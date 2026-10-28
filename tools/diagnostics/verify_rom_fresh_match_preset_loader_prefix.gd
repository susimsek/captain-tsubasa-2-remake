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
	var bad_wait_state: Dictionary = normalize_result.duplicate(true)
	bad_wait_state["caller_ram_after"][0x0078] = 0
	var refused_unowned_wait: Dictionary = preset.execute_from_normalizer_return(bad_wait_state)
	if bool(refused_unowned_wait.get("ok", true)):
		_fail("The preset loader accepted `$78` without a source provenance event.")
		return
	if bool(result.get("live_mapper_updated", true)):
		_fail("Bounded mapper bus effects must not mutate the live mapper.")
		return

	print("PASS: `$8112->$8114->$8920->$9DEE` and `$8938->$C4B9` execute from the prior ROM-source return, preserving stack and selecting bank `$06`.")
	print("PASS: preset pointer arithmetic yields `$BF00`; the component stops before reading unknown `$0078` at `$893B` and does not claim the `$8920` RTS.")
	print("LIMIT: `$0078` source event/wait resume and subsequent 19-byte preset copy/bank restore are unresolved; verifier event identity is a fixture, no production route integration.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
