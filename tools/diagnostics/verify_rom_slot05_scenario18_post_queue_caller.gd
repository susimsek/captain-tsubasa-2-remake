extends SceneTree

const RETURN_EXECUTOR := preload("res://scripts/gameplay/rom_slot05_scenario35_return_executor.gd")
const CALLER_EXECUTOR := preload("res://scripts/gameplay/rom_slot05_scenario18_post_queue_caller_executor.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var return_executor = RETURN_EXECUTOR.new()
	if not return_executor.configure_from_project_sources():
		_fail("Return source package configuration failed: " + return_executor.error_message)
		return
	var caller_executor = CALLER_EXECUTOR.new()
	if not caller_executor.configure():
		_fail("Caller source package configuration failed: " + caller_executor.error_message)
		return
	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources():
		_fail("Scheduler source configuration failed: " + scheduler.error_message)
		return
	var bootstrap: Dictionary = scheduler.initialize_fresh_game_bootstrap()
	if not bool(bootstrap.get("ok", false)):
		_fail("Scheduler fixture bootstrap failed: " + scheduler.error_message)
		return
	var context = scheduler._contexts.get(0x05)
	if context == null:
		_fail("Fresh bootstrap did not seed slot-$05.")
		return
	context.phase = SCHEDULER.ContextPhase.RUNNING
	context.program_counter = 0xCBC1
	context.stack_pointer = 0x4C
	context.accumulator = 0x00
	context.x_register = 0x05
	context.y_register = 0x05
	context.status_register = 0x20
	context.status_known_mask = 0xFF
	context.bank_low = 0x1A
	context.bank_high = 0x1B
	context.source_return_word = 0xE944
	context.source_label = "synthetic source-profile fixture for scenario-$18"
	scheduler._active_task_slot = 0x05
	scheduler._slot05_pass_selection_adopted = true
	scheduler._slot05_pass_handler_dispatch_pending = true
	scheduler._ram[0x0000] = 0x05
	scheduler._ram[0x0005] = 0x01
	scheduler._ram[0x0006] = 0x4C
	scheduler._ram[0x0007] = 0x1A
	scheduler._ram[0x0008] = 0x1B
	scheduler._ram[0x0022] = 0x07
	scheduler._ram[0x0024] = 0x1A
	scheduler._ram[0x0025] = 0x1B
	scheduler._ram[0x043B] = 0x01
	scheduler._ram[0x0444] = 0x00
	scheduler._ram[0x00E2] = 0x01
	scheduler._ram[0x0518] = 0x18
	scheduler._ram[0x0617] = 0x12
	scheduler._stack_page[0x4D] = 0x87
	scheduler._stack_page[0x4E] = 0x81
	scheduler._stack_page[0x4F] = 0x11
	scheduler._stack_page[0x50] = 0x81
	for index in range(0x100):
		scheduler._ram[0x0100 + index] = scheduler._stack_page[index]
	var dispatch := {
		"ok": true, "slot_base": 0x05, "resume_path": "yielded_rts",
		"pc": 0xCBC1, "sp": 0x4C, "a": 0x00, "x": 0x05, "y": 0x05,
		"p": 0x20, "p_known_mask": 0xFF, "p_known_value": 0x20,
		"source_return_word": 0xE944, "bank_low": 0x1A, "bank_high": 0x1B,
	}
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var wrong_frame: Dictionary = boundary.duplicate(true)
	var wrong_stack: PackedByteArray = wrong_frame["stack_page"].duplicate()
	wrong_stack[0x4D] = 0x00
	wrong_frame["stack_page"] = wrong_stack
	if bool(return_executor.execute_from_live_dispatch(dispatch, wrong_frame).get("ok", false)):
		_fail("RTS executor accepted a scenario-$18 frame without the live `$8187` stack word.")
		return
	var returned: Dictionary = return_executor.execute_from_live_dispatch(dispatch, boundary)
	if not bool(returned.get("ok", false)):
		_fail("RTS executor rejected the source-profile scenario-$18 frame: " + return_executor.error_message)
		return
	var returned_registers: Dictionary = returned.get("registers", {})
	if int(returned_registers.get("pc", -1)) != 0x8188 \
			or int(returned_registers.get("sp", -1)) != 0x4E \
			or returned.get("memory_writes", ["unexpected"]) != []:
		_fail("`$CBC1 RTS` did not return unchanged to `$8188`, SP `$4E`.")
		return
	if not scheduler.adopt_slot05_scenario35_return_state(dispatch, boundary, returned):
		_fail("Scheduler rejected the ROM `$CBC1 RTS` result: " + scheduler.error_message)
		return
	# The ordinary-input route has already consumed the initial handler dispatch
	# at `$D6C7`; this later scenario-$18 return is the action result phase.
	scheduler._slot05_pass_handler_dispatch_pending = false
	var caller_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var caller_result: Dictionary = caller_executor.execute_from_live_return(returned, caller_boundary)
	if not bool(caller_result.get("ok", false)):
		_fail("Caller executor rejected the source-profile `$8188` state: " + caller_executor.error_message)
		return
	if int(caller_result.get("exit_pc", -1)) != 0x8112 \
			or int(caller_result.get("registers", {}).get("sp", -1)) != 0x50 \
			or int(caller_result.get("ram_image", PackedByteArray())[0x044E]) != 0x02 \
			or int(caller_result.get("ram_image", PackedByteArray())[0x0617]) != 0x92:
		_fail("`$8188->$C624->$DCDF->$819B` output does not match the expected parity and flag updates.")
		return
	if not scheduler.adopt_slot05_scenario18_post_queue_caller_result(caller_boundary, caller_result):
		_fail("Scheduler rejected the source `$8188->$8112` caller: " + scheduler.error_message)
		return
	var adopted: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	if int(adopted.get("pc", -1)) != 0x8112 or int(adopted.get("sp", -1)) != 0x50 \
			or int(adopted.get("ram_image", PackedByteArray())[0x044E]) != 0x02 \
			or int(adopted.get("ram_image", PackedByteArray())[0x0617]) != 0x92:
		_fail("Scheduler did not adopt the ROM caller's `$8112`, stack, and RAM result.")
		return
	print("PASS: ROM-pinned scenario-$18 `$CBC1 RTS` pops `$8187->$8188`, SP `$4C->$4E`.")
	print("PASS: `$8188->$819B` executes `$C624->$DCDF`, derives `$044E=1+($00E2&1)` when zero, sets `$0617` bit 7, and returns via live `$8111->$8112`, SP `$4E->$50`.")
	print("LIMIT: This is a source-profile synthetic verifier; the full recorded-input route has not yet replayed this branch, and CPU cycle timing is not modeled.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
