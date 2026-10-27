extends SceneTree

const PRESENTER_SCENE := preload("res://scenes/prototypes/cold_start_source_command_presenter.tscn")
const MATERIAL_SHADER := preload("res://scripts/opening/rom_ppu_background_renderer.gdshader")
const TARGET_FRAMES: Array[int] = [
	1, 8, 12, 13, 14, 26, 27,
	377, 378, 379, 380, 381, 382, 500, 749, 750, 812, 813, 814, 815,
	1028, 1029, 1030, 1047, 1048, 1108, 1522, 1528, 1529, 1530,
	1759, 1760, 1778, 1779, 1780, 2119, 2120, 2121, 2122,
	2339, 2340, 2341, 2367, 2408,
	2688, 2689, 2690, 2939, 3554, 3555, 3596, 3597, 3598,
]
const WIDTH := 256
const HEIGHT := 240

var _presenter: ColdStartSourceCommandPresenter
var _screen: RomPpuNametableScreenRenderer
var _material := ShaderMaterial.new()
var _line_image: Image
var _ppu_image: Image
var _palette_image: Image
var _line_texture: ImageTexture
var _ppu_texture: ImageTexture
var _palette_texture: ImageTexture
var _render_viewport: SubViewport
var _expected_sha := PackedStringArray()
var _total_differing_rgb := 0
var _max_differing_rgb := 0
var _elapsed_usec := PackedInt64Array()
var _software_elapsed_usec := PackedInt64Array()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	get_root().size = Vector2i(WIDTH, HEIGHT)
	get_root().content_scale_size = Vector2i(WIDTH, HEIGHT)
	_presenter = PRESENTER_SCENE.instantiate() as ColdStartSourceCommandPresenter
	get_root().add_child(_presenter)
	await process_frame
	_presenter.set_process(false)
	_screen = _presenter.get_node("FieldScreen") as RomPpuNametableScreenRenderer
	_screen.set_rendering_enabled(false)
	_screen.set_force_software_renderer_diagnostics(true)
	_presenter.visible = false
	if not _create_material_inputs():
		quit(1)
		return
	_render_viewport = SubViewport.new()
	_render_viewport.size = Vector2i(WIDTH, HEIGHT)
	_render_viewport.transparent_bg = true
	_render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_render_viewport)
	var rect := ColorRect.new()
	rect.position = Vector2.ZERO
	rect.size = Vector2(WIDTH, HEIGHT)
	rect.color = Color.WHITE
	rect.material = _material
	_render_viewport.add_child(rect)
	var preview := TextureRect.new()
	preview.texture = _render_viewport.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.size = Vector2(1024, 960)
	get_root().add_child(preview)
	await process_frame
	await RenderingServer.frame_post_draw
	for frame in TARGET_FRAMES:
		if not _advance_to_frame(frame):
			quit(1)
			return
		var software_started := Time.get_ticks_usec()
		_screen.set_rendering_enabled(true)
		var reference := _screen._texture.get_image()
		var software_done := Time.get_ticks_usec()
		_software_elapsed_usec.append(software_done - software_started)
		_screen.set_rendering_enabled(false)
		var gpu_started := Time.get_ticks_usec()
		var input_started := Time.get_ticks_usec()
		var write_count := _screen._source_mmc3_chr_writes.size()
		if write_count > 8:
			push_error("Frame %d has %d MMC3 writes; shader supports at most 8." % [
				frame, write_count,
			])
			quit(1)
			return
		_update_material_inputs()
		var inputs_done := Time.get_ticks_usec()
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered := _render_viewport.get_texture().get_image()
		if rendered == null:
			push_error("The display renderer did not return a GPU viewport image.")
			quit(1)
			return
		var completed := Time.get_ticks_usec()
		var diff := _count_rgb_differences(rendered, reference)
		_total_differing_rgb += diff
		_max_differing_rgb = maxi(_max_differing_rgb, diff)
		_elapsed_usec.append(completed - gpu_started)
		_expected_sha.append("%d,%02X,%d,%s,%s,%d,%d,%d" % [
			frame, _screen._active_background_id, write_count,
			_sha256(rendered.get_data()), _sha256(reference.get_data()),
			diff, inputs_done - input_started, completed - gpu_started,
		])
	var sorted := _elapsed_usec.duplicate()
	sorted.sort()
	var software_sorted := _software_elapsed_usec.duplicate()
	software_sorted.sort()
	var total := 0
	for value in _elapsed_usec:
		total += value
	var software_total := 0
	for value in _software_elapsed_usec:
		software_total += value
	var hash_file := FileAccess.open("/tmp/opening_gpu_bg_modes_poc_hashes.csv", FileAccess.WRITE)
	if hash_file != null:
		hash_file.store_string("frame,bg_id,mmc3_writes,gpu_sha256,cpu_sha256,rgb_differing_channels,input_usec,total_usec\n")
		hash_file.store_string("\n".join(_expected_sha) + "\n")
	var exact_count := 0
	for row in _expected_sha:
		if int(row.split(",")[5]) == 0:
			exact_count += 1
	print("gpu_bg_mode_samples=%d exact_rgb_frames=%d total_differing_rgb_channels=%d max_frame_diff=%d software_mean_ms=%.3f software_median_ms=%.3f software_p95_ms=%.3f gpu_mean_total_ms=%.3f gpu_median_total_ms=%.3f gpu_p95_total_ms=%.3f csv=/tmp/opening_gpu_bg_modes_poc_hashes.csv" % [
		_elapsed_usec.size(), exact_count,
		_total_differing_rgb, _max_differing_rgb,
		float(software_total) / _software_elapsed_usec.size() / 1000.0,
		float(software_sorted[software_sorted.size() / 2]) / 1000.0,
		float(software_sorted[int(floor((software_sorted.size() - 1) * 0.95))]) / 1000.0,
		float(total) / _elapsed_usec.size() / 1000.0,
		float(sorted[sorted.size() / 2]) / 1000.0,
		float(sorted[int(floor((sorted.size() - 1) * 0.95))]) / 1000.0,
	])
	quit(0)


func _advance_to_frame(target_frame: int) -> bool:
	while int(_presenter.state.get("source_frame", 0)) < target_frame:
		_presenter._advance_source_frame()
		if bool(_presenter.state.get("slice_failed", false)):
			push_error("Presenter failed before source frame %d." % target_frame)
			return false
	return true


func _create_material_inputs() -> bool:
	var source_pixels := _screen._decoded_chr_pixels
	var atlas_bytes := PackedByteArray()
	atlas_bytes.resize(256 * 2048)
	for tile in 8192:
		var tx := (tile & 31) * 8
		var ty := (tile >> 5) * 8
		for py in 8:
			var src := tile * 64 + py * 8
			var dst := (ty + py) * 256 + tx
			for px in 8:
				atlas_bytes[dst + px] = source_pixels[src + px]
	var atlas_image := Image.create_from_data(256, 2048, false, Image.FORMAT_R8, atlas_bytes)
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	if atlas_texture == null:
		push_error("Could not create ROM CHR atlas texture.")
		return false
	_ppu_image = Image.create_from_data(64, 64, false, Image.FORMAT_R8,
		_screen._ppu_memory_bytes)
	_ppu_texture = ImageTexture.create_from_image(_ppu_image)
	_line_image = Image.create(1, HEIGHT, false, Image.FORMAT_RGBAF)
	_palette_image = Image.create(16, 1, false, Image.FORMAT_RGBA8)
	_update_material_inputs()
	_material.shader = MATERIAL_SHADER
	_material.set_shader_parameter("chr_atlas", atlas_texture)
	_material.set_shader_parameter("ppu_bytes", _ppu_texture)
	_material.set_shader_parameter("palette_rgba", _palette_texture)
	_material.set_shader_parameter("scanline_state", _line_texture)
	_update_mmc3_uniforms()
	return true


func _update_material_inputs() -> void:
	_build_scanline_state()
	_build_palette_texture()
	_ppu_image.set_data(64, 64, false, Image.FORMAT_R8, _screen._ppu_memory_bytes)
	if _ppu_texture == null:
		_ppu_texture = ImageTexture.create_from_image(_ppu_image)
	else:
		_ppu_texture.update(_ppu_image)
	if _line_texture == null:
		_line_texture = ImageTexture.create_from_image(_line_image)
	else:
		_line_texture.update(_line_image)
	if _palette_texture == null:
		_palette_texture = ImageTexture.create_from_image(_palette_image)
	else:
		_palette_texture.update(_palette_image)
	if _material.shader != null:
		_material.set_shader_parameter("ppu_bytes", _ppu_texture)
		_material.set_shader_parameter("palette_rgba", _palette_texture)
		_material.set_shader_parameter("scanline_state", _line_texture)
		_update_mmc3_uniforms()


func _build_scanline_state() -> void:
	var fine_x := 0
	var coarse_x_pixels := 0
	var pending_coarse_x_pixels := -1
	var initial_scroll_y := _screen._scroll_y
	var initial_vertical_nametable := _screen._initial_vertical_nametable
	var vertical_coarse_y := (initial_scroll_y >> 3) & 31
	var vertical_fine_y := initial_scroll_y & 7
	var vertical_nametable_y := initial_vertical_nametable & 1
	var raster_index := 0
	var address_origin_scanline := -1
	var address_origin_x := 0
	for y in HEIGHT:
		if pending_coarse_x_pixels >= 0:
			coarse_x_pixels = pending_coarse_x_pixels
			pending_coarse_x_pixels = -1
		while raster_index < _screen._source_raster_events.size():
			var event: Dictionary = _screen._source_raster_events[raster_index]
			var event_line := int(event.get("scanline", -1))
			if event_line > y:
				break
			raster_index += 1
			if event_line < 0 or event_line >= HEIGHT:
				continue
			if str(event.get("kind", "")) == "scroll":
				var scroll_value := int(event.get("scroll_x", 0)) & 255
				fine_x = scroll_value & 7
				var coarse_x := (scroll_value >> 3) & 31
				var initial_latch := event_line == 0 and event.has("scroll_y_base") \
						and event.has("control_value")
				var nt_x := int(event.get("control_nametable_bit", 0)) & 1
				if initial_latch:
					nt_x = int(event.get("ppuctrl_nametable_bit_observed",
						int(event.get("control_value", 0)) & 1)) & 1
					initial_scroll_y = int(event.get("scroll_y_base", initial_scroll_y)) & 255
					initial_vertical_nametable = (int(event.get("control_value", 0)) >> 1) & 1
					coarse_x_pixels = coarse_x * 8 + nt_x * WIDTH
					pending_coarse_x_pixels = -1
					if address_origin_scanline < 0:
						vertical_coarse_y = (initial_scroll_y >> 3) & 31
						vertical_fine_y = initial_scroll_y & 7
						vertical_nametable_y = initial_vertical_nametable
				else:
					pending_coarse_x_pixels = coarse_x * 8 + nt_x * WIDTH
			elif str(event.get("kind", "")) == "ppu_address":
				var address := int(event.get("address", 0)) & 0x3FFF
				address_origin_scanline = y
				address_origin_x = ((address >> 10) & 1) * WIDTH + (address & 0x1F) * 8
				var coarse_y := (address >> 5) & 31
				var fine_y := (address >> 12) & 7
				vertical_coarse_y = coarse_y
				vertical_fine_y = fine_y
				vertical_nametable_y = (address >> 11) & 1
				coarse_x_pixels = 0
				pending_coarse_x_pixels = -1
		var world_x := posmod(_screen._scroll_x + coarse_x_pixels + fine_x, 512)
		if address_origin_scanline >= 0:
			world_x = posmod(address_origin_x + fine_x, 512)
		var packed_line_state := vertical_nametable_y * 8 + fine_x
		_line_image.set_pixel(0, y, Color(world_x, vertical_coarse_y,
			vertical_fine_y, packed_line_state))
		if vertical_fine_y < 7:
			vertical_fine_y += 1
		else:
			vertical_fine_y = 0
			if vertical_coarse_y == 29:
				vertical_coarse_y = 0
				vertical_nametable_y ^= 1
			elif vertical_coarse_y == 31:
				vertical_coarse_y = 0
			else:
				vertical_coarse_y += 1


func _update_mmc3_uniforms() -> void:
	var write_data := PackedVector4Array()
	for source_write: Dictionary in _screen._source_mmc3_chr_writes:
		write_data.append(Vector4(int(source_write["scanline"]),
			int(source_write["dot"]), int(source_write["register"]),
			int(source_write["value"])))
	var write_count := write_data.size()
	while write_data.size() < 8:
		write_data.append(Vector4(-1, 0, 0, 0))
	_material.set_shader_parameter("initial_mmc3_selectors", Vector2(
		_screen._source_mmc3_initial_2k_selectors[0],
		_screen._source_mmc3_initial_2k_selectors[1]))
	_material.set_shader_parameter("mmc3_writes", write_data)
	_material.set_shader_parameter("mmc3_write_count", write_count)
	_material.set_shader_parameter("mmc3_writes_active",
		_screen._source_mmc3_chr_writes_active)
	_material.set_shader_parameter("raster_split_scanline",
		_screen._raster_split_scanline)
	_material.set_shader_parameter("upper_chr_banks", Vector4(
		_screen._chr_banks[0], _screen._chr_banks[1],
		_screen._chr_banks[2], _screen._chr_banks[3]))
	_material.set_shader_parameter("lower_chr_banks", Vector4(
		_screen._lower_chr_banks[0], _screen._lower_chr_banks[1],
		_screen._lower_chr_banks[2], _screen._lower_chr_banks[3]))


func _pack_rgba(value: Vector4i) -> int:
	return (value.x & 255) | ((value.y & 255) << 8) \
		| ((value.z & 255) << 16) | ((value.w & 255) << 24)


func _build_palette_texture() -> void:
	for slot in 16:
		var color_index := int(_screen._background_palette[slot]) & 63
		var offset := color_index * 3
		var alpha := 0 if _screen._sprites_behind_background and slot == 0 else 255
		_palette_image.set_pixel(slot, 0, Color8(_screen._rgb_palette[offset],
			_screen._rgb_palette[offset + 1], _screen._rgb_palette[offset + 2], alpha))


func _count_rgb_differences(first: Image, second: Image) -> int:
	if first == null or second == null or first.get_width() != WIDTH \
			or first.get_height() != HEIGHT or second.get_width() != WIDTH \
			or second.get_height() != HEIGHT:
		return WIDTH * HEIGHT * 3
	var count := 0
	for y in HEIGHT:
		for x in WIDTH:
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if int(round(a.r * 255.0)) != int(round(b.r * 255.0)):
				count += 1
			if int(round(a.g * 255.0)) != int(round(b.g * 255.0)):
				count += 1
			if int(round(a.b * 255.0)) != int(round(b.b * 255.0)):
				count += 1
	return count


func _sha256(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()
