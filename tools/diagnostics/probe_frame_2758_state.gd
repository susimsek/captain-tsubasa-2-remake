extends SceneTree
## Read-only scene-state probe for the source-frame-2758 mismatch.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TARGET_FRAME := 2758


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, true)
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load main scene")
		quit(1)
		return
	var scene := packed.instantiate()
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(scene)
	await process_frame
	var audio: Node = scene.get_node_or_null("OpeningAudio")
	if audio is AudioStreamPlayer:
		(audio as AudioStreamPlayer).stop()
	var expected := scene.get_node_or_null("SourcePresenter")
	if expected == null:
		push_error("Source presenter missing")
		quit(1)
		return
	scene.propagate_call("set_process", [false])
	var field = expected.get_node("FieldScreen")
	field.set_rendering_enabled(false)
	while int(expected.state.get("source_frame", 0)) < TARGET_FRAME:
		expected._advance_source_frame()
	var animations: Array[Dictionary] = []
	for animation in expected._animation_nodes:
		animations.append({
			"id": animation.animation_id,
			"visible": animation.visible,
			"position": [animation.position.x, animation.position.y],
			"origin_x_motion_offset": animation.get("_origin_x_motion_offset"),
			"manual_source_tick": animation.get("_manual_source_tick"),
			"z_index": animation.z_index,
		})
	var state: Dictionary = expected.state
	var report := {
		"source_frame": int(state.get("source_frame", -1)),
		"background_id": state.get("background_id", null),
		"animation_ids": state.get("animation_ids", []),
		"animation_set_source_frame": state.get("animation_set_source_frame", null),
		"source_frame_of_last_dispatch": state.get("source_frame_of_last_dispatch", null),
		"cutscene_cpu_pointer": state.get("cutscene_cpu_pointer", null),
		"last_rom_bytes": state.get("last_rom_bytes", null),
		"background_profile_ready": state.get("background_profile_ready", null),
		"field_screen": {
			"visible": field.visible,
			"active_background_id": field.get("_active_background_id"),
			"scroll": [field.get("_scroll_x"), field.get("_scroll_y")],
			"chr_banks": field.get("_chr_banks"),
			"lower_chr_banks": field.get("_lower_chr_banks"),
			"raster_split_scanline": field.get("_raster_split_scanline"),
			"source_mmc3_chr_writes_active": field.get("_source_mmc3_chr_writes_active"),
			"source_mmc3_initial_2k_selectors": field.get("_source_mmc3_initial_2k_selectors"),
			"source_mmc3_chr_writes": field.get("_source_mmc3_chr_writes"),
			"source_raster_events": field.get("_source_raster_events"),
			"ppu_address_count": field.get("_ppu_memory").size(),
		},
		"committed_palette_hex": expected.get("_committed_palette").hex_encode().to_upper(),
		"animations": animations,
		"slice_error": state.get("slice_error", null),
	}
	print(JSON.stringify(report, "\t"))
	scene.queue_free()
	await process_frame
	quit(0)
