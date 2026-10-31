extends SceneTree

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	var vm_error := [""]
	route.vm.vm_error.connect(func(message: String) -> void: vm_error[0] = message)

	# Reach the KICK OFF cutscene through the route's visible menus.
	route.call("_unhandled_input", _key(KEY_SHIFT))
	route.call("_advance_route_source_tick")
	_check(route.get_route_status().get("stage", "") == "matchup_presentation", "ID 1 Select reaches matchup presentation")
	route.call("_unhandled_input", _key(KEY_Z))
	route.call("_unhandled_input", _key_up(KEY_Z))
	_check(route.get_route_status().get("stage", "") == "meeting_scene", "A enters ROM scene $44")
	for _tick in 8:
		route.call("_advance_route_source_tick")
	_check(route.get_route_status().get("stage", "") == "meeting_menu", "scene $44 opens the MEETING menu")
	var meeting_input: Node = route.get_node("PreMatchMeetingMenuInput")
	for _row in 3:
		meeting_input.call("handle_input_event", _key(KEY_DOWN))
		route.call("_advance_route_source_tick")
	_check(route.get_route_status().get("meeting_cursor_y", -1) == 0xC8, "three Down edges reach the $06 KICKOFF row")
	meeting_input.call("handle_input_event", _key(KEY_Z))
	route.call("_advance_route_source_tick")
	await process_frame
	_check(route.get_route_status().get("stage", "") == "cutscene_2", "confirming $06 starts ROM cutscene ID 2")

	# The production source runner begins from this route-owned context. The
	# first externally supplied event is an explicitly labeled frame-level NMI
	# abstraction because beam/dot/cycle phase is unavailable.
	route.call("_unhandled_input", _key(KEY_SHIFT))
	route.call("_advance_route_source_tick")
	var status: Dictionary = route.get_route_status()
	_check(status.get("stage", "") == "source_route_waiting_for_nmi", "ID 2 Select starts the ROM source task composition")
	_check(bool(status.get("fresh_match_context", {}).get("ok", false)), "fresh match context is derived from ROM source")
	_check(status.get("initial_player_positions", []).is_empty(), "no post-poll player state is invented")
	var begin: Dictionary = status.get("fresh_source_route_begin", {})
	_check(bool(begin.get("ok", false))
		and String(begin.get("last_source_boundary", "")) == "$EB8B"
		and bool(begin.get("awaiting_external_nmi", false))
		and int(begin.get("ppu_ctrl_shadow", -1)) == 0x88,
		"source route uses the existing fresh-entry context and reaches slot-$09 `$EB8B`")
	_check(int(status.get("fresh_source_route_nmi_abstraction_count", -1)) == 0,
		"beginning the route does not fabricate an NMI event")

	# A gameplay A edge is ignored in this source-runner stage. The next source
	# tick supplies a frame-level NMI abstraction. The decoded route executes
	# the slot-$09 save and waits for the next source-owned NMI boundary.
	route.call("_unhandled_input", _key(KEY_Z))
	route.call("_advance_route_source_tick")
	status = route.get_route_status()
	var nmi_result: Dictionary = status.get("fresh_source_route_nmi", {})
	var call_request: Dictionary = nmi_result.get("slot01_callee_request", {})
	var slot01_dispatch: Dictionary = nmi_result.get("slot01_dispatch", {})
	_check(status.get("stage", "") == "source_route_waiting_for_nmi", "source route waits at the next external NMI boundary after slot `$09` saves")
	_check(int(status.get("fresh_source_route_nmi_abstraction_count", -1)) == 1
		and String(status.get("fresh_source_route_nmi_timing_note", "")).contains("no beam/dot/cycle phase"),
		"route records one explicitly limited frame-level NMI abstraction")
	_check(bool(nmi_result.get("ok", false))
		and String(nmi_result.get("phase", "")) == "awaiting_external_nmi"
		and String(nmi_result.get("last_source_boundary", "")) == "$CB0F save -> scheduler WAIT_FOR_NMI_READY"
		and int(slot01_dispatch.get("pc", -1)) == 0xCA52,
		"source route resumes root slot `$01`, slot `$05`, and slot `$09` through the checked `$CB0F` save")
	_check(String(call_request.get("status", "")) == "call_requested"
		and int(call_request.get("source_pc", -1)) == 0xCA52
		and int(call_request.get("target_cpu_address", -1)) == 0xEE9F
		and int(call_request.get("expected_return_pc", -1)) == 0xCA55
		and not bool(call_request.get("callee_body_executed", true)),
		"caller bytes emit the exact `$EE9F` request")
	var ee9f_result: Dictionary = nmi_result.get("ee9f_result", {})
	var e3ca_request: Dictionary = nmi_result.get("slot01_e3ca_request", {})
	var e3ca_result: Dictionary = nmi_result.get("e3ca_result", {})
	var yield_boundary: Dictionary = nmi_result.get("slot01_yield_result", {})
	var post_root_yield_scan: Dictionary = nmi_result.get("post_root_yield_scan", {})
	var slot05_dispatch: Dictionary = nmi_result.get("slot05_dispatch", {})
	var slot05_resume: Dictionary = nmi_result.get("slot05_resume_result", {})
	var slot05_yield: Dictionary = nmi_result.get("slot05_yield_result", {})
	var post_slot05_scan: Dictionary = nmi_result.get("post_slot05_yield_scan", {})
	var next_task_dispatch: Dictionary = nmi_result.get("next_task_dispatch", {})
	var menu_queue: Dictionary = nmi_result.get("menu_transfer_queue", {})
	var expected_menu_packets := PackedByteArray([
		0x07, 0x21, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x07, 0x41, 0x22, 0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D,
	])
	_check(bool(nmi_result.get("ee9f_body_executed", false))
		and String(ee9f_result.get("status", "")) == "returned_to_source_caller"
		and int(ee9f_result.get("registers", {}).get("pc", -1)) == 0xCA55
		and int(e3ca_request.get("source_pc", -1)) == 0xCA55
		and int(e3ca_request.get("target_cpu_address", -1)) == 0xE3CA
		and int(e3ca_request.get("expected_return_pc", -1)) == 0xCA58
		and bool(nmi_result.get("e3ca_body_executed", false))
		and String(e3ca_result.get("status", "")) == "returned_to_source_caller"
		and int(e3ca_result.get("registers", {}).get("pc", -1)) == 0xCA58
		and int(yield_boundary.get("pc", -1)) == 0xCB0F
		and yield_boundary.get("record", PackedByteArray()) == PackedByteArray([0x01, 0x26, 0x00, 0x01])
		and int(post_root_yield_scan.get("selected_slot_base", -1)) == 0x05
		and int(slot05_dispatch.get("pc", -1)) == 0x8889
		and int(slot05_dispatch.get("sp", -1)) == 0x4A
		and bool(slot05_resume.get("ok", false))
		and String(slot05_resume.get("exit_kind", "")) == "yield_at_c515"
		and int(slot05_resume.get("exit_pc", -1)) == 0xC515
		and slot05_yield.get("record", PackedByteArray()) == PackedByteArray([0x01, 0x46, 0x18, 0x19])
		and int(post_slot05_scan.get("selected_slot_base", -1)) == 0x09
		and int(next_task_dispatch.get("pc", -1)) == 0xEB8B
		and int(menu_queue.get("ready_flag", -1)) == 0x80
		and int(menu_queue.get("progress", -1)) == 0x02
		and menu_queue.get("first_two_packets", PackedByteArray()) == expected_menu_packets
		and bool(nmi_result.get("slot05_worker_resumed", false)),
		"ROM callbacks emit two exact menu-window packets, then yield slot `$05` and dispatch slot `$09` at `$EB8B`")
	var first_save: Dictionary = next_task_dispatch.get("slot09_cb0f_save_result", {})
	_check(String(first_save.get("status", "")) == "slot09_saved_at_cb0f"
		and not next_task_dispatch.get("post_slot09_scan", {}).is_empty(),
		"slot `$09` saves its live state and completes the source scheduler scan")
	_check(int(nmi_result.get("slot09_resume_result", {}).get("exit_pc", -1)) == 0x86F8
		and not bool(nmi_result.get("slot09_resume_result", {}).get("worker_body_bytes_read", true)),
		"slot-$09 reaches the hash-checked `$86F8` worker without reading its bytes")
	_check(int(nmi_result.get("slot09_86f8_worker_result", {}).get("exit_pc", -1)) == 0xEBB3
		and not bool(nmi_result.get("slot09_86f8_worker_result", {}).get("next_worker_bytes_read", true)),
		"the live `$0532=0` worker returns at `$EBB3` before `$8779`")
	_check(not bool(status.get("fresh_source_route_accepts_gameplay_input", true))
		and int(status.get("held_kickoff_input_bits", -1)) == 0,
		"gameplay A/B input is ignored at the source-runner boundary")

	# Gameplay input cannot bypass the source boundary. A second frame tick
	# dispatches the next source-owned NMI and its bounded selected-task chain.
	route.call("_unhandled_input", _key(KEY_X))
	route.call("_unhandled_input", _key(KEY_SHIFT))
	route.call("_advance_route_source_tick")
	status = route.get_route_status()
	var second_nmi: Dictionary = status.get("fresh_source_route_nmi", {})
	var second_nmi_consumer: Dictionary = second_nmi.get("nmi_result", {})
	var second_queue: Dictionary = second_nmi_consumer.get("secondary_queue", {})
	var resumed_task: Dictionary = status.get("fresh_source_route_task", {})
	_check(status.get("stage", "") == "source_route_waiting_for_nmi"
		and int(status.get("fresh_source_route_nmi_abstraction_count", -1)) == 2
		and int(status.get("held_kickoff_input_bits", -1)) == 0,
		"A/B/Select cannot alter the route while two source NMI events are processed")
	_check(bool(second_nmi.get("ok", false))
		and String(second_queue.get("status", "")) == "transferred"
		and second_nmi.get("ppu_bus_events", []).size() == 20
		and not bool(second_nmi.get("ppu_bus_events_applied", true))
		and bool(resumed_task.get("ok", false))
		and String(status.get("fresh_source_route", {}).get("phase", "")) == "awaiting_external_nmi",
		"second NMI consumes the live queue and runs the supported task chain to its next wait")
	_check(not bool(status.get("first_action_menu_complete", true))
		and not bool(status.get("fresh_source_route_accepts_gameplay_input", true)),
		"the route has not fabricated field/menu output or accepted soccer input")
	_check(vm_error[0].is_empty(), "all dispatched ROM cutscene streams validate")

	if _failures == 0:
		print("PASS: KICK OFF route advances two frame-level NMI events through the source-checked slot-$01/$05/$09 task cycle and second-NMI queue consumer.")
		print("LIMIT: PPU bus events are not rendered; full field setup, visible command menu, active-actor state, and beam/cycle timing remain unresolved.")
	else:
		printerr("FAIL: %d source-route assertion(s)" % _failures)
	if is_instance_valid(route.cue_audio):
		route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


func _key(key_code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = true
	return event


func _key_up(key_code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key_code
	event.pressed = false
	return event


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
