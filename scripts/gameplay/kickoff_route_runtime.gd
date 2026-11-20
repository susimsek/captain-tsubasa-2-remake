extends Node2D
class_name KickoffRouteRuntime
## ROM-derived fresh-start route from title KICK OFF to the first field menu.

signal route_stage_changed(stage: String)
signal cutscene_return_requested(cutscene_id: int, completion_kind: String)
signal first_action_menu_requested
signal action_selection_changed(action_id: int, direction_index: int)
signal action_confirmation_requested(action_id: int)
signal rom_sound_queue_write_requested(event: RefCounted)
signal title_handoff_fade_completed

const NES_FPS := 60.0988
const TITLE_HANDOFF_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const NES_A_EDGE := 0x80
const NES_B_HELD := 0x40
const NES_SELECT_HELD := 0x20
const NES_DIRECTION_BITS: Array[int] = [0x01, 0x02, 0x04, 0x08]
const NES_DIRECTION_KEYS: Array[int] = [KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP]
const NES_DIRECTION_JOY_BUTTONS: Array[int] = [JOY_BUTTON_DPAD_RIGHT,
	JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP]
const ACTION_LABEL_BLINK_TICKS := 13
const CUTSCENE_VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")
const MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const MEETING_MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/pre_match_meeting_menu_input.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const CUTSCENE_SELECT_WAIT_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_select_wait_task.gd")
const CUTSCENE_NATURAL_WAIT_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_natural_wait_task.gd")
const CUTSCENE_WORKER_SEED_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_cutscene_worker_seed.gd")
const CUTSCENE_CLEANUP_FADE_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_cleanup_fade_task.gd")
const CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_cleanup_clear_task.gd")
const CUTSCENE_FA0F_PRECLEAR_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_fa0f_preclear_task.gd")
const FRESH_KICKOFF_CALLER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_caller_continuation.gd")
const MAPPER_SHADOW_SOURCE_STATE_SCRIPT := preload("res://scripts/gameplay/rom_mapper_shadow_source_state.gd")
const FIXED_MAPPER_SELECT_HELPER_SCRIPT := preload("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd")
const FRESH_MATCH_SELECTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const FRESH_TITLE_STACK_CONTEXT_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_title_stack_context.gd")
const FRESH_MATCH_SELECTOR_CLOCK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_clock.gd")
const FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd")
const KICKOFF_RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const KICKOFF_RNG_SCHEDULE_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const KICKOFF_RNG_INPUT_ROUTE_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const FRESH_MATCH_NORMALIZER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_normalize_executor.gd")
const FRESH_MATCH_PRESET_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_preset_loader_prefix.gd")
const FRESH_MATCH_PRESET_WAIT_IRQ_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_preset_wait_irq_executor.gd")
const FRESH_MATCH_POSTWAIT_CALLER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_postwait_caller.gd")
const FRESH_MATCH_A4EB_PREFIX_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_a4eb_prefix_executor.gd")
const FRESH_MATCH_B0C0_STREAM_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_b0c0_stream_executor.gd")
const FRESH_MATCH_A503_ENTRY_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_a503_entry_executor.gd")
const FRESH_MATCH_A611_SETUP_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_a611_setup_executor.gd")
const FRESH_MATCH_STAMINA_INITIALIZER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_stamina_initializer.gd")
const FRESH_PREMATCH_A009_ENTRY_SCRIPT := preload("res://scripts/gameplay/rom_fresh_prematch_a009_entry.gd")
const FRESH_PREMATCH_A64C_SETUP_SCRIPT := preload("res://scripts/gameplay/rom_fresh_prematch_a64c_setup_executor.gd")
const FRESH_MATCH_PALETTE_RAMP_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_palette_ramp_task.gd")
const FRESH_MATCH_A503_INPUT_WAIT_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_a503_input_wait_task.gd")
const FRESH_MATCH_HANDOFF_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_handoff_executor.gd")
const FRESH_MATCH_CONTEXT_RESOLVER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_position_context_resolver.gd")
const FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const FRESH_PERIOD_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const FRESH_SOURCE_ROUTE_RUNNER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SOUND_QUEUE_EVENT_SCRIPT := preload("res://scripts/gameplay/rom_sound_queue_write_event.gd")
const SOURCE_RAM_IMAGE_SCRIPT := preload("res://scripts/gameplay/rom_source_ram_image.gd")
const GAMEPLAY_TASK_SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const NMI_MODE_PRODUCER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_nmi_mode_producer.gd")
const CUTSCENE_ATTRIBUTE_TAIL_SEED_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_dispatch_attribute_tail_seed.gd")
const E8_PRESET_MODEL_SCRIPT := preload("res://scripts/opening/rom_bg0a_raster_model.gd")
const CUTSCENE_BACKGROUND_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_background_source_task.gd")
const CUTSCENE_F1_DIALOG_TASK_SCRIPT := preload("res://scripts/gameplay/rom_f1_dialog_window_task.gd")
const CUTSCENE_CHR_SHADOW_PRODUCER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_chr_selector_shadow_producer.gd")
const CUTSCENE_ANIMATION_CHR_SHADOW_PRODUCER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_animation_chr_shadow_producer.gd")
const CUTSCENE_EB_POST_WAIT_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_eb_post_wait_source_task.gd")
const PREMATCH_MENU_RETURN_SCRIPT := preload("res://scripts/gameplay/rom_prematch_menu_return_executor.gd")

enum RouteStage {
	TITLE_HANDOFF_FADE,
	CUTSCENE_1,
	MATCHUP_PRESENTATION,
	MEETING_SCENE,
	MEETING_MENU,
	CUTSCENE_56,
	CUTSCENE_56_NATURAL_WAIT,
	CUTSCENE_2,
	CUTSCENE_CLEANUP_FADE,
	SOURCE_ROUTE_WAITING_FOR_NMI,
	SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE,
	SOURCE_ROUTE_GAP,
	PASS_RECEIVER_RENDERER_PENDING,
	FIELD_RUNNING, # Retained for isolated field-loop/provider verification only.
	FIRST_ACTION_MENU_PENDING,
	MATCH_SELECTOR_RUNNING,
	MATCH_SETUP_GAP,
	MATCH_SETUP_A503_TEXT_SETUP,
	MATCH_SETUP_A503_PALETTE_RAMP,
	MATCH_SETUP_A503_INPUT_WAIT,
	MATCH_SETUP_A503_POSTWAIT_FADE,
	MATCH_SETUP_A503_LEVEL_UPDATE,
	MATCH_SETUP_811F_PENDING,
	MATCH_SETUP_8122_PENDING,
	MATCH_SETUP_812F_PENDING,
	MATCH_SETUP_A64C_PENDING,
	FIRST_ACTION_MENU,
	FIRST_ACTION_HANDLER_PENDING,
}

@onready var vm: KickoffCutsceneCommandVm = $CutsceneVm
@onready var cue_audio: GameplayRomCueAudioPresenter = $CueAudio

var route_stage := RouteStage.CUTSCENE_1
var source_frame := 4693
var scheduler_tick := 0
var route_gaps: Array[String] = [
	"Cutscene VM uses verified script bytes and cooperative ticks, but not the full ROM worker/CPU/PPU phase.",
	"Cutscene palette, raster, and some animation-command effects remain unresolved.",
	"The fresh-match RNG state and kickoff-to-field input/update path are not yet produced by the live route.",
	"The ROM-executed selector checkpoint carries the source-derived caller stack; the frame-8 NMI and one candidate-edge wait IRQ run through their source returns, while fourteen earlier NMI/IRQ effects and physical subframe timing remain unresolved.",
	"First-match full field map, raster/scroll schedule, and actor OAM producers are unresolved; the current field is a ROM-backed candidate.",
	"Fresh match-00 stamina initialization is source-derived, but in-field player state still lacks a generic input/RNG producer and source-confirmed $E14D field-loop events.",
	"The single-slot task-context model is diagnostic-only; it does not produce the live $8327 callback/task event or previous $05CD needed by the field packet renderer.",
	"The source runner executes the `$EE9F`/`$E3CA` branches, slot-$05 `$C515` text callbacks and first two menu-window packets, then slot-$09 zero branches through `$EB88->$CB0F`. The production route executes the first `$BCFF` descriptor, the `$BD7C/$BDF2/$BE09` ROM text streams, the `$997A` palette ramp, the live `$A571` A-edge/timeout loop, `$99F0/$98A0`, the fresh zero-level `$A611` pass, `$C572->$DB62` energy initialization, the `$8122-$812F` branch-selected `$0700` music store, `$812F-$8142` RAM clears, `$813F->$C4B9` mapper selection, and `$A009->$A64C`. The live `$A64C` path now applies its `$98A0/$9B7F` clears and starts ROM scene `$44`; post-scene `$A662` cursor/input setup is still represented by the existing Godot menu presenter rather than executed as 6502. Complete CHR/sprite-palette presentation and field handoff remain unresolved.",
	"The live route advances only source-supported scheduler branches; complete first-match field PPU state, visible field/menu output, and same-input audio/timing remain unresolved.",
	"The 13-handler-iteration action-label blink is modeled on the route tick, but handler-to-video cadence and same-input selected-label pixels are not verified.",
	"Route cue assets are ROM-derived; cue onset, loop phase, SFX mix, and same-input PCM remain unverified.",
]

var _visuals: KickoffCutsceneVisuals
var _cutscene_background_task: Variant
var _cutscene_fa0f_preclear_task: Variant
var _cutscene_fa0f_preclear_task_result: Dictionary = {}
var _cutscene_fa0f_preclear_history: Array[Dictionary] = []
var _cutscene_fa0f_final_row_batch: Dictionary = {}
var _cutscene_fa0f_helper_selection: Dictionary = {}
var _scene56_natural_wait_task: Variant
var _cutscene_background_task_result: Dictionary = {}
var _cutscene_background_batch_history: Array[Dictionary] = []
var _cutscene_external_task_return_pending: Dictionary = {}
var _cutscene_external_task_return_history: Array[Dictionary] = []
var _cutscene_f1_dialog_task: Variant
var _cutscene_f1_dialog_task_result: Dictionary = {}
var _cutscene_f1_dialog_release_history: Array[Dictionary] = []
var _cutscene_fade_counter_history: Array[Dictionary] = []
var _cutscene_f3_palette_queue_history: Array[Dictionary] = []
var _cutscene_chr_selector_pair_receipts: Dictionary = {}
var _cutscene_chr_shadow_history: Array[Dictionary] = []
var _cutscene_chr_pair_read_pending: Dictionary = {}
var _cutscene_animation_chr_shadow_history: Array[Dictionary] = []
var _cutscene_eb_post_wait_task: Variant
var _cutscene_eb_post_wait_task_result: Dictionary = {}
var _cutscene_eb_post_wait_batch_history: Array[Dictionary] = []
var _menu_input: FirstActionMenuInput
var _meeting_menu_input: Node
var _first_action_menu_source_input_sample: Dictionary = {}
var _first_action_menu_dispatch_entry_reached := false
var _cutscene_select_wait_task: Variant
var _cutscene_cleanup_fade_task: Variant
var _cutscene_cleanup_clear_result: Dictionary = {}
var _cutscene_cleanup_ram_writes: Dictionary = {}
var _cutscene_post_helper_ram_writes: Dictionary = {}
var _source_ram_image: RomSourceRamImage
var _source_ppu_shadow_state: Dictionary = {}
var _nmi_mode_boot_receipt: Dictionary = {}
var _nmi_mode_route_receipt: Dictionary = {}
var _source_e8_preset_status: Array[Dictionary] = []
var _cutscene_cleanup_fade_counters := Vector2i.ZERO
var _cutscene_cleanup_fade_pending_palette_packet := PackedByteArray()
var _cutscene_cleanup_fade_pending_source_frame := -1
var _cutscene_cleanup_fade_packet_history: Array[Dictionary] = []
var _cutscene_wait_cleanup_result: Dictionary = {}
var _match_player_state_provider: RomFreshKickoffMatchStateProvider
var _frame_accumulator := 0.0
var _pending_a_edge := false
var _pending_select_edge := false
var _pending_b_edge := false
var _held_kickoff_input_bits := 0
var _previous_source_controller_bits := 0
var _deferred_pass_receiver_controller_sample: Dictionary = {}
var _action_label_blink_ticks_remaining := 0
var _action_label_blink_visible := false
var _fresh_match_context: Dictionary = {}
var _fresh_scheduler_dispatch: Dictionary = {}
var _fresh_period_task_status: Dictionary = {}
var _fresh_entry_context: Variant
var _fresh_source_route_runner: Variant
var _fresh_source_route_begin_result: Dictionary = {}
var _fresh_source_route_nmi_result: Dictionary = {}
var _fresh_source_route_task_result: Dictionary = {}
var _fresh_source_route_nmi_abstraction_count := 0
var _fresh_source_route_nmi_timing_note := ""
var _fresh_match_selector_clock: Variant
var _fresh_match_selector_context: Dictionary = {}
var _fresh_match_selector_entry_frame := -1
var _fresh_match_selector_progress: Dictionary = {}
var _fresh_match_selector_materialized_ram: Dictionary = {}
var _fresh_match_selector_scheduled_interrupts: Array[Dictionary] = []
var _fresh_match_selector_nmi_checkpoint: Dictionary = {}
var _fresh_match_preset_prefix_result: Dictionary = {}
var _fresh_match_wait_irq_result: Dictionary = {}
var _fresh_match_preset_tail_result: Dictionary = {}
var _fresh_match_postwait_caller_result: Dictionary = {}
var _fresh_match_a4eb_prefix_result: Dictionary = {}
var _fresh_match_a503_entry_result: Dictionary = {}
var _fresh_match_a503_text_setup_result: Dictionary = {}
var _fresh_match_a503_palette_ramp_task: Variant
var _fresh_match_a503_palette_ramp_result: Dictionary = {}
var _fresh_match_a503_input_wait_task: Variant
var _fresh_match_a503_input_wait_result: Dictionary = {}
var _fresh_match_a503_input_wait_initial_yield_pending := false
var _fresh_match_a503_postwait_fade_result: Dictionary = {}
var _fresh_match_a503_postwait_fade_pending_packet := PackedByteArray()
var _fresh_match_a503_postwait_fade_pending_source_frame := -1
var _fresh_match_a503_postwait_fade_history: Array[Dictionary] = []
var _fresh_match_a503_a611_handoff: Dictionary = {}
var _fresh_match_stamina_result: Dictionary = {}
var _fresh_match_music_store_result: Dictionary = {}
var _fresh_match_caller_tail_result: Dictionary = {}
var _fresh_match_a64c_setup_result: Dictionary = {}
var _fresh_match_handoff_result: Dictionary = {}
var _fresh_match_a503_controller_sample: Dictionary = {}
var _initial_player_positions: Array[Dictionary] = []
var _sound_queue_event_history: Array[Dictionary] = []
var _title_handoff_receipt: Dictionary = {}
var _title_handoff_fade_receipt: Dictionary = {}
var _title_irq_chr_selector_receipt: Dictionary = {}
var _title_handoff_fade_task: Variant
var _title_handoff_clear_result: Dictionary = {}
var _title_handoff_dispatch_seed_result: Dictionary = {}
var _title_source_renderer: Node
var _title_fade_counters := Vector2i.ZERO
var _title_fade_base_palette := PackedByteArray()
var _title_handoff_pending_palette_packet := PackedByteArray()
var _title_handoff_pending_palette_source_frame := -1
var _cutscene_worker_seed_receipt: Dictionary = {}
var _last_cutscene_completion_kind := "none"
var _last_completed_cutscene_id := 0
var _prematch_menu_return_result: Dictionary = {}


func _ready() -> void:
	_source_ram_image = SOURCE_RAM_IMAGE_SCRIPT.new() as RomSourceRamImage
	_seed_reset_wait_and_controller_latches()
	_seed_bootstrap_ppu_shadows()
	_seed_irq_chr_restore_selectors()
	_initialize_cold_start_nmi_mode()
	_visuals = VISUALS_SCENE.instantiate() as KickoffCutsceneVisuals
	_visuals.name = "CutsceneVisuals"
	_visuals.set_source_background_tasks_managed(true)
	add_child(_visuals)
	_visuals.bind_vm(vm)
	vm.presenter_event.connect(_on_presenter_event)
	vm.screen_fade_palette_step_requested.connect(_record_cutscene_fade_counter_step)
	vm.done.connect(_on_cutscene_done)
	vm.vm_error.connect(_on_vm_error)
	rom_sound_queue_write_requested.connect(_on_rom_sound_queue_write_requested)
	_install_route_input_actions()
	if is_instance_valid(_title_source_renderer):
		_begin_title_handoff_fade()
	else:
		_start_cutscene(1)


func _seed_reset_wait_and_controller_latches() -> void:
	var reset_source: Variant = FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT.new()
	if not bool(reset_source.configure_from_project_sources()):
		_route_gaps_add("ROM reset source could not establish the E8 wait-byte baseline: %s" % String(reset_source.error_message))
		return
	var reset_addresses: Array[int] = [0x0078, 0x001C, 0x001D, 0x004A, 0x004B,
		0x0026, 0x0034, 0x0035, 0x00E4, 0x00E6, 0x00E7, 0x00EB, 0x00EC, 0x00ED,
		0x044D,
		0x0454, 0x0455]
	for player_slot in range(11):
		reset_addresses.append(0x0303 + player_slot * 0x0C)
		reset_addresses.append(0x0656 + player_slot)
	var reset_receipt: Dictionary = reset_source.build_reset_ram_zero_write_receipt(
		"kickoff_reset_ram_clear_wait_and_controller_latches", reset_addresses)
	if not bool(reset_receipt.get("ok", false)):
		_route_gaps_add("ROM reset zero-fill receipt failed: %s" % String(reset_receipt.get("error", "unknown source error")))
		return
	if not _source_ram_image.merge_executor_result(
			"kickoff_reset_ram_clear_wait_and_controller_latches", reset_receipt):
		_route_gaps_add("ROM reset zero-fill receipt was rejected: %s" % _source_ram_image.error_message)
		return
	var nmi_executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
	if not nmi_executor.configure_from_project_sources():
		_route_gaps_add("ROM controller-latch source failed validation: %s" % nmi_executor.error_message)
		return
	var controller_invariant: Dictionary = nmi_executor.derive_controller_latch_zero_invariant(
		reset_receipt)
	if not bool(controller_invariant.get("ok", false)):
		_route_gaps_add("ROM controller-latch invariant failed: %s" % String(
			controller_invariant.get("error", "unknown source error")))
		return
	if not _source_ram_image.merge_known_bits_receipt(
			"kickoff_controller_latch_zero_invariant", controller_invariant):
		_route_gaps_add("ROM controller-latch invariant could not join the source RAM ledger: %s" % _source_ram_image.error_message)


func _seed_bootstrap_ppu_shadows() -> void:
	var scheduler: Variant = GAMEPLAY_TASK_SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources():
		_route_gaps_add("ROM gameplay bootstrap source could not establish PPU register shadows: %s" % String(scheduler.error_message))
		return
	var bootstrap: Dictionary = scheduler.initialize_fresh_game_bootstrap()
	var writes: Variant = bootstrap.get("ppu_shadow_ram_writes", [])
	if not bool(bootstrap.get("ok", false)) or not writes is Array or writes.size() != 4:
		_route_gaps_add("ROM gameplay bootstrap did not produce its checked PPU shadow writes.")
		return
	var ctrl := -1
	var mask := -1
	for write_variant in writes:
		if not write_variant is Dictionary:
			_route_gaps_add("ROM gameplay bootstrap PPU shadow receipt contains a malformed write.")
			return
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x0020:
			ctrl = int(write.get("value", -1))
		elif int(write.get("address", -1)) == 0x0021:
			mask = int(write.get("value", -1))
	if ctrl != 0x88 or mask != 0x1E:
		_route_gaps_add("ROM gameplay bootstrap PPU shadow values do not match the checked $C6E8-$C765 source path.")
		return
	var bootstrap_ram_receipt := bootstrap.duplicate(true)
	bootstrap_ram_receipt["ram_writes"] = writes.duplicate(true)
	if not _source_ram_image.merge_executor_result(
			"kickoff_gameplay_bootstrap_ppu_shadows", bootstrap_ram_receipt):
		_route_gaps_add("ROM gameplay bootstrap PPU RAM writes could not join the source ledger: %s" % _source_ram_image.error_message)
		return
	_source_ppu_shadow_state = {"ok": true, "ctrl_shadow": ctrl,
		"mask_shadow": mask, "source_event_id": "rom_gameplay_bootstrap_ppu_shadows",
		"source_rom_sha256": String(bootstrap.get("rom_sha256", "")),
		"source_writes": writes.duplicate(true), "trace_state_used": false,
		"emulator_data_used": false}


func _seed_irq_chr_restore_selectors() -> void:
	if not bool(_title_irq_chr_selector_receipt.get("ok", false)):
		_route_gaps_add("ROM `$807F-$8086` IRQ CHR selector initialization is unavailable.")
		return
	var event_id := String(_title_irq_chr_selector_receipt.get("source_event_id", ""))
	if event_id.is_empty() or not _source_ram_image.merge_executor_result(
			event_id, _title_irq_chr_selector_receipt):
		_route_gaps_add("ROM IRQ CHR selector initialization could not join the source RAM ledger: %s" % _source_ram_image.error_message)


func _get_source_ppu_shadow_input() -> Dictionary:
	if not bool(_source_ppu_shadow_state.get("ok", false)):
		return {}
	var ppu_state: Dictionary = _visuals.get_source_ppu_state()
	return {"ok": true,
		"ctrl_shadow": int(_source_ppu_shadow_state.get("ctrl_shadow", -1)),
		"mask_shadow": int(_source_ppu_shadow_state.get("mask_shadow", -1)),
		"ppu_address": int(ppu_state.get("ppu_address", -1)),
		"shared_write_toggle": bool(ppu_state.get("shared_write_toggle", false)),
		"scroll_x": int(ppu_state.get("scroll_x", -1)),
		"scroll_y": int(ppu_state.get("scroll_y", -1))}


func _accept_cleanup_ppu_shadow_result(event_id: String, cleanup_result: Dictionary) -> bool:
	var after: Dictionary = cleanup_result.get("ppu_shadow_after", {})
	if after.is_empty() or String(cleanup_result.get("rom_sha256", "")) != TITLE_HANDOFF_ROM_SHA256:
		return false
	_source_ppu_shadow_state = {"ok": true,
		"ctrl_shadow": int(after.get("ctrl_shadow", -1)),
		"mask_shadow": int(after.get("mask_shadow", -1)),
		"source_event_id": event_id,
		"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"source_writes": cleanup_result.get("ram_writes", []).filter(
			func(write: Dictionary) -> bool:
				return int(write.get("address", -1)) in [0x0020, 0x0021]),
		"trace_state_used": false, "emulator_data_used": false}
	return int(_source_ppu_shadow_state["ctrl_shadow"]) in range(0x100) \
		and int(_source_ppu_shadow_state["mask_shadow"]) in range(0x100)


func _cleanup_ram_result_for_source_ledger(cleanup_result: Dictionary) -> Dictionary:
	var ledger_result := cleanup_result.duplicate(true)
	var source_writes: Variant = cleanup_result.get("ram_writes", [])
	if not source_writes is Array:
		return {}
	var ledger_writes: Array[Dictionary] = []
	for write_variant in source_writes:
		if not write_variant is Dictionary:
			return {}
		ledger_writes.append(write_variant.duplicate(true))
	ledger_result["ram_writes"] = ledger_writes
	return ledger_result


## Records the checked ROM cold-start setter as prior source provenance. It is
## kept separate from the live wait RAM image because intervening route writes
## are not yet fully executed by the production route.
func _initialize_cold_start_nmi_mode() -> void:
	var producer: Variant = NMI_MODE_PRODUCER_SCRIPT.new()
	if not producer.configure_from_project_sources():
		_route_gaps_add("ROM cold-start NMI mode source is unavailable: %s" % String(producer.error_message))
		return
	var reset_source: Variant = FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT.new()
	if not reset_source.configure_from_project_sources():
		_route_gaps_add("ROM reset source for NMI mode is unavailable: %s" % String(reset_source.error_message))
		return
	var mode_reset_addresses: Array[int] = [0x001B]
	var reset_receipt: Dictionary = reset_source.build_reset_ram_zero_write_receipt(
		"kickoff_cold_start_reset_001b", mode_reset_addresses)
	if not bool(reset_receipt.get("ok", false)):
		_route_gaps_add("ROM reset receipt for `$001B` failed: %s" % String(reset_receipt.get("error", "unknown source error")))
		return
	_nmi_mode_boot_receipt = producer.build_cold_start_mode_receipt(reset_receipt)
	if not bool(_nmi_mode_boot_receipt.get("ok", false)):
		_route_gaps_add("ROM cold-start NMI mode setter failed: %s" % String(_nmi_mode_boot_receipt.get("error", producer.error_message)))
		return
	_nmi_mode_route_receipt = producer.build_route_mode_bit_receipt(_nmi_mode_boot_receipt)
	if not bool(_nmi_mode_route_receipt.get("ok", false)):
		_route_gaps_add("ROM NMI mode-bit preservation proof failed: %s" % String(_nmi_mode_route_receipt.get("error", producer.error_message)))
		return
	if not _source_ram_image.merge_known_bits_receipt(
			"kickoff_nmi_mode_bit6_preservation", _nmi_mode_route_receipt):
		_route_gaps_add("ROM NMI mode-bit receipt was rejected: %s" % _source_ram_image.error_message)
		return


func _process(delta: float) -> void:
	_frame_accumulator += delta * NES_FPS
	while _frame_accumulator >= 1.0:
		_frame_accumulator -= 1.0
		_advance_route_source_tick()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	# Controller state is continuous even while the source task is awaiting an
	# NMI. Preserve D-pad edges so a poll restored by that NMI can read them in
	# the same source frame.
	for direction_index in NES_DIRECTION_BITS.size():
		var direction_pressed := event is InputEventKey \
			and (event as InputEventKey).keycode == NES_DIRECTION_KEYS[direction_index]
		var direction_button_pressed := event is InputEventJoypadButton \
			and (event as InputEventJoypadButton).button_index == NES_DIRECTION_JOY_BUTTONS[direction_index]
		if (direction_pressed or direction_button_pressed) \
				and event.is_pressed():
			_held_kickoff_input_bits |= NES_DIRECTION_BITS[direction_index]
		elif (direction_pressed or direction_button_pressed) and not event.is_pressed():
			_held_kickoff_input_bits &= 0xFF ^ NES_DIRECTION_BITS[direction_index]
	if _is_source_route_waiting():
		if event.is_action_pressed("route_advance"):
			_held_kickoff_input_bits |= NES_A_EDGE
		elif event.is_action_released("route_advance"):
			_held_kickoff_input_bits &= 0xFF ^ NES_A_EDGE
		elif event.is_action_pressed("route_b"):
			_held_kickoff_input_bits |= NES_B_HELD
		elif event.is_action_released("route_b"):
			_held_kickoff_input_bits &= 0xFF ^ NES_B_HELD
		elif event.is_action_pressed("route_select"):
			_held_kickoff_input_bits |= NES_SELECT_HELD
		elif event.is_action_released("route_select"):
			_held_kickoff_input_bits &= 0xFF ^ NES_SELECT_HELD
		for action_name: String in ["route_advance", "route_b", "route_select"]:
			if event.is_action_pressed(action_name) or event.is_action_released(action_name):
				get_viewport().set_input_as_handled()
				return
		return
	if route_stage == RouteStage.SOURCE_ROUTE_GAP:
		for action_name: String in ["route_advance", "route_b", "route_select"]:
			if event.is_action_pressed(action_name) or event.is_action_released(action_name):
				get_viewport().set_input_as_handled()
				return
		return
	if event.is_action_pressed("route_advance"):
		_held_kickoff_input_bits |= NES_A_EDGE
	elif event.is_action_released("route_advance"):
		_held_kickoff_input_bits &= 0xFF ^ NES_A_EDGE
		return
	if event.is_action_pressed("route_b"):
		_held_kickoff_input_bits |= NES_B_HELD
	elif event.is_action_released("route_b"):
		_held_kickoff_input_bits &= 0xFF ^ NES_B_HELD
		return
	if event.is_action_pressed("route_select"):
		_held_kickoff_input_bits |= NES_SELECT_HELD
		if _is_cutscene_stage():
			if vm.cutscene_id in [1, 2] and _cutscene_select_wait_task != null \
					and _cutscene_select_wait_task.is_waiting():
				_pending_select_edge = true
			get_viewport().set_input_as_handled()
			return
	elif event.is_action_released("route_select"):
		_held_kickoff_input_bits &= 0xFF ^ NES_SELECT_HELD
		if _is_cutscene_stage():
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("route_advance"):
		if _is_cutscene_stage():
			_pending_a_edge = true
		elif route_stage == RouteStage.MATCHUP_PRESENTATION:
			_begin_pre_match_meeting_scene()
			get_viewport().set_input_as_handled()
		else:
			return
		get_viewport().set_input_as_handled()


func install_first_action_menu(player_state: FirstActionMenuMatchPlayerState,
		actor_source_context: Dictionary = {},
		descriptor_01_source_context: Dictionary = {}) -> bool:
	if route_stage != RouteStage.FIRST_ACTION_MENU_PENDING and route_stage != RouteStage.MATCH_SETUP_GAP:
		return false
	if not _visuals.present_first_action_menu(player_state, actor_source_context,
			descriptor_01_source_context):
		return false
	if not _visuals.action_menu_complete:
		var missing_row_names := PackedStringArray()
		for missing_row: Variant in _visuals.action_menu_missing_dynamic:
			missing_row_names.append(str(missing_row))
		_route_gaps_add("First-action menu was drawn with unresolved ROM-derived dynamic rows (%s); keep the route pending." % ", ".join(missing_row_names))
		return false
	_menu_input = MENU_INPUT_SCRIPT.new() as FirstActionMenuInput
	_menu_input.name = "FirstActionMenuInput"
	add_child(_menu_input)
	_menu_input.set_process(false)
	_menu_input.selection_changed.connect(_on_action_selection_changed)
	_menu_input.action_confirmed.connect(_on_action_confirmation_requested)
	_menu_input.reset_selection()
	_action_label_blink_ticks_remaining = 0
	_action_label_blink_visible = false
	_visuals.set_first_action_menu_selection(FirstActionMenuInput.ActionId.NONE, false)
	route_stage = RouteStage.FIRST_ACTION_MENU
	route_stage_changed.emit("first_action_menu")
	return true


## Binds a caller-owned ROM-derived source model. The route deliberately does
## not construct the fixed-input RNG replay itself: callers must bind an
## already validated provider and report only source-confirmed field-loop
## iterations. Emulator snapshots are not accepted here.
func bind_match_player_state_provider(provider: RomFreshKickoffMatchStateProvider) -> bool:
	if provider == null:
		return false
	var provider_status: Dictionary = provider.get_source_status()
	if not bool(provider_status.get("configured", false)):
		return false
	_match_player_state_provider = provider
	return true


## Carries the live title presenter boundary into the KICK OFF route. The
## route begins on the next source frame after the confirmed title choice.
func initialize_from_title_handoff(title_source_frame: int, source_rom_sha256: String,
		source_fade: Dictionary = {}, title_renderer: Node = null) -> bool:
	if is_inside_tree() or title_source_frame < 0 \
			or source_rom_sha256 != TITLE_HANDOFF_ROM_SHA256:
		return false
	if title_renderer != null:
		var counters_value: Variant = source_fade.get("fade_counters", Vector2i(-1, -1))
		var palette_value: Variant = source_fade.get("base_palette_bytes", PackedByteArray())
		if typeof(counters_value) != TYPE_VECTOR2I \
				or typeof(palette_value) != TYPE_PACKED_BYTE_ARRAY \
				or not title_renderer.has_method("set_rom_fade_palette_bytes") \
				or not title_renderer.has_method("get_source_title_palette_bytes") \
				or not title_renderer.has_method("apply_rom_cutscene_cleanup_clear"):
			return false
		var counters: Vector2i = counters_value
		var palette: PackedByteArray = palette_value
		if counters.x < 0 or counters.x > 0x0F or counters.y < 0 or counters.y > 0x0F \
				or palette.size() != 0x20 or palette != title_renderer.call("get_source_title_palette_bytes"):
			return false
		_title_fade_counters = counters
		_title_fade_base_palette = palette.duplicate()
		_title_source_renderer = title_renderer
		route_stage = RouteStage.TITLE_HANDOFF_FADE
		_title_handoff_fade_receipt = {
			"ok": true,
			"source_pc": "$9BA0->$99F0->$9A71->$9FA8",
			"counter_origin": "live ROM-derived opening presenter state at the title Start poll",
			"initial_counters": counters,
			"palette_sha256": _sha256_hex(palette),
			"palette_origin": "ROM-derived title $17 background palette plus animation-$0D sprite palette",
			"uses_trace_values": false,
			"uses_emulator_images_or_audio": false,
			"source_tick_rate": "one $99F0 resume per source frame; CPU/NMI phase remains unmodeled",
		}
	var irq_selector_source: Variant = FRESH_MATCH_PRESET_PREFIX_SCRIPT.new()
	if not irq_selector_source.configure_from_project_sources():
		return false
	_title_irq_chr_selector_receipt = irq_selector_source.execute_irq_chr_selector_initializer(
		source_fade.get("ram_0090_0091", null))
	if not bool(_title_irq_chr_selector_receipt.get("ok", false)):
		return false
	source_frame = title_source_frame + 1
	_title_handoff_receipt = {
		"ok": true,
		"kind": "live_rom_title_kickoff_handoff",
		"source_rom_sha256": source_rom_sha256,
		"title_source_frame": title_source_frame,
		"route_entry_source_frame": source_frame,
		"selected_option": "KICK OFF",
		"input_origin": "RomTitleMenu kickoff_requested signal",
		"trace_state_used": false,
		"emulator_data_used": false,
		"initial_fade": _title_handoff_fade_receipt.duplicate(true),
	}
	return true


## Installs the first command menu from the bound ROM-derived player state.
## The caller still owns the input-hash/RNG proof and eligible timer events.
func install_first_action_menu_from_provider() -> bool:
	if _match_player_state_provider == null:
		return false
	var player_state := _match_player_state_provider.get_controlled_player_state()
	if player_state == null:
		return false
	var actor_source_context: Dictionary = {}
	var descriptor_01_source_context: Dictionary = {}
	if _fresh_source_route_runner != null \
			and _fresh_source_route_runner.has_method("create_first_command_actor_source_context"):
		actor_source_context = _fresh_source_route_runner.create_first_command_actor_source_context()
	if _fresh_source_route_runner != null \
			and _fresh_source_route_runner.has_method("create_descriptor_01_source_context"):
		descriptor_01_source_context = _fresh_source_route_runner.create_descriptor_01_source_context()
	return install_first_action_menu(player_state, actor_source_context,
		descriptor_01_source_context)


## Reports a source-confirmed field-loop iteration to the isolated player-state
## provider. The live route does not enter FIELD_RUNNING before `$EE9F` resolves.
func report_eligible_field_loop_iteration() -> bool:
	if route_stage != RouteStage.FIELD_RUNNING or _match_player_state_provider == null:
		return false
	return _match_player_state_provider.advance_field_loop_iteration()


func get_route_status() -> Dictionary:
	return {
		"stage": _stage_name(),
		"source_frame": source_frame,
		"title_handoff": _title_handoff_receipt.duplicate(true),
		"title_handoff_fade": _title_handoff_fade_task.get_status() if _title_handoff_fade_task != null else {},
		"title_handoff_fade_receipt": _title_handoff_fade_receipt.duplicate(true),
		"irq_chr_selector_init_receipt": _title_irq_chr_selector_receipt.duplicate(true),
		"title_handoff_clear": _title_handoff_clear_result.duplicate(true),
		"title_handoff_dispatch_seed": _title_handoff_dispatch_seed_result.duplicate(true),
		"cutscene_worker_seed": _cutscene_worker_seed_receipt.duplicate(true),
		"scheduler_tick": scheduler_tick,
		"cutscene_id": vm.cutscene_id,
		"last_completed_cutscene_id": _last_completed_cutscene_id,
		"prematch_menu_return": _prematch_menu_return_result.duplicate(true),
		"last_cutscene_completion_kind": _last_cutscene_completion_kind,
		"cutscene_select_wait": _cutscene_select_wait_task.get_status() if _cutscene_select_wait_task != null else {},
		"cutscene_wait_cleanup": _cutscene_wait_cleanup_result.duplicate(true),
		"cutscene_cleanup_fade": _cutscene_cleanup_fade_task.get_status() if _cutscene_cleanup_fade_task != null else {},
		"cutscene_cleanup_fade_pending_packet": _cutscene_cleanup_fade_pending_palette_packet.duplicate(),
		"cutscene_cleanup_fade_packet_history": _cutscene_cleanup_fade_packet_history.duplicate(true),
		"cutscene_cleanup_clear": _cutscene_cleanup_clear_result.duplicate(true),
		"cutscene_cleanup_ram_writes": _cutscene_cleanup_ram_writes.duplicate(true),
		"cutscene_background_task": _cutscene_background_task.get_status() \
			if _cutscene_background_task != null else _cutscene_background_task_result.duplicate(true),
		"cutscene_fa0f_preclear_task": _cutscene_fa0f_preclear_task.get_status() \
			if _cutscene_fa0f_preclear_task != null else _cutscene_fa0f_preclear_task_result.duplicate(true),
		"cutscene_fa0f_preclear_history": _cutscene_fa0f_preclear_history.duplicate(true),
		"cutscene_fa0f_helper_selection": _cutscene_fa0f_helper_selection.duplicate(true),
		"cutscene_background_batch_history": _cutscene_background_batch_history.duplicate(true),
		"cutscene_external_task_return_pending": _cutscene_external_task_return_pending.duplicate(true),
		"cutscene_external_task_return_history": _cutscene_external_task_return_history.duplicate(true),
		"cutscene_f1_dialog_task": _cutscene_f1_dialog_task.get_status() \
			if _cutscene_f1_dialog_task != null else _cutscene_f1_dialog_task_result.duplicate(true),
		"cutscene_f1_dialog_release_history": _cutscene_f1_dialog_release_history.duplicate(true),
		"cutscene_fade_counter_history": _cutscene_fade_counter_history.duplicate(true),
		"cutscene_f3_palette_queue_history": _cutscene_f3_palette_queue_history.duplicate(true),
		"cutscene_chr_shadow_history": _cutscene_chr_shadow_history.duplicate(true),
		"cutscene_chr_pair_read_pending": _cutscene_chr_pair_read_pending.duplicate(true),
		"cutscene_animation_chr_shadow_history": _cutscene_animation_chr_shadow_history.duplicate(true),
		"cutscene_eb_post_wait_task": _cutscene_eb_post_wait_task.get_status() \
			if _cutscene_eb_post_wait_task != null else _cutscene_eb_post_wait_task_result.duplicate(true),
		"cutscene_eb_post_wait_batch_history": _cutscene_eb_post_wait_batch_history.duplicate(true),
		"cutscene_post_helper_ram_writes": _cutscene_post_helper_ram_writes.duplicate(true),
		"source_ram_image_at_893b": _source_ram_image.get_status() if _source_ram_image != null else {},
		"source_ppu_shadow_state": _source_ppu_shadow_state.duplicate(true),
		"cold_start_nmi_mode_receipt": _nmi_mode_boot_receipt.duplicate(true),
		"nmi_mode_route_bit_receipt": _nmi_mode_route_receipt.duplicate(true),
		"source_e8_preset_events": _source_e8_preset_status.duplicate(true),
		"vm_state": vm.state,
		"active_background_id": _visuals.active_background_id if is_instance_valid(_visuals) else -1,
		"source_ppu_queue_cursor_0628": _visuals.get_eb_post_wait_clear_source_inputs().get("source_queue_cursor_0628", -1) \
			if is_instance_valid(_visuals) else -1,
		"first_action_menu_complete": _visuals.action_menu_complete if is_instance_valid(_visuals) else false,
		"first_action_menu_source_pending": route_stage == RouteStage.FIRST_ACTION_MENU_PENDING,
		"menu_missing_dynamic": _visuals.action_menu_missing_dynamic.duplicate(true) if is_instance_valid(_visuals) else [],
		"pass_receiver_menu": _visuals.pass_receiver_menu_status.duplicate(true) if is_instance_valid(_visuals) else {},
		"selected_action_id": _menu_input.selected_action_id if is_instance_valid(_menu_input) else FirstActionMenuInput.ActionId.NONE,
		"first_action_menu_source_input_sample": _first_action_menu_source_input_sample.duplicate(true),
		"held_kickoff_input_bits": _held_kickoff_input_bits,
		"meeting_cursor_y": int(_meeting_menu_input.get("cursor_y")) if is_instance_valid(_meeting_menu_input) else -1,
		"action_label_blink_visible": _action_label_blink_visible,
		"presentation_gaps": _visuals.presentation_gaps.duplicate() if is_instance_valid(_visuals) else [],
		"fresh_match_context": _fresh_match_context.duplicate(true),
		"fresh_entry_context": _fresh_entry_context.to_dictionary() if _fresh_entry_context != null else {},
		"fresh_source_route": _fresh_source_route_runner.get_status() if _fresh_source_route_runner != null else {},
		"fresh_source_route_begin": _fresh_source_route_begin_result.duplicate(true),
		"fresh_source_route_nmi": _fresh_source_route_nmi_result.duplicate(true),
		"fresh_source_route_task": _fresh_source_route_task_result.duplicate(true),
		"fresh_source_route_nmi_abstraction_count": _fresh_source_route_nmi_abstraction_count,
		"fresh_source_route_nmi_timing_note": _fresh_source_route_nmi_timing_note,
		"fresh_source_route_waiting_for_task_source": route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE,
		"fresh_match_selector_clock": _get_fresh_match_selector_clock_status(),
		"fresh_match_selector_nmi_checkpoint": _fresh_match_selector_nmi_checkpoint.duplicate(true),
		"fresh_match_preset_prefix": _fresh_match_preset_prefix_result.duplicate(true),
		"fresh_match_wait_irq": _fresh_match_wait_irq_result.duplicate(true),
		"fresh_match_preset_tail": _fresh_match_preset_tail_result.duplicate(true),
		"fresh_match_postwait_caller": _fresh_match_postwait_caller_result.duplicate(true),
		"fresh_match_a4eb_prefix": _fresh_match_a4eb_prefix_result.duplicate(true),
		"fresh_match_a503_entry": _fresh_match_a503_entry_result.duplicate(true),
		"fresh_match_a503_text_setup": _fresh_match_a503_text_setup_result.duplicate(true),
		"fresh_match_a503_palette_ramp": _fresh_match_a503_palette_ramp_result.duplicate(true),
		"fresh_match_a503_input_wait": _fresh_match_a503_input_wait_result.duplicate(true),
		"fresh_match_a503_postwait_fade": _fresh_match_a503_postwait_fade_result.duplicate(true),
		"fresh_match_a503_a611_handoff": _fresh_match_a503_a611_handoff.duplicate(true),
		"fresh_match_stamina_initialization": _fresh_match_stamina_result.duplicate(true),
		"fresh_match_setup_music_store": _fresh_match_music_store_result.duplicate(true),
		"fresh_match_caller_tail": _fresh_match_caller_tail_result.duplicate(true),
		"fresh_match_a64c_setup": _fresh_match_a64c_setup_result.duplicate(true),
		"fresh_match_handoff": _fresh_match_handoff_result.duplicate(true),
		"fresh_match_a503_controller_sample": _fresh_match_a503_controller_sample.duplicate(true),
		"fresh_source_route_accepts_gameplay_input": _is_source_route_waiting(),
		"fresh_scheduler_dispatch": _fresh_scheduler_dispatch.duplicate(true),
		"fresh_period_task": _fresh_period_task_status.duplicate(true),
		"initial_player_positions": _initial_player_positions.duplicate(true),
		"unsupported_audio_queue_ids": cue_audio.unsupported_queue_ids.duplicate(),
		"sound_queue_write_events": _sound_queue_event_history.duplicate(true),
		"match_player_state": _match_player_state_provider.get_source_status() if _match_player_state_provider != null else {},
		"route_gaps": route_gaps.duplicate(),
	}


func _advance_route_source_tick() -> void:
	source_frame += 1
	scheduler_tick += 1
	var resumed_fa0f_return_before_nmi := false
	var controller_sample: Dictionary = {}
	if route_stage == RouteStage.MATCH_SETUP_A503_INPUT_WAIT:
		controller_sample = _sample_live_source_controller_frame()
		_fresh_match_a503_controller_sample = controller_sample.duplicate(true)
	elif _is_source_route_waiting():
		if _fresh_source_route_runner == null:
			_route_gaps_add("Source-frame controller sampling has no configured route runner.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var route_status: Dictionary = _fresh_source_route_runner.get_status()
		var source_wait_boundary := String(route_status.get("source_boundary", ""))
		var pass_receiver_poll_pending := bool(route_status.get(
			"pass_receiver_confirmation_input_pending", false))
		var defer_sample_for_rom_busy_wait := String(route_status.get("phase", "")) == "awaiting_external_nmi" \
			and source_wait_boundary in ["slot15_map_worker_busy_wait",
				"$A21A BPL busy loop waits for the next external NMI",
				"PASS receiver `$D80C->$CB0F` saved; awaiting source NMI before `$D80F` input poll",
				"$CB0F slot-$05 PASS confirmation waiter busy poll `$CC50` -> scheduler WAIT_FOR_NMI_READY"]
		defer_sample_for_rom_busy_wait = defer_sample_for_rom_busy_wait \
			or bool(route_status.get("pass_receiver_wait_nmi_pending", false)) \
			or bool(route_status.get("pass_receiver_descriptor_1d_final_nmi_pending", false)) \
			or pass_receiver_poll_pending
		if not _deferred_pass_receiver_controller_sample.is_empty():
			controller_sample = _deferred_pass_receiver_controller_sample.duplicate(true)
			controller_sample["deferred_until_source_poll"] = true
		elif pass_receiver_poll_pending:
			# The source route can resume its receiver confirmation after an NMI
			# boundary on the following scheduler tick. Preserve only a fresh A
			# edge for that one source poll; unrelated button/direction edges must
			# not shadow it, and the released host frame must not erase the receipt.
			var deferred_sample_result: Dictionary = _fresh_source_route_runner.sample_controller_input(
				_held_kickoff_input_bits)
			if not bool(deferred_sample_result.get("ok", false)):
				_route_gaps_add("PASS receiver busy-wait controller sample failed: %s" % String(
					deferred_sample_result.get("error", "unknown source error")))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			controller_sample = deferred_sample_result.get("sample", {}).duplicate(true)
			controller_sample["source_frame_label"] = source_frame
			_previous_source_controller_bits = _held_kickoff_input_bits & 0xFF
			if int(controller_sample.get("current", 0)) == 0x80 \
					and int(controller_sample.get("held_ram_001c", 0)) == 0x80 \
					and int(controller_sample.get("edge_ram_001e", 0)) == 0x80 \
					and int(controller_sample.get("newly_pressed", 0)) == 0x80 \
					and (int(controller_sample.get("previous", 0)) & 0x80) == 0:
				_deferred_pass_receiver_controller_sample = controller_sample.duplicate(true)
		elif defer_sample_for_rom_busy_wait:
			controller_sample = {"status": "deferred_while_rom_busy_poll_runs",
				"sampled": false, "held_bits": _held_kickoff_input_bits & 0xFF}
		else:
			var sample_result: Dictionary = _fresh_source_route_runner.sample_controller_input(
				_held_kickoff_input_bits)
			if not bool(sample_result.get("ok", false)):
				_route_gaps_add("Source-frame controller sample failed: %s" % String(sample_result.get("error", "unknown source error")))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			controller_sample = sample_result.get("sample", {}).duplicate(true)
			controller_sample["source_frame_label"] = source_frame
			_previous_source_controller_bits = _held_kickoff_input_bits & 0xFF
	else:
		_previous_source_controller_bits = _held_kickoff_input_bits & 0xFF
	if not _consume_pending_cleanup_fade_palette_packet():
		return
	if not _consume_pending_fresh_match_a503_fade_packet():
		return
	# FA `$0F` returns as soon as its final non-yield packet segment is staged.
	# Resume the parent cutscene stream at that source scheduler boundary before
	# the following NMI consumes the shared queue; otherwise `$F3 $00` would see
	# a falsely empty `$0628` cursor and its first text glyph would skip the ROM
	# `$9B28->$9FA8` capacity wait.
	if (_is_cutscene_stage() or route_stage == RouteStage.MEETING_SCENE) \
			and String(_cutscene_external_task_return_pending.get("task_kind", "")) == "fa_0f_background" \
			and source_frame >= int(_cutscene_external_task_return_pending.get("resume_source_frame", 0)):
		_resume_cutscene_external_task_return()
		resumed_fa0f_return_before_nmi = _cutscene_external_task_return_pending.is_empty() \
			and route_stage != RouteStage.SOURCE_ROUTE_GAP
	var source_nmi_receipt: Dictionary = {}
	if is_instance_valid(_visuals):
		source_nmi_receipt = _visuals.advance_source_tick(source_frame)
	if _is_cutscene_stage() or route_stage == RouteStage.MEETING_SCENE:
		if not _cutscene_external_task_return_pending.is_empty():
			_resume_cutscene_external_task_return()
		elif _cutscene_f1_dialog_task != null:
			_advance_cutscene_f1_dialog_task(source_nmi_receipt)
		elif _cutscene_fa0f_preclear_task != null:
			_advance_cutscene_fa0f_preclear_task(source_nmi_receipt)
		elif _cutscene_background_task != null:
			if bool(_cutscene_background_task.uses_nmi_release_receipts):
				_advance_cutscene_background_task(source_nmi_receipt)
			else:
				_advance_cutscene_background_task()
		elif _cutscene_eb_post_wait_task != null:
			_advance_cutscene_eb_post_wait_task()
		elif vm.state == KickoffCutsceneCommandVm.RunState.WAITING_INPUT and _pending_a_edge:
			_begin_cutscene_eb_post_wait_task()
		elif resumed_fa0f_return_before_nmi:
			# The parent command pump already ran before this frame's NMI. Do not
			# perform a second scheduler scan until the next source frame.
			pass
		else:
			vm.advance_scheduler_tick(NES_A_EDGE if _pending_a_edge else 0)
		if vm.cutscene_id in [1, 2] and _cutscene_select_wait_task != null \
				and _cutscene_select_wait_task.is_waiting():
			_advance_cutscene_select_wait(vm.cutscene_id)
	elif route_stage == RouteStage.TITLE_HANDOFF_FADE:
		_advance_title_handoff_fade()
	elif route_stage == RouteStage.CUTSCENE_CLEANUP_FADE:
		_advance_cutscene_cleanup_fade()
	elif route_stage == RouteStage.MEETING_MENU:
		if is_instance_valid(_meeting_menu_input):
			_meeting_menu_input.call("flush_pending_input")
	elif route_stage == RouteStage.CUTSCENE_56_NATURAL_WAIT:
		_advance_scene56_natural_wait()
	elif route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI:
		_advance_fresh_source_route_frame_level_nmi(controller_sample)
	elif route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
		_advance_fresh_source_route_selected_tasks(controller_sample)
		# A selected source task can finish its CPU slice by yielding to the next
		# normal NMI. This tick has not serviced an NMI yet; deliver that frame's
		# boundary now instead of idling until the following source tick. FCEUX
		# shows the PASS path completing `$CB0F` slot-$09 work in frame 9068 and
		# resuming the descriptor worker in frame 9069. Deferring this NMI adds an
		# observable frame to the recorded-input route.
		if route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI \
				and _fresh_source_route_runner != null:
			var route_after_task: Dictionary = _fresh_source_route_runner.get_status()
			if int(route_after_task.get("last_external_nmi_frame", -1)) < source_frame:
				_advance_fresh_source_route_frame_level_nmi(controller_sample)
	elif route_stage == RouteStage.FIRST_ACTION_MENU_PENDING:
		# A pending route does not advance by an invented wait. The ROM task,
		# callback event, packet queue, and caller-owned player state are not yet
		# produced here, so leave the endpoint explicitly pending.
		pass
	elif route_stage == RouteStage.FIRST_ACTION_HANDLER_PENDING:
		# The next source-frame NMI precedes the pending `$D5EA` continuation.
		# Service its real PPU queue/latch effects first, then run the ROM bridge.
		if _service_first_action_menu_external_nmi():
			_advance_first_action_menu_dispatch()
		pass
	elif route_stage == RouteStage.MATCH_SELECTOR_RUNNING:
		_advance_fresh_match_selector_clock()
	elif route_stage == RouteStage.MATCH_SETUP_A503_TEXT_SETUP:
		_advance_fresh_match_a503_text_setup()
	elif route_stage == RouteStage.MATCH_SETUP_A503_PALETTE_RAMP:
		_advance_fresh_match_a503_palette_ramp()
	elif route_stage == RouteStage.MATCH_SETUP_A503_INPUT_WAIT:
		_advance_fresh_match_a503_input_wait(controller_sample)
	elif route_stage == RouteStage.MATCH_SETUP_A503_POSTWAIT_FADE:
		_advance_fresh_match_a503_postwait_fade()
	elif route_stage == RouteStage.MATCH_SETUP_A503_LEVEL_UPDATE:
		_advance_fresh_match_a503_level_update()
	elif route_stage == RouteStage.MATCH_SETUP_811F_PENDING:
		_advance_fresh_match_stamina_initialization()
	elif route_stage == RouteStage.MATCH_SETUP_A64C_PENDING:
		_advance_fresh_match_a64c_setup()
	elif route_stage == RouteStage.FIRST_ACTION_MENU:
		if is_instance_valid(_menu_input):
			_menu_input.flush_pending_input()
		if _service_first_action_menu_external_nmi():
			_sample_first_action_menu_source_controller_frame()
		if route_stage == RouteStage.FIRST_ACTION_MENU:
			_advance_action_label_blink()
	_pending_a_edge = false
	_pending_select_edge = false
	_pending_b_edge = false


## Frame-level live input adapter for `$A571`. The current controller scanner's
## interrupt phase is not modeled; this preserves the route's actual prior and
## current pad masks and applies the verified `$001C/$001E` edge expression.
func _sample_live_source_controller_frame() -> Dictionary:
	var previous := _previous_source_controller_bits & 0xFF
	var current := _held_kickoff_input_bits & 0xFF
	var newly_pressed := (previous ^ current) & current
	_previous_source_controller_bits = current
	return {"previous": previous, "current": current,
		"newly_pressed": newly_pressed,
		"held_ram_001c": current, "edge_ram_001e": newly_pressed,
		"sample_source": "live_route_input_frame_adapter",
		"source_frame": _a503_source_frame_label(),
		"controller_nmi_phase_modeled": false}


## Carries the actual first-action menu pad state into the live source scheduler
## at its validated `$D5EA` wait boundary, then runs the bounded ROM-byte input
## poll and adopts only verified PASS selection/confirmation effects. The
## handler body remains pending until its own source executor is connected.
func _sample_first_action_menu_source_controller_frame() -> void:
	_first_action_menu_source_input_sample.clear()
	if _fresh_source_route_runner == null or not _fresh_source_route_runner.has_method("sample_controller_input") \
			or not is_instance_valid(_menu_input):
		return
	var pad_state := _first_action_menu_nes_pad_state()
	var sample_result: Dictionary = _fresh_source_route_runner.sample_controller_input(pad_state)
	if not bool(sample_result.get("ok", false)):
		_route_gaps_add("First-action menu source input sample failed: %s" % String(sample_result.get("error", "unknown source error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_first_action_menu_source_input_sample = {
		"source_frame": source_frame,
		"source_wait_pc": int(sample_result.get("pending_selected_task_boundary_pc", -1)),
		"sample": sample_result.get("sample", {}).duplicate(true),
		"source_input_consumed": false,
		"source_cycle_phase_modeled": false,
	}
	if not _fresh_source_route_runner.has_method("resolve_first_action_menu_source_poll"):
		_route_gaps_add("Live first-action input is sampled, but the ROM `$D5EA` source poll is not connected.")
		return
	var poll_result: Dictionary = _fresh_source_route_runner.resolve_first_action_menu_source_poll(
		_first_action_menu_source_input_sample["sample"])
	if not bool(poll_result.get("ok", false)):
		_route_gaps_add("First-action ROM input poll failed: %s" % String(poll_result.get("error", "unknown source error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_first_action_menu_source_input_sample["source_poll_status"] = String(poll_result.get("status", ""))
	_first_action_menu_source_input_sample["source_input_consumed"] = bool(
		poll_result.get("source_input_consumed", false))
	_first_action_menu_source_input_sample["source_writes_applied"] = poll_result.get(
		"source_writes_applied", []).duplicate(true)
	_first_action_menu_source_input_sample["pending_handler_dispatch"] = poll_result.get(
		"pending_handler_dispatch", {}).duplicate(true)
	if String(poll_result.get("status", "")) == "pass_selection_adopted" \
			and (not is_instance_valid(_menu_input) \
				or _menu_input.selected_action_id != FirstActionMenuInput.ActionId.PASS \
				or _menu_input.selected_direction_index != FirstActionMenuInput.DirectionIndex.LEFT):
		_route_gaps_add("ROM `$D6E8` selected PASS, but the visible menu selection did not match the same input edge.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
	elif String(poll_result.get("status", "")) in ["pass_confirmation_pending_source_execution",
			"pass_handler_entry_adopted"]:
		if is_instance_valid(_menu_input):
			_menu_input.set_process_unhandled_input(false)
			_menu_input.set_process_input(false)
		route_stage = RouteStage.FIRST_ACTION_HANDLER_PENDING
		route_stage_changed.emit(_stage_name())


func _service_first_action_menu_external_nmi() -> bool:
	if _fresh_source_route_runner == null \
			or not _fresh_source_route_runner.has_method("service_first_action_menu_external_nmi"):
		_route_gaps_add("The active `$D5EA` route has no source-owned NMI service for this frame.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var scheduler_status: Dictionary = _fresh_source_route_runner.get_status().get("scheduler", {})
	var ppu_ctrl_shadow := int(scheduler_status.get("live_ppu_ctrl_shadow", -1))
	if ppu_ctrl_shadow < 0 or (ppu_ctrl_shadow & 0x80) == 0:
		_route_gaps_add("Live ROM `$2000` shadow does not enable the first-action frame NMI.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var nmi_result: Dictionary = _fresh_source_route_runner.call(
		"service_first_action_menu_external_nmi", source_frame, ppu_ctrl_shadow)
	if not bool(nmi_result.get("ok", false)) \
			or not bool(nmi_result.get("external_nmi_consumed", false)):
		_route_gaps_add("Source scheduler rejected the first-action frame NMI: %s" % String(
			nmi_result.get("error", _fresh_source_route_runner.get("error_message"))))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	_fresh_source_route_nmi_result = nmi_result.get("normal_nmi_result", {}).duplicate(true)
	_emit_cbf1_audio_events_from_source_result(_fresh_source_route_nmi_result)
	var ppu_bus_events: Variant = nmi_result.get("ppu_bus_events", [])
	if not ppu_bus_events is Array:
		_route_gaps_add("First-action source NMI returned malformed PPU bus events.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	if not (ppu_bus_events as Array).is_empty():
		var ppu_render_result: Dictionary = _visuals.apply_source_ppu_bus_events(
			ppu_bus_events, ppu_ctrl_shadow)
		if not bool(ppu_render_result.get("ok", false)) \
				or not (ppu_render_result.get("unapplied_writes", []) as Array).is_empty():
			_route_gaps_add("First-action NMI PPU events could not be presented from their ROM source.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return false
		_fresh_source_route_nmi_result["ppu_bus_events_applied"] = true
		_fresh_source_route_nmi_result["ppu_render_result"] = ppu_render_result.duplicate(true)
	_fresh_source_route_nmi_abstraction_count += 1
	_fresh_source_route_nmi_timing_note = "Serviced the caller-supplied frame-level NMI at source frame %d before the active `$D5EA` task resumed; no beam/dot/cycle phase is modeled." % source_frame
	return true


func _advance_first_action_menu_dispatch(remaining_immediate_steps: int = 8) -> void:
	if remaining_immediate_steps <= 0:
		_route_gaps_add("PASS source continuations exceeded the bounded same-frame dispatch chain.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if _first_action_menu_dispatch_entry_reached:
		if _fresh_source_route_runner == null:
			return
		var live_phase := String(_fresh_source_route_runner.get_status().get("phase", ""))
		if live_phase not in ["first_action_pass_handler_ready", "first_action_pass_cb0f_ready"]:
			return
	if _fresh_source_route_runner == null \
			or not _fresh_source_route_runner.has_method("resume_pending_first_action_menu_pass_dispatch"):
		return
	var dispatch_result: Dictionary = _fresh_source_route_runner.call(
			"resume_pending_first_action_menu_pass_dispatch")
	if not bool(dispatch_result.get("ok", false)):
		_route_gaps_add("PASS handler dispatch continuation failed: %s" % String(
			dispatch_result.get("error", "unknown source error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var dispatch_status := String(dispatch_result.get("status", ""))
	if not _first_action_menu_source_input_sample.has("next_frame_dispatch"):
		_first_action_menu_source_input_sample["next_frame_dispatch"] = dispatch_result.duplicate(true)
	var dispatch_history: Array = _first_action_menu_source_input_sample.get(
		"same_frame_dispatch_history", [])
	dispatch_history.append(dispatch_result.duplicate(true))
	_first_action_menu_source_input_sample["same_frame_dispatch_history"] = dispatch_history
	if dispatch_status == "pass_d5ea_source_execution_gap":
		_route_gaps_add("PASS confirmation is held at live `$D5EA`; the ROM helper/NMI chain to `$D6C7` is not implemented yet.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if dispatch_status == "pass_confirmation_scheduler_handoff":
		_set_route_stage_from_source_runner()
		if route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
			_advance_fresh_source_route_selected_tasks()
		if route_stage == RouteStage.FIRST_ACTION_HANDLER_PENDING:
			_advance_first_action_menu_dispatch(remaining_immediate_steps - 1)
			return
		if route_stage not in [RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI,
				RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE,
				RouteStage.FIRST_ACTION_HANDLER_PENDING]:
			var failed_status: Dictionary = _fresh_source_route_runner.get_status()
			var detail := String(route_gaps.back()) if not route_gaps.is_empty() else "no route detail"
			_route_gaps_add("PASS confirmation reached `$CAA5`, but the selected ROM task did not reach a supported NMI/task boundary (phase=%s, boundary=%s, selected_slot=$%02X; %s)." % [
				String(failed_status.get("phase", "unknown")),
				String(failed_status.get("source_boundary", "unknown")),
				int(failed_status.get("pending_selected_task_slot", -1)) & 0xFF,
				detail])
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
		return
	if dispatch_status in ["pass_action_caller_reached_d6c7",
			"pass_scenario38_queue_at_cb0f_call_entry"]:
		_advance_first_action_menu_dispatch(remaining_immediate_steps - 1)
		return
	if dispatch_status == "pass_handler_scheduler_handoff":
		_set_route_stage_from_source_runner()
		if route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
			_advance_fresh_source_route_selected_tasks()
		elif route_stage != RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI:
			_route_gaps_add("PASS scenario `$38` reached the `$CB0F` yield, but the scheduler did not produce a supported task/NMI boundary.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
		return
	if dispatch_status == "pass_handler_entry_adopted":
		_first_action_menu_dispatch_entry_reached = true
		_first_action_menu_source_input_sample["handler_entry_reached_source_frame"] = source_frame
		_advance_first_action_menu_dispatch(remaining_immediate_steps - 1)


func _first_action_menu_nes_pad_state() -> int:
	if _menu_input.has_method("consume_nes_pad_state_for_source_poll"):
		return int(_menu_input.call("consume_nes_pad_state_for_source_poll")) & 0xFF
	if _menu_input.has_method("get_nes_pad_state"):
		return int(_menu_input.call("get_nes_pad_state")) & 0xFF
	var button_state := 0
	var action_bits := {
		"match_action_right": 0x01,
		"match_action_left": 0x02,
		"match_action_down": 0x04,
		"match_action_up": 0x08,
		"match_action_confirm": NES_A_EDGE,
	}
	for action_variant in action_bits:
		var action_name := StringName(action_variant)
		if InputMap.has_action(action_name) and Input.is_action_pressed(action_name):
			button_state |= int(action_bits[action_variant])
	return button_state & 0xFF


## FCEUX's caller first enters `$A571` at frame 7284, then returns from its
## initial `$9FA8` yield before the first X decrement/input poll at frame 7285.
## These trace labels are source-frame observations only, not CPU/PPU phase.
func _a503_source_frame_label() -> int:
	return maxi(0, source_frame - 1)


func _start_cutscene(cutscene_id: int) -> void:
	var effective_cutscene_id := cutscene_id
	if cutscene_id == 1:
		var worker_seed: Variant = CUTSCENE_WORKER_SEED_SCRIPT.new()
		if not worker_seed.configure_from_project_sources():
			_route_gaps_add("Cutscene worker task source could not be verified: %s" % worker_seed.error_message)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_worker_seed_receipt = worker_seed.build_title_cutscene1_seed(_title_handoff_receipt)
		if not bool(_cutscene_worker_seed_receipt.get("ok", false)):
			_route_gaps_add("KICK OFF cutscene worker seed was refused: %s" % String(_cutscene_worker_seed_receipt.get("error", "invalid source handoff")))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		if not _has_cutscene1_worker_entry_context(_cutscene_worker_seed_receipt):
			_route_gaps_add("KICK OFF cutscene worker entry CPU/stack context did not match the ROM-derived `$84C6` restore.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		if not _merge_cutscene1_mapper_bank6_shadow(_cutscene_worker_seed_receipt):
			_route_gaps_add("ROM `$9F5F` bank-6 shadow `$0024` write could not be carried into source RAM: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		effective_cutscene_id = int(_cutscene_worker_seed_receipt.get("caller_event", {}).get("cutscene_id", -1))
	var fade_a: Dictionary = _source_ram_image.get_byte(0x004A)
	var fade_b: Dictionary = _source_ram_image.get_byte(0x004B)
	if not bool(fade_a.get("known", false)) or not bool(fade_b.get("known", false)) \
			or int(fade_a.get("value", -1)) != int(fade_b.get("value", -2)):
		_route_gaps_add("ROM cutscene `$%02X` has no known equal `$004A/$004B` source fade state." % effective_cutscene_id)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var initial_fade_counters := Vector2i(int(fade_a["value"]), int(fade_b["value"]))
	if not vm.start_cutscene(effective_cutscene_id, initial_fade_counters):
		push_error("Could not start KICK OFF cutscene %d: %s" % [cutscene_id, vm.error_message])
		return
	_cutscene_cleanup_fade_task = null
	_cutscene_cleanup_clear_result.clear()
	_cutscene_cleanup_ram_writes.clear()
	_cutscene_post_helper_ram_writes.clear()
	_cutscene_cleanup_fade_counters = Vector2i.ZERO
	_cutscene_wait_cleanup_result.clear()
	match cutscene_id:
		1:
			route_stage = RouteStage.CUTSCENE_1
		2:
			route_stage = RouteStage.CUTSCENE_2
		0x56:
			route_stage = RouteStage.CUTSCENE_56
		0x44:
			route_stage = RouteStage.MEETING_SCENE
		_:
			push_error("Unexpected source cutscene ID %d on KICK OFF route." % cutscene_id)
			return
	if cutscene_id in [1, 2]:
		_cutscene_select_wait_task = CUTSCENE_SELECT_WAIT_TASK_SCRIPT.new()
		if not _cutscene_select_wait_task.configure_from_project_sources() \
				or not _cutscene_select_wait_task.begin():
			_route_gaps_add("ROM `$82B5` Select waiter could not start: %s" % _cutscene_select_wait_task.error_message)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
	route_stage_changed.emit(_stage_name())


func _has_cutscene1_worker_entry_context(receipt: Dictionary) -> bool:
	if String(receipt.get("source_rom_sha256", "")) != TITLE_HANDOFF_ROM_SHA256 \
			or bool(receipt.get("trace_state_used", true)) \
			or bool(receipt.get("emulator_data_used", true)) \
			or int(receipt.get("resume_pc", -1)) != 0x84C6 \
			or int(receipt.get("resume_sp", -1)) != 0x50 \
			or int(receipt.get("slot_offset", -1)) != 0x05 \
			or int(receipt.get("bank_low", -1)) != 0x00:
		return false
	var cpu: Variant = receipt.get("worker_entry_cpu", {})
	if not cpu is Dictionary \
			or int(cpu.get("pc", -1)) != 0x84C6 \
			or int(cpu.get("a", -1)) != 0x4E \
			or int(cpu.get("x", -1)) != 0x4E \
			or int(cpu.get("y", -1)) != 0x4E \
			or int(cpu.get("sp", -1)) != 0x50:
		return false
	var stack_bytes: Variant = receipt.get("worker_entry_stack_bytes", [])
	if not stack_bytes is Array:
		return false
	var values: Dictionary = {}
	for byte_variant in stack_bytes:
		if byte_variant is Dictionary:
			var byte_record: Dictionary = byte_variant
			values[int(byte_record.get("address", -1))] = int(byte_record.get("value", -1))
	return int(values.get(0x014F, -1)) == 0xC5 and int(values.get(0x0150, -1)) == 0x84


func _merge_cutscene1_mapper_bank6_shadow(receipt: Dictionary) -> bool:
	var resume_writes: Variant = receipt.get("resume_ram_writes", [])
	if not resume_writes is Array:
		return false
	var bank6_write: Dictionary = {}
	for write_variant in resume_writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x0024:
			if not bank6_write.is_empty():
				return false
			bank6_write = write.duplicate(true)
	if int(bank6_write.get("source_pc", -1)) != 0x9F5F \
			or int(bank6_write.get("value", -1)) != 0x00:
		return false
	# Carry only this source-owned mapper shadow into the sparse ledger. The
	# worker receipt's historical stack bytes are not a live stack snapshot.
	var bank6_receipt := receipt.duplicate(true)
	bank6_receipt["ram_writes"] = [bank6_write]
	return _source_ram_image.merge_executor_result(
		"kickoff_cutscene1_mapper_bank6_shadow_0024", bank6_receipt)


func _begin_title_handoff_fade() -> void:
	var fade_task: Variant = CUTSCENE_CLEANUP_FADE_TASK_SCRIPT.new()
	if not fade_task.configure_from_project_sources() \
			or not fade_task.begin(_title_fade_counters.x, _title_fade_counters.y,
				_title_fade_base_palette):
		_route_gaps_add("ROM `$99F0` title handoff fade could not start: %s" % fade_task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_title_handoff_fade_task = fade_task
	route_stage = RouteStage.TITLE_HANDOFF_FADE
	_advance_title_handoff_fade()
	route_stage_changed.emit(_stage_name())


func _advance_title_handoff_fade() -> void:
	if _title_handoff_fade_task == null or not is_instance_valid(_title_source_renderer):
		_route_gaps_add("ROM `$99F0` title fade has no live title palette consumer.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _title_handoff_pending_palette_packet.is_empty() \
			and _title_handoff_pending_palette_source_frame < source_frame:
		if not bool(_title_source_renderer.call("set_rom_fade_palette_bytes",
				_title_handoff_pending_palette_packet.slice(3, 0x23))):
			_route_gaps_add("Staged ROM `$9A71` title palette packet could not commit at the next source tick.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		_title_handoff_pending_palette_packet.clear()
		_title_handoff_pending_palette_source_frame = -1
	var step: Dictionary = _title_handoff_fade_task.advance_source_tick(source_frame)
	_title_handoff_fade_receipt["last_step"] = _title_handoff_fade_task.get_status()
	if not bool(step.get("ok", false)):
		_route_gaps_add("ROM `$99F0` title fade stopped: %s" % String(step.get("error", step.get("status", "unknown error"))))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if String(step.get("status", "")) == "yielded_after_palette_step":
		var packet: PackedByteArray = step.get("palette_packet", PackedByteArray())
		if packet.size() != 0x23:
			_route_gaps_add("ROM `$9A71` title fade packet has an invalid size.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		_title_handoff_pending_palette_packet = packet.duplicate()
		_title_handoff_pending_palette_source_frame = source_frame
		return
	if String(step.get("status", "")) != "returned_zero_counters":
		return
	var clear_task: Variant = CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT.new()
	if not clear_task.configure_from_project_sources():
		_route_gaps_add("Title handoff `$98A0/$9B7F` sources failed verification: %s" % clear_task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_title_handoff_clear_result = clear_task.execute(_title_source_renderer,
		_get_source_ppu_shadow_input())
	if not bool(_title_handoff_clear_result.get("ok", false)):
		_route_gaps_add("Title handoff PPU/OAM clear failed: %s" % String(_title_handoff_clear_result.get("error", "unknown presenter error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _accept_cleanup_ppu_shadow_result(
			"kickoff_title_handoff_cleanup_clear", _title_handoff_clear_result):
		_route_gaps_add("Title-handoff cleanup did not return valid ROM-derived PPU shadow writes.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _visuals.apply_rom_cutscene_cleanup_clear():
		_route_gaps_add("Route cutscene presenter refused the title `$98A0/$9B7F` clear state.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var title_ppu_register_writes: Array = _title_handoff_clear_result.get("ppu_register_writes", [])
	if not title_ppu_register_writes.is_empty() \
			and not _visuals.apply_source_ppu_register_writes(title_ppu_register_writes):
		_route_gaps_add("Route cutscene presenter refused the ROM title-handoff PPU register writes.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _source_ram_image.merge_executor_result(
			"kickoff_title_handoff_cleanup_clear", _cleanup_ram_result_for_source_ledger(
				_title_handoff_clear_result)):
		_route_gaps_add("Title-handoff source RAM writes could not join the live ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var dispatch_seed: Variant = CUTSCENE_ATTRIBUTE_TAIL_SEED_SCRIPT.new()
	if not dispatch_seed.configure_from_project_sources():
		_route_gaps_add("ROM `$8464->$98EA` attribute-tail seed failed verification: %s" % dispatch_seed.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var seed_presenters: Array[Node] = [_title_source_renderer, _visuals]
	_title_handoff_dispatch_seed_result = dispatch_seed.execute(seed_presenters, source_frame)
	if not bool(_title_handoff_dispatch_seed_result.get("ok", false)):
		_route_gaps_add("ROM `$8464->$98EA` attribute-tail seed could not update the live presenters.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_title_handoff_fade_receipt["status"] = "returned_from_9ba0"
	_title_handoff_fade_receipt["clear_result"] = _title_handoff_clear_result.duplicate(true)
	_title_handoff_fade_receipt["attribute_tail_seed"] = _title_handoff_dispatch_seed_result.duplicate(true)
	title_handoff_fade_completed.emit()
	_title_source_renderer = null
	_start_cutscene(1)


func _on_presenter_event(event: Dictionary) -> void:
	var kind := str(event.get("kind", ""))
	if kind == "palette_command":
		_record_rom_f3_palette_command(event)
		return
	if kind in ["background_1", "background_2"]:
		_begin_cutscene_background_task(event)
		return
	var dialog_arguments: Array = event.get("arguments", [])
	if kind == "dialog_window" and vm.cutscene_id == 0x56 \
			and int(event.get("opcode", -1)) == 0xF1 \
			and dialog_arguments.size() == 1 and int(dialog_arguments[0]) == 0x02:
		_begin_cutscene_f1_dialog_task(event)
		return
	if kind == "visual_preset":
		_record_e8_preset_source_writes(event)
		return
	if kind == "animations" and vm.cutscene_id == 1 \
			and int(event.get("event_index", -1)) == 51:
		_record_cutscene_animation_chr_shadow(event)
		return
	if kind != "sound_command":
		return
	var queue_write: RefCounted = SOUND_QUEUE_EVENT_SCRIPT.new()
	if not bool(queue_write.call("populate_from_cutscene_ed_command",
			vm.cutscene_id, event, source_frame)):
		_route_gaps_add("A cutscene sound command failed its ROM queue-write provenance checks.")
		return
	var queue_write_data: Dictionary = queue_write.call("to_dictionary")
	_sound_queue_event_history.append(queue_write_data)
	rom_sound_queue_write_requested.emit(queue_write)


func _record_cutscene_fade_counter_step(event: Dictionary, level: int) -> void:
	var opcode := int(event.get("opcode", -1))
	var event_index := int(event.get("event_index", -1))
	var event_pc := int(event.get("cpu_address", -1))
	if opcode not in [0xE9, 0xEA] or event_index < 0 or event_pc < 0 \
			or level < 0 or level > 0x0F:
		_route_gaps_add("ROM cutscene palette step has no valid `$E9/$EA` event contract.")
		return
	var write_pcs := [0x9992, 0x999A] if opcode == 0xE9 else [0x99F9, 0x99FF]
	var writes: Array[Dictionary] = []
	for index in 2:
		var address := 0x004A + index
		var prior: Dictionary = _source_ram_image.get_byte(address)
		var prior_value := int(prior.get("value", -1))
		if not bool(prior.get("known", false)):
			_route_gaps_add("ROM `$%04X` fade counter disagrees with the live `$%04X` source write." % [event_pc, address])
			return
		if opcode == 0xE9:
			if prior_value == level - 1:
				writes.append({"source_pc": write_pcs[index], "address": address, "value": level})
			elif prior_value != 0x0F or level != 0x0F:
				_route_gaps_add("ROM `$%04X` fade-up counter cannot advance from `$%02X` to `$%02X`." % [event_pc, prior_value, level])
				return
		elif prior_value == level + 1:
			writes.append({"source_pc": write_pcs[index], "address": address, "value": level})
		else:
			_route_gaps_add("ROM `$%04X` fade-down counter cannot advance from `$%02X` to `$%02X`." % [event_pc, prior_value, level])
			return
	var source_event_id := "cutscene_%02X_event_%03d_%04X_fade_%02X_%02d" % [
		vm.cutscene_id, event_index, event_pc, opcode, level]
	var receipt := {
		"ok": true,
		"status": "rom_cutscene_fade_counter_writes",
		"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"source_event_id": source_event_id,
		"source_cutscene_event": {"cutscene_id": vm.cutscene_id,
			"event_index": event_index, "cpu_address": event_pc,
			"opcode": opcode, "fade_level": level},
		"ram_writes": writes,
		"trace_state_used": false,
		"emulator_data_used": false,
	}
	if not _source_ram_image.merge_executor_result(source_event_id, receipt):
		_route_gaps_add("ROM cutscene fade counter writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
		return
	_cutscene_fade_counter_history.append({
		"source_frame": source_frame,
		"source_event_id": source_event_id,
		"cutscene_id": vm.cutscene_id,
		"event_index": event_index,
		"event_cpu_address": event_pc,
		"opcode": opcode,
		"fade_level": level,
		"ram_writes": writes.duplicate(true),
	})


func _record_rom_f3_palette_command(event: Dictionary) -> void:
	var arguments: Array = event.get("arguments", [])
	var raw_bytes: Array = event.get("raw_bytes", [])
	if int(event.get("opcode", -1)) != 0xF3 or arguments.size() != 1 \
			or int(arguments[0]) != 0x00 or raw_bytes.size() != 2 \
			or int(raw_bytes[0]) != 0xF3 or int(raw_bytes[1]) != 0x00:
		_route_gaps_add("Only ROM `$F3 $00` palette rebuild is resolved for this route.")
		return
	var event_index := int(event.get("event_index", -1))
	var event_pc := int(event.get("cpu_address", -1))
	if event_index < 0 or event_pc < 0:
		_route_gaps_add("ROM `$F3 $00` event has no checked source identity.")
		return
	var source_event_id := "cutscene_%02X_event_%03d_%04X_f3_00" % [
		vm.cutscene_id, event_index, event_pc]
	var receipt := {
		"ok": true,
		"status": "rom_f3_00_palette_counter_reset",
		"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"source_event_id": source_event_id,
		"source_cutscene_event": {"cutscene_id": vm.cutscene_id,
			"event_index": event_index, "cpu_address": event_pc,
			"opcode": 0xF3, "operand": 0x00},
		"ram_writes": [
			{"source_pc": 0x9A45, "address": 0x004A, "value": 0x0F},
			{"source_pc": 0x9A47, "address": 0x004B, "value": 0x0F},
		],
		"trace_state_used": false,
		"emulator_data_used": false,
	}
	if not _source_ram_image.merge_executor_result(source_event_id, receipt):
		_route_gaps_add("ROM `$9A35` palette-counter writes could not join source RAM: %s" % _source_ram_image.error_message)
		return
	if not vm.apply_rom_f3_palette_rebuild(event):
		_route_gaps_add("ROM `$F3 $00` palette event did not match the active cutscene VM command.")
		return
	var palette_batch: Dictionary = _visuals.build_f3_00_palette_nmi_batch(event)
	if not bool(palette_batch.get("ok", false)):
		_route_gaps_add("ROM `$F3 $00` palette packet could not be built from active ROM selectors: %s" % String(palette_batch.get("error", "unknown palette source error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	palette_batch["event_id"] = source_event_id
	if not _visuals.stage_source_nmi_packet_batch(palette_batch,
			RomCutsceneBackgroundSourceTask.NMI_QUEUE_CONSUMER_PC):
		_route_gaps_add("ROM `$F3 $00` palette packet could not reserve the shared PPU queue.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_f3_palette_queue_history.append({
		"source_frame": source_frame,
		"source_event_id": source_event_id,
		"cutscene_id": vm.cutscene_id,
		"event_index": event_index,
		"event_cpu_address": event_pc,
		"background_id": int(palette_batch.get("background_id", -1)),
		"source_palette": palette_batch.get("source_palette", PackedByteArray()),
		"palette_payload": palette_batch.get("palette_payload", PackedByteArray()),
		"queue_cursor_before": int(palette_batch.get("queue_cursor_before", -1)),
		"queue_cursor_after_staging": int(palette_batch.get("queue_cursor_bytes", -1)),
		"serialized_queue_byte_count": int(palette_batch.get("serialized_queue_byte_count", -1)),
		"consumer_source_pc": RomCutsceneBackgroundSourceTask.NMI_QUEUE_CONSUMER_PC,
	})
	_cutscene_fade_counter_history.append({
		"source_frame": source_frame,
		"source_event_id": source_event_id,
		"cutscene_id": vm.cutscene_id,
		"event_index": event_index,
		"event_cpu_address": event_pc,
		"opcode": 0xF3,
		"operand": 0x00,
		"ram_writes": receipt["ram_writes"].duplicate(true),
	})


func _record_cutscene_animation_chr_shadow(event: Dictionary) -> void:
	var producer: Variant = CUTSCENE_ANIMATION_CHR_SHADOW_PRODUCER_SCRIPT.new()
	if not producer.configure_from_project_sources():
		_route_gaps_add("ROM animation `$51` CHR-shadow source failed verification: %s" % producer.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var receipt: Dictionary = producer.build_receipt(vm.cutscene_id, event, source_frame)
	if not bool(receipt.get("ok", false)):
		_route_gaps_add("ROM animation `$51` CHR-shadow source event was rejected: %s" % String(receipt.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var event_id := String(receipt.get("source_event_id", ""))
	if not _source_ram_image.merge_executor_result(event_id, receipt):
		_route_gaps_add("ROM `$94D8` sprite CHR writes could not enter the live RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_animation_chr_shadow_history.append({
		"kind": "sprite_frame_header",
		"source_frame": source_frame,
		"animation_id": 0x51,
		"sprite_frame_cpu_address": 0xB364,
		"selector_values": receipt.get("selector_values", []).duplicate(),
		"source_event_id": event_id,
	})


func _begin_cutscene_f1_dialog_task(event: Dictionary) -> void:
	if _cutscene_f1_dialog_task != null or _cutscene_background_task != null \
			or _cutscene_eb_post_wait_task != null:
		_route_gaps_add("ROM `$F1 $02` arrived while another source queue task still owns `$0628`.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var counter_a: Dictionary = _source_ram_image.get_byte(0x004A)
	var counter_b: Dictionary = _source_ram_image.get_byte(0x004B)
	if not bool(counter_a.get("known", false)) or not bool(counter_b.get("known", false)):
		_route_gaps_add("ROM `$F1 $02` needs known live `$004A/$004B` source counters.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var queue_inputs: Dictionary = _visuals.get_eb_post_wait_clear_source_inputs()
	var queue_cursor := int(queue_inputs.get("source_queue_cursor_0628", -1))
	var task: Variant = CUTSCENE_F1_DIALOG_TASK_SCRIPT.new()
	if not task.begin(event, vm.cutscene_id, source_frame,
			Vector2i(int(counter_a.get("value", -1)), int(counter_b.get("value", -1))), queue_cursor):
		_route_gaps_add("ROM `$F1 $02` source task refused its live counter/queue inputs: %s" % task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var event_index := int(event.get("event_index", -1))
	var source_cpu_address := int(event.get("cpu_address", -1))
	if not vm.begin_external_source_task(event_index, source_cpu_address, "cutscene_f1_dialog_window_97b6"):
		_route_gaps_add("Cutscene VM refused to wait for the ROM `$97B6` dialog-window task.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_f1_dialog_task = task
	var initial_action: Dictionary = task.get_initial_action()
	if not bool(initial_action.get("ok", false)):
		_route_gaps_add("ROM `$F1 $02` could not produce its first source action: %s" % String(initial_action.get("error", task.error_message)))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_apply_f1_dialog_action(initial_action)


func _apply_f1_dialog_action(action: Dictionary) -> void:
	var status := String(action.get("status", ""))
	if status == "wait_for_inherited_queue_release":
		var expectation: Dictionary = action.get("release_receipt_expectation", {})
		var cursor := int(expectation.get("queue_cursor_before", -1))
		if not _visuals.stage_source_nmi_inherited_queue_release("f1_02", cursor,
				RomF1DialogWindowTask.NMI_CONSUMER_PC, int(action.get("event_index", -1))):
			_fail_active_f1_dialog_task("could not stage its inherited `$0628` NMI drain")
			return
	elif status in ["batch_staged_waiting_for_nmi", "task_returned"]:
		var batch: Dictionary = action.get("batch", {}).duplicate(true)
		batch["task_kind"] = "f1_02"
		if not _visuals.stage_source_nmi_packet_batch(batch, RomF1DialogWindowTask.NMI_CONSUMER_PC):
			_fail_active_f1_dialog_task("could not stage its ROM packet batch in the shared NMI queue")
			return
	else:
		_fail_active_f1_dialog_task("returned unsupported source action `%s`" % status)
		return
	_cutscene_f1_dialog_task_result = _cutscene_f1_dialog_task.get_status()
	_cutscene_f1_dialog_release_history.append({
		"source_frame": source_frame,
		"action_status": status,
		"batch_index": int(action.get("batch", {}).get("batch_index", -1)),
		"source_pc": int(action.get("source_pc", action.get("next_source_pc", -1))),
		"queue_cursor_after_staging": int(action.get("batch", {}).get("queue_cursor_after_staging", -1)),
	})
	if status == "task_returned":
		_finish_f1_dialog_task()


func _advance_cutscene_f1_dialog_task(nmi_receipt: Dictionary) -> void:
	if _cutscene_f1_dialog_task == null or nmi_receipt.is_empty():
		return
	if String(nmi_receipt.get("task_kind", "")) != "f1_02":
		_fail_active_f1_dialog_task("received an NMI release owned by another source queue task")
		return
	var release_receipt := nmi_receipt.duplicate(true)
	release_receipt["nmi_consumer_pc"] = int(nmi_receipt.get("consumer_source_pc", -1))
	var action: Dictionary = _cutscene_f1_dialog_task.advance_source_tick(source_frame, release_receipt)
	if not bool(action.get("ok", false)):
		_fail_active_f1_dialog_task("rejected the presenter NMI release: %s" % String(action.get("error", _cutscene_f1_dialog_task.error_message)))
		return
	_cutscene_f1_dialog_release_history.append({
		"source_frame": source_frame,
		"released_batch_index": int(nmi_receipt.get("batch_index", -1)),
		"nmi_sequence": int(nmi_receipt.get("nmi_sequence", -1)),
		"queue_cursor_at_nmi": int(nmi_receipt.get("queue_cursor_at_nmi", -1)),
	})
	_apply_f1_dialog_action(action)


func _finish_f1_dialog_task() -> void:
	if _cutscene_f1_dialog_task == null:
		return
	var event_index := int(_cutscene_f1_dialog_task.event_index)
	var source_cpu_address := int(_cutscene_f1_dialog_task.source_cpu_address)
	_cutscene_f1_dialog_task_result = _cutscene_f1_dialog_task.get_status()
	_cutscene_f1_dialog_task = null
	if not vm.complete_external_source_task(event_index, source_cpu_address):
		_route_gaps_add("ROM `$97B6` F1 dialog return was rejected by the cutscene VM.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _fail_active_f1_dialog_task(reason: String) -> void:
	_route_gaps_add("ROM `$F1 $02` source task %s." % reason)
	if _cutscene_f1_dialog_task != null:
		_cutscene_f1_dialog_task_result = _cutscene_f1_dialog_task.get_status()
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _begin_cutscene_background_task(event: Dictionary) -> void:
	if _cutscene_background_task != null:
		_route_gaps_add("A cutscene F9/FA command arrived before its prior background task returned.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if vm.cutscene_id == 0x56 and String(event.get("kind", "")) == "background_2" \
			and int(event.get("event_index", -1)) == 1 \
			and int(event.get("opcode", -1)) == 0xFA \
			and int(event.get("id", -1)) == 0x0F:
		_begin_cutscene_fa0f_preclear(event)
		return
	var load_receipt: Dictionary = _visuals.prepare_source_background_load(event)
	if not bool(load_receipt.get("ok", false)):
		_route_gaps_add("ROM background source load could not start: %s" % String(load_receipt.get("error", "unknown loader error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var task: Variant = CUTSCENE_BACKGROUND_TASK_SCRIPT.new()
	if not task.begin(event, source_frame, load_receipt):
		_visuals.finish_source_background_load(int(event.get("event_index", -1)))
		_route_gaps_add("ROM background source task refused the decoded loader receipt: %s" % task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if String(event.get("kind", "")) == "background_1" \
			and int(event.get("id", -1)) == 0x5E:
		var chr_producer: Variant = CUTSCENE_CHR_SHADOW_PRODUCER_SCRIPT.new()
		if not chr_producer.configure_from_project_sources():
			_visuals.finish_source_background_load(int(event.get("event_index", -1)))
			_route_gaps_add("ROM `$F9 $5E` CHR-shadow source failed verification: %s" % chr_producer.error_message)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		if not _cutscene_chr_pair_read_pending.is_empty():
			_visuals.finish_source_background_load(int(event.get("event_index", -1)))
			_route_gaps_add("ROM `$F9 $5E` selector reader overlapped a pending background source read.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		# `$A385` dispatches F9; the ROM's `$8B39` table reader and `$8B3F/$8B44`
		# stores execute on the following source scheduler pass, when the script
		# pointer is `$A386` (the ROM trace records that RAM edge at frame 7112).
		_cutscene_chr_pair_read_pending = {
			"event": event.duplicate(true),
			"load_receipt": load_receipt.duplicate(true),
			"presenter_pair": _visuals.screen.get_source_2k_chr_selectors(),
			"read_source_frame": source_frame + 1,
			"source_owner": "ROM `$8B39` background worker on next source scheduler pass",
		}
	if bool(task.uses_nmi_release_receipts):
		_begin_fa0f_background_task(task, event)
		return
	if not vm.begin_external_source_task(int(event.get("event_index", -1)),
		int(event.get("cpu_address", -1)), "cutscene_background_loader"):
		_visuals.finish_source_background_load(int(event.get("event_index", -1)))
		_route_gaps_add("Cutscene VM refused to wait for its ROM background task.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_background_task = task
	_cutscene_background_task_result = task.get_status()


func _begin_cutscene_fa0f_preclear(event: Dictionary) -> void:
	if _cutscene_fa0f_preclear_task != null or _cutscene_f1_dialog_task != null \
			or _cutscene_eb_post_wait_task != null:
		_route_gaps_add("Scene `$56` FA `$0F` preclear arrived while another source queue task still owns `$0628`.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var event_index := int(event.get("event_index", -1))
	var event_pc := int(event.get("cpu_address", -1))
	var mode_bit_receipt := {
		"ok": true,
		"kind": "rom_cutscene_fa_mode_bit_write",
		"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"source_event_id": "cutscene_56_event_%d_BFBC_fa_mode_bit" % event_index,
		"known_bit_writes": [{"address": 0x005B, "known_mask": 0x04,
			"known_value": 0x04, "source_pc": 0x881E}],
		"source_cutscene_event": {"cutscene_id": 0x56,
			"event_index": event_index, "cpu_address": event_pc,
			"opcode": 0xFA, "operand": 0x0F},
		"source_instruction": "LDA $5B; ORA #$04; STA $5B",
		"trace_state_used": false,
		"emulator_data_used": false,
	}
	if event_index != 1 or event_pc != 0xBFBC \
			or not _source_ram_image.merge_known_bits_receipt(
				String(mode_bit_receipt["source_event_id"]), mode_bit_receipt):
		_route_gaps_add("ROM FA `$0F` `$881E` mode-bit write could not enter the source RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var preclear_task: Variant = CUTSCENE_FA0F_PRECLEAR_TASK_SCRIPT.new()
	if not preclear_task.configure_from_project_sources():
		_route_gaps_add("ROM FA `$0F` preclear source failed validation: %s" % preclear_task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_fa0f_helper_selection = preclear_task.derive_helper_entry_pc(
		_source_ram_image.get_byte_bits(0x005B), _source_ram_image.get_byte(0x007B))
	if not bool(_cutscene_fa0f_helper_selection.get("ok", false)):
		_route_gaps_add("ROM `$8AF7` FA `$0F` clear-helper selector stopped: %s" % String(_cutscene_fa0f_helper_selection.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var counter_a: Dictionary = _source_ram_image.get_byte(0x004A)
	var counter_b: Dictionary = _source_ram_image.get_byte(0x004B)
	var queue_inputs: Dictionary = _visuals.get_eb_post_wait_clear_source_inputs()
	var queue_cursor := int(queue_inputs.get("source_queue_cursor_0628", -1))
	if not bool(counter_a.get("known", false)) or not bool(counter_b.get("known", false)):
		_route_gaps_add("ROM FA `$0F` preclear needs live `$004A/$004B` fade counters.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not preclear_task.begin(event, vm.cutscene_id, source_frame,
			int(_cutscene_fa0f_helper_selection.get("helper_entry_pc", -1)),
			Vector2i(int(counter_a.get("value", -1)), int(counter_b.get("value", -1))),
			queue_cursor, "rom_derived_presenter_state"):
		_route_gaps_add("ROM FA `$0F` preclear task could not start: %s" % preclear_task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not vm.begin_external_source_task(event_index, event_pc,
			"cutscene_fa_0f_helper_preclear_and_background_load"):
		_route_gaps_add("Cutscene VM refused to wait for ROM `$8AF7->$98E8` FA `$0F` preclear.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_fa0f_preclear_task = preclear_task
	_cutscene_fa0f_preclear_task_result = preclear_task.get_status()
	_cutscene_fa0f_final_row_batch.clear()
	var initial_action: Dictionary = preclear_task.get_initial_action()
	if not bool(initial_action.get("ok", false)):
		_fail_active_fa0f_preclear_task("could not produce its first `$98E8` row action: %s" % String(initial_action.get("error", preclear_task.error_message)))
		return
	_apply_fa0f_preclear_action(initial_action)


func _apply_fa0f_preclear_action(action: Dictionary) -> void:
	var status := String(action.get("status", ""))
	if status == "wait_for_inherited_queue_release":
		var expectation: Dictionary = action.get("release_receipt_expectation", {})
		var cursor := int(expectation.get("queue_cursor_before", -1))
		if not _visuals.stage_source_nmi_inherited_queue_release("fa_0f_preclear", cursor,
				RomCutsceneFa0fPreclearTask.NMI_QUEUE_CONSUMER_PC,
				int(action.get("event_index", -1))):
			var queue_state: Dictionary = _visuals.get_source_nmi_queue_state()
			if not bool(queue_state.get("pending_release", false)) \
					or int(queue_state.get("queue_cursor_0628", -1)) != cursor:
				_fail_active_fa0f_preclear_task("could not stage or adopt the pre-existing `$0628` queue drain")
				return
	elif status in ["row_staged_waiting_for_capacity_release", "task_returned"]:
		var batch: Dictionary = action.get("batch", {}).duplicate(true)
		if not _visuals.stage_source_nmi_packet_batch(batch,
				RomCutsceneFa0fPreclearTask.NMI_QUEUE_CONSUMER_PC):
			_fail_active_fa0f_preclear_task("could not stage ROM `$98E8` row %d in the shared NMI queue" % int(batch.get("row_index", -1)))
			return
		if status == "task_returned":
			_cutscene_fa0f_final_row_batch = batch.duplicate(true)
	else:
		_fail_active_fa0f_preclear_task("returned unsupported source action `%s`" % status)
		return
	_cutscene_fa0f_preclear_task_result = _cutscene_fa0f_preclear_task.get_status()
	_cutscene_fa0f_preclear_history.append({
		"source_frame": source_frame,
		"action_status": status,
		"event_index": int(action.get("event_index", -1)),
		"row_index": int(action.get("batch", {}).get("row_index", -1)),
		"queue_cursor_before": int(action.get("batch", {}).get("queue_cursor_before", action.get("release_receipt_expectation", {}).get("queue_cursor_before", -1))),
		"queue_cursor_after": int(action.get("batch", {}).get("queue_cursor_bytes", action.get("release_receipt_expectation", {}).get("queue_cursor_before", -1))),
	})


func _advance_cutscene_fa0f_preclear_task(presenter_receipt: Dictionary) -> void:
	if _cutscene_fa0f_preclear_task == null or presenter_receipt.is_empty():
		return
	var preclear_status: Dictionary = _cutscene_fa0f_preclear_task.get_status()
	var inherited_release := String(preclear_status.get("state", "")) == "waiting_for_inherited_queue_release"
	var nmi_entry_pc := int(presenter_receipt.get("consumer_source_pc", -1))
	if (inherited_release and nmi_entry_pc not in [0xA000, RomCutsceneFa0fPreclearTask.NMI_QUEUE_CONSUMER_PC]) \
			or (not inherited_release and nmi_entry_pc != RomCutsceneFa0fPreclearTask.NMI_QUEUE_CONSUMER_PC):
		_fail_active_fa0f_preclear_task("received a shared-queue NMI receipt from the wrong source consumer")
		return
	if String(presenter_receipt.get("task_kind", "")) != "fa_0f_preclear" and not inherited_release:
		_fail_active_fa0f_preclear_task("received a queue release owned by another source task after FA `$0F` began writing rows")
		return
	var actual_queue_cursor_at_nmi := int(presenter_receipt.get("queue_cursor_at_nmi", -1))
	var inherited_owner := String(presenter_receipt.get("task_kind", ""))
	var release_receipt := {
		"ok": bool(presenter_receipt.get("ok", false)),
		"event_id": "" if inherited_release else String(presenter_receipt.get("event_id", "")),
		"batch_index": -1 if inherited_release else int(presenter_receipt.get("batch_index", -1)),
		"queue_cursor_before": actual_queue_cursor_at_nmi if inherited_release else int(presenter_receipt.get("queue_cursor_before", -1)),
		"queued_bytes": actual_queue_cursor_at_nmi if inherited_release else int(presenter_receipt.get("queued_bytes", -1)),
		"committed_bytes": int(presenter_receipt.get("committed_bytes", -1)),
		"queue_cursor_after": int(presenter_receipt.get("queue_cursor_after", -1)),
		"nmi_consumer_pc": RomCutsceneFa0fPreclearTask.NMI_QUEUE_CONSUMER_PC,
		"nmi_entry_pc": nmi_entry_pc,
		"source_frame": int(presenter_receipt.get("source_frame", -1)),
		"queue_drained": bool(presenter_receipt.get("queue_drained", false)),
	}
	if not _cutscene_fa0f_final_row_batch.is_empty():
		if not _validate_fa0f_final_row_release(presenter_receipt, release_receipt):
			_fail_active_fa0f_preclear_task("final `$98E8` row did not commit before the `$8BAE` wait returned")
			return
		_cutscene_fa0f_preclear_task_result = _cutscene_fa0f_preclear_task.get_status()
		_cutscene_fa0f_preclear_history.append({
			"source_frame": source_frame,
			"action_status": "final_row_nmi_committed_and_8bae_wait_returned",
			"row_index": int(_cutscene_fa0f_final_row_batch.get("row_index", -1)),
			"queue_cursor_before": int(release_receipt.get("queue_cursor_before", -1)),
			"queue_cursor_after": int(release_receipt.get("queue_cursor_after", -1)),
			"committed_ppu_write_count": presenter_receipt.get("committed_ppu_writes", []).size(),
			"post_helper_wait": {"call_pc": 0x8BB0, "argument": 0x01,
				"saved_return_word": 0x8BB2, "resume_pc": 0x8BB3,
				"release_source": "$A03C final-row NMI receipt"},
		})
		_cutscene_fa0f_preclear_task = null
		_cutscene_fa0f_final_row_batch.clear()
		_start_fa0f_background_after_preclear()
		return
	var action: Dictionary = _cutscene_fa0f_preclear_task.advance_after_nmi_release(
		source_frame, release_receipt)
	if not bool(action.get("ok", false)):
		_fail_active_fa0f_preclear_task("rejected the `$A03C` queue release: %s" % String(action.get("error", _cutscene_fa0f_preclear_task.error_message)))
		return
	_cutscene_fa0f_preclear_task_result = _cutscene_fa0f_preclear_task.get_status()
	_cutscene_fa0f_preclear_history.append({
		"source_frame": source_frame,
		"action_status": "queue_release_accepted",
		"released_event_id": String(release_receipt.get("event_id", "")),
		"released_batch_index": int(release_receipt.get("batch_index", -1)),
		"queue_cursor_before": int(release_receipt.get("queue_cursor_before", -1)),
		"queue_cursor_after": int(release_receipt.get("queue_cursor_after", -1)),
		"nmi_sequence": int(presenter_receipt.get("nmi_sequence", -1)),
		"inherited_release_owner": inherited_owner if inherited_release else "fa_0f_preclear",
	})
	_apply_fa0f_preclear_action(action)


func _validate_fa0f_final_row_release(presenter_receipt: Dictionary,
		release_receipt: Dictionary) -> bool:
	var expected_writes: Array = _cutscene_fa0f_final_row_batch.get("ppu_writes", [])
	var actual_writes: Array = presenter_receipt.get("committed_ppu_writes", [])
	return bool(release_receipt.get("ok", false)) \
		and int(presenter_receipt.get("event_index", -1)) == 1 \
		and int(presenter_receipt.get("batch_index", -1)) == 15 \
		and String(presenter_receipt.get("event_id", "")) == String(_cutscene_fa0f_final_row_batch.get("event_id", "")) \
		and int(release_receipt.get("queue_cursor_before", -1)) == int(_cutscene_fa0f_final_row_batch.get("queue_cursor_before", -2)) \
		and int(release_receipt.get("queued_bytes", -1)) == 35 \
		and int(release_receipt.get("committed_bytes", -1)) == 35 \
		and int(release_receipt.get("queue_cursor_after", -1)) == 0 \
		and int(release_receipt.get("nmi_consumer_pc", -1)) == RomCutsceneFa0fPreclearTask.NMI_QUEUE_CONSUMER_PC \
		and actual_writes.size() == 32 and actual_writes == expected_writes


func _start_fa0f_background_after_preclear() -> void:
	var event := vm.get_active_event()
	if String(event.get("kind", "")) != "background_2" or int(event.get("event_index", -1)) != 1 \
			or int(event.get("cpu_address", -1)) != 0xBFBC:
		_route_gaps_add("FA `$0F` preclear returned at an unexpected cutscene command boundary.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var load_receipt: Dictionary = _visuals.prepare_source_background_load(event)
	if not bool(load_receipt.get("ok", false)):
		_route_gaps_add("ROM FA `$0F` background packets could not start after the checked preclear: %s" % String(load_receipt.get("error", "unknown loader error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var task: Variant = CUTSCENE_BACKGROUND_TASK_SCRIPT.new()
	if not task.begin(event, source_frame, load_receipt):
		_visuals.finish_source_background_load(int(event.get("event_index", -1)))
		_route_gaps_add("ROM FA `$0F` background task refused the post-preclear loader receipt: %s" % task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_background_task = task
	_cutscene_background_task_result = task.get_status()
	_begin_fa0f_background_task(task, event, true)


func _fail_active_fa0f_preclear_task(reason: String) -> void:
	_route_gaps_add("ROM FA `$0F` preclear %s." % reason)
	if _cutscene_fa0f_preclear_task != null:
		_cutscene_fa0f_preclear_task_result = _cutscene_fa0f_preclear_task.get_status()
	route_stage = RouteStage.SOURCE_ROUTE_GAP
	route_stage_changed.emit(_stage_name())


func _begin_fa0f_background_task(task: Variant, event: Dictionary,
		vm_wait_already_owned: bool = false) -> void:
	var initial_segment: Dictionary = task.get_initial_queue_segment()
	if initial_segment.is_empty() or not _stage_fa0f_background_segment(initial_segment, event):
		_visuals.finish_source_background_load(int(event.get("event_index", -1)))
		_route_gaps_add("ROM `$FA $0F` first queue segment could not enter the shared NMI consumer.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var must_wait_for_release := bool(initial_segment.get("must_yield_at_capacity", false))
	_cutscene_background_task_result = task.get_status()
	if not must_wait_for_release:
		var event_index := int(event.get("event_index", -1))
		if not _visuals.finish_source_background_load(event_index):
			_route_gaps_add("ROM `$FA $0F` returned without releasing its staged source loader.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		return
	if not vm_wait_already_owned and not vm.begin_external_source_task(int(event.get("event_index", -1)),
			int(event.get("cpu_address", -1)), "cutscene_fa_0f_queue_capacity"):
		_visuals.finish_source_background_load(int(event.get("event_index", -1)))
		_route_gaps_add("Cutscene VM refused the ROM `$9B28` capacity wait for `$FA $0F`.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_background_task = task


func _stage_fa0f_background_segment(segment: Dictionary, event: Dictionary) -> bool:
	if bool(segment.get("flush_existing_queue", false)):
		return _visuals.stage_source_nmi_inherited_queue_release("fa_0f",
			int(segment.get("queue_cursor_bytes", -1)),
			RomCutsceneBackgroundSourceTask.NMI_QUEUE_CONSUMER_PC,
			int(event.get("event_index", -1)))
	var staging_batch := {
		"task_kind": "fa_0f",
		"event_id": "fa_0f_event_%d" % int(event.get("event_index", -1)),
		"event_index": int(event.get("event_index", -1)),
		"batch_index": int(segment.get("segment_index", -1)),
		"queue_cursor_before": int(segment.get("queue_cursor_before", -1)),
		"serialized_queue_byte_count": int(segment.get("serialized_queue_byte_count", -1)),
		"queue_cursor_bytes": int(segment.get("queue_cursor_bytes", -1)),
		"packets": segment.get("packets", []).duplicate(true),
		"ppu_writes": segment.get("ppu_writes", []).duplicate(true),
		"source_batch": segment.duplicate(true),
	}
	return _visuals.stage_source_nmi_packet_batch(staging_batch,
		RomCutsceneBackgroundSourceTask.NMI_QUEUE_CONSUMER_PC)


func _consume_pending_cutscene_chr_pair_read() -> bool:
	if _cutscene_chr_pair_read_pending.is_empty():
		return true
	var read_source_frame := int(_cutscene_chr_pair_read_pending.get("read_source_frame", -1))
	if source_frame < read_source_frame:
		return true
	if source_frame != read_source_frame:
		_route_gaps_add("ROM `$8B39` CHR table read missed its source scheduler pass (%d expected, %d observed)." % [
			read_source_frame, source_frame])
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var producer: Variant = CUTSCENE_CHR_SHADOW_PRODUCER_SCRIPT.new()
	if not producer.configure_from_project_sources():
		_route_gaps_add("ROM `$F9 $5E` CHR-shadow source failed verification: %s" % producer.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var pair_receipt: Dictionary = producer.build_background_pair_receipt(
		_cutscene_chr_pair_read_pending.get("event", {}), source_frame,
		_cutscene_chr_pair_read_pending.get("load_receipt", {}),
		_cutscene_chr_pair_read_pending.get("presenter_pair", []))
	if not bool(pair_receipt.get("ok", false)):
		_route_gaps_add("ROM `$F9 $5E` table reader stopped: %s" % String(pair_receipt.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var pair_event_id := String(pair_receipt.get("source_event_id", ""))
	if not _source_ram_image.merge_executor_result(pair_event_id, pair_receipt):
		_route_gaps_add("ROM `$8B39->$8B44` CHR pair could not enter the source RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var event_index := int(pair_receipt.get("event_index", -1))
	_cutscene_chr_selector_pair_receipts[event_index] = pair_receipt.duplicate(true)
	_cutscene_chr_shadow_history.append({
		"kind": "source_table_pair",
		"source_frame": source_frame,
		"background_id": 0x5E,
		"selector_pair": pair_receipt.get("selector_pair", []).duplicate(),
		"source_event_id": pair_event_id,
		"source_owner": String(_cutscene_chr_pair_read_pending.get("source_owner", "")),
	})
	_cutscene_chr_pair_read_pending.clear()
	return true


func _advance_cutscene_background_task(nmi_receipt: Dictionary = {}) -> void:
	var task: Variant = _cutscene_background_task
	if task == null:
		return
	if not _consume_pending_cutscene_chr_pair_read():
		return
	if bool(task.uses_nmi_release_receipts):
		_advance_fa0f_background_task(nmi_receipt)
		return
	var step: Dictionary = task.advance_source_tick(source_frame)
	if not bool(step.get("ok", false)):
		_route_gaps_add("ROM background task stopped: %s" % String(step.get("error", "unknown source-task error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_background_task_result = task.get_status()
	var status := String(step.get("status", ""))
	var current_event_index := int(task.event_index)
	if status in ["packet_batch_released", "task_returned"]:
		var batch_index := int(step.get("batch_index", -1))
		if not _visuals.apply_source_background_batch(current_event_index, batch_index):
			_route_gaps_add("ROM background packet batch %d could not commit to the PPU presenter." % batch_index)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_background_batch_history.append({
			"event_index": current_event_index,
			"source_cpu_address": int(task.source_cpu_address),
			"background_id": int(task.background_id),
			"batch_index": batch_index,
			"source_frame": source_frame,
			"release_count": int(step.get("release_count", -1)),
			"release_count_required": int(step.get("release_count_required", -1)),
		})
		if status == "packet_batch_released":
			return
	if status != "task_returned":
		_route_gaps_add("ROM background task emitted an unsupported source status: %s" % status)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var source_cpu_address := int(task.source_cpu_address)
	if not _visuals.finish_source_background_load(current_event_index):
		_route_gaps_add("ROM background source task returned without a staged presenter load.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_background_task = null
	var pair_receipt: Dictionary = _cutscene_chr_selector_pair_receipts.get(
		current_event_index, {}).duplicate(true)
	if not _queue_cutscene_external_task_return(current_event_index, source_cpu_address,
			"cutscene_background", task.get_status(), pair_receipt):
		_route_gaps_add("Cutscene VM could not schedule its completed background return at the next source scheduler boundary.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _advance_fa0f_background_task(presenter_receipt: Dictionary) -> void:
	if _cutscene_background_task == null or presenter_receipt.is_empty():
		return
	if String(presenter_receipt.get("task_kind", "")) != "fa_0f":
		_fail_active_fa0f_task("received an NMI release owned by another source queue task")
		return
	var source_receipt := _build_fa0f_nmi_release_receipt(presenter_receipt)
	var step: Dictionary = _cutscene_background_task.advance_after_nmi_release(source_receipt)
	if not bool(step.get("ok", false)):
		_fail_active_fa0f_task("rejected the presenter NMI release: %s" % String(step.get("error", "source receipt mismatch")))
		return
	var next_segment: Dictionary = step.get("next_queue_segment", {})
	if not next_segment.is_empty():
		var event := vm.get_active_event()
		if not _stage_fa0f_background_segment(next_segment, event):
			_fail_active_fa0f_task("could not stage the next ROM `$9B28` packet segment")
			return
	_cutscene_background_task_result = _cutscene_background_task.get_status()
	_cutscene_background_batch_history.append({
		"event_index": int(step.get("event_index", -1)),
		"source_cpu_address": int(step.get("source_cpu_address", -1)),
		"background_id": int(step.get("background_id", -1)),
		"batch_index": int(step.get("released_segment", {}).get("segment_index", -1)),
		"source_frame": source_frame,
		"nmi_sequence": int(presenter_receipt.get("nmi_sequence", -1)),
		"queued_bytes": int(presenter_receipt.get("queued_bytes", -1)),
		"committed_write_count": presenter_receipt.get("committed_ppu_writes", []).size(),
		"status": String(step.get("status", "")),
	})
	if String(step.get("status", "")) == "task_returned":
		_finish_fa0f_background_task()


func _build_fa0f_nmi_release_receipt(presenter_receipt: Dictionary) -> Dictionary:
	var staged_batch: Dictionary = presenter_receipt.get("source_batch", {}).duplicate(true)
	var segment: Dictionary = staged_batch.get("source_batch", {}).duplicate(true)
	if segment.is_empty():
		return {
			"ok": bool(presenter_receipt.get("ok", false)),
			"event_id": String(presenter_receipt.get("event_id", "")),
			"batch_index": int(presenter_receipt.get("batch_index", -1)),
			"queue_cursor_before": int(presenter_receipt.get("queue_cursor_at_nmi", -1)),
			"queued_bytes": int(presenter_receipt.get("queue_cursor_at_nmi", -1)),
			"committed_bytes": int(presenter_receipt.get("queue_cursor_at_nmi", -1)),
			"queue_cursor_after": int(presenter_receipt.get("queue_cursor_after", -1)),
			"nmi_consumer_pc": int(presenter_receipt.get("consumer_source_pc", -1)),
			"source_frame": int(presenter_receipt.get("source_frame", -1)),
		}
	var source_yield := {
		"writer_pc": int(segment.get("queue_writer_pc", -1)),
		"yield_site_pc": int(segment.get("yield_site_pc", -1)),
		"yield_call_pc": int(segment.get("yield_call_pc", -1)),
		"saved_return_word": int(segment.get("yield_saved_return_word", -1)),
		"resume_pc": int(segment.get("yield_resume_pc", -1)),
		"caller_saved_return_word": int(segment.get("caller_saved_return_word", -1)),
		"caller_resume_pc": int(segment.get("caller_resume_pc", -1)),
	}
	return {
		"ok": bool(presenter_receipt.get("ok", false)),
		"kind": "rom_cutscene_background_nmi_queue_release",
		"source_rom_sha256": RomCutsceneBackgroundSourceTask.SOURCE_ROM_SHA256,
		"event_index": int(presenter_receipt.get("event_index", -1)),
		"source_cpu_address": int(vm.get_active_event().get("cpu_address", -1)),
		"background_id": 0x0F,
		"segment_index": int(segment.get("segment_index", -1)),
		"segment": segment,
		"queue_cursor_before": int(segment.get("queue_cursor_bytes", -1)),
		"queue_cursor_after": int(presenter_receipt.get("queue_cursor_after", -1)),
		"queue_drained": bool(presenter_receipt.get("queue_drained", false)),
		"consumer_source_pc": int(presenter_receipt.get("consumer_source_pc", -1)),
		"serialized_queue_byte_count": int(segment.get("serialized_queue_byte_count", -1)),
		"committed_ppu_writes": presenter_receipt.get("committed_ppu_writes", []).duplicate(true),
		"nmi_sequence": int(presenter_receipt.get("nmi_sequence", -1)),
		"source_frame": int(presenter_receipt.get("source_frame", -1)),
		"source_yield": source_yield,
	}


func _finish_fa0f_background_task() -> void:
	if _cutscene_background_task == null:
		return
	var event_index := int(_cutscene_background_task.event_index)
	var source_cpu_address := int(_cutscene_background_task.source_cpu_address)
	_cutscene_background_task_result = _cutscene_background_task.get_status()
	if not _visuals.finish_source_background_load(event_index):
		_fail_active_fa0f_task("returned without releasing its staged source loader")
		return
	var completed_task_status := _cutscene_background_task_result.duplicate(true)
	_cutscene_background_task = null
	if not _queue_cutscene_external_task_return(event_index, source_cpu_address,
			"fa_0f_background", completed_task_status):
		_route_gaps_add("ROM `$8F47` FA `$0F` return could not enter the next source scheduler boundary.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _fail_active_fa0f_task(reason: String) -> void:
	_route_gaps_add("ROM `$FA $0F` source task %s." % reason)
	if _cutscene_background_task != null:
		_cutscene_background_task_result = _cutscene_background_task.get_status()
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _begin_cutscene_eb_post_wait_task() -> void:
	var event: Dictionary = vm.get_active_event()
	var clear_inputs: Dictionary = _visuals.get_eb_post_wait_clear_source_inputs()
	var task: Variant = CUTSCENE_EB_POST_WAIT_TASK_SCRIPT.new()
	if not task.begin(event, source_frame, vm.get_rom_modeled_fade_counters(),
			int(clear_inputs.get("clear_origin_address", -1)),
			int(clear_inputs.get("source_queue_cursor_0628", -1))):
		_route_gaps_add("ROM `$88B1` EB post-wait task could not start: %s" % task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not vm.begin_external_input_completion_task(
			int(event.get("event_index", -1)), int(event.get("cpu_address", -1)),
			NES_A_EDGE, "cutscene_eb_post_wait_88b1"):
		_route_gaps_add("Cutscene VM refused the fresh-A completion at the ROM EB handler boundary.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_eb_post_wait_task = task
	var initial_batch: Dictionary = task.get_initial_packet_batch()
	if not _visuals.queue_source_eb_clear_batch(int(event.get("event_index", -1)), initial_batch):
		_route_gaps_add("ROM `$98E8` initial zero-fill packet batch could not enter the shared `$05E8` queue.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_eb_post_wait_task_result = task.get_status()
	_cutscene_eb_post_wait_batch_history.append({
		"event_index": int(event.get("event_index", -1)),
		"source_cpu_address": int(event.get("cpu_address", -1)),
		"batch_index": int(initial_batch.get("batch_index", -1)),
		"source_frame": source_frame,
		"queued_before_first_yield": true,
		"queue_cursor_after": int(initial_batch.get("queue_cursor_bytes", -1)),
	})


func _advance_cutscene_eb_post_wait_task() -> void:
	var task: Variant = _cutscene_eb_post_wait_task
	if task == null:
		return
	var step: Dictionary = task.advance_source_tick(source_frame)
	if not bool(step.get("ok", false)):
		_route_gaps_add("ROM `$9B28` EB post-wait task stopped: %s" % String(step.get("error", "unknown source-task error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var batch := {
		"batch_index": int(step.get("batch_index", -1)),
		"rows": step.get("rows", []),
		"queue_cursor_bytes": int(step.get("queue_cursor_bytes", -1)),
	}
	if not _visuals.queue_source_eb_clear_batch(int(task.event_index), batch):
		_route_gaps_add("ROM `$9B28` EB post-wait packet batch %d could not enter the shared `$05E8` queue." % int(batch["batch_index"]))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_eb_post_wait_task_result = task.get_status()
	_cutscene_eb_post_wait_batch_history.append({
		"event_index": int(task.event_index),
		"source_cpu_address": int(task.source_cpu_address),
		"batch_index": int(step.get("batch_index", -1)),
		"source_frame": source_frame,
		"capacity_release_count": int(step.get("capacity_release_count", -1)),
		"capacity_release_count_required": int(step.get("capacity_release_count_required", -1)),
		"queue_cursor_after": int(step.get("queue_cursor_bytes", -1)),
	})
	if String(step.get("status", "")) != "task_returned":
		return
	var event_index := int(task.event_index)
	var source_cpu_address := int(task.source_cpu_address)
	_cutscene_eb_post_wait_task = null
	if not vm.complete_external_source_task(event_index, source_cpu_address):
		_route_gaps_add("ROM `$88B1` post-EB task return was rejected by the cutscene VM.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _queue_cutscene_external_task_return(event_index: int, source_cpu_address: int,
		task_kind: String, task_status: Dictionary = {},
		chr_pair_receipt: Dictionary = {}) -> bool:
	if not _cutscene_external_task_return_pending.is_empty() \
			or vm.state != KickoffCutsceneCommandVm.RunState.WAITING_SOURCE_TASK \
			or vm.current_event_index != event_index \
			or vm.current_source_address != source_cpu_address \
			or event_index < 0 or source_cpu_address < 0 or task_kind.is_empty():
		return false
	_cutscene_external_task_return_pending = {
		"state": "awaiting_next_source_scheduler_tick",
		"task_kind": task_kind,
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"task_return_source_frame": source_frame,
		"resume_source_frame": source_frame + 1,
		"task_status": task_status.duplicate(true),
		"chr_pair_receipt": chr_pair_receipt.duplicate(true),
	}
	_cutscene_external_task_return_history.append({
		"state": "task_returned_waiting_for_source_scheduler",
		"task_kind": task_kind,
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"task_return_source_frame": source_frame,
		"resume_source_frame": source_frame + 1,
	})
	return true


func _resume_cutscene_external_task_return() -> void:
	var pending := _cutscene_external_task_return_pending.duplicate(true)
	if source_frame < int(pending.get("resume_source_frame", -1)):
		return
	var pair_receipt: Dictionary = pending.get("chr_pair_receipt", {})
	if not pair_receipt.is_empty():
		var chr_producer: Variant = CUTSCENE_CHR_SHADOW_PRODUCER_SCRIPT.new()
		if not chr_producer.configure_from_project_sources():
			_route_gaps_add("ROM `$F9 $5E` NMI shadow-copy source failed verification: %s" % chr_producer.error_message)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var copy_receipt: Dictionary = chr_producer.build_nmi_shadow_copy_receipt(
			pair_receipt, pending.get("task_status", {}), source_frame,
			_visuals.screen.get_source_2k_chr_selectors())
		if not bool(copy_receipt.get("ok", false)):
			_route_gaps_add("ROM `$8CA7->$8CAD` CHR-shadow copy stopped: %s" % String(copy_receipt.get("error", "source state rejected")))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var copy_event_id := String(copy_receipt.get("source_event_id", ""))
		if not _source_ram_image.merge_executor_result(copy_event_id, copy_receipt):
			_route_gaps_add("ROM NMI `$008E/$008F` CHR-shadow writes could not enter the source RAM ledger: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_chr_shadow_history.append({
			"kind": "nmi_shadow_copy",
			"source_frame": source_frame,
			"background_id": 0x5E,
			"selector_pair": pair_receipt.get("selector_pair", []).duplicate(),
			"source_event_id": copy_event_id,
		})
		_cutscene_chr_selector_pair_receipts.erase(int(pending.get("event_index", -1)))
	var event_index := int(pending.get("event_index", -1))
	var source_cpu_address := int(pending.get("source_cpu_address", -1))
	_cutscene_external_task_return_pending.clear()
	if not vm.complete_external_source_task(event_index, source_cpu_address):
		_route_gaps_add("Cutscene VM rejected task `%s` return at the next source scheduler boundary (state=%s event=%d PC=`$%04X`, error=%s)." % [
			String(pending.get("task_kind", "")),
			KickoffCutsceneCommandVm.RunState.keys()[vm.state].to_lower(),
			vm.current_event_index, vm.current_source_address, vm.error_message,
		])
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_external_task_return_history.append({
		"state": "source_task_return_resumed",
		"task_kind": String(pending.get("task_kind", "")),
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"task_return_source_frame": int(pending.get("task_return_source_frame", -1)),
		"resume_source_frame": source_frame,
	})


func _record_e8_preset_source_writes(event: Dictionary) -> void:
	var arguments: Array = event.get("arguments", [])
	if arguments.size() != 1 or int(arguments[0]) != 0x01:
		return
	var model: Variant = E8_PRESET_MODEL_SCRIPT.new()
	if not bool(model.configure_from_e8(int(arguments[0]), source_frame)):
		_route_gaps_add("ROM E8 `$01` preset could not be loaded: %s" % String(model.last_error))
		return
	var event_id := "kickoff_cutscene_%02d_event_%03d_e8_01" % [vm.cutscene_id, int(event.get("event_index", -1))]
	var wait_latch: Dictionary = _source_ram_image.get_byte(0x0078)
	var receipt: Dictionary = model.e8_source_ram_write_receipt(event_id, wait_latch)
	if not bool(receipt.get("ok", false)):
		_route_gaps_add("ROM E8 `$01` RAM writes could not be derived: %s" % String(receipt.get("error", "unknown source error")))
		return
	if not _source_ram_image.merge_executor_result(event_id, receipt):
		_route_gaps_add("ROM E8 `$01` RAM receipt was rejected: %s" % _source_ram_image.error_message)
		return
	_source_e8_preset_status.append({"event_id": event_id, "source_frame": source_frame,
		"script_cpu_address": int(event.get("cpu_address", -1)), "operand": 0x01,
		"source_ram_writes": receipt.get("ram_writes", []).size(),
		"preset_file_offset": receipt.get("preset_file_offset", ""),
		"preset_sha256": receipt.get("preset_sha256", "")})


func _on_rom_sound_queue_write_requested(event: RefCounted) -> void:
	if event == null:
		return
	var event_identity := String(event.get("event_identity"))
	var runtime_consumer := "GameplayRomCueAudioPresenter.apply_rom_sound_command"
	var applied := false
	if String(event.get("event_origin")) == "rom_cbf1_queue_insert":
		applied = bool(cue_audio.call("apply_rom_cbf1_queue_insert", event))
		runtime_consumer = "GameplayRomCueAudioPresenter.apply_rom_cbf1_queue_insert"
	elif String(event.get("event_origin")) == "rom_daaa_cbf1_queue_insert":
		applied = bool(cue_audio.call("apply_rom_fresh_daaa_queue_insert", event))
		runtime_consumer = "GameplayRomCueAudioPresenter.apply_rom_fresh_daaa_queue_insert"
	else:
		applied = cue_audio.apply_rom_sound_command(int(event.get("queue_id")),
			int(event.get("route_frame")))
	for index in range(_sound_queue_event_history.size() - 1, -1, -1):
		var event_row: Dictionary = _sound_queue_event_history[index]
		if String(event_row.get("event_identity", "")) == event_identity:
			event_row["applied"] = applied
			event_row["runtime_consumer"] = runtime_consumer
			_sound_queue_event_history[index] = event_row
			break


func _emit_cbf1_audio_events_from_source_result(source_result: Dictionary) -> void:
	if not bool(source_result.get("ok", false)):
		return
	var candidates: Array[Dictionary] = []
	_collect_cbf1_helper_results(source_result, candidates, 0)
	for helper_result in candidates:
		if String(helper_result.get("status", "")) != "queued_sound_request":
			continue
		var queue_event: RefCounted = SOUND_QUEUE_EVENT_SCRIPT.new()
		if not bool(queue_event.call("populate_from_cbf1_queue_insert", helper_result, source_frame)):
			_route_gaps_add("Accepted ROM `$CBFE` queue insertion failed its typed audio provenance checks.")
			continue
		var event_identity := String(queue_event.get("event_identity"))
		var duplicate_event := false
		for history_variant in _sound_queue_event_history:
			if history_variant is Dictionary \
					and String((history_variant as Dictionary).get("event_identity", "")) == event_identity:
				duplicate_event = true
				break
		if duplicate_event:
			continue
		var event_data: Dictionary = queue_event.call("to_dictionary")
		event_data["source_role"] = "slot09_rom_cbf1_queue"
		_sound_queue_event_history.append(event_data)
		rom_sound_queue_write_requested.emit(queue_event)


func _collect_cbf1_helper_results(source_result: Dictionary,
		candidates: Array[Dictionary], depth: int) -> void:
	if depth > 4:
		return
	var helper_variant: Variant = source_result.get("cbf1_helper_result", {})
	if helper_variant is Dictionary:
		var candidate: Dictionary = helper_variant.duplicate(true)
		var root_input_counter := int(source_result.get("input_ram_052e", -1))
		var root_ram_variant: Variant = source_result.get("ram_image", PackedByteArray())
		if root_input_counter >= 0 and root_ram_variant is PackedByteArray \
				and (root_ram_variant as PackedByteArray).size() == 0x800:
			var root_ram: PackedByteArray = root_ram_variant
			candidate["root_input_ram_052e"] = root_input_counter
			candidate["root_input_ram_052f"] = int(root_ram[0x052F])
			candidate["root_output_ram_052e"] = int(root_ram[0x052E])
			candidate["root_source_ram_0530"] = int(root_ram[0x0530])
			candidate["root_source_ram_0531"] = int(root_ram[0x0531])
			candidate["root_source_ram_063f"] = int(root_ram[0x063F])
			candidate["root_scenario_id"] = int(root_ram[0x0518])
		candidates.append(candidate)
	for key in ["slot09_ebd7_root_zero_result", "next_task_dispatch",
			"slot05_resume_result", "slot09_resume_result", "slot09_root_zero_result"]:
		var child_variant: Variant = source_result.get(key, {})
		if child_variant is Dictionary:
			_collect_cbf1_helper_results(child_variant, candidates, depth + 1)


func _on_cutscene_done(cutscene_id: int, completion_kind: String = "natural") -> void:
	if cutscene_id in [1, 2] and _cutscene_select_wait_task != null \
			and _cutscene_select_wait_task.is_waiting():
		# The ROM caller runs its own $82B5 waiter alongside the cutscene task.
		# The caller returns only after its source pointer or Select predicate wins.
		return
	_complete_cutscene_return(cutscene_id, completion_kind)


func _complete_cutscene_return(cutscene_id: int, completion_kind: String) -> void:
	if completion_kind != "select":
		_cutscene_cleanup_fade_counters = vm.get_rom_modeled_fade_counters()
	_last_cutscene_completion_kind = completion_kind
	_last_completed_cutscene_id = cutscene_id
	cutscene_return_requested.emit(cutscene_id, completion_kind)
	if cutscene_id == 0x56:
		_begin_scene56_natural_return(completion_kind)
		return
	if cutscene_id in [1, 2]:
		# Both ROM caller sites use the shared $82B5->$82C6->$82DF path. ID 1
		# returns to $80F1 after cleanup; ID 2 returns to $815D. Hold at the
		# shared helper until its live effects are executed.
		_cutscene_wait_cleanup_result.clear()
		var cleanup: Variant = FRESH_MATCH_HANDOFF_EXECUTOR_SCRIPT.new()
		if not cleanup.configure_from_project_sources():
			_route_gaps_add("Cutscene return cleanup source could not be verified: %s" % cleanup.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_wait_cleanup_result = cleanup.plan_cutscene_wait_cleanup(cutscene_id, completion_kind)
		if not bool(_cutscene_wait_cleanup_result.get("ok", false)) \
				or String(_cutscene_wait_cleanup_result.get("status", "")) != "blocked_on_helper" \
				or String(_cutscene_wait_cleanup_result.get("pending_helper_id", "")) != "cutscene_cleanup_9ba0":
			_route_gaps_add("Cutscene return cleanup did not stop at its expected ROM `$82DF->$9BA0` boundary.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var audio_stop: Dictionary = _cutscene_wait_cleanup_result.get("audio_stop_request", {})
		if int(audio_stop.get("source_pc", -1)) == 0x82DC \
				and int(audio_stop.get("queue_address", -1)) == 0x0700 \
				and int(audio_stop.get("value", -1)) == 0x01:
			var audio_applied := cue_audio.apply_rom_sound_command(0x01, source_frame)
			audio_stop["applied"] = audio_applied
			audio_stop["runtime_consumer"] = "GameplayRomCueAudioPresenter.apply_rom_sound_command"
			_cutscene_wait_cleanup_result["audio_stop_request"] = audio_stop
			_sound_queue_event_history.append({
				"source_pc": 0x82DC,
				"address": 0x0700,
				"queue_id": 0x01,
				"route_frame": source_frame,
				"rom_sha256": _cutscene_wait_cleanup_result.get("rom_sha256", ""),
				"effect": "stop_rom_audio",
				"applied": audio_applied,
			})
			if not audio_applied:
				_route_gaps_add("ROM `$82DC` audio stop could not be applied by the cue presenter.")
		_begin_cutscene_cleanup_fade(cutscene_id)
	elif cutscene_id == 0x44:
		_install_meeting_menu()


func _begin_scene56_natural_return(completion_kind: String) -> void:
	if completion_kind != "natural" or vm.state != KickoffCutsceneCommandVm.RunState.FINISHED:
		_route_gaps_add("ROM scene `$56` must reach its natural `$FF` terminator before the `$82A9` caller return.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var caller_a009: Dictionary = _fresh_match_caller_tail_result.get("a009_entry", {})
	var return_executor: Variant = PREMATCH_MENU_RETURN_SCRIPT.new()
	if not return_executor.configure_from_project_sources():
		_route_gaps_add("ROM scene `$56` return sources failed verification: %s" % return_executor.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var return_receipt: Dictionary = return_executor.resolve_after_scene56(
		3, vm, caller_a009, _source_ram_image)
	if not bool(return_receipt.get("ok", false)):
		_route_gaps_add("ROM scene `$56` could not resolve the live `$8145` return: %s" % String(return_receipt.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_prematch_menu_return_result = return_receipt.duplicate(true)
	_scene56_natural_wait_task = CUTSCENE_NATURAL_WAIT_TASK_SCRIPT.new()
	if not _scene56_natural_wait_task.configure_from_project_sources() \
			or not _scene56_natural_wait_task.begin():
		_route_gaps_add("ROM `$82A9` natural pointer waiter failed source validation: %s" % _scene56_natural_wait_task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_prematch_menu_return_result["natural_wait"] = {
		"source_pc": 0x82A9,
		"wait_kind": "ROM `$9FA8(A=1)` yield followed by `$004D/$004E` pointer poll",
		"vm_natural_terminator_seen": true,
		"background_task_returned": _cutscene_background_task == null,
		"wait_task_source": _scene56_natural_wait_task.get_status(),
		"frame_timing_verified": false,
	}
	_cutscene_wait_cleanup_result = {
		"ok": true,
		"status": "waiting_for_scene56_natural_return_cleanup",
		"cutscene_id": 0x56,
		"completion_kind": completion_kind,
		"caller_return_pc_after_helper": 0x8145,
		"pending_source_pc": 0xA715,
		"pending_helper_id": "cutscene_cleanup_9ba0",
		"source_return": return_receipt.duplicate(true),
		"audio_stop_request": {},
	}
	# The source task polls the live VM pointer on each yielded route tick.
	route_stage = RouteStage.CUTSCENE_56_NATURAL_WAIT
	route_stage_changed.emit(_stage_name())


func _advance_scene56_natural_wait() -> void:
	if vm.state != KickoffCutsceneCommandVm.RunState.FINISHED \
			or _cutscene_background_task != null or _cutscene_eb_post_wait_task != null:
		_route_gaps_add("ROM `$82A9` return requires scene `$56` to terminate and its background tasks to return before pointer polling.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if _scene56_natural_wait_task == null:
		_route_gaps_add("ROM `$82A9` pointer waiter was not initialized from its source bytes.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	# `$FF` has completed the ROM-derived command stream; this exposes the
	# source's zero-terminated script pointer without importing FCEUX RAM.
	var live_script_pointer := 0 if vm.state == KickoffCutsceneCommandVm.RunState.FINISHED \
		else vm.current_source_address
	var wait_step: Dictionary = _scene56_natural_wait_task.advance_source_tick(live_script_pointer)
	if not bool(wait_step.get("ok", false)):
		_route_gaps_add("ROM `$82A9` pointer waiter stopped: %s" % String(wait_step.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if String(wait_step.get("status", "")) == "yielded":
		_prematch_menu_return_result["natural_wait"]["last_wait_step"] = wait_step.duplicate(true)
		return
	_prematch_menu_return_result["natural_wait"].merge({
		"status": "returned_after_source_pointer_reached_zero",
		"return_source_frame": source_frame,
		"iterations_modelled": int(wait_step.get("yield_count", -1)),
		"last_wait_step": wait_step.duplicate(true),
	}, true)
	_cutscene_wait_cleanup_result["status"] = "natural_wait_returned_to_A715"
	_begin_cutscene_cleanup_fade(0x56)


func _finish_scene56_cleanup_return() -> void:
	if not bool(_prematch_menu_return_result.get("ok", false)) \
			or String(_cutscene_cleanup_clear_result.get("status", "")) != "returned_from_9ba0":
		_route_gaps_add("ROM `$A715->$9BA0->$A718` did not return through the verified scene-$56 cleanup path.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_prematch_menu_return_result["cleanup_return"] = {
		"source_pc_path": [0xA715, 0x9BA0, 0xA718, 0x8145],
		"cutscene_cleanup_clear": _cutscene_cleanup_clear_result.duplicate(true),
		"physical_stack_and_cycles_verified": false,
	}
	_prematch_menu_return_result["status"] = "returned_to_8145_ready_for_id2_dispatch"
	# The ROM caller's `$83DC[$26]` selects ID `$02` only after `$8145` resumes.
	_start_cutscene(2)


func _advance_cutscene_select_wait(cutscene_id: int) -> void:
	var select_edge := NES_SELECT_HELD if _pending_select_edge else 0
	var result: Dictionary = _cutscene_select_wait_task.resume(vm.is_running(), select_edge)
	_pending_select_edge = false
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$82B5` waiter rejected its live source state: %s" % String(result.get("status", "unknown")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if String(result.get("status", "")) == "yielded":
		return
	var completion_kind := String(result.get("completion_kind", ""))
	if completion_kind == "select" and vm.is_running():
		_cutscene_cleanup_fade_counters = vm.get_rom_modeled_fade_counters()
		vm.stop()
	_complete_cutscene_return(cutscene_id, completion_kind)


func _begin_cutscene_cleanup_fade(cutscene_id: int) -> void:
	var fade_task: Variant = CUTSCENE_CLEANUP_FADE_TASK_SCRIPT.new()
	if not fade_task.configure_from_project_sources():
		_route_gaps_add("ROM `$99F0` cleanup fade source could not be verified: %s" % fade_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var counters := _cutscene_cleanup_fade_counters
	var base_palette: PackedByteArray = _visuals.get_cleanup_fade_base_palette_bytes()
	if not fade_task.begin(counters.x, counters.y, base_palette):
		_route_gaps_add("ROM `$99F0` cleanup fade rejected the live VM/palette state: %s" % fade_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_cleanup_fade_task = fade_task
	route_stage = RouteStage.CUTSCENE_CLEANUP_FADE
	_advance_cutscene_cleanup_fade()
	route_stage_changed.emit(_stage_name())


func _consume_pending_cleanup_fade_palette_packet() -> bool:
	if _cutscene_cleanup_fade_pending_palette_packet.is_empty():
		return true
	var packet_source_frame := _cutscene_cleanup_fade_pending_source_frame
	var executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_route_gaps_add("ROM `$A000` cleanup-fade packet consumer sources failed verification: %s" % String(executor.error_message))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var result: Dictionary = executor.execute_cleanup_fade_palette_packet(
		_cutscene_cleanup_fade_pending_palette_packet)
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$A00A-$A05A` cleanup-fade packet consumer stopped: %s" % String(result.get("error", "unknown source error")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var ppu_bus_events: Variant = result.get("ppu_bus_events", null)
	if not ppu_bus_events is Array:
		_route_gaps_add("ROM `$A000` cleanup-fade packet receipt has no ordered PPU bus events.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var consumed_packet := PackedByteArray([0x20, 0x00, 0x3F])
	for event_variant in ppu_bus_events:
		if event_variant is Dictionary and int(event_variant.get("address", -1)) == 0x2007:
			consumed_packet.append(int(event_variant.get("value", -1)))
	if consumed_packet != _cutscene_cleanup_fade_pending_palette_packet:
		_route_gaps_add("ROM `$A000` `$2007` output differs from its pending `$99F0->$9A71` packet.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var event_id := "cutscene_cleanup_palette_packet_consumer_%d" % packet_source_frame
	if not _source_ram_image.merge_executor_result(event_id, result):
		_route_gaps_add("ROM `$A04A` queue-clear write could not join the source RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return false
	if not _visuals.queue_rom_cleanup_fade_palette_packet(consumed_packet):
		_route_gaps_add("ROM `$A000` consumed the fade packet, but the live palette presenter rejected its output.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return false
	var receipt := {
		"event_id": event_id,
		"producer_source_frame": packet_source_frame,
		"consumer_source_frame": source_frame,
		"consumer_entry_pc": 0xA00A,
		"queue_clear_pc": 0xA04A,
		"queue_clear_address": 0x0628,
		"queue_clear_value": int(result.get("ram_after_0628", -1)),
		"payload_writes": 32,
		"packet_matches_rom_ppu_output": true,
		"surrounding_nmi_executed": false,
	}
	_cutscene_cleanup_fade_packet_history.append(receipt)
	_cutscene_wait_cleanup_result["last_palette_packet_consumer"] = receipt.duplicate(true)
	_cutscene_cleanup_fade_pending_palette_packet.clear()
	_cutscene_cleanup_fade_pending_source_frame = -1
	return true


func _advance_cutscene_cleanup_fade() -> void:
	if _cutscene_cleanup_fade_task == null:
		_route_gaps_add("ROM `$99F0` cleanup fade has no configured live task.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var counters_before := Vector2i(
		int(_cutscene_cleanup_fade_task.counter_a),
		int(_cutscene_cleanup_fade_task.counter_b))
	var step: Dictionary = _cutscene_cleanup_fade_task.advance_source_tick(source_frame)
	_cutscene_wait_cleanup_result["fade_helper_result"] = _cutscene_cleanup_fade_task.get_status()
	if not bool(step.get("ok", false)):
		_route_gaps_add("ROM `$99F0` cleanup fade stopped: %s (step=%s; task=%s)" % [
			String(step.get("error", step.get("status", "unknown error"))),
			JSON.stringify(step), JSON.stringify(_cutscene_cleanup_fade_task.get_status())])
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var counters_after := Vector2i(
		int(_cutscene_cleanup_fade_task.counter_a),
		int(_cutscene_cleanup_fade_task.counter_b))
	var cleanup_fade_counter_writes: Array[Dictionary] = []
	for cleanup_fade_counter_index in 2:
		var cleanup_fade_counter_address := 0x004A + cleanup_fade_counter_index
		var prior_cleanup_fade_counter: Dictionary = _source_ram_image.get_byte(cleanup_fade_counter_address)
		var cleanup_fade_before_value := counters_before.x if cleanup_fade_counter_index == 0 else counters_before.y
		var cleanup_fade_after_value := counters_after.x if cleanup_fade_counter_index == 0 else counters_after.y
		if not bool(prior_cleanup_fade_counter.get("known", false)) \
				or int(prior_cleanup_fade_counter.get("value", -1)) != cleanup_fade_before_value:
			_route_gaps_add("ROM `$99F0` pre-step counter `$%04X` differs from the live source RAM ledger." % cleanup_fade_counter_address)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if cleanup_fade_after_value != cleanup_fade_before_value:
			cleanup_fade_counter_writes.append({"source_pc": 0x99F9 if cleanup_fade_counter_index == 0 else 0x99FF,
				"address": cleanup_fade_counter_address, "value": cleanup_fade_after_value})
	if not cleanup_fade_counter_writes.is_empty():
		var cleanup_fade_counter_event_id := "cutscene_cleanup_fade_frame_%d" % source_frame
		var cleanup_fade_counter_receipt := {"ok": true, "kind": "rom_99f0_source_counter_step",
			"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
			"source_event_id": cleanup_fade_counter_event_id,
			"ram_writes": cleanup_fade_counter_writes,
			"trace_state_used": false, "emulator_data_used": false,
			"physical_nes_timing_proven": false}
		if not _source_ram_image.merge_executor_result(cleanup_fade_counter_event_id, cleanup_fade_counter_receipt):
			_route_gaps_add("ROM `$99F0` counter writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_fade_counter_history.append({
			"source_frame": source_frame,
			"source_event_id": cleanup_fade_counter_event_id,
			"cutscene_id": int(_cutscene_wait_cleanup_result.get("cutscene_id", 0)),
			"event_index": -1, "event_cpu_address": 0x99F0,
			"opcode": 0xEA,
			"fade_level": counters_after.x if counters_after.x == counters_after.y else -1,
			"ram_writes": cleanup_fade_counter_writes.duplicate(true),
		})
	if String(step.get("status", "")) == "yielded_after_palette_step":
		var packet: PackedByteArray = step.get("palette_packet", PackedByteArray())
		if packet.size() != 0x23 or not _cutscene_cleanup_fade_pending_palette_packet.is_empty():
			_route_gaps_add("ROM `$99F0->$9A71` produced an invalid or overlapping palette packet.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if packet[0] != 0x20:
			_route_gaps_add("ROM `$9B28` palette queue control byte is not the checked `$20` value.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var queue_flag_event := "cleanup_palette_queue_flag_%d" % source_frame
		var queue_flag_receipt := {
			"ok": true,
			"status": "rom_queue_flag_written",
			"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
			"source_event_id": queue_flag_event,
			"ram_writes": [
				{"source_pc": 0x9B44, "address": 0x0629, "value": packet[0] | 0x40},
				{"source_pc": 0x9B6B, "address": 0x0629, "value": packet[0]},
			],
			"trace_state_used": false,
			"emulator_data_used": false,
		}
		if not _source_ram_image.merge_executor_result(queue_flag_event, queue_flag_receipt):
			_route_gaps_add("ROM `$9B28` palette queue latch writes could not join source RAM: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_cleanup_fade_pending_palette_packet = packet.duplicate()
		_cutscene_cleanup_fade_pending_source_frame = source_frame
		_cutscene_wait_cleanup_result["fade_helper_result"] = _cutscene_cleanup_fade_task.get_status()
		_cutscene_wait_cleanup_result["palette_queue_flag_receipt"] = queue_flag_receipt.duplicate(true)
		return
	if String(step.get("status", "")) == "returned_zero_counters":
		var clear_task: Variant = CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT.new()
		if not clear_task.configure_from_project_sources():
			_route_gaps_add("Cutscene cleanup clear sources failed verification: %s" % clear_task.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_cleanup_clear_result = clear_task.execute(_visuals,
			_get_source_ppu_shadow_input())
		if not bool(_cutscene_cleanup_clear_result.get("ok", false)):
			_route_gaps_add("Cutscene cleanup clear failed: %s" % String(_cutscene_cleanup_clear_result.get("error", "unknown source/presenter error")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if not _accept_cleanup_ppu_shadow_result(
				"cutscene_cleanup_clear", _cutscene_cleanup_clear_result):
			_route_gaps_add("Cutscene cleanup did not return valid ROM-derived PPU shadow writes.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if not _source_ram_image.merge_executor_result("cutscene_cleanup_clear",
				_cleanup_ram_result_for_source_ledger(_cutscene_cleanup_clear_result)):
			_route_gaps_add("Cutscene cleanup source RAM writes could not join the live ledger: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if int(_cutscene_wait_cleanup_result.get("caller_return_pc_after_helper", -1)) == 0x8145:
			_finish_scene56_cleanup_return()
			return
		_cutscene_cleanup_ram_writes.clear()
		for write_variant in _cutscene_cleanup_clear_result.get("ram_writes", []):
			if write_variant is Dictionary:
				var write: Dictionary = write_variant
				_cutscene_cleanup_ram_writes[int(write.get("address", -1))] = int(write.get("value", -1))
		var caller: Variant = FRESH_KICKOFF_CALLER_SCRIPT.new()
		if not caller.configure_from_project_sources():
			_route_gaps_add("KICK OFF caller source failed verification: %s" % caller.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var cleanup_cpu_contract: Dictionary = _cutscene_cleanup_clear_result.get("cpu_output_contract", {})
		var caller_result: Dictionary = caller.execute_cutscene_wait_post_cleanup(
			int(_cutscene_cleanup_clear_result.get("return_source_pc", -1)),
			int(_cutscene_wait_cleanup_result.get("caller_return_pc_after_helper", -1)),
			cleanup_cpu_contract)
		if not bool(caller_result.get("ok", false)):
			_route_gaps_add("KICK OFF caller post-cleanup stopped: %s" % String(caller_result.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if int(_cutscene_wait_cleanup_result.get("caller_return_pc_after_helper", -1)) == 0x815D:
			_advance_fresh_match_id2_handoff(caller_result)
			return
		_cutscene_post_helper_ram_writes.clear()
		for write_variant in caller_result.get("ram_writes", []):
			if write_variant is Dictionary:
				var write: Dictionary = write_variant
				_cutscene_post_helper_ram_writes[int(write.get("address", -1))] = int(write.get("value", -1))
		_cutscene_wait_cleanup_result["status"] = "blocked_on_caller"
		_cutscene_wait_cleanup_result["pending_source_pc"] = int(caller_result.get("final_source_pc", -1))
		_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_kickoff_caller_match_setup"
		_cutscene_wait_cleanup_result["clear_helper_result"] = _cutscene_cleanup_clear_result.duplicate(true)
		_cutscene_wait_cleanup_result["post_helper_caller_result"] = caller_result.duplicate(true)
		_cutscene_wait_cleanup_result["next_step"] = "Continue the source-owned KICK OFF caller from $%04X." % int(caller_result.get("final_source_pc", -1))
		var pending_call: Dictionary = caller_result.get("pending_call", {})
		var mapper_shadow_builder: Variant = MAPPER_SHADOW_SOURCE_STATE_SCRIPT.new()
		var mapper_shadow_state: Dictionary = mapper_shadow_builder.derive_fresh_kickoff_id1()
		if not bool(mapper_shadow_state.get("ok", false)):
			_route_gaps_add("ROM-derived MMC3 `$0022` source state could not be built: %s" % String(mapper_shadow_state.get("error", "unknown source error")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if not _source_ram_image.merge_executor_result(
				"kickoff_mapper_shadow_0022", mapper_shadow_state):
			_route_gaps_add("ROM `$0022` mapper-shadow receipt could not join the live source RAM ledger: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var mapper_helper: Variant = FIXED_MAPPER_SELECT_HELPER_SCRIPT.new()
		if not mapper_helper.configure_from_project_sources():
			_route_gaps_add("Fixed mapper helper source failed verification: %s" % mapper_helper.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var source_call: Dictionary = pending_call.duplicate(true)
		var mapper_cpu_contract: Dictionary = caller_result.get("cpu_output_contract", {}).duplicate(true)
		mapper_cpu_contract["pc"] = 0xC4B9
		var mapper_result: Dictionary = mapper_helper.execute_logical_source_call(
			source_call, mapper_cpu_contract, {0x0022: int(mapper_shadow_state.get("value", -1))})
		if not bool(mapper_result.get("ok", false)):
			_route_gaps_add("ROM `$C4B9` bank select stopped: %s" % String(mapper_result.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var title_stack_builder: Variant = FRESH_TITLE_STACK_CONTEXT_SCRIPT.new()
		if not title_stack_builder.configure_from_project_sources():
			_route_gaps_add("Fresh KICK OFF physical-stack source failed validation: %s" % String(title_stack_builder.error_message))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var selector_stack_context: Dictionary = title_stack_builder.build_selector_call_context(
			caller_result, mapper_result, "fresh_kickoff_id1_rom_call_80FA_A20F")
		if not bool(selector_stack_context.get("ok", false)):
			_route_gaps_add("ROM caller stack could not be derived for `$80FA->$A20F`: %s" % String(selector_stack_context.get("error", "unknown source error")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var next_call: Dictionary = selector_stack_context.get("selector_source_call", {})
		var source_ram_status: Dictionary = _source_ram_image.get_status()
		var prior_source_ram_values: Dictionary = source_ram_status.get("known_values", {})
		var selector_ram: Dictionary = {}
		var inherited_source_ram_byte_count := 0
		for address_variant in prior_source_ram_values:
			var address := int(address_variant)
			# The reset value of `$0078` belongs to the later wait-call owner;
			# carrying it through `$8112` would make the normalizer mistake it
			# for a caller-supplied wait state instead of the ROM preset result.
			if address == 0x0078:
				continue
			selector_ram[address] = int(prior_source_ram_values[address_variant])
			inherited_source_ram_byte_count += 1
		var caller_ram_writes: Variant = caller_result.get("ram_writes", [])
		if not caller_ram_writes is Array:
			_route_gaps_add("KICK OFF caller has no ordered RAM-write list for selector input state.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		for write_variant in caller_ram_writes:
			if not write_variant is Dictionary:
				continue
			var write: Dictionary = write_variant
			var address := int(write.get("address", -1))
			var value := int(write.get("value", -1))
			if address >= 0 and address < 0x0800 and value >= 0 and value <= 0xFF:
				selector_ram[address] = value
		var mapper_ram_after: Dictionary = mapper_result.get("ram_after", {})
		for address_variant in mapper_ram_after:
			selector_ram[int(address_variant)] = int(mapper_ram_after[address_variant])
		selector_ram[0x0026] = int(mapper_shadow_state.get("match_index_0026", -1))
		var known_stack_offsets: Array = selector_stack_context.get("stack_known_page_offsets", [])
		var caller_stack_page: PackedByteArray = selector_stack_context.get("stack_page", PackedByteArray())
		for page_offset_variant in known_stack_offsets:
			var page_offset := int(page_offset_variant)
			if page_offset < 0 or page_offset > 0xFF or caller_stack_page.size() != 0x100:
				_route_gaps_add("ROM caller stack context has an invalid source-known page byte.")
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			selector_ram[0x0100 | page_offset] = int(caller_stack_page[page_offset])
		var selector_executor: Variant = FRESH_MATCH_SELECTOR_SCRIPT.new()
		if not selector_executor.configure_from_project_sources():
			_route_gaps_add("Fresh-match selector source failed verification: %s" % selector_executor.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var selector_clock: Variant = FRESH_MATCH_SELECTOR_CLOCK_SCRIPT.new()
		if not selector_clock.configure_from_project_sources():
			_route_gaps_add("Fresh-match selector clock failed source validation: %s" % selector_clock.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var nmi_checkpoint_cycle := _selector_frame8_nmi_mainline_cycle(selector_clock)
		if not bool(nmi_checkpoint_cycle.get("ok", false)):
			_route_gaps_add("Selector's source-clock NMI checkpoint could not be resolved: %s" % String(nmi_checkpoint_cycle.get("error", "unknown clock error")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var interrupt_counter_executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
		if not interrupt_counter_executor.configure_from_project_sources():
			_route_gaps_add("ROM NMI/IRQ wrapper source for interrupt-counter convergence failed validation: %s" % String(interrupt_counter_executor.error_message))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var interrupt_counter_receipt: Dictionary = interrupt_counter_executor.derive_pre_candidate_interrupt_counter_receipt(
			selector_clock.get_status(), selector_clock.get_interrupt_events(),
			nmi_checkpoint_cycle.get("event", {}))
		if not bool(interrupt_counter_receipt.get("ok", false)):
			_route_gaps_add("ROM interrupt-counter history could not be derived before the selector NMI: %s" % String(interrupt_counter_receipt.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		# The ROM-only selector source model supplies full call-entry P at `$A20F`;
		# the selector clock separately checks I=clear at the NMI candidate.
		var selector_entry_status: Dictionary = selector_clock.get_candidate_entry_status_evidence()
		if not bool(selector_entry_status.get("ok", false)):
			_route_gaps_add("Selector clock did not provide its route-bound I-flag receipt: %s" % String(selector_entry_status.get("error", "source status unavailable")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var selector_cpu_contract: Dictionary = mapper_result.get("return_registers", {}).duplicate(true)
		var selector_call_entry_p_receipt: Dictionary = selector_clock.get_selector_call_entry_p_evidence()
		if not bool(selector_call_entry_p_receipt.get("ok", false)) \
				or String(selector_call_entry_p_receipt.get("kind", "")) != "rom_source_selector_call_entry_p_byte" \
				or int(selector_call_entry_p_receipt.get("source_pc", -1)) != 0xA20F \
				or int(selector_call_entry_p_receipt.get("source_frame", -1)) != 7258 \
				or int(selector_call_entry_p_receipt.get("source_cycle", -1)) != 216143875 \
				or int(selector_call_entry_p_receipt.get("known_mask", 0)) != 0xFF \
				or int(selector_call_entry_p_receipt.get("known_value", -1)) != 0x30 \
				or bool(selector_call_entry_p_receipt.get("fceux_trace_used_as_input", true)) \
				or bool(selector_call_entry_p_receipt.get("emulator_state_used", true)):
			_route_gaps_add("ROM-only selector-call entry P receipt is missing or conflicts with the reviewed `$A20F` boundary.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var prior_p_mask := int(selector_cpu_contract.get("p_known_mask", -1))
		var prior_p_value := int(selector_cpu_contract.get("p_known_value", -1))
		var source_entry_p := int(selector_call_entry_p_receipt.get("known_value", -1))
		if prior_p_mask < 0 or prior_p_mask > 0xFF or prior_p_value < 0 or prior_p_value > 0xFF \
				or ((prior_p_value ^ source_entry_p) & prior_p_mask) != 0:
			_route_gaps_add("ROM-only `$A20F` P byte conflicts with the selector caller's known flags.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		selector_cpu_contract["p"] = source_entry_p
		selector_cpu_contract["p_known_mask"] = 0xFF
		selector_cpu_contract["p_known_value"] = source_entry_p
		var source_p_mask := int(selector_entry_status.get("p_known_mask", -1))
		var source_p_value := int(selector_entry_status.get("p_known_value", -1))
		var caller_p_mask := int(selector_cpu_contract.get("p_known_mask", -1))
		var caller_p_value := int(selector_cpu_contract.get("p_known_value", -1))
		if source_p_mask != 0x04 or source_p_value != 0 \
				or caller_p_mask < 0 or caller_p_mask > 0xFF \
				or caller_p_value < 0 or caller_p_value > 0xFF \
				or ((caller_p_value ^ source_p_value) & caller_p_mask & source_p_mask) != 0:
			_route_gaps_add("Selector CPU status cannot merge the ROM-model I=clear receipt without a conflict.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var caller_p := int(selector_cpu_contract.get("p", caller_p_value))
		var merged_p_mask := caller_p_mask | source_p_mask
		var merged_p_value := (caller_p_value & caller_p_mask) | (source_p_value & source_p_mask)
		selector_cpu_contract["p"] = (caller_p & ~source_p_mask) | (source_p_value & source_p_mask)
		selector_cpu_contract["p_known_mask"] = merged_p_mask
		selector_cpu_contract["p_known_value"] = merged_p_value & merged_p_mask
		selector_entry_status["live_source_status_known"] = false
		selector_entry_status["partial_source_status_known"] = true
		selector_entry_status["i_flag_known"] = true
		selector_entry_status["candidate_status_applied"] = true
		selector_entry_status["full_p_byte_known"] = false
		selector_entry_status["candidate_p_byte_used_as_full_status"] = false
		selector_cpu_contract["pc"] = 0xA20F
		selector_cpu_contract["sp"] = int(selector_stack_context.get("entry_sp", -1))
		var checkpoint_cycle_offsets: Array[int] = [int(nmi_checkpoint_cycle.get("mainline_cycle_offset", -1))]
		var selector_result: Dictionary = selector_executor.execute_source_call(next_call,
			selector_cpu_contract, selector_ram, checkpoint_cycle_offsets)
		if not bool(selector_result.get("ok", false)):
			_route_gaps_add("ROM `$80FA->$A20F` match selector stopped: %s" % String(selector_result.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var cpu_checkpoints: Array = selector_result.get("source_cpu_checkpoints", [])
		if cpu_checkpoints.size() != 1:
			_route_gaps_add("ROM selector did not produce exactly one source CPU checkpoint for the frame-8 NMI candidate.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var cpu_checkpoint: Dictionary = cpu_checkpoints[0]
		if int(cpu_checkpoint.get("source_cycle_offset", -1)) != int(nmi_checkpoint_cycle["mainline_cycle_offset"]) \
				or int(cpu_checkpoint.get("source_pc", -1)) != 0xA15B:
			_route_gaps_add("ROM selector checkpoint does not match the source-clock frame-8 `$A15B` NMI boundary.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var candidate_ram_values: Dictionary = cpu_checkpoint.get("ram_known_values", {}).duplicate(true)
		var counter_writes: Variant = interrupt_counter_receipt.get("known_bit_writes", [])
		if not counter_writes is Array or counter_writes.size() != 1 \
				or not counter_writes[0] is Dictionary:
			_route_gaps_add("ROM interrupt-counter receipt does not prove the candidate NMI's full `$003B` byte.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var counter_write: Dictionary = counter_writes[0]
		if int(counter_write.get("address", -1)) != 0x003B \
				or int(counter_write.get("known_mask", 0)) != 0xFF:
			_route_gaps_add("ROM interrupt-counter receipt does not prove the candidate NMI's full `$003B` byte.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var counter_value := int(counter_write.get("known_value", -1))
		if counter_value < 0 or counter_value > 0xFF \
				or (candidate_ram_values.has(0x003B)
					and int(candidate_ram_values[0x003B]) != counter_value):
			_route_gaps_add("ROM interrupt-counter receipt conflicts with the selector's source-produced `$003B` value.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		candidate_ram_values[0x003B] = counter_value
		var candidate_source_frame := source_frame + int(nmi_checkpoint_cycle.get("event", {}).get("frame_offset", -1))
		var rng_history_receipt := _derive_pre_candidate_rng_history_receipt(candidate_source_frame)
		if not bool(rng_history_receipt.get("ok", false)):
			_route_gaps_add("ROM-only RNG history could not produce the candidate NMI input bytes: %s" % String(rng_history_receipt.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var rng_writes: Variant = rng_history_receipt.get("ram_writes", [])
		if not rng_writes is Array or rng_writes.size() != 3:
			_route_gaps_add("ROM-only RNG history did not produce exactly three A117 byte writes.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		for write_variant in rng_writes:
			if not write_variant is Dictionary:
				_route_gaps_add("ROM-only RNG history contains a malformed RAM write.")
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			var write: Dictionary = write_variant
			var address := int(write.get("address", -1))
			var value := int(write.get("value", -1))
			if address not in [0x00E1, 0x00E2, 0x00E3] or value < 0 or value > 0xFF \
					or (candidate_ram_values.has(address) and int(candidate_ram_values[address]) != value):
				_route_gaps_add("ROM-only RNG history conflicts with the selector's candidate RAM at `$%04X`." % address)
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			candidate_ram_values[address] = value
		var counter_003a_receipt: Dictionary = interrupt_counter_executor.derive_pre_candidate_sound_frame_counter_receipt(
			rng_history_receipt.get("counter_003a_reset_receipt", {}),
			rng_history_receipt.get("counter_003a_history_receipt", {}))
		if not bool(counter_003a_receipt.get("ok", false)):
			_route_gaps_add("ROM-only `$003A` counter history could not be verified: %s" % String(counter_003a_receipt.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var counter_003a_writes: Variant = counter_003a_receipt.get("known_bit_writes", [])
		if not counter_003a_writes is Array or counter_003a_writes.size() != 1 \
				or not counter_003a_writes[0] is Dictionary:
			_route_gaps_add("ROM `$003A` receipt does not contain exactly one full-byte invariant.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var counter_003a_write: Dictionary = counter_003a_writes[0]
		var counter_003a_value := int(counter_003a_write.get("known_value", -1))
		if int(counter_003a_write.get("address", -1)) != 0x003A \
				or int(counter_003a_write.get("known_mask", 0)) != 0xFF \
				or counter_003a_value < 0 or counter_003a_value > 0xFF \
				or (candidate_ram_values.has(0x003A)
					and int(candidate_ram_values[0x003A]) != counter_003a_value):
			_route_gaps_add("ROM `$003A` counter receipt conflicts with the selector's source-produced state.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		candidate_ram_values[0x003A] = counter_003a_value
		var sound_queue_input_receipt: Dictionary = rng_history_receipt.get(
			"pre_candidate_sound_queue_inputs_receipt", {})
		var sound_queue_known_values: Variant = sound_queue_input_receipt.get("known_byte_values", [])
		var expected_sound_queue_addresses: Array[int] = [0x0700, 0x0701, 0x0702,
			0x0703, 0x0704, 0x0705, 0x0706, 0x07E9]
		if not bool(sound_queue_input_receipt.get("ok", false)) \
				or int(sound_queue_input_receipt.get("candidate_source_frame", -1)) != candidate_source_frame \
				or int(sound_queue_input_receipt.get("candidate_source_pc", -1)) != 0xC421 \
				or bool(sound_queue_input_receipt.get("trace_state_used", true)) \
				or bool(sound_queue_input_receipt.get("emulator_data_used", true)) \
				or not sound_queue_known_values is Array \
				or sound_queue_known_values.size() != expected_sound_queue_addresses.size():
			_route_gaps_add("ROM-stepper sound-driver input receipt is missing or not bound to the candidate `$C421` boundary.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var observed_sound_queue_addresses: Dictionary = {}
		for value_variant in sound_queue_known_values:
			if not value_variant is Dictionary:
				_route_gaps_add("ROM-stepper sound-driver input receipt contains a malformed RAM value.")
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			var known_value: Dictionary = value_variant
			var address := int(known_value.get("address", -1))
			var value := int(known_value.get("known_value", -1))
			if address not in expected_sound_queue_addresses \
					or int(known_value.get("known_mask", 0)) != 0xFF \
					or value != 0 \
					or (candidate_ram_values.has(address) \
						and int(candidate_ram_values[address]) != value):
				_route_gaps_add("ROM-stepper sound-driver input conflicts at candidate RAM `$%04X`." % address)
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			observed_sound_queue_addresses[address] = true
			candidate_ram_values[address] = value
		if observed_sound_queue_addresses.size() != expected_sound_queue_addresses.size():
			_route_gaps_add("ROM-stepper sound-driver input receipt omits one or more queue bytes.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var mode_bit7_receipt: Dictionary = rng_history_receipt.get(
			"pre_candidate_nmi_mode_bit7_receipt", {})
		var mode_bit7_writes: Variant = mode_bit7_receipt.get("known_bit_writes", [])
		if not bool(mode_bit7_receipt.get("ok", false)) \
				or String(mode_bit7_receipt.get("kind", "")) != "rom_source_candidate_001b_bit7" \
				or int(mode_bit7_receipt.get("candidate_source_frame", -1)) != candidate_source_frame \
				or int(mode_bit7_receipt.get("candidate_source_pc", -1)) != 0xC421 \
				or int(mode_bit7_receipt.get("known_bit_mask", 0)) != 0xFF \
				or int(mode_bit7_receipt.get("known_bit_value", -1)) != 0xC0 \
				or not mode_bit7_writes is Array or mode_bit7_writes.size() != 1 \
				or not mode_bit7_writes[0] is Dictionary \
				or int(mode_bit7_writes[0].get("address", -1)) != 0x001B \
				or int(mode_bit7_writes[0].get("known_mask", 0)) != 0x80 \
				or int(mode_bit7_writes[0].get("known_value", -1)) != 0x80 \
				or int(mode_bit7_writes[0].get("source_pc", -1)) != 0xA133 \
				or bool(mode_bit7_receipt.get("candidate_nmi_executed", true)) \
				or bool(mode_bit7_receipt.get("trace_state_used", true)) \
				or bool(mode_bit7_receipt.get("emulator_data_used", true)) \
				or bool(mode_bit7_receipt.get("candidate_state_used", true)):
			_route_gaps_add("ROM `$001B.7` receipt is missing or not bound to the candidate `$C421` boundary.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var saved_bank_receipt: Dictionary = rng_history_receipt.get(
			"pre_candidate_saved_bank_07fc_receipt", {})
		var saved_bank_values: Variant = saved_bank_receipt.get("known_byte_values", [])
		if not bool(saved_bank_receipt.get("ok", false)) \
				or String(saved_bank_receipt.get("kind", "")) != "rom_source_candidate_saved_bank_07fc" \
				or int(saved_bank_receipt.get("candidate_source_frame", -1)) != candidate_source_frame \
				or int(saved_bank_receipt.get("candidate_source_pc", -1)) != 0xC421 \
				or int(saved_bank_receipt.get("saved_bank_07fc_value", -1)) != 0x0F \
				or not saved_bank_values is Array or saved_bank_values.size() != 1 \
				or not saved_bank_values[0] is Dictionary \
				or int(saved_bank_values[0].get("address", -1)) != 0x07FC \
				or int(saved_bank_values[0].get("known_mask", 0)) != 0xFF \
				or int(saved_bank_values[0].get("known_value", -1)) != 0x0F \
				or int(saved_bank_values[0].get("source_pc", -1)) != 0x804D \
				or bool(saved_bank_receipt.get("trace_state_used", true)) \
				or bool(saved_bank_receipt.get("emulator_data_used", true)) \
				or bool(saved_bank_receipt.get("candidate_state_used", true)):
			_route_gaps_add("ROM sound-driver saved-bank receipt is missing or invalid at candidate `$C421`.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		if candidate_ram_values.has(0x07FC) and int(candidate_ram_values[0x07FC]) != 0x0F:
			_route_gaps_add("ROM sound-driver saved-bank receipt conflicts with candidate RAM `$07FC`.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		candidate_ram_values[0x07FC] = 0x0F
		cpu_checkpoint["ram_known_values"] = candidate_ram_values
		cpu_checkpoint["ram_known_byte_count"] = candidate_ram_values.size()
		var candidate_ram_known_bits: Dictionary = {}
		for address_variant in candidate_ram_values:
			var address := int(address_variant)
			candidate_ram_known_bits[address] = {
				"known_mask": 0xFF,
				"known_value": int(candidate_ram_values[address]),
			}
		var prior_known_bits: Dictionary = source_ram_status.get("known_bits_by_address", {})
		for address_variant in prior_known_bits:
			var address := int(address_variant)
			var bit_state: Variant = prior_known_bits[address_variant]
			if not bit_state is Dictionary:
				_route_gaps_add("Source RAM bit-state ledger contains a malformed entry at `$%04X`." % address)
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			var known_mask := int(bit_state.get("known_mask", 0))
			var known_value := int(bit_state.get("known_value", 0))
			if known_mask <= 0 or known_mask > 0xFF or known_value < 0 or known_value > 0xFF:
				_route_gaps_add("Source RAM bit-state ledger has an invalid mask/value at `$%04X`." % address)
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			if candidate_ram_values.has(address):
				if ((int(candidate_ram_values[address]) ^ known_value) & known_mask) != 0:
					_route_gaps_add("Full candidate RAM at `$%04X` conflicts with its ROM-derived known bits." % address)
					route_stage = RouteStage.MATCH_SETUP_GAP
					route_stage_changed.emit(_stage_name())
					return
			else:
				candidate_ram_known_bits[address] = {
					"known_mask": known_mask,
					"known_value": known_value & known_mask,
				}
		var mode_bit7_write: Dictionary = mode_bit7_writes[0]
		var mode_bit_address := int(mode_bit7_write["address"])
		var prior_mode_bits: Dictionary = candidate_ram_known_bits.get(mode_bit_address, {})
		var prior_mode_mask := int(prior_mode_bits.get("known_mask", 0))
		var prior_mode_value := int(prior_mode_bits.get("known_value", 0))
		var mode_write_mask := int(mode_bit7_write["known_mask"])
		var mode_write_value := int(mode_bit7_write["known_value"])
		if ((prior_mode_value ^ mode_write_value) & prior_mode_mask & mode_write_mask) != 0:
			_route_gaps_add("ROM `$001B.7` source write conflicts with the previously derived mode bits.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var merged_mode_mask := prior_mode_mask | mode_write_mask
		var merged_mode_value := (prior_mode_value & prior_mode_mask) | (mode_write_value & mode_write_mask)
		if merged_mode_mask == 0xFF:
			if candidate_ram_values.has(mode_bit_address) \
					and int(candidate_ram_values[mode_bit_address]) != merged_mode_value:
				_route_gaps_add("Combined ROM `$001B` bit receipts conflict with the candidate RAM byte.")
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			candidate_ram_values[mode_bit_address] = merged_mode_value
		candidate_ram_known_bits[mode_bit_address] = {
			"known_mask": merged_mode_mask,
			"known_value": merged_mode_value & merged_mode_mask,
		}
		cpu_checkpoint["ram_known_values"] = candidate_ram_values
		cpu_checkpoint["ram_known_byte_count"] = candidate_ram_values.size()
		cpu_checkpoint["ram_known_bit_values"] = candidate_ram_known_bits
		cpu_checkpoint["additional_ram_state_receipts"] = [
			"pre_candidate_interrupt_counter_convergence",
			"pre_candidate_sound_frame_counter_history",
			"pre_candidate_sound_queue_inputs",
			"pre_candidate_sound_driver_saved_bank",
			"pre_candidate_nmi_mode_bit7",
			"pre_candidate_rom_rng_history",
			"pre_candidate_special_nmi_zero_mask_entry_ram_reads",
			"source_ram_known_bit_invariants",
		]
		cpu_checkpoint["ram_provenance"] = String(cpu_checkpoint.get("ram_provenance", "")) \
			+ "; `$003A` supplied by reset/boot clear and ROM A135 increments; `$003B` supplied by ROM wrapper convergence; `$00E1-$00E3` replayed from prior ROM-only A117 events; `$001B.7` derived from the route-bound ROM-stepper writer history ending at bank-$02 `$A133`; `$07FC` derived from reset plus prior bank-$0C `STY $07FC` writers; `$0700-$0706/$07E9` sampled from the route-bound ROM-stepper `$C421` boundary and writer history"
		_fresh_match_selector_nmi_checkpoint = {
			"ok": true,
			"status": "rom_selector_cpu_checkpoint_ready_candidate_nmi_not_dispatched",
			"source_rom_sha256": String(selector_result.get("source_rom_sha256", "")),
			"source_event": nmi_checkpoint_cycle.get("event", {}).duplicate(true),
			"mainline_cycle_offset": int(nmi_checkpoint_cycle["mainline_cycle_offset"]),
			"cpu_checkpoint": cpu_checkpoint.duplicate(true),
			"prior_source_ram_known_byte_count": prior_source_ram_values.size(),
			"prior_source_ram_bytes_inherited": inherited_source_ram_byte_count,
			"prior_source_ram_event_counts": source_ram_status.get("applied_event_counts", {}).duplicate(true),
			"candidate_clock_used_to_locate_checkpoint": true,
			"pre_candidate_interrupt_counter_receipt": interrupt_counter_receipt.duplicate(true),
			"pre_candidate_sound_frame_counter_receipt": counter_003a_receipt.duplicate(true),
			"pre_candidate_sound_queue_inputs_receipt": sound_queue_input_receipt.duplicate(true),
			"pre_candidate_saved_bank_07fc_receipt": saved_bank_receipt.duplicate(true),
			"pre_candidate_nmi_mode_bit7_receipt": mode_bit7_receipt.duplicate(true),
			"pre_candidate_rng_history_receipt": rng_history_receipt.duplicate(true),
			"selector_call_entry_p_receipt": selector_call_entry_p_receipt.duplicate(true),
			"selector_entry_status_receipt": selector_entry_status.duplicate(true),
			"candidate_source_frame": candidate_source_frame,
			"interrupt_handler_executed": false,
			"physical_stack_available": bool(cpu_checkpoint.get("stack_page_available", false)),
			"stack_page_complete": bool(cpu_checkpoint.get("stack_page_complete", false)),
			"stack_page_known_offsets": cpu_checkpoint.get("stack_page_known_offsets", []).duplicate(),
			"trace_state_used": false,
			"emulator_data_used": false,
		}
		var candidate_nmi_executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
		if not candidate_nmi_executor.configure_from_project_sources():
			_route_gaps_add("Special NMI source verification failed: %s" % candidate_nmi_executor.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var zero_mask_entry_ram_contract: Dictionary = candidate_nmi_executor.build_zero_mask_entry_ram_read_contract(
			candidate_source_frame, _fresh_match_selector_nmi_checkpoint)
		if not bool(zero_mask_entry_ram_contract.get("ok", false)):
			_route_gaps_add("Special NMI zero-mask entry RAM read contract failed: %s" % String(
				zero_mask_entry_ram_contract.get("error", candidate_nmi_executor.error_message)))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_fresh_match_selector_nmi_checkpoint[
			"pre_candidate_zero_mask_entry_ram_read_contract"] = zero_mask_entry_ram_contract
		_begin_fresh_match_selector_clock(caller_result, pending_call,
			mapper_shadow_state, mapper_result, selector_executor, selector_result,
			selector_ram, selector_clock, selector_entry_status)
		return
	_route_gaps_add("ROM `$99F0` cleanup fade returned an unsupported source state `%s`." % String(step.get("status", "unknown")))
	route_stage = RouteStage.MATCH_SETUP_GAP
	route_stage_changed.emit(_stage_name())


func _selector_frame8_nmi_mainline_cycle(clock: Variant) -> Dictionary:
	if clock == null or not clock.has_method("get_interrupt_events"):
		return {"ok": false, "error": "The ROM selector clock has no interrupt-event interface."}
	var interrupt_events: Array[Dictionary] = clock.get_interrupt_events()
	var elapsed_interrupt_cycles := 0
	for event in interrupt_events:
		if int(event.get("frame_offset", -1)) == 8 \
				and String(event.get("kind", "")) == "NMI":
			if String(event.get("pc_before", "")) != "$A15B":
				return {"ok": false, "error": "Frame-8 NMI candidate no longer names selector PC `$A15B`."}
			var elapsed_cycle := int(event.get("elapsed_cycle", -1))
			if elapsed_cycle < elapsed_interrupt_cycles:
				return {"ok": false, "error": "Frame-8 NMI candidate precedes its accumulated interrupt time."}
			return {
				"ok": true,
				"event": event.duplicate(true),
				"mainline_cycle_offset": elapsed_cycle - elapsed_interrupt_cycles,
				"prior_interrupt_cycles": elapsed_interrupt_cycles,
				"source_clock_status": clock.get_status(),
			}
		var event_start := int(event.get("elapsed_cycle", -1))
		var event_end := int(event.get("return_cycle", -1))
		if event_start < 0 or event_end < event_start:
			return {"ok": false, "error": "Selector clock contains an invalid prior interrupt interval."}
		elapsed_interrupt_cycles += event_end - event_start
	return {"ok": false, "error": "Selector clock has no frame-8 NMI candidate."}


func _derive_pre_candidate_rng_history_receipt(candidate_source_frame: int) -> Dictionary:
	if candidate_source_frame != 7266:
		return {"ok": false, "error": "The audited ROM-only RNG history ends immediately before candidate source frame 7266."}
	var replay: Variant = KICKOFF_RNG_REPLAY_SCRIPT.new()
	if not replay.configure(KICKOFF_RNG_SCHEDULE_PATH, KICKOFF_RNG_INPUT_ROUTE_SHA256):
		return {"ok": false, "error": replay.error_message}
	replay.reset_from_cold_start()
	if not replay.advance_to_source_frame(candidate_source_frame - 1):
		return {"ok": false, "error": replay.error_message}
	var state: Dictionary = replay.get_state()
	if int(state.get("last_source_frame", -1)) != 7265 \
			or int(state.get("a117_updates_applied", -1)) != 7255 \
			or int(state.get("c9c5_updates_applied", -1)) != 0 \
			or int(state.get("e1", -1)) != 0x85 \
			or int(state.get("e2", -1)) != 0xEB \
			or int(state.get("e3", -1)) != 0x45:
		return {"ok": false, "error": "ROM-only replay state before frame 7266 differs from the audited A117 history."}
	var receipt: Dictionary = replay.build_last_a117_ram_write_receipt(
		"selector_pre_candidate_rom_rng_history")
	if not bool(receipt.get("ok", false)) \
			or int(receipt.get("source_frame", -1)) != candidate_source_frame - 1 \
			or bool(receipt.get("following_nmi_executed", true)) \
			or bool(receipt.get("trace_state_used", true)) \
			or bool(receipt.get("emulator_data_used", true)):
		return {"ok": false, "error": String(receipt.get("error", "ROM-only RNG history receipt failed its provenance checks."))}
	var counter_history_receipt: Dictionary = replay.build_pre_candidate_counter_003a_history_receipt(
		candidate_source_frame, "selector_pre_candidate_sound_frame_counter_history")
	if not bool(counter_history_receipt.get("ok", false)):
		return {"ok": false, "error": String(counter_history_receipt.get("error", "ROM-only `$003A` history receipt failed."))}
	var reset_context_builder: Variant = FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT.new()
	var reset_counter_addresses: Array[int] = [0x003A]
	var reset_counter_receipt: Dictionary = reset_context_builder.build_reset_ram_zero_write_receipt(
		"selector_pre_candidate_sound_frame_counter_reset", reset_counter_addresses)
	if not bool(reset_counter_receipt.get("ok", false)):
		return {"ok": false, "error": String(reset_counter_receipt.get("error", "ROM reset-zero receipt for `$003A` failed."))}
	receipt["candidate_source_frame"] = candidate_source_frame
	receipt["candidate_nmi_input_only"] = true
	receipt["counter_003a_history_receipt"] = counter_history_receipt
	receipt["counter_003a_reset_receipt"] = reset_counter_receipt
	var sound_queue_receipt: Dictionary = replay.build_pre_candidate_sound_queue_inputs_receipt(
		candidate_source_frame, "selector_pre_candidate_sound_queue_inputs")
	if not bool(sound_queue_receipt.get("ok", false)):
		return {"ok": false, "error": String(sound_queue_receipt.get("error", "ROM-stepper sound-queue input receipt failed."))}
	receipt["pre_candidate_sound_queue_inputs_receipt"] = sound_queue_receipt
	var mode_history_receipt: Dictionary = replay.build_pre_candidate_nmi_mode_bit_history_receipt(
		candidate_source_frame, "selector_pre_candidate_nmi_mode_bit7")
	if not bool(mode_history_receipt.get("ok", false)):
		return {"ok": false, "error": String(mode_history_receipt.get("error", "ROM-stepper `$001B` writer history receipt failed."))}
	var mode_producer: Variant = NMI_MODE_PRODUCER_SCRIPT.new()
	if not mode_producer.configure_from_project_sources():
		return {"ok": false, "error": mode_producer.error_message}
	var mode_bit7_receipt: Dictionary = mode_producer.build_pre_candidate_mode_bit7_receipt(
		_nmi_mode_route_receipt, mode_history_receipt)
	if not bool(mode_bit7_receipt.get("ok", false)):
		return {"ok": false, "error": String(mode_bit7_receipt.get("error", mode_producer.error_message))}
	receipt["pre_candidate_nmi_mode_bit7_receipt"] = mode_bit7_receipt
	var saved_bank_history: Dictionary = replay.build_pre_candidate_saved_bank_07fc_history_receipt(
		candidate_source_frame, "selector_pre_candidate_saved_bank_07fc")
	if not bool(saved_bank_history.get("ok", false)):
		return {"ok": false, "error": String(saved_bank_history.get("error", "ROM-stepper `$07FC` history receipt failed."))}
	var special_nmi_executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
	if not special_nmi_executor.configure_from_project_sources():
		return {"ok": false, "error": special_nmi_executor.error_message}
	var saved_bank_receipt: Dictionary = special_nmi_executor.build_pre_candidate_saved_bank_07fc_receipt(
		saved_bank_history)
	if not bool(saved_bank_receipt.get("ok", false)):
		return {"ok": false, "error": String(saved_bank_receipt.get("error", special_nmi_executor.error_message))}
	receipt["pre_candidate_saved_bank_07fc_receipt"] = saved_bank_receipt
	return receipt


func _begin_fresh_match_selector_clock(caller_result: Dictionary, pending_call: Dictionary,
		mapper_shadow_state: Dictionary, mapper_result: Dictionary, selector_executor: Variant,
		selector_result: Dictionary, selector_initial_ram: Dictionary, clock: Variant,
		selector_entry_status: Dictionary) -> void:
	var clock_status: Dictionary = clock.get_status()
	if int(clock_status.get("mainline_cycles", -1)) != int(selector_result.get("cpu_cycles_without_interrupts", -2)):
		_route_gaps_add("Selector clock mainline total does not match the ROM executor's cycle count.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_match_selector_clock = clock
	_fresh_match_selector_context = {
		"caller_result": caller_result,
		"pending_call": pending_call.duplicate(true),
		"mapper_shadow_state": mapper_shadow_state.duplicate(true),
		"mapper_result": mapper_result,
		"selector_executor": selector_executor,
		"selector_result": selector_result,
		"selector_initial_ram": selector_initial_ram.duplicate(true),
		"selector_entry_status": selector_entry_status.duplicate(true),
	}
	_fresh_match_selector_entry_frame = source_frame
	_fresh_match_selector_progress.clear()
	_fresh_match_selector_materialized_ram.clear()
	_fresh_match_selector_scheduled_interrupts.clear()
	route_stage = RouteStage.MATCH_SELECTOR_RUNNING
	if not _advance_fresh_match_selector_clock():
		return
	if route_stage == RouteStage.MATCH_SELECTOR_RUNNING:
		route_stage_changed.emit(_stage_name())


func _advance_fresh_match_selector_clock() -> bool:
	if _fresh_match_selector_clock == null or _fresh_match_selector_context.is_empty():
		return _stop_match_selector_clock("Selector clock has no source-owned call context.")
	var frame_offset := source_frame - _fresh_match_selector_entry_frame
	var segment: Dictionary = _fresh_match_selector_clock.get_frame_segment(frame_offset)
	if not bool(segment.get("ok", false)):
		return _stop_match_selector_clock("Selector clock rejected route frame offset %d: %s" % [
			frame_offset, String(segment.get("error", "unknown source error"))
		])
	var selector_result: Dictionary = _fresh_match_selector_context.get("selector_result", {})
	var selector_executor: Variant = _fresh_match_selector_context.get("selector_executor")
	var write_timeline: Array[Dictionary] = selector_result.get("ram_write_timeline", [])
	var materialized: Dictionary = selector_executor.apply_ram_write_timeline_through_cycle(
		_fresh_match_selector_context.get("selector_initial_ram", {}), write_timeline,
		int(segment.get("mainline_cycle_end", -1)))
	if not bool(materialized.get("ok", false)):
		return _stop_match_selector_clock("Selector RAM timeline stopped: %s" % String(materialized.get("error", "unknown timeline error")))
	_fresh_match_selector_materialized_ram = materialized.get("ram_after_prefix", {}).duplicate(true)
	for event_variant in segment.get("interrupt_events", []):
		if event_variant is Dictionary:
			var event: Dictionary = event_variant.duplicate(true)
			event["route_source_frame"] = source_frame
			event["handler_executed_by_live_route"] = false
			_fresh_match_selector_scheduled_interrupts.append(event)
	_fresh_match_selector_progress = {
		"entry_source_frame": _fresh_match_selector_entry_frame,
		"route_source_frame": source_frame,
		"frame_offset": frame_offset,
		"mainline_cycle_start": int(segment.get("mainline_cycle_start", -1)),
		"mainline_cycle_end": int(segment.get("mainline_cycle_end", -1)),
		"mainline_cycle_budget": int(segment.get("mainline_cycle_budget", -1)),
		"entry_i_flag_known_clear": bool(_fresh_match_selector_context.get("selector_entry_status", {}).get("i_flag_known", false)) \
				and (int(_fresh_match_selector_context.get("selector_entry_status", {}).get("p_known_value", 0)) & 0x04) == 0,
		"ram_writes_applied": int(materialized.get("applied_write_count", -1)),
		"ram_timeline_complete": bool(materialized.get("all_timeline_writes_applied", false)),
		"scheduled_interrupt_count": _fresh_match_selector_scheduled_interrupts.size(),
		"interrupt_handler_state_applied": false,
		"resumable_6502_execution": false,
	}
	if frame_offset < 8:
		return true
	if not bool(materialized.get("all_timeline_writes_applied", false)):
		return _stop_match_selector_clock("Selector clock reached return before all source writes were applied.")
	if _fresh_match_selector_materialized_ram != selector_result.get("ram_after", {}):
		return _stop_match_selector_clock("Cycle-timed selector RAM differs from the ROM executor's final RAM image.")
	selector_result["ram_after"] = _fresh_match_selector_materialized_ram.duplicate(true)
	selector_result["route_cycle_progress"] = _fresh_match_selector_progress.duplicate(true)
	selector_result["scheduled_interrupt_events"] = _fresh_match_selector_scheduled_interrupts.duplicate(true)
	return _finish_fresh_match_selector_call()


func _finish_fresh_match_selector_call() -> bool:
	var caller_result: Dictionary = _fresh_match_selector_context.get("caller_result", {})
	var pending_call: Dictionary = _fresh_match_selector_context.get("pending_call", {})
	var mapper_shadow_state: Dictionary = _fresh_match_selector_context.get("mapper_shadow_state", {})
	var mapper_result: Dictionary = _fresh_match_selector_context.get("mapper_result", {})
	var selector_result: Dictionary = _fresh_match_selector_context.get("selector_result", {})
	var candidate_nmi_execution := _execute_source_clock_candidate_nmi(selector_result)
	if not bool(candidate_nmi_execution.get("ok", false)):
		return _stop_match_selector_clock("Frame-8 ROM-source NMI dispatch stopped: %s" % String(
			candidate_nmi_execution.get("error", "unknown NMI context error")))
	var normalizer: Variant = FRESH_MATCH_NORMALIZER_SCRIPT.new()
	if not normalizer.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match normalizer source failed verification: %s" % normalizer.error_message)
	var normalize_result: Dictionary
	if bool(selector_result.get("physical_stack_mode", false)):
		normalize_result = normalizer.execute_from_selector_return(selector_result)
	else:
		normalize_result = normalizer.execute_from_logical_selector_return(selector_result)
	if not bool(normalize_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$80FD-$8112` caller/normalizer stopped: %s" % String(normalize_result.get("error", "source state rejected")))
	if not _apply_normalizer_audio_stop(normalize_result):
		return _stop_match_selector_clock("ROM `$8107` stop write could not be consumed by the route audio presenter.")
	var preset_prefix: Variant = FRESH_MATCH_PRESET_PREFIX_SCRIPT.new()
	if not preset_prefix.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$8920` preset prefix source failed verification: %s" % preset_prefix.error_message)
	var source_write_receipts: Array[Dictionary] = [
		{"id": "post_cleanup_kickoff_caller", "result": caller_result,
			"writes_key": "ram_writes"},
		{"id": "kickoff_mapper_select", "result": mapper_result,
			"writes_key": "ram_writes"},
		{"id": "fresh_match_selector", "result": selector_result,
			"writes_key": "ram_writes"},
	]
	for receipt in source_write_receipts:
		var result: Dictionary = receipt["result"]
		result["ram_writes"] = result.get(String(receipt["writes_key"]), [])
		if not _source_ram_image.merge_executor_result(String(receipt["id"]), result):
			return _stop_match_selector_clock("Source RAM write continuity stopped: %s" % _source_ram_image.error_message)
	var interrupt_counter_receipt: Dictionary = _fresh_match_selector_nmi_checkpoint.get(
		"pre_candidate_interrupt_counter_receipt", {})
	if not bool(interrupt_counter_receipt.get("ok", false)) \
			or bool(interrupt_counter_receipt.get("handlers_executed", true)) \
			or bool(interrupt_counter_receipt.get("trace_state_used", true)) \
			or not _source_ram_image.merge_known_bits_receipt(
				"selector_pre_candidate_interrupt_counter_convergence", interrupt_counter_receipt):
		return _stop_match_selector_clock("ROM-derived `$003B` interrupt-history invariant could not join the sparse source RAM ledger: %s" % _source_ram_image.error_message)
	var sound_frame_counter_receipt: Dictionary = _fresh_match_selector_nmi_checkpoint.get(
		"pre_candidate_sound_frame_counter_receipt", {})
	if not bool(sound_frame_counter_receipt.get("ok", false)) \
			or bool(sound_frame_counter_receipt.get("nmi_handler_executed_for_candidate", true)) \
			or bool(sound_frame_counter_receipt.get("trace_state_used", true)) \
			or not _source_ram_image.merge_known_bits_receipt(
				"selector_pre_candidate_sound_frame_counter", sound_frame_counter_receipt):
		return _stop_match_selector_clock("ROM-derived `$003A` sound-frame counter invariant could not join the sparse source RAM ledger: %s" % _source_ram_image.error_message)
	var nmi_write_result := candidate_nmi_execution.duplicate(true)
	if not _source_ram_image.merge_executor_result("fresh_match_selector_frame8_nmi", nmi_write_result):
		return _stop_match_selector_clock("Frame-8 NMI RAM writes could not join the sparse source ledger: %s" % _source_ram_image.error_message)
	var preset_result: Dictionary = preset_prefix.execute_from_normalizer_return(
		normalize_result, _source_ram_image)
	if not bool(preset_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$8112->$893B` preset prefix stopped: %s" % String(preset_result.get("error", "source state rejected")))
	_fresh_match_preset_prefix_result = preset_result.duplicate(true)
	var ppu_shadow_input := _get_source_ppu_shadow_input()
	var nmi_ppu_events: Variant = candidate_nmi_execution.get("ppu_bus_events", [])
	if not nmi_ppu_events is Array:
		return _stop_match_selector_clock("Frame-8 ROM-source NMI returned malformed PPU bus events.")
	var nmi_ppu_render_result: Dictionary = _visuals.apply_source_ppu_bus_events(
		nmi_ppu_events, int(ppu_shadow_input.get("ctrl_shadow", -1)))
	if not bool(nmi_ppu_render_result.get("ok", false)):
		return _stop_match_selector_clock("Frame-8 ROM-source NMI PPU writes could not reach the Godot renderer: %s" % String(
			nmi_ppu_render_result.get("error", "unknown PPU error")))
	candidate_nmi_execution["ppu_bus_events_applied"] = true
	candidate_nmi_execution["ppu_render_result"] = nmi_ppu_render_result.duplicate(true)
	var wait_irq_executor: Variant = FRESH_MATCH_PRESET_WAIT_IRQ_EXECUTOR_SCRIPT.new()
	if not wait_irq_executor.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$893B` raster IRQ source failed verification: %s" % wait_irq_executor.error_message)
	var wait_irq_result: Dictionary = wait_irq_executor.execute_from_wait_prefix(
		preset_result, _source_ram_image, ppu_shadow_input, source_frame)
	if not bool(wait_irq_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$893B` wait IRQ stopped: %s" % String(wait_irq_result.get("error", "source state rejected")))
	var irq_ppu_events: Variant = wait_irq_result.get("ppu_bus_events", [])
	if not irq_ppu_events is Array:
		return _stop_match_selector_clock("ROM `$893B` wait IRQ returned malformed PPU bus events.")
	var irq_ppu_result: Dictionary = _visuals.apply_source_ppu_bus_events(
		irq_ppu_events, int(ppu_shadow_input.get("ctrl_shadow", -1)))
	if not bool(irq_ppu_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$893B` wait IRQ PPU writes could not reach the Godot renderer: %s" % String(
			irq_ppu_result.get("error", "unknown PPU error")))
	wait_irq_result["ppu_bus_events_applied"] = true
	wait_irq_result["ppu_render_result"] = irq_ppu_result.duplicate(true)
	var irq_ppu_after: Dictionary = wait_irq_result.get("ppu_after", {})
	if not irq_ppu_after.is_empty():
		_source_ppu_shadow_state["ctrl_shadow"] = int(irq_ppu_after.get("ctrl_shadow", ppu_shadow_input.get("ctrl_shadow", 0)))
		_source_ppu_shadow_state["mask_shadow"] = int(irq_ppu_after.get("mask_shadow", ppu_shadow_input.get("mask_shadow", 0)))
	if not _source_ram_image.merge_executor_result("fresh_match_preset_wait_irq", wait_irq_result):
		return _stop_match_selector_clock("ROM `$893B` IRQ writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
	var preset_tail_result: Dictionary = preset_prefix.execute_after_wait_release(
		preset_result, wait_irq_result)
	if not bool(preset_tail_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$893F-$895C` preset tail stopped: %s" % String(preset_tail_result.get("error", "source state rejected")))
	var preset_tail_receipt := preset_tail_result.duplicate(true)
	preset_tail_receipt["ram_writes"] = preset_tail_result.get("caller_ram_writes", [])
	if not _source_ram_image.merge_executor_result("fresh_match_preset_wait_tail", preset_tail_receipt):
		return _stop_match_selector_clock("ROM `$893F-$895C` tail writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
	var postwait_caller: Variant = FRESH_MATCH_POSTWAIT_CALLER_SCRIPT.new()
	if not postwait_caller.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$8117` caller source failed verification: %s" % postwait_caller.error_message)
	var postwait_result: Dictionary = postwait_caller.execute_from_preset_tail_result(preset_tail_result)
	if not bool(postwait_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$8117->$A4EB` caller stopped: %s" % String(postwait_result.get("error", "source state rejected")))
	var a4eb_prefix_executor: Variant = FRESH_MATCH_A4EB_PREFIX_EXECUTOR_SCRIPT.new()
	if not a4eb_prefix_executor.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$A4EB` source prefix failed verification: %s" % a4eb_prefix_executor.error_message)
	var a4eb_prefix_result: Dictionary = a4eb_prefix_executor.execute_from_postwait_result(
		postwait_result, wait_irq_result.get("mapper_after", {}), source_frame)
	if not bool(a4eb_prefix_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$A4EB` prefix stopped: %s" % String(a4eb_prefix_result.get("error", "source state rejected")))
	var ram_status_before_a4eb: Dictionary = _source_ram_image.get_status()
	var ram_values_before_a4eb: Dictionary = ram_status_before_a4eb.get("known_values", {})
	var ram_writers_before_a4eb: Dictionary = ram_status_before_a4eb.get("last_write_by_address", {})
	var a4eb_entry_values: Dictionary = {}
	var a4eb_entry_writers: Dictionary = {}
	for address: int in [0x009E, 0x009F, 0x00A0, 0x00A1]:
		if ram_values_before_a4eb.has(address):
			a4eb_entry_values[address] = ram_values_before_a4eb[address]
		if ram_writers_before_a4eb.has(address):
			a4eb_entry_writers[address] = ram_writers_before_a4eb[address].duplicate(true)
	a4eb_prefix_result["source_ram_before_prefix"] = {
		"known_values": a4eb_entry_values,
		"last_write_by_address": a4eb_entry_writers,
	}
	_fresh_match_a4eb_prefix_result = a4eb_prefix_result.duplicate(true)
	var a4eb_ram_receipt := a4eb_prefix_result.duplicate(true)
	if not _source_ram_image.merge_executor_result("fresh_match_a4eb_prefix", a4eb_ram_receipt):
		return _stop_match_selector_clock("ROM `$A4EB` prefix writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
	var b0c0_executor: Variant = FRESH_MATCH_B0C0_STREAM_EXECUTOR_SCRIPT.new()
	if not b0c0_executor.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$B0C0` source failed verification: %s" % b0c0_executor.error_message)
	var b0c0_first_result: Dictionary = b0c0_executor.execute_first_clear_command(
		a4eb_prefix_result, source_frame, String(a4eb_prefix_result.get("source_event_id", "")))
	if not bool(b0c0_first_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$B0C0` first command stopped: %s" % String(b0c0_first_result.get("error", "source state rejected")))
	var b0c0_ppu_events: Variant = b0c0_first_result.get("ppu_bus_events", [])
	if not b0c0_ppu_events is Array:
		return _stop_match_selector_clock("ROM `$B0C0` first command returned malformed PPU bus writes.")
	var b0c0_ppu_result: Dictionary = _visuals.apply_source_ppu_clear_events(
		b0c0_ppu_events, int(a4eb_prefix_result.get("ram_after", {}).get(0x0020, -1)))
	if not bool(b0c0_ppu_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$98A0` clear could not reach the live PPU renderer: %s" % String(b0c0_ppu_result.get("error", "unknown PPU error")))
	b0c0_first_result["ppu_bus_events_applied"] = true
	b0c0_first_result["ppu_render_result"] = b0c0_ppu_result.duplicate(true)
	var b0c0_ram_receipt := b0c0_first_result.duplicate(true)
	if not _source_ram_image.merge_executor_result("fresh_match_b0c0_first_clear", b0c0_ram_receipt):
		return _stop_match_selector_clock("ROM `$B0C0` first-command writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
	var reset_mode_evidence := {"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"known_values": {}, "last_write_by_address": {}}
	for address in [0x004A, 0x004B]:
		var source_byte: Dictionary = _source_ram_image.get_byte(address)
		if not bool(source_byte.get("known", false)):
			return _stop_match_selector_clock("ROM reset has no source-owned zero proof for `$%04X`." % address)
		reset_mode_evidence["known_values"][address] = int(source_byte.get("value", -1))
		reset_mode_evidence["last_write_by_address"][address] = source_byte.get("last_write", {}).duplicate(true)
	var b0c0_stream_result: Dictionary = b0c0_executor.execute_remaining_stream(
		b0c0_first_result, int(b0c0_first_result.get("next_observed_source_frame", source_frame)),
		"fresh_match_b0c0_remaining_stream",
		reset_mode_evidence)
	if not bool(b0c0_stream_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$B0C0` remaining PPU stream stopped: %s" % String(b0c0_stream_result.get("error", "source state rejected")))
	var b0c0_stream_ppu_events: Variant = b0c0_stream_result.get("ppu_bus_events", [])
	if not b0c0_stream_ppu_events is Array:
		return _stop_match_selector_clock("ROM `$B0C0` stream returned malformed PPU bus writes.")
	var b0c0_stream_ppu_result: Dictionary = _visuals.apply_source_ppu_bus_events(
		b0c0_stream_ppu_events, int(b0c0_first_result.get("ram_after", {}).get(0x0020, -1)))
	if not bool(b0c0_stream_ppu_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$B0C0` PPU commands could not reach the live renderer: %s" % String(b0c0_stream_ppu_result.get("error", "unknown PPU error")))
	b0c0_stream_result["ppu_render_result"] = b0c0_stream_ppu_result.duplicate(true)
	var actual_samples: Dictionary = {}
	var expected_samples: Dictionary = b0c0_stream_result.get("ppu_memory_samples_expected", {})
	for address_variant in expected_samples:
		var address := int(address_variant)
		actual_samples[address] = int(_visuals._ppu_memory.get(address, -1))
	b0c0_stream_result["ppu_memory_samples_actual"] = actual_samples
	b0c0_stream_result["ppu_memory_samples_match"] = actual_samples == expected_samples
	var b0c0_stream_ram_receipt := b0c0_stream_result.duplicate(true)
	if not _source_ram_image.merge_executor_result("fresh_match_b0c0_remaining_stream", b0c0_stream_ram_receipt):
		return _stop_match_selector_clock("ROM `$B0C0` stream RAM writes could not join the source ledger: %s" % _source_ram_image.error_message)
	var a503_executor: Variant = FRESH_MATCH_A503_ENTRY_EXECUTOR_SCRIPT.new()
	if not a503_executor.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$A503` source tables failed verification: %s" % a503_executor.error_message)
	var a503_result: Dictionary = a503_executor.execute_from_b0c0_stream_result(
		b0c0_stream_result, int(b0c0_stream_result.get("next_observed_source_frame", source_frame)))
	if not bool(a503_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$A503` entry stopped: %s" % String(a503_result.get("error", "source state rejected")))
	if not _source_ram_image.merge_executor_result("fresh_match_a503_entry", a503_result):
		return _stop_match_selector_clock("ROM `$A503` RAM writes could not join the source ledger: %s" % _source_ram_image.error_message)
	var descriptor_queue_evidence := {"known_values": {}, "last_write_by_address": {}}
	for address in [0x0628, 0x0629]:
		var source_byte: Dictionary = _source_ram_image.get_byte(address)
		if not bool(source_byte.get("known", false)):
			return _stop_match_selector_clock("ROM `$9D27` has no source-owned queue-state proof for `$%04X`." % address)
		descriptor_queue_evidence["known_values"][address] = int(source_byte.get("value", -1))
		descriptor_queue_evidence["last_write_by_address"][address] = source_byte.get("last_write", {}).duplicate(true)
	var a503_decoder_result: Dictionary = a503_executor.execute_descriptor_decoder(
		a503_result, descriptor_queue_evidence,
		int(b0c0_stream_result.get("next_observed_source_frame", source_frame)))
	if not bool(a503_decoder_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$9D27` descriptor decode stopped: %s" % String(a503_decoder_result.get("error", "source state rejected")))
	if not _source_ram_image.merge_executor_result("fresh_match_a503_descriptor_decoder", a503_decoder_result):
		return _stop_match_selector_clock("ROM `$9D27` queue writes could not join the source ledger: %s" % _source_ram_image.error_message)
	_fresh_match_a503_entry_result = a503_result.duplicate(true)
	_fresh_match_a503_entry_result["descriptor_decoder_result"] = a503_decoder_result.duplicate(true)
	var ppu_after_b0c0: Dictionary = _visuals.get_source_ppu_state()
	_source_ppu_shadow_state = {"ok": true,
		"ctrl_shadow": int(ppu_after_b0c0.get("ctrl_shadow", -1)),
		"mask_shadow": int(ppu_after_b0c0.get("mask_shadow", -1)),
		"source_event_id": "fresh_match_b0c0_remaining_stream",
		"source_rom_sha256": String(b0c0_first_result.get("source_rom_sha256", "")),
		"trace_state_used": false, "emulator_data_used": false}
	_fresh_match_selector_nmi_checkpoint["candidate_nmi_execution"] = candidate_nmi_execution.duplicate(true)
	_fresh_match_selector_nmi_checkpoint["status"] = "rom_source_frame8_nmi_executed_and_rti_returned_to_A15B"
	_fresh_match_selector_nmi_checkpoint["interrupt_handler_executed"] = true
	_fresh_match_selector_nmi_checkpoint["candidate_nmi_dispatched"] = true
	_fresh_match_selector_progress["interrupt_handler_state_applied"] = true
	_fresh_match_selector_progress["interrupt_handler_applied_count"] = 1
	_fresh_match_selector_progress["interrupt_handlers_unresolved"] = max(
		0, int(_fresh_match_selector_progress.get("scheduled_interrupt_count", 0)) - 1)
	for receipt in [
		{"id": "fresh_match_normalizer", "result": normalize_result,
			"writes_key": "caller_ram_writes"},
		{"id": "fresh_match_preset_prefix", "result": preset_result,
			"writes_key": "caller_ram_writes"},
	]:
		var result: Dictionary = receipt["result"]
		result["ram_writes"] = result.get(String(receipt["writes_key"]), [])
		if not _source_ram_image.merge_executor_result(String(receipt["id"]), result):
			return _stop_match_selector_clock("Source RAM write continuity stopped: %s" % _source_ram_image.error_message)
	caller_result["mapper_shadow_state"] = mapper_shadow_state
	caller_result["mapper_helper_result"] = mapper_result
	caller_result["match_selector_result"] = selector_result
	caller_result["match_normalize_result"] = normalize_result
	caller_result["match_preset_loader_prefix_result"] = preset_result
	_fresh_match_wait_irq_result = wait_irq_result.duplicate(true)
	_fresh_match_preset_tail_result = preset_tail_result.duplicate(true)
	_fresh_match_postwait_caller_result = postwait_result.duplicate(true)
	caller_result["match_preset_wait_irq_result"] = _fresh_match_wait_irq_result.duplicate(true)
	caller_result["match_preset_tail_result"] = _fresh_match_preset_tail_result.duplicate(true)
	caller_result["match_postwait_caller_result"] = _fresh_match_postwait_caller_result.duplicate(true)
	caller_result["caller_cpu_contract_before_mapper"] = caller_result.get("cpu_output_contract", {}).duplicate(true)
	caller_result["completed_call"] = pending_call.duplicate(true)
	caller_result["mapper_cpu_output_contract"] = mapper_result.get("return_registers", {}).duplicate(true)
	caller_result["selector_cpu_output_contract"] = selector_result.get("return_registers", {}).duplicate(true)
	caller_result["match_a4eb_prefix_result"] = a4eb_prefix_result.duplicate(true)
	caller_result["b0c0_first_command_result"] = b0c0_first_result.duplicate(true)
	caller_result["b0c0_stream_result"] = b0c0_stream_result.duplicate(true)
	caller_result["a503_entry_result"] = a503_result.duplicate(true)
	caller_result["a503_descriptor_decoder_result"] = a503_decoder_result.duplicate(true)
	caller_result["cpu_output_contract"] = a503_decoder_result.get("next_cpu_state", {}).duplicate(true)
	caller_result["caller_ram_after_match_selector"] = selector_result.get("ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_normalizer"] = normalize_result.get("caller_ram_after", {}).duplicate(true)
	caller_result["caller_ram_at_preset_wait"] = preset_result.get("caller_ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_preset_tail"] = preset_tail_result.get("caller_ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_a4eb_prefix"] = a4eb_prefix_result.get("ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_b0c0_first_command"] = b0c0_first_result.get("ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_b0c0_stream"] = b0c0_stream_result.get("ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_a503_entry"] = a503_decoder_result.get("ram_after", {}).duplicate(true)
	caller_result["selector_timing_clock"] = _fresh_match_selector_clock.get_status()
	caller_result["selector_entry_status_evidence"] = _fresh_match_selector_context.get("selector_entry_status", {}).duplicate(true)
	caller_result["selector_interrupts_scheduled_only"] = _fresh_match_selector_scheduled_interrupts.duplicate(true)
	caller_result["selector_frame8_nmi_execution"] = candidate_nmi_execution.duplicate(true)
	caller_result["next_pending_call"] = {"caller_pc": 0xA529, "next_source_pc": 0xA529,
		"call_id": "fresh_match_a503_next_setup_block", "status": "next_a503_block_unexecuted"}
	caller_result["pending_call"] = caller_result["next_pending_call"]
	caller_result["status"] = "stopped_after_a503_first_descriptor"
	caller_result["final_source_pc"] = 0xA529
	caller_result["next_observed_source_frame"] = int(b0c0_stream_result.get("next_observed_source_frame", source_frame))
	caller_result["source_path"].append_array(mapper_result.get("executed_instruction_pcs", []))
	caller_result["source_path"].append(0x80FA)
	caller_result["source_path"].append_array(selector_result.get("source_path", []))
	caller_result["source_path"].append(0x80FD)
	caller_result["source_path"].append_array(normalize_result.get("source_path", []))
	caller_result["source_path"].append(0x8112)
	caller_result["source_path"].append_array(preset_result.get("source_path", []))
	caller_result["source_path"].append(0x893B)
	caller_result["source_path"].append_array(wait_irq_result.get("source_path", []))
	caller_result["source_path"].append_array(preset_tail_result.get("source_path", []))
	caller_result["source_path"].append_array(postwait_result.get("source_path", []))
	caller_result["source_path"].append_array(a4eb_prefix_result.get("source_path", []))
	caller_result["source_path"].append_array(b0c0_first_result.get("source_path", []))
	caller_result["source_path"].append_array(b0c0_stream_result.get("source_path", []))
	caller_result["source_path"].append_array(a503_result.get("source_path", []))
	caller_result["source_path"].append_array(a503_decoder_result.get("source_path", []))
	source_frame = int(b0c0_stream_result.get("next_observed_source_frame", source_frame))
	var a503_text_setup_result: Dictionary = a503_executor.advance_text_setup(
		a503_decoder_result, source_frame, _get_source_ppu_shadow_input())
	if not bool(a503_text_setup_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$A529` text setup stopped: %s" % String(a503_text_setup_result.get("error", "source state rejected")))
	if not _source_ram_image.merge_executor_result(
			"fresh_match_a503_text_setup_frame_%d" % source_frame, a503_text_setup_result):
		return _stop_match_selector_clock("ROM `$A529` text-setup RAM writes could not join the source ledger: %s" % _source_ram_image.error_message)
	_fresh_match_a503_text_setup_result = a503_text_setup_result.duplicate(true)
	_fresh_match_a503_entry_result["text_setup_result"] = a503_text_setup_result.duplicate(true)
	caller_result["a503_text_setup_result"] = a503_text_setup_result.duplicate(true)
	caller_result["cpu_output_contract"] = a503_text_setup_result.get("next_cpu_state", {}).duplicate(true)
	caller_result["caller_ram_after_a503_entry"] = a503_text_setup_result.get("ram_after", {}).duplicate(true)
	var text_source_path: Array = a503_text_setup_result.get("source_path", [])
	var descriptor_source_path: Array = a503_decoder_result.get("source_path", [])
	caller_result["source_path"].append_array(text_source_path.slice(descriptor_source_path.size()))
	var a503_text_waiting := String(a503_text_setup_result.get("status", "")) == "waiting_for_a503_queue_drain"
	caller_result["status"] = "stopped_waiting_for_a503_queue_drain" if a503_text_waiting else "stopped_before_a503_fade_helper"
	caller_result["final_source_pc"] = int(a503_text_setup_result.get("next_cpu_state", {}).get("pc", -1))
	caller_result["next_pending_call"] = {"caller_pc": caller_result["final_source_pc"],
		"next_source_pc": caller_result["final_source_pc"],
		"call_id": "fresh_match_a503_text_queue_capacity_wait" if a503_text_waiting else "fresh_match_a503_fade_helper",
		"status": "rom_queue_capacity_wait" if a503_text_waiting else "fade_helper_unexecuted"}
	caller_result["pending_call"] = caller_result["next_pending_call"]
	_cutscene_wait_cleanup_result["status"] = String(caller_result["status"])
	_cutscene_wait_cleanup_result["pending_source_pc"] = caller_result["final_source_pc"]
	_cutscene_wait_cleanup_result["pending_helper_id"] = String(caller_result["next_pending_call"]["call_id"])
	_cutscene_wait_cleanup_result["clear_helper_result"] = _cutscene_cleanup_clear_result.duplicate(true)
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = caller_result.duplicate(true)
	_cutscene_wait_cleanup_result["wait_irq_result"] = _fresh_match_wait_irq_result.duplicate(true)
	_cutscene_wait_cleanup_result["preset_tail_result"] = _fresh_match_preset_tail_result.duplicate(true)
	_cutscene_wait_cleanup_result["postwait_caller_result"] = _fresh_match_postwait_caller_result.duplicate(true)
	_cutscene_wait_cleanup_result["a4eb_prefix_result"] = a4eb_prefix_result.duplicate(true)
	_cutscene_wait_cleanup_result["b0c0_first_command_result"] = b0c0_first_result.duplicate(true)
	_cutscene_wait_cleanup_result["b0c0_stream_result"] = b0c0_stream_result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_entry_result"] = a503_result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_descriptor_decoder_result"] = a503_decoder_result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_text_setup_result"] = a503_text_setup_result.duplicate(true)
	_cutscene_wait_cleanup_result["next_step"] = "The ROM `$A529` text setup is paused at its source `$9B28` capacity wait; the bounded `$A000` transfer and remaining text bytes will advance on later source ticks." if a503_text_waiting else "The ROM `$A56C->$997A` palette ramp will resume through its source `$9FA8` yields."
	if a503_text_waiting:
		route_stage = RouteStage.MATCH_SETUP_A503_TEXT_SETUP
	else:
		if not _begin_fresh_match_a503_palette_ramp(a503_text_setup_result):
			return false
	route_stage_changed.emit(_stage_name())
	return true


func _advance_fresh_match_a503_text_setup() -> void:
	if String(_fresh_match_a503_text_setup_result.get("status", "")) != "waiting_for_a503_queue_drain":
		_route_gaps_add("A503 continuation stage has no pending ROM queue-capacity wait.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var executor: Variant = FRESH_MATCH_A503_ENTRY_EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_route_gaps_add("A503 text continuation sources failed verification: %s" % executor.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var result: Dictionary = executor.advance_text_setup(
		_fresh_match_a503_text_setup_result, source_frame, _get_source_ppu_shadow_input())
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$A529` text continuation stopped: %s" % String(result.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _source_ram_image.merge_executor_result(
			"fresh_match_a503_text_setup_frame_%d" % source_frame, result):
		_route_gaps_add("A503 text-continuation RAM writes could not join the source ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var bus_events: Array[Dictionary] = []
	var applied: Dictionary = {}
	for event_variant in result.get("ppu_bus_events", []):
		if not event_variant is Dictionary:
			_route_gaps_add("The bounded A503 queue drain returned a malformed PPU event.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var event: Dictionary = event_variant
		bus_events.append({"operation": "write", "ppu_register": int(event.get("address", -1)),
			"value": int(event.get("value", -1)), "source_pc": int(event.get("source_pc", -1))})
	if not bus_events.is_empty():
		applied = _visuals.apply_source_ppu_bus_events(bus_events,
			int(_source_ppu_shadow_state.get("ctrl_shadow", -1)))
		if not bool(applied.get("ok", false)):
			_route_gaps_add("ROM `$A000` packet writes could not reach the PPU renderer: %s" % String(applied.get("error", "renderer rejected bus events")))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
	result["ppu_render_result"] = applied if not bus_events.is_empty() else {}
	if not bus_events.is_empty():
		var drain_history: Array = result.get("queue_drain_history", []).duplicate(true)
		if not drain_history.is_empty():
			var last_drain: Dictionary = drain_history.back().duplicate(true)
			last_drain["ppu_render_result"] = applied.duplicate(true)
			drain_history[drain_history.size() - 1] = last_drain
			result["queue_drain_history"] = drain_history
			var continuation: Dictionary = result.get("continuation_state", {}).duplicate(true)
			continuation["queue_drain_history"] = drain_history.duplicate(true)
			result["continuation_state"] = continuation
	_fresh_match_a503_text_setup_result = result.duplicate(true)
	_fresh_match_a503_entry_result["text_setup_result"] = result.duplicate(true)
	var handoff: Dictionary = _cutscene_wait_cleanup_result.get("post_helper_caller_result", {}).duplicate(true)
	var prior_text_path: Array = _fresh_match_a503_text_setup_result.get("source_path", [])
	var continued_text_path: Array = result.get("source_path", [])
	handoff["a503_text_setup_result"] = result.duplicate(true)
	handoff["cpu_output_contract"] = result.get("next_cpu_state", {}).duplicate(true)
	handoff["caller_ram_after_a503_entry"] = result.get("ram_after", {}).duplicate(true)
	handoff["source_path"] = handoff.get("source_path", []).duplicate()
	if continued_text_path.size() > prior_text_path.size():
		handoff["source_path"].append_array(continued_text_path.slice(prior_text_path.size()))
	var waiting := String(result.get("status", "")) == "waiting_for_a503_queue_drain"
	handoff["status"] = "stopped_waiting_for_a503_queue_drain" if waiting else "stopped_before_a503_fade_helper"
	handoff["final_source_pc"] = int(result.get("next_cpu_state", {}).get("pc", -1))
	handoff["next_pending_call"] = {"caller_pc": handoff["final_source_pc"],
		"next_source_pc": handoff["final_source_pc"],
		"call_id": "fresh_match_a503_text_queue_capacity_wait" if waiting else "fresh_match_a503_fade_helper",
		"status": "rom_queue_capacity_wait" if waiting else "fade_helper_unexecuted"}
	handoff["pending_call"] = handoff["next_pending_call"]
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = handoff
	_cutscene_wait_cleanup_result["a503_text_setup_result"] = result.duplicate(true)
	_cutscene_wait_cleanup_result["status"] = String(handoff["status"])
	_cutscene_wait_cleanup_result["pending_source_pc"] = handoff["final_source_pc"]
	_cutscene_wait_cleanup_result["pending_helper_id"] = String(handoff["next_pending_call"]["call_id"])
	if not waiting:
		_cutscene_wait_cleanup_result["next_step"] = "ROM `$A56C->$997A` begins its paired-counter palette ramp from the four pending text records."
		if not _begin_fresh_match_a503_palette_ramp(result):
			return
		route_stage_changed.emit(_stage_name())


func _begin_fresh_match_a503_palette_ramp(text_result: Dictionary) -> bool:
	var ramp_task: Variant = FRESH_MATCH_PALETTE_RAMP_TASK_SCRIPT.new()
	if not ramp_task.configure_from_project_sources():
		_route_gaps_add("ROM `$997A` palette source failed verification: %s" % ramp_task.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		return false
	var cleanup_status: Dictionary = _cutscene_cleanup_fade_task.get_status() \
		if _cutscene_cleanup_fade_task != null else {}
	var result: Dictionary = ramp_task.begin(text_result,
		_source_ram_image.get_status(), cleanup_status, source_frame)
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$A56C->$997A` palette ramp stopped: %s" % String(result.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		return false
	if not _source_ram_image.merge_executor_result(
			"fresh_match_a503_palette_ramp_begin", result):
		_route_gaps_add("ROM `$997A` table/queue writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		return false
	_fresh_match_a503_palette_ramp_task = ramp_task
	_fresh_match_a503_palette_ramp_result = result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_palette_ramp_result"] = result.duplicate(true)
	_cutscene_wait_cleanup_result["status"] = "waiting_for_a503_palette_ramp_nmi"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0x9FA8
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_a503_palette_ramp"
	var handoff: Dictionary = _cutscene_wait_cleanup_result.get("post_helper_caller_result", {}).duplicate(true)
	handoff["a503_palette_ramp_result"] = result.duplicate(true)
	handoff["status"] = "waiting_for_a503_palette_ramp_nmi"
	handoff["final_source_pc"] = 0x9FA8
	handoff["next_pending_call"] = {"caller_pc": 0xA56C,
		"next_source_pc": 0x9FA8, "call_id": "fresh_match_a503_palette_ramp",
		"status": "rom_cooperative_yield"}
	handoff["pending_call"] = handoff["next_pending_call"]
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = handoff
	route_stage = RouteStage.MATCH_SETUP_A503_PALETTE_RAMP
	return true


func _advance_fresh_match_a503_palette_ramp() -> void:
	if _fresh_match_a503_palette_ramp_task == null:
		_route_gaps_add("ROM `$997A` palette continuation has no task state.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var result: Dictionary = _fresh_match_a503_palette_ramp_task.advance_source_tick(
		source_frame, _get_source_ppu_shadow_input())
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$997A` palette continuation stopped: %s" % String(result.get("error", "source state rejected")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _source_ram_image.merge_executor_result(
			"fresh_match_a503_palette_ramp_frame_%d" % source_frame, result):
		_route_gaps_add("ROM `$997A` palette/queue writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var bus_events: Array[Dictionary] = []
	for event_variant in result.get("ppu_bus_events", []):
		if not event_variant is Dictionary:
			_route_gaps_add("The bounded `$A000` palette drain returned a malformed PPU event.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var event: Dictionary = event_variant
		bus_events.append({"operation": "write", "ppu_register": int(event.get("address", -1)),
			"value": int(event.get("value", -1)), "source_pc": int(event.get("source_pc", -1))})
	var applied: Dictionary = {}
	if not bus_events.is_empty():
		applied = _visuals.apply_source_ppu_bus_events(bus_events,
			int(_source_ppu_shadow_state.get("ctrl_shadow", -1)))
		if not bool(applied.get("ok", false)):
			_route_gaps_add("ROM `$A000` palette writes could not reach the live PPU renderer: %s" % String(applied.get("error", "renderer rejected bus events")))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
	if not bus_events.is_empty():
		var history: Array = result.get("queue_drain_history", []).duplicate(true)
		if not history.is_empty():
			var last_drain: Dictionary = history.back().duplicate(true)
			last_drain["ppu_render_result"] = applied.duplicate(true)
			history[history.size() - 1] = last_drain
			result["queue_drain_history"] = history
	result["ppu_render_result"] = applied
	_fresh_match_a503_palette_ramp_result = result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_palette_ramp_result"] = result.duplicate(true)
	var handoff: Dictionary = _cutscene_wait_cleanup_result.get("post_helper_caller_result", {}).duplicate(true)
	handoff["a503_palette_ramp_result"] = result.duplicate(true)
	handoff["cpu_output_contract"] = result.get("details", {}).get("cpu", {}).duplicate(true)
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = handoff
	if String(result.get("status", "")) == "returned_to_a503_wait_loop":
		_begin_fresh_match_a503_input_wait()


func _begin_fresh_match_a503_input_wait() -> void:
	var wait_task: Variant = FRESH_MATCH_A503_INPUT_WAIT_TASK_SCRIPT.new()
	if not wait_task.configure_from_project_sources():
		_route_gaps_add("ROM `$A571` input-wait source failed verification: %s" % wait_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var result: Dictionary = wait_task.begin(_fresh_match_a503_palette_ramp_result,
		_a503_source_frame_label())
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$A571` input wait rejected the `$997A` return: %s" % String(result.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_match_a503_input_wait_task = wait_task
	_fresh_match_a503_input_wait_result = result.duplicate(true)
	_fresh_match_a503_input_wait_initial_yield_pending = true
	_cutscene_wait_cleanup_result["status"] = "waiting_at_a503_input_loop"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0xA571
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_a503_input_wait"
	_cutscene_wait_cleanup_result["a503_input_wait_result"] = result.duplicate(true)
	_cutscene_wait_cleanup_result["next_step"] = "The route's live frame input adapter feeds the verified `$A571` edge/timeout rule; controller-scan NMI timing remains outside the model."
	var handoff: Dictionary = _cutscene_wait_cleanup_result.get("post_helper_caller_result", {}).duplicate(true)
	handoff["status"] = "waiting_at_a503_input_loop"
	handoff["final_source_pc"] = 0xA571
	handoff["next_pending_call"] = {"caller_pc": 0xA571,
		"next_source_pc": 0xA571, "call_id": "fresh_match_a503_input_wait",
		"status": "source_a_edge_or_countdown"}
	handoff["pending_call"] = handoff["next_pending_call"]
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = handoff
	route_stage = RouteStage.MATCH_SETUP_A503_INPUT_WAIT
	route_stage_changed.emit(_stage_name())


func _advance_fresh_match_a503_input_wait(controller_sample: Dictionary) -> void:
	if _fresh_match_a503_input_wait_task == null:
		_route_gaps_add("ROM `$A571` input loop has no configured source task.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	if _fresh_match_a503_input_wait_initial_yield_pending:
		_fresh_match_a503_input_wait_initial_yield_pending = false
		_fresh_match_a503_controller_sample = controller_sample.duplicate(true)
		return
	var wait_sample := controller_sample.duplicate(true)
	var wait_source_frame := int(wait_sample.get("source_frame", _a503_source_frame_label()))
	wait_sample["source_frame"] = wait_source_frame
	var result: Dictionary = _fresh_match_a503_input_wait_task.advance_source_tick(
		wait_source_frame, wait_sample)
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$A571` input loop stopped: %s" % String(result.get("error", "source input rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_match_a503_input_wait_result = result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_input_wait_result"] = result.duplicate(true)
	_cutscene_wait_cleanup_result["pending_source_pc"] = int(result.get("details", {}).get("cpu", {}).get("pc", 0xA571))
	var handoff: Dictionary = _cutscene_wait_cleanup_result.get("post_helper_caller_result", {}).duplicate(true)
	handoff["input_wait_result"] = result.duplicate(true)
	handoff["status"] = String(result.get("status", "waiting_at_a571"))
	handoff["final_source_pc"] = int(result.get("details", {}).get("cpu", {}).get("pc", 0xA571))
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = handoff
	if String(result.get("status", "")) in ["returned_to_a57d_on_a_edge", "timed_out_to_a57d"]:
		_begin_fresh_match_a503_postwait_fade(result)


func _begin_fresh_match_a503_postwait_fade(wait_result: Dictionary) -> void:
	var wait_cpu: Dictionary = wait_result.get("details", {}).get("cpu", {})
	if not bool(wait_result.get("ok", false)) \
			or int(wait_cpu.get("pc", -1)) != 0xA57D \
			or String(wait_result.get("status", "")) not in ["returned_to_a57d_on_a_edge", "timed_out_to_a57d"]:
		_route_gaps_add("ROM `$A57D` fade call requires an observed A edge or source countdown expiry.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var ramp_ram: Dictionary = _fresh_match_a503_palette_ramp_result.get("ram_after", {})
	var palette := PackedByteArray()
	for address in range(0x062A, 0x064A):
		if not ramp_ram.has(address):
			_route_gaps_add("ROM `$99F0` base palette lacks source RAM `$%04X`." % address)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		palette.append(int(ramp_ram[address]))
	var counter_a := int(ramp_ram.get(0x004A, -1))
	var counter_b := int(ramp_ram.get(0x004B, -1))
	var fade_task: Variant = CUTSCENE_CLEANUP_FADE_TASK_SCRIPT.new()
	if not fade_task.configure_from_project_sources() or not fade_task.begin(counter_a, counter_b, palette):
		_route_gaps_add("ROM `$99F0` fresh-match fade could not start from the `$997A` source palette: %s" % fade_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_cutscene_cleanup_fade_task = fade_task
	_fresh_match_a503_postwait_fade_result = {
		"ok": true, "status": "running_after_a57d",
		"source_frame": int(wait_result.get("source_frame", -1)),
		"input_wait_result": wait_result.duplicate(true),
		"base_palette_hex": palette.hex_encode(),
		"fade_status": fade_task.get_status(),
		"packet_history": [], "clear_result": {},
		"trace_state_used": false, "emulator_data_used": false,
		"physical_nes_timing_proven": false,
	}
	_fresh_match_a503_postwait_fade_pending_packet.clear()
	_fresh_match_a503_postwait_fade_pending_source_frame = -1
	_fresh_match_a503_postwait_fade_history.clear()
	_cutscene_wait_cleanup_result["status"] = "running_a503_postwait_fade"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0xA57D
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_a503_postwait_fade"
	var handoff: Dictionary = _cutscene_wait_cleanup_result.get("post_helper_caller_result", {}).duplicate(true)
	handoff["status"] = "running_a503_postwait_fade"
	handoff["final_source_pc"] = 0xA57D
	handoff["postwait_fade_input"] = {"counter_a": counter_a, "counter_b": counter_b,
		"base_palette_hex": palette.hex_encode(), "source_palette_ram_start": 0x062A}
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = handoff
	route_stage = RouteStage.MATCH_SETUP_A503_POSTWAIT_FADE
	route_stage_changed.emit(_stage_name())
	_advance_fresh_match_a503_postwait_fade()


func _advance_fresh_match_a503_postwait_fade() -> void:
	if _cutscene_cleanup_fade_task == null:
		_route_gaps_add("ROM `$99F0` fresh-match fade has no configured task.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var before_a := int(_cutscene_cleanup_fade_task.counter_a)
	var before_b := int(_cutscene_cleanup_fade_task.counter_b)
	var a503_frame := _a503_source_frame_label()
	var step: Dictionary = _cutscene_cleanup_fade_task.advance_source_tick(a503_frame)
	if not bool(step.get("ok", false)):
		_route_gaps_add("ROM `$99F0` fresh-match fade stopped: %s" % String(step.get("error", step.get("status", "source state rejected"))))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var fade_status: Dictionary = _cutscene_cleanup_fade_task.get_status()
	var counter_writes: Array[Dictionary] = []
	if int(fade_status.get("counter_a", -1)) != before_a:
		counter_writes.append({"source_pc": 0x99F9, "address": 0x004A,
			"value": int(fade_status["counter_a"])})
	if int(fade_status.get("counter_b", -1)) != before_b:
		counter_writes.append({"source_pc": 0x99FF, "address": 0x004B,
			"value": int(fade_status["counter_b"])})
	if not counter_writes.is_empty():
		var counter_receipt := {"ok": true, "kind": "rom_99f0_source_counter_step",
			"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
			"ram_writes": counter_writes, "trace_state_used": false,
			"emulator_data_used": false, "physical_nes_timing_proven": false}
		if not _source_ram_image.merge_executor_result(
				"fresh_match_a503_postwait_fade_frame_%d" % a503_frame, counter_receipt):
			_route_gaps_add("ROM `$99F0` counter writes could not join source RAM: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
	_fresh_match_a503_postwait_fade_result["source_frame"] = a503_frame
	_fresh_match_a503_postwait_fade_result["fade_status"] = fade_status.duplicate(true)
	if String(step.get("status", "")) == "yielded_after_palette_step":
		var packet: PackedByteArray = step.get("palette_packet", PackedByteArray())
		if packet.size() != 0x23 or not _fresh_match_a503_postwait_fade_pending_packet.is_empty():
			_route_gaps_add("ROM `$99F0` fresh-match fade produced an invalid or overlapping palette packet.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		var queue_flag_receipt := {"ok": true, "kind": "rom_9b28_palette_queue_flag",
			"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
			"ram_writes": [
				{"source_pc": 0x9B44, "address": 0x0629, "value": packet[0] | 0x40},
				{"source_pc": 0x9B6B, "address": 0x0629, "value": packet[0]},
			], "trace_state_used": false, "emulator_data_used": false,
			"physical_nes_timing_proven": false}
		if not _source_ram_image.merge_executor_result(
				"fresh_match_a503_postwait_fade_queue_%d" % a503_frame, queue_flag_receipt):
			_route_gaps_add("ROM `$9B28` fade-queue flag writes could not join source RAM: %s" % _source_ram_image.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_fresh_match_a503_postwait_fade_pending_packet = packet.duplicate()
		_fresh_match_a503_postwait_fade_pending_source_frame = a503_frame
		_fresh_match_a503_postwait_fade_result["last_palette_packet_hex"] = packet.hex_encode()
		_fresh_match_a503_postwait_fade_result["pending_packet_source_frame"] = a503_frame
	elif String(step.get("status", "")) == "returned_zero_counters":
		_finish_fresh_match_a503_postwait_clear()
		return
	_fresh_match_a503_postwait_fade_result["packet_history"] = _fresh_match_a503_postwait_fade_history.duplicate(true)
	_cutscene_wait_cleanup_result["a503_postwait_fade_result"] = _fresh_match_a503_postwait_fade_result.duplicate(true)


func _consume_pending_fresh_match_a503_fade_packet() -> bool:
	if _fresh_match_a503_postwait_fade_pending_packet.is_empty():
		return true
	var executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		return _fail_a503_postwait_fade("ROM `$A000` packet consumer source failed verification: %s" % executor.error_message)
	var ppu_input := _get_source_ppu_shadow_input()
	var consume: Dictionary = executor.execute_cleanup_fade_palette_packet(
		_fresh_match_a503_postwait_fade_pending_packet, ppu_input)
	if not bool(consume.get("ok", false)):
		return _fail_a503_postwait_fade("ROM `$A000` rejected the fresh-match fade packet: %s" % String(consume.get("error", "source state rejected")))
	var event_id := "fresh_match_a503_postwait_fade_consumer_%d" % _fresh_match_a503_postwait_fade_pending_source_frame
	if not _source_ram_image.merge_executor_result(event_id, consume):
		return _fail_a503_postwait_fade("ROM `$A04A` fade queue clear could not join source RAM: %s" % _source_ram_image.error_message)
	var bus_events: Array[Dictionary] = []
	for event_variant in consume.get("ppu_bus_events", []):
		if not event_variant is Dictionary:
			return _fail_a503_postwait_fade("ROM `$A000` returned a malformed fade PPU event.")
		var event: Dictionary = event_variant
		bus_events.append({"operation": "write", "ppu_register": int(event.get("address", -1)),
			"value": int(event.get("value", -1)), "source_pc": int(event.get("source_pc", -1))})
	var render: Dictionary = _visuals.apply_source_ppu_bus_events(bus_events,
		int(ppu_input.get("ctrl_shadow", -1)))
	if not bool(render.get("ok", false)):
		return _fail_a503_postwait_fade("ROM fade palette could not reach the live PPU renderer: %s" % String(render.get("error", "renderer rejected events")))
	_source_ppu_shadow_state = {"ok": true,
		# The bounded $A000 routine writes temporary $2000/$2001 values directly;
		# it does not alter the ROM's software shadows at $0020/$0021.
		"ctrl_shadow": int(ppu_input.get("ctrl_shadow", -1)),
		"mask_shadow": int(ppu_input.get("mask_shadow", -1)),
		"source_event_id": event_id, "source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"trace_state_used": false, "emulator_data_used": false}
	var receipt := {"producer_source_frame": _fresh_match_a503_postwait_fade_pending_source_frame,
		"consumer_source_frame": _a503_source_frame_label(),
		"payload_hex": _fresh_match_a503_postwait_fade_pending_packet.hex_encode(),
		"ppu_bus_event_count": bus_events.size(), "ppu_render_result": render.duplicate(true),
		"bounded_a000_consumer_only": true, "surrounding_nmi_executed": false}
	_fresh_match_a503_postwait_fade_history.append(receipt)
	_fresh_match_a503_postwait_fade_pending_packet.clear()
	_fresh_match_a503_postwait_fade_pending_source_frame = -1
	_fresh_match_a503_postwait_fade_result["packet_history"] = _fresh_match_a503_postwait_fade_history.duplicate(true)
	_fresh_match_a503_postwait_fade_result["last_consumer_result"] = consume.duplicate(true)
	_fresh_match_a503_postwait_fade_result["last_palette_render_result"] = render.duplicate(true)
	_cutscene_wait_cleanup_result["a503_postwait_fade_result"] = _fresh_match_a503_postwait_fade_result.duplicate(true)
	return true


func _finish_fresh_match_a503_postwait_clear() -> void:
	var clear_task: Variant = CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT.new()
	if not clear_task.configure_from_project_sources():
		_route_gaps_add("ROM `$98A0` source failed verification: %s" % clear_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var clear_result: Dictionary = clear_task.execute_98a0_ppu_clear_only(
		_visuals, _get_source_ppu_shadow_input())
	if not bool(clear_result.get("ok", false)):
		_route_gaps_add("ROM `$98A0` PPU clear stopped: %s" % String(clear_result.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _source_ram_image.merge_executor_result(
				"fresh_match_a503_postwait_98a0_frame_%d" % _a503_source_frame_label(), clear_result):
		_route_gaps_add("ROM `$98A0` PPU-shadow writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _accept_cleanup_ppu_shadow_result("fresh_match_a503_postwait_98a0", clear_result):
		_route_gaps_add("ROM `$98A0` PPU clear returned invalid source shadows.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var caller_receipt := {"ok": true, "kind": "rom_a006_a583_a58b_caller_prefix",
		"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"ram_writes": [
			{"source_pc": 0xA585, "address": 0x00ED, "value": 0x00},
			{"source_pc": 0xA587, "address": 0x00EC, "value": 0x00},
		], "trace_state_used": false, "emulator_data_used": false,
		"physical_nes_timing_proven": false}
	if not _source_ram_image.merge_executor_result(
		"fresh_match_a503_a58b_caller_%d" % _a503_source_frame_label(), caller_receipt):
		_route_gaps_add("ROM `$A583-$A58A` caller writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var a611_cpu := {"pc": 0xA58B, "a": 0x0B, "x": 0x00, "y": 0x00, "sp": 0x26,
		"p_known_mask": 0x82, "p_known_value": 0x00}
	var a503_frame := _a503_source_frame_label()
	source_frame = a503_frame
	_fresh_match_a503_a611_handoff = {"ok": true, "status": "pending_a611_call",
		"source_rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"source_frame": a503_frame, "previous_cpu_state": clear_result.get("cpu_output_contract", {}).duplicate(true),
		"cpu_output_contract": a611_cpu, "ppu_clear_result": clear_result.duplicate(true),
		"caller_ram_writes": caller_receipt["ram_writes"].duplicate(true),
		"pending_call": {"caller_pc": 0xA589, "next_source_pc": 0xA611,
			"return_pc": 0xA58E, "call_id": "fresh_match_a503_a611", "status": "ready_for_source_executor"},
		"trace_state_used": false, "emulator_data_used": false,
		"physical_nes_timing_proven": false}
	_fresh_match_a503_postwait_fade_result["status"] = "returned_to_a58b_after_fade_and_clear"
	_fresh_match_a503_postwait_fade_result["fade_status"] = _cutscene_cleanup_fade_task.get_status()
	_fresh_match_a503_postwait_fade_result["packet_history"] = _fresh_match_a503_postwait_fade_history.duplicate(true)
	_fresh_match_a503_postwait_fade_result["clear_result"] = clear_result.duplicate(true)
	_cutscene_wait_cleanup_result["a503_postwait_fade_result"] = _fresh_match_a503_postwait_fade_result.duplicate(true)
	_cutscene_wait_cleanup_result["status"] = "pending_a611_call"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0xA611
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_a503_a611"
	var caller_result: Dictionary = _cutscene_wait_cleanup_result.get(
		"post_helper_caller_result", {}).duplicate(true)
	caller_result["status"] = "pending_a611_call"
	caller_result["final_source_pc"] = 0xA58B
	caller_result["cpu_output_contract"] = a611_cpu.duplicate(true)
	caller_result["pending_call"] = _fresh_match_a503_a611_handoff["pending_call"].duplicate(true)
	caller_result["next_pending_call"] = caller_result["pending_call"].duplicate(true)
	caller_result["a503_a611_handoff"] = _fresh_match_a503_a611_handoff.duplicate(true)
	caller_result["a503_postwait_fade_result"] = _fresh_match_a503_postwait_fade_result.duplicate(true)
	caller_result["source_path"] = caller_result.get("source_path", []).duplicate()
	caller_result["source_path"].append_array([0xA583, 0xA585, 0xA587, 0xA589])
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = caller_result
	_cutscene_wait_cleanup_result["next_step"] = "Execute source `$A611`, then continue the A583 caller to its `$811F` return."
	route_stage = RouteStage.MATCH_SETUP_A503_LEVEL_UPDATE
	route_stage_changed.emit(_stage_name())


func _advance_fresh_match_a503_level_update() -> void:
	if String(_fresh_match_a503_a611_handoff.get("status", "")) != "pending_a611_call":
		_route_gaps_add("The `$A611` route stage has no pending source call.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var executor: Variant = FRESH_MATCH_A611_SETUP_EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_route_gaps_add("ROM `$A611` setup source failed verification: %s" % executor.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var result: Dictionary = executor.execute_from_a58b(
		_source_ram_image,
		_fresh_match_a503_a611_handoff.get("cpu_output_contract", {}),
		source_frame)
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$A611->$811F` source state was rejected: %s" % String(result.get("error", "unknown source error")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var event_id := "fresh_match_a611_return_%d" % source_frame
	if not _source_ram_image.merge_executor_result(event_id, result):
		_route_gaps_add("ROM `$A611` writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	result["event_id"] = event_id
	result["source_ram_write_count"] = result.get("ram_writes", []).size()
	_fresh_match_a503_a611_handoff = result.duplicate(true)
	_cutscene_wait_cleanup_result["status"] = "returned_to_811F"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0x811F
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_811F_caller"
	_cutscene_wait_cleanup_result["a503_a611_result"] = result.duplicate(true)
	var caller_result: Dictionary = _cutscene_wait_cleanup_result.get(
		"post_helper_caller_result", {}).duplicate(true)
	caller_result["status"] = "returned_to_811F"
	caller_result["final_source_pc"] = 0x811F
	caller_result["cpu_output_contract"] = result.get("cpu_output_contract", {}).duplicate(true)
	caller_result["pending_source_pc"] = 0x811F
	caller_result["pending_helper_id"] = "fresh_match_811F_caller"
	caller_result["a503_a611_handoff"] = result.duplicate(true)
	var path: Array = caller_result.get("source_path", []).duplicate()
	path.append_array([0xA58B, 0xA611, 0xC50C, 0xCD7C, 0xB013, 0xB023,
		0xB02E, 0xA58E, 0xA59D, 0xA5B1, 0xA610, 0x811F])
	caller_result["source_path"] = path
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = caller_result
	_cutscene_wait_cleanup_result["next_step"] = "Decode the `$811F` match-setup caller before continuing toward `$C572->$DB62`."
	route_stage = RouteStage.MATCH_SETUP_811F_PENDING
	route_stage_changed.emit(_stage_name())


func _advance_fresh_match_stamina_initialization() -> void:
	if String(_fresh_match_a503_a611_handoff.get("status", "")) != "returned_to_811F":
		_route_gaps_add("The `$811F` stamina call has no live `$A611` return contract.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var executor: Variant = FRESH_MATCH_STAMINA_INITIALIZER_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_route_gaps_add("ROM `$C572->$DB62` stamina sources failed verification: %s" % executor.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var result: Dictionary = executor.execute_from_811f(
		_source_ram_image,
		_fresh_match_a503_a611_handoff.get("cpu_output_contract", {}),
		source_frame)
	if not bool(result.get("ok", false)):
		_route_gaps_add("ROM `$DB62` fresh stamina state was rejected: %s" % String(result.get("error", "unknown source error")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var event_id := "fresh_match_db62_stamina_%d" % source_frame
	if not _source_ram_image.merge_executor_result(event_id, result):
		_route_gaps_add("ROM `$DB62` stamina writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	result["event_id"] = event_id
	result["source_ram_write_count"] = result.get("ram_writes", []).size()
	_fresh_match_stamina_result = result.duplicate(true)
	_cutscene_wait_cleanup_result["status"] = "returned_to_8122"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0x8122
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_8122_caller"
	_cutscene_wait_cleanup_result["fresh_match_stamina_initialization"] = result.duplicate(true)
	var caller_result: Dictionary = _cutscene_wait_cleanup_result.get(
		"post_helper_caller_result", {}).duplicate(true)
	caller_result["status"] = "returned_to_8122"
	caller_result["final_source_pc"] = 0x8122
	caller_result["cpu_output_contract"] = result.get("cpu_output_contract", {}).duplicate(true)
	caller_result["pending_source_pc"] = 0x8122
	caller_result["pending_helper_id"] = "fresh_match_8122_caller"
	caller_result["stamina_initialization"] = result.duplicate(true)
	var path: Array = caller_result.get("source_path", []).duplicate()
	path.append_array(result.get("source_path", []))
	caller_result["source_path"] = path
	var source_frame := _a503_source_frame_label()
	var caller_executor: Variant = FRESH_KICKOFF_CALLER_SCRIPT.new()
	if not caller_executor.configure_from_project_sources():
		_route_gaps_add("Fresh KICK OFF `$8122` caller source failed verification: %s" % caller_executor.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var music_result: Dictionary = caller_executor.execute_match_setup_music_store_8122(
		result, _source_ram_image, source_frame)
	if not bool(music_result.get("ok", false)):
		_route_gaps_add("ROM `$8122->$812F` music store stopped: %s" % String(music_result.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var queue_event: Dictionary = music_result.get("queue_event", {})
	var queue_event_id := String(queue_event.get("event_id", ""))
	var queue_receipt := music_result.duplicate(true)
	queue_receipt["source_event_id"] = queue_event_id
	if not _source_ram_image.merge_executor_result(queue_event_id, queue_receipt):
		_route_gaps_add("ROM `$812C` sound-queue store could not join the live source RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var typed_queue_event: RefCounted = RomSoundQueueWriteEvent.new()
	if not bool(typed_queue_event.call("populate_from_rom_direct_queue_store",
			queue_event, source_frame)):
		_route_gaps_add("ROM `$812C` queue event failed its direct-store provenance checks.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var typed_event_data: Dictionary = typed_queue_event.call("to_dictionary")
	typed_event_data["source_role"] = "fresh_match_setup_music"
	typed_event_data["match_index_0026"] = int(music_result.get("match_index_0026", -1))
	_sound_queue_event_history.append(typed_event_data)
	rom_sound_queue_write_requested.emit(typed_queue_event)
	music_result["event_id"] = queue_event_id
	music_result["runtime_consumer"] = "GameplayRomCueAudioPresenter.apply_rom_sound_command"
	_fresh_match_music_store_result = music_result.duplicate(true)
	var tail_executor_result: Dictionary = caller_executor.execute_match_setup_prefix_812f(
		music_result, _source_ram_image)
	if not bool(tail_executor_result.get("ok", false)):
		_route_gaps_add("ROM `$812F-$8142` caller prefix stopped: %s" % String(tail_executor_result.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _source_ram_image.merge_executor_result(
			String(tail_executor_result.get("event_id", "fresh_match_setup_812f_prefix")), tail_executor_result):
		_route_gaps_add("ROM `$812F-$813A` clears could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var mapper_helper: Variant = FIXED_MAPPER_SELECT_HELPER_SCRIPT.new()
	if not mapper_helper.configure_from_project_sources():
		_route_gaps_add("ROM `$813F->$C4B9` mapper helper failed source validation: %s" % mapper_helper.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var mapper_result: Dictionary = mapper_helper.execute_logical_source_call(
		tail_executor_result.get("mapper_source_call", {}),
		tail_executor_result.get("mapper_cpu_contract", {}), {0x0022: 0})
	if not bool(mapper_result.get("ok", false)):
		_route_gaps_add("ROM `$813F->$C4B9` mapper selection stopped: %s" % String(mapper_result.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not _source_ram_image.merge_executor_result("fresh_match_setup_813f_mapper", mapper_result):
		_route_gaps_add("ROM `$C4B9` mapper shadows could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var r7_selected := false
	var bank_one_selected := false
	for write_variant in mapper_result.get("mapper_bus_writes", []):
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x8000 and int(write.get("value", -1)) == 0x07:
			r7_selected = true
		if int(write.get("address", -1)) == 0x8001 and int(write.get("value", -1)) == 0x01:
			bank_one_selected = true
	if not r7_selected or not bank_one_selected:
		_route_gaps_add("ROM `$C4B9` did not prove bank `$01` selected into the `$A000` window.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var a009_entry: Variant = FRESH_PREMATCH_A009_ENTRY_SCRIPT.new()
	if not a009_entry.configure_from_project_sources():
		_route_gaps_add("ROM `$A009` entry failed source validation: %s" % a009_entry.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var a009_event_id := "fresh_match_setup_a009_jump_a64c"
	var a009_call := {"caller_pc": 0x8142, "target_pc": 0xA009, "return_pc": 0x8145,
		"source_event_id": a009_event_id,
		"logical_stack_frame": {"kind": "rom_jsr", "caller_pc": 0x8142,
			"target_pc": 0xA009, "return_pc": 0x8145, "return_word": 0x8144,
			"source_event_id": a009_event_id}}
	var a009_cpu: Dictionary = mapper_result.get("return_registers", {}).duplicate(true)
	a009_cpu["pc"] = 0xA009
	var a009_result: Dictionary = a009_entry.execute_logical_source_call(a009_call,
		a009_cpu, {"a000_prg_bank": 0x01})
	if not bool(a009_result.get("ok", false)):
		_route_gaps_add("ROM `$8142->$A009->$A64C` entry stopped: %s" % String(a009_result.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	caller_result["music_store_result"] = music_result.duplicate(true)
	caller_result["source_path"].append_array(music_result.get("source_path", []))
	caller_result["ram_writes"].append_array(music_result.get("ram_writes", []))
	caller_result["source_path"].append_array(tail_executor_result.get("source_path", []))
	caller_result["source_path"].append_array(mapper_result.get("executed_instruction_pcs", []))
	caller_result["source_path"].append_array(a009_result.get("source_path", []))
	caller_result["ram_writes"].append_array(tail_executor_result.get("ram_writes", []))
	caller_result["ram_writes"].append_array(mapper_result.get("ram_writes", []))
	caller_result["status"] = "transferred_to_A64C"
	caller_result["final_source_pc"] = 0xA64C
	caller_result["music_id"] = int(music_result.get("selected_queue_id", -1))
	caller_result["music_store_event_id"] = queue_event_id
	caller_result["post_music_prefix"] = tail_executor_result.duplicate(true)
	caller_result["mapper_helper_result"] = mapper_result.duplicate(true)
	caller_result["a009_entry_result"] = a009_result.duplicate(true)
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = caller_result
	_cutscene_wait_cleanup_result["status"] = "transferred_to_A64C"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0xA64C
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_a64c_prematch_body"
	_cutscene_wait_cleanup_result["fresh_match_setup_music_store"] = music_result.duplicate(true)
	_fresh_match_caller_tail_result = {"status": "transferred_to_A64C",
		"source_rom_sha256": music_result.get("source_rom_sha256", ""),
		"music_store": music_result.duplicate(true),
		"caller_prefix": tail_executor_result.duplicate(true),
		"mapper_helper": mapper_result.duplicate(true),
		"a009_entry": a009_result.duplicate(true),
		"next_source_pc": 0xA64C,
		"source_frame_label": source_frame,
		"timing_verified": false}
	_cutscene_wait_cleanup_result["fresh_match_caller_tail"] = _fresh_match_caller_tail_result.duplicate(true)
	_cutscene_wait_cleanup_result["next_step"] = "ROM `$812F-$8142` cleared four setup bytes, `$C4B9` selected bank `$01`, and `$A009` transferred to `$A64C`."
	route_stage = RouteStage.MATCH_SETUP_A64C_PENDING
	route_stage_changed.emit(_stage_name())


func _fail_a503_postwait_fade(message: String) -> bool:
	_route_gaps_add(message)
	route_stage = RouteStage.MATCH_SETUP_GAP
	route_stage_changed.emit(_stage_name())
	return false


func _advance_fresh_match_id2_handoff(caller_result: Dictionary) -> void:
	if int(caller_result.get("final_source_pc", -1)) != 0x815D \
			or int(caller_result.get("caller_return_pc", -1)) != 0x815D \
			or not bool(_cutscene_cleanup_clear_result.get("ok", false)) \
			or String(_cutscene_cleanup_clear_result.get("status", "")) != "returned_from_9ba0":
		_route_gaps_add("Cutscene ID-2 return must reach the checked `$815D` caller with the live `$82DF->$9BA0` effects applied.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var handoff_executor: Variant = FRESH_MATCH_HANDOFF_EXECUTOR_SCRIPT.new()
	if not handoff_executor.configure_from_project_sources():
		_route_gaps_add("Fresh-match handoff ROM spans failed verification: %s" % handoff_executor.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var helper_results: Array[Dictionary] = [{
		"helper_id": "cutscene_cleanup_9ba0",
		"source_pc": 0x82DF,
		"target_pc": 0x9BA0,
		"status": "applied",
		"effect_provider": "RomCutsceneCleanupClearTask.execute",
		"effect_summary": "Applied ROM-verified $98A0 nametable and $9B7F OAM clear; returned to $82E2.",
		"source_result": _cutscene_cleanup_clear_result.duplicate(true),
	}]
	var completion_kind := String(_last_cutscene_completion_kind)
	var handoff_plan: Dictionary = handoff_executor.execute_cutscene2_return(
		completion_kind, helper_results)
	if not bool(handoff_plan.get("ok", false)) \
			or String(handoff_plan.get("pending_helper_id", "")) != "fresh_setup_palette_fade_99f0" \
			or int(handoff_plan.get("pending_source_pc", -1)) != 0xA2AF:
		_route_gaps_add("Cutscene ID-2 source caller did not reach the `$A2AF->$99F0` match-setup call: %s" % String(handoff_plan.get("error", handoff_executor.error_message)))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var cleanup_fade_status: Dictionary = _cutscene_cleanup_fade_task.get_status() \
		if _cutscene_cleanup_fade_task != null else {}
	var fade_a := int(cleanup_fade_status.get("counter_a", -1))
	var fade_b := int(cleanup_fade_status.get("counter_b", -1))
	if fade_a != 0 or fade_b != 0:
		_route_gaps_add("ROM `$A2AF->$99F0` has nonzero source counters; this live handoff only accepts the verified zero-counter path.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var setup_fade: Variant = CUTSCENE_CLEANUP_FADE_TASK_SCRIPT.new()
	if not setup_fade.configure_from_project_sources() \
			or not setup_fade.begin(fade_a, fade_b, PackedByteArray()):
		_route_gaps_add("Fresh-match `$A2AF->$99F0` zero-counter call failed source setup: %s" % setup_fade.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var fade_return: Dictionary = setup_fade.advance_source_tick(source_frame)
	if not bool(fade_return.get("ok", false)) \
			or String(fade_return.get("status", "")) != "returned_zero_counters":
		_route_gaps_add("Fresh-match `$99F0` did not return on the verified zero-counter source path.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	helper_results.append({
		"helper_id": "fresh_setup_palette_fade_99f0",
		"source_pc": 0xA2AF,
		"target_pc": 0x99F0,
		"status": "applied",
		"effect_provider": "RomCutsceneCleanupFadeTask.advance_source_tick",
		"effect_summary": "Executed the ROM $99F0 loop with the caller-owned $004A/$004B counters at zero.",
		"source_result": fade_return.duplicate(true),
	})
	handoff_plan = handoff_executor.execute_cutscene2_return(completion_kind, helper_results)
	if not bool(handoff_plan.get("ok", false)) \
			or String(handoff_plan.get("pending_helper_id", "")) != "fresh_setup_ppu_clear_98a0":
		_route_gaps_add("Fresh-match `$A2AF` fade return did not advance to its source `$98A0` call.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var clear_task: Variant = CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT.new()
	if not clear_task.configure_from_project_sources():
		_route_gaps_add("Fresh-match `$A2AF` clear helper sources failed verification: %s" % clear_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var ppu_clear: Dictionary = clear_task.execute_98a0_ppu_clear_only(
		_visuals, _get_source_ppu_shadow_input(), 0xA2B2, 0xA2B5)
	if not bool(ppu_clear.get("ok", false)):
		_route_gaps_add("Fresh-match `$A2B2->$98A0` PPU clear stopped: %s" % String(ppu_clear.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var ppu_event_id := "fresh_match_a2af_ppu_clear_%d" % source_frame
	if not _source_ram_image.merge_executor_result(ppu_event_id, ppu_clear) \
			or not _accept_cleanup_ppu_shadow_result(ppu_event_id, ppu_clear):
		_route_gaps_add("Fresh-match `$98A0` PPU-shadow writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	helper_results.append({
		"helper_id": "fresh_setup_ppu_clear_98a0",
		"source_pc": 0xA2B2,
		"target_pc": 0x98A0,
		"status": "applied",
		"effect_provider": "RomCutsceneCleanupClearTask.execute_98a0_ppu_clear_only",
		"effect_summary": "Applied the ROM $98A0 PPU clear and updated source shadows at $0020/$0021.",
		"source_result": ppu_clear.duplicate(true),
	})
	handoff_plan = handoff_executor.execute_cutscene2_return(completion_kind, helper_results)
	if not bool(handoff_plan.get("ok", false)) \
			or String(handoff_plan.get("pending_helper_id", "")) != "fresh_setup_oam_clear_9b7f":
		_route_gaps_add("Fresh-match `$98A0` return did not advance to its source `$9B7F` call.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var oam_clear: Dictionary = clear_task.execute_direct_9b7f_oam_clear(
		ppu_clear.get("cpu_output_contract", {}), 0xA2B8)
	if not bool(oam_clear.get("ok", false)):
		_route_gaps_add("Fresh-match `$A2B5->$9B7F` OAM clear stopped: %s" % String(oam_clear.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var oam_event_id := "fresh_match_a2af_oam_clear_%d" % source_frame
	if not _source_ram_image.merge_executor_result(oam_event_id, oam_clear):
		_route_gaps_add("Fresh-match `$9B7F` OAM writes could not join the source RAM ledger: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	helper_results.append({
		"helper_id": "fresh_setup_oam_clear_9b7f",
		"source_pc": 0xA2B5,
		"target_pc": 0x9B7F,
		"status": "applied",
		"effect_provider": "RomCutsceneCleanupClearTask.execute_direct_9b7f_oam_clear",
		"effect_summary": "Applied the ROM $9B7F OAM shadow, DMA buffer, and motion-record writes.",
		"source_result": oam_clear.duplicate(true),
	})
	handoff_plan = handoff_executor.execute_cutscene2_return(completion_kind, helper_results)
	if not bool(handoff_plan.get("ok", false)) \
			or String(handoff_plan.get("status", "")) != "modeled_handoff_reached" \
			or int(handoff_plan.get("final_source_pc", -1)) != 0xC6BE:
		_route_gaps_add("Fresh-match source setup did not reach its checked `$C557->$C6BE` scheduler boundary.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	handoff_plan["source_frame"] = source_frame
	handoff_plan["caller_result"] = caller_result.duplicate(true)
	handoff_plan["ppu_clear"] = ppu_clear.duplicate(true)
	handoff_plan["oam_clear"] = oam_clear.duplicate(true)
	handoff_plan["helper_effects_executed_by_route"] = true
	handoff_plan["scheduler_runtime_entry"] = "RomFreshKickoffSourceRouteRunner.begin_from_context"
	handoff_plan["scheduler_runtime_started"] = false
	_fresh_match_handoff_result = handoff_plan.duplicate(true)
	_cutscene_wait_cleanup_result["fresh_match_handoff"] = handoff_plan.duplicate(true)
	if not _initialize_fresh_match_context() or not _begin_fresh_source_route():
		_route_gaps_add("Fresh-match scheduler could not start from the ROM-derived `$C6BE` handoff context.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_match_handoff_result["scheduler_runtime_started"] = true
	_fresh_match_handoff_result["scheduler_runtime_begin"] = _fresh_source_route_begin_result.duplicate(true)
	_fresh_match_handoff_result["scheduler_runtime_status"] = _fresh_source_route_runner.get_status()
	_fresh_match_handoff_result["source_frame_timing_verified"] = false
	_cutscene_wait_cleanup_result["fresh_match_handoff"] = _fresh_match_handoff_result.duplicate(true)
	_set_route_stage_from_source_runner()


func _advance_fresh_match_a64c_setup() -> void:
	if String(_fresh_match_caller_tail_result.get("status", "")) != "transferred_to_A64C":
		_route_gaps_add("The ROM `$A64C` setup has no checked `$A009` entry transfer.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var setup_executor: Variant = FRESH_PREMATCH_A64C_SETUP_SCRIPT.new()
	if not setup_executor.configure_from_project_sources():
		_route_gaps_add("ROM `$A64C` source failed verification: %s" % setup_executor.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var setup_plan: Dictionary = setup_executor.plan_initial_advice_scene(_source_ram_image, 0x01)
	if not bool(setup_plan.get("ok", false)):
		_route_gaps_add("ROM `$A64C` rejected the fresh-match source state: %s" % String(setup_plan.get("error", "unknown source error")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var clear_task: Variant = CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT.new()
	if not clear_task.configure_from_project_sources():
		_route_gaps_add("ROM `$98A0/$9B7F` helper sources failed verification: %s" % clear_task.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var ppu_clear: Dictionary = clear_task.execute_98a0_ppu_clear_only(
		_visuals, _get_source_ppu_shadow_input(), 0xA64C, 0xA64F)
	if not bool(ppu_clear.get("ok", false)):
		_route_gaps_add("ROM `$A64C->$98A0` PPU clear stopped: %s" % String(ppu_clear.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var ppu_event_id := "fresh_match_a64c_ppu_clear_%d" % source_frame
	if not _source_ram_image.merge_executor_result(ppu_event_id, ppu_clear) \
			or not _accept_cleanup_ppu_shadow_result(ppu_event_id, ppu_clear):
		_route_gaps_add("ROM `$A64C->$98A0` PPU shadows could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var oam_clear: Dictionary = clear_task.execute_direct_9b7f_oam_clear(
		ppu_clear.get("cpu_output_contract", {}), 0xA652)
	if not bool(oam_clear.get("ok", false)):
		_route_gaps_add("ROM `$A64F->$9B7F` OAM clear stopped: %s" % String(oam_clear.get("error", "source state rejected")))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var oam_event_id := "fresh_match_a64c_oam_clear_%d" % source_frame
	if not _source_ram_image.merge_executor_result(oam_event_id, oam_clear):
		_route_gaps_add("ROM `$A64F->$9B7F` OAM writes could not join source RAM: %s" % _source_ram_image.error_message)
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	setup_plan["ppu_clear"] = ppu_clear.duplicate(true)
	setup_plan["oam_clear"] = oam_clear.duplicate(true)
	setup_plan["ppu_clear_event_id"] = ppu_event_id
	setup_plan["oam_clear_event_id"] = oam_event_id
	setup_plan["scene_started_by_cutscene_vm"] = true
	setup_plan["cutscene_vm_cpu_execution"] = false
	setup_plan["route_start_source_frame"] = source_frame
	setup_plan["timing_verified"] = false
	_fresh_match_a64c_setup_result = setup_plan.duplicate(true)
	_fresh_match_caller_tail_result["status"] = "running_advice_scene_44"
	_fresh_match_caller_tail_result["a64c_setup"] = setup_plan.duplicate(true)
	_cutscene_wait_cleanup_result["fresh_match_a64c_setup"] = setup_plan.duplicate(true)
	_cutscene_wait_cleanup_result["status"] = "running_advice_scene_44"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0x82A9
	_cutscene_wait_cleanup_result["pending_helper_id"] = "wait_for_scene_return"
	_visuals.prepare_pre_match_meeting_scene()
	_start_cutscene(int(setup_plan.get("cutscene_id", -1)))


func _execute_source_clock_candidate_nmi(selector_result: Dictionary) -> Dictionary:
	var checkpoint: Dictionary = _fresh_match_selector_nmi_checkpoint.get("cpu_checkpoint", {})
	var read_contract: Dictionary = _fresh_match_selector_nmi_checkpoint.get(
		"pre_candidate_zero_mask_entry_ram_read_contract", {})
	var entry_p_receipt: Dictionary = _fresh_match_selector_nmi_checkpoint.get(
		"selector_call_entry_p_receipt", {})
	var source_event: Dictionary = {}
	for event_variant in _fresh_match_selector_scheduled_interrupts:
		if not event_variant is Dictionary:
			continue
		var event: Dictionary = event_variant
		if int(event.get("route_source_frame", -1)) == 7266 \
				and String(event.get("kind", "")) == "NMI" \
				and String(event.get("pc_before", "")) == "$A15B":
			source_event = event.duplicate(true)
			break
	if source_event.is_empty():
		return {"ok": false, "error": "The selector clock did not schedule the frame-7266 `$A15B` NMI event."}
	var executor: Variant = FRESH_MATCH_SPECIAL_NMI_EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		return {"ok": false, "error": "ROM NMI/vector source validation failed: %s" % executor.error_message}
	return executor.execute_source_clock_candidate_nmi(checkpoint, source_event,
		read_contract, _held_kickoff_input_bits, _get_source_ppu_shadow_input(),
		entry_p_receipt)


func _apply_normalizer_audio_stop(normalize_result: Dictionary) -> bool:
	var source_path: Array = normalize_result.get("source_path", [])
	var caller_writes: Array = normalize_result.get("caller_ram_writes", [])
	if not source_path.has(0x8107):
		return false
	var matching_write: Dictionary = {}
	for write_variant in caller_writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("source_pc", -1)) == 0x8109 \
				and int(write.get("address", -1)) == 0x0700 \
				and int(write.get("value", -1)) == 0x01:
			matching_write = write
			break
	if matching_write.is_empty():
		return false
	var audio_applied := cue_audio.apply_rom_sound_command(0x01, source_frame)
	_sound_queue_event_history.append({
		"source_pc": 0x8107,
		"receipt_source_pc": int(matching_write["source_pc"]),
		"address": int(matching_write["address"]),
		"queue_id": int(matching_write["value"]),
		"value": int(matching_write["value"]),
		"route_frame": source_frame,
		"rom_sha256": String(normalize_result.get("source_rom_sha256", "")),
		"effect": "stop_rom_audio",
		"timing_status": "ROM instruction order is sourced; subframe audio timing is unresolved.",
		"applied": audio_applied,
		"runtime_consumer": "GameplayRomCueAudioPresenter.apply_rom_sound_command",
	})
	return audio_applied


func _stop_match_selector_clock(message: String) -> bool:
	_route_gaps_add(message)
	route_stage = RouteStage.MATCH_SETUP_GAP
	route_stage_changed.emit(_stage_name())
	return false


func _get_fresh_match_selector_clock_status() -> Dictionary:
	return {
		"active": route_stage == RouteStage.MATCH_SELECTOR_RUNNING,
		"entry_source_frame": _fresh_match_selector_entry_frame,
		"progress": _fresh_match_selector_progress.duplicate(true),
		"scheduled_interrupt_events": _fresh_match_selector_scheduled_interrupts.duplicate(true),
		"clock": _fresh_match_selector_clock.get_status() if _fresh_match_selector_clock != null else {},
	}


func _begin_pre_match_meeting_scene() -> void:
	if route_stage != RouteStage.MATCHUP_PRESENTATION:
		return
	_visuals.prepare_pre_match_meeting_scene()
	_start_cutscene(0x44)


func _install_meeting_menu() -> void:
	_meeting_menu_input = MEETING_MENU_INPUT_SCRIPT.new() as Node
	_meeting_menu_input.name = "PreMatchMeetingMenuInput"
	add_child(_meeting_menu_input)
	_meeting_menu_input.set_process(false)
	_meeting_menu_input.connect("selection_changed", Callable(self, "_on_meeting_menu_selection_changed"))
	_meeting_menu_input.connect("option_confirmed", Callable(self, "_on_meeting_menu_option_confirmed"))
	_meeting_menu_input.call("reset_selection")
	if not _visuals.present_pre_match_meeting_menu(int(_meeting_menu_input.get("cursor_y"))):
		_route_gaps_add("The source MEETING cursor could not be rendered.")
	route_stage = RouteStage.MEETING_MENU
	route_stage_changed.emit(_stage_name())


func _on_meeting_menu_selection_changed(_option_index: int, cursor_y: int) -> void:
	if is_instance_valid(_visuals):
		_visuals.set_pre_match_meeting_cursor_y(cursor_y)


func _on_meeting_menu_option_confirmed(option_index: int) -> void:
	# Menu offsets 0/2/4/6 are Bilgi/Şifre/Veri/Başla. The slice follows only $06.
	if option_index != 3 or route_stage != RouteStage.MEETING_MENU:
		return
	if is_instance_valid(_meeting_menu_input):
		_meeting_menu_input.queue_free()
		_meeting_menu_input = null
	# The direct $812C/$812F $55 write is not this menu callback. It can only
	# be emitted by a future source-task runner when that ROM instruction is
	# actually reached; do not attach it to the user's MEETING confirmation.
	call_deferred("_start_cutscene", 0x56)


## Build source-owned match-zero context before the scenario-$35 A/B poll.
## The caller/timing path is still folded; no endpoint RAM is accepted.
func _initialize_fresh_match_context() -> bool:
	_fresh_match_context.clear()
	_fresh_scheduler_dispatch.clear()
	_fresh_period_task_status.clear()
	_fresh_entry_context = null
	_initial_player_positions.clear()
	var entry_builder: Variant = FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT.new()
	if not entry_builder.configure_from_project_sources():
		_route_gaps_add("Fresh KICK OFF context source unavailable: %s" % entry_builder.error_message)
		return false
	_fresh_entry_context = entry_builder.call("build_fresh_kickoff_context")
	if _fresh_entry_context == null:
		_route_gaps_add("Fresh KICK OFF context could not be derived: %s" % entry_builder.error_message)
		return false
	var selector_receipt: Dictionary = _fresh_match_selector_context.get("selector_result", {})
	if selector_receipt.is_empty():
		_route_gaps_add("Fresh-match route has no completed ROM selector receipt for the player records.")
		return false
	_fresh_entry_context.selector_roster_write_receipt = selector_receipt.duplicate(true)
	_fresh_entry_context.stamina_initialization_receipt = _fresh_match_stamina_result.duplicate(true)
	_fresh_scheduler_dispatch = _fresh_entry_context.scheduler_dispatch.duplicate(true)
	var period_task = FRESH_PERIOD_TASK_SCRIPT.new()
	if not period_task.configure_from_project_sources():
		_route_gaps_add("Fresh-period ROM source unavailable: %s" % period_task.error_message)
		return false
	var period_inputs: Dictionary = _fresh_entry_context.to_period_task_inputs()
	var period_result: Dictionary = period_task.execute_fresh_match_zero(period_inputs)
	if not bool(period_result.get("ok", false)):
		_route_gaps_add("Fresh-period ROM task did not reach $DAAA: %s" % period_task.error_message)
		return false
	_fresh_period_task_status = period_result.duplicate(true)
	var period_ram: Dictionary = period_result.get("ram", {})
	var kickoff_selector := int(period_ram.get("$0629", -1))
	if kickoff_selector < 0:
		_route_gaps_add("Fresh-period task did not produce selector $0629.")
		return false
	var context_resolver = FRESH_MATCH_CONTEXT_RESOLVER_SCRIPT.new()
	if not context_resolver.configure():
		_route_gaps_add("Fresh match context source unavailable: %s" % context_resolver.error_message)
		return false
	var context_result: Dictionary = context_resolver.resolve_fresh_match_context(
		_fresh_entry_context.match_index, kickoff_selector, _fresh_entry_context.provenance)
	if not bool(context_result.get("ok", false)):
		_route_gaps_add("Fresh match context could not be derived: %s" % str(context_result.get("error", "unknown source error")))
		return false
	_fresh_match_context = context_result.duplicate(true)
	_route_gaps_add("Fresh-match source state is folded through the bounded bootstrap, slot-$01 startup, slot-$05 period task, and DB24 resolver; callback scheduling and absolute ROM timing remain unexecuted.")
	return true


## Starts the source-owned task composition from the route's already-derived
## entry context. The runner returns after the slot-$09 first yield; it does
## not synthesize the next NMI or actor-call result.
func _begin_fresh_source_route() -> bool:
	_fresh_source_route_runner = FRESH_SOURCE_ROUTE_RUNNER_SCRIPT.new()
	_fresh_source_route_begin_result.clear()
	_fresh_source_route_nmi_result.clear()
	_fresh_source_route_task_result.clear()
	_fresh_source_route_nmi_abstraction_count = 0
	_fresh_source_route_nmi_timing_note = ""
	if not _fresh_source_route_runner.configure_from_project_sources():
		_route_gaps_add("First-match source runner could not load packaged ROM sources: %s" % _fresh_source_route_runner.error_message)
		return false
	_fresh_source_route_begin_result = _fresh_source_route_runner.begin_from_context(_fresh_entry_context)
	if not bool(_fresh_source_route_begin_result.get("ok", false)) \
			or String(_fresh_source_route_begin_result.get("last_source_boundary", "")) != "$EB8B" \
			or not bool(_fresh_source_route_begin_result.get("awaiting_external_nmi", false)):
		_route_gaps_add("First-match source runner did not reach the verified slot-$09 `$EB8B` boundary: %s" % String(_fresh_source_route_begin_result.get("error", _fresh_source_route_runner.error_message)))
		return false
	var initial_daaa_result: Dictionary = _fresh_source_route_begin_result.get(
		"initial_daaa_continuation_result", {})
	var initial_daaa_event: RefCounted = RomSoundQueueWriteEvent.new()
	if not bool(initial_daaa_event.call("populate_from_fresh_daaa_queue_insert",
			initial_daaa_result, source_frame)):
		_route_gaps_add("ROM `$DAAA->$CBF1->$CC01` audio queue request failed its source-event checks.")
		return false
	var initial_daaa_event_data: Dictionary = initial_daaa_event.call("to_dictionary")
	initial_daaa_event_data["source_role"] = "fresh_match_initial_daaa_queue"
	_sound_queue_event_history.append(initial_daaa_event_data)
	rom_sound_queue_write_requested.emit(initial_daaa_event)
	_fresh_source_route_nmi_timing_note = "Frame-level normal-NMI abstractions follow Godot NES_FPS ticks while the ROM-derived `$2000` shadow enables NMI; beam and CPU-cycle phase are unknown."
	return true


## The route currently has no PPU beam/cycle phase. While the ROM-derived
## `$2000` shadow enables NMI, this adapter supplies one normal-NMI abstraction
## per NES-frame source tick. It accepts only source-runner transitions and
## drains supported selected-task bodies until the next external NMI boundary.
## Returned source PPU bus events are applied to the current renderer, but this
## does not claim dot/cycle timing or a complete field composition.
func _advance_fresh_source_route_frame_level_nmi(controller_sample: Dictionary = {}) -> void:
	if _fresh_source_route_runner == null:
		_route_gaps_add("Frame-level NMI abstraction has no configured source route runner.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var source_status: Dictionary = _fresh_source_route_runner.get_status()
	var scheduler_status: Dictionary = source_status.get("scheduler", {})
	var ppu_ctrl_shadow := int(scheduler_status.get("live_ppu_ctrl_shadow", -1))
	if ppu_ctrl_shadow < 0 or (ppu_ctrl_shadow & 0x80) == 0:
		_route_gaps_add("Live ROM `$2000` shadow does not enable NMI; no frame-level NMI abstraction was issued.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_source_route_nmi_result = _fresh_source_route_runner.advance_on_external_nmi(
		source_frame, ppu_ctrl_shadow)
	if String(_fresh_source_route_nmi_result.get("status", "")) == "stopped_at_slot05_dc07_call_boundary":
		_fresh_source_route_task_result = _fresh_source_route_runner.resume_slot05_dc07_position_initializer(
			_fresh_match_context)
		if not bool(_fresh_source_route_task_result.get("ok", false)):
			_route_gaps_add("Live ROM `$DC07` position initialization failed: %s" % String(
				_fresh_source_route_task_result.get("error", _fresh_source_route_runner.error_message)))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var initializer_result: Dictionary = _fresh_source_route_task_result.get("initializer_result", {})
		_initial_player_positions.clear()
		for position_variant in initializer_result.get("positions", []):
			if position_variant is Dictionary:
				_initial_player_positions.append(position_variant.duplicate(true))
		var receiver_result: Dictionary = _fresh_source_route_runner.resume_slot05_daf5_receiver_caller(
			_fresh_match_context)
		if not bool(receiver_result.get("ok", false)):
			_route_gaps_add("Live ROM `$DAF5` receiver selection failed: %s" % String(
				receiver_result.get("error", _fresh_source_route_runner.error_message)))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var holder_result: Dictionary = _fresh_source_route_runner.resume_slot05_e6ec_holder_copy(
			_fresh_match_context)
		if not bool(holder_result.get("ok", false)):
			_route_gaps_add("Live ROM `$E6EC` holder copy failed: %s" % String(
				holder_result.get("error", _fresh_source_route_runner.error_message)))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		holder_result["position_initializer_result"] = initializer_result.duplicate(true)
		holder_result["receiver_result"] = receiver_result.get("receiver_result", {}).duplicate(true)
		var scenario36_result: Dictionary = _fresh_source_route_runner.resume_slot05_scenario36_enqueue()
		if not bool(scenario36_result.get("ok", false)):
			_route_gaps_add("Live ROM scenario-$36 queue/yield failed: %s" % String(
				scenario36_result.get("error", _fresh_source_route_runner.error_message)))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		scenario36_result["position_initializer_result"] = initializer_result.duplicate(true)
		scenario36_result["receiver_result"] = receiver_result.get("receiver_result", {}).duplicate(true)
		scenario36_result["holder_copy_result"] = holder_result.get("holder_copy_result", {}).duplicate(true)
		_fresh_source_route_task_result = scenario36_result
	if not bool(_fresh_source_route_nmi_result.get("ok", false)) \
			or not bool(_fresh_source_route_nmi_result.get("external_nmi_consumed", false)):
		var nmi_failure := String(_fresh_source_route_nmi_result.get("error",
			_fresh_source_route_nmi_result.get("reason", _fresh_source_route_runner.error_message)))
		if nmi_failure.is_empty():
			nmi_failure = JSON.stringify({
				"status": _fresh_source_route_nmi_result.get("status", "missing"),
				"phase": _fresh_source_route_nmi_result.get("phase", "missing"),
				"ok": _fresh_source_route_nmi_result.get("ok", false),
				"external_nmi_consumed": _fresh_source_route_nmi_result.get("external_nmi_consumed", false),
				"last_source_boundary": _fresh_source_route_runner.get_status().get("last_source_boundary", "missing"),
				"result_keys": _fresh_source_route_nmi_result.keys(),
			})
		_route_gaps_add("Source runner rejected the caller-supplied frame-level NMI: %s" % nmi_failure)
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_emit_cbf1_audio_events_from_source_result(_fresh_source_route_nmi_result)
	var ppu_bus_events: Variant = _fresh_source_route_nmi_result.get("ppu_bus_events", [])
	if not ppu_bus_events is Array:
		_route_gaps_add("ROM source NMI returned a malformed PPU bus-event list.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var ppu_render_result: Dictionary = _visuals.apply_source_ppu_bus_events(
		ppu_bus_events, ppu_ctrl_shadow)
	if not bool(ppu_render_result.get("ok", false)):
		_route_gaps_add("ROM source PPU bus events could not be applied to the runtime renderer: %s" % String(ppu_render_result.get("error", "unknown PPU error")))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_source_route_nmi_result["ppu_bus_events_applied"] = true
	_fresh_source_route_nmi_result["ppu_render_result"] = ppu_render_result.duplicate(true)
	if not bool(ppu_render_result.get("unapplied_writes", []).is_empty()):
		_route_gaps_add("ROM source PPU packet has writes the current renderer does not represent: %s" % str(ppu_render_result.get("unapplied_writes", [])))
	_fresh_source_route_nmi_abstraction_count += 1
	_fresh_source_route_nmi_timing_note = "Issued %d frame-level normal-NMI abstractions at source frame %d using live ROM `$2000` shadow `$%02X`; no beam/dot/cycle phase is modeled." % [_fresh_source_route_nmi_abstraction_count, source_frame, ppu_ctrl_shadow]
	_set_route_stage_from_source_runner()
	if route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
		var task_controller_sample := controller_sample.duplicate(true)
		var runner_status: Dictionary = _fresh_source_route_runner.get_status()
		if String(runner_status.get("phase", "")) == "pass_receiver_input_ready" \
				and not task_controller_sample.has("sample_receipt_id"):
			var input_result: Dictionary = _fresh_source_route_runner.sample_controller_input(
				_held_kickoff_input_bits)
			if not bool(input_result.get("ok", false)):
				_route_gaps_add("The newly restored ROM `$D80F` wait could not sample its same-frame controller input: %s" % String(input_result.get("error", "unknown input sampling error")))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			task_controller_sample = input_result.get("sample", {}).duplicate(true)
			task_controller_sample["source_frame_label"] = source_frame
		_advance_fresh_source_route_selected_tasks(task_controller_sample)


func _advance_fresh_source_route_selected_tasks(controller_sample: Dictionary = {}) -> void:
	if _fresh_source_route_runner == null:
		_route_gaps_add("Selected-task continuation has no configured source route runner.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var waitflag_watch_enabled := OS.get_environment("CT2_RAM_062D_WATCH").strip_edges() == "1"
	var waitflag_watch_from_text := OS.get_environment("CT2_RAM_062D_WATCH_FROM").strip_edges()
	var waitflag_watch_from := int(waitflag_watch_from_text) if not waitflag_watch_from_text.is_empty() else 9300
	var waitflag_watch_to_text := OS.get_environment("CT2_RAM_062D_WATCH_TO").strip_edges()
	var waitflag_watch_to := int(waitflag_watch_to_text) if not waitflag_watch_to_text.is_empty() else 9470
	for source_step in range(16):
		var runner_status: Dictionary = _fresh_source_route_runner.get_status()
		var phase := String(runner_status.get("phase", ""))
		if phase == "pass_receiver_input_ready":
			if not controller_sample.has("sample_receipt_id"):
				# An NMI can restore slot `$05` to `$D80F` partway through this
				# source-frame task drain. The earlier frame-level sampler ran while
				# the task was still at `$CB0F`, so it intentionally deferred input;
				# sample now that the scheduler has actually restored the input wait.
				var restored_wait_sample: Dictionary = _fresh_source_route_runner.sample_controller_input(
					_held_kickoff_input_bits)
				if not bool(restored_wait_sample.get("ok", false)):
					_route_gaps_add("The scheduler-restored ROM `$D80F` wait could not sample its controller input: %s" % String(restored_wait_sample.get("error", "unknown input sampling error")))
					route_stage = RouteStage.SOURCE_ROUTE_GAP
					route_stage_changed.emit(_stage_name())
					return
				controller_sample = restored_wait_sample.get("sample", {}).duplicate(true)
				controller_sample["source_frame_label"] = source_frame
			_fresh_source_route_task_result = _fresh_source_route_runner.resolve_pass_receiver_source_poll(
				controller_sample, source_frame)
			if not bool(_fresh_source_route_task_result.get("ok", false)):
				_route_gaps_add("Live ROM `$D80F` PASS receiver input poll stopped: %s" % String(
					_fresh_source_route_task_result.get("error", _fresh_source_route_runner.error_message)))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			_set_route_stage_from_source_runner()
			return
		if phase == "pass_receiver_descriptor_1d_pending":
			_set_route_stage_from_source_runner()
			return
		if phase == "pass_receiver_confirmed_at_d70c":
			if not _fresh_source_route_runner.has_method("resume_pass_receiver_confirmation_wait"):
				_route_gaps_add("The ordinary A edge reached live ROM `$D70C`, but the source-derived confirmation waiter is not exposed by the route runner.")
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			_fresh_source_route_task_result = _fresh_source_route_runner.resume_pass_receiver_confirmation_wait()
			if not bool(_fresh_source_route_task_result.get("ok", false)):
				_route_gaps_add("The ROM-derived PASS confirmation waiter stopped after `$D70C`: %s" % String(
					_fresh_source_route_task_result.get("error", _fresh_source_route_runner.error_message)))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			_emit_cbf1_audio_events_from_source_result(_fresh_source_route_task_result)
			_set_route_stage_from_source_runner()
			if route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
				continue
			return
		if phase == "stopped_at_slot05_descriptor01_next_row_boundary":
			_fresh_source_route_task_result = _fresh_source_route_runner.resume_slot05_descriptor01_ee_row00()
			if not bool(_fresh_source_route_task_result.get("ok", false)):
				_route_gaps_add("Selected slot `$05` stopped before its source-backed `$EE 00 FC` row: %s" % String(_fresh_source_route_task_result.get("error", _fresh_source_route_runner.error_message)))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			continue
		if phase == "stopped_after_slot05_descriptor01_ee_row00_yield":
			_fresh_source_route_task_result = _fresh_source_route_runner.save_slot05_ee_row_yield_and_scan()
			if not bool(_fresh_source_route_task_result.get("ok", false)):
				_route_gaps_add("Scheduler rejected the live slot `$05` `$EE 00 FC -> $C515` save: %s" % String(_fresh_source_route_task_result.get("error", _fresh_source_route_runner.error_message)))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
			_set_route_stage_from_source_runner()
			if route_stage != RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
				return
			continue
		if phase == "awaiting_external_nmi":
			_set_route_stage_from_source_runner()
			return
		if phase != "waiting_for_selected_task_source" and phase != "waiting_for_slot09_eb8b_source":
			_route_gaps_add("Source runner stopped at unsupported task phase `%s`: %s" % [phase, String(runner_status.get("source_boundary", "unknown boundary"))])
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var selected_slot := int(runner_status.get("pending_selected_task_slot", -1))
		if selected_slot < 0:
			selected_slot = int(_fresh_source_route_nmi_result.get("next_selected_task_slot", -1))
		if selected_slot < 0:
			selected_slot = int(_fresh_source_route_task_result.get("next_selected_task_slot", -1))
		match selected_slot:
			0x01:
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot01_worker()
			0x05:
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot05_worker(
					controller_sample)
				if waitflag_watch_enabled and source_frame >= waitflag_watch_from \
						and source_frame <= waitflag_watch_to:
					var slot05_worker: Dictionary = _fresh_source_route_task_result.get(
						"slot05_worker_result", {})
					var slot05_boundary: Dictionary = _fresh_source_route_task_result.get(
						"slot05_live_boundary", {})
					var scenario1e_trace_pcs := {
						0xCC50: true, 0xCC53: true, 0xCCA0: true, 0xCCA3: true,
						0xCCCE: true, 0xCCD1: true, 0x82E3: true,
						0xE247: true, 0xE267: true, 0xE252: true,
					}
					var scenario1e_instructions: Array[Dictionary] = []
					for instruction_variant in slot05_worker.get("instructions", []):
						if not instruction_variant is Dictionary:
							continue
						var instruction: Dictionary = instruction_variant
						if scenario1e_trace_pcs.has(int(instruction.get("pc", -1))):
							scenario1e_instructions.append(instruction.duplicate(true))
					var scenario1e_calls: Array[Dictionary] = []
					for call_variant in slot05_worker.get("calls", []):
						if not call_variant is Dictionary:
							continue
						var call_record: Dictionary = call_variant
						if scenario1e_trace_pcs.has(int(call_record.get("callsite", -1))) \
								or scenario1e_trace_pcs.has(int(call_record.get("target", -1))):
							scenario1e_calls.append(call_record.duplicate(true))
					if not scenario1e_instructions.is_empty() or not scenario1e_calls.is_empty():
						print("SCENARIO_1E_SLOT05_TRACE " + JSON.stringify({
							"source_frame": source_frame,
							"worker_status": slot05_worker.get("status", ""),
							"source_dispatch": slot05_worker.get("source_dispatch", {}),
							"slot05_boundary_pc": slot05_boundary.get("pc", -1),
							"slot05_record": (slot05_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
							"instructions": scenario1e_instructions,
							"calls": scenario1e_calls,
						}))
					var slot05_record: Variant = slot05_boundary.get("record", PackedByteArray())
					for write_variant in slot05_worker.get("writes", []):
						if not write_variant is Dictionary:
							continue
						if int((write_variant as Dictionary).get("address", -1)) != 0x062D:
							continue
						print("RAM_062D_SLOT05_WORKER " + JSON.stringify({
							"source_frame": source_frame,
							"selected_slot": selected_slot,
							"worker_status": slot05_worker.get("status", ""),
							"write": write_variant,
							"source_dispatch": slot05_worker.get("source_dispatch", {}),
						"slot05_dispatch": {
							"pc": _fresh_source_route_task_result.get("slot05_dispatch", {}).get("pc", -1),
							"sp": _fresh_source_route_task_result.get("slot05_dispatch", {}).get("sp", -1),
							"a": _fresh_source_route_task_result.get("slot05_dispatch", {}).get("a", -1),
							"x": _fresh_source_route_task_result.get("slot05_dispatch", {}).get("x", -1),
							"y": _fresh_source_route_task_result.get("slot05_dispatch", {}).get("y", -1),
						},
						"slot05_boundary": {
							"pc": slot05_boundary.get("pc", -1),
							"sp": slot05_boundary.get("sp", -1),
							"ready_delay": slot05_boundary.get("ready_delay", -1),
							"a": slot05_boundary.get("a", -1),
							"x": slot05_boundary.get("x", -1),
							"y": slot05_boundary.get("y", -1),
							"record": (slot05_record as PackedByteArray).hex_encode() \
								if slot05_record is PackedByteArray else "invalid",
						},
							"next_selected_task_slot": _fresh_source_route_task_result.get("next_selected_task_slot", -1),
						"calls": slot05_worker.get("calls", []),
						}))
			0x09:
				if not _fresh_source_route_runner.has_method("resume_selected_slot09_worker"):
					_route_gaps_add("Slot `$09` is selected at its yielded boundary, but its live worker continuation is not yet integrated.")
					route_stage = RouteStage.SOURCE_ROUTE_GAP
					route_stage_changed.emit(_stage_name())
					return
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot09_worker()
				if waitflag_watch_enabled and source_frame >= waitflag_watch_from \
						and source_frame <= waitflag_watch_to:
					var scenario0519_writes: Array[Dictionary] = []
					for result_key in ["slot09_resume_result", "slot09_86f8_worker_result",
							"slot09_8779_worker_result", "slot09_87e6_worker_result",
							"slot09_ebd7_root_zero_result"]:
						var worker_result: Variant = _fresh_source_route_task_result.get(
							result_key, {})
						if not worker_result is Dictionary:
							continue
						for write_variant in worker_result.get("writes", []):
							if not write_variant is Dictionary:
								continue
							var write_record: Dictionary = write_variant
							if int(write_record.get("address", -1)) in [0x0519, 0x0523]:
								var source_ram_variant: Variant = worker_result.get(
									"ram_image", PackedByteArray())
								var source_0523 := int(source_ram_variant[0x0523]) \
									if source_ram_variant is PackedByteArray \
									and source_ram_variant.size() == 0x800 else -1
								var source_044e := int(source_ram_variant[0x044E]) \
									if source_ram_variant is PackedByteArray \
									and source_ram_variant.size() == 0x800 else -1
								var source_00e2 := int(source_ram_variant[0x00E2]) \
									if source_ram_variant is PackedByteArray \
									and source_ram_variant.size() == 0x800 else -1
								var source_instructions: Variant = worker_result.get(
									"instruction_pcs", [])
								scenario0519_writes.append({"result": result_key,
									"write": write_record.duplicate(true),
									"ram_0523_after": source_0523,
									"ram_044e": source_044e,
									"ram_00e2": source_00e2,
									"executed_ec94": source_instructions is Array \
										and source_instructions.has(0xEC94)})
					if not scenario0519_writes.is_empty():
						print("SCENARIO_SLOT09_SOURCE_WRITES " + JSON.stringify({
							"source_frame": source_frame,
							"selected_slot": selected_slot,
							"writes": scenario0519_writes,
							"source_boundary": _fresh_source_route_runner.get_status().get(
								"source_boundary", ""),
						}))
			0x11:
				if not _fresh_source_route_runner.has_method("resume_selected_slot11_worker"):
					_route_gaps_add("Slot `$11` is selected at its seeded actor-worker boundary, but its live worker continuation is not yet integrated.")
					route_stage = RouteStage.SOURCE_ROUTE_GAP
					route_stage_changed.emit(_stage_name())
					return
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot11_worker()
			0x15:
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot15_source_task()
			_:
				_route_gaps_add("The scheduler selected unsupported task slot `$%02X` at the live source boundary." % selected_slot)
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
		if not bool(_fresh_source_route_task_result.get("ok", false)):
			_route_gaps_add("Selected task `$%02X` stopped before its source-supported boundary: %s" % [selected_slot, String(_fresh_source_route_task_result.get("error", _fresh_source_route_runner.error_message))])
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var pass_receiver_input_adoption: Variant = _fresh_source_route_task_result.get(
			"source_input_adoption", {})
		if not _deferred_pass_receiver_controller_sample.is_empty() \
				and pass_receiver_input_adoption is Dictionary \
				and int(pass_receiver_input_adoption.get("sample_receipt_id", -1)) \
				== int(_deferred_pass_receiver_controller_sample.get("sample_receipt_id", -2)):
			_deferred_pass_receiver_controller_sample.clear()
		var receiver_renderer_receipt: Variant = _fresh_source_route_task_result.get(
			"renderer_return_receipt", {})
		if receiver_renderer_receipt is Dictionary \
				and String(receiver_renderer_receipt.get("status", "")) == "pass_receiver_renderer_return_route_receipt" \
				and not bool(receiver_renderer_receipt.get("trace_state_used", true)) \
				and not bool(receiver_renderer_receipt.get("test_fixture", true)) \
				and is_instance_valid(_visuals) \
				and String(_visuals.pass_receiver_menu_status.get("state", "")) != "presented":
			if not _visuals.present_pass_receiver_menu():
				_route_gaps_add("ROM-built PASS receiver panel could not be presented after the source renderer return: %s" % str(_visuals.pass_receiver_menu_status))
				route_stage = RouteStage.SOURCE_ROUTE_GAP
				route_stage_changed.emit(_stage_name())
				return
		_emit_cbf1_audio_events_from_source_result(_fresh_source_route_task_result)
		_set_route_stage_from_source_runner()
		if route_stage == RouteStage.FIRST_ACTION_MENU_PENDING:
			_install_first_action_menu_from_source_provider()
			return
		if route_stage != RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
			return
	_route_gaps_add("Source task chain exceeded the bounded per-NMI continuation limit.")
	route_stage = RouteStage.SOURCE_ROUTE_GAP
	route_stage_changed.emit(_stage_name())


func _set_route_stage_from_source_runner() -> void:
	if _fresh_source_route_runner == null:
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		return
	var runner_status: Dictionary = _fresh_source_route_runner.get_status()
	var phase := String(runner_status.get("phase", ""))
	var next_stage := RouteStage.SOURCE_ROUTE_GAP
	if phase == "awaiting_external_nmi":
		next_stage = RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI
	elif phase == "first_action_menu_ready":
		next_stage = RouteStage.FIRST_ACTION_MENU_PENDING
	elif phase == "pass_receiver_descriptor_1d_pending":
		_route_gaps_add("Ordinary Down reached the ROM `$D96C->$EF7F` descriptor `$1D` call and changed the live receiver candidate, but the descriptor-$1D `$800C` worker, `$C515` queue wait, and real NMI/PPU transfer are not integrated.")
		next_stage = RouteStage.PASS_RECEIVER_RENDERER_PENDING
	elif phase == "pass_receiver_confirmed_at_d70c":
		# The live `$D70C` confirmation is an intermediate ROM boundary: drain
		# its `$CC46->$CC50->$CB0F` waiter before classifying the route endpoint.
		next_stage = RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE
	elif phase == "pass_receiver_input_ready":
		next_stage = RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE
	elif phase in ["first_action_pass_label_ready", "first_action_pass_dispatch_ready",
			"first_action_pass_handler_ready", "first_action_pass_cb0f_ready"]:
		next_stage = RouteStage.FIRST_ACTION_HANDLER_PENDING
	elif phase in ["waiting_for_selected_task_source", "waiting_for_slot09_eb8b_source",
			"stopped_at_slot05_descriptor01_next_row_boundary",
			"stopped_after_slot05_descriptor01_ee_row00_yield"]:
		next_stage = RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE
	elif phase == "stopped_at_slot05_dc07_call_boundary":
		_route_gaps_add("The recorded A/B input reaches the ROM `$DAF2->$DC07` call, but the live position initializer has not returned.")
	elif phase == "stopped_at_slot05_daf5_position_return_boundary":
		_route_gaps_add("ROM `$DC07` returned at `$DAF5`; its receiver-selection caller has not run.")
	elif phase == "stopped_at_slot05_e6ec_holder_call_boundary":
		_route_gaps_add("ROM `$DAF5` selected the receiver from live `$E2` and called `$E6EC`; its holder-copy callee has not run.")
	elif phase == "stopped_before_scenario36_slot09_dispatch":
		_route_gaps_add("ROM `$DB0E->$CBB0` queued scenario `$36`; `$CB0F` saved slot `$05`, then the scheduler selected slot `$09`. Scenario event execution, field rendering, and the first command menu remain ahead.")
	elif phase == "stopped_at_scenario36_ec74_return":
		_route_gaps_add("Scenario `$36` consumed its first `$F5/$F9` and `$10 3A 8F F0` event from ROM bytes; slot `$15` is seeded and slot `$09` returned `$EC74->$EB9E`. Its callback, visible field construction, and first command menu remain ahead.")
	elif phase == "stopped_at_scenario36_unexpected_task_selection":
		_route_gaps_add("After scenario `$36` slot `$05` yielded at `$CB0F`, the live scheduler selected an unhandled task slot.")
	elif phase == "stopped_at_scenario36_post_yield_scheduler_boundary":
		_route_gaps_add("Scenario `$36` slot `$05` yielded at `$CB0F`, but its post-yield scheduler decision is not yet handled.")
	elif phase == "stopped_at_scenario36_bank18_renderer_entry":
		_route_gaps_add("The source-executed `$E0DF->$EF7F->$800C` descriptor-$00 call now reaches the bank-$18 renderer entry. Its worker, PPU queue effects, descriptor-$01 call, field loop, and first command menu remain ahead.")
	elif phase == "stopped_after_scenario36_descriptor00_worker_yield":
		_route_gaps_add("The descriptor-$00 `$800C->$8851->$8886->$C515->$CB0F` worker now runs from its live ROM wrapper result and saves into the scheduler. The next selected task/PPU queue submission, descriptor-$01 call, visible field, and first command menu remain ahead.")
	elif phase == "stopped_at_scenario36_e0df_handoff":
		_route_gaps_add("Scenario `$36` returned through the ROM `$DB13->$E0DF` handoff, including the live `$05FC->$0441` holder and `$05FD=1` stores. The `$E0DF` field-entry routine and first command menu remain ahead.")
	elif phase == "stopped_at_scenario44_field_source_boundary":
		var field_entry: Dictionary = _fresh_source_route_task_result.get("scenario44_field_entry_result", {})
		var blocked_read: Dictionary = field_entry.get("blocked_read", {})
		_route_gaps_add("Scenario `$44` returned through `$E38F->$8003`; the ROM-byte field entry then stopped before mapped source `$%04X` in bank `$%02X`: %s. Its source bytes/behavior are the next transition." % [
			int(blocked_read.get("requested_address", field_entry.get("exit_pc", -1))),
			int(blocked_read.get("bank", field_entry.get("exit_bank", -1))),
			String(blocked_read.get("reason", field_entry.get("error", "source boundary")))])
	elif phase == "stopped_at_scenario44_field_entry_call_boundary":
		var field_entry: Dictionary = _fresh_source_route_task_result.get("scenario44_field_entry_result", {})
		_route_gaps_add("Scenario `$44` field entry reached ROM call boundary `$%04X`; its callee and subsequent field/menu state remain unexecuted." % int(field_entry.get("exit_pc", -1)))
	elif phase == "stopped_before_slot05_worker":
		var task_reason := String(_fresh_source_route_task_result.get("reason", ""))
		var worker_result: Dictionary = _fresh_source_route_task_result.get("slot05_worker_result", {})
		var stopped_pc := int(worker_result.get("exit_pc", -1))
		var calls: Array = worker_result.get("calls", [])
		var last_call: Dictionary = calls.back() if not calls.is_empty() else {}
		var trace_tail: Array[String] = []
		var instructions: Array = worker_result.get("instructions", [])
		for index in range(maxi(0, instructions.size() - 8), instructions.size()):
			var instruction_variant: Variant = instructions[index]
			if instruction_variant is Dictionary:
				var instruction: Dictionary = instruction_variant
				trace_tail.append("$%04X/bank$%02X->$%04X[%02X]" % [
					int(instruction.get("pc", -1)), int(instruction.get("bank", -1)),
					int(instruction.get("next_pc", -1)), int(instruction.get("opcode", -1))])
		_route_gaps_add("Slot-$05 ROM worker stopped at `$%04X` (%s): %s; last call `$%04X->$%04X` bank `$%02X`, trace=%s" % [
			stopped_pc, String(_fresh_source_route_task_result.get("status", "unknown")),
			task_reason if not task_reason.is_empty() else "source stop reason was not recorded",
			int(last_call.get("callsite", -1)), int(last_call.get("target", -1)),
			int(last_call.get("bank", -1)), str(trace_tail),
		])
	if route_stage != next_stage:
		route_stage = next_stage
		route_stage_changed.emit(_stage_name())


func _install_first_action_menu_from_source_provider() -> void:
	if _fresh_source_route_runner == null:
		_route_gaps_add("First-action menu has no live ROM source route boundary.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	var provider: Variant = _fresh_source_route_runner.create_match_player_state_provider()
	if provider == null or not provider is RomFreshKickoffMatchStateProvider \
			or not bind_match_player_state_provider(provider):
		_route_gaps_add("First-action menu could not bind the ROM-derived controlled-player state: %s" % String(_fresh_source_route_runner.error_message))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	if not install_first_action_menu_from_provider():
		_route_gaps_add("First-action menu source event arrived, but the ROM-derived panel or dynamic player rows are incomplete.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())


func _on_vm_error(message: String) -> void:
	push_error("KICK OFF route stopped at a source VM error: " + message)


func _on_action_selection_changed(action_id: int, direction_index: int) -> void:
	_action_label_blink_ticks_remaining = ACTION_LABEL_BLINK_TICKS
	_action_label_blink_visible = true
	if is_instance_valid(_visuals):
		_visuals.set_first_action_menu_selection(action_id, _action_label_blink_visible)
	action_selection_changed.emit(action_id, direction_index)


func _on_action_confirmation_requested(action_id: int) -> void:
	# Signal only; this vertical slice must stop before resolving the soccer action.
	action_confirmation_requested.emit(action_id)


func _advance_action_label_blink() -> void:
	if not is_instance_valid(_menu_input) or _menu_input.selected_action_id == FirstActionMenuInput.ActionId.NONE:
		return
	_action_label_blink_ticks_remaining -= 1
	if _action_label_blink_ticks_remaining > 0:
		return
	_action_label_blink_ticks_remaining = ACTION_LABEL_BLINK_TICKS
	_action_label_blink_visible = not _action_label_blink_visible
	if is_instance_valid(_visuals):
		_visuals.set_first_action_menu_selection(
			_menu_input.selected_action_id,
			_action_label_blink_visible
		)


func _stage_name() -> String:
	match route_stage:
		RouteStage.TITLE_HANDOFF_FADE:
			return "title_handoff_fade"
		RouteStage.CUTSCENE_1:
			return "cutscene_1"
		RouteStage.MATCHUP_PRESENTATION:
			return "matchup_presentation"
		RouteStage.MEETING_SCENE:
			return "meeting_scene"
		RouteStage.MEETING_MENU:
			return "meeting_menu"
		RouteStage.CUTSCENE_56:
			return "cutscene_56"
		RouteStage.CUTSCENE_56_NATURAL_WAIT:
			return "cutscene_56_natural_wait"
		RouteStage.CUTSCENE_2:
			return "cutscene_2"
		RouteStage.CUTSCENE_CLEANUP_FADE:
			return "cutscene_cleanup_fade"
		RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI:
			return "source_route_waiting_for_nmi"
		RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
			return "source_route_waiting_for_task_source"
		RouteStage.SOURCE_ROUTE_GAP:
			return "source_route_gap"
		RouteStage.PASS_RECEIVER_RENDERER_PENDING:
			return "pass_receiver_renderer_pending"
		RouteStage.FIELD_RUNNING:
			return "field_running"
		RouteStage.FIRST_ACTION_MENU_PENDING:
			return "first_action_menu_pending"
		RouteStage.MATCH_SELECTOR_RUNNING:
			return "match_selector_running"
		RouteStage.MATCH_SETUP_GAP:
			return "match_setup_gap"
		RouteStage.MATCH_SETUP_A503_TEXT_SETUP:
			return "match_setup_a503_text_setup"
		RouteStage.MATCH_SETUP_A503_PALETTE_RAMP:
			return "match_setup_a503_palette_ramp"
		RouteStage.MATCH_SETUP_A503_INPUT_WAIT:
			return "match_setup_a503_input_wait"
		RouteStage.MATCH_SETUP_A503_POSTWAIT_FADE:
			return "match_setup_a503_postwait_fade"
		RouteStage.MATCH_SETUP_A503_LEVEL_UPDATE:
			return "match_setup_a503_level_update"
		RouteStage.MATCH_SETUP_811F_PENDING:
			return "match_setup_811f_pending"
		RouteStage.MATCH_SETUP_8122_PENDING:
			return "match_setup_8122_pending"
		RouteStage.MATCH_SETUP_812F_PENDING:
			return "match_setup_812f_pending"
		RouteStage.MATCH_SETUP_A64C_PENDING:
			return "match_setup_a64c_pending"
		RouteStage.FIRST_ACTION_MENU:
			return "first_action_menu"
		RouteStage.FIRST_ACTION_HANDLER_PENDING:
			return "first_action_handler_pending"
	return "unknown"


func _is_cutscene_stage() -> bool:
	return route_stage in [RouteStage.CUTSCENE_1, RouteStage.CUTSCENE_2, RouteStage.CUTSCENE_56]


func _is_source_route_waiting() -> bool:
	return route_stage in [RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI,
		RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE,
		RouteStage.MATCH_SETUP_A503_INPUT_WAIT]


func _route_gaps_add(message: String) -> void:
	if not route_gaps.has(message):
		route_gaps.append(message)


func _install_route_input_actions() -> void:
	_add_action_if_missing("route_advance", [KEY_Z], JOY_BUTTON_A)
	_add_action_if_missing("route_b", [KEY_X], JOY_BUTTON_B)
	_add_action_if_missing("route_select", [KEY_SHIFT], JOY_BUTTON_BACK)


func _add_action_if_missing(action_name: StringName, key_codes: Array[Key], joy_button: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key_code in key_codes:
		var key_event := InputEventKey.new()
		key_event.keycode = key_code
		_add_input_binding(action_name, key_event)
	var joy_event := InputEventJoypadButton.new()
	joy_event.button_index = joy_button
	_add_input_binding(action_name, joy_event)


func _add_input_binding(action_name: StringName, event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action_name):
		if existing.as_text() == event.as_text():
			return
	InputMap.action_add_event(action_name, event)


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
