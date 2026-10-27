extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TARGET_FRAME := 662

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := scene.instantiate()
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(instance)
	await process_frame
	instance.set_process(false)
	var presenter = instance.get_node("SourcePresenter")
	presenter.set_process(false)
	var screen = presenter.get_node("FieldScreen")
	screen.set_rendering_enabled(false)
	var frame := int(presenter.state.get("source_frame", 0))
	while frame < TARGET_FRAME:
		presenter._advance_source_frame()
		frame = int(presenter.state.get("source_frame", frame + 1))
	var mem: Dictionary = screen._ppu_memory
	print("FRAME ", frame, " bg ", screen._active_background_id, " scroll ", screen.get_scroll_pixels(), " raster ", screen._source_raster_events)
	print("palette ", screen._background_palette.hex_encode())
	print("banks ", screen._chr_banks, " split ", screen._raster_split_scanline, " chr row3 ", screen._read_chr_pixel(0x6B, 0, 3, screen._chr_banks))
	var image: Image = screen._texture.get_image() if screen._texture != null else null
	if image != null:
		for y in [121, 122, 123, 124, 125, 126, 127, 128]:
			print("pixel ", y, " = ", image.get_pixel(0, y), " tile", screen._ppu_memory.get(0x2000 + int(y / 8) * 32, -1))
	for tx in range(32):
		var address := 0x2000 + 15 * 32 + tx
		print(tx, " tile=", "%02X" % int(mem.get(address, 0)), " attr=", "%02X" % int(mem.get(0x23C0 + 3 * 8 + int(tx / 4), 0)))
	quit()
