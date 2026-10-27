extends SceneTree
## Capture focused BG0B CHR/raster checkpoints for ROM comparison only.
## The output PNGs are diagnostics, never runtime assets.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SOURCE_FRAMES: Array[int] = [
	2939, 2940, 2942, 3000, 3462, 3466, 3554, 3556,
	3571, 3572, 3596, 3597, 3598, 3599,
]
const OUTPUT_ROOT := "res://reference/diagnostics/bg0b_chr_raster_runtime_20261025"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the configured main scene.")
		return
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	var runtime_scene := packed.instantiate()
	runtime_scene.name = "BG0BCHRRasterCapture"
	get_root().add_child(runtime_scene)
	await process_frame
	runtime_scene.propagate_call("set_process", [false])
	var presenter: ColdStartSourceCommandPresenter = runtime_scene.get_node("SourcePresenter")
	presenter.set_capture_render_updates_suppressed(true)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	var checkpoints: Array[Dictionary] = []
	for source_frame in SOURCE_FRAMES:
		while int(presenter.state.get("source_frame", 0)) < source_frame:
			presenter._advance_source_frame()
			if bool(presenter.state.get("slice_failed", false)):
				_fail("Source presenter failed before frame %d." % source_frame)
				return
			await process_frame
		presenter.set_capture_render_updates_suppressed(false)
		field_screen.set_rendering_enabled(true)
		await process_frame
		RenderingServer.force_draw(false)
		await process_frame
		var image := get_root().get_texture().get_image()
		if image == null or image.get_size() != Vector2i(256, 240):
			_fail("Could not capture source frame %d." % source_frame)
			return
		var frame_path := "%s/frame_%06d.png" % [OUTPUT_ROOT, source_frame]
		if image.save_png(frame_path) != OK:
			_fail("Could not save source frame %d." % source_frame)
			return
		checkpoints.append({
			"source_frame": source_frame,
			"background_id": int(presenter.state.get("background_id", -1)),
			"scroll_pixels": [field_screen._scroll_x, field_screen._scroll_y],
			"initial_2k_chr_selectors": field_screen._source_mmc3_initial_2k_selectors.duplicate(),
			"chr_writes": field_screen._source_mmc3_chr_writes.duplicate(true),
			"raster_events": field_screen._source_raster_events.duplicate(true),
		})
		presenter.set_capture_render_updates_suppressed(true)
		field_screen.set_rendering_enabled(false)
	var manifest := FileAccess.open(OUTPUT_ROOT + "/capture_manifest.json", FileAccess.WRITE)
	if manifest == null:
		_fail("Could not write the BG0B capture manifest.")
		return
	manifest.store_string(JSON.stringify({
		"capture_kind": "focused ROM-derived Godot renderer comparison; not runtime assets",
		"source_frames": SOURCE_FRAMES,
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"checkpoints": checkpoints,
	}, "\t") + "\n")
	get_root().remove_child(runtime_scene)
	runtime_scene.free()
	await process_frame
	print("Captured focused BG0B CHR/raster frames: %s" % OUTPUT_ROOT)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
