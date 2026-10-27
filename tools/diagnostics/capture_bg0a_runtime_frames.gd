extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const REFERENCE_SCREEN_DIR := "res://reference/opening_reference_capture/screens"
const SOURCE_FRAME_MIN := 2370
const SOURCE_FRAME_MAX := 2799


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene_resource := load(MAIN_SCENE_PATH) as PackedScene
	if scene_resource == null:
		push_error("Could not load the configured main scene.")
		quit(1)
		return
	var runtime_scene := scene_resource.instantiate()
	runtime_scene.name = "Main"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(runtime_scene)
	await process_frame
	runtime_scene.set_process(false)
	var presenter = runtime_scene.get_node("SourcePresenter")
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	var output_root := "res://reference/diagnostics/bg0a_camera_runtime_compare_%d" % int(Time.get_unix_time_from_system())
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var focused_source_frames := _available_reference_frames()
	if focused_source_frames.is_empty():
		push_error("No same-input reference frames were found in the requested BG0A interval.")
		quit(1)
		return
	var current_source_frame := int(presenter.state.get("source_frame", 0))
	var first_rendered_source_frame := SOURCE_FRAME_MIN - 1
	while current_source_frame < first_rendered_source_frame:
		presenter._advance_source_frame()
		current_source_frame = int(presenter.state.get("source_frame", current_source_frame + 1))
	field_screen.set_rendering_enabled(true)
	await process_frame
	var captured_frames := 0
	for source_frame in focused_source_frames:
		while current_source_frame < source_frame:
			presenter._advance_source_frame()
			current_source_frame = int(presenter.state.get("source_frame", current_source_frame + 1))
			# Let Godot draw every intermediate source frame. The renderer queues
			# redraws as PPU state changes, so skipping draw edges can leave stale
			# compositions in this temporal validation run.
			await process_frame
		var image := get_root().get_texture().get_image()
		if image == null or image.get_size() != Vector2i(256, 240):
			push_error("Runtime viewport did not produce a 256x240 image at frame %d." % source_frame)
			quit(1)
			return
		var frame_path := output_root + "/frame_%06d.png" % source_frame
		if image.save_png(frame_path) != OK:
			push_error("Could not save runtime frame %d." % source_frame)
			quit(1)
			return
		captured_frames += 1
	print("Rendered %d same-input checkpoints from frames %d–%d: %s" % [
		captured_frames, focused_source_frames.front(), focused_source_frames.back(), output_root,
	])
	quit(0)


func _available_reference_frames() -> Array[int]:
	var result: Array[int] = []
	var reference_dir := DirAccess.open(REFERENCE_SCREEN_DIR)
	if reference_dir == null:
		return result
	for filename in reference_dir.get_files():
		if not filename.begins_with("frame_") or not filename.ends_with(".gd"):
			continue
		var frame_text := filename.trim_prefix("frame_").trim_suffix(".gd")
		if not frame_text.is_valid_int():
			continue
		var source_frame := int(frame_text)
		if source_frame >= SOURCE_FRAME_MIN and source_frame <= SOURCE_FRAME_MAX:
			result.append(source_frame)
	result.sort()
	return result
