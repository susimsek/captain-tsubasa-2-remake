extends RefCounted
class_name RomKickoffRngSourceReplay
## Replays the ROM-stepper RNG update calls for one fingerprinted fresh-start
## route. This is deliberately not a generic replacement for the game's RNG.

const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_SCHEMA := "ct2-kickoff-rom-rng-replay-v6"
const EXPECTED_ROUTE_ID := "turkish-fresh-kickoff-capture-20261027"
const EXPECTED_SOURCE_STEPPER_SHA256 := "233a721c91b17b56e3527bfc336ab47d020186b44a7da15f322224aa674e493a"
const EXPECTED_SCHEDULE_BUILDER_SHA256 := "2b9e1acbb15d19dc51ddf85820c32929e4e52d0078211f9e07eb459d143140f5"
const RECEIVER_TABLE := [0x05, 0x06, 0x07, 0x09, 0x0A]
const SOUND_QUEUE_INPUT_ADDRESSES: Array[int] = [0x0700, 0x0701, 0x0702,
	0x0703, 0x0704, 0x0705, 0x0706, 0x07E9]
const RNG_ARITHMETIC_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_arithmetic.gd")
const A117_STORE_PCS: Array[int] = [0xA11B, 0xA121, 0xA127]

var error_message := ""
var route_identity := ""
var input_timeline_sha256 := ""
var last_source_frame := 0
var schedule_end_source_frame := -1
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
var _counter_003a_frame_set: Dictionary = {}
var _pre_candidate_counter_003a_history: Dictionary = {}
var _pre_candidate_sound_queue_inputs: Dictionary = {}
var _pre_candidate_mode_001b_history: Dictionary = {}
var _pre_candidate_saved_bank_07fc_history: Dictionary = {}
var _c9c5_state_by_frame: Dictionary = {}
var _c9c5_inputs_by_frame: Dictionary = {}
var _last_a117_source_frame := -1
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
	if str(document.get("source_stepper_sha256", "")) != EXPECTED_SOURCE_STEPPER_SHA256:
		return _fail("RNG schedule was produced by an unaudited or different source stepper revision.")
	if str(document.get("source_schedule_builder_sha256", "")) != EXPECTED_SCHEDULE_BUILDER_SHA256:
		return _fail("RNG schedule was produced by an unaudited or different source-schedule builder revision.")
	var source_model: Variant = document.get("source_model", {})
	if not source_model is Dictionary \
			or String(source_model.get("name", "")) != "ROM-only 6502/PPU/DMC source stepper" \
			or bool(source_model.get("target_ram_dumps_used_as_inputs", true)):
		return _fail("RNG source schedule does not identify a ROM-only input model.")
	var input_route: Variant = document.get("input_route", {})
	if not input_route is Dictionary:
		return _fail("RNG schedule is missing its input route identity.")
	input_timeline_sha256 = str(input_route.get("sha256", ""))
	schedule_end_source_frame = int(input_route.get("last_source_frame", -1))
	if schedule_end_source_frame != 9042:
		return _fail("Base RNG schedule must end at its recorded-input boundary on frame 9042.")
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
	var counter_history: Variant = updates.get("pre_candidate_counter_003a", {})
	if not counter_history is Dictionary \
			or int(counter_history.get("candidate_source_frame", -1)) != 7266 \
			or int(counter_history.get("increment_source_pc", -1)) != 0xA135 \
			or int(counter_history.get("increment_prg_bank", -1)) != 2 \
			or int(counter_history.get("unexpected_writer_count", -1)) != 0:
		return _fail("The ROM-stepper `$003A` pre-candidate writer history is missing or malformed.")
	var counter_runs: Variant = counter_history.get("increment_frame_runs_inclusive", [])
	if not counter_runs is Array:
		return _fail("The `$003A` increment frame ranges are malformed.")
	for run_variant in counter_runs:
		if not run_variant is Array or run_variant.size() != 2:
			return _fail("A `$003A` increment range must contain an inclusive start and end.")
		var first_frame := int(run_variant[0])
		var last_frame := int(run_variant[1])
		if first_frame < 1 or last_frame < first_frame or last_frame >= 7266:
			return _fail("A `$003A` increment range is invalid for the pre-candidate history.")
		for source_frame in range(first_frame, last_frame + 1):
			if _counter_003a_frame_set.has(source_frame):
				return _fail("`$003A` increment frame ranges overlap.")
			_counter_003a_frame_set[source_frame] = true
	if _counter_003a_frame_set.size() != int(counter_history.get("increment_count", -1)):
		return _fail("`$003A` increment count does not match its compressed frame ranges.")
	var a117_pre_candidate_count := 0
	for source_frame_variant in _a117_frame_set:
		var source_frame := int(source_frame_variant)
		if source_frame >= 7266:
			continue
		a117_pre_candidate_count += 1
		if not _counter_003a_frame_set.has(source_frame):
			return _fail("A pre-candidate A117 update has no paired `$A135` increment.")
	if a117_pre_candidate_count != _counter_003a_frame_set.size():
		return _fail("A pre-candidate `$A135` increment has no paired A117 update.")
	var counter_initializers: Variant = counter_history.get("initialization_writes", [])
	if not counter_initializers is Array or counter_initializers.size() != 2:
		return _fail("The `$003A` counter history must include both source initialization writes.")
	_pre_candidate_counter_003a_history = counter_history.duplicate(true)
	var sound_queue_history: Variant = updates.get("pre_candidate_sound_queue", {})
	if not sound_queue_history is Dictionary \
			or int(sound_queue_history.get("candidate_source_frame", -1)) != 7266 \
			or int(sound_queue_history.get("candidate_source_cycle", -1)) != 216355361 \
			or int(sound_queue_history.get("candidate_source_pc", -1)) != 0xC421 \
			or String(sound_queue_history.get("source_event_id", "")) \
			!= "rom-source-nmi-7266-216355361" \
			or String(sound_queue_history.get("source_ram_sha256", "")) \
			!= "aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0":
		return _fail("The ROM-stepper sound-queue input boundary does not match the audited frame-7266 `$C421` event.")
	var queue_values: Variant = sound_queue_history.get("values", {})
	var queue_summary: Variant = sound_queue_history.get("writer_summary", [])
	var mode_summary: Variant = sound_queue_history.get("mode_001b_writer_summary", [])
	if not queue_values is Dictionary or not queue_summary is Array \
			or queue_summary.size() != 89 \
			or int(sound_queue_history.get("write_count", -1)) != 58199 \
			or int(sound_queue_history.get("mode_001b_value", -1)) != 0xC0 \
			or not mode_summary is Array or mode_summary.size() != 9 \
			or int(sound_queue_history.get("mode_001b_write_count", -1)) != 14508:
		return _fail("The ROM-stepper sound-queue input writer history is missing or malformed.")
	var expected_queue_write_counts := {
		0x0700: 46, 0x0701: 1, 0x0702: 1, 0x0703: 1,
		0x0704: 1, 0x0705: 1, 0x0706: 58147, 0x07E9: 1,
	}
	var observed_queue_write_counts: Dictionary = {}
	var observed_queue_write_total := 0
	for address in SOUND_QUEUE_INPUT_ADDRESSES:
		var key := "%04X" % address
		if not queue_values.has(key) or int(queue_values[key]) != 0:
			return _fail("ROM source boundary did not produce zero at sound-driver input `$%04X`." % address)
		observed_queue_write_counts[address] = 0
	for row_variant in queue_summary:
		if not row_variant is Dictionary:
			return _fail("A ROM-stepper sound-queue writer summary row is malformed.")
		var row: Dictionary = row_variant
		var address := int(row.get("address", -1))
		var count := int(row.get("count", -1))
		var first_frame := int(row.get("first_source_frame", -1))
		var last_frame := int(row.get("last_source_frame", -1))
		var first_cycle := int(row.get("first_source_cycle", -1))
		var last_cycle := int(row.get("last_source_cycle", -1))
		if address not in SOUND_QUEUE_INPUT_ADDRESSES or count <= 0 \
				or int(row.get("source_pc", -1)) < 0x8000 \
				or int(row.get("prg_bank", -1)) < 0 \
				or int(row.get("value", -1)) < 0 or int(row.get("value", -1)) > 0xFF \
				or first_frame < 1 or last_frame > 7266 or last_frame < first_frame \
				or first_cycle < 0 or last_cycle >= 216355361 or last_cycle < first_cycle:
			return _fail("A ROM-stepper sound-queue writer summary row has an invalid address or source boundary.")
		observed_queue_write_counts[address] = int(observed_queue_write_counts[address]) + count
		observed_queue_write_total += count
	if observed_queue_write_total != 58199 \
			or observed_queue_write_counts != expected_queue_write_counts:
		return _fail("ROM-stepper sound-queue writer counts do not match the audited pre-candidate route.")
	_pre_candidate_sound_queue_inputs = sound_queue_history.duplicate(true)
	var expected_mode_writer_counts := {
		"808B:00:40": 1, "9F0A:00:40": 6948, "9F0A:00:41": 300,
		"A133:02:C0": 6955, "A133:02:C1": 300, "A228:02:40": 1,
		"A51E:02:41": 1, "A52E:02:40": 1, "C670:1E:00": 1,
	}
	var observed_mode_writer_counts: Dictionary = {}
	var observed_mode_write_total := 0
	var latest_mode_writer: Dictionary = {}
	for row_variant in mode_summary:
		if not row_variant is Dictionary:
			return _fail("A ROM-stepper `$001B` writer summary row is malformed.")
		var row: Dictionary = row_variant
		var source_pc := int(row.get("source_pc", -1))
		var bank := int(row.get("prg_bank", -1))
		var value := int(row.get("value", -1))
		var count := int(row.get("count", -1))
		var first_frame := int(row.get("first_source_frame", -1))
		var last_frame := int(row.get("last_source_frame", -1))
		var first_cycle := int(row.get("first_source_cycle", -1))
		var last_cycle := int(row.get("last_source_cycle", -1))
		var signature := "%04X:%02X:%02X" % [source_pc, bank, value]
		if int(row.get("address", -1)) != 0x001B or not expected_mode_writer_counts.has(signature) \
				or count <= 0 or first_frame < 1 or last_frame > 7265 or last_frame < first_frame \
				or first_cycle < 0 or last_cycle >= 216355361 or last_cycle < first_cycle:
			return _fail("The ROM-stepper `$001B` writer summary crosses or diverges from the candidate boundary.")
		observed_mode_writer_counts[signature] = count
		observed_mode_write_total += count
		if last_cycle > int(latest_mode_writer.get("last_source_cycle", -1)):
			latest_mode_writer = row.duplicate(true)
	if observed_mode_writer_counts != expected_mode_writer_counts \
			or observed_mode_write_total != 14508 \
			or int(latest_mode_writer.get("source_pc", -1)) != 0xA133 \
			or int(latest_mode_writer.get("prg_bank", -1)) != 0x02 \
			or int(latest_mode_writer.get("value", -1)) != 0xC0 \
			or int(latest_mode_writer.get("last_source_frame", -1)) != 7265 \
			or int(latest_mode_writer.get("last_source_cycle", -1)) != 216326882:
		return _fail("The ROM-stepper `$001B` history does not end at the source `$A133` set before candidate `$C421`.")
	_pre_candidate_mode_001b_history = {
		"candidate_source_frame": 7266,
		"candidate_source_cycle": 216355361,
		"candidate_source_pc": 0xC421,
		"mode_001b_value": int(sound_queue_history["mode_001b_value"]),
		"write_count": observed_mode_write_total,
		"writer_summary": mode_summary.duplicate(true),
		"latest_writer": latest_mode_writer.duplicate(true),
	}
	var saved_bank_summary: Variant = sound_queue_history.get("saved_bank_07fc_writer_summary", [])
	var expected_saved_bank_writer_counts := {"804D:0C:0F": 3, "C670:1E:00": 1}
	if not saved_bank_summary is Array or saved_bank_summary.size() != 2 \
			or int(sound_queue_history.get("saved_bank_07fc_value", -1)) != 0x0F \
			or int(sound_queue_history.get("saved_bank_07fc_write_count", -1)) != 4:
		return _fail("The ROM-stepper saved-bank `$07FC` history is missing or malformed.")
	var observed_saved_bank_counts: Dictionary = {}
	var saved_bank_write_total := 0
	var latest_saved_bank_writer: Dictionary = {}
	for row_variant in saved_bank_summary:
		if not row_variant is Dictionary:
			return _fail("A ROM-stepper `$07FC` writer summary row is malformed.")
		var row: Dictionary = row_variant
		var source_pc := int(row.get("source_pc", -1))
		var bank := int(row.get("prg_bank", -1))
		var value := int(row.get("value", -1))
		var count := int(row.get("count", -1))
		var first_frame := int(row.get("first_source_frame", -1))
		var last_frame := int(row.get("last_source_frame", -1))
		var first_cycle := int(row.get("first_source_cycle", -1))
		var last_cycle := int(row.get("last_source_cycle", -1))
		var signature := "%04X:%02X:%02X" % [source_pc, bank, value]
		if int(row.get("address", -1)) != 0x07FC \
				or not expected_saved_bank_writer_counts.has(signature) \
				or count <= 0 or first_frame < 1 or last_frame > 7265 \
				or first_frame > last_frame or first_cycle < 0 \
				or last_cycle >= 216355361 or last_cycle < first_cycle:
			return _fail("A ROM-stepper `$07FC` writer summary crosses or diverges from the candidate boundary.")
		observed_saved_bank_counts[signature] = count
		saved_bank_write_total += count
		if last_cycle > int(latest_saved_bank_writer.get("last_source_cycle", -1)):
			latest_saved_bank_writer = row.duplicate(true)
	if observed_saved_bank_counts != expected_saved_bank_writer_counts \
			or saved_bank_write_total != 4 \
			or int(latest_saved_bank_writer.get("source_pc", -1)) != 0x804D \
			or int(latest_saved_bank_writer.get("prg_bank", -1)) != 0x0C \
			or int(latest_saved_bank_writer.get("value", -1)) != 0x0F \
			or int(latest_saved_bank_writer.get("last_source_frame", -1)) != 4817 \
			or int(latest_saved_bank_writer.get("last_source_cycle", -1)) != 143424443:
		return _fail("The ROM-stepper `$07FC` history does not end at the checked bank-$0C `$804D` store.")
	_pre_candidate_saved_bank_07fc_history = {
		"candidate_source_frame": 7266,
		"candidate_source_cycle": 216355361,
		"candidate_source_pc": 0xC421,
		"value": int(sound_queue_history["saved_bank_07fc_value"]),
		"write_count": saved_bank_write_total,
		"writer_summary": saved_bank_summary.duplicate(true),
		"latest_writer": latest_saved_bank_writer.duplicate(true),
	}

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
	_last_a117_source_frame = -1


func advance_to_source_frame(source_frame: int) -> bool:
	if not _configured:
		return _fail("Configure the audited route schedule before advancing it.")
	if source_frame < last_source_frame or source_frame < 0:
		return _fail("RNG source frames must advance monotonically.")
	if source_frame > schedule_end_source_frame:
		return _fail("Audited RNG schedule ends at source frame %d." % schedule_end_source_frame)
	for frame in range(last_source_frame + 1, source_frame + 1):
		if _a117_frame_set.has(frame):
			_advance_a117(frame)
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


## Return the latest A117 byte writes after replaying to that source frame.
## This is an input-state receipt for the immediately following NMI, not proof
## that the NMI at that following frame has run.
func build_last_a117_ram_write_receipt(event_id: String) -> Dictionary:
	if not _configured or not _input_identity_bound or event_id.is_empty():
		return _failure("A configured, route-bound RNG replay and event ID are required.")
	if _last_a117_source_frame < 1 or _last_a117_source_frame != last_source_frame:
		return _failure("The replay is not stopped immediately after an A117 update frame.")
	return {
		"ok": true,
		"status": "rom_source_rng_replay_before_next_nmi",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stepper_sha256": EXPECTED_SOURCE_STEPPER_SHA256,
		"source_event_id": event_id,
		"source_frame": _last_a117_source_frame,
		"source_execution": "hash-bound ROM-only A117 event schedule with byte-level ROM arithmetic",
		"input_route_sha256": input_timeline_sha256,
		"a117_update_count": a117_update_count,
		"c9c5_update_count": c9c5_update_count,
		"ram_writes": [
			{"source_pc": A117_STORE_PCS[0], "address": 0x00E1, "value": e1},
			{"source_pc": A117_STORE_PCS[1], "address": 0x00E2, "value": e2},
			{"source_pc": A117_STORE_PCS[2], "address": 0x00E3, "value": e3},
		],
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"following_nmi_executed": false,
	}


## Return the ROM-stepper's source writes to `$003A` before the frame-7266 NMI.
## This is a history receipt only; source-byte semantics are checked by the NMI
## executor before the byte is merged into a route checkpoint.
func build_pre_candidate_counter_003a_history_receipt(candidate_source_frame: int,
		event_id: String) -> Dictionary:
	if not _configured or not _input_identity_bound or event_id.is_empty():
		return _failure("A configured, route-bound RNG replay and event ID are required.")
	if candidate_source_frame != 7266 \
			or int(_pre_candidate_counter_003a_history.get("candidate_source_frame", -1)) != candidate_source_frame:
		return _failure("The audited `$003A` history ends immediately before source frame 7266.")
	var initializers: Variant = _pre_candidate_counter_003a_history.get("initialization_writes", [])
	if not initializers is Array or initializers.size() != 2:
		return _failure("The `$003A` source history has no verified pair of zero writes.")
	return {
		"ok": true,
		"kind": "rom_stepper_pre_candidate_counter_003a_history",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stepper_sha256": EXPECTED_SOURCE_STEPPER_SHA256,
		"input_route_sha256": input_timeline_sha256,
		"source_event_id": event_id,
		"candidate_source_frame": candidate_source_frame,
		"initialization_writes": initializers.duplicate(true),
		"increment_source_pc": int(_pre_candidate_counter_003a_history["increment_source_pc"]),
		"increment_prg_bank": int(_pre_candidate_counter_003a_history["increment_prg_bank"]),
		"increment_count": int(_pre_candidate_counter_003a_history["increment_count"]),
		"increment_frame_runs_inclusive": _pre_candidate_counter_003a_history[
			"increment_frame_runs_inclusive"].duplicate(true),
		"unexpected_writer_count": int(_pre_candidate_counter_003a_history["unexpected_writer_count"]),
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"candidate_nmi_executed": false,
	}


func build_pre_candidate_sound_queue_inputs_receipt(candidate_source_frame: int,
		event_id: String) -> Dictionary:
	if not _configured or not _input_identity_bound or event_id.is_empty():
		return _failure("A configured, route-bound ROM-stepper replay and event ID are required.")
	if candidate_source_frame != 7266 \
			or int(_pre_candidate_sound_queue_inputs.get("candidate_source_frame", -1)) \
			!= candidate_source_frame:
		return _failure("The audited sound-queue inputs end at source frame 7266.")
	var values: Variant = _pre_candidate_sound_queue_inputs.get("values", {})
	var known_values: Array[Dictionary] = []
	for address in SOUND_QUEUE_INPUT_ADDRESSES:
		var key := "%04X" % address
		if not values is Dictionary or not values.has(key):
			return _failure("The source boundary is missing sound-driver input `$%04X`." % address)
		known_values.append({"address": address, "known_mask": 0xFF,
			"known_value": int(values[key]), "observation_pc": 0xC421})
	return {
		"ok": true,
		"kind": "rom_stepper_pre_candidate_sound_queue_inputs",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stepper_sha256": EXPECTED_SOURCE_STEPPER_SHA256,
		"source_schedule_builder_sha256": EXPECTED_SCHEDULE_BUILDER_SHA256,
		"input_route_sha256": input_timeline_sha256,
		"source_event_id": String(_pre_candidate_sound_queue_inputs["source_event_id"]),
		"consumer_event_id": event_id,
		"candidate_source_frame": candidate_source_frame,
		"candidate_source_cycle": int(_pre_candidate_sound_queue_inputs["candidate_source_cycle"]),
		"candidate_source_pc": int(_pre_candidate_sound_queue_inputs["candidate_source_pc"]),
		"source_ram_sha256": String(_pre_candidate_sound_queue_inputs["source_ram_sha256"]),
		"write_count": int(_pre_candidate_sound_queue_inputs["write_count"]),
		"writer_summary": _pre_candidate_sound_queue_inputs["writer_summary"].duplicate(true),
		"known_byte_values": known_values,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"candidate_nmi_executed": false,
	}


func build_pre_candidate_nmi_mode_bit_history_receipt(candidate_source_frame: int,
		event_id: String) -> Dictionary:
	if not _configured or not _input_identity_bound or event_id.is_empty():
		return _failure("A configured, route-bound ROM-stepper replay and event ID are required.")
	if candidate_source_frame != 7266 \
			or int(_pre_candidate_mode_001b_history.get("candidate_source_frame", -1)) != candidate_source_frame:
		return _failure("The audited `$001B` history ends at the frame-7266 source boundary.")
	var latest: Dictionary = _pre_candidate_mode_001b_history.get("latest_writer", {})
	var candidate_nmi_cycle := 216355343
	var candidate_boundary_cycle := int(_pre_candidate_mode_001b_history["candidate_source_cycle"])
	if int(latest.get("last_source_cycle", -1)) >= candidate_nmi_cycle \
			or candidate_boundary_cycle != 216355361 or candidate_nmi_cycle >= candidate_boundary_cycle:
		return _failure("The audited `$001B` writer history does not bracket the frame-7266 `$A15B` candidate.")
	return {
		"ok": true,
		"kind": "rom_stepper_pre_candidate_001b_bit7_history",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stepper_sha256": EXPECTED_SOURCE_STEPPER_SHA256,
		"source_schedule_builder_sha256": EXPECTED_SCHEDULE_BUILDER_SHA256,
		"input_route_sha256": input_timeline_sha256,
		"source_event_id": String(_pre_candidate_sound_queue_inputs.get("source_event_id", "")),
		"consumer_event_id": event_id,
		"candidate_source_frame": candidate_source_frame,
		"candidate_source_cycle": candidate_boundary_cycle,
		"candidate_source_pc": int(_pre_candidate_mode_001b_history["candidate_source_pc"]),
		"nmi_candidate_source_frame": candidate_source_frame,
		"nmi_candidate_source_cycle": candidate_nmi_cycle,
		"nmi_candidate_source_pc": 0xA15B,
		"no_mode_writer_between_nmi_candidate_and_boundary": true,
		"mode_001b_value_at_candidate": int(_pre_candidate_mode_001b_history["mode_001b_value"]),
		"write_count_before_candidate": int(_pre_candidate_mode_001b_history["write_count"]),
		"writer_summary": _pre_candidate_mode_001b_history["writer_summary"].duplicate(true),
		"latest_writer_before_candidate": latest.duplicate(true),
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"candidate_nmi_executed": false,
	}


func build_pre_candidate_saved_bank_07fc_history_receipt(candidate_source_frame: int,
		event_id: String) -> Dictionary:
	if not _configured or not _input_identity_bound or event_id.is_empty():
		return _failure("A configured, route-bound ROM-stepper replay and event ID are required.")
	if candidate_source_frame != 7266 \
			or int(_pre_candidate_saved_bank_07fc_history.get("candidate_source_frame", -1)) != candidate_source_frame:
		return _failure("The audited `$07FC` writer history ends at the frame-7266 source boundary.")
	var latest: Dictionary = _pre_candidate_saved_bank_07fc_history.get("latest_writer", {})
	return {
		"ok": true,
		"kind": "rom_stepper_pre_candidate_saved_bank_07fc_history",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stepper_sha256": EXPECTED_SOURCE_STEPPER_SHA256,
		"source_schedule_builder_sha256": EXPECTED_SCHEDULE_BUILDER_SHA256,
		"input_route_sha256": input_timeline_sha256,
		"source_event_id": String(_pre_candidate_sound_queue_inputs.get("source_event_id", "")),
		"consumer_event_id": event_id,
		"candidate_source_frame": candidate_source_frame,
		"candidate_source_cycle": int(_pre_candidate_saved_bank_07fc_history["candidate_source_cycle"]),
		"candidate_source_pc": int(_pre_candidate_saved_bank_07fc_history["candidate_source_pc"]),
		"saved_bank_07fc_value": int(_pre_candidate_saved_bank_07fc_history["value"]),
		"write_count_before_candidate": int(_pre_candidate_saved_bank_07fc_history["write_count"]),
		"writer_summary": _pre_candidate_saved_bank_07fc_history["writer_summary"].duplicate(true),
		"latest_writer_before_candidate": latest.duplicate(true),
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"candidate_nmi_executed": false,
	}


func get_receiver_slot() -> int:
	if not _configured or not _input_identity_bound \
			or last_source_frame < receiver_source_frame:
		return -1
	return receiver_slot


func get_state() -> Dictionary:
	return {
		"configured": _configured,
		"route_identity": route_identity,
		"input_timeline_sha256": input_timeline_sha256,
		"input_identity_bound": _input_identity_bound,
		"last_source_frame": last_source_frame,
		"schedule_end_source_frame": schedule_end_source_frame,
		"e1": e1,
		"e2": e2,
		"e3": e3,
		"a117_updates_applied": a117_update_count,
		"c9c5_updates_applied": c9c5_update_count,
		"receiver_source_frame": receiver_source_frame,
		"receiver_slot_calculated": get_receiver_slot(),
		"error": error_message,
	}


func _advance_a117(source_frame: int) -> void:
	var sum_e1 := e1 + 0x83
	var carry_e1 := 1 if sum_e1 > 0xFF else 0
	e1 = sum_e1 & 0xFF
	var sum_e2 := e2 + 0x0D + carry_e1
	var carry_e2 := 1 if sum_e2 > 0xFF else 0
	e2 = sum_e2 & 0xFF
	e3 = (e3 + 0x11 + carry_e2) & 0xFF
	a117_update_count += 1
	_last_a117_source_frame = source_frame


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
	_counter_003a_frame_set.clear()
	_pre_candidate_counter_003a_history.clear()
	_pre_candidate_sound_queue_inputs.clear()
	_pre_candidate_mode_001b_history.clear()
	_pre_candidate_saved_bank_07fc_history.clear()
	_c9c5_state_by_frame.clear()
	_c9c5_inputs_by_frame.clear()
	_last_a117_source_frame = -1
	_configured = false
	_input_identity_bound = false


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message, "trace_state_used": false,
		"emulator_data_used": false, "candidate_state_used": false}
