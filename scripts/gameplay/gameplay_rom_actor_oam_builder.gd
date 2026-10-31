extends RefCounted
class_name GameplayRomActorOamBuilder
## Interprets the supplied game's bank-$16 actor sprite streams.
##
## Inputs are live actor records, shared sprite selector/mirror/scroll state,
## the ROM Y clip window, and the caller's current 256-byte OAM shadow. This
## builder never reads the NES ROM file, endpoint snapshots, screenshots, or
## captured OAM. It returns updated OAM bytes for a caller-owned renderer.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/actor_oam/manifest.json"

const EXPECTED_SEGMENTS := {
	"sprite_engine_8000_8185": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_sprite_engine_8000_8185.bin",
		"cpu_start": 0x8000,
		"length": 0x186,
		"sha256": "4c8913c90c578a7924f74b8a94b91ff5ac4b059c7c9e7304d3f48a7ae67f9894",
	},
	"sprite_offsets_81d2_8239": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_sprite_offsets_81d2_8239.bin",
		"cpu_start": 0x81D2,
		"length": 0x68,
		"sha256": "7cbf389d7e51e0b550b95a5a11cbb6840320c95e3a25215f4553c2b15b06214d",
	},
	"sprite_descriptor_pointers_8280_82af": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_sprite_descriptor_pointers_8280_82af.bin",
		"cpu_start": 0x8280,
		"length": 0x30,
		"sha256": "307422f39c84f3bb3f12cd84879091d437582c0ed0d6d41adb2555c808ee6564",
	},
	"first_command_sprite_streams_842c_8979": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_first_command_sprite_streams_842c_8979.bin",
		"cpu_start": 0x842C,
		"length": 0x54E,
		"sha256": "90caefd89c50a5696347adba35d47b1b428829c4983051da11226f6bab1f1fa7",
	},
	"early_actor_descriptor_pointers_83f0_83f5": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_pointers_83f0_83f5.bin",
		"cpu_start": 0x83F0,
		"length": 0x06,
		"sha256": "c657102f38fc6bb3b6fdf8231ab95316f8eee01c64c9af2bda3a344876340b4f",
	},
	"early_actor_descriptor_b8_bb21_bb61": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_B8_BB21_BB61.bin",
		"cpu_start": 0xBB21,
		"length": 0x41,
		"sha256": "7e9cdcd5dbe2e732c0bdb4ba4a05328a26b36ce447d336702eaffdf46888b7dc",
	},
	"early_actor_descriptor_b9_bb62_bb6c": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_B9_BB62_BB6C.bin",
		"cpu_start": 0xBB62,
		"length": 0x0B,
		"sha256": "f8c2fe9650548e50d75b37eaca01d2a5e924e5f858718e6f0933cb816ebc615a",
	},
	"early_actor_descriptor_ba_bb6d_bb7b": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_BA_BB6D_BB7B.bin",
		"cpu_start": 0xBB6D,
		"length": 0x0F,
		"sha256": "40b0a4a2fd857fff6c29536666d2d2104acb9bf7ad2ce092eacd95aa62785803",
	},
}

const OAM_BYTES_REQUIRED := 64 * 4
const MAX_STREAM_STEPS := 4096

var last_error := ""

var _segments: Dictionary = {}
var _loaded := false


## Build OAM writes for active actor records in ROM draw order.
##
## Each actor dictionary has `record_bytes: PackedByteArray` containing the
## live 21-byte actor record. `record_address` is optional diagnostic metadata.
## `initial_oam` is the caller's current 256-byte shadow; out-of-range X sprites
## update only the source-defined hidden Y byte and preserve other bytes.
func build_oam(
		actor_records: Array,
		sprite_selector: int,
		mirror_mode: int,
		scroll_x: int,
		clip_y_min: int,
		clip_y_max: int,
		initial_oam: PackedByteArray,
		start_oam_byte_index: int = 0
) -> Dictionary:
	last_error = ""
	if not _ensure_source_resources():
		return _failure_result()
	if initial_oam.size() != OAM_BYTES_REQUIRED:
		return _fail_result("Actor OAM builder requires the caller's 256-byte OAM shadow.")
	if start_oam_byte_index < 0 or start_oam_byte_index > OAM_BYTES_REQUIRED \
			or start_oam_byte_index % 4 != 0:
		return _fail_result("Initial OAM byte index must be an aligned value from 0 through 256.")
	if sprite_selector < 0 or sprite_selector > 0xFF \
			or mirror_mode < 0 or mirror_mode > 0xFF \
			or scroll_x < 0 or scroll_x > 0xFF \
			or clip_y_min < 0 or clip_y_min > 0xFF \
			or clip_y_max < 0 or clip_y_max > 0xFF:
		return _fail_result("Shared sprite selector, mirror, scroll, and Y clip values must be bytes.")

	var output_oam := initial_oam.duplicate()
	var cursor := start_oam_byte_index
	var total_sprites_written := 0
	var actor_results: Array[Dictionary] = []
	for actor_variant in actor_records:
		if not actor_variant is Dictionary:
			return _fail_result("Actor draw list contains a non-dictionary entry.")
		var actor: Dictionary = actor_variant
		var record_variant: Variant = actor.get("record_bytes", null)
		if not record_variant is PackedByteArray or (record_variant as PackedByteArray).size() != 21:
			return _fail_result("Each actor needs exactly 21 live record bytes.")
		var record_bytes: PackedByteArray = record_variant
		var actor_result := _draw_actor(record_bytes, sprite_selector, mirror_mode,
			scroll_x, clip_y_min, clip_y_max, output_oam, cursor)
		if not bool(actor_result.get("ok", false)):
			return _fail_result("Actor %s: %s" % [str(actor.get("record_address", "?")), str(actor_result.get("error", "decode failed"))])
		actor_result["actor_address"] = str(actor.get("record_address", "?"))
		output_oam = actor_result["oam_bytes"]
		cursor = int(actor_result["next_oam_byte_index"])
		total_sprites_written += int(actor_result["sprites_written"])
		actor_result.erase("oam_bytes")
		actor_results.append(actor_result)

	return {
		"ok": true,
		"oam_bytes": output_oam,
		"next_oam_byte_index": cursor,
		"sprites_written": total_sprites_written,
		"actors": actor_results,
		"error": "",
	}


func _draw_actor(
		record_bytes: PackedByteArray,
		sprite_selector: int,
		mirror_mode: int,
		scroll_x: int,
		clip_y_min: int,
		clip_y_max: int,
		initial_oam: PackedByteArray,
		start_index: int
) -> Dictionary:
	var descriptor := int(record_bytes[0x12])
	var descriptor_pointer := _read_cpu_u16(0x8280 + descriptor * 2)
	if descriptor_pointer < 0:
		return {"ok": false, "error": last_error}
	var flag := int(record_bytes[0])
	var sprite_flip := ((flag & 0x60) << 1) ^ mirror_mode
	var x_origin := (((flag & 1) << 8) | int(record_bytes[8])) - 0x80 - scroll_x
	if (mirror_mode & 0x40) != 0:
		x_origin = 0x100 - x_origin
	x_origin &= 0xFFFF
	if (sprite_flip & 0x40) != 0:
		x_origin = (x_origin - 8) & 0xFFFF
	var movement_x := _signed_byte(int(record_bytes[0x13]))
	if ((flag ^ mirror_mode) & 0x40) != 0:
		movement_x = -movement_x
	x_origin = (x_origin + movement_x) & 0xFFFF

	var y_bias := 0x88 if (sprite_flip & 0x80) != 0 else 0x80
	var y_origin := (((flag >> 1) & 1) << 8) + int(record_bytes[12]) - y_bias
	y_origin = (y_origin + _signed_byte(int(record_bytes[0x14]))) & 0xFFFF

	var pointer := descriptor_pointer
	var stream_offset := 0
	var output_oam := initial_oam.duplicate()
	var oam_index := start_index
	var sprite_count := 0
	var run_count := 0
	var source_stream_roots: Array[int] = [descriptor_pointer]
	var visited: Dictionary = {}
	var steps := 0
	var run_log: Array[Dictionary] = []

	while steps < MAX_STREAM_STEPS:
		steps += 1
		var visit_key := "%04X:%04X" % [pointer, stream_offset]
		if visited.has(visit_key):
			return {"ok": false, "error": "sprite stream loop at $%s" % visit_key}
		visited[visit_key] = true
		var control := _read_cpu_byte(pointer + stream_offset)
		if control < 0:
			return {"ok": false, "error": last_error}
		var opcode := control & 0x07
		match opcode:
			1:
				return {
					"ok": true,
					"descriptor": descriptor,
					"descriptor_pointer": descriptor_pointer,
					"selected_stream_roots": source_stream_roots,
					"sprite_flip": sprite_flip,
					"base_x": x_origin,
					"base_y": y_origin,
					"run_count": run_count,
					"sprites_written": sprite_count,
					"start_oam_byte_index": start_index,
					"next_oam_byte_index": oam_index,
					"run_log": run_log,
					"oam_bytes": output_oam,
				}
			2:
				var jump_target := _read_cpu_u16(pointer + stream_offset + 1)
				if jump_target < 0:
					return {"ok": false, "error": last_error}
				pointer = jump_target
				stream_offset = 0
				source_stream_roots.append(pointer)
			3:
				var normalized_selector := sprite_selector - 0x0C if sprite_selector >= 0x0C else sprite_selector
				if normalized_selector < 0 or normalized_selector >= 12:
					return {"ok": false, "error": "selector $%02X is outside the source branch table" % sprite_selector}
				var table_address := pointer + stream_offset + 1 + normalized_selector * 2
				var branch_target := _read_cpu_u16(table_address)
				if branch_target < 0:
					return {"ok": false, "error": last_error}
				pointer = branch_target
				stream_offset = 0
				source_stream_roots.append(pointer)
			0:
				var count_minus_one := (control & 0x38) >> 3
				var count := count_minus_one + 1
				var y_index := _read_cpu_byte(pointer + stream_offset + 1)
				if y_index < 0:
					return {"ok": false, "error": last_error}
				if y_index >= 0x28:
					return {"ok": false, "error": "Y-offset index $%02X is out of range" % y_index}
				var y_offset := _signed_byte(_read_cpu_byte(0x81D2 + y_index))
				if (sprite_flip & 0x80) != 0:
					y_offset = -y_offset
				var y16 := (y_origin + y_offset) & 0xFFFF
				var screen_y := y16 & 0xFF
				var run_is_clipped := (y16 >> 8) != 0 or screen_y < clip_y_min or screen_y >= clip_y_max
				var run_record_address := pointer + stream_offset
				stream_offset += 2
				run_count += 1
				run_log.append({
					"source_address": run_record_address,
					"control": control,
					"count": count,
					"y_index": y_index,
					"y": screen_y,
					"clipped": run_is_clipped,
				})
				if run_is_clipped:
					stream_offset += count * 2
					continue
				for _sprite_index in count:
					var x_attribute_code := _read_cpu_byte(pointer + stream_offset)
					var tile_id := _read_cpu_byte(pointer + stream_offset + 1)
					if x_attribute_code < 0 or tile_id < 0:
						return {"ok": false, "error": last_error}
					var x_offset_index := x_attribute_code >> 2
					var x_offset := _signed_byte(_read_cpu_byte(0x81FA + x_offset_index))
					if (sprite_flip & 0x40) != 0:
						x_offset = -x_offset
					var x16 := (x_origin + x_offset) & 0xFFFF
					if oam_index + 4 > OAM_BYTES_REQUIRED:
						return {"ok": false, "error": "sprite stream exceeds the 64-entry OAM shadow"}
					if (x16 >> 8) != 0:
						# The source hides only Y and leaves the OAM cursor in place.
						output_oam[oam_index] = 0xF8
					else:
						output_oam[oam_index] = screen_y
						output_oam[oam_index + 1] = tile_id
						output_oam[oam_index + 2] = (x_attribute_code & 0x03) | sprite_flip
						output_oam[oam_index + 3] = x16 & 0xFF
						oam_index += 4
						sprite_count += 1
					stream_offset += 2
			_:
				return {"ok": false, "error": "unsupported sprite opcode %d at $%04X" % [opcode, pointer + stream_offset]}

	return {"ok": false, "error": "sprite stream exceeded %d parser steps" % MAX_STREAM_STEPS}


func _ensure_source_resources() -> bool:
	if _loaded:
		return true
	last_error = ""
	_segments.clear()
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if manifest_bytes.is_empty():
		return _fail("Actor OAM source manifest is missing.")
	var manifest_variant: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not manifest_variant is Dictionary:
		return _fail("Actor OAM source manifest is not a JSON object.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or manifest.get("runtime_rom_dependency", true) != false \
			or manifest.get("capture_or_screenshot_bytes_included", true) != false:
		return _fail("Actor OAM source manifest has an unexpected ROM identity or provenance flag.")
	var raw_segments: Array = manifest.get("segments", [])
	if raw_segments.size() != EXPECTED_SEGMENTS.size():
		return _fail("Actor OAM source manifest has the wrong segment count.")
	for segment_name in EXPECTED_SEGMENTS:
		var expected: Dictionary = EXPECTED_SEGMENTS[segment_name]
		var found: Dictionary = {}
		for raw_variant in raw_segments:
			if raw_variant is Dictionary and str(raw_variant.get("name", "")) == str(segment_name):
				found = raw_variant
				break
		if found.is_empty():
			return _fail("Actor OAM source manifest is missing segment %s." % str(segment_name))
		if str(found.get("path", "")) != str(expected["path"]) \
				or _hex_value(found.get("cpu_start", "")) != int(expected["cpu_start"]) \
				or int(found.get("length_bytes", -1)) != int(expected["length"]) \
				or str(found.get("sha256", "")) != str(expected["sha256"]):
			return _fail("Actor OAM source segment metadata differs for %s." % str(segment_name))
		var source_path := "res://" + str(found["path"])
		var source_bytes := FileAccess.get_file_as_bytes(source_path)
		if source_bytes.size() != int(expected["length"]) \
				or _sha256(source_bytes) != str(expected["sha256"]):
			return _fail("Actor OAM source bytes failed integrity validation for %s." % str(segment_name))
		_segments[segment_name] = {
			"cpu_start": int(expected["cpu_start"]),
			"bytes": source_bytes,
		}
	_loaded = true
	return true


func _read_cpu_byte(address: int) -> int:
	for segment_variant in _segments.values():
		var segment: Dictionary = segment_variant
		var start := int(segment["cpu_start"])
		var bytes: PackedByteArray = segment["bytes"]
		if address >= start and address < start + bytes.size():
			return int(bytes[address - start])
	last_error = "CPU address $%04X is outside the preserved actor OAM spans." % address
	return -1


func _read_cpu_u16(address: int) -> int:
	var low := _read_cpu_byte(address)
	var high := _read_cpu_byte(address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _signed_byte(value: int) -> int:
	return value - 0x100 if (value & 0x80) != 0 else value


func _hex_value(value: Variant) -> int:
	var normalized := str(value).to_lower().trim_prefix("0x")
	return normalized.hex_to_int()


func _sha256(bytes: PackedByteArray) -> String:
	if bytes.is_empty():
		return ""
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false


func _failure_result() -> Dictionary:
	return {"ok": false, "error": last_error, "oam_bytes": PackedByteArray(), "next_oam_byte_index": -1}


func _fail_result(message: String) -> Dictionary:
	last_error = message
	return _failure_result()
