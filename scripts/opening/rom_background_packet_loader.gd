extends RefCounted
class_name RomBackgroundPacketLoader
## Builds ordered PPU packets from the preserved ROM record, layout manifest,
## and selected 4x4 block-page byte extracts, including the $5B.0 variant.
## This describes static nametable writes; it does not emulate raster effects.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const INTRO_DATA_ROOT := "res://reference/rom_extract/intro"
const RECORD_HEADER_BYTES := 6
const BLOCK_BYTES := 17
const BLOCK_SIDE_TILES := 4
const PACKET_HEADER_BYTES := 3
const QUEUE_CURSOR_LIMIT := 0x3D
const BLOCK_PAGE_BASE_FILE_OFFSET := 0x010010
const BLOCK_PAGE_VARIANT_OFFSET := 0x1100
const BLOCK_PAGE_RECORD_BYTES := 17
const TWO_NAMETABLE_TILE_WIDTH := 64
const NAMETABLE_TILE_WIDTH := 32
const NAMETABLE_TILE_HEIGHT := 30
const ATTRIBUTE_TABLE_BASE := 0x23C0
const NAMETABLE_BASE := 0x2000
# These records' byte-decoded logical origins differ from their measured PPU
# destinations. BG03's record origin is $2108 (page 0), while the source NMI
# writes its first tile block at $2508 (page 1) during frames 2123–2127; its
# captured nametable likewise places the scene in $2400–$27FF. This is a +32
# tile world-X offset. BG07's decoded block coordinates are x=20..43, while
# its source writes/snapshots place those IDs at x=40..63. Preserve each
# record's logical origin and apply the source-observed destination here.
const OBSERVED_PPU_WORLD_X_OFFSET_TILES := {
	0x03: 32,
	0x07: 20,
	0x0B: 20,
}

var packets: Array[Dictionary] = []
var metadata: Dictionary = {}
var payload_byte_count := 0
var encoded_packet_byte_count := 0
var last_error := ""


static func get_supported_background_ids() -> Array[int]:
	var result: Array[int] = []
	var directory := DirAccess.open(INTRO_DATA_ROOT)
	if directory == null:
		return result
	directory.list_dir_begin()
	while true:
		var file_name := directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir() or not file_name.begins_with("background_") or not file_name.ends_with("_layout.json"):
			continue
		var id_text := file_name.trim_prefix("background_").trim_suffix("_layout.json")
		if id_text.length() != 2:
			continue
		var id := id_text.hex_to_int()
		if id >= 0 and id <= 0xFF:
			result.append(id)
	directory.list_dir_end()
	result.sort()
	return result


func build_packets(background_id: int) -> bool:
	_clear_result()
	if background_id < 0 or background_id > 0xFF:
		return _fail("Background ID must fit in one ROM byte.")

	var id_hex := "%02X" % background_id
	var layout_path := "%s/background_%s_layout.json" % [INTRO_DATA_ROOT, id_hex]
	var layout := _read_json(layout_path)
	if layout.is_empty():
		return _fail("Missing or invalid background layout: %s" % layout_path)
	if str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("Background layout belongs to a different ROM revision: %s" % layout_path)
	if str(layout.get("background_id", "")).to_upper() != "0X%s" % id_hex:
		return _fail("Background layout ID does not match requested ID $%s." % id_hex)

	var record_path := _project_resource_path(str(layout.get("record_source_bin", "")))
	var expected_record_source := "reference/rom_extract/intro/background_%s.bin" % id_hex
	if record_path.is_empty() or str(layout.get("record_source_bin", "")) != expected_record_source:
		return _fail("Background $%s has an invalid record source path." % id_hex)
	var record := FileAccess.get_file_as_bytes(record_path)
	var expected_record := _parse_hex_bytes(str(layout.get("record_raw_hex", "")))
	if record.is_empty() or expected_record.is_empty() or record != expected_record:
		return _fail("Background $%s record bytes do not match its preserved layout manifest." % id_hex)
	if record.size() < RECORD_HEADER_BYTES:
		return _fail("Background $%s record is shorter than its six-byte header." % id_hex)

	var rows := int(layout.get("metatile_rows", -1))
	var columns := int(layout.get("metatile_columns", -1))
	if rows <= 0 or columns <= 0:
		return _fail("Background $%s has invalid metatile dimensions." % id_hex)
	if record[3] != rows or record[4] != columns:
		return _fail("Background $%s dimensions differ from the ROM record header." % id_hex)
	if not _validate_header_metadata(layout, record, id_hex):
		return false
	var block_page_selector := (int(record[2]) >> 7) & 0x01
	var expected_page_base := BLOCK_PAGE_BASE_FILE_OFFSET + block_page_selector * BLOCK_PAGE_VARIANT_OFFSET
	if int(layout.get("block_page_selector", -1)) != block_page_selector:
		return _fail("Background $%s block-page selector differs from record bit 7." % id_hex)
	if _parse_hex_word(str(layout.get("block_page_offset", ""))) != block_page_selector * BLOCK_PAGE_VARIANT_OFFSET:
		return _fail("Background $%s block-page offset differs from the ROM selector." % id_hex)
	if _parse_hex_file_offset(str(layout.get("block_page_base_file_offset", ""))) != expected_page_base:
		return _fail("Background $%s block-page base offset differs from the ROM selector." % id_hex)

	var metatile_count := rows * columns
	var record_end := RECORD_HEADER_BYTES + metatile_count
	if record.size() < record_end:
		return _fail("Background $%s record is truncated before its metatile IDs." % id_hex)
	var metatile_ids := record.slice(RECORD_HEADER_BYTES, record_end)
	if metatile_ids != _parse_hex_bytes(str(layout.get("metatile_ids_hex", ""))):
		return _fail("Background $%s metatile IDs differ from the extracted record bytes." % id_hex)
	var trailing_bytes := record.slice(record_end, record.size())
	if trailing_bytes != _parse_hex_bytes(str(layout.get("trailing_record_bytes_hex", ""))):
		return _fail("Background $%s trailing record bytes differ from the layout manifest." % id_hex)

	var block_records := _load_block_records(
		layout.get("used_4x4_blocks", []), id_hex, block_page_selector
	)
	if block_records.is_empty():
		return false

	var origin_x := int(layout.get("origin_x_in_two_nametables", -1))
	var origin_y := int(layout.get("origin_y", -1))
	if origin_x < 0 or origin_x >= TWO_NAMETABLE_TILE_WIDTH or origin_x % BLOCK_SIDE_TILES != 0:
		return _fail("Background $%s origin X is not a 4-tile-aligned two-nametable coordinate." % id_hex)
	if origin_y < 0 or origin_y % BLOCK_SIDE_TILES != 0:
		return _fail("Background $%s origin Y is not a 4-tile-aligned coordinate." % id_hex)

	var generated_tile_placements: Dictionary = {}
	var packet_traversal := str(layout.get("block_packet_traversal", "row_major"))
	if packet_traversal != "row_major" and packet_traversal != "right_to_left_per_row":
		return _fail("Background $%s declares an unsupported block packet traversal." % id_hex)
	var world_x_origin := int(layout.get("metatile_world_x_origin", origin_x))
	if world_x_origin < 0 or world_x_origin >= TWO_NAMETABLE_TILE_WIDTH \
			or world_x_origin % BLOCK_SIDE_TILES != 0:
		return _fail("Background $%s metatile world X origin is invalid." % id_hex)
	var observed_ppu_x_offset := int(OBSERVED_PPU_WORLD_X_OFFSET_TILES.get(background_id, 0))
	var packet_origin_x := posmod(origin_x + observed_ppu_x_offset, TWO_NAMETABLE_TILE_WIDTH)
	var packet_world_x_origin := posmod(world_x_origin + observed_ppu_x_offset, TWO_NAMETABLE_TILE_WIDTH)
	if packet_traversal == "right_to_left_per_row" \
			and posmod(world_x_origin + (columns - 1) * BLOCK_SIDE_TILES, TWO_NAMETABLE_TILE_WIDTH) != origin_x:
		return _fail("Background $%s reverse traversal does not begin at the decoded PPU origin." % id_hex)
	for block_row in range(rows):
		for packet_column in range(columns):
			var block_column := columns - 1 - packet_column \
				if packet_traversal == "right_to_left_per_row" else packet_column
			var block_id := int(metatile_ids[block_row * columns + block_column])
			if not block_records.has(block_id):
				return _fail("Background $%s references missing block $%02X." % [id_hex, block_id])
			var block_bytes: PackedByteArray = block_records[block_id]
			if block_bytes.size() != BLOCK_BYTES:
				return _fail("Background $%s block $%02X is not 17 bytes." % [id_hex, block_id])
			if not _append_block_packets(
				block_row, block_column, block_id, block_bytes,
				packet_world_x_origin if packet_traversal == "right_to_left_per_row" else packet_origin_x,
				origin_y, generated_tile_placements, id_hex
			):
				return false

	if not _validate_tile_placements(layout.get("tile_placements", []), generated_tile_placements,
			metatile_count, id_hex, observed_ppu_x_offset):
		return false
	metadata = {
		"background_id": id_hex,
		"rom_sha256": SOURCE_ROM_SHA256,
		"record_cpu_address": str(layout.get("record_cpu_address", "")),
		"record_file_offset": str(layout.get("record_file_offset", "")),
		# These are taken from the validated project-owned record bytes, not from
		# the layout manifest or an emulator RAM snapshot.
		"record_chr_selector_bytes": [int(record[0]), int(record[1])],
		"block_page_selector": block_page_selector,
		"block_page_offset": str(layout.get("block_page_offset", "")),
		"block_page_base_file_offset": str(layout.get("block_page_base_file_offset", "")),
		"metatile_rows": rows,
		"metatile_columns": columns,
		"origin_x_in_two_nametables": origin_x,
		"observed_ppu_world_x_offset_tiles": observed_ppu_x_offset,
		"ppu_world_x_origin": packet_origin_x,
		"origin_y": origin_y,
		"origin_ppu_address": str(layout.get("origin_ppu_address", "")),
		"block_packet_traversal": packet_traversal,
		"packet_order": "record rows top-to-bottom, block columns right-to-left per row, attribute then tile rows 0 through 3" \
			if packet_traversal == "right_to_left_per_row" \
			else "attribute, then tile rows 0 through 3 for each row-major metatile",
		"payload_byte_count": payload_byte_count,
		"encoded_packet_byte_count": encoded_packet_byte_count,
		"queue_cursor_limit": QUEUE_CURSOR_LIMIT,
		"assumptions": [
			"Packed origin is interpreted as 4-tile coordinates: low 3 bits select X and upper 5 bits select Y.",
			"Horizontal placement wraps modulo 64 tiles across nametables $2000 and $2400.",
			"BG03 PPU writes are shifted +32 world tiles from its decoded record origin; the source NMI writes the first tile block at $2508 and captured scene data occupies page 1 ($2400–$27FF) during frames 2123–2127.",
			"BG07 PPU writes are shifted +20 world tiles from its decoded record origin; the mapping matches source PPU snapshots at frames 1535/1548 and traced $2007 destinations.",
			"BG0A's right-to-left per-row block packet traversal and world-X origin are verified against the source NMI transfer; other records retain row-major traversal until independently traced.",
			"Vertical placement is static and must remain within nametable tile rows 0 through 29.",
			"Scrolling, mirroring, raster CHR changes, sprite/OAM composition, and exact subframe NMI timing are outside this packet builder.",
			"Record palette-flag bit 7 selects block-page bit $5B.0; bank-0 $8EF0 adds $1100 to the bank-8 block pointer when set.",
			"Record trailer bytes remain preserved; their special motion and timing are outside this static packet builder.",
		],
	}
	return true


func build_capacity_batches() -> Array[Dictionary]:
	var batches: Array[Dictionary] = []
	var batch_packets: Array[Dictionary] = []
	var queue_cursor := 0
	var batch_payload_bytes := 0
	for packet in packets:
		var payload: PackedByteArray = packet["payload"]
		if queue_cursor + payload.size() >= QUEUE_CURSOR_LIMIT and not batch_packets.is_empty():
			batches.append(_make_capacity_batch(batch_packets, queue_cursor, batch_payload_bytes))
			batch_packets.clear()
			queue_cursor = 0
			batch_payload_bytes = 0
		batch_packets.append(packet)
		queue_cursor += int(packet["queue_encoded_bytes"])
		batch_payload_bytes += payload.size()
	if not batch_packets.is_empty():
		batches.append(_make_capacity_batch(batch_packets, queue_cursor, batch_payload_bytes))
	return batches


func _make_capacity_batch(batch_packets: Array[Dictionary], queue_cursor: int,
		batch_payload_bytes: int) -> Dictionary:
	return {
		"packets": batch_packets.duplicate(),
		"queue_cursor_bytes": queue_cursor,
		"terminator_offset": queue_cursor,
		"payload_byte_count": batch_payload_bytes,
		"packet_count": batch_packets.size(),
		"queue_buffer_capacity_bytes": 0x40,
	}


func _append_block_packets(block_row: int, block_column: int, block_id: int,
		block_bytes: PackedByteArray, origin_x: int, origin_y: int,
		generated_tile_placements: Dictionary, id_hex: String) -> bool:
	var block_x_unwrapped := origin_x + block_column * BLOCK_SIDE_TILES
	var block_y := origin_y + block_row * BLOCK_SIDE_TILES
	if block_y + BLOCK_SIDE_TILES > NAMETABLE_TILE_HEIGHT:
		return _fail("Background $%s block row %d extends below nametable tile row 29." % [id_hex, block_row])
	var block_x := posmod(block_x_unwrapped, TWO_NAMETABLE_TILE_WIDTH)
	var attribute_address := _attribute_address(block_x, block_y)
	if attribute_address < 0:
		return _fail("Could not map background $%s attribute address." % id_hex)
	_append_packet("attribute", attribute_address, PackedByteArray([block_bytes[0]]), block_row, block_column, block_id)

	for tile_row in range(BLOCK_SIDE_TILES):
		var tile_y := block_y + tile_row
		var row_payload := block_bytes.slice(1 + tile_row * BLOCK_SIDE_TILES, 1 + (tile_row + 1) * BLOCK_SIDE_TILES)
		var tile_address := _tile_row_address(block_x, tile_y)
		if tile_address < 0:
			return _fail("Could not map background $%s tile row address." % id_hex)
		_append_packet("tile_row", tile_address, row_payload, block_row, block_column, block_id, tile_row)
		for tile_column in range(BLOCK_SIDE_TILES):
			var tile_x := posmod(block_x_unwrapped + tile_column, TWO_NAMETABLE_TILE_WIDTH)
			var placement_key := "%d:%d" % [tile_x, tile_y]
			if generated_tile_placements.has(placement_key):
				return _fail("Background $%s wraps onto an already occupied tile at (%d, %d)." % [id_hex, tile_x, tile_y])
			generated_tile_placements[placement_key] = {
				"x": tile_x,
				"unwrapped_x": block_x_unwrapped + tile_column,
				"y": tile_y,
				"tile_id": int(row_payload[tile_column]),
				"block_id": block_id,
			}
	return true


func _append_packet(kind: String, address: int, payload: PackedByteArray,
		block_row: int, block_column: int, block_id: int, tile_row: int = -1) -> void:
	var packet := {
		"kind": kind,
		"ppu_address": address,
		"payload": payload,
		"block_row": block_row,
		"block_column": block_column,
		"block_id": block_id,
		"queue_encoded_bytes": PACKET_HEADER_BYTES + payload.size(),
	}
	if tile_row >= 0:
		packet["tile_row"] = tile_row
	packets.append(packet)
	payload_byte_count += payload.size()
	encoded_packet_byte_count += PACKET_HEADER_BYTES + payload.size()


func _tile_row_address(tile_x: int, tile_y: int) -> int:
	if tile_x < 0 or tile_x >= TWO_NAMETABLE_TILE_WIDTH or tile_y < 0 or tile_y >= NAMETABLE_TILE_HEIGHT:
		return -1
	var nametable := int(tile_x / NAMETABLE_TILE_WIDTH)
	var local_x := tile_x % NAMETABLE_TILE_WIDTH
	return NAMETABLE_BASE + nametable * 0x400 + tile_y * NAMETABLE_TILE_WIDTH + local_x


func _attribute_address(tile_x: int, tile_y: int) -> int:
	if tile_x < 0 or tile_x >= TWO_NAMETABLE_TILE_WIDTH or tile_y < 0 or tile_y >= NAMETABLE_TILE_HEIGHT:
		return -1
	if tile_x % BLOCK_SIDE_TILES != 0 or tile_y % BLOCK_SIDE_TILES != 0:
		return -1
	var nametable := int(tile_x / NAMETABLE_TILE_WIDTH)
	var attribute_column := int((tile_x % NAMETABLE_TILE_WIDTH) / BLOCK_SIDE_TILES)
	var attribute_row := int(tile_y / BLOCK_SIDE_TILES)
	return ATTRIBUTE_TABLE_BASE + nametable * 0x400 + attribute_row * 8 + attribute_column


func _load_block_records(raw_records: Variant, id_hex: String, block_page_selector: int) -> Dictionary:
	var result: Dictionary = {}
	if not raw_records is Array or raw_records.is_empty():
		_fail("Background $%s has no extracted block descriptors." % id_hex)
		return result
	for raw_record in raw_records:
		if not raw_record is Dictionary:
			_fail("Background $%s has a malformed block descriptor." % id_hex)
			return {}
		var descriptor: Dictionary = raw_record
		var block_id := _parse_hex_byte(str(descriptor.get("id", "")))
		if block_id < 0:
			_fail("Background $%s has an invalid block ID." % id_hex)
			return {}
		var source_path := _project_resource_path(str(descriptor.get("source_bin", "")))
		var expected_source := "reference/rom_extract/intro/block_%02X.bin" % block_id
		if block_page_selector == 1:
			expected_source = "reference/rom_extract/intro/block_%02X_page_11.bin" % block_id
		if source_path.is_empty() or str(descriptor.get("source_bin", "")) != expected_source or not FileAccess.file_exists(source_path):
			_fail("Background $%s block $%02X source is missing." % [id_hex, block_id])
			return {}
		var expected_file_offset := BLOCK_PAGE_BASE_FILE_OFFSET \
			+ block_page_selector * BLOCK_PAGE_VARIANT_OFFSET \
			+ BLOCK_PAGE_RECORD_BYTES * block_id
		if _parse_hex_file_offset(str(descriptor.get("file_offset", ""))) != expected_file_offset:
			_fail("Background $%s block $%02X source offset does not match its selected page." % [id_hex, block_id])
			return {}
		var block_bytes := FileAccess.get_file_as_bytes(source_path)
		var expected_bytes := _parse_hex_bytes(str(descriptor.get("raw_hex", "")))
		if block_bytes.size() != BLOCK_BYTES or block_bytes != expected_bytes:
			_fail("Background $%s block $%02X differs from its preserved ROM bytes." % [id_hex, block_id])
			return {}
		if result.has(block_id):
			_fail("Background $%s repeats block descriptor $%02X." % [id_hex, block_id])
			return {}
		result[block_id] = block_bytes
	return result


func _validate_header_metadata(layout: Dictionary, record: PackedByteArray, id_hex: String) -> bool:
	var chr_banks: Variant = layout.get("chr_2k_bank_start_ids", [])
	if not chr_banks is Array or chr_banks.size() != 2:
		return _fail("Background $%s must declare two CHR 2-KiB bank selectors." % id_hex)
	if int(chr_banks[0]) != int(record[0]) or int(chr_banks[1]) != int(record[1]):
		return _fail("Background $%s CHR selectors differ from the record bytes." % id_hex)
	if _parse_hex_byte(str(layout.get("palette_flag_byte", ""))) != int(record[2]):
		return _fail("Background $%s palette flag differs from the record bytes." % id_hex)
	var packed_origin := _parse_hex_byte(str(layout.get("packed_origin", "")))
	if packed_origin != int(record[5]):
		return _fail("Background $%s packed origin differs from the record bytes." % id_hex)
	var origin_x := (packed_origin & 0x07) * BLOCK_SIDE_TILES
	var origin_y := ((packed_origin >> 3) & 0x1F) * BLOCK_SIDE_TILES
	if origin_x != int(layout.get("origin_x_in_two_nametables", -1)) or origin_y != int(layout.get("origin_y", -1)):
		return _fail("Background $%s decoded origin differs from the layout manifest." % id_hex)
	var origin_address := _tile_row_address(origin_x, origin_y)
	if origin_address < 0 or _parse_hex_word(str(layout.get("origin_ppu_address", ""))) != origin_address:
		return _fail("Background $%s origin PPU address differs from its decoded coordinates." % id_hex)
	return true


func _validate_tile_placements(raw_placements: Variant, generated: Dictionary,
		metatile_count: int, id_hex: String, observed_ppu_x_offset: int = 0) -> bool:
	if not raw_placements is Array or raw_placements.size() != metatile_count * 16:
		return _fail("Background $%s tile placement manifest has an unexpected size." % id_hex)
	var expected: Dictionary = {}
	for raw_placement in raw_placements:
		if not raw_placement is Dictionary:
			return _fail("Background $%s has a malformed tile placement entry." % id_hex)
		var placement: Dictionary = raw_placement
		var expected_x := posmod(int(placement.get("x", -1)) + observed_ppu_x_offset,
			TWO_NAMETABLE_TILE_WIDTH)
		var key := "%d:%d" % [expected_x, int(placement.get("y", -1))]
		if expected.has(key):
			return _fail("Background $%s tile placement manifest duplicates coordinate %s." % [id_hex, key])
		var raw_block_id: Variant = placement.get("block_id", -1)
		var manifest_block_id := _parse_hex_byte(str(raw_block_id)) if raw_block_id is String else int(raw_block_id)
		expected[key] = {
			"tile_id": int(placement.get("tile_id", -1)),
			"block_id": manifest_block_id,
		}
	if expected.size() != generated.size():
		return _fail("Background $%s generated tile coordinate count differs from its manifest." % id_hex)
	for key in generated:
		if not expected.has(key):
			return _fail("Background $%s generated an unlisted tile coordinate %s." % [id_hex, key])
		var expected_tile: Dictionary = expected[key]
		var generated_tile: Dictionary = generated[key]
		if int(expected_tile["tile_id"]) != int(generated_tile["tile_id"]) or int(expected_tile["block_id"]) != int(generated_tile["block_id"]):
			return _fail("Background $%s tile/block bytes disagree at coordinate %s." % [id_hex, key])
	return true


func _project_resource_path(path: String) -> String:
	var normalized := path.trim_prefix("res://")
	if normalized.begins_with("/") or not normalized.begins_with("reference/rom_extract/intro/"):
		return ""
	return "res://%s" % normalized


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	return parsed


func _parse_hex_bytes(hex_text: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in hex_text.strip_edges().split(" ", false):
		var value := token.strip_edges()
		if value.is_empty():
			continue
		var parsed := value.hex_to_int()
		if parsed < 0 or parsed > 0xFF:
			return PackedByteArray()
		result.append(parsed)
	return result


func _parse_hex_byte(hex_text: String) -> int:
	var value := hex_text.strip_edges()
	if value.begins_with("0x") or value.begins_with("0X"):
		value = value.substr(2)
	var parsed := value.hex_to_int()
	return parsed if parsed >= 0 and parsed <= 0xFF else -1


func _parse_hex_word(hex_text: String) -> int:
	var value := hex_text.strip_edges()
	if value.begins_with("0x") or value.begins_with("0X"):
		value = value.substr(2)
	var parsed := value.hex_to_int()
	return parsed if parsed >= 0 and parsed <= 0x3FFF else -1


func _parse_hex_file_offset(hex_text: String) -> int:
	var value := hex_text.strip_edges()
	if value.begins_with("0x") or value.begins_with("0X"):
		value = value.substr(2)
	var parsed := value.hex_to_int()
	return parsed if parsed >= 0 and parsed <= 0xFFFFFF else -1


func _clear_result() -> void:
	packets.clear()
	metadata.clear()
	payload_byte_count = 0
	encoded_packet_byte_count = 0
	last_error = ""


func _fail(message: String) -> bool:
	last_error = message
	push_error(message)
	return false
