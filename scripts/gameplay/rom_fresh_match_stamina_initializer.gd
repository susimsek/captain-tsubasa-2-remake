extends RefCounted
class_name RomFreshMatchStaminaInitializer
## Executes the ROM-semantic fresh match-00 `$811F->$C572->$DB62` energy pass.
## This bounded model validates the ROM sources and live RAM inputs; it is not
## a general 6502 or MMC3 emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/first_match_player_state/"
const PLAYER_MENU_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const MANIFEST_PATH := RESOURCE_ROOT + "manifest.json"
const DYNAMIC_AUDIT_PATH := PLAYER_MENU_ROOT + "dynamic_player_source_audit.json"

const CODE_SPECS := {
	"fixed_match_stamina_vector_C572_C575.bin": {
		"cpu_start": "0xC572", "cpu_end_exclusive": "0xC575",
		"file_offset": "0x03C582", "size_bytes": 3,
		"sha256": "0cbb606a0a220384a7b6f7e18c761576cad7371a02db168f0c63ef73ce8a860e",
	},
	"fixed_energy_initializer_DB62_DB9E.bin": {
		"cpu_start": "0xDB62", "cpu_end_exclusive": "0xDB9E",
		"file_offset": "0x03DB72", "size_bytes": 60,
		"sha256": "430dd56ae794b1424df1b19834d68b81f7e498b7758337574bc59f2a724143c8",
	},
	"fixed_stamina_evaluator_helper_CE08_CE2A.bin": {
		"cpu_start": "0xCE08", "cpu_end_exclusive": "0xCE2A",
		"file_offset": "0x03CE18", "size_bytes": 34,
		"sha256": "a3fdef03b9da4f2e5f11a7ab79e70079600cf331bbd842c4ff695871df4395bb",
	},
	"fixed_stamina_bank_switch_CE2D_CE4A.bin": {
		"cpu_start": "0xCE2D", "cpu_end_exclusive": "0xCE4A",
		"file_offset": "0x03CE3D", "size_bytes": 29,
		"sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
	},
	"bank1c_stamina_evaluator_802D_818E.bin": {
		"cpu_start": "0x802D", "cpu_end_exclusive": "0x818E",
		"file_offset": "0x03803D", "size_bytes": 353,
		"sha256": "bfc9ff395d159963ea1e0a1d67028400eb727093d052865ad557cc3b8f65d3d2",
	},
	"fixed_record_pointer_vector_C50C_C50F.bin": {
		"cpu_start": "0xC50C", "cpu_end_exclusive": "0xC50F",
		"file_offset": "0x03C51C", "size_bytes": 3,
		"sha256": "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44",
	},
	"fixed_record_pointer_resolver_CD7C_CD89.bin": {
		"cpu_start": "0xCD7C", "cpu_end_exclusive": "0xCD89",
		"file_offset": "0x03CD8C", "size_bytes": 13,
		"sha256": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
	},
}

const DATA_SPECS := {
	"match_00_home_roster.bin": {
		"size_bytes": 12,
		"sha256": "dcb5f0103eaecbc9785e947085b02cd6b56f7d31e6671a699d82b22d80a3b123",
	},
	"stamina_profile_values_AE86_AFAE.bin": {
		"size_bytes": 296,
		"sha256": "1c87d94c9754655c7101939c784abf02a7c37f6287cbb89ed674cc40562b6cf8",
	},
	"stamina_value_words_9F0E_9FCD.bin": {
		"size_bytes": 192,
		"sha256": "9278cbdf95434a0dc120d6938b6095fc24261d735e8ce4f91c5c95400e291085",
	},
}

const MENU_DATA_SPECS := {
	"player_record_pointer_table_22.bin": {
		"size_bytes": 44,
		"sha256": "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185",
	},
	"player_stat_profile_map_00_22.bin": {
		"size_bytes": 140,
		"sha256": "a16ef4a351fe79c6465741d75e3700b1bfe84f6a28ddee5e837aba226cb4ff48",
	},
	"player_stat_profiles_00_8c.bin": {
		"size_bytes": 3384,
		"sha256": "3236a005cc380c17351cf6ebac20f3f090be2a0a67ba6d8849cd8e6bcaf95fff",
	},
}

var error_message := ""
var _configured := false
var _home_roster := PackedByteArray()
var _record_pointers := PackedByteArray()
var _profile_map := PackedByteArray()
var _player_stat_profiles := PackedByteArray()
var _stamina_profiles := PackedByteArray()
var _stamina_values := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	if not _validate_code_manifest():
		return false
	if not _load_rom_data():
		return false
	if not _validate_source_path_bytes():
		return false
	_configured = true
	return true


func execute_from_811f(source_ram: RomSourceRamImage, cpu_input: Dictionary,
		source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if source_ram == null or int(cpu_input.get("pc", -1)) != 0x811F \
			or int(cpu_input.get("a", -1)) != 0 \
			or int(cpu_input.get("x", -1)) != 0 \
			or int(cpu_input.get("y", -1)) != 3 \
			or int(cpu_input.get("sp", -1)) != 0x28:
		return _refused("The live caller does not match the verified `$811F` A611 return contract.")
	if source_frame < 0:
		return _refused("A nonnegative source-frame label is required for this route event.")

	var local_values: Dictionary = {}
	for address in [0x0026, 0x002A, 0x044D]:
		var input_value := _read_known(source_ram, local_values, address)
		if not bool(input_value.get("known", false)):
			return _refused("The `$DB62` input `$%04X` is not source-proven." % address)
		local_values[address] = int(input_value.get("value", 0))
	if int(local_values[0x0026]) != 0 or int(local_values[0x002A]) != 0 \
			or int(local_values[0x044D]) != 0:
		return _refused("Only fresh match 0, home selector 0, and reset-zero `$044D` are supported.")

	var writes: Array[Dictionary] = []
	var slots: Array[Dictionary] = []
	var source_path: Array[int] = [0x811F, 0xC572, 0xDB62]
	var last_low := 0
	for slot in range(10, -1, -1):
		var pointer_offset := slot * 2
		var record_address := int(_record_pointers[pointer_offset]) \
			| (int(_record_pointers[pointer_offset + 1]) << 8)
		if record_address != 0x0300 + slot * 0x0C:
			return _refused("ROM record pointer for home slot %d does not match the source table." % slot)
		var player_id_value := _read_known(source_ram, local_values, record_address)
		var level_value := _read_known(source_ram, local_values, record_address + 3)
		if not bool(player_id_value.get("known", false)) \
				or not bool(level_value.get("known", false)):
			return _refused("Home slot %d has an unknown source player ID or level." % slot)
		var player_id := int(player_id_value.get("value", -1))
		var level := int(level_value.get("value", -1))
		if player_id != int(_home_roster[slot]) or level != 0:
			return _refused("Home slot %d is outside the verified fresh match-00 roster/level state." % slot)
		if player_id <= 0 or player_id >= 0x23:
			return _refused("Home slot %d selects an unsupported ROM stamina profile." % slot)
		var profile_id := int(_profile_map[player_id * 4])
		if profile_id < 0 or profile_id >= 0x8D:
			return _refused("Home slot %d has an out-of-range ROM profile ID." % slot)
		# `$809A-$80D1` chooses common `$AE86` rows for selectors
		# 0/$0B/$1E/$1F. The ordinary selector-0 energy path at `$80D1-$80F6`
		# computes `$9FCE + profile_id * 24`; `$8113` reads its first byte,
		# adds the live record level, then indexes `$9F0E`.
		var use_common_profile_row := slot == 0 or slot == 0x0B \
			or slot == 0x1E or slot == 0x1F
		var curve_source_pc := 0x80B2 if use_common_profile_row else 0x80D1
		var curve_base := int(_stamina_profiles[profile_id * 8]) \
			if use_common_profile_row else int(_player_stat_profiles[profile_id * 0x18])
		var curve_index := mini(0x5F, curve_base + level)
		var value_offset := curve_index * 2
		var energy := int(_stamina_values[value_offset]) \
			| (int(_stamina_values[value_offset + 1]) << 8)
		if player_id == 0x20 and int(local_values[0x044D]) != 0:
			energy = 0

		# `$CE08->$8000->$802D->$803A->$C50C->$CD7C` resolves the record and
		# ROM profile. The evaluator returns the word in `$32/$33`; `$DB62`
		# stores that word at record offsets +1/+2.
		_append_write(writes, local_values, 0xCD81, 0x0034, record_address & 0xFF)
		_append_write(writes, local_values, 0xCD86, 0x0035, record_address >> 8)
		_append_write(writes, local_values, 0x8138, 0x0033, (energy >> 8) & 0xFF)
		_append_write(writes, local_values, 0x813A, 0x0032, energy & 0xFF)
		_append_write(writes, local_values, 0xDB90, record_address + 1, energy & 0xFF)
		_append_write(writes, local_values, 0xDB95, record_address + 2, (energy >> 8) & 0xFF)
		last_low = energy & 0xFF
		slots.append({
			"slot": slot,
			"record_address": record_address,
			"player_id": player_id,
			"profile_id": profile_id,
			"level": level,
			"curve_source_pc": curve_source_pc,
			"stamina_curve_index": curve_index,
			"maximum_energy": energy,
			"energy_write_addresses": [record_address + 1, record_address + 2],
		})
		source_path.append_array([0xDB6D, 0xDB74, 0xDB76, 0xCE08, 0xCE2D,
			0x8000, 0x802D, 0x803A, 0xC50C, 0xCD7C, 0x80F9, 0x8113,
			0x8138, 0x813A, 0x818B, 0xDB7B, 0xDB8C, 0xDB90, 0xDB95])

	return {
		"ok": true,
		"kind": "rom_fresh_match_zero_stamina_initialization",
		"status": "returned_to_8122",
		"source_rom_sha256": ROM_SHA256,
		"source_frame": source_frame,
		"source_path": source_path,
		"checked_home_player_slots": slots.size(),
		"home_player_energy": slots,
		"energy_write_count": slots.size() * 2,
		"return_source_pc": 0x8122,
		"cpu_output_contract": {
			"pc": 0x8122, "a": 0xFF, "x": last_low, "y": 0x02,
			"sp": 0x28, "p_known_mask": 0xC3, "p_known_value": 0x80,
		},
		"ram_writes": writes,
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
		"timing_status": "bounded source-semantic execution; instruction/cycle timing and mapper/PPU phase are not modeled",
	}


func _validate_code_manifest() -> bool:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("First-match ROM resource manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("First-match ROM resource manifest is malformed.")
	var manifest: Dictionary = parsed
	var source_rom: Variant = manifest.get("source_rom", {})
	var source_code: Variant = manifest.get("source_code_resources", {})
	if not source_rom is Dictionary \
			or String(source_rom.get("sha256", "")) != ROM_SHA256 \
			or not source_code is Dictionary:
		return _fail("First-match resource manifest targets another ROM or omits its source-code map.")
	for filename: String in CODE_SPECS:
		var spec: Dictionary = CODE_SPECS[filename]
		if not source_code.has(filename):
			return _fail("ROM manifest omits code resource %s." % filename)
		var row: Dictionary = source_code[filename]
		for key: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "size_bytes", "sha256"]:
			var expected: Variant = spec[key]
			var actual: Variant = row.get(key, null)
			var differs := int(actual) != int(expected) if key == "size_bytes" \
				else str(actual) != str(expected)
			if differs:
				return _fail("ROM manifest metadata differs for %s (%s)." % [filename, key])
		var bytes := FileAccess.get_file_as_bytes(RESOURCE_ROOT + filename)
		if bytes.size() != int(spec["size_bytes"]) \
				or _sha256(bytes) != String(spec["sha256"]):
			return _fail("ROM code resource failed size/hash validation: %s." % filename)
		if String(row.get("sha256", "")) != _sha256(bytes):
			return _fail("ROM code resource and manifest hash disagree: %s." % filename)
	return true


func _load_rom_data() -> bool:
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return _fail("First-match ROM resource manifest is malformed.")
	var resource_rows: Variant = (manifest_variant as Dictionary).get("resources", {})
	if not resource_rows is Dictionary:
		return _fail("First-match ROM data resource map is malformed.")
	for filename: String in DATA_SPECS:
		var spec: Dictionary = DATA_SPECS[filename]
		var row_variant: Variant = resource_rows.get(filename, {})
		if not row_variant is Dictionary:
			return _fail("First-match ROM data manifest omits %s." % filename)
		var row: Dictionary = row_variant
		if int(row.get("size_bytes", -1)) != int(spec["size_bytes"]) \
				or String(row.get("sha256", "")) != String(spec["sha256"]):
			return _fail("First-match ROM data manifest metadata differs for %s." % filename)
		var bytes := FileAccess.get_file_as_bytes(RESOURCE_ROOT + filename)
		if bytes.size() != int(spec["size_bytes"]) or _sha256(bytes) != String(spec["sha256"]):
			return _fail("ROM data resource failed size/hash validation: %s." % filename)
		match filename:
			"match_00_home_roster.bin": _home_roster = bytes
			"stamina_profile_values_AE86_AFAE.bin": _stamina_profiles = bytes
			"stamina_value_words_9F0E_9FCD.bin": _stamina_values = bytes
	var audit: Variant = JSON.parse_string(FileAccess.get_file_as_string(DYNAMIC_AUDIT_PATH))
	if not audit is Dictionary:
		return _fail("First-action menu ROM-data audit is malformed.")
	var audit_rows: Variant = (audit as Dictionary).get("rom_resources", {})
	if not audit_rows is Dictionary:
		return _fail("First-action menu ROM-data audit has no resource map.")
	var menu_data: Dictionary = {}
	for filename: String in MENU_DATA_SPECS:
		var spec: Dictionary = MENU_DATA_SPECS[filename]
		var row_variant: Variant = audit_rows.get(filename, {})
		if not row_variant is Dictionary:
			return _fail("Menu ROM-data audit omits %s." % filename)
		var row: Dictionary = row_variant
		if int(row.get("size_bytes", -1)) != int(spec["size_bytes"]) \
				or String(row.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Menu ROM-data audit metadata differs for %s." % filename)
		var bytes := FileAccess.get_file_as_bytes(PLAYER_MENU_ROOT + filename)
		if bytes.size() != int(spec["size_bytes"]) or _sha256(bytes) != String(spec["sha256"]):
			return _fail("Menu ROM resource failed size/hash validation: %s." % filename)
		menu_data[filename] = bytes
	_record_pointers = menu_data["player_record_pointer_table_22.bin"]
	_profile_map = menu_data["player_stat_profile_map_00_22.bin"]
	_player_stat_profiles = menu_data["player_stat_profiles_00_8c.bin"]
	if _home_roster.size() != 12 or _record_pointers.size() != 44 \
			or _profile_map.size() != 140 or _stamina_profiles.size() != 0x128 \
			or _stamina_values.size() != 0xC0 or _player_stat_profiles.size() != 0x8D * 0x18:
		return _fail("The ROM stamina-input resource dimensions are invalid.")
	return true


func _validate_source_path_bytes() -> bool:
	var vector := FileAccess.get_file_as_bytes(RESOURCE_ROOT + "fixed_match_stamina_vector_C572_C575.bin")
	var evaluator := FileAccess.get_file_as_bytes(RESOURCE_ROOT + "bank1c_stamina_evaluator_802D_818E.bin")
	var pointer_resolver := FileAccess.get_file_as_bytes(RESOURCE_ROOT + "fixed_record_pointer_resolver_CD7C_CD89.bin")
	if vector != PackedByteArray([0x4C, 0x62, 0xDB]):
		return _fail("ROM `$C572` no longer jumps to `$DB62`.")
	if evaluator.slice(0, 3) != PackedByteArray([0x20, 0x3A, 0x80]) \
			or evaluator.slice(0x813C - 0x802D, 0x813F - 0x802D) \
				!= PackedByteArray([0x4C, 0x8B, 0x81]):
		return _fail("The bank-$1C stamina evaluator entry or return path changed.")
	if pointer_resolver != PackedByteArray([0x0A, 0xA8, 0xB9, 0x89, 0xCD,
			0x85, 0x34, 0xB9, 0x8A, 0xCD, 0x85, 0x35, 0x60]):
		return _fail("The fixed `$CD7C` record-pointer resolver changed.")
	return true


func _read_known(source_ram: RomSourceRamImage, local_values: Dictionary,
		address: int) -> Dictionary:
	if local_values.has(address):
		return {"known": true, "value": int(local_values[address])}
	return source_ram.get_byte(address)


func _append_write(writes: Array[Dictionary], local_values: Dictionary,
		source_pc: int, address: int, value: int) -> void:
	local_values[address] = value & 0xFF
	writes.append({"source_pc": source_pc, "address": address,
		"value": value & 0xFF})


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message, "source_rom_sha256": ROM_SHA256,
		"trace_state_used": false, "emulator_data_used": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK \
			or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
