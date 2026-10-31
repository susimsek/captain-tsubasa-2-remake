extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_MANIFEST_SHA256 := "afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc"


func _init() -> void:
	var ok := _verify_live_ee_row00_return()
	quit(0 if ok else 1)


func _verify_live_ee_row00_return() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh KICK OFF context sources failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Could not produce the fresh KICK OFF source context: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route configuration failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)):
		return _fail("Source route did not begin: " + String(begin.get("error", runner.error_message)))
	for frame in [1, 2]:
		var nmi: Dictionary = runner.advance_on_external_nmi(frame, 0x88)
		if not bool(nmi.get("ok", false)):
			return _fail("External NMI %d was not consumed at its recorded scheduler boundary." % frame)
	var first_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(first_slot05.get("ok", false)) or int(first_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("First slot-$05 worker did not preserve its slot-$09 handoff.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("First selected slot-$09 continuation did not reach its saved boundary.")
	var nmi3: Dictionary = runner.advance_on_external_nmi(3, 0x88)
	if not bool(nmi3.get("ok", false)) or int(nmi3.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 3 did not select slot-$05.")
	var second_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(second_slot05.get("ok", false)) or int(second_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Second slot-$05 wrapper did not save its source yield.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("Slot-$09 continuation after the second wrapper did not complete.")
	var nmi4: Dictionary = runner.advance_on_external_nmi(4, 0x88)
	if not bool(nmi4.get("ok", false)) or int(nmi4.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 4 did not select the live slot-$05 worker.")
	var ed_boundary: Dictionary = runner.resume_selected_slot05_worker()
	if String(ed_boundary.get("status", "")) == "slot05_saved_and_rescanned" \
			and int(ed_boundary.get("next_selected_task_slot", -1)) == 0x09:
		if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
			return _fail("Intervening selected slot-$09 worker did not reach its saved boundary.")
		var nmi5: Dictionary = runner.advance_on_external_nmi(5, 0x88)
		if not bool(nmi5.get("ok", false)) or int(nmi5.get("next_selected_task_slot", -1)) != 0x05:
			return _fail("External NMI 5 did not select the source slot-$05 descriptor worker.")
		ed_boundary = runner.resume_selected_slot05_worker()
	var ed_worker: Dictionary = ed_boundary.get("slot05_worker_result", {})
	if not bool(ed_boundary.get("ok", false)) \
			or String(ed_boundary.get("status", "")) != "stopped_at_descriptor01_ee_row_boundary" \
			or String(ed_worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or int(ed_worker.get("exit_pc", -1)) != 0x89A0:
		return _fail("Expected `$ED` boundary; phase=%s status=%s pc=$%04X reason=%s worker=%s" % [
			String(ed_boundary.get("phase", "")), String(ed_boundary.get("status", "")),
			int(ed_worker.get("exit_pc", -1)), String(ed_boundary.get("reason", "")),
			str({"blocked": ed_worker.get("blocked_read", {}),
				"unsupported": ed_worker.get("unsupported_opcode", {})})])
	var before: Dictionary = ed_boundary.get("slot05_worker_adopted_boundary", {})
	var input_ram: PackedByteArray = before.get("ram_image", PackedByteArray())
	if int(input_ram[0x0028]) != 0 or int(input_ram[0x003C]) != 1 \
			or (int(input_ram[0x003E]) | (int(input_ram[0x003F]) << 8)) != 0xBD9C:
		return _fail("The adopted live continuation does not have `$0028=0`, `$003C=1`, and pointer `$BD9C`.")
	var ee_result: Dictionary = runner.resume_slot05_descriptor01_ee_row00()
	var worker: Dictionary = ee_result.get("slot05_worker_result", {})
	var validation: Dictionary = ee_result.get("slot05_ee_row_boundary_validation", {})
	var result_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var result_registers: Dictionary = worker.get("registers", {})
	var result_mapper: Dictionary = worker.get("mapper", {})
	var blocked: Dictionary = worker.get("blocked_read", {})
	if not bool(ee_result.get("ok", false)) \
			or String(ee_result.get("status", "")) != "stopped_after_descriptor01_ee_row00_yield" \
			or String(ee_result.get("phase", "")) != "stopped_after_slot05_descriptor01_ee_row00_yield" \
			or String(worker.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or String(worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker.get("exit_pc", -1)) != 0xC515 \
			or not blocked.is_empty() \
			or int(result_registers.get("pc", -1)) != 0xC515 \
			or int(result_mapper.get("bank_low", -1)) != 0x18 \
			or int(result_mapper.get("bank_high", -1)) != 0x19 \
			or int(result_ram[0x0028]) != 0 \
			or (int(result_ram[0x003E]) | (int(result_ram[0x003F]) << 8)) != 0xBD9C \
			or not bool(validation.get("ok", false)) \
			or int(validation.get("next_descriptor_row_cpu", -1)) != 0xBBE3 \
			or bool(validation.get("next_descriptor_row_pointer_live", true)) \
			or int(ee_result.get("next_descriptor_row_cpu", -1)) != 0xBBE3 \
			or bool(ee_result.get("next_descriptor_row_pointer_live", true)) \
			or bool(ee_result.get("scheduler_scan_performed", true)):
		return _fail("The `$EE 00 FC` path did not stop at its `$C515` yield: runner=%s status=%s validation=%s blocked=%s worker=%s" % [
			runner.error_message, String(ee_result.get("status", "")), str(validation),
			str(blocked), str(worker)])
	var pcs := {}
	var early_branch := false
	var fc_return := false
	var early_rts := false
	for instruction_variant in worker.get("instructions", []):
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		var pc := int(instruction.get("pc", -1))
		pcs[pc] = true
		if pc == 0x8C58 and int(instruction.get("next_pc", -1)) == 0x8C84:
			early_branch = true
		if pc == 0x8C54 and int(instruction.get("next_pc", -1)) == 0x896C:
			fc_return = true
		if pc == 0x8C84 and int(instruction.get("opcode", -1)) == 0x60:
			early_rts = true
	for required_pc in [0x89A0, 0x8B2F, 0x8C55, 0x8C58, 0x8C84, 0x8C52, 0x8C54, 0x896C]:
		if not pcs.has(required_pc):
			return _fail("The live row trace omitted ROM PC `$%04X`." % required_pc)
	if not early_branch or not fc_return or not early_rts:
		return _fail("The formatter early return or inline `$FC` return was not source-observed.")
	var required_spans := {
		"bank19_match_descriptor_B475_B47D.bin": false,
		"bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin": false,
		"bank18_ee_numeric_handler_8B2F_8B48.bin": false,
		"bank18_f0_decimal_formatter_8C55_8C85.bin": false,
	}
	for span_variant in worker.get("executed_source_spans", []):
		if span_variant is Dictionary:
			var name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(name):
				required_spans[name] = true
	for name in required_spans:
		if not bool(required_spans[name]):
			return _fail("The live row trace omitted source span %s." % name)
	var after: Dictionary = ee_result.get("slot05_worker_adopted_boundary", {})
	if int(after.get("pc", -1)) != 0xC515 \
			or int(after.get("active_task_slot", -1)) != 0x05 \
			or int(after.get("ram_007F", -1)) != int(before.get("ram_007F", -2)):
		return _fail("The slot-$05 scheduler context or queue-facing state was not preserved at the stop boundary.")
	var input_registers := {"a": int(before.get("a", -1)), "x": int(before.get("x", -1)),
		"y": int(before.get("y", -1)), "p": int(before.get("p", -1)),
		"p_known_mask": int(before.get("p_known_mask", -1)), "sp": int(before.get("sp", -1)),
		"pc": int(before.get("pc", -1))}
	var output_registers := {"a": int(result_registers.get("a", -1)),
		"x": int(result_registers.get("x", -1)), "y": int(result_registers.get("y", -1)),
		"p": int(result_registers.get("p", -1)), "sp": int(result_registers.get("sp", -1)),
		"pc": int(result_registers.get("pc", -1))}
	print("STATE: input CPU=%s RAM[$0028,$003C,$003E-$003F,$0515,$05C5]=[%d,%d,$%02X,$%02X,$%02X,$%02X]." % [
		str(input_registers), int(input_ram[0x0028]), int(input_ram[0x003C]),
		int(input_ram[0x003E]), int(input_ram[0x003F]), int(input_ram[0x0515]), int(input_ram[0x05C5])])
	print("STATE: output CPU=%s RAM[$003C,$003E-$003F,$0515,$05C5]=[%d,$%02X,$%02X,$%02X,$%02X]." % [
		str(output_registers), int(result_ram[0x003C]), int(result_ram[0x003E]),
		int(result_ram[0x003F]), int(result_ram[0x0515]), int(result_ram[0x05C5])])
	print("PASS: live slot-$05 `$BD9C: EE 00 FC` selected `$0028=0` and entered `$8B2F->$8C55`.")
	print("PASS: `$003C=1` took the formatter early return `$8C58->$8C84`; `$FC` returned `$8C54->$896C`.")
	print("PASS: the route retained the live `$C515` result and applied the ROM-checked `$CB0F` task save.")
	var save_scan: Dictionary = runner.save_slot05_ee_row_yield_and_scan()
	var saved_boundary: Dictionary = save_scan.get("slot05_cb0f_saved_boundary", {})
	var scan: Dictionary = save_scan.get("post_slot05_scan", {})
	var next_boundary: Dictionary = save_scan.get("next_selected_task_boundary", {})
	var saved_record: PackedByteArray = saved_boundary.get("record", PackedByteArray())
	var next_record: PackedByteArray = next_boundary.get("record", PackedByteArray())
	var saved_ram: PackedByteArray = saved_boundary.get("ram_image", PackedByteArray())
	var next_ram: PackedByteArray = next_boundary.get("ram_image", PackedByteArray())
	var ram_diffs: Array[String] = []
	for address in range(mini(saved_ram.size(), next_ram.size())):
		if saved_ram[address] != next_ram[address]:
			ram_diffs.append("$%04X:%02X>%02X" % [address, saved_ram[address], next_ram[address]])
	if not bool(save_scan.get("ok", false)) \
			or String(save_scan.get("status", "")) != "slot05_ee_row_cb0f_saved_and_scanned" \
			or String(save_scan.get("phase", "")) != "waiting_for_selected_task_source" \
			or String(save_scan.get("rom_sha256", "")) != ROM_SHA256 \
			or int(saved_boundary.get("pc", -1)) != 0xCB0F \
			or int(saved_boundary.get("slot_base", -1)) != 0x05 \
			or int(saved_boundary.get("active_task_slot", -1)) != -1 \
			or saved_record != PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
			or int(saved_boundary.get("sp", -1)) != 0x46 \
			or int(saved_boundary.get("ram_007F", -1)) != 0x01 \
			or saved_ram.size() != 0x800 \
			or int(saved_ram[0x0147]) != 0x03 or int(saved_ram[0x0148]) != 0x0F \
			or int(saved_ram[0x0149]) != 0x88 or int(saved_ram[0x014A]) != 0x88 \
			or int(scan.get("decision", -1)) != 1 \
			or scan.get("checked_slots", []) != [0x09] \
			or int(scan.get("scheduler_scan_cursor", -1)) != 0x09 \
			or int(save_scan.get("next_selected_task_slot", -1)) != 0x09 \
			or int(next_boundary.get("pc", -1)) != 0xCB0F \
			or int(next_boundary.get("ready_delay", -1)) != 0 \
			or int(next_boundary.get("phase", -1)) != 3 \
			or int(next_boundary.get("pending_resume", -1)) != 2 \
			or next_record != PackedByteArray([0x00, 0x76, 0x18, 0x19]) \
			or ram_diffs != ["$0009:01>00"] \
			or bool(save_scan.get("next_task_body_executed", true)) \
			or bool(save_scan.get("nmi_cadence_generated", true)):
		return _fail("Live `$C515->$CB0F` save or following slot-$09 boundary differs: %s" % str({
			"runner_error": runner.error_message,
			"save_status": save_scan.get("status"),
			"saved_record": saved_record.hex_encode(),
			"scan": scan,
			"next_record": next_record.hex_encode(),
			"ram_diffs": ram_diffs}))
	print("PASS: `$CB0F` saved slot `$05` as `01 46 18 19`, retaining X/Y and the existing `$8888` JSR frame on its stack.")
	print("PASS: `$CAA5` decremented only slot `$09` from `$01` to `$00` and selected its yielded pre-dispatch boundary at `$CB0F`.")
	print("STOP: slot `$09` remains undispatched; no NMI cadence or later task body ran.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
