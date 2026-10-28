extends SceneTree
## Focused contract check for caller-fed ROM RNG events and menu player-state
## handoff. Synthetic RAM is used only as arithmetic input; it is not a runtime
## asset, endpoint capture, or claim that the live route already emits events.

const RNG_EVENT_STREAM := preload("res://scripts/gameplay/rom_kickoff_rng_source_event_stream.gd")
const PLAYER_STATE_PROVIDER := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const ROM_ROSTER_PATH := "res://reference/rom_extract/gameplay/first_match_player_state/match_00_home_roster.bin"

var _failures: Array[String] = []


func _initialize() -> void:
	var stream: RefCounted = RNG_EVENT_STREAM.new()
	_check(stream.configure_from_project_sources(), "ROM instruction/table spans configure: " + stream.error_message)
	_check(stream.begin_after_rom_cold_reset(), "Stream starts from the ROM cold-reset RNG state.")
	var premature_provider: RomFreshKickoffMatchStateProvider = PLAYER_STATE_PROVIDER.new()
	_check(not premature_provider.configure_from_source_event_stream(stream),
		"Player records are withheld until the source $DB05 receiver event exists.")
	_check(not stream.accept_a117_call(0x02, 0xA118, 1, 0x10, Vector3i(0, 0, 0)),
		"A117 rejects a non-source instruction PC.")
	_check(not stream.accept_a117_call(0x02, 0xA117, 0, 0x10, Vector3i(0, 0, 0)),
		"A117 rejects a conflicting NMI mode.")
	_check(not stream.accept_a117_call(0x02, 0xA117, 1, 0x100, Vector3i(0, 0, 0)),
		"A117 rejects an invalid controller-state byte.")
	_check(not stream.accept_a117_call(0x02, 0xA117, 1, 0x10, Vector3i(0, 0, 1)),
		"A117 rejects a source pre-state that skips or duplicates RNG updates.")
	_check(stream.accept_a117_call(0x02, 0xA117, 1, 0x10, Vector3i(0, 0, 0)),
		"A117 accepts its bank/PC/mode/input event with matching source pre-state.")
	_check(stream.get_source_status().get("e1") == 0x83
		and stream.get_source_status().get("e2") == 0x0D
		and stream.get_source_status().get("e3") == 0x11,
		"ROM A117 arithmetic advances the source-owned RNG tuple.")

	var ram := PackedByteArray()
	ram.resize(0x0800)
	ram.fill(0)
	ram[0x00E1] = 0x83
	ram[0x00E2] = 0x0D
	ram[0x00E3] = 0x11
	ram[0x0383] = 0x07
	ram[0x0783] = 0x02
	ram[0x0003] = 0x04 # CPU $0803 aliases physical RAM $0003 for X=$83.
	var read_0300_x := int(ram[(0x0300 + 0x83) & 0x07FF])
	var read_0700_x := int(ram[(0x0700 + 0x83) & 0x07FF])
	var read_0780_x := int(ram[(0x0780 + 0x83) & 0x07FF])
	_check(not stream.accept_c9c5_call(0x1E, 0xC9C5, 0x1E, 0xC7E4,
		0, 0, read_0300_x, read_0700_x, read_0780_x, Vector3i(0x83, 0x0D, 0x11)),
		"C9C5 rejects a conflicting incoming carry.")
	_check(not stream.accept_c9c5_call(0x1E, 0xC9C5, 0x1E, 0xC7E4,
		0, 1, read_0300_x, read_0700_x, read_0780_x, Vector3i(0x83, 0xBE, 0x11)),
		"C9C5 rejects stale/captured RNG register state that conflicts with the source stream.")
	_check(stream.accept_c9c5_call(0x1E, 0xC9C5, 0x1E, 0xC7E4,
		0, 1, read_0300_x, read_0700_x, read_0780_x, Vector3i(0x83, 0x0D, 0x11)),
		"C9C5 accepts only the decoded normal-NMI call context and its three named source reads.")
	_check(stream.get_source_status().get("e1") == 0x84
		and stream.get_source_status().get("e2") == 0x29
		and stream.get_source_status().get("e3") == 0xA9,
		"C9C5 arithmetic uses the live RAM operands and 2 KiB mirroring.")

	_check(not stream.resolve_receiver_at_db05(0x1E, 0xDB06, 0, Vector3i(0x84, 0x29, 0xA9)),
		"Receiver resolution rejects an unrelated PC.")
	_check(stream.resolve_receiver_at_db05(0x1E, 0xDB05, 0, Vector3i(0x84, 0x29, 0xA9)),
		"Receiver resolution accepts the decoded ROM $DB05 event and fresh $05FB byte.")
	var selection: Dictionary = stream.get_receiver_selection()
	_check(bool(selection.get("ready", false)) and int(selection.get("receiver_slot", -1)) == 6,
		"ROM $DC82 offset table resolves the source E2 value to home slot 6.")

	var provider: RomFreshKickoffMatchStateProvider = PLAYER_STATE_PROVIDER.new()
	_check(provider.configure_from_source_event_stream(stream),
		"Provider builds match records only after source receiver selection: " + provider.error_message)
	var player_state := provider.get_controlled_player_state()
	var roster := FileAccess.get_file_as_bytes(ROM_ROSTER_PATH)
	_check(player_state != null and player_state.player_slot_index == 6
		and player_state.player_id == int(roster[6]) and player_state.player_id == 0x08
		and player_state.current_energy == 0x0190 and player_state.level == 0,
		"Menu player state derives slot, player ID, energy and level from the ROM roster/stat data.")
	var source_status: Dictionary = provider.get_source_status()
	_check(str(source_status.get("rng_source_mode", "")) == "decoded_instruction_event_stream"
		and str(source_status.get("input_timeline_sha256", "")) == ""
		and int(source_status.get("receiver_source_frame", -1)) == -1,
		"Live event mode has no recorded frame or input-hash binding.")
	_check(not stream.get_source_status().has("frame")
		and not stream.get_source_status().has("endpoint_ram")
		and _c9c5_signature_has_only_named_reads(stream),
		"The C9C5 contract has no frame or bulk/endpoint-RAM input; it accepts only three source read bytes.")

	if _failures.is_empty():
		print("PASS: caller-fed A117/C9C5/DB05 source events produce ROM-derived receiver and menu player state.")
		print("LIMIT: the live route must still produce the decoded NMI/input events and three current C9C5 RAM reads; this verifier does not generate them or prove full-route integration.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _c9c5_signature_has_only_named_reads(stream: Object) -> bool:
	for method_variant in stream.get_method_list():
		if not method_variant is Dictionary:
			continue
		var method: Dictionary = method_variant
		if str(method.get("name", "")) != "accept_c9c5_call":
			continue
		var names: Array[String] = []
		for argument_variant in method.get("args", []):
			if argument_variant is Dictionary:
				names.append(str(argument_variant.get("name", "")))
		return names.has("read_0300_x_at_c9c8") \
			and names.has("read_0700_x_at_c9cb") \
			and names.has("read_0780_x_at_c9dc") \
			and not names.has("frame") \
			and not names.has("endpoint_ram") \
			and not names.has("source_internal_ram")
	return false
