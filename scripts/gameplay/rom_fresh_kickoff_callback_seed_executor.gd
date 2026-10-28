extends RefCounted
class_name RomFreshKickoffCallbackSeedExecutor
## Source-driven composition of the first fresh-KICK-OFF bank-$10 event
## record with its verified `$8097 → $C50F → $CAE7` callback-task seed.
## This stops before scheduler dispatch or callback-handler execution: the
## preceding root-task bodies and NMI-ready deliveries are still caller-owned.

const SCENARIO_READER := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const TASK_SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const FIRST_SCENARIO_ID := 0x35
const CALLBACK_TASK_SETUP_PC := 0x8097
const FIRST_EVENT_BYTES := [0x02, 0x3A, 0x8F, 0x73]

var error_message := ""
var _scheduler: RefCounted
var _initialized := false
var _scenario_event_accepted := false


func configure() -> bool:
	error_message = ""
	_scheduler = TASK_SCHEDULER.new()
	if not bool(_scheduler.call("configure_from_project_sources")):
		return _fail("ROM task/NMI source spans failed configuration: " + str(_scheduler.get("error_message")))
	var bootstrap: Dictionary = _scheduler.call("initialize_fresh_game_bootstrap")
	if not bool(bootstrap.get("ok", false)):
		return _fail("Fresh-game root-task bootstrap could not be derived from ROM source.")
	_initialized = true
	_scenario_event_accepted = false
	return true


## Accept the first event record only when the caller identifies the decoded
## scenario reader's `$8097` record-setup callsite. This seeds the exact task
## context but does not claim that the scheduler has dispatched it.
func accept_first_scenario_event(source_caller_pc: int = CALLBACK_TASK_SETUP_PC) -> Dictionary:
	error_message = ""
	if not _initialized:
		return _failure("Configure and source-initialize the scheduler before accepting a scenario event.")
	if source_caller_pc != CALLBACK_TASK_SETUP_PC:
		return _failure("Only the byte-verified bank-$10 `$8097` callback-task setup callsite is supported.")
	if _scenario_event_accepted:
		return _failure("The first `$35` event record has already seeded its callback task.")

	var scenario: Dictionary = SCENARIO_READER.read_project_scenario(FIRST_SCENARIO_ID,
		{"continuation_depth": 0})
	if int(scenario.get("terminal_status", -1)) != SCENARIO_READER.ParseStatus.SOURCE_TERMINATED:
		return _failure("Scenario `$35` did not terminate at its validated root `$FB`.")
	var records: Array[Dictionary] = []
	for token_variant in scenario.get("tokens", []):
		if token_variant is Dictionary and str(token_variant.get("kind", "")) == "event_record":
			records.append(token_variant)
	if records.size() != 1:
		return _failure("Scenario `$35` no longer contains exactly one decoded first-event record.")
	var record: Dictionary = records[0]
	var raw: PackedByteArray = record.get("raw_bytes", PackedByteArray())
	if raw != PackedByteArray(FIRST_EVENT_BYTES) or int(record.get("byte_offset", -1)) != 3:
		return _failure("Scenario `$35` first event is not its ROM-derived `02 3A 8F 73` record at offset 3.")

	var seed: Dictionary = _scheduler.call("seed_scenario_callback_task", source_caller_pc)
	if not bool(seed.get("ok", false)):
		return _failure("ROM callback task seed failed: " + str(_scheduler.get("error_message")))
	_scenario_event_accepted = true
	var next_scan: Dictionary = _scheduler.call("scan_ready_tasks_once")
	if not bool(next_scan.get("ok", false)):
		return _failure("Scheduler could not evaluate the source-seeded task records.")
	return {
		"ok": true,
		"status": "first_event_task_seeded_waiting_for_root_task_execution",
		"scenario_id": FIRST_SCENARIO_ID,
		"scenario_record_offset": int(record.get("byte_offset", -1)),
		"scenario_record_raw": raw,
		"event_selector_0524": int(raw[1]),
		"animation_selector_0528": int(raw[2]),
		"animation_parameter_0529": int(raw[3]),
		"task_setup_callsite_pc": source_caller_pc,
		"callback_task_seed": seed,
		"first_scheduler_decision": next_scan,
		"callback_handler_reached": false,
		"incoming_05cd": null,
		"remaining_source_boundary": "The verified bootstrap leaves root task slots $01/$05/$09 ready; their bodies, the scenario task's later scheduler dispatch, callback $3A, and its incoming shared $05CD are not executed by this component.",
		"trace_data_used_as_runtime_input": false,
	}


func get_scheduler_status() -> Dictionary:
	if not _initialized:
		return {"configured": false, "error": error_message}
	return _scheduler.call("get_status")


## Resume slot `$15` only after the ROM scheduler has actually selected it.
## The current route increment deliberately reaches no such decision yet.
func dispatch_callback_task_from_scheduler() -> Dictionary:
	if not _initialized or not _scenario_event_accepted:
		return _failure("A source-seeded callback task and initialized scheduler are required before dispatch.")
	var dispatch: Dictionary = _scheduler.call("dispatch_pending_task", 0x15)
	if not bool(dispatch.get("ok", false)):
		return _failure("The ROM scheduler has not selected callback slot `$15`: " + str(_scheduler.get("error_message")))
	return dispatch


func _failure(message: String) -> Dictionary:
	_fail(message)
	return {"ok": false, "status": "source_execution_refused", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false
