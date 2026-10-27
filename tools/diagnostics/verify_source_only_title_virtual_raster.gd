extends SceneTree
## Derive the title endpoint's first visible pixel time from ROM-derived
## presenter state and the source CPU/PPU scheduler artifacts. This is a
## virtual raster clock check; it does not drive or alter runtime presentation.
## Run: godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_source_only_title_virtual_raster.gd

const TITLE_RENDERER_SCRIPT := preload("res://scripts/title_rom_background_renderer.gd")
const HANDOFF_EVENTS_PATH := "res://assets/opening/rom_logic/title_handoff_source_events.json"
const FRAME_CYCLES_PATH := "res://reference/diagnostics/start_poll_rom_source_timing_20261027/irq_mask_corrected_title_source_trace/source_frame_cycles.csv"
const CPU_TRACE_PATH := "res://reference/diagnostics/start_poll_rom_source_timing_20261027/irq_mask_corrected_title_source_trace/title_cpu_instructions.csv"
const REPORT_PATH := "res://reference/diagnostics/source_only_title_virtual_raster_20261027.json"

const TARGET_SOURCE_FRAME := 4692
const PRIOR_SOURCE_FRAME := TARGET_SOURCE_FRAME - 1
const NTSC_PPU_DOTS_PER_CPU_CYCLE := 3
const FIXED_UNITS_PER_PPU_DOT := 16
const FIXED_UNITS_PER_CPU_CYCLE := 48
const NTSC_DOTS_PER_SCANLINE := 341
const NEW_PPU_VBLANK_LINES := 20
const VISIBLE_CROP_TOP := 8
const VISIBLE_CROP_BOTTOM_EXCLUSIVE := 232
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const FCEUX_MODEL_BEAM_CYCLE_POST_RUN_VALIDATION := 139707186


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var frame_info := _read_frame_cycles()
	if frame_info.is_empty():
		_fail("Could not read the ROM-stepper source-frame cycle row.")
		return
	var phase_info := _read_boundary_phase(int(frame_info["cycle_start"]))
	if phase_info.is_empty():
		_fail("Could not read the ROM-stepper CPU/PPU phase at the target frame edge.")
		return
	var handoff := _read_handoff_events()
	if handoff.is_empty():
		_fail("Could not read the ROM-derived final title packet consumer.")
		return

	var renderer := TITLE_RENDERER_SCRIPT.new()
	root.add_child(renderer)
	await process_frame
	var frame_texture: ImageTexture = renderer.get("_frame_texture")
	if frame_texture == null:
		_fail("The ROM-derived title renderer did not produce its endpoint image.")
		return
	var image := frame_texture.get_image()
	var pixel := _first_nonblack_visible_pixel(image)
	if pixel.is_empty():
		_fail("No nonblack pixel was found in the visible title crop.")
		return

	# The renderer emits the full 240-line PPU image. NES visible output uses
	# dots 1..256, so output x maps to dot x+1. In the NewPPU software model,
	# output row y is composed while internal renderer line y+1 is active.
	var output_x := int(pixel["x"])
	var output_y := int(pixel["y"])
	var output_dot := output_x + 1
	var renderer_line := output_y + 1
	var lines_before_pixel := NEW_PPU_VBLANK_LINES + renderer_line
	var raster_dot_offset := lines_before_pixel * NTSC_DOTS_PER_SCANLINE + output_dot
	var boundary_credit := int(phase_info["cpu_credit_after_instruction"])
	var phase_adjusted_units := raster_dot_offset * FIXED_UNITS_PER_PPU_DOT + boundary_credit
	var cycle_numerator := phase_adjusted_units
	if cycle_numerator % FIXED_UNITS_PER_CPU_CYCLE != 0:
		_fail("The derived virtual pixel time is not on an integer CPU cycle.")
		return
	var raster_cycle_offset := cycle_numerator / FIXED_UNITS_PER_CPU_CYCLE
	var raster_cycle := int(frame_info["cycle_start"]) + raster_cycle_offset
	var commit_to_pixel_cycles := raster_cycle - int(handoff["final_consumer_absolute_cycle"])
	var source_event_pixel_offset := raster_cycle - int(handoff["start_cycle"])
	var crosscheck_delta := raster_cycle - FCEUX_MODEL_BEAM_CYCLE_POST_RUN_VALIDATION

	var result := {
		"status": "PASS" if output_x == 117 and output_y == 39 and crosscheck_delta == 0 else "FAIL",
		"purpose": "Derive a CPU timestamp for a virtual title raster coordinate from ROM-derived renderer pixels, ROM-stepper CPU/PPU phase, NTSC model constants, and ROM-stepper handoff events.",
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"runtime_changed": false,
		"capture_timestamps_used_as_inputs": false,
		"capture_pixels_or_audio_used_as_inputs": false,
		"source_artifact_provenance": {
			"handoff_events": HANDOFF_EVENTS_PATH,
			"source_cpu_stepper_sha256": handoff["source_cpu_stepper_sha256"],
			"source_event_builder_sha256": handoff["source_event_builder_sha256"],
			"input_timeline_sha256": handoff["input_timeline_sha256"],
			"captured_frame_intervals_used_for_event_generation": false,
			"captured_pixels_or_audio_used_for_event_generation": false,
		},
		"target_source_frame": TARGET_SOURCE_FRAME,
		"title_pixel": {
			"x": output_x,
			"output_y": output_y,
			"ppu_line": output_y,
			"ppu_dot": output_dot,
			"rgb": [int(pixel["r"]), int(pixel["g"]), int(pixel["b"])],
			"coordinate_source": "first nonblack pixel scanned from the live ROM-derived RomTitleBackgroundRenderer image in the 256x224 visible crop",
		},
		"rom_stepper_frame_edge": {
			"cycle_start": int(frame_info["cycle_start"]),
			"cycle_end": int(frame_info["cycle_end"]),
			"cycle_delta": int(frame_info["cycle_delta"]),
			"prior_frame_end_credit_units": boundary_credit,
			"credit_semantics": "PPU dot budget*16 minus CPU cycles*48; -64 means the CPU clock is four PPU dots ahead of the modeled raster boundary",
			"phase_source": "final ROM-only CPU-stepper instruction of source frame 4691, ending exactly at source frame 4692 cycle_start",
		},
		"virtual_raster_geometry": {
			"ppu_dots_per_cpu_cycle": NTSC_PPU_DOTS_PER_CPU_CYCLE,
			"dots_per_scanline": NTSC_DOTS_PER_SCANLINE,
			"source_stepper_frame_edge_anchor": "run_frame starts its NewPPU schedule at line 241/dot 0; cpu_credit carries the CPU-to-PPU phase across the prior source-frame boundary",
			"vblank_lines_before_internal_line_0": NEW_PPU_VBLANK_LINES,
			"internal_renderer_line_for_output_row": renderer_line,
			"complete_lines_before_pixel": lines_before_pixel,
			"unadjusted_dot_offset": raster_dot_offset,
			"boundary_phase_adjustment_dots": boundary_credit / FIXED_UNITS_PER_PPU_DOT,
			"phase_adjusted_dot_offset": phase_adjusted_units / FIXED_UNITS_PER_PPU_DOT,
			"frame_4692_first_render_line_shortened": false,
			"line_length_note": "The stepper starts frame 4692 with idle_synch=0 after the two reset frames and alternating normal frames; its NewPPU line-0 340-dot skip therefore does not apply on frame 4692.",
		},
		"derived_virtual_pixel_time": {
			"cpu_cycle_offset_from_frame_start": raster_cycle_offset,
			"absolute_cpu_cycle": raster_cycle,
			"start_stop_cycle": int(handoff["start_cycle"]),
			"cpu_cycle_offset_from_rom_start_stop": source_event_pixel_offset,
			"final_packet_consumer_cycle": int(handoff["final_consumer_absolute_cycle"]),
			"cycles_after_final_packet_consumer": commit_to_pixel_cycles,
		},
		"independent_post_run_validation": {
			"fceux_newppu_coordinate_derived_beam_cycle": FCEUX_MODEL_BEAM_CYCLE_POST_RUN_VALIDATION,
			"source_model_minus_fceux_cycles": crosscheck_delta,
			"source": "reference/diagnostics/title_first_pixel_trace_20261026/README.md",
			"used_to_choose_or_adjust_the_prediction": false,
		},
		"limits": [
			"This derives a virtual event time within the ROM-stepper's CPU/PPU synchronization and pinned-NewPPU scanline conventions; it is not a full 2C02 fetch/shifter simulation.",
			"The comparison validates the source model against the pinned FCEUX NewPPU timestamp only; it is not physical-console or analog video timing.",
			"Godot still draws a complete texture; this result does not control or prove host-window scanout at the calculated subframe time.",
		],
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_fail("Could not open the report path: %s" % REPORT_PATH)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("SOURCE_ONLY_TITLE_VIRTUAL_RASTER " + JSON.stringify(result))
	print("Report: %s" % ProjectSettings.globalize_path(REPORT_PATH))
	root.remove_child(renderer)
	renderer.free()
	await process_frame
	quit(0 if result["status"] == "PASS" else 1)


func _read_frame_cycles() -> Dictionary:
	var file := FileAccess.open(FRAME_CYCLES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= header.size() and int(row[header.find("source_frame")]) == TARGET_SOURCE_FRAME:
			return {
				"cycle_start": int(row[header.find("cycle_start")]),
				"cycle_end": int(row[header.find("cycle_end")]),
				"cycle_delta": int(row[header.find("cycle_delta")]),
			}
	return {}


func _read_boundary_phase(target_cycle: int) -> Dictionary:
	var file := FileAccess.open(CPU_TRACE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var header := file.get_csv_line()
	var source_frame_column := header.find("source_frame")
	var cycle_end_column := header.find("cycle_after_instruction")
	var credit_column := header.find("cpu_credit_after_instruction")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() != header.size():
			continue
		if int(row[source_frame_column]) == PRIOR_SOURCE_FRAME \
				and int(row[cycle_end_column]) == target_cycle:
			return {
				"source_frame": PRIOR_SOURCE_FRAME,
				"cycle_after_instruction": target_cycle,
				"cpu_credit_after_instruction": int(row[credit_column]),
			}
	return {}


func _read_handoff_events() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HANDOFF_EVENTS_PATH))
	if not parsed is Dictionary or parsed.get("source_rom_sha256", "") != SOURCE_ROM_SHA256:
		return {}
	var anchor: Dictionary = parsed.get("start_anchor", {})
	var final_consumer: Dictionary = {}
	for event_value in parsed.get("events", []):
		var event: Dictionary = event_value
		if event.get("kind", "") == "queue_consumer_packet" \
				and int(event.get("ordinal", -1)) == 241:
			final_consumer = event
	if anchor.is_empty() or final_consumer.is_empty():
		return {}
	return {
		"start_cycle": int(anchor.get("cycle", -1)),
		"final_consumer_cycle_offset": int(final_consumer.get("cycle_offset", -1)),
		"final_consumer_absolute_cycle": int(anchor.get("cycle", -1)) \
			+ int(final_consumer.get("cycle_offset", -1)),
		"source_cpu_stepper_sha256": str(parsed.get("source_cpu_stepper_sha256", "")),
		"source_event_builder_sha256": str(parsed.get("event_builder_sha256", "")),
		"input_timeline_sha256": str(parsed.get("input_timeline_sha256", "")),
	}


func _first_nonblack_visible_pixel(image: Image) -> Dictionary:
	if image.get_width() != 256 or image.get_height() != 240:
		return {}
	for y in range(VISIBLE_CROP_TOP, VISIBLE_CROP_BOTTOM_EXCLUSIVE):
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.r8 != 0 or color.g8 != 0 or color.b8 != 0:
				return {"x": x, "y": y, "r": color.r8, "g": color.g8, "b": color.b8}
	return {}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
