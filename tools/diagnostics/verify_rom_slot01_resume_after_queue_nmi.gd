extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	var ok := _verify()
	quit(0 if ok else 1)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh KICK OFF context configuration failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Fresh KICK OFF source context could not be built: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route configuration failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Route did not begin from the expected ROM-derived source context.")

	# Reconstruct the already-verified route to the live slot-$09 NMI wait.
	for frame in [1, 2]:
		var nmi: Dictionary = runner.advance_on_external_nmi(frame, 0x88)
		if not bool(nmi.get("ok", false)):
			return _fail("Initial external NMI %d failed: %s" % [frame, runner.error_message])
	var first_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(first_slot05.get("ok", false)) or int(first_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Initial slot-$05 source worker did not select slot `$09`.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("Initial slot-$09 continuation failed: " + runner.error_message)
	var nmi3: Dictionary = runner.advance_on_external_nmi(3, 0x88)
	if not bool(nmi3.get("ok", false)) or int(nmi3.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 3 did not select slot `$05`.")
	var second_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(second_slot05.get("ok", false)) or int(second_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Second slot-$05 source worker did not select slot `$09`.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("Second slot-$09 continuation failed: " + runner.error_message)
	var nmi4: Dictionary = runner.advance_on_external_nmi(4, 0x88)
	if not bool(nmi4.get("ok", false)) or int(nmi4.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 4 did not select slot `$05`.")
	var slot05_boundary: Dictionary = runner.resume_selected_slot05_worker()
	if String(slot05_boundary.get("status", "")) == "slot05_saved_and_rescanned" \
			and int(slot05_boundary.get("next_selected_task_slot", -1)) == 0x09:
		if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
			return _fail("Intervening slot-$09 continuation failed: " + runner.error_message)
		var nmi5: Dictionary = runner.advance_on_external_nmi(5, 0x88)
		if not bool(nmi5.get("ok", false)) or int(nmi5.get("next_selected_task_slot", -1)) != 0x05:
			return _fail("External NMI 5 did not select slot `$05`.")
		slot05_boundary = runner.resume_selected_slot05_worker()
	if not bool(slot05_boundary.get("ok", false)) \
			or String(slot05_boundary.get("status", "")) != "stopped_at_descriptor01_ee_row_boundary":
		return _fail("Slot `$05` did not reach its supported descriptor row boundary: %s" % str(slot05_boundary))
	var ee_row: Dictionary = runner.resume_slot05_descriptor01_ee_row00()
	if not bool(ee_row.get("ok", false)) \
			or String(ee_row.get("status", "")) != "stopped_after_descriptor01_ee_row00_yield":
		return _fail("Live descriptor `$EE 00 FC` transition failed: " + runner.error_message)
	var slot05_save: Dictionary = runner.save_slot05_ee_row_yield_and_scan()
	if not bool(slot05_save.get("ok", false)) \
			or int(slot05_save.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Slot `$05` save/scan did not select the source slot `$09` task.")
	var slot09_wait: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(slot09_wait.get("ok", false)) \
			or not bool(slot09_wait.get("awaiting_external_nmi", false)):
		return _fail("Slot `$09` did not reach its source-owned NMI wait.")
	return _verify_slot01_cycle(runner)


func _verify_slot01_cycle(runner: Variant) -> bool:
	var scheduler: Variant = runner._scheduler
	var pending: Dictionary = runner.get("_pending_nmi_queue_state")
	var queue_before: Dictionary = scheduler.get_live_nmi_secondary_queue_state()
	if queue_before != pending or String(queue_before.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Live queue is not identical to the slot-$09 producer snapshot.")
	var packets: PackedByteArray = queue_before.get("packet_buffer", PackedByteArray())
	if int(queue_before.get("ram_001b", -1)) != 0 \
			or int(queue_before.get("primary_count_0498", -1)) != 0 \
			or int(queue_before.get("ready_flag_0515", -1)) != 0x80 \
			or packets.slice(0, 20) != PackedByteArray([
				0x07,0xC1,0x22,0x9C,0xA8,0xA8,0xA8,0xA8,0xA8,0x9D,
				0x07,0xE1,0x22,0xAA,0x53,0x41,0x4F,0x00,0x33,0xAB]):
		return _fail("Pending secondary queue bytes or readiness differ from the source packet contract.")
	var prior_frame := int(runner.get_status().get("last_external_nmi_frame", -1))
	var frame_label := prior_frame + 1
	var route: Dictionary = runner.advance_on_external_nmi(frame_label, 0x88)
	var nmi: Dictionary = route.get("nmi_result", {})
	var queue_result: Dictionary = route.get("secondary_queue", {})
	var events: Array = route.get("ppu_bus_events", [])
	var dispatch: Dictionary = route.get("selected_task_dispatch", {})
	var selected: Dictionary = route.get("selected_task_boundary", {})
	var ee9f: Dictionary = route.get("slot01_ee9f_result", {})
	var e3ca: Dictionary = route.get("slot01_e3ca_result", {})
	var saved: Dictionary = route.get("slot01_cb0f_saved_boundary", {})
	var next_scan: Dictionary = route.get("post_root_yield_scan", {})
	var next: Dictionary = route.get("next_selected_task_boundary", {})
	var actor_visits: Array = ee9f.get("actor_visits", [])
	var input_ram: PackedByteArray = selected.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = selected.get("stack_page", PackedByteArray())
	var all_inactive := actor_visits.size() == 6
	for actor_variant in actor_visits:
		if not actor_variant is Dictionary or int((actor_variant as Dictionary).get("flag", -1)) != 0 \
				or not bool((actor_variant as Dictionary).get("inactive", false)):
			all_inactive = false
	if not bool(route.get("ok", false)) \
			or not bool(route.get("external_nmi_consumed", false)) \
			or int(route.get("external_nmi_frame", -1)) != frame_label \
			or not bool(route.get("pending_queue_guard_validated", false)) \
			or String(nmi.get("path", "")) != "fixed_normal" \
			or String(queue_result.get("status", "")) != "transferred" \
			or String(queue_result.get("branch", "")) != "secondary_queue_consumed" \
			or int(queue_result.get("ready_flag_before", -1)) != 0x80 \
			or int(queue_result.get("ready_flag_after", -1)) != 0 \
			or int(queue_result.get("packet_count", -1)) != 2 \
			or events.size() != 20 or not _verify_bus_events(events, packets) \
			or int(route.get("selected_task_slot", -1)) != 0x01 \
			or int(dispatch.get("pc", -1)) != 0xCA52 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("a", -1)) != 0 or int(dispatch.get("x", -1)) != 0 \
			or int(dispatch.get("y", -1)) != 0 or int(dispatch.get("sp", -1)) != 0x2A \
			or int(dispatch.get("bank_low", -1)) != 0 \
			or int(dispatch.get("bank_high", -1)) != 1 \
			or int(selected.get("pc", -1)) != 0xCA52 \
			or input_ram.size() != 0x800 or stack.size() != 0x100 \
			or stack.slice(0x27, 0x2C) != PackedByteArray([0x00,0x00,0x51,0xCA,0x00]) \
			or int(input_ram[0x05FB]) != 0 or (int(input_ram[0x001C]) & 0x0F) != 0 \
			or not all_inactive \
			or String(ee9f.get("status", "")) != "returned_to_source_caller" \
			or int(ee9f.get("entry", {}).get("call_pc", -1)) != 0xCA52 \
			or int(ee9f.get("entry", {}).get("expected_return_pc", -1)) != 0xCA55 \
			or int(e3ca.get("entry", {}).get("call_pc", -1)) != 0xCA55 \
			or int(e3ca.get("entry", {}).get("expected_return_pc", -1)) != 0xCA58 \
			or String(e3ca.get("field_input_branch", "")) != "no_direction" \
			or int(saved.get("pc", -1)) != 0xCB0F \
			or int(saved.get("slot_base", -1)) != 0x01 \
			or saved.get("record", PackedByteArray()) != PackedByteArray([0x01,0x26,0x00,0x01]) \
			or int(next_scan.get("decision", -1)) != 1 \
			or int(route.get("next_selected_task_slot", -1)) != 0x05 \
			or int(next.get("slot_base", -1)) != 0x05 \
			or int(next.get("pc", -1)) != 0xCB0F \
			or int(next.get("active_task_slot", -1)) != -1 \
			or int(next.get("pending_resume", -1)) != 2 \
			or bool(route.get("nmi_cadence_generated", true)) \
			or bool(route.get("ppu_bus_events_applied", true)):
		return _fail("Production slot-$01 continuation or next pre-dispatch boundary differs: %s" % str({
			"error": runner.error_message, "route": route, "actors": actor_visits}))
	var status: Dictionary = runner.get_status()
	if int(status.get("last_external_nmi_frame", -1)) != frame_label \
			or int(status.get("pending_selected_task_slot", -1)) != 0x05 \
			or int(scheduler.get_status().get("active_task_slot", -1)) != -1:
		return _fail("The route did not stop cleanly after its single NMI and next-task selection.")
	print("PASS: one caller-labeled NMI (%d) drained two packets into 20 ordered bus events; no renderer writes were applied." % frame_label)
	print("PASS: slot `$01` dispatch A/X/Y/SP=`00/00/00/2A`, PC `$CA52`, banks `$00/$01`, stack `$0127-$012B`=`%s`." % stack.slice(0x27, 0x2C).hex_encode())
	print("PASS: six actor flags were zero; `$05FB=$00` and `$001C & $0F=$00` drove `$CA52->$EE9F->$CA55->$E3CA->$CA58->$CA4F->$CB0F`.")
	print("STOP: slot `$01` saved record `%s`; scheduler selected slot `$05` record `%s` at `$CB0F` before dispatch." % [
		PackedByteArray(saved.get("record", PackedByteArray())).hex_encode(),
		PackedByteArray(next.get("record", PackedByteArray())).hex_encode()])
	print("LIMIT: this existing runner performs NMI selection and slot-$01 continuation in one call; there is no detached slot-$01 resume API.")
	var slot05_result: Dictionary = runner.resume_selected_slot05_worker()
	var slot05_dispatch: Dictionary = slot05_result.get("slot05_dispatch", {})
	var slot05_worker: Dictionary = slot05_result.get("slot05_worker_result", {})
	var slot05_worker_input: Dictionary = slot05_result.get("slot05_worker_input", {})
	var slot05_input_ram: PackedByteArray = slot05_worker_input.get("ram_image", PackedByteArray())
	var slot05_output_ram: PackedByteArray = slot05_worker.get("ram_image", PackedByteArray())
	var slot05_input_stack: PackedByteArray = slot05_worker_input.get("stack_page", PackedByteArray())
	var slot05_registers: Dictionary = slot05_worker_input.get("registers", {})
	var slot05_mapper: Dictionary = slot05_worker_input.get("mapper", {})
	var blocked: Dictionary = slot05_worker.get("blocked_read", {})
	var live_after_attempt: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var live_ram_after_attempt: PackedByteArray = live_after_attempt.get("ram_image", PackedByteArray())
	print("SLOT-$05 RESUME: ok=%s status=%s reason=%s error=%s dispatch=%s worker_exit=$%04X/%s instructions=%d blocked=%s live_$0629=%s" % [
		str(slot05_result.get("ok", false)), String(slot05_result.get("status", "")),
		String(slot05_result.get("reason", "")), runner.error_message, str({"pc": slot05_dispatch.get("pc"), "a": slot05_dispatch.get("a"),
		"x": slot05_dispatch.get("x"), "y": slot05_dispatch.get("y"), "sp": slot05_dispatch.get("sp"),
		"banks": [slot05_dispatch.get("bank_low"), slot05_dispatch.get("bank_high")],
		"stack": slot05_input_stack.slice(0x40, 0x50).hex_encode(),
		"mapper_select": slot05_mapper.get("select")}),
		int(slot05_worker.get("exit_pc", -1)), String(slot05_worker.get("exit_kind", "")),
		int(slot05_worker.get("instruction_count", -1)),
		str(blocked),
		str([slot05_input_ram[0x0629] if slot05_input_ram.size() > 0x629 else -1,
			slot05_output_ram[0x0629] if slot05_output_ram.size() > 0x629 else -1,
			live_ram_after_attempt[0x0629] if live_ram_after_attempt.size() > 0x629 else -1])])
	print("SLOT-$05 SOURCE STATE: CPU=%s mapper=%s RAM[$003E-$003F,$003C,$0629,$0516,$05F7-$05F8]=%s writes=%d" % [
		str(slot05_registers), str(slot05_mapper), str({
			"003E_003F": slot05_input_ram.slice(0x003E, 0x0040).hex_encode(),
			"003C": slot05_input_ram[0x003C],
			"0629": slot05_input_ram[0x0629],
			"0516": slot05_input_ram[0x0516],
			"05F7_05F8": slot05_input_ram.slice(0x05F7, 0x05F9).hex_encode()}),
		(slot05_worker.get("memory_writes", []) as Array).size()])
	var slot05_writes: Array = slot05_worker.get("memory_writes", [])
	var live_after: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var live_ram_after: PackedByteArray = live_after.get("ram_image", PackedByteArray())
	var scheduler_after: Dictionary = scheduler.get_status()
	if not bool(slot05_result.get("ok", false)) \
			or String(slot05_result.get("status", "")) != "unresolved_source_span" \
			or String(slot05_result.get("phase", "")) != "stopped_before_slot05_worker" \
			or int(slot05_dispatch.get("pc", -1)) != 0x8889 \
			or int(slot05_dispatch.get("a", -1)) != 0x0F \
			or int(slot05_dispatch.get("x", -1)) != 0x0F \
			or int(slot05_dispatch.get("y", -1)) != 0x03 \
			or int(slot05_dispatch.get("sp", -1)) != 0x4A \
			or int(slot05_dispatch.get("bank_low", -1)) != 0x18 \
			or int(slot05_dispatch.get("bank_high", -1)) != 0x19 \
			or String(slot05_dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(slot05_registers.get("pc", -1)) != 0x8889 \
			or int(slot05_registers.get("sp", -1)) != 0x4A \
			or int(slot05_mapper.get("bank_low", -1)) != 0x18 \
			or int(slot05_mapper.get("bank_high", -1)) != 0x19 \
			or int(slot05_mapper.get("select", -1)) != 0x07 \
			or slot05_input_ram.size() != 0x800 \
			or slot05_input_ram.slice(0x003E, 0x0040) != PackedByteArray([0x9C,0xBD]) \
			or int(slot05_input_ram[0x003C]) != 0xB0 \
			or int(slot05_input_ram[0x0629]) != 0 \
			or int(slot05_input_ram[0x0516]) != 0 \
			or slot05_input_ram.slice(0x05F7, 0x05F9) != PackedByteArray([0xB4,0x00]) \
			or slot05_input_stack.size() != 0x100 \
			or slot05_input_stack.slice(0x40, 0x50) != PackedByteArray([
				0x00,0x81,0x8C,0xB9,0x52,0xA8,0x89,0x03,0x0F,0x88,0x88,0x98,0xEF,0x1D,0x1C,0xD0]) \
			or int(slot05_worker.get("exit_pc", -1)) != 0x89A0 \
			or String(slot05_worker.get("exit_kind", "")) != "unresolved_source_span" \
			or int(blocked.get("instruction_pc", -1)) != 0x89A0 \
			or int(blocked.get("requested_address", -1)) != 0xBBE3 \
			or int(blocked.get("bank", -1)) != 0x19 \
			or not String(slot05_result.get("reason", "")).contains("$BBE3") \
			or slot05_writes.size() != 0 \
			or bool(slot05_result.get("slot05_worker_adopted", true)) \
			or live_ram_after != slot05_input_ram \
			or int(live_ram_after[0x0629]) != 0 \
			or int(scheduler_after.get("active_task_slot", -1)) != 0x05:
		return _fail("Slot-$05 did not stop cleanly at the first unsupported BBE3 read: %s" % str({
			"status": slot05_result.get("status"), "phase": slot05_result.get("phase"),
			"reason": slot05_result.get("reason"), "dispatch": slot05_dispatch,
			"registers": slot05_registers, "mapper": slot05_mapper,
			"ram_003e": slot05_input_ram.slice(0x003E, 0x0040).hex_encode(),
			"ram_003c": slot05_input_ram[0x003C] if slot05_input_ram.size() > 0x3C else -1,
			"ram_0629": slot05_input_ram[0x0629] if slot05_input_ram.size() > 0x629 else -1,
			"blocked": blocked, "writes": slot05_writes.size(),
			"live_ram_matches_input": live_ram_after == slot05_input_ram,
			"scheduler": scheduler_after}))
	print("PASS: slot-$05 dispatch restored A/X/Y/SP=0F/0F/03/4A, banks 18/19, selector 07; live $0629=00.")
	print("STOP: worker PC $89A0 needs the unpreserved bank-$19 byte at $BBE3; no worker writes were adopted and scenario $35 was not enqueued.")
	return true


func _verify_bus_events(events: Array, queue: PackedByteArray) -> bool:
	for index in range(events.size()):
		if not events[index] is Dictionary:
			return false
		var event: Dictionary = events[index]
		if int(event.get("sequence", -1)) != index:
			return false
		if index in [0, 10]:
			if String(event.get("operation", "")) != "read" or int(event.get("ppu_register", -1)) != 0x2002:
				return false
		elif index in [1, 11]:
			var high_index := 2 if index == 1 else 12
			if int(event.get("ppu_register", -1)) != 0x2006 or int(event.get("value", -1)) != int(queue[high_index]):
				return false
		elif index in [2, 12]:
			var low_index := 1 if index == 2 else 11
			if int(event.get("ppu_register", -1)) != 0x2006 or int(event.get("value", -1)) != int(queue[low_index]):
				return false
		else:
			var packet_start := 3 if index < 10 else 13
			var queue_index := packet_start + (index - (3 if index < 10 else 13))
			if int(event.get("ppu_register", -1)) != 0x2007 \
					or int(event.get("value", -1)) != int(queue[queue_index]):
				return false
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
