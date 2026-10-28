extends SceneTree

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const FIRST_TASK_TRACE := "res://reference/diagnostics/first_command_task_boundary_20261028_070655_utc/task_events.csv"


func _initialize() -> void:
	if not _verify_runtime_scheduler():
		quit(1)
		return
	print("PASS: the ROM-byte `$CA22` root startup reaches its `$CA4F` yield and matches the retained FCEUX register/task-record oracle.")
	print("LIMIT: this executes one bounded instruction subset; full 6502/task execution, callback continuations, and NMI cadence remain unmodeled.")
	quit(0)


func _verify_runtime_scheduler() -> bool:
	var scheduler = SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources():
		return _fail("Runtime scheduler rejected project-owned source spans: " + scheduler.error_message)
	var bootstrap: Dictionary = scheduler.initialize_fresh_game_bootstrap()
	if not bool(bootstrap.get("ok", false)):
		return _fail("Fresh-game bootstrap did not initialize: " + scheduler.error_message)
	if bootstrap.get("root_slots", []) != [0x01, 0x05, 0x09] \
			or bootstrap.get("root_task_return_words", []) != [0xCA21, 0xD11D, 0xEB85] \
			or bootstrap.get("stack_pointer_words", []) != [0x28, 0x50, 0x78] \
			or int(bootstrap.get("scheduler_entry_pc", -1)) != 0xCA97 \
			or int(bootstrap.get("ppu_ctrl_shadow", -1)) != 0x88 \
			or int(bootstrap.get("scheduler_ready_latch_001b", -1)) != 0:
		return _fail("Root task records/continuations or source bootstrap latch differ from the verified ROM recipes.")

	var status: Dictionary = scheduler.get_status()
	if bool(status.get("does_execute_6502", true)) \
			or bool(status.get("does_synthesize_nmi_cadence", true)) \
			or bool(status.get("does_execute_full_task_bodies", true)) \
			or not bool(status.get("does_execute_bounded_root_slot01_startup", false)):
		return _fail("Runtime task service must report unmodeled CPU/NMI/task-body behavior explicitly.")

	var no_edge: Dictionary = scheduler.apply_external_nmi_delivery(8459, 0x88, false)
	if not bool(no_edge.get("ok", false)) or bool(no_edge.get("serviced", true)) \
			or int(no_edge.get("latch_after", -1)) != 0:
		return _fail("A missing external NMI edge must not synthesize the scheduler-ready latch.")
	var first_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(first_scan.get("ok", false)) \
			or int(first_scan.get("decision", -1)) != SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH \
			or int(first_scan.get("selected_slot_base", -1)) != 0x01 \
			or first_scan.get("checked_slots", []) != [0x01]:
		return _fail("First source scheduler scan did not dispatch the earliest ready root task.")
	var first_dispatch: Dictionary = scheduler.dispatch_pending_task(0x01)
	if not bool(first_dispatch.get("ok", false)) \
			or int(first_dispatch.get("pc", -1)) != 0xCA22 \
			or int(first_dispatch.get("sp", -1)) != 0x2A \
			or int(first_dispatch.get("a", -1)) != 0x28 \
			or int(first_dispatch.get("x", -1)) != 0x28 \
			or int(first_dispatch.get("y", -1)) != 0x78 \
			or int(first_dispatch.get("bank_low", -1)) != 0 \
			or int(first_dispatch.get("bank_high", -1)) != 1:
		return _fail("Root dispatch did not restore its ROM-seeded RTS word, CPU registers, and bank pair.")
	var root_yield: Dictionary = scheduler.execute_root_slot01_startup_to_first_yield()
	if not bool(root_yield.get("ok", false)) \
			or int(root_yield.get("yield_callsite_pc", -1)) != 0xCA4F \
			or int(root_yield.get("resume_pc", -1)) != 0xCA52 \
			or int(root_yield.get("a", -1)) != 1 \
			or int(root_yield.get("x", -1)) != 0x28 \
			or int(root_yield.get("y", -1)) != 0x78 \
			or int(root_yield.get("saved_sp", -1)) != 0x26 \
			or root_yield.get("task_record", PackedByteArray()) != PackedByteArray([0x01, 0x26, 0x00, 0x01]):
		return _fail("The ROM-byte root `$CA22` body did not reproduce its first `$CA4F` yield state.")
	if not _verify_root_task_trace_oracle():
		return false
	if not _has_write(root_yield.get("writes", []), 0x0490, 0x00) \
			or not _has_write(root_yield.get("writes", []), 0x0491, 0x02) \
			or not _has_write(root_yield.get("writes", []), 0x0544, 0x23) \
			or not _has_write(root_yield.get("writes", []), 0x0545, 0x45):
		return _fail("Root startup did not apply its ROM-derived setup stores before yielding.")
	var slot5_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot5_scan.get("ok", false)) \
			or int(slot5_scan.get("selected_slot_base", -1)) != 0x05 \
			or int(slot5_scan.get("scheduler_scan_cursor", -1)) != 0x05:
		return _fail("After slot `$01` yields, the ROM scheduler must continue at slot `$05`.")
	var slot5_dispatch: Dictionary = scheduler.dispatch_pending_task(0x05)
	if not bool(slot5_dispatch.get("ok", false)) \
			or int(slot5_dispatch.get("pc", -1)) != 0xD11E \
			or int(slot5_dispatch.get("sp", -1)) != 0x52 \
			or int(slot5_dispatch.get("a", -1)) != 0x50 \
			or int(slot5_dispatch.get("x", -1)) != 0x50 \
			or int(slot5_dispatch.get("y", -1)) != 0x01:
		return _fail("Initial slot `$05` dispatch did not preserve the yielded scheduler Y/cursor state.")
	# Trace-derived callsite inputs let the bounded model check the real next
	# slot's `$856F → $C515 → $CB0F` stack layout without executing that task body.
	var slot5_context = scheduler.get_task_context(0x05)
	slot5_context.program_counter = 0x856F
	slot5_context.stack_pointer = 0x4A
	if not scheduler.yield_at_verified_callsite(0x05, 0x856F, 1, 0x4A,
			0xFF, 0x00, 0x18, 0x19):
		return _fail("Slot `$05` callback-yield frame failed: " + scheduler.error_message)
	var after_slot5_yield: Dictionary = scheduler.get_status()
	if _record_for_slot(after_slot5_yield.get("task_slots", []), 0x05) != PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
			or int(after_slot5_yield.get("scheduler_y_register", -1)) != 0x05 \
			or int(after_slot5_yield.get("scheduler_scan_cursor", -1)) != 0x09:
		return _fail("Slot `$05` yield did not advance the source cursor and retain its task record.")
	var slot9_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot9_scan.get("ok", false)) \
			or int(slot9_scan.get("selected_slot_base", -1)) != 0x09:
		return _fail("After slot `$05` yields, the ROM scheduler must continue at slot `$09`.")
	var slot9_dispatch: Dictionary = scheduler.dispatch_pending_task(0x09)
	if not bool(slot9_dispatch.get("ok", false)) \
			or int(slot9_dispatch.get("pc", -1)) != 0xEB86 \
			or int(slot9_dispatch.get("sp", -1)) != 0x7A \
			or int(slot9_dispatch.get("y", -1)) != 0x05:
		return _fail("Initial slot `$09` dispatch did not continue in ROM slot order.")

	var callback_scheduler = SCHEDULER_SCRIPT.new()
	if not callback_scheduler.configure_from_project_sources() \
			or callback_scheduler.initialize_fresh_game_bootstrap().is_empty():
		return _fail("Could not prepare the callback-seed source fixture.")
	var seed: Dictionary = callback_scheduler.seed_scenario_callback_task(0x8097)
	if not bool(seed.get("ok", false)) \
			or int(seed.get("slot_base", -1)) != 0x15 \
			or seed.get("record", PackedByteArray()) != PackedByteArray([0xFF, 0xF0, 0x0B, 0x00]) \
			or int(seed.get("source_return_word", -1)) != 0x8008 \
			or int(seed.get("initial_rts_pc", -1)) != 0x8009 \
			or bool(seed.get("scheduled", true)):
		return _fail("Explicit bank-$10 `$8097` caller did not seed the ROM-derived slot-$15 continuation.")
	var callback_scan: Dictionary = callback_scheduler.scan_ready_tasks_once()
	if not bool(callback_scan.get("ok", false)) \
			or int(callback_scan.get("selected_slot_base", -1)) != 0x01:
		return _fail("Scheduler skipped a higher-priority ready root task for the later callback slot.")

	var normal_edge: Dictionary = scheduler.apply_external_nmi_delivery(8461, 0x88, true)
	if not bool(normal_edge.get("ok", false)) or not bool(normal_edge.get("serviced", false)) \
			or int(normal_edge.get("writer_pc", -1)) != 0xC7F0 \
			or int(normal_edge.get("latch_after", -1)) != 0x80 \
			or bool(normal_edge.get("models_nmi_cycle", true)):
		return _fail("Normal NMI delivery must map to the ROM ready writer without assigning a cycle.")
	return true


func _verify_root_task_trace_oracle() -> bool:
	var file := FileAccess.open(FIRST_TASK_TRACE, FileAccess.READ)
	if file == null:
		return _fail("Retained muted FCEUX task trace is unavailable as a validation oracle.")
	var lines := file.get_as_text().split("\n", false)
	var root_yield_sequence := -1
	var slot5_dispatch_sequence := -1
	var slot5_yield_sequence := -1
	var slot9_dispatch_sequence := -1
	for line in lines:
		var columns := line.split(",", true)
		if columns.size() < 16:
			continue
		if columns[6] == "task_yield_save_CB0F" and columns[2] == "8460" \
				and columns[9] == "$01" and columns[10] == "$28" \
				and columns[11] == "$78" and columns[13] == "$28" \
				and columns[14] == "$01":
			root_yield_sequence = int(columns[0])
		if columns[6] == "task_first_dispatch_CAD4" and columns[2] == "8460" \
				and columns[10] == "$05" and columns[11] == "$01" \
				and columns[15] == "01 26 00 01":
			slot5_dispatch_sequence = int(columns[0])
		if columns[6] == "task_yield_save_CB0F" and columns[2] == "8460" \
				and columns[9] == "$01" and columns[10] == "$FF" \
				and columns[11] == "$00" and columns[13] == "$48" \
				and columns[14] == "$05":
			slot5_yield_sequence = int(columns[0])
		if columns[6] == "task_first_dispatch_CAD4" and columns[2] == "8460" \
				and columns[10] == "$09" and columns[11] == "$05" \
				and columns[15] == "01 46 18 19":
			slot9_dispatch_sequence = int(columns[0])
	if root_yield_sequence < 0 or slot5_dispatch_sequence <= root_yield_sequence \
			or slot5_yield_sequence <= slot5_dispatch_sequence \
			or slot9_dispatch_sequence <= slot5_yield_sequence:
		return _fail("Scheduler slot order/registers differ from the retained same-input FCEUX task trace.")
	return true


func _has_write(writes: Array, address: int, value: int) -> bool:
	for write_variant in writes:
		if write_variant is Dictionary \
				and int(write_variant.get("address", -1)) == address \
				and int(write_variant.get("value", -1)) == value:
			return true
	return false


func _record_for_slot(records: Array, slot_base: int) -> PackedByteArray:
	for record_variant in records:
		if record_variant is Dictionary and int(record_variant.get("slot_base", -1)) == slot_base:
			return record_variant.get("bytes", PackedByteArray())
	return PackedByteArray()


func _fail(message: String) -> bool:
	printerr("FAIL: " + message)
	return false
