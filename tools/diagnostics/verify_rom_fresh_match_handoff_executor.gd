extends SceneTree

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_handoff_executor.gd")


func _initialize() -> void:
	if not _verify_handoff_executor():
		quit(1)
		return
	print("PASS: fresh KICK OFF handoff derives the 664-byte $AA06 zero fill ($0468-$06FF), cleanup/audio/mapper plans, and pending task writes.")
	print("LIMIT: C557 is reached only after four named Godot-side helper results; no helper bytecode, live RAM, or general 6502 is executed.")
	quit(0)


func _verify_handoff_executor() -> bool:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		return _fail("Executor rejected the packaged source spans: " + executor.error_message)
	var status: Dictionary = executor.get_status()
	if bool(status.get("does_execute_6502", true)) \
			or bool(status.get("does_execute_presentation_helpers", true)) \
			or bool(status.get("does_apply_effects_to_live_ram", true)):
		return _fail("The handoff executor must report its bounded write-plan-only scope.")

	var natural_blocked: Dictionary = executor.execute_cutscene2_return("natural")
	if not bool(natural_blocked.get("ok", false)) \
			or String(natural_blocked.get("status", "")) != "blocked_on_helper" \
			or int(natural_blocked.get("final_source_pc", -1)) != 0x82DF \
			or int(natural_blocked.get("pending_source_pc", -1)) != 0x82DF \
			or String(natural_blocked.get("pending_helper_id", "")) != "cutscene_cleanup_9ba0" \
			or bool(natural_blocked.get("c557_reached", true)):
		return _fail("Natural completion must stop at its unresolved `$82DF → $9BA0` effect boundary.")
	if not _has_write(natural_blocked.get("task_writes", []), 0x0005, 0, 0x82C8) \
			or not _has_write(natural_blocked.get("task_writes", []), 0x004C, 0, 0x82D8):
		return _fail("Common cleanup did not emit its source-addressed scheduler/task writes.")
	var audio: Variant = natural_blocked.get("audio_stop_request")
	if not audio is Dictionary or int(audio.get("source_pc", -1)) != 0x82DC \
			or int(audio.get("queue_address", -1)) != 0x0700 \
			or int(audio.get("value", -1)) != 1 \
			or bool(audio.get("applied", true)):
		return _fail("Common completion must emit the unapplied ROM `$0700=$01` stop request.")

	var bad_kind: Dictionary = executor.execute_cutscene2_return("confirm")
	if bool(bad_kind.get("ok", true)) or bool(bad_kind.get("c557_reached", true)) \
			or not bad_kind.get("task_writes", []).is_empty():
		return _fail("Unsupported completion input must refuse without producing route effects.")

	var partial_results: Array = [_helper_result("cutscene_cleanup_9ba0", 0x82DF, 0x9BA0)]
	var partial: Dictionary = executor.execute_cutscene2_return("select", partial_results)
	if not bool(partial.get("ok", false)) \
			or int(partial.get("final_source_pc", -1)) != 0xA2AF \
			or int(partial.get("pending_source_pc", -1)) != 0xA2AF \
			or String(partial.get("pending_helper_id", "")) != "fresh_setup_palette_fade_99f0" \
			or bool(partial.get("c557_reached", true)):
		return _fail("A named cutscene-clear effect must advance only to the next unresolved `$A2AF` helper.")
	if partial.get("accepted_helper_results", []).size() != 1 \
			or not bool(partial.get("helper_results_are_external_effect_receipts", false)) \
			or bool(partial.get("helper_bytecode_executed", true)):
		return _fail("External helper receipts must remain labeled and must not imply source bytecode execution.")

	var invalid_receipt: Array = [{
		"helper_id": "cutscene_cleanup_9ba0", "source_pc": 0x82DF, "target_pc": 0x9BA0,
		"status": "applied", "effect_provider": "", "effect_summary": "",
	}]
	var still_blocked: Dictionary = executor.execute_cutscene2_return("natural", invalid_receipt)
	if int(still_blocked.get("pending_source_pc", -1)) != 0x82DF \
			or bool(still_blocked.get("c557_reached", true)):
		return _fail("A blank/unattributed helper receipt must not advance source control flow.")

	var all_results: Array = [
		_helper_result("cutscene_cleanup_9ba0", 0x82DF, 0x9BA0),
		_helper_result("fresh_setup_palette_fade_99f0", 0xA2AF, 0x99F0),
		_helper_result("fresh_setup_ppu_clear_98a0", 0xA2B2, 0x98A0),
		_helper_result("fresh_setup_oam_clear_9b7f", 0xA2B5, 0x9B7F),
	]
	var complete: Dictionary = executor.execute_cutscene2_return("natural", all_results)
	if not bool(complete.get("ok", false)) \
			or String(complete.get("status", "")) != "modeled_handoff_reached" \
			or int(complete.get("c557_source_pc", -1)) != 0xC557 \
			or not bool(complete.get("c557_reached", false)) \
			or bool(complete.get("c557_reached_in_live_runtime", true)) \
			or not bool(complete.get("c557_is_reached_in_this_source_plan_only", false)) \
			or int(complete.get("final_source_pc", -1)) != 0xC6BE \
			or int(complete.get("pending_source_pc", -1)) != 0xC6BE:
		return _fail("All four named helper results must model the verified `$C557 → $C6BE` handoff without claiming live-route integration.")
	if complete.get("task_writes", []).size() != 13 \
			or complete.get("pending_task_writes", []).size() != 12 \
			or complete.get("accepted_helper_results", []).size() != 4:
		return _fail("Cleanup or pending scheduler task-write count differs from the byte-derived source recipe.")
	var zero_fills: Array = complete.get("zero_fill_writes", [])
	if zero_fills.size() != 3 \
			or not _has_range(zero_fills, 0x0001, 0x0018, 24) \
			or not _has_range(zero_fills, 0x003A, 0x00DF, 166) \
			or not _has_range(zero_fills, 0x0468, 0x06FF, 664):
		return _fail("Source-derived wrapped RAM fills or `$AA06` range/count differ.")
	if not _has_write(complete.get("ram_writes", []), 0x00EC, 0x00, 0xAA10) \
			or not _has_write(complete.get("ram_writes", []), 0x00ED, 0x07, 0xAA14):
		return _fail("The `$AA06` loop must end at `$0700` after 664 writes.")
	if not _has_mapper_event(complete.get("mapper_events", []), 0xFF19, 0xE001) \
			or not _has_mapper_event(complete.get("mapper_events", []), 0xFFE0, 0xE000):
		return _fail("The 16-bit indexed-store wrap must preserve the `$FF19/$FFE0` MMC3 bus effects.")
	var select_complete: Dictionary = executor.execute_cutscene2_return("select", all_results)
	if not bool(select_complete.get("c557_reached", false)) \
			or select_complete.get("task_writes", []) != complete.get("task_writes", []) \
			or select_complete.get("zero_fill_writes", []) != complete.get("zero_fill_writes", []) \
			or select_complete.get("audio_stop_request", {}) != complete.get("audio_stop_request", {}):
		return _fail("Natural and Select exits must share the same decoded cleanup effects through the handoff.")
	for pending_variant in complete.get("pending_task_writes", []):
		if pending_variant is Dictionary and bool(pending_variant.get("applied", true)):
			return _fail("C6BE task-slot stores are pending after the handoff and must not be marked applied.")
	return true


func _helper_result(helper_id: String, source_pc: int, target_pc: int) -> Dictionary:
	return {
		"helper_id": helper_id,
		"source_pc": source_pc,
		"target_pc": target_pc,
		"status": "applied",
		"effect_provider": "focused_verifier_fixture",
		"effect_summary": "Synthetic external effect result for exercising the bounded handoff contract.",
	}


func _has_write(writes: Array, address: int, value: int, source_pc: int) -> bool:
	for write_variant in writes:
		if write_variant is Dictionary \
				and int(write_variant.get("address", -1)) == address \
				and int(write_variant.get("value", -1)) == value \
				and int(write_variant.get("source_pc", -1)) == source_pc:
			return true
	return false


func _has_range(ranges: Array, start_address: int, end_address: int, count: int) -> bool:
	for range_variant in ranges:
		if range_variant is Dictionary \
				and int(range_variant.get("start_address", -1)) == start_address \
				and int(range_variant.get("end_address_inclusive", -1)) == end_address \
				and int(range_variant.get("count", -1)) == count \
				and int(range_variant.get("value", -1)) == 0 \
				and not bool(range_variant.get("applied", true)):
			return true
	return false


func _has_mapper_event(events: Array, address: int, register: int) -> bool:
	for event_variant in events:
		if event_variant is Dictionary \
				and int(event_variant.get("address", -1)) == address \
				and int(event_variant.get("mirrored_register", -1)) == register \
				and int(event_variant.get("value", -1)) == 0:
			return true
	return false


func _fail(message: String) -> bool:
	printerr("FAIL: " + message)
	return false
