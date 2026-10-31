extends SceneTree

const SELECTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const NORMALIZE_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_normalize_executor.gd")
const PRESET_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_preset_loader_prefix.gd")


func _initialize() -> void:
	var selector: Variant = SELECTOR_SCRIPT.new()
	if not selector.configure_from_project_sources():
		_fail("Could not configure the ROM selector prerequisite: " + selector.error_message)
		return
	var pre_call_sp := 0xFD
	var entry_sp := (pre_call_sp - 2) & 0xFF
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	stack[(entry_sp + 1) & 0xFF] = 0xFC
	stack[(entry_sp + 2) & 0xFF] = 0x80
	var selector_call := {
		"caller_pc": 0x80FA,
		"target_pc": 0xA20F,
		"return_pc": 0x80FD,
		"source_event_id": "verifier_fixture_only_source_call_80FA",
		"pre_call_sp": pre_call_sp,
		"stack_page": stack,
	}
	var selector_result: Dictionary = selector.execute_source_call(selector_call,
		{"pc": 0xA20F, "sp": entry_sp, "a": 0x87, "x": 2, "y": 0, "p": 0xA4},
		{0x0022: 0x80, 0x0023: 0x87, 0x0025: 2, 0x0026: 0})
	if not bool(selector_result.get("ok", false)):
		_fail("The A20F prerequisite did not return: " + String(selector_result.get("error", "unknown error")))
		return
	var normalize: Variant = NORMALIZE_SCRIPT.new()
	if not normalize.configure_from_project_sources():
		_fail("Could not configure the ROM normalizer prerequisite: " + normalize.error_message)
		return
	var normalize_result: Dictionary = normalize.execute_from_selector_return(selector_result)
	if not bool(normalize_result.get("ok", false)):
		_fail("The A20C prerequisite did not reach `$8112`: " + String(normalize_result.get("error", "unknown error")))
		return

	var preset: Variant = PRESET_SCRIPT.new()
	if not preset.configure_from_project_sources():
		_fail("Could not configure hash-checked `$8920/$9DEE` sources: " + preset.error_message)
		return
	var result: Dictionary = preset.execute_from_normalizer_return(normalize_result)
	if not bool(result.get("ok", false)):
		_fail("Preset-loader prefix failed before its source wait boundary: " + String(result.get("error", "unknown error")))
		return
	if String(result.get("status", "")) != "stopped_at_unresolved_source_predicate" \
			or bool(result.get("completed", true)):
		_fail("The component must stop explicitly at the unmodeled `$78` wait, not claim a return.")
		return
	var boundary: Dictionary = result.get("boundary", {})
	if int(boundary.get("pc", -1)) != 0x893B \
			or int(boundary.get("required_ram_address", -1)) != 0x0078 \
			or int(boundary.get("zero_successor_pc", -1)) != 0x893F \
			or int(boundary.get("nonzero_successor_pc", -1)) != 0x893B:
		_fail("The reported wait boundary differs from the ROM `$893B LDA $78 / BNE $893B` bytes.")
		return
	var regs: Dictionary = result.get("boundary_registers", {})
	if int(regs.get("pc", -1)) != 0x893B \
			or int(regs.get("sp", -1)) != 0xFB \
			or int(regs.get("a", -1)) != 0x87 \
			or int(regs.get("x", -1)) != 6 \
			or int(regs.get("y", -1)) != 0 \
			or int(regs.get("p", -1)) != 0xA4:
		_fail("`$8920` prefix CPU state at `$893B` is incorrect: %s" % regs)
		return
	var ram: Dictionary = result.get("caller_ram_after", {})
	for address: int in [0x00EC, 0x00ED, 0x00EA, 0x0023, 0x0025, 0x0026, 0x002A, 0x002B]:
		if not ram.has(address):
			_fail("Preset-loader prefix omitted source RAM `$%04X`." % address)
			return
	if int(ram[0x00EC]) != 0 or int(ram[0x00ED]) != 0xBF \
			or int(ram[0x00EA]) != 2 or int(ram[0x0023]) != 0x87 \
			or int(ram[0x0025]) != 6 or int(ram[0x0026]) != 0 \
			or int(ram[0x002A]) != 0 or int(ram[0x002B]) != 3:
		_fail("ROM-derived preset pointer or preserved match context differs: %s" % ram)
		return
	if ram.has(0x0078):
		_fail("The fixture must not seed the unresolved `$78` wait byte.")
		return
	var bus_writes: Array = result.get("mapper_bus_writes", [])
	if bus_writes.size() != 2 \
			or int(bus_writes[0].get("address", -1)) != 0x8000 \
			or int(bus_writes[0].get("value", -1)) != 0x87 \
			or int(bus_writes[1].get("address", -1)) != 0x8001 \
			or int(bus_writes[1].get("value", -1)) != 6:
		_fail("Preset-loader prefix MMC3 select writes differ: %s" % bus_writes)
		return
	var stack_after: PackedByteArray = result.get("stack_after", PackedByteArray())
	if stack_after.size() != 0x100 \
			or int(stack_after[0xFA]) != 0x3A or int(stack_after[0xFB]) != 0x89 \
			or int(stack_after[0xFC]) != 0x16 or int(stack_after[0xFD]) != 0x81:
		_fail("The outer `$8114` and nested `$8938` return words were not carried through the prefix.")
		return
	if int(result.get("cpu_cycles_without_interrupts_from_8112", -1)) != 232 \
			or not result.get("return_receipt", {}).is_empty() \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)):
		_fail("Prefix cycles, non-return boundary, or source-only provenance failed.")
		return
	var mapper_receipts: Array = result.get("prefix_returns", [])
	if mapper_receipts.size() != 2 \
			or int(mapper_receipts[0].get("rts_pc", -1)) != 0x9E0B \
			or int(mapper_receipts[1].get("caller_pc", -1)) != 0x8938 \
			or int(mapper_receipts[1].get("return_pc", -1)) != 0x893B:
		_fail("The genuine nested `$9DEE` and mapper RTS receipts are missing.")
		return

	var logical_event_id := "verifier_fixture_only_logical_80FA_a20f"
	var logical_selector_call := {
		"caller_pc": 0x80FA, "target_pc": 0xA20F, "return_pc": 0x80FD,
		"source_event_id": logical_event_id,
		"logical_stack_frame": {
			"kind": "rom_jsr", "caller_pc": 0x80FA,
			"target_pc": 0xA20F, "return_pc": 0x80FD,
			"return_word": 0x80FC, "source_event_id": logical_event_id,
		},
	}
	var logical_selector_result: Dictionary = selector.execute_source_call(logical_selector_call,
		{"pc": 0xA20F, "a": 0x07, "x": 0x02, "y": 0x00,
			"p_known_mask": 0x82, "p_known_value": 0x00},
		{0x0022: 0x00, 0x0023: 0x07, 0x0025: 0x02, 0x0026: 0x00})
	if not bool(logical_selector_result.get("ok", false)):
		_fail("The logical source selector prerequisite failed: " + String(logical_selector_result.get("error", "unknown error")))
		return
	var logical_normalizer: Variant = NORMALIZE_SCRIPT.new()
	if not logical_normalizer.configure_from_project_sources():
		_fail("Could not configure logical normalizer prerequisite: " + logical_normalizer.error_message)
		return
	var logical_normalize_result: Dictionary = logical_normalizer.execute_from_logical_selector_return(logical_selector_result)
	if not bool(logical_normalize_result.get("ok", false)):
		_fail("The logical normalizer prerequisite did not return at `$8112`: " + String(logical_normalize_result.get("error", "unknown error")))
		return
	var logical_result: Dictionary = preset.execute_from_normalizer_return(logical_normalize_result)
	if not bool(logical_result.get("ok", false)):
		_fail("Logical preset-loader prefix failed: " + String(logical_result.get("error", "unknown error")))
		return
	var logical_regs: Dictionary = logical_result.get("boundary_registers", {})
	if String(logical_result.get("stack_model", "")) != "logical_source_jsr_frames" \
			or int(logical_result.get("cpu_cycles_without_interrupts_from_8112", -1)) != 232 \
			or int(logical_regs.get("pc", -1)) != 0x893B \
			or String(logical_regs.get("sp", "")) != "not modeled; logical JSR frame only" \
			or logical_regs.has("p") \
			or int(logical_regs.get("a", -1)) != 0x07 \
			or int(logical_regs.get("x", -1)) != 0x06 \
			or int(logical_regs.get("y", -1)) != 0x00 \
			or int(logical_regs.get("p_known_mask", -1)) != 0xC3 \
			or int(logical_regs.get("p_known_value", -1)) != 0:
		_fail("The logical prefix CPU/partial-P boundary contract is incorrect: %s" % logical_regs)
		return
	var known_i_call: Dictionary = logical_selector_call.duplicate(true)
	known_i_call["source_event_id"] = logical_event_id + ":known_i_clear"
	known_i_call["logical_stack_frame"] = logical_selector_call["logical_stack_frame"].duplicate(true)
	known_i_call["logical_stack_frame"]["source_event_id"] = known_i_call["source_event_id"]
	var known_i_selector: Dictionary = selector.execute_source_call(known_i_call,
		{"pc": 0xA20F, "a": 0x07, "x": 0x02, "y": 0x00,
			"p_known_mask": 0x86, "p_known_value": 0x00},
		{0x0022: 0x00, 0x0023: 0x07, 0x0025: 0x02, 0x0026: 0x00})
	if not bool(known_i_selector.get("ok", false)):
		_fail("The known-I selector fixture failed: " + String(known_i_selector.get("error", "unknown error")))
		return
	var known_i_normalize: Dictionary = logical_normalizer.execute_from_logical_selector_return(known_i_selector)
	if not bool(known_i_normalize.get("ok", false)):
		_fail("The known-I normalization fixture failed: " + String(known_i_normalize.get("error", "unknown error")))
		return
	var known_i_result: Dictionary = preset.execute_from_normalizer_return(known_i_normalize)
	if not bool(known_i_result.get("ok", false)):
		_fail("The known-I preset fixture failed: " + String(known_i_result.get("error", "unknown error")))
		return
	var known_i_registers: Dictionary = known_i_result.get("boundary_registers", {})
	if (int(known_i_registers.get("p_known_mask", 0)) & 0x04) == 0 \
			or (int(known_i_registers.get("p_known_value", 0)) & 0x04) != 0:
		_fail("Known I=0 was lost or changed before `$893B`: %s" % known_i_registers)
		return
	var logical_ram: Dictionary = logical_result.get("caller_ram_after", {})
	if int(logical_ram.get(0x0022, -1)) != 0 \
			or int(logical_ram.get(0x0023, -1)) != 0x07 \
			or int(logical_ram.get(0x0025, -1)) != 0x06 \
			or int(logical_ram.get(0x0026, -1)) != 0 \
			or int(logical_ram.get(0x002A, -1)) != 0 \
			or int(logical_ram.get(0x002B, -1)) != 3 \
			or int(logical_ram.get(0x00EC, -1)) != 0 \
			or int(logical_ram.get(0x00ED, -1)) != 0xBF \
			or int(logical_ram.get(0x00EA, -1)) != 2 \
			or logical_ram.has(0x0078):
		_fail("Logical preset pointer, mapper, match context, or unowned `$78` differs: %s" % logical_ram)
		return
	var logical_bus_writes: Array = logical_result.get("mapper_bus_writes", [])
	if logical_bus_writes.size() != 2 \
			or int(logical_bus_writes[0].get("address", -1)) != 0x8000 \
			or int(logical_bus_writes[0].get("value", -1)) != 0x07 \
			or int(logical_bus_writes[1].get("address", -1)) != 0x8001 \
			or int(logical_bus_writes[1].get("value", -1)) != 0x06:
		_fail("Logical prefix MMC3 writes do not preserve ROM `$0022=$00`: %s" % logical_bus_writes)
		return
	var logical_frames: Array = logical_result.get("logical_stack_frames", [])
	var logical_stack_contract: Dictionary = logical_result.get("stack_contract", {})
	if logical_frames.size() != 1 \
			or int(logical_frames[0].get("caller_pc", -1)) != 0x8114 \
			or int(logical_frames[0].get("return_pc", -1)) != 0x8117 \
			or int(logical_frames[0].get("return_word", -1)) != 0x8116 \
			or String(logical_stack_contract.get("model", "")) != "logical_source_jsr_frames" \
			or int(logical_stack_contract.get("sp_delta_from_8112_pre_call", 0)) != -2 \
			or bool(logical_stack_contract.get("absolute_sp_known", true)) \
			or bool(logical_stack_contract.get("physical_stack_page_known", true)) \
			or int(logical_stack_contract.get("pending_jsr_count", -1)) != 1 \
			or int(logical_stack_contract.get("pending_frame", {}).get("return_word", -1)) != 0x8116 \
			or not logical_result.get("return_receipt", {}).is_empty():
		_fail("The `$893B` contract must retain one pending `$8114->$8920` frame with SP delta -2, no absolute SP/page, and no return claim.")
		return
	var bad_logical_wait: Dictionary = logical_normalize_result.duplicate(true)
	bad_logical_wait["caller_ram_after"][0x0078] = 0
	var refused_logical_wait: Dictionary = preset.execute_from_normalizer_return(bad_logical_wait)
	if bool(refused_logical_wait.get("ok", true)):
		_fail("The logical preset loader accepted `$78` without a source-provenance event.")
		return
	var bad_wait_state: Dictionary = normalize_result.duplicate(true)
	bad_wait_state["caller_ram_after"][0x0078] = 0
	var refused_unowned_wait: Dictionary = preset.execute_from_normalizer_return(bad_wait_state)
	if bool(refused_unowned_wait.get("ok", true)):
		_fail("The preset loader accepted `$78` without a source provenance event.")
		return
	var continuation_prefix: Dictionary = known_i_result.duplicate(true)
	continuation_prefix["caller_ram_after"][0x007B] = 0x5A
	var known_i_registers_for_irq: Dictionary = known_i_result.get("boundary_registers", {})
	var known_i_event_id := String(known_i_result.get("source_event_id", ""))
	var wait_receipt := {
		"ok": true,
		"kind": "rom_irq_wait_release",
		"source_rom_sha256": logical_result["source_rom_sha256"],
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_event_id": known_i_event_id + ":893B_irq_source_fixture",
		"interrupt": "IRQ", "wait_pc": 0x893B, "return_pc": 0x893B,
		"interrupt_stack_balanced": true,
		"source_path": [0xC506, 0xC821, 0xC478, 0xC491, 0xA160, 0xA1C3, 0xC4AD],
		"ram_at_wait": {0x001B: 0xC0, 0x0078: 4, 0x0079: 0x40, 0x003B: 0x55},
		"ram_writes": [{"source_pc": 0xA1C3, "address": 0x0078,
			"before": 4, "value": 0,
			"source_event_id": known_i_event_id + ":893B_irq_source_fixture"}],
		"return_registers": {"pc": 0x893B, "a": 0x07, "x": 0x06, "y": 0x00,
			"p_known_mask": int(known_i_registers_for_irq.get("p_known_mask", 0)),
			"p_known_value": int(known_i_registers_for_irq.get("p_known_value", 0))},
	}
	var resumed_result: Dictionary = preset.execute_after_wait_release(continuation_prefix, wait_receipt)
	if not bool(resumed_result.get("ok", false)):
		_fail("The source-tail consumer rejected its explicitly test-only IRQ receipt: " + String(resumed_result.get("error", "unknown error")))
		return
	var resumed_ram: Dictionary = resumed_result.get("caller_ram_after", {})
	var expected_copied_ram: Dictionary = {0x0079: 0, 0x007A: 0}
	for address: int in range(0x007C, 0x008E):
		expected_copied_ram[address] = 0
	for address: int in expected_copied_ram:
		if int(resumed_ram.get(address, -1)) != int(expected_copied_ram[address]):
			_fail("The ROM preset record did not populate `$%04X` correctly." % address)
			return
	if int(resumed_ram.get(0x007B, -1)) != 0x5A \
			or int(resumed_ram.get(0x0025, -1)) != 2 \
			or int(resumed_ram.get(0x0078, -1)) != 0 \
			or int(resumed_result.get("final_source_pc", -1)) != 0x8117 \
			or int(resumed_result.get("cpu_cycles_excluding_wait_and_interrupts_from_8112", -1)) != 603 \
			or not resumed_result.get("stack_after", []).is_empty() \
			or bool(resumed_result.get("live_mapper_updated", true)) \
			or bool(resumed_result.get("trace_state_used", true)) \
			or bool(resumed_result.get("emulator_data_used", true)):
		_fail("The resumed ROM tail failed its bank restoration, outer RTS, stack, or source-only contract.")
		return
	if not String(resumed_result.get("status", "")).begins_with("returned_to_fresh_match_caller") \
			or String(resumed_result.get("source_return_receipt", {}).get("status", "")) != "returned":
		_fail("The ROM source-tail consumer omitted its `$8117` return receipt.")
		return
	var bad_irq_receipt: Dictionary = wait_receipt.duplicate(true)
	bad_irq_receipt["trace_state_used"] = true
	var refused_trace_irq: Dictionary = preset.execute_after_wait_release(continuation_prefix, bad_irq_receipt)
	if bool(refused_trace_irq.get("ok", true)):
		_fail("The source-tail consumer accepted a trace-backed IRQ receipt.")
		return
	if bool(result.get("live_mapper_updated", true)):
		_fail("Bounded mapper bus effects must not mutate the live mapper.")
		return

	print("PASS: `$8112->$8114->$8920->$9DEE` and `$8938->$C4B9` execute from the prior ROM-source return, preserving stack and selecting bank `$06`.")
	print("PASS: the same `$8112->$893B` prefix retains one pending JSR, proves SP delta -2, preserves `$0022=$00` and partial P flags, and leaves absolute SP/stack-page bytes unknown.")
	print("PASS: the prefix stops before unknown `$0078`; a test-only ROM IRQ receipt then drives the hash-checked `$893F-$895C` copy and `$8117` return consumer.")
	print("PASS: the 19-byte preset record copy preserves `$7B`, restores bank `$02`, consumes both logical RTS frames, and rejects trace-backed release receipts.")
	print("LIMIT: IRQ receipt is a verifier fixture only. Production PPU/MMC3/CPU interrupt event generation and route integration remain unresolved; this does not prove runtime reachability or exact IRQ timing.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
