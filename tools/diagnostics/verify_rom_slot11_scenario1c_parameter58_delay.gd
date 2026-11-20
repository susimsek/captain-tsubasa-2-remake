extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const STREAM_SHA256 := "15779004184bd0d73ede7e28bb543f63a92f64cc67a99cc49a4f14ec66d60274"


func _init() -> void:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		_fail("ROM source setup failed: " + executor.error_message)
		return
	var boundary := _frame_9233_boundary()
	if not executor.is_scenario1c_parameter58_initial_delay_boundary(boundary):
		_fail("The frame-9233 boundary does not match the exact scenario-$1C parameter-$58 profile.")
		return
	var dispatch_boundary := boundary.duplicate(true)
	dispatch_boundary["a"] = 0x01
	if not executor.is_scenario1c_parameter58_initial_delay_boundary(dispatch_boundary):
		_fail("The scheduler-dispatched `$804A` A=$01 variant did not retain the exact scenario-$1C parameter-$58 profile.")
		return
	var yielded_boundary := boundary.duplicate(true)
	yielded_boundary["pc"] = 0xCB0F
	yielded_boundary["sp"] = 0xC6
	yielded_boundary["a"] = 0x01
	if not executor.is_scenario1c_parameter58_initial_delay_boundary(yielded_boundary):
		_fail("The scheduler-yielded `$CB0F` task boundary did not match the exact scenario-$1C parameter-$58 profile.")
		return
	var result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var callsite: Dictionary = result.get("yield_callsite_registers", {})
	var hashes: Dictionary = result.get("source_span_hashes", {})
	var source_reads: Array = result.get("source_reads", [])
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "slot11_actor_scenario1c_parameter58_delay_at_8047" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0x804A \
			or int(result.get("exit_pc", -1)) != 0x8047 \
			or int(result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(callsite.get("a", -1)) != 0x01 \
			or int(callsite.get("x", -1)) != 0x62 \
			or int(callsite.get("y", -1)) != 0x00 \
			or ram.size() != 0x800 \
			or ram.slice(0x005F, 0x0061) != PackedByteArray([0x62, 0x9A]) \
			or ram.slice(0x05E4, 0x05E6) != PackedByteArray([0x01, 0x01]) \
			or int(ram[0x05E9]) != 0x01 or int(ram[0x05F4]) != 0x00 \
			or int(ram[0x05F5]) != 0x01 \
			or String(hashes.get("bank18_actor_stream_parameter58_9A62_9A6F.bin", "")) != STREAM_SHA256 \
			or not _has_stream_read(source_reads, 0x9A62, 0x01) \
			or not (result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (result.get("apu_register_writes", []) as Array).is_empty() \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("source_timing_modeled", true)):
		_fail("The ROM `$9A62` byte did not advance through `$804D->$A1EB(F4=0)->$8047`: " + str({
			"status": result.get("status", ""), "reason": result.get("reason", result.get("error", "")),
			"callsite": callsite, "ram_E4_E5_E9_F4_F5": ram.slice(0x05E4, 0x05F6).hex_encode(),
			"source_reads": source_reads,
		}))
		return
	print("PASS: frame-9233 scenario-$1C parameter-$58 state reads ROM `$9A62=$01`, advances the source worker through `$A1EB` with F4=0, and yields at `$8047`.")
	var countdown_boundary := _scenario1c_countdown_boundary()
	if not executor.is_scenario1c_parameter58_delay_boundary(countdown_boundary):
		_fail("The frame-9234 `$05E9` countdown boundary does not match the exact scenario-$1C parameter-$58 profile.")
		return
	var yielded_countdown_boundary := countdown_boundary.duplicate(true)
	yielded_countdown_boundary["pc"] = 0xCB0F
	yielded_countdown_boundary["sp"] = 0xC6
	yielded_countdown_boundary["a"] = 0x01
	if not executor.is_scenario1c_parameter58_delay_boundary(yielded_countdown_boundary):
		_fail("The scheduler-yielded `$CB0F` countdown boundary did not retain its exact profile.")
		return
	var countdown_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(countdown_boundary)
	var countdown_ram: PackedByteArray = countdown_result.get("ram_image", PackedByteArray())
	var countdown_callsite: Dictionary = countdown_result.get("yield_callsite_registers", {})
	var countdown_reads: Array = countdown_result.get("source_reads", [])
	if not bool(countdown_result.get("ok", false)) \
			or String(countdown_result.get("status", "")) != "slot11_actor_scenario1c_parameter58_countdown_at_8047" \
			or String(countdown_result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(countdown_result.get("entry_pc", -1)) != 0x804A \
			or int(countdown_result.get("exit_pc", -1)) != 0x8047 \
			or int(countdown_result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(countdown_callsite.get("a", -1)) != 0x01 \
			or int(countdown_callsite.get("x", -1)) != 0x62 \
			or int(countdown_callsite.get("y", -1)) != 0x00 \
			or countdown_ram.size() != 0x800 \
			or int(countdown_ram[0x0519]) != 0x3A \
			or countdown_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			or countdown_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x01, 0x00, 0x01]) \
			or int(countdown_ram[0x05F4]) != 0x00 \
			or int(countdown_ram[0x05F5]) != 0x01 \
			or not _has_ram_read(countdown_reads, 0x05E9, 0x01) \
			or not (countdown_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (countdown_result.get("apu_register_writes", []) as Array).is_empty() \
			or bool(countdown_result.get("trace_state_used", true)) \
			or bool(countdown_result.get("source_timing_modeled", true)):
		_fail("The frame-9234 ROM worker did not decrement `$05E9=1` to zero and return through `$A1EB` with F4=0: " + str({
			"status": countdown_result.get("status", ""), "reason": countdown_result.get("reason", countdown_result.get("error", "")),
			"callsite": countdown_callsite, "ram_E3_EA_F3_F5": countdown_ram.slice(0x05E3, 0x05F6).hex_encode(),
			"source_reads": countdown_reads,
		}))
		return
	print("PASS: frame-9234 scenario-$1C parameter-$58 state reads `$05E9=1`, decrements it to zero, and yields at `$8047`.")
	var event_boundary := _scenario1c_event_boundary()
	if not executor.is_scenario1c_parameter58_delay_boundary(event_boundary):
		_fail("The frame-9235 `$9A63` event boundary does not match the exact scenario-$1C parameter-$58 profile.")
		return
	var event_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(event_boundary)
	var event_ram: PackedByteArray = event_result.get("ram_image", PackedByteArray())
	var decoded_event: Dictionary = event_result.get("decoded_event", {})
	var event_hashes: Dictionary = event_result.get("source_span_hashes", {})
	var event_reads: Array = event_result.get("source_reads", [])
	if not bool(event_result.get("ok", false)) \
			or String(event_result.get("status", "")) != "slot11_actor_event_payload_at_cb0f" \
			or String(event_result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(event_result.get("entry_pc", -1)) != 0x804A \
			or int(event_result.get("exit_pc", -1)) != 0xCB0F \
			or int(event_result.get("yield_callsite_pc", -1)) != 0x8266 \
			or int(event_result.get("yield_target_pc", -1)) != 0xCB0F \
			or decoded_event.get("address", -1) != 0x9A63 \
			or decoded_event.get("byte", -1) != 0x10 \
			or decoded_event.get("type", -1) != 0x01 \
			or decoded_event.get("payload_address", -1) != 0x8E37 \
			or decoded_event.get("payload", PackedByteArray()) != PackedByteArray([0x2C, 0x22, 0x14]) \
			or event_ram.size() != 0x800 \
			or int(event_ram[0x05E6]) != 0x0E or int(event_ram[0x05E7]) != 0x14 \
			or int(event_ram[0x05E8]) != 0x06 or int(event_ram[0x05F4]) != 0x80 \
			or event_ram.slice(0x0061, 0x0063) != PackedByteArray([0x37, 0x8E]) \
			or String(event_hashes.get("bank18_actor_stream_parameter58_9A62_9A6F.bin", "")) != STREAM_SHA256 \
			or not _has_source_read(event_reads, 0x9A63, 0x10, "actor_event_byte") \
			or not _has_source_read(event_reads, 0x86B9, 0x0E, "actor_event_type_value") \
			or not _has_source_read(event_reads, 0x8E37, 0x2C, "actor_event_payload_byte_0") \
			or not (event_result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (event_result.get("apu_register_writes", []) as Array).is_empty() \
			or bool(event_result.get("trace_state_used", true)) \
			or bool(event_result.get("source_timing_modeled", true)):
		_fail("The ROM `$9A63=$10` type-$01 path did not resolve and yield with its ROM payload: " + str({
			"status": event_result.get("status", ""), "reason": event_result.get("reason", event_result.get("error", "")),
			"event": decoded_event, "ram_E3_EA": event_ram.slice(0x05E3, 0x05EB).hex_encode(),
			"source_reads": event_reads,
		}))
		return
	print("PASS: frame-9235 `$9A63=$10` dispatches through `$8218` as type 1, reads payload `$8E37`, and yields at `$CB0F`.")
	print("LIMIT: deterministic source-executor fixtures use ordinary-input Godot boundaries; this is not an independent FCEUX snapshot or hardware timing check.")
	quit(0)


func _has_stream_read(reads: Array, address: int, value: int) -> bool:
	for item: Variant in reads:
		if item is Dictionary and int(item.get("address", -1)) == address \
				and int(item.get("value", -1)) == value:
			return true
	return false


func _has_ram_read(reads: Array, address: int, value: int) -> bool:
	for item: Variant in reads:
		if item is Dictionary and int(item.get("address", -1)) == address \
				and int(item.get("value", -1)) == value \
				and String(item.get("kind", "")) == "actor_animation_delay":
			return true
	return false


func _has_source_read(reads: Array, address: int, value: int, kind: String) -> bool:
	for item: Variant in reads:
		if item is Dictionary and int(item.get("address", -1)) == address \
				and int(item.get("value", -1)) == value \
				and String(item.get("kind", "")) == kind:
			return true
	return false


func _scenario1c_countdown_boundary() -> Dictionary:
	var boundary := _frame_9233_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	ram[0x0519] = 0x3A
	ram[0x05E4] = 0x01
	ram[0x05E5] = 0x01
	ram[0x05E9] = 0x01
	stack[0xC7] = 0x00
	stack[0xC8] = 0x62
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	boundary["pc"] = 0x804A
	boundary["sp"] = 0xCA
	boundary["record"] = PackedByteArray([0x00, 0xC6, 0x18, 0x19])
	boundary["a"] = 0x62
	boundary["x"] = 0x62
	boundary["y"] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _scenario1c_event_boundary() -> Dictionary:
	var boundary := _scenario1c_countdown_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	ram[0x0519] = 0x39
	ram[0x05E9] = 0x00
	boundary["ram_image"] = ram
	return boundary


func _frame_9233_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC7] = 0xB1
	stack[0xC8] = 0x62
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	ram[0x003A] = 0x06
	ram[0x005D] = 0xA5
	ram[0x005E] = 0xB4
	ram[0x005F] = 0x62
	ram[0x0060] = 0x9A
	ram[0x0063] = 0xD7
	ram[0x0064] = 0xA2
	ram[0x0516] = 0x01
	ram[0x0517] = 0x40
	ram[0x0518] = 0x1C
	ram[0x0519] = 0x3B
	ram[0x051A] = 0xE8
	ram[0x051B] = 0x9B
	ram[0x051C] = 0x00
	ram[0x0522] = 0x00
	ram[0x0523] = 0x3C
	ram[0x0524] = 0x01
	ram[0x0525] = 0x02
	ram[0x0526] = 0x3C
	ram[0x0527] = 0x4A
	ram[0x0528] = 0x78
	ram[0x0529] = 0x58
	ram[0x052A] = 0x40
	ram[0x05C7] = 0x24
	ram[0x05C8] = 0xC0
	ram[0x05CB] = 0x01
	ram[0x05CC] = 0x12
	ram[0x05CD] = 0x80
	ram[0x05CE] = 0xA0
	ram[0x05D0] = 0x02
	ram[0x05E3] = 0x01
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05EA] = 0x58
	ram[0x05F3] = 0x01
	ram[0x05F5] = 0x01
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804A, "sp": 0xCA, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC6, 0x18, 0x19]),
		"a": 0x62, "x": 0x62, "y": 0xB1, "p": 0x20, "p_known_mask": 0x83,
		"mapper": {
			"bank_low": 0x18, "bank_high": 0x19,
			"bank_registers": {6: 0x18, 7: 0x19}, "select": 7,
		},
		"ram_image": ram,
		"stack_page": stack,
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
