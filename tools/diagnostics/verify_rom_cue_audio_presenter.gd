extends SceneTree

const AUDIO_SCRIPT := preload("res://scripts/gameplay/rom_cue_audio_presenter.gd")
const SOUND_QUEUE_EVENT := preload("res://scripts/gameplay/rom_sound_queue_write_event.gd")
const ISOLATED_CUE_IDS: Array[int] = [0x2B, 0x2C, 0x30, 0x31, 0x35, 0x36, 0x3C, 0x44, 0x45, 0x51, 0x53, 0x66, 0x69]
const UNSUPPORTED_IDS: Array[int] = [0x7F]

var _failures: Array[String] = []
var _started_events: Array[Array] = []
var _stopped_events: Array[Array] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var presenter = AUDIO_SCRIPT.new()
	root.add_child(presenter)
	presenter.rom_sound_started.connect(_on_sound_started)
	presenter.rom_sound_stopped.connect(_on_sound_stopped)
	await process_frame
	for queue_id in ISOLATED_CUE_IDS:
		_check(presenter.apply_rom_sound_command(queue_id, 1000 + queue_id),
			"isolated cue $%02X loads from its checked ROM-only manifest" % queue_id)
		_check(int(presenter.current_queue_id) == queue_id,
			"isolated cue $%02X preserves its queue command" % queue_id)
		_check(int(presenter.current_source_frame) == 1000 + queue_id,
			"isolated cue $%02X preserves source-frame metadata" % queue_id)
		if queue_id == 0x31:
			_check(not (presenter.active_sfx_queue_ids as Array).has(0x31),
				"empty ROM sequence $31 does not occupy an SFX voice")
	_started_events.clear()
	_stopped_events.clear()

	_check(presenter.apply_rom_sound_command(0x55, 4816), "first $55 starts the ROM-derived first-menu route mix")
	var bgm_player := presenter.get("_bgm_player") as AudioStreamPlayer
	var route_stream := bgm_player.stream if bgm_player != null else null
	var route_timing: Dictionary = presenter.get("current_playback_timing")
	_check(route_stream is AudioStreamWAV, "$55 route context is loaded as a WAV stream")
	_check(int(route_timing.get("queue_source_frame", -1)) == 4816,
		"full route audio starts at the first ROM $55 queue frame")
	_check(int(route_timing.get("source_end_frame", -1)) == 9042,
		"full route audio keeps source-rendered tail after the menu endpoint")
	_check(int(route_timing.get("verification_sample_count", -1)) == 3036345,
		"route audio carries the exact same-input window through frame 8953")
	_check(route_timing.get("embedded_bgm_queue_ids", []) == [0x55, 0x53, 0x3C],
		"route context declares its ROM-derived later BGM transitions")
	_check(route_timing.get("embedded_sfx_queue_ids", []) == [0x66, 0x2B, 0x2C],
		"route context declares its overlapping ROM-derived SFX")
	for stop_frame in [7243, 7266, 8108, 8443, 8458, 8460]:
		_check(presenter.apply_rom_sound_command(0x01, stop_frame), "$01 at frame %d preserves the full source route context" % stop_frame)
		_check(bgm_player != null and bgm_player.stream == route_stream and bgm_player.playing,
			"$01 at frame %d does not cut the ROM-derived route mix" % stop_frame)
	for event in [{"queue_id": 0x55, "frame": 7409}, {"queue_id": 0x53, "frame": 8271}]:
		_check(presenter.apply_rom_sound_command(event["queue_id"], event["frame"]), "$%02X BGM transition remains live" % event["queue_id"])
		_check(bgm_player != null and bgm_player.stream == route_stream and bgm_player.playing,
			"$%02X transition does not restart the pre-mixed source route" % event["queue_id"])

	var fresh_daaa_event = SOUND_QUEUE_EVENT.new()
	fresh_daaa_event.event_identity = "daaa-cbf1:DAAC:CC01:8460:00"
	fresh_daaa_event.event_origin = "rom_daaa_cbf1_queue_insert"
	fresh_daaa_event.source_rom_sha256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
	fresh_daaa_event.queue_id = 0x01
	fresh_daaa_event.queue_store_instruction_pc = 0xCBFE
	fresh_daaa_event.post_store_pc = 0xCC01
	fresh_daaa_event.queue_slot = 0
	fresh_daaa_event.queue_address = 0x0700
	fresh_daaa_event.source_caller_pc = 0xDAAC
	fresh_daaa_event.source_frame = 8460
	fresh_daaa_event.source_frame_domain = "godot_source_route_frame"
	fresh_daaa_event.source_helper_span_sha256 = "fc6689183aa19a053b44b44571a373ebb48b3bf940f299fb10623c61da4791ce"
	fresh_daaa_event.source_manifest_sha256 = "01b60a8cf91bfde2c6ff02098f50fe4851aca50aea5d43fffb792516dc53e0ea"
	fresh_daaa_event.route_frame = -1
	fresh_daaa_event.absolute_rom_frame = -1
	fresh_daaa_event.cpu_cycle = -1
	fresh_daaa_event.timing_verified = false
	_check(fresh_daaa_event.is_valid_fresh_daaa_queue_insert(), "ROM `$DAAA->$CBF1->$CC01` stop event keeps its typed provenance")
	_check(presenter.apply_rom_fresh_daaa_queue_insert(fresh_daaa_event), "typed source stop event is accepted")
	_check(presenter.get("_bgm_player").stream == route_stream, "typed stop preserves the full route context through the APU tail")
	var tampered_event = SOUND_QUEUE_EVENT.new()
	tampered_event.event_identity = fresh_daaa_event.event_identity
	tampered_event.event_origin = fresh_daaa_event.event_origin
	tampered_event.source_rom_sha256 = fresh_daaa_event.source_rom_sha256
	tampered_event.queue_id = fresh_daaa_event.queue_id
	tampered_event.queue_store_instruction_pc = fresh_daaa_event.queue_store_instruction_pc
	tampered_event.post_store_pc = fresh_daaa_event.post_store_pc
	tampered_event.queue_slot = fresh_daaa_event.queue_slot
	tampered_event.queue_address = fresh_daaa_event.queue_address
	tampered_event.source_frame = fresh_daaa_event.source_frame
	tampered_event.source_frame_domain = fresh_daaa_event.source_frame_domain
	tampered_event.source_helper_span_sha256 = fresh_daaa_event.source_helper_span_sha256
	tampered_event.source_manifest_sha256 = fresh_daaa_event.source_manifest_sha256
	tampered_event.source_caller_pc = 0xDAAA
	_check(not presenter.apply_rom_fresh_daaa_queue_insert(tampered_event), "typed source event rejects a changed caller PC")

	_check(presenter.apply_rom_sound_command(0x3C, 8607), "$3C replaces the overlapping route context at its ROM queue frame")
	var pass_stream := bgm_player.stream if bgm_player != null else null
	var pass_timing: Dictionary = presenter.get("current_playback_timing")
	_check(pass_stream is AudioStreamWAV and pass_stream != route_stream,
		"$3C starts the dedicated source-context asset instead of continuing the overlapping $55 render")
	_check(int(presenter.current_bgm_queue_id) == 0x3C and int(pass_timing.get("source_end_frame", -1)) == 9600,
		"$3C source context is bounded by the next input-wait boundary at frame 9600")
	var validated_cues: Dictionary = presenter.get("_validated_cues")
	var validated_3c: Dictionary = validated_cues.get(0x3C, {})
	_check(str(validated_3c.get("source_timing_path", "")) == "res://assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.json",
		"$3C loaded its SHA-pinned source sidecar and ROM-derived runtime WAV")
	_check(pass_timing.get("embedded_sfx_queue_ids", []) == [0x66, 0x2B, 0x2C, 0x2B, 0x2C],
		"$3C source context declares every embedded ROM SFX queue")
	for event in [
		{"queue_id": 0x66, "frame": 8624}, {"queue_id": 0x2B, "frame": 8664},
		{"queue_id": 0x2C, "frame": 8786}, {"queue_id": 0x2B, "frame": 9125},
		{"queue_id": 0x2C, "frame": 9247},
	]:
		_check(presenter.apply_rom_sound_command(event["queue_id"], event["frame"]), "$%02X mixed SFX event remains visible" % event["queue_id"])
		_check((presenter.get("_mixed_route_sfx_queue_ids") as Array).has(event["queue_id"]),
			"$%02X is tracked as already present in the route mix" % event["queue_id"])
		_check(not (presenter.get("_sfx_queue_by_voice") as Array).has(event["queue_id"]),
			"$%02X does not play a duplicate isolated SFX" % event["queue_id"])
	var expected_starts: Array[Array] = [[0x55, 4816], [0x55, 7409], [0x53, 8271], [0x3C, 8607], [0x66, 8624], [0x2B, 8664], [0x2C, 8786], [0x2B, 9125], [0x2C, 9247]]
	_check(_started_events == expected_starts, "route queue signals match ROM frames and order: %s" % JSON.stringify(_started_events))
	_check(presenter.is_rom_audio_playing() and bgm_player.stream == pass_stream,
		"the first-pass `$3C` source context remains active at its frame-9600 boundary")

	for queue_id in UNSUPPORTED_IDS:
		_check(not presenter.apply_rom_sound_command(queue_id, 3000 + queue_id), "unrendered queue $%02X fails closed" % queue_id)
	_check((presenter.unsupported_queue_ids as Array).size() == UNSUPPORTED_IDS.size(), "unknown queue IDs are reported")

	if _failures.is_empty():
		print("PASS: isolated ROM cues load; the $3C first-pass context replaces the overlapping $55 render and suppresses all embedded $66/$2B/$2C duplicates; typed stop provenance and unsupported cues are checked")
		print("LIMIT: this checks provenance, cue routing, and event suppression only; it does not establish same-input PCM parity or NES hardware phase.")
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


func _on_sound_started(queue_id: int, source_frame: int) -> void:
	_started_events.append([queue_id, source_frame])


func _on_sound_stopped(queue_id: int, source_frame: int) -> void:
	_stopped_events.append([queue_id, source_frame])


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
		printerr("FAIL: " + description)
