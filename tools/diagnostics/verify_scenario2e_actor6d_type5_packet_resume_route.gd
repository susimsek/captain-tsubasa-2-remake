extends SceneTree

const RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the actor-$6D `$82F7` resume matches frame 9497 under both FCEUX and scheduler-known CPU flag states.")
	quit(0)


func _verify() -> bool:
	var boundary := _frame9497_resume_boundary()
	if not RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(boundary):
		return _fail("The captured actor-$6D type-$05 `$82F7` boundary was rejected by the production route classifier.")
	var altered_boundary := boundary.duplicate(true)
	var altered_ram: PackedByteArray = boundary["ram_image"].duplicate()
	altered_ram[0x05EA] = 0x6C
	altered_boundary["ram_image"] = altered_ram
	if RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(altered_boundary):
		return _fail("The route classifier accepted actor `$6C` in place of `$6D`.")
	altered_boundary = boundary.duplicate(true)
	altered_ram = boundary["ram_image"].duplicate()
	altered_ram[0x0519] = 0x64
	altered_boundary["ram_image"] = altered_ram
	if RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(altered_boundary):
		return _fail("The route classifier accepted the pre-root-tick descriptor byte at the frame-9497 `$82F7` boundary.")
	var partial_status_boundary := boundary.duplicate(true)
	partial_status_boundary["p"] = 0x20
	partial_status_boundary["p_known_mask"] = 0x83
	if not RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(partial_status_boundary):
		return _fail("The route classifier rejected the scheduler's `$20/$83` status mask for frame 9497.")
	var reduced_mapper_boundary := partial_status_boundary.duplicate(true)
	reduced_mapper_boundary["mapper"] = {"select": 0x07, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	if not RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(reduced_mapper_boundary):
		return _fail("The route classifier rejected the scheduler's saved PRG-bank pair when PPU registers are absent.")
	var scheduler_scan_boundary := reduced_mapper_boundary.duplicate(true)
	var scheduler_scan_ram: PackedByteArray = scheduler_scan_boundary["ram_image"].duplicate()
	scheduler_scan_ram[0x0000] = 0x09
	scheduler_scan_boundary["ram_image"] = scheduler_scan_ram
	if not RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(scheduler_scan_boundary):
		return _fail("The route classifier rejected slot-$11 while `$0000` still names the previous slot-$09 scheduler task.")
	var wrong_slot_boundary := reduced_mapper_boundary.duplicate(true)
	wrong_slot_boundary["slot_base"] = 0x09
	if RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(wrong_slot_boundary):
		return _fail("The route classifier accepted a slot-$09 context as the actor-$6D slot-$11 resume.")
	var conflicting_ppu_mapper_boundary := reduced_mapper_boundary.duplicate(true)
	var conflicting_mapper: Dictionary = conflicting_ppu_mapper_boundary["mapper"].duplicate(true)
	var conflicting_registers: Dictionary = conflicting_mapper["bank_registers"].duplicate(true)
	conflicting_registers[0] = 0x00
	conflicting_mapper["bank_registers"] = conflicting_registers
	conflicting_ppu_mapper_boundary["mapper"] = conflicting_mapper
	if RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(conflicting_ppu_mapper_boundary):
		return _fail("The route classifier accepted a conflicting known MMC3 PPU register.")
	for unknown_flag in [0x80, 0x02, 0x01]:
		var unknown_status_boundary := partial_status_boundary.duplicate(true)
		unknown_status_boundary["p_known_mask"] = 0x83 & ~unknown_flag
		if RUNNER.is_scenario2e_actor6d_type5_packet_resume_boundary(unknown_status_boundary):
			return _fail("The route classifier accepted an unknown ROM-consumed status flag `$%02X`." % unknown_flag)

	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("The slot-$11 resume source package failed validation: " + executor.error_message)
	var dispatch_boundary := boundary.duplicate(true)
	dispatch_boundary["a"] = 0x24
	var result: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(dispatch_boundary)
	if not bool(result.get("ok", false)):
		return _fail("The frame-9497 actor-$6D packet resume failed: " + str(result.get("reason", result.get("error", "unknown error"))))
	var callsite: Dictionary = result.get("yield_callsite_registers", {})
	var callsite_stack: PackedByteArray = result.get("yield_callsite_stack_page", PackedByteArray())
	var cb0f: Dictionary = result.get("cb0f_entry_registers", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var input_ram: PackedByteArray = dispatch_boundary["ram_image"]
	if String(result.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
			or int(result.get("entry_pc", -1)) != 0x82F7 \
			or int(result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(result.get("resume_pc_after_rts", -1)) != 0x804A \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(callsite.get("sp", -1)) != 0xCA \
			or int(callsite.get("a", -1)) != 0x01 \
			or int(callsite.get("x", -1)) != 0x06 \
			or int(callsite.get("y", -1)) != 0x04 \
			or callsite_stack.slice(0xC9, 0xCB) != PackedByteArray([0x4F, 0x80]) \
			or int(cb0f.get("pc", -1)) != 0xCB0F \
			or int(cb0f.get("sp", -1)) != 0xC8 \
			or int(cb0f.get("a", -1)) != 0x01 \
			or int(cb0f.get("x", -1)) != 0x06 \
			or int(cb0f.get("y", -1)) != 0x04 \
			or output_ram.size() != 0x800 or output_stack.size() != 0x100 \
			or output_ram[0x0515] != 0x80 \
			or output_ram.slice(0x04A5, 0x04A8) != PackedByteArray([0x0E, 0xB0, 0x22]) \
			or input_ram[0x0519] != 0x63 or output_ram[0x0519] != input_ram[0x0519] \
			or output_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x01, 0x6D]) \
			or output_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x02, 0x01, 0x03]) \
			or output_ram.slice(0x0063, 0x0065) != PackedByteArray([0xEA, 0xA2]) \
			or output_stack.slice(0xC9, 0xCB) != PackedByteArray([0x49, 0x80]) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("source_timing_modeled", true)):
		return _fail("The ROM-byte packet resume does not match the worker-owned frame-9497 packet or `$8047->$C515` scheduler boundary: " + str({
			"status": result.get("status", ""), "entry_pc": result.get("entry_pc", -1),
			"callsite_pc": result.get("yield_callsite_pc", -1), "resume_pc": result.get("resume_pc_after_rts", -1),
			"exit_pc": result.get("exit_pc", -1), "callsite_registers": callsite, "cb0f_registers": cb0f,
			"stack_C9_CA": callsite_stack.slice(0xC9, 0xCB).hex_encode(),
			"queue": output_ram[0x0515] if output_ram.size() == 0x800 else -1,
			"packet": output_ram.slice(0x04A5, 0x04A8).hex_encode() if output_ram.size() == 0x800 else "invalid",
			"descriptor_0519_preserved": output_ram[0x0519] if output_ram.size() == 0x800 else -1,
			"worker_E3_EA": output_ram.slice(0x05E3, 0x05EB).hex_encode() if output_ram.size() == 0x800 else "invalid",
			"worker_F3_F5": output_ram.slice(0x05F3, 0x05F6).hex_encode() if output_ram.size() == 0x800 else "invalid",
		}))
	var partial_dispatch_boundary := dispatch_boundary.duplicate(true)
	partial_dispatch_boundary["p"] = 0x20
	partial_dispatch_boundary["p_known_mask"] = 0x83
	var partial_status_result: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(
		partial_dispatch_boundary)
	var partial_output_ram: PackedByteArray = partial_status_result.get("ram_image", PackedByteArray())
	var partial_callsite: Dictionary = partial_status_result.get("yield_callsite_registers", {})
	var partial_cb0f: Dictionary = partial_status_result.get("cb0f_entry_registers", {})
	if not bool(partial_status_result.get("ok", false)) \
			or partial_output_ram.size() != 0x800 \
			or partial_output_ram.slice(0x04A5, 0x04C1) != output_ram.slice(0x04A5, 0x04C1) \
			or (int(partial_callsite.get("p_known_mask", -1)) & 0x83) != 0x83 \
			or (int(partial_callsite.get("p", -1)) & 0x83) != 0 \
			or (int(partial_cb0f.get("p_known_mask", -1)) & 0x83) != 0x83 \
			or (int(partial_cb0f.get("p", -1)) & 0x83) != 0:
		return _fail("The ROM packet resume differs under the route's `$20/$83` status abstraction: " + str({
			"reason": partial_status_result.get("reason", ""), "callsite": partial_callsite,
			"cb0f": partial_cb0f,
			"packet_equal": partial_output_ram.size() == 0x800 and \
				partial_output_ram.slice(0x04A5, 0x04C1) == output_ram.slice(0x04A5, 0x04C1)}))
	return true


func _frame9497_resume_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC7] = 0xF6
	stack[0xC8] = 0x82
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	_write_bytes(ram, 0x005F, PackedByteArray([0xFE, 0x9B]))
	# Frame-9497 `$82F7` resumes after the slot-$09 scenario-root tick at seq 7449,
	# which changes `$0519` from `$64` to `$63`; slot-$11 must preserve `$63`.
	_write_bytes(ram, 0x0515, PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x63, 0xE8, 0x9B, 0x00]))
	_write_bytes(ram, 0x05E3, PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]))
	# Focused boundary input from frame 9496 seq 7439 in
	# reference/diagnostics/pass_receiver_waiter_boundaries_20261119_231454_utc/events.csv.
	# This fixture-only text buffer lets the ROM parser reach its $FD terminator;
	# production route state must continue to come from ordinary source execution.
	_write_bytes(ram, 0x05EB, PackedByteArray([0x4E, 0x6F, 0x2E, 0x00, 0x00, 0x00, 0x00, 0xFD]))
	_write_bytes(ram, 0x05F3, PackedByteArray([0x02, 0x01, 0x04]))
	_write_bytes(ram, 0x0063, PackedByteArray([0xEA, 0xA2]))
	_write_bytes(ram, 0x04A5, PackedByteArray([0x04, 0xC8, 0x22, 0x00, 0xB4, 0xE4, 0xE5, 0x04, 0xE8, 0x22, 0x00]))
	return {
		"rom_sha256": ROM_SHA256, "slot_base": 0x11,
		"phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x82F7, "sp": 0xC8, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC4, 0x18, 0x19]),
		"a": 0x01, "x": 0x24, "y": 0x06, "p": 0x30, "p_known_mask": 0xFF,
		"mapper": {"select": 0x07, "bank_low": 0x18, "bank_high": 0x19,
			"bank_registers": {0: 0x3C, 1: 0x4A, 2: 0x20, 3: 0x21, 4: 0x00, 5: 0x00, 6: 0x18, 7: 0x19}},
		"trace_state_used": false, "test_fixture": true,
		"ram_image": ram, "stack_page": stack,
	}


func _write_bytes(target: PackedByteArray, start: int, values: PackedByteArray) -> void:
	for offset in values.size():
		target[start + offset] = values[offset]


func _fail(message: String) -> bool:
	push_error(message)
	return false
