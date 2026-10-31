extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const FIRST_SOURCE_GAP_FRAME := 8464

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	var audio_callback := Callable(route, "_on_rom_sound_queue_write_requested")
	if route.rom_sound_queue_write_requested.is_connected(audio_callback):
		route.rom_sound_queue_write_requested.disconnect(audio_callback)
	route.set_process(false)
	route.source_frame = 4693
	var events := _read_recorded_edges()
	_check(not events.is_empty(), "the recorded KICK OFF input edges load")
	var e3ca: Dictionary = {}
	var gap: Dictionary = {}
	var stop_frame := -1
	for source_frame in range(4694, 8954):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		route.call("_advance_route_source_tick")
		if events.has(source_frame):
			await process_frame
		var route_status: Dictionary = route.get_route_status()
		var source_status: Dictionary = route_status.get("fresh_source_route", {})
		if String(source_status.get("phase", "")) == "error":
			stop_frame = source_frame
			gap = source_status
			if route._fresh_source_route_runner != null:
				e3ca = route._fresh_source_route_runner.get_last_root_e3ca_result()
			break
	_check(stop_frame == FIRST_SOURCE_GAP_FRAME,
		"the same recorded route reaches its current ROM-source gap at frame %d (actual %d)" % [FIRST_SOURCE_GAP_FRAME, stop_frame])
	_check(int(gap.get("scheduler", {}).get("active_task_slot", -1)) == 0x09
		and String(gap.get("error", "")).contains("$ED5B"),
		"the actor caller returns through the scheduler to the following live slot-$09 `$ED5B` boundary")
	if not _validate_e3ca(e3ca):
		print("E3CA live summary: ", JSON.stringify(e3ca))
		_check(false, "the production root caller's `$CA55->$E3CA->$CA58->$CA4F` path matches its source contract")
	if _failures == 0:
		print("PASS: recorded-input production route executed the ROM no-direction `$E3CA` callee and selected slot `$09` before the `$ED5B` source gap.")
		print("LIMIT: this source branch has no soccer movement; full match state, field/menu output, PPU/APU timing, and audio remain unresolved.")
	else:
		printerr("FAIL: %d recorded-route E3CA assertion(s)" % _failures)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


func _validate_e3ca(result: Dictionary) -> bool:
	var registers: Dictionary = result.get("registers", {})
	var call_request: Dictionary = result.get("caller_request", {})
	var yield_request: Dictionary = result.get("yield_request", {})
	var writes: Array = result.get("memory_writes", [])
	var expected_pcs: Array[int] = [0xCA55, 0xE3CA, 0xE3CD, 0xE3CF, 0xE3D2, 0xE3D4, 0xE406]
	if String(result.get("status", "")) != "returned_to_source_caller" \
			or not bool(result.get("returned_to_caller", false)) \
			or bool(result.get("movement_applied", true)) \
			or result.get("instruction_pcs", []) != expected_pcs \
			or int(registers.get("pc", -1)) != 0xCA58 \
			or int(registers.get("sp", -1)) != 0x2A \
			or int(registers.get("a", -1)) != 0 \
			or int(call_request.get("source_pc", -1)) != 0xCA55 \
			or int(call_request.get("target_cpu_address", -1)) != 0xE3CA \
			or int(call_request.get("expected_return_pc", -1)) != 0xCA58 \
			or String(yield_request.get("status", "")) != "yield_requested" \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or int(result.get("next_task_slot", -1)) != 0x09 \
			or writes.size() != 2:
		return false
	return true


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
		var frame := int(row[0])
		if frame <= 4693:
			continue
		var edges: Array[String] = []
		for index in range(2, 10):
			if row[index] == "1":
				edges.append(["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"][index - 2])
		if not edges.is_empty():
			result[frame] = edges
	return result


func _dispatch_edges(route: KickoffRouteRuntime, edges: Array) -> void:
	for edge in edges:
		var key_code: Key
		match String(edge):
			"Up": key_code = KEY_UP
			"Down": key_code = KEY_DOWN
			"Left": key_code = KEY_LEFT
			"Right": key_code = KEY_RIGHT
			"A": key_code = KEY_Z
			"B": key_code = KEY_X
			"Select": key_code = KEY_SHIFT
			_: continue
		var event := InputEventKey.new()
		event.keycode = key_code
		event.pressed = true
		route.call("_unhandled_input", event)
		var stage := String(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)
