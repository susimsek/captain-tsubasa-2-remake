extends SceneTree
## Audits whether the Godot-produced D193 checkpoint can safely resume through
## the production scheduler. It never seeds scheduler RAM or invokes FCEUX.

const DEFAULT_CHECKPOINT_PATH := "/tmp/ct2_d193_e14a_checkpoint.json"
const INPUT_TRACE_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const INPUT_TRACE_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const REPORT_PATH := "/tmp/ct2_d193_checkpoint_scheduler_resume_audit.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var start_msec := Time.get_ticks_msec()
	var checkpoint_path := OS.get_environment("CT2_ROUTE_CHECKPOINT_IN").strip_edges()
	if checkpoint_path.is_empty():
		checkpoint_path = DEFAULT_CHECKPOINT_PATH
	var checkpoint_file := FileAccess.open(checkpoint_path, FileAccess.READ)
	if checkpoint_file == null:
		_fail("Could not open the Godot route checkpoint: %s" % checkpoint_path)
		return
	var parsed: Variant = JSON.parse_string(checkpoint_file.get_as_text())
	checkpoint_file.close()
	if not parsed is Dictionary:
		_fail("The Godot route checkpoint is not a JSON object.")
		return
	var checkpoint: Dictionary = parsed
	var validation := _validate_checkpoint(checkpoint)
	if not bool(validation.get("ok", false)):
		_fail(String(validation.get("error", "Checkpoint validation failed.")))
		return

	# Configure only: do not initialize the source scheduler, since that would
	# start a new route state unrelated to this checkpoint.
	var scheduler: Object = SCHEDULER_SCRIPT.new()
	if not bool(scheduler.call("configure_from_project_sources")):
		_fail("Production scheduler source configuration failed: %s" % String(scheduler.get("error_message")))
		return
	var scheduler_status: Dictionary = scheduler.call("get_status")
	var method_names: Array[String] = []
	for method_variant in scheduler.get_method_list():
		if method_variant is Dictionary:
			method_names.append(String((method_variant as Dictionary).get("name", "")))
	var restore_methods: Array[String] = []
	for method_name in method_names:
		if method_name.to_lower().contains("checkpoint") \
				or method_name.to_lower().contains("restore") \
				or method_name.to_lower().contains("resume_from"):
			restore_methods.append(method_name)

	var missing_checkpoint_state: Array[String] = []
	for field_name in ["scheduler_snapshot", "slot05_e14a_boundary", "slot05_worker_input"]:
		if not checkpoint.has(field_name):
			missing_checkpoint_state.append(field_name)
	var output := {
		"schema": "ct2-d193-checkpoint-scheduler-resume-audit-v1",
		"status": "checkpoint_valid_but_scheduler_resume_unavailable",
		"checkpoint_path": checkpoint_path,
		"checkpoint_valid": true,
		"checkpoint_origin": String(checkpoint["origin"]),
		"source_frame": int(checkpoint["source_frame"]),
		"source_boundary_pc": int(checkpoint["source_boundary"]["pc"]),
		"source_boundary_bank": int(checkpoint["source_boundary"]["bank"]),
		"source_dispatch_pc": int(checkpoint["source_dispatch"]["pc"]),
		"source_dispatch_slot": int(checkpoint["source_dispatch"]["slot_base"]),
		"missing_scheduler_resume_state": missing_checkpoint_state,
		"production_scheduler_configured": true,
		"production_scheduler_initialized": bool(scheduler_status.get("initialized", false)),
		"production_scheduler_active_task_slot": int(scheduler_status.get("active_task_slot", -1)),
		"production_scheduler_adoption_api_available": method_names.has("adopt_slot05_clock_tick_renderer_handoff"),
		"production_scheduler_restore_api_candidates": restore_methods,
		"worker_or_scheduler_transition_attempted": false,
		"title_frames_replayed": false,
		"fceux_state_used": false,
		"hand_authored_ram_used": false,
		"elapsed_audit_msec": Time.get_ticks_msec() - start_msec,
		"reason": "The checkpoint contains the D193 worker boundary, but not the live E14A scheduler context required by the production adoption method. The scheduler is configured but intentionally uninitialized; no state was fabricated to pass its preconditions.",
	}
	_write_report(output)
	print("CHECKPOINT VALID: frame=%d, slot-$05 dispatch=$%04X, worker boundary=$%04X bank=$%02X" % [
		int(checkpoint["source_frame"]), int(checkpoint["source_dispatch"]["pc"]),
		int(checkpoint["source_boundary"]["pc"]), int(checkpoint["source_boundary"]["bank"]),
	])
	print("BLOCKED: checkpoint lacks scheduler/E14A resume state; production scheduler remains uninitialized.")
	print("No scheduler transition or worker replay attempted. Audit report: %s" % REPORT_PATH)
	quit(0)


func _validate_checkpoint(checkpoint: Dictionary) -> Dictionary:
	if int(checkpoint.get("schema_version", -1)) != 1 \
			or String(checkpoint.get("origin", "")) != "ordinary_input_godot_source_route" \
			or String(checkpoint.get("rom_sha256", "")) != ROM_SHA256 \
			or String(checkpoint.get("route_stage", "")) != "source_route_gap":
		return {"ok": false, "error": "Checkpoint schema, provenance, ROM identity, or route stage is invalid."}
	var input_bytes := FileAccess.get_file_as_bytes(INPUT_TRACE_PATH)
	if input_bytes.is_empty() or _sha256(input_bytes) != INPUT_TRACE_SHA256 \
			or String(checkpoint.get("input_trace_sha256", "")) != INPUT_TRACE_SHA256:
		return {"ok": false, "error": "Checkpoint does not match the checked recorded-input trace."}
	var source_boundary: Variant = checkpoint.get("source_boundary", {})
	var source_dispatch: Variant = checkpoint.get("source_dispatch", {})
	var registers: Variant = checkpoint.get("registers", {})
	var mapper: Variant = checkpoint.get("mapper", {})
	if not source_boundary is Dictionary or not source_dispatch is Dictionary \
			or not registers is Dictionary or not mapper is Dictionary:
		return {"ok": false, "error": "Checkpoint boundary, dispatch, register, or mapper data is malformed."}
	var boundary: Dictionary = source_boundary
	var dispatch: Dictionary = source_dispatch
	var cpu: Dictionary = registers
	var banks: Dictionary = mapper
	var blocked: Variant = boundary.get("blocked_read", {})
	if not blocked is Dictionary \
			or String(boundary.get("exit_kind", "")) != "unresolved_source_span" \
			or int(boundary.get("pc", -1)) != 0xD193 \
			or int(boundary.get("bank", -1)) != 0x1E \
			or int((blocked as Dictionary).get("requested_address", -1)) != 0xD193 \
			or int(cpu.get("pc", -1)) != 0xD193 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or int(dispatch.get("pc", -1)) != 0xE14A \
			or int(dispatch.get("bank", -1)) != 0x1F \
			or not bool(dispatch.get("source_dispatch_observed", false)) \
			or int(banks.get("bank_low", -1)) != 0x1C \
			or int(banks.get("bank_high", -1)) != 0x1D:
		return {"ok": false, "error": "Checkpoint does not match the verified E14A-to-D193 source boundary."}
	var ram_hex := String(checkpoint.get("ram_hex", ""))
	var stack_hex := String(checkpoint.get("stack_page_hex", ""))
	if ram_hex.length() != 0x1000 or stack_hex.length() != 0x200:
		return {"ok": false, "error": "Checkpoint RAM or stack payload has the wrong size."}
	var ram := ram_hex.hex_decode()
	var stack := stack_hex.hex_decode()
	if ram.size() != 0x800 or stack.size() != 0x100 \
			or _sha256(ram) != String(checkpoint.get("ram_sha256", "")) \
			or _sha256(stack) != String(checkpoint.get("stack_page_sha256", "")) \
			or ram.slice(0x0100, 0x0200) != stack:
		return {"ok": false, "error": "Checkpoint RAM/stack hashes or mirrored stack page do not validate."}
	return {"ok": true}


func _write_report(report: Dictionary) -> void:
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write audit report: " + REPORT_PATH)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK \
			or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
