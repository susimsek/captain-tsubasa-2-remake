extends SceneTree

const READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")

const EXPECTED_EVENT_RECORDS: Dictionary = {
	0x1E: [{"offset": 5, "selector": 0x90, "bytes": [0x07, 0x45, 0x90, 0xF0]}],
	0x35: [{"offset": 3, "selector": 0x8F, "bytes": [0x02, 0x3A, 0x8F, 0x73]}],
	0x44: [{"offset": 0, "selector": 0x5C, "bytes": [0x02, 0x70, 0x5C, 0xF0]}],
	0x36: [
		{"offset": 4, "selector": 0x8F, "bytes": [0x10, 0x3A, 0x8F, 0xF0]},
		{"offset": 11, "selector": 0x4E, "bytes": [0x20, 0x0C, 0x4E, 0x74]},
		{"offset": 20, "selector": 0x66, "bytes": [0x32, 0x72, 0x66, 0xF0]},
		{"offset": 26, "selector": 0x4C, "bytes": [0x32, 0x1F, 0x4C, 0xF0]},
		{"offset": 33, "selector": 0xE6, "bytes": [0x3E, 0x01, 0xE6, 0x75]},
	],
}

const EXPECTED_INLINE_TRANSFORMS: Array[Dictionary] = [
	{"handler": 0x8991, "file": 0x0209A1, "table_file": 0x0209A7, "table_bytes": [0x99, 0x89], "target": 0x8999, "target_file": 0x0209A9, "target_bytes": [0xA9, 0xFF, 0x60]},
	{"handler": 0x899C, "file": 0x0209AC, "table_file": 0x0209B2, "table_bytes": [0xA4, 0x89], "target": 0x89A4, "target_file": 0x0209B4, "target_bytes": [0xA9, 0xFF, 0x60]},
	{"handler": 0x89A7, "file": 0x0209B7, "table_file": 0x0209BD, "table_bytes": [0xB1, 0x89], "target": 0x89B1, "target_file": 0x0209C1, "target_bytes": [0xA9, 0xFF, 0x60]},
]

const EXPECTED_FLAG_HANDLERS: Dictionary = {
	0xF4: {"cpu": 0x87E0, "file": 0x0207F0, "bytes": [0xA9, 0x40, 0x8D, 0x2A, 0x05, 0x60], "result": 0x40},
	0xF5: {"cpu": 0x87E6, "file": 0x0207F6, "bytes": [0xA9, 0x00, 0x8D, 0x2A, 0x05, 0x60], "result": 0x00},
	0xF6: {"cpu": 0x87EC, "file": 0x0207FC, "bytes": [0xA9, 0x40, 0x4D, 0x2A, 0x05, 0x8D, 0x2A, 0x05, 0x60]},
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenario_35: Dictionary = READER_SCRIPT.read_project_scenario(0x35)
	_check(int(scenario_35.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
		"scenario $35 stops at its first external $FB return")
	_check(not bool(scenario_35.get("context_required", true)),
		"scenario $35's decoded prefix needs no unavailable transform context")
	_check(_event_records_match(scenario_35, 0x35),
		"scenario $35 event record and selector match source bytes at +3")
	_check(_word_write_at(scenario_35, 0, 0x44EB),
		"scenario $35 $F9 writes low/high bytes EB/44 to $0530/$0531")
	var scenario_35_root: Dictionary = READER_SCRIPT.read_project_scenario(0x35,
		{"continuation_depth": 0})
	_check(int(scenario_35_root.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
		"hash-checked scenario $35 at caller-owned depth zero ends at its root $FB terminator")

	var scenario_1e_context_zero: Dictionary = READER_SCRIPT.read_project_scenario(0x1E,
		{"ram_05FB": 0x00, "continuation_depth": 0})
	_check(int(scenario_1e_context_zero.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
		"scenario $1E reaches root $FB with its transform input and caller depth zero supplied")
	_check(not bool(scenario_1e_context_zero.get("context_required", true)),
		"scenario $1E transform state resolves with caller-supplied $05FB=$00")
	_check(int(scenario_1e_context_zero.get("ram_state", {}).get("ram_052A", -1)) == 0x40,
		"$FD $02 result $00 followed by $F6 yields $052A=$40 when $05FB=$00")
	_check(_event_records_match(scenario_1e_context_zero, 0x1E),
		"scenario $1E selector $90 is parsed at source byte +5")
	_check(_fd_handler_evidence(scenario_1e_context_zero, 0x02, 0x88B5, 0x0208C5,
		[0xB5, 0x88], [0xA2, 0x00, 0xAD, 0xFB, 0x05, 0xF0, 0x02, 0xA2, 0x40, 0x60], "transformed"),
		"$FD $02 dispatch bytes and $88B5 handler offset/bytes match target-ROM evidence")

	var scenario_1e_context_nonzero: Dictionary = READER_SCRIPT.read_project_scenario(0x1E, {"ram_05FB": 0x01})
	_check(int(scenario_1e_context_nonzero.get("ram_state", {}).get("ram_052A", -1)) == 0x00,
		"$FD $02 result $40 followed by $F6 yields $052A=$00 when $05FB is nonzero")

	var scenario_1e_missing_context: Dictionary = READER_SCRIPT.read_project_scenario(0x1E,
		{"continuation_depth": 0})
	_check(int(scenario_1e_missing_context.get("status", -1)) == READER_SCRIPT.ParseStatus.CONTEXT_REQUIRED,
		"$FD $02 without $05FB reports context-required status")
	_check(bool(scenario_1e_missing_context.get("context_required", false)),
		"missing $05FB context is retained in the parse result")
	_check(int(scenario_1e_missing_context.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
		"missing transform data does not obscure the separately verified root $FB terminal status")

	var scenario_36: Dictionary = READER_SCRIPT.read_project_scenario(0x36)
	_check(int(scenario_36.get("status", -1)) == READER_SCRIPT.ParseStatus.CONTEXT_REQUIRED,
		"scenario $36 reaches $FB but preserves the unresolved $FD $00 context requirement")
	_check(int(scenario_36.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
		"scenario $36 without a continuation depth remains external at its $FB")
	_check(_event_records_match(scenario_36, 0x36),
		"all five scenario $36 event-record selectors and byte offsets are retained")
	_check(int(scenario_36.get("ram_state", {}).get("ram_052A", -1)) == -1,
		"unresolved $FD $00 result is not replaced with a guessed $052A value")
	var scenario_36_root: Dictionary = READER_SCRIPT.read_project_scenario(0x36,
		{"continuation_depth": 0})
	_check(int(scenario_36_root.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
		"exact scenario $36 bytes terminate at root $FB despite an earlier unresolved transform")
	_check(_fd_handler_evidence(scenario_36, 0x00, 0x8877, 0x020887,
		[0x77, 0x88], [0xA9, 0x00, 0x85, 0x3B, 0xAD, 0x41, 0x04, 0x20, 0x0C, 0xC5, 0xAD, 0x38, 0x06, 0x20, 0x36, 0xC5]),
		"$FD $00 raw operand, target, offsets, and context-dependent handler bytes are exposed")
	_check(_byte_write_at(scenario_36, 24, 0xF7, 0x02, "$052B", 0x02),
		"scenario $36 $F7 $02 writes $02 to $052B at byte +24")

	var scenario_44: Dictionary = READER_SCRIPT.read_project_scenario(0x44)
	_check(int(scenario_44.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
		"scenario $44 decodes its source record then stops at the unresolved $FB continuation")
	_check(not bool(scenario_44.get("context_required", true)),
		"scenario $44 record fields and inline $F0 parameter transform need no missing input")
	_check(_event_records_match(scenario_44, 0x44),
		"scenario $44 preserves callback $70 and actor animation $5C from source bytes at +0")
	_check(int(scenario_44.get("ram_state", {}).get("ram_0523", -1)) == 0x02
		and int(scenario_44.get("ram_state", {}).get("ram_0524", -1)) == 0x70
		and int(scenario_44.get("ram_state", {}).get("ram_0528", -1)) == 0x5C
		and int(scenario_44.get("ram_state", {}).get("ram_0529", -1)) == 0xFF,
		"scenario $44 maps its four source bytes to $0523/$0524/$0528/$0529 without merging callback and animation IDs")
	_check(_has_control_flow_opcode(scenario_44, 0xFB),
		"scenario $44's trailing $FB remains an external continuation instead of guessed route state")
	var scenario_44_root: Dictionary = READER_SCRIPT.read_project_scenario(0x44,
		{"continuation_depth": 0})
	_check(int(scenario_44_root.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
		"exact scenario $44 source ends at the root terminator when depth zero is supplied")
	var scenario_44_nested: Dictionary = READER_SCRIPT.read_project_scenario(0x44,
		{"continuation_depth": 2})
	_check(int(scenario_44_nested.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
		"scenario $44 at nested depth preserves its external return target")
	var altered_44_bytes := FileAccess.get_file_as_bytes(
		"res://reference/rom_extract/gameplay/first_command_scenarios/scenario_44.bin")
	altered_44_bytes[0] = 0x03
	var altered_44: Dictionary = READER_SCRIPT.parse_bytes(0x44, altered_44_bytes,
		"synthetic altered scenario $44", {"continuation_depth": 0})
	_check(int(altered_44.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED,
		"altered/non-route scenario bytes do not inherit a validated root termination status")

	_check(_inline_transform_records_match(),
		"$F0 in each record field uses its matching $8991/$899C/$89A7 index-zero stub and returns $FF")
	_check(_flag_handler_results_match(),
		"$F4/$F5/$F6 apply their exact $052A effects from target-ROM handlers")

	var f3_result: Dictionary = READER_SCRIPT.parse_bytes(0x36, PackedByteArray([0xF3]))
	_check(int(f3_result.get("status", -1)) == READER_SCRIPT.ParseStatus.UNSUPPORTED_HANDLER,
		"unimplemented conditional $F3 handler returns an explicit unsupported status")
	_check(int(f3_result.get("unsupported_opcode", -1)) == 0xF3,
		"unsupported status identifies opcode $F3")

	var bad_inline_result: Dictionary = READER_SCRIPT.parse_bytes(0x36,
		PackedByteArray([0x01, 0xF1, 0x02, 0x03]))
	_check(int(bad_inline_result.get("status", -1)) == READER_SCRIPT.ParseStatus.UNSUPPORTED_TRANSFORM,
		"unverified inline dispatch index $F1 returns an explicit unsupported-transform status")

	var truncated_result: Dictionary = READER_SCRIPT.parse_bytes(0x35, PackedByteArray([0xF9, 0xEB]))
	_check(int(truncated_result.get("status", -1)) == READER_SCRIPT.ParseStatus.TRUNCATED_INPUT,
		"truncated $F9 operand does not read beyond the supplied span")

	var record_with_f0_result: Dictionary = READER_SCRIPT.parse_bytes(
		0x1E, PackedByteArray([0x01, 0x02, 0x90, 0xF0]))
	var record_tokens: Array = record_with_f0_result.get("tokens", [])
	_check(int(record_with_f0_result.get("status", -1)) == READER_SCRIPT.ParseStatus.PARSED_TO_SPAN_END
		and record_tokens.size() == 1
		and str(record_tokens[0].get("kind", "")) == "event_record"
		and int(record_tokens[0].get("ram_assignments", {}).get("$0529", -1)) == 0xFF,
		"$F0 in field four remains a record transform and resolves to $FF, not a top-level opcode")

	if _failures.is_empty():
		print("PASS: bank-$10 route records, verified depth-zero root $FB endings, nested/non-route external stops, and existing opcode transforms")
		print("LIMIT: FD $00 output, callback/worker lifecycle, and nested continuation execution remain unmodeled")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _event_records_match(result: Dictionary, scenario_id: int) -> bool:
	var expected: Array = EXPECTED_EVENT_RECORDS[scenario_id]
	var tokens: Array = result.get("tokens", [])
	var found: Array[Dictionary] = []
	for token: Dictionary in tokens:
		if str(token.get("kind", "")) == "event_record":
			found.append(token)
	if found.size() != expected.size():
		return false
	for index: int in expected.size():
		var actual: Dictionary = found[index]
		var wanted: Dictionary = expected[index]
		var actual_bytes: PackedByteArray = actual.get("raw_bytes", PackedByteArray())
		var assignments: Dictionary = actual.get("ram_assignments_before_inline_transformers", {})
		if int(actual.get("byte_offset", -1)) != int(wanted["offset"]):
			return false
		if int(assignments.get("$0528", -1)) != int(wanted["selector"]):
			return false
		if actual_bytes != PackedByteArray(wanted["bytes"]):
			return false
	return true


func _has_control_flow_opcode(result: Dictionary, opcode: int) -> bool:
	for token: Dictionary in result.get("tokens", []):
		if str(token.get("kind", "")) == "control_flow" \
				and int(token.get("opcode", -1)) == opcode:
			return true
	return false


func _inline_transform_records_match() -> bool:
	var result: Dictionary = READER_SCRIPT.parse_bytes(0x36,
		PackedByteArray([0x01, 0xF0, 0xF0, 0xF0]))
	var tokens: Array = result.get("tokens", [])
	if tokens.size() != 1:
		return false
	var token: Dictionary = tokens[0]
	var transforms: Array = token.get("transformations", [])
	if transforms.size() != EXPECTED_INLINE_TRANSFORMS.size():
		return false
	for index: int in EXPECTED_INLINE_TRANSFORMS.size():
		var actual: Dictionary = transforms[index]
		var expected: Dictionary = EXPECTED_INLINE_TRANSFORMS[index]
		if int(actual.get("transformer_cpu_address", -1)) != expected["handler"]:
			return false
		if int(actual.get("transformer_file_offset", -1)) != expected["file"]:
			return false
		if int(actual.get("inline_table_file_offset", -1)) != expected["table_file"]:
			return false
		if actual.get("inline_table_bytes", []) != expected["table_bytes"]:
			return false
		if int(actual.get("dispatch_target_cpu_address", -1)) != expected["target"]:
			return false
		if int(actual.get("dispatch_target_file_offset", -1)) != expected["target_file"]:
			return false
		if actual.get("dispatch_target_bytes", []) != expected["target_bytes"]:
			return false
		if int(actual.get("value", -1)) != 0xFF:
			return false
	var assignments: Dictionary = token.get("ram_assignments", {})
	return int(assignments.get("$0524", -1)) == 0xFF \
		and int(assignments.get("$0528", -1)) == 0xFF \
		and int(assignments.get("$0529", -1)) == 0xFF


func _flag_handler_results_match() -> bool:
	for opcode: int in [0xF4, 0xF5]:
		var result: Dictionary = READER_SCRIPT.parse_bytes(0x36,
			PackedByteArray([opcode, 0xFB]))
		var tokens: Array = result.get("tokens", [])
		if tokens.size() < 1:
			return false
		var token: Dictionary = tokens[0]
		var expected: Dictionary = EXPECTED_FLAG_HANDLERS[opcode]
		if int(token.get("handler_cpu_address", -1)) != expected["cpu"]:
			return false
		if int(token.get("handler_file_offset", -1)) != expected["file"]:
			return false
		if token.get("handler_bytes", []) != expected["bytes"]:
			return false
		if int(result.get("ram_state", {}).get("ram_052A", -1)) != expected["result"]:
			return false
	var f6: Dictionary = READER_SCRIPT.parse_bytes(0x36, PackedByteArray([0xF6, 0xFB]),
		"", {"ram_052A": 0x40})
	var f6_tokens: Array = f6.get("tokens", [])
	if f6_tokens.is_empty():
		return false
	var f6_token: Dictionary = f6_tokens[0]
	var f6_expected: Dictionary = EXPECTED_FLAG_HANDLERS[0xF6]
	return int(f6_token.get("handler_cpu_address", -1)) == f6_expected["cpu"] \
		and int(f6_token.get("handler_file_offset", -1)) == f6_expected["file"] \
		and f6_token.get("handler_bytes", []) == f6_expected["bytes"] \
		and int(f6.get("ram_state", {}).get("ram_052A", -1)) == 0x00


func _fd_handler_evidence(result: Dictionary, operand: int, target_cpu: int,
		target_file: int, table_entry_bytes: Array, handler_bytes: Array,
		expected_status: String = "context_required") -> bool:
	for token: Dictionary in result.get("tokens", []):
		if int(token.get("opcode", -1)) != 0xFD or int(token.get("operand", -1)) != operand:
			continue
		return int(token.get("fd_handler_cpu_address", -1)) == 0x885D \
			and int(token.get("fd_handler_file_offset", -1)) == 0x02086D \
			and token.get("fd_handler_bytes", []) == [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x20, 0x6A, 0x88, 0x8E, 0x2A, 0x05, 0x60] \
			and int(token.get("handler_target_cpu_address", -1)) == target_cpu \
			and int(token.get("handler_target_file_offset", -1)) == target_file \
			and int(token.get("dispatch_table_file_offset", -1)) == 0x02087D \
			and token.get("dispatch_table_entry_bytes", []) == table_entry_bytes \
			and token.get("handler_bytes", token.get("handler_bytes_prefix", [])) == handler_bytes \
			and str(token.get("status", "")) == expected_status
	return false


func _word_write_at(result: Dictionary, byte_offset: int, expected: int) -> bool:
	for token: Dictionary in result.get("tokens", []):
		if int(token.get("opcode", -1)) == 0xF9 and int(token.get("byte_offset", -1)) == byte_offset:
			return int(token.get("operand_word_little_endian", -1)) == expected \
				and int(token.get("handler_file_offset", -1)) == 0x020819 \
				and token.get("handler_bytes", []) == [0xA4, 0x3A, 0xB1, 0x5D, 0x8D, 0x30, 0x05, 0xC8, 0xB1, 0x5D, 0x8D, 0x31, 0x05]
	return false


func _byte_write_at(result: Dictionary, byte_offset: int, opcode: int,
		operand: int, destination: String, expected: int) -> bool:
	for token: Dictionary in result.get("tokens", []):
		if int(token.get("opcode", -1)) == opcode and int(token.get("byte_offset", -1)) == byte_offset:
			return int(token.get("operand", -1)) == operand \
				and int(token.get("ram_write", {}).get(destination, -1)) == expected \
				and int(token.get("handler_file_offset", -1)) == 0x020805 \
				and token.get("handler_bytes", []) == [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60]
	return false


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
