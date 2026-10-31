extends SceneTree

const WAIT_TASK := preload("res://scripts/gameplay/rom_cutscene_select_wait_task.gd")

var _failures := 0


func _initialize() -> void:
	var waiter: Variant = WAIT_TASK.new()
	_check(waiter.configure_from_project_sources(), "source wait-loop span and bytes are verified")
	_check(waiter.begin(), "$82B5 begins with its first $9FA8($01) yield")
	var status: Dictionary = waiter.get_status()
	_check(int(status.get("yield_count", -1)) == 1, "initial source yield count is one")
	for _poll in 42:
		var pending: Dictionary = waiter.resume(true, 0)
		_check(str(pending.get("status", "")) == "yielded", "$82B5 continues while script pointer is nonzero and Select is not pressed")
	var selected: Dictionary = waiter.resume(true, 0x20)
	_check(str(selected.get("status", "")) == "returned_select"
		and int(selected.get("yield_count", -1)) == 43
		and int(selected.get("return_source_pc", -1)) == 0x82C6,
		"Select exits after the 43 recorded $82B7 yields at the shared cleanup entry")
	_check(waiter.begin(), "waiter can be reused for a natural script return")
	var natural: Dictionary = waiter.resume(false, 0)
	_check(str(natural.get("status", "")) == "returned_natural"
		and int(natural.get("yield_count", -1)) == 1,
		"zero script pointer exits before another yield")
	if _failures == 0:
		print("PASS: ROM-byte-checked $82B5 cooperative wait, Select edge, and natural return.")
		print("LIMIT: the source CPU stack/task record and $82C6->$9BA0 cleanup effects are not executed here.")
	else:
		printerr("FAIL: %d cutscene Select-wait assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + label)
