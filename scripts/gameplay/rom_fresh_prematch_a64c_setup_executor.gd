extends RefCounted
class_name RomFreshPrematchA64cSetupExecutor
## Verifies the bank-$01 pre-match entry and resolves its match-zero advice scene.
## Shared PPU/OAM effects and the cutscene VM are separate runtime consumers.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/meeting_menu/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const CONTROLLER_FILE := "bank1_meeting_menu_controller.bin"
const CONTROLLER_SHA256 := "c6d8c67c6ad487c11946a136fd6955f7aacd5630d77609db8a7a942b49e66482"
const ADVICE_TABLE_FILE := "bank1_option_advice_match_table.bin"
const ADVICE_TABLE_SHA256 := "b20ddf440e2403afc7f4172a27dc48630bb8dc774f7301065959546fc49d11c4"
const CONTROLLER_PREFIX_HEX := "20a098207f9ba626bd93b320648420a982a901202089"
const ENTRY_PC := 0xA64C
const AFTER_CUTSCENE_ID_PC := 0xA662
const ADVICE_SCENE_BASE_ID := 0x44
const MATCH_INDEX_ADDRESS := 0x0026

var error_message := ""
var _controller := PackedByteArray()
var _advice_offsets := PackedByteArray()
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Meeting-menu ROM manifest is missing or malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Meeting-menu source manifest targets another ROM revision.")
	var entries: Dictionary = {}
	for entry_variant in manifest.get("files", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries[String(entry.get("file", ""))] = entry
	if not _load_span(entries, CONTROLLER_FILE, CONTROLLER_SHA256, 134):
		return false
	if not _load_span(entries, ADVICE_TABLE_FILE, ADVICE_TABLE_SHA256, 34):
		return false
	if _controller.slice(0, 22).hex_encode() != CONTROLLER_PREFIX_HEX:
		return _fail("ROM `$A64C-$A661` caller bytes differ from the audited clear/advice-scene/wait prefix.")
	_configured = true
	return true


## Resolve `$A64C` through its first advice-scene wait boundary. This verifies
## source control flow; the caller separately applies the actual PPU/OAM helper
## writes and runs the existing ROM-backed cutscene VM.
func plan_initial_advice_scene(source_ram: RomSourceRamImage,
		selected_prg_bank: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if source_ram == null or selected_prg_bank != 0x01:
		return _refused("`$A64C` requires source RAM and PRG bank `$01` mapped at `$A000`.")
	var match_index := source_ram.get_byte(MATCH_INDEX_ADDRESS)
	if not bool(match_index.get("known", false)):
		return _refused("Match index `$0026` is unknown at the `$A64C` entry.")
	var index := int(match_index.get("value", -1))
	if index < 0 or index >= _advice_offsets.size():
		return _refused("Match index `$%02X` is outside the ROM advice table." % index)
	var scene_id := int(_advice_offsets[index])
	if scene_id != ADVICE_SCENE_BASE_ID:
		return _refused("The current implementation only supports the fresh match-zero `$44` advice scene.")
	return {
		"ok": true,
		"status": "ready_to_run_advice_scene_44",
		"source_rom_sha256": ROM_SHA256,
		"entry_pc": ENTRY_PC,
		"match_index_address": MATCH_INDEX_ADDRESS,
		"match_index": index,
		"advice_scene_id": scene_id,
		"cutscene_id": scene_id,
		"helper_calls": [
			{"source_pc": 0xA64C, "target_pc": 0x98A0, "helper_id": "prematch_ppu_clear"},
			{"source_pc": 0xA64F, "target_pc": 0x9B7F, "helper_id": "prematch_oam_clear"},
			{"source_pc": 0xA657, "target_pc": 0x8464, "helper_id": "dispatch_advice_scene"},
			{"source_pc": 0xA65A, "target_pc": 0x82A9, "helper_id": "wait_for_scene_return"},
			{"source_pc": 0xA65F, "target_pc": 0x8920, "helper_id": "post_scene_setup"},
		],
		"source_path": [0xA64C, 0x98A0, 0xA64F, 0x9B7F, 0xA652, 0xA654,
			0xA657, 0x8464, 0xA65A, 0x82A9],
		"wait_boundary_pc": 0x82A9,
		"next_controller_pc_after_scene": AFTER_CUTSCENE_ID_PC,
		"controller_prefix_sha256": CONTROLLER_SHA256,
		"advice_table_sha256": ADVICE_TABLE_SHA256,
		"trace_state_used": false,
		"emulator_data_used": false,
		"executes_6502": false,
		"physical_nes_timing_proven": false,
	}


func _load_span(entries: Dictionary, file_name: String, expected_hash: String,
		expected_length: int) -> bool:
	if not entries.has(file_name):
		return _fail("Meeting-menu manifest omits `%s`." % file_name)
	var entry: Dictionary = entries[file_name]
	var source := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
	if int(entry.get("length_bytes", -1)) != expected_length \
			or String(entry.get("sha256", "")) != expected_hash \
			or source.size() != expected_length or _sha256(source) != expected_hash:
		return _fail("ROM source span failed its manifest, size, or SHA-256 check: %s." % file_name)
	if file_name == CONTROLLER_FILE:
		_controller = source
	else:
		_advice_offsets = source
	return true


func _refused(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_state_rejected", "error": reason}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
