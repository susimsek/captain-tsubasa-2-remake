extends SceneTree

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-byte slot-$11 resume writes were replayed into the synthetic live scheduler context and saved at `$CB0F`.")
	print("PASS: the `$CC50->$CB0F` return word was reused once; `$CB0F` then saved X/Y and slot `$11` as `01 BF 18 19`.")
	print("LIMIT: the fixture injects a valid `$804A` context; it does not establish that the production route reaches this boundary.")
	quit(0)


func _verify() -> bool:
	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources() \
			or not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Task scheduler source setup failed: " + scheduler.error_message)
	if not _install_synthetic_slot11_boundary(scheduler):
		return _fail("Could not install the explicitly synthetic running slot-$11 fixture.")
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$11 resume source package failed validation: " + executor.error_message)
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
	var result: Dictionary = executor.execute_from_resumed_slot11_boundary(boundary)
	if not bool(result.get("ok", false)):
		return _fail("ROM-byte resume executor rejected its synthetic live boundary: " + String(result.get("error", "unknown error")))
	var corrupted: Dictionary = result.duplicate(true)
	corrupted["source_manifest"] = "wrong-manifest"
	var before_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
	var before_ram: PackedByteArray = scheduler._ram.duplicate()
	var before_stack: PackedByteArray = scheduler._stack_page.duplicate()
	var rejected: Dictionary = scheduler.apply_slot11_actor_worker_resume_result(corrupted)
	if not rejected.is_empty() or scheduler.get_task_boundary_snapshot(0x11) != before_boundary \
			or scheduler._ram != before_ram or scheduler._stack_page != before_stack:
		return _fail("Scheduler accepted a wrong source manifest or mutated the live state on rejection.")
	var saved: Dictionary = scheduler.apply_slot11_actor_worker_resume_result(result)
	if not bool(saved.get("ok", false)):
		return _fail("Scheduler rejected the source-derived `$CC50->$CB0F` result: " + scheduler.error_message)
	var saved_boundary: Dictionary = saved.get("saved_boundary", {})
	var record: PackedByteArray = saved.get("task_record", PackedByteArray())
	var stack: PackedByteArray = scheduler._stack_page
	if String(saved.get("status", "")) != "slot11_actor_resume_saved_at_cb0f" \
			or record != PackedByteArray([0x01, 0xBF, 0x18, 0x19]) \
			or int(saved_boundary.get("pc", -1)) != 0xCB0F \
			or int(saved_boundary.get("sp", -1)) != 0xBF \
			or int(saved_boundary.get("ready_delay", -1)) != 0x01 \
			or stack[0xC0] != 0x0C or stack[0xC1] != 0x52 \
			or stack[0xC2] != 0x52 or stack[0xC3] != 0xCC \
			or stack[0xC4] != 0x06 \
			or int(scheduler._ram[0x007F]) != 0x01 \
			or int(saved.get("scheduler_scan_cursor", -1)) != 0x15 \
			or int(saved.get("scheduler_y_register", -1)) != 0x11 \
			or int(saved.get("active_task_slot", -1)) != -1 \
			or not bool(saved.get("preexisting_jsr_frame_reused", false)) \
			or bool(saved.get("source_ram_image_copied", true)):
		return _fail("Scheduler's `$CB0F` save changed the task record, call frame, scan state, or saved registers.")
	if not _verify_scenario1c_f0_zero_mode_gate(scheduler):
		return false
	if not _verify_scenario1c_f0_inactive_zero_mode_resume():
		return false
	if not _verify_scenario1e_actor58_f4_zero_idle_resume():
		return false
	return true


func _verify_scenario1c_f0_inactive_zero_mode_resume() -> bool:
	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources() \
			or not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Scenario-$1C inactive zero-mode scheduler setup failed: " + scheduler.error_message)
	var ram: PackedByteArray = scheduler._ram.duplicate()
	var stack: PackedByteArray = scheduler._stack_page.duplicate()
	ram[0x0000] = 0x11
	ram[0x0011] = 0x00
	ram[0x0012] = 0xC6
	ram[0x0013] = 0x18
	ram[0x0014] = 0x19
	ram[0x0022] = 0x00
	ram[0x005F] = 0x00
	ram[0x0060] = 0x94
	ram[0x0063] = 0xD7
	ram[0x0064] = 0xA2
	ram[0x0515] = 0x00
	ram[0x05E3] = 0x00
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x02
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05EA] = 0x00
	ram[0x05F3] = 0x01
	ram[0x05F4] = 0x00
	ram[0x05F5] = 0x01
	stack[0xC7] = 0x02
	stack[0xC8] = 0x21
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	scheduler._ram = ram
	scheduler._stack_page = stack
	var context = SCHEDULER.TaskContext.new()
	context.slot_base = 0x11
	context.ready_delay = 0
	context.phase = 2
	context.pending_resume = 0
	context.program_counter = 0x804A
	context.stack_pointer = 0xCA
	context.accumulator = 0x21
	context.x_register = 0x21
	context.y_register = 0x02
	context.status_register = 0x20
	context.status_known_mask = 0x83
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	context.source_label = "synthetic recorded scenario-$1C F0 inactive zero-mode boundary"
	scheduler._contexts[0x11] = context
	scheduler._active_task_slot = 0x11
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Scenario-$1C inactive zero-mode source setup failed: " + executor.error_message)
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
	var worker: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
	if not bool(worker.get("ok", false)) \
			or String(worker.get("status", "")) != "slot11_actor_scenario1c_f0_inactive_zero_mode_resume_at_8047" \
			or int(worker.get("exit_pc", -1)) != 0x8047:
		return _fail("Scenario-$1C inactive zero-mode executor failed: " \
				+ str(worker.get("reason", worker.get("error", "unknown error"))))
	var adopted: Dictionary = scheduler.apply_slot11_f5_animation_countdown_result(worker)
	var saved: Dictionary = adopted.get("saved_boundary", {})
	if not bool(adopted.get("ok", false)) \
			or String(adopted.get("status", "")) != "slot11_actor_rom_stream_delay_saved_at_cb0f" \
			or int(adopted.get("callsite_pc", -1)) != 0x8047 \
			or int(saved.get("pc", -1)) != 0xCB0F \
			or int(saved.get("sp", -1)) != 0xC6 \
			or bool(adopted.get("trace_state_used", true)):
		return _fail("Scenario-$1C inactive zero-mode adoption failed: " + scheduler.error_message \
				+ " adoption=" + JSON.stringify({"ok": adopted.get("ok", false),
					"status": adopted.get("status", ""), "callsite_pc": adopted.get("callsite_pc", -1),
					"saved": saved, "trace_state_used": adopted.get("trace_state_used", true)}))
	print("PASS: scenario-$1C F0 inactive worker follows `$804A->$8053 RTS->$A1EB F4=0 RTS->$8047->$CB0F`.")
	print("LIMIT: this focused boundary fixture is synthetic; full recorded-input replay establishes route reachability.")
	return true


func _verify_scenario1e_actor58_f4_zero_idle_resume() -> bool:
	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources() \
			or not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Scenario-$1E actor-$58 idle scheduler setup failed: " + scheduler.error_message)
	var ram: PackedByteArray = scheduler._ram.duplicate()
	var stack: PackedByteArray = scheduler._stack_page.duplicate()
	ram[0x0000] = 0x11
	ram[0x0011] = 0x00
	ram[0x0012] = 0xC6
	ram[0x0013] = 0x18
	ram[0x0014] = 0x19
	ram[0x0022] = 0x00
	ram[0x005D] = 0xE3
	ram[0x005E] = 0xB7
	ram[0x005F] = 0x62
	ram[0x0060] = 0x9A
	ram[0x0063] = 0xBC
	ram[0x0064] = 0xA2
	ram[0x0065] = 0x00
	ram[0x0515] = 0x80
	ram[0x0516] = 0x00
	ram[0x0517] = 0x40
	ram[0x0518] = 0x1E
	ram[0x0519] = 0x00
	ram[0x051A] = 0xE8
	ram[0x051B] = 0x9B
	ram[0x051C] = 0x00
	ram[0x0522] = 0x00
	ram[0x0523] = 0x07
	ram[0x0524] = 0x45
	ram[0x0525] = 0x06
	ram[0x0526] = 0x00
	ram[0x0527] = 0x3C
	ram[0x0528] = 0x90
	ram[0x0529] = 0xFF
	ram[0x052A] = 0x00
	ram[0x05E3] = 0x00
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x0E
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05EA] = 0x58
	ram[0x05F3] = 0x00
	ram[0x05F4] = 0x00
	ram[0x05F5] = 0x01
	ram[0x0629] = 0x00
	stack[0xC7] = 0x04
	stack[0xC8] = 0x04
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	scheduler._ram = ram
	scheduler._stack_page = stack
	var context = SCHEDULER.TaskContext.new()
	context.slot_base = 0x11
	context.ready_delay = 0
	context.phase = 2
	context.pending_resume = 0
	context.program_counter = 0x804A
	context.stack_pointer = 0xCA
	context.accumulator = 0x04
	context.x_register = 0x04
	context.y_register = 0x04
	context.status_register = 0x20
	context.status_known_mask = 0x83
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	context.source_label = "synthetic scenario-$1E actor-$58 F4=0 idle resume boundary"
	scheduler._contexts[0x11] = context
	scheduler._active_task_slot = 0x11
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Scenario-$1E actor-$58 idle source setup failed: " + executor.error_message)
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
	var worker: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
	if not bool(worker.get("ok", false)) \
			or String(worker.get("status", "")) != "slot11_actor_scenario1e_actor58_inactive_zero_mode_resume_at_8047" \
			or int(worker.get("exit_pc", -1)) != 0x8047:
		return _fail("Scenario-$1E actor-$58 F4=0 idle executor failed: " \
				+ str(worker.get("reason", worker.get("error", "unknown error"))))
	var adopted: Dictionary = scheduler.apply_slot11_f5_animation_countdown_result(worker)
	var saved: Dictionary = adopted.get("saved_boundary", {})
	if not bool(adopted.get("ok", false)) \
			or String(adopted.get("status", "")) != "slot11_actor_rom_stream_delay_saved_at_cb0f" \
			or int(adopted.get("callsite_pc", -1)) != 0x8047 \
			or int(saved.get("pc", -1)) != 0xCB0F \
			or int(scheduler._ram[0x05F5]) != 0x01 \
			or scheduler._ram.slice(0x0063, 0x0065) != PackedByteArray([0xBC, 0xA2]) \
			or int(scheduler._ram[0x0515]) != 0x80 \
			or bool(adopted.get("trace_state_used", true)):
		return _fail("Scenario-$1E actor-$58 idle scheduler adoption failed: " + scheduler.error_message \
				+ " adoption=" + JSON.stringify({"ok": adopted.get("ok", false),
					"status": adopted.get("status", ""), "callsite_pc": adopted.get("callsite_pc", -1),
					"saved": saved, "trace_state_used": adopted.get("trace_state_used", true)}))
	print("PASS: scenario-$1E actor-$58 F4=0 follows `$804A->$8053 RTS->$A1EB RTS->$8047->$CB0F` without advancing `$A2BC` or `$05F5`.")
	print("LIMIT: this focused boundary fixture is synthetic; only recorded-input route replay establishes production reachability.")
	return true


func _verify_scenario1c_f0_zero_mode_gate(scheduler) -> bool:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0000] = 0x11
	ram[0x0011] = 0x00
	ram[0x0012] = 0xC2
	ram[0x0013] = 0x18
	ram[0x0014] = 0x19
	ram[0x005F] = 0x00
	ram[0x0060] = 0x94
	ram[0x0022] = 0x00
	ram[0x0515] = 0x00
	ram[0x0516] = 0x61
	ram[0x0517] = 0x40
	ram[0x0518] = 0x1C
	ram[0x0519] = 0x26
	ram[0x05E3] = 0x00
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x02
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05EA] = 0x00
	ram[0x05F3] = 0x01
	ram[0x05F4] = 0x00
	ram[0x05F5] = 0x01
	ram[0x0063] = 0xD7
	ram[0x0064] = 0xA2
	stack[0xC7] = 0x7C
	stack[0xC8] = 0x80
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	scheduler._ram = ram.duplicate()
	scheduler._stack_page = stack.duplicate()
	scheduler._ram[0x0100 + 0xC7] = 0x7C
	scheduler._ram[0x0100 + 0xC8] = 0x80
	scheduler._ram[0x0100 + 0xC9] = 0x4C
	scheduler._ram[0x0100 + 0xCA] = 0x80
	var context = SCHEDULER.TaskContext.new()
	context.slot_base = 0x11
	context.ready_delay = 0
	context.phase = 2
	context.pending_resume = 0
	context.program_counter = 0x804D
	context.stack_pointer = 0xCA
	context.accumulator = 0x80
	context.x_register = 0x21
	context.y_register = 0x02
	context.status_register = 0xA0
	context.status_known_mask = 0x83
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	context.source_label = "synthetic recorded slot-$11 scenario-$1C F0 gate boundary"
	scheduler._contexts[0x11] = context
	scheduler._active_task_slot = 0x11
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Scenario-$1C F0 gate source setup failed: " + executor.error_message)
	var worker: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(
		scheduler.get_task_boundary_snapshot(0x11))
	if not bool(worker.get("ok", false)) \
			or String(worker.get("status", "")) != "slot11_actor_scenario1c_f0_zero_mode_gate_at_8047" \
			or int(worker.get("exit_pc", -1)) != 0x8047:
		return _fail("Scenario-$1C F0 executor boundary failed: " + str(worker.get("reason", worker.get("error", "unknown error"))))
	var adopted: Dictionary = scheduler.apply_slot11_actor_scenario1c_f0_zero_mode_gate_result(worker)
	if not bool(adopted.get("ok", false)):
		return _fail("Scheduler rejected the source-derived scenario-$1C F0 yield: " + scheduler.error_message)
	var saved: Dictionary = adopted.get("saved_boundary", {})
	if String(adopted.get("status", "")) != "slot11_actor_scenario1c_f0_zero_mode_gate_saved_at_cb0f" \
			or int(adopted.get("callsite_pc", -1)) != 0x8047 \
			or int(saved.get("pc", -1)) != 0xCB0F \
			or bool(adopted.get("trace_state_used", true)):
		return _fail("Scenario-$1C F0 adoption did not save its ROM callsite at `$CB0F`: " \
				+ JSON.stringify({"adoption_status": adopted.get("status", ""),
					"callsite_pc": adopted.get("callsite_pc", -1), "saved": saved,
					"trace_state_used": adopted.get("trace_state_used", true)}))
	print("PASS: scenario-$1C `$F0` zero-mode follows the `$804D->$C560->$A1EB RTS->$8047->$CB0F` source path and scheduler yield.")
	print("LIMIT: the boundary fixture is synthetic; the recorded-input route remains the production reachability check.")
	return true


func _install_synthetic_slot11_boundary(scheduler) -> bool:
	var context = SCHEDULER.TaskContext.new()
	context.slot_base = 0x11
	context.ready_delay = 0
	context.phase = 2 # RUNNING
	context.pending_resume = 0 # NONE
	context.program_counter = 0x804A
	context.stack_pointer = 0xCA
	context.accumulator = 0x42
	context.x_register = 0x42
	context.y_register = 0xE7
	context.status_register = 0x20
	context.status_known_mask = 0xC3
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = {"bank_low": 0x18, "bank_high": 0x19}
	context.source_label = "synthetic verifier fixture at slot-$11 `$804A`"
	scheduler._contexts[0x11] = context
	scheduler._active_task_slot = 0x11
	scheduler._ram[0x0000] = 0x11
	scheduler._ram[0x0011] = 0x00
	scheduler._ram[0x0012] = 0xC6
	scheduler._ram[0x0013] = 0x18
	scheduler._ram[0x0014] = 0x19
	scheduler._ram[0x0026] = 0x00
	scheduler._ram[0x005F] = 0x42
	scheduler._ram[0x0060] = 0x9F
	scheduler._ram[0x05E3] = 0x01
	scheduler._ram[0x05E4] = 0x00
	scheduler._ram[0x05E5] = 0x00
	scheduler._ram[0x05E9] = 0x00
	for offset in 0x100:
		scheduler._stack_page[offset] = 0x00
	scheduler._stack_page[0xC7] = 0xE7
	scheduler._stack_page[0xC8] = 0x42
	scheduler._stack_page[0xC9] = 0x49
	scheduler._stack_page[0xCA] = 0x80
	for offset in 0x100:
		scheduler._ram[0x0100 + offset] = scheduler._stack_page[offset]
	return scheduler.get_task_boundary_snapshot(0x11).size() > 0


func _fail(message: String) -> bool:
	push_error(message)
	return false
