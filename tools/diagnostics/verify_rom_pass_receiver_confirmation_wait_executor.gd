extends SceneTree
## Verifies the bounded ROM-byte `$D70C->$CC46->$CC50` callsite prefix.
## This synthetic source boundary is an isolated executor fixture, not a live
## route result or an emulator snapshot.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_confirmation_wait_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not configure PASS confirmation waiter sources: " + executor.error_message)
		return
	var boundary := _make_boundary()
	var original_ram: PackedByteArray = boundary["ram_image"].duplicate()
	var original_stack: PackedByteArray = boundary["stack_page"].duplicate()
	var result: Dictionary = executor.execute_from_live_boundary(boundary)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_confirmation_wait_callsite_ready" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0xD70C \
			or int(result.get("entry_sp", -1)) != 0x4A \
			or int(result.get("exit_pc", -1)) != 0xCC50 \
			or int(result.get("exit_bank", -1)) != 0x1E \
			or result.get("mapper", {}) != boundary.get("mapper", {}) \
			or bool(result.get("task_save_executed", true)):
		_fail("The executor did not stop before the scheduler-owned `$CC50` JSR/save: " + str(result))
		return
	var registers: Dictionary = result.get("registers", {})
	var next_boundary: Dictionary = result.get("next_boundary_snapshot", {})
	var next_ram: PackedByteArray = next_boundary.get("ram_image", PackedByteArray())
	var next_stack: PackedByteArray = next_boundary.get("stack_page", PackedByteArray())
	var writes: Array = result.get("source_writes", [])
	var stack_writes: Array = result.get("source_stack_writes", [])
	var calls: Array = result.get("calls", [])
	var call_request: Dictionary = result.get("call_request", {})
	if int(registers.get("pc", -1)) != 0xCC50 \
			or int(registers.get("sp", -1)) != 0x47 \
			or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("x", -1)) != 0x00 \
			or int(registers.get("y", -1)) != 0x03 \
			or int(registers.get("p", -1)) != 0x31 \
			or writes.size() != 1 \
			or not _write_matches(writes[0], 0xCC48, 0x05F4, 0x00) \
			or stack_writes.size() != 3 \
			or not _stack_write_matches(stack_writes[0], 0xD70C, 0x014A, 0xD7, "jsr_push_high") \
			or not _stack_write_matches(stack_writes[1], 0xD70C, 0x0149, 0x0E, "jsr_push_low") \
			or not _stack_write_matches(stack_writes[2], 0xCC4D, 0x0148, 0x06, "pha"):
		_fail("The ROM-ordered D70C waiter operations or CPU stack differ from the source bytes: " + str(result))
		return
	if next_ram.size() != 0x0800 or next_stack.size() != 0x100 \
			or next_ram.slice(0x0100, 0x0200) != next_stack \
			or int(next_ram[0x05F4]) != 0 \
			or int(next_stack[0x46]) != 0 or int(next_stack[0x47]) != 0 \
			or int(next_stack[0x48]) != 0x06 \
			or int(next_stack[0x49]) != 0x0E or int(next_stack[0x4A]) != 0xD7 \
			or calls.size() != 1 \
			or int((calls[0] as Dictionary).get("callsite", -1)) != 0xD70C \
			or int((calls[0] as Dictionary).get("target", -1)) != 0xCC46 \
			or int((calls[0] as Dictionary).get("return_pc", -1)) != 0xD70F \
			or int(call_request.get("callsite_pc", -1)) != 0xCC50 \
			or int(call_request.get("target_pc", -1)) != 0xCB0F \
			or not bool(call_request.get("scheduler_must_push_call_frame", false)) \
			or bool(result.get("input_boundary_fixture", false)) != true \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)) \
			or bool(result.get("ppu_effects_applied", true)) \
			or bool(result.get("apu_effects_applied", true)) \
			or bool(result.get("source_cycle_timing_modeled", true)) \
			or boundary["ram_image"] != original_ram or boundary["stack_page"] != original_stack:
		_fail("The task-call boundary lost its return frames, source flags, or input immutability: " + str(result))
		return
	var invalid := boundary.duplicate(true)
	invalid["pc"] = 0xD714
	var rejected: Dictionary = executor.execute_from_live_boundary(invalid)
	if bool(rejected.get("ok", true)) or String(rejected.get("status", "")) != "invalid_live_boundary":
		_fail("The executor accepted a boundary outside the live `$D70C` source contract.")
		return
	print("PASS: ROM-derived `$D70C->$CC46` execution reaches `$CC50` with the original caller and PHA stack frames intact; the scheduler owns the `$CB0F` JSR/save.")
	quit(0)


func _make_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x0800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0000] = 0x05
	ram[0x0024] = 0x1C
	ram[0x0025] = 0x1D
	ram[0x0441] = 0x06
	ram[0x05FC] = 0x0A
	ram[0x05F4] = 0xA5
	ram[0x062D] = 0x81
	ram[0x0638] = 0x78
	# Keep the synthetic caller stack distinguishable from emulator memory.
	stack[0x3B] = 0xCC
	stack[0x3C] = 0x45
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": 0xD70C,
		"sp": 0x4A,
		"a": 0x78,
		"x": 0x00,
		"y": 0x03,
		"p": 0x31,
		"p_known_mask": 0xFF,
		"bank_low": 0x1C,
		"bank_high": 0x1D,
		"mapper": {"bank_low": 0x1C, "bank_high": 0x1D, "fixed_bank": 0x1E},
		"ram_image": ram,
		"stack_page": stack,
		"source_label": "synthetic D70C waiter fixture; not a route result",
		"test_fixture": true,
		"trace_state_used": false,
	}


func _write_matches(write_variant: Variant, source_pc: int,
		address: int, value: int) -> bool:
	if not write_variant is Dictionary:
		return false
	var write: Dictionary = write_variant
	return int(write.get("source_pc", -1)) == source_pc \
		and int(write.get("trace_pc", -1)) == ((source_pc + 3) & 0xFFFF) \
		and int(write.get("address", -1)) == address \
		and int(write.get("value", -1)) == value


func _stack_write_matches(write_variant: Variant, source_pc: int,
		address: int, value: int, role: String) -> bool:
	if not write_variant is Dictionary:
		return false
	var write: Dictionary = write_variant
	return int(write.get("source_pc", -1)) == source_pc \
		and int(write.get("address", -1)) == address \
		and int(write.get("value", -1)) == value \
		and String(write.get("role", "")) == role


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
