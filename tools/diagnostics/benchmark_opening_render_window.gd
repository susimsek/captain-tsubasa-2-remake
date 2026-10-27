extends SceneTree

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const FIRST_MEASURED_FRAME := 2367
const LAST_MEASURED_FRAME := 2408


func _initialize() -> void:
	call_deferred("_run_benchmark")


func _run_benchmark() -> void:
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load the source presenter for the render benchmark.")
		quit(1)
		return
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_force_software_renderer_diagnostics(true)
	# The renderer defaults to native row blits. This flag explicitly selects
	# the slower per-pixel path for diagnostic comparison.
	field_screen.use_pixel_loop_diagnostics = \
			OS.get_cmdline_user_args().has("--pixel-loop-diagnostics")
	field_screen.use_dictionary_ppu_lookups_diagnostics = \
		OS.get_cmdline_user_args().has("--dictionary-ppu-lookups")
	field_screen.use_packed_row_copy = not \
			OS.get_cmdline_user_args().has("--image-blit-reference")
	field_screen.use_row_chunk_cache_diagnostics = \
			OS.get_cmdline_user_args().has("--row-chunk-cache")
	if field_screen.use_pixel_loop_diagnostics:
		field_screen.use_packed_row_copy = false
	field_screen.set_rendering_enabled(false)
	while int(presenter.state.get("source_frame", 0)) < FIRST_MEASURED_FRAME - 1:
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			push_error("Presenter failed before the benchmark window.")
			quit(1)
			return
	field_screen.set_rendering_enabled(true)
	var durations_usec := PackedInt64Array()
	var hash_lines := PackedStringArray(["source_frame,background_texture_sha256"])
	for source_frame in range(FIRST_MEASURED_FRAME, LAST_MEASURED_FRAME + 1):
		var started := Time.get_ticks_usec()
		presenter._advance_source_frame()
		durations_usec.append(Time.get_ticks_usec() - started)
		if bool(presenter.state.get("slice_failed", false)):
			push_error("Presenter failed at benchmark frame %d." % source_frame)
			quit(1)
			return
		var texture_image := field_screen._texture.get_image()
		hash_lines.append("%d,%s" % [source_frame, _sha256_hex(texture_image.get_data())])
	var sorted := durations_usec.duplicate()
	sorted.sort()
	var total := 0
	for duration in durations_usec:
		total += duration
	var average_usec := float(total) / durations_usec.size()
	var median_usec := int(sorted[sorted.size() / 2])
	var p95_usec := int(sorted[int(floor((sorted.size() - 1) * 0.95))])
	var hashes_path := "/tmp/opening_render_window_hashes.csv"
	if field_screen.use_row_chunk_cache_diagnostics:
		hashes_path = "/tmp/opening_render_window_hashes_row_chunk.csv"
	var hashes_file := FileAccess.open(hashes_path, FileAccess.WRITE)
	if hashes_file != null:
		hashes_file.store_string("\n".join(hash_lines) + "\n")
	print("frame_window=%d-%d count=%d mean_usec=%.1f median_usec=%d p95_usec=%d" % [
		FIRST_MEASURED_FRAME, LAST_MEASURED_FRAME, durations_usec.size(),
		average_usec, median_usec, p95_usec,
	])
	var direct_render_total_usec := 0
	for _sample in 5:
		var render_started := Time.get_ticks_usec()
		field_screen._redraw_screen()
		direct_render_total_usec += Time.get_ticks_usec() - render_started
	print("field_screen_redraw_only_mean_usec=%.1f" % (float(direct_render_total_usec) / 5.0))
	print("source_mmc3_fetch_path_active=%s write_events=%d" % [
		str(field_screen._source_mmc3_chr_writes_active),
		field_screen._source_mmc3_chr_writes.size(),
	])
	print("pixel_loop_diagnostics_enabled=%s dictionary_ppu_lookups=%s packed_row_copy=%s row_chunk_cache=%s image_cache_rows=%d byte_cache_rows=%d byte_chunk_cache_rows=%d chunk_hits=%d chunk_misses=%d" % [
		str(field_screen.use_pixel_loop_diagnostics),
		str(field_screen.use_dictionary_ppu_lookups_diagnostics),
		str(field_screen.use_packed_row_copy),
		str(field_screen.use_row_chunk_cache_diagnostics),
		field_screen._tile_row_blit_cache.size(),
		field_screen._tile_row_byte_cache.size(),
		field_screen._tile_row_chunk_byte_cache.size(),
		field_screen._row_chunk_cache_hits,
		field_screen._row_chunk_cache_misses,
	])
	quit(0)


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(bytes)
	return hasher.finish().hex_encode()
