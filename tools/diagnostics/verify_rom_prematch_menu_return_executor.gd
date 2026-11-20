extends SceneTree

const RETURN_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_prematch_menu_return_executor.gd")
const CUTSCENE_VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const SOURCE_RAM_SCRIPT := preload("res://scripts/gameplay/rom_source_ram_image.gd")
const A009_ENTRY_SCRIPT := preload("res://scripts/gameplay/rom_fresh_prematch_a009_entry.gd")
const MAPPER_SHADOW_SCRIPT := preload("res://scripts/gameplay/rom_mapper_shadow_source_state.gd")
const CALLER_CONTINUATION_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_caller_continuation.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-backed scene `$56` natural completion resolves through the saved `$8145` return into table-selected ID `$02` and its `$815A->$82B5` wait contract.")
	print("LIMIT: This isolated verifier does not execute `$82A9` counter reads, the `$A715->$9BA0` body, 6502 stack, or CPU/frame timing; the production route has a separate integration check and still labels those limits.")
	quit(0)


func _verify() -> bool:
	var executor: Variant = RETURN_EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		return _fail("Return executor source configuration failed: " + executor.error_message)

	var vm: KickoffCutsceneCommandVm = CUTSCENE_VM_SCRIPT.new() as KickoffCutsceneCommandVm
	root.add_child(vm)
	if not vm.start_cutscene(0x56) or not _advance_vm_to_natural_exit(vm):
		return _fail("Scene `$56` VM could not reach its ROM terminator: %s" % vm.error_message)

	var source_ram: RomSourceRamImage = SOURCE_RAM_SCRIPT.new() as RomSourceRamImage
	var reset_builder: Variant = MAPPER_SHADOW_SCRIPT.new()
	var reset_receipt: Dictionary = reset_builder.derive_fresh_kickoff_id1()
	if not bool(reset_receipt.get("ok", false)):
		return _fail("ROM reset source did not derive the fresh match index: %s" % reset_builder.error_message)
	var match_write := {
		"address": 0x0026,
		"value": int(reset_receipt.get("match_index_0026", -1)),
		"source_pc": 0xC670,
	}
	var reset_ram_receipt := {
		"ok": true,
		"source_rom_sha256": ROM_SHA256,
		"ram_writes": [match_write],
		"trace_state_used": false,
		"emulator_data_used": false,
	}
	if not source_ram.merge_executor_result("verified_reset_match_index", reset_ram_receipt):
		return _fail("ROM-derived reset match byte could not enter the source RAM ledger: " + source_ram.error_message)

	var caller: Variant = CALLER_CONTINUATION_SCRIPT.new()
	if not caller.configure_from_project_sources():
		return _fail("Fresh caller sources failed verification: " + caller.error_message)
	var e0_receipt: Dictionary = caller.execute_cutscene_wait_post_cleanup(0x82E2, 0x80F1, {
		"return_pc": 0x82E2, "a": 0, "x": 0, "y": 0,
		"p_known_mask": 0x86, "p_known_value": 0x02, "sp_delta": 0,
	})
	if not bool(e0_receipt.get("ok", false)):
		return _fail("Source-owned post-ID1 caller could not produce `$E0`: %s" % String(e0_receipt.get("error", "unknown error")))
	if not source_ram.merge_executor_result("verified_id1_caller_return", e0_receipt):
		return _fail("ROM-derived `$E0` write could not enter the source RAM ledger: " + source_ram.error_message)

	var a009_receipt := _build_a009_transfer_receipt()
	if a009_receipt.is_empty():
		return _fail("Source-byte-checked `$8142->$A009->$A64C` transfer failed.")
	var resolved: Dictionary = executor.resolve_after_scene56(3, vm, a009_receipt, source_ram)
	if not bool(resolved.get("ok", false)):
		return _fail("The verified scene-56 return was rejected: " + String(resolved.get("error", "unknown error")))
	if String(resolved.get("status", "")) != "id2_dispatch_wait_contract_ready" \
			or int(resolved.get("confirmed_option_offset", -1)) != 0x06 \
			or int(resolved.get("a64c_caller_return", {}).get("logical_return_pc", -1)) != 0x8145 \
			or int(resolved.get("scene56_return", {}).get("dispatcher_operand_low_byte_pc", -1)) != 0xA6CA \
			or int(resolved.get("scene56_return", {}).get("natural_wait_operand_low_byte_pc", -1)) != 0xA6CD \
			or int(resolved.get("scene56_return", {}).get("natural_wait_call_pc", -1)) != 0xA6CC \
			or int(resolved.get("scene56_return", {}).get("cleanup_tail_jump_pc", -1)) != 0xA6CF \
			or int(resolved.get("id2_dispatch_receipt", {}).get("cutscene_id", -1)) != 0x02 \
			or int(resolved.get("id2_dispatch_receipt", {}).get("caller_pc", -1)) != 0x8157 \
			or int(resolved.get("id2_dispatch_receipt", {}).get("target_pc", -1)) != 0x8464 \
			or int(resolved.get("wait_contract", {}).get("caller_pc", -1)) != 0x815A \
			or int(resolved.get("wait_contract", {}).get("target_pc", -1)) != 0x82B5 \
			or int(resolved.get("wait_contract", {}).get("return_pc", -1)) != 0x815D:
		return _fail("Source return or ID-$02 dispatch/wait contract did not resolve to the expected ROM path.")
	if int(resolved.get("source_frame", -2)) != -1 \
			or int(resolved.get("cpu_cycle", -2)) != -1 \
			or bool(resolved.get("cpu_timing_verified", true)) \
			or bool(resolved.get("id2_dispatch_receipt", {}).get("dispatch_executed", true)) \
			or bool(resolved.get("uses_trace_ram", true)) \
			or bool(resolved.get("uses_emulator_data", true)):
		return _fail("The return receipt overclaims execution, timing, or trace independence.")

	var wrong_option: Dictionary = executor.resolve_after_scene56(2, vm, a009_receipt, source_ram)
	if bool(wrong_option.get("ok", false)):
		return _fail("The scene-56 return must reject a non-Start menu row.")
	var wrong_return := a009_receipt.duplicate(true)
	wrong_return["return_pc"] = 0x8146
	var wrong_frame: Dictionary = executor.resolve_after_scene56(3, vm, wrong_return, source_ram)
	if bool(wrong_frame.get("ok", false)):
		return _fail("The scene-56 return must reject a changed saved `$8142` return frame.")
	var missing_source_ram: RomSourceRamImage = SOURCE_RAM_SCRIPT.new() as RomSourceRamImage
	var missing_state: Dictionary = executor.resolve_after_scene56(3, vm, a009_receipt, missing_source_ram)
	if bool(missing_state.get("ok", false)):
		return _fail("The source continuation must reject unknown caller RAM instead of injecting endpoint state.")

	vm.queue_free()
	return true


func _advance_vm_to_natural_exit(vm: KickoffCutsceneCommandVm) -> bool:
	for _tick in 10000:
		if vm.state == KickoffCutsceneCommandVm.RunState.FINISHED:
			return true
		if vm.state == KickoffCutsceneCommandVm.RunState.FAILED \
				or vm.state == KickoffCutsceneCommandVm.RunState.STOPPED \
				or vm.state == KickoffCutsceneCommandVm.RunState.WAITING_SOURCE_TASK:
			return false
		var pressed_edges := 0x80 if vm.state == KickoffCutsceneCommandVm.RunState.WAITING_INPUT else 0
		vm.advance_scheduler_tick(pressed_edges)
	return vm.state == KickoffCutsceneCommandVm.RunState.FINISHED


func _build_a009_transfer_receipt() -> Dictionary:
	var executor: Variant = A009_ENTRY_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("A009 transfer source configuration failed: " + executor.error_message)
		return {}
	var event_id := "verifier_rom_call_8142_a009"
	var frame := {
		"kind": "rom_jsr",
		"caller_pc": 0x8142,
		"target_pc": 0xA009,
		"return_pc": 0x8145,
		"return_word": 0x8144,
		"source_event_id": event_id,
	}
	var source_call := {
		"caller_pc": 0x8142,
		"target_pc": 0xA009,
		"return_pc": 0x8145,
		"source_event_id": event_id,
		"logical_stack_frame": frame.duplicate(true),
	}
	var transfer: Dictionary = executor.execute_logical_source_call(source_call, {
		"pc": 0xA009, "a": 0, "x": 0, "y": 0,
		"p_known_mask": 0xFF, "p_known_value": 0,
	}, {"a000_prg_bank": 0x01})
	return transfer if bool(transfer.get("ok", false)) else {}


func _fail(message: String) -> bool:
	push_error(message)
	return false
