extends RefCounted
class_name RomCutsceneVm
## Legacy visual prototype for a former ROM-derived opening parse.
## Its JSON event boundaries are withdrawn; see RomDispatchTraceVm for the
## verified, non-rendering live-dispatch research trace.
## This prototype is not an authoritative opening VM.

signal command_executed(event: Dictionary, state_snapshot: Dictionary)
signal sound_requested(sound_id: int, event: Dictionary)
signal wait_started(script_ticks: int, event: Dictionary)
signal input_wait_started(event: Dictionary)
signal input_wait_completed(event: Dictionary)
signal text_tile_revealed(tile_id: int, tile_index: int, event: Dictionary)
signal script_looped(event: Dictionary)

const DATA_PATH := "res://assets/opening/rom_logic/cutscene_00_vm.json"
const MAX_COMMANDS_PER_DRAIN := 1024
const A_BUTTON_EDGE_MASK := 0x80

var events: Array[Dictionary] = []
var state: Dictionary = {}
var _cpu_to_event: Dictionary = {}
var _pc: int = 0
var _wait_ticks_remaining: int = 0
var _input_waiting: bool = false
var _input_wait_event: Dictionary = {}
var _pending_text_tiles: Array[int] = []
var _pending_text_index: int = 0
var _pending_text_event: Dictionary = {}
var _pending_text_speed: int = 0
var _pending_text_wait: bool = false
var _started: bool = false
var _finished: bool = false


static func from_project_data() -> RomCutsceneVm:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open ROM cutscene VM data: %s" % DATA_PATH)
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("ROM cutscene VM data must be a JSON object.")
		return null
	if str(parsed.get("status", "")).begins_with("withdrawn"):
		push_error("Legacy ROM cutscene VM data is withdrawn; use RomDispatchTraceVm for evidence inspection.")
		return null
	return from_dictionary(parsed)


static func from_dictionary(data: Dictionary) -> RomCutsceneVm:
	var vm = load("res://scripts/opening/rom_cutscene_vm.gd").new()
	var raw_events: Variant = data.get("events", [])
	if not (raw_events is Array):
		push_error("ROM cutscene VM events must be an array.")
		return null
	for raw_event: Variant in raw_events:
		if not (raw_event is Dictionary):
			push_error("Each ROM cutscene VM event must be an object.")
			return null
		var event: Dictionary = raw_event.duplicate(true)
		if not (event.get("b", []) is Array):
			push_error("Every ROM cutscene event must preserve its raw byte span.")
			return null
		vm.events.append(event)
		vm._cpu_to_event[int(event.get("cpu", -1))] = vm.events.size() - 1
	return vm


## Starts at the ROM script entry and dispatches immediate events up to the first wait.
func begin() -> Dictionary:
	_pc = 0
	_wait_ticks_remaining = 0
	_input_waiting = false
	_input_wait_event.clear()
	_pending_text_tiles.clear()
	_pending_text_index = 0
	_pending_text_event.clear()
	_pending_text_speed = 0
	_pending_text_wait = false
	_finished = false
	_started = true
	state = {
		"script_ticks_elapsed": 0,
		"commands_executed": 0,
		"input_waiting": false,
		"screen_enabled": false,
		"clear_requested": false,
		"visual_preset": -1,
		"background_1": -1,
		"background_2": -1,
		"animation_ids": [],
		"portrait_id": -1,
		"dialog_window": -1,
		"text_speed": -1,
		"palette_command": [],
		"text_brightness": -1,
		"visual_flags": [],
		"visual_subroutine": -1,
		"camera_toggle_count": 0,
		"text_lines": [[]],
		"dialog_line_controls": [],
		"text_cursor_back_tiles": 0,
		"lower_area_clear_count": 0,
		"mouth_toggle_count": 0,
		"sound_ids": [],
		"last_event": {},
	}
	_drain_immediate_commands()
	return state.duplicate(true)


## Advances one abstract script wait tick. Its relationship to a physical NES
## frame and to PPU updates is intentionally unverified in this research VM.
func advance_one_script_tick(input_edge_mask: int = 0) -> Dictionary:
	if not _started or _finished:
		return state.duplicate(true)
	state["script_ticks_elapsed"] = int(state.get("script_ticks_elapsed", 0)) + 1
	if _input_waiting:
		if (input_edge_mask & A_BUTTON_EDGE_MASK) != 0:
			_input_waiting = false
			state["input_waiting"] = false
			input_wait_completed.emit(_input_wait_event.duplicate(true))
			_input_wait_event.clear()
			_drain_immediate_commands()
		return state.duplicate(true)
	if _wait_ticks_remaining > 0:
		_wait_ticks_remaining -= 1
	if _wait_ticks_remaining == 0:
		if _pending_text_wait:
			_pending_text_wait = false
			if _pending_text_index < _pending_text_tiles.size():
				_reveal_pending_text_tile()
				_wait_ticks_remaining = _pending_text_speed
				_pending_text_wait = _pending_text_speed > 0
				wait_started.emit(_pending_text_speed, _pending_text_event.duplicate(true))
			else:
				_pending_text_tiles.clear()
				_pending_text_index = 0
				_pending_text_event.clear()
				_pending_text_speed = 0
				_drain_immediate_commands()
		else:
			_drain_immediate_commands()
	return state.duplicate(true)


func is_waiting() -> bool:
	return _wait_ticks_remaining > 0 or _input_waiting


func get_wait_ticks_remaining() -> int:
	return _wait_ticks_remaining


func is_finished() -> bool:
	return _finished


func current_event_index() -> int:
	return _pc


func _drain_immediate_commands() -> void:
	var executed_this_drain := 0
	while not _finished and _wait_ticks_remaining == 0 and _pc >= 0 and _pc < events.size():
		if executed_this_drain >= MAX_COMMANDS_PER_DRAIN:
			push_error("ROM cutscene VM exceeded its immediate-command safety limit.")
			_finished = true
			return
		var event: Dictionary = events[_pc]
		_pc += 1
		executed_this_drain += 1
		state["commands_executed"] = int(state.get("commands_executed", 0)) + 1
		state["last_event"] = event.duplicate(true)
		var yields_after_event := _apply_event(event)
		command_executed.emit(event.duplicate(true), state.duplicate(true))
		if yields_after_event:
			return
	if _pc < 0 or _pc >= events.size():
		_finished = true


func _apply_event(event: Dictionary) -> bool:
	var kind := str(event.get("k", ""))
	var raw_bytes: Array = event.get("b", [])
	var opcode := int(event.get("op", -1))
	match kind:
		"wait_for_input":
			# EB polls the ROM's newly-pressed edge mask after one scheduler yield
			# and returns only for a fresh A-button edge (mask $80). Holding A from
			# before the wait began is not enough.
			_input_waiting = true
			_input_wait_event = event.duplicate(true)
			state["input_waiting"] = true
			input_wait_started.emit(event.duplicate(true))
			return true
		"compact_pause", "pause_frames":
			_wait_ticks_remaining = int(event.get("ticks", event.get("a", [0])[0] if not event.get("a", []).is_empty() else 0))
			wait_started.emit(_wait_ticks_remaining, event.duplicate(true))
			return true
		"text_tile_ids":
			_pending_text_tiles.clear()
			for tile: Variant in event.get("tiles", raw_bytes):
				_pending_text_tiles.append(int(tile))
			_pending_text_index = 0
			_pending_text_event = event.duplicate(true)
			var text_speed := maxi(0, int(state.get("text_speed", 0)))
			_pending_text_speed = text_speed
			if _pending_text_tiles.is_empty():
				return false
			_reveal_pending_text_tile()
			if text_speed > 0:
				_wait_ticks_remaining = text_speed
				_pending_text_wait = true
				wait_started.emit(text_speed, event.duplicate(true))
				return true
			while _pending_text_index < _pending_text_tiles.size():
				_reveal_pending_text_tile()
			_pending_text_tiles.clear()
			_pending_text_index = 0
			_pending_text_event.clear()
			_pending_text_speed = 0
		"text_cursor_back":
			state["text_cursor_back_tiles"] = int(event.get("tiles", 0))
		"dialog_line_control":
			# The full-stream JSON currently classifies FC using a counted-payload
			# hypothesis that live cold-start dispatch disproved. In the observed
			# bank-0 path, FC enters $8837 and returns to the next script byte. Do
			# not let this stale event consume subsequent command bytes.
			push_error("Unverified FC event reached the research VM; full-stream execution is stopped.")
			_finished = true
			return true
		"visual_preset":
			state["visual_preset"] = _first_argument(event)
		"background_1", "background_2":
			state[kind] = int(event.get("id", _first_argument(event)))
		"animations":
			state["animation_ids"] = (event.get("ids", []) as Array).duplicate()
		"screen_on":
			state["screen_enabled"] = true
			state["clear_requested"] = false
		"screen_off_clear":
			state["screen_enabled"] = false
			state["clear_requested"] = true
		"commentator_portrait":
			state["portrait_id"] = _first_argument(event)
		"dialog_window":
			state["dialog_window"] = _first_argument(event)
		"text_speed":
			state["text_speed"] = _first_argument(event)
		"palette_command":
			state["palette_command"] = event.get("a", []).duplicate()
		"text_brightness_command":
			state["text_brightness"] = _first_argument(event)
		"visual_flag":
			var flags: Array = state["visual_flags"]
			flags.append(_first_argument(event))
			state["visual_flags"] = flags
		"visual_subroutine":
			state["visual_subroutine"] = _first_argument(event)
		"clear_text":
			state["text_lines"] = [[]]
			state["text_cursor_back_tiles"] = 0
		"clear_lower_area":
			state["lower_area_clear_count"] = int(state["lower_area_clear_count"]) + 1
		"toggle_camera":
			state["camera_toggle_count"] = int(state["camera_toggle_count"]) + 1
		"toggle_mouth":
			state["mouth_toggle_count"] = int(state["mouth_toggle_count"]) + 1
		"sound_command":
			var sound_id := int(event.get("id", _first_argument(event)))
			var sound_ids: Array = state["sound_ids"]
			sound_ids.append(sound_id)
			state["sound_ids"] = sound_ids
			sound_requested.emit(sound_id, event.duplicate(true))
		"jump":
			var target := int(event.get("target", -1))
			if not _cpu_to_event.has(target):
				push_error("Cutscene jump target %04X is outside the extracted script." % target)
				_finished = true
				return true
			_pc = int(_cpu_to_event[target])
			if target == int(events[0].get("cpu", -1)):
				script_looped.emit(event.duplicate(true))
			# FE is ordinary control flow. Continue until the next explicit wait,
			# as the source bytecode does, without inventing an extra script tick.
			return false
		"exit":
			_finished = true
			return true
		_:
			# Keep unknown/future opcodes observable to the renderer without
			# guessing behavior. The raw bytes remain available on every event.
			if opcode >= 0 or not raw_bytes.is_empty():
				pass
	return false


func _first_argument(event: Dictionary) -> int:
	var args: Array = event.get("a", [])
	return int(args[0]) if not args.is_empty() else -1


func _reveal_pending_text_tile() -> void:
	if _pending_text_index >= _pending_text_tiles.size():
		return
	var tile_id := _pending_text_tiles[_pending_text_index]
	_pending_text_index += 1
	var lines: Array = state["text_lines"]
	if lines.is_empty():
		lines.append([])
	var current_line: Array = lines[lines.size() - 1]
	current_line.append(tile_id)
	state["text_lines"] = lines
	state["last_text_tile"] = tile_id
	state["text_tiles_revealed"] = int(state.get("text_tiles_revealed", 0)) + 1
	text_tile_revealed.emit(tile_id, _pending_text_index - 1, _pending_text_event.duplicate(true))
