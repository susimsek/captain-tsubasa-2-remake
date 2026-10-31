extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify_live_slot09_resume() or not _verify_stale_boundary_rejected():
		quit(1)
		return
	quit(0)


func _verify_live_slot09_resume() -> bool:
	var staged := _stage_selected_slot09()
	if not bool(staged.get("ok", false)):
		return _fail("Could not produce the live slot-$09 selection after slot-$05 save: " + String(staged.get("error", "unknown error")))
	var runner: Variant = staged["runner"]
	var slot05_resume: Dictionary = staged["slot05_resume"]
	var boundary: Dictionary = slot05_resume.get("next_selected_task_boundary", {})
	var status: Dictionary = runner.get_status()
	if String(slot05_resume.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(slot05_resume.get("next_selected_task_slot", -1)) != 0x09 \
			or int(boundary.get("pc", -1)) != 0xCB0F \
			or boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0x76, 0x18, 0x19]) \
			or int(status.get("pending_selected_task_slot", -1)) != 0x09 \
			or int(status.get("pending_selected_task_boundary_pc", -1)) != 0xCB0F:
		return _fail("Slot-$05 resume did not expose the live slot-$09 pre-dispatch boundary through the transition result and runner status.")
	var result: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(result.get("ok", false)):
		return _fail("Source-backed slot-$09 continuation failed: " + String(result.get("error", runner.error_message)))
	var dispatch: Dictionary = result.get("slot09_dispatch", {})
	var prefix: Dictionary = result.get("slot09_resume_result", {})
	var first_worker: Dictionary = result.get("slot09_86f8_worker_result", {})
	var second_worker: Dictionary = result.get("slot09_8779_worker_result", {})
	var third_worker: Dictionary = result.get("slot09_87e6_worker_result", {})
	var root_zero: Dictionary = result.get("slot09_ebd7_root_zero_result", {})
	var save_result: Dictionary = result.get("slot09_cb0f_save_result", {})
	var saved: Dictionary = result.get("slot09_cb0f_saved_boundary", {})
	var scan: Dictionary = result.get("post_slot09_scan", {})
	if String(result.get("status", "")) != "slot09_saved_and_rescanned" \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("slot_base", -1)) != 0x09 \
			or int(dispatch.get("pc", -1)) != 0xEB8B \
			or int(dispatch.get("a", -1)) != 0x00 \
			or int(dispatch.get("x", -1)) != 0x00 \
			or int(dispatch.get("y", -1)) != 0x05 \
			or int(dispatch.get("sp", -1)) != 0x7A \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19 \
			or String(prefix.get("status", "")) != "stopped_before_worker_body" \
			or int(prefix.get("exit_pc", -1)) != 0x86F8 \
			or bool(prefix.get("worker_body_bytes_read", true)) \
			or int(first_worker.get("exit_pc", -1)) != 0xEBB3 \
			or int(second_worker.get("exit_pc", -1)) != 0xEBC5 \
			or int(third_worker.get("exit_pc", -1)) != 0xEBD7 \
			or int(root_zero.get("exit_pc", -1)) != 0xCB0F \
			or bool(root_zero.get("yield_handler_executed", true)) \
			or String(save_result.get("status", "")) != "slot09_saved_at_cb0f" \
			or int(saved.get("slot_base", -1)) != 0x09 \
			or int(saved.get("pc", -1)) != 0xCB0F \
			or bool(result.get("nmi_cadence_generated", true)) \
			or bool(result.get("ppu_bus_events_applied", true)) \
			or bool(result.get("next_task_body_executed", true)):
		return _fail("Slot-$09 did not follow the checked prefix/zero branches through its save and stop at the next scheduler boundary.")
	var status_after: Dictionary = runner.get_status()
	var decision := int(scan.get("decision", -1))
	if decision == int(SCHEDULER.ScanDecision.YIELDED_RESUME):
		var next_boundary: Dictionary = result.get("next_selected_task_boundary", {})
		if int(result.get("next_selected_task_slot", -1)) != int(status_after.get("pending_selected_task_slot", -2)) \
				or int(next_boundary.get("pc", -1)) != 0xCB0F \
				or int(status_after.get("pending_selected_task_boundary_pc", -1)) != 0xCB0F \
				or bool(result.get("awaiting_external_nmi", true)):
			return _fail("Post-save yielded selection was not retained as the next pre-dispatch boundary.")
	elif decision == int(SCHEDULER.ScanDecision.WAIT_FOR_NMI_READY):
		if int(status_after.get("pending_selected_task_slot", -1)) != -1 \
				or int(status_after.get("pending_selected_task_boundary_pc", -1)) != -1 \
				or not bool(result.get("awaiting_external_nmi", false)) \
				or not bool(status_after.get("pending_nmi_queue_guard_available", false)):
			return _fail("Post-save NMI wait was not retained as the next external-NMI boundary.")
	else:
		return _fail("Post-save scan stopped at an unsupported scheduler decision: " + str(scan))
	print("PASS: the slot-$05 save scan exposed slot-$09 `$CB0F` without dispatch; the route resumed only that stored boundary.")
	print("PASS: ROM-checked `$EB8B->$86F8->$EBB3->$EBC5->$EBD7->$CB0F` branches and save reached the next selected-task/NMI boundary.")
	print("DISPATCH: PC=$%04X A/X/Y=$%02X/$%02X/$%02X SP=$%02X banks=$%02X/$%02X selected_record=%s" % [
		int(dispatch.get("pc", -1)), int(dispatch.get("a", -1)), int(dispatch.get("x", -1)),
		int(dispatch.get("y", -1)), int(dispatch.get("sp", -1)), int(dispatch.get("bank_low", -1)),
		int(dispatch.get("bank_high", -1)), PackedByteArray(boundary.get("record", PackedByteArray())).hex_encode()])
	var call_summary: Array[String] = []
	for call_variant in prefix.get("calls", []):
		var call: Dictionary = call_variant
		call_summary.append("$%04X->$%04X return->$%04X" % [int(call["source_pc"]),
			int(call["target_pc"]), int(call["return_pc"])])
	var return_summary: Array[String] = []
	for return_variant in prefix.get("returns", []):
		var return_event: Dictionary = return_variant
		return_summary.append("$%04X->$%04X" % [int(return_event["source_pc"]),
			int(return_event["return_pc"])])
	print("CALLS: " + ", ".join(PackedStringArray(call_summary)))
	print("RETURNS: " + ", ".join(PackedStringArray(return_summary)))
	print("SOURCE STOPS: $86F8->$EBB3, $8779->$EBC5, $87E6->$EBD7, root->$CB0F; save=%s record=%s; scan=%s next_slot=$%02X next_pc=$%04X" % [
		String(save_result.get("status", "")), PackedByteArray(save_result.get("task_record", PackedByteArray())).hex_encode(),
		str(scan), int(result.get("next_selected_task_slot", -1)),
		int(result.get("next_selected_task_boundary", {}).get("pc", -1))])
	print("LIMIT: no next task body, generated NMI cadence, PPU application, visible rendering, or later match flow was executed.")
	return true


func _verify_stale_boundary_rejected() -> bool:
	var staged := _stage_selected_slot09()
	if not bool(staged.get("ok", false)):
		return _fail("Could not stage the negative boundary-integrity case: " + String(staged.get("error", "unknown error")))
	var runner: Variant = staged["runner"]
	var pending: Dictionary = runner.get("_pending_selected_task_boundary").duplicate(true)
	pending["pc"] = 0xCB10
	runner.set("_pending_selected_task_boundary", pending)
	var rejected: Dictionary = runner.resume_selected_slot09_worker()
	var status: Dictionary = runner.get_status()
	var scheduler_status: Dictionary = status.get("scheduler", {})
	if bool(rejected.get("ok", true)) \
			or int(scheduler_status.get("active_task_slot", -2)) != -1 \
			or not String(rejected.get("error", "")).contains("refusing stale dispatch"):
		return _fail("A stale slot-$09 boundary was not rejected before task dispatch.")
	print("PASS: a mutated pending boundary was rejected before the scheduler dispatched slot-$09.")
	return true


func _stage_selected_slot09() -> Dictionary:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return {"ok": false, "error": builder.error_message}
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return {"ok": false, "error": builder.error_message}
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return {"ok": false, "error": runner.error_message}
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)):
		return {"ok": false, "error": runner.error_message}
	var first_nmi: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(first_nmi.get("ok", false)):
		return {"ok": false, "error": runner.error_message}
	var second_nmi: Dictionary = runner.advance_on_external_nmi(2, 0x88)
	if not bool(second_nmi.get("ok", false)) \
			or int(second_nmi.get("next_selected_task_slot", -1)) != 0x05:
		return {"ok": false, "error": runner.error_message}
	var slot05_resume: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(slot05_resume.get("ok", false)):
		return {"ok": false, "error": runner.error_message}
	return {"ok": true, "runner": runner, "slot05_resume": slot05_resume}


func _fail(message: String) -> bool:
	push_error(message)
	return false
