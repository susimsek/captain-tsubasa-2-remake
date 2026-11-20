extends SceneTree

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ENTRY_CONTEXT_BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const SELECTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const SOURCE_RAM_SCRIPT := preload("res://scripts/gameplay/rom_source_ram_image.gd")
const STAMINA_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_stamina_initializer.gd")
const EXPECTED_MATCH_00_ENERGY: Array[int] = [400, 400, 400, 400, 400, 400, 400, 400, 416, 748, 408]


func _initialize() -> void:
	var selector_result := _build_selector_result()
	if selector_result.is_empty():
		return
	var stamina_result := _build_stamina_result(selector_result)
	if stamina_result.is_empty():
		return
	var scheduler: Variant = SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources():
		_fail("Scheduler ROM-source setup failed: " + scheduler.error_message)
		return
	if not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		_fail("Scheduler fresh-game bootstrap failed: " + scheduler.error_message)
		return
	var roster_adoption: Dictionary = scheduler.apply_rom_match_selector_roster(selector_result)
	if not bool(roster_adoption.get("ok", false)):
		_fail("Live scheduler did not adopt the selector's eleven ROM roster writes: " + scheduler.error_message)
		return
	var before: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var before_records: Array = scheduler.get_status().get("task_slots", [])
	var adoption: Dictionary = scheduler.apply_rom_fresh_match_stamina_initialization(stamina_result)
	if not bool(adoption.get("ok", false)):
		_fail("Live scheduler rejected the ROM `$DB62` energy writes: " + scheduler.error_message)
		return
	var after: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var ram: PackedByteArray = after.get("ram_image", PackedByteArray())
	if ram.size() != 0x800 or ram.slice(0x0100, 0x0200) != before.get("stack_page", PackedByteArray()) \
			or scheduler.get_status().get("task_slots", []) != before_records \
			or int(adoption.get("energy_write_count", -1)) != 22:
		_fail("Stamina adoption changed scheduler-owned task/stack state or returned an invalid write count.")
		return
	var rows: Array = stamina_result.get("home_player_energy", [])
	if rows.size() != EXPECTED_MATCH_00_ENERGY.size():
		_fail("The ROM `$DB62` initializer did not resolve all eleven match-00 home records.")
		return
	for row_variant in rows:
		if not row_variant is Dictionary:
			_fail("Stamina initializer returned a malformed test row.")
			return
		var row: Dictionary = row_variant
		var address := int(row.get("record_address", -1))
		var energy := int(row.get("maximum_energy", -1))
		var slot := int(row.get("slot", -1))
		if slot < 0 or slot >= EXPECTED_MATCH_00_ENERGY.size() \
				or energy != EXPECTED_MATCH_00_ENERGY[slot] \
				or int(ram[address]) != int(row.get("player_id", -1)) \
				or (int(ram[address + 1]) | (int(ram[address + 2]) << 8)) != energy:
			_fail("Live scheduler record slot %d at $%04X does not contain the ROM `$DB62` result." % [slot, address])
			return
	if ram.slice(0x0348, 0x034C) != PackedByteArray([0x08, 0x90, 0x01, 0x00]):
		_fail("The source-derived slot-6 record did not become `08 90 01 00` ($400 energy).")
		return
	var rejected_scheduler: Variant = SCHEDULER_SCRIPT.new()
	if not rejected_scheduler.configure_from_project_sources() \
			or not bool(rejected_scheduler.initialize_fresh_game_bootstrap().get("ok", false)) \
			or not bool(rejected_scheduler.apply_rom_match_selector_roster(selector_result).get("ok", false)):
		_fail("Could not prepare the negative adoption case.")
		return
	var captured_result := stamina_result.duplicate(true)
	captured_result["trace_state_used"] = true
	var rejected: Dictionary = rejected_scheduler.apply_rom_fresh_match_stamina_initialization(captured_result)
	var rejected_ram: PackedByteArray = rejected_scheduler.get_task_boundary_snapshot(0x05).get("ram_image", PackedByteArray())
	if bool(rejected.get("ok", false)) or rejected_ram.slice(0x0348, 0x034C) != PackedByteArray([0x08, 0, 0, 0]):
		_fail("Scheduler accepted trace-marked stamina state or partially changed RAM before rejection.")
		return
	print("PASS: source-derived `$DB62` initializer contributes only 22 energy writes to the live scheduler RAM.")
	print("PASS: all eleven record energy words match the ROM `$80D1` 24-byte profile path; slot 6 is `08 90 01 00`.")
	print("PASS: scheduler task records and stack remain unchanged; trace-marked receipts are rejected without partial writes.")
	quit(0)


func _build_selector_result() -> Dictionary:
	var selector: Variant = SELECTOR_SCRIPT.new()
	if not selector.configure_from_project_sources():
		_fail("Could not configure the ROM selector: " + selector.error_message)
		return {}
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	stack[0xFC] = 0xFC
	stack[0xFD] = 0x80
	var source_call := {"caller_pc": 0x80FA, "target_pc": 0xA20F,
		"return_pc": 0x80FD, "source_event_id": "scheduler_stamina_verifier_selector",
		"pre_call_sp": 0xFD, "stack_page": stack}
	var cpu_state := {"pc": 0xA20F, "sp": 0xFB, "a": 0x87,
		"x": 0x02, "y": 0, "p": 0xA4}
	var ram_before := {0x0022: 0x80, 0x0023: 0x87, 0x0025: 0x02, 0x0026: 0}
	var result: Dictionary = selector.execute_source_call(source_call, cpu_state, ram_before)
	if not bool(result.get("ok", false)):
		_fail("ROM selector execution failed: " + String(result.get("error", "unknown error")))
		return {}
	return result


func _build_stamina_result(selector_result: Dictionary) -> Dictionary:
	var builder: Variant = ENTRY_CONTEXT_BUILDER_SCRIPT.new()
	if not builder.configure_from_project_sources():
		_fail("Could not configure reset source receipts: " + builder.error_message)
		return {}
	var source_ram: Variant = SOURCE_RAM_SCRIPT.new()
	var reset_addresses: Array[int] = [0x0026, 0x044D]
	for slot in range(11):
		reset_addresses.append(0x0303 + slot * 0x0C)
	var reset_result: Dictionary = builder.build_reset_ram_zero_write_receipt(
		"stamina_scheduler_verifier_reset", reset_addresses)
	if not source_ram.merge_executor_result("verifier_reset", reset_result) \
			or not source_ram.merge_executor_result("verifier_selector", selector_result):
		_fail("Could not compose reset and selector writes for the ROM stamina source execution: " + source_ram.error_message)
		return {}
	var stamina: Variant = STAMINA_SCRIPT.new()
	if not stamina.configure_from_project_sources():
		_fail("Could not configure ROM stamina sources: " + stamina.error_message)
		return {}
	var result: Dictionary = stamina.execute_from_811f(source_ram,
		{"pc": 0x811F, "a": 0, "x": 0, "y": 3, "sp": 0x28}, 7409)
	if not bool(result.get("ok", false)):
		_fail("ROM `$DB62` stamina execution failed: " + String(result.get("error", stamina.error_message)))
		return {}
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
