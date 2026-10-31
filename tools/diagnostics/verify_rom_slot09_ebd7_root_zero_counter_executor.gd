extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ROOT_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_ebd7_root_zero_counter_executor.gd")
const CBF1_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_cbf1_sound_queue_executor.gd")

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the production route's live `$87E6` result has `$052E=$00` and takes `$EBD7->$EC05->$EB86->$CB0F`.")
	print("PASS: root source hash, branch path, JSR return stack, mapper, and exact yield-call input contract match.")
	print("PASS: a branch-coverage copy with `$052E=$01` follows `$EBE1->$EC02->$CBF1->$EC05->$EB88`, and the helper writes only the first empty sound-queue byte.")
	print("LIMIT: the production route still reaches `$052E=$00`; this copied-counter path is not evidence that the live route calls `$CBF1`, or that queued sound reaches APU output.")
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
	var live_result: Dictionary = advance.get("slot09_87e6_worker_result", {})
	var live_ram: PackedByteArray = live_result.get("ram_image", PackedByteArray())
	if String(live_result.get("status", "")) != "returned_before_root_loop_check" \
			or int(live_result.get("exit_pc", -1)) != 0xEBD7 \
			or live_ram.size() != 0x800 \
			or int(live_ram[0x052E]) != 0 \
			or bool(live_result.get("trace_state_used", true)):
		return _fail("Runner did not supply the actual source-derived `$87E6` result with `$052E=$00` at `$EBD7`.")

	var executor = ROOT_EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Root-check source-package setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_87e6_result(live_result)
	if not bool(result.get("ok", false)):
		return _fail("`$EBD7` zero-counter path failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_boundary(result, live_result):
		return false
	if not _verify_counter_one_helper_path(executor, live_result):
		return false
	return true


func _verify_boundary(result: Dictionary, live_result: Dictionary) -> bool:
	var live_cpu: Dictionary = live_result.get("registers", {})
	var cpu: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var expected_stack_writes: Array[Dictionary] = [
		{"pc": 0xEB88, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEB88, "address": 0x0179, "value": 0x8A, "kind": "JSR_low"},
	]
	var expected_request := {
		"slot_base": 0x09,
		"callsite_pc": 0xEB88,
		"target_pc": 0xCB0F,
		"delay_in_a": 0x01,
		"pre_jsr_sp": 0x7A,
		"x": 0x00,
		"y": 0x05,
		"bank_low": 0x18,
		"bank_high": 0x19,
		"resume_pc": 0xEB8B,
	}
	var expected_pcs: Array[int] = [0xEBD7, 0xEBDA, 0xEC05, 0xEB86, 0xEB88]
	if String(result.get("status", "")) != "reached_scheduler_yield_handler_entry" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json" \
			or int(result.get("entry_pc", -1)) != 0xEBD7 \
			or int(result.get("input_ram_052e", -1)) != 0 \
			or result.get("entry_registers", {}) != live_cpu \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(cpu.get("pc", -1)) != 0xCB0F \
			or int(cpu.get("a", -1)) != 1 \
			or int(cpu.get("x", -1)) != 0 \
			or int(cpu.get("y", -1)) != 5 \
			or int(cpu.get("sp", -1)) != 0x78 \
			or (int(cpu.get("p", -1)) & 0x82) != 0 \
			or int(cpu.get("p_known_mask", -1)) & 0x82 != 0x82 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or ram.size() != 0x800 \
			or int(ram[0x052E]) != 0 \
			or ram != live_result.get("ram_image", PackedByteArray()) \
			or stack.slice(0x78, 0x7B) != PackedByteArray([0xD2, 0x8A, 0xEB]) \
			or result.get("stack_writes", []) != expected_stack_writes \
			or result.get("instruction_pcs", []) != expected_pcs \
			or result.get("source_yield_request", {}) != expected_request \
			or bool(result.get("yield_handler_executed", true)) \
			or bool(result.get("later_root_checks_executed", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)) \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != []:
		return _fail("Root loop did not reach the exact live `$CB0F` call boundary: " + str({
			"input_052e": result.get("input_ram_052e"), "exit_pc": result.get("exit_pc"),
			"registers": cpu, "instruction_pcs": result.get("instruction_pcs"),
			"request": result.get("source_yield_request")}))
	return true


func _verify_counter_one_helper_path(executor: Variant, live_result: Dictionary) -> bool:
	var counter_one_input := live_result.duplicate(true)
	var counter_one_ram: PackedByteArray = (live_result["ram_image"] as PackedByteArray).duplicate()
	counter_one_ram[0x052E] = 0x01
	counter_one_input["ram_image"] = counter_one_ram
	var result: Dictionary = executor.execute_from_87e6_result(counter_one_input)
	if not bool(result.get("ok", false)):
		return _fail("The copied `$052E=$01` branch did not reach the ROM-backed `$CBF1` helper: "
				+ String(result.get("reason", executor.error_message)))
	var call: Dictionary = result.get("source_cbf1_call", {})
	var helper: Dictionary = result.get("cbf1_helper_result", {})
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var request: Dictionary = result.get("source_yield_request", {})
	var call_stack_writes: Array[Dictionary] = [
		{"pc": 0xEC02, "address": 0x017A, "value": 0xEC, "kind": "JSR_high"},
		{"pc": 0xEC02, "address": 0x0179, "value": 0x04, "kind": "JSR_low"},
	]
	var source_queue: PackedByteArray = counter_one_ram.slice(0x0700, 0x0705)
	var expected_queue := source_queue.duplicate()
	var first_empty := -1
	for index in range(5):
		if expected_queue[index] == 0:
			first_empty = index
			break
	if first_empty >= 0:
		expected_queue[first_empty] = int(call.get("registers", {}).get("a", -1))
	var expected_instruction_pcs: Array[int] = [0xEBD7, 0xEBDA, 0xEBDC, 0xEBDF,
		0xEBE1, 0xEBE4, 0xEBE6, 0xEBF9, 0xEBFC, 0xEC02, 0xEC05, 0xEB86, 0xEB88]
	var helper_cpu: Dictionary = helper.get("registers", {})
	var replay_executor = CBF1_EXECUTOR.new()
	if not replay_executor.configure_from_project_sources():
		return _fail("`$CBF1` consumer source setup failed: " + replay_executor.error_message)
	var replay: Dictionary = replay_executor.execute_from_root_cbf1_call(call)
	if String(result.get("status", "")) != "reached_scheduler_yield_handler_entry" \
			or int(result.get("entry_pc", -1)) != 0xEBD7 \
			or int(result.get("input_ram_052e", -1)) != 1 \
			or int(result.get("output_ram_052e", -1)) != 0 \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(call.get("caller_pc", -1)) != 0xEC02 \
			or int(call.get("target_pc", -1)) != 0xCBF1 \
			or int(call.get("return_word", -1)) != 0xEC04 \
			or int(call.get("return_pc", -1)) != 0xEC05 \
			or call.get("stack_writes", []) != call_stack_writes \
			or String(call.get("status", "")) != "source_cbf1_call_entry" \
			or not bool(helper.get("ok", false)) \
			or int(helper.get("rts_pc", -1)) not in [0xCBFD, 0xCC01] \
			or int(helper.get("return_pc", -1)) != 0xEC05 \
			or helper.get("output_queue", PackedByteArray()) != expected_queue \
			or ram.slice(0x0700, 0x0705) != expected_queue \
			or replay.get("output_queue", PackedByteArray()) != expected_queue \
			or replay.get("memory_writes", []) != helper.get("memory_writes", []) \
			or int(request.get("x", -1)) != int(helper_cpu.get("x", -2)) \
			or int(request.get("y", -1)) != int(helper_cpu.get("y", -2)) \
			or result.get("instruction_pcs", []) != expected_instruction_pcs \
			or bool(result.get("trace_state_used", true)) \
			or bool(helper.get("ppu_apu_effects_applied", true)):
		return _fail("The `$CBF1` root call/result, one-slot queue write, resumed root registers, or stop boundary differs.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
