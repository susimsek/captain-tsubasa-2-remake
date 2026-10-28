extends SceneTree

const TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_period_task.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-byte slot-$05 fresh-period slice derives $0629, $05F7-$05F9, and SP=$50 before reaching JMP $DAAA.")
	quit(0)


func _verify() -> bool:
	var task = TASK_SCRIPT.new()
	if not task.configure_from_project_sources():
		return _fail("Could not configure hash-checked fresh-period source: " + task.error_message)
	var inputs := {
		"task_slot_base": 0x05,
		"entry_pc": 0xD11E,
		"entry_sp": 0x52,
		"period_0027": 0x00,
		"opponent_id_002b": 0x03,
		"source_context": {
			"kind": "caller_owned_decoded_game_logic",
			"source_event": "initial slot-$05 dispatch from the ROM fresh-game scheduler",
		},
	}
	var result: Dictionary = task.execute_fresh_match_zero(inputs)
	if not bool(result.get("ok", false)):
		return _fail("ROM-derived fresh-period execution failed: " + task.error_message)
	if int(result.get("exit_pc", -1)) != 0xDAAA or int(result.get("exit_sp", -1)) != 0x50:
		return _fail("Fresh-period path did not reach $DAAA with the ROM-derived stack pointer $50.")
	var ram: Dictionary = result.get("ram", {})
	var expected := {
		"$003A": 0x00,
		"$0613": 0x00,
		"$0629": 0x00,
		"$063E": 0x00,
		"$0640": 0x00,
		"$0641": 0x00,
		"$05F7": 0xB4,
		"$05F8": 0x00,
		"$05F9": 0x00,
	}
	for address: String in expected:
		if int(ram.get(address, -1)) != int(expected[address]):
			return _fail("Derived RAM %s is %s; expected %s." % [address, str(ram.get(address, "missing")), str(expected[address])])
	if not _has_instruction(result, 0xD14F, 0x8D) \
			or not _has_instruction(result, 0xD16C, 0xBD) \
			or not _has_instruction(result, 0xD17F, 0x9A) \
			or not _has_instruction(result, 0xD180, 0x4C):
		return _fail("Execution trace omitted a required selector/table/SP/exit source instruction.")
	if not _has_write(result, 0xD14F, 0x0629, 0x00) \
			or not _has_write(result, 0xD16F, 0x05F7, 0xB4) \
			or not _has_write(result, 0xD175, 0x05F8, 0x00) \
			or not _has_write(result, 0xD17A, 0x05F9, 0x00):
		return _fail("Instruction trace did not derive the selector/camera outputs from ROM stores.")
	if String(result.get("source_code_sha256", "")) != "28895a5c3512a45e1b1a59c4324654ec03bb5f2ea413445e32333aa3bd6b87cc" \
			or String(result.get("camera_table_sha256", "")) != "0e1862b77227e30a4b6f6d40295f173db76d2473f8b9e31b241239c07a5837fa":
		return _fail("Execution result did not retain the verified code and table hashes.")
	if not _expect_rejection(task, inputs, "period_0027", 4):
		return false
	if not _expect_rejection(task, inputs, "opponent_id_002b", 2):
		return false
	var missing_context := inputs.duplicate(true)
	missing_context.erase("source_context")
	if not task.execute_fresh_match_zero(missing_context).is_empty() or task.error_message.is_empty():
		return _fail("The isolated slice accepted missing caller-owned source context.")
	return true


func _has_instruction(result: Dictionary, pc: int, opcode: int) -> bool:
	for instruction_variant in result.get("instructions", []):
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			if int(instruction.get("pc", -1)) == pc and int(instruction.get("opcode", -1)) == opcode:
				return true
	return false


func _has_write(result: Dictionary, pc: int, address: int, value: int) -> bool:
	for write_variant in result.get("writes", []):
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("pc", -1)) == pc and int(write.get("address", -1)) == address \
					and int(write.get("value", -1)) == value:
				return true
	return false


func _expect_rejection(task, base_inputs: Dictionary, key: String, value: int) -> bool:
	var invalid_inputs := base_inputs.duplicate(true)
	invalid_inputs[key] = value
	if not task.execute_fresh_match_zero(invalid_inputs).is_empty() or task.error_message.is_empty():
		return _fail("The isolated slice accepted unsupported caller input %s=%d." % [key, value])
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
