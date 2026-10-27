extends SceneTree
## Measure real-window Godot frame pacing through the cold opening, without
## audio output. This is performance evidence only, not a ROM parity test.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TARGET_SOURCE_FRAME := 4661
const TIMEOUT_SECONDS := 120.0


func _initialize() -> void:
	call_deferred("_profile")


func _profile() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Could not load the configured main scene.")
		quit(1)
		return
	var runtime := packed_scene.instantiate()
	runtime.name = "OpeningRuntimeProfile"
	get_root().add_child(runtime)
	await process_frame
	var presenter = runtime.get_node("SourcePresenter")
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	var audio := runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if audio != null:
		audio.stop()

	var frame_intervals_usec: Array[int] = []
	var slow_intervals: Array[Dictionary] = []
	var source_frames_caught_up := 0
	var max_source_step := 0
	var previous_source_frame := int(presenter.state.get("source_frame", 0))
	var started_usec := Time.get_ticks_usec()
	var previous_tick_usec := started_usec
	var timed_out := false
	while int(presenter.state.get("source_frame", 0)) < TARGET_SOURCE_FRAME:
		await process_frame
		var now_usec := Time.get_ticks_usec()
		var interval_usec := now_usec - previous_tick_usec
		frame_intervals_usec.append(interval_usec)
		previous_tick_usec = now_usec
		var source_frame := int(presenter.state.get("source_frame", previous_source_frame))
		var source_step := maxi(0, source_frame - previous_source_frame)
		max_source_step = maxi(max_source_step, source_step)
		if source_step > 1:
			source_frames_caught_up += source_step - 1
		if interval_usec > 25000:
			slow_intervals.append({
				"interval_ms": float(interval_usec) / 1000.0,
				"source_frame_before": previous_source_frame,
				"source_frame_after": source_frame,
				"source_frame_step": source_step,
				"animation_generation": int(presenter.state.get("animation_generation", -1)),
				"animation_ids": presenter.state.get("animation_ids", []).duplicate(),
				"background_id": int(presenter.state.get("background_id", -1)),
				"gpu_background_active": field_screen.use_gpu_background_renderer,
				"gpu_background_fallback_count": field_screen.gpu_background_fallback_count,
			})
		previous_source_frame = source_frame
		if float(now_usec - started_usec) / 1000000.0 > TIMEOUT_SECONDS:
			timed_out = true
			break

	var sorted_intervals: Array[int] = frame_intervals_usec.duplicate()
	sorted_intervals.sort()
	var total_usec := 0
	var over_ntsc_budget := 0
	var over_60hz_budget := 0
	var max_interval_usec := 0
	for interval_usec in frame_intervals_usec:
		total_usec += interval_usec
		max_interval_usec = maxi(max_interval_usec, interval_usec)
		if interval_usec > 16639:
			over_ntsc_budget += 1
		if interval_usec > 16667:
			over_60hz_budget += 1
	var p95_usec := 0
	if not sorted_intervals.is_empty():
		p95_usec = sorted_intervals[mini(
			 sorted_intervals.size() - 1,
			 int(ceil(float(sorted_intervals.size()) * 0.95)) - 1)]
	slow_intervals.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["interval_ms"]) > float(b["interval_ms"]))
	var worst_slow_intervals: Array[Dictionary] = []
	for i in mini(10, slow_intervals.size()):
		worst_slow_intervals.append(slow_intervals[i])
	var result := {
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"source_frame_target": TARGET_SOURCE_FRAME,
		"source_frame_reached": int(presenter.state.get("source_frame", -1)),
		"host_frame_samples": frame_intervals_usec.size(),
		"elapsed_seconds": float(Time.get_ticks_usec() - started_usec) / 1000000.0,
		"mean_frame_interval_ms": float(total_usec) / maxf(1.0, float(frame_intervals_usec.size())) / 1000.0,
		"p95_frame_interval_ms": float(p95_usec) / 1000.0,
		"max_frame_interval_ms": float(max_interval_usec) / 1000.0,
		"frames_over_60_0988hz_budget": over_ntsc_budget,
		"frames_over_60hz_budget": over_60hz_budget,
		"source_frames_caught_up": source_frames_caught_up,
		"max_source_frame_step": max_source_step,
		"slow_intervals_over_25ms": worst_slow_intervals,
		"timed_out": timed_out,
		"audio_driver_expected": "Dummy; no audio output",
	}
	print("OPENING_REALTIME_PROFILE " + JSON.stringify(result))
	get_root().remove_child(runtime)
	runtime.free()
	quit(1 if timed_out else 0)
