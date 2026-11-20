extends SceneTree

const RUNTIME_SCRIPT := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var wrong_pointer_runtime := RUNTIME_SCRIPT.new()
	var wrong_pointer: Dictionary = wrong_pointer_runtime.begin_from_live_scenario_pointer(0x1C, 0x9BE4)
	_check(not bool(wrong_pointer.get("ok", true))
		and str(wrong_pointer.get("status", "")) == "source_state_required"
		and int(wrong_pointer.get("manifest_root_pointer", -1)) == 0x9BE3,
		"scenario-$1C admits only its manifest-checked root pointer $9BE3")

	var missing_context_runtime := RUNTIME_SCRIPT.new()
	var missing_context: Dictionary = missing_context_runtime.begin_from_live_scenario_pointer(0x1C, 0x9BE3)
	var requirements: Array = missing_context.get("context_requirements", [])
	var root_tokens: Array = missing_context.get("reader_tokens", [])
	_check(bool(missing_context.get("ok", false))
		and bool(missing_context.get("admitted", false))
		and str(missing_context.get("admission_status", "")) == "source_verified"
		and str(missing_context.get("reader_status", "")) == "context_required"
		and str(missing_context.get("terminal_status", "")) == "external_continuation_required"
		and str(missing_context.get("source_stream_sha256", "")) == "68d8512ef76afc90deee499c53952f8cf27d4c4473749a571ef1ed9deca132e2",
		"scenario-$1C source admission preserves parser context and external-terminal statuses")
	_check(_requirements_contain(requirements, "$0441")
		and _requirements_contain(requirements, "$043B")
		and _requirements_contain(requirements, "$043C")
		and _requirements_contain(requirements, "$044E"),
		"missing holder, nested-selector, and branch-selector inputs remain explicit requirements")
	_check(root_tokens.size() == 3
		and _token_is(root_tokens, 0, 0xFD, 0)
		and _token_is(root_tokens, 1, 0xFA, 2)
		and _token_is(root_tokens, 2, 0xF3, 5),
		"admission exposes only the parser's source-verified FD/FA/F3 root prefix")
	var fd_stop: Dictionary = missing_context_runtime.advance_one()
	_check(not bool(fd_stop.get("ok", true))
		and str(fd_stop.get("status", "")) == "context_required"
		and str(fd_stop.get("reader_status", "")) == "context_required"
		and str(fd_stop.get("terminal_status", "")) == "external_continuation_required"
		and not bool(fd_stop.get("cursor_advanced", true))
		and int(missing_context_runtime.get_state().get("source_byte_index", -1)) == 0,
		"runtime stops before unresolved FD $00 and preserves the source cursor/terminal status")
	_check(fd_stop.get("required_context", []) == [
		"RAM $0441", "resolved player-record fields", "RAM $0638"],
		"FD $00 stop identifies holder, resolved-record, and $0638 inputs without deriving a result")

	var selected_branch_runtime := RUNTIME_SCRIPT.new()
	var selected_branch: Dictionary = selected_branch_runtime.begin_from_live_scenario_pointer(0x1C,
		0x9BE3, {"ram_044E": 1, "ram_043B": 1, "ram_043C": 0, "ram_0516": 0})
	var selected_tokens: Array = selected_branch.get("reader_tokens", [])
	var f2_token: Dictionary = _find_opcode(selected_tokens, 0xF2)
	var nested_tokens: Array = selected_tokens[1].get("f3_dispatch_tokens", []) \
		if selected_tokens.size() > 1 and selected_tokens[1] is Dictionary else []
	_check(bool(selected_branch.get("ok", false))
		and str(selected_branch.get("reader_status", "")) == "context_required"
		and str(selected_branch.get("terminal_status", "")) == "external_continuation_required"
		and f2_token.get("status", "") == "external_continuation_required"
		and int(f2_token.get("target_cpu_address", -1)) == 0xB49E
		and int(f2_token.get("target_file_offset", -1)) == 0x0234AE
		and nested_tokens.size() == 2
		and int(nested_tokens[0].get("selected_target_cpu_address", -1)) == 0x9F4A
		and int(nested_tokens[1].get("selected_target_cpu_address", -1)) == 0xBB4B,
		"live $043B/$043C selectors resolve the nested $9F4A->$BB4B branch while F2 $B49E remains external")
	var still_stopped: Dictionary = selected_branch_runtime.advance_one()
	_check(not bool(still_stopped.get("ok", true))
		and str(still_stopped.get("status", "")) == "context_required"
		and int(selected_branch_runtime.get_state().get("source_byte_index", -1)) == 0,
		"selected-branch preview never bypasses the unresolved first FD $00 or executes its worker")

	var missing_043c_runtime := RUNTIME_SCRIPT.new()
	var missing_043c: Dictionary = missing_043c_runtime.begin_from_live_scenario_pointer(0x1C,
		0x9BE3, {"ram_044E": 1, "ram_043B": 1})
	_check(bool(missing_043c.get("ok", false))
		and _requirements_contain(missing_043c.get("context_requirements", []), "$043C")
		and str(missing_043c.get("terminal_status", "")) == "external_continuation_required",
		"conditional nested F3 $1E keeps missing $043C explicit while F2 remains external")

	if _failures.is_empty():
		print("PASS: scenario-$1C manifest pointer admission and context/external safe stops")
		print("LIMIT: FD $00, FA/F3 execution, F2 target streams, callback, and worker lifecycle remain unexecuted")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _token_is(tokens: Array, index: int, opcode: int, byte_offset: int) -> bool:
	if index < 0 or index >= tokens.size() or not tokens[index] is Dictionary:
		return false
	var token: Dictionary = tokens[index]
	return int(token.get("opcode", -1)) == opcode \
		and int(token.get("byte_offset", -1)) == byte_offset


func _find_opcode(tokens: Array, opcode: int) -> Dictionary:
	for token_variant in tokens:
		if token_variant is Dictionary and int((token_variant as Dictionary).get("opcode", -1)) == opcode:
			return token_variant
	return {}


func _requirements_contain(requirements: Array, needle: String) -> bool:
	for requirement_variant in requirements:
		if String(requirement_variant).contains(needle):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
