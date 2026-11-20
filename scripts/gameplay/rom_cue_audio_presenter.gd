extends Node
class_name GameplayRomCueAudioPresenter
## Route-local playback for offline renders built from the supplied ROM's
## sound driver and sequence bytes. This node never reads the ROM, emulator
## output, or captured WAV files at runtime.

signal rom_sound_started(queue_id: int, source_frame: int)
signal rom_sound_stopped(queue_id: int, source_frame: int)
signal unsupported_rom_sound(queue_id: int, source_frame: int)

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const STOP_QUEUE_ID := 0x01
const SOURCE_TIMED_CUE_CONFIG: Dictionary = {
	0x53: {
		"timing_path": "res://assets/gameplay/audio/match_track_53_wavehi_route_context_timing_rom_generated.json",
		"timing_sha256": "92166121547dd196e4725d2fddb0988a2792c1c68931ecb98108c0e07d232a48",
		"cue": "$53",
	},
	0x55: {
		"timing_path": "res://assets/gameplay/audio/first_command_menu_route_wavehi_source_timing_rom_generated.json",
		"timing_sha256": "42f6a1c183bb79dbbe4b1787636fd48ff314bd6c8bc2837dfca855131c5882bc",
		"cue": "$55",
		"schema": "ct2-rom-cue-wavehi-route-context-timing-v1",
		"required_occurrences": 1,
	},
	0x3C: {
		"timing_path": "res://assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.json",
		"timing_sha256": "f171d0cef0420e3c23272b49adc7fe19085972b00098a31647f49cf0dd6e2a81",
		"cue": "$3C",
		"schema": "ct2-rom-wavehi-pass-route-context-v1",
		"required_occurrences": 1,
		"replace_embedded_context": true,
	},
}
const MIXED_ROUTE_SFX_IDS: Array[int] = [0x66, 0x2B, 0x2C]
const CUE_MANIFESTS: Dictionary = {
	0x2B: "res://assets/gameplay/audio/match_sfx_2B_rom_generated.json",
	0x2C: "res://assets/gameplay/audio/match_sfx_2C_rom_generated.json",
	0x30: "res://assets/gameplay/audio/match_sfx_30_rom_generated.json",
	0x31: "res://assets/gameplay/audio/match_sfx_31_rom_generated.json",
	0x35: "res://assets/gameplay/audio/match_track_35_rom_generated.json",
	0x36: "res://assets/gameplay/audio/match_track_36_rom_generated.json",
	0x3C: "res://assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.json",
	0x44: "res://assets/gameplay/audio/match_track_44_rom_generated.json",
	0x45: "res://assets/gameplay/audio/match_track_45_rom_generated.json",
	0x51: "res://assets/gameplay/audio/match_track_51_rom_generated.json",
	0x53: "res://assets/gameplay/audio/match_track_53_wavehi_route_context_rom_generated.json",
	0x55: "res://assets/gameplay/audio/first_command_menu_route_wavehi_rom_generated.json",
	0x66: "res://assets/gameplay/audio/match_sfx_66_rom_generated.json",
	0x69: "res://assets/gameplay/audio/match_sfx_69_rom_generated.json",
}
const SFX_VOICE_COUNT := 4

var current_queue_id := 0
var current_source_frame := -1
var current_bgm_queue_id := 0
var current_playback_timing: Dictionary = {}
var active_sfx_queue_ids: Array[int] = []
var unsupported_queue_ids: Array[int] = []
var last_error := ""

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_queue_by_voice: Array[int] = []
var _sfx_frame_by_voice: Array[int] = []
var _next_sfx_voice := 0
var _source_timed_occurrence_indices: Dictionary = {}
var _active_source_timed_stop_source_frames: Array[int] = []
var _active_source_timed_bgm_queue_id := 0
var _active_source_timed_embedded_sfx_ids: Array[int] = []
var _active_source_timed_embedded_bgm_ids: Array[int] = []
var _active_source_timed_start_source_frame := -1
var _active_source_timed_end_source_frame := -1
var _mixed_route_sfx_queue_ids: Array[int] = []
var _validated_cues: Dictionary = {}


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "RomBgmCueStream"
	add_child(_bgm_player)
	_bgm_player.finished.connect(_on_bgm_finished)
	for voice_index in SFX_VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.name = "RomSfxVoice%d" % voice_index
		add_child(voice)
		_sfx_players.append(voice)
		_sfx_queue_by_voice.append(0)
		_sfx_frame_by_voice.append(-1)
		voice.finished.connect(_on_sfx_voice_finished.bind(voice_index))


## Dispatch a ROM sound-queue value. `$01` is the verified stop/control value;
## only cues with checked ROM-only renders are played. Unknown queue IDs are
## surfaced instead of being mapped to a guessed sound.
func apply_rom_sound_command(queue_id: int, source_frame: int = -1) -> bool:
	last_error = ""
	if queue_id == STOP_QUEUE_ID:
		stop_rom_audio(source_frame)
		return true
	if not CUE_MANIFESTS.has(queue_id):
		if not unsupported_queue_ids.has(queue_id):
			unsupported_queue_ids.append(queue_id)
		unsupported_rom_sound.emit(queue_id, source_frame)
		return false
	if _is_embedded_route_bgm_transition(queue_id, source_frame):
		if current_bgm_queue_id != 0 and current_bgm_queue_id != queue_id:
			rom_sound_stopped.emit(current_bgm_queue_id, source_frame)
		current_bgm_queue_id = queue_id
		current_queue_id = queue_id
		current_source_frame = source_frame
		rom_sound_started.emit(queue_id, source_frame)
		return true
	if _is_embedded_in_active_route_mix(queue_id, source_frame):
		active_sfx_queue_ids.append(queue_id)
		_mixed_route_sfx_queue_ids.append(queue_id)
		current_queue_id = queue_id
		current_source_frame = source_frame
		rom_sound_started.emit(queue_id, source_frame)
		return true

	var cue := _validated_cue(queue_id)
	if cue.is_empty():
		return false
	if bool(cue.get("empty_sequence", false)):
		current_queue_id = queue_id
		current_source_frame = source_frame
		return true
	var stream: AudioStreamWAV = cue["stream"]
	var playback_timing: Dictionary = {}
	if SOURCE_TIMED_CUE_CONFIG.has(queue_id):
		var occurrence_index := int(_source_timed_occurrence_indices.get(queue_id, 0)) if queue_id == 0x55 else 0
		var timed_playback := _build_source_timed_cue_stream(cue, occurrence_index, source_frame)
		if timed_playback.is_empty():
			return false
		stream = timed_playback["stream"] as AudioStreamWAV
		playback_timing = timed_playback["timing"]
		_source_timed_occurrence_indices[queue_id] = occurrence_index + 1
	if str(cue["kind"]) == "bgm":
		if _is_embedded_route_bgm_transition(queue_id, source_frame):
			if current_bgm_queue_id != 0 and current_bgm_queue_id != queue_id:
				rom_sound_stopped.emit(current_bgm_queue_id, source_frame)
			current_bgm_queue_id = queue_id
		else:
			if current_bgm_queue_id != 0:
				rom_sound_stopped.emit(current_bgm_queue_id, source_frame)
			_finish_mixed_route_sfx(source_frame)
			_bgm_player.stop()
			_bgm_player.stream = stream
			_bgm_player.play(0.0)
			current_bgm_queue_id = queue_id
			_clear_active_source_timing()
			if SOURCE_TIMED_CUE_CONFIG.has(queue_id):
				_active_source_timed_bgm_queue_id = queue_id
				_active_source_timed_embedded_sfx_ids = _int_array(playback_timing.get("embedded_sfx_queue_ids", []))
				_active_source_timed_embedded_bgm_ids = _int_array(playback_timing.get("embedded_bgm_queue_ids", []))
				_active_source_timed_start_source_frame = int(playback_timing.get("queue_source_frame", -1))
				_active_source_timed_end_source_frame = int(playback_timing.get("source_end_frame", -1))
				for stop_frame_variant in playback_timing.get("stop_queue_source_frames", []):
					_active_source_timed_stop_source_frames.append(int(stop_frame_variant))
	else:
		if _is_embedded_in_active_route_mix(queue_id, source_frame):
			active_sfx_queue_ids.append(queue_id)
			_mixed_route_sfx_queue_ids.append(queue_id)
		else:
			if _sfx_players.is_empty():
				_fail("No ROM SFX voices were created.")
				return false
			var voice_index := _next_sfx_voice
			_next_sfx_voice = (_next_sfx_voice + 1) % _sfx_players.size()
			var voice := _sfx_players[voice_index]
			var replaced_sfx_id := _sfx_queue_by_voice[voice_index]
			if replaced_sfx_id != 0:
				_remove_active_sfx(replaced_sfx_id)
				rom_sound_stopped.emit(replaced_sfx_id, source_frame)
			voice.stop()
			voice.stream = stream
			voice.play(0.0)
			_sfx_queue_by_voice[voice_index] = queue_id
			_sfx_frame_by_voice[voice_index] = source_frame
			active_sfx_queue_ids.append(queue_id)
	current_queue_id = queue_id
	current_source_frame = source_frame
	current_playback_timing = playback_timing
	rom_sound_started.emit(queue_id, source_frame)
	return true


## Apply a typed request inserted by the ROM's `$CBF1-$CBFE` helper. The
## event's source-route frame is forwarded as frame metadata; this API does not
## add or infer CPU-cycle/subframe timing.
func apply_rom_cbf1_queue_insert(event: RomSoundQueueWriteEvent) -> bool:
	if event == null or not event.is_valid_cbf1_queue_insert():
		last_error = "ROM `$CBFE` queue insertion failed its source provenance checks."
		return false
	return apply_rom_sound_command(event.queue_id, event.source_frame)


## Apply the first fresh-match stop request only from the verified
## `$DAAA->$CBF1->$CC01` queue-write event.
func apply_rom_fresh_daaa_queue_insert(event: RomSoundQueueWriteEvent) -> bool:
	if event == null or not event.is_valid_fresh_daaa_queue_insert():
		last_error = "Fresh ROM `$DAAA->$CBF1->$CC01` queue request failed provenance checks."
		return false
	return apply_rom_sound_command(event.queue_id, event.source_frame)


func stop_rom_audio(source_frame: int = -1) -> void:
	# The ROM sends more than one `$01` stop during a cue. Keep the exact
	# source-rendered APU/filters tail until the next BGM queue replaces it.
	var keep_source_timed_bgm_tail := _active_source_timed_stop_source_frames.has(source_frame)
	if current_bgm_queue_id != 0:
		rom_sound_stopped.emit(current_bgm_queue_id, source_frame)
	if not keep_source_timed_bgm_tail:
		_bgm_player.stop()
		_bgm_player.stream = null
		_clear_active_source_timing()
	for voice_index in _sfx_players.size():
		var voice := _sfx_players[voice_index]
		var stopped_sfx_id := _sfx_queue_by_voice[voice_index]
		if stopped_sfx_id != 0:
			rom_sound_stopped.emit(stopped_sfx_id, source_frame)
		voice.stop()
		voice.stream = null
		_sfx_queue_by_voice[voice_index] = 0
		_sfx_frame_by_voice[voice_index] = -1
	_finish_mixed_route_sfx(source_frame)
	current_queue_id = 0
	current_bgm_queue_id = 0
	current_playback_timing.clear()
	active_sfx_queue_ids.clear()
	current_source_frame = source_frame


## Stop any active cue and release project WAV references during route teardown.
func release_rom_audio_resources() -> void:
	stop_rom_audio(current_source_frame)
	_validated_cues.clear()


func _exit_tree() -> void:
	release_rom_audio_resources()


func is_rom_audio_playing() -> bool:
	if _bgm_player != null and _bgm_player.playing:
		return true
	for voice in _sfx_players:
		if voice.playing:
			return true
	return false


func _on_sfx_voice_finished(voice_index: int) -> void:
	if voice_index < 0 or voice_index >= _sfx_queue_by_voice.size():
		return
	var stopped_id := _sfx_queue_by_voice[voice_index]
	if stopped_id == 0:
		return
	_remove_active_sfx(stopped_id)
	_sfx_queue_by_voice[voice_index] = 0
	var source_frame := _sfx_frame_by_voice[voice_index]
	_sfx_frame_by_voice[voice_index] = -1
	rom_sound_stopped.emit(stopped_id, source_frame)


func _on_bgm_finished() -> void:
	if current_bgm_queue_id != 0:
		rom_sound_stopped.emit(current_bgm_queue_id, current_source_frame)
	current_bgm_queue_id = 0
	_clear_active_source_timing()
	_finish_mixed_route_sfx(current_source_frame)
	if _bgm_player != null:
		_bgm_player.stream = null


func _remove_active_sfx(queue_id: int) -> void:
	var index := active_sfx_queue_ids.find(queue_id)
	if index >= 0:
		active_sfx_queue_ids.remove_at(index)


func _is_embedded_in_active_route_mix(queue_id: int, source_frame: int) -> bool:
	return MIXED_ROUTE_SFX_IDS.has(queue_id) \
			and _active_source_timed_bgm_queue_id in [0x55, 0x53, 0x3C] \
			and _active_source_timed_embedded_sfx_ids.has(queue_id) \
			and _bgm_player != null and _bgm_player.playing \
			and source_frame >= _active_source_timed_start_source_frame \
			and source_frame <= _active_source_timed_end_source_frame


func _is_embedded_route_bgm_transition(queue_id: int, source_frame: int) -> bool:
	if queue_id == 0x3C and bool(SOURCE_TIMED_CUE_CONFIG[queue_id].get("replace_embedded_context", false)):
		return false
	return SOURCE_TIMED_CUE_CONFIG.has(queue_id) \
			and _active_source_timed_bgm_queue_id in [0x55, 0x53, 0x3C] \
			and _active_source_timed_embedded_bgm_ids.has(queue_id) \
			and source_frame >= _active_source_timed_start_source_frame \
			and source_frame <= _active_source_timed_end_source_frame


func _finish_mixed_route_sfx(source_frame: int) -> void:
	for queue_id in _mixed_route_sfx_queue_ids:
		_remove_active_sfx(queue_id)
		rom_sound_stopped.emit(queue_id, source_frame)
	_mixed_route_sfx_queue_ids.clear()


func _clear_active_source_timing() -> void:
	_active_source_timed_stop_source_frames.clear()
	_active_source_timed_bgm_queue_id = 0
	_active_source_timed_embedded_sfx_ids.clear()
	_active_source_timed_embedded_bgm_ids.clear()
	_active_source_timed_start_source_frame = -1
	_active_source_timed_end_source_frame = -1


func _int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	if values is Array:
		for value in values:
			result.append(int(value))
	return result


func _validated_cue(queue_id: int) -> Dictionary:
	if _validated_cues.has(queue_id):
		return _validated_cues[queue_id]
	var manifest: Dictionary = {}
	if queue_id == 0x3C:
		manifest = _validated_pass_context_cue_manifest()
		if manifest.is_empty():
			return {}
	else:
		var manifest_path := str(CUE_MANIFESTS[queue_id])
		if not FileAccess.file_exists(manifest_path):
			_fail("ROM-derived cue manifest is missing: %s" % manifest_path)
			return {}
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not parsed is Dictionary:
			_fail("ROM-derived cue manifest is invalid: %s" % manifest_path)
			return {}
		manifest = parsed
	if str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or int(_parse_hex(str(manifest.get("cue", "")))) != queue_id \
			or not ["bgm", "sound_effect"].has(str(manifest.get("cue_kind", ""))) \
			or bool(manifest.get("capture_used", true)) \
			or bool(manifest.get("captured_pcm_used", true)) \
			or bool(manifest.get("captured_wav_used", false)) \
			or bool(manifest.get("runtime_needs_rom_or_emulator", true)):
		_fail("Cue manifest does not establish this ROM-derived, capture-free standalone cue.")
		return {}
	var audio_path := str(manifest.get("wav", ""))
	if not audio_path.begins_with("assets/gameplay/audio/") or audio_path.contains(".."):
		_fail("Cue WAV path is outside the project-owned gameplay audio directory.")
		return {}
	var project_audio_path := "res://" + audio_path
	var audio_bytes := FileAccess.get_file_as_bytes(project_audio_path)
	var expected_sha256 := str(manifest.get("wav_sha256", ""))
	if audio_bytes.is_empty() or expected_sha256.is_empty() \
			or _sha256_hex(audio_bytes) != expected_sha256:
		_fail("ROM-derived cue WAV is missing or differs from its recorded SHA-256.")
		return {}
	var stream := load(project_audio_path) as AudioStreamWAV
	if stream == null:
		_fail("ROM-derived cue did not import as AudioStreamWAV: %s" % project_audio_path)
		return {}
	var cue := {
		"kind": str(manifest["cue_kind"]),
		"stream": stream,
		"empty_sequence": bool(manifest.get("empty_sequence", false)),
	}
	if SOURCE_TIMED_CUE_CONFIG.has(queue_id):
		var source_timing := _validated_source_timing_manifest(queue_id, manifest)
		if source_timing.is_empty():
			return {}
		var pcm_info := _decode_pcm_wave_file(audio_bytes)
		if pcm_info.is_empty():
			return {}
		cue["source_timing"] = source_timing
		cue["source_pcm"] = pcm_info["data"]
		cue["source_pcm_sample_rate"] = int(pcm_info["sample_rate"])
		cue["source_pcm_channels"] = int(pcm_info["channels"])
		cue["source_pcm_bits_per_sample"] = int(pcm_info["bits_per_sample"])
		cue["source_pcm_sample_count"] = int(pcm_info["sample_count"])
		cue["source_timing_path"] = str(SOURCE_TIMED_CUE_CONFIG[queue_id]["timing_path"])
	_validated_cues[queue_id] = cue
	return cue


func _validated_pass_context_cue_manifest() -> Dictionary:
	var config: Dictionary = SOURCE_TIMED_CUE_CONFIG[0x3C]
	var sidecar_path := str(config.get("timing_path", ""))
	if sidecar_path != str(CUE_MANIFESTS[0x3C]) or not FileAccess.file_exists(sidecar_path):
		_fail("The first-pass `$3C` source sidecar is missing or differs from its cue config.")
		return {}
	var sidecar_bytes := FileAccess.get_file_as_bytes(sidecar_path)
	if _sha256_hex(sidecar_bytes) != str(config.get("timing_sha256", "")):
		_fail("The first-pass `$3C` source sidecar changed without updating its verified identity.")
		return {}
	var parsed: Variant = JSON.parse_string(sidecar_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		_fail("The first-pass `$3C` source sidecar is invalid JSON.")
		return {}
	var sidecar: Dictionary = parsed
	var asset_variant: Variant = sidecar.get("asset", {})
	var source_variant: Variant = sidecar.get("source", {})
	var renderer_variant: Variant = source_variant.get("wavehi_renderer", {}) if source_variant is Dictionary else {}
	if str(sidecar.get("schema", "")) != str(config.get("schema", "")) \
			or not asset_variant is Dictionary or not source_variant is Dictionary \
			or not renderer_variant is Dictionary:
		_fail("The first-pass `$3C` sidecar does not match its configured ROM-derived schema.")
		return {}
	var asset: Dictionary = asset_variant
	var source: Dictionary = source_variant
	var renderer: Dictionary = renderer_variant
	var audio_path := str(asset.get("path", ""))
	if str(source.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(source.get("start_event", {}).get("queue_id", "")) != "$3C" \
			or int(source.get("start_event", {}).get("frame", -1)) != 8607 \
			or int(source.get("end_event", {}).get("frame", -1)) != 9600 \
			or not bool(asset.get("runtime_candidate", false)) \
			or bool(asset.get("rom_or_emulator_required_at_runtime", true)) \
			or bool(renderer.get("captured_pcm_or_wav_used_as_synthesis_input", true)) \
			or bool(renderer.get("fceux_trace_used_for_scheduling", true)) \
			or not audio_path.begins_with("assets/gameplay/audio/") or audio_path.contains(".."):
		_fail("The first-pass `$3C` sidecar does not establish the expected standalone ROM-derived audio asset.")
		return {}
	return {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"cue": "$3C",
		"cue_kind": "bgm",
		"capture_used": false,
		"captured_pcm_used": false,
		"captured_wav_used": false,
		"runtime_needs_rom_or_emulator": false,
		"wav": audio_path,
		"wav_sha256": str(asset.get("sha256", "")),
	}


func _validated_source_timing_manifest(queue_id: int, cue_manifest: Dictionary) -> Dictionary:
	if not SOURCE_TIMED_CUE_CONFIG.has(queue_id):
		return {}
	var config: Dictionary = SOURCE_TIMED_CUE_CONFIG[queue_id]
	var timing_path := str(config["timing_path"])
	if not FileAccess.file_exists(timing_path):
		_fail("ROM-derived source-timing manifest is missing for cue %s." % str(config["cue"]))
		return {}
	var timing_manifest_bytes := FileAccess.get_file_as_bytes(timing_path)
	if _sha256_hex(timing_manifest_bytes) != str(config["timing_sha256"]):
		_fail("Cue %s source-timing manifest changed without updating its verified identity." % str(config["cue"]))
		return {}
	var parsed: Variant = JSON.parse_string(timing_manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		_fail("ROM-derived source-timing manifest is invalid for cue %s." % str(config["cue"]))
		return {}
	var timing: Dictionary = parsed
	if queue_id == 0x3C and str(timing.get("schema", "")) == str(config.get("schema", "")):
		return _validated_first_pass_context_timing(timing, cue_manifest)
	if str(timing.get("schema", "")) != str(config.get("schema", "ct2-rom-cue-wavehi-route-context-timing-v1")) \
			or str(timing.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(timing.get("cue", "")) != str(config["cue"]) \
			or str(timing.get("source_audio_path", "")) != str(cue_manifest.get("wav", "")) \
			or str(timing.get("source_audio_sha256", "")) != str(cue_manifest.get("wav_sha256", "")) \
			or bool(timing.get("captured_pcm_used", true)) \
			or bool(timing.get("captured_wav_used", false)) \
			or bool(timing.get("capture_used_as_event_input", true)) \
			or bool(timing.get("runtime_needs_rom_or_emulator", true)):
		_fail("Cue %s source timing is not tied to the checked ROM-only audio build." % str(config["cue"]))
		return {}
	var sample_rate := int(timing.get("sample_rate_hz", 0))
	var cpu_hz := int(timing.get("ntsc_cpu_hz", 0))
	var occurrences: Variant = timing.get("occurrences", [])
	var required_occurrences := int(config.get("required_occurrences", 1))
	if sample_rate <= 0 or cpu_hz <= 0 or not occurrences is Array or occurrences.size() < required_occurrences:
		_fail("Cue %s source timing has no usable route occurrences." % str(config["cue"]))
		return {}
	return timing


func _validated_first_pass_context_timing(sidecar: Dictionary, cue_manifest: Dictionary) -> Dictionary:
	var asset_variant: Variant = sidecar.get("asset", {})
	var source_variant: Variant = sidecar.get("source", {})
	var validation_variant: Variant = sidecar.get("validation", {})
	if not asset_variant is Dictionary or not source_variant is Dictionary \
			or not validation_variant is Dictionary:
		_fail("The first-pass `$3C` sidecar is missing asset, source, or validation metadata.")
		return {}
	var asset: Dictionary = asset_variant
	var source: Dictionary = source_variant
	var validation: Dictionary = validation_variant
	var start_event: Dictionary = source.get("start_event", {})
	var end_event: Dictionary = source.get("end_event", {})
	var frame_range: Array = source.get("frame_range_inclusive", [])
	var events: Array = source.get("embedded_queue_events", [])
	var sample_rate := int(asset.get("sample_rate_hz", 0))
	var sample_count := int(asset.get("sample_count", 0))
	var cpu_hz := 1789773
	if str(source.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(start_event.get("queue_id", "")) != "$3C" \
			or int(start_event.get("frame", -1)) != 8607 \
			or int(end_event.get("frame", -1)) != 9600 \
			or frame_range.size() != 2 \
			or int(frame_range[0]) != 8607 or int(frame_range[1]) != 9600 \
			or str(cue_manifest.get("wav", "")) != str(asset.get("path", "")) \
			or str(cue_manifest.get("wav_sha256", "")) != str(asset.get("sha256", "")) \
			or sample_rate != 44100 or sample_count <= 0 \
			or int(asset.get("channels", 0)) != 1 \
			or int(asset.get("bits_per_sample", 0)) != 16 \
			or not bool(asset.get("runtime_candidate", false)) \
			or bool(asset.get("rom_or_emulator_required_at_runtime", true)) \
			or str(asset.get("sample_index_formula", "")).find(str(cpu_hz)) < 0 \
			or not bool(validation.get("apu_frame_address_value_sequence_exact", false)) \
			or bool(validation.get("fceux_wav_or_pcm_compared", true)) \
			or bool(validation.get("fceux_wav_or_pcm_used_as_synthesis_input", true)) \
			or events.is_empty():
		_fail("The first-pass `$3C` source sidecar does not match its checked asset/provenance bounds.")
		return {}
	var embedded_events: Array[Dictionary] = []
	for event_variant in events:
		if not event_variant is Dictionary:
			_fail("The first-pass `$3C` sidecar contains a malformed embedded queue event.")
			return {}
		var event: Dictionary = event_variant
		var queue_id := _parse_hex(str(event.get("queue_id", "")))
		var event_frame := int(event.get("frame", -1))
		if not MIXED_ROUTE_SFX_IDS.has(queue_id) or event_frame < 8607 or event_frame > 9600:
			_fail("The first-pass `$3C` sidecar contains an out-of-window or non-SFX queue event.")
			return {}
		embedded_events.append({
			"source_frame": event_frame,
			"queue_id": str(event.get("queue_id", "")),
		})
	return {
		"schema": "ct2-rom-cue-wavehi-route-context-timing-v1",
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"cue": "$3C",
		"source_audio_path": str(asset.get("path", "")),
		"source_audio_sha256": str(asset.get("sha256", "")),
		"sample_rate_hz": sample_rate,
		"ntsc_cpu_hz": cpu_hz,
		"captured_pcm_used": false,
		"captured_wav_used": false,
		"capture_used_as_event_input": false,
		"runtime_needs_rom_or_emulator": false,
		"occurrences": [{
			"occurrence_index": 0,
			"queue_id": "$3C",
			"queue_source_frame": 8607,
			"queue_source_cycle": int(start_event.get("cycle", -1)),
			"delay_cycles": 0,
			"delay_samples": 0,
			"asset_sample_window": [0, sample_count],
			"embedded_queue_events": embedded_events,
			"source_end": {"source_frame": 9600},
		}],
	}


func _build_source_timed_cue_stream(cue: Dictionary, occurrence_index: int, source_frame: int) -> Dictionary:
	var source_timing: Dictionary = cue.get("source_timing", {})
	var occurrences: Array = source_timing.get("occurrences", [])
	var source_pcm: PackedByteArray = cue.get("source_pcm", PackedByteArray())
	var cue_name := str(source_timing.get("cue", "source-timed cue"))
	if source_pcm.is_empty() or occurrence_index < 0 or occurrence_index >= occurrences.size():
		_fail("Cue %s has no ROM-derived timing entry for occurrence %d." % [cue_name, occurrence_index])
		return {}
	var source_sample_rate := int(cue.get("source_pcm_sample_rate", 0))
	if int(cue.get("source_pcm_bits_per_sample", 0)) != 16 \
			or int(cue.get("source_pcm_channels", 0)) != 1 \
			or source_sample_rate != int(source_timing.get("sample_rate_hz", 0)):
		_fail("Cue %s source PCM format differs from its ROM timing manifest." % cue_name)
		return {}
	var occurrence_variant: Variant = occurrences[occurrence_index]
	if not occurrence_variant is Dictionary:
		_fail("Cue %s timing occurrence %d is malformed." % [cue_name, occurrence_index])
		return {}
	var occurrence: Dictionary = occurrence_variant
	var delay_cycles := int(occurrence.get("delay_cycles", 0))
	var delay_samples := int(occurrence.get("delay_samples", 0))
	var sample_rate := int(source_timing.get("sample_rate_hz", 0))
	var cpu_hz := int(source_timing.get("ntsc_cpu_hz", 0))
	var expected_delay_samples := int(round(float(delay_cycles * sample_rate) / float(cpu_hz))) if cpu_hz > 0 else -1
	if delay_cycles < 0 or delay_samples != expected_delay_samples \
			or str(source_timing.get("schema", "")) == "ct2-rom-cue-wavehi-occurrence-timing-v1" and delay_cycles <= 0:
		_fail("Cue %s timing occurrence %d has inconsistent cycle/sample delay." % [cue_name, occurrence_index])
		return {}
	var bytes_per_sample := 2
	var pcm_sample_count := int(cue.get("source_pcm_sample_count", 0))
	if pcm_sample_count != int(source_pcm.size() / bytes_per_sample):
		_fail("Cue %s packed PCM sample count differs from its WAV data." % cue_name)
		return {}
	var asset_window: Variant = occurrence.get("asset_sample_window", [])
	if not asset_window is Array or asset_window.size() != 2:
		_fail("Cue %s occurrence %d has no checked packed-asset sample window." % [cue_name, occurrence_index])
		return {}
	var asset_start := int(asset_window[0])
	var asset_end := int(asset_window[1])
	if asset_start < 0 or asset_end <= asset_start or asset_end > pcm_sample_count \
			or int(occurrence.get("queue_source_frame", -1)) < 0:
		_fail("Cue %s occurrence %d has invalid ROM event or PCM bounds." % [cue_name, occurrence_index])
		return {}
	var timed_data := source_pcm.slice(asset_start * bytes_per_sample, asset_end * bytes_per_sample)
	if timed_data.size() != (asset_end - asset_start) * bytes_per_sample:
		_fail("Cue %s occurrence %d PCM slice was truncated." % [cue_name, occurrence_index])
		return {}
	var timed_stream := AudioStreamWAV.new()
	timed_stream.format = AudioStreamWAV.FORMAT_16_BITS
	timed_stream.mix_rate = source_sample_rate
	timed_stream.stereo = false
	timed_stream.data = timed_data
	timed_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var source_end: Dictionary = occurrence.get("source_end", {})
	return {
		"stream": timed_stream,
		"timing": {
			"occurrence_index": occurrence_index,
			"cue": cue_name,
			"queue_source_frame": int(occurrence.get("queue_source_frame", -1)),
			"runtime_source_frame": source_frame,
			"delay_cycles": delay_cycles,
			"delay_samples": delay_samples,
			"first_pulse_register_write_from_queue": delay_samples,
			"stop_queue_source_frame": int(occurrence.get("stop_queue_source_frame", -1)),
			"stop_queue_source_cycle": int(occurrence.get("stop_queue_source_cycle", -1)),
			"stop_queue_source_frames": _stop_queue_source_frames(occurrence),
			"embedded_sfx_queue_ids": _embedded_sfx_queue_ids(occurrence),
			"embedded_bgm_queue_ids": _embedded_bgm_queue_ids(occurrence),
			"embedded_sfx_source_frames": _embedded_sfx_source_frames(occurrence),
			"source_end_frame": int(source_end.get("source_frame", occurrence.get("next_bgm_queue_source_frame", -1))),
			"verification_sample_count": int(occurrence.get("verification_sample_count", 0)),
			"verification_asset_sample_window": occurrence.get("verification_asset_sample_window", []),
			"first_apu_mute_write": occurrence.get("first_apu_mute_write", {}),
			"last_apu_mute_write": occurrence.get("last_apu_mute_write", {}),
			"muted_channel_addresses": occurrence.get("muted_channel_addresses", []),
			"asset_sample_window": [asset_start, asset_end],
			"renderer_global_sample_window": occurrence.get("renderer_global_sample_window", []),
			"next_bgm_queue_id": str(occurrence.get("next_bgm_queue_id", "")),
			"next_bgm_queue_source_frame": int(occurrence.get("next_bgm_queue_source_frame", -1)),
			"source_timing_path": str(cue.get("source_timing_path", "")).trim_prefix("res://"),
		}
	}


func _stop_queue_source_frames(occurrence: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var route_frames: Variant = occurrence.get("stop_tail_source_frames", [])
	if route_frames is Array:
		for frame in route_frames:
			result.append(int(frame))
		if not result.is_empty():
			return result
	var events: Variant = occurrence.get("stop_queue_events", [])
	if events is Array:
		for event_variant in events:
			if event_variant is Dictionary and str(event_variant.get("queue_id", "")) == "$01":
				result.append(int(event_variant.get("source_frame", -1)))
	return result


func _embedded_sfx_queue_ids(occurrence: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var events: Variant = occurrence.get("embedded_queue_events", [])
	if events is Array:
		for event_variant in events:
			if event_variant is Dictionary:
				result.append(_parse_hex(str(event_variant.get("queue_id", ""))))
	return result


func _embedded_sfx_source_frames(occurrence: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var events: Variant = occurrence.get("embedded_queue_events", [])
	if events is Array:
		for event_variant in events:
			if event_variant is Dictionary:
				result.append(int(event_variant.get("source_frame", -1)))
	return result


func _embedded_bgm_queue_ids(occurrence: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var events: Variant = occurrence.get("embedded_bgm_queue_events", [])
	if events is Array:
		for event_variant in events:
			if event_variant is Dictionary:
				result.append(_parse_hex(str(event_variant.get("queue_id", ""))))
	return result


func _decode_pcm_wave_file(wav_bytes: PackedByteArray) -> Dictionary:
	if wav_bytes.size() < 44 or wav_bytes.slice(0, 4).get_string_from_ascii() != "RIFF" \
			or wav_bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		_fail("Cue $55 source is not a RIFF/WAVE file.")
		return {}
	var offset := 12
	var format_tag := -1
	var channels := 0
	var sample_rate := 0
	var bits_per_sample := 0
	var pcm_data := PackedByteArray()
	while offset + 8 <= wav_bytes.size():
		var chunk_id := wav_bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := int(wav_bytes.decode_u32(offset + 4))
		var payload_start := offset + 8
		var payload_end := payload_start + chunk_size
		if chunk_size < 0 or payload_end > wav_bytes.size():
			_fail("Cue $55 source WAVE has a malformed chunk length.")
			return {}
		if chunk_id == "fmt ":
			if chunk_size < 16:
				_fail("Cue $55 source WAVE format chunk is truncated.")
				return {}
			format_tag = int(wav_bytes.decode_u16(payload_start))
			channels = int(wav_bytes.decode_u16(payload_start + 2))
			sample_rate = int(wav_bytes.decode_u32(payload_start + 4))
			bits_per_sample = int(wav_bytes.decode_u16(payload_start + 14))
		elif chunk_id == "data":
			pcm_data = wav_bytes.slice(payload_start, payload_end)
		offset = payload_end + (chunk_size & 1)
	if format_tag != 1 or channels != 1 or sample_rate <= 0 or bits_per_sample != 16 \
			or pcm_data.is_empty() or pcm_data.size() % 2 != 0:
		_fail("Cue $55 source WAVE is not the expected mono 16-bit PCM format.")
		return {}
	return {
		"data": pcm_data,
		"sample_rate": sample_rate,
		"channels": channels,
		"bits_per_sample": bits_per_sample,
		"sample_count": pcm_data.size() / 2,
	}


func _parse_hex(value: String) -> int:
	var normalized := value.strip_edges().to_lower()
	if normalized.begins_with("$"):
		normalized = normalized.substr(1)
	normalized = normalized.trim_prefix("0x")
	return normalized.hex_to_int() if not normalized.is_empty() else -1


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> void:
	last_error = message
	push_error(message)
