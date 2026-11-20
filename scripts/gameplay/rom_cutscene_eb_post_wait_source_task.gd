extends RefCounted
class_name RomCutsceneEbPostWaitSourceTask
## ROM-derived model of EB's post-input `$85C3->$88B1->$98E8` clear.
## `$9B28` capacity checks determine the waits; no elapsed-frame delay is set.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/eb_post_wait_clear/"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const QUEUE_CAPACITY_CHECK_LIMIT := 0x3D
const SOURCE_ROW_COUNT := 8
const SOURCE_PACKET_HEADER_BYTES := 3
const SOURCE_YIELD_TICKS := 1
const EXPECTED_SPANS := {
	"bank00_85c3_85d2_eb_handler.bin": {
		"cpu_start": 0x85C3, "cpu_end_exclusive": 0x85D2, "file_offset": 0x05D3,
		"length": 15, "sha256": "1c1de2940440ee709001b996a3b5c762f1fc7d0ff72e98e8a6e10c0cb4e7637b",
	},
	"bank00_88b1_88ca_clear_geometry.bin": {
		"cpu_start": 0x88B1, "cpu_end_exclusive": 0x88CA, "file_offset": 0x08C1,
		"length": 25, "sha256": "79559e3af839e1d424f47ab56a63658ae7d2ea22fce9a621aa6f95b1c25f134d",
	},
	"bank00_98e8_992c_clear_queue_branch.bin": {
		"cpu_start": 0x98E8, "cpu_end_exclusive": 0x992C, "file_offset": 0x18F8,
		"length": 68, "sha256": "93a95cd78aef488fdbd2db75613e8a43ee127f7391cfa6c9580fe1dff8a41724",
	},
	"bank00_9b28_9b6f_queue_writer.bin": {
		"cpu_start": 0x9B28, "cpu_end_exclusive": 0x9B6F, "file_offset": 0x1B38,
		"length": 71, "sha256": "2ae1d070eb6fdb97902158ef4bf707c85606dc79d488134e922a65dacf837320",
	},
}

enum State {
	UNCONFIGURED,
	WAITING_FOR_CAPACITY_RELEASE,
	COMPLETED,
	FAILED,
}

var state: State = State.UNCONFIGURED
var error_message := ""
var event_index := -1
var source_cpu_address := -1
var source_rom_sha256 := ""
var start_source_frame := -1
var last_source_frame := -1
var source_clear_origin := -1
var source_queue_cursor_at_start := -1
var fill_width := -1
var row_count := -1
var capacity_release_count := 0
var capacity_release_count_required := 0
var final_queue_cursor := -1
var packet_batches: Array[Dictionary] = []
var _next_batch_index := 0
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	var manifest_path := SOURCE_ROOT + "manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return _fail("EB post-wait helper manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest_variant is Dictionary \
			or String(manifest_variant.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("EB post-wait helper manifest is malformed or targets another ROM.")
	var manifest_entries: Dictionary = {}
	for entry_variant in manifest_variant.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			manifest_entries[String(entry.get("file", ""))] = entry
	for file_name: String in EXPECTED_SPANS:
		var spec: Dictionary = EXPECTED_SPANS[file_name]
		if not manifest_entries.has(file_name):
			return _fail("EB post-wait helper manifest omits %s." % file_name)
		var entry: Dictionary = manifest_entries[file_name]
		if _hex_or_int(entry.get("cpu_start", -1)) != int(spec["cpu_start"]) \
				or _hex_or_int(entry.get("cpu_end_exclusive", -1)) != int(spec["cpu_end_exclusive"]) \
				or _hex_or_int(entry.get("file_offset", -1)) != int(spec["file_offset"]) \
				or int(entry.get("length", -1)) != int(spec["length"]) \
				or String(entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("EB post-wait helper manifest span differs for %s." % file_name)
		var source := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if source.size() != int(spec["length"]) or _sha256(source) != String(spec["sha256"]):
			return _fail("Packaged EB post-wait ROM bytes failed their size/hash check: %s." % file_name)
	_configured = true
	return true


## Begin after the VM observes a fresh A edge at an EB command. Geometry is
## derived from the active ROM dialog clear origin; fade counters select the
## queue branch, and the presenter supplies its live `$0628` queue cursor.
func begin(event: Dictionary, source_frame: int, fade_counters: Vector2i,
		clear_origin: int, queue_cursor: int) -> bool:
	_reset()
	if not _configured and not configure_from_project_sources():
		return false
	var raw_bytes: Array = event.get("raw_bytes", [])
	if String(event.get("kind", "")) != "wait_for_input" \
			or int(event.get("opcode", -1)) != 0xEB \
			or raw_bytes.size() != 1 or int(raw_bytes[0]) != 0xEB \
			or source_frame < 0:
		return _fail("EB post-wait source task requires the decoded ROM `$EB` command and a source frame.")
	if fade_counters.x <= 0 and fade_counters.y <= 0:
		return _fail("EB post-wait source task has no source-known fade counters for `$98E8` branch selection.")
	if clear_origin < 0x2000 or clear_origin >= 0x2800 or (clear_origin & 0x001F) >= 0x1F:
		return _fail("EB post-wait source task has an invalid dialog-clear origin.")
	if queue_cursor != 0:
		return _fail("EB post-wait helper needs a drained `$0628` cursor; runtime reports $%02X." % queue_cursor)
	if not _build_source_packet_batches(clear_origin):
		return false
	event_index = int(event.get("event_index", -1))
	source_cpu_address = int(event.get("cpu_address", -1))
	start_source_frame = source_frame
	last_source_frame = source_frame
	source_clear_origin = clear_origin
	source_queue_cursor_at_start = queue_cursor
	fill_width = _derive_fill_width(clear_origin & 0x001F)
	row_count = SOURCE_ROW_COUNT
	capacity_release_count = 0
	capacity_release_count_required = maxi(0, packet_batches.size() - 1)
	final_queue_cursor = int(packet_batches.back().get("queue_cursor_bytes", -1))
	_next_batch_index = 1
	state = State.WAITING_FOR_CAPACITY_RELEASE if capacity_release_count_required > 0 else State.COMPLETED
	return true


## Stage the initial source queue records in the same source tick as the A edge.
func get_initial_packet_batch() -> Dictionary:
	if packet_batches.is_empty():
		return {}
	return packet_batches[0].duplicate(true)


## One call represents a `$9FA8` one-tick wait released after the prior queue
## batch was drained by the next modeled NMI. Batch count is calculated from
## ROM `$9B28`'s `$0628 + payload >= $3D` test.
func advance_source_tick(source_frame: int) -> Dictionary:
	if state != State.WAITING_FOR_CAPACITY_RELEASE:
		return _refused("task_not_waiting")
	if source_frame <= last_source_frame:
		return _fail_result("EB post-wait task source ticks must advance monotonically.")
	last_source_frame = source_frame
	capacity_release_count += SOURCE_YIELD_TICKS
	var released_batch_index := _next_batch_index
	var batch: Dictionary = packet_batches[released_batch_index].duplicate(true)
	_next_batch_index += 1
	var returned := capacity_release_count >= capacity_release_count_required
	if returned:
		state = State.COMPLETED
	return {
		"ok": true,
		"status": "task_returned" if returned else "packet_batch_released",
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"source_frame": source_frame,
		"batch_index": int(batch.get("batch_index", -1)),
		"rows": batch.get("rows", []).duplicate(true),
		"queue_cursor_bytes": int(batch.get("queue_cursor_bytes", -1)),
		"capacity_release_count": capacity_release_count,
		"capacity_release_count_required": capacity_release_count_required,
		"source_rom_sha256": SOURCE_ROM_SHA256,
	}


func get_status() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"event_index": event_index,
		"source_cpu_address": source_cpu_address,
		"start_source_frame": start_source_frame,
		"last_source_frame": last_source_frame,
		"source_clear_origin": source_clear_origin,
		"source_queue_cursor_at_start": source_queue_cursor_at_start,
		"fill_width": fill_width,
		"row_count": row_count,
		"capacity_batch_count": packet_batches.size(),
		"capacity_release_count": capacity_release_count,
		"capacity_release_count_required": capacity_release_count_required,
		"final_queue_cursor": final_queue_cursor,
		"next_batch_index": _next_batch_index,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_span_sha256": _source_span_hashes(),
		"frame_level_scheduler_phase_modeled": false,
		"error": error_message,
	}


func _build_source_packet_batches(clear_origin: int) -> bool:
	var low_address := (clear_origin & 0x00E0) | (clear_origin & 0x001F)
	var high_address := (clear_origin >> 8) & 0xFF
	var width := _derive_fill_width(clear_origin & 0x001F)
	if width <= 0 or width > 0x3C:
		return _fail("EB post-wait source geometry produces an unsupported row width.")
	var batches: Array[Dictionary] = []
	var rows: Array[Dictionary] = []
	var queue_cursor := 0
	var batch_index := 0
	for row_index in SOURCE_ROW_COUNT:
		if queue_cursor + width >= QUEUE_CAPACITY_CHECK_LIMIT and not rows.is_empty():
			batches.append(_make_packet_batch(batch_index, rows, queue_cursor))
			batch_index += 1
			rows = []
			queue_cursor = 0
		var address := high_address * 0x100 + low_address + row_index * 0x20
		rows.append({
			"row_index": row_index,
			"ppu_address": address,
			"payload_size": width,
			"value": 0,
			"source_pc": 0x9901,
			"packet_source_pc": 0x9B57,
			"terminator_source_pc": 0x9B5E,
		})
		queue_cursor += width + SOURCE_PACKET_HEADER_BYTES
	if not rows.is_empty():
		batches.append(_make_packet_batch(batch_index, rows, queue_cursor))
	if batches.is_empty() or batches.back().get("rows", []).size() <= 0:
		return _fail("EB post-wait source geometry produced no `$9B28` packet batches.")
	for derived_batch_index in batches.size():
		var batch: Dictionary = batches[derived_batch_index]
		batch["drained_before_next_batch"] = derived_batch_index < batches.size() - 1
		batches[derived_batch_index] = batch
	packet_batches = batches
	return true


func _make_packet_batch(batch_index: int, rows: Array[Dictionary], queue_cursor: int) -> Dictionary:
	return {
		"batch_index": batch_index,
		"rows": rows.duplicate(true),
		"queue_cursor_bytes": queue_cursor,
		"queue_buffer_capacity_bytes": 0x40,
		"queue_cursor_limit": QUEUE_CAPACITY_CHECK_LIMIT,
		"drained_before_next_batch": false,
	}


func _derive_fill_width(source_right_edge: int) -> int:
	# ROM `$88B1`: EOR #$FF; CLC; ADC #$1F => `$1E - $54` modulo 256.
	return (0x1E - source_right_edge) & 0xFF


func _source_span_hashes() -> Dictionary:
	var result: Dictionary = {}
	for file_name: String in EXPECTED_SPANS:
		result[file_name] = EXPECTED_SPANS[file_name]["sha256"]
	return result


func _reset() -> void:
	state = State.UNCONFIGURED
	error_message = ""
	event_index = -1
	source_cpu_address = -1
	start_source_frame = -1
	last_source_frame = -1
	source_clear_origin = -1
	source_queue_cursor_at_start = -1
	fill_width = -1
	row_count = -1
	capacity_release_count = 0
	capacity_release_count_required = 0
	final_queue_cursor = -1
	packet_batches.clear()
	_next_batch_index = 0


func _hex_or_int(value: Variant) -> int:
	if value is int:
		return int(value)
	var text := String(value).strip_edges().trim_prefix("$").trim_prefix("0x")
	return int(text.hex_to_int())


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
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
