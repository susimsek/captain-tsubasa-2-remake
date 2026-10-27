extends SceneTree
## Render the active source-driven Godot scene at all same-numbered FCEUX
## samples in screen_index.csv. The reference screenshots are comparison-only.
## Usage: godot --path . --script tools/diagnostics/capture_sparse_opening_runtime_reference.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SCREEN_INDEX_PATH := "res://reference/opening_reference_capture/screen_index.csv"
const NES_FPS := 60.0988
const FRAME_STEP_EPSILON := 0.00001
const START_SOURCE_FRAME := 4661


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var index_file := FileAccess.open(SCREEN_INDEX_PATH, FileAccess.READ)
	if index_file == null:
		push_error("Could not open the sparse FCEUX screen index.")
		quit(1)
		return
	var source_frames: Array[int] = []
	index_file.get_line() # Header.
	while not index_file.eof_reached():
		var fields := index_file.get_line().strip_edges().split(",")
		if fields.size() >= 2 and fields[0].is_valid_int():
			source_frames.append(int(fields[0]))
	index_file.close()
	if source_frames.is_empty():
		push_error("The sparse FCEUX screen index has no source frames.")
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
	runtime_scene.set_process(false)
	var presenter = runtime_scene.get_node("SourcePresenter")
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	# Source-state advancement can rebuild the full 256x240 texture at every
	# intermediate emulated frame. Rebuild only at the sparse FCEUX checkpoints;
	# each saved checkpoint still redraws from the live ROM-derived state.
	field_screen.set_rendering_enabled(false)

	var output_root := "res://reference/diagnostics/opening_runtime_sparse_%d" % int(Time.get_unix_time_from_system())
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var current_source_frame := int(presenter.state.get("source_frame", 0))
	var title_handoff_started := false
	var title_transition_frames_advanced := 0
	for source_frame in source_frames:
		if source_frame <= START_SOURCE_FRAME:
			while current_source_frame < source_frame:
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

		if source_frame <= START_SOURCE_FRAME:
			field_screen.set_rendering_enabled(true)
		await process_frame
		var image := get_root().get_texture().get_image()
		if image == null or image.get_size() != Vector2i(256, 240):
			push_error("Runtime viewport did not produce a 256x240 image at frame %d." % source_frame)
			quit(1)
			return
		var frame_path := output_root + "/frame_%06d.png" % source_frame
		if image.save_png(frame_path) != OK:
			push_error("Could not save runtime frame %d." % source_frame)
			quit(1)
			return
		if source_frame <= START_SOURCE_FRAME:
			field_screen.set_rendering_enabled(false)

	print("Captured %d sparse opening checkpoints through frame %d: %s" % [
		source_frames.size(), source_frames[-1], output_root,
	])
	quit(0)
