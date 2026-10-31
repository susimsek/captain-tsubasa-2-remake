extends SceneTree
## Replays the real recorded KICK OFF route and checks only a root-produced
## `$EC02->$CBF1` call/result. This harness never fabricates helper-entry RAM.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const HELPER_SHA256 := "fc6689183aa19a053b44b44571a373ebb48b3bf940f299fb10623c61da4791ce"
const ROOT_SHA256 := "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917"
const START_FRAME := 4693
const MAX_SOURCE_FRAME := 10000

var _failures := 0
var _root_result: Dictionary = {}
var _helper_executor := RomSlot09Cbf1SoundQueueExecutor.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(_helper_executor.configure_from_project_sources(),
		"consumer and source manifests match the checked ROM spans")
	if not bool(_helper_executor.get_status().get("configured", false)):
		printerr("Helper source configuration error: ", _helper_executor.error_message)
		quit(1)
		return
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	root.add_child(route)
	await process_frame
	route.set_process(false)
	route.source_frame = START_FRAME
	var events := _read_recorded_edges()
	_check(not events.is_empty(), "recorded post-title input edges load")
	for source_frame in range(START_FRAME + 1, MAX_SOURCE_FRAME + 1):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		route.call("_advance_route_source_tick")
		var task_result: Dictionary = route._fresh_source_route_task_result
		var candidate := _find_root_result(task_result)
		if not candidate.is_empty():
			_root_result = candidate
			break
		var source_route: Dictionary = route.get_route_status().get("fresh_source_route", {})
		if String(source_route.get("phase", "")) == "error":
			break
		if events.has(source_frame):
			await process_frame

	_check(not _root_result.is_empty(), "live KICK OFF route reaches the root executor `$CBF1` call/result")
	if not _root_result.is_empty():
		_verify_result(_root_result)
	else:
		var status: Dictionary = route.get_route_status()
		printerr("Route stopped before `$CBF1`: ", JSON.stringify({
			"source_frame": route.source_frame,
			"stage": status.get("stage", ""),
			"source_boundary": status.get("fresh_source_route", {}).get("source_boundary", ""),
			"task_status": status.get("fresh_source_route_task", {}).get("status", ""),
			"task_error": status.get("fresh_source_route_task", {}).get("reason", "")
		}))

	if route.cue_audio != null:
		route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if _failures == 0:
		print("PASS: root-produced `$CBF1` queue helper result is consistent with its ROM call boundary.")
		print("LIMIT: this verifies queue and return-state emulation only; it does not verify APU delivery or audible output.")
	else:
		printerr("FAIL: %d `$CBF1` sound queue assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _verify_result(root_result: Dictionary) -> void:
	_check(bool(root_result.get("ok", false)), "root `$EBD7` executor result succeeds")
	_check(String(root_result.get("rom_sha256", "")) == ROM_SHA256,
		"root result is tied to the supplied ROM hash")
	var source_call_variant: Variant = root_result.get("source_cbf1_call", {})
	var helper_variant: Variant = root_result.get("cbf1_helper_result", {})
	_check(source_call_variant is Dictionary, "root result exposes its nested `$CBF1` call boundary")
	_check(helper_variant is Dictionary, "root result carries the reusable `$CBF1` helper result")
	if not source_call_variant is Dictionary or not helper_variant is Dictionary:
		return
	var source_call: Dictionary = source_call_variant
	var helper: Dictionary = helper_variant
	var request_value := int(source_call.get("registers", {}).get("a", -1))
	var replayed_helper := _helper_executor.execute_from_root_cbf1_call(source_call)
	_check(String(source_call.get("status", "")) == "source_cbf1_call_entry",
		"helper input is the root executor's real call boundary")
	_check(String(source_call.get("source_manifest", "")) ==
		"res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json",
		"helper entry provenance uses the slot-$09 root-source manifest")
	_check(int(source_call.get("caller_pc", -1)) == 0xEC02
		and int(source_call.get("entry_pc", -1)) == 0xCBF1
		and int(source_call.get("return_word", -1)) == 0xEC04
		and int(source_call.get("return_pc", -1)) == 0xEC05,
		"root call and RTS boundary match the ROM bytes")
	_check(bool(helper.get("ok", false)), "ROM-derived queue helper accepts root-produced call state")
	_check(bool(replayed_helper.get("ok", false)),
		"focused consumer replays only the real root-produced call state")
	if not bool(replayed_helper.get("ok", false)):
		printerr("Focused consumer rejected root result: ", String(replayed_helper.get("reason", "")))
		return
	_check(String(helper.get("rom_sha256", "")) == ROM_SHA256
		and String(helper.get("source_span_sha256", "")) == HELPER_SHA256
		and String(helper.get("root_source_span_sha256", "")) == ROOT_SHA256,
		"helper result reports verified source hashes")
	_check(int(helper.get("entry_pc", -1)) == 0xCBF1
		and int(helper.get("rts_pc", -1)) in [0xCBFD, 0xCC01]
		and int(helper.get("return_word", -1)) == 0xEC04
		and int(helper.get("return_pc", -1)) == 0xEC05,
		"helper scans then returns through the root caller's stack frame")
	_check(not bool(helper.get("trace_state_used", true))
		and not bool(helper.get("ppu_apu_effects_applied", true))
		and not bool(helper.get("runtime_rom_dependency", true)),
		"helper result uses no trace state, PPU/APU effects, or runtime ROM dependency")

	var source_ram_variant: Variant = source_call.get("ram_image", PackedByteArray())
	var output_ram_variant: Variant = helper.get("ram_image", PackedByteArray())
	var source_stack_variant: Variant = source_call.get("stack_page", PackedByteArray())
	var output_stack_variant: Variant = helper.get("stack_page", PackedByteArray())
	_check(source_ram_variant is PackedByteArray and output_ram_variant is PackedByteArray,
		"root and helper results carry complete RAM images")
	_check(source_stack_variant is PackedByteArray and output_stack_variant is PackedByteArray,
		"root and helper results carry stack pages")
	if not source_ram_variant is PackedByteArray or not output_ram_variant is PackedByteArray \
			or not source_stack_variant is PackedByteArray or not output_stack_variant is PackedByteArray:
		return
	var source_ram: PackedByteArray = source_ram_variant
	var output_ram: PackedByteArray = output_ram_variant
	var source_stack: PackedByteArray = source_stack_variant
	var output_stack: PackedByteArray = output_stack_variant
	_check(source_ram.size() == 0x800 and output_ram.size() == 0x800,
		"helper receives and returns all NES internal RAM")
	_check(source_stack.size() == 0x100 and output_stack.size() == 0x100,
		"helper receives and returns the full stack page")
	if source_ram.size() != 0x800 or output_ram.size() != 0x800 \
			or source_stack.size() != 0x100 or output_stack.size() != 0x100:
		return
	var input_queue := source_ram.slice(0x0700, 0x0705)
	var output_queue := output_ram.slice(0x0700, 0x0705)
	var queue_before_variant: Variant = helper.get("input_queue", PackedByteArray())
	var queue_after_variant: Variant = helper.get("output_queue", PackedByteArray())
	_check(queue_before_variant is PackedByteArray and queue_after_variant is PackedByteArray,
		"helper reports its queue before and after execution")
	if not queue_before_variant is PackedByteArray or not queue_after_variant is PackedByteArray:
		return
	_check(queue_before_variant == input_queue and queue_after_variant == output_queue,
		"reported queue exactly matches the live root RAM transition")
	_check(replayed_helper.get("output_queue", PackedByteArray()) == queue_after_variant
		and replayed_helper.get("registers", {}) == helper.get("registers", {})
		and replayed_helper.get("memory_writes", []) == helper.get("memory_writes", []),
		"focused replay matches the root result's queue, CPU state, and ordered store")
	var first_empty := -1
	for index in range(5):
		if input_queue[index] == 0:
			first_empty = index
			break
	var expected_queue := input_queue.duplicate()
	if first_empty >= 0:
		expected_queue[first_empty] = request_value
	_check(int(helper.get("queue_index", -2)) == first_empty
		and bool(helper.get("queue_full", false)) == (first_empty < 0)
		and output_queue == expected_queue,
		"helper writes the caller's A value only to the first zero slot, preserving all other queue entries")
	_check(output_ram.slice(0, 0x0700) == source_ram.slice(0, 0x0700)
		and output_ram.slice(0x0705, 0x0800) == source_ram.slice(0x0705, 0x0800),
		"helper leaves all nonqueue RAM unchanged")
	_check(output_stack == source_stack
		and output_ram.slice(0x0100, 0x0200) == source_ram.slice(0x0100, 0x0200),
		"RTS reads the JSR frame without changing stack bytes")
	var memory_writes_variant: Variant = helper.get("memory_writes", [])
	var stack_writes_variant: Variant = helper.get("stack_writes", [])
	_check(memory_writes_variant is Array and stack_writes_variant is Array,
		"helper reports ordered memory and stack effects")
	if memory_writes_variant is Array and stack_writes_variant is Array:
		var memory_writes: Array = memory_writes_variant
		var stack_writes: Array = stack_writes_variant
		_check(memory_writes.size() == (1 if first_empty >= 0 else 0),
			"helper reports the exact store count")
		_check(stack_writes.is_empty(), "RTS itself performs no stack writes")
		if first_empty >= 0 and memory_writes.size() == 1 and memory_writes[0] is Dictionary:
			var write: Dictionary = memory_writes[0]
			_check(int(write.get("pc", -1)) == 0xCBFE
				and int(write.get("address", -1)) == 0x0700 + first_empty
				and int(write.get("value", -1)) == request_value,
				"ordered store effect is the source `$CBFE STA $0700,X`")


func _find_root_result(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var dictionary: Dictionary = value
	if dictionary.has("source_cbf1_call") and dictionary.has("cbf1_helper_result"):
		return dictionary
	for child in dictionary.values():
		var candidate := _find_root_result(child)
		if not candidate.is_empty():
			return candidate
	return {}


func _read_recorded_edges() -> Dictionary:
	var file := FileAccess.open(INPUT_CSV, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	var result: Dictionary = {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		if source_frame <= START_FRAME:
			continue
		var edges: Array[String] = []
		for index in range(2, 10):
			if row[index] == "1":
				edges.append(["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"][index - 2])
		if not edges.is_empty():
			result[source_frame] = edges
	return result


func _dispatch_edges(route: KickoffRouteRuntime, edges: Array) -> void:
	for edge in edges:
		var key_code: Key
		match str(edge):
			"Up": key_code = KEY_UP
			"Down": key_code = KEY_DOWN
			"Left": key_code = KEY_LEFT
			"Right": key_code = KEY_RIGHT
			"A": key_code = KEY_Z
			"B": key_code = KEY_X
			"Select": key_code = KEY_SHIFT
			"Start": continue
			_: continue
		var event := InputEventKey.new()
		event.keycode = key_code
		event.pressed = true
		route.call("_unhandled_input", event)
		var stage := str(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
