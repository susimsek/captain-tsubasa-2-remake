extends SceneTree

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ACTOR6D_STREAM_FILE := "bank18_actor_parameter_6d_stream_9be3_9c70.bin"
const ACTOR6D_STREAM_SHA256 := "0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: actor-$6D type-$05 `$82F7->$8047->$CB0F` result was hash-checked and adopted with the route's partial CPU and mapper snapshot.")
	print("LIMIT: this focused scheduler fixture proves the bounded adoption contract; the recorded-input route establishes reachability.")
	quit(0)


func _verify() -> bool:
	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources() \
			or not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Scheduler source setup failed: " + scheduler.error_message)
	var boundary := _install_actor6d_packet_resume_boundary(scheduler)
	if boundary.is_empty():
		return _fail("Could not install the explicitly synthetic actor-$6D scheduler boundary.")
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Packet-resume source package failed validation: " + executor.error_message)
	var worker: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(boundary)
	if not bool(worker.get("ok", false)) \
			or String(worker.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
			or int(worker.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(worker.get("resume_pc_after_rts", -1)) != 0x804A:
		return _fail("Executor did not return the observed `$8047->$C515` wait: " \
				+ String(worker.get("reason", worker.get("error", "unknown error"))))
	var hashes: Dictionary = worker.get("source_span_hashes", {})
	if hashes.has(ACTOR6D_STREAM_FILE) and String(hashes[ACTOR6D_STREAM_FILE]) != ACTOR6D_STREAM_SHA256:
		return _fail("Executor reported an unexpected actor-$6D `$9BE3-$9C70` source hash.")
	var worker_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var worker_stack: PackedByteArray = worker.get("stack_page", PackedByteArray())
	var callsite: Dictionary = worker.get("yield_callsite_registers", {})
	if worker_ram.size() != 0x800 or worker_stack.size() != 0x100 \
			or int(callsite.get("sp", -1)) != 0xCA \
			or int(callsite.get("a", -1)) != 0x01 \
			or int(callsite.get("x", -1)) != 0x06 \
			or int(callsite.get("y", -1)) != 0x04 \
			or worker_ram.slice(0x04A5, 0x04A8) != PackedByteArray([0x0E, 0xB0, 0x22]):
		return _fail("Executor output did not match the frame-9497 actor-$6D packet boundary: " + str({
			"status": worker.get("status", ""), "callsite": callsite,
			"cb0f": worker.get("cb0f_entry_registers", {}),
			"callsite_stack": worker.get("yield_callsite_stack_page", PackedByteArray()).slice(0xC7, 0xCB).hex_encode(),
			"output_stack": worker_stack.slice(0xC7, 0xCB).hex_encode() if worker_stack.size() == 0x100 else "invalid",
			"packet": worker_ram.slice(0x04A5, 0x04C1).hex_encode() if worker_ram.size() == 0x800 else "invalid",
			"profile": worker_ram.slice(0x0515, 0x051D).hex_encode() if worker_ram.size() == 0x800 else "invalid",
			"E3_EA": worker_ram.slice(0x05E3, 0x05EB).hex_encode() if worker_ram.size() == 0x800 else "invalid",
			"F3_F5": worker_ram.slice(0x05F3, 0x05F6).hex_encode() if worker_ram.size() == 0x800 else "invalid",
			"hash_keys": hashes.keys()}))

	var before_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
	var before_ram: PackedByteArray = scheduler._ram.duplicate()
	var before_stack: PackedByteArray = scheduler._stack_page.duplicate()
	var corrupted: Dictionary = worker.duplicate(true)
	var corrupted_hashes: Dictionary = hashes.duplicate(true)
	var first_hash: String = String(corrupted_hashes.keys()[0])
	corrupted_hashes[first_hash] = "0".repeat(64)
	corrupted["source_span_hashes"] = corrupted_hashes
	var rejected: Dictionary = scheduler.apply_slot11_actor_packet_resume_result(corrupted)
	if not rejected.is_empty() or scheduler.get_task_boundary_snapshot(0x11) != before_boundary \
			or scheduler._ram != before_ram or scheduler._stack_page != before_stack:
		return _fail("Scheduler accepted a changed packet-resume source hash or mutated live state on rejection.")

	var saved: Dictionary = scheduler.apply_slot11_actor_packet_resume_result(worker)
	if not bool(saved.get("ok", false)):
		return _fail("Scheduler rejected the frame-9497 actor-$6D result: " + scheduler.error_message)
	var saved_boundary: Dictionary = saved.get("saved_boundary", {})
	var saved_record: PackedByteArray = saved.get("task_record", PackedByteArray())
	if String(saved.get("status", "")) != "slot11_actor_packet_resume_saved_at_cb0f" \
			or int(saved.get("callsite_pc", -1)) != 0x8047 \
			or int(saved.get("resume_pc", -1)) != 0x804A \
			or int(saved_boundary.get("pc", -1)) != 0xCB0F \
			or int(saved_boundary.get("sp", -1)) != 0xC6 \
			or int(saved_boundary.get("ready_delay", -1)) != 1 \
			or saved_record != PackedByteArray([0x01, 0xC6, 0x18, 0x19]) \
			or scheduler._ram.slice(0x04A5, 0x04A8) != PackedByteArray([0x0E, 0xB0, 0x22]) \
			or scheduler._ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x01, 0x6D]) \
			or scheduler._ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x02, 0x01, 0x03]) \
			or bool(saved.get("trace_state_used", true)):
		return _fail("The adopted frame-9497 packet boundary has unexpected scheduler state: " + str({
			"status": saved.get("status", ""), "callsite": saved.get("callsite_pc", -1),
			"resume": saved.get("resume_pc", -1),
			"boundary": [saved_boundary.get("pc", -1), saved_boundary.get("sp", -1), saved_boundary.get("ready_delay", -1)],
			"record": saved_record.hex_encode(),
			"packet": scheduler._ram.slice(0x04A5, 0x04A8).hex_encode(),
			"E3_EA": scheduler._ram.slice(0x05E3, 0x05EB).hex_encode(),
			"F3_F5": scheduler._ram.slice(0x05F3, 0x05F6).hex_encode()}))
	return true


func _install_actor6d_packet_resume_boundary(scheduler) -> Dictionary:
	var ram: PackedByteArray = scheduler._ram.duplicate()
	var stack: PackedByteArray = scheduler._stack_page.duplicate()
	for offset in ram.size():
		ram[offset] = 0
	for offset in stack.size():
		stack[offset] = 0
	stack[0xC7] = 0xF6
	stack[0xC8] = 0x82
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	ram[0x0011] = 0x00
	ram[0x0012] = 0xC4
	ram[0x0013] = 0x18
	ram[0x0014] = 0x19
	_write_bytes(ram, 0x005F, PackedByteArray([0xFE, 0x9B]))
	_write_bytes(ram, 0x0515, PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x63, 0xE8, 0x9B, 0x00]))
	_write_bytes(ram, 0x05E3, PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]))
	_write_bytes(ram, 0x05EB, PackedByteArray([0x4E, 0x6F, 0x2E, 0x00, 0x00, 0x00, 0x00, 0xFD]))
	_write_bytes(ram, 0x05F3, PackedByteArray([0x02, 0x01, 0x04]))
	_write_bytes(ram, 0x0063, PackedByteArray([0xEA, 0xA2]))
	_write_bytes(ram, 0x04A5, PackedByteArray([0x04, 0xC8, 0x22, 0x00, 0xB4, 0xE4, 0xE5, 0x04, 0xE8, 0x22, 0x00]))
	scheduler._ram = ram
	scheduler._stack_page = stack
	var context = SCHEDULER.TaskContext.new()
	context.slot_base = 0x11
	context.ready_delay = 0
	context.phase = 2
	context.pending_resume = 0
	context.program_counter = 0x82F7
	context.stack_pointer = 0xC8
	context.accumulator = 0x24
	context.x_register = 0x24
	context.y_register = 0x06
	context.status_register = 0x20
	context.status_known_mask = 0x83
	context.bank_low = 0x18
	context.bank_high = 0x19
	context.mapper_state = {"select": 0x07, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	context.source_label = "synthetic actor-$6D type-$05 `$82F7` scheduler boundary"
	scheduler._contexts[0x11] = context
	scheduler._active_task_slot = 0x11
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("pc", -1)) != 0x82F7:
		return {}
	return boundary


func _write_bytes(target: PackedByteArray, start: int, values: PackedByteArray) -> void:
	for offset in values.size():
		target[start + offset] = values[offset]


func _fail(message: String) -> bool:
	push_error(message)
	return false
