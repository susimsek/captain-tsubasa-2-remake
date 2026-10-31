extends RefCounted
class_name RomFreshKickoffSourceRouteRunner
## Composes source-verified fresh-match task and NMI transitions, including
## descriptor-$01 row `$BBE0: ED 00 FC`. The bounded worker stops before
## `$BD9C`; the caller supplies external NMI edges and this runner does not
## synthesize cadence, PPU side effects, or missing code.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const CONTEXT_BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PERIOD_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const WORKER_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const ROOT_SLOT01_CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_root_slot01_continuation_runtime.gd")
const EE9F_EMPTY_ACTOR_SCRIPT := preload("res://scripts/gameplay/rom_ee9f_actor_init_80_executor.gd")
const E3CA_NO_DIRECTION_SCRIPT := preload("res://scripts/gameplay/rom_e3ca_no_direction_call_executor.gd")
const SLOT09_CONTINUATION_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const SLOT09_86F8_ZERO_BRANCH_SCRIPT := preload("res://scripts/gameplay/rom_slot09_86f8_zero_branch_executor.gd")
const SLOT09_8779_ZERO_BRANCH_SCRIPT := preload("res://scripts/gameplay/rom_slot09_8779_zero_branch_executor.gd")
const SLOT09_87E6_ZERO_BRANCH_SCRIPT := preload("res://scripts/gameplay/rom_slot09_87e6_zero_branch_executor.gd")
const SLOT09_EBD7_ROOT_ZERO_COUNTER_SCRIPT := preload("res://scripts/gameplay/rom_slot09_ebd7_root_zero_counter_executor.gd")
const SLOT15_CALLBACK_ENTRY_SCRIPT := preload("res://scripts/gameplay/rom_slot15_callback_entry_executor.gd")
const SLOT15_CALLBACK_DISPATCHER_SCRIPT := preload("res://scripts/gameplay/rom_slot15_callback_dispatcher_executor.gd")
const SLOT15_MAP_HANDLER_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map_handler_prefix_executor.gd")
const SLOT15_MAP_WORKER_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map_worker_8525_prefix_executor.gd")
const SLOT15_MAP42_FIRST_BATCH_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map42_first_batch_executor.gd")
const SLOT15_MAP42_TERMINAL_RETURN_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map42_terminal_return_executor.gd")
const SLOT11_ACTOR_WORKER_SCRIPT := preload("res://scripts/gameplay/rom_slot11_actor_worker_prefix_executor.gd")
const SLOT11_ACTOR_WORKER_RESUME_SCRIPT := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const SLOT05_SCENARIO35_RETURN_SCRIPT := preload("res://scripts/gameplay/rom_slot05_scenario35_return_executor.gd")
const PLAYER_POSITION_INITIALIZER_SCRIPT := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")
const DAF5_RECEIVER_CALLER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_daf5_receiver_caller.gd")
const E6EC_HOLDER_COPY_SCRIPT := preload("res://scripts/gameplay/rom_fresh_e6ec_holder_copy_executor.gd")
const SCENARIO36_QUEUE_SCRIPT := preload("res://scripts/gameplay/rom_fresh_scenario36_queue_executor.gd")
const FIELD_ENTRY_PACKET_SOURCE_SCRIPT := preload("res://scripts/gameplay/rom_field_entry_window_packet_source.gd")
const RNG_SOURCE_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const RNG_SOURCE_SCHEDULE_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const RNG_ROUTE_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const RNG_RECEIVER_SOURCE_FRAME := 8593

const SLOT_01 := 0x01
const SLOT_05 := 0x05
const SLOT_09 := 0x09
const SLOT_11 := 0x11
const SLOT_15 := 0x15

var error_message := ""
var _configured := false
var _phase := "unconfigured"
var _scheduler: Variant = null
var _context_builder: Variant = null
var _period_task: Variant = null
var _continuation: Variant = null
var _worker_prefix: Variant = null
var _root_slot01_continuation: Variant = null
var _ee9f_empty_actor_executor: Variant = null
var _e3ca_no_direction_executor: Variant = null
var _slot09_continuation_prefix: Variant = null
var _slot09_86f8_zero_branch_executor: Variant = null
var _slot09_8779_zero_branch_executor: Variant = null
var _slot09_87e6_zero_branch_executor: Variant = null
var _slot09_ebd7_root_zero_counter_executor: Variant = null
var _slot15_callback_entry_executor: Variant = null
var _slot15_callback_dispatcher_executor: Variant = null
var _slot15_map_handler_prefix_executor: Variant = null
var _slot15_map_worker_prefix_executor: Variant = null
var _slot15_map42_first_batch_executor: Variant = null
var _slot15_map42_terminal_return_executor: Variant = null
var _slot11_actor_worker_executor: Variant = null
var _slot11_actor_worker_resume_executor: Variant = null
var _slot05_scenario35_return_executor: Variant = null
var _player_position_initializer: Variant = null
var _daf5_receiver_caller: Variant = null
var _e6ec_holder_copy_executor: Variant = null
var _scenario36_queue_executor: Variant = null
var _field_entry_packet_source: Variant = null
var _rng_source_replay: Variant = null
var _route_context: Variant
var _bootstrap_result: Dictionary = {}
var _fresh_period_result: Dictionary = {}
var _initial_worker_result: Dictionary = {}
var _last_slot05_source_worker_result: Dictionary = {}
var _last_slot05_ee_row_result: Dictionary = {}
var _slot09_yield_result: Dictionary = {}
var _scenario36_event_boundary_result: Dictionary = {}
var _scenario36_post_event_result: Dictionary = {}
var _scenario36_slot15_seed_result: Dictionary = {}
var _last_nmi_result: Dictionary = {}
var _last_root_actor_loop_result: Dictionary = {}
var _last_root_e3ca_result: Dictionary = {}
var _last_external_nmi_frame := -1
var _last_source_boundary := "unconfigured_or_error"
var _pending_nmi_queue_state: Dictionary = {}
var _pending_selected_task_slot := -1
var _pending_slot05_mapper_select := -1
var _pending_selected_task_boundary: Dictionary = {}
var _pending_selected_task_mapper: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_phase = "unconfigured"
	_scheduler = SCHEDULER_SCRIPT.new()
	_context_builder = CONTEXT_BUILDER_SCRIPT.new()
	_period_task = PERIOD_TASK_SCRIPT.new()
	_continuation = CONTINUATION_SCRIPT.new()
	_worker_prefix = WORKER_PREFIX_SCRIPT.new()
	_root_slot01_continuation = ROOT_SLOT01_CONTINUATION_SCRIPT.new()
	_ee9f_empty_actor_executor = EE9F_EMPTY_ACTOR_SCRIPT.new()
	_e3ca_no_direction_executor = E3CA_NO_DIRECTION_SCRIPT.new()
	_slot09_continuation_prefix = SLOT09_CONTINUATION_PREFIX_SCRIPT.new()
	_slot09_86f8_zero_branch_executor = SLOT09_86F8_ZERO_BRANCH_SCRIPT.new()
	_slot09_8779_zero_branch_executor = SLOT09_8779_ZERO_BRANCH_SCRIPT.new()
	_slot09_87e6_zero_branch_executor = SLOT09_87E6_ZERO_BRANCH_SCRIPT.new()
	_slot09_ebd7_root_zero_counter_executor = SLOT09_EBD7_ROOT_ZERO_COUNTER_SCRIPT.new()
	_slot15_callback_entry_executor = SLOT15_CALLBACK_ENTRY_SCRIPT.new()
	_slot15_callback_dispatcher_executor = SLOT15_CALLBACK_DISPATCHER_SCRIPT.new()
	_slot15_map_handler_prefix_executor = SLOT15_MAP_HANDLER_PREFIX_SCRIPT.new()
	_slot15_map_worker_prefix_executor = SLOT15_MAP_WORKER_PREFIX_SCRIPT.new()
	_slot15_map42_first_batch_executor = SLOT15_MAP42_FIRST_BATCH_SCRIPT.new()
	_slot15_map42_terminal_return_executor = SLOT15_MAP42_TERMINAL_RETURN_SCRIPT.new()
	_slot11_actor_worker_executor = SLOT11_ACTOR_WORKER_SCRIPT.new()
	_slot11_actor_worker_resume_executor = SLOT11_ACTOR_WORKER_RESUME_SCRIPT.new()
	_slot05_scenario35_return_executor = SLOT05_SCENARIO35_RETURN_SCRIPT.new()
	_player_position_initializer = PLAYER_POSITION_INITIALIZER_SCRIPT.new()
	_daf5_receiver_caller = DAF5_RECEIVER_CALLER_SCRIPT.new()
	_e6ec_holder_copy_executor = E6EC_HOLDER_COPY_SCRIPT.new()
	_scenario36_queue_executor = SCENARIO36_QUEUE_SCRIPT.new()
	_field_entry_packet_source = FIELD_ENTRY_PACKET_SOURCE_SCRIPT.new()
	if not _context_builder.configure_from_project_sources():
		return _fail("Fresh KICK OFF context sources failed: " + _context_builder.error_message)
	if not _scheduler.configure_from_project_sources():
		return _fail("Gameplay scheduler sources failed: " + _scheduler.error_message)
	if not _period_task.configure_from_project_sources():
		return _fail("Fresh-period sources failed: " + _period_task.error_message)
	if not _continuation.configure_from_project_sources():
		return _fail("Fresh match continuation sources failed: " + _continuation.error_message)
	if not _worker_prefix.configure_from_project_sources():
		return _fail("Bank-$18 worker sources failed: " + _worker_prefix.error_message)
	if not _root_slot01_continuation.configure_from_project_sources():
		return _fail("Root slot-$01 continuation sources failed: " + _root_slot01_continuation.error_message)
	if not _ee9f_empty_actor_executor.configure_from_project_sources():
		return _fail("`$EE9F` actor source packages failed: " + _ee9f_empty_actor_executor.error_message)
	if not _e3ca_no_direction_executor.configure_from_project_sources():
		return _fail("`$E3CA` no-direction source package failed: " + _e3ca_no_direction_executor.error_message)
	if not _slot09_continuation_prefix.configure_from_project_sources():
		return _fail("Slot-$09 `$EB8B` continuation source package failed: " + _slot09_continuation_prefix.error_message)
	if not _slot09_86f8_zero_branch_executor.configure_from_project_sources():
		return _fail("Slot-$09 `$86F8` worker source package failed: " + _slot09_86f8_zero_branch_executor.error_message)
	if not _slot09_8779_zero_branch_executor.configure_from_project_sources():
		return _fail("Slot-$09 `$8779` worker source package failed: " + _slot09_8779_zero_branch_executor.error_message)
	if not _slot09_87e6_zero_branch_executor.configure_from_project_sources():
		return _fail("Slot-$09 `$87E6` worker source package failed: " + _slot09_87e6_zero_branch_executor.error_message)
	if not _slot09_ebd7_root_zero_counter_executor.configure_from_project_sources():
		return _fail("Slot-$09 `$EBD7` root-loop source package failed: " + _slot09_ebd7_root_zero_counter_executor.error_message)
	if not _slot11_actor_worker_executor.configure_from_project_sources():
		return _fail("Slot-$11 actor-worker source package failed: " + _slot11_actor_worker_executor.error_message)
	if not _slot11_actor_worker_resume_executor.configure_from_project_sources():
		return _fail("Slot-$11 actor-worker resume source package failed: " + _slot11_actor_worker_resume_executor.error_message)
	if not _slot05_scenario35_return_executor.configure_from_project_sources():
		return _fail("Slot-$05 scenario-$35 return source package failed: " + _slot05_scenario35_return_executor.error_message)
	if not _player_position_initializer.configure():
		return _fail("ROM player-position initializer source package failed: " + _player_position_initializer.error_message)
	if not _daf5_receiver_caller.configure():
		return _fail("ROM `$DAF5` receiver caller source package failed: " + _daf5_receiver_caller.error_message)
	if not _e6ec_holder_copy_executor.configure():
		return _fail("ROM `$E6EC` holder-copy source package failed: " + _e6ec_holder_copy_executor.error_message)
	if not _scenario36_queue_executor.configure():
		return _fail("ROM scenario-$36 queue source package failed: " + _scenario36_queue_executor.error_message)
	_rng_source_replay = RNG_SOURCE_REPLAY_SCRIPT.new()
	if not _rng_source_replay.configure(RNG_SOURCE_SCHEDULE_PATH, RNG_ROUTE_INPUT_SHA256):
		return _fail("ROM-only KICK OFF RNG schedule failed integrity/input-route checks: " + _rng_source_replay.error_message)
	_configured = true
	_phase = "configured"
	return true


	## Runs the verified cold fresh-match task chain through slot-$09's `$EB8B`
## continuation. This initializes source state; it does not model elapsed time.
func start_fresh_kickoff_route() -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return {}
	var context: Variant = _context_builder.build_fresh_kickoff_context()
	if context == null:
		return _fail_result("Could not derive the fresh KICK OFF route context: " + _context_builder.error_message)
	return begin_from_context(context)


## Starts from a production route context already created by the title-route
## owner. This avoids deriving the same KICK OFF context twice.
func begin_from_context(route_context: Variant) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return {}
	if route_context == null or not route_context.has_method("to_period_task_inputs"):
		return _fail_result("A ROM-derived fresh KICK OFF route context is required.")
	_phase = "initializing"
	_last_nmi_result.clear()
	_scenario36_event_boundary_result.clear()
	_scenario36_post_event_result.clear()
	_scenario36_slot15_seed_result.clear()
	_last_external_nmi_frame = -1
	_rng_source_replay.reset_from_cold_start()
	_pending_nmi_queue_state.clear()
	_fresh_period_result.clear()
	_last_slot05_source_worker_result.clear()
	_last_slot05_ee_row_result.clear()
	_pending_selected_task_slot = -1
	_pending_slot05_mapper_select = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	_route_context = route_context
	_bootstrap_result = _scheduler.initialize_fresh_game_bootstrap()
	if not bool(_bootstrap_result.get("ok", false)):
		_fail("Fresh-game source bootstrap failed: " + _scheduler.error_message)
		return {}

	var slot01_scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(slot01_scan.get("ok", false)) or int(slot01_scan.get("selected_slot_base", -1)) != SLOT_01:
		return _fail_result("Source scheduler did not select the seeded slot-$01 task.")
	var slot01_dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_01)
	if not bool(slot01_dispatch.get("ok", false)) or int(slot01_dispatch.get("pc", -1)) != 0xCA22:
		return _fail_result("Slot-$01 dispatch did not restore `$CA22`.")
	var slot01_yield: Dictionary = _scheduler.execute_root_slot01_startup_to_first_yield()
	if not bool(slot01_yield.get("ok", false)) or int(slot01_yield.get("yield_callsite_pc", -1)) != 0xCA4F:
		return _fail_result("Slot-$01 source prefix did not yield at `$CA4F`.")

	var slot05_scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(slot05_scan.get("ok", false)) or int(slot05_scan.get("selected_slot_base", -1)) != SLOT_05:
		return _fail_result("Source scheduler did not select fresh slot-$05 after slot-$01 yielded.")
	var slot05_dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_05)
	if not bool(slot05_dispatch.get("ok", false)) or int(slot05_dispatch.get("pc", -1)) != 0xD11E \
			or int(slot05_dispatch.get("sp", -1)) != 0x52:
		return _fail_result("Fresh slot-$05 did not dispatch at `$D11E` / SP `$52`.")
	if not _same_dispatch(slot05_dispatch, _route_context.scheduler_dispatch):
		return _fail_result("Source scheduler and independently derived route context disagree on slot-$05 state.")

	var period_inputs: Dictionary = _route_context.to_period_task_inputs()
	period_inputs["scheduler_dispatch"] = slot05_dispatch.duplicate(true)
	var period_result: Dictionary = _period_task.execute_fresh_match_zero(period_inputs)
	if not bool(period_result.get("ok", false)):
		return _fail_result("Fresh-period ROM execution failed: " + _period_task.error_message)
	_fresh_period_result = period_result.duplicate(true)
	var worker_entry: Dictionary = _continuation.execute_synchronous_prefix(period_result)
	if not bool(worker_entry.get("ok", false)):
		return _fail_result("`$DAAA->$800C` ROM continuation failed: " + _continuation.error_message)
	_initial_worker_result = _worker_prefix.execute_to_yield_trampoline(worker_entry)
	if not bool(_initial_worker_result.get("ok", false)) \
			or int(_initial_worker_result.get("exit_pc", -1)) != 0xC515:
		return _fail_result("Bank-$18 source worker did not reach its verified `$C515` boundary: " + _worker_prefix.error_message)
	var merge_result: Dictionary = _scheduler.merge_source_ordered_worker_writes(
		SLOT_05, period_result, worker_entry, _initial_worker_result)
	if not bool(merge_result.get("ok", false)):
		return _fail_result("Scheduler rejected source-ordered fresh-match writes: " + _scheduler.error_message)
	if not _scheduler.adopt_bank18_worker_prefix_state(SLOT_05, _initial_worker_result):
		return _fail_result("Scheduler rejected the source-owned `$C515` worker boundary: " + _scheduler.error_message)
	var initial_regs: Dictionary = _initial_worker_result.get("registers", {})
	var initial_mapper: Dictionary = _initial_worker_result.get("mapper", {})
	if not _scheduler.yield_at_verified_callsite(SLOT_05, 0x8886,
			int(initial_regs.get("a", -1)), int(initial_regs.get("sp", -1)),
			int(initial_regs.get("x", -1)), int(initial_regs.get("y", -1)),
			int(initial_mapper.get("bank_low", -1)), int(initial_mapper.get("bank_high", -1))):
		return _fail_result("Initial slot-$05 worker could not save its `$CB0F` continuation: " + _scheduler.error_message)

	var slot09_scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(slot09_scan.get("ok", false)) or int(slot09_scan.get("selected_slot_base", -1)) != SLOT_09:
		return _fail_result("Source scheduler did not select the seeded slot-$09 root task.")
	var slot09_dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_09)
	if not bool(slot09_dispatch.get("ok", false)) or int(slot09_dispatch.get("pc", -1)) != 0xEB86 \
			or int(slot09_dispatch.get("sp", -1)) != 0x7A \
			or int(slot09_dispatch.get("bank_low", -1)) != 0x00 \
			or int(slot09_dispatch.get("bank_high", -1)) != 0x01:
		return _fail_result("Slot-$09 dispatch did not restore the fixed-bank `$EB86` root context.")
	_slot09_yield_result = _scheduler.execute_root_slot09_first_yield()
	if not bool(_slot09_yield_result.get("ok", false)) \
			or int(_slot09_yield_result.get("resume_pc", -1)) != 0xEB8B:
		return _fail_result("Slot-$09 did not save its first `$EB8B` continuation.")
	_phase = "awaiting_external_nmi"
	_last_source_boundary = "$EB8B"
	return {
		"ok": true,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"awaiting_external_nmi": true,
		"ppu_ctrl_shadow": int(_bootstrap_result.get("ppu_ctrl_shadow", -1)),
		"nmi_cadence_generated": false,
		"ppu_bus_events": [],
		"slot05_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
		"slot09_boundary": _scheduler.get_task_boundary_snapshot(SLOT_09),
		"initial_worker_exit_pc": int(_initial_worker_result.get("exit_pc", -1)),
		"initial_worker_exit_kind": String(_initial_worker_result.get("exit_kind", "")),
	}


## Consume one NMI edge already observed by the caller's PPU model. The frame
## label is diagnostic only; this method never creates an edge or a delay.
func advance_on_external_nmi(source_frame: int, ppu_ctrl_shadow: int) -> Dictionary:
	error_message = ""
	if _rng_source_replay != null and source_frame <= RNG_RECEIVER_SOURCE_FRAME \
			and source_frame > int(_rng_source_replay.get_state().get("last_source_frame", 0)):
		if not _rng_source_replay.advance_to_source_frame(source_frame):
			return _fail_result("ROM-only KICK OFF RNG replay could not advance through frame %d: " % source_frame + _rng_source_replay.error_message)
		if not _scheduler.adopt_kickoff_rng_source_replay_state(_rng_source_replay.get_state()):
			return _fail_result("Gameplay scheduler rejected the hash-bound ROM RNG event state: " + _scheduler.error_message)
	if _phase == "awaiting_external_nmi" \
			and _last_source_boundary == "$CB0F save -> scheduler WAIT_FOR_NMI_READY":
		return _advance_after_slot09_cb0f_wait(source_frame, ppu_ctrl_shadow)
	if not _configured or _phase != "awaiting_external_nmi":
		return _fail_result("Runner must be initialized and awaiting an external NMI edge.")
	if source_frame < 0 or source_frame <= _last_external_nmi_frame:
		return _fail_result("External NMI frame labels must be nonnegative and strictly increasing.")
	var source_boundary_before_nmi := _last_source_boundary
	var queue_guard_validated := false
	if not _pending_nmi_queue_state.is_empty():
		var live_queue_state: Dictionary = _scheduler.get_live_nmi_secondary_queue_state()
		if live_queue_state != _pending_nmi_queue_state:
			return _fail_result("Pending source `$0515/$04A5` queue changed after its producer boundary and before the caller-supplied NMI.")
		queue_guard_validated = true
	_last_external_nmi_frame = source_frame
	_last_nmi_result = _scheduler.service_external_nmi_delivery(
		source_frame, ppu_ctrl_shadow, true)
	if not bool(_last_nmi_result.get("ok", false)) or not bool(_last_nmi_result.get("serviced", false)):
		return _fail_result("Scheduler could not service the caller-confirmed NMI edge: " + _scheduler.error_message)

	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after external NMI failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	if scan.is_empty() or int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		return _fail_result("External-NMI scheduler did not select a yielded task: %s" % str(scan_results))
	var selected_slot := int(scan.get("selected_slot_base", -1))
	if selected_slot == SLOT_01:
		var slot01_dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_01)
		if not bool(slot01_dispatch.get("ok", false)) or int(slot01_dispatch.get("pc", -1)) != 0xCA52 \
				or String(slot01_dispatch.get("resume_path", "")) != "yielded_rts":
			return _fail_result("Root slot-$01 resume did not restore its source `$CA52` continuation.")
		var first_call: Dictionary = _root_slot01_continuation.begin_from_slot01_yielded_resume(slot01_dispatch)
		if not bool(first_call.get("ok", false)) \
				or String(first_call.get("status", "")) != "call_requested" \
				or int(first_call.get("source_pc", -1)) != 0xCA52 \
				or int(first_call.get("target_cpu_address", -1)) != 0xEE9F \
				or int(first_call.get("expected_return_pc", -1)) != 0xCA55:
			return _fail_result("Root slot-$01 continuation did not produce its source `$CA52->$EE9F` call request: " + _root_slot01_continuation.error_message)
		var slot01_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_01)
		var ee9f_result: Dictionary = _ee9f_empty_actor_executor.execute_to_source_caller(
			slot01_dispatch, slot01_boundary, first_call)
		if not bool(ee9f_result.get("ok", false)):
			return _fail_result("ROM-byte `$CA52->$EE9F` execution stopped: " \
					+ String(ee9f_result.get("reason", ee9f_result.get("error", "unknown source stop"))))
		_last_root_actor_loop_result = _summarize_actor_loop_result(source_frame, ee9f_result)
		if not _scheduler.adopt_root_slot01_callee_return_state(0xCA52, 0xEE9F, ee9f_result):
			return _fail_result("Scheduler rejected the source `$EE9F` return state: " + _scheduler.error_message)
		var slot01_after_ee9f_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_01)
		var after_ee9f: Dictionary = _root_slot01_continuation.accept_callee_return(
			0xEE9F, 0xCA55, ee9f_result.get("registers", {}))
		if not bool(after_ee9f.get("ok", false)) \
				or String(after_ee9f.get("status", "")) != "call_requested" \
				or int(after_ee9f.get("source_pc", -1)) != 0xCA55 \
				or int(after_ee9f.get("target_cpu_address", -1)) != 0xE3CA \
				or int(after_ee9f.get("expected_return_pc", -1)) != 0xCA58:
			return _fail_result("Root slot-$01 did not continue from `$CA55` to the source `$CA55->$E3CA` request: " + _root_slot01_continuation.error_message)
		var e3ca_result: Dictionary = _e3ca_no_direction_executor.execute_from_source_call(
			ee9f_result, after_ee9f)
		if not bool(e3ca_result.get("ok", false)):
			return _fail_result("ROM-byte `$CA55->$E3CA` execution stopped: " \
					+ String(e3ca_result.get("reason", e3ca_result.get("error", "unsupported source state"))))
		if not _scheduler.adopt_root_slot01_callee_return_state(0xCA55, 0xE3CA, e3ca_result):
			return _fail_result("Scheduler rejected the source `$E3CA` return state: " + _scheduler.error_message)
		var slot01_yield_request: Dictionary = _root_slot01_continuation.accept_callee_return(
			0xE3CA, 0xCA58, e3ca_result.get("registers", {}))
		if not bool(slot01_yield_request.get("ok", false)) \
				or String(slot01_yield_request.get("status", "")) != "yield_requested" \
				or int(slot01_yield_request.get("callsite_pc", -1)) != 0xCA4F:
			return _fail_result("Root slot-$01 did not return from `$E3CA` to its ROM `$CA4F` yield: " \
					+ _root_slot01_continuation.error_message)
		if not _scheduler.adopt_root_slot01_loop_yield_call_state(slot01_yield_request):
			return _fail_result("Scheduler rejected the source `$CA4F` yield request: " + _scheduler.error_message)
		if not _scheduler.yield_at_verified_callsite(SLOT_01, 0xCA4F,
				int(slot01_yield_request.get("delay_in_a", -1)),
				int(slot01_yield_request.get("sp", -1)),
				int(slot01_yield_request.get("x", -1)),
				int(slot01_yield_request.get("y", -1)),
				int(slot01_yield_request.get("bank_low", -1)),
				int(slot01_yield_request.get("bank_high", -1))):
			return _fail_result("Root slot-$01 could not save its source `$CA4F->$CB0F` yield: " + _scheduler.error_message)
		_last_root_e3ca_result = _summarize_e3ca_result(
			source_frame, e3ca_result, after_ee9f, slot01_yield_request, -1)
		var post_root_yield_scan: Dictionary = _scheduler.scan_ready_tasks_once()
		var post_root_selected_slot := int(post_root_yield_scan.get("selected_slot_base", -1))
		_last_root_e3ca_result = _summarize_e3ca_result(
			source_frame, e3ca_result, after_ee9f, slot01_yield_request, post_root_selected_slot)
		if bool(post_root_yield_scan.get("ok", false)) \
				and int(post_root_yield_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME) \
				and int(post_root_yield_scan.get("selected_slot_base", -1)) == SLOT_09:
			_pending_selected_task_slot = SLOT_09
			_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_09)
			var selected_ram: PackedByteArray = _pending_selected_task_boundary.get("ram_image", PackedByteArray())
			_pending_selected_task_mapper = {
				"bank_low": int(_pending_selected_task_boundary.get("bank_low", -1)),
				"bank_high": int(_pending_selected_task_boundary.get("bank_high", -1)),
				"select": ((int(selected_ram[0x0022]) | 0x07) & 0x07) if selected_ram.size() == 0x800 else -1,
			}
			_phase = "waiting_for_selected_task_source"
			_last_source_boundary = "$CAA5 selected slot $09 before task-body source"
			var post_root_ppu_bus_events: Array = _last_nmi_result.get("ppu_bus_events", [])
			return {
				"ok": true,
				"status": "nmi_resumed_slot01_then_selected_slot09",
				"phase": _phase,
				"source_frame": source_frame,
				"source_boundary_before_nmi": source_boundary_before_nmi,
				"external_nmi_consumed": true,
				"queue_guard_validated": queue_guard_validated,
				"normal_nmi_result": _last_nmi_result.duplicate(true),
				"scheduler_scan_results": scan_results.duplicate(true),
				"selected_task_slot_before_resume": SLOT_01,
				"root_slot01_yield_result": slot01_yield_request.duplicate(true),
				"post_root_yield_scan": post_root_yield_scan.duplicate(true),
				"next_selected_task_slot": SLOT_09,
				"next_selected_task_boundary": _pending_selected_task_boundary.duplicate(true),
				"next_selected_task_mapper": _pending_selected_task_mapper.duplicate(true),
				"ppu_bus_events": post_root_ppu_bus_events.duplicate(true),
				"ppu_bus_events_applied": false,
				"nmi_cadence_generated": false,
			}
		if bool(post_root_yield_scan.get("ok", false)) \
				and int(post_root_yield_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME) \
				and int(post_root_yield_scan.get("selected_slot_base", -1)) != SLOT_05:
			return _fail_result("Root slot-$01 yielded to an unintegrated task slot `$%02X`: %s" % [int(post_root_yield_scan.get("selected_slot_base", -1)), str(post_root_yield_scan)])
		if not bool(post_root_yield_scan.get("ok", false)) \
				or int(post_root_yield_scan.get("selected_slot_base", -1)) != SLOT_05 \
				or int(post_root_yield_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
			return _fail_result("The same ROM scheduler scan did not resume slot-$05 after root slot-$01 yielded: %s" % str(post_root_yield_scan))
		var slot05_dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_05)
		if not bool(slot05_dispatch.get("ok", false)) or int(slot05_dispatch.get("slot_base", -1)) != SLOT_05:
			return _fail_result("The same scheduler scan did not restore slot-$05's `$8889` worker continuation: %s" % str(slot05_dispatch))
		var slot05_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if int(slot05_dispatch.get("pc", -1)) == 0xCBC1:
			return _resume_slot05_scenario35_wait_cycle(slot05_dispatch, slot05_boundary)
		if int(slot05_dispatch.get("pc", -1)) == 0xDAE2:
			return _resume_slot05_scenario35_wait_resume_cycle(slot05_dispatch, slot05_boundary)
		if int(slot05_dispatch.get("pc", -1)) != 0x8889 \
				or int(slot05_dispatch.get("sp", -1)) != 0x4A \
				or int(slot05_dispatch.get("bank_low", -1)) != 0x18 \
				or int(slot05_dispatch.get("bank_high", -1)) != 0x19:
			return _fail_result("The same scheduler scan selected an unsupported slot-$05 continuation: %s" % str(slot05_dispatch))
		var e3ca_mapper: Dictionary = e3ca_result.get("mapper", {})
		var worker_resume_input := {
			"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": SLOT_05,
				"resume_path": "yielded_rts", "pc": 0x8889, "bank": 0x18,
				"source_dispatch_observed": true},
			"registers": {"a": int(slot05_dispatch.get("a", -1)),
				"x": int(slot05_dispatch.get("x", -1)),
				"y": int(slot05_dispatch.get("y", -1)),
				"sp": int(slot05_dispatch.get("sp", -1)), "pc": int(slot05_dispatch.get("pc", -1))},
			"mapper": {"bank_low": int(slot05_dispatch.get("bank_low", -1)),
				"bank_high": int(slot05_dispatch.get("bank_high", -1)),
				"select": int(e3ca_mapper.get("register_select", -1))},
			"ram_image": slot05_boundary.get("ram_image", PackedByteArray()),
			"stack_page": slot05_boundary.get("stack_page", PackedByteArray()),
		}
		var slot05_resume_result: Dictionary = _worker_prefix.resume_dispatched_slot05_worker(worker_resume_input)
		if not bool(slot05_resume_result.get("ok", false)) \
				or String(slot05_resume_result.get("exit_kind", "")) != "yield_at_c515" \
				or int(slot05_resume_result.get("exit_pc", -1)) != 0xC515:
			return _fail_result("Slot-$05 did not execute its source-backed callback and menu-worker path through `$8886->$C515`: " \
					+ str(slot05_resume_result.get("blocked_read", slot05_resume_result.get("error", _worker_prefix.error_message))))
		if not _scheduler.adopt_root_slot05_worker_resume_state(slot05_dispatch, slot05_boundary, slot05_resume_result):
			return _fail_result("Scheduler rejected the source-derived slot-$05 `$C515` state: " + _scheduler.error_message)
		var slot05_result_registers: Dictionary = slot05_resume_result.get("registers", {})
		var slot05_result_mapper: Dictionary = slot05_resume_result.get("mapper", {})
		if not _scheduler.yield_at_verified_callsite(SLOT_05, 0x8886,
				int(slot05_result_registers.get("a", -1)), int(slot05_result_registers.get("sp", -1)),
				int(slot05_result_registers.get("x", -1)), int(slot05_result_registers.get("y", -1)),
				int(slot05_result_mapper.get("bank_low", -1)), int(slot05_result_mapper.get("bank_high", -1))):
			return _fail_result("Scheduler could not save the live slot-$05 `$8886->$C515->$CB0F` yield: " + _scheduler.error_message)
		var post_slot05_scan_results: Array[Dictionary] = []
		var post_slot05_scan: Dictionary = {}
		for scan_index in range(8):
			post_slot05_scan = _scheduler.scan_ready_tasks_once()
			if not bool(post_slot05_scan.get("ok", false)):
				return _fail_result("Scheduler scan after slot-$05 yield failed: " + _scheduler.error_message)
			post_slot05_scan_results.append(post_slot05_scan.duplicate(true))
			if int(post_slot05_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
				break
		var next_task_dispatch: Dictionary = {}
		if int(post_slot05_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
			var next_slot := int(post_slot05_scan.get("selected_slot_base", -1))
			next_task_dispatch = _scheduler.dispatch_pending_task(next_slot)
			if not bool(next_task_dispatch.get("ok", false)):
				return _fail_result("Scheduler selected a task after the slot-$05 yield but could not restore its saved context: " + _scheduler.error_message)
			var next_task_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(next_slot)
			var dispatch_mapper: Dictionary = slot05_resume_result.get("mapper", {}).duplicate(true)
			var dispatch_ram: PackedByteArray = next_task_boundary.get("ram_image", PackedByteArray())
			dispatch_mapper["bank_low"] = int(next_task_dispatch.get("bank_low", -1))
			dispatch_mapper["bank_high"] = int(next_task_dispatch.get("bank_high", -1))
			# The yielded-resume branch at $CAB9 calls the checked $CE2D helper;
			# its last source select is $22 | $07, so MMC3 register 7 is selected.
			dispatch_mapper["select"] = (int(dispatch_ram[0x0022]) | 0x07) & 0x07
			next_task_dispatch["rom_sha256"] = ROM_SHA256
			next_task_dispatch["mapper"] = dispatch_mapper
			next_task_dispatch["ram_image"] = dispatch_ram
			next_task_dispatch["stack_page"] = next_task_boundary.get("stack_page", PackedByteArray())
			next_task_dispatch["task_record"] = next_task_boundary.get("record", PackedByteArray())
			var slot09_resume_result: Dictionary = _slot09_continuation_prefix.execute_from_next_task_dispatch(next_task_dispatch)
			if not bool(slot09_resume_result.get("ok", false)) \
					or int(slot09_resume_result.get("exit_pc", -1)) != 0x86F8:
				return _fail_result("Slot-$09 source prefix did not stop before the first bank-$18 worker body: " \
						+ str(slot09_resume_result.get("reason", _slot09_continuation_prefix.error_message)))
			next_task_dispatch["slot09_resume_result"] = slot09_resume_result
			var slot09_worker_result: Dictionary = _slot09_86f8_zero_branch_executor.execute_from_slot09_resume_result(slot09_resume_result)
			if not bool(slot09_worker_result.get("ok", false)) \
					or int(slot09_worker_result.get("exit_pc", -1)) != 0xEBB3:
				return _fail_result("Slot-$09 `$86F8` worker did not reach its supported zero-branch return at `$EBB3`: " \
						+ str(slot09_worker_result.get("reason", _slot09_86f8_zero_branch_executor.error_message)))
			next_task_dispatch["slot09_86f8_worker_result"] = slot09_worker_result
			var slot09_next_worker_result: Dictionary = _slot09_8779_zero_branch_executor.execute_from_86f8_worker_result(slot09_worker_result)
			if not bool(slot09_next_worker_result.get("ok", false)) \
					or int(slot09_next_worker_result.get("exit_pc", -1)) != 0xEBC5:
				return _fail_result("Slot-$09 `$8779` worker did not reach its supported zero-branch return at `$EBC5`: " \
						+ str(slot09_next_worker_result.get("reason", _slot09_8779_zero_branch_executor.error_message)))
			next_task_dispatch["slot09_8779_worker_result"] = slot09_next_worker_result
			var slot09_third_worker_result: Dictionary = _slot09_87e6_zero_branch_executor.execute_from_8779_worker_result(slot09_next_worker_result)
			if not bool(slot09_third_worker_result.get("ok", false)) \
					or int(slot09_third_worker_result.get("exit_pc", -1)) != 0xEBD7:
				return _fail_result("Slot-$09 `$87E6` worker did not reach its supported zero-state return at `$EBD7`: " \
						+ str(slot09_third_worker_result.get("reason", _slot09_87e6_zero_branch_executor.error_message)))
			next_task_dispatch["slot09_87e6_worker_result"] = slot09_third_worker_result
			var slot09_root_zero_result: Dictionary = _slot09_ebd7_root_zero_counter_executor.execute_from_87e6_result(slot09_third_worker_result)
			if not bool(slot09_root_zero_result.get("ok", false)) \
					or int(slot09_root_zero_result.get("exit_pc", -1)) != 0xCB0F:
				return _fail_result("Slot-$09 root loop did not reach its supported `$EB88->$CB0F` call at handler entry: " \
						+ str(slot09_root_zero_result.get("reason", _slot09_ebd7_root_zero_counter_executor.error_message)))
			next_task_dispatch["slot09_ebd7_root_zero_result"] = slot09_root_zero_result
			var slot09_cb0f_save_result: Dictionary = _scheduler.apply_slot09_cb0f_from_root_route_result(slot09_root_zero_result)
			if not bool(slot09_cb0f_save_result.get("ok", false)) \
					or String(slot09_cb0f_save_result.get("status", "")) != "slot09_saved_at_cb0f":
				return _fail_result("Scheduler rejected the source `$EB88->$CB0F` save result: " \
						+ _scheduler.error_message)
			next_task_dispatch["slot09_cb0f_save_result"] = slot09_cb0f_save_result
			var post_slot09_scan_results: Array[Dictionary] = []
			var post_slot09_scan: Dictionary = {}
			for scan_index in range(8):
				post_slot09_scan = _scheduler.scan_ready_tasks_once()
				if not bool(post_slot09_scan.get("ok", false)):
					return _fail_result("Scheduler scan after slot-$09 `$CB0F` save failed: " + _scheduler.error_message)
				post_slot09_scan_results.append(post_slot09_scan.duplicate(true))
				if int(post_slot09_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
					break
			if int(post_slot09_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
				return _fail_result("Post-save scheduler scan did not stop at its source-owned NMI-ready boundary: %s" % str(post_slot09_scan))
			next_task_dispatch["post_slot09_scan_results"] = post_slot09_scan_results
			next_task_dispatch["post_slot09_scan"] = post_slot09_scan
			_phase = "awaiting_external_nmi"
			_last_source_boundary = "$CB0F save -> scheduler WAIT_FOR_NMI_READY"
		elif int(post_slot05_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
			_phase = "awaiting_external_nmi"
			_last_source_boundary = "$8886->$C515"
		else:
			return _fail_result("Scheduler scan after slot-$05 yield ended without a task or external-NMI wait: %s" % str(post_slot05_scan))
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty():
			return _fail_result("The route could not capture the post-transition live NMI queue state.")
		return {
			"ok": true,
			"phase": _phase,
			"rom_sha256": ROM_SHA256,
			"external_nmi_frame": source_frame,
			"external_nmi_consumed": true,
			"source_boundary_before_nmi": source_boundary_before_nmi,
			"pending_queue_guard_validated": queue_guard_validated,
			"pending_queue_guard_captured_after_route": true,
			"nmi_cadence_generated": false,
			"nmi_result": _last_nmi_result.duplicate(true),
			"scan_results": scan_results,
			"slot01_dispatch": slot01_dispatch,
			"slot01_pre_ee9f_boundary": slot01_boundary,
			"slot01_after_ee9f_boundary": slot01_after_ee9f_boundary,
			"slot01_resume_boundary": _scheduler.get_task_boundary_snapshot(SLOT_01),
			"slot01_callee_request": first_call,
			"last_source_boundary": _last_source_boundary,
			"slot01_caller_bytes_executed": true,
			"ee9f_body_executed": true,
			"ee9f_result": ee9f_result,
			"slot01_e3ca_request": after_ee9f,
			"e3ca_body_executed": true,
			"e3ca_result": e3ca_result,
			"slot01_yield_request": slot01_yield_request,
			"slot01_yield_result": _scheduler.get_task_boundary_snapshot(SLOT_01),
			"post_root_yield_scan": post_root_yield_scan,
			"slot05_dispatch": slot05_dispatch,
			"slot05_boundary": slot05_boundary,
			"slot05_resume_input": worker_resume_input,
			"slot05_resume_result": slot05_resume_result,
			"slot05_worker_resumed": true,
			"slot05_yield_result": _scheduler.get_task_boundary_snapshot(SLOT_05),
			"slot05_yield_callsite_pc": 0x8886,
			"slot05_worker_yielded": true,
			"post_slot05_yield_scan_results": post_slot05_scan_results,
			"post_slot05_yield_scan": post_slot05_scan,
			"next_task_dispatch": next_task_dispatch,
			"slot09_resume_result": next_task_dispatch.get("slot09_resume_result", {}),
			"slot09_86f8_worker_result": next_task_dispatch.get("slot09_86f8_worker_result", {}),
			"slot09_8779_worker_result": next_task_dispatch.get("slot09_8779_worker_result", {}),
			"slot09_87e6_worker_result": next_task_dispatch.get("slot09_87e6_worker_result", {}),
			"slot09_ebd7_root_zero_result": next_task_dispatch.get("slot09_ebd7_root_zero_result", {}),
			"slot09_cb0f_save_result": next_task_dispatch.get("slot09_cb0f_save_result", {}),
			"slot09_cb0f_saved_boundary": _scheduler.get_task_boundary_snapshot(SLOT_09) if next_task_dispatch.has("slot09_cb0f_save_result") else {},
			"post_slot09_scan_results": next_task_dispatch.get("post_slot09_scan_results", []),
			"post_slot09_scan": next_task_dispatch.get("post_slot09_scan", {}),
			"scheduler_status": _scheduler.get_status(),
			"awaiting_external_nmi": _phase == "awaiting_external_nmi",
			"next_external_nmi_required": _phase == "awaiting_external_nmi",
			"menu_transfer_queue": {
				"ready_flag": int((slot05_resume_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x0515]),
				"progress": int((slot05_resume_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x05C5]),
				"frame_family": int((slot05_resume_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x05C6]),
				"first_two_packets": (slot05_resume_result.get("ram_image", PackedByteArray()) as PackedByteArray).slice(0x04A5, 0x04B9),
			},
			"ppu_bus_events": _last_nmi_result.get("ppu_bus_events", []),
			"ppu_bus_events_applied": false,
		}
	return _fail_result("External NMI selected slot $%02X; this runner currently supports only the observed first root slot-$01 resume." % selected_slot)


## Resume the actual slot-$05 task selected by the live scheduler. Preserve its
## source yield behavior, or adopt the bounded descriptor row and stop before
## the next unsupported text row.
func resume_selected_slot05_worker() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_05 \
			or not String(_last_source_boundary).contains("scheduler selected slot $05"):
		return _fail_result("Slot-$05 worker resume requires the live second-NMI scheduler boundary that selected slot `$05`.")
	if _pending_slot05_mapper_select < 0 or _pending_slot05_mapper_select > 0xFF:
		return _fail_result("Slot-$05 worker resume lacks the source-produced MMC3 selector from the live `$E3CA` return.")
	if _fresh_period_result.is_empty():
		return _fail_result("Slot-$05 descriptor tokens require the earlier ROM-produced fresh-period result.")
	var pending_boundary := _pending_selected_task_boundary
	var pre_dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if pre_dispatch_boundary.is_empty() \
			or int(pre_dispatch_boundary.get("slot_base", -1)) != SLOT_05 \
			or int(pre_dispatch_boundary.get("active_task_slot", -1)) != -1 \
			or int(pre_dispatch_boundary.get("pc", -1)) != int(pending_boundary.get("pc", -2)) \
			or int(pre_dispatch_boundary.get("ready_delay", -1)) != int(pending_boundary.get("ready_delay", -2)) \
			or pre_dispatch_boundary.get("record", PackedByteArray()) != pending_boundary.get("record", PackedByteArray()) \
			or pre_dispatch_boundary.get("ram_image", PackedByteArray()) != pending_boundary.get("ram_image", PackedByteArray()) \
			or pre_dispatch_boundary.get("stack_page", PackedByteArray()) != pending_boundary.get("stack_page", PackedByteArray()):
		return _fail_result("The live slot-$05 scheduler state changed after selection; refusing a stale dispatch.")
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_05)
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xCBC1:
		return _resume_slot05_scenario35_wait_cycle(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xDAE2:
		return _resume_slot05_scenario35_wait_resume_cycle(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19:
		return _fail_result("Actual scheduler dispatch did not restore slot-$05's yielded bank-$18 `$8889` continuation.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var worker_input := {
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": SLOT_05,
			"resume_path": "yielded_rts", "pc": int(dispatch.get("pc", -1)),
			"bank": 0x18, "source_dispatch_observed": true},
		"registers": {"a": int(dispatch.get("a", -1)),
			"x": int(dispatch.get("x", -1)), "y": int(dispatch.get("y", -1)),
			"sp": int(dispatch.get("sp", -1)), "pc": int(dispatch.get("pc", -1))},
		"mapper": {"bank_low": int(dispatch.get("bank_low", -1)),
			"bank_high": int(dispatch.get("bank_high", -1)),
			"select": _pending_slot05_mapper_select},
		"ram_image": boundary.get("ram_image", PackedByteArray()),
		"stack_page": boundary.get("stack_page", PackedByteArray()),
	}
	var descriptor_contract: Dictionary = _field_entry_packet_source.build_descriptor_00(
		_fresh_period_result)
	var unresolved_tokens: Array = descriptor_contract.get("unresolved_source_tokens", [])
	if not bool(descriptor_contract.get("ok", false)) \
			or not bool(descriptor_contract.get("packet_data_complete", false)) \
			or not bool(descriptor_contract.get("source_inputs_ready", false)) \
			or not unresolved_tokens.is_empty():
		return _stop_slot05_before_worker(dispatch, boundary, worker_input,
			"descriptor_worker_contract_unresolved", String(_field_entry_packet_source.last_error),
			descriptor_contract, {})
	var worker_descriptor_contract: Dictionary = _worker_prefix.validate_resumed_worker_descriptor_contract(worker_input)
	if not bool(worker_descriptor_contract.get("ok", false)):
		return _stop_slot05_before_worker(dispatch, boundary, worker_input,
			String(worker_descriptor_contract.get("status", "descriptor_source_invalid")),
			String(worker_descriptor_contract.get("reason", _worker_prefix.error_message)),
			descriptor_contract, worker_descriptor_contract)
	var worker_result: Dictionary = _worker_prefix.resume_dispatched_slot05_worker(worker_input, 0xBD9C)
	var accepted_unresolved_c509 := not bool(worker_result.get("ok", false)) \
			and String(worker_result.get("exit_kind", "")) == "unresolved_source_span" \
			and int(worker_result.get("exit_pc", -1)) == 0xC509
	var blocked_read_variant: Variant = worker_result.get("blocked_read", {})
	var blocked_read: Dictionary = blocked_read_variant if blocked_read_variant is Dictionary else {}
	var accepted_f0_token_boundary := not bool(worker_result.get("ok", false)) \
			and String(worker_result.get("exit_kind", "")) == "unresolved_source_span" \
			and int(worker_result.get("exit_pc", -1)) == 0x89A0 \
			and int(blocked_read.get("instruction_pc", -1)) == 0x89A0 \
			and int(blocked_read.get("requested_address", -1)) == 0xBBDE \
			and int(blocked_read.get("bank", -1)) == 0x19 \
			and String(worker_descriptor_contract.get("status", "")) == "descriptor_source_validated_for_live_worker" \
			and bool(descriptor_contract.get("packet_data_complete", false)) \
			and bool(descriptor_contract.get("source_inputs_ready", false))
	var ed_row_boundary: Dictionary = _worker_prefix.validate_descriptor01_ed_row00_boundary(
		worker_input, worker_result)
	var accepted_ed_row00_boundary := bool(ed_row_boundary.get("ok", false))
	var unsupported_opcode_variant: Variant = worker_result.get("unsupported_opcode", {})
	var unsupported_opcode: Dictionary = unsupported_opcode_variant \
		if unsupported_opcode_variant is Dictionary else {}
	var accepted_f0_division_opcode_boundary := not bool(worker_result.get("ok", false)) \
			and String(worker_result.get("exit_kind", "")) == "unsupported_source_opcode" \
			and int(worker_result.get("exit_pc", -1)) == 0xCD52 \
			and int(worker_result.get("exit_bank", -1)) == 0x1E \
			and int(unsupported_opcode.get("pc", -1)) == 0xCD52 \
			and int(unsupported_opcode.get("bank", -1)) == 0x1E \
			and int(unsupported_opcode.get("opcode", -1)) == 0xC5
	var scenario35_enqueue_validation: bool = _scheduler.validate_slot05_scenario35_enqueue_worker_result(worker_result)
	if not bool(worker_result.get("ok", false)) \
			and not accepted_unresolved_c509 and not accepted_f0_token_boundary \
			and not accepted_f0_division_opcode_boundary and not accepted_ed_row00_boundary \
			and not scenario35_enqueue_validation:
		return _stop_slot05_before_worker(dispatch, boundary, worker_input,
			String(worker_result.get("exit_kind", "unsupported_worker_state")),
			str(worker_result.get("error", worker_result.get("blocked_read", _worker_prefix.error_message))),
			descriptor_contract, worker_descriptor_contract, worker_result)
	if not _scheduler.adopt_root_slot05_worker_resume_state(dispatch, boundary, worker_result,
			descriptor_contract, worker_descriptor_contract):
		return _fail_result("Scheduler rejected slot-$05 source writes: " + _scheduler.error_message)
	var worker_adopted_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if accepted_f0_token_boundary:
		_phase = "stopped_at_slot05_f0_token_boundary"
		_last_source_boundary = "slot-$05 worker stopped before unsupported `$F0` token at `$89A0->$BBDE`"
		var token_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		return _slot05_resume_result("stopped_at_descriptor_f0_boundary", dispatch, boundary,
			worker_input, descriptor_contract, worker_descriptor_contract, worker_result,
			token_boundary, {}, [], -1, {}, true)
	if accepted_ed_row00_boundary:
		_last_slot05_source_worker_result = worker_result.duplicate(true)
		_phase = "stopped_at_slot05_descriptor01_next_row_boundary"
		_last_source_boundary = "slot-$05 worker returned from `$BBE0` `$ED 00 FC` and stopped before `$BD9C` `$EE`"
		var ed_boundary_snapshot: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var ed_result := _slot05_resume_result("stopped_at_descriptor01_ee_row_boundary", dispatch,
			boundary, worker_input, descriptor_contract, worker_descriptor_contract, worker_result,
			{}, {}, [], -1, {}, true, "", ed_boundary_snapshot)
		ed_result["slot05_ed_row_boundary_validation"] = ed_row_boundary.duplicate(true)
		return ed_result
	if accepted_f0_division_opcode_boundary:
		_phase = "stopped_at_slot05_f0_division_opcode_boundary"
		_last_source_boundary = "slot-$05 F0 callback stopped at unsupported `$CD52 CMP $74`"
		var division_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		return _slot05_resume_result("stopped_at_f0_division_opcode_boundary", dispatch, boundary,
			worker_input, descriptor_contract, worker_descriptor_contract, worker_result,
			division_boundary, {}, [], -1, {}, true)
	if accepted_unresolved_c509:
		_phase = "stopped_at_slot05_c509_source_boundary"
		_last_source_boundary = "slot-$05 worker source read blocked at `$C509`"
		return _slot05_resume_result("stopped_at_source_boundary", dispatch, boundary,
			worker_input, descriptor_contract, worker_descriptor_contract, worker_result,
			{}, {}, [], -1, {}, false)
	var result_registers: Dictionary = worker_result.get("registers", {})
	var result_mapper: Dictionary = worker_result.get("mapper", {})
	var yield_callsite_pc := 0x8886
	var caller_stack_pointer := int(result_registers.get("sp", -1))
	var call_frame_already_pushed := false
	if scenario35_enqueue_validation:
		yield_callsite_pc = 0xCBBE
		caller_stack_pointer = (caller_stack_pointer + 2) & 0xFF
		call_frame_already_pushed = true
	if not _scheduler.yield_at_verified_callsite(SLOT_05, yield_callsite_pc,
			int(result_registers.get("a", -1)), caller_stack_pointer,
			int(result_registers.get("x", -1)), int(result_registers.get("y", -1)),
			int(result_mapper.get("bank_low", -1)), int(result_mapper.get("bank_high", -1)),
			call_frame_already_pushed):
		return _fail_result("Scheduler could not save the source slot-$05 callsite `$%04X->$CB0F`: " % yield_callsite_pc + _scheduler.error_message)
	var saved_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after slot-$05 save failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot == SLOT_09:
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary)
			if _pending_selected_task_mapper.is_empty():
				return _fail_result("The selected slot-$09 boundary omitted its mapper/RAM snapshot.")
		else:
			_pending_selected_task_mapper.clear()
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X before task-body source" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "slot-$05 saved at `$CB0F`; scheduler WAIT_FOR_NMI_READY"
	else:
		_phase = "stopped_at_slot05_post_yield_scheduler_boundary"
		_last_source_boundary = "slot-$05 saved at `$CB0F`; scheduler decision $%02X" % int(scan.get("decision", -1))
	var result := _slot05_resume_result("slot05_saved_and_rescanned", dispatch, boundary,
		worker_input, descriptor_contract, worker_descriptor_contract, worker_result,
		saved_boundary, scan, scan_results, next_slot, next_boundary, true, "",
		worker_adopted_boundary)
	if scenario35_enqueue_validation:
		result["slot05_scenario35_enqueue_validated"] = true
		result["slot05_scenario35_queue_bytes"] = PackedByteArray([0x80, 0x80, 0x00, 0x35])
		result["slot05_cb0f_callsite_pc"] = yield_callsite_pc
	return result


## Continue the already-running slot-$05 source worker through one descriptor
## row, consuming only the current scheduler snapshot at `$89A0->$BD9C`.
## Executes the live `$DAF2->$DC07` request with formation/side values already
## produced by the route's ROM-derived match context, then adopts `$DAF5`.
func resume_slot05_dc07_position_initializer(match_context: Dictionary) -> Dictionary:
	if not _configured:
		return _fail_result("The source route must be configured before executing `$DC07`.")
	if _phase != "stopped_at_slot05_dc07_call_boundary" or _pending_selected_task_slot != SLOT_05:
		return _fail_result("The route is not stopped at the live slot-$05 `$DAF2 JSR $DC07` boundary.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var initializer_result: Dictionary = _player_position_initializer.execute_from_live_call(
		boundary, match_context)
	if not bool(initializer_result.get("ok", false)):
		return _fail_result("ROM-derived `$DC07` position initialization failed: " \
				+ String(initializer_result.get("error", _player_position_initializer.error_message)))
	if not _scheduler.adopt_slot05_dc07_position_initializer_result(boundary, initializer_result):
		return _fail_result("Scheduler rejected the `$DC07->$DAF5` RAM/stack return: " + _scheduler.error_message)
	_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(_pending_selected_task_boundary)
	_phase = "stopped_at_slot05_daf5_position_return_boundary"
	_last_source_boundary = "ROM-derived `$DC07` wrote the 22 match-zero player records and returned to `$DAF5`; caller continuation is next"
	return {
		"ok": true,
		"status": _phase,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"external_nmi_consumed": true,
		"nmi_cadence_generated": false,
		"last_source_boundary": _last_source_boundary,
		"initializer_result": initializer_result.duplicate(true),
		"slot05_boundary_after_initializer": _pending_selected_task_boundary.duplicate(true),
		"awaiting_external_nmi": false,
		"next_external_nmi_required": false,
	}


## Continues from `$DAF5`, derives the receiver slot from live `$00E2/$05FB`
## and ROM table `$DC82`, then stops before executing `$E6EC`.
func resume_slot05_daf5_receiver_caller(match_context: Dictionary) -> Dictionary:
	if not _configured:
		return _fail_result("The source route must be configured before executing the receiver caller.")
	if _phase != "stopped_at_slot05_daf5_position_return_boundary" \
			or _pending_selected_task_slot != SLOT_05:
		return _fail_result("The route is not stopped at the live slot-$05 `$DAF5` boundary.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var receiver_result: Dictionary = _daf5_receiver_caller.execute_from_live_boundary(
		boundary, match_context)
	if not bool(receiver_result.get("ok", false)):
		return _fail_result("ROM-derived receiver selection failed: " \
				+ String(receiver_result.get("error", _daf5_receiver_caller.error_message)))
	if not _scheduler.adopt_slot05_daf5_receiver_caller_result(boundary, receiver_result):
		return _fail_result("Scheduler rejected the receiver `$DAF5->$DB0B->$E6EC` boundary: " + _scheduler.error_message)
	_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(_pending_selected_task_boundary)
	_phase = "stopped_at_slot05_e6ec_holder_call_boundary"
	_last_source_boundary = "ROM `$DAF5` selected receiver `$%02X`, wrote `$05FC`, and called `$E6EC`; holder-copy callee is next" % int(receiver_result.get("entry", {}).get("receiver_slot", -1))
	return {
		"ok": true,
		"status": _phase,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"external_nmi_consumed": true,
		"nmi_cadence_generated": false,
		"last_source_boundary": _last_source_boundary,
		"receiver_result": receiver_result.duplicate(true),
		"slot05_boundary_after_receiver_call": _pending_selected_task_boundary.duplicate(true),
		"awaiting_external_nmi": false,
		"next_external_nmi_required": false,
	}


## Executes the holder record lookup/copy and `$CDE2` tile-index helper from
## the live `$E6EC` boundary. Stops at `$DB0E`, before scenario `$36` begins.
func resume_slot05_e6ec_holder_copy(match_context: Dictionary) -> Dictionary:
	if not _configured:
		return _fail_result("The source route must be configured before executing the holder copy.")
	if _phase != "stopped_at_slot05_e6ec_holder_call_boundary" \
			or _pending_selected_task_slot != SLOT_05:
		return _fail_result("The route is not stopped at the live slot-$05 `$E6EC` boundary.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var holder_result: Dictionary = _e6ec_holder_copy_executor.execute_from_live_boundary(
		boundary, match_context)
	if not bool(holder_result.get("ok", false)):
		return _fail_result("ROM-derived `$E6EC` holder copy failed: " \
				+ String(holder_result.get("error", _e6ec_holder_copy_executor.error_message)))
	if not _scheduler.adopt_slot05_e6ec_holder_copy_result(boundary, holder_result):
		return _fail_result("Scheduler rejected the `$E6EC->$DB0E` holder-copy return: " + _scheduler.error_message)
	_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(_pending_selected_task_boundary)
	_phase = "stopped_before_slot05_scenario36_db0e"
	var holder: Dictionary = holder_result.get("holder_copy", {})
	_last_source_boundary = "ROM `$E6EC` copied holder slot `$%02X` coordinates and returned at `$DB0E`; scenario `$36` is next" % int(holder.get("holder_slot_0441", -1))
	return {
		"ok": true,
		"status": _phase,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"external_nmi_consumed": true,
		"nmi_cadence_generated": false,
		"last_source_boundary": _last_source_boundary,
		"holder_copy_result": holder_result.duplicate(true),
		"slot05_boundary_before_scenario36": _pending_selected_task_boundary.duplicate(true),
		"awaiting_external_nmi": false,
		"next_external_nmi_required": false,
	}


## Executes the fresh scenario-$36 caller and saves its real nested JSR frame
## at the ROM `$CB0F` task-yield boundary.
func resume_slot05_scenario36_enqueue() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "stopped_before_slot05_scenario36_db0e" \
			or _pending_selected_task_slot != SLOT_05:
		return _fail_result("Scenario `$36` requires the live slot-$05 `$DB0E` boundary.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var queue_result: Dictionary = _scenario36_queue_executor.execute_from_live_boundary(boundary)
	if not bool(queue_result.get("ok", false)):
		return _fail_result("ROM-derived scenario-$36 queue caller failed: " \
				+ String(queue_result.get("error", _scenario36_queue_executor.error_message)))
	if not _scheduler.adopt_slot05_scenario36_queue_result(boundary, queue_result):
		return _fail_result("Scheduler rejected the `$CBBE->$CB0F` scenario-$36 yield: " + _scheduler.error_message)
	var saved_slot05_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after scenario-$36 yield failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot == SLOT_09:
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary)
			if _pending_selected_task_mapper.is_empty():
				return _fail_result("The selected slot-$09 boundary omitted its mapper/RAM snapshot.")
		else:
			_pending_selected_task_mapper.clear()
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_phase = "waiting_for_selected_task_source" if next_slot == SLOT_09 else "stopped_at_scenario36_unexpected_task_selection"
		_last_source_boundary = "$CAA5 scenario `$36` slot `$05` save selected slot `$%02X` before task body" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "scenario `$36` slot `$05` saved at `$CB0F`; scheduler WAIT_FOR_NMI_READY"
	else:
		_phase = "stopped_at_scenario36_post_yield_scheduler_boundary"
		_last_source_boundary = "scenario `$36` slot `$05` saved at `$CB0F`; scheduler decision $%02X" % int(scan.get("decision", -1))
	return {
		"ok": true,
		"status": "scenario36_queued_slot05_yielded_and_scheduler_scanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"scenario36_queue_result": queue_result.duplicate(true),
		"slot05_yielded_task_boundary": saved_slot05_boundary,
		"scheduler_scan_results": scan_results,
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary,
		"next_external_nmi_required": _phase == "awaiting_external_nmi",
		"nmi_cadence_generated": false,
	}


func resume_slot05_descriptor01_ee_row00() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "stopped_at_slot05_descriptor01_next_row_boundary" \
			or _last_slot05_source_worker_result.is_empty():
		return _fail_result("The slot-$05 `$EE` continuation requires the adopted `$BD9C` worker boundary.")
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var worker_result: Dictionary = _worker_prefix.resume_slot05_live_worker_boundary(
		live_boundary, _last_slot05_source_worker_result)
	if worker_result.is_empty():
		return _fail_result("The live `$BD9C` worker continuation failed before returning a boundary: " + _worker_prefix.error_message)
	var validation: Dictionary = _worker_prefix.validate_descriptor01_ee_row00_boundary(
		live_boundary, _last_slot05_source_worker_result, worker_result)
	if not bool(validation.get("ok", false)):
		return _fail_result("The `$EE 00 FC` continuation failed validation: %s" % str(validation))
	if not _scheduler.adopt_active_slot05_worker_continuation_state(
		live_boundary, _last_slot05_source_worker_result, worker_result):
		return _fail_result("Scheduler rejected the source-derived `$EE` worker writes: " + _scheduler.error_message)
	_last_slot05_ee_row_result = worker_result.duplicate(true)
	_phase = "stopped_after_slot05_descriptor01_ee_row00_yield"
	_last_source_boundary = "slot-$05 returned from `$BD9C` `$EE 00 FC` and reached `$C515`; descriptor lists `$BBE3` next, but the live pointer remains `$BD9C`"
	var adopted_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	return {
		"ok": true,
		"status": "stopped_after_descriptor01_ee_row00_yield",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"live_input_boundary": live_boundary.duplicate(true),
		"parent_worker_result": _last_slot05_source_worker_result.duplicate(true),
		"slot05_worker_result": worker_result.duplicate(true),
		"slot05_ee_row_boundary_validation": validation.duplicate(true),
		"slot05_worker_adopted": true,
		"slot05_worker_adopted_boundary": adopted_boundary.duplicate(true),
		"next_descriptor_row_cpu": 0xBBE3,
		"next_descriptor_row_pointer_live": false,
		"next_row_bytes_read": false,
		"live_text_pointer_after_row": int((worker_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x003E]) \
			| (int((worker_result.get("ram_image", PackedByteArray()) as PackedByteArray)[0x003F]) << 8),
		"scheduler_scan_performed": false,
		"nmi_cadence_generated": false,
	}


func _resume_slot05_scenario35_wait_cycle(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var return_result: Dictionary = _slot05_scenario35_return_executor.execute_from_live_dispatch(
		dispatch, boundary)
	if not bool(return_result.get("ok", false)):
		return _fail_result("ROM-byte slot-$05 `$CBC1 RTS` stopped: " \
				+ String(return_result.get("error", _slot05_scenario35_return_executor.error_message)))
	if not _scheduler.adopt_slot05_scenario35_return_state(dispatch, boundary, return_result):
		return _fail_result("Scheduler rejected the live `$CBC1->$DADD` return: " + _scheduler.error_message)
	var caller_result: Dictionary = _continuation.execute_after_scenario_return(return_result)
	if not bool(caller_result.get("ok", false)) or int(caller_result.get("exit_pc", -1)) != 0xDADF:
		return _fail_result("ROM-byte scenario caller did not reach `$DADF->$CB0F`: " + _continuation.error_message)
	if not _scheduler.adopt_slot05_scenario35_wait_callsite_state(return_result, caller_result):
		return _fail_result("Scheduler rejected the source `$DADD LDA #$01` wait callsite: " + _scheduler.error_message)
	return _yield_slot05_scenario35_wait_callsite(caller_result, return_result)


func _resume_slot05_scenario35_wait_resume_cycle(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var caller_result: Dictionary = _continuation.execute_scenario35_wait_resume(dispatch, boundary)
	if not bool(caller_result.get("ok", false)):
		return _fail_result("ROM-byte `$DAE2` scenario wait test failed: " + _continuation.error_message)
	if int(caller_result.get("exit_pc", -1)) == 0xDAE9:
		return _fail_result("Scenario-$35 wait bit became set at `$DAE2`; live `$DAE9` caller source is not yet integrated (observed `$001C=$%02X`)." % int(caller_result.get("wait_flags", -1)))
	if int(caller_result.get("exit_pc", -1)) == 0xDAF2:
		if not _scheduler.adopt_slot05_scenario35_input_call_state(dispatch, boundary, caller_result):
			return _fail_result("Scheduler rejected the source `$DAE2->$DAF2->$DC07` input-call boundary: " + _scheduler.error_message)
		_pending_selected_task_slot = SLOT_05
		_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(_pending_selected_task_boundary)
		_phase = "stopped_at_slot05_dc07_call_boundary"
		_last_source_boundary = "$DAF2 JSR $DC07 requested; ROM-derived position initializer is the next callee"
		return {"ok": true, "status": "stopped_at_slot05_dc07_call_boundary",
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"external_nmi_consumed": true, "nmi_cadence_generated": false,
			"last_source_boundary": _last_source_boundary,
			"slot05_wait_result": caller_result.duplicate(true),
			"slot05_boundary_after_input": _pending_selected_task_boundary.duplicate(true),
			"position_initializer_call_request": caller_result.get("position_initializer_call_request", {}).duplicate(true),
			"awaiting_external_nmi": false, "next_external_nmi_required": false}
	if not _scheduler.adopt_slot05_scenario35_wait_resume_state(dispatch, boundary, caller_result):
		return _fail_result("Scheduler rejected the source `$DAE2->$DADF` wait-loop result: " + _scheduler.error_message)
	return _yield_slot05_scenario35_wait_callsite(caller_result)


func _yield_slot05_scenario35_wait_callsite(caller_result: Dictionary,
		return_result: Dictionary = {}) -> Dictionary:
	var registers: Dictionary = caller_result.get("registers", {})
	var mapper: Dictionary = caller_result.get("mapper", {})
	if not _scheduler.yield_at_verified_callsite(SLOT_05, 0xDADF,
			int(registers.get("a", -1)), int(registers.get("sp", -1)),
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))):
		return _fail_result("Slot-$05 could not save its ROM `$DADF->$CB0F` wait yield: " + _scheduler.error_message)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after resumed slot-$05 yield failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var waiting_for_nmi := false
	if int(scan.get("decision", -1)) in [int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME),
			int(SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH)]:
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot < 0 or next_boundary.is_empty() \
				or int(next_boundary.get("active_task_slot", -1)) != -1:
			return _fail_result("Scheduler did not expose a stable next task boundary after slot-$05 resumed.")
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		if next_slot == SLOT_09:
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary)
			if _pending_selected_task_mapper.is_empty():
				return _fail_result("Selected slot-$09 boundary omitted its ROM-owned mapper context.")
		_phase = "waiting_for_selected_task_source"
		if next_slot == SLOT_09:
			_last_source_boundary = "$CAA5 selected slot $09 before task-body source"
		elif next_slot == SLOT_05:
			_last_source_boundary = "$CAA5 scheduler selected slot $05 after scenario wait"
		else:
			_last_source_boundary = "$CAA5 selected slot $%02X after slot-$05 scenario wait" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty():
			return _fail_result("Resumed slot-$05 yield reached NMI wait without its source queue signature.")
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CB0F slot-$05 scenario wait save -> scheduler WAIT_FOR_NMI_READY"
		waiting_for_nmi = true
	else:
		return _fail_result("Scheduler ended at an unsupported slot-$05 scenario-wait decision: %s" % str(scan))
	return {"ok": true, "status": "slot05_scenario35_wait_yielded",
		"phase": _phase, "rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"slot05_scenario_return_result": return_result.duplicate(true),
		"slot05_scenario_wait_result": caller_result.duplicate(true),
		"slot05_yield_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
		"post_slot05_scan_results": scan_results,
		"post_slot05_scan": scan,
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary,
		"awaiting_external_nmi": waiting_for_nmi,
		"external_nmi_consumed": true,
		"nmi_cadence_generated": false, "ppu_bus_events_applied": false}


## Applies the verified `$C515->$CB0F` task save to the just-completed live
## `$EE 00 FC` worker, then scans to the next selected-task or NMI-wait
## boundary. This does not dispatch that task or generate an NMI.
func save_slot05_ee_row_yield_and_scan() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "stopped_after_slot05_descriptor01_ee_row00_yield" \
			or _last_slot05_ee_row_result.is_empty():
		return _fail_result("The `$CB0F` transition requires the live slot-$05 `$C515` boundary from the `$EE 00 FC` worker.")
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var worker: Dictionary = _last_slot05_ee_row_result
	var registers: Dictionary = worker.get("registers", {})
	var mapper: Dictionary = worker.get("mapper", {})
	var calls: Array = worker.get("calls", [])
	var worker_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var worker_stack: PackedByteArray = worker.get("stack_page", PackedByteArray())
	if int(live_boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(live_boundary.get("phase", -1)) != 2 \
			or int(live_boundary.get("pc", -1)) != 0xC515 \
			or int(live_boundary.get("sp", -1)) != int(registers.get("sp", -2)) \
			or int(live_boundary.get("a", -1)) != int(registers.get("a", -2)) \
			or int(live_boundary.get("x", -1)) != int(registers.get("x", -2)) \
			or int(live_boundary.get("y", -1)) != int(registers.get("y", -2)) \
			or int(live_boundary.get("bank_low", -1)) != 0x18 \
			or int(live_boundary.get("bank_high", -1)) != 0x19 \
			or worker_ram.size() != 0x800 or worker_stack.size() != 0x100 \
			or live_boundary.get("ram_image", PackedByteArray()) != worker_ram \
			or live_boundary.get("stack_page", PackedByteArray()) != worker_stack \
			or int(worker.get("exit_pc", -1)) != 0xC515 \
			or String(worker.get("exit_kind", "")) != "yield_at_c515" \
			or String(worker.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker.get("source_manifest_sha256", "")) != "d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad":
		return _fail_result("The live `$C515` CPU, mapper, RAM, stack, or ROM-worker provenance changed; refusing `$CB0F` save.")
	if int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19:
		return _fail_result("The live `$C515` worker mapper pair is not `$18/$19`.")
	var yield_call_found := false
	for call_variant in calls:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) == 0x8886 \
					and int(call.get("target", -1)) == 0xC515 \
					and int(call.get("sp_after_push", -1)) == int(registers.get("sp", -2)):
				yield_call_found = true
	var worker_sp := int(registers.get("sp", -1))
	if not yield_call_found or worker_sp < 0 \
			or int(worker_stack[(worker_sp + 1) & 0xFF]) != 0x88 \
			or int(worker_stack[(worker_sp + 2) & 0xFF]) != 0x88:
		return _fail_result("The source worker did not retain the `$8886 JSR $C515` return frame needed by `$CB0F`.")
	if not _scheduler.yield_at_verified_callsite(SLOT_05, 0x8886,
			int(registers.get("a", -1)), worker_sp,
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))):
		return _fail_result("Scheduler rejected the source `$C515->$CB0F` task save: " + _scheduler.error_message)
	var saved_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after live slot-$05 `$CB0F` save failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var waiting_for_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME) \
			or int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot < 0 or next_boundary.is_empty() \
				or int(next_boundary.get("active_task_slot", -1)) != -1:
			return _fail_result("Post-save scan did not expose a stable selected-task pre-dispatch boundary.")
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		if next_slot == SLOT_09:
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary)
			if _pending_selected_task_mapper.is_empty():
				return _fail_result("The selected slot-$09 boundary omitted its mapper/RAM snapshot.")
		else:
			_pending_selected_task_mapper.clear()
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X before task-body source" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CB0F save -> scheduler WAIT_FOR_NMI_READY"
		waiting_for_nmi = true
	else:
		return _fail_result("Post-save scan stopped at an unsupported decision: %s" % str(scan))
	var next_task_wait := waiting_for_nmi
	return {
		"ok": true,
		"status": "slot05_ee_row_cb0f_saved_and_scanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"slot05_worker_result": worker.duplicate(true),
		"slot05_cb0f_saved_boundary": saved_boundary.duplicate(true),
		"post_slot05_scan_results": scan_results.duplicate(true),
		"post_slot05_scan": scan.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"next_task_body_executed": false,
		"awaiting_external_nmi": next_task_wait,
		"nmi_cadence_generated": false,
		"ppu_bus_events_applied": false,
	}


func _stop_slot05_before_worker(dispatch: Dictionary, boundary: Dictionary,
		worker_input: Dictionary, status: String, reason: String,
		descriptor_contract: Dictionary, worker_descriptor_contract: Dictionary,
		worker_result: Dictionary = {}) -> Dictionary:
	_phase = "stopped_before_slot05_worker"
	_last_source_boundary = "slot-$05 live yielded dispatch `$8889`; worker not executed"
	_pending_selected_task_slot = SLOT_05
	return _slot05_resume_result(status, dispatch, boundary, worker_input,
		descriptor_contract, worker_descriptor_contract, worker_result, {}, {}, [],
		-1, {}, false, reason)


func _slot05_resume_result(status: String, dispatch: Dictionary, boundary: Dictionary,
		worker_input: Dictionary, descriptor_contract: Dictionary,
		worker_descriptor_contract: Dictionary, worker_result: Dictionary,
		saved_boundary: Dictionary, scan: Dictionary, scan_results: Array,
		next_slot: int, next_boundary: Dictionary, worker_adopted: bool,
		reason: String = "", worker_adopted_boundary: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"status": status,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"reason": reason,
		"selected_task_slot_before_resume": SLOT_05,
		"slot05_dispatch": dispatch.duplicate(true),
		"slot05_live_boundary": boundary.duplicate(true),
		"slot05_worker_input": worker_input.duplicate(true),
		"slot05_descriptor_contract": descriptor_contract.duplicate(true),
		"slot05_worker_descriptor_contract": worker_descriptor_contract.duplicate(true),
		"slot05_worker_result": worker_result.duplicate(true),
		"slot05_worker_adopted": worker_adopted,
		"slot05_worker_adopted_boundary": worker_adopted_boundary.duplicate(true),
		"slot05_post_worker_boundary": saved_boundary.duplicate(true),
		"slot05_cb0f_saved_boundary": saved_boundary if int(saved_boundary.get("pc", -1)) == 0xCB0F else {},
		"post_slot05_scan_results": scan_results.duplicate(true),
		"post_slot05_scan": scan.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"next_task_body_executed": false,
		"nmi_cadence_generated": false,
		"ppu_bus_events_applied": false,
	}


func _mapper_snapshot_for_task_boundary(boundary: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != 0x800:
		return {}
	var ram: PackedByteArray = ram_variant
	return {
		"bank_low": int(boundary.get("bank_low", -1)),
		"bank_high": int(boundary.get("bank_high", -1)),
		"select": (int(ram[0x0022]) | 0x07) & 0x07,
	}


## Resume only the slot-$09 yielded context selected by the live scheduler scan
## after resume_selected_slot05_worker(). The task body and its callback/worker
## results remain source-checked; the next task body or NMI cadence is not run.
func resume_selected_slot09_worker() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_09 \
			or _last_source_boundary not in ["$CAA5 selected slot $09 before task-body source",
				"$CAA5 scenario `$36` slot `$05` save selected slot `$09` before task body"]:
		return _fail_result("Slot-$09 resume requires the live pre-dispatch boundary selected by a supported source scheduler scan.")
	if _pending_selected_task_mapper.is_empty():
		return _fail_result("Selected slot-$09 continuation lacks its own saved mapper/RAM state.")
	var pending_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected slot-$09 boundary.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "pc", "sp",
			"a", "x", "y", "p", "p_known_mask", "bank_low", "bank_high", "ram_007F",
			"active_task_slot", "scheduler_y_register", "scheduler_scan_cursor"]:
		if int(live_boundary.get(key, -1)) != int(pending_boundary.get(key, -2)):
			return _fail_result("The selected slot-$09 boundary changed at %s after the slot-$05 scan; refusing stale dispatch." % key)
	if live_boundary.get("record", PackedByteArray()) != pending_boundary.get("record", PackedByteArray()) \
			or live_boundary.get("ram_image", PackedByteArray()) != pending_boundary.get("ram_image", PackedByteArray()) \
			or live_boundary.get("stack_page", PackedByteArray()) != pending_boundary.get("stack_page", PackedByteArray()):
		return _fail_result("Selected slot-$09 RAM, record, or stack changed after the slot-$05 scan; refusing stale dispatch.")
	if int(live_boundary.get("slot_base", -1)) != SLOT_09 \
			or int(live_boundary.get("phase", -1)) != 3 \
			or int(live_boundary.get("ready_delay", -1)) != 0 \
			or int(live_boundary.get("pending_resume", -1)) != 2 \
			or int(live_boundary.get("pc", -1)) != 0xCB0F \
			or int(live_boundary.get("active_task_slot", -1)) != -1 \
			or int(live_boundary.get("bank_low", -1)) != 0x18 \
			or int(live_boundary.get("bank_high", -1)) != 0x19 \
			or live_boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0x76, 0x18, 0x19]):
		return _fail_result("The selected task is not the supported zero-delay slot-$09 `$CB0F` continuation in banks `$18/$19`.")
	var ram_before_dispatch: Variant = live_boundary.get("ram_image", PackedByteArray())
	var stack_before_dispatch: Variant = live_boundary.get("stack_page", PackedByteArray())
	if not ram_before_dispatch is PackedByteArray or ram_before_dispatch.size() != 0x800 \
			or not stack_before_dispatch is PackedByteArray or stack_before_dispatch.size() != 0x100:
		return _fail_result("Selected slot-$09 boundary must include its complete source RAM and stack pages.")
	var source_mapper := _pending_selected_task_mapper.duplicate(true)
	if int(source_mapper.get("bank_low", -1)) != 0x18 \
			or int(source_mapper.get("bank_high", -1)) != 0x19 \
			or int(source_mapper.get("select", -1)) != 0x07:
		return _fail_result("Selected slot-$09 mapper snapshot does not match its `$18/$19` bank pair and `$07` select.")

	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_09)
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("slot_base", -1)) != SLOT_09 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xEB8B:
		return _fail_result("The source scheduler did not restore the selected slot-$09 `$EB8B` continuation.")
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
	var dispatch_ram: PackedByteArray = dispatch_boundary.get("ram_image", PackedByteArray())
	if dispatch_ram.size() != 0x800:
		return _fail_result("Dispatched slot-$09 context has no complete source RAM/mapper-select state.")
	var dispatch_mapper := source_mapper.duplicate(true)
	dispatch_mapper["bank_low"] = int(dispatch.get("bank_low", -1))
	dispatch_mapper["bank_high"] = int(dispatch.get("bank_high", -1))
	# The yielded-resume path's last checked `$CE2D` select uses `$22 | $07`.
	dispatch_mapper["select"] = (int(dispatch_ram[0x0022]) | 0x07) & 0x07
	var next_task_dispatch := dispatch.duplicate(true)
	next_task_dispatch["rom_sha256"] = ROM_SHA256
	next_task_dispatch["mapper"] = dispatch_mapper
	next_task_dispatch["p"] = int(dispatch_boundary.get("p", 0))
	next_task_dispatch["p_known_mask"] = int(dispatch_boundary.get("p_known_mask", 0))
	next_task_dispatch["ram_image"] = dispatch_ram
	next_task_dispatch["stack_page"] = dispatch_boundary.get("stack_page", PackedByteArray())
	next_task_dispatch["task_record"] = dispatch_boundary.get("record", PackedByteArray())
	var slot09_resume_result: Dictionary = _slot09_continuation_prefix.execute_from_next_task_dispatch(next_task_dispatch)
	var scenario36_event_boundary_result: Dictionary = {}
	var preseeded_slot15_result: Dictionary = {}
	var slot09_actor_seed_prefix_result: Dictionary = {}
	var slot11_seed_result: Dictionary = {}
	if bool(slot09_resume_result.get("ok", false)) \
			and String(slot09_resume_result.get("status", "")) == "scenario36_event_seeded_at_ec74_return":
		if not _scheduler.adopt_slot09_scenario_active_prefix_state(slot09_resume_result):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$36 `$EC74 RTS->$EB9E` return: " + _scheduler.error_message)
		var seed_contract: Dictionary = slot09_resume_result.get("scenario_seed_request", {})
		var scenario36_slot15_seed: Dictionary = _scheduler.seed_scenario_callback_task(
			int(seed_contract.get("setup_cpu_address", -1)))
		if not bool(scenario36_slot15_seed.get("ok", false)) \
				or int(scenario36_slot15_seed.get("slot_base", -1)) != SLOT_15 \
				or int(scenario36_slot15_seed.get("callback_reader_pc", -1)) != 0x814C:
			return _fail_result("Scheduler rejected the ROM-derived scenario-$36 slot-$15 callback seed: " \
				+ _scheduler.error_message + " " + str(scenario36_slot15_seed))
		preseeded_slot15_result = scenario36_slot15_seed.duplicate(true)
		_scenario36_slot15_seed_result = {
			"ok": true,
			"slot_base": int(scenario36_slot15_seed.get("slot_base", -1)),
			"record": scenario36_slot15_seed.get("record", PackedByteArray()).duplicate(),
			"callback_reader_pc": int(scenario36_slot15_seed.get("callback_reader_pc", -1)),
		}
		scenario36_event_boundary_result = slot09_resume_result.duplicate(true)
		_scenario36_event_boundary_result = scenario36_event_boundary_result.duplicate(true)
		var scenario36_return_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
		var scenario36_post_event_result: Dictionary = _slot09_continuation_prefix.resume_scenario36_after_event(
			scenario36_return_boundary, scenario36_event_boundary_result)
		if not bool(scenario36_post_event_result.get("ok", false)) \
				or int(scenario36_post_event_result.get("exit_pc", -1)) != 0x86F8:
			return _fail_result("Scenario `$36` caller did not resume from `$EB9E` to its `$86F8` worker vector: " \
				+ String(scenario36_post_event_result.get("error", _slot09_continuation_prefix.error_message)))
		_scenario36_post_event_result = scenario36_post_event_result.duplicate(true)
		slot09_resume_result = scenario36_post_event_result
	if bool(slot09_resume_result.get("scenario36_post_callback_executed", false)):
		if not _scheduler.adopt_slot09_scenario36_post_callback_prefix_state(slot09_resume_result):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$36 post-callback prefix writes: " + _scheduler.error_message)
	if bool(slot09_resume_result.get("ok", false)) \
			and bool(slot09_resume_result.get("scenario_route_state_executed", false)) \
			and not bool(slot09_resume_result.get("scenario36_post_callback_executed", false)) \
			and not bool(slot09_resume_result.get("scenario_active", false)):
		if not _scheduler.adopt_slot09_scenario_wait_worker_state(slot09_resume_result):
			var failed_ram: PackedByteArray = slot09_resume_result.get("ram_image", PackedByteArray())
			return _fail_result("Scheduler rejected the ROM-derived slot-$09 scenario continuation: " \
					+ _scheduler.error_message + " result=" + JSON.stringify({
						"status": slot09_resume_result.get("status", ""),
						"route_executed": slot09_resume_result.get("scenario_route_state_executed", false),
						"wait_executed": slot09_resume_result.get("scenario_wait_worker_executed", false),
						"active": slot09_resume_result.get("scenario_active", true),
						"entry_flags": failed_ram.slice(0x0516, 0x051A).hex_encode() if failed_ram.size() == 0x800 else "invalid",
						"terminal": failed_ram.slice(0x0522, 0x052B).hex_encode() if failed_ram.size() == 0x800 else "invalid",
						"cursor": failed_ram[0x003A] if failed_ram.size() == 0x800 else -1,
						"pointer": failed_ram.slice(0x005D, 0x005F).hex_encode() if failed_ram.size() == 0x800 else "invalid",
					}))
	if bool(slot09_resume_result.get("ok", false)) \
			and String(slot09_resume_result.get("status", "")) == "slot09_actor_worker_seed_ready_before_cae7":
		slot09_actor_seed_prefix_result = slot09_resume_result.duplicate(true)
		if not _scheduler.adopt_slot09_actor_seed_caller_prefix(slot09_resume_result):
			return _fail_result("Scheduler rejected the source slot-$09 `$EB8B->$ED15` actor-seed caller: " + _scheduler.error_message)
		var actor_seed_request: Dictionary = slot09_resume_result.get("actor_worker_seed_request", {})
		slot11_seed_result = _scheduler.seed_slot11_actor_worker_from_source_request(actor_seed_request)
		if not bool(slot11_seed_result.get("ok", false)) \
				or String(slot11_seed_result.get("status", "")) != "slot11_seeded_caller_returned_ed2d":
			return _fail_result("Scheduler rejected the ROM-derived `$ED15->$CAE7->$ED2D` slot-$11 seed: " + _scheduler.error_message)
		var slot09_seed_return_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
		var slot09_after_seed_result: Dictionary = _slot09_continuation_prefix.resume_after_actor_worker_seed(slot09_seed_return_boundary)
		if not bool(slot09_after_seed_result.get("ok", false)) \
				or int(slot09_after_seed_result.get("exit_pc", -1)) != 0x86F8:
			return _fail_result("Slot-$09 post-seed caller stopped before its `$86F8` source vector: " \
					+ String(slot09_after_seed_result.get("error", _slot09_continuation_prefix.error_message)))
		if not _scheduler.adopt_slot09_after_actor_seed_continuation(slot09_after_seed_result):
			return _fail_result("Scheduler rejected the source `$ED2D->$86F8` slot-$09 continuation: " + _scheduler.error_message)
		slot09_resume_result = slot09_after_seed_result
	if not bool(slot09_resume_result.get("ok", false)) \
			or int(slot09_resume_result.get("exit_pc", -1)) != 0x86F8:
		return _fail_result("Slot-$09 prefix stopped before its supported `$86F8` vector boundary: " \
				+ str(slot09_resume_result.get("reason", _slot09_continuation_prefix.error_message)))
	var slot15_seed_result: Dictionary = {}
	if bool(slot09_resume_result.get("scenario_active", false)):
		if not _scheduler.adopt_slot09_scenario_active_prefix_state(slot09_resume_result):
			return _fail_result("Scheduler rejected the source-ordered slot-$09 scenario-active writes: " + _scheduler.error_message)
		var seed_contract: Dictionary = slot09_resume_result.get("scenario_seed_request", {})
		if not preseeded_slot15_result.is_empty():
			slot15_seed_result = preseeded_slot15_result.duplicate(true)
		else:
			slot15_seed_result = _scheduler.seed_scenario_callback_task(
				int(seed_contract.get("setup_cpu_address", -1)))
			if not bool(slot15_seed_result.get("ok", false)) \
					or int(slot15_seed_result.get("slot_base", -1)) != SLOT_15 \
					or int(slot15_seed_result.get("callback_reader_pc", -1)) != 0x814C:
				return _fail_result("Scheduler rejected the ROM-derived scenario callback task seed: " \
					+ _scheduler.error_message + " " + str(slot15_seed_result))
	var slot09_86f8_result: Dictionary = _slot09_86f8_zero_branch_executor.execute_from_slot09_resume_result(slot09_resume_result)
	if not bool(slot09_86f8_result.get("ok", false)) or int(slot09_86f8_result.get("exit_pc", -1)) != 0xEBB3:
		return _fail_result("Slot-$09 `$86F8` executor rejected its live branch: " \
				+ str(slot09_86f8_result.get("reason", _slot09_86f8_zero_branch_executor.error_message)))
	var slot09_8779_result: Dictionary = _slot09_8779_zero_branch_executor.execute_from_86f8_worker_result(slot09_86f8_result)
	if not bool(slot09_8779_result.get("ok", false)) or int(slot09_8779_result.get("exit_pc", -1)) != 0xEBC5:
		return _fail_result("Slot-$09 `$8779` executor rejected its live branch: " \
				+ str(slot09_8779_result.get("reason", _slot09_8779_zero_branch_executor.error_message)))
	var slot09_87e6_result: Dictionary = _slot09_87e6_zero_branch_executor.execute_from_8779_worker_result(slot09_8779_result)
	if not bool(slot09_87e6_result.get("ok", false)) or int(slot09_87e6_result.get("exit_pc", -1)) != 0xEBD7:
		return _fail_result("Slot-$09 `$87E6` executor rejected its live branch: " \
				+ str(slot09_87e6_result.get("reason", _slot09_87e6_zero_branch_executor.error_message)))
	var slot09_root_zero_result: Dictionary = _slot09_ebd7_root_zero_counter_executor.execute_from_87e6_result(slot09_87e6_result)
	if not bool(slot09_root_zero_result.get("ok", false)) or int(slot09_root_zero_result.get("exit_pc", -1)) != 0xCB0F:
		return _fail_result("Slot-$09 root loop rejected its live `$EB88->$CB0F` branch: " \
				+ str(slot09_root_zero_result.get("reason", _slot09_ebd7_root_zero_counter_executor.error_message)))
	if bool(slot09_resume_result.get("scenario36_post_callback_executed", false)):
		var scenario36_worker_chain: Array = [slot09_86f8_result,
			slot09_8779_result, slot09_87e6_result]
		if not _scheduler.adopt_slot09_scenario36_worker_chain_state(scenario36_worker_chain):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$36 worker writes: " + _scheduler.error_message)
	if not slot11_seed_result.is_empty():
		var actor_worker_chain: Array = [slot09_86f8_result, slot09_8779_result, slot09_87e6_result]
		if not _scheduler.adopt_slot09_actor_seeded_root_loop_entry_state(actor_worker_chain, slot09_root_zero_result):
			return _fail_result("Scheduler rejected the ROM-derived actor-seeded slot-$09 root-loop boundary: " + _scheduler.error_message)
	elif bool(slot09_resume_result.get("scenario_active", false)) \
			or bool(slot09_resume_result.get("scenario_route_state_executed", false)) \
			or bool(slot09_resume_result.get("scenario36_post_callback_executed", false)):
		if not _scheduler.adopt_slot09_root_loop_entry_state(slot09_root_zero_result):
			return _fail_result("Scheduler rejected the ROM-derived slot-$09 root-loop CPU boundary: " + _scheduler.error_message)
	var slot09_cb0f_save_result: Dictionary = _scheduler.apply_slot09_cb0f_from_root_route_result(slot09_root_zero_result)
	if not bool(slot09_cb0f_save_result.get("ok", false)) \
			or String(slot09_cb0f_save_result.get("status", "")) != "slot09_saved_at_cb0f":
		return _fail_result("Scheduler rejected the ROM-owned slot-$09 `$CB0F` save: " + _scheduler.error_message)
	var saved_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after slot-$09 save failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var awaiting_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot < 0 or next_boundary.is_empty() \
				or int(next_boundary.get("active_task_slot", -1)) != -1 \
				or int(next_boundary.get("phase", -1)) != 3 \
				or int(next_boundary.get("pending_resume", -1)) != 2 \
				or int(next_boundary.get("pc", -1)) != 0xCB0F:
			return _fail_result("Post-save scheduler selected no supported yielded-task pre-dispatch boundary.")
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state.clear()
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X after slot-$09 save; before task body" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_boundary.is_empty() or int(next_boundary.get("active_task_slot", -1)) != -1 \
				or int(next_boundary.get("phase", -1)) != 1 \
				or int(next_boundary.get("pending_resume", -1)) != 1 \
				or int(next_boundary.get("ready_delay", -1)) != 0xFF:
			return _fail_result("Post-save scheduler selected no seeded initial-task boundary.")
		if next_slot == SLOT_15:
			var slot15_stack: PackedByteArray = next_boundary.get("stack_page", PackedByteArray())
			if int(next_boundary.get("sp", -1)) != 0xF0 \
					or int(next_boundary.get("bank_low", -1)) != 0x0B \
					or next_boundary.get("record", PackedByteArray()) != PackedByteArray([0xFF, 0xF0, 0x0B, 0x00]) \
					or slot15_stack.size() != 0x100 \
					or int(slot15_stack[0xF1]) != 0x08 or int(slot15_stack[0xF2]) != 0x80:
				return _fail_result("Post-save scheduler selected an unsupported initial slot-$15 callback boundary.")
		elif next_slot == SLOT_11:
			if int(next_boundary.get("sp", -1)) != 0xC8 \
					or int(next_boundary.get("bank_low", -1)) != 0x18 \
					or int(next_boundary.get("bank_high", -1)) != 0x19 \
					or next_boundary.get("record", PackedByteArray()) != PackedByteArray([0xFF, 0xC8, 0x18, 0x00]):
				return _fail_result("Post-save scheduler selected an unsupported initial slot-$11 actor-worker boundary.")
		else:
			return _fail_result("Post-save scheduler selected unsupported seeded task slot `$%02X`." % next_slot)
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state.clear()
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected initial slot $%02X after slot-$09 save; before task dispatch" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		var queue_state: Dictionary = _scheduler.get_live_nmi_secondary_queue_state()
		if queue_state.is_empty():
			return _fail_result("The post-save NMI wait has no source-owned queue signature.")
		_pending_nmi_queue_state = queue_state.duplicate(true)
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CB0F save -> scheduler WAIT_FOR_NMI_READY"
		awaiting_nmi = true
	else:
		return _fail_result("Post-save scheduler ended at an unsupported decision: %s" % str(scan))

	return {
		"ok": true,
		"status": "slot09_saved_and_rescanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"slot05_selected_pre_dispatch_boundary": pending_boundary.duplicate(true),
		"slot09_dispatch": dispatch.duplicate(true),
		"slot09_dispatch_boundary": dispatch_boundary.duplicate(true),
		"slot09_resume_result": slot09_resume_result.duplicate(true),
		"scenario36_event_boundary_result": scenario36_event_boundary_result.duplicate(true),
		"slot09_actor_seed_prefix_result": slot09_actor_seed_prefix_result.duplicate(true),
		"slot11_seed_result": slot11_seed_result.duplicate(true),
		"slot15_scenario_seed_result": slot15_seed_result.duplicate(true),
		"slot09_86f8_worker_result": slot09_86f8_result.duplicate(true),
		"slot09_8779_worker_result": slot09_8779_result.duplicate(true),
		"slot09_87e6_worker_result": slot09_87e6_result.duplicate(true),
		"slot09_ebd7_root_zero_result": slot09_root_zero_result.duplicate(true),
		"slot09_cb0f_save_result": slot09_cb0f_save_result.duplicate(true),
		"slot09_cb0f_saved_boundary": saved_boundary.duplicate(true),
		"post_slot09_scan_results": scan_results.duplicate(true),
		"post_slot09_scan": scan.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"next_task_body_executed": false,
		"awaiting_external_nmi": awaiting_nmi,
		"nmi_cadence_generated": false,
		"ppu_bus_events_applied": false,
	}


## Runs only the first ROM-derived slot-$11 actor setup, from its live scheduler
## dispatch at `$8000` to the `$8047->$CB0F` save. Later actor-worker resumes
## remain separate source transitions.
func resume_selected_slot11_worker() -> Dictionary:
	error_message = ""
	var is_selected_slot11_boundary := _last_source_boundary.contains("selected slot $11") \
			or _last_source_boundary.contains("selected initial slot $11")
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_11 \
			or not is_selected_slot11_boundary:
		return _fail_result("Slot-$11 actor worker requires the live scheduler-selected initial-task boundary.")
	if int(_pending_selected_task_boundary.get("phase", -1)) == 3:
		return _resume_selected_slot11_actor_worker_continuation()
	var pending_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected slot-$11 task boundary.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "bank_low", "bank_high", "active_task_slot"]:
		if int(live_boundary.get(key, -1)) != int(pending_boundary.get(key, -2)):
			return _fail_result("The selected slot-$11 boundary changed at %s; refusing stale actor dispatch." % key)
	for key: String in ["record", "ram_image", "stack_page"]:
		if live_boundary.get(key, PackedByteArray()) != pending_boundary.get(key, PackedByteArray()):
			return _fail_result("Selected slot-$11 %s changed after the scheduler scan; refusing stale actor dispatch." % key)
	var record: PackedByteArray = live_boundary.get("record", PackedByteArray())
	if record != PackedByteArray([0xFF, 0xC8, 0x18, 0x00]) \
			or int(live_boundary.get("phase", -1)) != 1 \
			or int(live_boundary.get("ready_delay", -1)) != 0xFF \
			or int(live_boundary.get("pending_resume", -1)) != 1 \
			or int(live_boundary.get("active_task_slot", -1)) != -1 \
			or int(live_boundary.get("bank_low", -1)) != 0x18 \
			or int(live_boundary.get("bank_high", -1)) != 0x19:
		return _fail_result("Selected slot-$11 is not the ROM-seeded initial actor worker in banks `$18/$19`.")
	var mapper := _mapper_snapshot_for_task_boundary(live_boundary)
	if int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19:
		return _fail_result("Selected slot-$11 actor worker does not retain its source mapper pair.")
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_11)
	if not bool(dispatch.get("ok", false)) \
			or String(dispatch.get("resume_path", "")) != "initial_rts" \
			or int(dispatch.get("slot_base", -1)) != SLOT_11 \
			or int(dispatch.get("pc", -1)) != 0x8000 \
			or int(dispatch.get("sp", -1)) != 0xCA \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19:
		return _fail_result("The source scheduler did not restore the slot-$11 `$8000` actor-worker entry: %s" % str(dispatch))
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
	var worker: Dictionary = _slot11_actor_worker_executor.execute_from_dispatched_slot11(dispatch_boundary)
	if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
		return _fail_result("Slot-$11 ROM-byte actor setup stopped before `$8047`: " \
				+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_executor.error_message))))
	var save_result: Dictionary = _scheduler.save_slot11_actor_worker_first_yield(worker)
	if not bool(save_result.get("ok", false)) \
			or String(save_result.get("status", "")) != "slot11_actor_worker_yielded_at_cb0f":
		return _fail_result("Scheduler rejected the source slot-$11 `$8047->$CB0F` yield: " + _scheduler.error_message)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after the slot-$11 first yield failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var awaiting_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot < 0 or next_boundary.is_empty() \
				or int(next_boundary.get("active_task_slot", -1)) != -1 \
				or int(next_boundary.get("phase", -1)) != 3 \
				or int(next_boundary.get("pending_resume", -1)) != 2 \
				or int(next_boundary.get("pc", -1)) != 0xCB0F:
			return _fail_result("Post-yield scheduler selected no source-supported yielded task boundary.")
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X after slot-$11 first yield" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty():
			return _fail_result("Slot-$11 first yield reached an NMI wait without source-owned queue state.")
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$8047->$CB0F slot-$11 save -> scheduler WAIT_FOR_NMI_READY"
		awaiting_nmi = true
	else:
		return _fail_result("Slot-$11 first-yield scan stopped at an unsupported scheduler decision: %s" % str(scan))
	return {
		"ok": true,
		"status": "slot11_actor_worker_first_yield_saved_and_scanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"selected_task_boundary": live_boundary.duplicate(true),
		"selected_task_dispatch": dispatch.duplicate(true),
		"dispatched_worker_boundary": dispatch_boundary.duplicate(true),
		"slot11_worker_result": worker.duplicate(true),
		"slot11_cb0f_save_result": save_result.duplicate(true),
		"scheduler_scan_results": scan_results.duplicate(true),
		"post_yield_scan": scan.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"awaiting_external_nmi": awaiting_nmi,
		"nmi_cadence_generated": false,
		"trace_state_used": false,
		"ppu_bus_events_applied": false,
	}


## Resumes the live yielded slot-$11 actor stream from `$CB0F`, dispatches its
## saved RTS frame to `$804A`, and executes only the audited `$804A->$CC50`
## continuation before returning to the scheduler. It does not generate an
## NMI or infer a frame cadence.
func _resume_selected_slot11_actor_worker_continuation() -> Dictionary:
	var pending_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected yielded slot-$11 boundary.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "bank_low", "bank_high", "active_task_slot", "pc"]:
		if int(live_boundary.get(key, -1)) != int(pending_boundary.get(key, -2)):
			return _fail_result("The selected yielded slot-$11 boundary changed at %s; refusing stale resume." % key)
	for key: String in ["record", "ram_image", "stack_page"]:
		if live_boundary.get(key, PackedByteArray()) != pending_boundary.get(key, PackedByteArray()):
			return _fail_result("Selected yielded slot-$11 %s changed after the scheduler scan; refusing stale resume." % key)
	var first_stream_record := PackedByteArray([0x00, 0xC6, 0x18, 0x19])
	var waiter_record := PackedByteArray([0x00, 0xBF, 0x18, 0x19])
	var tail_waiter_record := PackedByteArray([0x00, 0xC0, 0x18, 0x19])
	var animation_record := PackedByteArray([0x00, 0xC2, 0x1A, 0x1B])
	var live_record: PackedByteArray = live_boundary.get("record", PackedByteArray())
	var is_animation_resume := live_record == animation_record
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var is_animation_countdown_resume: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) in [0, 1] \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) > 0 \
			and int(live_ram[0x0515]) == 0
	var is_waiter_resume: bool = live_record in [waiter_record, tail_waiter_record] \
			or is_animation_resume or is_animation_countdown_resume
	var expected_live_banks := PackedByteArray([0x1A, 0x1B]) if is_animation_resume \
		else PackedByteArray([0x18, 0x19])
	if int(live_boundary.get("phase", -1)) != 3 \
			or int(live_boundary.get("ready_delay", -1)) != 0 \
			or int(live_boundary.get("pending_resume", -1)) != 2 \
			or int(live_boundary.get("pc", -1)) != 0xCB0F \
			or int(live_boundary.get("active_task_slot", -1)) != -1 \
			or live_record not in [first_stream_record, waiter_record, tail_waiter_record, animation_record] \
			or int(live_boundary.get("bank_low", -1)) != int(expected_live_banks[0]) \
			or int(live_boundary.get("bank_high", -1)) != int(expected_live_banks[1]):
		var live_stack: PackedByteArray = live_boundary.get("stack_page", PackedByteArray())
		return _fail_result("Selected slot-$11 does not match the audited yielded `$CB0F` boundary for resume: phase=%d delay=%d resume=%d pc=$%04X sp=$%02X record=%s banks=$%02X/$%02X stack=%s." % [
			int(live_boundary.get("phase", -1)), int(live_boundary.get("ready_delay", -1)),
			int(live_boundary.get("pending_resume", -1)), int(live_boundary.get("pc", -1)),
			int(live_boundary.get("sp", -1)),
			(live_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
			int(live_boundary.get("bank_low", -1)), int(live_boundary.get("bank_high", -1)),
			live_stack.slice(0xBF, 0xC5).hex_encode() if live_stack.size() == 0x100 else "invalid",
		])
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_11)
	var expected_dispatch_pc := 0x804A if not is_waiter_resume else int(dispatch.get("pc", -1))
	var dispatch_pc_valid: bool = (not is_waiter_resume and expected_dispatch_pc == 0x804A) \
		or (is_waiter_resume and not is_animation_resume and expected_dispatch_pc in [0xCC53, 0xCCA3, 0xCCD1]) \
		or (is_animation_resume and expected_dispatch_pc == 0xA21A) \
		or (is_animation_countdown_resume and expected_dispatch_pc == 0x804A)
	var expected_dispatch_sp := 0xCA if expected_dispatch_pc == 0x804A \
		else 0xC3 if expected_dispatch_pc == 0xCC53 else 0xC6 if expected_dispatch_pc == 0xA21A else 0xC4
	if not bool(dispatch.get("ok", false)) \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("slot_base", -1)) != SLOT_11 \
			or not dispatch_pc_valid \
			or int(dispatch.get("sp", -1)) != expected_dispatch_sp \
			or int(dispatch.get("bank_low", -1)) != int(expected_live_banks[0]) \
			or int(dispatch.get("bank_high", -1)) != int(expected_live_banks[1]):
		return _fail_result("The source scheduler did not restore the audited slot-$11 actor continuation: %s" % str(dispatch))
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var resume_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
	var worker: Dictionary
	var save_result: Dictionary = {}
	var is_final_packet_resume := false
	if is_waiter_resume:
		if int(dispatch.get("pc", -1)) == 0xCC53:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_waiter_resume_boundary(resume_boundary)
		elif int(dispatch.get("pc", -1)) == 0xCCA3:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_waiter_tail_poll_boundary(resume_boundary)
		elif int(dispatch.get("pc", -1)) == 0xCCD1:
			is_final_packet_resume = true
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_final_packet_return_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x804D:
				return _fail_result("Slot-$11 final packet return stopped before the ROM F5 tail returned to `$804D`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			var tail_adoption: Dictionary = _scheduler.apply_slot11_actor_f5_tail_return_result(worker)
			if not bool(tail_adoption.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM F5 tail return: " + _scheduler.error_message)
			var animation_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_f5_animation_gate_boundary(animation_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0xCB0F:
				return _fail_result("Slot-$11 F5 actor-animation gate stopped before `$A217->$CB0F`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			var animation_adoption: Dictionary = _scheduler.apply_slot11_f5_animation_gate_result(worker)
			if not bool(animation_adoption.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM F5 actor-animation gate: " + _scheduler.error_message)
			save_result = animation_adoption
			_last_source_boundary = "$804D->$C560->$CF72->$CE2D->$A1EB->$A217->$CB0F; resumes at $A21A"
		elif int(dispatch.get("pc", -1)) == 0xA21A and is_animation_resume:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_after_a217_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Slot-$11 `$A21A` packet builder stopped before the `$8047` actor yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_queue_result(worker)
			if not bool(save_result.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM `$A21A` PPU packet queue: " + _scheduler.error_message)
		elif int(dispatch.get("pc", -1)) == 0x804A and is_animation_countdown_resume:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Slot-$11 animation countdown stopped before the `$8047` actor yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_countdown_result(worker)
			if not bool(save_result.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM animation countdown: " + _scheduler.error_message)
		else:
			return _fail_result("Slot-$11 waiter continuation dispatch resolved to an unsupported source PC `$%04X`." % int(dispatch.get("pc", -1)))
	else:
		worker = _slot11_actor_worker_resume_executor.execute_from_resumed_slot11_boundary(resume_boundary)
	if not bool(worker.get("ok", false)) \
			or (not is_animation_resume and not is_animation_countdown_resume \
				and int(worker.get("exit_pc", -1)) != 0xCB0F) \
			or ((is_animation_resume or is_animation_countdown_resume) \
				and int(worker.get("exit_pc", -1)) != 0x8047):
		return _fail_result("Slot-$11 ROM-byte actor continuation stopped before its `$CB0F` yield: " \
				+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
	if not is_final_packet_resume and not is_animation_resume and not is_animation_countdown_resume:
		if is_waiter_resume:
			save_result = _scheduler.apply_slot11_actor_waiter_resume_result(worker)
		else:
			save_result = _scheduler.apply_slot11_actor_worker_resume_result(worker)
		if not bool(save_result.get("ok", false)) \
				or String(save_result.get("status", "")) != ("slot11_actor_waiter_resume_saved_at_cb0f" if is_waiter_resume else "slot11_actor_resume_saved_at_cb0f"):
			return _fail_result("Scheduler rejected the source slot-$11 `$CC50->$CB0F` continuation: " + _scheduler.error_message)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after the slot-$11 resume yield failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var awaiting_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		if next_slot < 0 or next_boundary.is_empty() \
				or int(next_boundary.get("active_task_slot", -1)) != -1 \
				or int(next_boundary.get("phase", -1)) != 3 \
				or int(next_boundary.get("pending_resume", -1)) != 2 \
				or int(next_boundary.get("pc", -1)) != 0xCB0F:
			return _fail_result("Post-resume scheduler selected no source-supported yielded-task boundary.")
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		_phase = "waiting_for_selected_task_source"
		var waiter_continuation_name := "A21A animation packet builder" if is_animation_resume \
			else "804A animation countdown" if is_animation_countdown_resume \
			else "CC53 waiter resume" if int(dispatch.get("pc", -1)) == 0xCC53 \
			else "CCA3 counter-tail poll" if int(dispatch.get("pc", -1)) == 0xCCA3 \
			else "CCD1 F5 animation gate" if int(dispatch.get("pc", -1)) == 0xCCD1 else "actor-stream resume"
		_last_source_boundary = "$CAA5 selected slot $%02X after slot-$11 %s" % [
			next_slot, waiter_continuation_name if is_waiter_resume else "actor-stream resume"]
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty():
			return _fail_result("Slot-$11 resume yield reached an NMI wait without source-owned queue state.")
		_phase = "awaiting_external_nmi"
		var yield_callsite_pc := int(worker.get("yield_callsite_pc", worker.get("callsite_pc", -1)))
		if yield_callsite_pc == 0x8047:
			_last_source_boundary = "$8047->$C515->$CB0F slot-$11 actor yield -> scheduler WAIT_FOR_NMI_READY"
		elif yield_callsite_pc == 0xA217:
			_last_source_boundary = "$A217->$CB0F slot-$11 animation yield -> scheduler WAIT_FOR_NMI_READY"
		elif yield_callsite_pc == 0xCCA0:
			_last_source_boundary = "$CCA0->$CB0F slot-$11 waiter yield -> scheduler WAIT_FOR_NMI_READY"
		elif yield_callsite_pc == 0xCCCE:
			_last_source_boundary = "$CCCE->$CB0F slot-$11 final-packet yield -> scheduler WAIT_FOR_NMI_READY"
		elif yield_callsite_pc == 0xCC50:
			_last_source_boundary = "$CC50->$CB0F slot-$11 actor-stream wait -> scheduler WAIT_FOR_NMI_READY"
		else:
			return _fail_result("Slot-$11 reached an NMI wait from an unclassified ROM yield callsite `$%04X`." % yield_callsite_pc)
		awaiting_nmi = true
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		var selected_record: PackedByteArray = next_boundary.get("record", PackedByteArray())
		if next_slot != SLOT_15 or next_boundary.is_empty() \
				or int(next_boundary.get("active_task_slot", -1)) != -1 \
				or int(next_boundary.get("phase", -1)) != 1 \
				or int(next_boundary.get("ready_delay", -1)) != 0xFF \
				or int(next_boundary.get("pending_resume", -1)) != 1 \
				or selected_record.size() != 4 or selected_record.slice(0, 3) != PackedByteArray([0xFF, 0xF0, 0x0B]):
			return _fail_result("Slot-$11 resume selected an unsupported seeded task boundary: %s" % str(next_boundary))
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected initial slot $15 after slot-$11 actor resume; before task dispatch"
	else:
		return _fail_result("Slot-$11 actor-resume scan stopped at an unsupported scheduler decision: %s" % str(scan))
	return {
		"ok": true,
		"status": "slot11_f5_animation_countdown_saved_and_scanned" if is_animation_countdown_resume \
			else "slot11_f5_animation_queue_saved_and_scanned" if is_animation_resume \
			else "slot11_f5_animation_gate_saved_and_scanned" if is_final_packet_resume \
			else "slot11_actor_resume_yield_saved_and_scanned" if not is_waiter_resume \
			else "slot11_actor_waiter_resume_yield_saved_and_scanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"selected_task_boundary": live_boundary.duplicate(true),
		"selected_task_dispatch": dispatch.duplicate(true),
		"dispatched_worker_boundary": resume_boundary.duplicate(true),
		"slot11_resume_result": worker.duplicate(true),
		"slot11_cb0f_save_result": save_result.duplicate(true),
		"scheduler_scan_results": scan_results.duplicate(true),
		"post_resume_scan": scan.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"awaiting_external_nmi": awaiting_nmi,
		"nmi_cadence_generated": false,
		"trace_state_used": false,
		"ppu_bus_events_applied": false,
	}


## Dispatches slot `$15` only after classifying its source-saved context. The
## live task record distinguishes the initial callback entry, an ordinary
## map-row continuation, and the exhausted-row terminal return.
func resume_selected_slot15_source_task() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_15:
		return _fail_result("Slot-$15 source dispatch requires its live scheduler-selected task boundary.")
	if _last_source_boundary.contains("initial slot $15"):
		return resume_selected_slot15_callback_entry()
	var boundary := _pending_selected_task_boundary
	var record: PackedByteArray = boundary.get("record", PackedByteArray())
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	if record.size() != 4 or ram.size() != 0x800 \
			or int(boundary.get("pc", -1)) != 0xCB0F:
		return _fail_result("Selected slot-$15 task is not at a supported source-saved `$CB0F` boundary.")
	if record == PackedByteArray([0x00, 0xEA, 0x0B, 0x12]) \
			and int(ram[0x05CC]) == 0x42 and int(ram[0x05C9]) == 0x00:
		return resume_selected_slot15_terminal_callback()
	var initial_map_cursor := record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C]) \
			and int(ram[0x05C9]) == 0x20 \
			and ((int(ram[0x05C7]) == 0x00 and int(ram[0x05C8]) == 0x00) \
				or (int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0))
	if initial_map_cursor:
		return resume_selected_slot15_map_worker()
	var continuation_map_index := 0x20 - int(ram[0x05C9])
	var continuation_placement := int(ram[0x05C8])
	var continuation_cursor_matches := continuation_placement == continuation_map_index \
			or continuation_placement == 0xA0 + continuation_map_index
	if record == PackedByteArray([0x00, 0xE9, 0x0B, 0x12]) \
			and continuation_map_index in [3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			and continuation_cursor_matches:
		return resume_selected_slot15_map_worker()
	return _fail_result("Selected slot-$15 task record/RAM does not identify an implemented map-$42 source boundary: record=%s PC=$%04X SP=$%02X banks=$%02X/$%02X cursor=$%02X placement=$%02X remaining=$%02X callback=$%02X map=$%02X ready=$%02X." % [
		record.hex_encode(), int(boundary.get("pc", -1)), int(boundary.get("sp", -1)),
		int(boundary.get("bank_low", -1)), int(boundary.get("bank_high", -1)),
		int(ram[0x05C7]), int(ram[0x05C8]), int(ram[0x05C9]), int(ram[0x05CD]),
		int(ram[0x05CC]), int(ram[0x0515])])


## Dispatches the source-selected initial callback task, runs its checked entry
## and `$8327` prefix, then stops at map worker `$8525`.
func resume_selected_slot15_callback_entry() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_15 \
			or not _last_source_boundary.contains("initial slot $15"):
		return _fail_result("Slot-$15 dispatch requires the live initial-task boundary produced by the slot-$09 scenario route.")
	var expected_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected initial slot-$15 task.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "pc", "sp",
			"a", "x", "y", "bank_low", "bank_high", "active_task_slot", "scheduler_y_register"]:
		if int(live_boundary.get(key, -1)) != int(expected_boundary.get(key, -2)):
			return _fail_result("Selected slot-$15 boundary changed at %s; refusing stale initial dispatch." % key)
	if live_boundary.get("record", PackedByteArray()) != expected_boundary.get("record", PackedByteArray()) \
			or live_boundary.get("ram_image", PackedByteArray()) != expected_boundary.get("ram_image", PackedByteArray()) \
			or live_boundary.get("stack_page", PackedByteArray()) != expected_boundary.get("stack_page", PackedByteArray()):
		return _fail_result("Selected slot-$15 RAM, task record, or stack changed before initial dispatch.")
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_15)
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0x8009:
		return _fail_result("The selected slot-$15 initial RTS did not restore `$8009`: " + str(dispatch))
	var dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
	var entry_result: Dictionary = _slot15_callback_entry_executor.execute_from_initial_slot15_dispatch(
		dispatch, live_boundary, dispatch_boundary)
	if not bool(entry_result.get("ok", false)):
		return _fail_result("The slot-$15 `$8009` source entry refused dispatch: " + str(entry_result.get("error", "unknown source failure")))
	if not _scheduler.adopt_initial_task_jmp_result(SLOT_15, entry_result):
		return _fail_result("Scheduler rejected the source `$8009->$814C` callback entry: " + _scheduler.error_message)
	var handler_result: Dictionary = _slot15_callback_dispatcher_executor.execute_fresh_callback_3a(entry_result)
	if not bool(handler_result.get("ok", false)):
		return _fail_result("ROM callback `$3A` stopped before its first handler: " + str(handler_result.get("error", "unknown source error")))
	if not _scheduler.adopt_slot15_callback_handler_boundary(handler_result):
		return _fail_result("Scheduler rejected the ROM-byte callback `$3A->$8327` boundary: " + _scheduler.error_message)
	var map_worker_result: Dictionary = _slot15_map_handler_prefix_executor.execute_from_handler_boundary(handler_result)
	if not bool(map_worker_result.get("ok", false)):
		return _fail_result("ROM callback `$3A` map handler stopped before `$8525`: " + str(map_worker_result.get("error", "unknown source error")))
	if not _scheduler.adopt_slot15_map_worker_entry(map_worker_result):
		return _fail_result("Scheduler rejected the ROM `$8327->$8525` map-worker entry: " + _scheduler.error_message)
	var map_setup_result: Dictionary = _slot15_map_worker_prefix_executor.execute_map_42_to_first_yield_callsite(map_worker_result)
	if not bool(map_setup_result.get("ok", false)):
		return _fail_result("ROM map-$42 worker stopped before its first `$C515` yield: " + str(map_setup_result.get("error", "unknown source error")))
	if not _scheduler.adopt_slot15_map_worker_yield_callsite(map_setup_result):
		return _fail_result("Scheduler rejected the ROM map-$42 setup at `$856F`: " + _scheduler.error_message)
	var yield_registers: Dictionary = map_setup_result.get("registers", {})
	if not _scheduler.yield_at_verified_callsite(SLOT_15, 0x856F,
			int(yield_registers.get("a", -1)), int(yield_registers.get("sp", -1)),
			int(yield_registers.get("x", -1)), int(yield_registers.get("y", -1)),
			int(map_worker_result.get("mapper", {}).get("bank_low", -1)),
			int(map_worker_result.get("mapper", {}).get("bank_high", -1))):
		return _fail_result("Scheduler rejected the first map-$42 `$856F->$C515` yield: " + _scheduler.error_message)
	var post_yield_scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(post_yield_scan.get("ok", false)) \
			or int(post_yield_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		return _fail_result("The first map-worker yield did not return the scheduler to its NMI wait: " + str(post_yield_scan))
	_pending_selected_task_boundary.clear()
	_pending_selected_task_slot = -1
	_phase = "awaiting_external_nmi"
	_last_source_boundary = "slot-$15 map-$42 worker reached `$856F->$C515`, saved through `$CB0F`, and returned to the scheduler NMI wait"
	return {
		"ok": true,
		"status": "slot15_map_worker_yielded_waiting_nmi",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"selected_slot_boundary": live_boundary.duplicate(true),
		"selected_slot_dispatch_boundary": dispatch_boundary.duplicate(true),
		"selected_slot_dispatch": dispatch.duplicate(true),
		"callback_entry_result": entry_result.duplicate(true),
		"callback_handler_result": handler_result.duplicate(true),
		"callback_map_worker_entry_result": map_worker_result.duplicate(true),
		"map_worker_setup_result": map_setup_result.duplicate(true),
		"map_worker_yield_scan": post_yield_scan.duplicate(true),
		"callback_dispatcher_body_executed": true,
		"callback_handler_prefix_executed": true,
		"map_worker_setup_executed": true,
		"map_worker_rows_executed": false,
		"next_selected_task_slot": -1,
		"next_selected_task_boundary": {},
		"slot15_yielded_boundary": _scheduler.get_task_boundary_snapshot(SLOT_15),
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}


## Resumes the selected map-$42 worker from its saved `$8572` continuation and
## generates the first three ROM-derived metatile packet groups.
func resume_selected_slot15_map_worker() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_15 \
			or not _last_source_boundary.contains("selected slot $15"):
		return _fail_result("Slot-$15 map-worker resume requires its live scheduler-selected boundary.")
	var expected_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected slot-$15 continuation.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "pc", "sp",
			"a", "x", "y", "p", "bank_low", "bank_high", "active_task_slot", "scheduler_y_register"]:
		if int(live_boundary.get(key, -1)) != int(expected_boundary.get(key, -2)):
			return _fail_result("Selected slot-$15 boundary changed at %s; refusing stale map-worker dispatch." % key)
	if live_boundary.get("record", PackedByteArray()) != expected_boundary.get("record", PackedByteArray()) \
			or live_boundary.get("ram_image", PackedByteArray()) != expected_boundary.get("ram_image", PackedByteArray()) \
			or live_boundary.get("stack_page", PackedByteArray()) != expected_boundary.get("stack_page", PackedByteArray()):
		return _fail_result("Selected slot-$15 RAM, task record, or stack changed before map-worker dispatch.")
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var live_record: PackedByteArray = live_boundary.get("record", PackedByteArray())
	var first_batch_boundary := live_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C]) \
			and live_ram.size() == 0x800 and int(live_ram[0x05C9]) == 0x20 \
			and ((int(live_ram[0x05C7]) == 0x00 and int(live_ram[0x05C8]) == 0x00) \
				or (int(live_ram[0x05C7]) == 0x40 and int(live_ram[0x05C8]) == 0xA0))
	var continuation_map_index := 0x20 - int(live_ram[0x05C9]) if live_ram.size() == 0x800 else -1
	var continuation_placement := int(live_ram[0x05C8]) if live_ram.size() == 0x800 else -1
	var continuation_cursor_matches := continuation_placement == continuation_map_index \
			or continuation_placement == 0xA0 + continuation_map_index
	var continuation_batch_boundary := live_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x12]) \
			and live_ram.size() == 0x800 \
			and continuation_map_index in [3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			and continuation_cursor_matches
	if int(live_boundary.get("pc", -1)) != 0xCB0F \
			or int(live_boundary.get("pending_resume", -1)) != 2 \
			or not (first_batch_boundary or continuation_batch_boundary):
		return _fail_result("Map-$42 continuation is not a source-saved slot-$15 `$C515` batch boundary.")
	var mapper := _mapper_snapshot_for_task_boundary(live_boundary)
	if int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != (0x0C if first_batch_boundary else 0x12):
		return _fail_result("Selected map-worker task does not retain its source CHR/PRG bank state.")
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_15)
	if not bool(dispatch.get("ok", false)) \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8572:
		return _fail_result("The scheduler did not restore slot-$15's `$8572` continuation: " + str(dispatch))
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
	var worker_dispatch := {
		"rom_sha256": ROM_SHA256,
		"slot_base": SLOT_15,
		"resume_path": String(dispatch.get("resume_path", "")),
		"registers": {
			"pc": int(dispatch.get("pc", -1)), "a": int(dispatch.get("a", -1)),
			"x": int(dispatch.get("x", -1)), "y": int(dispatch.get("y", -1)),
			"sp": int(dispatch.get("sp", -1)), "p": int(dispatch_boundary.get("p", -1)),
			"p_known_mask": int(dispatch_boundary.get("p_known_mask", -1)),
		},
		"task_record": dispatch_boundary.get("record", PackedByteArray()),
	}
	var worker_boundary := dispatch_boundary.duplicate(true)
	worker_boundary["mapper"] = mapper.duplicate(true)
	var batch: Dictionary = _slot15_map42_first_batch_executor.execute_resumed_worker(
		worker_dispatch, worker_boundary)
	if not bool(batch.get("ok", false)):
		return _fail_result("ROM map-$42 worker could not build its first batch: " + String(batch.get("error", "unknown source error")))
	if not _scheduler.adopt_slot15_map42_batch_result(batch):
		return _fail_result("Scheduler rejected the ROM-derived map-$42 batch: " + _scheduler.error_message)
	var registers: Dictionary = batch.get("registers", {})
	var mapper_after: Dictionary = batch.get("mapper", {})
	var map_yield_callsite := int(batch.get("callsite_pc", -1))
	if not _scheduler.yield_at_verified_callsite(SLOT_15, map_yield_callsite,
			int(registers.get("a", -1)), int(registers.get("sp", -1)),
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper_after.get("bank_low", -1)), int(mapper_after.get("bank_high", -1))):
		return _fail_result("Scheduler rejected the resumed map-$42 `$856F->$C515` yield: " + _scheduler.error_message)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after map-$42 batch yield failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var awaiting_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper.clear()
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X after map-$42 batch yield" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty() \
				or int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) != 0x80:
			return _fail_result("Map-$42 batch did not leave a ready secondary queue for normal NMI.")
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CB0F slot-$15 map-$42 batch save -> scheduler WAIT_FOR_NMI_READY"
		awaiting_nmi = true
	else:
		return _fail_result("Map-$42 batch yield stopped at an unsupported scheduler decision: %s" % str(scan))
	return {
		"ok": true,
		"status": "slot15_map42_batch_yielded",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"selected_slot_boundary": live_boundary.duplicate(true),
		"selected_slot_dispatch": dispatch.duplicate(true),
		"selected_slot_dispatch_boundary": dispatch_boundary.duplicate(true),
		"map_batch_result": batch.duplicate(true),
		"yielded_boundary": _scheduler.get_task_boundary_snapshot(SLOT_15),
		"scheduler_scan_results": scan_results.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"awaiting_external_nmi": awaiting_nmi,
		"map_worker_rows_executed": true,
		"queue_bytes_generated": (batch.get("queue_bytes", PackedByteArray()) as PackedByteArray).size(),
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


## Resumes the source-selected final map-$42 continuation, returns through its
## callback and dispatcher, and enters the verified `$CAF7` task-finish handler.
## It stops there; the following scheduler/NMI transition is separate work.
func resume_selected_slot15_terminal_callback() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_15 \
			or not _last_source_boundary.contains("selected slot $15"):
		return _fail_result("Terminal map-$42 return requires the live scheduler-selected slot-$15 boundary.")
	var expected_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected slot-$15 terminal continuation.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "pc", "sp",
			"a", "x", "y", "p", "bank_low", "bank_high", "active_task_slot", "scheduler_y_register"]:
		if int(live_boundary.get(key, -1)) != int(expected_boundary.get(key, -2)):
			return _fail_result("Selected terminal slot-$15 boundary changed at %s; refusing stale return execution." % key)
	if live_boundary.get("record", PackedByteArray()) != expected_boundary.get("record", PackedByteArray()) \
			or live_boundary.get("ram_image", PackedByteArray()) != expected_boundary.get("ram_image", PackedByteArray()) \
			or live_boundary.get("stack_page", PackedByteArray()) != expected_boundary.get("stack_page", PackedByteArray()):
		return _fail_result("Selected terminal slot-$15 RAM, record, or stack changed before dispatch.")
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	if live_boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xEA, 0x0B, 0x12]) \
			or int(live_boundary.get("pc", -1)) != 0xCB0F \
			or int(live_ram[0x05CC]) != 0x42 or int(live_ram[0x05C9]) != 0x00:
		return _fail_result("Slot-$15 is not at the source-saved exhausted map-$42 row boundary.")
	var mapper := _mapper_snapshot_for_task_boundary(live_boundary)
	if int(mapper.get("bank_low", -1)) != 0x0B or int(mapper.get("bank_high", -1)) != 0x12:
		return _fail_result("Terminal map-$42 task did not retain its source bank-$0B worker state.")
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_15)
	if not bool(dispatch.get("ok", false)) or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x85C1 or int(dispatch.get("sp", -1)) != 0xEE:
		return _fail_result("Scheduler did not restore the exhausted map worker at `$85C1 RTS`: %s" % str(dispatch))
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
	var executor_boundary := dispatch_boundary.duplicate(true)
	executor_boundary["rom_sha256"] = ROM_SHA256
	var result: Dictionary = _slot15_map42_terminal_return_executor.execute_from_exhausted_map_worker(
		dispatch, executor_boundary)
	if not bool(result.get("ok", false)):
		return _fail_result("ROM-byte map-$42 terminal return stopped: %s" % String(result.get("error", "unknown source error")))
	if not _scheduler.adopt_slot15_map42_terminal_return_result(result):
		return _fail_result("Scheduler rejected the map-$42 terminal return: " + _scheduler.error_message)
	if not _scheduler.finish_task_at_handler(SLOT_15, 0xCAF7):
		return _fail_result("Scheduler rejected the source `$C512->$CAF7` finish: " + _scheduler.error_message)
	var post_finish_scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(post_finish_scan.get("ok", false)) \
			or int(post_finish_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		return _fail_result("After the ROM `$CAF7` finish, the source scheduler did not reach its NMI-ready wait: " + str(post_finish_scan))
	_phase = "awaiting_external_nmi"
	_last_source_boundary = "$CAF7 task finish -> scheduler WAIT_FOR_NMI_READY"
	return {
		"ok": true,
		"status": "slot15_map42_terminal_callback_finished_waiting_nmi",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"selected_slot_boundary": live_boundary.duplicate(true),
		"selected_slot_dispatch": dispatch.duplicate(true),
		"terminal_return_result": result.duplicate(true),
		"finished_slot_boundary": _scheduler.get_task_boundary_snapshot(SLOT_15),
		"slot15_record_after_finish": _scheduler.get_task_boundary_snapshot(SLOT_15).get("record", PackedByteArray()),
		"post_finish_scheduler_scan": post_finish_scan.duplicate(true),
		"awaiting_external_nmi": true,
		"next_external_nmi_required": true,
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
	}


## Consumes exactly one caller-supplied NMI after the slot-$09 `$CB0F` save.
## The live normal-NMI consumer returns its ordered bus events; the scheduler
## is scanned only through source-selected task boundaries. If slot `$01` is
## selected, this route executes its bounded caller/worker cycle and saves its
## next `$CB0F` yield before stopping at the following selected-task boundary.
func _advance_after_slot09_cb0f_wait(source_frame: int, ppu_ctrl_shadow: int) -> Dictionary:
	if not _configured or _phase != "awaiting_external_nmi" \
			or _last_source_boundary != "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			or _last_external_nmi_frame < 0:
		return _fail_result("Second-NMI transition requires the live slot-$09 scheduler wait boundary.")
	if source_frame < 0 or source_frame <= _last_external_nmi_frame:
		return _fail_result("External NMI frame labels must be nonnegative and strictly increasing.")
	if _pending_nmi_queue_state.is_empty():
		return _fail_result("Second-NMI transition has no source-owned pending PPU queue contract.")
	var live_queue_state: Dictionary = _scheduler.get_live_nmi_secondary_queue_state()
	if live_queue_state != _pending_nmi_queue_state:
		return _fail_result("Pending source PPU queue changed after its producer boundary and before the caller-supplied NMI.")
	var source_boundary_before_nmi := _last_source_boundary
	_pending_selected_task_slot = -1
	_pending_slot05_mapper_select = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	_last_external_nmi_frame = source_frame
	_last_nmi_result = _scheduler.service_external_nmi_delivery(
		source_frame, ppu_ctrl_shadow, true)
	if not bool(_last_nmi_result.get("ok", false)) \
			or not bool(_last_nmi_result.get("serviced", false)):
		return _fail_result("Scheduler could not service the caller-confirmed second NMI: " + _scheduler.error_message)
	var secondary_queue: Dictionary = _last_nmi_result.get("secondary_queue", {})
	var ppu_bus_events: Array = _last_nmi_result.get("ppu_bus_events", [])
	var queue_branch := String(secondary_queue.get("branch", ""))
	if String(_last_nmi_result.get("path", "")) != "fixed_normal" \
			or String(secondary_queue.get("status", "")) != "transferred" \
			or queue_branch not in ["primary_queue_consumed", "secondary_queue_consumed"] \
			or ppu_bus_events.is_empty():
		return _fail_result("Second NMI did not consume a source-owned normal PPU queue: " + str(secondary_queue))
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after second NMI failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		return _fail_result("Second NMI did not select a source-yielded task: %s" % str(scan_results))
	var selected_slot := int(scan.get("selected_slot_base", -1))
	_pending_selected_task_slot = selected_slot
	var dispatch: Dictionary = {}
	var selected_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(selected_slot)
	var slot01_call_request: Dictionary = {}
	var slot01_ee9f_result: Dictionary = {}
	var slot01_after_ee9f_boundary: Dictionary = {}
	var slot01_e3ca_result: Dictionary = {}
	var slot01_yield_request: Dictionary = {}
	var slot01_saved_boundary: Dictionary = {}
	var post_root_yield_scan: Dictionary = {}
	var next_selected_slot := -1
	var next_selected_boundary: Dictionary = {}
	if selected_slot == SLOT_09:
		dispatch = _scheduler.dispatch_pending_task(SLOT_09)
		if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0xEB8B \
				or String(dispatch.get("resume_path", "")) != "yielded_rts":
			return _fail_result("Source scan selected slot-$09 but did not restore its actual `$EB8B` yielded continuation.")
		selected_boundary = _scheduler.get_task_boundary_snapshot(SLOT_09)
		_phase = "waiting_for_slot09_eb8b_source"
		_last_source_boundary = "$CAA5->$EB8B yielded dispatch"
	elif selected_slot == SLOT_01:
		dispatch = _scheduler.dispatch_pending_task(SLOT_01)
		if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0xCA52 \
				or String(dispatch.get("resume_path", "")) != "yielded_rts":
			return _fail_result("Second-NMI scan selected slot-$01 but did not restore its yielded `$CA52` continuation.")
		selected_boundary = _scheduler.get_task_boundary_snapshot(SLOT_01)
		slot01_call_request = _root_slot01_continuation.begin_from_slot01_yielded_resume(dispatch)
		if not bool(slot01_call_request.get("ok", false)) \
				or String(slot01_call_request.get("status", "")) != "call_requested" \
				or int(slot01_call_request.get("source_pc", -1)) != 0xCA52 \
				or int(slot01_call_request.get("target_cpu_address", -1)) != 0xEE9F \
				or int(slot01_call_request.get("expected_return_pc", -1)) != 0xCA55:
			return _fail_result("Live slot-$01 caller did not request its ROM `$CA52->$EE9F` call: " \
					+ _root_slot01_continuation.error_message)
		slot01_ee9f_result = _ee9f_empty_actor_executor.execute_to_source_caller(
			dispatch, selected_boundary, slot01_call_request)
		if not bool(slot01_ee9f_result.get("ok", false)) \
				or String(slot01_ee9f_result.get("status", "")) != "returned_to_source_caller":
			return _fail_result("Live `$CA52->$EE9F` source path did not return: " \
					+ String(slot01_ee9f_result.get("reason", slot01_ee9f_result.get("error", "unsupported source state"))))
		_last_root_actor_loop_result = _summarize_actor_loop_result(source_frame, slot01_ee9f_result)
		if not _scheduler.adopt_root_slot01_callee_return_state(0xCA52, 0xEE9F, slot01_ee9f_result):
			return _fail_result("Scheduler rejected the live `$EE9F` result: " + _scheduler.error_message)
		slot01_after_ee9f_boundary = _scheduler.get_task_boundary_snapshot(SLOT_01)
		var after_ee9f: Dictionary = _root_slot01_continuation.accept_callee_return(
			0xEE9F, 0xCA55, slot01_ee9f_result.get("registers", {}))
		if not bool(after_ee9f.get("ok", false)) \
				or String(after_ee9f.get("status", "")) != "call_requested" \
				or int(after_ee9f.get("source_pc", -1)) != 0xCA55 \
				or int(after_ee9f.get("target_cpu_address", -1)) != 0xE3CA \
				or int(after_ee9f.get("expected_return_pc", -1)) != 0xCA58:
			return _fail_result("Live slot-$01 caller did not request its source `$CA55->$E3CA` call: " \
					+ _root_slot01_continuation.error_message)
		slot01_e3ca_result = _e3ca_no_direction_executor.execute_from_source_call(
			slot01_ee9f_result, after_ee9f)
		if not bool(slot01_e3ca_result.get("ok", false)):
			return _fail_result("Live `$CA55->$E3CA` source path stopped: " \
					+ String(slot01_e3ca_result.get("error", "unsupported source state")))
		if not _scheduler.adopt_root_slot01_callee_return_state(0xCA55, 0xE3CA, slot01_e3ca_result):
			return _fail_result("Scheduler rejected the live `$E3CA` result: " + _scheduler.error_message)
		slot01_yield_request = _root_slot01_continuation.accept_callee_return(
			0xE3CA, 0xCA58, slot01_e3ca_result.get("registers", {}))
		if not bool(slot01_yield_request.get("ok", false)) \
				or String(slot01_yield_request.get("status", "")) != "yield_requested" \
				or int(slot01_yield_request.get("callsite_pc", -1)) != 0xCA4F:
			return _fail_result("Live root slot-$01 caller did not derive its `$CA4F->$CB0F` yield request: " \
					+ _root_slot01_continuation.error_message)
		if not _scheduler.adopt_root_slot01_loop_yield_call_state(slot01_yield_request):
			return _fail_result("Scheduler rejected the live `$CA4F` yield request: " + _scheduler.error_message)
		if not _scheduler.yield_at_verified_callsite(SLOT_01, 0xCA4F,
				int(slot01_yield_request.get("delay_in_a", -1)),
				int(slot01_yield_request.get("sp", -1)),
				int(slot01_yield_request.get("x", -1)),
				int(slot01_yield_request.get("y", -1)),
				int(slot01_yield_request.get("bank_low", -1)),
				int(slot01_yield_request.get("bank_high", -1))):
			return _fail_result("Root slot-$01 could not save its live `$CA4F->$CB0F` yield: " + _scheduler.error_message)
		slot01_saved_boundary = _scheduler.get_task_boundary_snapshot(SLOT_01)
		post_root_yield_scan = _scheduler.scan_ready_tasks_once()
		if not bool(post_root_yield_scan.get("ok", false)) \
				or int(post_root_yield_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
			return _fail_result("Scheduler scan after the live slot-$01 save did not reach the next yielded-task boundary: %s" % str(post_root_yield_scan))
		next_selected_slot = int(post_root_yield_scan.get("selected_slot_base", -1))
		next_selected_boundary = _scheduler.get_task_boundary_snapshot(next_selected_slot)
		_pending_selected_task_slot = next_selected_slot
		_pending_selected_task_boundary = next_selected_boundary.duplicate(true)
		var e3ca_mapper: Dictionary = slot01_e3ca_result.get("mapper", {})
		_pending_slot05_mapper_select = int(e3ca_mapper.get("register_select", -1))
		_last_root_e3ca_result = _summarize_e3ca_result(
			source_frame, slot01_e3ca_result, after_ee9f, slot01_yield_request, next_selected_slot)
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CA4F->$CB0F slot-$01 save; scheduler selected slot $%02X" % next_selected_slot
	else:
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X before task-body source" % selected_slot
	_pending_nmi_queue_state.clear()
	return {
		"ok": true,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"external_nmi_frame": source_frame,
		"external_nmi_consumed": true,
		"source_boundary_before_nmi": source_boundary_before_nmi,
		"pending_queue_guard_validated": true,
		"pending_queue_guard_captured_after_route": false,
		"last_source_boundary": _last_source_boundary,
		"next_task_scan_results": scan_results,
		"next_task_scan": scan,
		"selected_task_slot": selected_slot,
		"selected_task_boundary": selected_boundary,
		"selected_task_dispatch": dispatch,
		"slot01_call_request": slot01_call_request,
		"slot01_ee9f_result": slot01_ee9f_result,
		"slot01_after_ee9f_boundary": slot01_after_ee9f_boundary if selected_slot == SLOT_01 else {},
		"slot01_e3ca_result": slot01_e3ca_result if selected_slot == SLOT_01 else {},
		"slot01_yield_request": slot01_yield_request if selected_slot == SLOT_01 else {},
		"slot01_cb0f_saved_boundary": slot01_saved_boundary if selected_slot == SLOT_01 else {},
		"post_root_yield_scan": post_root_yield_scan if selected_slot == SLOT_01 else {},
		"next_selected_task_slot": next_selected_slot if selected_slot == SLOT_01 else -1,
		"next_selected_task_boundary": next_selected_boundary if selected_slot == SLOT_01 else {},
		"slot09_resumed_at_eb8b": selected_slot == SLOT_09 and int(dispatch.get("pc", -1)) == 0xEB8B,
		"awaiting_external_nmi": false,
		"next_external_nmi_required": false,
		"nmi_cadence_generated": false,
		"nmi_result": _last_nmi_result.duplicate(true),
		"secondary_queue": secondary_queue.duplicate(true),
		"ppu_bus_events": ppu_bus_events.duplicate(true),
		"ppu_bus_events_applied": false,
	}


## Samples actual controller state at the caller's source-frame boundary, before
## the next ROM-derived task or NMI transition. Refresh the selected-task
## snapshot so a legitimate `$001C/$001E` update is not mistaken for stale RAM.
func sample_controller_input(button_state: int) -> Dictionary:
	error_message = ""
	if not _configured or _phase not in ["awaiting_external_nmi", "waiting_for_selected_task_source",
			"waiting_for_slot09_eb8b_source"]:
		return _fail_result("Controller sampling requires a live source-route boundary.")
	var sample: Dictionary = _scheduler.sample_controller_input(button_state)
	if not bool(sample.get("ok", false)):
		return _fail_result("Source-frame controller sample was rejected: " + String(sample.get("error", _scheduler.error_message)))
	if _pending_selected_task_slot >= 0:
		var refreshed: Dictionary = _scheduler.get_task_boundary_snapshot(_pending_selected_task_slot)
		if refreshed.is_empty() or int(refreshed.get("active_task_slot", -1)) != -1:
			return _fail_result("Controller sampling could not refresh the stable selected-task boundary.")
		_pending_selected_task_boundary = refreshed.duplicate(true)
	return {"ok": true, "phase": _phase, "sample": sample.get("sample", {}),
		"pending_selected_task_slot": _pending_selected_task_slot,
		"pending_selected_task_boundary_pc": int(_pending_selected_task_boundary.get("pc", -1))}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"phase": _phase,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"last_external_nmi_frame": _last_external_nmi_frame,
		"pending_nmi_queue_guard_available": not _pending_nmi_queue_state.is_empty(),
		"pending_selected_task_slot": _pending_selected_task_slot,
		"pending_selected_task_boundary_pc": int(_pending_selected_task_boundary.get("pc", -1)),
		"nmi_cadence_generated": false,
		"source_boundary": _last_source_boundary,
		"scenario36_event_boundary_result": _scenario36_event_boundary_result.duplicate(true),
		"scenario36_post_event_result": _scenario36_post_event_result.duplicate(true),
		"scenario36_slot15_seed_result": _scenario36_slot15_seed_result.duplicate(true),
		"last_root_actor_loop_result": _last_root_actor_loop_result.duplicate(true),
		"last_root_e3ca_result": _last_root_e3ca_result.duplicate(true),
		"pending_source_call": _root_slot01_continuation.get_status() if _root_slot01_continuation != null else {},
		"ee9f_empty_actor_executor": _ee9f_empty_actor_executor.get_status() if _ee9f_empty_actor_executor != null else {},
		"e3ca_no_direction_executor": _e3ca_no_direction_executor.get_status() if _e3ca_no_direction_executor != null else {},
		"slot09_continuation_prefix": _slot09_continuation_prefix.error_message if _slot09_continuation_prefix != null else "unconfigured",
		"slot09_86f8_zero_branch_executor": _slot09_86f8_zero_branch_executor.get_status() if _slot09_86f8_zero_branch_executor != null else {},
		"slot09_8779_zero_branch_executor": _slot09_8779_zero_branch_executor.get_status() if _slot09_8779_zero_branch_executor != null else {},
		"slot09_87e6_zero_branch_executor": _slot09_87e6_zero_branch_executor.get_status() if _slot09_87e6_zero_branch_executor != null else {},
		"slot09_ebd7_root_zero_counter_executor": _slot09_ebd7_root_zero_counter_executor.get_status() if _slot09_ebd7_root_zero_counter_executor != null else {},
		"slot09_cb0f_scheduler_save": _scheduler.get_status().get("slot09_cb0f_scheduler_save", {}) if _scheduler != null else {},
		"scheduler": _scheduler.get_status() if _scheduler != null else {},
		"kickoff_rng_source_replay": _rng_source_replay.get_state() if _rng_source_replay != null else {},
	}


func get_last_root_actor_loop_result() -> Dictionary:
	return _last_root_actor_loop_result.duplicate(true)


func get_last_root_e3ca_result() -> Dictionary:
	return _last_root_e3ca_result.duplicate(true)


func _summarize_actor_loop_result(source_frame: int, result: Dictionary) -> Dictionary:
	var loop: Dictionary = result.get("actor_loop", {})
	return {
		"source_frame": source_frame,
		"status": String(result.get("status", "")),
		"source_manifest": String(result.get("source_manifest", "")),
		"registers": result.get("registers", {}).duplicate(true),
		"actor_records": result.get("actor_records", []).duplicate(true),
		"actor_visits": result.get("actor_visits", []).duplicate(true),
		"actor_loop": {
			"entry_pc": int(loop.get("entry_pc", -1)),
			"return_pc": int(loop.get("return_pc", -1)),
			"active_actor_count": int(loop.get("active_actor_count", -1)),
			"actor_outputs": loop.get("actor_outputs", []).duplicate(true),
			"sprites_written": int(loop.get("sprites_written", -1)),
			"final_oam_cursor": int(loop.get("final_oam_cursor", -1)),
			"sprite_selector": int(loop.get("sprite_selector", -1)),
			"oam_shadow": loop.get("oam_shadow", PackedByteArray()).duplicate(),
		},
	}


func _summarize_e3ca_result(source_frame: int, result: Dictionary, caller_request: Dictionary,
			yield_request: Dictionary, next_task_slot: int) -> Dictionary:
	return {
		"source_frame": source_frame,
		"status": String(result.get("status", "")),
		"source_manifest": String(result.get("source_manifest", "")),
		"registers": result.get("registers", {}).duplicate(true),
		"instruction_pcs": result.get("instruction_pcs", []).duplicate(true),
		"memory_writes": result.get("memory_writes", []).duplicate(true),
		"returned_to_caller": bool(result.get("returned_to_caller", false)),
		"movement_applied": bool(result.get("movement_applied", false)),
		"caller_request": caller_request.duplicate(true),
		"yield_request": yield_request.duplicate(true),
		"next_task_slot": next_task_slot,
	}


func _same_dispatch(actual: Dictionary, expected_variant: Variant) -> bool:
	if not expected_variant is Dictionary:
		return false
	var expected: Dictionary = expected_variant
	for key: String in ["slot_base", "pc", "sp", "a", "x", "y", "bank_low", "bank_high", "source_return_word"]:
		if int(actual.get(key, -1)) != int(expected.get(key, -2)):
			return false
	return true


func _fail(message: String) -> bool:
	error_message = message
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	_phase = "error"
	return {"ok": false, "phase": _phase, "error": error_message}
