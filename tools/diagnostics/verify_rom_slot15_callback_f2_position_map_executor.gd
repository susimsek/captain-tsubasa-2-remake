extends SceneTree

const F2_EXECUTOR := preload("res://scripts/gameplay/rom_slot15_callback_f2_position_map_executor.gd")
const MAP_WORKER := preload("res://scripts/gameplay/rom_slot15_map_worker_8525_prefix_executor.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0518] = 0x36
	ram[0x0000] = 0x15
	ram[0x0523] = 0x32
	ram[0x0524] = 0x72
	ram[0x0528] = 0x66
	ram[0x0529] = 0xFF
	ram[0x0441] = 0x08
	ram[0x0366] = 0x7C
	ram[0x0368] = 0x7C
	ram[0x0635] = 0x7C
	ram[0x0637] = 0x7C
	ram[0x0638] = 0x00
	ram[0x05FB] = 0x00
	ram[0x05CD] = 0xA0
	var entry := {
		"ok": true,
		"status": "reached_callback_dispatcher_entry",
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"exit_pc": 0x814C,
		"dispatcher_dispatch": {"pc": 0x814C, "a": 0xF0, "x": 0xF0, "y": 0,
			"sp": 0xF2, "p": 0x20, "p_known_mask": 0, "slot_base": 0x15,
			"bank_low": 0x0B, "bank_high": 0x0C},
		"ram_image": ram,
		"stack_page": stack,
	}
	var f2 = F2_EXECUTOR.new()
	var dispatch: Dictionary = f2.execute_from_callback_dispatcher(entry)
	if not bool(dispatch.get("ok", false)):
		_fail("F2 dispatcher failed: " + str(dispatch.get("error", "unknown")))
		return
	if int(dispatch.get("map_id", -1)) != 0x00 \
			or int(dispatch.get("map_position_index", -1)) != 0x54 \
			or int(dispatch.get("holder_record_address", -1)) != 0x0360 \
			or int(dispatch.get("exit_pc", -1)) != 0x8525 \
			or int(dispatch.get("registers", {}).get("sp", -1)) != 0xEE \
			or int(dispatch.get("ram_image", PackedByteArray())[0x05CC]) != 0x00:
		_fail("ROM F2 holder-position calculation differs at `$8525`: " + str(dispatch))
		return
	var worker = MAP_WORKER.new()
	var setup: Dictionary = worker.execute_map_to_first_yield_callsite(dispatch)
	if not bool(setup.get("ok", false)):
		_fail("Map-$00 worker setup failed: " + str(setup.get("error", "unknown")))
		return
	if int(setup.get("map_id", -1)) != 0x00 \
			or int(setup.get("map_selector", -1)) != 0x00 \
			or int(setup.get("map_data_pointer", -1)) != 0x8B64 \
			or setup.get("chr_pair", PackedByteArray()) != PackedByteArray([0x3C, 0x4A]) \
			or setup.get("staged_chr_pair", PackedByteArray()) != PackedByteArray([0xBC, 0x4A]) \
			or int(setup.get("exit_pc", -1)) != 0x856F:
		_fail("Map-$00 worker setup differs at `$856F`: " + str(setup))
		return
	print("PASS: callback-$72 F2 resolves from live holder record and coordinates through ROM map table to map-$00.")
	print("PASS: shared `$8525` worker stages CHR `$3C/$4A` and reaches its `$856F` yield with map pointer `$8B64`.")
	print("LIMIT: map rows, field PPU rendering, later `$A3C9` event `$20`, and command-menu parity remain open.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
