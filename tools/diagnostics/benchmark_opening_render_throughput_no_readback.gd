extends SceneTree

const PRESENTER_SCENE := preload("res://scenes/prototypes/cold_start_source_command_presenter.tscn")
const FIRST_MEASURED_FRAME := 2367
const LAST_MEASURED_FRAME := 2408
const SOURCE_FRAME_BUDGET_MS := 1000.0 / 60.0988


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("No-readback throughput comparison requires a native display renderer.")
		quit(1)
		return
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	var can_disable_vsync := ClassDB.class_has_method("DisplayServer", "window_set_vsync_mode")
	if can_disable_vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var software := await _measure_mode(true)
	if software.is_empty():
		quit(1)
		return
	var gpu := await _measure_mode(false)
	if gpu.is_empty():
		quit(1)
		return
	var report_path := "res://reference/diagnostics/opening_render_no_readback_throughput_20261026.json"
	var report := {
		"godot_version": Engine.get_version_info(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"display_server": DisplayServer.get_name(),
		"vsync_disabled": can_disable_vsync,
		"source_frames": [FIRST_MEASURED_FRAME, LAST_MEASURED_FRAME],
		"samples_per_mode": LAST_MEASURED_FRAME - FIRST_MEASURED_FRAME + 1,
		"source_frame_budget_ms": SOURCE_FRAME_BUDGET_MS,
		"no_viewport_image_readback": true,
		"software": software,
		"gpu": gpu,
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write the no-readback throughput report.")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("NO_READBACK_THROUGHPUT software_mean_ms=%.3f software_fps=%.1f gpu_mean_ms=%.3f gpu_fps=%.1f gpu_fallbacks=%d frame_budget_ms=%.3f report=%s" % [
		float(software["mean_frame_ms"]), float(software["observed_fps"]),
		float(gpu["mean_frame_ms"]), float(gpu["observed_fps"]),
		int(gpu["fallback_count"]), SOURCE_FRAME_BUDGET_MS, report_path,
	])
	quit(0 if int(gpu["fallback_count"]) == 0 else 1)


func _measure_mode(force_software: bool) -> Dictionary:
	var presenter := PRESENTER_SCENE.instantiate() as ColdStartSourceCommandPresenter
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	var field_screen := presenter.get_node("FieldScreen") as RomPpuNametableScreenRenderer
	field_screen.set_rendering_enabled(false)
	field_screen.set_force_software_renderer_diagnostics(force_software)
	while int(presenter.state.get("source_frame", 0)) < FIRST_MEASURED_FRAME - 1:
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			push_error("Presenter failed before no-readback benchmark frame %d." % FIRST_MEASURED_FRAME)
			get_root().remove_child(presenter)
			presenter.free()
			return {}
	field_screen.set_rendering_enabled(true)
	await process_frame
	await RenderingServer.frame_post_draw
	var durations := PackedFloat64Array()
	var fallback_count := 0
	for source_frame in range(FIRST_MEASURED_FRAME, LAST_MEASURED_FRAME + 1):
		var started := Time.get_ticks_usec()
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			push_error("Presenter failed at no-readback benchmark frame %d." % source_frame)
			get_root().remove_child(presenter)
			presenter.free()
			return {}
		await process_frame
		await RenderingServer.frame_post_draw
		durations.append(float(Time.get_ticks_usec() - started) / 1000.0)
		if not force_software and not field_screen.use_gpu_background_renderer:
			fallback_count += 1
	var sorted := durations.duplicate()
	sorted.sort()
	var total := 0.0
	var over_budget := 0
	for duration in durations:
		total += duration
		if duration > SOURCE_FRAME_BUDGET_MS:
			over_budget += 1
	var mean_ms := total / durations.size()
	var median_ms := sorted[sorted.size() / 2]
	var p95_ms := sorted[int(floor((sorted.size() - 1) * 0.95))]
	var max_ms := sorted[-1]
	var result := {
		"renderer": "software" if force_software else "gpu",
		"mean_frame_ms": mean_ms,
		"median_frame_ms": median_ms,
		"p95_frame_ms": p95_ms,
		"max_frame_ms": max_ms,
		"observed_fps": 1000.0 / mean_ms if mean_ms > 0.0 else 0.0,
		"frames_over_60_0988hz_budget": over_budget,
		"fallback_count": fallback_count,
		"image_readbacks": 0,
		"fallback_reason": field_screen.gpu_background_fallback_reason,
	}
	get_root().remove_child(presenter)
	presenter.free()
	await process_frame
	return result
