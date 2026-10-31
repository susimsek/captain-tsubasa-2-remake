extends SceneTree
## Replays the captured post-title controller edges through the Godot route.
## Capture files are observations only; the harness does not inject captured
## player, RAM, PPU, or audio state into the runtime path.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const POSITION_RAM_ORACLE := "res://reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008593.bin"
const OUTPUT_PNG := "/tmp/ct2_godot_first_action_menu_recorded_input.png"

var _failures := 0
var _stage_at_checkpoints: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	route.set_process(false)
	route.source_frame = 4693

	var events := _read_recorded_edges()
	_check(not events.is_empty(), "captured route input edges load")
	var expect_scenario36_boundary := OS.get_environment("CT2_ROUTE_EXPECT_SCENARIO36").strip_edges() == "1" \
		or OS.get_environment("CT2_ROUTE_EXPECT_DB0E").strip_edges() == "1" \
		or OS.get_environment("CT2_ROUTE_EXPECT_E6EC").strip_edges() == "1"
	var stop_frame := -1
	var stop_route_status: Dictionary = {}
	var stopped_at_handoff_gap := false
	var stopped_at_preset_wait := false
	var configured_final_frame := OS.get_environment("CT2_ROUTE_FINAL_FRAME").strip_edges()
	var default_final_frame := 8593 if expect_scenario36_boundary else 9042
	var final_frame := int(configured_final_frame) if not configured_final_frame.is_empty() else default_final_frame
	var final_slot05: Dictionary = {}
	for source_frame in range(4694, final_frame + 1):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		route.call("_advance_route_source_tick")
		if source_frame in [7243, 7393, 7993, 8443, 8464, 8593, 8594, 8943, 8953, final_frame]:
			var checkpoint := route.get_route_status()
			var checkpoint_gaps: Array = checkpoint.get("route_gaps", [])
			var source_route: Dictionary = checkpoint.get("fresh_source_route", {})
			var scheduler: Dictionary = source_route.get("scheduler", {})
			var nmi_result: Dictionary = checkpoint.get("fresh_source_route_nmi", {})
			_stage_at_checkpoints[source_frame] = {
				"stage": checkpoint.get("stage", ""),
				"meeting_cursor_y": checkpoint.get("meeting_cursor_y", -1),
				"first_action_menu_source_pending": checkpoint.get("first_action_menu_source_pending", false),
				"last_route_gap": String(checkpoint_gaps.back()) if not checkpoint_gaps.is_empty() else "",
				"pending_source_pc": checkpoint.get("cutscene_wait_cleanup", {}).get("pending_source_pc", -1),
				"pending_helper_id": checkpoint.get("cutscene_wait_cleanup", {}).get("pending_helper_id", ""),
				"source_route_phase": source_route.get("phase", ""),
				"source_boundary": source_route.get("source_boundary", ""),
				"source_task_status": checkpoint.get("fresh_source_route_task", {}).get("status", ""),
				"last_external_nmi_frame": source_route.get("last_external_nmi_frame", -1),
				"nmi_result_status": nmi_result.get("status", ""),
				"nmi_ready_latch": scheduler.get("scheduler_ready_latch_001b", -1),
				"active_task_slot": scheduler.get("active_task_slot", -1),
				"controller_sample": scheduler.get("controller_sample", {}),
				"task_slots": scheduler.get("task_slots", []),
			}
			if String(source_route.get("phase", "")) in ["error", "stopped_before_scenario36_slot09_dispatch"] \
					and route._fresh_source_route_runner != null:
				var scheduler_status: Dictionary = source_route.get("scheduler", {})
				var active_slot := int(scheduler_status.get("active_task_slot", -1))
				var active_task: Dictionary = route._fresh_source_route_runner._scheduler.get_task_boundary_snapshot(active_slot)
				var source_ram: PackedByteArray = active_task.get("ram_image", PackedByteArray())
				if source_ram.size() == 0x800:
					_stage_at_checkpoints[source_frame]["active_task_live_inputs"] = {
						"slot": active_slot,
						"pc": active_task.get("pc", -1), "sp": active_task.get("sp", -1),
					"ram_001c_001e": source_ram.slice(0x001C, 0x001F).hex_encode(),
					"ram_0441": source_ram[0x0441],
						"record": (active_task.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
						"scenario_flags_0516_0519": source_ram.slice(0x0516, 0x051A).hex_encode(),
					"scenario_ptr_005d_005e": source_ram.slice(0x005D, 0x005F).hex_encode(),
					"scenario_cursor_003a": source_ram[0x003A],
					"scenario_continuation_051a_0522": source_ram.slice(0x051A, 0x0523).hex_encode(),
						"scenario_fields_0523_052A": source_ram.slice(0x0523, 0x052B).hex_encode(),
					"scenario_fields_052B_0539": source_ram.slice(0x052B, 0x053A).hex_encode(),
					"scenario_reader_0052_005e": source_ram.slice(0x0052, 0x005F).hex_encode(),
						"scenario_flags_053A_053D": source_ram.slice(0x053A, 0x053E).hex_encode(),
						"actor_order_0543_0545": source_ram.slice(0x0543, 0x0546).hex_encode(),
						"active_slot": source_ram[0x0000],
					}
		if events.has(source_frame):
			# The live route schedules the kickoff script with call_deferred after
			# confirming the meeting menu; yield at real input edges so the test
			# observes the same scene-tree boundary.
			await process_frame
		var route_status_now := route.get_route_status()
		var source_route_now: Dictionary = route_status_now.get("fresh_source_route", {})
		var handoff_now: Dictionary = route_status_now.get("cutscene_wait_cleanup", {})
		if String(source_route_now.get("phase", "")) == "error" \
				or String(route_status_now.get("stage", "")) == "source_route_gap" \
				or bool(route_status_now.get("first_action_menu_complete", false)):
			stop_frame = source_frame
			stop_route_status = route_status_now
			break
		if String(route_status_now.get("stage", "")) == "match_setup_gap" \
				and String(handoff_now.get("pending_helper_id", "")) == "cutscene_cleanup_9ba0":
			stop_frame = source_frame
			stop_route_status = route_status_now
			stopped_at_handoff_gap = true
			break
		if String(route_status_now.get("stage", "")) == "match_setup_gap" \
				and String(handoff_now.get("pending_helper_id", "")) == "fresh_match_preset_wait_0078" \
				and int(handoff_now.get("pending_source_pc", -1)) == 0x893B:
			stop_frame = source_frame
			stop_route_status = route_status_now
			stopped_at_preset_wait = true
			break

	if stop_frame < 0:
		stop_frame = route.source_frame
		stop_route_status = route.get_route_status()
	var reached_menu := bool(stop_route_status.get("first_action_menu_complete", false))
	var final_handoff: Dictionary = stop_route_status.get("cutscene_wait_cleanup", {})
	var stop_source_route: Dictionary = stop_route_status.get("fresh_source_route", {})
	var stopped_before_scenario36_slot09 := String(stop_source_route.get("phase", "")) \
		== "stopped_before_scenario36_slot09_dispatch"
	var stopped_at_scenario36_yield := String(stop_route_status.get("fresh_source_route_task", {}).get("status", "")) \
		== "scenario36_queued_slot05_yielded_and_scheduler_scanned"
	var reached_scenario36_boundary := stopped_before_scenario36_slot09 and stopped_at_scenario36_yield
	var sparse_ram: Dictionary = stop_route_status.get("source_ram_image_at_893b", {})
	var known_ram_values: Dictionary = sparse_ram.get("known_values", {})
	var wait_ram_state: Dictionary = {}
	for address in [0x001B, 0x0078, 0x0079, 0x003B]:
		var address_key := "0x%04X" % address
		wait_ram_state[address_key] = known_ram_values.get(address, "unknown")
	print("Recorded route stop: frame=%d stage=%s phase=%s boundary=%s error=%s handoff=%s@%s" % [
		stop_frame, String(stop_route_status.get("stage", "")),
		String(stop_source_route.get("phase", "")),
		String(stop_source_route.get("source_boundary", "")),
		String(stop_source_route.get("error", "")),
		String(final_handoff.get("pending_helper_id", "")),
		String.num_int64(int(final_handoff.get("pending_source_pc", -1)), 16),
	])
	print("Sparse source RAM at wait boundary: %d/%d bytes known; `$001B/$0078/$0079/$003B`=%s" % [
		int(sparse_ram.get("known_byte_count", 0)), int(sparse_ram.get("ram_size", 0)),
		JSON.stringify(wait_ram_state),
	])
	if route._fresh_source_route_runner != null:
		var scheduler: Variant = route._fresh_source_route_runner._scheduler
		var slot11: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
		var ram: PackedByteArray = slot11.get("ram_image", PackedByteArray())
		var stack: PackedByteArray = slot11.get("stack_page", PackedByteArray())
		var slot11_state := {
			"record": (slot11.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
			"pc": slot11.get("pc", -1), "sp": slot11.get("sp", -1),
			"phase": slot11.get("phase", -1), "pending_resume": slot11.get("pending_resume", -1),
			"ready_delay": slot11.get("ready_delay", -1), "x": slot11.get("x", -1), "y": slot11.get("y", -1),
		}
		if ram.size() == 0x800:
			slot11_state["ram_046c_0498"] = ram.slice(0x046C, 0x0498).hex_encode()
			slot11_state["ram_0498_04a5"] = ram.slice(0x0498, 0x04A5).hex_encode()
			slot11_state["ram_0515_0519"] = ram.slice(0x0515, 0x051A).hex_encode()
			slot11_state["ram_04a5_04c9"] = ram.slice(0x04A5, 0x04C9).hex_encode()
			slot11_state["ram_05e3_05ea"] = ram.slice(0x05E3, 0x05EA).hex_encode()
			slot11_state["ram_005f_0061"] = ram.slice(0x005F, 0x0061).hex_encode()
		if stack.size() == 0x100:
			slot11_state["stack_C0_D0"] = stack.slice(0xC0, 0xD1).hex_encode()
		var nmi_result: Dictionary = stop_route_status.get("fresh_source_route_nmi", {}).get("nmi_result", {})
		slot11_state["last_nmi_secondary_queue"] = nmi_result.get("secondary_queue", {})
		slot11_state["last_nmi_bus_event_count"] = (nmi_result.get("ppu_bus_events", []) as Array).size()
		print("Slot-$11 diagnostic snapshot at source frame %d: %s" % [stop_frame, JSON.stringify(slot11_state)])
		if reached_scenario36_boundary:
			final_slot05 = scheduler.get_task_boundary_snapshot(0x05)
			var slot05_ram: PackedByteArray = final_slot05.get("ram_image", PackedByteArray())
			print("Slot-$05 after scenario `$36` yield at source frame %d: pc=$%04X sp=$%02X input=$%02X/$%02X RNG=$%02X/$%02X/$%02X holder=$%02X receiver=$%02X coordinates=$%02X/$%02X index=$%02X positions=%d" % [
				stop_frame, int(final_slot05.get("pc", -1)), int(final_slot05.get("sp", -1)),
				int(slot05_ram[0x001C]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x001E]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x00E1]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x00E2]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x00E3]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x0441]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x05FC]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x0635]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x0637]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x05FE]) if slot05_ram.size() == 0x800 else -1,
				route.get_route_status().get("initial_player_positions", []).size(),
			])
	_check(route.source_frame == stop_frame, "route stops at the observed endpoint instead of advancing past it")
	_check(reached_menu or reached_scenario36_boundary or stopped_at_handoff_gap \
		or stopped_at_preset_wait or String(stop_source_route.get("phase", "")) == "error",
		"route reaches the first command menu or stops at its documented source boundary")
	if reached_menu:
		_check(String(stop_route_status.get("stage", "")) == "first_action_menu",
			"completed endpoint is the initial first-action menu")
	elif stopped_at_preset_wait:
		_check(String(final_handoff.get("status", "")) == "blocked_on_caller",
			"`$893B` wait boundary is documented as a blocked caller")
		_check(String(final_handoff.get("pending_helper_id", "")) == "fresh_match_preset_wait_0078"
			and int(final_handoff.get("pending_source_pc", -1)) == 0x893B,
			"`$893B` wait boundary preserves the pending ROM continuation")
		var next_step := String(final_handoff.get("next_step", ""))
		_check(next_step.contains("NMI/IRQ") and next_step.contains("$8117"),
			"`$893B` wait boundary identifies the unresolved interrupt handlers and `$8117` return")
		var caller_stop_seen := false
		for event_variant in stop_route_status.get("sound_queue_write_events", []):
			if not event_variant is Dictionary:
				continue
			var event: Dictionary = event_variant
			if int(event.get("source_pc", -1)) == 0x8107 \
					and int(event.get("address", -1)) == 0x0700 \
					and int(event.get("queue_id", -1)) == 0x01 \
					and bool(event.get("applied", false)):
				caller_stop_seen = true
				break
		_check(caller_stop_seen,
			"source-owned `$8107` queue-stop write reaches the route audio presenter")
	elif not reached_scenario36_boundary and not stopped_at_handoff_gap:
		_check(String(stop_source_route.get("error", "")).length() > 0,
			"unresolved route gap reports its source error")
	if expect_scenario36_boundary:
		var nmi_result: Dictionary = stop_route_status.get("fresh_source_route_nmi", {})
		var task_result: Dictionary = stop_route_status.get("fresh_source_route_task", {})
		var receiver_result: Dictionary = task_result.get("receiver_result", {})
		var holder_result: Dictionary = task_result.get("holder_copy_result", {})
		var scenario36_result: Dictionary = task_result
		var scenario36_queue_result: Dictionary = scenario36_result.get("scenario36_queue_result", {})
		var initializer_result: Dictionary = task_result.get("position_initializer_result", {})
		var wait_result: Dictionary = nmi_result.get("slot05_wait_result",
			nmi_result.get("slot05_scenario_wait_result", {}))
		var call_request: Dictionary = nmi_result.get("position_initializer_call_request", {})
		var live_ram: PackedByteArray = final_slot05.get("ram_image", PackedByteArray())
		_check(reached_scenario36_boundary, "recorded A press executes position setup, receiver selection, holder copy, and scenario `$36` yield through `$CB0F`")
		_check(String(nmi_result.get("status", "")) == "stopped_at_slot05_dc07_call_boundary",
			"ROM-byte input branch reaches the `$DAF2->$DC07` call")
		_check(int(wait_result.get("exit_pc", -1)) == 0xDAF2,
			"ROM-byte wait path exits at `$DAF2` under the recorded input")
		_check(int(call_request.get("target_pc", -1)) == 0xDC07,
			"ROM-byte `$DAF2` call targets the position initializer")
		_check(String(initializer_result.get("status", "")) == "returned_to_slot05_caller_DAF5",
			"hash-checked `$DC07` callee returns at its source caller boundary")
		_check(String(receiver_result.get("status", "")) == "stopped_at_slot05_e6ec_holder_call_boundary",
			"ROM-byte `$DAF5` caller reaches its `$E6EC` handoff")
		_check(String(holder_result.get("status", "")) == "returned_to_slot05_db0e_before_scenario36",
			"ROM-byte `$E6EC/$CDE2` holder copy returns before scenario `$36`")
		_check(live_ram.size() == 0x800 and live_ram[0x001C] == 0x80 and live_ram[0x001E] == 0x80,
			"source-frame sampler writes held A `$001C=$80` and new A edge `$001E=$80`")
		_check(live_ram.size() == 0x800 and live_ram[0x0441] == 8,
			"ROM `$DAEF` writes holder slot 8 to `$0441`")
		_check(String(scenario36_result.get("status", "")) == "scenario36_queued_slot05_yielded_and_scheduler_scanned",
			"source route executes `$DB0E->$CBB0->$CB0F`, saves slot `$05`, and scans the scheduler")
		_check(String(scenario36_queue_result.get("status", "")) == "scenario36_queue_at_cb0f_entry",
			"scenario `$36` queue executor reports the ROM-derived `$CB0F` entry")
		_check(int(scenario36_queue_result.get("registers", {}).get("pc", -1)) == 0xCB0F \
				and int(scenario36_queue_result.get("registers", {}).get("sp", -1)) == 0x4C,
			"nested source JSR frames reach `$CB0F` with the expected task stack")
		_check(int(final_slot05.get("pc", -1)) == 0xCB0F and int(final_slot05.get("sp", -1)) == 0x4A \
				and int(final_slot05.get("phase", -1)) == 3,
			"scheduler saves slot `$05` at the yielded `$CB0F` boundary")
		_check(int(scenario36_result.get("next_selected_task_slot", -1)) == 0x09 \
				and String(stop_source_route.get("phase", "")) == "stopped_before_scenario36_slot09_dispatch",
			"post-yield scan selects slot `$09` and stops before its scenario consumer runs")
		_check(not bool(scenario36_result.get("next_external_nmi_required", true)),
			"selected slot `$09` is pending dispatch before another external NMI")
		_check(live_ram.size() == 0x800 and live_ram[0x00E2] == 0xBE and live_ram[0x05FC] == 6,
			"live ROM RNG `$E2=$BE` and `$DC82` resolve receiver slot 6")
		_check(live_ram.size() == 0x800 and live_ram[0x0034] == 0x60 \
				and live_ram[0x0035] == 0x03 and live_ram[0x0635] == 0x7C \
				and live_ram[0x0637] == 0x7C and live_ram[0x05FE] == 0x71,
			"live `$E6EC` copies holder slot 8's ROM-derived coordinates and `$CDE2` index")
		_check(route.get_route_status().get("initial_player_positions", []).size() == 22,
			"all 22 player positions are consumed into the live route")
		var oracle_comparison := _compare_all_position_records(
			live_ram, initializer_result.get("positions", []))
		_check(oracle_comparison == "matched_22",
			"all 22 ROM-derived position pairs match the same-input FCEUX frame-8593 RAM oracle (%s)" % oracle_comparison)
		_check(_has_button_change(events, 8594, "A", false),
			"recorded input dispatch includes the frame-8594 A release")
	_check(int(stop_route_status.get("selected_action_id", -2)) == -1,
		"no soccer action is selected before the initial command menu")
	_check(not bool(stop_route_status.get("continue_entered", false)),
		"Continue flow remains outside the recorded route")
	print("Recorded-input stage checkpoints: ", JSON.stringify(_stage_at_checkpoints))
	if route.source_frame >= 8443:
		_save_background_image(route, route.source_frame)

	if _failures == 0 and reached_menu:
		print("PASS: recorded post-title inputs replay through the ROM-backed route to the initial command menu at frame %d." % route.source_frame)
		print("LIMIT: full field composition, PPU/APU timing, audio parity, menu-navigation coverage, and ROM-free runtime check remain open.")
	elif _failures == 0 and expect_scenario36_boundary and reached_scenario36_boundary:
		print("PASS: recorded frame-8593 A input executes `$DC07`, holder selection, scenario `$36` through `$CB0F`, and the next slot-$09 selection.")
		print("LIMIT: scenario event continuation, field PPU/audio parity, and the initial command menu remain open.")
	elif _failures == 0 and stopped_at_handoff_gap:
		print("PASS: recorded-input route reaches and holds at the unresolved `$82DF->$9BA0` cleanup boundary at frame %d." % route.source_frame)
		print("LIMIT: this is not completion of the goal; cleanup, fresh-match handoff, field rendering, and the first command menu remain open.")
	elif _failures == 0 and stopped_at_preset_wait:
		print("PASS: recorded-input route reaches `$893B` at frame %d, reports the pending `$8117` continuation, and sends the ROM `$8107` `$0700=$01` stop write to the audio presenter." % route.source_frame)
		print("LIMIT: the NMI/IRQ wait release is unresolved; the first command menu, same-input presentation/audio parity, and ROM-free runtime remain incomplete.")
	elif _failures == 0:
		printerr("INCOMPLETE: route stopped at a source boundary before the initial command menu.")
		_failures += 1
	else:
		printerr("FAIL: %d recorded-input route assertion(s)" % _failures)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


func _has_button_change(events: Dictionary, frame: int, name: String, pressed: bool) -> bool:
	for change_variant in events.get(frame, []):
		if change_variant is Dictionary \
				and String(change_variant.get("name", "")) == name \
				and bool(change_variant.get("pressed", false)) == pressed:
			return true
	return false


func _compare_all_position_records(live_ram: PackedByteArray, positions: Array) -> String:
	if not FileAccess.file_exists(POSITION_RAM_ORACLE):
		return "oracle unavailable"
	var oracle := FileAccess.get_file_as_bytes(POSITION_RAM_ORACLE)
	if live_ram.size() != 0x0800 or oracle.size() != 0x0800 or positions.size() != 22:
		return "malformed RAM or position input"
	for position_variant in positions:
		if not position_variant is Dictionary:
			return "malformed position record"
		var position: Dictionary = position_variant
		var record_address := int(position.get("record_address", -1))
		var x_offset := int(position.get("x_record_offset", -1))
		var y_offset := int(position.get("y_record_offset", -1))
		if record_address < 0 or record_address + max(x_offset, y_offset) >= 0x0800:
			return "record pointer out of bounds"
		for offset_name: String in ["x", "y"]:
			var offset := x_offset if offset_name == "x" else y_offset
			if live_ram[record_address + offset] != oracle[record_address + offset] \
					or int(position.get(offset_name, -1)) != oracle[record_address + offset]:
				return "slot %d %s differs" % [int(position.get("global_slot", -1)), offset_name]
	return "matched_22"


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


func _dispatch_edges(route: KickoffRouteRuntime, changes: Array) -> void:
	for change_variant in changes:
		var change: Dictionary = change_variant
		var key_code: Key
		match str(change.get("name", "")):
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
		var stage := str(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _save_background_image(route: KickoffRouteRuntime, source_frame: int) -> void:
	var image: Image = route._visuals.screen.get_rendered_background_image()
	_check(image != null and not image.is_empty(), "Godot renderer exposes the ROM-backed background image at frame %d" % source_frame)
	if image == null or image.is_empty():
		return
	var path := OUTPUT_PNG.get_basename() + "_%04d.png" % source_frame
	var save_error := image.save_png(path)
	_check(save_error == OK, "background diagnostic image saved at frame %d" % source_frame)
	print("Godot background frame %d: %s (%dx%d; CanvasItem sprites excluded)" % [source_frame, path, image.get_width(), image.get_height()])


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
