extends RefCounted
class_name RomCutsceneBackgroundSourceTask
## Source-owned continuation for cutscene F9/FA background loading.
## FA $0F advances only when the caller supplies a matching queue-drained NMI
## receipt for a ROM-derived $9B28 capacity wait; route frames are not timers.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const FA_0F_SOURCE_PC := 0xBFBC
const FA_0F_FILE_OFFSET := 0x00BFCC
const FA_0F_DESCRIPTOR_CPU := 0xA294
const FA_0F_DESCRIPTOR_FILE := 0x00E2A4
const FA_0F_DESCRIPTOR_HEX := "64669a020412575859525a5b5c5600a0"
const QUEUE_CURSOR_LIMIT := 0x3D
const QUEUE_PACKET_HEADER_BYTES := 3
const QUEUE_WRITER_PC := 0x9B28
const CAPACITY_YIELD_LDA_PC := 0x9B2E
const CAPACITY_YIELD_JSR_PC := 0x9B30
const CAPACITY_YIELD_SAVED_RETURN_WORD := 0x9B32
const CAPACITY_YIELD_RESUME_PC := 0x9B33
const CAPACITY_CALLER_JSR_PC := 0x8F44
const CAPACITY_CALLER_SAVED_RETURN_WORD := 0x8F46
const CAPACITY_CALLER_RESUME_PC := 0x8F47
const NMI_QUEUE_CONSUMER_PC := 0xA03C

enum State {
	UNCONFIGURED,
	WAITING_FOR_NMI_QUEUE_RELEASE,
	COMPLETED,
	FAILED,
}

var state: State = State.UNCONFIGURED
var error_message := ""
var event_index := -1
var source_cpu_address := -1
var background_id := -1
var source_queue_cursor_at_start := -1
var queue_cursor_source := ""
var source_packet_count := 0
var source_encoded_byte_count := 0
var capacity_boundary_count_required := 0
var nmi_queue_release_count := 0
var pending_segment_index := -1
var last_nmi_sequence := -1
var last_release_source_frame := -1
var return_scan_source_frame := -1
var uses_nmi_release_receipts := false
var _legacy_batch_count := 0

var _capacity_segments: Array[Dictionary] = []


func begin(event: Dictionary, source_frame: int, load_receipt: Dictionary) -> bool:
	_reset()
	var kind := String(event.get("kind", ""))
	var expected_opcode := 0xF9 if kind == "background_1" else 0xFA
	var arguments: Array = event.get("arguments", [])
	var expected_id := int(arguments[0]) if arguments.size() == 1 else -1
	if kind not in ["background_1", "background_2"] \
			or int(event.get("opcode", -1)) != expected_opcode \
			or int(event.get("id", -1)) != expected_id \
			or source_frame < 0:
		return _fail("Cutscene background task needs a decoded ROM F9/FA event and source frame.")
	if not bool(load_receipt.get("ok", false)) \
			or String(load_receipt.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or int(load_receipt.get("event_index", -1)) != int(event.get("event_index", -2)) \
			or int(load_receipt.get("background_id", -1)) != expected_id:
		return _fail("Cutscene background task has no matching ROM-validated loader receipt.")

	event_index = int(event.get("event_index", -1))
	source_cpu_address = int(event.get("cpu_address", -1))
	background_id = expected_id
	uses_nmi_release_receipts = kind == "background_2" and expected_id == 0x0F
	if uses_nmi_release_receipts:
		if not _configure_fa_0f_source_queue(event, load_receipt):
			return false
	else:
		var batch_count := int(load_receipt.get("capacity_batch_count", 0))
		if batch_count <= 0:
			return _fail("Cutscene background task has no ROM-validated packet capacity batches.")
		capacity_boundary_count_required = batch_count
		# Other F9/FA resources retain the existing frame-level adapter until
		# their own queue-resume paths have source receipts.
		_legacy_batch_count = batch_count
		state = State.WAITING_FOR_NMI_QUEUE_RELEASE
	return_scan_source_frame = source_frame if state == State.COMPLETED else -1
	return true


## FA $0F's ROM packet bytes come from RomBackgroundPacketLoader, not from a
## captured RAM snapshot. `source_queue_cursor_0628` is the presenter's live
## queue owner state; captures may validate it but are never its runtime input.
func _configure_fa_0f_source_queue(event: Dictionary, load_receipt: Dictionary) -> bool:
	var raw_bytes: Array = event.get("raw_bytes", [])
	if int(event.get("cpu_address", -1)) != FA_0F_SOURCE_PC \
			or int(event.get("file_offset", -1)) != FA_0F_FILE_OFFSET \
			or raw_bytes.size() != 2 or int(raw_bytes[0]) != 0xFA \
			or int(raw_bytes[1]) != 0x0F \
			or int(load_receipt.get("event_index", -1)) != event_index:
		return _fail("FA $0F event identity mismatch (PC=$%04X file=$%06X raw=%s event=%d loader_event=%d)." % [
			int(event.get("cpu_address", -1)), int(event.get("file_offset", -1)),
			str(raw_bytes), event_index, int(load_receipt.get("event_index", -1)),
		])
	if int(load_receipt.get("record_cpu_address", -1)) != FA_0F_DESCRIPTOR_CPU \
			or int(load_receipt.get("record_file_offset", -1)) != FA_0F_DESCRIPTOR_FILE:
		return _fail("FA $0F loader descriptor address differs from bank-7 `$A294`/`0x00E2A4`.")
	var record_bytes_variant: Variant = load_receipt.get("record_bytes", PackedByteArray())
	if not record_bytes_variant is PackedByteArray \
			or record_bytes_variant.hex_encode() != FA_0F_DESCRIPTOR_HEX:
		return _fail("FA $0F descriptor bytes differ from the preserved bank-7 ROM record.")
	if int(load_receipt.get("queue_cursor_limit", -1)) != QUEUE_CURSOR_LIMIT:
		return _fail("FA $0F loader receipt does not use ROM $9B28's $3D capacity comparison.")
	var cursor := int(load_receipt.get("source_queue_cursor_0628", -1))
	queue_cursor_source = String(load_receipt.get("source_queue_cursor_source", ""))
	if cursor < 0 or cursor >= QUEUE_CURSOR_LIMIT \
			or queue_cursor_source != "rom_derived_presenter_state":
		return _fail("FA $0F needs the live ROM-derived presenter queue cursor, not a capture-derived value.")
	var source_packets_variant: Variant = load_receipt.get("source_packet_stream", null)
	if not source_packets_variant is Array:
		return _fail("FA $0F load receipt is missing its ROM-derived ordered packet stream.")
	var source_packets: Array = source_packets_variant
	if source_packets.size() != int(load_receipt.get("packet_count", -1)) \
			or source_packets.size() != 40:
		return _fail("FA $0F must provide all 40 attribute/tile-row packets from its 2x4 descriptor.")
	source_queue_cursor_at_start = cursor
	if not _build_capacity_segments(source_packets, cursor):
		return false
	if int(load_receipt.get("capacity_batch_count", -1)) != _capacity_segments.size():
		return _fail("FA $0F packet capacity batches differ from the ROM $9B28 request-size branch.")
	source_packet_count = source_packets.size()
	capacity_boundary_count_required = maxi(0, _capacity_segments.size() - 1)
	var initial_segment := get_initial_queue_segment()
	pending_segment_index = 0 if bool(initial_segment.get("must_yield_at_capacity", false)) else -1
	state = State.WAITING_FOR_NMI_QUEUE_RELEASE \
		if bool(initial_segment.get("must_yield_at_capacity", false)) else State.COMPLETED
	return true


## Queue the first run of packet writes up to the next ROM capacity wait.
## This is staged work; the producer must not treat it as NMI-committed yet.
func get_initial_queue_segment() -> Dictionary:
	if _capacity_segments.is_empty():
		return {}
	return _capacity_segments[0].duplicate(true)


## Resume the FA $0F worker only after its queued packets were drained by the
## NMI consumer and the source scheduler released the `$9FA8(A=$01)` wait.
## A successful call returns the drained segment and the next segment to stage.
func advance_after_nmi_release(receipt: Dictionary) -> Dictionary:
	if not uses_nmi_release_receipts:
		return _refused("task_does_not_use_nmi_release_receipts")
	if state != State.WAITING_FOR_NMI_QUEUE_RELEASE or pending_segment_index < 0:
		return _refused("task_not_waiting_for_capacity_release")
	var expected: Dictionary = _capacity_segments[pending_segment_index]
	if not _validate_nmi_release_receipt(receipt, expected):
		return _refused("nmi_release_receipt_rejected")

	var sequence := int(receipt.get("nmi_sequence", -1))
	var release_source_frame := int(receipt.get("source_frame", -1))
	var has_nmi_sequence := sequence >= 0
	if (has_nmi_sequence and sequence <= last_nmi_sequence) or release_source_frame < 0 \
			or (last_release_source_frame >= 0 and release_source_frame <= last_release_source_frame):
		return _refused("nmi_release_order_rejected")
	if has_nmi_sequence:
		last_nmi_sequence = sequence
	last_release_source_frame = release_source_frame
	nmi_queue_release_count += 1
	var released_segment := expected.duplicate(true)
	var next_index := pending_segment_index + 1
	var next_segment: Dictionary = {}
	var returned := next_index >= _capacity_segments.size()
	if not returned:
		next_segment = _capacity_segments[next_index].duplicate(true)
		pending_segment_index = next_index if bool(next_segment.get("must_yield_at_capacity", false)) else -1
		returned = not bool(next_segment.get("must_yield_at_capacity", false))
	if returned:
		state = State.COMPLETED
		return_scan_source_frame = release_source_frame
	else:
		state = State.WAITING_FOR_NMI_QUEUE_RELEASE
	return {
		"ok": true,
		"status": "task_returned" if returned else "packet_batch_released",
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"background_id": background_id,
		"nmi_sequence": sequence if has_nmi_sequence else -1,
		"source_frame": release_source_frame,
		"released_segment": released_segment,
		"next_queue_segment": next_segment,
		"capacity_yield_count": nmi_queue_release_count,
		"capacity_yield_count_required": capacity_boundary_count_required,
		"resume_pc": CAPACITY_YIELD_RESUME_PC,
		"resume_saved_return_word": CAPACITY_YIELD_SAVED_RETURN_WORD,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_timing_claim": "NMI release is source-event driven; no Godot frame offset is assigned",
	}


## Compatibility path for existing cutscene background users. Descriptor FA
## $0F deliberately refuses this path so a route-frame tick cannot impersonate
## the required source NMI release.
func advance_source_tick(source_frame: int) -> Dictionary:
	if uses_nmi_release_receipts:
		return _refused("fa_0f_requires_source_nmi_release_receipt")
	if state != State.WAITING_FOR_NMI_QUEUE_RELEASE:
		return _refused("task_not_waiting")
	if source_frame <= last_release_source_frame:
		return _fail_result("Background source ticks must advance monotonically.")
	last_release_source_frame = source_frame
	nmi_queue_release_count += 1
	var batch_index := nmi_queue_release_count - 1
	var returned := nmi_queue_release_count >= _legacy_batch_count
	if returned:
		state = State.COMPLETED
		return_scan_source_frame = source_frame
	return {
		"ok": true,
		"status": "task_returned" if returned else "packet_batch_released",
		"event_index": event_index,
		"batch_index": batch_index,
		"source_frame": source_frame,
		"release_count": nmi_queue_release_count,
		"release_count_required": _legacy_batch_count,
	}


static func derive_capacity_segments(packet_stream: Array, initial_cursor: int) -> Dictionary:
	if initial_cursor < 0 or initial_cursor >= QUEUE_CURSOR_LIMIT:
		return {"ok": false, "error": "The live source queue cursor must be within 0..$3C."}
	var segments: Array[Dictionary] = []
	var current_packets: Array[Dictionary] = []
	var current_cursor := initial_cursor
	var current_start_cursor := initial_cursor
	var total_encoded_bytes := 0
	for packet_index in packet_stream.size():
		var packet_variant: Variant = packet_stream[packet_index]
		if not packet_variant is Dictionary:
			return {"ok": false, "error": "ROM packet %d is not a dictionary." % packet_index}
		var packet: Dictionary = packet_variant
		var payload_variant: Variant = packet.get("payload", PackedByteArray())
		if not payload_variant is PackedByteArray or payload_variant.is_empty():
			return {"ok": false, "error": "ROM packet %d has no non-empty payload." % packet_index}
		var payload: PackedByteArray = payload_variant
		var expected_encoded := payload.size() + QUEUE_PACKET_HEADER_BYTES
		if int(packet.get("queue_encoded_bytes", -1)) != expected_encoded:
			return {"ok": false, "error": "ROM packet %d encoded length does not match its payload plus three queue bytes." % packet_index}
		if int(packet.get("ppu_address", -1)) < 0x2000 or int(packet.get("ppu_address", -1)) >= 0x2800:
			return {"ok": false, "error": "ROM packet %d targets outside nametable/attribute RAM." % packet_index}
		if current_cursor + payload.size() >= QUEUE_CURSOR_LIMIT:
			if not current_packets.is_empty():
				segments.append(_make_capacity_segment(segments.size(), current_packets,
					current_start_cursor, current_cursor, true, false))
				current_packets = []
				current_cursor = 0
				current_start_cursor = 0
			elif current_cursor > 0:
				# Existing ROM-source queue bytes may already occupy $0628. The
				# handler yields before reserving this packet, flushing that queue.
				segments.append(_make_capacity_segment(segments.size(), [],
					current_start_cursor, current_cursor, true, true))
				current_cursor = 0
				current_start_cursor = 0
			else:
				return {"ok": false, "error": "A single ROM request reaches the $9B28 capacity limit from an empty queue."}
		current_packets.append(packet.duplicate(true))
		current_cursor += expected_encoded
		total_encoded_bytes += expected_encoded
	if not current_packets.is_empty():
		segments.append(_make_capacity_segment(segments.size(), current_packets,
			current_start_cursor, current_cursor, false, false))
	if segments.is_empty():
		return {"ok": false, "error": "FA $0F source packet stream produced no queue segments."}
	return {
		"ok": true,
		"segments": segments,
		"packet_count": packet_stream.size(),
		"encoded_byte_count": total_encoded_bytes,
		"capacity_boundary_count": maxi(0, segments.size() - 1),
		"queue_cursor_limit": QUEUE_CURSOR_LIMIT,
		"queue_writer_pc": QUEUE_WRITER_PC,
		"source_rom_sha256": SOURCE_ROM_SHA256,
	}


static func _make_capacity_segment(segment_index: int, packets: Array[Dictionary],
		queue_cursor_before: int, queue_cursor_after: int,
		must_yield_at_capacity: bool, flush_existing_queue: bool) -> Dictionary:
	return {
		"segment_index": segment_index,
		"packets": packets.duplicate(true),
		"ppu_writes": _flatten_packet_ppu_writes(packets),
		"packet_count": packets.size(),
		"queue_cursor_before": queue_cursor_before,
		"queue_cursor_bytes": queue_cursor_after,
		"serialized_queue_byte_count": queue_cursor_after - queue_cursor_before,
		"queue_cursor_after_nmi": 0,
		"queue_cursor_limit": QUEUE_CURSOR_LIMIT,
		"must_yield_at_capacity": must_yield_at_capacity,
		"flush_existing_queue": flush_existing_queue,
		"yield_site_pc": CAPACITY_YIELD_LDA_PC if must_yield_at_capacity else -1,
		"yield_call_pc": CAPACITY_YIELD_JSR_PC if must_yield_at_capacity else -1,
		"yield_saved_return_word": CAPACITY_YIELD_SAVED_RETURN_WORD if must_yield_at_capacity else -1,
		"yield_resume_pc": CAPACITY_YIELD_RESUME_PC if must_yield_at_capacity else -1,
		"caller_saved_return_word": CAPACITY_CALLER_SAVED_RETURN_WORD if must_yield_at_capacity else -1,
		"caller_resume_pc": CAPACITY_CALLER_RESUME_PC if must_yield_at_capacity else -1,
		"queue_writer_pc": QUEUE_WRITER_PC,
		"nmi_queue_consumer_pc": NMI_QUEUE_CONSUMER_PC,
	}


static func _flatten_packet_ppu_writes(packets: Array[Dictionary]) -> Array[Dictionary]:
	var writes: Array[Dictionary] = []
	for packet_index in packets.size():
		var packet: Dictionary = packets[packet_index]
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		var base_address := int(packet.get("ppu_address", -1))
		for byte_index in payload.size():
			writes.append({
				"packet_index": packet_index,
				"byte_index": byte_index,
				"ppu_address": base_address + byte_index,
				"value": int(payload[byte_index]),
			})
	return writes


func _validate_nmi_release_receipt(receipt: Dictionary, expected_segment: Dictionary) -> bool:
	if bool(expected_segment.get("flush_existing_queue", false)):
		# This segment contains no FA packets: it releases bytes that were
		# already in the shared queue before FA $0F reached its capacity guard.
		return bool(receipt.get("ok", false)) \
			and String(receipt.get("event_id", "")) == "" \
			and int(receipt.get("batch_index", -1)) == -1 \
			and int(receipt.get("queue_cursor_before", -1)) == int(expected_segment.get("queue_cursor_bytes", -2)) \
			and int(receipt.get("queued_bytes", -1)) == int(expected_segment.get("queue_cursor_bytes", -2)) \
			and int(receipt.get("committed_bytes", -1)) == int(expected_segment.get("queue_cursor_bytes", -2)) \
			and int(receipt.get("queue_cursor_after", -1)) == 0 \
			and int(receipt.get("nmi_consumer_pc", -1)) == NMI_QUEUE_CONSUMER_PC \
			and int(receipt.get("source_frame", -1)) >= 0
	var source_yield: Dictionary = receipt.get("source_yield", {})
	return bool(receipt.get("ok", false)) \
		and String(receipt.get("kind", "")) == "rom_cutscene_background_nmi_queue_release" \
		and String(receipt.get("source_rom_sha256", "")) == SOURCE_ROM_SHA256 \
		and int(receipt.get("event_index", -1)) == event_index \
		and int(receipt.get("source_cpu_address", -1)) == source_cpu_address \
		and int(receipt.get("background_id", -1)) == background_id \
		and int(receipt.get("segment_index", -1)) == pending_segment_index \
		and receipt.get("segment", {}) == expected_segment \
		and int(receipt.get("queue_cursor_before", -1)) == int(expected_segment.get("queue_cursor_bytes", -2)) \
		and int(receipt.get("queue_cursor_after", -1)) == 0 \
		and bool(receipt.get("queue_drained", false)) \
		and int(receipt.get("consumer_source_pc", -1)) == NMI_QUEUE_CONSUMER_PC \
		and int(receipt.get("serialized_queue_byte_count", -1)) == int(expected_segment.get("serialized_queue_byte_count", -2)) \
		and receipt.get("committed_ppu_writes", []) == expected_segment.get("ppu_writes", []) \
		and int(source_yield.get("writer_pc", -1)) == QUEUE_WRITER_PC \
		and int(source_yield.get("yield_site_pc", -1)) == CAPACITY_YIELD_LDA_PC \
		and int(source_yield.get("yield_call_pc", -1)) == CAPACITY_YIELD_JSR_PC \
		and int(source_yield.get("saved_return_word", -1)) == CAPACITY_YIELD_SAVED_RETURN_WORD \
		and int(source_yield.get("resume_pc", -1)) == CAPACITY_YIELD_RESUME_PC \
		and int(source_yield.get("caller_saved_return_word", -1)) == CAPACITY_CALLER_SAVED_RETURN_WORD \
		and int(source_yield.get("caller_resume_pc", -1)) == CAPACITY_CALLER_RESUME_PC


func _build_capacity_segments(source_packets: Array, initial_cursor: int) -> bool:
	var result := derive_capacity_segments(source_packets, initial_cursor)
	if not bool(result.get("ok", false)):
		return _fail(String(result.get("error", "ROM packet capacity derivation failed.")))
	_capacity_segments = result.get("segments", []).duplicate(true)
	source_packet_count = int(result.get("packet_count", 0))
	source_encoded_byte_count = int(result.get("encoded_byte_count", 0))
	return true


func get_status() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"background_id": background_id,
		"source_queue_cursor_at_start": source_queue_cursor_at_start,
		"source_queue_cursor_source": queue_cursor_source,
		"source_packet_count": source_packet_count,
		"source_encoded_byte_count": source_encoded_byte_count,
		"capacity_segment_count": _capacity_segments.size(),
		"capacity_boundary_count_required": capacity_boundary_count_required,
		"nmi_queue_release_count": nmi_queue_release_count,
		"pending_segment_index": pending_segment_index,
		"last_nmi_sequence": last_nmi_sequence,
		"last_release_source_frame": last_release_source_frame,
		"return_scan_source_frame": return_scan_source_frame,
		"uses_nmi_release_receipts": uses_nmi_release_receipts,
		"queue_cursor_limit": QUEUE_CURSOR_LIMIT,
		"queue_writer_pc": QUEUE_WRITER_PC,
		"capacity_yield_call_pc": CAPACITY_YIELD_JSR_PC,
		"capacity_yield_saved_return_word": CAPACITY_YIELD_SAVED_RETURN_WORD,
		"capacity_yield_resume_pc": CAPACITY_YIELD_RESUME_PC,
		"capacity_caller_resume_pc": CAPACITY_CALLER_RESUME_PC,
		"nmi_queue_consumer_pc": NMI_QUEUE_CONSUMER_PC,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"trace_state_used_as_runtime_input": false,
		"frame_level_scheduler_phase_modeled": false,
		"error": error_message,
	}


func _reset() -> void:
	state = State.UNCONFIGURED
	error_message = ""
	event_index = -1
	source_cpu_address = -1
	background_id = -1
	source_queue_cursor_at_start = -1
	queue_cursor_source = ""
	source_packet_count = 0
	source_encoded_byte_count = 0
	capacity_boundary_count_required = 0
	nmi_queue_release_count = 0
	pending_segment_index = -1
	last_nmi_sequence = -1
	last_release_source_frame = -1
	return_scan_source_frame = -1
	uses_nmi_release_receipts = false
	_capacity_segments.clear()
	_legacy_batch_count = 0


func _fail(message: String) -> bool:
	error_message = message
	state = State.FAILED
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	return _refused("failed")


func _refused(status: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error_message}
