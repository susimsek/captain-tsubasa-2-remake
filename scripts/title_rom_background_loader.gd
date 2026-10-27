extends RefCounted
class_name RomTitleBackgroundLoader
## Decodes title background $17 from byte-preserved ROM records and prepares
## ordered PPU writes. Scheduling and NMI timing are owned by the caller.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const RECORD_PATH := "res://reference/rom_extract/intro/background_17.bin"
const LAYOUT_PATH := "res://reference/rom_extract/intro/background_17_layout.json"
const PALETTE_PATH := "res://reference/rom_extract/intro/background_palette_01.bin"
const PACKET_HEADER_BYTES := 3
const BLOCK_TILE_WIDTH := 4
const BLOCK_TILE_HEIGHT := 4
const BLOCK_PAGE_BASE_FILE_OFFSET := 0x010010
const BLOCK_PAGE_VARIANT_OFFSET := 0x1100

var packets: Array[Dictionary] = []
var payload_byte_count := 0
var queue_encoded_byte_count := 0
var palette_bytes := PackedByteArray()
var chr_1k_banks: Array[int] = []
var origin_tile_x := 0
var origin_tile_y := 0
var metatile_rows := 0
var metatile_columns := 0
var record_file_offset := -1
var palette_file_offset := -1
var block_page_selector := -1
var block_page_offset := -1
var block_page_base_file_offset := -1


func build_packets() -> bool:
	packets.clear()
	payload_byte_count = 0
	queue_encoded_byte_count = 0
	palette_bytes.clear()
	chr_1k_banks.clear()
	record_file_offset = -1
	palette_file_offset = -1
	block_page_selector = -1
	block_page_offset = -1
	block_page_base_file_offset = -1

	var layout := _read_json(LAYOUT_PATH)
	if layout.is_empty() or str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("ROM title background metadata is missing or belongs to another ROM.")
		return false
	if str(layout.get("background_id", "")) != "0x17":
		push_error("Title background loader received a record other than $17.")
		return false

	var record := FileAccess.get_file_as_bytes(RECORD_PATH)
	var expected_record := _parse_hex_bytes(str(layout.get("record_raw_hex", "")))
	if record.is_empty() or record != expected_record or record.size() < 8:
		push_error("Title background $17 differs from its preserved source bytes.")
		return false
	record_file_offset = _parse_hex_word(str(layout.get("record_file_offset", "")))
	if record_file_offset != 0x00E383:
		push_error("Title background $17 source offset does not match the verified ROM record.")
		return false

	var chr_banks_variant: Variant = layout.get("chr_1k_banks_for_background", [])
	if not chr_banks_variant is Array or chr_banks_variant.size() != 4:
		push_error("Title background metadata does not define four CHR 1-KiB banks.")
		return false
	for bank_variant in chr_banks_variant:
		chr_1k_banks.append(int(bank_variant))
	if chr_1k_banks != [124, 125, 126, 127]:
		push_error("Title background $17 CHR bank selectors do not match ROM record $7C/$7E.")
		return false

	var source_palette_path := "res://" + str(layout.get("palette_source_bin", ""))
	palette_bytes = FileAccess.get_file_as_bytes(source_palette_path)
	var expected_palette := _parse_hex_bytes(str(layout.get("palette_raw_hex", "")))
	if palette_bytes.size() != 16 or palette_bytes != expected_palette:
		push_error("Title background $17 palette differs from its preserved ROM bytes.")
		return false
	if source_palette_path != PALETTE_PATH:
		push_error("Title background $17 palette source path is not the expected ROM extract.")
		return false
	palette_file_offset = _parse_hex_word(str(layout.get("palette_file_offset", "")))
	if palette_file_offset != 0x00D020:
		push_error("Title background $17 palette offset does not match the verified ROM source.")
		return false

	metatile_rows = int(record[3])
	metatile_columns = int(record[4])
	var packed_origin := int(record[5])
	var metatile_count := metatile_rows * metatile_columns
	if metatile_rows != 6 or metatile_columns != 8 or record.size() != 6 + metatile_count + 2:
		push_error("Title background $17 record has an unexpected dimensions or length.")
		return false
	if _parse_hex_bytes(str(layout.get("metatile_ids_hex", ""))) != record.slice(6, 6 + metatile_count):
		push_error("Title background metatile IDs differ from the source record.")
		return false
	if int(record[0]) != 0x7C or int(record[1]) != 0x7E or int(record[2]) != 0x81:
		push_error("Title background $17 header selectors differ from verified ROM values.")
		return false
	block_page_selector = (int(record[2]) >> 7) & 0x01
	block_page_offset = block_page_selector * BLOCK_PAGE_VARIANT_OFFSET
	block_page_base_file_offset = BLOCK_PAGE_BASE_FILE_OFFSET + block_page_offset
	if int(layout.get("block_page_selector", -1)) != block_page_selector \
			or _parse_hex_word(str(layout.get("block_page_offset", ""))) != block_page_offset \
			or _parse_hex_word(str(layout.get("block_page_base_file_offset", ""))) != block_page_base_file_offset:
		push_error("Title background $17 block page does not match its ROM selector bit.")
		return false
	if packed_origin != 0x08 or str(layout.get("origin_ppu_address", "")) != "0x2080":
		push_error("Title background $17 origin differs from the source-verified PPU origin.")
		return false
	if int(record[record.size() - 2]) != 0x00 or int(record[record.size() - 1]) != 0xA0:
		push_error("Title background $17 pointer-table terminator bytes are unexpected.")
		return false
	origin_tile_x = int(layout.get("origin_x_in_two_nametables", -1))
	origin_tile_y = int(layout.get("origin_y", -1))
	if origin_tile_x != 0 or origin_tile_y != 4:
		push_error("Title background $17 decoded origin metadata is unexpected.")
		return false

	var blocks := _load_block_records(layout.get("used_4x4_blocks", []))
	if blocks.is_empty():
		return false
	for block_row in metatile_rows:
		for block_column in metatile_columns:
			var block_id := int(record[6 + block_row * metatile_columns + block_column])
			if not blocks.has(block_id):
				push_error("Title background $17 references missing block $%02X." % block_id)
				return false
			var block_record: Dictionary = blocks[block_id]
			var block_bytes: PackedByteArray = block_record["bytes"]
			var block_source_offset := int(block_record["file_offset"])
			if block_bytes.size() != 17:
				push_error("Title block $%02X must contain one attribute and sixteen tile IDs." % block_id)
				return false
			_append_attribute_packet(block_row, block_column, block_id, int(block_bytes[0]),
				block_source_offset)
			for tile_row in BLOCK_TILE_HEIGHT:
				var start := 1 + tile_row * BLOCK_TILE_WIDTH
				_append_tile_row_packet(block_row, block_column, tile_row, block_id,
					block_bytes.slice(start, start + BLOCK_TILE_WIDTH), block_source_offset)

	var expected_packet_count := metatile_rows * metatile_columns * (1 + BLOCK_TILE_HEIGHT)
	var expected_payload_bytes := metatile_rows * metatile_columns * (1 + BLOCK_TILE_WIDTH * BLOCK_TILE_HEIGHT)
	var expected_queue_bytes := expected_packet_count * PACKET_HEADER_BYTES + expected_payload_bytes
	if packets.size() != expected_packet_count or payload_byte_count != expected_payload_bytes \
			or queue_encoded_byte_count != expected_queue_bytes:
		push_error("Title background $17 PPU packet totals are inconsistent with its ROM record.")
		return false
	return true


func _append_attribute_packet(block_row: int, block_column: int, block_id: int,
		value: int, block_source_offset: int) -> void:
	var tile_x := origin_tile_x + block_column * BLOCK_TILE_WIDTH
	var tile_y := origin_tile_y + block_row * BLOCK_TILE_HEIGHT
	var address := _attribute_address(tile_x, tile_y)
	_append_packet("attribute", address, PackedByteArray([value]), block_row,
		block_column, block_id, -1, block_source_offset)


func _append_tile_row_packet(block_row: int, block_column: int, tile_row: int,
		block_id: int, row_payload: PackedByteArray, block_source_offset: int) -> void:
	var tile_x := origin_tile_x + block_column * BLOCK_TILE_WIDTH
	var tile_y := origin_tile_y + block_row * BLOCK_TILE_HEIGHT + tile_row
	var address := _nametable_address(tile_x, tile_y)
	_append_packet("tile_row", address, row_payload, block_row, block_column,
		block_id, tile_row, block_source_offset)


func _append_packet(kind: String, address: int, payload: PackedByteArray,
		block_row: int, block_column: int, block_id: int, tile_row: int,
		block_source_offset: int) -> void:
	var encoded_size := PACKET_HEADER_BYTES + payload.size()
	packets.append({
		"kind": kind,
		"ppu_address": address,
		"payload": payload,
		"block_row": block_row,
		"block_column": block_column,
		"block_id": block_id,
		"source_block_file_offset": block_source_offset,
		"tile_row": tile_row,
		"queue_encoded_bytes": encoded_size,
	})
	payload_byte_count += payload.size()
	queue_encoded_byte_count += encoded_size


func _nametable_address(tile_x: int, tile_y: int) -> int:
	var page := int(tile_x / 32)
	var local_x := tile_x % 32
	var local_y := tile_y % 30
	var base := 0x2000 if page == 0 else 0x2400
	return base + local_y * 32 + local_x


func _attribute_address(tile_x: int, tile_y: int) -> int:
	var page := int(tile_x / 32)
	var block_x := int((tile_x % 32) / 4)
	var block_y := int((tile_y % 30) / 4)
	var base := 0x23C0 if page == 0 else 0x27C0
	return base + block_y * 8 + block_x


func _load_block_records(raw_records: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw_records is Array:
		push_error("Title background $17 block metadata is missing.")
		return result
	for raw_record in raw_records:
		if not raw_record is Dictionary:
			push_error("Title background $17 has a malformed block descriptor.")
			return {}
		var descriptor: Dictionary = raw_record
		var block_id := _parse_hex_word(str(descriptor.get("id", "")))
		var source_path := "res://" + str(descriptor.get("source_bin", ""))
		if block_id < 0 or not FileAccess.file_exists(source_path):
			push_error("Title background $17 block source is missing or has an invalid ID.")
			return {}
		var block_bytes := FileAccess.get_file_as_bytes(source_path)
		var expected_bytes := _parse_hex_bytes(str(descriptor.get("raw_hex", "")))
		var source_offset := _parse_hex_word(str(descriptor.get("file_offset", "")))
		var expected_source := "reference/rom_extract/intro/block_%02X.bin" % block_id
		if block_page_selector == 1:
			expected_source = "reference/rom_extract/intro/block_%02X_page_11.bin" % block_id
		var expected_source_offset := BLOCK_PAGE_BASE_FILE_OFFSET \
			+ block_page_offset + 17 * block_id
		if str(descriptor.get("source_bin", "")) != expected_source \
				or block_bytes.size() != 17 or block_bytes != expected_bytes \
				or source_offset != expected_source_offset:
			push_error("Title background $17 block $%02X differs from its source metadata." % block_id)
			return {}
		if result.has(block_id):
			push_error("Title background $17 block metadata repeats ID $%02X." % block_id)
			return {}
		result[block_id] = {"bytes": block_bytes, "file_offset": source_offset}
	return result


func _parse_hex_bytes(hex_text: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in hex_text.split(" ", false):
		var value := token.strip_edges()
		if value.is_empty():
			continue
		var parsed := value.hex_to_int()
		if parsed < 0 or parsed > 0xFF:
			return PackedByteArray()
		result.append(parsed)
	return result


func _parse_hex_word(hex_text: String) -> int:
	var value := hex_text.strip_edges()
	if value.begins_with("0x") or value.begins_with("0X"):
		value = value.substr(2)
	var parsed := value.hex_to_int()
	return parsed if parsed >= 0 else -1


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing ROM-derived title background metadata: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid ROM-derived title background metadata: %s" % path)
		return {}
	return parsed
