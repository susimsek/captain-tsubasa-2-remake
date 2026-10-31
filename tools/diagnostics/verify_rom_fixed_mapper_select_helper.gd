extends SceneTree

const HELPER_SCRIPT := preload("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd")
const SHADOW_STATE_SCRIPT := preload("res://scripts/gameplay/rom_mapper_shadow_source_state.gd")


func _initialize() -> void:
	var helper: Variant = HELPER_SCRIPT.new()
	if not helper.configure_from_project_sources():
		_fail("Could not load hash-checked `$C4B9-$C4C7` source: " + helper.error_message)
		return
	var callsites: Array[Dictionary] = [
		{"caller_pc": 0x80F7, "return_pc": 0x80FA, "bank": 0x02},
		{"caller_pc": 0x810C, "return_pc": 0x810F, "bank": 0x02},
		{"caller_pc": 0x8119, "return_pc": 0x811C, "bank": 0x01},
		{"caller_pc": 0x813F, "return_pc": 0x8142, "bank": 0x01},
		{"caller_pc": 0x8938, "return_pc": 0x893B, "bank": 0x06},
	]
	for call_variant in callsites:
		var test_case: Dictionary = call_variant
		var pre_call_sp := 0xFD
		var entry_sp := (pre_call_sp - 2) & 0xFF
		var stack := PackedByteArray()
		stack.resize(0x100)
		stack.fill(0)
		var return_word := int(test_case["return_pc"]) - 1
		stack[(entry_sp + 1) & 0xFF] = return_word & 0xFF
		stack[(entry_sp + 2) & 0xFF] = (return_word >> 8) & 0xFF
		var source_call := {
			"caller_pc": int(test_case["caller_pc"]),
			"target_pc": 0xC4B9,
			"return_pc": int(test_case["return_pc"]),
			"source_event_id": "verifier_decoded_JSR_%04X" % int(test_case["caller_pc"]),
			"pre_call_sp": pre_call_sp,
			"stack_page": stack,
		}
		var cpu_state := {
			"a": 0x4C,
			"x": int(test_case["bank"]),
			"y": 0x37,
			"p": 0x21, # Carry=1; the helper must preserve C.
			"sp": entry_sp,
			"pc": 0xC4B9,
		}
		var result: Dictionary = helper.execute_source_call(source_call, cpu_state, {0x0022: 0x80})
		if not bool(result.get("ok", false)):
			_fail("Source helper refused callsite $%04X: %s" % [int(test_case["caller_pc"]), String(result.get("error", "unknown error"))])
			return
		var returned: Dictionary = result.get("return_registers", {})
		var expected_bank := int(test_case["bank"])
		if int(returned.get("a", -1)) != 0x87 \
				or int(returned.get("x", -1)) != expected_bank \
				or int(returned.get("y", -1)) != 0x37 \
				or int(returned.get("sp", -1)) != pre_call_sp \
				or int(returned.get("pc", -1)) != int(test_case["return_pc"]) \
				or (int(returned.get("p", 0)) & 0xC3) != 0x81:
			_fail("Return registers/flags differ at callsite $%04X: %s" % [int(test_case["caller_pc"]), returned])
			return
		var writes: Array = result.get("mapper_bus_writes", [])
		if writes.size() != 2 \
				or int(writes[0].get("address", -1)) != 0x8000 \
				or int(writes[0].get("value", -1)) != 0x87 \
				or int(writes[1].get("address", -1)) != 0x8001 \
				or int(writes[1].get("value", -1)) != expected_bank \
				or int(result.get("cpu_cycles", -1)) != 25:
			_fail("MMC3 writes or instruction-cycle total differ at callsite $%04X." % int(test_case["caller_pc"]))
			return
		var receipt: Dictionary = result.get("source_return_receipt", {})
		if int(receipt.get("caller_pc", -1)) != int(test_case["caller_pc"]) \
				or int(receipt.get("target_pc", -1)) != 0xC4B9 \
				or int(receipt.get("return_pc", -1)) != int(test_case["return_pc"]) \
				or String(receipt.get("source_event_id", "")) != String(source_call["source_event_id"]):
			_fail("Return receipt lost its decoded caller identity.")
			return
		if bool(result.get("live_mapper_updated", true)) or bool(result.get("emulator_data_used", true)):
			_fail("Bounded helper must not mutate a live mapper or read emulator data.")

	var bad_call := {
		"caller_pc": 0x80F7, "target_pc": 0xC4B9, "return_pc": 0x80FA,
		"source_event_id": "verifier_bad_stack", "pre_call_sp": 0xFD,
		"stack_page": PackedByteArray(),
	}
	var rejected: Dictionary = helper.execute_source_call(bad_call,
		{"a": 0, "x": 2, "y": 0, "p": 0x20, "sp": 0xFB}, {0x0022: 0})
	if bool(rejected.get("ok", true)):
		_fail("Helper accepted a malformed stack page.")
		return
	var shadow_builder: Variant = SHADOW_STATE_SCRIPT.new()
	var shadow_state: Dictionary = shadow_builder.derive_fresh_kickoff_id1()
	if not bool(shadow_state.get("ok", false)) or int(shadow_state.get("value", -1)) != 0:
		_fail("Fresh KICK OFF `$0022` was not derived from reset/initializer ROM stores: %s" % String(shadow_state.get("error", "wrong value")))
		return
	var logical_event_id := "verifier_fresh_kickoff_id1_80F7_C4B9"
	var logical_call := {
		"caller_pc": 0x80F7, "target_pc": 0xC4B9, "return_pc": 0x80FA,
		"source_event_id": logical_event_id,
		"logical_stack_frame": {
			"kind": "rom_jsr", "caller_pc": 0x80F7, "target_pc": 0xC4B9,
			"return_pc": 0x80FA, "return_word": 0x80F9,
			"source_event_id": logical_event_id,
		},
	}
	var logical_result: Dictionary = helper.execute_logical_source_call(logical_call, {
		"pc": 0xC4B9, "a": 0xC0, "x": 0x02, "y": 0x00,
		"p_known_mask": 0x82, "p_known_value": 0x00,
	}, {0x0022: int(shadow_state["value"])})
	if not bool(logical_result.get("ok", false)):
		_fail("Logical source call did not execute `$80F7->$C4B9->$80FA`: %s" % String(logical_result.get("error", "unknown error")))
		return
	var logical_cpu: Dictionary = logical_result.get("return_registers", {})
	var logical_writes: Array = logical_result.get("mapper_bus_writes", [])
	if int(logical_result.get("cpu_cycles", -1)) != 25 \
			or int(logical_cpu.get("pc", -1)) != 0x80FA \
			or int(logical_cpu.get("a", -1)) != 0x07 \
			or int(logical_cpu.get("x", -1)) != 0x02 \
			or int(logical_cpu.get("y", -1)) != 0 \
			or int(logical_cpu.get("p_known_mask", -1)) != 0x82 \
			or int(logical_cpu.get("p_known_value", -1)) != 0 \
			or logical_writes.size() != 2 \
			or int(logical_writes[0].get("value", -1)) != 0x07 \
			or int(logical_writes[1].get("value", -1)) != 0x02:
		_fail("Logical source call returned a different CPU/mapper contract: %s" % logical_result)
		return
	print("PASS: ROM `$C4B9-$C4C7` executes for all five verified physical caller fixtures and the live fresh KICK OFF logical call; reset-derived `$0022`, return address, partial flags, MMC3 writes, and 25-cycle helper cost match the decoded bytes.")
	print("LIMIT: physical stack placement, later `$80FA->$A20F` selector execution, mapper application to live rendering, and hardware timing remain outside this component.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
