extends SceneTree

const EXECUTOR := preload("res://scripts/gameplay/rom_slot05_scenario35_return_executor.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		_fail("ROM source package configuration failed: " + executor.error_message)
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

	# The live route report supplied this precise boundary receipt. This fixture
	# reconstructs only its caller/stack profile; it does not claim a live replay.
	context.phase = SCHEDULER.ContextPhase.RUNNING
	context.program_counter = 0xCBC1
	context.stack_pointer = 0x48
	context.accumulator = 0x00
	context.x_register = 0x05
	context.y_register = 0x05
	context.status_register = 0x20
	context.status_known_mask = 0x20
	context.bank_low = 0x1A
	context.bank_high = 0x1B
	context.source_return_word = 0xE944
	context.source_label = "synthetic fixture from live scenario-$38 `$CBC1` receipt"
	scheduler._active_task_slot = 0x05
	scheduler._ram[0x0000] = 0x05
	scheduler._ram[0x0005] = 0x01
	scheduler._ram[0x0006] = 0x48
	scheduler._ram[0x0007] = 0x1A
	scheduler._ram[0x0008] = 0x1B
	scheduler._ram[0x0024] = 0x1A
	scheduler._ram[0x0025] = 0x1B
	scheduler._ram[0x0518] = 0x38
	scheduler._stack_page[0x49] = 0xEC
	scheduler._stack_page[0x4A] = 0xD7
	scheduler._ram[0x0149] = 0xEC
	scheduler._ram[0x014A] = 0xD7

	var dispatch := {
		"ok": true, "slot_base": 0x05, "resume_path": "yielded_rts",
		"pc": 0xCBC1, "sp": 0x48, "a": 0x00, "x": 0x05, "y": 0x05,
		"p": 0x20, "p_known_mask": 0x20, "p_known_value": 0x20,
		"source_return_word": 0xE944, "bank_low": 0x1A, "bank_high": 0x1B,
	}
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var rejected_dispatch: Dictionary = dispatch.duplicate(true)
	rejected_dispatch["source_return_word"] = 0xD11D
	if bool(executor.execute_from_live_dispatch(rejected_dispatch, boundary).get("ok", false)):
		_fail("Executor accepted the old `$D11D` caller word for the scenario-$38 profile.")
		return

	var result: Dictionary = executor.execute_from_live_dispatch(dispatch, boundary)
	if not bool(result.get("ok", false)):
		_fail("Executor rejected the exact scenario-$38 stack profile: " + executor.error_message)
		return
	var entry: Dictionary = result.get("entry", {})
	var registers: Dictionary = result.get("registers", {})
	var result_mapper: Dictionary = result.get("mapper", {})
	var result_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var source_register_select := int(result_ram[0x0022]) & 0x07
	if String(result.get("status", "")) != "returned_to_source_caller" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(entry.get("scenario_id", -1)) != 0x38 \
			or int(entry.get("return_word", -1)) != 0xD7EC \
			or int(entry.get("expected_return_pc", -1)) != 0xD7ED \
			or int(registers.get("pc", -1)) != 0xD7ED \
			or int(registers.get("sp", -1)) != 0x4A \
			or int(registers.get("bank_low", -1)) != 0x1A \
			or int(registers.get("bank_high", -1)) != 0x1B \
			or int(result_mapper.get("register_select", -1)) != source_register_select \
			or result.get("memory_writes", ["unexpected"]) != []:
		_fail("RTS result differs from the source-derived `$D7EC->$D7ED`, SP `$48->$4A`, bank `$1A/$1B` contract.")
		return
	if not scheduler.adopt_slot05_scenario35_return_state(dispatch, boundary, result):
		_fail("Scheduler rejected the narrowly gated scenario-$38 caller: " + scheduler.error_message)
		return
	var adopted: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var adopted_mapper: Dictionary = adopted.get("mapper", {})
	if int(adopted.get("pc", -1)) != 0xD7ED or int(adopted.get("sp", -1)) != 0x4A \
			or int(adopted.get("bank_low", -1)) != 0x1A \
			or int(adopted.get("bank_high", -1)) != 0x1B \
			or int(adopted_mapper.get("register_select", -1)) != source_register_select \
			or int(adopted_mapper.get("select", -1)) != source_register_select:
		_fail("Scheduler did not adopt the source RTS return PC/SP/banks and `$0022` MMC3 selector.")
		return
	print("PASS: pinned ROM bytes prove `$D7E8 LDA #$38; $D7EA JSR $CBB0`; `$CBC1 RTS` pops stack word `$D7EC` and resumes `$D7ED`.")
	print("PASS: scenario-$38 executor and scheduler preserve mapper register select `$%02X` from live RAM `$0022` in the `$D7ED` boundary; old caller-word mismatch is rejected." % source_register_select)
	print("LIMIT: positive boundary is a source-derived synthetic fixture based on the supplied live route receipt; no full-route replay or FCEUX terminal observation was run here.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
