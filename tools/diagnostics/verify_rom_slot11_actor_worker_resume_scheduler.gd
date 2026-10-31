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
