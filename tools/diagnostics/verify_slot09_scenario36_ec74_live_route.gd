extends SceneTree
## Replays the same post-title input through scenario $36's slot-$15 map-worker
## setup, map-$42 batches, and the terminal callback return. Stops before
## visible field presentation or soccer action selection.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const FCEUX_EVENTS_CSV := "res://reference/diagnostics/slot11_actor_handoff_trace_20261030/events.csv"
const FCEUX_REPEAT_EVENTS_CSV := "res://reference/diagnostics/slot11_actor_handoff_trace_20261030/events_repeat.csv"
const FCEUX_RAM_ROOT := "res://reference/diagnostics/kickoff_select_test_20261027/ram"
const FIRST_BATCH_FRAME := 8594
const TERMINAL_FRAME := 8605
const STOP_FRAME := TERMINAL_FRAME + 1

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	route.set_process(false)
	route.source_frame = 4693
	var events := _read_recorded_edges()
	_check(not events.is_empty(), "same-input post-title controller edges load")
	var callback_task_snapshot: Dictionary = {}
	var terminal_task_snapshot: Dictionary = {}
	var terminal_nmi_snapshot: Dictionary = {}
	var terminal_route_snapshot: Dictionary = {}
	var map_batch_snapshots: Dictionary = {}
	var slot11_live_timeline: Dictionary = {}
	var slot11_state_transitions: Array[Dictionary] = []
	var scenario_ram_transitions: Array[Dictionary] = []
	var previous_scenario_signature := ""
	var previous_slot11_signature := ""
	for source_frame in range(4694, STOP_FRAME + 1):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		route.call("_advance_route_source_tick")
		if events.has(source_frame):
			await process_frame
		var live_status := route.get_route_status()
		var live_route: Dictionary = live_status.get("fresh_source_route", {})
		var live_task: Dictionary = live_status.get("fresh_source_route_task", {})
		if source_frame <= 8472 and route._fresh_source_route_runner != null:
			var scenario_scheduler: Variant = route._fresh_source_route_runner.get("_scheduler")
			if scenario_scheduler != null:
				var scenario_boundary: Dictionary = scenario_scheduler.get_task_boundary_snapshot(0x09)
				var scenario_ram: PackedByteArray = scenario_boundary.get("ram_image", PackedByteArray())
				if scenario_ram.size() == 0x800:
					var scenario_signature := scenario_ram.slice(0x0516, 0x051A).hex_encode() \
						+ ":" + scenario_ram.slice(0x0523, 0x052A).hex_encode()
					if scenario_signature != previous_scenario_signature:
						var same_frame_fceux_ram := FileAccess.get_file_as_bytes(
							FCEUX_RAM_ROOT.path_join("route_frame_%06d.bin" % source_frame))
						var live_nmi: Dictionary = live_status.get("fresh_source_route_nmi", {})
						scenario_ram_transitions.append({
							"frame": source_frame,
							"godot": scenario_signature,
							"fceux": same_frame_fceux_ram.slice(0x0516, 0x051A).hex_encode() \
								+ ":" + same_frame_fceux_ram.slice(0x0523, 0x052A).hex_encode()
								if same_frame_fceux_ram.size() == 0x800 else "missing",
							"ram_0011_0014": scenario_ram.slice(0x0011, 0x0015).hex_encode(),
							"ram_0015_0018": scenario_ram.slice(0x0015, 0x0019).hex_encode(),
							"ram_001D_0020": scenario_ram.slice(0x001D, 0x0021).hex_encode(),
							"stage": String(live_status.get("stage", "")),
							"runner_phase": String(live_route.get("phase", "")),
							"pending_slot": int(live_route.get("pending_selected_task_slot", -1)),
							"held_input": int(live_status.get("held_kickoff_input_bits", -1)),
							"nmi": String(live_nmi.get("status", "")),
							"route": String(live_route.get("source_boundary", "")),
							"task": String(live_task.get("status", "")),
						})
						previous_scenario_signature = scenario_signature
		if source_frame >= 8460 and source_frame <= 8480 and route._fresh_source_route_runner != null:
			var scheduler: Variant = route._fresh_source_route_runner.get("_scheduler")
			if scheduler != null:
				var slot11_live_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
				var slot11_live_ram: PackedByteArray = slot11_live_boundary.get("ram_image", PackedByteArray())
				var slot11_signature := "empty"
				if slot11_live_ram.size() == 0x800:
					slot11_signature = "%s:%d:%04X" % [
						slot11_live_boundary.get("record", PackedByteArray()).hex_encode(),
						int(slot11_live_boundary.get("active_task_slot", -1)),
						int(slot11_live_boundary.get("pc", -1))]
				if slot11_signature != previous_slot11_signature:
					slot11_state_transitions.append({
						"frame": source_frame, "signature": slot11_signature,
						"route_phase": String(live_route.get("phase", "")),
						"route_boundary": String(live_route.get("source_boundary", "")),
						"nmi_status": String(live_status.get("fresh_source_route_nmi", {}).get("status", "")),
						"task_status": String(live_task.get("status", "")),
					})
					previous_slot11_signature = slot11_signature
				if source_frame >= 8480 and slot11_live_ram.size() == 0x800:
					slot11_live_timeline[source_frame] = {
						"e4": int(slot11_live_ram[0x05E4]), "e5": int(slot11_live_ram[0x05E5]),
						"e9": int(slot11_live_ram[0x05E9]), "f3": int(slot11_live_ram[0x05F3]),
						"f4": int(slot11_live_ram[0x05F4]), "f5": int(slot11_live_ram[0x05F5]),
					}
		if String(live_task.get("status", "")) == "slot15_map42_terminal_callback_finished_waiting_nmi":
			terminal_task_snapshot = live_task.duplicate(true)
			terminal_nmi_snapshot = live_status.get("fresh_source_route_nmi", {}).duplicate(true)
			terminal_route_snapshot = live_route.duplicate(true)
		if String(live_task.get("status", "")) == "slot15_map_worker_yielded_waiting_nmi":
			callback_task_snapshot = live_task.duplicate(true)
		if String(live_task.get("status", "")) == "slot15_map42_batch_yielded":
			var live_batch: Dictionary = live_task.get("map_batch_result", {})
			map_batch_snapshots[int(live_batch.get("batch_start_map_index", -1))] = live_task.duplicate(true)
		if String(live_route.get("phase", "")) == "error" \
				or bool(live_status.get("first_action_menu_complete", false)):
			break
	var status := route.get_route_status()
	var source_route: Dictionary = status.get("fresh_source_route", {})
	var source_task: Dictionary = status.get("fresh_source_route_task", {})
	var slot11_worker: Dictionary = source_task.get("slot11_resume_result", {})
	var slot11_save: Dictionary = source_task.get("slot11_cb0f_save_result", {})
	var slot11_saved_boundary: Dictionary = slot11_save.get("saved_boundary", {})
	var nmi: Dictionary = status.get("fresh_source_route_nmi", {})
	var event_boundary: Dictionary = source_route.get("scenario36_event_boundary_result", {})
	var post_event: Dictionary = source_route.get("scenario36_post_event_result", {})
	var seed: Dictionary = event_boundary.get("scenario_seed_request", {})
	var scenario_events: Array = event_boundary.get("scenario_runtime_events", [])
	var event_record: Dictionary = scenario_events.back() if not scenario_events.is_empty() else {}
	var event_ram: PackedByteArray = event_boundary.get("ram_image", PackedByteArray())
	var event_stack: PackedByteArray = event_boundary.get("stack_page", PackedByteArray())
	var slot15_seed: Dictionary = source_route.get("scenario36_slot15_seed_result", {})
	var callback_chain: Dictionary = callback_task_snapshot
	var callback_entry: Dictionary = callback_chain.get("callback_entry_result", {})
	var callback_handler: Dictionary = callback_chain.get("callback_handler_result", {})
	var map_worker_entry: Dictionary = callback_chain.get("callback_map_worker_entry_result", {})
	var map_worker_setup: Dictionary = callback_chain.get("map_worker_setup_result", {})
	print("Scenario-$36 live route stop: frame=%d phase=%s boundary=%s error=%s" % [
		route.source_frame, String(source_route.get("phase", "")),
		String(source_route.get("source_boundary", "")), String(source_route.get("error", ""))])
	print("Scenario-$36 RAM check: $0516=$%02X $0518=$%02X $0523-$0529=%s" % [
		int(event_ram[0x0516]) if event_ram.size() == 0x800 else -1,
		int(event_ram[0x0518]) if event_ram.size() == 0x800 else -1,
		event_ram.slice(0x0523, 0x052A).hex_encode() if event_ram.size() == 0x800 else "missing"])
	print("Slot-$11 task-state transitions around first divergence: " + str(slot11_state_transitions))
	print("Scenario RAM transition comparison: " + str(scenario_ram_transitions))
	var first_timeline_mismatch := _first_fceux_slot11_countdown_mismatch(slot11_live_timeline)
	if not first_timeline_mismatch.is_empty():
		print("Earliest same-input slot-$11 counter divergence: " + str(first_timeline_mismatch))
	_check(route.source_frame == STOP_FRAME, "same-input route reaches recorded source frame %d" % STOP_FRAME)
	var has_eleven_batches := true
	for map_index in [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30]:
		has_eleven_batches = has_eleven_batches and map_batch_snapshots.has(map_index)
	_check(has_eleven_batches,
		"recorded route executes all eleven map-$42 row batches through row exhaustion")
	_check(bool(event_boundary.get("ok", false)) \
			and String(event_boundary.get("status", "")) == "scenario36_event_seeded_at_ec74_return" \
			and int(event_boundary.get("exit_pc", -1)) == 0xEB9E \
			and String(event_boundary.get("scenario_active_stop_boundary", "")) == "$EC74 RTS->$EB9E",
		"slot-$09 returns from the first scenario event at `$EC74->$EB9E`")
	var mapper: Dictionary = event_boundary.get("mapper", {})
	_check(int(mapper.get("bank_low", -1)) == 0x10 and int(mapper.get("bank_high", -1)) == 0x11,
		"the bank-$10/$11 scenario reader mapping survives the return")
	_check(scenario_events.size() == 3 and event_record.get("source_bytes", PackedByteArray()) \
			== PackedByteArray([0x10, 0x3A, 0x8F, 0xF0]) \
			and int(event_record.get("source_pointer", -1)) == 0xB7E8,
		"scenario `$36` first event is decoded at stream offset +4 from ROM pointer `$B7E4`")
	_check(int(seed.get("scenario_id", -1)) == 0x36 \
			and int(seed.get("wait_value_ram_0523", -1)) == 0x10 \
			and int(seed.get("event_selector_ram_0524", -1)) == 0x3A \
			and int(seed.get("actor_selector_ram_0528", -1)) == 0x8F \
			and int(seed.get("actor_parameter_ram_0529", -1)) == 0xFF \
			and int(seed.get("task_slot_base", -1)) == 0x15,
		"the transformed event produces the source-derived `$10/$3A/$8F/$FF` callback contract")
	_check(event_ram.size() == 0x800 and int(event_ram[0x0516]) == 0x41 \
			and int(event_ram[0x0518]) == 0x36 \
			and event_ram.slice(0x0523, 0x052A) == PackedByteArray([0x10, 0x3A, 0x02, 0x3C, 0x2C, 0x8F, 0xFF]),
		"ordered scenario and event writes update live RAM through the return boundary")
	_check(slot15_seed.get("record", PackedByteArray()) == PackedByteArray([0xFF, 0xF0, 0x0B, 0x12]) \
			and event_ram.size() == 0x800 and int(event_ram[0x0018]) == 0x12 \
			and event_stack.size() == 0x100 and int(event_stack[0xF1]) == 0x08 \
			and int(event_stack[0xF2]) == 0x80,
		"callback task is seeded from ROM bytes while preserving its live high-bank byte")
	_check(bool(post_event.get("ok", false)) \
			and String(post_event.get("status", "")) == "scenario36_event_returned_to_worker_vector" \
			and int(post_event.get("entry_pc", -1)) == 0xEB9E \
			and int(post_event.get("exit_pc", -1)) == 0x86F8,
		"scenario caller reaches `$86F8` before callback dispatch")
	_check(bool(callback_chain.get("ok", false)) \
			and String(callback_chain.get("status", "")) == "slot15_map_worker_yielded_waiting_nmi" \
			and int(callback_entry.get("exit_pc", -1)) == 0x814C \
			and int(callback_handler.get("exit_pc", -1)) == 0x8327 \
			and int(callback_handler.get("scenario", -1)) == 0x36 \
			and callback_handler.get("callback_bytes", PackedByteArray()) == PackedByteArray([0x02, 0x00, 0x42]) \
			and int(map_worker_entry.get("exit_pc", -1)) == 0x8525 \
			and int(map_worker_setup.get("exit_pc", -1)) == 0x856F,
		"ROM callback `$3A` reaches `$8327->$8525->$856F` without capture-derived state")
	_check(not bool(event_boundary.get("trace_state_used", true)) \
			and not bool(post_event.get("trace_state_used", true)) \
			and not bool(callback_chain.get("trace_state_used", true)) \
			and int(status.get("selected_action_id", -2)) == -1 \
			and not bool(status.get("continue_entered", false)),
		"no trace-state injection, soccer action, or Continue flow is used")
	var first_batch_task: Dictionary = map_batch_snapshots.get(0, {})
	var map_batch: Dictionary = first_batch_task.get("map_batch_result", {})
	var queue_bytes: PackedByteArray = map_batch.get("queue_bytes", PackedByteArray())
	var map_calls: Array = map_batch.get("map_calls", [])
	var calls_are_first_block: bool = map_calls.size() == 3
	for call_variant in map_calls:
		var map_call: Dictionary = call_variant
		calls_are_first_block = calls_are_first_block and int(map_call.get("block_id", -1)) == 0x14
	_check(bool(first_batch_task.get("ok", false)) \
			and String(first_batch_task.get("status", "")) == "slot15_map42_batch_yielded" \
			and int(map_batch.get("entry_pc", -1)) == 0x8572 \
			and int(map_batch.get("callsite_pc", -1)) == 0x856F \
			and int(map_batch.get("batch_start_map_index", -1)) == 0 \
			and int(map_batch.get("batch_start_placement", -1)) == 0xA0 \
			and int(map_batch.get("row_count_remaining", -1)) == 0x1D \
			and int(map_batch.get("next_map_index", -1)) == 3 \
			and queue_bytes.size() == 0x60 and calls_are_first_block,
		"live `$8572` derives three `$14` cells into the 96-byte `$A0` map batch")
	var all_batches_match := true
	for map_index in [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30]:
		var batch_task: Dictionary = map_batch_snapshots.get(map_index, {})
		var batch_result: Dictionary = batch_task.get("map_batch_result", {})
		var batch_queue: PackedByteArray = batch_result.get("queue_bytes", PackedByteArray())
		var batch_calls: Array = batch_result.get("map_calls", [])
		var trace_frame := FIRST_BATCH_FRAME + int(map_index / 3)
		var expected_cells := 2 if map_index == 30 else 3
		var expected_queue_size := 0x24 if map_index == 30 else (0x36 if map_index in [24, 27] else 0x60)
		var expected_output_y := 0x17 if map_index == 30 else (0x29 if map_index in [24, 27] else 0x10)
		var expected_callsite := 0x85BE if map_index == 30 else 0x856F
		var expected_stack_pointer := 0xEE if map_index == 30 else 0xED
		var row_wrap_calls_match := true
		if map_index in [24, 27, 30]:
			for call_variant in batch_calls:
				var map_call: Dictionary = call_variant
				row_wrap_calls_match = row_wrap_calls_match \
						and bool(map_call.get("row_wrap_compaction", false)) \
						and int(map_call.get("queue_advance_bytes", -1)) == 0x12
		all_batches_match = all_batches_match \
				and bool(batch_task.get("ok", false)) \
				and String(batch_task.get("status", "")) == "slot15_map42_batch_yielded" \
				and int(batch_result.get("entry_pc", -1)) == 0x8572 \
				and int(batch_result.get("callsite_pc", -1)) == expected_callsite \
				and int(batch_result.get("batch_start_map_index", -1)) == map_index \
				and int(batch_result.get("batch_start_placement", -1)) == 0xA0 + map_index \
				and int(batch_result.get("batch_cell_count", -1)) == expected_cells \
				and int(batch_result.get("row_count_remaining", -1)) == 0x20 - map_index - expected_cells \
				and int(batch_result.get("next_map_index", -1)) == map_index + expected_cells \
				and batch_queue.size() == expected_queue_size and batch_calls.size() == expected_cells \
				and int(batch_result.get("registers", {}).get("x", -1)) == expected_queue_size \
				and int(batch_result.get("registers", {}).get("y", -1)) == expected_output_y \
				and int(batch_result.get("registers", {}).get("sp", -1)) == expected_stack_pointer \
				and row_wrap_calls_match \
				and _fceux_map_batch_signature_matches(trace_frame)
	_check(all_batches_match,
		"all eleven map-$42 batches match same-input FCEUX queue-yield registers and row-exhaustion boundary")
	var exact_queue_matches := true
	for map_index in [24, 27, 30]:
		var batch_task: Dictionary = map_batch_snapshots.get(map_index, {})
		var batch_result: Dictionary = batch_task.get("map_batch_result", {})
		var frame_queue_match := _fceux_queue_bytes_match(
			FIRST_BATCH_FRAME + int(map_index / 3), batch_result)
		exact_queue_matches = frame_queue_match and exact_queue_matches
	_check(exact_queue_matches,
		"row-wrap and terminal queue payloads match exact same-input FCEUX frame-end RAM bytes")
	var terminal_task := terminal_task_snapshot
	var terminal_return: Dictionary = terminal_task.get("terminal_return_result", {})
	_check(String(terminal_task.get("status", "")) == "slot15_map42_terminal_callback_finished_waiting_nmi" \
			and String(terminal_return.get("status", "")) == "slot15_map42_terminal_return_reached_CAF7" \
			and int(terminal_return.get("exit_pc", -1)) == 0xCAF7 \
			and int(terminal_return.get("callback_return_pc", -1)) == 0x819C \
			and String(terminal_route_snapshot.get("phase", "")) == "awaiting_external_nmi",
		"exhausted map-$42 callback returns through `$819C->$CAF7` and finishes slot `$15`")
	var terminal_ram_check := _fceux_terminal_return_ram_matches(TERMINAL_FRAME, terminal_task)
	if not bool(terminal_ram_check.get("ok", false)):
		print("Terminal FCEUX RAM comparison: " + String(terminal_ram_check.get("error", "unknown mismatch")))
	_check(bool(terminal_ram_check.get("ok", false)),
		"terminal callback and finished slot-$15 RAM match same-input FCEUX frame %d" % TERMINAL_FRAME)
	var terminal_nmi: Dictionary = terminal_nmi_snapshot
	var normal_nmi: Dictionary = terminal_nmi.get("normal_nmi_result", {})
	var secondary_queue: Dictionary = normal_nmi.get("secondary_queue", {})
	var nmi_bus_events: Array = normal_nmi.get("ppu_bus_events", [])
	if String(source_route.get("phase", "")) == "error":
		var selected_boundary: Dictionary = nmi.get("selected_task_boundary", {})
		var selected_ram: PackedByteArray = selected_boundary.get("ram_image", PackedByteArray())
		print("Frame-%d selected slot boundary: slot=$%02X PC=$%04X A/X/Y/SP=$%02X/$%02X/$%02X/$%02X banks=$%02X/$%02X record=%s map=$%02X/%02X/%02X queue=$%02X ready=$%02X" % [
			STOP_FRAME, int(selected_boundary.get("slot_base", -1)), int(selected_boundary.get("pc", -1)),
			int(selected_boundary.get("a", -1)), int(selected_boundary.get("x", -1)),
			int(selected_boundary.get("y", -1)), int(selected_boundary.get("sp", -1)),
			int(selected_boundary.get("bank_low", -1)), int(selected_boundary.get("bank_high", -1)),
			selected_boundary.get("record", PackedByteArray()).hex_encode(),
			int(selected_ram[0x05C7]) if selected_ram.size() == 0x800 else -1,
			int(selected_ram[0x05C8]) if selected_ram.size() == 0x800 else -1,
			int(selected_ram[0x05C9]) if selected_ram.size() == 0x800 else -1,
			int(selected_ram[0x05C7]) if selected_ram.size() == 0x800 else -1,
			int(selected_ram[0x0515]) if selected_ram.size() == 0x800 else -1])
	_check(bool(nmi.get("ok", false)) and bool(nmi.get("external_nmi_consumed", false)) \
			and bool(secondary_queue.get("transfer_performed", false)) \
			and int(secondary_queue.get("ready_flag_before", -1)) == 0x80 \
			and int(secondary_queue.get("ready_flag_after", -1)) == 0 \
			and not nmi_bus_events.is_empty(),
		"frame-%d normal NMI consumes the terminal ROM-derived map queue into ordered PPU bus events" % TERMINAL_FRAME)
	var slot11_trace_check := _fceux_slot11_animation_countdown_matches(
		STOP_FRAME, slot11_worker, slot11_saved_boundary)
	if not bool(slot11_trace_check.get("ok", false)):
		print("Slot-$11 FCEUX comparison: " + String(slot11_trace_check.get("error", "unknown mismatch")))
	_check(String(source_route.get("phase", "")) == "awaiting_external_nmi" \
			and String(source_route.get("source_boundary", "")).contains("$8047->$C515->$CB0F slot-$11 actor yield") \
			and String(source_task.get("status", "")) == "slot11_f5_animation_countdown_saved_and_scanned" \
			and bool(slot11_trace_check.get("ok", false)),
		"slot-$11 animation countdown, `$8047->$C515->$CB0F` task save, and same-input FCEUX registers/stack/state match at frame %d" % STOP_FRAME)
	if _failures == 0:
		print("PASS: same-input scenario `$36` route builds all 32 map-$42 cells, returns through the terminal callback, and matches slot-$11 actor-countdown trace state by frame %d." % STOP_FRAME)
		print("PASS: row-wrap and terminal queue payloads also match the three same-input FCEUX RAM snapshots byte-for-byte.")
		print("PASS: 24 selected callback, slot, and mapper RAM bytes match same-input FCEUX frame %d." % TERMINAL_FRAME)
		print("LIMIT: full 2 KB RAM parity remains open; slot-$01 saved bank high at `$0003` differs (`$00` Godot, `$16` FCEUX).")
		print("LIMIT: applying bus writes to rendered pixels, command menu, audio parity, and ROM-free runtime remain open.")
	else:
		printerr("FAIL: %d scenario-$36 route assertion(s)" % _failures)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
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
		if source_frame > 4693 and not changes.is_empty():
			result[source_frame] = changes
		previous = current
	return result


func _fceux_map_batch_signature_matches(source_frame: int) -> bool:
	var expected_x := 0x60
	var expected_y := 0x10
	if source_frame in [8602, 8603]:
		expected_x = 0x36
		expected_y = 0x29
	elif source_frame == 8604:
		expected_x = 0x24
		expected_y = 0x17
	for trace_path in [FCEUX_EVENTS_CSV, FCEUX_REPEAT_EVENTS_CSV]:
		var file := FileAccess.open(trace_path, FileAccess.READ)
		if file == null:
			return false
		file.get_csv_line()
		var queue_events := 0
		var yielded_events := 0
		while not file.eof_reached():
			var row := file.get_csv_line()
			if row.size() < 24 or int(row[2]) != source_frame:
				continue
			if row[6] == "event_queue_helper_C515" and row[7] == "C515" \
					and row[9] == "01" and row[10] == "%02X" % expected_x \
					and row[11] == "%02X" % expected_y \
					and row[22] == "80" and row[23] == "0B/12/1E/1F":
				queue_events += 1
			if row[6] == "task_yield_CB0F" and row[7] == "CB0F" \
					and row[9] == "01" and row[10] == "%02X" % expected_x \
					and row[11] == "%02X" % expected_y \
					and row[22] == "80" and row[23] == "0B/12/1E/1F":
				yielded_events += 1
		if queue_events != 1 or yielded_events != 1:
			return false
	return true


func _fceux_queue_bytes_match(source_frame: int, batch_result: Dictionary) -> bool:
	var path := FCEUX_RAM_ROOT.path_join("route_frame_%06d.bin" % source_frame)
	var ram := FileAccess.get_file_as_bytes(path)
	var queue: PackedByteArray = batch_result.get("queue_bytes", PackedByteArray())
	if ram.size() != 0x800 or queue.is_empty():
		print("Queue evidence unavailable frame %d: path=%s RAM size=%d Godot queue size=%d." % [
			source_frame, path, ram.size(), queue.size()])
		return false
	var queue_length := int(ram[0x05C7])
	var expected := ram.slice(0x04A5, 0x04A5 + queue_length)
	var terminator_address := 0x04A5 + queue_length
	var matches := queue_length == queue.size() and expected == queue \
			and int(ram[terminator_address]) == 0 \
			and int(batch_result.get("queue_terminator_address", -1)) == terminator_address
	if not matches:
		var first_difference := -1
		for byte_index in mini(queue.size(), expected.size()):
			if queue[byte_index] != expected[byte_index]:
				first_difference = byte_index
				break
		print("Queue mismatch frame %d: RAM len=%d Godot len=%d terminator=$%02X expected_address=$%04X batch_address=$%04X first_diff=%d RAM[%d]=$%02X Godot[%d]=$%02X." % [
			source_frame, queue_length, queue.size(),
			int(ram[terminator_address]), terminator_address,
			int(batch_result.get("queue_terminator_address", -1)),
			first_difference, first_difference,
			int(expected[first_difference]) if first_difference >= 0 else -1,
			first_difference, int(queue[first_difference]) if first_difference >= 0 else -1])
		print("Queue prefix RAM=%s Godot=%s" % [
			expected.slice(0, mini(24, expected.size())).hex_encode(),
			queue.slice(0, mini(24, queue.size())).hex_encode()])
		var calls: Array = batch_result.get("map_calls", [])
		if not calls.is_empty():
			print("Queue first call placement=$%02X PPU=$%04X." % [
				int(calls[0].get("placement", -1)), int(calls[0].get("ppu_address", -1))])
	return matches


func _fceux_terminal_return_ram_matches(source_frame: int, terminal_task: Dictionary) -> Dictionary:
	var path := FCEUX_RAM_ROOT.path_join("route_frame_%06d.bin" % source_frame)
	var fceux_ram := FileAccess.get_file_as_bytes(path)
	var finished_boundary: Dictionary = terminal_task.get("finished_slot_boundary", {})
	var godot_ram_variant: Variant = finished_boundary.get("ram_image", PackedByteArray())
	if fceux_ram.size() != 0x800 or not godot_ram_variant is PackedByteArray:
		return {"ok": false, "error": "one of the 2 KB frame-$%04d RAM images is missing" % source_frame}
	var godot_ram: PackedByteArray = godot_ram_variant
	if godot_ram.size() != 0x800:
		return {"ok": false, "error": "Godot terminal result does not include its full RAM image"}
	var addresses: Array[int] = [0x0000, 0x0019, 0x001B, 0x0020, 0x0024, 0x0025,
		0x0015, 0x0016, 0x0017, 0x0018,
		0x0515, 0x0516, 0x0518, 0x05C7, 0x05C8, 0x05C9, 0x05CA, 0x05CB,
		0x05CC, 0x05CD, 0x05CE, 0x05DB, 0x05DC, 0x05DD]
	for address in addresses:
		if int(godot_ram[address]) != int(fceux_ram[address]):
			return {"ok": false, "error": "$%04X Godot=$%02X FCEUX=$%02X" % [
				address, int(godot_ram[address]), int(fceux_ram[address])]}
	return {"ok": true, "matched_bytes": addresses.size(), "frame": source_frame}


func _fceux_slot11_animation_countdown_matches(source_frame: int,
		worker: Dictionary, saved_boundary: Dictionary) -> Dictionary:
	var ram_path := FCEUX_RAM_ROOT.path_join("route_frame_%06d.bin" % source_frame)
	var fceux_ram := FileAccess.get_file_as_bytes(ram_path)
	var worker_entry: Dictionary = worker.get("entry_registers", {})
	var worker_callsite: Dictionary = worker.get("yield_callsite_registers", {})
	var entry_stack: PackedByteArray = worker.get("entry_stack_page", PackedByteArray())
	var callsite_stack: PackedByteArray = worker.get("yield_callsite_stack_page", PackedByteArray())
	var worker_entry_ram: PackedByteArray = worker.get("entry_ram_image", PackedByteArray())
	var worker_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var saved_ram: PackedByteArray = saved_boundary.get("ram_image", PackedByteArray())
	var expected_record := PackedByteArray([0x01, 0xC6, 0x18, 0x19])
	if fceux_ram.size() != 0x800 or String(worker.get("status", "")) != "slot11_f5_animation_countdown_at_8047" \
			or int(worker.get("entry_pc", -1)) != 0x804A \
			or int(worker.get("exit_pc", -1)) != 0x8047 \
			or int(worker.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(worker.get("yield_target_pc", -1)) != 0xCB0F \
			or entry_stack.size() != 0x100 or callsite_stack.size() != 0x100 \
			or worker_entry_ram.size() != 0x800 or worker_ram.size() != 0x800 or saved_ram.size() != 0x800:
		return {"ok": false, "error": "the live slot-$11 countdown result or frame-$%06d FCEUX evidence is incomplete" % source_frame}
	if fceux_ram.slice(0x0011, 0x0015) != expected_record \
			or saved_boundary.get("record", PackedByteArray()) != expected_record:
		return {"ok": false, "error": "slot-$11 frame-end task record differs: FCEUX=%s Godot=%s" % [
			fceux_ram.slice(0x0011, 0x0015).hex_encode(),
			saved_boundary.get("record", PackedByteArray()).hex_encode()]}
	for trace_path in [FCEUX_EVENTS_CSV, FCEUX_REPEAT_EVENTS_CSV]:
		var trace := FileAccess.open(trace_path, FileAccess.READ)
		if trace == null:
			return {"ok": false, "error": "missing slot-$11 event trace %s" % trace_path}
		trace.get_csv_line()
		var events: Dictionary = {}
		while not trace.eof_reached():
			var row := trace.get_csv_line()
			if row.size() < 19 or int(row[2]) != source_frame:
				continue
			if row[6] in ["actor_resume_804A", "actor_yield_8047", "event_queue_helper_C515", "task_yield_CB0F"]:
				events[String(row[6])] = row
		for kind in ["actor_resume_804A", "actor_yield_8047", "event_queue_helper_C515", "task_yield_CB0F"]:
			if not events.has(kind):
				return {"ok": false, "error": "frame-%d trace %s omits %s" % [source_frame, trace_path, kind]}
		var resume_row: Array = events["actor_resume_804A"]
		var actor_yield_row: Array = events["actor_yield_8047"]
		var queue_row: Array = events["event_queue_helper_C515"]
		var task_yield_row: Array = events["task_yield_CB0F"]
		if not _trace_registers_match(worker_entry, resume_row):
			return {"ok": false, "error": "frame-%d %s `$804A` registers differ: Godot=%s FCEUX=%s" % [
				source_frame, trace_path, str(worker_entry), _trace_register_summary(resume_row)]}
		if not _trace_registers_match(worker_callsite, actor_yield_row):
			return {"ok": false, "error": "frame-%d %s `$8047` registers differ: Godot=%s FCEUX=%s" % [
				source_frame, trace_path, str(worker_callsite), _trace_register_summary(actor_yield_row)]}
		if not _trace_registers_match({"pc": 0xC515, "a": 0x01, "x": 0x24, "y": 0x02, "p": 0x30, "sp": 0xC8}, queue_row):
			return {"ok": false, "error": "frame-%d %s FCEUX `$C515` queue-helper contract changed: %s" % [
				source_frame, trace_path, _trace_register_summary(queue_row)]}
		if not _trace_registers_match({"pc": 0xCB0F, "a": 0x01, "x": 0x24, "y": 0x02, "p": 0x30, "sp": 0xC8}, task_yield_row):
			return {"ok": false, "error": "frame-%d %s FCEUX `$CB0F` task-yield contract changed: %s" % [
				source_frame, trace_path, _trace_register_summary(task_yield_row)]}
		if entry_stack.slice(0xC7, 0xCB).hex_encode() != String(resume_row[15]).to_lower().substr(14, 8) \
				or callsite_stack.slice(0xC7, 0xCB).hex_encode() != String(actor_yield_row[15]).to_lower().substr(14, 8):
			return {"ok": false, "error": "frame-%d %s active actor stack words differ: Godot entry/callsite=%s/%s FCEUX=%s/%s" % [
				source_frame, trace_path, entry_stack.slice(0xC7, 0xCB).hex_encode(),
				callsite_stack.slice(0xC7, 0xCB).hex_encode(),
				String(resume_row[15]).to_lower().substr(14, 8),
				String(actor_yield_row[15]).to_lower().substr(14, 8)]}
		if int(worker_ram[0x05E4]) != _csv_hex(String(actor_yield_row[16]).substr(0, 2)) \
				or int(worker_ram[0x05E5]) != _csv_hex(String(actor_yield_row[16]).substr(2, 2)) \
				or int(worker_ram[0x05E9]) != _csv_hex(String(actor_yield_row[17])) \
				or worker_ram.slice(0x05F3, 0x05F6).hex_encode() != String(actor_yield_row[18]).to_lower():
			return {"ok": false, "error": "frame-%d %s animation counters differ at `$8047`: Godot E4/E5/E9/F3-F5=%02X/%02X/%02X/%s FCEUX=%s/%s/%s/%s" % [
				source_frame, trace_path, int(worker_ram[0x05E4]), int(worker_ram[0x05E5]),
				int(worker_ram[0x05E9]), worker_ram.slice(0x05F3, 0x05F6).hex_encode(),
				String(actor_yield_row[16]).substr(0, 2), String(actor_yield_row[16]).substr(2, 2),
				String(actor_yield_row[17]), String(actor_yield_row[18])]}
		if int(resume_row[0]) >= int(actor_yield_row[0]) \
				or int(actor_yield_row[0]) >= int(queue_row[0]) \
				or int(queue_row[0]) >= int(task_yield_row[0]):
			return {"ok": false, "error": "frame-%d %s actor events are out of ROM execution order" % [source_frame, trace_path]}
	var state_addresses: Array[int] = [0x0000, 0x0010, 0x0011, 0x0012, 0x0013, 0x0014,
		0x001B, 0x0024, 0x0025, 0x0515, 0x05E3, 0x05E4, 0x05E5, 0x05E9,
		0x05F3, 0x05F4, 0x05F5]
	for address in state_addresses:
		if int(saved_ram[address]) != int(fceux_ram[address]):
			return {"ok": false, "error": "frame-%d slot-$11 RAM differs at $%04X: Godot=$%02X FCEUX=$%02X (worker entry `$05E9=$%02X`, post-countdown `$05E9=$%02X`)" % [
				source_frame, address, int(saved_ram[address]), int(fceux_ram[address]),
				int(worker_entry_ram[0x05E9]), int(worker_ram[0x05E9])]}
	return {"ok": true, "matched_frame_end_bytes": state_addresses.size(), "matched_trace_passes": 2}


func _trace_registers_match(registers: Dictionary, row: Array) -> bool:
	var known_status_mask := int(registers.get("p_known_mask", 0xEF))
	return int(registers.get("pc", -1)) == _csv_hex(String(row[7])) \
			and int(registers.get("a", -1)) == _csv_hex(String(row[9])) \
			and int(registers.get("x", -1)) == _csv_hex(String(row[10])) \
			and int(registers.get("y", -1)) == _csv_hex(String(row[11])) \
			and ((int(registers.get("p", -1)) ^ _csv_hex(String(row[12]))) & known_status_mask) == 0 \
			and int(registers.get("sp", -1)) == _csv_hex(String(row[13]))


func _trace_register_summary(row: Array) -> String:
	return "PC=$%s A/X/Y/P/SP=$%s/$%s/$%s/$%s/$%s" % [
		String(row[7]), String(row[9]), String(row[10]), String(row[11]),
		String(row[12]), String(row[13])]


func _csv_hex(value: String) -> int:
	return value.hex_to_int()


func _first_fceux_slot11_countdown_mismatch(godot_frames: Dictionary) -> Dictionary:
	var first_mismatch: Dictionary = {}
	var first_mismatch_frame := 0x7FFFFFFF
	for trace_path in [FCEUX_EVENTS_CSV, FCEUX_REPEAT_EVENTS_CSV]:
		var trace := FileAccess.open(trace_path, FileAccess.READ)
		if trace == null:
			continue
		trace.get_csv_line()
		while not trace.eof_reached():
			var row := trace.get_csv_line()
			if row.size() < 19 or row[6] != "actor_yield_8047":
				continue
			var frame := int(row[2])
			if frame < 8480 or frame > STOP_FRAME or frame >= first_mismatch_frame \
					or not godot_frames.has(frame):
				continue
			var live: Dictionary = godot_frames[frame]
			var expected_stream := String(row[16])
			var expected_animation := String(row[18]).to_lower()
			if int(live["e4"]) != _csv_hex(expected_stream.substr(0, 2)) \
					or int(live["e5"]) != _csv_hex(expected_stream.substr(2, 2)) \
					or int(live["e9"]) != _csv_hex(String(row[17])) \
					or PackedByteArray([int(live["f3"]), int(live["f4"]), int(live["f5"])]).hex_encode() != expected_animation:
				first_mismatch_frame = frame
				first_mismatch = {
					"frame": frame,
					"trace": trace_path,
					"godot_stream": "%02X%02X" % [int(live["e4"]), int(live["e5"])],
					"fceux_stream": expected_stream,
					"godot_delay": "%02X" % int(live["e9"]),
					"fceux_delay": String(row[17]),
					"godot_animation": PackedByteArray([int(live["f3"]), int(live["f4"]), int(live["f5"])]).hex_encode(),
					"fceux_animation": expected_animation,
				}
	return first_mismatch


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
			"Start": continue
			_: continue
		var event := InputEventKey.new()
		event.keycode = key_code
		event.pressed = bool(change.get("pressed", false))
		route.call("_unhandled_input", event)
		if String(route.get_route_status().get("stage", "")) == "meeting_menu" \
				and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


