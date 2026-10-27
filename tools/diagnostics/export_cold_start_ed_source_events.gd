extends SceneTree
## Run the existing ROM-byte-driven opening presenter and export its executed
## `$ED` sound commands. Captured RAM is read afterward as a comparison oracle
## only; it is never used to schedule or modify source events.
##
## Usage:
##   godot --headless --path . --script tools/diagnostics/export_cold_start_ed_source_events.gd
##   godot --headless --path . --script tools/diagnostics/export_cold_start_ed_source_events.gd -- --output=/tmp/cold_start_ed_source_events.json

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const CAPTURE_RAM_DIR := "res://reference/opening_timing_capture_20261024_131726/ram_states"
const LAST_SOURCE_FRAME := 4661
const CUTSCENE_TASK_SLOT := 5
const EXPECTED_ED_COUNT := 12

var _presenter: ColdStartSourceCommandPresenter
var _source_events: Array[Dictionary] = []
var _sound_signal_events: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run_export")


func _run_export() -> void:
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the isolated source-command presenter scene.")
		return

	_presenter = packed.instantiate() as ColdStartSourceCommandPresenter
	if _presenter == null:
		_fail("The presenter scene did not instantiate its expected script.")
		return
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(_presenter)
	await process_frame
	_presenter.propagate_call("set_process", [false])
	_presenter.set_capture_render_updates_suppressed(true)
	# This export needs command/state execution only. The source-driven nametable
	# renderer is disabled just as in the existing state-dump diagnostic.
	var field_screen := _presenter.get_node("FieldScreen") as RomPpuNametableScreenRenderer
	if field_screen != null:
		field_screen.set_rendering_enabled(false)
	_presenter.source_command_applied.connect(_on_source_command_applied)
	_presenter.rom_sound_requested.connect(_on_rom_sound_requested)

	for _frame in range(LAST_SOURCE_FRAME):
		_presenter._advance_source_frame()

	var capture := _read_captured_ram_schedule()
	if not bool(capture.get("ok", false)):
		_fail(str(capture.get("error", "Could not read the selected RAM capture.")))
		return
	var comparison := _compare_ed_events(capture["events"])
	var output := {
		"diagnostic": true,
		"purpose": "ROM source-command execution export; captured RAM is validation-only",
		"capture_used_to_schedule_source_events": false,
		"presenter_scene": PRESENTER_SCENE_PATH,
		"presenter_rom_sha256": _presenter.state.get("rom_sha256", ""),
		"script_start_cpu": "$A020",
		"script_start_file_offset": "0x006030",
		"script_sha256": "499ccb62b8b2b9118d7ebfaa6e6b9fce46806cd3b9173b5e1d5d61de21c2a6b7",
		"source_frames_advanced": int(_presenter.state.get("source_frame", -1)),
		"source_task_stopped": bool(_presenter.state.get("stopped_before_unmodeled_command", false)),
		"source_slice_error": str(_presenter.state.get("slice_error", "")),
		"source_ed_event_count": _source_events.size(),
		"rom_sound_requested_signal_count": _sound_signal_events.size(),
		"source_events": _source_events,
		"sound_signal_events": _sound_signal_events,
		"capture": capture,
		"comparison": comparison,
		"limitations": [
			"This is the existing partial presenter, not a full 6502/NMI execution.",
			"Initial scheduler release, EC stream timing, selected helper stalls and loop phase retain documented capture anchors.",
			"Captured RAM rows validate the result only and are excluded from source scheduling.",
		],
	}
	var output_path := _output_path()
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		_fail("Could not open diagnostic output: %s" % output_path)
		return
	file.store_string(JSON.stringify(output, "\t") + "\n")
	file.close()
	print("COLD_START_ED_EXPORT_OK output=%s source_ed=%d signal=%d capture_ram=%d exact=%s" % [
		output_path,
		_source_events.size(),
		_sound_signal_events.size(),
		int(capture["snapshot_count"]),
		str(comparison.get("all_ed_events_match", false)),
	])
	quit(0 if _source_events.size() == EXPECTED_ED_COUNT and bool(comparison.get("all_ed_events_match", false)) else 2)


func _on_rom_sound_requested(sound_id: int, source_frame: int) -> void:
	_sound_signal_events.append({"source_frame": source_frame, "sound_id": sound_id})


func _on_source_command_applied(event: Dictionary, state_snapshot: Dictionary) -> void:
	if str(event.get("byte", "")) != "$ED":
		return
	var scheduler := _presenter.get("_scheduler") as RomCooperativeScheduler
	var signal_index := _source_events.size()
	var sound_signal: Dictionary = _sound_signal_events[signal_index] if signal_index < _sound_signal_events.size() else {}
	var previous_yield: Dictionary = state_snapshot.get("last_scheduler_yield", {})
	_source_events.append({
		"ordinal": signal_index + 1,
		"source_frame": int(event.get("source_frame", -1)),
		"script_cpu": str(event.get("script_cpu", "")),
		"rom_file_offset": str(event.get("rom_file_offset", "")),
		"raw_bytes": str(event.get("rom_consumed_bytes", "")),
		"raw_byte_labels": event.get("consumed_bytes_array", []),
		"sound_id": int(event.get("operand_bytes_array", ["$00"])[0].trim_prefix("$").hex_to_int()),
		"handler_entry_pc": str(event.get("handler_entry_pc", "")),
		"dispatch_sequence": int(event.get("seq", -1)),
		"sound_signal_pair": {
			"matched": int(sound_signal.get("source_frame", -2)) == int(event.get("source_frame", -1))
				and int(sound_signal.get("sound_id", -2)) == int(event.get("operand_bytes_array", ["$00"])[0].trim_prefix("$").hex_to_int()),
			"event": sound_signal,
		},
		"scheduler_context": {
			"scheduler_tick_live": scheduler.scheduler_tick if scheduler != null else -1,
			"state_scheduler_tick_before_frame_return": int(state_snapshot.get("scheduler_tick", -1)),
			"current_task_slot_offset": scheduler.current_task_slot_offset if scheduler != null else -1,
			"cutscene_task_delay_byte": scheduler.get_task_delay(CUTSCENE_TASK_SLOT) if scheduler != null else -1,
			"nmi_ready_latched": scheduler.nmi_ready_latched if scheduler != null else false,
			"previous_yield": previous_yield.duplicate(true),
			"script_loop_count": int(state_snapshot.get("script_loop_count", 0)),
			"script_phase_frame": int(event.get("source_frame", -1)) - int(state_snapshot.get("script_loop_count", 0)) * 4199,
			"dispatch_not_before_frame": int(state_snapshot.get("script_dispatch_not_before_frame", -1)),
		},
	})


func _read_captured_ram_schedule() -> Dictionary:
	var events: Array[Dictionary] = []
	var previous_value := 0
	var snapshot_count := 0
	for frame in range(LAST_SOURCE_FRAME + 1):
		var path := "%s/ram_%05d.bin" % [CAPTURE_RAM_DIR, frame]
		if not FileAccess.file_exists(path):
			return {"ok": false, "error": "Missing captured RAM frame %d at %s" % [frame, path]}
		var ram := FileAccess.get_file_as_bytes(path)
		if ram.size() != 0x800:
			return {"ok": false, "error": "Captured RAM frame %d has size %d, expected 2048." % [frame, ram.size()]}
		snapshot_count += 1
		var value := int(ram[0x0700])
		if value != 0 and value != previous_value:
			events.append({"source_frame": frame, "sound_id": value, "ram_queue_bytes_0700_0704": ram.slice(0x0700, 0x0705).hex_encode().to_upper()})
		previous_value = value
	return {
		"ok": true,
		"directory": CAPTURE_RAM_DIR,
		"frames_included": [0, LAST_SOURCE_FRAME],
		"snapshot_count": snapshot_count,
		"queue_address": "$0700",
		"event_detection": "nonzero value at $0700 that differs from the immediately preceding frame",
		"events": events,
	}


func _compare_ed_events(captured_events: Array[Dictionary]) -> Dictionary:
	var ed_capture_events: Array[Dictionary] = []
	var excluded: Array[Dictionary] = []
	for item in captured_events:
		# The same-input trace identifies this as the title-handoff Stop ($8048),
		# a sound-queue write that is not emitted by the cutscene script's $ED.
		if int(item.get("source_frame", -1)) == 4661 and int(item.get("sound_id", -1)) == 0x01:
			excluded.append({
				"event": item,
				"reason": "bank-0 $8048 title handoff Stop write, not a script $ED command",
			})
			continue
		ed_capture_events.append(item)
	var rows: Array[Dictionary] = []
	var all_match := _source_events.size() == ed_capture_events.size()
	var row_count: int = maxi(_source_events.size(), ed_capture_events.size())
	for index in range(row_count):
		var source: Dictionary = _source_events[index] if index < _source_events.size() else {}
		var captured: Dictionary = ed_capture_events[index] if index < ed_capture_events.size() else {}
		var frame_match := not source.is_empty() and not captured.is_empty() \
			and int(source.get("source_frame", -1)) == int(captured.get("source_frame", -2))
		var id_match := not source.is_empty() and not captured.is_empty() \
			and int(source.get("sound_id", -1)) == int(captured.get("sound_id", -2))
		var row_match := frame_match and id_match
		all_match = all_match and row_match
		rows.append({
			"ordinal": index + 1,
			"source_event": source,
			"captured_ram_event": captured,
			"frame_match": frame_match,
			"sound_id_match": id_match,
			"exact_pair_match": row_match,
		})
	return {
		"source_ed_count": _source_events.size(),
		"captured_ram_ed_candidate_count": ed_capture_events.size(),
		"excluded_non_ed_queue_events": excluded,
		"all_ed_events_match": all_match,
		"rows": rows,
	}


func _output_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			return argument.trim_prefix("--output=")
	return "/tmp/cold_start_ed_source_events.json"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
