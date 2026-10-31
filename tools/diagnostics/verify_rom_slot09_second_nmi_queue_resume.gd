extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	if not _verify_live_second_nmi() or not _verify_mutated_pending_queue_rejected():
		quit(1)
		return
	print("PASS: second caller-supplied NMI consumed the live `$0515/$04A5` queue through the hash-checked `$C799->$C8FB` path.")
	print("PASS: 20 ordered `$2002/$2006/$2007` bus events were returned, not applied; the source scan selected yielded slot `$01`.")
	print("PASS: mutated pending queue state is rejected before consuming the second NMI; no cadence was generated.")
	print("LIMIT: the actual scan did not select slot `$09`, so its conditional `$EB8B` dispatch branch was not exercised; visible PPU state remains unresolved.")
	quit(0)


func _verify_live_second_nmi() -> bool:
	var expected_packet_buffer := PackedByteArray([
		0x07, 0x21, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x07, 0x41, 0x22, 0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D,
	])
	var runner = _new_runner()
	if runner == null:
		return false
	var first: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(first.get("ok", false)) \
			or String(first.get("last_source_boundary", "")) != "$CB0F save -> scheduler WAIT_FOR_NMI_READY" \
			or not bool(first.get("awaiting_external_nmi", false)):
		return _fail("First external NMI did not establish the preserved `$CB0F` wait boundary: " + str(first))
	var first_ram: PackedByteArray = first.get("slot09_cb0f_saved_boundary", {}).get("ram_image", PackedByteArray())
	if first_ram.size() != 0x800 \
			or int(first_ram[0x0498]) != 0 \
			or int(first_ram[0x0515]) != 0x80 \
			or first_ram.slice(0x04A5, 0x04A5 + expected_packet_buffer.size()) != expected_packet_buffer:
		return _fail("The first source route did not leave its ROM-derived two-packet queue live for the second NMI.")
	if first.get("ppu_bus_events", []) != [] or bool(first.get("ppu_bus_events_applied", true)):
		return _fail("The first NMI unexpectedly consumed or applied packets that were produced afterward.")

	var second: Dictionary = runner.advance_on_external_nmi(2, 0x88)
	if not bool(second.get("ok", false)):
		return _fail("Second NMI route did not reach its source-supported stop: " + runner.error_message)
	if String(second.get("source_boundary_before_nmi", "")) != String(first.get("last_source_boundary", "")) \
			or not bool(second.get("pending_queue_guard_validated", false)) \
			or int(second.get("external_nmi_frame", -1)) != 2 \
			or not bool(second.get("external_nmi_consumed", false)) \
			or bool(second.get("nmi_cadence_generated", true)):
		return _fail("Second external event lost the previous boundary or bypassed its pending-source guard.")
	var nmi_result: Dictionary = second.get("nmi_result", {})
	var queue: Dictionary = nmi_result.get("secondary_queue", {})
	var events: Array = second.get("ppu_bus_events", [])
	if not bool(nmi_result.get("serviced", false)) \
			or int(nmi_result.get("source_frame", -1)) != 2 \
			or String(nmi_result.get("path", "")) != "fixed_normal" \
			or String(queue.get("status", "")) != "transferred" \
			or String(queue.get("branch", "")) != "secondary_queue_consumed" \
			or int(queue.get("ready_flag_before", -1)) != 0x80 \
			or int(queue.get("ready_flag_after", -1)) != 0 \
			or int(queue.get("packet_count", -1)) != 2 \
			or events.size() != 20 \
			or events != nmi_result.get("ppu_bus_events", []) \
			or bool(second.get("ppu_bus_events_applied", true)):
		return _fail("The second normal-NMI consumer did not return the live two-packet event stream: " + str(queue))
	if not _verify_events(events):
		return false
	var selected_boundary: Dictionary = second.get("selected_task_boundary", {})
	var selected_task_dispatch: Dictionary = second.get("selected_task_dispatch", {})
	if int(second.get("selected_task_slot", -1)) != 0x01 \
			or int(selected_boundary.get("slot_base", -1)) != 0x01 \
			or selected_boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0x26, 0x00, 0x01]) \
			or int(selected_task_dispatch.get("pc", -1)) != 0xCA52 \
			or not String(second.get("last_source_boundary", "")).contains("selected slot $05") \
			or bool(second.get("slot09_resumed_at_eb8b", true)):
		return _fail("The live scheduler's next task boundary differs from its observed source scan: " + str(selected_boundary))
	var task_scans: Array = second.get("next_task_scan_results", [])
	if task_scans.size() != 2 \
			or int(task_scans[0].get("decision", -1)) != int(SCHEDULER.ScanDecision.CLEAR_NMI_AND_RESCAN) \
			or int(task_scans[1].get("decision", -1)) != int(SCHEDULER.ScanDecision.YIELDED_RESUME) \
			or String(second.get("phase", "")) != "waiting_for_selected_task_source" \
			or bool(second.get("ppu_bus_events_applied", true)):
		return _fail("Second NMI did not stop at the source-selected task boundary without applying PPU writes.")
	if String(second.get("rom_sha256", "")) != ROM_SHA256 \
			or bool(second.get("nmi_cadence_generated", true)):
		return _fail("Second-NMI route lost ROM identity or claims synthesized cadence.")
	return true


func _verify_events(events: Array) -> bool:
	var first: Dictionary = events[0]
	var second: Dictionary = events[1]
	var third: Dictionary = events[2]
	var packet_two_status: Dictionary = events[10]
	var packet_two_high: Dictionary = events[11]
	var packet_two_low: Dictionary = events[12]
	var first_payload: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	var second_payload: Array[int] = [0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D]
	if int(first.get("sequence", -1)) != 0 \
			or String(first.get("operation", "")) != "read" \
			or int(first.get("source_pc", -1)) != 0xC96A \
			or int(first.get("ppu_register", -1)) != 0x2002 \
			or int(second.get("ppu_register", -1)) != 0x2006 \
			or int(second.get("value", -1)) != 0x22 \
			or int(third.get("ppu_register", -1)) != 0x2006 \
			or int(third.get("value", -1)) != 0x21 \
			or String(packet_two_status.get("operation", "")) != "read" \
			or int(packet_two_status.get("ppu_register", -1)) != 0x2002 \
			or int(packet_two_high.get("value", -1)) != 0x22 \
			or int(packet_two_low.get("value", -1)) != 0x41:
		return _fail("Ordered PPU bus events do not match the two live queue packet headers.")
	for index in range(7):
		var first_data: Dictionary = events[3 + index]
		var second_data: Dictionary = events[13 + index]
		if String(first_data.get("operation", "")) != "write" \
				or int(first_data.get("source_pc", -1)) != 0xC978 \
				or int(first_data.get("ppu_register", -1)) != 0x2007 \
				or int(first_data.get("value", -1)) != first_payload[index] \
				or String(second_data.get("operation", "")) != "write" \
				or int(second_data.get("source_pc", -1)) != 0xC978 \
				or int(second_data.get("ppu_register", -1)) != 0x2007 \
				or int(second_data.get("value", -1)) != second_payload[index]:
			return _fail("PPUDATA event %d differs from the live ROM queue bytes." % index)
	for index in range(events.size()):
		if int((events[index] as Dictionary).get("sequence", -1)) != index:
			return _fail("PPU bus event order has a sequence gap at %d." % index)
	return true


func _verify_mutated_pending_queue_rejected() -> bool:
	var runner = _new_runner()
	if runner == null:
		return false
	var first: Dictionary = runner.advance_on_external_nmi(10, 0x88)
	if not bool(first.get("ok", false)):
		return _fail("Mutation case could not construct its source queue: " + runner.error_message)
	var scheduler = runner._scheduler
	scheduler._ram[0x04A5] = int(scheduler._ram[0x04A5]) ^ 0x01
	var rejected: Dictionary = runner.advance_on_external_nmi(11, 0x88)
	if bool(rejected.get("ok", true)) \
			or not String(rejected.get("error", "")).contains("Pending source `$0515/$04A5` queue changed") \
			or int(runner.get_status().get("last_external_nmi_frame", -1)) != 10:
		return _fail("A mutated pending queue was accepted or consumed as the second NMI input.")
	return true


func _new_runner() -> Variant:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		_fail("Fresh-route context source setup failed: " + builder.error_message)
		return null
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		_fail("Fresh-route context derivation failed: " + builder.error_message)
		return null
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		_fail("Production route source setup failed: " + runner.error_message)
		return null
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) \
			or String(begin.get("last_source_boundary", "")) != "$EB8B":
		_fail("Production route did not begin at slot-$09 `$EB8B`: " + runner.error_message)
		return null
	return runner


func _fail(message: String) -> bool:
	push_error(message)
	return false
