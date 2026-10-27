extends SceneTree
## Verify title cursor inputs against the byte-checked bank-0 menu behavior.
## This checks Godot action handling/PPU state, not the unmeasured CPU subframe.

const TITLE_SCENE := preload("res://scenes/title_menu.tscn")
const NES_FPS := 60.0988
const KICK_OFF_CURSOR_ADDRESS := 0x220A
const CONTINUE_CURSOR_ADDRESS := 0x224A
const CURSOR_TILE := 0x7F

var _menu: RomTitleMenu


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_menu = TITLE_SCENE.instantiate() as RomTitleMenu
	if _menu == null:
		push_error("Could not instantiate the title menu scene.")
		quit(1)
		return
	get_root().add_child(_menu)
	await process_frame
	_menu.visible = true

	if not _assert_cursor(0, "initial KICK OFF"):
		quit(1)
		return
	if not await _press_key(KEY_DOWN, 1, "Down -> CONTINUE"):
		quit(1)
		return
	if not await _press_key(KEY_UP, 0, "Up -> KICK OFF"):
		quit(1)
		return
	if not await _press_key(KEY_TAB, 1, "Select toggles to CONTINUE"):
		quit(1)
		return
	if not await _press_key(KEY_TAB, 0, "Select toggles to KICK OFF"):
		quit(1)
		return
	if not await _press_key(KEY_ENTER, 0, "Start remains unconfirmed"):
		quit(1)
		return
	if not await _press_joypad_button(JOY_BUTTON_DPAD_DOWN, 1, "Gamepad Down -> CONTINUE"):
		quit(1)
		return
	if not await _press_joypad_button(JOY_BUTTON_DPAD_UP, 0, "Gamepad Up -> KICK OFF"):
		quit(1)
		return
	if not await _press_joypad_button(JOY_BUTTON_BACK, 1, "Gamepad Select toggles to CONTINUE"):
		quit(1)
		return
	if not await _press_joypad_button(JOY_BUTTON_BACK, 0, "Gamepad Select toggles to KICK OFF"):
		quit(1)
		return
	if not await _press_joypad_button(JOY_BUTTON_START, 0, "Gamepad Start remains unconfirmed"):
		quit(1)
		return

	print("Title cursor controls passed: keyboard and gamepad Down/Up/Select; Start remains unconfirmed.")
	quit(0)


func _press_key(key_code: Key, expected_selection: int, label: String) -> bool:
	var prior_selection := int(_menu.title_background.get_render_state().get(
			"cursor_selection", -1))
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = true
	get_root().push_input(event, true)
	if not _assert_cursor(prior_selection, "%s before queued frame commit" % label):
		return false
	# Cursor PPU writes become visible after the source-observed one-frame delay.
	await create_timer(1.0 / NES_FPS + 0.01).timeout
	return _assert_cursor(expected_selection, label)


func _press_joypad_button(button_index: JoyButton, expected_selection: int, label: String) -> bool:
	var prior_selection := int(_menu.title_background.get_render_state().get(
			"cursor_selection", -1))
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	get_root().push_input(event, true)
	if not _assert_cursor(prior_selection, "%s before queued frame commit" % label):
		return false
	await create_timer(1.0 / NES_FPS + 0.01).timeout
	return _assert_cursor(expected_selection, label)


func _assert_cursor(expected_selection: int, label: String) -> bool:
	var ppu_memory := _menu.title_background.get_ppu_memory_snapshot()
	var expected_cursor_address := KICK_OFF_CURSOR_ADDRESS if expected_selection == 0 \
			else CONTINUE_CURSOR_ADDRESS
	var other_cursor_address := CONTINUE_CURSOR_ADDRESS if expected_selection == 0 \
			else KICK_OFF_CURSOR_ADDRESS
	var expected_render_state := _menu.title_background.get_render_state()
	if int(expected_render_state.get("cursor_selection", -1)) != expected_selection \
			or int(expected_render_state.get("cursor_ppu_address", -1)) != expected_cursor_address \
			or int(ppu_memory.get(expected_cursor_address, -1)) != CURSOR_TILE \
			or int(ppu_memory.get(other_cursor_address, -1)) != 0:
		push_error("Title cursor verification failed at '%s'." % label)
		return false
	return true
