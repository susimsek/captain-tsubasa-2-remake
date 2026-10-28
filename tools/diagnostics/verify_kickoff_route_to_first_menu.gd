extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const MENU_INPUT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const PPU_REFERENCE := "res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	var vm_error := [""]
	var cutscene_returns: Array[Dictionary] = []
	route.vm.vm_error.connect(func(message: String) -> void: vm_error[0] = message)
	route.cutscene_return_requested.connect(func(cutscene_id: int, completion_kind: String) -> void:
		cutscene_returns.append({"cutscene_id": cutscene_id, "completion_kind": completion_kind})
	)

	# Skip ID 1 to the ROM-observed matchup card, then enter scene $44.
	route.call("_unhandled_input", _key(KEY_TAB))
	route.call("_advance_route_source_tick")
	_check(route.get_route_status()["stage"] == "matchup_presentation", "ID 1 Select reaches matchup presentation")
	_check(cutscene_returns.size() == 1
		and int(cutscene_returns[0].get("cutscene_id", -1)) == 1
		and str(cutscene_returns[0].get("completion_kind", "")) == "select",
		"ID 1 Select exit is exposed as an explicit route continuation event")
	route.call("_unhandled_input", _key(KEY_Z))
	route.call("_unhandled_input", _key_up(KEY_Z))
	_check(route.get_route_status()["stage"] == "meeting_scene", "A enters ROM scene $44")
	for _tick in 8:
		route.call("_advance_route_source_tick")
	_check(route.get_route_status()["stage"] == "meeting_menu", "scene $44 opens the MEETING menu")
	_check(route.get_route_status()["meeting_cursor_y"] == 0x98, "MEETING cursor begins on its first ROM row")

	var meeting_input: Node = route.get_node("PreMatchMeetingMenuInput")
	for _row in 3:
		meeting_input.call("handle_input_event", _key(KEY_DOWN))
		route.call("_advance_route_source_tick")
	_check(route.get_route_status()["meeting_cursor_y"] == 0xC8, "three Down edges reach the $06 KICKOFF row")
	meeting_input.call("handle_input_event", _key(KEY_Z))
	route.call("_advance_route_source_tick")
	await process_frame
	_check(route.get_route_status()["stage"] == "cutscene_2", "confirming $06 starts ROM cutscene ID 2")

	# The captured route's Select skips the card. ROM source order establishes
	# match context before the A/B wait; player coordinates follow the held poll.
	route.call("_unhandled_input", _key(KEY_TAB))
	route.call("_advance_route_source_tick")
	_check(route.get_route_status()["stage"] == "kickoff_setup_gate", "ID 2 Select reaches the kickoff A/B gate")
	_check(cutscene_returns.size() >= 3
		and int(cutscene_returns[cutscene_returns.size() - 1].get("cutscene_id", -1)) == 2
		and str(cutscene_returns[cutscene_returns.size() - 1].get("completion_kind", "")) == "select",
		"ID 2 Select exit is exposed separately from natural completion")
	var gate_status := route.get_route_status()
	_check(bool(gate_status.get("fresh_match_context", {}).get("ok", false))
		and gate_status.get("initial_player_positions", []).is_empty(),
		"source match context exists before A/B while player positions remain pending")
	var slot5_dispatch: Dictionary = gate_status.get("fresh_scheduler_dispatch", {})
	_check(bool(slot5_dispatch.get("ok", false))
		and int(slot5_dispatch.get("pc", -1)) == 0xD11E
		and int(slot5_dispatch.get("sp", -1)) == 0x52
		and int(slot5_dispatch.get("slot01_yield_pc", -1)) == 0xCA4F,
		"route derives slot-$05 entry from the ROM bootstrap and slot-$01 source yield")
	var period_task: Dictionary = gate_status.get("fresh_period_task", {})
	var period_ram: Dictionary = period_task.get("ram", {})
	_check(bool(period_task.get("ok", false))
		and int(period_task.get("exit_pc", -1)) == 0xDAAA
		and int(period_ram.get("$0629", -1)) == 0,
		"route derives fresh selector $0629 from the bounded ROM period task")
	_verify_source_match_context(route)
	route.call("_unhandled_input", _key(KEY_Z))
	route.call("_advance_route_source_tick")
	_check(int(route.get_route_status()["held_kickoff_input_bits"]) == 0x80,
		"kickoff gate consumes the held NES A bit at its source poll")
	route.call("_unhandled_input", _key_up(KEY_Z))
	_check(route.get_route_status()["stage"] == "kickoff_narration", "A satisfies the ROM kickoff gate")
	_verify_source_player_positions(route)
	route.call("_unhandled_input", _key(KEY_TAB))
	route.call("_advance_route_source_tick")
	print("Field transition status: ", route.get_route_status()["stage"], " ", route._visuals.first_match_field_status)
	_check(route.get_route_status()["stage"] == "field_running", "Select exits kickoff narration into the source field loop")
	_check(route._visuals.first_match_field_status.is_empty(), "field candidate is deferred until the captured B/menu edge")

	route.call("_unhandled_input", _key(KEY_X))
	route.call("_advance_route_source_tick")
	_check(route.get_route_status()["active_background_id"] == 0x01, "B loads the ROM-data-backed field candidate")
	# Exercise beyond the old 60-tick placeholder window. Without a decoded
	# callback/task event, the route must remain pending and must not fabricate
	# a menu request from elapsed time.
	for _tick in 61:
		route.call("_advance_route_source_tick")
	_check(route.get_route_status()["stage"] == "first_action_menu_pending", "B reaches the first-menu pending boundary")
	_check(not route.get_route_status()["first_action_menu_complete"], "menu remains hidden until its source packets and player state exist")
	_check(route.get_route_status()["selected_action_id"] == MENU_INPUT.ActionId.NONE,
		"no soccer action is selected while the source event is missing")
	var packet_status: Dictionary = route._visuals.first_match_field_status.get("residual_packet_producer", {})
	_check(not bool(packet_status.get("applied", true))
		and str(packet_status.get("status", "")) == "awaiting_route_source_state",
		"live route does not inject endpoint RAM/PPU into the F015 packet path")
	_verify_selector_correct_field_maps(route)
	_check(vm_error[0].is_empty(), "all dispatched source streams validate")
	_check(route.action_confirmation_requested.get_connections().is_empty(), "no soccer action was confirmed")

	if _failures == 0:
		print("PASS: Godot route runs title-choice handoff → ID 1 → scene $44/MEETING → ID 2 → kickoff gate/narration → field/menu pending.")
		print("LIMIT: the task-context model is diagnostic-only and supplies no live $8327 event or previous $05CD; no fixed wait or endpoint snapshot creates the menu.")
	else:
		printerr("FAIL: %d full-route assertion(s)" % _failures)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


var _failures := 0


func _verify_selector_correct_field_maps(route: KickoffRouteRuntime) -> void:
	if not FileAccess.file_exists(PPU_REFERENCE):
		print("LIMIT: endpoint PPU validation file is absent; ROM-derived map data still runs, but pixel-byte comparison is skipped.")
		return
	var reference := FileAccess.get_file_as_bytes(PPU_REFERENCE)
	_check(reference.size() == 0x4000, "frame-8953 PPU validation snapshot has the expected size")
	if reference.size() != 0x4000:
		return
	var generated: Dictionary = route._visuals.get("_ppu_memory")
	var exact_tiles := 0
	var mismatches: Array[String] = []
	# Page-2 rows 14–29 contain the final two rows of map $36 and the visible
	# first fourteen rows of map $56. Compare the same endpoint PPU bytes only;
	# the snapshot is validation data and never feeds the runtime presenter.
	for offset in 512:
		var address := 0x2800 + 14 * 0x20 + offset
		if int(generated.get(address, -1)) == int(reference[address]):
			exact_tiles += 1
		elif mismatches.size() < 12:
			mismatches.append("$%04X" % address)
	print("ROM-derived map $36/$56 visible page-2 tile IDs match endpoint PPU: %d/512." % exact_tiles)
	_check(exact_tiles == 452, "source maps reproduce the documented 452/512 endpoint tile IDs")
	if exact_tiles != 452:
		printerr("Field tile endpoint result: %d/512; first differing addresses: %s" % [exact_tiles, ", ".join(mismatches)])

	var map36_attributes := _count_exact_bytes(generated, reference, 0x2BC0, 32)
	var map56_attributes := _count_exact_bytes(generated, reference, 0x2BE0, 32)
	print("Map $36/$56 attribute endpoint matches: %d/32 and %d/32." % [map36_attributes, map56_attributes])
	_check(map56_attributes == 26, "selector-$02 map-$56 attributes reproduce the documented 26/32 endpoint bytes")
	_check(generated.has(0x2800) and generated.has(0x2A00), "both source map tile origins are installed")
	_check(generated.has(0x2BC0) and generated.has(0x2BE0), "both source map attribute origins are installed")


func _verify_source_match_context(route: KickoffRouteRuntime) -> void:
	var status := route.get_route_status()
	var context: Dictionary = status.get("fresh_match_context", {})
	_check(bool(context.get("ok", false)), "pre-A/B source setup derives match context from preserved ROM logic")
	_check(int(context.get("match_index", -1)) == 0
		and int(context.get("kickoff_selector_0629", -1)) == 0
		and int(context.get("kickoff_branch_address", -1)) == 0xDB34,
		"fresh route derives match zero and selector-zero branch $DB34")
	_check(int(context.get("home_team_id", -1)) == 0
		and int(context.get("opponent_id", -1)) == 3
		and int(context.get("formation_002c", -1)) == 0
		and int(context.get("formation_002e", -1)) == 0
		and int(context.get("possession_side_05fb", -1)) == 0,
		"match-zero formations and home possession come from the source resolver")


func _verify_source_player_positions(route: KickoffRouteRuntime) -> void:
	var positions: Array = route.get_route_status().get("initial_player_positions", [])
	_check(positions.size() == 22, "A/B-held source transition derives all 22 player-record positions")
	if positions.size() == 22 and positions[6] is Dictionary:
		var slot_six: Dictionary = positions[6]
		_check(int(slot_six.get("record_address", -1)) == 0x0348
			and int(slot_six.get("table_index", -1)) == 6
			and str(slot_six.get("table_id", "")) == "$DC87",
			"post-A/B slot-six position uses the source pointer and formation-zero table")


func _count_exact_bytes(generated: Dictionary, reference: PackedByteArray,
		address: int, count: int) -> int:
	var exact := 0
	for offset in count:
		if int(generated.get(address + offset, -1)) == int(reference[address + offset]):
			exact += 1
	return exact


func _key(key_code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = true
	return event


func _key_up(key_code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = false
	return event


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
