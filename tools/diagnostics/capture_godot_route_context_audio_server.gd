extends SceneTree
## Capture the production presenter output for ROM-timed route-context music.
## The WAV is validation-only and is never consumed by the game or asset builder.

const AUDIO_SCRIPT := preload("res://scripts/gameplay/rom_cue_audio_presenter.gd")
const OUTPUT_DIR := "res://reference/diagnostics/audio/godot_route_context_audio_server_20261109"
const MIXER_STARTUP_LATENCY_SAMPLES := 66
const EXPECTED_SAMPLE_RATE := 44100

var _capture: AudioEffectCapture
var _presenter: Node
var _captured := PackedVector2Array()
var _capture_bus_index := -1
var _capture_effect_index := -1
var _capture_capacity_frames := 0
var _max_frames_available := 0
var _target_frames := 0
var _sample_count := 0
var _queue_id := 0
var _queue_frame := -1
var _stop_source_frame := -1
var _first_pass_route := false
var _wav_name := ""
var _timing_path := ""
var _cue_manifest_path := ""
var _failures: Array[String] = []
var _started_events: Array[Array] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_first_pass_route = args.has("--first-pass-route")
	var value_index := args.find("--queue-id")
	if value_index < 0 or value_index + 1 >= args.size():
		printerr("Use --queue-id 0x53, --queue-id 0x3C, or --queue-id 0x3C --first-pass-route.")
		quit(2)
		return
	var raw_queue_id := args[value_index + 1].to_lower()
	raw_queue_id = raw_queue_id.trim_prefix("0x").trim_prefix("$")
	_queue_id = raw_queue_id.hex_to_int()
	if not [0x53, 0x3C, 0x55].has(_queue_id):
		printerr("Only the checked route-context cues $53, $3C, and $55 are supported.")
		quit(2)
	if _first_pass_route and _queue_id != 0x3C:
		printerr("The --first-pass-route option requires --queue-id 0x3C.")
		quit(2)
	var cue_name := "%02X" % _queue_id
	if _queue_id == 0x55:
		_timing_path = "res://assets/gameplay/audio/first_command_menu_route_wavehi_source_timing_rom_generated.json"
		_cue_manifest_path = "res://assets/gameplay/audio/first_command_menu_route_wavehi_rom_generated.json"
		_wav_name = "godot_first_command_menu_route_55.wav"
	elif _first_pass_route:
		_timing_path = "res://assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.json"
		_cue_manifest_path = "res://assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.json"
		_wav_name = "godot_first_pass_route_context_3C.wav"
	else:
		_timing_path = "res://assets/gameplay/audio/match_track_%s_wavehi_route_context_timing_rom_generated.json" % cue_name
		_cue_manifest_path = "res://assets/gameplay/audio/match_track_%s_wavehi_route_context_rom_generated.json" % cue_name
		_wav_name = "godot_route_context_%s.wav" % cue_name
	call_deferred("_run")


func _run() -> void:
	var timing := _read_json(_timing_path)
	var occurrence: Dictionary = {}
	if _first_pass_route:
		var source_variant: Variant = timing.get("source", {})
		var asset_variant: Variant = timing.get("asset", {})
		if not source_variant is Dictionary or not asset_variant is Dictionary:
			_finish_with_error("First-PASS context manifest is missing its source or asset object.")
			return
		var source: Dictionary = source_variant
		var asset: Dictionary = asset_variant
		var start_event: Dictionary = source.get("start_event", {})
		var end_event: Dictionary = source.get("end_event", {})
		var source_events_variant: Variant = source.get("embedded_queue_events", [])
		if not source_events_variant is Array \
				or str(start_event.get("queue_id", "")) != "$3C" \
				or int(start_event.get("frame", -1)) != 8607 \
				or int(end_event.get("frame", -1)) != 9600 \
				or str(asset.get("path", "")) != "assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.wav" \
				or int(asset.get("sample_count", -1)) != 728838:
			_finish_with_error("First-PASS manifest does not identify the checked ROM `$3C` asset/window through frame 9600.")
			return
		var embedded_events: Array[Dictionary] = []
		for event_variant: Variant in source_events_variant:
			if not event_variant is Dictionary:
				_finish_with_error("First-PASS manifest contains a malformed embedded queue event.")
				return
			var event: Dictionary = event_variant
			embedded_events.append({
				"source_frame": int(event.get("frame", -1)),
				"queue_id": str(event.get("queue_id", "")),
			})
		occurrence = {
			"queue_source_frame": int(start_event.get("frame", -1)),
			"asset_sample_window": [0, int(asset.get("sample_count", 0))],
			"verification_sample_count": int(asset.get("sample_count", 0)),
			"embedded_queue_events": embedded_events,
			"source_end": {"source_frame": int(end_event.get("frame", -1))},
		}
	else:
		var occurrences: Array = timing.get("occurrences", [])
		if occurrences.size() != 1:
			_finish_with_error("Route-context timing manifest must contain one checked occurrence.")
			return
		occurrence = occurrences[0]
	_queue_frame = int(occurrence.get("queue_source_frame", -1))
	_stop_source_frame = _queue_frame
	var source_end_variant: Variant = occurrence.get("source_end", {})
	if _first_pass_route and source_end_variant is Dictionary:
		_stop_source_frame = int(source_end_variant.get("source_frame", -1))
	var window: Array = occurrence.get("asset_sample_window", [])
	if _queue_frame < 0 or window.size() != 2:
		_finish_with_error("Route-context source event/sample window is malformed.")
		return
	_sample_count = int(occurrence.get("verification_sample_count", int(window[1]) - int(window[0])))
	if _sample_count <= 0:
		_finish_with_error("Route-context source window has no PCM samples.")
		return
	if _first_pass_route and (_queue_frame != 8607 or _stop_source_frame != 9600 \
			or _sample_count != 728838):
		_finish_with_error("First-PASS capture must match the ROM-derived `$3C` frame-8607–9600 window (728,838 samples).")
		return
	if AudioServer.get_mix_rate() != EXPECTED_SAMPLE_RATE:
		_finish_with_error("AudioServer runs at %d Hz; exact capture requires %d Hz." % [AudioServer.get_mix_rate(), EXPECTED_SAMPLE_RATE])
		return
	_capture = AudioEffectCapture.new()
	_capture_bus_index = AudioServer.get_bus_index("Master")
	if _capture_bus_index < 0:
		_finish_with_error("Godot Master audio bus was not found.")
		return
	_capture.buffer_length = 4.0
	_capture_effect_index = AudioServer.get_bus_effect_count(_capture_bus_index)
	AudioServer.add_bus_effect(_capture_bus_index, _capture)
	_presenter = AUDIO_SCRIPT.new()
	root.add_child(_presenter)
	_presenter.rom_sound_started.connect(_on_sound_started)
	await process_frame
	_capture.clear_buffer()
	if not bool(_presenter.call("apply_rom_sound_command", _queue_id, _queue_frame)):
		_finish_with_error("Production presenter rejected cue $%02X: %s" % [_queue_id, str(_presenter.get("last_error"))])
		return
	if _queue_id == 0x53:
		_check(bool(_presenter.call("apply_rom_sound_command", 0x01, 8443)), "$53 first stop event keeps the source-rendered tail alive")
		_check(bool(_presenter.call("apply_rom_sound_command", 0x01, 8460)), "$53 second stop event keeps the source-rendered tail alive")
		var player := _presenter.get("_bgm_player") as AudioStreamPlayer
		_check(player != null and player.playing, "$53 source mix continues after both ROM stop requests")
		var source_route_stream := player.stream if player != null else null
		_check(bool(_presenter.call("apply_rom_sound_command", 0x3C, 8607)), "$3C BGM event is accepted inside the active route-context stream")
		_check(player != null and player.stream == source_route_stream and player.playing, "$3C event preserves the continuous $53-to-$3C ROM route mix")
	elif _queue_id == 0x55:
		var player := _presenter.get("_bgm_player") as AudioStreamPlayer
		var source_route_stream := player.stream if player != null else null
		for event in [{"queue_id": 0x01, "frame": 7243}, {"queue_id": 0x01, "frame": 7266}, {"queue_id": 0x55, "frame": 7409}, {"queue_id": 0x01, "frame": 8108}, {"queue_id": 0x53, "frame": 8271}, {"queue_id": 0x01, "frame": 8443}, {"queue_id": 0x01, "frame": 8458}, {"queue_id": 0x01, "frame": 8460}, {"queue_id": 0x3C, "frame": 8607}]:
			_check(bool(_presenter.call("apply_rom_sound_command", event["queue_id"], event["frame"])), "$%02X route event is accepted" % event["queue_id"])
			if event["queue_id"] in [0x55, 0x53, 0x3C]:
				_check(player != null and player.stream == source_route_stream and player.playing, "$%02X event preserves the complete first-menu route mix" % event["queue_id"])
	var embedded_events: Array = [
		{"queue_id": 0x66, "frame": 8624},
		{"queue_id": 0x2B, "frame": 8664},
		{"queue_id": 0x2C, "frame": 8786},
	]
	if _first_pass_route:
		var expected_pass_events: Array = [
			{"source_frame": 8624, "queue_id": "$66"},
			{"source_frame": 8664, "queue_id": "$2B"},
			{"source_frame": 8786, "queue_id": "$2C"},
			{"source_frame": 9125, "queue_id": "$2B"},
			{"source_frame": 9247, "queue_id": "$2C"},
		]
		var source_events: Variant = occurrence.get("embedded_queue_events", [])
		_check(source_events is Array and source_events == expected_pass_events,
			"first-PASS sidecar contains the five ROM-derived embedded `$66/$2B/$2C` events through frame 9600")
		embedded_events.clear()
		if source_events is Array:
			for event_variant in source_events:
				if not event_variant is Dictionary:
					continue
				var event: Dictionary = event_variant
				embedded_events.append({
					"queue_id": str(event.get("queue_id", "")).trim_prefix("$").hex_to_int(),
					"frame": int(event.get("source_frame", -1)),
				})
	for event in embedded_events:
		_check(bool(_presenter.call("apply_rom_sound_command", event["queue_id"], event["frame"])), "$%02X embedded SFX queue is accepted" % event["queue_id"])
		_check((_presenter.get("_mixed_route_sfx_queue_ids") as Array).has(event["queue_id"]), "$%02X is represented by the mixed route segment" % event["queue_id"])
		_check(not (_presenter.get("_sfx_queue_by_voice") as Array).has(event["queue_id"]), "$%02X does not start a duplicate isolated WAV" % event["queue_id"])
	var expected_started_events: Array[Array] = [[0x3C, 8607], [0x66, 8624], [0x2B, 8664], [0x2C, 8786]]
	if _queue_id == 0x53:
		expected_started_events.push_front([0x53, 8271])
	elif _queue_id == 0x55:
		expected_started_events = [[0x55, 4816], [0x55, 7409], [0x53, 8271], [0x3C, 8607], [0x66, 8624], [0x2B, 8664], [0x2C, 8786]]
	elif _first_pass_route:
		expected_started_events.append_array([[0x2B, 9125], [0x2C, 9247]])
		var mixed_sfx_ids: Array = _presenter.get("_mixed_route_sfx_queue_ids")
		var isolated_sfx_ids: Array = _presenter.get("_sfx_queue_by_voice")
		_check(mixed_sfx_ids.count(0x2B) == 2 and mixed_sfx_ids.count(0x2C) == 2,
			"both late `$2B/$2C` events are routed through the mixed ROM context exactly once each")
		_check(not isolated_sfx_ids.has(0x2B) and not isolated_sfx_ids.has(0x2C),
			"late `$2B/$2C` events do not start duplicate isolated SFX WAVs")
	_check(_started_events == expected_started_events, "queue signals preserve source route order and frames: %s" % JSON.stringify(_started_events))
	_target_frames = _sample_count + MIXER_STARTUP_LATENCY_SAMPLES
	while _captured.size() < _target_frames:
		await process_frame
		var available := _capture.get_frames_available()
		_max_frames_available = maxi(_max_frames_available, available)
		if available <= 0:
			continue
		var requested := mini(available, _target_frames - _captured.size())
		var chunk := _capture.get_buffer(requested)
		if chunk.size() != requested:
			_finish_with_error("AudioEffectCapture returned %d of %d requested frames." % [chunk.size(), requested])
			return
		_captured.append_array(chunk)
	if _captured.size() != _target_frames:
		_finish_with_error("Captured %d frames; expected %d." % [_captured.size(), _target_frames])
		return
	_capture_capacity_frames = int(_capture.buffer_length * float(EXPECTED_SAMPLE_RATE))
	if _max_frames_available >= _capture_capacity_frames:
		_finish_with_error("AudioEffectCapture reached its ring-buffer capacity.")
		return
	_presenter.call("stop_rom_audio", _stop_source_frame)
	if not _write_capture(timing):
		return
	print("GODOT_ROUTE_CONTEXT_CAPTURE_OK cue=$%02X samples=%d rate=%d events=%s wav=%s" % [
		_queue_id, _captured.size(), EXPECTED_SAMPLE_RATE, JSON.stringify(_started_events),
		ProjectSettings.globalize_path(OUTPUT_DIR.path_join(_wav_name)),
	])
	_cleanup()
	await create_timer(0.1).timeout
	quit(0 if _failures.is_empty() else 1)


func _on_sound_started(queue_id: int, source_frame: int) -> void:
	_started_events.append([queue_id, source_frame])


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
		printerr("FAIL: " + description)


func _write_capture(timing: Dictionary) -> bool:
	var directory := ProjectSettings.globalize_path(OUTPUT_DIR)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(directory)
	if mkdir_error != OK:
		_finish_with_error("Could not create diagnostics-only audio folder (error %d)." % mkdir_error)
		return false
	var pcm := PackedByteArray()
	pcm.resize(_captured.size() * 2)
	for index in _captured.size():
		var mono := clampf((_captured[index].x + _captured[index].y) * 0.5, -1.0, 1.0)
		pcm.encode_s16(index * 2, clampi(roundi(mono * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = EXPECTED_SAMPLE_RATE
	wav.stereo = false
	wav.data = pcm
	var wav_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(_wav_name))
	if wav.save_to_wav(wav_path) != OK:
		_finish_with_error("Could not write the validation-only Godot WAV.")
		return false
	var cue_manifest := _read_json(_cue_manifest_path)
	var manifest_source_variant: Variant = cue_manifest.get("source", {})
	var manifest_asset_variant: Variant = cue_manifest.get("asset", {})
	var manifest_source: Dictionary = manifest_source_variant if manifest_source_variant is Dictionary else {}
	var manifest_asset: Dictionary = manifest_asset_variant if manifest_asset_variant is Dictionary else {}
	var source_input_timeline_sha256 := str(timing.get("source_input_timeline_sha256", ""))
	if source_input_timeline_sha256.is_empty():
		source_input_timeline_sha256 = str(manifest_source.get("input_timeline_sha256", ""))
	var report := {
		"purpose": "Validation-only production Godot AudioServer capture of a ROM-derived route-context segment.",
		"runtime_asset": false,
		"source_rom_sha256": cue_manifest.get("source_rom_sha256", manifest_source.get("rom_sha256", "")),
		"source_input_timeline_sha256": source_input_timeline_sha256,
		"queue_id": "$%02X" % _queue_id,
		"queue_source_frame": _queue_frame,
		"source_end_frame": _stop_source_frame,
		"source_timing_manifest": _timing_path.trim_prefix("res://"),
		"source_timing_manifest_sha256": _sha256_hex(FileAccess.get_file_as_bytes(_timing_path)),
		"source_wav": cue_manifest.get("wav", manifest_asset.get("path", "")),
		"source_wav_sha256": cue_manifest.get("wav_sha256", manifest_asset.get("sha256", "")),
		"capture": {
			"godot_version": Engine.get_version_info().get("string", "unknown"),
			"audio_driver": AudioServer.get_driver_name(),
			"audio_bus": "Master",
			"mix_rate_hz": EXPECTED_SAMPLE_RATE,
			"captured_samples": _captured.size(),
			"expected_source_samples": _sample_count,
			"measured_mixer_startup_latency_prefix_samples": MIXER_STARTUP_LATENCY_SAMPLES,
			"comparison_window": [MIXER_STARTUP_LATENCY_SAMPLES, _target_frames],
			"max_capture_buffer_backlog_frames": _max_frames_available,
			"capture_buffer_capacity_frames": _capture_capacity_frames,
			"sound_started_events": _started_events,
			"fceux_capture_used": false,
			"rom_or_emulator_required_at_runtime": false,
		},
		"limitations": ["Capture validates the isolated production presenter source segment, not physical audio-device or NES hardware phase."],
	}
	var report_name := "godot_first_pass_route_context_3C.json" if _first_pass_route \
		else "godot_route_context_%02X.json" % _queue_id
	var report_file := FileAccess.open(OUTPUT_DIR.path_join(report_name), FileAccess.WRITE)
	if report_file == null:
		_finish_with_error("Could not write the validation capture manifest.")
		return false
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	report_file.close()
	return true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _finish_with_error(message: String) -> void:
	printerr("GODOT_ROUTE_CONTEXT_CAPTURE_BLOCKED: " + message)
	_cleanup()
	quit(2)


func _cleanup() -> void:
	if _presenter != null and is_instance_valid(_presenter):
		_presenter.call("release_rom_audio_resources")
		root.remove_child(_presenter)
		_presenter.free()
		_presenter = null
	if _capture_bus_index >= 0 and _capture_effect_index >= 0 \
			and _capture_effect_index < AudioServer.get_bus_effect_count(_capture_bus_index):
		AudioServer.remove_bus_effect(_capture_bus_index, _capture_effect_index)
	_capture_bus_index = -1
	_capture_effect_index = -1
	_capture = null
