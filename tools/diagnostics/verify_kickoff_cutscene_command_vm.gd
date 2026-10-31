extends SceneTree

const VmScript = preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const MANIFEST_PATHS := {
	1: "res://assets/gameplay/rom_logic/kickoff_cutscene_01_events.json",
	2: "res://assets/gameplay/rom_logic/kickoff_cutscene_02_events.json",
}

var _failure_count := 0


func _initialize() -> void:
	_verify_cutscene(1)
	_verify_cutscene(2)
	if _failure_count == 0:
		print("PASS: KICK OFF command VM source boundaries, waits, text cadence and FF stop")
		print("LIMIT: source scheduler ticks are modeled; CPU-cycle, PPU-pixel and raster phase are unresolved")
		quit(0)
	else:
		printerr("FAIL: %d KICK OFF command VM assertion(s)" % _failure_count)
		quit(1)


func _verify_cutscene(cutscene_id: int) -> void:
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATHS[cutscene_id]))
	_check(manifest_variant is Dictionary, "cutscene %d manifest JSON" % cutscene_id)
	if not manifest_variant is Dictionary:
		return
	var manifest: Dictionary = manifest_variant
	var expected_events: Array = manifest["events"]
	_verify_rejections(cutscene_id, manifest)
	var vm = VmScript.new()
	root.add_child(vm)
	var emitted_indices: Array[int] = []
	var emitted_addresses: Array[int] = []
	var event_dispatch_ticks: Array[int] = []
	var emitted_glyphs_by_event: Dictionary = {}
	var wait_records: Array[Dictionary] = []
	var completed_wait_records: Array[Dictionary] = []
	var screen_fade_levels: Dictionary = {}
	var completed_screen_off_events: Array[int] = []
	var checked_eb_hold := false
	var first_eb_event := [-1]
	var finish_counter := [0]
	var vm_error_text := [""]

	vm.presenter_event.connect(func(event: Dictionary) -> void:
		emitted_indices.append(int(event["event_index"]))
		emitted_addresses.append(int(event["cpu_address"]))
		event_dispatch_ticks.append(vm.scheduler_tick_index)
	)
	vm.text_glyph_requested.connect(func(tile_id: int, _cpu: int, event_index: int, glyph_index: int) -> void:
		if not emitted_glyphs_by_event.has(event_index):
			emitted_glyphs_by_event[event_index] = []
		emitted_glyphs_by_event[event_index].append([glyph_index, tile_id])
	)
	vm.wait_started.connect(func(kind: String, ticks: int, event: Dictionary) -> void:
		wait_records.append({"kind": kind, "ticks": ticks, "event_index": int(event["event_index"]), "tick_start": vm.scheduler_tick_index})
		if kind == "wait_for_input" and first_eb_event[0] < 0:
			first_eb_event[0] = int(event["event_index"])
	)
	vm.wait_completed.connect(func(kind: String, event: Dictionary) -> void:
		completed_wait_records.append({"kind": kind, "event_index": int(event["event_index"]), "tick_end": vm.scheduler_tick_index})
	)
	vm.screen_fade_palette_step_requested.connect(func(event: Dictionary, level: int) -> void:
		var event_index := int(event["event_index"])
		if not screen_fade_levels.has(event_index):
			screen_fade_levels[event_index] = []
		(screen_fade_levels[event_index] as Array).append(level)
	)
	vm.screen_off_clear_completed.connect(func(event: Dictionary) -> void:
		completed_screen_off_events.append(int(event["event_index"]))
	)
	vm.cutscene_finished.connect(func(_id: int) -> void:
		finish_counter[0] += 1
	)
	vm.vm_error.connect(func(message: String) -> void:
		vm_error_text[0] = message
	)

	_check(vm.start_cutscene(cutscene_id), "cutscene %d VM starts and validates" % cutscene_id)
	_check(vm.text_speed == 8, "cutscene %d starts with route-observed text speed $55=8" % cutscene_id)
	var source_tick_budget := 100000
	while vm.is_running() and source_tick_budget > 0:
		source_tick_budget -= 1
		if vm.state == VmScript.RunState.WAITING_INPUT:
			if not checked_eb_hold:
				var before_count := emitted_indices.size()
				for _hold_tick in 3:
					vm.advance_scheduler_tick(0)
				_check(vm.state == VmScript.RunState.WAITING_INPUT, "cutscene %d EB remains blocked without fresh A" % cutscene_id)
				_check(emitted_indices.size() == before_count, "cutscene %d EB does not advance command stream without A" % cutscene_id)
				checked_eb_hold = true
			vm.advance_scheduler_tick(0x80)
		else:
			vm.advance_scheduler_tick(0)

	_check(source_tick_budget > 0, "cutscene %d terminates within bounded scheduler replay" % cutscene_id)
	_check(vm.state == VmScript.RunState.FINISHED, "cutscene %d reaches FF finish" % cutscene_id)
	_check(finish_counter[0] == 1, "cutscene %d emits one finish at FF" % cutscene_id)
	_check(vm_error_text[0].is_empty(), "cutscene %d has no runtime error" % cutscene_id)
	_check(emitted_indices.size() == expected_events.size(), "cutscene %d emits every decoded event once" % cutscene_id)
	_check(event_dispatch_ticks.size() == expected_events.size(), "cutscene %d records every event's scheduler boundary" % cutscene_id)
	if emitted_indices.size() == expected_events.size():
		for event_index in expected_events.size():
			_check(emitted_indices[event_index] == event_index, "cutscene %d event order at %d" % [cutscene_id, event_index])
			_check(emitted_addresses[event_index] == int(expected_events[event_index]["cpu_address"]), "cutscene %d source address at %d" % [cutscene_id, event_index])
	for left in emitted_addresses.size() - 1:
		_check(emitted_addresses[left + 1] > emitted_addresses[left], "cutscene %d source addresses increase" % cutscene_id)

	var expected_glyph_event_count := 0
	for expected_event in expected_events:
		if str(expected_event["kind"]) == "text_tile_ids":
			expected_glyph_event_count += 1
			var event_index := int(expected_event["event_index"])
			var glyph_records: Array = emitted_glyphs_by_event.get(event_index, [])
			var expected_tiles: Array = expected_event["tile_ids"]
			_check(glyph_records.size() == expected_tiles.size(), "cutscene %d text glyph count at event %d" % [cutscene_id, event_index])
			for glyph_index in mini(glyph_records.size(), expected_tiles.size()):
				_check(glyph_records[glyph_index][0] == glyph_index and glyph_records[glyph_index][1] == expected_tiles[glyph_index], "cutscene %d text glyph byte at event %d/%d" % [cutscene_id, event_index, glyph_index])
	_check(emitted_glyphs_by_event.size() == expected_glyph_event_count, "cutscene %d forwards every text run as source glyph bytes" % cutscene_id)
	_check(wait_records.size() == completed_wait_records.size(), "cutscene %d completes every started wait" % cutscene_id)
	for wait_index in mini(wait_records.size(), completed_wait_records.size()):
		var started: Dictionary = wait_records[wait_index]
		var completed: Dictionary = completed_wait_records[wait_index]
		_check(started["kind"] == completed["kind"] and started["event_index"] == completed["event_index"], "cutscene %d wait order at %d" % [cutscene_id, wait_index])
		var elapsed_ticks := int(completed["tick_end"]) - int(started["tick_start"])
		var expected_ticks := int(started["ticks"])
		if started["kind"] == "wait_for_input":
			expected_ticks = 1
			if int(started["event_index"]) == int(first_eb_event[0]):
				expected_ticks = 4 # Three no-input polls, then the diagnostic's fresh A edge.
		_check(elapsed_ticks == expected_ticks, "cutscene %d %s duration at event %d is %d ticks" % [cutscene_id, started["kind"], started["event_index"], expected_ticks])
		var event_index := int(started["event_index"])
		var next_event_index := event_index + 1
		var is_final_text_wait: bool = started["kind"] == "text_speed" and (wait_index + 1 == wait_records.size() or int(wait_records[wait_index + 1]["event_index"]) != event_index)
		var later_wait_for_same_event := false
		for later_wait_index in range(wait_index + 1, wait_records.size()):
			if int(wait_records[later_wait_index]["event_index"]) == event_index:
				later_wait_for_same_event = true
				break
		if not later_wait_for_same_event and (started["kind"] != "text_speed" or is_final_text_wait) and next_event_index < event_dispatch_ticks.size():
			_check(event_dispatch_ticks[next_event_index] == int(completed["tick_end"]), "cutscene %d source byte boundary after event %d" % [cutscene_id, event_index])

	var expected_screen_on_events: Array[int] = []
	var expected_screen_off_events: Array[int] = []
	var expected_fade_levels: Dictionary = {}
	var model_palette_level := 0
	for event_variant in expected_events:
		if not event_variant is Dictionary:
			continue
		var kind := str(event_variant.get("kind", ""))
		var event_index := int(event_variant.get("event_index", -1))
		var expected_levels: Array[int] = []
		if kind == "screen_on":
			expected_screen_on_events.append(event_index)
			while model_palette_level < 15:
				model_palette_level += 1
				expected_levels.append(model_palette_level)
		if kind == "screen_off_clear":
			expected_screen_off_events.append(event_index)
			while model_palette_level > 0:
				model_palette_level -= 1
				expected_levels.append(model_palette_level)
		if kind == "screen_on" or kind == "screen_off_clear":
			expected_fade_levels[event_index] = expected_levels
	var pre_wait_count := 0
	var fade_wait_count := 0
	var off_pre_wait_count := 0
	var fade_down_wait_count := 0
	for wait in wait_records:
		if wait["kind"] == "screen_on_pre_wait":
			pre_wait_count += 1
		elif wait["kind"] == "screen_on_fade_up":
			fade_wait_count += 1
		elif wait["kind"] == "screen_off_pre_wait":
			off_pre_wait_count += 1
		elif wait["kind"] == "screen_off_fade_down":
			fade_down_wait_count += 1
	_check(pre_wait_count == expected_screen_on_events.size(), "cutscene %d E9 handler runs one source $02 pre-wait per event" % cutscene_id)
	_check(fade_wait_count == expected_fade_wait_count(expected_fade_levels, expected_screen_on_events), "cutscene %d E9 handler yields once per modeled fade-up pass" % cutscene_id)
	_check(off_pre_wait_count == expected_screen_off_events.size(), "cutscene %d EA handler runs one source pre-wait per event" % cutscene_id)
	_check(fade_down_wait_count == expected_fade_wait_count(expected_fade_levels, expected_screen_off_events), "cutscene %d EA handler yields once per modeled fade-down pass" % cutscene_id)
	_check(completed_screen_off_events == expected_screen_off_events, "cutscene %d EA clear follows its complete source fade-down" % cutscene_id)
	for event_index in expected_fade_levels:
		var actual_levels: Array = screen_fade_levels.get(event_index, [])
		_check(actual_levels == expected_fade_levels[event_index], "cutscene %d fade event %d follows its ROM-derived palette levels" % [cutscene_id, event_index])

	_check(_has_wait(wait_records, "compact_pause", 80, 3) if cutscene_id == 1 else _has_wait(wait_records, "compact_pause"), "cutscene %d executes compact D8-DF waits" % cutscene_id)
	_check(_has_wait(wait_records, "text_speed", 8, 7) if cutscene_id == 1 else _has_wait(wait_records, "text_speed", 8), "cutscene %d applies text-speed delays as scheduler ticks" % cutscene_id)
	_check(_has_wait(wait_records, "fc_handler", 4), "cutscene %d executes FC as four scheduler ticks" % cutscene_id)
	_check(_has_wait(wait_records, "screen_on_pre_wait", 2), "cutscene %d executes E9's two-tick source pre-wait" % cutscene_id)
	_check(_has_wait(wait_records, "screen_on_fade_up", 1), "cutscene %d executes E9's one-tick palette-fade yields" % cutscene_id)
	if not expected_screen_off_events.is_empty():
		_check(_has_wait(wait_records, "screen_off_pre_wait", 1), "cutscene %d executes EA's one-tick source pre-wait" % cutscene_id)
		_check(_has_wait(wait_records, "screen_off_fade_down", 1), "cutscene %d executes EA's one-tick palette-fade yields" % cutscene_id)
	_check(_has_wait(wait_records, "wait_for_input", -1), "cutscene %d executes EB as indefinite fresh-A wait" % cutscene_id)
	if cutscene_id == 1:
		_check(_has_wait(wait_records, "pause_frames", 1), "cutscene 1 executes F6 01")
		_check(_has_wait(wait_records, "pause_frames", 6), "cutscene 1 executes F6 06")
	else:
		_check(_has_wait(wait_records, "pause_frames", 180), "cutscene 2 executes F6 B4 as 180 scheduler ticks")
		_check(checked_eb_hold, "cutscene 2 has a replayed EB hold check")

	print("cutscene %d: %d decoded events, %d scheduler ticks, %d waits, %d text runs" % [cutscene_id, emitted_indices.size(), vm.scheduler_tick_index, wait_records.size(), expected_glyph_event_count])
	vm.queue_free()


func expected_fade_wait_count(expected_levels: Dictionary, event_indices: Array[int]) -> int:
	var count := 0
	for event_index in event_indices:
		count += (expected_levels[event_index] as Array).size()
	return count


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failure_count += 1
		printerr("FAIL: " + label)


func _has_wait(waits: Array[Dictionary], kind: String, ticks: int = -999, event_index: int = -1) -> bool:
	for wait in waits:
		if wait["kind"] != kind:
			continue
		if ticks != -999 and int(wait["ticks"]) != ticks:
			continue
		if event_index >= 0 and int(wait["event_index"]) != event_index:
			continue
		return true
	return false


func _verify_rejections(cutscene_id: int, manifest: Dictionary) -> void:
	var bad_hash_manifest := manifest.duplicate(true)
	bad_hash_manifest["source_execution_stream_sha256"] = "0".repeat(64)
	var hash_vm = VmScript.new()
	root.add_child(hash_vm)
	var hash_result: Variant = hash_vm.call("_validate_manifest", cutscene_id, bad_hash_manifest)
	_check(hash_result is Array and hash_result.is_empty() and hash_vm.state == VmScript.RunState.FAILED, "cutscene %d rejects execution-stream hash mismatch" % cutscene_id)
	hash_vm.queue_free()

	var unknown_manifest := manifest.duplicate(true)
	unknown_manifest["events"][0]["kind"] = "unknown_opcode_kind"
	var unknown_vm = VmScript.new()
	root.add_child(unknown_vm)
	var unknown_result: Variant = unknown_vm.call("_validate_manifest", cutscene_id, unknown_manifest)
	_check(unknown_result is Array and unknown_result.is_empty() and unknown_vm.state == VmScript.RunState.FAILED, "cutscene %d rejects unknown event kinds" % cutscene_id)
	unknown_vm.queue_free()
