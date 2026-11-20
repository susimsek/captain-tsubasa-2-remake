extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")

const RAM_SIZE := 0x800
const STACK_SIZE := 0x100


func _init() -> void:
	var executor = EXECUTOR.new()
	var dispatched := _make_dispatched_fixture()
	if not executor.is_scenario1c_parameter58_followup_packet_wait_boundary(dispatched):
		_fail("The exact callback-$63/map-$51 dispatched packet-wait fixture was rejected.")
		return
	print("PASS: exact synthetic callback-$63/map-$51 packet-wait boundary admitted at $804A.")

	var yielded := dispatched.duplicate(true)
	yielded["pc"] = 0xCB0F
	yielded["sp"] = 0xC6
	yielded["a"] = 0x01
	if not executor.is_scenario1c_parameter58_followup_packet_wait_boundary(yielded):
		_fail("The same exact packet-wait fixture was rejected at yielded scheduler boundary $CB0F.")
		return
	print("PASS: same fixture admitted at yielded scheduler boundary $CB0F.")

	if not _verify_rejections(executor, dispatched):
		return
	print("PASS: map, callback chain, stream pointer, countdown state, bank, registers, stack, and image-size mutations rejected.")
	print("LIMIT: this is an in-memory predicate check only; it does not establish FCEUX provenance, packet-wait execution, downstream route progress, PPU/APU timing, or visible fidelity.")
	quit(0)


func _make_dispatched_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(RAM_SIZE)
	var stack := PackedByteArray()
	stack.resize(STACK_SIZE)

	_put_bytes(ram, 0x005D, [0xBD, 0xB4, 0x62, 0x9A])
	_put_bytes(ram, 0x005F, [0x62, 0x9A])
	_put_bytes(ram, 0x0063, [0xB0, 0xA2])
	_put_bytes(ram, 0x0516, [0x01, 0x40, 0x1C, 0x2A, 0xE8, 0x9B, 0x00])
	_put_bytes(ram, 0x0522, [0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40])
	_put_bytes(ram, 0x05C7, [0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])
	_put_bytes(ram, 0x05E3, [0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x00, 0x58])
	_put_bytes(ram, 0x05F3, [0x00, 0x01, 0x03])
	ram[0x003A] = 0x06
	ram[0x05EA] = 0x58
	ram[0x0515] = 0x00
	ram[0x0022] = 0x00
	ram[0x0629] = 0x00
	_put_bytes(stack, 0xC7, [0x04, 0x05, 0x49, 0x80])
	_put_bytes(ram, 0x01C7, [0x04, 0x05, 0x49, 0x80])

	return {
		"pc": 0x804A,
		"sp": 0xCA,
		"a": 0x05,
		"x": 0x05,
		"y": 0x04,
		"p": 0x20,
		"p_known_mask": 0x83,
		"ram_image": ram,
		"stack_page": stack,
		"mapper": {
			"select": 7,
			"bank_low": 0x18,
			"bank_high": 0x19,
			"bank_registers": {6: 0x18, 7: 0x19},
		},
	}


func _verify_rejections(executor: Object, fixture: Dictionary) -> bool:
	var mutation := fixture.duplicate(true)
	mutation["ram_image"][0x05CC] = 0x12
	if not _expect_rejected(executor, "wrong map id", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["ram_image"][0x005D] = 0xA5
	if not _expect_rejected(executor, "wrong callback chain", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["ram_image"][0x0060] = 0x99
	if not _expect_rejected(executor, "wrong animation stream", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["ram_image"][0x05F5] = 0x04
	if not _expect_rejected(executor, "wrong countdown state", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["mapper"]["bank_registers"][7] = 0x17
	if not _expect_rejected(executor, "wrong mapper bank", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["x"] = 0x04
	if not _expect_rejected(executor, "wrong worker register", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["stack_page"][0xC8] = 0x06
	if not _expect_rejected(executor, "wrong saved stack frame", mutation):
		return false

	mutation = fixture.duplicate(true)
	mutation["ram_image"] = mutation["ram_image"].slice(0, RAM_SIZE - 1)
	if not _expect_rejected(executor, "truncated RAM image", mutation):
		return false
	return true


func _expect_rejected(executor: Object, label: String, boundary: Dictionary) -> bool:
	if executor.is_scenario1c_parameter58_followup_packet_wait_boundary(boundary):
		_fail("Mutation was incorrectly admitted: " + label + ".")
		return false
	return true


func _put_bytes(target: PackedByteArray, offset: int, values: Array[int]) -> void:
	for index in values.size():
		target[offset + index] = values[index]


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
