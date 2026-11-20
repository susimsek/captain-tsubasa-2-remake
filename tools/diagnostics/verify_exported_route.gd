extends SceneTree
## Replays input edges into the exported runtime pack. The input CSV is a
## validation-only external file; no RAM, PPU, ROM, screenshot, or audio state
## is loaded into the route.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const MENU_INPUT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const EXPECTED_INPUT_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const EXPECTED_FIRST_PASS_EDGES_SHA256 := "3e522de6924b0fb9ad40ffdd2271a9e4ea62cbe1bf76cc27c6b414b7e87bb6d2"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const TITLE_HANDOFF_FRAME := 4692
const LAST_SOURCE_FRAME := 9042
const MENU_COMPARISON_FRAME := 8953
const FIRST_PASS_SELECTION_FRAME := 9043
const FIRST_PASS_CONFIRMATION_FRAME := 9045
const FIRST_PASS_POST_CONFIRMATION_FRAME := 9046
const FIRST_RECEIVER_WAIT_FRAME := 9067
const FIRST_RECEIVER_DIRECTION_FRAME := 9068
const FIRST_RECEIVER_CONFIRMATION_FRAME := 9076
const FIRST_NEXT_DECISION_FRAME := 9600
const FIRST_PASS_RECEIVER_DIAGNOSTIC_END_FRAME := 9082
const FIRST_PASS_CONTEXT_QUEUE_ID := 0x3C
const FIRST_PASS_CONTEXT_START_FRAME := 8607
const FIRST_PASS_CONTEXT_TIMING_PATH := "assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.json"
const FIRST_PASS_CONTEXT_WAV_PATH := "assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.wav"
const FIRST_PASS_CONTEXT_WAV_SHA256 := "c97d8fc041a7c8561447c6b41c0a930845fc13b7fae8e3f1f27c8abff1b762b0"
const FIRST_PASS_CONTEXT_SAMPLE_COUNT := 728838

var _confirmations: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, true)
	var input_path := OS.get_environment("CT2_ROUTE_INPUT_CSV").strip_edges()
	if input_path.is_empty():
		_fail("Set CT2_ROUTE_INPUT_CSV to the validation-only input-edge CSV")
		return
	var input_result := _read_input_edges(input_path)
	if not bool(input_result.get("ok", false)):
		_fail(String(input_result.get("error", "Input-edge replay could not be loaded")))
		return
	var input_edges: Dictionary = input_result["edges"]

	var title_runtime := MAIN_SCENE.instantiate() as Node
	if title_runtime == null:
		_fail("Exported title scene could not be instantiated")
		return
	title_runtime.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(title_runtime)
	await process_frame
	var opening_audio := title_runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if opening_audio != null:
		opening_audio.stop()
	var title_presenter := title_runtime.get_node_or_null("SourcePresenter")
	var title_renderer := title_runtime.get_node_or_null("TitleMenu/TitleBackground")
	if title_presenter == null or title_renderer == null:
		_fail("Exported title scene is missing its ROM-derived handoff providers")
		return
	var title_state: Variant = title_presenter.get("state")
	if not title_state is Dictionary:
		_fail("Title presenter does not expose source state")
		return
	var counters: Variant = title_state.get("fade_counters", Vector2i(-1, -1))
	var palette: Variant = title_renderer.call("get_source_title_palette_bytes")
	if typeof(counters) != TYPE_VECTOR2I or counters != Vector2i(0x0F, 0x0F) \
			or not palette is PackedByteArray or palette.size() != 0x20:
		_fail("Title presenter did not provide the expected full-brightness source handoff")
		return

	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	route.process_mode = Node.PROCESS_MODE_DISABLED
	if not route.initialize_from_title_handoff(TITLE_HANDOFF_FRAME, ROM_SHA256,
		{"fade_counters": counters, "base_palette_bytes": palette}, title_renderer):
		_fail("Exported route rejected the ROM-derived title handoff")
		return
	route.action_confirmation_requested.connect(_on_confirmation_requested)
	root.add_child(route)
	await process_frame
	if OS.get_environment("CT2_VERIFY_FIRST_PASS").strip_edges() == "1":
		var first_pass_path := OS.get_environment("CT2_FIRST_PASS_INPUT_EDGES_CSV").strip_edges()
		if first_pass_path.is_empty():
			_fail("Set CT2_FIRST_PASS_INPUT_EDGES_CSV to the validation-only PASS input-edge CSV")
			return
		var first_pass_input := _read_first_pass_input_edges(first_pass_path)
		if not bool(first_pass_input.get("ok", false)):
			_fail(String(first_pass_input.get("error", "First PASS input-edge replay could not be loaded")))
			return
		for source_frame_variant in first_pass_input["edges"]:
			var source_frame := int(source_frame_variant)
			if input_edges.has(source_frame):
				_fail("The base route CSV and PASS edge CSV overlap at frame %d" % source_frame)
				return
			input_edges[source_frame] = first_pass_input["edges"][source_frame]
		var endpoint := OS.get_environment("CT2_FIRST_PASS_ROUTE_ENDPOINT").strip_edges().to_upper()
		if endpoint == "9600":
			endpoint = "D5EA"
		if endpoint == "CAA5":
			await _verify_first_pass_exported_route(route, input_edges,
				String(input_result["sha256"]), String(first_pass_input["sha256"]))
		elif endpoint == "D5EA":
			await _verify_first_pass_decision_boundary_exported_route(route, input_edges,
				String(input_result["sha256"]), String(first_pass_input["sha256"]))
		else:
			_fail("CT2_FIRST_PASS_ROUTE_ENDPOINT must be CAA5 or D5EA (frame 9600)")
		return
	for source_frame in range(TITLE_HANDOFF_FRAME + 2, LAST_SOURCE_FRAME + 1):
		if input_edges.has(source_frame):
			_dispatch_edges(route, input_edges[source_frame])
		route.call("_advance_route_source_tick")
		if input_edges.has(source_frame):
			await process_frame
		var route_status: Dictionary = route.get_route_status()
		var stage := String(route_status.get("stage", ""))
		if stage == "first_action_menu":
			var menu_onset_frame := source_frame
			for comparison_frame in range(source_frame + 1, MENU_COMPARISON_FRAME + 1):
				if input_edges.has(comparison_frame):
					_dispatch_edges(route, input_edges[comparison_frame])
				route.call("_advance_route_source_tick")
				if input_edges.has(comparison_frame):
					await process_frame
				route_status = route.get_route_status()
				if String(route_status.get("stage", "")) != "first_action_menu":
					_fail("Exported route left the initial command menu between frames %d and %d" % [
						menu_onset_frame, comparison_frame])
					return
			if not _verify_endpoint(route, route_status, menu_onset_frame,
				MENU_COMPARISON_FRAME, String(input_result["sha256"])):
				quit(1)
				return
			quit(0)
			return
		if stage in ["source_route_gap", "match_setup_gap"]:
			var gaps: Array = route_status.get("route_gaps", [])
			_fail("Exported source route stopped at %s by frame %d: %s" % [
				stage, source_frame, String(gaps.back()) if not gaps.is_empty() else "no gap detail"])
			return
	_fail("Exported source route did not reach the first menu by frame %d" % LAST_SOURCE_FRAME)


func _verify_first_pass_exported_route(route: KickoffRouteRuntime, input_edges: Dictionary,
		base_input_hash: String, first_pass_input_hash: String) -> void:
	var menu_onset_frame := -1
	var menu_baseline_8953_verified := false
	var menu_pre_action_9042_verified := false
	var pass_selection_verified := false
	var pass_confirmation_verified := false
	for source_frame in range(TITLE_HANDOFF_FRAME + 2, FIRST_PASS_POST_CONFIRMATION_FRAME + 1):
		if input_edges.has(source_frame):
			_dispatch_edges(route, input_edges[source_frame])
		route.call("_advance_route_source_tick")
		if input_edges.has(source_frame):
			await process_frame
		var route_status: Dictionary = route.get_route_status()
		var stage := String(route_status.get("stage", ""))
		if stage in ["source_route_gap", "match_setup_gap"]:
			var gaps: Array = route_status.get("route_gaps", [])
			_fail("Exported PASS route stopped at %s on frame %d: %s" % [
				stage, source_frame, String(gaps.back()) if not gaps.is_empty() else "no gap detail"])
			return
		if source_frame <= LAST_SOURCE_FRAME and stage == "first_action_menu":
			if menu_onset_frame < 0:
				menu_onset_frame = source_frame
			if source_frame in [MENU_COMPARISON_FRAME, LAST_SOURCE_FRAME] \
					and not _verify_unselected_menu_state(route, route_status, source_frame):
				return
			if source_frame == MENU_COMPARISON_FRAME:
				menu_baseline_8953_verified = true
			if source_frame == LAST_SOURCE_FRAME:
				menu_pre_action_9042_verified = true
		elif menu_onset_frame >= 0 and source_frame <= LAST_SOURCE_FRAME:
			_fail("Exported route left the initial menu before the recorded PASS input at frame %d (stage=%s)" % [
				source_frame, stage])
			return
		if source_frame == FIRST_PASS_SELECTION_FRAME:
			var input_sample: Dictionary = route_status.get("first_action_menu_source_input_sample", {})
			if stage != "first_action_menu" \
					or int(route_status.get("selected_action_id", -2)) != MENU_INPUT.ActionId.PASS \
					or String(input_sample.get("source_poll_status", "")) != "pass_selection_adopted" \
					or (input_sample.get("source_writes_applied", []) as Array).size() != 3:
				_fail("Recorded Left at frame %d did not select PASS through the ROM-backed live menu poll" % source_frame)
				return
			pass_selection_verified = true
		if source_frame == FIRST_PASS_CONFIRMATION_FRAME:
			var input_sample: Dictionary = route_status.get("first_action_menu_source_input_sample", {})
			var pending_dispatch: Dictionary = input_sample.get("pending_handler_dispatch", {})
			if stage != "first_action_handler_pending" \
					or String(input_sample.get("source_poll_status", "")) != "pass_confirmation_pending_source_execution" \
					or not bool(input_sample.get("source_input_consumed", false)) \
					or not (input_sample.get("source_writes_applied", []) as Array).is_empty() \
					or int(pending_dispatch.get("source_boundary_pc", -1)) != 0xD5EA \
					or pending_dispatch.has("target_pc"):
				_fail("Recorded A at frame %d was not consumed once at the live `$D5EA` wait" % source_frame)
				return
			pass_confirmation_verified = _confirmations.size() == 1 \
				and _confirmations[0] == MENU_INPUT.ActionId.PASS
			if not pass_confirmation_verified:
				_fail("The exported route did not emit exactly one PASS confirmation")
				return
		if source_frame == FIRST_PASS_POST_CONFIRMATION_FRAME:
			if not menu_baseline_8953_verified or not menu_pre_action_9042_verified \
					or not pass_selection_verified or not pass_confirmation_verified:
				_fail("The exported route reached the post-confirmation frame before verifying both menu baselines, Left, and A")
				return
			if not _verify_first_pass_scheduler_handoff(route, route_status,
				base_input_hash, first_pass_input_hash):
				quit(1)
				return
			quit(0)
			return
	_fail("Exported route did not reach the recorded post-confirmation boundary at frame %d" % FIRST_PASS_POST_CONFIRMATION_FRAME)


func _verify_first_pass_decision_boundary_exported_route(route: KickoffRouteRuntime,
		input_edges: Dictionary, base_input_hash: String, first_pass_input_hash: String) -> void:
	var menu_onset_frame := -1
	var menu_baseline_8953_verified := false
	var menu_pre_action_9042_verified := false
	var pass_selection_verified := false
	var pass_confirmation_verified := false
	var receiver_wait_verified := false
	var receiver_direction_verified := false
	var receiver_confirmation_verified := false
	var receiver_window_diagnostic := OS.get_environment("CT2_TRACE_FIRST_PASS_RECEIVER_WINDOW").strip_edges() == "1"
	for source_frame in range(TITLE_HANDOFF_FRAME + 2, FIRST_NEXT_DECISION_FRAME + 1):
		if input_edges.has(source_frame):
			_dispatch_edges(route, input_edges[source_frame])
		route.call("_advance_route_source_tick")
		if input_edges.has(source_frame):
			await process_frame
		var status: Dictionary = route.get_route_status()
		var stage := String(status.get("stage", ""))
		if source_frame >= FIRST_RECEIVER_CONFIRMATION_FRAME \
				and source_frame <= FIRST_RECEIVER_CONFIRMATION_FRAME + 16 \
				and not receiver_confirmation_verified \
				and _has_recorded_pass_receiver_confirmation(status,
					FIRST_RECEIVER_CONFIRMATION_FRAME):
			receiver_confirmation_verified = true
		if receiver_window_diagnostic and source_frame >= FIRST_RECEIVER_WAIT_FRAME \
				and source_frame <= FIRST_PASS_RECEIVER_DIAGNOSTIC_END_FRAME:
			var debug_boundary := _slot05_boundary(route)
			var debug_nmi: Dictionary = _source_route_timing_debug(route)
			var debug_runner: Variant = route.get("_fresh_source_route_runner")
			var debug_runner_status: Dictionary = debug_runner.get_status() if debug_runner != null else {}
			var debug_normal_nmi: Dictionary = status.get("fresh_source_route_nmi", {})
			var debug_queue: Dictionary = debug_normal_nmi.get("normal_nmi_result", {}).get("secondary_queue", {})
			var debug_ram: Variant = debug_boundary.get("ram_image", PackedByteArray())
			var debug_scheduler: Variant = debug_runner.get("_scheduler") if debug_runner != null else null
			var debug_scheduler_status: Dictionary = debug_scheduler.get_status() if debug_scheduler != null else {}
			print("RECEIVER_INPUT_DIAG frame=%d runner=%s sample=%s deferred=%s" % [
				source_frame,
				JSON.stringify({"phase": debug_runner_status.get("phase", ""),
					"source_boundary": debug_runner_status.get("source_boundary", ""),
					"pass_receiver_wait_nmi_pending": debug_runner_status.get("pass_receiver_wait_nmi_pending", false),
					"pass_receiver_descriptor_1d_final_nmi_pending": debug_runner_status.get("pass_receiver_descriptor_1d_final_nmi_pending", false),
					"pass_receiver_confirmation_input_pending": debug_runner_status.get("pass_receiver_confirmation_input_pending", false)}),
				JSON.stringify(debug_scheduler_status.get("controller_sample", {})),
				JSON.stringify(route.get("_deferred_pass_receiver_controller_sample"))])
			print("RECEIVER_WINDOW frame=%d stage=%s phase=%s boundary=%s pc=$%04X slot05=%s ram=%s pending_queue=%s packet_progress=%s packet_nmi=%s queue=%s timing=%s" % [
				source_frame, stage, String(debug_nmi.get("phase", "")),
				String(debug_nmi.get("boundary", "")),
				int(debug_boundary.get("pc", -1)),
				(debug_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
				JSON.stringify({
					"scenario_stream_cursor_003a": int(debug_ram[0x003A]) if debug_ram is PackedByteArray and debug_ram.size() > 0x003A else -1,
					"receiver_candidate_slot_0431": int(debug_ram[0x0431]) if debug_ram is PackedByteArray and debug_ram.size() > 0x0431 else -1,
					"receiver_cursor": int(debug_ram[0x0624]) if debug_ram is PackedByteArray and debug_ram.size() > 0x0624 else -1,
					"receiver_count": int(debug_ram[0x0430]) if debug_ram is PackedByteArray and debug_ram.size() > 0x0430 else -1,
					"holder": int(debug_ram[0x0441]) if debug_ram is PackedByteArray and debug_ram.size() > 0x0441 else -1,
					"input_held": int(debug_ram[0x001C]) if debug_ram is PackedByteArray and debug_ram.size() > 0x001C else -1,
					"input_edge": int(debug_ram[0x001E]) if debug_ram is PackedByteArray and debug_ram.size() > 0x001E else -1,
				}), JSON.stringify(debug_runner.get("_pending_nmi_queue_state") if debug_runner != null else {}),
				JSON.stringify(debug_runner.get("_pass_receiver_packet_batch_progress") if debug_runner != null else []),
				JSON.stringify(debug_runner.get("_pass_receiver_packet_batch_nmi_frames") if debug_runner != null else []),
				JSON.stringify({"queue_kind": debug_queue.get("queue_kind", ""),
					"status": debug_queue.get("status", ""),
					"packets": debug_queue.get("packet_count", -1),
					"ready_after": debug_queue.get("ready_flag_after", -1),
					"ppu_events": (debug_normal_nmi.get("ppu_bus_events", []) as Array).size()}),
				JSON.stringify(debug_nmi.get("nmi", {}))])
		if receiver_window_diagnostic and source_frame == FIRST_PASS_RECEIVER_DIAGNOSTIC_END_FRAME \
				and OS.get_environment("CT2_STOP_AFTER_FIRST_PASS_RECEIVER_WINDOW").strip_edges() == "1":
			print("DIAGNOSTIC_ENDPOINT=receiver_window_%d" % source_frame)
			quit(0)
			return
		if source_frame >= 9046 and source_frame <= FIRST_RECEIVER_WAIT_FRAME:
			var frame_debug := _source_route_timing_debug(route)
			var nmi_debug: Dictionary = frame_debug.get("nmi", {})
			var compact_slots: Array = []
			for slot_state_variant in frame_debug.get("slots", []):
				if slot_state_variant is Dictionary:
					var slot_state: Dictionary = slot_state_variant
					compact_slots.append([slot_state.get("slot", -1), slot_state.get("delay", -1),
						slot_state.get("pc", -1), slot_state.get("record", "")])
			print("ROUTE_FRAME=%d stage=%s phase=%s boundary=%s active=%s cursor=%s nmi=%s selected=%s next=%s slots=%s" % [
				source_frame, stage, String(frame_debug.get("phase", "")),
				String(frame_debug.get("boundary", "")), str(frame_debug.get("active_slot", -1)),
				str(frame_debug.get("scan_cursor", -1)), str(nmi_debug.get("secondary_queue", "")),
				str(nmi_debug.get("selected_slot", -1)), str(nmi_debug.get("next_selected_slot", -1)),
				str(compact_slots)])
		if stage in ["source_route_gap", "match_setup_gap"]:
			var gaps: Array = status.get("route_gaps", [])
			var fresh_source_route: Dictionary = status.get("fresh_source_route", {})
			var slot09_debug: Dictionary = fresh_source_route.get("last_slot09_resume_input_debug", {})
			_fail("Exported PASS route stopped at %s on frame %d: %s; slot-$09 input=%s" % [
				stage, source_frame, String(gaps.back()) if not gaps.is_empty() else "no gap detail",
				JSON.stringify(slot09_debug)])
			return
		if source_frame <= LAST_SOURCE_FRAME and stage == "first_action_menu":
			if menu_onset_frame < 0:
				menu_onset_frame = source_frame
			if source_frame in [MENU_COMPARISON_FRAME, LAST_SOURCE_FRAME] \
					and not _verify_unselected_menu_state(route, status, source_frame):
				return
			if source_frame == MENU_COMPARISON_FRAME:
				menu_baseline_8953_verified = true
			if source_frame == LAST_SOURCE_FRAME:
				menu_pre_action_9042_verified = true
		elif menu_onset_frame >= 0 and source_frame <= LAST_SOURCE_FRAME:
			_fail("Exported route left the initial menu before the recorded PASS input at frame %d (stage=%s)" % [
				source_frame, stage])
			return

		if source_frame == FIRST_PASS_SELECTION_FRAME:
			var sample: Dictionary = status.get("first_action_menu_source_input_sample", {})
			if stage != "first_action_menu" \
					or int(status.get("selected_action_id", -2)) != MENU_INPUT.ActionId.PASS \
					or String(sample.get("source_poll_status", "")) != "pass_selection_adopted" \
					or (sample.get("source_writes_applied", []) as Array).size() != 3:
				_fail("Recorded Left at frame %d did not select PASS through the ROM-backed menu poll" % source_frame)
				return
			pass_selection_verified = true
		if source_frame == FIRST_PASS_CONFIRMATION_FRAME:
			var sample: Dictionary = status.get("first_action_menu_source_input_sample", {})
			var pending: Dictionary = sample.get("pending_handler_dispatch", {})
			if stage != "first_action_handler_pending" \
					or String(sample.get("source_poll_status", "")) != "pass_confirmation_pending_source_execution" \
					or not bool(sample.get("source_input_consumed", false)) \
					or not (sample.get("source_writes_applied", []) as Array).is_empty() \
					or int(pending.get("source_boundary_pc", -1)) != 0xD5EA \
					or pending.has("target_pc") or sample.has("next_frame_dispatch"):
				_fail("Recorded A at frame %d was not consumed once at `$D5EA` and held until the next source tick" % source_frame)
				return
			pass_confirmation_verified = _confirmations.size() == 1 \
				and _confirmations[0] == MENU_INPUT.ActionId.PASS
			if not pass_confirmation_verified:
				_fail("The exported route did not emit exactly one PASS confirmation")
				return
		if source_frame == FIRST_PASS_POST_CONFIRMATION_FRAME:
			var sample: Dictionary = status.get("first_action_menu_source_input_sample", {})
			var source_tick_dispatch: Dictionary = sample.get("next_frame_dispatch", {})
			if stage in ["source_route_gap", "match_setup_gap"] \
					or String(source_tick_dispatch.get("status", "")) != "pass_confirmation_scheduler_handoff" \
					or int(source_tick_dispatch.get("source_boundary_pc", -1)) != 0xCAA5 \
					or String(source_tick_dispatch.get("next_scheduler_phase", "")) != "waiting_for_selected_task_source" \
					or int(source_tick_dispatch.get("next_selected_task_slot", -1)) != 0x09:
				_fail("Frame %d did not execute the ROM confirmation bridge and select slot `$09` after its NMI" % source_frame)
				return

		if source_frame == FIRST_RECEIVER_WAIT_FRAME and not receiver_window_diagnostic:
			var boundary := _slot05_boundary(route)
			var ram: Variant = boundary.get("ram_image", PackedByteArray())
			var panel: Dictionary = status.get("pass_receiver_menu", {})
			if int(boundary.get("pc", -1)) != 0xCB0F \
					or not String(boundary.get("source_label", "")).contains("$D80C->$CB0F") \
					or not _ram_signature(ram, {
				0x0624: 0x77, 0x0430: 0x00, 0x0441: 0x06,
			}) or String(panel.get("state", "")) != "presented" \
					or not bool(panel.get("ok", false)):
				_fail("Frame %d did not show the ROM-built PASS receiver panel after the source `$D80C->$CB0F` return (stage=%s pc=$%04X progress=$%02X queue=$%02X panel=%s route=%s)" % [
					source_frame, String(status.get("stage", "")), int(boundary.get("pc", -1)),
					int(ram[0x05C5]) if ram is PackedByteArray and ram.size() > 0x05C5 else -1,
					int(ram[0x0515]) if ram is PackedByteArray and ram.size() > 0x0515 else -1,
					str({"state": panel.get("state", ""), "ok": panel.get("ok", false)}),
					str(_source_route_timing_debug(route))])
				return
			receiver_wait_verified = true

		if source_frame == FIRST_RECEIVER_DIRECTION_FRAME and not receiver_window_diagnostic:
			var boundary := _slot05_boundary(route)
			var ram: Variant = boundary.get("ram_image", PackedByteArray())
			# FCEUX builds the receiver row and consumes Down within frame 9068;
			# the Godot route may expose the following NMI/scheduler PC at this
			# frame boundary, so compare the source-produced selection RAM here.
			if not _ram_signature(ram, {
				0x0624: 0x78, 0x0430: 0x01, 0x0431: 0x0A, 0x0441: 0x06,
			}):
				_fail("Recorded Down at frame %d did not select the sole ROM receiver candidate `$0A`" % source_frame)
				return
			receiver_direction_verified = true

		if source_frame == FIRST_RECEIVER_CONFIRMATION_FRAME + 16 \
				and not receiver_confirmation_verified and not receiver_window_diagnostic:
			var runner_status: Dictionary = status.get("fresh_source_route", {})
			var confirmation: Dictionary = runner_status.get("last_pass_receiver_input_result", {})
			_fail("Recorded A did not reach the ROM `$D852->$D70C` confirmation within the resumed input window: %s" % str({
				"status": confirmation.get("status", ""),
				"source_frame": confirmation.get("source_frame_label", -1),
				"input_sample": confirmation.get("input_sample_receipt", {}),
				"exit_pc": confirmation.get("exit_pc", -1)}))
			return

		if source_frame == FIRST_NEXT_DECISION_FRAME:
			var boundary := _slot05_boundary(route)
			var ram: Variant = boundary.get("ram_image", PackedByteArray())
			if not menu_baseline_8953_verified or not menu_pre_action_9042_verified \
					or not pass_selection_verified or not pass_confirmation_verified \
					or not receiver_wait_verified or not receiver_direction_verified \
					or not receiver_confirmation_verified:
				_fail("Route reached the next decision wait before all recorded menu and receiver input checks passed")
				return
			if int(boundary.get("pc", -1)) != 0xD5EA or not _ram_signature(ram, {
				0x0441: 0x0A, 0x05FE: 0x78, 0x062D: 0x00,
			}) or bool(status.get("continue_entered", false)) \
					or _confirmations.size() != 1:
				_fail("Frame %d did not stop at the first holder-$0A `$D5EA` decision wait" % source_frame)
				return
			if not _verify_pass_audio_evidence(route, status):
				_fail("The exported PASS route did not keep the ROM-derived $3C context through frame 9600 and apply both observed ROM SFX requests")
				return
			print("PASS: validated ROM-derived $3C audio context remained selected through frame 9600; this does not claim PCM parity.")
			var visuals: Variant = route.get("_visuals")
			if not is_instance_valid(visuals) or not bool(visuals.get("visible")) \
					or not bool(visuals.get("screen").get("visible")):
				_fail("The exported route reached the decision wait with no visible ROM-derived field presentation")
				return
			print("PASS: exported route replayed the unselected command menu, PASS, Down, and A; showed the source-built receiver prompt; confirmed holder `$0A`; and reached the first `$D5EA` decision wait at frame %d. No second action or Continue was entered. Base input SHA-256: %s; action input SHA-256: %s" % [
				FIRST_NEXT_DECISION_FRAME, base_input_hash, first_pass_input_hash])
			print("VERIFIED_ENDPOINT=D5EA")
			quit(0)
			return
	_fail("Exported route did not reach the first `$D5EA` decision wait at frame %d" % FIRST_NEXT_DECISION_FRAME)


func _slot05_boundary(route: KickoffRouteRuntime) -> Dictionary:
	if not is_instance_valid(route._fresh_source_route_runner):
		return {}
	var scheduler: Variant = route._fresh_source_route_runner._scheduler
	if scheduler == null or not scheduler.has_method("get_task_boundary_snapshot"):
		return {}
	return scheduler.get_task_boundary_snapshot(0x05)


func _source_route_timing_debug(route: KickoffRouteRuntime) -> Dictionary:
	var runner: Variant = route.get("_fresh_source_route_runner")
	if runner == null or not is_instance_valid(runner):
		return {"runner": "missing"}
	var runner_status: Dictionary = runner.get_status()
	var route_status: Dictionary = route.get_route_status()
	var nmi_result: Dictionary = route_status.get("fresh_source_route_nmi", {})
	var scheduler: Variant = runner.get("_scheduler")
	var slots: Array[Dictionary] = []
	if scheduler != null and is_instance_valid(scheduler):
		for slot_base in [0x01, 0x05, 0x09, 0x11, 0x15]:
			var boundary: Dictionary = scheduler.get_task_boundary_snapshot(slot_base)
			slots.append({"slot": slot_base, "phase": boundary.get("phase", ""),
				"delay": boundary.get("ready_delay", -1), "resume": boundary.get("pending_resume", -1),
				"pc": boundary.get("pc", -1), "bank": [boundary.get("bank_low", -1), boundary.get("bank_high", -1)],
				"source": boundary.get("source_label", ""), "record": boundary.get("record", PackedByteArray()).hex_encode()})
	return {"phase": runner_status.get("phase", ""),
		"boundary": runner_status.get("source_boundary", ""),
		"last_nmi": runner_status.get("last_external_nmi_frame", -1),
		"pending_slot": runner_status.get("pending_selected_task_slot", -1),
		"pending_pc": runner_status.get("pending_selected_task_boundary_pc", -1),
		"active_slot": runner_status.get("scheduler", {}).get("active_task_slot", -1),
		"scan_cursor": runner_status.get("scheduler", {}).get("scheduler_scan_cursor", -1),
		"nmi": {"ok": nmi_result.get("ok", false), "status": nmi_result.get("status", ""),
			"consumed": nmi_result.get("external_nmi_consumed", false),
			"secondary_queue": nmi_result.get("secondary_queue", {}).get("branch", ""),
			"selected_slot": nmi_result.get("selected_task_slot", -1),
			"next_selected_slot": nmi_result.get("next_selected_task_slot", -1),
			"scan": nmi_result.get("next_task_scan", nmi_result.get("next_task_scan_results", []))},
		"slots": slots}


func _ram_signature(ram: Variant, expected: Dictionary) -> bool:
	if not ram is PackedByteArray or ram.size() != 0x800:
		return false
	for address_variant in expected:
		var address := int(address_variant)
		if int(ram[address]) != int(expected[address_variant]):
			return false
	return true


func _has_recorded_pass_receiver_confirmation(status: Dictionary,
		expected_input_frame: int) -> bool:
	var runner_status: Dictionary = status.get("fresh_source_route", {})
	var confirmation: Dictionary = runner_status.get("last_pass_receiver_input_result", {})
	var input_receipt: Dictionary = confirmation.get("input_sample_receipt", {})
	var boundary: Dictionary = confirmation.get("next_boundary_snapshot", {})
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var poll_frame := int(confirmation.get("source_frame_label", -1))
	return String(confirmation.get("status", "")) \
			== "receiver_confirmed_at_d70c_from_renderer_return" \
		and int(confirmation.get("exit_pc", -1)) == 0xD70C \
		and poll_frame >= expected_input_frame \
		and int(input_receipt.get("source_frame_label", -1)) == expected_input_frame \
		and int(input_receipt.get("edge_ram_001e", -1)) == 0x80 \
		and int(input_receipt.get("held_ram_001c", -1)) == 0x80 \
		and int(confirmation.get("sample_receipt_id", -1)) > 0 \
		and int(input_receipt.get("sample_receipt_id", -2)) \
			== int(confirmation.get("sample_receipt_id", -1)) \
		and int(boundary.get("pc", -1)) == 0xD70C \
		and _ram_signature(ram, {0x05FC: 0x0A, 0x0638: 0x78, 0x0441: 0x06})


func _verify_pass_audio_evidence(route: KickoffRouteRuntime, status: Dictionary) -> bool:
	var seen_sfx: Dictionary = {}
	var context_start_applied := false
	var events: Array = status.get("sound_queue_write_events", [])
	for event_variant in events:
		if not event_variant is Dictionary:
			continue
		var event: Dictionary = event_variant
		var queue_id := int(event.get("queue_id", -1))
		var route_frame := int(event.get("route_frame", -1))
		if queue_id == FIRST_PASS_CONTEXT_QUEUE_ID and route_frame == FIRST_PASS_CONTEXT_START_FRAME \
				and event.has("applied") and bool(event["applied"]):
			context_start_applied = true
		if queue_id == 0x2B and route_frame == 9125 \
				or queue_id == 0x2C and route_frame == 9247:
			if event.has("applied") and bool(event["applied"]):
				seen_sfx[queue_id] = true
	if not context_start_applied or not seen_sfx.has(0x2B) or not seen_sfx.has(0x2C) \
			or not (status.get("unsupported_audio_queue_ids", []) as Array).is_empty():
		return false

	var cue_audio := route.cue_audio
	if not is_instance_valid(cue_audio) \
			or int(cue_audio.current_bgm_queue_id) != FIRST_PASS_CONTEXT_QUEUE_ID:
		return false
	var playback_timing: Dictionary = cue_audio.current_playback_timing
	if str(playback_timing.get("source_timing_path", "")) != FIRST_PASS_CONTEXT_TIMING_PATH \
			or int(playback_timing.get("queue_source_frame", -1)) != FIRST_PASS_CONTEXT_START_FRAME \
			or int(playback_timing.get("source_end_frame", -1)) != FIRST_NEXT_DECISION_FRAME \
			or playback_timing.get("embedded_sfx_queue_ids", []) != [0x66, 0x2B, 0x2C, 0x2B, 0x2C]:
		return false

	# The presenter validates the sidecar and WAV hashes before caching this cue.
	# Confirm that the active playback still refers to that validated ROM-only
	# asset and interval; this does not compare PCM output.
	var validated_cues: Dictionary = cue_audio.get("_validated_cues")
	var cue: Dictionary = validated_cues.get(FIRST_PASS_CONTEXT_QUEUE_ID, {})
	var source_timing: Dictionary = cue.get("source_timing", {})
	var occurrences: Array = source_timing.get("occurrences", [])
	if occurrences.size() != 1:
		return false
	var occurrence: Dictionary = occurrences[0]
	var source_end: Dictionary = occurrence.get("source_end", {})
	var cue_stream: Variant = cue.get("stream")
	var bgm_player := cue_audio.get("_bgm_player") as AudioStreamPlayer
	return str(cue.get("kind", "")) == "bgm" \
			and cue_stream is AudioStreamWAV \
			and str((cue_stream as AudioStreamWAV).resource_path) == "res://" + FIRST_PASS_CONTEXT_WAV_PATH \
			and int(cue.get("source_pcm_sample_count", -1)) == FIRST_PASS_CONTEXT_SAMPLE_COUNT \
			and str(source_timing.get("source_rom_sha256", "")) == ROM_SHA256 \
			and str(source_timing.get("cue", "")) == "$3C" \
			and str(source_timing.get("source_audio_path", "")) == FIRST_PASS_CONTEXT_WAV_PATH \
			and str(source_timing.get("source_audio_sha256", "")) == FIRST_PASS_CONTEXT_WAV_SHA256 \
			and not bool(source_timing.get("captured_pcm_used", true)) \
			and not bool(source_timing.get("captured_wav_used", true)) \
			and not bool(source_timing.get("capture_used_as_event_input", true)) \
			and not bool(source_timing.get("runtime_needs_rom_or_emulator", true)) \
			and int(occurrence.get("queue_source_frame", -1)) == FIRST_PASS_CONTEXT_START_FRAME \
			and int(source_end.get("source_frame", -1)) == FIRST_NEXT_DECISION_FRAME \
			and occurrence.get("asset_sample_window", []) == [0, FIRST_PASS_CONTEXT_SAMPLE_COUNT] \
			and bgm_player != null and bgm_player.stream is AudioStreamWAV


func _verify_unselected_menu_state(route: KickoffRouteRuntime, status: Dictionary,
		source_frame: int) -> bool:
	if String(status.get("stage", "")) != "first_action_menu" \
			or not bool(status.get("first_action_menu_complete", false)) \
			or int(status.get("selected_action_id", -2)) != MENU_INPUT.ActionId.NONE \
			or not is_instance_valid(route._menu_input) \
			or bool(status.get("continue_entered", false)) \
			or not _confirmations.is_empty():
		_fail("Exported first-menu baseline was not complete and unselected at frame %d" % source_frame)
		return false
	return true


func _verify_first_pass_scheduler_handoff(route: KickoffRouteRuntime, status: Dictionary,
		base_input_hash: String, first_pass_input_hash: String) -> bool:
	var stage := String(status.get("stage", ""))
	var input_sample: Dictionary = status.get("first_action_menu_source_input_sample", {})
	var dispatch: Dictionary = input_sample.get("next_frame_dispatch", {})
	var bridge: Dictionary = dispatch.get("confirmation_bridge", {})
	var bridge_handoff: Dictionary = bridge.get("scheduler_handoff", {})
	var scans: Array = dispatch.get("scheduler_scan_results", [])
	if stage not in ["source_route_waiting_for_nmi", "source_route_waiting_for_task_source",
			"first_action_handler_pending"] \
			or String(dispatch.get("status", "")) != "pass_confirmation_scheduler_handoff" \
			or int(dispatch.get("source_boundary_pc", -1)) != 0xCAA5 \
			or String(bridge.get("status", "")) != "pass_confirmation_yielded_waiting_for_scheduler_nmi" \
			or int(bridge_handoff.get("pc", -1)) != 0xCAA5 \
			or bool(bridge.get("d6c7_reached", true)) \
			or scans.is_empty() or _confirmations.size() != 1 \
			or bool(status.get("continue_entered", false)):
		_fail("Exported PASS route did not stop at its genuine post-A scheduler boundary (stage=%s, dispatch=%s)" % [
			stage, String(dispatch.get("status", ""))])
		return false
	print("PASS: exported route held the unselected menu through frame %d, replayed Left at %d and A at %d, and reached the source-verified `$CAA5` scheduler boundary at frame %d (%s). No second action or Continue was entered; `$D6C7` was not claimed. Base input SHA-256: %s; first-PASS edge SHA-256: %s" % [
		LAST_SOURCE_FRAME, FIRST_PASS_SELECTION_FRAME, FIRST_PASS_CONFIRMATION_FRAME,
		FIRST_PASS_POST_CONFIRMATION_FRAME, stage, base_input_hash, first_pass_input_hash])
	print("VERIFIED_ENDPOINT=CAA5")
	return true


func _read_first_pass_input_edges(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open validation PASS input-edge CSV: %s" % path}
	var bytes := FileAccess.get_file_as_bytes(path)
	var digest := _sha256_hex(bytes)
	if digest != EXPECTED_FIRST_PASS_EDGES_SHA256:
		return {"ok": false, "error": "PASS input-edge CSV hash mismatch: %s" % digest}
	file.get_csv_line()
	var result: Dictionary = {}
	var event_count := 0
	var expected_edges := {
		9043: {"name": "Left", "pressed": true},
		9044: {"name": "Left", "pressed": false},
		9045: {"name": "A", "pressed": true},
		9046: {"name": "A", "pressed": false},
		9068: {"name": "Down", "pressed": true},
		9069: {"name": "Down", "pressed": false},
		9076: {"name": "A", "pressed": true},
		9077: {"name": "A", "pressed": false},
	}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3:
			continue
		var source_frame := int(row[0])
		if source_frame < FIRST_PASS_SELECTION_FRAME or source_frame > FIRST_RECEIVER_CONFIRMATION_FRAME + 1:
			continue
		var button := String(row[1]).strip_edges()
		var expected_edge: Dictionary = expected_edges.get(source_frame, {})
		if expected_edge.is_empty() or button != String(expected_edge.get("name", "")) \
				or (String(row[2]).strip_edges() == "1") != bool(expected_edge.get("pressed", false)):
			return {"ok": false, "error": "Unexpected bounded PASS input edge at frame %d: %s/%s" % [
				source_frame, button, String(row[2]).strip_edges()]}
		if not result.has(source_frame):
			result[source_frame] = []
		(result[source_frame] as Array).append({"name": button,
			"pressed": String(row[2]).strip_edges() == "1"})
		event_count += 1
	file.close()
	var expected_frames := [9043, 9044, 9045, 9046, 9068, 9069, 9076, 9077]
	if event_count != expected_frames.size():
		return {"ok": false, "error": "Bounded PASS edge CSV must contain exactly eight command/receiver input press-release edges"}
	for expected_frame in expected_frames:
		if not result.has(expected_frame) or (result[expected_frame] as Array).size() != 1:
			return {"ok": false, "error": "Bounded PASS edge CSV is missing its unique event at frame %d" % expected_frame}
	return {"ok": true, "edges": result, "sha256": digest}


func _read_input_edges(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open validation input CSV: %s" % path}
	var bytes := FileAccess.get_file_as_bytes(path)
	var digest := _sha256_hex(bytes)
	if digest != EXPECTED_INPUT_SHA256:
		return {"ok": false, "error": "Input CSV hash mismatch: %s" % digest}
	file.get_csv_line()
	var result: Dictionary = {}
	var previous: Dictionary = {}
	var button_names := ["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"]
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		var current: Dictionary = {}
		for index in range(2, 10):
			if row[index] == "1":
				current[button_names[index - 2]] = true
		var changes: Array[Dictionary] = []
		for button_name: String in button_names:
			var was_pressed := bool(previous.get(button_name, false))
			var is_pressed := bool(current.get(button_name, false))
			if was_pressed != is_pressed:
				changes.append({"name": button_name, "pressed": is_pressed})
		if source_frame > TITLE_HANDOFF_FRAME and not changes.is_empty():
			result[source_frame] = changes
		previous = current
	return {"ok": not result.is_empty(), "edges": result, "sha256": digest}


func _dispatch_edges(route: KickoffRouteRuntime, changes: Array) -> void:
	for change_variant in changes:
		if not change_variant is Dictionary:
			continue
		var change: Dictionary = change_variant
		var key: Key
		match String(change.get("name", "")):
			"Up": key = KEY_UP
			"Down": key = KEY_DOWN
			"Left": key = KEY_LEFT
			"Right": key = KEY_RIGHT
			"A": key = KEY_Z
			"B": key = KEY_X
			"Select": key = KEY_SHIFT
			"Start": continue
			_: continue
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = bool(change.get("pressed", false))
		route.call("_unhandled_input", event)
		var stage := String(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _verify_endpoint(route: KickoffRouteRuntime, status: Dictionary, menu_onset_frame: int,
		comparison_frame: int, input_hash: String) -> bool:
	var selected := int(status.get("selected_action_id", -2))
	if not bool(status.get("first_action_menu_complete", false)) or selected != -1 \
			or not is_instance_valid(route._menu_input):
		_fail("First-menu endpoint is incomplete or already selected at comparison frame %d" % comparison_frame)
		return false
	if not _verify_navigation(route):
		_fail("Exported first-menu keyboard/D-pad navigation failed")
		return false
	var final_status: Dictionary = route.get_route_status()
	if String(final_status.get("stage", "")) != "first_action_menu" \
			or bool(final_status.get("continue_entered", false)) \
			or not _confirmations.is_empty():
		_fail("Navigation left the first menu or emitted an action confirmation")
		return false
	print("PASS: exported route opened the unselected first menu at frame %d and remained there through comparison frame %d; keyboard/D-pad navigation passed with no confirmation or Continue entry. Input SHA-256: %s" % [menu_onset_frame, comparison_frame, input_hash])
	return true


func _verify_navigation(route: KickoffRouteRuntime) -> bool:
	var key_cases: Array[Dictionary] = [
		{"key": KEY_RIGHT, "action": MENU_INPUT.ActionId.SHOOT},
		{"key": KEY_LEFT, "action": MENU_INPUT.ActionId.PASS},
		{"key": KEY_DOWN, "action": MENU_INPUT.ActionId.ONE_TWO_PASS},
		{"key": KEY_UP, "action": MENU_INPUT.ActionId.DRIBBLE},
	]
	for test_case: Dictionary in key_cases:
		var event := InputEventKey.new()
		event.keycode = int(test_case["key"])
		event.pressed = true
		if not route._menu_input.handle_input_event(event):
			return false
		route._menu_input.flush_pending_input()
		if route._menu_input.selected_action_id != int(test_case["action"]):
			return false
	var pad_cases: Array[Dictionary] = [
		{"button": JOY_BUTTON_DPAD_RIGHT, "action": MENU_INPUT.ActionId.SHOOT},
		{"button": JOY_BUTTON_DPAD_LEFT, "action": MENU_INPUT.ActionId.PASS},
		{"button": JOY_BUTTON_DPAD_DOWN, "action": MENU_INPUT.ActionId.ONE_TWO_PASS},
		{"button": JOY_BUTTON_DPAD_UP, "action": MENU_INPUT.ActionId.DRIBBLE},
	]
	for test_case: Dictionary in pad_cases:
		var event := InputEventJoypadButton.new()
		event.button_index = int(test_case["button"])
		event.pressed = true
		if not route._menu_input.handle_input_event(event):
			return false
		route._menu_input.flush_pending_input()
		if route._menu_input.selected_action_id != int(test_case["action"]):
			return false
	return route.get_route_status().get("selected_action_id", -2) == int(MENU_INPUT.ActionId.DRIBBLE)


func _on_confirmation_requested(action_id: int) -> void:
	_confirmations.append(action_id)


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	hash_context.update(bytes)
	return hash_context.finish().hex_encode()


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
