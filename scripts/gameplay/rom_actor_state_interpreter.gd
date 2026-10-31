extends RefCounted
class_name RomActorStateInterpreter
## Executes the preserved bank-$14 appearance/motion actor script slice.
## This is a bounded source interpreter, not the route scheduler or an OAM renderer.

class TickResult:
	extends RefCounted

	var ok: bool = false
	var actor_record: PackedByteArray = PackedByteArray()
	var appearance_events: Array[String] = []
	var motion_events: Array[String] = []
	var error: String = ""


const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_DIR := "res://reference/rom_extract/gameplay/actor_state_interpreter/"
const MANIFEST_PATH := SOURCE_DIR + "manifest.json"
const EXPECTED_SCHEMA := "ct2-bank14-actor-interpreter-source-v1"
const ACTOR_RECORD_BYTES := 21
const APPEARANCE_TIMER_OFFSET := 0x10
const MOTION_TIMER_OFFSET := 0x11
const APPEARANCE_POINTER_OFFSET := 0x03
const MOTION_POINTER_OFFSET := 0x01
const APPEARANCE_DESCRIPTOR_OFFSET := 0x12
const MOTION_X_DELTA_LOW_OFFSET := 0x05
const MOTION_X_DELTA_HIGH_OFFSET := 0x07
const MOTION_Y_DELTA_LOW_OFFSET := 0x09
const MOTION_Y_DELTA_HIGH_OFFSET := 0x0B

const RESOURCE_SPECS := {
	"appearance_interpreter_83D9_84DB.bin": {
		"file_offset": 0x0283E9, "length_bytes": 0x0103,
		"cpu_start": "$83D9", "cpu_end_exclusive": "$84DC",
		"sha256": "776dad1dab540ed1151725c48ea4be2b99dd0f75a27bee293b0b523760eec411",
	},
	"motion_interpreter_84DC_8623.bin": {
		"file_offset": 0x0284EC, "length_bytes": 0x0148,
		"cpu_start": "$84DC", "cpu_end_exclusive": "$8624",
		"sha256": "3f9bb278daab82f6b76b2d89cbd91d327dd0202b3bc6e594dd1734fa1882f380",
	},
	"appearance_loop_B026_B030.bin": {
		"file_offset": 0x02B036, "length_bytes": 0x000B,
		"cpu_start": "$B026", "cpu_end_exclusive": "$B031",
		"sha256": "ddadf844964526d70fe2b454781c33d00d0038447290a4132699f633f3c7ec7c",
	},
	"appearance_hold_B5AC_B5B3.bin": {
		"file_offset": 0x02B5BC, "length_bytes": 0x0008,
		"cpu_start": "$B5AC", "cpu_end_exclusive": "$B5B4",
		"sha256": "271792914b8d88c9f0df0d1bb6571ebf4bbec5785eadbb2b934872fedc155af2",
	},
	"fresh_actor_appearance_roots_B30E_B313.bin": {
		"file_offset": 0x02B31E, "length_bytes": 0x0006,
		"cpu_start": "$B30E", "cpu_end_exclusive": "$B314",
		"sha256": "91f6198e377498f48b5bd9fd659fd6a7fbcd76f417abf679e2ef16bdee9228d2",
	},
	"motion_step_A38A_A390.bin": {
		"file_offset": 0x02A39A, "length_bytes": 0x0007,
		"cpu_start": "$A38A", "cpu_end_exclusive": "$A391",
		"sha256": "95a66c8108f14acbb8740fd154087efd6230f204ceec3dcf198c3ac07ac31e7f",
	},
	"fresh_actor_motion_roots_A723_A734.bin": {
		"file_offset": 0x02A733, "length_bytes": 0x0012,
		"cpu_start": "$A723", "cpu_end_exclusive": "$A735",
		"sha256": "c68a7d28f793918e44b5b1362ba62a9ab07001d8f1ea2d9177672dd544b0d10e",
	},
}

const APPEARANCE_LOOP_CPU_START := 0xB026
const APPEARANCE_LOOP_CPU_END := 0xB031
const APPEARANCE_HOLD_CPU_START := 0xB5AC
const APPEARANCE_HOLD_CPU_END := 0xB5B4
const FRESH_APPEARANCE_ROOT_CPU_START := 0xB30E
const FRESH_APPEARANCE_ROOT_CPU_END := 0xB314
const MOTION_STEP_CPU_START := 0xA38A
const MOTION_STEP_CPU_END := 0xA391
const FRESH_MOTION_ROOTS_CPU_START := 0xA723
const FRESH_MOTION_ROOTS_CPU_END := 0xA735

var last_error: String = ""
var is_configured: bool = false
var _resources: Dictionary = {}


## Loads only project-owned, SHA-256-pinned ROM source spans.
func configure() -> bool:
	last_error = ""
	is_configured = false
	_resources.clear()
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var manifest_variant: Variant = JSON.parse_string(manifest_text)
	if not manifest_variant is Dictionary:
		return _fail("Actor interpreter source manifest is missing or malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != EXPECTED_SCHEMA \
			or str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(manifest.get("prg_bank", "")) != "$14" \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("capture_or_screenshot_bytes_included", true)):
		return _fail("Actor interpreter manifest does not match the target-ROM source contract.")
	var resources_variant: Variant = manifest.get("resources", null)
	if not resources_variant is Array:
		return _fail("Actor interpreter manifest has no resource list.")
	var entries_by_name: Dictionary = {}
	for entry_variant in resources_variant:
		if not entry_variant is Dictionary:
			return _fail("Actor interpreter manifest contains a malformed resource entry.")
		var entry: Dictionary = entry_variant
		var name := str(entry.get("name", ""))
		if entries_by_name.has(name):
			return _fail("Actor interpreter manifest repeats resource " + name + ".")
		entries_by_name[name] = entry

	for name_variant in RESOURCE_SPECS:
		var resource_name := str(name_variant)
		if not entries_by_name.has(resource_name):
			return _fail("Actor interpreter source span is missing: " + resource_name)
		var spec: Dictionary = RESOURCE_SPECS[resource_name]
		var entry: Dictionary = entries_by_name[resource_name]
		if int(entry.get("file_offset", -1)) != int(spec["file_offset"]) \
				or int(entry.get("length_bytes", -1)) != int(spec["length_bytes"]) \
				or str(entry.get("cpu_start", "")) != str(spec["cpu_start"]) \
				or str(entry.get("cpu_end_exclusive", "")) != str(spec["cpu_end_exclusive"]) \
				or str(entry.get("sha256", "")) != str(spec["sha256"]) \
				or str(entry.get("prg_bank", "")) != "$14":
			return _fail("Actor interpreter source metadata differs from the pinned ROM span: " + resource_name)
		var resource_path := SOURCE_DIR + resource_name
		var source_bytes := FileAccess.get_file_as_bytes(resource_path)
		if source_bytes.size() != int(spec["length_bytes"]) \
				or _sha256(source_bytes) != str(spec["sha256"]):
			return _fail("Actor interpreter byte span failed its SHA-256 check: " + resource_name)
		_resources[resource_name] = source_bytes

	if not _matches_motion_step(_resources["motion_step_A38A_A390.bin"]):
		return _fail("The motion-step fixture bytes differ from the exact source sequence.")
	if not _matches_fresh_motion_roots(_resources["fresh_actor_motion_roots_A723_A734.bin"]):
		return _fail("The animation-$8F motion-root bytes differ from the exact source loops.")
	is_configured = true
	return true


## Executes one appearance update followed by one motion update, matching the
## order used for each active actor record in the ROM's $EE9F loop.
func tick_actor(source_record: PackedByteArray) -> TickResult:
	var result := tick_appearance_only(source_record)
	if not result.ok:
		return result
	if not _tick_motion(result.actor_record, result):
		return result
	result.ok = true
	return result


## Advances only the source appearance stream. This is useful when an actor's
## selected motion cursor is outside the separately verified motion slice; it
## never silently applies a substitute movement model.
func tick_appearance_only(source_record: PackedByteArray) -> TickResult:
	var result := TickResult.new()
	result.actor_record = source_record.duplicate()
	if not is_configured:
		result.error = "Configure the hash-checked ROM actor source before ticking."
		return result
	if result.actor_record.size() != ACTOR_RECORD_BYTES:
		result.error = "A ROM actor record must contain exactly 21 bytes."
		return result
	if not _tick_appearance(result.actor_record, result):
		return result
	result.ok = true
	return result


## Advances only the source motion stream, for the ROM's `$0615.6` branch that
## skips appearance but still calls the `$84DC` updater.
func tick_motion_only(source_record: PackedByteArray) -> TickResult:
	var result := TickResult.new()
	result.actor_record = source_record.duplicate()
	if not is_configured:
		result.error = "Configure the hash-checked ROM actor source before ticking."
		return result
	if result.actor_record.size() != ACTOR_RECORD_BYTES:
		result.error = "A ROM actor record must contain exactly 21 bytes."
		return result
	if not _tick_motion(result.actor_record, result):
		return result
	result.ok = true
	return result


func _tick_appearance(record: PackedByteArray, result: TickResult) -> bool:
	var timer := int(record[APPEARANCE_TIMER_OFFSET])
	if timer != 0:
		if timer == 0xFF:
			result.appearance_events.append("hold")
			return true
		record[APPEARANCE_TIMER_OFFSET] = timer - 1
		result.appearance_events.append("timer:%d->%d" % [timer, timer - 1])
		return true

	var cursor := _read_u16(record, APPEARANCE_POINTER_OFFSET)
	for _command_index in 64:
		var opcode := _source_byte_at(cursor)
		if opcode < 0:
			result.error = "Appearance stream pointer $%04X is outside the preserved source spans." % cursor
			return false
		if opcode < 0xF0:
			var descriptor := _source_byte_at(cursor + 1)
			if descriptor < 0:
				result.error = "Appearance timed pair at $%04X is truncated." % cursor
				return false
			record[APPEARANCE_TIMER_OFFSET] = opcode
			record[APPEARANCE_DESCRIPTOR_OFFSET] = descriptor
			_write_u16(record, APPEARANCE_POINTER_OFFSET, cursor + 2)
			result.appearance_events.append("pair:$%04X wait=%d descriptor=$%02X" % [cursor, opcode, descriptor])
			return true
		match opcode:
			0xF0:
				record[APPEARANCE_TIMER_OFFSET] = 0xFF
				result.appearance_events.append("end-hold:$%04X" % cursor)
				return true
			0xF3:
				var target := _source_word_at(cursor + 1)
				if target < 0:
					result.error = "Appearance $F3 jump at $%04X is truncated." % cursor
					return false
				result.appearance_events.append("jump:$%04X->$%04X" % [cursor, target])
				cursor = target
				continue
			0xF7:
				var descriptor := _source_byte_at(cursor + 1)
				if descriptor < 0:
					result.error = "Appearance $F7 at $%04X is missing its descriptor." % cursor
					return false
				record[APPEARANCE_DESCRIPTOR_OFFSET] = descriptor
				record[APPEARANCE_TIMER_OFFSET] = 0xFF
				result.appearance_events.append("descriptor-hold:$%04X=$%02X" % [cursor, descriptor])
				return true
			_:
				result.error = "Appearance opcode $%02X at $%04X is outside this interpreter slice." % [opcode, cursor]
				return false
	result.error = "Appearance stream exceeded the bounded source-command budget."
	return false


func _tick_motion(record: PackedByteArray, result: TickResult) -> bool:
	var timer := int(record[MOTION_TIMER_OFFSET])
	if timer == 0xFF:
		result.motion_events.append("hold")
		return true
	var route_root := _fresh_motion_root_for_cursor(_read_u16(record, MOTION_POINTER_OFFSET))
	if route_root >= 0:
		return _tick_fresh_route_motion(record, result, route_root, timer)
	if timer != 0:
		var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
		if timer != 1 or cursor != MOTION_STEP_CPU_START + 6 or not _motion_deltas_are_zero(record):
			result.error = "Motion timer $%02X requires unsupported nonzero/general fixed-point integration." % timer
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		# The $A38A command loaded four zero deltas into the ROM's X/Y motion
		# lanes. The $852A integration path therefore leaves visible coordinates
		# unchanged while the one-count timer reaches zero.
		result.motion_events.append("integrate:$A390 timer=1->0 delta=(0,0)")
		return true

	var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	if cursor == MOTION_STEP_CPU_START:
		var step_bytes: PackedByteArray = _resources["motion_step_A38A_A390.bin"]
		if not _matches_motion_step(step_bytes):
			result.error = "Motion $01 step bytes failed their source signature."
			return false
		# Bank-$14 $85A9 calls $85E7 to load the next byte as +$11, then reads
		# two zero-byte pairs into the X/Y motion lanes and advances to $A390.
		record[MOTION_TIMER_OFFSET] = int(step_bytes[1])
		record[MOTION_X_DELTA_LOW_OFFSET] = int(step_bytes[2])
		record[MOTION_X_DELTA_HIGH_OFFSET] = int(step_bytes[3])
		record[MOTION_Y_DELTA_LOW_OFFSET] = int(step_bytes[4])
		record[MOTION_Y_DELTA_HIGH_OFFSET] = int(step_bytes[5])
		_write_u16(record, MOTION_POINTER_OFFSET, MOTION_STEP_CPU_START + 6)
		result.motion_events.append("step:$A38A timer=1 deltas=(0,0) cursor=$A390")
		return true
	if cursor == MOTION_STEP_CPU_START + 6:
		if _source_byte_at(cursor) != 0:
			result.error = "Motion stream at $A390 is not the source $00 hold command."
			return false
		record[MOTION_TIMER_OFFSET] = 0xFF
		result.motion_events.append("end-hold:$A390")
		return true
	result.error = "Motion stream pointer $%04X is outside this interpreter slice." % cursor
	return false


## Executes the exact initial $01 velocity command and self-targeting $04 loop
## selected by animation $8F. Only the two preserved roots are accepted.
func _tick_fresh_route_motion(record: PackedByteArray, result: TickResult, root: int, timer: int) -> bool:
	var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	if timer != 0:
		if cursor != root + 6:
			result.error = "Fresh motion timer $%02X is not paired with the source post-$01 cursor $%04X." % [timer, root + 6]
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$%04X timer=$%02X->$%02X" % [root, timer, timer - 1])
		return true

	if cursor == root + 6:
		var jump_opcode := _source_byte_at(cursor)
		var jump_target := _source_word_at(cursor + 1)
		if jump_opcode != 0x04 or jump_target != root:
			result.error = "Fresh motion cursor $%04X is not the byte-verified self-loop command." % cursor
			return false
		result.motion_events.append("jump:$%04X->$%04X" % [cursor, jump_target])
		cursor = jump_target
	if cursor != root or _source_byte_at(cursor) != 0x01:
		result.error = "Fresh motion root $%04X does not begin with the supported source $01 command." % root
		return false

	var duration := _source_byte_at(cursor + 1)
	var x_low := _source_byte_at(cursor + 2)
	var x_high := _source_byte_at(cursor + 3)
	var y_low := _source_byte_at(cursor + 4)
	var y_high := _source_byte_at(cursor + 5)
	if min(duration, min(x_low, min(x_high, min(y_low, y_high)))) < 0:
		result.error = "Fresh motion $01 command at $%04X is truncated." % cursor
		return false
	record[MOTION_TIMER_OFFSET] = duration
	record[MOTION_X_DELTA_LOW_OFFSET] = x_low
	record[MOTION_X_DELTA_HIGH_OFFSET] = x_high
	record[MOTION_Y_DELTA_LOW_OFFSET] = y_low
	record[MOTION_Y_DELTA_HIGH_OFFSET] = y_high
	_write_u16(record, MOTION_POINTER_OFFSET, root + 6)
	_integrate_source_motion_lanes(record)
	result.motion_events.append("step:$%04X timer=$%02X velocity=(%02X:%02X,%02X:%02X) cursor=$%04X" % [
		root, duration, x_high, x_low, y_high, y_low, root + 6,
	])
	return true


## Mirrors $852A/$85F2's two fixed-point lane updates, including the two
## high-coordinate bits packed into actor byte +$00.
func _integrate_source_motion_lanes(record: PackedByteArray) -> void:
	var high_x := int(record[0]) & 0x01
	var high_y := (int(record[0]) >> 1) & 0x01
	high_x = _integrate_source_motion_axis(record, 0x05, high_x)
	high_y = _integrate_source_motion_axis(record, 0x09, high_y)
	record[0] = (int(record[0]) & 0xFC) | (high_x & 0x01) | ((high_y & 0x01) << 1)


func _integrate_source_motion_axis(record: PackedByteArray, velocity_low_offset: int, high_coordinate: int) -> int:
	var fractional_offset := velocity_low_offset + 1
	var velocity_high_offset := velocity_low_offset + 2
	var integer_position_offset := velocity_low_offset + 3
	var fractional_sum := int(record[fractional_offset]) + int(record[velocity_low_offset])
	record[fractional_offset] = fractional_sum & 0xFF
	var carry := fractional_sum >> 8
	var signed_high_delta := int(record[velocity_high_offset])
	if signed_high_delta >= 0x80:
		high_coordinate = (high_coordinate - 1) & 0xFF
	var integer_sum := int(record[integer_position_offset]) + signed_high_delta + carry
	record[integer_position_offset] = integer_sum & 0xFF
	high_coordinate = (high_coordinate + (integer_sum >> 8)) & 0xFF
	return high_coordinate


func _motion_deltas_are_zero(record: PackedByteArray) -> bool:
	return record[MOTION_X_DELTA_LOW_OFFSET] == 0 \
			and record[MOTION_X_DELTA_HIGH_OFFSET] == 0 \
			and record[MOTION_Y_DELTA_LOW_OFFSET] == 0 \
			and record[MOTION_Y_DELTA_HIGH_OFFSET] == 0


func _source_byte_at(cpu_address: int) -> int:
	var source_name := ""
	var span_start := 0
	var span_end := 0
	if cpu_address >= APPEARANCE_LOOP_CPU_START and cpu_address < APPEARANCE_LOOP_CPU_END:
		source_name = "appearance_loop_B026_B030.bin"
		span_start = APPEARANCE_LOOP_CPU_START
		span_end = APPEARANCE_LOOP_CPU_END
	elif cpu_address >= APPEARANCE_HOLD_CPU_START and cpu_address < APPEARANCE_HOLD_CPU_END:
		source_name = "appearance_hold_B5AC_B5B3.bin"
		span_start = APPEARANCE_HOLD_CPU_START
		span_end = APPEARANCE_HOLD_CPU_END
	elif cpu_address >= FRESH_APPEARANCE_ROOT_CPU_START and cpu_address < FRESH_APPEARANCE_ROOT_CPU_END:
		source_name = "fresh_actor_appearance_roots_B30E_B313.bin"
		span_start = FRESH_APPEARANCE_ROOT_CPU_START
		span_end = FRESH_APPEARANCE_ROOT_CPU_END
	elif cpu_address >= MOTION_STEP_CPU_START and cpu_address < MOTION_STEP_CPU_END:
		source_name = "motion_step_A38A_A390.bin"
		span_start = MOTION_STEP_CPU_START
		span_end = MOTION_STEP_CPU_END
	elif cpu_address >= FRESH_MOTION_ROOTS_CPU_START and cpu_address < FRESH_MOTION_ROOTS_CPU_END:
		source_name = "fresh_actor_motion_roots_A723_A734.bin"
		span_start = FRESH_MOTION_ROOTS_CPU_START
		span_end = FRESH_MOTION_ROOTS_CPU_END
	if source_name.is_empty() or cpu_address >= span_end:
		return -1
	var source_bytes: PackedByteArray = _resources[source_name]
	var source_offset := cpu_address - span_start
	if source_offset < 0 or source_offset >= source_bytes.size():
		return -1
	return int(source_bytes[source_offset])


func _source_word_at(cpu_address: int) -> int:
	var low := _source_byte_at(cpu_address)
	var high := _source_byte_at(cpu_address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _matches_motion_step(bytes: PackedByteArray) -> bool:
	var expected := [0x01, 0x01, 0, 0, 0, 0, 0]
	if bytes.size() != expected.size():
		return false
	for index in expected.size():
		if int(bytes[index]) != int(expected[index]):
			return false
	return true


func _matches_fresh_motion_roots(bytes: PackedByteArray) -> bool:
	var expected := [
		0x01, 0xEF, 0x26, 0x00, 0x00, 0x00, 0x04, 0x23, 0xA7,
		0x01, 0xA0, 0x40, 0x00, 0x00, 0x00, 0x04, 0x2C, 0xA7,
	]
	if bytes.size() != expected.size():
		return false
	for index in expected.size():
		if int(bytes[index]) != int(expected[index]):
			return false
	return true


func _fresh_motion_root_for_cursor(cursor: int) -> int:
	if cursor == 0xA723 or cursor == 0xA729:
		return 0xA723
	if cursor == 0xA72C or cursor == 0xA732:
		return 0xA72C
	return -1


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _write_u16(bytes: PackedByteArray, offset: int, value: int) -> void:
	bytes[offset] = value & 0xFF
	bytes[offset + 1] = (value >> 8) & 0xFF


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false
