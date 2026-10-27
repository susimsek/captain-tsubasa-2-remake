extends SceneTree

const PRESENTER_SCENE := preload("res://scenes/prototypes/cold_start_source_command_presenter.tscn")
const TARGET_FRAMES: Array[int] = [
	1, 8, 12, 13, 14, 26, 27,
	377, 378, 379, 380, 381, 382, 500, 749, 750, 812, 813, 814, 815,
	1028, 1029, 1030, 1047, 1048, 1108, 1522, 1528, 1529, 1530,
	1759, 1760, 1778, 1779, 1780, 2119, 2120, 2121, 2122,
	2339, 2340, 2341, 2367, 2408,
	2688, 2689, 2690, 2939, 3554, 3555, 3596, 3597, 3598,
]
const WIDTH := 256
const HEIGHT := 240
const CSV_PATH := "res://reference/diagnostics/gpu_bg_modes_integrated_renderer_20261026.csv"

var _presenter: Node
var _screen: RomPpuNametableScreenRenderer
var _rows := PackedStringArray()
var _exact_frames := 0
var _total_diff_channels := 0
var _total_cpu_usec := 0
var _total_gpu_usec := 0
var _max_gpu_usec := 0
var _error_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(WIDTH, HEIGHT)
	root.content_scale_size = Vector2i(WIDTH, HEIGHT)
	_presenter = PRESENTER_SCENE.instantiate()
	root.add_child(_presenter)
	await process_frame
	_presenter.set_process(false)
	_screen = _presenter.get_node("FieldScreen") as RomPpuNametableScreenRenderer
	_screen.set_force_software_renderer_diagnostics(true)
	_screen.set_rendering_enabled(false)
	for frame in TARGET_FRAMES:
		if not _advance_to_frame(frame):
			quit(1)
			return
		var cpu_started := Time.get_ticks_usec()
		_screen.set_rendering_enabled(true)
		var software_image := _screen._texture.get_image()
		var cpu_done := Time.get_ticks_usec()
		_screen.set_rendering_enabled(false)
		if software_image == null:
			_rows.append("%d,%02X,-1,%d,0,,,software renderer produced no image" % [
				frame, _screen._active_background_id, cpu_done - cpu_started,
			])
			_error_count += 1
			continue

		var gpu_started := Time.get_ticks_usec()
		_screen.set_force_software_renderer_diagnostics(false)
		_screen.set_rendering_enabled(true)
		await process_frame
		await RenderingServer.frame_post_draw
		var gpu_image := _screen.get_gpu_background_image()
		var gpu_done := Time.get_ticks_usec()
		_screen.set_rendering_enabled(false)
		var gpu_error := ""
		if not _screen.use_gpu_background_renderer:
			gpu_error = "GPU backend fell back: %s" % str(
				_screen.gpu_background_fallback_reason)
		elif gpu_image == null or gpu_image.get_width() != WIDTH \
				or gpu_image.get_height() != HEIGHT:
			gpu_error = "GPU backend produced no 256x240 image."
		if not gpu_error.is_empty():
			_rows.append("%d,%02X,-1,%d,%d,%s,%s,%s" % [
				frame, _screen._active_background_id, cpu_done - cpu_started,
				gpu_done - gpu_started, _sha256(PackedByteArray()),
				_sha256(software_image.get_data()), _csv_escape(gpu_error),
			])
			_error_count += 1
			_screen.set_force_software_renderer_diagnostics(true)
			continue

		var diff_channels := _count_rgb_differences(gpu_image, software_image)
		var cpu_usec := cpu_done - cpu_started
		var gpu_usec := gpu_done - gpu_started
		_total_cpu_usec += cpu_usec
		_total_gpu_usec += gpu_usec
		_max_gpu_usec = maxi(_max_gpu_usec, gpu_usec)
		_total_diff_channels += diff_channels
		if diff_channels == 0 and gpu_image.get_data() == software_image.get_data():
			_exact_frames += 1
		_rows.append("%d,%02X,%d,%d,%d,%s,%s" % [
			frame, _screen._active_background_id, diff_channels, cpu_usec, gpu_usec,
			_sha256(gpu_image.get_data()), _sha256(software_image.get_data()),
		])
		_rows[_rows.size() - 1] += ","
		_screen.set_force_software_renderer_diagnostics(true)
	if not _write_csv():
		quit(1)
		return
	var sample_count := TARGET_FRAMES.size()
	print("gpu_background_renderer_samples=%d exact_rgba_frames=%d errors=%d total_diff_rgb_channels=%d software_mean_ms=%.3f gpu_mean_ms=%.3f gpu_max_ms=%.3f csv=%s" % [
		sample_count, _exact_frames, _error_count, _total_diff_channels,
		float(_total_cpu_usec) / sample_count / 1000.0,
		float(_total_gpu_usec) / sample_count / 1000.0,
		float(_max_gpu_usec) / 1000.0,
		CSV_PATH,
	])
	quit(1 if _error_count > 0 else 0)


func _advance_to_frame(target_frame: int) -> bool:
	while int(_presenter.state.get("source_frame", 0)) < target_frame:
		_presenter._advance_source_frame()
		if bool(_presenter.state.get("slice_failed", false)):
			push_error("Presenter failed before source frame %d." % target_frame)
			return false
	return true


func _count_rgb_differences(first: Image, second: Image) -> int:
	var count := 0
	for y in HEIGHT:
		for x in WIDTH:
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if a.r != b.r:
				count += 1
			if a.g != b.g:
				count += 1
			if a.b != b.b:
				count += 1
	return count


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _csv_escape(value: String) -> String:
	return "\"%s\"" % value.replace("\"", "\"\"")


func _write_csv() -> bool:
	var file := FileAccess.open(CSV_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write integrated GPU backend CSV: %s" % CSV_PATH)
		return false
	file.store_string("frame,bg_id,differing_rgb_channels,cpu_usec,gpu_usec,gpu_sha256,cpu_sha256,error\n")
	file.store_string("\n".join(_rows) + "\n")
	return true
