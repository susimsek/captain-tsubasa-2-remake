extends SceneTree

const READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")

const BRANCHES: Array[Dictionary] = [
	{
		"ram_044E": 1,
		"selector_x": 0,
		"skip_byte": 0x02,
		"resume_byte_offset": 9,
		"target_cpu_address": 0xB49E,
		"target_file_offset": 0x0234AE,
		"target_path": "res://reference/rom_extract/gameplay/pass_scenario_1c/bank10_F3_root_target_B49E_B4A6.bin",
		"target_sha256": "1a650937b1815dc4ab5a30a1da70eb4e3c4bad7059005d1fbb585995936db5e2",
		"target_bytes": [0xF9, 0x1D, 0x2C, 0x3C, 0x01, 0x78, 0x58, 0xFB],
		"record_bytes": [0x3C, 0x01, 0x78, 0x58],
		"expected_0523": 0x3C,
	},
	{
		"ram_044E": 2,
		"selector_x": 1,
		"skip_byte": 0x04,
		"resume_byte_offset": 12,
		"target_cpu_address": 0xB4B6,
		"target_file_offset": 0x0234C6,
		"target_path": "res://reference/rom_extract/gameplay/pass_scenario_1c/bank10_F3_root_target_B4B6_B4BE.bin",
		"target_sha256": "c2b1fab616d39995a449dc04d7893b270cb637df53a52ba54954c96de5d42915",
		"target_bytes": [0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB],
		"record_bytes": [0x38, 0x63, 0x7A, 0x58],
		"expected_0523": 0x38,
	},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for branch: Dictionary in BRANCHES:
		_verify_branch(branch)

	if _failures.is_empty():
		print("PASS: scenario-$1C F3 $84 selects B49E/B4B6 from live $044E and the ROM bytecode reader decodes both target records, including B4B6 $0523=$38")
		print("LIMIT: this parser verifier decodes source-pinned branch streams but does not exercise the live slot-$09 callback/worker lifecycle; see tools/diagnostics/verify_rom_bank10_pass_scenario1c_runtime.gd for focused scenario-runtime checks")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _verify_branch(branch: Dictionary) -> void:
	var incoming_044e := int(branch["ram_044E"])
	var root: Dictionary = READER_SCRIPT.read_project_scenario(0x1C, {"ram_044E": incoming_044e})
	var tokens: Array = root.get("tokens", [])
	var f3 := _find_opcode(tokens, 0xF3, 5)
	var f2 := _find_opcode(tokens, 0xF2)
	var target := int(branch["target_cpu_address"])
	var target_name := "$%04X" % target

	_check(str(f3.get("status", "")) == "selected"
		and int(f3.get("ram_044E", -1)) == incoming_044e
		and int(f3.get("selector_result_x", -1)) == int(branch["selector_x"])
		and int(f3.get("skip_byte", -1)) == int(branch["skip_byte"])
		and int(f3.get("resume_byte_offset", -1)) == int(branch["resume_byte_offset"])
		and int(f3.get("selected_f2_pointer", -1)) == target,
		"live RAM $044E=$%02X executes the decoded F3 $84 branch to %s" % [incoming_044e, target_name])
	_check(int(root.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED
		and int(f2.get("target_cpu_address", -1)) == target
		and int(f2.get("target_file_offset", -1)) == int(branch["target_file_offset"])
		and str(f2.get("target_prefix_sha256", "")) == str(branch["target_sha256"]),
		"selected F2 %s matches the source offset and pinned target digest" % target_name)

	var target_path := str(branch["target_path"])
	var target_bytes := FileAccess.get_file_as_bytes(target_path)
	var expected_bytes := PackedByteArray(branch["target_bytes"])
	_check(target_bytes == expected_bytes
		and _sha256_hex(target_bytes) == str(branch["target_sha256"])
		and f2.get("target_prefix_bytes", []) == branch["target_bytes"],
		"%s extracted ROM stream matches the reader's branch metadata" % target_name)
	if target_bytes != expected_bytes or _sha256_hex(target_bytes) != str(branch["target_sha256"]):
		return

	var parsed: Dictionary = READER_SCRIPT.parse_bytes(0x1C, target_bytes, target_path)
	var event_record := _find_event_record(parsed.get("tokens", []))
	var assignments: Dictionary = event_record.get("ram_assignments", {})
	_check(int(parsed.get("terminal_status", -1)) == READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED
		and event_record.get("raw_bytes", PackedByteArray()) == PackedByteArray(branch["record_bytes"])
		and int(event_record.get("byte_offset", -1)) == 3
		and int(assignments.get("$0523", -1)) == int(branch["expected_0523"])
		and int(assignments.get("$0524", -1)) == int(branch["record_bytes"][1])
		and int(assignments.get("$0528", -1)) == int(branch["record_bytes"][2])
		and int(assignments.get("$0529", -1)) == int(branch["record_bytes"][3]),
		"%s four-byte ROM record decodes at +3 to $0523=$%02X and its remaining assignments" % [
			target_name, int(branch["expected_0523"])
		])


func _find_opcode(tokens: Array, opcode: int, byte_offset: int = -1) -> Dictionary:
	for token_variant in tokens:
		if not token_variant is Dictionary:
			continue
		var token := token_variant as Dictionary
		if int(token.get("opcode", -1)) == opcode \
				and (byte_offset < 0 or int(token.get("byte_offset", -1)) == byte_offset):
			return token
	return {}


func _find_event_record(tokens: Array) -> Dictionary:
	for token_variant in tokens:
		if token_variant is Dictionary and str((token_variant as Dictionary).get("kind", "")) == "event_record":
			return token_variant as Dictionary
	return {}


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK or hashing.update(bytes) != OK:
		return ""
	return hashing.finish().hex_encode()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
