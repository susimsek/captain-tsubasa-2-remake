extends Node
class_name PreMatchMeetingMenuInput
## ROM-traced four-row pre-match menu input for fresh KICK OFF.
## It selects menu entries only; the route decides which entry is in scope.

signal selection_changed(option_index: int, cursor_y: int)
signal option_confirmed(option_index: int)

const FIRST_CURSOR_Y := 0x98
const LAST_CURSOR_Y := 0xC8
const CURSOR_ROW_STEP := 0x10

const UP_ACTION: StringName = &"meeting_menu_up"
const DOWN_ACTION: StringName = &"meeting_menu_down"
const CONFIRM_ACTION: StringName = &"meeting_menu_confirm"

var cursor_y := FIRST_CURSOR_Y
var selected_option_index := 0

var _pending_up := false
var _pending_down := false
var _pending_confirm := false


func _ready() -> void:
	_install_actions()


func _unhandled_input(event: InputEvent) -> void:
	if handle_input_event(event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	flush_pending_input()


## Queue fresh input edges. Held/repeated key events are ignored, matching the
## menu's ROM new-press polling rather than Godot's key repeat behavior.
func handle_input_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.echo:
		return false
	var handled := false
	if event.is_action_pressed(UP_ACTION):
		_pending_up = true
		handled = true
	if event.is_action_pressed(DOWN_ACTION):
		_pending_down = true
		handled = true
	if event.is_action_pressed(CONFIRM_ACTION):
		_pending_confirm = true
		handled = true
	return handled


## Resolve one input poll using the target-ROM Up-before-Down order. The source
## cursor moves by $10 per row and wraps between $98 and $C8.
func flush_pending_input() -> void:
	var moved := false
	if _pending_up:
		cursor_y = LAST_CURSOR_Y if cursor_y == FIRST_CURSOR_Y else cursor_y - CURSOR_ROW_STEP
		moved = true
	elif _pending_down:
		cursor_y = FIRST_CURSOR_Y if cursor_y == LAST_CURSOR_Y else cursor_y + CURSOR_ROW_STEP
		moved = true
	_pending_up = false
	_pending_down = false
	if moved:
		selected_option_index = int((cursor_y - FIRST_CURSOR_Y) / CURSOR_ROW_STEP)
		selection_changed.emit(selected_option_index, cursor_y)
	if _pending_confirm:
		_pending_confirm = false
		option_confirmed.emit(selected_option_index)


func move_up() -> void:
	_pending_up = true


func move_down() -> void:
	_pending_down = true


func confirm() -> void:
	_pending_confirm = true


func reset_selection() -> void:
	cursor_y = FIRST_CURSOR_Y
	selected_option_index = 0
	_pending_up = false
	_pending_down = false
	_pending_confirm = false


func _install_actions() -> void:
	_add_action_if_missing(UP_ACTION, KEY_UP, JOY_BUTTON_DPAD_UP)
	_add_action_if_missing(DOWN_ACTION, KEY_DOWN, JOY_BUTTON_DPAD_DOWN)
	_add_action_if_missing(CONFIRM_ACTION, KEY_Z, JOY_BUTTON_A)
	_add_key_binding(CONFIRM_ACTION, KEY_SPACE)
	_add_key_binding(CONFIRM_ACTION, KEY_ENTER)


func _add_action_if_missing(action_name: StringName, key: Key, joy_button: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	_add_key_binding(action_name, key)
	var joy_event := InputEventJoypadButton.new()
	joy_event.button_index = joy_button
	_add_event_binding(action_name, joy_event)


func _add_key_binding(action_name: StringName, key: Key) -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = key
	_add_event_binding(action_name, key_event)


func _add_event_binding(action_name: StringName, event: InputEvent) -> void:
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event.as_text() == event.as_text():
			return
	InputMap.action_add_event(action_name, event)
