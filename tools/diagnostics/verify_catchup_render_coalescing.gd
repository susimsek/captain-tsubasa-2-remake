extends SceneTree

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const PRE_CATCHUP_FRAME := 3590
const FINAL_SOURCE_FRAME := 3601


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	if OS.get_cmdline_user_args().has("--hide-window"):
		get_root().get_window().position = Vector2i(-10000, -10000)
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	RenderingServer.set_default_clear_color(Color.BLACK)
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the cold-start presenter.")
		return
	var sequential_hash := await _capture_final_hash(packed, false)
	if sequential_hash.is_empty():
		_fail("Could not capture the sequential-render control.")
		return
	var coalesced_hash := await _capture_final_hash(packed, true)
	if coalesced_hash.is_empty():
		_fail("Could not capture the coalesced-render candidate.")
		return
	print("source_frames=%d-%d sequential_sha256=%s coalesced_sha256=%s equal=%s" % [
		PRE_CATCHUP_FRAME + 1, FINAL_SOURCE_FRAME,
		sequential_hash, coalesced_hash, str(sequential_hash == coalesced_hash),
	])
	quit(0 if sequential_hash == coalesced_hash else 1)


func _capture_final_hash(packed: PackedScene, coalesce_frames: bool) -> String:
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	presenter.set_render_updates_suppressed(true)
	presenter.field_screen.set_rendering_enabled(false)
	while int(presenter.state.get("source_frame", 0)) < PRE_CATCHUP_FRAME:
		presenter._advance_source_frame()
	var measured_started_usec := Time.get_ticks_usec()
	if not coalesce_frames:
		presenter.set_render_updates_suppressed(false)
		presenter.field_screen.set_rendering_enabled(true)
		while int(presenter.state.get("source_frame", 0)) < FINAL_SOURCE_FRAME:
			presenter._advance_source_frame()
	else:
		while int(presenter.state.get("source_frame", 0)) < FINAL_SOURCE_FRAME:
			presenter._advance_source_frame()
		presenter.set_render_updates_suppressed(false)
		presenter.field_screen.set_rendering_enabled(true)
	var measured_elapsed_usec := Time.get_ticks_usec() - measured_started_usec
	print("render_mode=%s measured_source_frames=%d elapsed_ms=%.3f" % [
		"coalesced" if coalesce_frames else "sequential",
		FINAL_SOURCE_FRAME - PRE_CATCHUP_FRAME, float(measured_elapsed_usec) / 1000.0,
	])
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	var image_hash := ""
	if image != null and image.get_size() == Vector2i(256, 240):
		image_hash = _sha256_hex(image.get_data())
	get_root().remove_child(presenter)
	presenter.free()
	await process_frame
	return image_hash


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
