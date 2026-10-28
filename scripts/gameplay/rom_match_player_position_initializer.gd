extends RefCounted
class_name RomMatchPlayerPositionInitializer
## Decodes the fixed-bank match-0 position initializer from preserved ROM bytes.
## Inputs are explicit decoded-game-logic values; this helper never reads RAM/PPU captures.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/first_command_field/player_record_positions/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const MANIFEST_SHA256 := "5a12a34630b7c38a13812c3280eef00c2fcbd74615ccac7f21a31d3d8a9eff2d"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

const FORMATION_COUNT := 4
const FORMATION_ROW_STRIDE := 11
const TEAM_PLAYER_COUNT := 11
const GLOBAL_RECORD_COUNT := 22
const HOME_SIDE := 0
const AWAY_SIDE := 11
const RECORD_TABLE_BASE := 0x0300
const RECORD_SIZE := 0x0C
const X_RECORD_OFFSET := 0x06
const Y_RECORD_OFFSET := 0x08

const SOURCE_EXPECTATIONS := {
	"bank_1f_dc07_position_initializer_code.bin": {
		"size": 123, "sha256": "34e88c6568d39179f68bf31176222e1daa62d94a8beb0da107614b6fda725990",
		"cpu_address": "$DC07", "file_offset": "0x03DC17"
	},
	"bank_1f_dc87_primary_position_table.bin": {
		"size": 44, "sha256": "8bfe91dc257f57a3f59172e1f658ee1d0860b9f52f0a37321a88c92b4f18506f",
		"cpu_address": "$DC87", "file_offset": "0x03DC97"
	},
	"bank_1f_dcb3_secondary_position_table.bin": {
		"size": 44, "sha256": "5b9c57152a7855e2410309d9e2d0b5d1ff2adfb7a83329b0c0b0c8eadf32ce63",
		"cpu_address": "$DCB3", "file_offset": "0x03DCC3"
	},
	"bank_1f_cd7c_record_pointer_lookup_code.bin": {
		"size": 13, "sha256": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
		"cpu_address": "$CD7C", "file_offset": "0x03CD8C"
	},
	"bank_1f_cd89_record_pointer_table_22.bin": {
		"size": 44, "sha256": "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185",
		"cpu_address": "$CD89", "file_offset": "0x03CD99"
	},
	"bank_1f_cdc9_coordinate_transform_code.bin": {
		"size": 25, "sha256": "45eb9e048e38d5655178886e5c61d4245720493c9044e2acc2f180f8c76eba7c",
		"cpu_address": "$CDC9", "file_offset": "0x03CDD9"
	},
}

var error_message := ""
var _source_bytes: Dictionary = {}
var _configured := false


func configure() -> bool:
	error_message = ""
	_configured = false
	_source_bytes.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("The preserved player-position source manifest is missing.")
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if _sha256(manifest_bytes) != MANIFEST_SHA256:
		return _fail("The player-position source manifest failed its hash check.")
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail("The player-position source manifest is not a JSON object.")
	var manifest: Dictionary = parsed
	if str(manifest.get("schema", "")) != "ct2-match-player-position-sources-v1":
		return _fail("The player-position source manifest schema is unsupported.")
	if str(manifest.get("rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("The preserved sources do not identify the supplied ROM revision.")
	if int(manifest.get("supported_scope", {}).get("formation_row_stride_slots", -1)) != FORMATION_ROW_STRIDE:
		return _fail("The source manifest does not confirm the 11-slot formation stride.")

	var entries_variant: Variant = manifest.get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY:
		return _fail("The player-position source manifest entries are malformed.")
	var entries_by_path: Dictionary = {}
	for entry_variant in entries_variant:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return _fail("A player-position source entry is malformed.")
		var entry: Dictionary = entry_variant
		entries_by_path[str(entry.get("path", ""))] = entry

	for source_path_variant in SOURCE_EXPECTATIONS.keys():
		var source_path := str(source_path_variant)
		var expectation: Dictionary = SOURCE_EXPECTATIONS[source_path]
		if not entries_by_path.has(source_path):
			return _fail("The source manifest omits %s." % source_path)
		var entry: Dictionary = entries_by_path[source_path]
		if int(entry.get("size_bytes", -1)) != int(expectation["size"]):
			return _fail("The manifest size for %s is incorrect." % source_path)
		if str(entry.get("sha256", "")) != str(expectation["sha256"]):
			return _fail("The manifest hash for %s is incorrect." % source_path)
		if str(entry.get("cpu_address", "")) != str(expectation["cpu_address"]) \
				or str(entry.get("file_offset", "")) != str(expectation["file_offset"]):
			return _fail("The provenance span for %s is incorrect." % source_path)
		var path := SOURCE_ROOT + source_path
		if not FileAccess.file_exists(path):
			return _fail("The preserved ROM source span %s is missing." % source_path)
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(expectation["size"]):
			return _fail("The preserved ROM source span %s has the wrong size." % source_path)
		if _sha256(bytes) != str(expectation["sha256"]):
			return _fail("The preserved ROM source span %s failed its hash check." % source_path)
		var recorded_hex := str(entry.get("raw_hex", "")).replace(" ", "").to_lower()
		if recorded_hex != bytes.hex_encode():
			return _fail("The manifest byte listing for %s disagrees with its source span." % source_path)
		_source_bytes[source_path] = bytes

	if not _validate_record_pointer_table():
		return _fail("The ROM pointer table does not match the 22 supported record slots.")
	_configured = true
	return true


## Derive the initial 22 records from explicit decoded inputs.
## source_context must identify caller-owned game-logic inputs, never a capture.
func initialize_positions(match_index: int, formation_002c: int, formation_002e: int,
		possession_side_05fb: int, source_context: Dictionary) -> Dictionary:
	if not _configured:
		return _result(false, [], match_index, formation_002c, formation_002e,
			possession_side_05fb, source_context, "Configure the hash-checked ROM source spans first.")
	if match_index != 0:
		return _result(false, [], match_index, formation_002c, formation_002e,
			possession_side_05fb, source_context, "Only match index 0 is supported by this initializer.")
	if formation_002c < 0 or formation_002c >= FORMATION_COUNT \
			or formation_002e < 0 or formation_002e >= FORMATION_COUNT:
		return _result(false, [], match_index, formation_002c, formation_002e,
			possession_side_05fb, source_context, "Formation indices must select one of the four ROM table rows.")
	if possession_side_05fb != HOME_SIDE and possession_side_05fb != AWAY_SIDE:
		return _result(false, [], match_index, formation_002c, formation_002e,
			possession_side_05fb, source_context, "The source supports possession-side values 0 or 11 only.")
	if str(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(source_context.get("label", "")).is_empty():
		return _result(false, [], match_index, formation_002c, formation_002e,
			possession_side_05fb, source_context,
			"Provide a nonempty caller-owned decoded-game-logic source context, not capture data.")

	var primary_table: PackedByteArray = _source_bytes["bank_1f_dc87_primary_position_table.bin"]
	var secondary_table: PackedByteArray = _source_bytes["bank_1f_dcb3_secondary_position_table.bin"]
	var positions: Array[Dictionary] = []
	for global_slot in range(GLOBAL_RECORD_COUNT):
		var team_side := HOME_SIDE if global_slot < TEAM_PLAYER_COUNT else AWAY_SIDE
		var local_slot := global_slot if team_side == HOME_SIDE else global_slot - TEAM_PLAYER_COUNT
		var formation_index := formation_002c if team_side == HOME_SIDE else formation_002e
		var table_index := formation_index * FORMATION_ROW_STRIDE + local_slot
		var use_primary := team_side == possession_side_05fb
		var table_id := "$DC87" if use_primary else "$DCB3"
		var encoded: int = primary_table[table_index] if use_primary else secondary_table[table_index]
		var coordinate := _decode_coordinate(encoded)
		var x_position := int(coordinate["x"])
		var y_position := int(coordinate["y"])
		if possession_side_05fb != HOME_SIDE:
			x_position = (-x_position) & 0xFF
			y_position = (-y_position) & 0xFF
		positions.append({
			"global_slot": global_slot,
			"local_slot": local_slot,
			"team_side": team_side,
			"formation_index": formation_index,
			"table_id": table_id,
			"table_index": table_index,
			"encoded_position": encoded,
			"record_address": _record_address_for_slot(global_slot),
			"x_record_offset": X_RECORD_OFFSET,
			"y_record_offset": Y_RECORD_OFFSET,
			"x": x_position,
			"y": y_position,
		})
	return _result(true, positions, match_index, formation_002c, formation_002e,
		possession_side_05fb, source_context, "")


func get_source_status() -> Dictionary:
	var hashes: Dictionary = {}
	for source_path_variant in _source_bytes.keys():
		var source_path := str(source_path_variant)
		hashes[source_path] = _sha256(_source_bytes[source_path])
	return {
		"configured": _configured,
		"error": error_message,
		"manifest_path": MANIFEST_PATH,
		"manifest_sha256": MANIFEST_SHA256,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_hashes": hashes,
		"formation_row_stride": FORMATION_ROW_STRIDE,
		"supported_match_indices": [0],
	}


func _record_address_for_slot(global_slot: int) -> int:
	var pointers: PackedByteArray = _source_bytes["bank_1f_cd89_record_pointer_table_22.bin"]
	var pointer_index := global_slot * 2
	return int(pointers[pointer_index]) | (int(pointers[pointer_index + 1]) << 8)


func _validate_record_pointer_table() -> bool:
	var pointers: PackedByteArray = _source_bytes.get(
		"bank_1f_cd89_record_pointer_table_22.bin", PackedByteArray())
	if pointers.size() != GLOBAL_RECORD_COUNT * 2:
		return false
	for slot in range(GLOBAL_RECORD_COUNT):
		var address := int(pointers[slot * 2]) | (int(pointers[slot * 2 + 1]) << 8)
		if address != RECORD_TABLE_BASE + RECORD_SIZE * slot:
			return false
	return true


func _decode_coordinate(encoded_position: int) -> Dictionary:
	# $CDC9 divides by $0C; its loop count is X, quotient is x, remainder is y.
	var quotient := int(encoded_position / 0x0C)
	var remainder := encoded_position % 0x0C
	return {
		"x": (0x34 + 8 * quotient) & 0xFF,
		"y": (0x54 + 8 * remainder) & 0xFF,
	}


func _result(ok: bool, positions: Array, match_index: int, home_formation: int,
		away_formation: int, possession_side: int, source_context: Dictionary,
		message: String) -> Dictionary:
	return {
		"ok": ok,
		"positions": positions,
		"match_index": match_index,
		"formation_002c": home_formation,
		"formation_002e": away_formation,
		"possession_side_05fb": possession_side,
		"source_context": source_context.duplicate(true),
		"error": message,
	}


func _sha256(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
