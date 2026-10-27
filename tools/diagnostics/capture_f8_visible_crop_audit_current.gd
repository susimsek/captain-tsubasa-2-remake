extends SceneTree
## Capture the current Godot F8 transition rows for a focused FCEUX comparison.
## Outputs are diagnostic only and never loaded by the game.

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const FIRST_SOURCE_FRAME := 3598
const LAST_SOURCE_FRAME := 3604
const OUTPUT_ROOT := "res://reference/diagnostics/f8_visible_crop_audit_current_20261025"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the standalone source presenter.")
		return
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	presenter.name = "F8VisibleCropAuditCurrent"
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	while int(presenter.state.get("source_frame", 0)) < FIRST_SOURCE_FRAME:
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			_fail("Source presenter failed before the F8 visible-crop audit.")
			return
	field_screen.set_rendering_enabled(true)
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	var checkpoints: Array[Dictionary] = []
	for source_frame in range(FIRST_SOURCE_FRAME, LAST_SOURCE_FRAME + 1):
		while int(presenter.state.get("source_frame", 0)) < source_frame:
			presenter._advance_source_frame()
			if bool(presenter.state.get("slice_failed", false)):
				_fail("Source presenter failed at F8 source frame %d." % source_frame)
				return
		await process_frame
		var viewport_image := get_root().get_texture().get_image()
		if viewport_image == null or viewport_image.get_size() != Vector2i(256, 240):
			_fail("Could not capture F8 source frame %d." % source_frame)
			return
		var candidate_path := "%s/frame_%06d.png" % [OUTPUT_ROOT, source_frame]
		if viewport_image.save_png(candidate_path) != OK:
			_fail("Could not save F8 source frame %d." % source_frame)
			return
		if source_frame == 3601 or source_frame == 3603:
			var background_image := field_screen._texture.get_image()
			if background_image.save_png(
				"%s/background_%06d.png" % [OUTPUT_ROOT, source_frame]) != OK:
				_fail("Could not capture F8 background layer at source frame %d." % source_frame)
				return
			var modeled_ppu := PackedByteArray()
			modeled_ppu.resize(0x4000)
			modeled_ppu.fill(0)
			for address_variant in field_screen._ppu_memory:
				var address := int(address_variant)
				if address >= 0 and address < modeled_ppu.size():
					modeled_ppu[address] = int(field_screen._ppu_memory[address_variant]) & 0xFF
			var ppu_dump := FileAccess.open(
				"%s/runtime_ppu_%05d.bin" % [OUTPUT_ROOT, source_frame], FileAccess.WRITE)
			if ppu_dump == null:
				_fail("Could not write modeled PPU state at F8 source frame %d." % source_frame)
				return
			ppu_dump.store_buffer(modeled_ppu)
		checkpoints.append({
			"source_frame": source_frame,
			"background_id": int(presenter.state.get("background_id", -1)),
			"animation_ids": presenter.state.get("animation_ids", []).duplicate(),
			"oam_priority_behind_background": bool(
				presenter.state.get("oam_priority_behind_background", false)),
			"chr_1k_banks": field_screen._chr_banks.duplicate(),
			"ram_0079": int(presenter.state.get("ram_0079_value", -1)),
			"ram_007c": int(presenter.state.get("ram_007C_value", -1)),
			"scroll_y": field_screen._scroll_y,
			"raster_events": field_screen._source_raster_events.duplicate(true),
			"f8_title_raster_model": presenter.state.get("f8_title_raster_model", {}).duplicate(true),
		})
	var report_file := FileAccess.open(OUTPUT_ROOT + "/capture_manifest.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write the F8 visible-crop capture manifest.")
		return
	report_file.store_string(JSON.stringify({
		"capture_kind": "current-code diagnostic Godot output; not runtime assets",
		"first_source_frame": FIRST_SOURCE_FRAME,
		"last_source_frame": LAST_SOURCE_FRAME,
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"viewport_size": [256, 240],
		"checkpoints": checkpoints,
	}, "\t") + "\n")
	get_root().remove_child(presenter)
	presenter.free()
	await process_frame
	print("Captured current-code F8 crop audit: %s" % OUTPUT_ROOT)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
