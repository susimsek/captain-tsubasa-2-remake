extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_MANIFEST_SHA256 := "afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc"


func _init() -> void:
	var result := _verify_live_ed_row00_return()
	quit(0 if result else 1)


func _verify_live_ed_row00_return() -> bool:
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
	if not bool(first_slot05.get("ok", false)) \
			or String(first_slot05.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(first_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("First slot-$05 worker did not preserve its live slot-$09 handoff.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("First selected slot-$09 continuation did not reach its saved boundary.")
	var nmi3: Dictionary = runner.advance_on_external_nmi(3, 0x88)
	if not bool(nmi3.get("ok", false)) or int(nmi3.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 3 did not select the live slot-$05 continuation.")
	var second_wrapper: Dictionary = runner.resume_selected_slot05_worker()
	var wrapper_worker: Dictionary = second_wrapper.get("slot05_worker_result", {})
	if not bool(second_wrapper.get("ok", false)) \
			or String(second_wrapper.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(second_wrapper.get("next_selected_task_slot", -1)) != 0x09 \
			or String(wrapper_worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or String(wrapper_worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(wrapper_worker.get("exit_pc", -1)) != 0xC515:
		return _fail("The source second-wrapper continuation did not save its `$C515` yield.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("The source slot-$09 continuation after the second wrapper did not complete.")
	var nmi4: Dictionary = runner.advance_on_external_nmi(4, 0x88)
	if not bool(nmi4.get("ok", false)) or int(nmi4.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 4 did not select the next live slot-$05 continuation.")
	var row_result: Dictionary = runner.resume_selected_slot05_worker()
	var worker: Dictionary = row_result.get("slot05_worker_result", {})
	var validation: Dictionary = row_result.get("slot05_ed_row_boundary_validation", {})
	var descriptor_validation: Dictionary = row_result.get("slot05_worker_descriptor_contract", {})
	var input: Dictionary = row_result.get("slot05_worker_input", {})
	var input_ram: PackedByteArray = input.get("ram_image", PackedByteArray())
	var input_registers: Dictionary = input.get("registers", {})
	var input_mapper: Dictionary = input.get("mapper", {})
	var result_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = worker.get("stack_page", PackedByteArray())
	var blocked: Dictionary = worker.get("blocked_read", {})
	var registers: Dictionary = worker.get("registers", {})
	var mapper: Dictionary = worker.get("mapper", {})
	if not bool(row_result.get("ok", false)) \
			or String(row_result.get("status", "")) != "stopped_at_descriptor01_ee_row_boundary" \
			or String(row_result.get("phase", "")) != "stopped_at_slot05_descriptor01_next_row_boundary" \
			or not bool(row_result.get("slot05_worker_adopted", false)) \
			or String(worker.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or String(worker.get("exit_kind", "")) != "source_read_boundary" \
			or int(worker.get("exit_pc", -1)) != 0x89A0 \
			or int(blocked.get("instruction_pc", -1)) != 0x89A0 \
			or int(blocked.get("requested_address", -1)) != 0xBD9C \
			or int(blocked.get("bank", -1)) != 0x19 \
			or int(registers.get("pc", -1)) != 0x89A0 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or input_ram.size() != 0x800 or result_ram.size() != 0x800 \
			or stack.size() != 0x100 \
			or int(input_registers.get("a", -1)) != 0xFF \
			or int(input_registers.get("x", -1)) != 0xFF \
			or int(input_registers.get("y", -1)) != 0 \
			or int(input_registers.get("sp", -1)) != 0x4A \
			or int(input_registers.get("pc", -1)) != 0x8889 \
			or int(input_mapper.get("bank_low", -1)) != 0x18 \
			or int(input_mapper.get("bank_high", -1)) != 0x19 \
			or int(input_ram[0x002A]) != 0 or int(result_ram[0x002A]) != 0 \
			or int(result_ram[0x003C]) != 1 \
			or int(result_ram[0x003E]) != 0x9C or int(result_ram[0x003F]) != 0xBD \
			or int(result_ram[0x0515]) != 1 or int(result_ram[0x05C5]) != 0 \
			or int(stack[0x4F]) != 0xD0 or int(stack[0x50]) != 0xDA \
			or result_ram.slice(0x0100, 0x0200) != stack \
			or not bool(validation.get("ok", false)) \
			or String(descriptor_validation.get("status", "")) != "descriptor_source_validated_for_live_worker" \
			or int(descriptor_validation.get("second_descriptor_pointer_cpu", -1)) != 0xB464 \
			or int(descriptor_validation.get("descriptor01_text_pointer_cpu", -1)) != 0xBBE0 \
			or String(descriptor_validation.get("descriptor01_row00_hex", "")) != "ed00fc" \
			or int(descriptor_validation.get("descriptor01_next_row_pointer_cpu", -1)) != 0xBD9C \
			or bool(descriptor_validation.get("descriptor01_next_row_executed", true)) \
			or int(validation.get("next_row_cpu", -1)) != 0xBD9C \
			or bool(validation.get("next_row_read_executed", true)):
		return _fail("The live worker did not adopt the `$ED 00 FC` return and stop immediately before `$BD9C`.")
	var row_clear_seen := false
	var row_increment_seen := false
	var row_clear_index := -1
	var row_increment_index := -1
	var handler_index := -1
	var pcs := {}
	var instructions: Array = worker.get("instructions", [])
	var fc_return_observed := false
	for index in range(instructions.size()):
		var instruction: Dictionary = instructions[index]
		var pc := int(instruction.get("pc", -1))
		pcs[pc] = true
		if pc == 0x8AE7 and handler_index < 0:
			handler_index = index
		if pc == 0x8C54 and int(instruction.get("next_pc", -1)) == 0x896C:
			fc_return_observed = true
	for index in range((worker.get("writes", []) as Array).size()):
		var write: Dictionary = (worker.get("writes", []) as Array)[index]
		if int(write.get("address", -1)) != 0x003C:
			continue
		if int(write.get("pc", -1)) == 0x8954 and int(write.get("value", -1)) == 0:
			row_clear_seen = true
			row_clear_index = _first_instruction_index(instructions, 0x8954)
		if int(write.get("pc", -1)) == 0x8960 and int(write.get("value", -1)) == 1:
			row_increment_seen = true
			row_increment_index = _first_instruction_index(instructions, 0x8960)
	if not row_clear_seen or not row_increment_seen or handler_index < 0 \
			or row_clear_index < 0 or row_increment_index < row_clear_index \
			or row_increment_index >= handler_index or not fc_return_observed:
		return _fail("The live descriptor loop did not source `$003C=1` before `$ED`, or the `$FC` return PC chain was absent.")
	for pc in [0x89A0, 0x896C, 0x8AE7, 0x8A6F, 0x8B03, 0xC524, 0xCBC2, 0x8C9F, 0x8C52, 0x8C54, 0x89A9]:
		if not pcs.has(pc):
			return _fail("The live `$ED/$FC` worker trace omitted source PC `$%04X`." % pc)
	if pcs.has(0x8B2F):
		return _fail("The worker crossed into the following `$EE` handler instead of stopping at `$BD9C`.")
	var required_spans := {
		"bank19_match_descriptor_B464_B475.bin": false,
		"bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin": false,
		"bank18_ed_text_loop_8A56_8A86.bin": false,
		"bank18_ed_team_handler_8AE7_8B0A.bin": false,
		"bank18_ed_team_name_lengths_8B0A_8B0E.bin": false,
		"fixed_team_name_dispatch_C53C_C53F.bin": false,
		"fixed_team_name_lookup_F30F_F329.bin": false,
		"fixed_team_name_pointer_entries_76_79_F415_F41D.bin": false,
		"fixed_team_00_name_stream_F776_F77C.bin": false,
		"fixed_text_token_converter_CBC2_CBF1.bin": false,
	}
	for span_variant in worker.get("executed_source_spans", []):
		if span_variant is Dictionary:
			var file_name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(file_name):
				required_spans[file_name] = true
	for file_name in required_spans:
		if not bool(required_spans[file_name]):
			return _fail("The live `$ED` path did not consume required hash-bound span `%s`." % file_name)
	var adopted: Dictionary = row_result.get("slot05_worker_adopted_boundary", {})
	if int(adopted.get("pc", -1)) != 0x89A0 \
			or bool(row_result.get("next_task_body_executed", true)) \
			or bool(row_result.get("nmi_cadence_generated", true)) \
			or bool(row_result.get("ppu_bus_events_applied", true)):
		return _fail("The scheduler adoption did not stop at the live next-row boundary without advancing another task/NMI.")
	print("PASS: live slot-$05 source route consumed bank-$19 `$BBE0: ED 00 FC` through handler `$8AE7`, lookup/converter, and `$8C54 RTS -> $896C`.")
	print("PASS: ROM row code wrote `$003C=0` at `$8954`, incremented it to `1` at `$8960`, and the live `$002A=0` selected team-$00 data.")
	print("STOP: `$89A0` now points to `$BD9C`; the attempted read is blocked before any `$EE` byte or formatter executes.")
	return true


func _first_instruction_index(instructions: Array, pc: int) -> int:
	for index in range(instructions.size()):
		if instructions[index] is Dictionary and int((instructions[index] as Dictionary).get("pc", -1)) == pc:
			return index
	return -1


func _fail(message: String) -> bool:
	push_error(message)
	return false
