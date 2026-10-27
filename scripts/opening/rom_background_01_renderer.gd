extends Node2D
class_name RomBackground01Renderer
## Decodes the ROM's background-01 field layout into a two-nametable atlas.
## This is a source-data renderer prototype, not a complete NES screen renderer:
## scroll, mirroring, raster CHR changes and sprites are deliberately separate.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ATLAS_WIDTH := 512
const ATLAS_HEIGHT := 128
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const LAYOUT_PATH := "res://reference/rom_extract/intro/background_01_layout.json"
const RECORD_PATH := "res://reference/rom_extract/intro/background_01.bin"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"

var _texture: ImageTexture
var _chr := PackedByteArray()
var _rgb_palette := PackedByteArray()
var _background_palette := PackedByteArray()
var _palette_override_active := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _build_atlas():
		set_process(false)


func _draw() -> void:
	if _texture != null:
		draw_texture(_texture, Vector2.ZERO)


func set_fade_palette_bytes(palette_bytes: PackedByteArray) -> void:
	if palette_bytes.size() != 16 or _background_palette == palette_bytes:
		return
	_background_palette = palette_bytes.duplicate()
	_palette_override_active = true
	if not _chr.is_empty():
		_build_atlas()


func _build_atlas() -> bool:
	var layout := _read_json(LAYOUT_PATH)
	if layout.is_empty():
		return false
	if str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Background 1 layout belongs to a different ROM revision.")
		return false
	if str(layout.get("background_id", "")) != "0x01":
		push_error("This renderer only supports ROM background 1.")
		return false

	_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_rgb_palette = FileAccess.get_file_as_bytes(NES_RGB_PATH)
	if _chr.size() != 131072:
		push_error("Extracted CHR stream is missing or has an unexpected size.")
		return false
	if _rgb_palette.size() != 192:
		push_error("External NES RGB palette must contain 64 RGB triples.")
		return false

	var record := FileAccess.get_file_as_bytes(RECORD_PATH)
	var expected_record := _parse_hex_bytes(str(layout.get("record_raw_hex", "")))
	if record.is_empty() or record != expected_record:
		push_error("Background 1 record bytes do not match the ROM-derived layout metadata.")
		return false

	if not _palette_override_active:
		var palette_path := "res://" + str(layout.get("palette_source_bin", ""))
		_background_palette = FileAccess.get_file_as_bytes(palette_path)
		var expected_palette := _parse_hex_bytes(str(layout.get("palette_raw_hex", "")))
		if _background_palette.size() != 16 or _background_palette != expected_palette:
			push_error("Background 1 palette bytes do not match the ROM-derived metadata.")
			return false

	var banks_variant: Variant = layout.get("chr_1k_banks_for_background", [])
	if not banks_variant is Array or banks_variant.size() != 4:
		push_error("Background 1 must define four ordered 1 KiB CHR banks.")
		return false
	var banks: Array = banks_variant
	for bank_variant in banks:
		var bank := int(bank_variant)
		if bank < 0 or bank >= 128:
			push_error("Background 1 contains an invalid CHR bank index.")
			return false

	var placements_variant: Variant = layout.get("tile_placements", [])
	if not placements_variant is Array or placements_variant.is_empty():
		push_error("Background 1 tile placements are missing.")
		return false
	var image := Image.create(ATLAS_WIDTH, ATLAS_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(_color_for_nes_index(int(_background_palette[0])))
	for placement_variant: Variant in placements_variant:
		if not placement_variant is Dictionary:
			push_error("Background 1 contains a malformed tile placement.")
			return false
		var placement: Dictionary = placement_variant
		var tile_id := int(placement.get("tile_id", -1))
		var tile_x := int(placement.get("x", -1))
		var tile_y := int(placement.get("y", -1))
		var subpalette := int(placement.get("palette_id", -1))
		if tile_id < 0 or tile_id > 255 or tile_x < 0 or tile_x >= 64 \
				or tile_y < 0 or tile_y >= 16 or subpalette < 0 or subpalette > 3:
			push_error("Background 1 contains an invalid tile placement.")
			return false
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
			var color_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
			var palette_slot := 0 if color_index == 0 else subpalette * 4 + color_index
			image.set_pixel(origin_x + x, origin_y + y,
				_color_for_nes_index(int(_background_palette[palette_slot])))


func _color_for_nes_index(nes_index: int) -> Color:
	var offset := (nes_index & 0x3F) * 3
	return Color(float(_rgb_palette[offset]) / 255.0,
		float(_rgb_palette[offset + 1]) / 255.0,
		float(_rgb_palette[offset + 2]) / 255.0, 1.0)


func _parse_hex_bytes(hex_text: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in hex_text.split(" ", false):
		var value := token.strip_edges()
		if value.is_empty():
			continue
		var parsed := value.hex_to_int()
		if parsed < 0 or parsed > 0xFF:
			return PackedByteArray()
		result.append(parsed)
	return result


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing ROM-derived background data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid background metadata JSON: %s" % path)
		return {}
	return parsed
