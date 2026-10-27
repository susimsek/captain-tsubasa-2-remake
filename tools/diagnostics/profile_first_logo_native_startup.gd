extends SceneTree
## Short cold-process native timing probe for the first opening logo animation.
## Run without --headless or --editor so Godot opens its normal project window.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const LAST_SOURCE_FRAME := 26
const REPORT_PATH := "res://reference/diagnostics/sprite_first_logo_native_timing_20261026.json"

var _render_samples: Array[Dictionary] = []
var _source_step_samples: Array[Dictionary] = []
var _current_source_frame := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_started_usec := Time.get_ticks_usec()
	var scene_load_started_usec := Time.get_ticks_usec()
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var scene_load_usec := Time.get_ticks_usec() - scene_load_started_usec
	if packed_scene == null:
		push_error("Could not load the configured main scene.")
		quit(1)
		return

	var instantiate_started_usec := Time.get_ticks_usec()
	var runtime := packed_scene.instantiate()
	var instantiate_usec := Time.get_ticks_usec() - instantiate_started_usec
	var initial_tile_cache_entries := RomSpriteAnimationPrototype._shared_sprite_tile_images.size()
	var initial_chr_loaded := not RomSpriteAnimationPrototype._shared_chr.is_empty()
	RomSpriteAnimationPrototype.set_diagnostic_timing_sink(
		Callable(self, "_record_render_timing"), 0)

	var tree_enter_started_usec := Time.get_ticks_usec()
	root.add_child(runtime)
	var tree_enter_ready_usec := Time.get_ticks_usec() - tree_enter_started_usec
	runtime.set_process(false)
	var presenter: Node = runtime.get_node("SourcePresenter")
	presenter.set_process(false)
	var audio := runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if audio != null:
		audio.stop()

	var first_draw_started_usec := Time.get_ticks_usec()
	await process_frame
	await RenderingServer.frame_post_draw
	var ready_to_first_draw_usec := Time.get_ticks_usec() - first_draw_started_usec
	var first_native_draw_elapsed_usec := Time.get_ticks_usec() - run_started_usec

	for source_frame in range(1, LAST_SOURCE_FRAME + 1):
		_current_source_frame = source_frame
		RomSpriteAnimationPrototype.set_diagnostic_source_frame(source_frame)
		var source_step_started_usec := Time.get_ticks_usec()
		presenter._advance_source_frame()
		var source_step_usec := Time.get_ticks_usec() - source_step_started_usec
		await process_frame
		var frame_post_draw_started_usec := Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		var source_step_to_post_draw_usec := Time.get_ticks_usec() - source_step_started_usec
		var post_draw_wait_usec := Time.get_ticks_usec() - frame_post_draw_started_usec
		_source_step_samples.append({
			"source_frame": source_frame,
			"source_step_cpu_usec": source_step_usec,
			"source_step_to_post_draw_usec": source_step_to_post_draw_usec,
			"post_draw_wait_usec": post_draw_wait_usec,
		})

	var report := {
		"status": "PASS" if int(presenter.state.get("source_frame", -1)) == LAST_SOURCE_FRAME else "FAIL",
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"run_mode": "native window; no --headless; no diagnostic warmup; audio stopped",
		"source_frame_range": [0, int(presenter.state.get("source_frame", -1))],
		"target_last_source_frame": LAST_SOURCE_FRAME,
		"initial_shared_sprite_tile_cache_entries": initial_tile_cache_entries,
		"initial_shared_chr_loaded": initial_chr_loaded,
		"startup_timing_usec": {
			"script_initialize_to_report_end": Time.get_ticks_usec() - run_started_usec,
			"main_scene_resource_load": scene_load_usec,
			"scene_instantiate": instantiate_usec,
			"add_to_tree_and_ready": tree_enter_ready_usec,
			"ready_to_first_native_draw": ready_to_first_draw_usec,
			"script_initialize_to_first_native_draw": first_native_draw_elapsed_usec,
		},
		"render_timing_samples": _render_samples,
		"source_step_timing_samples": _source_step_samples,
		"measurement_notes": [
			"ImageTexture.create_from_image duration is CPU-side creation/submission time; Godot does not expose a separate GPU transfer timer here.",
			"source_step_to_post_draw includes the source step, native frame scheduling, presentation, and vsync; it is not a pure upload duration.",
			"The measured initialize-to-first-draw interval begins inside the SceneTree script, after OS process/window creation has already started.",
			"The diagnostic does not deliberately prewarm sprite CHR, animation JSON, tile images, or textures before the first logo pose.",
		],
	}
	var report_file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report_file == null:
		push_error("Could not write timing report: %s" % REPORT_PATH)
		RomSpriteAnimationPrototype.set_diagnostic_timing_sink(Callable())
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	report_file.close()
	print("FIRST_LOGO_NATIVE_TIMING " + JSON.stringify(report))
	print("Report: %s" % ProjectSettings.globalize_path(REPORT_PATH))
	RomSpriteAnimationPrototype.set_diagnostic_timing_sink(Callable())
	root.remove_child(runtime)
	runtime.free()
	quit(0 if report["status"] == "PASS" else 1)


func _record_render_timing(sample: Dictionary) -> void:
	_render_samples.append(sample.duplicate(true))
