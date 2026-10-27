extends SceneTree
## Exercise the configured main scene through the title endpoint without
## pressing KICK OFF or CONTINUE.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const NES_CPU_CLOCK_HZ := 1789773.0
const START_FRAME := 4661
const START_POLL_TO_STOP_CPU_CYCLES := 38


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
	presenter._advance_source_frame()
	if not bool(runtime._transition_active) \
			or int(presenter.state.get("source_frame", -1)) != START_FRAME:
		push_error("Latched Start was not consumed by the next source-frame poll.")
		quit(1)
		return
	var event_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/opening/rom_logic/title_handoff_source_events.json"))
	var nmi_cycle := -1
	var nmi_frame := -1
	var final_cycle := -1
	var final_consumer_frame := -1
	var consumer_count := 0
	for event_value in event_data.get("events", []):
		var source_event: Dictionary = event_value
		if str(source_event.get("kind", "")) == "nmi_accept" and nmi_cycle < 0:
			nmi_cycle = int(source_event.get("cycle_offset", -1))
			nmi_frame = int(source_event.get("source_frame", -1))
		if str(source_event.get("kind", "")) == "queue_consumer_packet":
			consumer_count += 1
			final_consumer_frame = int(source_event.get("source_frame", -1))
		final_cycle = maxi(final_cycle, int(source_event.get("cycle_offset", -1)))
	if nmi_cycle <= 0 or nmi_frame != 4662 or final_cycle <= nmi_cycle \
			or final_consumer_frame != 4692 or consumer_count != 242:
		push_error("Title source event resource has no valid NMI/reveal range.")
		quit(1)
		return
	runtime._advance_title_transition(float(
		nmi_cycle - 1 + START_POLL_TO_STOP_CPU_CYCLES) / NES_CPU_CLOCK_HZ)
	if runtime._transition_blackout_presented:
		push_error("Black handoff began before the first ROM NMI event.")
		quit(1)
		return
	runtime._advance_title_transition(1.0 / NES_CPU_CLOCK_HZ)
	if not runtime._transition_blackout_presented or not runtime.get_node("TransitionBlack").visible:
		push_error("Black handoff did not begin at the first accepted ROM NMI event.")
		quit(1)
		return
	runtime._advance_title_transition(float(final_cycle - nmi_cycle + 1) / NES_CPU_CLOCK_HZ)
	await process_frame
	var menu = runtime.get_node("TitleMenu")
	var queue = menu._handoff_queue
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
	print("Configured main scene reached the unconfirmed KICK OFF title endpoint after %d ROM source cycles." % final_cycle)
	print("Timing limit: Godot still samples held Start at a source-frame boundary. ROM-only analysis predicts the first title pixel at CPU cycle 139707186 and matches the pinned FCEUX model; it does not prove Godot host scanout or physical 2C02 timing.")
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
