extends SceneTree
## Narrow validation of F1/FD ROM mode gating and source-derived FD RAM geometry.

const MAIN_SCENE := "res://scenes/main.tscn"
const RAM_DIR := "res://reference/opening_timing_capture_20261024_125300/ram_states/"
const OUTPUT := "res://reference/diagnostics/f1_fd_rom_state_20261026/ram_state_validation.json"
const PC_BY_FRAME := {
	342: "$A02D", 810: "$A08A", 1025: "$A0BC", 1108: "$A0D2",
	1525: "$A11F", 1756: "$A14B", 1760: "$A14C", 2117: "$A18F",
	2336: "$A1B5", 2340: "$A1B6", 2685: "$A1FA", 2904: "$A22E",
	3469: "$A29A", 4541: "$A02D",
}
var events_by_frame: Dictionary = {}
var rows: Array[Dictionary] = []
var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	var runtime = packed.instantiate()
	get_root().add_child(runtime)
	await process_frame
	runtime.set_process(false)
	var presenter = runtime.get_node("SourcePresenter")
	presenter.set_process(false)
	presenter.get_node("FieldScreen").set_rendering_enabled(false)
	presenter.source_command_applied.connect(_on_dispatch)
	while int(presenter.state.get("source_frame", 0)) < 4692:
		presenter._advance_source_frame()
		_check_post_dispatch_state(presenter, int(presenter.state.get("source_frame", -1)))
	if rows.size() != PC_BY_FRAME.size():
		errors.append("Expected %d dispatches; observed %d." % [PC_BY_FRAME.size(), rows.size()])
	var report := {
		"schema": "ct2-f1-fd-rom-brightness-gate-validation-v1",
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"reference_ram": "reference/opening_timing_capture_20261024_125300/ram_states/",
		"runtime_screenshot_or_capture_asset_used": false,
		"dispatch_count": rows.size(),
		"rows": rows,
		"errors": errors,
		"status": "pass" if errors.is_empty() else "fail",
	}
	var f := FileAccess.open(OUTPUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t") + "\n")
	f.close()
	if errors.is_empty():
		print("F1_FD_ROM_GATE_OK dispatches=%d" % rows.size())
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)


func _on_dispatch(event: Dictionary, snapshot: Dictionary) -> void:
	var opcode := str(event.get("byte", ""))
	if opcode != "$F1" and opcode != "$FD":
		return
	var frame := int(event.get("source_frame", -1))
	if not PC_BY_FRAME.has(frame):
		errors.append("Unexpected %s dispatch at frame %d." % [opcode, frame])
		return
	var pc := str(event.get("script_cpu", ""))
	if pc != str(PC_BY_FRAME[frame]):
		errors.append("Frame %d PC mismatch: expected %s, got %s." % [frame, PC_BY_FRAME[frame], pc])
		return
	var ram := FileAccess.get_file_as_bytes(RAM_DIR + "ram_%05d.bin" % frame)
	if ram.size() < 0x55:
		errors.append("Missing RAM snapshot for frame %d." % frame)
		return
	var counters: Vector2i = snapshot.get("fade_counters", Vector2i.ZERO)
	var a := int(ram[0x4A])
	var b := int(ram[0x4B])
	if (counters.x & 0xFF) != a or (counters.y & 0xFF) != b:
		errors.append("Frame %d gate mismatch: model %02X/%02X, RAM %02X/%02X." % [
			frame, counters.x & 0xFF, counters.y & 0xFF, a, b,
		])
	if not events_by_frame.has(frame):
		events_by_frame[frame] = []
	events_by_frame[frame].append({
		"frame": frame,
		"pc": pc,
		"opcode": opcode,
		"ram_004A_004B": "%02X %02X" % [a, b],
		"model_fade_counters": "%02X %02X" % [counters.x & 0xFF, counters.y & 0xFF],
		"expected_mode": "buffered" if a != 0 or b != 0 else "direct",
	})


func _check_post_dispatch_state(presenter, frame: int) -> void:
	if not events_by_frame.has(frame):
		return
	var ram := FileAccess.get_file_as_bytes(RAM_DIR + "ram_%05d.bin" % frame)
	for value in events_by_frame[frame]:
		var row: Dictionary = value
		var expected_mode := str(row["expected_mode"])
		if str(row["opcode"]) == "$F1":
			var f1: Dictionary = presenter.state.get("f1_01_setup", {})
			var mode := str(f1.get("selected_draw_path", ""))
			if int(f1.get("dispatch_source_frame", -1)) != frame or mode != expected_mode:
				errors.append("F1 frame %d runtime state/mode mismatch." % frame)
			row["runtime_mode"] = mode
		else:
			var fd: Dictionary = presenter.state.get("fd_scene_clear", {})
			var mode := str(fd.get("mode_from_rom_004A_004B_gate", ""))
			var model_low := int(presenter.state.get("ram_004F_value", -1))
			var model_high := int(presenter.state.get("ram_0050_value", -1))
			var model_limit := int(presenter.state.get("ram_0054_value", -1))
			if [model_low, model_high, model_limit] != [int(ram[0x4F]), int(ram[0x50]), int(ram[0x54])]:
				errors.append("FD frame %d derived RAM mismatch: %02X %02X %02X != capture %02X %02X %02X." % [
					frame, model_low & 0xFF, model_high & 0xFF, model_limit & 0xFF,
					int(ram[0x4F]), int(ram[0x50]), int(ram[0x54]),
				])
			var start := (model_high << 8) | (model_low & 0xE0) | model_limit
			var width := (0x1E - model_limit) & 0xFF
			var actual_start := int(fd.get("ppu_fill_start_address", -1))
			var actual_width := int(fd.get("fill_width_bytes", -1))
			if int(fd.get("dispatch_source_frame", -1)) != frame or mode != expected_mode:
				errors.append("FD frame %d runtime state/mode mismatch." % frame)
			if actual_start != start or actual_width != width:
				errors.append("FD frame %d geometry mismatch: %04X/%d != modeled formula %04X/%d." % [
					frame, actual_start, actual_width, start, width,
				])
			row["runtime_mode"] = mode
			row["captured_ram_004F_0050_0054"] = "%02X %02X %02X" % [ram[0x4F], ram[0x50], ram[0x54]]
			row["modeled_ram_004F_0050_0054"] = "%02X %02X %02X" % [model_low, model_high, model_limit]
			row["runtime_geometry"] = "%04X/%d" % [actual_start, actual_width]
			row["geometry_from_modeled_ram"] = "%04X/%d" % [start, width]
		rows.append(row)
