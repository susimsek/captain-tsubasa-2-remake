extends RefCounted
class_name RomRunnerMotionRecord
## Source-backed 16-byte motion state for opening animations $6E, $A2, and $7D.
## F1/F7 setup is read from extracted ROM animation bytes and the decoded tick
## schedule; the per-tick update follows bank-0 subroutine $975B.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ANIMATION_ID := "0x6E"
const ANIMATION_BINARY_PATH := "res://reference/rom_extract/intro/animation_6E.bin"
const ANIMATION_TIMING_PATH := "res://reference/rom_extract/intro/animation_timing_entry.json"
const ANIMATION_BINARY_FILE_OFFSET := 0x0140D6
const ANIMATION_BINARY_SIZE := 42
const A2_ANIMATION_ID := "0xA2"
const A2_ANIMATION_BINARY_PATH := "res://reference/rom_extract/intro/animation_A2.bin"
const A2_ANIMATION_BINARY_FILE_OFFSET := 0x01451E
const A2_ANIMATION_BINARY_SIZE := 28
const A2_INITIAL_TRACE_FLAGS := 0x89 # Inferred from observed post-F7 $A9 and the handler's OR #$20.
const SEVEN_D_ANIMATION_ID := "0x7D"
const SEVEN_D_ANIMATION_BINARY_PATH := "res://reference/rom_extract/intro/animation_7D.bin"
const SEVEN_D_ANIMATION_BINARY_FILE_OFFSET := 0x0141DA
const SEVEN_D_ANIMATION_BINARY_SIZE := 50
const SEVEN_D_INITIAL_TRACE_FLAGS := 0x89 # Inferred from post-F7 $A9 and the handler's OR #$20.

const RECORD_SIZE := 16
const FLAG_OFFSET := 0x00
const INITIAL_TRACE_FLAGS := 0x81
const POSITION_Y_OFFSET := 0x04
const POSITION_X_OFFSET := 0x06
const VELOCITY_Y_OFFSET := 0x08
const ACCELERATION_Y_OFFSET := 0x0A
const VELOCITY_X_OFFSET := 0x0C
const ACCELERATION_X_OFFSET := 0x0E
const MOTION_ENABLED_FLAG := 0x20

var last_error := ""
var initialized := false

var _record := PackedByteArray()
var _physics_events: Array[Dictionary] = []
var _a2_motion_events: Array[Dictionary] = []
var _7d_motion_events: Array[Dictionary] = []
var _applied_f7_source_frames: Array[int] = []
var _repeat_cycle_start_tick := -1
var _repeat_cycle_length_ticks := 0
var _start_source_frame := -1
var _last_source_frame := -1
var _initial_y := -1
var _initial_x := -1
var _initial_trace_flags := INITIAL_TRACE_FLAGS
var _a2_mode := false
var _7d_mode := false


func configure(start_source_frame: int) -> bool:
	_reset()
	if start_source_frame < 0:
		return _fail("Runner animation needs a nonnegative source-frame anchor.")
	if not _load_rom_timeline():
		return false
	_record.resize(RECORD_SIZE)
	_record.fill(0)
	_start_source_frame = start_source_frame
	_initial_trace_flags = INITIAL_TRACE_FLAGS
	initialized = true
	return true


## Configures only the observed $A2 F1/F7 forms from the frame-2367 multi-object
## animation set. OAM overflow coordinates are exposed separately for the
## source-backed `$94D8`/`$A8CE` sprite culling path.
func configure_a2(start_source_frame: int) -> bool:
	_reset()
	if start_source_frame < 0:
		return _fail("A2 animation needs a nonnegative source-frame anchor.")
	if not _load_a2_rom_timeline():
		return false
	_record.resize(RECORD_SIZE)
	_record.fill(0)
	_start_source_frame = start_source_frame
	_initial_trace_flags = A2_INITIAL_TRACE_FLAGS
	_a2_mode = true
	initialized = true
	return true


## Configures the observed F1/F7 timeline for animation $7D in the frame-2367
## three-object scene. Its packed horizontal $F7 form is accepted only after
## validating this exact ROM entry and timing schedule.
func configure_7d(start_source_frame: int) -> bool:
	_reset()
	if start_source_frame < 0:
		return _fail("7D animation needs a nonnegative source-frame anchor.")
	if not _load_7d_rom_timeline():
		return false
	_record.resize(RECORD_SIZE)
	_record.fill(0)
	_start_source_frame = start_source_frame
	_initial_trace_flags = SEVEN_D_INITIAL_TRACE_FLAGS
	_7d_mode = true
	initialized = true
	return true


## Advances in the same order seen in the ROM trace: an already-active motion
## record integrates on the frame first, then any animation-bytecode F7 at that
## tick replaces its parameters. Tick 0 applies F1/F7 without an integration.
func advance_to_source_frame(source_frame: int) -> bool:
	if not initialized:
		return _fail("Runner motion record was not configured from ROM data.")
	if source_frame < _start_source_frame:
		return false
	if _a2_mode:
		return _advance_a2_to_source_frame(source_frame)
	if _7d_mode:
		return _advance_7d_to_source_frame(source_frame)
	if _last_source_frame < _start_source_frame:
		# The live trace shows these pre-existing object flag bits before F7 ORs
		# in the motion-enabled bit ($20), producing $A1 at the tick-zero event.
		_record[FLAG_OFFSET] = INITIAL_TRACE_FLAGS
		_write_initial_position()
		if not _apply_f7_events_at_tick(0):
			return false
		_last_source_frame = _start_source_frame
	if source_frame <= _last_source_frame:
		return true
	for next_source_frame: int in range(_last_source_frame + 1, source_frame + 1):
		if (_record[FLAG_OFFSET] & MOTION_ENABLED_FLAG) != 0:
			_integrate_axis(POSITION_Y_OFFSET, VELOCITY_Y_OFFSET, ACCELERATION_Y_OFFSET)
			_integrate_axis(POSITION_X_OFFSET, VELOCITY_X_OFFSET, ACCELERATION_X_OFFSET)
		var relative_tick := next_source_frame - _start_source_frame
		if not _apply_f7_events_at_tick(relative_tick):
			return false
		_last_source_frame = next_source_frame
	return true


func screen_x() -> int:
	var raw_position := _read_u16(POSITION_X_OFFSET)
	var signed_position := raw_position - 0x10000 if raw_position >= 0x8000 else raw_position
	# Existing renderer convention: signed Q8.8 animation coordinates are doubled
	# for OAM and floored to a screen pixel.
	return int(floor(float(signed_position) / 128.0))


func screen_y() -> int:
	var raw_position := _read_u16(POSITION_Y_OFFSET)
	var signed_position := raw_position - 0x10000 if raw_position >= 0x8000 else raw_position
	return int(floor(float(signed_position) / 128.0))


## Returns the unsigned doubled OAM coordinate before its low-byte wrap.
## `$94D8` uses the coordinate's ninth bit to set the X/Y overflow marker
## (`$04/$08`) that `$A8CE` later culls by writing DMA Y=`$F8`.
func oam_x_unwrapped_pixels() -> int:
	return _read_u16(POSITION_X_OFFSET) >> 7


func oam_y_unwrapped_pixels() -> int:
	return _read_u16(POSITION_Y_OFFSET) >> 7


func snapshot() -> Dictionary:
	return {
		"animation_id": A2_ANIMATION_ID if _a2_mode else (SEVEN_D_ANIMATION_ID if _7d_mode else ANIMATION_ID),
		"source_frame": _last_source_frame,
		"relative_animation_tick": _last_source_frame - _start_source_frame,
		"record_bytes_hex": _record.hex_encode().to_upper(),
		"position_y_q8_8": "$%04X" % _read_u16(POSITION_Y_OFFSET),
		"position_x_q8_8": "$%04X" % _read_u16(POSITION_X_OFFSET),
		"velocity_y_q8_8": "$%04X" % _read_u16(VELOCITY_Y_OFFSET),
		"acceleration_y_i8": "$%02X" % _record[ACCELERATION_Y_OFFSET],
		"velocity_x_q8_8": "$%04X" % _read_u16(VELOCITY_X_OFFSET),
		"acceleration_x_i8": "$%02X" % _record[ACCELERATION_X_OFFSET],
		"initial_trace_flags": "$%02X" % _initial_trace_flags,
		"reserved_initial_bytes_unmodeled": [1, 2, 3],
		"f7_applied_source_frames": _applied_f7_source_frames.duplicate(),
		"f7_schedule_source": "ROM animation command ticks; source-frame anchor is the FB dispatch frame",
		"integrator_source": "$975B: velocity += signed8(acceleration); position += updated velocity",
		"a2_dma_hide_culling": "Q8.8 unsigned doubled OAM coordinate bit 8 sets attr $04/$08; `$A8CE` substitutes DMA Y=$F8" if _a2_mode else "not applicable to this motion path",
		"oam_x_unwrapped_pixels": oam_x_unwrapped_pixels() if _a2_mode or _7d_mode else -1,
		"oam_y_unwrapped_pixels": oam_y_unwrapped_pixels() if _a2_mode or _7d_mode else -1,
	}


func _reset() -> void:
	last_error = ""
	initialized = false
	_record = PackedByteArray()
	_physics_events.clear()
	_a2_motion_events.clear()
	_7d_motion_events.clear()
	_applied_f7_source_frames.clear()
	_repeat_cycle_start_tick = -1
	_repeat_cycle_length_ticks = 0
	_start_source_frame = -1
	_last_source_frame = -1
	_initial_y = -1
	_initial_x = -1
	_initial_trace_flags = INITIAL_TRACE_FLAGS
	_a2_mode = false
	_7d_mode = false


func _load_rom_timeline() -> bool:
	if not FileAccess.file_exists(ANIMATION_BINARY_PATH):
		return _fail("ROM animation $6E bytes are missing.")
	var animation_bytes := FileAccess.get_file_as_bytes(ANIMATION_BINARY_PATH)
	if animation_bytes.size() != ANIMATION_BINARY_SIZE:
		return _fail("ROM animation $6E byte stream has an unexpected size.")
	if not FileAccess.file_exists(ANIMATION_TIMING_PATH):
		return _fail("ROM animation timing table is missing.")
	var timing_document: Variant = JSON.parse_string(FileAccess.get_file_as_string(ANIMATION_TIMING_PATH))
	if not timing_document is Dictionary:
		return _fail("ROM animation timing table is not a JSON object.")
	if str(timing_document.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("ROM animation timing table belongs to a different ROM revision.")

	var animation: Dictionary = {}
	var animation_variants: Variant = timing_document.get("animations", [])
	if not animation_variants is Array:
		return _fail("ROM animation timing table has no animation list.")
	for animation_variant: Variant in animation_variants:
		if animation_variant is Dictionary \
				and str(animation_variant.get("animation_id", "")) == ANIMATION_ID:
			animation = animation_variant
			break
	if animation.is_empty():
		return _fail("ROM animation $6E timing entry was not found.")
	if int(animation.get("prg_bank", -1)) != 10 \
			or str(animation.get("start_cpu_address", "")) != "0xA0C6":
		return _fail("ROM animation $6E pointer/bank does not match the verified Turkish entry.")

	var terminal_variant: Variant = animation.get("terminal", {})
	if not terminal_variant is Dictionary \
			or str(terminal_variant.get("kind", "")) != "repeat_cycle":
		return _fail("ROM animation $6E has no decoded repeat-cycle boundary.")
	_repeat_cycle_start_tick = int(terminal_variant.get("cycle_start_tick", -1))
	_repeat_cycle_length_ticks = int(terminal_variant.get("cycle_length_ticks", 0))
	if _repeat_cycle_start_tick != 16 or _repeat_cycle_length_ticks != 24 \
			or int(terminal_variant.get("at_relative_tick", -1)) != 40 \
			or str(terminal_variant.get("cpu_address", "")) != "0xA0DD":
		return _fail("ROM animation $6E repeat-cycle boundary does not match its traced loop bytes.")

	var found_initial_position := false
	var found_initial_f7 := false
	var found_cycle_f7 := false
	var command_variants: Variant = animation.get("commands", [])
	if not command_variants is Array:
		return _fail("ROM animation $6E has no decoded command list.")
	for command_variant: Variant in command_variants:
		if not command_variant is Dictionary:
			continue
		var command: Dictionary = command_variant
		var command_kind := str(command.get("kind", ""))
		var command_tick := int(command.get("at_relative_tick", -1))
		if command_kind == "set_y_x":
			if command_tick != 0 or found_initial_position \
					or str(command.get("cpu_address", "")) != "0xA0C7" \
					or str(command.get("file_offset", "")) != "0x0140D7" \
					or not _matches_animation_command(command, animation_bytes, 3):
				return _fail("ROM animation $6E F1 origin bytes do not match the timing record.")
			var position_offset := _parse_hex_int(str(command.get("file_offset", ""))) \
					- ANIMATION_BINARY_FILE_OFFSET
			_initial_y = int(animation_bytes[position_offset + 1])
			_initial_x = int(animation_bytes[position_offset + 2])
			found_initial_position = true
		elif command_kind == "set_physics":
			if command_tick < 0 or not _matches_animation_command(command, animation_bytes, 4):
				return _fail("ROM animation $6E F7 bytes do not match the timing record.")
			var file_offset := _parse_hex_int(str(command.get("file_offset", "")))
			var program_offset := file_offset - ANIMATION_BINARY_FILE_OFFSET
			var operands := PackedByteArray([
				animation_bytes[program_offset + 1],
				animation_bytes[program_offset + 2],
				animation_bytes[program_offset + 3],
			])
			var expected_cpu := "0xA0CA" if command_tick == 0 else "0xA0E0"
			var expected_file_offset := "0x0140DA" if command_tick == 0 else "0x0140F0"
			var expected_operands := "050000" if command_tick == 0 else "000002"
			if command_tick not in [0, 16] \
					or str(command.get("cpu_address", "")) != expected_cpu \
					or str(command.get("file_offset", "")) != expected_file_offset \
					or operands.hex_encode() != expected_operands:
				return _fail("ROM animation $6E F7 tick/PC/operand mapping is not the verified source mapping.")
			_physics_events.append({
				"tick": command_tick,
				"operands": operands,
				"cpu_address": str(command.get("cpu_address", "")),
			})
			if command_tick == 0:
				found_initial_f7 = true
			if command_tick == _repeat_cycle_start_tick:
				found_cycle_f7 = true

	if not found_initial_position or _initial_y < 0 or _initial_x < 0 \
			or not found_initial_f7 or not found_cycle_f7:
		return _fail("ROM animation $6E lacks the observed F1/F7 setup or repeated F7 event.")
	return true


func _load_a2_rom_timeline() -> bool:
	if not FileAccess.file_exists(A2_ANIMATION_BINARY_PATH):
		return _fail("ROM animation $A2 bytes are missing.")
	var animation_bytes := FileAccess.get_file_as_bytes(A2_ANIMATION_BINARY_PATH)
	if animation_bytes.size() != A2_ANIMATION_BINARY_SIZE \
			or animation_bytes.hex_encode() != "07f1128eecf72900008dd601f700000001f0f7000000f13ebe8dd6ff":
		return _fail("ROM animation $A2 bytes do not match the verified 28-byte entry.")
	if not FileAccess.file_exists(ANIMATION_TIMING_PATH):
		return _fail("ROM animation timing table is missing.")
	var timing_document: Variant = JSON.parse_string(FileAccess.get_file_as_string(ANIMATION_TIMING_PATH))
	if not timing_document is Dictionary:
		return _fail("ROM animation timing table is not a JSON object.")
	if str(timing_document.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("ROM animation timing table belongs to a different ROM revision.")

	var animation: Dictionary = {}
	var animation_variants: Variant = timing_document.get("animations", [])
	if not animation_variants is Array:
		return _fail("ROM animation timing table has no animation list.")
	for animation_variant: Variant in animation_variants:
		if animation_variant is Dictionary \
				and str(animation_variant.get("animation_id", "")) == A2_ANIMATION_ID:
			animation = animation_variant
			break
	if animation.is_empty():
		return _fail("ROM animation $A2 timing entry was not found.")
	if int(animation.get("prg_bank", -1)) != 10 \
			or str(animation.get("start_cpu_address", "")) != "0xA50E":
		return _fail("ROM animation $A2 pointer/bank does not match the verified Turkish entry.")

	var terminal_variant: Variant = animation.get("terminal", {})
	if not terminal_variant is Dictionary \
			or str(terminal_variant.get("kind", "")) != "exit" \
			or int(terminal_variant.get("at_relative_tick", -1)) != 48 \
			or str(terminal_variant.get("cpu_address", "")) != "0xA529" \
			or str(terminal_variant.get("file_offset", "")) != "0x014539":
		return _fail("ROM animation $A2 exit does not match its decoded 48-tick stream.")

	var f1_count := 0
	var f7_count := 0
	var command_variants: Variant = animation.get("commands", [])
	if not command_variants is Array:
		return _fail("ROM animation $A2 has no decoded command list.")
	for command_variant: Variant in command_variants:
		if not command_variant is Dictionary:
			continue
		var command: Dictionary = command_variant
		var command_kind := str(command.get("kind", ""))
		var command_tick := int(command.get("at_relative_tick", -1))
		if command_kind == "set_y_x":
			var expected_cpu := "0xA50F" if command_tick == 0 else "0xA524"
			var expected_file_offset := "0x01451F" if command_tick == 0 else "0x014534"
			var expected_raw_hex := "f1 12 8e" if command_tick == 0 else "f1 3e be"
			if command_tick not in [0, 48] or f1_count >= 2 \
					or str(command.get("cpu_address", "")) != expected_cpu \
					or str(command.get("file_offset", "")) != expected_file_offset \
					or str(command.get("raw_hex", "")).replace(" ", "").to_lower() \
						!= expected_raw_hex.replace(" ", "") \
					or not _matches_animation_command(
						command, animation_bytes, 3, A2_ANIMATION_BINARY_FILE_OFFSET):
				return _fail("ROM animation $A2 F1 bytes or tick do not match the verified source.")
			var file_offset := _parse_hex_int(str(command.get("file_offset", "")))
			var program_offset := file_offset - A2_ANIMATION_BINARY_FILE_OFFSET
			_a2_motion_events.append({
				"tick": command_tick,
				"kind": "set_y_x",
				"y": int(animation_bytes[program_offset + 1]),
				"x": int(animation_bytes[program_offset + 2]),
			})
			f1_count += 1
		elif command_kind == "set_physics":
			var expected_tick := f7_count * 2
			var is_final_clear := f7_count == 24 and command_tick == 48
			if f7_count >= 25 or command_tick != expected_tick and not is_final_clear:
				return _fail("ROM animation $A2 F7 event order does not match its decoded repeat.")
			var is_periodic_clear := not is_final_clear and posmod(command_tick, 4) == 2
			var expected_cpu := "0xA520" if is_final_clear else ("0xA51A" if is_periodic_clear else "0xA513")
			var expected_file_offset := "0x014530" if is_final_clear else ("0x01452A" if is_periodic_clear else "0x014523")
			var expected_operands := "000000" if is_final_clear or is_periodic_clear else "290000"
			var expected_raw_hex := "f7 " + expected_operands.substr(0, 2) + " " \
					+ expected_operands.substr(2, 2) + " " + expected_operands.substr(4, 2)
			if str(command.get("cpu_address", "")) != expected_cpu \
					or str(command.get("file_offset", "")) != expected_file_offset \
					or str(command.get("physics_raw_hex", "")).replace(" ", "").to_lower() \
						!= expected_operands \
					or str(command.get("raw_hex", "")).replace(" ", "").to_lower() \
						!= expected_raw_hex.replace(" ", "") \
					or not _matches_animation_command(
						command, animation_bytes, 4, A2_ANIMATION_BINARY_FILE_OFFSET):
				return _fail("ROM animation $A2 F7 bytes or tick do not match the observed forms.")
			var file_offset := _parse_hex_int(str(command.get("file_offset", "")))
			var program_offset := file_offset - A2_ANIMATION_BINARY_FILE_OFFSET
			var operands := PackedByteArray([
				animation_bytes[program_offset + 1],
				animation_bytes[program_offset + 2],
				animation_bytes[program_offset + 3],
			])
			_a2_motion_events.append({"tick": command_tick, "kind": "set_physics", "operands": operands})
			f7_count += 1
	if f1_count != 2 or f7_count != 25:
		return _fail("ROM animation $A2 must contain two observed F1 events and 25 F7 events.")
	return true


func _load_7d_rom_timeline() -> bool:
	if not FileAccess.file_exists(SEVEN_D_ANIMATION_BINARY_PATH):
		return _fail("ROM animation $7D bytes are missing.")
	var animation_bytes := FileAccess.get_file_as_bytes(SEVEN_D_ANIMATION_BINARY_PATH)
	if animation_bytes.size() != SEVEN_D_ANIMATION_BINARY_SIZE \
			or animation_bytes.hex_encode() \
			!= "07f1064eecf72f00008d7201f70000008d7201f0e6f70001ff8dc20192580192970192da01f0f70001ff8d9a018d9a01a1f0":
		return _fail("ROM animation $7D bytes do not match the verified 50-byte entry.")
	if not FileAccess.file_exists(ANIMATION_TIMING_PATH):
		return _fail("ROM animation timing table is missing.")
	var timing_document: Variant = JSON.parse_string(FileAccess.get_file_as_string(ANIMATION_TIMING_PATH))
	if not timing_document is Dictionary:
		return _fail("ROM animation timing table is not a JSON object.")
	if str(timing_document.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("ROM animation timing table belongs to a different ROM revision.")

	var animation: Dictionary = {}
	var animation_variants: Variant = timing_document.get("animations", [])
	if not animation_variants is Array:
		return _fail("ROM animation timing table has no animation list.")
	for animation_variant: Variant in animation_variants:
		if animation_variant is Dictionary \
				and str(animation_variant.get("animation_id", "")) == SEVEN_D_ANIMATION_ID:
			animation = animation_variant
			break
	if animation.is_empty():
		return _fail("ROM animation $7D timing entry was not found.")
	if int(animation.get("prg_bank", -1)) != 10 \
			or str(animation.get("start_cpu_address", "")) != "0xA1CA":
		return _fail("ROM animation $7D pointer/bank does not match the verified Turkish entry.")

	var terminal_variant: Variant = animation.get("terminal", {})
	if not terminal_variant is Dictionary \
			or str(terminal_variant.get("kind", "")) != "repeat_cycle" \
			or int(terminal_variant.get("at_relative_tick", -1)) != 100 \
			or int(terminal_variant.get("cycle_start_tick", -1)) != 96 \
			or int(terminal_variant.get("cycle_length_ticks", -1)) != 4 \
			or str(terminal_variant.get("cpu_address", "")) != "0xA1F0":
		return _fail("ROM animation $7D repeat cycle does not match its source loop bytes.")
	_repeat_cycle_start_tick = 96
	_repeat_cycle_length_ticks = 4

	var expected_f7_ticks: Array[int] = []
	for tick in range(0, 48, 2):
		expected_f7_ticks.append(tick)
	for tick in range(48, 97, 8):
		expected_f7_ticks.append(tick)
	var f1_count := 0
	var f7_count := 0
	var command_variants: Variant = animation.get("commands", [])
	if not command_variants is Array:
		return _fail("ROM animation $7D has no decoded command list.")
	for command_variant: Variant in command_variants:
		if not command_variant is Dictionary:
			continue
		var command: Dictionary = command_variant
		var command_kind := str(command.get("kind", ""))
		var command_tick := int(command.get("at_relative_tick", -1))
		if command_kind == "set_y_x":
			if f1_count != 0 or command_tick != 0 \
					or str(command.get("cpu_address", "")) != "0xA1CB" \
					or str(command.get("file_offset", "")) != "0x0141DB" \
					or str(command.get("raw_hex", "")).replace(" ", "").to_lower() != "f1064e" \
					or not _matches_animation_command(
						command, animation_bytes, 3, SEVEN_D_ANIMATION_BINARY_FILE_OFFSET):
				return _fail("ROM animation $7D F1 origin does not match the verified source bytes.")
			var f1_offset := _parse_hex_int(str(command.get("file_offset", ""))) \
					- SEVEN_D_ANIMATION_BINARY_FILE_OFFSET
			_7d_motion_events.append({
				"tick": 0,
				"kind": "set_y_x",
				"y": int(animation_bytes[f1_offset + 1]),
				"x": int(animation_bytes[f1_offset + 2]),
			})
			f1_count += 1
		elif command_kind == "set_physics":
			if f7_count >= expected_f7_ticks.size() \
					or command_tick != expected_f7_ticks[f7_count] \
					or not _matches_animation_command(
						command, animation_bytes, 4, SEVEN_D_ANIMATION_BINARY_FILE_OFFSET):
				return _fail("ROM animation $7D F7 order/bytes do not match the decoded source entry.")
			var f7_offset := _parse_hex_int(str(command.get("file_offset", ""))) \
					- SEVEN_D_ANIMATION_BINARY_FILE_OFFSET
			var operands := PackedByteArray([
				animation_bytes[f7_offset + 1],
				animation_bytes[f7_offset + 2],
				animation_bytes[f7_offset + 3],
			])
			var expected_operands := "2f0000" if command_tick < 48 and posmod(command_tick, 4) == 0 \
					else ("000000" if command_tick < 48 else "0001ff")
			if operands.hex_encode() != expected_operands \
					or str(command.get("physics_raw_hex", "")).replace(" ", "").to_lower() \
					!= expected_operands:
				return _fail("ROM animation $7D uses an F7 form outside its verified $2F/zero/$00-$01-$FF sequence.")
			_7d_motion_events.append({
				"tick": command_tick,
				"kind": "set_physics",
				"operands": operands,
				"cpu_address": str(command.get("cpu_address", "")),
			})
			f7_count += 1
	if f1_count != 1 or f7_count != expected_f7_ticks.size():
		return _fail("ROM animation $7D must contain its F1 origin and 31 verified F7 commands.")
	return true


func _matches_animation_command(command: Dictionary, animation_bytes: PackedByteArray,
		byte_count: int, animation_file_offset: int = ANIMATION_BINARY_FILE_OFFSET) -> bool:
	var file_offset := _parse_hex_int(str(command.get("file_offset", "")))
	var program_offset := file_offset - animation_file_offset
	if program_offset < 0 or program_offset + byte_count > animation_bytes.size():
		return false
	var expected_hex := str(command.get("raw_hex", "")).replace(" ", "").to_lower()
	var actual_hex := animation_bytes.slice(program_offset, program_offset + byte_count).hex_encode().to_lower()
	return expected_hex == actual_hex


func _advance_a2_to_source_frame(source_frame: int) -> bool:
	if _last_source_frame < _start_source_frame:
		# The post-F7 A2 flag byte is $A9 in the RAM anchor. The handler sets bit
		# $20, so the pre-handler base is modeled as $89; other flag uses are not
		# part of this motion slice.
		_record[FLAG_OFFSET] = _initial_trace_flags
		if not _apply_a2_motion_events_at_tick(0):
			return false
		_last_source_frame = _start_source_frame
	if source_frame <= _last_source_frame:
		return true
	for next_source_frame: int in range(_last_source_frame + 1, source_frame + 1):
		if (_record[FLAG_OFFSET] & MOTION_ENABLED_FLAG) != 0:
			_integrate_axis(POSITION_Y_OFFSET, VELOCITY_Y_OFFSET, ACCELERATION_Y_OFFSET)
			_integrate_axis(POSITION_X_OFFSET, VELOCITY_X_OFFSET, ACCELERATION_X_OFFSET)
		var relative_tick := next_source_frame - _start_source_frame
		if not _apply_a2_motion_events_at_tick(relative_tick):
			return false
		_last_source_frame = next_source_frame
	return true


func _advance_7d_to_source_frame(source_frame: int) -> bool:
	if _last_source_frame < _start_source_frame:
		# The source frame immediately before the FB dispatch has a zeroed slot;
		# the observed post-F7 flag is $A9. Its non-motion bits are inferred from
	# the handler's OR #$20 and are not used to render this motion path.
		_record[FLAG_OFFSET] = _initial_trace_flags
		if not _apply_7d_motion_events_at_tick(0):
			return false
		_last_source_frame = _start_source_frame
	if source_frame <= _last_source_frame:
		return true
	for next_source_frame: int in range(_last_source_frame + 1, source_frame + 1):
		if (_record[FLAG_OFFSET] & MOTION_ENABLED_FLAG) != 0:
			_integrate_axis(POSITION_Y_OFFSET, VELOCITY_Y_OFFSET, ACCELERATION_Y_OFFSET)
			_integrate_axis(POSITION_X_OFFSET, VELOCITY_X_OFFSET, ACCELERATION_X_OFFSET)
		var relative_tick := next_source_frame - _start_source_frame
		if not _apply_7d_motion_events_at_tick(relative_tick):
			return false
		_last_source_frame = next_source_frame
	return true


func _apply_7d_motion_events_at_tick(relative_tick: int) -> bool:
	for event in _7d_motion_events:
		var event_tick := int(event["tick"])
		var due := relative_tick == event_tick
		if str(event["kind"]) == "set_physics" \
				and event_tick >= _repeat_cycle_start_tick \
				and relative_tick > event_tick:
			due = posmod(relative_tick - event_tick, _repeat_cycle_length_ticks) == 0
		if not due:
			continue
		if str(event["kind"]) == "set_y_x":
			_write_u16(POSITION_Y_OFFSET, int(event["y"]) << 8)
			_write_u16(POSITION_X_OFFSET, int(event["x"]) << 8)
		elif str(event["kind"]) == "set_physics":
			var operands: PackedByteArray = event["operands"]
			if not _apply_7d_observed_f7(operands):
				return false
			_applied_f7_source_frames.append(_start_source_frame + relative_tick)
	return true


func _apply_7d_observed_f7(operands: PackedByteArray) -> bool:
	if operands == PackedByteArray([0x2F, 0x00, 0x00]):
		# Bank-0 $93DE takes the horizontal packed/sign branch for $2F: the
		# vertical normal parser yields VY=$0100, and the sign-extended horizontal
		# bytes yield VX=$FF80. The frame-2367 $05A8 snapshot verifies these fields.
		_record[VELOCITY_Y_OFFSET] = 0x00
		_record[VELOCITY_Y_OFFSET + 1] = 0x01
		_record[ACCELERATION_Y_OFFSET] = 0x00
		_record[VELOCITY_X_OFFSET] = 0x80
		_record[VELOCITY_X_OFFSET + 1] = 0xFF
		_record[ACCELERATION_X_OFFSET] = 0x00
		_record[0x0B] = 0
		_record[0x0F] = 0
		_record[FLAG_OFFSET] = int(_record[FLAG_OFFSET]) | MOTION_ENABLED_FLAG
		return true
	if operands == PackedByteArray([0x00, 0x00, 0x00]) \
			or operands == PackedByteArray([0x00, 0x01, 0xFF]):
		return _apply_f7_normal_operands(operands)
	return _fail("7D F7 form is outside the byte-verified $2F/$00/$01/$FF sequence.")


func _apply_a2_motion_events_at_tick(relative_tick: int) -> bool:
	for event in _a2_motion_events:
		if int(event["tick"]) != relative_tick:
			continue
		if str(event["kind"]) == "set_y_x":
			_write_u16(POSITION_Y_OFFSET, int(event["y"]) << 8)
			_write_u16(POSITION_X_OFFSET, int(event["x"]) << 8)
		elif str(event["kind"]) == "set_physics":
			var operands: PackedByteArray = event["operands"]
			if not _apply_a2_observed_f7(operands):
				return false
			_applied_f7_source_frames.append(_start_source_frame + relative_tick)
	return true


func _apply_a2_observed_f7(operands: PackedByteArray) -> bool:
	if operands == PackedByteArray([0x29, 0x00, 0x00]):
		# ROM $93A7/$93DE decodes this packed operand to VY=$0100 and VX=$FC80;
		# both one-byte accelerations are zero.
		_record[VELOCITY_Y_OFFSET] = 0x00
		_record[VELOCITY_Y_OFFSET + 1] = 0x01
		_record[ACCELERATION_Y_OFFSET] = 0x00
		_record[VELOCITY_X_OFFSET] = 0x80
		_record[VELOCITY_X_OFFSET + 1] = 0xFC
		_record[ACCELERATION_X_OFFSET] = 0x00
	elif operands == PackedByteArray([0x00, 0x00, 0x00]):
		_record[VELOCITY_Y_OFFSET] = 0
		_record[VELOCITY_Y_OFFSET + 1] = 0
		_record[ACCELERATION_Y_OFFSET] = 0
		_record[VELOCITY_X_OFFSET] = 0
		_record[VELOCITY_X_OFFSET + 1] = 0
		_record[ACCELERATION_X_OFFSET] = 0
	else:
		return _fail("A2 F7 operand form is outside the observed $29 00 00 / $00 00 00 set.")
	_record[0x0B] = 0
	_record[0x0F] = 0
	_record[FLAG_OFFSET] = int(_record[FLAG_OFFSET]) | MOTION_ENABLED_FLAG
	return true


func _apply_f7_events_at_tick(relative_tick: int) -> bool:
	for event in _physics_events:
		var event_tick := int(event["tick"])
		var due := relative_tick == event_tick
		if event_tick >= _repeat_cycle_start_tick and relative_tick > event_tick:
			due = posmod(relative_tick - event_tick, _repeat_cycle_length_ticks) == 0
		if not due:
			continue
		var operands: PackedByteArray = event["operands"]
		if not _apply_f7_normal_operands(operands):
			return false
		_applied_f7_source_frames.append(_start_source_frame + relative_tick)
	return true


## Implements the observed normal branch of bank-0 F7 at $93A7/$93DE. Other
## packed/special encodings are deliberately rejected until live-traced.
func _apply_f7_normal_operands(operands: PackedByteArray) -> bool:
	if operands.size() != 3:
		return _fail("ROM F7 requires three operand bytes.")
	var first_operand := int(operands[0])
	var vertical_packed := first_operand >> 5
	if (vertical_packed & 0x04) != 0:
		return _fail("Runner F7 selected the untraced packed vertical branch.")
	var vertical_carry := 1 if (first_operand & 0x10) != 0 else 0
	_record[0x09] = vertical_packed & 0xFF
	_record[0x08] = ((vertical_packed >> 1) | (vertical_carry << 7)) & 0xFF
	_record[0x0A] = int(operands[1])

	var horizontal_packed := (first_operand & 0x0F) >> 1
	if (horizontal_packed & 0x04) != 0:
		return _fail("Runner F7 selected the untraced packed horizontal branch.")
	var horizontal_carry := 1 if (first_operand & 0x01) != 0 else 0
	_record[0x0D] = horizontal_packed & 0xFF
	_record[0x0C] = (((horizontal_packed & 0x04) >> 1) | (horizontal_carry << 7)) & 0xFF
	_record[0x0E] = int(operands[2])
	_record[0x0B] = 0
	_record[0x0F] = 0
	_record[FLAG_OFFSET] = int(_record[FLAG_OFFSET]) | MOTION_ENABLED_FLAG
	return true


func _write_initial_position() -> void:
	_write_u16(POSITION_Y_OFFSET, _initial_y << 8)
	_write_u16(POSITION_X_OFFSET, _initial_x << 8)


func _integrate_axis(position_offset: int, velocity_offset: int,
		acceleration_offset: int) -> void:
	var acceleration := _signed_byte(int(_record[acceleration_offset]))
	var velocity := (_read_u16(velocity_offset) + acceleration) & 0xFFFF
	_write_u16(velocity_offset, velocity)
	var position := (_read_u16(position_offset) + velocity) & 0xFFFF
	_write_u16(position_offset, position)


func _read_u16(offset: int) -> int:
	return int(_record[offset]) | (int(_record[offset + 1]) << 8)


func _write_u16(offset: int, value: int) -> void:
	var wrapped := value & 0xFFFF
	_record[offset] = wrapped & 0xFF
	_record[offset + 1] = (wrapped >> 8) & 0xFF


func _signed_byte(value: int) -> int:
	return value - 0x100 if value >= 0x80 else value


func _parse_hex_int(value: String) -> int:
	var normalized := value.strip_edges().to_lower()
	if normalized.begins_with("0x"):
		normalized = normalized.substr(2)
	if normalized.is_empty():
		return -1
	return normalized.hex_to_int()


func _fail(reason: String) -> bool:
	last_error = reason
	initialized = false
	return false
