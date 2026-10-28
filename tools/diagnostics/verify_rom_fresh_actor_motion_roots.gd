extends SceneTree
## Verifies the first source-driven motion updates for animation-$8F actors.

const DECODER_SCRIPT := preload("res://scripts/gameplay/rom_actor_animation_stream_decoder.gd")
const CONSTRUCTOR_SCRIPT := preload("res://scripts/gameplay/rom_f1_actor_record_constructor.gd")
const INTERPRETER_SCRIPT := preload("res://scripts/gameplay/rom_actor_state_interpreter.gd")
const TRACE_PATH := "res://reference/diagnostics/first_command_actor_writer_trace_20261027_170114_utc/actor_routine_calls.csv"
const ACTOR_PACKET_KIND := 1
const EXPECTED := [
	{"record": 0x055C, "motion": 0xA723, "appearance": 0xB310, "descriptor": 0xBA, "x": 0x28, "y": 0xC3, "duration": 0xEF, "velocity": 0x26},
	{"record": 0x0571, "motion": 0xA723, "appearance": 0xB310, "descriptor": 0xBA, "x": 0x00, "y": 0xC3, "duration": 0xEF, "velocity": 0x26},
	{"record": 0x0586, "motion": 0xA72C, "appearance": 0xB312, "descriptor": 0xB9, "x": 0xB8, "y": 0xB3, "duration": 0xA0, "velocity": 0x40},
	{"record": 0x059B, "motion": 0xA72C, "appearance": 0xB312, "descriptor": 0xB9, "x": 0x00, "y": 0xB3, "duration": 0xA0, "velocity": 0x40},
]


func _initialize() -> void:
	_run()


func _run() -> void:
	var decoder: Variant = DECODER_SCRIPT.new()
	if not decoder.configure():
		_fail("Actor stream decoder setup failed: " + decoder.last_error)
		return
	var constructor: Variant = CONSTRUCTOR_SCRIPT.new()
	if not constructor.configure():
		_fail("F1 actor constructor setup failed: " + constructor.last_error)
		return
	var interpreter: Variant = INTERPRETER_SCRIPT.new()
	if not interpreter.configure():
		_fail("Actor interpreter setup failed: " + interpreter.last_error)
		return
	var animation: Dictionary = decoder.decode_animation(0x8F)
	if not bool(animation.get("ok", false)):
		_fail("Fresh-start animation $8F did not decode: " + str(animation.get("error", "unknown error")))
		return

	var source_actors: Array[PackedByteArray] = []
	var packet_index := 0
	for event_variant in animation.get("events", []):
		if int(event_variant.kind) != ACTOR_PACKET_KIND:
			continue
		var actor: Variant = constructor.construct(event_variant)
		if actor == null:
			_fail("F1 constructor failed at packet %d: %s" % [packet_index, constructor.last_error])
			return
		if packet_index > 0:
			if packet_index - 1 >= EXPECTED.size():
				_fail("Animation $8F emitted too many route-motion actor records.")
				return
			var expected: Dictionary = EXPECTED[packet_index - 1]
			if actor.record_cpu_address != int(expected["record"]) \
					or actor.motion_cpu_address != int(expected["motion"]) \
					or actor.appearance_cpu_address != int(expected["appearance"]):
				_fail("F1 source pointers differ for route-motion packet %d." % packet_index)
				return
			source_actors.append(actor.bytes.duplicate())
		packet_index += 1
	if packet_index != EXPECTED.size() + 1 or source_actors.size() != EXPECTED.size():
		_fail("Animation $8F produced %d packets; expected one zero-motion actor and four route-motion actors." % packet_index)
		return

	var trace_state_count := 0
	for index in EXPECTED.size():
		var expected: Dictionary = EXPECTED[index]
		var initial: PackedByteArray = source_actors[index]
		var first: Variant = interpreter.tick_actor(initial)
		if not first.ok:
			_fail("First source motion tick failed for actor $%04X: %s" % [int(expected["record"]), first.error])
			return
		var expected_first := _expected_motion_record(initial, expected, 1)
		if not _records_equal(first.actor_record, expected_first):
			_fail("First $84DC motion update differs from the decoded source operands for actor $%04X." % int(expected["record"]))
			return
		var second: Variant = interpreter.tick_actor(first.actor_record)
		if not second.ok:
			_fail("Second source motion tick failed for actor $%04X: %s" % [int(expected["record"]), second.error])
			return
		var expected_second := _expected_motion_record(initial, expected, 2)
		if not _records_equal(second.actor_record, expected_second):
			_fail("Second $84DC fixed-point accumulation differs for actor $%04X." % int(expected["record"]))
			return

		var trace_record := _trace_motion_record(8482, "$%04X" % int(expected["record"]))
		if trace_record.is_empty() or not _records_equal(first.actor_record, trace_record):
			_fail("The first source-model tick for actor $%04X does not match its independent frame-8482 ROM-derived trace row." % int(expected["record"]))
			return
		trace_state_count += 1

		var ticks_through_loop := int(expected["duration"]) + 2
		var looped := initial.duplicate()
		for _tick in ticks_through_loop:
			var update: Variant = interpreter.tick_actor(looped)
			if not update.ok:
				_fail("Source $04 self-loop failed for actor $%04X: %s" % [int(expected["record"]), update.error])
				return
			looped = update.actor_record
		var expected_looped := _expected_motion_record(initial, expected, ticks_through_loop)
		if not _records_equal(looped, expected_looped):
			_fail("Source $04 jump/reload result differs after one full loop for actor $%04X." % int(expected["record"]))
			return
	if trace_state_count != EXPECTED.size():
		_fail("Only %d of four independent source-frame trace checks ran." % trace_state_count)
		return

	print("PASS: animation-$8F actors $055C/$0571/$0586/$059B execute ROM $01 fixed-point motion, countdowns, and the $04 self-loop; all four first-tick records match the independent frame-8482 trace.")
	quit(0)


func _expected_motion_record(source: PackedByteArray, expected: Dictionary, tick_count: int) -> PackedByteArray:
	var result := source.duplicate()
	var root := int(expected["motion"])
	var velocity := int(expected["velocity"])
	var duration := int(expected["duration"])
	var total_fraction := velocity * tick_count
	result[0x01] = (root + 6) & 0xFF
	result[0x02] = (root + 6) >> 8
	result[0x05] = velocity
	result[0x06] = total_fraction & 0xFF
	result[0x07] = 0
	result[0x08] = (int(source[0x08]) + (total_fraction >> 8)) & 0xFF
	result[0x09] = 0
	result[0x0A] = 0
	result[0x0B] = 0
	result[0x0C] = int(source[0x0C])
	result[0x10] = 0xFF
	result[0x11] = duration if tick_count % (duration + 1) == 1 else duration - ((tick_count - 1) % (duration + 1))
	result[0x12] = int(expected["descriptor"])
	return result


func _trace_motion_record(frame: int, record_name: String) -> PackedByteArray:
	var csv := FileAccess.get_file_as_string(TRACE_PATH)
	if csv.is_empty():
		return PackedByteArray()
	var lines := csv.split("\n", false)
	if lines.is_empty():
		return PackedByteArray()
	var columns := lines[0].split(",", true)
	var frame_column := columns.find("source_frame")
	var pc_column := columns.find("cpu_pc")
	var actor_column := columns.find("actor_record")
	var bytes_column := columns.find("actor_record_21_bytes")
	if min(frame_column, min(pc_column, min(actor_column, bytes_column))) < 0:
		return PackedByteArray()
	for line_index in range(1, lines.size()):
		var fields := lines[line_index].split(",", true)
		if fields.size() != columns.size():
			continue
		if int(fields[frame_column]) != frame or fields[pc_column] != "$84DC" or fields[actor_column] != record_name:
			continue
		var record_bytes := PackedByteArray()
		for token in fields[bytes_column].split(" ", false):
			record_bytes.append(token.hex_to_int())
		return record_bytes
	return PackedByteArray()


func _records_equal(left: PackedByteArray, right: PackedByteArray) -> bool:
	if left.size() != 21 or right.size() != 21:
		return false
	for index in 21:
		if int(left[index]) != int(right[index]):
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
