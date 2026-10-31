extends SceneTree

const Source = preload("res://scripts/gameplay/rom_field_entry_window_01_packet_source.gd")
const Selector = preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const EntryBuilder = preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PeriodTask = preload("res://scripts/gameplay/rom_fresh_period_task.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source = Source.new()
	var unresolved: Dictionary = source.build_descriptor_01()
	assert(bool(unresolved.get("ok", false)), str(source.last_error))
	assert(not bool(unresolved["source_inputs_ready"]))
	assert(not bool(unresolved["packet_data_complete"]), "ED/EE inputs must not be guessed.")
	assert(not bool(unresolved["queue_submission_ready"]))
	assert(int(unresolved["unresolved_source_tokens"].size()) == 4)

	var selector_result := _build_selector_result()
	var period_result := _build_fresh_period_result()
	assert(not selector_result.is_empty(), "Could not execute the source match selector.")
	assert(not period_result.is_empty(), "Could not derive the source fresh-period state.")
	var result: Dictionary = source.build_descriptor_01(selector_result, period_result)
	assert(bool(result.get("ok", false)), str(source.last_error))
	assert(bool(result["known_dynamic_inputs_ready"]))
	assert(not bool(result["source_inputs_ready"]))
	assert(not bool(result["packet_data_complete"]))
	assert(not bool(result["queue_submission_ready"]))
	assert(not bool(result["runtime_rom_dependency"]))
	assert(result["ready_flag_0515"] == "caller-owned; this source does not write it")
	assert(result["source_inputs"] == {"$002A": 0, "$002B": 3, "$0628": 0, "$0629": 0, "$003C": -1})
	var records: Array = result["packet_records"]
	assert(records.size() == 8)
	var expected_addresses: Array[int] = [0x22C1, 0x22E1, 0x2301, 0x2321,
		0x2341, 0x2361, 0x2381, 0x23A1]
	for index in expected_addresses.size():
		assert(int(records[index]["ppu_address"]) == expected_addresses[index])
		var packet: PackedByteArray = records[index]["packet"]
		assert(packet.size() == 10 and int(packet[0]) == 7)
	assert(records[1]["packet"] == PackedByteArray([
		0x07, 0xE1, 0x22, 0xAA, 0xDF, 0xCD, 0xDB, 0x00, 0x00, 0xAB,
	]))
	assert(records[3]["packet"] == PackedByteArray([
		0x07, 0x21, 0x23, 0xAA, 0xD2, 0xD8, 0xE1, 0x00, 0x00, 0xAB,
	]))
	assert(not bool(records[1]["complete"]) and not bool(records[3]["complete"]))
	assert(records[1]["source_token_outputs"].size() == 1)
	assert(records[3]["source_token_outputs"].size() == 1)
	assert(int(result["source_token_outputs"][0]["name_pointer"]) == 0xF776)
	assert(int(result["source_token_outputs"][1]["name_pointer"]) == 0xF785)
	assert(int(result["unresolved_source_tokens"].size()) == 2)
	assert(int(result["complete_packet_records"].size()) == 6)
	assert(str(result["unresolved_source_tokens"][0]["needs"]).contains("$003C"))

	var wrong_team := selector_result.duplicate(true)
	(wrong_team["ram_after"] as Dictionary)[0x002B] = 4
	var refused_team: Dictionary = source.build_descriptor_01(wrong_team, period_result)
	assert(bool(refused_team.get("ok", false)))
	assert(not bool(refused_team["queue_submission_ready"]), "Unsupported team IDs must remain unqueueable.")

	var wrong_period := period_result.duplicate(true)
	(wrong_period["ram"] as Dictionary)["$0629"] = 1
	var refused_period: Dictionary = source.build_descriptor_01(selector_result, wrong_period)
	assert(bool(refused_period.get("ok", false)))
	assert(not bool(refused_period["queue_submission_ready"]), "Unsupported $EE inputs must remain unqueueable.")
	print("PASS: descriptor-$01 ED team rows derive ROM tiles; EE rows remain unqueueable until ROM caller RAM $003C is sourced. Missing/unsupported inputs fail closed.")
	quit(0)


func _build_selector_result() -> Dictionary:
	var selector = Selector.new()
	if not selector.configure_from_project_sources():
		push_error("Selector source setup failed: " + selector.error_message)
		return {}
	var pre_call_sp := 0xFD
	var entry_sp := (pre_call_sp - 2) & 0xFF
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	stack[(entry_sp + 1) & 0xFF] = 0xFC
	stack[(entry_sp + 2) & 0xFF] = 0x80
	var source_call := {
		"caller_pc": 0x80FA, "target_pc": 0xA20F, "return_pc": 0x80FD,
		"source_event_id": "verifier_fixture_only_source_call_80FA",
		"pre_call_sp": pre_call_sp, "stack_page": stack,
	}
	var cpu_state := {"pc": 0xA20F, "sp": entry_sp, "a": 0x87, "x": 2, "y": 0, "p": 0xA4}
	var ram_before := {0x0022: 0x80, 0x0023: 0x87, 0x0025: 2, 0x0026: 0}
	var result: Dictionary = selector.execute_source_call(source_call, cpu_state, ram_before)
	return result if bool(result.get("ok", false)) else {}


func _build_fresh_period_result() -> Dictionary:
	var entry_builder = EntryBuilder.new()
	if not entry_builder.configure_from_project_sources():
		push_error("Fresh-entry source setup failed: " + entry_builder.error_message)
		return {}
	var context = entry_builder.build_fresh_kickoff_context()
	if context == null:
		push_error("Fresh KICK OFF context derivation failed: " + entry_builder.error_message)
		return {}
	var period_task = PeriodTask.new()
	if not period_task.configure_from_project_sources():
		push_error("Fresh-period source setup failed: " + period_task.error_message)
		return {}
	var result: Dictionary = period_task.execute_fresh_match_zero(context.to_period_task_inputs())
	return result if bool(result.get("ok", false)) else {}
