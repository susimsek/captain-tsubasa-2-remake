extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var title := main.get_node("TitleMenu") as RomTitleMenu
	title.kickoff_requested.emit()
	await process_frame
	var route := main.get_node_or_null("KickoffRouteRuntime") as KickoffRouteRuntime
	if route == null:
		_fail("KICK OFF selection did not create the fresh-start route.")
		return
	if title.visible or (main.get_node("SourcePresenter") as Node2D).visible:
		_fail("The title or cold-start presenter remained visible after route entry.")
		return
	if route.vm.cutscene_id != 1 or route.get_route_status().get("stage") != "cutscene_1":
		_fail("Fresh-start route did not begin ROM cutscene ID 1.")
		return
	if main.get_node("OpeningAudio").playing:
		_fail("Cold-start music was not stopped when KICK OFF took audio ownership.")
		return

	print("PASS: title KICK OFF creates the route and starts ROM cutscene ID 1.")
	print("LIMIT: this test stops at cutscene ID 1. The separately checked route reaches field/menu pending; source callback/task integration, full visuals, exact timing, and route PCM remain open.")
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
