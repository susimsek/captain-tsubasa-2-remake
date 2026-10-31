extends SceneTree

const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ACTOR_WORKER := preload("res://scripts/gameplay/rom_slot11_actor_worker_prefix_executor.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: bank-$18 actor-worker and parameter-$73 pointer bytes validate; absent live slot-$09/$11 seed boundaries are rejected without scheduler mutation.")
	print("LIMIT: this verifier has not yet consumed a positive route-produced `$ED15` request or confirmed the `$8000->$8047->$CB0F` yield.")
	quit(0)


func _verify() -> bool:
	var worker = ACTOR_WORKER.new()
	if not worker.configure_from_project_sources():
		return _fail("Actor-worker source/pointer validation failed: " + worker.error_message)
	var no_boundary: Dictionary = worker.execute_from_dispatched_slot11({})
	if bool(no_boundary.get("ok", false)) or not String(no_boundary.get("error", "")).contains("live scheduler snapshot"):
		return _fail("Actor-worker executor did not fail closed when its live scheduler input was absent.")

	var scheduler = SCHEDULER.new()
	if not scheduler.configure_from_project_sources():
		return _fail("Scheduler source manifest validation failed: " + scheduler.error_message)
	if not bool(scheduler.initialize_fresh_game_bootstrap().get("ok", false)):
		return _fail("Source-derived scheduler bootstrap failed: " + scheduler.error_message)
	if not scheduler.get_task_boundary_snapshot(0x11).is_empty():
		return _fail("Verifier unexpectedly found a slot-$11 task context before its route seed.")
	var before: Dictionary = scheduler.get_status()
	var rejected: Dictionary = scheduler.save_slot11_actor_worker_first_yield({})
	var absent_worker_error: String = scheduler.error_message
	var caller_prefix_rejected: bool = not scheduler.adopt_slot09_actor_seed_caller_prefix({})
	var seed_request_rejected: Dictionary = scheduler.seed_slot11_actor_worker_from_source_request({})
	var continuation_rejected: bool = not scheduler.adopt_slot09_after_actor_seed_continuation({})
	var chain_rejected: bool = not scheduler.adopt_slot09_actor_seeded_root_loop_entry_state([], {})
	var after: Dictionary = scheduler.get_status()
	before["error"] = ""
	after["error"] = ""
	if bool(rejected.get("ok", false)) \
			or not absent_worker_error.contains("live initial `$8000` task context") \
			or not caller_prefix_rejected or not seed_request_rejected.is_empty() \
			or not continuation_rejected or not chain_rejected \
			or after != before:
			return _fail("Scheduler accepted or mutated absent slot-$09/slot-$11 actor-route source boundaries.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
