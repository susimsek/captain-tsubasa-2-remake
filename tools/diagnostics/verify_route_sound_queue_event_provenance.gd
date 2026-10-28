extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const EVENT_SCRIPT := preload("res://scripts/gameplay/rom_sound_queue_write_event.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route: KickoffRouteRuntime = ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	var events: Array[Dictionary] = []
	route.rom_sound_queue_write_requested.connect(func(event: RefCounted) -> void:
		events.append(event.call("to_dictionary"))
	)
	for _tick in 1000:
		if not events.is_empty():
			break
		route.call("_advance_route_source_tick")
	_check(events.size() == 1, "The first ROM-script sound command emits one typed queue-write event.")
	if not events.is_empty():
		var event := events[0]
		_check(str(event.get("event_origin", "")) == "rom_cutscene_script_ed_command",
			"Sound event identifies its ROM script-command origin.")
		_check(str(event.get("source_rom_sha256", "")) == "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
			"Sound event carries the audited Turkish ROM identity.")
		_check(int(event.get("queue_id", -1)) == 0x55 and int(event.get("cutscene_id", -1)) == 1,
			"The queue ID and cutscene identity come from the decoded VM event.")
		_check(int(event.get("script_event_index", -1)) == 5
			and int(event.get("script_offset", -1)) == 9
			and int(event.get("script_cpu_address", -1)) == 0xA2AA
			and event.get("script_raw_bytes", PackedByteArray()) == PackedByteArray([0xED, 0x55]),
			"The source command identity is the byte-verified ID-1 `$ED $55` record.")
		_check(int(event.get("handler_entry_pc", -1)) == 0x85EC
			and int(event.get("queue_store_instruction_pc", -1)) == 0x85FC
			and int(event.get("post_store_pc", -1)) == 0x85FF,
			"Queue-write PC provenance maps to the ROM `$85EC` handler and `$85FC` store.")
		_check(int(event.get("route_frame", -1)) >= 4693
			and str(event.get("route_frame_domain", "")) == "godot_route_vm_tick",
			"The emitted tick is explicitly labeled as a Godot route frame, not a verified ROM frame.")
		_check(int(event.get("absolute_rom_frame", -2)) == -1
			and int(event.get("cpu_cycle", -2)) == -1
			and not bool(event.get("timing_verified", true)),
			"Unknown absolute frame and CPU cycle remain unclaimed.")
		_check(route.cue_audio.current_queue_id == 0x55
			and route.cue_audio.current_source_frame == int(event.get("route_frame", -2)),
			"The route's audio consumer receives the queue ID and model tick from the typed event.")

	var malformed: RefCounted = EVENT_SCRIPT.new()
	var malformed_accepted: bool = malformed.call("populate_from_cutscene_ed_command", 1, {
		"kind": "sound_command", "opcode": 0xED, "id": 0x55,
		"event_index": 1, "script_offset": 1, "cpu_address": 0xA2AA,
		"raw_bytes": [0xED, 0x54],
	}, 5000)
	_check(not malformed_accepted, "A queue ID inconsistent with the source bytes is rejected.")

	# Exercise the real MEETING confirmation method after an actual source cue.
	# The direct setup store at `$812C` must not be faked by this UI event.
	var event_count_before: int = route.get_route_status()["sound_queue_write_events"].size()
	route.route_stage = KickoffRouteRuntime.RouteStage.MEETING_MENU
	route.call("_on_meeting_menu_option_confirmed", 3)
	_check(route.get_route_status()["sound_queue_write_events"].size() == event_count_before,
		"MEETING `$06` confirmation does not manufacture the separate `$812C/$812F` setup write.")
	await process_frame

	if _failures.is_empty():
		print("PASS: decoded `$ED` route events carry source identity and ROM handler/store PCs; unknown ROM timing stays explicit; MEETING confirmation emits no fabricated `$812F` cue.")
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
