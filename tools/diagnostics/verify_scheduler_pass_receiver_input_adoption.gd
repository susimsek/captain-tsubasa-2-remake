extends SceneTree
## Verifies live scheduler adoption for ordinary slot-$05 PASS receiver input.
## Fixtures use the pinned ROM executors with synthetic RAM/task state only.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const INPUT_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_input_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var input_executor = INPUT_EXECUTOR_SCRIPT.new()
	if not input_executor.configure_from_project_sources():
		_fail("PASS receiver executor source configuration failed: " + str(input_executor.error_message))
		return
	if not _verify_down_contract(input_executor):
		return
	if not _verify_fresh_a_adoption(input_executor):
		return
	print("PASS: scheduler adopts the live sampler's coherent fresh A receipt `$001C/current=$80`, `$001E/newly_pressed=$80` and stops at `$D70C`.")
	print("PASS: the existing Down edge contract `$001C/$001E=$04/$04` and one-use live scheduler receipt checks remain enforced.")	
	print("LIMIT: both receiver inputs use synthetic slot-$05 task/RAM fixtures; renderer, route, NMI cadence, pixels, and FCEUX parity are not verified.")
	quit(0)


func _verify_down_contract(input_executor: Variant) -> bool:
	var setup := _make_receiver_wait(true)
	if not bool(setup.get("ok", false)):
		_fail("Could not create the source-shaped live receiver wait: " + String(setup.get("error", "unknown")))
		return false
	var scheduler: Variant = setup["scheduler"]
	var context: Variant = setup["context"]
	var sample_result: Dictionary = scheduler.sample_controller_input(0x04)
	if not bool(sample_result.get("ok", false)):
		_fail("Down input sampling failed: " + str(sample_result))
		return false
	var sample: Dictionary = sample_result["sample"]
	if int(sample.get("previous", -1)) != 0 or int(sample.get("current", -1)) != 0x04 \
			or int(sample.get("newly_pressed", -1)) != 0x04 \
			or int(sample.get("held_ram_001c", -1)) != 0x04 \
			or int(sample.get("edge_ram_001e", -1)) != 0x04:
		_fail("Down sample did not produce the source-consistent `$04/$04` latch and receipt.")
		return false
	var source_result: Dictionary = input_executor.execute_after_input_poll(
		_make_executor_boundary(scheduler, sample))
	if not bool(source_result.get("ok", false)) \
			or String(source_result.get("status", "")) != "receiver_down_scan_stopped_at_renderer_call":
		_fail("ROM Down source execution failed: " + str(source_result.get("error", source_result)))
		return false
	var entry_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var adoption: Dictionary = scheduler.adopt_slot05_pass_receiver_input_result(
		entry_boundary, source_result, sample)
	if not bool(adoption.get("ok", false)) \
			or String(adoption.get("status", "")) != "pass_receiver_down_renderer_request_adopted" \
			or int(adoption.get("source_exit_pc", -1)) != 0xEF7F \
			or int(context.program_counter) != 0xEF7F \
			or not bool(scheduler._slot05_pass_receiver_descriptor_1d_worker_pending) \
			or int(scheduler._last_adopted_controller_sample_receipt_id) \
			!= int(sample.get("sample_receipt_id", -1)):
		_fail("The scheduler changed or rejected the existing Down adoption contract: " + str(adoption))
		return false
	var replayed: Dictionary = scheduler.adopt_slot05_pass_receiver_input_result(
		entry_boundary, source_result, sample)
	if bool(replayed.get("ok", true)):
		_fail("The scheduler accepted a replayed Down input receipt.")
		return false
	return true


func _verify_fresh_a_adoption(input_executor: Variant) -> bool:
	var setup := _make_receiver_wait(false)
	if not bool(setup.get("ok", false)):
		_fail("Could not create the A-confirm receiver wait: " + String(setup.get("error", "unknown")))
		return false
	var scheduler: Variant = setup["scheduler"]
	var context: Variant = setup["context"]
	var pre_sample_ram: PackedByteArray = scheduler._ram.duplicate()
	var sample_result: Dictionary = scheduler.sample_controller_input(0x80)
	if not bool(sample_result.get("ok", false)):
		_fail("A-confirm input sampling failed: " + str(sample_result))
		return false
	var sample: Dictionary = sample_result["sample"]
	if int(sample.get("previous", -1)) != 0 or int(sample.get("current", -1)) != 0x80 \
			or int(sample.get("newly_pressed", -1)) != 0x80 \
			or int(sample.get("held_ram_001c", -1)) != 0x80 \
			or int(sample.get("edge_ram_001e", -1)) != 0x80:
		_fail("Fresh A sample did not produce coherent held/current and newly-pressed `$80` masks.")
		return false
	var entry_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var source_result: Dictionary = input_executor.execute_after_input_poll(
		_make_executor_boundary(scheduler, sample))
	if not bool(source_result.get("ok", false)) \
			or String(source_result.get("status", "")) != "receiver_confirmed_at_d70c_before_holder_transfer":
		_fail("ROM A-confirm source execution failed: " + str(source_result.get("error", source_result)))
		return false
	var altered_sample := sample.duplicate(true)
	altered_sample["sample_receipt_id"] = int(sample["sample_receipt_id"]) + 1
	var stale_receipt: Dictionary = scheduler.adopt_slot05_pass_receiver_input_result(
		entry_boundary, source_result, altered_sample)
	if bool(stale_receipt.get("ok", true)) \
			or context.program_counter != 0xD80F \
			or not bool(scheduler._slot05_pass_receiver_input_wait_ready) \
			or scheduler._ram != entry_boundary["ram_image"]:
		_fail("A forged/stale sample receipt was accepted or mutated the live wait state: " + str(stale_receipt))
		return false
	var adoption: Dictionary = scheduler.adopt_slot05_pass_receiver_input_result(
		entry_boundary, source_result, sample)
	var next_boundary: Dictionary = adoption.get("next_boundary_snapshot", {})
	var next_ram: PackedByteArray = next_boundary.get("ram_image", PackedByteArray())
	if not bool(adoption.get("ok", false)) \
			or String(adoption.get("status", "")) != "pass_receiver_confirmation_stopped_at_d70c" \
			or int(adoption.get("source_exit_pc", -1)) != 0xD70C \
			or int(next_boundary.get("pc", -1)) != 0xD70C \
			or int(context.program_counter) != 0xD70C \
			or int(next_ram[0x001C]) != 0x80 or int(next_ram[0x001E]) != 0x80 \
			or int(next_ram[0x05FC]) != 0x0A or int(next_ram[0x0638]) != 0x78 \
			or int(next_ram[0x0441]) != 0x06 \
			or bool(adoption.get("holder_transfer_executed", true)) \
			or int(scheduler._last_adopted_controller_sample_receipt_id) \
			!= int(sample.get("sample_receipt_id", -1)) \
			or scheduler._ram == pre_sample_ram:
		_fail("Scheduler did not adopt the coherent fresh A receipt at the bounded `$D70C` stop: " + str(adoption))
		return false
	var replay: Dictionary = scheduler.adopt_slot05_pass_receiver_input_result(
		entry_boundary, source_result, sample)
	if bool(replay.get("ok", true)):
		_fail("The scheduler accepted the already-consumed fresh A receipt twice.")
		return false
	return true


func _make_receiver_wait(down_start: bool) -> Dictionary:
	var scheduler: Variant = SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources() \
			or scheduler.initialize_fresh_game_bootstrap().is_empty():
		return {"ok": false, "error": "Scheduler bootstrap failed: " + str(scheduler.error_message)}
	var context: Variant = scheduler._contexts.get(0x05)
	if context == null:
		return {"ok": false, "error": "Source-seeded slot-$05 context is missing."}
	context.phase = 2 # ContextPhase.RUNNING.
	context.ready_delay = 0
	context.pending_resume = 0
	context.program_counter = 0xD80F
	context.stack_pointer = 0x40
	context.accumulator = 0
	context.x_register = 0
	context.y_register = 0
	context.status_register = 0x20
	context.status_known_mask = 0xFF
	context.bank_low = 0x1C
	context.bank_high = 0x1D
	context.source_label = "synthetic slot-$05 `$D80F` receiver wait fixture"
	context.mapper_state = scheduler._restored_slot05_switchable_mapper_pair({}, 0x1C, 0x1D)
	context.mapper_state["fixed_bank"] = 0x1E
	context.mapper_state["cpu_c000_bank"] = 0x1E
	context.mapper_state["cpu_e000_bank"] = 0x1F
	scheduler._active_task_slot = 0x05
	scheduler._ram[0x0000] = 0x05
	scheduler._ram[0x0024] = 0x1C
	scheduler._ram[0x0025] = 0x1D
	scheduler._ram[0x001C] = 0
	scheduler._ram[0x001E] = 0
	scheduler._ram[0x0441] = 0x06
	if down_start:
		scheduler._ram[0x0624] = 0x77
		scheduler._ram[0x0430] = 0
		scheduler._ram[0x0431] = 0
		scheduler._ram[0x0625] = 0
		var receiver_record := 0x0300 + 0x0A * 0x0C
		scheduler._ram[receiver_record + 6] = 0x80
		scheduler._ram[receiver_record + 8] = 0x50
		var last_record := 0x0300 + 0x15 * 0x0C
		scheduler._ram[last_record + 8] = 0x67
	else:
		scheduler._ram[0x0624] = 0x78
		scheduler._ram[0x0430] = 1
		scheduler._ram[0x0431] = 0x0A
		scheduler._ram[0x0625] = 1
		scheduler._ram[0x05FC] = 0x0A
	for stack_index in scheduler._stack_page.size():
		scheduler._ram[0x0100 + stack_index] = scheduler._stack_page[stack_index]
	scheduler._slot05_pass_receiver_input_wait_dispatch_pending = true
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var dispatch := {
		"slot_base": 0x05, "resume_path": "yielded_rts", "pc": 0xD80F,
		"bank_low": 0x1C, "bank_high": 0x1D,
		"sp": context.stack_pointer, "a": context.accumulator,
		"x": context.x_register, "y": context.y_register,
	}
	if not scheduler.arm_slot05_pass_receiver_input_wait(dispatch, boundary):
		return {"ok": false, "error": "Scheduler rejected the synthetic live `$D80F` restore: " + str(scheduler.error_message)}
	return {"ok": true, "scheduler": scheduler, "context": context}


func _make_executor_boundary(scheduler: Variant, sample: Dictionary) -> Dictionary:
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	mapper["cpu_c000_bank"] = 0x1E
	mapper["cpu_e000_bank"] = 0x1F
	boundary["mapper"] = mapper
	boundary["executing_cpu_bank"] = 0x1E
	boundary["polled_controller"] = {
		"direction_mask": int(sample["held_ram_001c"]),
		"button_mask": int(sample["edge_ram_001e"]),
	}
	boundary["trace_state_used"] = false
	boundary["emulator_data_used"] = false
	return boundary


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
