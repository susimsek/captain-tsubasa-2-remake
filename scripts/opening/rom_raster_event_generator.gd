extends RefCounted
class_name RomRasterEventGenerator
## Reconstructs the opening field's five scroll accumulators and IRQ event list
## from the supplied ROM-derived preset/delta bytes. This is source data logic,
## not a captured-frame event table or a cycle-accurate PPU implementation.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const PRESET_PATH := "res://reference/rom_extract/intro/raster_event_state/preset_05.bin"
const DELTA_PATH := "res://reference/rom_extract/intro/raster_event_state/delta_records_phase_00.bin"
const PRESET_DATA := [
	0x18, 0x08, 0x00, 0x00, 0x20, 0x00, 0x00, 0x80, 0x00, 0x22,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]
const DELTA_DATA := [
	0x10, 0x00, 0x10, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00,
]
const RAM_TABLE_BASE := 0x78
const RAM_TABLE_SIZE := 0x16
const FIRST_PRODUCER_SOURCE_FRAME_OFFSET := 1
const EVENT_CURSOR_INITIAL := 0x04

var last_error := ""
var _active := false
var _start_source_frame := -1
var _last_source_frame := -1
var _table := PackedByteArray()
var _fractional_accumulators: Array[int] = [0, 0, 0, 0, 0]
var _delta_records := PackedByteArray()
var _initial_latch_scroll_x := 0
var _initial_latch_page_byte := 0
var _stop_producer_before_source_frame := -1
var _producer_stopped := false


func configure(start_source_frame: int) -> bool:
	last_error = ""
	if start_source_frame < 0:
		return _fail("Raster task start frame cannot be negative.")
	var preset: PackedByteArray = FileAccess.get_file_as_bytes(PRESET_PATH)
	var expected_preset := PackedByteArray(PRESET_DATA)
	if preset != expected_preset:
		return _fail("Bank-6 preset 5 source bytes are missing or changed.")
	_delta_records = FileAccess.get_file_as_bytes(DELTA_PATH)
	if _delta_records != PackedByteArray(DELTA_DATA):
		return _fail("Bank-2 raster delta source bytes are missing or changed.")
	_table = PackedByteArray()
	_table.resize(RAM_TABLE_SIZE)
	_table.fill(0)
	# $8920 copies source byte 0 to $79, clears $7A, leaves $7B alone,
	# then copies source bytes 1..18 to $7C..$8D.
	_table[1] = preset[0]
	_table[2] = 0
	for source_index in range(1, preset.size()):
		_table[3 + source_index] = preset[source_index]
	_fractional_accumulators = [0, 0, 0, 0, 0]
	_initial_latch_scroll_x = int(_table[2])
	_initial_latch_page_byte = int(_table[3])
	_start_source_frame = start_source_frame
	_last_source_frame = start_source_frame
	_active = true
	return true


## Advance one frame at a time. The task is installed and first yields on its
## start frame, so its first $A2E8 update is the next scheduler release.
func advance_to_source_frame(source_frame: int) -> bool:
	if not _active:
		return _fail("Raster task generator has not been configured.")
	if source_frame < _last_source_frame:
		return _fail("Raster task generator cannot run backwards.")
	while _last_source_frame < source_frame:
		_last_source_frame += 1
		if _stop_producer_before_source_frame >= 0 \
				and _last_source_frame >= _stop_producer_before_source_frame:
			_producer_stopped = true
		if _last_source_frame >= _start_source_frame + FIRST_PRODUCER_SOURCE_FRAME_OFFSET:
			# The vblank setup latches the previous frame's camera accumulator;
			# the cooperative raster producer updates RAM $7A/$7B later in this
			# source frame. Frame 506 demonstrates this: PPU $2005=$07 while the
			# frame-end RAM snapshot has already advanced $7A to $08.
			_initial_latch_scroll_x = int(_table[2])
			_initial_latch_page_byte = int(_table[3])
			if not _producer_stopped:
				_advance_one_scheduler_release()
	return true


## The same-input opening capture has worker slot $0D inactive on the Start
## frame. Stop only the producer at that boundary, leaving its already
## programmed IRQ table active for the final rendered field frame.
func stop_producer_before_source_frame(source_frame: int) -> bool:
	if not _active or source_frame <= _last_source_frame:
		return _fail("Producer stop must target a future source frame while the raster task is active.")
	_stop_producer_before_source_frame = source_frame
	return true


## Return frame-end RAM $78..$8D. The ROM IRQ consumer uses cursor 4, advances
## by three for each event, then writes zero at its terminal marker.
func frame_end_table_bytes() -> PackedByteArray:
	var result := _table.duplicate()
	if result.size() == RAM_TABLE_SIZE:
		result[0] = 0
	return result


## Source-derived per-frame events. The first IRQ line is twice $79 plus one;
## each subsequent interval is marker*2+2. A high-bit marker selects $2006.
func raster_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _active or _table.size() != RAM_TABLE_SIZE:
		return result
	# The field setup writes PPUCTRL=$88|$7B and PPUSCROLL=$7A,$FF
	# before visible rendering. The first table-driven IRQ event occurs later,
	# at scanline 2*$79+1; without this pre-render latch the initial camera X
	# is omitted from rows 0..48 (for example frame 721 writes $15,$FF while
	# RAM $7A=$15). The decoded shared setup routine is $A086-$A091.
	var initial_page_bit := _initial_latch_page_byte & 0x01
	result.append({
		"kind": "scroll",
		"scanline": 0,
		"scroll_x": _initial_latch_scroll_x,
		"control_nametable_bit": initial_page_bit,
		"ppuctrl_nametable_bit_observed": initial_page_bit,
		"control_value": 0x88 | initial_page_bit,
		"scroll_y_base": 0xFF,
		"source_pc": "$A086-$A091 previous-frame vblank scroll latch",
	})
	var cursor := EVENT_CURSOR_INITIAL
	var scanline := int(_table[1]) * 2 + 1
	for _event_index in range(8):
		if cursor < 0 or cursor + 2 >= _table.size():
			break
		var marker := int(_table[cursor])
		if (marker & 0x80) != 0:
			result.append({
				"kind": "ppu_address",
				"scanline": scanline,
				"cursor": cursor,
				"marker": marker,
				"address": (int(_table[cursor + 2]) << 8) | int(_table[cursor + 1]),
			})
			# The bank-2 IRQ consumer performs the terminal $2006 reload first,
			# then writes $2005=$00,$00 at the following scanline boundary. This
			# clears the fine-X value left by the preceding scroll marker. The
			# synchronized capture records $A187/$A18A after $A178/$A17B; see the
			# source trace and frame-502/506/758/800 bus rows.
			result.append({
				"kind": "scroll",
				"scanline": scanline + 1,
				"cursor": cursor,
				"marker": marker,
				"scroll_x": 0,
				"control_nametable_bit": 0,
				"source": "post-$2006 $2005=$00,$00 reset at $A187/$A18A",
			})
			break
		result.append({
			"kind": "scroll",
			"scanline": scanline,
			"cursor": cursor,
			"marker": marker,
			"scroll_x": int(_table[cursor + 1]),
			"control_nametable_bit": int(_table[cursor + 2]) & 0x01,
		})
		scanline += (marker & 0x7F) * 2 + 2
		cursor += 3
	return result


func debug_snapshot() -> Dictionary:
	return {
		"active": _active,
		"start_source_frame": _start_source_frame,
		"last_source_frame": _last_source_frame,
		"event_phase_ed": 0,
		"scheduler_task_delay": 1 if _active else 0,
		"scheduler_task_slot": 0x0D,
		"producer_stopped": _producer_stopped,
		"producer_stop_before_source_frame": _stop_producer_before_source_frame,
		"fractional_accumulators": _fractional_accumulators.duplicate(),
		"initial_latch_scroll_x": _initial_latch_scroll_x,
		"initial_latch_page_byte": _initial_latch_page_byte,
		"ram_0078_008d": frame_end_table_bytes(),
		"events": raster_events(),
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"delta_file_offset": "0x004AEF",
		"preset_file_offset": "0x00DF6F",
	}


func _advance_one_scheduler_release() -> void:
	for slot in range(5):
		var delta_index := slot * 2
		var fraction_sum := _fractional_accumulators[slot] + int(_delta_records[delta_index])
		_fractional_accumulators[slot] = fraction_sum & 0xFF
		var carry_from_fraction := 1 if fraction_sum > 0xFF else 0
		var integer_delta := int(_delta_records[delta_index + 1])
		if integer_delta >= 0x80:
			integer_delta -= 0x100
		var low_index := 2 + slot * 3
		var high_index := low_index + 1
		var low_sum := int(_table[low_index]) + integer_delta + carry_from_fraction
		var carry_to_high := 1 if low_sum > 0xFF else 0
		_table[low_index] = low_sum & 0xFF
		var high_delta := -1 if integer_delta < 0 else 0
		_table[high_index] = (int(_table[high_index]) + high_delta + carry_to_high) & 0xFF
	_table[0] = EVENT_CURSOR_INITIAL


func _fail(message: String) -> bool:
	last_error = message
	_active = false
	return false
