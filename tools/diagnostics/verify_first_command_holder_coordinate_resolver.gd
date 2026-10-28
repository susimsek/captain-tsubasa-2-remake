extends SceneTree
## Verifies the ROM-byte holder-record coordinate copy independently of any
## endpoint RAM/PPU files. The holder slot is an explicit test input.

const RESOLVER_SCRIPT := preload("res://scripts/gameplay/rom_first_command_holder_coordinate_resolver.gd")
const POSITION_INITIALIZER_SCRIPT := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	assert(resolver.configure(), "Preserved $E0F6/$E6EC ROM spans must pass exact instruction/hash checks.")
	var resolver_status: Dictionary = resolver.get_source_status()
	assert(bool(resolver_status.get("configured", false)), "Resolver status should report configured.")
	assert(not bool(resolver_status.get("holder_selection_derived", true)),
		"The resolver must not claim to derive the live holder selection.")
	assert(not bool(resolver_status.get("callback_state_modeled", true)),
		"The resolver must not claim to model $05CD/$05CE callback state.")

	var source_context := {
		"kind": "caller_owned_decoded_game_logic",
		"label": "fresh-match-holder-coordinate-verification",
	}
	var initializer = POSITION_INITIALIZER_SCRIPT.new()
	assert(initializer.configure(), "Preserved match-position ROM spans must configure.")
	var positions_result: Dictionary = initializer.initialize_positions(0, 0, 0, 0, source_context)
	assert(bool(positions_result.get("ok", false)), "Fresh match-zero formation positions must derive from ROM tables.")
	var positions: Array = positions_result.get("positions", [])
	assert(positions.size() == 22, "The source position model must contain 22 player records.")

	for slot in range(22):
		var result: Dictionary = resolver.resolve_initial_coordinates(slot, 0, 0, 0, 0, source_context)
		assert(bool(result.get("ok", false)), "ROM holder-coordinate resolver should accept slot %d." % slot)
		var expected: Dictionary = positions[slot]
		assert(int(result.get("record_address", -1)) == int(expected.get("record_address", -2)),
			"Slot %d should use the pointer-table-derived record address." % slot)
		assert(int(result.get("x_0635", -1)) == int(expected.get("x", -2)),
			"Slot %d X must equal ROM-initialized record +6." % slot)
		assert(int(result.get("y_0637", -1)) == int(expected.get("y", -2)),
			"Slot %d Y must equal ROM-initialized record +8." % slot)

	var trace_route_slot: Dictionary = resolver.resolve_initial_coordinates(6, 0, 0, 0, 0, source_context)
	assert(bool(trace_route_slot.get("ok", false)), "Slot-six source-input case must resolve.")
	assert(int(trace_route_slot.get("x_0635", -1)) == 0x7C \
			and int(trace_route_slot.get("y_0637", -1)) == 0xAC,
		"Match-zero formation-0 slot 6 should resolve to $7C/$AC from ROM tables.")
	assert(not bool(trace_route_slot.get("holder_selection_derived", true)),
		"The slot-six unit case is not evidence that the route selects slot 6.")

	var invalid_slot: Dictionary = resolver.resolve_initial_coordinates(22, 0, 0, 0, 0, source_context)
	assert(not bool(invalid_slot.get("ok", true)), "Slots outside the 22-record source range must fail.")
	var capture_context: Dictionary = {
		"kind": "emulator_capture",
		"label": "forbidden-holder-selection-input",
	}
	var capture_input: Dictionary = resolver.resolve_initial_coordinates(6, 0, 0, 0, 0, capture_context)
	assert(not bool(capture_input.get("ok", true)), "Capture-derived holder selection must be rejected.")

	print("Holder-coordinate resolver verified: E0F6→E6EC bytes hash-checked; all 22 coordinates copy source-derived record +6/+8; slot-six unit input yields $7C/$AC; holder selection and callback state remain external.")
	quit(0)
