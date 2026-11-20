extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: scenario-$2E actor-$6D type-$05 resumes the ROM `$8269` queue for counts 6→1 and returns to the source pre-animation `$804D` state.")
	quit(0)


func _verify() -> bool:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$11 resume source package failed validation: " + executor.error_message)
	var event_result: Dictionary = executor.execute_from_slot11_scenario2e_actor6d_type5_event_boundary(
		_scenario2e_type5_event_boundary())
	if not bool(event_result.get("ok", false)) \
			or String(event_result.get("status", "")) != "slot11_actor_event_payload_at_cb0f":
		return _fail("The actor-$6D type-$05 source event did not reach `$8269`: " + str(event_result.get("reason", event_result.get("error", "unknown error"))))
	var boundary := _queue_boundary_from_result(event_result)
	for remaining_before in [6, 5, 4, 3, 2, 1]:
		var ram: PackedByteArray = boundary["ram_image"]
		var stack: PackedByteArray = boundary["stack_page"]
		var expected_destination: int = (0x222C + ((6 - remaining_before) * 0x40)) & 0xFFFF
		var expected_stack := PackedByteArray([
			0x68, 0x82, (expected_destination >> 8) & 0xFF,
			expected_destination & 0xFF, 0x0A, 0x4C, 0x80])
		if int(ram[0x05E8]) != remaining_before \
				or stack.slice(0xC4, 0xCB) != expected_stack:
			return _fail("Queue input count %d has the wrong live count/destination stack: E8=%02X stack=%s expected=%s" % [
				remaining_before, int(ram[0x05E8]), stack.slice(0xC4, 0xCB).hex_encode(), expected_stack.hex_encode()])
		var result: Dictionary = executor.execute_from_slot11_actor_event_wait_boundary(boundary)
		if not bool(result.get("ok", false)):
			return _fail("Actor-$6D type-$05 queue resume at remaining count %d was rejected: %s" % [
				remaining_before, str(result.get("reason", result.get("error", "unknown error")))])
		var out_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
		var out_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
		if remaining_before > 1:
			var next_destination: int = (0x222C + ((7 - remaining_before) * 0x40)) & 0xFFFF
			var expected_output_stack := PackedByteArray([
				0x68, 0x82, (next_destination >> 8) & 0xFF,
				next_destination & 0xFF, 0x0A, 0x4C, 0x80])
			if String(result.get("status", "")) != "slot11_actor_event_queue_at_cb0f" \
					or int(result.get("yield_callsite_pc", -1)) != 0x8266 \
					or int(result.get("resume_pc_after_rts", -1)) != 0x8269 \
					or out_ram.size() != 0x800 \
					or int(out_ram[0x05E8]) != remaining_before - 1 \
					or int(out_ram[0x0515]) != 0x80 \
					or int(out_ram[0x04A5]) != 0x14 \
					or int(out_ram[0x04A6]) != (expected_destination & 0xFF) \
					or int(out_ram[0x04A7]) != ((expected_destination >> 8) & 0xFF) \
					or out_stack.slice(0xC4, 0xCB) != expected_output_stack:
				return _fail("Queue chunk %d did not emit its ROM packet and count decrement: %s" % [remaining_before, str({
					"status": result.get("status", ""), "count": out_ram[0x05E8] if out_ram.size() == 0x800 else -1,
					"flag": out_ram[0x0515] if out_ram.size() == 0x800 else -1,
					"packet": out_ram.slice(0x04A5, 0x04A8).hex_encode() if out_ram.size() == 0x800 else "invalid",
					"stack": out_stack.slice(0xC4, 0xCB).hex_encode()})])
			boundary = _queue_boundary_from_result(result)
		else:
			var exit_registers: Dictionary = result.get("exit_registers", {})
			if String(result.get("status", "")) != "slot11_actor_event_queue_returned_to_804d" \
					or int(result.get("exit_pc", -1)) != 0x804D \
					or int(exit_registers.get("x", -1)) != 0x0A \
					or int(exit_registers.get("y", -1)) != 0x56 \
				or out_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
				or out_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x02, 0x80, 0x01]) \
				or out_ram.slice(0x0063, 0x0065) != PackedByteArray([0xBA, 0xA2]):
				return _fail("Final queue count 1 did not produce the ROM pre-animation `$804D` state: " + str({
					"status": result.get("status", ""), "exit": exit_registers,
					"e4_e8": out_ram.slice(0x05E4, 0x05E9).hex_encode(),
					"e3_ea": out_ram.slice(0x05E3, 0x05EB).hex_encode(),
					"f3_f5": out_ram.slice(0x05F3, 0x05F6).hex_encode(),
					"animation": out_ram.slice(0x0063, 0x0065).hex_encode()}))
	return true


func _queue_boundary_from_result(result: Dictionary) -> Dictionary:
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = result.get("stack_page", PackedByteArray()).duplicate()
	var callsite: Dictionary = result.get("yield_callsite_registers", {}).duplicate(true)
	# The scheduler resumes `$8269` after NMI consumes the pending packet; keep
	# the source-produced RAM/stack and clear only that externally serviced flag.
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
		"bank_low": 0x18, "bank_high": 0x19,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
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
