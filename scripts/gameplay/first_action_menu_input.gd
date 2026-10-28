extends Node
class_name FirstActionMenuInput
## ROM-traced input state for the fresh-start first-match action menu.
## This selects a command only; it does not resolve or enter that action.

signal selection_changed(action_id: int, direction_index: int)
signal action_confirmed(action_id: int)

enum ActionId {
	NONE = -1,
	SHOOT = 0,
	PASS = 1,
	DRIBBLE = 2,
	ONE_TWO_PASS = 3,
}

enum DirectionIndex {
	RIGHT = 0,
	LEFT = 1,
	DOWN = 2,
	UP = 3,
}

const DIRECTION_ACTIONS: Array[int] = [
	ActionId.SHOOT,
	ActionId.PASS,
	ActionId.ONE_TWO_PASS,
	ActionId.DRIBBLE,
]

const INPUT_ACTION_BY_DIRECTION: Array[StringName] = [
	&"match_action_right",
	&"match_action_left",
	&"match_action_down",
	&"match_action_up",
]
const CONFIRM_INPUT_ACTION: StringName = &"match_action_confirm"

var selected_action_id: int = ActionId.NONE
var selected_direction_index: int = -1

var _pending_direction_mask := 0
var _pending_confirmation := false


func _ready() -> void:
	_install_input_actions()


func _unhandled_input(event: InputEvent) -> void:
	if handle_input_event(event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	flush_pending_input()


## Queue one Godot input event. Direction edges are collected until the next
## process edge, then resolved in the ROM's fixed Right/Left/Down/Up order.
func handle_input_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.echo:
		return false
	var handled := false
	for direction_index in INPUT_ACTION_BY_DIRECTION.size():
		if event.is_action_pressed(INPUT_ACTION_BY_DIRECTION[direction_index]):
			_pending_direction_mask |= 1 << direction_index
			handled = true
	if event.is_action_pressed(CONFIRM_INPUT_ACTION):
		_pending_confirmation = true
		handled = true
	return handled


## Apply queued edges as a single ROM input poll. Public for deterministic
## replay and focused verification without a live window or emulator.
func flush_pending_input() -> void:
	var direction_index := _first_pressed_direction(_pending_direction_mask)
	_pending_direction_mask = 0
	if direction_index >= 0:
		selected_direction_index = direction_index
		selected_action_id = DIRECTION_ACTIONS[direction_index]
		selection_changed.emit(selected_action_id, selected_direction_index)

	if _pending_confirmation:
		_pending_confirmation = false
		if selected_action_id != ActionId.NONE:
			action_confirmed.emit(selected_action_id)


## Directly apply a newly pressed direction from the ROM direction table:
## Right=Shoot, Left=Pass, Down=One-two pass, Up=Dribble.
func select_direction(direction_index: DirectionIndex) -> void:
	if direction_index < 0 or direction_index >= DIRECTION_ACTIONS.size():
		return
	_pending_direction_mask |= 1 << int(direction_index)


## Queue an A-button equivalent; no signal is emitted until an action is
## selected. This component intentionally has no action-resolution behavior.
func request_confirmation() -> void:
	_pending_confirmation = true


func reset_selection() -> void:
	selected_action_id = ActionId.NONE
	selected_direction_index = -1
	_pending_direction_mask = 0
	_pending_confirmation = false


func _first_pressed_direction(mask: int) -> int:
	# The ROM checks its newly-pressed direction bits in this exact order.
	for direction_index in DIRECTION_ACTIONS.size():
		if (mask & (1 << direction_index)) != 0:
			return direction_index
	return -1


func _install_input_actions() -> void:
	for direction_index in INPUT_ACTION_BY_DIRECTION.size():
		var action_name := INPUT_ACTION_BY_DIRECTION[direction_index]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		_add_key_binding(action_name, _key_for_direction(direction_index))
		_add_joypad_binding(action_name, _joypad_direction_for_index(direction_index))

	if not InputMap.has_action(CONFIRM_INPUT_ACTION):
		InputMap.add_action(CONFIRM_INPUT_ACTION)
	_add_key_binding(CONFIRM_INPUT_ACTION, KEY_Z)
	_add_key_binding(CONFIRM_INPUT_ACTION, KEY_SPACE)
	var joypad_a := InputEventJoypadButton.new()
	joypad_a.button_index = JOY_BUTTON_A
	_add_binding_if_missing(CONFIRM_INPUT_ACTION, joypad_a)


func _key_for_direction(direction_index: int) -> Key:
	match direction_index:
		DirectionIndex.RIGHT:
			return KEY_RIGHT
		DirectionIndex.LEFT:
			return KEY_LEFT
		DirectionIndex.DOWN:
			return KEY_DOWN
		_:
			return KEY_UP


func _joypad_direction_for_index(direction_index: int) -> JoyButton:
	match direction_index:
		DirectionIndex.RIGHT:
			return JOY_BUTTON_DPAD_RIGHT
		DirectionIndex.LEFT:
			return JOY_BUTTON_DPAD_LEFT
		DirectionIndex.DOWN:
			return JOY_BUTTON_DPAD_DOWN
		_:
			return JOY_BUTTON_DPAD_UP


func _add_key_binding(action_name: StringName, key_code: Key) -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = key_code
	_add_binding_if_missing(action_name, key_event)


func _add_joypad_binding(action_name: StringName, button_index: JoyButton) -> void:
	var button_event := InputEventJoypadButton.new()
	button_event.button_index = button_index
	_add_binding_if_missing(action_name, button_event)


func _add_binding_if_missing(action_name: StringName, event: InputEvent) -> void:
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event.as_text() == event.as_text():
			return
	InputMap.action_add_event(action_name, event)
