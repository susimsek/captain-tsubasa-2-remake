extends SceneTree

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PERIOD_TASK := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const CONTINUATION := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const WORKER_PREFIX := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: source-owned slot-$05 first yield resumes scheduler scanning, dispatches root slot-$09 at `$EB86`, and saves its `$EB8B` continuation at `$CB0F`.")
	print("LIMIT: executes only slot-$09 `$EB86-$EB8A`; no later root-loop behavior, NMI cadence/service, worker resumption, gameplay transition, or same-input FCEUX parity is verified.")
	quit(0)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh-route source setup failed: " + builder.error_message)
	var route_context = builder.build_fresh_kickoff_context()
	if route_context == null:
		return _fail("Fresh-route source context derivation failed: " + builder.error_message)

	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources():
		return _fail("Scheduler rejected packaged/hash-checked spans: " + scheduler.error_message)
	if not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Fresh-game ROM bootstrap failed: " + scheduler.error_message)
	var slot01_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot01_scan.get("ok", false)) or int(slot01_scan.get("selected_slot_base", -1)) != 0x01:
		return _fail("ROM scheduler did not select root slot `$01`.")
	var slot01_dispatch: Dictionary = scheduler.dispatch_pending_task(0x01)
	if not bool(slot01_dispatch.get("ok", false)) or int(slot01_dispatch.get("pc", -1)) != 0xCA22:
		return _fail("ROM scheduler did not restore root slot `$01` at `$CA22`.")
	var slot01_yield: Dictionary = scheduler.execute_root_slot01_startup_to_first_yield()
	if not bool(slot01_yield.get("ok", false)) or int(slot01_yield.get("yield_callsite_pc", -1)) != 0xCA4F:
		return _fail("Root slot `$01` did not reach its source yield at `$CA4F`.")
	var slot05_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot05_scan.get("ok", false)) or int(slot05_scan.get("selected_slot_base", -1)) != 0x05:
		return _fail("ROM scheduler did not continue from slot `$01` to slot `$05`.")
	var slot05_dispatch: Dictionary = scheduler.dispatch_pending_task(0x05)
	if not bool(slot05_dispatch.get("ok", false)) or int(slot05_dispatch.get("pc", -1)) != 0xD11E \
			or int(slot05_dispatch.get("sp", -1)) != 0x52:
		return _fail("Fresh root slot `$05` did not dispatch at `$D11E` / SP `$52`.")
	if not _same_dispatch(slot05_dispatch, route_context.scheduler_dispatch):
		return _fail("Route context disagrees with the live source-owned slot-$05 dispatch.")

	var source_inputs: Dictionary = route_context.to_period_task_inputs()
	source_inputs["scheduler_dispatch"] = slot05_dispatch.duplicate(true)
	var period = PERIOD_TASK.new()
	if not period.configure_from_project_sources():
		return _fail("Fresh-period source setup failed: " + period.error_message)
	var period_result: Dictionary = period.execute_fresh_match_zero(source_inputs)
	if not bool(period_result.get("ok", false)):
		return _fail("Source slot-$05 period segment failed: " + period.error_message)
	var continuation = CONTINUATION.new()
	if not continuation.configure_from_project_sources():
		return _fail("Fresh continuation source setup failed: " + continuation.error_message)
	var worker_entry: Dictionary = continuation.execute_synchronous_prefix(period_result)
	if not bool(worker_entry.get("ok", false)):
		return _fail("ROM-byte `$DAAA->$800C` continuation failed: " + continuation.error_message)
	var worker = WORKER_PREFIX.new()
	if not worker.configure_from_project_sources():
		return _fail("Bank-$18 worker source setup failed: " + worker.error_message)
	var worker_result: Dictionary = worker.execute_to_yield_trampoline(worker_entry)
	if not bool(worker_result.get("ok", false)):
		return _fail("ROM-byte worker prefix failed: " + worker.error_message)
	var merge_result: Dictionary = scheduler.merge_source_ordered_worker_writes(
		0x05, period_result, worker_entry, worker_result)
	if not bool(merge_result.get("ok", false)):
		return _fail("Scheduler rejected the source-ordered slot-$05 writes: " + scheduler.error_message)
	if not scheduler.adopt_bank18_worker_prefix_state(0x05, worker_result):
		return _fail("Scheduler rejected the source-owned worker boundary: " + scheduler.error_message)
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	if not scheduler.yield_at_verified_callsite(0x05, 0x8886, int(registers.get("a", -1)),
			int(registers.get("sp", -1)), int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))):
		return _fail("Slot `$05` source worker did not reach its existing `$8886->$CB0F` bridge: " + scheduler.error_message)
	var slot05_saved: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	if int(slot05_saved.get("pc", -1)) != 0xCB0F \
			or slot05_saved.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
			or int(slot05_saved.get("scheduler_scan_cursor", -1)) != 0x09:
		return _fail("Existing slot-$05 first-yield bridge did not leave the expected ready record/cursor.")

	var slot09_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot09_scan.get("ok", false)) or int(slot09_scan.get("selected_slot_base", -1)) != 0x09 \
			or int(slot09_scan.get("decision", -1)) != SCHEDULER.ScanDecision.INITIAL_DISPATCH:
		return _fail("Source scheduler did not dispatch the bootstrap-seeded root slot `$09` after slot `$05` yield.")
	var slot09_dispatch: Dictionary = scheduler.dispatch_pending_task(0x09)
	if not bool(slot09_dispatch.get("ok", false)) or int(slot09_dispatch.get("pc", -1)) != 0xEB86 \
			or int(slot09_dispatch.get("sp", -1)) != 0x7A \
			or int(slot09_dispatch.get("a", -1)) != 0x78 or int(slot09_dispatch.get("x", -1)) != 0x78 \
			or int(slot09_dispatch.get("y", -1)) != 0x05 \
			or int(slot09_dispatch.get("bank_low", -1)) != 0x00 \
			or int(slot09_dispatch.get("bank_high", -1)) != 0x01 \
			or int(slot09_dispatch.get("source_return_word", -1)) != 0xEB85:
		return _fail("Root slot `$09` dispatch is not the source-owned `$EB86` fixed-bank context.")
	var slot09_yield: Dictionary = scheduler.execute_root_slot09_first_yield()
	if not bool(slot09_yield.get("ok", false)) or int(slot09_yield.get("yield_callsite_pc", -1)) != 0xEB88 \
			or int(slot09_yield.get("resume_pc", -1)) != 0xEB8B \
			or slot09_yield.get("task_record", PackedByteArray()) != PackedByteArray([0x01, 0x76, 0x00, 0x01]) \
			or int(slot09_yield.get("scheduler_scan_cursor", -1)) != 0x0D:
		return _fail("Root slot `$09` first yield did not save its source continuation `$EB8B` and advance the cursor.")
	var saved: Dictionary = scheduler.get_task_boundary_snapshot(0x09)
	if int(saved.get("phase", -1)) != SCHEDULER.ContextPhase.YIELDED \
			or int(saved.get("pc", -1)) != 0xCB0F or int(saved.get("ready_delay", -1)) != 0x01 \
			or int(saved.get("a", -1)) != 0x01 or int(saved.get("x", -1)) != 0x78 \
			or int(saved.get("y", -1)) != 0x05 or int(saved.get("bank_low", -1)) != 0x00 \
			or int(saved.get("bank_high", -1)) != 0x01 \
			or int(saved.get("scheduler_y_register", -1)) != 0x09 \
			or int(saved.get("active_task_slot", -2)) != -1:
		return _fail("Saved slot-$09 context differs from the bounded `$CB0F` source-save effects.")
	var stack: PackedByteArray = saved.get("stack_page", PackedByteArray())
	if stack.size() != 0x100 or stack.slice(0x76, 0x7B) != PackedByteArray([0x00, 0x05, 0x78, 0x8A, 0xEB]):
		return _fail("Saved slot-$09 stack does not contain the expected Y/X/`$EB8A` RTS continuation.")
	return true


func _same_dispatch(actual: Dictionary, expected_variant: Variant) -> bool:
	if not expected_variant is Dictionary:
		return false
	var expected: Dictionary = expected_variant
	for key: String in ["slot_base", "pc", "sp", "a", "x", "y", "bank_low", "bank_high", "source_return_word"]:
		if int(actual.get(key, -1)) != int(expected.get(key, -2)):
			return false
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
