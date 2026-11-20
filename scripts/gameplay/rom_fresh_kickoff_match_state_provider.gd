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
const PLAYER_STAT_PROFILES_SHA256 := "3236a005cc380c17351cf6ebac20f3f090be2a0a67ba6d8849cd8e6bcaf95fff"

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
var live_source_energy_boundary_applied := false

var _roster: PackedByteArray = PackedByteArray()
var _stamina_profiles: PackedByteArray = PackedByteArray()
var _stamina_value_words: PackedByteArray = PackedByteArray()
var _profile_map: PackedByteArray = PackedByteArray()
var _record_pointers: PackedByteArray = PackedByteArray()
var _player_stat_profiles: PackedByteArray = PackedByteArray()
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


## Replaces the provider's initial table values with the live slot-$05 RAM only
## after a source-traced `$D193->$E1F1->$E1F7->$E2BC` return proves the run-cost
## writes. This rejects emulator/capture state and unverified endpoint values.
func synchronize_from_verified_live_source(boundary: Dictionary,
		transition: Dictionary) -> bool:
	if not _configured:
		return _fail("Configure the ROM player-state provider before syncing live source records.")
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var transition_calls: Array = transition.get("source_calls", [])
	var transition_pcs: Array = transition.get("source_pcs", [])
	var source_span: Dictionary = transition.get("source_span", {})
	var writes: Array = transition.get("holder_energy_writes", [])
	var live_source_records: Array = transition.get("live_player_records", [])
	if not ram_variant is PackedByteArray:
		return _fail("Live source boundary has no RAM image.")
	var ram: PackedByteArray = ram_variant
	if String(boundary.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xD5EA \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or ram.size() != 0x800 or ram.slice(0x0100, 0x0200) != boundary.get("stack_page", PackedByteArray()):
		return _fail("Live source RAM is not the verified unselected `$D5EA` slot-$05 endpoint.")
	if not bool(transition.get("ok", false)) \
			or String(transition.get("kind", "")) != "rom_d193_e1f1_e1f7_e2bc_stamina_update" \
			or String(transition.get("rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or int(transition.get("record_address", -1)) < 0 \
			or int(transition.get("energy_after", -1)) < 0 \
			or int(transition.get("energy_after", -1)) >= int(transition.get("energy_before", 0)) \
			or not transition_pcs.has(0xE1F1) or not transition_pcs.has(0xE1F7) \
			or not transition_pcs.has(0xE2BC) \
			or String(source_span.get("file", "")) != "fixed_field_entry_setup_E0E9_E349.bin" \
			or String(source_span.get("sha256", "")) != \
				"069aa6c733b9de0a6070e280f89277a4ec192f1c551001fb787e9038244806de" \
			or writes.size() < 2 or live_source_records.size() != _players.size():
		return _fail("The source worker receipt does not prove the D193-to-E2BC stamina call and energy stores.")
	var holder_call_seen := false
	for call_variant in transition_calls:
		if call_variant is Dictionary and int(call_variant.get("callsite", -1)) == 0xE1F7 \
				and int(call_variant.get("target", -1)) == 0xE2BC:
			holder_call_seen = true
	if not holder_call_seen:
		return _fail("The source worker receipt omits the `$E1F7->$E2BC` call.")
	var holder_slot := int(transition.get("player_slot", -1))
	if holder_slot != active_ball_player_slot or holder_slot < 0 or holder_slot >= _players.size():
		return _fail("Live stamina receipt targets a different ROM-selected ball holder.")
	var holder: Dictionary = _players[holder_slot]
	if int(holder.get("record_address", -1)) != int(transition.get("record_address", -2)) \
			or int(holder.get("player_id", -1)) != int(transition.get("player_id", -2)):
		return _fail("Live stamina receipt's player pointer or ID differs from the ROM-derived roster.")
	var entry_energy := int(transition.get("energy_before", -1))
	var resulting_energy := int(transition.get("energy_after", -1))
	var expected_cost := MISUGI_RUN_COST if int(holder["player_id"]) == MISUGI_ID else NORMAL_RUN_COST
	if resulting_energy != maxi(0, entry_energy - expected_cost):
		return _fail("ROM `$E2BC` holder run cost differs from the ROM-defined player rule.")
	if stamina_update_count != 0 or stamina_regen_skip_counter != 0:
		return _fail("This live-source handoff only supports the first `$E2BC` update from the fresh field state.")
	var synchronized_players: Array[Dictionary] = []
	for slot in range(_players.size()):
		var record: Dictionary = _players[slot]
		var address := int(record.get("record_address", -1))
		if address < 0 or address + 3 >= ram.size() \
				or int(ram[address]) != int(record.get("player_id", -1)) \
				or int(ram[address + 3]) != int(record.get("level", -1)):
			return _fail("Live RAM record %d does not match the ROM-derived roster and level." % slot)
		var energy := int(ram[address + 1]) | (int(ram[address + 2]) << 8)
		var live_record_variant: Variant = live_source_records[slot]
		if not live_record_variant is Dictionary:
			return _fail("The live ROM worker receipt has no player-record row for roster slot %d." % slot)
		var live_record: Dictionary = live_record_variant
		if int(live_record.get("slot", -1)) != slot \
				or int(live_record.get("record_address", -1)) != address \
				or int(live_record.get("player_id", -1)) != int(record.get("player_id", -1)) \
				or int(live_record.get("level", -1)) != int(record.get("level", -1)) \
				or int(live_record.get("energy", -1)) != energy \
				or String(live_record.get("record_bytes", "")) != ram.slice(address, address + 4).hex_encode():
			return _fail("Live player record %d differs from the ROM worker's verified RAM output." % slot)
		var expected_energy := int(record.get("max_energy", -1))
		if slot == holder_slot:
			expected_energy = maxi(0, int(record.get("current_energy", -1)) - expected_cost)
		else:
			var player_id := int(record.get("player_id", -1))
			var regeneration := 1 if player_id == MISUGI_ID else 2
			expected_energy = mini(expected_energy,
				int(record.get("current_energy", -1)) + regeneration)
		if energy != expected_energy:
			return _fail("Live `$E2BC` output for slot %d differs from its ROM-derived cap/regeneration rule." % slot)
		record["current_energy"] = energy
		synchronized_players.append(record)
	if (int(ram[int(holder["record_address"]) + 1]) \
			| (int(ram[int(holder["record_address"]) + 2]) << 8)) != resulting_energy:
		return _fail("Live `$D5EA` RAM does not contain the worker's `$E2BC` holder result.")
	_players = synchronized_players
	field_run_timer = int(ram[0x0614])
	stamina_update_count = 1
	stamina_regen_skip_counter = 1
	live_source_energy_boundary_applied = true
	return true


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
		"live_source_energy_boundary_applied": live_source_energy_boundary_applied,
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
	_player_stat_profiles = _load_verified_menu_bytes("player_stat_profiles_00_8c.bin",
		PLAYER_STAT_PROFILES_SHA256, 0x8D * 0x18)
	if _player_stat_profiles.is_empty():
		return false
	if _roster.size() != 12 or _stamina_profiles.size() != 0x128 \
			or _stamina_value_words.size() != 0xC0 \
			or _player_stat_profiles.size() != 0x8D * 0x18:
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
		var maximum_energy := _calculate_max_stamina(slot, profile_id, 0)
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


func _calculate_max_stamina(home_slot: int, profile_id: int, level: int) -> int:
	if home_slot < 0 or home_slot >= 11 or profile_id < 0 or profile_id >= 0x25 \
			or level < 0 or level > 0xFF:
		return -1
	var use_common_profile_row := home_slot == 0 or home_slot == 0x0B \
		or home_slot == 0x1E or home_slot == 0x1F
	# `$80D1-$80F6` forms `$9FCE + profile_id * 24` for ordinary
	# selectors; `$00/$0B/$1E/$1F` instead resolve the shared `$AE86` rows.
	# The first-action-menu extraction preserves the complete 24-byte rows.
	var stamina_base_index := int(_stamina_profiles[profile_id * 8]) \
		if use_common_profile_row else int(_player_stat_profiles[profile_id * 0x18])
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
	live_source_energy_boundary_applied = false
	_roster.clear()
	_stamina_profiles.clear()
	_stamina_value_words.clear()
	_player_stat_profiles.clear()
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
