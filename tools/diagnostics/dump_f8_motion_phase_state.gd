extends SceneTree
## Print selected F8 source-presenter and cooperative-task states for timing
## diagnosis. This read-only output is not a runtime asset.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CHECKPOINTS := [3596, 3597, 3598, 3599, 3600, 3601, 3602, 3603, 3650, 3651, 3652, 3653, 3891, 3892, 3951, 3952, 3966, 3967, 3968]


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
	var presenter := scene.get_node("SourcePresenter")
	presenter.get_node("FieldScreen").set_rendering_enabled(false)
	var checkpoint_index := 0
	for _frame in range(int(CHECKPOINTS[-1])):
		presenter._advance_source_frame()
		var source_frame := int(presenter.state.get("source_frame", -1))
		if checkpoint_index >= CHECKPOINTS.size() or source_frame != CHECKPOINTS[checkpoint_index]:
			continue
		var f8: Dictionary = presenter.state.get("f8_00_service", {})
		var scheduler := presenter._scheduler as RomCooperativeScheduler
		print(JSON.stringify({
			"source_frame": source_frame,
			"phase": f8.get("phase", ""),
			"pending_handler_phase": presenter._pending_handler_phase,
			"motion_steps": f8.get("motion_steps", -1),
			"ram_0044": presenter.state.get("ram_0044_value", -1),
			"ram_0079": presenter.state.get("ram_0079_value", -1),
			"ram_007c": presenter.state.get("ram_007C_value", -1),
			"scheduler_tick": scheduler.scheduler_tick,
			"slot_0005_delay": scheduler.get_task_delay(5),
			"last_scheduler_yield": presenter.state.get("last_scheduler_yield", {}),
			"paired_fade_steps": f8.get("paired_fade_steps", -1),
			"oam_shadow_cleared": presenter.state.get("oam_shadow_cleared", false),
			"palette": presenter._committed_palette.hex_encode().to_upper(),
			"background_nonzero_bytes": _count_nonzero(presenter._background_01_ppu_memory),
			"cutscene_task_stopped": presenter.state.get("cutscene_task_stopped", false),
			"slice_error": presenter.state.get("slice_error", ""),
		}), "")
		checkpoint_index += 1
	quit(0)


func _count_nonzero(bytes: Dictionary) -> int:
	var count := 0
	for value in bytes.values():
		if value != 0:
			count += 1
	return count
