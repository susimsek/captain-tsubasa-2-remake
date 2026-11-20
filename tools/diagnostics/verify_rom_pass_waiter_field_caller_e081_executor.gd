extends SceneTree
## Verifies the ROM-derived E081 source span, its first scheduler-call contract,
## one source loop edge, and the conditional `$E0AB JSR $8000` contract. The
## E0AB boundary is a trace-shaped fixture, not proof that the trace executed it.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_waiter_field_caller_e081_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not configure the E081 ROM source span: " + executor.error_message)
		return
	var entry := _make_boundary(0xE081, 0x4E, 0x0F, 0x00, 0x07, 0x31, true)
	var entry_ram: PackedByteArray = entry["ram_image"].duplicate()
	var entry_stack: PackedByteArray = entry["stack_page"].duplicate()
	var first: Dictionary = executor.execute_until_external_call(entry)
	var first_call: Dictionary = first.get("call_contract", {})
	var first_next: Dictionary = first.get("next_boundary_snapshot", {})
	var first_cpu: Dictionary = first.get("registers", {})
	var first_pcs: Array = first.get("source_instruction_pcs", [])
	if not bool(first.get("ok", false)) \
			or String(first.get("status", "")) != "source_call_contract_ready" \
			or int(first.get("entry_pc", -1)) != 0xE081 \
			or int(first.get("exit_pc", -1)) != 0xE086 \
			or int(first_call.get("target_pc", -1)) != 0xCB0F \
			or int(first_call.get("target_bank", -1)) != 0x1E \
			or int(first_call.get("return_word", -1)) != 0xE088 \
			or int(first_call.get("return_pc", -1)) != 0xE089 \
			or int(first_call.get("sp_before_push", -1)) != 0x4D \
			or int(first_call.get("sp_after_jsr", -1)) != 0x4B \
			or int(first_cpu.get("a", -1)) != 0x01 \
			or int(first_next.get("sp", -1)) != 0x4D \
			or int(first_pcs.size()) != 4 \
			or int(first_pcs[0]) != 0xE081 or int(first_pcs[-1]) != 0xE086 \
			or not bool(first.get("trace_state_used", false)) \
			or not bool(first.get("test_fixture", false)) \
			or not bool(first.get("input_boundary_unchanged", false)) \
			or entry["ram_image"] != entry_ram or entry["stack_page"] != entry_stack:
		_fail("The `$E081->$E086 JSR $CB0F` source call contract differs: " + str({
			"status": first.get("status", ""), "error": first.get("error", ""),
			"exit_pc": first.get("exit_pc", -1), "registers": first_cpu,
			"call": first_call, "pcs": first_pcs}))
		return
	var first_stack_writes: Array = first.get("source_stack_writes", [])
	if first_stack_writes.size() != 1 \
			or int(first_stack_writes[0].get("source_pc", -1)) != 0xE083 \
			or int(first_stack_writes[0].get("address", -1)) != 0x014E \
			or int(first_stack_writes[0].get("value", -1)) != 0:
		_fail("The `$E081` saved-A stack write differs from the ROM PHA.")
		return
	var resumed := _after_call(first, 0xE089, {"a": 0x01, "x": 0x00, "y": 0x07, "p": 0x20})
	var loop: Dictionary = executor.execute_until_external_call(resumed)
	var loop_call: Dictionary = loop.get("call_contract", {})
	var loop_pcs: Array = loop.get("source_instruction_pcs", [])
	if not bool(loop.get("ok", false)) \
			or int(loop.get("exit_pc", -1)) != 0xE086 \
			or int(loop_call.get("target_pc", -1)) != 0xCB0F \
			or int(loop_call.get("return_pc", -1)) != 0xE089 \
			or int(loop_call.get("sp_before_push", -1)) != 0x4D \
			or loop_pcs.is_empty() or int(loop_pcs[0]) != 0xE089 \
			or int(loop_pcs[-1]) != 0xE086:
		_fail("The ROM loop edge `$E0D1->$E083` did not reach its next `$CB0F` call: " + str({
			"status": loop.get("status", ""), "error": loop.get("error", ""),
			"exit_pc": loop.get("exit_pc", -1), "call": loop_call, "pcs": loop_pcs}))
		return
	var second_resume := _after_call(loop, 0xE089,
		{"a": 0x01, "x": 0x00, "y": 0x07, "p": 0x20}, {0x062A: 0x80})
	var mapper_call: Dictionary = executor.execute_until_external_call(second_resume)
	var mapper_call_contract: Dictionary = mapper_call.get("call_contract", {})
	var mapper_branches: Array = mapper_call.get("source_branches", [])
	if not bool(mapper_call.get("ok", false)) \
			or int(mapper_call.get("exit_pc", -1)) != 0xE0A7 \
			or int(mapper_call_contract.get("target_pc", -1)) != 0xCE2D \
			or int(mapper_call_contract.get("sp_before_push", -1)) != 0x4B \
			or mapper_branches.is_empty() \
			or int(mapper_branches[-1].get("source_pc", -1)) != 0xE099 \
			or bool(mapper_branches[-1].get("taken", true)):
		_fail("The source `$062A` bit-7 branch did not reach the mapper-helper contract before `$E0AB`: " + str({
			"status": mapper_call.get("status", ""), "error": mapper_call.get("error", ""),
			"exit_pc": mapper_call.get("exit_pc", -1), "call": mapper_call_contract,
			"branches": mapper_branches}))
		return
	var handoff_boundary := _after_call(mapper_call, 0xE0AA,
		{"a": 0x1B, "x": 0x00, "y": 0x07, "p": 0x20})
	var handoff_input_ram: PackedByteArray = handoff_boundary["ram_image"].duplicate()
	var handoff_input_stack: PackedByteArray = handoff_boundary["stack_page"].duplicate()
	var handoff: Dictionary = executor.execute_until_external_call(handoff_boundary)
	var handoff_call: Dictionary = handoff.get("call_contract", {})
	var handoff_pushes: Array = handoff_call.get("stack_pushes", [])
	if not bool(handoff.get("ok", false)) \
			or String(handoff.get("status", "")) != "source_handoff_contract_ready" \
			or int(handoff.get("exit_pc", -1)) != 0xE0AB \
			or String(handoff_call.get("kind", "")) != "rom_field_worker_handoff" \
			or int(handoff_call.get("target_pc", -1)) != 0x8000 \
			or int(handoff_call.get("target_bank", -1)) != 0x1A \
			or int(handoff_call.get("return_word", -1)) != 0xE0AD \
			or int(handoff_call.get("return_pc", -1)) != 0xE0AE \
			or int(handoff_call.get("sp_before_push", -1)) != 0x4C \
			or int(handoff_call.get("sp_after_jsr", -1)) != 0x4A \
			or handoff_pushes.size() != 2 \
			or int(handoff_pushes[0].get("address", -1)) != 0x014C \
			or int(handoff_pushes[0].get("value", -1)) != 0xE0 \
			or int(handoff_pushes[1].get("address", -1)) != 0x014B \
			or int(handoff_pushes[1].get("value", -1)) != 0xAD \
			or not bool(handoff.get("trace_state_used", false)) \
			or handoff_boundary["ram_image"] != handoff_input_ram \
			or handoff_boundary["stack_page"] != handoff_input_stack:
		_fail("The `$E0AB JSR $8000` handoff contract differs from ROM bytes and A103 entry evidence: " + str({
			"status": handoff.get("status", ""), "error": handoff.get("error", ""),
			"call": handoff_call}))
		return
	var wrong_mapper := _make_boundary(0xE0AB, 0x4C, 0x01, 0x00, 0x07, 0x20, true)
	var wrong_state: Dictionary = wrong_mapper.get("mapper", {}).duplicate(true)
	wrong_state["bank_low"] = 0x1B
	wrong_mapper["mapper"] = wrong_state
	var rejected: Dictionary = executor.execute_until_external_call(wrong_mapper)
	if bool(rejected.get("ok", true)) \
			or String(rejected.get("status", "")) != "invalid_e081_boundary":
		_fail("The E081 executor accepted `$E0AB JSR $8000` under the wrong low PRG bank.")
		return
	print("PASS: E081 ROM source, `$CB0F` call/loop, and conditional `$8000` handoff contract verified; FCEUX parity remains unproven.")
	quit(0)


func _make_boundary(pc: int, sp: int, a: int, x: int, y: int, p: int,
		trace_fixture: bool) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0441] = 0x06
	ram[0x062A] = 0x0F
	var stack := PackedByteArray()
	stack.resize(0x100)
	if pc == 0xE081:
		stack[0x4D] = 0x80
		stack[0x4E] = 0xE0
	if pc == 0xE0AB:
		ram[0x0441] = 0x06
	for index in 0x100:
		ram[0x0100 + index] = stack[index]
	return {"rom_sha256": ROM_SHA256, "pc": pc, "sp": sp, "a": a, "x": x, "y": y, "p": p,
		"p_known_mask": 0xFF,
		"mapper": {"bank_low": 0x1A, "bank_high": 0x1B,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": ram, "stack_page": stack,
		"trace_state_used": trace_fixture, "test_fixture": true}


func _after_call(prior: Dictionary, return_pc: int, registers: Dictionary,
		ram_patches: Dictionary = {}) -> Dictionary:
	var call: Dictionary = prior.get("call_contract", {})
	var boundary: Dictionary = prior.get("next_boundary_snapshot", {}).duplicate(true)
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var sp := int(call.get("sp_before_push", -1))
	var return_word := int(call.get("return_word", -1))
	stack[sp] = (return_word >> 8) & 0xFF
	stack[(sp - 1) & 0xFF] = return_word & 0xFF
	for index in 0x100:
		ram[0x0100 + index] = stack[index]
	for address_variant: Variant in ram_patches:
		ram[int(address_variant)] = int(ram_patches[address_variant]) & 0xFF
	boundary["pc"] = return_pc
	boundary["sp"] = sp
	boundary["a"] = int(registers["a"])
	boundary["x"] = int(registers["x"])
	boundary["y"] = int(registers["y"])
	boundary["p"] = int(registers["p"])
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
