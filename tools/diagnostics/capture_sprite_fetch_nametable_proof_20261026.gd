extends SceneTree
## Capture a source-only diagnostic for shared-$2006 sprite reads.
## The ROM presenter supplies the event and live nametable byte. The residual
## CSV only selects validation pixels; FCEUX traces/screens are not inputs here.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SOURCE_EVENTS_PATH := "res://reference/diagnostics/a160_fceux_subframe_trace_20261026/irq_return_phase_source_predictions.csv"
const VALIDATION_TARGETS_PATH := "res://reference/diagnostics/oam_all_residual_trace_20261026/residual_pixel_causal_attribution.csv"
const OUTPUT_PATH := "res://reference/diagnostics/shared_sprite_fetch_override_20261026/live_nametable_pixel_candidates.json"
const FINAL_SOURCE_FRAME := 3649


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load main scene.")
		quit(1)
		return
	var scene := packed.instantiate()
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(scene)
	await process_frame
	scene.propagate_call("set_process", [false])
	var presenter := scene.get_node("SourcePresenter") as ColdStartSourceCommandPresenter
	if presenter == null:
		push_error("Main scene has no source presenter.")
		quit(1)
		return
	presenter.set_capture_render_updates_suppressed(true)
	presenter.field_screen.set_rendering_enabled(false)

	var source_events := _load_source_events()
	var validation_targets := _load_targets()
	var output_frames: Array[Dictionary] = []
	for _frame in FINAL_SOURCE_FRAME:
		presenter._advance_source_frame()
		var source_frame := int(presenter.state.get("source_frame", -1))
		if not validation_targets.has(source_frame):
			continue
		if not source_events.has(source_frame):
			push_error("No ROM-only $2006 event pair at source frame %d." % source_frame)
			quit(1)
			return
		var pair: Dictionary = source_events[source_frame]
		if not pair.has("$A175") or not pair.has("$A178"):
			push_error("Incomplete ROM-only $2006 event pair at source frame %d." % source_frame)
			quit(1)
			return
		var high: Dictionary = pair["$A175"]
		var low: Dictionary = pair["$A178"]
		var temp_addr := ((int(high["value"]) & 0x3F) << 8) | (int(low["value"]) & 0xFF)
		var full_plane1_address := (temp_addr + 8) & 0x3FFF
		var has_explicit_memory_byte := presenter.field_screen._ppu_memory.has(full_plane1_address)
		var nametable_byte := int(presenter.field_screen._ppu_memory.get(full_plane1_address, 0)) & 0xFF
		var pixel_rows: Array[Dictionary] = []
		for target_variant in validation_targets[source_frame]:
			var target: Dictionary = target_variant
			var pixel := _resolve_source_pixel(presenter, target, nametable_byte)
			if pixel.is_empty():
				push_error("Could not resolve source sprite at frame %d pixel (%d,%d), slot %d." % [
					source_frame, int(target["x"]), int(target["y"]), int(target["slot"]),
				])
				quit(1)
				return
			pixel["full_ppu_plane1_address"] = "0x%04X" % full_plane1_address
			pixel["live_nametable_byte"] = "0x%02X" % nametable_byte
			pixel_rows.append(pixel)
		output_frames.append({
			"source_frame": source_frame,
			"rom_only_writes": [
				{"pc": "$A175", "scanline": int(high["predicted_scanline"]), "dot": int(high["predicted_dot"]), "value": "0x%02X" % int(high["value"])},
				{"pc": "$A178", "scanline": int(low["predicted_scanline"]), "dot": int(low["predicted_dot"]), "value": "0x%02X" % int(low["value"])},
			],
			"temp_addr_after_low_write": "0x%04X" % temp_addr,
			"plane1_full_address_after_plus_8": "0x%04X" % full_plane1_address,
			"live_source_nametable_byte": "0x%02X" % nametable_byte,
			"live_ppu_memory_has_explicit_key": has_explicit_memory_byte,
			"background_id": int(presenter.state.get("background_id", -1)),
			"active_field_profile_id": presenter.field_screen._active_background_id,
			"background_01_memory_has_key": presenter._background_01_ppu_memory.has(full_plane1_address),
			"background_01_memory_byte": "0x%02X" % int(presenter._background_01_ppu_memory.get(full_plane1_address, 0)),
			"pixels": pixel_rows,
		})

	var result := {
		"schema": 1,
		"source": "Godot source presenter replay from ROM-derived state; the predicted address indexes the presenter's live PPU memory dictionary with its renderer's zero default. No FCEUX trace or snapshot values feed candidate bytes.",
		"rom_only_prediction_csv": SOURCE_EVENTS_PATH,
		"validation_target_csv": VALIDATION_TARGETS_PATH,
		"frames": output_frames,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write diagnostic JSON: %s" % OUTPUT_PATH)
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("Wrote source-only live nametable proof for %d frames / %d pixels: %s" % [
		output_frames.size(), _count_pixels(output_frames), OUTPUT_PATH,
	])
	scene.queue_free()
	await process_frame
	quit(0)


func _load_source_events() -> Dictionary:
	var file := FileAccess.open(SOURCE_EVENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read ROM-only event rows.")
		return {}
	var lines := file.get_as_text().strip_edges().split("\n")
	if lines.size() < 2:
		return {}
	var headers := lines[0].split(",")
	var frame_i := headers.find("source_frame")
	var pc_i := headers.find("instruction_pc")
	var value_i := headers.find("value")
	var scanline_i := headers.find("predicted_scanline")
	var dot_i := headers.find("predicted_dot")
	var result := {}
	for line_index in range(1, lines.size()):
		var fields := lines[line_index].split(",")
		if fields.size() != headers.size():
			continue
		var frame := fields[frame_i].to_int()
		if frame < 0 or frame > FINAL_SOURCE_FRAME:
			continue
		var pc := fields[pc_i].strip_edges()
		if pc != "$A175" and pc != "$A178":
			continue
		if not result.has(frame):
			result[frame] = {}
		(result[frame] as Dictionary)[pc] = {
			"value": fields[value_i].to_int(),
			"predicted_scanline": fields[scanline_i].to_int(),
			"predicted_dot": fields[dot_i].to_int(),
		}
	return result


func _load_targets() -> Dictionary:
	var file := FileAccess.open(VALIDATION_TARGETS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read residual validation targets.")
		return {}
	var lines := file.get_as_text().strip_edges().split("\n")
	if lines.size() < 2:
		return {}
	var headers := lines[0].split(",")
	var frame_i := headers.find("frame")
	var x_i := headers.find("x")
	var y_i := headers.find("y")
	var slot_i := headers.find("affected_oam_slot")
	var result := {}
	for line_index in range(1, lines.size()):
		var fields := lines[line_index].split(",")
		if fields.size() != headers.size():
			continue
		var frame := fields[frame_i].to_int()
		if not result.has(frame):
			result[frame] = []
		(result[frame] as Array).append({
			"x": fields[x_i].to_int(),
			"y": fields[y_i].to_int(),
			"slot": fields[slot_i].to_int(),
		})
	return result


func _resolve_source_pixel(presenter: ColdStartSourceCommandPresenter,
		target: Dictionary, nametable_byte: int) -> Dictionary:
	var target_x := int(target["x"])
	var target_y := int(target["y"])
	var target_slot := int(target["slot"])
	for node_variant in presenter._animation_nodes + presenter._latched_animation_nodes:
		var node := node_variant as RomSpriteAnimationPrototype
		if not is_instance_valid(node) or not node.visible:
			continue
		var pose: Dictionary = node._resolve_current_pose()
		if pose.is_empty():
			continue
		var frame: Dictionary = pose["frame"]
		var sprites: Array = frame.get("sprites", [])
		var selectors: PackedByteArray = node._hex_bytes(str(frame.get("chr_selectors_hex", "")))
		for sprite_index in sprites.size():
			var sprite_variant: Variant = sprites[sprite_index]
			if not sprite_variant is Dictionary:
				continue
			var sprite: Dictionary = sprite_variant
			var placement: Dictionary = node._sprite_oam_placement(sprite, sprite_index, pose)
			if int(placement.get("slot", -1)) != target_slot:
				continue
			var screen_x := int(placement["x"]) + roundi(node.position.x)
			var screen_y := int(placement["y"]) + roundi(node.position.y)
			var local_x := target_x - screen_x
			var local_y := target_y - screen_y
			if local_x < 0 or local_x >= 8 or local_y < 0 or local_y >= 8:
				continue
			var source_x := 7 - local_x if bool(placement["flip_x"]) else local_x
			var source_y := 7 - local_y if bool(sprite.get("flip_v_bit", false)) else local_y
			var tile := node._hex_byte(str(sprite.get("tile_id", "0x00")))
			var bank_slot := tile >> 6
			if bank_slot >= selectors.size():
				continue
			var bank := int(selectors[bank_slot])
			var pattern_offset := bank * 1024 + (tile & 0x3F) * 16
			if pattern_offset + source_y + 8 >= node._chr.size():
				continue
			var plane0 := int(node._chr[pattern_offset + source_y])
			var normal_plane1 := int(node._chr[pattern_offset + 8 + source_y])
			var bit := 7 - source_x
			var pixel0 := (plane0 >> bit) & 1
			var normal_pixel1 := (normal_plane1 >> bit) & 1
			var replacement_pixel1 := (nametable_byte >> bit) & 1 if nametable_byte >= 0 else -1
			var before_index := pixel0 | (normal_pixel1 << 1)
			var after_index := pixel0 | (replacement_pixel1 << 1) if replacement_pixel1 >= 0 else -1
			var palette_slot := int(placement["subpalette"]) * 4 + after_index
			var candidate_rgb: Variant = null
			if after_index > 0:
				var color: Color = node._color_for_palette_slot(palette_slot, after_index)
				candidate_rgb = [roundi(color.r * 255.0), roundi(color.g * 255.0), roundi(color.b * 255.0)]
			var visibility: Variant = node._shared_oam_scanline_visibility.get(target_slot)
			var row_visible := true
			if visibility is Dictionary:
				var visible_rows: PackedByteArray = visibility.get("rows", PackedByteArray())
				var local_oam_row := int(placement["y"]) + local_y
				row_visible = local_oam_row >= 0 and local_oam_row < visible_rows.size() and visible_rows[local_oam_row] != 0
			return {
				"screen_position": [target_x, target_y],
				"oam_slot": target_slot,
				"animation_id": node.animation_id,
				"frame_cpu_address": str(pose.get("frame_address", "")),
				"sprite_index": sprite_index,
				"sprite_tile": "0x%02X" % tile,
				"source_chr_bank": bank,
				"source_chr_plane0_byte": "0x%02X" % plane0,
				"source_chr_plane1_normal_byte": "0x%02X" % normal_plane1,
				"source_plane1_replacement_byte": "0x%02X" % (nametable_byte & 0xFF) if nametable_byte >= 0 else "unavailable",
				"sprite_local_xy": [local_x, local_y],
				"tile_source_xy": [source_x, source_y],
				"pixel_bit": bit,
				"pattern_pixel_index_before_after": [before_index, after_index],
				"replacement_sprite_rgb": candidate_rgb,
				"shared_oam_row_visible": row_visible,
			}
	return {}


func _count_pixels(frames: Array[Dictionary]) -> int:
	var count := 0
	for frame in frames:
		count += (frame.get("pixels", []) as Array).size()
	return count
