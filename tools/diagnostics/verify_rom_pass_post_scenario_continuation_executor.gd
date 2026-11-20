extends SceneTree
## Focused verifier for the bounded PASS continuation. Both the scheduler
## return and descriptor-renderer return below are explicitly synthetic
## fixtures; this does not claim production route integration or renderer work.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_post_scenario_continuation_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("PASS continuation ROM sources failed: " + String(executor.error_message))
		return
	var source_status: Dictionary = executor.get_source_status()
	if not bool(source_status.get("configured", false)) \
			or String(source_status.get("e6ec_sha256", "")) \
			!= "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c" \
			or int(source_status.get("stop_boundary_pc", -1)) != 0xCB0F \
			or not bool(source_status.get("stop_boundary_is_call_entry", false)):
		_fail("Configured source status does not pin the ROM path or `$CB0F` call-entry stop.")
		return

	var boundary := _make_scheduler_return_fixture()
	var original_ram: PackedByteArray = boundary["ram_image"].duplicate()
	var original_stack: PackedByteArray = boundary["stack_page"].duplicate()
	var receipt := _make_renderer_return_fixture()
	var result: Dictionary = executor.execute_from_live_boundary(boundary, receipt)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_receiver_wait_yield_at_cb0f_call_entry" \
			or int(result.get("entry_pc", -1)) != 0xD7ED \
			or int(result.get("entry_sp", -1)) != 0x40 \
			or int(result.get("renderer_entry_pc", -1)) != 0xEF7F \
			or int(result.get("renderer_descriptor_id", -1)) != 0x0F \
			or int(result.get("renderer_return_pc", -1)) != 0xD7F2 \
			or int(result.get("exit_pc", -1)) != 0xCB0F \
			or int(result.get("resume_pc_after_yield", -1)) != 0xD80F:
		_fail("Continuation did not reach the bounded receiver `$CB0F` call entry: " + str(result))
		return

	var output: Dictionary = result.get("next_boundary_snapshot", {})
	var output_ram: PackedByteArray = output.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = output.get("stack_page", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var holder: Dictionary = result.get("holder_copy", {})
	var cursor: Dictionary = result.get("cursor", {})
	if output_ram.size() != 0x0800 or output_stack.size() != 0x100 \
			or output_ram.slice(0x0100, 0x0200) != output_stack \
			or int(output_ram[0x062D]) != 0x81 or int(output_ram[0x0494]) != 0x1F \
			or int(output_ram[0x0034]) != 0x48 or int(output_ram[0x0035]) != 0x03 \
			or int(output_ram[0x0635]) != 0x7C or int(output_ram[0x0637]) != 0xAC \
			or int(output_ram[0x05FE]) != 0x77 or int(output_ram[0x0624]) != 0x77 \
			or int(output_ram[0x0625]) != 0 or int(output_ram[0x0441]) != 0x06 \
			or int(holder.get("record_pointer", -1)) != 0x0348 \
			or int(holder.get("tile_index_05fe", -1)) != 0x77 \
			or int(cursor.get("candidate_count_0430", -1)) != 0 \
			or int(registers.get("pc", -1)) != 0xCB0F \
			or int(registers.get("sp", -1)) != 0x3E \
			or int(output_ram[0x0140]) != 0xD8 or int(output_ram[0x013F]) != 0x0E:
		_fail("`$EF7F->$E6EC->$D80C` writes, cursor tile, or final scheduler call frame differ: " + str(result))
		return
	var expected_writes := [
		{"source_pc": 0xD7F4, "address": 0x062D, "value": 0x81},
		{"source_pc": 0xD7F9, "address": 0x0494, "value": 0x1F},
		{"source_pc": 0xCD80, "address": 0x0034, "value": 0x48},
		{"source_pc": 0xCD83, "address": 0x0035, "value": 0x03},
		{"source_pc": 0xE6F6, "address": 0x0635, "value": 0x7C},
		{"source_pc": 0xE6FE, "address": 0x0637, "value": 0xAC},
		{"source_pc": 0xE705, "address": 0x05FE, "value": 0x77},
		{"source_pc": 0xD801, "address": 0x0625, "value": 0x00},
		{"source_pc": 0xD807, "address": 0x0624, "value": 0x77},
	]
	var expected_stack_writes := [
		[0xD7EF, 0x0140, 0xD7, "jsr_push_high"], [0xD7EF, 0x013F, 0xF1, "jsr_push_low"],
		[0xD7FC, 0x0140, 0xD7, "jsr_push_high"], [0xD7FC, 0x013F, 0xFE, "jsr_push_low"],
		[0xE6EF, 0x013E, 0xE6, "jsr_push_high"], [0xE6EF, 0x013D, 0xF1, "jsr_push_low"],
		[0xE702, 0x013E, 0xE7, "jsr_push_high"], [0xE702, 0x013D, 0x04, "jsr_push_low"],
		[0xD80C, 0x0140, 0xD8, "jsr_push_high"], [0xD80C, 0x013F, 0x0E, "jsr_push_low"],
	]
	if result.get("source_writes", []) != expected_writes \
			or not _stack_writes_match(result.get("source_stack_writes", []), expected_stack_writes) \
			or (result.get("source_reads", []) as Array).size() != 5 \
			or (result.get("calls", []) as Array).size() != 5 \
			or (result.get("descriptor_panel_packets", []) as Array).size() != 10:
		_fail("Ordered ROM writes, nested JSR frames, reads, calls, or descriptor-$0F packets differ.")
		return
	var calls: Array = result.get("calls", [])
	var input_pcs: Array = result.get("entry_to_yield_instructions", [])
	if int(calls[0].get("callsite", -1)) != 0xD7EF \
			or int(calls[0].get("descriptor_id", -1)) != 0x0F \
			or int(calls[4].get("callsite", -1)) != 0xD80C \
			or int(calls[4].get("target", -1)) != 0xCB0F \
			or not input_pcs.has(0xD80A) or not input_pcs.has(0xD80C) \
			or input_pcs.has(0xD80F):
		_fail("Call order or the stop-before-input-poll boundary is wrong.")
		return
	if bool(result.get("scheduler_yield_executed", true)) \
			or bool(result.get("receiver_input_poll_executed", true)) \
			or bool(result.get("ppu_effects_applied", true)) \
			or bool(result.get("apu_effects_applied", true)) \
			or not bool(result.get("renderer_return_fixture", false)) \
			or bool(result.get("runtime_integrated", true)):
		_fail("The bounded result overclaims scheduler, renderer, PPU, APU, input, or route execution.")
		return
	if boundary["ram_image"] != original_ram or boundary["stack_page"] != original_stack:
		_fail("Executor mutated the scheduler-boundary input images.")
		return

	var unmarked_fixture := _make_scheduler_return_fixture()
	unmarked_fixture.erase("test_fixture")
	unmarked_fixture.erase("fixture_label")
	var fixture_receipt_rejected := executor.execute_from_live_boundary(unmarked_fixture, receipt)
	if bool(fixture_receipt_rejected.get("ok", true)):
		_fail("Executor accepted a fixture renderer return on an unmarked live boundary.")
		return
	var wrong_receiver := _make_scheduler_return_fixture()
	var wrong_ram: PackedByteArray = wrong_receiver["ram_image"].duplicate()
	wrong_ram[0x0441] = 0xFF
	wrong_receiver["ram_image"] = wrong_ram
	var wrong_slot_rejected := executor.execute_from_live_boundary(wrong_receiver, receipt)
	if bool(wrong_slot_rejected.get("ok", true)):
		_fail("Executor accepted a holder slot outside the ROM player-record table.")
		return
	var wrong_pc := _make_scheduler_return_fixture()
	wrong_pc["pc"] = 0xD7EC
	var wrong_pc_rejected := executor.execute_from_live_boundary(wrong_pc, receipt)
	if bool(wrong_pc_rejected.get("ok", true)):
		_fail("Executor accepted a non-D7ED scheduler return.")
		return

	print("PASS: ROM-derived `$D7ED->$EF7F($0F)->$E6EC->$D80C->$CB0F` continuation yields cursor `$77` for the explicit holder-$06 fixture.")
	print("PASS: exact `$CD7C/$CD89` pointer lookup and `$CDE2` coordinate-index helper write holder coordinates and scheduler stack state.")
	print("LIMIT: scheduler return and renderer return are synthetic test fixtures; `$EF7F` worker/PPU effects, live integration, `$CB0F` execution, first `$D80F` poll, audio, and timing remain unverified.")
	quit(0)


func _make_scheduler_return_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x0800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0x41] = 0x34
	stack[0x42] = 0xD6
	ram[0x0100 + 0x41] = 0x34
	ram[0x0100 + 0x42] = 0xD6
	ram[0x0000] = 0x05
	ram[0x0441] = 0x06
	ram[0x0516] = 0x00
	ram[0x0518] = 0x38
	# Isolated test fixture: player record $0348 carries the supplied-ROM
	# match-zero coordinates used by this path; production receives live RAM.
	ram[0x034E] = 0x7C
	ram[0x0350] = 0xAC
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05, "active_task_slot": 0x05, "phase": 2,
		"pc": 0xD7ED, "sp": 0x40,
		"a": 0x00, "x": 0x00, "y": 0x00, "p": 0x20, "p_known_mask": 0xFF,
		"bank_low": 0x1A, "bank_high": 0x1B, "executing_cpu_bank": 0x1E,
		"mapper_proof": {"banks_at_fixed_dispatch": [0x1C, 0x1D], "fixed_bank": 0x1E},
		"ram_image": ram, "stack_page": stack, "trace_state_used": false,
		"test_fixture": true,
		"fixture_label": "synthetic D7ED scheduler-return fixture; not a route result",
	}


func _make_renderer_return_fixture() -> Dictionary:
	return {
		"ok": true, "rom_sha256": ROM_SHA256,
		"callsite_pc": 0xD7EF, "entry_pc": 0xEF7F,
		"descriptor_id": 0x0F, "return_pc": 0xD7F2,
		"returned_via_rts": true, "trace_state_used": false,
		"fixture_only": true,
		"fixture_label": "synthetic EF7F descriptor-0F return receipt; not a renderer result",
	}


func _stack_writes_match(actual_variant: Variant, expected: Array) -> bool:
	if not actual_variant is Array or actual_variant.size() != expected.size():
		return false
	for index in expected.size():
		var actual: Variant = actual_variant[index]
		if not actual is Dictionary:
			return false
		var row: Array = expected[index]
		if int(actual.get("source_pc", -1)) != int(row[0]) \
				or int(actual.get("address", -1)) != int(row[1]) \
				or int(actual.get("value", -1)) != int(row[2]) \
				or String(actual.get("operation", "")) != String(row[3]):
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
