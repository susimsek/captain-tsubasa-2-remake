extends RefCounted
class_name RomCutsceneDispatchAttributeTailSeed
## Decodes the checked $8464->$98EA attribute-tail seed used before worker release.

const SOURCE_PATH := "res://reference/rom_extract/intro/startup_dispatch_attribute_tail_seed.bin"
const SOURCE_SHA256 := "266560cc1d52cf2152f982b21742c84c1420c64f5871a90ab78b597c58b27170"
const EXPECTED_BYTE_VALUES: Array[int] = [
	0xA9, 0xE0, 0x85, 0xE6, 0xA9, 0x23, 0x85, 0xE7, 0xA0,
	0x01, 0xA2, 0x20, 0xA9, 0x55, 0x20, 0xEA, 0x98,
]

var error_message := ""
var _configured := false
var _ppu_address := -1
var _byte_count := 0
var _byte_value := -1


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source != PackedByteArray(EXPECTED_BYTE_VALUES) or _sha256(source) != SOURCE_SHA256:
		return _fail("ROM $8464/$98EA attribute-tail bytes failed their size/hash/byte check.")
	if source[0] != 0xA9 or source[2] != 0x85 or source[3] != 0xE6 \
			or source[4] != 0xA9 or source[6] != 0x85 or source[7] != 0xE7 \
			or source[8] != 0xA0 or source[10] != 0xA2 \
			or source[12] != 0xA9 or source[14] != 0x20 \
			or source[15] != 0xEA or source[16] != 0x98:
		return _fail("ROM attribute-tail instruction operands are outside the supported $98EA form.")
	_ppu_address = int(source[1]) | (int(source[5]) << 8)
	_byte_count = int(source[11])
	_byte_value = int(source[13])
	if _ppu_address != 0x23E0 or _byte_count != 0x20 or _byte_value != 0x55:
		return _fail("ROM attribute-tail operands differ from the verified title-route seed.")
	_configured = true
	return true


func execute(presenters: Array[Node], source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "status": "source_rejected", "error": error_message}
	if source_frame < 0 or presenters.is_empty():
		return _refused("invalid_source_boundary")
	for presenter in presenters:
		if not is_instance_valid(presenter) \
				or not presenter.has_method("apply_rom_dispatch_attribute_tail_seed") \
				or not bool(presenter.call("apply_rom_dispatch_attribute_tail_seed",
					_ppu_address, _byte_value, _byte_count)):
			return _refused("presentation_rejected")
	return {
		"ok": true,
		"status": "seeded_before_slot05_worker_release",
		"source_path": "$8464->$84B0/$84BE->$98EA",
		"source_file": SOURCE_PATH.trim_prefix("res://"),
		"source_sha256": SOURCE_SHA256,
		"source_frame": source_frame,
		"ppu_address": _ppu_address,
		"byte_count": _byte_count,
		"byte_value": _byte_value,
		"presenter_count": presenters.size(),
		"same_input_trace_values_used": false,
		"executes_6502": false,
	}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"ppu_address": _ppu_address,
		"byte_count": _byte_count,
		"byte_value": _byte_value,
		"source_sha256": SOURCE_SHA256,
	}


func _refused(status: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error_message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
