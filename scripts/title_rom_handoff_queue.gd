extends RefCounted
## Replays the ROM-stepper title handoff events against ROM-derived queue data.
## The source-event schedule is CPU-cycle based; this is not a PPU emulator.

const PPU_QUEUE_CURSOR_LIMIT := 0x3D
const EXPECTED_BACKGROUND_PACKET_COUNT := 240
const EXPECTED_CONSUMER_COUNT := 242
const EXPECTED_CAPACITY_WAIT_COUNT := 27
const EXPECTED_NMI_COUNT := 31
const CURSOR_PACKET_ADDRESS := 0x220A
const CURSOR_PACKET_TILE := 0x7F
const SOURCE_EVENT_PATH := "res://assets/opening/rom_logic/title_handoff_source_events.json"
const SOURCE_EVENT_SCHEMA := "ct2-title-handoff-rom-stepper-events-v1"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

enum HandoffPhase {
	IDLE,
	WAITING_FOR_LOADER,
	PRODUCING_BACKGROUND,
	WAITING_FOR_TITLE_SETUP,
	WAITING_FOR_TITLE_CONSUMERS,
	COMPLETE,
}

var _renderer: RomTitleBackgroundRenderer
var _background_packets: Array[Dictionary] = []
var _palette_bytes := PackedByteArray()
var _events: Array[Dictionary] = []
var _pending_nmi_packets: Array[Dictionary] = []
var _next_background_packet := 0
var _next_event_index := 0
var _next_consumer_ordinal := 0
var _queue_cursor := 0
var _last_cycle_offset := -1
var _nmi_count := 0
var _capacity_wait_count := 0
var _capacity_resume_count := 0
var _start_marker_seen := false
var _background_loader_seen := false
var _capacity_wait_seen := false
var _title_setup_seen := false
var _blackout_started := false
var _started := false
var _complete := false
var _phase := HandoffPhase.IDLE


func start(renderer: RomTitleBackgroundRenderer) -> bool:
	if renderer == null:
		push_error("Title handoff queue needs the ROM background renderer.")
		return false
	_renderer = renderer
	_background_packets = renderer.get_source_title_packets()
	_palette_bytes = renderer.get_source_title_palette_bytes()
	if _background_packets.size() != EXPECTED_BACKGROUND_PACKET_COUNT:
		push_error("Title handoff needs the source-verified 240-packet $17 stream.")
		return false
	if _palette_bytes.size() != 32:
		push_error("Title handoff needs 32 ROM-derived background/sprite palette bytes.")
		return false
	if not _load_source_events():
		return false

	_pending_nmi_packets.clear()
	_next_background_packet = 0
	_next_event_index = 0
	_next_consumer_ordinal = 0
	_queue_cursor = 0
	_last_cycle_offset = -1
	_nmi_count = 0
	_capacity_wait_count = 0
	_capacity_resume_count = 0
	_start_marker_seen = false
	_background_loader_seen = false
	_capacity_wait_seen = false
	_title_setup_seen = false
	_blackout_started = false
	_complete = false
	_started = true
	_phase = HandoffPhase.WAITING_FOR_LOADER
	_renderer.begin_source_handoff()
	return true


## Advance through source CPU events up to a Start-relative cycle offset.
## Returns true only after the final ROM queue consumer commits.
func advance_to_cpu_cycle(cycle_offset: int) -> bool:
	if not _started or _complete:
		return _complete
	if cycle_offset < _last_cycle_offset:
		push_error("Title handoff CPU-cycle position cannot move backward.")
		return false
	_last_cycle_offset = cycle_offset
	while _next_event_index < _events.size() and not _complete:
		var event: Dictionary = _events[_next_event_index]
		if int(event.get("cycle_offset", -1)) > cycle_offset:
			break
		_next_event_index += 1
		if not _consume_source_event(event):
			return false
	return _complete


func is_complete() -> bool:
	return _complete


func blackout_started() -> bool:
	return _blackout_started


func _load_source_events() -> bool:
	if not FileAccess.file_exists(SOURCE_EVENT_PATH):
		push_error("ROM-stepper title handoff event resource is missing.")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_EVENT_PATH))
	if not parsed is Dictionary:
		push_error("ROM-stepper title handoff event resource is malformed.")
		return false
	var source: Dictionary = parsed
	if str(source.get("schema", "")) != SOURCE_EVENT_SCHEMA \
			or str(source.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Title handoff events do not match the supplied ROM and schema.")
		return false
	var event_values: Variant = source.get("events", [])
	if not event_values is Array:
		push_error("Title handoff event list is not an array.")
		return false
	_events.clear()
	var counts: Dictionary = {}
	var previous_cycle := -1
	var first_nmi_source_frame := -1
	var last_consumer_source_frame := -1
	var consumer_ordinal := 0
	for event_value in event_values:
		if not event_value is Dictionary:
			push_error("Title handoff event is not an object.")
			return false
		var event: Dictionary = event_value
		var cycle := int(event.get("cycle_offset", -1))
		if cycle < 0 or cycle < previous_cycle:
			push_error("Title handoff events are not in nondecreasing source-cycle order.")
			return false
		previous_cycle = cycle
		var kind := str(event.get("kind", ""))
		counts[kind] = int(counts.get(kind, 0)) + 1
		if kind == "nmi_accept" and first_nmi_source_frame < 0:
			first_nmi_source_frame = int(event.get("source_frame", -1))
		if kind == "queue_consumer_packet":
			if int(event.get("ordinal", -1)) != consumer_ordinal:
				push_error("Title handoff source event packet ordinals are not contiguous.")
				return false
			consumer_ordinal += 1
			last_consumer_source_frame = int(event.get("source_frame", -1))
		_events.append(event)
	if counts.get("start_stop", 0) != 1 \
			or counts.get("title_background_loader_enter", 0) != 1 \
			or counts.get("title_palette_cursor_setup", 0) != 1 \
			or counts.get("queue_consumer_packet", 0) != EXPECTED_CONSUMER_COUNT \
			or counts.get("queue_capacity_wait", 0) != EXPECTED_CAPACITY_WAIT_COUNT \
			or counts.get("queue_capacity_resume", 0) != EXPECTED_CAPACITY_WAIT_COUNT \
			or counts.get("nmi_accept", 0) != EXPECTED_NMI_COUNT:
		push_error("Title handoff event counts do not match the ROM-stepper audit.")
		return false
	if first_nmi_source_frame != 4662 or last_consumer_source_frame != 4692:
		push_error("Title handoff event frame anchors differ from the retained 4662/4692 checkpoints.")
		return false
	if int(_events[0].get("cycle_offset", -1)) != 0 \
			or str(_events[0].get("kind", "")) != "start_stop" \
			or str(_events[0].get("pc", "")) != "$8048" \
			or str(_events[0].get("immediate", "")) != "$01":
		push_error("Title handoff events do not begin at the verified ROM $8048 Start stop.")
		return false
	return true


func _consume_source_event(event: Dictionary) -> bool:
	var kind := str(event.get("kind", ""))
	match kind:
		"start_stop":
			if _start_marker_seen or int(event.get("cycle_offset", -1)) != 0:
				return _event_error("Unexpected or duplicate ROM Start-stop event.")
			_start_marker_seen = true
		"nmi_accept":
			_nmi_count += 1
			if _nmi_count == 1:
				_blackout_started = true
		"title_background_loader_enter":
			if not _start_marker_seen or _background_loader_seen \
					or str(event.get("pc", "")) != "$8AF7" \
					or str(event.get("background_id", "")) != "$17":
				return _event_error("Unexpected ROM $8AF7 title background loader event.")
			_background_loader_seen = true
			_phase = HandoffPhase.PRODUCING_BACKGROUND
			if not _stage_next_background_batch():
				return false
		"queue_capacity_wait":
			if not _background_loader_seen or _capacity_wait_seen \
					or str(event.get("pc", "")) != "$9B30" \
					or str(event.get("resume_pc", "")) != "$9B33":
				return _event_error("ROM $9B30 capacity wait does not match the active producer batch.")
			if _pending_nmi_packets.is_empty():
				return _event_error("ROM capacity wait has no staged queue packets to protect.")
			_capacity_wait_seen = true
			_capacity_wait_count += 1
		"queue_consumer_packet":
			if int(event.get("ordinal", -1)) != _next_consumer_ordinal:
				return _event_error("ROM title NMI consumer packet order is not contiguous.")
			if _next_consumer_ordinal < EXPECTED_BACKGROUND_PACKET_COUNT:
				if not _capacity_wait_seen or _pending_nmi_packets.is_empty():
					return _event_error("Background consumer arrived before its ROM queue wait or staged packet.")
				_commit_next_pending_packet()
			else:
				if not _title_setup_seen or _pending_nmi_packets.is_empty():
					return _event_error("Title palette/cursor consumer arrived before ROM setup.")
				_commit_next_pending_packet()
			_next_consumer_ordinal += 1
			if _next_consumer_ordinal == EXPECTED_BACKGROUND_PACKET_COUNT \
					and _pending_nmi_packets.is_empty():
				_phase = HandoffPhase.WAITING_FOR_TITLE_SETUP
			if _next_consumer_ordinal == EXPECTED_CONSUMER_COUNT:
				if not _pending_nmi_packets.is_empty() or _nmi_count != EXPECTED_NMI_COUNT \
						or _capacity_wait_count != EXPECTED_CAPACITY_WAIT_COUNT \
						or _capacity_resume_count != EXPECTED_CAPACITY_WAIT_COUNT:
					return _event_error("Final title commit does not match the full ROM event schedule.")
				_renderer.complete_source_handoff()
				_phase = HandoffPhase.COMPLETE
				_complete = true
		"queue_capacity_resume":
			if not _capacity_wait_seen or not _pending_nmi_packets.is_empty() \
					or _queue_cursor != 0 or str(event.get("pc", "")) != "$9B33":
				return _event_error("ROM $9B33 resumed before its prior queue batch drained.")
			_capacity_wait_seen = false
			_capacity_resume_count += 1
			if _next_background_packet < EXPECTED_BACKGROUND_PACKET_COUNT:
				_phase = HandoffPhase.PRODUCING_BACKGROUND
				if not _stage_next_background_batch():
					return false
			else:
				_phase = HandoffPhase.WAITING_FOR_TITLE_SETUP
		"title_palette_cursor_setup":
			if _title_setup_seen or _next_background_packet != EXPECTED_BACKGROUND_PACKET_COUNT \
					or _next_consumer_ordinal != EXPECTED_BACKGROUND_PACKET_COUNT \
					or not _pending_nmi_packets.is_empty() or _queue_cursor != 0 \
					or str(event.get("pc", "")) != "$807A":
				return _event_error("ROM $807A title palette/cursor setup is out of queue order.")
			_stage_palette_and_cursor()
			_title_setup_seen = true
			_phase = HandoffPhase.WAITING_FOR_TITLE_CONSUMERS
		_:
			return _event_error("Unknown ROM title handoff event: %s" % kind)
	return true


func _stage_next_background_batch() -> bool:
	if _next_background_packet >= EXPECTED_BACKGROUND_PACKET_COUNT:
		return true
	var staged_packet_count := 0
	while _next_background_packet < _background_packets.size():
		var packet: Dictionary = _background_packets[_next_background_packet]
		var payload_value: Variant = packet.get("payload", PackedByteArray())
		if typeof(payload_value) != TYPE_PACKED_BYTE_ARRAY:
			return _event_error("Title background packet payload is not a byte array.")
		var payload: PackedByteArray = payload_value
		var encoded_size := int(packet.get("queue_encoded_bytes", -1))
		if encoded_size != 3 + payload.size():
			return _event_error("Title background packet size does not match the ROM queue header and payload.")
		if _queue_cursor + encoded_size >= PPU_QUEUE_CURSOR_LIMIT:
			if staged_packet_count == 0:
				return _event_error("A ROM title packet cannot fit in an empty `$05E8` queue.")
			return true
		_pending_nmi_packets.append(packet.duplicate(true))
		_queue_cursor += encoded_size
		_next_background_packet += 1
		staged_packet_count += 1
	if staged_packet_count == 0:
		return _event_error("ROM title producer emitted an empty background queue batch.")
	return true


func _stage_palette_and_cursor() -> void:
	_pending_nmi_packets.append({
		"kind": "title_palette",
		"ppu_address": 0x3F00,
		"payload": _palette_bytes.duplicate(),
	})
	_pending_nmi_packets.append({
		"kind": "title_cursor",
		"ppu_address": CURSOR_PACKET_ADDRESS,
		"payload": PackedByteArray([CURSOR_PACKET_TILE]),
	})
	_queue_cursor = 3 + _palette_bytes.size() + 3 + 1


func _commit_next_pending_packet() -> void:
	var packet: Dictionary = _pending_nmi_packets.pop_front()
	_renderer.commit_source_queue_packet(packet)
	var payload: PackedByteArray = packet.get("payload", PackedByteArray())
	_queue_cursor -= int(packet.get("queue_encoded_bytes", 3 + payload.size()))
	if _pending_nmi_packets.is_empty():
		_queue_cursor = 0


func _event_error(message: String) -> bool:
	push_error(message)
	return false
