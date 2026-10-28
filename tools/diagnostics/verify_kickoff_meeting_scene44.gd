extends SceneTree

const VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var vm := VM_SCRIPT.new() as KickoffCutsceneCommandVm
	var visuals := VISUALS_SCENE.instantiate() as KickoffCutsceneVisuals
	root.add_child(vm)
	root.add_child(visuals)
	await process_frame
	visuals.bind_vm(vm)
	visuals.prepare_pre_match_meeting_scene()
	_check(vm.start_cutscene(0x44), "Scene $44 validates against its flattened ROM jump stream")
	_check(visuals.active_background_id == 0x5F, "Scene $44 installs ROM background $5F")
	_check(visuals._animations.size() == 1, "Scene $44 creates its ROM speaker animation")
	_check(visuals._animations.size() == 1 and visuals._animations[0].animation_id == "0x3B", "Scene $44 selects animation $3B")
	_check(vm.state == VM_SCRIPT.RunState.WAITING_TICKS, "Scene $44 reaches its first source FC wait")
	for _tick in 8:
		visuals.advance_source_tick()
		vm.advance_scheduler_tick(0)
	_check(vm.state == VM_SCRIPT.RunState.FINISHED, "Scene $44 completes both four-tick FC handlers and its FE target")
	_check(visuals.present_pre_match_meeting_menu(0x98), "ROM cursor resources render on scene $44 background")
	_check(is_instance_valid(visuals._meeting_cursor), "Meeting menu cursor node is present")
	_check(visuals.set_pre_match_meeting_cursor_y(0xA8), "Meeting menu cursor accepts the next ROM row")
	_check(int(visuals._meeting_cursor.get("cursor_y")) == 0xA8, "Meeting cursor state tracks source Y=$A8")
	if _failures == 0:
		print("PASS: scene $44 ROM stream, $5F background, $3B speaker, FC waits, and ROM cursor resources")
		print("LIMIT: E8/F3 visual semantics, exact speaker $99 branch cadence, and scene-to-menu raster timing remain open")
	else:
		printerr("FAIL: %d MEETING scene assertion(s)" % _failures)
	visuals.queue_free()
	vm.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


var _failures := 0


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
