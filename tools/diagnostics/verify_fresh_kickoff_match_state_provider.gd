extends SceneTree

const RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const SCHEDULE_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/first_match_player_state/"
const MENU_DATA_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const AUDITED_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"


func _initialize() -> void:
	var rng_replay := RNG_REPLAY_SCRIPT.new() as RomKickoffRngSourceReplay
	if not rng_replay.configure(SCHEDULE_PATH, AUDITED_INPUT_SHA256):
		_fail("RNG source replay setup failed: " + rng_replay.error_message)
		return
	if not rng_replay.advance_to_source_frame(rng_replay.receiver_source_frame):
		_fail("RNG source replay could not reach receiver selection: " + rng_replay.error_message)
		return

	var provider := PLAYER_STATE_PROVIDER_SCRIPT.new() as RomFreshKickoffMatchStateProvider
	if not provider.configure_from_receiver_replay(rng_replay):
		_fail("ROM player-state provider setup failed: " + provider.error_message)
		return
	var slot := rng_replay.get_receiver_slot()
	var state := provider.get_controlled_player_state()
	if state == null or state.player_slot_index != slot:
		_fail("Active menu player slot does not come from the receiver replay.")
		return

	var roster := FileAccess.get_file_as_bytes(RESOURCE_ROOT + "match_00_home_roster.bin")
	var stamina_profiles := FileAccess.get_file_as_bytes(RESOURCE_ROOT + "stamina_profile_values_AE86_AFAE.bin")
	var stamina_values := FileAccess.get_file_as_bytes(RESOURCE_ROOT + "stamina_value_words_9F0E_9FCD.bin")
	var profile_map := FileAccess.get_file_as_bytes(MENU_DATA_ROOT + "player_stat_profile_map_00_22.bin")
	var record_pointers := FileAccess.get_file_as_bytes(MENU_DATA_ROOT + "player_record_pointer_table_22.bin")
	if slot < 0 or slot >= 11 or state.player_id != roster[slot]:
		_fail("Active player ID does not resolve through the extracted match-00 ROM roster.")
		return
	var profile_id := int(profile_map[state.player_id * 4])
	if state.stat_profile_id != profile_id:
		_fail("Menu stat profile did not resolve from the ROM's player-profile map.")
		return
	var profile_base := int(stamina_profiles[profile_id * 8])
	var stamina_index := mini(0x5F, profile_base + state.level)
	var value_offset := stamina_index * 2
	var source_maximum := int(stamina_values[value_offset]) | (int(stamina_values[value_offset + 1]) << 8)
	if state.level != 0 or state.current_energy != source_maximum:
		_fail("Fresh-start level/stamina initialization differs from the ROM tables.")
		return
	var pointer_offset := slot * 2
	var source_record_address := int(record_pointers[pointer_offset]) | (int(record_pointers[pointer_offset + 1]) << 8)
	if provider.get_player_record(slot).get("record_address", -1) != source_record_address:
		_fail("Player RAM-record address did not resolve through the ROM pointer table.")
		return

	for iteration in range(10):
		if provider.advance_field_loop_iteration():
			_fail("The run-cost source tick fired before the ROM timer expired.")
			return
	if not provider.advance_field_loop_iteration():
		_fail("The run-cost source tick did not fire on the eleventh eligible field-loop iteration.")
		return
	state = provider.get_controlled_player_state()
	var run_cost := 5 if state.player_id == 0x20 else 3
	var expected_after_tick := maxi(0, source_maximum - run_cost)
	if state.current_energy != expected_after_tick:
		_fail("Holder energy did not use the ROM-derived stamina cost and zero floor.")
		return
	for iteration in range(10):
		if provider.advance_field_loop_iteration():
			_fail("The next run-cost source tick fired before the reset timer expired.")
			return
	if not provider.advance_field_loop_iteration():
		_fail("The second run-cost source tick did not use the ROM timer cadence.")
		return
	var state_after_second_tick := provider.get_controlled_player_state()
	var expected_after_second_tick := maxi(0, expected_after_tick - run_cost)
	if state_after_second_tick.current_energy != expected_after_second_tick:
		_fail("Repeated run-cost source tick produced an incorrect holder-energy state.")
		return
	if not provider.set_active_ball_player_slot(0):
		_fail("The ROM-derived source model rejected a roster slot while preparing the counter-wrap check.")
		return
	for update_index in range(252):
		if not _advance_one_stamina_update(provider):
			_fail("A source-timer update failed while reaching the ROM $0618 wrap boundary.")
			return
	var slot_zero_before_wrap := int(provider.get_player_record(0)["current_energy"])
	if slot_zero_before_wrap != 0:
		_fail("The chosen non-holder was not at zero energy before the wrap check.")
		return
	if not provider.set_active_ball_player_slot(1) or not _advance_one_stamina_update(provider):
		_fail("The source model could not reach $0618=$FF before the wrap update.")
		return
	var slot_zero_on_255 := int(provider.get_player_record(0)["current_energy"])
	if slot_zero_on_255 != 2 or provider.get_source_status()["stamina_regen_skip_counter"] != 0xFF:
		_fail("The ordinary $0618=$FF update did not regenerate the non-holder and retain the byte counter.")
		return
	var holder_before_wrap := int(provider.get_player_record(1)["current_energy"])
	if not _advance_one_stamina_update(provider):
		_fail("The source model did not execute the $0618 wrap update.")
		return
	var slot_zero_after_wrap := int(provider.get_player_record(0)["current_energy"])
	var holder_after_wrap := int(provider.get_player_record(1)["current_energy"])
	if slot_zero_after_wrap != slot_zero_on_255:
		_fail("The $0618 wrap update should skip teammate regeneration.")
		return
	if holder_after_wrap != maxi(0, holder_before_wrap - 3):
		_fail("The $0618 wrap update should still charge the current ball holder.")
		return
	if provider.get_source_status()["stamina_regen_skip_counter"] != 0:
		_fail("The ROM $0618 regeneration counter did not wrap as an 8-bit value.")
		return

	var status: Dictionary = provider.get_source_status()
	print(
		"PASS ROM-derived first-match state: receiver frame %d, slot %d, player ID %d, level %d, max stamina %d; two timer ticks produce energy %d; 256 $0618 ticks verify regeneration wrap/skip and holder cost; profile, roster, pointer, and cost resolved from ROM bytes."
		% [rng_replay.receiver_source_frame, slot, state.player_id, state.level, source_maximum,
			state_after_second_tick.current_energy]
	)
	print(
		"LIMIT: receiver selection is available only for the audited input-hash route; caller must supply each eligible $E14D field-loop iteration and omit iterations preempted by B/menu or other transitions."
	)
	quit(0)


func _advance_one_stamina_update(provider: RomFreshKickoffMatchStateProvider) -> bool:
	for iteration in range(10):
		if provider.advance_field_loop_iteration():
			return false
	return provider.advance_field_loop_iteration()


func _fail(message: String) -> void:
	push_error("Fresh KICK OFF player-state source check failed: " + message)
	quit(1)
