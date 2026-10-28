extends SceneTree

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const COPY_SOURCE_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_prg_ram_copy_source_ACB0_BFFF.bin"


func _initialize() -> void:
	var executor: Variant = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not load the hash-checked selector sources: " + executor.error_message)
		return
	var pre_call_sp := 0xFD
	var entry_sp := (pre_call_sp - 2) & 0xFF
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	# The test supplies the real `$80FA JSR $A20F` return word; it is a
	# verifier fixture, not a recorded route receipt.
	stack[(entry_sp + 1) & 0xFF] = 0xFC
	stack[(entry_sp + 2) & 0xFF] = 0x80
	var source_call := {
		"caller_pc": 0x80FA,
		"target_pc": 0xA20F,
		"return_pc": 0x80FD,
		"source_event_id": "verifier_fixture_only_source_call_80FA",
		"pre_call_sp": pre_call_sp,
		"stack_page": stack,
	}
	var cpu_state := {"pc": 0xA20F, "sp": entry_sp, "a": 0x87, "x": 0x02, "y": 0, "p": 0xA4}
	var ram_before := {0x0022: 0x80, 0x0023: 0x87, 0x0025: 0x02, 0x0026: 0x00}
	var result: Dictionary = executor.execute_source_call(source_call, cpu_state, ram_before)
	if not bool(result.get("ok", false)):
		_fail("ROM selector did not reach its source RTS: " + String(result.get("error", "unknown error")))
		return
	var regs: Dictionary = result.get("return_registers", {})
	if int(regs.get("pc", -1)) != 0x80FD \
			or int(regs.get("sp", -1)) != pre_call_sp \
			or int(regs.get("a", -1)) != 0x03 \
			or int(regs.get("x", -1)) != 0x00 \
			or int(regs.get("y", -1)) != 0x84 \
			or int(regs.get("p", -1)) != 0x24:
		_fail("Post-RTS registers, flags, or stack pointer differ from the ROM path: %s" % regs)
		return
	var ram_after: Dictionary = result.get("ram_after", {})
	if int(result.get("copy_loop_iterations", -1)) != 0x1350 \
			or int(result.get("roster_loop_iterations", -1)) != 11 \
			or int(ram_after.get(0x00D0, -1)) != 0xFF \
			or int(ram_after.get(0x00D1, -1)) != 0xBF \
			or int(ram_after.get(0x00D2, -1)) != 0x4F \
			or int(ram_after.get(0x00D3, -1)) != 0x73 \
			or int(ram_after.get(0x00ED, -1)) != 0x0B \
			or int(ram_after.get(0x002C, -1)) != 0x00 \
			or int(ram_after.get(0x002A, -1)) != 0x00 \
			or int(ram_after.get(0x002B, -1)) != 0x03:
		_fail("ROM-derived PRG-RAM copy/selector outputs differ from the match-zero source path.")
		return
	var copy_source := FileAccess.get_file_as_bytes(COPY_SOURCE_PATH)
	if copy_source.size() != 0x1350:
		_fail("The preserved `$ACB0-$BFFF` data span has the wrong length.")
		return
	for index in range(copy_source.size()):
		if int(ram_after.get(0x6000 + index, -1)) != int(copy_source[index]):
			_fail("ROM copy destination diverges at PRG-RAM `$%04X`." % (0x6000 + index))
			return
	var roster: PackedByteArray = FileAccess.get_file_as_bytes("res://reference/rom_extract/gameplay/fresh_kickoff_position_context/bank_02_match_00_home_roster_AA47.bin")
	for player_index in range(11):
		if int(ram_after.get(0x0300 + player_index * 0x0C, -1)) != int(roster[player_index]):
			_fail("ROM roster ID copy differs at player slot %d." % player_index)
			return
	var returned_stack: PackedByteArray = result.get("stack_after", PackedByteArray())
	if returned_stack.size() != 0x100 \
			or int(returned_stack[0xFA]) != 0x80 or int(returned_stack[0xFB]) != 0xA8 \
			or int(returned_stack[0xFC]) != 0xFC or int(returned_stack[0xFD]) != 0x80:
		_fail("Nested/outer JSR stack words were not preserved through the two RTS instructions.")
		return
	var receipt: Dictionary = result.get("source_return_receipt", {})
	if String(receipt.get("source_event_id", "")) != String(source_call["source_event_id"]) \
			or int(receipt.get("nested_jsr_return", {}).get("rts_pc", -1)) != 0xA8CD:
		_fail("Source return receipt does not identify both ROM RTS boundaries.")
		return
	if bool(result.get("trace_state_used", true)) or bool(result.get("emulator_data_used", true)):
		_fail("Selector executor must not use trace or emulator state.")
		return

	var wrong_y := cpu_state.duplicate(true)
	wrong_y["y"] = 1
	var refused_y: Dictionary = executor.execute_source_call(source_call, wrong_y, ram_before)
	if bool(refused_y.get("ok", true)) or not String(refused_y.get("error", "")).contains("Y=0"):
		_fail("Selector must refuse unsupported nonzero Y instead of manufacturing copy semantics.")
		return
	var wrong_index := ram_before.duplicate(true)
	wrong_index[0x0026] = 1
	var refused_index: Dictionary = executor.execute_source_call(source_call, cpu_state, wrong_index)
	if bool(refused_index.get("ok", true)):
		_fail("Match selector must refuse a nonzero index outside this bounded helper.")
		return
	var broken_stack_call := source_call.duplicate(true)
	broken_stack_call["stack_page"] = PackedByteArray()
	var refused_stack: Dictionary = executor.execute_source_call(broken_stack_call, cpu_state, ram_before)
	if bool(refused_stack.get("ok", true)):
		_fail("Selector executor accepted an invalid caller stack page.")
		return

	print("PASS: source-backed `$80FA->$A20F->$A86E` match-zero path executes `$A8B7->$A138`, copies 4,944 ROM bytes and 11 roster IDs, and reaches both `$A8CD` and `$A8B6` RTS returns with exact registers/flags/stack.")
	print("LIMIT: caller state is explicit and must supply `$26=0`, post-`$C4B9` registers/RAM, stack, and `$Y=0`; no live route caller currently supplies this contract. Copy-loop cycle count excludes asynchronous NMI service.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
