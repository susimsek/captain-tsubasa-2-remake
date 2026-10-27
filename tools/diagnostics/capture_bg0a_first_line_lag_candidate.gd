extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SOURCE_FRAME_MIN := 2367
const SOURCE_FRAME_MAX := 2373
const OUTPUT_ROOT := "res://reference/diagnostics/bg0a_first_line_lag_candidate_20261025"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
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
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_ROOT)
	DirAccess.make_dir_recursive_absolute(output_absolute)
	var current_source_frame := int(presenter.state.get("source_frame", 0))
	while current_source_frame < SOURCE_FRAME_MIN - 1:
		presenter._advance_source_frame()
		current_source_frame = int(presenter.state.get("source_frame", current_source_frame + 1))
	field_screen.set_rendering_enabled(true)
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	for source_frame in range(SOURCE_FRAME_MIN, SOURCE_FRAME_MAX + 1):
		while current_source_frame < source_frame:
			presenter._advance_source_frame()
			current_source_frame = int(presenter.state.get("source_frame", current_source_frame + 1))
			await process_frame
		RenderingServer.force_draw(false)
		await process_frame
		var image := get_root().get_texture().get_image()
		if image == null or image.get_size() != Vector2i(256, 240):
			push_error("Runtime viewport did not produce a 256x240 image at frame %d." % source_frame)
			quit(1)
			return
		var frame_path := OUTPUT_ROOT + "/frame_%06d.png" % source_frame
		if image.save_png(frame_path) != OK:
			push_error("Could not save runtime frame %d." % source_frame)
			quit(1)
			return
	print("Rendered candidate frames %d–%d to %s" % [
		SOURCE_FRAME_MIN, SOURCE_FRAME_MAX, OUTPUT_ROOT,
	])
	quit(0)
