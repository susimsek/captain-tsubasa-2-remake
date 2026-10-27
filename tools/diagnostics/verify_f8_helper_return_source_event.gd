extends SceneTree
## Verifies that the ROM-stepper F8 return event dispatches `$DF` on frame
## 3968 and captures only that narrow render window for visual regression.

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const OUTPUT_ROOT := "res://reference/diagnostics/f8_helper_return_source_event_20261026"
const EXPECTED_SCRIPT_TAIL: Array[int] = [0xDF, 0xFE, 0x20, 0xA0]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the source-command presenter scene.")
		return
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	if presenter == null:
		_fail("Could not instantiate the source-command presenter.")
		return
	presenter.name = "F8HelperReturnSourceEventCheck"
	get_root().add_child(presenter)
	await process_frame
	if presenter._f8_helper_return_event.is_empty() or presenter.state.is_empty():
		_fail("Presenter did not load the ROM-stepper F8 helper-return event.")
		return
	presenter.propagate_call("set_process", [false])
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	presenter.set_render_updates_suppressed(true)
	while int(presenter.state.get("source_frame", 0)) < 3966:
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			_fail("Source presenter failed before the F8 return window.")
			return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	var checkpoints: Array[Dictionary] = []
	for source_frame in [3966, 3967, 3968, 3969]:
		presenter.set_render_updates_suppressed(true)
		field_screen.set_rendering_enabled(false)
		while int(presenter.state.get("source_frame", 0)) < source_frame:
			presenter._advance_source_frame()
			if bool(presenter.state.get("slice_failed", false)):
				_fail("Source presenter failed at frame %d: %s" % [
					source_frame, str(presenter.state.get("slice_error", "unknown error"))])
				return
		if source_frame == 3967:
			var f8_service: Dictionary = presenter.state.get("f8_00_service", {})
			if not bool(f8_service.get("helper_return_to_script", false)) \
					or int(presenter.state.get("script_dispatch_not_before_frame", -1)) != 3968 \
					or int(presenter.state.get("source_frame_of_last_dispatch", -1)) == 3968:
				_fail("Frame 3967 did not retain the source-event wait before `$DF` dispatch.")
				return
		if source_frame == 3968:
			var script_tail := presenter._script_bytes.slice(0x27D, 0x27D + EXPECTED_SCRIPT_TAIL.size())
			var pause_accounting: Dictionary = presenter.state.get("compact_pause_release_accounting", {})
			if str(presenter.state.get("last_rom_bytes", "")) != "$DF" \
					or str(presenter.state.get("cutscene_cpu_pointer", "")) != "$A29D" \
					or int(presenter.state.get("source_frame_of_last_dispatch", -1)) != 3968 \
					or int(presenter.state.get("pending_compact_pause_delay", -1)) != 240 \
					or not bool(pause_accounting.get("same_frame_release_precounted", false)) \
					or script_tail != PackedByteArray(EXPECTED_SCRIPT_TAIL):
				_fail("Frame 3968 `$DF` dispatch, preserved pause, or following `$FE` bytes differ.")
				return
		if source_frame == 3969:
			if str(presenter.state.get("last_rom_bytes", "")) != "$DF" \
					or str(presenter.state.get("cutscene_cpu_pointer", "")) != "$A29D" \
					or int(presenter.state.get("source_frame_of_last_dispatch", -1)) != 3968:
				_fail("Frame 3969 unexpectedly changed the F8-to-`$DF` pause state.")
				return
		presenter.set_render_updates_suppressed(false)
		field_screen.set_rendering_enabled(true)
		await process_frame
		RenderingServer.force_draw(false)
		await process_frame
		var viewport_image := get_root().get_texture().get_image()
		if viewport_image == null or viewport_image.get_size() != Vector2i(256, 240):
			_fail("Could not capture the 256x240 frame %d output." % source_frame)
			return
		var output_path := "%s/frame_%06d.png" % [OUTPUT_ROOT, source_frame]
		if viewport_image.save_png(output_path) != OK:
			_fail("Could not save frame %d output." % source_frame)
			return
		checkpoints.append({
			"source_frame": source_frame,
			"script_cpu_pointer": presenter.state.get("cutscene_cpu_pointer", ""),
			"last_rom_bytes": presenter.state.get("last_rom_bytes", ""),
			"last_dispatch_source_frame": presenter.state.get("source_frame_of_last_dispatch", -1),
			"dispatch_not_before_frame": presenter.state.get("script_dispatch_not_before_frame", -1),
			"rom_helper_completion_frame": presenter.state.get("f8_00_service", {}).get("complete_source_frame", -1),
			"f8_event_dispatch_frame": presenter.state.get("f8_helper_return_dispatch_event", {}).get("dispatch_source_frame", -1),
			"pending_compact_pause_delay": presenter.state.get("pending_compact_pause_delay", -1),
		})
	var report := FileAccess.open(OUTPUT_ROOT + "/verification.json", FileAccess.WRITE)
	if report == null:
		_fail("Could not write the F8 helper-return verification report.")
		return
	report.store_string(JSON.stringify({
		"result": "PASS",
		"source_rom_sha256": presenter.state.get("rom_sha256", ""),
		"event_resource": presenter.state.get("f8_helper_return_event_path", ""),
		"event_frame": 3968,
		"runtime_consumes_cycle_offsets": false,
		"checkpoints": checkpoints,
	}, "\t") + "\n")
	get_root().remove_child(presenter)
	presenter.free()
	await process_frame
	print("F8 helper-return source-event window passed at frames 3967–3969.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
