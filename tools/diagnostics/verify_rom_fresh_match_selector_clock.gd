extends SceneTree

const CLOCK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_clock.gd")
const ASSET_PATH := "res://assets/gameplay/rom_logic/fresh_match_selector_runtime_clock.json"
const EXPECTED_FRAME_BUDGETS := [2999, 27257, 27261, 27258, 27262, 27258, 27260, 27258, 9520]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var clock = CLOCK_SCRIPT.new()
	if not clock.configure_from_project_sources():
		_fail(clock.error_message)
		return
	var status: Dictionary = clock.get_status()
	var entry_status: Dictionary = clock.get_candidate_entry_status_evidence()
	if not bool(status.get("ok", false)) \
			or int(status.get("elapsed_cycles", -1)) != 223242 \
			or int(status.get("interrupt_cycles", -1)) != 19909 \
			or int(status.get("mainline_cycles", -1)) != 203333 \
			or int(status.get("frame_offset_min", -1)) != 0 \
			or int(status.get("frame_offset_max", -1)) != 8:
		_fail("Status must report the complete normalized call cycle contract.")
		return
	if not bool(entry_status.get("ok", false)) \
			or int(entry_status.get("p_known_mask", -1)) != 0x04 \
			or int(entry_status.get("p_known_value", -1)) != 0 \
			or int(entry_status.get("candidate_p_byte", -1)) != 0x30 \
			or bool(entry_status.get("physical_nes_timing_proven", true)):
		_fail("Entry I=clear contract must be ROM-model-derived and limited to one status bit.")
		return
	if bool(status.get("runtime_rom_dependency", true)) \
			or bool(status.get("runtime_emulator_dependency", true)) \
			or bool(status.get("handler_writes_applied", true)) \
			or bool(status.get("return_receipts_applied", true)) \
		or bool(status.get("physical_nes_timing_proven", true)) \
		or bool(status.get("candidate_status_is_runtime_input", true)):
		_fail("Runtime status must preserve independence and the explicit limits.")
		return
	var cumulative_mainline := 0
	for offset in range(EXPECTED_FRAME_BUDGETS.size()):
		var segment: Dictionary = clock.get_frame_segment(offset)
		if not bool(segment.get("ok", false)) \
				or int(segment.get("mainline_cycle_start", -1)) != cumulative_mainline \
				or int(segment.get("mainline_cycle_budget", -1)) != EXPECTED_FRAME_BUDGETS[offset]:
			_fail("Frame offset %d has the wrong mainline budget or cumulative start." % offset)
			return
		cumulative_mainline += EXPECTED_FRAME_BUDGETS[offset]
		if int(segment.get("mainline_cycle_end", -1)) != cumulative_mainline:
			_fail("Frame offset %d has the wrong cumulative mainline end." % offset)
			return
	if cumulative_mainline != 203333:
		_fail("Frame budgets do not sum to 203,333 mainline cycles.")
		return
	var outside_start: Dictionary = clock.get_frame_segment(-1)
	var outside_end: Dictionary = clock.get_frame_segment(9)
	if bool(outside_start.get("ok", true)) or bool(outside_end.get("ok", true)):
		_fail("Out-of-range frame offsets must be rejected.")
		return
	var events: Array[Dictionary] = clock.get_interrupt_events()
	if events.size() != 15:
		_fail("Expected 15 separate ordered interrupt time spans.")
		return
	var prior_accept := -1
	var prior_return := -1
	for event in events:
		if int(event["elapsed_cycle"]) <= prior_accept \
				or int(event["elapsed_cycle"]) < prior_return \
				or int(event["mainline_cycle_at_accept"]) != int(event["mainline_cycle_at_return"]):
			_fail("Interrupt events must remain ordered and excluded from the mainline cursor.")
			return
		prior_accept = int(event["elapsed_cycle"])
		prior_return = int(event["return_cycle"])

	var original_document: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSET_PATH))
	if not original_document is Dictionary:
		_fail("Runtime clock asset could not be reread for malformed-input checks.")
		return
	var malformed: Dictionary = original_document.duplicate(true)
	malformed["source_rom_sha256"] = "0".repeat(64)
	if clock._configure_document(malformed):
		_fail("Runtime consumer accepted a mismatched ROM hash.")
		return
	var noncontiguous: Dictionary = original_document.duplicate(true)
	var noncontiguous_intervals: Array = noncontiguous["frame_intervals"]
	var second_interval: Dictionary = noncontiguous_intervals[1]
	second_interval["elapsed_cycle_start"] = int(second_interval["elapsed_cycle_start"]) + 1
	noncontiguous_intervals[1] = second_interval
	noncontiguous["frame_intervals"] = noncontiguous_intervals
	if clock._configure_document(noncontiguous):
		_fail("Runtime consumer accepted noncontiguous frame intervals.")
		return
	var interrupt_masked: Dictionary = original_document.duplicate(true)
	interrupt_masked["entry_status_contract"]["known_value"] = 0x04
	if clock._configure_document(interrupt_masked):
		_fail("Runtime consumer accepted a candidate entry contract with I set.")
		return
	if not clock.configure_from_project_sources():
		_fail("Valid project asset no longer configures after malformed-input checks: %s" % clock.error_message)
		return
	print("PASS: selector clock validates ROM/call contract, derives offsets 0..8 mainline budgets, and returns 15 ordered interrupt spans.")
	print("PASS: diagnostic model retains only candidate I=clear evidence; runtime status is not sourced from it, and malformed identity/status, noncontiguous intervals, and out-of-range offsets are rejected.")
	print("LIMIT: candidate ROM-only scheduler clock; no handler writes, receipts, full PPU parity, or physical NES timing.")
	quit(0)


func _fail(message: String) -> void:
	push_error("Fresh selector clock verification failed: " + message)
	quit(1)
