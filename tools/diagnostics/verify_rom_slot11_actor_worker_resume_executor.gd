extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the synthetic live-contract fixture follows ROM bytes from `$804A` to the `$CC50->$CB0F` save entry.")
	print("LIMIT: this source-execution check is not a same-input FCEUX route comparison.")
	quit(0)


func _verify() -> bool:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$11 resume source package failed validation: " + executor.error_message)
	var missing: Dictionary = executor.execute_from_resumed_slot11_boundary({})
	if bool(missing.get("ok", false)) \
			or String(missing.get("status", "")) != "rejected_boundary" \
			or not String(missing.get("error", "")).contains("live dispatched slot-$11"):
		return _fail("Resume executor did not fail closed when its scheduler boundary was absent.")
	var wrong_rom: Dictionary = executor.execute_from_resumed_slot11_boundary({
		"rom_sha256": "wrong-rom",
		"slot_base": 0x11,
	})
	if bool(wrong_rom.get("ok", false)) \
			or String(wrong_rom.get("status", "")) != "rejected_boundary":
		return _fail("Resume executor accepted a boundary from another ROM revision.")
	var boundary := _supported_boundary()
	var result: Dictionary = executor.execute_from_resumed_slot11_boundary(boundary)
	if not bool(result.get("ok", false)):
		return _fail("Source-derived `$804A->$CC50->$CB0F` continuation failed: " + String(result.get("error", "unknown error")))
	var registers: Dictionary = result.get("cb0f_entry_registers", {})
	var callsite: Dictionary = result.get("yield_callsite_registers", {})
	var stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var callsite_stack: PackedByteArray = result.get("yield_callsite_stack_page", PackedByteArray())
	if int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(result.get("yield_callsite_pc", -1)) != 0xCC50 \
			or int(result.get("resume_pc_after_rts", -1)) != 0xCC53 \
			or int(registers.get("a", -1)) != 0x01 or int(registers.get("x", -1)) != 0x52 \
			or int(registers.get("y", -1)) != 0x0C or int(registers.get("sp", -1)) != 0xC1 \
			or int(callsite.get("sp", -1)) != 0xC3 or int(callsite.get("pc", -1)) != 0xCC50 \
			or not bool(result.get("call_frame_already_pushed", false)) \
			or stack.size() != 0x100 or callsite_stack.size() != 0x100 \
			or int(stack[0xC2]) != 0x52 or int(stack[0xC3]) != 0xCC \
			or int(stack[0xC4]) != 0x06 or int(stack[0xC5]) != 0xFF \
			or int(stack[0xC6]) != 0x81 or int(stack[0xC7]) != 0x7C \
			or int(stack[0xC8]) != 0x80 or int(stack[0xC9]) != 0x4C \
			or int(stack[0xCA]) != 0x80 \
			or int(callsite_stack[0xC4]) != 0x06 or int(callsite_stack[0xC5]) != 0xFF \
			or int(callsite_stack[0xC6]) != 0x81 or int(callsite_stack[0xC7]) != 0x7C:
		return _fail("The F4/F5 dispatch did not produce the expected CC50 callsite and nested JSR stack contract.")
	var ppu_events: Variant = result.get("ppu_bus_events", [])
	var apu_writes: Variant = result.get("apu_register_writes", [])
	if not ppu_events is Array or not apu_writes is Array \
			or not ppu_events.is_empty() or not apu_writes.is_empty():
		return _fail("The bounded path reported unsupported PPU/APU side effects.")
	var tail_result: Dictionary = executor.execute_from_slot11_waiter_resume_boundary(
		_supported_waiter_boundary(0x00))
	if not bool(tail_result.get("ok", false)) \
			or String(tail_result.get("status", "")) != "slot11_actor_waiter_tail_at_cb0f_from_cca0" \
			or int(tail_result.get("entry_pc", -1)) != 0xCC53 \
			or int(tail_result.get("yield_callsite_pc", -1)) != 0xCCA0 \
			or int(tail_result.get("resume_pc_after_rts", -1)) != 0xCCA3 \
			or int(tail_result.get("yield_callsite_registers", {}).get("sp", -1)) != 0xC4 \
			or int(tail_result.get("cb0f_entry_registers", {}).get("sp", -1)) != 0xC2:
		return _fail("The negative `$CC9C` pass count did not follow the packaged `$CC9E->$CCA0->$CB0F` tail.")
	var f5_tail_result: Dictionary = executor.execute_from_slot11_final_packet_return_boundary(
		_supported_final_packet_return_boundary())
	if not bool(f5_tail_result.get("ok", false)) \
			or String(f5_tail_result.get("status", "")) != "slot11_actor_f5_tail_returned_to_804d" \
			or int(f5_tail_result.get("entry_pc", -1)) != 0xCCD1 \
			or int(f5_tail_result.get("exit_pc", -1)) != 0x804D \
			or int(f5_tail_result.get("exit_registers", {}).get("sp", -1)) != 0xCA \
			or int(f5_tail_result.get("exit_registers", {}).get("a", -1)) != 0x80 \
			or int(f5_tail_result.get("exit_registers", {}).get("y", -1)) != 0x01 \
			or int(f5_tail_result.get("ram_image", PackedByteArray())[0x05F3]) != 0x0D \
			or int(f5_tail_result.get("ram_image", PackedByteArray())[0x05F4]) != 0x80 \
			or int(f5_tail_result.get("ram_image", PackedByteArray())[0x05E5]) != 0x02 \
			or int(f5_tail_result.get("ram_image", PackedByteArray())[0x05E9]) != 0x02 \
			or f5_tail_result.get("instruction_pcs", []) != [
			0xCCD1, 0x8200, 0x8202, 0x8205, 0x8207, 0x820A,
			0x820D, 0x820F, 0x8212, 0x8215, 0x8216, 0x8217,
		]:
		return _fail("The final packet RTS and F5 tail did not replay its parameter read and nested returns to `$804D`.")
	var animation_gate_boundary := _supported_f5_animation_gate_boundary(f5_tail_result)
	var animation_gate_result: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(
		animation_gate_boundary)
	if not bool(animation_gate_result.get("ok", false)) \
			or String(animation_gate_result.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(animation_gate_result.get("entry_pc", -1)) != 0x804D \
			or int(animation_gate_result.get("exit_pc", -1)) != 0xCB0F \
			or int(animation_gate_result.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(animation_gate_result.get("resume_pc_after_rts", -1)) != 0xA21A \
			or int(animation_gate_result.get("pre_jsr_sp", -1)) != 0xC6 \
			or int(animation_gate_result.get("yield_callsite_registers", {}).get("pc", -1)) != 0xA217 \
			or int(animation_gate_result.get("yield_callsite_registers", {}).get("a", -1)) != 0x01 \
			or int(animation_gate_result.get("yield_callsite_registers", {}).get("x", -1)) != 0x1A \
			or int(animation_gate_result.get("yield_callsite_registers", {}).get("y", -1)) != 0x01 \
			or int(animation_gate_result.get("cb0f_entry_registers", {}).get("sp", -1)) != 0xC4 \
			or int(animation_gate_result.get("mapper", {}).get("bank_low", -1)) != 0x1A \
			or int(animation_gate_result.get("mapper", {}).get("bank_high", -1)) != 0x1B \
			or int(animation_gate_result.get("ram_image", PackedByteArray())[0x0063]) != 0x25 \
			or int(animation_gate_result.get("ram_image", PackedByteArray())[0x0064]) != 0xA4 \
			or int(animation_gate_result.get("ram_image", PackedByteArray())[0x05F4]) != 0x01 \
			or int(animation_gate_result.get("ram_image", PackedByteArray())[0x05F5]) != 0x00 \
			or int(animation_gate_result.get("stack_page", PackedByteArray())[0xC5]) != 0x19 \
			or int(animation_gate_result.get("stack_page", PackedByteArray())[0xC6]) != 0xA2:
		return _fail("The `$804D->$CF72->$A1EB->$A217` ROM animation gate did not create the expected mapper/yield contract.")
	var a21a_boundary := _supported_a21a_animation_boundary(animation_gate_result)
	var a21a_result: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(a21a_boundary)
	if not bool(a21a_result.get("ok", false)) \
			or String(a21a_result.get("status", "")) != "slot11_f5_animation_queue_at_8047" \
			or int(a21a_result.get("entry_pc", -1)) != 0xA21A \
			or int(a21a_result.get("exit_pc", -1)) != 0x8047 \
			or int(a21a_result.get("resume_pc_after_rts", -1)) != 0x804A \
			or int(a21a_result.get("secondary_ppu_packets", []).size()) != 6 \
			or int(a21a_result.get("yield_callsite_registers", {}).get("a", -1)) != 0x01 \
			or int(a21a_result.get("yield_callsite_registers", {}).get("x", -1)) != 0x24 \
			or int(a21a_result.get("yield_callsite_registers", {}).get("y", -1)) != 0x24 \
			or int(a21a_result.get("yield_callsite_registers", {}).get("sp", -1)) != 0xCA \
			or int(a21a_result.get("mapper", {}).get("bank_low", -1)) != 0x18 \
			or int(a21a_result.get("mapper", {}).get("bank_high", -1)) != 0x19 \
			or int(a21a_result.get("ram_image", PackedByteArray())[0x0515]) != 0x80 \
			or int(a21a_result.get("ram_image", PackedByteArray())[0x0063]) != 0x27 \
			or int(a21a_result.get("ram_image", PackedByteArray())[0x0064]) != 0xA4 \
			or a21a_result.get("ram_image", PackedByteArray()).slice(0x04A5, 0x04CA) != PackedByteArray([
				0x04, 0xC8, 0x22, 0x00, 0xB4, 0xB5, 0xE0,
				0x04, 0xE8, 0x22, 0x00, 0xB6, 0xB7, 0xE2,
				0x04, 0x08, 0x23, 0x00, 0xBC, 0xBD, 0xE8,
				0x04, 0x28, 0x23, 0x00, 0xBE, 0xBF, 0xEA,
				0x01, 0xEA, 0x23, 0x50, 0x01, 0xF2, 0x23, 0x05, 0x00,
			]):
		return _fail("The `$A21A` ROM animation command did not build the six ordered PPU packets and restore/yield at `$8047`: %s" % str(a21a_result))
	return true


func _supported_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC7] = 0xE7
	stack[0xC8] = 0x42
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	ram[0x0026] = 0x00
	ram[0x005F] = 0x42
	ram[0x0060] = 0x9F
	ram[0x05E3] = 0x01
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x00
	ram[0x05E9] = 0x00
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804A, "sp": 0xCA, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC6, 0x18, 0x19]),
		"a": 0x42, "x": 0x42, "y": 0xE7, "p": 0x20, "p_known_mask": 0xC3,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
		"ram_image": ram, "stack_page": stack,
	}


func _supported_waiter_boundary(pass_count: int) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC2] = 0x52
	stack[0xC3] = 0xCC
	stack[0xC4] = pass_count & 0xFF
	stack[0xC5] = 0xFF
	stack[0xC6] = 0x81
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0xCC53, "sp": 0xC3, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xBF, 0x18, 0x19]),
		"a": 0x01, "x": 0x4F, "y": 0x00, "p": 0x20, "p_known_mask": 0xC3,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
		"ram_image": ram, "stack_page": stack,
	}


func _supported_final_packet_return_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0xC3] = 0xD0
	stack[0xC4] = 0xCC
	stack[0xC5] = 0xFF
	stack[0xC6] = 0x81
	stack[0xC7] = 0x7C
	stack[0xC8] = 0x80
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0000] = 0x11
	ram[0x005F] = 0x52
	ram[0x0060] = 0x9F
	ram[0x05E3] = 0x01
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x01
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0xCCD1, "sp": 0xC4, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC0, 0x18, 0x19]),
		"a": 0x01, "x": 0x21, "y": 0x00, "p": 0x30, "p_known_mask": 0xC3,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
		"ram_image": ram, "stack_page": stack,
	}


func _supported_f5_animation_gate_boundary(tail_result: Dictionary) -> Dictionary:
	var tail_ram: PackedByteArray = tail_result.get("ram_image", PackedByteArray())
	var tail_stack: PackedByteArray = tail_result.get("stack_page", PackedByteArray())
	var regs: Dictionary = tail_result.get("exit_registers", {})
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804D, "sp": int(regs.get("sp", -1)), "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC0, 0x18, 0x19]),
		"a": int(regs.get("a", -1)), "x": int(regs.get("x", -1)),
		"y": int(regs.get("y", -1)), "p": int(regs.get("p", -1)),
		"p_known_mask": int(regs.get("p_known_mask", -1)),
		"mapper": {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
			"bank_registers": {6: 0x18, 7: 0x19}},
		"ram_image": tail_ram, "stack_page": tail_stack,
	}


func _supported_a21a_animation_boundary(gate_result: Dictionary) -> Dictionary:
	var gate_ram: PackedByteArray = gate_result.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = gate_result.get("stack_page", PackedByteArray()).duplicate()
	var cb0f: Dictionary = gate_result.get("cb0f_entry_registers", {})
	stack[0xC4] = int(cb0f.get("x", -1))
	stack[0xC3] = int(cb0f.get("y", -1))
	for offset in stack.size():
		gate_ram[0x0100 + offset] = stack[offset]
	gate_ram[0x0011] = 0x00
	gate_ram[0x0012] = 0xC2
	gate_ram[0x0013] = 0x1A
	gate_ram[0x0014] = 0x1B
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0xA21A, "sp": 0xC6, "active_task_slot": 0x11,
		"bank_low": 0x1A, "bank_high": 0x1B,
		"record": PackedByteArray([0x00, 0xC2, 0x1A, 0x1B]),
		"a": 0x1A, "x": int(cb0f.get("x", -1)),
		"y": int(cb0f.get("y", -1)), "p": int(cb0f.get("p", -1)),
		"p_known_mask": int(cb0f.get("p_known_mask", -1)),
		"mapper": gate_result.get("mapper", {}).duplicate(true),
		"ram_image": gate_ram, "stack_page": stack,
	}


func _fail(message: String) -> bool:
	push_error(message)
	return false
