extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		_fail("Slot-$11 ROM source package failed validation: " + executor.error_message)
		return
	var tail: Dictionary = executor.execute_from_slot11_final_packet_return_boundary(
		_supported_final_packet_return_boundary())
	if not bool(tail.get("ok", false)):
		_fail("The ROM final-packet return fixture failed: " + str(tail.get("error", "unknown")))
		return
	var gate: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(
		_supported_f5_animation_gate_boundary(tail))
	if not bool(gate.get("ok", false)):
		_fail("The ROM `$A217` animation gate fixture failed: " + str(gate.get("error", "unknown")))
		return
	var a21a := _supported_a21a_animation_boundary(gate)
	var cases := [
		{"pointer": 0xA2E8, "index": 0x05, "table": 0xA434, "low": 0xC3,
			"packet": 0xA4C3, "next": 0xA2EA,
			"packets": [
				{"length": 4, "destination": 0x22C8, "payload": PackedByteArray([0x00, 0xB4, 0xE4, 0xE5])},
				{"length": 4, "destination": 0x22E8, "payload": PackedByteArray([0x00, 0xB6, 0xE6, 0xE7])},
				{"length": 4, "destination": 0x2308, "payload": PackedByteArray([0x00, 0xBC, 0xBD, 0xE8])},
				{"length": 4, "destination": 0x2328, "payload": PackedByteArray([0x00, 0xBE, 0xBF, 0xEA])},
				{"length": 1, "destination": 0x23EA, "payload": PackedByteArray([0x50])},
				{"length": 1, "destination": 0x23F2, "payload": PackedByteArray([0x05])},
			]},
		{"pointer": 0xA2EA, "index": 0x06, "table": 0xA436, "low": 0xE8,
			"packet": 0xA4E8, "next": 0xA2EC,
			"packets": [
				{"length": 1, "destination": 0x22EA, "payload": PackedByteArray([0xD9])},
			]},
		{"pointer": 0xA2EC, "index": 0x07, "table": 0xA438, "low": 0xED,
			"packet": 0xA4ED, "next": 0xA2EE,
			"packets": [
				{"length": 1, "destination": 0x22EA, "payload": PackedByteArray([0xF2])},
			]},
	]
	for case_variant: Variant in cases:
		var case: Dictionary = case_variant
		var result: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(
			_index2_boundary(a21a, int(case["pointer"])))
		var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
		if not bool(result.get("ok", false)) \
				or String(result.get("status", "")) != "slot11_f5_animation_queue_at_8047" \
				or int(result.get("animation_stream_pointer", -1)) != int(case["pointer"]) \
				or int(result.get("animation_command", -1)) != 0x04 \
				or int(result.get("animation_packet_index", -1)) != int(case["index"]) \
				or int(result.get("packet_stream_pointer", -1)) != int(case["packet"]) \
				or result.get("secondary_ppu_packets", []) != case["packets"] \
				or ram.size() != 0x800 \
				or int(ram[0x0063]) != (int(case["next"]) & 0xFF) \
				or int(ram[0x0064]) != ((int(case["next"]) >> 8) & 0xFF) \
				or not _has_source_read(result, int(case["table"]), int(case["low"]),
					"animation_event_pointer_low") \
				or not _has_source_read(result, int(case["table"]) + 1, 0xA4,
					"animation_event_pointer_high") \
				or bool(result.get("trace_state_used", true)):
			_fail("Index-$02 event %02X did not execute its exact ROM table and packet row: %s" % [
				int(case["index"]), str(result.get("error", result.get("reason", result)))])
			return
	var terminal: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(
		_index2_boundary(a21a, 0xA2FA))
	var terminal_ram: PackedByteArray = terminal.get("ram_image", PackedByteArray())
	if not bool(terminal.get("ok", false)) \
			or int(terminal.get("animation_stream_pointer", -1)) != 0xA2E8 \
			or int(terminal.get("animation_packet_index", -1)) != 0x05 \
			or int(terminal.get("packet_stream_pointer", -1)) != 0xA4C3 \
			or terminal_ram.slice(0x0063, 0x0065) != PackedByteArray([0xEA, 0xA2]) \
			or not _has_source_read(terminal, 0xA2FA, 0xFF, "animation_command") \
			or not _has_source_read(terminal, 0xA2FB, 0xE8, "terminal_animation_pointer_low") \
			or not _has_source_read(terminal, 0xA2FC, 0xA2, "terminal_animation_pointer_high"):
		_fail("The index-$02 ROM terminal pointer did not loop `$A2FA->$A2E8`: %s" % str(
			terminal.get("error", terminal.get("reason", terminal))))
		return
	print("PASS: ROM index-$02 events `$05-$07` decode packet rows `$A4C3/$A4E8/$A4ED`; the `$A2FA` terminator loops to `$A2E8`.")
	quit(0)


func _supported_final_packet_return_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC3] = 0xD0
	stack[0xC4] = 0xCC
	stack[0xC5] = 0xFF
	stack[0xC6] = 0x81
	stack[0xC7] = 0x7C
	stack[0xC8] = 0x80
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	ram[0x005F] = 0x52
	ram[0x0060] = 0x9F
	ram[0x05E3] = 0x01
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x01
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0xCCD1, "sp": 0xC4, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC0, 0x18, 0x19]),
		"a": 0x01, "x": 0x21, "y": 0x00, "p": 0x30, "p_known_mask": 0xC3,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
		"ram_image": ram, "stack_page": stack,
	}


func _supported_f5_animation_gate_boundary(tail: Dictionary) -> Dictionary:
	var registers: Dictionary = tail.get("exit_registers", {})
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804D, "sp": int(registers.get("sp", -1)), "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC0, 0x18, 0x19]),
		"a": int(registers.get("a", -1)), "x": int(registers.get("x", -1)),
		"y": int(registers.get("y", -1)), "p": int(registers.get("p", -1)),
		"p_known_mask": int(registers.get("p_known_mask", -1)),
		"mapper": {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
			"bank_registers": {6: 0x18, 7: 0x19}},
		"ram_image": tail.get("ram_image", PackedByteArray()),
		"stack_page": tail.get("stack_page", PackedByteArray()),
	}


func _supported_a21a_animation_boundary(gate: Dictionary) -> Dictionary:
	var ram: PackedByteArray = gate.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = gate.get("stack_page", PackedByteArray()).duplicate()
	var registers: Dictionary = gate.get("cb0f_entry_registers", {})
	stack[0xC4] = int(registers.get("x", -1))
	stack[0xC3] = int(registers.get("y", -1))
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	ram[0x0011] = 0x00
	ram[0x0012] = 0xC2
	ram[0x0013] = 0x1A
	ram[0x0014] = 0x1B
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0xA21A, "sp": 0xC6, "active_task_slot": 0x11,
		"bank_low": 0x1A, "bank_high": 0x1B,
		"record": PackedByteArray([0x00, 0xC2, 0x1A, 0x1B]),
		"a": 0x1A, "x": int(registers.get("x", -1)),
		"y": int(registers.get("y", -1)), "p": int(registers.get("p", -1)),
		"p_known_mask": int(registers.get("p_known_mask", -1)),
		"mapper": gate.get("mapper", {}).duplicate(true),
		"ram_image": ram, "stack_page": stack,
	}


func _index2_boundary(base: Dictionary, pointer: int) -> Dictionary:
	var boundary := base.duplicate(true)
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	ram[0x05F3] = 0x02
	ram[0x05F4] = 0x01
	ram[0x05F5] = 0x00
	ram[0x0515] = 0x00
	ram[0x05E3] = 0x01
	ram[0x0063] = pointer & 0xFF
	ram[0x0064] = (pointer >> 8) & 0xFF
	boundary["ram_image"] = ram
	return boundary


func _has_source_read(result: Dictionary, address: int, value: int, kind: String) -> bool:
	for read_variant: Variant in result.get("source_reads", []):
		if read_variant is Dictionary \
				and int(read_variant.get("address", -1)) == address \
				and int(read_variant.get("value", -1)) == value \
				and String(read_variant.get("kind", "")) == kind:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
