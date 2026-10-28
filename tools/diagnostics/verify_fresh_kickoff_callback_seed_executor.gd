extends SceneTree
## Verifies the ROM-derived first `$35` scenario event through its `$8097`
## callback-task seed. Retained FCEUX rows are an independent oracle only.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_callback_seed_executor.gd")
const TRACE_EVENTS := "res://reference/diagnostics/first_command_callback_state_20261028_061906_utc/callback_events.csv"
const TRACE_EVENTS_REPEAT := "res://reference/diagnostics/first_command_callback_state_20261028_061906_utc/callback_events_repeat.csv"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor: RefCounted = EXECUTOR_SCRIPT.new()
	_check(bool(executor.call("configure")),
		"Fresh-game task/NMI source spans configure: " + str(executor.get("error_message")))
	if not _failures.is_empty():
		_finish()
		return

	var event: Dictionary = executor.call("accept_first_scenario_event", 0x8097)
	_check(bool(event.get("ok", false)),
		"Scenario `$35` decodes and seeds the `$8097` callback task: " + str(event.get("error", executor.get("error_message"))))
	if bool(event.get("ok", false)):
		_check(int(event.get("scenario_id", -1)) == 0x35
			and int(event.get("scenario_record_offset", -1)) == 3
			and event.get("scenario_record_raw", PackedByteArray()) == PackedByteArray([0x02, 0x3A, 0x8F, 0x73])
			and int(event.get("event_selector_0524", -1)) == 0x3A,
			"The first callback request derives only from source record `$35:+3 = 02 3A 8F 73`.")
		var seed: Dictionary = event.get("callback_task_seed", {})
		_check(int(seed.get("slot_base", -1)) == 0x15
			and seed.get("record", PackedByteArray()) == PackedByteArray([0xFF, 0xF0, 0x0B, 0x00])
			and int(seed.get("callback_entry_pc", -1)) == 0x8009
			and not bool(seed.get("scheduled", true)),
			"Verified `$8097→$C50F→$CAE7` state seeds slot `$15` and callback entry `$8009` without claiming dispatch.")
		var decision: Dictionary = event.get("first_scheduler_decision", {})
		_check(int(decision.get("selected_slot_base", -1)) == 0x01,
			"Source scheduler order keeps the seeded callback behind the still-ready root slot `$01`.")
		_check(not bool(event.get("callback_handler_reached", true))
			and event.get("incoming_05cd", "not-null") == null
			and str(event.get("status", "")) == "first_event_task_seeded_waiting_for_root_task_execution",
			"The executor stops before `$8327`; it does not guess the callback's incoming `$05CD`.")
		var cannot_skip: Dictionary = executor.call("dispatch_callback_task_from_scheduler")
		_check(not bool(cannot_skip.get("ok", true)),
			"The callback task cannot bypass the scheduler's pending root-task dispatch.")
	_check(_trace_confirms_first_callback_without_seeding_model(),
		"Both retained muted trace passes independently confirm the `$35/$3A→$8327` entry and incoming `$05CD=$00`.")

	if _failures.is_empty():
		print("PASS: source-derived `$35` event `$8097` callback-task seed and scheduler boundary")
		print("LIMIT: root-task bodies/NMI delivery, callback `$3A` dispatch, and incoming `$05CD` producer remain outside this runtime increment")
		_finish(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		_finish(1)


func _trace_confirms_first_callback_without_seeding_model() -> bool:
	var first := _read_first_callback_observation(TRACE_EVENTS)
	var second := _read_first_callback_observation(TRACE_EVENTS_REPEAT)
	if first.is_empty() or first != second:
		return false
	return int(first.get("scenario_id", -1)) == 0x35 \
		and int(first.get("callback_id", -1)) == 0x3A \
		and int(first.get("handler_pc", -1)) == 0x8327 \
		and int(first.get("incoming_05cd", -1)) == 0x00


func _read_first_callback_observation(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var rows := FileAccess.get_file_as_string(path).split("\n", false)
	if rows.size() < 2:
		return {}
	var headers := rows[0].split(",", true)
	var kind_column := headers.find("kind")
	var pc_column := headers.find("pc")
	var scenario_column := headers.find("scenario_0518")
	var callback_column := headers.find("callback_0524")
	var state_column := headers.find("global_05cc_05cd_05ce")
	if mini(kind_column, mini(pc_column, mini(scenario_column, mini(callback_column, state_column)))) < 0:
		return {}
	for index in range(1, rows.size()):
		var columns := rows[index].split(",", true)
		if columns.size() <= maxi(kind_column, maxi(pc_column,
				maxi(scenario_column, maxi(callback_column, state_column)))):
			continue
		if columns[kind_column] != "map_placement_handler_8327" or \
				columns[scenario_column] != "$35" or columns[callback_column] != "$3A":
			continue
		var state := columns[state_column].split(" ", false)
		if state.size() != 3:
			return {}
		return {
			"scenario_id": 0x35,
			"callback_id": 0x3A,
			"handler_pc": 0x8327,
			"incoming_05cd": _hex_byte(state[1]),
		}
	return {}


func _hex_byte(value: String) -> int:
	var normalized := value.trim_prefix("$")
	return normalized.hex_to_int() if normalized.is_valid_hex_number(false) else -1


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish(exit_code: int = 1) -> void:
	quit(exit_code)
