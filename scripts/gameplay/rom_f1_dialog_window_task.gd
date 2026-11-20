extends RefCounted
class_name RomF1DialogWindowTask
## ROM-backed buffered F1 02 window producer. It emits source queue batches and
## suspends between them until the presenter returns the matching $A000 NMI receipt.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const STREAM_PATH := "res://assets/gameplay/rom_logic/f1_02_window.bin"
const MANIFEST_PATH := "res://assets/gameplay/rom_logic/f1_02_window.json"
const EXPECTED_STREAM_SHA256 := "03848717537daf13beb38610b062634b5e5096d11587e9aefaeed5ca19c9e422"
const EXPECTED_STREAM_LENGTH := 90
const EXPECTED_RECORD_COUNT := 4
const SOURCE_CPU_ADDRESS := 0xBBE8
const SOURCE_FILE_OFFSET := 0x00DBF8
const SOURCE_QUEUE_START := 0x05E8
const QUEUE_CAPACITY_LIMIT := 0x3D
const QUEUE_HEADER_BYTES := 3
const CLEAR_ROW_COUNT := 11
const CLEAR_ROW_BYTES := 30
const NMI_CONSUMER_PC := 0xA000

enum State {
	UNCONFIGURED,
	READY,
	WAITING_FOR_QUEUE_CAPACITY,
	WAITING_FOR_BATCH_RELEASE,
	COMPLETED,
	FAILED,
}

var state: State = State.UNCONFIGURED
var error_message := ""
var event_id := ""
var event_index := -1
var source_cpu_address := -1
var start_source_frame := -1
var last_source_frame := -1
var brightness_counters := Vector2i.ZERO
var source_queue_cursor_at_start := -1
var packets: Array[Dictionary] = []
var packet_batches: Array[Dictionary] = []
var release_receipt_history: Array[Dictionary] = []
var initial_release_receipt_required := false
var _configured := false
var _next_batch_index := 0
var _initial_action_consumed := false
var _expected_release_receipt: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var stream := FileAccess.get_file_as_bytes(STREAM_PATH)
	if stream.size() != EXPECTED_STREAM_LENGTH or _sha256(stream) != EXPECTED_STREAM_SHA256:
		return _fail("Packaged ROM-derived F1 02 stream failed size/hash validation.")
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return _fail("Packaged F1 02 manifest is not a JSON object.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != "ct2-f1-02-ppu-window-v1" \
			or str(manifest.get("rom", {}).get("sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("Packaged F1 02 manifest targets a different source or ROM revision.")
	var source: Dictionary = manifest.get("source", {})
	if int(str(source.get("prg_bank", "-1"))) != 6 \
			or str(source.get("pointer_entry_cpu", "")) != "$BB44" \
			or str(source.get("pointer_entry_bytes", "")) != "E8 BB" \
			or str(source.get("stream_cpu_start", "")) != "0xBBE8" \
			or str(source.get("stream_file_start", "")) != "0x00DBF8":
		return _fail("F1 02 source pointer/bank/file provenance differs from bank-6 $BB44->$BBE8.")
	var resource: Dictionary = manifest.get("resource", {})
	if int(resource.get("byte_length", -1)) != stream.size() \
			or str(resource.get("sha256", "")) != EXPECTED_STREAM_SHA256:
		return _fail("F1 02 manifest does not pin the packaged byte stream.")
	if not _decode_records(stream, manifest):
		return false
	_configured = true
	state = State.READY
	return true


## Start only the buffered F1 02 branch. The caller supplies source-owned
## $4A/$4B counters and the live presenter cursor for the shared $05E8 queue.
func begin(event: Dictionary, cutscene_id: int, source_frame: int,
		live_brightness_counters: Vector2i, queue_cursor: int) -> bool:
	_reset_run_state()
	if not _configured and not configure_from_project_sources():
		return false
	var arguments: Array = event.get("arguments", [])
	var raw_bytes: Array = event.get("raw_bytes", [])
	if cutscene_id != 0x56 or str(event.get("kind", "")) != "dialog_window" \
			or int(event.get("opcode", -1)) != 0xF1 \
			or arguments.size() != 1 or int(arguments[0]) != 0x02 \
			or raw_bytes.size() != 2 or int(raw_bytes[0]) != 0xF1 \
			or int(raw_bytes[1]) != 0x02 \
			or int(event.get("cpu_address", -1)) != 0xBFBA \
			or source_frame < 0:
		return _fail("F1 02 task requires scene $56's byte-checked $BFBA command and a source frame.")
	if live_brightness_counters.x <= 0 and live_brightness_counters.y <= 0:
		return _fail("F1 02 task only models the source-selected buffered $97B6 branch; both $4A/$4B may not be zero.")
	if queue_cursor < 0 or queue_cursor >= QUEUE_CAPACITY_LIMIT:
		return _fail("F1 02 task received an invalid live $0628 queue cursor.")
	event_index = int(event.get("event_index", -1))
	source_cpu_address = int(event.get("cpu_address", -1))
	event_id = "cutscene_%02X_event_%d_%04X" % [cutscene_id, event_index, source_cpu_address]
	start_source_frame = source_frame
	last_source_frame = source_frame
	brightness_counters = live_brightness_counters
	source_queue_cursor_at_start = queue_cursor
	if not _build_capacity_batches(queue_cursor):
		return false
	initial_release_receipt_required = queue_cursor > 0 \
		and queue_cursor + int(packets[0].get("payload_size", -1)) >= QUEUE_CAPACITY_LIMIT
	state = State.WAITING_FOR_QUEUE_CAPACITY if initial_release_receipt_required else State.READY
	return true


## Return the initial source action. It is either a generic inherited-queue
## drain request or the first ROM-derived batch, never both.
func get_initial_action() -> Dictionary:
	if _initial_action_consumed or state not in [State.READY, State.WAITING_FOR_QUEUE_CAPACITY]:
		return {"ok": false, "status": "initial_action_unavailable", "error": error_message}
	_initial_action_consumed = true
	if state == State.WAITING_FOR_QUEUE_CAPACITY:
		_expected_release_receipt = {
			"event_id": "",
			"batch_index": -1,
			"queue_cursor_before": source_queue_cursor_at_start,
			"queued_bytes": source_queue_cursor_at_start,
			"committed_bytes": source_queue_cursor_at_start,
			"queue_cursor_after": 0,
			"nmi_consumer_pc": NMI_CONSUMER_PC,
		}
		return {
			"ok": true,
			"status": "wait_for_inherited_queue_release",
			"event_id": event_id,
			"event_index": event_index,
			"release_receipt_expectation": _expected_release_receipt.duplicate(true),
			"source_pc": 0x9B28,
			"source_yield_delay": 1,
		}
	return _stage_next_batch(start_source_frame)


## Resume after the NMI consumer drains the pending $05E8 queue. For the
## initial inherited queue, use the empty event ID and batch index -1; later
## receipts must echo the exact batch contract emitted by this task.
func advance_source_tick(source_frame: int, nmi_release_receipt: Dictionary) -> Dictionary:
	if state not in [State.WAITING_FOR_QUEUE_CAPACITY, State.WAITING_FOR_BATCH_RELEASE]:
		return _refused("task_not_waiting_for_queue_release")
	if source_frame <= last_source_frame:
		return _fail_result("F1 02 source ticks must advance monotonically after the prior `$9FA8` yield.")
	if not _validate_release_receipt(nmi_release_receipt, source_frame):
		return _fail_result(error_message)
	last_source_frame = source_frame
	release_receipt_history.append(nmi_release_receipt.duplicate(true))
	if state == State.WAITING_FOR_QUEUE_CAPACITY:
		state = State.READY
	return _stage_next_batch(source_frame)


func get_status() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"event_id": event_id,
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"start_source_frame": start_source_frame,
		"last_source_frame": last_source_frame,
		"brightness_counters_004A_004B": [brightness_counters.x, brightness_counters.y],
		"source_queue_cursor_at_start": source_queue_cursor_at_start,
		"packet_count": packets.size(),
		"batch_count": packet_batches.size(),
		"next_batch_index": _next_batch_index,
		"initial_inherited_queue_release_required": initial_release_receipt_required,
		"expected_release_receipt": _expected_release_receipt.duplicate(true),
		"release_receipt_history": release_receipt_history.duplicate(true),
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_stream_sha256": EXPECTED_STREAM_SHA256,
		"source_cpu_stream_start": "$BBE8",
		"source_file_stream_start": "0x00DBF8",
		"queue_capacity_limit": QUEUE_CAPACITY_LIMIT,
		"nmi_consumer_pc": NMI_CONSUMER_PC,
		"physical_nmi_cycle_phase_modeled": false,
		"error": error_message,
	}


func _decode_records(stream: PackedByteArray, manifest: Dictionary) -> bool:
	packets.clear()
	var records_variant: Variant = manifest.get("format", {}).get("records", [])
	if not records_variant is Array or records_variant.size() != EXPECTED_RECORD_COUNT:
		return _fail("F1 02 manifest must preserve exactly four table records.")
	var position := 0
	for record_index in EXPECTED_RECORD_COUNT:
		if position + QUEUE_HEADER_BYTES > stream.size():
			return _fail("F1 02 stream has a truncated record header.")
		var header := int(stream[position])
		var payload_size := header & 0x3F
		var end := position + QUEUE_HEADER_BYTES + payload_size
		if end > stream.size():
			return _fail("F1 02 stream has a truncated record payload.")
		var record: PackedByteArray = stream.slice(position, end)
		var payload: PackedByteArray = stream.slice(position + QUEUE_HEADER_BYTES, end)
		var address := (int(stream[position + 1]) | (int(stream[position + 2]) << 8)) & 0x3FFF
		var increment := 32 if (header & 0x80) != 0 else 1
		var final_record := (header & 0x40) != 0
		var meta: Dictionary = records_variant[record_index]
		if int(meta.get("index", -1)) != record_index \
				or _hex_or_int(meta.get("cpu_address", "")) != SOURCE_CPU_ADDRESS + position \
				or _hex_or_int(meta.get("file_offset", "")) != SOURCE_FILE_OFFSET + position \
				or int(meta.get("header", -1)) != header \
				or int(meta.get("payload_size", -1)) != payload_size \
				or _hex_or_int(meta.get("ppu_address", "")) != address \
				or int(meta.get("increment", -1)) != increment \
				or bool(meta.get("final", false)) != final_record \
				or str(meta.get("sha256", "")) != _sha256(record):
			return _fail("F1 02 record %d failed its ROM manifest/byte validation." % record_index)
		packets.append({
			"kind": "f1_02_table_record",
			"record_index": record_index,
			"source_cpu_address": SOURCE_CPU_ADDRESS + position,
			"source_file_offset": SOURCE_FILE_OFFSET + position,
			"header": header,
			"ppu_address": address,
			"increment": increment,
			"payload": payload,
			"payload_size": payload_size,
			"queue_encoded_bytes": QUEUE_HEADER_BYTES + payload_size,
			"final": final_record,
			"source_sha256": _sha256(record),
		})
		position = end
	if position != stream.size() or not bool(packets.back().get("final", false)):
		return _fail("F1 02 stream end/final-record boundary differs from the ROM table.")
	return true


func _build_capacity_batches(initial_cursor: int) -> bool:
	packet_batches.clear()
	var producer_packets: Array[Dictionary] = []
	for row_index in CLEAR_ROW_COUNT:
		var payload := PackedByteArray()
		payload.resize(CLEAR_ROW_BYTES)
		payload.fill(0)
		producer_packets.append({
			"kind": "f1_02_clear_row",
			"record_index": row_index,
			"source_cpu_address": 0x98E8,
			"source_file_offset": 0x18F8,
			"ppu_address": 0x2221 + row_index * 0x20,
			"increment": 1,
			"payload": payload,
			"payload_size": CLEAR_ROW_BYTES,
			"queue_encoded_bytes": QUEUE_HEADER_BYTES + CLEAR_ROW_BYTES,
			"final": false,
		})
	producer_packets.append_array(packets)
	var queue_cursor := initial_cursor
	var batch_cursor_before := initial_cursor
	var current_packets: Array[Dictionary] = []
	var inherited_drain := false
	for packet_variant in producer_packets:
		var packet: Dictionary = packet_variant
		var payload_size := int(packet.get("payload_size", -1))
		if payload_size <= 0 or payload_size >= QUEUE_CAPACITY_LIMIT:
			return _fail("F1 02 source packet cannot fit within the `$9B28` queue limit.")
		if queue_cursor + payload_size >= QUEUE_CAPACITY_LIMIT:
			if not current_packets.is_empty():
				_append_batch(current_packets, batch_cursor_before, queue_cursor - batch_cursor_before)
				current_packets = []
				queue_cursor = 0
				batch_cursor_before = 0
			elif queue_cursor > 0:
				if not packet_batches.is_empty() or inherited_drain:
					return _fail("F1 02 source queue yielded twice before producing a batch.")
				inherited_drain = true
				queue_cursor = 0
				batch_cursor_before = 0
		if queue_cursor + payload_size >= QUEUE_CAPACITY_LIMIT:
			return _fail("F1 02 packet remains too large after the source queue release.")
		current_packets.append(packet.duplicate(true))
		queue_cursor += int(packet.get("queue_encoded_bytes", -1))
	if not current_packets.is_empty():
		_append_batch(current_packets, batch_cursor_before, queue_cursor - batch_cursor_before)
	if packet_batches.size() != 13:
		return _fail("F1 02 source records should produce 13 `$9B28` capacity batches; got %d." % packet_batches.size())
	initial_release_receipt_required = inherited_drain
	return true


func _append_batch(batch_packets: Array[Dictionary], cursor_before: int, encoded_bytes: int) -> void:
	var batch_index := packet_batches.size()
	var cursor_after := cursor_before + encoded_bytes
	var payload_bytes := 0
	for packet in batch_packets:
		payload_bytes += int(packet.get("payload_size", 0))
	packet_batches.append({
			"event_id": event_id,
			"event_index": event_index,
			"batch_index": batch_index,
			"queue_cursor_before": cursor_before,
			"queued_bytes": encoded_bytes,
			"queue_cursor_after_staging": cursor_after,
			"payload_bytes": payload_bytes,
			"packet_count": batch_packets.size(),
			"packets": batch_packets.duplicate(true),
			"source_queue_start": SOURCE_QUEUE_START,
			"capacity_limit": QUEUE_CAPACITY_LIMIT,
			"release_receipt_expectation": {
				"event_id": event_id,
				"batch_index": batch_index,
				"queue_cursor_before": cursor_before,
				"queued_bytes": encoded_bytes,
				"committed_bytes": encoded_bytes,
				"queue_cursor_after": 0,
				"nmi_consumer_pc": NMI_CONSUMER_PC,
			},
		})


func _stage_next_batch(source_frame: int) -> Dictionary:
	if _next_batch_index >= packet_batches.size():
		return _fail_result("F1 02 has no remaining ROM-derived packet batch.")
	var batch: Dictionary = packet_batches[_next_batch_index].duplicate(true)
	_next_batch_index += 1
	var returned := _next_batch_index >= packet_batches.size()
	state = State.COMPLETED if returned else State.WAITING_FOR_BATCH_RELEASE
	_expected_release_receipt = {} if returned else batch.get("release_receipt_expectation", {}).duplicate(true)
	return {
		"ok": true,
		"status": "task_returned" if returned else "batch_staged_waiting_for_nmi",
		"event_id": event_id,
		"event_index": event_index,
		"source_frame": source_frame,
		"batch": batch,
		"next_release_receipt_expectation": _expected_release_receipt.duplicate(true),
		"next_source_pc": 0x9B28 if not returned else 0x8879,
		"source_yield_delay": 1 if not returned else 0,
	}


func _validate_release_receipt(receipt: Dictionary, source_frame: int) -> bool:
	if not bool(receipt.get("ok", false)) \
			or int(receipt.get("source_frame", -1)) != source_frame \
			or String(receipt.get("event_id", "")) != String(_expected_release_receipt.get("event_id", "")) \
			or int(receipt.get("batch_index", -999)) != int(_expected_release_receipt.get("batch_index", -999)) \
			or int(receipt.get("queue_cursor_before", -1)) != int(_expected_release_receipt.get("queue_cursor_before", -2)) \
			or int(receipt.get("queued_bytes", -1)) != int(_expected_release_receipt.get("queued_bytes", -2)) \
			or int(receipt.get("committed_bytes", -1)) != int(_expected_release_receipt.get("committed_bytes", -2)) \
			or int(receipt.get("queue_cursor_after", -1)) != 0 \
			or _hex_or_int(receipt.get("nmi_consumer_pc", -1)) != NMI_CONSUMER_PC:
		return _fail("F1 02 refused a queue release without the exact source event/batch/$A000 NMI receipt.")
	return true


func _reset_run_state() -> void:
	state = State.READY if _configured else State.UNCONFIGURED
	error_message = ""
	event_id = ""
	event_index = -1
	source_cpu_address = -1
	start_source_frame = -1
	last_source_frame = -1
	brightness_counters = Vector2i.ZERO
	source_queue_cursor_at_start = -1
	packet_batches.clear()
	release_receipt_history.clear()
	initial_release_receipt_required = false
	_next_batch_index = 0
	_initial_action_consumed = false
	_expected_release_receipt.clear()


func _hex_or_int(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	var text := str(value).strip_edges().trim_prefix("$").trim_prefix("0x")
	return int(text.hex_to_int())


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	state = State.FAILED
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	return _refused("failed")


func _refused(status: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error_message}
