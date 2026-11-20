extends SceneTree
## Checks that the scenario-$38 `$CBC1 RTS->$D7ED` caller and the later
## scheduler-dispatch path share the bounded PASS descriptor-$0F yield hook.
## This is route-wiring coverage only; it does not execute the live route.

const RUNNER_PATH := "res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source := FileAccess.get_file_as_string(RUNNER_PATH)
	if source.is_empty():
		_fail("Could not read the production source-route runner.")
		return
	var cbc1_body := _method_body(source, "func _resume_slot05_scenario35_wait_cycle(",
			"func _execute_slot05_pass_receiver_descriptor_0f_first_yield(")
	var dispatch_body := _method_body(source, "func resume_selected_slot05_worker() -> Dictionary:",
			"func _resume_slot05_scenario35_wait_cycle(")
	var yield_body := _method_body(source, "func _execute_slot05_pass_receiver_descriptor_0f_first_yield() -> Dictionary:",
			"func _resume_slot05_field_minimap_wait(")
	if cbc1_body.is_empty() or dispatch_body.is_empty() or yield_body.is_empty():
		_fail("One or more bounded production route methods could not be isolated.")
		return
	var adoption_index := cbc1_body.find("adopt_slot05_scenario35_return_state")
	var direct_d7ed_index := cbc1_body.find("== 0xD7ED")
	var direct_hook_index := cbc1_body.find("return _execute_slot05_pass_receiver_descriptor_0f_first_yield()")
	var generic_dadf_index := cbc1_body.find("execute_after_scenario_return(return_result)")
	if adoption_index < 0 or direct_d7ed_index <= adoption_index \
			or direct_hook_index <= direct_d7ed_index \
			or generic_dadf_index <= direct_hook_index:
		_fail("The `$CBC1->$D7ED` route must invoke the shared worker immediately after scheduler adoption and before the generic `$DADF` caller.")
		return
	if not dispatch_body.contains("== 0xD7ED") \
			or not dispatch_body.contains("return _execute_slot05_pass_receiver_descriptor_0f_first_yield()"):
		_fail("The later scheduler-dispatch route no longer reuses the same `$D7ED` worker hook.")
		return
	var worker_index := yield_body.find("execute_pass_receiver_descriptor_0f_first_yield(")
	var adopt_index := yield_body.find("adopt_slot05_pass_receiver_descriptor_0f_first_yield(")
	var save_index := yield_body.find("_yield_slot05_field_worker_callsite(")
	if worker_index < 0 or adopt_index <= worker_index or save_index <= adopt_index \
			or source.count("execute_pass_receiver_descriptor_0f_first_yield(") != 1:
		_fail("The shared hook must execute one ROM worker, adopt its write receipt, and then save/yield at `$8886->$C515`.")
		return
	print("PASS: `$CBC1 RTS->$D7ED` invokes the shared descriptor-$0F worker/yield hook before the generic `$DADF` branch; later dispatch reuses it.")
	print("LIMIT: static route-wiring check only; ordinary-input live execution must confirm `$C515` task save and scheduler scan.")
	quit(0)


func _method_body(source: String, start_marker: String, next_marker: String) -> String:
	var start := source.find(start_marker)
	if start < 0:
		return ""
	var end := source.find(next_marker, start + start_marker.length())
	if end < 0:
		return ""
	return source.substr(start, end - start)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
