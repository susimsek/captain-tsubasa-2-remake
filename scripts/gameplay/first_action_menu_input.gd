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

const INPUT_ACTION_BY_DIRECTION: Array[StringName] = [
	&"match_action_right",
	&"match_action_left",
	&"match_action_down",
	&"match_action_up",
]
const NES_DIRECTION_BITS: Array[int] = [0x01, 0x02, 0x04, 0x08]
const CONFIRM_INPUT_ACTION: StringName = &"match_action_confirm"
const NES_CONFIRM_BIT := 0x80
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/first_action_menu_input/"
const SOURCE_MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const SOURCE_MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const DIRECTION_TABLE_PATH := SOURCE_ROOT + "direction_action_ids_context_00_D6E8.bin"
const DIRECTION_TABLE_SHA256 := "dce8e125cc41a56ea02407a10727c0fbced6827fea37a619f5c3cc98f1ee4968"
const DIRECTION_TABLE_CPU := 0xD6E8
const DIRECTION_TABLE_FILE_OFFSET := 0x03D6F8

var selected_action_id: int = ActionId.NONE
var selected_direction_index: int = -1
var source_ready := false
var source_error_message := ""

var _pending_direction_mask := 0
var _pending_confirmation := false
var _direction_action_ids := PackedByteArray()
var _held_nes_pad_state := 0
var _latched_nes_press_bits := 0


func _ready() -> void:
	if not _load_direction_action_table():
		push_error("First-action input is disabled: " + source_error_message)
		return
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
	if not source_ready:
		return false
	var handled := false
	for direction_index in INPUT_ACTION_BY_DIRECTION.size():
		var action_name := INPUT_ACTION_BY_DIRECTION[direction_index]
		var nes_bit := NES_DIRECTION_BITS[direction_index]
		if event.is_action_pressed(action_name):
			_pending_direction_mask |= 1 << direction_index
			_held_nes_pad_state |= nes_bit
			_latched_nes_press_bits |= nes_bit
			handled = true
		elif event.is_action_released(action_name):
			_held_nes_pad_state &= 0xFF ^ nes_bit
			handled = true
	if event.is_action_pressed(CONFIRM_INPUT_ACTION):
		_pending_confirmation = true
		_held_nes_pad_state |= NES_CONFIRM_BIT
		_latched_nes_press_bits |= NES_CONFIRM_BIT
		handled = true
	elif event.is_action_released(CONFIRM_INPUT_ACTION):
		_held_nes_pad_state &= 0xFF ^ NES_CONFIRM_BIT
		handled = true
	return handled


## Apply queued edges as a single ROM input poll. Public for deterministic
## replay and focused verification without a live window or emulator.
func flush_pending_input() -> void:
	if not source_ready:
		_pending_direction_mask = 0
		_pending_confirmation = false
		return
	var direction_index := _first_pressed_direction(_pending_direction_mask)
	_pending_direction_mask = 0
	if direction_index >= 0:
		selected_direction_index = direction_index
		selected_action_id = int(_direction_action_ids[direction_index])
		selection_changed.emit(selected_action_id, selected_direction_index)

	if _pending_confirmation:
		_pending_confirmation = false
		if selected_action_id != ActionId.NONE:
			action_confirmed.emit(selected_action_id)


## Directly apply a newly pressed direction from the ROM direction table:
## Right=Shoot, Left=Pass, Down=One-two pass, Up=Dribble.
func select_direction(direction_index: DirectionIndex) -> void:
	if not source_ready or direction_index < 0 or direction_index >= _direction_action_ids.size():
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


## Current held NES pad mask for the source route's `$001C/$001E` sampler.
## Direction values use A B Select Start Up Down Left Right bit order.
func get_nes_pad_state() -> int:
	return _held_nes_pad_state & 0xFF


## Returns one source-poll mask, preserving taps that were pressed and released
## between source ticks. The press latch is cleared after each read, while
## physically held buttons remain present until their release event.
func consume_nes_pad_state_for_source_poll() -> int:
	var state := (_held_nes_pad_state | _latched_nes_press_bits) & 0xFF
	_latched_nes_press_bits = 0
	return state


func _first_pressed_direction(mask: int) -> int:
	# The ROM checks its newly-pressed direction bits in this exact order.
	for direction_index in _direction_action_ids.size():
		if (mask & (1 << direction_index)) != 0:
			return direction_index
	return -1


func _load_direction_action_table() -> bool:
	source_ready = false
	source_error_message = ""
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH) \
			or not FileAccess.file_exists(DIRECTION_TABLE_PATH):
		return _source_failure("ROM-derived direction table or manifest is missing.")
	var manifest_bytes := FileAccess.get_file_as_bytes(SOURCE_MANIFEST_PATH)
	if FileAccess.get_sha256(SOURCE_MANIFEST_PATH) != SOURCE_MANIFEST_SHA256:
		return _source_failure("ROM-derived direction table manifest failed its SHA-256 check.")
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return _source_failure("ROM-derived direction table manifest is not a JSON object.")
	var manifest: Dictionary = parsed
	var table_variant: Variant = manifest.get("table", {})
	if String(manifest.get("schema", "")) != "ct2-first-action-menu-input-rom-data-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(manifest.get("source_rom_size_bytes", -1)) != 0x60010 \
			or not table_variant is Dictionary:
		return _source_failure("Direction table manifest does not identify the pinned ROM and schema.")
	var table: Dictionary = table_variant
	if int(table.get("context", -1)) != 0 \
			or String(table.get("cpu_address", "")) != "0xD6E8" \
			or String(table.get("prg_bank", "")) != "0x1E" \
			or String(table.get("file_offset", "")) != "0x03D6F8" \
			or int(table.get("length_bytes", -1)) != 4 \
			or String(table.get("resource", "")) != DIRECTION_TABLE_PATH.get_file() \
			or String(table.get("sha256", "")) != DIRECTION_TABLE_SHA256 \
			or String(table.get("bytes_hex", "")).replace(" ", "").to_lower() != "00010302":
		return _source_failure("Direction table manifest does not match the ROM span at `$D6E8`.")
	var table_bytes := FileAccess.get_file_as_bytes(DIRECTION_TABLE_PATH)
	if table_bytes.size() != 4 or FileAccess.get_sha256(DIRECTION_TABLE_PATH) != DIRECTION_TABLE_SHA256 \
			or table_bytes.hex_encode() != "00010302":
		return _source_failure("Direction/action table bytes failed size, content, or SHA-256 validation.")
	_direction_action_ids = table_bytes.duplicate()
	source_ready = true
	return true


func _source_failure(message: String) -> bool:
	source_error_message = message
	return false


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
