extends SceneTree
## Capture the production route's AudioServer output while replaying the
## ordinary recorded-input PASS action. The WAV is validation-only.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const FIRST_ACTION_MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const BASE_INPUT_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const BASE_INPUT_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const PASS_INPUT_PATH := "res://reference/diagnostics/first_pass_action_input_edges_20261110.csv"
const PASS_INPUT_SHA256 := "3e522de6924b0fb9ad40ffdd2271a9e4ea62cbe1bf76cc27c6b414b7e87bb6d2"
const TITLE_HANDOFF_FRAME := 4692
const FIRST_ROUTE_FRAME := 4693
const FIRST_CAPTURE_TICK := 4694
const PASS_ENDPOINT_FRAME := 9600
const ENDPOINT_PC := 0xD5EA
const EXPECTED_HOLDER := 0x0A
const EXPECTED_MIX_RATE := 44100
const CAPTURE_BUFFER_SECONDS := 4.0
const OUTPUT_DIR := "/tmp/ct2_kickoff_route_audio_server"
const BUTTON_NAMES: Array[String] = ["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"]

var _capture: AudioEffectCapture
var _master_bus_index := -1
var _capture_effect_index := -1
var _capture_capacity_frames := 0
var _max_frames_available := 0
var _captured := PackedVector2Array()
var _input_edges: Dictionary = {}
var _audio_events: Array[Dictionary] = []
var _frame_audio_spans: Array[Dictionary] = []
var _confirmation_requests: Array[int] = []
var _infrastructure_errors: Array[String] = []
var _route: KickoffRouteRuntime
var _route_status_at_stop: Dictionary = {}
var _stop_reason := ""
var _endpoint_verified := false
var _run_id := ""
var _wav_path := ""
var _metadata_path := ""


func _initialize() -> void:
	_run_id = str(int(Time.get_unix_time_from_system()))
	_wav_path = OUTPUT_DIR.path_join("pass_route_to_9600_%s.wav" % _run_id)
	_metadata_path = OUTPUT_DIR.path_join("pass_route_to_9600_%s.json" % _run_id)
	call_deferred("_run")


func _run() -> void:
	var input_result := _read_input_edges()
	if not bool(input_result.get("ok", false)):
		_infrastructure_errors.append(String(input_result.get("error", "Input timeline could not be loaded.")))
		await _finish_capture("input_error")
		return
	_input_edges = input_result.get("edges", {})

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		_infrastructure_errors.append("Godot Master audio bus was not found.")
		await _finish_capture("audio_bus_error")
		return
	_master_bus_index = master_bus
	_capture = AudioEffectCapture.new()
	_capture.buffer_length = CAPTURE_BUFFER_SECONDS
	_capture_effect_index = AudioServer.get_bus_effect_count(_master_bus_index)
	AudioServer.add_bus_effect(_master_bus_index, _capture)
	_capture_capacity_frames = int(CAPTURE_BUFFER_SECONDS * float(AudioServer.get_mix_rate()))

	var title_runtime := MAIN_SCENE.instantiate() as Node
	if title_runtime == null:
		_infrastructure_errors.append("Could not instantiate the configured title handoff scene.")
		await _finish_capture("title_scene_error")
		return
	title_runtime.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(title_runtime)
	await process_frame
	var opening_audio := title_runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if opening_audio != null:
		opening_audio.stop()
	var title_presenter := title_runtime.get_node_or_null("SourcePresenter")
	var title_renderer := title_runtime.get_node_or_null("TitleMenu/TitleBackground")
	if title_presenter == null or title_renderer == null:
		_infrastructure_errors.append("Configured title scene did not provide ROM-derived handoff state.")
		await _finish_capture("title_handoff_error")
		return
	var title_state: Variant = title_presenter.get("state")
	if not title_state is Dictionary:
		_infrastructure_errors.append("Title presenter does not expose source state.")
		await _finish_capture("title_handoff_error")
		return
	var fade_counters: Variant = title_state.get("fade_counters", Vector2i(-1, -1))
	var title_palette: Variant = title_renderer.call("get_source_title_palette_bytes")
	if typeof(fade_counters) != TYPE_VECTOR2I or fade_counters != Vector2i(0x0F, 0x0F) \
			or not title_palette is PackedByteArray or title_palette.size() != 0x20:
		_infrastructure_errors.append("Title presenter did not provide the expected ROM-derived handoff palette.")
		await _finish_capture("title_handoff_error")
		return

	_route = ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	if _route == null:
		_infrastructure_errors.append("Could not instantiate the production KICK OFF route.")
		await _finish_capture("route_scene_error")
		return
	var source_fade := {"fade_counters": fade_counters, "base_palette_bytes": title_palette}
	if not _route.initialize_from_title_handoff(TITLE_HANDOFF_FRAME, ROM_SHA256,
			source_fade, title_renderer):
		_infrastructure_errors.append("Production route rejected the ROM-derived title handoff.")
		await _finish_capture("title_handoff_error")
		return
	_route.action_confirmation_requested.connect(_on_action_confirmation_requested)
	_route.set_process(false)
	root.add_child(_route)
	await process_frame
	_route.cue_audio.rom_sound_started.connect(_on_audio_started)
	_route.cue_audio.rom_sound_stopped.connect(_on_audio_stopped)
	_route.cue_audio.unsupported_rom_sound.connect(_on_audio_unsupported)
	
	if _route.source_frame != FIRST_ROUTE_FRAME:
		_infrastructure_errors.append("Route started at source frame %d; expected %d." % [
			_route.source_frame, FIRST_ROUTE_FRAME])
		await _finish_capture("route_start_frame_error")
		return

	_capture.clear_buffer()
	for source_frame in range(FIRST_CAPTURE_TICK, PASS_ENDPOINT_FRAME + 1):
		if _route.source_frame != source_frame - 1:
			_stop_reason = "source_frame_sequence_error"
			_infrastructure_errors.append("Before tick %d the route was at frame %d." % [
				source_frame, _route.source_frame])
			break
		if _input_edges.has(source_frame):
			_dispatch_edges(_input_edges[source_frame])
		var samples_before := _captured.size()
		_route.call("_advance_route_source_tick")
		await process_frame
		if not _drain_capture():
			_stop_reason = "audio_capture_overflow"
			break
		_frame_audio_spans.append({
			"source_frame": _route.source_frame,
			"sample_start": samples_before,
			"sample_end": _captured.size(),
			"sample_count": _captured.size() - samples_before,
		})
		_route_status_at_stop = _route.get_route_status()
		var fresh_route: Dictionary = _route_status_at_stop.get("fresh_source_route", {})
		if String(_route_status_at_stop.get("stage", "")) in ["source_route_gap", "match_setup_gap"] \
				or String(fresh_route.get("phase", "")) == "error":
			_stop_reason = "route_source_gap"
			break
		if source_frame == PASS_ENDPOINT_FRAME:
			_endpoint_verified = _is_pass_endpoint(_route_status_at_stop)
			_stop_reason = "endpoint_reached" if _endpoint_verified else "frame_9600_endpoint_mismatch"
			break

	if _stop_reason.is_empty():
		_stop_reason = "capture_stopped_before_endpoint"
	if _route != null and is_instance_valid(_route):
		_route_status_at_stop = _route.get_route_status()
		if _route.source_frame == PASS_ENDPOINT_FRAME:
			_endpoint_verified = _is_pass_endpoint(_route_status_at_stop)
			if not _endpoint_verified and _stop_reason == "endpoint_reached":
				_stop_reason = "frame_9600_endpoint_mismatch"
	await _finish_capture(_stop_reason)


func _read_input_edges() -> Dictionary:
	var base_bytes := FileAccess.get_file_as_bytes(BASE_INPUT_PATH)
	if base_bytes.is_empty() or _sha256_hex(base_bytes) != BASE_INPUT_SHA256:
		return {"ok": false, "error": "Base post-title input CSV is missing or has an unexpected SHA-256."}
	var pass_bytes := FileAccess.get_file_as_bytes(PASS_INPUT_PATH)
	if pass_bytes.is_empty() or _sha256_hex(pass_bytes) != PASS_INPUT_SHA256:
		return {"ok": false, "error": "First-PASS input-edge CSV is missing or has an unexpected SHA-256."}
	var base_file := FileAccess.open(BASE_INPUT_PATH, FileAccess.READ)
	var pass_file := FileAccess.open(PASS_INPUT_PATH, FileAccess.READ)
	if base_file == null or pass_file == null:
		return {"ok": false, "error": "Could not open one of the checked input CSV files."}
	var result: Dictionary = {}
	var previous: Dictionary = {}
	base_file.get_csv_line()
	while not base_file.eof_reached():
		var row := base_file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		var current: Dictionary = {}
		for index in range(2, 10):
			if String(row[index]).strip_edges() == "1":
				current[BUTTON_NAMES[index - 2]] = true
		var changes: Array[Dictionary] = []
		for button_name in BUTTON_NAMES:
			var was_pressed := bool(previous.get(button_name, false))
			var is_pressed := bool(current.get(button_name, false))
			if was_pressed != is_pressed:
				changes.append({"name": button_name, "pressed": is_pressed})
		if source_frame > TITLE_HANDOFF_FRAME and not changes.is_empty():
			result[source_frame] = changes
		previous = current
	pass_file.get_csv_line()
	while not pass_file.eof_reached():
		var row := pass_file.get_csv_line()
		if row.size() < 3:
			continue
		var source_frame := int(row[0])
		var button_name := String(row[1]).strip_edges()
		var pressed := String(row[2]).strip_edges() == "1"
		if source_frame < 9043 or source_frame > 9077 or button_name not in BUTTON_NAMES:
			return {"ok": false, "error": "First-PASS input CSV contains an out-of-range or unknown edge."}
		if result.has(source_frame):
			return {"ok": false, "error": "Base and first-PASS input CSVs overlap at frame %d." % source_frame}
		result[source_frame] = [{"name": button_name, "pressed": pressed}]
	if not _pass_edge_contract_matches(result):
		return {"ok": false, "error": "First-PASS edge rows do not match the checked Left/A/Down/A route."}
	return {"ok": true, "edges": result,
		"base_input_sha256": BASE_INPUT_SHA256,
		"pass_input_sha256": PASS_INPUT_SHA256}


func _pass_edge_contract_matches(edges: Dictionary) -> bool:
	var expected := {
		9043: [{"name": "Left", "pressed": true}],
		9044: [{"name": "Left", "pressed": false}],
		9045: [{"name": "A", "pressed": true}],
		9046: [{"name": "A", "pressed": false}],
		9068: [{"name": "Down", "pressed": true}],
		9069: [{"name": "Down", "pressed": false}],
		9076: [{"name": "A", "pressed": true}],
		9077: [{"name": "A", "pressed": false}],
	}
	for frame_variant in expected:
		if edges.get(frame_variant, []) != expected[frame_variant]:
			return false
	return true


func _dispatch_edges(changes: Array) -> void:
	for change_variant in changes:
		if not change_variant is Dictionary:
			continue
		var change: Dictionary = change_variant
		var key_code: Key
		match String(change.get("name", "")):
			"Up": key_code = KEY_UP
			"Down": key_code = KEY_DOWN
			"Left": key_code = KEY_LEFT
			"Right": key_code = KEY_RIGHT
			"A": key_code = KEY_Z
			"B": key_code = KEY_X
			"Select": key_code = KEY_SHIFT
			"Start": continue
			_: continue
		var event := InputEventKey.new()
		event.keycode = key_code
		event.pressed = bool(change.get("pressed", false))
		_route.call("_unhandled_input", event)
		var stage := String(_route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(_route._meeting_menu_input):
			_route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(_route._menu_input):
			_route._menu_input.call("handle_input_event", event)


func _drain_capture() -> bool:
	if _capture == null or not is_instance_valid(_capture):
		_infrastructure_errors.append("AudioEffectCapture is unavailable.")
		return false
	var available := _capture.get_frames_available()
	_max_frames_available = maxi(_max_frames_available, available)
	if available <= 0:
		return true
	if available >= _capture_capacity_frames:
		_infrastructure_errors.append("AudioEffectCapture reached its ring-buffer capacity before draining.")
		return false
	var chunk := _capture.get_buffer(available)
	if chunk.size() != available:
		_infrastructure_errors.append("AudioEffectCapture returned %d of %d available frames." % [
			chunk.size(), available])
		return false
	_captured.append_array(chunk)
	return true


func _is_pass_endpoint(status: Dictionary) -> bool:
	if _route == null or _route.source_frame != PASS_ENDPOINT_FRAME \
			or int(status.get("source_frame", -1)) != PASS_ENDPOINT_FRAME \
			or not bool(status.get("fresh_source_route_accepts_gameplay_input", false)) \
			or _route._fresh_source_route_runner == null \
			or _confirmation_requests.size() != 1 \
			or _confirmation_requests[0] != FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.PASS \
			or bool(status.get("continue_entered", false)):
		return false
	var runner: Variant = _route._fresh_source_route_runner
	var runner_status: Dictionary = runner.get_status()
	if String(runner_status.get("phase", "")) not in ["first_action_menu_ready", "waiting_for_input"] \
			or int(runner_status.get("pending_selected_task_slot", -1)) != 0x05 \
			or int(runner_status.get("pending_selected_task_boundary_pc", -1)) != ENDPOINT_PC:
		return false
	var scheduler: Variant = runner._scheduler
	if scheduler == null or not scheduler.has_method("get_task_boundary_snapshot"):
		return false
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	return int(boundary.get("pc", -1)) == ENDPOINT_PC \
		and int(boundary.get("active_task_slot", -1)) == 0x05 \
		and ram is PackedByteArray and (ram as PackedByteArray).size() == 0x800 \
		and int((ram as PackedByteArray)[0x0441]) == EXPECTED_HOLDER \
		and int((ram as PackedByteArray)[0x05FE]) == 0x78 \
		and int((ram as PackedByteArray)[0x062D]) == 0x00


func _on_action_confirmation_requested(action_id: int) -> void:
	_confirmation_requests.append(action_id)


func _on_audio_started(queue_id: int, source_frame: int) -> void:
	_audio_events.append({"kind": "start", "queue_id": queue_id,
		"source_frame": source_frame, "drained_sample_count_at_signal": _captured.size()})


func _on_audio_stopped(queue_id: int, source_frame: int) -> void:
	_audio_events.append({"kind": "stop", "queue_id": queue_id,
		"source_frame": source_frame, "drained_sample_count_at_signal": _captured.size()})


func _on_audio_unsupported(queue_id: int, source_frame: int) -> void:
	_audio_events.append({"kind": "unsupported", "queue_id": queue_id,
		"source_frame": source_frame, "drained_sample_count_at_signal": _captured.size()})


func _finish_capture(status: String) -> void:
	if _route != null and is_instance_valid(_route) and _route.source_frame >= FIRST_ROUTE_FRAME:
		if _route_status_at_stop.is_empty():
			_route_status_at_stop = _route.get_route_status()
		_endpoint_verified = _is_pass_endpoint(_route_status_at_stop)
		if status == "endpoint_reached" and not _endpoint_verified:
			status = "frame_9600_endpoint_mismatch"
	if _capture != null and is_instance_valid(_capture):
		var final_drain_ok := _drain_capture()
		if not final_drain_ok and status == "endpoint_reached":
			status = "audio_capture_error"
	var directory_error := DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	if directory_error != OK:
		_infrastructure_errors.append("Could not create capture directory %s (error %d)." % [OUTPUT_DIR, directory_error])
		_cleanup()
		quit(1)
		return
	var wav_saved := _write_wav()
	if not wav_saved and status in ["endpoint_reached", "frame_9600_endpoint_mismatch"]:
		status = "audio_capture_error"
	var source_route_metadata: Dictionary = _route_status_at_stop.get("fresh_source_route", {})
	var result := {
		"schema": "ct2-kickoff-route-audio-server-capture-v1",
		"purpose": "Validation-only AudioServer capture during ordinary recorded-input PASS route execution.",
		"status": status,
		"status_reason": _status_reason(status),
		"endpoint_verified": _endpoint_verified,
		"target_endpoint": {"frame": PASS_ENDPOINT_FRAME, "pc": "$D5EA",
			"holder_slot": EXPECTED_HOLDER},
		"route": {
			"ordinary_input_path": true,
			"rom_sha256": ROM_SHA256,
			"base_input_path": BASE_INPUT_PATH.trim_prefix("res://"),
			"base_input_sha256": BASE_INPUT_SHA256,
			"pass_input_path": PASS_INPUT_PATH.trim_prefix("res://"),
			"pass_input_sha256": PASS_INPUT_SHA256,
			"first_route_frame": FIRST_ROUTE_FRAME,
			"first_captured_route_tick": FIRST_CAPTURE_TICK,
			"last_route_frame": _route.source_frame if _route != null else -1,
			"last_stage": _route_status_at_stop.get("stage", ""),
			"source_route_phase": source_route_metadata.get("phase", ""),
			"route_gaps": _route_status_at_stop.get("route_gaps", []),
			"queue_write_events": _route_status_at_stop.get("sound_queue_write_events", []),
			"audio_player_events": _audio_events.duplicate(true),
			"confirmation_requests": _confirmation_requests.duplicate(),
			"continue_entered": _route_status_at_stop.get("continue_entered", false),
			"endpoint_boundary": _endpoint_boundary_metadata(),
		},
		"capture": {
			"audio_driver": AudioServer.get_driver_name(),
			"mix_rate_hz": AudioServer.get_mix_rate(),
			"expected_mix_rate_hz": EXPECTED_MIX_RATE,
			"mix_rate_matches_expected": AudioServer.get_mix_rate() == EXPECTED_MIX_RATE,
			"channels_captured": 2,
			"wav_channels": 1,
			"wav_format": "mono signed 16-bit PCM",
			"captured_sample_frames": _captured.size(),
			"capture_buffer_seconds": CAPTURE_BUFFER_SECONDS,
			"capture_buffer_capacity_frames": _capture_capacity_frames,
			"maximum_buffer_backlog_frames": _max_frames_available,
			"buffer_overflow": status == "audio_capture_overflow",
			"source_tick_driver": "One production route source tick is advanced before each process-frame AudioServer capture drain.",
			"sample_span_convention": "Each frame_audio_spans row associates samples drained after its source tick; this does not establish NES subframe phase.",
			"frame_audio_spans": _frame_audio_spans.duplicate(true),
			"pcm_wav_path": _wav_path if wav_saved else "",
			"pcm_wav_sha256": FileAccess.get_sha256(_wav_path) if wav_saved else "",
			"fceux_pcm_used": false,
			"runtime_asset": false,
		},
		"infrastructure_errors": _infrastructure_errors.duplicate(),
		"metadata_path": _metadata_path,
	}
	var metadata_file := FileAccess.open(_metadata_path, FileAccess.WRITE)
	if metadata_file == null:
		printerr("Could not write capture metadata: " + _metadata_path)
		_cleanup()
		quit(1)
		return
	metadata_file.store_string(JSON.stringify(result, "\t") + "\n")
	metadata_file.close()
	print("KICKOFF_ROUTE_AUDIO_CAPTURE status=%s frame=%d samples=%d wav=%s metadata=%s" % [
		status, int(result.route.last_route_frame), _captured.size(),
		_wav_path if wav_saved else "not_written", _metadata_path])
	_cleanup()
	await create_timer(0.1).timeout
	quit(0 if _endpoint_verified and wav_saved and _infrastructure_errors.is_empty() else 2)


func _endpoint_boundary_metadata() -> Dictionary:
	if _route == null or _route._fresh_source_route_runner == null:
		return {}
	var runner: Variant = _route._fresh_source_route_runner
	var scheduler: Variant = runner._scheduler
	if scheduler == null or not scheduler.has_method("get_task_boundary_snapshot"):
		return {}
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	return {
		"pc": boundary.get("pc", -1),
		"active_task_slot": boundary.get("active_task_slot", -1),
		"holder": int((ram as PackedByteArray)[0x0441])
			if ram is PackedByteArray and (ram as PackedByteArray).size() == 0x800 else -1,
		"receiver_cursor": int((ram as PackedByteArray)[0x05FE])
			if ram is PackedByteArray and (ram as PackedByteArray).size() == 0x800 else -1,
		"field_wait_flag": int((ram as PackedByteArray)[0x062D])
			if ram is PackedByteArray and (ram as PackedByteArray).size() == 0x800 else -1,
	}


func _write_wav() -> bool:
	var pcm := PackedByteArray()
	pcm.resize(_captured.size() * 2)
	for index in _captured.size():
		var mono := clampf((_captured[index].x + _captured[index].y) * 0.5, -1.0, 1.0)
		pcm.encode_s16(index * 2, clampi(roundi(mono * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = AudioServer.get_mix_rate()
	wav.stereo = false
	wav.data = pcm
	var save_error := wav.save_to_wav(_wav_path)
	if save_error != OK:
		_infrastructure_errors.append("Could not write the validation WAV (error %d)." % save_error)
		return false
	return true


func _status_reason(status: String) -> String:
	match status:
		"endpoint_reached":
			return "Ordinary route reached frame 9600 at the verified slot-$05 `$D5EA` holder-$0A wait."
		"route_source_gap":
			return "Route stopped at a reported source-route gap; the target endpoint was not inferred."
		"frame_9600_endpoint_mismatch":
			return "Source frame 9600 was reached, but the `$D5EA` holder-$0A boundary contract did not match."
		"audio_capture_overflow":
			return "AudioEffectCapture reached its ring-buffer limit; the saved WAV is partial."
		"capture_stopped_before_endpoint":
			return "Capture ended before the target route frame; the saved WAV is partial."
		"input_error", "audio_bus_error", "title_scene_error", "title_handoff_error", "route_scene_error", "route_start_frame_error":
			return "Capture setup failed; see infrastructure_errors."
		"audio_capture_error":
			return "Audio capture failed while finalizing; see infrastructure_errors."
		"source_frame_sequence_error":
			return "The route source frame did not advance as expected; the saved WAV is partial."
		_:
			return "Capture status is partial or incomplete; inspect route frame and infrastructure_errors."


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _cleanup() -> void:
	if _route != null and is_instance_valid(_route):
		if _route.cue_audio != null and is_instance_valid(_route.cue_audio):
			_route.cue_audio.rom_sound_started.disconnect(_on_audio_started)
			_route.cue_audio.rom_sound_stopped.disconnect(_on_audio_stopped)
			_route.cue_audio.unsupported_rom_sound.disconnect(_on_audio_unsupported)
			_route.cue_audio.release_rom_audio_resources()
		_route.queue_free()
	if _master_bus_index >= 0 and _capture_effect_index >= 0 \
			and _capture_effect_index < AudioServer.get_bus_effect_count(_master_bus_index):
		AudioServer.remove_bus_effect(_master_bus_index, _capture_effect_index)
	_capture = null
