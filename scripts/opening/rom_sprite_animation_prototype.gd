extends Node2D
class_name RomSpriteAnimationPrototype
## Native sprite animation renderer driven by decoded ROM animation/frame bytes.
## This isolated prototype uses CHR ROM patterns and descriptor data only; it
## does not load the NES ROM, emulator dumps, or screenshots at runtime.

const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const TIMING_PATH := "res://reference/rom_extract/intro/animation_timing_entry.json"
const FRAMES_PATH := "res://reference/rom_extract/intro/sprite_frames_entry.json"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const NES_WIDTH := 256
const NES_HEIGHT := 240
const NES_FPS := 60.0988
const TICKS_PER_SECOND := NES_FPS
const MAX_SHARED_SPRITE_TILE_CACHE_ENTRIES := 8192

# ROM-derived lookup data is immutable across animation instances. Keeping these
# source files parsed once avoids rereading the 128 KiB CHR and reparsing nearly
# 1 MiB of animation JSON every time the cutscene replaces an FB animation set.
static var _shared_chr: PackedByteArray = PackedByteArray()
static var _shared_nes_rgb_palette: PackedByteArray = PackedByteArray()
static var _shared_json_by_path: Dictionary = {}
static var _shared_frames_by_address: Dictionary = {}
static var _shared_frames_by_path: Dictionary = {}
# Lazy ROM-derived tile variants are shared across animation nodes. The cache
# is bounded; an uncached miss at capacity uses the per-pixel renderer below.
static var _shared_sprite_tile_images: Dictionary = {}
# Optional, diagnostics-only timing hook. It stays unset in normal gameplay and
# does not change rendering decisions or source timing.
static var _diagnostic_timing_sink: Callable = Callable()
static var _diagnostic_source_frame := -1

## Selects any decoded intro animation. Tracks with waits use their ROM beats;
## zero-wait entries hold their final frame as a static pose.
@export var animation_id := "0x84"
@export_file("*.json") var timing_resource_path := TIMING_PATH
@export_file("*.json") var frame_resource_path := FRAMES_PATH
## Optionally override the animation-specific ROM palette with 16 RGB colors.
## An empty override loads the project palette resource for this animation;
## grayscale is only the geometry fallback when no resource can be loaded.
@export var sprite_palette_rgb: PackedColorArray = PackedColorArray()

var _chr := PackedByteArray()
var _beats: Array[Dictionary] = []
var _frames_by_address: Dictionary = {}
var _duration_ticks := 0
var _static_pose: Dictionary = {}
var _state_branch_frame_addresses: Dictionary = {}
var _elapsed := 0.0
var _manual_source_clock := false
var _manual_source_tick := 0
var _repeat_cycle_start_tick := -1
var _repeat_cycle_length_ticks := 0
var _origin_override_enabled := false
var _origin_override := Vector2i.ZERO
var _origin_x_motion_offset := 0
var _camera_follow_x_wrap_marker_active := false
var _source_oam_origin_enabled := false
var _source_oam_origin_unwrapped := Vector2i.ZERO
var _source_oam_slot_start := -1
var _source_oam_allocation_order := -1
var _shared_oam_scanline_visibility: Dictionary = {}
var _shared_oam_visibility_revision := -1
var _texture: ImageTexture
var _nes_rgb_palette := PackedByteArray()
var _last_rendered_pose_key := ""
var _render_updates_suppressed := false


func _ready() -> void:
	var load_started_usec := Time.get_ticks_usec()
	if not _load_rom_derived_data():
		set_process(false)
		return
	_emit_diagnostic_timing({
		"kind": "rom_data_load",
		"animation_id": animation_id,
		"source_frame": _diagnostic_source_frame,
		"duration_usec": Time.get_ticks_usec() - load_started_usec,
	})
	set_process(true)
	_request_pose_render()


func _process(delta: float) -> void:
	if not _manual_source_clock:
		_elapsed += delta
	_request_pose_render()


## Let a ROM source-frame presenter advance this animation with its own clock.
func reset_source_timeline() -> void:
	_manual_source_clock = true
	_manual_source_tick = 0
	_elapsed = 0.0
	_request_pose_render()


func advance_source_tick() -> void:
	_manual_source_clock = true
	_manual_source_tick += 1
	_request_pose_render()


## Diagnostic capture fast-forward: keep advancing the ROM clock, but render
## only the requested checkpoint pose when suppression is lifted.
func set_render_updates_suppressed(suppressed: bool) -> void:
	if _render_updates_suppressed == suppressed:
		return
	_render_updates_suppressed = suppressed
	if not _render_updates_suppressed:
		_render_current_pose()


func set_origin_override(screen_x: int, screen_y: int) -> void:
	_origin_override_enabled = true
	_origin_override = Vector2i(screen_x, screen_y)
	_request_pose_render()


## Switch a ROM `$FA` animation frame using its decoded selector bit. This is
## used by scene `$44`'s speaker animation; the caller supplies the traced
## `$0099` bit-0 state, while frame bytes remain ROM-derived.
func set_rom_state_branch(selector_value: int) -> bool:
	if not _state_branch_frame_addresses.has(selector_value):
		return false
	_static_pose["sprite_frame_cpu_address"] = str(_state_branch_frame_addresses[selector_value])
	_last_rendered_pose_key = ""
	_request_pose_render()
	return true


## Set the accumulated source-derived motion offset in 8-bit OAM space.
func set_origin_x_motion_offset(screen_x_offset: int) -> void:
	# Preserve whole-screen wraps: ROM attribute bit $04 toggles on every
	# 8-bit X overflow, while the displayed OAM coordinate still wraps below.
	if _origin_x_motion_offset == screen_x_offset:
		return
	_origin_x_motion_offset = screen_x_offset
	_request_pose_render()


## Enable the ROM X-wrap attribute marker used by motion animations. The shared
## OAM copier moves sprites with attribute bits $0C to Y=$F8; the source
## animation/camera worker toggles bit $04 for each sprite as its X wraps.
func set_camera_follow_x_wrap_marker_active(active: bool) -> void:
	if _camera_follow_x_wrap_marker_active == active:
		return
	_camera_follow_x_wrap_marker_active = active
	_request_pose_render()


## Supply a source-backed unsigned doubled coordinate for animations whose
## motion record feeds the descriptor writer directly. Bit 8 becomes the
## source X/Y overflow marker; the byte coordinate is still rendered modulo 256.
func set_source_oam_origin_unwrapped(x_pixels: int, y_pixels: int) -> void:
	var new_origin := Vector2i(posmod(x_pixels, 512), posmod(y_pixels, 512))
	if _source_oam_origin_enabled and _source_oam_origin_unwrapped == new_origin:
		return
	_source_oam_origin_enabled = true
	_source_oam_origin_unwrapped = new_origin
	_request_pose_render()


## Assign the first real hardware OAM slot allocated to this FB animation.
## `allocation_order` is the original FB list order; later allocations overwrite
## wrapped slots just as the source writer does.
func set_source_oam_allocation(slot_start: int, allocation_order: int) -> void:
	var normalized_slot_start := posmod(slot_start, 64)
	if _source_oam_slot_start == normalized_slot_start \
			and _source_oam_allocation_order == allocation_order:
		return
	_source_oam_slot_start = normalized_slot_start
	_source_oam_allocation_order = allocation_order
	_request_pose_render()


## Maximum descriptor count reserved for this object by the ROM animation
## allocator. The presenter uses this as the next FB object's starting slot.
func source_oam_slot_extent() -> int:
	var extent := 0
	for beat in _beats:
		var frame := _frame_for_beat(beat)
		var sprites: Variant = frame.get("sprites", [])
		if sprites is Array:
			extent = maxi(extent, sprites.size())
	if not _static_pose.is_empty():
		var static_frame := _frame_for_beat(_static_pose)
		var static_sprites: Variant = static_frame.get("sprites", [])
		if static_sprites is Array:
			extent = maxi(extent, static_sprites.size())
	return extent


func source_oam_allocation_order() -> int:
	return _source_oam_allocation_order


func source_oam_evaluation_entries() -> Array[Dictionary]:
	if _source_oam_slot_start < 0:
		return []
	var pose := _resolve_current_pose()
	if pose.is_empty():
		return []
	return _build_source_oam_evaluation_entries(pose)


## Apply the shared PPU's first-eight-sprites-per-scanline result. Each slot maps
## to 240 bytes, with 1 meaning the sprite is evaluated for that output row.
func set_shared_oam_scanline_visibility(visibility_by_slot: Dictionary, revision: int) -> void:
	if _shared_oam_scanline_visibility == visibility_by_slot:
		return
	_shared_oam_scanline_visibility = visibility_by_slot
	_shared_oam_visibility_revision = revision
	_last_rendered_pose_key = ""
	_request_pose_render()


func _load_rom_derived_data() -> bool:
	if _shared_chr.is_empty():
		_shared_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_chr = _shared_chr
	if _chr.is_empty() or _chr.size() != 131072:
		push_error("ROM-derived CHR byte stream is missing or has an unexpected size.")
		return false
	if _shared_nes_rgb_palette.is_empty():
		_shared_nes_rgb_palette = FileAccess.get_file_as_bytes(NES_RGB_PATH)
	_nes_rgb_palette = _shared_nes_rgb_palette
	if _nes_rgb_palette.size() != 192:
		push_error("External FCEUX RGB palette is missing or has an unexpected size.")
		return false

	var timing_data := _read_json(timing_resource_path)
	var frame_data := _read_json(frame_resource_path)
	if timing_data.is_empty() or frame_data.is_empty():
		return false
	if str(timing_data.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Animation timing data belongs to a different ROM revision.")
		return false
	if str(frame_data.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		push_error("Sprite frame data belongs to a different ROM revision.")
		return false
	if sprite_palette_rgb.is_empty():
		_load_original_palette()

	if not _shared_frames_by_path.has(frame_resource_path):
		var frames_for_path: Dictionary = {}
		for frame_variant: Variant in frame_data.get("frames", []):
			if frame_variant is Dictionary:
				var frame: Dictionary = frame_variant
				frames_for_path[str(frame.get("cpu_address", ""))] = frame
		_shared_frames_by_path[frame_resource_path] = frames_for_path
	_frames_by_address = _shared_frames_by_path[frame_resource_path]
	_shared_frames_by_address = _frames_by_address

	for animation_variant: Variant in timing_data.get("animations", []):
		if not animation_variant is Dictionary:
			continue
		var animation: Dictionary = animation_variant
		if str(animation.get("animation_id", "")) != animation_id:
			continue
		var state_branch_initial_value := 0
		var terminal_variant: Variant = animation.get("terminal", {})
		if terminal_variant is Dictionary:
			var terminal: Dictionary = terminal_variant
			if str(terminal.get("kind", "")) == "repeat_cycle":
				_repeat_cycle_start_tick = int(terminal.get("cycle_start_tick", -1))
				_repeat_cycle_length_ticks = int(terminal.get("cycle_length_ticks", 0))
			elif str(terminal.get("kind", "")) == "state_branch":
				state_branch_initial_value = int(terminal.get("initial_selector_value", 0))
				for branch_variant in terminal.get("cases", []):
					if not branch_variant is Dictionary:
						continue
					var branch: Dictionary = branch_variant
					_state_branch_frame_addresses[int(branch.get("selector_value", -1))] = str(branch.get("frame_cpu_address", ""))
		for beat_variant: Variant in animation.get("beats", []):
			if beat_variant is Dictionary:
				var beat: Dictionary = beat_variant
				_beats.append(beat)
				_duration_ticks = maxi(_duration_ticks,
					int(beat.get("start_tick", 0)) + int(beat.get("hold_ticks", 0)))
		if _beats.is_empty():
			_static_pose = _static_pose_from_commands(animation.get("commands", []))
			if not _state_branch_frame_addresses.is_empty():
				_static_pose["sprite_frame_cpu_address"] = str(_state_branch_frame_addresses.get(
					state_branch_initial_value, ""))
		break

	if _beats.is_empty() and _static_pose.is_empty():
		push_error("No ROM animation timing beats found for %s." % animation_id)
		return false
	if not _beats.is_empty() and _duration_ticks <= 0:
		push_error("Invalid ROM animation duration for %s." % animation_id)
		return false
	return true


func _load_original_palette() -> void:
	var palette_path := "res://assets/opening/rom_logic/animation_%s_sprite_palette.json" % animation_id.trim_prefix("0x").to_lower()
	# Some animations select palette index 00 from the global PPU palette packet;
	# those receive the source palette bytes from the scene presenter at runtime.
	if FileAccess.file_exists(palette_path):
		var palette_data := _read_json(palette_path)
		var rgb_mapping: Variant = palette_data.get("rgb_mapping", {})
		if not rgb_mapping is Dictionary:
			return
		var rows: Variant = rgb_mapping.get("rows", [])
		if not rows is Array or rows.size() != 16:
			push_error("Animation %s sprite palette resource must contain 16 entries." % animation_id)
			return
		for row_variant: Variant in rows:
			if row_variant is Dictionary:
				sprite_palette_rgb.append(Color.html(str(row_variant.get("rgb_hex", "#000000"))))
		return

	# KICK OFF route animations share the ROM's indexed sprite-palette table.
	# Their animation records live under gameplay/animations/kickoff, separate
	# from the cold-start extract, so derive the palette from that byte-preserved
	# record and the original nine-entry table rather than falling back to gray.
	if not timing_resource_path.contains("gameplay/animations/kickoff"):
		return
	var palette_id := animation_id.trim_prefix("0x").hex_to_int()
	var record_path := "res://reference/rom_extract/gameplay/animations/kickoff/animation_%02X.bin" % palette_id
	var record := FileAccess.get_file_as_bytes(record_path)
	var palette_table := FileAccess.get_file_as_bytes("res://reference/rom_extract/intro/sprite_palette_table_00_3F.bin")
	if record.is_empty() or palette_table.size() != 0x40 * 16 or record[0] >= 0x40:
		return
	for palette_index in 16:
		var nes_color := int(palette_table[int(record[0]) * 16 + palette_index]) & 0x3F
		var color_offset := nes_color * 3
		sprite_palette_rgb.append(Color(
			float(_nes_rgb_palette[color_offset]) / 255.0,
			float(_nes_rgb_palette[color_offset + 1]) / 255.0,
			float(_nes_rgb_palette[color_offset + 2]) / 255.0,
			1.0))


func set_fade_palette_bytes(palette_bytes: PackedByteArray) -> void:
	if palette_bytes.size() != 16 or _nes_rgb_palette.size() != 192:
		return
	var new_palette := PackedColorArray()
	for nes_color: int in palette_bytes:
		var offset := (nes_color & 0x3F) * 3
		new_palette.append(Color(
			float(_nes_rgb_palette[offset]) / 255.0,
			float(_nes_rgb_palette[offset + 1]) / 255.0,
			float(_nes_rgb_palette[offset + 2]) / 255.0,
			1.0))
	if sprite_palette_rgb == new_palette:
		return
	sprite_palette_rgb = new_palette
	if not _frames_by_address.is_empty():
		_request_pose_render()


func _request_pose_render() -> void:
	if not _render_updates_suppressed:
		_render_current_pose()


func _read_json(path: String) -> Dictionary:
	if _shared_json_by_path.has(path):
		return _shared_json_by_path[path]
	if not FileAccess.file_exists(path):
		push_error("Missing ROM-derived animation data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid JSON object in %s" % path)
		return {}
	_shared_json_by_path[path] = parsed
	return parsed


func _frame_for_beat(beat: Dictionary) -> Dictionary:
	var frame_address := str(beat.get("sprite_frame_cpu_address", ""))
	return _frames_by_address.get(frame_address, {})


func _resolve_current_pose() -> Dictionary:
	var beat: Dictionary
	if _beats.is_empty():
		beat = _static_pose
	else:
		var tick := _manual_source_tick if _manual_source_clock else int(floor(_elapsed * TICKS_PER_SECOND))
		if _repeat_cycle_start_tick >= 0 and _repeat_cycle_length_ticks > 0 \
				and tick >= _repeat_cycle_start_tick:
			tick = _repeat_cycle_start_tick + posmod(
				tick - _repeat_cycle_start_tick, _repeat_cycle_length_ticks)
		elif _repeat_cycle_start_tick < 0:
			tick = posmod(tick, _duration_ticks)
		beat = _find_beat(tick)
	if beat.is_empty():
		return {}
	var frame_address := str(beat.get("sprite_frame_cpu_address", ""))
	var frame: Dictionary = _frame_for_beat(beat)
	if frame.is_empty():
		return {}

	var selectors := _hex_bytes(str(frame.get("chr_selectors_hex", "")))
	if selectors.size() != 4:
		return {}
	# The source stores the animation X origin in an 8-bit OAM coordinate.
	# Apply the NES byte wrap before clipping sprites against the 256px viewport.
	var origin_x := posmod(_signed_byte(int(beat.get("initial_x", 0))) * 2, NES_WIDTH)
	var origin_y := _signed_byte(int(beat.get("initial_y", 0))) * 2
	if _origin_override_enabled:
		origin_x = posmod(_origin_override.x, NES_WIDTH)
		origin_y = _origin_override.y
	var base_origin_x := origin_x
	origin_x = posmod(base_origin_x + _origin_x_motion_offset, NES_WIDTH)
	var mirrored := bool(beat.get("mirror_h", false))
	var palette_visual_key := _palette_visual_key()
	var pose_key := "%s|%s|%d|%d|%s|%s" % [
		animation_id,
		frame_address,
		origin_x,
		origin_y,
		"1" if mirrored else "0",
		palette_visual_key,
	]
	pose_key += "|motion:%d|camera_wrap_marker:%d" % [
		_origin_x_motion_offset,
		1 if _camera_follow_x_wrap_marker_active else 0,
	]
	pose_key += "|source_oam_origin:%d:%d:%d" % [
		1 if _source_oam_origin_enabled else 0,
		_source_oam_origin_unwrapped.x,
		_source_oam_origin_unwrapped.y,
	]
	pose_key += "|shared_oam_revision:%d" % _shared_oam_visibility_revision
	return {
		"beat": beat,
		"frame": frame,
		"frame_address": frame_address,
		"origin_x": origin_x,
		"origin_y": origin_y,
		"base_origin_x": base_origin_x,
		"mirrored": mirrored,
		"palette_visual_key": palette_visual_key,
		"pose_key": pose_key,
	}


func _sprite_oam_placement(sprite: Dictionary, sprite_index: int, pose: Dictionary) -> Dictionary:
	var relative_x := int(sprite.get("x_offset_from_animation", 0))
	var relative_y := int(sprite.get("y_offset_from_animation", 0))
	var mirrored := bool(pose["mirrored"])
	var sprite_relative_x := -relative_x if mirrored else relative_x
	var sprite_x := posmod(int(pose["origin_x"]) + sprite_relative_x, NES_WIDTH)
	var sprite_y := int(pose["origin_y"]) + relative_y + 1 # OAM Y is top scanline minus one.
	var subpalette := int(sprite.get("palette_low_bits", 0))
	var hidden_by_dma_culling := false
	if _source_oam_origin_enabled:
		# `$94D8` preserves coordinate bit 8 in attr `$04/$08`; `$A8CE` replaces
		# only DMA Y with `$F8` when either bit is set.
		var source_oam_x := posmod(
			_source_oam_origin_unwrapped.x + sprite_relative_x, 512)
		var source_oam_y := posmod(
			_source_oam_origin_unwrapped.y + relative_y, 512)
		sprite_x = source_oam_x & 0xFF
		sprite_y = (source_oam_y & 0xFF) + 1
		var overflow_attribute := ((source_oam_x >> 8) & 1) << 2
		overflow_attribute |= ((source_oam_y >> 8) & 1) << 3
		hidden_by_dma_culling = ((subpalette | overflow_attribute) & 0x0C) != 0
	elif _camera_follow_x_wrap_marker_active:
		var initial_oam_x := posmod(
			int(pose["base_origin_x"]) + sprite_relative_x, NES_WIDTH)
		var unwrapped_oam_x := initial_oam_x + _origin_x_motion_offset
		var x_wrap_count := int(floor(float(unwrapped_oam_x) / float(NES_WIDTH)))
		var internal_attribute := subpalette
		# The ROM animation sets bit `$04` before the first X wrap; each X-byte
		# overflow toggles it. `$A8CE` hides entries with either marker bit.
		if posmod(x_wrap_count, 2) == 0:
			internal_attribute |= 0x04
		hidden_by_dma_culling = (internal_attribute & 0x0C) != 0
	return {
		"slot": posmod(_source_oam_slot_start + sprite_index, 64)
			if _source_oam_slot_start >= 0 else -1,
		"x": sprite_x,
		"y": sprite_y,
		"flip_x": mirrored != bool(sprite.get("flip_h_bit", false)),
		"subpalette": subpalette,
		"hidden": hidden_by_dma_culling,
	}


func _build_source_oam_evaluation_entries(pose: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if _source_oam_slot_start < 0:
		return entries
	var sprites: Array = pose["frame"].get("sprites", [])
	for sprite_index in sprites.size():
		var sprite_variant: Variant = sprites[sprite_index]
		if not sprite_variant is Dictionary:
			continue
		var placement := _sprite_oam_placement(sprite_variant, sprite_index, pose)
		if bool(placement["hidden"]):
			continue
		# Evaluate against the displayed scanline, including this animation's
		# canvas translation. Tile compositing itself stays in local coordinates.
		var first_visible_row := int(placement["y"]) + roundi(position.y)
		if first_visible_row >= NES_HEIGHT or first_visible_row + 8 <= 0:
			continue
		entries.append({
			"slot": int(placement["slot"]),
			"sprite_index": sprite_index,
			"first_visible_row": first_visible_row,
			"owner_instance_id": int(get_instance_id()),
		})
	return entries


func _render_current_pose() -> void:
	var total_started_usec := Time.get_ticks_usec()
	var resolve_started_usec := total_started_usec
	var pose := _resolve_current_pose()
	var resolve_usec := Time.get_ticks_usec() - resolve_started_usec
	if pose.is_empty():
		return
	var frame: Dictionary = pose["frame"]
	var sprites: Array = frame.get("sprites", [])
	var selectors := _hex_bytes(str(frame.get("chr_selectors_hex", "")))
	var pose_key := str(pose["pose_key"])
	if pose_key == _last_rendered_pose_key:
		return
	var cached_render_started_usec := Time.get_ticks_usec()
	var image := _render_pose_with_cached_tiles(pose, sprites, selectors)
	var cached_render_usec := Time.get_ticks_usec() - cached_render_started_usec
	var software_render_usec := 0
	if image == null:
		# Keep the established per-pixel path as a bounded fallback for invalid
		# image/cache states. It uses the same ROM bytes and OAM rules.
		var software_render_started_usec := Time.get_ticks_usec()
		image = _render_pose_software(pose, sprites, selectors)
		software_render_usec = Time.get_ticks_usec() - software_render_started_usec
	if image == null or image.is_empty():
		return
	var texture_create_started_usec := Time.get_ticks_usec()
	_texture = ImageTexture.create_from_image(image)
	var texture_create_usec := Time.get_ticks_usec() - texture_create_started_usec
	_last_rendered_pose_key = pose_key
	queue_redraw()
	_emit_diagnostic_timing({
		"kind": "render_pose",
		"animation_id": animation_id,
		"source_frame": _diagnostic_source_frame,
		"pose_key": pose_key,
		"sprite_count": sprites.size(),
		"pose_resolve_usec": resolve_usec,
		"cached_image_render_usec": cached_render_usec,
		"software_fallback_usec": software_render_usec,
		# ImageTexture creation measures CPU-side upload/setup submission. The
		# actual GPU transfer is asynchronous and is not exposed as a separate timer.
		"image_texture_create_submit_usec": texture_create_usec,
		"render_method_total_usec": Time.get_ticks_usec() - total_started_usec,
	})


static func set_diagnostic_timing_sink(sink: Callable, source_frame: int = -1) -> void:
	_diagnostic_timing_sink = sink
	_diagnostic_source_frame = source_frame


static func set_diagnostic_source_frame(source_frame: int) -> void:
	_diagnostic_source_frame = source_frame


func _emit_diagnostic_timing(sample: Dictionary) -> void:
	if _diagnostic_timing_sink.is_valid():
		_diagnostic_timing_sink.call(sample)


func _render_pose_with_cached_tiles(pose: Dictionary, sprites: Array,
		selectors: PackedByteArray) -> Image:
	var image := Image.create(NES_WIDTH, NES_HEIGHT, false, Image.FORMAT_RGBA8)
	if image == null or image.is_empty():
		return null
	image.fill(Color(0, 0, 0, 0))
	var palette_key := str(pose.get("palette_visual_key", _palette_visual_key()))

	# OAM draws lower indices in front. Paint the descriptor list backwards to
	# preserve the ROM descriptor/OAM order when sprites overlap.
	for sprite_index in range(sprites.size() - 1, -1, -1):
		var sprite_variant: Variant = sprites[sprite_index]
		if not sprite_variant is Dictionary:
			continue
		var sprite: Dictionary = sprite_variant
		var tile := _hex_byte(str(sprite.get("tile_id", "0x00")))
		var bank_slot := tile >> 6
		var bank := int(selectors[bank_slot])
		var pattern_offset := bank * 1024 + (tile & 0x3F) * 16
		if pattern_offset < 0 or pattern_offset + 16 > _chr.size():
			continue
		var placement := _sprite_oam_placement(sprite, sprite_index, pose)
		if bool(placement["hidden"]):
			continue
		var sprite_x := int(placement["x"])
		var sprite_y := int(placement["y"])
		var flip_x := bool(placement["flip_x"])
		var subpalette := int(placement["subpalette"])
		var oam_slot := int(placement["slot"])
		var visible_row_mask := _sprite_visible_row_mask(
			oam_slot, sprite_index, sprite_y)
		if visible_row_mask == 0:
			continue
		var plane1_overrides := _plane1_fetch_overrides_for_sprite(oam_slot, sprite_index)
		var tile_image: Image
		if plane1_overrides.is_empty():
			tile_image = _get_shared_sprite_tile_image(
				pattern_offset, subpalette, flip_x, palette_key)
		else:
			# Fetch-event variants are transient. Never store them in the immutable
			# ROM-CHR tile cache, whose entries represent ordinary sprite reads.
			tile_image = _build_sprite_tile_image_with_plane1_overrides(
				pattern_offset, subpalette, flip_x, plane1_overrides)
		if tile_image == null or tile_image.is_empty():
			return null
		_blend_visible_sprite_rows(image, tile_image, sprite_x,
			sprite_y, visible_row_mask)
	return image


func _render_pose_software(pose: Dictionary, sprites: Array,
		selectors: PackedByteArray) -> Image:
	var image := Image.create(NES_WIDTH, NES_HEIGHT, false, Image.FORMAT_RGBA8)
	if image == null or image.is_empty():
		return null
	image.fill(Color(0, 0, 0, 0))

	# Keep the original per-pixel implementation available if a cached tile
	# cannot be built. This remains the pixel-level reference path.
	for sprite_index in range(sprites.size() - 1, -1, -1):
		var sprite_variant: Variant = sprites[sprite_index]
		if not sprite_variant is Dictionary:
			continue
		var sprite: Dictionary = sprite_variant
		var tile := _hex_byte(str(sprite.get("tile_id", "0x00")))
		var bank_slot := tile >> 6
		var bank := int(selectors[bank_slot])
		var pattern_offset := bank * 1024 + (tile & 0x3F) * 16
		if pattern_offset < 0 or pattern_offset + 16 > _chr.size():
			continue
		var placement := _sprite_oam_placement(sprite, sprite_index, pose)
		if bool(placement["hidden"]):
			continue
		var sprite_x := int(placement["x"])
		var sprite_y := int(placement["y"])
		var flip_x := bool(placement["flip_x"])
		var subpalette := int(placement["subpalette"])
		var oam_slot := int(placement["slot"])
		var plane1_overrides := _plane1_fetch_overrides_for_sprite(oam_slot, sprite_index)
		for py in 8:
			var low_plane := int(_chr[pattern_offset + py])
			var high_plane := int(_chr[pattern_offset + 8 + py])
			if plane1_overrides.has(py):
				high_plane = int(plane1_overrides[py]) & 0xFF
			for px in 8:
				var source_x := 7 - px if flip_x else px
				var bit := 7 - source_x
				var color_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
				if color_index == 0:
					continue
				var screen_x := sprite_x + px
				var screen_y := sprite_y + py
				if screen_x < 0 or screen_x >= NES_WIDTH or screen_y < 0 or screen_y >= NES_HEIGHT:
					continue
				if oam_slot >= 0:
					var visibility_rule: Variant = _shared_oam_scanline_visibility.get(oam_slot)
					if visibility_rule is Dictionary:
						if int(visibility_rule.get("owner_instance_id", -1)) != int(get_instance_id()):
							continue
						if int(visibility_rule.get("sprite_index", -1)) != sprite_index:
							continue
						var visible_rows: Variant = visibility_rule.get("rows", PackedByteArray())
						var displayed_oam_row := screen_y + roundi(position.y)
						if visible_rows is PackedByteArray \
								and (displayed_oam_row < 0 or displayed_oam_row >= visible_rows.size() \
								or visible_rows[displayed_oam_row] == 0):
							continue
				var palette_slot := subpalette * 4 + color_index
				image.set_pixel(screen_x, screen_y, _color_for_palette_slot(palette_slot, color_index))
	return image


func _plane1_fetch_overrides_for_sprite(oam_slot: int, sprite_index: int) -> Dictionary:
	if oam_slot < 0:
		return {}
	var visibility_rule: Variant = _shared_oam_scanline_visibility.get(oam_slot)
	if not visibility_rule is Dictionary \
			or int(visibility_rule.get("owner_instance_id", -1)) != int(get_instance_id()) \
			or int(visibility_rule.get("sprite_index", -1)) != sprite_index:
		return {}
	var overrides_variant: Variant = visibility_rule.get("plane1_bytes_by_source_row", {})
	return overrides_variant if overrides_variant is Dictionary else {}


func _build_sprite_tile_image_with_plane1_overrides(pattern_offset: int,
		subpalette: int, flip_x: bool, overrides_by_source_row: Dictionary) -> Image:
	var tile_image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	if tile_image == null or tile_image.is_empty():
		return null
	tile_image.fill(Color(0, 0, 0, 0))
	for py in 8:
		var low_plane := int(_chr[pattern_offset + py])
		var high_plane := int(_chr[pattern_offset + 8 + py])
		if overrides_by_source_row.has(py):
			high_plane = int(overrides_by_source_row[py]) & 0xFF
		for px in 8:
			var source_x := 7 - px if flip_x else px
			var bit := 7 - source_x
			var color_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
			if color_index == 0:
				continue
			var palette_slot := subpalette * 4 + color_index
			tile_image.set_pixel(px, py, _color_for_palette_slot(palette_slot, color_index))
	return tile_image


func _sprite_visible_row_mask(oam_slot: int, sprite_index: int,
		sprite_y: int) -> int:
	if oam_slot < 0:
		return 0xFF
	var visibility_rule: Variant = _shared_oam_scanline_visibility.get(oam_slot)
	if not visibility_rule is Dictionary:
		return 0xFF
	if int(visibility_rule.get("owner_instance_id", -1)) != int(get_instance_id()) \
			or int(visibility_rule.get("sprite_index", -1)) != sprite_index:
		return 0
	var visible_rows: Variant = visibility_rule.get("rows", PackedByteArray())
	if not visible_rows is PackedByteArray:
		return 0xFF
	var mask := 0
	for py in 8:
		var screen_y := sprite_y + roundi(position.y) + py
		if screen_y < visible_rows.size() and visible_rows[screen_y] != 0:
			mask |= 1 << py
	return mask


func _get_shared_sprite_tile_image(pattern_offset: int, subpalette: int,
		flip_x: bool, palette_key: String) -> Image:
	var tile_key := "%d:%d:%d:%s" % [
		pattern_offset, subpalette, 1 if flip_x else 0, palette_key,
	]
	var cached_variant: Variant = _shared_sprite_tile_images.get(tile_key)
	if cached_variant is Image:
		return cached_variant
	if _shared_sprite_tile_images.size() >= MAX_SHARED_SPRITE_TILE_CACHE_ENTRIES:
		return null
	var tile_image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	if tile_image == null or tile_image.is_empty():
		return null
	tile_image.fill(Color(0, 0, 0, 0))
	for py in 8:
		var low_plane := int(_chr[pattern_offset + py])
		var high_plane := int(_chr[pattern_offset + 8 + py])
		for px in 8:
			var source_x := 7 - px if flip_x else px
			var bit := 7 - source_x
			var color_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
			if color_index == 0:
				continue
			var palette_slot := subpalette * 4 + color_index
			tile_image.set_pixel(px, py, _color_for_palette_slot(palette_slot, color_index))
	_shared_sprite_tile_images[tile_key] = tile_image
	return tile_image


func _blend_visible_sprite_rows(image: Image, tile_image: Image, sprite_x: int,
		sprite_y: int, visible_row_mask: int) -> void:
	var left := maxi(0, sprite_x)
	var right := mini(NES_WIDTH, sprite_x + 8)
	if left >= right:
		return
	var source_x := left - sprite_x
	var run_start := -1
	# Blend consecutive rows as blocks so OAM scanline limits preserve the
	# source-visible row mask without returning to per-pixel GDScript writes.
	for py in range(9):
		var row_visible := py < 8 and (visible_row_mask & (1 << py)) != 0
		if row_visible:
			var candidate_output_y := sprite_y + py
			row_visible = candidate_output_y >= 0 and candidate_output_y < NES_HEIGHT
		if row_visible:
			if run_start < 0:
				run_start = py
		elif run_start >= 0:
			var run_end := py
			var blend_output_y := sprite_y + run_start
			image.blend_rect(tile_image,
				Rect2i(source_x, run_start, right - left, run_end - run_start),
				Vector2i(left, blend_output_y))
			run_start = -1


func _palette_visual_key() -> String:
	var result := PackedStringArray()
	for color in sprite_palette_rgb:
		result.append("%08X" % color.to_rgba32())
	return ",".join(result)


func _find_beat(tick: int) -> Dictionary:
	for beat in _beats:
		var start := int(beat.get("start_tick", 0))
		var duration := int(beat.get("hold_ticks", 0))
		if tick >= start and tick < start + duration:
			return beat
	return _beats.back()


func _static_pose_from_commands(commands_variant: Variant) -> Dictionary:
	if not commands_variant is Array:
		return {}
	var state := {
		"initial_x": 0,
		"initial_y": 0,
		"mirror_h": false,
		"sprite_frame_cpu_address": "",
	}
	for command_variant: Variant in commands_variant:
		if not command_variant is Dictionary:
			continue
		var command: Dictionary = command_variant
		match str(command.get("kind", "")):
			"set_y_x":
				state["initial_y"] = int(command.get("y", 0))
				state["initial_x"] = int(command.get("x", 0))
			"set_y":
				state["initial_y"] = int(command.get("value", 0))
			"set_x":
				state["initial_x"] = int(command.get("value", 0))
			"mirror_on":
				state["mirror_h"] = true
			"mirror_off":
				state["mirror_h"] = false
			"sprite_frame":
				state["sprite_frame_cpu_address"] = str(command.get("frame_cpu_address", ""))
			"exit":
				break
	if str(state["sprite_frame_cpu_address"]).is_empty():
		return {}
	return state


func _color_for_palette_slot(slot: int, pixel_index: int) -> Color:
	if slot >= 0 and slot < sprite_palette_rgb.size():
		return sprite_palette_rgb[slot]
	# Geometry fallback only if the project-owned palette resource is unavailable.
	var shade := float(pixel_index) / 3.0
	return Color(shade, shade, shade, 1.0)


func _hex_bytes(value: String) -> PackedByteArray:
	var result := PackedByteArray()
	for part in value.split(" ", false):
		result.append(_hex_byte(part))
	return result


func _hex_byte(value: String) -> int:
	return value.trim_prefix("0x").hex_to_int() & 0xFF


func _signed_byte(value: int) -> int:
	var byte_value := value & 0xFF
	return byte_value - 0x100 if byte_value >= 0x80 else byte_value


func _draw() -> void:
	if _texture != null:
		draw_texture(_texture, Vector2.ZERO)
