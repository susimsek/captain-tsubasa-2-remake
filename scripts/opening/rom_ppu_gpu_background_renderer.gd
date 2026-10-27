extends Node
## GPU background renderer for ROM-derived opening frames.

const MATERIAL_SHADER := preload("res://scripts/opening/rom_ppu_background_renderer.gdshader")
const SCREEN_WIDTH := 256
const SCREEN_HEIGHT := 240
const CHR_ATLAS_WIDTH := 256
const CHR_ATLAS_HEIGHT := 2048
const MAX_MMC3_WRITES := 8

var last_error := ""
var viewport: SubViewport

var _material := ShaderMaterial.new()
var _line_image: Image
var _ppu_image: Image
var _palette_image: Image
var _line_texture: ImageTexture
var _ppu_texture: ImageTexture
var _palette_texture: ImageTexture


func configure(renderer: Node) -> bool:
	viewport = SubViewport.new()
	viewport.size = Vector2i(SCREEN_WIDTH, SCREEN_HEIGHT)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var rect := ColorRect.new()
	rect.position = Vector2.ZERO
	rect.size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	rect.color = Color.WHITE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _material
	viewport.add_child(rect)

	var source_pixels: PackedByteArray = renderer._decoded_chr_pixels
	if source_pixels.size() != 8192 * 64:
		last_error = "Decoded CHR data has an unexpected size."
		return false
	var atlas_bytes := PackedByteArray()
	atlas_bytes.resize(CHR_ATLAS_WIDTH * CHR_ATLAS_HEIGHT)
	for tile in 8192:
		var tx := (tile & 31) * 8
		var ty := (tile >> 5) * 8
		for py in 8:
			var src := tile * 64 + py * 8
			var dst := (ty + py) * CHR_ATLAS_WIDTH + tx
			for px in 8:
				atlas_bytes[dst + px] = source_pixels[src + px]
	var atlas_image := Image.create_from_data(CHR_ATLAS_WIDTH, CHR_ATLAS_HEIGHT,
		false, Image.FORMAT_R8, atlas_bytes)
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	if atlas_texture == null:
		last_error = "Could not create the ROM CHR atlas."
		return false
	_ppu_image = Image.create_from_data(64, 64, false, Image.FORMAT_R8,
		renderer._ppu_memory_bytes)
	_line_image = Image.create(1, SCREEN_HEIGHT, false, Image.FORMAT_RGBAF)
	_palette_image = Image.create(16, 1, false, Image.FORMAT_RGBA8)
	_ppu_texture = ImageTexture.create_from_image(_ppu_image)
	_line_texture = ImageTexture.create_from_image(_line_image)
	_palette_texture = ImageTexture.create_from_image(_palette_image)
	if _ppu_texture == null or _line_texture == null or _palette_texture == null:
		last_error = "Could not create one or more PPU state textures."
		return false
	_material.shader = MATERIAL_SHADER
	_material.set_shader_parameter("chr_atlas", atlas_texture)
	_material.set_shader_parameter("ppu_bytes", _ppu_texture)
	_material.set_shader_parameter("palette_rgba", _palette_texture)
	_material.set_shader_parameter("scanline_state", _line_texture)
	return true


func update_state(renderer: Node) -> bool:
	last_error = ""
	if _material.shader == null or viewport == null:
		last_error = "GPU background renderer is not configured."
		return false
	if renderer._source_mmc3_chr_writes.size() > MAX_MMC3_WRITES:
		last_error = "Frame has %d MMC3 writes; GPU background renderer supports at most %d." % [
			renderer._source_mmc3_chr_writes.size(), MAX_MMC3_WRITES,
		]
		return false
	_build_scanline_state(renderer)
	_build_palette_texture(renderer)
	_ppu_image.set_data(64, 64, false, Image.FORMAT_R8,
		renderer._ppu_memory_bytes)
	_ppu_texture.update(_ppu_image)
	_line_texture.update(_line_image)
	_palette_texture.update(_palette_image)
	_material.set_shader_parameter("ppu_bytes", _ppu_texture)
	_material.set_shader_parameter("palette_rgba", _palette_texture)
	_material.set_shader_parameter("scanline_state", _line_texture)
	_update_mmc3_uniforms(renderer)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return true


func get_image() -> Image:
	if viewport == null:
		return null
	return viewport.get_texture().get_image()


func _build_scanline_state(renderer: Node) -> void:
	var fine_x := 0
	var coarse_x_pixels := 0
	var pending_coarse_x_pixels := -1
	var initial_scroll_y: int = int(renderer._scroll_y)
	var initial_vertical_nametable: int = int(renderer._initial_vertical_nametable)
	var vertical_coarse_y := (initial_scroll_y >> 3) & 31
	var vertical_fine_y := initial_scroll_y & 7
	var vertical_nametable_y := initial_vertical_nametable & 1
	var raster_index := 0
	var address_origin_scanline := -1
	var address_origin_x := 0
	for y in SCREEN_HEIGHT:
		if pending_coarse_x_pixels >= 0:
			coarse_x_pixels = pending_coarse_x_pixels
			pending_coarse_x_pixels = -1
		while raster_index < renderer._source_raster_events.size():
			var event: Dictionary = renderer._source_raster_events[raster_index]
			var event_line := int(event.get("scanline", -1))
			if event_line > y:
				break
			raster_index += 1
			if event_line < 0 or event_line >= SCREEN_HEIGHT:
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
					coarse_x_pixels = coarse_x * 8 + nt_x * SCREEN_WIDTH
					pending_coarse_x_pixels = -1
					if address_origin_scanline < 0:
						vertical_coarse_y = (initial_scroll_y >> 3) & 31
						vertical_fine_y = initial_scroll_y & 7
						vertical_nametable_y = initial_vertical_nametable
				else:
					pending_coarse_x_pixels = coarse_x * 8 + nt_x * SCREEN_WIDTH
			elif str(event.get("kind", "")) == "ppu_address":
				var address := int(event.get("address", 0)) & 0x3FFF
				address_origin_scanline = y
				address_origin_x = ((address >> 10) & 1) * SCREEN_WIDTH + (address & 0x1F) * 8
				vertical_coarse_y = (address >> 5) & 31
				vertical_fine_y = (address >> 12) & 7
				vertical_nametable_y = (address >> 11) & 1
				coarse_x_pixels = 0
				pending_coarse_x_pixels = -1
		var world_x := posmod(renderer._scroll_x + coarse_x_pixels + fine_x, 512)
		if address_origin_scanline >= 0:
			world_x = posmod(address_origin_x + fine_x, 512)
		_line_image.set_pixel(0, y, Color(world_x, vertical_coarse_y,
			vertical_fine_y, vertical_nametable_y * 8 + fine_x))
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


func _build_palette_texture(renderer: Node) -> void:
	for slot in 16:
		var color_index := int(renderer._background_palette[slot]) & 63
		var offset := color_index * 3
		var alpha := 0 if renderer._sprites_behind_background and slot == 0 else 255
		_palette_image.set_pixel(slot, 0, Color8(renderer._rgb_palette[offset],
			renderer._rgb_palette[offset + 1], renderer._rgb_palette[offset + 2], alpha))


func _update_mmc3_uniforms(renderer: Node) -> void:
	var write_data := PackedVector4Array()
	for source_write: Dictionary in renderer._source_mmc3_chr_writes:
		write_data.append(Vector4(int(source_write["scanline"]),
			int(source_write["dot"]), int(source_write["register"]),
			int(source_write["value"])))
	var write_count := write_data.size()
	while write_data.size() < MAX_MMC3_WRITES:
		write_data.append(Vector4(-1, 0, 0, 0))
	_material.set_shader_parameter("initial_mmc3_selectors", Vector2(
		renderer._source_mmc3_initial_2k_selectors[0],
		renderer._source_mmc3_initial_2k_selectors[1]))
	_material.set_shader_parameter("mmc3_writes", write_data)
	_material.set_shader_parameter("mmc3_write_count", write_count)
	_material.set_shader_parameter("mmc3_writes_active",
		renderer._source_mmc3_chr_writes_active)
	_material.set_shader_parameter("raster_split_scanline", renderer._raster_split_scanline)
	_material.set_shader_parameter("upper_chr_banks", Vector4(
		renderer._chr_banks[0], renderer._chr_banks[1],
		renderer._chr_banks[2], renderer._chr_banks[3]))
	_material.set_shader_parameter("lower_chr_banks", Vector4(
		renderer._lower_chr_banks[0], renderer._lower_chr_banks[1],
		renderer._lower_chr_banks[2], renderer._lower_chr_banks[3]))
