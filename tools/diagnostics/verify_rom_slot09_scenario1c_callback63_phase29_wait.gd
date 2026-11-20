extends SceneTree
## Verifies the frame-9249 callback-$63/map-$51 phase-$29 wait tick from ROM bytes.

const PREFIX := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	var prefix: RefCounted = PREFIX.new()
	if not prefix.configure_from_project_sources():
		_fail("Slot-$09 ROM source setup failed: " + String(prefix.error_message))
		return
	var dispatch := _make_frame_9249_dispatch()
	var result: Dictionary = prefix.execute_from_next_task_dispatch(dispatch)
	if not bool(result.get("ok", false)):
		_fail("The frame-9249 callback-$63/map-$51 wait dispatch was rejected: "
				+ String(result.get("reason", prefix.error_message)))
		return
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	if String(result.get("status", "")) != "stopped_before_worker_body" \
			or int(result.get("entry_pc", -1)) != 0xEB8B \
			or int(result.get("exit_pc", -1)) != 0x86F8 \
			or not bool(result.get("scenario_wait_worker_executed", false)) \
			or not bool(result.get("scenario_route_state_executed", false)) \
			or bool(result.get("scenario_active", true)) \
			or bool(result.get("worker_body_executed", true)) \
			or bool(result.get("trace_state_used", true)) \
			or output_ram.size() != 0x800 \
			or int(output_ram[0x0519]) != 0x26 \
			or output_ram.slice(0x0516, 0x0519) != PackedByteArray([0x29, 0x40, 0x1C]) \
			or output_ram[0x003A] != 0x06 \
			or output_ram.slice(0x005D, 0x0061) != PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			or output_ram.slice(0x0523, 0x052B) != PackedByteArray([0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x00]) \
			or output_ram.slice(0x05C7, 0x05D3) != PackedByteArray([
				0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			or int(registers.get("pc", -1)) != 0x86F8 \
			or int(registers.get("sp", -1)) != 0x78:
		_fail("The ROM wait tick differs from FCEUX seq. 2795-2797: %s" % JSON.stringify({
			"status": result.get("status", ""),
			"exit_pc": registers.get("pc", -1),
			"exit_sp": registers.get("sp", -1),
			"scenario": output_ram.slice(0x0516, 0x051A).hex_encode() if output_ram.size() == 0x800 else "invalid",
			"cursor": output_ram[0x003A] if output_ram.size() == 0x800 else -1,
		}))
		return
	if not _has_wait_write(result.get("writes", [])):
		_fail("The `$0519=$26` result has no ROM `$ED5C` write event.")
		return
	var wrong_map := dispatch.duplicate(true)
	wrong_map["ram_image"][0x05CC] = 0x12
	var rejected: Dictionary = prefix.execute_from_next_task_dispatch(wrong_map)
	if bool(rejected.get("ok", false)):
		_fail("The callback-$63 phase-$29 profile accepted a map-$12 mutation.")
		return
	print("PASS: frame-9249 callback-$63/map-$51 source path decrements `$0519 27->26`, returns through `$EB9E`, and stops at `$86F8`.")
	print("PASS: ordered ROM write and phase/map/callback/pointer preservation match the source trace.")
	print("LIMIT: synthetic dispatch is built from FCEUX seq. 2795; no timing, PPU pixels, audio, or worker body is claimed.")
	quit(0)


func _make_frame_9249_dispatch() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x09
	ram[0x0009] = 0x00
	ram[0x000A] = 0x76
	ram[0x000B] = 0x18
	ram[0x000C] = 0x19
	ram[0x0017] = 0x0B
	ram[0x0021] = 0x1E
	ram[0x0022] = 0x00
	ram[0x0023] = 0x07
	ram[0x0024] = 0x18
	ram[0x0025] = 0x19
	ram[0x002B] = 0x03
	ram[0x003A] = 0x06
	_put_bytes(ram, 0x005D, [0xBD, 0xB4, 0x62, 0x9A])
	_put_bytes(ram, 0x0516, [0x29, 0x40, 0x1C, 0x27, 0xE8, 0x9B, 0x00])
	_put_bytes(ram, 0x0522, [0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x00, 0x00])
	_put_bytes(ram, 0x05C7, [0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])
	_put_bytes(ram, 0x05E3, [0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58])
	_put_bytes(ram, 0x05F3, [0x00, 0x01, 0x00])
	ram[0x05FB] = 0x00
	ram[0x0635] = 0x84
	ram[0x0637] = 0x54
	var stack := PackedByteArray()
	stack.resize(0x100)
	_put_bytes(stack, 0x77, [0x18, 0x05, 0x8A, 0xEB])
	_put_bytes(ram, 0x0177, [0x18, 0x05, 0x8A, 0xEB])
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x09,
		"resume_path": "yielded_rts",
		"pc": 0xEB8B,
		"sp": 0x7A,
		"a": 0x05,
		"x": 0x05,
		"y": 0x18,
		"p": 0x30,
		"p_known_mask": 0xFF,
		"bank_low": 0x18,
		"bank_high": 0x19,
		"task_record": PackedByteArray([0x00, 0x76, 0x18, 0x19]),
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07},
		"ram_image": ram,
		"stack_page": stack,
	}


func _has_wait_write(writes: Array) -> bool:
	for write_variant: Variant in writes:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("pc", -1)) == 0xED5C \
					and int(write.get("address", -1)) == 0x0519 \
					and int(write.get("value", -1)) == 0x26:
				return true
	return false


func _put_bytes(target: PackedByteArray, offset: int, values: Array[int]) -> void:
	for index in values.size():
		target[offset + index] = values[index]


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
