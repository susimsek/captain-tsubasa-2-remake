extends SceneTree

const AUDIO_SCRIPT := preload("res://scripts/gameplay/rom_cue_audio_presenter.gd")
const SUPPORTED_IDS: Array[int] = [0x2B, 0x2C, 0x30, 0x31, 0x35, 0x36, 0x3C, 0x44, 0x45, 0x51, 0x53, 0x55, 0x66, 0x69]
const UNSUPPORTED_IDS: Array[int] = [0x7F]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var presenter = AUDIO_SCRIPT.new()
	root.add_child(presenter)
	await process_frame
	for queue_id in SUPPORTED_IDS:
		_check(presenter.apply_rom_sound_command(queue_id, 1000 + queue_id),
			"cue $%02X loads from its verified ROM-only manifest" % queue_id)
		_check(int(presenter.current_queue_id) == queue_id,
			"cue $%02X becomes the active queue command" % queue_id)
		_check(int(presenter.current_source_frame) == 1000 + queue_id,
			"cue $%02X preserves source-frame origin" % queue_id)
		if queue_id == 0x31:
			_check(not (presenter.active_sfx_queue_ids as Array).has(0x31),
				"empty ROM sequence $31 is accepted without occupying an SFX voice")
		if queue_id == 0x55:
			_check_source_timed_cue_55(presenter, 0, 807, 4816)

	_check(presenter.apply_rom_sound_command(0x55, 2000), "BGM $55 can restart")
	_check_source_timed_cue_55(presenter, 1, 1239, 7409)
	_check(presenter.apply_rom_sound_command(0x2B, 2001), "SFX $2B can start over BGM")
	_check(int(presenter.current_bgm_queue_id) == 0x55,
		"SFX does not replace the active BGM stream")
	_check((presenter.active_sfx_queue_ids as Array).has(0x2B),
		"SFX voice records the active ROM effect")
	_check(presenter.apply_rom_sound_command(0x01, 2002), "ROM stop command is handled")
	_check(int(presenter.current_queue_id) == 0 and int(presenter.current_bgm_queue_id) == 0,
		"ROM stop command clears BGM and SFX state")
	_check((presenter.active_sfx_queue_ids as Array).is_empty(),
		"ROM stop command clears SFX voices")

	for queue_id in UNSUPPORTED_IDS:
		_check(not presenter.apply_rom_sound_command(queue_id, 3000 + queue_id),
			"unrendered route cue $%02X fails closed" % queue_id)
	_check((presenter.unsupported_queue_ids as Array).size() == UNSUPPORTED_IDS.size(),
		"unrendered cue IDs are exposed to the route integrator")

	if _failures.is_empty():
		print("PASS: fourteen ROM-only route cues load; $55 uses both ROM-timed startup variants; $01 stops all voices; unsupported cues fail closed")
		print("LIMIT: this check verifies cue loading and stream transforms only; the separate five-second Godot AudioServer $55 capture is compared against FCEUX, while full-route and hardware audio parity remain unverified")
		presenter.release_rom_audio_resources()
		root.remove_child(presenter)
		presenter.free()
		await create_timer(0.5).timeout
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		presenter.release_rom_audio_resources()
		root.remove_child(presenter)
		presenter.free()
		await create_timer(0.5).timeout
		quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _check_source_timed_cue_55(presenter: Object, occurrence_index: int, delay_samples: int, source_frame: int) -> void:
	var timing: Dictionary = presenter.get("current_playback_timing")
	_check(int(timing.get("occurrence_index", -1)) == occurrence_index,
		"cue $55 selects source timing occurrence %d" % occurrence_index)
	_check(int(timing.get("queue_source_frame", -1)) == source_frame,
		"cue $55 timing occurrence %d retains source queue frame" % occurrence_index)
	_check(int(timing.get("delay_samples", -1)) == delay_samples,
		"cue $55 uses ROM-derived %d-sample startup delay" % delay_samples)
	_check(int(timing.get("leading_zero_samples_removed", -1)) == 3065,
		"cue $55 removes only its checked 3,065-sample encoder silence")
	var bgm_player := presenter.get("_bgm_player") as AudioStreamPlayer
	var stream := bgm_player.stream as AudioStreamWAV if bgm_player != null else null
	_check(stream != null, "cue $55 timed playback has a WAV stream")
	if stream == null:
		return
	var expected_samples := 3969000 - 3065 + delay_samples
	_check(stream.data.size() == expected_samples * 2,
		"cue $55 timed stream has the source tail plus its source-timed silence")
	var prefix_bytes := delay_samples * 2
	var prefix_is_silent := true
	for byte_index in prefix_bytes:
		if stream.data[byte_index] != 0:
			prefix_is_silent = false
			break
	_check(prefix_is_silent, "cue $55 includes %d silent timing samples" % delay_samples)
	if stream.data.size() >= prefix_bytes + 2:
		_check(stream.data[prefix_bytes] != 0 or stream.data[prefix_bytes + 1] != 0,
			"cue $55 first nonzero source sample follows its timing prefix")
