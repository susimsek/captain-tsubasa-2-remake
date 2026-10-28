extends SceneTree

const Layout = preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const PlayerState = preload("res://scripts/gameplay/first_action_menu_match_player_state.gd")
const DynamicResolver = preload("res://scripts/gameplay/first_action_menu_dynamic_resolver.gd")
const DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const RAM_REFERENCE := "res://reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin"
const PPU_REFERENCE := "res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ram: PackedByteArray = FileAccess.get_file_as_bytes(RAM_REFERENCE)
	var ppu: PackedByteArray = FileAccess.get_file_as_bytes(PPU_REFERENCE)
	assert(ram.size() == 0x800 and ppu.size() == 0x4000, "Expected frame-8953 validation snapshots.")

	# The snapshot values below are match-state inputs for this comparison only.
	# The resolver itself reads only the byte-preserved ROM tables in DATA_ROOT.
	var player_slot: int = ram[0x0441]
	var record_pointers: PackedByteArray = FileAccess.get_file_as_bytes(DATA_ROOT + "player_record_pointer_table_22.bin")
	var record_pointer_offset: int = player_slot * 2
	var player_record_address: int = record_pointers[record_pointer_offset] | (record_pointers[record_pointer_offset + 1] << 8)
	var state = PlayerState.new()
	state.player_slot_index = player_slot
	state.player_id = ram[player_record_address]
	state.current_energy = ram[player_record_address + 1] | (ram[player_record_address + 2] << 8)
	state.level = ram[player_record_address + 3]

	var resolver = DynamicResolver.new()
	resolver.configure(state)
	assert(resolver.has_source_tables(), "ROM-derived dynamic source tables did not load.")
	var callback := Callable(resolver, "resolve_token")
	assert(
		callback.call(0xE0, -1) == PackedByteArray([0x86, 0x92, 0x00, 0x10, 0x11, 0x08, 0x10, 0x00]),
		"ROM-derived player-8 line must match the validation endpoint."
	)
	assert(callback.call(0xE1, 0) == 397, "Energy must be supplied from the selected live player record.")
	assert(callback.call(0xE1, 1) == 8, "ROM profile and level curve should resolve selector 1.")
	assert(callback.call(0xE1, 2) == 8, "ROM profile and level curve should resolve selector 2.")
	assert(callback.call(0xE1, 3) == 9, "ROM profile and level curve should resolve selector 3.")

	var descriptor: PackedByteArray = FileAccess.get_file_as_bytes(DATA_ROOT + "menu_descriptor_03.bin")
	var frame_tiles: PackedByteArray = FileAccess.get_file_as_bytes(DATA_ROOT + "window_3x3_tile_ids.bin")
	var rows: Array[PackedByteArray] = []
	for index in range(5):
		rows.append(FileAccess.get_file_as_bytes(DATA_ROOT + "menu_03_row_%02d.bin" % index))
	var packets: Array[Dictionary] = Layout.build_packets(descriptor, frame_tiles, rows, callback)
	assert(packets.size() == 11, "The descriptor should produce the eleven progress rows 0–10.")
	for packet_info in packets:
		assert(packet_info["complete"], "Observed tuple should resolve every first-panel dynamic token.")
		var address: int = packet_info["ppu_address"]
		var expected_tiles: PackedByteArray = packet_info["tiles"]
		assert(
			ppu.slice(address, address + expected_tiles.size()) == expected_tiles,
			"ROM-derived packet row at PPU $%04X differs from frame-8953 validation data." % address
		)
	print("Dynamic resolver verified: all 11 descriptor-$03 PPU rows match frame-8953 validation data.")
	quit(0)
