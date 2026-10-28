extends SceneTree

const COMPONENT_SCRIPT := preload("res://scripts/gameplay/rom_first_fresh_callback_source_component.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var component: RefCounted = COMPONENT_SCRIPT.new()
	_check(bool(component.call("configure_from_project_sources")),
		"Hash-check source assets for scenario $35/$3A, callback $3A, and fresh setup: " + str(component.get("error_message")))
	if not _failures.is_empty():
		_finish()
		return
	var result: Dictionary = component.call("project_first_callback_transition")
	_check(bool(result.get("ok", false)),
		"Project the first callback from source bytes: " + str(result.get("error", "")))
	if bool(result.get("ok", false)):
		var scenario: Dictionary = result.get("scenario", {})
		var callback: Dictionary = result.get("callback", {})
		var zero_fill: Dictionary = result.get("fresh_setup_zero_fill", {})
		var transition: Dictionary = result.get("handler_transition_if_dispatched", {})
		var seed: Dictionary = result.get("callback_task_seed", {})
		var first_scan: Dictionary = seed.get("first_scheduler_decision", {})
		_check(int(scenario.get("id", -1)) == 0x35
			and scenario.get("event_bytes", PackedByteArray()) == PackedByteArray([0x02, 0x3A, 0x8F, 0x73])
			and int(scenario.get("callback_id", -1)) == 0x3A,
			"Decode the source event record and keep callback ID separate from actor animation ID.")
		_check(int(callback.get("stream_address", -1)) == 0x89F3
			and int(callback.get("next_pointer_boundary", -1)) == 0x89F6
			and callback.get("stream_bytes", PackedByteArray()) == PackedByteArray([0x02, 0x00, 0x42])
			and int(callback.get("handler_pc", -1)) == 0x8327
			and int(callback.get("map_selector", -1)) == 0x42,
			"Resolve callback $3A's pointer-bounded operation through ROM vector $81A7 to $8327.")
		_check(int(zero_fill.get("start_address", -1)) == 0x0468
			and int(zero_fill.get("end_address_exclusive", -1)) == 0x0700
			and int(zero_fill.get("store_count", -1)) == 664
			and int(zero_fill.get("highest_address", -1)) == 0x06FF
			and int(zero_fill.get("write_index_05cd", -1)) == 0x165
			and int(zero_fill.get("write_index_05ce", -1)) == 0x166,
			"Execute the exact AA06 loop: 152 + 256 + 256 stores, ending at $0700.")
		_check(int(result.get("incoming_05cd_source_value", -1)) == 0
			and int(transition.get("previous_05cd", -1)) == 0
			and int(transition.get("written_05ce", -1)) == 0
			and int(transition.get("next_05cd", -1)) == 0xA0,
			"Derive the first handler's $05CD input from source zero-fill and run its ROM-byte formula.")
		_check(int(first_scan.get("selected_slot_base", -1)) == 0x01
			and not bool(result.get("callback_handler_executed", true))
			and not bool(result.get("yield_resume_executed", true))
			and str(result.get("status", "")) == "source_projection_waiting_for_task_body",
			"Keep scheduler dispatch and callback worker yield/resume explicitly unresolved.")
		_check(not bool(result.get("trace_data_used_as_runtime_input", true)),
			"No captured task state, RAM byte, frame, or PPU data enters the source projection.")

	_finish()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: first fresh callback source projection derives $05CD=0 and $8327->$05CD=$A0 from ROM bytes.")
		print("LIMIT: source plan only; root task completion, slot-$15 dispatch, worker yield/resume, and live route timing remain unmodeled.")
		quit(0)
	else:
		for message: String in _failures:
			printerr("FAIL: " + message)
		quit(1)
