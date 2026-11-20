extends SceneTree

const EXECUTOR_PATH := "res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd"
const CBF1_EXECUTOR_PATH := "res://scripts/gameplay/rom_slot09_cbf1_sound_queue_executor.gd"
const SERVICE_BYTES_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/fixed_raster_nmi_service_C421_C472.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor_script: Script = load(EXECUTOR_PATH)
	if executor_script == null:
		_fail("Could not load the special-NMI executor script.")
		return
	var executor: RefCounted = executor_script.new()
	if not bool(executor.configure_from_project_sources()):
		_fail("ROM source manifest/hash validation failed: " + String(executor.error_message))
		return
	var status: Dictionary = executor.get_status()
	if String(status.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or not bool(status.get("executes_special_nmi_through_sound_driver_first_queue_scan", false)) \
			or int(status.get("sound_driver_entry_pc", -1)) != 0x8000 \
			or int(status.get("sound_driver_prefix_end_pc", -1)) != 0x8061 \
			or not bool(status.get("can_resume_stop_id_one_queue_clear", false)) \
			or int(status.get("stop_id_one_queue_clear_end_pc", -1)) != 0x8350 \
			or bool(status.get("stop_id_one_queue_clear_completes_sound_driver", true)) \
			or int(status.get("empty_slot_second_pass_end_pc", -1)) != 0x80CA \
			or not bool(status.get("can_resume_empty_sound_slots_to_queue_head", false)) \
			or not bool(status.get("executes_zero_mask_sound_driver_to_caller_return", false)) \
			or not bool(status.get("executes_sound_driver_rts", false)) \
			or not bool(status.get("executes_special_nmi_rti", false)) \
			or bool(status.get("advances_live_route", true)):
		_fail("Executor status does not describe the hash-bound, non-route boundary.")
		return
	var service_bytes := FileAccess.get_file_as_bytes(SERVICE_BYTES_PATH)
	if service_bytes.size() != 82 \
			or service_bytes.slice(0x19, 0x1C) != PackedByteArray([0x20, 0x00, 0xA0]) \
			or service_bytes.slice(0x28, 0x2B) != PackedByteArray([0x20, 0x00, 0x80]):
		_fail("C421 source bytes do not contain the expected `$A000` and banked `$8000` calls.")
		return
	var ram := PackedByteArray()
	ram.resize(0x800)
	# Explicit bounded source-state fixture exercises all four bank-range paths.
	# This is a verifier input, not a captured or route-produced game state.
	ram[0x0700] = 0x58
	ram[0x0701] = 0x3F
	ram[0x0702] = 0x48
	ram[0x0703] = 0x5C
	ram[0x0704] = 0x31
	ram[0x0705] = 0x01
	ram[0x07FC] = 0x0C
	var stack := PackedByteArray()
	stack.resize(0x100)
	# JSR $8000 at $C449 pushes return-minus-one $C44B at SP=$EE.
	stack[0xEF] = 0x4B
	stack[0xF0] = 0xC4
	var cpu := {"pc": 0x8000, "a": 0x0C, "x": 0x00, "y": 0x00, "p": 0x24}
	var mapper := {"registers": [0, 0, 0, 0, 0, 0, 0x0C, 0x0C],
		"command": 0x06, "prg_mode": false, "chr_inversion": false,
		"8000_prg_bank": 0x0C, "a000_prg_bank": 0x0C}
	var prefix: Dictionary = executor.call("_execute_sound_driver_first_pass",
		ram, stack, 0xEE, cpu, mapper)
	if not bool(prefix.get("ok", false)):
		_fail("Sound-driver first-pass fixture failed: " + String(prefix.get("error", "unknown error")))
		return
	var prefix_cpu: Dictionary = prefix["cpu"]
	var prefix_mapper: Dictionary = prefix["mapper"]
	var prefix_registers: Array = prefix_mapper["registers"]
	var scanned_slots := 0
	for pc: int in prefix["source_path"]:
		if pc == 0x8002:
			scanned_slots += 1
	if String(prefix.get("status", "")) != "stopped_before_second_sound_driver_pass" \
			or int(prefix_cpu.get("pc", -1)) != 0x8061 \
			or int(prefix_cpu.get("x", -1)) != 0xFF \
			or int(prefix_cpu.get("y", -1)) != 0x0F \
			or scanned_slots != 6 \
			or int(prefix["sp"]) != 0xEE \
			or int(prefix["stack_page"][0xEF]) != 0x4B \
			or int(prefix["stack_page"][0xF0]) != 0xC4 \
			or int(prefix["ram"][0x07FC]) != 0x0F \
			or int(prefix_registers[6]) != 0x0C \
			or int(prefix_registers[7]) != 0x0F \
			or int(prefix_mapper.get("8000_prg_bank", -1)) != 0x0C \
			or int(prefix_mapper.get("a000_prg_bank", -1)) != 0x0F \
			or prefix["ram_writes"].size() != 3 \
			or prefix["mapper_bus_writes"].size() != 12 \
			or bool(prefix.get("apu_state_required_for_this_prefix", true)):
		_fail("Sound-driver prefix state mismatch: pc=%04X x=%02X y=%02X slots=%d sp=%02X saved=%02X r6/r7=%02X/%02X map=%02X/%02X RAM-writes=%d MMC3-writes=%d APU-independent=%s." % [
			int(prefix_cpu.get("pc", -1)), int(prefix_cpu.get("x", -1)), int(prefix_cpu.get("y", -1)),
			scanned_slots, int(prefix["sp"]), int(prefix["ram"][0x07FC]),
			int(prefix_registers[6]), int(prefix_registers[7]),
			int(prefix_mapper.get("8000_prg_bank", -1)), int(prefix_mapper.get("a000_prg_bank", -1)),
			prefix["ram_writes"].size(), prefix["mapper_bus_writes"].size(),
			str(not bool(prefix.get("apu_state_required_for_this_prefix", true)))])
		return
	var nmi_ram := PackedByteArray()
	nmi_ram.resize(0x800)
	nmi_ram[0x001B] = 0x40
	nmi_ram[0x003B] = 0x55
	nmi_ram[0x001C] = 0x00
	nmi_ram[0x001D] = 0x00
	nmi_ram[0x0020] = 0x88
	nmi_ram[0x0021] = 0x1E
	nmi_ram[0x0022] = 0x00
	nmi_ram[0x0023] = 0x06
	nmi_ram[0x0024] = 0x00
	nmi_ram[0x0025] = 0x02
	nmi_ram[0x0079] = 0x40
	nmi_ram[0x0700] = 0x58
	nmi_ram[0x0701] = 0x3F
	nmi_ram[0x0702] = 0x48
	nmi_ram[0x0703] = 0x5C
	nmi_ram[0x0704] = 0x31
	nmi_ram[0x0705] = 0x01
	nmi_ram[0x07FC] = 0x0C
	var nmi_stack := PackedByteArray()
	nmi_stack.resize(0x100)
	var nmi_sp := 0xE0
	nmi_stack[nmi_sp + 1] = 0x22
	nmi_stack[nmi_sp + 2] = 0x3B
	nmi_stack[nmi_sp + 3] = 0x89
	var nmi_context := {
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"provenance": {
			"kind": "rom_source_execution",
			"source_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
			"input_route_sha256": "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
			"trace_state_used": false,
			"emulator_data_used": false,
			"candidate_state_used": false,
			"fixture_only": true,
		},
		"source_event": {"kind": "NMI", "source_event_id": "fixture_nmi_at_893b",
			"entry_pc": 0xC421, "vector_pc": 0xC500, "dispatch_pc": 0xC76E},
		"nmi_frame": {"interrupted_p": 0x22, "interrupted_pc": 0x893B},
		"cpu": {"pc": 0xC421, "a": 0x1F, "x": 0x00, "y": 0x00,
			"p": 0xE6, "sp": nmi_sp},
		"ram": nmi_ram,
		"stack_page": nmi_stack,
		"mapper": {"registers": [0x00, 0x02, 0x04, 0x05, 0x06, 0x07, 0x00, 0x02],
			"command": 0x06, "prg_mode": false, "chr_inversion": false,
			"8000_prg_bank": 0x00, "a000_prg_bank": 0x02},
		"ppu": {"ctrl_shadow": 0x88, "mask_shadow": 0x1E},
		"controller_inputs": {"port1_buttons": 0x00, "port2_buttons": 0x00},
	}
	var nmi_result: Dictionary = executor.execute_from_c421(nmi_context)
	if not bool(nmi_result.get("ok", false)):
		_fail("Explicit NMI source-executor fixture failed: " + String(nmi_result.get("error", "unknown error")))
		return
	var wrapper_write_found := false
	for write_variant in nmi_result.get("ram_writes", []):
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("source_pc", -1)) == 0xC426 \
					and int(write.get("address", -1)) == 0x003B \
					and int(write.get("before", -1)) == 0x55 \
					and int(write.get("value", -1)) == 0xAA:
				wrapper_write_found = true
				break
	if String(nmi_result.get("status", "")) != "stopped_after_sound_driver_first_queue_scan" \
			or int(nmi_result.get("ram_after", PackedByteArray())[0x003B]) != 0xAA \
			or int(nmi_result.get("ram_after", PackedByteArray())[0x0078]) != 0x04 \
			or int(nmi_result.get("ram_after", PackedByteArray())[0x001B]) != 0xC0 \
			or int(nmi_result.get("cpu_at_sound_driver_boundary", {}).get("pc", -1)) != 0x8061 \
			or not wrapper_write_found \
			or not bool(nmi_result.get("nmi_stack_frame_preserved", false)) \
			or bool(nmi_result.get("advances_live_route", true)) \
			or bool(nmi_result.get("emulator_data_used", true)) \
			or bool(nmi_result.get("candidate_state_used", true)):
		_fail("NMI fixture did not preserve the wrapper write, wait state, ROM path, and explicit non-route boundary.")
		return
	var empty_nmi_context: Dictionary = nmi_context.duplicate(true)
	var empty_ram: PackedByteArray = nmi_ram.duplicate()
	for address in range(0x0700, 0x0706):
		empty_ram[address] = 0
	empty_nmi_context["ram"] = empty_ram
	var empty_event: Dictionary = nmi_context["source_event"].duplicate(true)
	empty_event["source_event_id"] = "fixture_empty_sound_slots_at_893b"
	empty_nmi_context["source_event"] = empty_event
	var empty_nmi_result: Dictionary = executor.execute_from_c421(empty_nmi_context)
	if not bool(empty_nmi_result.get("ok", false)):
		_fail("Empty-slot NMI fixture failed: " + String(empty_nmi_result.get("error", "unknown error")))
		return
	var empty_resume: Dictionary = executor.resume_empty_sound_slots_to_queue_head(empty_nmi_result)
	var empty_cpu: Dictionary = empty_resume.get("cpu_at_queue_head", {})
	var caller_return_cpu: Dictionary = empty_resume.get("cpu_at_sound_driver_caller_return", {})
	var returned_cpu: Dictionary = empty_resume.get("cpu_after_nmi_rti", {})
	var empty_nmi_result_ram: PackedByteArray = empty_nmi_result.get("ram_after", PackedByteArray())
	var empty_resume_ram: PackedByteArray = empty_resume.get("ram_after", PackedByteArray())
	var empty_scanned_slots: Array = empty_resume.get("queue_slot_ids_scanned_reverse", [])
	var zero_mask_write_count := 0
	for write_variant in empty_resume.get("ram_writes", []):
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) == 0x0706 \
					and int(write.get("value", -1)) == 0:
				zero_mask_write_count += 1
	var pc_offsets: Array = empty_resume.get("pc_cycle_offsets_from_8061", [])
	var first_810c_cycle := -1
	var first_8163_cycle := -1
	for offset_variant in pc_offsets:
		if offset_variant is Dictionary:
			var offset: Dictionary = offset_variant
			if int(offset.get("pc", -1)) == 0x810C and first_810c_cycle < 0:
				first_810c_cycle = int(offset.get("cycles", -1))
			if int(offset.get("pc", -1)) == 0x8163:
				first_8163_cycle = int(offset.get("cycles", -1))
	if not bool(empty_resume.get("ok", false)) \
			or String(empty_resume.get("status", "")) != "returned_from_special_nmi_to_interrupted_pc" \
			or int(empty_cpu.get("pc", -1)) != 0x80CA \
			or int(empty_cpu.get("a", -1)) != 0x00 \
			or int(empty_cpu.get("x", -1)) != 0xFF \
			or int(empty_cpu.get("y", -1)) != 0x08 \
			or int(caller_return_cpu.get("pc", -1)) != 0xC44C \
			or int(returned_cpu.get("pc", -1)) != int(empty_nmi_context["nmi_frame"]["interrupted_pc"]) \
			or int(returned_cpu.get("p", -1)) != int(empty_nmi_context["nmi_frame"]["interrupted_p"]) \
			or int(returned_cpu.get("sp", -1)) != ((int(empty_nmi_context["cpu"]["sp"]) + 3) & 0xFF) \
			or int(returned_cpu.get("a", -1)) != int(empty_nmi_result_ram[0x003C]) \
			or int(returned_cpu.get("x", -1)) != int(empty_nmi_result_ram[0x003D]) \
			or int(returned_cpu.get("y", -1)) != int(empty_nmi_result_ram[0x003E]) \
			or empty_scanned_slots != [0, 0, 0, 0, 0, 0] \
			or empty_resume_ram.size() != 0x800 \
			or int(empty_resume_ram[0x0706]) != 0 \
			or zero_mask_write_count != 8 \
			or int(empty_resume.get("cpu_cycles_from_8061", -1)) != 728 \
			or first_810c_cycle != 110 \
			or first_8163_cycle != 656 \
			or empty_resume.get("apu_writes", []) != [] \
			or not bool(empty_resume.get("queue_data_0706_read", false)) \
			or not bool(empty_resume.get("sound_driver_rts_reached", false)) \
			or not bool(empty_resume.get("nmi_rti_reached", false)) \
			or not bool(empty_resume.get("nmi_stack_frame_restored", false)) \
			or bool(empty_resume.get("live_route_advanced", true)) \
			or bool(empty_resume.get("trace_state_used", true)) \
			or bool(empty_resume.get("emulator_data_used", true)) \
			or bool(empty_resume.get("candidate_state_used", true)):
		_fail("The ROM zero-mask sound-driver path failed: %s; status=%s return=%s cycles=%d `$810C`=%d `$8163`=%d mask-writes=%d." % [
			String(empty_resume.get("error", "no result")), String(empty_resume.get("status", "")),
			String.num_int64(int(caller_return_cpu.get("pc", -1)), 16),
			int(empty_resume.get("cpu_cycles_from_8061", -1)), first_810c_cycle, first_8163_cycle,
			zero_mask_write_count])
		return
	var stop_nmi_context: Dictionary = nmi_context.duplicate(true)
	var stop_ram: PackedByteArray = nmi_ram.duplicate()
	stop_ram[0x0700] = 0x01
	for address in range(0x0701, 0x0706):
		stop_ram[address] = 0
	stop_nmi_context["ram"] = stop_ram
	var stop_event: Dictionary = nmi_context["source_event"].duplicate(true)
	stop_event["source_event_id"] = "fixture_nmi_with_stop_id_01_in_queue_slot_0"
	stop_nmi_context["source_event"] = stop_event
	var stop_nmi_result: Dictionary = executor.execute_from_c421(stop_nmi_context)
	if not bool(stop_nmi_result.get("ok", false)):
		_fail("ID-$01 NMI prefix fixture failed: " + String(stop_nmi_result.get("error", "unknown error")))
		return
	var stop_consumer: Dictionary = executor.resume_stop_id_one_queue_clear(stop_nmi_result)
	var stop_cpu: Dictionary = stop_consumer.get("cpu_at_id_one_clear", {})
	var stop_stack: PackedByteArray = stop_consumer.get("stack_page_after", PackedByteArray())
	var stop_queue_before: PackedByteArray = stop_consumer.get("queue_before", PackedByteArray())
	var stop_queue_after: PackedByteArray = stop_consumer.get("queue_after", PackedByteArray())
	var stop_sp := int(stop_cpu.get("sp", -1))
	var stop_write_found := false
	for write_variant in stop_consumer.get("ram_writes", []):
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("source_pc", -1)) == 0x834D \
					and int(write.get("address", -1)) == 0x0700 \
					and int(write.get("before", -1)) == 0x01 \
					and int(write.get("value", -1)) == 0x00:
				stop_write_found = true
				break
	var stop_path: Array = stop_consumer.get("source_path", [])
	if not bool(stop_consumer.get("ok", false)) \
			or String(stop_consumer.get("status", "")) != "stopped_after_id_one_queue_clear_at_8350" \
			or stop_queue_before != PackedByteArray([0x01, 0, 0, 0, 0, 0]) \
			or stop_queue_after != PackedByteArray([0, 0, 0, 0, 0, 0]) \
			or stop_queue_after.size() != 6 \
			or int(stop_cpu.get("pc", -1)) != 0x8350 \
			or int(stop_cpu.get("x", -1)) != 0 \
			or int(stop_cpu.get("y", -1)) != 0x01 \
			or stop_stack.size() != 0x100 \
			or stop_sp < 0 or stop_sp > 0xFD \
			or int(stop_stack[stop_sp + 1]) != 0xB1 \
			or int(stop_stack[stop_sp + 2]) != 0x80 \
			or stop_consumer.get("queue_ids_scanned_reverse", []) != [0, 0, 0, 0, 0, 1] \
			or int(stop_consumer.get("cpu_cycles_from_8061_to_8350", -1)) != 93 \
			or not stop_path.has(0x80B7) or not stop_path.has(0x80B8) \
			or not stop_path.has(0x806E) or not stop_path.has(0x80AF) \
			or not stop_path.has(0x8349) \
			or not stop_path.has(0x834B) or not stop_path.has(0x8350) \
			or not stop_write_found \
			or not bool(stop_consumer.get("continuation", {}).get("jsr_pending", false)) \
			or bool(stop_consumer.get("apu_path_executed", true)) \
			or bool(stop_consumer.get("trace_state_used", true)) \
			or bool(stop_consumer.get("emulator_data_used", true)):
		_fail("The source ID-$01 sound-consumer boundary mismatch: " + JSON.stringify({
			"error": stop_consumer.get("error", ""), "status": stop_consumer.get("status", ""),
			"queue_before": stop_queue_before, "queue_after": stop_queue_after,
			"cpu": stop_cpu, "slots": stop_consumer.get("queue_ids_scanned_reverse", []),
			"cycles": stop_consumer.get("cpu_cycles_from_8061_to_8350", -1),
			"path": stop_path, "clear_store_found": stop_write_found,
			"pending": stop_consumer.get("continuation", {}),
		}))
		return
	var cbf1_script: Script = load(CBF1_EXECUTOR_PATH)
	if cbf1_script == null:
		_fail("Could not load the existing ROM `$CBF1` sound-queue helper.")
		return
	var cbf1: RefCounted = cbf1_script.new()
	if not bool(cbf1.configure_from_project_sources()):
		_fail("Existing `$CBF1` source setup failed: " + String(cbf1.error_message))
		return
	var cbf1_ram: PackedByteArray = stop_consumer.get("ram_after", PackedByteArray()).duplicate()
	cbf1_ram[0x0000] = 0x09
	cbf1_ram[0x052E] = 0x00
	cbf1_ram[0x063E] = 0x00
	var cbf1_stack := PackedByteArray()
	cbf1_stack.resize(0x100)
	cbf1_stack[0x77] = 0xAA
	cbf1_stack[0x78] = 0xD0
	cbf1_stack[0x79] = 0xF5
	cbf1_stack[0x7A] = 0xEB
	var d093_call := {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"source_manifest": "res://reference/rom_extract/gameplay/slot09_d093_sound_request/manifest.json",
		"caller_source_span_sha256": "f40f3cd4e1dd98e081463a5b9e9e3651e65533b495f2b437a9fee4e2cbf311d8",
		"caller_pc": 0xD0A8, "target_pc": 0xCBF1, "entry_pc": 0xCBF1,
		"return_word": 0xD0AA, "return_pc": 0xD0AB,
		"status": "source_cbf1_call_entry", "trace_state_used": false,
		"d093_bit_bypass": true,
		"registers": {"pc": 0xCBF1, "a": 0x3C, "x": 0, "y": 0,
			"p": 0x03, "p_known_mask": 0xC3, "sp": 0x76},
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0,
			"bank_registers": {6: 0x18, 7: 0x19}},
		"ram_image": cbf1_ram,
		"stack_page": cbf1_stack,
		"stack_writes": [
			{"pc": 0xEBF3, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
			{"pc": 0xEBF3, "address": 0x0179, "value": 0xF5, "kind": "JSR_low"},
			{"pc": 0xD0A8, "address": 0x0178, "value": 0xD0, "kind": "JSR_high"},
			{"pc": 0xD0A8, "address": 0x0177, "value": 0xAA, "kind": "JSR_low"},
		],
	}
	var cbf1_result: Dictionary = cbf1.execute_from_d093_sound_request_call(d093_call)
	if not bool(cbf1_result.get("ok", false)):
		_fail("The existing `$CBF1` helper rejected the post-ID-$01 queue state: "
			+ String(cbf1_result.get("reason", cbf1.error_message)))
		return
	if int(cbf1_result.get("queue_index", -1)) != 0 \
			or cbf1_result.get("input_queue", PackedByteArray()) != PackedByteArray([0, 0, 0, 0, 0]) \
			or cbf1_result.get("output_queue", PackedByteArray()) != PackedByteArray([0x3C, 0, 0, 0, 0]) \
			or cbf1_result.get("memory_writes", []).size() != 1 \
			or int(cbf1_result.get("memory_writes", [])[0].get("address", -1)) != 0x0700 \
			or int(cbf1_result.get("memory_writes", [])[0].get("value", -1)) != 0x3C:
		_fail("The source `$CBF1` helper did not place `$3C` in `$0700` after the ID-$01 consumer result.")
		return
	var nonempty_resume: Dictionary = executor.resume_empty_sound_slots_to_queue_head(nmi_result)
	if bool(nonempty_resume.get("ok", true)) \
			or not String(nonempty_resume.get("error", "")).contains("only the source-proven empty-slot path"):
		_fail("The empty-slot continuation accepted nonzero sound IDs without their source handler.")
		return
	# This verifier uses a test-only fixture above. The separate
	# verify_rom_source_c421_snapshot.gd validates the ROM-only source context;
	# keep this check focused on rejecting missing runtime input.
	var rejected: Dictionary = executor.execute_from_c421({})
	if bool(rejected.get("ok", true)) or bool(rejected.get("advances_live_route", true)) \
			or bool(rejected.get("trace_state_used", true)) \
			or bool(rejected.get("candidate_state_used", true)):
		_fail("Executor did not safely reject missing source-owned CPU/stack/RAM context.")
		return
	print("PASS: ROM hashes verified; `$C421->$8061` accepts the fixture `$0700=$01`, and the bounded `$8061->$80B8->$80AF->$834D` path clears it at PC `$8350`. The existing `$CBF1` helper then places `$3C` in `$0700`. The ID-$01 audio routine remains pending at `$8350`; the zero-mask fixture separately reaches `$C44C` and RTI. No FCEUX, emulator state, or live route was run.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
