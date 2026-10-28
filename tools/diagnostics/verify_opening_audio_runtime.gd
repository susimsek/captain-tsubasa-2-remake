extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Could not load the main scene.")
		return
	var main := packed.instantiate()
	# Do not keep the packed scene's AudioStream resource alive through teardown.
	packed = null
	get_root().add_child(main)
	await process_frame

	var runtime := main
	var audio := runtime.get_node("OpeningAudio") as AudioStreamPlayer
	var presenter := runtime.get_node("SourcePresenter") as ColdStartSourceCommandPresenter
	presenter.set_process(false)
	if audio == null or audio.stream == null or not audio.playing:
		_fail("The main scene did not start its standalone ROM-derived WAV.")
		return
	if int(runtime.get("_audio_loop_start_frame")) != -1:
		_fail("The music loop point was loaded from metadata before a ROM command.")
		return

	presenter.rom_sound_requested.emit(0x58, 282)
	if int(runtime.get("_audio_loop_start_frame")) != 282 \
			or int(runtime.get("_last_audio_sync_source_frame")) != 282:
		_fail("The opening $58 cue did not re-anchor playback at frame 282.")
		return
	await create_timer(0.05).timeout
	presenter.rom_sound_requested.emit(0x68, 379)
	if int(runtime.get("_last_audio_sync_source_frame")) != 282:
		_fail("A non-music cue incorrectly restarted the mixed WAV.")
		return
	presenter.rom_sound_requested.emit(0x58, 4481)
	if int(runtime.get("_last_audio_sync_source_frame")) != 4481 or not audio.playing:
		_fail("The loop $58 cue did not re-anchor the playing WAV at frame 4481.")
		return
	print("OPENING_AUDIO_SYNC_OK cues=282,4481 stream=playing")

	var start_event := InputEventAction.new()
	start_event.action = "opening_start"
	start_event.pressed = true
	var first_poll_frame := int(presenter.get("_first_nmi_release_source_frame"))
	var first_poll_elapsed := presenter.elapsed_cpu_cycles_since_start_poll(first_poll_frame)
	runtime.call("_unhandled_input", start_event)
	# The main handoff verifier exercises the live presenter poll. This focused
	# audio-tail check emits its already-connected poll signal to avoid replaying
	# source-frame sprite setup unrelated to audio cleanup.
	var synthetic_poll_time := Time.get_ticks_usec() - int(round(
		first_poll_elapsed * 1000000.0 / 1789773.0))
	var input_transition: Dictionary = runtime._start_input_transitions.back()
	input_transition["timestamp_usec"] = synthetic_poll_time - 1
	runtime._start_input_transitions[runtime._start_input_transitions.size() - 1] = input_transition
	presenter.source_start_poll_completed.emit(first_poll_frame, first_poll_elapsed)
	if not runtime.get("_transition_active"):
		_fail("Latched Start was not consumed by the ROM's next frame-level poll.")
		return
	runtime.set_process(false)
	const frame_delta := 1.0 / 60.0988
	for _frame in range(31):
		await create_timer(frame_delta).timeout
		runtime.call("_advance_title_transition", frame_delta)
	var title_menu := runtime.get_node("TitleMenu") as RomTitleMenu
	if not title_menu.visible or not audio.playing or not audio.playback_expected_active():
		_fail("The ROM-derived audio tail did not continue through the title reveal.")
		return
	print("OPENING_AUDIO_HANDOFF_TAIL_OK title_visible=true stream=playing")
	# Leave the stream active and exercise the scene's AudioStreamPlayer cleanup
	# child. Its _exit_tree() stops playback, clears the WAV reference, and gives
	# the audio server time to release the playback object before process exit.
	get_root().remove_child(main)
	main.free()
	await create_timer(0.5).timeout
	print("OPENING_AUDIO_SCENE_RELEASE_OK")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
