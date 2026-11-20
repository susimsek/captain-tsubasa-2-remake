extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: frame-9496 actor-$6D `$804A` dispatch accepts scheduler-known mapper/status fields, rejects conflicting known fields, and preserves the ROM `$82F2->$82F4->$C515` yield signature.")
	quit(0)


func _verify() -> bool:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$11 resume source package failed validation: " + executor.error_message)
	var result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_frame9496_actor6d_type5_boundary())
	if not bool(result.get("ok", false)):
		return _fail("Frame-9496 actor-$6D `$804A` state was rejected: " + str(result.get("reason", result.get("error", "unknown error"))))
	var callsite: Dictionary = result.get("yield_callsite_registers", {})
	var yield_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var cb0f_registers: Dictionary = result.get("cb0f_entry_registers", {})
	var source_hashes: Dictionary = result.get("source_span_hashes", {})
	var instruction_pcs: Array = result.get("instruction_pcs", [])
	if String(result.get("status", "")) != "slot11_actor_scenario2e_actor6d_type5_packet_wait_at_cb0f" \
			or int(result.get("entry_pc", -1)) != 0x804A \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(result.get("yield_callsite_pc", -1)) != 0x82F4 \
			or int(result.get("resume_pc_after_rts", -1)) != 0x82F7 \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(callsite.get("a", -1)) != 0x01 \
			or int(callsite.get("x", -1)) != 0x24 \
			or int(callsite.get("y", -1)) != 0x06 \
			or int(callsite.get("sp", -1)) != 0xC8 \
			or int(cb0f_registers.get("sp", -1)) != 0xC6 \
			or int(cb0f_registers.get("a", -1)) != 0x01 \
			or int(cb0f_registers.get("x", -1)) != 0x24 \
			or int(cb0f_registers.get("y", -1)) != 0x06 \
			or yield_stack.slice(0xC7, 0xCB) != PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			or not instruction_pcs.has(0x8062) or not instruction_pcs.has(0x82F2) \
			or not instruction_pcs.has(0x82F4) or not instruction_pcs.has(0xC515) \
			or String(source_hashes.get("bank18_actor_parameter_6d_stream_9be3_9c70.bin", "")) != \
					"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e":
		return _fail("The ROM `$82F2->$82F4->$C515` waiter result differs from the frame-9496/9497 trace: " + str({
			"status": result.get("status", ""), "exit_pc": result.get("exit_pc", -1),
			"callsite_pc": result.get("yield_callsite_pc", -1),
			"resume_pc": result.get("resume_pc_after_rts", -1),
			"registers": callsite, "cb0f_registers": cb0f_registers,
			"stack": yield_stack.slice(0xC7, 0xCB).hex_encode(),
			"instruction_pcs": instruction_pcs,
		}))

	var altered_boundary := _frame9496_actor6d_type5_boundary()
	var altered_ram: PackedByteArray = altered_boundary["ram_image"].duplicate()
	altered_ram[0x05F5] = 0x05
	altered_boundary["ram_image"] = altered_ram
	var altered: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(altered_boundary)
	if bool(altered.get("ok", false)):
		return _fail("The actor-$6D packet-wait profile accepted a non-trace F5 countdown value.")

	var partial_status_boundary := _frame9496_actor6d_type5_boundary()
	partial_status_boundary["p"] = 0x20
	partial_status_boundary["p_known_mask"] = 0x83
	var partial_status_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		partial_status_boundary)
	if not bool(partial_status_result.get("ok", false)) \
			or String(partial_status_result.get("status", "")) != \
				"slot11_actor_scenario2e_actor6d_type5_packet_wait_at_cb0f":
		return _fail("The route's partial but sufficient `$20/$83` status state was rejected: " + str(partial_status_result.get("reason", "")))
	for required_flag in [0x80, 0x02, 0x01]:
		var unknown_flag_boundary := _frame9496_actor6d_type5_boundary()
		unknown_flag_boundary["p"] = 0x20
		unknown_flag_boundary["p_known_mask"] = 0x83 & ~required_flag
		var unknown_flag_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
			unknown_flag_boundary)
		if bool(unknown_flag_result.get("ok", false)):
			return _fail("The actor-$6D packet-wait profile accepted an unknown consumed status bit `$%02X`." % required_flag)
	var scheduler_mapper_boundary := _frame9496_actor6d_type5_boundary()
	scheduler_mapper_boundary["mapper"] = {"select": 0x07, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	var scheduler_mapper_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		scheduler_mapper_boundary)
	if not bool(scheduler_mapper_result.get("ok", false)):
		return _fail("The scheduler's saved PRG-bank pair was rejected when PPU registers were not represented: " + str(scheduler_mapper_result.get("reason", "")))
	var conflicting_ppu_mapper_boundary := _frame9496_actor6d_type5_boundary()
	var conflicting_mapper: Dictionary = conflicting_ppu_mapper_boundary["mapper"].duplicate(true)
	var conflicting_registers: Dictionary = conflicting_mapper["bank_registers"].duplicate(true)
	conflicting_registers[0] = 0x00
	conflicting_mapper["bank_registers"] = conflicting_registers
	conflicting_ppu_mapper_boundary["mapper"] = conflicting_mapper
	var conflicting_mapper_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		conflicting_ppu_mapper_boundary)
	if bool(conflicting_mapper_result.get("ok", false)):
		return _fail("The actor-$6D packet-wait profile accepted a conflicting known MMC3 PPU register.")
	return true


func _frame9496_actor6d_type5_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC7] = 0x24
	stack[0xC8] = 0x24
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	_write_bytes(ram, 0x005F, PackedByteArray([0xFE, 0x9B]))
	_write_bytes(ram, 0x0515, PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x64, 0xE8, 0x9B, 0x00]))
	_write_bytes(ram, 0x05E3, PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]))
	_write_bytes(ram, 0x05F3, PackedByteArray([0x02, 0x01, 0x04]))
	_write_bytes(ram, 0x0063, PackedByteArray([0xEA, 0xA2]))
	_write_bytes(ram, 0x04A5, PackedByteArray([0x04, 0xC8, 0x22]))
	return {
		"rom_sha256": ROM_SHA256, "slot_base": 0x11,
		"phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804A, "sp": 0xCA, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC6, 0x18, 0x19]),
		"a": 0x24, "x": 0x24, "y": 0x24, "p": 0x30, "p_known_mask": 0xFF,
		"mapper": {"select": 0x07, "bank_low": 0x18, "bank_high": 0x19,
			"bank_registers": {0: 0x3C, 1: 0x4A, 2: 0x20, 3: 0x21, 4: 0x00, 5: 0x00, 6: 0x18, 7: 0x19}},
		"trace_state_used": false, "test_fixture": false,
		"ram_image": ram, "stack_page": stack,
	}


func _write_bytes(target: PackedByteArray, start: int, values: PackedByteArray) -> void:
	for offset in values.size():
		target[start + offset] = values[offset]


func _fail(message: String) -> bool:
	push_error(message)
	return false
