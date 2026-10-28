extends SceneTree

const API_SCRIPT := preload("res://scripts/gameplay/rom_first_command_callback_dispatch_api.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var unresolved_api: RefCounted = API_SCRIPT.new()
	var no_callback: Dictionary = unresolved_api.call("compute_8327_placement_transition", 0x04)
	_check(not bool(no_callback.get("ok", true))
		and str(no_callback.get("status", "")) == "callback_source_required",
		"The placement API refuses to run without a resolved ROM callback source.")
	var api: RefCounted = API_SCRIPT.new()
	var dispatch: Dictionary = api.call("resolve_scenario_44_callback")
	_check(bool(dispatch.get("ok", false)),
		"ROM-backed callback source resolve: " + str(dispatch.get("error", api.get("error_message"))))
	if bool(dispatch.get("ok", false)):
		var first: Dictionary = dispatch.get("first_callback_command", {})
		_check(int(dispatch.get("callback_pointer_cpu", -1)) == 0x8B38,
			"Scenario $44 callback selector $70 resolves from ROM pointer bytes to $8B38.")
		_check(int(dispatch.get("continuation_depth", -1)) == 0
			and str(dispatch.get("continuation_status", "")).contains("root $FB")
			and not bool(dispatch.get("outer_cpu_task_return_modeled", true)),
			"Scenario $44 is classified as a depth-zero source terminator without claiming the outer task return.")
		_check(int(first.get("ram_0525_value", -1)) == 0x06
			and int(first.get("handler_subindex", -1)) == 0x00
			and int(first.get("handler_cpu", -1)) == 0x8327
			and int(first.get("map_selector", -1)) == 0x56,
			"Callback-$70 first command resolves through the ROM inline vector to map handler $8327/$56.")
		_check(dispatch.get("unresolved_callback_tail", PackedByteArray()) == PackedByteArray([0x02, 0x00, 0x80]),
			"The remaining callback bytes are preserved and not speculatively scheduled.")
		_check(not bool(dispatch.get("scheduler_verified", true))
			and dispatch.get("required_live_inputs", []).has("global RAM $05CD immediately before $8327"),
			"Callback resolution reports its missing scheduler and shared-$05CD route state.")

	var missing_state: Dictionary = api.call("compute_8327_placement_transition", -1)
	_check(not bool(missing_state.get("ok", true))
		and str(missing_state.get("status", "")) == "source_state_required",
		"The placement API refuses to invent a previous global $05CD value.")
	var explicit_state: Dictionary = api.call("compute_8327_placement_transition", 0x04)
	_check(bool(explicit_state.get("ok", false))
		and int(explicit_state.get("previous_05cd", -1)) == 0x04
		and int(explicit_state.get("written_05ce", -1)) == 0x80
		and int(explicit_state.get("next_05cd", -1)) == 0xA0
		and not bool(explicit_state.get("scheduler_verified", true)),
		"An explicit caller-owned $05CD is passed through the byte-verified $8327 formula without asserting task timing.")

	if _failures.is_empty():
		print("PASS: scenario-$44 → callback-$70 pointer/handler resolution and explicit-$05CD API contract")
		print("LIMIT: callback task scheduling, outer CPU/task return, callback tail, and prior route-owned $05CD remain unmodeled")
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
