extends SceneTree
## Focused check of the source-backed scenario/callback prefix and F015 loop.
## The muted trace is read only after the source model runs, as an independent
## oracle; captured values never seed the model.

const MODEL_SCRIPT := preload("res://tools/diagnostics/rom_first_command_callback_prefix_model.gd")
const TRACE_DIR := "res://reference/diagnostics/first_command_field_producer_input_trace_20261028_053644_utc/"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model: RefCounted = MODEL_SCRIPT.new()
	var payload := PackedByteArray([0xA5, 0x5A, 0xC3, 0x3C, 0x96, 0x69, 0xF0, 0x0F])
	var prefix: Dictionary = model.call("resolve_scenario44_callback_prefix", payload)
	_check(bool(prefix.get("ok", false)), "ROM-backed scenario-$44 → callback-$70 prefix resolves: " + str(prefix.get("error", model.get("error_message"))))
	var missing_payload: Dictionary = model.call("resolve_scenario44_callback_prefix", PackedByteArray())
	_check(not bool(missing_payload.get("ok", true)),
		"The continuation model requires explicit caller-owned stack payload instead of manufacturing it.")
	if bool(prefix.get("ok", false)):
		var scenario: Dictionary = prefix.get("scenario", {})
		var callback: Dictionary = prefix.get("callback", {})
		_check(int(scenario.get("record_cursor_start", -1)) == 0
			and int(scenario.get("record_cursor_after", -1)) == 4
			and int(scenario.get("root_fb_cursor", -1)) == 4
			and int(scenario.get("source_cursor_after_fb", -1)) == 5,
			"Scenario-$44 record and root-$FB byte cursors advance 0→4→5 from source bytes.")
		_check(int(scenario.get("stack_depth_before_fb", -1)) == 0
			and int(scenario.get("stack_depth_after_fb", -1)) == 0
			and bool(scenario.get("stack_payload_preserved", false)),
			"Source-start depth zero terminates root $FB and leaves caller-owned $051A-$0521 payload untouched.")
		_check(int(callback.get("pointer_cpu", -1)) == 0x8B38
			and callback.get("read_offsets", []) == [0, 1, 2]
			and callback.get("read_bytes", PackedByteArray()) == PackedByteArray([0x06, 0x00, 0x56])
			and int(callback.get("handler_cpu", -1)) == 0x8327,
			"Callback data cursor reads $06/$00/$56 at offsets 0/1/2 and selects $8327.")
		_check(str(prefix.get("status", "")) == "source_prefix_resolved_waiting_for_route_state"
			and not bool(prefix.get("scheduler_or_worker_executed", true))
			and not bool(prefix.get("f015_causal_link_from_callback_proven", true))
			and prefix.get("missing_predecessor_state", {}).get("required", []).has("global $05CD immediately before $8327"),
			"The prefix stops before execution because shared $05CD and callback worker state remain caller-owned.")

	var loop_from_zero: Dictionary = model.call("derive_f015_entry_indices", 0)
	var loop_from_two: Dictionary = model.call("derive_f015_entry_indices", 2)
	_check(bool(loop_from_zero.get("ok", false))
		and loop_from_zero.get("indices", []) == [0, 1, 2, 3, 4, 5]
		and int(loop_from_zero.get("terminal_a", -1)) == 6
		and not bool(loop_from_zero.get("initial_a_source_proven", true)),
		"ROM loop bytes derive F015 indices 0..5 only when the caller explicitly supplies entry A=0.")
	_check(bool(loop_from_two.get("ok", false))
		and loop_from_two.get("indices", []) == [2, 3, 4, 5]
		and int(loop_from_two.get("terminal_a", -1)) == 6,
		"The same source recurrence preserves a nonzero explicit caller entry instead of defaulting it to zero.")
	var invalid_loop: Dictionary = model.call("derive_f015_entry_indices", 6)
	_check(not bool(invalid_loop.get("ok", true)),
		"An unsupported F015 entry A=6 is rejected rather than treated as a normal route pass.")
	_check(_compare_f015_trace_as_independent_oracle(loop_from_zero.get("indices", [])),
		"The retained muted trace independently observes A=0..5 on both producer passes; trace values do not seed the model.")

	if _failures.is_empty():
		print("PASS: scenario-$44 root continuation, callback data cursor through $8327, and bounded F015 A recurrence")
		print("LIMIT: no live task/worker execution, incoming $05CD producer chain, or source proof of F015 caller entry A; route causality remains open")
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _compare_f015_trace_as_independent_oracle(expected: Array) -> bool:
	for filename: String in ["field_producer_entries.csv", "field_producer_entries_repeat.csv"]:
		var path: String = TRACE_DIR + filename
		if not FileAccess.file_exists(path):
			return false
		var lines := FileAccess.get_file_as_string(path).split("\n", false)
		if lines.is_empty():
			return false
		var headers := lines[0].split(",", true)
		var pc_column := headers.find("entry_pc")
		var pass_column := headers.find("pass")
		var a_column := headers.find("cpu_a")
		if pc_column < 0 or pass_column < 0 or a_column < 0:
			return false
		var pass_id := ""
		var indices: Array[String] = []
		for line_index in range(1, lines.size()):
			var columns := lines[line_index].split(",", true)
			if columns.size() <= maxi(pc_column, maxi(pass_column, a_column)) or columns[pc_column] != "$F015":
				continue
			if pass_id.is_empty():
				pass_id = columns[pass_column]
			elif pass_id != columns[pass_column]:
				return false
			indices.append(columns[a_column])
		if indices.size() != expected.size():
			return false
		for index in expected.size():
			if indices[index] != "$%02X" % int(expected[index]):
				return false
	return true


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
