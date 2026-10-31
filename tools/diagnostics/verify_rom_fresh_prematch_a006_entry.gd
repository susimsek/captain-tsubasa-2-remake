extends SceneTree

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_prematch_a006_entry.gd")


func _initialize() -> void:
	var executor: Variant = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not load the byte-checked `$A006` sources: " + executor.error_message)
		return
	var pre_call_sp := 0xFD
	var entry_sp := (pre_call_sp - 2) & 0xFF
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	# Verifier fixture only: this is the `$811C JSR $A006` return word.
	stack[(entry_sp + 1) & 0xFF] = 0x1E
	stack[(entry_sp + 2) & 0xFF] = 0x81
	var source_call := {
		"caller_pc": 0x811C,
		"target_pc": 0xA006,
		"return_pc": 0x811F,
		"source_event_id": "verifier_fixture_only_811C_a006_call",
		"pre_call_sp": pre_call_sp,
		"stack_page": stack,
	}
	var cpu_state := {"pc": 0xA006, "sp": entry_sp, "a": 0x87, "x": 0x01, "y": 0x13, "p": 0x20}
	var ram_before := {0x0025: 0x01}
	var mapper_state := {"a000_prg_bank": 0x01}
	var result: Dictionary = executor.execute_source_call(source_call, cpu_state, ram_before, mapper_state)
	if not bool(result.get("ok", false)):
		_fail("ROM `$A006` entry did not transfer to `$A4EB`: " + String(result.get("error", "unknown error")))
		return
	var next_cpu: Dictionary = result.get("next_cpu_state", {})
	if String(result.get("status", "")) != "transferred_to_body" \
			or int(result.get("next_pc", -1)) != 0xA4EB \
			or int(next_cpu.get("pc", -1)) != 0xA4EB \
			or int(next_cpu.get("sp", -1)) != entry_sp \
			or int(next_cpu.get("a", -1)) != 0x87 \
			or int(next_cpu.get("x", -1)) != 0x01 \
			or int(next_cpu.get("y", -1)) != 0x13 \
			or int(next_cpu.get("p", -1)) != 0x20 \
			or int(result.get("cpu_cycles", -1)) != 3:
		_fail("The JMP transfer changed registers/stack or returned the wrong source PC/cycle count.")
		return
	var transfer_receipt: Dictionary = result.get("source_transfer_receipt", {})
	if String(transfer_receipt.get("source_event_id", "")) != String(source_call["source_event_id"]) \
			or String(transfer_receipt.get("vector_bytes", "")) != "4ceba4" \
			or String(transfer_receipt.get("status", "")) != "entered_target":
		_fail("The source transfer receipt does not identify the checked vector and call event.")
		return
	if result.get("ram_after", {}) != ram_before \
			or result.get("mapper_state_after", {}) != mapper_state \
			or result.get("stack_after", PackedByteArray()) != stack:
		_fail("The vector JMP must leave RAM, mapper selection, and caller stack untouched.")
		return
	if bool(result.get("trace_state_used", true)) or bool(result.get("emulator_data_used", true)):
		_fail("A006 entry must use only the preserved ROM bytes and explicit source event.")
		return

	var wrong_bank: Dictionary = executor.execute_source_call(source_call, cpu_state, ram_before, {"a000_prg_bank": 0x02})
	if bool(wrong_bank.get("ok", true)):
		_fail("A006 entry accepted a bank mapping other than PRG bank $01.")
		return
	var wrong_stack_call := source_call.duplicate(true)
	wrong_stack_call["stack_page"] = PackedByteArray()
	var wrong_stack: Dictionary = executor.execute_source_call(wrong_stack_call, cpu_state, ram_before, mapper_state)
	if bool(wrong_stack.get("ok", true)):
		_fail("A006 entry accepted a missing JSR stack page.")
		return
	var wrong_target_call := source_call.duplicate(true)
	wrong_target_call["target_pc"] = 0xA009
	var wrong_target: Dictionary = executor.execute_source_call(wrong_target_call, cpu_state, ram_before, mapper_state)
	if bool(wrong_target.get("ok", true)):
		_fail("A006 entry accepted a call to a different target.")
		return

	print("PASS: checked `$811C JSR $A006` entry verifies the bank-$01 `$4C EB A4` vector and transfers to `$A4EB` in three cycles without altering registers, stack, RAM, or mapper state.")
	print("LIMIT: `$A4EB-$A610` is preserved and hash-checked but not executed; no `$811F` return or visible pre-match state is claimed. Test uses an explicit verifier fixture, not a live route receipt.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
