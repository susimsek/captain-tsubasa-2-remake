extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var title := main.get_node("TitleMenu") as RomTitleMenu
	title.visible = true
	if int(title.get("_selected")) != 0:
		_fail("The title did not begin with KICK OFF selected.")
		return
	var kickoff_start := InputEventKey.new()
	kickoff_start.keycode = KEY_ENTER
	kickoff_start.pressed = true
	title.call("_unhandled_input", kickoff_start)
	await process_frame
	var route: KickoffRouteRuntime = main.get_node_or_null("KickoffRouteRuntime") as KickoffRouteRuntime
	if route == null:
		_fail("KICK OFF selection did not create the fresh-start route.")
		return
	if title.visible or (main.get_node("SourcePresenter") as Node2D).visible:
		_fail("The title or cold-start presenter remained visible after route entry.")
		return
	if route.vm.cutscene_id != 1 or route.get_route_status().get("stage") != "cutscene_1":
		_fail("Fresh-start route did not begin ROM cutscene ID 1.")
		return
	var event_before_select: int = route.vm.current_event_index
	var vm_state_before_select: int = int(route.vm.state)
	var select_input := InputEventAction.new()
	select_input.action = "route_select"
	select_input.pressed = true
	route._unhandled_input(select_input)
	if route.vm.current_event_index != event_before_select \
			or int(route.vm.state) != vm_state_before_select \
			or route.get_route_status().get("stage") != "cutscene_1":
		_fail("Select incorrectly skipped or completed a ROM cutscene command.")
		return
	if main.get_node("OpeningAudio").playing:
		_fail("Cold-start music was not stopped when KICK OFF took audio ownership.")
		return

	print("PASS: Enter confirms selected KICK OFF, starts ROM cutscene ID 1, and Select cannot skip its source commands.")
	print("LIMIT: this test stops at cutscene ID 1. Cutscene-2 caller wait and the explicit $9BA0 stop boundary are checked separately; cleanup integration, field/menu rendering, exact timing, and route PCM remain open.")
	route.cue_audio.release_rom_audio_resources()
	(main.get_node("OpeningAudio") as AudioStreamPlayer).stop()
	root.remove_child(main)
	main.free()
	await process_frame
	# AudioStreamPlayer's playback object is released after the audio mixer has
	# observed stop/stream=null; let the dummy/headless mixer drain before exit.
	await create_timer(0.1).timeout
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
