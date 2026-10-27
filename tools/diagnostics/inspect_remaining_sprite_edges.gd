extends SceneTree
## Read-only inspection of the remaining 45-pixel sprite-overlap checkpoints.

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const CHECKPOINTS := [
	3523, 3525, 3527, 3536, 3547, 3551, 3555, 3560, 3561,
	3564, 3571, 3575, 3576, 3583, 3594, 3635, 3645, 3649,
]


func _initialize() -> void:
	call_deferred("_inspect")


func _inspect() -> void:
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load the cold-start presenter.")
		quit(1)
		return
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	presenter.set_render_updates_suppressed(true)
	presenter.field_screen.set_rendering_enabled(false)
	var checkpoint_index := 0
	var target_frame := int(CHECKPOINTS.back())
	while int(presenter.state.get("source_frame", 0)) < target_frame:
		presenter._advance_source_frame()
		var frame := int(presenter.state.get("source_frame", -1))
		if checkpoint_index >= CHECKPOINTS.size() or frame != CHECKPOINTS[checkpoint_index]:
			continue
		var row_slots: Array[int] = []
		var all_visible_entries: Array[Dictionary] = []
		for animation_node in presenter._animation_nodes + presenter._latched_animation_nodes:
			if not is_instance_valid(animation_node) or not animation_node.visible:
				continue
			for entry in animation_node.source_oam_evaluation_entries():
				var first_row := int(entry["first_visible_row"])
				if first_row <= 129 and first_row + 8 > 129:
					all_visible_entries.append({
						"slot": int(entry["slot"]),
						"sprite": int(entry["sprite_index"]),
						"animation": animation_node.animation_id,
						"first_row": first_row,
						"owner": int(entry["owner_instance_id"]),
					})
		all_visible_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["slot"]) < int(b["slot"]))
		for index in mini(8, all_visible_entries.size()):
			row_slots.append(int(all_visible_entries[index]["slot"]))
		var nodes: Array[Dictionary] = []
		for collection_name in ["active", "latched"]:
			var collection: Array = presenter._animation_nodes if collection_name == "active" \
					else presenter._latched_animation_nodes
			for animation_node in collection:
				if is_instance_valid(animation_node):
					var pose: Dictionary = animation_node._resolve_current_pose()
					nodes.append({
						"set": collection_name,
						"id": animation_node.animation_id,
						"visible": animation_node.visible,
						"order": animation_node.source_oam_allocation_order(),
						"slot_start": animation_node._source_oam_slot_start,
						"tick": animation_node._manual_source_tick,
						"beats": animation_node._beats.size(),
						"has_pose": not pose.is_empty(),
						"pose_sprites": pose.get("frame", {}).get("sprites", []).size(),
						"entries": animation_node.source_oam_evaluation_entries().size(),
						"last_rendered": animation_node._last_rendered_pose_key,
					})
		print(JSON.stringify({
			"frame": frame,
			"background_id": presenter.state.get("background_id", -1),
			"animation_ids": presenter.state.get("animation_ids", []),
			"nodes": nodes,
			"row_129_visible_entries": all_visible_entries,
			"first_8_slots_if_latched_nodes_count": row_slots,
			"currently_modeled_priority_behind": presenter.state.get(
				"oam_priority_display_latched", false),
		}))
		checkpoint_index += 1
	presenter.queue_free()
	await process_frame
	quit(0)
