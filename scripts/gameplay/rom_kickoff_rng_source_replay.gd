extends RefCounted
class_name RomKickoffRngSourceReplay
## Replays the ROM-stepper RNG update calls for one fingerprinted fresh-start
## route. This is deliberately not a generic replacement for the game's RNG.

const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_SCHEMA := "ct2-kickoff-rom-rng-replay-v2"
const EXPECTED_ROUTE_ID := "turkish-fresh-kickoff-capture-20261027"
const RECEIVER_TABLE := [0x05, 0x06, 0x07, 0x09, 0x0A]
const RNG_ARITHMETIC_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_arithmetic.gd")

var error_message := ""
var route_identity := ""
var input_timeline_sha256 := ""
var last_source_frame := 0
var e1 := 0
var e2 := 0
var e3 := 0
var a117_update_count := 0
var c9c5_update_count := 0
var receiver_source_frame := -1
var receiver_source_cycle := -1
var receiver_slot := -1
var _receiver_state := Vector3i(-1, -1, -1)

var _a117_frame_set: Dictionary = {}
var _c9c5_state_by_frame: Dictionary = {}
var _c9c5_inputs_by_frame: Dictionary = {}
var _configured := false
var _input_identity_bound := false


func configure(schedule_path: String, observed_input_timeline_sha256: String) -> bool:
	_reset()
	if observed_input_timeline_sha256.is_empty():
		return _fail("An observed route input-timeline hash is required.")
	if not FileAccess.file_exists(schedule_path):
		return _fail("RNG source schedule is missing: %s" % schedule_path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(schedule_path))
	if not parsed is Dictionary:
		return _fail("RNG source schedule is not a JSON object.")
	var document: Dictionary = parsed
	if str(document.get("schema", "")) != EXPECTED_SCHEMA:
		return _fail("Unsupported RNG source schedule schema.")
	if str(document.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("RNG schedule targets a different ROM revision.")
	var input_route: Variant = document.get("input_route", {})
	if not input_route is Dictionary:
		return _fail("RNG schedule is missing its input route identity.")
	input_timeline_sha256 = str(input_route.get("sha256", ""))
	if observed_input_timeline_sha256 != input_timeline_sha256:
		return _fail("Observed input route does not match the audited RNG schedule.")
	_input_identity_bound = true
	route_identity = str(document.get("route_identity", ""))
	if route_identity != EXPECTED_ROUTE_ID:
		return _fail("RNG schedule targets a different audited route.")

	var reset_state: Variant = document.get("cold_reset_state", {})
	if not reset_state is Dictionary \
			or int(reset_state.get("e1", -1)) != 0 \
			or int(reset_state.get("e2", -1)) != 0 \
			or int(reset_state.get("e3", -1)) != 0:
		return _fail("RNG schedule does not begin at the ROM cold-reset state.")
	var updates: Variant = document.get("updates", {})
	if not updates is Dictionary:
		return _fail("RNG schedule is missing update records.")
	var a117: Variant = updates.get("a117", {})
	var c9c5: Variant = updates.get("c9c5", {})
	if not a117 is Dictionary or not c9c5 is Dictionary:
		return _fail("RNG schedule update records are malformed.")
	var frame_runs: Variant = a117.get("frame_runs_inclusive", [])
	if not frame_runs is Array:
		return _fail("A117 frame ranges are malformed.")
	for run_variant in frame_runs:
		if not run_variant is Array or run_variant.size() != 2:
			return _fail("A117 frame range must contain an inclusive start and end.")
		var first_frame := int(run_variant[0])
		var last_frame := int(run_variant[1])
		if first_frame < 1 or last_frame < first_frame:
			return _fail("A117 frame range is invalid.")
		for source_frame in range(first_frame, last_frame + 1):
			if _a117_frame_set.has(source_frame):
				return _fail("A117 frame ranges overlap.")
			_a117_frame_set[source_frame] = true
	if _a117_frame_set.size() != int(a117.get("count", -1)):
		return _fail("A117 frame count does not match its compressed ranges.")

	var c9_rows: Variant = c9c5.get("state_after_each_call", [])
	if not c9_rows is Array:
		return _fail("C9C5 call-state records are malformed.")
	for row_variant in c9_rows:
		if not row_variant is Array or row_variant.size() != 5:
			return _fail("C9C5 row must contain frame, cycle, and E1/E2/E3.")
		var source_frame := int(row_variant[0])
		if source_frame < 1 or _c9c5_state_by_frame.has(source_frame):
			return _fail("C9C5 source frames must be unique and positive.")
		if _a117_frame_set.has(source_frame):
			return _fail("Schedule has overlapping A117 and C9C5 updates.")
		_c9c5_state_by_frame[source_frame] = {
			"cycle": int(row_variant[1]),
			"e1": int(row_variant[2]),
			"e2": int(row_variant[3]),
			"e3": int(row_variant[4]),
		}
	if _c9c5_state_by_frame.size() != int(c9c5.get("count", -1)):
		return _fail("C9C5 call count does not match its state records.")
	var operand_rows: Variant = c9c5.get("source_operands_each_call", [])
	if not operand_rows is Array:
		return _fail("C9C5 source operand rows are malformed.")
	for row_variant in operand_rows:
		if not row_variant is Array or row_variant.size() != 18:
			return _fail("C9C5 source operand row must contain 18 values.")
		var row: Array = row_variant
		var source_frame := int(row[0])
		if source_frame < 1 or _c9c5_inputs_by_frame.has(source_frame) \
				or not _c9c5_state_by_frame.has(source_frame):
			return _fail("C9C5 operand rows must uniquely match a result row.")
		var e1_before := int(row[2])
		var e2_before := int(row[3])
		var e3_before := int(row[4])
		var carry_in := int(row[5])
		var x0300 := int(row[6])
		var address0300 := int(row[7])
		var value0300 := int(row[8])
		var x0700 := int(row[9])
		var address0700 := int(row[10])
		var value0700 := int(row[11])
		var x0780 := int(row[12])
		var address0780 := int(row[13])
		var value0780 := int(row[14])
		var state_after: Dictionary = _c9c5_state_by_frame[source_frame]
		if int(row[1]) != int(state_after["cycle"]) \
				or int(row[15]) != int(state_after["e1"]) \
				or int(row[16]) != int(state_after["e2"]) \
				or int(row[17]) != int(state_after["e3"]) \
				or e1_before < 0 or e1_before > 0xFF \
				or e2_before < 0 or e2_before > 0xFF \
				or e3_before < 0 or e3_before > 0xFF \
				or carry_in < 0 or carry_in > 1 \
				or x0300 != e1_before or x0700 != e1_before or x0780 != e1_before \
				or address0300 != 0x0300 + x0300 \
				or address0700 != 0x0700 + x0700 \
				or address0780 != 0x0780 + x0780 \
				or value0300 < 0 or value0300 > 0xFF \
				or value0700 < 0 or value0700 > 0xFF \
				or value0780 < 0 or value0780 > 0xFF:
			return _fail("C9C5 source operands do not match the call's X, address, carry, or source cycle.")
		_c9c5_inputs_by_frame[source_frame] = {
			"e1_before": e1_before,
			"e2_before": e2_before,
			"e3_before": e3_before,
			"carry_in": carry_in,
			"value0300": value0300,
			"value0700": value0700,
			"value0780": value0780,
		}
	if _c9c5_inputs_by_frame.size() != _c9c5_state_by_frame.size():
		return _fail("C9C5 source operand count does not match its call-state records.")

	var receiver: Variant = document.get("receiver_selection", {})
	if not receiver is Dictionary:
		return _fail("RNG schedule is missing the receiver-selection event.")
	receiver_source_frame = int(receiver.get("source_frame", -1))
	receiver_source_cycle = int(receiver.get("source_cycle", -1))
	receiver_slot = int(receiver.get("slot", -1))
	_receiver_state = Vector3i(
		int(receiver.get("e1", -1)),
		int(receiver.get("e2", -1)),
		int(receiver.get("e3", -1))
	)
	if receiver_source_frame < 1 or receiver_source_cycle < 0 \
			or receiver_slot < 0 or receiver_slot > 0xFF \
			or _receiver_state.x < 0 or _receiver_state.x > 0xFF \
			or _receiver_state.y < 0 or _receiver_state.y > 0xFF \
			or _receiver_state.z < 0 or _receiver_state.z > 0xFF:
		return _fail("Receiver-selection event is invalid.")
	if not _input_identity_bound:
		return _fail("The observed route input identity was not bound.")
	_configured = true
	return true


func reset_from_cold_start() -> void:
	e1 = 0
	e2 = 0
	e3 = 0
	last_source_frame = 0
	a117_update_count = 0
	c9c5_update_count = 0


func advance_to_source_frame(source_frame: int) -> bool:
	if not _configured:
		return _fail("Configure the audited route schedule before advancing it.")
	if source_frame < last_source_frame or source_frame < 0:
		return _fail("RNG source frames must advance monotonically.")
	if source_frame > receiver_source_frame:
		return _fail("Audited RNG schedule ends at receiver selection.")
	for frame in range(last_source_frame + 1, source_frame + 1):
		if _a117_frame_set.has(frame):
			_advance_a117()
		elif _c9c5_state_by_frame.has(frame):
			var input: Dictionary = _c9c5_inputs_by_frame[frame]
			if e1 != int(input["e1_before"]) \
					or e2 != int(input["e2_before"]) \
					or e3 != int(input["e3_before"]):
				return _fail("C9C5 input state differs from the prior ROM-derived RNG calls.")
			var source_ram := PackedByteArray()
			source_ram.resize(0x0800)
			source_ram.fill(0)
			source_ram[(0x0300 + e1) & 0x07FF] = int(input["value0300"])
			source_ram[(0x0700 + e1) & 0x07FF] = int(input["value0700"])
			source_ram[(0x0780 + e1) & 0x07FF] = int(input["value0780"])
			var result: Vector4i = RNG_ARITHMETIC_SCRIPT.step_c9c5(
				e1, e2, e3, int(input["carry_in"]), source_ram)
			var expected_state: Dictionary = _c9c5_state_by_frame[frame]
			if result.x != int(expected_state["e1"]) \
					or result.y != int(expected_state["e2"]) \
					or result.z != int(expected_state["e3"]):
				return _fail("ROM C9C5 arithmetic output differs from its recorded source-stepper result.")
			e1 = result.x
			e2 = result.y
			e3 = result.z
			c9c5_update_count += 1
		last_source_frame = frame
	if source_frame == receiver_source_frame:
		if Vector3i(e1, e2, e3) != _receiver_state:
			return _fail("Replayed RNG state differs from the receiver-selection source state.")
		if get_receiver_slot() != receiver_slot:
			return _fail("Replayed RNG state resolves to a different receiver slot.")
	return true


func get_receiver_slot() -> int:
	if not _configured or not _input_identity_bound \
			or last_source_frame < receiver_source_frame:
		return -1
	var table_index := e2 & 0x07
	if table_index >= RECEIVER_TABLE.size():
		table_index -= RECEIVER_TABLE.size()
	return RECEIVER_TABLE[table_index]


func get_state() -> Dictionary:
	return {
		"configured": _configured,
		"route_identity": route_identity,
		"input_timeline_sha256": input_timeline_sha256,
		"input_identity_bound": _input_identity_bound,
		"last_source_frame": last_source_frame,
		"e1": e1,
		"e2": e2,
		"e3": e3,
		"a117_updates_applied": a117_update_count,
		"c9c5_updates_applied": c9c5_update_count,
		"receiver_source_frame": receiver_source_frame,
		"receiver_slot_calculated": get_receiver_slot(),
		"error": error_message,
	}


func _advance_a117() -> void:
	var sum_e1 := e1 + 0x83
	var carry_e1 := 1 if sum_e1 > 0xFF else 0
	e1 = sum_e1 & 0xFF
	var sum_e2 := e2 + 0x0D + carry_e1
	var carry_e2 := 1 if sum_e2 > 0xFF else 0
	e2 = sum_e2 & 0xFF
	e3 = (e3 + 0x11 + carry_e2) & 0xFF
	a117_update_count += 1


func _reset() -> void:
	error_message = ""
	route_identity = ""
	input_timeline_sha256 = ""
	last_source_frame = 0
	e1 = 0
	e2 = 0
	e3 = 0
	a117_update_count = 0
	c9c5_update_count = 0
	receiver_source_frame = -1
	receiver_source_cycle = -1
	receiver_slot = -1
	_receiver_state = Vector3i(-1, -1, -1)
	_a117_frame_set.clear()
	_c9c5_state_by_frame.clear()
	_c9c5_inputs_by_frame.clear()
	_configured = false
	_input_identity_bound = false


func _fail(message: String) -> bool:
	error_message = message
	return false
