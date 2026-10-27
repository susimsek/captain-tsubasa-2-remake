extends RefCounted
class_name RomBackground01Loader
## Builds the ROM F9 01 loader's ordered nametable packets from extracted
## metatile/block bytes. Scheduling and the NMI consumer are owned by the
## cold-start command presenter.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const RECORD_PATH := "res://reference/rom_extract/intro/background_01.bin"
const LAYOUT_PATH := "res://reference/rom_extract/intro/background_01_layout.json"
const ROW_PACKET_PAYLOAD_BYTES := 4
const ATTRIBUTE_PACKET_PAYLOAD_BYTES := 1
const PACKET_HEADER_BYTES := 3
const QUEUE_CURSOR_LIMIT := 0x3D

var packets: Array[Dictionary] = []
var payload_byte_count := 0


func build_packets() -> bool:
	packets.clear()
	payload_byte_count = 0
	var layout := _read_json(LAYOUT_PATH)
	if layout.is_empty() or str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("F9 background-01 metadata is missing or belongs to another ROM.")
		return false
	if str(layout.get("background_id", "")) != "0x01":
		push_error("F9 background-01 loader received a different background record.")
		return false

	var record := FileAccess.get_file_as_bytes(RECORD_PATH)
	var expected_record := _parse_hex_bytes(str(layout.get("record_raw_hex", "")))
	if record.is_empty() or record != expected_record:
		push_error("F9 background-01 record differs from its preserved ROM metadata.")
		return false

	var metatile_ids := _parse_hex_bytes(str(layout.get("metatile_ids_hex", "")))
	var rows := int(layout.get("metatile_rows", -1))
	var columns := int(layout.get("metatile_columns", -1))
	if rows != 4 or columns != 16 or metatile_ids.size() != rows * columns:
		push_error("F9 background-01 record must decode to four rows by sixteen metatiles.")
		return false

	var blocks := _load_block_records(layout.get("used_4x4_blocks", []))
	if blocks.is_empty():
		return false
	for block_row in rows:
		for block_column in columns:
			var id := int(metatile_ids[block_row * columns + block_column])
			if not blocks.has(id):
				push_error("F9 background-01 references missing 4x4 block $%02X." % id)
				return false
			var block_bytes: PackedByteArray = blocks[id]
			if block_bytes.size() != 17:
				push_error("F9 background-01 block $%02X must contain one attribute and sixteen tile IDs." % id)
				return false
			_append_attribute_packet(block_row, block_column, id, int(block_bytes[0]))
			for tile_row in 4:
				var row_payload := block_bytes.slice(1 + tile_row * 4, 1 + tile_row * 4 + 4)
				_append_tile_row_packet(block_row, block_column, tile_row, id, row_payload)

	if packets.size() != 320 or payload_byte_count != 1088:
		push_error("F9 background-01 packet stream has an unexpected count or payload size.")
		return false
	return true


func _append_attribute_packet(block_row: int, block_column: int, block_id: int, value: int) -> void:
	var nametable := int((block_column * 4) / 32)
	var local_block_column := block_column % 8
	var address := 0x23C0 + nametable * 0x400 + block_row * 8 + local_block_column
	packets.append({
		"kind": "attribute",
		"ppu_address": address,
		"payload": PackedByteArray([value]),
		"block_row": block_row,
		"block_column": block_column,
		"block_id": block_id,
		"queue_encoded_bytes": PACKET_HEADER_BYTES + ATTRIBUTE_PACKET_PAYLOAD_BYTES,
	})
	payload_byte_count += ATTRIBUTE_PACKET_PAYLOAD_BYTES


func _append_tile_row_packet(block_row: int, block_column: int, tile_row: int,
		block_id: int, row_payload: PackedByteArray) -> void:
	var tile_x := block_column * 4
	var nametable := int(tile_x / 32)
	var local_tile_x := tile_x % 32
	var address := 0x2000 + nametable * 0x400 + (block_row * 4 + tile_row) * 32 + local_tile_x
	packets.append({
		"kind": "tile_row",
		"ppu_address": address,
		"payload": row_payload,
		"block_row": block_row,
		"block_column": block_column,
		"block_id": block_id,
		"tile_row": tile_row,
		"queue_encoded_bytes": PACKET_HEADER_BYTES + ROW_PACKET_PAYLOAD_BYTES,
	})
	payload_byte_count += row_payload.size()


func _load_block_records(raw_records: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw_records is Array:
		push_error("F9 background-01 block metadata is missing.")
		return result
	for raw_record in raw_records:
		if not raw_record is Dictionary:
			push_error("F9 background-01 has a malformed block descriptor.")
			return {}
		var descriptor: Dictionary = raw_record
		var block_id := _parse_hex_word(str(descriptor.get("id", "")))
		var source_path := "res://" + str(descriptor.get("source_bin", ""))
		if block_id < 0 or not FileAccess.file_exists(source_path):
			push_error("F9 background-01 block source is missing or has an invalid ID.")
			return {}
		var block_bytes := FileAccess.get_file_as_bytes(source_path)
		var expected_bytes := _parse_hex_bytes(str(descriptor.get("raw_hex", "")))
		if block_bytes.size() != 17 or block_bytes != expected_bytes:
			push_error("F9 background-01 block $%02X does not match preserved ROM bytes." % block_id)
			return {}
		result[block_id] = block_bytes
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
	return parsed if parsed >= 0 and parsed <= 0xFF else -1


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing F9 background-01 ROM metadata: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid F9 background-01 ROM metadata: %s" % path)
		return {}
	return parsed
