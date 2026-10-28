extends SceneTree

const MODEL_SCRIPT := preload("res://tools/diagnostics/rom_gameplay_root_task_bootstrap_model.gd")
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
	print("ROM bootstrap/NMI contract: root slots and continuations, vector/handler gate, and bounded 59-special/493-normal frame observations match source and both retained passes; no NMI cycle schedule is synthesized.")
	quit(0)


func _run_verification() -> bool:
	var source_spans: Dictionary = {}
	if not _load_and_verify_sources(source_spans):
		return false
	var model = MODEL_SCRIPT.new()
	if not model.configure(source_spans):
		return _fail("Root-task bootstrap model rejected verified spans: " + model.error_message)
	var state: Dictionary = model.derive_bootstrap()
	if not bool(state.get("ok", false)):
		return _fail("ROM-derived gameplay bootstrap failed: " + model.error_message)
	if int(state.get("latch_001b", -1)) != 0:
		return _fail("Fresh-game bootstrap should clear `$001B` before enabling NMI.")
	if int(state.get("ppu_ctrl_shadow", -1)) != 0x88 or not bool(state.get("ppu_nmi_enabled", false)):
		return _fail("The source bootstrap did not enable PPU NMI with the `$2000` shadow at `$88`.")
	if int(state.get("scheduler_entry_pc", -1)) != 0xCA97:
		return _fail("Fresh-game bootstrap no longer enters the source scheduler at `$CA97`.")
	if not _verify_root_task_state(state):
		return false
	if not _verify_nmi_gate_model(model, state):
		return false
	if not _verify_two_pass_trace(state, model):
		return false
	return true


func _verify_root_task_state(state: Dictionary) -> bool:
	var tasks: Array = state.get("root_tasks", [])
	if tasks.size() != 3:
		return _fail("The bootstrap must derive exactly three root tasks.")
	var expected_slots := [0x01, 0x05, 0x09]
	var expected_sp := [0x28, 0x50, 0x78]
	var expected_pc := [0xCA21, 0xD11D, 0xEB85]
	for index in range(3):
		var task: Dictionary = tasks[index]
		var sp: int = int(expected_sp[index])
		var expected_record := PackedByteArray([0xFF, sp, 0x00, 0x00])
		if int(task.get("slot", -1)) != int(expected_slots[index]) \
				or int(task.get("saved_sp", -1)) != sp \
				or int(task.get("return_pc", -1)) != int(expected_pc[index]) \
				or task.get("record", PackedByteArray()) != expected_record:
			return _fail("Root task %d record or continuation differs from source bytes." % index)
		var stack_page: PackedByteArray = state.get("stack_page", PackedByteArray())
		var low_index := (sp + 1) & 0xFF
		var high_index := (sp + 2) & 0xFF
		if stack_page.size() != 0x100 \
				or stack_page[low_index] != (int(expected_pc[index]) & 0xFF) \
				or stack_page[high_index] != ((int(expected_pc[index]) >> 8) & 0xFF):
			return _fail("Root task %d RTS continuation was not written to the 6502 stack page." % index)
	return true


func _verify_nmi_gate_model(model: RefCounted, state: Dictionary) -> bool:
	var normal: Dictionary = model.call("apply_nmi_ready_edge", state, 0x00)
	if not bool(normal.get("ok", false)) or not bool(normal.get("serviced", false)) \
			or normal.get("path", "") != "fixed_normal" \
			or int(normal.get("latch_after", -1)) != 0x80 \
			or int(normal.get("writer_pc", -1)) != 0xC7F0:
		return _fail("The bit-6-clear NMI path did not derive the fixed-bank ready write.")
	var special: Dictionary = model.call("apply_nmi_ready_edge", state, 0x40)
	if not bool(special.get("ok", false)) or not bool(special.get("serviced", false)) \
			or special.get("path", "") != "bank02_mode6" \
			or int(special.get("latch_after", -1)) != 0xC0 \
			or int(special.get("writer_pc", -1)) != 0xA135:
		return _fail("The bit-6-set NMI path did not derive its bank-$02 ready write.")
	var source_normal: Dictionary = model.call("resolve_source_nmi_service", 8461, 0x88, 0x00, true)
	if not bool(source_normal.get("ok", false)) or not bool(source_normal.get("serviced", false)) \
			or int(source_normal.get("writer_pc", -1)) != 0xC7F0 \
			or bool(source_normal.get("models_nmi_cycle", true)):
		return _fail("Source-clock NMI service mapping must resolve the normal ready writer without inventing a cycle.")
	var disabled: Dictionary = model.call("resolve_source_nmi_service", 8459, 0x08, 0x00, false)
	if not bool(disabled.get("ok", false)) or bool(disabled.get("serviced", true)):
		return _fail("A source frame without an external NMI delivery must not synthesize a ready edge.")
	return true


func _load_and_verify_sources(source_spans: Dictionary) -> bool:
	if not FileAccess.file_exists(ROM_PATH):
		return _fail("The supplied ROM is required for this diagnostic source verifier.")
	var rom: PackedByteArray = FileAccess.get_file_as_bytes(ROM_PATH)
	if _sha256(rom) != ROM_SHA256:
		return _fail("Supplied ROM SHA-256 differs from the audited Turkish revision.")
	var manifest_file := FileAccess.open(TASK_CONTEXT_ROOT + "manifest.json", FileAccess.READ)
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
		var file_name: String = String(spec["path"]).get_file()
		if not manifest_by_file.has(file_name):
			return _fail("Manifest does not describe preserved span %s." % file_name)
		var entry: Dictionary = manifest_by_file[file_name]
		var offset: int = int(spec["offset"])
		var length: int = int(spec["length"])
		if int(entry.get("length", -1)) != length \
				or String(entry.get("file_offset", "")) != "0x%06X" % offset:
			return _fail("Manifest offset or length differs for %s." % file_name)
		if String(entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Manifest hash differs for %s." % file_name)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(String(spec["path"]))
		if bytes.size() != length or _sha256(bytes) != String(spec["sha256"]):
			return _fail("Preserved ROM span failed its size/hash check: %s." % file_name)
		for index in range(length):
			if bytes[index] != rom[offset + index]:
				return _fail("Preserved bytes differ from the supplied ROM at file offset $%06X." % (offset + index))
		source_spans[key] = bytes
	return true


func _verify_two_pass_trace(state: Dictionary, model: RefCounted) -> bool:
	var validation_file := FileAccess.open(TRACE_ROOT + "validation.json", FileAccess.READ)
	if validation_file == null:
		return _fail("Retained muted two-pass task-boundary validation is missing.")
	var validation: Dictionary = JSON.parse_string(validation_file.get_as_text())
	var metadata := FileAccess.get_file_as_string(TRACE_ROOT + "metadata.txt")
	if not metadata.contains("source_rom_sha256=" + ROM_SHA256) \
			or not metadata.contains("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted"):
		return _fail("Trace metadata does not identify the audited ROM and muted FCEUX configuration.")
	if int(validation.get("checkpoint_frame", -1)) != 8399 \
			or int(validation.get("replays", 0)) != 2 \
			or not bool(validation.get("checkpoint_signature_verified_after_both_loads", false)) \
			or String(validation.get("normalized_event_sha256", "")) != EVENT_SHA256 \
			or String(validation.get("normalized_write_sha256", "")) != WRITE_SHA256:
		return _fail("Retained trace identity/checkpoint signatures or normalized hashes differ.")
	var first_events := _read_csv(TRACE_ROOT + "task_events.csv")
	var second_events := _read_csv(TRACE_ROOT + "task_events_repeat.csv")
	var first_writes := _read_csv(TRACE_ROOT + "task_writes.csv")
	var second_writes := _read_csv(TRACE_ROOT + "task_writes_repeat.csv")
	for pass_number in range(2):
		var events: Array[Dictionary] = first_events if pass_number == 0 else second_events
		var writes: Array[Dictionary] = first_writes if pass_number == 0 else second_writes
		if events.is_empty() or writes.is_empty():
			return _fail("A retained trace pass is missing or empty.")
		if not _verify_seed_events(events, state) or not _verify_seed_stack(events, state):
			return _fail("Pass %d disagrees with ROM-derived slot/stack bootstrap state." % (pass_number + 1))
		if not _verify_nmi_trace(writes, model, state):
			return _fail("Pass %d disagrees with the ROM-derived NMI ready-latch gate." % (pass_number + 1))
		if not _verify_observed_nmi_frame_cadence(writes, model):
			return _fail("Pass %d disagrees with the bounded source-frame NMI observations." % (pass_number + 1))
	return true


func _verify_observed_nmi_frame_cadence(writes: Array[Dictionary], model: RefCounted) -> bool:
	var writes_by_frame: Dictionary = {}
	for write: Dictionary in writes:
		var frame_key := String(write.get("frame", ""))
		var frame_rows: Array = writes_by_frame.get(frame_key, [])
		frame_rows.append(write)
		writes_by_frame[frame_key] = frame_rows
	var normal_set_cycles: Array[int] = []
	for frame in range(8461, 8954):
		var frame_rows: Array = writes_by_frame.get(str(frame), [])
		var set_write := _find_write(frame_rows, str(frame), "$C7F0", "$001B", "$00", "$80")
		var consume_write := _find_write(frame_rows, str(frame), "$CAB6", "$001B", "$80", "$00")
		var disable_write := _find_write(frame_rows, str(frame), "$C783", "$0020", "", "")
		var reenable_write := _find_write(frame_rows, str(frame), "$C816", "$0020", "", "")
		if set_write.is_empty() or consume_write.is_empty() or disable_write.is_empty() or reenable_write.is_empty():
			return _fail("Normal NMI frame %d lacks a handler disable/set/reenable/consume sequence." % frame)
		var ppu_ctrl_before := _parse_hex_byte(String(disable_write["old"]))
		var ppu_ctrl_during := _parse_hex_byte(String(disable_write["new"]))
		var ppu_ctrl_after := _parse_hex_byte(String(reenable_write["new"]))
		if (ppu_ctrl_before & 0x80) == 0 or (ppu_ctrl_during & 0x80) != 0 \
				or (ppu_ctrl_after & 0x80) == 0:
			return _fail("Normal NMI frame %d does not show the source PPUCTRL disable/re-enable gate." % frame)
		var modeled: Dictionary = model.call("resolve_source_nmi_service", frame, ppu_ctrl_before, 0x00, true)
		if not bool(modeled.get("ok", false)) or not bool(modeled.get("serviced", false)) \
				or int(modeled.get("writer_pc", -1)) != 0xC7F0:
			return _fail("Normal NMI frame %d does not map to the ROM ready writer." % frame)
		var disable_sequence := int(disable_write["sequence"])
		var set_sequence := int(set_write["sequence"])
		var reenable_sequence := int(reenable_write["sequence"])
		var consume_sequence := int(consume_write["sequence"])
		if not (disable_sequence < set_sequence and set_sequence < reenable_sequence \
				and reenable_sequence < consume_sequence):
			return _fail("Normal NMI frame %d violates disable → ready → re-enable → scheduler-consume order." % frame)
		normal_set_cycles.append(int(set_write["cycle_from_frame_start"]))
	if normal_set_cycles.size() != 493:
		return _fail("Expected 493 observed normal NMI-ready frames in the retained field interval.")
	var min_cycle := normal_set_cycles[0]
	var max_cycle := normal_set_cycles[0]
	for cycle in normal_set_cycles:
		min_cycle = mini(min_cycle, cycle)
		max_cycle = maxi(max_cycle, cycle)
	if min_cycle != 1217 or max_cycle != 2677:
		return _fail("Normal NMI cycle-phase range changed from the retained trace evidence.")

	# The prior mode-6 interval uses the bank-$02 writer, then a separate source
	# store restores $001B from $C0 to $40. It is not the $CAB6 scheduler consume.
	for frame in range(8400, 8459):
		var frame_rows: Array = writes_by_frame.get(str(frame), [])
		var special_write := _find_write(frame_rows, str(frame), "$A135", "$001B", "$40", "$C0")
		var mode_restore := _find_write(frame_rows, str(frame), "$9F0C", "$001B", "$C0", "$40")
		if special_write.is_empty() or mode_restore.is_empty() \
				or int(special_write["sequence"]) >= int(mode_restore["sequence"]):
			return _fail("Special-mode NMI frame %d lacks the independent ready/mode restore pair." % frame)
		var modeled_special: Dictionary = model.call("resolve_source_nmi_service", frame, 0x80, 0x40, true)
		if not bool(modeled_special.get("ok", false)) \
				or int(modeled_special.get("writer_pc", -1)) != 0xA135:
			return _fail("Special-mode frame %d does not map to the ROM bank-$02 ready writer." % frame)
	if not _frame_has_no_latch_write(writes_by_frame.get("8459", [])):
		return _fail("Frame 8459 is no longer the observed transition gap; do not assume an unconditional edge.")
	var reset_write := _find_write(writes_by_frame.get("8460", []), "8460", "$C6EC", "$001B", "$40", "$00")
	if reset_write.is_empty():
		return _fail("Fresh-game setup no longer clears mode/ready bits at frame 8460.")
	return true


func _frame_has_no_latch_write(rows: Array) -> bool:
	for row: Dictionary in rows:
		if row.get("address", "") == "$001B":
			return false
	return true


func _find_write(rows: Array, frame: String, pc_after: String,
		address: String, old_value: String, new_value: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.get("frame", "") != frame or row.get("pc_after_write", "") != pc_after \
				or row.get("address", "") != address:
			continue
		if not old_value.is_empty() and row.get("old", "") != old_value:
			continue
		if not new_value.is_empty() and row.get("new", "") != new_value:
			continue
		return row
	return {}


func _verify_seed_events(events: Array[Dictionary], state: Dictionary) -> bool:
	var observed: Array[Dictionary] = []
	for row: Dictionary in events:
		if row.get("frame", "") == "8460" and row.get("kind", "") == "task_seed_CAE7":
			observed.append(row)
	if observed.size() < 3:
		return false
	var tasks: Array = state.get("root_tasks", [])
	for index in range(3):
		var task: Dictionary = tasks[index]
		var row: Dictionary = observed[index]
		var pc := int(task["return_pc"])
		if row.get("pc", "") != "$CAE7" \
				or row.get("x", "") != "$%02X" % int(task["slot"]) \
				or row.get("a", "") != "$%02X" % ((pc >> 8) & 0xFF) \
				or row.get("y", "") != "$%02X" % (pc & 0xFF):
			return false
	if observed[0].get("current_task_base_0000", "") != "$01" \
			or observed[0].get("current_task_record_0000_0003", "") != "00 28 00 00":
		return false
	var dispatch_slots: Array[int] = []
	for row: Dictionary in events:
		if row.get("frame", "") == "8460" and row.get("kind", "") == "task_first_dispatch_CAD4":
			dispatch_slots.append(_parse_hex_byte(String(row.get("x", ""))))
	if dispatch_slots.size() < 3:
		return false
	return dispatch_slots[0] == 0x01 and dispatch_slots[1] == 0x05 and dispatch_slots[2] == 0x09


func _verify_seed_stack(events: Array[Dictionary], state: Dictionary) -> bool:
	var scan: Dictionary = _find_event(events, "scheduler_scan_CA97", "8460", "pc", "$CA97")
	if scan.is_empty():
		return false
	var stack_hex: String = String(scan.get("stack_page_0100_01ff", ""))
	if stack_hex.length() != 0x200:
		return false
	var trace_stack := _bytes_from_hex(stack_hex)
	var source_stack: PackedByteArray = state.get("stack_page", PackedByteArray())
	if trace_stack.size() != 0x100 or source_stack.size() != 0x100:
		return false
	for task: Dictionary in state.get("root_tasks", []):
		var low_index := int(task["stack_low_index"])
		var high_index := int(task["stack_high_index"])
		if trace_stack[low_index] != source_stack[low_index] \
				or trace_stack[high_index] != source_stack[high_index]:
			return false
	return true


func _verify_nmi_trace(writes: Array[Dictionary], model: RefCounted, state: Dictionary) -> bool:
	var normal: Dictionary = model.call("apply_nmi_ready_edge", state, 0x00)
	var special: Dictionary = model.call("apply_nmi_ready_edge", state, 0x40)
	if not _contains_write(writes, "8400", "$A135", "$001B", "$40", "$C0"):
		return false
	if not _contains_write(writes, "8460", "$C6EC", "$001B", "$40", "$00"):
		return false
	if not _contains_write(writes, "8461", "$C7F0", "$001B", "$00", "$80") \
			or int(normal.get("latch_after", -1)) != 0x80:
		return false
	return _contains_write(writes, "8461", "$CAB6", "$001B", "$80", "$00") \
		and int(special.get("latch_after", -1)) == 0xC0


func _find_event(rows: Array[Dictionary], kind: String, frame: String,
		match_field: String, match_value: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.get("kind", "") == kind and row.get("frame", "") == frame \
				and String(row.get(match_field, "")) == match_value:
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


func _parse_hex_byte(text: String) -> int:
	return text.trim_prefix("$").hex_to_int()


func _bytes_from_hex(text: String) -> PackedByteArray:
	var result := PackedByteArray()
	for index in range(0, text.length(), 2):
		result.append(text.substr(index, 2).hex_to_int())
	return result


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


func _sha256(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _fail(message: String) -> bool:
	printerr("ROM gameplay root-task bootstrap verification failed: " + message)
	return false
