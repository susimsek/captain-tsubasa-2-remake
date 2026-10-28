extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PERIOD_TASK := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const CONTINUATION := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const TRACE_ROOT := "res://reference/diagnostics/fresh_period_daaa_trace_20261028_135904_utc/"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-byte fresh match-zero continuation reaches the first bank-$18:$800C worker entry with matching registers, mapper, RAM effects, and trace call boundary.")
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
		return _fail("Continuation source setup failed: " + continuation.error_message)
	var result: Dictionary = continuation.execute_synchronous_prefix(period_result)
	if not bool(result.get("ok", false)):
		return _fail("Synchronous ROM continuation failed: " + continuation.error_message)
	if int(result.get("exit_pc", -1)) != 0x800C or int(result.get("exit_bank", -1)) != 0x18:
		return _fail("ROM continuation did not stop at bank-$18:$800C.")
	var regs: Dictionary = result.get("registers", {})
	var expected_regs := {"a": 0x00, "x": 0x00, "y": 0x00, "p": 0x23, "sp": 0x4A}
	for name: String in expected_regs:
		if int(regs.get(name, -1)) != int(expected_regs[name]):
			return _fail("At bank-$18:$800C register %s=%s; trace comparison expects $%02X." % [name, str(regs.get(name, "missing")), int(expected_regs[name])])
	var mapper: Dictionary = result.get("mapper", {})
	if int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("ROM helper did not leave the source mapper at $18/$19, select $07.")
	var mapper_writes: Array = result.get("mapper_writes", [])
	var expected_mapper_pairs: Array[String] = []
	for map_pair: Array in [[0x06, 0x1A, 0x07, 0x1B], [0x06, 0x1C, 0x07, 0x1D], [0x06, 0x18, 0x07, 0x19]]:
		expected_mapper_pairs.append("8000:%02X" % map_pair[0])
		expected_mapper_pairs.append("8001:%02X" % map_pair[1])
		expected_mapper_pairs.append("8000:%02X" % map_pair[2])
		expected_mapper_pairs.append("8001:%02X" % map_pair[3])
	var actual_mapper_pairs: Array[String] = []
	for mapper_write_variant in mapper_writes:
		if mapper_write_variant is Dictionary:
			actual_mapper_pairs.append("%04X:%02X" % [int(mapper_write_variant.get("address", -1)), int(mapper_write_variant.get("value", -1))])
	if actual_mapper_pairs != expected_mapper_pairs:
		return _fail("The ROM-derived MMC3 write order differs from the three source helper calls.")
	var ram: Dictionary = result.get("ram", {})
	var expected_ram := {"$0022": 0x00, "$0023": 0x07, "$0024": 0x18, "$0025": 0x19,
		"$002E": 0x00, "$002F": 0x00, "$0034": 0xFC, "$0035": 0x03,
		"$0446": 0x00, "$0447": 0x00, "$044B": 0x00, "$044F": 0x00,
		"$05FB": 0x00, "$0629": 0x00}
	for address: String in expected_ram:
		if int(ram.get(address, -1)) != int(expected_ram[address]):
			return _fail("At bank-$18:$800C RAM %s=%s; source/trace boundary expects $%02X." % [address, str(ram.get(address, "missing")), int(expected_ram[address])])
	if String(ram.get("$0700-$0704", "")) != "0100000000":
		return _fail("$CBF1 did not occupy only the first source sound-queue slot.")
	if not _check_trace_boundary(result):
		return false
	return true


func _check_trace_boundary(result: Dictionary) -> bool:
	var validation_path := TRACE_ROOT + "validation.json"
	var validation: Variant = JSON.parse_string(FileAccess.get_file_as_string(validation_path))
	if not validation is Dictionary or int(validation.get("replays", -1)) != 2 \
			or String(validation.get("replay_endpoint", "")) != "$DAD8" \
			or String(validation.get("normalized_call_sha256", "")) != "af0d5fe7cd4a7f1a4abe96a921c287d9d2adcca80e1d54cc292ff29406e01ea0" \
			or String(validation.get("normalized_ram_write_sha256", "")) != "57d88263d38a854a481ccd21202353ea7c9901dc8a690f4864c8c4358600a694":
		return _fail("The two-pass FCEUX source trace is missing or failed its retained equality summary.")
	var call_rows := _read_csv(TRACE_ROOT + "call_boundaries.csv")
	if call_rows.is_empty(): return _fail("The retained FCEUX call-boundary CSV is missing.")
	var worker := _find_trace_row(call_rows, "bank18_entry_800C")
	if worker.is_empty() or int(worker.get("source_frame", -1)) != 8460 \
			or int(worker.get("cycle_from_frame_start", -1)) != 27472 \
			or String(worker.get("pc", "")).trim_prefix("$").hex_to_int() != 0x800C \
			or worker.get("a") != "$00" or worker.get("x") != "$00" or worker.get("y") != "$00" \
			or worker.get("p") != "$23" or worker.get("sp") != "$4A" \
			or worker.get("prg_map") != "18/19/1E/1F":
		return _fail("The retained two-pass FCEUX bank-$18:$800C entry boundary no longer matches the source result.")
	if String(result.get("stack_top_sp_plus_1_to_8", "")).replace(" ", "").to_lower() \
			!= String(worker.get("stack_top_sp_plus_1_to_8", "")).replace(" ", "").to_lower() \
			or String(worker.get("stack_top_sp_plus_1_to_8", "")).replace(" ", "").to_lower() != "98ef1d1ccbda1dd1":
		return _fail("The source-owned stack continuation at bank-$18:$800C differs from the retained FCEUX stack bytes.")
	var trace_calls: Array[String] = []
	for row: Dictionary in call_rows:
		if int(row.get("source_frame", -1)) != 8460 or int(row.get("cycle_from_frame_start", -1)) > int(worker["cycle_from_frame_start"]):
			continue
		var event_name := String(row.get("event", ""))
		if event_name in ["fresh_match_dispatch_DB24", "fresh_opponent_branch_DB34", "mapper_helper_CE2D", "bank1c_entry_8003", "return_bank1c_8003_DB46", "return_DB24_DAC7", "fade_call_1_EF7F", "bank18_wrapper_EF7F", "wrapper_map_call_CE2D", "return_wrapper_map_EF95", "bank18_call_800C", "bank18_entry_800C"]:
			trace_calls.append(event_name)
	var expected_trace_subsequence: Array[String] = ["mapper_helper_CE2D", "fresh_match_dispatch_DB24", "fresh_opponent_branch_DB34",
		"mapper_helper_CE2D", "bank1c_entry_8003", "return_bank1c_8003_DB46", "return_DB24_DAC7",
		"fade_call_1_EF7F", "bank18_wrapper_EF7F", "wrapper_map_call_CE2D", "mapper_helper_CE2D", "return_wrapper_map_EF95",
		"bank18_call_800C", "bank18_entry_800C"]
	if trace_calls != expected_trace_subsequence:
		return _fail("The observed fresh selector/branch/wrapper boundaries differ from the expected source call path: %s" % str(trace_calls))
	var actual_calls: Array[String] = []
	for call_variant in result.get("calls", []):
		if call_variant is Dictionary:
			actual_calls.append("$%04X" % int(call_variant.get("target", -1)))
	var source_key_calls: Array[String] = ["$CBF1", "$CF4F"]
	for _index in range(22): source_key_calls.append("$CD7C")
	source_key_calls.append_array(["$CE2D", "$8039", "$DB24", "$CB99", "$CE2D", "$8003"])
	for _index in range(11): source_key_calls.append("$C50C")
	source_key_calls.append_array(["$EF7F", "$CE2D", "$800C"])
	if actual_calls != source_key_calls:
		return _fail("Source call stream mismatch at the first worker entry (%d calls; expected %d)." % [actual_calls.size(), source_key_calls.size()])
	if not _compare_ordered_writes(result.get("writes", []), _read_csv(TRACE_ROOT + "ram_writes.csv"), worker):
		return false
	return true


func _compare_ordered_writes(actual_variant: Variant, trace_rows: Array[Dictionary], boundary: Dictionary) -> bool:
	if not actual_variant is Array:
		return _fail("Source interpreter did not return an ordered internal-RAM write stream.")
	var actual: Array[String] = []
	for write_variant in actual_variant:
		if not write_variant is Dictionary: continue
		var write: Dictionary = write_variant
		if int(write["address"]) >= 0x0100 and int(write["address"]) < 0x0200: continue
		actual.append("%04X:%04X:%02X" % [int(write.get("trace_pc", write["pc"])), int(write["address"]), int(write["value"])])
	var expected: Array[String] = []
	for row: Dictionary in trace_rows:
		if int(row.get("source_frame", -1)) != 8460 or int(row.get("cycle_from_frame_start", -1)) > int(boundary["cycle_from_frame_start"]):
			continue
		var pc_text := String(row.get("pc", ""))
		var address := String(row.get("address", "")).trim_prefix("$").hex_to_int()
		if address >= 0x0100 and address < 0x0200: continue
		if not _contains_pc(actual, pc_text): continue
		expected.append("%04X:%04X:%02X" % [pc_text.trim_prefix("$").hex_to_int(),
			address, String(row["new"]).trim_prefix("$").hex_to_int()])
	if actual != expected:
		var mismatch := 0
		while mismatch < actual.size() and mismatch < expected.size() and actual[mismatch] == expected[mismatch]:
			mismatch += 1
		return _fail("Ordered writes differ at index %d (actual %d, trace %d): actual=%s trace=%s" % [
			mismatch, actual.size(), expected.size(),
			actual[mismatch] if mismatch < actual.size() else "<end>",
			expected[mismatch] if mismatch < expected.size() else "<end>",
		])
	return true


func _contains_pc(writes: Array[String], pc_text: String) -> bool:
	var prefix := pc_text.trim_prefix("$") + ":"
	for write: String in writes:
		if write.begins_with(prefix): return true
	return false


func _read_csv(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(path)
	var lines := text.split("\n", false)
	if lines.is_empty(): return result
	var headers := lines[0].split(",")
	for index in range(1, lines.size()):
		var values := lines[index].split(",")
		if values.size() != headers.size(): continue
		var row: Dictionary = {}
		for column in range(headers.size()): row[String(headers[column])] = values[column]
		result.append(row)
	return result


func _find_trace_row(rows: Array[Dictionary], event_name: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("event", "")) == event_name: return row
	return {}


func _fail(message: String) -> bool:
	push_error(message)
	return false
