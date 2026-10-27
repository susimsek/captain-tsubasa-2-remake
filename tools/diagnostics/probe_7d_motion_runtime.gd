extends SceneTree
## Dumps the live Godot $7D motion-record state at FCEUX source-frame anchors.
## Validation only; no ROM or emulator is loaded at runtime by the game.
## Usage:
##   godot --audio-driver Dummy --path . --script tools/diagnostics/probe_7d_motion_runtime.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TARGET_SOURCE_FRAMES := [
	2367, 2368, 2369,
	2438, 2439, 2440, 2441, 2442, 2443, 2444, 2445, 2446, 2447, 2448,
	2449, 2450, 2451, 2452, 2453, 2454, 2455, 2456, 2457, 2458, 2459,
	2460, 2461, 2462, 2463, 2464, 2465,
]
const DEFAULT_OUTPUT_PATH := "res://reference/diagnostics/opening_runtime_7d_motion_validation_20261025/godot_motion_state.json"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
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
	runtime_scene.propagate_call("set_process", [false])
	var presenter = runtime_scene.get_node("SourcePresenter")
	presenter.set_capture_render_updates_suppressed(true)
	presenter.get_node("FieldScreen").set_rendering_enabled(false)

	var current_source_frame := int(presenter.state.get("source_frame", 0))
	var samples: Dictionary = {}
	for target_source_frame in TARGET_SOURCE_FRAMES:
		while current_source_frame < target_source_frame:
			presenter._advance_source_frame()
			current_source_frame = int(
				presenter.state.get("source_frame", current_source_frame + 1))
		var sample: Dictionary = {}
		var model_variant: Variant = presenter.state.get("7d_motion_model", {})
		if model_variant is Dictionary:
			sample["motion_model"] = model_variant.duplicate(true)
		for child in presenter.get_children():
			if child is RomSpriteAnimationPrototype and child.animation_id == "0x7D":
				sample["node_origin_override_enabled"] = child.get("_origin_override_enabled")
				sample["node_origin_override"] = child.get("_origin_override")
				sample["node_origin_x_motion_offset"] = child.get("_origin_x_motion_offset")
				break
		samples[str(target_source_frame)] = sample

	var report := {
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"source_frame_convention": "presenter state after advancing the matching source frame",
		"target_source_frames": TARGET_SOURCE_FRAMES,
		"samples": samples,
	}
	var output_path := DEFAULT_OUTPUT_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
			if not output_path.begins_with("res://") and not output_path.begins_with("/"):
				output_path = "res://" + output_path
	var output_file := FileAccess.open(output_path, FileAccess.WRITE)
	if output_file == null:
		push_error("Could not create 7D runtime motion-state output: %s" % output_path)
		quit(1)
		return
	output_file.store_string(JSON.stringify(report, "\t") + "\n")
	output_file.close()
	print("Captured $7D motion model at %d source-frame anchors: %s" % [
		TARGET_SOURCE_FRAMES.size(), output_path,
	])
	quit(0)
