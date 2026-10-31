extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: source route runner composes the fresh-match task path through slot-$09 `$EB8B`, executes its three zero branches, and saves `$EB88->$CB0F` before the next external NMI wait.")
	print("PASS: the live `$EE9F`/`$E3CA` paths yield root slot `$01`; slot `$05` runs both text callbacks, emits the first menu-window packets, and yields at `$C515`.")
	print("LIMIT: one frame-level NMI edge is supplied; PPU packet consumption, visible field/menu output, cycle timing, and later gameplay remain unresolved.")
	quit(0)


func _verify() -> bool:
	var context_builder = CONTEXT_BUILDER.new()
	if not context_builder.configure_from_project_sources():
		return _fail("Fresh context builder setup failed: " + context_builder.error_message)
	var route_context = context_builder.build_fresh_kickoff_context()
	if route_context == null:
		return _fail("Fresh source context could not be derived: " + context_builder.error_message)

	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source runner configuration failed: " + runner.error_message)
	var begin_result: Dictionary = runner.begin_from_context(route_context)
	if not bool(begin_result.get("ok", false)):
		return _fail("Source route composition failed before `$EB8B`: " + runner.error_message)
	if String(begin_result.get("phase", "")) != "awaiting_external_nmi" \
			or String(begin_result.get("last_source_boundary", "")) != "$EB8B" \
			or bool(begin_result.get("nmi_cadence_generated", true)):
		return _fail("Route runner did not stop at slot-$09 `$EB8B` while awaiting caller-owned NMI.")
	var slot09: Dictionary = begin_result.get("slot09_boundary", {})
	var slot05: Dictionary = begin_result.get("slot05_boundary", {})
	if int(slot09.get("pc", -1)) != 0xCB0F \
			or slot09.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x76, 0x00, 0x01]) \
			or int(slot05.get("pc", -1)) != 0xCB0F \
			or slot05.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x46, 0x18, 0x19]):
		return _fail("Pre-NMI task records do not match the source-owned first yields.")

	# A single explicitly supplied edge is a component-integration input, not
	# evidence for a frame interval or a generated PPU cadence.
	var advance: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(advance.get("ok", false)):
		return _fail("Caller-supplied NMI integration failed: " + runner.error_message)
	if String(advance.get("phase", "")) != "awaiting_external_nmi" \
			or String(advance.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			or not bool(advance.get("awaiting_external_nmi", false)) \
			or not bool(advance.get("next_external_nmi_required", false)) \
			or not bool(advance.get("slot01_caller_bytes_executed", false)) \
			or not bool(advance.get("ee9f_body_executed", false)) \
			or not bool(advance.get("e3ca_body_executed", false)) \
			or not bool(advance.get("slot05_worker_resumed", false)) \
			or bool(advance.get("nmi_cadence_generated", true)) \
			or bool(advance.get("ppu_bus_events_applied", true)):
		return _fail("Post-NMI route result overstates or misidentifies the next source-task boundary: " + str(advance.get("phase")) + " " + str(advance.get("last_source_boundary")) + " error=" + runner.error_message)
	var nmi: Dictionary = advance.get("nmi_result", {})
	var dispatch: Dictionary = advance.get("slot01_dispatch", {})
	var slot01_before: Dictionary = advance.get("slot01_pre_ee9f_boundary", {})
	var slot01_after: Dictionary = advance.get("slot01_after_ee9f_boundary", {})
	var caller_request: Dictionary = advance.get("slot01_callee_request", {})
	var ee9f_result: Dictionary = advance.get("ee9f_result", {})
	var e3ca_request: Dictionary = advance.get("slot01_e3ca_request", {})
	var e3ca_result: Dictionary = advance.get("e3ca_result", {})
	var yield_request: Dictionary = advance.get("slot01_yield_request", {})
	var yield_boundary: Dictionary = advance.get("slot01_yield_result", {})
	var post_root_yield_scan: Dictionary = advance.get("post_root_yield_scan", {})
	var slot05_dispatch: Dictionary = advance.get("slot05_dispatch", {})
	var slot05_resume: Dictionary = advance.get("slot05_resume_result", {})
	var slot05_yield: Dictionary = advance.get("slot05_yield_result", {})
	var post_slot05_scan: Dictionary = advance.get("post_slot05_yield_scan", {})
	var next_task_dispatch: Dictionary = advance.get("next_task_dispatch", {})
	var slot09_resume: Dictionary = advance.get("slot09_resume_result", {})
	var slot09_worker: Dictionary = advance.get("slot09_86f8_worker_result", {})
	var slot09_next_worker: Dictionary = advance.get("slot09_8779_worker_result", {})
	var slot09_third_worker: Dictionary = advance.get("slot09_87e6_worker_result", {})
	var slot09_root_zero: Dictionary = advance.get("slot09_ebd7_root_zero_result", {})
	var menu_queue: Dictionary = advance.get("menu_transfer_queue", {})
	var expected_menu_packets := PackedByteArray([
		0x07, 0x21, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x07, 0x41, 0x22, 0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D,
	])
	var scan_results: Array = advance.get("scan_results", [])
	var selected_slot01 := false
	for scan_variant in scan_results:
		if scan_variant is Dictionary and int(scan_variant.get("selected_slot_base", -1)) == 0x01 \
				and int(scan_variant.get("decision", -1)) == int(SCHEDULER.ScanDecision.YIELDED_RESUME):
			selected_slot01 = true
	if not bool(nmi.get("serviced", false)) \
			or String(nmi.get("edge_source", "")) != "caller-supplied PPU NMI delivery" \
			or not selected_slot01 \
			or int(dispatch.get("pc", -1)) != 0xCA52 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(slot01_before.get("pc", -1)) != 0xCA52 \
			or int(slot01_before.get("sp", -1)) != 0x2A \
			or int(slot01_before.get("ready_delay", -1)) != 0 \
			or slot01_before.get("record", PackedByteArray()) != PackedByteArray([0x00, 0x26, 0x00, 0x01]) \
			or String(caller_request.get("status", "")) != "call_requested" \
			or int(caller_request.get("source_pc", -1)) != 0xCA52 \
			or int(caller_request.get("target_cpu_address", -1)) != 0xEE9F \
			or int(caller_request.get("expected_return_pc", -1)) != 0xCA55 \
			or bool(caller_request.get("callee_body_executed", true)) \
			or String(ee9f_result.get("status", "")) != "returned_to_source_caller" \
			or int(ee9f_result.get("registers", {}).get("pc", -1)) != 0xCA55 \
			or int(slot01_after.get("pc", -1)) != 0xCA55 \
			or int(slot01_after.get("sp", -1)) != 0x2A \
			or int(e3ca_request.get("source_pc", -1)) != 0xCA55 \
			or int(e3ca_request.get("target_cpu_address", -1)) != 0xE3CA \
			or int(e3ca_request.get("expected_return_pc", -1)) != 0xCA58 \
			or String(e3ca_result.get("status", "")) != "returned_to_source_caller" \
			or int(e3ca_result.get("registers", {}).get("pc", -1)) != 0xCA58 \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or int(yield_boundary.get("pc", -1)) != 0xCB0F \
			or yield_boundary.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x26, 0x00, 0x01]) \
			or int(post_root_yield_scan.get("selected_slot_base", -1)) != 0x05 \
			or int(slot05_dispatch.get("pc", -1)) != 0x8889 \
			or int(slot05_dispatch.get("sp", -1)) != 0x4A \
			or not bool(slot05_resume.get("ok", false)) \
			or String(slot05_resume.get("exit_kind", "")) != "yield_at_c515" \
			or int(slot05_resume.get("exit_pc", -1)) != 0xC515 \
			or slot05_yield.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
			or int(post_slot05_scan.get("selected_slot_base", -1)) != 0x09 \
			or int(next_task_dispatch.get("pc", -1)) != 0xEB8B \
			or int(slot09_resume.get("exit_pc", -1)) != 0x86F8 \
			or bool(slot09_resume.get("worker_body_bytes_read", true)) \
			or int(slot09_worker.get("exit_pc", -1)) != 0xEBB3 \
			or bool(slot09_worker.get("next_worker_bytes_read", true)) \
			or int(slot09_next_worker.get("exit_pc", -1)) != 0xEBC5 \
			or bool(slot09_next_worker.get("next_worker_call_executed", true)) \
			or int(slot09_third_worker.get("exit_pc", -1)) != 0xEBD7 \
			or int(slot09_third_worker.get("input_ram_0536", -1)) != 0 \
			or bool(slot09_third_worker.get("next_root_check_executed", true)) \
			or int(slot09_root_zero.get("exit_pc", -1)) != 0xCB0F \
			or bool(slot09_root_zero.get("yield_handler_executed", true)) \
			or int(menu_queue.get("ready_flag", -1)) != 0x80 \
			or int(menu_queue.get("progress", -1)) != 0x02 \
			or menu_queue.get("first_two_packets", PackedByteArray()) != expected_menu_packets:
		return _fail("Route transition mismatch: EE9F=%s at pc=%s, E3CA=%s, slot05 exit=%s scan=%s next=%s." % [
				str(ee9f_result.get("status")), str(slot01_after.get("pc")),
				str(e3ca_result.get("status")), str(slot05_resume.get("exit_pc")),
				{"scan": post_slot05_scan.get("selected_slot_base"),
				"yield": yield_request.get("callsite_pc"), "slot01_yield_pc": yield_boundary.get("pc"),
				"slot01_record": yield_boundary.get("record"),
				"e3ca_pc": e3ca_result.get("registers", {}).get("pc"),
				"slot05_dispatch": slot05_dispatch.get("pc"), "slot05_yield_record": slot05_yield.get("record"),
				"next_pc": next_task_dispatch.get("pc"), "queue": menu_queue,
				"ok": slot05_resume.get("ok"), "last": advance.get("last_source_boundary")}])
	var status: Dictionary = runner.get_status()
	if String(status.get("phase", "")) != "awaiting_external_nmi" \
			or String(status.get("source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			or bool(status.get("nmi_cadence_generated", true)):
		return _fail("Runner status does not retain the root yield boundary and external NMI limitation.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
