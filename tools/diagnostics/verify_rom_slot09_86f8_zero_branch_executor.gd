extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ZERO_BRANCH_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_86f8_zero_branch_executor.gd")

const P_N := 0x80
const P_Z := 0x02


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the source route executes the live slot-$09 `$86F8` worker and returns at `$EBB3`.")
	print("PASS: the route continues through the checked `$8779` and `$87E6` workers to its `$CB0F` save.")
	print("LIMIT: actor-seeded high-bit normalization, later waits, PPU/APU delivery, NMI cadence, and screen output remain unresolved.")
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
		return _fail("Source route did not reach its first slot-$09 yield: " + runner.error_message)
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)) \
			or String(advance.get("phase", "")) != "awaiting_external_nmi" \
			or String(advance.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY":
		return _fail("Source runner did not execute the slot-$09 worker chain and save its `$CB0F` boundary: " + runner.error_message)
	var live_result: Dictionary = advance.get("slot09_resume_result", {})
	if int(live_result.get("exit_pc", -1)) != 0x86F8 \
			or int((live_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x0532]) != 0:
		return _fail("Source runner did not provide the source-derived zero-state slot-$09 resume result.")
	var route_worker_result: Dictionary = advance.get("slot09_86f8_worker_result", {})
	if int(route_worker_result.get("exit_pc", -1)) != 0xEBB3 \
			or bool(route_worker_result.get("next_worker_bytes_read", true)) \
			or int(advance.get("slot09_8779_worker_result", {}).get("exit_pc", -1)) != 0xEBC5 \
			or int(advance.get("slot09_87e6_worker_result", {}).get("exit_pc", -1)) != 0xEBD7 \
			or not bool(advance.get("slot09_ebd7_root_zero_result", {}).get("ok", false)):
		return _fail("Source runner did not retain the `$EBB3` return before `$8779`.")

	var executor = ZERO_BRANCH_EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Worker-source setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_slot09_resume_result(live_result)
	if not bool(result.get("ok", false)):
		return _fail("`$86F8` zero-branch execution failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_returned_state(result, live_result):
		return false
	if not _verify_rejected_inputs(executor, live_result):
		return false
	return true


func _verify_returned_state(result: Dictionary, live_result: Dictionary) -> bool:
	var input_ram: PackedByteArray = live_result["ram_image"]
	var input_stack: PackedByteArray = live_result["stack_page"]
	var input_mapper: Dictionary = live_result["mapper"]
	var registers: Dictionary = result.get("registers", {})
	var entry_registers: Dictionary = result.get("entry_registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var expected_stack_reads: Array[Dictionary] = [
		{"pc": 0x8722, "address": 0x0179, "value": 0xB2, "kind": "RTS_low"},
		{"pc": 0x8722, "address": 0x017A, "value": 0xEB, "kind": "RTS_high"},
	]
	if String(result.get("status", "")) != "returned_to_root_caller" \
			or String(result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or int(result.get("entry_pc", -1)) != 0x86F8 \
			or int(result.get("exit_pc", -1)) != 0xEBB3 \
			or int(result.get("entry_bank", -1)) != 0x18 \
			or int(result.get("exit_bank", -1)) != 0x18 \
			or int(result.get("input_ram_0532", -1)) != 0 \
			or int(entry_registers.get("pc", -1)) != 0x86F8 \
			or int(entry_registers.get("sp", -1)) != 0x78 \
			or int(registers.get("pc", -1)) != 0xEBB3 \
			or int(registers.get("sp", -1)) != 0x7A \
			or int(registers.get("a", -1)) != 0 \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & (P_N | P_Z)) != (P_N | P_Z) \
			or int(result.get("return_word", -1)) != 0xEBB2 \
			or int(result.get("return_pc", -1)) != 0xEBB3 \
			or result.get("instruction_pcs", []) != [0x86F8, 0x86FB, 0x8722] \
			or result.get("memory_writes", []) != [] \
			or result.get("stack_reads", []) != expected_stack_reads \
			or result.get("stack_writes", []) != [] \
			or output_ram != input_ram or output_stack != input_stack \
			or mapper != input_mapper \
			or bool(result.get("next_worker_executed", true)) \
			or bool(result.get("next_worker_bytes_read", true)) \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != [] \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)):
		return _fail("Zero-branch CPU/stack/RAM/mapper output or no-side-effect boundary differs: " + str({
				"status": result.get("status"), "entry_pc": result.get("entry_pc"), "exit_pc": result.get("exit_pc"),
				"entry_bank": result.get("entry_bank"), "exit_bank": result.get("exit_bank"),
				"ram_value": result.get("input_ram_0532"), "entry_registers": entry_registers,
				"registers": registers, "return_word": result.get("return_word"),
				"instruction_pcs": result.get("instruction_pcs"), "stack_reads": result.get("stack_reads"),
				"ram_same": output_ram == input_ram, "stack_same": output_stack == input_stack,
				"mapper_same": mapper == input_mapper,
				"next_worker_bytes_read": result.get("next_worker_bytes_read"),
				"ppu_bus_events": result.get("ppu_bus_events"), "apu_writes": result.get("apu_register_writes"),
				"effects_applied": result.get("ppu_apu_effects_applied"),
				"trace_used": result.get("trace_state_used"), "nmi_generated": result.get("nmi_cadence_generated")}))
	return true


func _verify_rejected_inputs(executor: Variant, live_result: Dictionary) -> bool:
	var nonzero := live_result.duplicate(true)
	var nonzero_ram: PackedByteArray = (live_result["ram_image"] as PackedByteArray).duplicate()
	nonzero_ram[0x0532] = 0x01
	nonzero["ram_image"] = nonzero_ram
	var rejected_nonzero: Dictionary = executor.execute_from_slot09_resume_result(nonzero)
	if bool(rejected_nonzero.get("ok", true)) \
			or String(rejected_nonzero.get("status", "")) != "unsupported_branch" \
			or int(rejected_nonzero.get("exit_pc", -1)) != 0x86FD:
		return _fail("Nonzero live `$0532` did not stop at its unresolved `$86F8` fall-through.")

	var invalid_stack := live_result.duplicate(true)
	var bad_stack: PackedByteArray = (live_result["stack_page"] as PackedByteArray).duplicate()
	bad_stack[0x79] = 0xB3
	invalid_stack["stack_page"] = bad_stack
	var rejected_stack: Dictionary = executor.execute_from_slot09_resume_result(invalid_stack)
	if bool(rejected_stack.get("ok", true)) \
			or String(rejected_stack.get("status", "")) != "rejected_input":
		return _fail("A mismatched `$EBB2->$EBB3` stack contract was not rejected.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
