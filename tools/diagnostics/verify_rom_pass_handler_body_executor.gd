extends SceneTree
## Focused source-boundary verifier for the PASS `$D7E8` handler prefix.
## The positive boundary below is a synthetic scheduler fixture, not a claimed
## route execution or emulator snapshot.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_handler_body_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not configure PASS handler source spans: " + executor.error_message)
		return
	var source_status: Dictionary = executor.get_source_status()
	if not bool(source_status.get("configured", false)) \
			or String(source_status.get("scenario38_sha256", "")) \
			!= "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76":
		_fail("PASS handler source package did not validate the scenario-$38 stream.")
		return

	var boundary := _make_live_boundary()
	var original_ram: PackedByteArray = boundary["ram_image"].duplicate()
	var original_stack: PackedByteArray = boundary["stack_page"].duplicate()
	var result: Dictionary = executor.execute_from_live_boundary(boundary)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_scenario38_queue_at_cb0f_call_entry" \
			or int(result.get("entry_pc", -1)) != 0xD7E8 \
			or int(result.get("resume_pc", -1)) != 0xCB0F \
			or int(result.get("entry_sp", -1)) != 0x40 \
			or int(result.get("final_sp", -1)) != 0x3C:
		_fail("The live-boundary prefix did not stop at `$CB0F` call entry: " + str(result))
		return
	var output: Dictionary = result.get("next_boundary_snapshot", {})
	var output_ram: PackedByteArray = output.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = output.get("stack_page", PackedByteArray())
	var writes: Array = result.get("source_writes", [])
	var stack_writes: Array = result.get("source_stack_writes", [])
	var registers: Dictionary = result.get("registers", {})
	if output_ram.size() != 0x0800 or output_stack.size() != 0x100 \
			or output_ram.slice(0x0100, 0x0200) != output_stack \
			or int(output_ram[0x0518]) != 0x38 \
			or int(output_ram[0x0516]) != 0x80 \
			or int(output_ram[0x0005]) != 0 \
			or int(output_ram[0x0036]) != 0xE8 or int(output_ram[0x0037]) != 0xD7 \
			or writes != [
				{"source_pc": 0xCBB0, "address": 0x0518, "value": 0x38},
				{"source_pc": 0xCBB5, "address": 0x0516, "value": 0x80},
				{"source_pc": 0xCBBA, "address": 0x0005, "value": 0x00},
			] \
			or stack_writes.size() != 4 \
			or not _stack_write_matches(stack_writes[0], 0xD7EA, 0x0140, 0xD7, "jsr_push_high") \
			or not _stack_write_matches(stack_writes[1], 0xD7EA, 0x013F, 0xEC, "jsr_push_low") \
			or not _stack_write_matches(stack_writes[2], 0xCBBE, 0x013E, 0xCB, "jsr_push_high") \
			or not _stack_write_matches(stack_writes[3], 0xCBBE, 0x013D, 0xC0, "jsr_push_low") \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("p", -1)) & 0x83 != 0x02 \
			or int(registers.get("x", -1)) != 0x57 \
			or int(registers.get("y", -1)) != 0x04 \
			or int(registers.get("sp", -1)) != 0x3C \
			or int(registers.get("pc", -1)) != 0xCB0F:
		_fail("CBB0 write events, nested JSR frames, or final CPU state differ: " + str(result))
		return
	if bool(result.get("scheduler_yield_executed", true)) \
			or bool(result.get("input_wait_reached", true)) \
			or bool(result.get("descriptor_0f_executed", true)) \
			or bool(result.get("holder_copy_executed", true)) \
			or bool(result.get("cursor_input_read", true)) \
			or bool(result.get("scheduler_resume_or_elapsed_wait_fabricated", true)) \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)):
		_fail("The bounded result claims work beyond the proven `$CB0F` call-entry boundary.")
		return
	if boundary["ram_image"] != original_ram or boundary["stack_page"] != original_stack:
		_fail("The executor mutated its input boundary images instead of returning copied state.")
		return

	for case in [
		{"name": "wrong ROM", "key": "rom_sha256", "value": "0".repeat(64)},
		{"name": "wrong PC", "key": "pc", "value": 0xD7E9},
		{"name": "wrong execution bank", "key": "executing_cpu_bank", "value": 0x1D},
		{"name": "trace-seeded", "key": "trace_state_used", "value": true},
	]:
		var invalid: Dictionary = _make_live_boundary()
		invalid[String(case["key"])] = case["value"]
		var rejected: Dictionary = executor.execute_from_live_boundary(invalid)
		if bool(rejected.get("ok", true)):
			_fail("Executor accepted %s boundary input." % String(case["name"]))
			return
	var bad_mirror: Dictionary = _make_live_boundary()
	var bad_stack: PackedByteArray = bad_mirror["stack_page"].duplicate()
	bad_stack[0x42] ^= 0x01
	bad_mirror["stack_page"] = bad_stack
	var mirror_result: Dictionary = executor.execute_from_live_boundary(bad_mirror)
	if bool(mirror_result.get("ok", true)):
		_fail("Executor accepted a RAM/stack mirror mismatch.")
		return

	print("PASS: ROM-derived D7E8/CBB0 prefix validates scenario $38 and adopts only $0518/$0516/$0005 plus source JSR stack writes.")
	print("PASS: output stops before executing $CB0F; descriptor $0F, holder/cursor work, receiver input, scheduler resume, PPU/APU, and timing are not claimed.")
	print("LIMIT: the fixture is synthetic. Production must supply an ordinary-input live slot-$05 D7E8 snapshot; descriptor-worker/scheduler source bridge to $D80A remains missing.")
	quit(0)


func _make_live_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x0800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	# CB99 dispatch leaves the D5C3 caller return word $D634 on the live stack.
	stack[0x41] = 0x34
	stack[0x42] = 0xD6
	ram[0x0100 + 0x41] = 0x34
	ram[0x0100 + 0x42] = 0xD6
	ram[0x0036] = 0xE8
	ram[0x0037] = 0xD7
	ram[0x043B] = 1
	ram[0x061E] = 0x81
	ram[0x0621] = 0
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": 0xD7E8,
		"sp": 0x40,
		"a": 0xE8,
		"x": 0x57,
		"y": 0x04,
		"p": 0x80,
		"p_known_mask": 0x83,
		"bank_low": 0x1A,
		"bank_high": 0x1B,
		"executing_cpu_bank": 0x1E,
		"mapper_proof": {
			"banks_at_fixed_dispatch": [0x1C, 0x1D],
			"fixed_bank": 0x1E,
		},
		"ram_image": ram,
		"stack_page": stack,
		"trace_state_used": false,
	}


func _stack_write_matches(actual: Variant, source_pc: int, address: int,
		value: int, operation: String) -> bool:
	if not actual is Dictionary:
		return false
	return int(actual.get("source_pc", -1)) == source_pc \
			and int(actual.get("address", -1)) == address \
			and int(actual.get("value", -1)) == value \
			and String(actual.get("operation", "")) == operation


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
