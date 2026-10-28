extends SceneTree

const Layout = preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var descriptor: PackedByteArray = FileAccess.get_file_as_bytes(DATA_ROOT + "menu_descriptor_03.bin")
	var frame_tiles: PackedByteArray = FileAccess.get_file_as_bytes(DATA_ROOT + "window_3x3_tile_ids.bin")
	var row_streams: Array[PackedByteArray] = []
	for index in range(5):
		row_streams.append(FileAccess.get_file_as_bytes(DATA_ROOT + "menu_03_row_%02d.bin" % index))

	var packets: Array[Dictionary] = Layout.build_packets(descriptor, frame_tiles, row_streams)
	assert(packets.size() == 11, "Descriptor $03 must produce progress rows 0 through 10.")
	var final_packet: Dictionary = packets[10]
	assert(final_packet["ppu_address"] == 0x2372, "Progress 10 must target PPU $2372.")
	assert(
		final_packet["packet"] == PackedByteArray([
			0x0C, 0x72, 0x23,
			0x9E, 0xA9, 0xA9, 0xA9, 0xA9, 0xA9,
			0xA9, 0xA9, 0xA9, 0xA9, 0xA9, 0x9F,
		]),
		"ROM-derived final row packet must match the frame-8953 $04A5 record."
	)
	assert(final_packet["complete"], "Final border packet has no dynamic substitutions.")

	var callback_packets: Array[Dictionary] = Layout.build_packets(
		descriptor,
		frame_tiles,
		row_streams,
		Callable(self, "_resolve_synthetic_token")
	)
	assert(callback_packets[1]["complete"], "Synthetic E0 callback should fill the player row.")
	assert(
		callback_packets[1]["tiles"] == PackedByteArray([
			0x9C, 0xA8, 0x86, 0x92, 0x00, 0x20, 0x21, 0x22, 0x23, 0x24, 0xA8, 0x9D,
		]),
		"E0 callback tiles must overlay the ROM border at descriptor column 2."
	)
	assert(
		callback_packets[3]["tiles"] == PackedByteArray([
			0xAA, 0x45, 0x6E, 0x65, 0x72, 0x6A, 0x69, 0x00, 0x37, 0x35, 0x00, 0xAB,
		]),
		"E1 callback digits must use ROM tile IDs and right-align after the label."
	)
	print("First-action menu ROM layout verification passed: 11 rows; final $04A5 packet is exact.")
	quit(0)


func _resolve_synthetic_token(token: int, selector: int) -> Variant:
	if token == 0xE0:
		return PackedByteArray([0x86, 0x92, 0x00, 0x20, 0x21, 0x22, 0x23, 0x24])
	match selector:
		0:
			return 42
		3:
			return 7
		2:
			return 11
		1:
			return 5
	return 0
