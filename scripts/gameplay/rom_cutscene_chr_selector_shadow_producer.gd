extends RefCounted
class_name RomCutsceneChrSelectorShadowProducer
## Replays the source-selected `$F9 $5E` CHR pair into the ROM's NMI shadow bytes.
## This is a bounded frame-level source receipt, not an NMI timing model.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/cutscene_nmi_chr_shadow/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const BACKGROUND_ID := 0x5E
const RECORD_CPU_ADDRESS := 0xAE37
const RECORD_FILE_OFFSET := 0x00EE47
const BACKGROUND_RECORD_HEX := "3c3e200206112c2d2c2c2c2c2e2f2e2f2e2f00a0"

var error_message := ""
var _configured := false
var _record := PackedByteArray()
var _reader_source := PackedByteArray()
var _copy_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_record.clear()
	_reader_source.clear()
	_copy_source.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Cutscene NMI CHR-shadow manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Cutscene NMI CHR-shadow manifest is malformed JSON.")
	var document: Dictionary = parsed
	var rom: Variant = document.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Cutscene NMI CHR-shadow source targets a different ROM revision.")
	var record_meta: Variant = document.get("record", {})
	if not record_meta is Dictionary \
			or String(record_meta.get("cpu_address", "")) != "$AE37" \
			or String(record_meta.get("file_offset", "")) != "0x00EE47" \
			or int(record_meta.get("length", -1)) != 20:
		return _fail("The `$5E` background table record mapping differs from the checked ROM entry.")
	_record = FileAccess.get_file_as_bytes(SOURCE_ROOT + String(record_meta.get("file", "")))
	if _record.hex_encode() != BACKGROUND_RECORD_HEX \
			or _sha256(_record) != String(record_meta.get("sha256", "")) \
			or String(record_meta.get("bytes", "")).to_lower().replace(" ", "") != _record.hex_encode():
		return _fail("The `$AE37` background record failed its raw-byte/hash check.")
	for span_variant in document.get("spans", []):
		if not span_variant is Dictionary:
			return _fail("Cutscene NMI CHR-shadow manifest contains a malformed code span.")
		var span: Dictionary = span_variant
		var source := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(span.get("file", "")))
		if source.size() != int(span.get("length", -1)) \
				or _sha256(source) != String(span.get("sha256", "")) \
				or String(span.get("bytes", "")).to_lower().replace(" ", "") != source.hex_encode():
			return _fail("Cutscene NMI CHR-shadow source span failed its byte/hash check.")
		match String(span.get("cpu_start", "")):
			"$8B39":
				if String(span.get("cpu_end_exclusive", "")) != "$8B46" \
						or String(span.get("file_offset", "")) != "0x000B49" \
						or source != PackedByteArray([0x86, 0x63, 0xA0, 0x00, 0xB1, 0x63,
							0x85, 0x75, 0xC8, 0xB1, 0x63, 0x85, 0x76]):
					return _fail("The `$8B39` `$63/$64` table-reader instructions changed.")
				_reader_source = source
			"$8CA7":
				if String(span.get("cpu_end_exclusive", "")) != "$8CAD" \
						or String(span.get("file_offset", "")) != "0x000CB7" \
						or source != PackedByteArray([0x85, 0x8E, 0xA5, 0x76, 0x85, 0x8F]):
					return _fail("The `$8CA7` R0/R1 shadow-copy instructions changed.")
				_copy_source = source
	if _reader_source.size() != 13 or _copy_source.size() != 6:
		return _fail("The cutscene NMI CHR-shadow source package is incomplete.")
	_configured = true
	return true


## Model the source table read at the start of the canonical `$F9 $5E` task.
## The selected CHR pair is read from the ROM record, not from a screenshot or
## emulator RAM. Other background IDs are outside this bounded receipt.
func build_background_pair_receipt(event: Dictionary, source_frame: int,
		load_receipt: Dictionary, presenter_pair: Array[int]) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if String(event.get("kind", "")) != "background_1" \
			or int(event.get("opcode", -1)) != 0xF9 \
			or int(event.get("id", -1)) != BACKGROUND_ID \
			or int(event.get("cpu_address", -1)) < 0 \
			or source_frame < 0:
		return _refused("A source-frame `$F9 $5E` background event is required.")
	var arguments: Array = event.get("arguments", [])
	if arguments.size() != 1 or int(arguments[0]) != BACKGROUND_ID \
			or not bool(load_receipt.get("ok", false)) \
			or String(load_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(load_receipt.get("background_id", -1)) != BACKGROUND_ID \
			or int(load_receipt.get("event_index", -1)) != int(event.get("event_index", -2)) \
			or not bool(load_receipt.get("replace_primary", false)):
		return _refused("The ROM background loader receipt does not belong to this primary `$F9 $5E` event.")
	var selectors: Array[int] = [int(_record[0]), int(_record[1])]
	if presenter_pair.size() != 2 \
			or int(presenter_pair[0]) != selectors[0] \
			or int(presenter_pair[1]) != selectors[1]:
		return _refused("The active ROM-derived PPU profile does not match the `$AE37` selector pair.")
	var layout_path := "res://reference/rom_extract/intro/background_5E_layout.json"
	if not FileAccess.file_exists(layout_path):
		layout_path = "res://reference/rom_extract/gameplay/backgrounds/background_5E_layout.json"
	if not FileAccess.file_exists(layout_path):
		return _refused("The ROM-derived `$5E` background layout is missing.")
	var layout_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	if not layout_variant is Dictionary:
		return _refused("The ROM-derived `$5E` background layout is malformed.")
	var layout: Dictionary = layout_variant
	var layout_selectors: Variant = layout.get("chr_2k_bank_start_ids", [])
	if String(layout.get("rom_sha256", "")) != ROM_SHA256 \
			or String(layout.get("record_cpu_address", "")) != "0xAE37" \
			or String(layout.get("record_file_offset", "")) != "0x00EE47" \
			or _parse_hex_bytes(String(layout.get("record_raw_hex", ""))) != _record \
			or not layout_selectors is Array or layout_selectors.size() != 2 \
			or int(layout_selectors[0]) != selectors[0] \
			or int(layout_selectors[1]) != selectors[1]:
		return _refused("The active `$5E` layout does not resolve to the checked `$AE37` table record.")
	var table_offset := (RECORD_FILE_OFFSET - 0x10) % 0x2000
	var table_bank := (RECORD_FILE_OFFSET - 0x10) >> 13
	if table_offset != RECORD_CPU_ADDRESS - 0xA000 \
			or table_bank != 0x07:
		return _refused("The `$AE37` table record no longer maps to PRG bank `$07`.")
	return {
		"ok": true,
		"status": "rom_f9_background_chr_pair_selected",
		"kind": "rom_cutscene_chr_selector_pair",
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": "cutscene_f9_5e_chr_pair_%d" % int(event.get("event_index", -1)),
		"event_index": int(event.get("event_index", -1)),
		"source_frame": source_frame,
		"background_id": BACKGROUND_ID,
		"record_cpu_address": RECORD_CPU_ADDRESS,
		"record_file_offset": RECORD_FILE_OFFSET,
		"record_prg_bank": 0x07,
		"selector_pair": selectors.duplicate(),
		"source_path": [0x8B39, 0x8B3D, 0x8B3F, 0x8B42, 0x8B44],
		"ram_writes": [
			{"source_pc": 0x8B3F, "post_instruction_pc": 0x8B41,
				"address": 0x0075, "value": selectors[0]},
			{"source_pc": 0x8B44, "post_instruction_pc": 0x8B46,
				"address": 0x0076, "value": selectors[1]},
		],
		"emulator_data_used": false,
		"trace_state_used": false,
		"physical_nes_timing_proven": false,
	}


## Model the same-input loader-return NMI's ROM copy into `$008E/$008F`.
## The source route supplies the completed packet-task receipt and active pair.
func build_nmi_shadow_copy_receipt(pair_receipt: Dictionary,
		task_status: Dictionary, source_frame: int,
		presenter_pair: Array[int]) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(pair_receipt.get("ok", false)) \
			or String(pair_receipt.get("status", "")) != "rom_f9_background_chr_pair_selected" \
			or int(pair_receipt.get("background_id", -1)) != BACKGROUND_ID \
			or String(pair_receipt.get("source_rom_sha256", "")) != ROM_SHA256:
		return _refused("A successful ROM-derived `$F9 $5E` selector-pair receipt is required.")
	if String(task_status.get("state", "")) != "completed" \
			or int(task_status.get("event_index", -1)) != int(pair_receipt.get("event_index", -2)) \
			or int(task_status.get("background_id", -1)) != BACKGROUND_ID \
			or int(task_status.get("return_scan_source_frame", -1)) + 1 != source_frame:
		return _refused("The NMI copy requires the same task's completion followed by the next ROM source scheduler tick.")
	var selectors: Array = pair_receipt.get("selector_pair", [])
	if selectors.size() != 2 or presenter_pair.size() != 2 \
			or int(selectors[0]) != int(presenter_pair[0]) \
			or int(selectors[1]) != int(presenter_pair[1]):
		return _refused("The active PPU selector pair changed before the source NMI copy.")
	var event_id := String(pair_receipt.get("source_event_id", ""))
	if event_id.is_empty():
		return _refused("The NMI shadow-copy receipt has no source event identity.")
	return {
		"ok": true,
		"status": "rom_nmi_copied_chr_pair_to_8e_8f",
		"kind": "rom_nmi_chr_selector_shadow_copy",
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": event_id + ":nmi_copy",
		"event_index": int(pair_receipt["event_index"]),
		"source_frame": source_frame,
		"background_id": BACKGROUND_ID,
		"source_path": [0x8CA7, 0x8CA9, 0x8CAB],
		"ram_writes": [
			{"source_pc": 0x8CA7, "post_instruction_pc": 0x8CA9,
				"address": 0x008E, "value": int(selectors[0])},
			{"source_pc": 0x8CAB, "post_instruction_pc": 0x8CAD,
				"address": 0x008F, "value": int(selectors[1])},
		],
		"emulator_data_used": false,
		"trace_state_used": false,
		"physical_nes_timing_proven": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "source_rom_sha256": ROM_SHA256,
		"background_id_scope": BACKGROUND_ID, "runtime_rom_dependency": false,
		"runtime_emulator_dependency": false, "error": error_message}


func _parse_hex_bytes(value: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in value.strip_edges().split(" ", false):
		var parsed := token.hex_to_int()
		if parsed < 0 or parsed > 0xFF:
			return PackedByteArray()
		result.append(parsed)
	return result


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
	return {"ok": false, "error": message, "emulator_data_used": false,
		"trace_state_used": false, "runtime_advances": false}
