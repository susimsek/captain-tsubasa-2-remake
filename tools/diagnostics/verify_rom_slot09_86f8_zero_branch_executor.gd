extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ZERO_BRANCH_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_86f8_zero_branch_executor.gd")
const SLOT09_PREFIX_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")

const P_N := 0x80
const P_Z := 0x02
const EXPECTED_SCENARIO38_WORKER_RAM := [
	0x01, 0x40, 0x38, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x40, 0x17, 0x00, 0x00,
	0x00, 0x2C, 0x00, 0x2C, 0x97, 0x06, 0x80, 0x00, 0x80, 0x00, 0x00, 0x00]
const EXPECTED_SCENARIO38_MAP2D := [
	0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00]


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the source route executes the slot-$09 `$86F8` worker through its live state.")
	print("PASS: the traced `$82` stream writes three `$046F` bytes, appends its ROM packet, and returns at `$EBB3`.")
	print("PASS: the exact frame-9065 callback-$34 input clears `$0533=$06` at `$8717`, loads `$AFE6`, and returns after its first ROM stream batch.")
	print("PASS: the callback-$34 batch's `$0532=$17`, `$0533=$04..$01` timer ticks decrement from ROM `$871F` and return to `$EBB3`.")
	print("PASS: the ordinary-input `$86F8` countdown profile preserves its reported `$0498=2` descriptor queue and `$047F=$0F` state.")
	print("PASS: the zero-countdown `$AFE9` control `$0A` writes both ROM pairs, appends `$00 $6C $04`, and returns at `$EBB3`.")
	print("PASS: the route continues through the checked `$8779` and `$87E6` workers to its `$CB0F` save.")
	print("LIMIT: the scenario-$38 source-boundary signature follows the ordinary-input route report, but the full worker RAM/stack and post-NMI queue-drained continuation are synthetic fixtures. `$AFEE` processing, PPU/APU delivery, NMI cadence, and screen output remain unresolved.")
	quit(0)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh-route source setup failed: " + builder.error_message)
	var route_context = builder.build_fresh_kickoff_context()
	if route_context == null:
		return _fail("Fresh-route context derivation failed: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route runner setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(route_context)
	if not bool(begin.get("ok", false)):
		return _fail("Source route did not reach its first slot-$09 yield: " + runner.error_message)
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)) \
			or String(advance.get("phase", "")) != "awaiting_external_nmi" \
			or String(advance.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY":
		return _fail("Source runner did not execute the slot-$09 worker chain and save its `$CB0F` boundary: " + runner.error_message)
	var live_result: Dictionary = advance.get("slot09_resume_result", {})
	if int(live_result.get("exit_pc", -1)) != 0x86F8 \
			or int((live_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x0532]) != 0:
		return _fail("Source runner did not provide the source-derived zero-state slot-$09 resume result.")
	var route_worker_result: Dictionary = advance.get("slot09_86f8_worker_result", {})
	if int(route_worker_result.get("exit_pc", -1)) != 0xEBB3 \
			or bool(route_worker_result.get("next_worker_bytes_read", true)) \
			or int(advance.get("slot09_8779_worker_result", {}).get("exit_pc", -1)) != 0xEBC5 \
			or int(advance.get("slot09_87e6_worker_result", {}).get("exit_pc", -1)) != 0xEBD7 \
			or not bool(advance.get("slot09_ebd7_root_zero_result", {}).get("ok", false)):
		return _fail("Source runner did not retain the `$EBB3` return before `$8779`.")

	var executor = ZERO_BRANCH_EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Worker-source setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_slot09_resume_result(live_result)
	if not bool(result.get("ok", false)):
		return _fail("`$86F8` zero-branch execution failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_returned_state(result, live_result):
		return false
	if not _verify_script82_branch(executor, live_result):
		return false
	if not _verify_rejected_inputs(executor, live_result):
		return false
	if not _verify_scenario38_callback34_reset_path(executor):
		return false
	return true


func _verify_scenario38_callback34_reset_path(executor: Variant) -> bool:
	var prefix = SLOT09_PREFIX_EXECUTOR.new()
	if not prefix.configure_from_project_sources():
		return _fail("Slot-$09 caller/callback source setup failed: " + prefix.error_message)
	var dispatch := _make_scenario38_callback34_dispatch()
	if not bool(dispatch.get("fixture_only", false)):
		return _fail("Scenario-$38 callback input must remain explicitly marked as a synthetic validation fixture.")
	var prefix_result: Dictionary = prefix.execute_from_next_task_dispatch(dispatch)
	if not bool(prefix_result.get("ok", false)) \
			or int(prefix_result.get("exit_pc", -1)) != 0x86F8 \
			or String(prefix_result.get("status", "")) != "stopped_before_worker_body":
		return _fail("The exact scenario-$38 callback-$34 pre-state did not source-run to `$86F8`: " \
			+ String(prefix_result.get("reason", prefix.error_message)))
	var input_ram: PackedByteArray = prefix_result.get("ram_image", PackedByteArray())
	if input_ram.size() != 0x800 \
			or input_ram.slice(0x0516, 0x053A) != PackedByteArray(EXPECTED_SCENARIO38_WORKER_RAM) \
			or input_ram.slice(0x05C7, 0x05D3) != PackedByteArray(EXPECTED_SCENARIO38_MAP2D) \
			or int(input_ram[0x0498]) != 1 \
			or input_ram.slice(0x0499, 0x049C) != PackedByteArray([0x00, 0x6C, 0x04]):
		return _fail("The callback source result did not preserve the exact marker-$97/countdown-$06 worker-entry RAM signature.")
	var result: Dictionary = executor.execute_from_slot09_resume_result(prefix_result)
	if not bool(result.get("ok", false)):
		return _fail("Scenario-$38 marker-$97 reset/stream worker failed: " \
			+ String(result.get("reason", executor.error_message)))
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var writes: Array = result.get("memory_writes", [])
	var source_reads: Array = result.get("source_reads", [])
	var instruction_pcs: Array = result.get("instruction_pcs", [])
	var queue_record: PackedByteArray = result.get("inline_queue_record", PackedByteArray())
	if String(result.get("status", "")) != "returned_after_stream_batch" \
			or int(result.get("entry_pc", -1)) != 0x86F8 or int(result.get("exit_pc", -1)) != 0xEBB3 \
			or int(result.get("input_ram_0532", -1)) != 0x97 \
			or int(result.get("input_ram_0533", -1)) != 0x06 \
			or int(result.get("output_ram_0532", -1)) != 0x17 \
			or int(result.get("countdown_before", -1)) != 0 \
			or int(result.get("countdown_after", -1)) != 4 \
			or int(result.get("stream_pointer_before", -1)) != 0xAFE6 \
			or int(result.get("stream_pointer_after", -1)) != 0xAFE9 \
			or int(result.get("stream_control", -1)) != 0x21 \
			or int(result.get("stream_pair_count", -1)) != 1 \
			or int(ram[0x0533]) != 4 or int(ram[0x003A]) != 0 \
			or int(ram[0x047F]) != 0x0F or int(ram[0x0498]) != 2 \
			or ram.slice(0x049C, 0x049F) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or queue_record != PackedByteArray([0x00, 0x6C, 0x04]) \
			or int(registers.get("pc", -1)) != 0xEBB3 or int(registers.get("sp", -1)) != 0x7A \
			or int(result.get("return_word", -1)) != 0xEBB2 \
			or not _has_worker_write(writes, 0x8701, 0x0532, 0x17) \
			or not _has_worker_write(writes, 0x8717, 0x0533, 0x00) \
			or not _has_worker_write(writes, 0x873C, 0x0533, 0x04) \
			or not _has_worker_write(writes, 0x874C, 0x047F, 0x0F) \
			or not _has_worker_source_read(source_reads, 0x870B, 0xAD9A, 0xE6, "stream_pointer_low") \
			or not _has_worker_source_read(source_reads, 0x8710, 0xAD9B, 0xAF, "stream_pointer_high") \
			or not _has_worker_source_read(source_reads, 0x8725, 0xAFE6, 0x21, "scenario_stream_control") \
			or not _has_worker_source_read(source_reads, 0x8746, 0xAFE7, 0x10, "ram_destination_index") \
			or not _has_worker_source_read(source_reads, 0x8749, 0xAFE8, 0x0F, "ram_destination_value") \
			or not instruction_pcs.has(0x8717) or not instruction_pcs.has(0x8723) \
			or bool(result.get("next_worker_executed", true)) \
			or bool(result.get("next_worker_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)) \
			or result.get("ppu_bus_events", []).size() != 0 \
			or result.get("apu_register_writes", []).size() != 0:
		return _fail("Scenario-$38 marker-$97 RAM/source/stack result differs: " + str({
			"status": result.get("status"), "countdown_in": result.get("input_ram_0533"),
			"countdown_out": ram[0x0533] if ram.size() == 0x800 else -1,
			"stream": [result.get("stream_pointer_before"), result.get("stream_pointer_after")],
			"registers": registers, "instruction_pcs": instruction_pcs}))
	return _verify_scenario38_terminal_wait_countdown_batch(executor)


func _verify_scenario38_terminal_wait_countdown_batch(executor: Variant) -> bool:
	var prefix = SLOT09_PREFIX_EXECUTOR.new()
	if not prefix.configure_from_project_sources():
		return _fail("Scenario-$38 terminal-wait prefix sources failed to configure: " + prefix.error_message)
	var dispatch := _make_scenario38_live_wait_dispatch()
	if not bool(dispatch.get("fixture_only", false)):
		return _fail("The post-`$B7CC` prefix dispatch must remain an explicitly synthetic fixture.")
	var prefix_result: Dictionary = prefix.execute_from_next_task_dispatch(dispatch)
	if not bool(prefix_result.get("ok", false)) \
			or String(prefix_result.get("status", "")) != "stopped_before_worker_body" \
			or int(prefix_result.get("exit_pc", -1)) != 0x86F8:
		return _fail("The terminal-wait prefix did not source-run to `$86F8`: " \
				+ String(prefix_result.get("reason", prefix.error_message)))
	var worker_input_ram: PackedByteArray = prefix_result.get("ram_image", PackedByteArray())
	if worker_input_ram.size() != 0x800 \
			or worker_input_ram.slice(0x0516, 0x051A) != PackedByteArray([0x29, 0x40, 0x38, 0x00]) \
			or worker_input_ram.slice(0x0523, 0x052B) != PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x00]) \
			or int(worker_input_ram[0x0522]) != 0x00 \
			or int(worker_input_ram[0x052B]) != 0 \
			or int(worker_input_ram[0x003A]) != 0x01 \
			or worker_input_ram.slice(0x05C7, 0x05D3) != PackedByteArray(EXPECTED_SCENARIO38_MAP2D) \
			or int(worker_input_ram[0x0079]) != 0xE9 or int(worker_input_ram[0x007A]) != 0xAF \
			or int(worker_input_ram[0x0532]) != 0x17 or int(worker_input_ram[0x0533]) != 0x04 \
			or int(worker_input_ram[0x0498]) != 0x02 \
			or worker_input_ram.slice(0x049C, 0x049F) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or int(worker_input_ram[0x047F]) != 0x0F:
		return _fail("The prefix's source-derived terminal `$29` worker profile differs: " + str({
			"phase": worker_input_ram.slice(0x0516, 0x051A).hex_encode() if worker_input_ram.size() == 0x800 else "invalid",
			"cursor": worker_input_ram[0x003A] if worker_input_ram.size() == 0x800 else -1,
			"pointer": worker_input_ram.slice(0x0079, 0x007B).hex_encode() if worker_input_ram.size() == 0x800 else "invalid",
			"marker_countdown": worker_input_ram.slice(0x0532, 0x0534).hex_encode() if worker_input_ram.size() == 0x800 else "invalid",
			"descriptor_queue": worker_input_ram.slice(0x0498, 0x049F).hex_encode() if worker_input_ram.size() == 0x800 else "invalid",
			"palette": worker_input_ram[0x047F] if worker_input_ram.size() == 0x800 else -1}))
	var countdown_input := prefix_result.duplicate(true)
	for expected_countdown in [4, 3, 2, 1]:
		var countdown_result: Dictionary = executor.execute_from_slot09_resume_result(countdown_input)
		var countdown_after: int = expected_countdown - 1
		if not bool(countdown_result.get("ok", false)) \
				or String(countdown_result.get("status", "")) != "returned_after_countdown" \
				or int(countdown_result.get("input_ram_0532", -1)) != 0x17 \
				or int(countdown_result.get("input_ram_0533", -1)) != expected_countdown \
				or int(countdown_result.get("countdown_after", -1)) != countdown_after \
				or int(countdown_result.get("stream_pointer", -1)) != 0xAFE9 \
				or int(countdown_result.get("exit_pc", -1)) != 0xEBB3 \
				or int(countdown_result.get("return_word", -1)) != 0xEBB2 \
				or not _has_worker_write(countdown_result.get("memory_writes", []), 0x871F, 0x0533, countdown_after) \
				or countdown_result.get("instruction_pcs", []) != [0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D, 0x871F, 0x8722] \
				or int(countdown_result.get("ram_image", PackedByteArray())[0x0498]) != 0x02 \
				or countdown_result.get("ram_image", PackedByteArray()).slice(0x049C, 0x049F) != PackedByteArray([0x00, 0x6C, 0x04]) \
				or int(countdown_result.get("ram_image", PackedByteArray())[0x047F]) != 0x0F \
				or bool(countdown_result.get("next_worker_bytes_read", true)) \
				or bool(countdown_result.get("trace_state_used", true)):
			return _fail("Scenario-$38 terminal `$29` countdown %d did not execute only `$86F8->$871A->$871F->$8722->$EBB3`: %s" % [
				expected_countdown, str(countdown_result)])
		countdown_input["ram_image"] = countdown_result["ram_image"].duplicate()
	# The next `$AFE9` batch is tested separately behind a synthetic NMI-drained
	# queue state. This does not claim that the route's NMI cadence is decoded.
	var next_stream_input := countdown_input.duplicate(true)
	var drained_ram: PackedByteArray = next_stream_input["ram_image"].duplicate()
	drained_ram[0x0498] = 0x00
	drained_ram[0x0499] = 0x00
	drained_ram[0x049A] = 0x00
	drained_ram[0x049B] = 0x00
	drained_ram[0x047F] = 0x00
	next_stream_input["ram_image"] = drained_ram
	var next_stream_result: Dictionary = executor.execute_from_slot09_resume_result(next_stream_input)
	if not bool(next_stream_result.get("ok", false)) \
			or String(next_stream_result.get("status", "")) != "returned_after_stream_batch" \
			or int(next_stream_result.get("input_ram_0532", -1)) != 0x17 \
			or int(next_stream_result.get("input_ram_0533", -1)) != 0 \
			or int(next_stream_result.get("stream_control", -1)) != 0x0A \
			or int(next_stream_result.get("stream_pair_count", -1)) != 2 \
			or int(next_stream_result.get("countdown_after", -1)) != 1 \
			or int(next_stream_result.get("stream_pointer_before", -1)) != 0xAFE9 \
			or int(next_stream_result.get("stream_pointer_after", -1)) != 0xAFEE \
			or int(next_stream_result.get("exit_pc", -1)) != 0xEBB3 \
			or int(next_stream_result.get("return_word", -1)) != 0xEBB2:
		return _fail("Scenario-$38 `$AFE9` batch did not return at `$EBB3`: " + str(next_stream_result))
	var next_stream_ram: PackedByteArray = next_stream_result.get("ram_image", PackedByteArray())
	var next_stream_reads: Array = next_stream_result.get("source_reads", [])
	var next_stream_writes: Array = next_stream_result.get("memory_writes", [])
	var next_stream_queue: PackedByteArray = next_stream_result.get("inline_queue_record", PackedByteArray())
	if next_stream_ram.size() != 0x800 \
			or int(next_stream_ram[0x048E]) != 0x11 or int(next_stream_ram[0x0485]) != 0x30 \
			or int(next_stream_ram[0x0533]) != 1 or int(next_stream_ram[0x003A]) != 0 \
			or int(next_stream_ram[0x0498]) != 1 \
			or next_stream_ram.slice(0x0499, 0x049C) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or next_stream_queue != PackedByteArray([0x00, 0x6C, 0x04]) \
			or not _has_worker_write(next_stream_writes, 0x873C, 0x0533, 0x01) \
			or not _has_worker_write(next_stream_writes, 0x8743, 0x003A, 0x02) \
			or not _has_worker_write(next_stream_writes, 0x874C, 0x048E, 0x11) \
			or not _has_worker_write(next_stream_writes, 0x874C, 0x0485, 0x30) \
			or not _has_worker_write(next_stream_writes, 0x8758, 0x0079, 0xEE) \
			or not _has_worker_write(next_stream_writes, 0xCD07, 0x0498, 0x01) \
			or not _has_worker_source_read(next_stream_reads, 0x8725, 0xAFE9, 0x0A, "scenario_stream_control") \
			or not _has_worker_source_read(next_stream_reads, 0x8746, 0xAFEA, 0x1F, "ram_destination_index") \
			or not _has_worker_source_read(next_stream_reads, 0x8749, 0xAFEB, 0x11, "ram_destination_value") \
			or not _has_worker_source_read(next_stream_reads, 0x8746, 0xAFEC, 0x16, "ram_destination_index") \
			or not _has_worker_source_read(next_stream_reads, 0x8749, 0xAFED, 0x30, "ram_destination_value") \
			or bool(next_stream_result.get("trace_state_used", true)) \
			or bool(next_stream_result.get("ppu_apu_effects_applied", true)):
		return _fail("Scenario-$38 `$AFE9` ordered RAM/source/queue effects differ: " + str({
			"ram_0485_048e": [next_stream_ram[0x0485], next_stream_ram[0x048E]] if next_stream_ram.size() == 0x800 else [],
			"pointer": next_stream_result.get("stream_pointer_after"),
			"countdown": next_stream_result.get("countdown_after"), "queue": next_stream_queue.hex_encode(),
			"writes": next_stream_writes, "reads": next_stream_reads}))
	if not _verify_scenario38_rejected_near_matches(executor, prefix_result):
		return false
	return true


func _make_scenario38_callback34_dispatch() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x09
	ram[0x0021] = 0x1E
	ram[0x0022] = 0x00
	ram[0x0516] = 0x51
	ram[0x0517] = 0x40
	ram[0x0518] = 0x38
	ram[0x0523] = 0x01
	ram[0x0524] = 0x34
	ram[0x0525] = 0x02
	ram[0x0526] = 0x80
	ram[0x0527] = 0x02
	ram[0x0529] = 0xFF
	ram[0x052A] = 0x40
	ram[0x052B] = 0x17
	ram[0x052F] = 0x2C
	ram[0x0531] = 0x2C
	ram[0x0533] = 0x06
	ram[0x05C7] = 0x40
	ram[0x05C8] = 0xA0
	ram[0x05CA] = 0x02
	ram[0x05CB] = 0x01
	ram[0x05CC] = 0x2D
	ram[0x05CD] = 0xA0
	ram[0x05CE] = 0x80
	ram[0x05D0] = 0x02
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0x77] = 0x05
	stack[0x78] = 0x78
	stack[0x79] = 0x8A
	stack[0x7A] = 0xEB
	ram[0x0177] = 0x05
	ram[0x0178] = 0x78
	ram[0x0179] = 0x8A
	ram[0x017A] = 0xEB
	return {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x09, "resume_path": "yielded_rts", "pc": 0xEB8B, "sp": 0x7A,
		"a": 0x78, "x": 0x78, "y": 0x05, "p": 0x00, "p_known_mask": 0,
		"bank_low": 0x18, "bank_high": 0x19,
		"task_record": PackedByteArray([0x00, 0x76, 0x18, 0x19]),
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07},
		"ram_image": ram, "stack_page": stack, "fixture_only": true,
		"trace_state_used": false,
	}


func _make_scenario38_live_wait_dispatch() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x09
	ram[0x0021] = 0x1E
	ram[0x0022] = 0x00
	ram[0x003A] = 0x06
	ram[0x005D] = 0xCC
	ram[0x005E] = 0xB7
	ram[0x0079] = 0xE9
	ram[0x007A] = 0xAF
	ram[0x0516] = 0x01
	ram[0x0517] = 0x40
	ram[0x0518] = 0x38
	ram[0x0519] = 0x01
	ram[0x0522] = 0x00
	ram[0x0523] = 0x01
	ram[0x0524] = 0x34
	ram[0x0525] = 0x02
	ram[0x0526] = 0x00
	ram[0x0527] = 0x02
	ram[0x0528] = 0x00
	ram[0x0529] = 0xFF
	ram[0x052A] = 0x40
	ram[0x052B] = 0x17
	ram[0x052F] = 0x2C
	ram[0x0531] = 0x2C
	ram[0x0532] = 0x17
	ram[0x0533] = 0x04
	ram[0x047F] = 0x0F
	ram[0x0498] = 0x02
	ram[0x049C] = 0x00
	ram[0x049D] = 0x6C
	ram[0x049E] = 0x04
	ram[0x05C7] = 0x40
	ram[0x05C8] = 0xA0
	ram[0x05C9] = 0x00
	ram[0x05CA] = 0x02
	ram[0x05CB] = 0x01
	ram[0x05CC] = 0x2D
	ram[0x05CD] = 0xA0
	ram[0x05CE] = 0x80
	ram[0x05D0] = 0x02
	ram[0x05D1] = 0x00
	ram[0x05D2] = 0x00
	ram[0x0177] = 0x05
	ram[0x0178] = 0x78
	ram[0x0179] = 0x8A
	ram[0x017A] = 0xEB
	var dispatch := _make_scenario38_callback34_dispatch()
	dispatch["ram_image"] = ram
	dispatch["fixture_only"] = true
	dispatch["trace_state_used"] = false
	return dispatch


func _verify_scenario38_rejected_near_matches(executor: Variant, resume_result: Dictionary) -> bool:
	for mutation in [
		{"name": "countdown other than six", "address": 0x0533, "value": 0x05},
		{"name": "callback palette state mismatch", "address": 0x0526, "value": 0x80},
		{"name": "map-$2D signature mismatch", "address": 0x05CC, "value": 0x36},
	]:
		var changed := resume_result.duplicate(true)
		var ram: PackedByteArray = (resume_result["ram_image"] as PackedByteArray).duplicate()
		ram[int(mutation["address"])] = int(mutation["value"])
		changed["ram_image"] = ram
		var rejected: Dictionary = executor.execute_from_slot09_resume_result(changed)
		if bool(rejected.get("ok", true)):
			return _fail("The exact callback-$34 worker gate accepted %s." % String(mutation["name"]))
	return true


func _has_worker_write(writes: Array, pc: int, address: int, value: int) -> bool:
	for row_variant in writes:
		if row_variant is Dictionary and int(row_variant.get("pc", -1)) == pc \
				and int(row_variant.get("address", -1)) == address \
				and int(row_variant.get("value", -1)) == value:
			return true
	return false


func _has_worker_source_read(reads: Array, pc: int, address: int, value: int, kind: String) -> bool:
	for row_variant in reads:
		if row_variant is Dictionary and int(row_variant.get("pc", -1)) == pc \
				and int(row_variant.get("address", -1)) == address \
				and int(row_variant.get("value", -1)) == value \
				and String(row_variant.get("kind", "")) == kind:
			return true
	return false


func _verify_returned_state(result: Dictionary, live_result: Dictionary) -> bool:
	var input_ram: PackedByteArray = live_result["ram_image"]
	var input_stack: PackedByteArray = live_result["stack_page"]
	var input_mapper: Dictionary = live_result["mapper"]
	var registers: Dictionary = result.get("registers", {})
	var entry_registers: Dictionary = result.get("entry_registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var expected_stack_reads: Array[Dictionary] = [
		{"pc": 0x8722, "address": 0x0179, "value": 0xB2, "kind": "RTS_low"},
		{"pc": 0x8722, "address": 0x017A, "value": 0xEB, "kind": "RTS_high"},
	]
	if String(result.get("status", "")) != "returned_to_root_caller" \
			or String(result.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or int(result.get("entry_pc", -1)) != 0x86F8 \
			or int(result.get("exit_pc", -1)) != 0xEBB3 \
			or int(result.get("entry_bank", -1)) != 0x18 \
			or int(result.get("exit_bank", -1)) != 0x18 \
			or int(result.get("input_ram_0532", -1)) != 0 \
			or int(entry_registers.get("pc", -1)) != 0x86F8 \
			or int(entry_registers.get("sp", -1)) != 0x78 \
			or int(registers.get("pc", -1)) != 0xEBB3 \
			or int(registers.get("sp", -1)) != 0x7A \
			or int(registers.get("a", -1)) != 0 \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & (P_N | P_Z)) != (P_N | P_Z) \
			or int(result.get("return_word", -1)) != 0xEBB2 \
			or int(result.get("return_pc", -1)) != 0xEBB3 \
			or result.get("instruction_pcs", []) != [0x86F8, 0x86FB, 0x8722] \
			or result.get("memory_writes", []) != [] \
			or result.get("stack_reads", []) != expected_stack_reads \
			or result.get("stack_writes", []) != [] \
			or output_ram != input_ram or output_stack != input_stack \
			or mapper != input_mapper \
			or bool(result.get("next_worker_executed", true)) \
			or bool(result.get("next_worker_bytes_read", true)) \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != [] \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)):
		return _fail("Zero-branch CPU/stack/RAM/mapper output or no-side-effect boundary differs: " + str({
				"status": result.get("status"), "entry_pc": result.get("entry_pc"), "exit_pc": result.get("exit_pc"),
				"entry_bank": result.get("entry_bank"), "exit_bank": result.get("exit_bank"),
				"ram_value": result.get("input_ram_0532"), "entry_registers": entry_registers,
				"registers": registers, "return_word": result.get("return_word"),
				"instruction_pcs": result.get("instruction_pcs"), "stack_reads": result.get("stack_reads"),
				"ram_same": output_ram == input_ram, "stack_same": output_stack == input_stack,
				"mapper_same": mapper == input_mapper,
				"next_worker_bytes_read": result.get("next_worker_bytes_read"),
				"ppu_bus_events": result.get("ppu_bus_events"), "apu_writes": result.get("apu_register_writes"),
				"effects_applied": result.get("ppu_apu_effects_applied"),
				"trace_used": result.get("trace_state_used"), "nmi_generated": result.get("nmi_cadence_generated")}))
	return true


func _verify_rejected_inputs(executor: Variant, live_result: Dictionary) -> bool:
	var nonzero := live_result.duplicate(true)
	var nonzero_ram: PackedByteArray = (live_result["ram_image"] as PackedByteArray).duplicate()
	nonzero_ram[0x0532] = 0x01
	nonzero["ram_image"] = nonzero_ram
	var rejected_nonzero: Dictionary = executor.execute_from_slot09_resume_result(nonzero)
	if bool(rejected_nonzero.get("ok", true)) \
			or String(rejected_nonzero.get("status", "")) != "unsupported_branch" \
			or int(rejected_nonzero.get("exit_pc", -1)) != 0x871A \
			or not String(rejected_nonzero.get("reason", "")).contains("$86FD->$871A"):
		return _fail("Nonzero low-bit marker did not stop at the unresolved source `$86FD->$871A` countdown branch: " + str(rejected_nonzero))

	var invalid_stack := live_result.duplicate(true)
	var bad_stack: PackedByteArray = (live_result["stack_page"] as PackedByteArray).duplicate()
	bad_stack[0x79] = 0xB3
	invalid_stack["stack_page"] = bad_stack
	var rejected_stack: Dictionary = executor.execute_from_slot09_resume_result(invalid_stack)
	if bool(rejected_stack.get("ok", true)) \
			or String(rejected_stack.get("status", "")) != "rejected_input":
		return _fail("A mismatched `$EBB2->$EBB3` stack contract was not rejected.")
	return true


func _verify_script82_branch(executor: Variant, live_result: Dictionary) -> bool:
	# This isolated branch probe checks the alternate source path from the same
	# structurally validated live caller contract. The production route never
	# receives this test-mutated RAM image; its recorded route supplies $82.
	var script82_input := live_result.duplicate(true)
	var ram: PackedByteArray = (live_result["ram_image"] as PackedByteArray).duplicate()
	ram[0x0532] = 0x82
	script82_input["ram_image"] = ram
	var result: Dictionary = executor.execute_from_slot09_resume_result(script82_input)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "returned_after_script82" \
			or int(result.get("exit_pc", -1)) != 0xEBB3 \
			or int(result.get("output_ram_0532", -1)) != 0x02:
		return _fail("The checked `$82` script branch failed: " + String(result.get("reason", executor.error_message)))
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var queue_record: PackedByteArray = result.get("inline_queue_record", PackedByteArray())
	if output_ram.size() != 0x800 \
			or output_ram.slice(0x047C, 0x047F) != PackedByteArray([0x1A, 0x1A, 0x3A]) \
			or int(output_ram[0x0533]) != 6 \
			or int(output_ram[0x003A]) != 0 \
			or int(output_ram[0x0498]) != ((int(ram[0x0498]) + 1) & 0xFF) \
			or queue_record != PackedByteArray([0x00, 0x6C, 0x04]) \
			or int(registers.get("pc", -1)) != 0xEBB3 \
			or int(registers.get("sp", -1)) != 0x7A \
			or int(registers.get("a", -1)) != 7 \
			or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 7 \
			or bool(result.get("trace_state_used", true)) \
			or result.get("ppu_bus_events", []).size() != 0 \
			or result.get("apu_register_writes", []).size() != 0:
		return _fail("The `$82` script stream's live RAM, return, queue, or side-effect boundary differs: " + str({
			"047C_047E": output_ram.slice(0x047C, 0x047F).hex_encode(),
			"0533": int(output_ram[0x0533]), "003A": int(output_ram[0x003A]),
			"0498": int(output_ram[0x0498]), "queue": queue_record.hex_encode(),
			"registers": registers, "trace_state_used": result.get("trace_state_used")}))
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
