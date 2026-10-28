extends SceneTree
## Replays the captured post-title controller edges through the Godot route.
## Capture files are observations only; the harness does not inject captured
## player, RAM, PPU, or audio state into the runtime path.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const EXPECTED_PENDING_BOUNDARY_FRAME := 8953
const OUTPUT_PNG := "/tmp/ct2_godot_first_action_menu_recorded_input.png"

var _failures := 0
var _stage_at_checkpoints: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	route.set_process(false)
	route.source_frame = 4693

	var events := _read_recorded_edges()
	_check(not events.is_empty(), "captured route input edges load")
	var final_frame := EXPECTED_PENDING_BOUNDARY_FRAME
	for source_frame in range(4694, final_frame + 1):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		route.call("_advance_route_source_tick")
		if source_frame in [7243, 7393, 7993, 8443, 8593, 8743, 8893, 8953]:
			var checkpoint := route.get_route_status()
			_stage_at_checkpoints[source_frame] = {
				"stage": checkpoint.get("stage", ""),
				"meeting_cursor_y": checkpoint.get("meeting_cursor_y", -1),
				"first_action_menu_source_pending": checkpoint.get("first_action_menu_source_pending", false),
			}
		if source_frame in [8743, 8788, 8848, 8863, 8893]:
			_save_background_image(route, source_frame)
		if events.has(source_frame):
			# The live route schedules the kickoff script with call_deferred after
			# confirming the meeting menu; yield at real input edges so the test
			# observes the same scene-tree boundary.
			await process_frame

	_check(route.source_frame == EXPECTED_PENDING_BOUNDARY_FRAME, "Godot replay reaches the captured first-panel boundary frame")
	_check(route.get_route_status()["stage"] == "first_action_menu_pending", "path stops before any soccer action")
	_check(not route.get_route_status()["first_action_menu_complete"], "capture snapshot has not silently become a runtime state provider")
	_check(bool(route.get_route_status()["first_action_menu_source_pending"]),
		"route waits for the missing ROM callback/task producer rather than an elapsed-frame delay")
	var packet_status: Dictionary = route._visuals.first_match_field_status.get("residual_packet_producer", {})
	_check(not bool(packet_status.get("applied", true))
		and str(packet_status.get("status", "")) == "awaiting_route_source_state",
		"recorded input does not inject endpoint RAM/PPU values into the packet producer")
	_check(route.get_route_status()["selected_action_id"] == -1,
		"no soccer action exists before the initial command menu has been produced")
	print("Recorded-input stage checkpoints: ", JSON.stringify(_stage_at_checkpoints))
	_save_background_image(route, EXPECTED_PENDING_BOUNDARY_FRAME)

	if _failures == 0:
		print("PASS: recorded post-title inputs replay through Godot to the pending first-menu boundary at source frame %d." % route.source_frame)
		print("LIMIT: no live task/callback state produces the initial menu or its player fields; selected-frame background images do not establish full composition/audio parity.")
	else:
		printerr("FAIL: %d recorded-input route assertion(s)" % _failures)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


func _read_recorded_edges() -> Dictionary:
	var file := FileAccess.open(INPUT_CSV, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	var result: Dictionary = {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		if source_frame <= 4693:
			continue # KICK OFF is already confirmed when this scene starts.
		var edges: Array[String] = []
		for index in range(2, 10):
			if row[index] == "1":
				edges.append(["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"][index - 2])
		if not edges.is_empty():
			result[source_frame] = edges
	return result


func _dispatch_edges(route: KickoffRouteRuntime, edges: Array) -> void:
	for edge in edges:
		var key_code: Key
		match str(edge):
			"Up": key_code = KEY_UP
			"Down": key_code = KEY_DOWN
			"Left": key_code = KEY_LEFT
			"Right": key_code = KEY_RIGHT
			"A": key_code = KEY_Z
			"B": key_code = KEY_X
			"Select": key_code = KEY_TAB
			"Start": continue
			_: continue
		var event := InputEventKey.new()
		event.keycode = key_code
		event.pressed = true
		route.call("_unhandled_input", event)
		var stage := str(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _save_background_image(route: KickoffRouteRuntime, source_frame: int) -> void:
	var image: Image = route._visuals.screen.get_rendered_background_image()
	_check(image != null and not image.is_empty(), "Godot renderer exposes the ROM-backed background image at frame %d" % source_frame)
	if image == null or image.is_empty():
		return
	var path := OUTPUT_PNG.get_basename() + "_%04d.png" % source_frame
	var save_error := image.save_png(path)
	_check(save_error == OK, "background diagnostic image saved at frame %d" % source_frame)
	print("Godot background frame %d: %s (%dx%d; CanvasItem sprites excluded)" % [source_frame, path, image.get_width(), image.get_height()])


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
