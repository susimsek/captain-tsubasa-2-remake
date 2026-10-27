extends RefCounted
class_name RomBG09PaletteEffectModel
## ROM-byte-driven palette effect selected by BG09's F5 01 command.
## It models the ROM's $82F0 stream reader and its one-byte palette writer;
## captured RAM/PPU states are validation evidence only.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const METADATA_PATH := "res://reference/rom_extract/intro/palette_effect_state/bg09_effect_01_metadata.json"
const POINTER_PATH := "res://reference/rom_extract/intro/palette_effect_state/effect_01_pointer.bin"
const STREAM_PATH := "res://reference/rom_extract/intro/palette_effect_state/bg09_effect_01_stream.bin"
const EXPECTED_POINTER := [0x38, 0xB8]
const EXPECTED_STREAM := [
	0x08, 0x04, 0x30, 0x00, 0x00,
	0x04, 0x21, 0x00, 0x00,
	0x04, 0x30, 0x00, 0x00,
	0x04, 0x25, 0x00, 0x00,
	0xFE,
]

var last_error := ""
var configured := false
var active := false
var effect_id := 1
var start_source_frame := -1
var last_source_frame := -1
var current_palette_value := -1
var _base_palette_offset := -1
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
		return _fail("BG09 effect start frame cannot be negative.")
	var metadata := _read_json(METADATA_PATH)
	if metadata.is_empty() or str(metadata.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("BG09 effect metadata is missing or has a different source-ROM identity.")
	var pointer := FileAccess.get_file_as_bytes(POINTER_PATH)
	if pointer != PackedByteArray(EXPECTED_POINTER):
		return _fail("Preserved bank-6 effect pointer bytes do not match table entry 1.")
	var pointer_metadata: Dictionary = metadata.get("pointer_table", {})
	if str(pointer_metadata.get("cpu_address", "")) != "$B802" \
			or str(pointer_metadata.get("file_offset", "")) != "0x00D812" \
			or str(pointer_metadata.get("path", "")) != "reference/rom_extract/intro/palette_effect_state/effect_01_pointer.bin" \
			or str(pointer_metadata.get("pointer_bytes_hex", "")).to_lower() != "38 b8" \
			or str(pointer_metadata.get("resolved_cpu_address", "")) != "$B838" \
			or str(pointer_metadata.get("resolved_file_offset", "")) != "0x00D848" \
			or str(pointer_metadata.get("sha256", "")) != _sha256_hex(pointer):
		return _fail("BG09 effect pointer metadata does not validate the ROM table entry.")
	var stream := FileAccess.get_file_as_bytes(STREAM_PATH)
	if stream != PackedByteArray(EXPECTED_STREAM):
		return _fail("Preserved bank-6 $B838 stream bytes differ from the supplied ROM source span.")
	var stream_metadata: Dictionary = metadata.get("effect_stream", {})
	if str(stream_metadata.get("cpu_address", "")) != "$B838" \
			or str(stream_metadata.get("file_offset", "")) != "0x00D848" \
			or int(stream_metadata.get("length_bytes", -1)) != EXPECTED_STREAM.size() \
			or str(stream_metadata.get("path", "")) != "reference/rom_extract/intro/palette_effect_state/bg09_effect_01_stream.bin" \
			or str(stream_metadata.get("bytes_hex", "")).replace(" ", "").to_lower() != stream.hex_encode().to_lower() \
			or str(stream_metadata.get("sha256", "")) != _sha256_hex(stream):
		return _fail("BG09 effect stream metadata does not validate the preserved source bytes.")
	if not _decode_source_stream(stream):
		return false
	_base_palette_offset = int(stream[0])
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


## Return ROM palette-byte writes that become staged on this source frame.
## The first write is immediate at F5 dispatch. The stream's four cooperative
## waits begin only after `$9A43` accepts its packet, including a capacity retry.
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
			# The 6502 writer skips zero payloads and stores nonzero values at
			# $062A+X after incrementing X from the stream's base offset.
			if value == 0:
				continue
			var palette_offset := _base_palette_offset + payload_index + 1
			writes.append({"palette_index": palette_offset, "value": value})
		if not writes.is_empty():
			current_palette_value = int(writes[writes.size() - 1]["value"])
		var delay := int(record["delay"])
		var commit_frame := event_frame + (2 if _is_first_update else 1)
		_pending_stage_event = {
			"kind": "palette_byte_stage",
			"source_frame": event_frame,
			"palette_offset_base": _base_palette_offset,
			"delay_wait_count": delay,
			"writes": writes,
			"commit_source_frame": commit_frame,
			"first_update_phase_anchor": _is_first_update,
		}
		events.append(_pending_stage_event.duplicate(true))
	last_source_frame = source_frame
	return events


## `$82F0` does not start its four `$838A` waits until `$9A43` can reserve the
## palette packet. A full shared `$05E8` queue leaves the current byte written
## but stalls the stream cursor at its capacity retry loop.
func complete_palette_packet_stage(staged_source_frame: int) -> bool:
	if not active or _pending_stage_event.is_empty():
		return false
	var delay := int(_pending_stage_event.get("delay_wait_count", 0))
	if delay <= 0:
		return _fail("BG09 effect cannot continue without its decoded positive wait count.")
	_next_update_source_frame = staged_source_frame + delay
	_is_first_update = false
	_record_index += 1
	if _record_index >= _records.size():
		# The preserved $FE marker returns the stream cursor to its first record.
		_record_index = 0
	_pending_stage_event.clear()
	return true


func stop() -> void:
	active = false
	_pending_stage_event.clear()


func debug_snapshot() -> Dictionary:
	return {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"effect_id": 1,
		"pointer_cpu_address": "$B802",
		"pointer_file_offset": "0x00D812",
		"stream_cpu_address": "$B838",
		"stream_file_offset": "0x00D848",
		"stream_bytes_validated": configured,
		"active": active,
		"start_source_frame": start_source_frame,
		"last_source_frame": last_source_frame,
		"next_update_source_frame": _next_update_source_frame,
		"palette_packet_stage_pending": not _pending_stage_event.is_empty(),
		"pending_stage_event": _pending_stage_event.duplicate(true),
		"current_palette_value": current_palette_value,
		"palette_base_offset": _base_palette_offset,
		"decoded_records": _records.size(),
		"delay_units": "cooperative scheduler releases; captured source-frame cadence is 4 after the initial dispatch phase",
		"initial_nmi_commit_phase": "first staged byte commits at F5 source frame +2; later updates at stage +1, matched against PPU snapshots",
	}


func _decode_source_stream(stream: PackedByteArray) -> bool:
	_records.clear()
	if stream.size() < 6 or stream[0] != 0x08 or stream[stream.size() - 1] != 0xFE:
		return _fail("BG09 effect stream has an unsupported palette base or loop marker.")
	var cursor := 1
	while cursor < stream.size():
		var control := int(stream[cursor])
		if control == 0xFE:
			if cursor != stream.size() - 1 or _records.is_empty():
				return _fail("BG09 effect stream loop marker is not at the validated end of the stream.")
			if _records.size() != 4:
				return _fail("BG09 effect stream must contain four records before its FE loop marker.")
			return true
		if control == 0xFF or cursor + 3 >= stream.size():
			return _fail("BG09 effect stream contains a truncated or terminating record.")
		var payload := PackedByteArray([stream[cursor + 1], stream[cursor + 2], stream[cursor + 3]])
		_records.append({"delay": control, "payload": payload})
		cursor += 4
	return _fail("BG09 effect stream has no FE loop marker.")


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
