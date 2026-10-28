extends Node2D
class_name FirstCommandActorSourcePresenter
## Builds the frozen first-command lineup from target-ROM source streams.
##
## This is an endpoint presenter, not a route-time actor state producer. It
## starts at scenario $44 / animation $5C, executes the source $F1 actor setup,
## resolves the held $F7 descriptors and stopped $A38A motion stream, then
## feeds the live records to GameplayRomActorOamBuilder. Runtime inputs are
## project-owned ROM extracts and CHR bytes only; captures are never opened.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_DIR := "res://reference/rom_extract/gameplay/first_command_actors/"
const MANIFEST_PATH := SOURCE_DIR + "manifest.json"
const ANIMATION_PACKETS_PATH := SOURCE_DIR + "animation_5C_actor_packets_9357.bin"
const RECORD_POINTERS_PATH := SOURCE_DIR + "actor_record_pointer_table_88E4_00_03.bin"
const MOTION_POINTER_PATH := SOURCE_DIR + "motion_pointer_table_A1B4_00.bin"
const APPEARANCE_POINTERS_PATH := SOURCE_DIR + "appearance_pointer_table_AC47_CA_CD.bin"
const MOTION_SCRIPT_PATH := SOURCE_DIR + "motion_script_A38A_A390.bin"
const APPEARANCE_SCRIPTS_PATH := SOURCE_DIR + "appearance_scripts_B5AC_B5B3.bin"
const GRAPHIC_CLASS_PATH := SOURCE_DIR + "player_graphic_class_table_88F0_ids_00_22.bin"
const NORMAL_PLAYER_PALETTE_PATH := SOURCE_DIR + "normal_player_palette_table_B80C_ids_00_22.bin"
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const NES_RGB_PATH := "res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
const ACTOR_OAM_BUILDER_SCRIPT := preload("res://scripts/gameplay/gameplay_rom_actor_oam_builder.gd")
const OAM_SPRITE_LAYER_SCRIPT := preload("res://scripts/gameplay/rom_oam_sprite_layer.gd")

const EXPECTED_SOURCE_HASHES := {
	ANIMATION_PACKETS_PATH: "421e49f864693c445615f708234ce96bbca517cd7256a656dfe5eee3248d1603",
	RECORD_POINTERS_PATH: "6c89c1d4ea3c175d5f764d403da2f4bf0a5d1ad28e46ab9ee76ac930769819bc",
	MOTION_POINTER_PATH: "d3622cca6c3e26b9187ccbee16ef99a919d9528af65c87e1f5aaa3f89ee56025",
	APPEARANCE_POINTERS_PATH: "b94da4db1c0b491e9a5ef8279b17e45157a773b88e31091cf3c966f4a97c87ee",
	MOTION_SCRIPT_PATH: "95a66c8108f14acbb8740fd154087efd6230f204ceec3dcf198c3ac07ac31e7f",
	APPEARANCE_SCRIPTS_PATH: "271792914b8d88c9f0df0d1bb6571ebf4bbec5785eadbb2b934872fedc155af2",
	GRAPHIC_CLASS_PATH: "9c159d7a0b3c4737eaf6b50c97e870a5e98e796b0fb0e88422fc207e990d59dd",
	NORMAL_PLAYER_PALETTE_PATH: "b6c3c9045f74bdf720ec8455dd283cd97619087758f523b28620e353f76a8732",
	CHR_PATH: "721579f3a3dc2042534de98b24135371fc379958711a168a6861c989a10d85ad",
	NES_RGB_PATH: "da30843b331e2e4474395866bc9871fcd60a7d716b3c8ee5ce3c89ee46e8c91e",
}

const ACTOR_RECORD_BYTES := 21
const OAM_BYTES := 256
const ACTOR_RECORD_BASES := [0x0547, 0x055C, 0x0571, 0x0586]
const ACTOR_ORDER := [0, 1, 2, 3, 4, 5]

## Draw the source-defined frame-8953 held pose. Shared route state remains an
## explicit caller input: in particular the route establishes mirror $40 and
## the palette record index separately from this animation's actor packets.
## `universal_color` is inherited from the active background palette because
## the normal-player writer deliberately leaves each sprite slot 0 untouched.
func configure_endpoint_pose(
		player_id: int,
		palette_record_index: int,
		mirror_mode: int,
		universal_color: int,
		scroll_x: int = 0,
		clip_y_min: int = 0,
		clip_y_max: int = 0xFF
) -> bool:
	last_error = ""
	last_oam_bytes = PackedByteArray()
	last_actor_records.clear()
	last_sprite_palette = PackedByteArray()
	last_sprite_chr_banks.clear()
	last_build_result.clear()
	if not _ensure_renderer():
		return false
	if not _load_source_resources():
		return false
	if player_id < 0 or player_id >= _graphic_class_bytes.size():
		return _fail("Player ID is outside the ROM graphic-class table.")
	if palette_record_index < 0 or palette_record_index * 5 + 5 > _normal_palette_bytes.size():
		return _fail("Palette index is outside the ROM normal-player palette table.")
	if mirror_mode < 0 or mirror_mode > 0xFF or scroll_x < 0 or scroll_x > 0xFF \
			or clip_y_min < 0 or clip_y_min > 0xFF or clip_y_max < 0 or clip_y_max > 0xFF \
			or universal_color < 0 or universal_color > 0x3F:
		return _fail("Shared route and palette inputs must be valid NES byte values.")

	var animation_state := _decode_animation_source()
	if not bool(animation_state.get("ok", false)):
		return _fail(str(animation_state.get("error", "Could not decode animation $5C.")))
	var actors_by_index: Dictionary = animation_state["actors_by_index"]
	var ordered_actors: Array[Dictionary] = []
	for actor_index in ACTOR_ORDER:
		if not actors_by_index.has(actor_index):
			continue
		var actor: Dictionary = actors_by_index[actor_index]
		var record_bytes: PackedByteArray = actor["record_bytes"]
		if (int(record_bytes[0]) & 0x80) != 0:
			ordered_actors.append(actor)
	if ordered_actors.size() != 3:
		return _fail("Animation $5C did not produce its three active source actors.")

	var graphic_selector := int(_graphic_class_bytes[player_id])
	var sprite_chr_banks: Array[int] = animation_state["sprite_chr_banks"]
	var palette_result := _build_sprite_palette(palette_record_index, universal_color)
	if not bool(palette_result.get("ok", false)):
		return _fail(str(palette_result.get("error", "Could not resolve the ROM sprite palette.")))
	var initial_oam := _new_hidden_oam()
	var builder := ACTOR_OAM_BUILDER_SCRIPT.new() as GameplayRomActorOamBuilder
	var build_result: Dictionary = builder.build_oam(
		ordered_actors,
		graphic_selector,
		mirror_mode,
		scroll_x,
		clip_y_min,
		clip_y_max,
		initial_oam
	)
	if not bool(build_result.get("ok", false)):
		return _fail("ROM actor OAM build failed: " + str(build_result.get("error", "unknown error")))
	var oam_bytes: PackedByteArray = build_result["oam_bytes"]
	var sprite_palette: PackedByteArray = palette_result["ppu_bytes"]
	if not _oam_layer.configure(_chr_bytes, _nes_rgb_bytes, sprite_palette, oam_bytes, sprite_chr_banks):
		return _fail("ROM CHR/OAM renderer rejected its inputs: " + _oam_layer.last_error)

	last_actor_records = ordered_actors.duplicate(true)
	last_oam_bytes = oam_bytes
	last_sprite_palette = sprite_palette
	last_sprite_chr_banks = sprite_chr_banks.duplicate()
	last_build_result = build_result.duplicate(true)
	last_source_state = {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"scenario": 0x44,
		"animation": 0x5C,
		"player_id": player_id,
		"graphic_selector": graphic_selector,
		"palette_record_index": palette_record_index,
		"palette_record_bytes": palette_result["record_bytes"],
		"sprite_palette_bytes": sprite_palette,
		"sprite_chr_banks_1k": sprite_chr_banks.duplicate(),
		"actor_record_indexes_draw_order": [0, 1, 3],
		"active_actor_count": ordered_actors.size(),
		"sprites_written": int(build_result["sprites_written"]),
		"mirror_mode": mirror_mode,
		"scroll_x": scroll_x,
		"clip_y_min": clip_y_min,
		"clip_y_max": clip_y_max,
		"universal_color_source": "caller-supplied background palette; player palette writer leaves slot 0 unchanged",
		"scope": "frozen scenario-$44 animation-$5C endpoint pose; no earlier route animation is simulated",
	}
	visible = true
	queue_redraw()
	return true


func source_state_summary() -> Dictionary:
	return last_source_state.duplicate(true)


var last_error := ""
var last_oam_bytes := PackedByteArray()
var last_actor_records: Array[Dictionary] = []
var last_sprite_palette := PackedByteArray()
var last_sprite_chr_banks: Array[int] = []
var last_build_result: Dictionary = {}
var last_source_state: Dictionary = {}

var _oam_layer: GameplayRomOamSpriteLayer
var _source_data: Dictionary = {}
var _source_loaded := false
var _chr_bytes := PackedByteArray()
var _nes_rgb_bytes := PackedByteArray()
var _record_pointer_bytes := PackedByteArray()
var _motion_pointer_bytes := PackedByteArray()
var _appearance_pointer_bytes := PackedByteArray()
var _motion_script_bytes := PackedByteArray()
var _appearance_script_bytes := PackedByteArray()
var _animation_packet_bytes := PackedByteArray()
var _graphic_class_bytes := PackedByteArray()
var _normal_palette_bytes := PackedByteArray()


func _ready() -> void:
	visible = false
	_ensure_renderer()


func _ensure_renderer() -> bool:
	if _oam_layer != null:
		return true
	_oam_layer = OAM_SPRITE_LAYER_SCRIPT.new() as GameplayRomOamSpriteLayer
	if _oam_layer == null:
		return _fail("Could not instantiate the ROM OAM sprite renderer.")
	_oam_layer.name = "FirstCommandRomActorOam"
	_oam_layer.position = Vector2(0.0, -8.0)
	add_child(_oam_layer)
	return true


func _load_source_resources() -> bool:
	if _source_loaded:
		return true
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var manifest_variant: Variant = JSON.parse_string(manifest_text)
	if not manifest_variant is Dictionary:
		return _fail("First-command actor source manifest is missing or malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != "first-command-rom-actor-source-v1" \
			or str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("capture_or_screenshot_bytes_included", true)):
		return _fail("First-command actor source manifest does not match the verified ROM-only package.")

	for path_variant in EXPECTED_SOURCE_HASHES:
		var path := str(path_variant)
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty() or _sha256(bytes) != str(EXPECTED_SOURCE_HASHES[path_variant]):
			return _fail("ROM-derived actor resource failed its source hash check: " + path)
		_source_data[path] = bytes
	_animation_packet_bytes = _source_data[ANIMATION_PACKETS_PATH]
	_record_pointer_bytes = _source_data[RECORD_POINTERS_PATH]
	_motion_pointer_bytes = _source_data[MOTION_POINTER_PATH]
	_appearance_pointer_bytes = _source_data[APPEARANCE_POINTERS_PATH]
	_motion_script_bytes = _source_data[MOTION_SCRIPT_PATH]
	_appearance_script_bytes = _source_data[APPEARANCE_SCRIPTS_PATH]
	_graphic_class_bytes = _source_data[GRAPHIC_CLASS_PATH]
	_normal_palette_bytes = _source_data[NORMAL_PLAYER_PALETTE_PATH]
	_chr_bytes = _source_data[CHR_PATH]
	_nes_rgb_bytes = _source_data[NES_RGB_PATH]
	if _chr_bytes.size() != 0x20000 or _nes_rgb_bytes.size() != 192:
		return _fail("CHR-ROM or external 64-color NES RGB palette has an unexpected size.")
	_source_loaded = true
	return true


func _decode_animation_source() -> Dictionary:
	# Scenario $44's record selects animation $5C. The preserved stream starts at
	# that ROM pointer and is checked byte-for-byte by its manifest hash.
	if _animation_packet_bytes.size() != 26 or _animation_packet_bytes[0] != 0xF5 \
			or _animation_packet_bytes[1] != 0x80 or _animation_packet_bytes[2] != 0xF4:
		return {"ok": false, "error": "Animation $5C packet prefix differs from the audited ROM bytes."}
	var sprite_chr_banks: Array[int] = []
	for bank_offset in range(3, 7):
		sprite_chr_banks.append(int(_animation_packet_bytes[bank_offset]))
	var actors_by_index: Dictionary = {}
	var packet_cursor := 7
	while packet_cursor < _animation_packet_bytes.size():
		var opcode := int(_animation_packet_bytes[packet_cursor])
		if opcode == 0xF0:
			break
		if opcode != 0xF1 or packet_cursor + 6 > _animation_packet_bytes.size():
			return {"ok": false, "error": "Animation $5C contains an unexpected actor packet."}
		var actor_result := _build_actor_record(_animation_packet_bytes.slice(packet_cursor + 1, packet_cursor + 6))
		if not bool(actor_result.get("ok", false)):
			return {"ok": false, "error": str(actor_result.get("error", "Actor packet failed."))}
		var actor_index := int(actor_result["actor_index"])
		if actors_by_index.has(actor_index):
			return {"ok": false, "error": "Animation $5C constructs the same actor record more than once."}
		actors_by_index[actor_index] = actor_result["actor"]
		packet_cursor += 6
	if packet_cursor != _animation_packet_bytes.size() - 1 or _animation_packet_bytes[packet_cursor] != 0xF0:
		return {"ok": false, "error": "Animation $5C source stream is not terminated by its expected $F0."}
	return {"ok": true, "actors_by_index": actors_by_index, "sprite_chr_banks": sprite_chr_banks}


func _build_actor_record(packet: PackedByteArray) -> Dictionary:
	if packet.size() != 5:
		return {"ok": false, "error": "$F1 actor packet must contain five operands."}
	var motion_index := int(packet[0])
	var appearance_index := int(packet[1])
	var record_selector := int(packet[4])
	var actor_index := (record_selector & 0x1C) >> 2
	var active_flags := record_selector & 0x03
	if actor_index >= ACTOR_RECORD_BASES.size():
		return {"ok": false, "error": "$F1 packet selects a record outside preserved pointer table $88E4."}
	if motion_index != 0 or appearance_index < 0xCA or appearance_index > 0xCD:
		return {"ok": false, "error": "$F1 packet uses an actor script pointer outside the preserved source tables."}
	var record_pointer_offset := actor_index * 2
	var record_address := _read_u16(_record_pointer_bytes, record_pointer_offset)
	var motion_pointer := _read_u16(_motion_pointer_bytes, motion_index * 2)
	var appearance_pointer := _read_u16(_appearance_pointer_bytes, (appearance_index - 0xCA) * 2)
	if record_address < 0 or motion_pointer != 0xA38A or appearance_pointer < 0:
		return {"ok": false, "error": "$F1 pointer-table lookup failed its expected ROM address."}
	var record := PackedByteArray()
	record.resize(ACTOR_RECORD_BYTES)
	record.fill(0)
	record[0] = 0x80 | active_flags
	_write_u16(record, 1, motion_pointer)
	_write_u16(record, 3, appearance_pointer)
	# The two packet coordinate fields populate the actor's +$08/+0C lanes.
	record[8] = int(packet[2])
	record[12] = int(packet[3])

	if not _advance_motion_to_hold(record, motion_pointer):
		return {"ok": false, "error": "ROM motion stream did not resolve to the audited held state."}
	if not _apply_appearance_hold(record, appearance_pointer):
		return {"ok": false, "error": "ROM appearance stream did not resolve to the audited held descriptor."}
	return {
		"ok": true,
		"actor_index": actor_index,
		"actor": {"record_address": "0x%04X" % record_address, "record_bytes": record},
	}


func _advance_motion_to_hold(record: PackedByteArray, motion_pointer: int) -> bool:
	if motion_pointer != 0xA38A or _motion_script_bytes.size() != 7:
		return false
	if _motion_script_bytes[0] != 0x01 or _motion_script_bytes[1] != 0x01 \
			or _motion_script_bytes[2] != 0 or _motion_script_bytes[3] != 0 \
			or _motion_script_bytes[4] != 0 or _motion_script_bytes[5] != 0 \
			or _motion_script_bytes[6] != 0:
		return false
	# Opcode $01 consumes six bytes and adds zero X/Y deltas. The following $00
	# command holds by setting the secondary timer to $FF without moving the root.
	_write_u16(record, 1, motion_pointer + 6)
	record[0x11] = 0xFF
	return true


func _apply_appearance_hold(record: PackedByteArray, appearance_pointer: int) -> bool:
	if appearance_pointer < 0xB5AC or appearance_pointer > 0xB5B2 or (appearance_pointer & 1) != 0:
		return false
	var source_offset := appearance_pointer - 0xB5AC
	if source_offset + 2 > _appearance_script_bytes.size():
		return false
	if _appearance_script_bytes[source_offset] != 0xF7:
		return false
	record[0x12] = int(_appearance_script_bytes[source_offset + 1])
	# $F7 keeps the main stream cursor at its root and sets the appearance timer
	# to $FF; the descriptor therefore remains held for the endpoint pose.
	record[0x10] = 0xFF
	return true


func _build_sprite_palette(palette_record_index: int, universal_color: int) -> Dictionary:
	# Bank-$14 advances five bytes for each normal-player palette index.
	# Player ID $08 therefore resolves to $B80C + 5*$08 = $B834.
	var source_offset := palette_record_index * 5
	if source_offset + 5 > _normal_palette_bytes.size():
		return {"ok": false, "error": "Palette record's five-byte read window is outside the ROM table."}
	var record_bytes := _normal_palette_bytes.slice(source_offset, source_offset + 5)
	var ppu_bytes := PackedByteArray()
	ppu_bytes.resize(16)
	for subpalette in 4:
		var base := subpalette * 4
		ppu_bytes[base] = universal_color & 0x3F
		ppu_bytes[base + 1] = 0x0F
		ppu_bytes[base + 2] = int(record_bytes[subpalette + 1]) & 0x3F
		ppu_bytes[base + 3] = int(record_bytes[0]) & 0x3F
	return {"ok": true, "record_bytes": record_bytes, "ppu_bytes": ppu_bytes}


func _new_hidden_oam() -> PackedByteArray:
	var oam := PackedByteArray()
	oam.resize(OAM_BYTES)
	oam.fill(0)
	for sprite_index in 64:
		oam[sprite_index * 4] = 0xF8
	return oam


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	if offset < 0 or offset + 1 >= bytes.size():
		return -1
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _write_u16(bytes: PackedByteArray, offset: int, value: int) -> void:
	bytes[offset] = value & 0xFF
	bytes[offset + 1] = (value >> 8) & 0xFF


func _sha256(bytes: PackedByteArray) -> String:
	if bytes.is_empty():
		return ""
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	visible = false
	push_error(message)
	return false
