extends SceneTree
## Capture runtime OAM/source state and rendered images at two BG08 checkpoints.
## Usage: godot --headless --path . --script tools/diagnostics/capture_bg08_oam_runtime.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DISPLAY_SOURCE_FRAMES: Array[int] = [1108, 1522]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene_resource := load(MAIN_SCENE_PATH) as PackedScene
	if scene_resource == null:
		push_error("Could not load the standalone opening runtime scene.")
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
	var output_root := "res://reference/diagnostics/bg08_oam_shared_composition_validation"
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var checkpoints: Array[Dictionary] = []
	for display_frame in DISPLAY_SOURCE_FRAMES:
		while int(presenter.state.get("source_frame", 0)) < display_frame:
			presenter._advance_source_frame()
			await process_frame
		if presenter._bg08_sprite_oam_composer == null:
			push_error("BG08 shared OAM compositor was not active at displayed frame %d." % display_frame)
			quit(1)
			return
		field_screen.set_rendering_enabled(true)
		await process_frame
		var viewport_available := false
		var viewport_path := ""
		if DisplayServer.get_name().to_lower() != "headless":
			var viewport_texture := get_root().get_texture()
			var image := viewport_texture.get_image()
			if image == null or image.get_size() != Vector2i(256, 240):
				push_error("Runtime viewport was not 256x240 at displayed frame %d." % display_frame)
				quit(1)
				return
			viewport_available = true
			viewport_path = output_root + "/frame_%06d.png" % display_frame
			if image.save_png(viewport_path) != OK:
				push_error("Could not save runtime viewport image at displayed frame %d." % display_frame)
				quit(1)
				return
		var sprite_image: Image = presenter._bg08_sprite_oam_composer.sprite_composition_image()
		if sprite_image == null or sprite_image.get_size() != Vector2i(256, 240):
			push_error("ROM-derived sprite composition was not rendered at displayed frame %d." % display_frame)
			quit(1)
			return
		var sprite_path := output_root + "/sprites_%06d.png" % display_frame
		if sprite_image.save_png(sprite_path) != OK:
			push_error("Could not save ROM-derived sprite composition at displayed frame %d." % display_frame)
			quit(1)
			return
		var snapshot: Dictionary = presenter._bg08_sprite_oam_composer.debug_snapshot()
		checkpoints.append({
			"display_frame": display_frame,
			"ram_oam_reference_frame": display_frame - 1,
			"godot_viewport_available": viewport_available,
			"godot_viewport_png": viewport_path,
			"godot_sprite_composition_png": sprite_path,
			"oam": snapshot,
		})
		field_screen.set_rendering_enabled(false)
	var report := {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"capture_kind": "Godot runtime validation output; images are not runtime assets",
		"checkpoints": checkpoints,
	}
	var report_file := FileAccess.open(output_root + "/runtime_oam.json", FileAccess.WRITE)
	if report_file == null:
		push_error("Could not write runtime OAM JSON.")
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	print("Captured BG08 shared OAM/runtime checkpoints: %s" % output_root)
	quit(0)
