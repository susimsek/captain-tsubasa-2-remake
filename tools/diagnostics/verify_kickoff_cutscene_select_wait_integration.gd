extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const CLEANUP_TRACE_CSV := "res://reference/diagnostics/kickoff_select_cleanup_counters_20261031_001445_utc/frame_snapshots.csv"
const CLEANUP_PPU_REFERENCE := "res://reference/diagnostics/kickoff_select_cleanup_counters_20261031_001445_utc/frame_7258_ppu_pass1.bin"
const CLEANUP_RAM_REFERENCE := "res://reference/diagnostics/kickoff_select_cleanup_counters_20261031_001445_utc/frame_7258_ram_pass1.bin"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var title := main.get_node("TitleMenu") as RomTitleMenu
	title.kickoff_requested.emit()
	await process_frame
	var route := main.get_node("KickoffRouteRuntime") as KickoffRouteRuntime
	route.set_process(false)
	route.source_frame = 4693
	var advance_key := InputEventKey.new()
	advance_key.keycode = KEY_Z
	advance_key.pressed = true
	_check(advance_key.is_action_pressed("route_advance"), "Z maps to the route's A/advance action")
	route._unhandled_input(advance_key)
	_check(route._pending_a_edge, "a fresh Z press reaches the cutscene A-edge input")
	route._pending_a_edge = false
	_check(route.get_route_status().get("stage") == "cutscene_1"
		and bool(route.get_route_status().get("cutscene_select_wait", {}).get("waiting", false)),
		"cutscene 1 starts with the ROM caller's $82B5 waiter")

	var edges := _read_recorded_edges()
	_check(not edges.is_empty(), "same-input FCEUX controller edges load")
	for frame in range(4694, 7244):
		if edges.has(frame):
			_dispatch_edges(route, edges[frame])
		route._advance_route_source_tick()
		if String(route.get_route_status().get("stage", "")) == "match_setup_gap":
			break

	var id1_status := route.get_route_status()
	var id1_cleanup: Dictionary = id1_status.get("cutscene_wait_cleanup", {})
	print("ID-1 route checkpoint: frame=%d stage=%s cutscene=%d completion=%s wait_yields=%d cleanup=%s next_helper=%s" % [
		int(id1_status.get("source_frame", -1)), String(id1_status.get("stage", "")),
		int(id1_status.get("last_completed_cutscene_id", -1)),
		String(id1_status.get("last_cutscene_completion_kind", "")),
		int(id1_status.get("cutscene_select_wait", {}).get("yield_count", -1)),
		String(id1_cleanup.get("status", "")),
		String(id1_cleanup.get("pending_helper_id", "")),
	])
	_check(int(id1_status.get("source_frame", -1)) == 7243
		and String(id1_status.get("stage", "")) == "cutscene_cleanup_fade"
		and int(id1_status.get("last_completed_cutscene_id", -1)) == 1
		and String(id1_status.get("last_cutscene_completion_kind", "")) == "select",
		"recorded Select at frame 7243 returns cutscene 1 and enters the shared cleanup fade")
	_check(String(id1_cleanup.get("status", "")) == "blocked_on_helper"
		and int(id1_cleanup.get("pending_source_pc", -1)) == 0x82DF
		and int(id1_cleanup.get("caller_return_pc_after_helper", -1)) == 0x80F1,
		"ID 1 holds at $82DF before its caller resumes at $80F1")
	var id1_audio: Dictionary = id1_cleanup.get("audio_stop_request", {})
	var sound_events: Array = id1_status.get("sound_queue_write_events", [])
	_check(bool(id1_audio.get("applied", false))
		and int(id1_audio.get("source_pc", -1)) == 0x82DC
		and int(id1_audio.get("queue_address", -1)) == 0x0700
		and not sound_events.is_empty()
		and int(sound_events.back().get("queue_id", -1)) == 0x01,
		"the verified $82DC=$01 store stops route audio and records provenance")
	var cleanup_trace := _read_cleanup_trace()
	_check(cleanup_trace.has(7243), "frame-end cleanup trace loads for packet comparison")
	_check(_check_cleanup_packet_against_trace(route, cleanup_trace, 7243),
		"the first source-built $05E8 packet matches FCEUX at frame 7243")
	for expected_frame in range(7244, 7258):
		route._advance_route_source_tick()
		_check(int(route.source_frame) == expected_frame
			and String(route.get_route_status().get("stage", "")) == "cutscene_cleanup_fade",
			"$99F0 yields once per source frame through %d" % expected_frame)
		_check(_check_cleanup_packet_against_trace(route, cleanup_trace, expected_frame),
			"the source-built $05E8 packet matches FCEUX at frame %d" % expected_frame)
	route._advance_route_source_tick()
	var selector_start_status: Dictionary = route.get_route_status()
	var selector_start: Dictionary = selector_start_status.get("fresh_match_selector_clock", {})
	_check(int(selector_start_status.get("source_frame", -1)) == 7258
		and String(selector_start_status.get("stage", "")) == "match_selector_running"
		and int(selector_start.get("progress", {}).get("frame_offset", -1)) == 0
		and int(selector_start.get("progress", {}).get("mainline_cycle_end", -1)) == 2999,
		"the `$A20F` selector starts its measured frame-offset-0 budget at frame 7258")
	var selector_frame_progress := true
	for expected_frame in range(7259, 7267):
		route._advance_route_source_tick()
		var frame_status: Dictionary = route.get_route_status()
		var frame_clock: Dictionary = frame_status.get("fresh_match_selector_clock", {})
		var frame_progress: Dictionary = frame_clock.get("progress", {})
		if int(frame_status.get("source_frame", -1)) != expected_frame:
			selector_frame_progress = false
			break
		if expected_frame < 7266 and (String(frame_status.get("stage", "")) != "match_selector_running"
				or int(frame_progress.get("frame_offset", -1)) != expected_frame - 7258):
			selector_frame_progress = false
			break
	_check(selector_frame_progress and String(route.get_route_status().get("stage", "")) == "match_setup_gap",
		"the cycle-ordered selector timeline advances over source frames 7258–7266")
	var fade_return_status: Dictionary = route.get_route_status()
	var source_ram_image: Dictionary = fade_return_status.get("source_ram_image_at_893b", {})
	var known_ram_values: Dictionary = source_ram_image.get("known_values", {})
	var sound_queue_tail_unknown := not known_ram_values.has(0x07FC)
	for address in range(0x0701, 0x0706):
		sound_queue_tail_unknown = sound_queue_tail_unknown and not known_ram_values.has(address)
	_check(String(source_ram_image.get("status", "")) == "sparse_source_writes_only"
		and int(source_ram_image.get("known_byte_count", 0)) > 0
		and int(source_ram_image.get("unknown_byte_count", 0)) > 0
		and int(source_ram_image.get("ignored_non_internal_ram_write_count", 0)) > 0
		and int(known_ram_values.get(0x0025, -1)) == 0x06
		and int(known_ram_values.get(0x0700, -1)) == 0x01
		and sound_queue_tail_unknown,
		"the `$893B` route exposes proven 2 KiB RAM writes, including `$0700=$01`, keeps queue tail and `$07FC` unknown, and excludes PRG-RAM copies")
	var selector_clock_status: Dictionary = fade_return_status.get("fresh_match_selector_clock", {})
	var selector_progress: Dictionary = selector_clock_status.get("progress", {})
	_check(int(selector_progress.get("frame_offset", -1)) == 8
		and int(selector_progress.get("mainline_cycle_end", -1)) == 203333
		and bool(selector_progress.get("ram_timeline_complete", false))
		and int(selector_progress.get("scheduled_interrupt_count", -1)) == 15
		and not bool(selector_progress.get("interrupt_handler_state_applied", true)),
		"the selector returns after 203,333 cycle-ordered mainline cycles while preserving handler gaps")
	var fade_status: Dictionary = fade_return_status.get("cutscene_cleanup_fade", {})
	var after_fade_cleanup: Dictionary = fade_return_status.get("cutscene_wait_cleanup", {})
	var caller_result: Dictionary = after_fade_cleanup.get("post_helper_caller_result", {})
	var cleanup_clear_result: Dictionary = after_fade_cleanup.get("clear_helper_result", {})
	var cleanup_cpu_contract: Dictionary = cleanup_clear_result.get("cpu_output_contract", {})
	var caller_cpu_input_contract: Dictionary = caller_result.get("cleanup_cpu_input_contract", {})
	_check(int(fade_return_status.get("source_frame", -1)) == 7266
		and String(fade_return_status.get("stage", "")) == "match_setup_gap"
		and int(fade_status.get("counter_a", -1)) == 0
		and int(fade_status.get("counter_b", -1)) == 0
		and int(fade_status.get("yield_count", -1)) == 15
		and int(fade_status.get("source_pc", -1)) == 0x9A0C,
		"$99F0 returns after 15 source-selected yields at frame 7258 before the selector spans eight frames")
	_check(int(cleanup_cpu_contract.get("return_pc", -1)) == 0x82E2
		and int(cleanup_cpu_contract.get("a", -1)) == 0
		and int(cleanup_cpu_contract.get("x", -1)) == 0
		and int(cleanup_cpu_contract.get("y", -1)) == 0
		and int(cleanup_cpu_contract.get("p_known_mask", -1)) == 0x82
		and int(cleanup_cpu_contract.get("p_known_value", -1)) == 0x02
		and caller_cpu_input_contract == cleanup_cpu_contract,
		"the cleanup helper passes its ROM-derived register/status contract into the caller prefix")
	var id1_caller_contract: Dictionary = caller_result.get("cpu_output_contract", {})
	var id1_pending_call: Dictionary = caller_result.get("pending_call", {})
	var caller_before_mapper: Dictionary = caller_result.get("caller_cpu_contract_before_mapper", {})
	var mapper_shadow: Dictionary = caller_result.get("mapper_shadow_state", {})
	var mapper_result: Dictionary = caller_result.get("mapper_helper_result", {})
	var mapper_cpu: Dictionary = mapper_result.get("return_registers", {})
	var mapper_writes: Array = mapper_result.get("mapper_bus_writes", [])
	var selector_result: Dictionary = caller_result.get("match_selector_result", {})
	var selector_entry_cpu: Dictionary = selector_result.get("entry_registers", {})
	var selector_entry_status: Dictionary = caller_result.get("selector_entry_status_evidence", {})
	var selector_cpu: Dictionary = selector_result.get("return_registers", {})
	var selector_ram: Dictionary = selector_result.get("ram_after", {})
	var normalize_result: Dictionary = caller_result.get("match_normalize_result", {})
	var normalize_cpu: Dictionary = normalize_result.get("return_registers", {})
	var normalize_ram: Dictionary = normalize_result.get("caller_ram_after", {})
	var preset_result: Dictionary = caller_result.get("match_preset_loader_prefix_result", {})
	var preset_boundary: Dictionary = preset_result.get("boundary", {})
	var preset_cpu: Dictionary = preset_result.get("boundary_registers", {})
	var preset_ram: Dictionary = preset_result.get("caller_ram_after", {})
	var expected_prefix := [0x82E2, 0x82E4, 0x82E6, 0x82E8, 0x82EA, 0x82EC, 0x80F1, 0x80F3, 0x80F5, 0x80F7, 0xC4B9, 0xC4BB, 0xC4BD, 0xC4BF, 0xC4C1, 0xC4C4, 0xC4C7, 0x80FA]
	var actual_source_path: Array = caller_result.get("source_path", [])
	var source_prefix_matches := actual_source_path.size() > expected_prefix.size()
	if source_prefix_matches:
		for index in expected_prefix.size():
			if int(actual_source_path[index]) != int(expected_prefix[index]):
				source_prefix_matches = false
				break
	_check(int(after_fade_cleanup.get("pending_source_pc", -1)) == 0x893B
		and String(after_fade_cleanup.get("pending_helper_id", "")) == "fresh_match_preset_wait_0078"
		and String(caller_result.get("status", "")) == "stopped_at_preset_wait"
		and int(caller_result.get("helper_return_pc", -1)) == 0x82E2
		and int(caller_result.get("caller_call_pc", -1)) == 0x80EE
		and source_prefix_matches
		and caller_result.get("ram_writes", []).back().get("address", -1) == 0x00E0
		and caller_result.get("ram_writes", []).back().get("value", -1) == 0xC0
		and actual_source_path.back() == 0x893B
		and int(id1_pending_call.get("caller_pc", -1)) == 0x893B
		and int(id1_pending_call.get("next_source_pc", -1)) == 0x893B
		and int(caller_result.get("final_source_pc", -1)) == 0x893B,
		"the caller reaches the source-confirmed `$893B` preset-wait boundary")
	_check(int(caller_before_mapper.get("a", -1)) == 0xC0
		and int(caller_before_mapper.get("x", -1)) == 0x02
		and int(caller_before_mapper.get("y", -1)) == 0x00
		and int(caller_before_mapper.get("p_known_mask", -1)) == 0x82
		and int(caller_before_mapper.get("p_known_value", -1)) == 0x00
		and bool(mapper_shadow.get("ok", false))
		and int(mapper_shadow.get("value", -1)) == 0
		and not bool(mapper_shadow.get("emulator_data_used", true))
		and bool(mapper_result.get("ok", false))
		and int(mapper_result.get("cpu_cycles", -1)) == 25
		and int(mapper_cpu.get("pc", -1)) == 0x80FA
		and int(mapper_cpu.get("a", -1)) == 0x07
		and int(mapper_cpu.get("x", -1)) == 0x02
		and int(mapper_cpu.get("y", -1)) == 0
		and int(mapper_cpu.get("p_known_mask", -1)) == 0x82
		and int(mapper_cpu.get("p_known_value", -1)) == 0
		and mapper_writes.size() == 2
		and int(mapper_writes[0].get("address", -1)) == 0x8000
		and int(mapper_writes[0].get("value", -1)) == 0x07
		and int(mapper_writes[1].get("address", -1)) == 0x8001
		and int(mapper_writes[1].get("value", -1)) == 0x02,
		"the live mapper call uses ROM-derived `$0022` and returns at `$80FA`")
	_check(bool(selector_result.get("ok", false))
		and String(selector_result.get("source_return_receipt", {}).get("stack_model", "")) == "logical_source_jsr_frames"
		and int(selector_result.get("copy_loop_iterations", -1)) == 0x1350
		and int(selector_result.get("roster_loop_iterations", -1)) == 11
		and int(selector_cpu.get("pc", -1)) == 0x80FD
		and int(selector_cpu.get("y", -1)) == 0x84
		and int(selector_ram.get(0x0300, -1)) == 0x02
		and int(selector_ram.get(0x002A, -1)) == 0x00
		and int(selector_ram.get(0x002B, -1)) == 0x03,
		"the live match selector copies the first roster and returns at `$80FD` using logical JSR frames")
	_check(not bool(selector_entry_status.get("live_source_status_known", true))
		and not bool(selector_entry_status.get("i_flag_known", true))
		and not bool(selector_entry_status.get("candidate_status_applied", true))
		and (int(selector_entry_cpu.get("p_known_mask", 0)) & 0x04) == 0,
		"the selector retains I as unknown instead of importing the ROM-only candidate bit")
	_check(bool(normalize_result.get("ok", false))
		and String(normalize_result.get("stack_model", "")) == "logical_source_jsr_frames"
		and int(normalize_result.get("cpu_cycles_without_interrupts_from_80FD", -1)) == 94
		and int(normalize_cpu.get("pc", -1)) == 0x8112
		and int(normalize_cpu.get("a", -1)) == 0x03
		and int(normalize_cpu.get("x", -1)) == 0x00
		and int(normalize_cpu.get("y", -1)) == 0x84
		and int(normalize_cpu.get("p_known_mask", -1)) == 0xC3
		and int(normalize_ram.get(0x0028, -1)) == 0
		and int(normalize_ram.get(0x0029, -1)) == 0
		and int(normalize_ram.get(0x0027, -1)) == 0
		and int(normalize_ram.get(0x0700, -1)) == 1
		and int(normalize_ram.get(0x002B, -1)) == 3,
		"the live caller executes `$80FD-$8112`, second `$C4B9`, and `$A20C` with the ROM-derived logical stack")
	_check(bool(preset_result.get("ok", false))
		and String(preset_result.get("status", "")) == "stopped_at_unresolved_source_predicate"
		and String(preset_result.get("stack_model", "")) == "logical_source_jsr_frames"
		and int(preset_result.get("cpu_cycles_without_interrupts_from_8112", -1)) == 232
		and int(preset_boundary.get("pc", -1)) == 0x893B
		and int(preset_boundary.get("required_ram_address", -1)) == 0x0078
		and int(preset_cpu.get("pc", -1)) == 0x893B
		and int(preset_cpu.get("a", -1)) == 0x07
		and int(preset_cpu.get("x", -1)) == 0x06
		and int(preset_cpu.get("y", -1)) == 0
		and int(preset_cpu.get("p_known_mask", -1)) == 0xC3
		and int(preset_cpu.get("p_known_value", -1)) == 0
		and int(preset_ram.get(0x00EC, -1)) == 0
		and int(preset_ram.get(0x00ED, -1)) == 0xBF
		and int(preset_ram.get(0x00EA, -1)) == 0x02
		and int(preset_ram.get(0x0025, -1)) == 0x06
		and not preset_ram.has(0x0078)
		and preset_result.get("return_receipt", {}).is_empty(),
		"the `$8112-$893B` prefix derives the `$BF00` preset pointer and bank `$06`, then stops before the unowned `$78` read")
	_check(route._visuals.screen.get_background_palette_bytes() == PackedByteArray([
		0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F,
		0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F]),
		"the final zero-level background palette commits on the following modeled source tick")
	var clear_ppu := FileAccess.get_file_as_bytes(CLEANUP_PPU_REFERENCE)
	var clear_ram := FileAccess.get_file_as_bytes(CLEANUP_RAM_REFERENCE)
	_check(clear_ppu.size() == 0x4000 and clear_ram.size() == 0x800,
		"same-input frame-7258 full PPU/RAM reference snapshots load")
	var ppu_clear_matches := clear_ppu.size() == 0x4000
	if ppu_clear_matches:
		for address in range(0x2000, 0x2800):
			if route._visuals.screen.read_nametable_ppu_byte(address) != clear_ppu[address]:
				ppu_clear_matches = false
				break
	_check(ppu_clear_matches, "Godot $98A0 nametable/attribute clear matches the same-input FCEUX PPU image")
	var oam_writes: Dictionary = fade_return_status.get("cutscene_cleanup_ram_writes", {})
	var post_helper_writes: Dictionary = fade_return_status.get("cutscene_post_helper_ram_writes", {})
	var oam_ram_matches := clear_ram.size() == 0x800 and oam_writes.size() == 516
	var clear_helper: Dictionary = after_fade_cleanup.get("clear_helper_result", {})
	var helper_ram_writes: Array = clear_helper.get("ram_writes", [])
	var dma_source_pcs_match := true
	var dma_pc_count := 0
	for write_variant in helper_ram_writes:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) in range(0x0200, 0x0300):
				dma_pc_count += 1
				if int(write.get("source_pc", -1)) != 0x9B8B:
					dma_source_pcs_match = false
	_check(dma_source_pcs_match and dma_pc_count == 0x100,
		"all OAM DMA shadow writes are attributed to the ROM STA at $9B8B")
	if oam_ram_matches:
		for address in range(0x0200, 0x0300):
			if int(oam_writes.get(address, -1)) != clear_ram[address]:
				oam_ram_matches = false
				break
		for address in range(0x0468, 0x0568):
			if int(oam_writes.get(address, -1)) != clear_ram[address]:
				oam_ram_matches = false
				break
		for address in [0x0568, 0x0588, 0x05A8, 0x05C8]:
			if int(oam_writes.get(address, -1)) != clear_ram[address]:
				oam_ram_matches = false
				break
	_check(oam_ram_matches, "Godot $9B7F OAM and motion-record writes match the same-input FCEUX RAM image")
	var caller_ram_matches := post_helper_writes.size() == 5 and clear_ram.size() == 0x800
	if caller_ram_matches:
		for address in [0x44, 0x45, 0x7A, 0x7B, 0xE0]:
			if int(post_helper_writes.get(address, -1)) != clear_ram[address]:
				caller_ram_matches = false
				break
	_check(caller_ram_matches, "the $82E2-$82EC and $80F3 caller stores match the same-input FCEUX RAM image")
	_check(route._visuals._animations.is_empty(), "$9B7F removes all cutscene sprite presenters from the live image")

	# The ID-2 wait uses the same helper. Start it directly here because ID 1's
	# required $9BA0 helper/caller continuation is deliberately still pending.
	route._start_cutscene(2)
	_check(String(route.get_route_status().get("stage", "")) == "cutscene_2",
		"cutscene 2 also starts with the shared ROM caller waiter")
	for _tick in 42:
		route._advance_route_source_tick()
	var id2_wait: Dictionary = route.get_route_status().get("cutscene_select_wait", {})
	_check(int(id2_wait.get("yield_count", -1)) == 43,
		"the ID-2 wait executes the 43 trace-backed one-tick polls")
	var select_input := InputEventAction.new()
	select_input.action = "route_select"
	select_input.pressed = true
	route._unhandled_input(select_input)
	route._advance_route_source_tick()
	var id2_status := route.get_route_status()
	var id2_cleanup: Dictionary = id2_status.get("cutscene_wait_cleanup", {})
	_check(int(id2_status.get("last_completed_cutscene_id", -1)) == 2
		and String(id2_status.get("last_cutscene_completion_kind", "")) == "select"
		and int(id2_cleanup.get("caller_return_pc_after_helper", -1)) == 0x815D,
		"ID 2 Select uses the same cleanup boundary and returns to $815D after it")

	if _failures == 0:
		print("PASS: ID-1 Select cleanup matches frame-7258 FCEUX PPU/RAM and palette evidence; selector writes advance over source-frame offsets 0–8 and reach `$893B` at frame 7266; ID-2 waiter also passes.")
		print("LIMIT: 15 selector NMI/IRQ handlers and `$78` wait return remain unexecuted; complete PPU timing parity, physical NES timing, automatic ID-2 dispatch, field, and first command menu remain unverified or incomplete.")
	else:
		printerr("FAIL: %d cutscene Select-wait integration assertion(s)" % _failures)
	if route.cue_audio != null:
		route.cue_audio.release_rom_audio_resources()
	(main.get_node("OpeningAudio") as AudioStreamPlayer).stop()
	root.remove_child(main)
	main.free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


func _read_recorded_edges() -> Dictionary:
	var file := FileAccess.open(INPUT_CSV, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	var result: Dictionary = {}
	var previous: Dictionary = {}
	var button_names := ["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"]
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var frame := int(row[0])
		var current: Dictionary = {}
		for index in range(2, 10):
			if row[index] == "1":
				current[button_names[index - 2]] = true
		var changes: Array[Dictionary] = []
		for name: String in button_names:
			var pressed := bool(current.get(name, false))
			if pressed != bool(previous.get(name, false)):
				changes.append({"name": name, "pressed": pressed})
		if frame > 4693 and not changes.is_empty():
			result[frame] = changes
		previous = current
	return result


func _dispatch_edges(route: KickoffRouteRuntime, changes: Array) -> void:
	for change_variant in changes:
		var change: Dictionary = change_variant
		var key_code: Key
		match String(change.get("name", "")):
			"Up": key_code = KEY_UP
			"Down": key_code = KEY_DOWN
			"Left": key_code = KEY_LEFT
			"Right": key_code = KEY_RIGHT
			"A": key_code = KEY_Z
			"B": key_code = KEY_X
			"Select": key_code = KEY_SHIFT
			_: continue
		var event := InputEventKey.new()
		event.keycode = key_code
		event.pressed = bool(change.get("pressed", false))
		route._unhandled_input(event)


func _read_cleanup_trace() -> Dictionary:
	var file := FileAccess.open(CLEANUP_TRACE_CSV, FileAccess.READ)
	if file == null:
		return {}
	var header := file.get_csv_line()
	var columns: Dictionary = {}
	for index in header.size():
		columns[String(header[index])] = index
	var snapshots := {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < header.size() or row[columns["pass"]] != "1":
			continue
		var frame := int(row[columns["source_frame"]])
		if frame in range(7243, 7258):
			snapshots[frame] = String(row[columns["ram_05e8_060a"]]).to_lower()
	return snapshots


func _check_cleanup_packet_against_trace(route: KickoffRouteRuntime, trace: Dictionary, frame: int) -> bool:
	if not trace.has(frame):
		return false
	var fade_status: Dictionary = route.get_route_status().get("cutscene_cleanup_fade", {})
	return String(fade_status.get("last_palette_packet_hex", "")) == String(trace[frame])


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + label)
