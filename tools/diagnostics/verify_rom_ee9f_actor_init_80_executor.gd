extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const ROOT_CALLER := preload("res://scripts/gameplay/rom_root_slot01_continuation_runtime.gd")
const EXECUTOR := preload("res://scripts/gameplay/rom_ee9f_actor_init_80_executor.gd")
const ACTOR_INTERPRETER := preload("res://scripts/gameplay/rom_actor_state_interpreter.gd")
const FIRST_MENU_FRAME := 8953


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route = ROUTE_SCENE.instantiate()
	root.add_child(route)
	await process_frame
	var audio_callback := Callable(route, "_on_rom_sound_queue_write_requested")
	if route.rom_sound_queue_write_requested.is_connected(audio_callback):
		route.rom_sound_queue_write_requested.disconnect(audio_callback)
	route.set_process(false)
	route.source_frame = 4693
	var events := _read_recorded_edges()
	if events.is_empty():
		_fail("Recorded post-title controller edges could not be read.")
		await _cleanup_route(route)
		quit(1)
		return
	var live_actor_summary: Dictionary = {}
	var stop_frame := -1
	var source_gap := ""
	var active_slot := -1
	for source_frame in range(4694, FIRST_MENU_FRAME + 1):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		route.call("_advance_route_source_tick")
		var status: Dictionary = route.get_route_status()
		var source_route: Dictionary = status.get("fresh_source_route", {})
		if str(source_route.get("phase", "")) == "error":
			stop_frame = source_frame
			var route_runner = route._fresh_source_route_runner
			if route_runner != null:
				live_actor_summary = route_runner.get_last_root_actor_loop_result()
			var scheduler_status: Dictionary = source_route.get("scheduler", {})
			active_slot = int(scheduler_status.get("active_task_slot", -1))
			source_gap = str(source_route.get("error", ""))
			break
		if events.has(source_frame):
			await process_frame
	if live_actor_summary.is_empty():
		_fail("Recorded inputs did not execute the production `$EE9F` actor loop before stopping at frame %d: %s" % [stop_frame, source_gap])
		await _cleanup_route(route)
		quit(1)
		return
	if active_slot != 0x09 or "$ED5B" not in source_gap or not _validate_live_actor_summary(live_actor_summary):
		_fail("Recorded route did not reach the verified next gap after the `$EE9F` return: frame=%d slot=%d gap=%s" % [stop_frame, active_slot, source_gap])
		await _cleanup_route(route)
		quit(1)
		return
	print("PASS: same recorded controller input executes the production `$EE9F` seed and active-actor loop, returns to `$CA55`, and reaches the later slot-$09 `$ED5B` gap at frame %d." % stop_frame)
	print("PASS: five ROM-derived actor records and all 34 visible OAM tuples match the muted frame-8481 trace.")
	print("LIMIT: slot-$09 wait/task continuation, full field/menu renderer, PPU/APU timing, audio parity, and the initial command menu remain incomplete.")
	await _cleanup_route(route)
	quit(0)


func _validate_result(result: Dictionary) -> bool:
	var registers: Dictionary = result.get("registers", {})
	var final_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var final_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var writes: Array = result.get("memory_writes", [])
	var actors: Array = result.get("actor_records", [])
	var path: Dictionary = result.get("active_actor_init", {})
	if str(result.get("status", "")) != "returned_to_ee9f_actor_loop" \
			or int(result.get("stop_pc", -1)) != 0xEEB1 \
			or int(registers.get("pc", -1)) != 0xEEB1 \
			or int(registers.get("sp", -1)) != 0x28 \
			or final_ram.size() != 0x800 or final_stack.size() != 0x100 \
			or final_ram.slice(0x053A, 0x053E) != PackedByteArray([0x00, 0x00, 0x8F, 0x00]) \
			or final_ram.slice(0x004C, 0x004E) != PackedByteArray([0xAA, 0x98]) \
			or final_ram.slice(0x0494, 0x0498) != PackedByteArray([0x2C, 0x0B, 0x05, 0x07]) \
			or actors.size() != 5 or writes.is_empty() \
			or str(path.get("status", "")) != "returned_to_ee9f_actor_loop" \
			or int(path.get("stream_pointer_after_f0", -1)) != 0x98AA \
			or int(path.get("actor_packets_executed", -1)) != 5 \
			or bool(result.get("returned_to_caller", true)):
		return _fail("Final `$F0->$EEB1` state differs from the ROM-derived first-call path.")
	var append_index := int(path.get("inline_append_cursor_before", -1))
	var append_base := 0x0499 + append_index * 3
	if append_index < 0 or int(path.get("inline_append_cursor_after", -1)) != append_index + 1 \
			or int(final_ram[0x0498]) != append_index + 1 \
			or final_ram.slice(append_base, append_base + 3) != PackedByteArray([0x00, 0x6C, 0x04]):
		return _fail("The ROM `$C533->$CCD2` inline record append did not honor the live `$0498` cursor.")
	var expected_motion: Array[int] = [0xA38A, 0xA723, 0xA723, 0xA72C, 0xA72C]
	var expected_appearance: Array[int] = [0xB30E, 0xB310, 0xB310, 0xB312, 0xB312]
	var expected_active: Array[int] = [0x81, 0x81, 0x80, 0x80, 0x80]
	var expected_addresses: Array[int] = [0x0547, 0x055C, 0x0571, 0x0586, 0x059B]
	var expected_packet_positions: Array[PackedByteArray] = [
		PackedByteArray([0x00, 0xD3]), PackedByteArray([0x28, 0xC3]),
		PackedByteArray([0x00, 0xC3]), PackedByteArray([0xB8, 0xB3]),
		PackedByteArray([0x00, 0xB3])]
	for actor_index in range(5):
		var actor: Dictionary = actors[actor_index]
		var address := expected_addresses[actor_index]
		var record: PackedByteArray = actor.get("bytes", PackedByteArray())
		if int(actor.get("cpu_address", -1)) != address \
				or int(actor.get("active_flags", -1)) != expected_active[actor_index] \
				or int(actor.get("motion_pointer", -1)) != expected_motion[actor_index] \
				or int(actor.get("appearance_pointer", -1)) != expected_appearance[actor_index] \
				or record.size() != 0x15 or int(final_ram[address]) != expected_active[actor_index] \
				or record[8] != expected_packet_positions[actor_index][0] \
				or record[0x0C] != expected_packet_positions[actor_index][1] \
				or final_ram.slice(address, address + 0x15) != record:
			return _fail("ROM `$F1` packet %d does not match its constructed actor record." % actor_index)
	if final_ram.slice(0x047F, 0x048F) != PackedByteArray([
			0x0F, 0x0F, 0x0F, 0x36, 0x0F, 0x0F, 0x30, 0x36,
			0x0F, 0x0F, 0x17, 0x36, 0x0F, 0x0F, 0x31, 0x30]):
		return _fail("ROM `$CC02` palette fill differs from the `$FC44` table row.")
	if result.get("ppu_bus_events", []) != [] \
			or bool(result.get("ppu_cycle_timing_modeled", true)) \
			or bool(result.get("audio_effects_modeled", true)):
		return _fail("The bounded result must state that PPU timing and audio are not modeled.")
	return true


func _validate_full_result(result: Dictionary, boundary: Dictionary) -> bool:
	var registers: Dictionary = result.get("registers", {})
	var loop: Dictionary = result.get("actor_loop", {})
	var records: Array = result.get("actor_records", [])
	var actor_outputs: Array = loop.get("actor_outputs", [])
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var writes: Array = result.get("memory_writes", [])
	if not bool(result.get("ok", false)) or String(result.get("status", "")) != "returned_to_source_caller" \
			or not bool(result.get("returned_to_caller", false)) \
			or int(registers.get("pc", -1)) != 0xCA55 or int(registers.get("sp", -1)) != 0x2A \
			or records.size() != 6 or actor_outputs.size() != 5 \
			or int(loop.get("sprites_written", -1)) != 34 \
			or int(loop.get("final_oam_cursor", -1)) != 136 \
			or ram.size() != 0x800 or int(ram[0x003A]) != 6 \
			or int(ram[0x003B]) != 136 or int(ram[0x0048]) != 34 \
			or not loop.has("oam_shadow"):
		return _fail("The live `$EEB1` loop did not return its five active actors and 34-sprite OAM state to `$CA55`.")
	var replayed_ram: PackedByteArray = boundary["ram_image"].duplicate()
	for write_variant in writes:
		if not write_variant is Dictionary:
			return _fail("The actor result contains a malformed ordered memory write.")
		var write: Dictionary = write_variant
		if String(write.get("space", "cpu_ram")) == "cpu_ram":
			var address := int(write.get("address", -1))
			if address < 0 or address >= replayed_ram.size():
				return _fail("The actor result contains an out-of-range RAM write.")
			replayed_ram[address] = int(write.get("value", -1)) & 0xFF
	if replayed_ram != ram:
		return _fail("Replaying the source actor loop's ordered writes does not reproduce its returned RAM image.")
	var trace_rows := _capture_actor_rows("8481")
	if trace_rows.size() != 5:
		return _fail("The muted actor trace does not contain the expected five frame-8481 draw validations.")
	var expected_addresses: Array[int] = [0x0547, 0x055C, 0x0571, 0x0586, 0x059B]
	var expected_counts: Array[int] = [25, 5, 0, 4, 0]
	var final_oam: PackedByteArray = loop["oam_shadow"]
	var matched_tuples := 0
	for index in range(5):
		var trace_row: Dictionary = trace_rows[index]
		var record: Dictionary = records[index]
		var actor_output: Dictionary = actor_outputs[index]
		var draw: Dictionary = actor_output.get("draw_result", {})
		var address := _hex_value(String(trace_row.get("actor_record", "")))
		var captured_record := _parse_hex_bytes(String(trace_row.get("actor_record_21_bytes", "")))
		if address != expected_addresses[index] \
				or int(record.get("cpu_address", -1)) != address \
				or record.get("bytes", PackedByteArray()) != captured_record \
				or int(draw.get("sprites_written", -1)) != expected_counts[index] \
				or int(draw.get("start_oam_byte_index", -1)) != int(trace_row.get("oam_index_before", -2)) \
				or int(draw.get("next_oam_byte_index", -1)) != int(trace_row.get("oam_index_after", -2)):
			return _fail("ROM-built actor record/OAM cursor differs from the muted trace at actor %d." % index)
		var captured_entries := _parse_oam_entries(String(trace_row.get("changed_oam_entries", "")))
		for entry_variant in captured_entries:
			var entry_index := int(entry_variant)
			var expected_tuple: PackedInt32Array = captured_entries[entry_variant]
			for byte_offset in 4:
				if int(final_oam[entry_index * 4 + byte_offset]) != expected_tuple[byte_offset]:
					return _fail("ROM-built OAM differs from the muted trace at actor %d / slot $%02X." % [index, entry_index])
			matched_tuples += 1
	if matched_tuples != 34:
		return _fail("Expected 34 matching muted-trace OAM tuples; got %d." % matched_tuples)
	return true


func _validate_live_actor_summary(result: Dictionary) -> bool:
	var registers: Dictionary = result.get("registers", {})
	var loop: Dictionary = result.get("actor_loop", {})
	var records: Array = result.get("actor_records", [])
	var actor_outputs: Array = loop.get("actor_outputs", [])
	var final_oam: PackedByteArray = loop.get("oam_shadow", PackedByteArray())
	if String(result.get("status", "")) != "returned_to_source_caller" \
			or int(registers.get("pc", -1)) != 0xCA55 or int(registers.get("sp", -1)) != 0x2A \
			or int(loop.get("entry_pc", -1)) != 0xEEB1 \
			or int(loop.get("return_pc", -1)) != 0xCA55 \
			or int(loop.get("active_actor_count", -1)) != 5 \
			or int(loop.get("sprites_written", -1)) != 34 \
			or int(loop.get("final_oam_cursor", -1)) != 136 \
			or records.size() != 6 or actor_outputs.size() != 5 or final_oam.size() != 256:
		return _fail("The production route's `$EEB1` result did not return five active actors and 34 OAM sprites to `$CA55`.")
	var trace_rows := _capture_actor_rows("8481")
	if trace_rows.size() != 5:
		return _fail("The muted actor trace does not contain five frame-8481 draw validations.")
	var expected_addresses: Array[int] = [0x0547, 0x055C, 0x0571, 0x0586, 0x059B]
	var expected_counts: Array[int] = [25, 5, 0, 4, 0]
	var matched_tuples := 0
	for index in range(5):
		var trace_row: Dictionary = trace_rows[index]
		var record: Dictionary = records[index]
		var actor_output: Dictionary = actor_outputs[index]
		var draw: Dictionary = actor_output.get("draw_result", {})
		var address := _hex_value(String(trace_row.get("actor_record", "")))
		var captured_record := _parse_hex_bytes(String(trace_row.get("actor_record_21_bytes", "")))
		if address != expected_addresses[index] \
				or int(record.get("cpu_address", -1)) != address \
				or record.get("bytes", PackedByteArray()) != captured_record \
				or int(draw.get("sprites_written", -1)) != expected_counts[index] \
				or int(draw.get("start_oam_byte_index", -1)) != int(trace_row.get("oam_index_before", -2)) \
				or int(draw.get("next_oam_byte_index", -1)) != int(trace_row.get("oam_index_after", -2)):
			return _fail("The production route's ROM-built actor record/OAM cursor differs from muted trace actor %d." % index)
		var captured_entries := _parse_oam_entries(String(trace_row.get("changed_oam_entries", "")))
		for entry_variant in captured_entries:
			var entry_index := int(entry_variant)
			var expected_tuple: PackedInt32Array = captured_entries[entry_variant]
			for byte_offset in 4:
				if int(final_oam[entry_index * 4 + byte_offset]) != expected_tuple[byte_offset]:
					return _fail("The production route's ROM-built OAM differs from muted trace actor %d / slot $%02X." % [index, entry_index])
			matched_tuples += 1
	if matched_tuples != 34:
		return _fail("Expected 34 matching muted-trace OAM tuples; got %d." % matched_tuples)
	return true


func _capture_actor_rows(frame_text: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open("res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/actor_draw_calls.csv", FileAccess.READ)
	if file == null:
		return rows
	var header := file.get_csv_line()
	var columns: Dictionary = {}
	for index in range(header.size()):
		columns[String(header[index])] = index
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.size() != header.size() or String(values[0]) != frame_text:
			continue
		var row: Dictionary = {}
		for key_variant in columns:
			row[String(key_variant)] = values[int(columns[key_variant])]
		rows.append(row)
	return rows


func _parse_hex_bytes(text: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	for token in text.strip_edges().split(" ", false):
		bytes.append(_hex_value(String(token)))
	return bytes


func _parse_oam_entries(text: String) -> Dictionary:
	var entries: Dictionary = {}
	for entry_text in text.strip_edges().split("|", false):
		var parts := String(entry_text).split(":", false)
		if parts.size() != 2:
			continue
		var values := parts[1].split("/", false)
		if values.size() != 4:
			continue
		var tuple := PackedInt32Array()
		for value in values:
			tuple.append(_hex_value(String(value)))
		entries[_hex_value(String(parts[0]))] = tuple
	return entries


func _hex_value(text: String) -> int:
	return text.trim_prefix("$").hex_to_int()


func _read_recorded_edges() -> Dictionary:
	var file := FileAccess.open(INPUT_CSV, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	var result: Dictionary = {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		if source_frame <= 4693:
			continue
		var edges: Array[String] = []
		for index in range(2, 10):
			if row[index] == "1":
				edges.append(["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"][index - 2])
		if not edges.is_empty():
			result[source_frame] = edges
	return result


func _dispatch_edges(route, edges: Array) -> void:
	for edge in edges:
		var key_code: Key
		match str(edge):
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
		event.pressed = true
		route.call("_unhandled_input", event)
		var stage := str(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _cleanup_route(route) -> void:
	if is_instance_valid(route):
		if route.cue_audio != null:
			route.cue_audio.release_rom_audio_resources()
		route.free()
	await process_frame
	await process_frame


func _fail(message: String) -> bool:
	push_error(message)
	return false
