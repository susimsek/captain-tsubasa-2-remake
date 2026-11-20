extends SceneTree
## Focused source check for FA $0F's $9B28 capacity wait and NMI release API.

const TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_background_source_task.gd")
const PACKET_LOADER_SCRIPT := preload("res://scripts/opening/rom_background_packet_loader.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const BG_ID := 0x0F
const EVENT_INDEX := 1
const EVENT_CPU := 0xBFBC
const EVENT_FILE := 0x00BFCC
const RECORD_CPU := 0xA294
const RECORD_FILE := 0x00E2A4
const RECORD_PATH := "res://reference/rom_extract/gameplay/backgrounds/background_0F.bin"
const DATA_ROOT := "res://reference/rom_extract/gameplay/backgrounds"
const SCENE56_MANIFEST_PATH := "res://assets/gameplay/rom_logic/kickoff_meeting_scene_56_events.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	var loader: Variant = PACKET_LOADER_SCRIPT.new()
	if not loader.build_packets(BG_ID, DATA_ROOT):
		_fail("ROM-derived FA $0F packet loader failed: " + String(loader.last_error))
		return
	if loader.packets.size() != 40 or int(loader.encoded_packet_byte_count) != 256:
		_fail("FA $0F must decode to 40 packets / 256 queue bytes.")
		return
	var record_bytes := FileAccess.get_file_as_bytes(RECORD_PATH)
	if record_bytes.size() != 16:
		_fail("The preserved bank-7 FA $0F descriptor is not 16 bytes.")
		return
	if not _verify_production_manifest_input(loader.packets, record_bytes):
		return

	var first_task: Variant = TASK_SCRIPT.new()
	var first_receipt := _make_load_receipt(loader.packets, record_bytes, 0)
	if not first_task.begin(_make_event(), 8000, first_receipt):
		_fail("FA $0F task rejected ROM bytes/live cursor: " + String(first_task.error_message))
		return
	var initial: Dictionary = first_task.get_initial_queue_segment()
	if int(first_task.get_status().get("capacity_segment_count", -1)) != 5 \
			or int(first_task.get_status().get("capacity_boundary_count_required", -1)) != 4 \
			or int(initial.get("packet_count", -1)) != 9 \
			or int(initial.get("queue_cursor_bytes", -1)) != 57 \
			or int(initial.get("serialized_queue_byte_count", -1)) != 57 \
			or initial.get("must_yield_at_capacity", false) != true:
		_fail("Zero-cursor FA $0F queue segments differ from the ROM capacity condition.")
		return
	var cursor_counts := PackedInt32Array([57])
	var packet_counts := PackedInt32Array([9])
	for segment_index in range(1, 5):
		var segment: Dictionary = first_task._capacity_segments[segment_index]
		cursor_counts.append(int(segment.get("queue_cursor_bytes", -1)))
		packet_counts.append(int(segment.get("packet_count", -1)))
	if cursor_counts != PackedInt32Array([57, 57, 57, 57, 28]) \
			or packet_counts != PackedInt32Array([9, 9, 9, 9, 4]):
		_fail("FA $0F packet segmentation is not four $9B28 waits followed by a final 4-packet run.")
		return
	var tick_attempt: Dictionary = first_task.advance_source_tick(8001)
	if bool(tick_attempt.get("ok", true)) \
			or String(tick_attempt.get("status", "")) != "fa_0f_requires_source_nmi_release_receipt":
		_fail("FA $0F incorrectly advanced on a Godot/source-frame tick.")
		return

	var task_returned := false
	for segment_index in range(4):
		var expected_segment: Dictionary = first_task._capacity_segments[segment_index]
		var receipt := _make_source_receipt(first_task, expected_segment, segment_index, 8100 + segment_index)
		var advanced: Dictionary = first_task.advance_after_nmi_release(receipt)
		if not bool(advanced.get("ok", false)):
			_fail("FA $0F rejected source-owned NMI release %d: %s" % [segment_index, str(advanced)])
			return
		if advanced.get("released_segment", {}) != expected_segment:
			_fail("FA $0F did not report the segment committed by this NMI release.")
			return
		if segment_index < 3:
			if String(advanced.get("status", "")) != "packet_batch_released" \
					or int(advanced.get("next_queue_segment", {}).get("segment_index", -1)) != segment_index + 1:
				_fail("FA $0F did not continue to the next ROM packet segment after NMI release.")
				return
		else:
			var final_segment: Dictionary = advanced.get("next_queue_segment", {})
			if String(advanced.get("status", "")) != "task_returned" \
					or int(final_segment.get("segment_index", -1)) != 4 \
					or int(final_segment.get("packet_count", -1)) != 4 \
					or bool(final_segment.get("must_yield_at_capacity", true)):
				_fail("FA $0F did not return after staging its final, non-yielding packet run.")
				return
			task_returned = true
	if not task_returned or String(first_task.get_status().get("state", "")) != "completed":
		_fail("FA $0F did not complete after four ROM-backed NMI queue releases.")
		return

	if not _verify_generic_inherited_queue_release(loader.packets, record_bytes):
		return
	if not _verify_rejections(loader.packets, record_bytes):
		return
	print("PASS: FA $0F stages 40 ROM-derived packets in four $9B28 capacity waits plus a final run; no Godot tick is used as a release.")
	quit(0)


func _verify_production_manifest_input(packets: Array, record_bytes: PackedByteArray) -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCENE56_MANIFEST_PATH))
	if not parsed is Dictionary:
		_fail("Production scene-$56 event manifest could not be parsed.")
		return false
	var events: Array = parsed.get("events", [])
	if events.size() <= EVENT_INDEX or not events[EVENT_INDEX] is Dictionary:
		_fail("Production scene-$56 manifest lacks its FA $0F event.")
		return false
	var loader: Variant = PACKET_LOADER_SCRIPT.new()
	if not loader.build_packets(BG_ID, DATA_ROOT):
		_fail("Production FA $0F packet loader failed: " + String(loader.last_error))
		return false
	var source_event: Dictionary = events[EVENT_INDEX]
	var capacity: Dictionary = TASK_SCRIPT.derive_capacity_segments(packets, 0)
	var source_receipt := {
		"ok": true,
		"source_rom_sha256": ROM_SHA256,
		"event_index": int(source_event.get("event_index", -1)),
		"background_id": BG_ID,
		"record_cpu_address": RECORD_CPU,
		"record_file_offset": RECORD_FILE,
		"record_bytes": record_bytes,
		"source_packet_stream": packets.duplicate(true),
		"packet_count": packets.size(),
		"capacity_batch_count": capacity.get("segments", []).size(),
		"queue_cursor_limit": 0x3D,
		"source_queue_cursor_0628": 0,
		"source_queue_cursor_source": "rom_derived_presenter_state",
	}
	var task: Variant = TASK_SCRIPT.new()
	if not task.begin(source_event, 8000, source_receipt):
		_fail("Production JSON event/raw-byte types failed the FA $0F source check: " + String(task.error_message))
		return false
	return true


func _verify_generic_inherited_queue_release(packets: Array, record_bytes: PackedByteArray) -> bool:
	var task: Variant = TASK_SCRIPT.new()
	var receipt := _make_load_receipt(packets, record_bytes, 0x3C)
	if not task.begin(_make_event(), 8200, receipt):
		_fail("FA $0F did not accept a live cursor at $3C: " + String(task.error_message))
		return false
	var flush: Dictionary = task.get_initial_queue_segment()
	if not bool(flush.get("flush_existing_queue", false)) or int(flush.get("packet_count", -1)) != 0:
		_fail("A pre-existing queue at cursor $3C did not produce an anonymous flush segment.")
		return false
	var generic_receipt := {
		"ok": true,
		"event_id": "",
		"batch_index": -1,
		"queue_cursor_before": 0x3C,
		"queued_bytes": 0x3C,
		"committed_bytes": 0x3C,
		"queue_cursor_after": 0,
		"nmi_consumer_pc": 0xA03C,
		"source_frame": 8201,
	}
	var advanced: Dictionary = task.advance_after_nmi_release(generic_receipt)
	if not bool(advanced.get("ok", false)) \
			or int(advanced.get("next_queue_segment", {}).get("segment_index", -1)) != 1:
		_fail("FA $0F rejected the generic drain for inherited queue bytes: " + str(advanced))
		return false
	var bad_owned_generic := generic_receipt.duplicate(true)
	bad_owned_generic["source_frame"] = 8202
	var rejected: Dictionary = task.advance_after_nmi_release(bad_owned_generic)
	if bool(rejected.get("ok", true)):
		_fail("FA $0F accepted a generic inherited drain in place of a task-owned packet receipt.")
		return false
	return true


func _verify_rejections(packets: Array, record_bytes: PackedByteArray) -> bool:
	var task: Variant = TASK_SCRIPT.new()
	if not task.begin(_make_event(), 8300, _make_load_receipt(packets, record_bytes, 0)):
		_fail("FA $0F rejection fixture could not initialize.")
		return false
	var expected_segment: Dictionary = task._capacity_segments[0]
	var wrong_receipt := _make_source_receipt(task, expected_segment, 1, 8301)
	var wrong_event: Dictionary = task.advance_after_nmi_release(wrong_receipt)
	if bool(wrong_event.get("ok", true)):
		_fail("FA $0F accepted a receipt for the wrong segment index.")
		return false
	wrong_receipt = _make_source_receipt(task, expected_segment, 0, 8301)
	wrong_receipt["committed_ppu_writes"] = []
	var wrong_writes: Dictionary = task.advance_after_nmi_release(wrong_receipt)
	if bool(wrong_writes.get("ok", true)):
		_fail("FA $0F accepted an NMI receipt with mismatched PPU writes.")
		return false
	return true


func _make_event() -> Dictionary:
	return {
		"kind": "background_2",
		"opcode": 0xFA,
		"id": BG_ID,
		"event_index": EVENT_INDEX,
		"cpu_address": EVENT_CPU,
		"file_offset": EVENT_FILE,
		"raw_bytes": [0xFA, BG_ID],
		"arguments": [BG_ID],
	}


func _make_load_receipt(packets: Array, record_bytes: PackedByteArray, live_cursor: int) -> Dictionary:
	var segment_result: Dictionary = TASK_SCRIPT.derive_capacity_segments(packets, live_cursor)
	return {
		"ok": true,
		"source_rom_sha256": ROM_SHA256,
		"event_index": EVENT_INDEX,
		"background_id": BG_ID,
		"record_cpu_address": RECORD_CPU,
		"record_file_offset": RECORD_FILE,
		"record_bytes": record_bytes,
		"source_packet_stream": packets.duplicate(true),
		"packet_count": packets.size(),
		"capacity_batch_count": segment_result.get("segments", []).size(),
		"queue_cursor_limit": 0x3D,
		"source_queue_cursor_0628": live_cursor,
		"source_queue_cursor_source": "rom_derived_presenter_state",
	}


func _make_source_receipt(task: Variant, segment: Dictionary, segment_index: int,
		source_frame: int) -> Dictionary:
	return {
		"ok": true,
		"kind": "rom_cutscene_background_nmi_queue_release",
		"source_rom_sha256": ROM_SHA256,
		"event_index": task.event_index,
		"source_cpu_address": task.source_cpu_address,
		"background_id": BG_ID,
		"segment_index": segment_index,
		"segment": segment.duplicate(true),
		"queue_cursor_before": int(segment.get("queue_cursor_bytes", -1)),
		"queue_cursor_after": 0,
		"queue_drained": true,
		"consumer_source_pc": 0xA03C,
		"serialized_queue_byte_count": int(segment.get("serialized_queue_byte_count", -1)),
		"committed_ppu_writes": segment.get("ppu_writes", []).duplicate(true),
		"source_yield": {
			"writer_pc": 0x9B28,
			"yield_site_pc": 0x9B2E,
			"yield_call_pc": 0x9B30,
			"saved_return_word": 0x9B32,
			"resume_pc": 0x9B33,
			"caller_saved_return_word": 0x8F46,
			"caller_resume_pc": 0x8F47,
		},
		"nmi_sequence": segment_index,
		"source_frame": source_frame,
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
