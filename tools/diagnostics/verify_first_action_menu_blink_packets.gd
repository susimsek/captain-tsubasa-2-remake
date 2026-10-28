extends SceneTree

const Layout = preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const STREAM_BASE := 0xEA1C


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var action_map := FileAccess.get_file_as_bytes(DATA_ROOT + "action_id_to_render_variant_context_00.bin")
	var pointers := FileAccess.get_file_as_bytes(DATA_ROOT + "action_render_variant_pointer_table_00_03.bin")
	var streams := FileAccess.get_file_as_bytes(DATA_ROOT + "action_label_render_streams_EA1C_EA45.bin")
	assert(action_map == PackedByteArray([0x02, 0x01, 0x00, 0x03]))
	assert(pointers == PackedByteArray([0x1C, 0xEA, 0x29, 0xEA, 0x34, 0xEA, 0x3D, 0xEA]))

	var expected_rows: Array[Array] = [
		[[0, 0, 0, 0, 0], [0x53, 0x75, 0x74, 0x20, 0]],
		[[0, 0x20, 0, 0, 0], [0x50, 0x61, 0x73, 0x20, 0]],
		[[0, 0, 0, 0, 0], [0x43, 0x61, 0x6C, 0x69, 0x6D]],
		[[0, 0, 0, 0, 0], [0x60, 0x72, 0x1A, 0x63, 0]],
	]
	for action_id in range(4):
		var visible_packets := Layout.build_action_selection_packets(
			action_id, true, action_map, pointers, STREAM_BASE, streams)
		assert(visible_packets.size() == 2, "Each action record emits two ROM rows.")
		for row_index in range(2):
			var packet: Dictionary = visible_packets[row_index]
			assert(packet["ppu_address"] == 0x22AC + row_index * 0x20)
			assert(packet["tiles"] == PackedByteArray(expected_rows[action_id][row_index]))
			assert(packet["packet"].size() == 8)

		var hidden_packets := Layout.build_action_selection_packets(
			action_id, false, action_map, pointers, STREAM_BASE, streams)
		assert(hidden_packets.size() == 2)
		for hidden_packet in hidden_packets:
			assert(hidden_packet["tiles"] == PackedByteArray([0, 0, 0, 0, 0]))

	assert(
		Layout.build_action_selection_packets(-1, true, action_map, pointers, STREAM_BASE, streams).is_empty(),
		"The ROM's unselected state must not draw a default action overlay."
	)
	print("ROM action-selection packets verified for all four context-0 actions and both blink phases.")
	quit(0)
