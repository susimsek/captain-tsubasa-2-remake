extends SceneTree
## Replays ordinary recorded input through the production route to the live
## scenario-$38 `$CA52->$EE9F` animation-$00 call at source frame 9066.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const POST_TITLE_INPUTS := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const FIRST_PASS_INPUTS := "res://reference/diagnostics/first_pass_action_input_edges_20261110.csv"
const FIRST_CALL_FRAME := 9066
const TITLE_HANDOFF_FRAME := 4692
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var title_runtime := MAIN_SCENE.instantiate()
	if title_runtime == null:
		_fail("The title scene is unavailable as the live KICK OFF handoff source.")
		quit(1)
		return
	title_runtime.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(title_runtime)
	await process_frame
	var opening_audio = title_runtime.get_node_or_null("OpeningAudio")
	if opening_audio != null:
		opening_audio.stop()
	var title_presenter = title_runtime.get_node_or_null("SourcePresenter")
	var title_renderer = title_runtime.get_node_or_null("TitleMenu/TitleBackground")
	var fade_counters: Variant = title_presenter.state.get("fade_counters", Vector2i(-1, -1)) \
		if title_presenter != null else Vector2i(-1, -1)
	var title_palette: PackedByteArray = title_renderer.call("get_source_title_palette_bytes") \
		if is_instance_valid(title_renderer) and title_renderer.has_method("get_source_title_palette_bytes") \
		else PackedByteArray()
	if typeof(fade_counters) != TYPE_VECTOR2I or fade_counters != Vector2i(0x0F, 0x0F) \
			or title_palette.size() != 0x20:
		_fail("The live title presenter did not supply the expected full-brightness ROM palette boundary.")
		await _cleanup_title(title_runtime)
		quit(1)
		return
	var route = ROUTE_SCENE.instantiate()
	route.process_mode = Node.PROCESS_MODE_DISABLED
	route.action_confirmation_requested.connect(_on_action_confirmation_requested)
	var source_fade := {"fade_counters": fade_counters, "base_palette_bytes": title_palette}
	if not route.initialize_from_title_handoff(TITLE_HANDOFF_FRAME, ROM_SHA256, source_fade, title_renderer):
		_fail("The production route rejected the ROM-derived title handoff.")
		await _cleanup_title(title_runtime)
		quit(1)
		return
	root.add_child(route)
	await process_frame
	var audio_callback := Callable(route, "_on_rom_sound_queue_write_requested")
	if route.rom_sound_queue_write_requested.is_connected(audio_callback):
		route.rom_sound_queue_write_requested.disconnect(audio_callback)
	route.set_process(false)
	route.source_frame = 4693
	var edges := _read_input_edges()
	if edges.is_empty():
		_fail("The recorded opening and first-PASS input edges are missing.")
		await _cleanup_route(route)
		await _cleanup_title(title_runtime)
		quit(1)
		return
	var target_summary: Dictionary = {}
	var failure_frame := -1
	var failure_text := ""
	for source_frame in range(4694, FIRST_CALL_FRAME + 1):
		if edges.has(source_frame):
			_dispatch_edges(route, edges[source_frame])
		route.call("_advance_route_source_tick")
		var status: Dictionary = route.get_route_status()
		var source_route: Dictionary = status.get("fresh_source_route", {})
		if str(source_route.get("phase", "")) == "error":
			failure_frame = source_frame
			failure_text = str(source_route.get("error", ""))
		var runner = route._fresh_source_route_runner
		if runner != null:
			var summary: Dictionary = runner.get_last_root_actor_loop_result()
			if int(summary.get("source_frame", -1)) == FIRST_CALL_FRAME:
				target_summary = summary
		if failure_frame >= 0 or source_frame == FIRST_CALL_FRAME:
			break
		if edges.has(source_frame):
			await process_frame
	if target_summary.is_empty():
		var final_status: Dictionary = route.get_route_status()
		var final_runner = route._fresh_source_route_runner
		var final_summary: Dictionary = final_runner.get_last_root_actor_loop_result() if final_runner != null else {}
		_fail("The production route did not complete the source-frame-9066 `$CA52->$EE9F` call. Stop frame=%d stage=%s route_phase=%s actor_frame=%s actor_status=%s error=%s" % [
			failure_frame, str(final_status.get("stage", "")),
			str(final_status.get("fresh_source_route", {}).get("phase", "")),
			str(final_summary.get("source_frame", "none")), str(final_summary.get("status", "none")), failure_text])
		await _cleanup_route(route)
		await _cleanup_title(title_runtime)
		quit(1)
		return
	if failure_frame == FIRST_CALL_FRAME and ("$CA52->$EE9F" in failure_text or "$8012" in failure_text):
		_fail("The source-derived animation-$00 branch still stops at frame 9066: " + failure_text)
		await _cleanup_route(route)
		await _cleanup_title(title_runtime)
		quit(1)
		return
	if not _validate_live_result(route, target_summary):
		await _cleanup_route(route)
		await _cleanup_title(title_runtime)
		quit(1)
		return
	var final_runner = route._fresh_source_route_runner
	var e3ca_summary: Dictionary = final_runner.get_last_root_e3ca_result() if final_runner != null else {}
	if not _validate_e3ca_live_result(e3ca_summary):
		var route_phase: Dictionary = route.get_route_status().get("fresh_source_route", {})
		var e3ca_executor = final_runner._e3ca_no_direction_executor if final_runner != null else null
		print("E3CA diagnostic: summary=%s route_phase=%s route_error=%s executor_error=%s" % [
			JSON.stringify(e3ca_summary), String(route_phase.get("phase", "")),
			String(route_phase.get("error", "")),
			String(e3ca_executor.error_message) if e3ca_executor != null else "unavailable"])
		await _cleanup_route(route)
		await _cleanup_title(title_runtime)
		quit(1)
		return
	print("PASS: recorded-input route executes scenario-$38 animation-$00 at frame 9066, then ROM no-direction `$CA55->$E3CA->$CA58->$CA4F->$CB0F`.")
	print("PASS: bank-$14 ID-$00 pointer, F5 `$0B` palette row, F4 selectors, six F6 record removals, and F0 return all match pinned ROM bytes.")
	print("PASS: `$E3CA` reads live `$05FB=$00` and `$001C & $0F=$00`; it leaves field position unchanged and saves the source caller's next yield.")
	print("LIMIT: no direct FCEUX terminal observation was made; this verifier establishes the source-derived Godot route state, not visible-pixel or PPU/APU timing parity.")
	await _cleanup_route(route)
	await _cleanup_title(title_runtime)
	quit(0)


func _validate_live_result(route, summary: Dictionary) -> bool:
	var loop: Dictionary = summary.get("actor_loop", {})
	var registers: Dictionary = summary.get("registers", {})
	var runner = route._fresh_source_route_runner
	var executor = runner._ee9f_empty_actor_executor if runner != null else null
	if executor == null:
		return _fail("The production `$EE9F` executor is unavailable after the live route call.")
	var ram: PackedByteArray = executor._ram
	var pcs: Array = executor._instruction_pcs
	var actor_zero_removals := _count_pc(pcs, 0x83AE)
	if str(summary.get("status", "")) != "returned_to_source_caller" \
			or int(registers.get("pc", -1)) != 0xCA55 \
			or int(registers.get("sp", -1)) != 0x2A \
			or int(loop.get("return_pc", -1)) != 0xCA55 \
			or int(loop.get("active_actor_count", -1)) != 0 \
			or ram.size() != 0x800 \
			or ram.slice(0x053A, 0x053E) != PackedByteArray([0x00, 0x00, 0x00, 0x00]) \
			or ram.slice(0x004C, 0x004E) != PackedByteArray([0x5B, 0x8B]) \
			or ram.slice(0x0494, 0x0498) != PackedByteArray([0x1F, 0x00, 0x00, 0x00]) \
			or int(ram[0x0498]) != 0x02 or actor_zero_removals != 6:
		return _fail("The live animation-$00 return, selectors, stream cursor, actor removals, or caller registers differ from ROM output.")
	for index in range(6):
		if int(ram[0x0547 + index * 0x15]) != 0:
			return _fail("ROM `$F6` did not clear actor record %d at the source return." % index)
	var expected_palette := PackedByteArray([
		0x0F, 0x36, 0x31, 0x30, 0x0F, 0x07, 0x18, 0x28,
		0x0F, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x30, 0x11])
	if ram.slice(0x047F, 0x048F) != expected_palette:
		return _fail("ROM `$F5 $0B->$CC02` palette output does not match `$FC50-$FC5B`.")
	for required_pc in [0x8153, 0x8142, 0x83AE, 0x80A2]:
		if not pcs.has(required_pc):
			return _fail("The production actor executor omitted source handler `$%04X`." % required_pc)
	return true


func _validate_e3ca_live_result(summary: Dictionary) -> bool:
	var registers: Dictionary = summary.get("registers", {})
	var caller_request: Dictionary = summary.get("caller_request", {})
	var yield_request: Dictionary = summary.get("yield_request", {})
	var expected_pcs: Array[int] = [0xCA55, 0xE3CA, 0xE3CD, 0xE3CF, 0xE3D2, 0xE3D4, 0xE406]
	if int(summary.get("source_frame", -1)) != FIRST_CALL_FRAME \
			or String(summary.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/e3ca_no_direction_call/manifest.json" \
			or String(summary.get("status", "")) != "returned_to_source_caller" \
			or summary.get("instruction_pcs", []) != expected_pcs \
			or not bool(summary.get("returned_to_caller", false)) \
			or bool(summary.get("movement_applied", true)) \
			or int(registers.get("pc", -1)) != 0xCA58 \
			or int(registers.get("sp", -1)) != 0x2A \
			or int(registers.get("a", -1)) != 0 \
			or int(caller_request.get("source_pc", -1)) != 0xCA55 \
			or int(caller_request.get("target_cpu_address", -1)) != 0xE3CA \
			or int(caller_request.get("expected_return_pc", -1)) != 0xCA58 \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or int(yield_request.get("target_cpu_address", -1)) != 0xCB0F \
			or int(yield_request.get("resume_pc", -1)) != 0xCA52 \
			or int(yield_request.get("delay_in_a", -1)) != 0x01:
		return _fail("The live animation-$00 EE9F result did not pass the ROM no-direction `$CA55->$E3CA` return and `$CA4F->$CB0F` yield contract.")
	return true


func _read_input_edges() -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(POST_TITLE_INPUTS, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	var previous: Dictionary = {}
	var buttons: Array[String] = ["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"]
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		var current: Dictionary = {}
		for index in range(buttons.size()):
			current[buttons[index]] = row[index + 2] == "1"
		var changes: Array[Dictionary] = []
		for button in buttons:
			if bool(previous.get(button, false)) != bool(current.get(button, false)):
				changes.append({"name": button, "pressed": bool(current.get(button, false))})
		if source_frame > 4693 and not changes.is_empty():
			result[source_frame] = changes
		previous = current
	file.close()
	file = FileAccess.open(FIRST_PASS_INPUTS, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3:
			continue
		var source_frame := int(row[0])
		if source_frame <= 8953 or source_frame > FIRST_CALL_FRAME:
			continue
		var changes: Array = result.get(source_frame, [])
		changes.append({"name": str(row[1]).strip_edges(), "pressed": str(row[2]).strip_edges() == "1"})
		result[source_frame] = changes
	file.close()
	return result


func _dispatch_edges(route, changes: Array) -> void:
	for change_variant in changes:
		if not change_variant is Dictionary:
			continue
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


func _on_action_confirmation_requested(_action_id: int) -> void:
	pass


func _count_pc(pcs: Array, expected_pc: int) -> int:
	var count := 0
	for pc_variant in pcs:
		if int(pc_variant) == expected_pc:
			count += 1
	return count


func _cleanup_route(route) -> void:
	if is_instance_valid(route):
		if route.cue_audio != null:
			route.cue_audio.release_rom_audio_resources()
		route.free()
	await process_frame
	await process_frame


func _cleanup_title(title_runtime) -> void:
	if is_instance_valid(title_runtime):
		title_runtime.free()
	await process_frame


func _fail(message: String) -> bool:
	push_error(message)
	return false
