extends SceneTree

const TERMINAL_EXECUTOR := preload("res://scripts/gameplay/rom_slot15_map_terminal_return_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failures: Array[String] = []


func _initialize() -> void:
	var result := _execute(_fixture())
	_check(bool(result.get("ok", false)), "map-$2D terminal callback accepts the exact source signature")
	if bool(result.get("ok", false)):
		var output_ram: PackedByteArray = result.get("updated_ram", PackedByteArray())
		var output_registers: Dictionary = result.get("registers", {})
		var writes: Array = result.get("ram_writes", [])
		var expected_writes := [
			[0x05CB, 0x01, 0x8339], [0x05CE, 0x80, 0x8345],
			[0x05CD, 0xA0, 0x834C], [0x05DB, 0x00, 0x8351],
			[0x05DC, 0x00, 0x8354], [0x05DD, 0x00, 0x8357],
			[0x0516, 0x30, 0x81A4],
		]
		var writes_match := writes.size() == expected_writes.size()
		for index in mini(writes.size(), expected_writes.size()):
			var write: Dictionary = writes[index]
			var expected: Array = expected_writes[index]
			writes_match = writes_match \
				and int(write.get("address", -1)) == int(expected[0]) \
				and int(write.get("value", -1)) == int(expected[1]) \
				and int(write.get("pc_after_write", -1)) == int(expected[2])
		_check(writes_match, "callback and dispatcher produce the ROM-ordered RAM writes")
		_check(String(result.get("status", "")) == "slot15_map2D_terminal_return_reached_CAF7" \
			and int(result.get("callback_return_pc", -1)) == 0x819C \
			and String(result.get("dispatcher_tail", "")) == "direct_819c" \
			and String(result.get("placement_branch", "")) == "placement_80" \
			and int(output_registers.get("pc", -1)) == 0xCAF7 \
			and int(output_registers.get("sp", -1)) == 0xF2 \
			and output_ram.size() == 0x800 \
			and int(output_ram[0x05CB]) == 0x01 \
			and int(output_ram[0x05CE]) == 0x80 \
			and int(output_ram[0x05CD]) == 0xA0 \
			and int(output_ram[0x0516]) == 0x30 \
			and int(output_ram[0x05DB]) == 0 \
			and int(output_ram[0x05DC]) == 0 \
			and int(output_ram[0x05DD]) == 0,
			"source dispatcher reaches `$CAF7` and commits the expected callback state")
		_check(result.get("source_hashes", {}) == {
			"worker": "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502",
			"placement": "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853",
			"dispatcher": "c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6",
			"finish_trampoline": "bc85dc6c05fac84b9063f3cb28a3acbe16e2591ab2dff53b935530aa2a35940f",
		}, "executor validates the pinned worker, placement, dispatcher, and finish bytes")

	var bad_callback_placement := _fixture()
	var bad_placement_ram: PackedByteArray = bad_callback_placement["boundary"]["ram_image"].duplicate()
	bad_placement_ram[0x05CD] = 0xA0
	bad_callback_placement["boundary"]["ram_image"] = bad_placement_ram
	_check(not bool(_execute(bad_callback_placement).get("ok", false)),
		"map-$2D rejects any callback placement outside the verified `$80` signature")

	var bad_terminal_record := _fixture()
	bad_terminal_record["boundary"]["record"] = PackedByteArray([0x00, 0xEA, 0x0B, 0x12])
	_check(not bool(_execute(bad_terminal_record).get("ok", false)),
		"map-$2D rejects an incorrect terminal task record bank")

	var bad_prg_bank := _fixture()
	bad_prg_bank["boundary"]["bank_low"] = 0x12
	_check(not bool(_execute(bad_prg_bank).get("ok", false)),
		"map-$2D rejects an incorrect worker PRG bank")

	if _failures.is_empty():
		print("PASS: ROM-derived map-$2D terminal signature, callback tail, dispatcher, and rejected near-matches.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0516] = 0x20
	ram[0x05C7] = 0x40
	ram[0x05C8] = 0xA0
	ram[0x05C9] = 0x00
	ram[0x05CA] = 0x02
	ram[0x05CC] = 0x2D
	ram[0x05CD] = 0x80
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xEF] = 0x33
	stack[0xF0] = 0x83
	stack[0xF1] = 0x9B
	stack[0xF2] = 0x81
	var dispatch := {"pc": 0x85C1, "sp": 0xEE, "a": 0x01, "x": 0x40,
		"y": 0x10, "resume_path": "yielded_rts"}
	var boundary := {"rom_sha256": ROM_SHA256, "slot_base": 0x15, "phase": 2,
		"pc": 0x85C1, "sp": 0xEE, "a": 0x01, "x": 0x40, "y": 0x10,
		"p": 0x20, "bank_low": 0x0B, "bank_high": 0x13,
		"record": PackedByteArray([0x00, 0xEA, 0x0B, 0x13]),
		"ram_image": ram, "stack_page": stack}
	return {"dispatch": dispatch, "boundary": boundary}


func _execute(fixture: Dictionary) -> Dictionary:
	var executor := TERMINAL_EXECUTOR.new()
	return executor.execute_from_exhausted_map_worker(fixture["dispatch"], fixture["boundary"])


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
