extends SceneTree
## Verifies a synthetic slot-$05 `$CC53` boundary through the ROM waiter's
## actual `$CCD1 RTS->$D70F` return using explicit synthetic normal-NMI proofs.
## Also checks one synthetic `$CCA3` terminal-packet step before its scheduler
## yield. It is not FCEUX, production-route, PPU-pixel, or timing evidence.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_confirmation_waiter_post_nmi_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const NORMAL_NMI_PROOF := {
	"schema": "rom-normal-nmi-c8fb-entry-proof-v1",
	"rom_sha256": ROM_SHA256,
	"nmi_kind": "normal",
	"call_site_pc": 0xC799,
	"entry_pc": 0xC8FB,
	"ram_001b_at_dispatch": 0x00,
	"source_dispatch_observed": true,
	"test_fixture": true,
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("Could not configure the hash-pinned PASS waiter sources: " + executor.error_message)
		return
	var boundary := _make_boundary()
	var first_packet: Dictionary = executor.execute_next_counted_packet_yield(boundary)
	var first_packet_next: Dictionary = first_packet.get("next_boundary_snapshot", {})
	var first_packet_ram: PackedByteArray = first_packet_next.get("ram_image", PackedByteArray())
	var first_packet_stack: PackedByteArray = first_packet_next.get("stack_page", PackedByteArray())
	var packet_stack_reads: Array = first_packet.get("source_stack_reads", [])
	var packet_stack_writes: Array = first_packet.get("source_stack_writes", [])
	var packet_writes: Array = first_packet.get("source_writes", [])
	if not bool(first_packet.get("ok", false)) \
			or int(first_packet.get("exit_pc", -1)) != 0xCC50 \
			or int(first_packet_next.get("sp", -1)) != 0x47 \
			or first_packet_ram.size() != 0x800 or first_packet_stack.size() != 0x100 \
			or int(first_packet_ram[0x04A6]) != 0x88 \
			or int(first_packet_ram[0x04A7]) != 0x23 \
			or int(first_packet_ram[0x04C1]) != 0xA8 \
			or int(first_packet_stack[0x48]) != 0x05 \
			or packet_stack_reads.size() != 2 \
			or int(packet_stack_reads[0].get("source_pc", -1)) != 0xCC76 \
			or int(packet_stack_reads[0].get("address", -1)) != 0x0148 \
			or int(packet_stack_reads[1].get("source_pc", -1)) != 0xCC98 \
			or int(packet_stack_reads[1].get("address", -1)) != 0x0148 \
			or packet_stack_writes.size() != 2 \
			or int(packet_stack_writes[0].get("source_pc", -1)) != 0xCC77 \
			or int(packet_stack_writes[1].get("source_pc", -1)) != 0xCC4D \
			or not _has_source_write(packet_writes, 0xCC7B, 0x04A6, 0x10) \
			or not _has_source_write(packet_writes, 0xCC7F, 0x04A6, 0x88):
		_fail("The live-shaped first `$CC53` packet differs from ROM PLA/PHA, ROR, packet, or stack behavior: " + str({
			"status": first_packet.get("status", ""),
			"error": first_packet.get("error", ""),
			"exit_pc": first_packet.get("exit_pc", -1),
			"registers": first_packet.get("registers", {}),
			"$04A6": first_packet_ram[0x04A6] if first_packet_ram.size() > 0x04A6 else -1,
			"stack_reads": packet_stack_reads, "stack_writes": packet_stack_writes,
			"writes": packet_writes}))
		return
	var input_ram: PackedByteArray = boundary["ram_image"].duplicate()
	var input_stack: PackedByteArray = boundary["stack_page"].duplicate()
	var proofs: Array = []
	for _index in 8:
		proofs.append(NORMAL_NMI_PROOF.duplicate(true))
	var result: Dictionary = executor.execute_to_waiter_return(boundary, proofs)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_confirmation_waiter_returned_to_d70f" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0xCC53 \
			or int(result.get("exit_pc", -1)) != 0xD70F \
			or int(result.get("exit_bank", -1)) != 0x1E:
		_fail("The shared PASS waiter did not reach its source `$CCD1->$D70F` return: " + str(result))
		return
	var registers: Dictionary = result.get("registers", {})
	var next_boundary: Dictionary = result.get("next_boundary_snapshot", {})
	var output_ram: PackedByteArray = next_boundary.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = next_boundary.get("stack_page", PackedByteArray())
	var receipts: Array = result.get("normal_nmi_receipts", [])
	var stack_reads: Array = result.get("source_stack_reads", [])
	var stack_writes: Array = result.get("source_stack_writes", [])
	var writes: Array = result.get("source_writes", [])
	var pcs: Array = result.get("source_instruction_pcs", [])
	if output_ram.size() != 0x800 or output_stack.size() != 0x100 \
			or output_ram.slice(0x0100, 0x0200) != output_stack \
			or int(next_boundary.get("pc", -1)) != 0xD70F \
			or int(next_boundary.get("sp", -1)) != 0x4A \
			or int(registers.get("pc", -1)) != 0xD70F \
			or int(registers.get("sp", -1)) != 0x4A \
			or int(registers.get("a", -1)) != 1 \
			or int(output_ram[0x0515]) != 0 \
			or int(output_stack[0x49]) != 0x0E \
			or int(output_stack[0x4A]) != 0xD7 \
			or receipts.size() != 8 \
			or int(result.get("normal_nmi_count", -1)) != 8 \
			or stack_reads.size() < 30 or stack_writes.size() < 29 \
			or writes.size() < 600 \
			or pcs.is_empty() or int(pcs[0]) != 0xCC53 or int(pcs[-1]) != 0xCCD1 \
			or bool(result.get("ppu_effects_applied", true)) \
			or bool(result.get("apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)) \
			or not bool(result.get("test_fixture", false)) \
			or not bool(result.get("input_boundary_unchanged", false)) \
			or boundary["ram_image"] != input_ram or boundary["stack_page"] != input_stack:
		_fail("Waiter RAM, stack, queue receipts, or real return boundary differs from the source model: " + str({
			"status": result.get("status", ""), "exit_pc": next_boundary.get("pc", -1),
			"sp": registers.get("sp", -1), "A": registers.get("a", -1),
			"nmi_count": receipts.size(), "stack_reads": stack_reads.size(),
			"stack_writes": stack_writes.size(), "writes": writes.size(),
			"pcs_first_last": [pcs[0], pcs[-1]] if not pcs.is_empty() else []}))
		return
	for index in 7:
		var receipt: Dictionary = receipts[index]
		var expected_callsite := 0xCCA0 if index == 6 else 0xCC50
		var expected_resume := 0xCCA3 if index == 6 else 0xCC53
		if int(receipt.get("callsite_pc", -1)) != expected_callsite \
				or int(receipt.get("resume_pc", -1)) != expected_resume \
				or int(receipt.get("source_flag_before", -1)) != 0x80 \
				or int(receipt.get("source_flag_after", -1)) != 0 \
				or (receipt.get("packet_summaries", []) as Array).size() != 3:
			_fail("Counted waiter NMI receipt %d differs from its source yield/queue transition." % index)
			return
	var final_receipt: Dictionary = receipts[7]
	if int(final_receipt.get("callsite_pc", -1)) != 0xCCCE \
			or int(final_receipt.get("resume_pc", -1)) != 0xCCD1 \
			or int(final_receipt.get("source_flag_before", -1)) != 0x80 \
			or int(final_receipt.get("source_flag_after", -1)) != 0 \
			or (final_receipt.get("packet_summaries", []) as Array).size() != 3:
		_fail("The final packet NMI did not return to the source `$CCD1 RTS`: " + str(final_receipt))
		return
	var stale_queue_boundary := _make_boundary()
	var stale_queue_ram: PackedByteArray = stale_queue_boundary["ram_image"].duplicate()
	stale_queue_ram[0x0515] = 0x80
	stale_queue_boundary["ram_image"] = stale_queue_ram
	var rejected_stale_queue: Dictionary = executor.execute_to_waiter_return(
		stale_queue_boundary, proofs)
	if bool(rejected_stale_queue.get("ok", true)) \
			or String(rejected_stale_queue.get("status", "")) != "invalid_pass_waiter_boundary":
		_fail("The executor accepted `$CC53` before the normal NMI had cleared `$0515`.")
		return
	var missing_proofs: Dictionary = executor.execute_to_waiter_return(boundary, proofs.slice(0, 7))
	if bool(missing_proofs.get("ok", true)) \
			or String(missing_proofs.get("status", "")) != "missing_nmi_proofs":
		_fail("The executor accepted a waiter run without all eight explicit NMI receipts.")
		return
	var terminal_boundary := _make_terminal_boundary()
	var terminal_input_ram: PackedByteArray = terminal_boundary["ram_image"].duplicate()
	var terminal_input_stack: PackedByteArray = terminal_boundary["stack_page"].duplicate()
	var terminal: Dictionary = executor.execute_next_terminal_packet_yield(terminal_boundary)
	var terminal_registers: Dictionary = terminal.get("registers", {})
	var terminal_call: Dictionary = terminal.get("call_request", {})
	var terminal_next: Dictionary = terminal.get("next_boundary_snapshot", {})
	var terminal_ram: PackedByteArray = terminal_next.get("ram_image", PackedByteArray())
	var terminal_stack: PackedByteArray = terminal_next.get("stack_page", PackedByteArray())
	var terminal_writes: Array = terminal.get("source_writes", [])
	var terminal_reads: Array = terminal.get("source_reads", [])
	var terminal_pcs: Array = terminal.get("source_instruction_pcs", [])
	if not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "pass_waiter_terminal_packet_yield_ready" \
			or int(terminal.get("entry_pc", -1)) != 0xCCA3 \
			or int(terminal.get("exit_pc", -1)) != 0xCCCE \
			or int(terminal.get("resume_pc_after_scheduler_jsr", -1)) != 0xCCD1 \
			or int(terminal_next.get("pc", -1)) != 0xCCCE \
			or int(terminal_next.get("sp", -1)) != 0x48 \
			or int(terminal_registers.get("a", -1)) != 1 \
			or int(terminal_registers.get("x", -1)) != 0x21 \
			or int(terminal_ram.size()) != 0x800 or terminal_stack.size() != 0x100 \
			or terminal_ram.slice(0x0100, 0x0200) != terminal_stack \
			or int(terminal_ram[0x0515]) != 0x80 \
			or int(terminal_ram[0x04A5]) != 0x20 \
			or int(terminal_ram[0x04A6]) != 0xE0 \
			or int(terminal_ram[0x04A7]) != 0x23 \
			or int(terminal_ram[0x04A8]) != 0 or int(terminal_ram[0x04C8]) != 0x20 \
			or terminal_writes.size() != 38 or terminal_reads.size() != 1 \
			or terminal_pcs.is_empty() or int(terminal_pcs[0]) != 0xCCA3 \
			or int(terminal_pcs[-1]) != 0xCCCE \
			or int(terminal_call.get("callsite_pc", -1)) != 0xCCCE \
			or int(terminal_call.get("target_pc", -1)) != 0xCB0F \
			or int(terminal_call.get("return_word", -1)) != 0xCCD0 \
			or int(terminal_call.get("return_pc", -1)) != 0xCCD1 \
			or int(terminal_call.get("sp_before_push", -1)) != 0x48 \
			or not bool(terminal_call.get("scheduler_must_push_call_frame", false)) \
			or bool(terminal.get("scheduler_save_executed", true)) \
			or bool(terminal.get("external_nmi_consumed", true)) \
			or bool(terminal.get("ppu_effects_applied", true)) \
			or bool(terminal.get("trace_state_used", true)) \
			or not bool(terminal.get("test_fixture", false)) \
			or not bool(terminal.get("input_boundary_unchanged", false)) \
			or terminal_boundary["ram_image"] != terminal_input_ram \
			or terminal_boundary["stack_page"] != terminal_input_stack:
		_fail("The `$CCA3` terminal packet did not stop at its source `$CCCE` scheduler yield: " + str({
			"status": terminal.get("status", ""), "pc": terminal_next.get("pc", -1),
			"sp": terminal_next.get("sp", -1), "writes": terminal_writes.size(),
			"reads": terminal_reads.size(), "x": terminal_registers.get("x", -1),
			"pcs": [terminal_pcs[0], terminal_pcs[-1]] if not terminal_pcs.is_empty() else [],
			"ram_size": terminal_ram.size(), "stack_size": terminal_stack.size(),
			"flag": terminal_ram[0x0515] if terminal_ram.size() > 0x515 else -1,
			"boundary_entry": [terminal.get("entry_pc", -1), terminal.get("exit_pc", -1),
				terminal.get("resume_pc_after_scheduler_jsr", -1)],
			"registers": terminal_registers,
			"packet_fill": [terminal_ram[0x04A8], terminal_ram[0x04C8]] if terminal_ram.size() > 0x04C8 else [],
			"packet_header": terminal_ram.slice(0x04A5, 0x04A8).hex_encode() if terminal_ram.size() > 0x04A8 else "",
			"write_ends": [terminal_writes[0], terminal_writes[-1]] if not terminal_writes.is_empty() else [],
			"call": terminal_call,
			"not_applied": [terminal.get("scheduler_save_executed", null),
				terminal.get("external_nmi_consumed", null), terminal.get("ppu_effects_applied", null),
				terminal.get("trace_state_used", null), terminal.get("test_fixture", null),
				terminal.get("input_boundary_unchanged", null)]}))
		return
	var stale_terminal := _make_terminal_boundary()
	var stale_terminal_ram: PackedByteArray = stale_terminal["ram_image"].duplicate()
	stale_terminal_ram[0x0515] = 0x80
	stale_terminal["ram_image"] = stale_terminal_ram
	var rejected_stale_terminal: Dictionary = executor.execute_next_terminal_packet_yield(stale_terminal)
	if bool(rejected_stale_terminal.get("ok", true)) \
			or String(rejected_stale_terminal.get("status", "")) != "invalid_pass_waiter_terminal_boundary":
		_fail("The terminal-packet executor accepted a stale pending `$0515` queue flag.")
		return
	var rts_boundary := _make_rts_boundary()
	var rts_input_ram: PackedByteArray = rts_boundary["ram_image"].duplicate()
	var rts_input_stack: PackedByteArray = rts_boundary["stack_page"].duplicate()
	var rts_result: Dictionary = executor.execute_waiter_rts_return(rts_boundary)
	var rts_registers: Dictionary = rts_result.get("registers", {})
	var rts_next: Dictionary = rts_result.get("next_boundary_snapshot", {})
	var rts_ram: PackedByteArray = rts_next.get("ram_image", PackedByteArray())
	var rts_stack: PackedByteArray = rts_next.get("stack_page", PackedByteArray())
	var rts_reads: Array = rts_result.get("source_stack_reads", [])
	var rts_pcs: Array = rts_result.get("source_instruction_pcs", [])
	if not bool(rts_result.get("ok", false)) \
			or String(rts_result.get("status", "")) != "pass_confirmation_waiter_returned_to_d70f" \
			or int(rts_result.get("entry_pc", -1)) != 0xCCD1 \
			or int(rts_result.get("exit_pc", -1)) != 0xD70F \
			or int(rts_next.get("pc", -1)) != 0xD70F or int(rts_next.get("sp", -1)) != 0x4A \
			or int(rts_registers.get("pc", -1)) != 0xD70F \
			or int(rts_registers.get("sp", -1)) != 0x4A \
			or rts_ram.slice(0x0100, 0x0200) != rts_stack \
			or int(rts_stack[0x49]) != 0x0E or int(rts_stack[0x4A]) != 0xD7 \
			or rts_reads.size() != 2 or rts_pcs != [0xCCD1] \
			or int(rts_reads[0].get("address", -1)) != 0x0149 \
			or int(rts_reads[0].get("value", -1)) != 0x0E \
			or String(rts_reads[0].get("role", "")) != "rts_return_low" \
			or int(rts_reads[1].get("address", -1)) != 0x014A \
			or int(rts_reads[1].get("value", -1)) != 0xD7 \
			or String(rts_reads[1].get("role", "")) != "rts_return_high" \
			or bool(rts_result.get("scheduler_save_executed", true)) \
			or bool(rts_result.get("external_nmi_consumed", true)) \
			or bool(rts_result.get("trace_state_used", true)) \
			or not bool(rts_result.get("test_fixture", false)) \
			or not bool(rts_result.get("input_boundary_unchanged", false)) \
			or rts_boundary["ram_image"] != rts_input_ram \
			or rts_boundary["stack_page"] != rts_input_stack:
		_fail("The `$CCD1 RTS` did not pop `$0E/$D7` and stop at `$D70F`/SP `$4A`: " + str({
			"status": rts_result.get("status", ""), "next": rts_next,
			"registers": rts_registers, "reads": rts_reads, "instruction_pcs": rts_pcs}))
		return
	var invalid_rts_boundary := _make_rts_boundary()
	var invalid_rts_stack: PackedByteArray = invalid_rts_boundary["stack_page"].duplicate()
	invalid_rts_stack[0x49] = 0x0F
	for index in invalid_rts_stack.size():
		(invalid_rts_boundary["ram_image"] as PackedByteArray)[0x0100 + index] = invalid_rts_stack[index]
	invalid_rts_boundary["stack_page"] = invalid_rts_stack
	var rejected_invalid_rts: Dictionary = executor.execute_waiter_rts_return(invalid_rts_boundary)
	if bool(rejected_invalid_rts.get("ok", true)) \
			or String(rejected_invalid_rts.get("status", "")) != "invalid_pass_waiter_rts_boundary":
		_fail("The `$CCD1 RTS` executor accepted a caller frame that does not return to `$D70F`.")
		return
	var cleanup_boundary := _make_cleanup_boundary()
	var cleanup_input_ram: PackedByteArray = cleanup_boundary["ram_image"].duplicate()
	var cleanup_input_stack: PackedByteArray = cleanup_boundary["stack_page"].duplicate()
	var cleanup: Dictionary = executor.execute_waiter_caller_cleanup(cleanup_boundary)
	var cleanup_registers: Dictionary = cleanup.get("registers", {})
	var cleanup_next: Dictionary = cleanup.get("next_boundary_snapshot", {})
	var cleanup_ram: PackedByteArray = cleanup_next.get("ram_image", PackedByteArray())
	var cleanup_stack: PackedByteArray = cleanup_next.get("stack_page", PackedByteArray())
	var cleanup_writes: Array = cleanup.get("source_writes", [])
	var cleanup_reads: Array = cleanup.get("source_stack_reads", [])
	var cleanup_pcs: Array = cleanup.get("source_instruction_pcs", [])
	var cleanup_bytes: PackedByteArray = cleanup.get("source_instruction_bytes", PackedByteArray())
	if not bool(cleanup.get("ok", false)) \
			or String(cleanup.get("status", "")) != "pass_waiter_caller_cleanup_returned" \
			or String(cleanup.get("source_span", "")) != "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/pass_confirmation_wait_return_D70C_D717.bin" \
			or int(cleanup.get("natural_return_pc", -1)) != 0xD568 \
			or int(cleanup.get("exit_pc", -1)) != 0xD568 \
			or int(cleanup_next.get("pc", -1)) != 0xD568 \
			or int(cleanup_next.get("sp", -1)) != 0x4E \
			or int(cleanup_registers.get("a", -1)) != 0x80 \
			or int(cleanup_registers.get("x", -1)) != 0x21 \
			or int(cleanup_registers.get("y", -1)) != 0x03 \
			or int(cleanup_registers.get("p", -1)) != 0xB1 \
			or cleanup_bytes != PackedByteArray([0xA9, 0x00, 0x8D, 0x2D, 0x06, 0x68, 0x68, 0x60]) \
			or cleanup_pcs != [0xD70F, 0xD711, 0xD714, 0xD715, 0xD716] \
			or cleanup_ram.size() != 0x800 or cleanup_stack.size() != 0x100 \
			or cleanup_ram.slice(0x0100, 0x0200) != cleanup_stack \
			or int(cleanup_ram[0x062D]) != 0 \
			or cleanup_writes.size() != 1 \
			or int(cleanup_writes[0].get("source_pc", -1)) != 0xD711 \
			or int(cleanup_writes[0].get("trace_pc", -1)) != 0xD714 \
			or int(cleanup_writes[0].get("address", -1)) != 0x062D \
			or int(cleanup_writes[0].get("old", -1)) != 0x81 \
			or int(cleanup_writes[0].get("value", -1)) != 0 \
			or cleanup_reads.size() != 4 \
			or int(cleanup_reads[0].get("address", -1)) != 0x014B \
			or int(cleanup_reads[0].get("value", -1)) != 0x5A \
			or int(cleanup_reads[1].get("address", -1)) != 0x014C \
			or int(cleanup_reads[1].get("value", -1)) != 0x80 \
			or int(cleanup_reads[2].get("address", -1)) != 0x014D \
			or int(cleanup_reads[2].get("value", -1)) != 0x67 \
			or int(cleanup_reads[3].get("address", -1)) != 0x014E \
			or int(cleanup_reads[3].get("value", -1)) != 0xD5 \
			or bool(cleanup.get("scheduler_save_executed", true)) \
			or bool(cleanup.get("trace_state_used", true)) \
			or not bool(cleanup.get("test_fixture", false)) \
			or not bool(cleanup.get("input_boundary_unchanged", false)) \
			or cleanup_boundary["ram_image"] != cleanup_input_ram \
			or cleanup_boundary["stack_page"] != cleanup_input_stack:
		_fail("The `$D70F-$D716` caller tail did not restore its natural `$D568` return and complete state: " + str({
			"status": cleanup.get("status", ""), "next": cleanup_next,
			"registers": cleanup_registers, "writes": cleanup_writes,
			"stack_reads": cleanup_reads, "instruction_bytes": cleanup_bytes.hex_encode()}))
		return
	var bad_cleanup_boundary := _make_cleanup_boundary()
	var bad_cleanup_stack: PackedByteArray = bad_cleanup_boundary["stack_page"].duplicate()
	bad_cleanup_stack[0x4D] = 0x09
	var bad_cleanup_ram: PackedByteArray = bad_cleanup_boundary["ram_image"].duplicate()
	for index in bad_cleanup_stack.size():
		bad_cleanup_ram[0x0100 + index] = bad_cleanup_stack[index]
	bad_cleanup_boundary["ram_image"] = bad_cleanup_ram
	bad_cleanup_boundary["stack_page"] = bad_cleanup_stack
	var rejected_bad_cleanup: Dictionary = executor.execute_waiter_caller_cleanup(bad_cleanup_boundary)
	if bool(rejected_bad_cleanup.get("ok", true)) \
			or String(rejected_bad_cleanup.get("status", "")) != "source_return_stack_mismatch":
		_fail("The caller-cleanup executor accepted a return word that does not lead to `$D568`.")
		return
	print("PASS: hash-pinned PASS waiter source reached `$CCD1 RTS->$D70F` after seven counted packet waits and the final packet wait.")
	print("PASS: the first `$CC53` iteration matches `$CC76 PLA`, `$CC77 PHA`, both `$04A6` ROR writes, and `$CC4D` counter push.")
	print("PASS: six `$CC50->$CC53` loops, one `$CCA0->$CCA3` tail wait, and one `$CCCE->$CCD1` final wait each consumed the source queue; final SP is `$4A`.")
	print("PASS: a separate live-shaped `$CCA3` step builds the terminal packet and stops before `$CCCE->$CB0F` save/NMI.")
	print("PASS: a separate `$CCD1 RTS` step pops the source caller return and stops at `$D70F`/SP `$4A`.")
	print("PASS: source `$D70F-$D716` caller cleanup clears `$062D`, pops the live stack bytes, and naturally returns to `$D568` from the fixture's `$D567` return word.")
	print("LIMIT: the `$CC53` fixture and NMI proofs are synthetic; no live PASS route, NMI cadence, PPU register effects, pixels, audio, or frame timing is established.")
	quit(0)


func _make_boundary() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	ram[0x0000] = 0x05
	ram[0x001B] = 0x00
	ram[0x0024] = 0x1C
	ram[0x0025] = 0x1D
	ram[0x0498] = 0x00
	ram[0x0515] = 0x00
	stack[0x48] = 0x06
	stack[0x49] = 0x0E
	stack[0x4A] = 0xD7
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": 0xCC53,
		"sp": 0x47,
		"a": 0x01,
		"x": 0x00,
		"y": 0x03,
		"p": 0x31,
		"p_known_mask": 0xFF,
		"bank_low": 0x1C,
		"bank_high": 0x1D,
		"mapper": {"bank_low": 0x1C, "bank_high": 0x1D,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": ram,
		"stack_page": stack,
		"source_label": "synthetic PASS `$CC53` post-NMI waiter fixture",
		"test_fixture": true,
		"trace_state_used": false,
	}


func _make_terminal_boundary() -> Dictionary:
	var boundary := _make_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	boundary["pc"] = 0xCCA3
	boundary["sp"] = 0x48
	boundary["x"] = 0x4F
	boundary["y"] = 0x00
	boundary["source_label"] = "synthetic PASS `$CCA3` terminal-packet fixture"
	stack[0x47] = 0xA2
	stack[0x48] = 0xCC
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _make_rts_boundary() -> Dictionary:
	var boundary := _make_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	boundary["pc"] = 0xCCD1
	boundary["sp"] = 0x48
	boundary["x"] = 0x21
	boundary["y"] = 0x00
	boundary["source_label"] = "synthetic PASS `$CCD1` RTS return fixture"
	stack[0x47] = 0xD0
	stack[0x48] = 0xCC
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _make_cleanup_boundary() -> Dictionary:
	var boundary := _make_boundary()
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	boundary["pc"] = 0xD70F
	boundary["sp"] = 0x4A
	boundary["a"] = 0x78
	boundary["x"] = 0x21
	boundary["y"] = 0x03
	boundary["source_label"] = "synthetic PASS `$D70F` caller cleanup fixture"
	ram[0x062D] = 0x81
	stack[0x4B] = 0x5A
	stack[0x4C] = 0x80
	stack[0x4D] = 0x67
	stack[0x4E] = 0xD5
	for index in stack.size():
		ram[0x0100 + index] = stack[index]
	boundary["ram_image"] = ram
	boundary["stack_page"] = stack
	return boundary


func _has_source_write(writes: Array, source_pc: int, address: int, value: int) -> bool:
	for write_variant in writes:
		if write_variant is Dictionary and int(write_variant.get("source_pc", -1)) == source_pc \
				and int(write_variant.get("address", -1)) == address \
				and int(write_variant.get("value", -1)) == value:
			return true
	return false


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
