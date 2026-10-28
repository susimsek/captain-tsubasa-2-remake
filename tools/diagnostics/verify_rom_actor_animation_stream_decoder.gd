extends SceneTree
## Focused source-byte check for the bank-$14 route animation decoder.

const DECODER_SCRIPT := preload("res://scripts/gameplay/rom_actor_animation_stream_decoder.gd")
const SCENARIO_READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const EVENT_ACTOR_PACKET := 1
const EVENT_SPRITE_CHR_SELECTORS := 2
const EVENT_ABSOLUTE_REDIRECT := 4
const EVENT_STREAM_END := 0
const EVENT_ACTOR_REMOVE := 7
const EVENT_WAIT_TICKS := 8

const EXPECTED_PACKET_OFFSETS := {
	0x8F: [0x02989C, 0x0298A2, 0x0298A8, 0x0298AE, 0x0298B4],
	0x4E: [0x029278],
	0x66: [0x029458, 0x02945F],
	0x4C: [0x02925C],
	0x78: [0x02962F, 0x029635, 0x02963B, 0x029641, 0x029653, 0x02965A],
	0x79: [0x029668],
	0x90: [0x0298C2, 0x0298C8, 0x0298CE],
}


func _initialize() -> void:
	_run()


func _run() -> void:
	var decoder: Variant = DECODER_SCRIPT.new()
	if not decoder.configure():
		_fail("Decoder configuration failed: " + decoder.last_error)
		return

	var decoded_by_id: Dictionary = {}
	for animation_id in [0x8F, 0x4E, 0x66, 0x4C, 0x78, 0x79, 0x90, 0xE6]:
		var result: Dictionary = decoder.decode_animation(animation_id)
		if not bool(result.get("ok", false)):
			_fail("Animation $%02X failed: %s" % [animation_id, str(result.get("error", "unknown error"))])
			return
		decoded_by_id[animation_id] = result
		if bool(result.get("cadence_implemented", true)):
			_fail("The byte decoder must not claim source cadence.")
			return
		if not _check_packet_offsets(animation_id, result):
			return

	var e6_result: Dictionary = decoded_by_id[0xE6]
	var e6_events: Array = e6_result["events"]
	var redirect: Variant = _find_event(e6_events, EVENT_ABSOLUTE_REDIRECT, 0x02A0B5)
	if redirect == null \
			or int(redirect.redirect_target_cpu_address) != 0x961A \
			or int(redirect.redirect_target_stream_id) != 0x78 \
			or int(redirect.redirect_target_file_offset) != 0x02962A \
			or e6_result.get("visited_stream_ids", []) != [0xE6, 0x78]:
		_fail("Animation $E6 did not follow its byte-checked absolute redirect into $78 at $961A / file 0x02962A.")
		return

	var f4_event: Variant = _find_event(e6_events, EVENT_SPRITE_CHR_SELECTORS, 0x02962A)
	if f4_event == null or f4_event.sprite_chr_selectors != PackedByteArray([0x08, 0x09, 0x0A, 0x0B]):
		_fail("The redirected $78 stream did not preserve the four source $F4 selector bytes.")
		return

	var timeline: Dictionary = decoder.decode_timeline(0xE6)
	if not bool(timeline.get("ok", false)) or int(timeline.get("source_tick_count", -1)) != 22:
		_fail("Animation $E6 did not produce its ROM-derived 22-tick relative schedule.")
		return
	var packet_ticks: Array[int] = []
	var wait_rows: Array[Array] = []
	var removals: Array[Array] = []
	for event in timeline["events"]:
		if int(event.kind) == EVENT_ACTOR_PACKET:
			packet_ticks.append(int(event.source_tick))
		elif int(event.kind) == EVENT_WAIT_TICKS:
			wait_rows.append([int(event.source_file_offset), int(event.wait_ticks), int(event.source_tick)])
		elif int(event.kind) == EVENT_ACTOR_REMOVE:
			removals.append([int(event.source_file_offset), int(event.actor_record_offset), int(event.actor_record_index)])
	if packet_ticks != [0, 0, 0, 0, 20, 22]:
		_fail("Animation $78 actor packets do not follow its ROM $14/$02 waits: %s" % str(packet_ticks))
		return
	if wait_rows != [[0x029647, 0x14, 0], [0x029659, 0x02, 20]]:
		_fail("Animation $78 low-byte waits do not resolve to its source-tick positions: %s" % str(wait_rows))
		return
	if removals != [[0x02964D, 0x00, 0], [0x02964F, 0x2A, 2], [0x029651, 0x3F, 3]]:
		_fail("Animation $78 $F6 removal packets do not preserve the ROM actor offsets: %s" % str(removals))
		return
	var scenario_result: Dictionary = SCENARIO_READER_SCRIPT.read_project_scenario(0x36)
	var e6_record: Dictionary = {}
	for token_variant in scenario_result.get("tokens", []):
		if not token_variant is Dictionary:
			continue
		var token: Dictionary = token_variant
		var assignments: Dictionary = token.get("ram_assignments", {})
		if str(token.get("kind", "")) == "event_record" and int(assignments.get("$0528", -1)) == 0xE6:
			e6_record = token
			break
	if e6_record.is_empty():
		_fail("The bank-$10 ROM scenario reader did not emit the source event record for animation $E6.")
		return
	var scenario_bridge: Dictionary = decoder.decode_scenario_event_record(e6_record)
	if not bool(scenario_bridge.get("ok", false)) \
			or int(scenario_bridge.get("scenario_wait_ticks", -1)) != 0x3E \
			or int(scenario_bridge.get("scenario_event_selector", -1)) != 0x01 \
			or int(scenario_bridge.get("selected_animation_id", -1)) != 0xE6 \
			or int(scenario_bridge.get("animation_parameter", -1)) != 0x75 \
			or int(scenario_bridge.get("source_tick_count", -1)) != 22 \
			or bool(scenario_bridge.get("actor_state_mutated", true)):
		_fail("The ROM-decoded bank-$10 $E6 record did not bridge to its source animation timeline.")
		return

	var id79_events: Array = decoded_by_id[0x79]["events"]
	var embedded_f0_packet: Variant = _find_event(id79_events, EVENT_ACTOR_PACKET, 0x029668)
	var id79_end: Variant = _find_event(id79_events, EVENT_STREAM_END, 0x02966E)
	if embedded_f0_packet == null \
			or embedded_f0_packet.raw_bytes != PackedByteArray([0xF1, 0x00, 0x79, 0xF0, 0xBB, 0x00]) \
			or id79_end == null:
		_fail("Animation $79 mistook its $F1 packet's $F0 operand for the stream terminator.")
		return

	print("PASS: ROM-derived actor events and relative ticks decode; $E6 redirects to $78, F6 operands remove actors, and $78 packets land at ticks 0/20/22.")
	quit(0)


func _check_packet_offsets(animation_id: int, result: Dictionary) -> bool:
	if not EXPECTED_PACKET_OFFSETS.has(animation_id):
		return true
	var actual_offsets: Array[int] = []
	for event in result["events"]:
		if int(event.kind) == EVENT_ACTOR_PACKET:
			actual_offsets.append(int(event.source_file_offset))
	if actual_offsets != EXPECTED_PACKET_OFFSETS[animation_id]:
		_fail("Animation $%02X F1 packet offsets differ: expected %s, got %s." % [
			animation_id,
			str(EXPECTED_PACKET_OFFSETS[animation_id]),
			str(actual_offsets),
		])
		return false
	return true


func _find_event(events: Array, kind: int, file_offset: int) -> Variant:
	for event in events:
		if int(event.kind) == kind and int(event.source_file_offset) == file_offset:
			return event
	return null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
