extends SceneTree
## Exercises the scheduler's callback-$34/map-$2D adoption validators.
## The task boundary is a synthetic source-derived fixture, not an FCEUX RAM
## image. Execution stops at `$8525`; no map worker, queue, or PPU runs.

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const CALLBACK_DISPATCHER := preload("res://scripts/gameplay/rom_slot15_callback_dispatcher_executor.gd")
const MAP_HANDLER_PREFIX := preload("res://scripts/gameplay/rom_slot15_map_handler_prefix_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scheduler: Variant = SCHEDULER.new()
	if not scheduler.configure_from_project_sources():
		_fail("Scheduler source configuration failed: " + str(scheduler.error_message))
		return
	if scheduler.initialize_fresh_game_bootstrap().is_empty():
		_fail("Scheduler bootstrap failed: " + str(scheduler.error_message))
		return
	var seeded: Dictionary = scheduler.seed_scenario_callback_task(0x8097)
	if not bool(seeded.get("ok", false)):
		_fail("ROM source task seed failed: " + str(scheduler.error_message))
		return

	# Build a bounded CPU/task boundary from the ROM callback entry and the
	# scenario-$38 / callback-$34 source record. No captured RAM is consumed.
	var context: Variant = scheduler._contexts.get(0x15)
	if context == null:
		_fail("Source-seeded callback task context is missing.")
		return
	context.phase = 2 # ContextPhase.RUNNING
	context.program_counter = 0x814C
	context.accumulator = 0xF0
	context.x_register = 0xF0
	context.y_register = 0
	context.stack_pointer = 0xF2
	context.status_register = 0x20
	context.status_known_mask = 0
	context.bank_low = 0x0B
	context.bank_high = 0x0C
	context.source_label = "synthetic ROM-derived slot-$15 callback-$34 boundary"
	scheduler._active_task_slot = 0x15
	scheduler._ram[0x0000] = 0x15
	scheduler._ram[0x0518] = 0x38
	scheduler._ram[0x0524] = 0x34
	scheduler._ram[0x05CD] = 0x00

	var dispatcher_input := {
		"ok": true,
		"status": "reached_callback_dispatcher_entry",
		"rom_sha256": ROM_SHA256,
		"exit_pc": 0x814C,
		"dispatcher_dispatch": {
			"pc": 0x814C,
			"a": 0xF0,
			"x": 0xF0,
			"y": 0,
			"sp": 0xF2,
			"p": 0x20,
			"p_known_mask": 0,
			"slot_base": 0x15,
			"bank_low": 0x0B,
			"bank_high": 0x0C,
		},
		"ram_image": scheduler._ram.duplicate(),
		"stack_page": scheduler._stack_page.duplicate(),
	}
	var dispatcher = CALLBACK_DISPATCHER.new()
	var callback_result: Dictionary = dispatcher.execute_fresh_callback(dispatcher_input)
	if not bool(callback_result.get("ok", false)):
		_fail("Callback-$34 ROM dispatch failed: " + str(callback_result.get("error", "unknown")))
		return
	if not scheduler.adopt_slot15_callback_handler_boundary(callback_result):
		_fail("Scheduler rejected the callback-$34 `$814C->$8327` source effects: " \
				+ str(scheduler.error_message))
		return

	var map_prefix = MAP_HANDLER_PREFIX.new()
	var map_worker_result: Dictionary = map_prefix.execute_from_handler_boundary(callback_result)
	if not bool(map_worker_result.get("ok", false)):
		_fail("Callback-$34 `$8327->$8525` source prefix failed: " \
				+ str(map_worker_result.get("error", "unknown")))
		return
	if not scheduler.adopt_slot15_map_worker_entry(map_worker_result):
		_fail("Scheduler rejected the map-$2D source boundary: " + str(scheduler.error_message))
		return

	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x15)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	if int(boundary.get("pc", -1)) != 0x8525 \
			or int(boundary.get("active_task_slot", -1)) != 0x15 \
			or ram.size() != 0x800 or int(ram[0x05CC]) != 0x2D:
		_fail("Adopted slot-$15 boundary does not stop at map-$2D `$8525`: " + str(boundary))
		return
	print("PASS: source-seeded scenario `$38` → callback `$34` → map `$2D` was adopted through `$8525`.")
	print("PASS: map-$2D selector/CHR hashes and first source cell batch passed scheduler validation.")
	print("LIMIT: synthetic task boundary only; no route continuation, map worker, PPU queue, or timing was executed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
