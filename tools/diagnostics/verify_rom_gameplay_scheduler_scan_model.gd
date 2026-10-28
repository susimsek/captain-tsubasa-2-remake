extends SceneTree

const MODEL_SCRIPT := preload("res://tools/diagnostics/rom_gameplay_scheduler_scan_model.gd")
const ROM_PATH := "res://Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
const TASK_CONTEXT_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const TRACE_ROOT := "res://reference/diagnostics/first_command_task_boundary_20261028_070655_utc/"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EVENT_SHA256 := "5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a"
const WRITE_SHA256 := "c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22"


func _initialize() -> void:
	if not _run_verification():
		quit(1)
		return
	print("ROM scheduler scan model: six-slot byte order, delay dispatch, and `$001B.7` gate verified; trace dispatch/latch events match both retained replay passes.")
	quit(0)


func _run_verification() -> bool:
	var source_bytes := PackedByteArray()
	if not _load_and_verify_source(source_bytes):
		return false
	var model = MODEL_SCRIPT.new()
	if not model.configure(source_bytes):
		return _fail("Scheduler model rejected verified source: " + model.error_message)
	if model.slot_bases() != [0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]:
		return _fail("Decoded task scan bases differ from the ROM's +4 loop.")
	if not _verify_model_decisions(model):
		return false
	return _verify_two_pass_trace()


func _verify_model_decisions(model) -> bool:
	var all_empty := PackedByteArray([0, 0, 0, 0, 0, 0])
	var wait_result: Dictionary = model.scan_once(all_empty, 0x45)
	if not _matches_result(wait_result, MODEL_SCRIPT.Decision.WAIT_FOR_NMI_READY,
			-1, PackedByteArray([0, 0, 0, 0, 0, 0]), 0x45,
			[0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]):
		return _fail("Empty slots should finish the six-slot scan and wait while `$001B.7` is clear.")

	# `$FF` dispatches immediately at the first available slot and leaves later
	# slot bytes untouched because the source branches out of the scan loop.
	var immediate_input := PackedByteArray([0xFF, 0x01, 0, 0, 0, 0])
	var immediate: Dictionary = model.scan_once(immediate_input, 0)
	if not _matches_result(immediate, MODEL_SCRIPT.Decision.INITIAL_DISPATCH,
			0x01, immediate_input, 0, [0x01]):
		return _fail("`$FF` was not treated as an immediate first-slot dispatch.")

	# A one-tick delay dispatches on the scan that decrements it to zero; the
	# NMI gate is reached only if no slot became eligible.
	var one_tick := PackedByteArray([0, 0, 1, 0, 0, 0])
	var resumed: Dictionary = model.scan_once(one_tick, 0)
	if not _matches_result(resumed, MODEL_SCRIPT.Decision.YIELDED_RESUME,
			0x09, PackedByteArray([0, 0, 0, 0, 0, 0]), 0, [0x01, 0x05, 0x09]):
		return _fail("A one-tick yielded record did not resume when its delay reached zero.")

	# A higher-priority finite delay reaches zero before a later `$FF` slot.
	var priority_input := PackedByteArray([2, 1, 0xFF, 0, 0, 0])
	var priority: Dictionary = model.scan_once(priority_input, 0x80)
	if not _matches_result(priority, MODEL_SCRIPT.Decision.YIELDED_RESUME,
			0x05, PackedByteArray([1, 0, 0xFF, 0, 0, 0]), 0x80, [0x01, 0x05]):
		return _fail("Scheduler did not stop at the first eligible record in slot order.")

	# No slot is ready: the scan decrements every finite nonzero slot, then the
	# NMI-ready bit is cleared without changing bits 0–6 before the source jump
	# back to `$CA97`.
	var delayed_slots := PackedByteArray([2, 2, 0, 0, 0, 0])
	var nmi_ready: Dictionary = model.scan_once(delayed_slots, 0xD5)
	if not _matches_result(nmi_ready, MODEL_SCRIPT.Decision.CLEAR_NMI_AND_RESCAN,
			-1, PackedByteArray([1, 1, 0, 0, 0, 0]), 0x55,
			[0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]):
		return _fail("NMI-ready scan did not preserve lower latch bits while clearing bit 7.")

	var next_nmi_scan: Dictionary = model.scan_once(
		PackedByteArray([1, 1, 0, 0, 0, 0]), 0x80)
	if not _matches_result(next_nmi_scan, MODEL_SCRIPT.Decision.YIELDED_RESUME,
			0x01, PackedByteArray([0, 1, 0, 0, 0, 0]), 0x80, [0x01]):
		return _fail("A new caller-supplied ready scan did not resume the first delay reaching zero.")
	return true


func _matches_result(result: Dictionary, decision: int, selected_slot: int,
		ready_after: PackedByteArray, latch_after: int, checked_slots: Array) -> bool:
	return int(result.get("decision", -1)) == decision \
		and int(result.get("selected_slot_base", -2)) == selected_slot \
		and result.get("ready_delays_after", PackedByteArray()) == ready_after \
		and int(result.get("ready_latch_after", -1)) == latch_after \
		and result.get("checked_slots", []) == checked_slots


func _load_and_verify_source(source_bytes: PackedByteArray) -> bool:
	if not FileAccess.file_exists(ROM_PATH):
		return _fail("The supplied ROM is required for this diagnostic source verifier.")
	var rom := FileAccess.get_file_as_bytes(ROM_PATH)
	if _sha256(rom) != ROM_SHA256:
		return _fail("Supplied ROM SHA-256 differs from the audited Turkish revision.")
	var manifest_file := FileAccess.open(TASK_CONTEXT_ROOT + "manifest.json", FileAccess.READ)
	if manifest_file == null:
		return _fail("Task-context source manifest is missing.")
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Task-context source manifest names a different ROM revision.")
	var spec: Dictionary = MODEL_SCRIPT.source_span_spec()
	var file_name: String = String(spec["path"]).get_file()
	var manifest_entry: Dictionary = {}
	for entry: Dictionary in manifest.get("spans", []):
		if String(entry.get("file", "")) == file_name:
			manifest_entry = entry
			break
	if manifest_entry.is_empty():
		return _fail("Manifest does not describe the preserved fixed-task scheduler span.")
	var offset: int = int(spec["offset"])
	var length: int = int(spec["length"])
	if int(manifest_entry.get("length", -1)) != length \
			or String(manifest_entry.get("file_offset", "")) != "0x%06X" % offset:
		return _fail("Manifest scheduler source offset or length differs from the verifier.")
	var preserved_path: String = String(spec["path"])
	var preserved := FileAccess.get_file_as_bytes(preserved_path)
	if preserved.size() != length or _sha256(preserved) != String(spec["sha256"]):
		return _fail("Preserved scheduler span failed its length or hash check.")
	if String(manifest_entry.get("sha256", "")) != String(spec["sha256"]):
		return _fail("Manifest scheduler source hash differs from the verifier.")
	for index in range(length):
		if preserved[index] != rom[offset + index]:
			return _fail("Preserved scheduler bytes differ at ROM file offset $%06X." % (offset + index))
	source_bytes.append_array(preserved)
	return true


func _verify_two_pass_trace() -> bool:
	var validation_file := FileAccess.open(TRACE_ROOT + "validation.json", FileAccess.READ)
	if validation_file == null:
		return _fail("The retained two-pass scheduler trace validation record is missing.")
	var validation: Dictionary = JSON.parse_string(validation_file.get_as_text())
	if int(validation.get("checkpoint_frame", -1)) != 8399 \
			or int(validation.get("replays", 0)) != 2 \
			or not bool(validation.get("checkpoint_signature_verified_after_both_loads", false)):
		return _fail("Trace is not the two-pass run from the verified frame-8399 checkpoint.")
	if String(validation.get("normalized_event_sha256", "")) != EVENT_SHA256 \
			or String(validation.get("normalized_write_sha256", "")) != WRITE_SHA256:
		return _fail("Normalized two-pass trace hashes differ from the retained audit.")
	if not bool(validation.get("diagnostics_only", false)):
		return _fail("Trace metadata does not mark the source capture diagnostic-only.")

	var events_one := _read_csv(TRACE_ROOT + "task_events.csv")
	var events_two := _read_csv(TRACE_ROOT + "task_events_repeat.csv")
	var writes_one := _read_csv(TRACE_ROOT + "task_writes.csv")
	var writes_two := _read_csv(TRACE_ROOT + "task_writes_repeat.csv")
	if events_one.is_empty() or events_two.is_empty() or writes_one.is_empty() or writes_two.is_empty():
		return _fail("One or more retained task trace passes are missing or empty.")
	if _scheduler_event_projection(events_one) != _scheduler_event_projection(events_two):
		return _fail("Scheduler dispatch/resume event sequences differ between the two trace passes.")
	if _scheduler_latch_projection(writes_one) != _scheduler_latch_projection(writes_two):
		return _fail("Observed scheduler-ready latch writes differ between the two trace passes.")
	if not _verify_observed_event_order(events_one) or not _verify_observed_event_order(events_two):
		return _fail("A retained pass does not show the expected source-route dispatch/resume order.")
	if not _verify_observed_latch_edge(writes_one) or not _verify_observed_latch_edge(writes_two):
		return _fail("A retained pass does not show the `$001B.7` set/clear edge at frame 8461.")
	return true


func _verify_observed_event_order(events: Array[Dictionary]) -> bool:
	if _frame_event_signature(events, "8460", ["task_first_dispatch_CAD4"]) \
			!= ["task_first_dispatch_CAD4:$01", "task_first_dispatch_CAD4:$05", "task_first_dispatch_CAD4:$09"]:
		return false
	if _frame_event_signature(events, "8461", ["scheduler_latch_clear_CAB6", "task_resume_CAB9"]) \
			!= ["scheduler_latch_clear_CAB6:$19", "task_resume_CAB9:$01",
				"task_resume_CAB9:$05", "task_resume_CAB9:$09"]:
		return false
	if _frame_event_signature(events, "8893", ["scheduler_latch_clear_CAB6",
			"task_resume_CAB9", "task_first_dispatch_CAD4"]) \
			!= ["scheduler_latch_clear_CAB6:$19", "task_resume_CAB9:$01",
				"task_resume_CAB9:$05", "task_resume_CAB9:$09", "task_first_dispatch_CAD4:$15"]:
		return false
	var initial_callback := _find_event(events, "task_first_dispatch_CAD4", "8893", "$15")
	if initial_callback.is_empty() or not String(initial_callback.get("task_slots_0011_002c", "")).contains("15:FFF00B12"):
		return false
	var next_frame_resume := _find_event(events, "task_resume_CAB9", "8894", "$15")
	if next_frame_resume.is_empty() or not String(next_frame_resume.get("task_slots_0011_002c", "")).contains("15:00E90B0C"):
		return false
	return true


func _verify_observed_latch_edge(writes: Array[Dictionary]) -> bool:
	var set_row := _find_latch_write(writes, "8461", "$C7F0", "$00", "$80")
	var clear_row := _find_latch_write(writes, "8461", "$CAB6", "$80", "$00")
	if set_row.is_empty() or clear_row.is_empty():
		return false
	return int(set_row.get("sequence", -1)) < int(clear_row.get("sequence", -1))


func _scheduler_event_projection(rows: Array[Dictionary]) -> Array[String]:
	var projection: Array[String] = []
	var kinds := ["scheduler_scan_CA97", "scheduler_latch_clear_CAB6",
		"task_first_dispatch_CAD4", "task_resume_CAB9"]
	for row: Dictionary in rows:
		if not kinds.has(String(row.get("kind", ""))):
			continue
		projection.append("%s|%s|%s|%s|%s" % [
			String(row.get("frame", "")), String(row.get("kind", "")),
			String(row.get("x", "")), String(row.get("current_task_record_0000_0003", "")),
			String(row.get("ready_latch_001b", "")),
		])
	return projection


func _scheduler_latch_projection(rows: Array[Dictionary]) -> Array[String]:
	var projection: Array[String] = []
	for row: Dictionary in rows:
		if row.get("address", "") != "$001B":
			continue
		if row.get("pc_after_write", "") not in ["$C7F0", "$CAB6"]:
			continue
		projection.append("%s|%s|%s|%s|%s" % [
			String(row.get("frame", "")), String(row.get("pc_after_write", "")),
			String(row.get("old", "")), String(row.get("new", "")),
			String(row.get("sequence", "")),
		])
	return projection


func _frame_event_signature(events: Array[Dictionary], frame: String,
		kinds: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for row: Dictionary in events:
		var kind := String(row.get("kind", ""))
		if row.get("frame", "") == frame and kinds.has(kind):
			result.append("%s:%s" % [kind, String(row.get("x", ""))])
	return result


func _find_event(events: Array[Dictionary], kind: String, frame: String,
		x_value: String) -> Dictionary:
	for row: Dictionary in events:
		if row.get("kind", "") == kind and row.get("frame", "") == frame \
				and row.get("x", "") == x_value:
			return row
	return {}


func _find_latch_write(writes: Array[Dictionary], frame: String, pc_after: String,
		old_value: String, new_value: String) -> Dictionary:
	for row: Dictionary in writes:
		if row.get("frame", "") == frame and row.get("pc_after_write", "") == pc_after \
				and row.get("address", "") == "$001B" and row.get("old", "") == old_value \
				and row.get("new", "") == new_value:
			return row
	return {}


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.is_empty() or values.size() != headers.size():
			continue
		var row: Dictionary = {}
		for index in range(headers.size()):
			row[headers[index]] = values[index]
		rows.append(row)
	return rows


func _fail(message: String) -> bool:
	push_error(message)
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
