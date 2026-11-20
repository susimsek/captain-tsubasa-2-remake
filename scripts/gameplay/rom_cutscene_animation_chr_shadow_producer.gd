extends RefCounted
class_name RomCutsceneAnimationChrShadowProducer
## Replays ROM sprite-frame CHR header writes for the source `$FB $01 $51` event.
## The receipt is source-frame aligned and does not emulate physical NMI timing.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/cutscene_animation_chr_shadow/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const WRITER_HEX := "a000b1e60980859ec8b1e6859fa002b1e685a0c8b1e685a1"
const FRAME_HEADER_HEX := "70716667"
const ANIMATION_51_HEX := "3ff130469364ff"

var error_message := ""
var _configured := false
var _animation_entry := PackedByteArray()
var _frame_header := PackedByteArray()
var _writer_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_animation_entry.clear()
	_frame_header.clear()
	_writer_source.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Animation CHR-shadow source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Animation CHR-shadow source manifest is malformed JSON.")
	var document: Dictionary = parsed
	var rom: Variant = document.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Animation CHR-shadow source targets a different ROM revision.")
	var event_meta: Variant = document.get("cutscene_event", {})
	if not event_meta is Dictionary \
			or int(event_meta.get("cutscene_id", -1)) != 1 \
			or int(event_meta.get("event_index", -1)) != 51 \
			or String(event_meta.get("cpu_address", "")) != "$A388" \
			or String(event_meta.get("file_offset", "")) != "0x006398" \
			or String(event_meta.get("arguments_hex", "")) != "01 51":
		return _fail("The checked cutscene `$FB $01 $51` event mapping changed.")
	var animation_meta: Variant = document.get("animation_entry", {})
	if not animation_meta is Dictionary \
			or String(animation_meta.get("resource_path", "")) != "res://reference/rom_extract/gameplay/animations/kickoff/animation_51.bin" \
			or String(animation_meta.get("prg_bank", "")) != "$09" \
			or String(animation_meta.get("cpu_address", "")) != "$A54E" \
			or String(animation_meta.get("file_offset", "")) != "0x01255E" \
			or String(animation_meta.get("resolved_frame_cpu_address", "")) != "$B364":
		return _fail("Animation `$51` does not map to the checked ROM sprite-frame entry.")
	_animation_entry = FileAccess.get_file_as_bytes(String(animation_meta.get("resource_path", "")))
	if _animation_entry.hex_encode() != ANIMATION_51_HEX \
			or _animation_entry.size() != int(animation_meta.get("length", -1)) \
			or _sha256(_animation_entry) != String(animation_meta.get("sha256", "")) \
			or String(animation_meta.get("bytes", "")).to_lower().replace(" ", "") != _animation_entry.hex_encode():
		return _fail("Animation `$51` ROM bytes failed their source/hash checks.")
	var spans: Variant = document.get("spans", [])
	if not spans is Array:
		return _fail("Animation CHR-shadow manifest has no source spans.")
	for span_variant in spans:
		if not span_variant is Dictionary:
			return _fail("Animation CHR-shadow manifest contains a malformed source span.")
		var span: Dictionary = span_variant
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(span.get("file", "")))
		if bytes.size() != int(span.get("length", -1)) \
				or _sha256(bytes) != String(span.get("sha256", "")) \
				or String(span.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Animation CHR-shadow raw span failed its byte/hash check.")
		match String(span.get("cpu_start", "")):
			"$94D8":
				if String(span.get("file_offset", "")) != "0x0014E8" \
						or span.get("length", -1) != 24 \
						or bytes.hex_encode() != WRITER_HEX:
					return _fail("The ROM `$94D8-$94F0` four-register store sequence changed.")
				_writer_source = bytes
			"$B364":
				if String(span.get("file_offset", "")) != "0x013374" \
						or span.get("length", -1) != 4 \
						or bytes.hex_encode() != FRAME_HEADER_HEX:
					return _fail("The ROM `$B364` sprite-frame CHR header changed.")
				_frame_header = bytes
	if _writer_source.size() != 24 or _frame_header.size() != 4:
		return _fail("Animation CHR-shadow source package is incomplete.")
	_configured = true
	return true


## The visual route emits this decoded animation event at its source scheduler
## edge; the ROM event/animation/frame bytes determine the four shadow values.
func build_receipt(cutscene_id: int, event: Dictionary, source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	var ids: Array = event.get("animation_ids", [])
	var arguments: Array = event.get("arguments", [])
	var raw_bytes: Array = event.get("raw_bytes", [])
	var event_payload_matches := arguments.size() == 2 \
		and int(arguments[0]) == 1 and int(arguments[1]) == 0x51 \
		and ids.size() == 1 and int(ids[0]) == 0x51 \
		and raw_bytes.size() == 3 and int(raw_bytes[0]) == 0xFB \
		and int(raw_bytes[1]) == 1 and int(raw_bytes[2]) == 0x51
	if cutscene_id != 1 or String(event.get("kind", "")) != "animations" \
			or int(event.get("opcode", -1)) != 0xFB \
			or int(event.get("event_index", -1)) != 51 \
			or int(event.get("cpu_address", -1)) != 0xA388 \
			or not event_payload_matches or source_frame < 0:
		return _refused("Expected cutscene `$01` event `$A388` (`$FB $01 $51`); received "
			+ JSON.stringify({"cutscene_id": cutscene_id, "kind": event.get("kind", ""),
				"opcode": event.get("opcode", -1), "event_index": event.get("event_index", -1),
				"cpu_address": event.get("cpu_address", -1), "arguments": arguments,
				"animation_ids": ids, "raw_bytes": raw_bytes, "source_frame": source_frame}) + ".")
	var values: Array[int] = [int(_frame_header[0]) | 0x80,
		int(_frame_header[1]), int(_frame_header[2]), int(_frame_header[3])]
	return {
		"ok": true,
		"status": "rom_animation_chr_selectors_written_to_9e_a1",
		"kind": "rom_cutscene_animation_chr_shadow",
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": "cutscene_01_animation_51_chr_shadow_%d" % source_frame,
		"cutscene_id": cutscene_id,
		"event_index": int(event["event_index"]),
		"source_cpu_address": int(event["cpu_address"]),
		"source_frame": source_frame,
		"animation_id": 0x51,
		"sprite_frame_cpu_address": 0xB364,
		"frame_header": _frame_header.duplicate(),
		"selector_values": values.duplicate(),
		"source_path": [0xA388, 0xA552, 0x9248, 0x924E, 0x94D8,
			0x94DE, 0x94E3, 0x94E9, 0x94EE],
		"ram_writes": [
			{"source_pc": 0x94DE, "post_instruction_pc": 0x94E0,
				"address": 0x009E, "value": values[0]},
			{"source_pc": 0x94E3, "post_instruction_pc": 0x94E5,
				"address": 0x009F, "value": values[1]},
			{"source_pc": 0x94E9, "post_instruction_pc": 0x94EB,
				"address": 0x00A0, "value": values[2]},
			{"source_pc": 0x94EE, "post_instruction_pc": 0x94F0,
				"address": 0x00A1, "value": values[3]},
		],
		"emulator_data_used": false,
		"trace_state_used": false,
		"physical_nes_timing_proven": false,
	}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message,
		"emulator_data_used": false, "trace_state_used": false,
		"runtime_advances": false}
