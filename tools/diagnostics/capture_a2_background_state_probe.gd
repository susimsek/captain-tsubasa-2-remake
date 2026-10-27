extends SceneTree
## Save source-presenter and BG0A renderer state around the A2 visual anomaly.
## Validation-only; this script does not load a ROM or create runtime assets.
## Run with: godot --headless --audio-driver Dummy --path . --script tools/diagnostics/capture_a2_background_state_probe.gd

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OUTPUT_PATH := "res://reference/diagnostics/a2_background_state_probe_20261025.json"
const OUTPUT_IMAGE_ROOT := "res://reference/diagnostics/a2_background_state_probe_20261025"
const TARGET_SOURCE_FRAMES: Array[int] = [
	2374, 2375, 2376, 2377, 2378, 2379, 2380, 2381, 2382, 2383, 2384, 2385,
]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, true)
	var scene_resource := load(MAIN_SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Could not load the main scene.")
		return
	var runtime_scene := scene_resource.instantiate()
	runtime_scene.name = "Main"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(runtime_scene)
	await process_frame

	# The command-line Dummy driver keeps this state replay silent. Stop the
	# runtime WAV too, so invoking the script without that flag stays quiet.
	var opening_audio: Node = runtime_scene.get_node_or_null("OpeningAudio")
	if opening_audio != null:
		if opening_audio is AudioStreamPlayer:
			(opening_audio as AudioStreamPlayer).stop()
		if opening_audio.has_method("set_playback_expected_active"):
			opening_audio.call("set_playback_expected_active", false)
	runtime_scene.propagate_call("set_process", [false])

	var presenter = runtime_scene.get_node_or_null("SourcePresenter")
	var field_screen = presenter.get_node_or_null("FieldScreen") if presenter != null else null
	if presenter == null or field_screen == null:
		push_error("The main scene has no source presenter or field renderer.")
		runtime_scene.queue_free()
		await process_frame
		quit(1)
		return

	var samples: Array[Dictionary] = []
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_IMAGE_ROOT))
	var current_source_frame := int(presenter.state.get("source_frame", 0))
	for target_frame in TARGET_SOURCE_FRAMES:
		# Match the existing targeted capture path: advance source state without
		# rebuilding intermediate textures, then rebuild from live state at each
		# requested frame before sampling the renderer.
		presenter.set_capture_render_updates_suppressed(true)
		field_screen.set_rendering_enabled(false)
		while current_source_frame < target_frame:
			presenter._advance_source_frame()
			current_source_frame = int(presenter.state.get(
				"source_frame", current_source_frame + 1))
		presenter.set_capture_render_updates_suppressed(false)
		field_screen.set_rendering_enabled(true)
		await process_frame
		RenderingServer.force_draw(false)
		await process_frame
	var viewport_texture := get_root().get_texture()
	var viewport_image: Image = viewport_texture.get_image() if viewport_texture != null else null
		if viewport_image != null and viewport_image.get_size() == Vector2i(256, 240):
			var image_path := OUTPUT_IMAGE_ROOT + "/frame_%06d.png" % target_frame
			if viewport_image.save_png(image_path) != OK:
				push_warning("Could not save viewport diagnostic image for frame %d." % target_frame)
		samples.append(_snapshot_frame(presenter, field_screen, target_frame, viewport_image))

	var report := {
		"purpose": "diagnostics-only A2/BG0A state probe with viewport screenshots; no runtime asset output",
		"source_frames": TARGET_SOURCE_FRAMES,
		"renderer_capture_mode": "field renderer disabled only while advancing between requested frames, then rebuilt from current state",
		"samples": samples,
	}
	var output_file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if output_file == null:
		push_error("Could not open the diagnostics JSON output path.")
		runtime_scene.queue_free()
		await process_frame
		quit(1)
		return
	output_file.store_string(JSON.stringify(report, "\t") + "\n")
	output_file.close()
	print("Saved A2/BG0A state probe: %s (%d frames)" % [OUTPUT_PATH, samples.size()])
	runtime_scene.queue_free()
	await process_frame
	quit(0)


func _snapshot_frame(presenter: Node, field_screen: Node, target_frame: int,
		viewport_image: Image) -> Dictionary:
	var state: Dictionary = presenter.state
	var background_palette := _packed_bytes(field_screen.get("_background_palette"))
	var committed_palette := _packed_bytes(presenter.get("_committed_palette"))
	var ppu_memory := _dictionary(field_screen.get("_ppu_memory"))
	var ppu_state := _ppu_memory_summary(ppu_memory)
	var texture_state := _texture_summary(field_screen.get("_texture"))
	var a2_model: Dictionary = state.get("a2_motion_model", {})
	return {
		"requested_source_frame": target_frame,
		"presenter_source_frame": int(state.get("source_frame", -1)),
		"background_id": int(state.get("background_id", -1)),
		"background_profile_ready": bool(state.get("background_profile_ready", false)),
		"field_renderer": {
			"visible": field_screen.visible,
			"visible_in_tree": field_screen.is_visible_in_tree(),
			"rendering_enabled": bool(field_screen.get("_rendering_enabled")),
			"active_background_id": int(field_screen.get("_active_background_id")),
			"scroll_pixels": [int(field_screen.get("_scroll_x")), int(field_screen.get("_scroll_y"))],
			"background_palette_hex": background_palette.hex_encode().to_upper(),
			"background_palette_sha256": _sha256_hex(background_palette),
			"committed_palette_hex": committed_palette.hex_encode().to_upper(),
			"committed_palette_sha256": _sha256_hex(committed_palette),
			"texture": texture_state,
		},
		"presenter_canvas_state": {
			"visible": presenter.visible,
			"visible_in_tree": presenter.is_visible_in_tree(),
			"z_index": presenter.z_index,
			"global_canvas_transform": str(presenter.get_global_transform_with_canvas()),
			"modulate_rgba32": "%08X" % presenter.modulate.to_rgba32(),
			"self_modulate_rgba32": "%08X" % presenter.self_modulate.to_rgba32(),
		},
		"viewport": _image_summary(viewport_image) \
			if viewport_image != null else {"available": false},
		"animation_ids": state.get("animation_ids", []).duplicate(true),
		"a2_motion_snapshot": a2_model.duplicate(true),
		"slice_error": state.get("slice_error", null),
		"field_ppu_state": ppu_state,
	}


func _ppu_memory_summary(ppu_memory: Dictionary) -> Dictionary:
	var addresses: Array = ppu_memory.keys()
	addresses.sort()
	var canonical_bytes := PackedByteArray()
	var nametable_page_counts := [0, 0, 0, 0]
	var first_address := -1
	var last_address := -1
	for address_variant in addresses:
		var address := int(address_variant)
		var value := int(ppu_memory[address_variant]) & 0xFF
		if first_address < 0:
			first_address = address
		last_address = address
		canonical_bytes.append((address >> 8) & 0xFF)
		canonical_bytes.append(address & 0xFF)
		canonical_bytes.append(value)
		if address >= 0x2000 and address < 0x3000:
			var page := int((address - 0x2000) / 0x0400)
			nametable_page_counts[page] += 1
	return {
		"address_count": addresses.size(),
		"first_address": "$%04X" % first_address if first_address >= 0 else null,
		"last_address": "$%04X" % last_address if last_address >= 0 else null,
		"nametable_page_entry_counts": nametable_page_counts,
		"canonical_address_value_sha256": _sha256_hex(canonical_bytes),
	}


func _texture_summary(texture_value: Variant) -> Dictionary:
	if texture_value is Image:
		return _image_summary(texture_value as Image)
	if not texture_value is Texture2D:
		return {"available": false}
	var texture := texture_value as Texture2D
	var image := texture.get_image()
	if image == null:
		return {"available": false}
	return _image_summary(image)


func _image_summary(image: Image) -> Dictionary:
	var pixel_bytes := image.get_data()
	var nontransparent_pixels := 0
	var nonblack_pixels := 0
	if image.get_format() == Image.FORMAT_RGBA8:
		for offset in range(0, pixel_bytes.size(), 4):
			if int(pixel_bytes[offset + 3]) != 0:
				nontransparent_pixels += 1
			if int(pixel_bytes[offset]) != 0 or int(pixel_bytes[offset + 1]) != 0 \
					or int(pixel_bytes[offset + 2]) != 0:
				nonblack_pixels += 1
	return {
		"available": true,
		"size": [image.get_width(), image.get_height()],
		"format": str(image.get_format()),
		"rgba_sha256": _sha256_hex(pixel_bytes),
		"nontransparent_pixels": nontransparent_pixels,
		"nonblack_pixels": nonblack_pixels,
	}


func _packed_bytes(value: Variant) -> PackedByteArray:
	return value if value is PackedByteArray else PackedByteArray()


func _dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK \
			or hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
