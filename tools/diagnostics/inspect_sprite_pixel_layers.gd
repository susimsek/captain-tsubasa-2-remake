extends SceneTree

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const TARGET_FRAME := 3560
const PIXELS := [Vector2i(134, 129), Vector2i(135, 129), Vector2i(136, 129), Vector2i(137, 129), Vector2i(138, 129)]


func _initialize() -> void:
	call_deferred("_inspect")


func _inspect() -> void:
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	presenter.set_render_updates_suppressed(true)
	presenter.field_screen.set_rendering_enabled(false)
	while int(presenter.state.get("source_frame", 0)) < TARGET_FRAME - 1:
		presenter._advance_source_frame()
	presenter.set_render_updates_suppressed(false)
	presenter.field_screen.set_rendering_enabled(true)
	presenter._advance_source_frame()
	await process_frame
	var field_image: Image = presenter.field_screen._texture.get_image()
	for point in PIXELS:
		var layers: Array[Dictionary] = []
		for node in presenter._animation_nodes + presenter._latched_animation_nodes:
			if not is_instance_valid(node) or not node.visible or node._texture == null:
				continue
			var image: Image = node._texture.get_image()
			var local_pixel: Vector2i = point - Vector2i(roundi(node.position.x), roundi(node.position.y))
			if local_pixel.x < 0 or local_pixel.x >= image.get_width() \
					or local_pixel.y < 0 or local_pixel.y >= image.get_height():
				continue
			var color := image.get_pixel(local_pixel.x, local_pixel.y)
			if color.a > 0.0:
				layers.append({"animation": node.animation_id, "pixel": color.to_rgba32(),
					"local": local_pixel, "z": node.z_index})
		print(JSON.stringify({
			"screen": point,
			"background_rgb": field_image.get_pixel(point.x, point.y).to_rgba32(),
			"priority_behind": presenter.state.get("oam_priority_display_latched", false),
			"layers": layers,
		}))
	presenter.queue_free()
	await process_frame
	quit(0)
