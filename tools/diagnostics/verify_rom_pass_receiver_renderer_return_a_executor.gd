extends SceneTree
## Verifies the ROM-byte A continuation from a synthetic `$D837` boundary
## produced by the bounded `$D96F` bridge. It is not route or emulator evidence.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_input_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not configure the pinned receiver-input ROM sources: " + executor.error_message)
		return
	var boundary := _make_bridge_return_fixture()
	var original_ram: PackedByteArray = boundary["ram_image"].duplicate()
	var original_stack: PackedByteArray = boundary["stack_page"].duplicate()
	var result: Dictionary = executor.execute_after_receiver_renderer_return(boundary)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "receiver_confirmed_at_d70c_from_renderer_return" \
			or int(result.get("entry_pc", -1)) != 0xD837 \
			or int(result.get("exit_pc", -1)) != 0xD70C:
		_fail("The ROM A-edge continuation did not reach `$D70C`: " + str(result))
		return
	var out_ram: PackedByteArray = result.get("next_boundary_snapshot", {}).get("ram_image", PackedByteArray())
	var out_stack: PackedByteArray = result.get("next_boundary_snapshot", {}).get("stack_page", PackedByteArray())
	var writes: Array = result.get("source_writes", [])
	var stack_writes: Array = result.get("source_stack_writes", [])
	var stack_reads: Array = result.get("source_stack_reads", [])
	var registers: Dictionary = result.get("registers", {})
	var expected_ram: PackedByteArray = original_ram.duplicate()
	expected_ram[0x05FC] = 0x0A
	expected_ram[0x0638] = 0x78
	expected_ram[0x013F] = 0x48
	expected_ram[0x0140] = 0xD8
	if out_ram.size() != 0x800 or out_stack.size() != 0x100 \
			or out_ram != expected_ram or out_ram.slice(0x0100, 0x0200) != out_stack \
			or int(out_ram[0x05FC]) != 0x0A or int(out_ram[0x0638]) != 0x78 \
			or int(out_ram[0x0441]) != 0x06 or int(out_ram[0x02FC]) != int(original_ram[0x02FC]) \
			or int(registers.get("a", -1)) != 0x78 or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != int(boundary["y"]) \
			or int(registers.get("sp", -1)) != int(boundary["sp"]) \
			or (int(registers.get("p", -1)) & 0xC3) != 0x01 \
			or (int(registers.get("p", -1)) & 0x30) != (int(boundary["p"]) & 0x30) \
			or writes.size() != 2 \
			or not _write_matches(writes[0], 0xD862, 0xD865, 0x05FC, 0x0A) \
			or not _write_matches(writes[1], 0xD8D5, 0xD8D8, 0x0638, 0x78) \
			or stack_writes.size() != 2 \
			or not _stack_matches(stack_writes[0], 0xD846, 0x0140, 0xD8, "jsr_push_high") \
			or not _stack_matches(stack_writes[1], 0xD846, 0x013F, 0x48, "jsr_push_low") \
			or stack_reads.size() != 2 \
			or not _stack_matches(stack_reads[0], 0xD8D9, 0x013F, 0x48, "rts_pop_return_low") \
			or not _stack_matches(stack_reads[1], 0xD8D9, 0x0140, 0xD8, "rts_pop_return_high") \
			or result.get("source_instruction_pcs", []) != [0xD837, 0xD839, 0xD83C, 0xD83F,
				0xD841, 0xD844, 0xD846, 0xD852, 0xD854, 0xD857, 0xD859, 0xD85C,
				0xD85D, 0xD85F, 0xD862, 0xD865, 0xD8D2, 0xD8D5, 0xD8D8,
				0xD8D9, 0xD849, 0xD84B] \
			or bool(result.get("holder_transfer_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or not bool(result.get("test_fixture", false)):
		_fail("D837 A execution, writes, stack call/return, or stop boundary differs from ROM: " + str(result))
		return
	if boundary["ram_image"] != original_ram or boundary["stack_page"] != original_stack:
		_fail("The source executor mutated its input bridge boundary.")
		return

	var bad_input := _make_bridge_return_fixture()
	var bad_input_ram: PackedByteArray = bad_input["ram_image"].duplicate()
	bad_input_ram[0x001E] = 0
	bad_input["ram_image"] = bad_input_ram
	var rejected_input: Dictionary = executor.execute_after_receiver_renderer_return(bad_input)
	if bool(rejected_input.get("ok", true)) \
			or String(rejected_input.get("status", "")) != "unsupported_receiver_input":
		_fail("The D837 continuation accepted a boundary without the A edge in `$001E`.")
		return

	var bad_stack := _make_bridge_return_fixture()
	var bad_stack_page: PackedByteArray = bad_stack["stack_page"].duplicate()
	bad_stack_page[0x3F] = 0x37
	bad_stack["stack_page"] = bad_stack_page
	var bad_stack_ram: PackedByteArray = bad_stack["ram_image"].duplicate()
	bad_stack_ram[0x013F] = 0x37
	bad_stack["ram_image"] = bad_stack_ram
	var rejected_stack: Dictionary = executor.execute_after_receiver_renderer_return(bad_stack)
	if bool(rejected_stack.get("ok", true)) \
			or String(rejected_stack.get("status", "")) != "invalid_receiver_return_stack":
		_fail("The D837 continuation accepted a boundary without the bridge's exact return stack.")
		return

	var wrong_pc := _make_bridge_return_fixture()
	wrong_pc["pc"] = 0xD80F
	var rejected_pc: Dictionary = executor.execute_after_receiver_renderer_return(wrong_pc)
	if bool(rejected_pc.get("ok", true)):
		_fail("The D837 continuation accepted a fabricated `$D80F` input-poll entry.")
		return

	print("PASS: hash-pinned `$D837->$D846->$D852->$D70C` consumes `$001E=$80` and confirms receiver `$0A`.")
	print("PASS: ROM writes only `$05FC=$0A` and `$0638=$78`; JSR/RTS stack effects and final SP are verified.")
	print("LIMIT: synthetic bridge-boundary fixture only; live route, renderer, NMI, pixels, audio, and frame timing are not verified.")
	quit(0)


func _make_bridge_return_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	ram[0x0000] = 0x05
	ram[0x001C] = 0
	ram[0x001E] = 0x80
	ram[0x0024] = 0x1C
	ram[0x0025] = 0x1D
	ram[0x0441] = 0x06
	ram[0x0430] = 1
	ram[0x0431] = 0x0A
	ram[0x0624] = 0x78
	ram[0x0625] = 1
	ram[0x05FC] = 0x0A
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	stack[0x3D] = 0x6E
	stack[0x3E] = 0xD9
	stack[0x3F] = 0x36
	stack[0x40] = 0xD8
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	var registers := {"a": 0x1D, "x": 0, "y": 0x67,
		"p": 0x71, "p_known_mask": 0xFF, "sp": 0x40, "pc": 0xD837}
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": 0xD837,
		"executing_cpu_bank": 0x1E,
		"sp": 0x40,
		"a": 0x1D, "x": 0, "y": 0x67, "p": 0x71, "p_known_mask": 0xFF,
		"bank_low": 0x1C, "bank_high": 0x1D,
		"mapper": {"bank_low": 0x1C, "bank_high": 0x1D, "select": 0x07,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"registers": registers,
		"ram_image": ram,
		"stack_page": stack,
		"source_label": "ROM `$D96F` RTS returned from PASS receiver descriptor renderer to `$D837`",
		"trace_state_used": false,
		"emulator_data_used": false,
		"test_fixture": true,
	}


func _write_matches(actual: Variant, source_pc: int, trace_pc: int,
		address: int, value: int) -> bool:
	if not actual is Dictionary:
		return false
	var write: Dictionary = actual
	return int(write.get("source_pc", -1)) == source_pc \
			and int(write.get("trace_pc", -1)) == trace_pc \
			and int(write.get("address", -1)) == address \
			and int(write.get("value", -1)) == value


func _stack_matches(actual: Variant, source_pc: int, address: int,
		value: int, operation: String) -> bool:
	if not actual is Dictionary:
		return false
	var stack_event: Dictionary = actual
	return int(stack_event.get("source_pc", -1)) == source_pc \
			and int(stack_event.get("address", -1)) == address \
			and int(stack_event.get("value", -1)) == value \
			and String(stack_event.get("operation", "")) == operation


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
