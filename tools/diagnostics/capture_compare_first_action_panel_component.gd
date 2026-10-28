extends SceneTree
## Diagnostic-only capture for the ROM-derived first-action panel component.
## The retained FCEUX screenshot is a comparison reference, never a runtime asset.

const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")
const RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const RNG_SCHEDULE := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const AUDITED_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const REFERENCE_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/screens/route_frame_008953.gd"
const POST_TITLE_INPUTS_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const POST_TITLE_INPUTS_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const REFERENCE_SHA256 := "cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559"
const REFERENCE_WIDTH := 256
const REFERENCE_HEIGHT := 240
const REFERENCE_HEADER_BYTES := 11
const VISIBLE_CROP_TOP := 8
# Descriptor $03 occupies nametable columns 18–29 and rows 18–27.
const PANEL_REFERENCE_RECT := Rect2i(144, 136, 96, 80)
const GODOT_CAPTURE_PATH := "/tmp/ct2_godot_first_action_panel_component_8953.png"
const DIFF_CAPTURE_PATH := "/tmp/ct2_first_action_panel_component_diff_8953.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var input_bytes := FileAccess.get_file_as_bytes(POST_TITLE_INPUTS_PATH)
	if input_bytes.is_empty() or _sha256(input_bytes) != POST_TITLE_INPUTS_SHA256:
		_fail("The post-title route input CSV is missing or its hash changed.")
		return
	# Match the project's logical visible viewport despite the desktop window's
	# 4x size override. In the normal renderer root.size controls capture pixels.
	root.size = Vector2i(REFERENCE_WIDTH, 224)
	var replay := RNG_REPLAY_SCRIPT.new() as RomKickoffRngSourceReplay
	if not replay.configure(RNG_SCHEDULE, AUDITED_INPUT_SHA256):
		_fail("ROM-derived receiver replay failed to configure: " + replay.error_message)
		return
	if not replay.advance_to_source_frame(replay.receiver_source_frame):
		_fail("ROM-derived receiver replay failed to reach its audited event: " + replay.error_message)
		return
	var provider := PLAYER_STATE_PROVIDER_SCRIPT.new() as RomFreshKickoffMatchStateProvider
	if not provider.configure_from_receiver_replay(replay):
		_fail("Fresh-match ROM player provider failed: " + provider.error_message)
		return
	var stamina_event_seen := false
	for iteration in 11:
		var event_seen := provider.advance_field_loop_iteration()
		if iteration < 10 and event_seen:
			_fail("Player stamina updated before the ROM-derived eleventh field iteration.")
			return
		if iteration == 10:
			stamina_event_seen = event_seen
	if not stamina_event_seen:
		_fail("The expected ROM-derived stamina event was not produced.")
		return
	var player_state: FirstActionMenuMatchPlayerState = provider.get_controlled_player_state()
	if player_state == null or player_state.current_energy != 397:
		_fail("The provider did not produce the expected post-timer player state.")
		return

	# Match the live project's 256x224 viewport crop: its 240-line PPU content is
	# shifted upward by eight rows. This parent is only a diagnostic canvas root.
	var canvas_root := Node2D.new()
	canvas_root.name = "PanelComponentCaptureRoot"
	canvas_root.position.y = -VISIBLE_CROP_TOP
	root.add_child(canvas_root)
	var visuals := VISUALS_SCENE.instantiate() as KickoffCutsceneVisuals
	canvas_root.add_child(visuals)
	await process_frame
	# Use the renderer's explicit diagnostic software path so the full viewport
	# readback observes the same PPU memory immediately, without nested GPU texture
	# presentation lag in this short-lived capture process.
	visuals.screen.set_force_software_renderer_diagnostics(true)
	if not visuals.present_first_action_menu(player_state):
		_fail("ROM-derived first-action panel renderer failed: " + str(visuals.presentation_gaps))
		return
	if not visuals.action_menu_complete or not visuals.action_menu_missing_dynamic.is_empty():
		_fail("The ROM-derived panel has unresolved dynamic rows: " + str(visuals.action_menu_missing_dynamic))
		return
	if visuals._action_menu_panel == null or visuals._action_menu_panel.selected_action_id != -1:
		_fail("The panel did not start in the unselected action state.")
		return
	# Isolate the panel component at its descriptor PPU coordinates. The field
	# candidate's gameplay scroll/raster is a separate unresolved route input and
	# would move this nametable region out of the visible crop.
	visuals.screen.set_source_raster_events([])
	visuals.screen.set_scroll_pixels(0, 0)
	# The fixed-bank IRQ reset at $C87C-$C8DF writes MMC3 R0=$00 and R1=$02
	# after selecting the lower gameplay viewport. This isolated panel crop is
	# evaluated in that ROM-derived post-IRQ state; its exact within-frame
	# transition remains unresolved and is not asserted by this component check.
	if not visuals.screen.set_source_mmc3_chr_writes([0x00, 0x02], []):
		_fail("Could not apply the byte-verified post-IRQ R0/R1 selectors.")
		return
	print("PPU panel bytes: $2252=$%02X, $2372=$%02X; renderer scroll=%s." % [
		visuals.screen.read_nametable_ppu_byte(0x2252),
		visuals.screen.read_nametable_ppu_byte(0x2372),
		str(visuals.screen.get_scroll_pixels())])

	# Let the renderer and CanvasItem draw command advance, then capture the
	# complete project viewport rather than only its background Image.
	await process_frame
	await process_frame
	var viewport_image := root.get_texture().get_image()
	if viewport_image == null or viewport_image.is_empty():
		_fail("Could not capture the Godot root viewport.")
		return
	if viewport_image.get_width() != REFERENCE_WIDTH or viewport_image.get_height() != 224:
		_fail("Expected the full 256x224 Godot project viewport; got %dx%d." % [
			viewport_image.get_width(), viewport_image.get_height()])
		return
	var capture_error := viewport_image.save_png(GODOT_CAPTURE_PATH)
	if capture_error != OK:
		_fail("Could not save the full Godot viewport capture.")
		return

	var reference := FileAccess.get_file_as_bytes(REFERENCE_PATH)
	if reference.size() != REFERENCE_HEADER_BYTES + REFERENCE_WIDTH * REFERENCE_HEIGHT * 4:
		_fail("Frame-8953 FCEUX screenshot has an unexpected raw GD size.")
		return
	if _sha256(reference) != REFERENCE_SHA256:
		_fail("The retained frame-8953 FCEUX screenshot hash changed.")
		return
	var reference_width := (int(reference[2]) << 8) | int(reference[3])
	var reference_height := (int(reference[4]) << 8) | int(reference[5])
	if reference_width != REFERENCE_WIDTH or reference_height != REFERENCE_HEIGHT:
		_fail("Frame-8953 FCEUX raw screenshot is not 256x240.")
		return

	var diff_image := Image.create(PANEL_REFERENCE_RECT.size.x, PANEL_REFERENCE_RECT.size.y, false, Image.FORMAT_RGBA8)
	var exact_pixels := 0
	var total_absolute_channel_error := 0
	var differing_pixels := 0
	for local_y in PANEL_REFERENCE_RECT.size.y:
		var reference_y := PANEL_REFERENCE_RECT.position.y + local_y
		var godot_y := reference_y - VISIBLE_CROP_TOP
		for local_x in PANEL_REFERENCE_RECT.size.x:
			var reference_x := PANEL_REFERENCE_RECT.position.x + local_x
			var source_index := REFERENCE_HEADER_BYTES + (reference_y * REFERENCE_WIDTH + reference_x) * 4
			# FCEUX GD stores A,R,G,B. Alpha is ignored for visible RGB parity.
			var reference_r := int(reference[source_index + 1])
			var reference_g := int(reference[source_index + 2])
			var reference_b := int(reference[source_index + 3])
			var godot_color := viewport_image.get_pixel(reference_x, godot_y)
			var godot_r := roundi(godot_color.r * 255.0)
			var godot_g := roundi(godot_color.g * 255.0)
			var godot_b := roundi(godot_color.b * 255.0)
			var matches := godot_r == reference_r and godot_g == reference_g and godot_b == reference_b
			if matches:
				exact_pixels += 1
				diff_image.set_pixel(local_x, local_y, Color.BLACK)
			else:
				differing_pixels += 1
				diff_image.set_pixel(local_x, local_y, Color.RED)
			total_absolute_channel_error += abs(godot_r - reference_r)
			total_absolute_channel_error += abs(godot_g - reference_g)
			total_absolute_channel_error += abs(godot_b - reference_b)

	var diff_error := diff_image.save_png(DIFF_CAPTURE_PATH)
	if diff_error != OK:
		_fail("Could not save the panel-region diagnostic diff.")
		return
	var total_pixels := PANEL_REFERENCE_RECT.size.x * PANEL_REFERENCE_RECT.size.y
	var exact_percent := 100.0 * float(exact_pixels) / float(total_pixels)
	var mean_channel_error := float(total_absolute_channel_error) / float(total_pixels * 3)
	var best_registration_offset := 0
	var best_registration_exact_pixels := -1
	for registration_offset in range(-8, 9):
		var registered_exact_pixels := _count_registered_panel_matches(
			viewport_image, reference, registration_offset)
		if registered_exact_pixels > best_registration_exact_pixels:
			best_registration_exact_pixels = registered_exact_pixels
			best_registration_offset = registration_offset
	print("Panel component provider: ROM-derived receiver slot %d, player ID $%02X, energy %d; source timer event count %d." % [
		provider.receiver_slot, player_state.player_id, player_state.current_energy, provider.stamina_update_count])
	print("Full Godot viewport capture: %dx%d at %s." % [viewport_image.get_width(), viewport_image.get_height(), GODOT_CAPTURE_PATH])
	print("Frame-8953 panel RGB comparison: reference rect x=%d..%d/y=%d..%d (%dx%d; %d pixels); Godot viewport rect x=%d..%d/y=%d..%d." % [
		PANEL_REFERENCE_RECT.position.x, PANEL_REFERENCE_RECT.end.x - 1,
		PANEL_REFERENCE_RECT.position.y, PANEL_REFERENCE_RECT.end.y - 1,
		PANEL_REFERENCE_RECT.size.x, PANEL_REFERENCE_RECT.size.y, total_pixels,
		PANEL_REFERENCE_RECT.position.x, PANEL_REFERENCE_RECT.end.x - 1,
		PANEL_REFERENCE_RECT.position.y - VISIBLE_CROP_TOP, PANEL_REFERENCE_RECT.end.y - VISIBLE_CROP_TOP - 1])
	print("RGB result: %d/%d exact pixels (%.3f%%), %d differ; mean absolute channel error %.4f; crop diff %s." % [
		exact_pixels, total_pixels, exact_percent, differing_pixels, mean_channel_error, DIFF_CAPTURE_PATH])
	print("Validation-only vertical registration search (-8..+8 Godot rows): best %+d rows, %d/%d exact pixels (%.3f%%). This does not alter runtime positioning." % [
		best_registration_offset, best_registration_exact_pixels, total_pixels,
		100.0 * float(best_registration_exact_pixels) / float(total_pixels)])
	print("LIMIT: Panel-component comparison only. Descriptor-$03 is isolated at scroll (0,0) for the component check; this does not test B-to-panel route/task integration, actor animation, or full field-screen parity. Frame-8953 screenshot data is comparison-only.")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _count_registered_panel_matches(viewport_image: Image, reference: PackedByteArray,
		registration_offset: int) -> int:
	var exact_pixels := 0
	for local_y in PANEL_REFERENCE_RECT.size.y:
		var reference_y := PANEL_REFERENCE_RECT.position.y + local_y
		var godot_y := reference_y - VISIBLE_CROP_TOP + registration_offset
		if godot_y < 0 or godot_y >= viewport_image.get_height():
			continue
		for local_x in PANEL_REFERENCE_RECT.size.x:
			var reference_x := PANEL_REFERENCE_RECT.position.x + local_x
			var source_index := REFERENCE_HEADER_BYTES + (reference_y * REFERENCE_WIDTH + reference_x) * 4
			var reference_r := int(reference[source_index + 1])
			var reference_g := int(reference[source_index + 2])
			var reference_b := int(reference[source_index + 3])
			var godot_color := viewport_image.get_pixel(reference_x, godot_y)
			if roundi(godot_color.r * 255.0) == reference_r \
					and roundi(godot_color.g * 255.0) == reference_g \
					and roundi(godot_color.b * 255.0) == reference_b:
				exact_pixels += 1
	return exact_pixels
