extends SceneTree
## Verifies the ROM $8F F1 packets reach their source $B30E/$B310/$B312 F7 poses.

const DECODER_SCRIPT := preload("res://scripts/gameplay/rom_actor_animation_stream_decoder.gd")
const CONSTRUCTOR_SCRIPT := preload("res://scripts/gameplay/rom_f1_actor_record_constructor.gd")
const INTERPRETER_SCRIPT := preload("res://scripts/gameplay/rom_actor_state_interpreter.gd")
const ACTOR_PACKET_KIND := 1
const EXPECTED := [
	{"record": 0x0547, "motion": 0xA38A, "appearance": 0xB30E, "descriptor": 0xB8, "x": 0x00, "y": 0xD3},
	{"record": 0x055C, "motion": 0xA723, "appearance": 0xB310, "descriptor": 0xBA, "x": 0x28, "y": 0xC3},
	{"record": 0x0571, "motion": 0xA723, "appearance": 0xB310, "descriptor": 0xBA, "x": 0x00, "y": 0xC3},
	{"record": 0x0586, "motion": 0xA72C, "appearance": 0xB312, "descriptor": 0xB9, "x": 0xB8, "y": 0xB3},
	{"record": 0x059B, "motion": 0xA72C, "appearance": 0xB312, "descriptor": 0xB9, "x": 0x00, "y": 0xB3},
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
	var packet_index := 0
	for event_variant in animation.get("events", []):
		if int(event_variant.kind) != ACTOR_PACKET_KIND:
			continue
		if packet_index >= EXPECTED.size():
			_fail("Animation $8F emitted more F1 packets than the checked actor-root set.")
			return
		var expected: Dictionary = EXPECTED[packet_index]
		var actor: Variant = constructor.construct(event_variant)
		if actor == null:
			_fail("F1 constructor failed at packet %d: %s" % [packet_index, constructor.last_error])
			return
		if actor.record_cpu_address != int(expected["record"]) \
				or actor.motion_cpu_address != int(expected["motion"]) \
				or actor.appearance_cpu_address != int(expected["appearance"]):
			_fail("F1 source pointers differ for packet %d." % packet_index)
			return
		var before: PackedByteArray = actor.bytes.duplicate()
		var update: Variant = interpreter.tick_appearance_only(before)
		if not update.ok:
			_fail("Appearance interpreter failed at packet %d: %s" % [packet_index, update.error])
			return
		var record: PackedByteArray = update.actor_record
		if int(record[0x10]) != 0xFF \
				or int(record[0x12]) != int(expected["descriptor"]) \
				or _read_u16(record, 0x01) != int(expected["motion"]) \
				or _read_u16(record, 0x03) != int(expected["appearance"]) \
				or int(record[0x08]) != int(expected["x"]) \
				or int(record[0x0C]) != int(expected["y"]) \
				or int(record[0x11]) != int(before[0x11]):
			_fail("Source appearance F7 result changed an unexpected actor field at packet %d." % packet_index)
			return
		if update.appearance_events.size() != 1:
			_fail("Each checked appearance root should consume exactly one direct $F7 command.")
			return
		packet_index += 1
	if packet_index != EXPECTED.size():
		_fail("Animation $8F produced %d F1 packets; expected %d." % [packet_index, EXPECTED.size()])
		return
	print("PASS: all five ROM $8F F1 records execute the first $B30E/$B310/$B312 appearance $F7 pose without changing motion or packet coordinates.")
	quit(0)


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
