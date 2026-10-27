extends RefCounted
class_name RomBG0ARasterModel
## ROM-derived E8/$01 preset and BG0A raster-handler state.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const PRESET_PATH := "res://reference/rom_extract/intro/raster_event_state/preset_01.bin"
const PRESET_FILE_OFFSET := "0x00DF23"
const BACKGROUND_RECORD_PATH := "res://reference/rom_extract/intro/background_0A.bin"
const BACKGROUND_RECORD_FILE_OFFSET := "0x00E201"
const BACKGROUND_RECORD_SHA256 := "af6d84b35b705bef4a0ed6426307fa7773fb61ef92fe68ae7b198f976584ed7b"
const CAMERA_RECORD_FILE_OFFSET := "0x00E237"
const PRESET_BYTES := [
	0x40, 0x80, 0x00, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]

const BACKGROUND_ID := 0x0A
const RAM_TABLE_BASE := 0x78
const RAM_TABLE_LENGTH := 0x16 # $78..$8D inclusive
const IRQ_CURSOR := 0x04 # `$A091` writes this before enabling the preset IRQ.
const FIRST_IRQ_SCANLINE_BIAS := 1
const ADDRESS_RELOAD_SCANLINE := 129 # Verified on the shared `$A160` handler path.
const LOWER_SCROLL_SCANLINE := 130 # Second `$2005` write crosses to the next row.
const ADDRESS_RELOAD_MARKER := 0x80
const INITIAL_PPUCTRL_VALUE := 0x88 # `$A086` writes the base control value; its page bit follows the prior camera RAM.
const INITIAL_NAMETABLE_X := INITIAL_PPUCTRL_VALUE & 0x01
const RENDERER_INITIAL_NAMETABLE_X_CANDIDATE := INITIAL_NAMETABLE_X
const INITIAL_SCROLL_Y := 0xFF # `$A091` writes the second `$2005` value.
const RENDERER_INITIAL_SCROLL_Y_CANDIDATE := INITIAL_SCROLL_Y
const INITIAL_BG_CHR_SELECTORS := [0x3C, 0x4C] # BG0A record: R0/R1 = banks 60/76.
const LOWER_BG_CHR_SELECTORS := [0x00, 0x02] # `$A1C0/$A1CB` terminal R0/R1 pair.
const LOWER_CHR_SCANLINE_CANDIDATE := LOWER_SCROLL_SCANLINE
const LOWER_CHR_DOT_CANDIDATE := 0 # Bus order is known; within-line PPU phase is not.
const TRACE_SOURCE := "reference/rom_extract/intro/bg0a_raster_source_trace.md"
const CAMERA_RECORD_OFFSET := 0x36 # `$A227` = background record base + 6 + 4*12.
const CAMERA_RECORD_BYTES := [0x00, 0x21, 0x04]
const CAMERA_FIRST_UPDATE_DELAY_RELEASES := 2
const CAMERA_FIRST_UPDATE_FRAME_OFFSET := CAMERA_FIRST_UPDATE_DELAY_RELEASES + 1
const CAMERA_CHUNK_PIXELS := 0x20
const CAMERA_STEP_Q8_8 := 0x0040

var last_error := ""
var _configured := false
var _e8_source_frame := -1
var _preset := PackedByteArray()
var _camera_configured := false
var _camera_f9_source_frame := -1
var _camera_load_complete_source_frame := -1
var _camera_first_update_source_frame := -1
var _camera_record := PackedByteArray()
var _camera_initial_chunks := 0
var _camera_direction := 0
var _camera_uses_global_scroll := false


## Model the source E8 `$01` command. `$8920` writes byte 0 to `$79`, clears
## `$7A`, leaves `$7B` unchanged, and copies bytes 1..18 to `$7C..$8D`.
func configure_from_e8(operand: int, source_frame: int) -> bool:
	last_error = ""
	_configured = false
	if operand != 0x01:
		return _fail("BG0A raster model only decodes the traced E8 $01 preset.")
	if source_frame < 0:
		return _fail("E8 preset source frame cannot be negative.")
	var expected := PackedByteArray(PRESET_BYTES)
	_preset = FileAccess.get_file_as_bytes(PRESET_PATH)
	if _preset != expected:
		return _fail("Preserved E8 preset bytes do not match the supplied ROM record.")
	_e8_source_frame = source_frame
	_configured = true
	return true


## Return only state that the ROM preset and BG0A setup handler establish.
## `$7B` is omitted because E8 deliberately leaves it untouched.
func preset_state() -> Dictionary:
	if not _configured:
		return {}
	return {
		"active": true,
		"background_id": BACKGROUND_ID,
		"e8_source_frame": _e8_source_frame,
		"ram_0079": int(_preset[0]),
		"ram_007a_after_e8": 0,
		"ram_007c": int(_preset[1]),
		"ram_007d": int(_preset[2]),
		"ram_007e": int(_preset[3]),
		"irq_cursor_after_bg0a_setup": IRQ_CURSOR,
		"irq_latch": (int(_preset[0]) * 2) & 0xFF,
		"preset_file_offset": PRESET_FILE_OFFSET,
		"preset_bytes": _preset.duplicate(),
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_trace": TRACE_SOURCE,
	}


## Decode the one camera triple reached by F9 `$0A`. This loads the source
## record, but the camera worker starts only after the background loader returns.
## Byte 0 is a two-release startup delay; byte 1 encodes a signed Q8.8 step and
## camera-select flag; byte 2 is the number of 32-pixel chunks.
func configure_camera_from_f9(background_id: int, source_frame: int) -> bool:
	last_error = ""
	_camera_configured = false
	if not _configured:
		return _fail("BG0A camera motion requires the ROM E8 $01 preset first.")
	if background_id != BACKGROUND_ID:
		return _fail("BG0A camera motion can only be configured by F9 $0A.")
	if source_frame < _e8_source_frame:
		return _fail("BG0A F9 source frame precedes the E8 preset load.")
	var record := FileAccess.get_file_as_bytes(BACKGROUND_RECORD_PATH)
	if record.size() != 57 or _sha256_hex(record) != BACKGROUND_RECORD_SHA256:
		return _fail("Preserved BG0A record does not match the supplied ROM bytes.")
	_camera_record = record.slice(CAMERA_RECORD_OFFSET, CAMERA_RECORD_OFFSET + CAMERA_RECORD_BYTES.size())
	if _camera_record != PackedByteArray(CAMERA_RECORD_BYTES):
		return _fail("BG0A `$A227` camera record bytes do not match the decoded source.")
	if int(_camera_record[0]) != 0:
		return _fail("BG0A camera record uses an unsupported startup-delay encoding.")
	var packed_speed := int(_camera_record[1])
	var magnitude := packed_speed & 0x1F
	if magnitude != 1:
		return _fail("BG0A camera record uses an unsupported Q8.8 speed magnitude.")
	_camera_direction = -1 if (packed_speed & 0x80) == 0 else 1
	_camera_uses_global_scroll = (packed_speed & 0x40) == 0
	if not _camera_uses_global_scroll:
		return _fail("BG0A camera record selects a non-global scroll path.")
	_camera_initial_chunks = int(_camera_record[2])
	if _camera_initial_chunks <= 0:
		return _fail("BG0A camera record has no remaining 32-pixel chunks.")
	_camera_f9_source_frame = source_frame
	_camera_configured = true
	return true


## The ROM's F9 worker starts the camera record after its packet producer exits.
## The producer supplies this frame at its actual completion edge; the initial
## two scheduler releases and first update are then derived from the record.
func activate_camera_after_background_load(source_frame: int) -> bool:
	last_error = ""
	if not _camera_configured:
		return _fail("BG0A camera record must be decoded before its loader can complete.")
	if source_frame < _camera_f9_source_frame:
		return _fail("BG0A loader completion precedes its F9 dispatch.")
	_camera_load_complete_source_frame = source_frame
	_camera_first_update_source_frame = source_frame + CAMERA_FIRST_UPDATE_FRAME_OFFSET
	return true


## Build the visible BG0A split state from ROM inputs and the source-frame
## progression of the decoded first camera record. No capture file is read.
func frame_state(source_frame: int) -> Dictionary:
	if not _configured:
		return {"active": false, "reason": "E8 $01 preset has not been decoded."}
	if source_frame < _e8_source_frame:
		return {"active": false, "reason": "Raster frame precedes its E8 preset load."}
	if not _camera_configured:
		return {"active": false, "reason": "F9 $0A camera record has not been decoded."}
	var marker := int(_preset[1])
	if marker != ADDRESS_RELOAD_MARKER:
		return {"active": false, "reason": "E8 preset does not contain the verified address-reload marker."}
	var reload_address := ((int(_preset[3]) & 0xFF) << 8) | (int(_preset[2]) & 0xFF)
	var irq_latch := (int(_preset[0]) * 2) & 0xFF
	var first_irq_scanline := int(_preset[0]) * 2 + FIRST_IRQ_SCANLINE_BIAS
	if first_irq_scanline != ADDRESS_RELOAD_SCANLINE:
		return {"active": false, "reason": "Preset IRQ scanline differs from the verified shared-handler line."}
	var camera := _camera_state_at_source_frame(source_frame)
	# `$A086` writes the camera RAM that existed before this frame's worker
	# update. Same-input bus and NewPPU fetch traces show source frame 2370 still
	# latches `$2005=$00` even though its end-frame `$7A/$7B` becomes `$FF/$FF`.
	var ppu_camera := _camera_state_at_source_frame(source_frame - 1)
	var ppu_control := INITIAL_PPUCTRL_VALUE
	if int(ppu_camera["ram_007b"]) == 0xFF:
		ppu_control |= 0x01
	var ppu_scroll_x := int(ppu_camera["ram_007a"])
	var ppu_nametable_x := ppu_control & 0x01
	var events: Array[Dictionary] = [
		{
			"kind": "scroll",
			"scanline": 0,
			"scroll_x": ppu_scroll_x,
			# The setup writes base PPUCTRL `$88` plus the prior camera page bit,
			# and prior `$7A` plus `$FF` to PPUSCROLL before the pre-render latch.
			"control_nametable_bit": ppu_nametable_x,
			"ppuctrl_nametable_bit_observed": ppu_nametable_x,
			"control_value": ppu_control,
			"scroll_y_base": INITIAL_SCROLL_Y,
			"source_pc": "$A086-$A091",
			"camera_ram_source_frame": source_frame - 1,
		},
		{
			"kind": "ppu_address",
			"scanline": first_irq_scanline,
			"address": reload_address,
			"cursor": IRQ_CURSOR,
			"marker": marker,
			"irq_latch": irq_latch,
			"source_pc": "$A160-$A178",
		},
		{
			"kind": "scroll",
			"scanline": first_irq_scanline + 1,
			"scroll_x": 0,
			"control_nametable_bit": 0,
			"source_pc": "$A182-$A18A",
		},
	]
	var chr_writes: Array[Dictionary] = [
		{
			"scanline": LOWER_CHR_SCANLINE_CANDIDATE,
			"dot": LOWER_CHR_DOT_CANDIDATE,
			"register": 0,
			"value": LOWER_BG_CHR_SELECTORS[0],
			"source_pc": "$A1D4/$A1D7",
			"phase_verified": false,
		},
		{
			"scanline": LOWER_CHR_SCANLINE_CANDIDATE,
			"dot": LOWER_CHR_DOT_CANDIDATE,
			"register": 1,
			"value": LOWER_BG_CHR_SELECTORS[1],
			"source_pc": "$A1E0/$A1E3",
			"phase_verified": false,
		},
	]
	var initial_chr_selectors: Array[int] = [
		int(INITIAL_BG_CHR_SELECTORS[0]), int(INITIAL_BG_CHR_SELECTORS[1]),
	]
	return {
		"active": true,
		"background_id": BACKGROUND_ID,
		"source_frame": source_frame,
		"e8_source_frame": _e8_source_frame,
		"camera_scroll_x_byte": ppu_scroll_x,
		"camera_scroll_source_frame": source_frame - 1,
		"ppu_camera_state": ppu_camera,
		"initial_scroll_y": INITIAL_SCROLL_Y,
		"renderer_initial_scroll_y_candidate": RENDERER_INITIAL_SCROLL_Y_CANDIDATE,
		"initial_vertical_scroll_mapping_verified": false,
		"initial_ppuctrl": ppu_control,
		"initial_nametable_x": ppu_nametable_x,
		"renderer_initial_nametable_x_candidate": ppu_nametable_x,
		"initial_nametable_x_mapping_verified": false,
		"camera_scroll_source": "F9 $0A `$A227` ROM record + bank-0 `$8D88-$8DC5` Q8.8 integrator",
		"camera_state": camera,
		"camera_f9_source_frame": _camera_f9_source_frame,
		"camera_load_complete_source_frame": _camera_load_complete_source_frame,
		"camera_first_update_source_frame": _camera_first_update_source_frame,
		"irq_cursor": IRQ_CURSOR,
		"irq_latch": irq_latch,
		"first_irq_scanline_candidate": first_irq_scanline,
		"address_reload_scanline": ADDRESS_RELOAD_SCANLINE,
		"lower_scroll_scanline": LOWER_SCROLL_SCANLINE,
		"initial_2k_chr_selectors": initial_chr_selectors,
		"lower_2k_chr_selectors": LOWER_BG_CHR_SELECTORS.duplicate(),
		"lower_chr_scanline_candidate": LOWER_CHR_SCANLINE_CANDIDATE,
		"lower_chr_dot_candidate": LOWER_CHR_DOT_CANDIDATE,
		"lower_chr_first_affected_pixel_phase_verified": false,
		"ppu_reload_address": reload_address,
		"ppu_events": events,
		"chr_writes": chr_writes,
		"first_affected_pixel_phase_verified": false,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"source_trace": TRACE_SOURCE,
	}


	## Diagnostic/integration hook. Call only with frame_state produced from ROM
	## state; the active presenter wires the same events alongside its other updates.
func apply_frame_state(renderer: RomPpuNametableScreenRenderer,
		source_frame: int) -> Dictionary:
	var current := frame_state(source_frame)
	if not bool(current.get("active", false)):
		return current
	renderer.set_scroll_pixels(0, int(current["renderer_initial_scroll_y_candidate"]))
	renderer.set_source_raster_events(current["ppu_events"])
	if not renderer.set_source_mmc3_chr_writes(
			current["initial_2k_chr_selectors"], current["chr_writes"]):
		return {"active": false, "reason": "Renderer rejected the decoded BG0A CHR events."}
	return current


func debug_snapshot(source_frame: int = -1) -> Dictionary:
	var result := preset_state()
	result["camera_configured"] = _camera_configured
	result["camera_f9_source_frame"] = _camera_f9_source_frame
	result["camera_load_complete_source_frame"] = _camera_load_complete_source_frame
	result["camera_first_update_source_frame"] = _camera_first_update_source_frame
	result["camera_record_file_offset"] = CAMERA_RECORD_FILE_OFFSET
	result["camera_record_bytes"] = _camera_record.duplicate()
	if source_frame >= 0 and _camera_configured:
		result["frame_state"] = frame_state(source_frame)
	return result


func _camera_state_at_source_frame(source_frame: int) -> Dictionary:
	if _camera_first_update_source_frame < 0:
		return {
			"source_frame": source_frame,
			"update_count": 0,
			"q8_8_step": -CAMERA_STEP_Q8_8,
			"ram_0069_fraction": 0,
			"ram_006a_chunk_pixels": 0,
			"ram_0072_chunks_remaining": _camera_initial_chunks,
			"ram_007a": 0,
			"ram_007b": 0,
			"displacement_pixels": 0,
			"camera_complete": false,
			"worker_started": false,
		}
	var update_count := maxi(0, source_frame - _camera_first_update_source_frame + 1)
	var signed_q8_total := update_count * CAMERA_STEP_Q8_8 * _camera_direction
	var absolute_q8_total := absi(signed_q8_total)
	var displacement_pixels := int((absolute_q8_total + 0xFF) / 0x100)
	var maximum_displacement := _camera_initial_chunks * CAMERA_CHUNK_PIXELS
	displacement_pixels = mini(displacement_pixels, maximum_displacement)
	var fractional_velocity := posmod(signed_q8_total, 0x100)
	var remaining_chunks := _camera_initial_chunks - int(displacement_pixels / CAMERA_CHUNK_PIXELS)
	var residual_chunk_pixels := displacement_pixels % CAMERA_CHUNK_PIXELS
	var signed_scroll := displacement_pixels * _camera_direction
	return {
		"source_frame": source_frame,
		"update_count": update_count,
		"q8_8_step": -CAMERA_STEP_Q8_8,
		"ram_0069_fraction": fractional_velocity,
		"ram_006a_chunk_pixels": residual_chunk_pixels,
		"ram_0072_chunks_remaining": remaining_chunks,
		"ram_007a": posmod(signed_scroll, 0x100),
		"ram_007b": 0xFF if signed_scroll < 0 else 0,
		"displacement_pixels": displacement_pixels,
		"camera_complete": remaining_chunks <= 0,
		"worker_started": source_frame >= _camera_first_update_source_frame,
	}


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	_configured = false
	return false
