extends SceneTree
## Capture the ROM-derived Godot presentation at selected original source frames.
## PNGs are validation references only; they must never be used as runtime assets.
## Usage:
##   godot --path . --script tools/diagnostics/capture_full_opening_runtime_reference.gd
##   godot --path . --script tools/diagnostics/capture_full_opening_runtime_reference.gd -- --index=reference/opening_full_frame_capture_20261025_101014/screen_index.csv

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DEFAULT_INDEX_PATH := "res://reference/opening_full_frame_capture_20261025_101014/screen_index.csv"
const NES_FPS := 60.0988
const FRAME_STEP_EPSILON := 0.00001
const START_SOURCE_FRAME := 4661


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if OS.get_cmdline_user_args().has("--hide-window"):
		# Godot does not allow hiding its main window on macOS. Move the capture
		# window offscreen so chunked validation does not flash over the user's UI.
		get_root().get_window().position = Vector2i(-10000, -10000)
	var index_path := _get_index_path()
	var source_frames := _read_source_frames(index_path)
	if source_frames.is_empty():
		push_error("The selected FCEUX index contains no source frames: %s" % index_path)
		quit(1)
		return

	var scene_resource := load(MAIN_SCENE_PATH) as PackedScene
	if scene_resource == null:
		push_error("Could not load the configured main scene.")
		quit(1)
		return
	var runtime_scene := scene_resource.instantiate()
	runtime_scene.name = "Main"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(runtime_scene)
	await process_frame
	# Every presentation node is advanced explicitly by SourcePresenter's ROM
	# frame clock. Disable inherited and overridden child clocks too; otherwise
	# waiting one render frame per source frame lets animation children advance a
	# second time and desynchronizes later scenes.
	runtime_scene.propagate_call("set_process", [false])
	var presenter = runtime_scene.get_node("SourcePresenter")
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	var force_software_mode := OS.get_cmdline_user_args().has(
		"--force-software-renderer-diagnostics")
	var require_gpu_diagnostic := OS.get_cmdline_user_args().has("--gpu-diagnostic")
	# Native Image.blit_rect tile-row rendering is the runtime default. Pass
	# --pixel-loop-diagnostics only to compare against the slower per-pixel path.
	field_screen.use_pixel_loop_diagnostics = \
			OS.get_cmdline_user_args().has("--pixel-loop-diagnostics")
	# Source state is advanced manually, and child process clocks are disabled.
	# Suspend expensive texture rebuilds while seeking between requested frames.
	# ROM clocks, command handlers, OAM state and PPU state still advance every
	# source frame; renderers rebuild once at each requested checkpoint.
	presenter.set_capture_render_updates_suppressed(true)
	field_screen.set_rendering_enabled(false)
	field_screen.set_force_software_renderer_diagnostics(force_software_mode)
	var gpu_background_mode := field_screen.use_gpu_background_renderer
	if require_gpu_diagnostic:
		if not field_screen.use_gpu_background_renderer:
			push_error("GPU background renderer is unavailable: %s" %
				field_screen.gpu_background_fallback_reason)
			quit(1)
			return

	var output_root := _get_output_root()
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var current_source_frame := int(presenter.state.get("source_frame", 0))
	var title_handoff_started := false
	var title_transition_frames_advanced := 0
	var captured_count := 0
	var viewport_readback_count := 0
	var cached_image_reuse_count := 0
	var gpu_diagnostic_fallback_count := 0
	var last_visual_key := ""
	var last_visual_image: Image
	var last_visual_resources: Array[Resource] = []
	for source_frame in source_frames:
		if source_frame < 0:
			continue
		presenter.set_capture_render_updates_suppressed(true)
		if source_frame <= START_SOURCE_FRAME:
			field_screen.set_rendering_enabled(false)
		if source_frame <= START_SOURCE_FRAME:
			while current_source_frame < source_frame:
				if not _arm_start_input_raster_stop(presenter, current_source_frame):
					quit(1)
					return
				if not title_handoff_started \
						and current_source_frame == START_SOURCE_FRAME - 1:
					var start_event := InputEventAction.new()
					start_event.action = &"opening_start"
					start_event.pressed = true
					runtime_scene._unhandled_input(start_event)
					title_handoff_started = true
				presenter._advance_source_frame()
				current_source_frame = int(presenter.state.get("source_frame", current_source_frame + 1))
		else:
			if not title_handoff_started:
				while current_source_frame < START_SOURCE_FRAME:
					if not _arm_start_input_raster_stop(presenter, current_source_frame):
						quit(1)
						return
					if not title_handoff_started \
							and current_source_frame == START_SOURCE_FRAME - 1:
						var start_event := InputEventAction.new()
						start_event.action = &"opening_start"
						start_event.pressed = true
						runtime_scene._unhandled_input(start_event)
						title_handoff_started = true
					presenter._advance_source_frame()
					current_source_frame = int(presenter.state.get("source_frame", current_source_frame + 1))
			while title_transition_frames_advanced < source_frame - START_SOURCE_FRAME:
				runtime_scene._advance_title_transition(1.0 / NES_FPS + FRAME_STEP_EPSILON)
				title_transition_frames_advanced += 1
				await process_frame

		presenter.set_capture_render_updates_suppressed(false)
		if source_frame <= START_SOURCE_FRAME:
			field_screen.set_rendering_enabled(true)
		if gpu_background_mode and not field_screen.use_gpu_background_renderer:
			gpu_diagnostic_fallback_count += 1
			var backend_error := field_screen.gpu_background_fallback_reason
			if backend_error.is_empty():
				backend_error = "backend is disabled"
			print("GPU_DIAGNOSTIC_FALLBACK frame=%d count=%d error=%s" % [
				source_frame, gpu_diagnostic_fallback_count, backend_error,
			])
			push_error("GPU diagnostic backend fell back at source frame %d: %s" % [
				source_frame, backend_error,
			])
			if require_gpu_diagnostic:
				print("GPU_DIAGNOSTIC_SUMMARY fallback_count=%d viewport_readbacks=%d cached_image_reuses=%d" % [
					gpu_diagnostic_fallback_count, viewport_readback_count,
					cached_image_reuse_count,
				])
				quit(1)
				return
		var visual_state := _visual_state_key(runtime_scene)
		var visual_key := str(visual_state["key"])
		var image: Image
		if not gpu_background_mode and visual_key == last_visual_key \
				and last_visual_image != null:
			image = last_visual_image
			cached_image_reuse_count += 1
		else:
			await process_frame
			# Force the pending CanvasItem changes into the viewport, then wait one
			# additional process frame before readback. On Metal, frame_post_draw can
			# still expose the previous viewport image after an explicit state replay.
			RenderingServer.force_draw(false)
			await process_frame
			var readback_attempts := 0
			while readback_attempts < 12:
				image = get_root().get_texture().get_image()
				if image != null and image.get_size() == Vector2i(256, 240):
					break
				# A viewport readback can be transiently empty on Metal while the
				# previous frame's texture is retired. Retry without advancing source.
				readback_attempts += 1
				RenderingServer.force_draw(false)
				await process_frame
			if image == null or image.get_size() != Vector2i(256, 240):
				push_error("Runtime viewport did not produce a 256x240 image at frame %d after %d readback attempts." % [source_frame, readback_attempts])
				quit(1)
				return
			if not gpu_background_mode:
				last_visual_key = visual_key
				last_visual_image = image
				last_visual_resources = visual_state["resources"]
			viewport_readback_count += 1
		var frame_path := output_root + "/frame_%06d.png" % source_frame
		if image.save_png(frame_path) != OK:
			push_error("Could not save runtime frame %d." % source_frame)
			quit(1)
			return
		captured_count += 1

	print("Captured %d opening reference frames through source frame %d: %s (index: %s; viewport readbacks=%d, cached image reuses=%d)" % [
		captured_count, source_frames[-1], output_root, index_path,
		viewport_readback_count, cached_image_reuse_count,
	])
	if gpu_background_mode or require_gpu_diagnostic:
		print("GPU_DIAGNOSTIC_SUMMARY fallback_count=%d viewport_readbacks=%d cached_image_reuses=%d" % [
			gpu_diagnostic_fallback_count, viewport_readback_count,
			cached_image_reuse_count,
		])
	quit(0)


func _arm_start_input_raster_stop(presenter: Node, current_source_frame: int) -> bool:
	if current_source_frame + 1 != START_SOURCE_FRAME:
		return true
	# In the same-input ROM capture Start is held beginning on source frame
	# 4661. The ROM Start branch clears worker slot $000D at $8040; scheduler
	# order lets the main slot handle Start before the raster slot is resumed.
	# This harness applies that source-supported state change at the frame edge;
	# the exact CPU write cycle is not captured. Preserve the programmed IRQ
	# table and suppress only the producer release.
	if presenter._raster_event_generator == null:
		push_error("Start input frame has no active ROM raster producer to stop.")
		return false
	if not presenter._raster_event_generator.stop_producer_before_source_frame(START_SOURCE_FRAME):
		push_error("Could not stop the raster producer at the recorded Start-input edge.")
		return false
	return true


func _visual_state_key(root_node: Node) -> Dictionary:
	var parts := PackedStringArray([
		"viewport:%s:%s" % [get_root().size, get_root().get_canvas_transform()],
	])
	var resources: Array[Resource] = []
	_append_canvas_state(root_node, parts, resources)
	return {"key": "\n".join(parts), "resources": resources}


func _append_canvas_state(node: Node, parts: PackedStringArray,
		resources: Array[Resource]) -> void:
	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		# Hidden branches cannot affect this viewport's pixels, so their changing
		# ROM state must not invalidate an otherwise reusable image.
		if not canvas_item.is_visible_in_tree():
			return
		parts.append("item:%s:%s:%s" % [node.get_path(), node.get_class(),
			canvas_item.get_global_transform_with_canvas()])
		parts.append("canvas:%d:%d:%s:%s:%d:%s:%d" % [
			canvas_item.z_index,
			1 if canvas_item.z_as_relative else 0,
			"%08X" % canvas_item.modulate.to_rgba32(),
			"%08X" % canvas_item.self_modulate.to_rgba32(),
			canvas_item.texture_filter,
			str(canvas_item.material),
			1 if canvas_item.use_parent_material else 0,
		])
		var available_properties: Dictionary = {}
		for property_info in node.get_property_list():
			available_properties[str(property_info["name"])] = true
		for property_name in [
			"color", "offset_left", "offset_top", "offset_right", "offset_bottom",
			"size", "texture", "_texture", "_frame_texture", "_image_texture",
			"frame", "frame_coords", "hframes", "vframes", "region_enabled",
			"region_rect", "offset", "flip_h", "flip_v", "centered",
		]:
			if not available_properties.has(property_name):
				continue
			var value: Variant = node.get(property_name)
			if value is Texture2D:
				var texture := value as Texture2D
				resources.append(texture)
				parts.append("%s:texture:%d" % [property_name, texture.get_instance_id()])
			elif value is Resource:
				var resource := value as Resource
				resources.append(resource)
				parts.append("%s:resource:%d" % [property_name, resource.get_instance_id()])
			else:
				parts.append("%s:%s" % [property_name, var_to_str(value)])
		var script_resource := node.get_script() as Script
		if script_resource != null:
			parts.append("script:%s" % script_resource.resource_path)
	for child in node.get_children():
		_append_canvas_state(child, parts, resources)


func _get_index_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--index="):
			var selected_path := argument.trim_prefix("--index=")
			if not selected_path.begins_with("/") and not selected_path.begins_with("res://") and not selected_path.begins_with("user://"):
				selected_path = "res://" + selected_path
			return selected_path
	return DEFAULT_INDEX_PATH


func _get_output_root() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			var selected_path := argument.trim_prefix("--output-dir=")
			if not selected_path.begins_with("/") and not selected_path.begins_with("res://"):
				selected_path = "res://" + selected_path
			return selected_path
	return "res://reference/diagnostics/opening_runtime_full_%d" % int(Time.get_unix_time_from_system())


func _read_source_frames(index_path: String) -> Array[int]:
	var index_file := FileAccess.open(index_path, FileAccess.READ)
	if index_file == null:
		push_error("Could not open the selected FCEUX reference index: %s" % index_path)
		return []
	var header := index_file.get_line().strip_edges().split(",")
	var frame_column := header.find("source_frame")
	if frame_column < 0:
		push_error("Selected reference index has no source_frame column: %s" % index_path)
		index_file.close()
		return []
	var frames: Array[int] = []
	while not index_file.eof_reached():
		var fields := index_file.get_line().strip_edges().split(",")
		if frame_column < fields.size() and fields[frame_column].is_valid_int():
			frames.append(int(fields[frame_column]))
	index_file.close()
	frames.sort()
	var unique_frames: Array[int] = []
	var previous_frame := -1
	for frame in frames:
		if frame != previous_frame:
			unique_frames.append(frame)
			previous_frame = frame
	return unique_frames
