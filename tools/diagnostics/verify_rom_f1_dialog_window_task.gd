extends SceneTree

const WINDOW_TASK := preload("res://scripts/gameplay/rom_f1_dialog_window_task.gd")
const SCENE56_MANIFEST_PATH := "res://assets/gameplay/rom_logic/kickoff_meeting_scene_56_events.json"

var _failures := 0


func _initialize() -> void:
	var task: Variant = WINDOW_TASK.new()
	_check(task.configure_from_project_sources(), "F1 02 stream, manifest, and four $BBE8 records validate")
	var event := {
		"kind": "dialog_window",
		"opcode": 0xF1,
		"arguments": [0x02],
		"raw_bytes": [0xF1, 0x02],
		"event_index": 0,
		"cpu_address": 0xBFBA,
	}
	_check(task.begin(event, 0x56, 7994, Vector2i(0x0F, 0x0F), 0x23),
		"scene-$56 F1 02 enters the buffered queue branch from live input state")
	if not task.error_message.is_empty():
		printerr("F1 02 task begin error: " + task.error_message)
	var initial: Dictionary = task.get_initial_action()
	var inherited_expectation: Dictionary = initial.get("release_receipt_expectation", {})
	_check(String(initial.get("status", "")) == "wait_for_inherited_queue_release"
		and String(inherited_expectation.get("event_id", "not-empty")) == ""
		and int(inherited_expectation.get("batch_index", -999)) == -1
		and int(inherited_expectation.get("queue_cursor_before", -1)) == 0x23,
		"the pre-existing $05E8 queue is drained under the unowned receipt sentinel")
	var receipt := _release_receipt(inherited_expectation, 7995)
	var first_batch_result: Dictionary = task.advance_source_tick(7995, receipt)
	var first_batch: Dictionary = first_batch_result.get("batch", {})
	_check(String(first_batch_result.get("status", "")) == "batch_staged_waiting_for_nmi"
		and int(first_batch.get("batch_index", -1)) == 0
		and int(first_batch.get("queue_cursor_before", -1)) == 0
		and int(first_batch.get("queued_bytes", -1)) == 33,
		"the first 30-byte clear row is queued after the inherited drain")

	var staged_batches: Array[Dictionary] = [first_batch]
	var source_frame := 7995
	while String(task.get_status().get("state", "")) == "waiting_for_batch_release":
		var expected: Dictionary = task.get_status().get("expected_release_receipt", {})
		source_frame += 1
		var next: Dictionary = task.advance_source_tick(source_frame,
			_release_receipt(expected, source_frame))
		if not bool(next.get("ok", false)):
			_check(false, "source NMI release advances the next F1 batch")
			break
		staged_batches.append(next.get("batch", {}).duplicate(true))
	_check(staged_batches.size() == 13
		and String(task.get_status().get("state", "")) == "completed",
		"eleven clear rows plus four table records stage in 13 ROM-capacity batches")
	if staged_batches.size() == 13:
		var final_batch: Dictionary = staged_batches.back()
		var final_packets: Array = final_batch.get("packets", [])
		_check(final_packets.size() == 3
			and int(final_packets[0].get("record_index", -1)) == 1
			and int(final_packets[1].get("record_index", -1)) == 2
			and int(final_packets[2].get("record_index", -1)) == 3
			and int(final_batch.get("queue_cursor_after_staging", -1)) == 57,
			"the 30-byte row plus both 9-byte records fit in the final 57-byte queue batch")
		var final_record: Dictionary = final_packets.back()
		_check(bool(final_record.get("final", false))
			and int(final_record.get("ppu_address", -1)) == 0x225E
			and int(final_record.get("increment", -1)) == 32,
			"the final ROM record retains its marker, $225E destination, and increment-32 flag")
	
	var rejected_task: Variant = WINDOW_TASK.new()
	_check(rejected_task.configure_from_project_sources()
		and rejected_task.begin(event, 0x56, 7994, Vector2i(0x0F, 0x0F), 0x23),
		"invalid receipt fixture starts from the same source state")
	var rejected_initial: Dictionary = rejected_task.get_initial_action()
	var rejected: Dictionary = rejected_task.advance_source_tick(7995, {
		"ok": true, "event_id": "wrong", "batch_index": -1,
		"queue_cursor_before": 0x23, "queued_bytes": 0x23,
		"committed_bytes": 0x23, "queue_cursor_after": 0,
		"nmi_consumer_pc": 0xA000, "source_frame": 7995,
	})
	_check(not bool(rejected.get("ok", false)),
		"queue release cannot be accepted without the expected event/batch identity")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCENE56_MANIFEST_PATH))
	var scene56_events: Array = parsed.get("events", []) if parsed is Dictionary else []
	var runtime_task: Variant = WINDOW_TASK.new()
	var runtime_event: Dictionary = scene56_events[0] if not scene56_events.is_empty() else {}
	_check(scene56_events.size() > 0 and runtime_task.begin(runtime_event, 0x56,
		7994, Vector2i(0x0F, 0x0F), 0),
		"production scene-$56 JSON byte types enter the F1 02 source task")

	if _failures == 0:
		print("PASS: F1 02 ROM records, buffered queue batching, and source $A000 release receipts.")
		print("LIMIT: the production route must provide the live counters/cursor and actual presenter NMI receipts; physical PPU-cycle timing remains separate.")
	else:
		printerr("FAIL: %d F1 02 dialog-window task assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _release_receipt(expectation: Dictionary, source_frame: int) -> Dictionary:
	var receipt := expectation.duplicate(true)
	receipt["ok"] = true
	receipt["source_frame"] = source_frame
	return receipt


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + label)
