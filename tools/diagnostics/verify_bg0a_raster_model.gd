extends SceneTree

const MODEL := preload("res://scripts/opening/rom_bg0a_raster_model.gd")
const BUS_TRACE_PATH := "res://reference/opening_timing_capture_20261024_131726/bus_events.csv"

var _camera_ppuctrl_by_frame: Dictionary = {}


func _initialize() -> void:
	var model = MODEL.new()
	if not model.configure_from_e8(0x01, 814):
		push_error(model.last_error)
		quit(1)
		return
	var preset: Dictionary = model.preset_state()
	var reset_model = load("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd").new()
	if not reset_model.configure_from_project_sources():
		push_error(reset_model.error_message)
		quit(1)
		return
	var reset_addresses: Array[int] = [0x0078]
	var reset_receipt: Dictionary = reset_model.build_reset_ram_zero_write_receipt(
		"kickoff_reset_ram_clear_0078", reset_addresses)
	var ram_image = load("res://scripts/gameplay/rom_source_ram_image.gd").new()
	if not bool(reset_receipt.get("ok", false)) \
			or not ram_image.merge_executor_result("kickoff_reset_ram_clear_0078", reset_receipt):
		push_error(String(reset_receipt.get("error", ram_image.error_message)))
		quit(1)
		return
	var preset_receipt: Dictionary = model.e8_source_ram_write_receipt(
		"kickoff_cutscene_01_event_000_e8_01", ram_image.get_byte(0x0078))
	var preset_writes: Array = preset_receipt.get("ram_writes", [])
	if not bool(preset_receipt.get("ok", false)) or preset_writes.size() != 20 \
			or int(preset_writes[0].get("source_pc", -1)) != 0x8943 \
			or int(preset_writes[0].get("address", -1)) != 0x0079 \
			or int(preset_writes[0].get("value", -1)) != 0x40 \
			or int(preset_writes[1].get("address", -1)) != 0x007A \
			or int(preset_writes[2].get("address", -1)) != 0x007C \
			or int(preset_writes.back().get("address", -1)) != 0x008D:
		push_error("E8 `$01` ROM preset write receipt differs from the audited `$8943/$8948/$8950` mapping.")
		quit(1)
		return
	var irq_cleared_wait_receipt: Dictionary = model.e8_source_ram_write_receipt(
		"kickoff_cutscene_44_after_irq_release_e8_01",
		{"known": true, "value": 0,
			"last_write": {"event_id": "rom_irq_terminal_clear_0078",
				"source_pc": 0xA1C3, "value": 0}})
	if not bool(irq_cleared_wait_receipt.get("ok", false)) \
			or int(irq_cleared_wait_receipt.get("wait_latch_precondition", {}).get("source_pc", -1)) != 0xA1C3:
		push_error("E8 `$01` rejected the live ROM-owned `$78=0` released by the IRQ path.")
		quit(1)
		return
	var unknown_wait_receipt: Dictionary = model.e8_source_ram_write_receipt(
		"unknown_wait_source_e8_01", {"known": true, "value": 0, "last_write": {}})
	if bool(unknown_wait_receipt.get("ok", false)):
		push_error("E8 `$01` accepted a zero wait latch without source-write provenance.")
		quit(1)
		return
	for frame in [814, 819]:
		var ram := _capture_ram(frame)
		if ram.is_empty() \
				or int(preset.get("ram_0079", -1)) != int(ram[0x79]) \
				or int(preset.get("ram_007c", -1)) != int(ram[0x7C]) \
				or int(preset.get("ram_007d", -1)) != int(ram[0x7D]) \
				or int(preset.get("ram_007e", -1)) != int(ram[0x7E]) \
				or int(ram[0x7A]) != 0:
			push_error("BG0A E8 preset state differs from FCEUX validation RAM at frame %d." % frame)
			quit(1)
			return
	var camera_model = MODEL.new()
	if not camera_model.configure_from_e8(0x01, 814) \
			or not camera_model.configure_camera_from_f9(0x0A, 2340) \
			or not camera_model.activate_camera_after_background_load(2367):
		push_error(camera_model.last_error)
		quit(1)
		return
	for frame in [2367, 2369, 2370, 2570, 2580, 2680, 2682]:
		var state: Dictionary = camera_model.frame_state(frame)
		var ram := _capture_ram(frame)
		var ppu_ram := _capture_ram(frame - 1)
		var captured_ppuctrl := _capture_camera_ppuctrl(frame)
		var captured_nametable_bit := captured_ppuctrl & 0x01
		var camera: Dictionary = state.get("camera_state", {})
		var events: Array = state.get("ppu_events", [])
		var initial_selectors: Array = state.get("initial_2k_chr_selectors", [])
		var chr_writes: Array = state.get("chr_writes", [])
		var camera_registers_match := not ram.is_empty() \
				and bool(state.get("active", false)) \
				and int(camera.get("ram_007a", -1)) == int(ram[0x7A]) \
				and int(camera.get("ram_007b", -1)) == int(ram[0x7B])
		if frame >= 2369:
			camera_registers_match = camera_registers_match \
					and int(camera.get("ram_0069_fraction", -1)) == int(ram[0x69]) \
					and int(camera.get("ram_006a_chunk_pixels", -1)) == int(ram[0x6A]) \
					and int(camera.get("ram_0072_chunks_remaining", -1)) == int(ram[0x72])
		if not camera_registers_match or events.size() != 3 \
				or str(events[0].get("kind", "")) != "scroll" \
				or int(events[0].get("scanline", -1)) != 0 \
				or ppu_ram.is_empty() \
				or int(events[0].get("scroll_x", -1)) != int(ppu_ram[0x7A]) \
				or captured_ppuctrl < 0 \
				or int(events[0].get("control_value", -1)) != captured_ppuctrl \
				or int(events[0].get("control_nametable_bit", -1)) != captured_nametable_bit \
				or int(events[0].get("ppuctrl_nametable_bit_observed", -1)) != captured_nametable_bit \
				or int(state.get("initial_ppuctrl", -1)) != captured_ppuctrl \
				or int(state.get("initial_nametable_x", -1)) != captured_nametable_bit \
				or bool(state.get("initial_nametable_x_mapping_verified", true)) \
				or int(state.get("initial_scroll_y", -1)) != 0xFF \
				or int(state.get("renderer_initial_scroll_y_candidate", -1)) != 0xFF \
				or bool(state.get("initial_vertical_scroll_mapping_verified", true)) \
				or str(events[1].get("kind", "")) != "ppu_address" \
				or int(events[1].get("scanline", -1)) != 129 \
				or int(events[1].get("address", -1)) != 0x2200 \
				or int(events[2].get("scanline", -1)) != 130 \
				or initial_selectors.size() != 2 \
				or int(initial_selectors[0]) != 0x3C \
				or int(initial_selectors[1]) != 0x4C \
				or chr_writes.size() != 2 \
				or int(chr_writes[0].get("value", -1)) != 0 \
				or int(chr_writes[1].get("value", -1)) != 2 \
				or int(chr_writes[0].get("scanline", -1)) != 130 \
				or int(chr_writes[1].get("scanline", -1)) != 130:
			push_error("BG0A ROM camera/raster model differs from FCEUX validation at frame %d." % frame)
			quit(1)
			return
		print(JSON.stringify({
			"source_frame": frame,
			"camera": camera,
			"events": events,
			"first_affected_pixel_phase_verified": state["first_affected_pixel_phase_verified"],
		}))
	quit(0)


func _capture_ram(source_frame: int) -> PackedByteArray:
	var path := "res://reference/opening_timing_capture_20261024_131726/ram_states/ram_%05d.bin" % source_frame
	return FileAccess.get_file_as_bytes(path)


func _capture_camera_ppuctrl(source_frame: int) -> int:
	if _camera_ppuctrl_by_frame.is_empty():
		var trace := FileAccess.open(BUS_TRACE_PATH, FileAccess.READ)
		if trace == null:
			return -1
		trace.get_line()
		while not trace.eof_reached():
			var columns := trace.get_line().split(",")
			if columns.size() < 9 or columns[5] != "PPUCTRL_write" or columns[8] != "$A086":
				continue
			var value_text: String = columns[7]
			if value_text.begins_with("$"):
				_camera_ppuctrl_by_frame[int(columns[0])] = value_text.trim_prefix("$").hex_to_int()
		trace.close()
	return int(_camera_ppuctrl_by_frame.get(source_frame, -1))
