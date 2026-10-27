extends RefCounted
class_name RomF500PaletteEffectModel
## ROM-byte-driven palette effect selected by the opening runner's F5 00.
## The model follows the bank-6 $B82A stream and bank-0 $82F0/$8326 writer;
## emulator memory and PPU captures are validation evidence only.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const METADATA_PATH := "res://reference/rom_extract/intro/palette_effect_state/runner_effect_00_metadata.json"
const POINTER_PATH := "res://reference/rom_extract/intro/palette_effect_state/effect_00_pointer.bin"
const STREAM_PATH := "res://reference/rom_extract/intro/palette_effect_state/runner_effect_00_stream.bin"
const EXPECTED_POINTER := [0x2A, 0xB8]
const EXPECTED_STREAM := [
	0x0C, 0x04, 0x3A, 0x1A, 0x1A,
	0x04, 0x1A, 0x1A, 0x3A,
	0x04, 0x1A, 0x3A, 0x1A,
	0xFE,
]

var last_error := ""
var configured := false
var active := false
var effect_id := 0
var start_source_frame := -1
var last_source_frame := -1
var current_palette_value := -1
var _records: Array[Dictionary] = []
var _record_index := 0
var _next_update_source_frame := -1
var _is_first_update := true
var _pending_stage_event: Dictionary = {}


func configure(effect_start_source_frame: int) -> bool:
	last_error = ""
	configured = false
	active = false
	if effect_start_source_frame < 0:
		return _fail("F5 00 effect start frame cannot be negative.")
	var metadata := _read_json(METADATA_PATH)
	if metadata.is_empty() or str(metadata.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("F5 00 metadata is missing or belongs to a different source ROM.")
	var selection: Dictionary = metadata.get("selection", {})
	if str(selection.get("cutscene_cpu_address", "")) != "$A03A" \
			or str(selection.get("cutscene_file_offset", "")) != "0x00604A" \
			or str(selection.get("command_bytes_hex", "")) != "F5 00" \
			or str(selection.get("effect_selector_ram", "")) != "$4C=$80" \
			or str(selection.get("pointer_ram", "")) != "$EC/$ED=$2A/$B8":
		return _fail("F5 00 selection metadata differs from the observed ROM command and pointer state.")
	var pointer := FileAccess.get_file_as_bytes(POINTER_PATH)
	if pointer != PackedByteArray(EXPECTED_POINTER):
		return _fail("Preserved bank-6 F5 00 pointer bytes differ from the supplied ROM.")
	var pointer_metadata: Dictionary = metadata.get("pointer_table", {})
	if int(pointer_metadata.get("index", -1)) != 0 \
			or str(pointer_metadata.get("cpu_address", "")) != "$B800" \
			or str(pointer_metadata.get("file_offset", "")) != "0x00D810" \
			or str(pointer_metadata.get("pointer_bytes_hex", "")).to_lower() != "2a b8" \
			or str(pointer_metadata.get("path", "")) != "reference/rom_extract/intro/palette_effect_state/effect_00_pointer.bin" \
			or str(pointer_metadata.get("resolved_cpu_address", "")) != "$B82A" \
			or str(pointer_metadata.get("resolved_file_offset", "")) != "0x00D83A" \
			or str(pointer_metadata.get("sha256", "")) != _sha256_hex(pointer):
		return _fail("F5 00 pointer metadata does not validate the bank-6 table entry.")
	var stream := FileAccess.get_file_as_bytes(STREAM_PATH)
	if stream != PackedByteArray(EXPECTED_STREAM):
		return _fail("Preserved bank-6 $B82A stream bytes differ from the supplied ROM.")
	var stream_metadata: Dictionary = metadata.get("effect_stream", {})
	if str(stream_metadata.get("cpu_address", "")) != "$B82A" \
			or str(stream_metadata.get("file_offset", "")) != "0x00D83A" \
			or int(stream_metadata.get("length_bytes", -1)) != EXPECTED_STREAM.size() \
			or str(stream_metadata.get("path", "")) != "reference/rom_extract/intro/palette_effect_state/runner_effect_00_stream.bin" \
			or str(stream_metadata.get("bytes_hex", "")).replace(" ", "").to_lower() != stream.hex_encode().to_lower() \
			or str(stream_metadata.get("sha256", "")) != _sha256_hex(stream):
		return _fail("F5 00 stream metadata does not validate the preserved ROM bytes.")
	var writer: Dictionary = metadata.get("writer", {})
	if str(writer.get("cpu_address", "")) != "$8326" \
			or str(writer.get("sta_opcode_hex", "")) != "9D 2A 06" \
			or str(writer.get("ram_addresses", "")) != "$0637-$0639" \
			or str(writer.get("ppu_addresses", "")) != "$3F0D-$3F0F":
		return _fail("F5 00 writer metadata does not match the byte-verified ROM destination.")
	if not _decode_source_stream(stream):
		return false
	start_source_frame = effect_start_source_frame
	last_source_frame = effect_start_source_frame - 1
	current_palette_value = -1
	_record_index = 0
	_next_update_source_frame = effect_start_source_frame
	_is_first_update = true
	_pending_stage_event.clear()
	active = true
	configured = true
	return true


func advance_to_source_frame(source_frame: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not configured or not active or source_frame < start_source_frame \
			or source_frame <= last_source_frame:
		return events
	if not _pending_stage_event.is_empty():
		last_source_frame = source_frame
		return events
	if _next_update_source_frame <= source_frame:
		var event_frame := _next_update_source_frame
		var record: Dictionary = _records[_record_index]
		var payload: PackedByteArray = record["payload"]
		var writes: Array[Dictionary] = []
		for payload_index in payload.size():
			var value := int(payload[payload_index])
			if value == 0:
				continue
			var palette_offset := 0x0C + payload_index + 1
			writes.append({"palette_index": palette_offset, "value": value})
		if not writes.is_empty():
			current_palette_value = int(writes[writes.size() - 1]["value"])
		_pending_stage_event = {
			"kind": "palette_byte_stage",
			"source_frame": event_frame,
			"palette_offset_base": 0x0C,
			"delay_wait_count": int(record["delay"]),
			"writes": writes,
			"commit_source_frame": event_frame + (2 if _is_first_update else 1),
			"first_update_phase_anchor": _is_first_update,
		}
		events.append(_pending_stage_event.duplicate(true))
	last_source_frame = source_frame
	return events


func complete_palette_packet_stage(staged_source_frame: int) -> bool:
	if not active or _pending_stage_event.is_empty():
		return false
	var delay := int(_pending_stage_event.get("delay_wait_count", 0))
	if delay <= 0:
		return _fail("F5 00 stream cannot continue without its decoded positive wait count.")
	_next_update_source_frame = staged_source_frame + delay
	_is_first_update = false
	_record_index += 1
	if _record_index >= _records.size():
		_record_index = 0
	_pending_stage_event.clear()
	return true


func stop() -> void:
	active = false
	_pending_stage_event.clear()


func debug_snapshot() -> Dictionary:
	return {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"effect_id": effect_id,
		"pointer_cpu_address": "$B800",
		"pointer_file_offset": "0x00D810",
		"stream_cpu_address": "$B82A",
		"stream_file_offset": "0x00D83A",
		"stream_bytes_validated": configured,
		"active": active,
		"start_source_frame": start_source_frame,
		"last_source_frame": last_source_frame,
		"next_update_source_frame": _next_update_source_frame,
		"palette_packet_stage_pending": not _pending_stage_event.is_empty(),
		"pending_stage_event": _pending_stage_event.duplicate(true),
		"current_palette_value": current_palette_value,
		"palette_base_offset": 0x0C,
		"decoded_records": _records.size(),
		"delay_units": "four cooperative scheduler releases decoded from each bank-6 stream record",
		"writer": "$8326 STA $062A,X; live write callback at $8329 confirms $0637-$0639",
	}


func _decode_source_stream(stream: PackedByteArray) -> bool:
	_records.clear()
	if stream.size() < 6 or stream[0] != 0x0C or stream[stream.size() - 1] != 0xFE:
		return _fail("F5 00 stream has an unsupported palette base or loop marker.")
	var cursor := 1
	while cursor < stream.size():
		var control := int(stream[cursor])
		if control == 0xFE:
			if cursor != stream.size() - 1 or _records.size() != 3:
				return _fail("F5 00 FE loop does not close its three source records.")
			return true
		if control == 0xFF or cursor + 3 >= stream.size():
			return _fail("F5 00 stream contains a truncated or terminating record.")
		_records.append({
			"delay": control,
			"payload": PackedByteArray([stream[cursor + 1], stream[cursor + 2], stream[cursor + 3]]),
		})
		cursor += 4
	return _fail("F5 00 stream has no FE loop marker.")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false
