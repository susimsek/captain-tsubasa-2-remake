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
	var slot11_motion_actor := _new_actor(0xB2E0, 0xA865)
	slot11_motion_actor[0] = 0xA1
	slot11_motion_actor[APPEARANCE_TIMER_OFFSET] = 0xFF
	slot11_motion_actor[0x08] = 0x0C
	slot11_motion_actor[0x0C] = 0xBB
	var slot11_motion_start: Variant = interpreter.tick_motion_only(slot11_motion_actor)
	if not bool(slot11_motion_start.ok) \
			or int(slot11_motion_start.actor_record[MOTION_TIMER_OFFSET]) != 0x0A \
			or _read_u16(slot11_motion_start.actor_record, MOTION_POINTER_OFFSET) != 0xA86B \
			or slot11_motion_start.actor_record[0x05] != 0x30 \
			or slot11_motion_start.actor_record[0x06] != 0x30 \
			or slot11_motion_start.actor_record[0x08] != 0x0C \
			or slot11_motion_start.actor_record[0x0C] != 0xBB \
			or slot11_motion_start.motion_events != ["step:$A865 timer=10 velocity=(00:30,00:00) cursor=$A86B"]:
		_fail("Slot-$11 ROM motion `$A865` did not load and integrate its `$01` packet to the source frame-8781 state.")
		return
	var slot11_motion_record: PackedByteArray = slot11_motion_start.actor_record
	for expected_timer in [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]:
		var slot11_motion_tick: Variant = interpreter.tick_motion_only(slot11_motion_record)
		if not bool(slot11_motion_tick.ok) \
				or int(slot11_motion_tick.actor_record[MOTION_TIMER_OFFSET]) != expected_timer:
			_fail("Slot-$11 ROM motion `$A86B` countdown failed at expected timer $%02X." % expected_timer)
			return
		slot11_motion_record = slot11_motion_tick.actor_record
	if slot11_motion_record[0x06] != 0x10 or slot11_motion_record[0x08] != 0x0E:
		_fail("Slot-$11 ROM motion `$A865` ten-update integration does not match the captured frame-8791 fixed-point state.")
		return
	var slot11_motion_hold: Variant = interpreter.tick_motion_only(slot11_motion_record)
	if not bool(slot11_motion_hold.ok) \
			or int(slot11_motion_hold.actor_record[MOTION_TIMER_OFFSET]) != 0xFF \
			or slot11_motion_hold.motion_events != ["end-hold:$A86B"]:
		_fail("Slot-$11 ROM motion `$00` hold at `$A86B` did not set the source hold timer.")
		return
	var pass_motion_actor := _new_actor(0xAF23, 0xA95C)
	pass_motion_actor[0] = 0x81
	pass_motion_actor[0x08] = 0x0E
	pass_motion_actor[0x0C] = 0xAF
	var pass_motion_start: Variant = interpreter.tick_motion_only(pass_motion_actor)
	if not bool(pass_motion_start.ok) \
			or int(pass_motion_start.actor_record[MOTION_TIMER_OFFSET]) != 0x32 \
			or _read_u16(pass_motion_start.actor_record, MOTION_POINTER_OFFSET) != 0xA962 \
			or pass_motion_start.actor_record[0] != 0x91 \
			or pass_motion_start.actor_record[5] != 0xD0 \
			or pass_motion_start.actor_record[7] != 0xFF \
			or pass_motion_start.actor_record[9] != 0x95 \
			or pass_motion_start.actor_record[11] != 0xFF \
			or pass_motion_start.actor_record[6] != 0xD0 \
			or pass_motion_start.actor_record[8] != 0x0D \
			or pass_motion_start.actor_record[10] != 0x95 \
			or pass_motion_start.actor_record[12] != 0xAE \
			or pass_motion_start.motion_events != ["step:$A95C opcode=$03 timer=50 velocity=(FF:D0,FF:95) cursor=$A962 flag=$10"]:
		_fail("PASS actor motion index `$A7` did not load and integrate its ROM `$03` packet: ok=%s error=%s events=%s record=%s." % [
			str(pass_motion_start.ok), str(pass_motion_start.error), str(pass_motion_start.motion_events),
			pass_motion_start.actor_record.hex_encode(),
		])
		return
	var pass_motion_record: PackedByteArray = pass_motion_start.actor_record
	for expected_timer in range(0x31, -1, -1):
		var pass_motion_tick: Variant = interpreter.tick_motion_only(pass_motion_record)
		if not bool(pass_motion_tick.ok) \
				or int(pass_motion_tick.actor_record[MOTION_TIMER_OFFSET]) != expected_timer:
			_fail("PASS actor motion `$A962` countdown failed at expected timer $%02X." % expected_timer)
			return
		pass_motion_record = pass_motion_tick.actor_record
	var pass_motion_hold: Variant = interpreter.tick_motion_only(pass_motion_record)
	if not bool(pass_motion_hold.ok) \
			or int(pass_motion_hold.actor_record[MOTION_TIMER_OFFSET]) != 0xFF \
			or _read_u16(pass_motion_hold.actor_record, MOTION_POINTER_OFFSET) != 0xA962 \
			or (pass_motion_hold.actor_record[0] & 0x10) != 0 \
			or pass_motion_hold.motion_events != ["end-hold:$A966 skipped=4"]:
		_fail("PASS actor motion did not honor the ROM `$04` skip to `$A966` and source `$00` hold.")
		return
	var scenario_1c_motion_66_actor := _new_actor(0xAF11, 0xA6E3)
	scenario_1c_motion_66_actor[0] = 0x80
	scenario_1c_motion_66_actor[0x08] = 0x0E
	var scenario_1c_motion_66_start: Variant = interpreter.tick_motion_only(scenario_1c_motion_66_actor)
	if not bool(scenario_1c_motion_66_start.ok) \
			or int(scenario_1c_motion_66_start.actor_record[MOTION_TIMER_OFFSET]) != 0x28 \
			or _read_u16(scenario_1c_motion_66_start.actor_record, MOTION_POINTER_OFFSET) != 0xA6E9 \
			or scenario_1c_motion_66_start.actor_record[5] != 0xE0 \
			or scenario_1c_motion_66_start.actor_record[7] != 0xFF \
			or scenario_1c_motion_66_start.actor_record[9] != 0x20 \
			or scenario_1c_motion_66_start.actor_record[11] != 0 \
			or scenario_1c_motion_66_start.motion_events != ["step:$A6E3 timer=$28 velocity=(FF:E0,00:20) cursor=$A6E9"]:
		_fail("Scenario-$1C animation-$7A motion index `$66` did not apply its ROM `$A6E3` packet: ok=%s error=%s events=%s record=%s." % [
			str(scenario_1c_motion_66_start.ok), str(scenario_1c_motion_66_start.error),
			str(scenario_1c_motion_66_start.motion_events), scenario_1c_motion_66_start.actor_record.hex_encode(),
		])
		return
	var scenario_1c_motion_66_record: PackedByteArray = scenario_1c_motion_66_start.actor_record
	for expected_timer in range(0x27, -1, -1):
		var scenario_1c_motion_66_tick: Variant = interpreter.tick_motion_only(scenario_1c_motion_66_record)
		if not bool(scenario_1c_motion_66_tick.ok) \
				or int(scenario_1c_motion_66_tick.actor_record[MOTION_TIMER_OFFSET]) != expected_timer:
			_fail("Scenario-$1C motion index `$66` countdown failed at expected timer $%02X." % expected_timer)
			return
		scenario_1c_motion_66_record = scenario_1c_motion_66_tick.actor_record
	var scenario_1c_motion_66_hold: Variant = interpreter.tick_motion_only(scenario_1c_motion_66_record)
	if not bool(scenario_1c_motion_66_hold.ok) \
			or int(scenario_1c_motion_66_hold.actor_record[MOTION_TIMER_OFFSET]) != 0xFF \
			or scenario_1c_motion_66_hold.motion_events != ["end-hold:$A6E9"]:
		_fail("Scenario-$1C motion index `$66` did not execute its source `$00` hold.")
		return
	var animation_66_actor := _new_actor(0xAF81, 0xA390)
	animation_66_actor[MOTION_TIMER_OFFSET] = 0xFF
	var animation_66_tick: Variant = interpreter.tick_appearance_only(animation_66_actor)
	if not bool(animation_66_tick.ok):
		_fail("Animation-$66 appearance root failed: " + str(animation_66_tick.error))
		return
	var animation_66_updated: PackedByteArray = animation_66_tick.actor_record
	if animation_66_updated[0] != 0xA0 \
			or int(animation_66_updated[APPEARANCE_TIMER_OFFSET]) != 6 \
			or int(animation_66_updated[DESCRIPTOR_OFFSET]) != 0x9E \
			or _read_u16(animation_66_updated, APPEARANCE_POINTER_OFFSET) != 0xAF84 \
			or animation_66_tick.appearance_events != ["flip-x:$AF81", "pair:$AF82 wait=6 descriptor=$9E"]:
		_fail("Animation-$66 appearance root did not set source horizontal flip and descriptor $9E with six ticks.")
		return
	var animation_66_motion_actor := _new_actor(0xAF84, 0xA692)
	animation_66_motion_actor[APPEARANCE_TIMER_OFFSET] = 0xFF
	var animation_66_motion_tick: Variant = interpreter.tick_motion_only(animation_66_motion_actor)
	if not bool(animation_66_motion_tick.ok):
		_fail("Animation-$66 motion root failed: " + str(animation_66_motion_tick.error))
		return
	var animation_66_motion_updated: PackedByteArray = animation_66_motion_tick.actor_record
	if int(animation_66_motion_updated[MOTION_TIMER_OFFSET]) != 0x3C \
			or _read_u16(animation_66_motion_updated, MOTION_POINTER_OFFSET) != 0xA698 \
			or animation_66_motion_updated[5] != 0xDA or animation_66_motion_updated[7] != 0xFF \
			or animation_66_motion_updated[9] != 0xED or animation_66_motion_updated[11] != 0xFF \
			or animation_66_motion_updated[0] != 0x83 \
			or animation_66_motion_updated[8] != 0xFF or animation_66_motion_updated[12] != 0xFF:
		_fail("Animation-$66 motion root did not load its ROM fixed-point step and integrate one source tick.")
		return
	var route_actor := _new_actor(0xB537, 0xA96E)
	route_actor[APPEARANCE_TIMER_OFFSET] = 0
	route_actor[MOTION_TIMER_OFFSET] = 0xFF
	var route_tick: Variant = interpreter.tick_appearance_only(route_actor)
	if not bool(route_tick.ok):
		_fail("Frame-8663 route appearance pair failed: " + str(route_tick.error))
		return
	if int(route_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 4 \
			or int(route_tick.actor_record[DESCRIPTOR_OFFSET]) != 0x7D \
			or _read_u16(route_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB539 \
			or route_tick.appearance_events != ["pair:$B537 wait=4 descriptor=$7D"]:
		_fail("Frame-8663 ROM appearance bytes did not produce descriptor $7D and cursor $B539.")
		return
	var scenario_36_continuation := _new_actor(0xB440, 0xA79B)
	var scenario_36_continuation_tick: Variant = interpreter.tick_appearance_only(scenario_36_continuation)
	if not bool(scenario_36_continuation_tick.ok) \
			or int(scenario_36_continuation_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 3 \
			or int(scenario_36_continuation_tick.actor_record[DESCRIPTOR_OFFSET]) != 0x7C \
			or _read_u16(scenario_36_continuation_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB442 \
			or scenario_36_continuation_tick.appearance_events != ["pair:$B440 wait=3 descriptor=$7C"]:
		_fail("Scenario-$36 animation-$4C continuation did not decode its ROM pair at `$B440`.")
		return
	var scenario_36_actor_record: PackedByteArray = scenario_36_continuation_tick.actor_record
	for expected_descriptor in [0x7B, 0x7A, 0x79, 0x78, 0x77, 0x76, 0x75, 0x74, 0x73, 0x72, 0x71, 0x71]:
		for _timer_tick in 3:
			var countdown: Variant = interpreter.tick_appearance_only(scenario_36_actor_record)
			if not bool(countdown.ok):
				_fail("Scenario-$36 animation-$4C pair countdown failed: " + str(countdown.error))
				return
			scenario_36_actor_record = countdown.actor_record
		var pair_tick: Variant = interpreter.tick_appearance_only(scenario_36_actor_record)
		if not bool(pair_tick.ok) or int(pair_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 3 \
				or int(pair_tick.actor_record[DESCRIPTOR_OFFSET]) != expected_descriptor:
			_fail("Scenario-$36 animation-$4C ROM continuation produced the wrong timed descriptor.")
			return
		scenario_36_actor_record = pair_tick.actor_record
	for _timer_tick in 3:
		var loop_countdown: Variant = interpreter.tick_appearance_only(scenario_36_actor_record)
		if not bool(loop_countdown.ok):
			_fail("Scenario-$36 animation-$4C loop countdown failed: " + str(loop_countdown.error))
			return
		scenario_36_actor_record = loop_countdown.actor_record
	var scenario_36_loop_tick: Variant = interpreter.tick_appearance_only(scenario_36_actor_record)
	if not bool(scenario_36_loop_tick.ok) \
			or int(scenario_36_loop_tick.actor_record[DESCRIPTOR_OFFSET]) != 0x71 \
			or _read_u16(scenario_36_loop_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB467 \
			or scenario_36_loop_tick.appearance_events != ["jump:$B46E->$B462", "local-offset:$B462 x=$00 y=$01",
				"pair:$B465 wait=3 descriptor=$71"]:
		_fail("Scenario-$36 animation-$4C ROM `$F3` loop at `$B46E` did not return to `$B462`.")
		return
	var route_motion_actor := route_actor.duplicate()
	route_motion_actor[MOTION_TIMER_OFFSET] = 0
	var route_actor_update: Variant = interpreter.tick_actor(route_motion_actor)
	if not bool(route_actor_update.ok):
		_fail("Frame-8663 route actor update failed: " + str(route_actor_update.error))
		return
	var route_actor_record: PackedByteArray = route_actor_update.actor_record
	if int(route_actor_record[APPEARANCE_TIMER_OFFSET]) != 4 \
			or int(route_actor_record[MOTION_TIMER_OFFSET]) != 0x3C \
			or _read_u16(route_actor_record, APPEARANCE_POINTER_OFFSET) != 0xB539 \
			or _read_u16(route_actor_record, MOTION_POINTER_OFFSET) != 0xA974 \
			or route_actor_record[0] != 0x90 \
			or route_actor_record[5] != 0x84 or route_actor_record[7] != 0x00 \
			or route_actor_record[9] != 0x34 or route_actor_record[11] != 0xFF \
			or route_actor_update.motion_events != ["step:$A96E opcode=$03 timer=60 velocity=(00:84,FF:34) cursor=$A974 flag=$10"]:
		_fail("Frame-8663 ROM motion command $03 did not load its timer, fixed-point lanes, cursor, and flag.")
		return
	var route_motion_countdown: Variant = interpreter.tick_motion_only(route_actor_record)
	if not bool(route_motion_countdown.ok):
		_fail("Frame-8663 route motion countdown failed: " + str(route_motion_countdown.error))
		return
	var route_countdown_record: PackedByteArray = route_motion_countdown.actor_record
	if int(route_countdown_record[MOTION_TIMER_OFFSET]) != 0x3B \
			or _read_u16(route_countdown_record, MOTION_POINTER_OFFSET) != 0xA974 \
			or route_motion_countdown.motion_events != ["integrate:$A96E timer=$3C->$3B"]:
		_fail("Frame-8663 route motion command did not perform its first source countdown/integration update.")
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
	var pass_receiver_actor := _new_actor(0xB048, 0xA38A)
	pass_receiver_actor[0] = 0xA1
	var pass_receiver_tick: Variant = interpreter.tick_appearance_only(pass_receiver_actor)
	if not bool(pass_receiver_tick.ok) \
			or int(pass_receiver_tick.actor_record[0]) != 0x81 \
			or int(pass_receiver_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 4 \
			or int(pass_receiver_tick.actor_record[DESCRIPTOR_OFFSET]) != 0x05 \
			or _read_u16(pass_receiver_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB04A:
		_fail("Appearance `$83E9-$83EF` did not clear `$A1->$81` before consuming the ROM `$B048` pair.")
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
	var local_offset_actor := _new_actor(0xB545, 0xA390)
	local_offset_actor[MOTION_TIMER_OFFSET] = 0xFF
	var local_offset_tick: Variant = interpreter.tick_appearance_only(local_offset_actor)
	if not bool(local_offset_tick.ok):
		_fail("Route appearance $F6 local-offset command failed: " + str(local_offset_tick.error))
		return
	if local_offset_tick.actor_record[0x13] != 0xFE \
			or local_offset_tick.actor_record[0x14] != 0x01 \
			or int(local_offset_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 4 \
			or int(local_offset_tick.actor_record[DESCRIPTOR_OFFSET]) != 0x76 \
			or _read_u16(local_offset_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB54A \
			or local_offset_tick.appearance_events != ["local-offset:$B545 x=$FE y=$01", "pair:$B548 wait=4 descriptor=$76"]:
		_fail("The ROM $F6 handler did not apply its signed local offsets before the following timed pair.")
		return
	var shared_selector_actor := _new_actor(0xB56A, 0xA390)
	shared_selector_actor[MOTION_TIMER_OFFSET] = 0xFF
	var shared_selector_tick: Variant = interpreter.tick_appearance_only(shared_selector_actor)
	if not bool(shared_selector_tick.ok):
		_fail("Route appearance $F8 shared-selector command failed: " + str(shared_selector_tick.error))
		return
	if shared_selector_tick.shared_ram_writes != [{"address": 0x0546, "value": 0x01, "source_pc": 0x84D8}] \
			or shared_selector_tick.actor_record[0] != 0xA0 \
			or int(shared_selector_tick.actor_record[APPEARANCE_TIMER_OFFSET]) != 1 \
			or int(shared_selector_tick.actor_record[DESCRIPTOR_OFFSET]) != 0xD2 \
			or _read_u16(shared_selector_tick.actor_record, APPEARANCE_POINTER_OFFSET) != 0xB56F:
		_fail("The ROM $F8 handler output differs: writes=%s actor=%s events=%s." % [str(shared_selector_tick.shared_ram_writes), shared_selector_tick.actor_record.hex_encode(), str(shared_selector_tick.appearance_events)])
		return

	print("PASS: hashed bank-$14 source spans drove animation-$66/frame-8663 actors, PASS `$A95C` motion/countdown/hold, appearance commands, and fixed-point updates.")
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
	if not _expect_bytes(source, 0x8589, PackedByteArray([0xE1, 0x85]), "$03 dispatch table entry"):
		return false
	if not _expect_bytes(source, 0x85E1, PackedByteArray([
		0x20, 0xA9, 0x85, 0x4C, 0xD8, 0x85,
	]), "$03 command handler: load motion packet and set movement flag"):
		return false
	if not _expect_bytes(source, 0x85D8, PackedByteArray([
		0xA0, 0x00, 0xB1, 0x3C, 0x09, 0x10, 0x91, 0x3C, 0x60,
	]), "$03 movement flag $10 handler"):
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
