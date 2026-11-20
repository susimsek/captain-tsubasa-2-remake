extends RefCounted
class_name RomKickoffRngPassExtension
## Replays the ROM-only source-stepper RNG calls after the first-match receiver
## selection. The extension is tied to the recorded PASS route, not a generic RNG.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCHEMA := "ct2-kickoff-rom-rng-pass-extension-v1"
const ROUTE_ID := "turkish-fresh-kickoff-first-pass-route-20261110"
const INPUT_SHA256 := "92bd6e971ea5c59672fd2a7a4eece18d797c0fb006ea7f427f9b521dcbec42e0"
const SOURCE_STEPPER_SHA256 := "233a721c91b17b56e3527bfc336ab47d020186b44a7da15f322224aa674e493a"
const BUILDER_SHA256 := "2b9e1acbb15d19dc51ddf85820c32929e4e52d0078211f9e07eb459d143140f5"
const BASE_SCHEDULE_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const EXTENSION_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_pass_extension.json"
const ARITHMETIC := preload("res://scripts/gameplay/rom_kickoff_rng_arithmetic.gd")
const START_FRAME := 8593
const END_FRAME := 9600

var error_message := ""
var e1 := 0
var e2 := 0
var e3 := 0
var last_source_frame := START_FRAME
var c9c5_call_count := 0
var a117_call_count := 0
var base_schedule_sha256 := ""
var _start_state: Dictionary = {}

var _a117_frame_set: Dictionary = {}
var _c9c5_state_by_frame: Dictionary = {}
var _c9c5_inputs_by_frame: Dictionary = {}
var _observed_pre_state: Dictionary = {}
var _configured := false
var _started := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_started = false
	var base_bytes := FileAccess.get_file_as_bytes(BASE_SCHEDULE_PATH)
	var extension_bytes := FileAccess.get_file_as_bytes(EXTENSION_PATH)
	if base_bytes.is_empty() or extension_bytes.is_empty():
		return _fail("The base RNG route or first-PASS extension source is unavailable.")
	base_schedule_sha256 = _sha256(base_bytes)
	var base: Variant = JSON.parse_string(base_bytes.get_string_from_utf8())
	var parsed: Variant = JSON.parse_string(extension_bytes.get_string_from_utf8())
	if not base is Dictionary or not parsed is Dictionary:
		return _fail("The base RNG schedule and first-PASS extension must be JSON objects.")
	var document: Dictionary = parsed
	if String(document.get("schema", "")) != SCHEMA \
			or String(document.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(document.get("source_stepper_sha256", "")) != SOURCE_STEPPER_SHA256 \
			or String(document.get("source_schedule_builder_sha256", "")) != BUILDER_SHA256 \
			or String(document.get("route_identity", "")) != ROUTE_ID \
			or String(document.get("base_schedule_sha256", "")) != base_schedule_sha256:
		return _fail("The first-PASS RNG extension provenance does not match its pinned ROM/source route.")
	var source_model: Variant = document.get("source_model", {})
	if not source_model is Dictionary \
			or String(source_model.get("name", "")) != "ROM-only 6502/PPU/DMC source stepper" \
			or bool(source_model.get("target_ram_dumps_used_as_inputs", true)) \
			or bool(source_model.get("fceux_ram_or_captures_used_as_inputs", true)):
		return _fail("The first-PASS RNG extension is not a ROM-only source-stepper output.")
	var route: Variant = document.get("input_route", {})
	if not route is Dictionary or String(route.get("sha256", "")) != INPUT_SHA256 \
			or int(route.get("first_source_frame", -1)) != 0 \
			or int(route.get("last_source_frame", -1)) != END_FRAME:
		return _fail("The first-PASS RNG extension is not bound to the verified 0..9600 input route.")
	var base_document: Dictionary = base
	var receiver: Variant = base_document.get("receiver_selection", {})
	var extension_receiver: Variant = document.get("base_receiver_event", {})
	var start_state: Variant = document.get("start_state", {})
	if not receiver is Dictionary or not extension_receiver is Dictionary \
			or not start_state is Dictionary \
			or int(receiver.get("source_frame", -1)) != int(extension_receiver.get("source_frame", -2)) \
			or int(receiver.get("source_cycle", -1)) != int(extension_receiver.get("source_cycle", -2)) \
			or int(receiver.get("e1", -1)) != int(extension_receiver.get("e1", -2)) \
			or int(receiver.get("e2", -1)) != int(extension_receiver.get("e2", -2)) \
			or int(receiver.get("e3", -1)) != int(extension_receiver.get("e3", -2)) \
			or int(receiver.get("slot", -1)) != int(extension_receiver.get("slot", -2)) \
			or int(receiver.get("source_frame", -1)) != START_FRAME \
			or int(start_state.get("e1", -1)) != int(receiver.get("e1", -2)) \
			or int(start_state.get("e2", -1)) != int(receiver.get("e2", -2)) \
			or int(start_state.get("e3", -1)) != int(receiver.get("e3", -2)):
		return _fail("The first-PASS RNG start state does not match the ROM receiver event at frame 8593.")
	e1 = int(start_state["e1"])
	e2 = int(start_state["e2"])
	e3 = int(start_state["e3"])
	_start_state = start_state.duplicate(true)
	var updates: Variant = document.get("updates", {})
	if not updates is Dictionary:
		return _fail("The first-PASS RNG extension has no source update records.")
	var a117_frames: Variant = updates.get("a117_frames", [])
	if not a117_frames is Array:
		return _fail("The first-PASS A117 frame list is malformed.")
	if not a117_frames.is_empty():
		return _fail("The current PASS extension contract expects no A117 calls after frame 8593.")
	for frame_variant in a117_frames:
		var frame := int(frame_variant)
		if frame <= START_FRAME or frame > END_FRAME or _a117_frame_set.has(frame):
			return _fail("The first-PASS A117 frame lies outside the monotonic extension.")
		_a117_frame_set[frame] = true
	var c9_states: Variant = updates.get("c9c5_state_after_each_call", [])
	var c9_operands: Variant = updates.get("c9c5_operands_each_call", [])
	if not c9_states is Array or not c9_operands is Array \
			or c9_states.size() != c9_operands.size() \
			or c9_states.size() != int(updates.get("c9c5_count", -1)):
		return _fail("The first-PASS C9C5 result and operand rows differ in size.")
	for index in range(c9_states.size()):
		var state_row: Variant = c9_states[index]
		var operand_row: Variant = c9_operands[index]
		if not state_row is Array or state_row.size() != 5 \
				or not operand_row is Array or operand_row.size() != 18:
			return _fail("The first-PASS C9C5 row has an invalid layout.")
		var frame := int(state_row[0])
		if frame <= START_FRAME or frame > END_FRAME or _c9c5_state_by_frame.has(frame) \
				or _a117_frame_set.has(frame):
			return _fail("The first-PASS RNG updates overlap or lie outside frames 8594..9600.")
		if int(operand_row[0]) != frame or int(operand_row[1]) != int(state_row[1]) \
				or int(operand_row[15]) != int(state_row[2]) \
				or int(operand_row[16]) != int(state_row[3]) \
				or int(operand_row[17]) != int(state_row[4]):
			return _fail("The first-PASS C9C5 operand row does not match its result row.")
		for operand_index in [2, 3, 4, 6, 8, 11, 14, 15, 16, 17]:
			if int(operand_row[operand_index]) < 0 or int(operand_row[operand_index]) > 0xFF:
				return _fail("A first-PASS C9C5 operand or state value is not a byte.")
		if int(operand_row[5]) != 1 \
				or int(operand_row[6]) != int(operand_row[2]) \
				or int(operand_row[9]) != int(operand_row[2]) \
				or int(operand_row[12]) != int(operand_row[2]) \
				or int(operand_row[7]) != 0x0300 + int(operand_row[2]) \
				or int(operand_row[10]) != 0x0700 + int(operand_row[2]) \
				or int(operand_row[13]) != 0x0780 + int(operand_row[2]):
			return _fail("The first-PASS C9C5 indexed reads do not match the ROM X/address/carry contract.")
		_c9c5_state_by_frame[frame] = {
			"cycle": int(state_row[1]), "e1": int(state_row[2]),
			"e2": int(state_row[3]), "e3": int(state_row[4]),
		}
		_c9c5_inputs_by_frame[frame] = {
			"e1_before": int(operand_row[2]), "e2_before": int(operand_row[3]),
			"e3_before": int(operand_row[4]), "carry_in": int(operand_row[5]),
			"value0300": int(operand_row[8]), "value0700": int(operand_row[11]),
			"value0780": int(operand_row[14]),
		}
	if _c9c5_state_by_frame.size() != END_FRAME - START_FRAME:
		return _fail("The first-PASS extension must contain one C9C5 update for every frame 8594..9600.")
	for frame in range(START_FRAME + 1, END_FRAME + 1):
		if not _c9c5_state_by_frame.has(frame):
			return _fail("The first-PASS C9C5 call stream has a gap at frame %d." % frame)
	_configured = true
	return true


func reset_replay() -> bool:
	if not _configured or _start_state.is_empty():
		return _fail("Configure the first-PASS RNG extension before resetting its route state.")
	e1 = int(_start_state["e1"])
	e2 = int(_start_state["e2"])
	e3 = int(_start_state["e3"])
	last_source_frame = START_FRAME
	c9c5_call_count = 0
	a117_call_count = 0
	_observed_pre_state.clear()
	_started = false
	error_message = ""
	return true


func begin_from_base_replay(base_state: Dictionary) -> bool:
	if not _configured or _started:
		return _fail("Configure the first-PASS RNG extension before starting it once.")
	if String(base_state.get("route_identity", "")) != "turkish-fresh-kickoff-capture-20261027" \
			or String(base_state.get("input_timeline_sha256", "")) != "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc" \
			or int(base_state.get("last_source_frame", -1)) != START_FRAME \
			or int(base_state.get("e1", -1)) != e1 or int(base_state.get("e2", -1)) != e2 \
			or int(base_state.get("e3", -1)) != e3:
		return _fail("The base RNG replay did not end at the matching ROM receiver state at frame 8593.")
	_started = true
	last_source_frame = START_FRAME
	_observed_pre_state.clear()
	return true


func advance_to_source_frame(source_frame: int, observed_live_state: Dictionary) -> bool:
	if not _configured or not _started:
		return _fail("The first-PASS RNG extension must start from the verified base receiver event.")
	if source_frame != last_source_frame + 1 or source_frame > END_FRAME:
		return _fail("First-PASS RNG events must advance one source frame at a time through frame 9600.")
	if not _c9c5_state_by_frame.has(source_frame):
		return _fail("The ROM-only first-PASS source stream has no C9C5 event at frame %d." % source_frame)
	var input: Dictionary = _c9c5_inputs_by_frame[source_frame]
	var expected: Dictionary = _c9c5_state_by_frame[source_frame]
	var live_e1 := int(observed_live_state.get("e1", -1))
	var live_e2 := int(observed_live_state.get("e2", -1))
	var live_e3 := int(observed_live_state.get("e3", -1))
	if live_e1 != int(input["e1_before"]) or live_e2 != int(input["e2_before"]) \
			or live_e3 != int(input["e3_before"]):
		return _fail("Live scheduler RNG %02X/%02X/%02X does not match ROM-only C9C5 pre-state %02X/%02X/%02X at frame %d." % [
			live_e1, live_e2, live_e3, int(input["e1_before"]),
			int(input["e2_before"]), int(input["e3_before"]), source_frame])
	var source_ram := PackedByteArray()
	source_ram.resize(0x0800)
	source_ram.fill(0)
	source_ram[(0x0300 + live_e1) & 0x07FF] = int(input["value0300"])
	source_ram[(0x0700 + live_e1) & 0x07FF] = int(input["value0700"])
	source_ram[(0x0780 + live_e1) & 0x07FF] = int(input["value0780"])
	var result: Vector4i = ARITHMETIC.step_c9c5(
		live_e1, live_e2, live_e3, int(input["carry_in"]), source_ram)
	if result.x != int(expected["e1"]) or result.y != int(expected["e2"]) \
			or result.z != int(expected["e3"]):
		return _fail("The first-PASS C9C5 output differs from the ROM-only source stepper result.")
	e1 = result.x
	e2 = result.y
	e3 = result.z
	_observed_pre_state = {"e1": live_e1, "e2": live_e2, "e3": live_e3}
	c9c5_call_count += 1
	last_source_frame = source_frame
	return true


func get_state() -> Dictionary:
	return {
		"configured": _configured, "started": _started,
		"source_rom_sha256": ROM_SHA256,
		"route_identity": ROUTE_ID, "input_timeline_sha256": INPUT_SHA256,
		"last_source_frame": last_source_frame, "e1": e1, "e2": e2, "e3": e3,
		"a117_updates_applied": a117_call_count, "c9c5_updates_applied": c9c5_call_count,
		"source_stepper_sha256": SOURCE_STEPPER_SHA256,
		"source_schedule_builder_sha256": BUILDER_SHA256,
		"base_schedule_sha256": base_schedule_sha256,
		"observed_pre_state": _observed_pre_state.duplicate(true),
		"rom_c9c5_event_validated": _observed_pre_state.size() == 3,
		"fceux_ram_or_captures_used_as_inputs": false,
	}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
