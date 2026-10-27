extends SceneTree
## Verify the source-command runtime's BG08 CHR-pair carry-over and capture
## sparse FCEUX checkpoints around the transition.
## Usage: godot --path . --script tools/diagnostics/verify_bg08_pending_pair_runtime.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CHECKPOINTS: Array[int] = [1026, 1047, 1048, 1050, 1522]
const IMAGE_CHECKPOINTS: Array[int] = [1050, 1522]


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the configured main scene.")
		return
	var runtime := packed.instantiate()
	runtime.name = "Main"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(runtime)
	await process_frame
	runtime.set_process(false)
	var presenter = runtime.get_node("SourcePresenter")
	presenter.set_process(false)
	var renderer: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	renderer.set_rendering_enabled(false)

	var output_root := "res://reference/diagnostics/bg08_pending_pair_%d" % int(Time.get_unix_time_from_system())
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var recorded_states: Array[Dictionary] = []
	var current_frame := int(presenter.state.get("source_frame", 0))
	for source_frame in CHECKPOINTS:
		while current_frame < source_frame:
			presenter._advance_source_frame()
			current_frame = int(presenter.state.get("source_frame", current_frame + 1))
			await process_frame

		if source_frame == 1047 or source_frame == 1048:
			var model = presenter.get("_bg08_raster_model")
			if model == null:
				_fail("BG08 raster model was not active by source frame %d." % source_frame)
				return
			var frame_state: Dictionary = model.frame_state()
			var selectors: Array = frame_state.get("initial_2k_selectors", [])
			var model_state: Dictionary = model.debug_snapshot()
			if source_frame == 1047:
				if selectors != [0x3A, 0x00] or bool(model_state.get("background_pair_transition_applied", true)):
					_fail("Frame 1047 did not retain BG03 R0/R1=$3A/$00 before the loader transition: %s" % str(model_state))
					return
			else:
				if selectors != [0x40, 0x00] or not bool(model_state.get("background_pair_transition_applied", false)):
					_fail("Frame 1048 did not apply the BG08 R0/R1=$40/$00 transition: %s" % str(model_state))
					return
			recorded_states.append({
				"source_frame": source_frame,
				"initial_2k_selectors": selectors,
				"model": model_state,
				"frame_state": frame_state,
			})

		if IMAGE_CHECKPOINTS.has(source_frame):
			renderer.set_rendering_enabled(true)
			await process_frame
			var image := get_root().get_texture().get_image()
			if image == null or image.get_size() != Vector2i(256, 240):
				_fail("Could not render source frame %d as a 256x240 image." % source_frame)
				return
			var image_path := output_root + "/frame_%06d.png" % source_frame
			if image.save_png(image_path) != OK:
				_fail("Could not save source frame %d." % source_frame)
				return
			renderer.set_rendering_enabled(false)

	var state_file := FileAccess.open(output_root + "/transition_states.json", FileAccess.WRITE)
	if state_file == null:
		_fail("Could not write BG08 transition state evidence.")
		return
	state_file.store_string(JSON.stringify(recorded_states, "\t") + "\n")
	state_file.close()
	print("BG08 pending-pair runtime verified at frames 1047/1048; captures: %s" % output_root)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
