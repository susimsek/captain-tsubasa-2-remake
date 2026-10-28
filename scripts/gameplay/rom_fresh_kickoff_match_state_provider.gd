class_name RomFreshKickoffMatchStateProvider
extends RefCounted
## Builds fresh match player records from ROM roster/stat bytes and consumes
## source-derived field-loop stamina events. It does not read RAM captures.

const PLAYER_STATE_SCRIPT := preload("res://scripts/gameplay/first_action_menu_match_player_state.gd")
const RNG_EVENT_STREAM_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_event_stream.gd")
const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/first_match_player_state/"
const MENU_DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_ROUTE_ID := "turkish-fresh-kickoff-capture-20261027"
const EXPECTED_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const FIELD_RUN_TIMER_INITIAL := 10
const NORMAL_RUN_COST := 3
const MISUGI_ID := 0x20
const MISUGI_RUN_COST := 5

const RESOURCE_HASHES := {
	"match_00_home_roster.bin": "dcb5f0103eaecbc9785e947085b02cd6b56f7d31e6671a699d82b22d80a3b123",
	"stamina_profile_values_AE86_AFAE.bin": "1c87d94c9754655c7101939c784abf02a7c37f6287cbb89ed674cc40562b6cf8",
	"stamina_value_words_9F0E_9FCD.bin": "9278cbdf95434a0dc120d6938b6095fc24261d735e8ce4f91c5c95400e291085",
}
const PROFILE_MAP_SHA256 := "a16ef4a351fe79c6465741d75e3700b1bfe84f6a28ddee5e837aba226cb4ff48"
const RECORD_POINTERS_SHA256 := "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"

var error_message := ""
var route_identity := ""
var input_timeline_sha256 := ""
var rng_source_mode := ""
var receiver_source_frame := -1
var receiver_slot := -1
var active_ball_player_slot := -1
var field_run_timer := FIELD_RUN_TIMER_INITIAL
var stamina_update_count := 0
var stamina_regen_skip_counter := 0

var _roster: PackedByteArray = PackedByteArray()
var _stamina_profiles: PackedByteArray = PackedByteArray()
var _stamina_value_words: PackedByteArray = PackedByteArray()
var _profile_map: PackedByteArray = PackedByteArray()
var _record_pointers: PackedByteArray = PackedByteArray()
var _players: Array[Dictionary] = []
var _configured := false


## `rng_replay` must already be advanced through its ROM-derived receiver event.
## The current RNG replay is deliberately bound to one audited input hash; this
## provider does not pretend to resolve arbitrary route RNG state.
func configure_from_receiver_replay(rng_replay: RomKickoffRngSourceReplay) -> bool:
	_reset()
	if rng_replay == null:
		return _fail("A ROM-derived kickoff RNG replay is required.")
	var rng_state: Dictionary = rng_replay.get_state()
	if not bool(rng_state.get("configured", false)) or not bool(rng_state.get("input_identity_bound", false)):
		return _fail("Kickoff RNG replay is not configured with a verified input identity.")
	if str(rng_state.get("route_identity", "")) != EXPECTED_ROUTE_ID:
		return _fail("This player-state source supports only the audited fresh-start route.")
	route_identity = str(rng_state.get("route_identity", ""))
	input_timeline_sha256 = str(rng_state.get("input_timeline_sha256", ""))
	if input_timeline_sha256 != EXPECTED_INPUT_SHA256:
		return _fail("The route input hash is outside the available ROM-derived RNG replay.")
	receiver_source_frame = int(rng_state.get("receiver_source_frame", -1))
	receiver_slot = rng_replay.get_receiver_slot()
	if receiver_source_frame < 0 or int(rng_state.get("last_source_frame", -1)) < receiver_source_frame:
		return _fail("The source replay has not reached the receiver-selection event.")
	if receiver_slot < 0:
		return _fail("The receiver slot is unavailable from the source RNG replay.")
	rng_source_mode = "hash_bound_route_replay"
	return _configure_from_receiver_slot(receiver_slot)


## Builds menu player records from caller-fed decoded ROM instruction events.
## The event stream must have reached bank-$1E $DB05 and resolved the fresh
## match's live $05FB base. It intentionally has no frame/hash fallback.
func configure_from_source_event_stream(source_stream: RefCounted) -> bool:
	_reset()
	if source_stream == null or source_stream.get_script() != RNG_EVENT_STREAM_SCRIPT:
		return _fail("A decoded ROM RNG source-event stream is required.")
	var selection: Dictionary = source_stream.call("get_receiver_selection")
	if not bool(selection.get("ready", false)):
		return _fail("The source stream has not reached the decoded $DB05 receiver-selection event.")
	if int(selection.get("receiver_base_05fb", -1)) != 0:
		return _fail("The ROM player-state provider supports the fresh home-side $05FB=$00 route only.")
	receiver_slot = int(selection.get("receiver_slot", -1))
	if receiver_slot < 0 or receiver_slot >= 11:
		return _fail("The ROM-derived receiver slot is outside the fresh home roster.")
	route_identity = "caller_fed_decoded_fresh_kickoff_events"
	input_timeline_sha256 = ""
	receiver_source_frame = -1
	rng_source_mode = "decoded_instruction_event_stream"
	return _configure_from_receiver_slot(receiver_slot)


func _configure_from_receiver_slot(selected_receiver_slot: int) -> bool:
	if selected_receiver_slot < 0 or selected_receiver_slot >= 11:
		return _fail("The source receiver slot lies outside the match-00 home roster.")
	receiver_slot = selected_receiver_slot
	if not _load_and_validate_rom_resources():
		return false
	if receiver_slot >= 11 or receiver_slot >= _roster.size() - 1:
		return _fail("The ROM-selected receiver slot lies outside the match-00 home roster.")
	if not _build_fresh_home_records():
		return false
	active_ball_player_slot = receiver_slot
	field_run_timer = FIELD_RUN_TIMER_INITIAL
	stamina_update_count = 0
	stamina_regen_skip_counter = 0
	_configured = true
	return true


func get_controlled_player_state() -> FirstActionMenuMatchPlayerState:
	if not _configured:
		return null
	return get_player_state(active_ball_player_slot)


func get_player_state(player_slot: int) -> FirstActionMenuMatchPlayerState:
	if not _configured or player_slot < 0 or player_slot >= _players.size():
		return null
	var record: Dictionary = _players[player_slot]
	var state := PLAYER_STATE_SCRIPT.new() as FirstActionMenuMatchPlayerState
	state.player_slot_index = player_slot
	state.player_id = int(record["player_id"])
	state.current_energy = int(record["current_energy"])
	state.level = int(record["level"])
	state.stat_profile_id = int(record["profile_id"])
	return state


func get_player_record(player_slot: int) -> Dictionary:
	if not _configured or player_slot < 0 or player_slot >= _players.size():
		return {}
	return _players[player_slot].duplicate(true)


## Call once only when the source field loop reaches `$E14D`, after `$E349`
## returned without starting a transition. B/menu entry exits earlier and must
## not call this method for that interrupted iteration.
## Returns true exactly when the source timer reaches `$E1F7 -> $E2BC`.
func advance_field_loop_iteration() -> bool:
	if not _configured:
		return false
	if field_run_timer > 0:
		field_run_timer -= 1
		return false
	field_run_timer = FIELD_RUN_TIMER_INITIAL
	_apply_e2bc_regeneration_and_run_cost()
	stamina_update_count += 1
	return true


func set_active_ball_player_slot(player_slot: int) -> bool:
	if not _configured or player_slot < 0 or player_slot >= _players.size():
		return false
	active_ball_player_slot = player_slot
	return true


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"route_identity": route_identity,
		"input_timeline_sha256": input_timeline_sha256,
		"rng_source_mode": rng_source_mode,
		"receiver_source_frame": receiver_source_frame,
		"receiver_slot": receiver_slot,
		"active_ball_player_slot": active_ball_player_slot,
		"active_ball_player_id": int(_players[active_ball_player_slot]["player_id"]) if _configured else -1,
		"field_run_timer": field_run_timer,
		"stamina_update_count": stamina_update_count,
		"stamina_regen_skip_counter": stamina_regen_skip_counter,
		"home_roster_slots": _players.size(),
		"error": error_message,
	}


func _load_and_validate_rom_resources() -> bool:
	var manifest_path := RESOURCE_ROOT + "manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return _fail("The source-derived player-state manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		return _fail("The source-derived player-state manifest is malformed.")
	var manifest: Dictionary = parsed
	var source_rom: Variant = manifest.get("source_rom", {})
	if not source_rom is Dictionary or str(source_rom.get("sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("The player-state manifest targets a different ROM revision.")
	var manifest_resources: Variant = manifest.get("resources", {})
	if not manifest_resources is Dictionary:
		return _fail("The player-state manifest has no resource table.")

	for filename in RESOURCE_HASHES:
		var path: String = RESOURCE_ROOT + str(filename)
		if not FileAccess.file_exists(path):
			return _fail("A required ROM-derived state resource is missing: %s" % filename)
		var bytes := FileAccess.get_file_as_bytes(path)
		var row_variant: Variant = manifest_resources.get(filename, {})
		if not row_variant is Dictionary:
			return _fail("The manifest has no metadata for %s." % filename)
		var row: Dictionary = row_variant
		var expected_hash := str(RESOURCE_HASHES[filename])
		if _sha256(bytes) != expected_hash or str(row.get("sha256", "")) != expected_hash:
			return _fail("ROM-derived resource hash mismatch: %s" % filename)
		match filename:
			"match_00_home_roster.bin":
				_roster = bytes
			"stamina_profile_values_AE86_AFAE.bin":
				_stamina_profiles = bytes
			"stamina_value_words_9F0E_9FCD.bin":
				_stamina_value_words = bytes

	_profile_map = _load_verified_menu_bytes("player_stat_profile_map_00_22.bin", PROFILE_MAP_SHA256, 35 * 4)
	if _profile_map.is_empty():
		return false
	_record_pointers = _load_verified_menu_bytes("player_record_pointer_table_22.bin", RECORD_POINTERS_SHA256, 22 * 2)
	if _record_pointers.is_empty():
		return false
	if _roster.size() != 12 or _stamina_profiles.size() != 0x128 or _stamina_value_words.size() != 0xC0:
		return _fail("ROM-derived player-state tables have unexpected dimensions.")
	return true


func _load_verified_menu_bytes(filename: String, expected_hash: String, expected_size: int) -> PackedByteArray:
	var path := MENU_DATA_ROOT + filename
	if not FileAccess.file_exists(path):
		_fail("A required ROM-derived menu table is missing: %s" % filename)
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() != expected_size or _sha256(bytes) != expected_hash:
		_fail("ROM-derived menu table hash/size mismatch: %s" % filename)
		return PackedByteArray()
	return bytes


func _build_fresh_home_records() -> bool:
	_players.clear()
	for slot in range(11):
		var player_id := int(_roster[slot])
		if player_id < 1 or player_id > 0x22:
			return _fail("The match-00 home roster contains an unsupported fresh-start player ID.")
		var profile_id := int(_profile_map[player_id * 4])
		var maximum_energy := _calculate_max_stamina(profile_id, 0)
		if maximum_energy < 0:
			return _fail("ROM stamina lookup failed for roster slot %d." % slot)
		var pointer_offset := slot * 2
		var record_address := int(_record_pointers[pointer_offset]) | (int(_record_pointers[pointer_offset + 1]) << 8)
		_players.append({
			"player_slot_index": slot,
			"record_address": record_address,
			"player_id": player_id,
			"level": 0,
			"profile_id": profile_id,
			"max_energy": maximum_energy,
			"current_energy": maximum_energy,
		})
	return true


func _calculate_max_stamina(profile_id: int, level: int) -> int:
	if profile_id < 0 or profile_id >= 0x25 or level < 0 or level > 0xFF:
		return -1
	var stamina_base_index := int(_stamina_profiles[profile_id * 8])
	var value_index := mini(0x5F, stamina_base_index + level)
	var word_offset := value_index * 2
	return int(_stamina_value_words[word_offset]) | (int(_stamina_value_words[word_offset + 1]) << 8)


func _apply_e2bc_regeneration_and_run_cost() -> void:
	# ROM `$E2BC` increments `$0618`; when that byte wraps to zero, its `BCC`
	# skips the teammate regeneration loop but continues into holder charging.
	stamina_regen_skip_counter = (stamina_regen_skip_counter + 1) & 0xFF
	if stamina_regen_skip_counter != 0:
		for slot in range(_players.size()):
			if slot == active_ball_player_slot:
				continue
			var record: Dictionary = _players[slot]
			var player_id := int(record["player_id"])
			var energy := int(record["current_energy"])
			if player_id == MISUGI_ID:
				if energy > 0:
					energy += 1
			else:
				energy += 2
			record["current_energy"] = mini(int(record["max_energy"]), energy)
			_players[slot] = record

	if active_ball_player_slot < 0 or active_ball_player_slot >= _players.size():
		return
	var holder: Dictionary = _players[active_ball_player_slot]
	var run_cost := MISUGI_RUN_COST if int(holder["player_id"]) == MISUGI_ID else NORMAL_RUN_COST
	holder["current_energy"] = maxi(0, int(holder["current_energy"]) - run_cost)
	_players[active_ball_player_slot] = holder


func _reset() -> void:
	error_message = ""
	route_identity = ""
	input_timeline_sha256 = ""
	rng_source_mode = ""
	receiver_source_frame = -1
	receiver_slot = -1
	active_ball_player_slot = -1
	field_run_timer = FIELD_RUN_TIMER_INITIAL
	stamina_update_count = 0
	stamina_regen_skip_counter = 0
	_roster.clear()
	_stamina_profiles.clear()
	_stamina_value_words.clear()
	_profile_map.clear()
	_record_pointers.clear()
	_players.clear()
	_configured = false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
