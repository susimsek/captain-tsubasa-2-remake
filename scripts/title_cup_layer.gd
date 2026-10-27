extends Sprite2D
## ROM-derived one-frame cup animation used as the title's behind-background
## sprite layer. The original animation exits at tick zero; its OAM survives
## into the title and is shifted/priority-flipped by the title setup code.

const WIDTH: int = 256
const HEIGHT: int = 240
const CHR_SOURCE_PATH: String = "res://reference/rom_extract/chr_rom.2bpp"
const ANIMATION_SOURCE_PATH: String = "res://reference/rom_extract/intro/animation_0D.bin"
const ANIMATION_TIMING_PATH: String = "res://reference/rom_extract/intro/animation_timing_entry.json"
const CUTSCENE_SOURCE_PATH: String = "res://reference/rom_extract/intro/cutscene_00.json"
const SPRITE_FRAME_INDEX_PATH: String = "res://reference/rom_extract/intro/sprite_frames_entry.json"
const SPRITE_PALETTE_PATH: String = "res://reference/rom_extract/intro/animation_0D_sprite_palette.bin"
const RGB_PALETTE_PATH: String = "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"

const TITLE_OAM_Y_ADD: int = 0x30
const OAM_PRIORITY_BIT: int = 0x20
const OAM_HFLIP_BIT: int = 0x40


func _ready() -> void:
	centered = false
	position = Vector2(0, 1)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The ROM toggles OAM attribute bit $20 on every sprite for this title.
	# Put this transparent layer behind the background; the background alpha
	# mask then provides the NES sprite-behind-background behavior.
	z_index = -1
	texture = _build_rom_cup_texture()


func _build_rom_cup_texture() -> Texture2D:
	var animation_bytes := FileAccess.get_file_as_bytes(ANIMATION_SOURCE_PATH)
	var timing_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ANIMATION_TIMING_PATH))
	var cutscene_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUTSCENE_SOURCE_PATH))
	var frame_index_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPRITE_FRAME_INDEX_PATH))
	var chr_bytes := FileAccess.get_file_as_bytes(CHR_SOURCE_PATH)
	var sprite_palette := FileAccess.get_file_as_bytes(SPRITE_PALETTE_PATH)
	var rgb_palette := FileAccess.get_file_as_bytes(RGB_PALETTE_PATH)

	if animation_bytes.size() != 7 or animation_bytes[1] != 0xF1 or animation_bytes[6] != 0xFF:
		push_error("ROM animation 0D source bytes are missing or have an unsupported shape.")
		return null
	if typeof(timing_data) != TYPE_DICTIONARY or typeof(cutscene_data) != TYPE_DICTIONARY \
			or typeof(frame_index_data) != TYPE_DICTIONARY:
		push_error("ROM cutscene, animation timing, or sprite-frame index could not be parsed.")
		return null
	if chr_bytes.size() != 128 * 1024 or sprite_palette.size() != 16 or rgb_palette.size() != 192:
		push_error("ROM-derived CHR or title palette resources have an unexpected size.")
		return null

	var animation := _find_animation(timing_data as Dictionary)
	var cutscene_animation := _find_cutscene_animation(cutscene_data as Dictionary)
	if animation.is_empty() or cutscene_animation.is_empty() \
			or _parse_hex(str(cutscene_animation.get("entry_decode", {}).get("sprite_palette_index", "0x00"))) != animation_bytes[0]:
		push_error("ROM animation 0D bytes do not match the timing descriptor.")
		return null
	var start_y := -1
	var start_x := -1
	var frame_cpu_address := ""
	for command_value in animation.get("commands", []):
		if typeof(command_value) != TYPE_DICTIONARY:
			continue
		var command: Dictionary = command_value
		match str(command.get("kind", "")):
			"set_y_x":
				start_y = int(command.get("y", -1))
				start_x = int(command.get("x", -1))
			"sprite_frame":
				frame_cpu_address = str(command.get("frame_cpu_address", ""))

	if start_y != animation_bytes[2] or start_x != animation_bytes[3]:
		push_error("ROM animation 0D coordinates differ from its decoded timing descriptor.")
		return null
	# Animation frame pointers are encoded as a big-endian offset relative to
	# $8000; this bank's sprite data occupies the $A000-$BFFF CPU window.
	var pointer_from_bytes := ((animation_bytes[4] << 8) | animation_bytes[5]) + 0x2000
	if frame_cpu_address.is_empty() or _parse_hex(frame_cpu_address) != pointer_from_bytes:
		push_error("ROM animation 0D frame pointer differs from its decoded descriptor.")
		return null

	var frame := _find_sprite_frame(frame_index_data as Dictionary, frame_cpu_address)
	if frame.is_empty():
		push_error("ROM animation 0D sprite frame is absent from the decoded frame index.")
		return null
	var selector_values := _parse_hex_bytes(str(frame.get("chr_selectors_hex", "")))
	if selector_values.size() != 4:
		push_error("ROM animation 0D frame does not have four CHR selectors.")
		return null
	var sprite_patterns := PackedByteArray()
	for selector in selector_values:
		var start := selector * 1024
		sprite_patterns.append_array(chr_bytes.slice(start, start + 1024))

	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var sprites: Array = frame.get("sprites", [])
	var origin_x := start_x * 2
	var origin_y := start_y * 2 + TITLE_OAM_Y_ADD
	var behind_background := true
	# NES OAM index zero wins overlaps, so draw from the last descriptor back to
	# the first. Color zero remains transparent within each sprite.
	for sprite_index in range(sprites.size() - 1, -1, -1):
		var sprite_value: Variant = sprites[sprite_index]
		if typeof(sprite_value) != TYPE_DICTIONARY:
			continue
		var sprite: Dictionary = sprite_value
		var x_offset_value: Variant = sprite.get("x_offset_from_animation")
		var y_offset_value: Variant = sprite.get("y_offset_from_animation")
		if x_offset_value == null or y_offset_value == null:
			continue
		var attributes := int(sprite.get("palette_low_bits", 0))
		if bool(sprite.get("flip_h_bit", false)):
			attributes |= OAM_HFLIP_BIT
		# This mirrors the title's $88FB XOR $20 operation.
		attributes ^= OAM_PRIORITY_BIT
		behind_background = behind_background and (attributes & OAM_PRIORITY_BIT) != 0
		_draw_sprite(
			image,
			sprite_patterns,
			sprite_palette,
			rgb_palette,
			_parse_hex(str(sprite.get("tile_id", "0x00"))),
			origin_x + int(x_offset_value),
			origin_y + int(y_offset_value),
			attributes
		)

	if sprites.size() != 63 or not behind_background:
		push_error("ROM title cup descriptor count or priority differs from the traced OAM setup.")
		return null
	return ImageTexture.create_from_image(image)


func _draw_sprite(image: Image, patterns: PackedByteArray, sprite_palette: PackedByteArray,
		rgb_palette: PackedByteArray, tile_id: int, origin_x: int, origin_y: int,
		attributes: int) -> void:
	if tile_id < 0 or tile_id >= 256:
		return
	if origin_y < 0 or origin_y >= 240:
		return
	var tile_offset := tile_id * 16
	var palette_offset := (attributes & 0x03) * 4
	var flip_h := (attributes & OAM_HFLIP_BIT) != 0
	for local_y in range(8):
		var low_plane := patterns[tile_offset + local_y]
		var high_plane := patterns[tile_offset + local_y + 8]
		var screen_y := origin_y + local_y
		if screen_y < 0 or screen_y >= HEIGHT:
			continue
		for local_x in range(8):
			var source_x := 7 - local_x if flip_h else local_x
			var bit := 7 - source_x
			var color_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
			if color_index == 0:
				continue
			var screen_x := origin_x + local_x
			if screen_x < 0 or screen_x >= WIDTH:
				continue
			var nes_color := sprite_palette[palette_offset + color_index] & 0x3F
			var rgb_offset := nes_color * 3
			image.set_pixel(screen_x, screen_y, Color8(
				rgb_palette[rgb_offset],
				rgb_palette[rgb_offset + 1],
				rgb_palette[rgb_offset + 2],
				255
			))


func _find_animation(timing_data: Dictionary) -> Dictionary:
	for animation_value in timing_data.get("animations", []):
		if typeof(animation_value) != TYPE_DICTIONARY:
			continue
		var animation: Dictionary = animation_value
		if str(animation.get("animation_id", "")) == "0x0D":
			return animation
	return {}


func _find_cutscene_animation(cutscene_data: Dictionary) -> Dictionary:
	for animation_value in cutscene_data.get("animations", []):
		if typeof(animation_value) != TYPE_DICTIONARY:
			continue
		var animation: Dictionary = animation_value
		if str(animation.get("id", "")) == "0x0D":
			return animation
	return {}


func _find_sprite_frame(index_data: Dictionary, cpu_address: String) -> Dictionary:
	for frame_value in index_data.get("frames", []):
		if typeof(frame_value) != TYPE_DICTIONARY:
			continue
		var frame: Dictionary = frame_value
		if str(frame.get("cpu_address", "")) == cpu_address:
			return frame
	return {}


func _parse_hex(value: String) -> int:
	var digits := value.trim_prefix("0x").trim_prefix("0X")
	return digits.hex_to_int()


func _parse_hex_bytes(value: String) -> PackedInt32Array:
	var result := PackedInt32Array()
	for token in value.split(" ", false):
		result.append(token.hex_to_int())
	return result
