extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const WORKER_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_8779_zero_branch_executor.gd")
const PREFIX_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const PREVIOUS_WORKER_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_86f8_zero_branch_executor.gd")
const NEXT_WORKER_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_87e6_zero_branch_executor.gd")

const P_N := 0x80
const P_Z := 0x02
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the live route's `$86F8` result executes `$EBB3->$8006->$8779` through the `$0534==0` branch and returns at `$EBC5`.")
	print("PASS: source hashes, CPU/RAM/stack/MMC3 state, writes, branch, and next-call boundary match the checked ROM path.")
	print("PASS: scenario-$38 `$B7CC/$FB` route signature ticks `$0533` 4→3, then `$8779->$87A3 RTS` and `$87E6->$8814 RTS` reach `$EBD7`.")
	print("LIMIT: `$80` normalization awaits its actor-seeded route check; stream/script behavior, PPU/APU effects, and visible output remain unresolved.")
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
		return _fail("Source route did not reach its slot-$09 yield: " + runner.error_message)
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)) \
			or String(advance.get("phase", "")) != "awaiting_external_nmi" \
			or String(advance.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY":
		return _fail("Source route did not execute the slot-$09 chain through the live `$CB0F` save: " + runner.error_message)
	var previous_result: Dictionary = advance.get("slot09_86f8_worker_result", {})
	if String(previous_result.get("status", "")) != "returned_to_root_caller" \
			or int(previous_result.get("exit_pc", -1)) != 0xEBB3 \
			or int(previous_result.get("ram_image", PackedByteArray())[0x0532]) != 0 \
			or bool(previous_result.get("trace_state_used", true)):
		return _fail("Runner did not provide an actual source-derived `$86F8` return at `$EBB3`.")

	var executor = WORKER_EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("Worker source-package setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_86f8_worker_result(previous_result)
	if not bool(result.get("ok", false)):
		return _fail("`$8779` zero-branch execution failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_returned_state(result, previous_result):
		return false
	if not _verify_rejected_inputs(executor, previous_result):
		return false
	if not _verify_scenario38_countdown_handoff(executor):
		return false
	if not _verify_scenario38_live_pass_handoff(executor):
		return false
	return true


func _verify_scenario38_countdown_handoff(executor: Variant) -> bool:
	var prefix: RefCounted = PREFIX_EXECUTOR.new()
	var previous_worker: RefCounted = PREVIOUS_WORKER_EXECUTOR.new()
	var next_worker: RefCounted = NEXT_WORKER_EXECUTOR.new()
	if not bool(prefix.call("configure_from_project_sources")) \
			or not bool(previous_worker.call("configure_from_project_sources")) \
			or not bool(next_worker.call("configure_from_project_sources")):
		return _fail("Scenario-$38 prefix/worker source packages failed setup.")
	var dispatch := _make_scenario38_fb_wait_dispatch()
	var dispatch_ram: PackedByteArray = dispatch["ram_image"]
	if dispatch_ram.slice(0x0516, 0x051A) != PackedByteArray([0x01, 0x40, 0x38, 0x01]) \
			or dispatch_ram[0x003A] != 0x06 \
			or (dispatch_ram[0x005D] | (dispatch_ram[0x005E] << 8)) != 0xB7CC \
			or dispatch_ram.slice(0x0523, 0x052B) != PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x40]) \
			or dispatch_ram.slice(0x05C7, 0x05D3) != PackedByteArray([0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00]) \
			or dispatch_ram[0x0498] != 0x02 \
			or dispatch_ram.slice(0x049C, 0x049F) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or dispatch_ram[0x047F] != 0x0F:
		return _fail("Scenario-$38 callback dispatch does not match the ordinary-input report's exact signature.")
	var prefix_result: Dictionary = prefix.call("execute_from_next_task_dispatch", dispatch)
	if not bool(prefix_result.get("ok", false)) or int(prefix_result.get("exit_pc", -1)) != 0x86F8:
		return _fail("Scenario-$38 `$B7CC/$FB` source prefix did not reach `$86F8`: " + String(prefix_result.get("reason", "unknown")))
	var countdown_result: Dictionary = previous_worker.call("execute_from_slot09_resume_result", prefix_result)
	var countdown_ram: PackedByteArray = countdown_result.get("ram_image", PackedByteArray())
	if not bool(countdown_result.get("ok", false)) \
			or String(countdown_result.get("status", "")) != "returned_after_countdown" \
			or int(countdown_result.get("input_ram_0532", -1)) != 0x17 \
			or int(countdown_result.get("output_ram_0532", -1)) != 0x17 \
			or int(countdown_result.get("countdown_before", -1)) != 0x04 \
			or int(countdown_result.get("countdown_after", -1)) != 0x03 \
			or countdown_ram.size() != 0x800 \
			or countdown_ram.slice(0x0516, 0x051A) != PackedByteArray([0x29, 0x40, 0x38, 0x00]) \
			or countdown_ram[0x0533] != 0x03 \
			or (countdown_ram[0x0079] | (countdown_ram[0x007A] << 8)) != 0xAFE9 \
			or countdown_ram[0x003A] != 0x01 \
			or countdown_ram[0x0498] != 0x02 \
			or countdown_ram.slice(0x049C, 0x049F) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or countdown_ram[0x047F] != 0x0F:
		return _fail("Scenario-$38 ROM countdown did not produce the exact `$04->$03` live `$8779` handoff: " + str({
			"status": countdown_result.get("status"), "reason": countdown_result.get("reason"),
			"countdown": countdown_ram.slice(0x0532, 0x0534).hex_encode() if countdown_ram.size() == 0x800 else "invalid",
			"queue": countdown_ram.slice(0x0498, 0x049F).hex_encode() if countdown_ram.size() == 0x800 else "invalid"}))
	var root_result: Dictionary = executor.call("execute_from_86f8_worker_result", countdown_result)
	if not bool(root_result.get("ok", false)):
		return _fail("`$8779` rejected the exact scenario-$38 callback-$34 countdown result: " + String(root_result.get("reason", "unknown")))
	if not _verify_returned_state(root_result, countdown_result):
		return false
	var bad_queue := countdown_result.duplicate(true)
	var bad_queue_ram: PackedByteArray = countdown_ram.duplicate()
	bad_queue_ram[0x0498] = 0x01
	bad_queue["ram_image"] = bad_queue_ram
	var rejected_queue: Dictionary = executor.call("execute_from_86f8_worker_result", bad_queue)
	if bool(rejected_queue.get("ok", true)) or String(rejected_queue.get("status", "")) != "rejected_input":
		return _fail("Scenario-$38 countdown near-match with append cursor `$01` was not rejected.")
	var next_result: Dictionary = next_worker.call("execute_from_8779_worker_result", root_result)
	var next_ram: PackedByteArray = next_result.get("ram_image", PackedByteArray())
	if not bool(next_result.get("ok", false)) \
			or String(next_result.get("status", "")) != "returned_before_root_loop_check" \
			or int(next_result.get("entry_pc", -1)) != 0xEBC5 \
			or int(next_result.get("exit_pc", -1)) != 0xEBD7 \
			or int(next_result.get("worker_entry_pc", -1)) != 0x87E6 \
			or int(next_result.get("input_ram_0536", -1)) != 0 \
			or next_ram.size() != 0x800 or next_ram[0x0538] != 0 \
			or bool(next_result.get("next_root_check_executed", true)):
		return _fail("The `$8779->$87E6` continuation did not stop at its verified `$EBD7` boundary: " + str({
			"status": next_result.get("status"), "exit_pc": next_result.get("exit_pc"),
			"reason": next_result.get("reason")}))
	return true


func _verify_scenario38_live_pass_handoff(executor: Variant) -> bool:
	var prefix: RefCounted = PREFIX_EXECUTOR.new()
	var previous_worker: RefCounted = PREVIOUS_WORKER_EXECUTOR.new()
	if not bool(prefix.call("configure_from_project_sources")) \
			or not bool(previous_worker.call("configure_from_project_sources")):
		return _fail("Scenario-$38 live-PASS caller/worker sources failed setup.")
	var dispatch := _make_scenario38_live_pass_dispatch()
	if not bool(dispatch.get("fixture_only", false)):
		return _fail("The isolated live-PASS source pre-state must be marked as a validation fixture.")
	var prefix_result: Dictionary = prefix.call("execute_from_next_task_dispatch", dispatch)
	if not bool(prefix_result.get("ok", false)) \
			or String(prefix_result.get("status", "")) != "stopped_before_worker_body" \
			or int(prefix_result.get("exit_pc", -1)) != 0x86F8:
		return _fail("The live-PASS source prefix did not reach the `$86F8` worker vector: " \
				+ String(prefix_result.get("reason", "unknown")))
	var input_ram: PackedByteArray = prefix_result.get("ram_image", PackedByteArray())
	if input_ram.size() != 0x800 \
			or input_ram.slice(0x0516, 0x051A) != PackedByteArray([0x00, 0x40, 0x38, 0x00]) \
			or int(input_ram[0x0441]) != 0x06 \
			or int(input_ram[0x0532]) != 0x01 or int(input_ram[0x0533]) != 0x03 \
			or int(input_ram[0x0079]) != 0xE9 or int(input_ram[0x007A]) != 0xAF \
			or int(input_ram[0x003A]) != 0x06 \
			or int(input_ram[0x0498]) != 0x00 \
			or input_ram.slice(0x0499, 0x04A0) != PackedByteArray([0x00, 0x6C, 0x04, 0x00, 0x6C, 0x04, 0x00]) \
			or int(input_ram[0x047F]) != 0x0F:
		return _fail("The live-PASS prefix did not preserve the source `$38` fields, holder, countdown, palette, and empty PPU queue: " + str({
				"phase": input_ram.slice(0x0516, 0x051A).hex_encode() if input_ram.size() == 0x800 else "invalid",
				"holder": input_ram[0x0441] if input_ram.size() == 0x800 else -1,
				"marker_countdown": input_ram.slice(0x0532, 0x0534).hex_encode() if input_ram.size() == 0x800 else "invalid",
				"pointer": input_ram.slice(0x0079, 0x007B).hex_encode() if input_ram.size() == 0x800 else "invalid",
				"queue": input_ram.slice(0x0498, 0x04A0).hex_encode() if input_ram.size() == 0x800 else "invalid"}))
	var countdown_result: Dictionary = previous_worker.call("execute_from_slot09_resume_result", prefix_result)
	var countdown_ram: PackedByteArray = countdown_result.get("ram_image", PackedByteArray())
	if not bool(countdown_result.get("ok", false)) \
			or String(countdown_result.get("status", "")) != "returned_after_countdown" \
			or int(countdown_result.get("input_ram_0532", -1)) != 0x01 \
			or int(countdown_result.get("output_ram_0532", -1)) != 0x01 \
			or int(countdown_result.get("input_ram_0533", -1)) != 0x03 \
			or int(countdown_result.get("countdown_before", -1)) != 0x03 \
			or int(countdown_result.get("countdown_after", -1)) != 0x02 \
			or countdown_ram.size() != 0x800 \
			or countdown_ram.slice(0x0516, 0x051A) != PackedByteArray([0x00, 0x40, 0x38, 0x00]) \
			or int(countdown_ram[0x0441]) != 0x06 \
			or int(countdown_ram[0x0533]) != 0x02 \
			or (int(countdown_ram[0x0079]) | (int(countdown_ram[0x007A]) << 8)) != 0xAFE9 \
			or int(countdown_ram[0x003A]) != 0x06 \
			or int(countdown_ram[0x0498]) != 0 \
			or countdown_ram.slice(0x0499, 0x04A0) != PackedByteArray([0x00, 0x6C, 0x04, 0x00, 0x6C, 0x04, 0x00]) \
			or int(countdown_ram[0x047F]) != 0x0F:
		return _fail("The live-PASS `$86F8->$871A` tick did not preserve/decrement the strict route state: " + str({
				"status": countdown_result.get("status"), "reason": countdown_result.get("reason"),
				"countdown": countdown_ram.slice(0x0532, 0x0534).hex_encode() if countdown_ram.size() == 0x800 else "invalid",
				"queue": countdown_ram.slice(0x0498, 0x04A0).hex_encode() if countdown_ram.size() == 0x800 else "invalid"}))
	var scratch_countdown_input := prefix_result.duplicate(true)
	var scratch_countdown_ram: PackedByteArray = input_ram.duplicate()
	scratch_countdown_ram[0x003A] = 0x0F
	scratch_countdown_input["ram_image"] = scratch_countdown_ram
	var scratch_countdown_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", scratch_countdown_input)
	var scratch_countdown_output: PackedByteArray = scratch_countdown_result.get("ram_image", PackedByteArray())
	if not bool(scratch_countdown_result.get("ok", false)) \
			or String(scratch_countdown_result.get("status", "")) != "returned_after_countdown" \
			or int(scratch_countdown_result.get("countdown_before", -1)) != 0x03 \
			or int(scratch_countdown_result.get("countdown_after", -1)) != 0x02 \
			or scratch_countdown_output.size() != 0x800 \
			or int(scratch_countdown_output[0x003A]) != 0x0F \
			or scratch_countdown_output.slice(0x0498, 0x04A0) != countdown_ram.slice(0x0498, 0x04A0) \
			or int(scratch_countdown_output[0x0533]) != 0x02:
		return _fail("The source countdown incorrectly depends on or modifies unused `$003A` scratch state: " + str({
			"status": scratch_countdown_result.get("status"), "reason": scratch_countdown_result.get("reason"),
			"003A": scratch_countdown_output[0x003A] if scratch_countdown_output.size() == 0x800 else -1,
			"0533": scratch_countdown_output[0x0533] if scratch_countdown_output.size() == 0x800 else -1}))
	var root_result: Dictionary = executor.call("execute_from_86f8_worker_result", countdown_result)
	if not bool(root_result.get("ok", false)) \
			or String(root_result.get("status", "")) != "returned_before_next_worker_call" \
			or int(root_result.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(root_result, countdown_result):
		return _fail("The strict live-PASS countdown did not run `$EBB3->$8006->$8779->$EBC5`: " + String(root_result.get("reason", "state mismatch")))
	var wrong_holder := countdown_result.duplicate(true)
	var wrong_holder_ram: PackedByteArray = countdown_ram.duplicate()
	wrong_holder_ram[0x0441] = 0x0A
	wrong_holder["ram_image"] = wrong_holder_ram
	var rejected_holder: Dictionary = executor.call("execute_from_86f8_worker_result", wrong_holder)
	if bool(rejected_holder.get("ok", true)) \
			or String(rejected_holder.get("status", "")) != "rejected_input":
		return _fail("The strict live-PASS countdown accepted an already-transferred holder `$0A`.")

	# This separate fixture starts at the source `$AFE9` batch boundary after the
	# preceding countdown reaches zero and the NMI-owned queue is empty. It tests
	# the ROM batch/caller contract, not the full inter-frame/NMI route cadence.
	var batch_input := prefix_result.duplicate(true)
	var batch_input_ram: PackedByteArray = input_ram.duplicate()
	batch_input_ram[0x0533] = 0x00
	batch_input_ram[0x003A] = 0x0F
	batch_input["ram_image"] = batch_input_ram
	var batch_result: Dictionary = previous_worker.call("execute_from_slot09_resume_result", batch_input)
	var batch_ram: PackedByteArray = batch_result.get("ram_image", PackedByteArray())
	if not bool(batch_result.get("ok", false)) \
			or String(batch_result.get("status", "")) != "returned_after_stream_batch" \
			or int(batch_result.get("input_ram_0532", -1)) != 0x01 \
			or int(batch_result.get("output_ram_0532", -1)) != 0x01 \
			or int(batch_result.get("stream_pointer_before", -1)) != 0xAFE9 \
			or int(batch_result.get("stream_control", -1)) != 0x0A \
			or int(batch_result.get("stream_pair_count", -1)) != 2 \
			or int(batch_result.get("countdown_after", -1)) != 1 \
			or int(batch_result.get("stream_pointer_after", -1)) != 0xAFEE \
			or batch_ram.size() != 0x800 \
			or batch_ram.slice(0x0516, 0x051A) != PackedByteArray([0x00, 0x40, 0x38, 0x00]) \
			or int(batch_ram[0x0441]) != 0x06 \
			or int(batch_ram[0x0533]) != 0x01 \
			or int(batch_ram[0x003A]) != 0 \
			or int(batch_ram[0x0498]) != 1 \
			or batch_ram.slice(0x0499, 0x049C) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or PackedByteArray(batch_result.get("inline_queue_record", PackedByteArray())) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or int(batch_ram[0x047F]) != 0x0F:
		return _fail("The strict live-PASS `$AFE9` stream batch did not produce the exact two-pair/countdown/queue result: " + str({
				"status": batch_result.get("status"), "reason": batch_result.get("reason"),
				"control_pairs": [batch_result.get("stream_control"), batch_result.get("stream_pair_count")],
				"pointer": [batch_result.get("stream_pointer_before"), batch_result.get("stream_pointer_after")],
				"queue": batch_ram.slice(0x0498, 0x049C).hex_encode() if batch_ram.size() == 0x800 else "invalid"}))
	if not _has_worker_write(batch_result.get("memory_writes", []), 0x8743, 0x003A, 0x02):
		return _fail("The zero-countdown `$8723` parser did not replace scratch `$003A` with the ROM-derived two-pair count before use.")
	var batch_root_result: Dictionary = executor.call("execute_from_86f8_worker_result", batch_result)
	if not bool(batch_root_result.get("ok", false)) \
			or String(batch_root_result.get("status", "")) != "returned_before_next_worker_call" \
			or int(batch_root_result.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(batch_root_result, batch_result):
		return _fail("The live-PASS `$AFE9` batch did not run the source caller through `$EBC5`: " + String(batch_root_result.get("reason", "state mismatch")))
	var afee_tick_input := prefix_result.duplicate(true)
	var afee_tick_ram: PackedByteArray = input_ram.duplicate()
	afee_tick_ram[0x0079] = 0xEE
	afee_tick_ram[0x007A] = 0xAF
	afee_tick_ram[0x0533] = 0x01
	afee_tick_input["ram_image"] = afee_tick_ram
	var afee_tick_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", afee_tick_input)
	var afee_tick_output: PackedByteArray = afee_tick_result.get("ram_image", PackedByteArray())
	if not bool(afee_tick_result.get("ok", false)) \
			or String(afee_tick_result.get("status", "")) != "returned_after_countdown" \
			or afee_tick_output.size() != 0x800 \
			or int(afee_tick_result.get("countdown_before", -1)) != 1 \
			or int(afee_tick_result.get("countdown_after", -1)) != 0 \
			or (int(afee_tick_output[0x0079]) | (int(afee_tick_output[0x007A]) << 8)) != 0xAFEE:
		return _fail("The source `$AFEE` positive timer tick did not decrement `$0533` and preserve its stream pointer: " + String(afee_tick_result.get("reason", "state mismatch")))
	var afee_tick_root: Dictionary = executor.call("execute_from_86f8_worker_result", afee_tick_result)
	if not bool(afee_tick_root.get("ok", false)) \
			or String(afee_tick_root.get("status", "")) != "returned_before_next_worker_call" \
			or int(afee_tick_root.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(afee_tick_root, afee_tick_result):
		return _fail("The source `$AFEE` timer tick was rejected at the `$8779` caller: " + String(afee_tick_root.get("reason", "state mismatch")))
	var afee_batch_input := prefix_result.duplicate(true)
	var afee_input_ram: PackedByteArray = batch_ram.duplicate()
	afee_input_ram[0x0533] = 0x00
	afee_input_ram[0x0498] = 0x00
	afee_batch_input["ram_image"] = afee_input_ram
	var afee_batch_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", afee_batch_input)
	var afee_batch_ram: PackedByteArray = afee_batch_result.get("ram_image", PackedByteArray())
	if not bool(afee_batch_result.get("ok", false)) \
			or String(afee_batch_result.get("status", "")) != "returned_after_stream_batch" \
			or int(afee_batch_result.get("stream_pointer_before", -1)) != 0xAFEE \
			or int(afee_batch_result.get("stream_control", -1)) != 0x39 \
			or int(afee_batch_result.get("stream_pair_count", -1)) != 1 \
			or int(afee_batch_result.get("countdown_after", -1)) != 7 \
			or int(afee_batch_result.get("stream_pointer_after", -1)) != 0xAFF1 \
			or afee_batch_ram.size() != 0x800 \
			or int(afee_batch_ram[0x0533]) != 7 \
			or int(afee_batch_ram[0x0498]) != 1 \
			or int(afee_batch_ram[0x0485]) != 0x30:
		return _fail("The live-PASS `$AFEE` one-pair/countdown-seven batch did not match the ROM bytes: " + str({
			"status": afee_batch_result.get("status"), "reason": afee_batch_result.get("reason"),
			"control": afee_batch_result.get("stream_control"),
			"pair_count": afee_batch_result.get("stream_pair_count"),
			"countdown": afee_batch_result.get("countdown_after"),
			"pointer": [afee_batch_result.get("stream_pointer_before"), afee_batch_result.get("stream_pointer_after")]}))
	if not _has_worker_write(afee_batch_result.get("memory_writes", []), 0x874C, 0x0485, 0x30):
		return _fail("The `$AFEE` stream batch did not log its ROM-selected `$046F+$16` pair write.")
	var afee_root_result: Dictionary = executor.call("execute_from_86f8_worker_result", afee_batch_result)
	if not bool(afee_root_result.get("ok", false)) \
			or String(afee_root_result.get("status", "")) != "returned_before_next_worker_call" \
			or int(afee_root_result.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(afee_root_result, afee_batch_result):
		return _fail("The live-PASS `$AFEE` batch did not run the source caller through `$EBC5`: " + String(afee_root_result.get("reason", "state mismatch")))
	var aff1_tick_input := prefix_result.duplicate(true)
	var aff1_tick_ram: PackedByteArray = input_ram.duplicate()
	aff1_tick_ram[0x0079] = 0xF1
	aff1_tick_ram[0x007A] = 0xAF
	aff1_tick_ram[0x0533] = 0x07
	aff1_tick_input["ram_image"] = aff1_tick_ram
	var aff1_tick_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", aff1_tick_input)
	var aff1_tick_output: PackedByteArray = aff1_tick_result.get("ram_image", PackedByteArray())
	if not bool(aff1_tick_result.get("ok", false)) \
			or String(aff1_tick_result.get("status", "")) != "returned_after_countdown" \
			or aff1_tick_output.size() != 0x800 \
			or int(aff1_tick_result.get("countdown_before", -1)) != 7 \
			or int(aff1_tick_result.get("countdown_after", -1)) != 6 \
			or (int(aff1_tick_output[0x0079]) | (int(aff1_tick_output[0x007A]) << 8)) != 0xAFF1:
		return _fail("The source `$AFF1` positive timer tick did not decrement `$0533` and preserve its stream pointer: " + String(aff1_tick_result.get("reason", "state mismatch")))
	var aff1_tick_root: Dictionary = executor.call("execute_from_86f8_worker_result", aff1_tick_result)
	if not bool(aff1_tick_root.get("ok", false)) \
			or String(aff1_tick_root.get("status", "")) != "returned_before_next_worker_call" \
			or int(aff1_tick_root.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(aff1_tick_root, aff1_tick_result):
		return _fail("The source `$AFF1` timer tick was rejected at the `$8779` caller: " + String(aff1_tick_root.get("reason", "state mismatch")))
	var aff1_batch_input := prefix_result.duplicate(true)
	var aff1_input_ram: PackedByteArray = afee_batch_ram.duplicate()
	aff1_input_ram[0x0533] = 0x00
	aff1_input_ram[0x0498] = 0x00
	aff1_batch_input["ram_image"] = aff1_input_ram
	var aff1_batch_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", aff1_batch_input)
	var aff1_batch_ram: PackedByteArray = aff1_batch_result.get("ram_image", PackedByteArray())
	if not bool(aff1_batch_result.get("ok", false)) \
			or String(aff1_batch_result.get("status", "")) != "returned_after_stream_batch" \
			or int(aff1_batch_result.get("stream_pointer_before", -1)) != 0xAFF1 \
			or int(aff1_batch_result.get("stream_control", -1)) != 0x19 \
			or int(aff1_batch_result.get("stream_pair_count", -1)) != 1 \
			or int(aff1_batch_result.get("countdown_after", -1)) != 3 \
			or int(aff1_batch_result.get("stream_pointer_after", -1)) != 0xAFF4 \
			or aff1_batch_ram.size() != 0x800 \
			or int(aff1_batch_ram[0x0533]) != 3 \
			or int(aff1_batch_ram[0x0498]) != 1 \
			or int(aff1_batch_ram[0x0485]) != 0x0F:
		return _fail("The live-PASS `$AFF1` one-pair/countdown-three batch did not match the ROM bytes: " + str({
			"status": aff1_batch_result.get("status"), "reason": aff1_batch_result.get("reason"),
			"control": aff1_batch_result.get("stream_control"),
			"pair_count": aff1_batch_result.get("stream_pair_count"),
			"countdown": aff1_batch_result.get("countdown_after"),
			"pointer": [aff1_batch_result.get("stream_pointer_before"), aff1_batch_result.get("stream_pointer_after")]}))
	if not _has_worker_write(aff1_batch_result.get("memory_writes", []), 0x874C, 0x0485, 0x0F):
		return _fail("The `$AFF1` stream batch did not log its ROM-selected `$046F+$16` pair write.")
	var aff1_root_result: Dictionary = executor.call("execute_from_86f8_worker_result", aff1_batch_result)
	if not bool(aff1_root_result.get("ok", false)) \
			or String(aff1_root_result.get("status", "")) != "returned_before_next_worker_call" \
			or int(aff1_root_result.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(aff1_root_result, aff1_batch_result):
		return _fail("The live-PASS `$AFF1` batch did not run the source caller through `$EBC5`: " + String(aff1_root_result.get("reason", "state mismatch")))
	var aff4_tick_input := prefix_result.duplicate(true)
	var aff4_tick_ram: PackedByteArray = input_ram.duplicate()
	aff4_tick_ram[0x0079] = 0xF4
	aff4_tick_ram[0x007A] = 0xAF
	aff4_tick_ram[0x0533] = 0x03
	aff4_tick_input["ram_image"] = aff4_tick_ram
	var aff4_tick_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", aff4_tick_input)
	var aff4_tick_output: PackedByteArray = aff4_tick_result.get("ram_image", PackedByteArray())
	if not bool(aff4_tick_result.get("ok", false)) \
			or String(aff4_tick_result.get("status", "")) != "returned_after_countdown" \
			or aff4_tick_output.size() != 0x800 \
			or int(aff4_tick_result.get("countdown_before", -1)) != 0x03 \
			or int(aff4_tick_result.get("countdown_after", -1)) != 0x02 \
			or (int(aff4_tick_output[0x0079]) | (int(aff4_tick_output[0x007A]) << 8)) != 0xAFF4:
		return _fail("The source `$AFF4` selector timer tick did not preserve its pointer and decrement `$0533`: " + String(aff4_tick_result.get("reason", "state mismatch")))
	var aff4_tick_root: Dictionary = executor.call("execute_from_86f8_worker_result", aff4_tick_result)
	if not bool(aff4_tick_root.get("ok", false)) \
			or String(aff4_tick_root.get("status", "")) != "returned_before_next_worker_call" \
			or int(aff4_tick_root.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(aff4_tick_root, aff4_tick_result):
		return _fail("The source `$AFF4` timer tick was rejected at caller `$8779`: " + String(aff4_tick_root.get("reason", "state mismatch")))
	var aff4_batch_input := prefix_result.duplicate(true)
	var aff4_input_ram: PackedByteArray = aff1_batch_ram.duplicate()
	aff4_input_ram[0x0533] = 0x00
	aff4_input_ram[0x0498] = 0x00
	aff4_batch_input["ram_image"] = aff4_input_ram
	var aff4_batch_result: Dictionary = previous_worker.call(
		"execute_from_slot09_resume_result", aff4_batch_input)
	var aff4_batch_ram: PackedByteArray = aff4_batch_result.get("ram_image", PackedByteArray())
	var aff4_source_reads: Array = aff4_batch_result.get("source_reads", [])
	if not bool(aff4_batch_result.get("ok", false)) \
			or String(aff4_batch_result.get("status", "")) != "returned_after_stream_batch" \
			or int(aff4_batch_result.get("selector_redirect_from", -1)) != 0xAFF4 \
			or int(aff4_batch_result.get("selector_redirect_to", -1)) != 0xAFEE \
			or bool(aff4_batch_result.get("selector_arm_appended_queue", true)) \
			or int(aff4_batch_result.get("stream_pointer_before", -1)) != 0xAFF4 \
			or int(aff4_batch_result.get("stream_control", -1)) != 0x39 \
			or int(aff4_batch_result.get("stream_pair_count", -1)) != 1 \
			or int(aff4_batch_result.get("countdown_after", -1)) != 7 \
			or int(aff4_batch_result.get("stream_pointer_after", -1)) != 0xAFF1 \
			or aff4_batch_ram.size() != 0x800 \
			or int(aff4_batch_ram[0x0533]) != 7 or int(aff4_batch_ram[0x003A]) != 0 \
			or int(aff4_batch_ram[0x0498]) != 1 \
			or aff4_batch_ram.slice(0x0499, 0x049C) != PackedByteArray([0x00, 0x6C, 0x04]) \
			or int(aff4_batch_ram[0x0485]) != 0x30 \
			or not _has_worker_source_read(aff4_source_reads, 0xAFF5, 0xEE, "stream_redirect_low") \
			or not _has_worker_source_read(aff4_source_reads, 0xAFF6, 0xAF, "stream_redirect_high") \
			or not _has_worker_write(aff4_batch_result.get("memory_writes", []), 0x8772, 0x007A, 0xAF) \
			or not _has_worker_write(aff4_batch_result.get("memory_writes", []), 0x8774, 0x0079, 0xEE):
		return _fail("The live `$AFF4->$AFEE` selector cycle did not redirect and execute the one-append `$AFEE` batch: " + str({
			"status": aff4_batch_result.get("status"), "reason": aff4_batch_result.get("reason"),
			"redirect": [aff4_batch_result.get("selector_redirect_from"), aff4_batch_result.get("selector_redirect_to"), aff4_batch_result.get("selector_arm_appended_queue")],
			"batch": [aff4_batch_result.get("stream_control"), aff4_batch_result.get("stream_pair_count"), aff4_batch_result.get("countdown_after")],
			"pointer": [aff4_batch_result.get("stream_pointer_before"), aff4_batch_result.get("stream_pointer_after")],
			"RAM": [aff4_batch_ram[0x0533], aff4_batch_ram[0x003A], aff4_batch_ram[0x0485]] if aff4_batch_ram.size() == 0x800 else "invalid",
			"queue": aff4_batch_ram.slice(0x0498, 0x049C).hex_encode() if aff4_batch_ram.size() == 0x800 else "invalid",
			"redirect_reads": [_has_worker_source_read(aff4_source_reads, 0xAFF5, 0xEE, "stream_redirect_low"), _has_worker_source_read(aff4_source_reads, 0xAFF6, 0xAF, "stream_redirect_high")]}))
	if _has_worker_address(aff4_batch_result.get("memory_writes", []), 0x055D):
		return _fail("The `$AFF4` selector was incorrectly treated as a `$055D` pair write.")
	var aff4_root_result: Dictionary = executor.call("execute_from_86f8_worker_result", aff4_batch_result)
	if not bool(aff4_root_result.get("ok", false)) \
			or String(aff4_root_result.get("status", "")) != "returned_before_next_worker_call" \
			or int(aff4_root_result.get("exit_pc", -1)) != 0xEBC5 \
			or not _verify_returned_state(aff4_root_result, aff4_batch_result):
		return _fail("The `$AFF4->$AFEE` redirect result did not return through source caller `$8779`: " + String(aff4_root_result.get("reason", "state mismatch")))
	return true


func _has_worker_source_read(reads: Array, address: int, value: int, kind: String) -> bool:
	for read_variant in reads:
		if not read_variant is Dictionary:
			continue
		var read: Dictionary = read_variant
		if int(read.get("address", -1)) == address and int(read.get("value", -1)) == value \
				and String(read.get("kind", "")) == kind:
			return true
	return false


func _make_scenario38_live_pass_dispatch() -> Dictionary:
	var dispatch := _make_scenario38_fb_wait_dispatch()
	var ram: PackedByteArray = (dispatch["ram_image"] as PackedByteArray).duplicate()
	ram[0x003A] = 0x06
	ram[0x0079] = 0xE9
	ram[0x007A] = 0xAF
	ram[0x0441] = 0x06
	ram[0x047F] = 0x0F
	ram[0x0498] = 0x00
	ram[0x0499] = 0x00
	ram[0x049A] = 0x6C
	ram[0x049B] = 0x04
	ram[0x049C] = 0x00
	ram[0x049D] = 0x6C
	ram[0x049E] = 0x04
	ram[0x049F] = 0x00
	ram[0x0516] = 0x00
	ram[0x0517] = 0x40
	ram[0x0518] = 0x38
	ram[0x0519] = 0x00
	ram[0x0532] = 0x01
	ram[0x0533] = 0x03
	dispatch["ram_image"] = ram
	dispatch["fixture_only"] = true
	dispatch["trace_state_used"] = false
	return dispatch


func _make_scenario38_fb_wait_dispatch() -> Dictionary:
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
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x09,
		"resume_path": "yielded_rts",
		"pc": 0xEB8B,
		"sp": 0x7A,
		"a": 0x78,
		"x": 0x78,
		"y": 0x05,
		"p": 0x00,
		"p_known_mask": 0,
		"bank_low": 0x18,
		"bank_high": 0x19,
		"task_record": PackedByteArray([0x00, 0x76, 0x18, 0x19]),
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07},
		"ram_image": ram,
		"stack_page": stack,
		"fixture_only": true,
		"trace_state_used": false,
	}


func _verify_returned_state(result: Dictionary, previous_result: Dictionary) -> bool:
	var input_ram: PackedByteArray = previous_result["ram_image"]
	var input_stack: PackedByteArray = previous_result["stack_page"]
	var input_mapper: Dictionary = previous_result["mapper"]
	var root_entry_a := int(previous_result.get("registers", {}).get("a", -1))
	var base: int = int(input_ram[0x0022])
	var select6 := (base | 0x06) & 0xFF
	var select7 := (base | 0x07) & 0xFF
	var selected6 := select6 & 0x07
	var selected7 := select7 & 0x07
	var expected_ram := input_ram.duplicate()
	expected_ram[0x0024] = 0x18
	expected_ram[0x0025] = 0x19
	expected_ram[0x0023] = select7
	var expected_ram_writes: Array[Dictionary] = [
		{"pc": 0xEBB8, "address": 0x0024, "value": 0x18, "kind": "ram"},
		{"pc": 0xEBBC, "address": 0x0025, "value": 0x19, "kind": "ram"},
		{"pc": 0xCE31, "address": 0x0023, "value": select6, "kind": "ram"},
		{"pc": 0xCE3F, "address": 0x0023, "value": select7, "kind": "ram"},
	]
	var expected_mapper_writes: Array[Dictionary] = [
		{"pc": 0xCE33, "address": 0x8000, "value": select6, "select": selected6, "kind": "register_select"},
		{"pc": 0xCE38, "address": 0x8001, "value": 0x18, "select": selected6, "kind": "register_data"},
		{"pc": 0xCE41, "address": 0x8000, "value": select7, "select": selected7, "kind": "register_select"},
		{"pc": 0xCE46, "address": 0x8001, "value": 0x19, "select": selected7, "kind": "register_data"},
	]
	var expected_pcs: Array[int] = [
		0xEBB3, 0xEBB4, 0xEBB6, 0xEBB8, 0xEBBA, 0xEBBC, 0xEBBE,
		0xCE2D, 0xCE2F, 0xCE31, 0xCE33, 0xCE36, 0xCE38, 0xCE3B,
		0xCE3D, 0xCE3F, 0xCE41, 0xCE44, 0xCE46, 0xCE49,
		0xEBC1, 0xEBC2, 0x8006, 0x8779, 0x877C, 0x87A3,
	]
	var expected_stack_writes: Array[Dictionary] = [
		{"pc": 0xEBB3, "address": 0x017A, "value": root_entry_a, "kind": "PHA"},
		{"pc": 0xEBBE, "address": 0x0179, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBBE, "address": 0x0178, "value": 0xC0, "kind": "JSR_low"},
		{"pc": 0xEBC2, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBC2, "address": 0x0179, "value": 0xC4, "kind": "JSR_low"},
	]
	var expected_stack_reads: Array[Dictionary] = [
		{"pc": 0xCE49, "address": 0x0178, "value": 0xC0, "kind": "RTS_low"},
		{"pc": 0xCE49, "address": 0x0179, "value": 0xEB, "kind": "RTS_high"},
		{"pc": 0xEBC1, "address": 0x017A, "value": root_entry_a, "kind": "PLA"},
		{"pc": 0x87A3, "address": 0x0179, "value": 0xC4, "kind": "RTS_low"},
		{"pc": 0x87A3, "address": 0x017A, "value": 0xEB, "kind": "RTS_high"},
	]
	var expected_mapper: Dictionary = input_mapper.duplicate(true)
	var expected_worker_nz := P_Z if root_entry_a == 0 else (P_N if (root_entry_a & 0x80) != 0 else 0)
	var expected_bank_registers: Dictionary = expected_mapper.get("bank_registers", {}).duplicate(true)
	expected_bank_registers[selected6] = 0x18
	expected_bank_registers[selected7] = 0x19
	expected_mapper["bank_registers"] = expected_bank_registers
	expected_mapper["bank_low"] = 0x18 if selected6 == 6 else int(input_mapper.get("bank_low", -1))
	expected_mapper["bank_high"] = 0x19 if selected7 == 7 else int(input_mapper.get("bank_high", -1))
	expected_mapper["select"] = selected7
	var entry_registers: Dictionary = result.get("entry_registers", {})
	var worker_entry_registers: Dictionary = result.get("worker_entry_registers", {})
	var registers: Dictionary = result.get("registers", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	if String(result.get("status", "")) != "returned_before_next_worker_call" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0xEBB3 \
			or int(result.get("worker_entry_pc", -1)) != 0x8779 \
			or int(result.get("input_ram_0534", -1)) != int(input_ram[0x0534]) \
			or int(input_ram[0x0534]) != 0 \
			or int(entry_registers.get("pc", -1)) != 0xEBB3 \
			or int(entry_registers.get("sp", -1)) != 0x7A \
			or int(worker_entry_registers.get("pc", -1)) != 0x8779 \
			or int(worker_entry_registers.get("sp", -1)) != 0x78 \
			or int(worker_entry_registers.get("a", -1)) != root_entry_a \
			or int(worker_entry_registers.get("x", -1)) != int(entry_registers.get("x", -2)) \
			or int(worker_entry_registers.get("y", -1)) != int(entry_registers.get("y", -2)) \
			or (int(worker_entry_registers.get("p", -1)) & (P_N | P_Z)) != expected_worker_nz \
			or int(result.get("exit_pc", -1)) != 0xEBC5 \
			or int(registers.get("pc", -1)) != 0xEBC5 \
			or int(registers.get("sp", -1)) != 0x7A \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("x", -1)) != int(entry_registers.get("x", -2)) \
			or int(registers.get("y", -1)) != int(entry_registers.get("y", -2)) \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & (P_N | P_Z)) != (P_N | P_Z) \
			or result.get("instruction_pcs", []) != expected_pcs \
			or result.get("ram_writes", []) != expected_ram_writes \
			or result.get("stack_writes", []) != expected_stack_writes \
			or result.get("stack_reads", []) != expected_stack_reads \
			or result.get("mapper_writes", []) != expected_mapper_writes \
			or output_ram != expected_ram \
			or output_stack.slice(0x78, 0x7B) != PackedByteArray([0xC0, 0xC4, 0xEB]) \
			or result.get("mapper", {}) != expected_mapper \
			or int(result.get("worker_return_word", -1)) != 0xEBC4 \
			or int(result.get("worker_return_pc", -1)) != 0xEBC5 \
			or bool(result.get("next_worker_call_executed", true)) \
			or bool(result.get("next_worker_body_bytes_read", true)) \
			or result.get("ppu_bus_events", []) != [] \
			or result.get("apu_register_writes", []) != [] \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)):
		return _fail("`$8779` result differs from the ROM-supported branch/return contract: " + str({
				"entry_registers": entry_registers, "worker_entry_registers": worker_entry_registers,
				"registers": registers, "input_ram_0022": base, "input_ram_0534": input_ram[0x0534],
				"exit_pc": result.get("exit_pc"), "instruction_pcs": result.get("instruction_pcs"),
				"ram_writes": result.get("ram_writes"), "mapper_writes": result.get("mapper_writes"),
				"mapper": result.get("mapper"), "expected_mapper": expected_mapper,
				"stack_reads": result.get("stack_reads"), "stack_writes": result.get("stack_writes"),
				"next_worker_body_bytes_read": result.get("next_worker_body_bytes_read")}))
	return true


func _verify_rejected_inputs(executor: Variant, previous_result: Dictionary) -> bool:
	var nonzero := previous_result.duplicate(true)
	var nonzero_ram: PackedByteArray = (previous_result["ram_image"] as PackedByteArray).duplicate()
	nonzero_ram[0x0534] = 1
	nonzero["ram_image"] = nonzero_ram
	var unsupported: Dictionary = executor.execute_from_86f8_worker_result(nonzero)
	if bool(unsupported.get("ok", true)) \
			or String(unsupported.get("status", "")) != "unsupported_branch" \
			or int(unsupported.get("exit_pc", -1)) != 0x877E \
			or int(unsupported.get("input_ram_0534", -1)) != 1 \
			or bool(unsupported.get("next_worker_call_executed", true)) \
			or bool(unsupported.get("next_worker_body_bytes_read", true)):
		return _fail("Nonzero `$0534` did not stop at the unresolved `$877E` branch.")

	var invalid_stack := previous_result.duplicate(true)
	var bad_stack: PackedByteArray = (previous_result["stack_page"] as PackedByteArray).duplicate()
	bad_stack[0x79] = (int(bad_stack[0x79]) + 1) & 0xFF
	invalid_stack["stack_page"] = bad_stack
	var rejected: Dictionary = executor.execute_from_86f8_worker_result(invalid_stack)
	if bool(rejected.get("ok", true)) or String(rejected.get("status", "")) != "rejected_input":
		return _fail("Mismatched live `$EBB2->$EBB3` return stack was not rejected.")
	return true


func _has_worker_write(writes: Array, pc: int, address: int, value: int) -> bool:
	for row_variant in writes:
		if row_variant is Dictionary and int(row_variant.get("pc", -1)) == pc \
				and int(row_variant.get("address", -1)) == address \
				and int(row_variant.get("value", -1)) == value:
			return true
	return false


func _has_worker_address(writes: Array, address: int) -> bool:
	for row_variant in writes:
		if row_variant is Dictionary and int(row_variant.get("address", -1)) == address:
			return true
	return false


func _fail(message: String) -> bool:
	push_error(message)
	return false
