extends SceneTree
## Verifies the live-boundary first-action input contract and CB99 byte executor.
## Synthetic source snapshots cover the bounded unit; they do not prove the route.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_first_action_dispatch_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const INPUT_SPAN_SHA256 := "ad109ac091d382e1dca97d8d9c596617187b6f37e0ea0a965cc090066822d101"
const DIRECTION_TABLE_SHA256 := "dce8e125cc41a56ea02407a10727c0fbced6827fea37a619f5c3cc98f1ee4968"
const HANDLER_SPAN_SHA256 := "9ccc071c8af66e997b4fe1fe3613af4e764d756c35c6c96118ceba7faf034032"
const INLINE_DISPATCH_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"

var _executor: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_executor = EXECUTOR_SCRIPT.new()
	if not _executor.configure_from_project_sources():
		_fail("ROM-byte source setup failed: %s" % _executor.error_message)
		return
	if not _verify_d5ea_poll_contract():
		return
	if not _verify_d5c3_refusal():
		return
	if not _verify_cb99_from_live_boundary():
		return
	print("PASS: live `$D5EA` receipt maps Left to the three ROM writes; A has only a non-targeting confirmation handoff result.")
	print("PASS: byte-stepping `$CB99` from a live `$D6C7` fixture resolves action 1 to `$D7E8` with stack, pointer, and flag semantics.")
	print("LIMIT: synthetic snapshots verify the bounded contracts; `$D5C3->$D6C7` helpers are not executed, so no full-route D7E8 boundary is claimed.")
	quit(0)


func _verify_d5ea_poll_contract() -> bool:
	var bad_boundary := _boundary(0xD5E5)
	var invalid: Dictionary = _executor.execute_from_live_action_menu_boundary(
		bad_boundary, _receipt(1, 0, 0x02, 0x02))
	if String(invalid.get("status", "")) != "invalid_live_boundary":
		return _fail("The D5EA executor accepted a non-poll PC.")

	var left_boundary := _boundary(0xD5EA)
	left_boundary["ram_image"][0x001C] = 0x02
	left_boundary["ram_image"][0x001E] = 0x02
	var left: Dictionary = _executor.execute_from_live_action_menu_boundary(
		left_boundary, _receipt(1, 0, 0x02, 0x02))
	if not bool(left.get("ok", false)) \
			or String(left.get("status", "")) != "pass_selection_applied" \
			or int(left.get("selected_action_id", -1)) != 1 \
			or int(left.get("resume_pc", -1)) != 0xD5E5 \
			or not _writes_match(left.get("source_writes", []), [
				[0xD60A, 0x043B, 0x01], [0xD612, 0x061E, 0x01],
				[0xD623, 0x061E, 0x81]]):
		return _fail("A live Left edge did not yield the exact source selection effects.")

	var a_boundary := _boundary(0xD5EA)
	a_boundary["ram_image"][0x043B] = 0x01
	a_boundary["ram_image"][0x061E] = 0x81
	a_boundary["ram_image"][0x001C] = 0x80
	a_boundary["ram_image"][0x001E] = 0x80
	var a_result: Dictionary = _executor.execute_from_live_action_menu_boundary(
		a_boundary, _receipt(2, 0, 0x80, 0x80))
	if not bool(a_result.get("ok", false)) \
			or String(a_result.get("status", "")) != "pass_confirmation_handoff_resolved" \
			or a_result.has("resume_pc") \
			or a_result.has("handler_entry_pc") \
			or String(a_result.get("handler_span_sha256", "")) != HANDLER_SPAN_SHA256 \
			or not a_result.get("source_writes", []).is_empty() \
			or bool(a_result.get("handler_dispatch_executed", true)):
		return _fail("A confirmation broke the scheduler handoff contract or claimed a resume/handler target.")
	return true


func _verify_d5c3_refusal() -> bool:
	var boundary := _boundary(0xD5C3)
	boundary["ram_image"][0x043B] = 0x01
	boundary["ram_image"][0x061E] = 0x81
	boundary["ram_image"][0x001C] = 0x80
	boundary["ram_image"][0x001E] = 0x80
	var result: Dictionary = _executor.resume_pending_first_action_menu_pass_dispatch(boundary)
	if bool(result.get("ok", true)) \
			or String(result.get("status", "")) != "pass_dispatch_source_gap" \
			or int(result.get("handler_entry_pc", 0)) != -1 \
			or not result.get("source_writes", []).is_empty() \
			or not result.get("source_stack_writes", []).is_empty() \
			or not result.get("missing_live_source_steps", []).has(0xD717):
		return _fail("D5C3 gap refusal fabricated a dispatch or omitted the undecoded source bridge.")
	return true


func _verify_cb99_from_live_boundary() -> bool:
	# First establish the one-use confirmation from a source-owned D5EA sample.
	var confirmation_boundary := _boundary(0xD5EA)
	confirmation_boundary["ram_image"][0x043B] = 0x01
	confirmation_boundary["ram_image"][0x061E] = 0x81
	confirmation_boundary["ram_image"][0x001C] = 0x80
	confirmation_boundary["ram_image"][0x001E] = 0x80
	var confirmation: Dictionary = _executor.execute_from_live_action_menu_boundary(
		confirmation_boundary, _receipt(3, 0, 0x80, 0x80))
	if not bool(confirmation.get("ok", false)):
		return _fail("Could not establish the one-use PASS confirmation: %s" % confirmation.get("error", ""))

	var dispatch_boundary := _boundary(0xD6C7)
	dispatch_boundary["sp"] = 0x4A
	dispatch_boundary["a"] = 0x01
	dispatch_boundary["x"] = 0x77
	dispatch_boundary["y"] = 0x02
	dispatch_boundary["p"] = 0x31
	dispatch_boundary["p_known_mask"] = 0xFF
	dispatch_boundary["ram_image"][0x043B] = 0x01
	dispatch_boundary["ram_image"][0x061E] = 0x81
	dispatch_boundary["ram_image"][0x001C] = 0x80
	dispatch_boundary["ram_image"][0x001E] = 0x80
	dispatch_boundary["stack_page"][0x4C] = 0xD6
	dispatch_boundary["stack_page"][0x4B] = 0x34
	dispatch_boundary["mapper"] = {"bank_registers": {6: 0x1C, 7: 0x1D}}
	var result: Dictionary = _executor.execute_pass_cb99_from_live_d6c7_boundary(dispatch_boundary)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_cb99_dispatched" \
			or int(result.get("source_boundary_pc", -1)) != 0xD6C7 \
			or int(result.get("handler_entry_pc", -1)) != 0xD7E8 \
			or int(result.get("entry_sp", -1)) != 0x4A \
			or int(result.get("final_sp", -1)) != 0x4A \
			or not _writes_match(result.get("source_writes", []), [
				[0xCB9C, 0x0036, 0xC9], [0xCB9F, 0x0037, 0xD6],
				[0xCBA8, 0x0037, 0xD7], [0xCBAB, 0x0036, 0xE8]]) \
			or not _stack_writes_match(result.get("source_stack_writes", [])):
		return _fail("The CB99 live-boundary execution did not match source pointer/stack effects.")
	var registers: Dictionary = result.get("registers", {})
	if int(registers.get("a", -1)) != 0xE8 or int(registers.get("x", -1)) != 0x77 \
			or int(registers.get("y", -1)) != 0x04 \
			or (int(registers.get("p", -1)) & 0x83) != 0x80 \
			or not bool(registers.get("x_known", false)) \
			or bool(result.get("handler_instructions_executed", true)) \
			or bool(result.get("trace_state_used", true)):
		return _fail("CB99 register provenance or pre-handler stop boundary is incorrect.")
	return true


func _boundary(pc: int) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0621] = 0
	ram[0x043B] = 0
	ram[0x061E] = 0
	var stack := PackedByteArray()
	stack.resize(0x100)
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": pc,
		"sp": 0x4C,
		"a": 0,
		"x": 0,
		"y": 0,
		"p": 0,
		"p_known_mask": 0,
		"bank_low": 0x1A,
		"bank_high": 0x1B,
		"ram_image": ram,
		"stack_page": stack,
		"mapper": {"bank_registers": {6: 0x1A, 7: 0x1B}},
	}


func _receipt(id: int, previous: int, current: int, edge: int) -> Dictionary:
	return {"sample_receipt_id": id, "previous": previous, "current": current,
		"newly_pressed": edge, "held_ram_001c": current, "edge_ram_001e": edge}


func _writes_match(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size():
		return false
	for index in expected.size():
		var event: Variant = value[index]
		if not event is Dictionary:
			return false
		if int(event.get("source_pc", -1)) != int(expected[index][0]) \
				or int(event.get("address", -1)) != int(expected[index][1]) \
				or int(event.get("value", -1)) != int(expected[index][2]):
			return false
	return true


func _stack_writes_match(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	var expected := [
		[0xD6C7, 0x014A, 0xD6, "jsr_push_high"],
		[0xD6C7, 0x0149, 0xC9, "jsr_push_low"],
		[0xCBA4, 0x0148, 0xE8, "pha"],
	]
	for index in expected.size():
		var event: Variant = value[index]
		if not event is Dictionary:
			return false
		for field_index in 3:
			var field: String = ["source_pc", "address", "value"][field_index]
			if int(event.get(field, -1)) != int(expected[index][field_index]):
				return false
		if String(event.get("operation", "")) != String(expected[index][3]):
			return false
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
