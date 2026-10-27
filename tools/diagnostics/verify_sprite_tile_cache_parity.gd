extends SceneTree
## Compare every distinct live sprite pose in the opening with the retained
## per-pixel renderer. Writes a machine-readable report under reference/diagnostics.
## Run: godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_sprite_tile_cache_parity.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TARGET_SOURCE_FRAME := 4661
const REPORT_PATH := "res://reference/diagnostics/sprite_tile_cache_parity_20261026.json"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _last_checked_pose_by_instance: Dictionary = {}
var _pose_count_by_animation: Dictionary = {}
var _mismatches: Array[Dictionary] = []
var _checked_pose_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		_fail("Could not load the configured main scene.")
		return
	var runtime := packed_scene.instantiate()
	root.add_child(runtime)
	runtime.set_process(false)
	runtime.propagate_call("set_process", [false])
	await process_frame
	var audio := runtime.get_node_or_null("OpeningAudio") as AudioStreamPlayer
	if audio != null:
		audio.stop()
	var presenter: Node = runtime.get_node("SourcePresenter")
	presenter.set_process(false)
	var field_screen := presenter.get_node("FieldScreen") as RomPpuNametableScreenRenderer
	field_screen.set_rendering_enabled(false)

	var current_frame := int(presenter.state.get("source_frame", 0))
	var first_source_frame := current_frame
	_check_active_poses(presenter, current_frame)
	while current_frame < TARGET_SOURCE_FRAME:
		presenter._advance_source_frame()
		current_frame = int(presenter.state.get("source_frame", current_frame + 1))
		_check_active_poses(presenter, current_frame)

	var result := {
		"status": "PASS" if _mismatches.is_empty() else "FAIL",
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"comparison": "cached tile renderer ImageTexture bytes vs retained per-pixel software renderer bytes",
		"source_frames_checked": [first_source_frame, current_frame],
		"distinct_pose_count": _checked_pose_count,
		"pose_count_by_animation": _pose_count_by_animation,
		"pose_mismatch_count": _mismatches.size(),
		"mismatch_examples": _mismatches.slice(0, 12),
		"shared_tile_cache_entries": RomSpriteAnimationPrototype._shared_sprite_tile_images.size(),
		"shared_tile_cache_capacity": RomSpriteAnimationPrototype.MAX_SHARED_SPRITE_TILE_CACHE_ENTRIES,
		"verification_command": "godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_sprite_tile_cache_parity.gd",
		"nes_file_required_at_runtime": false,
		"emulator_required": false,
		"rom_derived_project_resources_used": true,
	}
	var report := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report == null:
		push_error("Could not write sprite cache report: %s" % REPORT_PATH)
		root.remove_child(runtime)
		runtime.free()
		quit(1)
		return
	report.store_string(JSON.stringify(result, "\t") + "\n")
	report.close()
	print("SPRITE_TILE_CACHE_PARITY " + JSON.stringify(result))
	print("Report: %s" % ProjectSettings.globalize_path(REPORT_PATH))
	root.remove_child(runtime)
	runtime.free()
	RomSpriteAnimationPrototype._shared_sprite_tile_images.clear()
	await process_frame
	await process_frame
	quit(1 if not _mismatches.is_empty() else 0)


func _check_active_poses(presenter: Node, source_frame: int) -> void:
	var active_nodes: Array = []
	active_nodes.append_array(presenter.get("_animation_nodes"))
	active_nodes.append_array(presenter.get("_latched_animation_nodes"))
	for node_variant in active_nodes:
		if not node_variant is RomSpriteAnimationPrototype:
			continue
		var animation_node := node_variant as RomSpriteAnimationPrototype
		if animation_node._texture == null:
			continue
		var pose := animation_node._resolve_current_pose()
		if pose.is_empty():
			continue
		var pose_key := str(pose.get("pose_key", ""))
		var instance_key := str(animation_node.get_instance_id())
		var complete_pose_key := "%s|oam_slot:%d|oam_order:%d" % [
			pose_key,
			animation_node._source_oam_slot_start,
			animation_node._source_oam_allocation_order,
		]
		if _last_checked_pose_by_instance.get(instance_key, "") == complete_pose_key:
			continue
		_last_checked_pose_by_instance[instance_key] = complete_pose_key
		if animation_node._last_rendered_pose_key != pose_key:
			_mismatches.append({
				"source_frame": source_frame,
				"animation_id": animation_node.animation_id,
				"reason": "rendered pose key is stale",
			})
			continue
		var frame: Dictionary = pose["frame"]
		var sprites: Array = frame.get("sprites", [])
		var selectors := animation_node._hex_bytes(str(frame.get("chr_selectors_hex", "")))
		var expected := animation_node._render_pose_software(pose, sprites, selectors)
		var actual := animation_node._texture.get_image()
		if expected == null or actual == null or actual.get_data() != expected.get_data():
			_mismatches.append({
				"source_frame": source_frame,
				"animation_id": animation_node.animation_id,
				"reason": "RGBA image differs from software reference",
			})
			continue
		_checked_pose_count += 1
		var animation_id := str(animation_node.animation_id)
		_pose_count_by_animation[animation_id] = int(
			_pose_count_by_animation.get(animation_id, 0)) + 1


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
