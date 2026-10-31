extends RefCounted
class_name RomFirstCommandHolderCoordinateResolver
## Reproduces the ROM copy from the current $0441 player record into
## $0635/$0637, using ROM-derived initial positions. It does not select the
## holder or model any later movement/callback scheduling.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/first_command_field/holder_coordinates/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const MANIFEST_SHA256 := "aa951660b645d51a2c8fbfa6fbbc44026c478daea8bd8068b8afedf1a08b2bf3"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const POSITION_INITIALIZER_SCRIPT := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")

const SOURCE_EXPECTATIONS := {
	"bank_1f_e0f6_coordinate_copy_call.bin": {
		"size": 3,
		"sha256": "a755646aa4700379e0fbfdaf1fc58a9c63c250abe2a49c654a6cda3299b56392",
		"cpu_address": "$E0F6",
		"file_offset": "0x03E106",
		"hex": "20ece6",
	},
	"bank_1f_e6ec_holder_coordinate_copy.bin": {
		"size": 0x1D,
		"sha256": "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c",
		"cpu_address": "$E6EC",
		"file_offset": "0x03E6FC",
		"hex": "ad4104207ccd a006b1348d3506 aa a008b1348d3706 a820e2cd8dfe0560",
	},
	"bank_1f_cde2_coordinate_index_helper.bin": {
		"size": 0x26,
		"sha256": "e5f6dcb9f5d2451ba1770add2906daa504befaf7800e3bfe2e1b163708e58a83",
		"cpu_address": "$CDE2",
		"file_offset": "0x03CDF2",
		"hex": "8a38e930901dc9a0b0194a4a4aaa9838e950900fc960b00b4a4a4aca30071869 0cd0f8a9ff60",
	},
}

var last_error := ""
var is_configured := false
var _source_hashes: Dictionary = {}


func configure() -> bool:
	last_error = ""
	is_configured = false
	_source_hashes.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("The holder-coordinate source manifest is missing.")
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if _sha256(manifest_bytes) != MANIFEST_SHA256:
		return _fail("The holder-coordinate source manifest failed its hash check.")
	var manifest_variant: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not manifest_variant is Dictionary:
		return _fail("The holder-coordinate source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != "ct2-first-command-holder-coordinate-copy-v1" \
			or str(manifest.get("rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("The holder-coordinate sources target a different ROM or schema.")
	if bool(manifest.get("runtime_boundary", {}).get("captures_used_as_runtime_inputs", true)):
		return _fail("The holder-coordinate source manifest violates the capture-only boundary.")

	var entries: Dictionary = {}
	for entry_variant in manifest.get("entries", []):
		if not entry_variant is Dictionary:
			return _fail("A holder-coordinate source entry is malformed.")
		var entry: Dictionary = entry_variant
		entries[str(entry.get("path", ""))] = entry
	for source_name_variant in SOURCE_EXPECTATIONS.keys():
		var source_name := str(source_name_variant)
		var expected: Dictionary = SOURCE_EXPECTATIONS[source_name]
		if not entries.has(source_name):
			return _fail("The source manifest omits %s." % source_name)
		var entry: Dictionary = entries[source_name]
		if int(entry.get("size_bytes", -1)) != int(expected["size"]) \
				or str(entry.get("sha256", "")) != str(expected["sha256"]) \
				or str(entry.get("cpu_address", "")) != str(expected["cpu_address"]) \
				or str(entry.get("file_offset", "")) != str(expected["file_offset"]):
			return _fail("The metadata for %s differs from the verified ROM span." % source_name)
		var source_bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + source_name)
		if source_bytes.size() != int(expected["size"]) \
				or _sha256(source_bytes) != str(expected["sha256"]) \
				or source_bytes.hex_encode() != str(expected["hex"]).replace(" ", "").to_lower():
			return _fail("The preserved bytes for %s failed their hash or instruction check." % source_name)
		if str(entry.get("raw_hex", "")).replace(" ", "").to_lower() != source_bytes.hex_encode():
			return _fail("The manifest byte listing for %s disagrees with the preserved span." % source_name)
		_source_hashes[source_name] = _sha256(source_bytes)

	is_configured = true
	return true


## Map an explicitly source-owned live holder slot to the match-zero initial
## player-record coordinates copied by $E6EC. This method does not derive the
## holder slot from the route's RNG or from a captured $0441 value.
func resolve_initial_coordinates(holder_slot_index: int, match_index: int,
		home_formation: int, away_formation: int, possession_side: int,
		source_context: Dictionary) -> Dictionary:
	if not is_configured:
		return _failure("Configure the hash-checked ROM copy path before resolving coordinates.")
	if holder_slot_index < 0 or holder_slot_index >= 22:
		return _failure("The live $0441 holder slot must be in the source range 0..21.")
	if str(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(source_context.get("label", "")).is_empty():
		return _failure("Holder selection must be supplied by decoded game logic, not an emulator capture.")

	var initializer = POSITION_INITIALIZER_SCRIPT.new()
	if not initializer.configure():
		return _failure("The ROM position initializer could not configure: " + str(initializer.error_message))
	var position_result: Dictionary = initializer.initialize_positions(
		match_index, home_formation, away_formation, possession_side,
		source_context.duplicate(true))
	if not bool(position_result.get("ok", false)):
		return _failure("Initial player coordinates could not be derived: " + str(position_result.get("error", "unknown error")))
	var positions: Array = position_result.get("positions", [])
	if positions.size() != 22 or not positions[holder_slot_index] is Dictionary:
		return _failure("The ROM position initializer did not provide all 22 player records.")
	var position: Dictionary = positions[holder_slot_index]
	var expected_record_address := 0x0300 + 0x0C * holder_slot_index
	if int(position.get("global_slot", -1)) != holder_slot_index \
			or int(position.get("record_address", -1)) != expected_record_address \
			or int(position.get("x_record_offset", -1)) != 0x06 \
			or int(position.get("y_record_offset", -1)) != 0x08:
		return _failure("The position record does not match the $CD7C/$CD89 +6/+8 copy path.")
	var x_position := int(position.get("x", -1))
	var y_position := int(position.get("y", -1))
	if x_position < 0 or x_position > 0xFF or y_position < 0 or y_position > 0xFF:
		return _failure("The ROM-derived holder coordinates are outside byte range.")
	return {
		"ok": true,
		"holder_slot_index": holder_slot_index,
		"record_address": expected_record_address,
		"x_0635": x_position,
		"y_0637": y_position,
		"source_coordinates": position.duplicate(true),
		"source_path": "$E0F6→$E6EC: $0441→$CD7C/$CD89→record +$06/+08",
		"holder_selection_derived": false,
		"dynamic_movement_modeled": false,
		"callback_05cd_05ce_modeled": false,
		"source_context": source_context.duplicate(true),
	}


func get_source_status() -> Dictionary:
	return {
		"configured": is_configured,
		"error": last_error,
		"manifest_path": MANIFEST_PATH,
		"manifest_sha256": MANIFEST_SHA256,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_hashes": _source_hashes.duplicate(true),
		"holder_selection_derived": false,
		"dynamic_movement_modeled": false,
		"callback_state_modeled": false,
	}


func _failure(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "error": message}


func _fail(message: String) -> bool:
	last_error = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
