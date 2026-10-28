extends SceneTree
## Confirms the earliest `$35/$3A` callback is not executable from the
## currently available source-owned scheduler state. No trace frame, endpoint
## RAM, or hand-seeded callback/task state is supplied.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const PERIOD_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const ENTRY_CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const SCENARIO_READER := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_verify_rom_scenario_and_callback_bytes()
	_verify_first_source_scheduler_context()
	if _failures.is_empty():
		print("PASS: source-derived slot-$05 context executes the bounded `$D11E->$DAAA` period slice; `$35/$3A` data resolves to `$8327`.")
		print("LIMIT: no `$DAAA-$DAD8` helper continuation, `$DAD8` scenario start, `$8097` task seed, slot `$15` dispatch, or callback execution was manufactured.")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _verify_rom_scenario_and_callback_bytes() -> void:
	var scenario: Dictionary = SCENARIO_READER.read_project_scenario(0x35, {"continuation_depth": 0})
	_check(int(scenario.get("terminal_status", -1)) == SCENARIO_READER.ParseStatus.SOURCE_TERMINATED,
		"Hash-checked bank-$10 scenario `$35` parses to its depth-zero root terminator.")
	var event: Dictionary = {}
	for token_variant in scenario.get("tokens", []):
		if token_variant is Dictionary and str(token_variant.get("kind", "")) == "event_record":
			event = token_variant
			break
	_check(int(event.get("byte_offset", -1)) == 3
		and event.get("raw_bytes", PackedByteArray()) == PackedByteArray([0x02, 0x3A, 0x8F, 0x73]),
		"The first event is source record `02 3A 8F 73`, with callback `$3A` distinct from animation `$8F`.")
	var callback_root := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/"
	var pointer := FileAccess.get_file_as_bytes(callback_root + "bank_0b_event_3a_pointer_boundary.bin")
	var stream := FileAccess.get_file_as_bytes(callback_root + "bank_0b_event_3a_stream.bin")
	var vector := FileAccess.get_file_as_bytes(callback_root + "bank_0b_dispatch_vector_81a7.bin")
	_check(pointer == PackedByteArray([0xF3, 0x89, 0xF6, 0x89])
	and stream == PackedByteArray([0x02, 0x00, 0x42])
	and vector.size() >= 5
	and int(vector[3]) == 0x27 and int(vector[4]) == 0x83,
		"Preserved callback bytes resolve `$3A→$89F3→02 00 42→$81A7 index 0→$8327` (data resolution only).")


func _verify_first_source_scheduler_context() -> void:
	var scheduler: RefCounted = SCHEDULER_SCRIPT.new()
	_check(bool(scheduler.call("configure_from_project_sources")),
		"Task scheduler accepts the hash-checked ROM-derived source spans.")
	if not _failures.is_empty():
		return
	var bootstrap: Dictionary = scheduler.call("initialize_fresh_game_bootstrap")
	_check(bool(bootstrap.get("ok", false))
		and bootstrap.get("root_slots", []) == [0x01, 0x05, 0x09],
		"Fresh-game bootstrap derives only root task slots `$01/$05/$09`.")
	var first_scan: Dictionary = scheduler.call("scan_ready_tasks_once")
	_check(bool(first_scan.get("ok", false))
		and int(first_scan.get("selected_slot_base", -1)) == 0x01,
		"The first actual scheduler scan selects source-seeded slot `$01`.")
	var slot1_dispatch: Dictionary = scheduler.call("dispatch_pending_task", 0x01)
	_check(bool(slot1_dispatch.get("ok", false)) and int(slot1_dispatch.get("pc", -1)) == 0xCA22,
		"Slot `$01` dispatch restores the ROM continuation `$CA22`.")
	var slot1_yield: Dictionary = scheduler.call("execute_root_slot01_startup_to_first_yield")
	_check(bool(slot1_yield.get("ok", false))
		and int(slot1_yield.get("resume_pc", -1)) == 0xCA52,
		"The bounded source runner executes slot `$01` through its real `$CA4F` yield.")
	var slot5_scan: Dictionary = scheduler.call("scan_ready_tasks_once")
	_check(bool(slot5_scan.get("ok", false))
		and int(slot5_scan.get("selected_slot_base", -1)) == 0x05,
		"After slot `$01` yields, the source scheduler selects slot `$05`.")
	var slot5_dispatch: Dictionary = scheduler.call("dispatch_pending_task", 0x05)
	_check(bool(slot5_dispatch.get("ok", false))
		and int(slot5_dispatch.get("pc", -1)) == 0xD11E
		and int(slot5_dispatch.get("sp", -1)) == 0x52,
		"Slot `$05` dispatch produces only its source entry `$D11E` and stack pointer.")
	var slot15_record := PackedByteArray()
	for record_variant in scheduler.call("get_status").get("task_slots", []):
		if record_variant is Dictionary and int(record_variant.get("slot_base", -1)) == 0x15:
			slot15_record = record_variant.get("bytes", PackedByteArray())
	_check(slot15_record == PackedByteArray([0x00, 0x00, 0x00, 0x00]),
		"The actual scheduler state has no `$0015` callback task before scenario setup executes.")

	var entry_builder = ENTRY_CONTEXT_BUILDER.new()
	_check(bool(entry_builder.configure_from_project_sources()),
		"Hash-checked reset/title/selector and scheduler bytes configure the typed entry-context builder.")
	if not _failures.is_empty():
		return
	var entry_context = entry_builder.build_fresh_kickoff_context()
	_check(entry_context != null,
		"Source formulas and the bounded scheduler projection produce the fresh slot-$05 context.")
	if not _failures.is_empty():
		return
	_check(int(entry_context.match_index) == 0 and int(entry_context.period_0027) == 0
		and int(entry_context.opponent_id_002b) == 3
		and int(entry_context.task_slot_base) == 0x05
		and int(entry_context.entry_pc) == 0xD11E
		and int(entry_context.entry_sp) == 0x52,
		"The typed source context matches match-0 period/opponent and the slot-$05 entry contract.")

	var period_task: RefCounted = PERIOD_TASK_SCRIPT.new()
	_check(bool(period_task.call("configure_from_project_sources")),
		"The bounded slot-$05 ROM instruction slice is available.")
	var period_result: Dictionary = period_task.call("execute_fresh_match_zero",
		entry_context.to_period_task_inputs())
	_check(bool(period_result.get("ok", false))
		and int(period_result.get("exit_pc", -1)) == 0xDAAA
		and int(period_result.get("ram", {}).get("$0629", -1)) == 0,
		"The typed source inputs execute the verified slot-$05 bytes through `$DAAA` and produce `$0629=0`.")
	# Do not invoke seed_scenario_callback_task here: the DAD8/$8097 caller and
	# its helper/task continuation are still not executed by source code.


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
