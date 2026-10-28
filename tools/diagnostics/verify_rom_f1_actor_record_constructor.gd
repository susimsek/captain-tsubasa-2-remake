extends SceneTree
## Verifies animation-$8F source $F1 events become ROM-constructor actor records.

const DECODER_SCRIPT := preload("res://scripts/gameplay/rom_actor_animation_stream_decoder.gd")
const CONSTRUCTOR_SCRIPT := preload("res://scripts/gameplay/rom_f1_actor_record_constructor.gd")
const EVENT_ACTOR_PACKET := 1
const EXPECTED := [
	{"offset": 0x02989C, "record": 0x0547, "motion_index": 0x00, "motion": 0xA38A, "appearance_index": 0x91, "appearance": 0xB30E, "active": 0x81, "x": 0x00, "y": 0xD3},
	{"offset": 0x0298A2, "record": 0x055C, "motion_index": 0x70, "motion": 0xA723, "appearance_index": 0x92, "appearance": 0xB310, "active": 0x81, "x": 0x28, "y": 0xC3},
	{"offset": 0x0298A8, "record": 0x0571, "motion_index": 0x70, "motion": 0xA723, "appearance_index": 0x92, "appearance": 0xB310, "active": 0x80, "x": 0x00, "y": 0xC3},
	{"offset": 0x0298AE, "record": 0x0586, "motion_index": 0x71, "motion": 0xA72C, "appearance_index": 0x93, "appearance": 0xB312, "active": 0x80, "x": 0xB8, "y": 0xB3},
	{"offset": 0x0298B4, "record": 0x059B, "motion_index": 0x71, "motion": 0xA72C, "appearance_index": 0x93, "appearance": 0xB312, "active": 0x80, "x": 0x00, "y": 0xB3},
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
		_fail("Actor record constructor setup failed: " + constructor.last_error)
		return
	var animation: Dictionary = decoder.decode_animation(0x8F)
	if not bool(animation.get("ok", false)):
		_fail("Fresh-start animation $8F did not decode: " + str(animation.get("error", "unknown error")))
		return
	var packet_index := 0
	for event_variant in animation.get("events", []):
		if int(event_variant.kind) != EVENT_ACTOR_PACKET:
			continue
		if packet_index >= EXPECTED.size():
			_fail("Animation $8F yielded more F1 packets than the constructor fixture covers.")
			return
		var expected: Dictionary = EXPECTED[packet_index]
		if int(event_variant.source_file_offset) != int(expected["offset"]):
			_fail("Animation $8F packet order/source offset differs from the source table.")
			return
		var actor: Variant = constructor.construct(event_variant)
		if actor == null:
			_fail("ROM F1 packet construction failed: " + constructor.last_error)
			return
		if actor.actor_index != packet_index \
				or actor.record_cpu_address != int(expected["record"]) \
				or actor.motion_index != int(expected["motion_index"]) \
				or actor.motion_cpu_address != int(expected["motion"]) \
				or actor.appearance_index != int(expected["appearance_index"]) \
				or actor.appearance_cpu_address != int(expected["appearance"]) \
				or actor.active_flags != int(expected["active"]):
			_fail("F1 actor record pointer/flag values differ from the source-table result at packet %d." % packet_index)
			return
		if actor.bytes.size() != 21 or int(actor.bytes[0]) != int(expected["active"]) \
				or _read_u16(actor.bytes, 1) != int(expected["motion"]) \
				or _read_u16(actor.bytes, 3) != int(expected["appearance"]) \
				or int(actor.bytes[8]) != int(expected["x"]) \
				or int(actor.bytes[12]) != int(expected["y"]):
			_fail("F1 actor record bytes do not match the mapped $80AA field writes at packet %d." % packet_index)
			return
		for offset in range(actor.bytes.size()):
			if [0, 1, 2, 3, 4, 8, 12].has(offset):
				continue
			if int(actor.bytes[offset]) != 0:
				_fail("ROM constructor did not zero actor-record byte +$%02X." % offset)
				return
		packet_index += 1
	if packet_index != EXPECTED.size():
		_fail("Animation $8F yielded %d packets; expected %d source constructors." % [packet_index, EXPECTED.size()])
		return
	print("PASS: all five animation-$8F F1 packets resolve through ROM pointer tables into 21-byte $80AA actor records; no RAM snapshot or fixed route timing was used.")
	quit(0)


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
