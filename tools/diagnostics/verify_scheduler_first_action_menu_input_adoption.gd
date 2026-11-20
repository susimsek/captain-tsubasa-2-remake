extends SceneTree
## Verifies source-boundary adoption for the PASS menu poll and CB99 dispatch.
## Positive task boundaries here are synthetic fixtures; no FCEUX data is used.

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const DISPATCHER := preload("res://scripts/gameplay/rom_first_action_dispatch_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const INPUT_SPAN_SHA256 := "ad109ac091d382e1dca97d8d9c596617187b6f37e0ea0a965cc090066822d101"
const DIRECTION_TABLE_SHA256 := "dce8e125cc41a56ea02407a10727c0fbced6827fea37a619f5c3cc98f1ee4968"
const HANDLER_SPAN_SHA256 := "9ccc071c8af66e997b4fe1fe3613af4e764d756c35c6c96118ceba7faf034032"
const INLINE_DISPATCH_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:	
	var scheduler = SCHEDULER.new()
	var executor = DISPATCHER.new()
	if not scheduler.configure_from_project_sources() \
			or scheduler.initialize_fresh_game_bootstrap().is_empty():
		_fail("Scheduler source bootstrap failed: " + String(scheduler.error_message))
		return
	if not executor.configure_from_project_sources():
		_fail("PASS dispatch source configuration failed: " + String(executor.error_message))
		return
	var context = scheduler._contexts.get(0x05)
	if context == null:
		_fail("Source-seeded root slot-$05 context is missing.")
		return
	_set_action_menu_boundary(scheduler, context)

	var left_sample_result: Dictionary = scheduler.sample_controller_input(0x02)
	if not bool(left_sample_result.get("ok", false)):
		_fail("Left sample failed: " + str(left_sample_result))
		return
	var left_sample: Dictionary = left_sample_result["sample"]
	var left_boundary := _make_d5ea_boundary(scheduler, context)
	var selection_result: Dictionary = executor.execute_from_live_action_menu_boundary(
		left_boundary, left_sample)
	var adopted_selection: Dictionary = scheduler.adopt_first_action_menu_input_result(selection_result)
	if not bool(adopted_selection.get("ok", false)) \
			or String(adopted_selection.get("accepted_status", "")) != "pass_selection_applied" \
			or adopted_selection.get("source_writes_applied", []).size() != 3 \
			or int(scheduler._ram[0x043B]) != 1 or int(scheduler._ram[0x061E]) != 0x81 \
			or int(context.program_counter) != 0xD5EA:
		_fail("Scheduler did not adopt only the ROM PASS-selection writes: " + str(adopted_selection))
		return
	var duplicate_selection: Dictionary = scheduler.adopt_first_action_menu_input_result(selection_result)
	if bool(duplicate_selection.get("ok", true)):
		_fail("Scheduler accepted a replayed/consumed selection receipt.")
		return

	# Release Left, then execute/adopt a distinct A edge. This consumes the input
	# receipt but deliberately leaves the scheduler at its old $D5EA boundary.
	var release_result: Dictionary = scheduler.sample_controller_input(0)
	if not bool(release_result.get("ok", false)):
		_fail("Left release sample failed before A confirmation.")
		return
	var confirm_sample_result: Dictionary = scheduler.sample_controller_input(0x80)
	if not bool(confirm_sample_result.get("ok", false)):
		_fail("A confirmation sample failed.")
		return
	var confirm_sample: Dictionary = confirm_sample_result["sample"]
	var confirmation_result: Dictionary = executor.execute_from_live_action_menu_boundary(
		_make_d5ea_boundary(scheduler, context), confirm_sample)
	var adopted_confirmation: Dictionary = scheduler.adopt_first_action_menu_input_result(confirmation_result)
	if not bool(adopted_confirmation.get("ok", false)) \
			or String(adopted_confirmation.get("status", "")) \
			!= "pass_confirmation_pending_source_execution" \
			or int(adopted_confirmation.get("source_boundary_pc", -1)) != 0xD5EA \
			or not bool(adopted_confirmation.get("source_execution_pending", false)) \
			or adopted_confirmation.has("resume_pc") \
			or adopted_confirmation.has("handler_entry_pc") \
			or adopted_confirmation.has("handler_handoff_target_pc") \
			or adopted_confirmation.has("next_boundary_snapshot") \
			or int(context.program_counter) != 0xD5EA \
			or not bool(scheduler._slot05_pass_handler_dispatch_pending):
		_fail("A confirmation invented a later source PC/target or failed to retain the unresolved `$D5EA` boundary: " + str(adopted_confirmation))
		return
	if bool(scheduler.sample_controller_input(0).get("ok", true)):
		_fail("A second controller sample was accepted after confirmation while source execution is pending.")
		return

	var before_pending_pc: int = context.program_counter
	var stale_dispatch := _legacy_d5c3_dispatch_claim()
	var stale_adoption: Dictionary = scheduler.adopt_first_action_menu_handler_dispatch(stale_dispatch)
	if bool(stale_adoption.get("ok", true)) or context.program_counter != before_pending_pc:
		_fail("Scheduler accepted a historical D5C3 result claiming D7E8 dispatch: " + str(stale_adoption))
		return

	# A source executor may be called only after the ordinary source route has
	# actually advanced its scheduler-owned context to D6C7. This fixture models
	# that boundary for the narrow adopter test; it is not route evidence.
	_seed_live_d6c7_fixture(scheduler, context)
	var before_unproven_rejection: int = context.program_counter
	var before_unproven_pointer := [int(scheduler._ram[0x0036]), int(scheduler._ram[0x0037])]
	var unproven_claim := _unproven_d6c7_dispatch_claim()
	var unproven_adoption: Dictionary = scheduler.adopt_first_action_menu_handler_dispatch(unproven_claim)
	if bool(unproven_adoption.get("ok", true)) \
			or context.program_counter != before_unproven_rejection \
			or int(scheduler._ram[0x0036]) != before_unproven_pointer[0] \
			or int(scheduler._ram[0x0037]) != before_unproven_pointer[1]:
		_fail("Scheduler accepted a D6C7 endpoint claim without live CB99 reads/writes/stack evidence.")
		return
	var live_d6c7 := _make_d6c7_boundary(scheduler, context)
	var dispatch_result: Dictionary = executor.execute_pass_cb99_from_live_d6c7_boundary(live_d6c7)
	if not bool(dispatch_result.get("ok", false)) \
			or String(dispatch_result.get("status", "")) != "pass_cb99_dispatched":
		_fail("The source executor did not produce a live D6C7 CB99 result: " + str(dispatch_result))
		return
	var adopted_dispatch: Dictionary = scheduler.adopt_first_action_menu_handler_dispatch(dispatch_result)
	var next_boundary: Dictionary = adopted_dispatch.get("next_boundary_snapshot", {})
	if not bool(adopted_dispatch.get("ok", false)) \
			or String(adopted_dispatch.get("status", "")) != "pass_handler_entry_adopted" \
			or int(adopted_dispatch.get("source_boundary_pc", -1)) != 0xD6C7 \
			or int(context.program_counter) != 0xD7E8 \
			or int(context.stack_pointer) != 0x4A \
			or int(scheduler._ram[0x0036]) != 0xE8 \
			or int(scheduler._ram[0x0037]) != 0xD7 \
			or int(scheduler._stack_page[0x4A]) != 0xD6 \
			or int(scheduler._stack_page[0x49]) != 0xC9 \
			or int(scheduler._stack_page[0x48]) != 0xE8 \
			or int(scheduler._ram[0x014A]) != int(scheduler._stack_page[0x4A]) \
			or int(scheduler._ram[0x0149]) != int(scheduler._stack_page[0x49]) \
			or int(scheduler._ram[0x0148]) != int(scheduler._stack_page[0x48]) \
			or int(context.accumulator) != 0xE8 or int(context.y_register) != 0x04 \
			or int(context.x_register) != 0x57 \
			or int(next_boundary.get("pc", -1)) != 0xD7E8 \
			or int(next_boundary.get("executing_cpu_bank", -1)) != 0x1E \
			or not bool(next_boundary.get("mapper_proof", {}).get("fixed_bank", -1) == 0x1E):
		_fail("Scheduler did not apply the exact live CB99 events at D7E8: " + str(adopted_dispatch))
		return
	if bool(scheduler._slot05_pass_handler_dispatch_pending):
		_fail("Successful D6C7/CB99 adoption did not consume its one-use confirmation.")
		return
	var duplicate_dispatch: Dictionary = scheduler.adopt_first_action_menu_handler_dispatch(dispatch_result)
	if bool(duplicate_dispatch.get("ok", true)):
		_fail("Scheduler accepted a replayed live D6C7 CB99 result.")
		return

	print("PASS: D5EA A confirmation consumes its receipt but remains at D5EA with no synthesized D5C3/D7E8 target; further input is blocked.")
	print("PASS: historical D5C3 and incomplete D6C7 endpoint claims are rejected; only live D6C7->$CB99 reads/writes/stack/register/mapper evidence advances to D7E8.")
	print("LIMIT: positive D6C7 boundary is a synthetic scheduler fixture; production source route and FCEUX parity remain unverified.")
	quit(0)


func _set_action_menu_boundary(scheduler: Variant, context: Variant) -> void:
	context.phase = 2
	context.program_counter = 0xD5EA
	context.bank_low = 0x1A
	context.bank_high = 0x1B
	context.source_label = "synthetic validated slot-$05 `$D5EA` poll fixture"
	scheduler._active_task_slot = 0x05
	scheduler._ram[0x0000] = 0x05
	scheduler._ram[0x0024] = 0x1A
	scheduler._ram[0x0025] = 0x1B
	scheduler._ram[0x0621] = 0
	scheduler._ram[0x043B] = 0
	scheduler._ram[0x061E] = 0


func _make_d5ea_boundary(scheduler: Variant, context: Variant) -> Dictionary:
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": context.phase,
		"pc": context.program_counter,
		"sp": context.stack_pointer,
		"a": context.accumulator,
		"x": context.x_register,
		"y": context.y_register,
		"p": context.status_register,
		"p_known_mask": context.status_known_mask,
		"bank_low": context.bank_low,
		"bank_high": context.bank_high,
		"ram_image": scheduler._ram.duplicate(),
	}


func _seed_live_d6c7_fixture(scheduler: Variant, context: Variant) -> void:
	context.program_counter = 0xD6C7
	context.stack_pointer = 0x4A
	context.accumulator = 1
	context.x_register = 0x57
	context.y_register = 2
	context.status_register = 0x20
	context.status_known_mask = 0x20
	context.source_label = "synthetic source-owned slot-$05 `$D6C7` fixture"
	scheduler._ram[0x043B] = 1
	scheduler._ram[0x061E] = 0x81
	scheduler._ram[0x001C] = 0x80
	scheduler._ram[0x001E] = 0x80
	scheduler._stack_page[0x4C] = 0xD6
	scheduler._stack_page[0x4B] = 0x34
	scheduler._ram[0x014C] = 0xD6
	scheduler._ram[0x014B] = 0x34


func _make_d6c7_boundary(scheduler: Variant, context: Variant) -> Dictionary:
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": context.phase,
		"pc": context.program_counter,
		"sp": context.stack_pointer,
		"a": context.accumulator,
		"x": context.x_register,
		"y": context.y_register,
		"p": context.status_register,
		"p_known_mask": context.status_known_mask,
		"bank_low": context.bank_low,
		"bank_high": context.bank_high,
		"ram_image": scheduler._ram.duplicate(),
		"stack_page": scheduler._stack_page.duplicate(),
		"mapper": {"bank_registers": {6: 0x1C, 7: 0x1D}},
	}


func _legacy_d5c3_dispatch_claim() -> Dictionary:
	return {
		"ok": true,
		"status": "pass_handler_dispatched",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": MANIFEST_SHA256,
		"input_span_sha256": INPUT_SPAN_SHA256,
		"direction_table_sha256": DIRECTION_TABLE_SHA256,
		"handler_span_sha256": HANDLER_SPAN_SHA256,
		"inline_dispatch_span_sha256": INLINE_DISPATCH_SHA256,
		"source_boundary_pc": 0xD5C3,
		"resume_pc": 0xD7E8,
		"handler_entry_pc": 0xD7E8,
		"caller_return_pc": 0xD634,
		"trace_state_used": false,
		"source_writes": [],
		"source_stack_writes": [],
	}


func _unproven_d6c7_dispatch_claim() -> Dictionary:
	return {
		"ok": true,
		"status": "pass_cb99_dispatched",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": MANIFEST_SHA256,
		"input_span_sha256": INPUT_SPAN_SHA256,
		"direction_table_sha256": DIRECTION_TABLE_SHA256,
		"handler_span_sha256": HANDLER_SPAN_SHA256,
		"inline_dispatch_span_sha256": INLINE_DISPATCH_SHA256,
		"source_boundary_pc": 0xD6C7,
		"resume_pc": 0xD7E8,
		"handler_entry_pc": 0xD7E8,
		"caller_return_pc": 0xD6C9,
		"outer_caller_return_pc": 0xD634,
		"trace_state_used": false,
		"source_writes": [],
		"source_stack_writes": [],
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
