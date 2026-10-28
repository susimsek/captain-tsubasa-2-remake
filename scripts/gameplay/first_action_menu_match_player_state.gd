class_name FirstActionMenuMatchPlayerState
extends RefCounted
## Runtime inputs used by the first action menu's ROM `$E0` / `$E1` tokens.
## A negative value means the route/match model has not supplied that field.

var player_slot_index: int = -1
var player_id: int = -1
var current_energy: int = -1
var level: int = -1

## Optional profile already resolved by the match model. When unset, IDs
## `$01–$22` use the target ROM's normal low-ID profile table.
var stat_profile_id: int = -1

## Optional effective ID for the bank-$1C high-ID alternate/clone path. The
## match model sets this only after applying the ROM's record-flag rule.
var stat_lookup_player_id: int = -1

## Optional custom-name tile sequence for special ID-0 records. The normal
## opponent slots (11–21) use the target ROM's four-tile fallback table.
var custom_name_tiles: PackedByteArray = PackedByteArray()
