class_name FirstActionMenuRomLayout
extends RefCounted
## Pure packet builder for ROM-decoded first-action-menu descriptor bytes.
## Callers provide raw descriptor/row bytes, the decoded ROM window-tile family,
## and match-state substitutions. This class reads no ROM or capture at runtime.

const HEADER_SIZE: int = 9
const ROW_RECORD_SIZE: int = 4
const ROW_END: int = 0xFC
const DYNAMIC_PLAYER_LINE: int = 0xE0
const DYNAMIC_STAT: int = 0xE1
const DIGIT_TILE_BASE: int = 0x33
const ACTION_LABEL_FILL: int = 0xFE


## Return one PPU transfer packet for each descriptor progress row, in ROM order.
##
## `descriptor` and `row_streams` are the byte-preserved resources extracted from
## the target ROM. `frame_family_tiles` is the selected nine-tile 3x3 family.
## For the first-match descriptors $02/$03, the verified packed selector yields
## family zero (`9C A8 9D AA 00 AB 9E A9 9F`).
##
## `dynamic_state` may provide:
## - for E0, a PackedByteArray/Array of position pair + blank + ROM-derived name
##   tiles;
## - for E1, an integer value selected by its following selector byte
##   (0 energy, 1..3 stats).
## Missing/invalid callback results stay blank and are listed in each affected
## packet's `missing_dynamic` array; callers must not treat those rows as complete.
static func build_packets(
	_descriptor: PackedByteArray,
	frame_family_tiles: PackedByteArray,
	row_streams: Array[PackedByteArray],
	dynamic_token_resolver: Callable = Callable()
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _descriptor.size() < HEADER_SIZE:
		push_error("Menu descriptor is shorter than its 9-byte header.")
		return result
	var row_count: int = _descriptor[8]
	if _descriptor.size() != HEADER_SIZE + row_count * ROW_RECORD_SIZE:
		push_error("Menu descriptor byte length does not match its row count.")
		return result
	if row_streams.size() != row_count:
		push_error("Menu text row count does not match the descriptor.")
		return result
	if frame_family_tiles.size() < 9:
		push_error("A complete 3x3 ROM window-tile family is required.")
		return result

	var packet_width: int = _descriptor[2]
	var final_progress: int = _descriptor[3]
	var frame_column: int = _descriptor[4]
	var top_edge: int = _descriptor[5]
	var frame_width: int = _descriptor[6]
	var bottom_offset: int = _descriptor[7]
	var base_address: int = _descriptor[0] | (_descriptor[1] << 8)

	for progress in range(final_progress + 1):
		var tiles := PackedByteArray()
		tiles.resize(packet_width)
		for i in range(packet_width):
			tiles[i] = 0

		var frame_row: int = -1
		if progress == top_edge:
			frame_row = 0
		elif progress == top_edge + bottom_offset:
			frame_row = 2
		elif progress > top_edge and progress < top_edge + bottom_offset:
			frame_row = 1
		if frame_row >= 0:
			var frame_start: int = frame_row * 3
			if frame_column >= 0 and frame_column + frame_width <= packet_width:
				tiles[frame_column] = frame_family_tiles[frame_start]
				for center_index in range(frame_width - 2):
					tiles[frame_column + 1 + center_index] = frame_family_tiles[frame_start + 1]
				tiles[frame_column + frame_width - 1] = frame_family_tiles[frame_start + 2]

		var missing_dynamic: Array[Dictionary] = []
		for row_index in range(row_count):
			var record_offset: int = HEADER_SIZE + row_index * ROW_RECORD_SIZE
			var row_coordinate: int = _descriptor[record_offset]
			# The shared ROM routine also visits row_coordinate - 1 with a
			# suppression flag. At this first-menu endpoint those rows remain
			# blank; visible text is emitted at the exact coordinate.
			if progress != row_coordinate:
				continue
			var text_column: int = frame_column + _descriptor[record_offset + 1]
			var missing := _write_text_row(
				tiles,
				text_column,
				row_streams[row_index],
				dynamic_token_resolver,
				row_index
			)
			missing_dynamic.append_array(missing)

		var address: int = (base_address + progress * 0x20) & 0x3FFF
		var packet := PackedByteArray([packet_width, address & 0xFF, (address >> 8) & 0xFF])
		packet.append_array(tiles)
		result.append({
			"progress": progress,
			"ppu_address": address,
			"packet": packet,
			"tiles": tiles,
			"complete": missing_dynamic.is_empty(),
			"missing_dynamic": missing_dynamic,
		})
	return result


## Return the two ROM-described packets that present the selected context-0
## action. `visible` is the ROM blink phase ($061E bit 6). An unselected state
## is represented by action_id -1 and emits no overlay packets.
static func build_action_selection_packets(
	action_id: int,
	visible: bool,
	action_id_to_variant: PackedByteArray,
	variant_pointer_table: PackedByteArray,
	stream_base_address: int,
	stream_data: PackedByteArray
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if action_id < 0:
		return result
	if action_id >= action_id_to_variant.size():
		push_error("Action ID is outside the ROM context-0 action map.")
		return result
	var variant: int = action_id_to_variant[action_id]
	var pointer_offset: int = variant * 2
	if pointer_offset + 1 >= variant_pointer_table.size():
		push_error("Action render variant is outside the ROM pointer table.")
		return result
	var stream_address: int = (
		variant_pointer_table[pointer_offset]
		| (variant_pointer_table[pointer_offset + 1] << 8)
	)
	var stream_offset: int = stream_address - stream_base_address
	if stream_offset < 0 or stream_offset + 3 > stream_data.size():
		push_error("Action render pointer is outside the preserved ROM stream bytes.")
		return result

	var ppu_address: int = stream_data[stream_offset] | (stream_data[stream_offset + 1] << 8)
	var shape: int = stream_data[stream_offset + 2]
	var row_count: int = shape & 0x03
	var row_width: int = shape >> 2
	if row_count <= 0 or row_width <= 0:
		push_error("Action render stream has an empty row shape.")
		return result
	stream_offset += 3

	for row_index in row_count:
		var row_tiles := PackedByteArray()
		while row_tiles.size() < row_width:
			if stream_offset >= stream_data.size():
				push_error("Action render stream ends before its row is complete.")
				return []
			var tile: int = stream_data[stream_offset]
			stream_offset += 1
			if tile == ACTION_LABEL_FILL:
				while row_tiles.size() < row_width:
					row_tiles.append(0)
				break
			row_tiles.append(tile)
		if not visible:
			for tile_index in row_tiles.size():
				row_tiles[tile_index] = 0
		var row_address: int = (ppu_address + row_index * 0x20) & 0x3FFF
		var packet := PackedByteArray([
			row_width,
			row_address & 0xFF,
			(row_address >> 8) & 0xFF,
		])
		packet.append_array(row_tiles)
		result.append({
			"action_id": action_id,
			"render_variant": variant,
			"visible": visible,
			"row": row_index,
			"ppu_address": row_address,
			"packet": packet,
			"tiles": row_tiles,
		})
	return result


static func _write_text_row(
	tiles: PackedByteArray,
	start_column: int,
	stream: PackedByteArray,
	dynamic_token_resolver: Callable,
	row_index: int
) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	var cursor: int = start_column
	var source_index: int = 0
	while source_index < stream.size():
		var token: int = stream[source_index]
		source_index += 1
		if token == ROW_END:
			break
		if token < DYNAMIC_PLAYER_LINE:
			_write_tile(tiles, cursor, token)
			cursor += 1
			continue
		if token == DYNAMIC_PLAYER_LINE:
			if not dynamic_token_resolver.is_valid():
				missing.append({"row": row_index, "token": "E0", "needs": "player_line_tiles"})
			else:
				var player_tiles: Variant = dynamic_token_resolver.call(DYNAMIC_PLAYER_LINE, -1)
				if not (player_tiles is Array or player_tiles is PackedByteArray) or player_tiles.is_empty():
					missing.append({"row": row_index, "token": "E0", "needs": "non-empty player_line_tiles"})
				else:
					for tile in player_tiles:
						_write_tile(tiles, cursor, int(tile))
						cursor += 1
			continue
		if token == DYNAMIC_STAT:
			if source_index >= stream.size():
				missing.append({"row": row_index, "token": "E1", "needs": "selector byte"})
				break
			var selector: int = stream[source_index]
			source_index += 1
			if not dynamic_token_resolver.is_valid():
				missing.append({"row": row_index, "token": "E1", "selector": selector, "needs": "stat_values[selector]"})
				continue
			var resolved_stat: Variant = dynamic_token_resolver.call(DYNAMIC_STAT, selector)
			if not (resolved_stat is int):
				missing.append({"row": row_index, "token": "E1", "selector": selector, "needs": "integer stat result"})
				continue
			var value: int = max(0, int(resolved_stat))
			var digits: String = str(value)
			var first_digit_column: int = cursor - digits.length() + 1
			for digit_index in range(digits.length()):
				var digit: int = digits.unicode_at(digit_index) - 48
				_write_tile(tiles, first_digit_column + digit_index, DIGIT_TILE_BASE + digit)
			continue
		missing.append({"row": row_index, "token": "unknown", "value": token})
	return missing


static func _write_tile(tiles: PackedByteArray, column: int, tile_id: int) -> void:
	if column >= 0 and column < tiles.size():
		tiles[column] = tile_id & 0xFF
