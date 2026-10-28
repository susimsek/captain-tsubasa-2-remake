extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const MENU_INPUT = preload("res://scripts/gameplay/first_action_menu_input.gd")
const RNG_SCHEDULE := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const AUDITED_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"


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

	for _tick in 13:
		route._advance_route_source_tick()
	assert(route.get_route_status()["action_label_blink_visible"] == false, "ROM `$061F` period should toggle the first visible label after 13 source ticks.")
	for _tick in 13:
		route._advance_route_source_tick()
	assert(route.get_route_status()["action_label_blink_visible"] == true)
	assert(route._visuals._action_menu_panel.selected_action_id == MENU_INPUT.ActionId.SHOOT)
	assert(route._visuals._action_menu_panel.selected_action_visible, "The ROM action name remains only a presentation overlay; no action was confirmed.")

	print("PASS: route installs the first menu from the ROM-derived roster/stat/stamina provider, starts unselected, accepts Right=Shoot, and toggles its ROM label every 13 modeled source ticks.")
	print("LIMIT: the provider is bound to the one audited input-hash RNG replay; live route input/RNG and eligible $E14D event production, field actors/raster, and same-input selection pixels remain open.")
	route.queue_free()
	await process_frame
	quit(0)
