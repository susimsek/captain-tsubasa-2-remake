extends SceneTree

const CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_caller_continuation.gd")
const SOURCE_QUEUE_PATH := "res://reference/rom_extract/gameplay/first_match_audio_queue_events_20261027.json"
const FCEUX_HOOKS_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/pc_hooks.csv"


func _initialize() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: hash-checked KICK OFF caller reaches the ROM `$812C` queue store and `$8157` ID-2 dispatch only with explicit call-return and cutscene-completion inputs.")
	print("LIMIT: helper bodies, wait-loop/task-stack timing, source frame/cycle, and production route integration remain unmodeled.")
	quit(0)


func _verify() -> bool:
	var continuation: Variant = CONTINUATION_SCRIPT.new()
	if not continuation.configure_from_project_sources():
		return _fail("Could not configure the hash-checked caller source: " + continuation.error_message)
	var status: Dictionary = continuation.get_status()
	if bool(status.get("does_execute_6502", true)) \
			or bool(status.get("does_execute_helper_bodies", true)) \
			or bool(status.get("does_execute_wait_loop_or_yield_ticks", true)) \
			or bool(status.get("does_model_stack_or_exact_cpu_timing", true)) \
			or bool(status.get("uses_trace_ram_or_trace_frame_as_input", true)) \
			or bool(status.get("live_runtime_integrated", true)):
		return _fail("The continuation scope/status flags overclaim execution or integration.")
	if continuation.resolve_match_setup_music_id(0) != 0x55 \
			or continuation.resolve_match_setup_music_id(0x1F) != 0x55 \
			or continuation.resolve_match_setup_music_id(0x20) != 0x4C:
		return _fail("The byte-derived `$8122-$812C` music branch differs at its threshold.")
	if continuation.resolve_pre_match_cutscene_id(0) != 0x02:
		return _fail("ROM table `$83DC[0]` no longer selects cutscene ID `$02`.")

	var caller_inputs := _fresh_caller_inputs("natural")
	var blocked: Dictionary = continuation.execute_fresh_kickoff(caller_inputs, [])
	if not bool(blocked.get("ok", false)) \
			or String(blocked.get("status", "")) != "blocked_on_source_return" \
			or int(blocked.get("final_source_pc", -1)) != 0x80E6 \
			or not blocked.get("queue_events", []).is_empty():
		return _fail("Caller must block at the first unprovided `$80E6->$9BA0` return without fabricating audio.")

	var receipts := _verifier_source_returns(continuation)
	var missing_pre_music := _without_callsite(receipts, 0x811F)
	var pre_music_blocked: Dictionary = continuation.execute_fresh_kickoff(caller_inputs, missing_pre_music)
	if String(pre_music_blocked.get("status", "")) != "blocked_on_source_return" \
			or int(pre_music_blocked.get("final_source_pc", -1)) != 0x811F \
			or _has_queue_event(pre_music_blocked.get("queue_events", []), 0x812C):
		return _fail("The `$812C` cue must remain absent until the final pre-music `$811F` return is supplied.")

	var missing_dispatch := _without_callsite(receipts, 0x8157)
	var dispatch_blocked: Dictionary = continuation.execute_fresh_kickoff(caller_inputs, missing_dispatch)
	if String(dispatch_blocked.get("status", "")) != "blocked_on_source_return" \
			or int(dispatch_blocked.get("final_source_pc", -1)) != 0x8157 \
			or not _has_queue_event(dispatch_blocked.get("queue_events", []), 0x812C) \
			or not dispatch_blocked.get("cutscene_dispatch_events", []).is_empty():
		return _fail("After the music store, ID 2 must wait for its own `$8157->$8464` source return.")

	var complete: Dictionary = continuation.execute_fresh_kickoff(caller_inputs, receipts)
	if String(complete.get("status", "")) != "cutscene_2_dispatched_wait_pending" \
			or int(complete.get("final_source_pc", -1)) != 0x815A \
			or int(complete.get("source_frame", -2)) != -1 \
			or int(complete.get("cpu_cycle", -2)) != -1 \
			or bool(complete.get("timing_verified", true)):
		return _fail("Complete source continuation must stop at `$815A` and leave absolute timing unknown.")
	var queue_events: Array = complete.get("queue_events", [])
	if queue_events.size() != 3 \
			or not _has_queue_event(queue_events, 0x812C) \
			or not _has_queue_event(queue_events, 0x8107) \
			or not _has_queue_event(queue_events, 0x82DC):
		return _fail("The caller's `$82DC`, `$8107`, `$812C` queue-store sequence is incomplete.")
	var music_event := _find_queue_event(queue_events, 0x812C)
	if music_event.is_empty() \
			or int(music_event.get("queue_id", -1)) != 0x55 \
			or int(music_event.get("queue_address", -1)) != 0x0700 \
			or int(music_event.get("post_store_pc", -1)) != 0x812F \
			or int(music_event.get("source_frame", -2)) != -1 \
			or int(music_event.get("cpu_cycle", -2)) != -1:
		return _fail("The source-derived fresh-match event must identify the actual `$812C` store without guessed timing.")
	var id2_events: Array = complete.get("cutscene_dispatch_events", [])
	if id2_events.size() != 1 or int(id2_events[0].get("cutscene_id", -1)) != 2 \
			or int(id2_events[0].get("caller_pc", -1)) != 0x8157:
		return _fail("Fresh match zero must dispatch table-selected cutscene ID 2 at `$8157`.")
	if not _contains_pc(complete.get("source_path", []), 0x812C) \
			or not _contains_pc(complete.get("source_path", []), 0x8157) \
			or not _contains_pc(complete.get("source_path", []), 0x815A):
		return _fail("The executed source path must include the audio store, ID-2 dispatch, and second wait call.")

	var select_inputs := _fresh_caller_inputs("select")
	var select_result: Dictionary = continuation.execute_fresh_kickoff(select_inputs, receipts)
	if String(select_result.get("status", "")) != "cutscene_2_dispatched_wait_pending" \
			or not _contains_pc(select_result.get("source_path", []), 0x82C4) \
			or not _has_queue_event(select_result.get("queue_events", []), 0x812C):
		return _fail("Select exit must take the source wait's `$82C0-$82C4` path and resume the same KICK OFF caller.")

	var continue_inputs := _fresh_caller_inputs("natural")
	continue_inputs["title_state_ed"] = 0x40
	var continue_result: Dictionary = continuation.execute_fresh_kickoff(continue_inputs, receipts)
	if bool(continue_result.get("ok", true)) or not continue_result.get("queue_events", []).is_empty():
		return _fail("Title `$ED.6=1` must refuse this KICK OFF continuation and emit no queue event.")
	var wrong_index := _fresh_caller_inputs("natural")
	wrong_index["match_index_0026"] = 1
	var wrong_index_result: Dictionary = continuation.execute_fresh_kickoff(wrong_index, receipts)
	if bool(wrong_index_result.get("ok", true)) or not wrong_index_result.get("queue_events", []).is_empty():
		return _fail("The cold fresh-start path must refuse a match index not derived from reset source.")

	return _verify_source_stepper_and_muted_trace(music_event)


func _fresh_caller_inputs(wait_kind: String) -> Dictionary:
	var wait_return := {
		"cutscene_id": 1,
		"kind": wait_kind,
		"source_event_id": "verifier_fixture:cutscene1:%s" % wait_kind,
		"script_pointer_ended": wait_kind == "natural",
		"newly_pressed_buttons": 0x20 if wait_kind == "select" else 0x00,
	}
	return {
		"start_press_accepted": true,
		"title_input_event_id": "verifier_fixture:title_start_kickoff",
		"title_state_ed": 0x00,
		"cutscene1_wait_return": wait_return,
		"match_index_0026": 0,
		"ram_at_8145": {
			"$0026": 0,
			"$00E0": 0xC0,
			"provenance": "rom_derived_caller_state",
		},
	}


func _verifier_source_returns(continuation: Variant) -> Array:
	var receipts: Array = []
	for call_variant in continuation.required_source_return_contract():
		if not call_variant is Dictionary:
			continue
		var call: Dictionary = call_variant
		var receipt := {
			"caller_pc": int(call["caller_pc"]),
			"target_pc": int(call["target_pc"]),
			"return_pc": int(call["return_pc"]),
			"status": "returned",
			"source_event_id": "verifier_fixture:%04X:%04X" % [int(call["caller_pc"]), int(call["target_pc"])],
		}
		if call.has("cutscene_id"):
			receipt["cutscene_id"] = int(call["cutscene_id"])
		elif int(call["caller_pc"]) == 0x8157:
			receipt["cutscene_id"] = 0x02
		receipts.append(receipt)
	return receipts


func _without_callsite(receipts: Array, caller_pc: int) -> Array:
	var filtered: Array = []
	for receipt_variant in receipts:
		if receipt_variant is Dictionary and int(receipt_variant.get("caller_pc", -1)) != caller_pc:
			filtered.append(receipt_variant)
	return filtered


func _has_queue_event(events: Array, store_pc: int) -> bool:
	return not _find_queue_event(events, store_pc).is_empty()


func _find_queue_event(events: Array, store_pc: int) -> Dictionary:
	for event_variant in events:
		if event_variant is Dictionary and int(event_variant.get("queue_store_instruction_pc", -1)) == store_pc:
			return event_variant
	return {}


func _contains_pc(source_path: Array, pc: int) -> bool:
	return source_path.has(pc)


func _verify_source_stepper_and_muted_trace(projected_event: Dictionary) -> bool:
	var source_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_QUEUE_PATH))
	if not source_variant is Dictionary:
		return _fail("ROM source-stepper queue-event reference is missing or malformed.")
	var source: Dictionary = source_variant
	if String(source.get("source_rom_sha256", "")) != String(projected_event.get("source_rom_sha256", "")):
		return _fail("Source-stepper event belongs to a different ROM revision.")
	var found_source_event := false
	for event_variant in source.get("events", []):
		if event_variant is Dictionary:
			var event: Dictionary = event_variant
			if int(event.get("source_frame", -1)) == 7409 \
					and int(event.get("source_cycle", -1)) == 220630517 \
					and int(event.get("queue_id", -1)) == 0x55 \
					and String(event.get("post_store_pc", "")) == "$812F":
				found_source_event = true
				break
	if not found_source_event:
		return _fail("The ROM-only source trace no longer contains the documented `$812C/$812F` event.")
	var hooks := FileAccess.get_file_as_string(FCEUX_HOOKS_PATH)
	if hooks.is_empty():
		return _fail("Muted FCEUX PC-hook reference is unavailable.")
	var hook_frame_found := false
	var direct_store_hook_found := false
	for row in hooks.split("\n", false).slice(1):
		var columns := row.split(",")
		if columns.size() < 4:
			continue
		if int(columns[0]) == 7408 or int(columns[0]) == 7409:
			if String(columns[3]) == "$A626":
				hook_frame_found = true
			if String(columns[3]) == "$812C":
				direct_store_hook_found = true
	if not hook_frame_found or direct_store_hook_found:
		return _fail("Muted FCEUX hook comparison must show ID-2 entry around frame 7409 while retaining the `$812C` hook gap.")
	return true


func _fail(message: String) -> bool:
	printerr("FAIL: " + message)
	return false
