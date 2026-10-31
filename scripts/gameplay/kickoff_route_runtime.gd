extends Node2D
class_name KickoffRouteRuntime
## ROM-derived fresh-start route from title KICK OFF to the first field menu.

signal route_stage_changed(stage: String)
signal cutscene_return_requested(cutscene_id: int, completion_kind: String)
signal first_action_menu_requested
signal action_selection_changed(action_id: int, direction_index: int)
signal action_confirmation_requested(action_id: int)
signal rom_sound_queue_write_requested(event: RefCounted)

const NES_FPS := 60.0988
const NES_A_EDGE := 0x80
const NES_B_HELD := 0x40
const NES_SELECT_HELD := 0x20
const ACTION_LABEL_BLINK_TICKS := 13
const CUTSCENE_VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")
const MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const MEETING_MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/pre_match_meeting_menu_input.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const CUTSCENE_SELECT_WAIT_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_select_wait_task.gd")
const CUTSCENE_CLEANUP_FADE_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_cleanup_fade_task.gd")
const CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_cleanup_clear_task.gd")
const FRESH_KICKOFF_CALLER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_caller_continuation.gd")
const MAPPER_SHADOW_SOURCE_STATE_SCRIPT := preload("res://scripts/gameplay/rom_mapper_shadow_source_state.gd")
const FIXED_MAPPER_SELECT_HELPER_SCRIPT := preload("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd")
const FRESH_MATCH_SELECTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_executor.gd")
const FRESH_MATCH_SELECTOR_CLOCK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_selector_clock.gd")
const FRESH_MATCH_NORMALIZER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_normalize_executor.gd")
const FRESH_MATCH_PRESET_PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_preset_loader_prefix.gd")
const FRESH_MATCH_HANDOFF_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_handoff_executor.gd")
const FRESH_MATCH_CONTEXT_RESOLVER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_position_context_resolver.gd")
const FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const FRESH_PERIOD_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const FRESH_SOURCE_ROUTE_RUNNER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SOUND_QUEUE_EVENT_SCRIPT := preload("res://scripts/gameplay/rom_sound_queue_write_event.gd")
const SOURCE_RAM_IMAGE_SCRIPT := preload("res://scripts/gameplay/rom_source_ram_image.gd")

enum RouteStage {
	CUTSCENE_1,
	MATCHUP_PRESENTATION,
	MEETING_SCENE,
	MEETING_MENU,
	CUTSCENE_2,
	CUTSCENE_CLEANUP_FADE,
	SOURCE_ROUTE_WAITING_FOR_NMI,
	SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE,
	SOURCE_ROUTE_GAP,
	FIELD_RUNNING, # Retained for isolated field-loop/provider verification only.
	FIRST_ACTION_MENU_PENDING,
	MATCH_SELECTOR_RUNNING,
	MATCH_SETUP_GAP,
	FIRST_ACTION_MENU,
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
	"First-match full field map, raster/scroll schedule, and actor OAM producers are unresolved; the current field is a ROM-backed candidate.",
	"A ROM-derived player-state provider can be bound, but the live route still lacks a generic input/RNG producer and source-confirmed $E14D field-loop events.",
	"The single-slot task-context model is diagnostic-only; it does not produce the live $8327 callback/task event or previous $05CD needed by the field packet renderer.",
	"The live route executes the source-generated `$EE9F`/`$E3CA` branches, resumes the slot-$05 worker through `$8886->$C515`, executes its `$EF->$8B48` and `$FC->$8C52` text callbacks, writes the first two menu-window PPU packets, and source-executes slot `$09` through the `$86F8`, `$8779`, and `$87E6` zero branches plus the `$EBD7->$EB88->$CB0F` scheduler-call entry. The scheduler handler, later PPU delivery, visible field/menu output, and same-input audio/timing remain unresolved.",
	"The live route advances only source-supported scheduler branches; first-match PPU state, visible field/menu output, and same-input audio/timing remain unresolved.",
	"The 13-handler-iteration action-label blink is modeled on the route tick, but handler-to-video cadence and same-input selected-label pixels are not verified.",
	"Route cue assets are ROM-derived; cue onset, loop phase, SFX mix, and same-input PCM remain unverified.",
]

var _visuals: KickoffCutsceneVisuals
var _menu_input: FirstActionMenuInput
var _meeting_menu_input: Node
var _cutscene_select_wait_task: Variant
var _cutscene_cleanup_fade_task: Variant
var _cutscene_cleanup_clear_result: Dictionary = {}
var _cutscene_cleanup_ram_writes: Dictionary = {}
var _cutscene_post_helper_ram_writes: Dictionary = {}
var _source_ram_image: RomSourceRamImage
var _cutscene_cleanup_fade_counters := Vector2i.ZERO
var _cutscene_wait_cleanup_result: Dictionary = {}
var _match_player_state_provider: RomFreshKickoffMatchStateProvider
var _frame_accumulator := 0.0
var _pending_a_edge := false
var _pending_select_edge := false
var _pending_b_edge := false
var _held_kickoff_input_bits := 0
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
var _initial_player_positions: Array[Dictionary] = []
var _sound_queue_event_history: Array[Dictionary] = []
var _last_cutscene_completion_kind := "none"
var _last_completed_cutscene_id := 0


func _ready() -> void:
	_source_ram_image = SOURCE_RAM_IMAGE_SCRIPT.new() as RomSourceRamImage
	_visuals = VISUALS_SCENE.instantiate() as KickoffCutsceneVisuals
	_visuals.name = "CutsceneVisuals"
	add_child(_visuals)
	_visuals.bind_vm(vm)
	vm.presenter_event.connect(_on_presenter_event)
	vm.done.connect(_on_cutscene_done)
	vm.vm_error.connect(_on_vm_error)
	rom_sound_queue_write_requested.connect(_on_rom_sound_queue_write_requested)
	_install_route_input_actions()
	_start_cutscene(1)


func _process(delta: float) -> void:
	_frame_accumulator += delta * NES_FPS
	while _frame_accumulator >= 1.0:
		_frame_accumulator -= 1.0
		_advance_route_source_tick()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
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


func install_first_action_menu(player_state: FirstActionMenuMatchPlayerState) -> bool:
	if route_stage != RouteStage.FIRST_ACTION_MENU_PENDING and route_stage != RouteStage.MATCH_SETUP_GAP:
		return false
	if not _visuals.present_first_action_menu(player_state):
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


## Installs the first command menu from the bound ROM-derived player state.
## The caller still owns the input-hash/RNG proof and eligible timer events.
func install_first_action_menu_from_provider() -> bool:
	if _match_player_state_provider == null:
		return false
	var player_state := _match_player_state_provider.get_controlled_player_state()
	if player_state == null:
		return false
	return install_first_action_menu(player_state)


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
		"scheduler_tick": scheduler_tick,
		"cutscene_id": vm.cutscene_id,
		"last_completed_cutscene_id": _last_completed_cutscene_id,
		"last_cutscene_completion_kind": _last_cutscene_completion_kind,
		"cutscene_select_wait": _cutscene_select_wait_task.get_status() if _cutscene_select_wait_task != null else {},
		"cutscene_wait_cleanup": _cutscene_wait_cleanup_result.duplicate(true),
		"cutscene_cleanup_fade": _cutscene_cleanup_fade_task.get_status() if _cutscene_cleanup_fade_task != null else {},
		"cutscene_cleanup_clear": _cutscene_cleanup_clear_result.duplicate(true),
		"cutscene_cleanup_ram_writes": _cutscene_cleanup_ram_writes.duplicate(true),
		"cutscene_post_helper_ram_writes": _cutscene_post_helper_ram_writes.duplicate(true),
		"source_ram_image_at_893b": _source_ram_image.get_status() if _source_ram_image != null else {},
		"vm_state": vm.state,
		"active_background_id": _visuals.active_background_id if is_instance_valid(_visuals) else -1,
		"first_action_menu_complete": _visuals.action_menu_complete if is_instance_valid(_visuals) else false,
		"first_action_menu_source_pending": route_stage == RouteStage.FIRST_ACTION_MENU_PENDING,
		"menu_missing_dynamic": _visuals.action_menu_missing_dynamic.duplicate(true) if is_instance_valid(_visuals) else [],
		"selected_action_id": _menu_input.selected_action_id if is_instance_valid(_menu_input) else FirstActionMenuInput.ActionId.NONE,
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
	if _is_source_route_waiting():
		if _fresh_source_route_runner == null:
			_route_gaps_add("Source-frame controller sampling has no configured route runner.")
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
		var controller_sample: Dictionary = _fresh_source_route_runner.sample_controller_input(
			_held_kickoff_input_bits)
		if not bool(controller_sample.get("ok", false)):
			_route_gaps_add("Source-frame controller sample failed: %s" % String(controller_sample.get("error", "unknown source error")))
			route_stage = RouteStage.SOURCE_ROUTE_GAP
			route_stage_changed.emit(_stage_name())
			return
	if is_instance_valid(_visuals):
		_visuals.advance_source_tick()
	if _is_cutscene_stage():
		vm.advance_scheduler_tick(NES_A_EDGE if _pending_a_edge else 0)
		if vm.cutscene_id in [1, 2] and _cutscene_select_wait_task != null \
				and _cutscene_select_wait_task.is_waiting():
			_advance_cutscene_select_wait(vm.cutscene_id)
	elif route_stage == RouteStage.CUTSCENE_CLEANUP_FADE:
		_advance_cutscene_cleanup_fade()
	elif route_stage == RouteStage.MEETING_SCENE:
		vm.advance_scheduler_tick(0)
	elif route_stage == RouteStage.MEETING_MENU:
		if is_instance_valid(_meeting_menu_input):
			_meeting_menu_input.call("flush_pending_input")
	elif route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI:
		_advance_fresh_source_route_frame_level_nmi()
	elif route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
		_advance_fresh_source_route_selected_tasks()
	elif route_stage == RouteStage.FIRST_ACTION_MENU_PENDING:
		# A pending route does not advance by an invented wait. The ROM task,
		# callback event, packet queue, and caller-owned player state are not yet
		# produced here, so leave the endpoint explicitly pending.
		pass
	elif route_stage == RouteStage.MATCH_SELECTOR_RUNNING:
		_advance_fresh_match_selector_clock()
	elif route_stage == RouteStage.FIRST_ACTION_MENU:
		if is_instance_valid(_menu_input):
			_menu_input.flush_pending_input()
		_advance_action_label_blink()
	_pending_a_edge = false
	_pending_select_edge = false
	_pending_b_edge = false


func _start_cutscene(cutscene_id: int) -> void:
	if not vm.start_cutscene(cutscene_id):
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


func _on_presenter_event(event: Dictionary) -> void:
	if str(event.get("kind", "")) != "sound_command":
		return
	var queue_write: RefCounted = SOUND_QUEUE_EVENT_SCRIPT.new()
	if not bool(queue_write.call("populate_from_cutscene_ed_command",
			vm.cutscene_id, event, source_frame)):
		_route_gaps_add("A cutscene sound command failed its ROM queue-write provenance checks.")
		return
	var queue_write_data: Dictionary = queue_write.call("to_dictionary")
	_sound_queue_event_history.append(queue_write_data)
	rom_sound_queue_write_requested.emit(queue_write)


func _on_rom_sound_queue_write_requested(event: RefCounted) -> void:
	if event == null:
		return
	cue_audio.apply_rom_sound_command(int(event.get("queue_id")), int(event.get("route_frame")))


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


func _advance_cutscene_cleanup_fade() -> void:
	if _cutscene_cleanup_fade_task == null:
		_route_gaps_add("ROM `$99F0` cleanup fade has no configured live task.")
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	var step: Dictionary = _cutscene_cleanup_fade_task.advance_source_tick(source_frame)
	_cutscene_wait_cleanup_result["fade_helper_result"] = _cutscene_cleanup_fade_task.get_status()
	if not bool(step.get("ok", false)):
		_route_gaps_add("ROM `$99F0` cleanup fade stopped: %s" % String(step.get("error", step.get("status", "unknown error"))))
		route_stage = RouteStage.MATCH_SETUP_GAP
		route_stage_changed.emit(_stage_name())
		return
	if String(step.get("status", "")) == "yielded_after_palette_step":
		var packet: PackedByteArray = step.get("palette_packet", PackedByteArray())
		if not _visuals.queue_rom_cleanup_fade_palette_packet(packet):
			_route_gaps_add("The `$99F0->$9A71` palette packet had no verified live presenter consumer.")
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_wait_cleanup_result["fade_helper_result"] = _cutscene_cleanup_fade_task.get_status()
		return
	if String(step.get("status", "")) == "returned_zero_counters":
		var clear_task: Variant = CUTSCENE_CLEANUP_CLEAR_TASK_SCRIPT.new()
		if not clear_task.configure_from_project_sources():
			_route_gaps_add("Cutscene cleanup clear sources failed verification: %s" % clear_task.error_message)
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_cutscene_cleanup_clear_result = clear_task.execute(_visuals)
		if not bool(_cutscene_cleanup_clear_result.get("ok", false)):
			_route_gaps_add("Cutscene cleanup clear failed: %s" % String(_cutscene_cleanup_clear_result.get("error", "unknown source/presenter error")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
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
		var next_logical_frame := {
			"kind": "rom_jsr", "caller_pc": 0x80FA, "target_pc": 0xA20F,
			"return_pc": 0x80FD, "return_word": 0x80FC,
			"source_event_id": "fresh_kickoff_id1_rom_call_80FA_A20F",
		}
		var next_call := {
			"caller_pc": 0x80FA, "target_pc": 0xA20F, "return_pc": 0x80FD,
			"call_id": "resolve_fresh_match_roster",
			"source_event_id": "fresh_kickoff_id1_rom_call_80FA_A20F",
			"logical_stack_frame": next_logical_frame,
		}
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
		# The selector-clock P candidate is diagnostic evidence only. The live
		# title-to-route CPU path does not propagate I, so retain it as unknown.
		var selector_entry_status := {
			"live_source_status_known": false,
			"p_known_mask": 0,
			"p_known_value": 0,
			"i_flag_known": false,
			"candidate_status_applied": false,
			"gap": "title-to-selector CPU status propagation is not source-executed",
		}
		var selector_cpu_contract: Dictionary = mapper_result.get("return_registers", {}).duplicate(true)
		selector_cpu_contract["pc"] = 0xA20F
		var selector_ram: Dictionary = mapper_result.get("ram_after", {}).duplicate(true)
		selector_ram[0x0026] = int(mapper_shadow_state.get("match_index_0026", -1))
		var selector_result: Dictionary = selector_executor.execute_source_call(next_call,
			selector_cpu_contract, selector_ram)
		if not bool(selector_result.get("ok", false)):
			_route_gaps_add("ROM `$80FA->$A20F` match selector stopped: %s" % String(selector_result.get("error", "source state rejected")))
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_begin_fresh_match_selector_clock(caller_result, pending_call,
			mapper_shadow_state, mapper_result, selector_executor, selector_result,
			selector_ram, selector_clock, selector_entry_status)
		return
	_route_gaps_add("ROM `$99F0` cleanup fade returned an unsupported source state `%s`." % String(step.get("status", "unknown")))
	route_stage = RouteStage.MATCH_SETUP_GAP
	route_stage_changed.emit(_stage_name())


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
	var normalizer: Variant = FRESH_MATCH_NORMALIZER_SCRIPT.new()
	if not normalizer.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match normalizer source failed verification: %s" % normalizer.error_message)
	var normalize_result: Dictionary = normalizer.execute_from_logical_selector_return(selector_result)
	if not bool(normalize_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$80FD-$8112` caller/normalizer stopped: %s" % String(normalize_result.get("error", "source state rejected")))
	if not _apply_normalizer_audio_stop(normalize_result):
		return _stop_match_selector_clock("ROM `$8107` stop write could not be consumed by the route audio presenter.")
	var preset_prefix: Variant = FRESH_MATCH_PRESET_PREFIX_SCRIPT.new()
	if not preset_prefix.configure_from_project_sources():
		return _stop_match_selector_clock("Fresh-match `$8920` preset prefix source failed verification: %s" % preset_prefix.error_message)
	var preset_result: Dictionary = preset_prefix.execute_from_normalizer_return(normalize_result)
	if not bool(preset_result.get("ok", false)):
		return _stop_match_selector_clock("ROM `$8112->$893B` preset prefix stopped: %s" % String(preset_result.get("error", "source state rejected")))
	_source_ram_image = SOURCE_RAM_IMAGE_SCRIPT.new() as RomSourceRamImage
	var source_write_receipts: Array[Dictionary] = [
		{"id": "cutscene_cleanup_clear", "result": _cutscene_cleanup_clear_result,
			"writes_key": "ram_writes"},
		{"id": "post_cleanup_kickoff_caller", "result": caller_result,
			"writes_key": "ram_writes"},
		{"id": "kickoff_mapper_select", "result": mapper_result,
			"writes_key": "ram_writes"},
		{"id": "fresh_match_selector", "result": selector_result,
			"writes_key": "ram_writes"},
		{"id": "fresh_match_normalizer", "result": normalize_result,
			"writes_key": "caller_ram_writes"},
		{"id": "fresh_match_preset_prefix", "result": preset_result,
			"writes_key": "caller_ram_writes"},
	]
	for receipt in source_write_receipts:
		var result: Dictionary = receipt["result"]
		result["ram_writes"] = result.get(String(receipt["writes_key"]), [])
		if not _source_ram_image.merge_executor_result(String(receipt["id"]), result):
			return _stop_match_selector_clock("Source RAM write continuity stopped: %s" % _source_ram_image.error_message)
	caller_result["mapper_shadow_state"] = mapper_shadow_state
	caller_result["mapper_helper_result"] = mapper_result
	caller_result["match_selector_result"] = selector_result
	caller_result["match_normalize_result"] = normalize_result
	caller_result["match_preset_loader_prefix_result"] = preset_result
	caller_result["caller_cpu_contract_before_mapper"] = caller_result.get("cpu_output_contract", {}).duplicate(true)
	caller_result["completed_call"] = pending_call.duplicate(true)
	caller_result["mapper_cpu_output_contract"] = mapper_result.get("return_registers", {}).duplicate(true)
	caller_result["selector_cpu_output_contract"] = selector_result.get("return_registers", {}).duplicate(true)
	caller_result["cpu_output_contract"] = preset_result.get("boundary_registers", {}).duplicate(true)
	caller_result["caller_ram_after_match_selector"] = selector_result.get("ram_after", {}).duplicate(true)
	caller_result["caller_ram_after_normalizer"] = normalize_result.get("caller_ram_after", {}).duplicate(true)
	caller_result["caller_ram_at_preset_wait"] = preset_result.get("caller_ram_after", {}).duplicate(true)
	caller_result["selector_timing_clock"] = _fresh_match_selector_clock.get_status()
	caller_result["selector_entry_status_evidence"] = _fresh_match_selector_context.get("selector_entry_status", {}).duplicate(true)
	caller_result["selector_interrupts_scheduled_only"] = _fresh_match_selector_scheduled_interrupts.duplicate(true)
	caller_result["next_pending_call"] = {"caller_pc": 0x893B, "next_source_pc": 0x893B,
		"call_id": "fresh_match_preset_wait_0078"}
	caller_result["pending_call"] = caller_result["next_pending_call"]
	caller_result["status"] = "stopped_at_preset_wait"
	caller_result["final_source_pc"] = 0x893B
	caller_result["source_path"].append_array(mapper_result.get("executed_instruction_pcs", []))
	caller_result["source_path"].append(0x80FA)
	caller_result["source_path"].append_array(selector_result.get("source_path", []))
	caller_result["source_path"].append(0x80FD)
	caller_result["source_path"].append_array(normalize_result.get("source_path", []))
	caller_result["source_path"].append(0x8112)
	caller_result["source_path"].append_array(preset_result.get("source_path", []))
	caller_result["source_path"].append(0x893B)
	_cutscene_wait_cleanup_result["status"] = "blocked_on_caller"
	_cutscene_wait_cleanup_result["pending_source_pc"] = 0x893B
	_cutscene_wait_cleanup_result["pending_helper_id"] = "fresh_match_preset_wait_0078"
	_cutscene_wait_cleanup_result["clear_helper_result"] = _cutscene_cleanup_clear_result.duplicate(true)
	_cutscene_wait_cleanup_result["post_helper_caller_result"] = caller_result.duplicate(true)
	_cutscene_wait_cleanup_result["next_step"] = "Execute the ROM-owned NMI/IRQ handlers at `$893B`; only then continue at `$8117`."
	_route_gaps_add("Cutscene %d cleanup, `$C4B9`, `$80FA->$A20F` selector writes, `$80FD-$8112` normalization, and the `$8112->$893B` prefix were applied over source-frame offsets 0–8. The 15 scheduled NMI/IRQ handler effects and `$78` wait return remain unresolved." % int(_cutscene_wait_cleanup_result.get("cutscene_id", -1)))
	route_stage = RouteStage.MATCH_SETUP_GAP
	route_stage_changed.emit(_stage_name())
	return true


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
	_visuals.clear_route_screen()
	# The direct $812C/$812F $55 write is not this menu callback. It can only
	# be emitted by a future source-task runner when that ROM instruction is
	# actually reached; do not attach it to the user's MEETING confirmation.
	call_deferred("_start_cutscene", 2)


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
	_fresh_source_route_nmi_timing_note = "Frame-level normal-NMI abstractions follow Godot NES_FPS ticks while the ROM-derived `$2000` shadow enables NMI; beam and CPU-cycle phase are unknown."
	return true


## The route currently has no PPU beam/cycle phase. While the ROM-derived
## `$2000` shadow enables NMI, this adapter supplies one normal-NMI abstraction
## per NES-frame source tick. It accepts only source-runner transitions and
## drains supported selected-task bodies until the next external NMI boundary.
## It does not claim dot/cycle timing, synthesize field state, or apply queued
## PPU bus events to the renderer.
func _advance_fresh_source_route_frame_level_nmi() -> void:
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
		_route_gaps_add("Source runner rejected the caller-supplied frame-level NMI: %s" % String(_fresh_source_route_nmi_result.get("error", _fresh_source_route_runner.error_message)))
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	_fresh_source_route_nmi_abstraction_count += 1
	_fresh_source_route_nmi_timing_note = "Issued %d frame-level normal-NMI abstractions at source frame %d using live ROM `$2000` shadow `$%02X`; no beam/dot/cycle phase is modeled." % [_fresh_source_route_nmi_abstraction_count, source_frame, ppu_ctrl_shadow]
	_set_route_stage_from_source_runner()
	if route_stage == RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE:
		_advance_fresh_source_route_selected_tasks()


func _advance_fresh_source_route_selected_tasks() -> void:
	if _fresh_source_route_runner == null:
		_route_gaps_add("Selected-task continuation has no configured source route runner.")
		route_stage = RouteStage.SOURCE_ROUTE_GAP
		route_stage_changed.emit(_stage_name())
		return
	for source_step in range(16):
		var runner_status: Dictionary = _fresh_source_route_runner.get_status()
		var phase := String(runner_status.get("phase", ""))
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
			0x05:
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot05_worker()
			0x09:
				if not _fresh_source_route_runner.has_method("resume_selected_slot09_worker"):
					_route_gaps_add("Slot `$09` is selected at its yielded boundary, but its live worker continuation is not yet integrated.")
					route_stage = RouteStage.SOURCE_ROUTE_GAP
					route_stage_changed.emit(_stage_name())
					return
				_fresh_source_route_task_result = _fresh_source_route_runner.resume_selected_slot09_worker()
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
		_set_route_stage_from_source_runner()
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
	if route_stage != next_stage:
		route_stage = next_stage
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
		RouteStage.CUTSCENE_1:
			return "cutscene_1"
		RouteStage.MATCHUP_PRESENTATION:
			return "matchup_presentation"
		RouteStage.MEETING_SCENE:
			return "meeting_scene"
		RouteStage.MEETING_MENU:
			return "meeting_menu"
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
		RouteStage.FIELD_RUNNING:
			return "field_running"
		RouteStage.FIRST_ACTION_MENU_PENDING:
			return "first_action_menu_pending"
		RouteStage.MATCH_SELECTOR_RUNNING:
			return "match_selector_running"
		RouteStage.MATCH_SETUP_GAP:
			return "match_setup_gap"
		RouteStage.FIRST_ACTION_MENU:
			return "first_action_menu"
	return "unknown"


func _is_cutscene_stage() -> bool:
	return route_stage == RouteStage.CUTSCENE_1 or route_stage == RouteStage.CUTSCENE_2


func _is_source_route_waiting() -> bool:
	return route_stage in [RouteStage.SOURCE_ROUTE_WAITING_FOR_NMI,
		RouteStage.SOURCE_ROUTE_WAITING_FOR_TASK_SOURCE]


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
