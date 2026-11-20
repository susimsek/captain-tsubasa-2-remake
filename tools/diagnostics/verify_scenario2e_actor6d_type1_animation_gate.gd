extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: scenario-$2E actor-$6D type-$01 gate consumes the source-produced pre-gate state and yields `$A217->$C515` with `$A2E8` selected.")
	quit(0)


func _verify() -> bool:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$11 resume source package failed validation: " + executor.error_message)
	var event_result: Dictionary = executor.execute_from_slot11_scenario2e_actor6d_type5_event_boundary(
		_scenario2e_type5_event_boundary())
	if not bool(event_result.get("ok", false)) \
			or String(event_result.get("status", "")) != "slot11_actor_event_payload_at_cb0f":
		return _fail("The actor-$6D type-$05 event did not reach its ROM payload wait: " + str(event_result.get("reason", event_result.get("error", "unknown error"))))

	var queue_boundary := _queue_boundary_from_result(event_result)
	var final_queue_result: Dictionary = {}
	for remaining_before in [6, 5, 4, 3, 2, 1]:
		var queue_ram: PackedByteArray = queue_boundary["ram_image"]
		var queue_stack: PackedByteArray = queue_boundary["stack_page"]
		var destination: int = 0x222C + ((6 - remaining_before) * 0x40)
		var expected_stack := PackedByteArray([
			0x68, 0x82, (destination >> 8) & 0xFF,
			destination & 0xFF, 0x0A, 0x4C, 0x80])
		if int(queue_ram[0x05E8]) != remaining_before \
				or queue_stack.slice(0xC4, 0xCB) != expected_stack:
			return _fail("Type-$05 queue input %d is not the ROM-produced count/destination boundary." % remaining_before)
		var queue_result: Dictionary = executor.execute_from_slot11_actor_event_wait_boundary(queue_boundary)
		if not bool(queue_result.get("ok", false)):
			return _fail("Type-$05 queue resume %d failed: %s" % [remaining_before, str(queue_result.get("reason", queue_result.get("error", "unknown error")))])
		if remaining_before > 1:
			queue_boundary = _queue_boundary_from_result(queue_result)
		else:
			final_queue_result = queue_result

	var pre_gate_ram: PackedByteArray = final_queue_result.get("ram_image", PackedByteArray())
	var pre_gate_stack: PackedByteArray = final_queue_result.get("stack_page", PackedByteArray())
	var pre_gate_registers: Dictionary = final_queue_result.get("exit_registers", {})
	if String(final_queue_result.get("status", "")) != "slot11_actor_event_queue_returned_to_804d" \
			or int(final_queue_result.get("exit_pc", -1)) != 0x804D \
			or pre_gate_ram.slice(0x005F, 0x0061) != PackedByteArray([0xFE, 0x9B]) \
			or pre_gate_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
			or pre_gate_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x02, 0x80, 0x01]) \
			or pre_gate_ram.slice(0x0063, 0x0065) != PackedByteArray([0xBA, 0xA2]) \
			or int(pre_gate_registers.get("a", -1)) != 0x02 \
			or int(pre_gate_registers.get("x", -1)) != 0x0A \
			or int(pre_gate_registers.get("y", -1)) != 0x56:
		return _fail("The source-produced `$804D` input does not match the retained frame-9494 actor-$6D pre-gate state.")

	var source_mapper: Dictionary = final_queue_result.get("mapper", {})
	var gate_boundary := {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804D, "sp": int(pre_gate_registers.get("sp", -1)),
		"active_task_slot": 0x11,
		"bank_low": int(source_mapper.get("bank_low", -1)),
		"bank_high": int(source_mapper.get("bank_high", -1)),
		"record": PackedByteArray([0x00, 0xC1, 0x18, 0x19]),
		"a": int(pre_gate_registers.get("a", -1)),
		"x": int(pre_gate_registers.get("x", -1)),
		"y": int(pre_gate_registers.get("y", -1)),
		"p": int(pre_gate_registers.get("p", -1)),
		"p_known_mask": int(pre_gate_registers.get("p_known_mask", -1)),
		"mapper": source_mapper,
		"trace_state_used": false,
		"ram_image": pre_gate_ram,
		"stack_page": pre_gate_stack,
	}
	var gate_result: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(gate_boundary)
	if not bool(gate_result.get("ok", false)):
		return _fail("The actor-$6D type-$01 animation gate rejected the source-produced pre-gate boundary: " + str(gate_result.get("reason", gate_result.get("error", "unknown error"))))
	var gate_ram: PackedByteArray = gate_result.get("ram_image", PackedByteArray())
	var gate_callsite: Dictionary = gate_result.get("yield_callsite_registers", {})
	var gate_stack: PackedByteArray = gate_result.get("stack_page", PackedByteArray())
	if String(gate_result.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(gate_result.get("entry_pc", -1)) != 0x804D \
			or int(gate_result.get("exit_pc", -1)) != 0xCB0F \
			or int(gate_result.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(gate_result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(gate_result.get("resume_pc_after_rts", -1)) != 0xA21A \
			or int(gate_callsite.get("a", -1)) != 0x01 \
			or int(gate_callsite.get("x", -1)) != 0x04 \
			or int(gate_callsite.get("y", -1)) != 0x56 \
			or gate_ram.slice(0x005F, 0x0061) != PackedByteArray([0xFE, 0x9B]) \
			or gate_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
			or gate_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x02, 0x01, 0x00]) \
			or gate_ram.slice(0x0063, 0x0065) != PackedByteArray([0xE8, 0xA2]) \
			or int(gate_result.get("cb0f_entry_registers", {}).get("sp", -1)) != 0xC4 \
			or gate_stack.slice(0xC4, 0xCB) != PackedByteArray([0x68, 0x19, 0xA2, 0x83, 0xCF, 0x4F, 0x80]):
		return _fail("The `$A217->$C515` yield differs from the retained frame-9494 `$A2E8` state: " + str({
			"status": gate_result.get("status", ""),
			"callsite": gate_callsite,
			"cb0f": gate_result.get("cb0f_entry_registers", {}),
			"ram_e3_ea": gate_ram.slice(0x05E3, 0x05EB).hex_encode(),
			"ram_f3_f5": gate_ram.slice(0x05F3, 0x05F6).hex_encode(),
			"animation": gate_ram.slice(0x0063, 0x0065).hex_encode(),
			"stack_c4_cb": gate_stack.slice(0xC4, 0xCB).hex_encode(),
		}))
	if bool(gate_result.get("trace_state_used", true)):
		return _fail("The source-derived animation gate marked its result as trace-state-backed.")
	var wrong_actor_boundary: Dictionary = gate_boundary.duplicate(true)
	var wrong_actor_ram: PackedByteArray = pre_gate_ram.duplicate()
	wrong_actor_ram[0x05EA] = 0x6C
	wrong_actor_boundary["ram_image"] = wrong_actor_ram
	var wrong_actor_result: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(wrong_actor_boundary)
	if bool(wrong_actor_result.get("ok", false)):
		return _fail("The actor-$6D gate profile accepted a changed actor identity.")
	var wrong_animation_boundary: Dictionary = gate_boundary.duplicate(true)
	var wrong_animation_ram: PackedByteArray = pre_gate_ram.duplicate()
	wrong_animation_ram[0x0063] = 0xA2
	wrong_animation_boundary["ram_image"] = wrong_animation_ram
	var wrong_animation_result: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(wrong_animation_boundary)
	if bool(wrong_animation_result.get("ok", false)):
		return _fail("The actor-$6D gate profile accepted an altered animation pointer.")
	return true


func _queue_boundary_from_result(result: Dictionary) -> Dictionary:
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = result.get("stack_page", PackedByteArray()).duplicate()
	var callsite: Dictionary = result.get("yield_callsite_registers", {}).duplicate(true)
	var mapper: Dictionary = result.get("mapper", {}).duplicate(true)
	# The scheduler clears only this source-consumed pending flag before resuming `$8269`.
	if ram.size() == 0x800:
		ram[0x0515] = 0x00
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x11, "active_task_slot": 0x11,
		"phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x8269, "sp": 0xC5,
		"record": PackedByteArray([0x00, 0xC1, 0x18, 0x19]),
		"a": int(callsite.get("a", -1)), "x": int(callsite.get("x", -1)),
		"y": int(callsite.get("y", -1)), "p": int(callsite.get("p", -1)),
		"p_known_mask": int(callsite.get("p_known_mask", -1)),
		"bank_low": int(mapper.get("bank_low", -1)),
		"bank_high": int(mapper.get("bank_high", -1)),
		"mapper": mapper,
		"trace_state_used": false, "test_fixture": false,
		"ram_image": ram, "stack_page": stack,
	}


func _scenario2e_type5_event_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC7] = 0x00
	stack[0xC8] = 0xFE
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	_write_bytes(ram, 0x005F, PackedByteArray([0xFE, 0x9B]))
	_write_bytes(ram, 0x0516, PackedByteArray([0x01, 0x00, 0x2E, 0x6C, 0xE8, 0x9B, 0x00]))
	_write_bytes(ram, 0x05E3, PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]))
	_write_bytes(ram, 0x05F3, PackedByteArray([0x00, 0x00, 0x01]))
	_write_bytes(ram, 0x0063, PackedByteArray([0xBA, 0xA2]))
	_write_bytes(ram, 0x04A5, PackedByteArray([0x20, 0xE0, 0x23]))
	return {
		"rom_sha256": ROM_SHA256, "slot_base": 0x11,
		"phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804A, "sp": 0xCA, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC6, 0x18, 0x19]),
		"a": 0xFE, "x": 0xFE, "y": 0x00, "p": 0xB0, "p_known_mask": 0xFF,
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
