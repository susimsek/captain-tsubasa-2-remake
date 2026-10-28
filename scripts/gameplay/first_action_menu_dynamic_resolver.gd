class_name FirstActionMenuDynamicResolver
extends RefCounted
## Resolves the first action panel's `$E0` and `$E1` tokens from current
## match/player state plus byte-preserved ROM-derived tables.

const MatchPlayerState = preload("res://scripts/gameplay/first_action_menu_match_player_state.gd")
const DATA_ROOT: String = "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const TOKEN_PLAYER_LINE: int = 0xE0
const TOKEN_STAT: int = 0xE1
const STAT_PROFILE_RECORD_SIZE: int = 24
const STAT_CURVE_MAX_INDEX: int = 0xBF

var _state: MatchPlayerState
var _player_name_pointers: PackedByteArray
var _player_name_streams: PackedByteArray
var _player_record_pointers: PackedByteArray
var _position_table: PackedByteArray
var _guest_name_tiles: PackedByteArray
var _low_stat_profile_map: PackedByteArray
var _high_stat_profile_map: PackedByteArray
var _stat_profiles: PackedByteArray
var _stat_value_curve: PackedByteArray


func configure(player_state: MatchPlayerState) -> void:
	_state = player_state
	_player_name_pointers = _load_source_bytes("player_name_pointer_table_00_ef.bin")
	_player_name_streams = _load_source_bytes("player_name_streams_f509_fd14.bin")
	_player_record_pointers = _load_source_bytes("player_record_pointer_table_22.bin")
	_position_table = _load_source_bytes("player_position_table_11.bin")
	_guest_name_tiles = _load_source_bytes("guest_player_name_tiles_11x4.bin")
	_low_stat_profile_map = _load_source_bytes("player_stat_profile_map_00_22.bin")
	_high_stat_profile_map = _load_source_bytes("player_stat_profile_map_23_ef.bin")
	_stat_profiles = _load_source_bytes("player_stat_profiles_00_8c.bin")
	_stat_value_curve = _load_source_bytes("player_stat_value_curve_00_bf.bin")


## Pass `Callable(resolver, "resolve_token")` to FirstActionMenuRomLayout.
## `$E0` returns a PackedByteArray; `$E1` returns an integer or null if the
## necessary match-state/profile fields are missing or outside the decoded path.
func resolve_token(token: int, selector: int) -> Variant:
	if _state == null:
		return null
	if token == TOKEN_PLAYER_LINE:
		return _resolve_player_line_tiles()
	if token == TOKEN_STAT:
		return _resolve_stat_value(selector)
	return null


func has_source_tables() -> bool:
	return (
		_player_name_pointers.size() == 0x1E0
		and _player_name_streams.size() == 0x80C
		and _player_record_pointers.size() == 44
		and _position_table.size() == 22
		and _guest_name_tiles.size() == 44
		and _low_stat_profile_map.size() == 35 * 4
		and _high_stat_profile_map.size() == 205 * 4
		and _stat_profiles.size() == 141 * STAT_PROFILE_RECORD_SIZE
		and _stat_value_curve.size() == STAT_CURVE_MAX_INDEX + 1
	)


func _resolve_player_line_tiles() -> Variant:
	if not has_source_tables():
		return null
	if _state.player_slot_index < 0 or _state.player_slot_index > 21:
		return null
	if _state.player_id < 0:
		return null

	var position_index: int = _state.player_slot_index
	if position_index >= 11:
		position_index -= 11
	var position_offset: int = position_index * 2
	var name_tiles: Variant = _resolve_name_tiles()
	if not (name_tiles is PackedByteArray) or name_tiles.is_empty():
		return null

	var result := PackedByteArray()
	result.append(_position_table[position_offset])
	result.append(_position_table[position_offset + 1])
	result.append(0)
	var player_name: PackedByteArray = name_tiles
	for tile in player_name:
		result.append(tile)
	while player_name.size() < 5:
		result.append(0)
		player_name.append(0)
	return result


func _resolve_name_tiles() -> Variant:
	if not _state.custom_name_tiles.is_empty():
		return _state.custom_name_tiles.duplicate()

	if _state.player_id == 0:
		if _state.player_slot_index < 11 or _state.player_slot_index > 21:
			return null
		var guest_offset: int = (_state.player_slot_index - 11) * 4
		return _guest_name_tiles.slice(guest_offset, guest_offset + 4)

	if _state.player_id < 1 or _state.player_id > 0xEF:
		return null
	var pointer_offset: int = _state.player_id * 2
	var name_address: int = _player_name_pointers[pointer_offset] | (_player_name_pointers[pointer_offset + 1] << 8)
	if name_address < 0xF509 or name_address >= 0xFD15:
		return null
	var string_offset: int = name_address - 0xF509
	var result := PackedByteArray()
	while string_offset < _player_name_streams.size():
		var tile: int = _player_name_streams[string_offset]
		string_offset += 1
		if tile == 0xFC:
			return result
		if tile >= 0xE0:
			return null
		result.append(tile)
	return null


func _resolve_stat_value(selector: int) -> Variant:
	if not has_source_tables():
		return null
	if selector == 0:
		if _state.current_energy < 0 or _state.current_energy > 0xFFFF:
			return null
		return _state.current_energy
	if selector < 1 or selector > 3:
		return null
	if _state.level < 0:
		return null
	# The byte-checked bank-$1C evaluator has separate logic for these special
	# player-slot indices. They are outside this first-panel normal-player path.
	if _state.player_slot_index == 0 or _state.player_slot_index == 11:
		return null
	if _state.player_slot_index == 30 or _state.player_slot_index == 31:
		return null

	var profile_id: int = _resolve_profile_id()
	if profile_id < 0 or profile_id > 140:
		return null
	var profile_offset: int = profile_id * STAT_PROFILE_RECORD_SIZE + selector
	if profile_offset < 0 or profile_offset >= _stat_profiles.size():
		return null
	var base_curve_index: int = _stat_profiles[profile_offset]
	var curve_index: int = min(STAT_CURVE_MAX_INDEX, base_curve_index + 2 * _state.level)
	if curve_index < 0 or curve_index >= _stat_value_curve.size():
		return null
	return _stat_value_curve[curve_index]


func _resolve_profile_id() -> int:
	if _state.stat_profile_id >= 0:
		return _state.stat_profile_id
	var lookup_player_id: int = _state.stat_lookup_player_id
	if lookup_player_id < 0:
		lookup_player_id = _state.player_id
	if lookup_player_id >= 1 and lookup_player_id <= 0x22:
		return _low_stat_profile_map[lookup_player_id * 4]
	if lookup_player_id >= 0x23 and lookup_player_id <= 0xEF:
		var profile_offset: int = (lookup_player_id - 0x23) * 4
		return _high_stat_profile_map[profile_offset]
	return -1


func _load_source_bytes(filename: String) -> PackedByteArray:
	var path: String = DATA_ROOT + filename
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)
