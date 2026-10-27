extends SceneTree
## Capture the source-driven BG08 OAM state exactly at display frame 1088.
## Images/OAM output are validation evidence only, never runtime assets.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DISPLAY_SOURCE_FRAME := 1088
const OUTPUT_ROOT := "res://reference/diagnostics/bg08_oam_frame1088_oam_audit"


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
	runtime_scene.propagate_call("set_process", [false])
	var presenter = runtime_scene.get_node("SourcePresenter")
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	presenter.set_capture_render_updates_suppressed(true)
	field_screen.set_rendering_enabled(false)
	while int(presenter.state.get("source_frame", 0)) < DISPLAY_SOURCE_FRAME:
		presenter._advance_source_frame()
	if presenter._bg08_sprite_oam_composer == null:
		push_error("BG08 shared OAM compositor was not active at frame 1088.")
		quit(1)
		return
	presenter.set_capture_render_updates_suppressed(false)
	var composer: RomBg08SpriteOamComposer = presenter._bg08_sprite_oam_composer
	var root := ProjectSettings.globalize_path(OUTPUT_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var sprite_image := composer.sprite_composition_image()
	if sprite_image == null or sprite_image.get_size() != Vector2i(256, 240):
		push_error("BG08 sprite composition image was unavailable at frame 1088.")
		quit(1)
		return
	var image_path := OUTPUT_ROOT + "/sprites_001088.png"
	if sprite_image.save_png(image_path) != OK:
		push_error("Could not save BG08 sprite composition image.")
		quit(1)
		return
	var snapshot: Dictionary = composer.debug_snapshot()
	var report := {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"capture_kind": "Godot source-driven OAM diagnostic; not a runtime asset",
		"checkpoints": [{
			"display_frame": DISPLAY_SOURCE_FRAME,
			"ram_oam_reference_frame": DISPLAY_SOURCE_FRAME - 1,
			"godot_sprite_composition_png": image_path,
			"oam": snapshot,
			"presenter_visual_state": {
				"background_id": int(presenter.state.get("background_id", -1)),
				"animation_ids": presenter.state.get("animation_ids", []),
				"oam_shadow_cleared": bool(presenter.state.get("oam_shadow_cleared", false)),
				"oam_y_shift_pixels": int(presenter.state.get("oam_y_shift_pixels", 0)),
				"oam_priority_behind_background": bool(presenter.state.get("oam_priority_behind_background", false)),
			},
		}],
	}
	var report_file := FileAccess.open(OUTPUT_ROOT + "/runtime_oam.json", FileAccess.WRITE)
	if report_file == null:
		push_error("Could not write the BG08 OAM report.")
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	print("Captured BG08 runtime OAM state at frame 1088: %s" % OUTPUT_ROOT)
	quit(0)
