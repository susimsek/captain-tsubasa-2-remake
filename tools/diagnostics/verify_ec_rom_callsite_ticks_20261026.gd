extends SceneTree
## Check that ROM-driven EC consumers advance only on the `$89FF` text-delay
## callsite, against the synchronized per-frame RAM snapshots. This is
## validation only; the snapshots are never loaded by the runtime presenter.
## Run: godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_ec_rom_callsite_ticks_20261026.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const RAM_STATE_ROOT := "res://reference/opening_timing_capture_20261024_125300/ram_states"
const PPU_STATE_ROOT := "res://reference/opening_timing_capture_20261024_125300/ppu_states"
const RESULT_PATH := "res://reference/diagnostics/opening_runtime_ec_callsite_timing_20261026/ram_ppu_validation.json"
const LAST_FRAME := 4600
const CHECK_RANGES: Array[Vector2i] = [
	Vector2i(342, 814),
	Vector2i(1119, 1529),
	Vector2i(1760, 1842),
	Vector2i(2340, 2689),
	Vector2i(4541, 4600),
]
const EXPECTED_FIRST_RECORDS: Array[Dictionary] = [
	{"selector": 0, "frame": 380},
	{"selector": 5, "frame": 1120},
	{"selector": 2, "frame": 1780},
	{"selector": 4, "frame": 2369},
	{"selector": 0, "frame": 4579},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the default opening scene.")
		return
	var scene := packed.instantiate()
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(scene)
	await process_frame
	scene.propagate_call("set_process", [false])
	var presenter = scene.get_node("SourcePresenter")
	presenter.get_node("FieldScreen").set_rendering_enabled(false)
	presenter.set_render_updates_suppressed(true)

	var compared_frames := 0
	var ram_mismatch_count := 0
	var ppu_bytes_compared := 0
	var ppu_mismatch_count := 0
	var mismatches: Array[Dictionary] = []
	var ppu_mismatches: Array[Dictionary] = []
	var first_records: Array[Dictionary] = []
	var pause_start_tick := -1
	var pause_end_tick := -1
	var pause_tick_changes := 0
	var pause_ram_at_1839: Array[int] = []
	for _step in range(LAST_FRAME):
		presenter._advance_source_frame()
		var frame := int(presenter.state.get("source_frame", -1))
		if _in_check_range(frame):
			var ram_path := "%s/ram_%05d.bin" % [RAM_STATE_ROOT, frame]
			var ram := FileAccess.get_file_as_bytes(ram_path)
			if ram.size() < 0x656:
				_fail("Missing or short captured RAM state at source frame %d." % frame)
				return
			var player = presenter._ec_stream_player
			if player == null:
				_fail("No ROM EC player exists by source frame %d in a verified EC range." % frame)
				return
			var model: Dictionary = player.get_state()
			var model_ram := [
				int(model.get("ram_0652", -1)),
				int(model.get("ram_0653", -1)),
				int(player._stream_base_cpu_pointer) & 0xFF,
				(int(player._stream_base_cpu_pointer) >> 8) & 0xFF,
			]
			var capture_ram := [ram[0x652], ram[0x653], ram[0x654], ram[0x655]]
			compared_frames += 1
			if model_ram != capture_ram:
				ram_mismatch_count += 1
				if mismatches.size() < 20:
					mismatches.append({
						"frame": frame,
						"model": _hex_bytes(model_ram),
						"fceux": _hex_bytes(capture_ram),
						"last_event": model.get("last_event", {}),
					})
			var ppu_path := "%s/ppu_%05d.bin" % [PPU_STATE_ROOT, frame]
			var ppu := FileAccess.get_file_as_bytes(ppu_path)
			if ppu.size() != 0x4000:
				_fail("Missing or short captured PPU state at source frame %d." % frame)
				return
			for base_address in [0x2302, 0x2303, 0x2304]:
				for row in range(4):
					var address: int = int(base_address) + row * 0x20
					var actual_value := int(presenter._background_01_ppu_memory.get(address, -1))
					var expected_value := int(ppu[address])
					ppu_bytes_compared += 1
					if actual_value != expected_value:
						ppu_mismatch_count += 1
						if ppu_mismatches.size() < 20:
							ppu_mismatches.append({
								"frame": frame,
								"address": "$%04X" % address,
								"model": "$%02X" % (actual_value & 0xFF),
								"fceux": "$%02X" % expected_value,
							})

		var ec_event: Dictionary = presenter.state.get("ec_stream_last_event", {})
		if str(ec_event.get("kind", "")) == "record_staged" \
				and int(ec_event.get("source_frame", -1)) == frame:
			var selector := int(presenter.state.get("ec_stream_pointer_table_index", -1))
			var looped := bool(ec_event.get("loop_restarted", false))
			if bool(ec_event.get("first_record_on_this_tick", false)) \
					or (looped and frame > 4200):
				first_records.append({"selector": selector, "frame": frame, "looped": looped})

		if frame == 1799:
			pause_start_tick = int(presenter._ec_stream_player.get_state().get("consumer_tick_count", -1))
			pause_end_tick = pause_start_tick
		elif frame >= 1800 and frame <= 1839:
			var current_tick := int(presenter._ec_stream_player.get_state().get("consumer_tick_count", -1))
			pause_end_tick = current_tick
			if current_tick != pause_start_tick:
				pause_tick_changes += 1
			if frame == 1839:
				pause_ram_at_1839 = [
					presenter._ec_stream_player.ram_0652,
					presenter._ec_stream_player.ram_0653,
				]

	var expected_records := EXPECTED_FIRST_RECORDS
	var first_record_mismatches: Array[Dictionary] = []
	for index in range(max(first_records.size(), expected_records.size())):
		var actual: Dictionary = first_records[index] if index < first_records.size() else {}
		var expected: Dictionary = expected_records[index] if index < expected_records.size() else {}
		if actual.get("selector", -1) != expected.get("selector", -2) \
				or actual.get("frame", -1) != expected.get("frame", -2):
			first_record_mismatches.append({"expected": expected, "actual": actual})

	var passed := ram_mismatch_count == 0 and ppu_mismatch_count == 0 \
		and first_record_mismatches.is_empty() \
		and pause_tick_changes == 0
	var result := {
		"passed": passed,
		"rom_hash": presenter.SOURCE_ROM_SHA256,
		"compared_ram_frames": compared_frames,
		"ram_mismatch_count": ram_mismatch_count,
		"ram_mismatch_examples": mismatches,
		"compared_ec_ppu_bytes": ppu_bytes_compared,
		"ec_ppu_mismatch_count": ppu_mismatch_count,
		"ec_ppu_mismatch_examples": ppu_mismatches,
		"first_records": first_records,
		"first_record_mismatches": first_record_mismatches,
		"ec02_pause_consumer_tick_changes_1800_1839": pause_tick_changes,
		"ec02_pause_tick_count_start_end": [pause_start_tick, pause_end_tick],
		"ec02_pause_ram_at_1839": pause_ram_at_1839,
		"capture_data_used_only_for_validation": true,
	}
	var result_json := JSON.stringify(result, "\t")
	var result_absolute_path := ProjectSettings.globalize_path(RESULT_PATH)
	DirAccess.make_dir_recursive_absolute(result_absolute_path.get_base_dir())
	var result_file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if result_file != null:
		result_file.store_string(result_json + "\n")
		result_file.close()
	print(result_json)
	quit(0 if passed else 1)


func _in_check_range(frame: int) -> bool:
	for source_range in CHECK_RANGES:
		if frame >= source_range.x and frame <= source_range.y:
			return true
	return false


func _hex_bytes(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append("%02X" % int(value))
	return " ".join(parts)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
