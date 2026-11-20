extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/manifest.json"


func _initialize() -> void:
	var checkpoint_path := OS.get_environment("CT2_SLOT11_BOUNDARY_JSON").strip_edges()
	if checkpoint_path.is_empty() or not FileAccess.file_exists(checkpoint_path):
		_fail("Set CT2_SLOT11_BOUNDARY_JSON to a retained ordinary-input Godot route boundary JSON file.")
		return
	var file := FileAccess.open(checkpoint_path, FileAccess.READ)
	if file == null:
		_fail("Could not open route boundary JSON: " + checkpoint_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_fail("Route boundary must be a JSON object.")
		return
	var checkpoint: Dictionary = parsed
	if String(checkpoint.get("source", "")) != "ordinary_input_godot_source_route":
		_fail("Refusing a checkpoint without ordinary-input Godot route provenance.")
		return
	var registers: Dictionary = checkpoint.get("registers", {})
	var mapper: Dictionary = checkpoint.get("mapper", {})
	var boundary := {
		"source_frame": int(checkpoint.get("source_frame", -1)),
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"slot_base": int(checkpoint.get("slot_base", -1)),
		"phase": 2, "ready_delay": 0, "pending_resume": 0,
		"active_task_slot": 0x11,
		"pc": int(checkpoint.get("pc", -1)), "sp": int(checkpoint.get("sp", -1)),
		"a": int(registers.get("a", -1)), "x": int(registers.get("x", -1)),
		"y": int(registers.get("y", -1)), "p": int(registers.get("p", -1)),
		"p_known_mask": int(registers.get("p_known_mask", -1)),
		"record": String(checkpoint.get("record_hex", "")).hex_decode(),
		"bank_low": int(checkpoint.get("bank_low", -1)),
		"bank_high": int(checkpoint.get("bank_high", -1)),
		"mapper": mapper,
		"ram_image": String(checkpoint.get("ram_hex", "")).hex_decode(),
		"stack_page": String(checkpoint.get("stack_hex", "")).hex_decode(),
	}
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		_fail("ROM source setup failed: " + executor.error_message)
		return
	if OS.get_environment("CT2_VERIFY_FOLLOWUP_PACKET_RESUME").strip_edges() == "1":
		var packet_resume: Dictionary = executor.execute_from_slot11_packet_wait_resume_boundary(boundary)
		if not bool(packet_resume.get("ok", false)):
			_fail("Frame-%d `$82F7` ROM packet resume failed: %s" % [
				int(boundary["source_frame"]), String(packet_resume.get("error", "unsupported source path"))])
			return
		var resume_ram: PackedByteArray = packet_resume.get("ram_image", PackedByteArray())
		var resume_reads: Array = packet_resume.get("source_reads", [])
		var resume_callsite: Dictionary = packet_resume.get("yield_callsite_registers", {})
		var resume_cb0f: Dictionary = packet_resume.get("cb0f_entry_registers", {})
		var resume_mapper: Dictionary = packet_resume.get("mapper", {})
		var resume_initial_mapper: Dictionary = packet_resume.get("initial_mapper", {})
		var row02_header := PackedByteArray([
			0x0E, 0xF0, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0E, 0x10, 0x23,
		])
		var followup_text := PackedByteArray([0x61, 0x6C, 0x69, 0x79, 0x6F, 0x72, 0x21])
		var followup_stream := PackedByteArray([0x61, 0x6C, 0x69, 0x79, 0x6F, 0x72, 0x21, 0xFC])
		var followup_reads_match := true
		for offset in followup_stream.size():
			followup_reads_match = followup_reads_match and _has_read(
				resume_reads, 0x9A67 + offset, int(followup_stream[offset]), "actor_packet_resume_rom_data")
		if String(packet_resume.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
				or int(packet_resume.get("entry_pc", -1)) != 0x82F7 \
				or int(packet_resume.get("exit_pc", -1)) != 0xCB0F \
				or int(packet_resume.get("yield_callsite_pc", -1)) != 0x8047 \
				or int(packet_resume.get("resume_pc_after_rts", -1)) != 0x804A \
				or int(resume_callsite.get("pc", -1)) != 0x8047 \
				or int(resume_callsite.get("sp", -1)) != 0xCA \
				or int(resume_callsite.get("a", -1)) != 0x01 \
				or int(resume_callsite.get("x", -1)) != 0x06 \
				or int(resume_callsite.get("y", -1)) != 0x3A \
				or int(resume_cb0f.get("pc", -1)) != 0xCB0F \
				or int(resume_cb0f.get("sp", -1)) != 0xC8 \
				or int(resume_cb0f.get("a", -1)) != 0x01 \
				or int(resume_cb0f.get("x", -1)) != 0x06 \
				or int(resume_cb0f.get("y", -1)) != 0x3A \
				or resume_ram.size() != 0x800 \
				or resume_ram.slice(0x05E3, 0x05EB) \
					!= PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x01, 0x58]) \
				or resume_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x02]) \
				or int(resume_ram[0x0515]) != 0x80 \
				or resume_ram.slice(0x04A5, 0x04B9) != row02_header \
				or resume_ram.slice(0x04B9, 0x04C0) != followup_text \
				or not followup_reads_match \
				or int(resume_mapper.get("bank_low", -1)) != 0x18 \
				or int(resume_mapper.get("bank_high", -1)) != 0x19 \
				or int(resume_initial_mapper.get("bank_low", -1)) != 0x18 \
				or int(resume_initial_mapper.get("bank_high", -1)) != 0x19 \
				or not (packet_resume.get("ppu_bus_events", []) as Array).is_empty() \
				or not (packet_resume.get("apu_register_writes", []) as Array).is_empty() \
				or bool(packet_resume.get("ppu_apu_effects_applied", true)) \
				or bool(packet_resume.get("trace_state_used", true)) \
				or bool(packet_resume.get("source_timing_modeled", true)):
			_fail("The frame-9247 packet result differs from its ROM source profile: %s" % JSON.stringify({
				"callsite": resume_callsite, "cb0f": resume_cb0f,
				"E3_EA": resume_ram.slice(0x05E3, 0x05EB).hex_encode() if resume_ram.size() == 0x800 else "invalid",
				"F3_F5": resume_ram.slice(0x05F3, 0x05F6).hex_encode() if resume_ram.size() == 0x800 else "invalid",
				"packet": resume_ram.slice(0x04A5, 0x04C0).hex_encode() if resume_ram.size() == 0x800 else "invalid",
				"stream_reads_match": followup_reads_match,
				"mapper": resume_mapper, "initial_mapper": resume_initial_mapper,
			}))
			return
		print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X yield=$%04X resume=$%04X E3:EA=%s F3:F5=%s 04A5:04C0=%s queue=$%02X reads=%d writes=%d" % [
			int(boundary["source_frame"]), String(packet_resume.get("status", "")),
			int(packet_resume.get("entry_pc", -1)), int(packet_resume.get("exit_pc", -1)),
			int(packet_resume.get("yield_callsite_pc", -1)), int(packet_resume.get("resume_pc_after_rts", -1)),
			resume_ram.slice(0x05E3, 0x05EB).hex_encode(), resume_ram.slice(0x05F3, 0x05F6).hex_encode(),
			resume_ram.slice(0x04A5, 0x04C0).hex_encode(), int(resume_ram[0x0515]),
			resume_reads.size(), (packet_resume.get("ram_writes", []) as Array).size()])
		print("REGISTERS: callsite=%s cb0f=%s mapper=%s initial_mapper=%s" % [
			JSON.stringify(resume_callsite), JSON.stringify(resume_cb0f),
			JSON.stringify(resume_mapper), JSON.stringify(resume_initial_mapper)])
		var read_summary: Array[String] = []
		var seen_stream_reads: Dictionary = {}
		for read_variant: Variant in resume_reads:
			if read_variant is Dictionary:
				var read: Dictionary = read_variant
				var address := int(read.get("address", -1))
				if address >= 0x9A62 and address <= 0x9A6F \
						and String(read.get("kind", "")) == "actor_packet_resume_rom_data":
					seen_stream_reads[address] = int(read.get("value", -1))
		for address_variant: Variant in seen_stream_reads:
			var address := int(address_variant)
			read_summary.append("$%04X=$%02X" % [address, int(seen_stream_reads[address])])
		print("SOURCE_READS: " + ",".join(read_summary))
		quit(0)
		return
	if OS.get_environment("CT2_VERIFY_FOLLOWUP_PACKET_TERMINAL").strip_edges() == "1":
		if not executor.is_scenario1c_parameter58_followup_text_terminal_boundary(boundary):
			_fail("Frame %d is not the pinned scenario-$1C/$58 follow-up text terminal boundary." % int(boundary["source_frame"]))
			return
		var terminal: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
		if not bool(terminal.get("ok", false)):
			_fail("Frame-%d `$9A6F=$F0` text terminal failed: %s" % [
				int(boundary["source_frame"]), String(terminal.get("error", "unsupported source path"))])
			return
		var terminal_ram: PackedByteArray = terminal.get("ram_image", PackedByteArray())
		var terminal_callsite: Dictionary = terminal.get("yield_callsite_registers", {})
		var terminal_reads: Array = terminal.get("source_reads", [])
		var terminal_mapper: Dictionary = terminal.get("mapper", {})
		var terminal_initial_mapper: Dictionary = terminal.get("initial_mapper", {})
		if String(terminal.get("status", "")) != "slot11_actor_scenario1c_parameter58_followup_text_terminal_at_8047" \
				or int(terminal.get("entry_pc", -1)) != 0x804A \
				or int(terminal.get("exit_pc", -1)) != 0x8047 \
				or int(terminal.get("yield_callsite_pc", -1)) != 0x8047 \
				or int(terminal.get("yield_target_pc", -1)) != 0xCB0F \
				or int(terminal_callsite.get("pc", -1)) != 0x8047 \
				or int(terminal_callsite.get("sp", -1)) != 0xCA \
				or int(terminal_callsite.get("a", -1)) != 0x01 \
				or int(terminal_callsite.get("x", -1)) != 0x06 \
				or int(terminal_callsite.get("y", -1)) != 0x02 \
				or terminal_ram.size() != 0x800 \
				or terminal_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
				or terminal_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x00]) \
				or terminal_ram.slice(0x0063, 0x0065) != PackedByteArray([0xB0, 0xA2]) \
				or int(terminal_ram[0x0515]) != 0x00 \
				or int(terminal_ram[0x0022]) != 0x00 or int(terminal_ram[0x0629]) != 0x00 \
				or not _has_read(terminal_reads, 0x9A6F, 0xF0, "actor_stream_followup_delay") \
				or not _has_read(terminal_reads, 0x05E3, 0x01, "worker_active_flag") \
				or not _has_read(terminal_reads, 0x05E9, 0x00, "actor_animation_delay") \
				or not _has_read(terminal_reads, 0x05E5, 0x0D, "actor_stream_index") \
				or not _has_read(terminal_reads, 0x05F4, 0x01, "animation_gate_mode") \
				or not _has_read(terminal_reads, 0x05F5, 0x01, "animation_wait_counter") \
				or not _has_read(terminal_reads, 0x8098, 0xA9, "selector03_terminal_handler_rom_byte") \
				or not _has_read(terminal_reads, 0x809F, 0x60, "selector03_terminal_handler_rom_byte") \
				or int(terminal_mapper.get("bank_low", -1)) != 0x18 \
				or int(terminal_mapper.get("bank_high", -1)) != 0x19 \
				or int(terminal_initial_mapper.get("bank_low", -1)) != 0x18 \
				or int(terminal_initial_mapper.get("bank_high", -1)) != 0x19 \
				or not (terminal.get("ppu_bus_events", []) as Array).is_empty() \
				or not (terminal.get("apu_register_writes", []) as Array).is_empty() \
				or bool(terminal.get("ppu_apu_effects_applied", true)) \
				or bool(terminal.get("trace_state_used", true)) \
				or bool(terminal.get("source_timing_modeled", true)):
			_fail("The frame-%d ROM `$F0` terminal differs from its source profile: %s" % [
				int(boundary["source_frame"]), JSON.stringify({
					"status": terminal.get("status", ""), "callsite": terminal_callsite,
					"E3_EA": terminal_ram.slice(0x05E3, 0x05EB).hex_encode() if terminal_ram.size() == 0x800 else "invalid",
					"F3_F5": terminal_ram.slice(0x05F3, 0x05F6).hex_encode() if terminal_ram.size() == 0x800 else "invalid",
					"reads": terminal_reads, "mapper": terminal_mapper,
				})])
			return
		print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X callsite=%s E3:EA=%s F3:F5=%s mapper=$%02X/$%02X reads=%d" % [
			int(boundary["source_frame"]), String(terminal.get("status", "")),
			int(terminal.get("entry_pc", -1)), int(terminal.get("exit_pc", -1)),
			JSON.stringify(terminal_callsite), terminal_ram.slice(0x05E3, 0x05EB).hex_encode(),
			terminal_ram.slice(0x05F3, 0x05F6).hex_encode(),
			int(terminal_mapper.get("bank_low", -1)), int(terminal_mapper.get("bank_high", -1)),
			terminal_reads.size()])
		var terminal_read_summary: Array[String] = []
		for read_variant: Variant in terminal_reads:
			if not read_variant is Dictionary:
				continue
			var read: Dictionary = read_variant
			terminal_read_summary.append("$%04X=$%02X:%s" % [
				int(read.get("address", -1)), int(read.get("value", -1)), String(read.get("kind", ""))])
		print("SOURCE_READS: " + ",".join(terminal_read_summary))
		quit(0)
		return
	if OS.get_environment("CT2_VERIFY_FOLLOWUP_TERMINAL_INACTIVE_GATE").strip_edges() == "1":
		var inactive_gate: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
		if not bool(inactive_gate.get("ok", false)):
			_fail("Frame-%d terminal inactive `$A1EB/$A20C` gate failed: %s" % [
				int(boundary["source_frame"]), String(inactive_gate.get("error", "unsupported source path"))])
			return
		var gate_ram: PackedByteArray = inactive_gate.get("ram_image", PackedByteArray())
		var gate_callsite: Dictionary = inactive_gate.get("yield_callsite_registers", {})
		var gate_reads: Array = inactive_gate.get("source_reads", [])
		var gate_mapper: Dictionary = inactive_gate.get("mapper", {})
		if String(inactive_gate.get("status", "")) != "slot11_f5_animation_gate_at_cb0f_from_a217" \
				or int(inactive_gate.get("entry_pc", -1)) != 0x804A \
				or int(inactive_gate.get("exit_pc", -1)) != 0xCB0F \
				or int(inactive_gate.get("yield_callsite_pc", -1)) != 0xA217 \
				or int(gate_callsite.get("pc", -1)) != 0xA217 \
				or int(gate_callsite.get("sp", -1)) != 0xC6 \
				or int(gate_callsite.get("a", -1)) != 0x01 \
				or int(gate_callsite.get("x", -1)) != 0x06 \
				or int(gate_callsite.get("y", -1)) != 0x02 \
				or gate_ram.size() != 0x800 \
				or gate_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
				or gate_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x00]) \
				or gate_ram.slice(0x0063, 0x0065) != PackedByteArray([0xB0, 0xA2]) \
				or int(gate_ram[0x0515]) != 0x00 \
				or int(gate_mapper.get("bank_low", -1)) != 0x1A \
				or int(gate_mapper.get("bank_high", -1)) != 0x1B \
				or not _has_read(gate_reads, 0x05E3, 0x00, "worker_active_flag") \
				or not _has_read(gate_reads, 0x05F4, 0x01, "animation_gate_mode") \
				or not _has_read(gate_reads, 0x05F5, 0x00, "animation_wait_counter") \
				or not (inactive_gate.get("ppu_bus_events", []) as Array).is_empty() \
				or not (inactive_gate.get("apu_register_writes", []) as Array).is_empty() \
				or bool(inactive_gate.get("trace_state_used", true)) \
				or bool(inactive_gate.get("source_timing_modeled", true)):
			_fail("The frame-%d terminal inactive animation gate differs from the ROM callsite: %s" % [
				int(boundary["source_frame"]), JSON.stringify({
					"status": inactive_gate.get("status", ""), "callsite": gate_callsite,
					"E3_EA": gate_ram.slice(0x05E3, 0x05EB).hex_encode() if gate_ram.size() == 0x800 else "invalid",
					"F3_F5": gate_ram.slice(0x05F3, 0x05F6).hex_encode() if gate_ram.size() == 0x800 else "invalid",
					"mapper": gate_mapper, "reads": gate_reads,
				})])
			return
		print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X yield=$%04X callsite=%s E3:EA=%s F3:F5=%s mapper=$%02X/$%02X reads=%d" % [
			int(boundary["source_frame"]), String(inactive_gate.get("status", "")),
			int(inactive_gate.get("entry_pc", -1)), int(inactive_gate.get("exit_pc", -1)),
			int(inactive_gate.get("yield_callsite_pc", -1)), JSON.stringify(gate_callsite),
			gate_ram.slice(0x05E3, 0x05EB).hex_encode(), gate_ram.slice(0x05F3, 0x05F6).hex_encode(),
			int(gate_mapper.get("bank_low", -1)), int(gate_mapper.get("bank_high", -1)), gate_reads.size()])
		quit(0)
		return
	if OS.get_environment("CT2_VERIFY_FOLLOWUP_TERMINAL_ANIMATION_COUNTDOWN").strip_edges() == "1":
		var countdown: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
		if not bool(countdown.get("ok", false)):
			_fail("Frame-%d terminal animation countdown failed: %s" % [
				int(boundary["source_frame"]), String(countdown.get("error", "unsupported source path"))])
			return
		var countdown_ram: PackedByteArray = countdown.get("ram_image", PackedByteArray())
		var countdown_callsite: Dictionary = countdown.get("yield_callsite_registers", {})
		var countdown_reads: Array = countdown.get("source_reads", [])
		var countdown_mapper: Dictionary = countdown.get("mapper", {})
		var countdown_initial_mapper: Dictionary = countdown.get("initial_mapper", {})
		if int(boundary.get("source_frame", -1)) != 9252 \
				or String(countdown.get("status", "")) != "slot11_actor_scenario1c_parameter58_terminal_animation_countdown_at_8047" \
				or int(countdown.get("entry_pc", -1)) != 0x804A \
				or int(countdown.get("exit_pc", -1)) != 0x8047 \
				or int(countdown.get("yield_callsite_pc", -1)) != 0x8047 \
				or int(countdown.get("yield_target_pc", -1)) != 0xCB0F \
				or int(countdown_callsite.get("pc", -1)) != 0x8047 \
				or int(countdown_callsite.get("sp", -1)) != 0xCA \
				or int(countdown_callsite.get("a", -1)) != 0x01 \
				or int(countdown_callsite.get("x", -1)) != 0x04 \
				or int(countdown_callsite.get("y", -1)) != 0x04 \
				or countdown_ram.size() != 0x800 \
				or countdown_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
				or countdown_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x04]) \
				or countdown_ram.slice(0x0063, 0x0065) != PackedByteArray([0xB2, 0xA2]) \
				or int(countdown_ram[0x0515]) != 0x00 \
				or int(countdown_ram[0x0022]) != 0x00 or int(countdown_ram[0x0629]) != 0x00 \
				or not _has_read(countdown_reads, 0x05E3, 0x00, "worker_active_flag") \
				or not _has_read(countdown_reads, 0x05F4, 0x01, "animation_gate_mode") \
				or not _has_read(countdown_reads, 0x05F5, 0x05, "animation_wait_counter") \
				or int(countdown_mapper.get("bank_low", -1)) != 0x18 \
				or int(countdown_mapper.get("bank_high", -1)) != 0x19 \
				or int(countdown_initial_mapper.get("bank_low", -1)) != 0x18 \
				or int(countdown_initial_mapper.get("bank_high", -1)) != 0x19 \
				or not (countdown.get("ppu_bus_events", []) as Array).is_empty() \
				or not (countdown.get("apu_register_writes", []) as Array).is_empty() \
				or bool(countdown.get("ppu_apu_effects_applied", true)) \
				or bool(countdown.get("trace_state_used", true)) \
				or bool(countdown.get("source_timing_modeled", true)):
			_fail("The frame-9252 ROM animation countdown differs from its source profile: %s" % JSON.stringify({
				"status": countdown.get("status", ""), "callsite": countdown_callsite,
				"E3_EA": countdown_ram.slice(0x05E3, 0x05EB).hex_encode() if countdown_ram.size() == 0x800 else "invalid",
				"F3_F5": countdown_ram.slice(0x05F3, 0x05F6).hex_encode() if countdown_ram.size() == 0x800 else "invalid",
				"reads": countdown_reads, "mapper": countdown_mapper,
			}))
			return
		print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X yield=$%04X callsite=%s E3:EA=%s F3:F5=%s mapper=$%02X/$%02X reads=%d" % [
			int(boundary["source_frame"]), String(countdown.get("status", "")),
			int(countdown.get("entry_pc", -1)), int(countdown.get("exit_pc", -1)),
			int(countdown.get("yield_callsite_pc", -1)), JSON.stringify(countdown_callsite),
			countdown_ram.slice(0x05E3, 0x05EB).hex_encode(), countdown_ram.slice(0x05F3, 0x05F6).hex_encode(),
			int(countdown_mapper.get("bank_low", -1)), int(countdown_mapper.get("bank_high", -1)), countdown_reads.size()])
		quit(0)
		return
	if OS.get_environment("CT2_VERIFY_FOLLOWUP_PACKET_DELAY_TICK").strip_edges() == "1":
		if not executor.is_scenario1c_parameter58_followup_post_packet_delay_boundary(boundary):
			_fail("Frame %d is not the pinned scenario-$1C/$58 follow-up packet countdown boundary." % int(boundary["source_frame"]))
			return
		var delay_result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
		if not bool(delay_result.get("ok", false)):
			_fail("Frame-%d `$804A` follow-up packet countdown failed: %s" % [
				int(boundary["source_frame"]), String(delay_result.get("error", "unsupported source path"))])
			return
		var delay_ram: PackedByteArray = delay_result.get("ram_image", PackedByteArray())
		var delay_callsite: Dictionary = delay_result.get("yield_callsite_registers", {})
		var delay_reads: Array = delay_result.get("source_reads", [])
		var delay_mapper: Dictionary = delay_result.get("mapper", {})
		var delay_initial_mapper: Dictionary = delay_result.get("initial_mapper", {})
		var counter_write_found := false
		for write_variant: Variant in delay_result.get("ram_writes", []):
			if write_variant is Dictionary:
				var write: Dictionary = write_variant
				if int(write.get("address", -1)) == 0x05F5 \
						and int(write.get("value", -1)) == 0x01 \
						and int(write.get("pc", -1)) == 0xA211:
					counter_write_found = true
		if String(delay_result.get("status", "")) != "slot11_actor_scenario1c_parameter58_followup_post_packet_delay_at_8047" \
				or int(delay_result.get("entry_pc", -1)) != 0x804A \
				or int(delay_result.get("exit_pc", -1)) != 0x8047 \
				or delay_ram.size() != 0x800 \
				or delay_ram.slice(0x05E3, 0x05EB) \
					!= PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
				or delay_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x01]) \
				or int(delay_ram[0x0515]) != 0x00 or not counter_write_found \
				or int(delay_mapper.get("bank_low", -1)) != 0x18 \
				or int(delay_mapper.get("bank_high", -1)) != 0x19 \
				or int(delay_initial_mapper.get("bank_low", -1)) != 0x18 \
				or int(delay_initial_mapper.get("bank_high", -1)) != 0x19 \
				or not (delay_result.get("ppu_bus_events", []) as Array).is_empty() \
				or not (delay_result.get("apu_register_writes", []) as Array).is_empty() \
				or bool(delay_result.get("ppu_apu_effects_applied", true)) \
				or bool(delay_result.get("trace_state_used", true)) \
				or bool(delay_result.get("source_timing_modeled", true)):
			_fail("The frame-9248 countdown differs from its ROM source profile: %s" % JSON.stringify({
				"status": delay_result.get("status", ""), "entry_pc": delay_result.get("entry_pc", -1),
				"exit_pc": delay_result.get("exit_pc", -1),
				"E3_EA": delay_ram.slice(0x05E3, 0x05EB).hex_encode() if delay_ram.size() == 0x800 else "invalid",
				"F3_F5": delay_ram.slice(0x05F3, 0x05F6).hex_encode() if delay_ram.size() == 0x800 else "invalid",
				"counter_write_found": counter_write_found, "callsite": delay_callsite,
				"mapper": delay_mapper, "initial_mapper": delay_initial_mapper,
			}))
			return
		print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X E3:EA=%s F3:F5=%s counter_write=%s mapper=$%02X/$%02X reads=%d" % [
			int(boundary["source_frame"]), String(delay_result.get("status", "")),
			int(delay_result.get("entry_pc", -1)), int(delay_result.get("exit_pc", -1)),
			delay_ram.slice(0x05E3, 0x05EB).hex_encode(), delay_ram.slice(0x05F3, 0x05F6).hex_encode(),
			str(counter_write_found), int(delay_mapper.get("bank_low", -1)), int(delay_mapper.get("bank_high", -1)),
			delay_reads.size()])
		print("CALLSITE: " + JSON.stringify(delay_callsite))
		quit(0)
		return
	if OS.get_environment("CT2_VERIFY_FOLLOWUP_PACKET_WAIT").strip_edges() == "1":
		if not executor.is_scenario1c_parameter58_followup_packet_wait_boundary(boundary):
			_fail("Frame %d is not the pinned scenario-$1C/$58 follow-up packet-wait boundary." % int(boundary["source_frame"]))
			return
		var yielded_boundary := boundary.duplicate(true)
		yielded_boundary["pc"] = 0xCB0F
		yielded_boundary["sp"] = 0xC6
		yielded_boundary["a"] = 0x01
		if not executor.is_scenario1c_parameter58_followup_packet_wait_boundary(yielded_boundary):
			_fail("The yielded `$CB0F` frame-9246 packet-wait signature is not recognized before scheduler dispatch.")
			return
		var packet_wait: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
		var packet_ram: PackedByteArray = packet_wait.get("ram_image", PackedByteArray())
		var packet_stack: PackedByteArray = packet_wait.get("stack_page", PackedByteArray())
		var packet_callsite: Dictionary = packet_wait.get("yield_callsite_registers", {})
		var packet_reads: Array = packet_wait.get("source_reads", [])
		if not bool(packet_wait.get("ok", false)) \
				or String(packet_wait.get("status", "")) != "slot11_actor_packet_wait_at_cb0f" \
				or int(packet_wait.get("entry_pc", -1)) != 0x804A \
				or int(packet_wait.get("exit_pc", -1)) != 0xCB0F \
				or int(packet_wait.get("yield_callsite_pc", -1)) != 0x82F4 \
				or int(packet_wait.get("yield_target_pc", -1)) != 0xCB0F \
				or int(packet_wait.get("resume_pc_after_rts", -1)) != 0x82F7 \
				or int(packet_callsite.get("a", -1)) != 0x01 \
				or int(packet_callsite.get("x", -1)) != 0x05 \
				or int(packet_callsite.get("y", -1)) != 0x06 \
				or packet_ram.size() != 0x800 \
				or packet_stack.size() != 0x100 \
				or packet_stack.slice(0xC7, 0xC9) != PackedByteArray([0xF6, 0x82]) \
				or int(packet_ram[0x0515]) != 0 \
				or not _has_read(packet_reads, 0x82F2, 0xA9, "actor_packet_wait_rom_byte") \
				or not _has_read(packet_reads, 0x82F6, 0xC5, "actor_packet_wait_rom_byte") \
				or not _has_read(packet_reads, 0xC515, 0x4C, "task_yield_dispatch_opcode") \
				or not (packet_wait.get("ppu_bus_events", []) as Array).is_empty() \
				or not (packet_wait.get("apu_register_writes", []) as Array).is_empty() \
				or bool(packet_wait.get("trace_state_used", true)) \
				or bool(packet_wait.get("source_timing_modeled", true)):
			_fail("The frame-%d ROM `$82F2->$82F4->$CB0F` packet-wait result differs from its source contract: %s" % [
				int(boundary["source_frame"]), JSON.stringify({
					"status": packet_wait.get("status", ""), "callsite": packet_callsite,
					"exit_pc": packet_wait.get("exit_pc", -1),
					"reads": packet_reads, "stack_c7_cb": packet_stack.slice(0xC7, 0xCB).hex_encode() if packet_stack.size() == 0x100 else "invalid",
				})])
			return
		print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X yield=$%04X resume=$%04X callsite=%s E3:EA=%s F3:F5=%s stack[C7:CB]=%s reads=%d" % [
			int(boundary["source_frame"]), String(packet_wait.get("status", "")),
			int(packet_wait.get("entry_pc", -1)), int(packet_wait.get("exit_pc", -1)),
			int(packet_wait.get("yield_callsite_pc", -1)), int(packet_wait.get("resume_pc_after_rts", -1)),
			JSON.stringify(packet_callsite), packet_ram.slice(0x05E3, 0x05EB).hex_encode(),
			packet_ram.slice(0x05F3, 0x05F6).hex_encode(), packet_stack.slice(0xC7, 0xCB).hex_encode(),
			packet_reads.size()])
		quit(0)
		return
	if not executor.is_scenario1c_parameter58_delay_boundary(boundary):
		_fail("Frame %d is not the pinned scenario-$1C/$58 post-packet boundary." % int(boundary["source_frame"]))
		return
	if OS.get_environment("CT2_VERIFY_YIELDED_PROFILE").strip_edges() == "1":
		var yielded_boundary := boundary.duplicate(true)
		yielded_boundary["pc"] = 0xCB0F
		yielded_boundary["sp"] = 0xC6
		yielded_boundary["a"] = 0x01
		if not executor.is_scenario1c_parameter58_post_packet_delay_boundary(yielded_boundary):
			_fail("The observed `$CB0F` pre-dispatch scenario-$58 yield variant is not recognized.")
			return
		print("PASS: the pinned frame-9245 signature accepts its `$CB0F` yielded variant.")
		quit(0)
	var result: Dictionary = executor.execute_from_slot11_animation_countdown_boundary(boundary)
	if not bool(result.get("ok", false)):
		_fail("ROM worker rejected frame %d: %s" % [
			int(boundary["source_frame"]), String(result.get("error", "unsupported source path"))])
		return
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var callsite: Dictionary = result.get("yield_callsite_registers", {})
	var source_reads: Array = result.get("source_reads", [])
	if String(result.get("status", "")) != "slot11_actor_scenario1c_parameter58_post_packet_delay_at_8047" \
			or int(result.get("entry_pc", -1)) != 0x804A \
			or int(result.get("exit_pc", -1)) != 0x8047 \
			or int(result.get("yield_callsite_pc", -1)) != 0x8047 \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(callsite.get("a", -1)) != 0x01 \
			or int(callsite.get("x", -1)) != 0x05 \
			or int(callsite.get("y", -1)) != 0x04 \
			or output_ram.size() != 0x800 \
			or output_ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			or output_ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x01, 0x03]) \
			or output_ram.slice(0x0063, 0x0065) != PackedByteArray([0xB0, 0xA2]) \
			or int(output_ram[0x0515]) != 0 \
			or output_stack.size() != 0x100 \
			or output_stack.slice(0xC7, 0xCB) != PackedByteArray([0x83, 0xCF, 0x4F, 0x80]) \
			or int(output_ram[0x0022]) != 0 or int(output_ram[0x0629]) != 0 \
			or not _has_read(source_reads, 0x05E3, 0x01, "worker_active_flag") \
			or not _has_read(source_reads, 0x05E9, 0x01, "actor_animation_delay") \
			or not _has_read(source_reads, 0x05F4, 0x01, "animation_gate_mode") \
			or not _has_read(source_reads, 0x05F5, 0x04, "animation_wait_counter") \
			or not (result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (result.get("apu_register_writes", []) as Array).is_empty() \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("source_timing_modeled", true)):
		_fail("The ROM-backed post-packet delay result differs from the pinned `$804A->$8047` output: " + JSON.stringify({
			"status": result.get("status", ""), "callsite": callsite,
			"E3_EA": output_ram.slice(0x05E3, 0x05EB).hex_encode(),
			"F3_F5": output_ram.slice(0x05F3, 0x05F6).hex_encode(),
			"source_reads": source_reads,
	}))
		return
	print("RESULT: frame=%d status=%s entry=$%04X exit=$%04X yield=$%04X callsite=%s E3:EA=%s F3:F5=%s animation=$%04X queue=$%02X reads=%d writes=%d" % [
		int(boundary["source_frame"]), String(result.get("status", "")),
		int(result.get("entry_pc", -1)), int(result.get("exit_pc", -1)),
		int(result.get("yield_callsite_pc", -1)), JSON.stringify(callsite),
		output_ram.slice(0x05E3, 0x05EB).hex_encode(),
		output_ram.slice(0x05F3, 0x05F6).hex_encode(),
		int(output_ram[0x0063]) | (int(output_ram[0x0064]) << 8),
		int(output_ram[0x0515]), source_reads.size(),
		(result.get("ram_writes", []) as Array).size()])
	var read_summary: Array[String] = []
	for read_variant: Variant in source_reads:
		if not read_variant is Dictionary:
			continue
		var read: Dictionary = read_variant
		read_summary.append("$%04X=$%02X:%s" % [
			int(read.get("address", -1)), int(read.get("value", -1)), String(read.get("kind", ""))])
	print("SOURCE_READS: " + ",".join(read_summary))
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _has_read(reads: Array, address: int, value: int, kind: String) -> bool:
	for item: Variant in reads:
		if item is Dictionary and int(item.get("address", -1)) == address \
				and int(item.get("value", -1)) == value and String(item.get("kind", "")) == kind:
			return true
	return false
