extends Node2D
class_name RomBg08SpriteOamComposer
## Source-driven shared NES OAM compositor for the opening BG08 C1/82 pair.
## Runtime input is ROM-derived project data, never the .nes file or a capture.

const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const TIMING_PATH := "res://reference/rom_extract/intro/animation_timing_entry.json"
const FRAMES_PATH := "res://reference/rom_extract/intro/sprite_frames_entry.json"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const OAM_SLOT_COUNT := 64
const OAM_BYTES := OAM_SLOT_COUNT * 4
const OAM_UNFILLED_SLOT_Y := 0xF8
const NES_WIDTH := 256
const NES_HEIGHT := 240
const OAM_START_SOURCE_OFFSET := 0x10
const OAM_LENGTH_SOURCE_OFFSET := 0x11
const POSITION_Y_OFFSET := 0x04
const POSITION_X_OFFSET := 0x06
const VELOCITY_Y_OFFSET := 0x08
const ACCELERATION_Y_OFFSET := 0x0A
const VELOCITY_X_OFFSET := 0x0C
const ACCELERATION_X_OFFSET := 0x0E
const MOTION_ENABLED_FLAG := 0x20

var last_error := ""
var initialized := false
var _chr := PackedByteArray()
var _nes_rgb := PackedByteArray()
var _palette_rgb: PackedColorArray = PackedColorArray()
var _frames_by_address: Dictionary = {}
var _tracks: Array[Dictionary] = []
var _oam := PackedByteArray()
var _slot_owner: Array[String] = []
var _start_source_frame := -1
var _last_source_frame := -1
var _image_texture: ImageTexture
var _last_rendered_oam_key := ""
var _render_updates_suppressed := false
var _render_update_pending := false


func configure(animation_ids: Array, start_source_frame: int) -> bool:
	_reset()
	if animation_ids.size() != 2 or int(animation_ids[0]) != 0xC1 or int(animation_ids[1]) != 0x82:
		return _fail("BG08 OAM compositor accepts only the ROM FB order C1, 82.")
	if start_source_frame < 0 or not _load_source_data():
		return false
	var slot_cursor := 0
	for animation_id in ["0xC1", "0x82"]:
		var track := _load_animation_track(animation_id, slot_cursor)
		if track.is_empty():
			return false
		_tracks.append(track)
		slot_cursor = (slot_cursor + int(track["allocation_sprite_count"])) % OAM_SLOT_COUNT
	if slot_cursor != 6:
		return _fail("BG08 max-frame OAM capacities must wrap from 70 sprites to slot 6.")
	_start_source_frame = start_source_frame
	_last_source_frame = start_source_frame - 1
	_oam.resize(OAM_BYTES)
	_oam.fill(0)
	_slot_owner.resize(OAM_SLOT_COUNT)
	_slot_owner.fill("")
	initialized = true
	return true


func advance_to_source_frame(source_frame: int) -> bool:
	if not initialized:
		return _fail("BG08 OAM compositor was not configured from ROM-derived data.")
	if source_frame < _start_source_frame:
		return true
	if source_frame <= _last_source_frame:
		return true
	for frame in range(_last_source_frame + 1, source_frame + 1):
		var relative_tick := frame - _start_source_frame
		if frame > _start_source_frame:
			for track_index in _tracks.size():
				var track: Dictionary = _tracks[track_index]
				if bool(track["active"]) and bool(track["motion_enabled"]):
					_integrate_track(track)
				_tracks[track_index] = track
		for track_index in _tracks.size():
			var track: Dictionary = _tracks[track_index]
			track["exit_this_tick"] = false
			track["pose_frame_updated_this_tick"] = false
			_apply_track_events(track, relative_tick)
			_tracks[track_index] = track
		for track_index in _tracks.size():
			var track: Dictionary = _tracks[track_index]
			if (bool(track["active"]) or bool(track["exit_this_tick"])) \
					and not str(track["frame_address"]).is_empty():
				_write_track_sprites(track)
				_tracks[track_index] = track
		_last_source_frame = frame
	_render_oam()
	return true


func set_fade_palette_bytes(palette_bytes: PackedByteArray) -> void:
	if palette_bytes.size() != 16 or _nes_rgb.size() != 192:
		return
	var replacement := PackedColorArray()
	for color_index in palette_bytes:
		var offset := (int(color_index) & 0x3F) * 3
		replacement.append(Color(
			float(_nes_rgb[offset]) / 255.0,
			float(_nes_rgb[offset + 1]) / 255.0,
			float(_nes_rgb[offset + 2]) / 255.0,
			1.0))
	if replacement != _palette_rgb:
		_palette_rgb = replacement
		if _image_texture != null:
			_render_oam()


## Diagnostic capture fast-forward: retain OAM state but defer texture composition
## until the requested source-frame checkpoint.
func set_render_updates_suppressed(suppressed: bool) -> void:
	if _render_updates_suppressed == suppressed:
		return
	_render_updates_suppressed = suppressed
	if not _render_updates_suppressed and _render_update_pending:
		_render_update_pending = false
		_render_oam()


func oam_bytes() -> PackedByteArray:
	return _oam.duplicate()


func sprite_composition_image() -> Image:
	if _image_texture == null:
		return null
	return _image_texture.get_image()


func debug_snapshot() -> Dictionary:
	var track_states: Array[Dictionary] = []
	for track in _tracks:
		track_states.append({
			"animation_id": str(track["animation_id"]),
			"active": bool(track["active"]),
			"frame_address": str(track["frame_address"]),
			"oam_start_slot": int(track["oam_start_slot"]),
			"allocation_sprite_count": int(track["allocation_sprite_count"]),
			"live_oam_extent_bytes": int((track["record"] as PackedByteArray)[OAM_LENGTH_SOURCE_OFFSET]),
			"live_oam_extent_sprites": int(track["record"][OAM_LENGTH_SOURCE_OFFSET]) >> 2,
			"oam_start_byte_offset_from_source_record": int(track["oam_start_slot"]) * 4,
			"oam_max_capacity_bytes_from_rom_frames": int(track["allocation_sprite_count"]) * 4,
			"record_bytes_hex": _record_hex(track),
			"position_y_q8_8": "$%04X" % _read_u16(track, POSITION_Y_OFFSET),
			"position_x_q8_8": "$%04X" % _read_u16(track, POSITION_X_OFFSET),
			"velocity_y_q8_8": "$%04X" % _read_u16(track, VELOCITY_Y_OFFSET),
			"velocity_x_q8_8": "$%04X" % _read_u16(track, VELOCITY_X_OFFSET),
		})
	return {
		"rom_sha256": SOURCE_ROM_SHA256,
		"display_source_frame": _last_source_frame,
		"animation_start_source_frame": _start_source_frame,
		"shared_oam_bytes_hex": _oam.hex_encode().to_upper(),
		"slot_owners": _slot_owner.duplicate(),
		"tracks": track_states,
		"composition_model": "ROM FB order; maximum pose counts determine FB slot starts, while each record keeps a live OAM extent that grows only when a pose writes past its end; motion deltas update every live tuple; ROM coordinate overflow toggles attribute $04/$08 markers; the $96F2 frame terminator fills unused live slots with Y=$F8 when record flag bit $08 is set.",
		"slot_5_status": "Source-derived tail: $82/$AE08 writes 55 descriptors into a 56-sprite live extent; $96F2 writes $F8 to the unused Y byte at $047C and motion at $91B4 moves it with the live span.",
	}


func _load_source_data() -> bool:
	_chr = FileAccess.get_file_as_bytes(CHR_PATH)
	_nes_rgb = FileAccess.get_file_as_bytes(NES_RGB_PATH)
	if _chr.size() != 131072 or _nes_rgb.size() != 192:
		return _fail("BG08 OAM compositor requires the checked 128 KiB CHR and FCEUX RGB palette resources.")
	var timing_data := _read_json(TIMING_PATH)
	var frames_data := _read_json(FRAMES_PATH)
	if timing_data.is_empty() or frames_data.is_empty():
		return false
	if str(timing_data.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(frames_data.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("BG08 animation manifests do not match the supplied Turkish ROM hash.")
	for frame_variant: Variant in frames_data.get("frames", []):
		if frame_variant is Dictionary:
			var frame: Dictionary = frame_variant
			_frames_by_address[str(frame.get("cpu_address", "")).to_lower()] = frame
	return true


func _load_animation_track(animation_id: String, start_slot: int) -> Dictionary:
	var timing_document := _read_json(TIMING_PATH)
	var animation: Dictionary = {}
	for animation_variant: Variant in timing_document.get("animations", []):
		if animation_variant is Dictionary \
				and str(animation_variant.get("animation_id", "")).to_upper() == animation_id.to_upper():
			animation = animation_variant
			break
	if animation.is_empty() or int(animation.get("prg_bank", -1)) != 10:
		_fail("ROM animation %s is missing from bank 10 timing metadata." % animation_id)
		return {}
	var command_values: Variant = animation.get("commands", [])
	if not command_values is Array:
		_fail("ROM animation %s has no command stream." % animation_id)
		return {}
	var commands: Array[Dictionary] = []
	for command_variant: Variant in command_values:
		if command_variant is Dictionary:
			commands.append((command_variant as Dictionary).duplicate(true))
	var first_frame_address := ""
	for command in commands:
		if int(command.get("at_relative_tick", -1)) == 0 \
				and str(command.get("kind", "")) == "sprite_frame":
			first_frame_address = str(command.get("frame_cpu_address", "")).to_lower()
			break
	var first_frame: Dictionary = _frames_by_address.get(first_frame_address, {})
	var first_sprites: Variant = first_frame.get("sprites", [])
	if first_frame.is_empty() or not first_sprites is Array or first_sprites.is_empty():
		_fail("ROM animation %s has no decoded initial frame descriptors." % animation_id)
		return {}
	var maximum_sprite_count := 0
	var beat_values: Variant = animation.get("beats", [])
	if not beat_values is Array:
		_fail("ROM animation %s has no decoded pose timeline." % animation_id)
		return {}
	for beat_variant: Variant in beat_values:
		if not beat_variant is Dictionary:
			continue
		var beat: Dictionary = beat_variant
		var frame_address := str(beat.get("sprite_frame_cpu_address", "")).to_lower()
		var beat_frame: Dictionary = _frames_by_address.get(frame_address, {})
		var beat_sprites: Variant = beat_frame.get("sprites", [])
		if beat_sprites is Array:
			maximum_sprite_count = maxi(maximum_sprite_count, beat_sprites.size())
	if maximum_sprite_count <= 0:
		_fail("ROM animation %s has no sprite descriptors in its decoded poses." % animation_id)
		return {}
	var binary_path := "res://reference/rom_extract/intro/animation_%s.bin" % animation_id.trim_prefix("0x").to_upper()
	var animation_binary := FileAccess.get_file_as_bytes(binary_path)
	if animation_binary.is_empty() or not _verify_command_bytes(animation, commands, animation_binary):
		_fail("ROM animation %s command bytes differ from its preserved source span." % animation_id)
		return {}
	var initial_flag := 0xA9
	var record := PackedByteArray()
	record.resize(32)
	record.fill(0)
	record[0] = initial_flag
	record[OAM_START_SOURCE_OFFSET] = (start_slot * 4) & 0xFF
	record[OAM_LENGTH_SOURCE_OFFSET] = (first_sprites.size() * 4) & 0xFF
	return {
		"animation_id": animation_id,
		"commands": commands,
		"terminal": (animation.get("terminal", {}) as Dictionary).duplicate(true),
		"initial_flag": initial_flag,
		"record": record,
		"active": true,
		"exit_this_tick": false,
		"motion_enabled": false,
		"frame_address": "",
		"oam_start_slot": start_slot,
		"allocation_sprite_count": maximum_sprite_count,
		"live_oam_extent_sprite_count": first_sprites.size(),
		"last_written_sprites": 0,
		"pose_frame_updated_this_tick": false,
	}


func _verify_command_bytes(animation: Dictionary, commands: Array[Dictionary], binary: PackedByteArray) -> bool:
	var start_address := _parse_hex_int(str(animation.get("start_cpu_address", "")))
	var start_file_offset := 0x14010 + start_address - 0xA000
	for command in commands:
		var command_bytes := _hex_bytes(str(command.get("raw_hex", "")))
		if command_bytes.is_empty():
			continue
		var absolute_offset := _parse_hex_int(str(command.get("file_offset", "")))
		var binary_offset := absolute_offset - start_file_offset
		if binary_offset < 0 or binary_offset + command_bytes.size() > binary.size():
			continue
		if binary.slice(binary_offset, binary_offset + command_bytes.size()) != command_bytes:
			push_error("ROM command byte mismatch for %s at %s: expected %s, extracted %s" % [
				str(command.get("kind", "")), str(command.get("file_offset", "")),
				command_bytes.hex_encode(), binary.slice(binary_offset, binary_offset + command_bytes.size()).hex_encode()])
			return false
		if str(command.get("kind", "")) == "set_physics":
			var physics_bytes := _hex_bytes(str(command.get("physics_raw_hex", "")))
			if physics_bytes.size() != 3 or command_bytes.slice(1, 4) != physics_bytes:
				return false
	return true


func _apply_track_events(track: Dictionary, relative_tick: int) -> void:
	if not bool(track["active"]):
		return
	var effective_tick := relative_tick
	var terminal: Dictionary = track["terminal"]
	if str(terminal.get("kind", "")) == "repeat_cycle":
		var cycle_start := int(terminal.get("cycle_start_tick", -1))
		var cycle_length := int(terminal.get("cycle_length_ticks", 0))
		if cycle_start >= 0 and cycle_length > 0 and relative_tick >= cycle_start:
			effective_tick = cycle_start + posmod(relative_tick - cycle_start, cycle_length)
	for command in track["commands"]:
		if int(command.get("at_relative_tick", -1)) != effective_tick:
			continue
		match str(command.get("kind", "")):
			"set_y_x":
				_write_u16(track, POSITION_Y_OFFSET, _signed_byte(int(command.get("y", 0))) << 8)
				_write_u16(track, POSITION_X_OFFSET, _signed_byte(int(command.get("x", 0))) << 8)
			"set_physics":
				_apply_f7(track, _hex_bytes(str(command.get("physics_raw_hex", ""))))
			"sprite_frame":
				track["frame_address"] = str(command.get("frame_cpu_address", "")).to_lower()
				track["pose_frame_updated_this_tick"] = true
			"exit":
				track["active"] = false
				track["exit_this_tick"] = true
				track["motion_enabled"] = false
				track["record"][0x00] = 0


func _apply_f7(track: Dictionary, operands: PackedByteArray) -> void:
	if operands.size() != 3:
		return
	var packed_vertical := int(operands[0]) >> 5
	var vertical_fraction := 0x80 if (int(operands[0]) & 0x10) != 0 else 0
	var vertical_integer := packed_vertical
	if (packed_vertical & 0x04) != 0:
		vertical_integer |= 0xF8
	_write_u16(track, VELOCITY_Y_OFFSET, vertical_fraction | (vertical_integer << 8))
	if (packed_vertical & 0x04) != 0:
		# The ROM's sign-extended vertical branch exits before the horizontal
		# unpacker. Its retained horizontal/acceleration bytes are intentional.
		pass
	else:
		track["record"][ACCELERATION_Y_OFFSET] = int(operands[1])
		var packed_horizontal := (int(operands[0]) & 0x0F) >> 1
		var horizontal_fraction := 0x80 if (int(operands[0]) & 0x01) != 0 else 0
		var horizontal_integer := packed_horizontal
		var horizontal_acceleration := int(operands[2])
		if (packed_horizontal & 0x04) != 0:
			horizontal_integer |= 0xF8
			horizontal_acceleration = (-horizontal_acceleration) & 0xFF
		_write_u16(track, VELOCITY_X_OFFSET, horizontal_fraction | (horizontal_integer << 8))
		track["record"][ACCELERATION_X_OFFSET] = horizontal_acceleration
		track["record"][0x0B] = 0
		track["record"][0x0F] = 0
	track["motion_enabled"] = true
	track["record"][0x00] = int(track["initial_flag"]) | MOTION_ENABLED_FLAG


func _integrate_track(track: Dictionary) -> void:
	var previous_y := _screen_position(_read_u16(track, POSITION_Y_OFFSET))
	var previous_x := _screen_position(_read_u16(track, POSITION_X_OFFSET))
	_integrate_axis(track, POSITION_Y_OFFSET, VELOCITY_Y_OFFSET, ACCELERATION_Y_OFFSET)
	_integrate_axis(track, POSITION_X_OFFSET, VELOCITY_X_OFFSET, ACCELERATION_X_OFFSET)
	var delta_y := _screen_position(_read_u16(track, POSITION_Y_OFFSET)) - previous_y
	var delta_x := _screen_position(_read_u16(track, POSITION_X_OFFSET)) - previous_x
	if delta_x != 0 or delta_y != 0:
		_move_live_oam_span(track, delta_y, delta_x)


## ROM $91B4-$91F1 applies integrated pixel deltas to every tuple in the
## animation record's live OAM extent, including entries not written by its pose.
func _move_live_oam_span(track: Dictionary, delta_y: int, delta_x: int) -> void:
	var start_slot := int(track["oam_start_slot"])
	var allocation_count := int((track["record"] as PackedByteArray)[OAM_LENGTH_SOURCE_OFFSET]) >> 2
	for allocation_index in allocation_count:
		var slot := posmod(start_slot + allocation_index, OAM_SLOT_COUNT)
		var byte_offset := slot * 4
		var sprite_y := int(_oam[byte_offset]) + delta_y
		var sprite_x := int(_oam[byte_offset + 3]) + delta_x
		var attributes := int(_oam[byte_offset + 2])
		if sprite_y < 0 or sprite_y > 0xFF:
			attributes ^= 0x08
		if sprite_x < 0 or sprite_x > 0xFF:
			attributes ^= 0x04
		_oam[byte_offset] = sprite_y & 0xFF
		_oam[byte_offset + 2] = attributes
		_oam[byte_offset + 3] = sprite_x & 0xFF


func _integrate_axis(track: Dictionary, position_offset: int, velocity_offset: int,
			acceleration_offset: int) -> void:
	var acceleration := _signed_byte(int(track["record"][acceleration_offset]))
	var velocity := (_read_u16(track, velocity_offset) + acceleration) & 0xFFFF
	_write_u16(track, velocity_offset, velocity)
	_write_u16(track, position_offset, _read_u16(track, position_offset) + velocity)


func _write_track_sprites(track: Dictionary) -> void:
	var frame: Dictionary = _frames_by_address.get(str(track["frame_address"]), {})
	if frame.is_empty():
		return
	var sprites: Variant = frame.get("sprites", [])
	if not sprites is Array:
		return
	var origin_x := _screen_position(_read_u16(track, POSITION_X_OFFSET))
	var origin_y := _screen_position(_read_u16(track, POSITION_Y_OFFSET))
	var start_slot := int(track["oam_start_slot"])
	for sprite_index in sprites.size():
		var sprite_variant: Variant = sprites[sprite_index]
		if not sprite_variant is Dictionary:
			continue
		var sprite: Dictionary = sprite_variant
		var slot := posmod(start_slot + sprite_index, OAM_SLOT_COUNT)
		var byte_offset := slot * 4
		var attributes := int(sprite.get("palette_low_bits", 0)) & 0x03
		if bool(sprite.get("flip_h_bit", false)):
			attributes |= 0x40
		var sprite_y := origin_y + int(sprite.get("y_offset_from_animation", 0))
		var sprite_x := origin_x + int(sprite.get("x_offset_from_animation", 0))
		# ROM $9541 sets marker bits when the unwrapped descriptor coordinate
		# leaves the byte range. The $A8CE DMA copier later hides marked entries
		# by substituting Y=$F8; keep the raw wrapped coordinates in this shadow.
		if sprite_x < 0 or sprite_x > 0xFF:
			attributes |= 0x04
		if sprite_y < 0 or sprite_y > 0xFF:
			attributes |= 0x08
		_oam[byte_offset] = sprite_y & 0xFF
		_oam[byte_offset + 1] = _hex_byte(str(sprite.get("tile_id", "0x00")))
		_oam[byte_offset + 2] = attributes
		_oam[byte_offset + 3] = sprite_x & 0xFF
		_slot_owner[slot] = "%s[%d]" % [str(track["animation_id"]), sprite_index]
	track["last_written_sprites"] = sprites.size()
	if not bool(track.get("pose_frame_updated_this_tick", false)):
		return
	var record: PackedByteArray = track["record"]
	if (int(record[0]) & 0x08) == 0:
		# $96F2 sets the ready bit and takes $9727, recording the live span
		# from the record's OAM start to the cursor after this pose.
		record[0] = int(record[0]) | 0x08
		_set_live_oam_extent(track, sprites.size(), record)
		return
	var live_sprite_count := int(record[OAM_LENGTH_SOURCE_OFFSET]) >> 2
	if sprites.size() > live_sprite_count:
		# A pose that writes past the old end takes the $9727 path and grows the
		# live extent to its current cursor; it does not fill a tail.
		_set_live_oam_extent(track, sprites.size(), record)
		return
	if sprites.size() == live_sprite_count:
		return
	# The live span already covers this pose. $96F2 fills the remaining tuple Y
	# bytes, preserving its previous tile, attributes, and X coordinate.
	for allocation_index in range(sprites.size(), live_sprite_count):
		var slot := posmod(start_slot + allocation_index, OAM_SLOT_COUNT)
		_oam[slot * 4] = OAM_UNFILLED_SLOT_Y
	track["record"] = record


func _set_live_oam_extent(track: Dictionary, sprite_count: int,
		record: PackedByteArray) -> void:
	var extent_bytes := (sprite_count * 4) & 0xFF
	record[OAM_LENGTH_SOURCE_OFFSET] = extent_bytes
	track["record"] = record
	track["live_oam_extent_sprite_count"] = sprite_count


func _render_oam() -> void:
	if _render_updates_suppressed:
		_render_update_pending = true
		return
	var key_parts := PackedStringArray([_oam.hex_encode()])
	for owner in _slot_owner:
		key_parts.append(owner)
	for track in _tracks:
		key_parts.append("%s:%s:%s" % [
			str(track.get("animation_id", "")),
			str(track.get("frame_address", "")),
			"1" if bool(track.get("active", false)) else "0",
		])
	for color in _palette_rgb:
		key_parts.append("%08X" % color.to_rgba32())
	var render_key := "\n".join(key_parts)
	if render_key == _last_rendered_oam_key:
		return
	var image := Image.create(NES_WIDTH, NES_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# NES OAM index zero has highest priority, so paint larger indices first.
	for sprite_index in range(OAM_SLOT_COUNT - 1, -1, -1):
		var byte_offset := sprite_index * 4
		var sprite_y := int(_oam[byte_offset])
		var tile := int(_oam[byte_offset + 1])
		var attributes := int(_oam[byte_offset + 2])
		var sprite_x := int(_oam[byte_offset + 3])
		if (attributes & 0x0C) != 0:
			# ROM $A8CE replaces Y with $F8 in the DMA page for any OAM entry
			# marked by $9541's X/Y coordinate-overflow bits.
			sprite_y = 0xF8
		var bank_slot := tile >> 6
		var frame_address := _last_frame_address_for_slot(sprite_index)
		var frame: Dictionary = _frames_by_address.get(frame_address, {})
		var selectors := _hex_bytes(str(frame.get("chr_selectors_hex", "")))
		if selectors.size() != 4:
			continue
		var pattern_offset := int(selectors[bank_slot]) * 1024 + (tile & 0x3F) * 16
		if pattern_offset < 0 or pattern_offset + 16 > _chr.size():
			continue
		var top_y := (sprite_y + 1) & 0xFF
		for py in 8:
			var screen_y := top_y + py
			if screen_y < 0 or screen_y >= NES_HEIGHT:
				continue
			var source_y := 7 - py if (attributes & 0x80) != 0 else py
			var low_plane := int(_chr[pattern_offset + source_y])
			var high_plane := int(_chr[pattern_offset + 8 + source_y])
			for px in 8:
				var screen_x := sprite_x + px
				if screen_x < 0 or screen_x >= NES_WIDTH:
					continue
				var source_x := 7 - px if (attributes & 0x40) != 0 else px
				var bit := 7 - source_x
				var color_index := ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
				if color_index == 0:
					continue
				var palette_slot := (attributes & 0x03) * 4 + color_index
				if palette_slot < 0 or palette_slot >= _palette_rgb.size():
					continue
				image.set_pixel(screen_x, screen_y, _palette_rgb[palette_slot])
	_image_texture = ImageTexture.create_from_image(image)
	_last_rendered_oam_key = render_key
	queue_redraw()


func _last_frame_address_for_slot(slot: int) -> String:
	# Every BG08 C1/82 frame uses the same four ROM CHR selectors. Keep the
	# slot ownership lookup explicit because the shared OAM wraps and overwrites.
	var owner := _slot_owner[slot] if slot >= 0 and slot < _slot_owner.size() else ""
	if owner.is_empty():
		return "0xADF0"
	var animation_id := owner.substr(0, owner.find("["))
	for track in _tracks:
		if str(track["animation_id"]) == animation_id:
			return str(track["frame_address"])
	return "0xADF0"


func _record_hex(track: Dictionary) -> String:
	return (track["record"] as PackedByteArray).hex_encode().to_upper()


func _read_u16(track: Dictionary, offset: int) -> int:
	var record: PackedByteArray = track["record"]
	return int(record[offset]) | (int(record[offset + 1]) << 8)


func _write_u16(track: Dictionary, offset: int, value: int) -> void:
	var record: PackedByteArray = track["record"]
	var wrapped := value & 0xFFFF
	record[offset] = wrapped & 0xFF
	record[offset + 1] = (wrapped >> 8) & 0xFF
	track["record"] = record


func _screen_position(raw_position: int) -> int:
	var signed_position := raw_position - 0x10000 if raw_position >= 0x8000 else raw_position
	return int(floor(float(signed_position) / 128.0))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("Missing ROM-derived BG08 source data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_fail("Invalid JSON object in %s" % path)
		return {}
	return parsed


func _hex_bytes(value: String) -> PackedByteArray:
	var result := PackedByteArray()
	for part in value.split(" ", false):
		result.append(_hex_byte(part))
	return result


func _hex_byte(value: String) -> int:
	return value.trim_prefix("0x").hex_to_int() & 0xFF


func _parse_hex_int(value: String) -> int:
	var normalized := value.strip_edges().to_lower()
	if normalized.begins_with("0x"):
		normalized = normalized.substr(2)
	return normalized.hex_to_int()


func _signed_byte(value: int) -> int:
	var wrapped := value & 0xFF
	return wrapped - 0x100 if wrapped >= 0x80 else wrapped


func _fail(message: String) -> bool:
	last_error = message
	push_error(message)
	return false


func _reset() -> void:
	last_error = ""
	initialized = false
	_chr.clear()
	_nes_rgb.clear()
	_palette_rgb.clear()
	_frames_by_address.clear()
	_tracks.clear()
	_oam.clear()
	_slot_owner.clear()
	_start_source_frame = -1
	_last_source_frame = -1
	_image_texture = null
	_last_rendered_oam_key = ""


func _draw() -> void:
	if _image_texture != null:
		draw_texture(_image_texture, Vector2.ZERO)
