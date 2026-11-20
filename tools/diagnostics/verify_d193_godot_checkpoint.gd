extends SceneTree
## Validates a Godot-produced `$E14A` route checkpoint and, when available,
## runs the focused ROM-source D193 worker transition from that checkpoint.
## This diagnostic never reads emulator state or supplies state to game runtime.

const DEFAULT_CHECKPOINT_PATH := "/tmp/ct2_d193_e14a_checkpoint.json"
const INPUT_TRACE_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const INPUT_TRACE_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_SCRIPT_PATH := "res://scripts/gameplay/rom_clock_tick_d193_worker.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var checkpoint_path := OS.get_environment("CT2_ROUTE_CHECKPOINT_IN").strip_edges()
	if checkpoint_path.is_empty():
		checkpoint_path = DEFAULT_CHECKPOINT_PATH
	var checkpoint_file := FileAccess.open(checkpoint_path, FileAccess.READ)
	if checkpoint_file == null:
		_fail("Could not open checkpoint: %s" % checkpoint_path)
		return
	var parsed: Variant = JSON.parse_string(checkpoint_file.get_as_text())
	checkpoint_file.close()
	if not parsed is Dictionary:
		_fail("Checkpoint is not a JSON object.")
		return
	var checkpoint: Dictionary = parsed
	var validated := _validate_checkpoint(checkpoint)
	if not bool(validated.get("ok", false)):
		_fail(String(validated.get("error", "Checkpoint validation failed.")))
		return

	var registers: Dictionary = checkpoint.get("registers", {})
	var boundary: Dictionary = checkpoint.get("source_boundary", {})
	var ram: PackedByteArray = validated["ram"]
	var stack_page: PackedByteArray = validated["stack_page"]
	print("Checkpoint provenance: origin=%s frame=%d stage=%s ROM=%s input=%s" % [
		String(checkpoint["origin"]), int(checkpoint.get("source_frame", -1)),
		String(checkpoint.get("route_stage", "")),
		String(checkpoint["rom_sha256"]).substr(0, 12),
		String(checkpoint["input_trace_sha256"]).substr(0, 12),
	])
	print("D193 boundary: dispatch slot=$05 PC=$%04X bank=$%02X; unresolved read PC=$%04X bank=$%02X; RAM=%d bytes, stack=%d bytes, mirror=valid" % [
		int(checkpoint["source_dispatch"]["pc"]),
		int(checkpoint["source_dispatch"]["bank"]),
		int(boundary["pc"]), int(boundary["bank"]), ram.size(), stack_page.size(),
	])

	if not ResourceLoader.exists(WORKER_SCRIPT_PATH):
		print("Checkpoint envelope validated; focused execution awaits the D193 worker API at %s." % WORKER_SCRIPT_PATH)
		quit(2)
		return
	var worker_script := load(WORKER_SCRIPT_PATH) as Script
	if worker_script == null:
		_fail("The D193 worker script could not be loaded.")
		return
	var worker: Object = worker_script.new()
	if not worker.has_method("configure_from_project_sources") \
			or not worker.has_method("execute_live_boundary"):
		_fail("The D193 worker does not expose the coordinated checkpoint API.")
		return
	if not bool(worker.call("configure_from_project_sources")):
		_fail("D193 worker source configuration failed: %s" % str(worker.get("error_message")))
		return
	var live_boundary: Dictionary = checkpoint["source_boundary"].duplicate(true)
	live_boundary["rom_sha256"] = String(checkpoint["rom_sha256"])
	live_boundary["exit_pc"] = int(live_boundary["pc"])
	live_boundary["exit_bank"] = int(live_boundary["bank"])
	live_boundary["source_dispatch"] = checkpoint["source_dispatch"].duplicate(true)
	live_boundary["registers"] = checkpoint["registers"].duplicate(true)
	live_boundary["mapper"] = checkpoint["mapper"].duplicate(true)
	live_boundary["ram_image"] = ram.duplicate()
	live_boundary["stack_page"] = stack_page.duplicate()
	var transition: Variant = worker.call("execute_live_boundary", live_boundary)
	if not transition is Dictionary or not bool(transition.get("ok", false)):
		var failure: Dictionary = transition if transition is Dictionary else {}
		var clock_trace: Array[String] = []
		for instruction_variant in failure.get("instructions", []):
			if instruction_variant is Dictionary:
				var instruction: Dictionary = instruction_variant
				var pc := int(instruction.get("pc", -1))
				if pc >= 0xD1AD and pc < 0xD1D2:
					clock_trace.append("$%04X->$%04X op=$%02X/$%02X A/X/P=$%02X/$%02X/$%02X branch=%s" % [pc,
						int(instruction.get("next_pc", -1)),
						int(instruction.get("opcode", -1)), int(instruction.get("operand", -1)),
						int(instruction.get("a", -1)), int(instruction.get("x", -1)),
						int(instruction.get("p", -1)), str(instruction.get("branch_taken", "-"))])
		_fail("D193 focused transition failed at bank=$%02X PC=$%04X: %s" % [
			int(failure.get("exit_bank", -1)), int(failure.get("exit_pc", -1)),
			String(failure.get("error", "malformed worker result")) + " trace=" + str(clock_trace)])
		return
	var handoff_variant: Variant = transition.get("handoff", {})
	var calls_variant: Variant = transition.get("calls", [])
	if not handoff_variant is Dictionary or not calls_variant is Array:
		_fail("D193 worker result omitted its handoff or call trace.")
		return
	var handoff: Dictionary = handoff_variant
	var calls: Array = calls_variant
	var yield_jsr_callsite := -1
	var yield_jsr_call_count := 0
	for call_variant in calls:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("target", -1)) == 0xC515:
				yield_jsr_callsite = int(call.get("callsite", -1))
				yield_jsr_call_count += 1
	if String(transition.get("status", "")) != "ef7f_async_task_yield" \
			or String(transition.get("exit_kind", "")) != "source_handoff_at_cb0f" \
			or int(transition.get("exit_pc", -1)) != 0xCB0F \
			or int(transition.get("exit_bank", -1)) != 0x1E \
			or String(handoff.get("kind", "")) != "async_renderer_worker_task_yield" \
			or int(handoff.get("renderer_callsite", -1)) != 0xD1CF \
			or int(handoff.get("renderer_entry_pc", -1)) != 0xEF7F \
			or int(handoff.get("renderer_return_pc", -1)) != 0xD1D2 \
			or int(handoff.get("worker_callsite", -1)) != 0xEF96 \
			or int(handoff.get("worker_entry_pc", -1)) != 0x800C \
			or int(handoff.get("yield_trampoline_pc", -1)) != 0xC515 \
			or int(handoff.get("yield_target_pc", -1)) != 0xCB0F \
			or int(handoff.get("yield_target_bank", -1)) != 0x1E \
			or int(handoff.get("d193_resume_pc_after_renderer", -1)) != 0xD1D2 \
			or int(handoff.get("outer_caller_return_pc", -1)) != 0xE1F1 \
			or bool(handoff.get("callee_rts_observed", true)) \
			or int(handoff.get("yield_jsr_callsite", -1)) != yield_jsr_callsite \
			or yield_jsr_call_count != 1:
		_fail("D193 worker result did not match the bounded `$EF7F->$800C->$C515->$CB0F` handoff.")
		return
	print("D193 focused transition: status=%s exit=$%04X bank=$%02X; `$D1CF->$EF7F->$800C->$%04X->$C515->$CB0F`; callee RTS unobserved; post-scheduler return `$E1F1` is recorded, not executed" % [
		String(transition["status"]), int(transition["exit_pc"]),
		int(transition["exit_bank"]), yield_jsr_callsite,
	])
	quit(0)


func _validate_checkpoint(checkpoint: Dictionary) -> Dictionary:
	if int(checkpoint.get("schema_version", -1)) != 1:
		return _invalid("Unsupported checkpoint schema version.")
	if String(checkpoint.get("origin", "")) != "ordinary_input_godot_source_route":
		return _invalid("Checkpoint origin is not the ordinary-input Godot source route.")
	if String(checkpoint.get("rom_sha256", "")) != ROM_SHA256:
		return _invalid("Checkpoint ROM hash does not match the supported ROM revision.")
	var trace_bytes := FileAccess.get_file_as_bytes(INPUT_TRACE_PATH)
	if trace_bytes.is_empty() or _sha256(trace_bytes) != INPUT_TRACE_SHA256:
		return _invalid("The packaged recorded-input trace is missing or has changed.")
	if String(checkpoint.get("input_trace_sha256", "")) != INPUT_TRACE_SHA256:
		return _invalid("Checkpoint input-trace hash does not match the packaged trace.")
	if String(checkpoint.get("route_stage", "")) != "source_route_gap":
		return _invalid("Checkpoint was not captured at the expected source-route gap.")

	var source_boundary_variant: Variant = checkpoint.get("source_boundary", {})
	var source_dispatch_variant: Variant = checkpoint.get("source_dispatch", {})
	var registers_variant: Variant = checkpoint.get("registers", {})
	var mapper_variant: Variant = checkpoint.get("mapper", {})
	if not source_boundary_variant is Dictionary or not source_dispatch_variant is Dictionary \
			or not registers_variant is Dictionary or not mapper_variant is Dictionary:
		return _invalid("Checkpoint source boundary, dispatch, register, or mapper data is malformed.")
	var source_boundary: Dictionary = source_boundary_variant
	var source_dispatch: Dictionary = source_dispatch_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var blocked_variant: Variant = source_boundary.get("blocked_read", {})
	var calls_variant: Variant = source_boundary.get("calls", [])
	var instructions_variant: Variant = source_boundary.get("instructions", [])
	var spans_variant: Variant = source_boundary.get("executed_source_spans", [])
	if not blocked_variant is Dictionary or not calls_variant is Array \
			or not instructions_variant is Array or not spans_variant is Array:
		return _invalid("Checkpoint blocked-read, call, instruction, or source-span provenance is malformed.")
	var blocked_read: Dictionary = blocked_variant
	if String(source_boundary.get("exit_kind", "")) != "unresolved_source_span" \
			or int(source_boundary.get("pc", -1)) != 0xD193 \
			or int(source_boundary.get("bank", -1)) != 0x1E \
			or int(blocked_read.get("instruction_pc", -1)) != 0xD193 \
			or int(blocked_read.get("requested_address", -1)) != 0xD193 \
			or int(blocked_read.get("bank", -1)) != 0x1E \
			or int(registers.get("pc", -1)) != 0xD193:
		return _invalid("Checkpoint does not identify the exact unresolved D193 bank-$1E read.")
	if String(source_dispatch.get("rom_sha256", "")) != ROM_SHA256 \
			or int(source_dispatch.get("slot_base", -1)) != 0x05 \
			or String(source_dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(source_dispatch.get("pc", -1)) != 0xE14A \
			or int(source_dispatch.get("bank", -1)) != 0x1F \
			or not bool(source_dispatch.get("source_dispatch_observed", false)):
		return _invalid("Checkpoint does not carry the expected live slot-$05 `$E14A` dispatch proof.")
	if int(mapper.get("bank_low", -1)) < 0 or int(mapper.get("bank_low", -1)) > 0xFF \
			or int(mapper.get("bank_high", -1)) < 0 or int(mapper.get("bank_high", -1)) > 0xFF \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F \
			or int(mapper.get("select", -1)) < 0 or int(mapper.get("select", -1)) > 0x07:
		return _invalid("Checkpoint mapper state does not match the fixed-bank D193 worker context.")

	var ram_hex := String(checkpoint.get("ram_hex", ""))
	var stack_hex := String(checkpoint.get("stack_page_hex", ""))
	if ram_hex.length() != 0x800 * 2 or stack_hex.length() != 0x100 * 2:
		return _invalid("Checkpoint RAM or stack hex length is invalid.")
	var ram := ram_hex.hex_decode()
	var stack_page := stack_hex.hex_decode()
	if ram.size() != 0x800 or stack_page.size() != 0x100:
		return _invalid("Checkpoint RAM or stack payload failed hex decoding.")
	if _sha256(ram) != String(checkpoint.get("ram_sha256", "")) \
			or _sha256(stack_page) != String(checkpoint.get("stack_page_sha256", "")):
		return _invalid("Checkpoint RAM or stack SHA-256 does not match its payload.")
	if ram.slice(0x0100, 0x0200) != stack_page:
		return _invalid("Checkpoint stack page does not mirror RAM `$0100-$01FF`.")
	return {"ok": true, "ram": ram, "stack_page": stack_page}


func _invalid(message: String) -> Dictionary:
	return {"ok": false, "error": message}


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK \
			or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
