extends Node2D
class_name RomTitleMenu
## Displays the ROM-CHR title reconstruction. The original Select/Up/Down
## cursor behavior is preserved. KICK OFF confirmation hands control to the
## fresh-start route; Continue is outside the current slice.

signal kickoff_requested

const NES_FPS := 60.0988
const HANDOFF_QUEUE_SCRIPT := preload("res://scripts/title_rom_handoff_queue.gd")

@onready var title_background: RomTitleBackgroundRenderer = $TitleBackground

var _selected: int = 0
var _cursor_commit_pending := false
var _cursor_commit_delay := 0.0
var _handoff_queue: Variant
var _handoff_queue_active := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	position = Vector2.ZERO
	_handoff_queue = HANDOFF_QUEUE_SCRIPT.new()
	_install_select_action()
	_update_frame()


## Reset the hidden endpoint and start the source-ordered title PPU handoff.
func begin_source_handoff() -> bool:
	_selected = 0
	_cursor_commit_pending = false
	_cursor_commit_delay = 0.0
	_handoff_queue_active = bool(_handoff_queue.start(title_background))
	return _handoff_queue_active


## Advance the ROM-derived queue through a Start-relative CPU-cycle offset.
func advance_source_handoff_to_cpu_cycle(cycle_offset: int) -> bool:
	if not _handoff_queue_active:
		return true
	var is_complete := bool(_handoff_queue.advance_to_cpu_cycle(cycle_offset))
	if is_complete:
		_handoff_queue_active = false
	return is_complete


func source_handoff_blackout_started() -> bool:
	return bool(_handoff_queue.blackout_started())


func _process(delta: float) -> void:
	if not visible or not _cursor_commit_pending:
		return
	_cursor_commit_delay -= delta
	if _cursor_commit_delay > 0.0:
		return
	_cursor_commit_pending = false
	_update_frame()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_up"):
		_selected = 0
	elif event.is_action_pressed("ui_down"):
		_selected = 1
	elif event.is_action_pressed("opening_select"):
		_selected = 1 - _selected
	elif event.is_action_pressed("opening_start"):
		if _selected == 0:
			kickoff_requested.emit()
		get_viewport().set_input_as_handled()
		return
	else:
		return
	_queue_cursor_commit()
	get_viewport().set_input_as_handled()


func _queue_cursor_commit() -> void:
	# The observed Down pulse is queued in source frame 4693 and reaches the PPU
	# snapshot in frame 4694. Keep the first pending edge's one-frame deadline;
	# additional edges before that commit update the target selection.
	if not _cursor_commit_pending:
		_cursor_commit_delay = 1.0 / NES_FPS
	_cursor_commit_pending = true


func _update_frame() -> void:
	title_background.set_cursor_selection(_selected)


func _install_select_action() -> void:
	if InputMap.has_action("opening_select"):
		return
	InputMap.add_action("opening_select")
	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	InputMap.action_add_event("opening_select", key)
	var gamepad := InputEventJoypadButton.new()
	gamepad.button_index = JOY_BUTTON_BACK
	InputMap.action_add_event("opening_select", gamepad)
