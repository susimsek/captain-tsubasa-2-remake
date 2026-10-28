extends SceneTree

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_root_slot01_continuation_runtime.gd")


func _initialize() -> void:
	if not _verify_continuation_contract():
		quit(1)
		return
	print("PASS: packaged ROM bytes drive the slot-$01 $CA52 → $EE9F → $E3CA → $CA4F caller continuation and yield contract.")
	print("LIMIT: callee bodies, their live register/RAM effects, NMI cadence, and production route integration remain unmodeled.")
	quit(0)


func _verify_continuation_contract() -> bool:
	var helper = CONTINUATION_SCRIPT.new()
	if not helper.configure_from_project_sources():
		return _fail("Continuation helper rejected its packaged source: " + helper.error_message)
	var helper_status: Dictionary = helper.get_status()
	if helper_status.get("rom_sha256", "") != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or helper_status.get("source_sha256", "") != "e57b4fe7ceb639050a5d21b6a8d4ea958c181137f63ded21388b9ad9715a094a" \
			or bool(helper_status.get("executes_ee9f_body", true)) \
			or bool(helper_status.get("executes_e3ca_body", true)) \
			or bool(helper_status.get("accepts_capture_ram_or_emulator_frame_input", true)):
		return _fail("Continuation helper must report its exact ROM source and limited execution boundary.")

	var scheduler = SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources() \
			or not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Could not initialize the ROM-byte scheduler source fixture: " + scheduler.error_message)
	scheduler.apply_external_nmi_delivery(8459, 0x88, false)
	var root_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if int(root_scan.get("selected_slot_base", -1)) != 0x01:
		return _fail("Fresh scheduler fixture did not initially select slot $01.")
	var root_dispatch: Dictionary = scheduler.dispatch_pending_task(0x01)
	var initial_root_yield: Dictionary = scheduler.execute_root_slot01_startup_to_first_yield()
	if not bool(initial_root_yield.get("ok", false)) \
			or int(initial_root_yield.get("resume_pc", -1)) != 0xCA52:
		return _fail("ROM startup helper did not leave the root task at its $CA52 continuation.")
	if not _yield_other_seeded_slot_at_test_callsite(scheduler, 0x05) \
			or not _yield_other_seeded_slot_at_test_callsite(scheduler, 0x09):
		return false
	var nmi_edge: Dictionary = scheduler.apply_external_nmi_delivery(1, 0x88, true)
	if not bool(nmi_edge.get("ok", false)):
		return _fail("Could not provide the explicit test-only NMI-ready event.")
	var consumed_latch: Dictionary = scheduler.scan_ready_tasks_once()
	if int(consumed_latch.get("decision", -1)) != SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN:
		return _fail("Scheduler did not clear the explicit NMI-ready latch before rescanning.")
	var root_resume_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if int(root_resume_scan.get("decision", -1)) != SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME \
			or int(root_resume_scan.get("selected_slot_base", -1)) != 0x01:
		return _fail("ROM scheduler did not resume the one-tick slot-$01 continuation.")
	var dispatch: Dictionary = scheduler.dispatch_pending_task(0x01)
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0xCA52 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts":
		return _fail("Root task did not resume through the source scheduler at $CA52.")

	var wrong_slot: Dictionary = dispatch.duplicate(true)
	wrong_slot["slot_base"] = 0x05
	if bool(helper.begin_from_slot01_yielded_resume(wrong_slot).get("ok", false)):
		return _fail("Continuation accepted a non-root task dispatch.")
	var first_call: Dictionary = helper.begin_from_slot01_yielded_resume(dispatch)
	if not bool(first_call.get("ok", false)) \
			or first_call.get("status", "") != "call_requested" \
			or int(first_call.get("source_pc", -1)) != 0xCA52 \
			or int(first_call.get("target_cpu_address", -1)) != 0xEE9F \
			or int(first_call.get("expected_return_pc", -1)) != 0xCA55 \
			or int(first_call.get("call_ordinal", -1)) != 0:
		return _fail("$CA52 did not produce the source-derived first $EE9F call request.")
	if bool(helper.accept_callee_return(0xEE9F, 0xCA56, _test_cpu_state()).get("ok", false)):
		return _fail("Continuation accepted an incorrect $EE9F return PC.")
	var actor_return_state := _test_cpu_state()
	actor_return_state["a"] = 0x55
	var second_call: Dictionary = helper.accept_callee_return(0xEE9F, 0xCA55, actor_return_state)
	if not bool(second_call.get("ok", false)) \
			or second_call.get("status", "") != "call_requested" \
			or int(second_call.get("source_pc", -1)) != 0xCA55 \
			or int(second_call.get("target_cpu_address", -1)) != 0xE3CA \
			or int(second_call.get("expected_return_pc", -1)) != 0xCA58 \
			or int(second_call.get("a", -1)) != 0x55:
		return _fail("The source continuation did not request $E3CA with returned caller registers.")
	var invalid_return_state := _test_cpu_state()
	invalid_return_state["x"] = 0x100
	if bool(helper.accept_callee_return(0xE3CA, 0xCA58, invalid_return_state).get("ok", false)):
		return _fail("Continuation accepted a non-byte CPU register value.")
	var field_return_state := _test_cpu_state()
	field_return_state["a"] = 0x99
	field_return_state["x"] = 0x03
	field_return_state["y"] = 0x04
	var yield_request: Dictionary = helper.accept_callee_return(0xE3CA, 0xCA58, field_return_state)
	if not bool(yield_request.get("ok", false)) \
			or yield_request.get("status", "") != "yield_requested" \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or int(yield_request.get("target_cpu_address", -1)) != 0xCB0F \
			or int(yield_request.get("resume_pc", -1)) != 0xCA52 \
			or int(yield_request.get("delay_in_a", -1)) != 1 \
			or int(yield_request.get("x", -1)) != 0x03 \
			or int(yield_request.get("y", -1)) != 0x04 \
			or int(yield_request.get("sp", -1)) != 0x2A:
		return _fail("$E3CA return did not flow through JMP/LDA into the exact $CA4F yield request.")
	if bool(yield_request.get("callee_body_executed", true)):
		return _fail("The source caller helper must not claim to execute either subroutine body.")

	# This is a synthetic, test-only callee return fixture. In production, the
	# same values must come from the separate decoded $EE9F/$E3CA source runner.
	var root_context = scheduler.get_task_context(0x01)
	root_context.program_counter = int(yield_request["callsite_pc"])
	root_context.accumulator = int(yield_request["delay_in_a"])
	root_context.x_register = int(yield_request["x"])
	root_context.y_register = int(yield_request["y"])
	root_context.stack_pointer = int(yield_request["sp"])
	root_context.bank_low = int(yield_request["bank_low"])
	root_context.bank_high = int(yield_request["bank_high"])
	if not scheduler.yield_at_verified_callsite(0x01, 0xCA4F,
			int(yield_request["delay_in_a"]), int(yield_request["sp"]),
			int(yield_request["x"]), int(yield_request["y"]),
			int(yield_request["bank_low"]), int(yield_request["bank_high"])):
		return _fail("The source-derived $CA4F yield request was rejected by the existing task scheduler: " + scheduler.error_message)
	var status: Dictionary = scheduler.get_status()
	if _record_for_slot(status.get("task_slots", []), 0x01) != PackedByteArray([0x01, 0x26, 0x00, 0x01]) \
			or int(status.get("scheduler_scan_cursor", -1)) != 0x05:
		return _fail("Applying the continuation's yield did not preserve the ROM task save/cursor contract.")
	return true


func _yield_other_seeded_slot_at_test_callsite(scheduler: Variant, slot_base: int) -> bool:
	var scan: Dictionary = scheduler.scan_ready_tasks_once()
	if int(scan.get("selected_slot_base", -1)) != slot_base:
		return _fail("Test-only scheduler fixture expected slot $%02X." % slot_base)
	var dispatch: Dictionary = scheduler.dispatch_pending_task(slot_base)
	if not bool(dispatch.get("ok", false)):
		return _fail("Test-only scheduler fixture could not dispatch slot $%02X." % slot_base)
	var context = scheduler.get_task_context(slot_base)
	context.program_counter = 0x856F
	if not scheduler.yield_at_verified_callsite(slot_base, 0x856F, 1,
			context.stack_pointer, context.x_register, context.y_register,
			context.bank_low, context.bank_high):
		return _fail("Test-only slot $%02X task could not yield at the packaged callsite." % slot_base)
	return true


func _test_cpu_state() -> Dictionary:
	return {"a": 0x10, "x": 0x28, "y": 0x78, "sp": 0x2A, "bank_low": 0x00, "bank_high": 0x01}


func _record_for_slot(records: Array, slot_base: int) -> PackedByteArray:
	for record_variant in records:
		if record_variant is Dictionary and int(record_variant.get("slot_base", -1)) == slot_base:
			return record_variant.get("bytes", PackedByteArray())
	return PackedByteArray()


func _fail(message: String) -> bool:
	printerr("FAIL: " + message)
	return false
