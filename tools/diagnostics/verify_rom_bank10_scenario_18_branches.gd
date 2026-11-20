extends SceneTree

const READER := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const SCENARIO_RUNTIME := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	for height: int in [0, 1, 2]:
		for selector: int in [0, 1, 2, 3]:
			var parsed: Dictionary = READER.read_project_scenario(0x18, {
				"continuation_depth": 0,
				"ram_0441": 0x06,
				"ram_044E": height,
				"ram_043C": selector,
				"ram_0516": 0x80,
				"ram_0638": 0x78,
				"ram_fd00_mirror_flag": 0x00,
			})
			var expected_status := READER.ParseStatus.SOURCE_TERMINATED if height == 2 \
				else READER.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED
			if int(parsed.get("terminal_status", -1)) != expected_status:
				failures.append("height=$%02X selector=$%02X status=%s terminal=%d message=%s" % [
					height, selector, READER.status_name(int(parsed.get("status", -1))),
					int(parsed.get("terminal_status", -1)), String(parsed.get("message", ""))])
				continue
			var tokens: Array = parsed.get("tokens", [])
			if height == 2:
				if tokens.size() < 5 or String(tokens[3].get("kind", "")) != "event_record" \
						or int(tokens[3].get("byte_offset", -1)) != 20 \
						or tokens[3].get("raw_bytes", PackedByteArray()) != PackedByteArray([0x3F, 0x2A, 0x19, 0x47]):
					failures.append("height=$02 root branch lacks the ROM event at +0x14")
			else:
				var f3_token: Dictionary = tokens.back() if not tokens.is_empty() else {}
				var expected_target: int = [0xAF51, 0xAF59, 0xAF90, 0xAFAA][selector]
				if int(f3_token.get("selected_target_cpu_address", -1)) != expected_target:
					failures.append("height=$%02X selector=$%02X target=%s expected=$%04X" % [
						height, selector, str(f3_token.get("selected_target_cpu_address", -1)), expected_target])
	var live_cursor_runtime: RefCounted = SCENARIO_RUNTIME.new()
	var missing_stack_context: Dictionary = live_cursor_runtime.begin_from_live_scenario_pointer(0x18, 0xAF58)
	if bool(missing_stack_context.get("ok", false)) \
			or String(missing_stack_context.get("status", "")) != "source_state_required":
		failures.append("live `$AF58` was accepted without its caller-owned `$0522` stack state")
	var nonempty_stack_context: Dictionary = live_cursor_runtime.begin_from_live_scenario_pointer(0x18,
		0xAF58, {"ram_0522": 1})
	if bool(nonempty_stack_context.get("ok", false)) \
			or String(nonempty_stack_context.get("status", "")) != "source_state_required":
		failures.append("live `$AF58` was accepted with a nonempty caller-owned `$0522` stack")
	var live_cursor_begin: Dictionary = live_cursor_runtime.begin_from_live_scenario_pointer(0x18,
		0xAF58, {"ram_0522": 0})
	if not bool(live_cursor_begin.get("ok", false)) \
			or int(live_cursor_begin.get("source_root_pointer_cpu", -1)) != 0xAF51 \
			or int(live_cursor_begin.get("source_byte_index", -1)) != 7:
		failures.append("live `$AF58` did not bind to the `$AF51` branch terminal: %s" % str(live_cursor_begin))
	else:
		var live_terminal: Dictionary = live_cursor_runtime.advance_one()
		if not bool(live_terminal.get("ok", false)) \
				or String(live_terminal.get("status", "")) != "root_scenario_terminated" \
				or int(live_terminal.get("source_byte_offset", -1)) != 7 \
				or int(live_terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF:
			failures.append("live `$AF58` did not decode its ROM `$FB` terminal: %s" % str(live_terminal))
	if failures.is_empty():
		print("PASS: scenario-$18 selects its ROM `$044E` skip and `$043C` targets, decodes root events, and resumes the `$AF51->$AF58` ROM `$FB` terminal.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
