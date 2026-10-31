extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: production route consumed its live `$EB88->$CB0F` result and applied the hash-checked `$CB0F` slot save.")
	print("PASS: saved slot `$09` retains `$EB8B`, source stack, banks `$18/$19`, and the scheduler reaches `WAIT_FOR_NMI_READY` at cursor `$19`.")
	print("PASS: modified source RAM and non-source trace state are rejected; no NMI cadence or PPU/APU events are synthesized.")
	print("LIMIT: route stops before the next external NMI and later slot-$09 root checks; no visible match output is established.")
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
	var begin: Dictionary = runner.begin_from_context(route_context)
	if not bool(begin.get("ok", false)):
		return _fail("Source route did not reach its slot-$09 task: " + runner.error_message)
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)):
		return _fail("Source route failed before the post-save boundary: " + runner.error_message)
	if String(advance.get("phase", "")) != "awaiting_external_nmi" \
			or String(advance.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			or not bool(advance.get("awaiting_external_nmi", false)) \
			or not bool(advance.get("next_external_nmi_required", false)) \
			or bool(advance.get("nmi_cadence_generated", true)):
		return _fail("Route did not stop after the source scheduler's next NMI-ready wait: " + str({
			"phase": advance.get("phase"), "boundary": advance.get("last_source_boundary"),
			"awaiting_external_nmi": advance.get("awaiting_external_nmi"),
			"nmi_cadence_generated": advance.get("nmi_cadence_generated")}))
	if not _verify_save(advance):
		return false
	if not _verify_scan(advance):
		return false
	if not _verify_rejection(runner, advance):
		return false
	return true


func _verify_save(advance: Dictionary) -> bool:
	var expected_record := PackedByteArray([0x01, 0x76, 0x18, 0x19])
	var root_result: Dictionary = advance.get("slot09_ebd7_root_zero_result", {})
	var save_result: Dictionary = advance.get("slot09_cb0f_save_result", {})
	var boundary: Dictionary = advance.get("slot09_cb0f_saved_boundary", {})
	var scheduler_status: Dictionary = advance.get("scheduler_status", {})
	if String(root_result.get("status", "")) != "reached_scheduler_yield_handler_entry" \
			or String(root_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json" \
			or String(save_result.get("status", "")) != "slot09_saved_at_cb0f" \
			or String(save_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(save_result.get("source_manifest", "")) != String(root_result.get("source_manifest", "")) \
			or int(save_result.get("handler_entry_pc", -1)) != 0xCB0F \
			or int(save_result.get("callsite_pc", -1)) != 0xEB88 \
			or int(save_result.get("resume_pc", -1)) != 0xEB8B \
			or save_result.get("task_record", PackedByteArray()) != expected_record \
			or int(save_result.get("saved_stack_pointer", -1)) != 0x76 \
			or int(save_result.get("saved_y", -1)) != 0x05 \
			or int(save_result.get("saved_x", -1)) != 0x00 \
			or int(save_result.get("return_low", -1)) != 0x8A \
			or int(save_result.get("return_high", -1)) != 0xEB \
			or String(save_result.get("handler_source_hash", "")) != "b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc" \
			or not bool(save_result.get("preexisting_jsr_frame_reused", false)) \
			or bool(save_result.get("full_source_ram_copied", true)):
		return _fail("`$CB0F` save output differs from its live handler contract: " + str(save_result))
	if int(boundary.get("slot_base", -1)) != 0x09 \
			or int(boundary.get("pc", -1)) != 0xCB0F \
			or int(boundary.get("sp", -1)) != 0x76 \
			or boundary.get("record", PackedByteArray()) != expected_record \
			or int(boundary.get("active_task_slot", -1)) != -1 \
			or int(boundary.get("ram_007F", -1)) != 0x01:
		return _fail("Saved task boundary does not match the modeled `$CB0F` effects: " + str(boundary))
	var saved_ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	var saved_stack: PackedByteArray = boundary.get("stack_page", PackedByteArray())
	if saved_ram.size() != 0x800 or saved_stack.size() != 0x100 \
			or int(saved_ram[0x09]) != 0x01 or int(saved_ram[0x0A]) != 0x76 \
			or int(saved_ram[0x0B]) != 0x18 or int(saved_ram[0x0C]) != 0x19 \
			or int(saved_stack[0x77]) != 0x05 or int(saved_stack[0x78]) != 0x00 \
			or int(saved_stack[0x79]) != 0x8A or int(saved_stack[0x7A]) != 0xEB:
		return _fail("Scheduler RAM/stack snapshot does not preserve the source-derived slot record and resume frame.")
	if String(scheduler_status.get("rom_sha256", "")) != ROM_SHA256 \
			or bool(scheduler_status.get("does_synthesize_nmi_cadence", true)):
		return _fail("Scheduler status does not preserve ROM identity or claims generated NMI cadence.")
	return true


func _verify_scan(advance: Dictionary) -> bool:
	var scans: Array = advance.get("post_slot09_scan_results", [])
	var scan: Dictionary = advance.get("post_slot09_scan", {})
	var checked_slots: Array = scan.get("checked_slots", [])
	if scans.size() != 1 \
			or int(scan.get("decision", -1)) != int(SCHEDULER.ScanDecision.WAIT_FOR_NMI_READY) \
			or checked_slots != [0x0D, 0x11, 0x15] \
			or int(scan.get("scheduler_scan_cursor", -1)) != 0x19 \
			or int(scan.get("ready_latch_after", -1)) != 0:
		return _fail("Scheduler did not scan only later empty slots then wait for an external NMI: " + str(scan))
	return true


func _verify_rejection(runner: Variant, advance: Dictionary) -> bool:
	var live_result: Dictionary = advance.get("slot09_ebd7_root_zero_result", {})
	var mutated: Dictionary = live_result.duplicate(true)
	var ram: PackedByteArray = (live_result.get("ram_image", PackedByteArray()) as PackedByteArray).duplicate()
	ram[0x052E] = 0x01
	mutated["ram_image"] = ram
	var rejected: Dictionary = runner._scheduler.validate_slot09_cb0f_root_result(mutated)
	if bool(rejected.get("ok", true)):
		return _fail("Scheduler accepted a mutated `$052E` that did not come from the live `$87E6` route result.")
	var traced: Dictionary = live_result.duplicate(true)
	traced["trace_state_used"] = true
	rejected = runner._scheduler.validate_slot09_cb0f_root_result(traced)
	if bool(rejected.get("ok", true)):
		return _fail("Scheduler accepted a result marked as trace-state sourced.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
