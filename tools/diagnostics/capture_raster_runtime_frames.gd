extends SceneTree
## Capture the ROM-derived Godot runtime at the three runner raster checkpoints.
## Usage: godot --path . --script tools/diagnostics/capture_raster_runtime_frames.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SOURCE_FRAMES: Array[int] = [380, 382, 394]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene_resource := load(MAIN_SCENE_PATH) as PackedScene
	if scene_resource == null:
		push_error("Could not load the opening runtime scene.")
		quit(1)
		return
	var runtime_scene := scene_resource.instantiate()
	runtime_scene.name = "Main"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(runtime_scene)
	await process_frame
	runtime_scene.set_process(false)
	var presenter := runtime_scene.get_node("SourcePresenter")
	presenter.set_process(false)
	var output_root := "res://reference/diagnostics/raster_runtime_compare_%d" % int(Time.get_unix_time_from_system())
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	for source_frame in SOURCE_FRAMES:
		while int(presenter.state.get("source_frame", 0)) < source_frame:
			presenter._advance_source_frame()
			await process_frame
		var image := get_root().get_texture().get_image()
		if image == null or image.get_size() != Vector2i(256, 240):
			push_error("Runtime viewport did not produce a 256x240 image.")
			quit(1)
			return
		var frame_path := output_root + "/frame_%06d.png" % source_frame
		if image.save_png(frame_path) != OK:
			push_error("Could not save runtime frame %d." % source_frame)
			quit(1)
			return
	print("Captured raster runtime frames 380, 382, 394: %s" % output_root)
	quit(0)
