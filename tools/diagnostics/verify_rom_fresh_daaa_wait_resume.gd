extends SceneTree

const CONTINUATION := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const RAM_SIZE := 0x800


func _init() -> void:
	var continuation = CONTINUATION.new()
	if not continuation.configure_from_project_sources():
		_fail("Fresh continuation sources failed: " + continuation.error_message)
		return
	if not _check_wait_path(continuation, 0x00, false):
		return
	if not _check_wait_path(continuation, 0x80, true):
		return
	if not _check_wait_path(continuation, 0x40, true):
		return
	print("PASS: `$001C & $C0 == 0` still yields at `$DADF`; A and B input execute the ROM `$0441 = $05FB + 8` write and stop at the byte-verified `$DAF2 JSR $DC07` request.")
	quit(0)


func _check_wait_path(continuation: RefCounted, controller_bits: int,
		expect_call_request: bool) -> bool:
	var ram := PackedByteArray()
	ram.resize(RAM_SIZE)
	ram.fill(0)
	ram[0x001C] = controller_bits
	ram[0x05FB] = 0
	var dispatch := {
		"ok": true,
		"slot_base": 0x05,
		"pc": 0xDAE2,
		"sp": 0x50,
		"resume_path": "yielded_rts",
		"bank_low": 0x1C,
		"bank_high": 0x1D,
	}
	var boundary := {
		"active_task_slot": 0x05,
		"pc": 0xDAE2,
		"p": 0x20,
		"mapper": {"select": 0x07},
		"ram_image": ram,
		"stack_page": ram.slice(0x0100, 0x0200),
	}
	var result: Dictionary = continuation.execute_scenario35_wait_resume(dispatch, boundary)
	if not bool(result.get("ok", false)):
		return _fail("Wait path `$%02X` failed: %s" % [controller_bits, continuation.error_message])
	if expect_call_request:
		if int(result.get("exit_pc", -1)) != 0xDAF2 \
				or String(result.get("status", "")) != "scenario35_input_exit_dc07_callsite_ready" \
				or int(result.get("ball_holder_slot_0441", -1)) != 8 \
				or int(result.get("wait_flags", -1)) != controller_bits \
				or not bool(result.get("input_exit_taken", false)):
			return _fail("Set-input path `$%02X` did not reach the expected ROM call boundary." % controller_bits)
		var request: Dictionary = result.get("position_initializer_call_request", {})
		if String(request.get("kind", "")) != "rom_jsr_request" \
				or int(request.get("source_pc", -1)) != 0xDAF2 \
				or int(request.get("target_pc", -1)) != 0xDC07 \
				or int(request.get("return_pc", -1)) != 0xDAF5 \
				or int(request.get("return_minus_one", -1)) != 0xDAF4 \
				or request.get("source_bytes", PackedByteArray()) != PackedByteArray([0x20, 0x07, 0xDC]):
			return _fail("Set-input path `$%02X` did not expose the byte-verified `$DAF2 JSR $DC07` contract." % controller_bits)
		var writes: Array = result.get("writes", [])
		if writes.size() != 1 or not writes[0] is Dictionary \
				or int(writes[0].get("pc", -1)) != 0xDAEF \
				or int(writes[0].get("address", -1)) != 0x0441 \
				or int(writes[0].get("value", -1)) != 8:
			return _fail("Set-input path `$%02X` did not report the ROM `$DAEF STA $0441` write." % controller_bits)
		return true
	if int(result.get("exit_pc", -1)) != 0xDADF \
			or String(result.get("status", "")) != "scenario35_wait_yield_callsite_ready" \
			or int(result.get("wait_flags", -1)) != 0 \
			or bool(result.get("input_exit_taken", true)) \
			or not result.get("position_initializer_call_request", {}).is_empty() \
			or not result.get("writes", []).is_empty():
		return _fail("Zero-input wait no longer preserves the `$DADF` yield behavior.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
