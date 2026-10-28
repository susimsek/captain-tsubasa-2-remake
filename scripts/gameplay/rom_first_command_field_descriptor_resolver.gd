extends RefCounted
class_name RomFirstCommandFieldDescriptorResolver
## Replays the bank-$1F $EFFC field-packet descriptor selection rule.
## Inputs are caller-owned source state: $0621 menu context and $0600 defender count.
## This selector is not the separate $D5C3 menu-window descriptor lookup.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/first_command_field/descriptor_selector/"
const CODE_PATH := SOURCE_ROOT + "bank_1f_selector_code_EFF6_F00E.bin"
const LOOKUP_PATH := SOURCE_ROOT + "bank_1f_descriptor_lookup_F00F_F012.bin"
const CODE_SHA256 := "ceb162a49b18c4629a508c12762d90e54e5b720dacf857634e3cee9014abc27b"
const LOOKUP_SHA256 := "6b1e73a0094b7b812d3b9e22cffb4f8239319847522c4fa103753b6950020f93"
const SELECTOR_CODE_SIZE := 25
const CONTEXT_LOOKUP_SIZE := 4
const ZERO_DEFENDER_OVERRIDE_CONTEXT := 0
const ZERO_DEFENDER_DESCRIPTOR := 0x02

var error_message := ""
var _selector_code: PackedByteArray = PackedByteArray()
var _context_lookup: PackedByteArray = PackedByteArray()
var _configured := false


func configure() -> bool:
	error_message = ""
	_selector_code = _load_source_bytes(CODE_PATH)
	_context_lookup = _load_source_bytes(LOOKUP_PATH)
	if _selector_code.size() != SELECTOR_CODE_SIZE:
		return _fail("The ROM selector instruction span is missing or has the wrong size.")
	if _context_lookup.size() != CONTEXT_LOOKUP_SIZE:
		return _fail("The ROM context lookup table is missing or has the wrong size.")
	if _sha256(_selector_code) != CODE_SHA256:
		return _fail("The ROM selector instruction span failed its source hash check.")
	if _sha256(_context_lookup) != LOOKUP_SHA256:
		return _fail("The ROM context lookup table failed its source hash check.")
	_configured = true
	return true


## Apply the verified selector for explicit caller-owned $0621/$0600 values.
## Only contexts represented by the preserved four-byte indexed table are accepted.
func resolve_descriptor(menu_context_0621: int, defender_count_0600: int) -> Dictionary:
	if not _configured:
		return _result(false, -1, menu_context_0621, defender_count_0600,
			"Configure the ROM source spans before resolving a descriptor.")
	if menu_context_0621 < 0 or menu_context_0621 >= _context_lookup.size():
		return _result(false, -1, menu_context_0621, defender_count_0600,
			"Menu context is outside the preserved indexed lookup span.")
	if defender_count_0600 < 0 or defender_count_0600 > 0xFF:
		return _result(false, -1, menu_context_0621, defender_count_0600,
			"Defender count must fit the source RAM byte.")

	# $EFF9 loads table[$0621] into $063D. $EFFF skips the override for
	# nonzero contexts; context zero uses $0600==0 to select descriptor $02.
	var descriptor_id: int = _context_lookup[menu_context_0621]
	if menu_context_0621 == ZERO_DEFENDER_OVERRIDE_CONTEXT and defender_count_0600 == 0:
		descriptor_id = ZERO_DEFENDER_DESCRIPTOR
	return _result(true, descriptor_id, menu_context_0621, defender_count_0600, "")


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"selector_code_path": CODE_PATH,
		"selector_code_sha256": _sha256(_selector_code) if not _selector_code.is_empty() else "",
		"context_lookup_path": LOOKUP_PATH,
		"context_lookup_sha256": _sha256(_context_lookup) if not _context_lookup.is_empty() else "",
	}


func _result(ok: bool, descriptor_id: int, menu_context: int,
		defender_count: int, message: String) -> Dictionary:
	return {
		"ok": ok,
		"descriptor_id": descriptor_id,
		"menu_context_0621": menu_context,
		"defender_count_0600": defender_count,
		"error": message,
	}


func _load_source_bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)


func _sha256(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hash_context.update(bytes) != OK:
		return ""
	return hash_context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
