extends SceneTree
## Exercise the configured main scene through the title endpoint without
## pressing KICK OFF or CONTINUE.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const NES_CPU_CLOCK_HZ := 1789773.0
const START_FRAME := 4661


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load(MAIN_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Main scene could not be loaded.")
		quit(1)
		return
	var runtime = scene.instantiate()
	get_root().add_child(runtime)
	await process_frame
	runtime.set_process(false)
	var presenter = runtime.get_node("SourcePresenter")
	presenter.set_process(false)
	# This check validates the full source/state handoff and title queue. The
	# expensive per-frame field texture rebuild is checked by image diagnostics;
	# suspend it here so the 4,661-frame replay stays fast and deterministic.
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	var quick_press := InputEventKey.new()
	quick_press.keycode = KEY_ENTER
	quick_press.pressed = true
	runtime._unhandled_input(quick_press)
	var quick_release := InputEventKey.new()
	quick_release.keycode = KEY_ENTER
	quick_release.pressed = false
	runtime._unhandled_input(quick_release)
	while int(presenter.state.get("source_frame", 0)) < START_FRAME - 1:
		presenter._advance_source_frame()
	if bool(runtime._transition_active):
		push_error("A Start press released before the ROM poll incorrectly triggered the handoff.")
		quit(1)
		return
	var start_event := InputEventKey.new()
	start_event.keycode = KEY_ENTER
	start_event.pressed = true
	runtime._unhandled_input(start_event)
	# This deterministic replay advances source frames without waiting for host
	# time. Backdate the synthetic key-down to just before the ROM poll so the
	# runtime's cycle-timestamped input sampler sees it at the correct poll.
	var poll_elapsed_at_edge: float = presenter.elapsed_cpu_cycles_since_start_poll(START_FRAME)
	var poll_timestamp_usec := Time.get_ticks_usec() - int(round(
		poll_elapsed_at_edge * 1000000.0 / NES_CPU_CLOCK_HZ))
	var last_input_transition: Dictionary = runtime._start_input_transitions.back()
	last_input_transition["timestamp_usec"] = poll_timestamp_usec - 1
	runtime._start_input_transitions[runtime._start_input_transitions.size() - 1] = last_input_transition
	presenter._advance_source_frame()
	if not bool(runtime._transition_active) \
			or int(presenter.state.get("source_frame", -1)) != START_FRAME:
		push_error("Start held at the ROM-derived poll was not consumed.")
		quit(1)
		return
	var event_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/opening/rom_logic/title_handoff_source_events.json"))
	var nmi_cycle := -1
	var nmi_frame := -1
	var final_cycle := -1
	var final_consumer_frame := -1
	var final_consumer_ordinal := -1
	var consumer_count := 0
	for event_value in event_data.get("events", []):
		var source_event: Dictionary = event_value
		if str(source_event.get("kind", "")) == "nmi_accept" and nmi_cycle < 0:
			nmi_cycle = int(source_event.get("cycle_offset", -1))
			nmi_frame = int(source_event.get("source_frame", -1))
		if str(source_event.get("kind", "")) == "queue_consumer_packet":
			consumer_count += 1
			final_consumer_frame = int(source_event.get("source_frame", -1))
			final_consumer_ordinal = int(source_event.get("ordinal", -1))
		final_cycle = maxi(final_cycle, int(source_event.get("cycle_offset", -1)))
	if nmi_cycle <= 0 or nmi_frame != 4662 or final_cycle <= nmi_cycle \
			or final_cycle != 920030 or final_consumer_frame != 4692 \
			or final_consumer_ordinal != 241 or consumer_count != 242:
		push_error("Title source event resource has no valid NMI/reveal range.")
		quit(1)
		return
	var stop_cycle_delta: int = presenter.start_poll_to_stop_cpu_cycles()
	var expected_start_offset: int = int(round(poll_elapsed_at_edge)) - stop_cycle_delta
	if int(runtime._transition_cpu_cycles_elapsed) != expected_start_offset:
		push_error("Start handoff did not begin at the source-clock position for the sampled poll.")
		quit(1)
		return
	runtime._advance_title_transition(float(nmi_cycle - expected_start_offset - 1) / NES_CPU_CLOCK_HZ)
	if runtime._transition_blackout_presented:
		push_error("Black handoff began before the first ROM NMI event.")
		quit(1)
		return
	runtime._advance_title_transition(1.0 / NES_CPU_CLOCK_HZ)
	if not runtime._transition_blackout_presented or not runtime.get_node("TransitionBlack").visible:
		push_error("Black handoff did not begin at the first accepted ROM NMI event.")
		quit(1)
		return
	runtime._advance_title_transition(float(final_cycle - nmi_cycle) / NES_CPU_CLOCK_HZ)
	var menu = runtime.get_node("TitleMenu")
	var queue = menu._handoff_queue
	var title_pixel_cycle: int = presenter.title_first_pixel_cycle_offset_from_start_stop()
	if not queue.is_complete() or bool(menu.visible) or not bool(runtime._transition_active) \
			or title_pixel_cycle <= final_cycle:
		push_error("Title image revealed at the final packet commit instead of the source pixel event.")
		quit(1)
		return
	runtime._advance_title_transition(float(title_pixel_cycle - final_cycle - 1) / NES_CPU_CLOCK_HZ)
	if bool(menu.visible):
		push_error("Title image appeared before its ROM-derived first-pixel time.")
		quit(1)
		return
	runtime._advance_title_transition(1.0 / NES_CPU_CLOCK_HZ)
	await process_frame
	var cursor := int(menu.title_background.get_render_state().get("cursor_selection", -1))
	var passed := bool(menu.visible) and not bool(runtime._transition_active) \
			and bool(queue.is_complete()) and cursor == 0
	print("handoff_visible=%s transition_active=%s source_cycles=%d queue_complete=%s initial_selection=%d" % [
		menu.visible, runtime._transition_active, runtime._transition_cpu_cycles_elapsed,
		queue.is_complete(), cursor,
	])
	if not passed:
		push_error("Main scene did not reach the unconfirmed KICK OFF title endpoint at source frame 4692.")
		quit(1)
		return
	print("Configured main scene reached the unconfirmed KICK OFF title endpoint at ROM virtual pixel cycle %d (final packet %d)." % [title_pixel_cycle, final_cycle])
	print("Timing: Start poll, handoff, and first title pixel follow ROM-stepper cycles; desktop scanout and physical 2C02 edge timing are not hardware measurements.")
	var audio := runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if audio != null:
		AudioServer.lock()
		audio.stop()
		audio.stream = null
		AudioServer.unlock()
		await create_timer(0.5).timeout
	get_root().remove_child(runtime)
	runtime.free()
	await process_frame
	quit(0)
