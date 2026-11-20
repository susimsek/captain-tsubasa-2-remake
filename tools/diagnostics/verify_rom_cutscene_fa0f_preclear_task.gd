extends SceneTree
## Focused ROM/source-and-receipt verifier for the scene-$56 FA $0F row preclear.

const TASK_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_fa0f_preclear_task.gd")
const EVENT_MANIFEST_PATH := "res://assets/gameplay/rom_logic/kickoff_meeting_scene_56_events.json"
const SOURCE_MANIFEST_PATH := "res://assets/gameplay/rom_logic/fa_0f_preclear_sources.json"
const SOURCE_STREAM_PATH := "res://assets/gameplay/rom_logic/fa_0f_preclear_sources.bin"
const TRACE_RAM_ROOT := "res://reference/diagnostics/kickoff_select_test_20261027/ram"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EVENT_INDEX := 1

var _next_fixture_frame := 1000


func _initialize() -> void:
	_run()


func _run() -> void:
	if not _verify_packaged_sources():
		return
	var event := _load_event()
	if event.is_empty():
		return
	if not _verify_helper_paths_and_row_sequence(event):
		return
	if not _verify_capacity_boundaries(event):
		return
	if not _verify_receipt_rejections(event):
		return
	if not _verify_retained_trace_context():
		return
	print("PASS: FA $0F preclear decodes 16 ROM-sized zero rows; source waits resume only on matching $A03C receipts, with no frame-delay model.")
	quit(0)


func _verify_packaged_sources() -> bool:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_MANIFEST_PATH))
	if not manifest is Dictionary \
			or String(manifest.get("schema", "")) != "ct2-scene-56-fa-0f-preclear-source-v1" \
			or String(manifest.get("rom", {}).get("sha256", "")) != ROM_SHA256:
		_fail("FA $0F source manifest does not pin the supplied Turkish ROM revision.")
		return false
	var stream := FileAccess.get_file_as_bytes(SOURCE_STREAM_PATH)
	if stream.size() != 365 or _sha256(stream) != "208e9658ca12e3c21c26dfa418bf7a08607d4d997797be760b8affc563681c35":
		_fail("FA $0F packaged runtime source stream failed length/hash validation.")
		return false
	var task: Variant = TASK_SCRIPT.new()
	if not task.configure_from_project_sources():
		_fail("FA $0F task rejected its packaged ROM-derived spans: " + String(task.error_message))
		return false
	return true


func _load_event() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENT_MANIFEST_PATH))
	if not parsed is Dictionary or String(parsed.get("source_rom_sha256", "")) != ROM_SHA256:
		_fail("Scene-$56 event manifest is missing or points to a different ROM.")
		return {}
	var events: Array = parsed.get("events", [])
	if events.size() <= EVENT_INDEX or not events[EVENT_INDEX] is Dictionary:
		_fail("Scene-$56 event manifest has no FA $0F event at index 1.")
		return {}
	var event: Dictionary = events[EVENT_INDEX]
	if String(event.get("kind", "")) != "background_2" \
			or int(event.get("opcode", -1)) != 0xFA \
			or int(event.get("id", -1)) != 0x0F \
			or int(event.get("cpu_address", -1)) != 0xBFBC \
			or int(event.get("file_offset", -1)) != 0x00BFCC:
		_fail("Scene-$56 event index 1 is not the byte-checked bank-5 `$BFBC` FA $0F command.")
		return {}
	var raw_bytes: Array = event.get("raw_bytes", [])
	if raw_bytes.size() != 2 or int(raw_bytes[0]) != 0xFA or int(raw_bytes[1]) != 0x0F:
		_fail("Scene-$56 event index 1 has the wrong FA $0F source bytes.")
		return {}
	return event


func _verify_helper_paths_and_row_sequence(event: Dictionary) -> bool:
	for helper_case in [
		{"pc": 0x9071, "base": 0x2000},
		{"pc": 0x9076, "base": 0x2400},
	]:
		var task: Variant = TASK_SCRIPT.new()
		if not task.begin(event, 0x56, _next_frame(), int(helper_case.pc),
				Vector2i(0x0F, 0x0F), 0x39, "rom_derived_presenter_state"):
			_fail("Preclear task rejected source inputs for helper $%04X: %s" % [
				int(helper_case.pc), String(task.error_message)])
			return false
		var flush: Dictionary = task.get_initial_action()
		if String(flush.get("status", "")) != "wait_for_inherited_queue_release":
			_fail("Cursor $39 must wait for the inherited queue before the first 32-byte row.")
			return false
		var expected_flush: Dictionary = flush.get("release_receipt_expectation", {})
		if expected_flush != {
			"event_id": "",
			"batch_index": -1,
			"queue_cursor_before": 0x39,
			"queued_bytes": 0x39,
			"committed_bytes": 0x39,
			"queue_cursor_after": 0,
			"nmi_consumer_pc": 0xA03C,
		}:
			_fail("Inherited drain receipt differs from the unowned queue contract.")
			return false
		var flush_release_frame := _next_frame()
		var row_action: Dictionary = task.advance_after_nmi_release(flush_release_frame, _receipt(expected_flush, flush_release_frame))
		if not bool(row_action.get("ok", false)):
			_fail("Preclear task rejected valid inherited release: " + str(row_action))
			return false
		if not _verify_all_rows_after_first(task, row_action, int(helper_case.base)):
			return false
	return true


func _verify_all_rows_after_first(task: Variant, first_action: Dictionary, base_address: int) -> bool:
	var action := first_action
	for row_index in 16:
		var status := String(action.get("status", ""))
		if status != ("task_returned" if row_index == 15 else "row_staged_waiting_for_capacity_release"):
			_fail("Preclear row %d returned unexpected action status `%s`." % [row_index, status])
			return false
		var batch: Dictionary = action.get("batch", {})
		var payload: PackedByteArray = batch.get("payload", PackedByteArray())
		if String(batch.get("task_kind", "")) != "fa_0f_preclear" \
				or int(batch.get("batch_index", -1)) != row_index \
				or int(batch.get("row_index", -1)) != row_index \
				or int(batch.get("source_helper_entry_pc", -1)) != task.source_helper_entry_pc \
				or int(batch.get("ppu_address", -1)) != base_address + row_index * 0x20 \
				or int(batch.get("payload_size", -1)) != 32 \
				or payload.size() != 32 or not _all_zero(payload) \
				or int(batch.get("queue_encoded_bytes", -1)) != 35 \
				or int(batch.get("queue_cursor_after_staging", -1)) != 35 \
				or batch.get("packets", []).size() != 1 \
				or batch.get("ppu_writes", []).size() != 32:
			_fail("Preclear row %d does not match the ROM-derived 16x32 packet model." % row_index)
			return false
		var expected_cursor := 0 if row_index > 0 else 0
		if int(batch.get("queue_cursor_before", -1)) != expected_cursor:
			_fail("Preclear row %d did not resume on the drained queue cursor." % row_index)
			return false
		if row_index == 15:
			if not task.get_status().get("state", "") == "completed" \
					or int(task.get_status().get("rows_staged", -1)) != 16 \
					or int(task.get_status().get("nmi_release_count", -1)) != 16:
				_fail("Task must return after staging row 15, without waiting for its final NMI commit.")
				return false
			if int(action.get("next_source_pc", -1)) != 0x8BAE:
				_fail("Final clear helper return must converge on the separate `$8BAE` wait.")
			return true
		var expectation: Dictionary = batch.get("release_receipt_expectation", {})
		if int(expectation.get("batch_index", -1)) != row_index \
				or int(expectation.get("queue_cursor_before", -1)) != 0 \
				or int(expectation.get("queued_bytes", -1)) != 35 \
				or int(expectation.get("committed_bytes", -1)) != 35 \
				or int(expectation.get("queue_cursor_after", -1)) != 0 \
				or int(expectation.get("nmi_consumer_pc", -1)) != 0xA03C:
			_fail("Row %d did not expose the exact queue drain receipt contract." % row_index)
			return false
		var row_release_frame := _next_frame()
		action = task.advance_after_nmi_release(row_release_frame, _receipt(expectation, row_release_frame))
		if not bool(action.get("ok", false)):
			_fail("Preclear task rejected row-%d queue receipt: %s" % [row_index, str(action)])
			return false
	return false


func _verify_capacity_boundaries(event: Dictionary) -> bool:
	var below: Variant = TASK_SCRIPT.new()
	if not below.begin(event, 0x56, _next_frame(), 0x9071,
			Vector2i(1, 0), 0x1C, "rom_derived_presenter_state"):
		_fail("Preclear rejected the valid $1C capacity-edge cursor: " + String(below.error_message))
		return false
	var below_action: Dictionary = below.get_initial_action()
	if String(below_action.get("status", "")) != "row_staged_waiting_for_capacity_release" \
			or int(below_action.get("batch", {}).get("queue_cursor_after_staging", -1)) != 0x3F:
		_fail("ROM's payload-only threshold should accept cursor $1C and serialize through cursor $3F.")
		return false
	var at_limit: Variant = TASK_SCRIPT.new()
	if not at_limit.begin(event, 0x56, _next_frame(), 0x9071,
			Vector2i(1, 0), 0x1D, "rom_derived_presenter_state"):
		_fail("Preclear rejected valid cursor $1D: " + String(at_limit.error_message))
		return false
	var at_limit_action: Dictionary = at_limit.get_initial_action()
	if String(at_limit_action.get("status", "")) != "wait_for_inherited_queue_release":
		_fail("ROM $9B28 must yield at cursor $1D because $1D + $20 reaches $3D.")
		return false
	return true


func _verify_receipt_rejections(event: Dictionary) -> bool:
	var task: Variant = TASK_SCRIPT.new()
	if not task.begin(event, 0x56, _next_frame(), 0x9076,
			Vector2i(1, 1), 0x39, "rom_derived_presenter_state"):
		_fail("Receipt rejection fixture failed to initialize.")
		return false
	var initial: Dictionary = task.get_initial_action()
	var expected: Dictionary = initial.get("release_receipt_expectation", {}).duplicate(true)
	var bad_pc := _receipt(expected, _next_fixture_frame)
	bad_pc["nmi_consumer_pc"] = 0xA000
	var rejected_pc: Dictionary = task.advance_after_nmi_release(_next_frame(), bad_pc)
	if bool(rejected_pc.get("ok", true)):
		_fail("Preclear accepted `$A000` in place of the observed `$A03C` consumer PC.")
		return false
	var bad_event: Variant = TASK_SCRIPT.new()
	if not bad_event.begin(event, 0x56, _next_frame(), 0x9076,
			Vector2i(1, 1), 0, "rom_derived_presenter_state"):
		_fail("Bad-event fixture failed to initialize.")
		return false
	var row: Dictionary = bad_event.get_initial_action()
	var row_receipt: Dictionary = _receipt(row.get("batch", {}).get("release_receipt_expectation", {}), _next_fixture_frame)
	row_receipt["event_id"] = "wrong_event"
	var rejected_event: Dictionary = bad_event.advance_after_nmi_release(_next_frame(), row_receipt)
	if bool(rejected_event.get("ok", true)):
		_fail("Preclear accepted a row release receipt for another source event.")
		return false
	var direct: Variant = TASK_SCRIPT.new()
	if direct.begin(event, 0x56, _next_frame(), 0x9071,
			Vector2i.ZERO, 0, "rom_derived_presenter_state"):
		_fail("Preclear accepted the unsupported direct-PPU branch with $4A|$4B == 0.")
		return false
	return true


func _verify_retained_trace_context() -> bool:
	var frame_8006 := _load_trace_ram(8006)
	var frame_8007 := _load_trace_ram(8007)
	var frame_8021 := _load_trace_ram(8021)
	var frame_8022 := _load_trace_ram(8022)
	if frame_8006.size() != 0x800 or frame_8007.size() != 0x800 \
			or frame_8021.size() != 0x800 or frame_8022.size() != 0x800:
		_fail("Retained scene-$56 RAM captures for the preclear wait boundary are missing.")
		return false
	if int(frame_8006[0x0628]) != 0x39 or int(frame_8006[0x004A]) != 0x0F \
			or int(frame_8006[0x004B]) != 0x0F:
		_fail("Frame-8006 trace cursor/counters differ from the recorded scene-$56 preclear entry context.")
		return false
	if not _contains_pair(frame_8006, 0x0100, 0x0200, [0x32, 0x9B]) \
			or not _contains_pair(frame_8006, 0x0100, 0x0200, [0xFE, 0x98]) \
			or not _contains_pair(frame_8007, 0x0100, 0x0200, [0x32, 0x9B]) \
			or not _contains_pair(frame_8007, 0x0100, 0x0200, [0xFE, 0x98]) \
			or not _contains_pair(frame_8021, 0x0100, 0x0200, [0x32, 0x9B]) \
			or not _contains_pair(frame_8021, 0x0100, 0x0200, [0xFE, 0x98]):
		_fail("Retained frames 8006-8021 no longer show nested `$9B32`/`$98FE` saved returns.")
		return false
	if _contains_pair(frame_8022, 0x0100, 0x0200, [0x32, 0x9B]) \
			or _contains_pair(frame_8022, 0x0100, 0x0200, [0xFE, 0x98]):
		_fail("Frame 8022 still contains the preclear suspended return pair; expected the recorded boundary transition.")
		return false
	return true


func _load_trace_ram(frame: int) -> PackedByteArray:
	var path := "%s/route_frame_%06d.bin" % [TRACE_RAM_ROOT, frame]
	return FileAccess.get_file_as_bytes(path)


func _contains_pair(bytes: PackedByteArray, start: int, end: int, pair: Array[int]) -> bool:
	for offset in range(start, end - pair.size() + 1):
		var matches := true
		for index in pair.size():
			if int(bytes[offset + index]) != pair[index]:
				matches = false
				break
		if matches:
			return true
	return false


func _all_zero(bytes: PackedByteArray) -> bool:
	for value in bytes:
		if int(value) != 0:
			return false
	return true


func _receipt(expectation: Dictionary, source_frame: int) -> Dictionary:
	var receipt := expectation.duplicate(true)
	receipt["ok"] = true
	receipt["source_frame"] = source_frame
	return receipt


func _next_frame() -> int:
	var value := _next_fixture_frame
	_next_fixture_frame += 1
	return value


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
