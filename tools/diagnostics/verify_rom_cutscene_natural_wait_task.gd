extends SceneTree

const WAIT_TASK := preload("res://scripts/gameplay/rom_cutscene_natural_wait_task.gd")

var _failures := 0


func _initialize() -> void:
	var waiter: Variant = WAIT_TASK.new()
	_check(waiter.configure_from_project_sources(), "$82A9 source bytes and hash are verified")
	_check(waiter.begin(), "$82A9 begins its cooperative pointer-poll loop")
	var still_active: Dictionary = waiter.advance_source_tick(0xBFF2)
	_check(String(still_active.get("status", "")) == "yielded"
		and int(still_active.get("yield_count", -1)) == 1
		and int(still_active.get("next_source_pc", -1)) == 0x82A9,
		"nonzero $004D/$004E repeats the source loop after one yield")
	var natural: Dictionary = waiter.advance_source_tick(0)
	_check(String(natural.get("status", "")) == "returned_natural"
		and int(natural.get("yield_count", -1)) == 2
		and int(natural.get("next_source_pc", -1)) == 0x82B4,
		"zero $004D/$004E returns after the second source yield")
	_check(not bool(waiter.advance_source_tick(0).get("ok", false)),
		"a completed caller loop cannot be advanced again")
	if _failures == 0:
		print("PASS: ROM-byte-checked $82A9 wait loop yields then polls the live script pointer.")
		print("LIMIT: pointer-byte phase and CPU/NMI cycle timing remain frame-level route evidence.")
	else:
		printerr("FAIL: %d natural-wait assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + label)
