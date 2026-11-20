extends SceneTree
## Exercises the ROM-byte PASS confirmation bridge from a source-derived
## scheduler fixture, adopts the CB0F/CAA5 yield, then executes one scheduler scan.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const DISPATCHER_SCRIPT := preload("res://scripts/gameplay/rom_first_action_dispatch_executor.gd")
const BRIDGE_SCRIPT := preload("res://scripts/gameplay/rom_first_action_confirmation_bridge_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scheduler = SCHEDULER_SCRIPT.new()
	var dispatcher = DISPATCHER_SCRIPT.new()
	var bridge = BRIDGE_SCRIPT.new()
	if not scheduler.configure_from_project_sources() \
			or scheduler.initialize_fresh_game_bootstrap().is_empty():
		_fail("Scheduler ROM source bootstrap failed: " + String(scheduler.error_message))
		return
	if not dispatcher.configure_from_project_sources() or not bridge.configure_from_project_sources():
		_fail("ROM-byte dispatcher/bridge configuration failed: " \
			+ String(dispatcher.error_message) + " " + String(bridge.error_message))
		return
	var context = scheduler._contexts.get(0x05)
	if context == null:
		_fail("The source-seeded slot-$05 scheduler context is missing.")
		return
	_make_d5ea_source_fixture(scheduler, context)
	var left_sample_result: Dictionary = scheduler.sample_controller_input(0x02)
	if not bool(left_sample_result.get("ok", false)):
		_fail("Source Left sample failed: " + str(left_sample_result))
		return
	var left_sample: Dictionary = left_sample_result["sample"]
	var selection: Dictionary = dispatcher.execute_from_live_action_menu_boundary(
		scheduler.get_task_boundary_snapshot(0x05), left_sample)
	var adopted_selection: Dictionary = scheduler.adopt_first_action_menu_input_result(selection)
	if not bool(adopted_selection.get("ok", false)) \
			or String(adopted_selection.get("accepted_status", "")) != "pass_selection_applied":
		_fail("The source-derived PASS selection fixture was not adopted: " + str(adopted_selection))
		return
	var release_result: Dictionary = scheduler.sample_controller_input(0)
	if not bool(release_result.get("ok", false)):
		_fail("Controller release sample failed: " + str(release_result))
		return
	var confirm_sample_result: Dictionary = scheduler.sample_controller_input(0x80)
	if not bool(confirm_sample_result.get("ok", false)):
		_fail("A-confirm controller sample failed: " + str(confirm_sample_result))
		return
	var confirm_sample: Dictionary = confirm_sample_result["sample"]
	var confirmation: Dictionary = dispatcher.execute_from_live_action_menu_boundary(
		scheduler.get_task_boundary_snapshot(0x05), confirm_sample)
	var adoption: Dictionary = scheduler.adopt_first_action_menu_input_result(confirmation)
	if not bool(adoption.get("ok", false)) \
			or String(adoption.get("status", "")) != "pass_confirmation_pending_source_execution" \
			or int(context.program_counter) != 0xD5EA:
		_fail("The scheduler did not consume A while preserving its D5EA boundary: " + str(adoption))
		return
	var live_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var result: Dictionary = bridge.execute_from_consumed_pass_confirmation(
		live_boundary, confirm_sample, adoption)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_confirmation_yielded_waiting_for_scheduler_nmi":
		_fail("The source bridge did not stop at its proven CB0F scheduler handoff: " + str(result))
		return
	if not _writes_match(result.get("source_writes", []), [
			[0xD684, 0x043C, 0x00], [0xCB0F, 0x007F, 0x01],
			[0xCB19, 0x0007, 0x1A], [0xCB1D, 0x0008, 0x1B],
			[0xCB21, 0x0005, 0x01], [0xCB26, 0x0006, int(result.get("saved_task_sp", -1))]]) \
			or not _stack_writes_match(result.get("source_stack_writes", []),
			int(result.get("entry_sp", -1)), int(live_boundary.get("y", -1))):
		_fail("Ordered D5EA/D67C/E93D/CB0F RAM or stack receipts differ from the source path.")
		return
	var registers: Dictionary = result.get("registers", {})
	var record: Array = result.get("saved_task_record", [])
	var handoff: Dictionary = result.get("scheduler_handoff", {})
	var mapper: Dictionary = result.get("mapper_state", {})
	if int(registers.get("pc", -1)) != 0xCAA5 \
			or int(registers.get("sp", -1)) != int(result.get("saved_task_sp", -2)) \
			or int(registers.get("a", -1)) != 0x05 \
			or int(registers.get("x", -1)) != 0x05 \
			or int(registers.get("y", -1)) != 0x05 \
			or int(result.get("task_resume_pc_after_scheduler", -1)) != 0xE945 \
			or record != [0x01, int(result.get("saved_task_sp", -1)), 0x1A, 0x1B] \
			or int(handoff.get("pc", -1)) != 0xCAA5 \
			or int(handoff.get("next_scan_slot_after_caa5", -1)) != 0x09 \
			or bool(handoff.get("nmi_wait_reached", true)) \
			or mapper.get("slot05_saved_bank_pair", []) != [0x1A, 0x1B] \
			or mapper.get("switchable_window_shadow_pair", []) != [0x1A, 0x1B] \
			or not mapper.get("mapper_writes_during_slice", []).is_empty() \
			or bool(result.get("d6c7_reached", true)) \
			or result.has("d6c7_boundary") or result.has("handler_entry_pc") \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)):
		_fail("The bridge did not preserve the actual CAA5/E945 scheduler handoff or emitted a false D6C7 endpoint.")
		return
	var invalid_adoption := adoption.duplicate(true)
	invalid_adoption["source_execution_pending"] = false
	var refused: Dictionary = bridge.execute_from_consumed_pass_confirmation(
		live_boundary, confirm_sample, invalid_adoption)
	if bool(refused.get("ok", true)) or refused.has("d6c7_boundary"):
		_fail("The bridge accepted a confirmation that was not pending source execution.")
		return
	var yielded: Dictionary = scheduler.adopt_first_action_confirmation_bridge_yield(result)
	var yielded_boundary: Dictionary = yielded.get("next_boundary_snapshot", {})
	if not bool(yielded.get("ok", false)) \
			or String(yielded.get("status", "")) != "pass_confirmation_yield_adopted" \
			or PackedByteArray(yielded.get("saved_task_record", PackedByteArray())) \
			!= PackedByteArray(result.get("saved_task_record", [])) \
			or int(yielded.get("source_handoff_pc", -1)) != 0xCAA5 \
			or int(yielded.get("source_resume_pc", -1)) != 0xE945 \
			or int(yielded.get("active_task_slot", -2)) != -1 \
			or int(yielded.get("scheduler_y_register", -1)) != 0x05 \
			or int(yielded.get("scheduler_scan_cursor", -1)) != 0x09 \
			or bool(yielded.get("source_scan_executed", true)) \
			or bool(yielded.get("nmi_delivery_claimed", true)) \
			or int(yielded_boundary.get("phase", -1)) != 3 \
			or int(yielded_boundary.get("pc", -1)) != 0xE945 \
			or int(yielded_boundary.get("sp", -1)) != int(result.get("saved_task_sp", -2)) \
			or int(yielded_boundary.get("ready_delay", -1)) != 1 \
			or PackedByteArray(yielded_boundary.get("record", PackedByteArray())) \
			!= PackedByteArray([0x01, int(result.get("saved_task_sp", -1)), 0x1A, 0x1B]) \
			or yielded_boundary.get("ram_image").slice(0x0100, 0x0200) != yielded_boundary.get("stack_page"):
		_fail("Scheduler did not adopt the verified slot-$05 CAA5 yield consistently: " + str(yielded))
		return
	var scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(scan.get("ok", false)) \
			or int(scan.get("selected_slot_base", -1)) != 0x09 \
			or int(scan.get("decision", -1)) != 0 \
			or scan.get("checked_slots", []) != [0x09] \
			or int(scan.get("scheduler_scan_cursor", -1)) != 0x09:
		_fail("The actual scheduler scan did not select the seeded slot-$09 task next: " + str(scan))
		return
	print("PASS: ROM-byte bridge executes the consumed PASS A path through `$D5EA->$D632->$D67C->$E93D->$CB0F->$CAA5`.")
	print("PASS: scheduler adopts ordered CB0F RAM/stack effects; slot-$05 yields at `$E945` with banks `$1A/$1B`.")
	print("PASS: `scan_ready_tasks_once()` selects seeded slot `$09` next (checked slots `[9]`); no NMI is claimed.")
	print("LIMIT: slot `$09` dispatch and later NMI/slot-$05 resume are outside this diagnostic; no `$D6C7` boundary is emitted.")
	quit(0)


func _make_d5ea_source_fixture(scheduler: Variant, context: Variant) -> void:
	# This fixture starts from the ordinary ROM-seeded slot-$05 task and uses
	# the ROM input dispatcher plus scheduler adoption for selection/confirmation.
	context.phase = 2
	context.program_counter = 0xD5EA
	context.bank_low = 0x1A
	context.bank_high = 0x1B
	context.source_label = "source-derived slot-$05 D5EA input fixture"
	scheduler._active_task_slot = 0x05
	scheduler._ram[0x0000] = 0x05
	scheduler._ram[0x0024] = 0x1A
	scheduler._ram[0x0025] = 0x1B
	scheduler._ram[0x0621] = 0
	scheduler._ram[0x043B] = 0
	scheduler._ram[0x061E] = 0


func _writes_match(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size():
		return false
	for index in expected.size():
		var event: Variant = value[index]
		if not event is Dictionary \
				or int(event.get("source_pc", -1)) != int(expected[index][0]) \
				or int(event.get("address", -1)) != int(expected[index][1]) \
				or int(event.get("value", -1)) != int(expected[index][2]):
			return false
	return true


func _stack_writes_match(value: Variant, entry_sp: int, entry_y: int) -> bool:
	if not value is Array or value.size() != 10 or entry_sp < 0 or entry_y < 0:
		return false
	var source_rows := [
		[0xD632, 0xD6, "jsr_push_high"], [0xD632, 0x34, "jsr_push_low"],
		[0xD687, 0xD6, "jsr_push_high"], [0xD687, 0x89, "jsr_push_low"],
		[0xE93D, 0x01, "pha"], [0xE93F, 0x00, "pha"],
		[0xE942, 0xE9, "jsr_push_high"], [0xE942, 0x44, "jsr_push_low"],
		[0xCB12, 0x00, "pha"], [0xCB14, entry_y & 0xFF, "pha"],
	]
	var sp := entry_sp & 0xFF
	for index in source_rows.size():
		var event: Dictionary = value[index]
		if int(event.get("source_pc", -1)) != int(source_rows[index][0]) \
				or int(event.get("address", -1)) != (0x0100 | sp) \
				or int(event.get("value", -1)) != int(source_rows[index][1]) \
				or String(event.get("operation", "")) != String(source_rows[index][2]):
			return false
		sp = (sp - 1) & 0xFF
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
