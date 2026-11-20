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
const CLOCK_TICK_D193_WORKER_SCRIPT := preload("res://scripts/gameplay/rom_clock_tick_d193_worker.gd")
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
const SLOT15_CALLBACK_F2_POSITION_MAP_SCRIPT := preload("res://scripts/gameplay/rom_slot15_callback_f2_position_map_executor.gd")
const SLOT15_MAP_HANDLER_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map_handler_prefix_executor.gd")
const SLOT15_MAP_WORKER_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map_worker_8525_prefix_executor.gd")
const SLOT15_MAP42_FIRST_BATCH_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map42_first_batch_executor.gd")
const SLOT15_MAP_TERMINAL_RETURN_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map_terminal_return_executor.gd")
const SLOT11_ACTOR_WORKER_SCRIPT := preload("res://scripts/gameplay/rom_slot11_actor_worker_prefix_executor.gd")
const SLOT11_ACTOR_WORKER_RESUME_SCRIPT := preload("res://scripts/gameplay/rom_slot11_actor_worker_resume_executor.gd")
const SLOT05_SCENARIO35_RETURN_SCRIPT := preload("res://scripts/gameplay/rom_slot05_scenario35_return_executor.gd")
const SLOT05_SCENARIO18_POST_QUEUE_CALLER_SCRIPT := preload("res://scripts/gameplay/rom_slot05_scenario18_post_queue_caller_executor.gd")
const SCENARIO44_POST_QUEUE_RETURN_SCRIPT := preload("res://scripts/gameplay/rom_scenario44_post_queue_return_executor.gd")
const PLAYER_POSITION_INITIALIZER_SCRIPT := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")
const DAF5_RECEIVER_CALLER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_daf5_receiver_caller.gd")
const E6EC_HOLDER_COPY_SCRIPT := preload("res://scripts/gameplay/rom_fresh_e6ec_holder_copy_executor.gd")
const SCENARIO36_QUEUE_SCRIPT := preload("res://scripts/gameplay/rom_fresh_scenario36_queue_executor.gd")
const FIELD_ENTRY_PACKET_SOURCE_SCRIPT := preload("res://scripts/gameplay/rom_field_entry_window_packet_source.gd")
const RNG_SOURCE_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const RNG_PASS_EXTENSION_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_pass_extension.gd")
const FIRST_ACTION_DISPATCH_SCRIPT := preload("res://scripts/gameplay/rom_first_action_dispatch_executor.gd")
const FIRST_ACTION_CONFIRMATION_BRIDGE_SCRIPT := preload("res://scripts/gameplay/rom_first_action_confirmation_bridge_executor.gd")
const FIRST_ACTION_PASS_LABEL_RESUME_SCRIPT := preload("res://scripts/gameplay/rom_first_action_pass_label_resume_executor.gd")
const PASS_NO_CANDIDATES_CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_pass_no_candidates_continuation_executor.gd")
const PASS_HANDLER_BODY_SCRIPT := preload("res://scripts/gameplay/rom_pass_handler_body_executor.gd")
const PASS_RECEIVER_INPUT_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_input_executor.gd")
const PASS_RECEIVER_DESCRIPTOR_1D_PRESENTER_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_descriptor_1d_presenter.gd")
const PASS_RECEIVER_CONFIRMATION_WAIT_SCRIPT := preload("res://scripts/gameplay/rom_pass_receiver_confirmation_wait_executor.gd")
const PASS_CONFIRMATION_WAITER_POST_NMI_SCRIPT := preload("res://scripts/gameplay/rom_pass_confirmation_waiter_post_nmi_executor.gd")
const PASS_WAITER_FIELD_CALLER_E081_SCRIPT := preload("res://scripts/gameplay/rom_pass_waiter_field_caller_e081_executor.gd")
const MATCH_PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const RNG_SOURCE_SCHEDULE_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const RNG_ROUTE_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const RNG_RECEIVER_SOURCE_FRAME := 8593
const RAM_SIZE := 0x800

const SLOT_01 := 0x01
const SLOT_05 := 0x05
const SLOT_09 := 0x09
const SLOT_11 := 0x11
const SLOT_15 := 0x15


## Frame-9497 candidate at the scheduler-restored `$82F7` continuation. The
## descriptor byte `$0519=$63` includes the earlier slot-$09 `$EB9E` root tick.
## The saved task's RAM, return stack and registers are pinned as one profile;
## the resume executor separately verifies its ROM path to `$8047->$C515`.
static func is_scenario2e_actor6d_type5_packet_resume_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if int(boundary.get("slot_base", -1)) != SLOT_11 \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != 0x100 \
			or not record is PackedByteArray or record != PackedByteArray([0x00, 0xC4, 0x18, 0x19]) \
			or not mapper is Dictionary:
		return false
	var registers: Variant = mapper.get("bank_registers", {})
	if not registers is Dictionary:
		return false
	var expected_ppu_registers := PackedByteArray([0x3C, 0x4A, 0x20, 0x21, 0x00, 0x00])
	for register_index in expected_ppu_registers.size():
		var register_key := str(register_index)
		if registers.has(register_index) or registers.has(register_key):
			if int(registers.get(register_index, registers.get(register_key, -1))) \
					!= int(expected_ppu_registers[register_index]):
				return false
	var status := int(boundary.get("p", -1))
	var status_known_mask := int(boundary.get("p_known_mask", -1))
	return (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9BFE \
			and ram.slice(0x0515, 0x051D) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x63, 0xE8, 0x9B, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x02, 0x01, 0x04]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xEA, 0xA2]) \
			and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(mapper.get("bank_low", -1)) == 0x18 \
			and int(mapper.get("bank_high", -1)) == 0x19 \
			and int(mapper.get("select", -1)) in [0x06, 0x07] \
			and int(registers.get(6, registers.get("6", -1))) == 0x18 \
			and int(registers.get(7, registers.get("7", -1))) == 0x19 \
			and int(boundary.get("a", -1)) == 0x01 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x06 \
			and (status_known_mask & 0x83) == 0x83 \
			and (status & 0x83) == 0x00

var error_message := ""
var _configured := false
var _phase := "unconfigured"
var _scheduler: Variant = null
var _context_builder: Variant = null
var _period_task: Variant = null
var _continuation: Variant = null
var _worker_prefix: Variant = null
var _clock_tick_d193_worker: Variant = null
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
var _slot15_callback_f2_position_map_executor: Variant = null
var _slot15_map_handler_prefix_executor: Variant = null
var _slot15_map_worker_prefix_executor: Variant = null
var _slot15_map42_first_batch_executor: Variant = null
var _slot15_map_terminal_return_executor: Variant = null
var _slot11_actor_worker_executor: Variant = null
var _slot11_actor_worker_resume_executor: Variant = null
var _slot05_scenario35_return_executor: Variant = null
var _slot05_scenario18_post_queue_caller_executor: Variant = null
var _scenario44_post_queue_return_executor: Variant = null
var _player_position_initializer: Variant = null
var _daf5_receiver_caller: Variant = null
var _e6ec_holder_copy_executor: Variant = null
var _scenario36_queue_executor: Variant = null
var _field_entry_packet_source: Variant = null
var _rng_source_replay: Variant = null
var _rng_pass_extension: Variant = null
var _last_rng_pass_extension_receipt: Dictionary = {}
var _first_action_dispatch_executor: Variant = null
var _first_action_confirmation_bridge_executor: Variant = null
var _first_action_pass_label_resume_executor: Variant = null
var _pass_no_candidates_continuation_executor: Variant = null
var _pass_handler_body_executor: Variant = null
var _pass_receiver_input_executor: Variant = null
var _pass_receiver_descriptor_1d_presenter: Variant = null
var _pass_receiver_confirmation_wait_executor: Variant = null
var _pass_confirmation_waiter_post_nmi_executor: Variant = null
var _pass_waiter_field_caller_e081_executor: Variant = null
var _route_context: Variant
var _bootstrap_result: Dictionary = {}
var _fresh_period_result: Dictionary = {}
var _initial_daaa_continuation_result: Dictionary = {}
var _initial_worker_result: Dictionary = {}
var _last_slot05_source_worker_result: Dictionary = {}
var _last_slot05_ee_row_result: Dictionary = {}
var _last_slot05_pass_receiver_first_yield_result: Dictionary = {}
var _last_slot05_pass_receiver_descriptor_1d_first_yield_result: Dictionary = {}
var _pass_receiver_packet_batch_progress: Array[int] = []
var _pass_receiver_packet_batch_nmi_frames: Array[int] = []
var _pass_receiver_descriptor_1d_batch_progress: Array[int] = []
var _pass_receiver_descriptor_1d_batch_nmi_frames: Array[int] = []
var _pass_receiver_descriptor_1d_final_queue_pending := false
var _pass_receiver_descriptor_1d_input_poll_pending := false
var _pass_receiver_confirmation_input_pending := false
var _last_slot05_action_menu_wait_result: Dictionary = {}
var _last_first_action_menu_dispatch_result: Dictionary = {}
var _last_first_action_menu_adoption_result: Dictionary = {}
var _last_first_action_confirmation_bridge_result: Dictionary = {}
var _last_first_action_confirmation_bridge_adoption: Dictionary = {}
var _last_first_action_confirmation_bridge_scans: Array[Dictionary] = []
var _last_first_action_pass_label_result: Dictionary = {}
var _last_first_action_pass_label_adoption: Dictionary = {}
var _last_first_action_pass_label_return_receipt: Dictionary = {}
var _last_pass_no_candidates_continuation_result: Dictionary = {}
var _last_pass_no_candidates_continuation_adoption: Dictionary = {}
var _last_pass_handler_body_result: Dictionary = {}
var _last_pass_handler_body_adoption: Dictionary = {}
var _last_pass_receiver_input_result: Dictionary = {}
var _last_pass_receiver_input_adoption: Dictionary = {}
var _last_pass_receiver_descriptor_1d_batch: Dictionary = {}
var _last_pass_receiver_confirmation_wait_result: Dictionary = {}
var _last_pass_handler_cb0f_save_result: Dictionary = {}
var _last_pass_handler_cb0f_scans: Array[Dictionary] = []
var _last_pass_waiter_field_call_contract: Dictionary = {}
var _pending_first_action_menu_handler_dispatch: Dictionary = {}
var _hold_pass_confirmation_input_state := false
var _last_d193_clock_tick_handoff_result: Dictionary = {}
var _verified_stamina_update_receipt: Dictionary = {}
var _scenario44_field_entry_worker_result: Dictionary = {}
var _slot09_yield_result: Dictionary = {}
var _scenario36_event_boundary_result: Dictionary = {}
var _scenario36_post_event_result: Dictionary = {}
var _scenario36_slot15_seed_result: Dictionary = {}
var _last_nmi_result: Dictionary = {}
var _last_root_actor_loop_result: Dictionary = {}
var _last_root_e3ca_result: Dictionary = {}
var _last_slot09_resume_input_debug: Dictionary = {}
var _last_external_nmi_frame := -1
var _last_source_boundary := "unconfigured_or_error"
var _pending_nmi_queue_state: Dictionary = {}
var _pending_slot11_a21a_queue_wait := false
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
	_clock_tick_d193_worker = CLOCK_TICK_D193_WORKER_SCRIPT.new()
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
	_slot15_callback_f2_position_map_executor = SLOT15_CALLBACK_F2_POSITION_MAP_SCRIPT.new()
	_slot15_map_handler_prefix_executor = SLOT15_MAP_HANDLER_PREFIX_SCRIPT.new()
	_slot15_map_worker_prefix_executor = SLOT15_MAP_WORKER_PREFIX_SCRIPT.new()
	_slot15_map42_first_batch_executor = SLOT15_MAP42_FIRST_BATCH_SCRIPT.new()
	_slot15_map_terminal_return_executor = SLOT15_MAP_TERMINAL_RETURN_SCRIPT.new()
	_slot11_actor_worker_executor = SLOT11_ACTOR_WORKER_SCRIPT.new()
	_slot11_actor_worker_resume_executor = SLOT11_ACTOR_WORKER_RESUME_SCRIPT.new()
	_slot05_scenario35_return_executor = SLOT05_SCENARIO35_RETURN_SCRIPT.new()
	_slot05_scenario18_post_queue_caller_executor = SLOT05_SCENARIO18_POST_QUEUE_CALLER_SCRIPT.new()
	_scenario44_post_queue_return_executor = SCENARIO44_POST_QUEUE_RETURN_SCRIPT.new()
	_player_position_initializer = PLAYER_POSITION_INITIALIZER_SCRIPT.new()
	_daf5_receiver_caller = DAF5_RECEIVER_CALLER_SCRIPT.new()
	_e6ec_holder_copy_executor = E6EC_HOLDER_COPY_SCRIPT.new()
	_scenario36_queue_executor = SCENARIO36_QUEUE_SCRIPT.new()
	_field_entry_packet_source = FIELD_ENTRY_PACKET_SOURCE_SCRIPT.new()
	_first_action_dispatch_executor = FIRST_ACTION_DISPATCH_SCRIPT.new()
	if not _first_action_dispatch_executor.configure_from_project_sources():
		return _fail("First-action menu ROM input source failed: " + _first_action_dispatch_executor.error_message)
	_first_action_confirmation_bridge_executor = FIRST_ACTION_CONFIRMATION_BRIDGE_SCRIPT.new()
	if not _first_action_confirmation_bridge_executor.configure_from_project_sources():
		return _fail("First-action confirmation bridge sources failed: " + _first_action_confirmation_bridge_executor.error_message)
	_first_action_pass_label_resume_executor = FIRST_ACTION_PASS_LABEL_RESUME_SCRIPT.new()
	if not _first_action_pass_label_resume_executor.configure_from_project_sources():
		return _fail("First-action PASS label renderer sources failed: " + _first_action_pass_label_resume_executor.error_message)
	_pass_no_candidates_continuation_executor = PASS_NO_CANDIDATES_CONTINUATION_SCRIPT.new()
	if not _pass_no_candidates_continuation_executor.configure_from_project_sources():
		return _fail("PASS no-candidates continuation sources failed: " + _pass_no_candidates_continuation_executor.error_message)
	_pass_handler_body_executor = PASS_HANDLER_BODY_SCRIPT.new()
	if not _pass_handler_body_executor.configure_from_project_sources():
		return _fail("PASS handler body sources failed: " + _pass_handler_body_executor.error_message)
	_pass_receiver_input_executor = PASS_RECEIVER_INPUT_SCRIPT.new()
	if not _pass_receiver_input_executor.configure_from_project_sources():
		return _fail("PASS receiver input ROM sources failed: " + _pass_receiver_input_executor.error_message)
	_pass_receiver_descriptor_1d_presenter = PASS_RECEIVER_DESCRIPTOR_1D_PRESENTER_SCRIPT.new()
	if not _pass_receiver_descriptor_1d_presenter.configure_from_project_sources():
		return _fail("PASS receiver descriptor-$1D sources failed: " + _pass_receiver_descriptor_1d_presenter.error_message)
	_pass_receiver_confirmation_wait_executor = PASS_RECEIVER_CONFIRMATION_WAIT_SCRIPT.new()
	if not _pass_receiver_confirmation_wait_executor.configure_from_project_sources():
		return _fail("PASS confirmation-wait ROM sources failed: " + _pass_receiver_confirmation_wait_executor.error_message)
	_pass_confirmation_waiter_post_nmi_executor = PASS_CONFIRMATION_WAITER_POST_NMI_SCRIPT.new()
	if not _pass_confirmation_waiter_post_nmi_executor.configure_from_project_sources():
		return _fail("PASS confirmation waiter packet ROM sources failed: " + _pass_confirmation_waiter_post_nmi_executor.error_message)
	_pass_waiter_field_caller_e081_executor = PASS_WAITER_FIELD_CALLER_E081_SCRIPT.new()
	if not _pass_waiter_field_caller_e081_executor.configure_from_project_sources():
		return _fail("PASS E081 field-caller ROM sources failed: " + _pass_waiter_field_caller_e081_executor.error_message)
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
	if not _clock_tick_d193_worker.configure_from_project_sources():
		return _fail("Fresh clock `$D193` source package failed: " + _clock_tick_d193_worker.error_message)
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
	if not _slot05_scenario18_post_queue_caller_executor.configure():
		return _fail("Slot-$05 scenario-$18 caller source package failed: " + _slot05_scenario18_post_queue_caller_executor.error_message)
	if not _scenario44_post_queue_return_executor.configure():
		return _fail("Scenario-$44 post-queue ROM caller source package failed: " + _scenario44_post_queue_return_executor.error_message)
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
	_rng_pass_extension = RNG_PASS_EXTENSION_SCRIPT.new()
	if not _rng_pass_extension.configure_from_project_sources():
		return _fail("ROM-only first-PASS RNG extension failed integrity/input-route checks: " + _rng_pass_extension.error_message)
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
	_last_slot09_resume_input_debug.clear()
	_last_external_nmi_frame = -1
	_rng_source_replay.reset_from_cold_start()
	if _rng_pass_extension == null or not _rng_pass_extension.reset_replay():
		return _fail_result("First-PASS RNG extension could not reset to its checked receiver state: " \
			+ String(_rng_pass_extension.error_message if _rng_pass_extension != null else "extension is missing"))
	_pending_nmi_queue_state.clear()
	_pending_slot11_a21a_queue_wait = false
	_fresh_period_result.clear()
	_initial_daaa_continuation_result.clear()
	_last_slot05_source_worker_result.clear()
	_last_slot05_ee_row_result.clear()
	_last_slot05_pass_receiver_first_yield_result.clear()
	_last_slot05_pass_receiver_descriptor_1d_first_yield_result.clear()
	_pass_receiver_packet_batch_progress.clear()
	_pass_receiver_packet_batch_nmi_frames.clear()
	_pass_receiver_descriptor_1d_batch_progress.clear()
	_pass_receiver_descriptor_1d_batch_nmi_frames.clear()
	_pass_receiver_descriptor_1d_final_queue_pending = false
	_pass_receiver_descriptor_1d_input_poll_pending = false
	_pass_receiver_confirmation_input_pending = false
	_last_d193_clock_tick_handoff_result.clear()
	_verified_stamina_update_receipt.clear()
	_scenario44_field_entry_worker_result.clear()
	_pending_selected_task_slot = -1
	_pending_slot05_mapper_select = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	_last_first_action_menu_dispatch_result.clear()
	_last_first_action_menu_adoption_result.clear()
	_last_first_action_confirmation_bridge_result.clear()
	_last_first_action_confirmation_bridge_adoption.clear()
	_last_first_action_confirmation_bridge_scans.clear()
	_last_first_action_pass_label_result.clear()
	_last_first_action_pass_label_adoption.clear()
	_last_first_action_pass_label_return_receipt.clear()
	_last_pass_no_candidates_continuation_result.clear()
	_last_pass_no_candidates_continuation_adoption.clear()
	_last_pass_handler_body_result.clear()
	_last_pass_handler_body_adoption.clear()
	_last_pass_receiver_input_result.clear()
	_last_pass_receiver_input_adoption.clear()
	_last_pass_receiver_descriptor_1d_batch.clear()
	_last_pass_receiver_confirmation_wait_result.clear()
	_last_pass_handler_cb0f_save_result.clear()
	_last_pass_handler_cb0f_scans.clear()
	_last_pass_waiter_field_call_contract.clear()
	_pending_first_action_menu_handler_dispatch.clear()
	_hold_pass_confirmation_input_state = false
	_route_context = route_context
	_bootstrap_result = _scheduler.initialize_fresh_game_bootstrap()
	if not bool(_bootstrap_result.get("ok", false)):
		_fail("Fresh-game source bootstrap failed: " + _scheduler.error_message)
		return {}
	var selector_roster_receipt: Dictionary = _route_context.selector_roster_write_receipt
	if not selector_roster_receipt.is_empty():
		var roster_adoption: Dictionary = _scheduler.apply_rom_match_selector_roster(
			selector_roster_receipt)
		if not bool(roster_adoption.get("ok", false)):
			_fail("ROM selector player records could not enter the live task scheduler: " + String(
				roster_adoption.get("error", _scheduler.error_message)))
			return {}
	var stamina_receipt: Dictionary = _route_context.stamina_initialization_receipt
	if not stamina_receipt.is_empty():
		var stamina_adoption: Dictionary = \
				_scheduler.apply_rom_fresh_match_stamina_initialization(stamina_receipt)
		if not bool(stamina_adoption.get("ok", false)):
			_fail("ROM `$DB62` energy writes could not enter live slot-$05 RAM: " \
				+ String(stamina_adoption.get("error", _scheduler.error_message)))
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
	_initial_daaa_continuation_result = worker_entry.duplicate(true)
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
		"initial_daaa_continuation_result": _initial_daaa_continuation_result.duplicate(true),
		"slot05_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
		"slot09_boundary": _scheduler.get_task_boundary_snapshot(SLOT_09),
		"initial_worker_exit_pc": int(_initial_worker_result.get("exit_pc", -1)),
		"initial_worker_exit_kind": String(_initial_worker_result.get("exit_kind", "")),
	}


## Consume one NMI edge already observed by the caller's PPU model. The frame
## label is diagnostic only; this method never creates an edge or a delay.
## The first-action command menu remains inside slot-$05 `$D5EA` while normal
## frame NMIs arrive. Service that externally supplied queue/latch transition
## without scanning tasks; the active source routine continues after RTI.
func service_first_action_menu_external_nmi(source_frame: int,
		ppu_ctrl_shadow: int) -> Dictionary:
	error_message = ""
	if not _configured or _phase != "first_action_menu_ready" \
			or source_frame < 0 or source_frame <= _last_external_nmi_frame:
		return _fail_result("First-action menu NMI requires a strictly newer external frame while the source route waits at `$D5EA`.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if boundary.is_empty() or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("pc", -1)) != 0xD5EA \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B:
		return _fail_result("First-action menu NMI cannot interrupt a different source task boundary.")
	var rng_extension_receipt := _advance_rng_pass_extension(source_frame)
	if not bool(rng_extension_receipt.get("ok", false)):
		return _fail_result("ROM-only PASS-route RNG could not advance before the menu NMI: " \
			+ String(rng_extension_receipt.get("error", "unknown extension failure")))
	_last_rng_pass_extension_receipt = rng_extension_receipt.duplicate(true)
	var nmi_result: Dictionary = _scheduler.service_external_nmi_delivery(
		source_frame, ppu_ctrl_shadow, true)
	if not bool(nmi_result.get("ok", false)) or not bool(nmi_result.get("serviced", false)):
		return _fail_result("Scheduler rejected the caller-supplied first-action NMI: " \
			+ String(_scheduler.error_message))
	_last_external_nmi_frame = source_frame
	_last_nmi_result = nmi_result.duplicate(true)
	return {
		"ok": true, "status": "first_action_menu_nmi_serviced_without_task_scan",
		"source_frame": source_frame, "external_nmi_consumed": true,
		"normal_nmi_result": nmi_result.duplicate(true),
		"ppu_bus_events": nmi_result.get("ppu_bus_events", []).duplicate(true),
		"rng_pass_extension": rng_extension_receipt.duplicate(true),
		"nmi_cadence_generated": false, "trace_state_used": false,
	}


func advance_on_external_nmi(source_frame: int, ppu_ctrl_shadow: int) -> Dictionary:
	error_message = ""
	if _rng_source_replay != null and source_frame <= RNG_RECEIVER_SOURCE_FRAME \
			and source_frame > int(_rng_source_replay.get_state().get("last_source_frame", 0)):
		if not _rng_source_replay.advance_to_source_frame(source_frame):
			return _fail_result("ROM-only KICK OFF RNG replay could not advance through frame %d: " % source_frame + _rng_source_replay.error_message)
		if not _scheduler.adopt_kickoff_rng_source_replay_state(_rng_source_replay.get_state()):
			return _fail_result("Gameplay scheduler rejected the hash-bound ROM RNG event state: " + _scheduler.error_message)
	if source_frame > RNG_RECEIVER_SOURCE_FRAME:
		var rng_extension_receipt := _advance_rng_pass_extension(source_frame)
		if not bool(rng_extension_receipt.get("ok", false)):
			return _fail_result("ROM-only PASS-route RNG could not advance before the source NMI: " \
				+ String(rng_extension_receipt.get("error", "unknown extension failure")))
		_last_rng_pass_extension_receipt = rng_extension_receipt.duplicate(true)
	if _phase == "awaiting_external_nmi" \
			and _last_source_boundary == "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			and _pass_receiver_packet_batch_progress.is_empty():
		return _advance_after_slot09_cb0f_wait(source_frame, ppu_ctrl_shadow)
	if not _configured or _phase != "awaiting_external_nmi":
		return _fail_result("Runner must be initialized and awaiting an external NMI edge.")
	if source_frame < 0 or source_frame <= _last_external_nmi_frame:
		return _fail_result("External NMI frame labels must be nonnegative and strictly increasing.")
	var source_boundary_before_nmi := _last_source_boundary
	var queue_guard_validated := false
	var pass_receiver_packet_nmi := _pass_receiver_packet_batch_progress.size() \
			== _pass_receiver_packet_batch_nmi_frames.size() + 1 \
			and int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) == 0x80 \
			and int(_pending_nmi_queue_state.get("primary_count_0498", -1)) == 0
	var pass_receiver_1d_packet_nmi := _pass_receiver_descriptor_1d_batch_progress.size() \
			== _pass_receiver_descriptor_1d_batch_nmi_frames.size() + 1 \
			and int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) == 0x80 \
			and int(_pending_nmi_queue_state.get("primary_count_0498", -1)) == 0
	var pass_receiver_1d_final_nmi := _pass_receiver_descriptor_1d_final_queue_pending \
			and int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) == 0x80 \
			and int(_pending_nmi_queue_state.get("primary_count_0498", -1)) == 0
	if not _pending_nmi_queue_state.is_empty():
		var live_queue_state: Dictionary = _scheduler.get_live_nmi_secondary_queue_state()
		if live_queue_state != _pending_nmi_queue_state:
			return _fail_result("Pending source `$0515/$04A5` queue changed after its producer boundary and before the caller-supplied NMI.")
		queue_guard_validated = true
	if pass_receiver_packet_nmi or pass_receiver_1d_packet_nmi or pass_receiver_1d_final_nmi:
		if not queue_guard_validated:
			return _fail_result("PASS receiver packet NMI lacks its exact pending scheduler queue and preceding ROM row batch.")
	_last_external_nmi_frame = source_frame
	_last_nmi_result = _scheduler.service_external_nmi_delivery(
		source_frame, ppu_ctrl_shadow, true)
	if not bool(_last_nmi_result.get("ok", false)) or not bool(_last_nmi_result.get("serviced", false)):
		return _fail_result("Scheduler could not service the caller-confirmed NMI edge: " + _scheduler.error_message)
	if OS.get_environment("CT2_TRACE_FIRST_PASS_RECEIVER_WINDOW").strip_edges() == "1" \
			and source_frame >= 9067 and source_frame <= 9073:
		var nmi_queue: Dictionary = _last_nmi_result.get("secondary_queue", {})
		print("PASS_PACKET_NMI frame=%d candidate=%s descriptor_1d=%s final_1d=%s progress=%s consumed_frames=%s pending=%s result=%s" % [
			source_frame, str(pass_receiver_packet_nmi), str(pass_receiver_1d_packet_nmi),
			str(pass_receiver_1d_final_nmi),
			JSON.stringify(_pass_receiver_packet_batch_progress),
			JSON.stringify(_pass_receiver_packet_batch_nmi_frames),
			JSON.stringify({"ready": _pending_nmi_queue_state.get("ready_flag_0515", -1),
				"primary": _pending_nmi_queue_state.get("primary_count_0498", -1)}),
			JSON.stringify({"status": nmi_queue.get("status", ""),
				"branch": nmi_queue.get("branch", ""), "kind": nmi_queue.get("queue_kind", ""),
				"packets": nmi_queue.get("packet_count", -1),
				"ready_before": nmi_queue.get("ready_flag_before", -1),
				"ready_after": nmi_queue.get("ready_flag_after", -1),
				"ppu_events": (_last_nmi_result.get("ppu_bus_events", []) as Array).size()})])
	if pass_receiver_packet_nmi or pass_receiver_1d_packet_nmi or pass_receiver_1d_final_nmi:
		var secondary_queue: Dictionary = _last_nmi_result.get("secondary_queue", {})
		if String(secondary_queue.get("status", "")) != "transferred" \
				or String(secondary_queue.get("queue_kind", "")) != "secondary" \
				or String(secondary_queue.get("branch", "")) != "secondary_queue_consumed" \
				or int(secondary_queue.get("packet_count", -1)) \
				!= (1 if pass_receiver_1d_final_nmi else 2) \
				or int(secondary_queue.get("ready_flag_before", -1)) != 0x80 \
				or int(secondary_queue.get("ready_flag_after", -1)) != 0 \
				or (_last_nmi_result.get("ppu_bus_events", []) as Array).is_empty():
			return _fail_result("PASS receiver's source NMI did not consume the expected ROM packet queue into PPU bus events.")
		if pass_receiver_packet_nmi:
			_pass_receiver_packet_batch_nmi_frames.append(source_frame)
		if pass_receiver_1d_packet_nmi:
			_pass_receiver_descriptor_1d_batch_nmi_frames.append(source_frame)
		if pass_receiver_1d_final_nmi:
			_pass_receiver_descriptor_1d_final_queue_pending = false
	# `$A21A` is a yielded task continuation. Let the ROM scheduler resume its
	# higher-priority tasks first; the slot-$11 worker rechecks `$0515` only when
	# its own task is selected again. Resuming it immediately here would skip
	# queue producers that can keep the secondary queue busy after this NMI.
	if _pending_slot11_a21a_queue_wait:
		_pending_nmi_queue_state.clear()
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
			var stopped_detail: Dictionary = ee9f_result.get("detail", {})
			var partial_state: Dictionary = ee9f_result.get("partial_state", {})
			var stopped_registers: Dictionary = partial_state.get("registers", {})
			return _fail_result("ROM-byte `$CA52->$EE9F` execution stopped (status=%s pc=$%04X): reason=%s error=%s detail=%s registers=%s" % [
				String(ee9f_result.get("status", "")), int(ee9f_result.get("stop_pc", -1)),
				String(ee9f_result.get("reason", "")), String(ee9f_result.get("error", "")),
				JSON.stringify(stopped_detail), JSON.stringify(stopped_registers)])
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
				and int(post_root_yield_scan.get("selected_slot_base", -1)) == SLOT_05 \
				and not _last_slot05_pass_receiver_first_yield_result.is_empty():
			var root_e3ca_mapper_for_pass_receiver: Dictionary = e3ca_result.get("mapper", {})
			_pending_selected_task_slot = SLOT_05
			_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
			_pending_slot05_mapper_select = int(root_e3ca_mapper_for_pass_receiver.get("register_select", -1))
			if _pending_selected_task_boundary.is_empty() \
					or int(_pending_selected_task_boundary.get("active_task_slot", -1)) != -1 \
					or int(_pending_selected_task_boundary.get("pc", -1)) != 0xCB0F \
					or int(_pending_selected_task_boundary.get("phase", -1)) != 3 \
					or int(_pending_selected_task_boundary.get("pending_resume", -1)) != 2 \
					or _pending_slot05_mapper_select < 0 or _pending_slot05_mapper_select > 0xFF:
				return _fail_result("Root slot-$01 selected PASS receiver slot-$05 without its live `$CB0F` resume boundary and MMC3 selector: " \
					+ JSON.stringify({"boundary": _pending_selected_task_boundary,
						"mapper_select": _pending_slot05_mapper_select,
						"e3ca_mapper": root_e3ca_mapper_for_pass_receiver}))
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(
				_pending_selected_task_boundary)
			_pending_nmi_queue_state.clear()
			_phase = "waiting_for_selected_task_source"
			_last_source_boundary = "$CAA5 selected slot $05 after root slot-$01 yield"
			return _attach_external_nmi_receipt({
				"ok": true, "status": "nmi_resumed_slot01_then_selected_pass_receiver_slot05",
				"phase": _phase, "rom_sha256": ROM_SHA256,
				"source_frame": source_frame,
				"source_boundary_before_nmi": source_boundary_before_nmi,
				"selected_task_slot_before_resume": SLOT_01,
				"root_slot01_yield_result": slot01_yield_request.duplicate(true),
				"post_root_yield_scan": post_root_yield_scan.duplicate(true),
				"next_selected_task_slot": SLOT_05,
				"next_selected_task_boundary": _pending_selected_task_boundary.duplicate(true),
				"ppu_bus_events_applied": false,
				"nmi_cadence_generated": false,
			}, source_boundary_before_nmi, queue_guard_validated)
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
		if int(slot05_dispatch.get("pc", -1)) in [0xCC53, 0xCCA3, 0xCCD1] \
				and String(slot05_boundary.get("source_label", "")).begins_with(
					"ROM-byte PASS confirmation waiter"):
			return _attach_external_nmi_receipt(
				_resume_slot05_pass_confirmation_waiter(slot05_dispatch, slot05_boundary),
				source_boundary_before_nmi, queue_guard_validated)
		if int(slot05_dispatch.get("pc", -1)) == 0xD80F:
			return _attach_external_nmi_receipt(
				_accept_slot05_pass_receiver_input_wait(slot05_dispatch, slot05_boundary, source_frame),
				source_boundary_before_nmi, queue_guard_validated)
		if int(slot05_dispatch.get("pc", -1)) in [0xCC53, 0xCCA3, 0xCCD1, 0x82E3]:
			return _attach_external_nmi_receipt(
				_resume_slot05_field_minimap_wait(slot05_dispatch, slot05_boundary),
				source_boundary_before_nmi, queue_guard_validated)
		if int(slot05_dispatch.get("pc", -1)) == 0xCBC1:
			if String(slot05_boundary.get("source_label", "")) == "ROM-byte fresh scenario-$36 caller `$DB0E->$CBB0->$CB0F`":
				return _attach_external_nmi_receipt(
					_resume_slot05_scenario36_queue_return(slot05_dispatch, slot05_boundary),
					source_boundary_before_nmi, queue_guard_validated)
			if _is_slot05_scenario1c_handoff_return(slot05_dispatch, slot05_boundary):
				return _attach_external_nmi_receipt(
					_resume_slot05_scenario1c_handoff(slot05_dispatch, slot05_boundary),
					source_boundary_before_nmi, queue_guard_validated)
			return _attach_external_nmi_receipt(
				_resume_slot05_scenario35_wait_cycle(slot05_dispatch, slot05_boundary),
				source_boundary_before_nmi, queue_guard_validated)
		if int(slot05_dispatch.get("pc", -1)) == 0xDAE2:
			return _attach_external_nmi_receipt(
				_resume_slot05_scenario35_wait_resume_cycle(slot05_dispatch, slot05_boundary),
				source_boundary_before_nmi, queue_guard_validated)
		if int(slot05_dispatch.get("pc", -1)) == 0xE778 \
				and String(slot05_boundary.get("source_label", "")).begins_with(
					"ROM-byte PASS scenario-$18 field update"):
			return _attach_external_nmi_receipt(
				_resume_slot05_scenario18_field_update(slot05_dispatch, slot05_boundary),
				source_boundary_before_nmi, queue_guard_validated)
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
		var scan_return_bridge: Dictionary = {}
		if not bool(slot05_resume_result.get("ok", false)) \
				and String(slot05_resume_result.get("exit_kind", "")) == "unresolved_source_span" \
				and int(slot05_resume_result.get("exit_pc", -1)) == 0xD96F:
			scan_return_bridge = \
				_worker_prefix.execute_pass_receiver_scan_return_bridge(slot05_resume_result)
			if not scan_return_bridge.is_empty():
				if not bool(scan_return_bridge.get("ok", false)):
					return _fail_result("ROM-byte PASS receiver `$D96F->$D837` bridge stopped: " \
						+ String(scan_return_bridge.get("error", _worker_prefix.error_message)))
				var d837_boundary: Variant = scan_return_bridge.get("next_boundary_snapshot", {})
				if not d837_boundary is Dictionary or int((d837_boundary as Dictionary).get("pc", -1)) != 0xD837:
					return _fail_result("PASS receiver scan-return bridge omitted its source `$D837` boundary.")
				var source_return_boundary: Dictionary = d837_boundary
				var controller_sample: Dictionary = _scheduler.get_status().get("controller_sample", {})
				source_return_boundary["source_frame_label"] = source_frame
				source_return_boundary["emulator_data_used"] = false
				source_return_boundary["polled_controller"] = {
					"direction_mask": int(controller_sample.get("held_ram_001c", -1)),
					"button_mask": int(controller_sample.get("edge_ram_001e", -1)),
				}
				var post_renderer_result: Dictionary = \
					_pass_receiver_input_executor.execute_after_receiver_renderer_return(source_return_boundary)
				if not bool(post_renderer_result.get("ok", false)):
					return _fail_result("ROM-byte PASS receiver caller stopped after `$D96F->$D837`: " \
						+ String(post_renderer_result.get("error", _pass_receiver_input_executor.error_message)))
				post_renderer_result["source_frame_label"] = source_frame
				post_renderer_result["sample_receipt_id"] = int(controller_sample.get("sample_receipt_id", -1))
				post_renderer_result["input_sample_receipt"] = controller_sample.duplicate(true)
				var scan_return_adoption: Dictionary = \
					_scheduler.adopt_slot05_pass_receiver_scan_return_result(
						slot05_dispatch, slot05_boundary, slot05_resume_result,
						scan_return_bridge, post_renderer_result, controller_sample)
				if not bool(scan_return_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the live PASS scan-return/A continuation: " \
						+ String(scan_return_adoption.get("error", _scheduler.error_message)))
				_last_pass_receiver_input_result = post_renderer_result.duplicate(true)
				_last_pass_receiver_input_adoption = scan_return_adoption.duplicate(true)
				_pass_receiver_confirmation_input_pending = false
				_phase = "pass_receiver_confirmed_at_d70c"
				_last_source_boundary = "ROM PASS receiver A continued from `$D96F->$D837->$D70C`"
				return _attach_external_nmi_receipt({
					"ok": true,
					"status": "pass_receiver_confirmation_stopped_at_d70c",
					"phase": _phase,
					"source_frame": source_frame,
					"source_boundary_before_nmi": source_boundary_before_nmi,
					"renderer_return_bridge": scan_return_bridge.duplicate(true),
					"source_input_result": post_renderer_result.duplicate(true),
					"source_input_adoption": scan_return_adoption.duplicate(true),
					"holder_transfer_executed": false,
					"trace_state_used": false,
					"nmi_cadence_generated": false,
				}, source_boundary_before_nmi, queue_guard_validated)
		var field_entry_enqueue_validated: bool = \
			_scheduler.validate_slot05_field_entry_enqueue_worker_result(slot05_resume_result)
		var scenario35_enqueue_validated: bool = \
			_scheduler.validate_slot05_scenario35_enqueue_worker_result(slot05_resume_result)
		var field_input_loop_yield_validated: bool = \
			_scheduler.validate_slot05_field_input_loop_yield_worker_result(slot05_resume_result)
		if not bool(slot05_resume_result.get("ok", false)) \
				or String(slot05_resume_result.get("exit_kind", "")) != "yield_at_c515" \
				or int(slot05_resume_result.get("exit_pc", -1)) != 0xC515:
			if not field_entry_enqueue_validated and not scenario35_enqueue_validated \
					and not field_input_loop_yield_validated:
				var worker_ram_debug: PackedByteArray = slot05_resume_result.get("ram_image", PackedByteArray())
				var span_names_debug: Array[String] = []
				for span_variant in slot05_resume_result.get("executed_source_spans", []):
					if span_variant is Dictionary:
						span_names_debug.append("%s:%s" % [String(span_variant.get("file", "")),
							String(span_variant.get("sha256", ""))])
				var call_debug: Array[Dictionary] = []
				for call_variant in slot05_resume_result.get("calls", []):
					if call_variant is Dictionary and int(call_variant.get("callsite", -1)) \
							in [0xE0E9, 0xE235, 0xCBBE]:
						call_debug.append(call_variant)
				var write_debug: Array[Dictionary] = []
				for write_variant in slot05_resume_result.get("writes", []):
					if write_variant is Dictionary and int(write_variant.get("pc", -1)) \
							in [0xCBB0, 0xCBB5, 0xCBBA]:
						write_debug.append(write_variant)
				var validation_debug := {
					"worker": {"exit_kind": slot05_resume_result.get("exit_kind", ""),
						"exit_pc": slot05_resume_result.get("exit_pc", -1),
						"manifest_sha256": slot05_resume_result.get("source_manifest_sha256", ""),
						"rom_sha256": slot05_resume_result.get("rom_sha256", ""),
						"manifest": slot05_resume_result.get("source_manifest", ""),
						"blocked_read": slot05_resume_result.get("blocked_read", {}),
						"registers": slot05_resume_result.get("registers", {}),
						"mapper": slot05_resume_result.get("mapper", {}),
						"source_dispatch": slot05_resume_result.get("source_dispatch", {}),
					"scenario35_enqueue_validated": scenario35_enqueue_validated,
						"ram_size": worker_ram_debug.size(),
						"ram_0005_0516_0518_0629": [worker_ram_debug[0x0005],
							worker_ram_debug[0x0516], worker_ram_debug[0x0518], worker_ram_debug[0x0629]] \
							if worker_ram_debug.size() == 0x800 else [],
						"stack_mirror_matches": worker_ram_debug.slice(0x0100, 0x0200) == \
							(slot05_resume_result.get("stack_page", PackedByteArray()) as PackedByteArray)
							if worker_ram_debug.size() == 0x800 else false,
						"spans": span_names_debug, "calls": call_debug, "writes": write_debug},
				}
				return _fail_result("Slot-$05 field-entry worker validation failed: " \
					+ JSON.stringify(validation_debug))
		if not _scheduler.adopt_root_slot05_worker_resume_state(slot05_dispatch, slot05_boundary, slot05_resume_result):
			return _fail_result("Scheduler rejected the source-derived slot-$05 worker result: " + _scheduler.error_message)
		var slot05_result_registers: Dictionary = slot05_resume_result.get("registers", {})
		var slot05_result_mapper: Dictionary = slot05_resume_result.get("mapper", {})
		var worker_yield_callsite := 0x8886
		var worker_caller_stack_pointer := int(slot05_result_registers.get("sp", -1))
		var worker_call_frame_already_pushed := false
		if field_entry_enqueue_validated or scenario35_enqueue_validated:
			worker_yield_callsite = 0xCBBE
			worker_caller_stack_pointer = (worker_caller_stack_pointer + 2) & 0xFF
			worker_call_frame_already_pushed = true
		elif field_input_loop_yield_validated:
			worker_yield_callsite = 0xE40F
			worker_caller_stack_pointer = (worker_caller_stack_pointer + 2) & 0xFF
			worker_call_frame_already_pushed = true
		if not _scheduler.yield_at_verified_callsite(SLOT_05, worker_yield_callsite,
				int(slot05_result_registers.get("a", -1)), worker_caller_stack_pointer,
				int(slot05_result_registers.get("x", -1)), int(slot05_result_registers.get("y", -1)),
				int(slot05_result_mapper.get("bank_low", -1)), int(slot05_result_mapper.get("bank_high", -1)),
				worker_call_frame_already_pushed):
			return _fail_result("Scheduler could not save the source slot-$05 `$%04X->$CB0F` yield: " % worker_yield_callsite + _scheduler.error_message)
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
			if bool(slot09_resume_result.get("ok", false)) \
					and (bool(slot09_resume_result.get("scenario_wait_worker_executed", false)) \
						or bool(slot09_resume_result.get("scenario_route_state_executed", false)) \
						or bool(slot09_resume_result.get("scenario_idle_worker_vector_ready", false))) \
					and not bool(slot09_resume_result.get("scenario_post_callback_executed", false)) \
					and not bool(slot09_resume_result.get("scenario_active", false)):
				if not _scheduler.adopt_slot09_scenario_wait_worker_state(slot09_resume_result):
					return _fail_result("Scheduler rejected the ROM-derived slot-$09 scenario writes before its worker chain: " \
						+ _scheduler.error_message)
			var slot09_resume_ram: Variant = slot09_resume_result.get("ram_image", PackedByteArray())
			var scenario1e_callback_seed: Dictionary = {}
			if bool(slot09_resume_result.get("scenario_active", false)) \
					and slot09_resume_ram is PackedByteArray and slot09_resume_ram.size() == 0x800 \
					and int(slot09_resume_ram[0x0518]) == 0x1E:
				if not _scheduler.adopt_slot09_scenario_active_prefix_state(slot09_resume_result):
					return _fail_result("Scheduler rejected the ROM-derived scenario-$1E prefix before its worker chain: " \
						+ _scheduler.error_message)
				var scenario1e_seed_contract: Dictionary = slot09_resume_result.get("scenario_seed_request", {})
				scenario1e_callback_seed = _scheduler.seed_scenario_callback_task(
					int(scenario1e_seed_contract.get("setup_cpu_address", -1)))
				if not bool(scenario1e_callback_seed.get("ok", false)) \
						or int(scenario1e_callback_seed.get("slot_base", -1)) != SLOT_15 \
						or int(scenario1e_callback_seed.get("callback_reader_pc", -1)) != 0x814C:
					return _fail_result("Scheduler rejected the ROM-derived scenario-$1E slot-$15 callback seed: " \
						+ _scheduler.error_message + " " + str(scenario1e_callback_seed))
			var slot09_worker_result: Dictionary = _slot09_86f8_zero_branch_executor.execute_from_slot09_resume_result(slot09_resume_result)
			if not bool(slot09_worker_result.get("ok", false)) \
					or int(slot09_worker_result.get("exit_pc", -1)) != 0xEBB3:
				return _fail_result("Slot-$09 `$86F8` worker did not reach its supported source return at `$EBB3`: " \
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
			if slot09_resume_ram is PackedByteArray and slot09_resume_ram.size() == 0x800 \
					and int(slot09_resume_ram[0x0518]) in [0x1E, 0x36, 0x38]:
				var scenario_id := int(slot09_resume_ram[0x0518])
				var scenario_workers: Array = [slot09_worker_result,
					slot09_next_worker_result, slot09_third_worker_result]
				if not _scheduler.adopt_slot09_scenario_worker_chain_state(scenario_workers, scenario_id):
					return _fail_result("Scheduler rejected the ROM-derived scenario-$%02X slot-$09 worker chain: " % scenario_id \
						+ _scheduler.error_message)
				if not _scheduler.adopt_slot09_root_loop_entry_state(slot09_root_zero_result):
					return _fail_result("Scheduler rejected the scenario-$%02X root-loop entry: " % scenario_id \
						+ _scheduler.error_message)
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
			if int(post_slot09_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH):
				var initial_selected_slot := int(post_slot09_scan.get("selected_slot_base", -1))
				var initial_selected_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(initial_selected_slot)
				var actor_record: PackedByteArray = initial_selected_boundary.get("record", PackedByteArray())
				if initial_selected_slot != SLOT_11 or initial_selected_boundary.is_empty() \
						or int(initial_selected_boundary.get("active_task_slot", -1)) != -1 \
						or int(initial_selected_boundary.get("phase", -1)) != 1 \
						or int(initial_selected_boundary.get("pending_resume", -1)) != 1 \
						or int(initial_selected_boundary.get("ready_delay", -1)) != 0xFF \
						or int(initial_selected_boundary.get("sp", -1)) != 0xC8 \
						or int(initial_selected_boundary.get("bank_low", -1)) != 0x18 \
						or int(initial_selected_boundary.get("bank_high", -1)) != 0x19 \
						or actor_record.size() != 4 \
						or actor_record.slice(0, 3) != PackedByteArray([0xFF, 0xC8, 0x18]):
					return _fail_result("Post-slot-$09 scan selected an unsupported initial task boundary: %s" % str(initial_selected_boundary))
				_pending_selected_task_slot = initial_selected_slot
				_pending_selected_task_boundary = initial_selected_boundary.duplicate(true)
				_pending_selected_task_mapper.clear()
				_phase = "waiting_for_selected_task_source"
				_last_source_boundary = "$CAA5 selected initial slot $11 after slot-$09 save; before task dispatch"
			elif int(post_slot09_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
				var yielded_selected_slot := int(post_slot09_scan.get("selected_slot_base", -1))
				var yielded_selected_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(yielded_selected_slot)
				if yielded_selected_boundary.is_empty() or int(yielded_selected_boundary.get("active_task_slot", -1)) != -1 \
						or int(yielded_selected_boundary.get("phase", -1)) != 3 \
						or int(yielded_selected_boundary.get("pending_resume", -1)) != 2 \
						or int(yielded_selected_boundary.get("pc", -1)) != 0xCB0F:
					return _fail_result("Post-slot-$09 scan selected no supported yielded-task boundary: %s" % str(yielded_selected_boundary))
				_pending_selected_task_slot = yielded_selected_slot
				_pending_selected_task_boundary = yielded_selected_boundary.duplicate(true)
				_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(yielded_selected_boundary)
				_phase = "waiting_for_selected_task_source"
				_last_source_boundary = "$CAA5 selected slot $%02X after slot-$09 save; before task body" % yielded_selected_slot
			elif int(post_slot09_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
				var queue_state: Dictionary = _scheduler.get_live_nmi_secondary_queue_state()
				if queue_state.is_empty():
					return _fail_result("The post-slot-$09 NMI wait has no source-owned queue signature.")
				_pending_nmi_queue_state = queue_state.duplicate(true)
				_phase = "awaiting_external_nmi"
				_last_source_boundary = "$CB0F save -> scheduler WAIT_FOR_NMI_READY"
			else:
				return _fail_result("Post-save scheduler ended at an unsupported decision: %s" % str(post_slot09_scan))
			next_task_dispatch["post_slot09_scan_results"] = post_slot09_scan_results
			next_task_dispatch["post_slot09_scan"] = post_slot09_scan
		elif int(post_slot05_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
			_phase = "awaiting_external_nmi"
			_last_source_boundary = "$8886->$C515"
		else:
			return _fail_result("Scheduler scan after slot-$05 yield ended without a task or external-NMI wait: %s" % str(post_slot05_scan))
		if _phase == "awaiting_external_nmi":
			_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
			if _pending_nmi_queue_state.is_empty():
				return _fail_result("The route could not capture the post-transition live NMI queue state.")
		else:
			_pending_nmi_queue_state.clear()
		return {
			"ok": true,
			"phase": _phase,
			"rom_sha256": ROM_SHA256,
			"slot05_field_entry_enqueue_validated": field_entry_enqueue_validated,
			"slot05_yield_callsite": worker_yield_callsite,
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
			"slot05_yield_callsite_pc": worker_yield_callsite,
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
	if selected_slot == SLOT_09:
		var slot09_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
		if slot09_boundary.is_empty() or int(slot09_boundary.get("pc", -1)) != 0xCB0F \
				or int(slot09_boundary.get("active_task_slot", -1)) != -1:
			return _fail_result("External NMI selected slot-$09 without a live yielded task boundary.")
		_pending_selected_task_slot = SLOT_09
		_pending_selected_task_boundary = slot09_boundary.duplicate(true)
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(slot09_boundary)
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $09 after scenario44 field-entry yield"
		var slot09_result: Dictionary = resume_selected_slot09_worker()
		if not bool(slot09_result.get("ok", false)):
			return slot09_result
		slot09_result["external_nmi_frame"] = source_frame
		slot09_result["next_task_scan_results"] = scan_results.duplicate(true)
		slot09_result["next_task_scan"] = scan.duplicate(true)
		slot09_result["selected_task_slot"] = selected_slot
		return _attach_external_nmi_receipt(slot09_result, source_boundary_before_nmi,
			queue_guard_validated)
	if selected_slot == SLOT_15:
		var slot15_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_15)
		var slot15_ram_variant: Variant = slot15_boundary.get("ram_image", PackedByteArray())
		var slot15_ram: PackedByteArray = slot15_ram_variant if slot15_ram_variant is PackedByteArray else PackedByteArray()
		var slot15_record: PackedByteArray = slot15_boundary.get("record", PackedByteArray())
		if slot15_boundary.is_empty() or slot15_ram.size() != 0x800 \
				or slot15_record.size() != 4 \
				or int(slot15_boundary.get("pc", -1)) != 0xCB0F \
				or int(slot15_boundary.get("active_task_slot", -1)) != -1 \
				or int(slot15_boundary.get("phase", -1)) != 3 \
				or int(slot15_boundary.get("pending_resume", -1)) != 2 \
				or int(slot15_ram[0x0518]) != 0x2E \
				or int(slot15_ram[0x0524]) != 0x36 \
				or int(slot15_ram[0x05CC]) != 0x2F:
			return _fail_result("External NMI selected slot-$15 outside the source-observed scenario-$2E/callback-$36/map-$2F boundary: %s" % str(slot15_boundary))
		_pending_selected_task_slot = SLOT_15
		_pending_selected_task_boundary = slot15_boundary.duplicate(true)
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(slot15_boundary)
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $15 after scenario-$2E callback-$36 map-$2F NMI; before worker body"
		return _attach_external_nmi_receipt({
			"ok": true,
			"status": "scenario2e_map2f_selected_after_nmi",
			"phase": _phase,
			"rom_sha256": ROM_SHA256,
			"source_boundary_before_nmi": source_boundary_before_nmi,
			"last_source_boundary": _last_source_boundary,
			"selected_task_slot": selected_slot,
			"selected_task_boundary": slot15_boundary.duplicate(true),
			"next_task_scan_results": scan_results.duplicate(true),
			"next_task_scan": scan.duplicate(true),
			"awaiting_external_nmi": false,
			"next_external_nmi_required": false,
			"nmi_cadence_generated": false,
			"trace_state_used": false,
		}, source_boundary_before_nmi, queue_guard_validated)
	return _fail_result("External NMI selected unsupported source task slot $%02X." % selected_slot)


## Continue the fixed-input ROM-stepper RNG schedule after the base receiver
## boundary, checking the current live `$E1-$E3` bytes before each C9C5 result.
func _advance_rng_pass_extension(source_frame: int) -> Dictionary:
	if source_frame <= RNG_RECEIVER_SOURCE_FRAME:
		return {"ok": true, "status": "before_pass_rng_extension"}
	if source_frame > 9600:
		return {"ok": false, "error": "The PASS RNG extension ends at source frame 9600."}
	if _rng_pass_extension == null or _rng_source_replay == null or _scheduler == null:
		return {"ok": false, "error": "The checked base replay, PASS extension, and scheduler are required."}
	var extension_state: Dictionary = _rng_pass_extension.get_state()
	if not bool(extension_state.get("started", false)):
		if not _rng_pass_extension.begin_from_base_replay(_rng_source_replay.get_state()):
			return {"ok": false, "error": _rng_pass_extension.error_message}
	var live_rng: Dictionary = _scheduler.get_live_kickoff_rng_state()
	if live_rng.is_empty():
		return {"ok": false, "error": "The scheduler has no live RNG state for the PASS extension."}
	var scheduler_frame := int(live_rng.get("last_applied_source_frame", -1))
	var extension_frame := int(extension_state.get("last_source_frame", -1))
	if scheduler_frame != extension_frame or scheduler_frame > source_frame:
		return {"ok": false, "error": "Scheduler RNG frame %d and extension frame %d do not agree before source frame %d." % [
			scheduler_frame, extension_frame, source_frame]}
	if scheduler_frame == source_frame:
		return {"ok": true, "status": "rom_only_c9c5_event_already_applied",
			"source_frame": source_frame, "state": extension_state.duplicate(true),
			"trace_state_used": false, "emulator_data_used": false}
	for next_frame in range(scheduler_frame + 1, source_frame + 1):
		live_rng = _scheduler.get_live_kickoff_rng_state()
		if int(live_rng.get("last_applied_source_frame", -1)) != next_frame - 1:
			return {"ok": false, "error": "Scheduler RNG frame %d cannot precede missing C9C5 event %d." % [
				int(live_rng.get("last_applied_source_frame", -1)), next_frame]}
		if not _rng_pass_extension.advance_to_source_frame(next_frame, live_rng):
			return {"ok": false, "error": "Source frame %d: %s" % [next_frame, _rng_pass_extension.error_message]}
		var loop_rng_state: Dictionary = _rng_pass_extension.get_state()
		if not _scheduler.adopt_kickoff_rng_pass_extension_state(loop_rng_state):
			return {"ok": false, "error": _scheduler.error_message}
	var final_rng_state: Dictionary = _rng_pass_extension.get_state()
	return {
		"ok": true,
		"status": "rom_only_c9c5_event_applied",
		"source_frame": source_frame,
		"state": final_rng_state.duplicate(true),
		"trace_state_used": false, "emulator_data_used": false,
	}


## Resume the actual slot-$05 task selected by the live scheduler. Preserve its
## source yield behavior, or adopt the bounded descriptor row and stop before
## the next unsupported text row.
func resume_selected_slot05_worker(controller_sample: Dictionary = {}) -> Dictionary:
	error_message = ""
	var selected_after_root_slot01 := \
		String(_last_source_boundary).contains("$CAA5 selected slot $05 after root slot-$01 yield")
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_05 \
			or (not String(_last_source_boundary).contains("scheduler selected slot $05") \
				and not selected_after_root_slot01):
		return _fail_result("Slot-$05 worker resume requires the live second-NMI scheduler boundary that selected slot `$05`.")
	if _pending_slot05_mapper_select < 0 or _pending_slot05_mapper_select > 0xFF:
		return _fail_result("Slot-$05 worker resume lacks the source-produced MMC3 selector from the live `$E3CA` return.")
	if _fresh_period_result.is_empty():
		return _fail_result("Slot-$05 descriptor tokens require the earlier ROM-produced fresh-period result.")
	var pending_boundary := _pending_selected_task_boundary
	var pre_dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var pending_ram_variant: Variant = pending_boundary.get("ram_image", PackedByteArray())
	var current_ram_variant: Variant = pre_dispatch_boundary.get("ram_image", PackedByteArray())
	var ram_unchanged_except_sampled_controller: bool = pending_ram_variant == current_ram_variant
	if pending_ram_variant is PackedByteArray and current_ram_variant is PackedByteArray \
			and (pending_ram_variant as PackedByteArray).size() == RAM_SIZE \
			and (current_ram_variant as PackedByteArray).size() == RAM_SIZE:
		var current_ram_without_new_sample: PackedByteArray = (current_ram_variant as PackedByteArray).duplicate()
		current_ram_without_new_sample[0x001C] = (pending_ram_variant as PackedByteArray)[0x001C]
		current_ram_without_new_sample[0x001E] = (pending_ram_variant as PackedByteArray)[0x001E]
		ram_unchanged_except_sampled_controller = current_ram_without_new_sample == pending_ram_variant
	var changed_ram_addresses: Array[int] = []
	if pending_ram_variant is PackedByteArray and current_ram_variant is PackedByteArray \
			and (pending_ram_variant as PackedByteArray).size() == RAM_SIZE \
			and (current_ram_variant as PackedByteArray).size() == RAM_SIZE:
		for address in range(RAM_SIZE):
			if (pending_ram_variant as PackedByteArray)[address] != (current_ram_variant as PackedByteArray)[address] \
					and address not in [0x001C, 0x001E]:
				changed_ram_addresses.append(address)
				if changed_ram_addresses.size() >= 12:
					break
	if pre_dispatch_boundary.is_empty() \
			or int(pre_dispatch_boundary.get("slot_base", -1)) != SLOT_05 \
			or int(pre_dispatch_boundary.get("active_task_slot", -1)) != -1 \
			or int(pre_dispatch_boundary.get("pc", -1)) != int(pending_boundary.get("pc", -2)) \
			or int(pre_dispatch_boundary.get("ready_delay", -1)) != int(pending_boundary.get("ready_delay", -2)) \
			or pre_dispatch_boundary.get("record", PackedByteArray()) != pending_boundary.get("record", PackedByteArray()) \
			or not ram_unchanged_except_sampled_controller \
			or pre_dispatch_boundary.get("stack_page", PackedByteArray()) != pending_boundary.get("stack_page", PackedByteArray()):
		return _fail_result("The live slot-$05 scheduler state changed after selection; refusing a stale dispatch: " \
				+ JSON.stringify({"pending_pc": pending_boundary.get("pc", -1),
					"current_pc": pre_dispatch_boundary.get("pc", -1),
					"pending_delay": pending_boundary.get("ready_delay", -1),
					"current_delay": pre_dispatch_boundary.get("ready_delay", -1),
					"pending_record": (pending_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
					"current_record": (pre_dispatch_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
					"ram_diff_other_than_controller": changed_ram_addresses,
					"pending_controller": [int((pending_ram_variant as PackedByteArray)[0x001C]),
						int((pending_ram_variant as PackedByteArray)[0x001E])] if pending_ram_variant is PackedByteArray \
						and (pending_ram_variant as PackedByteArray).size() == RAM_SIZE else [],
					"current_controller": [int((current_ram_variant as PackedByteArray)[0x001C]),
						int((current_ram_variant as PackedByteArray)[0x001E])] if current_ram_variant is PackedByteArray \
						and (current_ram_variant as PackedByteArray).size() == RAM_SIZE else [],
					"controller_only_change": ram_unchanged_except_sampled_controller}))
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_05)
	if OS.get_environment("CT2_TRACE_RNG_FIELD_WORKER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9070 and _last_external_nmi_frame <= 9090:
		var live_rng_debug: Dictionary = _scheduler.get_live_kickoff_rng_state()
		print("RNG_FIELD_DISPATCH frame=%d pc=$%04X sp=$%02X banks=$%02X/$%02X rng=%02X%02X%02X boundary=%s" % [
			_last_external_nmi_frame, int(dispatch.get("pc", -1)), int(dispatch.get("sp", -1)),
			int(dispatch.get("bank_low", -1)), int(dispatch.get("bank_high", -1)),
			int(live_rng_debug.get("e1", -1)), int(live_rng_debug.get("e2", -1)),
			int(live_rng_debug.get("e3", -1)), String(_last_source_boundary)])
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xD80F:
		return _accept_slot05_pass_receiver_input_wait(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05), _last_external_nmi_frame)
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xE089:
		var e081_entry_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var e081_resume_result := _resume_pass_waiter_e081_input_caller(dispatch,
			e081_entry_boundary)
		if OS.get_environment("CT2_TRACE_RNG_FIELD_WORKER").strip_edges() == "1" \
				and _last_external_nmi_frame >= 9070 and _last_external_nmi_frame <= 9090:
			var callee_summaries: Array[Dictionary] = []
			for callee_variant in e081_resume_result.get("pass_waiter_rom_callee_results", []):
				if not callee_variant is Dictionary:
					continue
				var callee: Dictionary = callee_variant
				var rng_writes: Array[Dictionary] = []
				for write_variant in callee.get("writes", []):
					if write_variant is Dictionary and int((write_variant as Dictionary).get("address", -1)) in [0x00E1, 0x00E2, 0x00E3]:
						rng_writes.append((write_variant as Dictionary).duplicate(true))
				callee_summaries.append({"entry_pc": callee.get("entry_pc", -1),
					"exit_pc": callee.get("exit_pc", -1), "status": callee.get("status", ""),
					"executed_source_spans": callee.get("executed_source_spans", []),
					"rng_writes": rng_writes})
			var caller_summaries: Array[Dictionary] = []
			for caller_variant in e081_resume_result.get("pass_waiter_e081_results", []):
				if not caller_variant is Dictionary:
					continue
				var caller: Dictionary = caller_variant
				var gate_reads: Array[Dictionary] = []
				for read_variant in caller.get("source_reads", []):
					if read_variant is Dictionary and int((read_variant as Dictionary).get("address", -1)) in [0x0441, 0x062A]:
						gate_reads.append((read_variant as Dictionary).duplicate(true))
				caller_summaries.append({"entry_pc": caller.get("entry_pc", -1),
					"exit_pc": caller.get("exit_pc", -1), "status": caller.get("status", ""),
					"registers": caller.get("registers", {}),
					"instructions": caller.get("source_instruction_pcs", []),
					"branches": caller.get("source_branches", []), "gate_reads": gate_reads,
					"call": caller.get("call_contract", {})})
			var e081_ram: PackedByteArray = e081_entry_boundary.get("ram_image", PackedByteArray())
			var e081_stack: PackedByteArray = e081_entry_boundary.get("stack_page", PackedByteArray())
			print("RNG_FIELD_E081 frame=%d entry=$%04X A/X/Y/P/SP=%02X/%02X/%02X/%02X/%02X holder=%02X mode=%02X stack=%s status=%s callees=%s callers=%s" % [
				_last_external_nmi_frame, int(e081_entry_boundary.get("pc", -1)),
				int(e081_entry_boundary.get("a", -1)),
				int(e081_entry_boundary.get("x", -1)), int(e081_entry_boundary.get("y", -1)),
				int(e081_entry_boundary.get("p", -1)), int(e081_entry_boundary.get("sp", -1)),
				int(e081_ram[0x0441]) if e081_ram.size() == RAM_SIZE else -1,
				int(e081_ram[0x062A]) if e081_ram.size() == RAM_SIZE else -1,
				e081_stack.slice(0x48, 0x50).hex_encode() if e081_stack.size() == 0x100 else "invalid",
				String(e081_resume_result.get("status", "")), JSON.stringify(callee_summaries),
				JSON.stringify(caller_summaries)])
		return e081_resume_result
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xD7ED:
		return _execute_slot05_pass_receiver_descriptor_0f_first_yield()
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xE945:
		var pass_label_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var pass_label_result: Dictionary = _first_action_pass_label_resume_executor.call(
			"execute_from_scheduler_dispatched_pass_label", dispatch, pass_label_boundary)
		if not bool(pass_label_result.get("ok", false)):
			return _fail_result("ROM-byte PASS label renderer stopped: " \
				+ String(pass_label_result.get("error", _first_action_pass_label_resume_executor.error_message)))
		if String(pass_label_result.get("status", "")) != "pass_action_label_queued":
			return _fail_result("PASS label renderer reached an unsupported source boundary: " \
				+ String(pass_label_result.get("status", "missing status")))
		if not _scheduler.has_method("adopt_first_action_pass_label_renderer_result"):
			return _fail_result("Scheduler has no ROM-write adopter for the live PASS label renderer.")
		var pass_label_adoption: Dictionary = _scheduler.call(
			"adopt_first_action_pass_label_renderer_result", pass_label_result)
		if not bool(pass_label_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected the ROM PASS label renderer: " \
				+ String(pass_label_adoption.get("error", _scheduler.error_message)))
		var returned_boundary: Variant = pass_label_adoption.get("next_boundary_snapshot", {})
		if not returned_boundary is Dictionary or returned_boundary.is_empty() \
				or int(returned_boundary.get("pc", -1)) != 0xD68A \
				or int(returned_boundary.get("active_task_slot", -1)) != SLOT_05:
			return _fail_result("PASS label renderer adoption did not preserve its live `$D68A` continuation.")
		_last_first_action_pass_label_result = pass_label_result.duplicate(true)
		_last_first_action_pass_label_adoption = pass_label_adoption.duplicate(true)
		_last_first_action_pass_label_return_receipt = pass_label_result.duplicate(true)
		_last_first_action_pass_label_return_receipt["callsite_pc"] = 0xD687
		_last_first_action_pass_label_return_receipt["return_pc"] = 0xD68A
		_last_first_action_pass_label_return_receipt["returned_via_rts"] = true
		_last_first_action_pass_label_return_receipt["receipt_id"] = "pass-label-%d" % int(_last_external_nmi_frame)
		_last_first_action_pass_label_return_receipt["entry_boundary"] = pass_label_boundary.duplicate(true)
		_last_first_action_pass_label_return_receipt["returned_boundary"] = returned_boundary.duplicate(true)
		_pending_selected_task_boundary = returned_boundary.duplicate(true)
		_phase = "first_action_pass_label_ready"
		_last_source_boundary = "PASS label renderer returned to live slot-$05 `$D68A`"
		return {"ok": true, "status": "pass_action_label_renderer_returned",
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"source_dispatch": dispatch.duplicate(true),
			"pass_label_result": pass_label_result.duplicate(true),
			"pass_label_adoption": pass_label_adoption.duplicate(true),
			"next_boundary_snapshot": returned_boundary.duplicate(true),
			"ppu_bus_events_applied": false, "trace_state_used": false}
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) in [0xF01B,
			0xF0AB, 0xD5C0, 0xCC53, 0xCCA3, 0xCCD1]:
		var resumed_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if String(resumed_boundary.get("source_label", "")) in [ \
				"ROM-byte scenario-$44 field packet producer yielded at `$F018->$CB0F`", \
				"ROM-byte scenario-$44 field packet producer yielded at `$F0A8->$CB0F`", \
				"ROM-byte scenario-$44 field packet producer yielded at `$D5BD->$CB0F`", \
				"ROM-byte scenario-$44 field packet producer yielded at `$CC50->$CB0F`", \
				"ROM-byte scenario-$44 field packet producer yielded at `$CCA0->$CB0F`", \
				"ROM-byte scenario-$44 field packet producer yielded at `$CCCE->$CB0F`"]:
			return _resume_slot05_scenario44_field_entry(dispatch, resumed_boundary)
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) in [0xCC53, 0xCCA3, 0xCCD1]:
		var pass_waiter_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if String(pass_waiter_boundary.get("source_label", "")).begins_with(
				"ROM-byte PASS confirmation waiter"):
			return _resume_slot05_pass_confirmation_waiter(dispatch, pass_waiter_boundary)
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) in [0xCC53, 0xCCA3, 0xCCD1, 0x82E3]:
		return _resume_slot05_field_minimap_wait(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xCBC1:
		var cbb1_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if String(cbb1_boundary.get("source_label", "")) == "ROM-byte fresh scenario-$36 caller `$DB0E->$CBB0->$CB0F`":
			return _resume_slot05_scenario36_queue_return(dispatch, cbb1_boundary)
		if _is_slot05_scenario1c_handoff_return(dispatch, cbb1_boundary):
			return _resume_slot05_scenario1c_handoff(dispatch, cbb1_boundary)
		return _resume_slot05_scenario35_wait_cycle(dispatch, cbb1_boundary)
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xDAE2:
		return _resume_slot05_scenario35_wait_resume_cycle(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xE778:
		var scenario18_field_update_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if String(scenario18_field_update_boundary.get("source_label", "")).begins_with(
				"ROM-byte PASS scenario-$18 field update"):
			return _resume_slot05_scenario18_field_update(dispatch,
				scenario18_field_update_boundary)
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xD5EA:
		return _finish_first_action_menu_source_entry(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xE14A:
		var field_loop_result := _resume_slot05_field_loop_continuation(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
		_trace_rng_field_worker(_last_external_nmi_frame, "E14A", field_loop_result)
		return field_loop_result
	if bool(dispatch.get("ok", false)) and int(dispatch.get("pc", -1)) == 0xE412:
		var field_input_result := _resume_slot05_field_input_iteration(dispatch,
			_scheduler.get_task_boundary_snapshot(SLOT_05))
		_trace_rng_field_worker(_last_external_nmi_frame, "E412", field_input_result)
		return field_input_result
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19:
		return _fail_result("Actual scheduler dispatch did not restore slot-$05's yielded bank-$18 `$8889` continuation: %s" % str(dispatch))
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
		"source_label": String(boundary.get("source_label", "")),
		"ram_image": boundary.get("ram_image", PackedByteArray()),
		"stack_page": boundary.get("stack_page", PackedByteArray()),
		"test_fixture": false,
		"trace_state_used": false,
	}
	var worker_input_ram: Variant = worker_input.get("ram_image", PackedByteArray())
	var worker_descriptor_pointer := -1
	if worker_input_ram is PackedByteArray and (worker_input_ram as PackedByteArray).size() == RAM_SIZE:
		worker_descriptor_pointer = int((worker_input_ram as PackedByteArray)[0x0050]) \
			| (int((worker_input_ram as PackedByteArray)[0x0051]) << 8)
	if OS.get_environment("CT2_TRACE_RNG_FIELD_WORKER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9068 and _last_external_nmi_frame <= 9090 \
			and worker_input_ram is PackedByteArray \
			and (worker_input_ram as PackedByteArray).size() == RAM_SIZE:
		var gate_ram: PackedByteArray = worker_input_ram
		print("RNG_FIELD_GATE frame=%d pc=$%04X descriptor=$%04X cached_1d=%s row=%02X queue=%02X active=%02X sp=%02X stack=%s" % [
			_last_external_nmi_frame, int(dispatch.get("pc", -1)), worker_descriptor_pointer,
			str(not _last_slot05_pass_receiver_descriptor_1d_first_yield_result.is_empty()),
			int(gate_ram[0x05C5]), int(gate_ram[0x0515]), int(gate_ram[0x0000]),
			int(dispatch.get("sp", -1)),
			(worker_input.get("stack_page", PackedByteArray()) as PackedByteArray).slice(0x40, 0x58).hex_encode()])
	if worker_descriptor_pointer == 0xB6C7 \
			and not _last_slot05_pass_receiver_descriptor_1d_first_yield_result.is_empty():
		return _resume_slot05_pass_receiver_descriptor_1d(dispatch, boundary, worker_input,
			controller_sample)
	# Slot $05 is reused after the PASS receiver worker. Only route the cached
	# descriptor-$0F yield while the live descriptor pointer still identifies
	# its ROM table target; later $B453 match-descriptor work uses the generic
	# source worker even if the earlier PASS result remains cached.
	if worker_descriptor_pointer == 0xB58D \
			and not _last_slot05_pass_receiver_first_yield_result.is_empty():
		var pass_receiver_packet: Dictionary = _worker_prefix.execute_pass_receiver_descriptor_0f_first_packet(
			_last_slot05_pass_receiver_first_yield_result, worker_input)
		var receiver_status := String(pass_receiver_packet.get("status", ""))
		if not bool(pass_receiver_packet.get("ok", false)) \
				or bool(pass_receiver_packet.get("input_boundary_fixture", true)) \
				or not bool(pass_receiver_packet.get("route_boundary_observed", false)) \
				or not bool(pass_receiver_packet.get("source_execution_executed", false)) \
				or int(pass_receiver_packet.get("worker_entry_pc", -1)) != 0x8889:
			return _fail_result("Live PASS descriptor-$0F packet worker did not return its verified ROM source output: " \
				+ String(pass_receiver_packet.get("error", _worker_prefix.error_message)))
		var pass_receiver_worker_variant: Variant = pass_receiver_packet.get("worker_result", {})
		if not pass_receiver_worker_variant is Dictionary:
			return _fail_result("PASS descriptor-$0F packet output omitted its nested ROM worker result.")
		var pass_receiver_worker: Dictionary = pass_receiver_worker_variant
		if receiver_status == "pass_receiver_descriptor_0f_renderer_returned_wait_call_entry":
			var expected_batch_progress: Array[int] = [0, 2, 4, 6, 8]
			if String(pass_receiver_packet.get("worker_exit_kind", "")) != "source_call_boundary" \
					or int(pass_receiver_packet.get("worker_exit_pc", -1)) != 0xCB0F \
					or int(pass_receiver_packet.get("worker_exit_bank", -1)) != 0x1E \
					or not bool(pass_receiver_packet.get("renderer_returned", false)) \
					or not bool(pass_receiver_packet.get("returned_to_D7F2", false)) \
					or _pass_receiver_packet_batch_progress != expected_batch_progress \
					or _pass_receiver_packet_batch_nmi_frames.size() != expected_batch_progress.size() \
					or not bool(pass_receiver_worker.get("ok", false)) \
					or String(pass_receiver_worker.get("exit_kind", "")) != "source_call_boundary" \
					or String(pass_receiver_worker.get("status", "")) != "pass_receiver_wait_source_call_boundary":
				return _fail_result("PASS receiver renderer return lacks the five ROM row batches, five consumed NMI queues, or exact `$D80C->$CB0F` source boundary.")
			var renderer_receipt := {
				"ok": true, "status": "pass_receiver_renderer_return_route_receipt",
				"rom_sha256": ROM_SHA256, "batch_progress": _pass_receiver_packet_batch_progress.duplicate(),
				"nmi_frames": _pass_receiver_packet_batch_nmi_frames.duplicate(),
				"renderer_return": pass_receiver_packet.get("renderer_return_receipt", {}).duplicate(true),
				"trace_state_used": false, "test_fixture": false,
			}
			if not _scheduler.has_method("adopt_slot05_pass_receiver_wait_resume_result") \
					or not bool(_scheduler.call("adopt_slot05_pass_receiver_wait_resume_result",
						dispatch, boundary, pass_receiver_worker, renderer_receipt)):
				return _fail_result("Scheduler rejected the source-derived PASS receiver renderer return: " \
					+ String(_scheduler.error_message))
			var registers: Dictionary = pass_receiver_worker.get("registers", {})
			var mapper: Dictionary = pass_receiver_worker.get("mapper", {})
			var caller_sp := (int(registers.get("sp", -1)) + 2) & 0xFF
			if not _scheduler.yield_at_verified_callsite(SLOT_05, 0xD80C,
					int(registers.get("a", -1)), caller_sp, int(registers.get("x", -1)),
					int(registers.get("y", -1)), int(mapper.get("bank_low", -1)),
					int(mapper.get("bank_high", -1)), true):
				return _fail_result("Scheduler rejected the live `$D80C->$CB0F` receiver wait call: " \
					+ String(_scheduler.error_message))
			var wait_scans: Array[Dictionary] = []
			var wait_scan: Dictionary = {}
			for scan_index in range(8):
				wait_scan = _scheduler.scan_ready_tasks_once()
				if not bool(wait_scan.get("ok", false)):
					return _fail_result("Scheduler scan after the PASS receiver wait yield failed: " + _scheduler.error_message)
				wait_scans.append(wait_scan.duplicate(true))
				if int(wait_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
					break
			if int(wait_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME) \
					and int(wait_scan.get("selected_slot_base", -1)) == SLOT_09:
				_pending_selected_task_slot = SLOT_09
				_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_09)
				_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(
					_pending_selected_task_boundary)
				_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
				if _pending_selected_task_boundary.is_empty() \
						or int(_pending_selected_task_boundary.get("pc", -1)) != 0xCB0F \
						or int(_pending_selected_task_boundary.get("pending_resume", -1)) != 2 \
						or int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) != 0x80 \
						or int(_pending_nmi_queue_state.get("primary_count_0498", -1)) != 0:
					return _fail_result("PASS receiver `$D80C` wait did not preserve its pending PPU queue and selected slot-$09 source boundary.")
				_phase = "waiting_for_selected_task_source"
				_last_source_boundary = "$CAA5 selected slot $09 after PASS receiver renderer wait yield"
				return {"ok": true, "status": "pass_receiver_renderer_return_selected_slot09",
					"phase": _phase, "rom_sha256": ROM_SHA256,
					"renderer_return_receipt": renderer_receipt,
					"worker_result": pass_receiver_worker.duplicate(true),
					"scheduler_scans": wait_scans,
					"next_selected_task_slot": SLOT_09,
					"next_selected_task_boundary": _pending_selected_task_boundary.duplicate(true),
					"next_selected_task_mapper": _pending_selected_task_mapper.duplicate(true),
					"awaiting_external_nmi": false, "next_external_nmi_required": false,
					"nmi_cadence_generated": false, "trace_state_used": false}
			if int(wait_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
				return _fail_result("PASS receiver wait did not settle at a supported source scheduler boundary: %s" % str(wait_scan))
			_pending_selected_task_slot = -1
			_pending_selected_task_boundary.clear()
			_pending_selected_task_mapper.clear()
			_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
			_phase = "awaiting_external_nmi"
			_last_source_boundary = "PASS receiver `$D80C->$CB0F` saved; awaiting source NMI before `$D80F` input poll"
			return {"ok": true, "status": "pass_receiver_renderer_returned_wait_saved",
				"phase": _phase, "rom_sha256": ROM_SHA256,
				"renderer_return_receipt": renderer_receipt,
				"worker_result": pass_receiver_worker.duplicate(true),
				"scheduler_scans": wait_scans,
				"slot05_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
				"awaiting_external_nmi": true, "next_external_nmi_required": true,
				"nmi_cadence_generated": false, "trace_state_used": false}
		if receiver_status != "pass_receiver_descriptor_0f_packet_batch_staged" \
				or String(pass_receiver_packet.get("worker_exit_kind", "")) != "yield_at_c515" \
				or int(pass_receiver_packet.get("worker_exit_pc", -1)) != 0xC515 \
				or int(pass_receiver_packet.get("worker_exit_bank", -1)) != 0x1E \
				or int(pass_receiver_packet.get("packet_count", -1)) != 2 \
				or not bool(pass_receiver_packet.get("packet_queue_staged", false)) \
				or bool(pass_receiver_packet.get("nmi_executed", true)) \
				or bool(pass_receiver_packet.get("ppu_packet_applied", true)):
			return _fail_result("Unexpected PASS receiver packet result status: " + receiver_status)
		if not bool(pass_receiver_worker.get("ok", false)) \
				or String(pass_receiver_worker.get("exit_kind", "")) != "yield_at_c515" \
				or int(pass_receiver_worker.get("exit_pc", -1)) != 0xC515 \
				or String(pass_receiver_worker.get("rom_sha256", "")) != ROM_SHA256:
			return _fail_result("Nested PASS descriptor-$0F worker result is not a successful pinned-ROM `$C515` yield.")
		var expected_progress := _pass_receiver_packet_batch_progress.size() * 2
		if int(pass_receiver_packet.get("menu_row_progress_before", -1)) != expected_progress \
				or _pass_receiver_packet_batch_progress.size() >= 5:
			return _fail_result("PASS receiver source rows are not advancing through the expected ROM order.")
		_pass_receiver_packet_batch_progress.append(int(pass_receiver_packet.get("menu_row_progress_before", -1)))
		if not _scheduler.adopt_root_slot05_worker_resume_state(dispatch, boundary,
				pass_receiver_worker):
			return _fail_result("Scheduler rejected the ROM-derived PASS descriptor-$0F packet worker: " \
				+ _scheduler.error_message)
		var pass_receiver_packet_yield: Dictionary = _yield_slot05_field_worker_callsite(
			pass_receiver_worker, "PASS receiver descriptor-$0F first packet worker")
		if not bool(pass_receiver_packet_yield.get("ok", false)):
			return pass_receiver_packet_yield
		pass_receiver_packet_yield["status"] = "pass_receiver_descriptor_0f_first_packet_saved"
		pass_receiver_packet_yield["pass_receiver_packet_result"] = pass_receiver_packet.duplicate(true)
		pass_receiver_packet_yield["pass_receiver_worker_result"] = pass_receiver_worker.duplicate(true)
		pass_receiver_packet_yield["renderer_returned"] = false
		pass_receiver_packet_yield["ppu_bus_events_applied"] = false
		pass_receiver_packet_yield["nmi_cadence_generated"] = false
		return pass_receiver_packet_yield
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
	_capture_verified_stamina_update(boundary, worker_result)
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
	var field_entry_enqueue_validation: bool = _scheduler.validate_slot05_field_entry_enqueue_worker_result(worker_result)
	var field_loop_yield_validation: bool = _scheduler.validate_slot05_field_loop_yield_worker_result(worker_result)
	var field_input_loop_yield_validation: bool = _scheduler.validate_slot05_field_input_loop_yield_worker_result(worker_result)
	var action_menu_wait_yield_validation: bool = \
			_scheduler.validate_slot05_action_menu_wait_worker_result(worker_result)
	if not bool(worker_result.get("ok", false)) \
			and not accepted_unresolved_c509 and not accepted_f0_token_boundary \
			and not accepted_f0_division_opcode_boundary and not accepted_ed_row00_boundary \
			and not scenario35_enqueue_validation and not field_entry_enqueue_validation \
			and not field_loop_yield_validation and not field_input_loop_yield_validation \
			and not action_menu_wait_yield_validation:
		return _stop_slot05_before_worker(dispatch, boundary, worker_input,
			String(worker_result.get("exit_kind", "unsupported_worker_state")),
			str(worker_result.get("error", worker_result.get("blocked_read", _worker_prefix.error_message))),
			descriptor_contract, worker_descriptor_contract, worker_result)
	if not _scheduler.adopt_root_slot05_worker_resume_state(dispatch, boundary, worker_result,
			descriptor_contract, worker_descriptor_contract):
		return _fail_result("Scheduler rejected slot-$05 source writes: " + _scheduler.error_message)
	if action_menu_wait_yield_validation:
		_last_slot05_action_menu_wait_result = worker_result.duplicate(true)
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
	if scenario35_enqueue_validation or field_entry_enqueue_validation:
		yield_callsite_pc = 0xCBBE
		caller_stack_pointer = (caller_stack_pointer + 2) & 0xFF
		call_frame_already_pushed = true
	elif field_loop_yield_validation:
		yield_callsite_pc = 0xE147
		caller_stack_pointer = (caller_stack_pointer + 2) & 0xFF
		call_frame_already_pushed = true
	elif field_input_loop_yield_validation:
		yield_callsite_pc = 0xE40F
		caller_stack_pointer = (caller_stack_pointer + 2) & 0xFF
		call_frame_already_pushed = true
	elif action_menu_wait_yield_validation:
		yield_callsite_pc = 0xD5E7
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
		_last_source_boundary = "slot-$05 field-input loop saved at `$CB0F`; scheduler WAIT_FOR_NMI_READY" \
				if field_input_loop_yield_validation else "slot-$05 saved at `$CB0F`; scheduler WAIT_FOR_NMI_READY"
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
	if field_entry_enqueue_validation:
		result["slot05_field_entry_enqueue_validated"] = true
		result["slot05_field_entry_queue_bytes"] = PackedByteArray([0x80, 0x80, 0x00, 0x1E])
		result["slot05_cb0f_callsite_pc"] = yield_callsite_pc
	if field_loop_yield_validation:
		result["slot05_field_loop_yield_validated"] = true
		result["slot05_cb0f_callsite_pc"] = yield_callsite_pc
	if field_input_loop_yield_validation:
		result["slot05_field_input_loop_yield_validated"] = true
		result["slot05_cb0f_callsite_pc"] = yield_callsite_pc
	return result


func _resume_slot05_pass_receiver_descriptor_1d(dispatch: Dictionary,
		boundary: Dictionary, worker_input: Dictionary,
		controller_sample: Dictionary) -> Dictionary:
	var candidates_variant: Variant = _last_pass_receiver_descriptor_1d_batch.get(
		"all_packet_candidates", [])
	if not candidates_variant is Array or (candidates_variant as Array).size() != 11 \
			or _last_slot05_pass_receiver_descriptor_1d_first_yield_result.is_empty():
		return _fail_result("Live `$C7B6` slot-$05 dispatch has no retained ROM-derived descriptor-$1D first-yield result or 11 row candidates.")
	var pass_receiver_packet: Dictionary = _worker_prefix.execute_pass_receiver_descriptor_1d_packet_batch(
		_last_slot05_pass_receiver_descriptor_1d_first_yield_result, worker_input,
		candidates_variant as Array)
	if OS.get_environment("CT2_TRACE_RNG_FIELD_WORKER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9068 and _last_external_nmi_frame <= 9090:
		var raw_worker: Dictionary = pass_receiver_packet.get("worker_result", {})
		var raw_pcs: Array[int] = []
		for instruction_variant in raw_worker.get("instructions", []):
			if instruction_variant is Dictionary:
				raw_pcs.append(int((instruction_variant as Dictionary).get("pc", -1)))
		var raw_ram: Variant = raw_worker.get("ram_image", PackedByteArray())
		var first_ram: Variant = worker_input.get("ram_image", PackedByteArray())
		var raw_regs: Dictionary = raw_worker.get("registers", {})
		print("RNG_FIELD_1D_RAW frame=%d ok=%s status=%s error=%s exit=$%04X/%s progress=%s->%s packets=%s candidate_count=%d regs=%s ram_progress=%s ram_queue=%s pc_tail=%s calls=%s" % [
			_last_external_nmi_frame, str(bool(pass_receiver_packet.get("ok", false))),
			String(pass_receiver_packet.get("status", "")),
			String(pass_receiver_packet.get("error", "")),
			int(raw_worker.get("exit_pc", pass_receiver_packet.get("worker_exit_pc", -1))),
			String(raw_worker.get("exit_kind", pass_receiver_packet.get("worker_exit_kind", ""))),
			str(pass_receiver_packet.get("menu_row_progress_before", -1)),
			str(pass_receiver_packet.get("menu_row_progress_after", -1)),
			str(pass_receiver_packet.get("packet_count", -1)),
			(candidates_variant as Array).size() if candidates_variant is Array else -1,
			JSON.stringify(raw_regs),
			str([int((first_ram as PackedByteArray)[0x05C5]), int((raw_ram as PackedByteArray)[0x05C5])]) \
				if first_ram is PackedByteArray and (first_ram as PackedByteArray).size() == RAM_SIZE \
				and raw_ram is PackedByteArray and (raw_ram as PackedByteArray).size() == RAM_SIZE else "invalid",
			(raw_ram as PackedByteArray).slice(0x0515, 0x0519).hex_encode() \
				if raw_ram is PackedByteArray and (raw_ram as PackedByteArray).size() == RAM_SIZE else "invalid",
			raw_pcs.slice(maxi(0, raw_pcs.size() - 24), raw_pcs.size()),
			JSON.stringify(raw_worker.get("calls", []))])
	if not bool(pass_receiver_packet.get("ok", false)):
		var partial_worker_variant: Variant = pass_receiver_packet.get("worker_result", {})
		if partial_worker_variant is Dictionary \
				and String((partial_worker_variant as Dictionary).get("exit_kind", "")) \
				== "unresolved_source_span" \
				and int((partial_worker_variant as Dictionary).get("exit_pc", -1)) == 0xD96F:
			return _resume_slot05_pass_receiver_scan_return(dispatch, boundary,
				partial_worker_variant as Dictionary, controller_sample)
	var receiver_status := String(pass_receiver_packet.get("status", ""))
	if not bool(pass_receiver_packet.get("ok", false)) \
			or bool(pass_receiver_packet.get("input_boundary_fixture", true)) \
			or not bool(pass_receiver_packet.get("route_boundary_observed", false)) \
			or not bool(pass_receiver_packet.get("source_execution_executed", false)) \
			or int(pass_receiver_packet.get("worker_entry_pc", -1)) != 0x8889 \
			or int(pass_receiver_packet.get("descriptor_pointer", -1)) != 0xB6C7:
		return _fail_result("Live PASS descriptor-$1D packet worker did not return its verified ROM source output: " \
				+ String(pass_receiver_packet.get("error", _worker_prefix.error_message)))
	var pass_receiver_worker_variant: Variant = pass_receiver_packet.get("worker_result", {})
	if not pass_receiver_worker_variant is Dictionary:
		return _fail_result("PASS descriptor-$1D packet output omitted its nested ROM worker result.")
	var pass_receiver_worker: Dictionary = pass_receiver_worker_variant
	if OS.get_environment("CT2_TRACE_RNG_FIELD_WORKER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9068 and _last_external_nmi_frame <= 9088:
		print("RNG_FIELD_DESC1D frame=%d status=%s worker_exit=$%04X/%s progress=%s->%s packets=%s queue=%s pcs=%s branches=%s" % [
			_last_external_nmi_frame, receiver_status,
			int(pass_receiver_packet.get("worker_exit_pc", -1)),
			String(pass_receiver_packet.get("worker_exit_kind", "")),
			str(pass_receiver_packet.get("menu_row_progress_before", -1)),
			str(pass_receiver_packet.get("menu_row_progress_after", -1)),
			str(pass_receiver_packet.get("packet_count", -1)),
			str(pass_receiver_packet.get("queue_control_0515", -1)),
			str(pass_receiver_worker.get("instruction_tail", [])),
			str(pass_receiver_worker.get("branch_trace", pass_receiver_worker.get("branches", [])))])
	if receiver_status == "pass_receiver_descriptor_1d_queue_wait_yield":
		if String(pass_receiver_packet.get("worker_exit_kind", "")) != "yield_at_c515" \
				or int(pass_receiver_packet.get("worker_exit_pc", -1)) != 0xC515 \
				or int(pass_receiver_packet.get("worker_exit_bank", -1)) != 0x1E \
				or int(pass_receiver_packet.get("packet_count", -1)) != 0 \
				or int(pass_receiver_packet.get("menu_row_progress_before", -1)) \
				!= int(pass_receiver_packet.get("menu_row_progress_after", -2)) \
				or int(pass_receiver_packet.get("queue_control_0515", -1)) != 0x80 \
				or bool(pass_receiver_packet.get("ppu_packet_applied", true)):
			return _fail_result("PASS descriptor-$1D queue wait lacks its ROM `$8886->$C515` pending-queue signature.")
		if not bool(pass_receiver_worker.get("ok", false)) \
				or String(pass_receiver_worker.get("exit_kind", "")) != "yield_at_c515" \
				or int(pass_receiver_worker.get("exit_pc", -1)) != 0xC515 \
				or String(pass_receiver_worker.get("rom_sha256", "")) != ROM_SHA256:
			return _fail_result("PASS descriptor-$1D queue wait omitted its successful ROM worker wait boundary.")
		if not _scheduler.adopt_root_slot05_worker_resume_state(dispatch, boundary,
				pass_receiver_worker):
			return _fail_result("Scheduler rejected the source PASS descriptor-$1D pending-queue wait: " \
				+ String(_scheduler.error_message))
		var wait_yield := _yield_slot05_field_worker_callsite(
			pass_receiver_worker, "PASS descriptor-$1D pending PPU queue wait")
		if not bool(wait_yield.get("ok", false)):
			return wait_yield
		wait_yield["status"] = "pass_receiver_descriptor_1d_queue_wait_saved"
		wait_yield["pass_receiver_wait_result"] = pass_receiver_packet.duplicate(true)
		wait_yield["renderer_returned"] = false
		wait_yield["ppu_bus_events_applied"] = false
		wait_yield["nmi_cadence_generated"] = false
		return wait_yield
	if receiver_status == "pass_receiver_descriptor_1d_renderer_returned_wait_call_entry":
		var expected_batch_progress: Array[int] = [0, 2, 4, 6, 8]
		if String(pass_receiver_packet.get("worker_exit_kind", "")) != "source_call_boundary" \
				or int(pass_receiver_packet.get("worker_exit_pc", -1)) != 0xCB0F \
				or int(pass_receiver_packet.get("worker_exit_bank", -1)) != 0x1E \
				or not bool(pass_receiver_packet.get("renderer_returned", false)) \
				or not bool(pass_receiver_packet.get("returned_to_D7F2", false)) \
				or int(pass_receiver_packet.get("menu_row_progress_before", -1)) != 10 \
				or int(pass_receiver_packet.get("menu_row_progress_after", -1)) != 11 \
				or int(pass_receiver_packet.get("packet_count", -1)) != 1 \
				or _pass_receiver_descriptor_1d_batch_progress != expected_batch_progress \
				or _pass_receiver_descriptor_1d_batch_nmi_frames.size() != expected_batch_progress.size() \
				or not bool(pass_receiver_worker.get("ok", false)) \
				or String(pass_receiver_worker.get("exit_kind", "")) != "source_call_boundary" \
				or String(pass_receiver_worker.get("status", "")) != "pass_receiver_wait_source_call_boundary":
			return _fail_result("PASS descriptor-$1D renderer return lacks its five consumed two-row queues, final row-10 packet, or `$D80C->$CB0F` source boundary.")
		var renderer_receipt := {
			"ok": true, "status": "pass_receiver_descriptor_1d_renderer_return_route_receipt",
			"descriptor_id": 0x1D, "rom_sha256": ROM_SHA256,
			"batch_progress": _pass_receiver_descriptor_1d_batch_progress.duplicate(),
			"progress_sequence": [0, 2, 4, 6, 8, 10],
			"nmi_frames": _pass_receiver_descriptor_1d_batch_nmi_frames.duplicate(),
			"final_worker_status": receiver_status,
			"renderer_return": pass_receiver_packet.get("renderer_return_receipt", {}).duplicate(true),
			"trace_state_used": false, "test_fixture": false,
		}
		if not _scheduler.has_method("adopt_slot05_pass_receiver_descriptor_1d_wait_resume_result") \
				or not bool(_scheduler.call("adopt_slot05_pass_receiver_descriptor_1d_wait_resume_result",
					dispatch, boundary, pass_receiver_packet, renderer_receipt)):
			return _fail_result("Scheduler rejected the ROM-derived descriptor-$1D renderer return: " \
					+ String(_scheduler.error_message))
		var registers: Dictionary = pass_receiver_worker.get("registers", {})
		var mapper: Dictionary = pass_receiver_worker.get("mapper", {})
		var caller_sp := (int(registers.get("sp", -1)) + 2) & 0xFF
		if not _scheduler.yield_at_verified_callsite(SLOT_05, 0xD80C,
				int(registers.get("a", -1)), caller_sp, int(registers.get("x", -1)),
				int(registers.get("y", -1)), int(mapper.get("bank_low", -1)),
				int(mapper.get("bank_high", -1)), true):
			return _fail_result("Scheduler rejected the live descriptor-$1D `$D80C->$CB0F` receiver wait call: " \
					+ String(_scheduler.error_message))
		_pass_receiver_descriptor_1d_final_queue_pending = true
		_pass_receiver_descriptor_1d_input_poll_pending = true
		_last_slot05_pass_receiver_descriptor_1d_first_yield_result.clear()
		var wait_scans: Array[Dictionary] = []
		var wait_scan: Dictionary = {}
		for scan_index in range(8):
			wait_scan = _scheduler.scan_ready_tasks_once()
			if not bool(wait_scan.get("ok", false)):
				return _fail_result("Scheduler scan after the descriptor-$1D receiver wait yield failed: " + _scheduler.error_message)
			wait_scans.append(wait_scan.duplicate(true))
			if int(wait_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
				break
		if int(wait_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME) \
					and int(wait_scan.get("selected_slot_base", -1)) == SLOT_09:
			_pending_selected_task_slot = SLOT_09
			_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_09)
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(
				_pending_selected_task_boundary)
			_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
			if _pending_selected_task_boundary.is_empty() \
					or int(_pending_selected_task_boundary.get("pc", -1)) != 0xCB0F \
					or int(_pending_selected_task_boundary.get("pending_resume", -1)) != 2 \
					or int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) != 0x80 \
					or int(_pending_nmi_queue_state.get("primary_count_0498", -1)) != 0:
				return _fail_result("Descriptor-$1D receiver wait did not preserve its pending PPU queue and selected slot-$09 boundary.")
			_phase = "waiting_for_selected_task_source"
			_last_source_boundary = "$CAA5 selected slot $09 after descriptor-$1D renderer wait yield"
			return {"ok": true, "status": "pass_receiver_descriptor_1d_renderer_return_selected_slot09",
				"phase": _phase, "rom_sha256": ROM_SHA256,
				"renderer_return_receipt": renderer_receipt,
				"worker_result": pass_receiver_worker.duplicate(true),
				"scheduler_scans": wait_scans,
				"next_selected_task_slot": SLOT_09,
				"next_selected_task_boundary": _pending_selected_task_boundary.duplicate(true),
				"next_selected_task_mapper": _pending_selected_task_mapper.duplicate(true),
				"awaiting_external_nmi": false, "next_external_nmi_required": false,
				"nmi_cadence_generated": false, "trace_state_used": false}
		if int(wait_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
			return _fail_result("Descriptor-$1D receiver wait did not settle at a supported scheduler boundary: %s" % str(wait_scan))
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "descriptor-$1D `$D80C->$CB0F` saved; awaiting NMI before `$D80F` input poll"
		return {"ok": true, "status": "pass_receiver_descriptor_1d_renderer_returned_wait_saved",
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"renderer_return_receipt": renderer_receipt,
			"worker_result": pass_receiver_worker.duplicate(true),
			"scheduler_scans": wait_scans,
			"slot05_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
			"awaiting_external_nmi": true, "next_external_nmi_required": true,
			"nmi_cadence_generated": false, "trace_state_used": false}
	if receiver_status != "pass_receiver_descriptor_1d_packet_batch_staged" \
			or String(pass_receiver_packet.get("worker_exit_kind", "")) != "yield_at_c515" \
			or int(pass_receiver_packet.get("worker_exit_pc", -1)) != 0xC515 \
			or int(pass_receiver_packet.get("worker_exit_bank", -1)) != 0x1E \
			or int(pass_receiver_packet.get("packet_count", -1)) != 2 \
			or not bool(pass_receiver_packet.get("packet_queue_staged", false)) \
			or bool(pass_receiver_packet.get("nmi_executed", true)) \
			or bool(pass_receiver_packet.get("ppu_packet_applied", true)):
		return _fail_result("Unexpected descriptor-$1D packet result status: " + receiver_status)
	if not bool(pass_receiver_worker.get("ok", false)) \
			or String(pass_receiver_worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(pass_receiver_worker.get("exit_pc", -1)) != 0xC515 \
			or String(pass_receiver_worker.get("rom_sha256", "")) != ROM_SHA256:
		return _fail_result("Nested PASS descriptor-$1D worker result is not a successful pinned-ROM `$C515` yield.")
	var expected_progress := _pass_receiver_descriptor_1d_batch_progress.size() * 2
	if int(pass_receiver_packet.get("menu_row_progress_before", -1)) != expected_progress \
			or int(pass_receiver_packet.get("menu_row_progress_after", -1)) != expected_progress + 2 \
			or _pass_receiver_descriptor_1d_batch_progress.size() >= 5:
		return _fail_result("PASS descriptor-$1D rows are not advancing through the expected ROM order.")
	if not _scheduler.adopt_root_slot05_worker_resume_state(dispatch, boundary,
			pass_receiver_worker):
		return _fail_result("Scheduler rejected the ROM-derived PASS descriptor-$1D packet worker: " \
				+ String(_scheduler.error_message))
	_pass_receiver_descriptor_1d_batch_progress.append(
		int(pass_receiver_packet.get("menu_row_progress_before", -1)))
	var pass_receiver_packet_yield: Dictionary = _yield_slot05_field_worker_callsite(
		pass_receiver_worker, "PASS receiver descriptor-$1D packet worker")
	if not bool(pass_receiver_packet_yield.get("ok", false)):
		return pass_receiver_packet_yield
	pass_receiver_packet_yield["status"] = "pass_receiver_descriptor_1d_packet_batch_saved"
	pass_receiver_packet_yield["pass_receiver_packet_result"] = pass_receiver_packet.duplicate(true)
	pass_receiver_packet_yield["pass_receiver_worker_result"] = pass_receiver_worker.duplicate(true)
	pass_receiver_packet_yield["renderer_returned"] = false
	pass_receiver_packet_yield["ppu_bus_events_applied"] = false
	pass_receiver_packet_yield["nmi_cadence_generated"] = false
	return pass_receiver_packet_yield


func _resume_slot05_pass_receiver_scan_return(dispatch: Dictionary, boundary: Dictionary,
		worker_result: Dictionary, controller_sample: Dictionary) -> Dictionary:
	var bridge: Dictionary = _worker_prefix.execute_pass_receiver_scan_return_bridge(worker_result)
	if not bool(bridge.get("ok", false)):
		return _fail_result("ROM-byte PASS receiver `$D96F->$D837` bridge stopped: " \
			+ String(bridge.get("error", _worker_prefix.error_message)))
	var next_boundary_variant: Variant = bridge.get("next_boundary_snapshot", {})
	if not next_boundary_variant is Dictionary:
		return _fail_result("PASS receiver `$D96F` bridge omitted the `$D837` boundary.")
	var source_boundary: Dictionary = (next_boundary_variant as Dictionary).duplicate(true)
	var sample := controller_sample.duplicate(true)
	if sample.is_empty():
		sample = _scheduler.get_status().get("controller_sample", {}).duplicate(true)
	var sample_frame := int(sample.get("source_frame_label", _last_external_nmi_frame))
	source_boundary["source_frame_label"] = sample_frame
	source_boundary["emulator_data_used"] = false
	source_boundary["polled_controller"] = {
		"direction_mask": int(sample.get("held_ram_001c", -1)),
		"button_mask": int(sample.get("edge_ram_001e", -1)),
	}
	var continuation: Dictionary = _pass_receiver_input_executor.execute_after_receiver_renderer_return(
		source_boundary)
	if not bool(continuation.get("ok", false)):
		return _fail_result("ROM-byte PASS receiver caller stopped after `$D96F->$D837`: " \
			+ String(continuation.get("error", _pass_receiver_input_executor.error_message)) \
			+ " sample=" + JSON.stringify({"frame": sample_frame,
				"held": sample.get("held_ram_001c", -1),
				"edge": sample.get("edge_ram_001e", -1),
				"id": sample.get("sample_receipt_id", -1)}))
	continuation["source_frame_label"] = sample_frame
	continuation["sample_receipt_id"] = int(sample.get("sample_receipt_id", -1))
	continuation["input_sample_receipt"] = sample.duplicate(true)
	var adoption: Dictionary = _scheduler.adopt_slot05_pass_receiver_scan_return_result(
		dispatch, boundary, worker_result, bridge, continuation, sample)
	if not bool(adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the live PASS scan-return/A continuation: " \
			+ String(adoption.get("error", _scheduler.error_message)))
	_last_pass_receiver_input_result = continuation.duplicate(true)
	_last_pass_receiver_input_adoption = adoption.duplicate(true)
	_pass_receiver_confirmation_input_pending = false
	_phase = "pass_receiver_confirmed_at_d70c"
	_last_source_boundary = "ROM PASS receiver A continued from `$D96F->$D837->$D70C`"
	return {"ok": true, "status": "pass_receiver_confirmation_stopped_at_d70c",
		"phase": _phase, "rom_sha256": ROM_SHA256,
		"source_frame": sample_frame, "renderer_return_bridge": bridge.duplicate(true),
		"source_input_result": continuation.duplicate(true),
		"source_input_adoption": adoption.duplicate(true),
		"holder_transfer_executed": false, "trace_state_used": false,
		"nmi_cadence_generated": false}


func _resume_slot05_field_loop_continuation(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var worker_input := {
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": SLOT_05,
			"resume_path": "yielded_rts", "pc": 0xE14A, "bank": 0x1F,
			"source_dispatch_observed": true},
		"registers": {"a": int(dispatch.get("a", -1)),
			"x": int(dispatch.get("x", -1)), "y": int(dispatch.get("y", -1)),
			"p": int(boundary.get("p", -1)),
			"p_known_mask": int(boundary.get("p_known_mask", -1)),
			"sp": int(dispatch.get("sp", -1)), "pc": 0xE14A},
		"mapper": {"bank_low": int(dispatch.get("bank_low", -1)),
			"bank_high": int(dispatch.get("bank_high", -1)),
			"select": _pending_slot05_mapper_select},
		"ram_image": boundary.get("ram_image", PackedByteArray()),
		"stack_page": boundary.get("stack_page", PackedByteArray()),
	}
	var worker_result: Dictionary = _worker_prefix.resume_dispatched_slot05_field_loop(worker_input)
	var field_loop_result: Dictionary = worker_result
	var clock_tick_handoff := false
	var yield_callsite_pc := 0xE147
	var scenario44_enqueue_valid: bool = \
		_scheduler.validate_slot05_field_scenario44_enqueue_worker_result(worker_result, boundary)
	var neutral_loop_valid: bool = scenario44_enqueue_valid \
		or _scheduler.validate_slot05_field_loop_continuation_worker_result(worker_result, boundary)
	if not neutral_loop_valid:
		var blocked_read: Dictionary = worker_result.get("blocked_read", {})
		var is_live_d193_boundary := String(worker_result.get("exit_kind", "")) == "unresolved_source_span" \
			and int(worker_result.get("exit_pc", -1)) == 0xD193 \
			and int(blocked_read.get("requested_address", -1)) == 0xD193 \
			and int(blocked_read.get("bank", -1)) == 0x1E \
			and String(worker_result.get("source_executor_handoff", "")) == "rom_clock_tick_d193_worker"
		if is_live_d193_boundary:
			var clock_tick_result: Dictionary = _clock_tick_d193_worker.execute_live_boundary(worker_result)
			if not bool(clock_tick_result.get("ok", false)):
				var d193_failure := _fail_result("ROM-byte `$D193->$EF7F` clock renderer handoff stopped: " \
					+ String(clock_tick_result.get("error", _clock_tick_d193_worker.error_message)))
				d193_failure["status"] = "slot05_clock_tick_handoff_rejected"
				d193_failure["slot05_dispatch"] = dispatch.duplicate(true)
				d193_failure["slot05_live_boundary"] = boundary.duplicate(true)
				d193_failure["slot05_worker_input"] = worker_input.duplicate(true)
				d193_failure["slot05_worker_result"] = worker_result.duplicate(true)
				d193_failure["slot05_clock_tick_result"] = clock_tick_result.duplicate(true)
				return d193_failure
			_last_d193_clock_tick_handoff_result = clock_tick_result.duplicate(true)
			var live_e14a_boundary := boundary.duplicate(true)
			live_e14a_boundary["registers"] = worker_input.get("registers", {}).duplicate(true)
			live_e14a_boundary["mapper"] = worker_input.get("mapper", {}).duplicate(true)
			if not _scheduler.adopt_slot05_clock_tick_renderer_handoff(dispatch,
					live_e14a_boundary, clock_tick_result):
				return _fail_result("Scheduler rejected the source `$D193->$EF7F` async renderer handoff: " \
					+ _scheduler.error_message)
			field_loop_result = clock_tick_result
			var handoff: Dictionary = clock_tick_result.get("handoff", {})
			yield_callsite_pc = int(handoff.get("yield_jsr_callsite", -1))
			if yield_callsite_pc < 0:
				return _fail_result("The ROM-derived `$EF7F` result omitted its `$C515` caller PC.")
			clock_tick_handoff = true
		else:
				var failed_ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
				var executed_pcs: Array[int] = []
				for instruction_variant in worker_result.get("instructions", []):
					if instruction_variant is Dictionary:
						executed_pcs.append(int(instruction_variant.get("pc", -1)))
				var source_spans: Array[String] = []
				for span_variant in worker_result.get("executed_source_spans", []):
					if span_variant is Dictionary:
						source_spans.append("%s:%s" % [String(span_variant.get("file", "")),
							String(span_variant.get("sha256", ""))])
				var details := {"exit": worker_result.get("exit_kind", ""),
					"pc": worker_result.get("exit_pc", -1),
					"manifest": worker_result.get("source_manifest_sha256", ""),
					"blocked": worker_result.get("blocked_read", {}),
					"registers": worker_result.get("registers", {}),
					"mapper": worker_result.get("mapper", {}),
					"ram": {"0614": int(failed_ram[0x0614]), "0532": int(failed_ram[0x0532]),
						"0615": int(failed_ram[0x0615]), "001C": int(failed_ram[0x001C])} \
						if failed_ram.size() == 0x800 else {},
					"return_word": failed_ram.slice(0x014F, 0x0151).hex_encode() \
						if failed_ram.size() == 0x800 else "",
					"spans": source_spans, "calls": worker_result.get("calls", []),
					"pcs": executed_pcs}
				var rejected_result := _fail_result("ROM-byte slot-$05 field continuation did not satisfy its source, RAM, and stack contract: " \
						+ str(details))
				rejected_result["status"] = "slot05_field_loop_stopped_at_unaccepted_source_boundary"
				rejected_result["slot05_dispatch"] = dispatch.duplicate(true)
				rejected_result["slot05_live_boundary"] = boundary.duplicate(true)
				rejected_result["slot05_worker_input"] = worker_input.duplicate(true)
				rejected_result["slot05_worker_result"] = worker_result.duplicate(true)
				return rejected_result
	if scenario44_enqueue_valid:
		yield_callsite_pc = 0xCBBE
	if not clock_tick_handoff and not _scheduler.adopt_root_slot05_worker_resume_state(
			dispatch, boundary, field_loop_result):
		return _fail_result("Scheduler rejected the source-produced slot-$05 field-loop continuation: " + _scheduler.error_message)
	var registers: Dictionary = field_loop_result.get("registers", {})
	var mapper: Dictionary = field_loop_result.get("mapper", {})
	var caller_sp := (int(registers.get("sp", -1)) + 2) & 0xFF
	if not _scheduler.yield_at_verified_callsite(SLOT_05, yield_callsite_pc,
			int(registers.get("a", -1)), caller_sp,
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)), true):
		return _fail_result("Scheduler rejected the ROM-produced `$%04X->$CB0F` stack frame: " % yield_callsite_pc + _scheduler.error_message)
	var saved_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after the field-loop save failed: " + _scheduler.error_message)
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
		if clock_tick_handoff:
			_last_source_boundary = "slot-$05 clock tick saved after `$D193->$EF7F->$CB0F`; scheduler WAIT_FOR_NMI_READY"
		elif scenario44_enqueue_valid:
			_last_source_boundary = "slot-$05 scenario-$44 field transition saved at `$CBBE->$CB0F`; scheduler WAIT_FOR_NMI_READY"
		else:
			_last_source_boundary = "slot-$05 saved after source `$E14A->$E349->$E147`; scheduler WAIT_FOR_NMI_READY"
	else:
		_phase = "stopped_at_slot05_post_yield_scheduler_boundary"
		_last_source_boundary = "slot-$05 field loop saved at `$CB0F`; scheduler decision $%02X" % int(scan.get("decision", -1))
	var result_status := "slot05_clock_tick_saved_and_rescanned" if clock_tick_handoff \
		else "slot05_field_loop_saved_and_rescanned"
	var result := _slot05_resume_result(result_status, dispatch,
		boundary, worker_input, {}, {}, field_loop_result, saved_boundary, scan,
		scan_results, next_slot, next_boundary, true, "",
		_scheduler.get_task_boundary_snapshot(SLOT_05))
	result["slot05_field_loop_continuation_validated"] = not scenario44_enqueue_valid
	result["slot05_scenario44_enqueue_validated"] = scenario44_enqueue_valid
	result["slot05_clock_tick_handoff_validated"] = clock_tick_handoff
	result["slot05_cb0f_callsite_pc"] = yield_callsite_pc
	return result


func _resume_slot05_scenario18_field_update(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or int(dispatch.get("pc", -1)) != 0xE778 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("bank_low", -1)) != 0x1A \
			or int(dispatch.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("pc", -1)) != 0xE778 \
			or not String(boundary.get("source_label", "")).begins_with(
				"ROM-byte PASS scenario-$18 field update"):
		return _fail_result("Scenario-$18 field update resume requires the scheduler's live `$E775->$CB0F RTS->$E778` dispatch.")
	var worker_boundary := boundary.duplicate(true)
	worker_boundary["a"] = int(dispatch.get("a", -1))
	worker_boundary["x"] = int(dispatch.get("x", -1))
	worker_boundary["y"] = int(dispatch.get("y", -1))
	worker_boundary["sp"] = int(dispatch.get("sp", -1))
	worker_boundary["pc"] = 0xE778
	worker_boundary["source_dispatch"] = {"rom_sha256": ROM_SHA256,
		"slot_base": SLOT_05, "resume_path": "yielded_rts",
		"pc": 0xE778, "bank": 0x1F, "source_dispatch_observed": true}
	var worker_result: Dictionary = _worker_prefix.execute_scenario18_pass_result_from_live_boundary(
		worker_boundary)
	if not bool(worker_result.get("ok", false)) \
			or String(worker_result.get("status", "")) != "scenario18_pass_result_source_call_boundary" \
			or int(worker_result.get("cb0f_callsite_pc", -1)) not in [0xE775, 0xCBBE]:
		return _fail_result("ROM-byte scenario-$18 `$E778` continuation stopped at `$%04X`: %s" % [
			int(worker_result.get("cb0f_callsite_pc", worker_result.get("exit_pc", -1))),
			JSON.stringify({"status": worker_result.get("status", ""),
				"scenario": worker_result.get("scenario_id_at_boundary", -1),
				"reason": worker_result.get("source_gap_reason", "")})])
	var callsite_pc := int(worker_result.get("cb0f_callsite_pc", -1))
	var update_adoption: Dictionary
	var yield_description := "PASS scenario-$18 field update"
	if callsite_pc == 0xE775:
		update_adoption = _scheduler.adopt_slot05_scenario18_field_update_yield(
			worker_boundary, worker_result)
	elif callsite_pc == 0xCBBE:
		update_adoption = _scheduler.adopt_slot05_scenario18_pass_result_queue_from_e778(
			worker_boundary, worker_result)
		yield_description = "PASS action scenario-$1C"
	if not bool(update_adoption.get("ok", false)):
		return _fail_result("Scheduler rejected scenario-$18 `$E778->$%04X` continuation: " \
			% callsite_pc + String(update_adoption.get("error", _scheduler.error_message)))
	var yield_source := worker_result.duplicate(true)
	yield_source["call_request"] = (update_adoption.get("call_contract", {}) as Dictionary).duplicate(true)
	var yielded := _yield_slot05_source_task_callsite(yield_source, false,
		yield_description, true)
	if not bool(yielded.get("ok", false)):
		return yielded
	yielded["status"] = "scenario18_field_update_resumed_and_yielded" if callsite_pc == 0xE775 \
		else "scenario18_pass_result_queued"
	yielded["field_update_boundary"] = "scenario-$18 coordinate update resumed at `$E778` and yielded at `$E775->$CB0F`" \
		if callsite_pc == 0xE775 else "scenario-$18 PASS result resumed at `$E778` and queued scenario `$1C` at `$CBBE->$CB0F`"
	yielded["scenario18_field_update_worker"] = worker_result.duplicate(true)
	yielded["scenario18_field_update_adoption"] = update_adoption.duplicate(true)
	return yielded


func _resume_slot05_field_input_iteration(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var worker_input := {
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": SLOT_05,
			"resume_path": "yielded_rts", "pc": 0xE412, "bank": 0x1F,
			"source_dispatch_observed": true},
		"registers": {"a": int(dispatch.get("a", -1)),
			"x": int(dispatch.get("x", -1)), "y": int(dispatch.get("y", -1)),
			"p": int(boundary.get("p", -1)),
			"p_known_mask": int(boundary.get("p_known_mask", -1)),
			"sp": int(dispatch.get("sp", -1)), "pc": 0xE412},
		"mapper": {"bank_low": int(dispatch.get("bank_low", -1)),
			"bank_high": int(dispatch.get("bank_high", -1)),
			"select": _pending_slot05_mapper_select},
		"ram_image": boundary.get("ram_image", PackedByteArray()),
		"stack_page": boundary.get("stack_page", PackedByteArray()),
	}
	var worker_result: Dictionary = _worker_prefix.resume_dispatched_slot05_field_input_iteration(worker_input)
	var accepted_scenario2e_enqueue: bool = _scheduler.validate_slot05_field_input_scenario2e_enqueue_worker_result(
		worker_result, boundary)
	if not accepted_scenario2e_enqueue \
			and not _scheduler.validate_slot05_field_input_iteration_worker_result(worker_result, boundary):
		var worker_ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
		var worker_stack: PackedByteArray = worker_result.get("stack_page", PackedByteArray())
		var worker_relevant_writes: Array[Dictionary] = []
		for write_variant in worker_result.get("writes", []):
			if write_variant is Dictionary:
				var write: Dictionary = write_variant
				var address := int(write.get("address", -1))
				if address in [0x0000, 0x0516, 0x0518, 0x0600, 0x0601, 0x0602,
						0x0603, 0x0604, 0x0605, 0x0613, 0x0615, 0x062D]:
					worker_relevant_writes.append(write.duplicate(true))
		return _fail_result("ROM-byte `$E412->$E349` field-input iteration reached no accepted source yield boundary: " \
			+ str({"error": worker_result.get("error", ""),
				"status": worker_result.get("status", ""),
				"manifest_sha256": worker_result.get("source_manifest_sha256", ""),
				"source_manifest": worker_result.get("source_manifest", ""),
				"exit_kind": worker_result.get("exit_kind", ""),
				"pc": worker_result.get("exit_pc", -1),
				"exit_bank": worker_result.get("exit_bank", -1),
				"blocked_read": worker_result.get("blocked_read", {}),
				"unsupported_opcode": worker_result.get("unsupported_opcode", {}),
				"registers": worker_result.get("registers", {}),
				"mapper": worker_result.get("mapper", {}),
				"entry_mapper": worker_result.get("entry_mapper", {}),
				"mapper_writes": worker_result.get("mapper_writes", []),
				"source_return_bytes": [
					int(worker_stack[(int(worker_result.get("registers", {}).get("sp", -1)) + 1) & 0xFF]) \
						if worker_stack.size() == 0x100 else -1,
					int(worker_stack[(int(worker_result.get("registers", {}).get("sp", -1)) + 2) & 0xFF]) \
						if worker_stack.size() == 0x100 else -1],
				"outer_cbb0_return_bytes": [
					int(worker_stack[(int(worker_result.get("registers", {}).get("sp", -1)) + 3) & 0xFF]) \
						if worker_stack.size() == 0x100 else -1,
					int(worker_stack[(int(worker_result.get("registers", {}).get("sp", -1)) + 4) & 0xFF]) \
						if worker_stack.size() == 0x100 else -1],
				"source_dispatch": worker_result.get("source_dispatch", {}),
				"live_boundary": {"slot_base": boundary.get("slot_base", -1),
					"active_task_slot": boundary.get("active_task_slot", -1),
					"pc": boundary.get("pc", -1), "bank_low": boundary.get("bank_low", -1),
					"bank_high": boundary.get("bank_high", -1)},
				"ram_size": worker_ram.size(),
				"ram_0515_0519": worker_ram.slice(0x0515, 0x051A).hex_encode() \
					if worker_ram.size() == 0x800 else "invalid",
				"ram_0600_0606": worker_ram.slice(0x0600, 0x0606).hex_encode() \
					if worker_ram.size() == 0x800 else "invalid",
				"ram_0613_0616": worker_ram.slice(0x0613, 0x0616).hex_encode() \
					if worker_ram.size() == 0x800 else "invalid",
				"ram_062D": int(worker_ram[0x062D]) if worker_ram.size() == 0x800 else -1,
				"relevant_writes": worker_relevant_writes,
				"stack_mirror_matches": worker_ram.size() == 0x800 and worker_stack.size() == 0x100 \
					and worker_ram.slice(0x0100, 0x0200) == worker_stack,
				"calls": worker_result.get("calls", []),
				"executed_source_spans": worker_result.get("executed_source_spans", [])}))
	if not _scheduler.adopt_root_slot05_worker_resume_state(dispatch, boundary, worker_result):
		return _fail_result("Scheduler rejected the ROM-produced `$E412` field-input continuation: " \
			+ _scheduler.error_message)
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	var field_input_yield_callsite := 0xCBBE if accepted_scenario2e_enqueue else \
		(0xE147 if int(worker_result.get("exit_pc", -1)) == 0xCB0F else 0xE40F)
	var input_iteration_call_frame_already_pushed := field_input_yield_callsite in [0xCBBE, 0xE147]
	var yield_stack_pointer := int(registers.get("sp", -1))
	if input_iteration_call_frame_already_pushed:
		yield_stack_pointer = (yield_stack_pointer + 2) & 0xFF
	if not _scheduler.yield_at_verified_callsite(SLOT_05, field_input_yield_callsite,
			int(registers.get("a", -1)), yield_stack_pointer,
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			input_iteration_call_frame_already_pushed):
		return _fail_result("Scheduler rejected the source `$%04X->$CB0F` field-input yield: " % field_input_yield_callsite \
			+ _scheduler.error_message)
	var saved_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var field_input_yield_label := "$E40F" if field_input_yield_callsite == 0xE40F \
		else ("$%04X->$CB0F" % field_input_yield_callsite)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after the field-input yield failed: " + _scheduler.error_message)
		scan_results.append(scan.duplicate(true))
		if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var waiting_for_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary) \
				if next_slot == SLOT_09 else {}
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X after `%s` field-input yield" % [
			next_slot, field_input_yield_label]
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "slot-$05 field-input loop saved at `%s`; scheduler WAIT_FOR_NMI_READY" % \
			field_input_yield_label
		waiting_for_nmi = true
	else:
		return _fail_result("Field-input yield stopped at an unsupported scheduler decision: %s" % str(scan))
	return {
		"ok": true,
		"status": "slot05_field_input_iteration_saved_and_rescanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"slot05_dispatch": dispatch.duplicate(true),
		"slot05_live_boundary": boundary.duplicate(true),
		"slot05_worker_result": worker_result.duplicate(true),
		"slot05_cb0f_saved_boundary": saved_boundary,
		"post_slot05_scan_results": scan_results,
		"post_slot05_scan": scan,
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary,
		"awaiting_external_nmi": waiting_for_nmi,
		"slot05_field_input_iteration_validated": true,
		"slot05_scenario2e_enqueue_validated": accepted_scenario2e_enqueue,
		"slot05_cb0f_callsite_pc": field_input_yield_callsite,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


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


func _finish_first_action_menu_source_entry(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	var record: PackedByteArray = boundary.get("record", PackedByteArray())
	var active_source_yield_is_valid: bool = not _last_slot05_action_menu_wait_result.is_empty() \
			and _scheduler.validate_slot05_action_menu_wait_worker_result(
				_last_slot05_action_menu_wait_result)
	if not active_source_yield_is_valid \
			or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xD5EA \
			or int(dispatch.get("bank_low", -1)) != 0x1A \
			or int(dispatch.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("slot_base", -1)) != SLOT_05 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xD5EA \
			or int(boundary.get("sp", -1)) != int(dispatch.get("sp", -2)) \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or ram.size() != RAM_SIZE or record.size() != 4 \
			or int(ram[0x0621]) != 0 or (int(ram[0x061E]) & 0x80) != 0:
		return _fail_result("The source-dispatched `$D5EA` action-menu wait boundary lacks its verified `$D5E7->$CB0F` predecessor or unselected context-0 state.")
	_phase = "first_action_menu_ready"
	_last_source_boundary = "ROM `$D5E5` action menu is drawn; source scheduler restored `$D5EA` before any action selection"
	_pending_selected_task_slot = SLOT_05
	_pending_selected_task_boundary = boundary.duplicate(true)
	_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(boundary)
	return {
		"ok": true,
		"status": "first_action_menu_source_ready",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"source_dispatch": dispatch.duplicate(true),
		"source_task_boundary": boundary.duplicate(true),
		"preceding_action_menu_wait_worker": _last_slot05_action_menu_wait_result.duplicate(true),
		"menu_context": int(ram[0x0621]),
		"selection_state": int(ram[0x061E]),
		"action_selected": false,
		"action_confirmed": false,
		"source_owned_input_wait_pc": 0xD5EA,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func create_match_player_state_provider() -> Variant:
	if _rng_source_replay == null:
		error_message = "The source route has no configured ROM-derived kickoff RNG replay."
		return null
	var provider = MATCH_PLAYER_STATE_PROVIDER_SCRIPT.new()
	if not provider.configure_from_receiver_replay(_rng_source_replay):
		error_message = "ROM-derived first-menu player state could not be built: " + provider.error_message
		return null
	var live_boundary := _pending_selected_task_boundary.duplicate(true)
	live_boundary["source_rom_sha256"] = ROM_SHA256
	if not provider.synchronize_from_verified_live_source(live_boundary,
			_verified_stamina_update_receipt):
		error_message = "ROM-derived first-menu energy does not have a verified live `$E2BC` result: " \
			+ String(provider.error_message)
		return null
	return provider


func _capture_verified_stamina_update(boundary: Dictionary,
		worker_result: Dictionary) -> void:
	if not _verified_stamina_update_receipt.is_empty() \
			or _last_d193_clock_tick_handoff_result.is_empty():
		return
	var handoff: Dictionary = _last_d193_clock_tick_handoff_result.get("handoff", {})
	var dispatch: Dictionary = worker_result.get("source_dispatch", {})
	var entry_ram: Variant = boundary.get("ram_image", PackedByteArray())
	var result_ram: Variant = worker_result.get("ram_image", PackedByteArray())
	var calls_variant: Variant = worker_result.get("calls", [])
	var instructions_variant: Variant = worker_result.get("instructions", [])
	var spans_variant: Variant = worker_result.get("executed_source_spans", [])
	var writes_variant: Variant = worker_result.get("writes", [])
	if not entry_ram is PackedByteArray or (entry_ram as PackedByteArray).size() != RAM_SIZE \
			or not result_ram is PackedByteArray or (result_ram as PackedByteArray).size() != RAM_SIZE \
			or not calls_variant is Array or not instructions_variant is Array \
			or not spans_variant is Array or not writes_variant is Array:
		return
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != \
				"res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json" \
			or not bool(worker_result.get("ok", false)) \
			or String(worker_result.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker_result.get("exit_pc", -1)) != 0xC515 \
			or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or not bool(dispatch.get("source_dispatch_observed", false)) \
			or int(handoff.get("outer_caller_return_pc", -1)) != 0xE1F1:
		return
	var saw_e1f7_to_e2bc := false
	var source_calls: Array[Dictionary] = []
	for call_variant in calls_variant:
		if not call_variant is Dictionary:
			continue
		var call: Dictionary = call_variant
		if int(call.get("callsite", -1)) in [0xE1F7, 0xE2D3, 0xE31C, 0xE33F, 0xE343]:
			source_calls.append(call.duplicate(true))
		if int(call.get("callsite", -1)) == 0xE1F7 \
				and int(call.get("target", -1)) == 0xE2BC \
				and int(call.get("bank", -1)) == 0x1F:
			saw_e1f7_to_e2bc = true
	var source_pcs: Array[int] = []
	for instruction_variant in instructions_variant:
		if instruction_variant is Dictionary:
			var pc := int(instruction_variant.get("pc", -1))
			if pc in [0xE1F1, 0xE1F7, 0xE2BC, 0xE33F, 0xE343]:
				source_pcs.append(pc)
	var field_setup_span: Dictionary = {}
	for span_variant in spans_variant:
		if span_variant is Dictionary and String(span_variant.get("file", "")) == \
				"fixed_field_entry_setup_E0E9_E349.bin":
			field_setup_span = span_variant
	if not saw_e1f7_to_e2bc or not source_pcs.has(0xE1F1) \
			or not source_pcs.has(0xE1F7) or not source_pcs.has(0xE2BC) \
			or String(field_setup_span.get("sha256", "")) != \
				"069aa6c733b9de0a6070e280f89277a4ec192f1c551001fb787e9038244806de":
		return
	var player_slot: int = _rng_source_replay.get_receiver_slot() if _rng_source_replay != null else -1
	var pointer_path := "res://reference/rom_extract/gameplay/menus/first_action_menu/player_record_pointer_table_22.bin"
	if player_slot < 0 or player_slot >= 11 or not FileAccess.file_exists(pointer_path):
		return
	var pointers := FileAccess.get_file_as_bytes(pointer_path)
	if pointers.size() != 44 or _sha256(pointers) != \
			"b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185":
		return
	var pointer_offset: int = player_slot * 2
	var record_address := int(pointers[pointer_offset]) | (int(pointers[pointer_offset + 1]) << 8)
	if record_address < 0 or record_address + 3 >= RAM_SIZE:
		return
	var player_id := int((entry_ram as PackedByteArray)[record_address])
	var run_cost := 5 if player_id == 0x20 else 3
	var before_energy := int((entry_ram as PackedByteArray)[record_address + 1]) \
		| (int((entry_ram as PackedByteArray)[record_address + 2]) << 8)
	var after_energy := int((result_ram as PackedByteArray)[record_address + 1]) \
		| (int((result_ram as PackedByteArray)[record_address + 2]) << 8)
	if int((result_ram as PackedByteArray)[record_address]) != player_id \
			or before_energy <= 0 or after_energy != maxi(0, before_energy - run_cost):
		return
	var holder_writes: Array[Dictionary] = []
	var last_low := -1
	var last_high := -1
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		if address == record_address + 1:
			last_low = int(write.get("value", -1))
			holder_writes.append(write.duplicate(true))
		elif address == record_address + 2:
			last_high = int(write.get("value", -1))
			holder_writes.append(write.duplicate(true))
	if last_low != ((after_energy) & 0xFF) or last_high != ((after_energy >> 8) & 0xFF) \
			or holder_writes.size() < 2:
		return
	var live_player_records: Array[Dictionary] = []
	var source_record_writes: Array[Dictionary] = []
	for write_variant in writes_variant:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			var address := int(write.get("address", -1))
			if address >= 0x0300 and address < 0x037C:
				source_record_writes.append(write.duplicate(true))
	for slot in range(11):
		var slot_pointer_offset: int = slot * 2
		var slot_address := int(pointers[slot_pointer_offset]) \
			| (int(pointers[slot_pointer_offset + 1]) << 8)
		if slot_address < 0 or slot_address + 3 >= RAM_SIZE:
			return
		var source_record_ram: PackedByteArray = result_ram as PackedByteArray
		var source_energy := int(source_record_ram[slot_address + 1]) \
			| (int(source_record_ram[slot_address + 2]) << 8)
		live_player_records.append({"slot": slot, "record_address": slot_address,
			"player_id": int(source_record_ram[slot_address]),
			"energy": source_energy, "level": int(source_record_ram[slot_address + 3]),
			"record_bytes": source_record_ram.slice(slot_address, slot_address + 4).hex_encode()})
	_verified_stamina_update_receipt = {
		"ok": true,
		"kind": "rom_d193_e1f1_e1f7_e2bc_stamina_update",
		"rom_sha256": ROM_SHA256,
		"source_frame_domain": "Godot route source tick; no cycle-phase claim",
		"source_dispatch": dispatch.duplicate(true),
		"d193_handoff": handoff.duplicate(true),
		"source_pcs": source_pcs,
		"source_calls": source_calls,
		"source_record_writes": source_record_writes,
		"source_span": field_setup_span.duplicate(true),
		"player_slot": player_slot,
		"player_id": player_id,
		"record_address": record_address,
		"run_cost": run_cost,
		"energy_before": before_energy,
		"energy_after": after_energy,
		"holder_energy_writes": holder_writes,
		"live_player_records": live_player_records,
		"worker_exit_pc": int(worker_result.get("exit_pc", -1)),
		"worker_ram_image_sha256": _sha256(result_ram as PackedByteArray),
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func create_descriptor_01_source_context() -> Dictionary:
	error_message = ""
	if _route_context == null or _phase != "first_action_menu_ready" \
			or _fresh_period_result.is_empty():
		error_message = "Descriptor-$01 team packets require the completed selector and fresh-period source results."
		return {}
	var selector_receipt: Dictionary = _route_context.selector_roster_write_receipt
	if selector_receipt.is_empty() or String(selector_receipt.get("source_rom_sha256", "")) != ROM_SHA256:
		error_message = "Descriptor-$01 team packets have no source ROM selector receipt."
		return {}
	return {
		"selector_result": selector_receipt.duplicate(true),
		"fresh_period_result": _fresh_period_result.duplicate(true),
		"source_context": "live ROM selector and period receipts retained by the configured fresh-match route",
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func create_first_command_actor_source_context() -> Dictionary:
	error_message = ""
	var boundary := _pending_selected_task_boundary
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	if _phase != "first_action_menu_ready" or boundary.is_empty() \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_05 \
			or int(boundary.get("pc", -1)) != 0xD5EA \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or _last_slot05_action_menu_wait_result.is_empty() \
			or not _scheduler.validate_slot05_action_menu_wait_worker_result(
				_last_slot05_action_menu_wait_result):
		error_message = "Actor render state is unavailable without the verified live slot-$05 `$D5EA` ROM boundary."
		return {}
	return {
		"kind": "caller_owned_decoded_game_logic",
		"label": "live slot-$05 source scheduler RAM at ROM `$D5EA` before menu selection",
		"source_rom_sha256": ROM_SHA256,
		"source_pc": 0xD5EA,
		"trace_state_used": false,
		"emulator_data_used": false,
		"mirror_mode": int(ram[0x0517]),
		"scroll_x": int(ram[0x0538]),
		"clip_y_min": int(ram[0x0540]),
		"clip_y_max": int(ram[0x0541]),
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
		return _fail_result("Scheduler rejected the live `$CBC1` scenario return: " + _scheduler.error_message)
	if int((return_result.get("registers", {}) as Dictionary).get("pc", -1)) == 0xD7ED:
		return _execute_slot05_pass_receiver_descriptor_0f_first_yield()
	if int((return_result.get("registers", {}) as Dictionary).get("pc", -1)) == 0x8188:
		var caller_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var caller_result: Dictionary = _slot05_scenario18_post_queue_caller_executor.execute_from_live_return(
			return_result, caller_boundary)
		if OS.get_environment("CT2_SCENARIO18_CALLER_TRACE").strip_edges() == "1":
			var caller_entry_ram: Variant = caller_result.get("entry_ram_image", PackedByteArray())
			var caller_output_ram: Variant = caller_result.get("ram_image", PackedByteArray())
			if caller_entry_ram is PackedByteArray and caller_entry_ram.size() == 0x800 \
					and caller_output_ram is PackedByteArray and caller_output_ram.size() == 0x800:
				print("SCENARIO18_CALLER_TRACE " + JSON.stringify({
					"entry_pc": caller_result.get("entry_pc", -1),
					"entry_0444": int(caller_entry_ram[0x0444]),
					"entry_044e": int(caller_entry_ram[0x044E]),
					"entry_00e2": int(caller_entry_ram[0x00E2]),
					"output_044e": int(caller_output_ram[0x044E]),
					"branch_mode_initial": caller_result.get("call_contract", {}).get("branch_mode_initial", -1),
					"writes": caller_result.get("ram_writes", []),
				}))
		if not bool(caller_result.get("ok", false)):
			return _fail_result("ROM-byte scenario-$18 `$8188->$8112` caller stopped: " \
				+ String(caller_result.get("error", _slot05_scenario18_post_queue_caller_executor.error_message)))
		if not _scheduler.adopt_slot05_scenario18_post_queue_caller_result(caller_boundary,
				caller_result):
			return _fail_result("Scheduler rejected the ROM scenario-$18 `$8188->$8112` caller: " \
				+ _scheduler.error_message)
		var result_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var pass_result_worker: Dictionary = _worker_prefix.execute_scenario18_pass_result_from_live_boundary(
			result_boundary)
		if not bool(pass_result_worker.get("ok", false)):
			return _fail_result("ROM-byte scenario-$18 PASS-result handler stopped: " \
				+ String(pass_result_worker.get("error", _worker_prefix.error_message)) \
				+ " at `$%04X`." % int(pass_result_worker.get("exit_pc", -1)))
		if String(pass_result_worker.get("status", "")) \
				!= "scenario18_pass_result_source_call_boundary":
			return _fail_result("Scenario-$18 PASS result reached an unresolved `$CB0F` call at `$%04X`, scenario `$%02X`; calls=%s recent_pcs=%s." % [
				int(pass_result_worker.get("cb0f_callsite_pc", -1)),
				int(pass_result_worker.get("scenario_id_at_boundary", -1)),
				JSON.stringify(pass_result_worker.get("calls_to_cb0f", [])),
				JSON.stringify(pass_result_worker.get("recent_instruction_pcs", []))])
		if int(pass_result_worker.get("cb0f_callsite_pc", -1)) == 0xE775:
			var field_update_adoption: Dictionary = _scheduler.adopt_slot05_scenario18_field_update_yield(
				result_boundary, pass_result_worker)
			if not bool(field_update_adoption.get("ok", false)):
				return _fail_result("Scheduler rejected scenario-$18 field update `$E775->$CB0F`: " \
					+ String(field_update_adoption.get("error", _scheduler.error_message)))
			var field_update_source := pass_result_worker.duplicate(true)
			field_update_source["call_request"] = (field_update_adoption.get("call_contract", {}) as Dictionary).duplicate(true)
			var field_update_yield := _yield_slot05_source_task_callsite(field_update_source,
				false, "PASS scenario-$18 field update", true)
			if not bool(field_update_yield.get("ok", false)):
				return field_update_yield
			field_update_yield["status"] = "scenario18_field_update_yielded"
			field_update_yield["field_update_boundary"] = "scenario-$18 coordinate update yielded one ROM frame at `$E775->$CB0F`"
			field_update_yield["slot05_scenario_return_result"] = return_result.duplicate(true)
			field_update_yield["scenario18_post_queue_caller_result"] = caller_result.duplicate(true)
			field_update_yield["scenario18_field_update_worker"] = pass_result_worker.duplicate(true)
			field_update_yield["scenario18_field_update_adoption"] = field_update_adoption.duplicate(true)
			return field_update_yield
		if int(pass_result_worker.get("cb0f_callsite_pc", -1)) != 0xCBBE:
			return _fail_result("Scenario-$18 PASS result reached unsupported `$CB0F` caller `$%04X`." % int(pass_result_worker.get("cb0f_callsite_pc", -1)))
		var queue_adoption: Dictionary = _scheduler.adopt_slot05_scenario18_pass_result_queue(
			result_boundary, pass_result_worker)
		if not bool(queue_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected the ROM scenario-$18 `$CBBE->$CB0F` queue: " \
				+ String(queue_adoption.get("error", _scheduler.error_message)))
		var yield_source := pass_result_worker.duplicate(true)
		yield_source["call_request"] = (queue_adoption.get("call_contract", {}) as Dictionary).duplicate(true)
		var yielded := _yield_slot05_source_task_callsite(yield_source, false,
			"PASS action scenario-$1C", true)
		if not bool(yielded.get("ok", false)):
			return yielded
		_last_source_boundary = "scenario-$18 PASS result queued ROM scenario `$1C` at `$CB0F`"
		yielded["status"] = "scenario18_pass_result_queued"
		yielded["slot05_scenario_return_result"] = return_result.duplicate(true)
		yielded["scenario18_post_queue_caller_result"] = caller_result.duplicate(true)
		yielded["scenario18_pass_result_worker"] = pass_result_worker.duplicate(true)
		yielded["scenario18_pass_result_queue_adoption"] = queue_adoption.duplicate(true)
		yielded["last_source_boundary"] = _last_source_boundary
		return yielded
	if int((return_result.get("registers", {}) as Dictionary).get("pc", -1)) == 0xE38F:
		var scenario44_handoff: Dictionary = _scenario44_post_queue_return_executor.execute_from_return_result(
			return_result)
		if not bool(scenario44_handoff.get("ok", false)):
			return _fail_result("ROM-byte scenario-$44 `$E38F->$8003` caller stopped: " \
				+ String(scenario44_handoff.get("error", _scenario44_post_queue_return_executor.error_message)))
		if not _scheduler.adopt_slot05_scenario44_field_handoff(return_result,
				scenario44_handoff):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$44 field handoff: " \
				+ _scheduler.error_message)
		var field_entry_live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var field_entry_result: Dictionary = _worker_prefix.execute_scenario44_field_entry(
			scenario44_handoff)
		if field_entry_result.is_empty():
			return _fail_result("ROM-byte scenario-$44 field entry could not start at `$8003`: " \
				+ _worker_prefix.error_message)
		_scenario44_field_entry_worker_result = field_entry_result.duplicate(true)
		var field_entry_status := String(field_entry_result.get("status", ""))
		var scenario44_field_entry_yield: Dictionary = {}
		var resumed_scheduler := field_entry_status == "scenario44_field_entry_source_call_boundary" \
			and int(field_entry_result.get("exit_pc", -1)) == 0xCB0F
		if resumed_scheduler:
			scenario44_field_entry_yield = _scheduler.adopt_slot05_scenario44_field_entry_yield(
				field_entry_live_boundary, scenario44_handoff, field_entry_result)
			if resumed_scheduler and scenario44_field_entry_yield.is_empty():
				return _fail_result("Scheduler rejected the ROM-derived `$F018->$CB0F` field packet-producer yield: " \
					+ _scheduler.error_message)
		if resumed_scheduler:
			field_entry_result["scheduler_yield_adoption_result"] = scenario44_field_entry_yield.duplicate(true)
			_phase = "awaiting_external_nmi"
			_pending_selected_task_slot = -1
			_pending_selected_task_boundary.clear()
			_pending_selected_task_mapper.clear()
			_pending_nmi_queue_state.clear()
			_last_source_boundary = "`$F018->$CB0F` field packet producer saved; scheduler awaits the source NMI edge"
		else:
			_phase = "stopped_at_scenario44_field_entry_call_boundary" \
				if field_entry_status == "scenario44_field_entry_source_call_boundary" \
				else "stopped_at_scenario44_field_source_boundary"
			_pending_selected_task_slot = -1
			_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(
				_pending_selected_task_boundary)
			_last_source_boundary = "scenario-$44 ROM field entry from `$8003` stopped at `$%04X` (%s)" % [
				int(field_entry_result.get("exit_pc", -1)),
				String(field_entry_result.get("blocked_read", {}).get("reason", \
					field_entry_result.get("unsupported_opcode", {}).get("reason", field_entry_status)))]
		scenario44_handoff["field_entry_execution_result"] = field_entry_result.duplicate(true)
		return {"ok": true, "status": "scenario44_field_entry_yield_saved" if resumed_scheduler else field_entry_status,
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"last_source_boundary": _last_source_boundary,
			"slot05_scenario_return_result": return_result.duplicate(true),
			"scenario44_field_handoff_result": scenario44_handoff.duplicate(true),
			"scenario44_field_entry_result": field_entry_result.duplicate(true),
			"scenario44_field_entry_yield_result": scenario44_field_entry_yield.duplicate(true),
			"slot05_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
			"awaiting_external_nmi": resumed_scheduler, "next_external_nmi_required": resumed_scheduler,
			"ppu_cycle_timing_modeled": false, "audio_effects_modeled": false}
	if int((return_result.get("registers", {}) as Dictionary).get("pc", -1)) == 0xE238:
		var field_setup_result: Dictionary = _continuation.execute_after_field_setup_scenario_return(
			return_result)
		if not bool(field_setup_result.get("ok", false)):
			return _fail_result("ROM-byte scenario-$1E caller did not reach its `$E247->$8024` minimap callsite: " \
					+ _continuation.error_message)
		if not _scheduler.adopt_slot05_field_setup_minimap_callsite_state(
				return_result, field_setup_result):
			return _fail_result("Scheduler rejected the ROM-derived `$E238->$E247->$8024` field setup: " \
					+ _scheduler.error_message)
		var minimap_result: Dictionary = _continuation.execute_field_minimap_to_first_wait_callsite(
			field_setup_result)
		if not bool(minimap_result.get("ok", false)):
			return _fail_result("ROM-byte minimap vector/waiter did not reach `$CC50->$CB0F`: " \
					+ _continuation.error_message)
		if not _scheduler.adopt_slot05_minimap_first_wait_callsite_state(
				field_setup_result, minimap_result):
			return _fail_result("Scheduler rejected the ROM-derived minimap `$CC50` wait state: " \
					+ _scheduler.error_message)
		return _yield_slot05_field_minimap_wait_callsite(minimap_result)
	var caller_result: Dictionary = _continuation.execute_after_scenario_return(return_result)
	if not bool(caller_result.get("ok", false)) or int(caller_result.get("exit_pc", -1)) != 0xDADF:
		return _fail_result("ROM-byte scenario caller did not reach `$DADF->$CB0F`: " + _continuation.error_message)
	if not _scheduler.adopt_slot05_scenario35_wait_callsite_state(return_result, caller_result):
		return _fail_result("Scheduler rejected the source `$DADD LDA #$01` wait callsite: " + _scheduler.error_message)
	return _yield_slot05_scenario35_wait_callsite(caller_result, return_result)


## Executes the live slot-$05 PASS receiver descriptor-$0F worker at its
## scheduler-owned `$D7ED` boundary. Both the direct `$CBC1 RTS->$D7ED` caller
## and a later scheduler dispatch use this same source-byte worker/adoption and
## `$8886->$C515` save path.
func _execute_slot05_pass_receiver_descriptor_0f_first_yield() -> Dictionary:
	_pass_receiver_packet_batch_progress.clear()
	_pass_receiver_packet_batch_nmi_frames.clear()
	var pass_receiver_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	pass_receiver_boundary["executing_cpu_bank"] = 0x1E
	pass_receiver_boundary["mapper_proof"] = {
		"banks_at_fixed_dispatch": [0x1C, 0x1D], "fixed_bank": 0x1E,
	}
	pass_receiver_boundary["trace_state_used"] = false
	var pass_receiver_worker: Dictionary = _worker_prefix.execute_pass_receiver_descriptor_0f_first_yield(
		pass_receiver_boundary)
	if not bool(pass_receiver_worker.get("ok", false)):
		return _fail_result("ROM-byte PASS descriptor-$0F worker did not reach its first `$C515` call entry: " \
			+ String(pass_receiver_worker.get("error", _worker_prefix.error_message)))
	if not _scheduler.adopt_slot05_pass_receiver_descriptor_0f_first_yield(
			pass_receiver_boundary, pass_receiver_worker):
		return _fail_result("Scheduler rejected the ROM-derived PASS descriptor-$0F worker boundary: " \
			+ _scheduler.error_message)
	var pass_receiver_yield: Dictionary = _yield_slot05_field_worker_callsite(
		pass_receiver_worker, "PASS receiver descriptor-$0F first worker")
	if not bool(pass_receiver_yield.get("ok", false)):
		return pass_receiver_yield
	pass_receiver_yield["status"] = "pass_receiver_descriptor_0f_first_yield_saved"
	pass_receiver_yield["pass_receiver_worker_result"] = pass_receiver_worker.duplicate(true)
	_last_slot05_pass_receiver_first_yield_result = pass_receiver_worker.duplicate(true)
	pass_receiver_yield["renderer_returned"] = false
	pass_receiver_yield["descriptor_rows_executed"] = false
	pass_receiver_yield["ppu_bus_events_applied"] = false
	pass_receiver_yield["nmi_cadence_generated"] = false
	return pass_receiver_yield


## Exposes only the scheduler-restored `$D80F` continuation after the adopted
## `$D80C->$CB0F` renderer wait and caller-supplied NMI/task scan.
func _accept_slot05_pass_receiver_input_wait(dispatch: Dictionary,
		boundary: Dictionary, source_frame_label: int) -> Dictionary:
	if not _configured or _pending_selected_task_slot not in [-1, SLOT_05] \
			or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xD80F \
			or int(dispatch.get("bank_low", -1)) != 0x1C \
			or int(dispatch.get("bank_high", -1)) != 0x1D \
			or int(source_frame_label) < 0:
		return _fail_result("PASS receiver wait requires a live scheduler `$D80F` restore after its saved `$D80C` yield.")
	if not _scheduler.arm_slot05_pass_receiver_input_wait(dispatch, boundary):
		return _fail_result("Scheduler rejected the live PASS receiver `$D80F` input-wait restore: " \
				+ String(_scheduler.error_message))
	_pass_receiver_packet_batch_progress.clear()
	_pass_receiver_packet_batch_nmi_frames.clear()
	_pass_receiver_descriptor_1d_input_poll_pending = false
	_pending_selected_task_slot = SLOT_05
	_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(
		_pending_selected_task_boundary)
	_phase = "pass_receiver_input_ready"
	_last_source_boundary = "ROM scheduler restored live PASS receiver `$D80F` at source frame %d" % source_frame_label
	return {
		"ok": true,
		"status": "pass_receiver_input_wait_restored",
		"phase": _phase,
		"source_frame_label": source_frame_label,
		"source_dispatch": dispatch.duplicate(true),
		"next_boundary_snapshot": _pending_selected_task_boundary.duplicate(true),
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


## Samples a live controller receipt at the restored `$D80F` context and invokes
## only the existing ROM-bounded Down/A executor. The Down renderer request is
## exposed with its ROM-derived first packet batch; this method does not claim
## descriptor-worker/NMI/PPU completion or the later holder transfer.
func resolve_pass_receiver_source_poll(input_sample: Dictionary,
		source_frame_label: int) -> Dictionary:
	error_message = ""
	_last_pass_receiver_input_result.clear()
	_last_pass_receiver_input_adoption.clear()
	_last_pass_receiver_descriptor_1d_batch.clear()
	if not _configured or _phase != "pass_receiver_input_ready" \
			or _pending_selected_task_slot != SLOT_05 \
			or _pass_receiver_input_executor == null \
			or not _pass_receiver_input_executor.has_method("execute_after_input_poll") \
			or int(source_frame_label) < 0:
		return _fail_result("PASS receiver poll requires the source-restored live slot-$05 `$D80F` boundary.")
	var sample_id := int(input_sample.get("sample_receipt_id", -1))
	var sampled_input_frame := int(input_sample.get("source_frame_label", -1))
	var buffered_until_source_poll := bool(input_sample.get("deferred_until_source_poll", false))
	if (sampled_input_frame != source_frame_label \
			and not (buffered_until_source_poll and sampled_input_frame >= 0 \
				and sampled_input_frame < source_frame_label)) \
			or sample_id <= 0 or sample_id != int(_scheduler.get_status().get(
			"controller_sample", {}).get("sample_receipt_id", -2)):
		return _fail_result("PASS receiver poll must use a current or explicitly buffered source-frame input and the latest ordinary controller-sample receipt.")
	# Keep the complete `$001C` latch byte for boundary validation. The ROM
	# itself masks `$001C` with `$0F` when it branches on direction bits.
	var direction := int(input_sample.get("held_ram_001c", -1))
	var direction_bits := direction & 0x0F
	var edge := int(input_sample.get("edge_ram_001e", -1))
	if direction_bits == 0 and edge == 0:
		return {"ok": true, "status": "pass_receiver_neutral_sample_not_consumed",
			"phase": _phase, "source_frame_label": source_frame_label,
			"sample_receipt_id": sample_id, "source_input_consumed": false,
			"trace_state_used": false}
	if not ((direction_bits == 0x04 and edge == 0x04) \
			or (direction_bits == 0 and edge == 0x80)):
		return _fail_result("PASS receiver executor currently supports only the trace-proven fresh Down and A inputs.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if boundary.is_empty() or int(boundary.get("pc", -1)) != 0xD80F \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05:
		return _fail_result("PASS receiver input lost the scheduler-owned active `$D80F` boundary.")
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not mapper_variant is Dictionary:
		return _fail_result("PASS receiver input boundary omits source mapper state.")
	var mapper: Dictionary = mapper_variant.duplicate(true)
	if int(mapper.get("fixed_bank", -1)) != 0x1E:
		return _fail_result("PASS receiver input boundary does not prove fixed CPU bank `$1E`.")
	mapper["cpu_c000_bank"] = 0x1E
	mapper["cpu_e000_bank"] = 0x1F
	boundary["mapper"] = mapper
	boundary["executing_cpu_bank"] = 0x1E
	boundary["polled_controller"] = {
		"direction_mask": direction,
		"button_mask": edge,
	}
	boundary["trace_state_used"] = false
	var source_result: Dictionary = _pass_receiver_input_executor.execute_after_input_poll(boundary)
	if not bool(source_result.get("ok", false)):
		return _fail_result("ROM-byte PASS receiver poll stopped: " \
				+ String(source_result.get("error", _pass_receiver_input_executor.error_message)))
	source_result["source_frame_label"] = source_frame_label
	source_result["sample_receipt_id"] = sample_id
	source_result["input_sample_receipt"] = input_sample.duplicate(true)
	var adoption: Dictionary = _scheduler.adopt_slot05_pass_receiver_input_result(
		boundary, source_result, input_sample)
	_last_pass_receiver_input_result = source_result.duplicate(true)
	_last_pass_receiver_input_adoption = adoption.duplicate(true)
	if not bool(adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the ROM receiver-input result: " \
				+ String(adoption.get("error", _scheduler.error_message)))
	if String(source_result.get("status", "")) == "receiver_down_scan_stopped_at_renderer_call":
		_pass_receiver_confirmation_input_pending = true
		_last_slot05_pass_receiver_descriptor_1d_first_yield_result.clear()
		_pass_receiver_descriptor_1d_batch_progress.clear()
		_pass_receiver_descriptor_1d_batch_nmi_frames.clear()
		var packet_batch: Dictionary = _pass_receiver_descriptor_1d_presenter.present_first_queue_batch(
			source_result)
		_last_pass_receiver_descriptor_1d_batch = packet_batch.duplicate(true)
		if not bool(packet_batch.get("ok", false)):
			return _fail_result("ROM descriptor-$1D source presenter rejected the live Down renderer request: " \
					+ String(packet_batch.get("error", _pass_receiver_descriptor_1d_presenter.error_message)))
		var renderer_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if renderer_boundary.is_empty() or int(renderer_boundary.get("pc", -1)) != 0xEF7F \
				or int(renderer_boundary.get("active_task_slot", -1)) != SLOT_05:
			return _fail_result("Down adoption did not leave the scheduler at the live descriptor-$1D `$EF7F` call boundary.")
		renderer_boundary["executing_cpu_bank"] = 0x1E
		renderer_boundary["trace_state_used"] = false
		renderer_boundary["input_sample_receipt_id"] = sample_id
		renderer_boundary["source_frame_label"] = source_frame_label
		var renderer_worker: Dictionary = _worker_prefix.execute_pass_receiver_descriptor_1d_first_yield(
			renderer_boundary, source_result)
		if not bool(renderer_worker.get("ok", false)):
			var blocked_read: Dictionary = renderer_worker.get("blocked_read", {})
			return _fail_result("ROM-byte descriptor-$1D renderer stopped before its first source yield: " \
					+ String(renderer_worker.get("error", _worker_prefix.error_message)) \
					+ (" blocked_read=" + JSON.stringify(blocked_read) if not blocked_read.is_empty() else ""))
		var renderer_adoption: Dictionary = _scheduler.adopt_slot05_pass_receiver_descriptor_1d_first_yield(
			renderer_boundary, source_result, renderer_worker)
		if not bool(renderer_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected the ROM descriptor-$1D first-yield result: " \
					+ String(renderer_adoption.get("error", _scheduler.error_message)))
		var renderer_yield: Dictionary = _yield_slot05_field_worker_callsite(
			renderer_worker, "PASS receiver descriptor-$1D first worker")
		if not bool(renderer_yield.get("ok", false)):
			return renderer_yield
		_last_slot05_pass_receiver_descriptor_1d_first_yield_result = renderer_worker.duplicate(true)
		renderer_yield["source_input_result"] = source_result.duplicate(true)
		renderer_yield["source_input_adoption"] = adoption.duplicate(true)
		renderer_yield["descriptor_1d_packet_batch"] = packet_batch.duplicate(true)
		renderer_yield["pass_receiver_descriptor_1d_worker_result"] = renderer_worker.duplicate(true)
		renderer_yield["pass_receiver_descriptor_1d_scheduler_adoption"] = renderer_adoption.duplicate(true)
		renderer_yield["renderer_worker_executed"] = true
		renderer_yield["nmi_or_ppu_transfer_executed"] = false
		renderer_yield["holder_transfer_executed"] = false
		renderer_yield["trace_state_used"] = false
		return renderer_yield
	_pass_receiver_confirmation_input_pending = false
	_phase = "pass_receiver_confirmed_at_d70c"
	_last_source_boundary = "PASS A adopted at `$D70C`; source holder transfer remains pending"
	return {
		"ok": true, "status": "pass_receiver_confirmation_stopped_at_d70c",
		"phase": _phase, "source_frame_label": source_frame_label,
		"input_sample_receipt": input_sample.duplicate(true),
		"source_result": source_result.duplicate(true),
		"scheduler_adoption": adoption.duplicate(true),
		"holder_transfer_executed": false,
		"fceux_full_ram_compared": false,
		"trace_state_used": false,
	}


## Runs the PASS confirmation caller from live `$D70C` through the shared
## waiter's real `$CC50->$CB0F` callsite, then delegates the task save/scan to
## the ordinary scheduler/NMI path. This continuation is one-use after A.
func resume_pass_receiver_confirmation_wait() -> Dictionary:
	if not _configured or _scheduler == null \
			or _pass_receiver_confirmation_wait_executor == null:
		return _fail_result("PASS confirmation waiter is not configured from ROM sources.")
	if _phase != "pass_receiver_confirmed_at_d70c":
		return _fail_result("PASS confirmation waiter may resume only once from phase `pass_receiver_confirmed_at_d70c`.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if boundary.is_empty() or int(boundary.get("pc", -1)) != 0xD70C \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05:
		return _fail_result("PASS confirmation waiter expected the scheduler-owned live slot-$05 `$D70C` boundary.")
	boundary["executing_cpu_bank"] = 0x1E
	boundary["trace_state_used"] = false
	var waiter_result: Dictionary = _pass_receiver_confirmation_wait_executor.execute_from_live_boundary(
		boundary)
	if not bool(waiter_result.get("ok", false)):
		return _fail_result("ROM-byte PASS confirmation waiter did not reach `$CC50`: " \
			+ String(waiter_result.get("error", _pass_receiver_confirmation_wait_executor.error_message)) \
			+ " boundary=" + JSON.stringify({"slot": boundary.get("slot_base", -1),
				"active": boundary.get("active_task_slot", -1), "phase": boundary.get("phase", -1),
				"pc": boundary.get("pc", -1), "sp": boundary.get("sp", -1),
				"banks": [boundary.get("bank_low", -1), boundary.get("bank_high", -1)],
				"mapper": boundary.get("mapper", {}), "source_label": boundary.get("source_label", ""),
				"trace": boundary.get("trace_state_used", true),
				"fixture": boundary.get("test_fixture", false),
				"ram_values": _pass_receiver_wait_boundary_ram_values(boundary),
				"stack_matches_ram": _pass_receiver_wait_boundary_stack_matches(boundary)}))
	if not _scheduler.adopt_slot05_pass_confirmation_wait_callsite(boundary, waiter_result):
		return _fail_result("Scheduler rejected the PASS confirmation wait callsite: " + _scheduler.error_message)
	var yielded := _yield_slot05_source_task_callsite(waiter_result, true,
		"PASS receiver confirmation waiter")
	if not bool(yielded.get("ok", false)):
		return yielded
	_phase = String(yielded.get("phase", "awaiting_external_nmi"))
	_last_source_boundary = String(yielded.get("last_source_boundary", ""))
	_last_pass_receiver_confirmation_wait_result = {
		"boundary": boundary.duplicate(true),
		"waiter_result": waiter_result.duplicate(true),
		"scheduler_yield": yielded.duplicate(true),
	}
	var output := yielded.duplicate(true)
	output["status"] = "pass_receiver_confirmation_wait_yielded"
	output["source_task_result"] = waiter_result.duplicate(true)
	output["confirmation_waiter_result"] = waiter_result.duplicate(true)
	output["confirmation_waiter_adoption"] = {
		"ok": true, "status": "pass_confirmation_wait_callsite_adopted",
		"source_exit_pc": 0xCC50, "scheduler_jsr_pending": true,
		"external_nmi_consumed": false, "ppu_effects_applied": false,
	}
	output["awaiting_external_nmi"] = bool(yielded.get("awaiting_external_nmi", false))
	output["trace_state_used"] = false
	output["holder_transfer_executed"] = false
	return output


func _pass_receiver_wait_boundary_ram_values(boundary: Dictionary) -> Dictionary:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	if not ram is PackedByteArray or (ram as PackedByteArray).size() != RAM_SIZE:
		return {"size": (ram as PackedByteArray).size() if ram is PackedByteArray else -1}
	var bytes: PackedByteArray = ram
	return {"size": bytes.size(), "0000": bytes[0x0000], "0024": bytes[0x0024],
		"0025": bytes[0x0025], "0441": bytes[0x0441], "05FC": bytes[0x05FC],
		"0624": bytes[0x0624], "0625": bytes[0x0625], "062D": bytes[0x062D],
		"0638": bytes[0x0638]}


func _pass_receiver_wait_boundary_stack_matches(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
		and (ram as PackedByteArray).size() == RAM_SIZE \
		and (stack as PackedByteArray).size() == 0x100 \
		and (ram as PackedByteArray).slice(0x0100, 0x0200) == stack


func _resume_slot05_pass_confirmation_waiter(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	if _pass_confirmation_waiter_post_nmi_executor == null:
		return _fail_result("PASS confirmation waiter packet executor is not configured from ROM sources.")
	var resume_pc := int(dispatch.get("pc", -1))
	if OS.get_environment("CT2_TRACE_PASS_WAITER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9078 and _last_external_nmi_frame <= 9090:
		var entry_ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
		var entry_stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
		var entry_ram: PackedByteArray = entry_ram_variant if entry_ram_variant is PackedByteArray else PackedByteArray()
		var entry_stack: PackedByteArray = entry_stack_variant if entry_stack_variant is PackedByteArray else PackedByteArray()
		var entry_queue := entry_ram.slice(0x0515, 0x0519).hex_encode() if entry_ram.size() == RAM_SIZE else "invalid"
		var entry_counter := int(entry_stack[0x48]) if entry_stack.size() == 0x100 else -1
		var nmi_queue: Dictionary = _last_nmi_result.get("secondary_queue", {})
		print("PASS_WAITER_ENTRY frame=%d pc=$%04X sp=$%02X ready_delay=%d ram0515_0518=%s stack0148=%02X nmi=%s scans=%s" % [
			_last_external_nmi_frame, resume_pc, int(dispatch.get("sp", -1)),
			int(dispatch.get("ready_delay", -1)), entry_queue, entry_counter,
			JSON.stringify({"status": nmi_queue.get("status", ""),
				"branch": nmi_queue.get("branch", ""), "ready_before": nmi_queue.get("ready_flag_before", -1),
				"ready_after": nmi_queue.get("ready_flag_after", -1),
				"primary_before": nmi_queue.get("primary_count_before", -1),
				"primary_after": nmi_queue.get("primary_count_after", -1)}),
			JSON.stringify(_last_nmi_result.get("scheduler_scan_results", []))])
	if resume_pc == 0xCC53:
		var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
		if not ram_variant is PackedByteArray or (ram_variant as PackedByteArray).size() != RAM_SIZE:
			return _fail_result("PASS waiter `$CC53` busy-loop check requires the scheduler-owned full RAM image.")
		var queue_ready_flag := int((ram_variant as PackedByteArray)[0x0515])
		if queue_ready_flag != 0:
			if queue_ready_flag != 0x80:
				return _fail_result("PASS waiter `$CC53` busy-poll currently supports only the observed secondary queue flag `$80`; got `$%02X`." % queue_ready_flag)
			var busy_poll_result: Dictionary = _pass_confirmation_waiter_post_nmi_executor.execute_busy_poll_scheduler_yield(
				boundary)
			if not bool(busy_poll_result.get("ok", false)):
				return _fail_result("ROM-byte PASS waiter busy poll stopped at `$CC53`: " \
					+ String(busy_poll_result.get("error", _pass_confirmation_waiter_post_nmi_executor.error_message)))
			if not _scheduler.has_method("adopt_slot05_pass_confirmation_busy_poll_callsite") \
					or not bool(_scheduler.call("adopt_slot05_pass_confirmation_busy_poll_callsite",
						boundary, busy_poll_result)):
				return _fail_result("Scheduler rejected the ROM `$CC53->$CC4E->$CC50` busy-poll callsite: " \
					+ String(_scheduler.error_message))
			var busy_poll_source_result := busy_poll_result.duplicate(true)
			busy_poll_source_result["mapper"] = boundary.get("mapper", {}).duplicate(true)
			var busy_poll_yield := _yield_slot05_source_task_callsite(busy_poll_source_result,
				false, "PASS confirmation waiter busy poll")
			if not bool(busy_poll_yield.get("ok", false)):
				return busy_poll_yield
			_phase = String(busy_poll_yield.get("phase", "awaiting_external_nmi"))
			_last_source_boundary = String(busy_poll_yield.get("last_source_boundary", ""))
			var busy_poll_output := busy_poll_yield.duplicate(true)
			busy_poll_output["status"] = "pass_confirmation_waiter_busy_poll_yielded"
			busy_poll_output["source_task_result"] = busy_poll_source_result.duplicate(true)
			busy_poll_output["pass_confirmation_waiter_busy_poll_result"] = busy_poll_source_result.duplicate(true)
			busy_poll_output["pass_confirmation_waiter_busy_poll_adopted"] = true
			busy_poll_output["awaiting_external_nmi"] = bool(busy_poll_yield.get("awaiting_external_nmi", false))
			busy_poll_output["trace_state_used"] = false
			busy_poll_output["holder_transfer_executed"] = false
			return busy_poll_output
	var packet_result: Dictionary = {}
	match resume_pc:
		0xCC53:
			packet_result = _pass_confirmation_waiter_post_nmi_executor.execute_next_counted_packet_yield(
				boundary)
		0xCCA3:
			packet_result = _pass_confirmation_waiter_post_nmi_executor.execute_next_terminal_packet_yield(
				boundary)
		0xCCD1:
			if not _pass_confirmation_waiter_post_nmi_executor.has_method("execute_waiter_rts_return"):
				return _fail_result("PASS waiter reached `$CCD1`; its source RTS executor is not yet integrated.")
			packet_result = _pass_confirmation_waiter_post_nmi_executor.execute_waiter_rts_return(
				boundary)
		_:
			return _fail_result("PASS confirmation waiter received unsupported resume PC `$%04X`." % resume_pc)
	if not bool(packet_result.get("ok", false)):
		if resume_pc == 0xCCA3 \
				and OS.get_environment("CT2_TRACE_FIRST_PASS_RECEIVER_WINDOW").strip_edges() == "1":
			var failed_ram: Variant = boundary.get("ram_image", PackedByteArray())
			var failed_stack: Variant = boundary.get("stack_page", PackedByteArray())
			var failed_context := {"pc": boundary.get("pc", -1), "sp": boundary.get("sp", -1),
				"phase": boundary.get("phase", -1), "slot": boundary.get("active_task_slot", -1),
				"banks": [boundary.get("bank_low", -1), boundary.get("bank_high", -1)],
				"source_label": boundary.get("source_label", ""),
				"ram_0000": int((failed_ram as PackedByteArray)[0]) if failed_ram is PackedByteArray and (failed_ram as PackedByteArray).size() == RAM_SIZE else -1,
				"ram_0024_0025": (failed_ram as PackedByteArray).slice(0x24, 0x26).hex_encode() if failed_ram is PackedByteArray and (failed_ram as PackedByteArray).size() == RAM_SIZE else "",
				"ram_0498_0499": (failed_ram as PackedByteArray).slice(0x498, 0x49A).hex_encode() if failed_ram is PackedByteArray and (failed_ram as PackedByteArray).size() == RAM_SIZE else "",
				"ram_0515": int((failed_ram as PackedByteArray)[0x515]) if failed_ram is PackedByteArray and (failed_ram as PackedByteArray).size() == RAM_SIZE else -1,
				"ram_stack_0148_014A": (failed_ram as PackedByteArray).slice(0x148, 0x14B).hex_encode() if failed_ram is PackedByteArray and (failed_ram as PackedByteArray).size() == RAM_SIZE else "",
				"stack_48_4A": (failed_stack as PackedByteArray).slice(0x48, 0x4B).hex_encode() if failed_stack is PackedByteArray and (failed_stack as PackedByteArray).size() == 0x100 else "",
				"stack_mirrors_ram": failed_ram is PackedByteArray and failed_stack is PackedByteArray \
					and (failed_ram as PackedByteArray).size() == RAM_SIZE \
					and (failed_stack as PackedByteArray).size() == 0x100 \
					and (failed_ram as PackedByteArray).slice(0x100, 0x200) == failed_stack}
			print("PASS_TERMINAL_BOUNDARY_REJECTED %s" % JSON.stringify(failed_context))
		return _fail_result("ROM-byte PASS confirmation waiter stopped at `$%04X`: %s" % [
			resume_pc, String(packet_result.get("error",
				_pass_confirmation_waiter_post_nmi_executor.error_message))])
	if resume_pc == 0xCCD1:
		return _continue_pass_confirmation_waiter_caller(dispatch, boundary, packet_result)
	if OS.get_environment("CT2_TRACE_PASS_WAITER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9078 and _last_external_nmi_frame <= 9090:
		var packet_registers: Dictionary = packet_result.get("registers", {})
		var packet_boundary_variant: Variant = packet_result.get("next_boundary_snapshot", {})
		var packet_boundary: Dictionary = packet_boundary_variant if packet_boundary_variant is Dictionary else {}
		var packet_ram_variant: Variant = packet_boundary.get("ram_image", PackedByteArray())
		var packet_stack_variant: Variant = packet_boundary.get("stack_page", PackedByteArray())
		var packet_ram: PackedByteArray = packet_ram_variant if packet_ram_variant is PackedByteArray else PackedByteArray()
		var packet_stack: PackedByteArray = packet_stack_variant if packet_stack_variant is PackedByteArray else PackedByteArray()
		print("PASS_WAITER_PACKET frame=%d entry=$%04X exit=$%04X resume=$%04X status=%s registers=%s ram0515_0518=%s stack0148=%02X" % [
			_last_external_nmi_frame, resume_pc, int(packet_result.get("exit_pc", -1)),
			int(packet_result.get("resume_pc_after_scheduler_jsr", -1)),
			String(packet_result.get("status", "")), JSON.stringify(packet_registers),
			packet_ram.slice(0x0515, 0x0519).hex_encode() if packet_ram.size() == RAM_SIZE else "invalid",
			int(packet_stack[0x48]) if packet_stack.size() == 0x100 else -1])
	if not _scheduler.adopt_slot05_pass_confirmation_wait_packet(dispatch, boundary, packet_result):
		return _fail_result("Scheduler rejected the ROM PASS waiter packet: " + _scheduler.error_message)
	var source_result := packet_result.duplicate(true)
	source_result["mapper"] = boundary.get("mapper", {}).duplicate(true)
	var yielded := _yield_slot05_source_task_callsite(source_result, true,
		"PASS confirmation waiter packet")
	if not bool(yielded.get("ok", false)):
		return yielded
	if OS.get_environment("CT2_TRACE_PASS_WAITER").strip_edges() == "1" \
			and _last_external_nmi_frame >= 9078 and _last_external_nmi_frame <= 9090:
		print("PASS_WAITER_YIELD frame=%d callsite=$%04X phase=%s awaiting_nmi=%s selected=%d selected_pc=$%04X delay=%d scans=%s" % [
			_last_external_nmi_frame, int(packet_result.get("exit_pc", -1)),
			String(yielded.get("phase", "")), str(yielded.get("awaiting_external_nmi", false)),
			int(yielded.get("next_selected_task_slot", -1)),
			int(yielded.get("next_selected_task_boundary", {}).get("pc", -1)),
			int(yielded.get("next_selected_task_boundary", {}).get("ready_delay", -1)),
			JSON.stringify(yielded.get("scheduler_scans", []))])
	if not _last_pass_receiver_confirmation_wait_result.is_empty():
		_last_pass_receiver_confirmation_wait_result["last_packet_resume"] = {
			"dispatch_pc": resume_pc,
			"packet_result": packet_result.duplicate(true),
			"scheduler_yield": yielded.duplicate(true),
		}
	var output := yielded.duplicate(true)
	output["status"] = "pass_confirmation_waiter_packet_yielded"
	output["source_task_result"] = packet_result.duplicate(true)
	output["pass_confirmation_waiter_packet_result"] = packet_result.duplicate(true)
	output["awaiting_external_nmi"] = bool(yielded.get("awaiting_external_nmi", false))
	output["holder_transfer_executed"] = false
	output["trace_state_used"] = false
	return output


func _continue_pass_confirmation_waiter_caller(dispatch: Dictionary,
		boundary: Dictionary, return_result: Dictionary) -> Dictionary:
	var returned_boundary_variant: Variant = return_result.get("next_boundary_snapshot", {})
	if not returned_boundary_variant is Dictionary:
		return _fail_result("PASS waiter `$CCD1 RTS` omitted its live `$D70F` continuation boundary.")
	var returned_boundary: Dictionary = returned_boundary_variant
	var cleanup_result: Dictionary = _pass_confirmation_waiter_post_nmi_executor.execute_waiter_caller_cleanup(
		returned_boundary)
	if not bool(cleanup_result.get("ok", false)):
		return _fail_result("ROM-byte PASS waiter caller cleanup stopped at `$D70F`: " \
			+ String(cleanup_result.get("error", _pass_confirmation_waiter_post_nmi_executor.error_message)))
	if not _scheduler.has_method("adopt_slot05_pass_confirmation_waiter_cleanup"):
		return _fail_result("Scheduler has no source-state adopter for the PASS waiter caller cleanup.")
	var adoption: Dictionary = _scheduler.call("adopt_slot05_pass_confirmation_waiter_cleanup",
		dispatch, boundary, return_result, cleanup_result)
	if not bool(adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the live PASS waiter `$CCD1->$D70F->$D568` return: " \
			+ String(adoption.get("error", _scheduler.error_message)))
	var field_entry_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var field_entry_result: Dictionary = _worker_prefix.resume_live_pass_waiter_field_continuation(
		field_entry_boundary, adoption)
	if not bool(field_entry_result.get("ok", false)):
		return _fail_result("ROM-byte PASS field continuation stopped at `$D568`: " \
			+ String(field_entry_result.get("error", _worker_prefix.error_message)) \
			+ " Source tail: %s" % str(field_entry_result.get("instruction_tail", [])))
	var field_entry_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_field_continuation(
		adoption, field_entry_boundary, field_entry_result)
	if not bool(field_entry_adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the source `$D568->$E07E` field continuation: " \
			+ String(field_entry_adoption.get("error", _scheduler.error_message)))
	var coordinate_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	var coordinate_result: Dictionary = _worker_prefix.execute_live_pass_waiter_coordinate_call(
		coordinate_boundary)
	if not bool(coordinate_result.get("ok", false)):
		return _fail_result("ROM-byte PASS field update `$E07E->$E709` stopped: " \
			+ String(coordinate_result.get("error", _worker_prefix.error_message)))
	var coordinate_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_coordinate_call(
		coordinate_boundary, coordinate_result)
	if not bool(coordinate_adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the natural `$E709 RTS->$E081` result: " \
			+ String(coordinate_adoption.get("error", _scheduler.error_message)))
	var e081_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	e081_boundary["source_dispatch_proof"] = coordinate_adoption.get("source_dispatch_proof", {}).duplicate(true)
	var e081_result: Dictionary = _pass_waiter_field_caller_e081_executor.execute_until_external_call(
		e081_boundary)
	if not bool(e081_result.get("ok", false)):
		return _fail_result("ROM-byte PASS E081 field caller stopped: " \
			+ String(e081_result.get("error", _pass_waiter_field_caller_e081_executor.error_message)))
	var e081_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_e081_callsite(
		e081_boundary, e081_result)
	if not bool(e081_adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the source `$E081->$E086` caller result: " \
			+ String(e081_adoption.get("error", _scheduler.error_message)))
	var e086_source_result := e081_result.duplicate(true)
	e086_source_result["mapper"] = e081_boundary.get("mapper", {}).duplicate(true)
	e086_source_result["call_request"] = e081_result.get("call_contract", {}).duplicate(true)
	var field_wait_yield: Dictionary = _yield_slot05_source_task_callsite(
		e086_source_result, false, "PASS field caller E081")
	if not bool(field_wait_yield.get("ok", false)):
		return field_wait_yield
	_last_pass_waiter_field_call_contract = e081_result.get("call_contract", {}).duplicate(true)
	var output := field_wait_yield.duplicate(true)
	output["status"] = "pass_waiter_field_caller_yielded_e086"
	output["pass_waiter_rts_result"] = return_result.duplicate(true)
	output["pass_waiter_caller_cleanup_result"] = cleanup_result.duplicate(true)
	output["pass_waiter_field_entry_result"] = field_entry_result.duplicate(true)
	output["pass_waiter_field_entry_adoption"] = field_entry_adoption.duplicate(true)
	output["pass_waiter_coordinate_result"] = coordinate_result.duplicate(true)
	output["pass_waiter_coordinate_adoption"] = coordinate_adoption.duplicate(true)
	output["pass_waiter_e081_result"] = e081_result.duplicate(true)
	output["pass_waiter_e081_adoption"] = e081_adoption.duplicate(true)
	output["e086_wait_call_result"] = e086_source_result.duplicate(true)
	output["holder_transfer_executed"] = false
	output["trace_state_used"] = false
	output["next_source_consumer_executed"] = true
	return output


func _resume_pass_waiter_e081_input_caller(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("slot_base", -1)) != SLOT_05 \
			or int(dispatch.get("pc", -1)) != 0xE089 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("bank_low", -1)) != 0x1A \
			or int(dispatch.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("pc", -1)) != 0xE089 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or _last_pass_waiter_field_call_contract.is_empty():
		return _fail_result("PASS E081 input-wait resume requires the scheduler's live `$E086->$CB0F RTS->$E089` dispatch.")
	var resume_contract := _last_pass_waiter_field_call_contract.duplicate(true)
	resume_contract["call_return_verified"] = true
	resume_contract["trace_state_used"] = false
	var current_boundary := boundary.duplicate(true)
	var caller_results: Array[Dictionary] = []
	var caller_adoptions: Array[Dictionary] = []
	var callee_results: Array[Dictionary] = []
	var callee_adoptions: Array[Dictionary] = []
	var final_call_contract: Dictionary = {}
	var final_source_result: Dictionary = {}
	var final_adoption: Dictionary = {}
	var yielded: Dictionary = {}
	for bridge_index in range(16):
		var source_result: Dictionary = _pass_waiter_field_caller_e081_executor.execute_until_external_call(
			current_boundary, resume_contract)
		if not bool(source_result.get("ok", false)):
			return _fail_result("ROM-byte PASS E081 input-wait resume stopped at `$%04X`: %s" % [
				int(current_boundary.get("pc", -1)),
				String(source_result.get("error", _pass_waiter_field_caller_e081_executor.error_message))])
		if String(source_result.get("status", "")) == "source_function_returned":
			var return_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_e081_function_return(
				current_boundary, source_result, resume_contract)
			if not bool(return_adoption.get("ok", false)):
				return _fail_result("Scheduler rejected PASS E081 natural RTS `$E0DE->$80F0`: " \
					+ String(return_adoption.get("error", _scheduler.error_message)))
			caller_results.append(source_result.duplicate(true))
			caller_adoptions.append(return_adoption.duplicate(true))
			final_source_result = source_result
			final_adoption = return_adoption
			var returned_boundary_variant: Variant = return_adoption.get("next_boundary_snapshot", {})
			if not returned_boundary_variant is Dictionary:
				return _fail_result("PASS E081 natural RTS has no scheduler-owned `$80F0` caller boundary.")
			var returned_boundary: Dictionary = returned_boundary_variant
			var caller_continuation: Dictionary = _worker_prefix.resume_slot05_worker_after_e081_return(
				returned_boundary, return_adoption, -1, 0xE0D1)
			if not bool(caller_continuation.get("ok", false)):
				return _fail_result("ROM-byte bank-$1A caller continuation from `$80F0` stopped: " \
					+ String(caller_continuation.get("error", _worker_prefix.error_message)))
			if String(caller_continuation.get("status", "")) == "slot05_source_task_yield_call_boundary":
				var scenario_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_e081_scenario_queue(
					returned_boundary, caller_continuation, return_adoption)
				if not bool(scenario_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM PASS `$18` scenario queue after E081: " \
						+ String(scenario_adoption.get("error", _scheduler.error_message)))
				caller_results.append(caller_continuation.duplicate(true))
				caller_adoptions.append(scenario_adoption.duplicate(true))
				final_source_result = caller_continuation
				final_adoption = scenario_adoption
				var scenario_yield_source := caller_continuation.duplicate(true)
				scenario_yield_source["call_request"] = scenario_adoption.get(
					"call_contract", {}).duplicate(true)
				yielded = _yield_slot05_source_task_callsite(scenario_yield_source,
					false, "PASS action scenario-$18", true)
				if not bool(yielded.get("ok", false)):
					return yielded
				_last_pass_waiter_field_call_contract.clear()
				break
			var caller_entry_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_e081_source_entry(
				returned_boundary, caller_continuation, return_adoption)
			if not bool(caller_entry_adoption.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM `$80F0->$E0D1` E081 caller boundary: " \
					+ String(caller_entry_adoption.get("error", _scheduler.error_message)))
			caller_results.append(caller_continuation.duplicate(true))
			caller_adoptions.append(caller_entry_adoption.duplicate(true))
			current_boundary = caller_entry_adoption.get("next_boundary_snapshot", {}).duplicate(true)
			resume_contract = caller_entry_adoption.get("resume_call_contract", {}).duplicate(true)
			continue
		var adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_e081_callsite(
			current_boundary, source_result, resume_contract)
		if not bool(adoption.get("ok", false)):
			return _fail_result("Scheduler rejected PASS E081 source call `$%04X`: %s" % [
				int(source_result.get("exit_pc", -1)),
				String(adoption.get("error", _scheduler.error_message))])
		caller_results.append(source_result.duplicate(true))
		caller_adoptions.append(adoption.duplicate(true))
		final_source_result = source_result
		final_adoption = adoption
		final_call_contract = source_result.get("call_contract", {}).duplicate(true)
		if int(source_result.get("exit_pc", -1)) == 0xE086:
			var source_yield := source_result.duplicate(true)
			source_yield["mapper"] = current_boundary.get("mapper", {}).duplicate(true)
			source_yield["call_request"] = final_call_contract.duplicate(true)
			yielded = _yield_slot05_source_task_callsite(
				source_yield, false, "PASS field caller E081")
			if not bool(yielded.get("ok", false)):
				return yielded
			_last_pass_waiter_field_call_contract = final_call_contract.duplicate(true)
			break
		var call_boundary_variant: Variant = adoption.get("next_boundary_snapshot", {})
		if not call_boundary_variant is Dictionary:
			return _fail_result("PASS E081 call `$%04X` has no scheduler-owned live callee boundary." % int(source_result.get("exit_pc", -1)))
		var call_boundary: Dictionary = call_boundary_variant
		var callee_result: Dictionary = _worker_prefix.execute_live_pass_waiter_rom_call(
			call_boundary, final_call_contract)
		if not bool(callee_result.get("ok", false)):
			return _fail_result("ROM-byte PASS E081 callee `$%04X->$%04X` stopped: %s" % [
				int(final_call_contract.get("callsite_pc", -1)),
				int(final_call_contract.get("target_pc", -1)),
				String(callee_result.get("error", _worker_prefix.error_message))])
		var callee_adoption: Dictionary = _scheduler.adopt_slot05_pass_waiter_rom_call_return(
			call_boundary, final_call_contract, callee_result)
		if not bool(callee_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected PASS E081 callee `$%04X`: %s" % [
				int(final_call_contract.get("target_pc", -1)),
				String(callee_adoption.get("error", _scheduler.error_message))])
		callee_results.append(callee_result.duplicate(true))
		callee_adoptions.append(callee_adoption.duplicate(true))
		current_boundary = callee_adoption.get("next_boundary_snapshot", {}).duplicate(true)
		resume_contract = final_call_contract.duplicate(true)
		resume_contract["call_return_verified"] = true
		resume_contract["trace_state_used"] = false
		if bridge_index == 15:
			return _fail_result("PASS E081 caller exceeded 16 verified ROM-call/return bridges before reaching its source input wait.")
	if yielded.is_empty():
		return _fail_result("PASS E081 source bridge loop ended without the ROM `$E086->$CB0F` input-wait callsite.")
	var output := yielded.duplicate(true)
	output["status"] = "pass_waiter_e081_scenario18_yielded" \
		if String(yielded.get("status", "")) == "pass_action_scenario_queue_yielded" \
		else "pass_waiter_e081_input_iteration_yielded"
	output["queued_scenario_id"] = 0x18 \
		if String(yielded.get("status", "")) == "pass_action_scenario_queue_yielded" else -1
	output["scenario_queue_call_contract"] = final_adoption.get("call_contract", {}).duplicate(true) \
		if String(yielded.get("status", "")) == "pass_action_scenario_queue_yielded" else {}
	output["pass_waiter_e081_resume_contract"] = _last_pass_waiter_field_call_contract.duplicate(true)
	output["pass_waiter_e081_results"] = caller_results
	output["pass_waiter_e081_adoptions"] = caller_adoptions
	output["pass_waiter_rom_callee_results"] = callee_results
	output["pass_waiter_rom_callee_adoptions"] = callee_adoptions
	output["pass_waiter_e081_result"] = final_source_result.duplicate(true)
	output["pass_waiter_e081_adoption"] = final_adoption.duplicate(true)
	output["source_task_result"] = final_source_result.duplicate(true)
	output["holder_transfer_executed"] = false
	output["trace_state_used"] = false
	return output


func _resume_slot05_field_minimap_wait(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var resume_result: Dictionary = _continuation.execute_field_minimap_wait_resume(
		dispatch, boundary)
	if not bool(resume_result.get("ok", false)):
		return _fail_result("ROM-byte minimap waiter did not resume from its live source state: " \
				+ _continuation.error_message)
	if String(resume_result.get("status", "")) == "minimap_loader_returned_to_bank18_worker":
		if not _scheduler.adopt_slot05_minimap_wait_resume_state(dispatch, boundary, resume_result):
			return _fail_result("Scheduler rejected the ROM-derived minimap loader return: " \
					+ _scheduler.error_message)
		var worker_mapper: Dictionary = resume_result.get("mapper", {}).duplicate(true)
		worker_mapper["select"] = int(worker_mapper.get("register_select", -1))
		var worker_entry := {
			"ok": true, "status": "minimap_loader_returned_to_bank18_worker",
			"rom_sha256": resume_result.get("rom_sha256", ""),
			"entry_pc": 0x800C, "exit_pc": 0x800C, "exit_bank": 0x18,
			"registers": resume_result.get("registers", {}).duplicate(true),
			"mapper": worker_mapper,
			"ram_image": resume_result.get("ram_image", PackedByteArray()).duplicate(),
			"stack_page": resume_result.get("stack_page", PackedByteArray()).duplicate(),
			"source_context": {"kind": "scenario1e_minimap_loader_return",
				"entry_pc": 0x82E3, "entry_bank": 0x1C, "renderer_descriptor": 0x30},
		}
		var worker_result: Dictionary = _worker_prefix.execute_to_yield_trampoline(worker_entry)
		if not bool(worker_result.get("ok", false)):
			return _fail_result("ROM-byte minimap descriptor-$30 worker failed: " \
					+ _worker_prefix.error_message)
		if not _scheduler.adopt_slot05_field_entry_worker_result(worker_entry, worker_result):
			return _fail_result("Scheduler rejected the ROM-derived minimap descriptor-$30 worker: " \
					+ _scheduler.error_message)
		return _yield_slot05_field_worker_callsite(worker_result)
	if not _scheduler.adopt_slot05_minimap_wait_resume_state(dispatch, boundary, resume_result):
		return _fail_result("Scheduler rejected the ROM-derived minimap waiter resume: " \
				+ _scheduler.error_message)
	return _yield_slot05_field_minimap_wait_callsite(resume_result)


func _yield_slot05_field_minimap_wait_callsite(minimap_result: Dictionary) -> Dictionary:
	return _yield_slot05_source_task_callsite(minimap_result, true)


func _yield_slot05_field_worker_callsite(worker_result: Dictionary,
		task_description: String = "descriptor-$30 worker") -> Dictionary:
	var calls: Array = worker_result.get("calls", [])
	var worker_yield_call: Dictionary = {}
	for call_variant in calls:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) == 0x8886 \
					and int(call.get("target", -1)) == 0xC515:
				if not worker_yield_call.is_empty():
					return _fail_result("ROM-byte field worker repeated its `$8886->$C515` yield callsite.")
				worker_yield_call = call
	if worker_yield_call.is_empty():
		return _fail_result("ROM-byte field worker omitted its source `$8886->$C515` call record.")
	var source_result := worker_result.duplicate(true)
	source_result["call_request"] = {"callsite_pc": int(worker_yield_call.get("callsite", -1)),
		"target_pc": int(worker_yield_call.get("target", -1))}
	return _yield_slot05_source_task_callsite(source_result, false, task_description)


func _yield_slot05_source_task_callsite(source_result: Dictionary,
		is_minimap_wait: bool, task_description: String = "descriptor-$30 worker",
		call_frame_already_pushed: bool = false) -> Dictionary:
	var registers: Dictionary = source_result.get("registers", {})
	var mapper: Dictionary = source_result.get("mapper", {})
	var call_request: Dictionary = source_result.get("call_request", {})
	var callsite_pc := int(call_request.get("callsite_pc", -1))
	var pass_confirmation_wait := task_description.begins_with("PASS confirmation waiter")
	var pass_field_caller_wait := task_description.begins_with("PASS field caller")
	var pass_action_scenario_queue_wait := task_description.begins_with("PASS action scenario")
	var pass_scenario18_field_update_wait := task_description.begins_with(
		"PASS scenario-$18 field update")
	var callsite_supported := (callsite_pc in [0xCC50, 0xCCA0, 0xCCCE, 0x82E0] \
		if is_minimap_wait or pass_confirmation_wait else callsite_pc == 0x8886 \
			and int(call_request.get("target_pc", -1)) == 0xC515)
	if pass_field_caller_wait:
		callsite_supported = callsite_pc == 0xE086 \
			and int(call_request.get("target_pc", -1)) == 0xCB0F
	if pass_action_scenario_queue_wait:
		callsite_supported = callsite_pc == 0xCBBE \
			and int(call_request.get("target_pc", -1)) == 0xCB0F \
			and call_frame_already_pushed
	if pass_scenario18_field_update_wait:
		callsite_supported = callsite_pc == 0xE775 \
			and int(call_request.get("target_pc", -1)) == 0xCB0F \
			and call_frame_already_pushed
	if not callsite_supported:
		return _fail_result("ROM-byte source task returned an unsupported callsite `$%04X`." % callsite_pc)
	var caller_stack_pointer := int(registers.get("sp", -1))
	if pass_action_scenario_queue_wait or pass_scenario18_field_update_wait:
		caller_stack_pointer = int(call_request.get("sp_before_push", -1))
	if not _scheduler.yield_at_verified_callsite(SLOT_05, callsite_pc,
			int(registers.get("a", -1)), caller_stack_pointer,
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			call_frame_already_pushed):
		return _fail_result("Slot-$05 could not save the ROM `$%04X->$%04X` source task: %s" % [callsite_pc,
			int(call_request.get("target_pc", -1)), _scheduler.error_message])
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after the source task yield failed: " + _scheduler.error_message)
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
			return _fail_result("Scheduler did not expose the next task after the source task yield.")
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary) \
			if next_slot == SLOT_09 else {}
		if next_slot == SLOT_09 and _pending_selected_task_mapper.is_empty():
			return _fail_result("Selected slot-$09 boundary omitted its ROM-owned mapper context after the source task yield.")
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X after source task yield" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty():
			return _fail_result("Source task yielded to NMI without its source queue signature.")
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CB0F slot-$05 %s `$%04X` -> scheduler WAIT_FOR_NMI_READY" % [
			"minimap wait" if is_minimap_wait else task_description, callsite_pc]
		waiting_for_nmi = true
	else:
		return _fail_result("Scheduler ended at an unsupported source task decision: %s" % str(scan))
	var yield_status := "slot05_minimap_wait_yielded" if is_minimap_wait else \
		("pass_receiver_descriptor_0f_first_yield_saved" if task_description == "PASS receiver descriptor-$0F first worker" else \
		("pass_receiver_descriptor_1d_first_yield_saved" if task_description == "PASS receiver descriptor-$1D first worker" else "slot05_minimap_worker_yielded"))
	if pass_confirmation_wait:
		yield_status = "pass_confirmation_waiter_busy_poll_yielded"
	elif pass_field_caller_wait:
		yield_status = "pass_field_caller_input_wait_yielded"
	elif pass_action_scenario_queue_wait:
		yield_status = "pass_action_scenario_queue_yielded"
	return {"ok": true, "status": yield_status,
		"phase": _phase, "rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"slot05_minimap_wait_result": source_result.duplicate(true) if is_minimap_wait else {},
		"slot05_minimap_worker_result": source_result.duplicate(true) if not is_minimap_wait \
				and task_description == "descriptor-$30 worker" else {},
		"source_task_result": source_result.duplicate(true) if not is_minimap_wait else {},
		"slot05_yield_boundary": _scheduler.get_task_boundary_snapshot(SLOT_05),
		"post_slot05_scan_results": scan_results,
		"post_slot05_scan": scan,
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary,
		"awaiting_external_nmi": waiting_for_nmi,
		"external_nmi_consumed": false,
		"nmi_cadence_generated": false,
		"ppu_bus_events_applied": false}


func _is_slot05_scenario1c_handoff_return(dispatch: Dictionary,
		boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var sp := int(dispatch.get("sp", -1))
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0xCBC1 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or sp != 0x4E or int(dispatch.get("source_return_word", -1)) != 0xE944 \
			or int(dispatch.get("bank_low", -1)) != 0x1A \
			or int(dispatch.get("bank_high", -1)) != 0x1B \
			or not ram is PackedByteArray or ram.size() != 0x800 \
			or int(ram[0x0518]) != 0x1C \
			or not stack is PackedByteArray or stack.size() != 0x100:
		return false
	var return_word := int(stack[(sp + 1) & 0xFF]) \
		| (int(stack[(sp + 2) & 0xFF]) << 8)
	return return_word == 0xDE8F


func _resume_slot05_scenario1c_handoff(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var return_result: Dictionary = _slot05_scenario35_return_executor.execute_from_live_dispatch(
		dispatch, boundary)
	if not bool(return_result.get("ok", false)):
		return _fail_result("ROM-byte scenario-$1C `$CBC1 RTS->$DE90` stopped: " \
				+ String(return_result.get("error", _slot05_scenario35_return_executor.error_message)))
	if not _scheduler.adopt_slot05_scenario35_return_state(dispatch, boundary, return_result):
		return _fail_result("Scheduler rejected the live scenario-$1C `$DE8F` return: " \
				+ _scheduler.error_message)
	var tail_result: Dictionary = _slot05_scenario35_return_executor.execute_scenario1c_handoff_tail(
		return_result)
	if not bool(tail_result.get("ok", false)):
		return _fail_result("ROM-byte scenario-$1C `$DE90->$E0DF` tail stopped: " \
				+ String(tail_result.get("error", _slot05_scenario35_return_executor.error_message)))
	if not _scheduler.adopt_slot05_scenario1c_handoff_tail(return_result, tail_result):
		return _fail_result("Scheduler rejected the ROM scenario-$1C `$DE90->$E0DF` tail: " \
				+ _scheduler.error_message)
	var result := _execute_slot05_e0df_field_entry(tail_result, 0x1C)
	if bool(result.get("ok", false)):
		result["slot05_cbc1_return_result"] = return_result.duplicate(true)
	return result


func _resume_slot05_scenario36_queue_return(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var return_result: Dictionary = _scenario36_queue_executor.execute_post_queue_handoff(
		dispatch, boundary)
	if not bool(return_result.get("ok", false)):
		return _fail_result("ROM-byte scenario-$36 `$CBC1->$DB13->$E0DF` handoff stopped: " \
				+ String(return_result.get("error", _scenario36_queue_executor.error_message)))
	if not _scheduler.adopt_slot05_scenario36_queue_return_state(dispatch, boundary, return_result):
		return _fail_result("Scheduler rejected the ROM-derived scenario-$36 `$DB13->$E0DF` handoff: " \
				+ _scheduler.error_message)
	return _execute_slot05_e0df_field_entry(return_result, 0x36)


func _execute_slot05_e0df_field_entry(handoff_result: Dictionary,
		source_scenario: int) -> Dictionary:
	var renderer_entry: Dictionary = _continuation.execute_field_entry_first_wrapper(handoff_result)
	if not bool(renderer_entry.get("ok", false)):
		return _fail_result("ROM-byte field-entry wrapper did not reach bank-$18 `$800C`: " \
				+ _continuation.error_message)
	if not _scheduler.adopt_slot05_field_entry_worker_entry(handoff_result, renderer_entry):
		return _fail_result("Scheduler rejected the ROM-derived `$E0DF->$EF7F->$800C` renderer entry: " \
				+ _scheduler.error_message)
	var renderer_worker: Dictionary = _worker_prefix.execute_to_yield_trampoline(renderer_entry)
	if not bool(renderer_worker.get("ok", false)):
		return _fail_result("ROM-byte descriptor-$00 `$800C->$8851` worker failed: " \
				+ _worker_prefix.error_message)
	if not _scheduler.adopt_slot05_field_entry_worker_result(renderer_entry, renderer_worker):
		return _fail_result("Scheduler rejected the ROM-derived descriptor-$00 worker writes: " \
				+ _scheduler.error_message)
	var worker_registers: Dictionary = renderer_worker.get("registers", {})
	var worker_mapper: Dictionary = renderer_worker.get("mapper", {})
	if not _scheduler.yield_at_verified_callsite(SLOT_05, 0x8886,
			int(worker_registers.get("a", -1)), int(worker_registers.get("sp", -1)),
			int(worker_registers.get("x", -1)), int(worker_registers.get("y", -1)),
			int(worker_mapper.get("bank_low", -1)), int(worker_mapper.get("bank_high", -1))):
		return _fail_result("Descriptor-$00 worker could not save its ROM `$8886->$C515->$CB0F` continuation: " \
				+ _scheduler.error_message)
	var post_worker_scan_results: Array[Dictionary] = []
	var post_worker_scan: Dictionary = {}
	for scan_index in range(8):
		post_worker_scan = _scheduler.scan_ready_tasks_once()
		if not bool(post_worker_scan.get("ok", false)):
			return _fail_result("Scheduler scan after the descriptor-$00 worker yield failed: " \
					+ _scheduler.error_message)
		post_worker_scan_results.append(post_worker_scan.duplicate(true))
		if int(post_worker_scan.get("decision", -1)) \
				!= int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
			break
	if post_worker_scan.is_empty() or int(post_worker_scan.get("decision", -1)) \
			== int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
		return _fail_result("Scheduler did not finish its bounded post-yield scan after the descriptor-$00 worker.")
	var selected_post_yield_slot := int(post_worker_scan.get("selected_slot_base", -1))
	if int(post_worker_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		if selected_post_yield_slot != SLOT_09:
			return _fail_result("Descriptor-$00 post-yield scheduler selected unsupported slot `$%02X`." % selected_post_yield_slot)
		_pending_selected_task_slot = selected_post_yield_slot
		_pending_selected_task_boundary = _scheduler.get_task_boundary_snapshot(selected_post_yield_slot)
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(_pending_selected_task_boundary)
		if _pending_selected_task_boundary.is_empty() or _pending_selected_task_mapper.is_empty():
			return _fail_result("The post-worker slot-$09 boundary lacks its live mapper/task snapshot.")
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 scenario `$%02X` slot `$05` save selected slot `$09` before task body" % source_scenario
	elif int(post_worker_scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_selected_task_slot = -1
		_pending_selected_task_boundary.clear()
		_pending_selected_task_mapper.clear()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "descriptor-$00 slot-$05 saved at `$CB0F`; scheduler WAIT_FOR_NMI_READY"
	else:
		return _fail_result("Descriptor-$00 post-yield scheduler returned an unsupported decision $%02X." % int(post_worker_scan.get("decision", -1)))
	return {
		"ok": true,
		"status": "scenario%02X_descriptor00_worker_yielded_and_scanned" % source_scenario,
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"handoff_result": handoff_result.duplicate(true),
		"renderer_entry_result": renderer_entry.duplicate(true),
		"renderer_worker_result": renderer_worker.duplicate(true),
		"post_worker_scan": post_worker_scan.duplicate(true),
		"post_worker_scan_results": post_worker_scan_results.duplicate(true),
		"slot05_after_worker_yield": _scheduler.get_task_boundary_snapshot(SLOT_05),
		"scheduler_status": _scheduler.get_status(),
		"external_nmi_consumed": true,
		"nmi_cadence_generated": false,
		"next_external_nmi_required": false,
	}


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
	var worker_manifest_sha256 := String(worker.get("source_manifest_sha256", ""))
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
			or String(worker.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json" \
			or worker_manifest_sha256.is_empty() \
			or worker_manifest_sha256 != _worker_prefix.source_manifest_sha256():
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
	var input_registers: Dictionary = worker_input.get("registers", {})
	var stopped_pc := int(worker_result.get("exit_pc", input_registers.get("pc", dispatch.get("pc", -1))))
	var instruction_trace: Array = worker_result.get("instructions", [])
	var trace_tail: Array[String] = []
	for index in range(maxi(0, instruction_trace.size() - 8), instruction_trace.size()):
		var instruction_variant: Variant = instruction_trace[index]
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			trace_tail.append("$%04X/bank$%02X->$%04X[%02X]" % [
				int(instruction.get("pc", -1)), int(instruction.get("bank", -1)),
				int(instruction.get("next_pc", -1)), int(instruction.get("opcode", -1))])
	var calls: Array = worker_result.get("calls", [])
	var last_call: Dictionary = calls.back() if not calls.is_empty() else {}
	_last_source_boundary = "slot-$05 live dispatch `$8889`; worker resume stopped at `$%04X` (%s), last call `$%04X->$%04X` bank `$%02X`, trace=%s" % [
		stopped_pc, status, int(last_call.get("callsite", -1)),
		int(last_call.get("target", -1)), int(last_call.get("bank", -1)), str(trace_tail)]
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


func _trace_rng_field_worker(source_frame: int, entry_label: String,
		route_result: Dictionary) -> void:
	if OS.get_environment("CT2_TRACE_RNG_FIELD_WORKER").strip_edges() != "1" \
			or source_frame < 9087 or source_frame > 9089:
		return
	var worker: Dictionary = route_result.get("slot05_worker_result", {})
	var worker_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var entry_ram: PackedByteArray = worker.get("entry_ram_image", PackedByteArray())
	var rng_writes: Array[Dictionary] = []
	var executed_a103 := false
	for span_variant in worker.get("executed_source_spans", []):
		if span_variant is Dictionary \
				and String((span_variant as Dictionary).get("file", "")) \
				== "bank1b_field_update_A103_A1EB.bin":
			executed_a103 = true
	for write_variant in worker.get("writes", []):
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) in [0x00E1, 0x00E2, 0x00E3]:
				rng_writes.append(write.duplicate(true))
	print("RNG_FIELD_WORKER source_frame=%d entry=%s status=%s exit=$%04X entry_e1e2e3=%s output_e1e2e3=%s executed_a103=%s writes=%s" % [
		source_frame, entry_label, String(worker.get("status", "")),
		int(worker.get("exit_pc", -1)),
		entry_ram.slice(0x00E1, 0x00E4).hex_encode() if entry_ram.size() == RAM_SIZE else "missing",
		worker_ram.slice(0x00E1, 0x00E4).hex_encode() if worker_ram.size() == RAM_SIZE else "missing",
		executed_a103,
		JSON.stringify(rng_writes)])


## Resumes scenario `$44`'s live slot-$05 packet producer from `$F01B`.
func _resume_slot05_scenario44_field_entry(dispatch: Dictionary,
		boundary: Dictionary) -> Dictionary:
	var resume_pc := int(dispatch.get("pc", -1))
	if _scenario44_field_entry_worker_result.is_empty() \
			or _pending_slot05_mapper_select < 0 or _pending_slot05_mapper_select > 0xFF:
		return _fail_result("Scenario-$44 packet-producer resume lacks its prior source boundary or MMC3 selector.")
	var worker_input := {
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": SLOT_05,
			"resume_path": "yielded_rts", "pc": resume_pc,
			"bank": 0x1E if resume_pc in [0xD5C0, 0xCC53, 0xCCA3, 0xCCD1] else 0x1F,
			"source_dispatch_observed": true},
		"registers": {"a": int(dispatch.get("a", -1)), "x": int(dispatch.get("x", -1)),
			"y": int(dispatch.get("y", -1)), "p": int(dispatch.get("p", 0)),
			"p_known_mask": int(dispatch.get("p_known_mask", 0xFF)),
			"sp": int(dispatch.get("sp", -1)), "pc": int(dispatch.get("pc", -1))},
		"mapper": {"bank_low": int(dispatch.get("bank_low", -1)),
			"bank_high": int(dispatch.get("bank_high", -1)),
			"select": _pending_slot05_mapper_select},
		"ram_image": boundary.get("ram_image", PackedByteArray()),
		"stack_page": boundary.get("stack_page", PackedByteArray()),
	}
	var worker_result: Dictionary = _worker_prefix.resume_scenario44_field_entry_worker(
		worker_input, _scenario44_field_entry_worker_result)
	if not bool(worker_result.get("ok", false)) \
			or String(worker_result.get("status", "")) != "scenario44_field_entry_resume_source_call_boundary":
		return _fail_result("Scenario-$44 ROM packet producer did not reach its next supported `$CB0F` yield: " \
			+ String(worker_result.get("error", _worker_prefix.error_message)) \
			+ " state=" + JSON.stringify({"status": worker_result.get("status", ""),
				"exit_pc": worker_result.get("exit_pc", -1),
				"blocked_read": worker_result.get("blocked_read", {}),
				"unsupported_opcode": worker_result.get("unsupported_opcode", {})}))
	if int(worker_result.get("exit_pc", -1)) == 0xC515:
		if not _scheduler.adopt_slot05_scenario44_field_worker_resume_yield(
				boundary, _scenario44_field_entry_worker_result, worker_result):
			return _fail_result("Scheduler rejected the ROM `$8886->$C515` field-renderer continuation: " \
				+ _scheduler.error_message)
		var worker_yield_result := _yield_slot05_field_worker_callsite(worker_result)
		if bool(worker_yield_result.get("ok", false)):
			_scenario44_field_entry_worker_result.clear()
		return worker_yield_result
	if int(worker_result.get("exit_pc", -1)) != 0xCB0F:
		return _fail_result("Scenario-$44 worker stopped at unsupported boundary `$%04X`." % int(worker_result.get("exit_pc", -1)))
	if not _scheduler.adopt_slot05_scenario44_field_entry_resume_yield(
			boundary, _scenario44_field_entry_worker_result, worker_result):
		return _fail_result("Scheduler rejected the resumed ROM `$F018->$CB0F` packet-producer yield: " \
			+ _scheduler.error_message)
	_scenario44_field_entry_worker_result = worker_result.duplicate(true)
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	_phase = "awaiting_external_nmi"
	_last_source_boundary = "Scenario-$44 packet producer resumed from `$F01B` and saved at `$F018->$CB0F`"
	return {"ok": true, "status": "scenario44_field_entry_resume_yield_saved",
		"phase": _phase, "rom_sha256": ROM_SHA256,
		"last_source_boundary": _last_source_boundary,
		"slot05_worker_result": worker_result.duplicate(true),
		"slot05_yield_result": _scheduler.get_task_boundary_snapshot(SLOT_05),
		"awaiting_external_nmi": true, "next_external_nmi_required": true,
		"ppu_cycle_timing_modeled": false, "audio_effects_modeled": false}


## Resume only the slot-$09 yielded context selected by the live scheduler scan
## after resume_selected_slot05_worker(). The task body and its callback/worker
## results remain source-checked; the next task body or NMI cadence is not run.
func resume_selected_slot09_worker() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_09 \
			or _last_source_boundary not in ["$CAA5 selected slot $09 before task-body source",
				"$CAA5 scenario `$36` slot `$05` save selected slot `$09` before task body",
				"$CAA5 scenario `$1C` slot `$05` save selected slot `$09` before task body",
				"$CAA5 selected slot $09 after root slot-$01 yield",
				"$CAA5 selected slot $09 after `$E40F` field-input yield",
				"$CAA5 selected slot $09 after `$E147->$CB0F` field-input yield",
				"$CAA5 selected slot $09 after `$CBBE->$CB0F` field-input yield",
				"$CAA5 selected slot $09 after minimap wait",
				"$CAA5 selected slot $09 after source task yield",
				"$CAA5 selected slot $09 after PASS confirmation yield",
				"$CAA5 selected slot $09 after PASS receiver renderer wait yield",
			"$CAA5 selected slot $09 after slot-$09 save; before task body",
			"$CA4F->$CB0F slot-$01 save; scheduler selected slot $09",
				"$CAA5 selected slot $09 after scenario44 field-entry yield",
				"PASS `$CBBE->$CB0F` save; `$CAA5` selected slot $09"]:
		return _fail_result("Slot-$09 resume requires a supported live pre-dispatch boundary: phase=%s slot=$%02X source=`%s`." % [
			_phase, _pending_selected_task_slot, _last_source_boundary])
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
	if bool(slot09_resume_result.get("scenario_idle_worker_vector_profile_matches", false)):
		slot09_resume_result["scenario_idle_worker_vector_ready"] = true
	_last_slot09_resume_input_debug = _summarize_slot09_resume_input(slot09_resume_result)
	_last_slot09_resume_input_debug["dispatch_entry_0516_0539"] = dispatch_ram.slice(0x0516, 0x053A).hex_encode()
	_last_slot09_resume_input_debug["dispatch_entry_003a"] = int(dispatch_ram[0x003A])
	_last_slot09_resume_input_debug["idle_worker_vector_ready"] = bool(
		slot09_resume_result.get("scenario_idle_worker_vector_ready", false))
	_last_slot09_resume_input_debug["idle_worker_vector_profile_matches"] = bool(
		slot09_resume_result.get("scenario_idle_worker_vector_profile_matches", false))
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
	elif bool(slot09_resume_result.get("ok", false)) \
			and String(slot09_resume_result.get("status", "")) == "scenario2e_event_seeded_at_ec74_return":
		if not _scheduler.adopt_slot09_scenario_active_prefix_state(slot09_resume_result):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$2E `$EC74 RTS->$EB9E` return: " + _scheduler.error_message)
		var scenario2e_seed_contract: Dictionary = slot09_resume_result.get("scenario_seed_request", {})
		var scenario2e_slot15_seed: Dictionary = _scheduler.seed_scenario_callback_task(
			int(scenario2e_seed_contract.get("setup_cpu_address", -1)))
		if not bool(scenario2e_slot15_seed.get("ok", false)) \
				or int(scenario2e_slot15_seed.get("slot_base", -1)) != SLOT_15 \
				or int(scenario2e_slot15_seed.get("callback_reader_pc", -1)) != 0x814C:
			return _fail_result("Scheduler rejected the ROM-derived scenario-$2E slot-$15 callback seed: " \
				+ _scheduler.error_message + " " + str(scenario2e_slot15_seed))
		preseeded_slot15_result = scenario2e_slot15_seed.duplicate(true)
		var scenario2e_event_boundary := slot09_resume_result.duplicate(true)
		var scenario2e_live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_09)
		var scenario2e_post_event_result: Dictionary = _slot09_continuation_prefix.resume_scenario2e_after_event(
			scenario2e_live_boundary, scenario2e_event_boundary)
		if not bool(scenario2e_post_event_result.get("ok", false)) \
				or int(scenario2e_post_event_result.get("exit_pc", -1)) != 0x86F8:
			return _fail_result("Scenario `$2E` caller did not resume from `$EB9E` to its `$86F8` worker vector: " \
				+ String(scenario2e_post_event_result.get("error", _slot09_continuation_prefix.error_message)))
		slot09_resume_result = scenario2e_post_event_result
	if bool(slot09_resume_result.get("scenario_post_callback_executed", false)):
		if not _scheduler.adopt_slot09_post_callback_prefix_state(slot09_resume_result):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$36 post-callback prefix writes: " + _scheduler.error_message)
	if bool(slot09_resume_result.get("ok", false)) \
			and (bool(slot09_resume_result.get("scenario_wait_worker_executed", false)) \
				or bool(slot09_resume_result.get("scenario_route_state_executed", false)) \
				or bool(slot09_resume_result.get("scenario_idle_worker_vector_ready", false))) \
			and not bool(slot09_resume_result.get("scenario_post_callback_executed", false)) \
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
	var live_pass_prefix_ram: Variant = slot09_resume_result.get("ram_image", PackedByteArray())
	var live_pass_stream_pointer := (int(live_pass_prefix_ram[0x0079]) \
			| (int(live_pass_prefix_ram[0x007A]) << 8)) \
			if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == 0x800 else -1
	var live_pass_stream_countdown := int(live_pass_prefix_ram[0x0533]) \
			if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == 0x800 else -1
	var live_pass_stream_phase := (live_pass_stream_pointer == 0xAFE9 \
			and live_pass_stream_countdown in [0x00, 0x01, 0x02, 0x03]) \
		or (live_pass_stream_pointer == 0xAFEE \
			and live_pass_stream_countdown in [0x00, 0x01]) \
		or (live_pass_stream_pointer == 0xAFF1 \
			and live_pass_stream_countdown in [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]) \
		or (live_pass_stream_pointer == 0xAFF4 \
			and live_pass_stream_countdown in [0x00, 0x01, 0x02, 0x03])
	var live_pass_scenario38_prefix: bool = live_pass_prefix_ram is PackedByteArray \
			and live_pass_prefix_ram.size() == 0x800 \
			and String(slot09_resume_result.get("status", "")) == "stopped_before_worker_body" \
			and int(slot09_resume_result.get("entry_pc", -1)) == 0xEB8B \
			and live_pass_prefix_ram.slice(0x0516, 0x051A) == PackedByteArray([0x00, 0x40, 0x38, 0x00]) \
			and int(live_pass_prefix_ram[0x0441]) == 0x06 \
			and int(live_pass_prefix_ram[0x0532]) == 0x01 \
			and live_pass_stream_phase \
			and int(live_pass_prefix_ram[0x0498]) == 0x00 \
			and live_pass_prefix_ram.slice(0x0499, 0x04A0) \
			== PackedByteArray([0x00, 0x6C, 0x04, 0x00, 0x6C, 0x04, 0x00]) \
			and int(live_pass_prefix_ram[0x047F]) == 0x0F
	if live_pass_scenario38_prefix \
			and not _scheduler.adopt_slot09_live_pass_scenario38_worker_vector_state(slot09_resume_result):
		return _fail_result("Scheduler rejected the live PASS scenario-$38 `$EB8B->$86F8` source prefix: " \
				+ _scheduler.error_message)
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
	var slot09_live_ram_variant: Variant = slot09_resume_result.get("ram_image", PackedByteArray())
	var is_live_scenario18_callback72_worker: bool = slot09_live_ram_variant is PackedByteArray \
			and slot09_live_ram_variant.size() == 0x800 \
			and slot09_live_ram_variant.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x00, 0x18]) \
			and int(slot09_live_ram_variant[0x0519]) >= 0x28 \
			and int(slot09_live_ram_variant[0x0519]) <= 0x3C \
			and int(slot09_live_ram_variant[0x003A]) == 0x06 \
			and int(slot09_live_ram_variant[0x0522]) == 0x00 \
			and slot09_live_ram_variant.slice(0x005D, 0x005F) == PackedByteArray([0x58, 0xAF]) \
			and slot09_live_ram_variant.slice(0x0523, 0x052A) == PackedByteArray([
				0x3C, 0x72, 0x02, 0x3C, 0x4A, 0x66, 0x47]) \
			and int(slot09_live_ram_variant[0x0539]) == 0x00 \
			and slot09_live_ram_variant.slice(0x05C7, 0x05D3) == PackedByteArray([
				0x24, 0xC0, 0x00, 0x00, 0x01, 0x11, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])
	var is_live_scenario_worker: bool = slot09_live_ram_variant is PackedByteArray \
			and slot09_live_ram_variant.size() == 0x800 \
			and (int(slot09_live_ram_variant[0x0518]) in [0x1C, 0x1E, 0x36, 0x38, 0x44] \
				or is_live_scenario18_callback72_worker)
	var scenario_worker_id := int(slot09_live_ram_variant[0x0518]) if is_live_scenario_worker else -1
	var scenario_worker_chain: Array = [slot09_86f8_result,
		slot09_8779_result, slot09_87e6_result]
	var scenario_chain_ram_variant: Variant = slot09_87e6_result.get("ram_image", PackedByteArray())
	var scenario_worker_ram_changed := false
	if slot09_live_ram_variant is PackedByteArray and scenario_chain_ram_variant is PackedByteArray \
			and slot09_live_ram_variant.size() == 0x800 and scenario_chain_ram_variant.size() == 0x800:
		for address in range(0x800):
			if address in [0x0023, 0x0024, 0x0025] or address in range(0x0100, 0x0200):
				continue
			if int(slot09_live_ram_variant[address]) != int(scenario_chain_ram_variant[address]):
				scenario_worker_ram_changed = true
				break
	if slot11_seed_result.is_empty() and is_live_scenario_worker \
			and (scenario_worker_ram_changed or scenario_worker_id in [0x1C, 0x1E] \
			or bool(slot09_resume_result.get("scenario_post_callback_executed", false))):
		if not _scheduler.adopt_slot09_scenario_worker_chain_state(scenario_worker_chain, scenario_worker_id):
			return _fail_result("Scheduler rejected the ROM-derived scenario-$%02X worker writes: " % scenario_worker_id \
				+ _scheduler.error_message + " resume=" + JSON.stringify({
					"status": slot09_resume_result.get("status", ""),
					"entry_pc": slot09_resume_result.get("entry_pc", -1),
					"exit_pc": slot09_resume_result.get("exit_pc", -1),
					"active": slot09_resume_result.get("scenario_active", false),
					"route_state": slot09_resume_result.get("scenario_route_state_executed", false),
					"idle_worker_vector": slot09_resume_result.get("scenario_idle_worker_vector_ready", false),
					"wait_worker": slot09_resume_result.get("scenario_wait_worker_executed", false),
					"post_callback": slot09_resume_result.get("scenario_post_callback_executed", false),
					"live_pass_scenario38_profile": live_pass_scenario38_prefix,
					"ram_003a": int(live_pass_prefix_ram[0x003A]) if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else -1,
					"ram_0441": int(live_pass_prefix_ram[0x0441]) if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else -1,
					"ram_047f": int(live_pass_prefix_ram[0x047F]) if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else -1,
					"ram_0516_0519": live_pass_prefix_ram.slice(0x0516, 0x051A).hex_encode() if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else "invalid",
					"ram_0532_0533": live_pass_prefix_ram.slice(0x0532, 0x0534).hex_encode() if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else "invalid",
					"ram_0079_007a": live_pass_prefix_ram.slice(0x0079, 0x007B).hex_encode() if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else "invalid",
					"ram_0498_04a0": live_pass_prefix_ram.slice(0x0498, 0x04A0).hex_encode() if live_pass_prefix_ram is PackedByteArray and live_pass_prefix_ram.size() == RAM_SIZE else "invalid",
					"seed_request": slot09_resume_result.get("scenario_seed_request", {}),
				}))
	if not slot11_seed_result.is_empty():
		var actor_worker_chain: Array = [slot09_86f8_result, slot09_8779_result, slot09_87e6_result]
		if not _scheduler.adopt_slot09_actor_seeded_root_loop_entry_state(actor_worker_chain, slot09_root_zero_result):
			return _fail_result("Scheduler rejected the ROM-derived actor-seeded slot-$09 root-loop boundary: " + _scheduler.error_message)
	elif bool(slot09_resume_result.get("scenario_active", false)) \
			or bool(slot09_resume_result.get("scenario_route_state_executed", false)) \
			or bool(slot09_resume_result.get("scenario_wait_worker_executed", false)) \
			or bool(slot09_resume_result.get("scenario_post_callback_executed", false)):
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
			var slot15_ram: PackedByteArray = next_boundary.get("ram_image", PackedByteArray())
			var scenario2e_callback_seed := slot15_ram.size() > 0x0524 \
					and int(slot15_ram[0x0518]) == 0x2E and int(slot15_ram[0x0524]) == 0x36
			var scenario44_callback_seed := slot15_ram.size() > 0x0524 \
					and int(slot15_ram[0x0518]) == 0x44 and int(slot15_ram[0x0524]) == 0x70
			var scenario1c_callback_seed := slot15_ram.size() > 0x0524 \
					and int(slot15_ram[0x0518]) == 0x1C and int(slot15_ram[0x0524]) == 0x1F
			var scenario38_callback_seed := slot15_ram.size() > 0x0524 \
					and int(slot15_ram[0x0518]) == 0x38 and int(slot15_ram[0x0524]) == 0x34
			var scenario18_callback_seed := slot15_ram.size() > 0x0524 \
					and int(slot15_ram[0x0518]) == 0x18 and int(slot15_ram[0x0524]) == 0x72
			var expected_slot15_record := PackedByteArray([0xFF, 0xF0, 0x0B, 0x12]) \
				if scenario2e_callback_seed or scenario44_callback_seed or scenario1c_callback_seed else (PackedByteArray([0xFF, 0xF0, 0x0B, 0x13]) \
				if scenario38_callback_seed or scenario18_callback_seed else PackedByteArray([0xFF, 0xF0, 0x0B, 0x00]))
			if int(next_boundary.get("sp", -1)) != 0xF0 \
					or int(next_boundary.get("bank_low", -1)) != 0x0B \
					or next_boundary.get("record", PackedByteArray()) != expected_slot15_record \
					or slot15_stack.size() != 0x100 \
					or int(slot15_stack[0xF1]) != 0x08 or int(slot15_stack[0xF2]) != 0x80:
				return _fail_result("Post-save scheduler selected an unsupported initial slot-$15 callback boundary: scenario=$%02X callback=$%02X SP=$%02X bank=$%02X record=%s return=$%02X%02X." % [
					int(slot15_ram[0x0518]) if slot15_ram.size() > 0x0524 else -1,
					int(slot15_ram[0x0524]) if slot15_ram.size() > 0x0524 else -1,
					int(next_boundary.get("sp", -1)), int(next_boundary.get("bank_low", -1)),
					(next_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
					int(slot15_stack[0xF2]) if slot15_stack.size() == 0x100 else -1,
					int(slot15_stack[0xF1]) if slot15_stack.size() == 0x100 else -1])
		elif next_slot == SLOT_11:
			var actor_record: PackedByteArray = next_boundary.get("record", PackedByteArray())
			if int(next_boundary.get("sp", -1)) != 0xC8 \
					or int(next_boundary.get("bank_low", -1)) != 0x18 \
					or int(next_boundary.get("bank_high", -1)) != 0x19 \
					or actor_record.size() != 4 \
					or actor_record.slice(0, 3) != PackedByteArray([0xFF, 0xC8, 0x18]):
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
	if record.size() != 4 or record.slice(0, 3) != PackedByteArray([0xFF, 0xC8, 0x18]) \
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
	var event_queue_record := PackedByteArray([0x00, 0xC1, 0x18, 0x19])
	var parameter47_f2_tail_record := PackedByteArray([0x00, 0xC2, 0x18, 0x19])
	var animation_record := PackedByteArray([0x00, 0xC2, 0x1A, 0x1B])
	var packet_wait_record := PackedByteArray([0x00, 0xC4, 0x18, 0x19])
	var live_record: PackedByteArray = live_boundary.get("record", PackedByteArray())
	var is_animation_resume := live_record == animation_record
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var live_stack: PackedByteArray = live_boundary.get("stack_page", PackedByteArray())
	var packet_stream_pointer := int(live_ram[0x005F]) | (int(live_ram[0x0060]) << 8) \
		if live_ram.size() == 0x800 else -1
	var is_packet_wait_resume: bool = live_record == packet_wait_record \
			and live_ram.size() == 0x800 \
			and packet_stream_pointer in [0xA3C9, 0xA439] \
			and int(live_ram[0x05E3]) == 1 \
			and ((int(live_ram[0x05E4]) == 2 and int(live_ram[0x05E5]) == 2 \
				and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 0 \
				and int(live_ram[0x05E8]) == 2 and int(live_ram[0x05E9]) == 0 \
				and int(live_ram[0x05F3]) == 0 and int(live_ram[0x05F4]) == 1 \
				and int(live_ram[0x05F5]) == 5) \
				or (packet_stream_pointer == 0xA439 and int(live_ram[0x05E4]) == 2 \
				and int(live_ram[0x05E5]) == 2 and int(live_ram[0x05E6]) == 0x0E \
				and int(live_ram[0x05E7]) == 1 and int(live_ram[0x05E8]) == 2 \
				and int(live_ram[0x05E9]) == 0 and int(live_ram[0x05F3]) == 0 \
				and int(live_ram[0x05F4]) == 1 and int(live_ram[0x05F5]) == 5) \
				or (packet_stream_pointer == 0xA439 and int(live_ram[0x05E4]) == 2 \
				and int(live_ram[0x05E5]) == 5 and int(live_ram[0x05E6]) == 0x0E \
				and int(live_ram[0x05E7]) == 2 and int(live_ram[0x05E8]) == 2 \
				and int(live_ram[0x05E9]) == 0 and int(live_ram[0x05F3]) == 0 \
				and int(live_ram[0x05F4]) == 1 and int(live_ram[0x05F5]) == 3) \
				or (int(live_ram[0x05E4]) == 2 and int(live_ram[0x05E5]) == 6 \
				and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 1 \
				and int(live_ram[0x05E8]) == 2 and int(live_ram[0x05E9]) == 0 \
				and int(live_ram[0x05F3]) == 0 and int(live_ram[0x05F4]) == 1 \
				and int(live_ram[0x05F5]) == 3) \
				or (int(live_ram[0x05E4]) == 2 and int(live_ram[0x05E5]) == 0x10 \
				and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 2 \
				and int(live_ram[0x05E8]) == 2 and int(live_ram[0x05E9]) == 0 \
				and int(live_ram[0x05F3]) == 0 and int(live_ram[0x05F4]) == 1 \
				and int(live_ram[0x05F5]) == 1)) \
			and int(live_ram[0x0515]) == 0
	var is_scenario1c_parameter58_packet_wait_resume: bool = live_record == packet_wait_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and packet_stream_pointer == 0x9A62 and int(live_ram[0x05EA]) == 0x58 \
			and live_ram.slice(0x05E3, 0x05EB) \
				== PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x58]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x05]) \
			and int(live_ram[0x0515]) == 0 \
			and int(live_ram[0x0022]) == 0 and int(live_ram[0x0629]) == 0 \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x24 \
			and int(live_boundary.get("y", -1)) == 0x06
	var is_scenario1c_parameter58_followup_packet_wait_resume: bool = live_record == packet_wait_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and packet_stream_pointer == 0x9A62 and int(live_ram[0x05EA]) == 0x58 \
			and live_ram.slice(0x05E3, 0x05EB) \
				== PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x03]) \
			and int(live_ram[0x0515]) == 0 \
			and int(live_ram[0x0022]) == 0 and int(live_ram[0x0629]) == 0 \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x05 \
			and int(live_boundary.get("y", -1)) == 0x06
	var is_scenario2e_actor6d_type5_packet_wait_resume: bool = \
		is_scenario2e_actor6d_type5_packet_resume_boundary(live_boundary)
	var sequence_pointer := int(live_ram[0x005F]) | (int(live_ram[0x0060]) << 8) if live_ram.size() == 0x800 else -1
	var is_a439_delay_tick: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0xA439 \
			and live_ram[0x05E3] == 0x01 \
			and live_ram[0x05E6] == 0x0E \
			and live_ram[0x05E7] == 0x02 and live_ram[0x05E8] == 0x02 \
			and live_ram[0x05F3] == 0x00 \
			and live_ram[0x0515] == 0x00 \
			and live_stack[0xC9] == 0x49 and live_stack[0xCA] == 0x80 \
			and ( \
				(live_ram[0x05F4] == 0x00 and live_ram[0x05F5] == 0x05 \
					and ((live_ram[0x05E4] == 0x00 and live_ram[0x05E5] == 0x00 \
						and live_ram[0x05E9] == 0x00 and live_stack[0xC7] == 0xEB \
						and live_stack[0xC8] == 0x39) \
					or (live_ram[0x05E4] == 0x01 and live_ram[0x05E5] == 0x01 \
						and live_ram[0x05E9] == 0x01 and live_stack[0xC7] == 0x00 \
						and live_stack[0xC8] == 0x39) \
					or (live_ram[0x05E4] == 0x01 and live_ram[0x05E5] == 0x01 \
						and live_ram[0x05E9] == 0x00 and live_stack[0xC7] == 0x00 \
						and live_stack[0xC8] == 0x39))) \
				or (live_ram[0x05E4] == 0x02 and live_ram[0x05E5] == 0x05 \
					and live_ram[0x05E9] == 0x01 and live_ram[0x05F4] == 0x01 \
					and live_ram[0x05F5] == 0x04 and live_stack[0xC7] == 0x04 \
					and live_stack[0xC8] == 0x05 \
					and live_ram[0x0063] == 0xB0 and live_ram[0x0064] == 0xA2) \
				or (live_ram[0x05E4] == 0x00 and live_ram[0x05E5] == 0x0D \
					and live_ram[0x05E9] == 0x01 and live_ram[0x05F4] == 0x01 \
					and live_ram[0x05F5] == 0x02 and live_stack[0xC7] == 0x3A \
					and live_stack[0xC8] == 0x06 \
					and live_ram[0x0063] == 0xB0 and live_ram[0x0064] == 0xA2))
	var is_parameter47_f2_delay_tick: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x01 \
			and int(live_ram[0x05E5]) == 0x02 and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x01 and int(live_ram[0x05F3]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x00 and int(live_ram[0x05F5]) == 0x01 \
			and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xBC and int(live_ram[0x0064]) == 0xA2 \
			and int(live_stack[0xC7]) == 0x01 and int(live_stack[0xC8]) == 0x21 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x21 \
			and int(live_boundary.get("y", -1)) == 0x01
	var is_parameter47_f2_followup_delay_tick: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x02 \
			and int(live_ram[0x05E5]) == 0x06 and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x01 \
			and int(live_ram[0x05F3]) == 0x01 and int(live_ram[0x05F4]) == 0x01 \
			and int(live_ram[0x05F5]) == 0x04 and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xCD and int(live_ram[0x0064]) == 0xA2 \
			and int(live_ram[0x0629]) == 0x00 \
			and int(live_stack[0xC7]) == 0x05 and int(live_stack[0xC8]) == 0x05 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x05 \
			and int(live_boundary.get("y", -1)) == 0x05
	var is_parameter47_f2_type5_event: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x01 \
			and int(live_ram[0x05E5]) == 0x02 and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 and int(live_ram[0x05F3]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x00 and int(live_ram[0x05F5]) == 0x01 \
			and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xBC and int(live_ram[0x0064]) == 0xA2 \
			and int(live_stack[0xC7]) == 0x01 and int(live_stack[0xC8]) == 0x21 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x21 \
			and int(live_boundary.get("y", -1)) == 0x01
	var is_scenario2e_actor6d_type5_event: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9BFE and int(live_ram[0x05EA]) == 0x6D \
			and live_ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x00, 0x2E, 0x6C, 0xE8, 0x9B, 0x00]) \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
			and live_ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0xFE, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0xFE \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_scenario1c_parameter58_delay_tick: bool = _slot11_actor_worker_resume_executor \
			.is_scenario1c_parameter58_delay_boundary(live_boundary)
	var is_scenario1c_parameter58_post_packet_delay_tick: bool = _slot11_actor_worker_resume_executor \
			.is_scenario1c_parameter58_post_packet_delay_boundary(live_boundary)
	var is_scenario1c_parameter58_followup_post_packet_delay_tick: bool = _slot11_actor_worker_resume_executor \
			.is_scenario1c_parameter58_followup_post_packet_delay_boundary(live_boundary)
	var is_scenario1c_parameter58_followup_text_terminal_tick: bool = _slot11_actor_worker_resume_executor \
			.is_scenario1c_parameter58_followup_text_terminal_boundary(live_boundary)
	var is_scenario2e_actor6d_9bfe_delay_tick: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9BFE and int(live_ram[0x05EA]) == 0x6D \
			and live_ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x00, 0x2E, 0x6D, 0xE8, 0x9B, 0x00]) \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x01, 0x6D]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
			and live_ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0xFE, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0xFE \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_actor_stream_delay_tick: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 \
			and int(live_ram[0x05E3]) == 1 \
			and int(live_ram[0x05F5]) > 0 and int(live_ram[0x0515]) == 0 \
			and (is_parameter47_f2_delay_tick or is_a439_delay_tick \
				or is_scenario2e_actor6d_type5_event \
				or is_scenario2e_actor6d_9bfe_delay_tick \
				or is_scenario1c_parameter58_delay_tick \
				or is_scenario1c_parameter58_followup_post_packet_delay_tick \
				or is_scenario1c_parameter58_followup_text_terminal_tick \
				or (int(live_ram[0x05F4]) == 0 \
				and ((sequence_pointer == 0xA3BD and int(live_ram[0x05E4]) == 0 \
					and int(live_ram[0x05E5]) == 0 and int(live_ram[0x05E9]) == 0) \
				or (sequence_pointer == 0xA3C9 and int(live_ram[0x05E4]) == 1 \
					and int(live_ram[0x05E5]) == 1 and int(live_ram[0x05E9]) in [0, 1]))))
	var is_selector03_packet_wait_start: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 \
			and sequence_pointer in [0xA3C9, 0xA439] \
			and int(live_ram[0x05E3]) == 1 \
			and ((int(live_ram[0x05E4]) == 2 and int(live_ram[0x05E5]) == 2 \
				and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 0 \
				and int(live_ram[0x05E8]) == 2 and int(live_ram[0x05E9]) == 0 \
				and int(live_ram[0x05F3]) == 0 and int(live_ram[0x05F4]) == 1 \
				and int(live_ram[0x05F5]) == 5) \
				or (sequence_pointer == 0xA439 and int(live_ram[0x05E4]) == 2 \
				and int(live_ram[0x05E5]) == 2 and int(live_ram[0x05E6]) == 0x0E \
				and int(live_ram[0x05E7]) == 1 and int(live_ram[0x05E8]) == 2 \
				and int(live_ram[0x05E9]) == 0 and int(live_ram[0x05F3]) == 0 \
				and int(live_ram[0x05F4]) == 1 and int(live_ram[0x05F5]) == 5) \
				or (sequence_pointer == 0xA439 and int(live_ram[0x05E4]) == 2 \
				and int(live_ram[0x05E5]) == 5 and int(live_ram[0x05E6]) == 0x0E \
				and int(live_ram[0x05E7]) == 2 and int(live_ram[0x05E8]) == 2 \
				and int(live_ram[0x05E9]) == 0 and int(live_ram[0x05F3]) == 0 \
				and int(live_ram[0x05F4]) == 1 and int(live_ram[0x05F5]) == 3) \
				or (int(live_ram[0x05E4]) == 2 and int(live_ram[0x05E5]) == 6 \
				and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 1 \
				and int(live_ram[0x05E8]) == 2 and int(live_ram[0x05E9]) == 0 \
				and int(live_ram[0x05F3]) == 0 and int(live_ram[0x05F4]) == 1 \
				and int(live_ram[0x05F5]) == 3) \
				or (int(live_ram[0x05E4]) == 2 and int(live_ram[0x05E5]) == 0x10 \
				and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 2 \
				and int(live_ram[0x05E8]) == 2 and int(live_ram[0x05E9]) == 0 \
				and int(live_ram[0x05F3]) == 0 and int(live_ram[0x05F4]) == 1 \
				and int(live_ram[0x05F5]) == 1)) \
			and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xB0 and int(live_ram[0x0064]) == 0xA2
	var is_scenario1c_parameter58_packet_wait_start: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9A62 and int(live_ram[0x05EA]) == 0x58 \
			and live_ram.slice(0x05E3, 0x05EB) \
				== PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x58]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x05]) \
			and int(live_ram[0x0515]) == 0x00 \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x24, 0x24, 0x49, 0x80])
	var is_scenario1c_parameter58_followup_packet_wait_start: bool = \
			_slot11_actor_worker_resume_executor.is_scenario1c_parameter58_followup_packet_wait_boundary(live_boundary)
	var is_parameter47_f2_index1_packet_wait_start: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 \
			and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x02 \
			and int(live_ram[0x05E5]) == 0x03 and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x01 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 and int(live_ram[0x05F3]) == 0x01 \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) == 0x05 \
			and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xCD and int(live_ram[0x0064]) == 0xA2 \
			and int(live_ram[0x0629]) == 0x00 \
			and int(live_stack[0xC7]) == 0x24 and int(live_stack[0xC8]) == 0x24 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x24 \
			and int(live_boundary.get("y", -1)) == 0x24
	var is_parameter47_f2_index2_packet_wait_start: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and live_ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x06, 0x0E, 0x02, 0x02, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x03]) \
			and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xCD and int(live_ram[0x0064]) == 0xA2 \
			and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x05, 0x05, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x05 \
			and int(live_boundary.get("y", -1)) == 0x05
	var is_parameter47_f2_index1_packet_wait_resume: bool = live_record == packet_wait_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and live_ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x03, 0x0E, 0x01, 0x02, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x05]) \
			and int(live_ram[0x0515]) == 0x00 \
			and (int(live_ram[0x0063]) | (int(live_ram[0x0064]) << 8)) == 0xA2CD \
			and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x24 \
			and int(live_boundary.get("y", -1)) == 0x06
	var is_parameter47_f2_index2_packet_wait_resume: bool = live_record == packet_wait_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and live_ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x06, 0x0E, 0x02, 0x02, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x03]) \
			and int(live_ram[0x0515]) == 0x00 \
			and (int(live_ram[0x0063]) | (int(live_ram[0x0064]) << 8)) == 0xA2CD \
			and int(live_ram[0x0022]) == 0x00 and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x05 \
			and int(live_boundary.get("y", -1)) == 0x06
	var animation_stream_pointer := int(live_ram[0x0063]) | (int(live_ram[0x0064]) << 8) if live_ram.size() == 0x800 else -1
	var selector03_inactive_animation_pointers: Array[int] = [
		0xA2B2, 0xA2B4, 0xA2B6, 0xA2B8, 0xA2BA, 0xA2BC, 0xA2BE,
		0xA2C0, 0xA2C2, 0xA2C4, 0xA2C6, 0xA2C8,
	]
	var is_selector03_animation_tail_idle: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and int(live_ram[0x005F]) == 0xC9 and int(live_ram[0x0060]) == 0xA3 \
			and int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x1A and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x00 and int(live_ram[0x05F5]) == 0x05 \
			and int(live_ram[0x0515]) in [0x00, 0x80] \
			and int(live_ram[0x0063]) == 0xB0 and int(live_ram[0x0064]) == 0xA2 \
			and int(live_stack[0xC7]) == 0x24 and int(live_stack[0xC8]) == 0x24
	var is_a439_inactive_animation_countdown: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0xA439 \
			and int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x0E and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 and int(live_ram[0x05F3]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(live_ram[0x0515]) in [0x00, 0x80] \
			and animation_stream_pointer in selector03_inactive_animation_pointers \
			and int(live_stack[0xC7]) == 0x04 and int(live_stack[0xC8]) == 0x04 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80
	var is_scenario1c_parameter58_terminal_animation_countdown: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9A62 and int(live_ram[0x05EA]) == 0x58 \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and live_ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x00, 0x01]) \
			and int(live_ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and animation_stream_pointer == 0xA2B2 \
			and int(live_ram[0x0515]) == 0x00 and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x04 \
			and int(live_boundary.get("y", -1)) == 0x04 \
		or _slot11_actor_worker_resume_executor.is_scenario1c_parameter58_phase29_cursor10_queue_busy_animation_boundary(live_boundary)
	var is_scenario1e_actor58_animation_countdown: bool = \
			_slot11_actor_worker_resume_executor.is_scenario1e_actor58_animation_countdown_saved_boundary(live_boundary)
	var is_scenario1e_actor58_zero_counter_gate: bool = int(live_ram[0x05F5]) == 0 \
			and _slot11_actor_worker_resume_executor.is_scenario1e_actor58_animation_countdown_saved_boundary(
				live_boundary, true)
	var is_scenario1c_parameter58_zero_counter_queue_busy_gate: bool = \
			_slot11_actor_worker_resume_executor.is_scenario1c_parameter58_zero_counter_queue_busy_animation_boundary(
				live_boundary)
	var is_parameter47_f2_animation_script_countdown: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and live_ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x01, 0x01]) \
			and int(live_ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(live_ram[0x0515]) == 0x00 and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and int(live_ram[0x0063]) in [0xCD, 0xCF, 0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(live_ram[0x0064]) == 0xA2 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x04 \
			and int(live_boundary.get("y", -1)) == 0x04
	var is_parameter47_f2_animation_script_zero_counter_gate: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and live_ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(live_ram[0x0515]) == 0x00 and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and int(live_ram[0x0063]) in [0xCD, 0xCF, 0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(live_ram[0x0064]) == 0xA2 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x04 \
			and int(live_boundary.get("y", -1)) == 0x04
	var is_scenario2e_actor6d_post_type5_animation_countdown: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9BFE and int(live_ram[0x05EA]) == 0x6D \
			and live_ram.slice(0x05E3, 0x05E9) == PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02]) \
			and int(live_ram[0x05E9]) == 0x00 \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x02, 0x01, 0x04]) \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xEA, 0xA2]) \
			and int(live_ram[0x0515]) == 0x00 \
			and live_stack.slice(0xC9, 0xCB) == PackedByteArray([0x49, 0x80])
	var is_animation_countdown_resume: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 \
		and ((int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) in [0, 1]) \
				or (int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E4]) == 0 \
				and int(live_ram[0x05E5]) == 0x1A and int(live_ram[0x05E6]) == 0x0E \
				and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0 and animation_stream_pointer in selector03_inactive_animation_pointers) \
			or is_a439_inactive_animation_countdown \
			or is_scenario1c_parameter58_terminal_animation_countdown \
			or is_scenario1e_actor58_animation_countdown \
			or is_parameter47_f2_followup_delay_tick \
			or is_parameter47_f2_animation_script_countdown \
			or is_scenario2e_actor6d_post_type5_animation_countdown) \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) > 0 \
			and (int(live_ram[0x0515]) == 0 or is_scenario2e_actor6d_post_type5_animation_countdown \
				or (int(live_ram[0x05E3]) == 0 \
				and int(live_ram[0x005F]) == 0xC9 and int(live_ram[0x0060]) == 0xA3 \
				and int(live_ram[0x05E5]) == 0x1A \
				and animation_stream_pointer in selector03_inactive_animation_pointers \
				and int(live_ram[0x0515]) == 0x80) \
				or is_a439_inactive_animation_countdown \
				or is_scenario1c_parameter58_terminal_animation_countdown)
	var is_selector03_post_packet_countdown: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 \
			and int(live_ram[0x005F]) == 0xC9 and int(live_ram[0x0060]) == 0xA3 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x02 \
			and ((int(live_ram[0x05E5]) == 0x06 and int(live_ram[0x05E7]) == 0x01 \
				and int(live_ram[0x05F5]) == 0x04) \
				or (int(live_ram[0x05E5]) == 0x10 and int(live_ram[0x05E7]) == 0x02 \
				and int(live_ram[0x05F5]) == 0x02)) \
			and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x01 and int(live_ram[0x05F3]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x01 \
			and int(live_ram[0x0515]) == 0x00 \
			and int(live_ram[0x0063]) == 0xB0 and int(live_ram[0x0064]) == 0xA2
	var is_selector03_row02_animation_gate: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 \
			and int(live_ram[0x005F]) == 0xC9 and int(live_ram[0x0060]) == 0xA3 \
			and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05F3]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) == 0x00 \
			and int(live_ram[0x0515]) == 0x00 \
			and ((int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E5]) == 0x19 \
				and int(live_ram[0x05E9]) == 0x01 and int(live_ram[0x0063]) == 0xB0 \
				and int(live_ram[0x0064]) == 0xA2) \
				or (int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E5]) == 0x1A \
				and int(live_ram[0x05E9]) == 0x00 \
				and animation_stream_pointer in selector03_inactive_animation_pointers))
	var is_a439_text_terminal_inactive_gate: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0xA439 \
			and int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x0E and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) == 0x00 \
			and int(live_ram[0x0515]) == 0x00
	var is_scenario1c_parameter58_followup_text_terminal_inactive_gate: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9A62 and int(live_ram[0x05EA]) == 0x58 \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x00]) \
			and int(live_ram[0x0515]) == 0x00 and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2])
	var is_a439_inactive_zero_counter_gate: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0xA439 \
			and int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x0E and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x01 and int(live_ram[0x05F5]) == 0x00 \
			and int(live_ram[0x0515]) in [0x00, 0x80] \
			and int(live_ram[0x0063]) in [0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] \
			and int(live_ram[0x0064]) == 0xA2 \
			and int(live_stack[0xC7]) == 0x04 and int(live_stack[0xC8]) == 0x04 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80 \
			and int(live_boundary.get("x", -1)) == 0x04 \
			and int(live_boundary.get("y", -1)) in [0x02, 0x04]
	var is_a439_inactive_zero_mode_resume: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0xA439 \
			and int(live_ram[0x05E3]) == 0x00 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x0E and int(live_ram[0x05E6]) == 0x0E \
			and int(live_ram[0x05E7]) == 0x02 and int(live_ram[0x05E8]) == 0x02 \
			and int(live_ram[0x05E9]) == 0x00 \
			and int(live_ram[0x05F3]) == 0x00 and int(live_ram[0x05F4]) == 0x00 \
			and int(live_ram[0x05F5]) == 0x01 and int(live_ram[0x0515]) in [0x00, 0x80] \
			and int(live_ram[0x0063]) == 0xBC and int(live_ram[0x0064]) == 0xA2 \
			and int(live_stack[0xC7]) == 0x04 and int(live_stack[0xC8]) == 0x04 \
			and int(live_stack[0xC9]) == 0x49 and int(live_stack[0xCA]) == 0x80 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x04 \
			and int(live_boundary.get("y", -1)) == 0x04
	var is_scenario1c_f0_inactive_zero_mode_resume: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9400 and int(live_ram[0x05EA]) == 0x00 \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x02, 0x0E, 0x02, 0x02, 0x00, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(live_ram[0x0515]) == 0x00 and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x02, 0x21, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x21 \
			and int(live_boundary.get("y", -1)) == 0x02
	var is_scenario1e_actor58_inactive_zero_mode_resume: bool = live_record == first_stream_record \
			and sequence_pointer == 0x9A62 \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and int(live_ram[0x05EA]) == 0x58 \
			and live_ram.slice(0x0517, 0x0519) == PackedByteArray([0x40, 0x1E]) \
			and int(live_ram[0x0519]) <= 0x20 \
			and (int(live_ram[0x0516]) == 0x29 or (int(live_ram[0x0516]) == 0x00 and int(live_ram[0x0519]) == 0x00)) \
			and live_ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
			and live_ram.slice(0x005D, 0x005F) == PackedByteArray([0xE3, 0xB7]) \
			and int(live_ram[0x0522]) == 0x00 \
			and live_ram.slice(0x0523, 0x052B) == PackedByteArray([0x07, 0x45, 0x06, 0x00, 0x3C, 0x90, 0xFF, 0x00]) \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and live_ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
			and int(live_ram[0x0515]) in [0x00, 0x80] and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80])
	var is_parameter47_f2_terminal_inactive_gate: bool = live_record == first_stream_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and live_ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(live_ram[0x0063]) == 0xCD and int(live_ram[0x0064]) == 0xA2 \
			and int(live_ram[0x0515]) == 0x00 and int(live_ram[0x0022]) == 0x00 \
			and int(live_ram[0x0629]) == 0x00 \
			and live_stack.slice(0xC7, 0xCB) == PackedByteArray([0x02, 0x06, 0x49, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x06 \
			and int(live_boundary.get("y", -1)) == 0x02
	var is_parameter47_f2_event_queue_resume: bool = live_record == event_queue_record \
			and live_ram.size() == 0x800 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x01 \
			and int(live_ram[0x05E5]) == 0x02 \
			and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 0x14 \
			and int(live_ram[0x05E8]) in [1, 2, 3, 4, 5, 6] \
			and int(live_ram[0x05E9]) == 0x00 \
			and int(live_ram[0x05F3]) == 0x01 and int(live_ram[0x05F4]) == 0x80 \
			and int(live_ram[0x05F5]) == 0x01 \
			and int(live_ram[0x0061]) == 0xBF and int(live_ram[0x0062]) == 0x8F \
			and int(live_ram[0x0515]) in [0x00, 0x80]
	var scenario2e_actor6d_type5_queue_remaining := int(live_ram[0x05E8]) \
			if live_ram.size() == 0x800 else -1
	var scenario2e_actor6d_type5_next_ppu_address := (0x222C \
			+ ((6 - scenario2e_actor6d_type5_queue_remaining) * 0x40)) & 0xFFFF
	var scenario2e_actor6d_type5_queue_stack := PackedByteArray([
		0x68, 0x82, (scenario2e_actor6d_type5_next_ppu_address >> 8) & 0xFF,
		scenario2e_actor6d_type5_next_ppu_address & 0xFF, 0x0A, 0x4C, 0x80,
	])
	var is_scenario2e_actor6d_type5_event_queue_resume: bool = live_record == event_queue_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9BFE and int(live_ram[0x05EA]) == 0x6D \
			and live_ram[0x0516] == 0x01 and live_ram[0x0517] == 0x00 \
			and live_ram[0x0518] == 0x2E \
			and int(live_ram[0x0519]) == 0x65 + scenario2e_actor6d_type5_queue_remaining \
			and live_ram.slice(0x05E3, 0x05E8) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x14]) \
			and scenario2e_actor6d_type5_queue_remaining in [1, 2, 3, 4, 5, 6] \
			and int(live_ram[0x05E9]) == 0x00 and int(live_ram[0x05F3]) == 0x02 \
			and int(live_ram[0x05F4]) == 0x80 and int(live_ram[0x05F5]) == 0x01 \
			and live_ram.slice(0x0061, 0x0063) == PackedByteArray([0xBF, 0x8F]) \
			and live_ram[0x0515] in [0x00, 0x80] \
			and live_stack.slice(0xC4, 0xCB) == scenario2e_actor6d_type5_queue_stack
	var is_event_queue_resume: bool = live_record == event_queue_record \
			and live_ram.size() == 0x800 \
			and int(live_ram[0x05E6]) == 0x0E and int(live_ram[0x05E7]) == 0x14 \
			and int(live_ram[0x05E8]) in [1, 2, 3, 4, 5, 6] \
			and ((int(live_ram[0x0061]) in [0x37, 0x94] and int(live_ram[0x0062]) == 0x8E) \
				or is_parameter47_f2_event_queue_resume \
				or is_scenario2e_actor6d_type5_event_queue_resume) \
			and int(live_ram[0x0515]) in [0x00, 0x80]
	var is_parameter47_f2_waiter_resume: bool = live_record == event_queue_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x01 and int(live_ram[0x05E9]) == 0x00 \
			and int(live_ram[0x05F4]) == 0x00 \
			and int(live_stack[0xC4]) == 0x52 and int(live_stack[0xC5]) == 0xCC \
			and int(live_stack[0xC7]) == 0x7C and int(live_stack[0xC8]) == 0x80 \
			and ((int(live_stack[0xC6]) == 0x06 \
				and int(live_boundary.get("x", -1)) == 0x17 \
				and int(live_boundary.get("y", -1)) == 0x06) \
				or (int(live_stack[0xC6]) >= 0 and int(live_stack[0xC6]) < 0x06 \
				and int(live_boundary.get("x", -1)) == 0x4F \
				and int(live_boundary.get("y", -1)) == 0x00))
	var is_scenario2e_actor6d_f2_waiter_resume: bool = \
		_slot11_actor_worker_resume_executor.is_scenario2e_callback36_map2f_actor6d_f2_waiter_resume_candidate(
			live_boundary)
	var is_scenario2e_actor6d_f2_tail_poll_resume: bool = live_record == parameter47_f2_tail_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9BE3 and int(live_ram[0x05EA]) == 0x6D \
			and live_boundary.get("mapper", {}).get("bank_low", -1) == 0x18 \
			and live_boundary.get("mapper", {}).get("bank_high", -1) == 0x19 \
			and live_ram.slice(0x0515, 0x051A) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x6F]) \
			and live_ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x18, 0x08, 0x22]) \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and live_stack.slice(0xC3, 0xCB) == PackedByteArray([0x00, 0x4F, 0xA2, 0xCC, 0x7C, 0x80, 0x4C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x4F \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_scenario2e_actor6d_f2_final_packet_resume: bool = live_record == parameter47_f2_tail_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9BE3 and int(live_ram[0x05EA]) == 0x6D \
			and live_boundary.get("mapper", {}).get("bank_low", -1) == 0x18 \
			and live_boundary.get("mapper", {}).get("bank_high", -1) == 0x19 \
			and live_ram.slice(0x0515, 0x051A) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x6E]) \
			and live_ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and live_stack.slice(0xC3, 0xCB) == PackedByteArray([0x00, 0x21, 0xD0, 0xCC, 0x7C, 0x80, 0x4C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x21 \
			and int(live_boundary.get("y", -1)) == 0x00
	var scenario1c_parameter00_f2_wait_count := int(live_stack[0xC6]) \
		if live_stack.size() == 0x100 else -1
	var scenario1c_parameter00_f2_wait_registers := \
		(scenario1c_parameter00_f2_wait_count == 0x06 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x00 \
			and int(live_boundary.get("y", -1)) == 0x06) \
		or (scenario1c_parameter00_f2_wait_count >= 0 \
			and scenario1c_parameter00_f2_wait_count < 0x06 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x4F \
			and int(live_boundary.get("y", -1)) == 0x00)
	var is_scenario1c_parameter00_f2_waiter_resume: bool = live_record == event_queue_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9400 and int(live_ram[0x05EA]) == 0x00 \
			and scenario1c_parameter00_f2_wait_count >= 0 \
			and scenario1c_parameter00_f2_wait_count <= 0x06 \
			and int(live_ram[0x0519]) == 0x28 + scenario1c_parameter00_f2_wait_count \
			and live_ram.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x40, 0x1C]) \
			and live_ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
			and int(live_ram[0x003A]) == 0x06 \
			and live_ram.slice(0x005D, 0x005F) == PackedByteArray([0x4F, 0xBB]) \
			and live_ram.slice(0x0522, 0x052B) == PackedByteArray([0x02, 0x30, 0x1F, 0x02, 0x3C, 0x4A, 0x4C, 0x00, 0x40]) \
			and int(live_ram[0x0539]) == 0x00 \
			and live_ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x40, 0xA0, 0x00, 0x00, 0x01, 0x52, 0xA0, 0x80, 0x00, 0x02, 0x80, 0x01]) \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x00]) \
			and live_ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and int(live_ram[0x0515]) == 0x00 \
			and live_stack.slice(0xC4, 0xC6) == PackedByteArray([0x52, 0xCC]) \
			and live_stack[0xC6] == scenario1c_parameter00_f2_wait_count \
			and live_stack.slice(0xC7, 0xC9) == PackedByteArray([0x7C, 0x80]) \
			and int(live_boundary.get("sp", -1)) == 0xC1 \
			and scenario1c_parameter00_f2_wait_registers
	var is_scenario1c_parameter00_f2_tail_record: bool = live_record.size() == 4 \
			and int(live_record[0]) in [0x00, 0x01] \
			and live_record.slice(1, 4) == PackedByteArray([0xC2, 0x18, 0x19])
	# Before scheduler RTS restoration, saved contexts may expose A=$01; dispatch
	# reloads A from X. The executor validates the restored A at the ROM PC.
	var is_scenario1c_parameter00_f2_tail_poll_resume: bool = is_scenario1c_parameter00_f2_tail_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9400 and int(live_ram[0x05EA]) == 0x00 \
			and int(live_ram[0x0515]) == 0x00 \
			and live_ram.slice(0x0516, 0x051A) == PackedByteArray([0x61, 0x40, 0x1C, 0x27]) \
			and live_ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x18, 0x08, 0x22]) \
			and int(live_ram[0x05D1]) == 0x80 and int(live_ram[0x05D2]) == 0x01 \
			and live_ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x00]) \
			and live_stack.slice(0xC4, 0xC9) == PackedByteArray([0x4F, 0xA2, 0xCC, 0x7C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x4F \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_scenario1c_parameter00_f2_final_packet_resume: bool = is_scenario1c_parameter00_f2_tail_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9400 and int(live_ram[0x05EA]) == 0x00 \
			and int(live_ram[0x0515]) == 0x00 \
			and live_ram.slice(0x0516, 0x051A) == PackedByteArray([0x61, 0x40, 0x1C, 0x26]) \
			and live_ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and live_ram.slice(0x05E3, 0x05E6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and live_stack.slice(0xC4, 0xC9) == PackedByteArray([0x21, 0xD0, 0xCC, 0x7C, 0x80]) \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x21 \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_scenario1c_parameter00_f2_tail_resume: bool = is_scenario1c_parameter00_f2_tail_poll_resume \
			or is_scenario1c_parameter00_f2_final_packet_resume
	var is_parameter47_f2_tail_poll_resume: bool = live_record == parameter47_f2_tail_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x01 \
			and int(live_stack[0xC3]) == 0x00 and int(live_stack[0xC4]) == 0x4F \
			and int(live_stack[0xC5]) == 0xA2 and int(live_stack[0xC6]) == 0xCC \
			and int(live_stack[0xC7]) == 0x7C and int(live_stack[0xC8]) == 0x80 \
			and int(live_boundary.get("x", -1)) == 0x4F \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_parameter47_f2_final_packet_resume: bool = live_record == parameter47_f2_tail_record \
			and live_ram.size() == 0x800 and live_stack.size() == 0x100 \
			and sequence_pointer == 0x9917 and int(live_ram[0x05EA]) == 0x47 \
			and int(live_ram[0x05E3]) == 0x01 and int(live_ram[0x05E4]) == 0x00 \
			and int(live_ram[0x05E5]) == 0x01 \
			and int(live_stack[0xC4]) == 0x21 and int(live_stack[0xC5]) == 0xD0 \
			and int(live_stack[0xC6]) == 0xCC \
			and int(live_stack[0xC7]) == 0x7C and int(live_stack[0xC8]) == 0x80 \
			and int(live_boundary.get("a", -1)) == 0x01 \
			and int(live_boundary.get("x", -1)) == 0x21 \
			and int(live_boundary.get("y", -1)) == 0x00
	var is_parameter47_f2_tail_resume: bool = is_parameter47_f2_tail_poll_resume \
			or is_parameter47_f2_final_packet_resume
	var is_waiter_resume: bool = live_record in [waiter_record, tail_waiter_record] \
			or is_animation_resume or is_animation_countdown_resume \
			or is_selector03_animation_tail_idle \
			or is_selector03_post_packet_countdown or is_selector03_row02_animation_gate \
			or is_a439_text_terminal_inactive_gate \
			or is_scenario1c_parameter58_followup_text_terminal_inactive_gate \
			or is_a439_inactive_zero_counter_gate \
			or is_parameter47_f2_terminal_inactive_gate \
			or is_parameter47_f2_animation_script_zero_counter_gate \
			or is_scenario1c_parameter58_zero_counter_queue_busy_gate \
			or is_scenario1e_actor58_zero_counter_gate \
			or is_a439_inactive_zero_mode_resume \
			or is_scenario1c_f0_inactive_zero_mode_resume \
			or is_scenario1e_actor58_inactive_zero_mode_resume \
			or is_actor_stream_delay_tick or is_selector03_packet_wait_start \
			or is_scenario1c_parameter58_packet_wait_start \
			or is_scenario1c_parameter58_followup_packet_wait_start \
			or is_parameter47_f2_index1_packet_wait_start \
			or is_parameter47_f2_index2_packet_wait_resume \
			or is_parameter47_f2_index2_packet_wait_start \
			or is_parameter47_f2_index1_packet_wait_resume \
			or is_parameter47_f2_type5_event or is_scenario2e_actor6d_type5_event \
			or is_packet_wait_resume or is_scenario1c_parameter58_packet_wait_resume \
			or is_scenario1c_parameter58_followup_packet_wait_resume \
			or is_scenario2e_actor6d_type5_packet_wait_resume or is_event_queue_resume \
			or is_parameter47_f2_waiter_resume or is_scenario1c_parameter00_f2_waiter_resume \
			or is_scenario2e_actor6d_f2_waiter_resume \
			or is_parameter47_f2_tail_resume or is_scenario1c_parameter00_f2_tail_resume \
			or is_scenario2e_actor6d_f2_tail_poll_resume \
			or is_scenario2e_actor6d_f2_final_packet_resume
	var expected_live_banks := PackedByteArray([0x1A, 0x1B]) if is_animation_resume \
		else PackedByteArray([0x18, 0x19])
	if int(live_boundary.get("phase", -1)) != 3 \
			or int(live_boundary.get("ready_delay", -1)) != 0 \
			or int(live_boundary.get("pending_resume", -1)) != 2 \
			or int(live_boundary.get("pc", -1)) != 0xCB0F \
			or int(live_boundary.get("active_task_slot", -1)) != -1 \
			or live_record not in [first_stream_record, waiter_record, tail_waiter_record, event_queue_record, parameter47_f2_tail_record, animation_record, packet_wait_record] \
			or int(live_boundary.get("bank_low", -1)) != int(expected_live_banks[0]) \
			or int(live_boundary.get("bank_high", -1)) != int(expected_live_banks[1]):
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
		or (is_parameter47_f2_type5_event and expected_dispatch_pc == 0x804A) \
			or (is_scenario1c_parameter58_zero_counter_queue_busy_gate and expected_dispatch_pc == 0x804A) \
			or (is_scenario1e_actor58_zero_counter_gate and expected_dispatch_pc == 0x804A) \
		or (is_packet_wait_resume and expected_dispatch_pc == 0x82F7) \
		or (is_scenario1c_parameter58_packet_wait_resume and expected_dispatch_pc == 0x82F7) \
		or (is_scenario1c_parameter58_followup_packet_wait_resume and expected_dispatch_pc == 0x82F7) \
		or (is_parameter47_f2_index1_packet_wait_resume and expected_dispatch_pc == 0x82F7) \
		or (is_parameter47_f2_index2_packet_wait_resume and expected_dispatch_pc == 0x82F7) \
		or (is_scenario2e_actor6d_type5_packet_wait_resume and expected_dispatch_pc == 0x82F7) \
		or (is_selector03_packet_wait_start and expected_dispatch_pc == 0x804A) \
		or (is_scenario1c_parameter58_packet_wait_start and expected_dispatch_pc == 0x804A) \
		or (is_scenario1c_parameter58_followup_packet_wait_start and expected_dispatch_pc == 0x804A) \
		or (is_parameter47_f2_index1_packet_wait_start and expected_dispatch_pc == 0x804A) \
		or (is_parameter47_f2_index2_packet_wait_start and expected_dispatch_pc == 0x804A) \
		or (is_event_queue_resume and expected_dispatch_pc == 0x8269) \
		or (is_animation_resume and expected_dispatch_pc == 0xA21A) \
			or ((is_animation_countdown_resume or is_selector03_post_packet_countdown \
					or is_selector03_row02_animation_gate or is_a439_text_terminal_inactive_gate \
					or is_scenario1c_parameter58_followup_text_terminal_inactive_gate \
					or is_a439_inactive_zero_counter_gate or is_parameter47_f2_terminal_inactive_gate \
					or is_parameter47_f2_animation_script_zero_counter_gate \
					or is_a439_inactive_zero_mode_resume \
				or is_scenario1c_f0_inactive_zero_mode_resume \
				or is_scenario1e_actor58_inactive_zero_mode_resume \
					or is_selector03_animation_tail_idle) \
				and expected_dispatch_pc == 0x804A) \
		or (is_actor_stream_delay_tick and expected_dispatch_pc == 0x804A)
	var expected_dispatch_sp := 0xCA if expected_dispatch_pc == 0x804A \
		else 0xC8 if expected_dispatch_pc == 0x82F7 \
		else 0xC5 if expected_dispatch_pc == 0x8269 \
		else 0xC5 if expected_dispatch_pc == 0xCC53 \
			and (is_parameter47_f2_waiter_resume or is_scenario1c_parameter00_f2_waiter_resume \
			or is_scenario2e_actor6d_f2_waiter_resume) \
		else 0xC6 if expected_dispatch_pc == 0xCCA3 and (is_parameter47_f2_tail_resume \
			or is_scenario2e_actor6d_f2_tail_poll_resume) \
		else 0xC6 if expected_dispatch_pc == 0xCCA3 and is_scenario1c_parameter00_f2_tail_poll_resume \
		else 0xC6 if expected_dispatch_pc == 0xCCD1 and (is_parameter47_f2_final_packet_resume \
			or is_scenario1c_parameter00_f2_final_packet_resume \
			or is_scenario2e_actor6d_f2_final_packet_resume) \
		else 0xC3 if expected_dispatch_pc == 0xCC53 else 0xC6 if expected_dispatch_pc == 0xA21A else 0xC4
	if not bool(dispatch.get("ok", false)) \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("slot_base", -1)) != SLOT_11 \
			or not dispatch_pc_valid \
			or int(dispatch.get("sp", -1)) != expected_dispatch_sp \
			or (is_scenario2e_actor6d_post_type5_animation_countdown \
				and (int(dispatch.get("a", -1)) != 0x24 \
				or int(dispatch.get("x", -1)) != 0x24 \
				or int(dispatch.get("y", -1)) != 0x24)) \
			or int(dispatch.get("bank_low", -1)) != int(expected_live_banks[0]) \
			or int(dispatch.get("bank_high", -1)) != int(expected_live_banks[1]):
		return _fail_result("The source scheduler did not restore the audited slot-$11 actor continuation: %s signature=%s" % [str(dispatch), JSON.stringify({
			"waiter": is_waiter_resume, "f2_waiter": is_parameter47_f2_waiter_resume,
			"scenario1c_parameter00_f2_waiter": is_scenario1c_parameter00_f2_waiter_resume,
			"f2_tail": is_parameter47_f2_tail_resume,
			"f2_final": is_parameter47_f2_final_packet_resume,
			"f2_poll": is_parameter47_f2_tail_poll_resume,
			"scenario2e_actor6d_f2_waiter_resume": is_scenario2e_actor6d_f2_waiter_resume,
			"scenario2e_actor6d_type5_packet_wait_resume": is_scenario2e_actor6d_type5_packet_wait_resume,
			"record": live_record.hex_encode(), "pc_expected": expected_dispatch_pc,
			"sp_expected": expected_dispatch_sp, "pointer": sequence_pointer,
			"actor6d_packet_resume_boundary": {
				"p": int(live_boundary.get("p", -1)),
				"p_known_mask": int(live_boundary.get("p_known_mask", -1)),
				"mapper": live_boundary.get("mapper", {}),
				"ram_0515_051d": live_ram.slice(0x0515, 0x051D).hex_encode() if live_ram.size() == 0x800 else "invalid",
				"ram_0022": int(live_ram[0x0022]) if live_ram.size() == 0x800 else -1,
				"ram_0629": int(live_ram[0x0629]) if live_ram.size() == 0x800 else -1,
				"stack_C7_CB": live_stack.slice(0xC7, 0xCB).hex_encode() if live_stack.size() == 0x100 else "invalid",
			},
			"boundary_state": {
				"phase": int(live_boundary.get("phase", -1)),
				"pc": int(live_boundary.get("pc", -1)),
				"sp": int(live_boundary.get("sp", -1)),
				"pending_resume": int(live_boundary.get("pending_resume", -1)),
				"active_task_slot": int(live_boundary.get("active_task_slot", -1)),
				"ready_delay": int(live_boundary.get("ready_delay", -1)),
				"ram_0516_051d": live_ram.slice(0x0516, 0x051D).hex_encode() if live_ram.size() == 0x800 else "invalid",
				"ram_0522_052c": live_ram.slice(0x0522, 0x052C).hex_encode() if live_ram.size() == 0x800 else "invalid",
				"ram_005d_0061": live_ram.slice(0x005D, 0x0061).hex_encode() if live_ram.size() == 0x800 else "invalid",
				"ram_05e3_05f6": live_ram.slice(0x05E3, 0x05F6).hex_encode() if live_ram.size() == 0x800 else "invalid",
				"ram_0063_0065": live_ram.slice(0x0063, 0x0065).hex_encode() if live_ram.size() == 0x800 else "invalid",
			},
			"actor": int(live_ram[0x05EA]) if live_ram.size() == 0x800 else -1,
			"mode": live_ram.slice(0x05E3, 0x05E6).hex_encode() if live_ram.size() == 0x800 else "invalid",
			"f4": int(live_ram[0x05F4]) if live_ram.size() == 0x800 else -1,
			"regs": [int(live_boundary.get("a", -1)), int(live_boundary.get("x", -1)), int(live_boundary.get("y", -1))],
			"xy": [int(live_boundary.get("x", -1)), int(live_boundary.get("y", -1))],
			"stack": live_stack.slice(0xC3, 0xCB).hex_encode() if live_stack.size() == 0x100 else "invalid",
		})])
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var resume_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
	if is_scenario2e_actor6d_post_type5_animation_countdown:
		var dispatch_stack_variant: Variant = resume_boundary.get("stack_page", PackedByteArray())
		if not dispatch_stack_variant is PackedByteArray or dispatch_stack_variant.size() != 0x100 \
				or dispatch_stack_variant.slice(0xC7, 0xCB) != PackedByteArray([0x24, 0x24, 0x49, 0x80]):
			return _fail_result("Scenario-$2E actor-$6D post-type-$5 `$804A` stack differs from frame 9496.")
	var worker: Dictionary
	var save_result: Dictionary = {}
	var slot11_gate_result_preapplied := false
	var is_final_packet_resume := false
	var is_scenario1c_terminal_return := false
	var is_packet_resume_result := false
	var is_animation_busy_gate := false
	var is_actor_event_payload_yield := false
	var is_event_queue_return := false
	var is_parameter47_f2_delay_gate_yield := false
	if is_waiter_resume:
		if int(dispatch.get("pc", -1)) == 0x8269 and is_event_queue_resume:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_actor_event_wait_boundary(resume_boundary)
			is_actor_event_payload_yield = String(worker.get("status", "")) \
				in ["slot11_actor_event_payload_at_cb0f", "slot11_actor_event_queue_at_cb0f"]
			is_event_queue_return = String(worker.get("status", "")) \
				== "slot11_actor_event_queue_returned_to_804d"
			if not bool(worker.get("ok", false)) \
				or (is_actor_event_payload_yield and int(worker.get("exit_pc", -1)) != 0xCB0F) \
					or (is_event_queue_return and int(worker.get("exit_pc", -1)) != 0x804D) \
				or (not is_actor_event_payload_yield and not is_event_queue_return):
				return _fail_result("Slot-$11 ROM event queue stopped outside its verified yield/return: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			if is_event_queue_return:
				var event_return_adoption: Dictionary = _scheduler.apply_slot11_actor_event_queue_return_result(worker)
				if not bool(event_return_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM event-queue return to `$804D`: " + _scheduler.error_message)
				var event_animation_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
				worker = _slot11_actor_worker_resume_executor.execute_from_slot11_f5_animation_gate_boundary(event_animation_boundary)
				if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0xCB0F:
					return _fail_result("Slot-$11 `$804D` event return stopped before its `$A217->$CB0F` animation yield: " \
							+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
				var event_animation_adoption: Dictionary = _scheduler.apply_slot11_f5_animation_gate_result(worker)
				if not bool(event_animation_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM event-return animation gate: " + _scheduler.error_message)
				save_result = event_animation_adoption
				_last_source_boundary = "$8269->$8231->$804D->$C560->$CF72->$CE2D->$A1EB->$A217->$CB0F; resumes at $A21A"
		elif int(dispatch.get("pc", -1)) == 0xCC53:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_waiter_resume_boundary(resume_boundary)
		elif int(dispatch.get("pc", -1)) == 0xCCA3:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_waiter_tail_poll_boundary(resume_boundary)
		elif int(dispatch.get("pc", -1)) == 0xCCD1:
			is_final_packet_resume = true
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_final_packet_return_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x804D:
				return _fail_result("Slot-$11 final packet return stopped before its ROM-defined `$804D` continuation: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			if String(worker.get("status", "")) == "slot11_actor_parameter47_f2_delay_returned_to_804d":
				var f2_adoption: Dictionary = _scheduler.apply_slot11_actor_f2_postwait_return_result(worker)
				if not bool(f2_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM F2 parser return: " + _scheduler.error_message)
				var f2_gate_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
				worker = _slot11_actor_worker_resume_executor.execute_from_slot11_f5_animation_gate_boundary(f2_gate_boundary)
				if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
					return _fail_result("Slot-$11 F2 zero-mode gate stopped before `$8047`: " \
							+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
				save_result = _scheduler.apply_slot11_actor_parameter47_f2_delay_gate_result(worker)
				if not bool(save_result.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM F2 delay-gate yield: " + _scheduler.error_message)
				is_parameter47_f2_delay_gate_yield = true
				_last_source_boundary = "$CCD1->$807D->$806E reads `$01`; `$804D->$C560->$A1EB` zero-mode return -> `$8047->$CB0F`"
			elif String(worker.get("status", "")) == \
					"slot11_actor_scenario2e_actor6d_f2_parser_delay_returned_to_804d":
				var actor6d_parser_adoption: Dictionary = \
						_scheduler.apply_slot11_scenario2e_actor6d_f4_delay_return_result(worker)
				if not bool(actor6d_parser_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM actor-$6D F4 parser continuation: " + _scheduler.error_message)
				var actor6d_gate_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
				worker = _slot11_actor_worker_resume_executor.execute_from_slot11_f5_animation_gate_boundary(
						actor6d_gate_boundary)
				if not bool(worker.get("ok", false)) \
						 or String(worker.get("status", "")) != \
							"slot11_actor_scenario2e_actor6d_f4_delay_gate_at_8047" \
						 or int(worker.get("exit_pc", -1)) != 0x8047:
					return _fail_result("Slot-$11 actor-$6D F4 delay gate stopped before `$8047`: " \
							+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
				save_result = _scheduler.apply_slot11_actor_scenario2e_actor6d_f4_delay_gate_result(worker)
				if not bool(save_result.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM actor-$6D F4 delay gate: " + _scheduler.error_message)
				is_parameter47_f2_delay_gate_yield = true
				_last_source_boundary = "$CCD1 RTS->$807D->$806E; F4 $01/$02 -> $9BEA/$9BFE; `$01` delay -> `$804D->$C560->$A1EB F4=0->$8047->$C515->$CB0F`"
			elif String(worker.get("status", "")) == \
					"slot11_actor_scenario1c_parameter00_f2_terminal_returned_to_804d":
				save_result = _scheduler.apply_slot11_scenario1c_parameter00_f2_terminal_return_result(worker)
				if not bool(save_result.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM scenario-$1C `$F0` actor return: " + _scheduler.error_message)
				is_scenario1c_terminal_return = true
				var terminal_animation_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
				worker = _slot11_actor_worker_resume_executor.execute_from_slot11_f5_animation_gate_boundary(
					terminal_animation_boundary)
				if not bool(worker.get("ok", false)) \
						or String(worker.get("status", "")) != "slot11_actor_scenario1c_f0_zero_mode_gate_at_8047" \
						or int(worker.get("exit_pc", -1)) != 0x8047:
					return _fail_result("Slot-$11 scenario-$1C `$F0` zero-mode return stopped before `$8047`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
				var terminal_animation_adoption: Dictionary = \
					_scheduler.apply_slot11_actor_scenario1c_f0_zero_mode_gate_result(worker)
				if not bool(terminal_animation_adoption.get("ok", false)):
					return _fail_result("Scheduler rejected the scenario-$1C `$F0` zero-mode yield: " \
						+ _scheduler.error_message)
				save_result = terminal_animation_adoption
				slot11_gate_result_preapplied = true
				_last_source_boundary = "$CCD1->$807D->$806E reads `$F0`; `$8098` clears `$05E3`->$804D->$C560->$CF72->$A1EB F4=0 RTS->$8047->$C515->$CB0F"
			else:
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
			is_animation_busy_gate = bool(worker.get("ok", false)) \
					and String(worker.get("status", "")) == "slot11_f5_animation_busy_gate_at_cb0f_from_a217"
			if is_animation_busy_gate:
				save_result = _scheduler.apply_slot11_f5_animation_gate_result(worker)
				if not bool(save_result.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM `$A21A->$A215->$A217` busy-queue yield: " + _scheduler.error_message)
				_pending_slot11_a21a_queue_wait = true
				_last_source_boundary = "$A21A BNE->$A215->$A217->$CB0F queue-busy yield; resumes at $A21A"
			elif not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Slot-$11 `$A21A` packet builder stopped before the `$8047` actor yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			else:
				save_result = _scheduler.apply_slot11_f5_animation_queue_result(worker)
				if not bool(save_result.get("ok", false)):
					return _fail_result("Scheduler rejected the ROM `$A21A` PPU packet queue: " + _scheduler.error_message)
				_pending_slot11_a21a_queue_wait = false
		elif int(dispatch.get("pc", -1)) == 0x82F7 \
				and (is_packet_wait_resume or is_scenario1c_parameter58_packet_wait_resume \
					or is_scenario1c_parameter58_followup_packet_wait_resume \
					or is_parameter47_f2_index1_packet_wait_resume \
					or is_parameter47_f2_index2_packet_wait_resume \
					or is_scenario2e_actor6d_type5_packet_wait_resume):
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_packet_wait_resume_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != "slot11_actor_packet_resume_at_cb0f" \
					or int(worker.get("yield_callsite_pc", -1)) != 0x8047 \
					or int(worker.get("resume_pc_after_rts", -1)) != 0x804A \
					or int(worker.get("exit_pc", -1)) != 0xCB0F:
				return _fail_result("Slot-$11 `$82F7` packet builder stopped before its `$8047->$C515->$CB0F` yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			is_packet_resume_result = true
			_last_source_boundary = "$82F7 scenario-$2E actor-$6D type-$05 packet -> $8047->$C515->$CB0F; resumes at $804A" \
				if is_scenario2e_actor6d_type5_packet_wait_resume else "$82F7 scenario-$1C parameter-$58 follow-up text packet -> $8047->$C515->$CB0F" \
				if is_scenario1c_parameter58_followup_packet_wait_resume else "$82F7 scenario-$1C parameter-$58 packet -> $8047->$C515->$CB0F" \
				if is_scenario1c_parameter58_packet_wait_resume else "$82F7 parameter-$47 index-$02 packet -> $8047->$C515->$CB0F" \
				if is_parameter47_f2_index2_packet_wait_resume else "$82F7 ROM event/text packet -> $8047->$C515->$CB0F"
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and is_a439_inactive_zero_mode_resume:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != "slot11_actor_rom_stream_delay_at_8047" \
					or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Slot-$11 `$A439` inactive-worker and zero-mode returns stopped before `$8047`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_countdown_result(worker)
			if not bool(save_result.get("ok", false)) \
					or String(save_result.get("status", "")) != "slot11_actor_rom_stream_delay_saved_at_cb0f":
				return _fail_result("Scheduler rejected the ROM `$A439` inactive-worker zero-mode return: " + _scheduler.error_message)
			_last_source_boundary = "$A439->$8053 inactive RTS->$CF72/$CE2D->$A1EB F4=0->$8047->$CB0F"
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and is_scenario1c_f0_inactive_zero_mode_resume:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != "slot11_actor_scenario1c_f0_inactive_zero_mode_resume_at_8047" \
					or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Scenario-$1C F0 inactive worker zero-mode return stopped before `$8047`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_countdown_result(worker)
			if not bool(save_result.get("ok", false)) \
					or String(save_result.get("status", "")) != "slot11_actor_rom_stream_delay_saved_at_cb0f":
				return _fail_result("Scheduler rejected scenario-$1C F0 inactive-worker zero-mode return: " + _scheduler.error_message)
			_last_source_boundary = "$9400 scenario-$1C F0; $804A->$8053 E3=0 RTS; $A1EB F4=0 RTS->$8047->$CB0F"
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and is_scenario1e_actor58_inactive_zero_mode_resume:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != "slot11_actor_scenario1e_actor58_inactive_zero_mode_resume_at_8047" \
					or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Scenario-$1E actor-$58 F4=0 inactive return stopped before `$8047`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_countdown_result(worker)
			if not bool(save_result.get("ok", false)) \
					or String(save_result.get("status", "")) != "slot11_actor_rom_stream_delay_saved_at_cb0f":
				return _fail_result("Scheduler rejected the scenario-$1E actor-$58 F4=0 inactive return: " + _scheduler.error_message)
			_last_source_boundary = "$9A62 scenario-$1E/$58; `$8053` E3=0 RTS; `$A1EB` F4=0 RTS; `$8047->$CB0F`"
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and (is_selector03_row02_animation_gate or is_a439_text_terminal_inactive_gate \
				or is_scenario1c_parameter58_followup_text_terminal_inactive_gate \
				or is_a439_inactive_zero_counter_gate or is_parameter47_f2_terminal_inactive_gate \
				or is_parameter47_f2_animation_script_zero_counter_gate \
				or is_scenario1c_parameter58_zero_counter_queue_busy_gate \
				or is_scenario1e_actor58_zero_counter_gate):
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != ("slot11_actor_parameter47_f2_post_packet_zero_counter_gate_at_cb0f_from_a217" \
						if is_parameter47_f2_animation_script_zero_counter_gate \
						and animation_stream_pointer in [0xA2D1, 0xA2D3, 0xA2D5, 0xA2D7, 0xA2D9, 0xA2DB, 0xA2DD, 0xA2DF, 0xA2E1, 0xA2E3, 0xA2E5] else "slot11_f5_animation_gate_at_cb0f_from_a217") \
					or int(worker.get("exit_pc", -1)) != 0xCB0F:
				return _fail_result("Slot-$11 selector-$03 row-$02 animation gate stopped before `$A217->$CB0F`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_gate_result(worker)
			if not bool(save_result.get("ok", false)):
				return _fail_result("Scheduler rejected the selector-$03 row-$02 animation gate: " + _scheduler.error_message)
			slot11_gate_result_preapplied = true
			if is_parameter47_f2_terminal_inactive_gate:
				_last_source_boundary = "$9920 parameter-$47 $F0 -> $8098 clears E3; inactive worker RTS; $A1EB F4=1/$A20C F5=0 -> $A217->$CB0F"
			elif is_parameter47_f2_animation_script_zero_counter_gate:
				_last_source_boundary = "$9917 parameter-$47 saved actor; E3=0 RTS; $A1EB F4=1/$A20C F5=0 -> $A217->$CB0F"
			elif is_scenario1c_parameter58_followup_text_terminal_inactive_gate:
				_last_source_boundary = "$9A6F=$F0 terminal -> $8098 clears E3; inactive worker RTS; $A1EB/$A20C F5=0 -> $A217->$CB0F"
			elif is_scenario1c_parameter58_zero_counter_queue_busy_gate:
				_last_source_boundary = "$9A62 scenario-$1C/$58; $8053 E3=0 RTS; $A20C F5=0->$A217->$C515->$CB0F; resumes at $A21A with queue $80"
			elif is_scenario1e_actor58_zero_counter_gate:
				_last_source_boundary = "$9A62 scenario-$1E/$58; $8053 E3=0 RTS; $A20C F5=0->$A217->$C515->$CB0F"
			elif is_a439_text_terminal_inactive_gate or is_a439_inactive_zero_counter_gate:
				_last_source_boundary = "$A439 $F0 terminal -> $8098 -> $A1EB/$A20C -> $A217->$CB0F; resumes at $A21A"
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and is_scenario2e_actor6d_post_type5_animation_countdown:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != "slot11_actor_scenario2e_actor6d_type5_packet_wait_at_cb0f" \
					or int(worker.get("exit_pc", -1)) != 0xCB0F \
					or int(worker.get("yield_callsite_pc", -1)) != 0x82F4 \
					or int(worker.get("resume_pc_after_rts", -1)) != 0x82F7:
				return _fail_result("Frame-9496 actor-$6D packet wait did not follow `$82F2->$82F4->$C515->$CB0F` with resume `$82F7`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_actor_packet_wait_result(worker)
			if not bool(save_result.get("ok", false)):
				return _fail_result("Scheduler rejected the frame-9496 actor-$6D `$82F2` packet-wait yield: " + _scheduler.error_message)
			_last_source_boundary = "$804A->$8053 dispatch E4=$02->$82F2->$82F4->$C515->$CB0F; resumes at `$82F7`"
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and (is_animation_countdown_resume or is_selector03_post_packet_countdown \
				or is_selector03_animation_tail_idle):
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Slot-$11 animation countdown stopped before the `$8047` actor yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_f5_animation_countdown_result(worker)
			if not bool(save_result.get("ok", false)) \
					or (is_parameter47_f2_followup_delay_tick \
						and String(save_result.get("status", "")) != "slot11_actor_parameter47_f2_followup_delay_saved_at_cb0f"):
				return _fail_result("Scheduler rejected the ROM animation countdown: " + _scheduler.error_message)
		elif int(dispatch.get("pc", -1)) == 0x804A \
				and (is_selector03_packet_wait_start or is_parameter47_f2_index1_packet_wait_start \
					or is_parameter47_f2_index2_packet_wait_start \
					or is_scenario1c_parameter58_packet_wait_start \
					or is_scenario1c_parameter58_followup_packet_wait_start):
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) \
					or String(worker.get("status", "")) != "slot11_actor_packet_wait_at_cb0f" \
					or int(worker.get("exit_pc", -1)) != 0xCB0F:
				return _fail_result("Slot-$11 `$82F2` actor-packet handler stopped before its `$82F4->$CB0F` packet-wait yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
		elif int(dispatch.get("pc", -1)) == 0x804A and is_parameter47_f2_delay_tick:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_parameter47_f2_delay_tick_boundary(resume_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x804D:
				return _fail_result("Slot-$11 parameter-$47 F2 delay tick stopped before its `$804D` return: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_actor_parameter47_f2_delay_tick_result(worker)
			if not bool(save_result.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM F2 delay countdown to `$804D`: " + _scheduler.error_message)
			var f2_tick_gate_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_11)
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_f5_animation_gate_boundary(f2_tick_gate_boundary)
			if not bool(worker.get("ok", false)) or int(worker.get("exit_pc", -1)) != 0x8047:
				return _fail_result("Slot-$11 F2 countdown zero-mode gate stopped before `$8047`: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			save_result = _scheduler.apply_slot11_actor_parameter47_f2_delay_gate_result(worker)
			if not bool(save_result.get("ok", false)):
				return _fail_result("Scheduler rejected the ROM F2 countdown zero-mode yield: " + _scheduler.error_message)
			is_parameter47_f2_delay_gate_yield = true
			_last_source_boundary = "$804A->$8053 decrements F2 `$05E9`; `$804D->$C560->$A1EB` zero-mode return -> `$8047->$CB0F`"
		elif int(dispatch.get("pc", -1)) == 0x804A and is_parameter47_f2_type5_event:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_parameter47_f2_delay_tick_boundary(resume_boundary)
			is_actor_event_payload_yield = String(worker.get("status", "")) \
				== "slot11_actor_event_payload_at_cb0f"
			if not bool(worker.get("ok", false)) or not is_actor_event_payload_yield \
					or int(worker.get("exit_pc", -1)) != 0xCB0F \
					or int(worker.get("yield_callsite_pc", -1)) != 0x8266:
				return _fail_result("Slot-$11 parameter-$47 F2 type-$05 event stopped before its ROM `$8266->$CB0F` payload yield: " \
					+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			_last_source_boundary = "$9919=$51 -> $8218 type 5 -> $86BD/$8DCC -> $8FBF payload -> $8266->$CB0F"
		elif int(dispatch.get("pc", -1)) == 0x804A and is_scenario2e_actor6d_type5_event:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_scenario2e_actor6d_type5_event_boundary(resume_boundary)
			is_actor_event_payload_yield = String(worker.get("status", "")) \
				== "slot11_actor_event_payload_at_cb0f"
			if not bool(worker.get("ok", false)) or not is_actor_event_payload_yield \
					or int(worker.get("exit_pc", -1)) != 0xCB0F \
					or int(worker.get("yield_callsite_pc", -1)) != 0x8266:
				return _fail_result("Slot-$11 scenario-$2E actor-$6D type-$05 event stopped before its ROM `$8266->$CB0F` payload yield: " \
					+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			_last_source_boundary = "$9BFF=$52 -> $8218 type 5 -> $86BD/$8DCC -> $8FBF payload -> $8266->$CB0F"
		elif int(dispatch.get("pc", -1)) == 0x804A and is_actor_stream_delay_tick:
			worker = _slot11_actor_worker_resume_executor.execute_from_slot11_animation_countdown_boundary(resume_boundary)
			is_actor_event_payload_yield = String(worker.get("status", "")) \
					== "slot11_actor_event_payload_at_cb0f"
			if not bool(worker.get("ok", false)) \
					or (not is_actor_event_payload_yield and int(worker.get("exit_pc", -1)) != 0x8047) \
					or (is_actor_event_payload_yield and int(worker.get("exit_pc", -1)) != 0xCB0F) \
					or (is_scenario1c_parameter58_followup_text_terminal_tick \
						and String(worker.get("status", "")) != "slot11_actor_scenario1c_parameter58_followup_text_terminal_at_8047"):
				return _fail_result("Slot-$11 selector-$03 delay tick stopped before the `$8047` actor yield: " \
						+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))))
			if is_scenario1c_parameter58_followup_text_terminal_tick:
				_last_source_boundary = "$9A6F=$F0 -> $8098 terminal handler -> $8047; scenario-$1C/$58 follow-up text ends"
		else:
			return _fail_result("Slot-$11 waiter continuation dispatch resolved to an unsupported source PC `$%04X`." % int(dispatch.get("pc", -1)))
	else:
		worker = _slot11_actor_worker_resume_executor.execute_from_resumed_slot11_boundary(resume_boundary)
	if not bool(worker.get("ok", false)) \
		or (not is_parameter47_f2_delay_gate_yield \
			and not is_animation_resume and not is_animation_countdown_resume \
			and not is_selector03_post_packet_countdown and not is_selector03_row02_animation_gate \
			and not is_a439_text_terminal_inactive_gate \
			and not is_a439_inactive_zero_counter_gate \
			and not is_parameter47_f2_terminal_inactive_gate \
			and not is_parameter47_f2_animation_script_zero_counter_gate \
			and not is_a439_inactive_zero_mode_resume \
			and not is_scenario1c_f0_inactive_zero_mode_resume \
			and not is_scenario1e_actor58_inactive_zero_mode_resume \
			and not is_actor_stream_delay_tick and not is_selector03_animation_tail_idle \
			and not is_scenario1c_terminal_return \
				and int(worker.get("exit_pc", -1)) != 0xCB0F) \
		or (is_parameter47_f2_delay_gate_yield and int(worker.get("exit_pc", -1)) != 0x8047) \
		or (is_animation_busy_gate and int(worker.get("exit_pc", -1)) != 0xCB0F) \
		or ((is_animation_resume or is_animation_countdown_resume \
			or is_selector03_post_packet_countdown or is_actor_stream_delay_tick \
			or is_a439_inactive_zero_mode_resume \
			or is_scenario1c_f0_inactive_zero_mode_resume \
			or is_scenario1e_actor58_inactive_zero_mode_resume \
			or is_selector03_animation_tail_idle) \
				and not is_animation_busy_gate and not is_actor_event_payload_yield \
				and not is_scenario2e_actor6d_post_type5_animation_countdown \
				and int(worker.get("exit_pc", -1)) != 0x8047) \
			or (is_actor_event_payload_yield and int(worker.get("exit_pc", -1)) != 0xCB0F):
		return _fail_result("Slot-$11 ROM-byte actor continuation stopped before its `$CB0F` yield: " \
				+ String(worker.get("reason", worker.get("error", _slot11_actor_worker_resume_executor.error_message))) \
				+ " Route classifier: waiter=%s countdown=%s a439_gate=%s scenario1c_parameter58=%s record_match=%s dispatch=$%04X live_record=%s live_stream=$%04X live_anim=$%04X live_E3:E5=%s live_F3:F5=%s queue=%02X stack_size=%d stack[C7:CA]=%s regs=%02X/%02X/%02X pc/sp=$%04X/$%02X flags=$%02X/$%02X/$%02X profile_ram516=%s ram3a=%02X ram5d=%s ram522=%s ram5c7=%s ramE3=%s ramF3=%s ram_anim=%s." % [
					str(is_waiter_resume), str(is_animation_countdown_resume), str(is_a439_inactive_zero_counter_gate),
					str(is_scenario1c_parameter58_delay_tick), str(live_record == first_stream_record), int(dispatch.get("pc", -1)),
					live_record.hex_encode(),
					sequence_pointer,
					(int(live_ram[0x0063]) | (int(live_ram[0x0064]) << 8)) if live_ram.size() == 0x800 else -1,
					live_ram.slice(0x05E3, 0x05E6).hex_encode() if live_ram.size() == 0x800 else "invalid",
					live_ram.slice(0x05F3, 0x05F6).hex_encode() if live_ram.size() == 0x800 else "invalid",
					int(live_ram[0x0515]) if live_ram.size() == 0x800 else -1,
					live_stack.size(),
					live_stack.slice(0xC7, 0xCB).hex_encode() if live_stack.size() == 0x100 else "invalid",
					int(live_boundary.get("a", -1)), int(live_boundary.get("x", -1)), int(live_boundary.get("y", -1)),
					int(live_boundary.get("pc", -1)), int(live_boundary.get("sp", -1)),
					int(live_ram[0x0515]) if live_ram.size() == 0x800 else -1,
					int(live_ram[0x0022]) if live_ram.size() == 0x800 else -1,
					int(live_ram[0x0629]) if live_ram.size() == 0x800 else -1,
					live_ram.slice(0x0516, 0x051D).hex_encode() if live_ram.size() == 0x800 else "invalid",
					int(live_ram[0x003A]) if live_ram.size() == 0x800 else -1,
					live_ram.slice(0x005D, 0x0061).hex_encode() if live_ram.size() == 0x800 else "invalid",
					live_ram.slice(0x0522, 0x052B).hex_encode() if live_ram.size() == 0x800 else "invalid",
					live_ram.slice(0x05C7, 0x05D3).hex_encode() if live_ram.size() == 0x800 else "invalid",
					live_ram.slice(0x05E3, 0x05EB).hex_encode() if live_ram.size() == 0x800 else "invalid",
					live_ram.slice(0x05F3, 0x05F6).hex_encode() if live_ram.size() == 0x800 else "invalid",
					live_ram.slice(0x0063, 0x0065).hex_encode() if live_ram.size() == 0x800 else "invalid",
				])
	if not slot11_gate_result_preapplied and not is_final_packet_resume and not is_animation_resume and not is_animation_countdown_resume \
			and not is_selector03_post_packet_countdown and not is_selector03_row02_animation_gate \
			and not is_a439_text_terminal_inactive_gate \
			and not is_a439_inactive_zero_counter_gate \
			and not is_parameter47_f2_terminal_inactive_gate \
			and not is_parameter47_f2_animation_script_zero_counter_gate \
			and not is_a439_inactive_zero_mode_resume \
			and not is_scenario1c_f0_inactive_zero_mode_resume \
			and not is_scenario1e_actor58_inactive_zero_mode_resume \
			and not is_selector03_animation_tail_idle and not is_event_queue_return:
		if is_parameter47_f2_delay_tick:
			pass
		elif is_packet_resume_result:
			save_result = _scheduler.apply_slot11_actor_packet_resume_result(worker)
		elif is_selector03_packet_wait_start or is_parameter47_f2_index1_packet_wait_start \
				or is_parameter47_f2_index2_packet_wait_start \
				or is_scenario1c_parameter58_packet_wait_start \
				or is_scenario1c_parameter58_followup_packet_wait_start:
			save_result = _scheduler.apply_slot11_actor_packet_wait_result(worker)
		elif is_actor_event_payload_yield:
			save_result = _scheduler.apply_slot11_actor_waiter_resume_result(worker)
		elif is_actor_stream_delay_tick:
			save_result = _scheduler.apply_slot11_f5_animation_countdown_result(worker)
		elif is_waiter_resume:
			save_result = _scheduler.apply_slot11_actor_waiter_resume_result(worker)
		else:
			save_result = _scheduler.apply_slot11_actor_worker_resume_result(worker)
		var expected_save_status := "slot11_actor_resume_saved_at_cb0f"
		if is_parameter47_f2_delay_tick:
			expected_save_status = "slot11_actor_f2_delay_gate_saved_at_cb0f"
		elif is_packet_resume_result:
			expected_save_status = "slot11_actor_packet_resume_saved_at_cb0f"
		elif is_selector03_packet_wait_start or is_parameter47_f2_index1_packet_wait_start \
				or is_parameter47_f2_index2_packet_wait_start \
				or is_scenario1c_parameter58_packet_wait_start \
				or is_scenario1c_parameter58_followup_packet_wait_start:
			expected_save_status = "slot11_actor_packet_wait_saved_at_cb0f"
		elif is_actor_event_payload_yield:
			expected_save_status = "slot11_actor_waiter_resume_saved_at_cb0f"
		elif is_actor_stream_delay_tick:
			expected_save_status = "slot11_actor_sequence_selector03_delay_saved_at_cb0f"
			if is_scenario1c_parameter58_followup_text_terminal_tick:
				expected_save_status = "slot11_actor_scenario1c_parameter58_followup_text_terminal_saved_at_cb0f"
			elif is_scenario1c_parameter58_followup_post_packet_delay_tick:
				expected_save_status = "slot11_actor_scenario1c_parameter58_followup_post_packet_delay_saved_at_cb0f"
			elif is_scenario1c_parameter58_post_packet_delay_tick:
				expected_save_status = "slot11_actor_scenario1c_parameter58_post_packet_delay_saved_at_cb0f"
			elif is_a439_delay_tick or is_scenario2e_actor6d_9bfe_delay_tick \
					or is_scenario1c_parameter58_delay_tick \
					or is_a439_inactive_zero_mode_resume or is_parameter47_f2_delay_tick:
				expected_save_status = "slot11_actor_rom_stream_delay_saved_at_cb0f"
		elif is_waiter_resume:
			expected_save_status = "slot11_actor_waiter_resume_saved_at_cb0f"
		if not bool(save_result.get("ok", false)) \
				or String(save_result.get("status", "")) != expected_save_status:
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
		var waiter_continuation_name := "A21A queue-busy gate" if is_animation_busy_gate \
			else "A21A animation packet builder" if is_animation_resume \
			else "804A animation countdown" if is_animation_countdown_resume or is_selector03_post_packet_countdown \
			else "parameter-$47 terminal animation gate" if is_parameter47_f2_terminal_inactive_gate \
			else "A439 text terminal animation gate" if is_a439_text_terminal_inactive_gate \
			else "scenario-$1C parameter-$58 `$82F2` packet wait" if is_scenario1c_parameter58_packet_wait_start \
			else "scenario-$1C parameter-$58 follow-up `$82F2` packet wait" if is_scenario1c_parameter58_followup_packet_wait_start \
			else "82F2 parameter-$47 index-$02 packet wait" if is_parameter47_f2_index2_packet_wait_start \
			else "82F2 parameter-$47 index-$01 packet wait" if is_parameter47_f2_index1_packet_wait_start \
			else "82F2 selector-$03 packet wait" if is_selector03_packet_wait_start \
			else "actor event payload queue wait" if is_actor_event_payload_yield \
				else "scenario-$1C parameter-$58 follow-up text terminator" if is_scenario1c_parameter58_followup_text_terminal_tick \
				else "804A parameter-$47 F2 delay tick" if is_parameter47_f2_delay_tick \
			else "804A ROM `$A439` delay tick" if is_a439_delay_tick \
			else "scenario-$1C parameter-$58 follow-up post-packet text countdown" if is_scenario1c_parameter58_followup_post_packet_delay_tick \
			else "scenario-$1C parameter-$58 post-packet delay tick" if is_scenario1c_parameter58_post_packet_delay_tick \
			else "scenario-$1C parameter-$58 delay tick" if is_scenario1c_parameter58_delay_tick \
			else "804A actor-stream delay tick" if is_actor_stream_delay_tick \
			else "CC53 waiter resume" if int(dispatch.get("pc", -1)) == 0xCC53 \
			else "CCA3 counter-tail poll" if int(dispatch.get("pc", -1)) == 0xCCA3 \
			else "CCD1 F5 animation gate" if int(dispatch.get("pc", -1)) == 0xCCD1 else "actor-stream resume"
		_last_source_boundary = "$CAA5 selected slot $%02X after slot-$11 %s" % [
			next_slot, waiter_continuation_name if is_waiter_resume \
			else "scenario-$1C parameter-$58 post-packet delay tick" if is_scenario1c_parameter58_post_packet_delay_tick \
			else "actor-stream resume"]
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
		elif yield_callsite_pc == 0x8266:
			_last_source_boundary = "$8266->$C515->$CB0F slot-$11 event payload wait -> scheduler WAIT_FOR_NMI_READY"
		elif yield_callsite_pc == 0x82F4:
			_last_source_boundary = "$82F4->$C515->$CB0F slot-$11 row-$02 packet wait; resumes at $82F7 -> scheduler WAIT_FOR_NMI_READY"
		elif yield_callsite_pc == 0x8047 and is_packet_resume_result:
			_last_source_boundary = "$82F7 actor text packet -> $8047->$C515->$CB0F; scheduler awaits NMI consumption"
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
		"status": "slot11_actor_packet_resume_saved_and_scanned" if is_packet_resume_result \
			else "slot11_actor_packet_wait_saved_and_scanned" if (is_selector03_packet_wait_start \
				or is_parameter47_f2_index1_packet_wait_start or is_parameter47_f2_index2_packet_wait_start \
				or is_scenario1c_parameter58_packet_wait_start \
				or is_scenario1c_parameter58_followup_packet_wait_start) \
			else "slot11_parameter47_f2_terminal_animation_gate_saved_and_scanned" if is_parameter47_f2_terminal_inactive_gate \
			else "slot11_a439_text_terminal_animation_gate_saved_and_scanned" if is_a439_text_terminal_inactive_gate \
			else "slot11_selector03_row02_animation_gate_saved_and_scanned" if is_selector03_row02_animation_gate \
			else "slot11_event_queue_return_animation_saved_and_scanned" if is_event_queue_return \
			else "slot11_actor_event_payload_saved_and_scanned" if is_actor_event_payload_yield \
			else "slot11_actor_scenario1c_parameter58_followup_text_terminal_saved_and_scanned" if is_scenario1c_parameter58_followup_text_terminal_tick \
			else "slot11_actor_scenario1c_parameter58_followup_post_packet_delay_saved_and_scanned" if is_scenario1c_parameter58_followup_post_packet_delay_tick \
			else "slot11_actor_scenario1c_parameter58_post_packet_delay_saved_and_scanned" if is_scenario1c_parameter58_post_packet_delay_tick \
			else "slot11_actor_scenario1e_actor58_inactive_zero_mode_saved_and_scanned" if is_scenario1e_actor58_inactive_zero_mode_resume \
			else "slot11_actor_rom_stream_delay_saved_and_scanned" if is_a439_delay_tick \
			else "slot11_actor_sequence_selector03_delay_saved_and_scanned" if is_actor_stream_delay_tick \
			else "slot11_f5_animation_countdown_saved_and_scanned" if is_animation_countdown_resume \
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
func resume_selected_slot01_worker() -> Dictionary:
	error_message = ""
	if not _configured or _phase != "waiting_for_selected_task_source" \
			or _pending_selected_task_slot != SLOT_01:
		return _fail_result("Root slot-$01 resume requires its live scheduler-selected boundary.")
	var expected_boundary := _pending_selected_task_boundary
	var live_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_01)
	if live_boundary.is_empty():
		return _fail_result("The scheduler no longer exposes the selected root slot-$01 boundary.")
	for key: String in ["slot_base", "phase", "ready_delay", "pending_resume", "pc", "sp",
			"a", "x", "y", "bank_low", "bank_high", "active_task_slot"]:
		if int(live_boundary.get(key, -1)) != int(expected_boundary.get(key, -2)):
			return _fail_result("Selected root slot-$01 boundary changed at %s; refusing stale dispatch." % key)
	for key: String in ["record", "ram_image", "stack_page"]:
		if live_boundary.get(key, PackedByteArray()) != expected_boundary.get(key, PackedByteArray()):
			return _fail_result("Selected root slot-$01 %s changed before dispatch." % key)
	var dispatch: Dictionary = _scheduler.dispatch_pending_task(SLOT_01)
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0xCA52 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts":
		return _fail_result("Root slot-$01 did not restore its ROM `$CA52` continuation: " + str(dispatch))
	_pending_selected_task_slot = -1
	_pending_selected_task_boundary.clear()
	_pending_selected_task_mapper.clear()
	var dispatch_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_01)
	var first_call: Dictionary = _root_slot01_continuation.begin_from_slot01_yielded_resume(dispatch)
	if not bool(first_call.get("ok", false)) \
			or String(first_call.get("status", "")) != "call_requested" \
			or int(first_call.get("target_cpu_address", -1)) != 0xEE9F \
			or int(first_call.get("expected_return_pc", -1)) != 0xCA55:
		return _fail_result("Root slot-$01 caller did not request `$CA52->$EE9F`: " \
				+ _root_slot01_continuation.error_message)
	var ee9f_result: Dictionary = _ee9f_empty_actor_executor.execute_to_source_caller(
		dispatch, dispatch_boundary, first_call)
	if not bool(ee9f_result.get("ok", false)):
		var stopped_detail: Dictionary = ee9f_result.get("detail", {})
		var partial_state: Dictionary = ee9f_result.get("partial_state", {})
		var stopped_registers: Dictionary = partial_state.get("registers", {})
		return _fail_result("ROM-byte `$CA52->$EE9F` execution stopped (status=%s pc=$%04X): reason=%s error=%s detail=%s registers=%s" % [
			String(ee9f_result.get("status", "")), int(ee9f_result.get("stop_pc", -1)),
			String(ee9f_result.get("reason", "")), String(ee9f_result.get("error", "")),
			JSON.stringify(stopped_detail), JSON.stringify(stopped_registers)])
	if not _scheduler.adopt_root_slot01_callee_return_state(0xCA52, 0xEE9F, ee9f_result):
		return _fail_result("Scheduler rejected the source `$EE9F` return: " + _scheduler.error_message)
	var after_ee9f: Dictionary = _root_slot01_continuation.accept_callee_return(
		0xEE9F, 0xCA55, ee9f_result.get("registers", {}))
	if not bool(after_ee9f.get("ok", false)) \
			or String(after_ee9f.get("status", "")) != "call_requested" \
			or int(after_ee9f.get("target_cpu_address", -1)) != 0xE3CA \
			or int(after_ee9f.get("expected_return_pc", -1)) != 0xCA58:
		return _fail_result("Root slot-$01 caller did not request `$CA55->$E3CA`: " \
				+ _root_slot01_continuation.error_message)
	var e3ca_result: Dictionary = _e3ca_no_direction_executor.execute_from_source_call(
		ee9f_result, after_ee9f)
	if not bool(e3ca_result.get("ok", false)):
		return _fail_result("ROM-byte `$CA55->$E3CA` execution stopped: " \
				+ String(e3ca_result.get("error", e3ca_result.get("reason", "unsupported source state"))))
	if not _scheduler.adopt_root_slot01_callee_return_state(0xCA55, 0xE3CA, e3ca_result):
		return _fail_result("Scheduler rejected the source `$E3CA` return: " + _scheduler.error_message)
	var yield_request: Dictionary = _root_slot01_continuation.accept_callee_return(
		0xE3CA, 0xCA58, e3ca_result.get("registers", {}))
	if not bool(yield_request.get("ok", false)) \
			or String(yield_request.get("status", "")) != "yield_requested" \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or not _scheduler.adopt_root_slot01_loop_yield_call_state(yield_request):
		return _fail_result("Root slot-$01 did not produce its checked `$CA4F` yield: " \
				+ _root_slot01_continuation.error_message)
	if not _scheduler.yield_at_verified_callsite(SLOT_01, 0xCA4F,
			int(yield_request.get("delay_in_a", -1)), int(yield_request.get("sp", -1)),
			int(yield_request.get("x", -1)), int(yield_request.get("y", -1)),
			int(yield_request.get("bank_low", -1)), int(yield_request.get("bank_high", -1))):
		return _fail_result("Scheduler rejected the source root slot-$01 `$CA4F` yield: " + _scheduler.error_message)
	var scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(scan.get("ok", false)):
		return _fail_result("Scheduler scan after root slot-$01 yield failed: " + _scheduler.error_message)
	var next_slot := -1
	var next_boundary: Dictionary = {}
	var awaiting_nmi := false
	if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
		next_slot = int(scan.get("selected_slot_base", -1))
		next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
		_pending_selected_task_slot = next_slot
		_pending_selected_task_boundary = next_boundary.duplicate(true)
		var e3ca_mapper: Dictionary = e3ca_result.get("mapper", {})
		_pending_slot05_mapper_select = int(e3ca_mapper.get("register_select", -1)) \
			if next_slot == SLOT_05 else -1
		var selected_ram: PackedByteArray = next_boundary.get("ram_image", PackedByteArray())
		_pending_selected_task_mapper = {
			"bank_low": int(next_boundary.get("bank_low", -1)),
			"bank_high": int(next_boundary.get("bank_high", -1)),
			"select": ((int(selected_ram[0x0022]) | 0x07) & 0x07) if selected_ram.size() == 0x800 else -1,
		}
		_phase = "waiting_for_selected_task_source"
		_last_source_boundary = "$CAA5 selected slot $%02X after root slot-$01 yield" % next_slot
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CA4F root slot-$01 yield -> scheduler WAIT_FOR_NMI_READY"
		awaiting_nmi = true
	else:
		return _fail_result("Scheduler stopped after root slot-$01 at an unsupported boundary: %s" % str(scan))
	return {
		"ok": true,
		"status": "slot01_root_callers_yielded_and_scanned",
		"phase": _phase,
		"rom_sha256": ROM_SHA256,
		"selected_slot_boundary": live_boundary.duplicate(true),
		"selected_slot_dispatch": dispatch.duplicate(true),
		"selected_slot_dispatch_boundary": dispatch_boundary.duplicate(true),
		"ee9f_result": ee9f_result.duplicate(true),
		"e3ca_result": e3ca_result.duplicate(true),
		"yield_request": yield_request.duplicate(true),
		"yielded_boundary": _scheduler.get_task_boundary_snapshot(SLOT_01),
		"scheduler_scan": scan.duplicate(true),
		"next_selected_task_slot": next_slot,
		"next_selected_task_boundary": next_boundary.duplicate(true),
		"awaiting_external_nmi": awaiting_nmi,
		"nmi_cadence_generated": false,
		"trace_state_used": false,
	}


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
	var map_id := int(ram[0x05CC])
	var expected_terminal_record := PackedByteArray([0x00, 0xEA, 0x0B,
		0x13 if map_id in [0x2D, 0x56] else 0x12])
	if record == expected_terminal_record \
			and map_id in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56] \
			and int(ram[0x05C9]) == 0x00 \
			and (map_id != 0x51 or (int(ram[0x0518]) == 0x1C and int(ram[0x0524]) == 0x63)):
		return resume_selected_slot15_terminal_callback()
	var initial_map_cursor := record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C]) \
			and int(ram[0x05C9]) == 0x20 \
			and ((int(ram[0x05C7]) == 0x00 and int(ram[0x05C8]) == 0x00) \
				or (map_id in [0x00, 0x0E, 0x11, 0x12, 0x2F] \
					and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0) \
				or (map_id in [0x51, 0x52, 0x56] and int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0) \
				or (map_id == 0x42 and ((int(ram[0x05C7]) == 0x00 and int(ram[0x05C8]) == 0x00) \
					or (int(ram[0x05C7]) == 0x40 and int(ram[0x05C8]) == 0xA0))) \
				or (map_id in [0x2D, 0x36, 0x43, 0x52] and int(ram[0x05C7]) == 0x24 \
					and int(ram[0x05C8]) == 0x80))
	if initial_map_cursor:
		return resume_selected_slot15_map_worker()
	var continuation_map_index := 0x20 - int(ram[0x05C9])
	var continuation_placement := int(ram[0x05C8])
	var continuation_cursor_matches := (map_id in [0x00, 0x0E, 0x11, 0x12, 0x2F] and continuation_placement == 0xA0 + continuation_map_index) \
			or (map_id == 0x42 and (continuation_placement == continuation_map_index \
			or continuation_placement == 0xA0 + continuation_map_index)) \
			or (map_id in [0x2D, 0x36, 0x43] and continuation_placement == 0x80 + continuation_map_index) \
			or (map_id == 0x51 and continuation_placement == 0xA0 + continuation_map_index) \
			or (map_id == 0x52 and continuation_placement in [0x80 + continuation_map_index,
				0xA0 + continuation_map_index]) \
			or (map_id == 0x56 and continuation_placement == 0xA0 + continuation_map_index)
	var expected_continuation_record := PackedByteArray([0x00, 0xE9, 0x0B,
		0x13 if map_id in [0x2D, 0x56] else 0x12])
	if record == expected_continuation_record \
			and continuation_map_index in [3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			and map_id in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56] \
			and int(boundary.get("bank_high", -1)) == (0x13 if map_id in [0x2D, 0x56] else 0x12) \
			and continuation_cursor_matches:
		return resume_selected_slot15_map_worker()
	return _fail_result("Selected slot-$15 task record/RAM does not identify an implemented map-$%02X source boundary: record=%s PC=$%04X SP=$%02X banks=$%02X/$%02X cursor=$%02X placement=$%02X remaining=$%02X callback=$%02X map=$%02X ready=$%02X." % [
		map_id,
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
	var callback_id := int(entry_result.get("ram_image", PackedByteArray())[0x0524])
	var handler_result: Dictionary = {}
	var map_worker_result: Dictionary = {}
	if callback_id == 0x01:
		handler_result = _slot15_callback_f2_position_map_executor.execute_callback_01_from_dispatcher(entry_result)
		if not bool(handler_result.get("ok", false)):
			return _fail_result("ROM callback `$01` F0 path stopped before `$8525`: " + str(handler_result.get("error", "unknown source error")))
		if not _scheduler.adopt_slot15_callback_f2_map_worker_boundary(handler_result):
			return _fail_result("Scheduler rejected the ROM callback `$01` F0 `$814C->$8525` boundary: " + _scheduler.error_message)
		map_worker_result = handler_result
	elif callback_id == 0x72:
		handler_result = _slot15_callback_f2_position_map_executor.execute_from_callback_dispatcher(entry_result)
		if not bool(handler_result.get("ok", false)):
			return _fail_result("ROM callback `$72` F2 path stopped before `$8525`: " + str(handler_result.get("error", "unknown source error")))
		if not _scheduler.adopt_slot15_callback_f2_map_worker_boundary(handler_result):
			return _fail_result("Scheduler rejected the ROM callback `$72` F2 `$814C->$8525` boundary: " + _scheduler.error_message)
		map_worker_result = handler_result
	else:
		handler_result = _slot15_callback_dispatcher_executor.execute_fresh_callback(entry_result)
		if not bool(handler_result.get("ok", false)):
			return _fail_result("ROM callback `$%02X` stopped before its first handler: " % callback_id + str(handler_result.get("error", "unknown source error")))
		if not _scheduler.adopt_slot15_callback_handler_boundary(handler_result):
			return _fail_result("Scheduler rejected the ROM-byte callback `$%02X->$8327` boundary: " % int(handler_result.get("callback_id", -1)) + _scheduler.error_message)
		map_worker_result = _slot15_map_handler_prefix_executor.execute_from_handler_boundary(handler_result)
		if not bool(map_worker_result.get("ok", false)):
			return _fail_result("ROM callback `$%02X` map handler stopped before `$8525`: " % int(handler_result.get("callback_id", -1)) + str(map_worker_result.get("error", "unknown source error")))
		if not _scheduler.adopt_slot15_map_worker_entry(map_worker_result):
			return _fail_result("Scheduler rejected the ROM `$8327->$8525` map-worker entry: " + _scheduler.error_message)
	var callback_map_id := int(map_worker_result.get("map_selector", -1))
	var map_setup_result: Dictionary = _slot15_map_worker_prefix_executor.execute_map_to_first_yield_callsite(map_worker_result)
	if not bool(map_setup_result.get("ok", false)):
		return _fail_result("ROM map-$%02X worker stopped before its first `$C515` yield: " % callback_map_id + str(map_setup_result.get("error", "unknown source error")))
	if not _scheduler.adopt_slot15_map_worker_yield_callsite(map_setup_result):
		return _fail_result("Scheduler rejected the ROM map-$%02X setup at `$856F`: " % callback_map_id + _scheduler.error_message)
	var yield_registers: Dictionary = map_setup_result.get("registers", {})
	if not _scheduler.yield_at_verified_callsite(SLOT_15, 0x856F,
			int(yield_registers.get("a", -1)), int(yield_registers.get("sp", -1)),
			int(yield_registers.get("x", -1)), int(yield_registers.get("y", -1)),
			int(map_worker_result.get("mapper", {}).get("bank_low", -1)),
			int(map_worker_result.get("mapper", {}).get("bank_high", -1))):
		return _fail_result("Scheduler rejected the first map-$%02X `$856F->$C515` yield: " % callback_map_id + _scheduler.error_message)
	var post_yield_scan: Dictionary = _scheduler.scan_ready_tasks_once()
	if not bool(post_yield_scan.get("ok", false)) \
			or int(post_yield_scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		return _fail_result("The map-$%02X worker yield did not return the scheduler to its NMI wait: " % callback_map_id + str(post_yield_scan))
	_pending_selected_task_boundary.clear()
	_pending_selected_task_slot = -1
	_phase = "awaiting_external_nmi"
	_last_source_boundary = "slot-$15 map-$%02X worker reached `$856F->$C515`, saved through `$CB0F`, and returned to the scheduler NMI wait" % callback_map_id
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


## Resumes the selected map worker from its saved `$8572` continuation and
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
	var map_id := int(live_ram[0x05CC]) if live_ram.size() == 0x800 else -1
	var first_batch_cursor := (map_id in [0x00, 0x0E, 0x11, 0x12, 0x2F] and int(live_ram[0x05C7]) == 0x40 \
			and int(live_ram[0x05C8]) == 0xA0) \
			or (map_id == 0x42 and ((int(live_ram[0x05C7]) == 0x00 \
			and int(live_ram[0x05C8]) == 0x00) \
			or (int(live_ram[0x05C7]) == 0x40 and int(live_ram[0x05C8]) == 0xA0))) \
			or (map_id in [0x2D, 0x36, 0x43, 0x52] and int(live_ram[0x05C7]) == 0x24 and int(live_ram[0x05C8]) == 0x80) \
			or (map_id in [0x51, 0x52, 0x56] and int(live_ram[0x05C7]) == 0x40 and int(live_ram[0x05C8]) == 0xA0)
	var first_batch_boundary := live_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C]) \
			and live_ram.size() == 0x800 and int(live_ram[0x05C9]) == 0x20 \
			and map_id in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56] and first_batch_cursor
	var continuation_map_index := 0x20 - int(live_ram[0x05C9]) if live_ram.size() == 0x800 else -1
	var continuation_placement := int(live_ram[0x05C8]) if live_ram.size() == 0x800 else -1
	var continuation_cursor_matches := (map_id in [0x00, 0x0E, 0x11, 0x12, 0x2F] and continuation_placement == 0xA0 + continuation_map_index) \
			or (map_id == 0x42 and (continuation_placement == continuation_map_index \
			or continuation_placement == 0xA0 + continuation_map_index)) \
			or (map_id in [0x2D, 0x36, 0x43] and continuation_placement == 0x80 + continuation_map_index) \
			or (map_id == 0x51 and continuation_placement == 0xA0 + continuation_map_index) \
			or (map_id in [0x52, 0x56] and continuation_placement in [0x80 + continuation_map_index,
				0xA0 + continuation_map_index])
	var expected_continuation_record := PackedByteArray([0x00, 0xE9, 0x0B, 0x13]) \
		if map_id in [0x2D, 0x56] else PackedByteArray([0x00, 0xE9, 0x0B, 0x12])
	var continuation_batch_boundary := live_record == expected_continuation_record \
			and live_ram.size() == 0x800 \
			and continuation_map_index in [3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			and map_id in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56] and continuation_cursor_matches
	if int(live_boundary.get("pc", -1)) != 0xCB0F \
			or int(live_boundary.get("pending_resume", -1)) != 2 \
			or not (first_batch_boundary or continuation_batch_boundary):
		return _fail_result("Map-$%02X continuation is not a source-saved slot-$15 `$C515` batch boundary: record=%s expected=%s pc=$%04X phase=%d resume=%d q/pos/rem/selector=%s regs=$%02X/$%02X/$%02X/$%02X banks=$%02X/$%02X index=%d placement=$%02X cursor_ok=%s first=%s continuation=%s ram=%d." % [
			map_id, live_record.hex_encode(), expected_continuation_record.hex_encode(), int(live_boundary.get("pc", -1)),
			int(live_boundary.get("phase", -1)), int(live_boundary.get("pending_resume", -1)),
			live_ram.slice(0x05C7, 0x05CB).hex_encode(), int(live_boundary.get("a", -1)),
			int(live_boundary.get("x", -1)), int(live_boundary.get("y", -1)),
			int(live_boundary.get("sp", -1)), int(live_boundary.get("bank_low", -1)),
			int(live_boundary.get("bank_high", -1)), continuation_map_index, continuation_placement,
			str(continuation_cursor_matches), str(first_batch_boundary), str(continuation_batch_boundary), live_ram.size()])
	var mapper := _mapper_snapshot_for_task_boundary(live_boundary)
	if int(mapper.get("bank_low", -1)) != 0x0B \
		or int(mapper.get("bank_high", -1)) != (0x0C if first_batch_boundary else (0x13 if map_id in [0x2D, 0x56] else 0x12)):
		return _fail_result("Selected map-$%02X task does not retain its source CHR/PRG bank state." % map_id)
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
		return _fail_result("ROM map-$%02X worker could not build its first batch: " % map_id + String(batch.get("error", "unknown source error")))
	var queue_busy_yield := String(batch.get("status", "")) == "map_worker_queue_busy_yield_at_856F"
	if queue_busy_yield:
		if not _scheduler.adopt_slot15_map_busy_queue_yield_result(batch):
			return _fail_result("Scheduler rejected the ROM `$0515` busy-queue `$856F` yield: " + _scheduler.error_message)
	elif not _scheduler.adopt_slot15_map_batch_result(batch):
		return _fail_result("Scheduler rejected the ROM-derived map-$%02X batch: " % map_id + _scheduler.error_message)
	var registers: Dictionary = batch.get("registers", {})
	var mapper_after: Dictionary = batch.get("mapper", {})
	var map_yield_callsite := int(batch.get("callsite_pc", -1))
	if not _scheduler.yield_at_verified_callsite(SLOT_15, map_yield_callsite,
			int(registers.get("a", -1)), int(registers.get("sp", -1)),
			int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(mapper_after.get("bank_low", -1)), int(mapper_after.get("bank_high", -1))):
		return _fail_result("Scheduler rejected the resumed map-$%02X `$856F->$C515` yield: " % map_id + _scheduler.error_message)
	var scan_results: Array[Dictionary] = []
	var scan: Dictionary = {}
	for scan_index in range(8):
		scan = _scheduler.scan_ready_tasks_once()
		if not bool(scan.get("ok", false)):
			return _fail_result("Scheduler scan after map-$%02X batch yield failed: " % map_id + _scheduler.error_message)
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
		_last_source_boundary = "$CAA5 selected slot $%02X after map-$%02X batch yield" % [next_slot, map_id]
	elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
		_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
		if _pending_nmi_queue_state.is_empty() \
				or int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) != 0x80:
			return _fail_result("Map-$%02X batch did not leave a ready secondary queue for normal NMI." % map_id)
		_phase = "awaiting_external_nmi"
		_last_source_boundary = "$CB0F slot-$15 map-$%02X batch save -> scheduler WAIT_FOR_NMI_READY" % map_id
		awaiting_nmi = true
	else:
		return _fail_result("Map-$%02X batch yield stopped at an unsupported scheduler decision: %s" % [map_id, str(scan)])
	return {
		"ok": true,
		"status": "slot15_map%02X_batch_yielded" % map_id,
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
		"map_worker_rows_executed": not queue_busy_yield,
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
		return _fail_result("Terminal map return requires the live scheduler-selected slot-$15 boundary.")
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
	if live_ram.size() != 0x800:
		return _fail_result("Selected terminal slot-$15 boundary has no complete RAM image.")
	var map_id := int(live_ram[0x05CC])
	var map42_placement_branch := map_id == 0x42 and int(live_ram[0x05C7]) == 0x24 \
		and int(live_ram[0x05C8]) == 0xC0 and int(live_ram[0x05CD]) == 0xA0
	var map42_zero_branch := map_id == 0x42 and int(live_ram[0x05C7]) == 0x40 \
		and int(live_ram[0x05C8]) == 0x20 and int(live_ram[0x05CD]) == 0
	var map43_placement_branch := map_id == 0x43 and int(live_ram[0x05C7]) == 0x40 \
		and int(live_ram[0x05C8]) == 0xA0 and int(live_ram[0x05CD]) == 0x80
	var map36_final_page_branch := map_id == 0x36 and int(live_ram[0x05C7]) == 0x40 \
		and int(live_ram[0x05C8]) == 0xA0 and int(live_ram[0x05C9]) == 0x00 \
		and int(live_ram[0x05CA]) == 0x01 and int(live_ram[0x05CD]) == 0x80
	var map52_placement_branch := map_id == 0x52 and int(live_ram[0x05C7]) == 0x40 \
		and int(live_ram[0x05C8]) == 0xA0 and int(live_ram[0x05CD]) == 0x80
	var map52_final_page_branch := map_id == 0x52 and int(live_ram[0x05C7]) == 0x24 \
		and int(live_ram[0x05C8]) == 0xC0 and int(live_ram[0x05C9]) == 0x00 \
		and int(live_ram[0x05CA]) == 0x00 and int(live_ram[0x05CD]) == 0xA0
	var map51_final_page_branch := map_id == 0x51 and int(live_ram[0x05C7]) == 0x24 \
		and int(live_ram[0x05C8]) == 0xC0 and int(live_ram[0x05C9]) == 0x00 \
		and int(live_ram[0x05CA]) == 0x00 and int(live_ram[0x05CD]) == 0xA0
	var map2d_final_page_branch := map_id == 0x2D and int(live_ram[0x05C7]) == 0x40 \
		and int(live_ram[0x05C8]) == 0xA0 and int(live_ram[0x05C9]) == 0x00 \
		and int(live_ram[0x05CA]) == 0x02 and int(live_ram[0x05CD]) == 0x80
	var map2f_final_page_branch := map_id == 0x2F and int(live_ram[0x05C7]) == 0x24 \
		and int(live_ram[0x05C8]) == 0xC0 and int(live_ram[0x05C9]) == 0x00 \
		and int(live_ram[0x05CA]) == 0x01 and int(live_ram[0x05CC]) == 0x2F \
		and int(live_ram[0x05CD]) == 0xA0
	var map56_final_page_branch := map_id == 0x56 and int(live_ram[0x05C7]) == 0x24 \
		and int(live_ram[0x05C8]) == 0xC0 and int(live_ram[0x05C9]) == 0x00 \
		and int(live_ram[0x05CA]) == 0x02 and int(live_ram[0x05CD]) == 0xA0
	var map_f0_placement_branch := map_id in [0x00, 0x0E, 0x11, 0x12] and int(live_ram[0x05C7]) == 0x24 \
		and int(live_ram[0x05C8]) == 0xC0 and int(live_ram[0x05CD]) == 0xA0
	var expected_terminal_record := PackedByteArray([0x00, 0xEA, 0x0B,
		0x13 if map_id in [0x2D, 0x56] else 0x12])
	if live_boundary.get("record", PackedByteArray()) != expected_terminal_record \
			or int(live_boundary.get("pc", -1)) != 0xCB0F \
		or map_id not in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56] or (map_id == 0x51 and (int(live_ram[0x0518]) != 0x1C or int(live_ram[0x0524]) != 0x63)) \
			or int(live_ram[0x05C9]) != 0x00 \
			or not (map_f0_placement_branch or map42_placement_branch or map42_zero_branch \
				or map36_final_page_branch or map43_placement_branch or map52_placement_branch \
				or map51_final_page_branch or map52_final_page_branch or map56_final_page_branch or map2d_final_page_branch \
				or map2f_final_page_branch):
		return _fail_result("Slot-$15 is not at a supported exhausted map-$%02X row boundary: record=%s PC=$%04X cursor=$%02X placement=$%02X remaining=$%02X callback=$%02X." % [
			map_id, (live_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
			int(live_boundary.get("pc", -1)), int(live_ram[0x05C7]), int(live_ram[0x05C8]),
			int(live_ram[0x05C9]), int(live_ram[0x05CD])])
	var mapper := _mapper_snapshot_for_task_boundary(live_boundary)
	if int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != (0x13 if map_id in [0x2D, 0x56] else 0x12):
		return _fail_result("Terminal map-$%02X task did not retain its source bank-$0B worker state." % map_id)
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
	var result: Dictionary = _slot15_map_terminal_return_executor.execute_from_exhausted_map_worker(
		dispatch, executor_boundary)
	if not bool(result.get("ok", false)):
		return _fail_result("ROM-byte map-$%02X terminal return stopped: %s" % [map_id, String(result.get("error", "unknown source error"))])
	if not _scheduler.adopt_slot15_map_terminal_return_result(result):
		return _fail_result("Scheduler rejected the map-$%02X terminal return: " % map_id + _scheduler.error_message)
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
		"status": "slot15_map%02X_terminal_callback_finished_waiting_nmi" % map_id,
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
	var queue_transferred := String(secondary_queue.get("status", "")) == "transferred" \
		and queue_branch in ["primary_queue_consumed", "secondary_queue_consumed"] \
		and not ppu_bus_events.is_empty()
	var source_queue_empty_at_nmi := String(secondary_queue.get("status", "")) == "skipped" \
		and queue_branch == "secondary_queue_not_ready" \
		and int(secondary_queue.get("ready_flag_before", -1)) == 0 \
		and int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) == 0 \
		and int(_pending_nmi_queue_state.get("primary_count_0498", -1)) == 0 \
		and ppu_bus_events.is_empty()
	if String(_last_nmi_result.get("path", "")) != "fixed_normal" \
			or not (queue_transferred or source_queue_empty_at_nmi):
		return _fail_result("Second NMI did not follow a supported source-owned normal PPU queue branch: " + str(secondary_queue))
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
					+ String(slot01_e3ca_result.get("error", slot01_e3ca_result.get("reason", "unsupported source state"))))
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
		_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_selected_boundary)
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
			"waiting_for_slot09_eb8b_source", "pass_receiver_input_ready", "first_action_menu_ready"]:
		return _fail_result("Controller sampling requires a live source-route boundary.")
	if _hold_pass_confirmation_input_state and _phase != "first_action_menu_ready":
		return {"ok": true, "phase": _phase,
			"sample": {"status": "pass_confirmation_input_retained_until_handler_entry",
				"sampled": false, "deferred_button_state": button_state & 0xFF},
			"pending_selected_task_slot": _pending_selected_task_slot,
			"pending_selected_task_boundary_pc": int(_pending_selected_task_boundary.get("pc", -1))}
	if _phase == "first_action_menu_ready":
		var action_menu_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var boundary_ram: Variant = action_menu_boundary.get("ram_image", PackedByteArray())
		if _pending_selected_task_slot != SLOT_05 \
				or int(action_menu_boundary.get("slot_base", -1)) != SLOT_05 \
				or int(action_menu_boundary.get("active_task_slot", -1)) != SLOT_05 \
				or int(action_menu_boundary.get("phase", -1)) != 2 \
				or int(action_menu_boundary.get("pc", -1)) != 0xD5EA \
				or int(action_menu_boundary.get("bank_low", -1)) != 0x1A \
				or int(action_menu_boundary.get("bank_high", -1)) != 0x1B \
				or not boundary_ram is PackedByteArray or boundary_ram.size() != RAM_SIZE \
				or _last_slot05_action_menu_wait_result.is_empty() \
				or not _scheduler.validate_slot05_action_menu_wait_worker_result(
					_last_slot05_action_menu_wait_result):
			return _fail_result("Action-menu input sampling requires the validated live slot-$05 `$D5EA` wait boundary.")
	if _phase == "pass_receiver_input_ready":
		var pass_receiver_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var pass_receiver_boundary_ram: Variant = pass_receiver_boundary.get("ram_image", PackedByteArray())
		if _pending_selected_task_slot != SLOT_05 \
				or int(pass_receiver_boundary.get("slot_base", -1)) != SLOT_05 \
				or int(pass_receiver_boundary.get("active_task_slot", -1)) != SLOT_05 \
				or int(pass_receiver_boundary.get("phase", -1)) != 2 \
				or int(pass_receiver_boundary.get("pc", -1)) != 0xD80F \
				or int(pass_receiver_boundary.get("bank_low", -1)) != 0x1C \
				or int(pass_receiver_boundary.get("bank_high", -1)) != 0x1D \
				or not pass_receiver_boundary_ram is PackedByteArray \
				or pass_receiver_boundary_ram.size() != RAM_SIZE \
				or not bool(_scheduler.get_status().get("pass_receiver_input_wait_ready", false)):
			return _fail_result("PASS receiver input sampling requires the scheduler-armed live slot-$05 `$D80F` wait boundary.")
	var sample: Dictionary = _scheduler.sample_controller_input(button_state)
	if not bool(sample.get("ok", false)):
		return _fail_result("Source-frame controller sample was rejected: " + String(sample.get("error", _scheduler.error_message)))
	if _pending_selected_task_slot >= 0:
		var refreshed: Dictionary = _scheduler.get_task_boundary_snapshot(_pending_selected_task_slot)
		var expected_active_slot := SLOT_05 if _phase in ["pass_receiver_input_ready",
			"first_action_menu_ready"] else -1
		if refreshed.is_empty() or int(refreshed.get("active_task_slot", -1)) != expected_active_slot:
			return _fail_result("Controller sampling could not refresh the stable selected-task boundary.")
		_pending_selected_task_boundary = refreshed.duplicate(true)
	return {"ok": true, "phase": _phase, "sample": sample.get("sample", {}),
		"pending_selected_task_slot": _pending_selected_task_slot,
		"pending_selected_task_boundary_pc": int(_pending_selected_task_boundary.get("pc", -1))}


## Executes the bounded ROM-byte `$D5EA` poll against the scheduler's live
## slot-$05 boundary, then adopts only a source-verified PASS selection or
## confirmation result. Neutral/unsupported samples do not mutate task state.
func resolve_first_action_menu_source_poll(input_sample: Dictionary) -> Dictionary:
	error_message = ""
	_last_first_action_menu_dispatch_result.clear()
	_last_first_action_menu_adoption_result.clear()
	if not _configured or _phase != "first_action_menu_ready" \
			or _pending_selected_task_slot != SLOT_05 \
			or _first_action_dispatch_executor == null \
			or not _first_action_dispatch_executor.has_method("execute_from_live_action_menu_boundary") \
			or not input_sample.has("sample_receipt_id"):
		return _fail_result("First-action source poll requires the live slot-$05 `$D5EA` boundary and its controller receipt.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if boundary.is_empty() or int(boundary.get("pc", -1)) != 0xD5EA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B:
		return _fail_result("First-action source poll lost its validated `$D5EA` task boundary.")
	var dispatch: Dictionary = _first_action_dispatch_executor.call(
			"execute_from_live_action_menu_boundary", boundary, input_sample)
	_last_first_action_menu_dispatch_result = dispatch.duplicate(true)
	var dispatch_status := String(dispatch.get("status", ""))
	if dispatch_status in ["waiting_for_pass_selection", "waiting_for_a_edge",
			"waiting_for_source_input_poll", "no_source_input_edge"]:
		return {"ok": true, "status": dispatch_status,
			"dispatch": dispatch.duplicate(true), "source_input_consumed": false,
			"source_writes_applied": []}
	if not bool(dispatch.get("ok", false)):
		return _fail_result("ROM-byte first-action input poll failed: " + String(dispatch.get("error", "unknown source failure")))
	if dispatch_status not in ["pass_selection_applied", "pass_confirmation_handoff_resolved",
			"pass_handler_dispatched"]:
		return {"ok": true, "status": dispatch_status,
			"dispatch": dispatch.duplicate(true), "source_input_consumed": false,
			"source_writes_applied": []}
	var adoption: Dictionary = _scheduler.adopt_first_action_menu_input_result(dispatch)
	_last_first_action_menu_adoption_result = adoption.duplicate(true)
	if not bool(adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the ROM-byte first-action input result: " \
				+ String(adoption.get("error", _scheduler.error_message)))
	if dispatch_status == "pass_confirmation_handoff_resolved":
		if String(adoption.get("status", "")) != "pass_confirmation_pending_source_execution" \
				or int(adoption.get("source_boundary_pc", -1)) != 0xD5EA \
				or not bool(adoption.get("source_execution_pending", false)) \
				or adoption.has("resume_pc") or adoption.has("handler_entry_pc") \
				or adoption.has("next_boundary_snapshot"):
			return _fail_result("Scheduler confirmation must retain the live `$D5EA` state without claiming an unexecuted handler target.")
		var confirmation_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		if confirmation_boundary.is_empty() or int(confirmation_boundary.get("pc", -1)) != 0xD5EA:
			return _fail_result("Scheduler confirmation lost the current `$D5EA` boundary while source execution is pending.")
		_pending_selected_task_boundary = confirmation_boundary.duplicate(true)
		_pending_first_action_menu_handler_dispatch = {
			"source_boundary_pc": 0xD5EA,
			"sample_receipt_id": int(adoption.get("sample_receipt_id", -1)),
			"selection_action_id": int(adoption.get("selected_action_id", -1)),
			"source_execution_pending": true,
			"source_input_consumed": true,
		}
		_hold_pass_confirmation_input_state = true
	else:
		var next_boundary: Variant = adoption.get("next_boundary_snapshot", {})
		if not next_boundary is Dictionary or next_boundary.is_empty():
			return _fail_result("Scheduler accepted the input result but returned no live continuation boundary.")
		_pending_selected_task_boundary = next_boundary.duplicate(true)
	return {"ok": true, "status": String(adoption.get("status", "")),
		"dispatch": dispatch.duplicate(true), "adoption": adoption.duplicate(true),
		"source_input_consumed": true,
		"source_writes_applied": adoption.get("source_writes_applied", []).duplicate(true),
		"pending_handler_dispatch": _pending_first_action_menu_handler_dispatch.duplicate(true),
		"next_boundary_snapshot": _pending_selected_task_boundary.duplicate(true)}


## Returns the validated PASS handler target exactly once. It is still only a
## dispatch handoff until a source executor actually enters `$D7E8`.
func take_first_action_menu_handler_dispatch() -> Dictionary:
	var pending := _pending_first_action_menu_handler_dispatch.duplicate(true)
	_pending_first_action_menu_handler_dispatch.clear()
	return pending


## Executes the one-use confirmation bridge from the live `$D5EA` boundary,
## adopts its real `$CAA5` yield, and scans the scheduler. It executes `$CB99`
## only when a separate live source continuation reaches `$D6C7`.
func resume_pending_first_action_menu_pass_dispatch() -> Dictionary:
	error_message = ""
	if not _configured or _phase not in ["first_action_menu_ready",
			"first_action_pass_label_ready", "first_action_pass_dispatch_ready",
			"first_action_pass_handler_ready", "first_action_pass_cb0f_ready"] \
			or _first_action_dispatch_executor == null \
			or not _first_action_dispatch_executor.has_method(
				"execute_pass_cb99_from_live_d6c7_boundary") \
			or not _scheduler.has_method("adopt_first_action_menu_handler_dispatch"):
		return _fail_result("PASS dispatch continuation requires the pending confirmation and its source executor/adopter.")
	if _phase == "first_action_menu_ready" \
			and _pending_first_action_menu_handler_dispatch.is_empty():
		return _fail_result("PASS input dispatch requires the pending one-use confirmation receipt.")
	var boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
	if boundary.is_empty() or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B:
		return _fail_result("PASS source continuation lost the scheduler-owned slot-$05 context-zero boundary.")
	if int(boundary.get("pc", -1)) == 0xD5EA:
		if _first_action_confirmation_bridge_executor == null \
				or not _first_action_confirmation_bridge_executor.has_method(
					"execute_from_consumed_pass_confirmation") \
				or not _scheduler.has_method("adopt_first_action_confirmation_bridge_yield"):
			return _fail_result("PASS confirmation bridge executor or scheduler adopter is unavailable.")
		var confirmation: Dictionary = _last_first_action_menu_adoption_result.duplicate(true)
		var input_receipt: Dictionary = _last_first_action_menu_dispatch_result.get(
			"input_sample_receipt", {}).duplicate(true)
		var bridge: Dictionary = _first_action_confirmation_bridge_executor.call(
			"execute_from_consumed_pass_confirmation", boundary, input_receipt, confirmation)
		_last_first_action_confirmation_bridge_result = bridge.duplicate(true)
		if not bool(bridge.get("ok", false)):
			return _fail_result("ROM-byte PASS confirmation bridge failed: " \
				+ String(bridge.get("error", "unknown source failure")))
		var bridge_adoption: Dictionary = _scheduler.call(
			"adopt_first_action_confirmation_bridge_yield", bridge)
		_last_first_action_confirmation_bridge_adoption = bridge_adoption.duplicate(true)
		if not bool(bridge_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected the ROM `$CB0F->$CAA5` PASS yield: " \
				+ String(bridge_adoption.get("error", _scheduler.error_message)))
		if String(bridge_adoption.get("status", "")) != "pass_confirmation_yield_adopted" \
				or int(bridge_adoption.get("source_resume_pc", -1)) != 0xE945 \
				or int(bridge_adoption.get("active_task_slot", -1)) != -1 \
				or int(bridge_adoption.get("scheduler_scan_cursor", -1)) != 0x09:
			return _fail_result("Scheduler adopted the PASS yield without preserving its source `$E945` continuation and `$09` scan cursor.")
		var scan_results: Array[Dictionary] = []
		var scan: Dictionary = {}
		for scan_index in range(8):
			scan = _scheduler.scan_ready_tasks_once()
			if not bool(scan.get("ok", false)):
				return _fail_result("Scheduler scan after the live PASS `$CB0F` yield failed: " \
					+ String(scan.get("error", _scheduler.error_message)))
			scan_results.append(scan.duplicate(true))
			if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
				break
		_last_first_action_confirmation_bridge_scans = scan_results.duplicate(true)
		var next_slot := -1
		var next_boundary: Dictionary = {}
		if int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME):
			next_slot = int(scan.get("selected_slot_base", -1))
			next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
			if next_boundary.is_empty():
				return _fail_result("Scheduler selected a yielded PASS-route task without a live boundary snapshot.")
			_pending_selected_task_slot = next_slot
			_pending_selected_task_boundary = next_boundary.duplicate(true)
			_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary) \
				if next_slot == SLOT_09 else {}
			if next_slot == SLOT_09 and _pending_selected_task_mapper.is_empty():
				return _fail_result("Selected slot-$09 after PASS omitted its live mapper snapshot.")
			_phase = "waiting_for_selected_task_source"
			_last_source_boundary = "$CAA5 selected slot $%02X after PASS confirmation yield" % next_slot
		elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
			_pending_selected_task_slot = -1
			_pending_selected_task_boundary.clear()
			_pending_selected_task_mapper.clear()
			_phase = "awaiting_external_nmi"
			_last_source_boundary = "PASS `$CB0F` yield; `$CAA5` scheduler WAIT_FOR_NMI_READY"
		else:
			return _fail_result("Scheduler scan after PASS yield stopped at unsupported decision $%02X." % int(scan.get("decision", -1)))
		_pending_first_action_menu_handler_dispatch.clear()
		return {"ok": true, "status": "pass_confirmation_scheduler_handoff",
			"source_boundary_pc": 0xCAA5,
			"confirmation_bridge": bridge.duplicate(true),
			"bridge_adoption": bridge_adoption.duplicate(true),
			"scheduler_scan_results": scan_results.duplicate(true),
			"next_scheduler_phase": _phase,
			"next_selected_task_slot": next_slot,
			"next_selected_task_boundary": next_boundary.duplicate(true),
			"nmi_cadence_generated": false, "trace_state_used": false}
	if _phase == "first_action_pass_label_ready":
		if int(boundary.get("pc", -1)) != 0xD68A \
				or _pass_no_candidates_continuation_executor == null \
				or not _scheduler.has_method("adopt_first_action_pass_no_candidates_result"):
			return _fail_result("PASS no-candidates caller requires its adopted live `$D68A` boundary and scheduler adopter.")
		var no_candidates: Dictionary = _pass_no_candidates_continuation_executor.call(
			"execute_from_live_e945_renderer_return", boundary,
			_last_first_action_pass_label_return_receipt)
		_last_pass_no_candidates_continuation_result = no_candidates.duplicate(true)
		if not bool(no_candidates.get("ok", false)):
			return _fail_result("ROM-byte PASS no-candidates continuation failed: " \
				+ String(no_candidates.get("error", _pass_no_candidates_continuation_executor.error_message)))
		var no_candidates_adoption: Dictionary = _scheduler.call(
			"adopt_first_action_pass_no_candidates_result", no_candidates)
		_last_pass_no_candidates_continuation_adoption = no_candidates_adoption.duplicate(true)
		if not bool(no_candidates_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected the ROM PASS no-candidates continuation: " \
				+ String(no_candidates_adoption.get("error", _scheduler.error_message)))
		var d6c7_boundary: Variant = no_candidates_adoption.get("next_boundary_snapshot", {})
		if not d6c7_boundary is Dictionary or d6c7_boundary.is_empty() \
				or int(d6c7_boundary.get("pc", -1)) != 0xD6C7 \
				or int(d6c7_boundary.get("active_task_slot", -1)) != SLOT_05:
			return _fail_result("Scheduler adoption did not preserve the source-derived PASS caller `$D6C7` boundary.")
		_pending_selected_task_boundary = d6c7_boundary.duplicate(true)
		_phase = "first_action_pass_dispatch_ready"
		_last_source_boundary = "ROM PASS no-candidates caller returned to live slot-$05 `$D6C7`"
		return {"ok": true, "status": "pass_action_caller_reached_d6c7",
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"continuation": no_candidates.duplicate(true),
			"adoption": no_candidates_adoption.duplicate(true),
			"next_boundary_snapshot": d6c7_boundary.duplicate(true),
			"trace_state_used": false, "ppu_apu_effects_applied": false}
	if _phase == "first_action_pass_handler_ready":
		if _pass_handler_body_executor == null \
				or not _scheduler.has_method("adopt_first_action_pass_handler_body_result"):
			return _fail_result("PASS handler body executor or live-state adopter is unavailable.")
		var adopted_dispatch: Dictionary = _last_first_action_menu_adoption_result.get(
			"next_boundary_snapshot", {})
		var live_ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
		var live_stack: PackedByteArray = boundary.get("stack_page", PackedByteArray())
		if adopted_dispatch.is_empty() or int(adopted_dispatch.get("pc", -1)) != 0xD7E8 \
				or int(boundary.get("pc", -1)) != 0xD7E8 \
				or int(adopted_dispatch.get("sp", -1)) != int(boundary.get("sp", -2)) \
				or adopted_dispatch.get("ram_image", PackedByteArray()) != live_ram \
				or adopted_dispatch.get("stack_page", PackedByteArray()) != live_stack:
			return _fail_result("PASS handler entry snapshot is no longer identical to the scheduler-owned live `$D7E8` state.")
		adopted_dispatch["trace_state_used"] = false
		var handler_result: Dictionary = _pass_handler_body_executor.call(
			"execute_from_live_boundary", adopted_dispatch)
		_last_pass_handler_body_result = handler_result.duplicate(true)
		if not bool(handler_result.get("ok", false)):
			return _fail_result("ROM-byte PASS handler prefix failed: " \
				+ String(handler_result.get("error", _pass_handler_body_executor.error_message)))
		var handler_adoption: Dictionary = _scheduler.call(
			"adopt_first_action_pass_handler_body_result", handler_result)
		_last_pass_handler_body_adoption = handler_adoption.duplicate(true)
		if not bool(handler_adoption.get("ok", false)):
			return _fail_result("Scheduler rejected the PASS handler's `$CB0F` call-entry result: " \
				+ String(handler_adoption.get("error", _scheduler.error_message)))
		var cb0f_boundary: Dictionary = handler_adoption.get("next_boundary_snapshot", {})
		if cb0f_boundary.is_empty() or int(cb0f_boundary.get("pc", -1)) != 0xCB0F:
			return _fail_result("PASS handler adoption did not preserve the source `$CB0F` call-entry boundary.")
		_pending_selected_task_boundary = cb0f_boundary.duplicate(true)
		_phase = "first_action_pass_cb0f_ready"
		_last_source_boundary = "ROM PASS handler queued scenario `$38`; live `$CB0F` call entry"
		return {"ok": true, "status": "pass_scenario38_queue_at_cb0f_call_entry",
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"handler": handler_result.duplicate(true),
			"adoption": handler_adoption.duplicate(true),
			"next_boundary_snapshot": cb0f_boundary.duplicate(true),
			"scheduler_yield_executed": false, "trace_state_used": false}
	if _phase == "first_action_pass_cb0f_ready":
		var context: Variant = _scheduler._contexts.get(SLOT_05)
		if context == null or int(boundary.get("pc", -1)) != 0xCB0F \
				or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
				or int(boundary.get("sp", -1)) != int(context.stack_pointer) \
				or not _scheduler.has_method("yield_at_verified_callsite"):
			return _fail_result("PASS scenario `$38` CB0F save requires the scheduler-owned live slot-$05 call-entry boundary.")
		var caller_sp := (int(context.stack_pointer) + 2) & 0xFF
		if not bool(_scheduler.call("yield_at_verified_callsite", SLOT_05, 0xCBBE,
				int(context.accumulator), caller_sp, int(context.x_register),
				int(context.y_register), int(context.bank_low), int(context.bank_high), true)):
			return _fail_result("Scheduler rejected the ROM CBBE pre-pushed `$CB0F` yield: " + String(_scheduler.error_message))
		var saved_boundary: Dictionary = _scheduler.get_task_boundary_snapshot(SLOT_05)
		var scans: Array[Dictionary] = []
		var scan: Dictionary = {}
		for scan_index in range(8):
			scan = _scheduler.scan_ready_tasks_once()
			if not bool(scan.get("ok", false)):
				return _fail_result("Scheduler scan after the PASS scenario `$38` yield failed: " + String(_scheduler.error_message))
			scans.append(scan.duplicate(true))
			if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.CLEAR_NMI_AND_RESCAN):
				break
		var next_slot := -1
		var next_boundary: Dictionary = {}
		if int(scan.get("decision", -1)) in [int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME),
				int(SCHEDULER_SCRIPT.ScanDecision.INITIAL_DISPATCH)]:
			next_slot = int(scan.get("selected_slot_base", -1))
			next_boundary = _scheduler.get_task_boundary_snapshot(next_slot)
			if next_slot < 0 or next_boundary.is_empty() \
					or int(next_boundary.get("active_task_slot", -1)) != -1:
				return _fail_result("Post-CB0F scan did not yield a stable selected-task boundary.")
			_pending_selected_task_slot = next_slot
			_pending_selected_task_boundary = next_boundary.duplicate(true)
			if next_slot == SLOT_09:
				_pending_selected_task_mapper = _mapper_snapshot_for_task_boundary(next_boundary)
				if _pending_selected_task_mapper.is_empty():
					return _fail_result("Selected slot-$09 after the PASS yield omitted its live mapper snapshot.")
			else:
				_pending_selected_task_mapper.clear()
			_phase = "waiting_for_selected_task_source"
			_last_source_boundary = "PASS `$CBBE->$CB0F` save; `$CAA5` selected slot $%02X" % next_slot
		elif int(scan.get("decision", -1)) == int(SCHEDULER_SCRIPT.ScanDecision.WAIT_FOR_NMI_READY):
			_pending_selected_task_slot = -1
			_pending_selected_task_boundary.clear()
			_pending_selected_task_mapper.clear()
			_pending_nmi_queue_state = _scheduler.get_live_nmi_secondary_queue_state()
			_phase = "awaiting_external_nmi"
			_last_source_boundary = "PASS `$CBBE->$CB0F` save -> scheduler WAIT_FOR_NMI_READY"
		else:
			return _fail_result("Post-CB0F scheduler scan stopped at unsupported decision: " + str(scan))
		_last_pass_handler_cb0f_save_result = {
			"ok": true, "status": "pass_handler_cb0f_saved_and_scanned",
			"source_callsite_pc": 0xCBBE,
			"saved_boundary": saved_boundary.duplicate(true),
			"next_scheduler_phase": _phase,
			"next_selected_task_slot": next_slot,
			"next_selected_task_boundary": next_boundary.duplicate(true),
			"nmi_cadence_generated": false, "trace_state_used": false,
		}
		_last_pass_handler_cb0f_scans = scans.duplicate(true)
		return {"ok": true, "status": "pass_handler_scheduler_handoff",
			"phase": _phase, "rom_sha256": ROM_SHA256,
			"save": _last_pass_handler_cb0f_save_result.duplicate(true),
			"scheduler_scan_results": scans.duplicate(true),
			"next_selected_task_slot": next_slot,
			"next_selected_task_boundary": next_boundary.duplicate(true),
			"nmi_cadence_generated": false, "trace_state_used": false}
	if int(boundary.get("pc", -1)) != 0xD6C7:
		return _fail_result("PASS source continuation reached an unsupported CPU boundary before `$D6C7`.")
	var dispatch: Dictionary = _first_action_dispatch_executor.call(
			"execute_pass_cb99_from_live_d6c7_boundary", boundary)
	_last_first_action_menu_dispatch_result = dispatch.duplicate(true)
	if not bool(dispatch.get("ok", false)):
		return _fail_result("ROM-byte PASS dispatch continuation failed: " \
				+ String(dispatch.get("error", "unknown source failure")))
	var adoption: Dictionary = _scheduler.call(
			"adopt_first_action_menu_handler_dispatch", dispatch)
	_last_first_action_menu_adoption_result = adoption.duplicate(true)
	if not bool(adoption.get("ok", false)):
		return _fail_result("Scheduler rejected the ROM `$D6C7->$D7E8` handler dispatch: " \
				+ String(adoption.get("error", _scheduler.error_message)))
	var next_boundary: Variant = adoption.get("next_boundary_snapshot", {})
	if not next_boundary is Dictionary or next_boundary.is_empty() \
			or int(next_boundary.get("pc", -1)) != 0xD7E8:
		return _fail_result("Scheduler adopted PASS dispatch without a source-derived `$D7E8` boundary.")
	_pending_selected_task_boundary = next_boundary.duplicate(true)
	_pending_first_action_menu_handler_dispatch.clear()
	_hold_pass_confirmation_input_state = false
	_phase = "first_action_pass_handler_ready"
	return {"ok": true, "status": String(adoption.get("status", "")),
		"dispatch": dispatch.duplicate(true), "adoption": adoption.duplicate(true),
		"source_frame_transition": "next_source_tick",
		"next_boundary_snapshot": _pending_selected_task_boundary.duplicate(true),
		"handler_body_executed": false}


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
		"pass_receiver_wait_nmi_pending": _phase == "awaiting_external_nmi" \
			and _pass_receiver_packet_batch_progress.size() == 5 \
			and _pass_receiver_packet_batch_nmi_frames.size() == 5 \
			and int(_pending_nmi_queue_state.get("ready_flag_0515", -1)) == 0x80,
		"pass_receiver_descriptor_1d_final_nmi_pending": _phase == "awaiting_external_nmi" \
			and _pass_receiver_descriptor_1d_input_poll_pending,
		"pass_receiver_confirmation_input_pending": _pass_receiver_confirmation_input_pending,
		"nmi_cadence_generated": false,
		"source_boundary": _last_source_boundary,
		"verified_stamina_update_receipt": _verified_stamina_update_receipt.duplicate(true),
		"last_first_action_menu_dispatch_result": _last_first_action_menu_dispatch_result.duplicate(true),
		"last_first_action_menu_adoption_result": _last_first_action_menu_adoption_result.duplicate(true),
		"last_pass_receiver_input_result": _last_pass_receiver_input_result.duplicate(true),
		"last_pass_receiver_input_adoption": _last_pass_receiver_input_adoption.duplicate(true),
		"last_pass_receiver_descriptor_1d_batch": _last_pass_receiver_descriptor_1d_batch.duplicate(true),
		"last_first_action_confirmation_bridge_result": _last_first_action_confirmation_bridge_result.duplicate(true),
		"last_first_action_confirmation_bridge_adoption": _last_first_action_confirmation_bridge_adoption.duplicate(true),
		"last_first_action_confirmation_bridge_scans": _last_first_action_confirmation_bridge_scans.duplicate(true),
		"last_first_action_pass_label_result": _last_first_action_pass_label_result.duplicate(true),
		"last_first_action_pass_label_adoption": _last_first_action_pass_label_adoption.duplicate(true),
		"last_pass_no_candidates_continuation_result": _last_pass_no_candidates_continuation_result.duplicate(true),
		"last_pass_no_candidates_continuation_adoption": _last_pass_no_candidates_continuation_adoption.duplicate(true),
		"last_pass_handler_body_result": _last_pass_handler_body_result.duplicate(true),
		"last_pass_handler_body_adoption": _last_pass_handler_body_adoption.duplicate(true),
		"last_pass_handler_cb0f_save_result": _last_pass_handler_cb0f_save_result.duplicate(true),
		"last_pass_handler_cb0f_scans": _last_pass_handler_cb0f_scans.duplicate(true),
		"pending_first_action_menu_handler_dispatch": _pending_first_action_menu_handler_dispatch.duplicate(true),
		"initial_daaa_continuation_result": _initial_daaa_continuation_result.duplicate(true),
		"scenario36_event_boundary_result": _scenario36_event_boundary_result.duplicate(true),
		"scenario36_post_event_result": _scenario36_post_event_result.duplicate(true),
		"scenario36_slot15_seed_result": _scenario36_slot15_seed_result.duplicate(true),
		"last_root_actor_loop_result": _last_root_actor_loop_result.duplicate(true),
		"last_root_e3ca_result": _last_root_e3ca_result.duplicate(true),
		"last_slot09_resume_input_debug": _last_slot09_resume_input_debug.duplicate(true),
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


func _summarize_slot09_resume_input(result: Dictionary) -> Dictionary:
	var ram: Variant = result.get("ram_image", PackedByteArray())
	var stack: Variant = result.get("stack_page", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var sp := int(registers.get("sp", result.get("sp", -1)))
	var stack_window := PackedByteArray()
	if stack is PackedByteArray and stack.size() == 0x100 and sp >= 0:
		stack_window = stack.slice(maxi(0, sp - 8), mini(0x100, sp + 9))
	var valid_ram: bool = ram is PackedByteArray and ram.size() == RAM_SIZE
	return {
		"ok": bool(result.get("ok", false)),
		"status": String(result.get("status", "")),
		"reason": String(result.get("reason", result.get("error", ""))),
		"entry_pc": int(result.get("entry_pc", -1)),
		"exit_pc": int(result.get("exit_pc", -1)),
		"registers": registers.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_0079_007a": ram.slice(0x0079, 0x007B).hex_encode() if valid_ram else "invalid",
		"ram_003a": int(ram[0x003A]) if valid_ram else -1,
		"ram_0052_005f": ram.slice(0x0052, 0x0060).hex_encode() if valid_ram else "invalid",
		"ram_0516_0539": ram.slice(0x0516, 0x053A).hex_encode() if valid_ram else "invalid",
		"ram_05c7_05d2": ram.slice(0x05C7, 0x05D3).hex_encode() if valid_ram else "invalid",
		"ram_05fb": int(ram[0x05FB]) if valid_ram else -1,
		"ram_0635_0638": ram.slice(0x0635, 0x0638).hex_encode() if valid_ram else "invalid",
		"ram_0430_043b": ram.slice(0x0430, 0x043C).hex_encode() if valid_ram else "invalid",
		"ram_047c_047f": ram.slice(0x047C, 0x0480).hex_encode() if valid_ram else "invalid",
		"ram_0498_04a1": ram.slice(0x0498, 0x04A2).hex_encode() if valid_ram else "invalid",
		"ram_04a5_04db": ram.slice(0x04A5, 0x04DC).hex_encode() if valid_ram else "invalid",
		"ram_0543_0546": ram.slice(0x0543, 0x0547).hex_encode() if valid_ram else "invalid",
		"stack_sp": sp,
		"stack_window_start": maxi(0, sp - 8) if not stack_window.is_empty() else -1,
		"stack_window": stack_window.hex_encode(),
	}


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


func _attach_external_nmi_receipt(result: Dictionary, source_boundary_before_nmi: String,
		queue_guard_validated: bool) -> Dictionary:
	if not bool(result.get("ok", false)):
		return result
	result["external_nmi_consumed"] = true
	result["source_boundary_before_nmi"] = source_boundary_before_nmi
	result["pending_queue_guard_validated"] = queue_guard_validated
	result["nmi_cadence_generated"] = false
	result["normal_nmi_result"] = _last_nmi_result.duplicate(true)
	result["ppu_bus_events"] = _last_nmi_result.get("ppu_bus_events", []).duplicate(true)
	return result


func _fail(message: String) -> bool:
	error_message = message
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	_phase = "error"
	return {"ok": false, "phase": _phase, "error": error_message}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
