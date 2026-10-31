extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify_f0_worker_boundary():
		quit(1)
		return
	quit(0)


func _verify_f0_worker_boundary() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh context builder setup failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Source-generated kickoff context failed: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Route runner setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("last_source_boundary", "")) != "$EB8B":
		return _fail("Fresh route did not reach its ROM-derived `$EB8B` boundary.")
	var first_nmi: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(first_nmi.get("ok", false)) or not bool(first_nmi.get("awaiting_external_nmi", false)):
		return _fail("First caller-supplied NMI did not reach the checked second-NMI wait boundary.")
	var second_nmi: Dictionary = runner.advance_on_external_nmi(2, 0x88)
	if not bool(second_nmi.get("ok", false)) \
			or int(second_nmi.get("selected_task_slot", -1)) != 0x01 \
			or int(second_nmi.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("The actual second-NMI cycle did not select slot `$05` after the source `$CA4F` save.")
	var resumed: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(resumed.get("ok", false)):
		return _fail("Live slot-$05 resume failed: " + String(resumed.get("error", runner.error_message)))
	var worker: Dictionary = resumed.get("slot05_worker_result", {})
	var dispatch: Dictionary = resumed.get("slot05_dispatch", {})
	var live_boundary: Dictionary = resumed.get("slot05_live_boundary", {})
	var worker_input: Dictionary = resumed.get("slot05_worker_input", {})
	var descriptor_contract: Dictionary = resumed.get("slot05_descriptor_contract", {})
	var worker_contract: Dictionary = resumed.get("slot05_worker_descriptor_contract", {})
	var unsupported: Dictionary = worker.get("unsupported_opcode", {})
	var blocked: Dictionary = worker.get("blocked_read", {})
	var saved_boundary: Dictionary = resumed.get("slot05_cb0f_saved_boundary", {})
	var post_scan: Dictionary = resumed.get("post_slot05_scan", {})
	var scan_results: Array = resumed.get("post_slot05_scan_results", [])
	var next_boundary: Dictionary = resumed.get("next_selected_task_boundary", {})
	print("BOUNDARY: status=%s save_pc=$%04X scan_decision=$%02X selected=$%02X next_pc=$%04X checked=%s cursor=$%02X" % [
		String(resumed.get("status", "")), int(saved_boundary.get("pc", -1)),
		int(post_scan.get("decision", -1)), int(resumed.get("next_selected_task_slot", -1)),
		int(next_boundary.get("pc", -1)), str(post_scan.get("checked_slots", [])),
		int(post_scan.get("scheduler_scan_cursor", -1))])
	if String(resumed.get("status", "")) != "slot05_saved_and_rescanned" \
			or not bool(worker.get("ok", false)) \
			or String(worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker.get("exit_pc", -1)) != 0xC515 \
			or int(worker.get("exit_bank", -1)) != 0x1E \
			or not unsupported.is_empty() \
			or not blocked.is_empty() \
			or String(worker.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker.get("source_manifest_sha256", "")) != "afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc":
		return _fail("Live worker did not reach the `$C515` source yield boundary.")
	if int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19 \
			or int(live_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(worker_input.get("mapper", {}).get("select", -1)) != 0x07:
		return _fail("Worker input was not the actual second-NMI slot-$05 yielded dispatch and mapper state.")
	var source_inputs: Dictionary = descriptor_contract.get("source_inputs", {})
	if not bool(descriptor_contract.get("ok", false)) \
			or not bool(descriptor_contract.get("packet_data_complete", false)) \
			or not bool(descriptor_contract.get("source_inputs_ready", false)) \
			or not (descriptor_contract.get("unresolved_source_tokens", []) as Array).is_empty() \
			or int(source_inputs.get("$0027", -1)) != 0 \
			or int(source_inputs.get("$05F7", -1)) != 0xB4 \
			or int(source_inputs.get("$05F8", -1)) != 0 \
			or String(worker_contract.get("status", "")) != "descriptor_source_validated_for_live_worker" \
			or String(worker_contract.get("descriptor_second_row_hex", "")) != "f0fc" \
			or not bool(worker_contract.get("descriptor_second_row_source_validated", false)):
		return _fail("ROM-derived `$0027/$05F7/$05F8` or hash-checked `$F0,$FC` row contract did not validate.")
	var instructions: Array = worker.get("instructions", [])
	var instruction_pcs: Dictionary = {}
	for instruction_variant in instructions:
		if instruction_variant is Dictionary:
			instruction_pcs[int((instruction_variant as Dictionary).get("pc", -1))] = true
	var rol_completed := false
	var cmp_zp_seen := false
	var sbc_zp_seen := false
	for instruction_variant in instructions:
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		if int(instruction.get("pc", -1)) == 0xCD46 \
				and int(instruction.get("opcode", -1)) == 0x26 \
				and int(instruction.get("next_pc", -1)) == 0xCD48:
			rol_completed = true
		if int(instruction.get("opcode", -1)) == 0xC5:
			cmp_zp_seen = true
		if int(instruction.get("opcode", -1)) == 0xE5:
			sbc_zp_seen = true
	for pc in [0x89A0, 0x8B8B, 0x8C55, 0xCD3C, 0xCD46, 0xCD52]:
		if not instruction_pcs.has(pc):
			return _fail("The executed worker trace omitted ROM instruction `$%04X` on the F0 path." % pc)
	if not rol_completed or not cmp_zp_seen or not sbc_zp_seen:
		return _fail("The worker did not execute the bounded divider's observed ROL/CMP/SBC zero-page operations.")
	var token_read_count := 0
	var fc_return_count := 0
	for instruction_variant in instructions:
		if not instruction_variant is Dictionary:
			continue
		var instruction_pc := int((instruction_variant as Dictionary).get("pc", -1))
		if instruction_pc == 0x89A0:
			token_read_count += 1
		if instruction_pc == 0x8C52:
			fc_return_count += 1
	if not instruction_pcs.has(0xC51E) or token_read_count != 4 or fc_return_count != 2:
		return _fail("Worker did not consume both `$FC` row-return callbacks before its `$C515` yield.")
	var required_spans := {
		"bank19_resumed_worker_text_row01_BBDE_BBE0.bin": true,
		"bank18_resumed_worker_vector_tail_89D7_89DC.bin": true,
		"bank18_f0_match_clock_handler_8B8B_8BD5.bin": true,
		"bank18_f0_decimal_formatter_8C55_8C85.bin": true,
		"fixed_division_dispatch_C51E_C521.bin": true,
		"fixed_division_16bit_CD3C_CD77.bin": true,
	}
	for span_variant in worker.get("executed_source_spans", []):
		if span_variant is Dictionary:
			required_spans.erase(String((span_variant as Dictionary).get("file", "")))
	if not required_spans.is_empty():
		return _fail("F0 path omitted required hash-checked source spans: " + str(required_spans.keys()))
	if not (worker.get("mapper_writes", []) as Array).is_empty() \
			or not bool(resumed.get("slot05_worker_adopted", false)) \
			or int(saved_boundary.get("pc", -1)) != 0xCB0F \
			or int(saved_boundary.get("slot_base", -1)) != 0x05 \
			or int(saved_boundary.get("phase", -1)) != 3 \
			or post_scan.is_empty() or scan_results.size() != 1 \
			or int(resumed.get("next_selected_task_slot", -1)) < 0 \
			or bool(resumed.get("next_task_body_executed", true)) \
			or bool(resumed.get("nmi_cadence_generated", true)) \
			or bool(resumed.get("ppu_bus_events_applied", true)):
		return _fail("Route did not save slot-$05 through `$CB0F` and stop at one source scan boundary without later work.")
	var scheduler = runner.get("_scheduler")
	if scheduler == null:
		return _fail("Could not inspect the route's live scheduler after automatic adoption.")
	var adopted: Dictionary = resumed.get("slot05_worker_adopted_boundary", {})
	var current_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var result_registers: Dictionary = worker.get("registers", {})
	var worker_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var worker_stack: PackedByteArray = worker.get("stack_page", PackedByteArray())
	var next_task_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x09)
	var scan_ram_before: PackedByteArray = saved_boundary.get("ram_image", PackedByteArray())
	var scan_ram_after: PackedByteArray = current_boundary.get("ram_image", PackedByteArray())
	var scan_ram_diffs: Array[String] = []
	for ram_address in range(mini(scan_ram_before.size(), scan_ram_after.size())):
		if scan_ram_before[ram_address] != scan_ram_after[ram_address]:
			scan_ram_diffs.append("$%04X:%02X>%02X" % [ram_address,
				scan_ram_before[ram_address], scan_ram_after[ram_address]])
	if int(adopted.get("pc", -1)) != 0xC515 \
			or int(adopted.get("active_task_slot", -1)) != 0x05 \
			or int(adopted.get("a", -1)) != int(result_registers.get("a", -2)) \
			or int(adopted.get("x", -1)) != int(result_registers.get("x", -2)) \
			or int(adopted.get("y", -1)) != int(result_registers.get("y", -2)) \
			or int(adopted.get("p", -1)) != int(result_registers.get("p", -2)) \
			or int(adopted.get("p_known_mask", -1)) != int(result_registers.get("p_known_mask", -2)) \
			or int(adopted.get("sp", -1)) != int(result_registers.get("sp", -2)) \
			or int(adopted.get("bank_low", -1)) != 0x18 \
			or int(adopted.get("bank_high", -1)) != 0x19 \
			or adopted.get("ram_image", PackedByteArray()) != worker_ram \
			or adopted.get("stack_page", PackedByteArray()) != worker_stack \
			or adopted.get("record", PackedByteArray()) != live_boundary.get("record", PackedByteArray()) \
			or int(adopted.get("scheduler_scan_cursor", -1)) != 0x05 \
			or int(current_boundary.get("pc", -1)) != 0xCB0F \
			or current_boundary.get("record", PackedByteArray()) != saved_boundary.get("record", PackedByteArray()) \
			or scan_ram_diffs.size() != 1 or scan_ram_diffs[0] != "$0009:01>00" \
			or current_boundary.get("stack_page", PackedByteArray()) != saved_boundary.get("stack_page", PackedByteArray()) \
			or int(scheduler.get_status().get("scheduler_scan_cursor", -1)) \
				!= int(post_scan.get("scheduler_scan_cursor", -2)):
		return _fail("Route API did not preserve worker output, save the exact task context, and return after the source scan.")
	var worker_sp := int(result_registers.get("sp", -1))
	var saved_sp := (worker_sp - 2) & 0xFF
	var result_mapper: Dictionary = worker.get("mapper", {})
	var expected_saved_record := PackedByteArray([
		int(result_registers.get("a", -1)), saved_sp,
		int(result_mapper.get("bank_low", -1)), int(result_mapper.get("bank_high", -1)),
	])
	var expected_saved_ram := worker_ram.duplicate()
	expected_saved_ram[0x007F] = int(result_registers.get("a", -1))
	expected_saved_ram[0x0100 + worker_sp] = int(result_registers.get("x", -1))
	expected_saved_ram[0x0100 + ((worker_sp - 1) & 0xFF)] = int(result_registers.get("y", -1))
	for record_offset in range(expected_saved_record.size()):
		expected_saved_ram[0x05 + record_offset] = expected_saved_record[record_offset]
	var expected_saved_stack := worker_stack.duplicate()
	expected_saved_stack[worker_sp] = int(result_registers.get("x", -1))
	expected_saved_stack[(worker_sp - 1) & 0xFF] = int(result_registers.get("y", -1))
	var saved_ram: PackedByteArray = saved_boundary.get("ram_image", PackedByteArray())
	var saved_stack: PackedByteArray = saved_boundary.get("stack_page", PackedByteArray())
	if saved_boundary.get("record", PackedByteArray()) != expected_saved_record \
			or saved_ram != expected_saved_ram or saved_stack != expected_saved_stack \
			or int(saved_boundary.get("ram_007F", -1)) != int(result_registers.get("a", -2)):
		return _fail("`$CB0F` save result differs from the worker's live A/X/Y/SP and mapper state.")
	var expected_scan_decision: int = int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME)
	if int(post_scan.get("decision", -1)) != expected_scan_decision \
			or post_scan.get("checked_slots", []) != [0x09] \
			or int(resumed.get("next_selected_task_slot", -1)) != 0x09 \
			or int(next_task_boundary.get("slot_base", -1)) != 0x09 \
			or int(next_task_boundary.get("phase", -1)) != 3 \
			or int(next_task_boundary.get("pending_resume", -1)) != 2 \
			or int(next_task_boundary.get("pc", -1)) != 0xCB0F \
			or next_task_boundary.get("record", PackedByteArray()) != PackedByteArray([0, 0x76, 0x18, 0x19]) \
			or bool(resumed.get("next_task_body_executed", true)):
		return _fail("The ROM-ordered scan did not stop at slot-$09's actual yielded pre-dispatch boundary.")
	var worker_writes: Array = worker.get("writes", [])
	var input_ram: PackedByteArray = worker_input.get("ram_image", PackedByteArray())
	var replayed_ram := input_ram.duplicate()
	for write_variant in worker_writes:
		var write: Dictionary = write_variant
		replayed_ram[int(write["address"])] = int(write["value"])
	if replayed_ram != worker_ram or worker_ram.size() != 0x800 or worker_stack.size() != 0x100:
		return _fail("Adopted worker RAM/stack is not the exact replay of its recorded ROM instruction writes.")
	var calls: Array = worker.get("calls", [])
	print("PASS: row-one `$F0,$FC` completed through the ROM callback, formatter, divider, and row-return path.")
	print("PASS: route API adopted worker writes and CPU/stack state, then saved `$C515->$CB0F` from live A/X/Y/SP and banks.")
	print("PASS: the scan decremented slot `$09` from `$01` to `$00` and stopped at its pre-dispatch yielded boundary; no body or NMI ran.")
	print("INPUT: slot=$05 PC=$8889 A=$%02X X=$%02X Y=$%02X SP=$%02X banks=$18/$19 selector=$07; `$0027=$%02X`, clock=`$%04X`." % [
		int(dispatch.get("a", -1)), int(dispatch.get("x", -1)), int(dispatch.get("y", -1)),
		int(dispatch.get("sp", -1)), int(source_inputs.get("$0027", -1)),
		int(source_inputs.get("$05F7", -1)) | (int(source_inputs.get("$05F8", -1)) << 8)])
	print("WORKER: instructions=%d calls=%d RAM writes=%d mapper writes=0; slot-$05 saved record=%s." % [
		int(worker.get("instruction_count", -1)), calls.size(), worker_writes.size(),
		(saved_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode()])
	print("STATE: RAM SHA input=%s output=%s; stack SHA input=%s output=%s; packet buffer `$04A5-$04B4`=%s." % [
		_sha256(input_ram), _sha256(worker_ram), _sha256(worker_input.get("stack_page", PackedByteArray())),
		_sha256(worker_stack), worker_ram.slice(0x04A5, 0x04B5).hex_encode()])
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return "unavailable"
	return context.finish().hex_encode()
