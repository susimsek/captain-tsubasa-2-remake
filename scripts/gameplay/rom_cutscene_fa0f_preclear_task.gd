extends RefCounted
class_name RomCutsceneFa0fPreclearTask
## ROM-derived row-clear producer for scene-$56 FA $0F's buffered path.
## Route frames never release this task; only a matching $A03C NMI receipt does.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const STREAM_PATH := "res://assets/gameplay/rom_logic/fa_0f_preclear_sources.bin"
const MANIFEST_PATH := "res://assets/gameplay/rom_logic/fa_0f_preclear_sources.json"
const EXPECTED_STREAM_SHA256 := "208e9658ca12e3c21c26dfa418bf7a08607d4d997797be760b8affc563681c35"
const EXPECTED_STREAM_LENGTH := 365
const EXPECTED_SOURCE_SPAN_COUNT := 6
const EVENT_CPU_ADDRESS := 0xBFBC
const EVENT_FILE_OFFSET := 0x00BFCC
const EVENT_INDEX := 1
const SOURCE_QUEUE_START := 0x05E8
const QUEUE_CAPACITY_LIMIT := 0x3D
const QUEUE_STORAGE_LIMIT := 0x40
const QUEUE_HEADER_BYTES := 3
const ROW_COUNT := 16
const ROW_BYTES := 32
const ROW_ADDRESS_STRIDE := 0x20
const ROW_PRODUCER_CPU_ADDRESS := 0x98E8
const QUEUE_WRITER_CPU_ADDRESS := 0x9B28
const QUEUE_YIELD_CALL_PC := 0x9B30
const QUEUE_YIELD_SAVED_RETURN_WORD := 0x9B32
const QUEUE_YIELD_RESUME_PC := 0x9B33
const ROW_CALLER_JSR_PC := 0x98FC
const ROW_CALLER_SAVED_RETURN_WORD := 0x98FE
const NMI_QUEUE_CONSUMER_PC := 0xA03C

enum State {
	UNCONFIGURED,
	READY,
	WAITING_FOR_INHERITED_QUEUE_RELEASE,
	WAITING_FOR_ROW_QUEUE_RELEASE,
	COMPLETED,
	FAILED,
}

var state: State = State.UNCONFIGURED
var error_message := ""
var event_id := ""
var event_index := -1
var source_cpu_address := -1
var source_helper_entry_pc := -1
var destination_ppu_base := -1
var row_count := 0
var row_bytes := 0
var start_source_frame := -1
var last_source_frame := -1
var live_brightness_counters := Vector2i.ZERO
var source_queue_cursor_at_start := -1
var queue_cursor_source := ""
var rows_staged := 0
var nmi_release_count := 0
var release_receipt_history: Array[Dictionary] = []

var _configured := false
var _source_stream := PackedByteArray()
var _source_spans: Array = []
var _initial_action_consumed := false
var _expected_release_receipt: Dictionary = {}
var _pending_receipt_kind := ""


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var stream := FileAccess.get_file_as_bytes(STREAM_PATH)
	if stream.size() != EXPECTED_STREAM_LENGTH or _sha256(stream) != EXPECTED_STREAM_SHA256:
		return _fail("Packaged FA $0F preclear source bytes failed size/hash validation.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Packaged FA $0F preclear manifest is not a JSON object.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-scene-56-fa-0f-preclear-source-v1" \
			or String(manifest.get("rom", {}).get("sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("Preclear manifest targets a different schema or ROM revision.")
	var resource: Dictionary = manifest.get("resource", {})
	if int(resource.get("byte_length", -1)) != EXPECTED_STREAM_LENGTH \
			or String(resource.get("sha256", "")) != EXPECTED_STREAM_SHA256:
		return _fail("Preclear manifest does not pin the packaged source stream.")
	var spans_variant: Variant = manifest.get("source_spans", [])
	if not spans_variant is Array or spans_variant.size() != EXPECTED_SOURCE_SPAN_COUNT:
		return _fail("Preclear manifest must preserve all six checked ROM source spans.")
	for span_variant in spans_variant:
		if not span_variant is Dictionary:
			return _fail("Preclear source-span entry is not an object.")
		var span: Dictionary = span_variant
		var offset := int(span.get("combined_offset", -1))
		var length := int(span.get("byte_length", -1))
		if offset < 0 or length <= 0 or offset + length > stream.size():
			return _fail("Preclear source span has invalid packaged bounds.")
		var raw := stream.slice(offset, offset + length)
		if _sha256(raw) != String(span.get("sha256", "")) \
				or raw.hex_encode() != String(span.get("bytes_hex", "")):
			return _fail("Packaged source span %s failed byte/hash provenance." % String(span.get("name", "?")))
	if not _verify_known_source_rules(stream, spans_variant):
		return false
	_source_stream = stream
	_source_spans = spans_variant.duplicate(true)
	_configured = true
	state = State.READY
	return true


## Derive `$8AF7`'s `$9071/$9076` helper from live, source-owned RAM bits and
## the checked `$0F` loader bytes. The frame-end `$005D` capture is not an input.
func derive_helper_entry_pc(ram_005b_bits: Dictionary,
		ram_007b: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "error": error_message}
	var loader := _span_bytes(_source_stream, _source_spans, "fa_loader_selector")
	var descriptor := _span_bytes(_source_stream, _source_spans, "background_0f_descriptor")
	if loader.size() != 188 or descriptor.hex_encode() != "64669a020412575859525a5b5c5600a0" \
			or loader.slice(0x6E, 0x90).hex_encode() != "a902855d065c265d065c265db1632907055c855c065c265d065c265da55d290cd00c" \
			or loader.slice(0x90, 0x9C).hex_encode() != "a57b0a0a455b2904055d855d" \
			or loader.slice(0x9C, 0xBC).hex_encode() != "a55ec90990062071904cab8ba55d2904d0062071904cae8b207690a90120a89f":
		return {"ok": false, "error": "The `$8B87->$8BB2` helper selector or background `$0F` record differs from its checked ROM bytes."}
	var known_mask := int(ram_005b_bits.get("known_mask", 0))
	var known_value := int(ram_005b_bits.get("known_value", 0))
	if (known_mask & 0x04) == 0 or not bool(ram_007b.get("known", false)):
		return {"ok": false, "error": "The helper selector needs source-owned `$005B.2` and `$007B` state."}
	var write_5b: Dictionary = ram_005b_bits.get("last_write", {})
	var write_7b: Dictionary = ram_007b.get("last_write", {})
	if String(write_5b.get("event_id", "")).is_empty() \
			or int(write_5b.get("source_pc", -1)) != 0x881E \
			or String(write_7b.get("event_id", "")).is_empty() \
			or int(write_7b.get("source_pc", -1)) < 0:
		return {"ok": false, "error": "The helper selector RAM inputs do not carry their ROM writer provenance."}
	# `$8B65-$8B85` decodes this ROM descriptor to pre-formula `$5D=$21`;
	# `$8B87-$8B91` ORs in `(($7B << 2) XOR $5B) & $04`.
	var descriptor_baseline_5d := 0x21
	var selector_bit := (((int(ram_007b.get("value", -1)) << 2) ^ known_value) & 0x04)
	var computed_5d := descriptor_baseline_5d | selector_bit
	var helper_entry_pc := 0x9076 if (computed_5d & 0x04) != 0 else 0x9071
	return {
		"ok": true,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_event_id": "cutscene_56_event_1_BFBC_helper_selector",
		"source_frame": int(ram_007b.get("last_write", {}).get("source_frame", -1)),
		"ram_reads": [
			{"address": 0x005B, "bit_mask": 0x04,
				"value": known_value & 0x04, "last_write": write_5b.duplicate(true)},
			{"address": 0x007B, "bit_mask": 0x01,
				"value": int(ram_007b.get("value", -1)) & 0x01,
				"last_write": write_7b.duplicate(true)},
		],
		"descriptor_file_offset": "0x00E2A4",
		"descriptor_byte_3_5_hex": descriptor.slice(3, 6).hex_encode(),
		"descriptor_baseline_5d": descriptor_baseline_5d,
		"computed_5d": computed_5d,
		"formula_source_pc_start": 0x8B87,
		"formula_source_pc_end_exclusive": 0x8B93,
		"branch_source_pc": 0x8B9F,
		"branch_result_pc": 0x8BAB if helper_entry_pc == 0x9076 else 0x8BA5,
		"helper_entry_pc": helper_entry_pc,
		"destination_ppu_base": 0x2400 if helper_entry_pc == 0x9076 else 0x2000,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


## `helper_entry_pc` must come from the source loader's selected $9071 or $9076
## call. The task decodes that helper's ROM bytes to obtain the PPU base. The
## queue cursor must be live presenter state, never a retained capture value.
func begin(event: Dictionary, cutscene_id: int, source_frame: int,
		helper_entry_pc: int, brightness_counters: Vector2i,
		queue_cursor: int, cursor_source: String) -> bool:
	_reset_run_state()
	if not _configured and not configure_from_project_sources():
		return false
	var arguments: Array = event.get("arguments", [])
	var raw_bytes: Array = event.get("raw_bytes", [])
	if cutscene_id != 0x56 or String(event.get("kind", "")) != "background_2" \
			or int(event.get("opcode", -1)) != 0xFA \
			or arguments.size() != 1 or int(arguments[0]) != 0x0F \
			or int(event.get("id", -1)) != 0x0F \
			or int(event.get("event_index", -1)) != EVENT_INDEX \
			or raw_bytes.size() != 2 or int(raw_bytes[0]) != 0xFA \
			or int(raw_bytes[1]) != 0x0F \
			or int(event.get("cpu_address", -1)) != EVENT_CPU_ADDRESS \
			or int(event.get("file_offset", -1)) != EVENT_FILE_OFFSET \
			or source_frame < 0:
		return _fail("Preclear task requires scene $56's byte-checked $BFBC FA $0F event.")
	if brightness_counters.x <= 0 and brightness_counters.y <= 0:
		return _fail("Preclear task models the buffered $98E8 branch only; $4A|$4B is zero.")
	if queue_cursor < 0 or queue_cursor >= QUEUE_STORAGE_LIMIT \
			or cursor_source != "rom_derived_presenter_state":
		return _fail("Preclear task requires a live $0628 cursor in 0..$3F from the ROM-derived presenter.")
	if not _configure_helper(helper_entry_pc):
		return false

	event_index = int(event.get("event_index", -1))
	source_cpu_address = int(event.get("cpu_address", -1))
	source_helper_entry_pc = helper_entry_pc
	event_id = "cutscene_%02X_event_%d_%04X" % [cutscene_id, event_index, source_cpu_address]
	start_source_frame = source_frame
	last_source_frame = source_frame
	live_brightness_counters = brightness_counters
	source_queue_cursor_at_start = queue_cursor
	queue_cursor_source = cursor_source
	if queue_cursor + row_bytes >= QUEUE_CAPACITY_LIMIT:
		state = State.WAITING_FOR_INHERITED_QUEUE_RELEASE
		_pending_receipt_kind = "inherited"
		_expected_release_receipt = _make_inherited_receipt_expectation(queue_cursor)
	else:
		state = State.READY
	return true


## The first action either requests a generic drain of pre-existing queue bytes
## or emits the first ROM-derived clear row. It never does both at once.
func get_initial_action() -> Dictionary:
	if _initial_action_consumed or state not in [State.READY, State.WAITING_FOR_INHERITED_QUEUE_RELEASE]:
		return _refused("initial_action_unavailable")
	_initial_action_consumed = true
	if state == State.WAITING_FOR_INHERITED_QUEUE_RELEASE:
		return {
			"ok": true,
			"status": "wait_for_inherited_queue_release",
			"event_id": event_id,
			"event_index": event_index,
			"source_pc": QUEUE_WRITER_CPU_ADDRESS,
			"source_yield": _source_yield_metadata(),
			"release_receipt_expectation": _expected_release_receipt.duplicate(true),
		}
	return _stage_next_row(start_source_frame)


## A row-capacity wait resumes only when the NMI queue writer's receipt matches
## this task's expected event, row batch, byte count, empty cursor, and $A03C PC.
func advance_after_nmi_release(source_frame: int, receipt: Dictionary) -> Dictionary:
	if state not in [State.WAITING_FOR_INHERITED_QUEUE_RELEASE, State.WAITING_FOR_ROW_QUEUE_RELEASE]:
		return _refused("task_not_waiting_for_queue_release")
	if source_frame <= last_source_frame:
		return _fail_result("Preclear source frames must increase after the prior $9FA8 yield.")
	if not _validate_release_receipt(receipt, source_frame):
		return _fail_result(error_message)
	last_source_frame = source_frame
	release_receipt_history.append(receipt.duplicate(true))
	nmi_release_count += 1
	_pending_receipt_kind = ""
	_expected_release_receipt.clear()
	return _stage_next_row(source_frame)


func get_status() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"event_id": event_id,
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"source_helper_entry_pc": source_helper_entry_pc,
		"destination_ppu_base": destination_ppu_base,
		"row_count": row_count,
		"row_bytes": row_bytes,
		"rows_staged": rows_staged,
		"start_source_frame": start_source_frame,
		"last_source_frame": last_source_frame,
		"live_brightness_counters_004A_004B": [live_brightness_counters.x, live_brightness_counters.y],
		"source_queue_cursor_at_start": source_queue_cursor_at_start,
		"queue_cursor_source": queue_cursor_source,
		"nmi_release_count": nmi_release_count,
		"expected_release_receipt": _expected_release_receipt.duplicate(true),
		"release_receipt_history": release_receipt_history.duplicate(true),
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_stream_sha256": EXPECTED_STREAM_SHA256,
		"row_producer_pc": ROW_PRODUCER_CPU_ADDRESS,
		"queue_writer_pc": QUEUE_WRITER_CPU_ADDRESS,
		"queue_capacity_limit": QUEUE_CAPACITY_LIMIT,
		"queue_storage_limit": QUEUE_STORAGE_LIMIT,
		"nmi_queue_consumer_pc": NMI_QUEUE_CONSUMER_PC,
		"physical_nmi_cycle_phase_modeled": false,
		"frame_delays_injected": false,
		"error": error_message,
	}


func _verify_known_source_rules(stream: PackedByteArray, spans: Array) -> bool:
	var loader := _span_bytes(stream, spans, "fa_loader_selector")
	var helper := _span_bytes(stream, spans, "clear_helper_entrypoints")
	var producer := _span_bytes(stream, spans, "clear_row_producer")
	var queue := _span_bytes(stream, spans, "queue_capacity_writer")
	var event := _span_bytes(stream, spans, "scene_56_fa_0f_event")
	var descriptor := _span_bytes(stream, spans, "background_0f_descriptor")
	if loader.is_empty() or helper.is_empty() or producer.is_empty() or queue.is_empty() \
			or event.is_empty() or descriptor.is_empty():
		return _fail("Preclear manifest is missing a required ROM source span.")
	if event.hex_encode() != "fa0f" or descriptor.hex_encode() != "64669a020412575859525a5b5c5600a0":
		return _fail("FA $0F event or bank-7 descriptor source identity does not match this ROM.")
	if helper.slice(0, 5).hex_encode() != "a9204c7890" \
			or helper.slice(5, 20).hex_encode() != "a92485e7a90085e6a010a2204ce898":
		return _fail("ROM $9071/$9076 helper bytes no longer select the checked row-clear setup.")
	if producer.slice(4, 10).hex_encode() != "a54a054bf03a" \
			or producer.slice(20, 23).hex_encode() != "20289b" \
			or producer.slice(25, 31).hex_encode() != "a5eb9de805e8" \
			or producer.slice(34, 37).hex_encode() != "205e9b":
		return _fail("ROM $98E8 no longer matches the buffered 16 x 32 row producer path.")
	if queue.slice(0x0F, 0x19).hex_encode() != "293f186d2806c93db0ed" \
			or queue.slice(0x06, 0x0B).hex_encode() != "a90120a89f" \
			or queue.slice(0x36, 0x47).hex_encode() != "a9009de8058e2806ad290629bf8d290660":
		return _fail("ROM $9B28/$9B5E capacity, wait, or finalization bytes failed verification.")
	if loader.slice(0x9C, 0xBC).hex_encode() != "a55ec90990062071904cab8ba55d2904d0062071904cae8b207690a90120a89f":
		return _fail("ROM $8AF7 helper dispatch or separate post-helper wait differs from the manifest.")
	return true


func _configure_helper(helper_entry_pc: int) -> bool:
	var setup := _span_bytes(_source_stream, _source_spans, "clear_helper_entrypoints")
	if helper_entry_pc == 0x9071:
		if setup.slice(0, 5).hex_encode() != "a9204c7890" \
				or setup.slice(7, 20).hex_encode() != "85e7a90085e6a010a2204ce898":
			return _fail("ROM helper $9071 setup bytes differ from the expected $2000 row clear.")
		destination_ppu_base = 0x2000
	elif helper_entry_pc == 0x9076:
		if setup.slice(5, 20).hex_encode() != "a92485e7a90085e6a010a2204ce898":
			return _fail("ROM helper $9076 setup bytes differ from the expected $2400 row clear.")
		destination_ppu_base = 0x2400
	else:
		return _fail("Preclear task accepts only ROM helper entries $9071 or $9076.")
	row_count = ROW_COUNT
	row_bytes = ROW_BYTES
	return true


func _stage_next_row(source_frame: int) -> Dictionary:
	if rows_staged >= row_count:
		return _fail_result("Preclear has no remaining ROM-derived row.")
	var row_index := rows_staged
	var cursor_before := 0 if nmi_release_count > 0 or _pending_receipt_kind == "inherited" else source_queue_cursor_at_start
	if cursor_before + row_bytes >= QUEUE_CAPACITY_LIMIT:
		return _fail_result("Preclear tried to stage a row before the ROM capacity release.")
	var payload := PackedByteArray()
	payload.resize(row_bytes)
	payload.fill(0)
	var encoded_bytes := QUEUE_HEADER_BYTES + row_bytes
	var ppu_address := destination_ppu_base + row_index * ROW_ADDRESS_STRIDE
	var packet := {
		"kind": "fa_0f_preclear_row",
		"row_index": row_index,
		"source_cpu_address": ROW_PRODUCER_CPU_ADDRESS,
		"source_file_offset": 0x0018F8,
		"ppu_address": ppu_address,
		"increment": 1,
		"header": row_bytes,
		"payload": payload.duplicate(),
		"payload_size": row_bytes,
		"queue_encoded_bytes": encoded_bytes,
		"final": false,
	}
	var ppu_writes: Array[Dictionary] = []
	for byte_index in row_bytes:
		ppu_writes.append({
			"packet_index": 0,
			"byte_index": byte_index,
			"ppu_address": ppu_address + byte_index,
			"value": 0,
		})
	var batch := {
		"task_kind": "fa_0f_preclear",
		"event_id": event_id,
		"event_index": event_index,
		"batch_index": row_index,
		"row_index": row_index,
		"source_helper_entry_pc": source_helper_entry_pc,
		"source_cpu_address": ROW_PRODUCER_CPU_ADDRESS,
		"source_file_offset": 0x0018F8,
		"packets": [packet],
		"ppu_writes": ppu_writes,
		"packet_count": 1,
		"payload_bytes": row_bytes,
		"ppu_address": ppu_address,
		"increment": 1,
		"header": row_bytes,
		"payload": payload.duplicate(),
		"payload_size": row_bytes,
		"queue_encoded_bytes": encoded_bytes,
		"serialized_queue_byte_count": encoded_bytes,
		"queue_cursor_before": cursor_before,
		"queue_cursor_after_staging": cursor_before + encoded_bytes,
		"queue_cursor_bytes": cursor_before + encoded_bytes,
		"source_queue_start": SOURCE_QUEUE_START,
		"capacity_limit": QUEUE_CAPACITY_LIMIT,
		"release_receipt_expectation": _make_row_receipt_expectation(row_index, cursor_before, encoded_bytes),
	}
	rows_staged += 1
	var is_final_row := rows_staged >= row_count
	state = State.COMPLETED if is_final_row else State.WAITING_FOR_ROW_QUEUE_RELEASE
	if is_final_row:
		_expected_release_receipt.clear()
		_pending_receipt_kind = ""
	else:
		_expected_release_receipt = batch.get("release_receipt_expectation", {}).duplicate(true)
		_pending_receipt_kind = "row"
	return {
		"ok": true,
		"status": "task_returned" if is_final_row else "row_staged_waiting_for_capacity_release",
		"event_id": event_id,
		"event_index": event_index,
		"source_frame": source_frame,
		"batch": batch,
		"next_source_pc": QUEUE_WRITER_CPU_ADDRESS if not is_final_row else 0x8BAE,
		"source_wait": _source_yield_metadata(),
		"next_release_receipt_expectation": _expected_release_receipt.duplicate(true),
	}


func _make_inherited_receipt_expectation(cursor: int) -> Dictionary:
	return {
		"event_id": "",
		"batch_index": -1,
		"queue_cursor_before": cursor,
		"queued_bytes": cursor,
		"committed_bytes": cursor,
		"queue_cursor_after": 0,
		"nmi_consumer_pc": NMI_QUEUE_CONSUMER_PC,
	}


func _make_row_receipt_expectation(row_index: int, cursor_before: int, encoded_bytes: int) -> Dictionary:
	return {
		"event_id": event_id,
		"batch_index": row_index,
		"queue_cursor_before": cursor_before,
		"queued_bytes": encoded_bytes,
		"committed_bytes": encoded_bytes,
		"queue_cursor_after": 0,
		"nmi_consumer_pc": NMI_QUEUE_CONSUMER_PC,
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
			or _hex_or_int(receipt.get("nmi_consumer_pc", -1)) != NMI_QUEUE_CONSUMER_PC:
		return _fail("Preclear refused a queue release without the exact inherited/row receipt from $A03C.")
	return true


func _source_yield_metadata() -> Dictionary:
	return {
		"queue_writer_pc": QUEUE_WRITER_CPU_ADDRESS,
		"capacity_yield_call_pc": QUEUE_YIELD_CALL_PC,
		"capacity_yield_saved_return_word": QUEUE_YIELD_SAVED_RETURN_WORD,
		"capacity_resume_pc": QUEUE_YIELD_RESUME_PC,
		"row_caller_jsr_pc": ROW_CALLER_JSR_PC,
		"row_caller_saved_return_word": ROW_CALLER_SAVED_RETURN_WORD,
		"nmi_queue_consumer_pc": NMI_QUEUE_CONSUMER_PC,
		"scheduler_delay_argument": 1,
		"physical_nmi_cycle_phase_modeled": false,
	}


func _span_bytes(stream: PackedByteArray, spans: Array, name: String) -> PackedByteArray:
	for span_variant in spans:
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("name", "")) == name:
			var offset := int(span.get("combined_offset", -1))
			var length := int(span.get("byte_length", -1))
			if offset < 0 or length <= 0 or offset + length > stream.size():
				return PackedByteArray()
			return stream.slice(offset, offset + length)
	return PackedByteArray()


func _reset_run_state() -> void:
	state = State.READY if _configured else State.UNCONFIGURED
	error_message = ""
	event_id = ""
	event_index = -1
	source_cpu_address = -1
	source_helper_entry_pc = -1
	destination_ppu_base = -1
	row_count = 0
	row_bytes = 0
	start_source_frame = -1
	last_source_frame = -1
	live_brightness_counters = Vector2i.ZERO
	source_queue_cursor_at_start = -1
	queue_cursor_source = ""
	rows_staged = 0
	nmi_release_count = 0
	release_receipt_history.clear()
	_initial_action_consumed = false
	_expected_release_receipt.clear()
	_pending_receipt_kind = ""


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _hex_or_int(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	return str(value).strip_edges().trim_prefix("$").trim_prefix("0x").hex_to_int()


func _fail(message: String) -> bool:
	error_message = message
	state = State.FAILED
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	return _refused("failed")


func _refused(status: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error_message}
