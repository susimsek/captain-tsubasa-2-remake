extends SceneTree
## Capture BG09 palette-state checkpoints and viewport frames from the standalone runtime.
## FCEUX PPU/RAM and screenshots are read only by the separate validation script.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const STATE_FRAMES: Array[int] = [
	1779, 1780, 1781, 1784, 1785, 1788, 1789, 1792, 1793, 2033, 2034, 2035, 2036,
	2098, 2100, 2101, 2102, 2103, 2104, 2105, 2106, 2107, 2108, 2109, 2110,
	2111, 2112, 2113, 2114, 2115, 2116, 2117,
]
const VIEWPORT_FRAMES: Array[int] = [
	1780, 1784, 1788, 1792, 2034, 2036,
	2098, 2100, 2102, 2104, 2106, 2108, 2110, 2112, 2114, 2116,
]
const OUTPUT_ROOT := "res://reference/diagnostics/bg09_palette_effect_validation"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the standalone opening runtime.")
		return
	var runtime = packed.instantiate()
	runtime.name = "BG09PaletteValidationRuntime"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(runtime)
	await process_frame
	runtime.set_process(false)
	var presenter: ColdStartSourceCommandPresenter = runtime.get_node("SourcePresenter")
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	var viewport_capture_available := DisplayServer.get_name().to_lower() != "headless"
	var absolute_root := ProjectSettings.globalize_path(OUTPUT_ROOT)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var checkpoint_report: Array[Dictionary] = []
	for frame in STATE_FRAMES:
		while int(presenter.state.get("source_frame", 0)) < frame:
			presenter._advance_source_frame()
			await process_frame
		var palette: PackedByteArray = presenter._committed_palette
		var field_palette: PackedByteArray = field_screen._background_palette
		if palette.size() != 32 or field_palette.size() != 16:
			_fail("ROM palette state was unavailable at source frame %d." % frame)
			return
		var checkpoint := {
			"source_frame": frame,
			"modeled_ram_004c": int(presenter.state.get("ram_004C_value_or_delta", -1)),
			"modeled_ram_0633": int(presenter._base_palette[9]),
			"modeled_committed_3f09": int(palette[9]),
			"renderer_background_3f09": int(field_palette[9]),
			"effect_state": presenter.state.get("bg09_palette_effect", {}).duplicate(true),
			"effect_model": presenter._bg09_palette_effect_model.debug_snapshot() if presenter._bg09_palette_effect_model != null else {},
			"modeled_fade_counters": presenter.state.get("fade_counters", Vector2i.ZERO),
			"modeled_fade_running": presenter._fade_running,
			"modeled_queue_cursor_0628": presenter._background_01_queue_cursor,
			"viewport_png": "",
		}
		if VIEWPORT_FRAMES.has(frame) and viewport_capture_available:
			field_screen.set_rendering_enabled(true)
			await process_frame
			var viewport_image := get_root().get_texture().get_image()
			if viewport_image == null or viewport_image.get_size() != Vector2i(256, 240):
				_fail("Could not capture a 256x240 Godot viewport at frame %d." % frame)
				return
			var viewport_path := "%s/frame_%06d.png" % [OUTPUT_ROOT, frame]
			if viewport_image.save_png(viewport_path) != OK:
				_fail("Could not save the Godot viewport at frame %d." % frame)
				return
			checkpoint["viewport_png"] = viewport_path
			field_screen.set_rendering_enabled(false)
		checkpoint_report.append(checkpoint)
	var report := {
		"capture_kind": "Godot source-runtime validation output; viewport images are not runtime assets",
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"effect_stream_source": "ROM bank 6 $B838, preserved bytes and metadata under reference/rom_extract/intro/palette_effect_state/",
		"godot_viewport_capture_available": viewport_capture_available,
		"checkpoints": checkpoint_report,
	}
	var report_file := FileAccess.open(OUTPUT_ROOT + "/runtime_palette.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write the BG09 runtime palette report.")
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	get_root().remove_child(runtime)
	runtime.free()
	await process_frame
	print("Captured BG09 palette state and viewport checkpoints: %s" % OUTPUT_ROOT)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
