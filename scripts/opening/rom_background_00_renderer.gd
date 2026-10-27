extends Node2D
class_name RomBackground00Renderer
## Standalone renderer for ROM background 0 (Tecmo Theater logo backdrop).
## Reads only byte-preserved, project-owned ROM extracts; never loads the ROM,
## emulator captures, screenshots, or captured video/audio at runtime.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WIDTH := 256
const HEIGHT := 240
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const LAYOUT_PATH := "res://reference/rom_extract/intro/background_00_layout.json"
const NAMETABLE_PATH := "res://reference/rom_extract/intro/background_00_nametable_layout.json"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"

var _texture: ImageTexture
var _chr := PackedByteArray()
var _rgb_palette := PackedByteArray()
var _background_palette := PackedByteArray()
var _palette_override_active := false


func _ready() -> void:
	if _build_background():
		queue_redraw()
	else:
		set_process(false)


func _draw() -> void:
	if _texture != null:
		# The ROM's title band enters the visible frame with coarseY=31/fineY=7
		# (captured $2005 scroll_y=$FF). That wrap places the tile image one pixel
		# lower than its nametable coordinates; sprites use screen-space OAM and
		# must not receive this offset.
		draw_texture(_texture, Vector2(0.0, 1.0))


func set_fade_palette_bytes(palette_bytes: PackedByteArray) -> void:
	if palette_bytes.size() != 16:
		return
	if _background_palette == palette_bytes:
		return
	_background_palette = palette_bytes.duplicate()
	_palette_override_active = true
	if not _chr.is_empty():
		_build_background()


func _build_background() -> bool:
	var layout := _read_json(LAYOUT_PATH)
	if layout.is_empty():
		return false
	var nametable := _read_json(NAMETABLE_PATH)
	if nametable.is_empty():
		return false
	if str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Background 0 layout belongs to a different ROM revision.")
		return false
	if str(layout.get("background_id", "")) != "0x00":
		push_error("This renderer only supports ROM background 0.")
		return false
	if str(nametable.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Background 0 nametable mapping belongs to a different ROM revision.")
		return false

	_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_rgb_palette = FileAccess.get_file_as_bytes(NES_RGB_PATH)
	if _chr.size() != 131072:
		push_error("Extracted CHR stream is missing or has an unexpected size.")
		return false
	if _rgb_palette.size() != 192:
		push_error("External NES RGB palette must contain 64 RGB triples.")
		return false

	if not _palette_override_active:
		var palette_path := "res://" + str(layout.get("palette_source_bin", ""))
		_background_palette = FileAccess.get_file_as_bytes(palette_path)
		if _background_palette.size() != 16:
			push_error("ROM background palette record must contain 16 bytes.")
			return false

	var banks_variant: Variant = layout.get("chr_1k_banks_for_background", [])
	if not banks_variant is Array or banks_variant.size() != 4:
		push_error("Background 0 must define four ordered 1 KiB CHR banks.")
		return false
	var banks: Array = banks_variant
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(_color_for_nes_index(int(_background_palette[0])))

	# F9's static 4x4 blocks do not contain the Tecmo Theater lettering visible
	# in the frame-26 PPU nametable. Use its observed tile IDs as layout data,
	# while decoding every pixel from the original CHR bytes above. This is a
	# project-owned mapping; emulator captures are never loaded at runtime.
	var placements_variant: Variant = nametable.get("tile_placements", [])
	if not placements_variant is Array:
		push_error("Background 0 nametable tile placements are missing.")
		return false
	for placement_variant: Variant in placements_variant:
		if not placement_variant is Dictionary:
			continue
		var placement: Dictionary = placement_variant
		var tile_id := int(placement.get("tile_id", -1))
		var tile_x := int(placement.get("x", -1))
		var tile_y := int(placement.get("y", -1))
		var subpalette := int(placement.get("palette_id", -1))
		if tile_id < 0 or tile_id > 255 or tile_x < 0 or tile_y < 0 or subpalette < 0 or subpalette > 3:
			push_error("Background 0 contains an invalid tile placement.")
			return false
		if tile_x >= 32 or tile_y >= 30:
			# The decoded origin fits within the visible top-left nametable.
			continue
		_draw_tile(image, banks, tile_id, tile_x * 8, tile_y * 8, subpalette)

	_texture = ImageTexture.create_from_image(image)
	queue_redraw()
	return true


func _draw_tile(image: Image, banks: Array, tile_id: int, origin_x: int,
		origin_y: int, subpalette: int) -> void:
	var bank_slot := tile_id >> 6
	var physical_bank := int(banks[bank_slot])
	var pattern_offset := physical_bank * 1024 + (tile_id & 0x3F) * 16
	for y in 8:
		var low_plane := int(_chr[pattern_offset + y])
		var high_plane := int(_chr[pattern_offset + 8 + y])
		for x in 8:
			var bit := 7 - x
			var color := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
			var palette_slot := 0 if color == 0 else subpalette * 4 + color
			image.set_pixel(origin_x + x, origin_y + y,
				_color_for_nes_index(int(_background_palette[palette_slot])))


func _color_for_nes_index(nes_index: int) -> Color:
	var offset := (nes_index & 0x3F) * 3
	return Color(float(_rgb_palette[offset]) / 255.0,
		float(_rgb_palette[offset + 1]) / 255.0,
		float(_rgb_palette[offset + 2]) / 255.0, 1.0)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing ROM-derived background data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid background metadata JSON: %s" % path)
		return {}
	return parsed
