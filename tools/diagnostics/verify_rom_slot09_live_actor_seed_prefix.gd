extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_ED15_FIELDS: Array[int] = [0x02, 0x3A, 0x02, 0x3C, 0x2C, 0x8F, 0x73, 0x00]
const EXPECTED_SCENARIO_WAIT_SHA256 := "6a8872b8888dab2fa3ab8ed9dcb76236a6616d2d727f7174a5ed0af57bcb5ad8"


func _init() -> void:
	var ok := await _verify_live_route()
	quit(0 if ok else 1)


func _verify_live_route() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh KICK OFF context setup failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Fresh KICK OFF context could not be derived from ROM sources: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Production source-route setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Production route did not begin from the expected ROM-derived context.")

	# Continue authentic source-selected tasks and externally supplied NMI edges.
	# When live scheduler RAM identifies the target slot-$09 callback, execute
	# only that checked caller prefix and stop at its verified `$86F8` vector.
	for _step in range(96):
		var state: Dictionary = runner.get_status()
		var phase := String(state.get("phase", ""))
		var slot := int(state.get("pending_selected_task_slot", -1))
		var route_result: Dictionary = {}
		if phase == "awaiting_external_nmi":
			var frame := int(state.get("last_external_nmi_frame", -1)) + 1
			route_result = runner.advance_on_external_nmi(frame, 0x88)
		elif slot == 0x05 and phase == "stopped_at_slot05_descriptor01_next_row_boundary":
			route_result = runner.resume_slot05_descriptor01_ee_row00()
			if bool(route_result.get("ok", false)):
				route_result = runner.save_slot05_ee_row_yield_and_scan()
		elif slot == 0x05:
			route_result = runner.resume_selected_slot05_worker()
		elif slot == 0x09:
			var live_slot09: Dictionary = runner._scheduler.get_task_boundary_snapshot(0x09)
			var live_ram: PackedByteArray = live_slot09.get("ram_image", PackedByteArray())
			if live_ram.size() == 0x800 and int(live_ram[0x0516]) == 0x51 \
					and int(live_ram[0x0518]) == 0x35 and int(live_ram[0x0519]) == 0x00:
				return _run_live_actor_seed_prefix(runner, live_slot09)
			route_result = runner.resume_selected_slot09_worker()
		elif slot == 0x11:
			route_result = runner.resume_selected_slot11_worker()
		elif slot == 0x15:
			route_result = runner.resume_selected_slot15_source_task()
		else:
			return _fail("Route stopped before a live slot-$09 `$0516=$51` boundary: %s" % str({
				"phase": phase, "slot": slot, "boundary": state.get("source_boundary", "")}))
		if not bool(route_result.get("ok", false)):
			return _fail("Production route failed while following its live source boundary: " + runner.error_message)
	return _fail("Production route did not reach the live slot-$09 `$0516=$51` boundary within 96 bounded source/NMI transitions.")


func _run_live_actor_seed_prefix(runner, live_slot09: Dictionary) -> bool:
	var scheduler = runner._scheduler
	var selected_boundary: Dictionary = runner._pending_selected_task_boundary
	var selected_mapper: Dictionary = runner._pending_selected_task_mapper
	if live_slot09 != selected_boundary \
			or int(live_slot09.get("slot_base", -1)) != 0x09 \
			or int(live_slot09.get("pc", -1)) != 0xCB0F \
			or int(live_slot09.get("phase", -1)) != 3 \
			or int(live_slot09.get("pending_resume", -1)) != 2 \
			or int(live_slot09.get("ready_delay", -1)) != 0 \
			or live_slot09.get("record", PackedByteArray()) != PackedByteArray([0x00, 0x76, 0x18, 0x19]) \
			or selected_mapper.get("bank_low", -1) != 0x18 \
			or selected_mapper.get("bank_high", -1) != 0x19 \
			or selected_mapper.get("select", -1) != 0x07:
		return _fail("The `$0516=$51` bytes are not on the fresh scheduler-selected slot-$09 `$CB0F` boundary.")
	var dispatch: Dictionary = scheduler.dispatch_pending_task(0x09)
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != 0xEB8B \
			or String(dispatch.get("resume_path", "")) != "yielded_rts":
		return _fail("Source scheduler failed to restore the selected slot-$09 `$EB8B` caller.")
	var dispatch_boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x09)
	var dispatch_ram: PackedByteArray = dispatch_boundary.get("ram_image", PackedByteArray())
	var dispatch_stack: PackedByteArray = dispatch_boundary.get("stack_page", PackedByteArray())
	if dispatch_ram.size() != 0x800 or dispatch_stack.size() != 0x100:
		return _fail("The live slot-$09 dispatch lacks full source RAM/stack images.")
	var mapper := selected_mapper.duplicate(true)
	mapper["bank_low"] = int(dispatch.get("bank_low", -1))
	mapper["bank_high"] = int(dispatch.get("bank_high", -1))
	mapper["select"] = (int(dispatch_ram[0x0022]) | 0x07) & 0x07
	var source_dispatch := dispatch.duplicate(true)
	source_dispatch["rom_sha256"] = ROM_SHA256
	source_dispatch["mapper"] = mapper
	source_dispatch["p"] = int(dispatch_boundary.get("p", 0))
	source_dispatch["p_known_mask"] = int(dispatch_boundary.get("p_known_mask", 0))
	source_dispatch["ram_image"] = dispatch_ram
	source_dispatch["stack_page"] = dispatch_stack
	source_dispatch["task_record"] = dispatch_boundary.get("record", PackedByteArray())
	var prefix_executor = runner._slot09_continuation_prefix
	var prefix: Dictionary = prefix_executor.execute_from_next_task_dispatch(source_dispatch)
	if not bool(prefix.get("ok", false)) \
			or String(prefix.get("status", "")) != "slot09_actor_worker_seed_ready_before_cae7":
		return _fail("ROM source prefix did not reach `$ED15` from the live `$EB8B` dispatch: %s" % str({
			"status": prefix.get("status"), "pc": prefix.get("exit_pc"), "error": prefix.get("reason")}))
	if not scheduler.adopt_slot09_actor_seed_caller_prefix(prefix):
		return _fail("Scheduler rejected the source-derived `$ED15` caller prefix: " + scheduler.error_message)
	var request: Dictionary = prefix.get("actor_worker_seed_request", {})
	var seed: Dictionary = scheduler.seed_slot11_actor_worker_from_source_request(request)
	if not bool(seed.get("ok", false)) or String(seed.get("status", "")) != "slot11_seeded_caller_returned_ed2d":
		return _fail("Scheduler rejected the source-derived `$ED15->$CAE7->$ED2D` seed: " + scheduler.error_message)
	var parent_after_seed: Dictionary = scheduler.get_task_boundary_snapshot(0x09)
	var resumed: Dictionary = prefix_executor.resume_after_actor_worker_seed(parent_after_seed)
	if not bool(resumed.get("ok", false)) or int(resumed.get("exit_pc", -1)) != 0x86F8:
		return _fail("ROM caller could not continue from `$ED2D` to `$86F8`: " + String(resumed.get("error", prefix_executor.error_message)))
	if not scheduler.adopt_slot09_after_actor_seed_continuation(resumed):
		return _fail("Scheduler rejected the checked `$ED2D->$86F8` continuation: " + scheduler.error_message)
	return _verify_actor_seed_result(prefix, seed, resumed)


func _verify_actor_seed_result(prefix: Dictionary, seed: Dictionary, resumed: Dictionary) -> bool:
	var registers: Dictionary = prefix.get("registers", {})
	var mapper: Dictionary = prefix.get("mapper", {})
	var request: Dictionary = prefix.get("actor_worker_seed_request", {})
	var ram: PackedByteArray = prefix.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = prefix.get("stack_page", PackedByteArray())
	var request_registers: Dictionary = request.get("entry_registers", {})
	var request_mapper: Dictionary = request.get("mapper", {})
	var request_ram: PackedByteArray = request.get("ram_image", PackedByteArray())
	var request_stack: PackedByteArray = request.get("stack_page", PackedByteArray())
	var source_hashes: Dictionary = prefix.get("source_span_hashes", {})
	var expected_writes := [
		{"pc": 0xED08, "address": 0x000D, "value": 0, "kind": "ram"},
		{"pc": 0xED0A, "address": 0x000E, "value": 0, "kind": "ram"},
	]
	var writes: Array = prefix.get("writes", [])
	var scratch_writes_found: Array[Dictionary] = []
	for write_variant in writes:
		if write_variant is Dictionary and int((write_variant as Dictionary).get("pc", -1)) in [0xED08, 0xED0A]:
			scratch_writes_found.append(write_variant)
	if String(prefix.get("status", "")) != "slot09_actor_worker_seed_ready_before_cae7" \
			or String(prefix.get("rom_sha256", "")) != ROM_SHA256 \
			or String(prefix.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or int(prefix.get("entry_pc", -1)) != 0xEB8B \
			or int(prefix.get("exit_pc", -1)) != 0xED15 \
			or int(prefix.get("active_slot", -1)) != 0x09 \
			or bool(prefix.get("fixture_only", true)) \
			or bool(prefix.get("trace_state_used", true)) \
			or int(registers.get("pc", -1)) != 0xED15 \
			or int(registers.get("a", -1)) != 0x73 \
			or int(registers.get("x", -1)) != 0x02 \
			or int(registers.get("y", -1)) != 0xE4 \
			or int(registers.get("sp", -1)) != 0x78 \
			or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != 0x0C \
			or ram.size() != 0x800 or stack.size() != 0x100 \
			or int(ram[0x0000]) != 0x09 \
			or int(ram[0x0516]) != 0x01 or int(ram[0x0518]) != 0x35 \
			or int(ram[0x0519]) != 0x02 or int(ram[0x0529]) != 0x73 \
			or int(ram[0x05CE]) != 0x00 \
			or int(ram[0x0526]) != 0x3C or int(ram[0x0490]) != 0x3C \
			or int(ram[0x0491]) != 0x2C \
			or String(request.get("schema", "")) != "rom-slot11-actor-seed-request-v1" \
			or String(request.get("source_manifest", "")) != String(prefix.get("source_manifest", "")) \
			or request.get("source_span_hashes", {}) != source_hashes \
			or String(request.get("source_sha256", "")) != "61ef48dd58901f95f2c20f7f4a8bc1bb850221cb403f6bfbd52a65a12e33f551" \
			or String(request.get("helper_sha256", "")) != "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55" \
			or int(request.get("source_pc", -1)) != 0xED15 \
			or int(request.get("call_pc", -1)) != 0xED2A \
			or int(request.get("return_pc", -1)) != 0xED2D \
			or int(request.get("active_slot", -1)) != 0x09 \
			or int(request.get("actor_parameter", -1)) != 0x73 \
			or int(request.get("a", -1)) != 0x73 \
			or bool(request.get("trace_state_used", true)) \
			or bool(request.get("fixture_only", true)) \
			or request_registers != registers or request_mapper != mapper \
			or request_ram != ram or request_stack != stack \
			or scratch_writes_found != expected_writes:
		return _fail("The live `$ED15` result or slot-$11 seed request differs from its source contract: %s" % str({
			"registers": registers, "mapper": mapper, "request": request,
			"scratch_writes": scratch_writes_found}))
	if Array(ram.slice(0x0523, 0x052B)) != EXPECTED_ED15_FIELDS:
		return _fail("The scenario event bytes changed before the `$ED15` seed callsite.")
	var saw_wait_span := false
	for span_variant in prefix.get("source_spans", []):
		if span_variant is Dictionary and String((span_variant as Dictionary).get("file", "")) == "fixed_scenario_wait_handler_ED5B_ED84.bin" \
				and String((span_variant as Dictionary).get("sha256", "")) == EXPECTED_SCENARIO_WAIT_SHA256:
			saw_wait_span = true
	if not saw_wait_span or source_hashes.get("fixed_scenario_wait_handler_ED5B_ED84.bin", "") != EXPECTED_SCENARIO_WAIT_SHA256:
		return _fail("The fail-closed `$ED5B` source span/hash is missing from this result.")
	var parent_return: Dictionary = seed.get("slot09_post_return_boundary", {})
	if String(seed.get("status", "")) != "slot11_seeded_caller_returned_ed2d" \
			or int(parent_return.get("pc", -1)) != 0xED2D \
			or String(resumed.get("status", "")) != "slot09_actor_seed_continuation_to_worker_vector" \
			or int(resumed.get("entry_pc", -1)) != 0xED2D \
			or int(resumed.get("exit_pc", -1)) != 0x86F8 \
			or int(resumed.get("active_slot", -1)) != 0x09 \
			or bool(resumed.get("fixture_only", true)) \
			or bool(resumed.get("worker_body_executed", true)) \
			or bool(resumed.get("worker_body_bytes_read", true)):
		return _fail("The source `$CAE7` request, parent return, or `$86F8` stop contract failed: %s" % str({
			"seed": seed.get("status"), "parent_return": parent_return.get("pc"),
			"resumed": resumed.get("exit_pc")}))
	print("PASS: production route reached the authentic slot-$09 `$0516=$51` boundary and derived a non-fixture `$ED15` request from ROM bytes.")
	print("PASS: scheduler source seed returned the parent to `$ED2D`; ROM caller continued to `$86F8` and stopped before worker-body execution.")
	print("LIMIT: the next nonzero `$0519` route is explicitly bounded at `$ED5B` before its handler executes. No visible-output, audio, or cycle-timing parity is claimed.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
