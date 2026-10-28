extends SceneTree
## Capture the actual Godot AudioServer output of the first ROM-timed $55 cue.
##
## Run with:
## godot --headless --audio-driver Dummy --path . --script tools/diagnostics/capture_godot_match_track_55_audio_server.gd
##
## The resulting WAV/JSON live only under ignored reference/diagnostics/audio/.
## They are validation artifacts, never runtime assets or synthesis inputs.

const AUDIO_SCRIPT := preload("res://scripts/gameplay/rom_cue_audio_presenter.gd")
const OUTPUT_DIR := "res://reference/diagnostics/audio/godot_match_track_55_audio_server_20261028"
const OUTPUT_WAV_NAME := "godot_match_track_55_audio_server.wav"
const OUTPUT_JSON_NAME := "godot_match_track_55_audio_server.json"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_CUE_MANIFEST := "res://assets/gameplay/audio/match_track_55_rom_generated.json"
const SOURCE_TIMING_MANIFEST := "res://assets/gameplay/audio/match_track_55_source_timing_rom_generated.json"
const EXPECTED_SAMPLE_RATE := 44100
const CAPTURE_SOURCE_SECONDS := 5.0

var _capture: AudioEffectCapture
var _presenter: Node
var _captured := PackedVector2Array()
var _target_frames := 0
var _mix_rate := 0
var _capture_bus_index := -1
var _capture_effect_index := -1
var _capture_capacity_frames := 0
var _max_frames_available := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_capture = AudioEffectCapture.new()
	_mix_rate = int(AudioServer.get_mix_rate())
	if _mix_rate != EXPECTED_SAMPLE_RATE:
		_finish_with_error("AudioServer mix rate is %d Hz; this direct comparison requires %d Hz and performs no resampling." % [_mix_rate, EXPECTED_SAMPLE_RATE])
		return
	_capture_bus_index = AudioServer.get_bus_index("Master")
	if _capture_bus_index < 0:
		_finish_with_error("Godot Master audio bus was not found.")
		return
	_capture.buffer_length = 4.0
	_capture_effect_index = AudioServer.get_bus_effect_count(_capture_bus_index)
	AudioServer.add_bus_effect(_capture_bus_index, _capture)

	_presenter = AUDIO_SCRIPT.new()
	root.add_child(_presenter)
	await process_frame
	_capture.clear_buffer()
	_target_frames = int(round(CAPTURE_SOURCE_SECONDS * float(_mix_rate)))
	if not bool(_presenter.call("apply_rom_sound_command", 0x55, 4816)):
		_finish_with_error("The production route presenter could not start its first ROM-timed $55 cue: %s" % str(_presenter.get("last_error")))
		return
	var playback_timing: Dictionary = (_presenter.get("current_playback_timing") as Dictionary).duplicate(true)
	if int(playback_timing.get("occurrence_index", -1)) != 0 \
			or int(playback_timing.get("delay_samples", -1)) != 807 \
			or int(playback_timing.get("queue_source_frame", -1)) != 4816:
		_finish_with_error("First $55 capture did not select the expected source-timing entry: %s" % JSON.stringify(playback_timing))
		return

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

	_presenter.call("stop_rom_audio", 4816)
	_capture_capacity_frames = int(_capture.buffer_length * float(_mix_rate))
	if _max_frames_available >= _capture_capacity_frames:
		_finish_with_error("AudioEffectCapture backlog reached its ring-buffer capacity (%d/%d frames)." % [_max_frames_available, _capture_capacity_frames])
		return
	if not _write_capture(playback_timing):
		return
	print("GODOT_AUDIO_SERVER_CAPTURE_OK frames=%d rate=%d wav=%s" % [
		_captured.size(), _mix_rate, ProjectSettings.globalize_path(OUTPUT_DIR.path_join(OUTPUT_WAV_NAME))
	])
	print("LIMIT: capture is the Godot Master-bus mix of the production cue presenter, not the complete gameplay route or a hardware NES output.")
	_cleanup()
	await create_timer(0.1).timeout
	quit(0)


func _write_capture(playback_timing: Dictionary) -> bool:
	var directory := ProjectSettings.globalize_path(OUTPUT_DIR)
	var make_directory_error := DirAccess.make_dir_recursive_absolute(directory)
	if make_directory_error != OK:
		_finish_with_error("Could not create diagnostics-only output directory (error %d)." % make_directory_error)
		return false
	var pcm := PackedByteArray()
	pcm.resize(_captured.size() * 2)
	var first_nonzero := -1
	for frame_index in _captured.size():
		var sample := clampf((_captured[frame_index].x + _captured[frame_index].y) * 0.5, -1.0, 1.0)
		var sample_i16 := clampi(roundi(sample * 32767.0), -32768, 32767)
		pcm.encode_s16(frame_index * 2, sample_i16)
		if first_nonzero < 0 and sample_i16 != 0:
			first_nonzero = frame_index
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _mix_rate
	stream.stereo = false
	stream.data = pcm
	var wav_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(OUTPUT_WAV_NAME))
	var wav_error := stream.save_to_wav(wav_path)
	if wav_error != OK:
		_finish_with_error("Could not save the Godot audio-server PCM capture (error %d)." % wav_error)
		return false
	var wav_bytes := FileAccess.get_file_as_bytes(wav_path)
	var source_cue := _read_json(SOURCE_CUE_MANIFEST)
	var source_timing := _read_json(SOURCE_TIMING_MANIFEST)
	if source_cue.is_empty() or source_timing.is_empty():
		_finish_with_error("Could not load source cue provenance for the diagnostic manifest.")
		return false
	var manifest := {
		"purpose": "Validation-only Godot AudioServer Master-bus PCM capture of the first ROM-timed $55 cue.",
		"runtime_asset": false,
		"synthesis_input": "The project's ROM-derived $55 source WAV, played through GameplayRomCueAudioPresenter and Godot AudioServer; no captured FCEUX PCM/WAV is read by this capture process.",
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_cue_manifest": "assets/gameplay/audio/match_track_55_rom_generated.json",
		"source_cue_manifest_sha256": _sha256_hex(FileAccess.get_file_as_bytes(SOURCE_CUE_MANIFEST)),
		"source_wav": str(source_cue.get("wav", "")),
		"source_wav_sha256": str(source_cue.get("wav_sha256", "")),
		"source_timing_manifest": "assets/gameplay/audio/match_track_55_source_timing_rom_generated.json",
		"source_timing_manifest_sha256": _sha256_hex(FileAccess.get_file_as_bytes(SOURCE_TIMING_MANIFEST)),
		"queue_id": "$55",
		"queue_source_frame": 4816,
		"playback_timing": playback_timing,
		"capture": {
			"godot_version": Engine.get_version_info().get("string", "unknown"),
			"audio_driver": AudioServer.get_driver_name(),
			"audio_bus": "Master",
			"audio_effect": "AudioEffectCapture",
			"capture_origin": "AudioEffectCapture ring buffer cleared immediately before dispatching the $55 queue command; frame 0 is the first captured Godot mix sample after that clear.",
			"audio_server_mix_rate_hz": _mix_rate,
			"captured_samples": _captured.size(),
			"max_capture_buffer_backlog_frames": _max_frames_available,
			"capture_buffer_capacity_frames": _capture_capacity_frames,
			"duration_seconds": float(_captured.size()) / float(_mix_rate),
			"channels_in_saved_wav": 1,
			"quantization": "Godot Master-bus stereo float PCM averaged to mono and quantized to signed 16-bit PCM for comparison.",
			"first_nonzero_sample_from_capture_start": first_nonzero,
			"output_wav": "reference/diagnostics/audio/godot_match_track_55_audio_server_20261028/%s" % OUTPUT_WAV_NAME,
			"output_wav_sha256": _sha256_hex(wav_bytes),
			"fceux_capture_used": false,
			"rom_or_emulator_required_at_runtime": false,
		},
		"limit": "This captures only the production cue presenter's Godot audio-server output. The capture is drained once per Godot process frame with a four-second ring buffer; it is not a full route recording or physical NES audio. Compare against retained same-input FCEUX PCM in a separate validation-only step.",
	}
	var json_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(OUTPUT_JSON_NAME))
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		_finish_with_error("Could not save the diagnostic capture manifest.")
		return false
	json_file.store_string(JSON.stringify(manifest, "\t") + "\n")
	json_file.close()
	return true


func _read_json(resource_path: String) -> Dictionary:
	if not FileAccess.file_exists(resource_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(resource_path))
	return parsed if parsed is Dictionary else {}


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _finish_with_error(message: String) -> void:
	printerr("GODOT_AUDIO_SERVER_CAPTURE_BLOCKED: " + message)
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
