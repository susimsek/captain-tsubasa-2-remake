extends SceneTree
## Diagnostic composition check for the ROM-derived first-menu panel and actor
## presenter. Trace values below are validation fixtures only; production gets
## actor fields from the decoded route state and never opens these snapshots.

const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")
const RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const PLAYER_STATE_PROVIDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd")
const RNG_SCHEDULE := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const ENDPOINT_RAM_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/cpu_ram_0000_07ff_frame_008953.bin"
const ENDPOINT_PPU_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/ppu_memory_frame_008953.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(256, 224)
	var replay := RNG_REPLAY_SCRIPT.new() as RomKickoffRngSourceReplay
	if not replay.configure(RNG_SCHEDULE, INPUT_SHA256) \
			or not replay.advance_to_source_frame(replay.receiver_source_frame):
		_fail("The ROM-derived receiver replay could not reach its audited route event.")
		return
	var provider := PLAYER_STATE_PROVIDER_SCRIPT.new() as RomFreshKickoffMatchStateProvider
	if not provider.configure_from_receiver_replay(replay):
		_fail("The ROM-derived player provider failed: " + provider.error_message)
		return
	for _iteration in 11:
		provider.advance_field_loop_iteration()
	var player_state := provider.get_controlled_player_state()
	if player_state == null or player_state.player_id != 0x08 or player_state.current_energy != 397:
		_fail("The audited route did not produce its expected live player state.")
		return

	var visuals := VISUALS_SCENE.instantiate() as KickoffCutsceneVisuals
	root.add_child(visuals)
	await process_frame
	visuals.screen.set_force_software_renderer_diagnostics(true)
	# `$0517/$0538/$0540/$0541` values are copied only into this diagnostic test
	# fixture from the retained frame-8953 trace. The running route must calculate
	# each field from source logic before it calls this API.
	var trace_validation_context := {
		"kind": "caller_owned_decoded_game_logic",
		"label": "frame-8953 muted FCEUX validation fixture; test-only",
		"mirror_mode": 0x40,
		"scroll_x": 0,
		"clip_y_min": 0,
		"clip_y_max": 0xFF,
	}
	if not visuals.present_first_action_menu(player_state, trace_validation_context):
		_fail("The ROM-derived menu panel could not be composed: " + str(visuals.presentation_gaps))
		return
	if not visuals.action_menu_complete:
		_fail("The first-action panel has unresolved dynamic text rows.")
		return
	if not bool(visuals.first_command_actor_status.get("ok", false)):
		_fail("The source actor presenter was not added to the screen: " + str(visuals.first_command_actor_status))
		return
	var actor_presenter := visuals._first_command_actor_presenter
	if actor_presenter == null or int(visuals.first_command_actor_status.get("sprite_count", -1)) != 41:
		_fail("The ROM actor layer did not compose the 41-sprite endpoint pose.")
		return
	var endpoint_ram := FileAccess.get_file_as_bytes(ENDPOINT_RAM_PATH)
	var endpoint_ppu := FileAccess.get_file_as_bytes(ENDPOINT_PPU_PATH)
	if endpoint_ram.size() < 0x2A4 or endpoint_ppu.size() < 0x3F20:
		_fail("The endpoint OAM/palette validation snapshots are missing or truncated.")
		return
	var expected_oam := endpoint_ram.slice(0x200, 0x2A4)
	var actual_oam: PackedByteArray = actor_presenter.last_oam_bytes.slice(0, 0xA4)
	if actual_oam != expected_oam:
		_fail("The composed source actor pose differs from the 41 endpoint OAM entries.")
		return
	var expected_palette := endpoint_ppu.slice(0x3F10, 0x3F20)
	if actor_presenter.last_sprite_palette != expected_palette:
		_fail("The composed source actor palette differs from the endpoint palette bytes.")
		return
	print("PASS: first-action panel and source-derived actor node compose in the gameplay visual scene; panel dynamics are complete, and ROM actor source bytes produce 41 sprites with OAM 164/164 and palette 16/16 endpoint-byte matches.")
	print("LIMIT: actor shared-state arguments in this diagnostic come from the retained trace fixture. This does not prove the route produces those values, resolve sprite/background priority, or establish full-screen frame parity.")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
