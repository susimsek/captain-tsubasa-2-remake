extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const WORKER_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_8779_zero_branch_executor.gd")

const P_N := 0x80
const P_Z := 0x02
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the live route's `$86F8` result executes `$EBB3->$8006->$8779` through the `$0534==0` branch and returns at `$EBC5`.")
	print("PASS: source hashes, CPU/RAM/stack/MMC3 state, writes, branch, and next-call boundary match the checked ROM path.")
	print("LIMIT: `$80` normalization awaits its actor-seeded route check; stream/script behavior, PPU/APU effects, and visible output remain unresolved.")
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
	var previous_result: Dictionary = advance.get("slot09_86f8_worker_result", {})
	if String(previous_result.get("status", "")) != "returned_to_root_caller" \
			or int(previous_result.get("exit_pc", -1)) != 0xEBB3 \
			or int(previous_result.get("ram_image", PackedByteArray())[0x0532]) != 0 \
			or bool(previous_result.get("trace_state_used", true)):
		return _fail("Runner did not provide an actual source-derived `$86F8` return at `$EBB3`.")

	var executor = WORKER_EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Worker source-package setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_86f8_worker_result(previous_result)
	if not bool(result.get("ok", false)):
		return _fail("`$8779` zero-branch execution failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_returned_state(result, previous_result):
		return false
	if not _verify_rejected_inputs(executor, previous_result):
		return false
	return true


func _verify_returned_state(result: Dictionary, previous_result: Dictionary) -> bool:
	var input_ram: PackedByteArray = previous_result["ram_image"]
	var input_stack: PackedByteArray = previous_result["stack_page"]
	var input_mapper: Dictionary = previous_result["mapper"]
	var base: int = int(input_ram[0x0022])
	var select6 := (base | 0x06) & 0xFF
	var select7 := (base | 0x07) & 0xFF
	var selected6 := select6 & 0x07
	var selected7 := select7 & 0x07
	var expected_ram := input_ram.duplicate()
	expected_ram[0x0024] = 0x18
	expected_ram[0x0025] = 0x19
	expected_ram[0x0023] = select7
	var expected_ram_writes: Array[Dictionary] = [
		{"pc": 0xEBB8, "address": 0x0024, "value": 0x18, "kind": "ram"},
		{"pc": 0xEBBC, "address": 0x0025, "value": 0x19, "kind": "ram"},
		{"pc": 0xCE31, "address": 0x0023, "value": select6, "kind": "ram"},
		{"pc": 0xCE3F, "address": 0x0023, "value": select7, "kind": "ram"},
	]
	var expected_mapper_writes: Array[Dictionary] = [
		{"pc": 0xCE33, "address": 0x8000, "value": select6, "select": selected6, "kind": "register_select"},
		{"pc": 0xCE38, "address": 0x8001, "value": 0x18, "select": selected6, "kind": "register_data"},
		{"pc": 0xCE41, "address": 0x8000, "value": select7, "select": selected7, "kind": "register_select"},
		{"pc": 0xCE46, "address": 0x8001, "value": 0x19, "select": selected7, "kind": "register_data"},
	]
	var expected_pcs: Array[int] = [
		0xEBB3, 0xEBB4, 0xEBB6, 0xEBB8, 0xEBBA, 0xEBBC, 0xEBBE,
		0xCE2D, 0xCE2F, 0xCE31, 0xCE33, 0xCE36, 0xCE38, 0xCE3B,
		0xCE3D, 0xCE3F, 0xCE41, 0xCE44, 0xCE46, 0xCE49,
		0xEBC1, 0xEBC2, 0x8006, 0x8779, 0x877C, 0x87A3,
	]
	var expected_stack_writes: Array[Dictionary] = [
		{"pc": 0xEBB3, "address": 0x017A, "value": 0x00, "kind": "PHA"},
		{"pc": 0xEBBE, "address": 0x0179, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBBE, "address": 0x0178, "value": 0xC0, "kind": "JSR_low"},
		{"pc": 0xEBC2, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBC2, "address": 0x0179, "value": 0xC4, "kind": "JSR_low"},
	]
	var expected_stack_reads: Array[Dictionary] = [
		{"pc": 0xCE49, "address": 0x0178, "value": 0xC0, "kind": "RTS_low"},
		{"pc": 0xCE49, "address": 0x0179, "value": 0xEB, "kind": "RTS_high"},
		{"pc": 0xEBC1, "address": 0x017A, "value": 0x00, "kind": "PLA"},
		{"pc": 0x87A3, "address": 0x0179, "value": 0xC4, "kind": "RTS_low"},
		{"pc": 0x87A3, "address": 0x017A, "value": 0xEB, "kind": "RTS_high"},
	]
	var expected_mapper: Dictionary = input_mapper.duplicate(true)
	var expected_bank_registers: Dictionary = expected_mapper.get("bank_registers", {}).duplicate(true)
	expected_bank_registers[selected6] = 0x18
	expected_bank_registers[selected7] = 0x19
	expected_mapper["bank_registers"] = expected_bank_registers
	expected_mapper["bank_low"] = 0x18 if selected6 == 6 else int(input_mapper.get("bank_low", -1))
	expected_mapper["bank_high"] = 0x19 if selected7 == 7 else int(input_mapper.get("bank_high", -1))
	expected_mapper["select"] = selected7
	var entry_registers: Dictionary = result.get("entry_registers", {})
	var worker_entry_registers: Dictionary = result.get("worker_entry_registers", {})
	var registers: Dictionary = result.get("registers", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	if String(result.get("status", "")) != "returned_before_next_worker_call" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0xEBB3 \
			or int(result.get("worker_entry_pc", -1)) != 0x8779 \
			or int(result.get("input_ram_0534", -1)) != int(input_ram[0x0534]) \
			or int(input_ram[0x0534]) != 0 \
			or int(entry_registers.get("pc", -1)) != 0xEBB3 \
			or int(entry_registers.get("sp", -1)) != 0x7A \
			or int(worker_entry_registers.get("pc", -1)) != 0x8779 \
			or int(worker_entry_registers.get("sp", -1)) != 0x78 \
			or int(worker_entry_registers.get("a", -1)) != 0 \
			or int(worker_entry_registers.get("x", -1)) != int(entry_registers.get("x", -2)) \
			or int(worker_entry_registers.get("y", -1)) != int(entry_registers.get("y", -2)) \
			or (int(worker_entry_registers.get("p", -1)) & P_Z) == 0 \
			or (int(worker_entry_registers.get("p", -1)) & P_N) != 0 \
			or int(result.get("exit_pc", -1)) != 0xEBC5 \
			or int(registers.get("pc", -1)) != 0xEBC5 \
			or int(registers.get("sp", -1)) != 0x7A \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("x", -1)) != int(entry_registers.get("x", -2)) \
			or int(registers.get("y", -1)) != int(entry_registers.get("y", -2)) \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & (P_N | P_Z)) != (P_N | P_Z) \
			or result.get("instruction_pcs", []) != expected_pcs \
			or result.get("ram_writes", []) != expected_ram_writes \
			or result.get("stack_writes", []) != expected_stack_writes \
			or result.get("stack_reads", []) != expected_stack_reads \
			or result.get("mapper_writes", []) != expected_mapper_writes \
			or output_ram != expected_ram \
			or output_stack.slice(0x78, 0x7B) != PackedByteArray([0xC0, 0xC4, 0xEB]) \
			or result.get("mapper", {}) != expected_mapper \
			or int(result.get("worker_return_word", -1)) != 0xEBC4 \
			or int(result.get("worker_return_pc", -1)) != 0xEBC5 \
			or bool(result.get("next_worker_call_executed", true)) \
			or bool(result.get("next_worker_body_bytes_read", true)) \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != [] \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)):
		return _fail("`$8779` result differs from the ROM-supported branch/return contract: " + str({
				"entry_registers": entry_registers, "worker_entry_registers": worker_entry_registers,
				"registers": registers, "input_ram_0022": base, "input_ram_0534": input_ram[0x0534],
				"exit_pc": result.get("exit_pc"), "instruction_pcs": result.get("instruction_pcs"),
				"ram_writes": result.get("ram_writes"), "mapper_writes": result.get("mapper_writes"),
				"mapper": result.get("mapper"), "expected_mapper": expected_mapper,
				"stack_reads": result.get("stack_reads"), "stack_writes": result.get("stack_writes"),
				"next_worker_body_bytes_read": result.get("next_worker_body_bytes_read")}))
	return true


func _verify_rejected_inputs(executor: Variant, previous_result: Dictionary) -> bool:
	var nonzero := previous_result.duplicate(true)
	var nonzero_ram: PackedByteArray = (previous_result["ram_image"] as PackedByteArray).duplicate()
	nonzero_ram[0x0534] = 1
	nonzero["ram_image"] = nonzero_ram
	var unsupported: Dictionary = executor.execute_from_86f8_worker_result(nonzero)
	if bool(unsupported.get("ok", true)) \
			or String(unsupported.get("status", "")) != "unsupported_branch" \
			or int(unsupported.get("exit_pc", -1)) != 0x877E \
			or int(unsupported.get("input_ram_0534", -1)) != 1 \
			or bool(unsupported.get("next_worker_call_executed", true)) \
			or bool(unsupported.get("next_worker_body_bytes_read", true)):
		return _fail("Nonzero `$0534` did not stop at the unresolved `$877E` branch.")

	var invalid_stack := previous_result.duplicate(true)
	var bad_stack: PackedByteArray = (previous_result["stack_page"] as PackedByteArray).duplicate()
	bad_stack[0x79] = (int(bad_stack[0x79]) + 1) & 0xFF
	invalid_stack["stack_page"] = bad_stack
	var rejected: Dictionary = executor.execute_from_86f8_worker_result(invalid_stack)
	if bool(rejected.get("ok", true)) or String(rejected.get("status", "")) != "rejected_input":
		return _fail("Mismatched live `$EBB2->$EBB3` return stack was not rejected.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
