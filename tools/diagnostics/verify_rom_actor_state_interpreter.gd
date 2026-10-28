extends SceneTree
## Focused source-only checks for the bounded bank-$14 actor interpreter.
## This verifier uses no emulator capture, endpoint RAM, OAM, or screenshot data.

const INTERPRETER_SCRIPT := preload("res://scripts/gameplay/rom_actor_state_interpreter.gd")
const MOTION_CODE_PATH := "res://reference/rom_extract/gameplay/actor_state_interpreter/motion_interpreter_84DC_8623.bin"
const MOTION_CODE_SHA256 := "3f9bb278daab82f6b76b2d89cbd91d327dd0202b3bc6e594dd1734fa1882f380"
const MOTION_CODE_CPU_START := 0x84DC
const APPEARANCE_POINTER_OFFSET := 0x03
const MOTION_POINTER_OFFSET := 0x01
const APPEARANCE_TIMER_OFFSET := 0x10
const MOTION_TIMER_OFFSET := 0x11
const DESCRIPTOR_OFFSET := 0x12


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _verify_motion_handler_bytes():
		return
	var interpreter: Variant = INTERPRETER_SCRIPT.new()
	if not interpreter.configure():
		_fail("Interpreter source setup failed: " + interpreter.last_error)
		return

	var actor := _new_actor(0xB026, 0xA38A)
	actor[8] = 0xC3
	actor[12] = 0x40
	var first_tick: Variant = interpreter.tick_actor(actor)
	if not bool(first_tick.ok):
		_fail("First ROM actor tick failed: " + str(first_tick.error))
		return
	var updated: PackedByteArray = first_tick.actor_record
	if int(updated[APPEARANCE_TIMER_OFFSET]) != 4 \
			or int(updated[DESCRIPTOR_OFFSET]) != 0 \
			or _read_u16(updated, APPEARANCE_POINTER_OFFSET) != 0xB028:
		_fail("Appearance $B026 timed pair did not set wait=4, descriptor=$00, and cursor=$B028.")
		return
	if _read_u16(updated, MOTION_POINTER_OFFSET) != 0xA390 \
			or int(updated[MOTION_TIMER_OFFSET]) != 1 \
			or updated[5] != 0 or updated[7] != 0 or updated[9] != 0 or updated[11] != 0 \
			or int(updated[8]) != 0xC3 or int(updated[12]) != 0x40:
		_fail("Motion $A38A parse did not set timer=1, zero deltas, cursor=$A390, and preserve visible coordinates.")
		return
	if first_tick.appearance_events != ["pair:$B026 wait=4 descriptor=$00"] \
			or first_tick.motion_events != ["step:$A38A timer=1 deltas=(0,0) cursor=$A390"]:
		_fail("The first update did not report the expected ROM-script commands.")
		return

	for expected_timer in [3, 2, 1, 0]:
		var countdown: Variant = interpreter.tick_actor(updated)
		if not bool(countdown.ok):
			_fail("Source tick countdown failed: " + str(countdown.error))
			return
		updated = countdown.actor_record
		if int(updated[APPEARANCE_TIMER_OFFSET]) != expected_timer \
				or int(updated[DESCRIPTOR_OFFSET]) != 0:
			_fail("Appearance source countdown did not decrement once per actor tick.")
			return
		if expected_timer == 3:
			if int(updated[MOTION_TIMER_OFFSET]) != 0 \
					or countdown.motion_events != ["integrate:$A390 timer=1->0 delta=(0,0)"]:
				_fail("Motion timer 1 did not decrement and execute the zero-delta integration update.")
				return
		elif expected_timer == 2:
			if int(updated[MOTION_TIMER_OFFSET]) != 0xFF \
					or countdown.motion_events != ["end-hold:$A390"]:
				_fail("The source $00 command at $A390 did not hold after the timer update.")
				return
		elif int(updated[MOTION_TIMER_OFFSET]) != 0xFF:
			_fail("The source motion hold did not persist on later actor ticks.")
			return

	var next_pose: Variant = interpreter.tick_actor(updated)
	if not bool(next_pose.ok):
		_fail("Second appearance pair failed: " + str(next_pose.error))
		return
	updated = next_pose.actor_record
	if int(updated[APPEARANCE_TIMER_OFFSET]) != 4 \
			or int(updated[DESCRIPTOR_OFFSET]) != 1 \
			or _read_u16(updated, APPEARANCE_POINTER_OFFSET) != 0xB02A:
		_fail("The next source appearance pair did not advance to descriptor $01 at $B02A.")
		return

	var loop_actor := _new_actor(0xB02E, 0xA390)
	loop_actor[APPEARANCE_TIMER_OFFSET] = 0
	loop_actor[MOTION_TIMER_OFFSET] = 0xFF
	var loop_tick: Variant = interpreter.tick_actor(loop_actor)
	if not bool(loop_tick.ok):
		_fail("Source $F3 appearance loop failed: " + str(loop_tick.error))
		return
	if int(loop_tick.actor_record[DESCRIPTOR_OFFSET]) != 0 \
			or _read_u16(loop_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB028 \
			or loop_tick.appearance_events != ["jump:$B02E->$B026", "pair:$B026 wait=4 descriptor=$00"]:
		_fail("The ROM $F3 loop did not redirect and execute the source pair.")
		return

	var held_actor := _new_actor(0xB5AC, 0xA390)
	held_actor[MOTION_TIMER_OFFSET] = 0xFF
	var held_tick: Variant = interpreter.tick_actor(held_actor)
	if not bool(held_tick.ok):
		_fail("Source $F7 held appearance failed: " + str(held_tick.error))
		return
	if int(held_tick.actor_record[DESCRIPTOR_OFFSET]) != 0 \
			or int(held_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 0xFF \
			or _read_u16(held_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB5AC:
		_fail("The ROM $F7 command did not set and hold descriptor $00.")
		return

	print("PASS: hashed bank-$14 source spans drove $83D9 timed-pair/countdown/$F3/$F7 and the three-step $84DC $A38A parse, timer/integration, then $A390 hold sequence.")
	quit(0)


func _verify_motion_handler_bytes() -> bool:
	var source := FileAccess.get_file_as_bytes(MOTION_CODE_PATH)
	if source.size() != 0x0148 or _sha256(source) != MOTION_CODE_SHA256:
		_fail("The preserved $84DC-$8623 motion interpreter span failed its source hash/length check.")
		return false
	if not _expect_bytes(source, 0x84DC, PackedByteArray([
		0xA0, 0x11, 0xB1, 0x3C, 0xF0, 0x0D, 0xC9, 0xFF, 0xD0, 0x01,
		0x60, 0x38, 0xE9, 0x01, 0x91, 0x3C, 0x4C, 0x2A, 0x85,
	]), "$84DC timer decrement / $852A integrator dispatch"):
		return false
	if not _expect_bytes(source, 0x85A9, PackedByteArray([
		0x20, 0xE7, 0x85, 0xA4, 0x40, 0xB1, 0x3E, 0xAA, 0xC8, 0xB1,
		0x3E, 0xC8, 0x84, 0x40, 0xA0, 0x07, 0x91, 0x3C, 0x88, 0x88,
		0x8A, 0x91, 0x3C, 0xA4, 0x40, 0xB1, 0x3E, 0xAA, 0xC8, 0xB1,
		0x3E, 0xC8, 0x84, 0x40, 0xA0, 0x0B, 0x91, 0x3C, 0x88, 0x88,
		0x8A, 0x91, 0x3C, 0x60,
	]), "$85A9 $01 command: load X/Y motion lanes"):
		return false
	if not _expect_bytes(source, 0x85E7, PackedByteArray([
		0xA4, 0x40, 0xB1, 0x3E, 0xA0, 0x11, 0x91, 0x3C, 0xE6, 0x40, 0x60,
	]), "$85E7 $01 timer operand into actor +$11"):
		return false
	if not _expect_bytes(source, 0x85A0, PackedByteArray([
		0xA0, 0x11, 0xA9, 0xFF, 0x91, 0x3C, 0x68, 0x68, 0x60,
	]), "$85A0 $00 hold command"):
		return false
	return true


func _expect_bytes(source: PackedByteArray, cpu_address: int, expected: PackedByteArray, label: String) -> bool:
	var offset := cpu_address - MOTION_CODE_CPU_START
	var end_offset := offset + expected.size()
	if offset < 0 or end_offset > source.size() or source.slice(offset, end_offset) != expected:
		_fail("Motion source bytes do not match the ROM-derived handler at " + label + ".")
		return false
	return true


func _new_actor(appearance_pointer: int, motion_pointer: int) -> PackedByteArray:
	var record := PackedByteArray()
	record.resize(21)
	record.fill(0)
	record[0] = 0x80
	_write_u16(record, MOTION_POINTER_OFFSET, motion_pointer)
	_write_u16(record, APPEARANCE_POINTER_OFFSET, appearance_pointer)
	return record


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


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
