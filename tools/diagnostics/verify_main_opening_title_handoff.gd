extends SceneTree
## Exercise the configured main scene through the title's KICK OFF handoff.
## It does not enter CONTINUE or confirm a soccer action.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const KICKOFF_PPU_REFERENCE_ROOT := "res://reference/diagnostics/kickoff_select_test_20261027/ppu/"
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
	var title_fade_counters: Vector2i = presenter.state.get("fade_counters", Vector2i(-1, -1))
	if title_fade_counters != Vector2i(0x0F, 0x0F):
		push_error("The live ROM-derived title source did not hand off full-brightness $4A/$4B counters.")
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
	var title_endpoint_frame: int = presenter.title_first_pixel_source_frame()
	if title_endpoint_frame != final_consumer_frame \
			or int(runtime._title_menu_source_frame) != title_endpoint_frame:
		push_error("Title menu source clock did not start at the ROM first-pixel frame.")
		quit(1)
		return
	print("Configured main scene reached the unconfirmed KICK OFF title endpoint at ROM virtual pixel cycle %d (final packet %d)." % [title_pixel_cycle, final_cycle])
	print("Timing: Start poll, handoff, and first title pixel follow ROM-stepper cycles; desktop scanout and physical 2C02 edge timing are not hardware measurements.")
	var kickoff_press := InputEventKey.new()
	kickoff_press.keycode = KEY_ENTER
	kickoff_press.pressed = true
	menu._unhandled_input(kickoff_press)
	var kickoff_route := runtime.get_node_or_null("KickoffRouteRuntime")
	if kickoff_route == null:
		push_error("KICK OFF input did not enter the production route.")
		quit(1)
		return
	kickoff_route.set_process(false)
	var title_renderer = menu.title_background
	var kickoff_frame_4693_ppu := FileAccess.get_file_as_bytes(
		KICKOFF_PPU_REFERENCE_ROOT + "route_frame_004693.bin")
	if kickoff_frame_4693_ppu.size() != 0x4000 \
			or title_renderer.get_source_title_palette_bytes() != kickoff_frame_4693_ppu.slice(0x3F00, 0x3F20):
		push_error("ROM-derived title palette differs from the same-input FCEUX PPU state at route entry.")
		quit(1)
		return
	var kickoff_status: Dictionary = kickoff_route.get_route_status()
	var title_handoff: Dictionary = kickoff_status.get("title_handoff", {})
	var fade_status: Dictionary = kickoff_status.get("title_handoff_fade", {})
	var fade_receipt: Dictionary = kickoff_status.get("title_handoff_fade_receipt", {})
	var title_source_frame := int(runtime._title_menu_source_frame)
	var route_entry_frame := int(kickoff_status.get("source_frame", -1))
	if not bool(title_handoff.get("ok", false)) \
			or int(title_handoff.get("title_source_frame", -1)) != title_source_frame \
			or route_entry_frame != title_source_frame + 1 \
			or String(title_handoff.get("selected_option", "")) != "KICK OFF" \
			or not bool(fade_receipt.get("ok", false)) \
			or bool(fade_receipt.get("uses_trace_values", true)) \
			or String(kickoff_status.get("stage", "")) != "title_handoff_fade" \
			or int(fade_status.get("yield_count", -1)) != 1 \
			or int(fade_status.get("counter_a", -1)) != 0x0E \
			or int(fade_status.get("counter_b", -1)) != 0x0E \
			or not bool(menu.visible) \
			or bool(kickoff_status.get("first_action_menu_complete", true)):
		push_error("KICK OFF route did not begin the ROM-derived title fade from the live title state.")
		quit(1)
		return
	var first_palette_packet: PackedByteArray = kickoff_route._title_handoff_fade_task.last_palette_packet
	if title_renderer.get_current_title_palette_bytes() != title_renderer.get_source_title_palette_bytes():
		push_error("The staged title fade changed PPU colors before the modeled next-frame commit.")
		quit(1)
		return
	kickoff_route._advance_route_source_tick()
	if title_renderer.get_current_title_palette_bytes() != first_palette_packet.slice(3, 0x23):
		push_error("The first ROM $9A71 fade packet did not commit on the next modeled source frame.")
		quit(1)
		return
	for _source_frame in range(14):
		kickoff_route._advance_route_source_tick()
	kickoff_status = kickoff_route.get_route_status()
	fade_status = kickoff_status.get("title_handoff_fade", {})
	var clear_result: Dictionary = kickoff_status.get("title_handoff_clear", {})
	var dispatch_seed: Dictionary = kickoff_status.get("title_handoff_dispatch_seed", {})
	var ppu_shadow_state: Dictionary = kickoff_status.get("source_ppu_shadow_state", {})
	var ppu_shadow_before: Dictionary = clear_result.get("ppu_shadow_before", {})
	var ppu_shadow_after: Dictionary = clear_result.get("ppu_shadow_after", {})
	var ppu_register_writes: Array = clear_result.get("ppu_register_writes", [])
	var task_seed: Dictionary = kickoff_status.get("cutscene_worker_seed", {})
	var kickoff_frame_4708_ppu := FileAccess.get_file_as_bytes(
		KICKOFF_PPU_REFERENCE_ROOT + "route_frame_004708.bin")
	var title_ppu_state: Dictionary = title_renderer.get_ppu_memory_snapshot()
	if int(kickoff_status.get("source_frame", -1)) != route_entry_frame + 15 \
			or String(kickoff_status.get("stage", "")) != "cutscene_1" \
			or String(fade_status.get("state", "")) != "returned" \
			or int(fade_status.get("yield_count", -1)) != 15 \
			or not bool(clear_result.get("ok", false)) \
			or int(clear_result.get("ppu_clear", {}).get("write_count", 0)) != 0x800 \
			or int(ppu_shadow_before.get("ctrl_shadow", -1)) != 0x88 \
			or int(ppu_shadow_before.get("mask_shadow", -1)) != 0x1E \
			or int(ppu_shadow_after.get("ctrl_shadow", -1)) != 0x88 \
			or int(ppu_shadow_after.get("mask_shadow", -1)) != 0x1E \
			or ppu_register_writes.size() != 4 \
			or int(ppu_register_writes[0].get("source_pc", -1)) != 0x98A4 \
			or int(ppu_register_writes[0].get("ppu_register", -1)) != 0x2000 \
			or int(ppu_register_writes[0].get("value", -1)) != 0x08 \
			or int(ppu_register_writes[1].get("source_pc", -1)) != 0x98AD \
			or int(ppu_register_writes[1].get("ppu_register", -1)) != 0x2001 \
			or int(ppu_register_writes[1].get("value", -1)) != 0x06 \
			or int(ppu_register_writes[2].get("source_pc", -1)) != 0x98CE \
			or int(ppu_register_writes[2].get("ppu_register", -1)) != 0x2001 \
			or int(ppu_register_writes[2].get("value", -1)) != 0x1E \
			or int(ppu_register_writes[3].get("source_pc", -1)) != 0x98D9 \
			or int(ppu_register_writes[3].get("ppu_register", -1)) != 0x2000 \
			or int(ppu_register_writes[3].get("value", -1)) != 0x88 \
			or int(ppu_shadow_state.get("ctrl_shadow", -1)) != 0x88 \
			or int(ppu_shadow_state.get("mask_shadow", -1)) != 0x1E \
			or String(ppu_shadow_state.get("source_event_id", "")) != "kickoff_title_handoff_cleanup_clear" \
			or not bool(dispatch_seed.get("ok", false)) \
			or int(dispatch_seed.get("source_frame", -1)) != 4708 \
			or int(dispatch_seed.get("ppu_address", -1)) != 0x23E0 \
			or int(dispatch_seed.get("byte_count", -1)) != 0x20 \
			or int(dispatch_seed.get("byte_value", -1)) != 0x55 \
			or kickoff_frame_4708_ppu.size() != 0x4000 \
			or title_renderer.get_current_title_palette_bytes() != kickoff_frame_4708_ppu.slice(0x3F00, 0x3F20) \
			or not bool(task_seed.get("ok", false)) \
			or int(task_seed.get("slot_offset", -1)) != 0x05 \
			or int(task_seed.get("saved_sp", -1)) != 0x4E \
			or int(task_seed.get("resume_pc", -1)) != 0x84C6 \
			or int(task_seed.get("resume_sp", -1)) != 0x50 \
			or bool(menu.visible) \
			or bool(kickoff_status.get("first_action_menu_complete", true)):
		push_error("The ROM title fade/clear did not return at the worker's frame-level route boundary.")
		quit(1)
		return
	for address in range(0x2000, 0x2800):
		if int(title_ppu_state.get(address, -1)) != int(kickoff_frame_4708_ppu[address]):
			push_error("ROM-derived title clear/attribute seed differs from FCEUX PPU byte $%04X at frame 4708." % address)
			quit(1)
			return
	print("KICK OFF handoff: title frame %d -> route frame %d; title fade returned at frame %d; route stage=%s." % [
		title_source_frame, route_entry_frame, int(kickoff_status.get("source_frame", -1)),
		String(kickoff_status.get("stage", "")),
	])
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
