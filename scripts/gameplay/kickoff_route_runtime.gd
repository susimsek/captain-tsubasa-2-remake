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
const ACTION_LABEL_BLINK_TICKS := 13
const CUTSCENE_VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")
const MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const MEETING_MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/pre_match_meeting_menu_input.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const FRESH_MATCH_CONTEXT_RESOLVER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_position_context_resolver.gd")
const PLAYER_POSITION_INITIALIZER_SCRIPT := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")
const FRESH_ENTRY_CONTEXT_BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const FRESH_PERIOD_TASK_SCRIPT := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const SOUND_QUEUE_EVENT_SCRIPT := preload("res://scripts/gameplay/rom_sound_queue_write_event.gd")

enum RouteStage {
	CUTSCENE_1,
	MATCHUP_PRESENTATION,
	MEETING_SCENE,
	MEETING_MENU,
	CUTSCENE_2,
	KICKOFF_SETUP_GATE,
	KICKOFF_NARRATION,
	FIELD_RUNNING,
	FIRST_ACTION_MENU_PENDING,
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
	"After B, the route remains pending until a source-owned first-menu packet event and active-player state are supplied; no fixed-frame wait stands in for that event.",
	"The 13-handler-iteration action-label blink is modeled on the route tick, but handler-to-video cadence and same-input selected-label pixels are not verified.",
	"Route cue assets are ROM-derived; cue onset, loop phase, SFX mix, and same-input PCM remain unverified.",
]

var _visuals: KickoffCutsceneVisuals
var _menu_input: FirstActionMenuInput
var _meeting_menu_input: Node
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
var _initial_player_positions: Array[Dictionary] = []
var _sound_queue_event_history: Array[Dictionary] = []
var _last_cutscene_completion_kind := "none"


func _ready() -> void:
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
	if event.is_action_pressed("route_advance"):
		if _is_cutscene_stage():
			_pending_a_edge = true
		elif route_stage == RouteStage.MATCHUP_PRESENTATION:
			_begin_pre_match_meeting_scene()
			get_viewport().set_input_as_handled()
		elif route_stage == RouteStage.KICKOFF_SETUP_GATE:
			_pending_a_edge = true
		else:
			return
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("route_b"):
		if route_stage == RouteStage.KICKOFF_SETUP_GATE:
			_pending_b_edge = true
			get_viewport().set_input_as_handled()
		elif route_stage == RouteStage.FIELD_RUNNING:
			_begin_first_action_menu_pending()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("route_select"):
		if _is_cutscene_stage():
			_pending_select_edge = true
			get_viewport().set_input_as_handled()
		elif route_stage == RouteStage.KICKOFF_NARRATION:
			_pending_select_edge = true
			get_viewport().set_input_as_handled()


func install_first_action_menu(player_state: FirstActionMenuMatchPlayerState) -> bool:
	if route_stage != RouteStage.MATCH_SETUP_GAP and route_stage != RouteStage.FIRST_ACTION_MENU_PENDING:
		return false
	if not _visuals.present_first_action_menu(player_state):
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


## Reports one field-loop pass that has reached the ROM `$E14D` timer check.
## Returns false when this route has no configured state provider or the ROM
## timer did not trigger a stamina update on this eligible iteration.
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
		"last_cutscene_completion_kind": _last_cutscene_completion_kind,
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
	if is_instance_valid(_visuals):
		_visuals.advance_source_tick()
	if _is_cutscene_stage():
		if _pending_select_edge:
			_skip_active_cutscene()
		else:
			vm.advance_scheduler_tick(NES_A_EDGE if _pending_a_edge else 0)
	elif route_stage == RouteStage.MEETING_SCENE:
		vm.advance_scheduler_tick(0)
	elif route_stage == RouteStage.MEETING_MENU:
		if is_instance_valid(_meeting_menu_input):
			_meeting_menu_input.call("flush_pending_input")
	elif route_stage == RouteStage.KICKOFF_SETUP_GATE:
		if (_held_kickoff_input_bits & (NES_A_EDGE | NES_B_HELD)) != 0:
			if not _initialize_initial_player_positions():
				route_stage = RouteStage.MATCH_SETUP_GAP
				route_stage_changed.emit(_stage_name())
				return
			route_stage = RouteStage.KICKOFF_NARRATION
			route_stage_changed.emit(_stage_name())
	elif route_stage == RouteStage.KICKOFF_NARRATION:
		if _pending_select_edge:
			# Source input at this point leaves the kickoff narration state; the
			# live capture still shows the character/status sequence until B opens
			# the field command screen later. Keep the field loader deferred.
			route_stage = RouteStage.FIELD_RUNNING
			route_stage_changed.emit(_stage_name())
	elif route_stage == RouteStage.FIRST_ACTION_MENU_PENDING:
		# A pending route does not advance by an invented wait. The ROM task,
		# callback event, packet queue, and caller-owned player state are not yet
		# produced here, so leave the endpoint explicitly pending.
		pass
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
	_last_cutscene_completion_kind = completion_kind
	cutscene_return_requested.emit(cutscene_id, completion_kind)
	if cutscene_id == 1:
		route_stage = RouteStage.MATCHUP_PRESENTATION
		route_stage_changed.emit(_stage_name())
	elif cutscene_id == 0x44:
		_install_meeting_menu()
	elif cutscene_id == 2:
		# ROM source order derives team/formation/possession setup before the
		# scenario-$35 A/B wait. Player records are initialized only after that
		# held-button poll, so keep those as a separate later transition.
		if not _initialize_fresh_match_context():
			route_stage = RouteStage.MATCH_SETUP_GAP
			route_stage_changed.emit(_stage_name())
			return
		_route_gaps_add("Fresh-match setup is folded from ROM source at the cutscene return; scheduler callbacks and exact source timing are not executed by this route.")
		route_stage = RouteStage.KICKOFF_SETUP_GATE
		route_stage_changed.emit(_stage_name())


func _skip_active_cutscene() -> void:
	var skipped_id := vm.cutscene_id
	if skipped_id <= 0:
		return
	# The ROM's `$82B5` caller wait checks fresh Select while the shared worker
	# is active. `$82C6` then clears scheduler slots and performs common route
	# cleanup; the script pointer itself need not be zeroed. Do not infer a
	# separate story branch from the stale pointer visible in frame snapshots.
	vm.stop()
	_on_cutscene_done(skipped_id, "select")


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


func _begin_first_action_menu_pending() -> void:
	if route_stage != RouteStage.FIELD_RUNNING:
		return
	if not _visuals.present_first_match_field_candidate():
		_route_gaps_add("The ROM-derived field candidate could not be applied on the B/menu transition.")
	route_stage = RouteStage.FIRST_ACTION_MENU_PENDING
	route_stage_changed.emit(_stage_name())


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


## The ROM initializes the 22 player coordinates after the A/B-held poll.
## Receiver/control state and movement remain separate source transitions.
func _initialize_initial_player_positions() -> bool:
	_initial_player_positions.clear()
	if not bool(_fresh_match_context.get("ok", false)):
		_route_gaps_add("Player positions require the earlier ROM-derived fresh-match context.")
		return false
	var position_initializer = PLAYER_POSITION_INITIALIZER_SCRIPT.new()
	if not position_initializer.configure():
		_route_gaps_add("Initial player-position source unavailable: %s" % position_initializer.error_message)
		return false
	var position_result: Dictionary = position_initializer.initialize_positions(
		int(_fresh_match_context.get("match_index", -1)),
		int(_fresh_match_context.get("formation_002c", -1)),
		int(_fresh_match_context.get("formation_002e", -1)),
		int(_fresh_match_context.get("possession_side_05fb", -1)),
		_fresh_entry_context.provenance if _fresh_entry_context != null else {})
	if not bool(position_result.get("ok", false)):
		_route_gaps_add("Initial player positions could not be derived: %s" % str(position_result.get("error", "unknown source error")))
		return false
	var positions: Array = position_result.get("positions", [])
	if positions.size() != 22:
		_route_gaps_add("Initial player-position source returned %d records; expected 22." % positions.size())
		return false

	for position_variant in positions:
		if not position_variant is Dictionary:
			_initial_player_positions.clear()
			_route_gaps_add("Initial player-position source returned a malformed record.")
			return false
		var position: Dictionary = position_variant
		_initial_player_positions.append(position.duplicate(true))
	return true


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
		RouteStage.KICKOFF_SETUP_GATE:
			return "kickoff_setup_gate"
		RouteStage.KICKOFF_NARRATION:
			return "kickoff_narration"
		RouteStage.FIELD_RUNNING:
			return "field_running"
		RouteStage.FIRST_ACTION_MENU_PENDING:
			return "first_action_menu_pending"
		RouteStage.MATCH_SETUP_GAP:
			return "match_setup_gap"
		RouteStage.FIRST_ACTION_MENU:
			return "first_action_menu"
	return "unknown"


func _is_cutscene_stage() -> bool:
	return route_stage == RouteStage.CUTSCENE_1 or route_stage == RouteStage.CUTSCENE_2


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
