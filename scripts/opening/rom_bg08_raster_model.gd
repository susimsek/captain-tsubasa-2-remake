extends RefCounted
class_name RomBG08RasterModel
## ROM-derived state/events for the BG08 opening raster split.
## Timing annotations are calibrated against one same-input FCEUX trace; the
## model never reads a capture CSV and does not emulate the 2C02 pixel pipeline.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const PRESET_PATH := "res://reference/rom_extract/intro/raster_event_state/preset_01.bin"
const SELECTOR_STREAM_PATH := "res://reference/rom_extract/intro/raster_event_state/bg08_chr_selector_stream.bin"
const BACKGROUND_RECORD_PATH := "res://reference/rom_extract/intro/background_08.bin"

const PRESET_DATA := [
	0x40, 0x80, 0x00, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]
const SELECTOR_STREAM_DATA := [0x80, 0x40, 0x02, 0x42, 0x02, 0x44, 0x02, 0xFE, 0xFF]
const BG08_INITIAL_CHR_PAIR := [0x40, 0x00]
const BG08_LOWER_CHR_PAIR := [0x00, 0x02]

const RAM_TABLE_SIZE := 0x16 # $78..$8D inclusive
const EVENT_CURSOR := 0x04
const SELECTOR_STREAM_POINTER := 0xBA96
const SELECTOR_STREAM_FILE_OFFSET := "0x00DAA6"
const SELECTOR_POINTER_TABLE_FILE_OFFSET := "0x00D830"

# Representative bus positions from source frame 1522. The MMC3 IRQ phase can
# move in dots across frames; the CPU/PPU phase and physical color edge are not
# modeled. Scanlines and source order are ROM-derived; these dots are a single
# capture calibration only and must not be treated as universal exact timing.
const VBLANK_SCANLINE := 252
const VBLANK_R0_SELECT_DOT := 55
const VBLANK_R0_DATA_DOT := 67
const VBLANK_R1_SELECT_DOT := 106
const VBLANK_R1_DATA_DOT := 118
const FIRST_IRQ_DOT_REFERENCE := 115
const PPUADDR_HIGH_DOT_REFERENCE := 284
const PPUADDR_LOW_DOT_REFERENCE := 296
const TERMINAL_IRQ_ACK_SCANLINE_OFFSET := 1
const TERMINAL_IRQ_ACK_DOT_REFERENCE := 59
const VISIBLE_R0_SELECT_DOT := 131
const VISIBLE_R0_DATA_DOT := 143
const VISIBLE_R1_SELECT_DOT := 182
const VISIBLE_R1_DATA_DOT := 194

var last_error := ""
var _configured := false
var _active_window_started := false
var _active_window_start_source_frame := -1
var _stream_start_source_frame := -1
var _last_source_frame := -1
var _selector_value := 0
var _selector_r1_value := 0
var _selector_index := 0
var _next_selector_write_source_frame := -1
var _selector_values := PackedByteArray()
var _selector_delays := PackedByteArray()
var _vblank_table := PackedByteArray()
var _bg08_record_pair := PackedByteArray()
var _background_pair_transition_set := false
var _background_pair_transition_applied := false
var _background_pair_transition_selectors: Array[int] = []
var _background_pair_transition_source_frame := -1
var _frame_state: Dictionary = {}


## `stream_start_source_frame` is the source-frame edge for command `F5 10`.
## Configure this on BG08's activation edge and pass the previous background's
## live R0/R1 pair. The stream starts at 1048 in the observed opening.
func configure(stream_start_source_frame: int, initial_2k_selectors: Array[int]) -> bool:
	last_error = ""
	_configured = false
	if stream_start_source_frame < 0:
		return _fail("BG08 selector-effect start frame cannot be negative.")
	if initial_2k_selectors.size() != 2:
		return _fail("BG08 needs the prior background's initial R0/R1 selector pair.")
	for selector in initial_2k_selectors:
		if selector < 0 or selector >= 128:
			return _fail("Initial MMC3 R0/R1 selectors must be in the 7-bit CHR bank range.")

	var expected_preset := PackedByteArray(PRESET_DATA)
	var preset := FileAccess.get_file_as_bytes(PRESET_PATH)
	if preset != expected_preset:
		return _fail("Preserved preset-01 bytes are missing or do not match the supplied ROM.")
	var selector_stream := FileAccess.get_file_as_bytes(SELECTOR_STREAM_PATH)
	if selector_stream != PackedByteArray(SELECTOR_STREAM_DATA):
		return _fail("Preserved BG08 selector-effect bytes are missing or do not match the supplied ROM.")
	var background_record := FileAccess.get_file_as_bytes(BACKGROUND_RECORD_PATH)
	if background_record.size() < BG08_INITIAL_CHR_PAIR.size():
		return _fail("Preserved BG08 background record is truncated.")
	if background_record.slice(0, BG08_INITIAL_CHR_PAIR.size()) != PackedByteArray(BG08_INITIAL_CHR_PAIR):
		return _fail("BG08's initial R0/R1 selectors do not match the supplied ROM.")
	if not _decode_selector_stream(selector_stream):
		return false

	_vblank_table = PackedByteArray()
	_vblank_table.resize(RAM_TABLE_SIZE)
	_vblank_table.fill(0)
	# `$8920`: preset byte 0->$79, clear $7A, preserve $7B, bytes 1..18->$7C..$8D.
	# Cold-start RAM evidence establishes the untouched `$7B=0` value.
	_vblank_table[0] = EVENT_CURSOR # $78
	_vblank_table[1] = preset[0] # $79: IRQ latch is doubled by $A091
	_vblank_table[2] = 0 # $7A
	for source_index in range(1, preset.size()):
		_vblank_table[3 + source_index] = preset[source_index]

	_selector_value = initial_2k_selectors[0]
	_selector_r1_value = initial_2k_selectors[1]
	_selector_index = 0
	_active_window_started = false
	_active_window_start_source_frame = -1
	_stream_start_source_frame = stream_start_source_frame
	_last_source_frame = -1
	_next_selector_write_source_frame = stream_start_source_frame
	_bg08_record_pair = PackedByteArray(BG08_INITIAL_CHR_PAIR)
	_background_pair_transition_set = false
	_background_pair_transition_applied = false
	_background_pair_transition_selectors.clear()
	_background_pair_transition_source_frame = -1
	_frame_state = {}
	_configured = true
	return true


## Queue the ROM-loaded BG08 initial R0/R1 pair. Call when the BG08 packet
## loader completes; the pair becomes active on `effective_source_frame`.
func set_background_pair_transition(new_selectors: Array[int], effective_source_frame: int) -> bool:
	last_error = ""
	if not _configured:
		return _fail("BG08 raster model has not been configured.")
	if new_selectors.size() != 2:
		return _fail("BG08 background transition needs exactly two MMC3 selectors.")
	for selector in new_selectors:
		if selector < 0 or selector >= 128:
			return _fail("BG08 transition selectors must be in the 7-bit CHR bank range.")
	if new_selectors[0] != int(_bg08_record_pair[0]) or new_selectors[1] != int(_bg08_record_pair[1]):
		return _fail("BG08 transition pair does not match the preserved ROM background record.")
	if effective_source_frame != _stream_start_source_frame:
		return _fail("BG08 record transition must align with the decoded F5 10 stream start.")
	if _active_window_started and effective_source_frame <= _last_source_frame:
		return _fail("BG08 background transition must be queued before its effective source frame.")
	if _background_pair_transition_set:
		if _background_pair_transition_source_frame == effective_source_frame \
				and _background_pair_transition_selectors == new_selectors:
			return true
		return _fail("A different BG08 background pair transition is already queued.")
	_background_pair_transition_set = true
	_background_pair_transition_selectors = new_selectors.duplicate()
	_background_pair_transition_source_frame = effective_source_frame
	return true


## Advance monotonically through decoded source frames. Returns false on invalid
## state or backwards movement; read the result with `frame_state()`.
func advance_to_source_frame(frame: int) -> bool:
	last_error = ""
	if not _configured:
		return _fail("BG08 raster model has not been configured.")
	if not _active_window_started:
		if frame < 0:
			return _fail("BG08 active-window frame cannot be negative.")
		if _background_pair_transition_set and frame > _background_pair_transition_source_frame:
			return _fail("BG08 raster history must begin on or before its background-pair transition.")
		_active_window_started = true
		_active_window_start_source_frame = frame
		_last_source_frame = frame - 1
	if frame < _last_source_frame:
		return _fail("BG08 raster model cannot run backwards.")
	while _last_source_frame < frame:
		_last_source_frame += 1
		if _last_source_frame >= _stream_start_source_frame and not _background_pair_transition_set:
			_last_source_frame -= 1
			return _fail("BG08 packet-load transition must be supplied before the F5 10 frame.")
		_frame_state = _build_frame_state(_last_source_frame)
	return true


## Returns the most recently advanced frame's source-derived observations.
## Required consumer fields expose the initial R0/R1 pair, PPUADDR events,
## and two visible MMC3 R0/R1 data writes.
func frame_state() -> Dictionary:
	return _frame_state.duplicate(true)


func debug_snapshot() -> Dictionary:
	return {
		"configured": _configured,
		"active_window_started": _active_window_started,
		"active_window_start_source_frame": _active_window_start_source_frame,
		"stream_start_source_frame": _stream_start_source_frame,
		"last_source_frame": _last_source_frame,
		"current_chr_r0_selector": _selector_value,
		"current_chr_r1_selector": _selector_r1_value,
		"background_pair_transition_set": _background_pair_transition_set,
		"background_pair_transition_applied": _background_pair_transition_applied,
		"background_pair_transition_source_frame": _background_pair_transition_source_frame,
		"selector_stream_values": _selector_values.duplicate(),
		"selector_stream_delays": _selector_delays.duplicate(),
		"ram_0078_008d_vblank": _vblank_table.duplicate(),
		"preset_file_offset": "0x00DF23",
		"selector_pointer_table_file_offset": SELECTOR_POINTER_TABLE_FILE_OFFSET,
		"selector_stream_pointer": SELECTOR_STREAM_POINTER,
		"selector_stream_file_offset": SELECTOR_STREAM_FILE_OFFSET,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"timing_assumptions": _timing_assumptions(),
	}


func _build_frame_state(source_frame: int) -> Dictionary:
	var pair_transition_event: Dictionary = {}
	if source_frame == _background_pair_transition_source_frame and _background_pair_transition_set:
		_selector_value = _background_pair_transition_selectors[0]
		_selector_r1_value = _background_pair_transition_selectors[1]
		_background_pair_transition_applied = true
		pair_transition_event = {
			"kind": "background_pair_transition",
			"source_frame": source_frame,
			"selectors": _background_pair_transition_selectors.duplicate(),
			"source": "ROM BG08 record",
		}
	# `$A091/$A1CB` issue the vblank pair before this frame's `$836B` stream
	# update is visible to the next vblank. This is why frame 1522 uses $44.
	var initial_r0_selector := _selector_value
	var initial_r1_selector := _selector_r1_value
	var irq_latch := int(_vblank_table[1]) * 2
	var first_irq_scanline := irq_latch + 1
	var marker := int(_vblank_table[4]) # $7C
	var address_low := int(_vblank_table[5]) # $7D
	var address_high := int(_vblank_table[6]) # $7E
	var ppu_address := (address_high << 8) | address_low
	var ppu_events: Array[Dictionary] = []
	var chr_writes: Array[Dictionary] = []
	var selector_updates: Array[Dictionary] = []

	ppu_events.append({
		"kind": "mmc3_irq_setup",
		"phase": "vblank",
		"scanline": VBLANK_SCANLINE,
		"latch": irq_latch,
		"reload": irq_latch,
		"enabled": true,
		"source_pc": "$A091-$A0A4",
		"meaning": "$79 doubled into $C000/$C001; $78 initialized to event cursor 4",
		"reference_dot_positions": [169, 181, 193],
	})
	ppu_events.append({
		"kind": "mmc3_initial_chr_pair",
		"phase": "vblank_initial_pair",
		"scanline": VBLANK_SCANLINE,
		"selectors": [initial_r0_selector, initial_r1_selector],
		"source_pc": "$A091/$A1CB",
		"dot_positions_reference": [
			VBLANK_R0_SELECT_DOT, VBLANK_R0_DATA_DOT,
			VBLANK_R1_SELECT_DOT, VBLANK_R1_DATA_DOT,
		],
	})

	if (marker & 0x80) != 0:
		ppu_events.append({
			"kind": "mmc3_irq_event",
			"phase": "first_visible_irq",
			"scanline": first_irq_scanline,
			"reference_dot": FIRST_IRQ_DOT_REFERENCE,
			"source_pc": "$A160",
			"event_cursor": EVENT_CURSOR,
			"marker": marker,
			"irq_latch": irq_latch,
		})
		ppu_events.append({
			"kind": "ppu_address",
			"phase": "first_visible_irq",
			"address": ppu_address,
			"address_hex": "$%04X" % ppu_address,
			"scanline": first_irq_scanline,
			"reference_dot": PPUADDR_HIGH_DOT_REFERENCE,
			"source_pc": "$A160/$A1A8",
			"ppu_register": 0x2006,
			"writes": [
				{"register": 0x2006, "value": address_high, "scanline": first_irq_scanline,
					"dot_reference": PPUADDR_HIGH_DOT_REFERENCE, "source_pc": "$A178"},
				{"register": 0x2006, "value": address_low, "scanline": first_irq_scanline,
					"dot_reference": PPUADDR_LOW_DOT_REFERENCE, "source_pc": "$A17B"},
			],
			"marker_address_mode": true,
		})
		ppu_events.append({
			"kind": "ppu_register_write",
			"phase": "first_visible_irq",
			"register": 0x2006,
			"register_hex": "$2006",
			"value": address_high,
			"value_hex": "$%02X" % address_high,
			"resulting_address": ppu_address,
			"resulting_address_hex": "$%04X" % ppu_address,
			"scanline": first_irq_scanline,
			"reference_dot": PPUADDR_HIGH_DOT_REFERENCE,
			"source_pc": "$A178",
			"marker_address_mode": true,
		})
		ppu_events.append({
			"kind": "ppu_register_write",
			"phase": "first_visible_irq",
			"register": 0x2006,
			"register_hex": "$2006",
			"value": address_low,
			"value_hex": "$%02X" % address_low,
			"resulting_address": ppu_address,
			"resulting_address_hex": "$%04X" % ppu_address,
			"scanline": first_irq_scanline,
			"reference_dot": PPUADDR_LOW_DOT_REFERENCE,
			"source_pc": "$A17B",
			"marker_address_mode": true,
		})
		ppu_events.append({
			"kind": "mmc3_irq_terminal_ack",
			"phase": "terminal_path_after_address_event",
			"scanline": first_irq_scanline + TERMINAL_IRQ_ACK_SCANLINE_OFFSET,
			"reference_dot": TERMINAL_IRQ_ACK_DOT_REFERENCE,
			"source_pc": "$A1C0",
			"event_cursor_after": 0,
		})
		_append_visible_chr_writes(chr_writes, first_irq_scanline + TERMINAL_IRQ_ACK_SCANLINE_OFFSET)
	else:
		ppu_events.append({"kind": "unsupported_irq_marker", "marker": marker, "source_pc": "$A160"})

	if source_frame == _next_selector_write_source_frame and not _selector_values.is_empty():
		var written_selector := int(_selector_values[_selector_index])
		var delay_frames := int(_selector_delays[_selector_index])
		selector_updates.append({
			"kind": "ram_write",
			"address": 0x008E,
			"address_hex": "$008E",
			"value": written_selector,
			"source_pc": "$836B",
			"stream_pointer": SELECTOR_STREAM_POINTER,
			"stream_file_offset": SELECTOR_STREAM_FILE_OFFSET,
			"next_delay_frames": delay_frames,
			"ordering_note": "stream update is after this frame's vblank selector pair in the model; exact intra-frame CPU phase is not emulated",
		})
		_selector_value = written_selector
		_selector_index = (_selector_index + 1) % _selector_values.size()
		_next_selector_write_source_frame += delay_frames

	var frame_table := _vblank_table.duplicate()
	frame_table[0] = 0 # `$A1C0` terminal path clears $78.
	var initial_selectors: Array[int] = [int(initial_r0_selector), int(initial_r1_selector)]
	return {
		"active": true,
		"source_frame": source_frame,
		"initial_2k_selectors": initial_selectors,
		"background_pair_transition": pair_transition_event,
		"initial_chr_pair_timing_reference": {
			"scanline": VBLANK_SCANLINE,
			"dots": [VBLANK_R0_SELECT_DOT, VBLANK_R0_DATA_DOT,
				VBLANK_R1_SELECT_DOT, VBLANK_R1_DATA_DOT],
			"source_pc": "$A091/$A1CB",
		},
		"ppu_events": ppu_events,
		"chr_writes": chr_writes,
		"selector_updates": selector_updates,
		"irq_latch": irq_latch,
		"first_irq_scanline": first_irq_scanline,
		"source_address": ppu_address,
		"source_address_hex": "$%04X" % ppu_address,
		"visible_chr_pair": BG08_LOWER_CHR_PAIR.duplicate(),
		"ram_0078_008d_vblank": _vblank_table.duplicate(),
		"ram_0078_008d_frame_end": frame_table,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"timing_assumptions": _timing_assumptions(),
	}


func _append_visible_chr_writes(writes: Array[Dictionary], scanline: int) -> void:
	writes.append({
		"phase": "visible_lower_pair",
		"scanline": scanline,
		"dot": VISIBLE_R0_DATA_DOT,
		"dot_is_reference": true,
		"register": 0,
		"value": BG08_LOWER_CHR_PAIR[0],
		"source_pc": "$A1C0/$A1CB",
		"select_dot_reference": VISIBLE_R0_SELECT_DOT,
		"data_dot_reference": VISIBLE_R0_DATA_DOT,
		"mmc3_select_write": {"address": 0x8000, "value": 0x00},
		"mmc3_data_write": {"address": 0x8001, "value": BG08_LOWER_CHR_PAIR[0]},
	})
	writes.append({
		"phase": "visible_lower_pair",
		"scanline": scanline,
		"dot": VISIBLE_R1_DATA_DOT,
		"dot_is_reference": true,
		"register": 1,
		"value": BG08_LOWER_CHR_PAIR[1],
		"source_pc": "$A1C0/$A1CB",
		"select_dot_reference": VISIBLE_R1_SELECT_DOT,
		"data_dot_reference": VISIBLE_R1_DATA_DOT,
		"mmc3_select_write": {"address": 0x8000, "value": 0x01},
		"mmc3_data_write": {"address": 0x8001, "value": BG08_LOWER_CHR_PAIR[1]},
	})


func _decode_selector_stream(stream: PackedByteArray) -> bool:
	_selector_values = PackedByteArray()
	_selector_delays = PackedByteArray()
	if stream.size() != 9 or stream[0] != 0x80:
		return _fail("BG08 selector stream does not match the verified F5 10 effect format.")
	var cursor := 1 # `$8353` branches to the ROM animation loop at Y=1.
	var saw_loop_marker := false
	while cursor < stream.size():
		var selector := int(stream[cursor])
		if selector == 0xFE:
			saw_loop_marker = cursor + 1 < stream.size() and stream[cursor + 1] == 0xFF
			break
		if selector == 0xFF or cursor + 1 >= stream.size():
			return _fail("BG08 selector stream has a truncated selector/wait pair.")
		var delay := int(stream[cursor + 1])
		if delay <= 0:
			return _fail("BG08 selector stream contains a zero-frame wait.")
		_selector_values.append(selector)
		_selector_delays.append(delay)
		cursor += 2
	if not saw_loop_marker or _selector_values.is_empty():
		return _fail("BG08 selector stream is missing its verified FE/FF loop marker.")
	return true


func _timing_assumptions() -> Dictionary:
	return {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"preset_source": "bank 6 $BF13, file 0x00DF23; copied by bank-0 $8920",
		"selector_producer": "bank-0 $82F0 pointer lookup + $8353/$836B loop; F5 10 selects bank-6 $B820 entry -> $BA96",
		"selector_stream_file_offset": SELECTOR_STREAM_FILE_OFFSET,
		"irq_consumer": "bank-2 $A091/$A160/$A1C0/$A1CB, with preset-01 $79=$40 and marker $7C=$80",
		"first_irq_scanline_formula": "2 * $79 + 1 = 129; terminal lower-pair path continues on line 130",
		"selector_wait_units": "source frames; each ROM wait byte $02 schedules the next $8E value two frames later",
		"lower_pair_origin": "$90/$91 = 00/02 is the captured BG08 terminal-pair state consumed by $A1C0/$A1CB; its initializer is not yet traced",
		"active_window": "starts on the first source frame advanced after BG08 activation; configure is intended at F9 08, source frame 1029 in the observed opening",
		"background_pair_transition": "caller supplies the previous live pair at configure, then passes the ROM-loaded BG08 record pair and effective frame when packet loading completes",
		"ordering": "frame N vblank uses the selector state carried from N-1; source stream writes are exposed after those vblank events",
		"dot_phase_limit": "dots are a single frame-1522 FCEUX bus calibration; IRQ/CPU/PPU dot phase can vary across frames",
		"raster_limit": "no 2C02 fetch/shifter pipeline is modeled; events do not establish the physical pixel edge",
		"runtime_inputs": "preserved ROM-derived byte files plus caller-supplied F5 10 source-frame edge; no capture CSV",
	}


func _fail(message: String) -> bool:
	last_error = message
	return false
