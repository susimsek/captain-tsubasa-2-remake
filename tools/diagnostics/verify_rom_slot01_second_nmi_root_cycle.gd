extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const EXECUTOR := preload("res://scripts/gameplay/rom_ee9f_empty_actor_call_executor.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ACTOR_POINTERS := [0x0547, 0x055C, 0x0571, 0x0586, 0x059B, 0x05B0]


func _init() -> void:
	if not _verify_live_root_cycle():
		quit(1)
		return
	quit(0)


func _verify_live_root_cycle() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh context builder setup failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Source-generated kickoff context failed: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Route runner setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("last_source_boundary", "")) != "$EB8B":
		return _fail("Fresh route did not reach its ROM-derived `$EB8B` yield boundary.")
	var first_nmi: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(first_nmi.get("ok", false)) \
			or String(first_nmi.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			or not bool(first_nmi.get("awaiting_external_nmi", false)):
		return _fail("First NMI did not leave the source-owned second-NMI wait state.")
	var second_nmi: Dictionary = runner.advance_on_external_nmi(2, 0x88)
	if not bool(second_nmi.get("ok", false)):
		return _fail("Second-NMI root transition failed: " + runner.error_message)
	if int(second_nmi.get("selected_task_slot", -1)) != 0x01 \
			or not bool(second_nmi.get("pending_queue_guard_validated", false)) \
			or bool(second_nmi.get("ppu_bus_events_applied", true)):
		return _fail("Second NMI did not preserve the source-selected slot-$01 boundary and unapplied PPU events.")

	var dispatch: Dictionary = second_nmi.get("selected_task_dispatch", {})
	var boundary: Dictionary = second_nmi.get("selected_task_boundary", {})
	var request: Dictionary = second_nmi.get("slot01_call_request", {})
	var ee9f_result: Dictionary = second_nmi.get("slot01_ee9f_result", {})
	if int(dispatch.get("pc", -1)) != 0xCA52 \
			or int(dispatch.get("sp", -1)) != 0x2A \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(boundary.get("active_task_slot", -1)) != 0x01 \
			or int(boundary.get("pc", -1)) != 0xCA52 \
			or int(request.get("source_pc", -1)) != 0xCA52 \
			or int(request.get("target_cpu_address", -1)) != 0xEE9F \
			or int(request.get("expected_return_pc", -1)) != 0xCA55 \
			or bool(request.get("callee_body_executed", true)):
		return _fail("Live slot-$01 dispatch, scheduler snapshot, and `$EE9F` caller request are not aligned.")
	if not bool(ee9f_result.get("ok", false)) \
			or String(ee9f_result.get("status", "")) != "returned_to_source_caller" \
			or String(ee9f_result.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Live `$EE9F` actor loop did not return through its checked source path.")
	var visits: Array = ee9f_result.get("actor_visits", [])
	var ee9f_ram: PackedByteArray = ee9f_result.get("ram_image", PackedByteArray())
	var ee9f_stack: PackedByteArray = ee9f_result.get("stack_page", PackedByteArray())
	var ee9f_registers: Dictionary = ee9f_result.get("registers", {})
	if visits.size() != 6 or ee9f_ram.size() != 0x800 or ee9f_stack.size() != 0x100 \
			or int(ee9f_registers.get("pc", -1)) != 0xCA55 \
			or int(ee9f_registers.get("sp", -1)) != int(dispatch.get("sp", -2)):
		return _fail("The ROM actor loop did not return after six visits with the dispatched stack restored.")
	for ordinal in range(ACTOR_POINTERS.size()):
		var visit: Dictionary = visits[ordinal]
		var actor_pointer := int(ACTOR_POINTERS[ordinal])
		if int(visit.get("ordinal", -1)) != ordinal \
				or int(visit.get("actor_index", -1)) != ordinal \
				or int(visit.get("actor_pointer", -1)) != actor_pointer \
				or int(visit.get("flag", -1)) != 0 \
				or not bool(visit.get("inactive", false)) \
				or int(ee9f_ram[actor_pointer]) != 0:
			return _fail("Actor record `$%04X` did not take its source-derived inactive branch." % actor_pointer)

	var e3ca_result: Dictionary = second_nmi.get("slot01_e3ca_result", {})
	var yield_request: Dictionary = second_nmi.get("slot01_yield_request", {})
	var saved_boundary: Dictionary = second_nmi.get("slot01_cb0f_saved_boundary", {})
	var post_yield_scan: Dictionary = second_nmi.get("post_root_yield_scan", {})
	var next_boundary: Dictionary = second_nmi.get("next_selected_task_boundary", {})
	var next_slot := int(second_nmi.get("next_selected_task_slot", -1))
	if not bool(e3ca_result.get("ok", false)) \
			or String(e3ca_result.get("status", "")) != "returned_to_source_caller" \
			or int(e3ca_result.get("registers", {}).get("pc", -1)) != 0xCA58 \
			or String(yield_request.get("status", "")) != "yield_requested" \
			or int(yield_request.get("callsite_pc", -1)) != 0xCA4F \
			or int(yield_request.get("target_cpu_address", -1)) != 0xCB0F \
			or int(yield_request.get("resume_pc", -1)) != 0xCA52 \
			or int(yield_request.get("delay_in_a", -1)) != 1 \
			or int(saved_boundary.get("pc", -1)) != 0xCB0F \
			or int(saved_boundary.get("slot_base", -1)) != 0x01 \
			or next_slot != 0x05 \
			or int(next_boundary.get("slot_base", -1)) != next_slot \
			or int(post_yield_scan.get("decision", -1)) != int(SCHEDULER.ScanDecision.YIELDED_RESUME):
		return _fail("The live `$CA55->$E3CA->$CA4F->$CB0F` return/yield did not stop at the next scheduler selection.")
	var saved_record: PackedByteArray = saved_boundary.get("record", PackedByteArray())
	if saved_record.size() != 4 \
			or not String(second_nmi.get("last_source_boundary", "")).contains("$CA4F->$CB0F") \
			or not String(second_nmi.get("last_source_boundary", "")).contains("$05"):
		return _fail("Saved slot-$01 boundary or next selected slot-$05 scheduler boundary is missing.")
	var ppu_events: Array = second_nmi.get("ppu_bus_events", [])
	if ppu_events.size() != 20 or bool(second_nmi.get("ppu_bus_events_applied", true)) \
			or bool(second_nmi.get("nmi_cadence_generated", true)):
		return _fail("The route applied PPU events or generated NMI cadence.")

	var mutated_dispatch := dispatch.duplicate(true)
	mutated_dispatch["a"] = (int(mutated_dispatch.get("a", 0)) + 1) & 0xFF
	var executor = EXECUTOR.new()
	if not executor.configure_from_project_sources():
		return _fail("ROM source package setup failed: " + executor.error_message)
	var rejected: Dictionary = executor.execute_from_source_call(mutated_dispatch, boundary, request)
	if bool(rejected.get("ok", true)) \
			or not String(rejected.get("error", "")).contains("Caller request and live dispatch disagree"):
		return _fail("The executor accepted a dispatch mutation that disagreed with its live caller request.")

	print("PASS: second NMI selected slot-$01; all six ROM-ordered actor flags were `$00`, and `$EE9F` returned to `$CA55`.")
	print("PASS: the live caller consumed `$E3CA`, saved the next slot-$01 yield at `$CB0F`, then the scheduler selected slot `$05`.")
	print("PASS: the 20 PPU bus events remained unapplied; the executor rejected a mismatched caller/dispatch pair.")
	var input_stack: PackedByteArray = boundary.get("stack_page", PackedByteArray())
	print("INPUT: A=$%02X X=$%02X Y=$%02X SP=$%02X banks=$%02X/$%02X; stack[$27:$2C]=%s." % [
		int(dispatch.get("a", -1)), int(dispatch.get("x", -1)), int(dispatch.get("y", -1)),
		int(dispatch.get("sp", -1)), int(dispatch.get("bank_low", -1)), int(dispatch.get("bank_high", -1)),
		input_stack.slice(0x27, 0x2C).hex_encode()])
	print("BOUNDARY: saved record=%s; next selected slot=$%02X before its task body." % [
		(saved_record as PackedByteArray).hex_encode(), next_slot])
	print("LIMIT: no actor was active; the `$F1` actor producer route, drawing, and PPU/APU timing are not established by this transition.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
