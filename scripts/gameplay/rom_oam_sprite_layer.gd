extends Node2D
class_name GameplayRomOamSpriteLayer
## Static 8x8 NES sprite compositor for a caller-supplied gameplay OAM state.
##
## Pixels are decoded from the project's ROM-derived 2bpp CHR bytes. This node
## never opens the ROM, emulator captures, screenshots, or captured audio. The
## supplied RGB palette is an external NES palette; it is not asserted to be a
## palette stored in the ROM.
##
## Evidence for the initial gameplay snapshot: the FCEUX trace reaches the
## first command-menu state at frame 8953; MMC3 $8000 selects R7 and the
## observed R0-R5 values are $00,$02,$1F,$2E,$0A,$0B. The caller supplies the
## four 1 KiB banks that correspond to the active 8x8 sprite pattern table.
## PPUCTRL's sprite-table select is not inferred here, and no background
## animation/record is assumed. The OAM input is likewise supplied by the
## caller (the reference snapshot is CPU $0200-$02FF), never loaded by this
## renderer. For the final live game it should come from decoded game state.

const NES_WIDTH := 256
const NES_HEIGHT := 240
const OAM_SPRITE_COUNT := 64
const OAM_BYTES_REQUIRED := OAM_SPRITE_COUNT * 4
const NES_RGB_BYTES_REQUIRED := 64 * 3
const SPRITE_PALETTE_BYTES_REQUIRED := 16
const SPRITE_BANK_BYTES := 0x400
const TILE_BYTES := 16
const MAX_SPRITES_PER_SCANLINE := 8

## True when behind-background sprite priority could not be resolved because
## no background opacity mask was supplied to configure().
var priority_behind_background_unresolved := true
var last_error := ""

var _chr_bytes := PackedByteArray()
var _nes_rgb_bytes := PackedByteArray()
var _sprite_palette_bytes := PackedByteArray()
var _oam_bytes := PackedByteArray()
var _sprite_chr_banks_1k: Array[int] = []
var _background_opaque_mask := PackedByteArray()
var _sprite_image: Image
var _sprite_texture: ImageTexture


## Configure and immediately render one static OAM state.
##
## `sprite_chr_banks_1k` maps the four 1 KiB slots of the active 4 KiB NES
## sprite pattern table, indexed by tile bits 7-6. For the observed MMC3 trace,
## R2-R5 are $1F,$2E,$0A,$0B when the sprite table is $1000; pass a verified
## four-bank map appropriate to the PPUCTRL sprite-table selection instead of
## relying on that conditional mapping here.
##
## `background_opaque_mask` is optional and has 256*240 bytes, row-major, with
## nonzero values marking nontransparent background pixels. It lets this
## overlay honor OAM attribute bit 5. If omitted, sprites still render, but
## behind-background occlusion cannot be established by a sprite-only layer.
func configure(
		chr_bytes: PackedByteArray,
		nes_rgb_palette_bytes: PackedByteArray,
		ppu_sprite_palette_bytes: PackedByteArray,
		oam_snapshot_bytes: PackedByteArray,
		sprite_chr_banks_1k: Array[int],
		background_opaque_mask: PackedByteArray = PackedByteArray()
) -> bool:
	_clear_render()
	last_error = ""
	if chr_bytes.is_empty():
		return _fail("ROM-derived CHR data is empty.")
	if nes_rgb_palette_bytes.size() < NES_RGB_BYTES_REQUIRED:
		return _fail("NES RGB palette must contain 64 RGB triples (192 bytes).")
	if ppu_sprite_palette_bytes.size() != SPRITE_PALETTE_BYTES_REQUIRED:
		return _fail("PPU sprite palette must contain exactly 16 bytes.")
	if oam_snapshot_bytes.size() != OAM_BYTES_REQUIRED:
		return _fail("OAM input must contain exactly 64 four-byte entries.")
	if sprite_chr_banks_1k.size() != 4:
		return _fail("Sprite CHR map must contain four 1 KiB bank numbers.")
	if not background_opaque_mask.is_empty() \
			and background_opaque_mask.size() != NES_WIDTH * NES_HEIGHT:
		return _fail("Background opacity mask must be 256x240 bytes or empty.")
	for bank_value in sprite_chr_banks_1k:
		var bank := int(bank_value)
		if bank < 0 or (bank + 1) * SPRITE_BANK_BYTES > chr_bytes.size():
			return _fail("Sprite CHR map points outside the supplied CHR data.")

	_chr_bytes = chr_bytes
	_nes_rgb_bytes = nes_rgb_palette_bytes
	_sprite_palette_bytes = ppu_sprite_palette_bytes
	_oam_bytes = oam_snapshot_bytes
	_sprite_chr_banks_1k = sprite_chr_banks_1k.duplicate()
	_background_opaque_mask = background_opaque_mask
	priority_behind_background_unresolved = _background_opaque_mask.is_empty()
	_render_oam()
	return true


## Replace only the background coverage used by attribute-bit-5 priority.
## Empty data means the background is unknown/transparent for this overlay.
func set_background_opaque_mask(background_opaque_mask: PackedByteArray) -> bool:
	if not background_opaque_mask.is_empty() \
			and background_opaque_mask.size() != NES_WIDTH * NES_HEIGHT:
		last_error = "Background opacity mask must be 256x240 bytes or empty."
		return false
	_background_opaque_mask = background_opaque_mask
	priority_behind_background_unresolved = _background_opaque_mask.is_empty()
	if not _chr_bytes.is_empty():
		_render_oam()
	return true


func rendered_image() -> Image:
	if _sprite_image == null:
		return null
	return _sprite_image


func rendered_texture() -> Texture2D:
	return _sprite_texture


func _draw() -> void:
	if _sprite_texture != null:
		draw_texture(_sprite_texture, Vector2.ZERO)


func _render_oam() -> void:
	var image := Image.create(NES_WIDTH, NES_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var claimed_pixels := PackedByteArray()
	claimed_pixels.resize(NES_WIDTH * NES_HEIGHT)
	claimed_pixels.fill(0)

	# NES OAM evaluation considers only the first eight sprites intersecting each
	# scanline. Keeping OAM order here also preserves first-opaque-sprite priority
	# where sprite rectangles overlap.
	for screen_y in NES_HEIGHT:
		var visible_slots: Array[int] = []
		for slot in OAM_SPRITE_COUNT:
			var oam_offset := slot * 4
			var sprite_top := int(_oam_bytes[oam_offset]) + 1
			if screen_y >= sprite_top and screen_y < sprite_top + 8:
				visible_slots.append(slot)
				if visible_slots.size() == MAX_SPRITES_PER_SCANLINE:
					break

		for slot in visible_slots:
			var offset := slot * 4
			var sprite_top := int(_oam_bytes[offset]) + 1
			var tile_index := int(_oam_bytes[offset + 1])
			var attributes := int(_oam_bytes[offset + 2])
			var sprite_left := int(_oam_bytes[offset + 3])
			var row_in_sprite := screen_y - sprite_top
			if (attributes & 0x80) != 0:
				row_in_sprite = 7 - row_in_sprite
			var chr_offset := _tile_chr_offset(tile_index)
			if chr_offset < 0:
				continue
			var plane_0 := chr_offset + row_in_sprite
			var plane_1 := chr_offset + row_in_sprite + 8
			var palette_number := attributes & 0x03
			var behind_background := (attributes & 0x20) != 0
			var flip_horizontal := (attributes & 0x40) != 0

			for pixel_x in 8:
				var screen_x := sprite_left + pixel_x
				if screen_x < 0 or screen_x >= NES_WIDTH:
					continue
				var destination_index := screen_y * NES_WIDTH + screen_x
				if claimed_pixels[destination_index] != 0:
					continue
				var source_x := 7 - pixel_x if flip_horizontal else pixel_x
				var bit_mask := 1 << (7 - source_x)
				var color_number := (1 if (_chr_bytes[plane_0] & bit_mask) != 0 else 0) \
						| (2 if (_chr_bytes[plane_1] & bit_mask) != 0 else 0)
				if color_number == 0:
					continue

				# The first nontransparent OAM sprite owns this pixel even when its
				# behind-background flag makes the background win the final pixel.
				claimed_pixels[destination_index] = 1
				if behind_background and not _background_opaque_mask.is_empty() \
						and _background_opaque_mask[destination_index] != 0:
					continue
				var palette_address := palette_number * 4 + color_number
				var nes_color := int(_sprite_palette_bytes[palette_address]) & 0x3F
				var rgb_offset := nes_color * 3
				image.set_pixel(screen_x, screen_y, Color(
					float(_nes_rgb_bytes[rgb_offset]) / 255.0,
					float(_nes_rgb_bytes[rgb_offset + 1]) / 255.0,
					float(_nes_rgb_bytes[rgb_offset + 2]) / 255.0,
					1.0))

	_sprite_image = image
	_sprite_texture = ImageTexture.create_from_image(_sprite_image)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _tile_chr_offset(tile_index: int) -> int:
	var bank_slot := (tile_index >> 6) & 0x03
	var bank_number := _sprite_chr_banks_1k[bank_slot]
	var local_tile := tile_index & 0x3F
	var offset := bank_number * SPRITE_BANK_BYTES + local_tile * TILE_BYTES
	if offset + TILE_BYTES > _chr_bytes.size():
		return -1
	return offset


func _clear_render() -> void:
	_chr_bytes = PackedByteArray()
	_nes_rgb_bytes = PackedByteArray()
	_sprite_palette_bytes = PackedByteArray()
	_oam_bytes = PackedByteArray()
	_sprite_chr_banks_1k.clear()
	_background_opaque_mask = PackedByteArray()
	_sprite_image = null
	_sprite_texture = null
	priority_behind_background_unresolved = true
	queue_redraw()


func _fail(message: String) -> bool:
	last_error = message
	return false
