extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-byte fixtures preserve the `$F4 $04` wait path and resolve the live `$F4 $03` selector through `$0629` to `$A3C9`.")
	print("PASS: selector-$03 resolves `$A3BD->$A3C9`, stores its `$01` delay, runs the `$804D` wrapper, and yields at `$8047`.")
	print("PASS: the traced `$20` event resolves its type-2 ROM payload and reaches the `$8266->$CB0F` yield.")
	print("PASS: the repeated frame-9477 scenario-$2E actor-$6D signature executes its ROM `$F2` waiter through `$CC50->$CB0F`.")
	print("PASS: frame-9478/9479 `$CC53` resumes emit the ROM packet and decrement the actor-$6D F2 count 6→5→4.")
	print("PASS: selector-$03 row `$02` follows ROM `$82F2->$82F4->$CB0F`, preserving its `$82F7` resume frame.")
	print("PASS: selector-$03 row `$02` `$F0` command dispatches to ROM `$8098` and returns through `$804D->$8047`.")
	print("PASS: the inactive selector-$03 countdown reaches the `$A217->$CB0F` animation gate when `$05F5` reaches zero.")
	print("PASS: `$A21A` preserves its active loop while the secondary queue is pending and resumes only after external NMI consumption.")
	print("PASS: slot-$11 animation index `$02` loads hash-checked ROM spans, dispatches packet events `$05-$07`, and follows `$A2FA->$A2E8->$A2EA`.")
	print("LIMIT: live full-route reconciliation and visible field output remain open.")
	quit(0)


func _verify() -> bool:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$11 resume source package failed validation: " + executor.error_message)
	var scenario1c_parameter00: Dictionary = executor.execute_from_resumed_slot11_boundary(
		_scenario1c_parameter00_boundary())
	var scenario1c_registers: Dictionary = scenario1c_parameter00.get("cb0f_entry_registers", {})
	var scenario1c_stack: PackedByteArray = scenario1c_parameter00.get("stack_page", PackedByteArray())
	if not bool(scenario1c_parameter00.get("ok", false)) \
			or String(scenario1c_parameter00.get("stream_route", "")) != "scenario1c_parameter00_f2_terminal" \
			or int(scenario1c_registers.get("pc", -1)) != 0xCB0F \
			or int(scenario1c_registers.get("sp", -1)) != 0xC3 \
			or int(scenario1c_registers.get("a", -1)) != 0x01 \
			or int(scenario1c_registers.get("x", -1)) != 0x00 \
			or int(scenario1c_registers.get("y", -1)) != 0x06 \
			or scenario1c_stack.slice(0xC4, 0xC9) != PackedByteArray([0x52, 0xCC, 0x06, 0x7C, 0x80]) \
			or bool(scenario1c_parameter00.get("trace_state_used", true)):
		return _fail("The live scenario-$1C parameter-$00 `$9400` F2 stream did not reach its ROM-derived `$CC50->$CB0F` save boundary: %s" % str(scenario1c_parameter00.get("error", "unknown error")))
	var scenario2e_f2_waiter: Dictionary = executor.execute_from_resumed_slot11_boundary(
		_scenario2e_actor6d_f2_waiter_entry_boundary())
	var scenario2e_callsite: Dictionary = scenario2e_f2_waiter.get("yield_callsite_registers", {})
	var scenario2e_callsite_stack: PackedByteArray = scenario2e_f2_waiter.get(
		"yield_callsite_stack_page", PackedByteArray())
	var scenario2e_stack_writes: Array = scenario2e_f2_waiter.get("stack_writes", [])
	var scenario2e_ram: PackedByteArray = scenario2e_f2_waiter.get("ram_image", PackedByteArray())
	if not bool(scenario2e_f2_waiter.get("ok", false)) \
			or String(scenario2e_f2_waiter.get("stream_route", "")) != \
			"scenario2e_callback36_map2f_parameter6d_f2_waiter" \
			or int(scenario2e_f2_waiter.get("exit_pc", -1)) != 0xCB0F \
			or int(scenario2e_f2_waiter.get("yield_callsite_pc", -1)) != 0xCC50 \
			or int(scenario2e_callsite.get("pc", -1)) != 0xCC50 \
			or int(scenario2e_callsite.get("a", -1)) != 0x01 \
			or int(scenario2e_callsite.get("x", -1)) != 0xE3 \
			or int(scenario2e_callsite.get("y", -1)) != 0x06 \
			or scenario2e_callsite_stack.slice(0xC6, 0xCB) != PackedByteArray([0x06, 0x7C, 0x80, 0x4C, 0x80]) \
			or scenario2e_stack_writes.filter(func(write: Dictionary) -> bool:
				return int(write.get("pc", -1)) in [0xCC4D, 0xCC50]) != [
				{"pc": 0xCC4D, "address": 0x01C6, "value": 0x06, "kind": "PHA"},
				{"pc": 0xCC50, "address": 0x01C5, "value": 0xCC, "kind": "JSR_high"},
				{"pc": 0xCC50, "address": 0x01C4, "value": 0x52, "kind": "JSR_low"},
			] \
			or scenario2e_ram.size() != 0x800 \
			or int(scenario2e_ram[0x05E5]) != 0x01 \
			or int(scenario2e_ram[0x05F4]) != 0x00 \
			or bool(scenario2e_f2_waiter.get("trace_state_used", true)):
		return _fail("The frame-9477 scenario-$2E actor-$6D `$F2` waiter entry did not execute its ROM `$CC50->$CB0F` path: %s" % str(scenario2e_f2_waiter.get("error", "unknown error")))
	print("PASS: frame-9477 scenario-$2E actor-$6D signature executed `$9BE3->$80B5->$C52D->$CC46->$CC50->$CB0F`.")
	for wait_count: int in [0x06, 0x05]:
		var waiter_result: Dictionary = executor.execute_from_slot11_waiter_resume_boundary(
			_scenario2e_actor6d_f2_waiter_resume_boundary(wait_count))
		var waiter_ram: PackedByteArray = waiter_result.get("ram_image", PackedByteArray())
		var waiter_stack: PackedByteArray = waiter_result.get("stack_page", PackedByteArray())
		if not bool(waiter_result.get("ok", false)) \
				or int(waiter_result.get("entry_pc", -1)) != 0xCC53 \
				or int(waiter_result.get("exit_pc", -1)) != 0xCB0F \
				or int(waiter_result.get("yield_callsite_pc", -1)) != 0xCC50 \
				or waiter_ram.size() != 0x800 or int(waiter_ram[0x0515]) != 0x80 \
				or waiter_stack.size() != 0x100 \
				or int(waiter_stack[0xC6]) != wait_count - 1 \
				or bool(waiter_result.get("trace_state_used", true)):
			return _fail("The scenario-$2E actor-$6D `$CC53` F2 waiter failed its count-%d packet yield: %s" % [
				wait_count, str(waiter_result.get("error", "unknown error"))])
	var scenario2e_type5_event: Dictionary = executor.execute_from_slot11_scenario2e_actor6d_type5_event_boundary(
		_scenario2e_actor6d_type5_event_boundary())
	var scenario2e_type5_callsite: Dictionary = scenario2e_type5_event.get("yield_callsite_registers", {})
	var scenario2e_type5_ram: PackedByteArray = scenario2e_type5_event.get("ram_image", PackedByteArray())
	var scenario2e_type5_stack: PackedByteArray = scenario2e_type5_event.get("stack_page", PackedByteArray())
	var scenario2e_type5_decoded: Dictionary = scenario2e_type5_event.get("decoded_event", {})
	if not bool(scenario2e_type5_event.get("ok", false)) \
			or String(scenario2e_type5_event.get("status", "")) != "slot11_actor_event_payload_at_cb0f" \
			or int(scenario2e_type5_event.get("entry_pc", -1)) != 0x804A \
			or int(scenario2e_type5_event.get("exit_pc", -1)) != 0xCB0F \
			or int(scenario2e_type5_event.get("yield_callsite_pc", -1)) != 0x8266 \
			or int(scenario2e_type5_event.get("resume_pc_after_rts", -1)) != 0x8269 \
			or int(scenario2e_type5_callsite.get("sp", -1)) != 0xC5 \
			or int(scenario2e_type5_callsite.get("a", -1)) != 0x01 \
			or int(scenario2e_type5_callsite.get("x", -1)) != 0x0A \
			or int(scenario2e_type5_callsite.get("y", -1)) != 0x03 \
			or scenario2e_type5_ram.size() != 0x800 \
			or scenario2e_type5_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x14, 0x06, 0x00, 0x6D]) \
			or scenario2e_type5_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x02, 0x80, 0x01]) \
			or scenario2e_type5_ram.slice(0x0061, 0x0063) != PackedByteArray([0xBF, 0x8F]) \
			or scenario2e_type5_stack.slice(0xC6, 0xC9) != PackedByteArray([0x22, 0x2C, 0x0A]) \
			or int(scenario2e_type5_decoded.get("address", -1)) != 0x9BFF \
			or int(scenario2e_type5_decoded.get("byte", -1)) != 0x52 \
			or int(scenario2e_type5_decoded.get("type", -1)) != 0x05 \
			or int(scenario2e_type5_decoded.get("type_value", -1)) != 0x0E \
			or int(scenario2e_type5_decoded.get("payload_address", -1)) != 0x8FBF \
			or scenario2e_type5_decoded.get("payload", PackedByteArray()) != PackedByteArray([0x2C, 0x22, 0x14]) \
			or not _has_source_read(scenario2e_type5_event, 0x9BFF, 0x52, "actor_event_byte") \
			or not _has_source_read(scenario2e_type5_event, 0x86BD, 0x0E, "actor_event_type_value") \
			or not _has_source_read(scenario2e_type5_event, 0x8DCC, 0xBF, "actor_event_payload_pointer_low") \
			or not _has_source_read(scenario2e_type5_event, 0x8DCD, 0x8F, "actor_event_payload_pointer_high") \
			or not _has_source_read(scenario2e_type5_event, 0x8FBF, 0x2C, "actor_event_payload_byte_0") \
			or not _has_source_read(scenario2e_type5_event, 0x8FC0, 0x22, "actor_event_payload_byte_1") \
			or not _has_source_read(scenario2e_type5_event, 0x8FC1, 0x14, "actor_event_payload_byte_2") \
			or bool(scenario2e_type5_event.get("trace_state_used", true)):
		return _fail("Frame-9488 actor-$6D type-$05 event did not reproduce its `$9BFF->$8FBF->$8266->$CB0F` ROM path: %s" % str(scenario2e_type5_event.get("reason", scenario2e_type5_event.get("error", "unknown error"))))
	print("PASS: frame-9488 scenario-$2E actor-$6D `$52` event resolves `$86BD/$8DCC->$8FBF`, emits `$2C $22 $14`, and yields at `$8266->$CB0F`.")
	var scenario1c_zero_mode: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(
		_scenario1c_f0_zero_mode_boundary())
	var scenario1c_zero_callsite: Dictionary = scenario1c_zero_mode.get("yield_callsite_registers", {})
	if not bool(scenario1c_zero_mode.get("ok", false)) \
			or String(scenario1c_zero_mode.get("status", "")) != "slot11_actor_scenario1c_f0_zero_mode_gate_at_8047" \
			or int(scenario1c_zero_mode.get("entry_pc", -1)) != 0x804D \
			or int(scenario1c_zero_mode.get("exit_pc", -1)) != 0x8047 \
			or int(scenario1c_zero_mode.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(scenario1c_zero_mode.get("yield_target_pc", -1)) != 0xCB0F \
			or int(scenario1c_zero_callsite.get("a", -1)) != 0x01 \
			or int(scenario1c_zero_callsite.get("x", -1)) != 0x21 \
			or int(scenario1c_zero_callsite.get("y", -1)) != 0x02 \
			or bool(scenario1c_zero_mode.get("trace_state_used", true)):
		return _fail("Scenario-$1C `$F0` zero-mode did not follow `$804D->$C560->$A1EB RTS->$8047->$CB0F`: %s" % str(scenario1c_zero_mode.get("error", "unknown error")))
	var parameter47_gate: Dictionary = executor.execute_from_slot11_f5_animation_gate_boundary(
		_parameter47_f2_boundary(false))
	if not bool(parameter47_gate.get("ok", false)) or int(parameter47_gate.get("exit_pc", -1)) != 0x8047:
		return _fail("The traced parameter-$47 F2 zero-mode gate failed: " + str(parameter47_gate.get("reason", parameter47_gate.get("error", "unknown error"))))
	var parameter47_packet_wait: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_parameter47_f2_boundary(true))
	var parameter47_callsite: Dictionary = parameter47_packet_wait.get("yield_callsite_registers", {})
	if not bool(parameter47_packet_wait.get("ok", false)) \
			or String(parameter47_packet_wait.get("status", "")) != "slot11_actor_packet_wait_at_cb0f" \
			or int(parameter47_packet_wait.get("yield_callsite_pc", -1)) != 0x82F4 \
			or int(parameter47_packet_wait.get("resume_pc_after_rts", -1)) != 0x82F7 \
			or int(parameter47_callsite.get("a", -1)) != 0x01 \
			or int(parameter47_callsite.get("x", -1)) != 0x24 \
			or int(parameter47_callsite.get("y", -1)) != 0x06:
		return _fail("Parameter-$47 animation index-$01 did not reach the `$82F4->$CB0F` wait with its `$82F7` frame and source registers: " + str(parameter47_packet_wait))
	var parameter47_packet_resume: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(
		_parameter47_index1_packet_resume_boundary(parameter47_packet_wait))
	if not bool(parameter47_packet_resume.get("ok", false)):
		return _fail("The source-derived parameter-$47 index-$01 `$82F7` continuation failed: " + String(parameter47_packet_resume.get("reason", parameter47_packet_resume.get("error", "unknown error"))))
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
	var selector03_result: Dictionary = executor.execute_from_resumed_slot11_boundary(
		_supported_selector03_boundary())
	var selector03_error := String(selector03_result.get("error", ""))
	if bool(selector03_result.get("ok", false)) \
			or String(selector03_result.get("status", "")) != "unsupported_live_branch" \
			or not selector03_error.contains("ROM `$A3BD` selector `$03` resolved `$A3C9`") \
			or not selector03_error.contains("`$8080` reads the first `$01` delay byte"):
		return _fail("The live selector-$03 fixture did not resolve `$0629` through `$A3BD` to `$A3C9` before the documented `$804D` continuation gap: %s" % selector03_error)
	var selector03_tick: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_boundary())
	if not bool(selector03_tick.get("ok", false)) \
			or String(selector03_tick.get("status", "")) != "slot11_actor_sequence_selector03_delay_at_8047" \
			or int(selector03_tick.get("entry_pc", -1)) != 0x804A \
			or int(selector03_tick.get("exit_pc", -1)) != 0x8047 \
			or int(selector03_tick.get("yield_callsite_registers", {}).get("a", -1)) != 0x01 \
			or int(selector03_tick.get("yield_callsite_registers", {}).get("x", -1)) != 0xC9 \
			or int(selector03_tick.get("yield_callsite_registers", {}).get("y", -1)) != 0x00 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x005F]) != 0xC9 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x0060]) != 0xA3 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x05E4]) != 0x01 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x05E5]) != 0x01 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x05E9]) != 0x01 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x05F4]) != 0x00 \
			or int(selector03_tick.get("ram_image", PackedByteArray())[0x05F5]) != 0x6C:
		return _fail("Selector-$03 first-delay worker tick differs from the source route and frame-8624 FCEUX boundary: " + str(selector03_tick))
	var selector03_delay_tick: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_delay_boundary())
	if not bool(selector03_delay_tick.get("ok", false)) \
			or String(selector03_delay_tick.get("status", "")) != "slot11_actor_sequence_selector03_delay_at_8047" \
			or int(selector03_delay_tick.get("ram_image", PackedByteArray())[0x05E9]) != 0 \
			or int(selector03_delay_tick.get("ram_image", PackedByteArray())[0x05F5]) != 0x6C \
			or int(selector03_delay_tick.get("yield_callsite_registers", {}).get("x", -1)) != 0xC9 \
			or int(selector03_delay_tick.get("yield_callsite_registers", {}).get("y", -1)) != 0:
		return _fail("Selector-$03 one-tick delay decrement differs from the frame-8625 FCEUX worker resume.")
	var selector03_event: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_event_boundary())
	if not bool(selector03_event.get("ok", false)):
		return _fail("The frame-8626 selector-$03 `$20` event did not reach its ROM-derived queue yield: "
				+ String(selector03_event.get("error", "unknown error")))
	var event_registers: Dictionary = selector03_event.get("yield_callsite_registers", {})
	var event_ram: PackedByteArray = selector03_event.get("ram_image", PackedByteArray())
	var event_stack: PackedByteArray = selector03_event.get("stack_page", PackedByteArray())
	var decoded_event: Dictionary = selector03_event.get("decoded_event", {})
	if String(selector03_event.get("status", "")) != "slot11_actor_event_payload_at_cb0f" \
			or int(selector03_event.get("entry_pc", -1)) != 0x804A \
			or int(selector03_event.get("exit_pc", -1)) != 0xCB0F \
			or int(selector03_event.get("yield_callsite_pc", -1)) != 0x8266 \
			or int(selector03_event.get("resume_pc_after_rts", -1)) != 0x8269 \
			or int(event_registers.get("sp", -1)) != 0xC5 \
			or int(event_registers.get("a", -1)) != 0x01 \
			or int(event_registers.get("x", -1)) != 0x04 \
			or int(event_registers.get("y", -1)) != 0x03 \
			or event_ram.size() != 0x800 \
			or int(event_ram[0x05F3]) != 0x00 or int(event_ram[0x05F4]) != 0x80 \
			or int(event_ram[0x05E6]) != 0x0E or int(event_ram[0x05E7]) != 0x14 \
			or int(event_ram[0x05E8]) != 0x06 \
			or int(event_ram[0x0061]) != 0x94 or int(event_ram[0x0062]) != 0x8E \
			or int(event_stack[0xC6]) != 0x22 or int(event_stack[0xC7]) != 0x2C \
			or int(event_stack[0xC8]) != 0x04 \
			or decoded_event.get("payload", PackedByteArray()) != PackedByteArray([0x2C, 0x22, 0x14]):
		return _fail("The selector-$03 type-2 payload or `$8266->$CB0F` stack/register state differs from FCEUX frame 8626: "
				+ str({"status": selector03_event.get("status", ""), "callsite": event_registers,
				"decoded_event": decoded_event, "ram": [event_ram[0x05F3], event_ram[0x05F4],
					event_ram[0x05E6], event_ram[0x05E7], event_ram[0x05E8]],
				"stack": event_stack.slice(0xC2, 0xCA).hex_encode()}))
	var event_wait_ram := event_ram.duplicate()
	var event_wait_stack := event_stack.duplicate()
	var event_wait_boundary := {
		"slot_base": 0x11, "active_task_slot": 0x11, "pc": 0x8269, "sp": 0xC5,
		"phase": 2, "pending_resume": 0, "ready_delay": 0,
		"record": PackedByteArray([0x00, 0xC1, 0x18, 0x19]),
		"a": 0x04, "x": 0x04, "y": 0x03, "p": 0x30, "p_known_mask": 0xC3,
		"bank_low": 0x18, "bank_high": 0x19,
		"mapper": {"bank_low": 0x18, "bank_high": 0x19},
		"ram_image": event_wait_ram, "stack_page": event_wait_stack,
	}
	var event_wait: Dictionary = executor.execute_from_slot11_actor_event_wait_boundary(event_wait_boundary)
	if not bool(event_wait.get("ok", false)):
		return _fail("The ROM event-queue source did not execute from `$8269`: " + String(event_wait.get("error", "unknown error")))
	var wait_callsite: Dictionary = event_wait.get("yield_callsite_registers", {})
	var wait_ram: PackedByteArray = event_wait.get("ram_image", PackedByteArray())
	if String(event_wait.get("status", "")) != "slot11_actor_event_queue_at_cb0f" \
			or int(event_wait.get("entry_pc", -1)) != 0x8269 \
			or int(event_wait.get("yield_callsite_pc", -1)) != 0x8266 \
			or int(event_wait.get("exit_pc", -1)) != 0xCB0F \
			or int(wait_callsite.get("sp", -1)) != 0xC5 \
			or int(wait_callsite.get("a", -1)) != 0x01 \
			or int(wait_callsite.get("x", -1)) != 0x2E \
			or int(wait_callsite.get("y", -1)) != 0x18 \
			or int(wait_ram[0x0515]) != 0x80 or int(wait_ram[0x05E8]) != 0x05 \
			or wait_ram.slice(0x04A5, 0x04A9) != PackedByteArray([0x14, 0x2C, 0x22, 0x00]):
		return _fail("ROM event-queue packet does not match the frame-8627 `$8269->$8266` state: " + str({
			"status": event_wait.get("status", ""), "callsite": wait_callsite,
			"queue": [wait_ram[0x0515], wait_ram[0x05E8], wait_ram[0x04A5], wait_ram[0x04A6], wait_ram[0x04A7], wait_ram[0x04A8]],
		}))
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
	var index1_boundary := a21a_boundary.duplicate(true)
	var index1_ram: PackedByteArray = index1_boundary["ram_image"].duplicate()
	index1_ram[0x05F3] = 0x01
	index1_ram[0x05F4] = 0x01
	index1_ram[0x05F5] = 0x00
	index1_ram[0x0515] = 0x00
	index1_ram[0x0063] = 0xCB
	index1_ram[0x0064] = 0xA2
	index1_ram[0x05E3] = 0x01
	index1_boundary["ram_image"] = index1_ram
	for offset in 0x100:
		index1_boundary["stack_page"][offset] = index1_ram[0x0100 + offset]
	var index1_result: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(index1_boundary)
	if not bool(index1_result.get("ok", false)) \
			or int(index1_result.get("animation_stream_pointer", -1)) != 0xA2CB \
			or int(index1_result.get("animation_packet_index", -1)) != 0x04 \
			or int(index1_result.get("packet_stream_pointer", -1)) != 0xA49E \
			or int(index1_result.get("secondary_ppu_packets", []).size()) != 6 \
			or int(index1_result.get("yield_callsite_registers", {}).get("x", -1)) != 0x24 \
			or index1_result.get("ram_image", PackedByteArray()).slice(0x04A5, 0x04CA) != PackedByteArray([
				0x04, 0xC8, 0x22, 0x00, 0xEB, 0xEE, 0xEF,
				0x04, 0xE8, 0x22, 0x00, 0xB6, 0xB7, 0xE2,
				0x04, 0x08, 0x23, 0x00, 0xBC, 0xBD, 0xE8,
				0x04, 0x28, 0x23, 0x00, 0xBE, 0xBF, 0xEA,
				0x01, 0xEA, 0x23, 0x50, 0x01, 0xF2, 0x23, 0x05, 0x00,
			]):
		return _fail("The ROM index-$01 `$A2CB->$A49E` animation did not build its six exact PPU packets: %s" % str(index1_result))
	var index1_terminal_boundary := index1_boundary.duplicate(true)
	var index1_terminal_ram: PackedByteArray = index1_terminal_boundary["ram_image"].duplicate()
	index1_terminal_ram[0x0063] = 0xE5
	index1_terminal_boundary["ram_image"] = index1_terminal_ram
	var index1_terminal_result: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(index1_terminal_boundary)
	var index1_terminal_read_found := false
	for read_variant in index1_terminal_result.get("source_reads", []):
		if read_variant is Dictionary \
				and int(read_variant.get("address", -1)) == 0xA2E5 \
				and int(read_variant.get("value", -1)) == 0xFF \
				and String(read_variant.get("kind", "")) == "animation_command":
			index1_terminal_read_found = true
	if not bool(index1_terminal_result.get("ok", false)) \
			or int(index1_terminal_result.get("animation_stream_pointer", -1)) != 0xA2CB \
			or int(index1_terminal_result.get("packet_stream_pointer", -1)) != 0xA49E \
			or int(index1_terminal_result.get("ram_image", PackedByteArray())[0x05F4]) != 0x01 \
			or not index1_terminal_read_found:
		return _fail("The index-$01 `$A2E5->$A2CB` active-worker loop did not resume from its ROM terminal pointer: %s" % str(index1_terminal_result))
	print("PASS: ROM animation index `$01` decodes packet row `$04` at `$A49E`; `$A2E5->$A2CB` follows the active-worker loop.")
	var index2_cases := [
		{"pointer": 0xA2E8, "index": 0x05, "table_address": 0xA434,
			"table_low": 0xC3, "packet": 0xA4C3, "next_pointer": 0xA2EA},
		{"pointer": 0xA2EA, "index": 0x06, "table_address": 0xA436,
			"table_low": 0xE8, "packet": 0xA4E8, "next_pointer": 0xA2EC},
		{"pointer": 0xA2EC, "index": 0x07, "table_address": 0xA438,
			"table_low": 0xED, "packet": 0xA4ED, "next_pointer": 0xA2EE},
	]
	for case_variant: Variant in index2_cases:
		var case: Dictionary = case_variant
		var index2_case_boundary := _supported_index2_animation_boundary(
			a21a_boundary, int(case["pointer"]))
		var index2_case: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(
			index2_case_boundary)
		var index2_ram: PackedByteArray = index2_case.get("ram_image", PackedByteArray())
		var index2_packets: Array = index2_case.get("secondary_ppu_packets", [])
		if not bool(index2_case.get("ok", false)) \
				or int(index2_case.get("animation_stream_pointer", -1)) != int(case["pointer"]) \
				or int(index2_case.get("animation_command", -1)) != 0x04 \
				or int(index2_case.get("animation_packet_index", -1)) != int(case["index"]) \
				or int(index2_case.get("packet_stream_pointer", -1)) != int(case["packet"]) \
				or not _has_source_read(index2_case, int(case["table_address"]),
					int(case["table_low"]), "animation_event_pointer_low") \
				or not _has_source_read(index2_case, int(case["table_address"]) + 1,
					0xA4, "animation_event_pointer_high") \
				or index2_ram.size() != 0x800 \
				or int(index2_ram[0x0063]) != (int(case["next_pointer"]) & 0xFF) \
				or int(index2_ram[0x0064]) != ((int(case["next_pointer"]) >> 8) & 0xFF):
			return _fail("Animation-index-$02 command 04 event %02X did not resolve its exact ROM table/packet row: %s" % [
				int(case["index"]), str(index2_case)])
		if int(case["index"]) == 0x05 and index2_packets != [
			{"length": 4, "destination": 0x22C8, "payload": PackedByteArray([0x00, 0xB4, 0xE4, 0xE5])},
			{"length": 4, "destination": 0x22E8, "payload": PackedByteArray([0x00, 0xB6, 0xE6, 0xE7])},
			{"length": 4, "destination": 0x2308, "payload": PackedByteArray([0x00, 0xBC, 0xBD, 0xE8])},
			{"length": 4, "destination": 0x2328, "payload": PackedByteArray([0x00, 0xBE, 0xBF, 0xEA])},
			{"length": 1, "destination": 0x23EA, "payload": PackedByteArray([0x50])},
			{"length": 1, "destination": 0x23F2, "payload": PackedByteArray([0x05])},
		]:
			return _fail("Animation-index-$02 packet row 05 `$A4C3` differs from its six ROM packets: %s" % str(index2_packets))
		if int(case["index"]) == 0x06 and index2_packets != [
			{"length": 1, "destination": 0x22EA, "payload": PackedByteArray([0xD9])},
		]:
			return _fail("Animation-index-$02 packet row 06 `$A4E8` differs from its ROM packet: %s" % str(index2_packets))
		if int(case["index"]) == 0x07 and index2_packets != [
			{"length": 1, "destination": 0x22EA, "payload": PackedByteArray([0xF2])},
		]:
			return _fail("Animation-index-$02 packet row 07 `$A4ED` differs from its ROM packet: %s" % str(index2_packets))
	var index2_terminal_boundary := _supported_index2_animation_boundary(a21a_boundary, 0xA2FA)
	var index2_terminal: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(
		index2_terminal_boundary)
	var index2_terminal_ram: PackedByteArray = index2_terminal.get("ram_image", PackedByteArray())
	var index2_redirect_writes: Array = index2_terminal.get("ram_writes", []).filter(
		func(write: Dictionary) -> bool:
			return int(write.get("pc", -1)) in [0xA233, 0xA235]
	)
	if not bool(index2_terminal.get("ok", false)) \
			or int(index2_terminal.get("animation_stream_pointer", -1)) != 0xA2E8 \
			or int(index2_terminal.get("animation_packet_index", -1)) != 0x05 \
			or int(index2_terminal.get("packet_stream_pointer", -1)) != 0xA4C3 \
			or index2_terminal_ram.size() != 0x800 \
			or index2_terminal_ram.slice(0x0063, 0x0065) != PackedByteArray([0xEA, 0xA2]) \
			or index2_redirect_writes != [
				{"pc": 0xA233, "address": 0x0064, "value": 0xA2, "kind": "STA"},
				{"pc": 0xA235, "address": 0x0063, "value": 0xE8, "kind": "STA"},
			] \
			or not _has_source_read(index2_terminal, 0xA2FA, 0xFF, "animation_command") \
			or not _has_source_read(index2_terminal, 0xA2FB, 0xE8, "terminal_animation_pointer_low") \
			or not _has_source_read(index2_terminal, 0xA2FC, 0xA2, "terminal_animation_pointer_high") \
			or not _has_source_read(index2_terminal, 0xA2E8, 0x04, "animation_command") \
			or not _has_source_read(index2_terminal, 0xA2E9, 0x05, "animation_event_index"):
		return _fail("The active index-$02 `$A2FA->$A2E8->$A2EA` redirect did not follow its ROM pointer bytes: %s" % str(index2_terminal))
	var queue_wait_boundary := _supported_a21a_animation_boundary(animation_gate_result)
	var queue_wait_ram: PackedByteArray = queue_wait_boundary["ram_image"].duplicate()
	queue_wait_ram[0x0515] = 0x80
	queue_wait_boundary["ram_image"] = queue_wait_ram
	var queue_wait_result: Dictionary = executor.execute_from_slot11_animation_after_a217_boundary(queue_wait_boundary)
	if not bool(queue_wait_result.get("ok", false)) \
			or String(queue_wait_result.get("status", "")) != "slot11_f5_animation_busy_gate_at_cb0f_from_a217" \
			or int(queue_wait_result.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(queue_wait_result.get("resume_pc_after_rts", -1)) != 0xA21A \
			or int(queue_wait_result.get("ram_image", PackedByteArray())[0x0515]) != 0x80 \
			or int(queue_wait_result.get("ram_image", PackedByteArray())[0x01C5]) != 0x19 \
			or int(queue_wait_result.get("ram_image", PackedByteArray())[0x01C6]) != 0xA2 \
			or not (queue_wait_result.get("ram_writes", []) as Array).is_empty() \
			or int(queue_wait_result.get("source_reads", []).size()) < 5:
		return _fail("The `$A21A->$A217` queue-busy yield did not preserve its ROM return frame while awaiting NMI: %s" % str(queue_wait_result))
	var packet_wait: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_packet_wait_boundary())
	var packet_wait_callsite: Dictionary = packet_wait.get("yield_callsite_registers", {})
	var packet_wait_stack: PackedByteArray = packet_wait.get("stack_page", PackedByteArray())
	if not bool(packet_wait.get("ok", false)) \
			or String(packet_wait.get("status", "")) != "slot11_actor_packet_wait_at_cb0f" \
			or int(packet_wait.get("entry_pc", -1)) != 0x804A \
			or int(packet_wait.get("yield_callsite_pc", -1)) != 0x82F4 \
			or int(packet_wait.get("resume_pc_after_rts", -1)) != 0x82F7 \
			or int(packet_wait_callsite.get("a", -1)) != 0x01 \
			or int(packet_wait_callsite.get("x", -1)) != 0x24 \
			or int(packet_wait_callsite.get("y", -1)) != 0x06 \
			or int(packet_wait_callsite.get("sp", -1)) != 0xC8 \
			or int(packet_wait_stack[0xC7]) != 0xF6 or int(packet_wait_stack[0xC8]) != 0x82:
		return _fail("The live `$82F2->$82F4->$C515` row-2 wait did not save its traced `$82F7` continuation: %s" % str(packet_wait))
	var packet_resume: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(
		_supported_selector03_packet_resume_boundary())
	if not bool(packet_resume.get("ok", false)):
		return _fail("The ROM `$82F7` packet resume did not reach its next task yield: %s" % str(packet_resume))
	var packet_resume_ram: PackedByteArray = packet_resume.get("ram_image", PackedByteArray())
	var packet_resume_callsite: Dictionary = packet_resume.get("yield_callsite_registers", {})
	if String(packet_resume.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
			or int(packet_resume.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(packet_resume.get("resume_pc_after_rts", -1)) != 0x804A \
			or int(packet_resume_callsite.get("a", -1)) != 0x01 \
			or int(packet_resume_callsite.get("x", -1)) != 0x05 \
			or int(packet_resume_callsite.get("y", -1)) != 0x05 \
			or int(packet_resume_ram[0x0515]) != 0x80 \
			or int(packet_resume_ram[0x05F5]) != 0x04 \
			or packet_resume_ram.slice(0x04B9, 0x04BF) != PackedByteArray([0x53, 0x41, 0x4F, 0x20, 0x50, 0x20]):
		return _fail("The ROM packet resume did not build the checked `SAO P ` packet and yield at `$8047`: %s" % str(packet_resume))
	print("PASS: ROM `$82F7` queue polling, `$A3C9` event dispatch, `$F776` text lookup and `$8047` yield build the `SAO P ` PPU packet.")
	var post_packet_tick: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_post_packet_countdown_boundary())
	var post_packet_ram: PackedByteArray = post_packet_tick.get("ram_image", PackedByteArray())
	if not bool(post_packet_tick.get("ok", false)) \
			or String(post_packet_tick.get("status", "")) != "slot11_actor_sequence_selector03_delay_at_8047" \
			or int(post_packet_tick.get("entry_pc", -1)) != 0x804A \
			or int(post_packet_tick.get("exit_pc", -1)) != 0x8047 \
			or int(post_packet_ram[0x05E4]) != 0x02 or int(post_packet_ram[0x05E5]) != 0x06 \
			or int(post_packet_ram[0x05E9]) != 0x00 \
			or int(post_packet_ram[0x05F5]) != 0x03:
		return _fail("The source countdown after the `$82F7` packet differs from the frame-8636 FCEUX state: %s" % str(post_packet_tick))
	print("PASS: frame-8636 FCEUX actor state resumes at `$804A`, decrements `$05E9`, and advances the ROM animation gate through `$8047`.")
	var followup_wait: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_followup_packet_wait_boundary())
	if not bool(followup_wait.get("ok", false)) \
			or String(followup_wait.get("status", "")) != "slot11_actor_packet_wait_at_cb0f" \
			or int(followup_wait.get("yield_callsite_pc", -1)) != 0x82F4 \
			or int(followup_wait.get("resume_pc_after_rts", -1)) != 0x82F7 \
			or int(followup_wait.get("yield_callsite_registers", {}).get("x", -1)) != 0x05 \
			or int(followup_wait.get("yield_callsite_registers", {}).get("y", -1)) != 0x06:
		return _fail("The frame-8637 follow-up actor packet did not enter its traced `$82F2->$82F7` wait: %s" % str(followup_wait))
	var followup_resume_boundary: Dictionary = _supported_selector03_followup_packet_resume_boundary(
		followup_wait)
	var followup_resume: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(
		followup_resume_boundary)
	if not bool(followup_resume.get("ok", false)):
		return _fail("The ROM `$82F7` follow-up packet failed: %s" % str(followup_resume))
	var followup_ram: PackedByteArray = followup_resume.get("ram_image", PackedByteArray())
	if String(followup_resume.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
			or int(followup_resume.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(followup_ram[0x05E4]) != 0x02 or int(followup_ram[0x05E5]) != 0x10 \
			or int(followup_ram[0x05E9]) != 0x01 \
			or int(followup_ram[0x0515]) != 0x80:
		return _fail("The ROM `$82F7` follow-up packet output differs from the FCEUX next-source state: %s" % str(followup_resume))
	var row02_wait: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_row02_packet_wait_boundary())
	if not bool(row02_wait.get("ok", false)) \
			or String(row02_wait.get("status", "")) != "slot11_actor_packet_wait_at_cb0f" \
			or int(row02_wait.get("yield_callsite_pc", -1)) != 0x82F4 \
			or int(row02_wait.get("yield_callsite_registers", {}).get("x", -1)) != 0x07 \
			or int(row02_wait.get("yield_callsite_registers", {}).get("y", -1)) != 0x06:
		return _fail("The frame-8640 row-2 packet wait differs from the FCEUX callsite: %s" % str(row02_wait))
	var row02_resume: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(
		_supported_selector03_row02_packet_resume_boundary(row02_wait))
	if not bool(row02_resume.get("ok", false)):
		return _fail("The frame-8641 row-2 packet resume did not follow the ROM stream: %s" % str(row02_resume))
	var row02_ram: PackedByteArray = row02_resume.get("ram_image", PackedByteArray())
	var row02_callsite: Dictionary = row02_resume.get("yield_callsite_registers", {})
	if String(row02_resume.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
			or int(row02_resume.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(row02_callsite.get("x", -1)) != 0x07 \
			or int(row02_callsite.get("y", -1)) != 0x3A \
			or int(row02_ram[0x05E5]) != 0x19 or int(row02_ram[0x0515]) != 0x80 \
			or row02_ram.slice(0x04A5, 0x04B9) != PackedByteArray([
				0x0E, 0xF0, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0E, 0x10, 0x23,
			]) \
			or row02_ram.slice(0x04B9, 0x04C1) != PackedByteArray([
				0x08, 0x63, 0x20, 0x02, 0x73, 0x07, 0x51, 0x72,
			]):
		return _fail("The frame-8641 ROM stream did not build the checked row-2 packet: %s" % str(row02_resume))
	print("PASS: frame-8637 and frame-8640 FCEUX waits resume through ROM `$82F7` to `$8047`; row 2 builds its `$F0/$23` packet.")
	var terminal_command: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_terminal_command_boundary())
	if not bool(terminal_command.get("ok", false)) \
			or String(terminal_command.get("status", "")) != "slot11_actor_sequence_selector03_delay_at_8047" \
			or int(terminal_command.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(terminal_command.get("yield_callsite_registers", {}).get("a", -1)) != 0x01 \
			or int(terminal_command.get("yield_callsite_registers", {}).get("x", -1)) != 0x04 \
			or int(terminal_command.get("yield_callsite_registers", {}).get("y", -1)) != 0x02:
		return _fail("The ROM `$A3E2=$F0->$8098` terminator did not reproduce the FCEUX `$8047` register boundary: %s" % str(terminal_command))
	var terminal_ram: PackedByteArray = terminal_command.get("ram_image", PackedByteArray())
	if terminal_ram.size() != 0x800 or int(terminal_ram[0x05E3]) != 0 \
			or int(terminal_ram[0x05E4]) != 0 or int(terminal_ram[0x05E5]) != 0x1A \
			or int(terminal_ram[0x05F5]) != 0x04:
		return _fail("The ROM `$8098` termination or `$A1EB` counter output differs from frame 8644: %s" % str(terminal_ram.slice(0x05E3, 0x05F6).hex_encode()))
	var inactive_tick: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		_supported_selector03_terminal_inactive_countdown_boundary())
	if not bool(inactive_tick.get("ok", false)) \
			or int(inactive_tick.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(inactive_tick.get("yield_callsite_registers", {}).get("a", -1)) != 0x01 \
			or int(inactive_tick.get("yield_callsite_registers", {}).get("x", -1)) != 0x04 \
			or int(inactive_tick.get("yield_callsite_registers", {}).get("y", -1)) != 0x02:
		return _fail("The inactive `$8053->$8059` selector-$03 countdown differs from the frame-8645 FCEUX yield: %s" % str(inactive_tick))
	var inactive_ram: PackedByteArray = inactive_tick.get("ram_image", PackedByteArray())
	if inactive_ram.size() != 0x800 or int(inactive_ram[0x05E3]) != 0 \
			or int(inactive_ram[0x05E5]) != 0x1A or int(inactive_ram[0x05F5]) != 0x03:
		return _fail("The inactive selector-$03 countdown changed stream state or missed the `$05F5` decrement.")
	var inactive_gate_boundary := _supported_selector03_terminal_inactive_countdown_boundary()
	var inactive_gate_ram: PackedByteArray = inactive_gate_boundary["ram_image"].duplicate()
	inactive_gate_ram[0x05F5] = 0x00
	inactive_gate_boundary["ram_image"] = inactive_gate_ram
	var inactive_gate: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		inactive_gate_boundary)
	var inactive_gate_callsite: Dictionary = inactive_gate.get("yield_callsite_registers", {})
	var inactive_gate_stack: PackedByteArray = inactive_gate.get("stack_page", PackedByteArray())
	if not bool(inactive_gate.get("ok", false)) \
			or String(inactive_gate.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(inactive_gate.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(inactive_gate.get("exit_pc", -1)) != 0xCB0F \
			or int(inactive_gate_callsite.get("a", -1)) != 0x01 \
			or int(inactive_gate_callsite.get("x", -1)) != 0x04 \
			or int(inactive_gate_callsite.get("y", -1)) != 0x02 \
			or inactive_gate_stack.slice(0xC5, 0xCB) != PackedByteArray([0x19, 0xA2, 0x83, 0xCF, 0x4F, 0x80]):
		return _fail("The frame-8649 inactive selector-$03 path did not resolve F5=$00 through `$A217->$CB0F` with the source stack: %s" % str(inactive_gate))
	var inactive_packet_gate_boundary := _supported_selector03_terminal_inactive_countdown_boundary()
	var inactive_packet_gate_ram: PackedByteArray = inactive_packet_gate_boundary["ram_image"].duplicate()
	var inactive_packet_gate_stack: PackedByteArray = inactive_packet_gate_boundary["stack_page"].duplicate()
	inactive_packet_gate_ram[0x0063] = 0xB4
	inactive_packet_gate_ram[0x0064] = 0xA2
	inactive_packet_gate_ram[0x05F5] = 0x00
	inactive_packet_gate_stack[0xC7] = 0x04
	inactive_packet_gate_stack[0xC8] = 0x04
	for offset in 0x100:
		inactive_packet_gate_ram[0x0100 + offset] = inactive_packet_gate_stack[offset]
	inactive_packet_gate_boundary["ram_image"] = inactive_packet_gate_ram
	inactive_packet_gate_boundary["stack_page"] = inactive_packet_gate_stack
	inactive_packet_gate_boundary["a"] = 0x04
	inactive_packet_gate_boundary["x"] = 0x04
	inactive_packet_gate_boundary["y"] = 0x04
	var inactive_packet_gate := executor.execute_from_slot11_animation_countdown_boundary(
		inactive_packet_gate_boundary)
	var inactive_packet_gate_callsite: Dictionary = inactive_packet_gate.get("yield_callsite_registers", {})
	if not bool(inactive_packet_gate.get("ok", false)) \
			or String(inactive_packet_gate.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(inactive_packet_gate.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(inactive_packet_gate_callsite.get("x", -1)) != 0x04 \
			or int(inactive_packet_gate_callsite.get("y", -1)) != 0x04 \
			or int(inactive_packet_gate.get("ram_image", PackedByteArray())[0x0063]) != 0xB4 \
			or int(inactive_packet_gate.get("ram_image", PackedByteArray())[0x0064]) != 0xA2:
		return _fail("The terminal `$A2B4` packet gate did not preserve its ROM-selected yield registers and animation pointer: %s" % str(inactive_packet_gate))
	var a439_inactive_gate_boundary := _supported_selector03_terminal_inactive_countdown_boundary()
	var a439_inactive_gate_ram: PackedByteArray = a439_inactive_gate_boundary["ram_image"].duplicate()
	var a439_inactive_gate_stack: PackedByteArray = a439_inactive_gate_boundary["stack_page"].duplicate()
	a439_inactive_gate_ram[0x005F] = 0x39
	a439_inactive_gate_ram[0x0060] = 0xA4
	a439_inactive_gate_ram[0x0063] = 0xB2
	a439_inactive_gate_ram[0x0064] = 0xA2
	a439_inactive_gate_ram[0x05E5] = 0x0E
	a439_inactive_gate_ram[0x05F5] = 0x00
	a439_inactive_gate_ram[0x0515] = 0x80
	a439_inactive_gate_stack[0xC7] = 0x04
	a439_inactive_gate_stack[0xC8] = 0x04
	for offset in 0x100:
		a439_inactive_gate_ram[0x0100 + offset] = a439_inactive_gate_stack[offset]
	a439_inactive_gate_boundary["ram_image"] = a439_inactive_gate_ram
	a439_inactive_gate_boundary["stack_page"] = a439_inactive_gate_stack
	a439_inactive_gate_boundary["a"] = 0x04
	a439_inactive_gate_boundary["x"] = 0x04
	a439_inactive_gate_boundary["y"] = 0x04
	var a439_inactive_gate := executor.execute_from_slot11_animation_countdown_boundary(
		a439_inactive_gate_boundary)
	var a439_inactive_gate_callsite: Dictionary = a439_inactive_gate.get("yield_callsite_registers", {})
	var a439_inactive_gate_stack_out: PackedByteArray = a439_inactive_gate.get("stack_page", PackedByteArray())
	var a439_inactive_gate_ram_out: PackedByteArray = a439_inactive_gate.get("ram_image", PackedByteArray())
	if not bool(a439_inactive_gate.get("ok", false)) \
			or String(a439_inactive_gate.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(a439_inactive_gate.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(a439_inactive_gate.get("exit_pc", -1)) != 0xCB0F \
			or int(a439_inactive_gate_callsite.get("a", -1)) != 0x01 \
			or int(a439_inactive_gate_callsite.get("x", -1)) != 0x04 \
			or int(a439_inactive_gate_callsite.get("y", -1)) != 0x04 \
			or a439_inactive_gate_stack_out.slice(0xC5, 0xCB) != PackedByteArray([0x19, 0xA2, 0x83, 0xCF, 0x4F, 0x80]) \
			or a439_inactive_gate_ram_out[0x0515] != 0x80:
		return _fail("The frame-8783 A439 inactive worker did not preserve its queued flag and reach the `$A217->$CB0F` yield: %s" % str(a439_inactive_gate))
	var a439_b4_gate_boundary := a439_inactive_gate_boundary.duplicate(true)
	var a439_b4_gate_ram: PackedByteArray = a439_b4_gate_boundary["ram_image"].duplicate()
	var a439_b4_gate_stack: PackedByteArray = a439_b4_gate_boundary["stack_page"].duplicate()
	a439_b4_gate_ram[0x0063] = 0xB4
	a439_b4_gate_ram[0x0515] = 0x00
	for offset in 0x100:
		a439_b4_gate_ram[0x0100 + offset] = a439_b4_gate_stack[offset]
	a439_b4_gate_boundary["ram_image"] = a439_b4_gate_ram
	a439_b4_gate_boundary["stack_page"] = a439_b4_gate_stack
	var a439_b4_gate := executor.execute_from_slot11_animation_countdown_boundary(
		a439_b4_gate_boundary)
	var a439_b4_gate_callsite: Dictionary = a439_b4_gate.get("yield_callsite_registers", {})
	var a439_b4_gate_ram_out: PackedByteArray = a439_b4_gate.get("ram_image", PackedByteArray())
	if not bool(a439_b4_gate.get("ok", false)) \
			or String(a439_b4_gate.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
			or int(a439_b4_gate.get("yield_callsite_pc", -1)) != 0xA217 \
			or int(a439_b4_gate.get("exit_pc", -1)) != 0xCB0F \
			or int(a439_b4_gate_callsite.get("a", -1)) != 0x01 \
			or int(a439_b4_gate_callsite.get("x", -1)) != 0x04 \
			or int(a439_b4_gate_callsite.get("y", -1)) != 0x04 \
			or a439_b4_gate_ram_out[0x0063] != 0xB4 \
			or a439_b4_gate_ram_out[0x0064] != 0xA2 \
			or a439_b4_gate_ram_out[0x0515] != 0x00:
		return _fail("The FCEUX frame-8796 `$A2B4` A439 inactive state did not preserve its cleared queue and reach `$A217->$CB0F`: %s" % str(a439_b4_gate))
	var a439_countdown_boundary := _supported_selector03_terminal_inactive_countdown_boundary()
	var a439_countdown_ram: PackedByteArray = a439_countdown_boundary["ram_image"].duplicate()
	var a439_countdown_stack: PackedByteArray = a439_countdown_boundary["stack_page"].duplicate()
	a439_countdown_stack[0xC7] = 0x04
	a439_countdown_stack[0xC8] = 0x04
	for offset in 0x100:
		a439_countdown_ram[0x0100 + offset] = a439_countdown_stack[offset]
	a439_countdown_ram[0x005F] = 0x39
	a439_countdown_ram[0x0060] = 0xA4
	a439_countdown_ram[0x0063] = 0xB4
	a439_countdown_ram[0x0064] = 0xA2
	a439_countdown_ram[0x05E5] = 0x0E
	a439_countdown_ram[0x05E6] = 0x0E
	a439_countdown_ram[0x05F5] = 0x05
	a439_countdown_ram[0x0515] = 0x80
	a439_countdown_boundary["ram_image"] = a439_countdown_ram
	a439_countdown_boundary["stack_page"] = a439_countdown_stack
	a439_countdown_boundary["a"] = 0x04
	a439_countdown_boundary["x"] = 0x04
	a439_countdown_boundary["y"] = 0x04
	var a439_countdown := executor.execute_from_slot11_animation_countdown_boundary(
		a439_countdown_boundary)
	var a439_countdown_ram_out: PackedByteArray = a439_countdown.get("ram_image", PackedByteArray())
	var a439_countdown_callsite: Dictionary = a439_countdown.get("yield_callsite_registers", {})
	if not bool(a439_countdown.get("ok", false)) \
			or int(a439_countdown.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(a439_countdown_callsite.get("a", -1)) != 0x01 \
			or int(a439_countdown_callsite.get("x", -1)) != 0x04 \
			or int(a439_countdown_callsite.get("y", -1)) != 0x04 \
			or a439_countdown_ram_out[0x0063] != 0xB4 \
			or a439_countdown_ram_out[0x0064] != 0xA2 \
			or a439_countdown_ram_out[0x05F5] != 0x04 \
			or a439_countdown_ram_out[0x0515] != 0x80:
		return _fail("The frame-8785 A439 inactive countdown did not decrement F5 while preserving animation pointer and pending NMI queue: %s" % str(a439_countdown))
	print("PASS: frame-8785 A439 inactive countdown decrements `$05F5`, preserves `$A2B4` and the pending queue, then yields at `$8047`.")
	var inactive_a2b8_boundary := _supported_selector03_terminal_inactive_countdown_boundary()
	var inactive_a2b8_ram: PackedByteArray = inactive_a2b8_boundary["ram_image"].duplicate()
	var inactive_a2b8_stack: PackedByteArray = inactive_a2b8_boundary["stack_page"].duplicate()
	inactive_a2b8_ram[0x0063] = 0xB8
	inactive_a2b8_ram[0x05F5] = 0x05
	inactive_a2b8_stack[0xC7] = 0x04
	inactive_a2b8_stack[0xC8] = 0x04
	for offset in 0x100:
		inactive_a2b8_ram[0x0100 + offset] = inactive_a2b8_stack[offset]
	inactive_a2b8_boundary["ram_image"] = inactive_a2b8_ram
	inactive_a2b8_boundary["stack_page"] = inactive_a2b8_stack
	inactive_a2b8_boundary["a"] = 0x04
	inactive_a2b8_boundary["x"] = 0x04
	inactive_a2b8_boundary["y"] = 0x04
	var inactive_a2b8_tick: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(
		inactive_a2b8_boundary)
	var inactive_a2b8_result_ram: PackedByteArray = inactive_a2b8_tick.get("ram_image", PackedByteArray())
	if not bool(inactive_a2b8_tick.get("ok", false)) \
			or int(inactive_a2b8_result_ram[0x0063]) != 0xB8 \
			or int(inactive_a2b8_result_ram[0x05F5]) != 0x04:
		return _fail("The trace-observed `$A2B8` selector-$03 animation tick did not preserve its pointer and decrement the source wait: %s" % str(inactive_a2b8_tick))
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


func _scenario1c_parameter00_boundary() -> Dictionary:
	var boundary := _supported_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x01
	stack[0xC8] = 0x00
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x003A] = 0x06
	ram[0x005D] = 0x4F
	ram[0x005E] = 0xBB
	ram[0x005F] = 0x00
	ram[0x0060] = 0x94
	ram[0x0063] = 0xD7
	ram[0x0064] = 0xA2
	ram[0x0022] = 0x00
	ram[0x0515] = 0x00
	ram[0x0516] = 0x01
	ram[0x0517] = 0x40
	ram[0x0518] = 0x1C
	ram[0x0519] = 0x2F
	ram[0x051B] = 0x9B
	ram[0x0522] = 0x02
	ram[0x0523] = 0x30
	ram[0x0524] = 0x1F
	ram[0x0525] = 0x02
	ram[0x0526] = 0x3C
	ram[0x0527] = 0x4A
	ram[0x0528] = 0x4C
	ram[0x0529] = 0x00
	ram[0x052A] = 0x40
	ram[0x0539] = 0x00
	ram[0x05C7] = 0x40
	ram[0x05C8] = 0xA0
	ram[0x05C9] = 0x00
	ram[0x05CA] = 0x00
	ram[0x05CB] = 0x01
	ram[0x05CC] = 0x52
	ram[0x05CD] = 0xA0
	ram[0x05CE] = 0x80
	ram[0x05CF] = 0x00
	ram[0x05D0] = 0x02
	ram[0x05D1] = 0x80
	ram[0x05D2] = 0x01
	ram[0x0629] = 0x00
	ram[0x05E3] = 0x01
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x00
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05EA] = 0x00
	ram[0x05F4] = 0x00
	ram[0x05F5] = 0x01
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["pc"] = 0x804A
	boundary["sp"] = 0xCA
	boundary["a"] = 0x00
	boundary["x"] = 0x00
	boundary["y"] = 0x01
	boundary["p"] = 0x22
	boundary["p_known_mask"] = 0x83
	return boundary


func _scenario2e_actor6d_f2_waiter_entry_boundary() -> Dictionary:
	var boundary := _supported_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	_write_bytes(stack, 0xC7, PackedByteArray([0xDB, 0xE3, 0x49, 0x80]))
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	_write_bytes(ram, 0x005D, PackedByteArray([0x53, 0xB7, 0xE3, 0x9B]))
	_write_bytes(ram, 0x0063, PackedByteArray([0xBA, 0xA2]))
	_write_bytes(ram, 0x0516, PackedByteArray([0x01, 0x00, 0x2E, 0x77, 0xE8, 0x9B, 0x00]))
	_write_bytes(ram, 0x0523, PackedByteArray([0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]))
	ram[0x003A] = 0x06
	_write_bytes(ram, 0x05C7, PackedByteArray([
		0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]))
	_write_bytes(ram, 0x05E3, PackedByteArray([0x01, 0x00, 0x00, 0x0E, 0x02, 0x02, 0x00, 0x6D]))
	_write_bytes(ram, 0x05F3, PackedByteArray([0x00, 0x00, 0x01]))
	boundary["a"] = 0xE3
	boundary["x"] = 0xE3
	boundary["y"] = 0xDB
	boundary["p"] = 0xB0
	boundary["p_known_mask"] = 0xFF
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _scenario2e_actor6d_f2_waiter_resume_boundary(wait_count: int) -> Dictionary:
	var boundary := _scenario2e_actor6d_f2_waiter_entry_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	ram[0x0519] = 0x70 + wait_count
	ram[0x05E5] = 0x01
	_write_bytes(stack, 0xC4, PackedByteArray([0x52, 0xCC, wait_count, 0x7C, 0x80, 0x4C, 0x80]))
	stack[0xC2] = 0x06 if wait_count == 0x06 else 0x00
	stack[0xC3] = 0xE3 if wait_count == 0x06 else 0x4F
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	boundary["phase"] = 2
	boundary["pending_resume"] = 0
	boundary["pc"] = 0xCC53
	boundary["sp"] = 0xC5
	boundary["active_task_slot"] = 0x11
	boundary["record"] = PackedByteArray([0x00, 0xC1, 0x18, 0x19])
	boundary["a"] = 0xE3 if wait_count == 0x06 else 0x4F
	boundary["x"] = 0xE3 if wait_count == 0x06 else 0x4F
	boundary["y"] = 0x06 if wait_count == 0x06 else 0x00
	boundary["p"] = 0xB0 if wait_count == 0x06 else 0x30
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _scenario2e_actor6d_type5_event_boundary() -> Dictionary:
	var boundary := _supported_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x00
	stack[0xC8] = 0xFE
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	_write_bytes(ram, 0x0100, stack)
	_write_bytes(ram, 0x005F, PackedByteArray([0xFE, 0x9B]))
	_write_bytes(ram, 0x0516, PackedByteArray([0x01, 0x00, 0x2E, 0x6C, 0xE8, 0x9B, 0x00]))
	_write_bytes(ram, 0x05E3, PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]))
	_write_bytes(ram, 0x05F3, PackedByteArray([0x00, 0x00, 0x01]))
	_write_bytes(ram, 0x0063, PackedByteArray([0xBA, 0xA2]))
	_write_bytes(ram, 0x04A5, PackedByteArray([0x20, 0xE0, 0x23]))
	ram[0x0515] = 0x00
	boundary["a"] = 0xFE
	boundary["x"] = 0xFE
	boundary["y"] = 0x00
	boundary["p"] = 0xB0
	boundary["p_known_mask"] = 0xFF
	boundary["trace_state_used"] = false
	boundary["test_fixture"] = false
	boundary["mapper"] = {
		"select": 0x07, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {0: 0x3C, 1: 0x4A, 2: 0x20, 3: 0x21, 4: 0x00, 5: 0x00, 6: 0x18, 7: 0x19},
	}
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _write_bytes(target: PackedByteArray, start: int, values: PackedByteArray) -> void:
	for offset in values.size():
		target[start + offset] = values[offset]


func _scenario1c_f0_zero_mode_boundary() -> Dictionary:
	var boundary := _scenario1c_parameter00_boundary()
	var ram: PackedByteArray = boundary["ram_image"]
	var stack: PackedByteArray = boundary["stack_page"]
	# Exact `$804D` state from the recorded route at frame 9193, after the
	# scenario-$1C `$F0` return and before the `$05F4 == 0` wrapper call.
	ram[0x005F] = 0x00
	ram[0x0060] = 0x94
	ram[0x0515] = 0x00
	ram[0x0516] = 0x61
	ram[0x0517] = 0x40
	ram[0x0518] = 0x1C
	ram[0x0519] = 0x26
	ram[0x05E3] = 0x00
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x02
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05EA] = 0x00
	ram[0x05F3] = 0x01
	ram[0x05F4] = 0x00
	ram[0x05F5] = 0x01
	ram[0x0063] = 0xD7
	ram[0x0064] = 0xA2
	ram[0x0000] = 0x11
	stack[0xC7] = 0x7C
	stack[0xC8] = 0x80
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	boundary["pc"] = 0x804D
	boundary["sp"] = 0xCA
	boundary["record"] = PackedByteArray([0x00, 0xC2, 0x18, 0x19])
	boundary["a"] = 0x80
	boundary["x"] = 0x21
	boundary["y"] = 0x02
	boundary["mapper"] = {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
		"bank_registers": {6: 0x18, 7: 0x19}}
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _supported_selector03_boundary() -> Dictionary:
	var boundary := _supported_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0xE9
	stack[0xC8] = 0xBD
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0xBD
	ram[0x0060] = 0xA3
	ram[0x0629] = 0x00
	ram[0x0063] = 0x27
	ram[0x0064] = 0xA4
	ram[0x05F3] = 0x0D
	ram[0x05F4] = 0x00
	ram[0x05F5] = 0x6C
	var mapper: Dictionary = boundary["mapper"]
	mapper["select"] = 6
	mapper["bank_registers"] = {6: 0x18, 7: 0x19}
	boundary["mapper"] = mapper
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0xBD
	boundary["x"] = 0xBD
	boundary["y"] = 0xE9
	boundary["p"] = 0xB0
	return boundary


func _supported_selector03_delay_boundary() -> Dictionary:
	var boundary := _supported_selector03_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x00
	stack[0xC8] = 0xC9
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0xC9
	ram[0x0060] = 0xA3
	ram[0x05E4] = 0x01
	ram[0x05E5] = 0x01
	ram[0x05E9] = 0x01
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0xC9
	boundary["x"] = 0xC9
	boundary["y"] = 0x00
	boundary["p"] = 0x30
	return boundary


func _supported_selector03_event_boundary() -> Dictionary:
	var boundary := _supported_selector03_delay_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	ram[0x05E9] = 0x00
	boundary["ram_image"] = ram
	return boundary


func _supported_selector03_packet_wait_boundary() -> Dictionary:
	var boundary := _supported_selector03_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x24
	stack[0xC8] = 0x24
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0xC9
	ram[0x0060] = 0xA3
	ram[0x0063] = 0xB0
	ram[0x0064] = 0xA2
	ram[0x05E4] = 0x02
	ram[0x05E5] = 0x02
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x00
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05F3] = 0x00
	ram[0x05F4] = 0x01
	ram[0x05F5] = 0x05
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0x24
	boundary["x"] = 0x24
	boundary["y"] = 0x24
	boundary["p"] = 0x30
	return boundary


func _supported_selector03_packet_resume_boundary() -> Dictionary:
	var boundary := _supported_selector03_packet_wait_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0xF6
	stack[0xC8] = 0x82
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0xC9
	ram[0x0060] = 0xA3
	ram[0x0515] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["record"] = PackedByteArray([0x00, 0xC4, 0x18, 0x19])
	boundary["pc"] = 0x82F7
	boundary["sp"] = 0xC8
	boundary["a"] = 0x01
	boundary["x"] = 0x24
	boundary["y"] = 0x06
	return boundary


func _supported_selector03_post_packet_countdown_boundary() -> Dictionary:
	var boundary := _supported_selector03_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x05
	stack[0xC8] = 0x05
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0xC9
	ram[0x0060] = 0xA3
	ram[0x0063] = 0xB0
	ram[0x0064] = 0xA2
	ram[0x05E4] = 0x02
	ram[0x05E5] = 0x06
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x01
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x01
	ram[0x05F3] = 0x00
	ram[0x05F4] = 0x01
	ram[0x05F5] = 0x04
	ram[0x0515] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0x05
	boundary["x"] = 0x05
	boundary["y"] = 0x05
	boundary["p"] = 0x20
	return boundary


func _supported_selector03_followup_packet_wait_boundary() -> Dictionary:
	var boundary := _supported_selector03_post_packet_countdown_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	ram[0x05E9] = 0x00
	ram[0x05F5] = 0x03
	boundary["ram_image"] = ram
	boundary["p"] = 0x30
	return boundary


func _supported_selector03_followup_packet_resume_boundary(wait_result: Dictionary) -> Dictionary:
	var boundary := _supported_selector03_followup_packet_wait_boundary()
	var ram: PackedByteArray = wait_result.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = wait_result.get("stack_page", PackedByteArray()).duplicate()
	stack[0xC7] = 0xF6
	stack[0xC8] = 0x82
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0515] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["record"] = PackedByteArray([0x00, 0xC4, 0x18, 0x19])
	boundary["pc"] = 0x82F7
	boundary["sp"] = 0xC8
	boundary["a"] = 0x01
	boundary["x"] = 0x05
	boundary["y"] = 0x06
	return boundary


func _supported_selector03_row02_packet_wait_boundary() -> Dictionary:
	var boundary := _supported_selector03_followup_packet_wait_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x0F
	stack[0xC8] = 0x07
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x05E5] = 0x10
	ram[0x05E7] = 0x02
	ram[0x05F5] = 0x01
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0x07
	boundary["x"] = 0x07
	boundary["y"] = 0x0F
	return boundary


func _supported_selector03_row02_packet_resume_boundary(wait_result: Dictionary) -> Dictionary:
	var boundary := _supported_selector03_row02_packet_wait_boundary()
	var ram: PackedByteArray = wait_result.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = wait_result.get("stack_page", PackedByteArray()).duplicate()
	stack[0xC7] = 0xF6
	stack[0xC8] = 0x82
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x0515] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["record"] = PackedByteArray([0x00, 0xC4, 0x18, 0x19])
	boundary["pc"] = 0x82F7
	boundary["sp"] = 0xC8
	boundary["a"] = 0x01
	boundary["x"] = 0x07
	boundary["y"] = 0x06
	return boundary


func _supported_selector03_terminal_command_boundary() -> Dictionary:
	var boundary := _supported_selector03_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x04
	stack[0xC8] = 0x04
	stack[0xC9] = 0x49
	stack[0xCA] = 0x80
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0xC9
	ram[0x0060] = 0xA3
	ram[0x0063] = 0xB2
	ram[0x0064] = 0xA2
	ram[0x05E3] = 0x01
	ram[0x05E4] = 0x00
	ram[0x05E5] = 0x19
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x02
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05F3] = 0x00
	ram[0x05F4] = 0x01
	ram[0x05F5] = 0x05
	ram[0x0515] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0x04
	boundary["x"] = 0x04
	boundary["y"] = 0x04
	boundary["p"] = 0x30
	return boundary


func _supported_selector03_terminal_inactive_countdown_boundary() -> Dictionary:
	var boundary := _supported_selector03_terminal_command_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	stack[0xC7] = 0x02
	stack[0xC8] = 0x04
	for offset in 0x100:
		ram[0x0100 + offset] = stack[offset]
	ram[0x05E3] = 0x00
	ram[0x05E5] = 0x1A
	ram[0x05F5] = 0x04
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["a"] = 0x04
	boundary["y"] = 0x02
	return boundary


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


func _parameter47_f2_boundary(packet_wait: bool) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0000] = 0x11
	ram[0x005F] = 0x17
	ram[0x0060] = 0x99
	ram[0x05EA] = 0x47
	ram[0x0022] = 0x00
	if packet_wait:
		ram[0x05E3] = 0x01
		ram[0x05E4] = 0x02
		ram[0x05E5] = 0x03
		ram[0x05E6] = 0x0E
		ram[0x05E7] = 0x01
		ram[0x05E8] = 0x02
		ram[0x05E9] = 0x00
		ram[0x05F3] = 0x01
		ram[0x05F4] = 0x01
		ram[0x05F5] = 0x05
		ram[0x0515] = 0x00
		ram[0x0063] = 0xCD
		ram[0x0064] = 0xA2
		ram[0x0629] = 0x00
		stack[0xC7] = 0x24
		stack[0xC8] = 0x24
		stack[0xC9] = 0x49
		stack[0xCA] = 0x80
	else:
		ram[0x05E3] = 0x01
		ram[0x05E4] = 0x01
		ram[0x05E5] = 0x02
		ram[0x05E6] = 0x0E
		ram[0x05E7] = 0x02
		ram[0x05E8] = 0x02
		ram[0x05E9] = 0x01
		ram[0x05F3] = 0x00
		ram[0x05F4] = 0x00
		ram[0x05F5] = 0x01
		ram[0x0063] = 0xBC
		ram[0x0064] = 0xA2
		stack[0xC7] = 0x7C
		stack[0xC8] = 0x80
		stack[0xC9] = 0x4C
		stack[0xCA] = 0x80
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x11, "phase": 2, "pending_resume": 0, "ready_delay": 0,
		"pc": 0x804A if packet_wait else 0x804D,
		"sp": 0xCA, "active_task_slot": 0x11,
		"bank_low": 0x18, "bank_high": 0x19,
		"record": PackedByteArray([0x00, 0xC6 if packet_wait else 0xC2, 0x18, 0x19]),
		"a": 0x24 if packet_wait else 0x01,
		"x": 0x24 if packet_wait else 0x21,
		"y": 0x24 if packet_wait else 0x01,
		"p": 0x24, "p_known_mask": 0xC3,
		"mapper": {"select": 7, "bank_low": 0x18, "bank_high": 0x19,
			"bank_registers": {6: 0x18, 7: 0x19}},
		"ram_image": ram, "stack_page": stack,
	}


func _parameter47_index1_packet_resume_boundary(packet_wait: Dictionary) -> Dictionary:
	var boundary := _parameter47_f2_boundary(true)
	var ram: PackedByteArray = packet_wait.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = packet_wait.get("stack_page", PackedByteArray()).duplicate()
	stack[0xC7] = 0xF6
	stack[0xC8] = 0x82
	stack[0xC9] = 0x4C
	stack[0xCA] = 0x80
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	ram[0x005F] = 0x17
	ram[0x0060] = 0x99
	ram[0x05E4] = 0x02
	ram[0x05E5] = 0x03
	ram[0x05E6] = 0x0E
	ram[0x05E7] = 0x01
	ram[0x05E8] = 0x02
	ram[0x05E9] = 0x00
	ram[0x05F3] = 0x01
	ram[0x05F4] = 0x01
	ram[0x05F5] = 0x05
	ram[0x0515] = 0x00
	ram[0x0063] = 0xCD
	ram[0x0064] = 0xA2
	ram[0x0629] = 0x00
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	boundary["record"] = PackedByteArray([0x00, 0xC4, 0x18, 0x19])
	boundary["pc"] = 0x82F7
	boundary["sp"] = 0xC8
	boundary["a"] = 0x01
	boundary["x"] = 0x24
	boundary["y"] = 0x06
	boundary["p"] = 0x23
	return boundary


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


func _supported_index2_animation_boundary(base_boundary: Dictionary,
		animation_pointer: int) -> Dictionary:
	var boundary := base_boundary.duplicate(true)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray()).duplicate()
	var stack: PackedByteArray = boundary.get("stack_page", PackedByteArray()).duplicate()
	if ram.size() != 0x800 or stack.size() != 0x100:
		return {}
	ram[0x05F3] = 0x02
	ram[0x05F4] = 0x01
	ram[0x05F5] = 0x00
	ram[0x0515] = 0x00
	ram[0x05E3] = 0x01
	ram[0x0063] = animation_pointer & 0xFF
	ram[0x0064] = (animation_pointer >> 8) & 0xFF
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _has_source_read(result: Dictionary, address: int, value: int, kind: String) -> bool:
	for read_variant: Variant in result.get("source_reads", []):
		if read_variant is Dictionary \
				and int(read_variant.get("address", -1)) == address \
				and int(read_variant.get("value", -1)) == value \
				and String(read_variant.get("kind", "")) == kind:
			return true
	return false


func _fail(message: String) -> bool:
	push_error(message)
	return false
