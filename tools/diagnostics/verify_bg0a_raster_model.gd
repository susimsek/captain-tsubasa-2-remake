extends SceneTree

const MODEL := preload("res://scripts/opening/rom_bg0a_raster_model.gd")


func _initialize() -> void:
	var model = MODEL.new()
	if not model.configure_from_e8(0x01, 814):
		push_error(model.last_error)
		quit(1)
		return
	var preset: Dictionary = model.preset_state()
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
				or int(events[0].get("scroll_x", -1)) != int(ram[0x7A]) \
				or int(events[0].get("control_nametable_bit", -1)) != 1 \
				or int(events[0].get("ppuctrl_nametable_bit_observed", -1)) != 1 \
				or int(state.get("initial_nametable_x", -1)) != 1 \
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
