extends Node2D
class_name RomTitleBackgroundRenderer
## Renders title output from ROM-derived PPU packets, CHR and palette.
## The handoff runner models traced packet/frame order, not PPU/NMI subframe cycles.

const SCREEN_WIDTH := 256
const SCREEN_HEIGHT := 240
const TITLE_LAYOUT_PATH := "res://reference/rom_extract/intro/background_17_layout.json"
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const TITLE_SPRITE_PALETTE_PATH := "res://reference/rom_extract/intro/animation_0D_sprite_palette.bin"
const RGB_PALETTE_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const CUP_LAYER_SCRIPT := preload("res://scripts/title_cup_layer.gd")
const TITLE_LOADER_SCRIPT := preload("res://scripts/title_rom_background_loader.gd")
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CHR_SHA256 := "721579f3a3dc2042534de98b24135371fc379958711a168a6861c989a10d85ad"
const TITLE_SPRITE_PALETTE_SHA256 := "7e47683c68602db72d4f3a40bc2e3dc160c5f01c9a5c2cfe8cfc570da42c1c32"
const RGB_PALETTE_SHA256 := "da30843b331e2e4474395866bc9871fcd60a7d716b3c8ee5ce3c89ee46e8c91e"
const TITLE_CHR_SLOT_BANKS: Array[int] = [124, 125, 126, 127, 124, 125, 126, 127]
const TITLE_FIRST_VISIBLE_SCROLL_Y := 0xFF
const TITLE_INITIAL_CURSOR_ADDRESS := 0x220A
const TITLE_CONTINUE_CURSOR_ADDRESS := 0x224A
const TITLE_CURSOR_TILE := 0x7F
const TITLE_CURSOR_CLEAR_ADDRESSES: Array[int] = [0x220A, 0x222A, 0x224A]

@export_range(0, 1, 1) var cursor_selection: int = 0
@export var include_verified_cup_oam: bool = true

var _loader
var _ppu_memory: Dictionary = {}
var _chr := PackedByteArray()
var _background_palette := PackedByteArray()
var _source_background_palette := PackedByteArray()
var _source_sprite_palette := PackedByteArray()
var _ppu_palette_memory := PackedByteArray()
var _rgb_palette := PackedByteArray()
var _frame_texture: ImageTexture
var _cup_texture: Texture2D
var _hidden_cup_layer: Sprite2D
var _render_state: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _load_title_sources():
		return
	_initialize_ppu_memory()
	_apply_title_loader_packets()
	_apply_cursor_state()
	if include_verified_cup_oam and not _load_title_cup_texture():
		return
	_rebuild_frame()


func _draw() -> void:
	if _frame_texture != null:
		draw_texture(_frame_texture, Vector2.ZERO)


## Set the visible endpoint cursor. 0 selects KICK OFF; 1 selects CONTINUE.
## This applies the source-observed final PPU tile state directly; it does not
## simulate the title menu's queue delay or scheduler.
func set_cursor_selection(selection: int) -> void:
	if selection < 0 or selection > 1:
		push_error("Title cursor selection must be 0 (KICK OFF) or 1 (CONTINUE).")
		return
	if cursor_selection == selection and not _ppu_memory.is_empty():
		return
	cursor_selection = selection
	if _ppu_memory.is_empty():
		return
	_apply_cursor_state()
	_rebuild_frame()


## Return the reconstructed PPU nametable/attribute values for diagnostics or
## a future source-timed NMI consumer. Callers receive an independent copy.
func get_ppu_memory_snapshot() -> Dictionary:
	return _ppu_memory.duplicate()


## Return the already ROM-verified title loader packet stream in source order.
func get_source_title_packets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _loader == null:
		return result
	for packet_value in _loader.packets:
		var packet: Dictionary = packet_value
		result.append(packet.duplicate(true))
	return result


## Return the 32 palette bytes rebuilt from title background and animation 0D
## palette records in the supplied ROM. Captured PPU bytes are not consulted.
func get_source_title_palette_bytes() -> PackedByteArray:
	var result := _source_background_palette.duplicate()
	result.append_array(_source_sprite_palette)
	return result


## Start an observable title handoff with cleared nametable and black palette.
## The queue runner applies the ROM-derived packets progressively afterward.
func begin_source_handoff() -> void:
	_initialize_ppu_memory()
	_ppu_palette_memory.resize(32)
	for index in range(_ppu_palette_memory.size()):
		_ppu_palette_memory[index] = 0x0F
	_background_palette = PackedByteArray()
	for _index in range(16):
		_background_palette.append(0x0F)
	_render_state["cursor_selection"] = 0
	_render_state["cursor_ppu_address"] = -1
	_render_state["packet_order_status"] = "progressive ROM queue handoff in progress"
	_render_state["title_handoff_commits"] = []
	_render_state["title_handoff_queue_status"] = "waiting for ROM $8AF7 loader event"


## Apply one source-staged PPU packet at its modeled NMI boundary.
func commit_source_queue_packet(packet: Dictionary) -> void:
	var address := int(packet.get("ppu_address", -1))
	var payload_value: Variant = packet.get("payload", PackedByteArray())
	if typeof(payload_value) != TYPE_PACKED_BYTE_ARRAY:
		push_error("Title handoff queue packet payload is not a byte array.")
		return
	var payload: PackedByteArray = payload_value
	for value in payload:
		if address >= 0x2000 and address < 0x2400:
			_ppu_memory[address] = int(value)
		elif address >= 0x3F00 and address < 0x3F20:
			_ppu_palette_memory[address - 0x3F00] = int(value)
		address += 1
	if int(packet.get("ppu_address", -1)) == 0x3F00 and payload.size() == 32:
		_background_palette = _ppu_palette_memory.slice(0, 16)
	elif int(packet.get("ppu_address", -1)) == TITLE_INITIAL_CURSOR_ADDRESS \
			and payload.size() == 1 and int(payload[0]) == TITLE_CURSOR_TILE:
		_render_state["cursor_selection"] = 0
		_render_state["cursor_ppu_address"] = TITLE_INITIAL_CURSOR_ADDRESS
	elif int(packet.get("ppu_address", -1)) == TITLE_CONTINUE_CURSOR_ADDRESS \
			and payload.size() == 1 and int(payload[0]) == TITLE_CURSOR_TILE:
		_render_state["cursor_selection"] = 1
		_render_state["cursor_ppu_address"] = TITLE_CONTINUE_CURSOR_ADDRESS
	var commits: Array = _render_state.get("title_handoff_commits", [])
	commits.append({
		"ppu_address": int(packet.get("ppu_address", -1)),
		"payload_size": payload.size(),
		"kind": str(packet.get("kind", "source")),
	})
	_render_state["title_handoff_commits"] = commits


## Finalize the handoff after the palette/cursor NMI packet commits.
func complete_source_handoff() -> void:
	_render_state["packet_order_status"] = "ROM-stepper CPU-cycle events drive source-capacity waits, 240 background consumers, and palette/cursor consumers"
	_render_state["title_handoff_queue_status"] = "complete after source event 242; post-DMC CPU-cycle offsets, physical 2C02 output-dot timing, and input-poll phase remain unresolved"
	_rebuild_frame()


## Return the current 256×240 ROM-CHR endpoint texture.
func get_frame_texture() -> Texture2D:
	return _frame_texture


func get_render_state() -> Dictionary:
	return _render_state.duplicate(true)


func _load_title_sources() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TITLE_LAYOUT_PATH))
	if not parsed is Dictionary:
		push_error("Title background layout metadata is missing or malformed.")
		return false
	var layout: Dictionary = parsed
	if str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Title background metadata belongs to a different ROM revision.")
		return false

	_loader = TITLE_LOADER_SCRIPT.new()
	if not _loader.build_packets():
		return false
	_background_palette = _loader.palette_bytes.duplicate()
	_source_background_palette = _background_palette.duplicate()
	_source_sprite_palette = FileAccess.get_file_as_bytes(TITLE_SPRITE_PALETTE_PATH)
	_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_rgb_palette = FileAccess.get_file_as_bytes(RGB_PALETTE_PATH)
	if _chr.size() != 128 * 1024 or _sha256_hex(_chr) != CHR_SHA256:
		push_error("Title renderer CHR bytes are not the preserved ROM extract.")
		return false
	if _background_palette.size() != 16:
		push_error("Title renderer needs the ROM's 16-byte background palette.")
		return false
	if _source_sprite_palette.size() != 16 \
			or _sha256_hex(_source_sprite_palette) != TITLE_SPRITE_PALETTE_SHA256:
		push_error("Title renderer sprite palette differs from the preserved ROM animation-0D record.")
		return false
	if _rgb_palette.size() != 192 or _sha256_hex(_rgb_palette) != RGB_PALETTE_SHA256:
		push_error("Title renderer NES RGB table differs from the documented FCEUX palette.")
		return false
	if _loader.chr_1k_banks != [124, 125, 126, 127]:
		push_error("Title renderer received unexpected ROM CHR banks.")
		return false
	_render_state = {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"background_id": 0x17,
		"record_file_offset": _loader.record_file_offset,
		"block_page_selector": _loader.block_page_selector,
		"block_page_offset": _loader.block_page_offset,
		"block_page_base_file_offset": _loader.block_page_base_file_offset,
		"block_page_ppu_snapshot_crosscheck": "815/816 bytes match frame 4692; remaining $2208 difference is the expected $7F cursor overlay at $220A",
		"palette_file_offset": _loader.palette_file_offset,
		"sprite_palette_file_offset": "0x00D3A0",
		"sprite_palette_sha256": TITLE_SPRITE_PALETTE_SHA256,
		"chr_file_offset": "0x40010",
		"chr_1k_banks_by_ppu_slot": TITLE_CHR_SLOT_BANKS.duplicate(),
		"packet_count": _loader.packets.size(),
		"payload_bytes": _loader.payload_byte_count,
		"queue_encoded_bytes_estimate": _loader.queue_encoded_byte_count,
		"endpoint_source_frame": 4692,
		"scroll_y_source_value": TITLE_FIRST_VISIBLE_SCROLL_Y,
		"first_scanline_method": "coarseY=31/fineY=7; tile IDs read from PPU $23E0-$23FF",
		"first_scanline_verified_pixels": 256,
		"cursor_selection": cursor_selection,
		"cup_oam_enabled": include_verified_cup_oam,
		"packet_order_status": "ROM-derived $17 loader packets are progressively staged and consumed from the ROM-stepper event schedule",
		"handoff_event_resource": "assets/opening/rom_logic/title_handoff_source_events.json",
		"handoff_timing_limit": "ROM instruction/event order is source-derived; post-frame-367 CPU cycle offsets omit DMC DMA stalls and are approximate",
		"raster_status": "endpoint scroll-$FF first scanline modeled; no cycle-accurate raster or MMC3 pipeline",
		"oam_status": "title animation $0D descriptor/palette and $890C/$88FB transforms reused when enabled",
	}
	return true


func _initialize_ppu_memory() -> void:
	_ppu_memory.clear()
	# The title record writes the first nametable only. Missing positions in this
	# endpoint model begin at the reset/cleared value and therefore use tile $00.
	for address in range(0x2000, 0x2400):
		_ppu_memory[address] = 0
	_ppu_palette_memory.resize(32)
	for index in range(16):
		_ppu_palette_memory[index] = _source_background_palette[index]
		_ppu_palette_memory[index + 16] = _source_sprite_palette[index]


func _apply_title_loader_packets() -> void:
	for packet_value in _loader.packets:
		var packet: Dictionary = packet_value
		var address := int(packet["ppu_address"])
		var payload: PackedByteArray = packet["payload"]
		for value in payload:
			if address >= 0x2000 and address < 0x2400:
				_ppu_memory[address] = int(value)
			address += 1


func _apply_cursor_state() -> void:
	for address in TITLE_CURSOR_CLEAR_ADDRESSES:
		_ppu_memory[address] = 0
	var cursor_address := TITLE_INITIAL_CURSOR_ADDRESS if cursor_selection == 0 \
			else TITLE_CONTINUE_CURSOR_ADDRESS
	_ppu_memory[cursor_address] = TITLE_CURSOR_TILE
	_render_state["cursor_selection"] = cursor_selection
	_render_state["cursor_ppu_address"] = cursor_address


func _load_title_cup_texture() -> bool:
	# The hidden helper runs its source-derived animation/OAM decoder once. Its
	# transparent ROM-CHR texture is sampled into the final frame so priority is
	# resolved against background pattern color zero below.
	_hidden_cup_layer = Sprite2D.new()
	_hidden_cup_layer.name = "HiddenVerifiedTitleCupOAM"
	_hidden_cup_layer.set_script(CUP_LAYER_SCRIPT)
	_hidden_cup_layer.visible = false
	add_child(_hidden_cup_layer)
	_cup_texture = _hidden_cup_layer.texture
	if _cup_texture == null:
		push_error("Could not create the ROM-derived title cup OAM texture.")
		return false
	return true


func _rebuild_frame() -> void:
	if _chr.is_empty() or _background_palette.size() != 16 or _rgb_palette.size() != 192:
		return
	var image := Image.create(SCREEN_WIDTH, SCREEN_HEIGHT, false, Image.FORMAT_RGBA8)
	var universal_color := _nes_color(int(_background_palette[0]))
	image.fill(universal_color)
	var background_color_indices := PackedByteArray()
	background_color_indices.resize(SCREEN_WIDTH * SCREEN_HEIGHT)

	for screen_y in SCREEN_HEIGHT:
		for screen_x in SCREEN_WIDTH:
			var tile_id: int
			var tile_column := int(screen_x / 8)
			var tile_row := -1
			var pixel_x := screen_x % 8
			var pixel_y: int
			var attribute: int
			var quadrant_x: int
			var quadrant_y: int
			if screen_y == 0:
				# At $2005=$FF, the observed title endpoint begins at coarse Y 31,
				# fine Y 7. Nametable fetches therefore read tile IDs from the final
			# 32 bytes of the attribute-table range, as confirmed in the source
			# frame-4692 PPU/raster plan.
				tile_id = int(_ppu_memory.get(0x23E0 + tile_column, 0)) & 0xFF
				pixel_y = 7
				attribute = int(_ppu_memory.get(0x23F8 + int(tile_column / 4), 0)) & 0xFF
				quadrant_x = int((tile_column % 4) / 2)
				quadrant_y = 1
			else:
				# Lines 1–239 are the ordinary nametable view shifted down one row.
				var source_y := screen_y - 1
				tile_row = int(source_y / 8)
				pixel_y = source_y % 8
				tile_id = int(_ppu_memory.get(0x2000 + tile_row * 32 + tile_column, 0)) & 0xFF
				attribute = int(_ppu_memory.get(
					0x23C0 + int(tile_row / 4) * 8 + int(tile_column / 4), 0)) & 0xFF
				quadrant_x = int((tile_column % 4) / 2)
				quadrant_y = int((tile_row % 4) / 2)

			var palette_shift := (quadrant_y * 2 + quadrant_x) * 2
			var subpalette := (attribute >> palette_shift) & 0x03
			var color_index := _read_chr_pixel(tile_id, pixel_x, pixel_y)
			var output_index := screen_y * SCREEN_WIDTH + screen_x
			background_color_indices[output_index] = color_index
			if color_index != 0:
				var palette_slot := subpalette * 4 + color_index
				image.set_pixel(screen_x, screen_y,
					_nes_color(int(_background_palette[palette_slot])))

	if include_verified_cup_oam and _cup_texture != null:
		_composite_behind_background_cup(image, background_color_indices)

	_frame_texture = ImageTexture.create_from_image(image)
	_render_state["frame_size"] = Vector2i(SCREEN_WIDTH, SCREEN_HEIGHT)
	_render_state["cursor_selection"] = cursor_selection
	queue_redraw()


func _composite_behind_background_cup(image: Image,
		background_color_indices: PackedByteArray) -> void:
	var cup_image := _cup_texture.get_image()
	if cup_image == null or cup_image.get_width() != SCREEN_WIDTH or cup_image.get_height() != SCREEN_HEIGHT:
		push_error("ROM-derived title cup texture has an unexpected size.")
		return
	# The ROM applies $890C to cup OAM and $88FB sets sprite-behind-background.
	# The existing ROM-derived sprite renderer bakes the OAM geometry and one-
	# pixel title placement into this transparent 256×240 helper texture.
	for screen_y in range(1, SCREEN_HEIGHT):
		var cup_y := screen_y - 1
		for screen_x in SCREEN_WIDTH:
			var output_index := screen_y * SCREEN_WIDTH + screen_x
			if background_color_indices[output_index] != 0:
				continue
			var cup_color := cup_image.get_pixel(screen_x, cup_y)
			if cup_color.a > 0.0:
				image.set_pixel(screen_x, screen_y, cup_color)


func _read_chr_pixel(tile_id: int, pixel_x: int, pixel_y: int) -> int:
	var bank_slot := tile_id >> 6
	var physical_bank := TITLE_CHR_SLOT_BANKS[bank_slot]
	var pattern_offset := physical_bank * 1024 + (tile_id & 0x3F) * 16
	var bit := 7 - pixel_x
	var low_plane := int(_chr[pattern_offset + pixel_y])
	var high_plane := int(_chr[pattern_offset + 8 + pixel_y])
	return ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)


func _nes_color(nes_index: int) -> Color:
	var offset := (nes_index & 0x3F) * 3
	return Color8(_rgb_palette[offset], _rgb_palette[offset + 1], _rgb_palette[offset + 2], 255)


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK:
		return ""
	hasher.update(bytes)
	return hasher.finish().hex_encode()
