extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PERIOD_TASK := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const CONTINUATION := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const WORKER_PREFIX := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const TASK_TRACE_ROOT := "res://reference/diagnostics/first_command_task_boundary_20261028_070655_utc/"
const WRITE_TRACE_ROOT := "res://reference/diagnostics/fresh_period_daaa_trace_20261028_135904_utc/"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-byte bank-$18 worker prefix reaches $C515 with trace-matching CPU, mapper, stack, and ordered RAM writes.")
	quit(0)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh route context source setup failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Could not derive source-owned fresh kickoff context: " + builder.error_message)
	var task = PERIOD_TASK.new()
	if not task.configure_from_project_sources():
		return _fail("Fresh-period source setup failed: " + task.error_message)
	var period_result: Dictionary = task.execute_fresh_match_zero(context.to_period_task_inputs())
	if not bool(period_result.get("ok", false)):
		return _fail("Fresh-period source execution failed: " + task.error_message)
	var continuation = CONTINUATION.new()
	if not continuation.configure_from_project_sources():
		return _fail("Fresh dispatch continuation source setup failed: " + continuation.error_message)
	var worker_entry: Dictionary = continuation.execute_synchronous_prefix(period_result)
	if not bool(worker_entry.get("ok", false)):
		return _fail("Could not derive the ROM-source bank-$18:$800C input state: " + continuation.error_message)
	var worker = WORKER_PREFIX.new()
	if not worker.configure_from_project_sources():
		return _fail("Bank-$18 worker source setup failed: " + worker.error_message)
	var result: Dictionary = worker.execute_to_yield_trampoline(worker_entry)
	if not bool(result.get("ok", false)):
		return _fail("Bank-$18 worker source execution failed: " + worker.error_message)
	if int(result.get("exit_pc", -1)) != 0xC515 or int(result.get("exit_bank", -1)) != 0x1E:
		return _fail("Worker prefix did not stop at fixed-bank $C515.")
	if not _check_source_state(result):
		return false
	return _check_retained_trace(result)


func _check_source_state(result: Dictionary) -> bool:
	var registers: Dictionary = result.get("registers", {})
	var expected_registers := {"a": 0x01, "x": 0xFF, "y": 0x00, "p": 0x20, "sp": 0x48}
	for name: String in expected_registers:
		if int(registers.get(name, -1)) != int(expected_registers[name]):
			return _fail("At $C515 register %s=%s; source/trace expects $%02X." % [name, str(registers.get(name, "missing")), int(expected_registers[name])])
	var mapper: Dictionary = result.get("mapper", {})
	if int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("Worker prefix changed the $18/$19 mapper context unexpectedly.")
	if not (result.get("mapper_writes", []) as Array).is_empty():
		return _fail("Worker prefix emitted a mapper write despite no mapper instruction in this path.")
	var ram: Dictionary = result.get("ram", {})
	var expected_ram := {"$0022": 0x00, "$0023": 0x07, "$0024": 0x18, "$0025": 0x19,
		"$0050": 0x53, "$0051": 0xB4, "$05C5": 0x00, "$05C6": 0x00}
	for address: String in expected_ram:
		if int(ram.get(address, -1)) != int(expected_ram[address]):
			return _fail("At $C515 RAM %s=%s; source expects $%02X." % [address, str(ram.get(address, "missing")), int(expected_ram[address])])
	if String(ram.get("$0700-$0704", "")) != "0100000000":
		return _fail("Worker prefix unexpectedly changed the inherited sound queue.")
	var calls: Array = result.get("calls", [])
	if calls.size() != 1:
		return _fail("Expected exactly the terminal JSR $C515; got %d calls." % calls.size())
	var call: Dictionary = calls[0]
	if int(call.get("callsite", -1)) != 0x8886 or int(call.get("target", -1)) != 0xC515 \
			or int(call.get("sp_after_push", -1)) != 0x48:
		return _fail("Terminal call does not match $8886 JSR $C515 and its source stack push.")
	if String(result.get("stack_top_sp_plus_1_to_8", "")) != "888898ef1d1ccbda":
		return _fail("The source stack return bytes at $C515 do not preserve the wrapper continuation.")
	return true


func _check_retained_trace(result: Dictionary) -> bool:
	var validation: Variant = JSON.parse_string(FileAccess.get_file_as_string(TASK_TRACE_ROOT + "validation.json"))
	if not validation is Dictionary or int(validation.get("replays", -1)) != 2 \
			or String(validation.get("normalized_event_sha256", "")) != "5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a" \
			or String(validation.get("normalized_write_sha256", "")) != "c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22":
		return _fail("The retained task trace is missing or its two-pass equality summary changed.")
	var task_rows := _read_csv(TASK_TRACE_ROOT + "task_events.csv")
	var repeat_rows := _read_csv(TASK_TRACE_ROOT + "task_events_repeat.csv")
	var first := _find_yield_row(task_rows, "1")
	var repeat := _find_yield_row(repeat_rows, "2")
	if first.is_empty() or repeat.is_empty():
		return _fail("The retained trace does not contain both first-worker $C515 boundaries.")
	var expected_fields := {
		"frame": "8460", "cycle_from_frame_start": "27552", "pc": "$C515",
		"a": "$01", "x": "$FF", "y": "$00", "p": "$20", "sp": "$48",
		"current_task_base_0000": "$05", "current_task_record_0000_0003": "FF 50 00 00",
		"mapper_shadow_0024_0025": "$18 $19", "mapper_select": "$07", "prg_map": "18/19/1E/1F",
	}
	for field: String in expected_fields:
		if String(first.get(field, "")) != String(expected_fields[field]) \
				or String(repeat.get(field, "")) != String(expected_fields[field]):
			return _fail("Two-pass $C515 trace field %s differs from the ROM-byte worker result." % field)
	var trace_stack := _stack_top_from_trace(first)
	if trace_stack != "888898ef1d1ccbda" \
			or trace_stack != String(result.get("stack_top_sp_plus_1_to_8", "")):
		return _fail("The two-pass trace stack bytes do not match the ROM-byte $C515 call stack.")
	if not _compare_ordered_writes(result.get("writes", []), _read_csv(WRITE_TRACE_ROOT + "ram_writes.csv"), first):
		return false
	return true


func _find_yield_row(rows: Array[Dictionary], pass_text: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("pass", "")) == pass_text and String(row.get("kind", "")) == "task_yield_trampoline_C515":
			return row
	return {}


func _stack_top_from_trace(row: Dictionary) -> String:
	var stack_hex := String(row.get("stack_page_0100_01ff", ""))
	if stack_hex.length() != 0x100 * 2:
		return ""
	var stack_page := PackedByteArray()
	for offset in range(0x100):
		stack_page.append(stack_hex.substr(offset * 2, 2).hex_to_int())
	var output := PackedByteArray()
	for address in range(0x49, 0x51):
		output.append(int(stack_page[address]))
	return output.hex_encode()


func _compare_ordered_writes(actual_variant: Variant, trace_rows: Array[Dictionary], boundary: Dictionary) -> bool:
	if not actual_variant is Array:
		return _fail("Worker source interpreter did not return ordered RAM writes.")
	var actual: Array[String] = []
	for write_variant in actual_variant:
		if not write_variant is Dictionary: continue
		var write: Dictionary = write_variant
		actual.append("%04X:%04X:%02X" % [int(write.get("trace_pc", write.get("pc", -1))),
			int(write.get("address", -1)), int(write.get("value", -1))])
	var actual_trace_pcs: Array[String] = []
	for write_text: String in actual:
		var pc_text := write_text.substr(0, 4)
		if not actual_trace_pcs.has(pc_text): actual_trace_pcs.append(pc_text)
	var expected: Array[String] = []
	for row: Dictionary in trace_rows:
		if String(row.get("pass", "")) != "1" or String(row.get("source_frame", "")) != String(boundary.get("frame", "")) \
				or int(row.get("cycle_from_frame_start", -1)) > int(boundary.get("cycle_from_frame_start", -1)):
			continue
		var pc_text := String(row.get("pc", "")).trim_prefix("$")
		var address := String(row.get("address", "")).trim_prefix("$").hex_to_int()
		if not actual_trace_pcs.has(pc_text): continue
		expected.append("%04X:%04X:%02X" % [pc_text.hex_to_int(), address, String(row.get("new", "")).trim_prefix("$").hex_to_int()])
	if actual != expected:
		var mismatch := 0
		while mismatch < actual.size() and mismatch < expected.size() and actual[mismatch] == expected[mismatch]:
			mismatch += 1
		return _fail("Worker ordered RAM writes differ at %d (actual %d, trace %d): %s vs %s" % [
			mismatch, actual.size(), expected.size(),
			actual[mismatch] if mismatch < actual.size() else "<end>",
			expected[mismatch] if mismatch < expected.size() else "<end>",
		])
	return true


func _read_csv(path: String) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(path)
	var lines := text.split("\n", false)
	if lines.is_empty(): return output
	var headers := lines[0].split(",")
	for line_index in range(1, lines.size()):
		var values := lines[line_index].split(",")
		if values.size() != headers.size(): continue
		var row: Dictionary = {}
		for column in range(headers.size()): row[String(headers[column])] = values[column]
		output.append(row)
	return output


func _fail(message: String) -> bool:
	push_error(message)
	return false
