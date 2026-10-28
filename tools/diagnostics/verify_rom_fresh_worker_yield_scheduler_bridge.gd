extends SceneTree

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PERIOD_TASK := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const CONTINUATION := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const WORKER_PREFIX := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const TRACE_ROOT := "res://reference/diagnostics/first_command_task_boundary_20261028_070655_utc/"
const WRITE_TRACE_ROOT := "res://reference/diagnostics/fresh_period_daaa_trace_20261028_135904_utc/"
const TASK_TRACE_ROOT := "res://reference/diagnostics/first_command_task_boundary_20261028_070655_utc/"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: bounded slot-$05 source writes merge without touching scheduler-owned RAM; continuation/worker writes and the `$CB0F` save match both retained trace passes.")
	print("LIMIT: this merges only writes from `$D11E->$C515`; earlier route RAM and the next scan/NMI/resume are not modeled.")
	quit(0)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh-route context source setup failed: " + builder.error_message)
	var route_context = builder.build_fresh_kickoff_context()
	if route_context == null:
		return _fail("Could not derive fresh-route source context: " + builder.error_message)

	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources():
		return _fail("Scheduler rejected its packaged/hash-checked source spans: " + scheduler.error_message)
	if not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Scheduler fresh-game source bootstrap failed: " + scheduler.error_message)
	var slot01_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot01_scan.get("ok", false)) or int(slot01_scan.get("selected_slot_base", -1)) != 0x01:
		return _fail("ROM scheduler did not select its first seeded root task.")
	var slot01_dispatch: Dictionary = scheduler.dispatch_pending_task(0x01)
	if not bool(slot01_dispatch.get("ok", false)) or int(slot01_dispatch.get("pc", -1)) != 0xCA22:
		return _fail("ROM scheduler did not restore the slot-$01 root continuation.")
	var slot01_yield: Dictionary = scheduler.execute_root_slot01_startup_to_first_yield()
	if not bool(slot01_yield.get("ok", false)) or int(slot01_yield.get("yield_callsite_pc", -1)) != 0xCA4F:
		return _fail("Slot-$01 source startup did not yield through its verified root callsite.")
	var slot05_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot05_scan.get("ok", false)) or int(slot05_scan.get("selected_slot_base", -1)) != 0x05:
		return _fail("The source scheduler did not continue from slot `$01` to slot `$05`.")
	var slot05_dispatch: Dictionary = scheduler.dispatch_pending_task(0x05)
	if not bool(slot05_dispatch.get("ok", false)) or int(slot05_dispatch.get("pc", -1)) != 0xD11E \
			or int(slot05_dispatch.get("sp", -1)) != 0x52:
		return _fail("Fresh slot-$05 dispatch did not restore `$D11E` / SP `$52`.")
	if not _same_dispatch(slot05_dispatch, route_context.scheduler_dispatch):
		return _fail("The independently derived slot-$05 context disagrees with the source scheduler dispatch.")

	var source_inputs: Dictionary = route_context.to_period_task_inputs()
	source_inputs["scheduler_dispatch"] = slot05_dispatch.duplicate(true)
	var period = PERIOD_TASK.new()
	if not period.configure_from_project_sources():
		return _fail("Fresh-period ROM source setup failed: " + period.error_message)
	var period_result: Dictionary = period.execute_fresh_match_zero(source_inputs)
	if not bool(period_result.get("ok", false)):
		return _fail("Slot-$05 source period execution failed: " + period.error_message)
	var continuation = CONTINUATION.new()
	if not continuation.configure_from_project_sources():
		return _fail("Fresh continuation source setup failed: " + continuation.error_message)
	var worker_entry: Dictionary = continuation.execute_synchronous_prefix(period_result)
	if not bool(worker_entry.get("ok", false)):
		return _fail("ROM-byte match-zero continuation failed: " + continuation.error_message)
	var worker = WORKER_PREFIX.new()
	if not worker.configure_from_project_sources():
		return _fail("Bank-$18 worker source setup failed: " + worker.error_message)
	var worker_result: Dictionary = worker.execute_to_yield_trampoline(worker_entry)
	if not bool(worker_result.get("ok", false)):
		return _fail("ROM-byte worker prefix failed: " + worker.error_message)
	var before_merge_status: Dictionary = scheduler.get_status()
	var before_merge_snapshot: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var merge_result: Dictionary = scheduler.merge_source_ordered_worker_writes(
		0x05, period_result, worker_entry, worker_result)
	if not bool(merge_result.get("ok", false)):
		return _fail("Scheduler rejected the source-ordered RAM delta: " + scheduler.error_message)
	var after_merge_status: Dictionary = scheduler.get_status()
	var after_merge_snapshot: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	if not _check_source_ram_merge(merge_result, before_merge_status, after_merge_status,
			before_merge_snapshot, after_merge_snapshot, period_result, worker_entry, worker_result):
		return false
	if not scheduler.adopt_bank18_worker_prefix_state(0x05, worker_result):
		return _fail("Scheduler rejected the source-owned worker boundary: " + scheduler.error_message)
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	if not scheduler.yield_at_verified_callsite(0x05, 0x8886, int(registers.get("a", -1)),
			int(registers.get("sp", -1)), int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))):
		return _fail("Source worker could not apply the verified `$CB0F` save: " + scheduler.error_message)
	var saved: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	if not _check_saved_source_state(saved, worker_result):
		return false
	return _check_retained_two_pass_trace(saved, worker_result)


func _check_source_ram_merge(merge: Dictionary, before_status: Dictionary,
		after_status: Dictionary, before: Dictionary, after: Dictionary,
		period_result: Dictionary, continuation_result: Dictionary,
		worker_result: Dictionary) -> bool:
	var source_order := ["fresh_period_D11E_DAAA", "fresh_continuation_DAAA_800C", "bank18_worker_800C_C515"]
	if merge.get("source_order", []) != source_order or bool(merge.get("full_ram_image_copied", true)) \
			or int(merge.get("reserved_address_write_count", -1)) != 0:
		return _fail("The RAM bridge did not report the bounded source order or claims a full image/reserved write.")
	var source_results: Array[Dictionary] = [period_result, continuation_result, worker_result]
	var expected_write_count := 0
	var touched_addresses: Dictionary = {}
	var expected_ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
	var expected_stack: PackedByteArray = worker_result.get("stack_page", PackedByteArray())
	var merged_ram: PackedByteArray = after.get("ram_image", PackedByteArray())
	var merged_stack: PackedByteArray = after.get("stack_page", PackedByteArray())
	if expected_ram.size() != 0x800 or expected_stack.size() != 0x100 \
			or merged_ram.size() != 0x800 or merged_stack.size() != 0x100:
		return _fail("The source delta or scheduler snapshot does not carry full internal-RAM/stack storage.")
	for source_result: Dictionary in source_results:
		for write_variant in source_result.get("writes", []):
			if not write_variant is Dictionary:
				return _fail("A source-ordered write stream contains a malformed entry.")
			var write: Dictionary = write_variant
			var address := int(write.get("address", -1))
			if address < 0 or address >= 0x800 or _scheduler_owned_address(address):
				return _fail("Source write touches scheduler-owned address $%04X." % address)
			expected_write_count += 1
			touched_addresses[address] = true
	if int(merge.get("write_count", -1)) != expected_write_count \
			or int(merge.get("unique_address_count", -1)) != touched_addresses.size() \
			or expected_write_count != 303:
		return _fail("Merged write count/address set differs from the three byte-executed source streams.")
	for address_variant in touched_addresses.keys():
		var address := int(address_variant)
		if int(merged_ram[address]) != int(expected_ram[address]):
			return _fail("Merged RAM `$%04X` differs from the final source-byte worker state." % address)
		if address >= 0x0100 and address < 0x0200 \
				and int(merged_stack[address & 0xFF]) != int(expected_stack[address & 0xFF]):
			return _fail("Merged stack-page byte `$%04X` differs from the source worker result." % address)
	if before_status.get("task_slots", []) != after_status.get("task_slots", []) \
			or int(before_status.get("scheduler_ready_latch_001b", -1)) != int(after_status.get("scheduler_ready_latch_001b", -2)) \
			or int(before_status.get("scheduler_ready_latch_001b", -1)) != 0 \
			or int(merged_ram[0x0000]) != 0x05 or int(before.get("ram_image", PackedByteArray())[0x0000]) != 0x05:
		return _fail("RAM delta changed task records, `$001B`, or the active slot pointer `$0000`.")
	for address: int in [0x0000, 0x001B, 0x0001, 0x0002, 0x0003, 0x0005, 0x0006, 0x0007,
			0x0008, 0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F,
			0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017, 0x0018]:
		if int(merged_ram[address]) != int(before["ram_image"][address]):
			return _fail("Scheduler-owned RAM `$%04X` was not preserved." % address)
	return _check_source_write_trace(continuation_result, worker_result)


func _check_source_write_trace(continuation_result: Dictionary, worker_result: Dictionary) -> bool:
	var validation: Variant = JSON.parse_string(FileAccess.get_file_as_string(WRITE_TRACE_ROOT + "validation.json"))
	if not validation is Dictionary or int(validation.get("replays", -1)) != 2 \
			or String(validation.get("replay_endpoint", "")) != "$DAD8" \
			or String(validation.get("normalized_call_sha256", "")) != "af0d5fe7cd4a7f1a4abe96a921c287d9d2adcca80e1d54cc292ff29406e01ea0" \
			or String(validation.get("normalized_ram_write_sha256", "")) != "57d88263d38a854a481ccd21202353ea7c9901dc8a690f4864c8c4358600a694":
		return _fail("The retained two-pass fresh-period RAM-write trace is missing or its equality summary changed.")
	var pass_specs := [
		{"pass": "1", "calls": "call_boundaries.csv", "writes": "ram_writes.csv",
			"events": TASK_TRACE_ROOT + "task_events.csv"},
		{"pass": "2", "calls": "call_boundaries_repeat.csv", "writes": "ram_writes_repeat.csv",
			"events": TASK_TRACE_ROOT + "task_events_repeat.csv"},
	]
	for spec: Dictionary in pass_specs:
		var pass_text := String(spec["pass"])
		var call_rows := _read_csv(WRITE_TRACE_ROOT + String(spec["calls"]))
		var write_rows := _read_csv(WRITE_TRACE_ROOT + String(spec["writes"]))
		var call_boundary := _find_event_row(call_rows, pass_text, "bank18_entry_800C", "event")
		var task_rows := _read_csv(String(spec["events"]))
		var task_boundary := _find_event_row(task_rows, pass_text, "task_yield_trampoline_C515", "kind")
		if call_boundary.is_empty() or task_boundary.is_empty() \
				or String(call_boundary.get("source_frame", "")) != "8460" \
				or String(call_boundary.get("cycle_from_frame_start", "")) != "27472" \
				or String(task_boundary.get("frame", "")) != "8460" \
				or String(task_boundary.get("cycle_from_frame_start", "")) != "27552":
			return _fail("Trace pass %s lacks the byte-runner source boundaries for ordered write validation." % pass_text)
		if not _compare_source_write_stream(continuation_result.get("writes", []), write_rows,
				call_boundary, pass_text, true):
			return false
		if not _compare_source_write_stream(worker_result.get("writes", []), write_rows,
				task_boundary, pass_text, false):
			return false
	return true


func _compare_source_write_stream(actual_variant: Variant, trace_rows: Array[Dictionary],
		boundary: Dictionary, pass_text: String, omit_stack_page: bool) -> bool:
	if not actual_variant is Array:
		return _fail("ROM-byte component did not return an ordered write array.")
	var actual: Array[String] = []
	var source_pcs: Dictionary = {}
	for write_variant in actual_variant:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		if omit_stack_page and address >= 0x0100 and address < 0x0200:
			continue
		var pc := int(write.get("trace_pc", write.get("pc", -1)))
		var value := int(write.get("value", -1))
		if pc < 0 or address < 0 or value < 0:
			return _fail("ROM-byte source write contains invalid PC/address/value data.")
		actual.append("%04X:%04X:%02X" % [pc, address, value])
		source_pcs[pc] = true
	var expected: Array[String] = []
	for row: Dictionary in trace_rows:
		if String(row.get("pass", "")) != pass_text \
				or String(row.get("source_frame", "")) != String(boundary.get("source_frame", boundary.get("frame", ""))) \
				or int(row.get("cycle_from_frame_start", -1)) > int(boundary.get("cycle_from_frame_start", -1)):
			continue
		var pc := String(row.get("pc", "")).trim_prefix("$").hex_to_int()
		var address := String(row.get("address", "")).trim_prefix("$").hex_to_int()
		if not source_pcs.has(pc) or omit_stack_page and address >= 0x0100 and address < 0x0200:
			continue
		expected.append("%04X:%04X:%02X" % [pc, address,
			String(row.get("new", "")).trim_prefix("$").hex_to_int()])
	if actual != expected:
		var mismatch := 0
		while mismatch < actual.size() and mismatch < expected.size() and actual[mismatch] == expected[mismatch]:
			mismatch += 1
		return _fail("Pass %s source RAM writes differ at %d (source %d, FCEUX %d): %s vs %s." % [
			pass_text, mismatch, actual.size(), expected.size(),
			actual[mismatch] if mismatch < actual.size() else "<end>",
			expected[mismatch] if mismatch < expected.size() else "<end>",
		])
	return true


func _find_event_row(rows: Array[Dictionary], pass_text: String, event_name: String,
		kind_field: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("pass", "")) == pass_text and String(row.get(kind_field, "")) == event_name:
			return row
	return {}


func _scheduler_owned_address(address: int) -> bool:
	if address == 0x0000 or address == 0x001B:
		return true
	for slot_base: int in [0x01, 0x05, 0x09, 0x0D, 0x11, 0x15]:
		if address >= slot_base and address < slot_base + 4:
			return true
	return false


func _same_dispatch(actual: Dictionary, expected_variant: Variant) -> bool:
	if not expected_variant is Dictionary:
		return false
	var expected: Dictionary = expected_variant
	for key: String in ["slot_base", "pc", "sp", "a", "x", "y", "bank_low", "bank_high", "source_return_word"]:
		if int(actual.get(key, -1)) != int(expected.get(key, -2)):
			return false
	return true


func _check_saved_source_state(saved: Dictionary, worker_result: Dictionary) -> bool:
	if int(saved.get("slot_base", -1)) != 0x05 or int(saved.get("phase", -1)) != SCHEDULER.ContextPhase.YIELDED \
			or int(saved.get("pc", -1)) != 0xCB0F or int(saved.get("sp", -1)) != 0x46 \
			or int(saved.get("a", -1)) != 0x01 or int(saved.get("x", -1)) != 0xFF \
			or int(saved.get("y", -1)) != 0x00 or int(saved.get("bank_low", -1)) != 0x18 \
			or int(saved.get("bank_high", -1)) != 0x19:
		return _fail("Saved slot-$05 task context differs from the `$CB0F` source save effects.")
	if saved.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
			or int(saved.get("ram_007F", -1)) != 0x01 \
			or int(saved.get("scheduler_y_register", -1)) != 0x05 \
			or int(saved.get("scheduler_scan_cursor", -1)) != 0x09 \
			or int(saved.get("active_task_slot", -2)) != -1:
		return _fail("`$CB0F` record, staging byte, or post-yield cursor differs from the source handler.")
	var stack: PackedByteArray = saved.get("stack_page", PackedByteArray())
	if stack.size() != 0x100 or _stack_window(stack, 0x47, 10) != "00ff888898ef1d1ccbda":
		return _fail("Saved worker stack window `$0147-$0150` does not preserve X/Y pushes and the wrapper return chain.")
	var source_regs: Dictionary = worker_result.get("registers", {})
	if int(source_regs.get("a", -1)) != 0x01 or int(source_regs.get("x", -1)) != 0xFF \
			or int(source_regs.get("y", -1)) != 0x00 or int(source_regs.get("p", -1)) != 0x20 \
			or int(source_regs.get("sp", -1)) != 0x48:
		return _fail("Pre-save CPU state differs from the byte-executed `$C515` worker result.")
	return true


func _check_retained_two_pass_trace(saved: Dictionary, worker_result: Dictionary) -> bool:
	var validation: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRACE_ROOT + "validation.json"))
	if not validation is Dictionary or int(validation.get("replays", -1)) != 2 \
			or String(validation.get("normalized_event_sha256", "")) != "5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a" \
			or String(validation.get("normalized_write_sha256", "")) != "c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22":
		return _fail("The retained two-pass task trace is missing or its equality summary changed.")
	var saved_stack: PackedByteArray = saved["stack_page"]
	var save_stack_window := _stack_window(saved_stack, 0x47, 10)
	var event_paths := ["task_events.csv", "task_events_repeat.csv"]
	var expected_passes := ["1", "2"]
	for event_index in range(event_paths.size()):
		var rows := _read_csv(TRACE_ROOT + String(event_paths[event_index]))
		var pass_text := String(expected_passes[event_index])
		var entry := _find_boundary_row(rows, pass_text, "task_yield_trampoline_C515")
		var handler := _find_boundary_row(rows, pass_text, "task_yield_save_CB0F")
		var after_save := _find_post_save_row(rows, pass_text)
		if entry.is_empty() or handler.is_empty() or after_save.is_empty():
			return _fail("Trace pass %s lacks the worker, handler, or post-save task boundary." % pass_text)
		for row: Dictionary in [entry, handler]:
			if not _matches_worker_entry(row, worker_result):
				return _fail("Trace pass %s worker/CB0F registers, mapper, stack, or live record differs." % pass_text)
		if String(after_save.get("current_task_record_0000_0003", "")) != "01 46 18 19" \
				or String(after_save.get("mapper_shadow_0024_0025", "")) != "$18 $19" \
				or String(after_save.get("mapper_select", "")) != "$07" \
				or String(after_save.get("prg_map", "")) != "18/19/1E/1F" \
				or String(after_save.get("sp", "")) != "$46":
			return _fail("Trace pass %s post-save record/bank/SP differs from the source scheduler state." % pass_text)
		var trace_stack := _trace_stack_window(after_save, 0x47, 10)
		if trace_stack.is_empty() or trace_stack != save_stack_window:
			return _fail("Trace pass %s saved stack window differs from the ROM-byte result." % pass_text)
		var write_rows := _read_csv(TRACE_ROOT + ("task_writes.csv" if pass_text == "1" else "task_writes_repeat.csv"))
		if not _has_source_write(write_rows, pass_text, "$CB11", "$007F", "$01") \
				or not _has_source_write(write_rows, pass_text, "$CB23", "$0005", "$01"):
			return _fail("Trace pass %s omits the `$CB0F` staging/ready-record writes." % pass_text)
	return true


func _matches_worker_entry(row: Dictionary, worker_result: Dictionary) -> bool:
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	var stack_hex := _trace_stack_window(row, 0x49, 8)
	return String(row.get("frame", "")) == "8460" \
			and String(row.get("a", "")) == "$%02X" % int(registers.get("a", -1)) \
			and String(row.get("x", "")) == "$%02X" % int(registers.get("x", -1)) \
			and String(row.get("y", "")) == "$%02X" % int(registers.get("y", -1)) \
			and String(row.get("p", "")) == "$%02X" % int(registers.get("p", -1)) \
			and String(row.get("sp", "")) == "$%02X" % int(registers.get("sp", -1)) \
			and String(row.get("current_task_base_0000", "")) == "$05" \
			and String(row.get("current_task_record_0000_0003", "")) == "FF 50 00 00" \
			and String(row.get("mapper_shadow_0024_0025", "")) == "$18 $19" \
			and String(row.get("mapper_select", "")) == "$07" \
			and String(row.get("prg_map", "")) == "18/19/1E/1F" \
			and stack_hex == "888898ef1d1ccbda" \
			and int(mapper.get("bank_low", -1)) == 0x18 and int(mapper.get("bank_high", -1)) == 0x19


func _find_boundary_row(rows: Array[Dictionary], pass_text: String, kind: String) -> Dictionary:
	var expected_cycle := "27552" if kind == "task_yield_trampoline_C515" else "27555"
	for row: Dictionary in rows:
		if String(row.get("pass", "")) == pass_text and String(row.get("frame", "")) == "8460" \
				and String(row.get("cycle_from_frame_start", "")) == expected_cycle \
				and String(row.get("kind", "")) == kind \
				and String(row.get("current_task_base_0000", "")) == "$05":
			return row
	return {}


func _find_post_save_row(rows: Array[Dictionary], pass_text: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("pass", "")) == pass_text and String(row.get("frame", "")) == "8460" \
				and String(row.get("kind", "")) == "task_first_dispatch_CAD4" \
				and String(row.get("current_task_base_0000", "")) == "$05" \
				and String(row.get("current_task_record_0000_0003", "")) == "01 46 18 19":
			return row
	return {}


func _has_source_write(rows: Array[Dictionary], pass_text: String, pc: String, address: String, new_value: String) -> bool:
	for row: Dictionary in rows:
		if String(row.get("pass", "")) == pass_text and String(row.get("frame", "")) == "8460" \
				and String(row.get("pc_after_write", "")) == pc \
				and String(row.get("address", "")) == address \
				and String(row.get("new", "")) == new_value:
			return true
	return false


func _trace_stack_window(row: Dictionary, first_offset: int, count: int) -> String:
	var stack_hex := String(row.get("stack_page_0100_01ff", "")).replace(" ", "").to_lower()
	if stack_hex.length() != 0x100 * 2:
		return ""
	var output := PackedByteArray()
	for offset in range(first_offset, first_offset + count):
		output.append(stack_hex.substr(offset * 2, 2).hex_to_int())
	return output.hex_encode()


func _stack_window(stack: PackedByteArray, first_offset: int, count: int) -> String:
	if stack.size() != 0x100:
		return ""
	return stack.slice(first_offset, first_offset + count).hex_encode()


func _read_csv(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var lines := FileAccess.get_file_as_string(path).split("\n", false)
	if lines.is_empty():
		return result
	var headers := lines[0].split(",")
	for line_index in range(1, lines.size()):
		var values := lines[line_index].split(",")
		if values.size() != headers.size():
			continue
		var row: Dictionary = {}
		for column in range(headers.size()):
			row[String(headers[column])] = values[column]
		result.append(row)
	return result


func _fail(message: String) -> bool:
	push_error(message)
	return false
