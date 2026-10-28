extends RefCounted
class_name FirstActionMenuPanel
## Rebuilds the two initial command-panel windows from target-ROM descriptors,
## ROM text rows, the ROM border family, and caller-supplied match state.
## It never reads a PPU dump, emulator screenshot, or captured audio.

const LAYOUT_BUILDER := preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const DYNAMIC_RESOLVER := preload("res://scripts/gameplay/first_action_menu_dynamic_resolver.gd")
const ROM_DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu"
const ACTION_MAP_PATH := ROM_DATA_ROOT + "/action_id_to_render_variant_context_00.bin"
const ACTION_POINTERS_PATH := ROM_DATA_ROOT + "/action_render_variant_pointer_table_00_03.bin"
const ACTION_STREAMS_PATH := ROM_DATA_ROOT + "/action_label_render_streams_EA1C_EA45.bin"
const ACTION_STREAM_BASE := 0xEA1C

var packets: Array[Dictionary] = []
var missing_dynamic: Array[Dictionary] = []
var last_error := ""
var dynamic_resolver: FirstActionMenuDynamicResolver
var selected_action_id: int = -1
var selected_action_visible: bool = false


func rebuild_for_match_state(player_state: FirstActionMenuMatchPlayerState) -> bool:
	dynamic_resolver = DYNAMIC_RESOLVER.new() as FirstActionMenuDynamicResolver
	dynamic_resolver.configure(player_state)
	if not dynamic_resolver.has_source_tables():
		return _fail("ROM-derived player/name/stat lookup tables are incomplete.")
	return rebuild_with_dynamic_resolver(Callable(dynamic_resolver, "resolve_token"))


func rebuild_with_dynamic_resolver(dynamic_token_resolver: Callable) -> bool:
	packets.clear()
	missing_dynamic.clear()
	last_error = ""
	var frame_family := FileAccess.get_file_as_bytes(ROM_DATA_ROOT + "/window_3x3_tile_ids.bin")
	if frame_family.size() != 9:
		return _fail("ROM menu window family is missing or has the wrong size.")
	for descriptor_id in [0x02, 0x03]:
		var descriptor_path := ROM_DATA_ROOT + "/menu_descriptor_%02X.bin" % descriptor_id
		var descriptor := FileAccess.get_file_as_bytes(descriptor_path)
		if descriptor.is_empty():
			return _fail("ROM menu descriptor $%02X is missing." % descriptor_id)
		var row_count := int(descriptor[8])
		var row_streams: Array[PackedByteArray] = []
		for row_index in row_count:
			var row_path := ROM_DATA_ROOT + "/menu_%02X_row_%02d.bin" % [descriptor_id, row_index]
			var row_bytes := FileAccess.get_file_as_bytes(row_path)
			if row_bytes.is_empty():
				return _fail("ROM menu row $%02X/%d is missing." % [descriptor_id, row_index])
			row_streams.append(row_bytes)
		var descriptor_packets: Array[Dictionary] = LAYOUT_BUILDER.build_packets(
			descriptor, frame_family, row_streams, dynamic_token_resolver)
		if descriptor_packets.size() != int(descriptor[3]) + 1:
			return _fail("ROM menu descriptor $%02X produced an incomplete progress-row set." % descriptor_id)
		for packet in descriptor_packets:
			packets.append(packet)
			missing_dynamic.append_array(packet.get("missing_dynamic", []))
	return true


func apply_to_ppu_memory(ppu_memory: Dictionary) -> Dictionary:
	var updated := ppu_memory.duplicate()
	for packet_record in packets:
		var address := int(packet_record.get("ppu_address", -1))
		var tiles: PackedByteArray = packet_record.get("tiles", PackedByteArray())
		if address < 0:
			continue
		for tile_index in tiles.size():
			updated[address + tile_index] = int(tiles[tile_index])
	if selected_action_id >= 0:
		for packet_record in build_action_selection_packets(selected_action_id, selected_action_visible):
			var address := int(packet_record.get("ppu_address", -1))
			var tiles: PackedByteArray = packet_record.get("tiles", PackedByteArray())
			if address < 0:
				continue
			for tile_index in tiles.size():
				updated[address + tile_index] = int(tiles[tile_index])
	return updated


## Called from the input component's selection signal and the ROM-tick blink
## phase. Passing action_id -1 restores the ROM's unselected state.
func set_action_selection(action_id: int, blink_visible: bool) -> void:
	selected_action_id = action_id if action_id >= 0 and action_id <= 3 else -1
	selected_action_visible = blink_visible


## Build source-backed $04A5-compatible PPU packets for the action label only.
## Parent route owns the cadence and supplies the $061E bit-6 blink phase.
func build_action_selection_packets(action_id: int, blink_visible: bool) -> Array[Dictionary]:
	var action_map := FileAccess.get_file_as_bytes(ACTION_MAP_PATH)
	var pointer_table := FileAccess.get_file_as_bytes(ACTION_POINTERS_PATH)
	var render_streams := FileAccess.get_file_as_bytes(ACTION_STREAMS_PATH)
	if action_map.size() != 4 or pointer_table.size() < 8 or render_streams.is_empty():
		last_error = "ROM-derived action-label map, pointers, or streams are missing."
		return []
	return LAYOUT_BUILDER.build_action_selection_packets(
		action_id,
		blink_visible,
		action_map,
		pointer_table,
		ACTION_STREAM_BASE,
		render_streams
	)


func _fail(message: String) -> bool:
	last_error = message
	return false
