extends SceneTree

const Source = preload("res://scripts/gameplay/rom_field_entry_window_packet_source.gd")
const EntryBuilder = preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PeriodTask = preload("res://scripts/gameplay/rom_fresh_period_task.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source = Source.new()
	var unresolved: Dictionary = source.build_descriptor_00()
	assert(bool(unresolved.get("ok", false)), str(source.last_error))
	assert(not bool(unresolved["source_inputs_ready"]))
	assert(not bool(unresolved["packet_data_complete"]), "$EF/$F0 require the ROM-owned fresh-period result.")
	assert(not bool(unresolved["queue_submission_ready"]), "Do not queue rows with missing handler inputs.")
	assert(int(unresolved["unresolved_source_tokens"].size()) == 2)
	assert(unresolved["ready_flag_0515"] == "caller-owned; this component never writes it")
	assert(not bool(unresolved["descriptor_01_supported"]))

	var fresh_period_result := _build_fresh_period_result()
	assert(not fresh_period_result.is_empty(), "Could not derive descriptor-$00 handler inputs from source code.")
	var result: Dictionary = source.build_descriptor_00(fresh_period_result)
	assert(bool(result.get("ok", false)), str(source.last_error))
	assert(bool(result["source_inputs_ready"]))
	assert(int(result["descriptor_id"]) == 0x00)
	assert(int(result["progress_packet_count"]) == 5)
	assert(bool(result["packet_data_complete"]), "$EF/$F0 source rows should resolve for the supported fresh match.")
	assert(bool(result["queue_submission_ready"]), "All five complete source rows should be queueable.")

	var records: Array = result["packet_records"]
	var expected_addresses: Array[int] = [0x2221, 0x2241, 0x2261, 0x2281, 0x22A1]
	for index in expected_addresses.size():
		assert(int(records[index]["ppu_address"]) == expected_addresses[index],
			"Descriptor $00 progress address differs at row %d." % index)
		var packet: PackedByteArray = records[index]["packet"]
		assert(packet.size() == 10 and int(packet[0]) == 7,
			"Each descriptor-$00 queue record must contain a 7-tile payload.")

	assert(records[0]["packet"] == PackedByteArray([0x07, 0x21, 0x22, 0, 0, 0, 0, 0, 0, 0]))
	assert(records[1]["packet"] == PackedByteArray([
		0x07, 0x41, 0x22, 0x9C, 0xA8, 0xA8, 0xA8, 0xA8, 0xA8, 0x9D,
	]))
	assert(records[2]["packet"] == PackedByteArray([
		0x07, 0x61, 0x22, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAB,
	]))
	assert(records[3]["packet"] == PackedByteArray([
		0x07, 0x81, 0x22, 0xAA, 0x36, 0x33, 0x77, 0x33, 0x33, 0xAB,
	]))
	assert(records[4]["packet"] == PackedByteArray([
		0x07, 0xA1, 0x22, 0x9E, 0xA9, 0xA9, 0xA9, 0xA9, 0xA9, 0x9F,
	]))
	assert(bool(records[0]["complete"]) and bool(records[1]["complete"]))
	assert(bool(records[2]["complete"]) and bool(records[3]["complete"]))
	assert(bool(records[4]["complete"]))
	assert(int(result["unresolved_source_tokens"].size()) == 0)
	assert(int(result["complete_packet_records"].size()) == 5)
	assert(int(records[1]["source_token_output"]["caller_$0027"]) == 0)
	assert(records[1]["source_token_output"]["emitted_tiles"].is_empty())
	assert(int(records[3]["source_token_output"]["source_clock_value"]) == 0xB4)
	assert(int(records[3]["source_token_output"]["divide_by_six_quotient"]) == 30)
	assert(int(records[3]["source_token_output"]["divide_by_six_remainder"]) == 0)

	var altered_result := fresh_period_result.duplicate(true)
	(altered_result["ram"] as Dictionary)["$05F7"] = 0xB3
	var rejected_inputs: Dictionary = source.build_descriptor_00(altered_result)
	assert(bool(rejected_inputs.get("ok", false)))
	assert(not bool(rejected_inputs["queue_submission_ready"]), "A mismatched ROM caller value must not produce queueable rows.")
	assert(int(rejected_inputs["unresolved_source_tokens"].size()) == 2)
	print("Field-entry descriptor-$00 verification passed: ROM-backed $EF/$F0 handlers produce five queueable $04A5 records only for the sourced fresh-period inputs; absent/tampered inputs fail closed.")
	quit(0)


func _build_fresh_period_result() -> Dictionary:
	var entry_builder = EntryBuilder.new()
	if not entry_builder.configure_from_project_sources():
		push_error("Entry source setup failed: " + entry_builder.error_message)
		return {}
	var context = entry_builder.build_fresh_kickoff_context()
	if context == null:
		push_error("Fresh KICK OFF context derivation failed: " + entry_builder.error_message)
		return {}
	var period_task = PeriodTask.new()
	if not period_task.configure_from_project_sources():
		push_error("Period source setup failed: " + period_task.error_message)
		return {}
	var result: Dictionary = period_task.execute_fresh_match_zero(context.to_period_task_inputs())
	if not bool(result.get("ok", false)):
		push_error("Fresh-period source execution failed: " + period_task.error_message)
		return {}
	return result
