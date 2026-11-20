extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const MENU_INPUT = preload("res://scripts/gameplay/first_action_menu_input.gd")
const RNG_SCHEDULE := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const AUDITED_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"

var _confirmation_requests: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	route.vm.stop()
	route.route_stage = KickoffRouteRuntime.RouteStage.MATCH_SETUP_GAP

	var rng_replay := RNG_REPLAY_SCRIPT.new() as RomKickoffRngSourceReplay
	assert(rng_replay.configure(RNG_SCHEDULE, AUDITED_INPUT_SHA256), "Audited ROM input route should configure the RNG replay.")
	assert(rng_replay.advance_to_source_frame(rng_replay.receiver_source_frame), "ROM RNG replay should reach the receiver selection.")
	var provider := PLAYER_STATE_PROVIDER_SCRIPT.new() as RomFreshKickoffMatchStateProvider
	assert(provider.configure_from_receiver_replay(rng_replay), "ROM player-state provider should configure from the verified receiver event.")
	assert(route.bind_match_player_state_provider(provider), "Route should accept a configured ROM-derived match-state provider.")
	route.route_stage = KickoffRouteRuntime.RouteStage.FIELD_RUNNING
	for _tick in 10:
		assert(not route.report_eligible_field_loop_iteration(), "The ROM timer should not update energy before the eleventh eligible field iteration.")
	assert(route.report_eligible_field_loop_iteration(), "The route should forward the eleventh eligible source iteration to the player-state provider.")
	route.route_stage = KickoffRouteRuntime.RouteStage.MATCH_SETUP_GAP
	assert(route.install_first_action_menu_from_provider(), "First action panel should install from provider-owned ROM-derived state.")
	route.action_confirmation_requested.connect(_on_action_confirmation_requested)
	assert(route.get_route_status()["stage"] == "first_action_menu")
	assert(route.get_route_status()["first_action_menu_complete"], "All dynamic menu rows must resolve from supplied match state.")
	assert(provider.get_controlled_player_state().current_energy == 397, "One source timer update derives 397 energy from ROM max-stamina and run-cost data.")
	assert(route.get_route_status()["selected_action_id"] == MENU_INPUT.ActionId.NONE, "Fresh menu starts without a selected action.")
	assert(route.get_route_status()["action_label_blink_visible"] == false, "No action label should blink before a direction edge.")

	var direction := InputEventKey.new()
	direction.keycode = KEY_RIGHT
	direction.pressed = true
	assert(route._menu_input.handle_input_event(direction), "Right direction should be accepted.")
	route._menu_input.flush_pending_input()
	assert(route.get_route_status()["selected_action_id"] == MENU_INPUT.ActionId.SHOOT)
	assert(route.get_route_status()["action_label_blink_visible"] == true)

	var key_cases: Array[Dictionary] = [
		{"key": KEY_RIGHT, "action": MENU_INPUT.ActionId.SHOOT, "direction": MENU_INPUT.DirectionIndex.RIGHT},
		{"key": KEY_LEFT, "action": MENU_INPUT.ActionId.PASS, "direction": MENU_INPUT.DirectionIndex.LEFT},
		{"key": KEY_DOWN, "action": MENU_INPUT.ActionId.ONE_TWO_PASS, "direction": MENU_INPUT.DirectionIndex.DOWN},
		{"key": KEY_UP, "action": MENU_INPUT.ActionId.DRIBBLE, "direction": MENU_INPUT.DirectionIndex.UP},
	]
	for test_case in key_cases:
		assert(_send_key(route, int(test_case["key"])), "Keyboard direction should be accepted: %s" % test_case)
		assert(_selection_matches(route, int(test_case["action"]), int(test_case["direction"])),
			"Keyboard direction did not match the ROM menu mapping: %s" % test_case)

	var pad_cases: Array[Dictionary] = [
		{"button": JOY_BUTTON_DPAD_RIGHT, "action": MENU_INPUT.ActionId.SHOOT, "direction": MENU_INPUT.DirectionIndex.RIGHT},
		{"button": JOY_BUTTON_DPAD_LEFT, "action": MENU_INPUT.ActionId.PASS, "direction": MENU_INPUT.DirectionIndex.LEFT},
		{"button": JOY_BUTTON_DPAD_DOWN, "action": MENU_INPUT.ActionId.ONE_TWO_PASS, "direction": MENU_INPUT.DirectionIndex.DOWN},
		{"button": JOY_BUTTON_DPAD_UP, "action": MENU_INPUT.ActionId.DRIBBLE, "direction": MENU_INPUT.DirectionIndex.UP},
	]
	for test_case in pad_cases:
		assert(_send_joypad_button(route, int(test_case["button"])), "Controller direction should be accepted: %s" % test_case)
		assert(_selection_matches(route, int(test_case["action"]), int(test_case["direction"])),
			"Controller direction did not match the ROM menu mapping: %s" % test_case)

	# Return to the existing blink check's selection using navigation only.
	assert(_send_key(route, KEY_RIGHT), "Keyboard Right should remain navigable after controller input.")
	assert(_selection_matches(route, MENU_INPUT.ActionId.SHOOT, MENU_INPUT.DirectionIndex.RIGHT))
	assert(_confirmation_requests.is_empty(), "Navigation must not request action confirmation.")

	for _tick in 13:
		route._advance_route_source_tick()
	assert(route.get_route_status()["action_label_blink_visible"] == false, "ROM `$061F` period should toggle the first visible label after 13 source ticks.")
	for _tick in 13:
		route._advance_route_source_tick()
	assert(route.get_route_status()["action_label_blink_visible"] == true)
	assert(route._visuals._action_menu_panel.selected_action_id == MENU_INPUT.ActionId.SHOOT)
	assert(route._visuals._action_menu_panel.selected_action_visible, "The ROM action name remains only a presentation overlay; no action was confirmed.")

	print("PASS: ROM-derived route menu starts unselected; all keyboard and controller directions select the ROM-mapped actions without requesting confirmation; the label toggles every 13 modeled source ticks.")
	print("LIMIT: this starts from the audited input-hash RNG provider fixture, not a live held-B field route. It does not verify physical hardware, same-input selection pixels, or full-route timing.")
	route.queue_free()
	await process_frame
	quit(0)


func _send_key(route: KickoffRouteRuntime, key_code: Key) -> bool:
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = true
	var handled: bool = route._menu_input.handle_input_event(event)
	route._menu_input.flush_pending_input()
	return handled


func _send_joypad_button(route: KickoffRouteRuntime, button_index: JoyButton) -> bool:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	var handled: bool = route._menu_input.handle_input_event(event)
	route._menu_input.flush_pending_input()
	return handled


func _selection_matches(route: KickoffRouteRuntime, expected_action: int,
		expected_direction: int) -> bool:
	var status := route.get_route_status()
	return route._menu_input.selected_action_id == expected_action \
		and route._menu_input.selected_direction_index == expected_direction \
		and int(status.get("selected_action_id", MENU_INPUT.ActionId.NONE)) == expected_action \
		and String(status.get("stage", "")) == "first_action_menu" \
		and _confirmation_requests.is_empty()


func _on_action_confirmation_requested(action_id: int) -> void:
	_confirmation_requests.append(action_id)
