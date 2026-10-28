extends Node2D
class_name RomMeetingMenuCursor
## ROM-derived OAM cursor overlay for the pre-match MEETING menu.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CURSOR_DESCRIPTOR_PATH := "res://reference/rom_extract/gameplay/meeting_menu/bank1_menu_cursor_descriptor.bin"
const CURSOR_DESCRIPTOR_SHA256 := "93f65165d1ebdb4e44d6ca61121308c647ca300d9c4e236bbb4c57c4663fb567"
const PALETTE_TABLE_PATH := "res://reference/rom_extract/intro/sprite_palette_table_00_3F.bin"
const PALETTE_METADATA_PATH := "res://reference/rom_extract/intro/sprite_palette_table_00_3F.json"
const PALETTE_TABLE_SHA256 := "38d295f70e1ebe934f2eef84910b5f555943f07283fe158db4dcf64ef00657c2"
const ANIMATION_RECORD_PATH := "res://reference/rom_extract/gameplay/animations/kickoff/animation_3B.bin"
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const OAM_LAYER_SCRIPT := preload("res://scripts/gameplay/rom_oam_sprite_layer.gd")

var cursor_y := 0x98
var last_error := ""

var _oam_layer: GameplayRomOamSpriteLayer
var _descriptor := PackedByteArray()
var _sprite_palette := PackedByteArray()
var _chr := PackedByteArray()
var _nes_rgb := PackedByteArray()
var _sprite_banks: Array[int] = [0x78, 0x79, 0x7A, 0x7B]


func _ready() -> void:
	visible = false
	_oam_layer = OAM_LAYER_SCRIPT.new() as GameplayRomOamSpriteLayer
	_oam_layer.name = "RomMeetingMenuCursorOam"
	add_child(_oam_layer)
	_oam_layer.position = Vector2.ZERO
	_load_rom_resources()
	_apply_cursor()


func set_cursor_y(new_y: int) -> bool:
	if new_y < 0x98 or new_y > 0xC8 or (new_y - 0x98) % 0x10 != 0:
		last_error = "MEETING cursor Y must be one of the ROM rows $98/$A8/$B8/$C8."
		return false
	cursor_y = new_y
	return _apply_cursor()


func _load_rom_resources() -> bool:
	last_error = ""
	_descriptor = FileAccess.get_file_as_bytes(CURSOR_DESCRIPTOR_PATH)
	_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_nes_rgb = FileAccess.get_file_as_bytes(NES_RGB_PATH)
	var palette_table := FileAccess.get_file_as_bytes(PALETTE_TABLE_PATH)
	var animation_record := FileAccess.get_file_as_bytes(ANIMATION_RECORD_PATH)
	if _sha256(_descriptor) != CURSOR_DESCRIPTOR_SHA256:
		return _fail("MEETING cursor descriptor differs from the target ROM extract.")
	if _sha256(palette_table) != PALETTE_TABLE_SHA256:
		return _fail("ROM sprite palette table $00-$3F failed its source hash check.")
	var palette_meta_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_METADATA_PATH))
	if not palette_meta_variant is Dictionary \
			or str(palette_meta_variant.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("ROM sprite palette table metadata belongs to another source ROM.")
	if _descriptor.size() != 6 or animation_record.is_empty() or animation_record[0] != 0x0A:
		return _fail("MEETING cursor or speaker-animation palette selectors are malformed.")
	if _chr.size() != 131072 or _nes_rgb.size() != 192:
		return _fail("ROM CHR or documented NES RGB palette is missing.")
	_sprite_palette = palette_table.slice(int(animation_record[0]) * 16, int(animation_record[0]) * 16 + 16)
	if _sprite_palette.size() != 16:
		return _fail("Scene $44 sprite palette $0A is absent from the ROM table.")
	return true


func _apply_cursor() -> bool:
	if _oam_layer == null or _descriptor.size() != 6 or _sprite_palette.size() != 16:
		return false
	var oam := PackedByteArray()
	oam.resize(256)
	for sprite_index in 64:
		var offset := sprite_index * 4
		oam[offset] = 0xF8
		oam[offset + 1] = 0x00
		oam[offset + 2] = 0x00
		oam[offset + 3] = 0x00
	var oam_offset := int(_descriptor[0])
	if oam_offset + 3 >= oam.size() or oam_offset % 4 != 0:
		return _fail("ROM cursor descriptor has an invalid OAM shadow offset.")
	oam[oam_offset] = cursor_y
	oam[oam_offset + 1] = int(_descriptor[2])
	oam[oam_offset + 2] = int(_descriptor[3])
	oam[oam_offset + 3] = int(_descriptor[4])
	if not _oam_layer.configure(_chr, _nes_rgb, _sprite_palette, oam, _sprite_banks):
		return _fail("ROM cursor OAM renderer rejected its source data: " + _oam_layer.last_error)
	return true


func _sha256(bytes: PackedByteArray) -> String:
	if bytes.is_empty():
		return ""
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	push_error(message)
	return false
