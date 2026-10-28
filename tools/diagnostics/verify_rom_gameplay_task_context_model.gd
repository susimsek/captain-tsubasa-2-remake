extends SceneTree

const MODEL_SCRIPT := preload("res://tools/diagnostics/rom_gameplay_task_context_model.gd")
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
	print("ROM gameplay task-context model: seed, initial dispatch, yield save, finite-delay resume, stack continuation, and finish verified against ROM bytes; trace used only for independent checks.")
	quit(0)


func _run_verification() -> bool:
	var source_spans: Dictionary = {}
	if not _load_and_verify_sources(source_spans):
		return false
	var model = MODEL_SCRIPT.new()
	if not model.configure(source_spans):
		return _fail("Task-context model rejected verified source spans: " + model.error_message)
	var source_status: Dictionary = model.get_source_status()
	if int(source_status["scenario_callback_slot"]) != 0x15:
		return _fail("Decoded scenario caller does not select task slot $0015.")
	if int(source_status["initial_stack_pointer"]) != 0xF0:
		return _fail("Decoded scenario caller does not seed SP $F0.")
	if int(source_status["initial_bank_base"]) != 0x0B:
		return _fail("Decoded scenario caller does not seed bank base $0B.")
	if int(source_status["initial_entry_pc"]) != 0x8009 or int(source_status["callback_reader_pc"]) != 0x814C:
		return _fail("Decoded initial stack return or bank-$0B jump is incorrect.")
	if int(source_status["yield_return_pc"]) != 0x8572:
		return _fail("Decoded $856F JSR return does not resume at $8572.")

	var context = model.seed_scenario_callback_task()
	if context == null:
		return _fail("ROM-backed scenario task seed failed: " + model.error_message)
	if context.record.to_bytes() != PackedByteArray([0xFF, 0xF0, 0x0B, 0x00]):
		return _fail("$C50F/$CAE7 produced an unexpected initial four-byte task record.")
	if context.stack_page[0xF1] != 0x08 or context.stack_page[0xF2] != 0x80:
		return _fail("$CAE7 did not seed the little-endian RTS continuation at SP $F0.")
	if context.program_counter != 0x80A8:
		return _fail("$CAE7 helper return should continue at bank-$10 $80A8.")
	if not model.evaluate_single_slot_scan(context):
		return _fail("A freshly seeded $FF task was not immediately eligible.")
	if not model.dispatch_pending_task(context):
		return _fail("Initial task context dispatch failed: " + model.error_message)
	if context.program_counter != 0x8009 or context.stack_pointer != 0xF2:
		return _fail("Initial task RTS did not enter $8009 with SP $F2.")
	if context.mapper_bank_low != 0x0B or context.mapper_bank_high != 0x0C:
		return _fail("Initial task did not derive the adjacent $0B/$0C bank map.")

	# This independent fixture exercises the verified $856F JSR call frame and
	# $CB0F save operation. The trace is consulted below only as an oracle; no
	# captured RAM, stack, or task record initializes this model context.
	if not model.yield_at_verified_callsite(context, 0x01, 0xED, 0x08, 0x10, 0x0B, 0x0C):
		return _fail("ROM-backed yield save failed: " + model.error_message)
	if context.record.to_bytes() != PackedByteArray([0x01, 0xE9, 0x0B, 0x0C]):
		return _fail("$CB0F did not save delay/SP/mapper context as expected.")
	if context.stack_page[0xEA] != 0x10 or context.stack_page[0xEB] != 0x08:
		return _fail("$CB0F did not push Y then X onto the task's 6502 stack page.")
	if context.stack_page[0xEC] != 0x71 or context.stack_page[0xED] != 0x85:
		return _fail("The $856F call return address was not retained below saved X/Y.")
	if not model.evaluate_single_slot_scan(context):
		return _fail("A one-tick yielded task did not become eligible after one scan.")
	if context.record.ready_delay != 0:
		return _fail("The source scheduler's one-step finite delay did not decrement to zero.")
	if not model.dispatch_pending_task(context):
		return _fail("Yielded task context restore failed: " + model.error_message)
	if context.program_counter != 0x8572 or context.stack_pointer != 0xED:
		return _fail("Yielded task did not RTS back to $8572 with its caller SP restored.")
	if context.x_register != 0x08 or context.y_register != 0x10:
		return _fail("Yielded task did not restore X/Y from the saved stack page.")
	if context.mapper_bank_low != 0x0B or context.mapper_bank_high != 0x0C:
		return _fail("Yielded task did not restore its saved mapper pair.")
	var saved_stack: PackedByteArray = context.stack_page.duplicate()
	if not model.finish_task(context):
		return _fail("ROM-backed task finish failed: " + model.error_message)
	if context.record.to_bytes() != PackedByteArray([0x00, 0x00, 0x0B, 0x0C]):
		return _fail("$CAF7 did not clear exactly record bytes +0/+1.")
	if context.stack_page != saved_stack:
		return _fail("$CAF7 unexpectedly changed the stack-page continuation bytes.")

	var delayed_context = model.seed_scenario_callback_task()
	if delayed_context == null or not model.evaluate_single_slot_scan(delayed_context) \
			or not model.dispatch_pending_task(delayed_context):
		return _fail("Could not prepare a second diagnostic finite-delay context.")
	if not model.yield_at_verified_callsite(delayed_context, 0x02, 0xE0, 0xA5, 0x5A, 0x18, 0x19):
		return _fail("Could not seed the two-scan finite-delay boundary.")
	if model.evaluate_single_slot_scan(delayed_context) or delayed_context.record.ready_delay != 0x01:
		return _fail("A delay of two should remain parked after its first scheduler scan.")
	if not model.evaluate_single_slot_scan(delayed_context) or delayed_context.record.ready_delay != 0:
		return _fail("A delay of two should become eligible after its second scheduler scan.")
	if not model.dispatch_pending_task(delayed_context):
		return _fail("Two-scan task context did not restore after becoming eligible.")
	if delayed_context.program_counter != 0x8572 or delayed_context.x_register != 0xA5 \
			or delayed_context.y_register != 0x5A or delayed_context.mapper_bank_high != 0x19:
		return _fail("Two-scan resume did not restore the tested stack/register/bank context.")

	if not _verify_two_pass_trace():
		return false
	return true


func _load_and_verify_sources(source_spans: Dictionary) -> bool:
	if not FileAccess.file_exists(ROM_PATH):
		return _fail("The supplied ROM is required for this diagnostic source verifier.")
	var rom: PackedByteArray = FileAccess.get_file_as_bytes(ROM_PATH)
	if _sha256(rom) != ROM_SHA256:
		return _fail("Supplied ROM SHA-256 differs from the audited Turkish revision.")
	var manifest_path := TASK_CONTEXT_ROOT + "manifest.json"
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		return _fail("Task-context source manifest is missing.")
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Task-context source manifest names a different ROM revision.")
	var manifest_by_file: Dictionary = {}
	for entry: Dictionary in manifest.get("spans", []):
		manifest_by_file[String(entry.get("file", ""))] = entry

	for key: String in MODEL_SCRIPT.source_span_specs():
		var spec: Dictionary = MODEL_SCRIPT.source_span_specs()[key]
		var path: String = String(spec["path"])
		var file_name: String = path.get_file()
		if not manifest_by_file.has(file_name):
			return _fail("Manifest does not describe preserved span %s." % file_name)
		var entry: Dictionary = manifest_by_file[file_name]
		var offset: int = int(spec["offset"])
		var length: int = int(spec["length"])
		if int(entry.get("length", -1)) != length or String(entry.get("file_offset", "")) != "0x%06X" % offset:
			return _fail("Manifest offset or length differs for %s." % file_name)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if bytes.size() != length or _sha256(bytes) != String(spec["sha256"]):
			return _fail("Preserved source span failed its length or hash check: %s." % file_name)
		if String(entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Manifest hash differs for %s." % file_name)
		for index in range(length):
			if bytes[index] != rom[offset + index]:
				return _fail("Preserved bytes differ from supplied ROM at file offset $%06X." % (offset + index))
		source_spans[key] = bytes
	return true


func _verify_two_pass_trace() -> bool:
	var validation_path := TRACE_ROOT + "validation.json"
	var validation_file := FileAccess.open(validation_path, FileAccess.READ)
	if validation_file == null:
		return _fail("The retained two-pass task trace validation record is missing.")
	var validation: Dictionary = JSON.parse_string(validation_file.get_as_text())
	if int(validation.get("checkpoint_frame", -1)) != 8399 or int(validation.get("replays", 0)) != 2:
		return _fail("Trace does not describe two replays from the expected source frame.")
	if not bool(validation.get("checkpoint_signature_verified_after_both_loads", false)):
		return _fail("Trace checkpoint signature was not verified after both loads.")
	if String(validation.get("normalized_event_sha256", "")) != EVENT_SHA256:
		return _fail("Normalized event trace hash differs from the retained audit.")
	if String(validation.get("normalized_write_sha256", "")) != WRITE_SHA256:
		return _fail("Normalized write trace hash differs from the retained audit.")

	var pass_one_events := _read_csv(TRACE_ROOT + "task_events.csv")
	var pass_two_events := _read_csv(TRACE_ROOT + "task_events_repeat.csv")
	var pass_one_writes := _read_csv(TRACE_ROOT + "task_writes.csv")
	var pass_two_writes := _read_csv(TRACE_ROOT + "task_writes_repeat.csv")
	if pass_one_events.is_empty() or pass_two_events.is_empty() or pass_one_writes.is_empty() or pass_two_writes.is_empty():
		return _fail("One or more retained task trace CSV files are missing or empty.")
	for pass_number in ["1", "2"]:
		var events: Array[Dictionary] = pass_one_events if pass_number == "1" else pass_two_events
		var writes: Array[Dictionary] = pass_one_writes if pass_number == "1" else pass_two_writes
		if not _verify_initial_trace_event(events):
			return _fail("Pass %s does not show the seeded task entering the initial callback." % pass_number)
		if not _verify_yield_trace(events, writes):
			return _fail("Pass %s does not show the modeled yield-save/resume boundary." % pass_number)
		if not _verify_finish_trace(events, writes):
			return _fail("Pass %s does not show the modeled task finish writes." % pass_number)
	return true


func _verify_initial_trace_event(events: Array[Dictionary]) -> bool:
	var dispatch: Dictionary = _find_event(events, "task_first_dispatch_CAD4", "8467", "x", "$15")
	if dispatch.is_empty():
		return false
	if not String(dispatch["task_slots_0011_002c"]).contains("15:FFF00B00"):
		return false
	if not String(dispatch["task_stack_windows_by_saved_sp"]).contains("15:F0:0880"):
		return false
	var callback: Dictionary = _find_event(events, "callback_read_814C", "8467", "pc", "$814C")
	if callback.is_empty() or callback["a"] != "$F0" or callback["sp"] != "$F2":
		return false
	if callback["mapper_shadow_0024_0025"] != "$0B $0C":
		return false
	return true


func _verify_yield_trace(events: Array[Dictionary], writes: Array[Dictionary]) -> bool:
	var yielded: Dictionary = _find_event(events, "task_yield_save_CB0F", "8467", "x", "$08")
	if yielded.is_empty() or yielded["x"] != "$08" or yielded["y"] != "$10" or yielded["sp"] != "$EB":
		return false
	if yielded["mapper_shadow_0024_0025"] != "$0B $0C":
		return false
	if not _contains_write(writes, "8467", "$CB23", "$0015", "$FF", "$01"):
		return false
	if not _contains_write(writes, "8467", "$CB28", "$0016", "$F0", "$E9"):
		return false
	if not _contains_write(writes, "8467", "$CB1F", "$0018", "$00", "$0C"):
		return false
	var resume: Dictionary = _find_event(events, "task_resume_CAB9", "8468", "pc", "$CAB9")
	if resume.is_empty() or not String(resume["task_slots_0011_002c"]).contains("15:01E90B0C"):
		return false
	return String(resume["task_stack_windows_by_saved_sp"]).contains("15:E9:10087185")


func _verify_finish_trace(events: Array[Dictionary], writes: Array[Dictionary]) -> bool:
	var finish: Dictionary = _find_event(events, "task_finish_CAF7", "8479", "pc", "$CAF7")
	if finish.is_empty() or not String(finish["task_slots_0011_002c"]).contains("15:00EA0B12"):
		return false
	if not _contains_write(writes, "8479", "$CAFD", "$0015", "$00", "$00"):
		return false
	return _contains_write(writes, "8479", "$CAFF", "$0016", "$EA", "$00")


func _find_event(rows: Array[Dictionary], kind: String, frame: String,
		match_field: String, match_value: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.get("pass", "") == "" or row.get("kind", "") != kind or row.get("frame", "") != frame:
			continue
		if String(row.get(match_field, "")) == match_value:
			return row
	return {}


func _contains_write(rows: Array[Dictionary], frame: String, pc_after: String,
		address: String, old_value: String, new_value: String) -> bool:
	for row: Dictionary in rows:
		if row.get("frame", "") == frame and row.get("pc_after_write", "") == pc_after \
				and row.get("address", "") == address and row.get("old", "") == old_value \
				and row.get("new", "") == new_value:
			return true
	return false


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.is_empty():
			continue
		if values.size() != headers.size():
			continue
		var row: Dictionary = {}
		for index in range(headers.size()):
			row[headers[index]] = values[index]
		rows.append(row)
	return rows


func _sha256(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _fail(message: String) -> bool:
	printerr("ROM gameplay task-context verification failed: " + message)
	return false
