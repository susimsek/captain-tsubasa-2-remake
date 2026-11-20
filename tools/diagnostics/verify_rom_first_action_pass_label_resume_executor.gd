extends SceneTree
## Carries a source-derived PASS confirmation through its scheduler-dispatched
## `$E945` resume and checks the ROM-built label packets in the secondary queue.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const DISPATCHER_SCRIPT := preload("res://scripts/gameplay/rom_first_action_dispatch_executor.gd")
const BRIDGE_SCRIPT := preload("res://scripts/gameplay/rom_first_action_confirmation_bridge_executor.gd")
const LABEL_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_first_action_pass_label_resume_executor.gd")
const PASS_CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_pass_no_candidates_continuation_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scheduler = SCHEDULER_SCRIPT.new()
	var dispatcher = DISPATCHER_SCRIPT.new()
	var bridge = BRIDGE_SCRIPT.new()
	var label_executor = LABEL_EXECUTOR_SCRIPT.new()
	if not scheduler.configure_from_project_sources() \
			or scheduler.initialize_fresh_game_bootstrap().is_empty():
		_fail("Scheduler ROM source bootstrap failed: " + String(scheduler.error_message))
		return
	if not dispatcher.configure_from_project_sources() \
			or not bridge.configure_from_project_sources() \
			or not label_executor.configure_from_project_sources():
		_fail("ROM-byte dispatcher/bridge/label-source configuration failed: " \
			+ String(dispatcher.error_message) + " " + String(bridge.error_message) \
			+ " " + String(label_executor.error_message))
		return
	var context = scheduler._contexts.get(0x05)
	if context == null:
		_fail("The source-seeded slot-$05 scheduler context is missing.")
		return
	_make_d5ea_source_fixture(scheduler, context)
	var left_sample_result: Dictionary = scheduler.sample_controller_input(0x02)
	if not bool(left_sample_result.get("ok", false)):
		_fail("Source Left sample failed: " + str(left_sample_result))
		return
	var left_sample: Dictionary = left_sample_result["sample"]
	var selection: Dictionary = dispatcher.execute_from_live_action_menu_boundary(
		scheduler.get_task_boundary_snapshot(0x05), left_sample)
	var adopted_selection: Dictionary = scheduler.adopt_first_action_menu_input_result(selection)
	if not bool(adopted_selection.get("ok", false)) \
			or String(adopted_selection.get("accepted_status", "")) != "pass_selection_applied":
		_fail("The source-derived PASS selection fixture was not adopted: " + str(adopted_selection))
		return
	if not bool(scheduler.sample_controller_input(0).get("ok", false)):
		_fail("Controller release sample failed.")
		return
	var confirm_sample_result: Dictionary = scheduler.sample_controller_input(0x80)
	if not bool(confirm_sample_result.get("ok", false)):
		_fail("A-confirm controller sample failed: " + str(confirm_sample_result))
		return
	var confirm_sample: Dictionary = confirm_sample_result["sample"]
	var confirmation: Dictionary = dispatcher.execute_from_live_action_menu_boundary(
		scheduler.get_task_boundary_snapshot(0x05), confirm_sample)
	var adoption: Dictionary = scheduler.adopt_first_action_menu_input_result(confirmation)
	if not bool(adoption.get("ok", false)) \
			or String(adoption.get("status", "")) != "pass_confirmation_pending_source_execution" \
			or int(context.program_counter) != 0xD5EA:
		_fail("The scheduler did not consume A while preserving its D5EA boundary: " + str(adoption))
		return
	var confirmation_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var bridge_result: Dictionary = bridge.execute_from_consumed_pass_confirmation(
		confirmation_boundary, confirm_sample, adoption)
	if not bool(bridge_result.get("ok", false)) \
			or String(bridge_result.get("status", "")) != "pass_confirmation_yielded_waiting_for_scheduler_nmi":
		_fail("The source bridge did not stop at its proven CB0F scheduler handoff: " + str(bridge_result))
		return
	var yield_adoption: Dictionary = scheduler.adopt_first_action_confirmation_bridge_yield(bridge_result)
	if not bool(yield_adoption.get("ok", false)):
		_fail("The scheduler rejected the source CB0F yield: " + str(yield_adoption))
		return
	# The preceding bridge receipt proves CAA5 yielded at E945 and leaves the
	# normal scheduler cursor at slot 09. This focused diagnostic positions its
	# next scan on slot 05 to exercise the actual ready-delay decrement/dispatch;
	# it does not claim a normal NMI cadence or a complete route frame.
	scheduler._scheduler_scan_cursor = 0x05
	var scan: Dictionary = scheduler.scan_ready_tasks_once()
	var delay_rows: PackedByteArray = scan.get("ready_delays_after", PackedByteArray())
	if not bool(scan.get("ok", false)) \
			or int(scan.get("decision", -1)) != 1 \
			or int(scan.get("selected_slot_base", -1)) != 0x05 \
			or scan.get("checked_slots", []) != [0x05] \
			or delay_rows.size() != 6 or int(delay_rows[1]) != 0:
		_fail("Scheduler did not turn the yielded slot-$05 delay into a dispatch: " + str(scan))
		return
	var dispatch: Dictionary = scheduler.dispatch_pending_task(0x05)
	var live_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	if not bool(dispatch.get("ok", false)) \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xE945 \
			or int(dispatch.get("source_return_word", -1)) != 0xE944 \
			or int(live_boundary.get("pc", -1)) != 0xE945:
		_fail("Scheduler dispatch did not produce the genuine slot-$05 `$E945` continuation: " + str(dispatch))
		return
	var result: Dictionary = label_executor.execute_from_scheduler_dispatched_pass_label(
		dispatch, live_boundary)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_action_label_queued":
		_fail("ROM action-label renderer did not finish its source span: " + str(result))
		return
	if not _assert_pass_result(result, dispatch, live_boundary):
		return
	if not _assert_queue_write_events(result):
		return
	var renderer_adoption: Dictionary = scheduler.adopt_first_action_pass_label_renderer_result(result)
	var returned_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var adopted_ram: PackedByteArray = returned_boundary.get("ram_image", PackedByteArray())
	if not bool(renderer_adoption.get("ok", false)) \
			or String(renderer_adoption.get("status", "")) != "pass_action_label_renderer_adopted" \
			or int(returned_boundary.get("pc", -1)) != 0xD68A \
			or int(returned_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(adopted_ram[0x0515]) != 0x80 \
			or PackedByteArray(adopted_ram.slice(0x04A5, 0x04B6)) \
			!= PackedByteArray(result.get("ppu_queue_buffer_bytes", PackedByteArray())):
		_fail("Scheduler did not replay the ROM renderer's ordered RAM/queue writes into its live `$D68A` context: " + str(renderer_adoption))
		return
	var renderer_receipt: Dictionary = result.duplicate(true)
	renderer_receipt["callsite_pc"] = 0xD687
	renderer_receipt["return_pc"] = 0xD68A
	renderer_receipt["returned_via_rts"] = true
	renderer_receipt["receipt_id"] = "focused-pass-label-return"
	renderer_receipt["returned_boundary"] = returned_boundary.duplicate(true)
	var continuation = PASS_CONTINUATION_SCRIPT.new()
	if not continuation.configure_from_project_sources():
		_fail("PASS continuation source setup failed: " + String(continuation.error_message))
		return
	var continuation_result: Dictionary = continuation.execute_from_live_e945_renderer_return(
		returned_boundary, renderer_receipt)
	if not bool(continuation_result.get("ok", false)) \
			or String(continuation_result.get("status", "")) != "pass_no_candidates_reached_live_d6c7":
		_fail("The live D68A renderer boundary did not continue through the ROM no-candidates caller: " + str(continuation_result))
		return
	var continuation_adoption: Dictionary = scheduler.adopt_first_action_pass_no_candidates_result(
		continuation_result)
	var d6c7_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	if not bool(continuation_adoption.get("ok", false)) \
			or int(d6c7_boundary.get("pc", -1)) != 0xD6C7 \
			or int(d6c7_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(d6c7_boundary.get("bank_low", -1)) != 0x1A \
			or int(d6c7_boundary.get("bank_high", -1)) != 0x1B \
			or int(d6c7_boundary.get("mapper", {}).get("bank_registers", {}).get(6, -1)) != 0x1C \
			or int(d6c7_boundary.get("mapper", {}).get("bank_registers", {}).get(7, -1)) != 0x1D:
		_fail("Scheduler rejected ROM no-candidates adoption: " + str(continuation_adoption))
		return
	if not _assert_busy_poll_stops(label_executor, dispatch, live_boundary):
		return
	print("PASS: consumed Left@selection then A reaches scheduler-dispatched slot-$05 `$E945->$D68A` through ROM renderer bytes.")
	print("PASS: ROM label stream emits the exact PASS row packets into `$04A5`; `$0515` becomes `$80`; no PPU bus or NMI is applied.")
	print("PASS: scheduler adopts renderer writes into live slot `$05` at `$D68A` while leaving the PPU transfer to normal NMI.")
	print("PASS: ROM `$D68A->$D6C7` no-candidates caller runs from that live boundary; scheduler retains task banks `$1A/$1B` separately from mapped banks `$1C/$1D`.")
	print("PASS: nonzero `$0515` explicitly stops at `$E940` and reports the required `$CB0F` re-yield without writes.")
	print("LIMIT: the focused scheduler scan cursor is positioned at slot `$05`; ordinary NMI cadence and full recorded-input route remain outside this verifier.")
	quit(0)


func _assert_pass_result(result: Dictionary, dispatch: Dictionary,
		boundary: Dictionary) -> bool:
	var expected_bytes := PackedByteArray([
		0x05, 0xAC, 0x22, 0x00, 0x20, 0x00, 0x00, 0x00,
		0x05, 0xCC, 0x22, 0x50, 0x61, 0x73, 0x20, 0x00,
		0x00,
	])
	var packets: Array = result.get("ppu_queue_packets", [])
	var registers: Dictionary = result.get("registers", {})
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0xE945 \
			or int(result.get("exit_pc", -1)) != 0xD68A \
			or int(result.get("source_return_word", -1)) != 0xE944 \
			or int(registers.get("pc", -1)) != 0xD68A \
			or int(registers.get("a", -1)) != 0x80 \
			or int(registers.get("x", -1)) != 0x10 \
			or int(registers.get("y", -1)) != 0x0B \
			or int(registers.get("sp", -1)) != ((int(boundary.get("sp", -1)) + 4) & 0xFF) \
			or int(result.get("exit_sp", -1)) != int(registers.get("sp", -2)) \
			or int(result.get("queue_ready_flag_before", -1)) != 0 \
			or int(result.get("queue_ready_flag_after", -1)) != 0x80 \
			or int(result.get("ppu_queue_buffer_length", -1)) != 17 \
			or PackedByteArray(result.get("ppu_queue_buffer_bytes", PackedByteArray())) != expected_bytes \
			or packets.size() != 2 \
			or int(packets[0].get("ppu_address", -1)) != 0x22AC \
			or PackedByteArray(packets[0].get("tiles", PackedByteArray())) != PackedByteArray([0, 0x20, 0, 0, 0]) \
			or int(packets[1].get("ppu_address", -1)) != 0x22CC \
			or PackedByteArray(packets[1].get("tiles", PackedByteArray())) != PackedByteArray([0x50, 0x61, 0x73, 0x20, 0]) \
			or bool(result.get("ppu_bus_writes_applied", true)) \
			or bool(result.get("normal_nmi_applied", true)) \
			or bool(result.get("runtime_mutation_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)):
		_fail("Renderer exit, exact PASS stream packet bytes, or no-injection flags differ from the source result: " + str(result))
		return false
	return true


func _assert_queue_write_events(result: Dictionary) -> bool:
	var expected := [
		[0x04A5, 0x05], [0x04A6, 0xAC], [0x04A7, 0x22],
		[0x04A8, 0x00], [0x04A9, 0x20], [0x04AA, 0x00],
		[0x04AB, 0x00], [0x04AC, 0x00], [0x04AD, 0x00],
		[0x04AD, 0x05], [0x04AE, 0xCC], [0x04AF, 0x22],
		[0x04B0, 0x50], [0x04B1, 0x61], [0x04B2, 0x73],
		[0x04B3, 0x20], [0x04B4, 0x00], [0x04B5, 0x00],
	]
	var writes: Array = result.get("ppu_queue_buffer_writes", [])
	if writes.size() != expected.size():
		_fail("Renderer did not retain the ROM-ordered stores, including the overwritten inter-row zero.")
		return false
	for index in expected.size():
		var event: Dictionary = writes[index]
		if int(event.get("address", -1)) != int(expected[index][0]) \
				or int(event.get("value", -1)) != int(expected[index][1]):
			_fail("ROM queue write event %d differs from the source renderer." % index)
			return false
	return true


func _assert_busy_poll_stops(label_executor: Variant, dispatch: Dictionary,
		boundary: Dictionary) -> bool:
	var busy_boundary := boundary.duplicate(true)
	var busy_ram: PackedByteArray = busy_boundary["ram_image"]
	busy_ram[0x0515] = 0x01
	busy_boundary["ram_image"] = busy_ram
	var result: Dictionary = label_executor.execute_from_scheduler_dispatched_pass_label(
		dispatch, busy_boundary)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "waiting_for_0515_clear" \
			or int(result.get("exit_pc", -1)) != 0xE940 \
			or int(result.get("yield_callsite_pc", -1)) != 0xE940 \
			or int(result.get("yield_target_pc", -1)) != 0xCB0F \
			or int(result.get("resume_pc_after_yield", -1)) != 0xE945 \
			or not bool(result.get("source_reyield_required", false)) \
			or bool(result.get("state_mutated", true)) \
			or not result.get("source_writes", []).is_empty() \
			or not result.get("ppu_queue_buffer_writes", []).is_empty():
		_fail("Busy `$0515` polling did not stop for a real source re-yield: " + str(result))
		return false
	return true


func _make_d5ea_source_fixture(scheduler: Variant, context: Variant) -> void:
	# This fixture starts from the ordinary ROM-seeded slot-$05 task and uses
	# the ROM input dispatcher plus scheduler adoption for selection/confirmation.
	context.phase = 2
	context.program_counter = 0xD5EA
	context.bank_low = 0x1A
	context.bank_high = 0x1B
	context.stack_pointer = 0x4C
	context.source_label = "source-derived slot-$05 D5EA input fixture"
	scheduler._active_task_slot = 0x05
	scheduler._ram[0x0000] = 0x05
	scheduler._ram[0x0024] = 0x1A
	scheduler._ram[0x0025] = 0x1B
	scheduler._ram[0x0621] = 0
	scheduler._ram[0x043B] = 0
	scheduler._ram[0x0348] = 0x08
	scheduler._ram[0x0349] = 90
	scheduler._ram[0x034A] = 0
	scheduler._ram[0x0441] = 0x06
	scheduler._ram[0x044E] = 0
	scheduler._ram[0x061E] = 0


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
