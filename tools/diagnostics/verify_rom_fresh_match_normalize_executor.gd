extends SceneTree

const SELECTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const NORMALIZE_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_normalize_executor.gd")


func _initialize() -> void:
	var selector: Variant = SELECTOR_SCRIPT.new()
	if not selector.configure_from_project_sources():
		_fail("Could not configure the hash-checked A20F selector: " + selector.error_message)
		return
	var pre_call_sp := 0xFD
	var entry_sp := (pre_call_sp - 2) & 0xFF
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	stack[(entry_sp + 1) & 0xFF] = 0xFC
	stack[(entry_sp + 2) & 0xFF] = 0x80
	var selector_call := {
		"caller_pc": 0x80FA,
		"target_pc": 0xA20F,
		"return_pc": 0x80FD,
		"source_event_id": "verifier_fixture_only_source_call_80FA",
		"pre_call_sp": pre_call_sp,
		"stack_page": stack,
	}
	var selector_cpu := {"pc": 0xA20F, "sp": entry_sp, "a": 0x87, "x": 2, "y": 0, "p": 0xA4}
	var selector_ram := {0x0022: 0x80, 0x0023: 0x87, 0x0025: 2, 0x0026: 0}
	var selector_result: Dictionary = selector.execute_source_call(selector_call, selector_cpu, selector_ram)
	if not bool(selector_result.get("ok", false)):
		_fail("The prerequisite A20F ROM execution did not return: " + String(selector_result.get("error", "unknown error")))
		return

	var normalize: Variant = NORMALIZE_SCRIPT.new()
	if not normalize.configure_from_project_sources():
		_fail("Could not configure the hash-checked A20C sources: " + normalize.error_message)
		return
	var result: Dictionary = normalize.execute_from_selector_return(selector_result)
	if not bool(result.get("ok", false)):
		_fail("ROM continuation failed to reach `$8112`: " + String(result.get("error", "unknown error")))
		return
	var regs: Dictionary = result.get("return_registers", {})
	if int(regs.get("pc", -1)) != 0x8112 \
			or int(regs.get("sp", -1)) != pre_call_sp \
			or int(regs.get("a", -1)) != 3 \
			or int(regs.get("x", -1)) != 0 \
			or int(regs.get("y", -1)) != 0x84 \
			or int(regs.get("p", -1)) != 0x24:
		_fail("Post-RTS CPU state differs from the source path: %s" % regs)
		return
	var ram: Dictionary = result.get("caller_ram_after", {})
	for expected: Dictionary in [
		{0x0027: 0}, {0x0028: 0}, {0x0029: 0}, {0x002A: 0}, {0x002B: 3},
		{0x0026: 0}, {0x0025: 2}, {0x0023: 0x87}, {0x0700: 1},
	]:
		for address: int in expected:
			if int(ram.get(address, -1)) != int(expected[address]):
				_fail("Caller RAM `$%04X` is $%02X, expected $%02X." % [address, int(ram.get(address, -1)), int(expected[address])])
				return
	if ram.has(0x00E4):
		_fail("The test fixture unexpectedly supplied `$E4`; this proof must work without a seeded value.")
		return
	var proof: Dictionary = result.get("e4_branch_proof", {})
	if int(proof.get("candidate_values_checked", -1)) != 256 \
			or bool(proof.get("input_value_supplied", true)) \
			or not bool(proof.get("branch_taken_for_all_candidates", false)) \
			or int(proof.get("branch_target_pc", -1)) != 0xA8A8 \
			or int(proof.get("return_flags", -1)) != 0x24:
		_fail("The exhaustive E4 branch-invariance proof is incomplete: %s" % proof)
		return
	var mapper_writes: Array = result.get("caller_mapper_bus_writes", [])
	if mapper_writes.size() != 2 \
			or int(mapper_writes[0].get("address", -1)) != 0x8000 \
			or int(mapper_writes[0].get("value", -1)) != 0x87 \
			or int(mapper_writes[1].get("address", -1)) != 0x8001 \
			or int(mapper_writes[1].get("value", -1)) != 2:
		_fail("The caller's `$810C->$C4B9` bank-$02 writes differ: %s" % mapper_writes)
		return
	var returned_stack: PackedByteArray = result.get("stack_after", PackedByteArray())
	if returned_stack.size() != 0x100 \
			or int(returned_stack[0xFC]) != 0x11 or int(returned_stack[0xFD]) != 0x81:
		_fail("The final `$810F` JSR return word was not preserved through `$A8B6 RTS`.")
		return
	var receipt: Dictionary = result.get("normalize_source_return_receipt", {})
	if int(receipt.get("caller_pc", -1)) != 0x810F \
			or int(receipt.get("target_pc", -1)) != 0xA20C \
			or int(receipt.get("return_pc", -1)) != 0x8112 \
			or int(receipt.get("rts_pc", -1)) != 0xA8B6:
		_fail("Return receipt does not identify `$810F->$A20C->$A8B6 RTS->$8112`.")
		return
	if int(result.get("cpu_cycles_without_interrupts_from_80FD", -1)) != 94 \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)):
		_fail("Instruction-cycle total or source-only provenance failed: %s" % result)
		return

	var bad_match: Dictionary = selector_result.duplicate(true)
	bad_match["ram_after"][0x0026] = 1
	var refused_match: Dictionary = normalize.execute_from_selector_return(bad_match)
	if bool(refused_match.get("ok", true)):
		_fail("The normalizer accepted a selector result outside fresh match index zero.")
		return
	var bad_stack: Dictionary = selector_result.duplicate(true)
	bad_stack["stack_after"] = PackedByteArray()
	var refused_stack: Dictionary = normalize.execute_from_selector_return(bad_stack)
	if bool(refused_stack.get("ok", true)):
		_fail("The normalizer accepted a missing source stack page.")
		return
	if bool(result.get("live_mapper_updated", true)):
		_fail("The bounded executor must report mapper bus effects without mutating a live mapper.")
		return
	var logical_event_id := "verifier_fresh_kickoff_logical_selector_80FA_A20F"
	var logical_selector_call := {
		"caller_pc": 0x80FA, "target_pc": 0xA20F, "return_pc": 0x80FD,
		"source_event_id": logical_event_id,
		"logical_stack_frame": {
			"kind": "rom_jsr", "caller_pc": 0x80FA, "target_pc": 0xA20F,
			"return_pc": 0x80FD, "return_word": 0x80FC,
			"source_event_id": logical_event_id,
		},
	}
	var logical_selector: Dictionary = selector.execute_source_call(logical_selector_call, {
		"pc": 0xA20F, "a": 0x07, "x": 2, "y": 0,
		"p_known_mask": 0x82, "p_known_value": 0,
	}, {0x0022: 0, 0x0023: 0x07, 0x0025: 2, 0x0026: 0})
	if not bool(logical_selector.get("ok", false)):
		_fail("Live-shaped logical selector fixture failed: " + String(logical_selector.get("error", "unknown error")))
		return
	var logical_result: Dictionary = normalize.execute_from_logical_selector_return(logical_selector)
	if not bool(logical_result.get("ok", false)):
		_fail("Logical caller continuation failed through `$8112`: " + String(logical_result.get("error", "unknown error")))
		return
	var logical_registers: Dictionary = logical_result.get("return_registers", {})
	var logical_ram: Dictionary = logical_result.get("caller_ram_after", {})
	var logical_mapper_writes: Array = logical_result.get("caller_mapper_bus_writes", [])
	var logical_proof: Dictionary = logical_result.get("e4_branch_proof", {})
	var logical_return_stack: Array = logical_result.get("stack_after", [])
	if int(logical_registers.get("pc", -1)) != 0x8112 \
			or int(logical_registers.get("a", -1)) != 3 \
			or int(logical_registers.get("x", -1)) != 0 \
			or int(logical_registers.get("y", -1)) != 0x84 \
			or int(logical_registers.get("p_known_mask", -1)) != 0xC3 \
			or int(logical_registers.get("p_known_value", -1)) != 0 \
			or int(logical_ram.get(0x0022, -1)) != 0 \
			or int(logical_ram.get(0x0023, -1)) != 0x07 \
			or int(logical_ram.get(0x0025, -1)) != 2 \
			or int(logical_ram.get(0x0027, -1)) != 0 \
			or int(logical_ram.get(0x0028, -1)) != 0 \
			or int(logical_ram.get(0x0029, -1)) != 0 \
			or int(logical_ram.get(0x002A, -1)) != 0 \
			or int(logical_ram.get(0x002B, -1)) != 3 \
			or int(logical_ram.get(0x0700, -1)) != 1 \
			or logical_mapper_writes.size() != 2 \
			or int(logical_mapper_writes[0].get("value", -1)) != 0x07 \
			or int(logical_mapper_writes[1].get("value", -1)) != 2 \
			or logical_return_stack.size() != 0 \
			or String(logical_result.get("stack_model", "")) != "logical_source_jsr_frames" \
			or int(logical_proof.get("candidate_values_checked", -1)) != 256 \
			or int(logical_result.get("cpu_cycles_without_interrupts_from_80FD", -1)) != 94:
		_fail("Logical continuation state differs from ROM-derived `$80FD-$8112`: %s" % logical_result)
		return

	print("PASS: physical-stack fixture and ROM-derived logical frames both run the `$80FD-$8112` caller/mapper/normalizer path with checked writes and RTS contracts.")
	print("PASS: all 256 possible `$E4` bytes take the same `$26=0` branch and produce identical return flags; no `$E4` value or trace state was supplied.")
	print("LIMIT: logical mode omits absolute SP/stack-page data; the `$8112->$8920` task/NMI wait and later caller remain outside this component.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
