extends RefCounted
class_name RomFreshKickoffPositionContextResolver
## Resolves match-zero formation and possession-side inputs from preserved ROM bytes.
## Route state is caller-owned decoded logic; emulator RAM is never an input.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_position_context/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const MANIFEST_SHA256 := "932c477de0336097e63758afc6ecce415b32d98334f200870f31e15fe9a75702"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

const SUPPORTED_MATCH_INDEX := 0
const SUPPORTED_KICKOFF_SELECTOR := 0
const HOME_ROSTER_FORMATION_OFFSET := 11
const OPPONENT_BASE_ID := 3
const OPPONENT_FORMATION_MASK := 0x0F
const HOME_POSSESSION_SIDE := 0

const SOURCE_EXPECTATIONS := {
	"bank_02_home_match_selector_code_A86E_A8CD.bin": {
		"size": 96, "sha256": "f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123",
		"cpu_address": "$A86E", "file_offset": "0x00487E"
	},
	"bank_02_match_00_home_roster_AA47.bin": {
		"size": 12, "sha256": "dcb5f0103eaecbc9785e947085b02cd6b56f7d31e6671a699d82b22d80a3b123",
		"cpu_address": "$AA47", "file_offset": "0x004A57"
	},
	"bank_02_match_00_home_team_id_AA75.bin": {
		"size": 1, "sha256": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
		"cpu_address": "$AA75", "file_offset": "0x004A85"
	},
	"bank_1c_away_formation_decode_8B39_8B62.bin": {
		"size": 41, "sha256": "0a98b9de6c875ca85a0044356bf951de9a2ec5e4c7b4ea21d03f5711a9a4f890",
		"cpu_address": "$8B39", "file_offset": "0x038B49"
	},
	"bank_1d_opponent_pointer_table_entry_0_BAB2.bin": {
		"size": 2, "sha256": "1d22ca41334213a0048e0f2dea829d998839cca5d882e25b42d46505e1f61afc",
		"cpu_address": "$BAB2", "file_offset": "0x03BAC2"
	},
	"bank_1d_opponent_3_record_header_BAF6.bin": {
		"size": 1, "sha256": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
		"cpu_address": "$BAF6", "file_offset": "0x03BB06"
	},
	"fixed_kickoff_dispatch_and_branch_DB20_DB62.bin": {
		"size": 66, "sha256": "b573548c1d45d901effe7e870f7af992179d5276c1e6278e7636a2443783b4f9",
		"cpu_address": "$DB20", "file_offset": "0x03DB30"
	},
	"fixed_branch_table_dispatch_helper_CB99_CBAF.bin": {
		"size": 23, "sha256": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54",
		"cpu_address": "$CB99", "file_offset": "0x03CBA9"
	},
	"fixed_reset_jump_C503.bin": {
		"size": 3, "sha256": "1af2205ae6c5e64cd5a956e38ab915e5f3049b2c6e40ed85803c3c8b6abbdf3d",
		"cpu_address": "$C503", "file_offset": "0x03C513"
	},
	"fixed_reset_ram_clear_C64E_C679.bin": {
		"size": 44, "sha256": "8315e93ae660d302632f7bfeffc9db002b3f1c1643ae2b6936d3ce5703e6f75a",
		"cpu_address": "$C64E", "file_offset": "0x03C65E"
	},
	"fixed_reset_entry_FFF0.bin": {
		"size": 8, "sha256": "95925881564c84710f0f280e12ddf5913882b5d9cf59cd89eabdf47442f9b122",
		"cpu_address": "$FFF0", "file_offset": "0x040000"
	},
	"fixed_reset_vector_FFFC.bin": {
		"size": 2, "sha256": "def1e0885184cca73afc582c50470a0c10851a849027a1dd1d2aacc482b2516a",
		"cpu_address": "$FFFC", "file_offset": "0x04000C"
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
		return _fail("The preserved kickoff-position source manifest is missing.")
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if _sha256(manifest_bytes) != MANIFEST_SHA256:
		return _fail("The kickoff-position source manifest failed its hash check.")
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail("The kickoff-position source manifest is not a JSON object.")
	var manifest: Dictionary = parsed
	if str(manifest.get("schema", "")) != "ct2-fresh-kickoff-position-context-source-v1":
		return _fail("The kickoff-position source manifest schema is unsupported.")
	if str(manifest.get("rom", {}).get("sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("The preserved sources do not identify the supplied ROM revision.")
	var entries_variant: Variant = manifest.get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY:
		return _fail("The kickoff-position source manifest entries are malformed.")
	var entries_by_path: Dictionary = {}
	for entry_variant in entries_variant:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return _fail("A kickoff-position source entry is malformed.")
		var entry: Dictionary = entry_variant
		entries_by_path[str(entry.get("path", ""))] = entry

	for path_variant in SOURCE_EXPECTATIONS.keys():
		var path := str(path_variant)
		var expected: Dictionary = SOURCE_EXPECTATIONS[path]
		if not entries_by_path.has(path):
			return _fail("The source manifest omits %s." % path)
		var entry: Dictionary = entries_by_path[path]
		if int(entry.get("size_bytes", -1)) != int(expected["size"]) \
				or str(entry.get("sha256", "")) != str(expected["sha256"]):
			return _fail("The manifest size/hash for %s is incorrect." % path)
		if str(entry.get("cpu_start", "")) != str(expected["cpu_address"]) \
				or str(entry.get("file_offset", "")) != str(expected["file_offset"]):
			return _fail("The source provenance for %s is incorrect." % path)
		var source_path := SOURCE_ROOT + path
		if not FileAccess.file_exists(source_path):
			return _fail("The preserved ROM span %s is missing." % path)
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if bytes.size() != int(expected["size"]) or _sha256(bytes) != str(expected["sha256"]):
			return _fail("The preserved ROM span %s failed size/hash validation." % path)
		if str(entry.get("raw_hex", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("The manifest byte listing for %s disagrees with the extracted span." % path)
		_source_bytes[path] = bytes
	if not _validate_source_instructions():
		return _fail("The code bytes do not match the expected match-zero source paths.")
	_configured = true
	return true


## Caller supplies decoded route state, never a RAM/PPU capture or endpoint fixture.
## `kickoff_selector` is the route-owned value consumed through `$DB24/$CB99`.
func resolve_fresh_match_context(match_index: int, kickoff_selector: int,
		source_context: Dictionary) -> Dictionary:
	if not _configured:
		return _result(false, match_index, kickoff_selector, source_context,
			"Configure the hash-checked ROM source spans first.")
	if match_index != SUPPORTED_MATCH_INDEX:
		return _result(false, match_index, kickoff_selector, source_context,
			"Only fresh match index 0 is supported.")
	if kickoff_selector != SUPPORTED_KICKOFF_SELECTOR:
		return _result(false, match_index, kickoff_selector, source_context,
			"Only kickoff selector 0, which resolves to ROM branch $DB34, is supported.")
	if str(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(source_context.get("label", "")).is_empty():
		return _result(false, match_index, kickoff_selector, source_context,
			"Provide a named caller-owned decoded-game-logic context, not capture data.")

	var home_record: PackedByteArray = _source_bytes["bank_02_match_00_home_roster_AA47.bin"]
	var home_team_table: PackedByteArray = _source_bytes["bank_02_match_00_home_team_id_AA75.bin"]
	var away_pointer_entry: PackedByteArray = _source_bytes["bank_1d_opponent_pointer_table_entry_0_BAB2.bin"]
	var opponent_header: PackedByteArray = _source_bytes["bank_1d_opponent_3_record_header_BAF6.bin"]
	var dispatch: PackedByteArray = _source_bytes["fixed_kickoff_dispatch_and_branch_DB20_DB62.bin"]

	var home_formation := int(home_record[HOME_ROSTER_FORMATION_OFFSET])
	var home_team_id := int(home_team_table[0])
	var opponent_id := match_index + OPPONENT_BASE_ID
	var opponent_pointer := int(away_pointer_entry[0]) | (int(away_pointer_entry[1]) << 8)
	var away_formation := int(opponent_header[0]) & OPPONENT_FORMATION_MASK
	var table_pointer_offset := 0x0A + kickoff_selector * 2
	var branch_address := int(dispatch[table_pointer_offset]) \
			| (int(dispatch[table_pointer_offset + 1]) << 8)
	if branch_address != 0xDB34:
		return _result(false, match_index, kickoff_selector, source_context,
			"The ROM branch table no longer resolves selector 0 to $DB34.")
	if home_formation > 3 or away_formation > 3 or opponent_id != 3 \
			or home_team_id != 0 or opponent_pointer != 0xBAF6:
		return _result(false, match_index, kickoff_selector, source_context,
			"The match-zero ROM data is outside this resolver's verified context.")
	# At $DB34, X is initialized to 0. If $002B == 3, BNE's opposite path is
	# skipped and X=0 is written to both $044F and $05FB.
	var branch_side := HOME_POSSESSION_SIDE
	return {
		"ok": true,
		"match_index": match_index,
		"home_team_id": home_team_id,
		"opponent_id": opponent_id,
		"formation_002c": home_formation,
		"formation_002e": away_formation,
		"possession_side_05fb": branch_side,
		"kickoff_selector_0629": kickoff_selector,
		"kickoff_branch_address": branch_address,
		"opponent_record_address": opponent_pointer,
		"source_context": source_context.duplicate(true),
		"source_hashes": _source_hashes(),
		"error": "",
	}


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"manifest_path": MANIFEST_PATH,
		"manifest_sha256": MANIFEST_SHA256,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_hashes": _source_hashes(),
		"supported_match_indices": [SUPPORTED_MATCH_INDEX],
		"supported_kickoff_selectors": [SUPPORTED_KICKOFF_SELECTOR],
		"reset_ram_clear_proven": _configured,
		"kickoff_selector_is_caller_owned": true,
	}


func _validate_source_instructions() -> bool:
	var home_code: PackedByteArray = _source_bytes["bank_02_home_match_selector_code_A86E_A8CD.bin"]
	var away_code: PackedByteArray = _source_bytes["bank_1c_away_formation_decode_8B39_8B62.bin"]
	var dispatch: PackedByteArray = _source_bytes["fixed_kickoff_dispatch_and_branch_DB20_DB62.bin"]
	var dispatch_helper: PackedByteArray = _source_bytes["fixed_branch_table_dispatch_helper_CB99_CBAF.bin"]
	var reset_stub: PackedByteArray = _source_bytes["fixed_reset_jump_C503.bin"]
	var reset_clear: PackedByteArray = _source_bytes["fixed_reset_ram_clear_C64E_C679.bin"]
	var reset_entry: PackedByteArray = _source_bytes["fixed_reset_entry_FFF0.bin"]
	var reset_vector: PackedByteArray = _source_bytes["fixed_reset_vector_FFFC.bin"]
	return _bytes_at(home_code, 0x35, [0xBD, 0x47, 0xAA, 0x85, 0x2C]) \
			and _bytes_at(home_code, 0x41, [0xA5, 0x26, 0x18, 0x69, 0x03, 0x85, 0x2B]) \
			and _bytes_at(away_code, 0x00, [0xAD, 0x2B, 0x00, 0x38, 0xE9, 0x03, 0x0A, 0xAA]) \
			and _bytes_at(away_code, 0x14, [0xB1, 0x38, 0x29, 0x0F, 0x8D, 0x2E, 0x00]) \
			and _bytes_at(dispatch, 0x04, [0xAD, 0x29, 0x06, 0x20, 0x99, 0xCB]) \
			and _bytes_at(dispatch, 0x0A, [0x34, 0xDB]) \
			and _bytes_at(dispatch, 0x14, [0x48, 0xA5, 0x22, 0xA9, 0x1C]) \
			and _bytes_at(dispatch, 0x2B, [0xA2, 0x00]) \
			and _bytes_at(dispatch, 0x2D, [0xAD, 0x2B, 0x00, 0xC9, 0x03, 0xF0, 0x07]) \
			and _bytes_at(dispatch, 0x3B, [0x8E, 0x4F, 0x04, 0x8E, 0xFB, 0x05, 0x60]) \
			and _bytes_at(dispatch_helper, 0x00,
				[0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8]) \
			and _bytes_at(reset_stub, 0x00, [0x4C, 0x4E, 0xC6]) \
			and _bytes_at(reset_entry, 0x00, [0xA9, 0x00, 0x8D, 0x00, 0x80, 0x4C, 0x03, 0xC5]) \
			and _bytes_at(reset_vector, 0x00, [0xF0, 0xFF]) \
			and _bytes_at(reset_clear, 0x19,
				[0xA9, 0x00, 0x85, 0x00, 0x85, 0x01, 0xA8, 0xA2, 0x08,
				0x91, 0x00, 0xC8, 0xD0, 0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6])


func _bytes_at(source: PackedByteArray, offset: int, expected: Array[int]) -> bool:
	if offset < 0 or offset + expected.size() > source.size():
		return false
	for index in range(expected.size()):
		if int(source[offset + index]) != expected[index]:
			return false
	return true


func _source_hashes() -> Dictionary:
	var hashes: Dictionary = {}
	for path_variant in _source_bytes.keys():
		var path := str(path_variant)
		hashes[path] = _sha256(_source_bytes[path])
	return hashes


func _result(ok: bool, match_index: int, kickoff_selector: int,
		source_context: Dictionary, message: String) -> Dictionary:
	return {
		"ok": ok,
		"match_index": match_index,
		"kickoff_selector_0629": kickoff_selector,
		"source_context": source_context.duplicate(true),
		"source_hashes": _source_hashes(),
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
