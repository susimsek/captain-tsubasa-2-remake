extends SceneTree

const PRODUCER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_animation_chr_shadow_producer.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var producer: Variant = PRODUCER_SCRIPT.new()
	if not producer.configure_from_project_sources():
		_fail("Animation CHR-shadow producer did not configure: " + producer.error_message)
		_quit()
		return
	var event := {
		"kind": "animations", "opcode": 0xFB,
		"arguments": [1, 0x51], "animation_ids": [0x51],
		"event_index": 51, "cpu_address": 0xA388,
		"raw_bytes": [0xFB, 1, 0x51],
	}
	var receipt: Dictionary = producer.build_receipt(1, event, 7119)
	if not bool(receipt.get("ok", false)):
		_fail("ROM animation `$51` CHR-shadow receipt failed: " + String(receipt.get("error", "unknown error")))
		_quit()
		return
	var writes: Array = receipt.get("ram_writes", [])
	var expected := [
		[0x94DE, 0x94E0, 0x009E, 0xF0],
		[0x94E3, 0x94E5, 0x009F, 0x71],
		[0x94E9, 0x94EB, 0x00A0, 0x66],
		[0x94EE, 0x94F0, 0x00A1, 0x67],
	]
	if writes.size() != expected.size():
		_fail("ROM `$94D8` producer did not emit four ordered CHR shadow writes.")
		_quit()
		return
	for index in expected.size():
		var write: Dictionary = writes[index]
		var want: Array = expected[index]
		if int(write.get("source_pc", -1)) != want[0] \
				or int(write.get("post_instruction_pc", -1)) != want[1] \
				or int(write.get("address", -1)) != want[2] \
				or int(write.get("value", -1)) != want[3]:
			_fail("ROM `$94D8` CHR shadow write %d differs from the checked ROM instructions." % index)
			_quit()
			return
	var wrong_event := event.duplicate(true)
	wrong_event["animation_ids"] = [0x12]
	if bool(producer.build_receipt(1, wrong_event, 7119).get("ok", true)):
		_fail("Animation CHR-shadow producer accepted an unrelated cutscene animation.")
		_quit()
		return
	print("PASS: cutscene `$FB $01 $51` resolves ROM frame `$B364`; `$94D8` derives `$F0,$71,$66,$67` at `$009E-$00A1`.")
	print("LIMIT: source-frame event attribution only; interrupt and sub-frame timing remain unexecuted.")
	_quit()


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _quit() -> void:
	quit(1 if _failed else 0)
