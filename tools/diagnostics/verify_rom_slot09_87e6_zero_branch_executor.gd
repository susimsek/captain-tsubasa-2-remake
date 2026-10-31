extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const WORKER_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_87e6_zero_branch_executor.gd")

const P_N := 0x80
const P_Z := 0x02
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the live route's `$8779` result executes the `$EBC5->$8009->$87E6` caller and `$0536==0` branch, returning at `$EBD7`.")
	print("PASS: hash-checked source spans, CPU/RAM/stack/MMC3 state, writes, branch, and stop boundary match the supported ROM path.")
	print("PASS: nonzero live `$0536` stops at `$87EB`; a mismatched `$EBC5` stack is rejected.")
	print("LIMIT: `$80` normalization awaits its actor-seeded route check; stream/reset-marker paths, PPU/APU delivery, and visible menu output remain unresolved.")
	quit(0)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh-route source setup failed: " + builder.error_message)
	var route_context = builder.build_fresh_kickoff_context()
	if route_context == null:
		return _fail("Fresh-route context derivation failed: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route runner setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(route_context)
	if not bool(begin.get("ok", false)):
		return _fail("Source route did not reach its slot-$09 yield: " + runner.error_message)
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)) \
			or String(advance.get("phase", "")) != "awaiting_external_nmi" \
			or String(advance.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY":
		return _fail("Source route did not execute the slot-$09 chain through the live `$CB0F` save: " + runner.error_message)
	var previous_result: Dictionary = advance.get("slot09_8779_worker_result", {})
	var previous_ram: PackedByteArray = previous_result.get("ram_image", PackedByteArray())
	if String(previous_result.get("status", "")) != "returned_before_next_worker_call" \
			or int(previous_result.get("exit_pc", -1)) != 0xEBC5 \
			or previous_ram.size() != 0x800 \
			or int(previous_ram[0x0536]) != 0 \
			or bool(previous_result.get("trace_state_used", true)) \
			or bool(previous_result.get("next_worker_call_executed", true)) \
			or bool(previous_result.get("next_worker_body_bytes_read", true)):
		return _fail("Runner did not provide the actual source-derived `$8779` result with live `$0536==0` at `$EBC5`.")

	var executor = WORKER_EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("`$87E6` source-package setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_8779_worker_result(previous_result)
	if not bool(result.get("ok", false)):
		return _fail("`$EBC5->$87E6` zero-branch execution failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_returned_state(result, previous_result):
		return false
	if not _verify_rejected_inputs(executor, previous_result):
		return false
	return true


func _verify_returned_state(result: Dictionary, previous_result: Dictionary) -> bool:
	var input_ram: PackedByteArray = previous_result["ram_image"]
	var input_stack: PackedByteArray = previous_result["stack_page"]
	var input_mapper: Dictionary = previous_result["mapper"]
	var expected_ram := input_ram.duplicate()
	expected_ram[0x0023] = 0x07
	expected_ram[0x0024] = 0x18
	expected_ram[0x0025] = 0x19
	expected_ram[0x0538] = 0x00
	var expected_ram_writes: Array[Dictionary] = [
		{"pc": 0xEBCA, "address": 0x0024, "value": 0x18, "kind": "ram"},
		{"pc": 0xEBCE, "address": 0x0025, "value": 0x19, "kind": "ram"},
		{"pc": 0xCE31, "address": 0x0023, "value": 0x06, "kind": "ram"},
		{"pc": 0xCE3F, "address": 0x0023, "value": 0x07, "kind": "ram"},
		{"pc": 0x8811, "address": 0x0538, "value": 0x00, "kind": "ram"},
	]
	var expected_mapper_writes: Array[Dictionary] = [
		{"pc": 0xCE33, "address": 0x8000, "value": 0x06, "select": 6, "kind": "register_select"},
		{"pc": 0xCE38, "address": 0x8001, "value": 0x18, "select": 6, "kind": "register_data"},
		{"pc": 0xCE41, "address": 0x8000, "value": 0x07, "select": 7, "kind": "register_select"},
		{"pc": 0xCE46, "address": 0x8001, "value": 0x19, "select": 7, "kind": "register_data"},
	]
	var expected_pcs: Array[int] = [
		0xEBC5, 0xEBC6, 0xEBC8, 0xEBCA, 0xEBCC, 0xEBCE, 0xEBD0,
		0xCE2D, 0xCE2F, 0xCE31, 0xCE33, 0xCE36, 0xCE38, 0xCE3B,
		0xCE3D, 0xCE3F, 0xCE41, 0xCE44, 0xCE46, 0xCE49, 0xEBD3,
		0xEBD4, 0x8009, 0x87E6, 0x87E9, 0x8811, 0x8814,
	]
	var expected_stack_writes: Array[Dictionary] = [
		{"pc": 0xEBC5, "address": 0x017A, "value": 0x00, "kind": "PHA"},
		{"pc": 0xEBD0, "address": 0x0179, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBD0, "address": 0x0178, "value": 0xD2, "kind": "JSR_low"},
		{"pc": 0xEBD4, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBD4, "address": 0x0179, "value": 0xD6, "kind": "JSR_low"},
	]
	var expected_stack_reads: Array[Dictionary] = [
		{"pc": 0xCE49, "address": 0x0178, "value": 0xD2, "kind": "RTS_low"},
		{"pc": 0xCE49, "address": 0x0179, "value": 0xEB, "kind": "RTS_high"},
		{"pc": 0xEBD3, "address": 0x017A, "value": 0x00, "kind": "PLA"},
		{"pc": 0x8814, "address": 0x0179, "value": 0xD6, "kind": "RTS_low"},
		{"pc": 0x8814, "address": 0x017A, "value": 0xEB, "kind": "RTS_high"},
	]
	var expected_mapper: Dictionary = input_mapper.duplicate(true)
	var expected_bank_registers: Dictionary = expected_mapper.get("bank_registers", {}).duplicate(true)
	expected_bank_registers[6] = 0x18
	expected_bank_registers[7] = 0x19
	expected_mapper["bank_registers"] = expected_bank_registers
	expected_mapper["bank_low"] = 0x18
	expected_mapper["bank_high"] = 0x19
	expected_mapper["select"] = 7
	var entry_registers: Dictionary = result.get("entry_registers", {})
	var worker_entry_registers: Dictionary = result.get("worker_entry_registers", {})
	var worker_entry_mapper: Dictionary = result.get("worker_entry_mapper", {})
	var registers: Dictionary = result.get("registers", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	if String(result.get("status", "")) != "returned_before_root_loop_check" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json" \
			or String(result.get("previous_worker_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_8779_worker/manifest.json" \
			or int(result.get("entry_pc", -1)) != 0xEBC5 \
			or int(result.get("worker_entry_pc", -1)) != 0x87E6 \
			or int(result.get("input_ram_0536", -1)) != 0 \
			or int(entry_registers.get("pc", -1)) != 0xEBC5 \
			or int(entry_registers.get("a", -1)) != 0 \
			or int(entry_registers.get("sp", -1)) != 0x7A \
			or entry_registers != previous_result.get("registers", {}) \
			or int(worker_entry_registers.get("pc", -1)) != 0x87E6 \
			or int(worker_entry_registers.get("a", -1)) != 0 \
			or int(worker_entry_registers.get("x", -1)) != 0 \
			or int(worker_entry_registers.get("y", -1)) != 0x05 \
			or int(worker_entry_registers.get("sp", -1)) != 0x78 \
			or int(worker_entry_mapper.get("bank_low", -1)) != 0x18 \
			or int(worker_entry_mapper.get("bank_high", -1)) != 0x19 \
			or (int(worker_entry_registers.get("p", -1)) & P_Z) == 0 \
			or (int(worker_entry_registers.get("p", -1)) & P_N) != 0 \
			or int(result.get("exit_pc", -1)) != 0xEBD7 \
			or int(registers.get("pc", -1)) != 0xEBD7 \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 0x05 \
			or int(registers.get("sp", -1)) != 0x7A \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & (P_N | P_Z)) != (P_N | P_Z) \
			or result.get("instruction_pcs", []) != expected_pcs \
			or result.get("ram_writes", []) != expected_ram_writes \
			or result.get("stack_writes", []) != expected_stack_writes \
			or result.get("stack_reads", []) != expected_stack_reads \
			or result.get("mapper_writes", []) != expected_mapper_writes \
			or output_ram != expected_ram \
			or output_stack.slice(0x78, 0x7B) != PackedByteArray([0xD2, 0xD6, 0xEB]) \
			or result.get("mapper", {}) != expected_mapper \
			or result.get("entry_mapper", {}) != previous_result.get("mapper", {}) \
			or int(result.get("worker_return_word", -1)) != 0xEBD6 \
			or int(result.get("worker_return_pc", -1)) != 0xEBD7 \
			or bool(result.get("next_root_check_executed", true)) \
			or bool(result.get("next_root_body_bytes_read", true)) \
			or bool(result.get("next_worker_call_executed", true)) \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != [] \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)):
		return _fail("`$87E6` route result differs from the supported ROM branch/return contract: " + str({
				"entry_registers": entry_registers, "worker_entry_registers": worker_entry_registers,
				"registers": registers, "input_ram_0536": result.get("input_ram_0536"),
				"exit_pc": result.get("exit_pc"), "instruction_pcs": result.get("instruction_pcs"),
				"ram_writes": result.get("ram_writes"), "mapper_writes": result.get("mapper_writes"),
				"stack_reads": result.get("stack_reads"), "stack_writes": result.get("stack_writes")}))
	return true


func _verify_rejected_inputs(executor: Variant, previous_result: Dictionary) -> bool:
	var unsupported_input := previous_result.duplicate(true)
	var unsupported_ram: PackedByteArray = (previous_result["ram_image"] as PackedByteArray).duplicate()
	unsupported_ram[0x0536] = 0x01
	unsupported_input["ram_image"] = unsupported_ram
	var unsupported: Dictionary = executor.execute_from_8779_worker_result(unsupported_input)
	var unsupported_pcs: Array = unsupported.get("instruction_pcs", [])
	if bool(unsupported.get("ok", true)) \
			or String(unsupported.get("status", "")) != "unsupported_branch" \
			or int(unsupported.get("input_ram_0536", -1)) != 1 \
			or int(unsupported.get("exit_pc", -1)) != 0x87EB \
			or unsupported_pcs.size() < 2 \
			or int(unsupported_pcs[unsupported_pcs.size() - 2]) != 0x87E6 \
			or int(unsupported_pcs[unsupported_pcs.size() - 1]) != 0x87E9 \
			or bool(unsupported.get("next_root_check_executed", true)) \
			or bool(unsupported.get("next_root_body_bytes_read", true)) \
			or bool(unsupported.get("trace_state_used", true)):
		return _fail("Nonzero live `$0536` did not stop immediately after the unresolved `$87E9` branch.")

	var invalid_input := previous_result.duplicate(true)
	var invalid_stack: PackedByteArray = (previous_result["stack_page"] as PackedByteArray).duplicate()
	invalid_stack[0x7A] = (int(invalid_stack[0x7A]) + 1) & 0xFF
	invalid_input["stack_page"] = invalid_stack
	var rejected: Dictionary = executor.execute_from_8779_worker_result(invalid_input)
	if bool(rejected.get("ok", true)) or String(rejected.get("status", "")) != "rejected_input":
		return _fail("Mismatched live `$EBC5` return stack was not rejected.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
