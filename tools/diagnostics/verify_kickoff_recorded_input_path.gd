extends SceneTree
## Replays the captured post-title controller edges through the Godot route.
## Capture files are observations only; the harness does not inject captured
## player, RAM, PPU, or audio state into the runtime path.

const ROUTE_SCENE := preload("res://scenes/kickoff_route_runtime.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const FIRST_ACTION_MENU_INPUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_input.gd")
const INPUT_CSV := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const FIRST_PASS_INPUT_EDGES_CSV := "res://reference/diagnostics/first_pass_action_input_edges_20261110.csv"
const FCEUX_RAM_TRACE_DIR := "res://reference/diagnostics/kickoff_select_test_20261027/ram"
const CUTSCENE_POINTER_AUDIT_FRAMES: Array[int] = [6808, 6943, 6968, 7093, 7096, 7112, 7119]
const POSITION_RAM_ORACLE := "res://reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008593.bin"
const OUTPUT_PNG := "/tmp/ct2_godot_first_action_menu_recorded_input.png"
const ENDPOINT_VIEWPORT_PNG := "/tmp/ct2_godot_first_action_menu_viewport_8953.png"
const FIRST_PASS_DECISION_VIEWPORT_PNG := "/tmp/ct2_godot_first_pass_decision_viewport_9600.png"
const FIRST_PASS_DECISION_FRAME := 9600
const TITLE_HANDOFF_FRAME := 4692
const TITLE_HANDOFF_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const NMI_TRACE_ROOT := "res://reference/diagnostics/kickoff_select_cleanup_counters_20261031_035453_utc/"
const NMI_TRACE_VALIDATION := NMI_TRACE_ROOT + "validation.json"
const NMI_RAM_PASS1 := NMI_TRACE_ROOT + "frame_7266_C421_ram_pass1.bin"
const NMI_RAM_PASS2 := NMI_TRACE_ROOT + "frame_7266_C421_ram_pass2.bin"
const NMI_RAM_SHA256 := "aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0"
const MAP36_BLOCK_MAP_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/block_map_36_selector_01.bin"
const MAP36_BLOCK_MAP_SHA256 := "fe786bcee977d21f7351d0275263ed940942626bdca02ff94c25745ade5998b0"
const MAP36_METATILE_DIR := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/"
const MAP2D_MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot15_callback_34/map_2d_metatiles/manifest.json"
const MAP2D_MANIFEST_SHA256 := "66f9b2ae9e60936d5bda78053ae9d62718c77da108aef3e82a9cefff453457b1"
const MAP2D_BLOCK_MAP_PATH := "res://reference/rom_extract/gameplay/slot15_callback_34/map_2d_block.bin"
const MAP2D_BLOCK_MAP_SHA256 := "5f2a7c9e9b42fa9860e062f8df1ee57caf1d255424d85ff884c6158f1cf8e1e9"
const MAP2D_METATILE_DIR := "res://reference/rom_extract/gameplay/slot15_callback_34/map_2d_metatiles/"

var _failures := 0
var _stage_at_checkpoints: Dictionary = {}
var _frame_7266_c421_ram_reference := PackedByteArray()
var _godot_background_5e_event_frame := -1
var _godot_input_wait_frames: Dictionary = {}
var _godot_initial_cutscene_event_frames: Dictionary = {}
var _slot11_alignment_mismatches: Array[int] = []
var _slot11_alignment_sample_count := 0
var _menu_confirmation_requests: Array[int] = []
var _route_audio_player_events: Array[Dictionary] = []
var _map2d_observed_batches: Array[Dictionary] = []
var _slot11_watch_previous_signature := ""


func _diagnostic_ram_byte(route: KickoffRouteRuntime, address: int) -> int:
	if route._fresh_source_route_runner == null:
		return -1
	var scheduler = route._fresh_source_route_runner._scheduler
	if scheduler == null:
		return -1
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	if not ram is PackedByteArray or (ram as PackedByteArray).size() != 0x800:
		return -1
	return int((ram as PackedByteArray)[address])


func _diagnostic_collect_address_writes(value: Variant, address: int,
		path: String, output: Array[Dictionary], depth: int = 0) -> void:
	if depth > 10 or output.size() >= 16:
		return
	if value is Dictionary:
		var dictionary: Dictionary = value
		for field in ["ram_writes", "source_writes", "writes", "memory_writes"]:
			var records: Variant = dictionary.get(field, [])
			if records is Array:
				for record_variant in records:
					if not record_variant is Dictionary:
						continue
					var record: Dictionary = record_variant
					if int(record.get("address", record.get("addr", -1))) == address:
						output.append({
							"path": path + "." + field,
							"pc": int(record.get("source_pc", record.get("pc", -1))),
							"value": int(record.get("value", record.get("new_value", -1))),
							"kind": String(record.get("kind", "")),
						})
		for key in dictionary.keys():
			var child: Variant = dictionary[key]
			if child is Dictionary or child is Array:
				_diagnostic_collect_address_writes(child, address,
					path + "." + String(key), output, depth + 1)
	elif value is Array:
		for index in range((value as Array).size()):
			var child: Variant = (value as Array)[index]
			if child is Dictionary or child is Array:
				_diagnostic_collect_address_writes(child, address,
					"%s[%d]" % [path, index], output, depth + 1)


func _diagnostic_collect_instruction_hits(value: Variant, addresses: Array[int],
		path: String, output: Array[Dictionary], depth: int = 0) -> void:
	if depth > 10 or output.size() >= 24:
		return
	if value is Dictionary:
		var dictionary: Dictionary = value
		for field in ["source_instruction_pcs", "instruction_pcs"]:
			var pcs: Variant = dictionary.get(field, [])
			if pcs is Array:
				for pc_variant in pcs:
					var pc := int(pc_variant)
					if pc in addresses:
						output.append({"path": path + "." + field, "pc": pc})
		for key in dictionary.keys():
			var child: Variant = dictionary[key]
			if child is Dictionary or child is Array:
				_diagnostic_collect_instruction_hits(child, addresses,
					path + "." + String(key), output, depth + 1)
	elif value is Array:
		for index in range((value as Array).size()):
			var child: Variant = (value as Array)[index]
			if child is Dictionary or child is Array:
				_diagnostic_collect_instruction_hits(child, addresses,
					"%s[%d]" % [path, index], output, depth + 1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, true)
	_verify_frame7266_nmi_ram_reference()
	var title_runtime := MAIN_SCENE.instantiate() as Node
	if title_runtime == null:
		_check(false, "configured title scene loads as the route handoff source")
		quit(1)
		return
	title_runtime.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(title_runtime)
	await process_frame
	var opening_audio := title_runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if opening_audio != null:
		opening_audio.stop()
	var title_presenter := title_runtime.get_node_or_null("SourcePresenter") as ColdStartSourceCommandPresenter
	var title_renderer := title_runtime.get_node_or_null("TitleMenu/TitleBackground")
	var title_fade_counters: Variant = title_presenter.state.get("fade_counters", Vector2i(-1, -1)) \
		if title_presenter != null else Vector2i(-1, -1)
	var title_palette: PackedByteArray = title_renderer.call("get_source_title_palette_bytes") \
		if is_instance_valid(title_renderer) and title_renderer.has_method("get_source_title_palette_bytes") \
		else PackedByteArray()
	_check(typeof(title_fade_counters) == TYPE_VECTOR2I \
		and title_fade_counters == Vector2i(0x0F, 0x0F) and title_palette.size() == 0x20,
		"ROM-derived title presenter supplies the full-brightness KICK OFF handoff state")
	var route := ROUTE_SCENE.instantiate() as KickoffRouteRuntime
	route.action_confirmation_requested.connect(_on_menu_action_confirmation_requested)
	var source_fade := {
		"fade_counters": title_fade_counters,
		"base_palette_bytes": title_palette,
	}
	route.process_mode = Node.PROCESS_MODE_DISABLED
	_check(route.initialize_from_title_handoff(TITLE_HANDOFF_FRAME, TITLE_HANDOFF_ROM_SHA256,
		source_fade, title_renderer),
		"recorded route starts with the production ROM-derived title handoff")
	root.add_child(route)
	await process_frame
	route.set_process(false)
	route.cue_audio.rom_sound_started.connect(_on_route_audio_started)
	route.cue_audio.rom_sound_stopped.connect(_on_route_audio_stopped)
	route.vm.presenter_event.connect(func(event: Dictionary) -> void:
		var kind := str(event.get("kind", ""))
		var event_index := int(event.get("event_index", -1))
		if event_index >= 0 and event_index <= 30:
			_godot_initial_cutscene_event_frames[event_index] = {
				"frame": route.source_frame,
				"pc": int(event.get("cpu_address", -1)),
				"kind": kind,
			}
		if kind == "wait_for_input":
			_godot_input_wait_frames[event_index] = {
				"frame": route.source_frame,
				"pc": int(event.get("cpu_address", -1)),
			}
		elif kind == "background_1" and int(event.get("id", -1)) == 0x5E:
			_godot_background_5e_event_frame = route.source_frame
	)

	var events := _read_recorded_edges()
	_check(not events.is_empty(), "captured route input edges load")
	var expect_scenario36_boundary := OS.get_environment("CT2_ROUTE_EXPECT_SCENARIO36").strip_edges() == "1" \
		or OS.get_environment("CT2_ROUTE_EXPECT_DB0E").strip_edges() == "1" \
		or OS.get_environment("CT2_ROUTE_EXPECT_E6EC").strip_edges() == "1"
	var check_first_pass_input := OS.get_environment("CT2_ROUTE_CHECK_FIRST_PASS_INPUT").strip_edges() == "1"
	var stop_frame := -1
	var stop_route_status: Dictionary = {}
	var stopped_at_handoff_gap := false
	var stopped_at_preset_wait := false
	var stopped_at_a503_text_setup := false
	var stopped_at_a503_wait_loop := false
	var stopped_at_811f := false
	var stopped_at_812f := false
	var stopped_at_a64c := false
	var stop_at_811f := OS.get_environment("CT2_ROUTE_STOP_AT_811F").strip_edges() == "1"
	var configured_final_frame := OS.get_environment("CT2_ROUTE_FINAL_FRAME").strip_edges()
	var default_final_frame := 9045 if check_first_pass_input else (8593 if expect_scenario36_boundary else 9042)
	var final_frame := int(configured_final_frame) if not configured_final_frame.is_empty() else default_final_frame
	var final_slot05: Dictionary = {}
	var checkpoint_out := OS.get_environment("CT2_ROUTE_CHECKPOINT_OUT").strip_edges()
	var checkpoint_pc_text := OS.get_environment("CT2_ROUTE_CHECKPOINT_PC").strip_edges()
	var checkpoint_pc := int(checkpoint_pc_text) if not checkpoint_pc_text.is_empty() else 0xE14A
	var checkpoint_timer_text := OS.get_environment("CT2_ROUTE_CHECKPOINT_RAM_0614").strip_edges()
	var checkpoint_timer := int(checkpoint_timer_text) if not checkpoint_timer_text.is_empty() else 0x00
	var checkpoint_result_pc_text := OS.get_environment("CT2_ROUTE_CHECKPOINT_RESULT_PC").strip_edges()
	var checkpoint_result_pc := int(checkpoint_result_pc_text) if not checkpoint_result_pc_text.is_empty() else 0xD193
	var slot11_watch_from_text := OS.get_environment("CT2_SLOT11_WATCH_FROM").strip_edges()
	var slot11_watch_from := int(slot11_watch_from_text) if not slot11_watch_from_text.is_empty() else -1
	var slot11_watch_dir := OS.get_environment("CT2_SLOT11_WATCH_DIR").strip_edges()
	var slot05_watch_dir := OS.get_environment("CT2_SLOT05_WATCH_DIR").strip_edges()
	var route_phase_watch := OS.get_environment("CT2_ROUTE_PHASE_WATCH").strip_edges() == "1"
	var waitflag_watch := OS.get_environment("CT2_RAM_062D_WATCH").strip_edges() == "1"
	var waitflag_watch_from_text := OS.get_environment("CT2_RAM_062D_WATCH_FROM").strip_edges()
	var waitflag_watch_from := int(waitflag_watch_from_text) if not waitflag_watch_from_text.is_empty() else 9300
	var waitflag_watch_to_text := OS.get_environment("CT2_RAM_062D_WATCH_TO").strip_edges()
	var waitflag_watch_to := int(waitflag_watch_to_text) if not waitflag_watch_to_text.is_empty() else 9470
	var checkpoint_saved := false
	for source_frame in range(4694, final_frame + 1):
		if events.has(source_frame):
			_dispatch_edges(route, events[source_frame])
		var waitflag_before := _diagnostic_ram_byte(route, 0x062D) \
			if waitflag_watch and source_frame >= waitflag_watch_from \
				and source_frame <= waitflag_watch_to else -1
		route.call("_advance_route_source_tick")
		if waitflag_watch and source_frame >= waitflag_watch_from \
				and source_frame <= waitflag_watch_to \
				and route._fresh_source_route_runner != null:
			var frame_scheduler = route._fresh_source_route_runner._scheduler
			if frame_scheduler != null:
				var frame_slot05: Dictionary = frame_scheduler.get_task_boundary_snapshot(0x05)
				var frame_slot05_ram: PackedByteArray = frame_slot05.get("ram_image", PackedByteArray())
				if frame_slot05_ram.size() == 0x800 \
						and int(frame_slot05_ram[0x0518]) in [0x1C, 0x1E]:
					var frame_route_status: Dictionary = route.get_route_status()
					var frame_source_route: Dictionary = frame_route_status.get("fresh_source_route", {})
					var frame_scheduler_status: Dictionary = frame_source_route.get("scheduler", {})
					var frame_task_records: Array[Dictionary] = []
					for task_record_variant in frame_scheduler_status.get("task_slots", []):
						if not task_record_variant is Dictionary:
							continue
						var task_record: Dictionary = task_record_variant
						var task_bytes: Variant = task_record.get("bytes", PackedByteArray())
						frame_task_records.append({
							"slot": task_record.get("slot_base", -1),
							"bytes": (task_bytes as PackedByteArray).hex_encode() \
								if task_bytes is PackedByteArray else "invalid",
						})
					var frame_nmi_result: Dictionary = frame_route_status.get(
						"fresh_source_route_nmi", {})
					var frame_scan_results: Array[Dictionary] = []
					for scan_variant in frame_nmi_result.get("scheduler_scan_results", \
							frame_nmi_result.get("next_task_scan_results", [])):
						if not scan_variant is Dictionary:
							continue
						var scan_result: Dictionary = scan_variant
						var delays: Variant = scan_result.get("ready_delays_after", PackedByteArray())
						frame_scan_results.append({
							"decision": scan_result.get("decision", -1),
							"selected_slot": scan_result.get("selected_slot_base", -1),
							"checked_slots": scan_result.get("checked_slots", []),
							"ready_after": (delays as PackedByteArray).hex_encode() \
								if delays is PackedByteArray else "invalid",
						})
					var frame_record: Variant = frame_slot05.get("record", PackedByteArray())
					print("SCENARIO_1E_FRAME " + JSON.stringify({
						"source_frame": source_frame,
						"active_slot": int(frame_slot05_ram[0x0000]),
						"scenario_0516_0519": frame_slot05_ram.slice(0x0516, 0x051A).hex_encode(),
						"ram_062d": int(frame_slot05_ram[0x062D]),
						"slot05_pc": int(frame_slot05.get("pc", -1)),
						"slot05_ready_delay": int(frame_slot05.get("ready_delay", -1)),
						"slot05_record": (frame_record as PackedByteArray).hex_encode() \
							if frame_record is PackedByteArray else "invalid",
						"runner_phase": frame_source_route.get("phase", ""),
						"pending_selected_slot": frame_source_route.get("pending_selected_task_slot", -1),
						"pending_boundary_pc": frame_source_route.get("pending_selected_task_boundary_pc", -1),
						"source_boundary": frame_source_route.get("source_boundary", ""),
						"scheduler_active_slot": frame_scheduler_status.get("active_task_slot", -1),
						"scheduler_scan_cursor": frame_scheduler_status.get("scheduler_scan_cursor", -1),
						"scheduler_ready_latch": frame_scheduler_status.get("scheduler_ready_latch_001b", -1),
						"scheduler_task_records": frame_task_records,
						"nmi_status": frame_nmi_result.get("status", ""),
						"nmi_next_slot": frame_nmi_result.get("next_selected_task_slot", -1),
						"nmi_selected_slot": frame_nmi_result.get("selected_task_slot", -1),
						"nmi_scan_results": frame_scan_results,
					}))
		if waitflag_before >= 0:
			var waitflag_after := _diagnostic_ram_byte(route, 0x062D)
			if waitflag_after >= 0 and waitflag_after != waitflag_before:
				var diagnostic_status: Dictionary = route.get_route_status()
				var diagnostic_runner: Dictionary = diagnostic_status.get("fresh_source_route", {})
				var diagnostic_scheduler: Dictionary = diagnostic_runner.get("scheduler", {})
				var diagnostic_task: Dictionary = diagnostic_status.get("fresh_source_route_task", {})
				var diagnostic_nmi: Dictionary = diagnostic_status.get("fresh_source_route_nmi", {})
				var changed_writes: Array[Dictionary] = []
				var instruction_hits: Array[Dictionary] = []
				_diagnostic_collect_address_writes(diagnostic_task, 0x062D, "task", changed_writes)
				_diagnostic_collect_address_writes(diagnostic_nmi, 0x062D, "nmi", changed_writes)
				_diagnostic_collect_instruction_hits(diagnostic_task,
					[0xE24D, 0xE252, 0xE254, 0xE255, 0xE4B8, 0xE4BB], "task", instruction_hits)
				_diagnostic_collect_instruction_hits(diagnostic_nmi,
					[0xE24D, 0xE252, 0xE254, 0xE255, 0xE4B8, 0xE4BB], "nmi", instruction_hits)
				var nmi_slot05: Dictionary = diagnostic_nmi.get("slot05_resume_result", {})
				var task_slot05: Dictionary = diagnostic_task.get("slot05_resume_result", {})
				var nmi_slot05_writes: Array[Dictionary] = []
				for write_variant in nmi_slot05.get("writes", []):
					if write_variant is Dictionary and int(write_variant.get("address", -1)) == 0x062D:
						nmi_slot05_writes.append(write_variant.duplicate(true))
				var task_slot05_writes: Array[Dictionary] = []
				for write_variant in task_slot05.get("writes", []):
					if write_variant is Dictionary and int(write_variant.get("address", -1)) == 0x062D:
						task_slot05_writes.append(write_variant.duplicate(true))
				var task_snapshots: Array[Dictionary] = []
				var watched_scheduler = route._fresh_source_route_runner._scheduler \
					if route._fresh_source_route_runner != null else null
				if watched_scheduler != null:
					for slot_base in [0x01, 0x05, 0x09, 0x11, 0x15]:
						var slot_boundary: Dictionary = watched_scheduler.get_task_boundary_snapshot(slot_base)
						var record: Variant = slot_boundary.get("record", PackedByteArray())
						task_snapshots.append({
							"slot": slot_base,
							"pc": int(slot_boundary.get("pc", -1)),
							"ready_delay": int(slot_boundary.get("ready_delay", -1)),
							"record": (record as PackedByteArray).hex_encode() \
								if record is PackedByteArray else "invalid",
						})
				var ram_snapshot: Dictionary = watched_scheduler.get_task_boundary_snapshot(0x05) \
					if watched_scheduler != null else {}
				var diagnostic_ram: PackedByteArray = ram_snapshot.get("ram_image", PackedByteArray())
				print("RAM_062D_WRITE frame=%d old=$%02X new=$%02X active=$%02X scenario=%s runner_phase=%s selected_slot=%s selected_pc=%s boundary=%s task_status=%s task_keys=%s nmi_keys=%s nmi_slot05_keys=%s nmi_slot05_writes=%s task_slot05_keys=%s task_slot05_writes=%s writes=%s instruction_hits=%s slots=%s" % [
					source_frame, waitflag_before, waitflag_after,
					int(diagnostic_ram[0]) if diagnostic_ram.size() == 0x800 else -1,
					diagnostic_ram.slice(0x0516, 0x051A).hex_encode() if diagnostic_ram.size() == 0x800 else "invalid",
					String(diagnostic_runner.get("phase", "")),
					str(diagnostic_runner.get("pending_selected_task_slot", -1)),
					str(diagnostic_runner.get("pending_selected_task_boundary_pc", -1)),
					String(diagnostic_runner.get("source_boundary", "")),
					String(diagnostic_task.get("status", "")),
					str(diagnostic_task.keys()), str(diagnostic_nmi.keys()),
					str(nmi_slot05.keys()), JSON.stringify(nmi_slot05_writes),
					str(task_slot05.keys()), JSON.stringify(task_slot05_writes), JSON.stringify(changed_writes),
					JSON.stringify(instruction_hits), JSON.stringify(task_snapshots)])
		if route_phase_watch and source_frame in [9068, 9069, 9070, 9071, 9072, 9073, 9074, 9075, 9076, 9077, 9078, 9079, 9080, 9081, 9082, 9083, 9084, 9085, 9086, 9087, 9088, 9089, 9090, 9091, 9093, 9100, 9108, 9109, 9110, 9121, 9122, final_frame]:
			var phase_status: Dictionary = route.get_route_status()
			var phase_route: Dictionary = phase_status.get("fresh_source_route", {})
			var phase_scheduler: Dictionary = phase_route.get("scheduler", {})
			var phase_task: Dictionary = phase_status.get("fresh_source_route_task", {})
			var phase_nmi: Dictionary = phase_status.get("fresh_source_route_nmi", {})
			print("ROUTE_PHASE frame=%d stage=%s phase=%s selected=%s pending_pc=%s boundary=%s task=%s nmi=%s" % [
				source_frame, String(phase_status.get("stage", "")),
				String(phase_route.get("phase", "")),
				str(phase_route.get("pending_selected_task_slot", -1)),
				str(phase_route.get("pending_selected_task_boundary_pc", -1)),
				String(phase_route.get("source_boundary", "")),
				String(phase_task.get("status", "")), String(phase_nmi.get("status", ""))])
		if source_frame >= slot11_watch_from and slot11_watch_from >= 0 \
				and route._fresh_source_route_runner != null:
			var watch_scheduler = route._fresh_source_route_runner._scheduler
			var watch_boundary: Dictionary = watch_scheduler.get_task_boundary_snapshot(0x11)
			var watch_ram: PackedByteArray = watch_boundary.get("ram_image", PackedByteArray())
			if watch_ram.size() == 0x800:
				var watch_signature := watch_ram.slice(0x005F, 0x0061).hex_encode() + ":" \
					+ watch_ram.slice(0x0063, 0x0065).hex_encode() + ":" \
					+ watch_ram.slice(0x05E3, 0x05F6).hex_encode() + ":" \
					+ watch_ram.slice(0x0515, 0x051A).hex_encode() + ":" \
					+ watch_ram.slice(0x0404, 0x0406).hex_encode()
				if watch_signature != _slot11_watch_previous_signature:
					_slot11_watch_previous_signature = watch_signature
					var watch_context = watch_scheduler.get_task_context(0x11)
					var watch_stack: PackedByteArray = watch_boundary.get("stack_page", PackedByteArray())
					print("SLOT11_WATCH frame=%d pc=$%04X sp=$%02X A/X/Y=$%02X/$%02X/$%02X P=$%02X record=%s stack[C7:CB]=%s signature=%s" % [
						source_frame, int(watch_context.program_counter), int(watch_context.stack_pointer),
						int(watch_context.accumulator), int(watch_context.x_register),
						int(watch_context.y_register), int(watch_context.status_register),
						(watch_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
						watch_stack.slice(0xC7, 0xCB).hex_encode() if watch_stack.size() == 0x100 else "invalid",
						watch_signature])
				if not slot11_watch_dir.is_empty():
					DirAccess.make_dir_recursive_absolute(slot11_watch_dir)
					var watch_file := FileAccess.open("%s/frame_%06d.bin" % [slot11_watch_dir, source_frame], FileAccess.WRITE)
					if watch_file != null:
						watch_file.store_buffer(watch_ram)
					var watch_dump_stack: PackedByteArray = watch_boundary.get("stack_page", PackedByteArray())
					var watch_dump_context = watch_scheduler.get_task_context(0x11)
					var watch_record: PackedByteArray = watch_boundary.get("record", PackedByteArray())
					var watch_dump := {
						"source": "ordinary_input_godot_source_route",
						"source_frame": source_frame,
						"slot_base": 0x11,
						"pc": int(watch_dump_context.program_counter),
						"sp": int(watch_dump_context.stack_pointer),
						"registers": {"a": int(watch_dump_context.accumulator),
							"x": int(watch_dump_context.x_register), "y": int(watch_dump_context.y_register),
							"p": int(watch_dump_context.status_register),
							"p_known_mask": int(watch_dump_context.status_known_mask)},
						"record_hex": watch_record.hex_encode(),
						"bank_low": int(watch_boundary.get("bank_low", -1)),
						"bank_high": int(watch_boundary.get("bank_high", -1)),
						"mapper": watch_boundary.get("mapper", {}).duplicate(true),
						"ram_hex": watch_ram.hex_encode(),
						"stack_hex": watch_dump_stack.hex_encode(),
					}
					var watch_json := FileAccess.open(
						"%s/frame_%06d_boundary.json" % [slot11_watch_dir, source_frame], FileAccess.WRITE)
					if watch_json != null:
						watch_json.store_string(JSON.stringify(watch_dump))
						watch_json.close()
			if source_frame in [9093, final_frame] and not slot11_watch_dir.is_empty() \
					and watch_ram.size() == 0x800:
				var exact_watch_file := FileAccess.open(
					"%s/frame_%06d_exact.bin" % [slot11_watch_dir, source_frame], FileAccess.WRITE)
				if exact_watch_file != null:
					exact_watch_file.store_buffer(watch_ram)
		if source_frame in [6808, 6943, 6968, 7093, 7096, 7112, 7119, 7243, 7393, 7993, 8443, 8464, 8593, 8594, 8782, 8855, 8858, 8863, 8943, 8945, 8953, 9043, 9045, 9068, 9191, final_frame] \
				or (source_frame >= 8783 and source_frame <= 8797) \
				or (source_frame >= 8801 and source_frame <= 8820):
			var checkpoint := route.get_route_status()
			var checkpoint_gaps: Array = checkpoint.get("route_gaps", [])
			var source_route: Dictionary = checkpoint.get("fresh_source_route", {})
			var scheduler: Dictionary = source_route.get("scheduler", {})
			var nmi_result: Dictionary = checkpoint.get("fresh_source_route_nmi", {})
			_stage_at_checkpoints[source_frame] = {
				"stage": checkpoint.get("stage", ""),
				"cutscene_id": checkpoint.get("cutscene_id", -1),
				"vm_event_index": route.vm.current_event_index,
				"vm_source_pc": route.vm.current_source_address,
				"vm_wait_remaining": route.vm._wait_remaining,
				"cutscene_background_task": checkpoint.get("cutscene_background_task", {}),
				"fceux_script_pointer": _read_fceux_script_pointer(source_frame),
				"active_background_id": checkpoint.get("active_background_id", -1),
				"source_chr_2k_selectors": route._visuals.screen.get_source_2k_chr_selectors(),
				"meeting_cursor_y": checkpoint.get("meeting_cursor_y", -1),
				"first_action_menu_source_pending": checkpoint.get("first_action_menu_source_pending", false),
				"first_action_menu_source_input_sample": checkpoint.get(
					"first_action_menu_source_input_sample", {}).duplicate(true),
				"pass_receiver_poll": _summarize_pass_receiver_poll(source_route),
				"first_action_menu_visible_selection_id": int(
					route._visuals._action_menu_panel.selected_action_id)
					if is_instance_valid(route._visuals._action_menu_panel) else -1,
				"last_route_gap": String(checkpoint_gaps.back()) if not checkpoint_gaps.is_empty() else "",
				"pending_source_pc": checkpoint.get("cutscene_wait_cleanup", {}).get("pending_source_pc", -1),
				"pending_helper_id": checkpoint.get("cutscene_wait_cleanup", {}).get("pending_helper_id", ""),
				"source_route_phase": source_route.get("phase", ""),
				"source_boundary": source_route.get("source_boundary", ""),
				"source_task_status": checkpoint.get("fresh_source_route_task", {}).get("status", ""),
				"last_external_nmi_frame": source_route.get("last_external_nmi_frame", -1),
				"nmi_result_status": nmi_result.get("status", ""),
				"nmi_ready_latch": scheduler.get("scheduler_ready_latch_001b", -1),
				"active_task_slot": scheduler.get("active_task_slot", -1),
				"controller_sample": scheduler.get("controller_sample", {}),
				"task_slots": scheduler.get("task_slots", []),
			}
			if source_frame >= 8855 and route._fresh_source_route_runner != null:
				var slot05_boundary: Dictionary = route._fresh_source_route_runner._scheduler.get_task_boundary_snapshot(0x05)
				var slot05_ram: PackedByteArray = slot05_boundary.get("ram_image", PackedByteArray())
				var slot05_player_records: Array[Dictionary] = []
				var record_pointers := FileAccess.get_file_as_bytes(
					"res://reference/rom_extract/gameplay/menus/first_action_menu/player_record_pointer_table_22.bin")
				if slot05_ram.size() == 0x800 and record_pointers.size() == 44:
					for player_slot in range(11):
						var pointer_offset := player_slot * 2
						var record_address := int(record_pointers[pointer_offset]) \
							| (int(record_pointers[pointer_offset + 1]) << 8)
						var energy := int(slot05_ram[record_address + 1]) \
							| (int(slot05_ram[record_address + 2]) << 8)
						slot05_player_records.append({"slot": player_slot,
							"address": record_address, "record": slot05_ram.slice(record_address,
							record_address + 4).hex_encode(), "energy": energy})
				var source_task: Dictionary = checkpoint.get("fresh_source_route_task", {})
				var source_worker: Dictionary = source_task.get("slot05_worker_result", {})
				if source_frame == final_frame and not slot05_watch_dir.is_empty():
					var field_entry_valid: bool = route._fresh_source_route_runner._scheduler \
						.validate_slot05_field_entry_enqueue_worker_result(source_worker)
					var worker_ram: PackedByteArray = source_worker.get("ram_image", PackedByteArray())
					var worker_stack: PackedByteArray = source_worker.get("stack_page", PackedByteArray())
					var live_slot05: Dictionary = route._fresh_source_route_runner._scheduler \
						.get_task_boundary_snapshot(0x05)
					var live_ram: PackedByteArray = live_slot05.get("ram_image", PackedByteArray())
					var live_stack: PackedByteArray = live_slot05.get("stack_page", PackedByteArray())
					var slot05_dump := {
						"source": "ordinary_input_godot_source_route",
						"source_frame": source_frame,
						"field_entry_validator": field_entry_valid,
						"live_boundary": {
							"pc": live_slot05.get("pc", -1), "sp": live_slot05.get("sp", -1),
							"record_hex": (live_slot05.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
							"bank_low": live_slot05.get("bank_low", -1), "bank_high": live_slot05.get("bank_high", -1),
							"ram_hex": live_ram.hex_encode(), "stack_hex": live_stack.hex_encode(),
						},
						"worker": {
							"ok": source_worker.get("ok", false),
							"exit_kind": source_worker.get("exit_kind", ""),
							"exit_pc": source_worker.get("exit_pc", -1),
							"exit_bank": source_worker.get("exit_bank", -1),
							"blocked_read": source_worker.get("blocked_read", {}),
							"registers": source_worker.get("registers", {}),
							"mapper": source_worker.get("mapper", {}),
							"entry_mapper": source_worker.get("entry_mapper", {}),
							"source_dispatch": source_worker.get("source_dispatch", {}),
							"rom_sha256": source_worker.get("rom_sha256", ""),
							"source_manifest": source_worker.get("source_manifest", ""),
							"source_manifest_sha256": source_worker.get("source_manifest_sha256", ""),
							"ram_hex": worker_ram.hex_encode(), "stack_hex": worker_stack.hex_encode(),
							"calls": source_worker.get("calls", []),
							"writes": source_worker.get("writes", []),
							"executed_source_spans": source_worker.get("executed_source_spans", []),
						},
					}
					DirAccess.make_dir_recursive_absolute(slot05_watch_dir)
					var slot05_json := FileAccess.open("%s/frame_%06d_slot05.json" % [slot05_watch_dir, source_frame],
						FileAccess.WRITE)
					if slot05_json != null:
						slot05_json.store_string(JSON.stringify(slot05_dump))
						slot05_json.close()
				var source_calls: Array = source_worker.get("calls", [])
				var source_instructions: Array = source_worker.get("instructions", [])
				var source_writes: Array = source_worker.get("writes", [])
				var relevant_pcs: Array[int] = []
				for instruction_variant in source_instructions:
					if instruction_variant is Dictionary:
						var instruction: Dictionary = instruction_variant
						var pc := int(instruction.get("pc", -1))
						if pc in [0xE1F1, 0xE1F7, 0xE2BC, 0xE33F, 0xE343]:
							relevant_pcs.append(pc)
				var energy_writes: Array[Dictionary] = []
				for write_variant in source_writes:
					if write_variant is Dictionary and int(write_variant.get("address", -1)) in [0x0349, 0x034A, 0x0618]:
						energy_writes.append(write_variant)
				_stage_at_checkpoints[source_frame]["slot05_state"] = {
					"pc": slot05_boundary.get("pc", -1),
					"active_task_slot": slot05_boundary.get("active_task_slot", -1),
					"phase": slot05_boundary.get("phase", -1),
					"record": (slot05_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
					"source_label": slot05_boundary.get("source_label", ""),
					"ram_player_record_0348_034b": slot05_ram.slice(0x0348, 0x034C).hex_encode() if slot05_ram.size() == 0x800 else "invalid",
					"player_records": slot05_player_records,
					"ram_timer_0614": int(slot05_ram[0x0614]) if slot05_ram.size() == 0x800 else -1,
					"ram_stamina_counter_0618": int(slot05_ram[0x0618]) if slot05_ram.size() == 0x800 else -1,
					"last_task_status": source_task.get("status", ""),
					"worker_exit_pc": source_worker.get("exit_pc", -1),
					"worker_relevant_pcs": relevant_pcs,
					"worker_calls": source_calls.filter(func(call_variant: Variant) -> bool:
						return call_variant is Dictionary and int(call_variant.get("callsite", -1)) in [0xE1EE, 0xE1F7, 0xD1CF]),
					"worker_energy_writes": energy_writes,
				}
				_stage_at_checkpoints[source_frame]["verified_stamina_update_receipt"] = \
					route._fresh_source_route_runner._verified_stamina_update_receipt.duplicate(true)
				if source_frame == 9191:
					var slot09_boundary: Dictionary = route._fresh_source_route_runner._scheduler.get_task_boundary_snapshot(0x09)
					var slot09_ram: PackedByteArray = slot09_boundary.get("ram_image", PackedByteArray())
					var slot09_source_task: Dictionary = checkpoint.get("fresh_source_route_task", {})
					var slot09_resume: Dictionary = slot09_source_task.get("slot09_resume_result", {})
					var selector_writes: Array[Dictionary] = []
					for result_key in ["slot09_resume_result", "slot09_86f8_worker_result",
							"slot09_8779_worker_result", "slot09_87e6_worker_result",
							"slot09_ebd7_root_zero_result"]:
						var result_variant: Variant = slot09_source_task.get(result_key, {})
						if not result_variant is Dictionary:
							continue
						var result_writes: Variant = result_variant.get("writes",
							result_variant.get("source_writes", result_variant.get("ram_writes", [])))
						if not result_writes is Array:
							continue
						for write_variant: Variant in result_writes:
							if not write_variant is Dictionary:
								continue
							var write: Dictionary = write_variant
							var address := int(write.get("address", -1))
							if address in [0x044E, 0x00E2, 0x0523]:
								selector_writes.append({"result": result_key,
									"source_pc": int(write.get("source_pc", write.get("pc", -1))),
									"address": address, "value": int(write.get("value", -1))})
					_stage_at_checkpoints[source_frame]["scenario1c_frame9191"] = {
						"slot09_pc": int(slot09_boundary.get("pc", -1)),
						"slot09_sp": int(slot09_boundary.get("sp", -1)),
						"slot09_record": (slot09_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
						"bank_low": int(slot09_boundary.get("bank_low", -1)),
						"bank_high": int(slot09_boundary.get("bank_high", -1)),
					"044E": int(slot09_ram[0x044E]) if slot09_ram.size() == 0x800 else -1,
						"00E2": int(slot09_ram[0x00E2]) if slot09_ram.size() == 0x800 else -1,
						"0523_052A": slot09_ram.slice(0x0523, 0x052B).hex_encode()
							if slot09_ram.size() == 0x800 else "invalid",
						"slot09_resume_status": String(slot09_resume.get("status", "")),
						"slot09_resume_entry_pc": int(slot09_resume.get("entry_pc", -1)),
						"slot09_resume_exit_pc": int(slot09_resume.get("exit_pc", -1)),
						"scenario_active": bool(slot09_resume.get("scenario_active", false)),
						"scenario_route_state_executed": bool(slot09_resume.get("scenario_route_state_executed", false)),
						"selector_result_x": int(slot09_resume.get("selector_result_x", -1)),
						"selected_f2_pointer": int(slot09_resume.get("selected_f2_pointer", -1)),
						"selector_writes_of_interest": selector_writes,
					}
				if source_frame == 8863:
					var fceux_stamina_ram := _read_fceux_ram(source_frame)
					var stamina_receipt: Dictionary = route._fresh_source_route_runner._verified_stamina_update_receipt
					var receipt_rows: Array = stamina_receipt.get("live_player_records", [])
					var stamina_ram_matches := fceux_stamina_ram.size() == 0x800 \
						and slot05_ram.size() == 0x800 \
						and slot05_player_records.size() == 11 and receipt_rows.size() == 11 \
						and bool(stamina_receipt.get("ok", false)) \
						and String(stamina_receipt.get("kind", "")) == "rom_d193_e1f1_e1f7_e2bc_stamina_update" \
						and int(stamina_receipt.get("energy_before", -1)) == 400 \
						and int(stamina_receipt.get("energy_after", -1)) == 397
					for player_index in range(mini(slot05_player_records.size(), receipt_rows.size())):
						var route_record: Dictionary = slot05_player_records[player_index]
						var receipt_record: Dictionary = receipt_rows[player_index]
						var record_address := int(route_record.get("address", -1))
						var route_bytes := slot05_ram.slice(record_address, record_address + 4) \
							if record_address >= 0 and record_address + 4 <= slot05_ram.size() else PackedByteArray()
						var fceux_bytes := fceux_stamina_ram.slice(record_address, record_address + 4) \
							if record_address >= 0 and record_address + 4 <= fceux_stamina_ram.size() else PackedByteArray()
						stamina_ram_matches = stamina_ram_matches \
							and int(route_record.get("slot", -1)) == player_index \
							and int(receipt_record.get("slot", -1)) == player_index \
							and int(receipt_record.get("record_address", -1)) == record_address \
							and route_bytes.size() == 4 and route_bytes == fceux_bytes \
							and String(route_record.get("record", "")) == fceux_bytes.hex_encode() \
							and String(receipt_record.get("record_bytes", "")) == fceux_bytes.hex_encode()
					_stage_at_checkpoints[source_frame]["stamina_fceux_ram_parity"] = {
						"source_frame": source_frame,
						"rom_worker_ok": bool(stamina_receipt.get("ok", false)),
						"matched_player_records": 11 if stamina_ram_matches else 0,
						"expected_player_records": 11,
						"holder_energy_before": stamina_receipt.get("energy_before", -1),
						"holder_energy_after": stamina_receipt.get("energy_after", -1),
					}
					_check(stamina_ram_matches,
						"live `$D193->$E1F1->$E1F7->$E2BC` receipt and all eleven four-byte player records match same-input FCEUX RAM at frame 8863")
					if stamina_ram_matches:
						print("PASS: live stamina receipt and all 11 player records match same-input FCEUX RAM at frame 8863; holder energy 400→397.")
			if ((source_frame >= 8783 and source_frame <= 8797) \
					or (source_frame >= 8801 and source_frame <= 8820) \
					or source_frame == final_frame) \
					and route._fresh_source_route_runner != null:
				var slot11_boundary: Dictionary = route._fresh_source_route_runner._scheduler.get_task_boundary_snapshot(0x11)
				var slot11_ram: PackedByteArray = slot11_boundary.get("ram_image", PackedByteArray())
				var slot11_stack: PackedByteArray = slot11_boundary.get("stack_page", PackedByteArray())
				var fceux_slot11_ram := _read_fceux_ram(source_frame)
				if slot11_ram.size() == 0x800:
					_stage_at_checkpoints[source_frame]["slot11_state"] = {
						"pc": slot11_boundary.get("pc", -1),
						"sp": slot11_boundary.get("sp", -1),
						"registers": [slot11_boundary.get("a", -1), slot11_boundary.get("x", -1),
							slot11_boundary.get("y", -1)],
						"record": (slot11_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
						"stream_pointer": slot11_ram.slice(0x005F, 0x0061).hex_encode(),
						"animation_pointer": slot11_ram.slice(0x0063, 0x0065).hex_encode(),
						"animation_counters": slot11_ram.slice(0x05E3, 0x05EA).hex_encode(),
						"wait_counters": slot11_ram.slice(0x05F3, 0x05F6).hex_encode(),
						"queue_flag": slot11_ram[0x0515],
						"mapper_shadow": slot11_ram[0x0022],
						"stack_c7_cb": slot11_stack.slice(0xC7, 0xCB).hex_encode()
							if slot11_stack.size() == 0x100 else "invalid",
					}
				if slot11_ram.size() == 0x800 and fceux_slot11_ram.size() == 0x800:
					var slot11_matches_reference := slot11_ram.slice(0x0063, 0x0065) == fceux_slot11_ram.slice(0x0063, 0x0065) \
						and slot11_ram.slice(0x05F3, 0x05F6) == fceux_slot11_ram.slice(0x05F3, 0x05F6) \
						and slot11_ram[0x0515] == fceux_slot11_ram[0x0515]
					_slot11_alignment_sample_count += 1
					if not slot11_matches_reference:
						_slot11_alignment_mismatches.append(source_frame)
					_stage_at_checkpoints[source_frame]["slot11_reference"] = {
						"godot_animation_pointer": slot11_ram.slice(0x0063, 0x0065).hex_encode(),
						"fceux_animation_pointer": fceux_slot11_ram.slice(0x0063, 0x0065).hex_encode(),
						"godot_wait_counters": slot11_ram.slice(0x05F3, 0x05F6).hex_encode(),
						"fceux_wait_counters": fceux_slot11_ram.slice(0x05F3, 0x05F6).hex_encode(),
						"godot_queue_flag": slot11_ram[0x0515],
						"fceux_queue_flag": fceux_slot11_ram[0x0515],
						"matches": slot11_matches_reference,
					}
			if source_frame == 8782:
				_stage_at_checkpoints[source_frame]["fresh_source_route"] = source_route.duplicate(true)
				_stage_at_checkpoints[source_frame]["fresh_source_route_nmi"] = checkpoint.get(
					"fresh_source_route_nmi", {}).duplicate(true)
				_stage_at_checkpoints[source_frame]["fresh_source_route_task"] = checkpoint.get(
					"fresh_source_route_task", {}).duplicate(true)
			if String(source_route.get("phase", "")) in ["error", "stopped_before_scenario36_slot09_dispatch"] \
					and route._fresh_source_route_runner != null:
				var scheduler_status: Dictionary = source_route.get("scheduler", {})
				var active_slot := int(scheduler_status.get("active_task_slot", -1))
				var active_task: Dictionary = route._fresh_source_route_runner._scheduler.get_task_boundary_snapshot(active_slot)
				var source_ram: PackedByteArray = active_task.get("ram_image", PackedByteArray())
				if source_ram.size() == 0x800:
					_stage_at_checkpoints[source_frame]["active_task_live_inputs"] = {
						"slot": active_slot,
						"pc": active_task.get("pc", -1), "sp": active_task.get("sp", -1),
					"ram_001c_001e": source_ram.slice(0x001C, 0x001F).hex_encode(),
					"ram_0441": source_ram[0x0441],
						"record": (active_task.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
						"scenario_flags_0516_0519": source_ram.slice(0x0516, 0x051A).hex_encode(),
					"scenario_ptr_005d_005e": source_ram.slice(0x005D, 0x005F).hex_encode(),
					"scenario_cursor_003a": source_ram[0x003A],
					"scenario_continuation_051a_0522": source_ram.slice(0x051A, 0x0523).hex_encode(),
						"scenario_fields_0523_052A": source_ram.slice(0x0523, 0x052B).hex_encode(),
					"scenario_fields_052B_0539": source_ram.slice(0x052B, 0x053A).hex_encode(),
					"scenario_reader_0052_005e": source_ram.slice(0x0052, 0x005F).hex_encode(),
						"scenario_flags_053A_053D": source_ram.slice(0x053A, 0x053E).hex_encode(),
						"actor_order_0543_0545": source_ram.slice(0x0543, 0x0546).hex_encode(),
						"active_slot": source_ram[0x0000],
					}
		if events.has(source_frame):
			# The live route schedules the kickoff script with call_deferred after
			# confirming the meeting menu; yield at real input edges so the test
			# observes the same scene-tree boundary.
			await process_frame
		var route_status_now := route.get_route_status()
		_record_map2d_batch_at_frame(route_status_now, source_frame)
		if not checkpoint_out.is_empty() and not checkpoint_saved:
			var checkpoint_attempt := _try_write_route_checkpoint(route_status_now, source_frame,
				checkpoint_out, checkpoint_pc, checkpoint_timer, checkpoint_result_pc, route)
			if bool(checkpoint_attempt.get("matched", false)):
				checkpoint_saved = bool(checkpoint_attempt.get("saved", false))
				if not checkpoint_saved:
					printerr("Failed to write Godot route checkpoint: ", checkpoint_attempt.get("error", "unknown error"))
		var source_route_now: Dictionary = route_status_now.get("fresh_source_route", {})
		var handoff_now: Dictionary = route_status_now.get("cutscene_wait_cleanup", {})
		var reached_menu_now := bool(route_status_now.get("first_action_menu_complete", false))
		var menu_comparison_frame := mini(final_frame, 8953)
		if String(source_route_now.get("phase", "")) == "error" \
				or String(route_status_now.get("stage", "")) == "source_route_gap" \
			or (reached_menu_now and source_frame >= menu_comparison_frame and not check_first_pass_input):
			stop_frame = source_frame
			stop_route_status = route_status_now
			break
		if String(route_status_now.get("stage", "")) == "match_setup_gap" \
				and String(handoff_now.get("pending_helper_id", "")) == "cutscene_cleanup_9ba0":
			stop_frame = source_frame
			stop_route_status = route_status_now
			stopped_at_handoff_gap = true
			break
		if String(route_status_now.get("stage", "")) == "match_setup_gap" \
				and String(handoff_now.get("pending_helper_id", "")) == "fresh_match_preset_wait_0078" \
				and int(handoff_now.get("pending_source_pc", -1)) == 0x893B:
			stop_frame = source_frame
			stop_route_status = route_status_now
			stopped_at_preset_wait = true
			break
		if String(route_status_now.get("stage", "")) == "match_setup_gap" \
				and String(handoff_now.get("pending_helper_id", "")) == "fresh_match_a503_fade_helper" \
				and int(handoff_now.get("pending_source_pc", -1)) == 0xA56C:
			stop_frame = route.source_frame
			stop_route_status = route_status_now
			stopped_at_a503_text_setup = true
			break
		if stop_at_811f and String(route_status_now.get("stage", "")) == "match_setup_811f_pending" \
				and String(handoff_now.get("pending_helper_id", "")) == "fresh_match_811F_caller" \
				and int(handoff_now.get("pending_source_pc", -1)) == 0x811F:
			stop_frame = route.source_frame
			stop_route_status = route_status_now
			stopped_at_811f = true
			break
		if String(route_status_now.get("stage", "")) == "match_setup_a64c_pending" \
				and String(handoff_now.get("pending_helper_id", "")) == "fresh_match_a64c_prematch_body" \
				and int(handoff_now.get("pending_source_pc", -1)) == 0xA64C \
				and route.source_frame >= final_frame:
			stop_frame = route.source_frame
			stop_route_status = route_status_now
			stopped_at_a64c = true
			break
		if String(route_status_now.get("stage", "")) == "match_setup_gap" \
				and String(handoff_now.get("pending_helper_id", "")) == "fresh_match_a503_input_wait" \
				and int(handoff_now.get("pending_source_pc", -1)) == 0xA571:
			stop_frame = route.source_frame
			stop_route_status = route_status_now
			stopped_at_a503_wait_loop = true
			break
	if not checkpoint_out.is_empty():
		_check(checkpoint_saved, "ordinary-input Godot route writes the requested worker checkpoint")

	if stop_frame < 0:
		stop_frame = route.source_frame
		stop_route_status = route.get_route_status()
	if check_first_pass_input:
		var selection_checkpoint: Dictionary = _stage_at_checkpoints.get(9043, {})
		var selection_sample: Dictionary = selection_checkpoint.get(
			"first_action_menu_source_input_sample", {})
		var confirmation_checkpoint: Dictionary = _stage_at_checkpoints.get(9045, {})
		var confirmation_sample: Dictionary = confirmation_checkpoint.get(
			"first_action_menu_source_input_sample", {})
		var confirmation_slot05: Dictionary = confirmation_checkpoint.get("slot05_state", {})
		var visual_selection_id := int(selection_checkpoint.get(
			"first_action_menu_visible_selection_id", -1))
		var source_runner: Variant = route._fresh_source_route_runner
		var slot05_boundary: Dictionary = source_runner._scheduler.get_task_boundary_snapshot(0x05) \
				if source_runner != null else {}
		var pending_dispatch: Dictionary = confirmation_sample.get("pending_handler_dispatch", {})
		var expects_bridge_handoff := final_frame >= 9046
		var observed_confirmation_pc := int(confirmation_slot05.get("pc", -1))
		var observed_confirmation_active_slot := int(confirmation_slot05.get("active_task_slot", -1))
		var confirmation_stage := String(confirmation_checkpoint.get("stage", ""))
		_check(final_frame >= 9045 and confirmation_stage == "first_action_handler_pending",
			"same-input route consumes the recorded A edge at `$D5EA` frame 9045 and defers its source continuation to frame 9046")
		_check(String(selection_sample.get("source_poll_status", "")) == "pass_selection_adopted" \
			and (selection_sample.get("source_writes_applied", []) as Array).size() == 3 \
			and is_instance_valid(route._menu_input) \
			and route._menu_input.selected_action_id == FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.PASS \
			and route._menu_input.selected_direction_index == FIRST_ACTION_MENU_INPUT_SCRIPT.DirectionIndex.LEFT \
			and visual_selection_id == FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.PASS,
			"ordinary Left input at frame 9043 updates ROM selection writes and the visible PASS menu row")
		_check(String(confirmation_sample.get("source_poll_status", "")) == "pass_confirmation_pending_source_execution" \
			and bool(confirmation_sample.get("source_input_consumed", false)) \
			and (confirmation_sample.get("source_writes_applied", []) as Array).is_empty() \
			and observed_confirmation_pc == 0xD5EA \
			and observed_confirmation_active_slot == 0x05 \
			and int(pending_dispatch.get("source_boundary_pc", -1)) == 0xD5EA \
			and not pending_dispatch.has("target_pc"),
			"ordinary A input is consumed at `$D5EA`; the later scheduler state remains source-owned and has no injected handler target")
		if final_frame >= FIRST_PASS_DECISION_FRAME:
			_check(_has_button_change(events, 9068, "Down", true) \
				and _has_button_change(events, 9069, "Down", false) \
				and _has_button_change(events, 9076, "A", true) \
				and _has_button_change(events, 9077, "A", false),
				"recorded same-input route includes the frame-9068 receiver Down edge and frame-9076 A selection edge with releases")
			var receiver_down_poll: Dictionary = _stage_at_checkpoints.get(9068, {}).get(
				"pass_receiver_poll", {})
			_check(_pass_receiver_poll_matches(receiver_down_poll, 9068, 0x04,
				"receiver_down_scan_stopped_at_renderer_call", 0xEF7F),
				"live `$D80F` receiver poll consumes the fresh frame-9068 Down receipt and adopts its `$EF7F` scan result")
			var receiver_a_poll: Dictionary = _summarize_pass_receiver_poll(
				stop_route_status.get("fresh_source_route", {}))
			_check(_pass_receiver_poll_matches(receiver_a_poll, 9076, 0x80,
				"receiver_confirmed_at_d70c_before_holder_transfer", 0xD70C),
				"live `$D80F` receiver poll consumes the fresh frame-9076 A receipt and adopts its `$D70C` confirmation result")
		if expects_bridge_handoff:
			var bridge_handoff: Dictionary = {}
			var bridge_result: Dictionary = {}
			var scans: Array = []
			if final_frame <= 9048:
				var stop_input_sample: Dictionary = stop_route_status.get(
					"first_action_menu_source_input_sample", {})
				bridge_handoff = stop_input_sample.get("next_frame_dispatch", {})
				bridge_result = bridge_handoff.get("confirmation_bridge", {})
				scans = bridge_handoff.get("scheduler_scan_results", [])
			else:
				var source_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
				bridge_result = source_runner_status.get("last_first_action_confirmation_bridge_result", {})
				scans = source_runner_status.get("last_first_action_confirmation_bridge_scans", [])
			var first_scan: Dictionary = scans[0] if not scans.is_empty() else {}
			var outer_handoff_matches := final_frame > 9048 or (
				String(bridge_handoff.get("status", "")) == "pass_confirmation_scheduler_handoff" \
				and int(bridge_handoff.get("source_boundary_pc", -1)) == 0xCAA5 \
				and String(bridge_handoff.get("next_scheduler_phase", "")) == "waiting_for_selected_task_source" \
				and int(bridge_handoff.get("next_selected_task_slot", -1)) == 0x09)
			_check(outer_handoff_matches \
				and String(bridge_result.get("status", "")) == "pass_confirmation_yielded_waiting_for_scheduler_nmi" \
				and int(bridge_result.get("task_resume_pc_after_scheduler", -1)) == 0xE945 \
				and not bool(bridge_result.get("d6c7_reached", true)) \
				and int(first_scan.get("selected_slot_base", -1)) == 0x09 \
				and first_scan.get("checked_slots", []) == [0x09],
				"frame 9046 resumes `$D5EA->$D632->$D67C->$E93D->$CB0F->$CAA5`, selects slot `$09`, and continues only through the source-selected task boundaries")
		if final_frame >= 9048:
			var label_resume: Dictionary = stop_route_status.get("fresh_source_route_task", {})
			var label_result: Dictionary = label_resume.get("pass_label_result", {})
			var label_boundary: Dictionary = label_resume.get("next_boundary_snapshot", {})
			if final_frame > 9048:
				var source_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
				label_result = source_runner_status.get("last_first_action_pass_label_result", {})
				label_boundary = source_runner_status.get("last_first_action_pass_label_adoption", {}).get(
					"next_boundary_snapshot", {})
			_check(String(label_result.get("status", "")) == "pass_action_label_queued" \
				and int(label_boundary.get("pc", -1)) == 0xD68A \
				and label_result.get("ppu_queue_packets", []).size() == 2,
				"next normal NMI dispatches slot `$05` at `$E945`, renders the ROM PASS label, and returns at `$D68A`")
		if final_frame >= 9049:
			var source_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
			var no_candidates: Dictionary = source_runner_status.get(
				"last_pass_no_candidates_continuation_result", {})
			var no_candidates_adoption: Dictionary = source_runner_status.get(
				"last_pass_no_candidates_continuation_adoption", {})
			var no_candidates_boundary: Dictionary = no_candidates_adoption.get(
				"next_boundary_snapshot", {})
			_check(String(no_candidates.get("status", "")) == "pass_no_candidates_reached_live_d6c7" \
				and String(no_candidates_adoption.get("status", "")) == "pass_no_candidates_continuation_adopted" \
				and int(no_candidates_boundary.get("pc", -1)) == 0xD6C7 \
				and int(no_candidates.get("registers", {}).get("sp", -1)) == 0x4A,
				"live `$D68A` renderer return continues through the no-candidates source path and scheduler adoption at `$D6C7`")
		if final_frame >= 9050:
			var source_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
			var pass_dispatch: Dictionary = source_runner_status.get(
				"last_first_action_menu_dispatch_result", {})
			var pass_adoption: Dictionary = source_runner_status.get(
				"last_first_action_menu_adoption_result", {})
			var handler_boundary: Dictionary = pass_adoption.get("next_boundary_snapshot", {})
			_check(String(pass_dispatch.get("status", "")) == "pass_cb99_dispatched" \
				and String(pass_adoption.get("status", "")) == "pass_handler_entry_adopted" \
				and int(handler_boundary.get("pc", -1)) == 0xD7E8 \
				and not bool(pass_adoption.get("handler_body_executed", true)),
				"live `$D6C7->$CB99->$D7E8` dispatch reaches the first action handler entry without running its body")
		if final_frame >= 9051:
			var source_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
			var handler_result: Dictionary = source_runner_status.get(
				"last_pass_handler_body_result", {})
			var handler_adoption: Dictionary = source_runner_status.get(
				"last_pass_handler_body_adoption", {})
			var handler_boundary: Dictionary = handler_adoption.get("next_boundary_snapshot", {})
			_check(String(handler_result.get("status", "")) == "pass_scenario38_queue_at_cb0f_call_entry" \
				and String(handler_adoption.get("status", "")) == "pass_handler_cb0f_entry_adopted" \
				and int(handler_boundary.get("pc", -1)) == 0xCB0F \
				and int(handler_result.get("scenario_id_queued", -1)) == 0x38 \
				and not bool(handler_result.get("scheduler_yield_executed", true)),
				"ROM PASS handler queues scenario `$38` and reaches live slot `$05` `$CB0F` before scheduler save/NMI")
		if final_frame >= 9052:
			var source_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
			var cb0f_save: Dictionary = source_runner_status.get("last_pass_handler_cb0f_save_result", {})
			var cb0f_boundary: Dictionary = cb0f_save.get("saved_boundary", {})
			var cb0f_scans: Array = source_runner_status.get("last_pass_handler_cb0f_scans", [])
			var cb0f_scan: Dictionary = cb0f_scans[cb0f_scans.size() - 1] if not cb0f_scans.is_empty() else {}
			_check(String(cb0f_save.get("status", "")) == "pass_handler_cb0f_saved_and_scanned" \
				and int(cb0f_save.get("source_callsite_pc", -1)) == 0xCBBE \
				and int(cb0f_boundary.get("pc", -1)) == 0xCB0F \
				and int(cb0f_boundary.get("active_task_slot", -1)) == -1 \
				and int(cb0f_boundary.get("phase", -1)) == 3 \
				and int(cb0f_save.get("next_selected_task_slot", -1)) == 0x09 \
				and String(cb0f_save.get("next_scheduler_phase", "")) in [
					"awaiting_external_nmi", "waiting_for_selected_task_source"] \
				and int(cb0f_scan.get("selected_slot_base", -1)) == 0x09,
				"PASS handler saves slot `$05` at `$CB0F` and the live scheduler independently selects slot `$09`")
		if final_frame == 9053:
			var map2d_task: Dictionary = stop_route_status.get("fresh_source_route_task", {})
			var map2d_batch: Dictionary = map2d_task.get("map_batch_result", {})
			var map2d_runner: Dictionary = stop_route_status.get("fresh_source_route", {})
			var map2d_output_ram: PackedByteArray = map2d_batch.get("updated_ram", PackedByteArray())
			var map2d_batch_reached: bool = String(stop_route_status.get("stage", "")) == "source_route_waiting_for_nmi" \
				and String(map2d_runner.get("phase", "")) == "awaiting_external_nmi" \
				and String(map2d_runner.get("source_boundary", "")).contains("slot-$15 map-$2D batch save -> scheduler WAIT_FOR_NMI_READY") \
				and String(map2d_task.get("status", "")) == "slot15_map2D_batch_yielded" \
				and String(map2d_batch.get("status", "")) == "map2D_3_metatiles_ready_at_yield" \
				and int(map2d_batch.get("entry_pc", -1)) == 0x8572 \
				and int(map2d_batch.get("callsite_pc", -1)) == 0x856F \
				and int(map2d_batch.get("map_id", -1)) == 0x2D \
				and int(map2d_batch.get("batch_start_map_index", -1)) == 0 \
				and int(map2d_batch.get("batch_start_placement", -1)) == 0x80 \
				and int(map2d_batch.get("batch_cell_count", -1)) == 3 \
				and _map2d_batch_source_matches(map2d_batch) \
				and map2d_output_ram.size() == 0x800 \
				and int(map2d_output_ram[0x0515]) == 0x80 \
				and map2d_output_ram.slice(0x05C7, 0x05CA) == PackedByteArray([0x60, 0x83, 0x1D]) \
				and int(map2d_output_ram[0x05CA]) == 0x02 \
				and int(map2d_output_ram[0x05CC]) == 0x2D \
				and int(map2d_batch.get("mapper", {}).get("bank_low", -1)) == 0x0B \
				and int(map2d_batch.get("mapper", {}).get("bank_high", -1)) == 0x13 \
				and map2d_batch.get("ppu_bus_events", []).is_empty() \
				and not bool(map2d_batch.get("trace_state_used", true)) \
				and not bool(map2d_batch.get("source_cycle_timing_modeled", true))
			_check(map2d_batch_reached,
				"live slot-$15 `$8572` expands map-$2D IDs `$00/$71/$72` into three source-matched `$85C2` packet groups and yields at `$856F`")
			if map2d_batch_reached:
				print("PASS: frame 9053 map-$2D batch is 3 metatiles / 96 queue bytes, with source-matched tile/attribute groups and cursor `$60/$83/$1D`.")
		elif final_frame == 9054:
			var map2d_nmi: Dictionary = stop_route_status.get("fresh_source_route_nmi", {})
			var map2d_normal_nmi: Dictionary = map2d_nmi.get("normal_nmi_result",
				map2d_nmi.get("nmi_result", {}))
			var map2d_secondary_queue: Dictionary = map2d_normal_nmi.get("secondary_queue", {})
			var map2d_nmi_bus_events: Array = map2d_normal_nmi.get("ppu_bus_events", [])
			var map2d_ppu_render: Dictionary = map2d_nmi.get("ppu_render_result", {})
			var map2d_nmi_transfer_matches: bool = String(map2d_secondary_queue.get("status", "")) == "transferred" \
				and String(map2d_secondary_queue.get("branch", "")) == "secondary_queue_consumed" \
				and String(map2d_secondary_queue.get("queue_kind", "")) == "secondary" \
				and int(map2d_secondary_queue.get("packet_count", -1)) == 15 \
				and int(map2d_secondary_queue.get("ready_flag_before", -1)) == 0x80 \
				and int(map2d_secondary_queue.get("ready_flag_after", -1)) == 0 \
				and map2d_nmi_bus_events.size() == 96 \
				and bool(map2d_nmi.get("ppu_bus_events_applied", false)) \
				and bool(map2d_ppu_render.get("ok", false)) \
				and String(map2d_ppu_render.get("status", "")) == "applied" \
				and int(map2d_ppu_render.get("nametable_writes_applied", -1)) == 51 \
				and map2d_ppu_render.get("unapplied_writes", []).is_empty()
			_check(map2d_nmi_transfer_matches,
				"next normal NMI consumes the map-$2D 15-packet queue and applies all 51 nametable writes")
			print("Map-$2D NMI checkpoint: ", JSON.stringify({
				"nmi_status": map2d_nmi.get("status", ""),
				"queue_status": map2d_secondary_queue.get("status", ""),
				"queue_packets": map2d_secondary_queue.get("packet_count", -1),
				"bus_events": map2d_nmi_bus_events.size(),
				"render_status": map2d_ppu_render.get("status", ""),
				"nametable_writes": map2d_ppu_render.get("nametable_writes_applied", -1),
				"unapplied": map2d_ppu_render.get("unapplied_writes", []).size()}))
		if final_frame >= 9055:
			var batch_indices: Array[int] = []
			var batch_frames: Array[int] = []
			var batch_summaries: Array[Dictionary] = []
			var batches_source_matched := not _map2d_observed_batches.is_empty()
			for observed_variant in _map2d_observed_batches:
				var observed: Dictionary = observed_variant
				var batch: Dictionary = observed.get("batch", {})
				batch_indices.append(int(batch.get("batch_start_map_index", -1)))
				batch_frames.append(int(observed.get("source_frame", -1)))
				var call_summaries: Array[Dictionary] = []
				for call_variant in batch.get("map_calls", []):
					if call_variant is Dictionary:
						var call: Dictionary = call_variant
						call_summaries.append({"id": call.get("block_id", -1),
							"placement": call.get("placement", -1),
							"ppu": call.get("ppu_address", -1)})
				var source_match := _map2d_batch_source_matches(batch)
				batches_source_matched = batches_source_matched and source_match
				batch_summaries.append({"index": batch.get("batch_start_map_index", -1),
					"status": batch.get("status", ""), "count": batch.get("batch_cell_count", -1),
					"placement": batch.get("batch_start_placement", -1),
					"queue_size": (batch.get("queue_bytes", PackedByteArray()) as PackedByteArray).size(),
					"source_match": source_match, "calls": call_summaries})
			var expected_batch_indices: Array[int] = []
			var last_batch_index := int(batch_indices.back()) if not batch_indices.is_empty() else -1
			for map_index in range(0, 32, 3):
				if map_index <= last_batch_index:
					expected_batch_indices.append(map_index)
			_check(batch_indices == expected_batch_indices and batches_source_matched,
				"each observed map-$2D batch is an uninterrupted source-indexed sequence with ROM-matched tile/attribute packet bytes")
			print("Map-$2D batch sequence: ", JSON.stringify({
				"indices": batch_indices,
				"source_frames": batch_frames,
				"source_matched": batches_source_matched,
				"expected_indices": expected_batch_indices,
				"batch_details": batch_summaries}))
		var final_runner_status: Dictionary = stop_route_status.get("fresh_source_route", {})
		var prior_actor_loop: Dictionary = final_runner_status.get("last_root_actor_loop_result", {})
		var prior_actor_records: Array[Dictionary] = []
		for actor_variant in prior_actor_loop.get("actor_records", []):
			if not actor_variant is Dictionary:
				continue
			var actor: Dictionary = actor_variant
			var actor_bytes: Variant = actor.get("bytes", PackedByteArray())
			if not actor_bytes is PackedByteArray or (actor_bytes as PackedByteArray).size() != 21:
				continue
			var bytes: PackedByteArray = actor_bytes
			prior_actor_records.append({
				"index": actor.get("actor_index", -1), "address": actor.get("cpu_address", -1),
				"flag": bytes[0], "appearance_pointer": bytes[3] | (bytes[4] << 8),
				"appearance_timer": bytes[0x10], "appearance_descriptor": bytes[0x12],
			})
		print("Last successful root actor loop before PASS route stop: ", JSON.stringify({
			"source_frame": prior_actor_loop.get("source_frame", -1),
			"status": prior_actor_loop.get("status", "none"),
			"active_actor_count": prior_actor_loop.get("actor_loop", {}).get("active_actor_count", -1),
			"actors": prior_actor_records,
		}))
		var final_dispatch: Dictionary = final_runner_status.get("last_first_action_menu_dispatch_result", {})
		var final_adoption: Dictionary = final_runner_status.get("last_first_action_menu_adoption_result", {})
		var final_nmi_status: Dictionary = stop_route_status.get("fresh_source_route_nmi", {})
		var final_task_status: Dictionary = stop_route_status.get("fresh_source_route_task", {})
		var final_map_batch: Dictionary = final_task_status.get("map_batch_result", {})
		var latest_route_gap := ""
		var route_gaps: Array = stop_route_status.get("route_gaps", [])
		if not route_gaps.is_empty():
			latest_route_gap = String(route_gaps.back())
		var slot09_debug_boundary: Dictionary = {}
		if route._fresh_source_route_runner != null:
			slot09_debug_boundary = route._fresh_source_route_runner._scheduler.get_task_boundary_snapshot(0x09)
		var slot09_debug_ram: PackedByteArray = slot09_debug_boundary.get("ram_image", PackedByteArray())
		var slot09_debug_cpu: Dictionary = {
			"pc": slot09_debug_boundary.get("pc", -1), "sp": slot09_debug_boundary.get("sp", -1),
			"a": slot09_debug_boundary.get("a", -1), "x": slot09_debug_boundary.get("x", -1),
			"y": slot09_debug_boundary.get("y", -1), "p": slot09_debug_boundary.get("p", -1),
			"bank_low": slot09_debug_boundary.get("bank_low", -1),
			"bank_high": slot09_debug_boundary.get("bank_high", -1),
		}
		print("Slot-$09 live callback diagnostic: ", JSON.stringify({
			"runner_error": final_runner_status.get("error", ""),
			"slot09_resume_input": final_runner_status.get("last_slot09_resume_input_debug", {}),
			"boundary": slot09_debug_cpu,
			"record": (slot09_debug_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
			"scenario_0516_0539": slot09_debug_ram.slice(0x0516, 0x053A).hex_encode() if slot09_debug_ram.size() == 0x800 else "invalid",
			"map_05c7_05d2": slot09_debug_ram.slice(0x05C7, 0x05D3).hex_encode() if slot09_debug_ram.size() == 0x800 else "invalid",
			"stack_0170_0180": slot09_debug_boundary.get("stack_page", PackedByteArray()).slice(0x70, 0x81).hex_encode()
				if (slot09_debug_boundary.get("stack_page", PackedByteArray()) as PackedByteArray).size() == 0x100 else "invalid",
		}))
		var slot05_worker_result: Dictionary = final_task_status.get("slot05_worker_result", {})
		var slot05_worker_calls: Array[Dictionary] = []
		for call_variant in slot05_worker_result.get("calls", []):
			if call_variant is Dictionary:
				var call: Dictionary = call_variant
				slot05_worker_calls.append({"bank": call.get("bank", -1),
					"callsite": call.get("callsite", -1), "target": call.get("target", -1),
					"return_pc": call.get("return_pc", -1)})
		var slot05_worker_tail_pcs: Array[int] = []
		for instruction_variant in slot05_worker_result.get("instructions", []):
			if instruction_variant is Dictionary:
				slot05_worker_tail_pcs.append(int(instruction_variant.get("pc", -1)))
		var slot05_worker_ram: PackedByteArray = slot05_worker_result.get("ram_image", PackedByteArray())
		print("Slot-$05 live worker boundary: ", JSON.stringify({
			"status": final_task_status.get("status", ""),
			"exit_kind": slot05_worker_result.get("exit_kind", ""),
			"exit_pc": slot05_worker_result.get("exit_pc", -1),
			"exit_bank": slot05_worker_result.get("exit_bank", -1),
			"registers": slot05_worker_result.get("registers", {}),
			"mapper": slot05_worker_result.get("mapper", {}),
			"entry_mapper": slot05_worker_result.get("entry_mapper", {}),
			"source_dispatch": slot05_worker_result.get("source_dispatch", {}),
			"field_input_loop_yield_validated": route._fresh_source_route_runner._scheduler \
				.validate_slot05_field_input_loop_yield_worker_result(slot05_worker_result) \
				if route._fresh_source_route_runner != null else false,
			"blocked_read": slot05_worker_result.get("blocked_read", {}),
			"calls": slot05_worker_calls,
			"tail_pcs": slot05_worker_tail_pcs.slice(maxi(0, slot05_worker_tail_pcs.size() - 16)),
			"executed_spans": slot05_worker_result.get("executed_source_spans", []),
			"ram_0515_0518": slot05_worker_ram.slice(0x0515, 0x0519).hex_encode()
				if slot05_worker_ram.size() == 0x800 else "invalid",
			"ram_0430_0432": slot05_worker_ram.slice(0x0430, 0x0432).hex_encode()
				if slot05_worker_ram.size() == 0x800 else "invalid",
			"ram_05fc_0639": slot05_worker_ram.slice(0x05FC, 0x0639).hex_encode()
				if slot05_worker_ram.size() == 0x800 else "invalid",
		}))
		var pass_receiver_first_yield: Dictionary = {}
		if route._fresh_source_route_runner != null:
			pass_receiver_first_yield = route._fresh_source_route_runner._last_slot05_pass_receiver_first_yield_result
		var pass_receiver_first_regs: Dictionary = pass_receiver_first_yield.get("registers", {})
		var pass_receiver_first_mapper: Dictionary = pass_receiver_first_yield.get("mapper", {})
		var pass_receiver_first_ram: PackedByteArray = pass_receiver_first_yield.get("ram_image", PackedByteArray())
		var pass_receiver_first_stack: PackedByteArray = pass_receiver_first_yield.get("stack_page", PackedByteArray())
		print("PASS receiver descriptor-$0F first-yield signature: ", JSON.stringify({
			"status": pass_receiver_first_yield.get("status", ""),
			"route_boundary_observed": pass_receiver_first_yield.get("route_boundary_observed", false),
			"input_boundary_fixture": pass_receiver_first_yield.get("input_boundary_fixture", true),
			"source_manifest_sha256": pass_receiver_first_yield.get("source_manifest_sha256", ""),
			"registers": pass_receiver_first_regs,
			"mapper": pass_receiver_first_mapper,
			"ram_0005_0009": pass_receiver_first_ram.slice(0x0005, 0x0009).hex_encode()
				if pass_receiver_first_ram.size() == 0x800 else "invalid",
			"ram_0050_0051": pass_receiver_first_ram.slice(0x0050, 0x0052).hex_encode()
				if pass_receiver_first_ram.size() == 0x800 else "invalid",
			"ram_0515_0519": pass_receiver_first_ram.slice(0x0515, 0x0519).hex_encode()
				if pass_receiver_first_ram.size() == 0x800 else "invalid",
			"stack_mirror_matches": pass_receiver_first_ram.slice(0x0100, 0x0200) == pass_receiver_first_stack
				if pass_receiver_first_stack.size() == 0x100 else false,
			"stack_0038_003A": pass_receiver_first_stack.slice(0x38, 0x3B).hex_encode()
				if pass_receiver_first_stack.size() == 0x100 else "invalid",
		}))
		print("First PASS input edge check: stop_frame=%d stage=%s input=[%s,%s] slot05_pc=$%04X runner_phase=%s boundary=%s nmi=[%s@%s,next_slot=%s] task=[%s,map=%s,index=%s,placement=$%02X] dispatch=%s/%s adoption=%s/%s latest_gap=%s" % [
			stop_frame, String(stop_route_status.get("stage", "")),
			String(selection_sample.get("source_poll_status", "")),
			String(confirmation_sample.get("source_poll_status", "")),
			int(slot05_boundary.get("pc", -1)), String(final_runner_status.get("phase", "")),
			String(final_runner_status.get("source_boundary", "")),
			String(final_nmi_status.get("status", "")), str(final_nmi_status.get("source_frame", -1)),
			str(final_nmi_status.get("next_selected_task_slot", final_nmi_status.get("selected_task_slot", -1))),
			String(final_task_status.get("status", "")), str(final_map_batch.get("map_id", -1)),
			str(final_map_batch.get("batch_start_map_index", -1)),
			int(final_map_batch.get("batch_start_placement", -1)),
			String(final_dispatch.get("status", "")), String(final_dispatch.get("error", "")),
			String(final_adoption.get("status", "")), String(final_adoption.get("error", "")),
			latest_route_gap])
		if final_frame < FIRST_PASS_DECISION_FRAME:
			route.queue_free()
			await process_frame
			quit(1 if _failures > 0 else 0)
			return
	if final_frame >= 8803:
		_check(_slot11_alignment_sample_count >= 18 and _slot11_alignment_mismatches.is_empty(),
			"slot-$11 animation pointer, `$05F3-$05F5` counters, and `$0515` queue flag match same-frame FCEUX RAM for frames 8783–8797 and 8801 through the stop (samples=%d mismatches=%s)" % [
				_slot11_alignment_sample_count, str(_slot11_alignment_mismatches)])
	elif final_frame >= 8797:
		_check(_slot11_alignment_sample_count >= 15 and _slot11_alignment_mismatches.is_empty(),
			"slot-$11 animation pointer, `$05F3-$05F5` counters, and `$0515` queue flag match same-frame FCEUX RAM for frames 8783–8797 (samples=%d mismatches=%s)" % [
				_slot11_alignment_sample_count, str(_slot11_alignment_mismatches)])
	_verify_eb_post_wait_route_batches(route, stop_frame)
	_verify_f9_return_boundary(final_frame)
	var reached_menu := bool(stop_route_status.get("first_action_menu_complete", false))
	var expects_first_pass_decision_wait := check_first_pass_input \
			and final_frame >= FIRST_PASS_DECISION_FRAME
	var reached_first_pass_decision_wait := expects_first_pass_decision_wait \
			and _is_first_pass_decision_wait_endpoint(route, stop_route_status, stop_frame)
	var menu_endpoint_reached := reached_menu and not expects_first_pass_decision_wait
	var stopped_after_a611 := stopped_at_811f or stopped_at_812f or stopped_at_a64c
	var cold_start_mode: Dictionary = stop_route_status.get("cold_start_nmi_mode_receipt", {})
	_check(bool(cold_start_mode.get("ok", false))
		and int(cold_start_mode.get("known_bit_mask", 0)) == 0xFF
		and int(cold_start_mode.get("known_bit_value", 0)) == 0x40
		and not bool(cold_start_mode.get("full_byte_known_at_later_route_boundary", true)),
		"route exposes the ROM-derived cold-start `$001B.6` receipt without treating it as live wait RAM")
	var route_mode_bits: Dictionary = stop_route_status.get("nmi_mode_route_bit_receipt", {})
	_check(bool(route_mode_bits.get("ok", false))
		and int(route_mode_bits.get("known_bit_mask", 0)) == 0x7F
		and int(route_mode_bits.get("known_bit_value", 0)) == 0x40,
		"route carries the source-validated `$001B` low-seven-bit invariant")
	var final_handoff: Dictionary = stop_route_status.get("cutscene_wait_cleanup", {})
	if stopped_after_a611:
		var debug_wait: Dictionary = final_handoff.get("a503_input_wait_result", {})
		var debug_fade: Dictionary = final_handoff.get("a503_postwait_fade_result", {})
		var debug_packets: Array = debug_fade.get("packet_history", [])
		var first_packet: Dictionary = debug_packets.front() if not debug_packets.is_empty() else {}
		var last_packet: Dictionary = debug_packets.back() if not debug_packets.is_empty() else {}
		var debug_clear: Dictionary = debug_fade.get("clear_result", {})
		print("A503 endpoint diagnostic: ", JSON.stringify({
			"route_frame": route.source_frame,
			"wait_status": debug_wait.get("status", ""),
			"wait_frame": debug_wait.get("source_frame", -1),
			"wait_tick_count": debug_wait.get("wait_tick_count", -1),
			"wait_cpu": debug_wait.get("details", {}).get("cpu", {}),
			"wait_sample": debug_wait.get("details", {}).get("controller_sample", {}),
			"fade_status": debug_fade.get("status", ""),
			"counter_a": debug_fade.get("fade_status", {}).get("counter_a", -1),
			"counter_b": debug_fade.get("fade_status", {}).get("counter_b", -1),
			"packet_count": debug_packets.size(),
			"first_packet_frames": [first_packet.get("producer_source_frame", -1), first_packet.get("consumer_source_frame", -1)],
			"last_packet_frames": [last_packet.get("producer_source_frame", -1), last_packet.get("consumer_source_frame", -1)],
			"clear_status": debug_clear.get("status", ""),
			"clear_write_count": debug_clear.get("ppu_clear", {}).get("write_count", -1),
		}))
	var wait_caller_for_stack: Dictionary = final_handoff.get("post_helper_caller_result", {})
	var wait_prefix_for_stack: Dictionary = wait_caller_for_stack.get(
		"match_preset_loader_prefix_result", {})
	var wait_stack_contract: Dictionary = wait_prefix_for_stack.get("stack_contract", {})
	var wait_stack_page: PackedByteArray = wait_prefix_for_stack.get("stack_after", PackedByteArray())
	if not wait_prefix_for_stack.is_empty() or stopped_at_preset_wait:
		_check(String(wait_stack_contract.get("model", "")) == "physical_stack_page" \
			and bool(wait_stack_contract.get("absolute_sp_known", false)) \
			and int(wait_stack_contract.get("sp_at_893b", -1)) == 0x26 \
			and wait_stack_page.size() == 0x100 \
			and int(wait_stack_page[0x25]) == 0x3A \
			and int(wait_stack_page[0x26]) == 0x89 \
			and int(wait_stack_page[0x27]) == 0x16 \
			and int(wait_stack_page[0x28]) == 0x81,
			"ROM `$8114` wait caller and nested helper return bytes reach `$893B` on the physical stack page")
	if stopped_at_preset_wait:
		var prior_wait_latch: Dictionary = wait_prefix_for_stack.get("prior_nmi_wait_latch", {})
		var preset_wait_ram: Dictionary = wait_caller_for_stack.get("caller_ram_at_preset_wait", {})
		_check(bool(prior_wait_latch.get("used", false))
			and int(prior_wait_latch.get("source_pc", -1)) == 0xA0A6
			and String(prior_wait_latch.get("source_event_id", "")) == "fresh_match_selector_frame8_nmi"
			and int(preset_wait_ram.get(0x0078, -1)) == 0x04,
			"executed frame-8 NMI `$A0A6` write arms `$78=$04` before the `$893B` loop")
	if OS.get_environment("CT2_ROUTE_DEBUG_IRQ_CONTEXT").strip_edges() == "1":
		var wait_caller: Dictionary = final_handoff.get("post_helper_caller_result", {})
		var wait_cpu: Dictionary = wait_caller.get("cpu_output_contract", {})
		var wait_ram: Dictionary = wait_caller.get("caller_ram_at_preset_wait", {})
		var irq_ram: Dictionary = {}
		for address in [0x001B, 0x0020, 0x0021, 0x0022, 0x0023, 0x0025,
				0x003B, 0x003C, 0x003D, 0x003E, 0x0078, 0x0079, 0x007C,
				0x007D, 0x007E, 0x0090, 0x0091]:
			irq_ram["$%04X" % address] = wait_ram.get(address, "unknown")
		print("IRQ context route CPU: ", JSON.stringify(wait_cpu))
		print("IRQ context selector CPU: ", JSON.stringify(wait_caller.get("selector_cpu_output_contract", {})))
		print("IRQ context selector stack: ", JSON.stringify(wait_caller.get("match_selector_result", {}).get("stack_after", {})))
		print("IRQ context prefix stack: ", JSON.stringify(wait_caller.get("match_preset_loader_prefix_result", {}).get("stack_contract", {})))
		print("IRQ context selector clock: ", JSON.stringify(wait_caller.get("selector_timing_clock", {}).get("return_source_cycle_provenance", -1)))
		print("IRQ context normalizer cycles: ", JSON.stringify(wait_caller.get("match_normalize_result", {}).get("cpu_cycles_without_interrupts_from_80FD", -1)))
		print("IRQ context preset cycles: ", JSON.stringify(wait_caller.get("match_preset_loader_prefix_result", {}).get("cpu_cycles_without_interrupts_from_8112", -1)))
		print("IRQ context route RAM: ", JSON.stringify(irq_ram))
		print("IRQ context mapper: ", JSON.stringify(wait_caller.get("mapper_shadow_state", {})))
		print("IRQ context PPU shadows: ", JSON.stringify(stop_route_status.get("source_ppu_shadow_state", {})))
	_print_selector_nmi_input_audit(final_handoff)
	var stop_source_route: Dictionary = stop_route_status.get("fresh_source_route", {})
	var scenario44_task_result: Dictionary = stop_route_status.get("fresh_source_route_task", {})
	var scenario44_field_handoff: Dictionary = scenario44_task_result.get("scenario44_field_handoff_result", {})
	var scenario44_field_entry: Dictionary = scenario44_task_result.get("scenario44_field_entry_result", {})
	var scenario44_field_entry_phase := String(stop_source_route.get("phase", ""))
	var stopped_at_scenario44_field_boundary := scenario44_field_entry_phase in [
		"stopped_at_scenario44_field_source_boundary",
		"stopped_at_scenario44_field_entry_call_boundary"]
	var scenario44_entry_span_seen := false
	for span_variant in scenario44_field_entry.get("executed_source_spans", []):
		if span_variant is Dictionary \
				and String(span_variant.get("file", "")) == "bank1a_field_entry_8003_A000.bin" \
				and String(span_variant.get("sha256", "")) == "cfcde4d67358fc36a7e7e67e039d7f36a046a215bcd55b962eb7decac6a7e5fd":
			scenario44_entry_span_seen = true
	if stopped_at_scenario44_field_boundary:
		_check(String(stop_route_status.get("stage", "")) == "source_route_gap" \
			and bool(scenario44_field_entry.get("ok", false)) \
			and String(scenario44_field_entry.get("status", "")) in [
				"scenario44_field_entry_source_boundary",
				"scenario44_field_entry_source_call_boundary",
				"scenario44_field_entry_instruction_bound"] \
			and String(scenario44_field_handoff.get("status", "")) == "scenario44_field_runtime_entered" \
			and int(scenario44_field_handoff.get("exit_pc", -1)) == 0x8003 \
			and (scenario44_field_handoff.get("oam_writes", []) as Array).size() == 64 \
			and (scenario44_field_handoff.get("mapper_writes", []) as Array).size() == 4 \
			and scenario44_entry_span_seen \
			and int(scenario44_field_entry.get("instruction_count", 0)) > 0,
			"recorded-input route executes scenario-$44 `$E38F->$8003`, then ROM-derived bank-$1A entry code to its next boundary")
	var descriptor_checkpoint: Dictionary = _stage_at_checkpoints.get(8782, {})
	var descriptor_source_route: Dictionary = descriptor_checkpoint.get("fresh_source_route", stop_source_route)
	var stopped_before_scenario36_slot09 := String(stop_source_route.get("phase", "")) \
		== "stopped_before_scenario36_slot09_dispatch"
	var field_entry_nmi: Dictionary = descriptor_checkpoint.get("fresh_source_route_nmi",
		stop_route_status.get("fresh_source_route_nmi", {}))
	var field_renderer_entry: Dictionary = field_entry_nmi.get("renderer_entry_result", {})
	var field_renderer_worker: Dictionary = field_entry_nmi.get("renderer_worker_result", {})
	var field_worker_registers: Dictionary = field_renderer_worker.get("registers", {})
	var field_worker_mapper: Dictionary = field_renderer_worker.get("mapper", {})
	var field_post_worker_scan: Dictionary = field_entry_nmi.get("post_worker_scan", {})
	var field_slot05_after_yield: Dictionary = field_entry_nmi.get("slot05_after_worker_yield", {})
	var field_slot05_yield_record: PackedByteArray = field_slot05_after_yield.get("record", PackedByteArray())
	var renderer_registers: Dictionary = field_renderer_entry.get("registers", {})
	var renderer_mapper: Dictionary = field_renderer_entry.get("mapper", {})
	var renderer_p_known_mask := int(renderer_registers.get("p_known_mask", -1))
	var reached_scenario36_e0df := String(field_entry_nmi.get("status", "")) == "scenario36_descriptor00_worker_yielded_and_scanned" \
		and String(field_entry_nmi.get("handoff_result", {}).get("status", "")) == "scenario36_queue_returned_to_e0df" \
		and String(field_renderer_entry.get("status", "")) == "field_entry_first_renderer_wrapper_returned_to_bank18" \
		and int(field_renderer_entry.get("exit_pc", -1)) == 0x800C \
		and int(renderer_registers.get("a", -1)) == 0x00 \
		and int(renderer_registers.get("x", -1)) == 0x50 \
		and int(renderer_registers.get("y", -1)) == 0x00 \
		and renderer_p_known_mask >= 0 \
		and ((int(renderer_registers.get("p", -1)) ^ 0x33) & renderer_p_known_mask) == 0 \
		and int(renderer_registers.get("sp", -1)) == 0x4A \
		and int(renderer_mapper.get("bank_low", -1)) == 0x18 \
		and int(renderer_mapper.get("bank_high", -1)) == 0x19 \
		and int(renderer_mapper.get("select", -1)) == 0x07 \
		and String(field_renderer_worker.get("entry_profile", "")) == "field_entry_e0df_first_renderer" \
		and int(field_renderer_worker.get("exit_pc", -1)) == 0xC515 \
		and int(field_worker_registers.get("a", -1)) == 0x01 \
		and int(field_worker_registers.get("x", -1)) == 0xFF \
		and int(field_worker_registers.get("y", -1)) == 0x00 \
		and int(field_worker_registers.get("p", -1)) == 0x20 \
		and int(field_worker_registers.get("sp", -1)) == 0x48 \
		and int(field_worker_mapper.get("bank_low", -1)) == 0x18 \
		and int(field_worker_mapper.get("bank_high", -1)) == 0x19 \
		and int(field_worker_mapper.get("select", -1)) == 0x07 \
		and bool(field_post_worker_scan.get("ok", false)) \
		and int(field_post_worker_scan.get("decision", -1)) >= 0 \
		and int(field_post_worker_scan.get("decision", -1)) <= 2 \
		and field_slot05_yield_record == PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
		and int(field_slot05_after_yield.get("pc", -1)) == 0xCB0F \
		and int(field_slot05_after_yield.get("sp", -1)) == 0x46 \
		and int(field_slot05_after_yield.get("ready_delay", -1)) == 0x01 \
		and int(field_slot05_after_yield.get("ram_007F", -1)) == 0x01
	var stopped_at_scenario36_e0df := reached_scenario36_e0df \
		and String(descriptor_source_route.get("phase", "")) == "stopped_after_scenario36_descriptor00_worker_yield"
	var slot15_task_result: Dictionary = stop_route_status.get("fresh_source_route_task", {})
	var slot15_callback_result: Dictionary = slot15_task_result.get("callback_handler_result", {})
	var slot15_map_entry: Dictionary = slot15_task_result.get("callback_map_worker_entry_result", {})
	var slot15_map_setup: Dictionary = slot15_task_result.get("map_worker_setup_result", {})
	var slot15_map_batch: Dictionary = slot15_task_result.get("map_batch_result", {})
	var slot15_map_batch_boundary: Dictionary = slot15_task_result.get("selected_slot_boundary", {})
	var slot15_map_batch_ram: PackedByteArray = slot15_map_batch_boundary.get("ram_image", PackedByteArray())
	var slot15_map_batch_output_ram: PackedByteArray = slot15_map_batch.get("updated_ram", PackedByteArray())
	var slot15_map_batch_queue: PackedByteArray = slot15_map_batch.get("queue_bytes", PackedByteArray())
	var slot15_map_batch_calls: Array = slot15_map_batch.get("map_calls", [])
	var slot15_nmi_result: Dictionary = stop_route_status.get("fresh_source_route_nmi", {})
	var slot15_normal_nmi: Dictionary = slot15_nmi_result.get("normal_nmi_result",
		slot15_nmi_result.get("nmi_result", {}))
	var slot15_secondary_queue: Dictionary = slot15_normal_nmi.get("secondary_queue", {})
	var slot15_nmi_bus_events: Array = slot15_normal_nmi.get("ppu_bus_events", [])
	var slot15_ppu_render: Dictionary = slot15_nmi_result.get("ppu_render_result", {})
	var map36_batch_start_index := int(slot15_map_batch.get("batch_start_map_index", -1))
	var map2d_batch_start_index := int(slot15_map_batch.get("batch_start_map_index", -1))
	var map2d_batch_calls_valid := _map2d_batch_source_matches(slot15_map_batch)
	var map36_source_bytes: PackedByteArray = FileAccess.get_file_as_bytes(MAP36_BLOCK_MAP_PATH)
	var map36_source_valid: bool = map36_source_bytes.size() == 0x20 \
		and FileAccess.get_sha256(MAP36_BLOCK_MAP_PATH) == MAP36_BLOCK_MAP_SHA256
	var map36_expected_calls := PackedByteArray()
	if map36_source_valid and map36_batch_start_index >= 0 \
			and map36_batch_start_index < map36_source_bytes.size():
		for source_index in range(map36_batch_start_index,
				mini(map36_batch_start_index + 3, map36_source_bytes.size())):
			map36_expected_calls.append(map36_source_bytes[source_index])
	var map36_expected_queue_prefixes: Array[PackedByteArray] = []
	for expected_index in map36_expected_calls.size():
		var expected_placement := 0x80 + map36_batch_start_index + expected_index
		var expected_ppu_address := 0x2000 | ((expected_placement & 0x38) << 4) \
			| ((expected_placement & 0xC0) << 4) | ((expected_placement & 0x07) << 2)
		map36_expected_queue_prefixes.append(PackedByteArray([0x04,
			expected_ppu_address & 0xFF, (expected_ppu_address >> 8) & 0xFF]))
	var map36_batch_call_ids_valid: bool = map36_source_valid \
		and slot15_map_batch_calls.size() == map36_expected_calls.size() \
		and map36_expected_calls.size() == int(slot15_map_batch.get("batch_cell_count", -1))
	if map36_batch_call_ids_valid:
		for call_index in map36_expected_calls.size():
			var call: Dictionary = slot15_map_batch_calls[call_index]
			var block_id := int(map36_expected_calls[call_index])
			var tiles_path := MAP36_METATILE_DIR + "map_36_metatile_%02X_tiles.bin" % block_id
			var attribute_path := MAP36_METATILE_DIR + "map_36_metatile_%02X_attribute.bin" % block_id
			var expected_placement := 0x80 + map36_batch_start_index + call_index
			var expected_ppu_address := 0x2000 | ((expected_placement & 0x38) << 4) \
				| ((expected_placement & 0xC0) << 4) | ((expected_placement & 0x07) << 2)
			if int(call.get("block_id", -1)) != block_id \
					or int(call.get("map_index", -1)) != map36_batch_start_index + call_index \
					or int(call.get("placement", -1)) != expected_placement \
					or int(call.get("ppu_address", -1)) != expected_ppu_address \
					or not FileAccess.file_exists(tiles_path) or not FileAccess.file_exists(attribute_path):
				map36_batch_call_ids_valid = false
				break
			var tiles := FileAccess.get_file_as_bytes(tiles_path)
			var attribute := FileAccess.get_file_as_bytes(attribute_path)
			if tiles.size() != 0x10 or attribute.size() != 1 \
					or FileAccess.get_sha256(tiles_path) != String(call.get("tile_source_sha256", "")) \
					or FileAccess.get_sha256(attribute_path) != String(call.get("attribute_source_sha256", "")) \
					or slot15_map_batch_queue.slice(call_index * 0x20,
						(call_index + 1) * 0x20) != _map36_expected_packet_group(
							expected_placement, tiles, int(attribute[0])):
				map36_batch_call_ids_valid = false
				break
	var map36_expected_output_placement := 0x80 + map36_batch_start_index \
		+ int(slot15_map_batch.get("batch_cell_count", 0))
	var map36_expected_output_remaining := 0x20 - map36_batch_start_index \
		- int(slot15_map_batch.get("batch_cell_count", 0))
	var map36_prior_batch_ppu_applied: bool = String(slot15_secondary_queue.get("status", "")) == "transferred" \
		and String(slot15_secondary_queue.get("branch", "")) == "secondary_queue_consumed" \
		and String(slot15_secondary_queue.get("queue_kind", "")) == "secondary" \
		and int(slot15_secondary_queue.get("packet_count", -1)) == 15 \
		and int(slot15_secondary_queue.get("ready_flag_before", -1)) == 0x80 \
		and int(slot15_secondary_queue.get("ready_flag_after", -1)) == 0 \
		and slot15_nmi_bus_events.size() == 96 \
		and bool(slot15_nmi_result.get("ppu_bus_events_applied", false)) \
		and bool(slot15_ppu_render.get("ok", false)) \
		and String(slot15_ppu_render.get("status", "")) == "applied" \
		and int(slot15_ppu_render.get("nametable_writes_applied", -1)) == 51 \
		and slot15_ppu_render.get("unapplied_writes", []).is_empty()
	var stopped_at_slot15_map36_busy_yield: bool = String(slot15_task_result.get("status", "")) == "slot15_map36_batch_yielded" \
		and String(stop_route_status.get("stage", "")) == "source_route_waiting_for_nmi" \
		and String(stop_source_route.get("phase", "")) == "awaiting_external_nmi" \
		and String(stop_source_route.get("source_boundary", "")).contains("slot-$15 map-$36 batch save -> scheduler WAIT_FOR_NMI_READY") \
		and String(slot15_map_batch.get("status", "")) == "map_worker_queue_busy_yield_at_856F" \
		and int(slot15_map_batch.get("map_id", -1)) == 0x36 \
		and int(slot15_map_batch.get("exit_pc", -1)) == 0x856F \
		and int(slot15_map_batch.get("queue_busy_flag", -1)) == 0x80 \
		and int(slot15_map_batch_boundary.get("slot_base", -1)) == 0x15 \
		and int(slot15_map_batch_boundary.get("pc", -1)) == 0xCB0F \
		and slot15_map_batch_boundary.get("record", PackedByteArray()) == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C]) \
		and slot15_map_batch_ram.size() == 0x800 \
		and slot15_map_batch_ram.slice(0x05C7, 0x05CA) == PackedByteArray([0x24, 0x80, 0x20]) \
		and int(slot15_map_batch_ram[0x05CA]) == 0x01 \
		and int(slot15_map_batch_ram[0x05CC]) == 0x36 \
		and int(slot15_map_batch_ram[0x0515]) == 0x80
	var stopped_at_slot15_map36_rows_yield: bool = String(slot15_task_result.get("status", "")) == "slot15_map36_batch_yielded" \
		and String(stop_route_status.get("stage", "")) == "source_route_waiting_for_nmi" \
		and String(stop_source_route.get("phase", "")) == "awaiting_external_nmi" \
		and String(stop_source_route.get("source_boundary", "")).contains("slot-$15 map-$36 batch save -> scheduler WAIT_FOR_NMI_READY") \
		and String(slot15_map_batch.get("status", "")) == "map36_%d_metatiles_ready_at_yield" % int(slot15_map_batch.get("batch_cell_count", 0)) \
		and int(slot15_map_batch.get("map_id", -1)) == 0x36 \
		and int(slot15_map_batch.get("entry_pc", -1)) == 0x8572 \
		and int(slot15_map_batch.get("callsite_pc", -1)) == 0x856F \
		and map36_batch_start_index >= 0 and map36_batch_start_index < 0x20 \
		and map36_batch_start_index % 3 == 0 \
		and int(slot15_map_batch.get("batch_start_placement", -1)) == 0x80 + map36_batch_start_index \
		and int(slot15_map_batch.get("batch_cell_count", -1)) == map36_expected_calls.size() \
		and slot15_map_batch_queue.size() == map36_expected_calls.size() * 0x20 \
		and _map36_queue_prefixes_match(slot15_map_batch_queue, map36_expected_queue_prefixes) \
		and map36_batch_call_ids_valid \
		and slot15_map_batch_output_ram.size() == 0x800 \
		and slot15_map_batch_output_ram.slice(0x05C7, 0x05CA) == PackedByteArray([slot15_map_batch_queue.size() & 0xFF, map36_expected_output_placement, map36_expected_output_remaining]) \
		and int(slot15_map_batch_output_ram[0x05CC]) == 0x36 \
		and int(slot15_map_batch_output_ram[0x0515]) == 0x80 \
		and (map36_batch_start_index == 0 or map36_prior_batch_ppu_applied) \
		and not bool(slot15_map_batch.get("trace_state_used", true))
	if String(slot15_task_result.get("status", "")) == "slot15_map36_batch_yielded":
		var map36_call_audit: Array[Dictionary] = []
		for call_variant in slot15_map_batch_calls:
			if call_variant is Dictionary:
				var call: Dictionary = call_variant
				map36_call_audit.append({"block_id": call.get("block_id", -1),
					"placement": call.get("placement", -1), "ppu_address": call.get("ppu_address", -1),
					"tile_sha256": call.get("tile_source_sha256", ""),
					"attribute_sha256": call.get("attribute_source_sha256", "")})
		print("Map-$36 batch checkpoint: ", JSON.stringify({
			"route_boundary": stop_source_route.get("source_boundary", ""),
			"task_status": slot15_task_result.get("status", ""),
			"batch_status": slot15_map_batch.get("status", ""),
			"map_index": slot15_map_batch.get("batch_start_map_index", -1),
			"placement": slot15_map_batch.get("batch_start_placement", -1),
			"queue_size": slot15_map_batch_queue.size(),
			"queue_prefixes": _map36_queue_prefix_hex(slot15_map_batch_queue,
				map36_expected_queue_prefixes.size()),
			"calls": map36_call_audit,
			"output_cursor": slot15_map_batch_output_ram.slice(0x05C7, 0x05CA).hex_encode()
				if slot15_map_batch_output_ram.size() == 0x800 else "invalid",
			"nmi_queue": {
				"status": slot15_secondary_queue.get("status", ""),
				"branch": slot15_secondary_queue.get("branch", ""),
				"queue_kind": slot15_secondary_queue.get("queue_kind", ""),
				"packet_count": slot15_secondary_queue.get("packet_count", -1),
				"ready_before": slot15_secondary_queue.get("ready_flag_before", -1),
				"ready_after": slot15_secondary_queue.get("ready_flag_after", -1),
				"bus_event_count": slot15_nmi_bus_events.size(),
			},
			"ppu_render": {
				"applied": slot15_nmi_result.get("ppu_bus_events_applied", false),
				"status": slot15_ppu_render.get("status", ""),
				"nametable_writes": slot15_ppu_render.get("nametable_writes_applied", -1),
				"unapplied_writes": slot15_ppu_render.get("unapplied_writes", []).size(),
			},
		}))
	var stopped_at_slot15_map36_yield: bool = String(stop_route_status.get("stage", "")) == "source_route_waiting_for_nmi" \
		and String(stop_source_route.get("phase", "")) == "awaiting_external_nmi" \
		and (String(stop_source_route.get("source_boundary", "")).contains("slot-$15 map-$36 worker reached `$856F->$C515`") \
			or String(stop_source_route.get("source_boundary", "")).contains("$CB0F slot-$15 map-$36 batch save -> scheduler WAIT_FOR_NMI_READY")) \
		and String(slot15_task_result.get("status", "")) in ["slot15_map_worker_yielded_waiting_nmi", "slot15_map36_batch_yielded"] \
		and int(slot15_callback_result.get("callback_id", -1)) == 0x45 \
		and int(slot15_map_entry.get("map_selector", -1)) == 0x36 \
		and int(slot15_map_setup.get("map_id", -1)) == 0x36 \
		and int(slot15_map_setup.get("map_selector", -1)) == 0x01 \
		and slot15_map_setup.get("chr_pair", PackedByteArray()) == PackedByteArray([0x00, 0x3C]) \
		and int(slot15_map_setup.get("yield_callsite", -1)) == 0x856F \
		and not bool(slot15_task_result.get("map_worker_rows_executed", true)) \
		and not bool(slot15_task_result.get("trace_state_used", true)) \
		or stopped_at_slot15_map36_busy_yield or stopped_at_slot15_map36_rows_yield
	var slot15_map_yield_boundary: Dictionary = slot15_task_result.get("slot15_yielded_boundary", {})
	var slot15_map_yield_record: PackedByteArray = slot15_map_yield_boundary.get("record", PackedByteArray())
	var slot15_map2d_first_batch: Dictionary = slot15_map_entry.get("map_2d_first_batch_source", {})
	var stopped_at_slot15_map2d_batch_yield: bool = String(stop_route_status.get("stage", "")) == "source_route_waiting_for_nmi" \
		and String(stop_source_route.get("phase", "")) == "awaiting_external_nmi" \
		and String(stop_source_route.get("source_boundary", "")).contains("slot-$15 map-$2D batch save -> scheduler WAIT_FOR_NMI_READY") \
		and String(slot15_task_result.get("status", "")) == "slot15_map2D_batch_yielded" \
		and String(slot15_map_batch.get("status", "")) == "map2D_3_metatiles_ready_at_yield" \
		and int(slot15_map_batch.get("entry_pc", -1)) == 0x8572 \
		and int(slot15_map_batch.get("callsite_pc", -1)) == 0x856F \
		and int(slot15_map_batch.get("map_id", -1)) == 0x2D \
		and int(slot15_map_batch.get("batch_start_map_index", -1)) == 0 \
		and map2d_batch_start_index == 0 \
		and int(slot15_map_batch.get("batch_start_placement", -1)) == 0x80 \
		and int(slot15_map_batch.get("batch_cell_count", -1)) == 3 \
		and map2d_batch_calls_valid \
		and int(slot15_map_batch_output_ram[0x0515]) == 0x80 \
		and slot15_map_batch_output_ram.slice(0x05C7, 0x05CA) == PackedByteArray([0x60, 0x83, 0x1D]) \
		and int(slot15_map_batch_output_ram[0x05CA]) == 0x02 \
		and int(slot15_map_batch_output_ram[0x05CC]) == 0x2D \
		and int(slot15_map_batch.get("mapper", {}).get("bank_low", -1)) == 0x0B \
		and int(slot15_map_batch.get("mapper", {}).get("bank_high", -1)) == 0x13 \
		and slot15_map_batch.get("ppu_bus_events", []).is_empty() \
		and not bool(slot15_map_batch.get("trace_state_used", true)) \
		and not bool(slot15_map_batch.get("source_cycle_timing_modeled", true))
	var stopped_at_slot15_map2d_initial_yield: bool = String(stop_route_status.get("stage", "")) == "source_route_waiting_for_nmi" \
		and String(stop_source_route.get("phase", "")) == "awaiting_external_nmi" \
		and String(stop_source_route.get("source_boundary", "")).contains("slot-$15 map-$2D worker reached `$856F->$C515`") \
		and String(slot15_task_result.get("status", "")) == "slot15_map_worker_yielded_waiting_nmi" \
		and int(slot15_callback_result.get("scenario", -1)) == 0x38 \
		and int(slot15_callback_result.get("callback_id", -1)) == 0x34 \
		and int(slot15_map_entry.get("map_selector", -1)) == 0x2D \
		and bool(slot15_map2d_first_batch.get("ok", false)) \
		and slot15_map2d_first_batch.get("first_batch_cell_ids", PackedByteArray()) == PackedByteArray([0x00, 0x71, 0x72]) \
		and int(slot15_map_setup.get("map_id", -1)) == 0x2D \
		and int(slot15_map_setup.get("map_selector", -1)) == 0x02 \
		and slot15_map_setup.get("chr_pair", PackedByteArray()) == PackedByteArray([0x00, 0x02]) \
		and slot15_map_setup.get("staged_chr_pair", PackedByteArray()) == PackedByteArray([0x80, 0x02]) \
		and int(slot15_map_setup.get("map_data_pointer", -1)) == 0x9104 \
		and int(slot15_map_setup.get("yield_callsite", -1)) == 0x856F \
		and int(slot15_map_yield_boundary.get("slot_base", -1)) == 0x15 \
		and int(slot15_map_yield_boundary.get("pc", -1)) == 0xCB0F \
		and slot15_map_yield_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C]) \
		and int(slot15_map_yield_boundary.get("active_task_slot", -1)) == -1 \
		and not bool(slot15_task_result.get("map_worker_rows_executed", true)) \
		and not bool(slot15_task_result.get("trace_state_used", true))
	var stopped_at_slot15_map2d_yield := stopped_at_slot15_map2d_initial_yield \
		or stopped_at_slot15_map2d_batch_yield
	_check(reached_scenario36_e0df,
		"recorded-input route executes the descriptor-$00 `$E0DF->$EF7F->$800C->$8851->$C515->$CB0F` path and scheduler save")
	var stopped_at_scenario36_yield := String(stop_route_status.get("fresh_source_route_task", {}).get("status", "")) \
		== "scenario36_queued_slot05_yielded_and_scheduler_scanned"
	var reached_scenario36_boundary := stopped_before_scenario36_slot09 and stopped_at_scenario36_yield
	var sparse_ram: Dictionary = stop_route_status.get("source_ram_image_at_893b", {})
	var known_ram_values: Dictionary = sparse_ram.get("known_values", {})
	var last_ram_writes: Dictionary = sparse_ram.get("last_write_by_address", {})
	var irq_selector_seed: Dictionary = stop_route_status.get("irq_chr_selector_init_receipt", {})
	var irq_selector_writes: Array = irq_selector_seed.get("ram_writes", [])
	_check(bool(irq_selector_seed.get("ok", false))
		and irq_selector_seed.get("source_pc_path", []) == [0x807F, 0x8081, 0x8083, 0x8085]
		and irq_selector_writes.size() == 2
		and int(irq_selector_writes[0].get("address", -1)) == 0x0090
		and int(irq_selector_writes[0].get("value", -1)) == 0x00
		and int(irq_selector_writes[0].get("source_pc", -1)) == 0x8081
		and int(irq_selector_writes[1].get("address", -1)) == 0x0091
		and int(irq_selector_writes[1].get("value", -1)) == 0x02
		and int(irq_selector_writes[1].get("source_pc", -1)) == 0x8085
		and int(known_ram_values.get(0x0090, -1)) == 0x00
		and int(known_ram_values.get(0x0091, -1)) == 0x02
		and int(last_ram_writes.get(0x0090, {}).get("source_pc", -1)) == 0x8081
		and int(last_ram_writes.get(0x0091, {}).get("source_pc", -1)) == 0x8085
		and not bool(irq_selector_seed.get("trace_state_used", true))
		and not bool(irq_selector_seed.get("emulator_data_used", true)),
		"ROM `$807F-$8086` initializes and carries `$0090/$0091` into the IRQ-source RAM ledger")
	var wait_ram_state: Dictionary = {}
	for address in [0x001B, 0x0078, 0x0079, 0x003B]:
		var address_key := "0x%04X" % address
		wait_ram_state[address_key] = known_ram_values.get(address, "unknown")
	print("Recorded route stop: frame=%d stage=%s phase=%s boundary=%s error=%s handoff=%s@%s" % [
		stop_frame, String(stop_route_status.get("stage", "")),
		String(stop_source_route.get("phase", "")),
		String(stop_source_route.get("source_boundary", "")),
		String(stop_source_route.get("error", "")),
		String(final_handoff.get("pending_helper_id", "")),
		String.num_int64(int(final_handoff.get("pending_source_pc", -1)), 16),
	])
	print("ROM-derived audio queue events at endpoint: ",
		JSON.stringify(_summarize_audio_queue_events(
			stop_route_status.get("sound_queue_write_events", []))))
	print("Godot audio presenter events at endpoint: ", JSON.stringify(_route_audio_player_events))
	if String(stop_route_status.get("stage", "")) == "source_route_gap":
		var stopped_task: Dictionary = stop_route_status.get("fresh_source_route_task", {})
		var descriptor: Dictionary = stopped_task.get("slot05_descriptor_contract", {})
		var worker_descriptor: Dictionary = stopped_task.get("slot05_worker_descriptor_contract", {})
		var worker_result: Dictionary = stopped_task.get("slot05_worker_result", {})
		var worker_registers: Dictionary = worker_result.get("registers", {})
		var worker_mapper: Dictionary = worker_result.get("mapper", {})
		var worker_ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
		var worker_stack: PackedByteArray = worker_result.get("stack_page", PackedByteArray())
		var worker_calls: Array = worker_result.get("calls", [])
		var recent_worker_calls := worker_calls.slice(max(0, worker_calls.size() - 5))
		print("Slot-$05 gap detail: status=%s reason=%s descriptor=%s descriptor_reason=%s worker_descriptor=%s worker_reason=%s worker_exit=%s worker_pc=$%04X A/X/Y/P/SP=%02X/%02X/%02X/%02X/%02X banks=%02X/%02X blocked_read=%s" % [
			String(stopped_task.get("status", "")), String(stopped_task.get("reason", "")),
			String(descriptor.get("status", "")), String(descriptor.get("reason", "")),
			String(worker_descriptor.get("status", "")), String(worker_descriptor.get("reason", "")),
			String(worker_result.get("exit_kind", "")), int(worker_result.get("exit_pc", -1)),
			int(worker_registers.get("a", -1)), int(worker_registers.get("x", -1)),
			int(worker_registers.get("y", -1)), int(worker_registers.get("p", -1)),
			int(worker_registers.get("sp", -1)), int(worker_mapper.get("bank_low", -1)),
			int(worker_mapper.get("bank_high", -1)),
			JSON.stringify(worker_result.get("blocked_read", {})),
		])
		if worker_ram.size() == 0x800 and worker_stack.size() == 0x100:
			print("Slot-$05 source boundary context: flags=$0515-$0519=%s $0005/$0629=%02X/%02X stack=$0148-$0157=%s recent_calls=%s" % [
				worker_ram.slice(0x0515, 0x051A).hex_encode(), worker_ram[0x0005],
				worker_ram[0x0629], worker_stack.slice(0x48, 0x58).hex_encode(),
				JSON.stringify(recent_worker_calls),
			])
	print("Recorded route gaps at stop: ", JSON.stringify(stop_route_status.get("route_gaps", [])))
	if String(stop_route_status.get("stage", "")) == "source_route_gap":
		print("Recorded route source frame at stop snapshot: ", stop_route_status.get("source_frame", -1))
		print("Recorded route gaps at stop: ", JSON.stringify(stop_route_status.get("route_gaps", [])))
		print("Cutscene background task at stop: ", JSON.stringify(stop_route_status.get("cutscene_background_task", {})))
		print("Cutscene VM state at stop: ", stop_route_status.get("vm_state", "unknown"),
			" event=", route.vm.current_event_index, " pc=$%04X" % route.vm.current_source_address)
	print("Sparse source RAM at wait boundary: %d/%d bytes known; `$001B/$0078/$0079/$003B`=%s" % [
		int(sparse_ram.get("known_byte_count", 0)), int(sparse_ram.get("ram_size", 0)),
		JSON.stringify(wait_ram_state),
	])
	var irq_table_inputs: Array[Dictionary] = []
	for address in [0x007C, 0x007D, 0x007E, 0x0090, 0x0091]:
		var writer: Dictionary = last_ram_writes.get(address, {})
		irq_table_inputs.append({
			"address": "$%04X" % address,
			"known": known_ram_values.has(address),
			"value": known_ram_values.get(address, -1),
			"writer": String(writer.get("event_id", "unknown")),
			"source_pc": "$%04X" % int(writer.get("source_pc", -1)) if not writer.is_empty() else "unknown",
		})
	print("Bank-$02 `$A160` wait IRQ inputs (`$78=$04` indexes `$7C-$7E`; terminal CHR helper reads `$90/$91`): ", JSON.stringify(irq_table_inputs))
	var selected_nmi_context_bytes: Array[int] = [0x001B, 0x001C, 0x001D, 0x0020, 0x0021,
		0x0022, 0x0023, 0x0024, 0x0025, 0x003B, 0x0044, 0x0045, 0x0079,
		0x007A, 0x007B, 0x008E, 0x008F, 0x009E, 0x009F, 0x00A0, 0x00A1,
		0x00E1, 0x00E2, 0x00E3, 0x0628]
	var unknown_nmi_bytes: Array[String] = []
	for address in selected_nmi_context_bytes:
		if not known_ram_values.has(address):
			unknown_nmi_bytes.append("$%04X" % address)
	var oam_dma_known_bytes := 0
	var oam_writer_counts: Dictionary = {}
	for address in range(0x0200, 0x0300):
		if known_ram_values.has(address):
			oam_dma_known_bytes += 1
		var write: Dictionary = last_ram_writes.get(address, {})
		var writer_key := "%s@$%04X" % [String(write.get("event_id", "missing")), int(write.get("source_pc", -1))]
		oam_writer_counts[writer_key] = int(oam_writer_counts.get(writer_key, 0)) + 1
	print("Projected `$893B` ledger coverage for the selected 25-byte NMI context subset (not the full executor footprint or earlier `$A15B` event-time context): %d/%d addresses known; unknown=%s; OAM-DMA page=$0200-$02FF known=%d/256 writers=%s" % [
		selected_nmi_context_bytes.size() - unknown_nmi_bytes.size(), selected_nmi_context_bytes.size(),
		JSON.stringify(unknown_nmi_bytes), oam_dma_known_bytes, JSON.stringify(oam_writer_counts),
	])
	var mapper_shadow_write: Dictionary = sparse_ram.get("last_write_by_address", {}).get(0x0022, {})
	_check(int(known_ram_values.get(0x0022, -1)) == 0
		and String(mapper_shadow_write.get("event_id", "")) == "kickoff_mapper_shadow_0022"
		and int(mapper_shadow_write.get("source_pc", -1)) == 0xC411,
		"selector caller folds the ROM reset/mapper initializer writes for `$0022` into live source RAM")
	var source_ram_writes: Dictionary = sparse_ram.get("last_write_by_address", {})
	var controller_1c_write: Dictionary = source_ram_writes.get(0x001C, {})
	var controller_1d_write: Dictionary = source_ram_writes.get(0x001D, {})
	var ppu_ctrl_write: Dictionary = source_ram_writes.get(0x0020, {})
	var ppu_mask_write: Dictionary = source_ram_writes.get(0x0021, {})
	var expected_ppu_ctrl_event := "fresh_match_a2af_ppu_clear_8458" if reached_scenario36_e0df \
		else "fresh_match_a503_postwait_98a0_frame_" if stopped_after_a611 \
		else "fresh_match_b0c0_remaining_stream"
	var expected_ppu_ctrl_pc := 0x98D7 if stopped_after_a611 or reached_scenario36_e0df else 0x9884
	var expected_ppu_mask_pc := 0x98D1 if stopped_after_a611 or reached_scenario36_e0df else 0x987E
	var route_selector_nmi_checkpoint: Dictionary = stop_route_status.get("fresh_match_selector_nmi_checkpoint", {})
	var frame8_nmi: Dictionary = route_selector_nmi_checkpoint.get("candidate_nmi_execution", {})
	var frame8_nmi_ram: PackedByteArray = frame8_nmi.get("ram_after", PackedByteArray())
	var a4eb_prefix_for_ram: Dictionary = stop_route_status.get("fresh_match_a4eb_prefix", {})
	var pre_a4eb_ram_status: Dictionary = a4eb_prefix_for_ram.get("source_ram_before_prefix", {})
	var pre_a4eb_ram_values: Dictionary = pre_a4eb_ram_status.get("known_values", {})
	var pre_a4eb_ram_writes: Dictionary = pre_a4eb_ram_status.get("last_write_by_address", {})
	var ppu_ramp_provenance_ok := (int(known_ram_values.get(0x0020, -1)) == 0x88
		and int(known_ram_values.get(0x0021, -1)) == 0x1E
		and int(known_ram_values.get(0x0019, -1)) == 0x01
		and frame8_nmi_ram.size() == 0x800
		and int(frame8_nmi_ram[0x0020]) == int(known_ram_values.get(0x0020, -1))
		and int(frame8_nmi_ram[0x0021]) == int(known_ram_values.get(0x0021, -1))
		and String(ppu_ctrl_write.get("event_id", "")).begins_with(expected_ppu_ctrl_event)
		and int(ppu_ctrl_write.get("source_pc", -1)) == expected_ppu_ctrl_pc
		and String(ppu_mask_write.get("event_id", "")).begins_with(expected_ppu_ctrl_event)
		and int(ppu_mask_write.get("source_pc", -1)) == expected_ppu_mask_pc
		and int(source_ram_writes.get(0x0019, {}).get("source_pc", -1)) == 0x9FA8
		and String(source_ram_writes.get(0x0019, {}).get("event_id", "")).begins_with("fresh_match_a503_palette_ramp_frame_")
		and not unknown_nmi_bytes.has("$0020")
		and not unknown_nmi_bytes.has("$0021"))
	if not ppu_ramp_provenance_ok:
		print("PPU-ramp provenance details: ", JSON.stringify({
			"known_0020": known_ram_values.get(0x0020, "unknown"),
			"known_0021": known_ram_values.get(0x0021, "unknown"),
			"known_0019": known_ram_values.get(0x0019, "unknown"),
			"nmi_ram_size": frame8_nmi_ram.size(),
			"nmi_0020": int(frame8_nmi_ram[0x0020]) if frame8_nmi_ram.size() == 0x800 else -1,
			"nmi_0021": int(frame8_nmi_ram[0x0021]) if frame8_nmi_ram.size() == 0x800 else -1,
			"writer_0020": ppu_ctrl_write, "writer_0021": ppu_mask_write,
			"writer_0019": source_ram_writes.get(0x0019, {}),
			"unknown_context_bytes": unknown_nmi_bytes,
		}))
	_check(ppu_ramp_provenance_ok,
		"ROM PPU shadows survive the `$997A` ramp while `$9FA8` writes its one-tick task delay")
	var bank6_shadow_write: Dictionary = last_ram_writes.get(0x0024, {})
	var interrupt_counter_write: Dictionary = last_ram_writes.get(0x003B, {})
	_check(int(known_ram_values.get(0x0024, -1)) == 0
		and String(bank6_shadow_write.get("event_id", "")) == "kickoff_cutscene1_mapper_bank6_shadow_0024"
		and int(bank6_shadow_write.get("source_pc", -1)) == 0x9F5F
		and not unknown_nmi_bytes.has("$0024")
		and int(known_ram_values.get(0x003B, -1)) == 0x55
		and String(interrupt_counter_write.get("event_id", "")) == "fresh_match_preset_wait_irq"
		and int(interrupt_counter_write.get("source_pc", -1)) == 0xC4AB
		and not unknown_nmi_bytes.has("$003B")
		and int(known_ram_values.get(0x0075, -1)) == 0x3C
		and int(known_ram_values.get(0x0076, -1)) == 0x3E
		and int(known_ram_values.get(0x008E, -1)) == 0x00
		and int(known_ram_values.get(0x008F, -1)) == 0x2E
		and int(pre_a4eb_ram_values.get(0x009E, -1)) == 0xF0
		and int(pre_a4eb_ram_values.get(0x009F, -1)) == 0x71
		and int(pre_a4eb_ram_values.get(0x00A0, -1)) == 0x66
		and int(pre_a4eb_ram_values.get(0x00A1, -1)) == 0x67
			and int(known_ram_values.get(0x001C, -1)) == 0
			and int(known_ram_values.get(0x001D, -1)) == 0
			and String(controller_1c_write.get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and String(controller_1d_write.get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and int(controller_1c_write.get("source_pc", -1)) == 0xA111
			and int(controller_1d_write.get("source_pc", -1)) == 0xA111
			and String(source_ram_writes.get(0x00E1, {}).get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and String(source_ram_writes.get(0x00E2, {}).get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and String(source_ram_writes.get(0x00E3, {}).get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and int(source_ram_writes.get(0x00E1, {}).get("source_pc", -1)) == 0xA11B
			and int(source_ram_writes.get(0x00E2, {}).get("source_pc", -1)) == 0xA121
			and int(source_ram_writes.get(0x00E3, {}).get("source_pc", -1)) == 0xA127
		and int(source_ram_writes.get(0x0075, {}).get("source_pc", -1)) == 0x8B3F
		and int(source_ram_writes.get(0x0076, {}).get("source_pc", -1)) == 0x8B44
		and int(source_ram_writes.get(0x008E, {}).get("source_pc", -1)) == 0xA562
		and int(source_ram_writes.get(0x008F, {}).get("source_pc", -1)) == 0xA566
		and int(pre_a4eb_ram_writes.get(0x009E, {}).get("source_pc", -1)) == 0x94DE
		and int(pre_a4eb_ram_writes.get(0x009F, {}).get("source_pc", -1)) == 0x94E3
		and int(pre_a4eb_ram_writes.get(0x00A0, {}).get("source_pc", -1)) == 0x94E9
		and int(pre_a4eb_ram_writes.get(0x00A1, {}).get("source_pc", -1)) == 0x94EE
			and selected_nmi_context_bytes.size() - unknown_nmi_bytes.size() == 25,
		"frame-8 ROM NMI writes and source histories produce all twenty-five selected context bytes in the wait ledger")
	var chr_shadow_history: Array = stop_route_status.get("cutscene_chr_shadow_history", [])
	var saw_chr_pair := false
	var saw_nmi_chr_copy := false
	for receipt_variant in chr_shadow_history:
		if not receipt_variant is Dictionary:
			continue
		var receipt: Dictionary = receipt_variant
		if String(receipt.get("kind", "")) == "source_table_pair" \
				and int(receipt.get("source_frame", -1)) == 7112 \
				and receipt.get("selector_pair", []) == [0x3C, 0x3E]:
			saw_chr_pair = true
		if String(receipt.get("kind", "")) == "nmi_shadow_copy" \
				and int(receipt.get("source_frame", -1)) == 7119 \
				and receipt.get("selector_pair", []) == [0x3C, 0x3E]:
			saw_nmi_chr_copy = true
	_check(saw_chr_pair and saw_nmi_chr_copy,
		"ROM `$AE37` selector data and the completed `$F9 $5E` task produce the `$75/$76` and `$8E/$8F` source writes")
	var animation_chr_history: Array = stop_route_status.get("cutscene_animation_chr_shadow_history", [])
	var saw_animation_chr_header := false
	for receipt_variant in animation_chr_history:
		if not receipt_variant is Dictionary:
			continue
		var receipt: Dictionary = receipt_variant
		if String(receipt.get("kind", "")) == "sprite_frame_header" \
				and int(receipt.get("source_frame", -1)) == 7119 \
				and receipt.get("selector_values", []) == [0xF0, 0x71, 0x66, 0x67]:
			saw_animation_chr_header = true
	_check(saw_animation_chr_header,
		"cutscene `$FB $01 $51` runs the ROM `$94D8` CHR-header stores on its frame-7119 source event")
	var counter_checkpoint_status: Dictionary = stop_route_status.get("fresh_match_selector_nmi_checkpoint", {})
	var interrupt_counter_receipt: Dictionary = counter_checkpoint_status.get(
		"pre_candidate_interrupt_counter_receipt", {})
	_check(bool(interrupt_counter_receipt.get("ok", false))
		and int(interrupt_counter_receipt.get("prior_completed_nmi_count", -1)) == 7
		and int(interrupt_counter_receipt.get("prior_completed_irq_count", -1)) == 7
		and int(interrupt_counter_receipt.get("converged_counter_value", -1)) == 0x55
		and not bool(interrupt_counter_receipt.get("handlers_executed", true)),
		"14 source-clock interrupt events converge `$003B` to `$55` without claiming handler execution")
	var sound_frame_counter_receipt: Dictionary = counter_checkpoint_status.get(
		"pre_candidate_sound_frame_counter_receipt", {})
	var sound_frame_counter_writes: Array = sound_frame_counter_receipt.get("known_bit_writes", [])
	_check(bool(sound_frame_counter_receipt.get("ok", false))
		and int(sound_frame_counter_receipt.get("candidate_source_frame", -1)) == 7266
		and int(sound_frame_counter_receipt.get("increment_count", -1)) == 7255
		and sound_frame_counter_writes.size() == 1
		and int(sound_frame_counter_writes[0].get("address", -1)) == 0x003A
		and int(sound_frame_counter_writes[0].get("known_mask", 0)) == 0xFF
		and int(sound_frame_counter_writes[0].get("known_value", -1)) == 0x57
		and _frame_7266_c421_ram_reference.size() == 0x800
		and int(_frame_7266_c421_ram_reference[0x003A]) == 0x57
		and sound_frame_counter_receipt.get("rom_source_spans", []) == ["$C64E-$C679", "$A234-$A23D", "$A116-$A137"]
		and not bool(sound_frame_counter_receipt.get("nmi_handler_executed_for_candidate", true))
		and not bool(sound_frame_counter_receipt.get("trace_state_used", true))
		and not bool(sound_frame_counter_receipt.get("emulator_data_used", true)),
		"ROM reset/boot clears plus 7,255 ROM A117-to-A135 calls prove candidate `$003A=$57` without executing that NMI")
	var sound_queue_receipt: Dictionary = counter_checkpoint_status.get(
		"pre_candidate_sound_queue_inputs_receipt", {})
	var sound_queue_candidate_checkpoint: Dictionary = counter_checkpoint_status.get("cpu_checkpoint", {})
	var sound_queue_candidate_ram: Dictionary = sound_queue_candidate_checkpoint.get("ram_known_values", {})
	var sound_queue_values: Array = sound_queue_receipt.get("known_byte_values", [])
	var sound_queue_expected: Array[int] = [0x0700, 0x0701, 0x0702, 0x0703,
		0x0704, 0x0705, 0x0706, 0x07E9]
	var sound_queue_values_valid := sound_queue_values.size() == sound_queue_expected.size()
	var sound_queue_seen: Dictionary = {}
	for value_variant in sound_queue_values:
		if not value_variant is Dictionary:
			sound_queue_values_valid = false
			continue
		var value_row: Dictionary = value_variant
		var address := int(value_row.get("address", -1))
		if address not in sound_queue_expected \
				or int(value_row.get("known_mask", 0)) != 0xFF \
				or int(value_row.get("known_value", -1)) != 0 \
				or int(value_row.get("observation_pc", -1)) != 0xC421 \
				or sound_queue_seen.has(address) \
				or int(sound_queue_candidate_ram.get(address, -1)) != 0:
			sound_queue_values_valid = false
		else:
			sound_queue_seen[address] = true
	_check(bool(sound_queue_receipt.get("ok", false))
		and int(sound_queue_receipt.get("candidate_source_frame", -1)) == 7266
		and int(sound_queue_receipt.get("candidate_source_cycle", -1)) == 216355361
		and int(sound_queue_receipt.get("candidate_source_pc", -1)) == 0xC421
		and String(sound_queue_receipt.get("source_ram_sha256", "")) == "aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0"
		and int(sound_queue_receipt.get("write_count", -1)) == 58199
		and sound_queue_receipt.get("writer_summary", []).size() == 89
		and sound_queue_values_valid
		and sound_queue_seen.size() == sound_queue_expected.size()
		and not bool(sound_queue_receipt.get("candidate_nmi_executed", true))
		and not bool(sound_queue_receipt.get("trace_state_used", true))
		and not bool(sound_queue_receipt.get("emulator_data_used", true)),
		"ROM-only route execution proves all eight bank-$0C sound-driver branch bytes at `$C421` before dispatch")
	var rng_history_receipt: Dictionary = counter_checkpoint_status.get("pre_candidate_rng_history_receipt", {})
	var rng_history_writes: Array = rng_history_receipt.get("ram_writes", [])
	_check(bool(rng_history_receipt.get("ok", false))
		and int(rng_history_receipt.get("source_frame", -1)) == 7265
		and int(rng_history_receipt.get("candidate_source_frame", -1)) == 7266
		and int(rng_history_receipt.get("a117_update_count", -1)) == 7255
		and int(rng_history_receipt.get("c9c5_update_count", -1)) == 0
		and rng_history_writes.size() == 3
		and int(rng_history_writes[0].get("address", -1)) == 0x00E1
		and int(rng_history_writes[0].get("value", -1)) == 0x85
		and int(rng_history_writes[0].get("source_pc", -1)) == 0xA11B
		and int(rng_history_writes[1].get("address", -1)) == 0x00E2
		and int(rng_history_writes[1].get("value", -1)) == 0xEB
		and int(rng_history_writes[1].get("source_pc", -1)) == 0xA121
		and int(rng_history_writes[2].get("address", -1)) == 0x00E3
		and int(rng_history_writes[2].get("value", -1)) == 0x45
		and int(rng_history_writes[2].get("source_pc", -1)) == 0xA127
		and not bool(rng_history_receipt.get("following_nmi_executed", true))
		and not bool(rng_history_receipt.get("trace_state_used", true))
		and not bool(rng_history_receipt.get("emulator_data_used", true)),
		"ROM-only A117 history produces three pre-NMI RNG bytes without claiming the candidate NMI ran")
	var wait_bank6_shadow_write: Dictionary = last_ram_writes.get(0x0025, {})
	var a503_ramp_restored_bank1 := false
	var a503_ramp_mapper_writes: Array = stop_route_status.get(
		"fresh_match_a503_palette_ramp", {}).get("mapper_bus_writes", [])
	for mapper_write_variant in a503_ramp_mapper_writes:
		if mapper_write_variant is Dictionary:
			var mapper_write: Dictionary = mapper_write_variant
			if int(mapper_write.get("address", -1)) == 0x8001 \
					and int(mapper_write.get("value", -1)) == 0x01:
				a503_ramp_restored_bank1 = true
	var final_bank_shadow_write_is_expected := String(wait_bank6_shadow_write.get("event_id", "")) \
		== "fresh_match_a503_palette_ramp_begin"
	if stopped_at_a64c:
		final_bank_shadow_write_is_expected = String(wait_bank6_shadow_write.get("event_id", "")) \
			== "fresh_match_setup_813f_mapper" \
			and int(wait_bank6_shadow_write.get("source_pc", -1)) == 0xC4B9
	elif reached_scenario36_e0df:
		final_bank_shadow_write_is_expected = String(wait_bank6_shadow_write.get("event_id", "")) \
			== "fresh_match_setup_813f_mapper" \
			and int(wait_bank6_shadow_write.get("source_pc", -1)) == 0xC4B9
	var preselector_bank_shadow_ok := (_frame_7266_c421_ram_reference.size() == 0x800
		and int(_frame_7266_c421_ram_reference[0x0025]) == 0x02
		and int(known_ram_values.get(0x0025, -1)) == 0x01
		and final_bank_shadow_write_is_expected
		and a503_ramp_restored_bank1)
	if not preselector_bank_shadow_ok:
		print("Pre-selector bank-shadow details: ", JSON.stringify({
			"candidate_ram_0025": int(_frame_7266_c421_ram_reference[0x0025]) if _frame_7266_c421_ram_reference.size() == 0x800 else -1,
			"wait_ledger_0025": known_ram_values.get(0x0025, "unknown"),
			"last_writer_0025": wait_bank6_shadow_write,
			"writer_matches_expected": final_bank_shadow_write_is_expected,
			"ramp_restored_bank1": a503_ramp_restored_bank1,
			"ramp_mapper_writes": a503_ramp_mapper_writes,
		}))
	_check(preselector_bank_shadow_ok,
		"the pre-selector NMI `$A15B` snapshot uses bank shadow `$02`, `$893B` selects `$06`, and `$997A` restores bank `$01`")
	var known_mode_bits: Dictionary = sparse_ram.get("known_bits_by_address", {}).get(0x001B, {})
	_check(int(known_mode_bits.get("known_mask", 0)) == 0x7F
		and int(known_mode_bits.get("known_value", 0)) == 0x40,
		"the later interrupt-free wait projection proves only `$001B & $7F=$40`; candidate `$A15B` mode state is checked separately")
	print("Partial wait provenance: `$001B` known mask=$%02X value=$%02X; full byte remains unknown." % [
		int(known_mode_bits.get("known_mask", 0)), int(known_mode_bits.get("known_value", 0)),
	])
	if route._fresh_source_route_runner != null:
		var scheduler: Variant = route._fresh_source_route_runner._scheduler
		var slot11: Dictionary = scheduler.get_task_boundary_snapshot(0x11)
		var ram: PackedByteArray = slot11.get("ram_image", PackedByteArray())
		var stack: PackedByteArray = slot11.get("stack_page", PackedByteArray())
		var slot11_state := {
			"record": (slot11.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
			"pc": slot11.get("pc", -1), "sp": slot11.get("sp", -1),
			"phase": slot11.get("phase", -1), "pending_resume": slot11.get("pending_resume", -1),
			"ready_delay": slot11.get("ready_delay", -1), "a": slot11.get("a", -1),
			"x": slot11.get("x", -1), "y": slot11.get("y", -1),
			"p": slot11.get("p", -1), "p_known_mask": slot11.get("p_known_mask", -1),
		}
		if ram.size() == 0x800:
			slot11_state["ram_046c_0498"] = ram.slice(0x046C, 0x0498).hex_encode()
			slot11_state["ram_0498_04a5"] = ram.slice(0x0498, 0x04A5).hex_encode()
			slot11_state["ram_0515_0519"] = ram.slice(0x0515, 0x051A).hex_encode()
			slot11_state["ram_04a5_04c9"] = ram.slice(0x04A5, 0x04C9).hex_encode()
			slot11_state["ram_05e3_05ea"] = ram.slice(0x05E3, 0x05EA).hex_encode()
			slot11_state["ram_005f_0061"] = ram.slice(0x005F, 0x0061).hex_encode()
		if stack.size() == 0x100:
			slot11_state["stack_C0_D0"] = stack.slice(0xC0, 0xD1).hex_encode()
		var nmi_result: Dictionary = stop_route_status.get("fresh_source_route_nmi", {}).get("nmi_result", {})
		slot11_state["last_nmi_secondary_queue"] = nmi_result.get("secondary_queue", {})
		slot11_state["last_nmi_bus_event_count"] = (nmi_result.get("ppu_bus_events", []) as Array).size()
		print("Slot-$11 diagnostic snapshot at source frame %d: %s" % [stop_frame, JSON.stringify(slot11_state)])
		if reached_scenario36_boundary:
			final_slot05 = scheduler.get_task_boundary_snapshot(0x05)
			var slot05_ram: PackedByteArray = final_slot05.get("ram_image", PackedByteArray())
			print("Slot-$05 after scenario `$36` yield at source frame %d: pc=$%04X sp=$%02X input=$%02X/$%02X RNG=$%02X/$%02X/$%02X holder=$%02X receiver=$%02X coordinates=$%02X/$%02X index=$%02X positions=%d" % [
				stop_frame, int(final_slot05.get("pc", -1)), int(final_slot05.get("sp", -1)),
				int(slot05_ram[0x001C]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x001E]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x00E1]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x00E2]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x00E3]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x0441]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x05FC]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x0635]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x0637]) if slot05_ram.size() == 0x800 else -1,
				int(slot05_ram[0x05FE]) if slot05_ram.size() == 0x800 else -1,
				route.get_route_status().get("initial_player_positions", []).size(),
			])
	_check(route.source_frame == stop_frame, "route stops at the observed endpoint instead of advancing past it")
	_check(menu_endpoint_reached or reached_first_pass_decision_wait \
		or reached_scenario36_boundary or stopped_at_handoff_gap \
		or stopped_at_preset_wait or stopped_at_a503_text_setup or stopped_at_a503_wait_loop \
		or stopped_at_811f or stopped_at_812f or stopped_at_a64c or stopped_at_scenario36_e0df \
		or stopped_at_slot15_map36_yield or stopped_at_slot15_map2d_yield or stopped_at_scenario44_field_boundary \
		or String(stop_source_route.get("phase", "")) == "error",
		"route reaches its configured endpoint or stops at a documented source boundary")
	if menu_endpoint_reached:
		_check(String(stop_route_status.get("stage", "")) == "first_action_menu",
			"completed endpoint is the initial first-action menu")
	elif stopped_at_preset_wait:
		_check(String(final_handoff.get("status", "")) == "blocked_on_caller",
			"`$893B` wait boundary is documented as a blocked caller")
		_check(String(final_handoff.get("pending_helper_id", "")) == "fresh_match_preset_wait_0078"
			and int(final_handoff.get("pending_source_pc", -1)) == 0x893B,
			"`$893B` wait boundary preserves the pending ROM continuation")
		var next_step := String(final_handoff.get("next_step", ""))
		_check(next_step.contains("NMI/IRQ") and next_step.contains("$8117"),
			"`$893B` wait boundary identifies the unresolved interrupt handlers and `$8117` return")
		var selector_nmi_checkpoint: Dictionary = stop_route_status.get("fresh_match_selector_nmi_checkpoint", {})
		var selector_event: Dictionary = selector_nmi_checkpoint.get("source_event", {})
		var selector_entry_status_receipt: Dictionary = selector_nmi_checkpoint.get(
			"selector_entry_status_receipt", {})
		var selector_cpu_checkpoint: Dictionary = selector_nmi_checkpoint.get("cpu_checkpoint", {})
		var selector_cpu: Dictionary = selector_cpu_checkpoint.get("registers", {})
		var selector_pointers: Dictionary = selector_cpu_checkpoint.get("ram_pointers", {})
		var selector_ram_values: Dictionary = selector_cpu_checkpoint.get("ram_known_values", {})
		var selector_ram_known_bits: Dictionary = selector_cpu_checkpoint.get("ram_known_bit_values", {})
		var frame8_nmi_execution: Dictionary = selector_nmi_checkpoint.get("candidate_nmi_execution", {})
		var frame8_nmi_cpu: Dictionary = frame8_nmi_execution.get("cpu_after_nmi_rti", {})
		var frame8_nmi_context: Dictionary = frame8_nmi_execution.get("entry_context_receipt", {})
		var selector_mode_bits: Dictionary = selector_ram_known_bits.get(0x001B, {})
		var selector_stack: PackedByteArray = selector_cpu_checkpoint.get("stack_page", PackedByteArray())
		var selector_stack_offsets: Array = selector_cpu_checkpoint.get("stack_page_known_offsets", [])
		var selector_source_ram: Dictionary = stop_route_status.get("source_ram_image_at_893b", {})
		var selector_last_writes: Dictionary = selector_source_ram.get("last_write_by_address", {})
		var selector_packet_consumer_write: Dictionary = selector_last_writes.get(0x0628, {})
		var selector_nmi_known_read_count := 0
		for address in selected_nmi_context_bytes:
			if selector_ram_values.has(address):
				selector_nmi_known_read_count += 1
		_print_nmi_read_set_checkpoint(selector_ram_values)
		print("ROM-source `$A15B` CPU status: P=$%02X known_mask=$%02X known_value=$%02X; physical stack offsets known=%s" % [
			int(selector_cpu.get("p", -1)), int(selector_cpu.get("p_known_mask", -1)),
			int(selector_cpu.get("p_known_value", -1)), str(selector_stack_offsets)])
		print("ROM-source `$A15B` `$001B` bit knowledge: mask=$%02X value=$%02X" % [
			int(selector_mode_bits.get("known_mask", 0)),
			int(selector_mode_bits.get("known_value", 0))])
		_check(bool(selector_nmi_checkpoint.get("ok", false))
			and String(selector_nmi_checkpoint.get("status", "")) == "rom_source_frame8_nmi_executed_and_rti_returned_to_A15B"
			and int(selector_nmi_checkpoint.get("mainline_cycle_offset", -1)) == 193821
			and String(selector_event.get("kind", "")) == "NMI"
			and String(selector_event.get("pc_before", "")) == "$A15B"
			and int(selector_cpu.get("pc", -1)) == 0xA15B
			and int(selector_cpu.get("a", -1)) == 0x1F
			and int(selector_cpu.get("p", -1)) == 0x30
			and int(selector_cpu.get("p_known_mask", 0)) == 0xFF
			and int(selector_cpu.get("p_known_value", -1)) == 0x30
			and (int(selector_cpu.get("p_known_mask", 0)) & 0x04) == 0x04
			and (int(selector_cpu.get("p_known_value", 0)) & 0x04) == 0
			and int(selector_pointers.get(0x00D0, -1)) == 0x1F
			and int(selector_pointers.get(0x00D1, -1)) == 0xBF
			and int(selector_pointers.get(0x00D2, -1)) == 0x6F
			and int(selector_pointers.get(0x00D3, -1)) == 0x72
			and bool(selector_nmi_checkpoint.get("physical_stack_available", false))
			and int(selector_nmi_checkpoint.get("prior_source_ram_known_byte_count", 0)) > 0
			and int(selector_nmi_checkpoint.get("prior_source_ram_bytes_inherited", 0)) > 0
			and int(selector_ram_values.get(0x0024, -1)) == 0x00
			and int(selector_ram_values.get(0x003B, -1)) == 0x55
			and int(selector_ram_values.get(0x0628, -1)) == 0
			and int(selector_ram_values.get(0x009E, -1)) == 0xF0
			and int(selector_ram_values.get(0x009F, -1)) == 0x71
			and int(selector_ram_values.get(0x00A0, -1)) == 0x66
			and int(selector_ram_values.get(0x00A1, -1)) == 0x67
			and int(selector_ram_values.get(0x001C, -1)) == 0
			and int(selector_ram_values.get(0x001D, -1)) == 0
			and String(selector_last_writes.get(0x001C, {}).get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and String(selector_last_writes.get(0x001D, {}).get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and int(selector_last_writes.get(0x001C, {}).get("source_pc", -1)) == 0xA111
			and int(selector_last_writes.get(0x001D, {}).get("source_pc", -1)) == 0xA111
			and int(selector_mode_bits.get("known_mask", 0)) == 0xFF
			and int(selector_mode_bits.get("known_value", -1)) == 0xC0
			and int(selector_ram_values.get(0x001B, -1)) == 0xC0
			and String(selector_packet_consumer_write.get("event_id", "")).begins_with("cutscene_cleanup_palette_packet_consumer_")
			and int(selector_packet_consumer_write.get("source_pc", -1)) == 0xA04A
			and selector_nmi_known_read_count == 25
			and not bool(selector_nmi_checkpoint.get("stack_page_complete", true))
			and int(selector_cpu_checkpoint.get("sp", -1)) == 0x24
			and int(selector_cpu_checkpoint.get("ram_known_byte_count", -1)) == selector_ram_values.size()
			and not bool(selector_cpu_checkpoint.get("ram_image_complete", true))
			and selector_stack.size() == 0x100
			and selector_stack[0x25] == 0x80 and selector_stack[0x26] == 0xA8
			and selector_stack[0x27] == 0xFC and selector_stack[0x28] == 0x80
			and selector_stack_offsets.has(0x25) and selector_stack_offsets.has(0x26)
			and selector_stack_offsets.has(0x27) and selector_stack_offsets.has(0x28)
			and bool(selector_nmi_checkpoint.get("interrupt_handler_executed", false))
			and bool(selector_nmi_checkpoint.get("candidate_nmi_dispatched", false)),
			"ROM-backed route state assembles the frame-7266 `$A15B` checkpoint and dispatches its source NMI")
		_check(bool(frame8_nmi_execution.get("candidate_nmi_dispatched", false))
			and String(frame8_nmi_execution.get("status", "")) == "returned_from_special_nmi_to_interrupted_pc"
			and String(frame8_nmi_execution.get("source_rom_sha256", "")) == TITLE_HANDOFF_ROM_SHA256
			and String(frame8_nmi_execution.get("source_event", {}).get("kind", "")) == "NMI"
			and int(frame8_nmi_execution.get("source_event", {}).get("interrupted_pc", -1)) == 0xA15B
			and int(frame8_nmi_execution.get("source_event", {}).get("entry_pc", -1)) == 0xC421
			and int(frame8_nmi_execution.get("source_event", {}).get("entry_cycle", -1)) == 216355343
			and int(frame8_nmi_execution.get("source_event", {}).get("dispatch_cycle", -1)) == 216355361
			and int(frame8_nmi_execution.get("source_event", {}).get("entry_dispatch_cycles", -1)) == 18
			and int(frame8_nmi_cpu.get("pc", -1)) == 0xA15B
			and int(frame8_nmi_cpu.get("p", -1)) == 0x20
			and int(frame8_nmi_cpu.get("sp", -1)) == 0x24
			and bool(frame8_nmi_execution.get("sound_driver_rts_reached", false))
			and bool(frame8_nmi_execution.get("nmi_rti_reached", false))
			and bool(frame8_nmi_execution.get("nmi_stack_frame_restored", false))
			and frame8_nmi_execution.get("apu_writes", []).is_empty()
			and int(frame8_nmi_execution.get("mapper_after", {}).get("known_register_mask", 0)) == 0xFF
			and not bool(frame8_nmi_execution.get("trace_state_used", true))
			and not bool(frame8_nmi_execution.get("emulator_data_used", true))
			and not bool(frame8_nmi_execution.get("candidate_state_used", true))
			and bool(frame8_nmi_context.get("ok", false))
			and int(frame8_nmi_context.get("entry_ram_read_count", -1)) == 35
			and not bool(frame8_nmi_context.get("ram_source_image_complete", true))
			and not bool(frame8_nmi_context.get("stack_page_complete", true))
			and int(frame8_nmi_context.get("mmc3_registers_known_at_entry_mask", 0)) == 0xC0
			and not bool(frame8_nmi_context.get("physical_nes_timing_proven", true)),
			"ROM vector dispatch executes the sparse-context frame-8 NMI through sound-driver RTS and RTI without claiming full memory or hardware timing")
		var mode_bit7_receipt: Dictionary = selector_nmi_checkpoint.get(
			"pre_candidate_nmi_mode_bit7_receipt", {})
		var mode_bit7_writes: Array = mode_bit7_receipt.get("known_bit_writes", [])
		_check(bool(mode_bit7_receipt.get("ok", false))
			and String(mode_bit7_receipt.get("kind", "")) == "rom_source_candidate_001b_bit7"
			and int(mode_bit7_receipt.get("candidate_source_frame", -1)) == 7266
			and int(mode_bit7_receipt.get("candidate_source_cycle", -1)) == 216355361
			and int(mode_bit7_receipt.get("candidate_source_pc", -1)) == 0xC421
			and int(mode_bit7_receipt.get("nmi_candidate_source_frame", -1)) == 7266
			and int(mode_bit7_receipt.get("nmi_candidate_source_cycle", -1)) == 216355343
			and int(mode_bit7_receipt.get("nmi_candidate_source_pc", -1)) == 0xA15B
			and int(mode_bit7_receipt.get("known_bit_mask", 0)) == 0xFF
			and int(mode_bit7_receipt.get("known_bit_value", -1)) == 0xC0
			and mode_bit7_writes.size() == 1
			and int(mode_bit7_writes[0].get("address", -1)) == 0x001B
			and int(mode_bit7_writes[0].get("known_mask", 0)) == 0x80
			and int(mode_bit7_writes[0].get("known_value", -1)) == 0x80
			and int(mode_bit7_writes[0].get("source_pc", -1)) == 0xA133
			and int(mode_bit7_receipt.get("last_writer_before_candidate", {}).get("last_source_frame", -1)) == 7265
			and int(mode_bit7_receipt.get("last_writer_before_candidate", {}).get("last_source_cycle", -1)) == 216326882
			and bool(mode_bit7_receipt.get("no_mode_writer_between_nmi_candidate_and_boundary", false))
			and not bool(mode_bit7_receipt.get("candidate_nmi_executed", true))
			and not bool(mode_bit7_receipt.get("trace_state_used", true))
			and not bool(mode_bit7_receipt.get("emulator_data_used", true))
			and not bool(mode_bit7_receipt.get("candidate_state_used", true))
			and not bool(mode_bit7_receipt.get("physical_nes_timing_proven", true)),
			"ROM-stepper `$001B` writer history and checked `$A133` bytes establish `$001B=$C0` before the separately verified frame-8 NMI dispatch")
		var saved_bank_receipt: Dictionary = selector_nmi_checkpoint.get(
			"pre_candidate_saved_bank_07fc_receipt", {})
		var saved_bank_values: Array = saved_bank_receipt.get("known_byte_values", [])
		_check(bool(saved_bank_receipt.get("ok", false))
			and String(saved_bank_receipt.get("kind", "")) == "rom_source_candidate_saved_bank_07fc"
			and int(saved_bank_receipt.get("candidate_source_frame", -1)) == 7266
			and int(saved_bank_receipt.get("candidate_source_cycle", -1)) == 216355361
			and int(saved_bank_receipt.get("candidate_source_pc", -1)) == 0xC421
			and int(saved_bank_receipt.get("saved_bank_07fc_value", -1)) == 0x0F
			and int(saved_bank_receipt.get("write_count_before_candidate", -1)) == 4
			and saved_bank_values.size() == 1
			and int(saved_bank_values[0].get("address", -1)) == 0x07FC
			and int(saved_bank_values[0].get("known_mask", 0)) == 0xFF
			and int(saved_bank_values[0].get("known_value", -1)) == 0x0F
			and int(saved_bank_values[0].get("source_pc", -1)) == 0x804D
			and int(saved_bank_receipt.get("latest_writer_before_candidate", {}).get("last_source_frame", -1)) == 4817
			and int(saved_bank_receipt.get("latest_writer_before_candidate", {}).get("last_source_cycle", -1)) == 143424443
			and int(selector_ram_values.get(0x07FC, -1)) == 0x0F
			and not bool(saved_bank_receipt.get("candidate_nmi_executed", true))
			and not bool(saved_bank_receipt.get("trace_state_used", true))
			and not bool(saved_bank_receipt.get("emulator_data_used", true))
			and not bool(saved_bank_receipt.get("candidate_state_used", true)),
			"ROM-stepper history plus checked bank-$0C `STY $07FC` bytes derive saved sound bank `$0F` at the candidate")
		var zero_mask_read_contract: Dictionary = selector_nmi_checkpoint.get(
			"pre_candidate_zero_mask_entry_ram_read_contract", {})
		var zero_mask_read_addresses: Array = zero_mask_read_contract.get(
			"entry_ram_read_addresses", [])
		var zero_mask_read_values: Array = zero_mask_read_contract.get(
			"known_entry_ram_values", [])
		print("Special NMI zero-mask entry RAM reads: %d/%d known; full machine context complete=%s" % [
			int(zero_mask_read_contract.get("known_entry_ram_read_count", 0)),
			int(zero_mask_read_contract.get("required_entry_ram_read_count", 0)),
			str(bool(zero_mask_read_contract.get("cpu_stack_mapper_ppu_apu_context_complete", false)))])
		_check(bool(zero_mask_read_contract.get("ok", false))
			and String(zero_mask_read_contract.get("kind", "")) == "rom_source_special_nmi_zero_mask_entry_ram_read_contract"
			and int(zero_mask_read_contract.get("source_frame", -1)) == 7266
			and int(zero_mask_read_contract.get("candidate_pc", -1)) == 0xA15B
			and zero_mask_read_addresses.size() == 35
			and zero_mask_read_values.size() == 35
			and int(zero_mask_read_contract.get("required_entry_ram_read_count", -1)) == 35
			and int(zero_mask_read_contract.get("known_entry_ram_read_count", -1)) == 35
			and bool(zero_mask_read_contract.get("empty_packet_queue", false))
			and bool(zero_mask_read_contract.get("empty_sound_slots", false))
			and bool(zero_mask_read_contract.get("zero_sound_mask", false))
			and not bool(zero_mask_read_contract.get("full_ram_image_complete", true))
			and not bool(zero_mask_read_contract.get("cpu_stack_mapper_ppu_apu_context_complete", true))
			and bool(zero_mask_read_contract.get("candidate_nmi_not_dispatched", false))
			and not bool(zero_mask_read_contract.get("candidate_nmi_executed", true))
			and not bool(zero_mask_read_contract.get("trace_state_used", true))
			and not bool(zero_mask_read_contract.get("emulator_data_used", true))
			and not bool(zero_mask_read_contract.get("physical_nes_timing_proven", true)),
			"ROM-source special-NMI/zero-mask path has all 35 required entry RAM bytes while the remaining machine state stays explicitly incomplete")
		_check(bool(selector_entry_status_receipt.get("ok", false))
			and String(selector_entry_status_receipt.get("flag", "")) == "I"
			and int(selector_entry_status_receipt.get("p_known_mask", 0)) == 0x04
			and int(selector_entry_status_receipt.get("p_known_value", -1)) == 0
			and int(selector_entry_status_receipt.get("candidate_p_byte", -1)) == 0x30
			and bool(selector_entry_status_receipt.get("candidate_status_applied", false))
			and not bool(selector_entry_status_receipt.get("full_p_byte_known", true))
			and not bool(selector_entry_status_receipt.get("physical_nes_timing_proven", true))
			and not bool(selector_entry_status_receipt.get("runtime_rom_dependency", true))
			and not bool(selector_entry_status_receipt.get("runtime_emulator_dependency", true)),
			"ROM-only selector clock contributes only I=clear to the partial CPU status; it is not treated as a full P byte or physical timing result")
		var selector_call_entry_p_receipt: Dictionary = selector_nmi_checkpoint.get(
			"selector_call_entry_p_receipt", {})
		_check(bool(selector_call_entry_p_receipt.get("ok", false))
			and String(selector_call_entry_p_receipt.get("kind", "")) == "rom_source_selector_call_entry_p_byte"
			and int(selector_call_entry_p_receipt.get("source_pc", -1)) == 0xA20F
			and int(selector_call_entry_p_receipt.get("source_frame", -1)) == 7258
			and int(selector_call_entry_p_receipt.get("source_cycle", -1)) == 216143875
			and int(selector_call_entry_p_receipt.get("known_mask", 0)) == 0xFF
			and int(selector_call_entry_p_receipt.get("known_value", -1)) == 0x30
			and String(selector_call_entry_p_receipt.get("source_model_sha256", "")) == "b0f528dfd73f79cf7148a5a2f6a9f0683cde22a03c1705deb8e5215864d888db"
			and String(selector_call_entry_p_receipt.get("input_route_sha256", "")) == "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
			and not bool(selector_call_entry_p_receipt.get("fceux_trace_used_as_input", true))
			and not bool(selector_call_entry_p_receipt.get("emulator_state_used", true))
			and not bool(selector_call_entry_p_receipt.get("runtime_rom_dependency", true))
			and not bool(selector_call_entry_p_receipt.get("runtime_emulator_dependency", true)),
			"ROM-only `$A20F` call-entry P is checked and carried through the selector executor to the full `$A15B` candidate P byte")
		var e8_events: Array = stop_route_status.get("source_e8_preset_events", [])
		var source_ram_status: Dictionary = stop_route_status.get("source_ram_image_at_893b", {})
		var known_ram: Dictionary = source_ram_status.get("known_values", {})
		var last_writes: Dictionary = source_ram_status.get("last_write_by_address", {})
		var wait_latch_writer: Dictionary = last_writes.get(0x0078, {})
		var preset_writer: Dictionary = last_writes.get(0x0079, {})
		var route_caller: Dictionary = final_handoff.get("post_helper_caller_result", {})
		var preset_prefix: Dictionary = route_caller.get("match_preset_loader_prefix_result", {})
		var prior_preset_state: Dictionary = preset_prefix.get("prior_e8_preset_ram", {})
		_check(not e8_events.is_empty() and int(e8_events[0].get("operand", -1)) == 1
			and int(e8_events[0].get("source_ram_writes", -1)) == 20
			and String(e8_events[0].get("preset_file_offset", "")) == "0x00DF23",
			"ROM E8 `$01` event materializes the 20-byte `$BF13` write mapping")
		_check(int(known_ram.get(0x0078, -1)) == 0x04
			and String(wait_latch_writer.get("event_id", "")) == "fresh_match_selector_frame8_nmi"
			and int(wait_latch_writer.get("source_pc", -1)) == 0xA0A6,
			"the frame-8 ROM NMI arms `$78=$04`; the `$893B` wait has not yet been released")
		_check(int(known_ram.get(0x0079, -1)) == 0x40
			and int(preset_writer.get("source_pc", -1)) == 0x8943
			and String(preset_writer.get("event_id", "")).begins_with("kickoff_cutscene_"),
			"the earlier ROM E8 `$01` write carries `$79=$40` to the fresh-match route")
		_check(bool(prior_preset_state.get("used", false))
			and int(prior_preset_state.get("source_pc", -1)) == 0x8943,
			"the `$8112->$893B` prefix consumes the provenance-carrying E8 `$79` state")
		var caller_stop_seen := false
		for event_variant in stop_route_status.get("sound_queue_write_events", []):
			if not event_variant is Dictionary:
				continue
			var event: Dictionary = event_variant
			if int(event.get("source_pc", -1)) == 0x8107 \
					and int(event.get("address", -1)) == 0x0700 \
					and int(event.get("queue_id", -1)) == 0x01 \
					and bool(event.get("applied", false)):
				caller_stop_seen = true
				break
		_check(caller_stop_seen,
			"source-owned `$8107` queue-stop write reaches the route audio presenter")
	elif stopped_at_a503_text_setup or stopped_at_a503_wait_loop or stopped_after_a611:
		var wait_irq: Dictionary = final_handoff.get("wait_irq_result", {})
		var wait_tail: Dictionary = final_handoff.get("preset_tail_result", {})
		var postwait: Dictionary = final_handoff.get("postwait_caller_result", {})
		var a4eb_prefix: Dictionary = final_handoff.get("a4eb_prefix_result", {})
		var b0c0_first: Dictionary = final_handoff.get("b0c0_first_command_result", {})
		var b0c0_stream: Dictionary = final_handoff.get("b0c0_stream_result", {})
		var b0c0_ppu: Dictionary = b0c0_first.get("ppu_render_result", {})
		var b0c0_ppu_contract: Dictionary = b0c0_first.get("ppu_result_contract", {})
		var b0c0_stream_ppu: Dictionary = b0c0_stream.get("ppu_render_result", {})
		var b0c0_stream_ppu_contract: Dictionary = b0c0_stream.get("ppu_render_contract", {})
		var b0c0_timing: Dictionary = b0c0_stream.get("timing_comparison", {})
		var a503_entry: Dictionary = final_handoff.get("a503_entry_result", {})
		var a503_decoder: Dictionary = final_handoff.get("a503_descriptor_decoder_result", {})
		var release: Dictionary = wait_irq.get("release_write", {})
		var expected_a503_status := "transferred_to_A64C" if stopped_at_a64c else ("returned_to_812F" if stopped_at_812f \
			else ("returned_to_811F" if stopped_at_811f \
			else ("stopped_at_a503_wait_loop" if stopped_at_a503_wait_loop else "stopped_before_a503_fade_helper")))
		var expected_a503_pc := 0xA64C if stopped_at_a64c else (0x812F if stopped_at_812f else (0x811F if stopped_at_811f \
			else (0xA571 if stopped_at_a503_wait_loop else 0xA56C)))
		_check(String(final_handoff.get("status", "")) == expected_a503_status
			and int(final_handoff.get("pending_source_pc", -1)) == expected_a503_pc
			and String(postwait.get("status", "")) == "stopped_at_unexecuted_a006_body"
			and int(postwait.get("next_cpu_state", {}).get("pc", -1)) == 0xA4EB,
			"live source route enters `$A4EB`, executes `$A503/$A611`, and returns to the `$811F` match caller")
		_check(bool(a4eb_prefix.get("ok", false))
			and String(a4eb_prefix.get("status", "")) == "stopped_before_b0c0_stream"
			and int(a4eb_prefix.get("next_cpu_state", {}).get("pc", -1)) == 0xA500
			and int(a4eb_prefix.get("next_cpu_state", {}).get("a", -1)) == 0x00
			and int(a4eb_prefix.get("next_cpu_state", {}).get("x", -1)) == 0xB3
			and int(a4eb_prefix.get("next_cpu_state", {}).get("y", -1)) == 0x05
			and (int(a4eb_prefix.get("next_cpu_state", {}).get("p_known_mask", 0)) & 0x82) == 0x82
			and (int(a4eb_prefix.get("next_cpu_state", {}).get("p_known_value", 0)) & 0x82) == 0x80
			and a4eb_prefix.get("ram_writes", []).size() == 521,
			"ROM `$A4EB` prefix returns source-derived registers, five pointer writes, and 516 OAM/motion writes")
		_check(bool(b0c0_first.get("ok", false))
			and String(b0c0_first.get("status", "")) == "stopped_at_second_b0c6_command_fetch"
			and int(b0c0_first.get("next_cpu_state", {}).get("pc", -1)) == 0xB0C6
			and int(b0c0_first.get("next_cpu_state", {}).get("a", -1)) == 0xB3
			and int(b0c0_first.get("next_cpu_state", {}).get("x", -1)) == 0x00
			and int(b0c0_first.get("next_cpu_state", {}).get("y", -1)) == 0x00
			and (int(b0c0_first.get("next_cpu_state", {}).get("p_known_mask", 0)) & 0xE3) == 0xE3
			and (int(b0c0_first.get("next_cpu_state", {}).get("p_known_value", 0)) & 0xE3) == 0x22
			and int(b0c0_first.get("ram_after", {}).get(0x00EC, -1)) == 0x06
			and int(b0c0_first.get("ram_after", {}).get(0x00ED, -1)) == 0xB3
			and b0c0_first.get("ram_writes", []).size() == 10
			and b0c0_first.get("ppu_bus_events", []).size() == 0x806
			and int(b0c0_first.get("next_command", {}).get("command", -1)) == 0x05,
			"ROM `$B0C0` dispatches `$0D` through `$B1A4->$98A0` and resumes at the `$B306` `$05` fetch")
		_check(bool(b0c0_ppu.get("ok", false))
			and int(b0c0_ppu.get("nametable_writes_applied", -1)) == 0x800
			and int(b0c0_ppu.get("ppu_address_after", -1)) == 0x2800
			and int(b0c0_ppu.get("ppuctrl_shadow_after", -1)) == 0x88
			and int(b0c0_ppu.get("ppu_shared_write_toggle_after", -1)) == 0
			and int(b0c0_ppu_contract.get("ctrl_shadow_after", -1)) == 0x88
			and int(b0c0_ppu_contract.get("mask_shadow_after", -1)) == 0x1E,
			"ROM `$98A0` PPU bus writes clear `$2000-$27FF` and restore the source shadows")
		_check(bool(b0c0_stream.get("ok", false))
			and String(b0c0_stream.get("status", "")) == "returned_to_A503_after_b0c0_stream"
			and int(b0c0_stream.get("next_cpu_state", {}).get("pc", -1)) == 0xA503
			and int(b0c0_stream.get("next_cpu_state", {}).get("a", -1)) == 0xB1
			and int(b0c0_stream.get("next_cpu_state", {}).get("x", -1)) == 0x1E
			and int(b0c0_stream.get("next_cpu_state", {}).get("y", -1)) == 0
			and int(b0c0_stream.get("ram_after", {}).get(0x00EC, -1)) == 0x27
			and int(b0c0_stream.get("ram_after", {}).get(0x00ED, -1)) == 0xB3
			and b0c0_stream.get("command_fetches", []).size() == 8
			and b0c0_stream.get("ram_writes", []).size() == 180
			and b0c0_stream.get("ppu_bus_events", []).size() == 202,
			"ROM `$B306-$B327` fill and `$B328` packet handlers return through `$B1BA` to `$A503`")
		_check(bool(b0c0_stream_ppu.get("ok", false))
			and int(b0c0_stream_ppu.get("nametable_writes_applied", -1)) == 99
			and int(b0c0_stream_ppu.get("ppu_address_after", -1)) == 0x2235
			and int(b0c0_stream_ppu.get("ppuctrl_shadow_after", -1)) == 0x88
			and int(b0c0_stream_ppu_contract.get("ram_mask_shadow_after", -1)) == 0x1E
			and bool(b0c0_stream.get("ppu_memory_samples_match", false)),
			"ROM fill commands and packet bytes reach the live PPU nametable presenter at their source addresses")
		_check(int(b0c0_timing.get("independent_py65_cpu_cycles_to_A503", -1)) == 4121
			and int(b0c0_timing.get("fceux_callback_cycles_to_A503", -1)) == 4118
			and bool(b0c0_timing.get("fceux_pass_1_equals_pass_2", false))
			and int(b0c0_timing.get("unresolved_rts_callback_offset_cycles", -1)) == 3,
			"same-input FCEUX passes reproduce the command-fetch deltas and keep the 3-cycle RTS boundary discrepancy explicit")
		_check(bool(a503_entry.get("ok", false))
			and String(a503_entry.get("status", "")) == "stopped_before_a503_first_data_decoder"
			and int(a503_entry.get("next_cpu_state", {}).get("pc", -1)) == 0xA526
			and int(a503_entry.get("next_cpu_state", {}).get("a", -1)) == 0xBC
			and int(a503_entry.get("next_cpu_state", {}).get("x", -1)) == 0xBC
			and int(a503_entry.get("next_cpu_state", {}).get("y", -1)) == 0xFF
			and int(a503_entry.get("ram_writes", []).size()) == 54
			and int(a503_entry.get("copy_contract", {}).get("byte_count", -1)) == 52
			and int(a503_entry.get("first_decoder_call", {}).get("target_pc", -1)) == 0x9D27
			and int(a503_entry.get("first_decoder_call", {}).get("table_pointer", -1)) == 0xBCFF
			and int(a503_entry.get("source_instruction_cycles_to_decoder_call", -1)) == 816
			and not bool(a503_entry.get("trace_state_used", true))
			and not bool(a503_entry.get("emulator_data_used", true)),
			"ROM `$A503` clears `$44/$45`, copies 52 source bytes, and derives `$BCFF` before `$9D27`")
		var expected_queue := PackedByteArray()
		var expected_payload := [0x42, 0x0B, 0x7A, 0x0D, 0x09, 0x6F, 0x20, 0x43, 0x75, 0x70]
		for index in expected_payload.size():
			expected_queue.append_array([0x82, 0x6A + index, 0x21, 0x00, expected_payload[index]])
		expected_queue.append(0x00)
		var decoder_ram: Dictionary = a503_decoder.get("ram_after", {})
		var decoder_bytes_match: bool = expected_queue.size() == 51 \
			and a503_decoder.get("decoder_result", {}).get("queue_bytes", PackedByteArray()) == expected_queue
		if decoder_bytes_match:
			for offset in expected_queue.size():
				if int(decoder_ram.get(0x05E8 + offset, -1)) != expected_queue[offset]:
					decoder_bytes_match = false
					break
		_check(bool(a503_decoder.get("ok", false))
			and String(a503_decoder.get("status", "")) == "stopped_before_a503_next_setup_block"
			and int(a503_decoder.get("next_cpu_state", {}).get("pc", -1)) == 0xA529
			and int(a503_decoder.get("next_cpu_state", {}).get("a", -1)) == 0xBD
			and int(a503_decoder.get("next_cpu_state", {}).get("x", -1)) == 0xFF
			and int(a503_decoder.get("next_cpu_state", {}).get("y", -1)) == 0x0C
			and a503_decoder.get("ram_writes", []).size() == 119
			and int(a503_decoder.get("decoder_result", {}).get("queue_cursor_after", -1)) == 0x32
			and int(a503_decoder.get("decoder_result", {}).get("queue_control_after", -1)) == 0x82
			and int(a503_decoder.get("decoder_result", {}).get("ppu_bus_events_emitted", -1)) == 0
			and bool(a503_decoder.get("decoder_result", {}).get("buffer_pending_for_rom_nmi", false))
			and decoder_bytes_match
			and not bool(a503_decoder.get("trace_state_used", true))
			and not bool(a503_decoder.get("emulator_data_used", true)),
			"ROM `$BCFF->$9D27->$88CA` creates ten checked `$05E8` queue records and returns to `$A529` without fabricating PPU writes")
		var text_setup: Dictionary = final_handoff.get("a503_text_setup_result", {})
		var drain_history: Array = text_setup.get("queue_drain_history", [])
		var two_drains_match := drain_history.size() == 2
		if two_drains_match:
			for drain_variant in drain_history:
				if not drain_variant is Dictionary \
						or int(drain_variant.get("queue_cursor_before", -1)) != 60 \
						or int(drain_variant.get("ppu_packet_queue", {}).get("packet_count", -1)) != 12 \
						or int(drain_variant.get("ppu_packet_queue", {}).get("payload_bytes", -1)) != 24 \
						or drain_variant.get("ppu_bus_events", []).size() != 66 \
						or int(drain_variant.get("ppu_render_result", {}).get("nametable_writes_applied", -1)) != 24 \
						or bool(drain_variant.get("surrounding_nmi_executed", true)):
					two_drains_match = false
					break
		var final_queue_render: Dictionary = text_setup.get("ppu_render_result", {})
		_check(bool(text_setup.get("ok", false))
			and String(text_setup.get("status", "")) == "stopped_before_a503_fade_helper"
			and int(text_setup.get("next_cpu_state", {}).get("pc", -1)) == 0xA56C
			and int(text_setup.get("next_cpu_state", {}).get("a", -1)) == 0x04
			and int(text_setup.get("next_cpu_state", {}).get("x", -1)) == 0x37
			and int(text_setup.get("next_cpu_state", {}).get("y", -1)) == 0x07
			and int(text_setup.get("capacity_yield_count", -1)) == 2
			and int(text_setup.get("queue_boundary", {}).get("queue_cursor", -1)) == 20
			and int(text_setup.get("queue_boundary", {}).get("queue_control", -1)) == 0x82
			and int(final_queue_render.get("nametable_writes_applied", -1)) == 24
			and two_drains_match
			and not bool(text_setup.get("trace_state_used", true))
			and not bool(text_setup.get("emulator_data_used", true)),
			"ROM `$A529-$A56B` resolves its three text streams and two `$9B28` capacity waits through bounded `$A000` transfers into the live PPU renderer")
		var text_cursor_write_found := false
		var text_control_write_found := false
		for write_variant in text_setup.get("ram_writes", []):
			if not write_variant is Dictionary:
				continue
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) == 0x0628 \
					and int(write.get("source_pc", -1)) == 0x9B63 \
					and int(write.get("value", -1)) == 0x14:
				text_cursor_write_found = true
			if int(write.get("address", -1)) == 0x0629 \
					and int(write.get("source_pc", -1)) == 0x9B6B \
					and int(write.get("value", -1)) == 0x82:
				text_control_write_found = true
		var palette_ramp: Dictionary = final_handoff.get("a503_palette_ramp_result", {})
		var palette_drains: Array = palette_ramp.get("queue_drain_history", [])
		var all_palette_drains_match := palette_drains.size() == 15
		if all_palette_drains_match:
			for drain_variant in palette_drains:
				if not drain_variant is Dictionary \
						or int(drain_variant.get("palette_payload_writes", -1)) != 32 \
						or String(drain_variant.get("palette_payload_hex", "")).length() != 64 \
						or not bool(drain_variant.get("bounded_queue_only", false)) \
						or bool(drain_variant.get("surrounding_nmi_executed", true)):
					all_palette_drains_match = false
					break
		var palette_cpu: Dictionary = palette_ramp.get("details", {}).get("cpu", {})
		_check(bool(palette_ramp.get("ok", false))
			and String(palette_ramp.get("status", "")) == "returned_to_a503_wait_loop"
			and int(palette_ramp.get("iterations", -1)) == 15
			and int(palette_ramp.get("counter_a", -1)) == 15
			and int(palette_ramp.get("counter_b", -1)) == 15
			and int(palette_cpu.get("pc", -1)) == 0xA571
			and int(palette_cpu.get("a", -1)) == 0x1E
			and int(palette_cpu.get("x", -1)) == 0xF0
			and int(palette_cpu.get("y", -1)) == 0x20
			and all_palette_drains_match
			and not bool(palette_ramp.get("trace_state_used", true))
			and not bool(palette_ramp.get("emulator_data_used", true))
			and not bool(palette_ramp.get("physical_nes_timing_proven", true)),
			"ROM `$997A` runs its 15 paired-counter steps and bounded palette drains, then returns at `$A571`")
		var final_palette_hex := String(palette_drains.back().get("palette_payload_hex", "")) \
			if not palette_drains.is_empty() and palette_drains.back() is Dictionary else ""
		var ppu_reference_path := "res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_007288.bin"
		var ppu_reference := FileAccess.get_file_as_bytes(ppu_reference_path)
		var observed_palette_bytes: PackedByteArray = route._visuals.screen.get_background_palette_bytes()
		var reference_palette_bytes := ppu_reference.slice(0x3F00, 0x3F20) \
			if ppu_reference.size() >= 0x3F20 else PackedByteArray()
		var reference_background_palette := reference_palette_bytes.slice(0, 16) \
			if reference_palette_bytes.size() == 32 else PackedByteArray()
		var background_palette_matches := reference_palette_bytes.size() == 32 \
			and final_palette_hex.substr(0, 32) == reference_background_palette.hex_encode()
		if not stopped_after_a611:
			background_palette_matches = background_palette_matches \
				and observed_palette_bytes.size() == 16 \
				and observed_palette_bytes == reference_background_palette
		_check(background_palette_matches,
			"ROM-derived final background palette `$3F00-$3F0F` matches same-input FCEUX PPU frame 7288")
		var final_palette_render: Dictionary = palette_drains.back().get("ppu_render_result", {}) \
			if not palette_drains.is_empty() and palette_drains.back() is Dictionary else {}
		_check(int(final_palette_render.get("background_palette_writes_applied", -1)) == 20
			and final_palette_render.get("unapplied_writes", []).size() == 12,
			"Godot applies 16 background bytes plus four NES palette mirrors, and reports 12 unsupported sprite entries")
		if stopped_after_a611:
			var input_wait: Dictionary = final_handoff.get("a503_input_wait_result", {})
			var wait_cpu: Dictionary = input_wait.get("details", {}).get("cpu", {})
			var wait_sample: Dictionary = input_wait.get("details", {}).get("controller_sample", {})
			var fceux_wait_ram := _read_fceux_ram(7393)
			var fade: Dictionary = final_handoff.get("a503_postwait_fade_result", {})
			var fade_status: Dictionary = fade.get("fade_status", {})
			var fade_packets: Array = fade.get("packet_history", [])
			var clear: Dictionary = fade.get("clear_result", {})
			var clear_contract: Dictionary = clear.get("ppu_clear", {})
			var wait_frame_palette := FileAccess.get_file_as_bytes(
				"res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_007393.bin")
			var clear_frame_ppu := FileAccess.get_file_as_bytes(
				"res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_007408.bin")
			var godot_nametable_clear := true
			var reference_nametable_clear := clear_frame_ppu.size() >= 0x2800
			if reference_nametable_clear:
				for address in range(0x2000, 0x2800):
					if clear_frame_ppu[address] != 0:
						reference_nametable_clear = false
						break
			for address in range(0x2000, 0x2800):
				if int(route._visuals._ppu_memory.get(address, -1)) != 0:
					godot_nametable_clear = false
					break
			var route_palette_after_fade: PackedByteArray = route._visuals.screen.get_background_palette_bytes()
			var ref_palette_after_fade := clear_frame_ppu.slice(0x3F00, 0x3F10) \
				if clear_frame_ppu.size() >= 0x3F10 else PackedByteArray()
			var wait_palette_lit := false
			if wait_frame_palette.size() >= 0x3F20:
				for palette_index in range(0x3F00, 0x3F20):
					if wait_frame_palette[palette_index] != 0x0F:
						wait_palette_lit = true
						break
			var all_reference_palette_black := clear_frame_ppu.size() >= 0x3F20
			if all_reference_palette_black:
				for palette_index in range(0x3F00, 0x3F20):
					if clear_frame_ppu[palette_index] != 0x0F:
						all_reference_palette_black = false
						break
			_check(bool(input_wait.get("ok", false))
				and String(input_wait.get("status", "")) == "returned_to_a57d_on_a_edge"
				and int(input_wait.get("source_frame", -1)) == 7393
				and int(wait_cpu.get("pc", -1)) == 0xA57D
				and int(wait_cpu.get("a", -1)) == 0x80
				and int(wait_cpu.get("x", -1)) == 0x84
				and int(wait_sample.get("newly_pressed", -1)) == 0x80
				and fceux_wait_ram.size() == 0x800
				and fceux_wait_ram[0x001C] == 0x80 and fceux_wait_ram[0x001E] == 0x80
				and wait_palette_lit,
				"live `$A571` sampler takes the recorded frame-7393 A edge at `$A57D` with X=$84; FCEUX RAM/PPU corroborate the boundary")
			var fade_consumers_consecutive := fade_packets.size() == 15
			if fade_consumers_consecutive:
				for packet_index in range(fade_packets.size()):
					var packet_variant: Variant = fade_packets[packet_index]
					if not packet_variant is Dictionary \
							or int(packet_variant.get("producer_source_frame", -1)) != 7393 + packet_index \
							or int(packet_variant.get("consumer_source_frame", -1)) != 7394 + packet_index \
							or int(packet_variant.get("ppu_bus_event_count", -1)) != 40:
						fade_consumers_consecutive = false
						break
			var godot_fade_palette_matches := route_palette_after_fade.size() == 16 \
					and ref_palette_after_fade.size() == 16 \
					and route_palette_after_fade == ref_palette_after_fade
			_check(bool(fade.get("ok", false))
					and String(fade.get("status", "")) == "returned_to_a58b_after_fade_and_clear"
					and fade_packets.size() == 15 and fade_consumers_consecutive
					and int(fade_status.get("counter_a", -1)) == 0
					and int(fade_status.get("counter_b", -1)) == 0
					and bool(clear.get("ok", false))
					and int(clear_contract.get("write_count", -1)) == 0x800
					and godot_nametable_clear and reference_nametable_clear
					and godot_fade_palette_matches and all_reference_palette_black,
					"ROM `$99F0/$A000/$98A0` produces fifteen consumed fade packets and the frame-7408 palette/nametable clear")
			var a611_result: Dictionary = stop_route_status.get("fresh_match_a503_a611_handoff", {})
			var a611_cpu: Dictionary = a611_result.get("cpu_output_contract", {})
			_check(String(a611_result.get("status", "")) == "returned_to_811F"
					and int(a611_cpu.get("pc", -1)) == 0x811F
					and int(a611_cpu.get("a", -1)) == 0x00
					and int(a611_cpu.get("x", -1)) == 0 and int(a611_cpu.get("y", -1)) == 0x03
					and int(a611_cpu.get("sp", -1)) == 0x28
					and int(a611_result.get("checked_home_player_slots", -1)) == 11
					and int(a611_result.get("changed_level_count", -1)) == 0
					and int(a611_result.get("source_frame", -1)) == 7409,
				"ROM `$A611` checks all eleven match-00 home slots and returns through `$A610` to `$811F` on frame 7409")
		var fceux_level_ram := _read_fceux_ram(7409)
		var source_loop_state_ok := fceux_level_ram.size() == 0x800
		if source_loop_state_ok:
			for address in [0x00EB, 0x00EC, 0x00ED]:
				var live_byte: Dictionary = route._source_ram_image.get_byte(address)
				if not bool(live_byte.get("known", false)) or int(live_byte.get("value", -1)) != fceux_level_ram[address]:
					source_loop_state_ok = false
			for slot in 11:
				for address in [0x0303 + slot * 0x0C, 0x0656 + slot]:
					var live_byte: Dictionary = route._source_ram_image.get_byte(address)
					if not bool(live_byte.get("known", false)) or int(live_byte.get("value", -1)) != fceux_level_ram[address]:
						source_loop_state_ok = false
		_check(source_loop_state_ok
			and int(fceux_level_ram[0x00EB]) == 0
			and int(fceux_level_ram[0x00EC]) == 0
			and int(fceux_level_ram[0x00ED]) == 0x0B,
			"source `$A611` loop counters, unchanged level bytes, and empty level-up list agree with FCEUX frame 7409")
		if stopped_at_812f or stopped_at_a64c:
			var music_result: Dictionary = stop_route_status.get("fresh_match_setup_music_store", {})
			var stamina_result: Dictionary = stop_route_status.get("fresh_match_stamina_initialization", {})
			var stamina_rows: Array = stamina_result.get("home_player_energy", [])
			var profile_map := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/menus/first_action_menu/player_stat_profile_map_00_22.bin")
			var stamina_profiles := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/first_match_player_state/stamina_profile_values_AE86_AFAE.bin")
			var stamina_values := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/first_match_player_state/stamina_value_words_9F0E_9FCD.bin")
			var player_curves := FileAccess.get_file_as_bytes(
				"res://reference/rom_extract/gameplay/first_match_player_state/stamina_player_curves_9FCE_A596.bin")
			var stamina_source_values_match := fceux_level_ram.size() == 0x800 \
				and profile_map.size() == 0x23 * 4 and stamina_profiles.size() == 0x25 * 8 \
				and stamina_values.size() == 0x60 * 2 and player_curves.size() == 0x25 * 0x28 \
				and stamina_rows.size() == 11
			if stamina_source_values_match:
				for row_variant in stamina_rows:
					if not row_variant is Dictionary:
						stamina_source_values_match = false
						break
					var row: Dictionary = row_variant
					var record_address := int(row.get("record_address", -1))
					var player_id := int(row.get("player_id", -1))
					var level := int(row.get("level", -1))
					if player_id < 0 or player_id >= 0x23 or level < 0 \
							or record_address != 0x0300 + int(row.get("slot", -1)) * 0x0C \
							or fceux_level_ram[record_address] != player_id \
							or fceux_level_ram[record_address + 3] != level:
						stamina_source_values_match = false
						continue
					var profile_id := int(profile_map[player_id * 4])
					var use_common_profile_row := int(row.get("slot", -1)) == 0
					var expected_curve_pc := 0x80B2 if use_common_profile_row else 0x80D1
					var curve_base := int(stamina_profiles[profile_id * 8]) if use_common_profile_row \
						else int(player_curves[profile_id * 0x28])
					var curve_index := mini(0x5F, curve_base + level)
					var value_offset := curve_index * 2
					var expected_energy := int(stamina_values[value_offset]) \
						| (int(stamina_values[value_offset + 1]) << 8)
					if player_id == 0x20 and fceux_level_ram[0x044D] != 0:
						expected_energy = 0
					if int(row.get("profile_id", -1)) != profile_id \
							or int(row.get("stamina_curve_index", -1)) != curve_index \
							or int(row.get("maximum_energy", -1)) != expected_energy:
						stamina_source_values_match = false
					if int(row.get("curve_source_pc", -1)) != expected_curve_pc:
						stamina_source_values_match = false
					for address in [record_address + 1, record_address + 2]:
						var live_byte: Dictionary = route._source_ram_image.get_byte(address)
						var expected_byte := expected_energy & 0xFF \
							if address == record_address + 1 else (expected_energy >> 8) & 0xFF
						if not bool(live_byte.get("known", false)) \
								or int(live_byte.get("value", -1)) != expected_byte:
							stamina_source_values_match = false
			_check(String(music_result.get("status", "")) == "returned_to_812F"
				and String(stamina_result.get("status", "")) == "returned_to_8122"
				and int(stamina_result.get("checked_home_player_slots", -1)) == 11
				and int(stamina_result.get("energy_write_count", -1)) == 22
				and stamina_source_values_match,
				"ROM `$C572->$DB62` writes all eleven ROM-table stamina values and returns to `$8122`; frame-7409 FCEUX RAM validates input roster and levels")
			var music_event: Dictionary = music_result.get("queue_event", {})
			var music_cpu: Dictionary = music_result.get("cpu_output_contract", {})
			var live_audio_applied := false
			for event_variant in stop_route_status.get("sound_queue_write_events", []):
				if not event_variant is Dictionary:
					continue
				var event: Dictionary = event_variant
				if String(event.get("event_origin", "")) == "rom_direct_queue_store" \
						and int(event.get("queue_id", -1)) == 0x55 \
						and int(event.get("queue_store_instruction_pc", -1)) == 0x812C \
						and int(event.get("post_store_pc", -1)) == 0x812F:
					live_audio_applied = bool(event.get("applied", false)) \
						and int(event.get("route_frame", -1)) == route.source_frame - 1
			var live_music_queue := route._source_ram_image.get_byte(0x0700)
			_check(String(music_result.get("status", "")) == "returned_to_812F"
				and int(music_result.get("match_index_0026", -1)) == 0
				and int(music_result.get("selected_queue_id", -1)) == 0x55
				and int(music_cpu.get("pc", -1)) == 0x812F
				and int(music_cpu.get("x", -1)) == 0x55
				and int(music_event.get("queue_store_instruction_pc", -1)) == 0x812C
				and int(music_event.get("route_frame", -1)) == route.source_frame - 1
				and int(music_event.get("source_frame", -2)) == -1,
				"live `$0026=0` caller branch reaches `$812C` and selects BGM `$55`")
			_check(bool(live_music_queue.get("known", false))
				and int(live_music_queue.get("value", -1)) == 0x55,
				"ROM `$812C` stores BGM `$55` into live RAM `$0700`")
			_check(int(music_event.get("cpu_cycle", -2)) == -1
				and not bool(music_event.get("timing_verified", true))
				and live_audio_applied,
				"direct ROM queue event reaches the ROM-cue presenter with timing left unknown")
			if stopped_at_a64c:
				var tail: Dictionary = stop_route_status.get("fresh_match_caller_tail", {})
				var prefix: Dictionary = tail.get("caller_prefix", {})
				var mapper: Dictionary = tail.get("mapper_helper", {})
				var entry: Dictionary = tail.get("a009_entry", {})
				var caller_ram_matches_fceux := fceux_level_ram.size() == 0x800
				for address in [0x0023, 0x0025, 0x0450, 0x0451, 0x0452, 0x0453, 0x0700]:
					var live_byte: Dictionary = route._source_ram_image.get_byte(address)
					if not bool(live_byte.get("known", false)) \
							or int(live_byte.get("value", -1)) != fceux_level_ram[address]:
						caller_ram_matches_fceux = false
				_check(String(final_handoff.get("status", "")) == "transferred_to_A64C"
					and int(final_handoff.get("pending_source_pc", -1)) == 0xA64C
					and String(tail.get("status", "")) == "transferred_to_A64C"
					and prefix.get("ram_writes", []).size() == 4
					and int(prefix.get("mapper_source_call", {}).get("caller_pc", -1)) == 0x813F
					and String(mapper.get("status", "")) == "returned"
					and mapper.get("mapper_bus_writes", []).size() == 2
					and bool(entry.get("ok", false))
					and String(entry.get("entry_bytes", "")) == "4c4ca6"
					and int(entry.get("target_pc", -1)) == 0xA64C
					and caller_ram_matches_fceux,
					"ROM `$812F-$8142` clears and `$813F->$C4B9->$A009->$A64C` entry match frame-7409 FCEUX RAM")
		var source_copy := _read_fceux_ram(7368)
		var modeled_copy: Dictionary = a503_entry.get("ram_after", {})
		print("A503 queue entry `$0628/$0629`: runtime=%s source-ledger=%s/%s" % [
			JSON.stringify({"$0628": modeled_copy.get(0x0628, "unknown"),
				"$0629": modeled_copy.get(0x0629, "unknown")}),
			JSON.stringify(route._source_ram_image.get_byte(0x0628)),
			JSON.stringify(route._source_ram_image.get_byte(0x0629)),
		])
		var copy_matches_fceux := source_copy.size() == 0x800 and modeled_copy.size() > 0
		if copy_matches_fceux:
			for offset in 52:
				if int(modeled_copy.get(0x0468 + offset, -1)) != source_copy[0x0468 + offset]:
					copy_matches_fceux = false
					break
		_check(copy_matches_fceux and source_copy[0x0044] == 0 and source_copy[0x0045] == 0,
			"same-input FCEUX frame 7368 corroborates the A503 `$0468-$049B` copy and scratch clears")
		var predecode_queue_evidence: Dictionary = a503_decoder.get("queue_state_evidence", {})
		var predecode_queue_values: Dictionary = predecode_queue_evidence.get("known_values", {})
		var predecode_queue_writers: Dictionary = predecode_queue_evidence.get("last_write_by_address", {})
		var queue_flag_writer: Dictionary = predecode_queue_writers.get(0x0629, {})
		_check(int(predecode_queue_values.get(0x0629, -1)) == 0x20
			and int(queue_flag_writer.get("source_pc", -1)) == 0x9B6B
			and String(queue_flag_writer.get("event_id", "")).begins_with("cleanup_palette_queue_flag_"),
			"ROM `$9B28` palette-packet source leaves `$0629=$20` before the A503 descriptor runs")
		var queue_cursor_source: Dictionary = route._source_ram_image.get_byte(0x0628)
		var queue_cursor_writer: Dictionary = queue_cursor_source.get("last_write", {})
		var descriptor_control_source: Dictionary = route._source_ram_image.get_byte(0x0629)
		var descriptor_control_writer: Dictionary = descriptor_control_source.get("last_write", {})
		var queue_cursor_event := "fresh_match_a503_postwait_fade_consumer_" \
			if stopped_after_a611 else "fresh_match_a503_palette_ramp_frame_"
		var descriptor_control_event := "fresh_match_a503_postwait_fade_queue_" \
			if stopped_after_a611 else "fresh_match_a503_palette_ramp_frame_"
		_check(text_cursor_write_found and text_control_write_found
			and bool(queue_cursor_source.get("known", false))
			and int(queue_cursor_source.get("value", -1)) == 0
			and int(queue_cursor_writer.get("source_pc", -1)) == 0xA04A
			and String(queue_cursor_writer.get("event_id", "")).begins_with(queue_cursor_event)
			and bool(descriptor_control_source.get("known", false))
			and int(descriptor_control_source.get("value", -1)) == 0x20
			and int(descriptor_control_writer.get("source_pc", -1)) == 0x9B6B
			and String(descriptor_control_writer.get("event_id", "")).begins_with(descriptor_control_event),
			"text setup records `$9B63/$9B6B` writes; the final ROM palette drain clears `$0628` and restores control `$20`")
		_check(bool(wait_irq.get("ok", false))
			and String(wait_irq.get("kind", "")) == "rom_irq_wait_release"
			and String(release.get("source_event_id", "")).begins_with(String(wait_irq.get("source_event_id", "")))
			and int(release.get("source_pc", -1)) == 0xA1C3
			and int(release.get("before", -1)) == 4 and int(release.get("value", -1)) == 0
			and bool(wait_irq.get("interrupt_stack_balanced", false))
			and not bool(wait_irq.get("physical_nes_timing_proven", true)),
			"ROM-byte raster IRQ releases `$78` and balances the stack while keeping subframe timing unproven")
		_check(bool(wait_tail.get("ok", false))
			and String(wait_tail.get("status", "")) == "returned_to_fresh_match_caller"
			and int(wait_tail.get("final_source_pc", -1)) == 0x8117
			and String(postwait.get("source_event_id", "")).length() > 0,
			"ROM `$893F-$895C` returns through `$8117` into the checked match caller")
	elif not reached_scenario36_boundary and not stopped_at_handoff_gap \
			and not stopped_at_preset_wait and not stopped_at_a503_text_setup \
			and not stopped_at_a503_wait_loop and not stopped_after_a611 \
			and not stopped_at_scenario36_e0df and not stopped_at_slot15_map36_yield \
			and not stopped_at_slot15_map2d_yield \
			and not stopped_at_scenario44_field_boundary:
		var stopped_task_reason := String(stop_route_status.get("fresh_source_route_task", {}).get("reason", ""))
		_check(String(stop_source_route.get("error", "")).length() > 0 or not stopped_task_reason.is_empty(),
			"unresolved route gap retains its source-level failure reason")
	if expect_scenario36_boundary:
		var nmi_result: Dictionary = stop_route_status.get("fresh_source_route_nmi", {})
		var task_result: Dictionary = stop_route_status.get("fresh_source_route_task", {})
		var receiver_result: Dictionary = task_result.get("receiver_result", {})
		var holder_result: Dictionary = task_result.get("holder_copy_result", {})
		var scenario36_result: Dictionary = task_result
		var scenario36_queue_result: Dictionary = scenario36_result.get("scenario36_queue_result", {})
		var initializer_result: Dictionary = task_result.get("position_initializer_result", {})
		var wait_result: Dictionary = nmi_result.get("slot05_wait_result",
			nmi_result.get("slot05_scenario_wait_result", {}))
		var call_request: Dictionary = nmi_result.get("position_initializer_call_request", {})
		var live_ram: PackedByteArray = final_slot05.get("ram_image", PackedByteArray())
		_check(reached_scenario36_boundary, "recorded A press executes position setup, receiver selection, holder copy, and scenario `$36` yield through `$CB0F`")
		_check(String(nmi_result.get("status", "")) == "stopped_at_slot05_dc07_call_boundary",
			"ROM-byte input branch reaches the `$DAF2->$DC07` call")
		_check(int(wait_result.get("exit_pc", -1)) == 0xDAF2,
			"ROM-byte wait path exits at `$DAF2` under the recorded input")
		_check(int(call_request.get("target_pc", -1)) == 0xDC07,
			"ROM-byte `$DAF2` call targets the position initializer")
		_check(String(initializer_result.get("status", "")) == "returned_to_slot05_caller_DAF5",
			"hash-checked `$DC07` callee returns at its source caller boundary")
		_check(String(receiver_result.get("status", "")) == "stopped_at_slot05_e6ec_holder_call_boundary",
			"ROM-byte `$DAF5` caller reaches its `$E6EC` handoff")
		_check(String(holder_result.get("status", "")) == "returned_to_slot05_db0e_before_scenario36",
			"ROM-byte `$E6EC/$CDE2` holder copy returns before scenario `$36`")
		_check(live_ram.size() == 0x800 and live_ram[0x001C] == 0x80 and live_ram[0x001E] == 0x80,
			"source-frame sampler writes held A `$001C=$80` and new A edge `$001E=$80`")
		_check(live_ram.size() == 0x800 and live_ram[0x0441] == 8,
			"ROM `$DAEF` writes holder slot 8 to `$0441`")
		_check(String(scenario36_result.get("status", "")) == "scenario36_queued_slot05_yielded_and_scheduler_scanned",
			"source route executes `$DB0E->$CBB0->$CB0F`, saves slot `$05`, and scans the scheduler")
		_check(String(scenario36_queue_result.get("status", "")) == "scenario36_queue_at_cb0f_entry",
			"scenario `$36` queue executor reports the ROM-derived `$CB0F` entry")
		_check(int(scenario36_queue_result.get("registers", {}).get("pc", -1)) == 0xCB0F \
				and int(scenario36_queue_result.get("registers", {}).get("sp", -1)) == 0x4C,
			"nested source JSR frames reach `$CB0F` with the expected task stack")
		_check(int(final_slot05.get("pc", -1)) == 0xCB0F and int(final_slot05.get("sp", -1)) == 0x4A \
				and int(final_slot05.get("phase", -1)) == 3,
			"scheduler saves slot `$05` at the yielded `$CB0F` boundary")
		_check(int(scenario36_result.get("next_selected_task_slot", -1)) == 0x09 \
				and String(stop_source_route.get("phase", "")) == "stopped_before_scenario36_slot09_dispatch",
			"post-yield scan selects slot `$09` and stops before its scenario consumer runs")
		_check(not bool(scenario36_result.get("next_external_nmi_required", true)),
			"selected slot `$09` is pending dispatch before another external NMI")
		_check(live_ram.size() == 0x800 and live_ram[0x00E2] == 0xBE and live_ram[0x05FC] == 6,
			"live ROM RNG `$E2=$BE` and `$DC82` resolve receiver slot 6")
		_check(live_ram.size() == 0x800 and live_ram[0x0034] == 0x60 \
				and live_ram[0x0035] == 0x03 and live_ram[0x0635] == 0x7C \
				and live_ram[0x0637] == 0x7C and live_ram[0x05FE] == 0x71,
			"live `$E6EC` copies holder slot 8's ROM-derived coordinates and `$CDE2` index")
		_check(route.get_route_status().get("initial_player_positions", []).size() == 22,
			"all 22 player positions are consumed into the live route")
		var oracle_comparison := _compare_all_position_records(
			live_ram, initializer_result.get("positions", []))
		_check(oracle_comparison == "matched_22",
			"all 22 ROM-derived position pairs match the same-input FCEUX frame-8593 RAM oracle (%s)" % oracle_comparison)
		_check(_has_button_change(events, 8594, "A", false),
			"recorded input dispatch includes the frame-8594 A release")
	if expects_first_pass_decision_wait:
		_check(_menu_confirmation_requests == [FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.PASS],
			"the recorded route confirms exactly one PASS command and no later soccer action")
	else:
		_check(int(stop_route_status.get("selected_action_id", -2)) == -1,
			"no soccer action is selected before the initial command menu")
	_check(not bool(stop_route_status.get("continue_entered", false)),
		"Continue flow remains outside the recorded route")
	if menu_endpoint_reached:
		var actor_status: Dictionary = route._visuals.first_command_actor_status
		_check(bool(actor_status.get("ok", false)) and int(actor_status.get("sprite_count", 0)) > 0,
			"the first-menu actors are composed from the live ROM scheduler's shared render state")
		print("First-command actor source status: ", JSON.stringify(actor_status))
		if route._fresh_source_route_runner != null:
			print("Verified stamina worker receipt: ", JSON.stringify(
				route._fresh_source_route_runner._verified_stamina_update_receipt))
		print("Endpoint background palette: %s; carried source PPU overlay: %s" % [
			route._visuals.screen.get_background_palette_bytes().hex_encode(),
			JSON.stringify(route._visuals._source_ppu_background_palette_overlay)])
	print("Recorded-input stage checkpoints: ", JSON.stringify(_stage_at_checkpoints))
	_print_cutscene_pointer_timing_audit()
	if route.source_frame >= 8443:
		_save_background_image(route, route.source_frame)
	if menu_endpoint_reached:
		# The title scene remains alive as the source of the handoff palette, but
		# it must not underlay the route's endpoint viewport capture.
		if title_runtime is CanvasItem:
			(title_runtime as CanvasItem).visible = false
		await _save_full_route_viewport(route, route.source_frame)
		_verify_live_first_action_menu_navigation(route)
	elif expects_first_pass_decision_wait:
		_check(reached_first_pass_decision_wait,
			"recorded PASS route reaches frame %d at slot-$05 `$D5EA` input wait with holder `$0A`" \
			% FIRST_PASS_DECISION_FRAME)
		if reached_first_pass_decision_wait:
			# This next `$D5EA` wait is an input boundary, not a redrawn command menu.
			if title_runtime is CanvasItem:
				(title_runtime as CanvasItem).visible = false
			await _save_full_route_viewport(route, route.source_frame,
				FIRST_PASS_DECISION_VIEWPORT_PNG)
		else:
			print("LIMIT: PASS endpoint viewport was not captured; see the failed endpoint assertion above.")

	if _failures == 0 and menu_endpoint_reached:
		print("PASS: recorded post-title inputs replay through the ROM-backed route to the initial command menu at frame %d." % route.source_frame)
		print("LIMIT: this verifier proves the recorded route/menu boundary and frame-level queue events. Exact endpoint pixels and production Godot route PCM are checked by dedicated same-input comparisons; intermediate-frame PPU phase and physical NES/output-device timing remain separate limits.")
	elif _failures == 0 and reached_first_pass_decision_wait:
		print("PASS: the recorded PASS route reaches the frame-%d holder input wait with holder `$0A`." % FIRST_PASS_DECISION_FRAME)
		print("LIMIT: same-input endpoint pixel comparison, production route PCM parity, and fresh isolated export remain separate acceptance checks.")
	elif _failures == 0 and expect_scenario36_boundary and reached_scenario36_boundary:
		print("PASS: recorded frame-8593 A input executes `$DC07`, holder selection, scenario `$36` through `$CB0F`, and the next slot-$09 selection.")
		print("LIMIT: scenario event continuation, field PPU/audio parity, and the initial command menu remain open.")
	elif _failures == 0 and stopped_at_handoff_gap:
		print("PASS: recorded-input route reaches and holds at the unresolved `$82DF->$9BA0` cleanup boundary at frame %d." % route.source_frame)
		print("LIMIT: this is not completion of the goal; cleanup, fresh-match handoff, field rendering, and the first command menu remain open.")
	elif _failures == 0 and stopped_at_slot15_map36_yield:
		print("PASS: recorded-input route enters callback `$45`, selects map `$36`, applies its `$00/$3C` CHR pair, and reaches the queue-gated map worker boundary at frame %d." % route.source_frame)
		if map36_batch_start_index >= 3:
			print("PASS: normal NMI consumes the prior `$0515` secondary queue (15 packets; 51 nametable writes applied), then the route produces the next ROM-derived three-metatile batch.")
		print("LIMIT: remaining map `$36` rows and complete field composition/actors/menu, same-input visible/audio parity, timing, and ROM-free packaged runtime remain open.")
	elif _failures == 0 and stopped_at_slot15_map2d_yield:
		if stopped_at_slot15_map2d_batch_yield:
			print("PASS: recorded-input route resumes the live slot-$15 `$8572` map-$2D worker and builds 96 ROM-derived queue bytes for metatiles `$00/$71/$72` at placements `$80-$82`.")
			print("PASS: each queue group matches its source tile and attribute bytes; RAM advances to `$05C7/$05C8/$05C9=$60/$83/$1D` and the worker yields at `$856F`.")
			print("LIMIT: the normal NMI transfer/render after this batch, full map, receiver/holder result, actor motion, same-input screen/audio parity, next input wait, timing, and fresh export remain open.")
		else:
			print("PASS: recorded-input route executes PASS scenario `$38`, callback `$34`, and the live map `$2D` `$8525->$856F->$C515` setup, then saves slot `$15` and returns to the scheduler NMI wait at frame %d." % route.source_frame)
			print("PASS: selector `$02`, CHR `$00/$02`, source map block `$9104`, and first map-cell IDs `$00/$71/$72` derive from packaged ROM bytes.")
			print("LIMIT: resumed `$8572` rows/PPU packets, complete receiver/holder result, actor motion, screen/audio parity, next input wait, timing, and fresh export remain open.")
	elif _failures == 0 and stopped_at_scenario36_e0df:
		print("PASS: recorded-input route executes the descriptor-$00 ROM worker through `$8886->$C515->$CB0F`, saves slot `$05`, and scans the scheduler at frame %d." % route.source_frame)
		print("LIMIT: subsequent task/PPU packet processing, descriptor `$01`, scenario `$1E` field setup, visible field, first command menu/navigation, route audio parity, and ROM/emulator-free packaging remain open.")
	elif _failures == 0 and stopped_at_a64c:
		print("PASS: recorded route executes `$A611`, the ROM-table `$C572->$DB62` stamina pass, stores BGM `$55`, clears `$0450-$0453`, selects mapper bank `$01`, and follows `$A009->$A64C`; frame-7409 caller RAM matches FCEUX. Route stops at `$A64C` at frame %d. Stamina outputs match ROM tables, but no post-call capture verifies them." % route.source_frame)
		print("LIMIT: `$A64C` body and later pre-match setup, field/menu composition and navigation, post-call FCEUX energy comparison, same-input audio/onset and subframe timing, earlier interrupt effects, and ROM/emulator-free packaging remain open.")
	elif _failures == 0 and stopped_at_scenario44_field_boundary:
		var field_blocked_read: Dictionary = scenario44_field_entry.get("blocked_read", {})
		print("PASS: same-input route executes scenario `$44`'s `$E38F->$8003` caller, then %d ROM-derived field-entry instructions to `$%04X` at frame %d." % [
			int(scenario44_field_entry.get("instruction_count", 0)),
			int(scenario44_field_entry.get("exit_pc", -1)), route.source_frame])
		print("LIMIT: field-entry boundary=%s; field PPU composition, command menu, same-input audio/timing parity, and ROM/emulator-free packaging remain open." % str(field_blocked_read))
	elif _failures == 0 and stopped_at_811f:
		print("PASS: recorded route executes `$A611` for all eleven fresh match-00 home slots and returns through `$A610` to `$811F` at frame %d. The frame-7393 A edge, fifteen fade packets, frame-7408 palette/nametable clear, and frame-7409 level-loop RAM agree with the matching FCEUX observations." % route.source_frame)
		print("LIMIT: this closes only the zero-experience fresh-start branch. `$811F` continuation, full match initialization, field/menu composition and navigation, audio parity, exact subframe timing, earlier interrupt effects, and packaged runtime independence remain open.")
	elif _failures == 0 and stopped_at_a503_wait_loop:
		print("PASS: recorded route executes ROM `$A4EB`, `$B305-$B327`, `$A503` text setup, and the 15-step `$997A` palette ramp; its background palette matches same-input FCEUX frame 7288. It stops at `$A571` on frame %d." % route.source_frame)
		print("LIMIT: frame 7288 is four frames after Godot's route stop, so this is palette-value corroboration, not same-frame timing proof. `$A571` input/timeout, `$99F0/$98A0` cleanup, `$A611` setup, `$811F` return, surrounding NMI/controller/audio work, 12 sprite-palette entries, earlier interrupt history, field/menu parity, route audio, and ROM-free packaging remain open.")
	elif _failures == 0 and stopped_at_a503_text_setup:
		print("PASS: recorded route executes the ROM `$A4EB` prefix, `$B305-$B327` PPU stream, `$A503` copy/descriptor, all three checked ROM text readers, and two queue-capacity drains; FCEUX frame 7368 agrees on the A503 copy. It stops before `$997A` at frame %d with four text records pending." % route.source_frame)
		print("LIMIT: the two drains model only the bounded `$A000` packet transfer, not surrounding NMI/controller/audio work. Remaining `$997A` palette ramp, `$A571` input wait, `$811F` return, earlier interrupt history, field/menu parity, route audio, and ROM-free packaging remain open.")
	elif _failures == 0 and stopped_at_preset_wait:
		print("PASS: recorded-input route forms an interrupt-free projection to `$893B` at frame %d, reports the pending `$8117` continuation, and sends the ROM `$8107` `$0700=$01` stop write to the audio presenter." % route.source_frame)
		print("LIMIT: this is not the FCEUX-observed wait state: the frame-8 NMI source path ran through RTI, but fourteen earlier NMI/IRQ effects and `$78` release remain unresolved; the first command menu, same-input presentation/audio parity, and ROM-free runtime remain incomplete.")
	elif _failures == 0:
		printerr("INCOMPLETE: route stopped at a source boundary before the initial command menu.")
		_failures += 1
	else:
		printerr("FAIL: %d recorded-input route assertion(s)" % _failures)
	route.cue_audio.release_rom_audio_resources()
	route.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if _failures == 0 else 1)


func _has_button_change(events: Dictionary, frame: int, name: String, pressed: bool) -> bool:
	for change_variant in events.get(frame, []):
		if change_variant is Dictionary \
				and String(change_variant.get("name", "")) == name \
				and bool(change_variant.get("pressed", false)) == pressed:
			return true
	return false


func _verify_eb_post_wait_route_batches(route: KickoffRouteRuntime, stop_frame: int) -> void:
	if stop_frame < 5746:
		_check(false, "recorded route reaches both EB post-wait clear helpers")
		return
	var history: Array[Dictionary] = route._cutscene_eb_post_wait_batch_history
	_check(history.size() >= 8,
		"two recorded EB waits each stage four `$9B28` zero-fill batches")
	var expected_event_indices := [14, 14, 14, 14, 18, 18, 18, 18]
	var expected_frames := [5443, 5444, 5445, 5446, 5743, 5744, 5745, 5746]
	for history_index in mini(history.size(), expected_event_indices.size()):
		var entry: Dictionary = history[history_index]
		_check(int(entry.get("event_index", -1)) == expected_event_indices[history_index]
			and int(entry.get("source_frame", -1)) == expected_frames[history_index]
			and int(entry.get("batch_index", -1)) == history_index % 4
			and int(entry.get("queue_cursor_after", -1)) == 0x30,
			"EB source batch %d advances on its recorded source frame" % history_index)
	_check(history.size() >= expected_event_indices.size(),
		"both EB task histories include their final packet batch")
	for observation: Dictionary in [
		{"frame": 5443, "pc": 0xA2E1, "queue_cursor": 0x30},
		{"frame": 5446, "pc": 0xA2E2, "queue_cursor": 0x35},
		{"frame": 5743, "pc": 0xA2F8, "queue_cursor": 0x30},
		{"frame": 5746, "pc": 0xA2F9, "queue_cursor": 0x30},
	]:
		var ram := _read_fceux_ram(int(observation["frame"]))
		_check(ram.size() == 0x800
			and (ram[0x004D] | (ram[0x004E] << 8)) == int(observation["pc"])
			and ram[0x0628] == int(observation["queue_cursor"]),
			"FCEUX frame %d corroborates EB PC and `$0628` queue cursor" % int(observation["frame"]))
	if stop_frame >= 5800:
		var final_ram := _read_fceux_ram(5800)
		_check(final_ram.size() == 0x800 and final_ram[0x0628] == 0
			and int(route._visuals.get_eb_post_wait_clear_source_inputs().get("source_queue_cursor_0628", -1)) == 0,
			"source queue accounting drains to zero like FCEUX after both EB clears")


func _read_fceux_ram(source_frame: int) -> PackedByteArray:
	return FileAccess.get_file_as_bytes("%s/route_frame_%06d.bin" % [FCEUX_RAM_TRACE_DIR, source_frame])


func _verify_f9_return_boundary(final_frame: int) -> void:
	if final_frame < 7119:
		return
	var checkpoint: Dictionary = _stage_at_checkpoints.get(7119, {})
	var task: Dictionary = checkpoint.get("cutscene_background_task", {})
	_check(int(checkpoint.get("fceux_script_pointer", -1)) == 0xA38B
		and int(checkpoint.get("vm_source_pc", -1)) == 0xA38B,
		"F9 loader resumes at ROM `$A38B` on the same frame as the FCEUX replay")
	_check(String(task.get("state", "")) == "completed"
		and int(task.get("return_scan_source_frame", -1)) == 7118
		and int(task.get("nmi_queue_release_count", -1)) == 7,
		"F9 task releases seven groups by frame 7118; its ROM caller resumes at `$A38B` on frame 7119")


func _compare_all_position_records(live_ram: PackedByteArray, positions: Array) -> String:
	if not FileAccess.file_exists(POSITION_RAM_ORACLE):
		return "oracle unavailable"
	var oracle := FileAccess.get_file_as_bytes(POSITION_RAM_ORACLE)
	if live_ram.size() != 0x0800 or oracle.size() != 0x0800 or positions.size() != 22:
		return "malformed RAM or position input"
	for position_variant in positions:
		if not position_variant is Dictionary:
			return "malformed position record"
		var position: Dictionary = position_variant
		var record_address := int(position.get("record_address", -1))
		var x_offset := int(position.get("x_record_offset", -1))
		var y_offset := int(position.get("y_record_offset", -1))
		if record_address < 0 or record_address + max(x_offset, y_offset) >= 0x0800:
			return "record pointer out of bounds"
		for offset_name: String in ["x", "y"]:
			var offset := x_offset if offset_name == "x" else y_offset
			if live_ram[record_address + offset] != oracle[record_address + offset] \
					or int(position.get(offset_name, -1)) != oracle[record_address + offset]:
				return "slot %d %s differs" % [int(position.get("global_slot", -1)), offset_name]
	return "matched_22"


func _read_recorded_edges() -> Dictionary:
	var file := FileAccess.open(INPUT_CSV, FileAccess.READ)
	if file == null:
		return {}
	file.get_csv_line()
	var result: Dictionary = {}
	var previous: Dictionary = {}
	var button_names := ["Up", "Down", "Left", "Right", "A", "B", "Start", "Select"]
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 10:
			continue
		var source_frame := int(row[0])
		var current: Dictionary = {}
		for index in range(2, 10):
			if row[index] == "1":
				current[button_names[index - 2]] = true
		var changes: Array[Dictionary] = []
		for button_name: String in button_names:
			var was_pressed := bool(previous.get(button_name, false))
			var is_pressed := bool(current.get(button_name, false))
			if was_pressed != is_pressed:
				changes.append({"name": button_name, "pressed": is_pressed})
		if source_frame > 4693 and not changes.is_empty():
			result[source_frame] = changes
		previous = current
	if OS.get_environment("CT2_ROUTE_CHECK_FIRST_PASS_INPUT").strip_edges() == "1":
		var action_file := FileAccess.open(FIRST_PASS_INPUT_EDGES_CSV, FileAccess.READ)
		if action_file == null:
			return {}
		action_file.get_csv_line()
		while not action_file.eof_reached():
			var action_row := action_file.get_csv_line()
			if action_row.size() < 3:
				continue
			var action_frame := int(action_row[0])
			var action_button := String(action_row[1]).strip_edges()
			var action_pressed := String(action_row[2]).strip_edges() == "1"
			if action_frame <= 9042 or action_button.is_empty():
				continue
			if not result.has(action_frame):
				result[action_frame] = []
			(result[action_frame] as Array).append({"name": action_button, "pressed": action_pressed})
	return result


func _try_write_route_checkpoint(route_status: Dictionary, source_frame: int,
		output_path: String, expected_pc: int, expected_timer: int,
		expected_result_pc: int, route: Node) -> Dictionary:
	if expected_pc != 0xE14A:
		if not is_instance_valid(route) or route._fresh_source_route_runner == null:
			return {}
		var scheduler = route._fresh_source_route_runner._scheduler
		if scheduler == null:
			return {}
		var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
		var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
		var stack_page: PackedByteArray = boundary.get("stack_page", PackedByteArray())
		if int(boundary.get("pc", -1)) != expected_pc \
				or int(boundary.get("active_task_slot", -1)) != 0x05 \
				or ram.size() != 0x800 or stack_page.size() != 0x100 \
				or (expected_pc == 0x8112 and (int(boundary.get("bank_low", -1)) != 0x1A \
					or int(boundary.get("bank_high", -1)) != 0x1B or int(ram[0x0518]) != 0x18)) \
				or ram.slice(0x0100, 0x0200) != stack_page:
			return {}
		var input_bytes := FileAccess.get_file_as_bytes(INPUT_CSV)
		var checkpoint := {"schema_version": 1,
			"origin": "ordinary_input_godot_source_route_boundary",
			"rom_sha256": TITLE_HANDOFF_ROM_SHA256,
			"input_trace_sha256": _sha256(input_bytes),
			"source_frame": source_frame,
			"route_stage": String(route_status.get("stage", "")),
			"active_task_slot": 0x05, "slot_base": 0x05,
			"pc": expected_pc, "source_label": String(boundary.get("source_label", "")),
			"registers": {"a": int(boundary.get("a", -1)),
				"x": int(boundary.get("x", -1)), "y": int(boundary.get("y", -1)),
				"p": int(boundary.get("p", -1)),
				"p_known_mask": int(boundary.get("p_known_mask", -1)),
				"sp": int(boundary.get("sp", -1)), "pc": expected_pc},
			"mapper": boundary.get("mapper", {}).duplicate(true),
			"bank_low": int(boundary.get("bank_low", -1)),
			"bank_high": int(boundary.get("bank_high", -1)),
			"ram_sha256": _sha256(ram), "ram_hex": ram.hex_encode(),
			"stack_page_sha256": _sha256(stack_page),
			"stack_page_hex": stack_page.hex_encode()}
		var general_output := FileAccess.open(output_path, FileAccess.WRITE)
		if general_output == null:
			return {"matched": true, "saved": false, "error": "could not open %s" % output_path}
		general_output.store_string(JSON.stringify(checkpoint))
		general_output.close()
		print("Godot source-route checkpoint saved: frame=%d pc=$%04X path=%s" % [
			source_frame, expected_pc, output_path])
		return {"matched": true, "saved": true}
	var task: Dictionary = route_status.get("fresh_source_route_task", {})
	var worker_input: Dictionary = task.get("slot05_worker_input", {})
	var worker_result: Dictionary = task.get("slot05_worker_result", {})
	var source_dispatch: Dictionary = worker_input.get("source_dispatch", {})
	var input_registers: Dictionary = worker_input.get("registers", {})
	var input_ram: PackedByteArray = worker_input.get("ram_image", PackedByteArray())
	var registers: Dictionary = worker_result.get("registers", {})
	var mapper: Dictionary = worker_result.get("mapper", {})
	var ram: PackedByteArray = worker_result.get("ram_image", PackedByteArray())
	var stack_page: PackedByteArray = worker_result.get("stack_page", PackedByteArray())
	var blocked_read: Dictionary = worker_result.get("blocked_read", {})
	var pc := int(input_registers.get("pc", -1))
	if pc != expected_pc or pc != 0xE14A:
		return {}
	if ram.size() != 0x800 or stack_page.size() != 0x100 \
			or ram.slice(0x0100, 0x0200) != stack_page:
		return {"matched": true, "saved": false, "error": "invalid RAM/stack image"}
	if input_ram.size() != 0x800 or (expected_timer >= 0 and int(input_ram[0x0614]) != expected_timer):
		return {}
	if String(worker_result.get("exit_kind", "")) != "unresolved_source_span" \
			or int(worker_result.get("exit_pc", -1)) != expected_result_pc \
			or int(blocked_read.get("requested_address", -1)) != expected_result_pc \
			or int(blocked_read.get("bank", -1)) != 0x1E:
		return {}
	if String(source_dispatch.get("rom_sha256", "")) != TITLE_HANDOFF_ROM_SHA256 \
			or int(source_dispatch.get("slot_base", -1)) != 0x05 \
			or String(source_dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(source_dispatch.get("pc", -1)) != 0xE14A \
			or int(source_dispatch.get("bank", -1)) != 0x1F \
			or not bool(source_dispatch.get("source_dispatch_observed", false)):
		return {"matched": true, "saved": false, "error": "source dispatch proof mismatch"}
	var input_bytes := FileAccess.get_file_as_bytes(INPUT_CSV)
	var checkpoint := {
		"schema_version": 1,
		"origin": "ordinary_input_godot_source_route",
		"rom_sha256": TITLE_HANDOFF_ROM_SHA256,
		"input_trace_sha256": _sha256(input_bytes),
		"source_frame": source_frame,
		"route_stage": String(route_status.get("stage", "")),
		"source_boundary": {
			"exit_kind": String(worker_result.get("exit_kind", "")),
			"pc": int(worker_result.get("exit_pc", -1)),
			"bank": int(worker_result.get("exit_bank", -1)),
			"blocked_read": worker_result.get("blocked_read", {}),
			"calls": worker_result.get("calls", []),
			"instructions": worker_result.get("instructions", []),
			"executed_source_spans": worker_result.get("executed_source_spans", []),
		},
		"source_dispatch": source_dispatch,
		"registers": registers,
		"mapper": mapper,
		"ram_hex": ram.hex_encode(),
		"ram_sha256": _sha256(ram),
		"stack_page_hex": stack_page.hex_encode(),
		"stack_page_sha256": _sha256(stack_page),
	}
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		return {"matched": true, "saved": false, "error": "could not open %s" % output_path}
	output.store_string(JSON.stringify(checkpoint))
	output.close()
	print("Godot source-route checkpoint saved: frame=%d pc=$%04X timer=$%02X path=%s" % [
		source_frame, pc, int(ram[0x0614]), output_path,
	])
	return {"matched": true, "saved": true}


func _read_fceux_script_pointer(source_frame: int) -> int:
	var path := "%s/route_frame_%06d.bin" % [FCEUX_RAM_TRACE_DIR, source_frame]
	var ram := FileAccess.get_file_as_bytes(path)
	if ram.size() != 0x800:
		return -1
	return int(ram[0x004D]) | (int(ram[0x004E]) << 8)


func _print_cutscene_pointer_timing_audit() -> void:
	print("Cutscene script-pointer comparison (reference only; Godot runtime receives no FCEUX RAM):")
	print("  Godot dispatched background `$F9 $5E` at frame %d; FCEUX remains on `$A385` through 7111, enters `$A386` at 7112, and reaches `$A38B` at 7119." % _godot_background_5e_event_frame)
	var wait_event_indices: Array = _godot_input_wait_frames.keys()
	wait_event_indices.sort()
	var wait_summaries: Array[String] = []
	for event_index_variant in wait_event_indices:
		var wait_event: Dictionary = _godot_input_wait_frames[int(event_index_variant)]
		wait_summaries.append("%d:$%04X@%d" % [int(event_index_variant), int(wait_event["pc"]), int(wait_event["frame"])])
	print("  Godot fresh-A waits (event:PC@frame): %s" % ", ".join(wait_summaries))
	var initial_event_summaries: Array[String] = []
	var initial_event_indices: Array = _godot_initial_cutscene_event_frames.keys()
	initial_event_indices.sort()
	for event_index_variant in initial_event_indices:
		var initial_event: Dictionary = _godot_initial_cutscene_event_frames[int(event_index_variant)]
		initial_event_summaries.append("%d:$%04X@%d:%s" % [int(event_index_variant), int(initial_event["pc"]), int(initial_event["frame"]), str(initial_event["kind"])])
	print("  Godot first cutscene events (index:PC@frame:kind): %s" % ", ".join(initial_event_summaries))
	for source_frame in CUTSCENE_POINTER_AUDIT_FRAMES:
		var checkpoint: Dictionary = _stage_at_checkpoints.get(source_frame, {})
		var rom_pointer := int(checkpoint.get("fceux_script_pointer", -1))
		var godot_pointer := int(checkpoint.get("vm_source_pc", -1))
		print("  frame %d: FCEUX=$%04X Godot=$%04X delta=%+d" % [
			source_frame, rom_pointer, godot_pointer, godot_pointer - rom_pointer])


func _verify_frame7266_nmi_ram_reference() -> void:
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(NMI_TRACE_VALIDATION))
	var rom: Variant = metadata.get("rom_sha256", "") if metadata is Dictionary else ""
	var replay_count := int(metadata.get("replays", 0)) if metadata is Dictionary else 0
	_check(rom == TITLE_HANDOFF_ROM_SHA256 and replay_count == 2,
		"frame-7266 RAM reference metadata pins this ROM and two muted replays")
	var pass1 := FileAccess.get_file_as_bytes(NMI_RAM_PASS1)
	var pass2 := FileAccess.get_file_as_bytes(NMI_RAM_PASS2)
	if pass1.size() == 0x800 and pass2.size() == 0x800 and pass1 == pass2:
		_frame_7266_c421_ram_reference = pass1.duplicate()
	_check(pass1.size() == 0x800 and pass2.size() == 0x800
		and _sha256(pass1) == NMI_RAM_SHA256 and _sha256(pass2) == NMI_RAM_SHA256
		and pass1 == pass2 and int(pass1[0x0024]) == 0x00,
		"ROM-derived `$0024=$00` agrees with identical same-input `$C421` RAM snapshots; snapshots are validation only")
	_check(pass1.size() == 0x800
		and int(pass1[0x001B]) == 0xC0
		and int(pass1[0x001C]) == 0x00 and int(pass1[0x001D]) == 0x00
		and int(pass1[0x0020]) == 0x88 and int(pass1[0x0021]) == 0x1E
		and int(pass1[0x0022]) == 0x00 and int(pass1[0x0023]) == 0x07
		and int(pass1[0x0024]) == 0x00 and int(pass1[0x0025]) == 0x02
		and int(pass1[0x003B]) == 0x55
		and int(pass1[0x0079]) == 0x40 and int(pass1[0x0628]) == 0x00,
		"two-pass `$C421` snapshot pins event-time latch, PPU shadows, mapper shadows, OAM guard, preset, and empty packet queue")


func _print_nmi_read_set_checkpoint(ram_values: Dictionary) -> void:
	var addresses: Array[int] = [0x001B, 0x001C, 0x001D, 0x0020, 0x0021,
		0x0022, 0x0023, 0x0024, 0x0025, 0x003B, 0x0044, 0x0045, 0x0079,
		0x007A, 0x007B, 0x008E, 0x008F, 0x009E, 0x009F, 0x00A0, 0x00A1,
		0x00E1, 0x00E2, 0x00E3, 0x0628]
	var known: Array[String] = []
	var unknown: Array[String] = []
	for address in addresses:
		if ram_values.has(address):
			known.append("$%04X=$%02X" % [address, int(ram_values[address])])
		else:
			unknown.append("$%04X" % address)
	print("ROM-source `$A15B` checkpoint selected NMI context subset: %d/%d known; values=%s; unknown=%s" % [
		known.size(), addresses.size(), ",".join(known), ",".join(unknown)])
	var sound_driver_branch_inputs: Array[int] = [0x0700, 0x0701, 0x0702, 0x0703,
		0x0704, 0x0705, 0x0706, 0x07E9]
	var sound_known: Array[String] = []
	var sound_unknown: Array[String] = []
	for address in sound_driver_branch_inputs:
		if ram_values.has(address):
			sound_known.append("$%04X=$%02X" % [address, int(ram_values[address])])
		else:
			sound_unknown.append("$%04X" % address)
	print("Additional bank-$0C sound-driver branch inputs at `$A15B`: %d/%d known; values=%s; unknown=%s" % [
		sound_known.size(), sound_driver_branch_inputs.size(),
		",".join(sound_known), ",".join(sound_unknown)])
	if ram_values.has(0x003A):
		print("ROM-source `$A15B` sound-frame counter input: $003A=$%02X (full context still required)" % int(ram_values[0x003A]))
	else:
		print("ROM-source `$A15B` sound-frame counter input: $003A provenance unknown")


func _print_selector_nmi_input_audit(handoff: Dictionary) -> void:
	var caller: Dictionary = handoff.get("post_helper_caller_result", {})
	var selector: Dictionary = caller.get("match_selector_result", {})
	var nmi_execution: Dictionary = caller.get("selector_frame8_nmi_execution", {})
	var nmi_ram: PackedByteArray = nmi_execution.get("ram_after", PackedByteArray())
	var nmi_cpu: Dictionary = nmi_execution.get("cpu_after_nmi_rti", {})
	if not nmi_ram.is_empty():
		print("Frame-8 source NMI: dispatched=%s status=%s return=$%04X P=$%02X SP=$%02X cycles-from-$8061=%d; RAM $1B/$1C/$1D/$20/$21/$3B/$E1-$E3=%s; PPU events=%d APU writes=%d" % [
			str(bool(nmi_execution.get("candidate_nmi_dispatched", false))),
			String(nmi_execution.get("status", "")), int(nmi_cpu.get("pc", -1)),
			int(nmi_cpu.get("p", -1)), int(nmi_cpu.get("sp", -1)),
			int(nmi_execution.get("cpu_cycles_from_8061", -1)),
			"$%02X/$%02X/$%02X/$%02X/$%02X/$%02X/$%02X,$%02X,$%02X" % [
				nmi_ram[0x001B], nmi_ram[0x001C], nmi_ram[0x001D], nmi_ram[0x0020],
				nmi_ram[0x0021], nmi_ram[0x003B], nmi_ram[0x00E1], nmi_ram[0x00E2],
				nmi_ram[0x00E3]], nmi_execution.get("ppu_bus_events", []).size(),
			nmi_execution.get("apu_writes", []).size()])
	var ram_variant: Variant = selector.get("ram_after", {})
	if not ram_variant is Dictionary:
		print("Selector NMI-input audit: no selector RAM result is available at the `$893B` stop.")
		return
	var ram: Dictionary = ram_variant
	var addresses: Array[int] = [0x001B, 0x001C, 0x001D, 0x0020, 0x0021,
		0x0022, 0x0023, 0x0024, 0x0025, 0x003B, 0x0044, 0x0045, 0x0079,
		0x007A, 0x007B, 0x008E, 0x008F, 0x009E, 0x009F, 0x00A0, 0x00A1,
		0x00E1, 0x00E2, 0x00E3, 0x0628]
	var fields: Array[String] = []
	for address in addresses:
		var actual: Variant = ram.get(address, "unknown")
		var actual_text := "unknown" if not actual is int else "$%02X" % int(actual)
		var expected_text := "unavailable"
		if _frame_7266_c421_ram_reference.size() == 0x800:
			expected_text = "$%02X" % int(_frame_7266_c421_ram_reference[address])
		fields.append("$%04X=%s/ref:%s" % [address, actual_text, expected_text])
	print("Selector return RAM vs ROM-only `$C421` reference (comparison only; not event-time proof): %s" % ", ".join(fields))


func _map2d_batch_source_matches(batch: Dictionary) -> bool:
	if FileAccess.get_sha256(MAP2D_MANIFEST_PATH) != MAP2D_MANIFEST_SHA256 \
			or FileAccess.get_sha256(MAP2D_BLOCK_MAP_PATH) != MAP2D_BLOCK_MAP_SHA256:
		return false
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP2D_MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return false
	var manifest: Dictionary = manifest_variant
	var map_source: Dictionary = manifest.get("map_source", {})
	var block_map := FileAccess.get_file_as_bytes(MAP2D_BLOCK_MAP_PATH)
	var calls: Array = batch.get("map_calls", [])
	var queue: PackedByteArray = batch.get("queue_bytes", PackedByteArray())
	var batch_start_index := int(batch.get("batch_start_map_index", -1))
	var batch_start_placement := int(batch.get("batch_start_placement", -1))
	var expected_cell_count := mini(3, 0x20 - batch_start_index) if batch_start_index >= 0 else -1
	if String(manifest.get("schema", "")) != "ct2-slot15-callback-34-map-2d-metatiles-v1" \
			or String(manifest.get("source_rom_sha256", "")) != TITLE_HANDOFF_ROM_SHA256 \
			or String(map_source.get("map_id", "")) != "0x2D" \
			or String(map_source.get("resolved_selector", "")) != "0x02" \
			or String(map_source.get("block_map_cpu_address", "")) != "0x9104" \
			or block_map.size() != 0x20 \
			or block_map.slice(0, 3) != PackedByteArray([0x00, 0x71, 0x72]) \
			or batch_start_index < 0 or batch_start_index >= 0x20 \
			or batch_start_index % 3 != 0 \
			or batch_start_placement != 0x80 + batch_start_index \
			or calls.size() != expected_cell_count \
			or int(batch.get("batch_cell_count", -1)) != expected_cell_count \
			or queue.size() != expected_cell_count * 0x20:
		return false
	for call_index in range(expected_cell_count):
		var map_index := batch_start_index + call_index
		var expected_id := int(block_map[map_index])
		var call_variant: Variant = calls[call_index]
		if not call_variant is Dictionary:
			return false
		var call: Dictionary = call_variant
		var id_text := "0x%02X" % expected_id
		var record: Dictionary = {}
		for record_variant in manifest.get("metatiles", []):
			if record_variant is Dictionary \
					and String((record_variant as Dictionary).get("metatile_id", "")) == id_text:
				record = record_variant
				break
		if record.is_empty():
			return false
		var tiles_record: Dictionary = record.get("tiles", {})
		var attribute_record: Dictionary = record.get("attribute", {})
		var tiles_path := MAP2D_METATILE_DIR + String(tiles_record.get("path", ""))
		var attribute_path := MAP2D_METATILE_DIR + String(attribute_record.get("path", ""))
		var tiles := FileAccess.get_file_as_bytes(tiles_path)
		var attribute := FileAccess.get_file_as_bytes(attribute_path)
		var expected_placement := batch_start_placement + call_index
		var expected_ppu_address := 0x2000 | ((expected_placement & 0x38) << 4) \
			| ((expected_placement & 0xC0) << 4) | ((expected_placement & 0x07) << 2)
		if String(tiles_record.get("prg_bank", "")) != "0x13" \
				or String(attribute_record.get("prg_bank", "")) != "0x0B" \
				or tiles.size() != 0x10 or attribute.size() != 1 \
				or FileAccess.get_sha256(tiles_path) != String(tiles_record.get("sha256", "")) \
				or FileAccess.get_sha256(attribute_path) != String(attribute_record.get("sha256", "")) \
				or int(call.get("block_id", -1)) != expected_id \
				or int(call.get("placement", -1)) != expected_placement \
				or int(call.get("ppu_address", -1)) != expected_ppu_address \
				or String(call.get("tile_source_sha256", "")) != String(tiles_record.get("sha256", "")) \
				or String(call.get("attribute_source_sha256", "")) != String(attribute_record.get("sha256", "")):
			return false
		var expected_group := _map36_expected_packet_group(expected_placement, tiles, int(attribute[0]))
		if call.get("expanded_queue_bytes", PackedByteArray()) != expected_group \
				or queue.slice(call_index * 0x20, (call_index + 1) * 0x20) != expected_group:
			return false
	return true


func _record_map2d_batch_at_frame(route_status: Dictionary, source_frame: int) -> void:
	var task: Dictionary = route_status.get("fresh_source_route_task", {})
	var batch: Dictionary = task.get("map_batch_result", {})
	if String(task.get("status", "")) != "slot15_map2D_batch_yielded" \
			or int(batch.get("map_id", -1)) != 0x2D:
		return
	var map_index := int(batch.get("batch_start_map_index", -1))
	for observed_variant in _map2d_observed_batches:
		if int((observed_variant as Dictionary).get("batch", {}).get(
				"batch_start_map_index", -2)) == map_index:
			return
	_map2d_observed_batches.append({"source_frame": source_frame,
		"batch": batch.duplicate(true)})


func _map36_expected_packet_group(placement: int, tiles: PackedByteArray,
		attribute: int) -> PackedByteArray:
	if tiles.size() != 0x10 or attribute < 0 or attribute > 0xFF:
		return PackedByteArray()
	var group := PackedByteArray()
	var base_address := 0x2000 | ((placement & 0x38) << 4) \
		| ((placement & 0xC0) << 4) | ((placement & 0x07) << 2)
	for row in 4:
		var address := base_address + row * 0x20
		group.append(0x04)
		group.append(address & 0xFF)
		group.append((address >> 8) & 0xFF)
		for column in 4:
			group.append(tiles[row * 4 + column])
	var attribute_address := 0x23C0 | (placement & 0x3F) | ((placement & 0xC0) << 4)
	group.append(0x01)
	group.append(attribute_address & 0xFF)
	group.append((attribute_address >> 8) & 0xFF)
	group.append(attribute)
	return group


func _map36_queue_prefixes_match(queue: PackedByteArray,
		prefixes: Array[PackedByteArray]) -> bool:
	if queue.size() != prefixes.size() * 0x20:
		return false
	for call_index in prefixes.size():
		var start := call_index * 0x20
		if queue.slice(start, start + prefixes[call_index].size()) != prefixes[call_index]:
			return false
	return true


func _map36_queue_prefix_hex(queue: PackedByteArray, metatile_count: int) -> Array[String]:
	var prefixes: Array[String] = []
	for call_index in metatile_count:
		var start := call_index * 0x20
		prefixes.append(queue.slice(start, start + 3).hex_encode()
			if queue.size() >= start + 3 else "invalid")
	return prefixes


func _dispatch_edges(route: KickoffRouteRuntime, changes: Array) -> void:
	for change_variant in changes:
		var change: Dictionary = change_variant
		var key_code: Key
		match str(change.get("name", "")):
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
		event.pressed = bool(change.get("pressed", false))
		route.call("_unhandled_input", event)
		var stage := str(route.get_route_status().get("stage", ""))
		if stage == "meeting_menu" and is_instance_valid(route._meeting_menu_input):
			route._meeting_menu_input.call("handle_input_event", event)
		elif stage == "first_action_menu" and is_instance_valid(route._menu_input):
			route._menu_input.call("handle_input_event", event)


func _save_background_image(route: KickoffRouteRuntime, source_frame: int) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	var image: Image = route._visuals.screen.get_rendered_background_image()
	_check(image != null and not image.is_empty(), "Godot renderer exposes the ROM-backed background image at frame %d" % source_frame)
	if image == null or image.is_empty():
		return
	var path := OUTPUT_PNG.get_basename() + "_%04d.png" % source_frame
	var save_error := image.save_png(path)
	_check(save_error == OK, "background diagnostic image saved at frame %d" % source_frame)
	print("Godot background frame %d: %s (%dx%d; CanvasItem sprites excluded)" % [source_frame, path, image.get_width(), image.get_height()])


func _is_first_pass_decision_wait_endpoint(route: KickoffRouteRuntime,
		route_status: Dictionary, source_frame: int) -> bool:
	if source_frame != FIRST_PASS_DECISION_FRAME \
			or int(route_status.get("source_frame", -1)) != FIRST_PASS_DECISION_FRAME \
			or not bool(route_status.get("fresh_source_route_accepts_gameplay_input", false)) \
			or route._fresh_source_route_runner == null:
		return false
	var runner: Variant = route._fresh_source_route_runner
	var runner_status: Dictionary = runner.get_status()
	var source_route_status: Dictionary = route_status.get("fresh_source_route", {})
	var runner_phase := String(runner_status.get("phase", ""))
	# `first_action_menu_ready` is the runner's current name for its live
	# `$D5EA` poll; accept the explicit semantic label if the runner adopts it.
	if runner_phase not in ["first_action_menu_ready", "waiting_for_input"] \
			or String(source_route_status.get("phase", "")) != runner_phase \
			or int(runner_status.get("pending_selected_task_slot", -1)) != 0x05 \
			or int(runner_status.get("pending_selected_task_boundary_pc", -1)) != 0xD5EA:
		return false
	var scheduler: Variant = runner._scheduler
	if scheduler == null or not scheduler.has_method("get_task_boundary_snapshot"):
		return false
	var boundary: Dictionary = scheduler.get_task_boundary_snapshot(0x05)
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	return int(boundary.get("pc", -1)) == 0xD5EA \
		and int(boundary.get("active_task_slot", -1)) == 0x05 \
		and ram is PackedByteArray and (ram as PackedByteArray).size() == 0x800 \
		and int((ram as PackedByteArray)[0x0441]) == 0x0A \
		and int((ram as PackedByteArray)[0x0430]) == 0x01 \
		and int((ram as PackedByteArray)[0x0431]) == 0x0A \
		and int((ram as PackedByteArray)[0x0624]) == 0x78 \
		and int((ram as PackedByteArray)[0x062D]) == 0x00 \
		and int((ram as PackedByteArray)[0x001C]) == 0x00 \
		and int((ram as PackedByteArray)[0x001E]) == 0x00 \
		and int((ram as PackedByteArray)[0x05FC]) == 0x0A \
		and int((ram as PackedByteArray)[0x05FE]) == 0x78 \
		and int((ram as PackedByteArray)[0x0638]) == 0x78


func _summarize_pass_receiver_poll(task_variant: Variant) -> Dictionary:
	if not task_variant is Dictionary:
		return {}
	var task_result: Dictionary = task_variant
	var source_result_variant: Variant = task_result.get("last_pass_receiver_input_result",
		task_result.get("source_input_result", task_result.get("source_result", {})))
	var adoption_variant: Variant = task_result.get("last_pass_receiver_input_adoption",
		task_result.get("source_input_adoption", task_result.get("scheduler_adoption", {})))
	var receipt_variant: Variant = task_result.get("input_sample_receipt", {})
	if source_result_variant is Dictionary:
		var source_result: Dictionary = source_result_variant
		receipt_variant = source_result.get("input_sample_receipt", receipt_variant)
		if adoption_variant is Dictionary and adoption_variant.is_empty():
			adoption_variant = source_result.get("scheduler_adoption", adoption_variant)
	var source_result: Dictionary = source_result_variant if source_result_variant is Dictionary else {}
	var adoption: Dictionary = adoption_variant if adoption_variant is Dictionary else {}
	var receipt: Dictionary = receipt_variant if receipt_variant is Dictionary else {}
	return {
		"route_phase": String(task_result.get("phase", "")),
		"source_status": String(source_result.get("status", "")),
		"entry_pc": int(source_result.get("entry_pc", -1)),
		"exit_pc": int(source_result.get("exit_pc", -1)),
		"adoption_ok": bool(adoption.get("ok", false)),
		"adoption_receipt_id": int(adoption.get("sample_receipt_id", -1)),
		"adoption_source_frame_label": int(adoption.get("source_frame_label", -1)),
		"adoption_exit_pc": int(adoption.get("source_exit_pc", -1)),
		"sample_receipt_id": int(receipt.get("sample_receipt_id", -1)),
		"source_frame_label": int(receipt.get("source_frame_label", -1)),
		"held_ram_001c": int(receipt.get("held_ram_001c", -1)),
		"edge_ram_001e": int(receipt.get("edge_ram_001e", -1)),
		"previous": int(receipt.get("previous", -1)),
		"current": int(receipt.get("current", -1)),
		"source_input_consumed": String(source_result.get("status", "")) in [
			"receiver_down_scan_stopped_at_renderer_call",
			"receiver_confirmed_at_d70c_before_holder_transfer"],
	}


func _pass_receiver_poll_matches(poll: Dictionary, expected_frame: int,
		expected_mask: int, expected_source_status: String, expected_exit_pc: int) -> bool:
	var receipt_id := int(poll.get("sample_receipt_id", -1))
	return receipt_id > 0 \
		and int(poll.get("adoption_receipt_id", -1)) == receipt_id \
		and int(poll.get("source_frame_label", -1)) == expected_frame \
		and int(poll.get("adoption_source_frame_label", -1)) >= expected_frame \
		and int(poll.get("held_ram_001c", -1)) == expected_mask \
		and int(poll.get("edge_ram_001e", -1)) == expected_mask \
		and int(poll.get("current", -1)) == expected_mask \
		and (int(poll.get("previous", -1)) & expected_mask) == 0 \
		and String(poll.get("source_status", "")) == expected_source_status \
		and int(poll.get("entry_pc", -1)) == 0xD80F \
		and int(poll.get("exit_pc", -1)) == expected_exit_pc \
		and int(poll.get("adoption_exit_pc", -1)) == expected_exit_pc \
		and bool(poll.get("adoption_ok", false)) \
		and bool(poll.get("source_input_consumed", true))


func _save_full_route_viewport(route: KickoffRouteRuntime, source_frame: int,
		output_path: String = ENDPOINT_VIEWPORT_PNG) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("LIMIT: headless renderer exposes the ROM-backed background image but cannot read a composited viewport texture.")
		return
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		print("LIMIT: headless renderer exposes the ROM-backed background image but no composited viewport texture.")
		return
	var image := viewport_texture.get_image()
	_check(image != null and not image.is_empty(),
		"Godot exposes the full endpoint viewport at frame %d" % source_frame)
	if image == null or image.is_empty():
		return
	var save_error := image.save_png(output_path)
	_check(save_error == OK, "full endpoint viewport saved at frame %d" % source_frame)
	print("Godot full viewport frame %d: %s (%dx%d)" % [source_frame,
		output_path, image.get_width(), image.get_height()])


func _verify_live_first_action_menu_navigation(route: KickoffRouteRuntime) -> void:
	if not is_instance_valid(route._menu_input):
		_check(false, "live route installs first-action input before navigation")
		return
	var key_cases: Array[Dictionary] = [
		{"key": KEY_RIGHT, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.SHOOT},
		{"key": KEY_LEFT, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.PASS},
		{"key": KEY_DOWN, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.ONE_TWO_PASS},
		{"key": KEY_UP, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.DRIBBLE},
	]
	for test_case: Dictionary in key_cases:
		var key_event := InputEventKey.new()
		key_event.keycode = int(test_case["key"])
		key_event.pressed = true
		_check(route._menu_input.handle_input_event(key_event), "live route accepts keyboard menu direction")
		route._menu_input.flush_pending_input()
		_check(route._menu_input.selected_action_id == int(test_case["action"]),
			"live route maps keyboard direction to the ROM command")
	var pad_cases: Array[Dictionary] = [
		{"button": JOY_BUTTON_DPAD_RIGHT, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.SHOOT},
		{"button": JOY_BUTTON_DPAD_LEFT, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.PASS},
		{"button": JOY_BUTTON_DPAD_DOWN, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.ONE_TWO_PASS},
		{"button": JOY_BUTTON_DPAD_UP, "action": FIRST_ACTION_MENU_INPUT_SCRIPT.ActionId.DRIBBLE},
	]
	for test_case: Dictionary in pad_cases:
		var pad_event := InputEventJoypadButton.new()
		pad_event.button_index = int(test_case["button"])
		pad_event.pressed = true
		_check(route._menu_input.handle_input_event(pad_event), "live route accepts controller menu direction")
		route._menu_input.flush_pending_input()
		_check(route._menu_input.selected_action_id == int(test_case["action"]),
			"live route maps controller direction to the ROM command")
	_check(String(route.get_route_status().get("stage", "")) == "first_action_menu" \
			and _menu_confirmation_requests.is_empty(),
		"menu navigation stays at the initial command menu and requests no soccer action")
	if _menu_confirmation_requests.is_empty():
		print("PASS: live-route keyboard and controller navigation selects ROM commands without confirming an action.")


func _on_menu_action_confirmation_requested(action_id: int) -> void:
	_menu_confirmation_requests.append(action_id)


func _on_route_audio_started(queue_id: int, source_frame: int) -> void:
	_route_audio_player_events.append({"kind": "start", "queue_id": queue_id,
		"source_frame": source_frame})


func _on_route_audio_stopped(queue_id: int, source_frame: int) -> void:
	_route_audio_player_events.append({"kind": "stop", "queue_id": queue_id,
		"source_frame": source_frame})


func _summarize_audio_queue_events(events: Array) -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for event_variant in events:
		if not event_variant is Dictionary:
			continue
		var event: Dictionary = event_variant
		summary.append({
			"queue_id": int(event.get("queue_id", -1)),
			"route_frame": int(event.get("route_frame", -1)),
			"route_frame_domain": String(event.get("route_frame_domain", "")),
			"source_frame": int(event.get("source_frame", -1)),
			"source_frame_domain": String(event.get("source_frame_domain", "")),
			"source_pc": int(event.get("source_pc", event.get("queue_store_instruction_pc", -1))),
			"source_caller_pc": int(event.get("source_caller_pc", -1)),
			"queue_slot": int(event.get("queue_slot", -1)),
			"event_identity": String(event.get("event_identity", "")),
			"origin": String(event.get("event_origin", event.get("effect", ""))),
			"root_input_052e": int(event.get("root_input_ram_052e", -1)),
			"root_input_052f": int(event.get("root_input_ram_052f", -1)),
			"root_output_052e": int(event.get("root_output_ram_052e", -1)),
			"root_source_0530": int(event.get("root_source_ram_0530", -1)),
			"root_source_0531": int(event.get("root_source_ram_0531", -1)),
			"root_source_063f": int(event.get("root_source_ram_063f", -1)),
			"root_scenario_id": int(event.get("root_scenario_id", -1)),
			"applied": bool(event.get("applied", false)),
			"timing_verified": bool(event.get("timing_verified", false)),
		})
	return summary


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK \
			or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
