extends SceneTree

const QUEUE_EXECUTOR := preload("res://scripts/gameplay/rom_fresh_scenario36_queue_executor.gd")


func _init() -> void:
	var executor = QUEUE_EXECUTOR.new()
	if not executor.configure():
		push_error("Scenario-$36 ROM source package failed: " + executor.error_message)
		quit(1)
		return
	print("PASS: scenario-$36 caller, queue routine, and `$DB13->$E0DF` handoff bytes match their ROM manifest entries.")
	quit(0)
