extends SceneTree
## Inspect interpreter state at selected source-frame boundaries.
## This is a read-only diagnostic and does not save runtime assets.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CHECKPOINTS := [4207, 4209, 4212, 4213, 4215, 4217, 4218, 4226, 4465, 4466, 4475, 4480, 4481]


func _initialize() -> void:
	call_deferred("_dump")


func _dump() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load the main scene.")
		quit(1)
		return
	var scene := packed.instantiate()
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(scene)
	await process_frame
	scene.propagate_call("set_process", [false])
	var presenter = scene.get_node("SourcePresenter")
	var field_screen = presenter.get_node("FieldScreen")
	var logo_background = presenter.get_node("Background")
	field_screen.set_rendering_enabled(false)
	var checkpoint_index := 0
	var final_frame := int(CHECKPOINTS[-1])
	for _frame in range(final_frame):
		presenter._advance_source_frame()
		var source_frame := int(presenter.state.get("source_frame", -1))
		if checkpoint_index < CHECKPOINTS.size() and source_frame == CHECKPOINTS[checkpoint_index]:
			var state: Dictionary = presenter.state
			var logo_palette_rgb: Array[String] = []
			for animation_node in presenter._animation_nodes:
				if animation_node.animation_id == "0x8D":
					for color in animation_node.sprite_palette_rgb:
						logo_palette_rgb.append("%08X" % color.to_rgba32())
			print(JSON.stringify({
				"source_frame": source_frame,
				"background_id": state.get("background_id", null),
				"animation_ids": state.get("animation_ids", []),
				"animation_set_source_frame": state.get("animation_set_source_frame", null),
				"background_profile_ready": state.get("background_profile_ready", null),
				"background_01_committed_packets": state.get("background_01_committed_packets", null),
				"background_01_queued_packets": state.get("background_01_queued_packets", null),
				"logo_background_visible": logo_background.visible,
				"logo_palette_rgb": logo_palette_rgb,
				"committed_palette_hex": presenter._committed_palette.hex_encode().to_upper(),
				"palette_committed_level": state.get("palette_committed_level", null),
				"palette_staged_level": state.get("palette_staged_level", null),
				"palette_commit_source_frame": state.get("palette_commit_source_frame", null),
				"logo_fade_palette_restore": state.get("logo_fade_palette_restore", {}),
				"fade_up_level": presenter._fade_up_level,
				"ea_clear_applied": state.get("ea_clear_applied", false),
				"field_screen_visible": field_screen.visible,
				"field_screen_profile_id": field_screen._active_background_id,
				"dispatch_count": state.get("dispatch_count", null),
				"last_dispatch_frame": state.get("source_frame_of_last_dispatch", null),
				"last_dispatch_pc": state.get("cutscene_cpu_pointer", null),
				"last_dispatch_bytes": state.get("last_rom_bytes", null),
				"cutscene_task_stopped": state.get("cutscene_task_stopped", null),
				"slice_error": state.get("slice_error", ""),
				"unresolved_command": state.get("unresolved_command", {}),
				"scheduler_tick": state.get("scheduler_tick", null),
				"f5_effect": state.get("f5_00_palette_effect_model", {}),
			}))
			checkpoint_index += 1
	quit(0)
