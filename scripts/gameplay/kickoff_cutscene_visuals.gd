extends Node2D
class_name KickoffCutsceneVisuals
## ROM-data-backed presenter for KICK OFF cutscene command streams.
## The VM supplies verified byte order and scheduler ticks; this node turns
## decoded background records, CHR/palette data, sprite descriptors, and text
## tile bytes into a Godot image. Unsupported palette/raster semantics remain
## explicit rather than being inferred from screenshots.

const SCREEN_SCRIPT := preload("res://scripts/opening/rom_ppu_nametable_screen_renderer.gd")
const BACKGROUND_PACKET_LOADER := preload("res://scripts/opening/rom_background_packet_loader.gd")
const SPRITE_SCRIPT := preload("res://scripts/opening/rom_sprite_animation_prototype.gd")
const INTRO_DATA_ROOT := "res://reference/rom_extract/intro"
const GAMEPLAY_DATA_ROOT := "res://reference/rom_extract/gameplay/backgrounds"
const GAMEPLAY_ANIMATION_TIMING := "res://reference/rom_extract/gameplay/animations/kickoff/animation_timing.json"
const GAMEPLAY_SPRITE_FRAMES := "res://reference/rom_extract/gameplay/animations/kickoff/sprite_frames.json"
const FIRST_ACTION_MENU_SCRIPT := preload("res://scripts/gameplay/first_action_menu_panel.gd")
const FIRST_MATCH_FIELD_SCRIPT := preload("res://scripts/gameplay/first_match_field_candidate_presenter.gd")
const FIRST_COMMAND_ACTOR_SCRIPT := preload("res://scripts/gameplay/first_command_actor_source_presenter.gd")
const MEETING_CURSOR_SCRIPT := preload("res://scripts/gameplay/rom_meeting_menu_cursor.gd")
const TEXT_CURSOR_START := 0x2249
const NAMETABLE_END := 0x2800

@onready var screen: RomPpuNametableScreenRenderer = $Screen
@onready var sprite_layer: Node2D = $Sprites

var active_background_id := -1
var active_background_data_root := ""
var text_cursor_base := TEXT_CURSOR_START
var text_cursor_column := 0
var presentation_gaps: Array[String] = []
var action_menu_complete := false
var action_menu_missing_dynamic: Array[Dictionary] = []
var first_match_field_status: Dictionary = {}
var first_command_actor_status: Dictionary = {"ok": false, "state": "not_presented"}

var _ppu_memory: Dictionary = {}
var _animations: Array[RomSpriteAnimationPrototype] = []
var _pending_glyph_writes: Array[Dictionary] = []
var _action_menu_panel: FirstActionMenuPanel
var _first_command_actor_presenter: FirstCommandActorSourcePresenter
var _meeting_speaker: RomSpriteAnimationPrototype
var _meeting_cursor: Node2D
var _display_enabled := false


func _ready() -> void:
	visible = false
	screen.visible = false


func bind_vm(vm: KickoffCutsceneCommandVm) -> void:
	vm.presenter_event.connect(_on_presenter_event)
	vm.text_glyph_requested.connect(_on_text_glyph_requested)
	vm.wait_completed.connect(_on_wait_completed)


func advance_source_tick() -> void:
	_commit_pending_glyph_writes()
	for animation_node in _animations:
		if is_instance_valid(animation_node):
			animation_node.advance_source_tick()


func clear_route_screen() -> void:
	_pending_glyph_writes.clear()
	_ppu_memory.clear()
	_clear_animations()
	_clear_meeting_cursor()
	active_background_id = -1
	active_background_data_root = ""
	text_cursor_base = TEXT_CURSOR_START
	text_cursor_column = 0
	action_menu_complete = false
	action_menu_missing_dynamic.clear()
	first_match_field_status.clear()
	first_command_actor_status = {"ok": false, "state": "not_presented"}
	_clear_first_command_actor_presenter()
	_display_enabled = false
	visible = false
	screen.visible = false
	screen.set_ppu_memory(_ppu_memory)


## Prepare the source's bank-1 $A64C clear/scene sequence. The NES keeps its
## display active while the ROM background packets are loaded, so expose the
## cleared PPU canvas before scene $44 begins dispatching.
func prepare_pre_match_meeting_scene() -> void:
	clear_route_screen()
	_display_enabled = true
	visible = true
	screen.visible = true


## Install the source cursor after scene $44 has completed. Its position and
## graphics are built from the bank-1 $ADD0 descriptor, ROM CHR, and ROM sprite
## palette $0A; only the current Y row is supplied by the route input model.
func present_pre_match_meeting_menu(cursor_y: int = 0x98) -> bool:
	if active_background_id != 0x5F:
		presentation_gaps.append("MEETING menu requested before ROM background $5F was applied.")
		return false
	if _meeting_cursor == null:
		_meeting_cursor = MEETING_CURSOR_SCRIPT.new() as Node2D
		_meeting_cursor.name = "MeetingMenuCursor"
		sprite_layer.add_child(_meeting_cursor)
	if not _meeting_cursor.set_cursor_y(cursor_y):
		presentation_gaps.append("MEETING cursor: " + _meeting_cursor.last_error)
		return false
	_meeting_cursor.visible = true
	visible = true
	screen.visible = true
	_display_enabled = true
	return true


func set_pre_match_meeting_cursor_y(cursor_y: int) -> bool:
	if _meeting_cursor == null:
		return false
	return _meeting_cursor.set_cursor_y(cursor_y)


## Draw the two first-action windows from their target-ROM descriptors and
## source text rows. Dynamic text and values must come from match state supplied
## by the route; missing substitutions are reported instead of guessed.
func present_first_action_menu(player_state: FirstActionMenuMatchPlayerState,
		actor_source_context: Dictionary = {}) -> bool:
	if first_match_field_status.is_empty() or not bool(first_match_field_status.get("ok", false)):
		if not present_first_match_field_candidate():
			presentation_gaps.append("first-match field candidate: " + str(first_match_field_status.get("error", "source data unavailable")))
	_action_menu_panel = FIRST_ACTION_MENU_SCRIPT.new()
	if not _action_menu_panel.rebuild_for_match_state(player_state):
		presentation_gaps.append("first action menu ROM layout: " + _action_menu_panel.last_error)
		return false
	_ppu_memory = _action_menu_panel.apply_to_ppu_memory(_ppu_memory)
	action_menu_missing_dynamic = _action_menu_panel.missing_dynamic.duplicate(true)
	action_menu_complete = action_menu_missing_dynamic.is_empty()
	screen.set_ppu_memory(_ppu_memory)
	visible = true
	screen.visible = true
	_display_enabled = true
	if actor_source_context.is_empty():
		first_command_actor_status = {
			"ok": false,
			"state": "awaiting_decoded_source_context",
			"required": ["mirror_mode", "scroll_x", "clip_y_min", "clip_y_max"],
		}
		presentation_gaps.append("first-command actors await live ROM-derived mirror/scroll/clip state.")
	else:
		present_first_command_actor_pose(player_state, actor_source_context)
	return true


## Add the endpoint's held ROM actor pose only after the route supplies the
## mutable `$0517/$0538/$0540/$0541` values from decoded gameplay state. The
## active background's universal palette color is read from its ROM profile;
## endpoint RAM/PPU values are never accepted here.
func present_first_command_actor_pose(player_state: FirstActionMenuMatchPlayerState,
		source_context: Dictionary) -> bool:
	first_command_actor_status = {"ok": false, "state": "invalid_source_context"}
	if player_state == null:
		return _actor_pose_failure("A live ROM-derived player state is required for actor graphics/palette selection.")
	if str(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(source_context.get("label", "")).is_empty():
		return _actor_pose_failure("Actor state must come from named decoded game logic, not an endpoint capture.")
	var player_id := player_state.player_id
	if player_id < 0 or player_id > 0x22:
		return _actor_pose_failure("The active ROM player ID is outside the normal-player palette table.")
	# The verified target route's holder is player $08. ROM `$8282` returns the
	# same palette index for ordinary IDs $02-$0E. Special/alternate selectors
	# are deliberately rejected until their live `$002A` input is available.
	if player_id < 0x02 or player_id > 0x0E:
		return _actor_pose_failure("The ROM palette selector's special-player branches need additional source state.")
	var required_byte_fields := ["mirror_mode", "scroll_x", "clip_y_min", "clip_y_max"]
	for field_name in required_byte_fields:
		if not source_context.has(field_name):
			return _actor_pose_failure("Decoded actor source context omits %s." % field_name)
		var raw_field_value: Variant = source_context[field_name]
		if typeof(raw_field_value) != TYPE_INT:
			return _actor_pose_failure("Decoded actor source field %s must be an integer ROM byte." % field_name)
		var field_value := int(raw_field_value)
		if field_value < 0 or field_value > 0xFF:
			return _actor_pose_failure("Decoded actor source field %s does not fit a ROM byte." % field_name)
	var background_palette := screen.get_background_palette_bytes()
	if background_palette.size() != 16:
		return _actor_pose_failure("The active ROM background palette is unavailable for universal sprite color.")
	_clear_first_command_actor_presenter()
	_first_command_actor_presenter = FIRST_COMMAND_ACTOR_SCRIPT.new() as FirstCommandActorSourcePresenter
	_first_command_actor_presenter.name = "FirstCommandRomActorPose"
	sprite_layer.add_child(_first_command_actor_presenter)
	if not _first_command_actor_presenter.configure_endpoint_pose(
			player_id,
			player_id,
			int(source_context["mirror_mode"]),
			int(background_palette[0]),
			int(source_context["scroll_x"]),
			int(source_context["clip_y_min"]),
			int(source_context["clip_y_max"])):
		var presenter_error := _first_command_actor_presenter.last_error
		_clear_first_command_actor_presenter()
		return _actor_pose_failure("ROM actor pose: " + presenter_error)
	first_command_actor_status = {
		"ok": true,
		"state": "rom_source_endpoint_pose",
		"player_id": player_id,
		"palette_record_index": player_id,
		"mirror_mode": int(source_context["mirror_mode"]),
		"scroll_x": int(source_context["scroll_x"]),
		"clip_y_min": int(source_context["clip_y_min"]),
		"clip_y_max": int(source_context["clip_y_max"]),
		"sprite_count": int(_first_command_actor_presenter.last_build_result.get("sprites_written", 0)),
		"source_state": _first_command_actor_presenter.source_state_summary(),
		"source_context": source_context.duplicate(true),
	}
	return true


func _actor_pose_failure(message: String) -> bool:
	first_command_actor_status["error"] = message
	if not presentation_gaps.has(message):
		presentation_gaps.append(message)
	return false


func _clear_first_command_actor_presenter() -> void:
	if is_instance_valid(_first_command_actor_presenter):
		sprite_layer.remove_child(_first_command_actor_presenter)
		_first_command_actor_presenter.free()
	_first_command_actor_presenter = null


## Apply the source menu's selected-action label overlay. The caller owns the
## `$061F` 13-iteration cadence and bit-6 phase; this presenter only builds
## ROM-derived `$04A5`-shape packets.
func set_first_action_menu_selection(action_id: int, blink_visible: bool) -> bool:
	if _action_menu_panel == null or not action_menu_complete:
		return false
	_action_menu_panel.set_action_selection(action_id, blink_visible)
	_ppu_memory = _action_menu_panel.apply_to_ppu_memory(_ppu_memory)
	screen.set_ppu_memory(_ppu_memory)
	return true


## Present the ROM-derived field candidate at the fresh-match command endpoint.
## The candidate contains BG01 row/block output plus the decoded $70/$56 block
## and palette/CHR selectors. Map/raster gaps remain; actor descriptor/OAM
## parsing exists, but route-time actor state is not yet supplied here.
func present_first_match_field_candidate(field_source_context: Dictionary = {}) -> bool:
	var field_presenter = FIRST_MATCH_FIELD_SCRIPT.new()
	if not field_presenter.build_and_apply(screen, field_source_context):
		first_match_field_status = {"ok": false, "error": str(field_presenter.last_error)}
		return false
	_ppu_memory = field_presenter.ppu_memory.duplicate()
	active_background_id = 0x01
	active_background_data_root = "res://reference/rom_extract/intro"
	first_match_field_status = field_presenter.status.duplicate(true)
	for gap in first_match_field_status.get("gaps", []):
		var gap_text := str(gap)
		if not presentation_gaps.has(gap_text):
			presentation_gaps.append(gap_text)
	_display_enabled = true
	visible = true
	screen.visible = true
	return true


func _on_presenter_event(event: Dictionary) -> void:
	var kind := str(event.get("kind", ""))
	match kind:
		"background_1":
			_set_background(int(event.get("id", -1)), true)
		"background_2":
			# The second ROM background is a secondary draw layer. Preserve the
			# primary CHR profile while applying its ROM packet stream on top.
			_set_background(int(event.get("id", -1)), false)
		"animations":
			_replace_animations(event.get("animation_ids", []))
		"screen_on":
			_display_enabled = true
			visible = true
			screen.visible = true
		"screen_off_clear":
			_display_enabled = false
			visible = false
			screen.visible = false
			_clear_animations()
		"text_cursor_back":
			text_cursor_column -= int(event.get("tile_count", 0))
		"text_base_ppu_address":
			var arguments: Array = event.get("arguments", [])
			if arguments.size() == 2:
				text_cursor_base = int(arguments[0]) | (int(arguments[1]) << 8)
				text_cursor_column = 0
		"clear_text":
			_clear_text_window()
		"palette_command", "text_brightness_command", "visual_preset", "visual_flag", "toggle_camera":
			# These commands are forwarded for a later renderer extension. The ROM
			# operands remain in the event manifest; no guessed visual effect is
			# added here.
			presentation_gaps.append("%s at %s" % [kind, str(event.get("cpu_address", "?"))])
		"jump", "dialog_window", "exit", "compact_pause", "fc_handler", "pause_frames", "sound_command", "text_speed", "text_tile_ids", "wait_for_input":
			pass
		_:
			presentation_gaps.append("unknown event %s at %s" % [kind, str(event.get("cpu_address", "?"))])


func _on_wait_completed(wait_kind: String, event: Dictionary) -> void:
	if wait_kind == "fc_handler":
		# Local ROM $8837 handler yields four scheduler ticks, increments the
		# little-endian text base by $0040, then re-enters $84E3 and seeds the
		# glyph cursor from that new base.
		text_cursor_base = (text_cursor_base + 0x40) & 0xFFFF
		text_cursor_column = 0
	elif wait_kind == "text_speed":
		pass
	else:
		pass


func _on_text_glyph_requested(tile_id: int, _source_cpu: int, _event_index: int, _glyph_index: int) -> void:
	var address := text_cursor_base + text_cursor_column
	if address < 0x2000 or address + 0x20 >= NAMETABLE_END:
		presentation_gaps.append("glyph cursor outside modeled nametable: $%04X" % address)
		return
	_pending_glyph_writes.append({"address": address, "value": 0x00})
	_pending_glyph_writes.append({"address": address + 0x20, "value": tile_id & 0xFF})
	text_cursor_column += 1


func _commit_pending_glyph_writes() -> void:
	if _pending_glyph_writes.is_empty():
		return
	for write in _pending_glyph_writes:
		_ppu_memory[int(write["address"])] = int(write["value"])
	_pending_glyph_writes.clear()
	screen.set_ppu_memory(_ppu_memory)


func _set_background(background_id: int, replace_primary: bool) -> void:
	if background_id < 0 or background_id > 0xFF:
		presentation_gaps.append("invalid background id %d" % background_id)
		return
	var data_root := INTRO_DATA_ROOT if FileAccess.file_exists(
		INTRO_DATA_ROOT + "/background_%02X_layout.json" % background_id) else GAMEPLAY_DATA_ROOT
	if not FileAccess.file_exists(data_root + "/background_%02X_layout.json" % background_id):
		presentation_gaps.append("no ROM-derived layout for background $%02X" % background_id)
		return
	if replace_primary:
		active_background_id = background_id
		active_background_data_root = data_root
		_ppu_memory.clear()
		text_cursor_base = TEXT_CURSOR_START
		text_cursor_column = 0
		if not screen.set_background_profile(background_id, PackedByteArray(), data_root):
			presentation_gaps.append("renderer rejected background $%02X" % background_id)
			return
	var loader: RomBackgroundPacketLoader = BACKGROUND_PACKET_LOADER.new()
	if not loader.build_packets(background_id, data_root):
		presentation_gaps.append("packet builder rejected background $%02X: %s" % [background_id, loader.last_error])
		return
	for packet in loader.packets:
		var address := int(packet.get("ppu_address", -1))
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		if address < 0:
			continue
		for byte_index in payload.size():
			_ppu_memory[address + byte_index] = int(payload[byte_index])
	screen.set_ppu_memory(_ppu_memory)


func _replace_animations(ids_variant: Variant) -> void:
	_clear_animations()
	_meeting_speaker = null
	if not ids_variant is Array:
		presentation_gaps.append("animation ID list is malformed")
		return
	var ids: Array = ids_variant
	# Reverse creation order so the earlier ROM FB entry draws in front, as in
	# the NES OAM list. Source animation timing remains a separate scheduler.
	for animation_index in range(ids.size() - 1, -1, -1):
		var animation_id := int(ids[animation_index])
		var animation_node: RomSpriteAnimationPrototype = SPRITE_SCRIPT.new()
		animation_node.name = "KickoffAnimation_%02X_%d" % [animation_id, animation_index]
		animation_node.animation_id = "0x%02X" % animation_id
		animation_node.timing_resource_path = GAMEPLAY_ANIMATION_TIMING
		animation_node.frame_resource_path = GAMEPLAY_SPRITE_FRAMES
		animation_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite_layer.add_child(animation_node)
		if animation_id == 0x3B:
			_meeting_speaker = animation_node
			if not animation_node.set_rom_state_branch(0):
				presentation_gaps.append("scene $44 animation $3B lacks decoded ROM $FA branch poses")
			presentation_gaps.append("scene $44 speaker branch cadence from $0099 remains untraced")
		animation_node.reset_source_timeline()
		_animations.append(animation_node)


func _clear_animations() -> void:
	_meeting_speaker = null
	for animation_node in _animations:
		if is_instance_valid(animation_node):
			sprite_layer.remove_child(animation_node)
			animation_node.queue_free()
	_animations.clear()


func _clear_meeting_cursor() -> void:
	if is_instance_valid(_meeting_cursor):
		sprite_layer.remove_child(_meeting_cursor)
		_meeting_cursor.queue_free()
	_meeting_cursor = null


func _clear_text_window() -> void:
	# FD's clear origin/width comes from its separate ROM state helper; the
	# command manifest preserves opcode order but not that RAM state. Clear the
	# currently modeled text band and reset to the verified first-line origin.
	for row in range(0, 10):
		for column in range(0, 32):
			var address := TEXT_CURSOR_START + row * 0x20 + column
			_ppu_memory[address] = 0
	text_cursor_base = TEXT_CURSOR_START
	text_cursor_column = 0
	screen.set_ppu_memory(_ppu_memory)
