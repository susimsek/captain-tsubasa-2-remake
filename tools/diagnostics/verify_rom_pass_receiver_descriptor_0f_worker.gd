extends SceneTree
## Verifies a source-executed descriptor-$0F worker prefix and its bounded
## `$8889` continuation. The yielded-RTS restore is an explicit synthetic
## fixture; this does not prove live scheduler/NMI integration or `$D7F2` return.

const WORKER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var worker = WORKER_SCRIPT.new()
	if not worker.configure_from_project_sources():
		_fail("PASS descriptor-$0F worker sources failed provenance checks: " + worker.error_message)
		return
	var boundary := _make_scheduler_boundary_fixture()
	var matching_selector: Dictionary = worker.call("_validate_pass_receiver_boundary", boundary)
	if not bool(matching_selector.get("ok", false)):
		_fail("A scenario-$38 mapper selector matching RAM `$0022=$00` must be accepted: " \
			+ JSON.stringify(matching_selector.get("mismatches", [])))
		return
	var bad_selector_boundary: Dictionary = boundary.duplicate(true)
	var bad_selector_mapper: Dictionary = (bad_selector_boundary.get("mapper", {}) as Dictionary).duplicate(true)
	bad_selector_mapper["select"] = 0x07
	bad_selector_mapper["register_select"] = 0x07
	bad_selector_boundary["mapper"] = bad_selector_mapper
	var selector_rejection: Dictionary = worker.call("_validate_pass_receiver_boundary",
		bad_selector_boundary)
	var selector_mismatches: Array = selector_rejection.get("mismatches", [])
	if bool(selector_rejection.get("ok", false)) or selector_mismatches.size() != 2 \
			or selector_mismatches[0].get("field", "") != "mapper.register_select" \
			or selector_mismatches[0].get("expected", "") != "$00 from RAM[$0022]" \
			or selector_mismatches[0].get("actual", "") != "$07" \
			or selector_mismatches[1].get("field", "") != "mapper.select":
		_fail("A mapper selector inconsistent with live RAM `$0022=$00` must be rejected precisely.")
		return
	var bad_boundary: Dictionary = boundary.duplicate(true)
	bad_boundary["pc"] = 0xD7EE
	var rejection: Dictionary = worker.call("_validate_pass_receiver_boundary", bad_boundary)
	var mismatches: Array = rejection.get("mismatches", [])
	if bool(rejection.get("ok", false)) or mismatches.size() != 1 \
			or mismatches[0].get("field", "") != "pc" \
			or mismatches[0].get("expected", "") != "$D7ED" \
			or mismatches[0].get("actual", "") != "$D7EE":
		_fail("A single bad `$D7ED` PC must report only its expected and actual values.")
		return
	var first_yield: Dictionary = worker.execute_pass_receiver_descriptor_0f_first_yield(boundary)
	if not bool(first_yield.get("ok", false)):
		_fail("6502 source execution failed before its bounded `$C515` boundary: "
			+ String(first_yield.get("error", "unknown")))
		return
	if not _first_yield_matches(first_yield):
		_fail("First-yield PC/register/mapper/descriptor signature did not match the pinned source contract.")
		return
	var resume_fixture := _make_scheduler_restore_fixture(first_yield)
	var packet_result: Dictionary = worker.execute_pass_receiver_descriptor_0f_first_packet(
		first_yield, resume_fixture)
	if not bool(packet_result.get("ok", false)):
		_fail("Bounded `$8889` source continuation failed: " + String(packet_result.get("error", "unknown")))
		return
	if String(packet_result.get("status", "")) != "pass_receiver_descriptor_0f_packet_batch_staged" \
			or String(packet_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(packet_result.get("source_manifest_sha256", "")).is_empty() \
			or String(packet_result.get("input_boundary_kind", "")) != "synthetic_test_fixture" \
			or not bool(packet_result.get("input_boundary_fixture", false)) \
			or bool(packet_result.get("route_boundary_observed", true)) \
			or int(packet_result.get("worker_entry_pc", -1)) != 0x8889 \
			or int(packet_result.get("worker_exit_pc", -1)) != 0xC515 \
			or int(packet_result.get("worker_exit_bank", -1)) != 0x1E \
			or int(packet_result.get("descriptor_pointer", -1)) != 0xB58D \
			or not bool(packet_result.get("descriptor_header_executed", false)) \
			or not bool(packet_result.get("descriptor_row00_executed", false)) \
			or bool(packet_result.get("descriptor_row01_executed", true)) \
			or int(packet_result.get("packet_count", -1)) != 2 \
			or not bool(packet_result.get("packet_queue_staged", false)) \
			or int(packet_result.get("queue_control_0515", -1)) != 0x80 \
			or bool(packet_result.get("nmi_executed", true)) \
			or bool(packet_result.get("nmi_queue_consumed", true)) \
			or bool(packet_result.get("ppu_packet_applied", true)) \
			or bool(packet_result.get("apu_writes_executed", true)) \
			or bool(packet_result.get("renderer_returned", true)) \
			or bool(packet_result.get("returned_to_D7F2", true)) \
			or bool(packet_result.get("runtime_integrated", true)):
		_fail("Packet boundary provenance, execution endpoint, or explicit limitation flags are inconsistent.")
		return
	var packets: Array = packet_result.get("packets", [])
	if packets.size() != 2 \
			or not _packet_matches(packets[0], 0x04A5, 0x2228, _zero_payload()) \
			or not _packet_matches(packets[1], 0x04C0, 0x2248, _window_payload()):
		_fail("ROM-produced RAM packet records did not match the two pinned window writes.")
		return
	var spans: Array[String] = []
	for span_variant in packet_result.get("executed_source_spans", []):
		if span_variant is Dictionary:
			spans.append(String((span_variant as Dictionary).get("file", "")))
	for required_span in [
		"bank18_worker_resume_8889_89D7.bin",
		"bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin",
		"bank19_pass_receiver_row00_BBED_BBEE.bin",
		"bank18_window_3x3_tile_ids_8D9E_8DA7.bin",
	]:
		if not spans.has(required_span):
			_fail("Executed source-span log omitted %s." % required_span)
			return
	if spans.has("bank19_pass_receiver_row01_BBF4_BBFB.bin"):
		_fail("The bounded continuation unexpectedly claims row `$BBF4` was fetched.")
		return
	var wrong_pc := resume_fixture.duplicate(true)
	(wrong_pc["registers"] as Dictionary)["pc"] = 0x888A
	var rejected: Dictionary = worker.execute_pass_receiver_descriptor_0f_first_packet(
		first_yield, wrong_pc)
	if bool(rejected.get("ok", true)) or String(rejected.get("status", "")) != "invalid_yielded_rts_boundary":
		_fail("The bounded continuation accepted a wrong-PC restore signature.")
		return
	print("PASS: ROM-byte worker execution reached `$C515`, then a clearly synthetic yielded-RTS restore executed the `$8889` continuation to its next `$C515` yield.")
	print("PASS: Descriptor `$B58D` and blank row `$BBED` were fetched; two 24-byte RAM records stage writes at `$2228` and `$2248`; row `$BBF4` was not fetched.")
	print("LIMIT: Scheduler/NMI cadence, queue consumption, PPU application, audio, renderer return, and `$D7F2` remain unverified; fixture is not route integration.")
	quit(0)


func _first_yield_matches(result: Dictionary) -> bool:
	var registers: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var descriptor: Dictionary = result.get("descriptor_source", {})
	return String(result.get("status", "")) == "pass_receiver_descriptor_0f_first_yield" \
		and String(result.get("rom_sha256", "")) == ROM_SHA256 \
		and not String(result.get("source_manifest_sha256", "")).is_empty() \
		and int(result.get("exit_pc", -1)) == 0xC515 \
		and int(registers.get("a", -1)) == 0x01 \
		and int(registers.get("x", -1)) == 0xFF \
		and int(registers.get("y", -1)) == 0x03 \
		and int(registers.get("sp", -1)) == 0x38 \
		and int(registers.get("pc", -1)) == 0xC515 \
		and int(mapper.get("bank_low", -1)) == 0x18 \
		and int(mapper.get("bank_high", -1)) == 0x19 \
		and int(mapper.get("select", -1)) == 0x07 \
		and ram.size() == 0x800 and stack.size() == 0x100 \
		and ram.slice(0x0100, 0x0200) == stack \
		and int(ram[0x0050]) == 0x8D and int(ram[0x0051]) == 0xB5 \
		and int(stack[0x39]) == 0x88 and int(stack[0x3A]) == 0x88 \
		and int(descriptor.get("descriptor_id", -1)) == 0x0F \
		and int(descriptor.get("descriptor_pointer", -1)) == 0xB58D \
		and bool(descriptor.get("pointer_read_by_source", false)) \
		and bool(result.get("input_boundary_fixture", false)) \
		and not bool(result.get("route_boundary_observed", true)) \
		and not bool(result.get("trace_state_used", true))


func _packet_matches(packet_variant: Variant, ram_offset: int, ppu_address: int,
		payload: PackedByteArray) -> bool:
	if not packet_variant is Dictionary:
		return false
	var packet: Dictionary = packet_variant
	return int(packet.get("ram_offset", -1)) == ram_offset \
		and int(packet.get("payload_size", -1)) == payload.size() \
		and int(packet.get("ppu_address", -1)) == ppu_address \
		and String(packet.get("payload_hex", "")).hex_decode() == payload


func _zero_payload() -> PackedByteArray:
	var payload := PackedByteArray()
	payload.resize(24)
	return payload


func _window_payload() -> PackedByteArray:
	var payload := PackedByteArray([0x9C])
	for _index in range(8):
		payload.append(0xA8)
	payload.append(0x9D)
	while payload.size() < 24:
		payload.append(0x00)
	return payload


func _make_scheduler_restore_fixture(first_yield: Dictionary) -> Dictionary:
	var ram: PackedByteArray = (first_yield["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (first_yield["stack_page"] as PackedByteArray).duplicate()
	var first_registers: Dictionary = first_yield["registers"]
	var first_mapper: Dictionary = first_yield["mapper"]
	var yield_sp := int(first_registers["sp"])
	# These bytes model a scheduler-restored yielded RTS boundary for this test
	# only. No NMI interval or live scheduler dispatch is asserted.
	stack[yield_sp] = int(first_registers["x"])
	stack[(yield_sp - 1) & 0xFF] = int(first_registers["y"])
	ram[0x0100 + yield_sp] = int(first_registers["x"])
	ram[0x0100 + ((yield_sp - 1) & 0xFF)] = int(first_registers["y"])
	ram[0x007F] = int(first_registers["a"])
	ram[0x0005] = 0x00
	ram[0x0006] = (yield_sp - 2) & 0xFF
	ram[0x0007] = int(first_mapper["bank_low"])
	ram[0x0008] = int(first_mapper["bank_high"])
	return {
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": 0x05,
			"resume_path": "yielded_rts", "pc": 0x8889, "bank": 0x18,
			"source_dispatch_observed": true},
		"registers": {"a": int(first_registers["x"]), "x": int(first_registers["x"]),
			"y": int(first_registers["y"]), "sp": (yield_sp + 2) & 0xFF, "pc": 0x8889},
		"mapper": {"bank_low": int(first_mapper["bank_low"]),
			"bank_high": int(first_mapper["bank_high"]), "select": int(first_mapper["select"])},
		"ram_image": ram,
		"stack_page": stack,
		"test_fixture": true,
		"fixture_label": "synthetic yielded-task restore from ROM-byte `$8886->$C515`; NMI cadence not modeled",
	}


func _make_scheduler_boundary_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0x41] = 0x34
	stack[0x42] = 0xD6
	ram[0x0100 + 0x41] = 0x34
	ram[0x0100 + 0x42] = 0xD6
	ram[0x0000] = 0x05
	ram[0x0007] = 0x18
	ram[0x0008] = 0x19
	ram[0x0441] = 0x06
	ram[0x0518] = 0x38
	return {
		"rom_sha256": ROM_SHA256, "slot_base": 0x05, "active_task_slot": 0x05,
		"phase": 2, "pc": 0xD7ED, "sp": 0x40, "a": 0x00, "x": 0x00, "y": 0x00,
		"p": 0x20, "p_known_mask": 0xFF, "bank_low": 0x1A, "bank_high": 0x1B,
		"executing_cpu_bank": 0x1E,
		"mapper": {"bank_low": 0x1A, "bank_high": 0x1B,
			"select": int(ram[0x0022]) & 0x07, "register_select": int(ram[0x0022]) & 0x07},
		"mapper_proof": {"banks_at_fixed_dispatch": [0x1C, 0x1D], "fixed_bank": 0x1E},
		"ram_image": ram, "stack_page": stack, "trace_state_used": false,
		"test_fixture": true,
		"fixture_label": "synthetic D7ED scheduler-return fixture; not a route result",
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
