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
const STACK_PAGE_SIZE := 0x0100
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


## Executes the source-owned `$DAF2 JSR $DC07` callee from a live scheduler
## boundary and returns its ordered RAM/stack writes and `$DAF5` CPU state.
## This is an instruction-derived routine model, not a capture-state importer.
func execute_from_live_call(boundary: Dictionary, match_context: Dictionary) -> Dictionary:
	if not _configured:
		return _execution_failure("Configure the hash-checked ROM source spans first.")
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != 0x0800 \
			or not stack_variant is PackedByteArray or stack_variant.size() != 0x0100:
		return _execution_failure("The live `$DAF2` boundary must provide complete scheduler RAM and stack images.")
	if String(boundary.get("rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xDAF2 \
			or int(boundary.get("sp", -1)) != 0x50 \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D:
		return _execution_failure("The position initializer requires the live slot-$05 `$DAF2` / SP `$50` / bank `$1C/$1D` boundary.")
	var ram := (ram_variant as PackedByteArray).duplicate()
	var initial_context: Dictionary = match_context.get("source_context", {})
	if int(match_context.get("match_index", -1)) != 0 \
			or int(ram[0x002C]) != int(match_context.get("formation_002c", -1)) \
			or int(ram[0x002E]) != int(match_context.get("formation_002e", -1)) \
			or int(ram[0x05FB]) != int(match_context.get("possession_side_05fb", -1)):
		return _execution_failure("Live `$002C/$002E/$05FB` inputs disagree with the decoded match-zero context.")
	var decoded: Dictionary = initialize_positions(0, ram[0x002C], ram[0x002E],
		ram[0x05FB], initial_context)
	if not bool(decoded.get("ok", false)):
		return _execution_failure(String(decoded.get("error", "ROM position tables could not be decoded.")))
	var positions: Array = decoded.get("positions", [])
	if positions.size() != GLOBAL_RECORD_COUNT:
		return _execution_failure("The source tables did not resolve all 22 player records.")
	var writes: Array[Dictionary] = []
	var home_base := int(ram[0x002C]) * FORMATION_ROW_STRIDE
	var away_base := int(ram[0x002E]) * FORMATION_ROW_STRIDE
	_write_ram(ram, writes, 0xDC0F, 0x003A, (ram[0x002C] * 3) & 0xFF)
	_write_ram(ram, writes, 0xDC16, 0x003A, home_base)
	_write_ram(ram, writes, 0xDC20, 0x003B, (ram[0x002E] * 3) & 0xFF)
	_write_ram(ram, writes, 0xDC27, 0x003B, away_base)
	for position_variant in positions:
		var position: Dictionary = position_variant
		var slot := int(position.get("global_slot", -1))
		var record_address := int(position.get("record_address", -1))
		_write_ram(ram, writes, 0xCD81, 0x0034, record_address & 0xFF)
		_write_ram(ram, writes, 0xCD86, 0x0035, (record_address >> 8) & 0xFF)
		var table_base_address := 0x003A if slot < TEAM_PLAYER_COUNT else 0x003B
		var increment_pc := 0xDC31 if slot < TEAM_PLAYER_COUNT else 0xDC40
		var table_base := int(ram[table_base_address])
		_write_ram(ram, writes, increment_pc, table_base_address, (table_base + 1) & 0xFF)
		_write_ram(ram, writes, 0xDC61, record_address + Y_RECORD_OFFSET, int(position.get("y", -1)))
		_write_ram(ram, writes, 0xDC66, record_address + X_RECORD_OFFSET, int(position.get("x", -1)))
		if slot == TEAM_PLAYER_COUNT:
			_write_ram(ram, writes, 0xDC74, record_address + 0x07, 0)
	var expected_last_pointer := _record_address_for_slot(GLOBAL_RECORD_COUNT - 1)
	if int(ram[0x0034]) | (int(ram[0x0035]) << 8) != expected_last_pointer:
		return _execution_failure("The source pointer loop did not finish on player record 21.")
	var stack := (stack_variant as PackedByteArray).duplicate()
	var stack_writes: Array[Dictionary] = []
	# JSR/RTS and the routine's balanced PHA/PLA pairs leave these final bytes
	# behind in the NES stack page even though SP returns to its entry value.
	_stack_write(stack, stack_writes, 0xDAF2, 0x50, 0xDA)
	_stack_write(stack, stack_writes, 0xDAF2, 0x4F, 0xF4)
	_stack_write(stack, stack_writes, 0xDC0B, 0x4E, (ram[0x002C] * 2) & 0xFF)
	_stack_write(stack, stack_writes, 0xDC1C, 0x4E, (ram[0x002E] * 2) & 0xFF)
	for slot in range(GLOBAL_RECORD_COUNT):
		_stack_write(stack, stack_writes, 0xDC2B, 0x4E, slot)
		_stack_write(stack, stack_writes, 0xDC2C, 0x4D, 0xDC)
		_stack_write(stack, stack_writes, 0xDC2C, 0x4C, 0x2E)
		_stack_write(stack, stack_writes, 0xDC34, 0x4E, slot)
		_stack_write(stack, stack_writes, 0xDC4C, 0x4D, 0xDC)
		_stack_write(stack, stack_writes, 0xDC4C, 0x4C, 0x4E)
		_stack_write(stack, stack_writes, 0xDC69, 0x4E, slot)
	for stack_offset in STACK_PAGE_SIZE:
		ram[0x0100 + stack_offset] = stack[stack_offset]
	var last_position: Dictionary = positions[GLOBAL_RECORD_COUNT - 1]
	var entry_p := int(boundary.get("p", 0x20)) & 0xFF
	var return_p := (entry_p & 0x3C) | 0x23 # final CMP #$16: C/Z=1, N=0; ADC has no overflow.
	var return_known_mask := (int(boundary.get("p_known_mask", 0)) | 0xE3 | 0x20) & 0xFF
	return {
		"ok": true,
		"status": "returned_to_slot05_caller_DAF5",
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": MANIFEST_SHA256,
		"source_hashes": get_source_status().get("source_hashes", {}),
		"entry": {"pc": 0xDAF2, "sp": 0x50, "return_word": 0xDAF4,
			"slot_base": 0x05, "bank_low": 0x1C, "bank_high": 0x1D},
		"registers": {"pc": 0xDAF5, "sp": 0x50, "a": 0x16,
			"x": int(last_position.get("x", -1)), "y": 0x06,
			"p": return_p, "p_known_mask": return_known_mask},
		"ram_image": ram,
		"stack_page": stack,
		"memory_writes": writes,
		"stack_writes": stack_writes,
		"positions": positions.duplicate(true),
		"scratch_after": {"$0034": int(ram[0x0034]), "$0035": int(ram[0x0035]),
			"$003A": int(ram[0x003A]), "$003B": int(ram[0x003B])},
		"ppu_bus_events": [], "apu_register_writes": [],
		"source_cycle_timing_modeled": false,
		"error": "",
	}


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


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], pc: int,
		address: int, value: int) -> void:
	var byte_value := value & 0xFF
	ram[address] = byte_value
	writes.append({"pc": pc, "address": address, "value": byte_value})


func _stack_write(stack: PackedByteArray, writes: Array[Dictionary], pc: int,
		address: int, value: int) -> void:
	var offset := address & 0xFF
	var byte_value := value & 0xFF
	stack[offset] = byte_value
	writes.append({"pc": pc, "address": 0x0100 | offset, "value": byte_value})


func _execution_failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}


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
