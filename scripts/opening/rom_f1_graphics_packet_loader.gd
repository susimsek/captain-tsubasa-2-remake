extends RefCounted
class_name RomF1GraphicsPacketLoader

## Reads and validates the extracted F1 01 packet stream without opening the ROM.

const PACKET_RESOURCE_PATH := "res://assets/opening/rom_logic/f1_01_graphics.bin"
const MANIFEST_RESOURCE_PATH := "res://assets/opening/rom_logic/f1_01_graphics.json"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_STREAM_SHA256 := "6f2b7603e57aec97c109eef96eeab562963e7f097a1a000da99c3eda89532d92"
const EXPECTED_STREAM_LENGTH := 78
const EXPECTED_RECORD_COUNT := 4
const SOURCE_PRG_BANK := 6
const SOURCE_CPU_ADDRESS := "$BB9A"
const SOURCE_FILE_OFFSET := 0x00DBAA
const SOURCE_FILE_END_EXCLUSIVE := 0x00DBF8

var packets: Array[Dictionary] = []
var last_error: String = ""
var stream_sha256: String = ""
var source_file_offset: int = SOURCE_FILE_OFFSET


func build_packets() -> bool:
	packets.clear()
	last_error = ""
	stream_sha256 = ""
	source_file_offset = SOURCE_FILE_OFFSET

	if not FileAccess.file_exists(PACKET_RESOURCE_PATH):
		return _fail("Missing F1 01 packet resource: " + PACKET_RESOURCE_PATH)
	if not FileAccess.file_exists(MANIFEST_RESOURCE_PATH):
		return _fail("Missing F1 01 packet manifest: " + MANIFEST_RESOURCE_PATH)

	var stream := FileAccess.get_file_as_bytes(PACKET_RESOURCE_PATH)
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_RESOURCE_PATH)
	var parsed_manifest: Variant = JSON.parse_string(manifest_text)
	if typeof(parsed_manifest) != TYPE_DICTIONARY:
		return _fail("F1 01 packet manifest is not a JSON object")
	var manifest: Dictionary = parsed_manifest
	if not _validate_manifest_source(manifest):
		return false
	if stream.size() != EXPECTED_STREAM_LENGTH:
		return _fail("F1 01 packet stream length mismatch: %d" % stream.size())

	stream_sha256 = _sha256(stream)
	var resource_meta: Dictionary = manifest["resource"]
	if stream_sha256 != EXPECTED_STREAM_SHA256:
		return _fail("F1 01 packet stream SHA-256 does not match the verified ROM bytes")
	if str(resource_meta.get("sha256", "")) != stream_sha256:
		return _fail("F1 01 packet stream hash does not match its manifest")
	if int(resource_meta.get("byte_length", -1)) != stream.size():
		return _fail("F1 01 packet stream length does not match its manifest")
	if str(resource_meta.get("file", "")) != "f1_01_graphics.bin":
		return _fail("F1 01 manifest names an unexpected resource file")

	var format_meta: Dictionary = manifest["format"]
	var manifest_records_value: Variant = format_meta.get("records", null)
	if typeof(manifest_records_value) != TYPE_ARRAY:
		return _fail("F1 01 manifest does not contain packet records")
	var manifest_records: Array = manifest_records_value
	if int(format_meta.get("record_count", -1)) != EXPECTED_RECORD_COUNT:
		return _fail("F1 01 manifest record count is not the verified count")
	if manifest_records.size() != EXPECTED_RECORD_COUNT:
		return _fail("F1 01 manifest record metadata count is incorrect")

	var position := 0
	var record_index := 0
	var found_final := false
	while position < stream.size():
		if position + 3 > stream.size():
			return _fail("Truncated F1 01 packet header at stream byte %d" % position)

		var header := int(stream[position])
		var payload_length := header & 0x3F
		var record_end := position + 3 + payload_length
		if record_end > stream.size():
			return _fail("Truncated F1 01 packet payload at stream byte %d" % position)
		if record_index >= manifest_records.size():
			return _fail("F1 01 packet stream has more records than its manifest")

		var metadata_value: Variant = manifest_records[record_index]
		if typeof(metadata_value) != TYPE_DICTIONARY:
			return _fail("F1 01 record metadata %d is not an object" % record_index)
		var metadata: Dictionary = metadata_value
		var record_bytes := stream.slice(position, record_end)
		var payload := stream.slice(position + 3, record_end)
		var raw_address := int(stream[position + 1]) | (int(stream[position + 2]) << 8)
		var ppu_address := raw_address & 0x3FFF
		var increment := 32 if (header & 0x80) != 0 else 1
		var final_record := (header & 0x40) != 0
		var packet_file_offset := SOURCE_FILE_OFFSET + position

		if int(metadata.get("record_index", -1)) != record_index:
			return _fail("F1 01 record index disagrees with its manifest")
		if _hex_to_int(metadata.get("source_file_offset", "")) != packet_file_offset:
			return _fail("F1 01 record source offset disagrees with its manifest")
		if _hex_to_int(metadata.get("header", "")) != header:
			return _fail("F1 01 record header disagrees with its manifest")
		if int(metadata.get("payload_length", -1)) != payload_length:
			return _fail("F1 01 record payload length disagrees with its manifest")
		if _hex_to_int(metadata.get("ppu_address", "")) != ppu_address:
			return _fail("F1 01 record PPU address disagrees with its manifest")
		if int(metadata.get("increment", -1)) != increment:
			return _fail("F1 01 record increment disagrees with its manifest")
		if bool(metadata.get("final", false)) != final_record:
			return _fail("F1 01 record final marker disagrees with its manifest")
		if str(metadata.get("record_sha256", "")) != _sha256(record_bytes):
			return _fail("F1 01 record hash disagrees with its manifest")
		if str(metadata.get("payload_sha256", "")) != _sha256(payload):
			return _fail("F1 01 record payload hash disagrees with its manifest")

		packets.append({
			"ppu_address": ppu_address,
			"payload": payload,
			"increment": increment,
			"record_index": record_index,
			"source_file_offset": packet_file_offset,
			"header": header,
			"final": final_record,
			"record_bytes": record_bytes,
			"queue_encoded_bytes": 3 + payload.size(),
		})
		position = record_end
		record_index += 1
		if final_record:
			found_final = true
			break

	if not found_final:
		return _fail("F1 01 packet stream has no final record marker")
	if position != stream.size():
		return _fail("Unexpected trailing bytes after the F1 01 final record")
	if record_index != EXPECTED_RECORD_COUNT:
		return _fail("F1 01 packet record count does not match the verified count")
	return true


func _validate_manifest_source(manifest: Dictionary) -> bool:
	if int(manifest.get("schema", -1)) != 1:
		return _fail("Unsupported F1 01 manifest schema")
	var rom_value: Variant = manifest.get("rom", null)
	var source_value: Variant = manifest.get("source", null)
	var resource_value: Variant = manifest.get("resource", null)
	var format_value: Variant = manifest.get("format", null)
	if typeof(rom_value) != TYPE_DICTIONARY or typeof(source_value) != TYPE_DICTIONARY:
		return _fail("F1 01 manifest is missing ROM/source metadata")
	if typeof(resource_value) != TYPE_DICTIONARY or typeof(format_value) != TYPE_DICTIONARY:
		return _fail("F1 01 manifest is missing resource/format metadata")
	var rom_meta: Dictionary = rom_value
	var source_meta: Dictionary = source_value
	if str(rom_meta.get("sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("F1 01 manifest ROM SHA-256 is not the verified source ROM")
	if int(source_meta.get("prg_bank", -1)) != SOURCE_PRG_BANK:
		return _fail("F1 01 manifest PRG bank is incorrect")
	if str(source_meta.get("cpu_address", "")) != SOURCE_CPU_ADDRESS:
		return _fail("F1 01 manifest CPU address is incorrect")
	if _hex_to_int(source_meta.get("file_offset_start", "")) != SOURCE_FILE_OFFSET:
		return _fail("F1 01 manifest source start offset is incorrect")
	if _hex_to_int(source_meta.get("file_offset_end_exclusive", "")) != SOURCE_FILE_END_EXCLUSIVE:
		return _fail("F1 01 manifest source end offset is incorrect")
	if int(source_meta.get("ines_header_bytes", -1)) != 16:
		return _fail("F1 01 manifest iNES header size is incorrect")
	return true


func _hex_to_int(value: Variant) -> int:
	var text_value := str(value)
	if not text_value.begins_with("0x"):
		return -1
	return text_value.substr(2).hex_to_int()


func _sha256(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(data) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	packets.clear()
	last_error = message
	return false
