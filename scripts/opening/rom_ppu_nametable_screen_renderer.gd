extends Node2D
class_name RomPpuNametableScreenRenderer
## Draws one 256x240 view from ROM-derived CHR data and emulated PPU nametable
## bytes. This is a screen-view prototype, not a cycle-accurate NES PPU.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CHR_SHA256 := "721579f3a3dc2042534de98b24135371fc379958711a168a6861c989a10d85ad"
const RGB_PALETTE_SHA256 := "da30843b331e2e4474395866bc9871fcd60a7d716b3c8ee5ce3c89ee46e8c91e"
const SCREEN_WIDTH := 256
const SCREEN_HEIGHT := 240
const WORLD_WIDTH := 512
const NAMETABLE_0 := 0x2000
const NAMETABLE_1 := 0x2400
const NAMETABLE_BYTES := 0x400
const PHYSICAL_NAMETABLE_RAM_BYTES := 0x800
const ATTRIBUTE_OFFSET := 0x3C0
const BG08_BACKGROUND_ID := 0x08
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const INTRO_DATA_ROOT := "res://reference/rom_extract/intro"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const BG0B_BACKGROUND_ID := 0x0B
const BG09_BACKGROUND_ID := 0x09
const BG0B_INITIAL_PPUCTRL := 0x88
const BG0B_INITIAL_SCROLL_Y := 0xFF
const BG0B_ADDRESS_RELOAD_SCANLINE := 129
const BG0B_LOWER_SPLIT_SCANLINE := 130
# Representative line-130 bus writes from source frame 3000: R0 data at dot
# 146 and R1 data at dot 197. Other captured frames vary by a few dots.
const BG0B_R0_WRITE_DOT_CANDIDATE := 146
const BG0B_R1_WRITE_DOT_CANDIDATE := 197
const BG09_INITIAL_PPUCTRL := 0x88
const BG09_INITIAL_SCROLL_Y := 0xFF
const BG09_ADDRESS_RELOAD_SCANLINE := 129
const BG09_LOWER_SPLIT_SCANLINE := 130
# Representative source-frame 2018 dots. Frames 2040 and 2116 measure 146/197
# and 149/200 respectively; the exact first affected pixel is still unresolved.
const BG09_R0_WRITE_DOT_CANDIDATE := 146
const BG09_R1_WRITE_DOT_CANDIDATE := 197
const BG08_INITIAL_PPUCTRL := 0x88
const BG08_INITIAL_SCROLL_X := 0x00
const BG08_INITIAL_SCROLL_Y := 0xFF
const ROW_CHUNK_CACHE_LIMIT := 8192
const ROW_CHUNK_TILE_ROWS := 8
const GPU_BACKGROUND_RENDERER_SCRIPT := preload("res://scripts/opening/rom_ppu_gpu_background_renderer.gd")

var _ppu_memory: Dictionary = {}
var _ppu_memory_bytes := PackedByteArray()
var _nametable_ram_power_on := PackedByteArray()
var _background_palette := PackedByteArray()
var _chr := PackedByteArray()
var _decoded_chr_pixels := PackedByteArray()
var _chr_banks: Array[int] = [60, 61, 62, 63]
var _lower_chr_banks: Array[int] = [0, 1, 2, 3]
var _raster_split_scanline := 134
var _rgb_palette := PackedByteArray()
var _nes_rgba32_colors := PackedInt64Array()
var _scroll_x := 0
var _scroll_y := 0
var _active_background_id := 0x01
var _active_data_root := INTRO_DATA_ROOT
var _sprites_behind_background := false
var _source_raster_events: Array[Dictionary] = []
## Select the legacy dictionary path only for paired renderer profiling.
var use_dictionary_ppu_lookups_diagnostics := false
var _source_mmc3_chr_writes: Array[Dictionary] = []
var _source_mmc3_initial_2k_selectors: Array[int] = [0, 0]
var _source_mmc3_chr_writes_active := false
var _rendering_enabled := true
## The ROM-derived GPU path is the normal renderer. Diagnostics can force the
## software implementation to compare identical source states.
var use_gpu_background_renderer := true
var force_software_renderer_diagnostics := false
var gpu_background_fallback_count := 0
var gpu_background_fallback_reason := ""
var _gpu_background_renderer: Node
var _gpu_background_texture: Texture2D
var _initial_vertical_nametable := 0
var _state_update_depth := 0
var _redraw_pending := false
## Diagnostic-only fallback to the slower per-pixel renderer. Native row blits
## are the default path; enable this only for comparison captures.
var use_pixel_loop_diagnostics := false
## Appends cached ROM-derived RGBA tile-row spans to one image buffer.
var use_packed_row_copy := true
var _tile_row_blit_cache: Dictionary = {}
var _tile_row_byte_cache: Dictionary = {}
## Diagnostic-only cache that joins up to eight consecutive full tile rows before
## appending them to the output buffer. The default path remains per-span.
var use_row_chunk_cache_diagnostics := false
var _tile_row_chunk_byte_cache: Dictionary = {}
var _row_chunk_cache_hits := 0
var _row_chunk_cache_misses := 0
var _texture: ImageTexture
var _last_software_render_image: Image


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _gpu_background_renderer_supported():
		use_gpu_background_renderer = false
	_ppu_memory_bytes.resize(0x1000)
	_ppu_memory_bytes.fill(0)
	# Pinned FCEUX 2.7.0's power-on path calls FCEU_MemoryRand(NTARAM, 0x800,
	# true); with its default RAMInitOption=0 this initializes 2 KiB of nametable
	# RAM to zero. Match that emulator baseline while keeping physical hardware
	# power-on contents explicitly unresolved.
	_nametable_ram_power_on.resize(PHYSICAL_NAMETABLE_RAM_BYTES)
	_nametable_ram_power_on.fill(0)
	if not _load_rom_resources():
		set_process(false)
		return
	_redraw_screen()


func _draw() -> void:
	if use_gpu_background_renderer and _gpu_background_texture != null:
		draw_texture(_gpu_background_texture, Vector2.ZERO)
		return
	if _texture != null:
		draw_texture(_texture, Vector2.ZERO)


func set_force_software_renderer_diagnostics(enabled: bool) -> void:
	if force_software_renderer_diagnostics == enabled:
		return
	force_software_renderer_diagnostics = enabled
	if enabled:
		use_gpu_background_renderer = false
	else:
		use_gpu_background_renderer = _gpu_background_renderer_supported()
		if use_gpu_background_renderer:
			gpu_background_fallback_reason = ""
			_ensure_gpu_background_renderer()
	_request_redraw()


func get_gpu_background_image() -> Image:
	if _gpu_background_renderer == null:
		return null
	return _gpu_background_renderer.get_image()


## Diagnostic background readback for headless frame comparisons. This omits
## CanvasItem sprites, which are composed by the scene viewport separately.
func get_rendered_background_image() -> Image:
	if use_gpu_background_renderer:
		return get_gpu_background_image()
	return _last_software_render_image


func _ensure_gpu_background_renderer() -> bool:
	if not _gpu_background_renderer_supported():
		return false
	if _gpu_background_renderer != null:
		return true
	_gpu_background_renderer = GPU_BACKGROUND_RENDERER_SCRIPT.new()
	_gpu_background_renderer.name = "RomPpuGpuBackgroundRenderer"
	add_child(_gpu_background_renderer)
	if not _gpu_background_renderer.configure(self):
		gpu_background_fallback_reason = _gpu_background_renderer.last_error
		push_warning("GPU background renderer setup failed; using software renderer: %s" % gpu_background_fallback_reason)
		_gpu_background_renderer.queue_free()
		_gpu_background_renderer = null
		return false
	return true


func _gpu_background_renderer_supported() -> bool:
	if DisplayServer.get_name() == "headless":
		gpu_background_fallback_reason = "headless display server"
		return false
	var rendering_method := RenderingServer.get_current_rendering_method()
	if rendering_method != "gl_compatibility":
		gpu_background_fallback_reason = \
			"GPU background renderer is parity-checked only for gl_compatibility; current method: %s" % rendering_method
		return false
	return true


func _fallback_to_software_renderer(reason: String) -> void:
	if not use_gpu_background_renderer:
		return
	use_gpu_background_renderer = false
	gpu_background_fallback_count += 1
	gpu_background_fallback_reason = reason
	push_warning("GPU background renderer fell back to software: %s" % reason)


## Suspend expensive texture rebuilds while a source-state replay advances
## through intermediate frames. Enabling rendering rebuilds the current frame.
func set_rendering_enabled(enabled: bool) -> void:
	if _rendering_enabled == enabled:
		return
	_rendering_enabled = enabled
	if _rendering_enabled:
		_request_redraw()


## Batch ROM state setters while one source frame is assembled. The final image
## is produced once after the caller applies all frame-edge PPU state.
func begin_state_update() -> void:
	_state_update_depth += 1


func end_state_update() -> void:
	if _state_update_depth <= 0:
		push_error("PPU renderer state update ended without a matching begin.")
		return
	_state_update_depth -= 1
	if _state_update_depth == 0 and _redraw_pending:
		_redraw_pending = false
		_redraw_screen()


func _request_redraw() -> void:
	if _state_update_depth > 0:
		_redraw_pending = true
		return
	_redraw_screen()


## Replace the visible nametable/attribute state. Dictionary keys are PPU
## addresses ($2000-$2FFF); values are byte values from the modeled PPU writes.
func set_ppu_memory(ppu_memory: Dictionary) -> void:
	if _ppu_memory == ppu_memory:
		return
	_ppu_memory = ppu_memory.duplicate()
	_ppu_memory_bytes.resize(0x1000)
	for address_offset in 0x1000:
		_ppu_memory_bytes[address_offset] = int(
			_ppu_memory.get(0x2000 + address_offset, 0)) & 0xFF
	_request_redraw()


## Read the live modeled PPU bus for the source `$2000-$2FFF` nametable range.
## Cold-start nametable RAM is initialized to zero in this project; later bytes
## come from the ROM-derived packet/direct-write state passed to set_ppu_memory.
## The PPU snapshot and FCEUX read traces are comparison references only.
func read_nametable_ppu_byte(address: int) -> int:
	var ppu_address := address & 0x3FFF
	if ppu_address >= 0x3000 and ppu_address < 0x3F00:
		ppu_address = 0x2000 | (ppu_address & 0x0FFF)
	if ppu_address < 0x2000 or ppu_address >= 0x3000:
		return -1
	if _ppu_memory.has(ppu_address):
		return int(_ppu_memory[ppu_address]) & 0xFF
	var logical_offset := ppu_address - 0x2000
	var power_on_offset := logical_offset & (PHYSICAL_NAMETABLE_RAM_BYTES - 1)
	if power_on_offset < 0 or power_on_offset >= _nametable_ram_power_on.size():
		return -1
	return int(_nametable_ram_power_on[power_on_offset])


## Supply the first 16 background-palette bytes from the ROM-derived PPU state.
func set_background_palette_bytes(palette_bytes: PackedByteArray) -> void:
	if palette_bytes.size() != 16:
		push_error("PPU nametable renderer needs exactly 16 background palette bytes.")
		return
	if _background_palette == palette_bytes:
		return
	_background_palette = palette_bytes.duplicate()
	_tile_row_blit_cache.clear()
	_tile_row_byte_cache.clear()
	_tile_row_chunk_byte_cache.clear()
	_request_redraw()


## Return the active raw 16-byte background palette for source-derived sprite
## setup. Callers may use the universal color at index zero, which gameplay's
## normal-player palette writer intentionally leaves untouched.
func get_background_palette_bytes() -> PackedByteArray:
	return _background_palette.duplicate()


## In the NES, a sprite with OAM priority bit 5 set is visible only through
## transparent background pixels. The caller draws its sprite layer below this
## node; this mode makes color-index-zero background pixels transparent.
func set_sprites_behind_background(active: bool) -> void:
	if _sprites_behind_background == active:
		return
	_sprites_behind_background = active
	_tile_row_blit_cache.clear()
	_tile_row_byte_cache.clear()
	_tile_row_chunk_byte_cache.clear()
	_request_redraw()


## Return the ROM profile's raw 2 KiB R0/R1 selectors so a scene transition can
## retain the currently active pair until the asynchronous loader commits.
func get_source_2k_chr_selectors() -> Array[int]:
	return [_chr_banks[0], _chr_banks[2]]


## Change the static ROM background profile and its four 1 KiB CHR selectors.
## Palette overrides may be supplied by a source-command palette operation.
func set_background_profile(background_id: int,
		palette_override: PackedByteArray = PackedByteArray(),
		data_root: String = INTRO_DATA_ROOT) -> bool:
	if background_id < 0 or background_id > 0xFF:
		push_error("Background ID must fit in one ROM byte.")
		return false
	var normalized_data_root := data_root.trim_prefix("res://").trim_suffix("/")
	if normalized_data_root != "reference/rom_extract/intro" \
			and normalized_data_root != "reference/rom_extract/gameplay/backgrounds":
		push_error("Background data root is outside the supported ROM-extract folders.")
		return false
	var project_data_root := "res://" + normalized_data_root
	var id_hex := "%02X" % background_id
	var layout_path := "%s/background_%s_layout.json" % [project_data_root, id_hex]
	var layout := _read_json(layout_path)
	if layout.is_empty() or str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("PPU renderer has no matching ROM layout for background $%s." % id_hex)
		return false
	if str(layout.get("background_id", "")).to_upper() != "0X%s" % id_hex:
		push_error("PPU renderer layout ID does not match background $%s." % id_hex)
		return false
	var record_path := "res://" + str(layout.get("record_source_bin", ""))
	var record := FileAccess.get_file_as_bytes(record_path)
	var expected_record := _parse_hex_bytes(str(layout.get("record_raw_hex", "")))
	if record.is_empty() or record != expected_record:
		push_error("PPU renderer background $%s record differs from its preserved ROM bytes." % id_hex)
		return false
	var banks_variant: Variant = layout.get("chr_1k_banks_for_background", [])
	if not banks_variant is Array or banks_variant.size() != 4:
		push_error("PPU renderer background $%s needs four 1 KiB CHR selectors." % id_hex)
		return false
	var selected_banks: Array[int] = []
	for bank_variant in banks_variant:
		var bank := int(bank_variant)
		if bank < 0 or bank >= 128:
			push_error("PPU renderer background $%s contains an invalid CHR bank." % id_hex)
			return false
		selected_banks.append(bank)
	var selected_palette := palette_override.duplicate()
	if selected_palette.is_empty():
		var palette_path := "res://" + str(layout.get("palette_source_bin", ""))
		selected_palette = FileAccess.get_file_as_bytes(palette_path)
		var expected_palette := _parse_hex_bytes(str(layout.get("palette_raw_hex", "")))
		if selected_palette != expected_palette:
			push_error("PPU renderer background $%s palette differs from its preserved ROM bytes." % id_hex)
			return false
	if selected_palette.size() != 16:
		push_error("PPU renderer background $%s needs a 16-byte palette." % id_hex)
		return false
	_active_background_id = background_id
	_active_data_root = project_data_root
	_chr_banks = selected_banks
	_background_palette = selected_palette
	_tile_row_blit_cache.clear()
	_tile_row_byte_cache.clear()
	_tile_row_chunk_byte_cache.clear()
	_source_mmc3_initial_2k_selectors = [selected_banks[0], selected_banks[2]]
	_source_mmc3_chr_writes_active = false
	_source_mmc3_chr_writes.clear()
	if background_id == 0x01:
		_lower_chr_banks = [0, 1, 2, 3]
		_raster_split_scanline = 134
		# The ROM initializes the field view with $2005 = $00,$FF. The first
		# visible row fetches coarse-Y 31 / fine-Y 7 from the nametable tail;
		# the PPU's next vertical increment wraps coarse-Y 31 to 0.
		_scroll_y = 0xFF
		_initial_vertical_nametable = 0
	elif background_id == BG09_BACKGROUND_ID:
		# BG09 sets PPUCTRL=$88 and PPUSCROLL=$00,$FF. Its IRQ reloads
		# $2200 at scanline 129, then switches the lower CHR pair at line 130.
		# These are source bus positions; the exact fetch-to-pixel edge is open.
		_lower_chr_banks = selected_banks.duplicate()
		_raster_split_scanline = -1
		_scroll_y = BG09_INITIAL_SCROLL_Y
		_initial_vertical_nametable = (BG09_INITIAL_PPUCTRL >> 1) & 0x01
		_source_mmc3_initial_2k_selectors = [selected_banks[0], selected_banks[2]]
		_source_mmc3_chr_writes = [
			{
				"scanline": BG09_LOWER_SPLIT_SCANLINE,
				"dot": BG09_R0_WRITE_DOT_CANDIDATE,
				"register": 0,
				"value": 0x00,
				"source_pc": "$A1D4/$A1D7",
				"phase_verified": false,
			},
			{
				"scanline": BG09_LOWER_SPLIT_SCANLINE,
				"dot": BG09_R1_WRITE_DOT_CANDIDATE,
				"register": 1,
				"value": 0x02,
				"source_pc": "$A1E0/$A1E3",
				"phase_verified": false,
			},
		]
		_source_mmc3_chr_writes_active = true
	elif background_id == BG0B_BACKGROUND_ID:
		# BG0B's ROM record selects R0/R1=$38/$3A for the upper band. The shared
		# `$A160` IRQ handler replaces them with $00/$02 at scanline 130. The
		# exact first color pixel remains unresolved; use the recorded write dots
		# as fetch-selection candidates in the source-MM3 model below.
		_lower_chr_banks = selected_banks.duplicate()
		_raster_split_scanline = -1
		_scroll_y = BG0B_INITIAL_SCROLL_Y
		_initial_vertical_nametable = (BG0B_INITIAL_PPUCTRL >> 1) & 0x01
		_source_mmc3_initial_2k_selectors = [selected_banks[0], selected_banks[2]]
		_source_mmc3_chr_writes = [
			{
				"scanline": BG0B_LOWER_SPLIT_SCANLINE,
				"dot": BG0B_R0_WRITE_DOT_CANDIDATE,
				"register": 0,
				"value": 0x00,
				"source_pc": "$A1D4/$A1D7",
				"phase_verified": false,
			},
			{
				"scanline": BG0B_LOWER_SPLIT_SCANLINE,
				"dot": BG0B_R1_WRITE_DOT_CANDIDATE,
				"register": 1,
				"value": 0x02,
				"source_pc": "$A1E0/$A1E3",
				"phase_verified": false,
			},
		]
		_source_mmc3_chr_writes_active = true
	elif background_id == BG08_BACKGROUND_ID:
		# BG08's ROM `$A086/$A08B/$A091` setup writes PPUCTRL=$88 and
		# PPUSCROLL=$00,$FF before the upper raster. The same-input frame-1088
		# bus/fetch trace confirms that this starts at coarse-Y 31/fine-Y 7;
		# the lower IRQ path later reloads $2200. Keep the actual loopy scroll
		# state here instead of compensating with a captured-image Y offset.
		_lower_chr_banks = selected_banks.duplicate()
		_raster_split_scanline = -1
		_scroll_x = BG08_INITIAL_SCROLL_X
		_scroll_y = BG08_INITIAL_SCROLL_Y
		_initial_vertical_nametable = (BG08_INITIAL_PPUCTRL >> 1) & 0x01
	else:
		_lower_chr_banks = selected_banks.duplicate()
		_raster_split_scanline = -1
		_scroll_y = 0
		_initial_vertical_nametable = 0
	_request_redraw()
	return true


## Horizontal world scroll can address two adjacent nametables. The default
## zero scroll is a prototype assumption until the corresponding PPU scroll
## writes are connected to this renderer.
func set_scroll_pixels(scroll_x: int, scroll_y: int = 0) -> void:
	var next_x := posmod(scroll_x, WORLD_WIDTH)
	var next_y := scroll_y & 0xFF
	if _scroll_x == next_x and _scroll_y == next_y:
		return
	_scroll_x = next_x
	_scroll_y = next_y
	_request_redraw()


func get_scroll_pixels() -> Vector2i:
	return Vector2i(_scroll_x, _scroll_y)


## Advance the PPU's vertical coarse/fine scroll state by one scanline at a
## time. Coarse-Y 31 wraps to 0 without toggling the vertical nametable bit;
## coarse-Y 29 wraps to 0 and toggles it, matching the 2C02 increment rule.
func _vertical_state_for_line(coarse_y: int, fine_y: int, nametable_y: int,
		scanline_steps: int) -> Vector3i:
	var current_coarse_y := coarse_y & 0x1F
	var current_fine_y := fine_y & 0x07
	var current_nametable_y := nametable_y & 0x01
	for _step in scanline_steps:
		if current_fine_y < 7:
			current_fine_y += 1
			continue
		current_fine_y = 0
		if current_coarse_y == 29:
			current_coarse_y = 0
			current_nametable_y ^= 1
		elif current_coarse_y == 31:
			current_coarse_y = 0
		else:
			current_coarse_y += 1
	return Vector3i(current_coarse_y, current_fine_y, current_nametable_y)


## Apply the source-derived per-frame event records produced by the ROM raster
## task. $2005 fine-X takes effect on its event row; coarse-X is latched for
## following rows. A $2006 address event supplies the active PPU v origin for
## its row and later rows. MMC3 CHR changes remain a separate profile.
func set_source_raster_events(events: Array[Dictionary]) -> void:
	var resolved_events: Array[Dictionary] = []
	if _active_background_id == BG09_BACKGROUND_ID and events.is_empty():
		# BG09's PPUCTRL/scroll pair initializes the field at coarse-Y 31/fine-Y 7;
		# the separate $2006=$2200 write resets the dialogue rows after scanline 129.
		resolved_events.append({
			"kind": "scroll",
			"scanline": 0,
			"scroll_x": _scroll_x,
			"control_nametable_bit": BG09_INITIAL_PPUCTRL & 0x01,
			"ppuctrl_nametable_bit_observed": BG09_INITIAL_PPUCTRL & 0x01,
			"control_value": BG09_INITIAL_PPUCTRL,
			"scroll_y_base": BG09_INITIAL_SCROLL_Y,
			"source_pc": "$A086-$A091",
		})
		resolved_events.append({
			"kind": "ppu_address",
			"scanline": BG09_ADDRESS_RELOAD_SCANLINE,
			"address": 0x2200,
			"source_pc": "$A160-$A178",
		})
		resolved_events.append({
			"kind": "scroll",
			"scanline": BG09_LOWER_SPLIT_SCANLINE,
			"scroll_x": 0,
			"control_nametable_bit": 0,
			"source_pc": "$A182-$A18A",
		})
	elif _active_background_id == BG0B_BACKGROUND_ID and events.is_empty():
		# The source presenter has no BG0B-specific raster branch yet. Reconstruct
		# the writes shared with BG0A from the ROM-verified `$A086/$A160` handler
		# and the line-aware FCEUX bus trace. In the 2939–3597 span, `$7A` is zero.
		resolved_events.append({
				"kind": "scroll",
				"scanline": 0,
				"scroll_x": _scroll_x,
				"control_nametable_bit": BG0B_INITIAL_PPUCTRL & 0x01,
				"ppuctrl_nametable_bit_observed": BG0B_INITIAL_PPUCTRL & 0x01,
				"control_value": BG0B_INITIAL_PPUCTRL,
				"scroll_y_base": BG0B_INITIAL_SCROLL_Y,
				"source_pc": "$A086-$A091",
			})
		resolved_events.append({
				"kind": "ppu_address",
				"scanline": BG0B_ADDRESS_RELOAD_SCANLINE,
				"address": 0x2200,
				"source_pc": "$A160-$A178",
			})
		resolved_events.append({
				"kind": "scroll",
				"scanline": BG0B_LOWER_SPLIT_SCANLINE,
				"scroll_x": 0,
				"control_nametable_bit": 0,
				"source_pc": "$A182-$A18A",
			})
	else:
		for event in events:
			resolved_events.append(event.duplicate(true))
	if _source_raster_events == resolved_events:
		return
	_source_raster_events = resolved_events
	_source_raster_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("scanline", -1)) < int(b.get("scanline", -1))
	)
	_request_redraw()


## Apply ROM-derived MMC3 writes to background CHR selectors R0/R1.
## `initial_2k_selectors` contains the raw initial R0/R1 register values after
## the vblank setup. Each write is a resolved R0/R1 data write with
## `scanline`, `dot`, `register` (0 or 1), and `value` fields. The renderer
## applies each value at its timestamp to the next pattern-plane fetch. It
## models FCEUX NewPPU's record schedule, including the two prior-line
## prefetch records; it is not a physical 2C02 shifter model.
func set_source_mmc3_chr_writes(initial_2k_selectors: Array[int],
		writes: Array[Dictionary]) -> bool:
	if initial_2k_selectors.size() != 2:
		push_error("MMC3 background raster state needs initial R0 and R1 selectors.")
		return false
	for selector in initial_2k_selectors:
		if selector < 0 or selector >= 128:
			push_error("MMC3 background 2 KiB selectors must fit the 7-bit CHR bank range.")
			return false

	var indexed_writes: Array[Dictionary] = []
	for source_order in writes.size():
		var source_write: Dictionary = writes[source_order]
		var scanline := int(source_write.get("scanline", -1))
		var dot := int(source_write.get("dot", -1))
		var register := int(source_write.get("register", -1))
		var value := int(source_write.get("value", -1))
		if scanline < 0 or scanline > 261 or dot < 0 or dot > 340:
			push_error("MMC3 source writes need a PPU position within scanlines 0-261 and dots 0-340.")
			return false
		if register < 0 or register > 1 or value < 0 or value >= 128:
			push_error("MMC3 source writes must target R0/R1 with a 7-bit CHR selector value.")
			return false
		var indexed_write := source_write.duplicate(true)
		indexed_write["scanline"] = scanline
		indexed_write["dot"] = dot
		indexed_write["register"] = register
		indexed_write["value"] = value
		indexed_write["_source_order"] = source_order
		indexed_writes.append(indexed_write)
	indexed_writes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["scanline"]) != int(b["scanline"]):
			return int(a["scanline"]) < int(b["scanline"])
		if int(a["dot"]) != int(b["dot"]):
			return int(a["dot"]) < int(b["dot"])
		return int(a["_source_order"]) < int(b["_source_order"])
	)
	var ordered_writes: Array[Dictionary] = []
	for indexed_write in indexed_writes:
		indexed_write.erase("_source_order")
		ordered_writes.append(indexed_write)
	if _source_mmc3_chr_writes_active \
			and _source_mmc3_initial_2k_selectors == initial_2k_selectors \
			and _source_mmc3_chr_writes == ordered_writes:
		return true
	_source_mmc3_initial_2k_selectors = initial_2k_selectors.duplicate()
	_source_mmc3_chr_writes = ordered_writes
	_source_mmc3_chr_writes_active = true
	_request_redraw()
	return true


## Apply the observed MMC3-style CHR bank profile. `split_scanline` is a
## scanline-level approximation: the bus trace places the bank writes on that
## line, but the first affected pixel depends on unresolved PPU fetch timing.
func set_raster_chr_split(upper_banks: Array[int], lower_banks: Array[int], split_scanline: int) -> void:
	if upper_banks.size() != 4 or lower_banks.size() != 4:
		push_error("CHR raster profile must provide four 1 KiB banks for each region.")
		return
	if split_scanline < 0 or split_scanline >= SCREEN_HEIGHT:
		push_error("CHR raster split scanline must be within the visible 240-line viewport.")
		return
	_chr_banks = upper_banks.duplicate()
	_lower_chr_banks = lower_banks.duplicate()
	_raster_split_scanline = split_scanline
	_source_mmc3_chr_writes_active = false
	_source_mmc3_chr_writes.clear()
	_request_redraw()


func _load_rom_resources() -> bool:
	_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_rgb_palette = FileAccess.get_file_as_bytes(NES_RGB_PATH)
	if _chr.size() != 131072 or _sha256_hex(_chr) != CHR_SHA256:
		push_error("PPU screen renderer CHR bytes differ from the supplied ROM extract.")
		return false
	if _rgb_palette.size() != 192 or _sha256_hex(_rgb_palette) != RGB_PALETTE_SHA256:
		push_error("PPU screen renderer RGB palette differs from the documented FCEUX palette.")
		return false
	_build_rgba32_palette_cache()
	_decode_chr_pixel_cache()
	return set_background_profile(_active_background_id)


func _build_rgba32_palette_cache() -> void:
	_nes_rgba32_colors.resize(64)
	for nes_index in 64:
		var offset := nes_index * 3
		_nes_rgba32_colors[nes_index] = int(_rgb_palette[offset]) \
				| (int(_rgb_palette[offset + 1]) << 8) \
				| (int(_rgb_palette[offset + 2]) << 16) \
				| (0xFF << 24)


## Expand ROM planar CHR once so scanline rendering uses one indexed color read
## per pixel instead of two plane reads and per-pixel bit extraction.
func _decode_chr_pixel_cache() -> void:
	var tile_count := int(_chr.size() / 16)
	_decoded_chr_pixels.resize(tile_count * 64)
	for tile_index in tile_count:
		var chr_offset := tile_index * 16
		var pixel_offset := tile_index * 64
		for pixel_y in 8:
			var low_plane := int(_chr[chr_offset + pixel_y])
			var high_plane := int(_chr[chr_offset + 8 + pixel_y])
			for pixel_x in 8:
				var bit := 7 - pixel_x
				_decoded_chr_pixels[pixel_offset + pixel_y * 8 + pixel_x] = \
						((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)


func _redraw_screen() -> void:
	if not _rendering_enabled or _chr.is_empty() \
			or _background_palette.size() != 16 or _rgb_palette.size() != 192:
		return
	if use_gpu_background_renderer:
		if _ensure_gpu_background_renderer() \
				and _gpu_background_renderer.update_state(self):
			_gpu_background_texture = _gpu_background_renderer.viewport.get_texture()
			queue_redraw()
			return
		var fallback_reason := gpu_background_fallback_reason
		if _gpu_background_renderer != null:
			fallback_reason = _gpu_background_renderer.last_error
		if fallback_reason.is_empty():
			fallback_reason = "backend setup failed"
		_fallback_to_software_renderer(fallback_reason)
	var image: Image
	var image_data := PackedByteArray()
	var packed_row_copy_active := use_packed_row_copy and not use_pixel_loop_diagnostics
	if not use_pixel_loop_diagnostics and not packed_row_copy_active:
		image = Image.create(SCREEN_WIDTH, SCREEN_HEIGHT, false, Image.FORMAT_RGBA8)
	elif use_pixel_loop_diagnostics:
		image_data.resize(SCREEN_WIDTH * SCREEN_HEIGHT * 4)
	var raster_event_index := 0
	var fine_x := 0
	var coarse_x_pixels := 0
	var pending_coarse_x_pixels := -1
	var initial_scroll_y := _scroll_y
	var initial_vertical_nametable := _initial_vertical_nametable
	# Carry loopy-Y forward as each scanline is drawn. Recomputing the same
	# vertical increments from row 0 for every output line did O(height²) work.
	var vertical_coarse_y := (initial_scroll_y >> 3) & 0x1F
	var vertical_fine_y := initial_scroll_y & 0x07
	var vertical_nametable_y := initial_vertical_nametable & 0x01
	var ppu_address_origin_scanline := -1
	var ppu_address_origin_x := 0
	var ppu_address_origin_y := 0
	var ppu_address_origin_nametable_y := 0
	for screen_y in SCREEN_HEIGHT:
		if pending_coarse_x_pixels >= 0:
			coarse_x_pixels = pending_coarse_x_pixels
			pending_coarse_x_pixels = -1
		while raster_event_index < _source_raster_events.size():
			var event: Dictionary = _source_raster_events[raster_event_index]
			var event_scanline := int(event.get("scanline", -1))
			if event_scanline > screen_y:
				break
			raster_event_index += 1
			if event_scanline < 0 or event_scanline >= SCREEN_HEIGHT:
				continue
			if str(event.get("kind", "")) == "scroll":
				var scroll_value := int(event.get("scroll_x", 0)) & 0xFF
				fine_x = scroll_value & 0x07
				var coarse_x := (scroll_value >> 3) & 0x1F
				var initial_scroll_latch := event_scanline == 0 \
						and event.has("scroll_y_base") \
						and event.has("control_value")
				var nametable_x := int(event.get("control_nametable_bit", 0)) & 0x01
				if initial_scroll_latch:
					# BG0A writes PPUCTRL=$89 and PPUSCROLL=$B2,$FF in its vblank
					# setup. FCEUX NewPPU installs those temporary loopy latches at
					# pre-render scanline 0, dot 304, so the coarse-X/nametable and
					# coarse-Y/fine-Y values already govern the first visible row.
					# The source PPUCTRL bit is kept separately from the renderer
					# candidate field because it is the register value, not a guessed
					# world-page offset.
					nametable_x = int(event.get("ppuctrl_nametable_bit_observed",
						int(event.get("control_value", 0)) & 0x01)) & 0x01
					initial_scroll_y = int(event.get("scroll_y_base", initial_scroll_y)) & 0xFF
					initial_vertical_nametable = (int(event.get("control_value", 0)) >> 1) & 0x01
					coarse_x_pixels = coarse_x * 8 + nametable_x * SCREEN_WIDTH
					pending_coarse_x_pixels = -1
					if ppu_address_origin_scanline < 0:
						vertical_coarse_y = (initial_scroll_y >> 3) & 0x1F
						vertical_fine_y = initial_scroll_y & 0x07
						vertical_nametable_y = initial_vertical_nametable
				else:
					# Mid-frame $2005 writes change fine-X immediately; coarse-X
					# becomes visible on the following scanline in this renderer.
					pending_coarse_x_pixels = coarse_x * 8 + nametable_x * SCREEN_WIDTH
			elif str(event.get("kind", "")) == "ppu_address":
				var address := int(event.get("address", 0)) & 0x3FFF
				ppu_address_origin_scanline = screen_y
				ppu_address_origin_x = ((address >> 10) & 0x01) * SCREEN_WIDTH \
						+ (address & 0x001F) * 8
				var coarse_y := (address >> 5) & 0x1F
				var fine_y := (address >> 12) & 0x07
				ppu_address_origin_y = coarse_y * 8 + fine_y
				ppu_address_origin_nametable_y = (address >> 11) & 0x01
				vertical_coarse_y = coarse_y
				vertical_fine_y = fine_y
				vertical_nametable_y = ppu_address_origin_nametable_y
				coarse_x_pixels = 0
				pending_coarse_x_pixels = -1
		var tile_y := vertical_coarse_y
		var pixel_y := vertical_fine_y
		var vertical_nametable := vertical_nametable_y
		var active_chr_banks := _chr_banks
		if not _source_mmc3_chr_writes_active \
				and _raster_split_scanline >= 0 and screen_y >= _raster_split_scanline:
			active_chr_banks = _lower_chr_banks
		var cached_tile_address := -1
		var cached_tile_id := 0
		var cached_subpalette := 0
		var cached_fetch_record_slot := -1
		var low_fetch_chr_banks := Vector4i(0, 0, 0, 0)
		var high_fetch_chr_banks := Vector4i(0, 0, 0, 0)
		var world_x := posmod(_scroll_x + coarse_x_pixels + fine_x, WORLD_WIDTH)
		if ppu_address_origin_scanline >= 0:
			world_x = posmod(ppu_address_origin_x + fine_x, WORLD_WIDTH)
		var screen_x := 0
		var pending_row_chunk_keys: Array[int] = []
		while screen_x < SCREEN_WIDTH:
			var nametable_page := world_x >> 8
			var local_x := world_x & 0xFF
			var tile_x := local_x >> 3
			var pixel_x := local_x & 0x07
			var nametable_base := NAMETABLE_0 + (vertical_nametable << 11) \
					+ (nametable_page << 10)
			var tile_address := nametable_base + (tile_y << 5) + tile_x
			if tile_address != cached_tile_address:
				cached_tile_address = tile_address
				if use_dictionary_ppu_lookups_diagnostics:
					cached_tile_id = int(_ppu_memory.get(tile_address, 0)) & 0xFF
				else:
					cached_tile_id = int(_ppu_memory_bytes[tile_address & 0x0FFF])
				var attribute_address := nametable_base + ATTRIBUTE_OFFSET \
						+ (tile_y >> 2) * 8 + (tile_x >> 2)
				var attribute := 0
				if use_dictionary_ppu_lookups_diagnostics:
					attribute = int(_ppu_memory.get(attribute_address, 0)) & 0xFF
				else:
					attribute = int(_ppu_memory_bytes[attribute_address & 0x0FFF])
				var quadrant_x := (tile_x & 0x03) >> 1
				var quadrant_y := (tile_y & 0x03) >> 1
				var palette_shift := (quadrant_y * 2 + quadrant_x) * 2
				cached_subpalette = (attribute >> palette_shift) & 0x03
			var record_slot := -1
			if _source_mmc3_chr_writes_active:
				record_slot = (screen_x + fine_x) >> 3
				if record_slot != cached_fetch_record_slot:
					cached_fetch_record_slot = record_slot
					var fetch_scanline := screen_y
					var low_plane_dot := 0
					if record_slot < 2:
						# The first two tile records for this row were fetched at the
						# end of the previous scanline.
						low_plane_dot = 324 + record_slot * 8
					else:
						fetch_scanline += 1
						low_plane_dot = 4 + (record_slot - 2) * 8
					low_fetch_chr_banks = _source_mmc3_chr_banks_at(
						fetch_scanline, low_plane_dot)
					high_fetch_chr_banks = _source_mmc3_chr_banks_at(
						fetch_scanline, low_plane_dot + 2)
			if not use_pixel_loop_diagnostics:
				var tile_bank_slot := cached_tile_id >> 6
				var low_bank := active_chr_banks[tile_bank_slot]
				var high_bank := low_bank
				if _source_mmc3_chr_writes_active:
					low_bank = _chr_bank_from_vector(low_fetch_chr_banks, tile_bank_slot)
					high_bank = _chr_bank_from_vector(high_fetch_chr_banks, tile_bank_slot)
				var blit_length := mini(8 - pixel_x, SCREEN_WIDTH - screen_x)
				if _source_mmc3_chr_writes_active:
					blit_length = mini(blit_length, 8 - ((screen_x + fine_x) & 0x07))
				if packed_row_copy_active:
					var source_start := pixel_x * 4
					var source_end := (pixel_x + blit_length) * 4
					var row_cache_key := _tile_row_cache_key(cached_tile_id, pixel_y,
						cached_subpalette, low_bank, high_bank)
					if use_row_chunk_cache_diagnostics and source_start == 0 \
							and source_end == 32:
						pending_row_chunk_keys.append(row_cache_key)
						if pending_row_chunk_keys.size() >= ROW_CHUNK_TILE_ROWS:
							_append_cached_row_chunk(image_data, pending_row_chunk_keys)
							pending_row_chunk_keys.clear()
					else:
						if not pending_row_chunk_keys.is_empty():
							_append_cached_row_chunk(image_data, pending_row_chunk_keys)
							pending_row_chunk_keys.clear()
						var tile_row_bytes := _cached_tile_row_bytes(cached_tile_id,
							pixel_y, cached_subpalette, low_bank, high_bank)
						if source_start == 0 and source_end == 32:
							image_data.append_array(tile_row_bytes)
						else:
							image_data.append_array(tile_row_bytes.slice(source_start, source_end))
				else:
					var tile_row := _cached_tile_row_image(cached_tile_id, pixel_y,
						cached_subpalette, low_bank, high_bank)
					image.blit_rect(tile_row, Rect2i(pixel_x, 0, blit_length, 1),
						Vector2i(screen_x, screen_y))
				world_x += blit_length
				if world_x >= WORLD_WIDTH:
					world_x -= WORLD_WIDTH
				screen_x += blit_length
				continue
			var color_index := 0
			if _source_mmc3_chr_writes_active:
				color_index = _read_chr_pixel_from_source_banks(cached_tile_id,
					pixel_x, pixel_y, low_fetch_chr_banks, high_fetch_chr_banks)
			else:
				color_index = _read_chr_pixel(cached_tile_id, pixel_x, pixel_y, active_chr_banks)
			var palette_slot := 0 if color_index == 0 else cached_subpalette * 4 + color_index
			var nes_color := int(_background_palette[palette_slot]) & 0x3F
			var rgba32 := int(_nes_rgba32_colors[nes_color])
			if _sprites_behind_background and color_index == 0:
				rgba32 &= 0x00FFFFFF
			image_data.encode_u32((screen_y * SCREEN_WIDTH + screen_x) * 4, rgba32)
			world_x += 1
			if world_x == WORLD_WIDTH:
				world_x = 0
			screen_x += 1
		if packed_row_copy_active and not pending_row_chunk_keys.is_empty():
			_append_cached_row_chunk(image_data, pending_row_chunk_keys)
		# Advance to the next scanline with the 2C02 coarse-Y wrap rules.
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
	if use_pixel_loop_diagnostics or packed_row_copy_active:
		image = Image.create(SCREEN_WIDTH, SCREEN_HEIGHT, false, Image.FORMAT_RGBA8)
		image.set_data(SCREEN_WIDTH, SCREEN_HEIGHT, false, Image.FORMAT_RGBA8, image_data)
	_last_software_render_image = image
	_texture = ImageTexture.create_from_image(image)
	queue_redraw()


func _read_chr_pixel(tile_id: int, pixel_x: int, pixel_y: int, banks: Array[int]) -> int:
	var bank_slot := tile_id >> 6
	var physical_bank := banks[bank_slot]
	var decoded_tile_index := physical_bank * 64 + (tile_id & 0x3F)
	return int(_decoded_chr_pixels[decoded_tile_index * 64 + pixel_y * 8 + pixel_x])


func _cached_tile_row_image(tile_id: int, pixel_y: int, subpalette: int,
		low_bank: int, high_bank: int) -> Image:
	var cache_key := _tile_row_cache_key(tile_id, pixel_y, subpalette, low_bank, high_bank)
	var cached: Variant = _tile_row_blit_cache.get(cache_key)
	if cached is Image:
		return cached
	var row_image := Image.create(8, 1, false, Image.FORMAT_RGBA8)
	var tile_index := tile_id & 0x3F
	var decoded_row_index := tile_index * 64 + pixel_y * 8
	for pixel_x in 8:
		var pixel_offset := decoded_row_index + pixel_x
		var low_pixel := int(_decoded_chr_pixels[low_bank * 4096 + pixel_offset])
		var high_pixel := int(_decoded_chr_pixels[high_bank * 4096 + pixel_offset])
		var color_index := (low_pixel & 0x01) | (high_pixel & 0x02)
		var palette_slot := 0 if color_index == 0 else subpalette * 4 + color_index
		var color := _color_for_nes_index(int(_background_palette[palette_slot]))
		if _sprites_behind_background and color_index == 0:
			color.a = 0.0
		row_image.set_pixel(pixel_x, 0, color)
	_tile_row_blit_cache[cache_key] = row_image
	return row_image


func _cached_tile_row_bytes(tile_id: int, pixel_y: int, subpalette: int,
		low_bank: int, high_bank: int) -> PackedByteArray:
	var cache_key := _tile_row_cache_key(tile_id, pixel_y, subpalette, low_bank, high_bank)
	var cached: Variant = _tile_row_byte_cache.get(cache_key)
	if cached is PackedByteArray:
		return cached
	var row_bytes := PackedByteArray()
	row_bytes.resize(8 * 4)
	var tile_index := tile_id & 0x3F
	var decoded_row_index := tile_index * 64 + pixel_y * 8
	for pixel_x in 8:
		var pixel_offset := decoded_row_index + pixel_x
		var low_pixel := int(_decoded_chr_pixels[low_bank * 4096 + pixel_offset])
		var high_pixel := int(_decoded_chr_pixels[high_bank * 4096 + pixel_offset])
		var color_index := (low_pixel & 0x01) | (high_pixel & 0x02)
		var palette_slot := 0 if color_index == 0 else subpalette * 4 + color_index
		var nes_color := int(_background_palette[palette_slot]) & 0x3F
		var rgba32 := int(_nes_rgba32_colors[nes_color])
		if _sprites_behind_background and color_index == 0:
			rgba32 &= 0x00FFFFFF
		row_bytes.encode_u32(pixel_x * 4, rgba32)
	_tile_row_byte_cache[cache_key] = row_bytes
	return row_bytes


func _tile_row_cache_key(tile_id: int, pixel_y: int, subpalette: int,
		low_bank: int, high_bank: int) -> int:
	var cache_key := low_bank
	cache_key = cache_key * 128 + high_bank
	cache_key = cache_key * 256 + tile_id
	cache_key = cache_key * 8 + pixel_y
	cache_key = cache_key * 4 + subpalette
	return cache_key * 2 + (1 if _sprites_behind_background else 0)


func _append_cached_row_chunk(image_data: PackedByteArray,
		row_cache_keys: Array[int]) -> void:
	if row_cache_keys.is_empty():
		return
	if row_cache_keys.size() == 1:
		image_data.append_array(_tile_row_bytes_for_cache_key(row_cache_keys[0]))
		return
	var chunk_key := str(row_cache_keys.size())
	for row_key in row_cache_keys:
		chunk_key += ":" + str(row_key)
	var cached: Variant = _tile_row_chunk_byte_cache.get(chunk_key)
	if cached is PackedByteArray:
		_row_chunk_cache_hits += 1
		image_data.append_array(cached)
		return
	_row_chunk_cache_misses += 1
	var chunk_bytes := PackedByteArray()
	for row_key in row_cache_keys:
		chunk_bytes.append_array(_tile_row_bytes_for_cache_key(row_key))
	if _tile_row_chunk_byte_cache.size() >= ROW_CHUNK_CACHE_LIMIT:
		_tile_row_chunk_byte_cache.clear()
	_tile_row_chunk_byte_cache[chunk_key] = chunk_bytes
	image_data.append_array(chunk_bytes)


func _tile_row_bytes_for_cache_key(row_cache_key: int) -> PackedByteArray:
	var remaining := row_cache_key
	var behind := remaining & 0x01
	remaining >>= 1
	var subpalette := remaining & 0x03
	remaining >>= 2
	var pixel_y := remaining & 0x07
	remaining >>= 3
	var tile_id := remaining & 0xFF
	remaining >>= 8
	var high_bank := remaining & 0x7F
	remaining >>= 7
	var low_bank := remaining & 0x7F
	if behind != (1 if _sprites_behind_background else 0):
		push_error("Tile-row chunk key no longer matches the active sprite priority.")
		return PackedByteArray()
	return _cached_tile_row_bytes(tile_id, pixel_y, subpalette, low_bank, high_bank)


func _read_chr_pixel_from_source_banks(tile_id: int, pixel_x: int, pixel_y: int,
		low_banks: Vector4i, high_banks: Vector4i) -> int:
	var tile_bank_slot := tile_id >> 6
	var decoded_tile_index := (tile_id & 0x3F) * 64 + pixel_y * 8 + pixel_x
	var low_bank := _chr_bank_from_vector(low_banks, tile_bank_slot)
	var high_bank := _chr_bank_from_vector(high_banks, tile_bank_slot)
	var low_pixel := int(_decoded_chr_pixels[low_bank * 4096 + decoded_tile_index])
	var high_pixel := int(_decoded_chr_pixels[high_bank * 4096 + decoded_tile_index])
	return (low_pixel & 0x01) | (high_pixel & 0x02)


func _chr_bank_from_vector(banks: Vector4i, slot: int) -> int:
	match slot:
		0:
			return banks.x
		1:
			return banks.y
		2:
			return banks.z
		_:
			return banks.w


func _source_mmc3_chr_banks_at(scanline: int, dot: int) -> Vector4i:
	var r0 := _source_mmc3_initial_2k_selectors[0]
	var r1 := _source_mmc3_initial_2k_selectors[1]
	for source_write in _source_mmc3_chr_writes:
		var write_scanline := int(source_write["scanline"])
		var write_dot := int(source_write["dot"])
		if write_scanline > scanline or (write_scanline == scanline and write_dot > dot):
			break
		if int(source_write["register"]) == 0:
			r0 = int(source_write["value"])
		else:
			r1 = int(source_write["value"])
		# MMC3 R0/R1 select paired 1 KiB banks; bit 0 is ignored by the mapper.
	return Vector4i(r0 & 0xFE, (r0 & 0xFE) + 1, r1 & 0xFE, (r1 & 0xFE) + 1)


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
		push_error("Missing ROM-derived PPU layout: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid ROM-derived PPU layout: %s" % path)
		return {}
	return parsed


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
