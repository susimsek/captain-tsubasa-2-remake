extends SceneTree
## Read-only live Godot dump for the two remaining sprite-composition pixels.

const SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const TARGETS := [{"frame": 3525, "point": Vector2i(136, 129)}, {"frame": 3635, "point": Vector2i(134, 149)}]

func _initialize() -> void:
	call_deferred("_inspect")

func _inspect() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load presenter scene.")
		quit(1)
		return
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	get_root().add_child(presenter)
	await process_frame
	presenter.propagate_call("set_process", [false])
	presenter.set_capture_render_updates_suppressed(true)
	presenter.field_screen.set_rendering_enabled(false)
	var target_index := 0
	while target_index < TARGETS.size():
		var target: Dictionary = TARGETS[target_index]
		while int(presenter.state.get("source_frame", 0)) < int(target["frame"]):
			presenter._advance_source_frame()
			if bool(presenter.state.get("slice_failed", false)):
				push_error("Presenter failed at source frame %d." % presenter.state.get("source_frame", -1))
				quit(1)
				return
		presenter.set_capture_render_updates_suppressed(false)
		presenter.field_screen.set_rendering_enabled(true)
		await process_frame
		var point: Vector2i = target["point"]
		var field_image: Image = presenter.field_screen._texture.get_image()
		var report := {
			"source_frame": target["frame"],
			"point": [point.x, point.y],
			"background_id": presenter.state.get("background_id", -1),
			"animation_ids": presenter.state.get("animation_ids", []),
			"oam_y_shift_pixels": presenter.state.get("oam_y_shift_pixels", 0),
			"oam_priority_behind_background": presenter.state.get("oam_priority_display_latched", false),
			"field_bg_chr_banks": presenter.field_screen._chr_banks.duplicate(),
			"field_bg_lower_chr_banks": presenter.field_screen._lower_chr_banks.duplicate(),
			"field_mmc3_event_writes": presenter.field_screen._source_mmc3_chr_writes.duplicate(true),
			"field_rgb": _rgba(field_image.get_pixel(point.x, point.y)),
			"sprite_nodes": [],
		}
		for node in presenter._animation_nodes + presenter._latched_animation_nodes:
			if not is_instance_valid(node) or not node.visible:
				continue
			var pose: Dictionary = node._resolve_current_pose()
			if pose.is_empty():
				continue
			var frame: Dictionary = pose["frame"]
			var selectors: PackedByteArray = node._hex_bytes(str(frame.get("chr_selectors_hex", "")))
			var node_row := {
				"animation_id": node.animation_id,
				"frame_address": pose.get("frame_address", ""),
				"tick": node._manual_source_tick,
				"node_position": [node.position.x, node.position.y],
				"oam_slot_start": node._source_oam_slot_start,
				"allocation_order": node.source_oam_allocation_order(),
				"chr_selectors_hex": selectors.hex_encode().to_upper(),
				"frame_sprites": [],
				"texture_rgba_at_screen_point": null,
			}
			if node._texture != null:
				var sprite_image: Image = node._texture.get_image()
				var image_point := point - Vector2i(roundi(node.position.x), roundi(node.position.y))
				if image_point.x >= 0 and image_point.x < sprite_image.get_width() and image_point.y >= 0 and image_point.y < sprite_image.get_height():
					node_row["texture_rgba_at_screen_point"] = _rgba(sprite_image.get_pixel(image_point.x, image_point.y))
			var sprites: Array = frame.get("sprites", [])
			for sprite_index in sprites.size():
				var sprite_variant: Variant = sprites[sprite_index]
				if not sprite_variant is Dictionary:
					continue
				var sprite: Dictionary = sprite_variant
				var placement: Dictionary = node._sprite_oam_placement(sprite, sprite_index, pose)
				var sprite_x := int(placement["x"])
				var sprite_y := int(placement["y"])
				var global_x := sprite_x + roundi(node.position.x)
				var global_y := sprite_y + roundi(node.position.y)
				if point.x < global_x or point.x >= global_x + 8 or point.y < global_y or point.y >= global_y + 8:
					continue
				var tile := node._hex_byte(str(sprite.get("tile_id", "0x00")))
				var bank_slot := tile >> 6
				var selected_bank := int(selectors[bank_slot])
				var source_x := point.x - global_x
				var source_y := point.y - global_y
				if bool(placement["flip_x"]):
					source_x = 7 - source_x
				if bool(sprite.get("flip_v_bit", false)):
					source_y = 7 - source_y
				var pattern_offset := selected_bank * 1024 + (tile & 0x3F) * 16
				var low_plane := int(node._chr[pattern_offset + source_y])
				var high_plane := int(node._chr[pattern_offset + 8 + source_y])
				var bit := 7 - source_x
				var pixel_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
				var palette_slot := (int(placement["subpalette"]) * 4 + pixel_index)
				var palette_color := node._color_for_palette_slot(palette_slot, pixel_index)
				var slot := int(placement["slot"])
				var visibility: Variant = node._shared_oam_scanline_visibility.get(slot)
				var scanline_visible := true
				if visibility is Dictionary:
					var visible_rows: PackedByteArray = visibility.get("rows", PackedByteArray())
					scanline_visible = int(visibility.get("sprite_index", -1)) == sprite_index and sprite_y < visible_rows.size() and visible_rows[sprite_y] != 0
				(node_row["frame_sprites"] as Array).append({
					"sprite_index": sprite_index,
					"oam_slot": slot,
					"tile": "$%02X" % tile,
					"oam_xy": [sprite_x, sprite_y],
					"global_xy": [global_x, global_y],
					"attr_palette_low_bits": placement["subpalette"],
					"chr_bank_slot": bank_slot,
					"static_chr_bank": selected_bank,
					"source_xy": [source_x, source_y],
					"low_plane_byte": "$%02X" % low_plane,
					"high_plane_byte": "$%02X" % high_plane,
					"pixel_index": pixel_index,
					"palette_slot": palette_slot,
					"palette_rgba": _rgba(palette_color),
					"visible_by_shared_scanline_model": scanline_visible,
				})
			(report["sprite_nodes"] as Array).append(node_row)
		print(JSON.stringify(report))
		presenter.field_screen.set_rendering_enabled(false)
		target_index += 1
	presenter.queue_free()
	await process_frame
	quit(0)

func _rgba(color: Color) -> Array[int]:
	return [roundi(color.r * 255.0), roundi(color.g * 255.0), roundi(color.b * 255.0), roundi(color.a * 255.0)]
