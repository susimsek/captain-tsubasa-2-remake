extends SceneTree

const STACK_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_continuation_stack.gd")

const ROUTE_SCENARIOS: Dictionary = {
	0x1E: {"path": "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_1E.bin", "size": 10, "sha256": "383f2248d753ef12b325c98238ee1c0eaa96c693ca427a5885536e1c16f1a496"},
	0x35: {"path": "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin", "size": 8, "sha256": "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df"},
	0x36: {"path": "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_36.bin", "size": 38, "sha256": "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f"},
	0x44: {"path": "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_44.bin", "size": 5, "sha256": "22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f"},
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stack_model = STACK_SCRIPT.new()
	var stale_stack := PackedByteArray([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])
	var initialized: Dictionary = stack_model.initialize_from_source_scenario_start(stale_stack)
	var source_status: Dictionary = stack_model.get_source_status()
	_check(bool(source_status.get("configured", false)),
		"all preserved continuation source ranges match the ROM-bound manifest")
	_check(str(source_status.get("source_rom_sha256", "")) ==
		"4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"continuation helper is pinned to the supplied Turkish ROM revision")
	_check(bool(initialized.get("ok", false)) and int(initialized.get("stack_depth", -1)) == 0,
		"fixed scenario-start path sets continuation depth $0522 to zero")
	_check(initialized.get("stack_memory", PackedByteArray()) == stale_stack,
		"scenario start leaves the $051A-$0521 payload bytes untouched")

	_check(_route_streams_end_at_root_fb(),
		"fresh-route scenario streams $1E/$35/$36/$44 contain no $FA and end at $FB")
	_check(_root_fb_ignores_payload(stack_model, stale_stack),
		"root $FB takes the $80CF terminal path without reading stale continuation payload")
	_check(_nested_fa_fb_round_trip(stack_model, stale_stack),
		"nested source $FA calls push return pointers and $FB restores them LIFO")
	_check(_rejects_invalid_context(stack_model, stale_stack),
		"out-of-window targets and impossible continuation depths are rejected")

	if _failures.is_empty():
		print("PASS: source-backed $FA/$FB continuation stack effects and all four fresh-route root terminators")
		print("LIMIT: outer CPU/task stack, scheduler, callback workers, and route source-state production remain outside this helper")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _route_streams_end_at_root_fb() -> bool:
	for scenario_id_variant in ROUTE_SCENARIOS:
		var scenario_id := int(scenario_id_variant)
		var source_metadata: Dictionary = ROUTE_SCENARIOS[scenario_id_variant]
		var path := str(source_metadata["path"])
		if not FileAccess.file_exists(path):
			return false
		var source := FileAccess.get_file_as_bytes(path)
		if source.size() != int(source_metadata["size"]) or \
				_sha256(source) != str(source_metadata["sha256"]) or \
				source.is_empty() or int(source[source.size() - 1]) != 0xFB:
			return false
		for value: int in source:
			if value == 0xFA:
				return false
		if scenario_id not in [0x1E, 0x35, 0x36, 0x44]:
			return false
	return true


func _root_fb_ignores_payload(stack_model: RefCounted,
		stack_memory: PackedByteArray) -> bool:
	for metadata_variant in ROUTE_SCENARIOS.values():
		var metadata: Dictionary = metadata_variant
		var source := FileAccess.get_file_as_bytes(str(metadata["path"]))
		var result: Dictionary = stack_model.execute_fb(0xB800, source.size(), 0, stack_memory)
		if not bool(result.get("ok", false)) or \
				str(result.get("status", "")) != "scenario_termination" or \
				int(result.get("underflow_value_before_terminal_reset", -1)) != 0xFE or \
				int(result.get("stack_depth_after", -1)) != 0 or \
				result.get("stack_memory_after", PackedByteArray()) != stack_memory or \
				bool(result.get("outer_cpu_task_return_modeled", true)):
			return false
	return true


func _nested_fa_fb_round_trip(stack_model: RefCounted,
		initial_memory: PackedByteArray) -> bool:
	var first_call := PackedByteArray([0xFA, 0x10, 0x80])
	var first: Dictionary = stack_model.execute_fa(first_call, 0xB700, 1, 0, initial_memory)
	if not bool(first.get("ok", false)) or int(first.get("target_pointer", -1)) != 0x8010 or \
			int(first.get("return_pointer", -1)) != 0xB703 or \
			int(first.get("stack_depth_after", -1)) != 2:
		return false
	var after_first: PackedByteArray = first.get("stack_memory_after", PackedByteArray())
	if after_first.slice(0, 2) != PackedByteArray([0x03, 0xB7]):
		return false

	var second_call := PackedByteArray([0xFA, 0x20, 0x80])
	var second: Dictionary = stack_model.execute_fa(second_call, 0x8010, 1, 2, after_first)
	if not bool(second.get("ok", false)) or int(second.get("target_pointer", -1)) != 0x8020 or \
			int(second.get("return_pointer", -1)) != 0x8013 or \
			int(second.get("stack_depth_after", -1)) != 4:
		return false
	var after_second: PackedByteArray = second.get("stack_memory_after", PackedByteArray())
	if after_second.slice(2, 4) != PackedByteArray([0x13, 0x80]):
		return false

	var inner_return: Dictionary = stack_model.execute_fb(0x8020, 3, 4, after_second)
	if not bool(inner_return.get("ok", false)) or \
			str(inner_return.get("status", "")) != "subroutine_return" or \
			int(inner_return.get("script_pointer_after", -1)) != 0x8013 or \
			int(inner_return.get("stack_depth_after", -1)) != 2:
		return false
	var outer_return: Dictionary = stack_model.execute_fb(0x8013, 3, 2,
		inner_return.get("stack_memory_after", PackedByteArray()))
	return bool(outer_return.get("ok", false)) and \
		str(outer_return.get("status", "")) == "subroutine_return" and \
		int(outer_return.get("script_pointer_after", -1)) == 0xB703 and \
		int(outer_return.get("stack_depth_after", -1)) == 0


func _rejects_invalid_context(stack_model: RefCounted,
		stack_memory: PackedByteArray) -> bool:
	var invalid_target := PackedByteArray([0xFA, 0x00, 0xC0])
	var fa_result: Dictionary = stack_model.execute_fa(invalid_target, 0xB700, 1, 0, stack_memory)
	var fb_result: Dictionary = stack_model.execute_fb(0xB800, 1, 1, stack_memory)
	var full_depth_result: Dictionary = stack_model.execute_fa(
		PackedByteArray([0xFA, 0x00, 0x80]), 0xB700, 1, 8, stack_memory)
	return not bool(fa_result.get("ok", true)) and not bool(fb_result.get("ok", true)) and \
		not bool(full_depth_result.get("ok", true))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
