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
const SOURCE_TIMED_CUE_ID := 0x55
const SOURCE_TIMED_CUE_MANIFEST := "res://assets/gameplay/audio/match_track_55_source_timing_rom_generated.json"
const SOURCE_TIMED_CUE_MANIFEST_SHA256 := "a1cc6a81d32bc2656e65786c0bc0ec61b60ccc1333d7c604b28f1a218a1e4045"
const CUE_MANIFESTS: Dictionary = {
	0x2B: "res://assets/gameplay/audio/match_sfx_2B_rom_generated.json",
	0x2C: "res://assets/gameplay/audio/match_sfx_2C_rom_generated.json",
	0x30: "res://assets/gameplay/audio/match_sfx_30_rom_generated.json",
	0x31: "res://assets/gameplay/audio/match_sfx_31_rom_generated.json",
	0x35: "res://assets/gameplay/audio/match_track_35_rom_generated.json",
	0x36: "res://assets/gameplay/audio/match_track_36_rom_generated.json",
	0x3C: "res://assets/gameplay/audio/match_track_3C_rom_generated.json",
	0x44: "res://assets/gameplay/audio/match_track_44_rom_generated.json",
	0x45: "res://assets/gameplay/audio/match_track_45_rom_generated.json",
	0x51: "res://assets/gameplay/audio/match_track_51_rom_generated.json",
	0x53: "res://assets/gameplay/audio/match_track_53_rom_generated.json",
	0x55: "res://assets/gameplay/audio/match_track_55_rom_generated.json",
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
var _cue_55_occurrence_index := 0
var _validated_cues: Dictionary = {}


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "RomBgmCueStream"
	add_child(_bgm_player)
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

	var cue := _validated_cue(queue_id)
	if cue.is_empty():
		return false
	if bool(cue.get("empty_sequence", false)):
		current_queue_id = queue_id
		current_source_frame = source_frame
		return true
	var stream: AudioStreamWAV = cue["stream"]
	var playback_timing: Dictionary = {}
	if queue_id == SOURCE_TIMED_CUE_ID:
		var timed_playback := _build_source_timed_cue_stream(cue, _cue_55_occurrence_index, source_frame)
		if timed_playback.is_empty():
			return false
		stream = timed_playback["stream"] as AudioStreamWAV
		playback_timing = timed_playback["timing"]
		_cue_55_occurrence_index += 1
	if str(cue["kind"]) == "bgm":
		if current_bgm_queue_id != 0:
			rom_sound_stopped.emit(current_bgm_queue_id, source_frame)
		_bgm_player.stop()
		_bgm_player.stream = stream
		_bgm_player.play(0.0)
		current_bgm_queue_id = queue_id
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


func stop_rom_audio(source_frame: int = -1) -> void:
	if current_bgm_queue_id != 0:
		rom_sound_stopped.emit(current_bgm_queue_id, source_frame)
	_bgm_player.stop()
	_bgm_player.stream = null
	for voice_index in _sfx_players.size():
		var voice := _sfx_players[voice_index]
		var stopped_sfx_id := _sfx_queue_by_voice[voice_index]
		if stopped_sfx_id != 0:
			rom_sound_stopped.emit(stopped_sfx_id, source_frame)
		voice.stop()
		voice.stream = null
		_sfx_queue_by_voice[voice_index] = 0
		_sfx_frame_by_voice[voice_index] = -1
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


func _remove_active_sfx(queue_id: int) -> void:
	var index := active_sfx_queue_ids.find(queue_id)
	if index >= 0:
		active_sfx_queue_ids.remove_at(index)


func _validated_cue(queue_id: int) -> Dictionary:
	if _validated_cues.has(queue_id):
		return _validated_cues[queue_id]
	var manifest_path := str(CUE_MANIFESTS[queue_id])
	if not FileAccess.file_exists(manifest_path):
		_fail("ROM-derived cue manifest is missing: %s" % manifest_path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		_fail("ROM-derived cue manifest is invalid: %s" % manifest_path)
		return {}
	var manifest: Dictionary = parsed
	if str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or int(_parse_hex(str(manifest.get("cue", "")))) != queue_id \
			or not ["bgm", "sound_effect"].has(str(manifest.get("cue_kind", ""))) \
			or bool(manifest.get("capture_used", true)) \
			or bool(manifest.get("captured_pcm_used", true)) \
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
	if queue_id == SOURCE_TIMED_CUE_ID:
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
	_validated_cues[queue_id] = cue
	return cue


func _validated_source_timing_manifest(queue_id: int, cue_manifest: Dictionary) -> Dictionary:
	if queue_id != SOURCE_TIMED_CUE_ID:
		return {}
	if not FileAccess.file_exists(SOURCE_TIMED_CUE_MANIFEST):
		_fail("ROM-derived source-timing manifest is missing for cue $55.")
		return {}
	var timing_manifest_bytes := FileAccess.get_file_as_bytes(SOURCE_TIMED_CUE_MANIFEST)
	if _sha256_hex(timing_manifest_bytes) != SOURCE_TIMED_CUE_MANIFEST_SHA256:
		_fail("ROM-derived source-timing manifest changed without updating its verified identity.")
		return {}
	var parsed: Variant = JSON.parse_string(timing_manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		_fail("ROM-derived source-timing manifest is invalid for cue $55.")
		return {}
	var timing: Dictionary = parsed
	if str(timing.get("schema", "")) != "ct2-rom-cue-route-source-timing-v1" \
			or str(timing.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(timing.get("cue", "")) != "$55" \
			or str(timing.get("source_audio_path", "")) != str(cue_manifest.get("wav", "")) \
			or str(timing.get("source_audio_sha256", "")) != str(cue_manifest.get("wav_sha256", "")) \
			or bool(timing.get("captured_pcm_used", true)) \
			or bool(timing.get("capture_used_as_event_input", true)) \
			or bool(timing.get("runtime_needs_rom_or_emulator", true)):
		_fail("Cue $55 source timing is not tied to the checked ROM-only audio build.")
		return {}
	var sample_rate := int(timing.get("sample_rate_hz", 0))
	var cpu_hz := int(timing.get("ntsc_cpu_hz", 0))
	var occurrences: Variant = timing.get("occurrences", [])
	if sample_rate <= 0 or cpu_hz <= 0 or not occurrences is Array or occurrences.size() < 2:
		_fail("Cue $55 source timing has no usable route occurrences.")
		return {}
	return timing


func _build_source_timed_cue_stream(cue: Dictionary, occurrence_index: int, source_frame: int) -> Dictionary:
	var source_timing: Dictionary = cue.get("source_timing", {})
	var occurrences: Array = source_timing.get("occurrences", [])
	var source_pcm: PackedByteArray = cue.get("source_pcm", PackedByteArray())
	if source_pcm.is_empty() or occurrence_index < 0 or occurrence_index >= occurrences.size():
		_fail("Cue $55 has no ROM-derived timing entry for occurrence %d." % occurrence_index)
		return {}
	var source_sample_rate := int(cue.get("source_pcm_sample_rate", 0))
	if int(cue.get("source_pcm_bits_per_sample", 0)) != 16 \
			or int(cue.get("source_pcm_channels", 0)) != 1 \
			or source_sample_rate != int(source_timing.get("sample_rate_hz", 0)):
		_fail("Cue $55 source PCM format differs from its ROM timing manifest.")
		return {}
	var occurrence_variant: Variant = occurrences[occurrence_index]
	if not occurrence_variant is Dictionary:
		_fail("Cue $55 timing occurrence %d is malformed." % occurrence_index)
		return {}
	var occurrence: Dictionary = occurrence_variant
	var delay_cycles := int(occurrence.get("delay_cycles", -1))
	var delay_samples := int(occurrence.get("delay_samples", -1))
	var sample_rate := int(source_timing.get("sample_rate_hz", 0))
	var cpu_hz := int(source_timing.get("ntsc_cpu_hz", 0))
	var expected_delay_samples := int(round(float(delay_cycles * sample_rate) / float(cpu_hz))) if cpu_hz > 0 else -1
	if delay_cycles <= 0 or delay_samples != expected_delay_samples:
		_fail("Cue $55 timing occurrence %d has inconsistent cycle/sample delay." % occurrence_index)
		return {}
	var trim_samples := int(source_timing.get("leading_zero_samples_removed", -1))
	var bytes_per_sample := 2
	var trim_bytes := trim_samples * bytes_per_sample
	if trim_samples <= 0 or trim_bytes >= source_pcm.size() \
			or int(cue.get("source_pcm_sample_count", 0)) != int(source_pcm.size() / bytes_per_sample):
		_fail("Cue $55 source-silence trim is outside the source PCM data.")
		return {}
	for byte_index in trim_bytes:
		if source_pcm[byte_index] != 0:
			_fail("Cue $55 source PCM has nonzero data inside the declared leading silence.")
			return {}
	if source_pcm[trim_bytes] == 0 and source_pcm[trim_bytes + 1] == 0:
		_fail("Cue $55 source PCM trim does not end at its first nonzero sample.")
		return {}
	var timed_data := PackedByteArray()
	timed_data.resize(delay_samples * bytes_per_sample)
	timed_data.append_array(source_pcm.slice(trim_bytes))
	var timed_stream := AudioStreamWAV.new()
	timed_stream.format = AudioStreamWAV.FORMAT_16_BITS
	timed_stream.mix_rate = source_sample_rate
	timed_stream.stereo = false
	timed_stream.data = timed_data
	timed_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return {
		"stream": timed_stream,
		"timing": {
			"occurrence_index": occurrence_index,
			"queue_source_frame": int(occurrence.get("queue_source_frame", -1)),
			"runtime_source_frame": source_frame,
			"delay_cycles": delay_cycles,
			"delay_samples": delay_samples,
			"leading_zero_samples_removed": trim_samples,
			"first_nonzero_sample_from_queue": delay_samples,
			"source_timing_path": str(source_timing.get("source_timing_path", "")),
		}
	}


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
	var normalized := value.strip_edges().to_lower().trim_prefix("0x")
	return normalized.hex_to_int() if not normalized.is_empty() else -1


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> void:
	last_error = message
	push_error(message)
