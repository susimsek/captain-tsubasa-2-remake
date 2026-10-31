extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const EXECUTOR := preload("res://scripts/gameplay/rom_ee9f_empty_actor_call_executor.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: live route consumed the source slot-$01 `$CA52->$EE9F` request, then reached `$CA55->$E3CA`.")
	print("PASS: ROM-byte prologue, mapper helper, bank-$14 zero gate, six inactive actor flags, and empty OAM clear returned to `$CA55`.")
	print("PASS: final CPU, mapper writes, RAM, stack, actor order, and all 64 hidden-OAM Y writes matched the bounded source path.")
	print("LIMIT: this is a source-specific instruction executor, not general 6502 emulation; it does not model active actors, PPU cycles/bus effects, rendering, or audio.")
	quit(0)


func _verify() -> bool:
	var context_builder = CONTEXT_BUILDER.new()
	if not context_builder.configure_from_project_sources():
		return _fail("Fresh context builder setup failed: " + context_builder.error_message)
	var context = context_builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Source-generated kickoff context failed: " + context_builder.error_message)

	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Route runner setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("last_source_boundary", "")) != "$EB8B":
		return _fail("Fresh route did not reach its source-derived `$EB8B` yield boundary.")
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)) \
			or String(advance.get("phase", "")) != "waiting_for_slot09_cb0f_handler_source" \
			or String(advance.get("last_source_boundary", "")) != "$EB88->$CB0F" \
			or not bool(advance.get("slot05_worker_resumed", false)):
		return _fail("The source runner did not execute the slot-$05 worker path and continue the scheduler scan to slot `$09:$EB8B`.")
	var dispatch: Dictionary = advance.get("slot01_dispatch", {})
	var boundary: Dictionary = advance.get("slot01_pre_ee9f_boundary", {})
	var request: Dictionary = advance.get("slot01_callee_request", {})
	if int(dispatch.get("pc", -1)) != 0xCA52 or int(boundary.get("sp", -1)) != 0x2A \
			or int(request.get("target_cpu_address", -1)) != 0xEE9F:
		return _fail("Live scheduler dispatch, snapshot, and call request are not aligned.")

	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("ROM source package setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_source_call(dispatch, boundary, request)
	if not bool(result.get("ok", false)):
		return _fail("Bounded `$EE9F` execution stopped: " + str(result))
	var live_result: Dictionary = advance.get("ee9f_result", {})
	if String(live_result.get("status", "")) != "returned_to_source_caller" \
			or live_result.get("registers", {}) != result.get("registers", {}) \
			or live_result.get("memory_writes", []) != result.get("memory_writes", []):
		return _fail("The live route's `$EE9F` result differs from a replay of the same source dispatch and inputs.")
	var registers: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var banks: Dictionary = mapper.get("bank_registers", {})
	var final_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var final_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var visits: Array = result.get("actor_visits", [])
	var writes: Array = result.get("memory_writes", [])
	if int(registers.get("a", -1)) != 0xF8 or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 0 or int(registers.get("sp", -1)) != 0x2A \
			or int(registers.get("pc", -1)) != 0xCA55 \
			or int(registers.get("p_known_mask", -1)) != 0xC3 \
			or int(registers.get("p_known_value", -1)) != 0x03 \
			or int(registers.get("p_unknown_mask", -1)) != 0x3C:
		return _fail("Final CPU state does not match the verified empty-actor return boundary.")
	if int(mapper.get("register_select", -1)) != 7 \
			or int(banks.get(6, -1)) != 0x14 or int(banks.get(7, -1)) != 0x15 \
			or int(mapper.get("task_bank_low", -1)) != int(dispatch.get("bank_low", -2)) \
			or int(mapper.get("task_bank_high", -1)) != int(dispatch.get("bank_high", -2)):
		return _fail("MMC3 register writes or preserved scheduler task banks are incorrect.")
	if final_ram.size() != 0x800 or final_stack.size() != 0x100 \
			or int(final_ram[0x003A]) != 6 or int(final_ram[0x003B]) != 0 \
			or int(final_ram[0x003C]) != 0xB0 or int(final_ram[0x003D]) != 0x05 \
			or int(final_ram[0x0048]) != 0 or int(final_ram[0x053F]) != 0x40:
		return _fail("Actor-loop counters, selected record pointer, or OAM-clear length are incorrect.")
	if visits.size() != 6 or writes.size() != 101:
		return _fail("Expected six inactive visits and 101 writes; got %d visits and %d writes." % [visits.size(), writes.size()])
	var expected_pointers := [0x0547, 0x055C, 0x0571, 0x0586, 0x059B, 0x05B0]
	for ordinal in range(6):
		var visit: Dictionary = visits[ordinal]
		var pointer := int(expected_pointers[ordinal])
		if int(visit.get("ordinal", -1)) != ordinal \
				or int(visit.get("actor_index", -1)) != ordinal \
				or int(visit.get("actor_pointer", -1)) != pointer \
				or int(visit.get("flag", -1)) != 0 or not bool(visit.get("inactive", false)) \
				or int(final_ram[pointer]) != 0:
			return _fail("Actor `%d` was not selected from live RAM and the ROM pointer table." % ordinal)
	for index in range(64):
		var address := 0x0200 + index * 4
		if int(final_ram[address]) != 0xF8:
			return _fail("OAM shadow clear omitted `$%04X`." % address)
	if int(final_stack[0x29]) != 0x54 or int(final_stack[0x2A]) != 0xCA \
			or int(final_stack[0x28]) != 0xEE or int(final_stack[0x27]) != 0xB0 \
			or int(final_stack[0x26]) != 0xAC:
		return _fail("6502 JSR/RTS/PHA/PLA stack bytes do not match the nested ROM call path.")
	if not bool(result.get("returned_to_caller", false)) \
			or result.get("ppu_bus_events", []) != [] \
			or bool(result.get("ppu_cycle_timing_modeled", true)):
		return _fail("Result must report the caller return and explicit absence of PPU-cycle modeling.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
