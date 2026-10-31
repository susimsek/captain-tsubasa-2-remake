extends SceneTree

const SELECTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const NORMALIZE_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_normalize_executor.gd")
const PRESET_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_preset_loader_prefix.gd")
const CALLER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_postwait_caller.gd")


func _initialize() -> void:
	var selector: Variant = SELECTOR_SCRIPT.new()
	if not selector.configure_from_project_sources():
		_fail("Could not configure selector source: " + selector.error_message)
		return
	var event_id := "verifier_fixture_only_postwait_80FA_A20F"
	var selector_call := {
		"caller_pc": 0x80FA, "target_pc": 0xA20F, "return_pc": 0x80FD,
		"source_event_id": event_id,
		"logical_stack_frame": {
			"kind": "rom_jsr", "caller_pc": 0x80FA,
			"target_pc": 0xA20F, "return_pc": 0x80FD,
			"return_word": 0x80FC, "source_event_id": event_id,
		},
	}
	var selector_result: Dictionary = selector.execute_source_call(selector_call,
		{"pc": 0xA20F, "a": 0x07, "x": 0x02, "y": 0x00,
			"p_known_mask": 0x86, "p_known_value": 0x00},
		{0x0022: 0x00, 0x0023: 0x07, 0x0025: 0x02, 0x0026: 0x00})
	if not bool(selector_result.get("ok", false)):
		_fail("The source selector fixture failed: " + String(selector_result.get("error", "unknown error")))
		return
	var normalizer: Variant = NORMALIZE_SCRIPT.new()
	if not normalizer.configure_from_project_sources():
		_fail("Could not configure normalizer source: " + normalizer.error_message)
		return
	var normalized: Dictionary = normalizer.execute_from_logical_selector_return(selector_result)
	if not bool(normalized.get("ok", false)):
		_fail("The logical normalization fixture failed: " + String(normalized.get("error", "unknown error")))
		return
	var preset: Variant = PRESET_SCRIPT.new()
	if not preset.configure_from_project_sources():
		_fail("Could not configure preset source: " + preset.error_message)
		return
	var waiting_prefix: Dictionary = preset.execute_from_normalizer_return(normalized)
	if not bool(waiting_prefix.get("ok", false)):
		_fail("The `$893B` source prefix failed: " + String(waiting_prefix.get("error", "unknown error")))
		return
	var registers: Dictionary = waiting_prefix.get("boundary_registers", {})
	var source_id := String(waiting_prefix.get("source_event_id", ""))
	var release_id := source_id + ":893B_verifier_only_irq_release"
	var continuation_prefix: Dictionary = waiting_prefix.duplicate(true)
	continuation_prefix["caller_ram_after"][0x007B] = 0x5A
	var wait_receipt := {
		"ok": true,
		"kind": "rom_irq_wait_release",
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_event_id": release_id,
		"interrupt": "IRQ", "wait_pc": 0x893B, "return_pc": 0x893B,
		"interrupt_stack_balanced": true,
		"source_path": [0xC506, 0xC821, 0xC478, 0xC491, 0xA160, 0xA1C3, 0xC4AD],
		"ram_at_wait": {0x001B: 0xC0, 0x0078: 4, 0x0079: 0x40, 0x003B: 0x55},
		"ram_writes": [{"source_pc": 0xA1C3, "address": 0x0078,
			"before": 4, "value": 0,
			"source_event_id": release_id}],
		"return_registers": {
			"pc": 0x893B, "a": 0x07, "x": 0x06, "y": 0x00,
			"p_known_mask": int(registers.get("p_known_mask", 0)),
			"p_known_value": int(registers.get("p_known_value", 0)),
		},
	}
	var tail_result: Dictionary = preset.execute_after_wait_release(continuation_prefix, wait_receipt)
	if not bool(tail_result.get("ok", false)):
		_fail("The test-only release fixture did not produce `$8117`: " + String(tail_result.get("error", "unknown error")))
		return
	var caller: Variant = CALLER_SCRIPT.new()
	if not caller.configure_from_project_sources():
		_fail("Could not configure post-wait caller sources: " + caller.error_message)
		return
	var result: Dictionary = caller.execute_from_preset_tail_result(tail_result)
	if not bool(result.get("ok", false)):
		_fail("Post-wait caller execution failed: " + String(result.get("error", "unknown error")))
		return
	var cpu: Dictionary = result.get("next_cpu_state", {})
	var pending: Array = result.get("logical_stack_frames", [])
	var next_call: Dictionary = result.get("next_source_call", {})
	if String(result.get("status", "")) != "stopped_at_unexecuted_a006_body" \
			or bool(result.get("completed", true)) \
			or int(cpu.get("pc", -1)) != 0xA4EB \
			or pending.size() != 1 \
			or int(pending[0].get("caller_pc", -1)) != 0x811C \
			or int(pending[0].get("return_pc", -1)) != 0x811F \
			or String(next_call.get("status", "")) != "verified_in_rom_but_not_reached" \
			or int(next_call.get("target_pc", -1)) != 0xC572 \
			or int(result.get("cpu_cycles_through_a006_jmp", -1)) != 42 \
			or result.get("source_path", []).has(0xC572) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)):
		_fail("The bounded `$8117->$C4B9->$A006->$A4EB` result or stop boundary is invalid: %s" % result)
		return
	var bad_tail: Dictionary = waiting_prefix.duplicate(true)
	var rejected_waiting_prefix: Dictionary = caller.execute_from_preset_tail_result(bad_tail)
	if bool(rejected_waiting_prefix.get("ok", true)):
		_fail("The post-wait caller accepted an unresolved `$893B` prefix without a release receipt.")
		return
	var traced_tail: Dictionary = tail_result.duplicate(true)
	traced_tail["trace_state_used"] = true
	var rejected_trace_tail: Dictionary = caller.execute_from_preset_tail_result(traced_tail)
	if bool(rejected_trace_tail.get("ok", true)):
		_fail("The post-wait caller accepted a trace-backed prefix result.")
		return
	print("PASS: source `$8117 LDX #$01`, `$8119->$C4B9`, and `$811C->$A006->$A4EB` execute from the preset-tail return.")
	print("PASS: `$C4B9` selects MMC3 register 7 / bank `$01`; the logical `$811C` JSR frame remains pending at `$A4EB`.")
	print("PASS: `$811F JSR $C572` is verified in caller ROM bytes and remains explicitly unexecuted; unresolved or trace-backed tail inputs are rejected.")
	print("LIMIT: the verifier's IRQ release receipt is a test fixture only. Runtime IRQ production is absent; `$A4EB` is not executed, so `$811F->$C572` and later match setup remain unreachable.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
