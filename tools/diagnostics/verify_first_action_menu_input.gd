extends SceneTree
## Check ROM-traced first-action menu input selection and confirmation.
## This covers the input state component only, not the full route or PPU output.

const INPUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_input.gd")

var _menu_input: Variant
var _confirmed_actions: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_menu_input = INPUT_SCRIPT.new()
	if _menu_input == null:
		_fail("Could not instantiate first-action menu input component.")
		return
	_menu_input.action_confirmed.connect(_on_action_confirmed)
	root.add_child(_menu_input)
	await process_frame

	if _menu_input.selected_action_id != INPUT_SCRIPT.ActionId.NONE:
		_fail("Menu did not start with no action selected.")
		return
	if not _send_key(KEY_Z) or not _confirmed_actions.is_empty():
		_fail("A-button equivalent confirmed an action before selection.")
		return

	var key_cases: Array[Dictionary] = [
		{"key": KEY_RIGHT, "action": INPUT_SCRIPT.ActionId.SHOOT, "direction": 0},
		{"key": KEY_LEFT, "action": INPUT_SCRIPT.ActionId.PASS, "direction": 1},
		{"key": KEY_DOWN, "action": INPUT_SCRIPT.ActionId.ONE_TWO_PASS, "direction": 2},
		{"key": KEY_UP, "action": INPUT_SCRIPT.ActionId.DRIBBLE, "direction": 3},
	]
	for test_case in key_cases:
		if not _send_key(int(test_case["key"])):
			_fail("Keyboard direction was not handled: %s" % test_case)
			return
		if _menu_input.selected_action_id != int(test_case["action"]) \
				or _menu_input.selected_direction_index != int(test_case["direction"]):
			_fail("Keyboard direction mapped to the wrong ROM action: %s" % test_case)
			return

	var pad_cases: Array[Dictionary] = [
		{"button": JOY_BUTTON_DPAD_RIGHT, "action": INPUT_SCRIPT.ActionId.SHOOT},
		{"button": JOY_BUTTON_DPAD_LEFT, "action": INPUT_SCRIPT.ActionId.PASS},
		{"button": JOY_BUTTON_DPAD_DOWN, "action": INPUT_SCRIPT.ActionId.ONE_TWO_PASS},
		{"button": JOY_BUTTON_DPAD_UP, "action": INPUT_SCRIPT.ActionId.DRIBBLE},
	]
	for test_case in pad_cases:
		if not _send_joypad_button(int(test_case["button"])):
			_fail("Gamepad direction was not handled: %s" % test_case)
			return
		if _menu_input.selected_action_id != int(test_case["action"]):
			_fail("Gamepad direction mapped to the wrong ROM action: %s" % test_case)
			return

	_menu_input.reset_selection()
	_menu_input.select_direction(INPUT_SCRIPT.DirectionIndex.UP)
	_menu_input.request_confirmation()
	_menu_input.flush_pending_input()
	if _menu_input.selected_action_id != INPUT_SCRIPT.ActionId.DRIBBLE \
			or _confirmed_actions != [INPUT_SCRIPT.ActionId.DRIBBLE]:
		_fail("A confirmation did not emit the selected action ID exactly once.")
		return

	_menu_input.reset_selection()
	_menu_input.select_direction(INPUT_SCRIPT.DirectionIndex.UP)
	_menu_input.select_direction(INPUT_SCRIPT.DirectionIndex.DOWN)
	_menu_input.select_direction(INPUT_SCRIPT.DirectionIndex.RIGHT)
	_menu_input.flush_pending_input()
	if _menu_input.selected_direction_index != INPUT_SCRIPT.DirectionIndex.RIGHT \
			or _menu_input.selected_action_id != INPUT_SCRIPT.ActionId.SHOOT:
		_fail("Simultaneous directions did not use ROM Right/Left/Down/Up priority.")
		return

	print("First action menu input passed: unselected start, keyboard/gamepad direction mapping, A gating, and direction priority.")
	quit(0)


func _send_key(key_code: Key) -> bool:
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = true
	var handled: bool = _menu_input.handle_input_event(event)
	_menu_input.flush_pending_input()
	return handled


func _send_joypad_button(button_index: JoyButton) -> bool:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	var handled: bool = _menu_input.handle_input_event(event)
	_menu_input.flush_pending_input()
	return handled


func _on_action_confirmed(action_id: int) -> void:
	_confirmed_actions.append(action_id)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
