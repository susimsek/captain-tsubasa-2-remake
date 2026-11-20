extends SceneTree
## Focused ROM-source verifier for the bounded PASS receiver Down/A poll slices.
## Fixtures model live inputs/RAM for this isolated executor; they are not FCEUX
## snapshots and do not claim the production scheduler/renderer route.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_input_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not configure PASS receiver-input ROM spans: " + executor.error_message)
		return
	var source_status: Dictionary = executor.get_source_status()
	if not bool(source_status.get("configured", false)) \
			or String(source_status.get("rom_sha256", "")) != ROM_SHA256 \
			or String(source_status.get("scan_span_sha256", "")) \
			!= "516f3edfaef0868e42229d5f75c609596a21991962647d720037cd041c2d079a":
		_fail("The D8F7 poll/scanner source spans did not validate against the pinned ROM.")
		return

	var starting := _make_live_poll_fixture(0x04, 0x00)
	var original_ram: PackedByteArray = starting["ram_image"].duplicate()
	var original_stack: PackedByteArray = starting["stack_page"].duplicate()
	var down_result: Dictionary = executor.execute_after_input_poll(starting)
	if not bool(down_result.get("ok", false)) \
			or String(down_result.get("status", "")) != "receiver_down_scan_stopped_at_renderer_call" \
			or int(down_result.get("entry_pc", -1)) != 0xD80F \
			or int(down_result.get("exit_pc", -1)) != 0xEF7F \
			or int(down_result.get("entry_sp", -1)) != 0x40 \
			or int(down_result.get("final_sp", -1)) != 0x3C:
		_fail("Down did not stop at the source `$D96C->$EF7F` call boundary: " + str(down_result))
		return
	var down_boundary: Dictionary = down_result.get("next_boundary_snapshot", {})
	var down_ram: PackedByteArray = down_boundary.get("ram_image", PackedByteArray())
	var down_stack: PackedByteArray = down_boundary.get("stack_page", PackedByteArray())
	var down_cpu: Dictionary = down_result.get("registers", {})
	var writes: Array = down_result.get("source_writes", [])
	var stack_writes: Array = down_result.get("source_stack_writes", [])
	var stack_reads: Array = down_result.get("source_stack_reads", [])
	var renderers: Array = down_result.get("renderer_requests", [])
	if down_ram.size() != 0x800 or down_stack.size() != 0x100 \
			or down_ram.slice(0x0100, 0x0200) != down_stack \
			or int(down_ram[0x0624]) != 0x78 \
			or int(down_ram[0x0430]) != 1 \
			or int(down_ram[0x0431]) != 0x0A \
			or int(down_ram[0x0625]) != 1 \
			or int(down_ram[0x05FC]) != 0x0A \
			or int(down_ram[0x0441]) != 0x06 \
			or int(down_cpu.get("a", -1)) != 0x1D \
			or int(down_cpu.get("x", -1)) != 0 \
			or int(down_cpu.get("y", -1)) != 0x67 \
			or writes.size() != 7 \
			or not _write_matches(writes[0], 0xD82F, 0xD832, 0x0624, 0x78) \
			or not _write_matches(writes[1], 0xD8F9, 0xD8FC, 0x0430, 0) \
			or not _write_matches(writes[2], 0xD8FC, 0xD8FF, 0x0625, 0) \
			or not _write_matches(writes[3], 0xD934, 0xD937, 0x0431, 0x0A) \
			or not _write_matches(writes[4], 0xD937, 0xD93A, 0x0430, 1) \
			or not _write_matches(writes[5], 0xD93E, 0xD941, 0x0625, 1) \
			or not _write_matches(writes[6], 0xD967, 0xD96A, 0x05FC, 0x0A):
		_fail("The source Down scan did not derive the trace-observed `$77->$78` / slot-$0A candidate state: " + str(down_result))
		return
	if stack_writes.size() < 6 or stack_reads.is_empty() \
			or not _stack_write_matches(stack_writes[0], 0xD834, 0x0140, 0xD8, "jsr_push_high") \
			or not _stack_write_matches(stack_writes[1], 0xD834, 0x013F, 0x36, "jsr_push_low") \
			or not _stack_write_matches(stack_writes[stack_writes.size() - 2], 0xD96C, 0x013E, 0xD9, "jsr_push_high") \
			or not _stack_write_matches(stack_writes[stack_writes.size() - 1], 0xD96C, 0x013D, 0x6E, "jsr_push_low") \
			or int(down_stack[0x3E]) != 0xD9 \
			or int(down_stack[0x3D]) != 0x6E \
			or int(down_stack[0x3C]) != 0x1C:
		_fail("The Down scan omitted transient PHA/PLA and CD7C/CDE2 stack state or the `$D96C->$EF7F` JSR frame.")
		return
	if renderers.size() != 1 or not renderers[0] is Dictionary \
			or int(renderers[0].get("source_pc", -1)) != 0xD96C \
			or int(renderers[0].get("entry_pc", -1)) != 0xEF7F \
			or int(renderers[0].get("return_pc", -1)) != 0xD96F \
			or int(renderers[0].get("descriptor_id", -1)) != 0x1D \
			or bool(renderers[0].get("ppu_effects_applied", true)):
		_fail("The scan must expose the ROM `$D96C` descriptor-$1D renderer call as pending.")
		return
	if bool(down_result.get("trace_state_used", true)) \
			or bool(down_result.get("emulator_data_used", true)) \
			or bool(down_result.get("ppu_effects_applied", true)) \
			or bool(down_result.get("holder_transfer_applied", true)) \
			or int(starting["ram_image"][0x0624]) != 0x77 \
			or starting["ram_image"] != original_ram \
			or starting["stack_page"] != original_stack:
		_fail("The bounded Down executor must keep captures out of runtime state and preserve its input boundary.")
		return

	# The verifier drives a distinct later A-only poll fixture using the source
	# RAM state produced above. It does not claim to execute EF7F or the scheduler.
	var confirm_ram: PackedByteArray = down_ram.duplicate()
	var confirm_stack: PackedByteArray = original_stack.duplicate()
	confirm_ram[0x001C] = 0
	confirm_ram[0x001E] = 0x80
	for stack_index in confirm_stack.size():
		confirm_ram[0x0100 + stack_index] = confirm_stack[stack_index]
	var confirm_boundary := _make_boundary(confirm_ram, confirm_stack, 0x40, 0x00, 0x80)
	var confirm_result: Dictionary = executor.execute_after_input_poll(confirm_boundary)
	if not bool(confirm_result.get("ok", false)) \
			or String(confirm_result.get("status", "")) != "receiver_confirmed_at_d70c_before_holder_transfer" \
			or int(confirm_result.get("exit_pc", -1)) != 0xD70C:
		_fail("A-only confirmation did not stop at `$D70C`: " + str(confirm_result))
		return
	var confirm_out: Dictionary = confirm_result.get("next_boundary_snapshot", {})
	var confirm_out_ram: PackedByteArray = confirm_out.get("ram_image", PackedByteArray())
	var confirm_writes: Array = confirm_result.get("source_writes", [])
	if confirm_out_ram.size() != 0x800 \
			or int(confirm_out_ram[0x05FC]) != 0x0A \
			or int(confirm_out_ram[0x0638]) != 0x78 \
			or int(confirm_out_ram[0x02FC]) != 0xF8 \
			or int(confirm_out_ram[0x0441]) != 0x06 \
			or confirm_writes.size() != 3 \
			or not _write_matches(confirm_writes[0], 0xD862, 0xD865, 0x05FC, 0x0A) \
			or not _write_matches(confirm_writes[1], 0xD8CF, 0xD8D2, 0x02FC, 0xF8) \
			or not _write_matches(confirm_writes[2], 0xD8D5, 0xD8D8, 0x0638, 0x78) \
			or bool(confirm_result.get("holder_transfer_applied", true)) \
			or bool(confirm_result.get("trace_state_used", true)) \
			or bool(confirm_result.get("emulator_data_used", true)):
		_fail("A confirmation must record ROM writes `$05FC/$02FC/$0638` and stop before holder transfer.")
		return

	for invalid_case in [
		{"name": "wrong PC", "key": "pc", "value": 0xD80E},
		{"name": "wrong fixed bank", "key": "executing_cpu_bank", "value": 0x1D},
		{"name": "trace-seeded", "key": "trace_state_used", "value": true},
	]:
		var invalid: Dictionary = _make_live_poll_fixture(0x04, 0x00)
		invalid[String(invalid_case["key"])] = invalid_case["value"]
		var rejected: Dictionary = executor.execute_after_input_poll(invalid)
		if bool(rejected.get("ok", true)):
			_fail("Executor accepted %s source boundary." % String(invalid_case["name"]))
			return
	var bad_latch: Dictionary = _make_live_poll_fixture(0x04, 0x00)
	var bad_ram: PackedByteArray = bad_latch["ram_image"].duplicate()
	bad_ram[0x001C] = 0x02
	bad_latch["ram_image"] = bad_ram
	var latch_result: Dictionary = executor.execute_after_input_poll(bad_latch)
	if bool(latch_result.get("ok", true)) or String(latch_result.get("status", "")) != "input_latch_mismatch":
		_fail("Executor accepted a controller mask that disagrees with live `$001C/$001E`.")
		return
	var bad_stack: Dictionary = _make_live_poll_fixture(0x04, 0x00)
	var bad_stack_page: PackedByteArray = bad_stack["stack_page"].duplicate()
	bad_stack_page[0x41] ^= 0x01
	bad_stack["stack_page"] = bad_stack_page
	var stack_result: Dictionary = executor.execute_after_input_poll(bad_stack)
	if bool(stack_result.get("ok", true)) or String(stack_result.get("status", "")) != "stack_mirror_mismatch":
		_fail("Executor accepted a stack page that disagrees with its RAM mirror.")
		return

	print("PASS: hash-checked `$D80F->$D8F7` Down semantics derive cursor `$78`, candidate `$0A`, `$0625=$01`, `$05FC=$0A`, and the exact `$EF7F` descriptor-$1D call/JSR stack boundary.")
	print("PASS: a later A-only poll follows `$D852->$D70C`, writes `$05FC=$0A`, `$02FC=$F8`, `$0638=$78`, and leaves holder `$0441` unchanged.")
	print("LIMIT: verifier fixtures are isolated source-state fixtures; EF7F rendering, scheduler handoff, live route integration, holder transfer, PPU/APU, and FCEUX parity are not verified here.")
	quit(0)


func _make_live_poll_fixture(direction: int, buttons: int) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	# An unrelated source return word keeps the fixture's live stack non-empty.
	stack[0x41] = 0x34
	stack[0x42] = 0xD6
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	ram[0x001C] = direction & 0xFF
	ram[0x001E] = buttons & 0xFF
	ram[0x0024] = 0x1A
	ram[0x0025] = 0x1B
	ram[0x0441] = 0x06
	ram[0x0624] = 0x77
	ram[0x0625] = 0
	ram[0x0430] = 0
	# Place one synthetic live player record so the ROM coordinate helper maps it
	# to tile $78. This is test data, not an emulator-derived player position.
	var receiver_record := 0x0300 + 0x0A * 0x0C
	ram[receiver_record + 6] = 0x80
	ram[receiver_record + 8] = 0x50
	# The final scanned slot makes the source's Y register at `$D96C` explicit.
	var last_record := 0x0300 + 0x15 * 0x0C
	ram[last_record + 8] = 0x67
	return _make_boundary(ram, stack, 0x40, direction, buttons)


func _make_boundary(ram: PackedByteArray, stack: PackedByteArray, sp: int,
		direction: int, buttons: int) -> Dictionary:
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": 0xD80F,
		"sp": sp,
		"a": 0,
		"x": 0,
		"y": 0,
		"p": 0x30,
		"p_known_mask": 0xFF,
		"executing_cpu_bank": 0x1E,
		"mapper": {
			"cpu_c000_bank": 0x1E,
			"cpu_e000_bank": 0x1F,
			"bank_registers": {6: int(ram[0x0024]), 7: int(ram[0x0025])},
		},
		"ram_image": ram.duplicate(),
		"stack_page": stack.duplicate(),
		"polled_controller": {"direction_mask": direction, "button_mask": buttons},
		"trace_state_used": false,
		"emulator_data_used": false,
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


func _stack_write_matches(actual: Variant, source_pc: int, address: int,
		value: int, operation: String) -> bool:
	if not actual is Dictionary:
		return false
	var write: Dictionary = actual
	return int(write.get("source_pc", -1)) == source_pc \
			and int(write.get("address", -1)) == address \
			and int(write.get("value", -1)) == value \
			and String(write.get("operation", "")) == operation


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
