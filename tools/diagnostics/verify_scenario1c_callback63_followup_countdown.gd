extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/manifest.json"


func _initialize() -> void:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		_fail("ROM source setup failed: " + executor.error_message)
		return
	var boundary := _make_frame_9247_fixture()
	if not executor.is_scenario1c_parameter58_followup_post_packet_delay_boundary(boundary):
		_fail("The exact callback-$63/map-$51 frame-9247 countdown boundary was rejected.")
		return
	print("PASS: frame-9247 callback-$63/map-$51 boundary admitted at `$804A`.")

	var wrong_map := boundary.duplicate(true)
	wrong_map["ram_image"][0x05CC] = 0x12
	if executor.is_scenario1c_parameter58_followup_post_packet_delay_boundary(wrong_map):
		_fail("The callback-$63 countdown gate admitted a mutated map-$12 fixture.")
		return
	print("PASS: map mutation rejected by the callback-$63 countdown gate.")

	var result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
	if not bool(result.get("ok", false)):
		_fail("ROM `$804A` countdown execution failed: " + String(result.get("error", "unsupported source path")))
		return
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var writes: Array = result.get("ram_writes", [])
	var counter_write_found := false
	for write_variant: Variant in writes:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) == 0x05F5 \
					and int(write.get("value", -1)) == 0x01 \
					and int(write.get("pc", -1)) == 0xA211:
				counter_write_found = true
	if String(result.get("status", "")) != "slot11_actor_scenario1c_parameter58_followup_post_packet_delay_at_8047" \
			or int(result.get("entry_pc", -1)) != 0x804A \
			or int(result.get("exit_pc", -1)) != 0x8047 \
			or output_ram.size() != 0x800 \
			or output_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			or output_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x01]) \
			or int(output_ram[0x0516]) != 0x01 or int(output_ram[0x0519]) != 0x28 \
			or output_ram.slice(0x005D, 0x0061) != PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			or output_ram.slice(0x05C7, 0x05D3) != PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			or int(output_ram[0x0515]) != 0x00 or not counter_write_found \
			or not (result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (result.get("apu_register_writes", []) as Array).is_empty() \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("source_timing_modeled", true)):
		_fail("The ROM countdown result differs from the expected source transition: %s" % JSON.stringify({
			"status": result.get("status", ""),
			"E3_EA": output_ram.slice(0x05E3, 0x05EB).hex_encode() if output_ram.size() == 0x800 else "invalid",
			"F3_F5": output_ram.slice(0x05F3, 0x05F6).hex_encode() if output_ram.size() == 0x800 else "invalid",
			"counter_write_found": counter_write_found,
		}))
		return
	print("PASS: ROM countdown executes `$05E9 01->00`, `$05F5 02->01`, preserving callback/map/stream and queue state.")
	var terminal_boundary := _make_frame_9248_terminal_fixture()
	if not executor.is_scenario1c_parameter58_followup_text_terminal_boundary(terminal_boundary):
		_fail("The exact frame-9248 callback-$63/map-$51 `$F0` terminal boundary was rejected.")
		return
	var terminal_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(terminal_boundary)
	if not bool(terminal_result.get("ok", false)):
		_fail("ROM `$9A6F` terminal command execution failed: " + String(terminal_result.get("error", "unsupported source path")))
		return
	var terminal_ram: PackedByteArray = terminal_result.get("ram_image", PackedByteArray())
	var terminal_reads: Array = terminal_result.get("source_reads", [])
	var terminal_f0_read := false
	var active_clear_read := false
	var final_gate_read := false
	for read_variant: Variant in terminal_reads:
		if read_variant is Dictionary:
			var source_read: Dictionary = read_variant
			terminal_f0_read = terminal_f0_read or (int(source_read.get("address", -1)) == 0x9A6F \
				and int(source_read.get("value", -1)) == 0xF0)
			active_clear_read = active_clear_read or (int(source_read.get("address", -1)) == 0x05E3 \
				and int(source_read.get("value", -1)) == 0x01)
			final_gate_read = final_gate_read or (int(source_read.get("address", -1)) == 0x05F5 \
				and int(source_read.get("value", -1)) == 0x01)
	if String(terminal_result.get("status", "")) != "slot11_actor_scenario1c_parameter58_followup_text_terminal_at_8047" \
			or int(terminal_result.get("entry_pc", -1)) != 0x804A \
			or int(terminal_result.get("exit_pc", -1)) != 0x8047 \
			or terminal_ram.size() != 0x800 \
			or terminal_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			or terminal_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x00]) \
			or terminal_ram.slice(0x0516, 0x051D) != terminal_boundary["ram_image"].slice(0x0516, 0x051D) \
			or terminal_ram.slice(0x05C7, 0x05D3) != terminal_boundary["ram_image"].slice(0x05C7, 0x05D3) \
			or terminal_ram.slice(0x04A5, 0x04C0) != terminal_boundary["ram_image"].slice(0x04A5, 0x04C0) \
			or not terminal_f0_read or not active_clear_read or not final_gate_read \
			or not (terminal_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (terminal_result.get("apu_register_writes", []) as Array).is_empty() \
			or bool(terminal_result.get("trace_state_used", true)) \
			or bool(terminal_result.get("source_timing_modeled", true)):
		_fail("The ROM terminal result differs from the trace-bracketed frame-9248 transition: %s" % JSON.stringify({
			"status": terminal_result.get("status", ""),
			"actor": terminal_ram.slice(0x05E3, 0x05EB).hex_encode() if terminal_ram.size() == 0x800 else "invalid",
			"gate": terminal_ram.slice(0x05F3, 0x05F6).hex_encode() if terminal_ram.size() == 0x800 else "invalid",
			"f0_read": terminal_f0_read,
			"active_clear_read": active_clear_read,
			"final_gate_read": final_gate_read,
		}))
		return
	print("PASS: frame-9248 `$9A6F=$F0` clears `$05E3` and the ROM gate decrements `$05F5 01->00`.")
	print("LIMIT: synthetic boundaries plus ROM-source execution only; live route parity, rendered pixels/audio, and exact write cycles remain separate evidence.")
	quit(0)


func _make_frame_9247_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x11
	var stack := PackedByteArray()
	stack.resize(0x100)
	_put_bytes(ram, 0x005D, [0xBD, 0xB4, 0x62, 0x9A])
	_put_bytes(ram, 0x0063, [0xB0, 0xA2])
	_put_bytes(ram, 0x0516, [0x01, 0x40, 0x1C, 0x28, 0xE8, 0x9B, 0x00])
	_put_bytes(ram, 0x0522, [0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40])
	_put_bytes(ram, 0x05C7, [0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])
	_put_bytes(ram, 0x05E3, [0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x01, 0x58])
	_put_bytes(ram, 0x05F3, [0x00, 0x01, 0x02])
	_put_bytes(ram, 0x01C7, [0x3A, 0x06, 0x49, 0x80])
	_put_bytes(stack, 0xC7, [0x3A, 0x06, 0x49, 0x80])
	ram[0x003A] = 0x06
	ram[0x0515] = 0x00
	ram[0x0022] = 0x00
	ram[0x0629] = 0x00
	ram[0x052B] = 0x00
	ram[0x05FB] = 0x00
	ram[0x0635] = 0x84
	ram[0x0637] = 0x54
	return {
		"source_frame": 9247,
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"slot_base": 0x11,
		"phase": 2,
		"ready_delay": 0,
		"pending_resume": 0,
		"active_task_slot": 0x11,
		"pc": 0x804A,
		"sp": 0xCA,
		"a": 0x06,
		"x": 0x06,
		"y": 0x3A,
		"p": 0x20,
		"p_known_mask": 0x83,
		"record": PackedByteArray([0x00, 0xC6, 0x18, 0x19]),
		"bank_low": 0x18,
		"bank_high": 0x19,
		"mapper": {"select": 7, "bank_low": 0x18, "bank_high": 0x19, "bank_registers": {6: 0x18, 7: 0x19}},
		"ram_image": ram,
		"stack_page": stack,
	}


func _make_frame_9248_terminal_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x11
	var stack := PackedByteArray()
	stack.resize(0x100)
	_put_bytes(ram, 0x005D, [0xBD, 0xB4, 0x62, 0x9A])
	_put_bytes(ram, 0x005F, [0x62, 0x9A])
	_put_bytes(ram, 0x0063, [0xB0, 0xA2])
	_put_bytes(ram, 0x0516, [0x29, 0x40, 0x1C, 0x27, 0xE8, 0x9B, 0x00])
	_put_bytes(ram, 0x0522, [0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x00])
	_put_bytes(ram, 0x05C7, [0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])
	_put_bytes(ram, 0x05E3, [0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x00, 0x58])
	_put_bytes(ram, 0x05F3, [0x00, 0x01, 0x01])
	_put_bytes(ram, 0x01C7, [0x3A, 0x06, 0x49, 0x80])
	_put_bytes(stack, 0xC7, [0x3A, 0x06, 0x49, 0x80])
	ram[0x003A] = 0x01
	ram[0x0515] = 0x00
	ram[0x0022] = 0x00
	ram[0x0629] = 0x00
	ram[0x052B] = 0x00
	ram[0x05FB] = 0x00
	ram[0x0635] = 0x84
	ram[0x0637] = 0x54
	return {
		"source_frame": 9248,
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"slot_base": 0x11,
		"phase": 2,
		"ready_delay": 0,
		"pending_resume": 0,
		"active_task_slot": 0x11,
		"pc": 0x804A,
		"sp": 0xCA,
		"a": 0x06,
		"x": 0x06,
		"y": 0x3A,
		"p": 0x20,
		"p_known_mask": 0x83,
		"record": PackedByteArray([0x00, 0xC6, 0x18, 0x19]),
		"bank_low": 0x18,
		"bank_high": 0x19,
		"mapper": {"select": 7, "bank_low": 0x18, "bank_high": 0x19, "bank_registers": {6: 0x18, 7: 0x19}},
		"ram_image": ram,
		"stack_page": stack,
	}


func _put_bytes(target: PackedByteArray, offset: int, values: Array[int]) -> void:
	for index in values.size():
		target[offset + index] = values[index]


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
