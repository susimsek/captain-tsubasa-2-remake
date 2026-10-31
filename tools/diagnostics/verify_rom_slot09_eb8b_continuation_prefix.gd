extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SLOT09_PREFIX := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: the slot-$09 prefix executes through `$0516=$00` and `$05D2=$00`, maps banks `$18/$19`, and returns a live `$86F8` worker context.")
	print("LIMIT: this prefix verifier does not cover the separate `$86F8` zero-branch executor, later workers, menu transition, NMI cadence, or same-input visual/audio parity.")	
	quit(0)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh-route source setup failed: " + builder.error_message)
	var route_context = builder.build_fresh_kickoff_context()
	if route_context == null:
		return _fail("Fresh-route context derivation failed: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route runner setup failed: " + runner.error_message)
	if not bool(runner.begin_from_context(route_context).get("ok", false)):
		return _fail("Source route did not reach its first slot-$09 yield: " + runner.error_message)
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)):
		return _fail("Source route did not reach the live yielded slot-$09 dispatch: " + runner.error_message)
	var dispatch: Dictionary = advance.get("next_task_dispatch", {})
	if int(dispatch.get("slot_base", -1)) != 0x09 \
			or int(dispatch.get("pc", -1)) != 0xEB8B \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("a", -1)) != 0x78 \
			or int(dispatch.get("x", -1)) != 0x78 \
			or int(dispatch.get("y", -1)) != 0x05 \
			or not dispatch.get("ram_image", PackedByteArray()) is PackedByteArray \
			or not dispatch.get("stack_page", PackedByteArray()) is PackedByteArray \
			or not dispatch.get("mapper", {}) is Dictionary:
		return _fail("Route runner did not provide the live slot-$09 CPU/mapper/RAM/stack dispatch context.")
	var source_ram: PackedByteArray = dispatch["ram_image"]
	if int(source_ram[0x0539]) != 0 or int(source_ram[0x0516]) != 0 or int(source_ram[0x05D2]) != 0:
		return _fail("Fresh route state does not take the three source-supported zero branches.")

	var executor = SLOT09_PREFIX.new()
	if not executor.configure_from_project_sources():
		return _fail("Slot-$09 source package setup failed: " + executor.error_message)
	var result: Dictionary = executor.execute_from_next_task_dispatch(dispatch)
	if not bool(result.get("ok", false)):
		return _fail("Bounded slot-$09 continuation failed: " + String(result.get("reason", executor.error_message)))
	if not _verify_result(result, dispatch):
		return false
	if not _verify_rejected_branches(executor, dispatch):
		return false
	return true


func _verify_result(result: Dictionary, dispatch: Dictionary) -> bool:
	var regs: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var expected_entry_value := int((dispatch["ram_image"] as PackedByteArray)[0x0021]) & 0x1E
	if String(result.get("status", "")) != "stopped_before_worker_body" \
			or int(result.get("entry_pc", -1)) != 0xEB8B \
			or int(result.get("exit_pc", -1)) != 0x86F8 \
			or int(result.get("exit_bank", -1)) != 0x18 \
			or int(regs.get("a", -1)) != 0 \
			or int(regs.get("x", -1)) != 0 \
			or int(regs.get("y", -1)) != 0x05 \
			or int(regs.get("sp", -1)) != 0x78 \
			or int(regs.get("p_known_mask", -1)) != 0x82 \
			or int(regs.get("p", -1)) != 0x02 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 7 \
			or bool(result.get("worker_body_executed", true)) \
			or bool(result.get("worker_body_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)):
		return _fail("Stopped PC, CPU registers, mapper pair, or no-worker boundary differs from the ROM prefix result.")
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	if int(output_ram[0x0021]) != expected_entry_value \
			or int(output_ram[0x0023]) != 7 \
			or int(output_ram[0x0024]) != 0x18 \
			or int(output_ram[0x0025]) != 0x19:
		return _fail("ROM prefix RAM writes differ from its live inputs and mapper setup.")
	var expected_pcs: Array[int] = [
		0xEB8B, 0xEB8D, 0xEB8F, 0xEB92, 0xEB99, 0xEB9B,
		0xEC08, 0xEC0B, 0xEC0D, 0xEC0F, 0xEB9E,
		0xED85, 0xED88, 0xED8A, 0xEBA1, 0xEBA2, 0xEBA4,
		0xEBA6, 0xEBA8, 0xEBAA, 0xEBAC,
		0xCE2D, 0xCE2F, 0xCE31, 0xCE33, 0xCE36, 0xCE38,
		0xCE3B, 0xCE3D, 0xCE3F, 0xCE41, 0xCE44, 0xCE46, 0xCE49,
		0xEBAF, 0xEBB0, 0x8003,
	]
	if result.get("instruction_pcs", []) != expected_pcs:
		return _fail("Executed source PC sequence differs from the checked instruction path.")
	var expected_writes: Array[Dictionary] = [
		{"pc": 0xEB99, "address": 0x0021, "value": expected_entry_value, "kind": "ram"},
		{"pc": 0xEBA6, "address": 0x0024, "value": 0x18, "kind": "ram"},
		{"pc": 0xEBAA, "address": 0x0025, "value": 0x19, "kind": "ram"},
		{"pc": 0xCE31, "address": 0x0023, "value": 6, "kind": "ram"},
		{"pc": 0xCE3F, "address": 0x0023, "value": 7, "kind": "ram"},
	]
	if result.get("writes", []) != expected_writes:
		return _fail("Ordered source RAM writes differ from the supported continuation prefix.")
	var expected_mapper_writes: Array[Dictionary] = [
		{"pc": 0xCE33, "address": 0x8000, "value": 6, "select": 6, "kind": "register_select"},
		{"pc": 0xCE38, "address": 0x8001, "value": 0x18, "select": 6, "kind": "register_data"},
		{"pc": 0xCE41, "address": 0x8000, "value": 7, "select": 7, "kind": "register_select"},
		{"pc": 0xCE46, "address": 0x8001, "value": 0x19, "select": 7, "kind": "register_data"},
	]
	if result.get("mapper_writes", []) != expected_mapper_writes:
		return _fail("MMC3 mapper write sequence differs from the ROM helper.")
	var expected_stack_writes: Array[Dictionary] = [
		{"pc": 0xEB9B, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEB9B, "address": 0x0179, "value": 0x9D, "kind": "JSR_low"},
		{"pc": 0xEB9E, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEB9E, "address": 0x0179, "value": 0xA0, "kind": "JSR_low"},
		{"pc": 0xEBA1, "address": 0x017A, "value": 0, "kind": "PHA"},
		{"pc": 0xEBAC, "address": 0x0179, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBAC, "address": 0x0178, "value": 0xAE, "kind": "JSR_low"},
		{"pc": 0xEBB0, "address": 0x017A, "value": 0xEB, "kind": "JSR_high"},
		{"pc": 0xEBB0, "address": 0x0179, "value": 0xB2, "kind": "JSR_low"},
	]
	if result.get("stack_writes", []) != expected_stack_writes:
		return _fail("JSR/PHA stack writes differ from the source continuation.")
	var stack_page: PackedByteArray = result.get("stack_page", PackedByteArray())
	if int(stack_page[0x79]) != 0xB2 \
			or int(stack_page[0x7A]) != 0xEB:
		return _fail("Bank-$18 pending worker call has the wrong stack return state at SP $78.")
	var pending: Dictionary = result.get("pending_worker_call", {})
	if int(pending.get("source_pc", -1)) != 0xEBB0 \
			or int(pending.get("return_word", -1)) != 0xEBB2 \
			or int(pending.get("return_pc", -1)) != 0xEBB3 \
			or int(pending.get("target_pc", -1)) != 0x86F8 \
			or int(pending.get("target_bank", -1)) != 0x18:
		return _fail("Pending bank-$18 call return target is not source-derived.")
	return true


func _verify_rejected_branches(executor: Variant, dispatch: Dictionary) -> bool:
	var branch_cases: Array[Dictionary] = [
		{"address": 0x0539, "value": 1, "pc": 0xEB92},
		{"address": 0x0516, "value": 1, "pc": 0xEC0D},
		{"address": 0x05D2, "value": 1, "pc": 0xED88},
	]
	for branch_case in branch_cases:
		var changed := dispatch.duplicate(true)
		var ram: PackedByteArray = (dispatch["ram_image"] as PackedByteArray).duplicate()
		ram[int(branch_case["address"])] = int(branch_case["value"])
		changed["ram_image"] = ram
		var rejected: Dictionary = executor.execute_from_next_task_dispatch(changed)
		if bool(rejected.get("ok", true)) \
				or String(rejected.get("status", "")) != "unsupported_branch" \
				or int(rejected.get("exit_pc", -1)) != int(branch_case["pc"]):
			return _fail("Nonzero branch input $%04X was not rejected at its unresolved source branch." % int(branch_case["address"]))
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
