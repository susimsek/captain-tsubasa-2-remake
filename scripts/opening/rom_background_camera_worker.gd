extends RefCounted
class_name RomBackgroundCameraWorker
## ROM-derived background camera record and shared camera-worker movement state.
## The camera-follow branch applies the inverse per-frame $47 step to sprite X
## through $E8; this model exposes that step and the cumulative X displacement.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CAMERA_RECORD_RELATIVE_OFFSET := 14
const CAMERA_RECORD_BYTES_BY_BACKGROUND := {
	0x03: [0x00, 0xBF, 0x08],
	0x07: [0x00, 0x3F, 0x08],
	0x0B: [0x00, 0x3F, 0x08],
}

const BACKGROUND_RECORDS := {
	0x03: {
		"path": "res://reference/rom_extract/intro/background_03.bin",
		"file_offset": "0x00E14F",
		"camera_file_offset": "0x00E15D",
		"sha256": "40b5483fe87bc3ae2c25ab69ed6c285c2c3c943ae6a9345016ed5585c6e09f87",
	},
	0x07: {
		"path": "res://reference/rom_extract/intro/background_07.bin",
		"file_offset": "0x00E1A0",
		"camera_file_offset": "0x00E1AE",
		"sha256": "681156cdb6ea8cc44544f0cc66fb8ce832b9800366aabc87fee3491f67821450",
	},
	0x0B: {
		"path": "res://reference/rom_extract/intro/background_0B.bin",
		"file_offset": "0x00E23A",
		"camera_file_offset": "0x00E248",
		"sha256": "586678e8dc2e253882b0bb54221dddbcb8eda04ae507a52f895b4d5b27dc9018",
	},
}
const CAMERA_FIRST_UPDATE_FRAME_OFFSET := 3 # Shared worker edge: BG07 1534/1537; BG0B 2694/2697.
const CAMERA_CHUNK_PIXELS := 0x20
const CAMERA_STEP_QUARTER_PIXEL_Q8_8 := 0x40
const CAMERA_SPEED_MAGNITUDE_MASK := 0x1F
const CAMERA_USES_GLOBAL_SCROLL_MASK := 0x40
const CAMERA_DIRECTION_MASK := 0x80

var last_error := ""
var _configured := false
var _camera_record := PackedByteArray()
var _camera_fa_source_frame := -1
var _camera_load_complete_source_frame := -1
var _camera_first_update_source_frame := -1
var _camera_speed_q8_8 := 0
var _camera_direction := 0
var _camera_initial_chunks := 0
var _background_id := -1
var _background_record_file_offset := ""
var _camera_record_file_offset := ""


## Decode a byte-preserved background's trailing camera triple. The shared $8BD8 parser reads
## byte 1 as signed Q8.8 speed/flags and byte 2 as 32px chunks. Byte 0 is not
## consumed by this setup path and remains unassigned.
func configure_from_fa(background_id: int, source_frame: int) -> bool:
	last_error = ""
	_configured = false
	if not BACKGROUND_RECORDS.has(background_id):
		return _fail("No source-checked camera-worker record is available for background $%02X." % background_id)
	if source_frame < 0:
		return _fail("FA background source frame cannot be negative.")
	var record_metadata: Dictionary = BACKGROUND_RECORDS[background_id]
	var record := FileAccess.get_file_as_bytes(str(record_metadata["path"]))
	if record.size() != 17 or _sha256_hex(record) != str(record_metadata["sha256"]):
		return _fail("Preserved background-$%02X record does not match the supplied ROM bytes." % background_id)
	_camera_record = record.slice(
		CAMERA_RECORD_RELATIVE_OFFSET,
		CAMERA_RECORD_RELATIVE_OFFSET + CAMERA_RECORD_BYTES_BY_BACKGROUND[background_id].size())
	if _camera_record != PackedByteArray(CAMERA_RECORD_BYTES_BY_BACKGROUND[background_id]):
		return _fail("Background-$%02X camera record bytes do not match the decoded source." % background_id)
	var packed_speed := int(_camera_record[1])
	var magnitude := packed_speed & CAMERA_SPEED_MAGNITUDE_MASK
	if magnitude <= 0:
		return _fail("Background-$%02X camera record has no movement speed." % background_id)
	if (packed_speed & CAMERA_USES_GLOBAL_SCROLL_MASK) != 0:
		return _fail("Background-$%02X camera record selects an unsupported non-global scroll path." % background_id)
	_camera_speed_q8_8 = magnitude * CAMERA_STEP_QUARTER_PIXEL_Q8_8
	_camera_direction = -1 if (packed_speed & CAMERA_DIRECTION_MASK) == 0 else 1
	_camera_initial_chunks = int(_camera_record[2])
	if _camera_initial_chunks <= 0:
		return _fail("Background-$%02X camera record has no remaining 32-pixel chunks." % background_id)
	_background_id = background_id
	_background_record_file_offset = str(record_metadata["file_offset"])
	_camera_record_file_offset = str(record_metadata["camera_file_offset"])
	_camera_fa_source_frame = source_frame
	_configured = true
	return true


## The generic background worker activates the shared camera integrator after
## its loader completion. The +3-frame first-update edge is cross-checked for
## BG07 and BG0B; subsequent deltas come from the decoded fixed-point step.
func activate_after_background_load(source_frame: int) -> bool:
	last_error = ""
	if not _configured:
		return _fail("Background camera record must be decoded before its loader completes.")
	if source_frame < _camera_fa_source_frame:
		return _fail("Background loader completion precedes its FA command.")
	_camera_load_complete_source_frame = source_frame
	_camera_first_update_source_frame = source_frame + CAMERA_FIRST_UPDATE_FRAME_OFFSET
	return true


## Return the 8-bit camera byte used by the observed OAM world-to-screen transform.
## Fractional movement is accumulated in Q8.8, then the visible whole-pixel
## displacement follows the ROM integrator's signed, rounded pixel count.
func frame_state(source_frame: int) -> Dictionary:
	if not _configured:
		return {"active": false, "reason": "Background camera record has not been decoded."}
	if _camera_load_complete_source_frame < 0:
		return {"active": false, "reason": "Background loader has not completed."}
	if source_frame < _camera_load_complete_source_frame:
		return {"active": false, "reason": "Frame precedes camera-worker activation."}
	var update_count := 0
	if source_frame >= _camera_first_update_source_frame:
		update_count = source_frame - _camera_first_update_source_frame + 1
	var signed_q8_total := update_count * _camera_speed_q8_8 * _camera_direction
	var absolute_q8_total := absi(signed_q8_total)
	var displacement_pixels := _pixel_displacement_from_q8(absolute_q8_total)
	var maximum_displacement := _camera_initial_chunks * CAMERA_CHUNK_PIXELS
	displacement_pixels = mini(displacement_pixels, maximum_displacement)
	var signed_displacement := displacement_pixels * _camera_direction
	# `$7B` is the signed 8-bit high byte of the global scroll position, not
	# merely a direction flag. A positive 256-pixel wrap is `$7B=$01`; negative
	# positions use the corresponding two's-complement high byte (for example
	# `$FF`). The low bit is copied into PPUCTRL's horizontal nametable select.
	var ram_007b := posmod(signed_displacement, 0x10000) >> 8
	var previous_update_count := maxi(0, update_count - 1)
	var previous_q8_total := previous_update_count * _camera_speed_q8_8 * _camera_direction
	var previous_displacement := _pixel_displacement_from_q8(absi(previous_q8_total))
	previous_displacement = mini(previous_displacement, maximum_displacement)
	var previous_signed_displacement := previous_displacement * _camera_direction
	var ram_0047_step := signed_displacement - previous_signed_displacement
	var remaining_chunks := _camera_initial_chunks - int(displacement_pixels / CAMERA_CHUNK_PIXELS)
	return {
		"active": true,
		"background_id": _background_id,
		"source_frame": source_frame,
		"camera_fa_source_frame": _camera_fa_source_frame,
		"camera_load_complete_source_frame": _camera_load_complete_source_frame,
		"camera_first_update_source_frame": _camera_first_update_source_frame,
		"update_count": update_count,
		"background_record_file_offset": _background_record_file_offset,
		"camera_record_file_offset": _camera_record_file_offset,
		"camera_record_bytes": _camera_record.duplicate(),
		"camera_speed_q8_8": _camera_speed_q8_8 * _camera_direction,
		"ram_0069_fraction": posmod(signed_q8_total, 0x100),
		"ram_0047_step_pixels": ram_0047_step,
		"sprite_x_delta_pixels": -ram_0047_step,
		# Keep full-wrap history for the ROM's toggling X-overflow marker. The
		# visible OAM X is byte-wrapped by the sprite renderer separately.
		"sprite_x_cumulative_offset": -signed_displacement,
		"ram_0072_chunks_remaining": remaining_chunks,
		"ram_007a": posmod(signed_displacement, 0x100),
		"ram_007b": ram_007b,
		"ppu_nametable_x_bit": ram_007b & 0x01,
		"signed_displacement_pixels": signed_displacement,
		"camera_complete": remaining_chunks <= 0,
		"worker_started": update_count > 0,
		"runtime_source": "FA $%02X ROM record %s + shared `$8BD8` fixed-point camera worker" % [_background_id, _background_record_file_offset],
		"sprite_x_transform_status": "camera-follow flag selects `$E8 = 0 - $47`; `$91D8-$91DB` adds the inverse per-frame delta to sprite X",
		"source_rom_sha256": SOURCE_ROM_SHA256,
	}


func debug_snapshot(source_frame: int = -1) -> Dictionary:
	var result := {
		"configured": _configured,
		"background_id": _background_id,
		"camera_fa_source_frame": _camera_fa_source_frame,
		"camera_load_complete_source_frame": _camera_load_complete_source_frame,
		"camera_first_update_source_frame": _camera_first_update_source_frame,
		"background_record_file_offset": _background_record_file_offset,
		"camera_record_file_offset": _camera_record_file_offset,
		"camera_record_bytes": _camera_record.duplicate(),
		"source_rom_sha256": SOURCE_ROM_SHA256,
	}
	if source_frame >= 0:
		result["frame_state"] = frame_state(source_frame)
	return result


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _pixel_displacement_from_q8(absolute_q8_total: int) -> int:
	# BG03's `$BF` camera tail is directly checked against `$7A` in the
	# same-input RAM capture at frames 2129–2152: the ROM exposes the accumulated
	# whole-pixel high byte (floor). Keep the previously validated round-up path
	# for BG07/BG0B, whose source records use `$3F`.
	if _background_id == 0x03:
		return absolute_q8_total >> 8
	return (absolute_q8_total + 0xFF) >> 8


func _fail(message: String) -> bool:
	last_error = message
	_configured = false
	return false
