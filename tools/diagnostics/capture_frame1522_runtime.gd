extends SceneTree
## Capture source frame 1522 from the standalone Godot opening runtime.
## Usage: godot --headless --path . --script tools/diagnostics/capture_frame1522_runtime.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SOURCE_FRAME := 1522


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
	var presenter = runtime_scene.get_node("SourcePresenter")
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	while int(presenter.state.get("source_frame", 0)) < SOURCE_FRAME:
		presenter._advance_source_frame()
		await process_frame
	field_screen.set_rendering_enabled(true)
	await process_frame
	var output_root := "res://reference/diagnostics/frame1522_runtime_%d" % int(Time.get_unix_time_from_system())
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var image := get_root().get_texture().get_image()
	if image == null or image.get_size() != Vector2i(256, 240):
		push_error("Runtime viewport did not produce a 256x240 image at frame 1522.")
		quit(1)
		return
	var frame_path := output_root + "/frame_001522.png"
	if image.save_png(frame_path) != OK:
		push_error("Could not save the frame-1522 runtime image.")
		quit(1)
		return
	print("Captured source frame 1522: %s" % output_root)
	quit(0)
