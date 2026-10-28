extends SceneTree
## Diagnostic-only replay of recorded post-title inputs against ROM-source
## audio queue events. It observes audio presenter signals but never reads a
## captured WAV/PCM or changes production audio behavior.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const INPUT_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const SOURCE_EVENTS_PATH := "res://reference/rom_extract/gameplay/first_match_audio_queue_events_20261027.json"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_LAST_FRAME := 8953
const REPORT_PATH := "/tmp/ct2_first_match_audio_event_parity_20261028.json"
const SFX_IDS: Array[int] = [0x2B, 0x2C, 0x30, 0x66, 0x69]

var _infra_errors: Array[String] = []
var _audio_events: Array[Dictionary] = []
var _route: KickoffRouteRuntime


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_events := _load_source_events()
	var input_edges := _read_recorded_edges()
	if source_events.is_empty() or input_edges.is_empty():
		_finish_with_infrastructure_error()
		return

	_route = ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	if _route == null:
		_infra_errors.append("Could not instantiate the KICK OFF route scene.")
		_finish_with_infrastructure_error()
		return
	root.add_child(_route)
	await process_frame
	_route.set_process(false)
	_route.source_frame = 4693
	_route.cue_audio.rom_sound_started.connect(_on_sound_started)
	_route.cue_audio.rom_sound_stopped.connect(_on_sound_stopped)

	for source_frame in range(4694, EXPECTED_LAST_FRAME + 1):
		if input_edges.has(source_frame):
			_dispatch_edges(input_edges[source_frame])
		_route.call("_advance_route_source_tick")
		if input_edges.has(source_frame):
			# Allow deferred cutscene/menu scene-tree transitions to settle at the
			# same input boundaries used by the existing recorded-input harness.
			await process_frame

	if _route.source_frame != EXPECTED_LAST_FRAME:
		_infra_errors.append("Replay ended at source frame %d, expected %d." % [_route.source_frame, EXPECTED_LAST_FRAME])
	if str(_route.get_route_status().get("stage", "")) != "first_action_menu_pending":
		_infra_errors.append("Replay did not stop at the first-command-menu pending endpoint.")

	var expected_events := _derive_expected_player_events(source_events)
	var natural_sfx_finishes: Array[Dictionary] = []
	var comparable_actual_events := _exclude_async_sfx_finishes(source_events, natural_sfx_finishes)
	var differences := _compare_events(expected_events, comparable_actual_events)
	var result := {
		"schema": "ct2-kickoff-route-audio-event-parity-report-v1",
		"purpose": "Diagnostic-only actual presenter start/stop events compared with ROM-source queue events.",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_event_table": SOURCE_EVENTS_PATH,
		"post_title_input_path": INPUT_PATH,
		"post_title_input_sha256": INPUT_SHA256,
		"captured_wav_or_pcm_loaded": false,
		"production_audio_changed": false,
		"route_endpoint_frame": _route.source_frame,
		"route_endpoint_stage": _route.get_route_status().get("stage", ""),
		"source_queue_events": source_events,
		"expected_audio_player_events": expected_events,
		"actual_audio_player_events": _audio_events.duplicate(true),
		"async_sfx_finish_signals_excluded_from_queue_parity": natural_sfx_finishes,
		"parity": differences,
		"known_second_55_issue": _second_55_finding(source_events),
		"infrastructure_errors": _infra_errors.duplicate(),
	}
	_write_report(result)
	_print_report(result)

	# Disconnect before teardown so resource-release stops are not mistaken for
	# route queue events.
	_route.cue_audio.rom_sound_started.disconnect(_on_sound_started)
	_route.cue_audio.rom_sound_stopped.disconnect(_on_sound_stopped)
	_route.cue_audio.release_rom_audio_resources()
	_route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(1 if not _infra_errors.is_empty() else 0)


func _load_source_events() -> Array[Dictionary]:
	if not FileAccess.file_exists(SOURCE_EVENTS_PATH):
		_infra_errors.append("ROM-source event table is missing: " + SOURCE_EVENTS_PATH)
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_EVENTS_PATH))
	if not parsed is Dictionary:
		_infra_errors.append("ROM-source event table is not a JSON object.")
		return []
	var table: Dictionary = parsed
	if str(table.get("schema", "")) != "ct2-first-match-audio-source-queue-events-v1" \
			or str(table.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or bool(table.get("captured_pcm_used", true)) \
			or bool(table.get("captured_wav_used", true)) \
			or bool(table.get("runtime_consumes_this_file", true)):
		_infra_errors.append("ROM-source event table identity or diagnostic-only flags are invalid.")
		return []
	var rows: Variant = table.get("events", [])
	if not rows is Array or rows.is_empty():
		_infra_errors.append("ROM-source event table has no queue events.")
		return []
	var result: Array[Dictionary] = []
	var previous_frame := -1
	for row_variant in rows:
		if not row_variant is Dictionary:
			_infra_errors.append("ROM-source event table contains a malformed row.")
			return []
		var row: Dictionary = row_variant
		var frame := int(row.get("source_frame", -1))
		var queue_id := int(row.get("queue_id", -1))
		if frame <= previous_frame or frame > EXPECTED_LAST_FRAME or queue_id < 0:
			_infra_errors.append("ROM-source queue rows are unordered or outside this replay interval.")
			return []
		previous_frame = frame
		result.append(row.duplicate(true))
	return result


func _read_recorded_edges() -> Dictionary:
	if not FileAccess.file_exists(INPUT_PATH):
		_infra_errors.append("Recorded post-title input timeline is missing.")
		return {}
	var input_bytes := FileAccess.get_file_as_bytes(INPUT_PATH)
	if _sha256_hex(input_bytes) != INPUT_SHA256:
		_infra_errors.append("Recorded post-title input timeline hash changed.")
		return {}
	var file := FileAccess.open(INPUT_PATH, FileAccess.READ)
	if file == null:
		_infra_errors.append("Could not open recorded post-title inputs.")
		return {}
	file.get_csv_line()
	var result: Dictionary = {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		if source_frame <= 4693 or source_frame > EXPECTED_LAST_FRAME:
			continue
		var edges: Array[String] = []
		for index in range(2, 10):
			if row[index] == "1":
				edges.append(["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"][index - 2])
		if not edges.is_empty():
			result[source_frame] = edges
	if result.is_empty():
		_infra_errors.append("Recorded post-title input timeline contains no route edges.")
	return result


func _dispatch_edges(edges: Array) -> void:
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
		_route.call("_unhandled_input", event)
		var stage := str(_route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(_route._meeting_menu_input):
			_route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(_route._menu_input):
			_route._menu_input.call("handle_input_event", event)


func _on_sound_started(queue_id: int, source_frame: int) -> void:
	_audio_events.append({"kind": "start", "queue_id": queue_id, "source_frame": source_frame})


func _on_sound_stopped(queue_id: int, source_frame: int) -> void:
	_audio_events.append({"kind": "stop", "queue_id": queue_id, "source_frame": source_frame})


func _derive_expected_player_events(source_events: Array[Dictionary]) -> Array[Dictionary]:
	var expected: Array[Dictionary] = []
	var active_bgm := 0
	var active_sfx: Array[int] = []
	for source_event in source_events:
		var queue_id := int(source_event["queue_id"])
		var source_frame := int(source_event["source_frame"])
		var effect := str(source_event.get("playback_effect", ""))
		match effect:
			"stop_all":
				if active_bgm != 0:
					expected.append({"kind": "stop", "queue_id": active_bgm, "source_frame": source_frame, "trigger_queue_id": queue_id})
					active_bgm = 0
				for sfx_id in active_sfx:
					expected.append({"kind": "stop", "queue_id": sfx_id, "source_frame": source_frame, "trigger_queue_id": queue_id})
				active_sfx.clear()
			"empty_sequence":
				continue
			"start_bgm":
				if active_bgm != 0:
					expected.append({"kind": "stop", "queue_id": active_bgm, "source_frame": source_frame, "trigger_queue_id": queue_id})
				expected.append({"kind": "start", "queue_id": queue_id, "source_frame": source_frame})
				active_bgm = queue_id
			"start_sfx":
				expected.append({"kind": "start", "queue_id": queue_id, "source_frame": source_frame})
				active_sfx.append(queue_id)
			_:
				_infra_errors.append("No playback-effect mapping for source queue ID $%02X." % queue_id)
	return expected


func _exclude_async_sfx_finishes(source_events: Array[Dictionary], out_finishes: Array[Dictionary]) -> Array[Dictionary]:
	var expected_stop_set: Dictionary = {}
	var latest_sfx_start_frame: Dictionary = {}
	for source_event in source_events:
		var effect := str(source_event.get("playback_effect", ""))
		var queue_id := int(source_event.get("queue_id", -1))
		var frame := int(source_event.get("source_frame", -1))
		if effect == "start_sfx":
			latest_sfx_start_frame[queue_id] = frame
		elif effect == "stop_all":
			for sfx_id in SFX_IDS:
				expected_stop_set["%d:%d" % [sfx_id, frame]] = true
	var comparable: Array[Dictionary] = []
	for actual in _audio_events:
		var queue_id := int(actual.get("queue_id", -1))
		var source_frame := int(actual.get("source_frame", -1))
		if str(actual.get("kind", "")) == "stop" and SFX_IDS.has(queue_id) \
				and latest_sfx_start_frame.get(queue_id, -2) == source_frame \
				and not expected_stop_set.has("%d:%d" % [queue_id, source_frame]):
			var natural_finish := actual.duplicate(true)
			natural_finish["classification"] = "async_sfx_finish_signal"
			natural_finish["source_frame_semantics"] = "presenter echoes cue-start frame; this is not a ROM stop-event time"
			out_finishes.append(natural_finish)
			continue
		comparable.append(actual.duplicate(true))
	return comparable


func _compare_events(expected: Array[Dictionary], actual: Array[Dictionary]) -> Dictionary:
	var remaining_actual := actual.duplicate(true)
	var matched: Array[Dictionary] = []
	var missing: Array[Dictionary] = []
	for expected_event in expected:
		var found_index := -1
		for index in remaining_actual.size():
			if _same_event(expected_event, remaining_actual[index]):
				found_index = index
				break
		if found_index < 0:
			missing.append(expected_event.duplicate(true))
		else:
			matched.append(expected_event.duplicate(true))
			remaining_actual.remove_at(found_index)
	return {
		"status": "MATCH" if missing.is_empty() and remaining_actual.is_empty() else "MISMATCH",
		"expected_count": expected.size(),
		"actual_comparable_count": actual.size(),
		"matched_count": matched.size(),
		"missing_from_runtime": missing,
		"unexpected_runtime_events": remaining_actual,
	}


func _same_event(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("kind", "")) == str(right.get("kind", "")) \
			and int(left.get("queue_id", -1)) == int(right.get("queue_id", -1)) \
			and int(left.get("source_frame", -1)) == int(right.get("source_frame", -1))


func _second_55_finding(source_events: Array[Dictionary]) -> Dictionary:
	var source_restart_frame := -1
	for event in source_events:
		if int(event.get("queue_id", -1)) == 0x55:
			source_restart_frame = int(event.get("source_frame", -1))
	var godot_restarts: Array[int] = []
	var count := 0
	for actual in _audio_events:
		if str(actual.get("kind", "")) == "start" and int(actual.get("queue_id", -1)) == 0x55:
			count += 1
			if count == 2:
				godot_restarts.append(int(actual.get("source_frame", -1)))
	return {
		"source_setup_queue_frame": source_restart_frame,
		"runtime_second_55_source_frame": godot_restarts[0] if not godot_restarts.is_empty() else -1,
		"runtime_call_site": "No ROM-source match-setup task currently reaches the $812C/$812F queue write; the false MEETING confirmation dispatch has been removed.",
		"call_site_is_meeting_confirmation": false,
		"meeting_confirmation_dispatches_55": false,
		"source_setup_post_store_pc": "$812F",
		"note": "Frame 7409 is the ROM bank-0 fresh-match setup store at $812C/$812F. The route no longer substitutes MEETING Başla as that event. Until a ROM-source task runner reaches $812C/$812F, no second $55 is emitted; this diagnostic reports the missing source event and does not schedule one from a captured frame table.",
	}


func _write_report(result: Dictionary) -> void:
	var absolute_path := ProjectSettings.globalize_path(REPORT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		_infra_errors.append("Could not write diagnostic report: " + absolute_path)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()


func _print_report(result: Dictionary) -> void:
	print("ROM source queue events: ", JSON.stringify(result["source_queue_events"]))
	print("Expected playback events: ", JSON.stringify(result["expected_audio_player_events"]))
	print("Actual AudioPresenter signals: ", JSON.stringify(result["actual_audio_player_events"]))
	print("Queue parity: ", JSON.stringify(result["parity"]))
	print("Known second-$55 timing issue: ", JSON.stringify(result["known_second_55_issue"]))
	print("Captured WAV/PCM runtime input: false; production audio changed: false")
	print("Diagnostic report: ", ProjectSettings.globalize_path(REPORT_PATH))


func _finish_with_infrastructure_error() -> void:
	for message in _infra_errors:
		printerr("ERROR: " + message)
	quit(1)


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
