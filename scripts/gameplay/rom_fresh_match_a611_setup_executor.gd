class_name RomFreshMatchA611SetupExecutor
extends RefCounted
## Executes the verified zero-experience A611 branch and its A583 caller return.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/first_match_player_state/"
const MENU_DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const A503_BODY_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/bank01_prematch_setup_body_A4EB_A610.bin"
const A503_BODY_SHA256 := "1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587"
const A583_CALLER_SHA256 := "2933f0764b9660a2c9987cb531d3c78d3ba6359bc20cdec9ad1528f865e043e2"
const A611_SHA256 := "46e66749b1b1335162245f59c65ccf68189d8e4fcfa55e67c0b2d9493181ed14"
const LEVEL_HELPERS_SHA256 := "9305de9d5c70c8fc48fea82f89c68cbf2a55edddc47cdf402f0d4d1604c57317"
const THRESHOLDS_SHA256 := "26a7e191432e7174737ec3ac353710e2aad6d9c60241745b06cde7754540c67c"
const C50C_VECTOR_SHA256 := "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44"
const CD7C_RESOLVER_SHA256 := "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24"
const HOME_ROSTER_SHA256 := "dcb5f0103eaecbc9785e947085b02cd6b56f7d31e6671a699d82b22d80a3b123"
const RECORD_POINTERS_SHA256 := "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"

const RESOURCE_SPECS := {
	"bank01_level_update_A611_A63C.bin": {"size": 0x2B, "sha256": A611_SHA256,
		"start": "0xA611", "end": "0xA63C", "offset": "0x002621"},
	"bank01_level_helpers_B013_B03A.bin": {"size": 0x27, "sha256": LEVEL_HELPERS_SHA256,
		"start": "0xB013", "end": "0xB03A", "offset": "0x003023"},
	"fixed_record_pointer_vector_C50C_C50F.bin": {"size": 0x03, "sha256": C50C_VECTOR_SHA256,
		"start": "0xC50C", "end": "0xC50F", "offset": "0x03C51C"},
	"fixed_record_pointer_resolver_CD7C_CD89.bin": {"size": 0x0D, "sha256": CD7C_RESOLVER_SHA256,
		"start": "0xCD7C", "end": "0xCD89", "offset": "0x03CD8C"},
}

var error_message := ""
var _configured := false
var _a611 := PackedByteArray()
var _level_helpers := PackedByteArray()
var _thresholds := PackedByteArray()
var _c50c_vector := PackedByteArray()
var _cd7c_resolver := PackedByteArray()
var _home_roster := PackedByteArray()
var _record_pointers := PackedByteArray()
var _a583_caller := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_path := RESOURCE_ROOT + "manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return _fail("The first-match player-state manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		return _fail("The first-match player-state manifest is malformed.")
	var manifest: Dictionary = parsed
	var source_rom: Variant = manifest.get("source_rom", {})
	if String(manifest.get("schema", "")) != "ct2-first-match-player-state-rom-resources-v1" \
			or not source_rom is Dictionary \
			or String(source_rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The player-state manifest targets a different ROM revision.")
	var code_resources: Variant = manifest.get("source_code_resources", {})
	if not code_resources is Dictionary:
		return _fail("The manifest omits the A611 source-code resources.")
	var loaded_code: Dictionary = {}
	for file_name: String in RESOURCE_SPECS:
		var spec: Dictionary = RESOURCE_SPECS[file_name]
		var manifest_row: Variant = code_resources.get(file_name, {})
		if not manifest_row is Dictionary \
				or String(manifest_row.get("cpu_start", "")) != String(spec["start"]) \
				or String(manifest_row.get("cpu_end_exclusive", "")) != String(spec["end"]) \
				or String(manifest_row.get("file_offset", "")) != String(spec["offset"]) \
				or int(manifest_row.get("size_bytes", -1)) != int(spec["size"]) \
				or String(manifest_row.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Manifest provenance differs for %s." % file_name)
		var bytes := _read_verified(RESOURCE_ROOT + file_name, int(spec["size"]), String(spec["sha256"]))
		if bytes.is_empty():
			return false
		loaded_code[file_name] = bytes
	_a611 = loaded_code["bank01_level_update_A611_A63C.bin"]
	_level_helpers = loaded_code["bank01_level_helpers_B013_B03A.bin"]
	_c50c_vector = loaded_code["fixed_record_pointer_vector_C50C_C50F.bin"]
	_cd7c_resolver = loaded_code["fixed_record_pointer_resolver_CD7C_CD89.bin"]
	if _c50c_vector != PackedByteArray([0x4C, 0x7C, 0xCD]) \
			or _cd7c_resolver != PackedByteArray([0x0A, 0xA8, 0xB9, 0x89, 0xCD,
				0x85, 0x34, 0xB9, 0x8A, 0xCD, 0x85, 0x35, 0x60]):
		return _fail("The verified record-pointer helpers no longer match the decoded ROM routine.")
	var resource_manifest: Variant = manifest.get("resources", {})
	if not resource_manifest is Dictionary:
		return _fail("The player-state manifest omits its ROM data resources.")
	var threshold_row: Variant = resource_manifest.get("level_thresholds_BA90_BB10.bin", {})
	if not threshold_row is Dictionary \
			or int(threshold_row.get("size_bytes", -1)) != 0x80 \
			or String(threshold_row.get("sha256", "")) != THRESHOLDS_SHA256:
		return _fail("The experience-threshold manifest entry is invalid.")
	_thresholds = _read_verified(RESOURCE_ROOT + "level_thresholds_BA90_BB10.bin", 0x80, THRESHOLDS_SHA256)
	if _thresholds.is_empty():
		return false
	_home_roster = _read_verified(RESOURCE_ROOT + "match_00_home_roster.bin", 12, HOME_ROSTER_SHA256)
	if _home_roster.is_empty():
		return false
	_record_pointers = _read_verified(MENU_DATA_ROOT + "player_record_pointer_table_22.bin", 44,
		RECORD_POINTERS_SHA256)
	if _record_pointers.is_empty():
		return false
	var caller_body := _read_verified(A503_BODY_PATH, 0x126, A503_BODY_SHA256)
	if caller_body.is_empty():
		return false
	_a583_caller = caller_body.slice(0x98, 0x126)
	if _a583_caller.size() != 0x8E or _sha256(_a583_caller) != A583_CALLER_SHA256:
		return _fail("The preserved A583 caller tail is not byte-identical to this ROM.")
	if _home_roster.size() != 12 or _home_roster[11] != 0:
		return _fail("The match-00 home roster has an unexpected slot count or terminator.")
	if _read_u16(_thresholds, 0) != 0 or _read_u16(_thresholds, 2) != 0x0060:
		return _fail("The zero-experience level boundary differs from the source table.")
	_configured = true
	return true


## Supports the recorded fresh match-00 branch only: reset experience and levels are zero.
func execute_from_a58b(source_ram: RomSourceRamImage, cpu_input: Dictionary,
		source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if source_ram == null:
		return _refused("A provenance-carrying source RAM image is required.")
	if int(cpu_input.get("pc", -1)) != 0xA58B \
			or int(cpu_input.get("a", -1)) != 0x0B \
			or int(cpu_input.get("x", -1)) != 0 \
			or int(cpu_input.get("y", -1)) != 0 \
			or int(cpu_input.get("sp", -1)) != 0x26:
		return _refused("The caller is not at the verified fresh-start `$A58B` register boundary.")
	var local_values: Dictionary = {}
	for address in [0x0026, 0x00E4, 0x00EC, 0x00ED, 0x0454, 0x0455]:
		var value := _read_known_byte(source_ram, local_values, address)
		if not bool(value.get("known", false)) or int(value.get("value", -1)) != 0:
			return _refused("Fresh-start `$A611` source byte `$%04X` is not known zero." % address)
	for slot in 11:
		var record_address := _record_address(slot)
		var record_level := _read_known_byte(source_ram, local_values, record_address + 3)
		if not bool(record_level.get("known", false)) or int(record_level.get("value", -1)) != 0:
			return _refused("Player slot %d does not have a source-proven reset level of zero." % slot)
		var player_id := _read_known_byte(source_ram, local_values, record_address)
		if not bool(player_id.get("known", false)) \
				or int(player_id.get("value", -1)) != int(_home_roster[slot]):
			return _refused("Player slot %d does not match the ROM match-00 roster." % slot)
		var list_byte := _read_known_byte(source_ram, local_values, 0x0656 + slot)
		if not bool(list_byte.get("known", false)) or int(list_byte.get("value", -1)) != 0:
			return _refused("The fresh-start level-up list is not known empty at slot %d." % slot)
	var experience_slot_zero_low := _read_known_byte(source_ram, local_values, 0x0454)
	var experience_slot_zero_high := _read_known_byte(source_ram, local_values, 0x0455)
	if int(experience_slot_zero_low.get("value", -1)) != 0 \
			or int(experience_slot_zero_high.get("value", -1)) != 0:
		return _refused("The zero-level helper state at `$0454/$0455` is not zero.")

	var writes: Array[Dictionary] = []
	_append_write(writes, local_values, 0xA611, 0x00EB, 0x0B)
	var remaining := 0x0B
	for slot in 11:
		var ed := _read_known_byte(source_ram, local_values, 0x00ED)
		if not bool(ed.get("known", false)) or int(ed.get("value", -1)) != slot:
			return _refused("The source loop index diverged before home slot %d." % slot)
		var pointer_low := int(_record_pointers[slot * 2])
		var pointer_high := int(_record_pointers[slot * 2 + 1])
		var record_address := pointer_low | (pointer_high << 8)
		if record_address != _record_address(slot):
			return _refused("ROM `$CD7C` pointer entry %d differs from its slot record." % slot)
		_append_write(writes, local_values, 0xCD81, 0x0034, pointer_low)
		_append_write(writes, local_values, 0xCD86, 0x0035, pointer_high)
		# `$B023` resolves zero experience through `$BA90`; `$B013/$B02E` then
		# map level zero through the source-owned `$0454/$0455` table pair.
		_append_write(writes, local_values, 0xB023, 0x00E6, 0x00)
		_append_write(writes, local_values, 0xB025, 0x00E7, 0x00)
		var experience_level := _resolve_zero_experience_level()
		if experience_level != 0:
			return _refused("The source level helpers did not resolve fresh experience to level zero.")
		var current_level := _read_known_byte(source_ram, local_values, record_address + 3)
		if not bool(current_level.get("known", false)) or int(current_level.get("value", -1)) != experience_level:
			return _refused("The fresh-start level differs from the ROM `$A611` calculation.")
		remaining -= 1
		_append_write(writes, local_values, 0xA635, 0x00ED, slot + 1)
		_append_write(writes, local_values, 0xA637, 0x00EB, remaining)

	var match_index := _read_known_byte(source_ram, local_values, 0x0026)
	var prior_level_counter := _read_known_byte(source_ram, local_values, 0x00E4)
	var changed_count := _read_known_byte(source_ram, local_values, 0x00EC)
	if int(match_index.get("value", -1)) != 0 \
			or int(prior_level_counter.get("value", -1)) != 0 \
			or int(changed_count.get("value", -1)) != 0:
		return _refused("The A583 match-00 return branches do not match the supported fresh-start route.")
	return {
		"ok": true,
		"kind": "rom_a611_fresh_match_level_update_and_a583_return",
		"status": "returned_to_811F",
		"source_rom_sha256": ROM_SHA256,
		"source_frame": source_frame,
		"source_path": [0xA58B, 0xA611, 0xC50C, 0xCD7C, 0xB013, 0xB023, 0xB02E,
			0xA58E, 0xA59D, 0xA5B1, 0xA610, 0x811F],
		"checked_home_player_slots": 11,
		"computed_level": 0,
		"changed_level_count": 0,
		"level_up_player_ids": [],
		"return_source_pc": 0x811F,
		"cpu_output_contract": {"pc": 0x811F, "a": 0x00, "x": 0x00,
			"y": 0x03, "sp": 0x28, "flags": "only source-derived branch path asserted"},
		"ram_writes": writes,
		"source_effects": {
			"$EB": 0x00, "$EC": 0x00, "$ED": 0x0B,
			"$0656-$0660": "unchanged zero; no player level changed",
			"player_record_level_bytes": "unchanged zero for all eleven home slots",
		},
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
	}


func _resolve_zero_experience_level() -> int:
	# Source table begins at 0x0000 and its next threshold is 0x0060.
	# The source B023 descending scan therefore resolves the fresh 0x0000 input to level 0.
	if _read_u16(_thresholds, 0) == 0 and _read_u16(_thresholds, 2) == 0x0060:
		return 0
	return -1


func _record_address(slot: int) -> int:
	return int(_record_pointers[slot * 2]) | (int(_record_pointers[slot * 2 + 1]) << 8)


func _read_known_byte(source_ram: RomSourceRamImage, local_values: Dictionary,
		address: int) -> Dictionary:
	if local_values.has(address):
		return {"known": true, "value": int(local_values[address])}
	return source_ram.get_byte(address)


func _append_write(writes: Array[Dictionary], local_values: Dictionary,
		source_pc: int, address: int, value: int) -> void:
	writes.append({"source_pc": source_pc, "address": address, "value": value & 0xFF})
	local_values[address] = value & 0xFF


func _read_verified(path: String, expected_size: int, expected_sha256: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		_fail("Source asset is missing: %s" % path)
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() != expected_size or _sha256(bytes) != expected_sha256:
		_fail("ROM-derived source asset failed its size/hash check: %s" % path)
		return PackedByteArray()
	return bytes


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	if offset < 0 or offset + 1 >= bytes.size():
		return -1
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_rejected", "error": message,
		"source_rom_sha256": ROM_SHA256, "trace_state_used": false,
		"emulator_data_used": false}


func _fail(message: String) -> bool:
	error_message = message
	return false
