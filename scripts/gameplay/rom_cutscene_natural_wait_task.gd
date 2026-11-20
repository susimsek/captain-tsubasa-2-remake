extends RefCounted
class_name RomCutsceneNaturalWaitTask
## Cooperative source model for bank-$00 caller loop `$82A9`.
## It yields once through `$9FA8(A=1)`, then polls `$004D/$004E` until zero.

const SOURCE_PATH := "res://reference/rom_extract/gameplay/meeting_menu/bank00_natural_cutscene_wait_82A9_82B4.bin"
const EXPECTED_SOURCE_SHA256 := "a5de1ba379876bdf1ff68c417244633c5369e18506648a54ac6efa470d1e2e29"
const EXPECTED_BYTES := [
	0xA9, 0x01, # LDA #$01
	0x20, 0xA8, 0x9F, # JSR $9FA8
	0xA5, 0x4D, # LDA $004D
	0x05, 0x4E, # ORA $004E
	0xD0, 0xF5, # BNE $82A9
	0x60, # RTS
]

var error_message := ""
var _configured := false
var _waiting := false
var _yield_count := 0


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var source_bytes := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source_bytes != PackedByteArray(EXPECTED_BYTES) \
			or _sha256(source_bytes) != EXPECTED_SOURCE_SHA256:
		return _fail("The packaged `$82A9-$82B4` source span failed its exact-byte/hash check.")
	_configured = true
	return true


## Enter at `$82A9`; every call represents the routine's `$9FA8(A=1)` yield
## followed by its zero/nonzero test of the live little-endian `$004D/$004E`.
func begin() -> bool:
	if not _configured and not configure_from_project_sources():
		return false
	_waiting = true
	_yield_count = 0
	return true


func advance_source_tick(script_pointer: int) -> Dictionary:
	if not _waiting:
		return _refused("not_waiting")
	if script_pointer < 0 or script_pointer > 0xFFFF:
		return _refused("invalid_script_pointer")
	_yield_count += 1
	if script_pointer == 0:
		_waiting = false
		return {
			"ok": true,
			"status": "returned_natural",
			"source_pointer": 0,
			"yield_count": _yield_count,
			"next_source_pc": 0x82B4,
		}
	return {
		"ok": true,
		"status": "yielded",
		"source_pointer": script_pointer,
		"yield_count": _yield_count,
		"next_source_pc": 0x82A9,
	}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"waiting": _waiting,
		"yield_count": _yield_count,
		"source_entry_pc": 0x82A9,
		"pointer_low_address": 0x004D,
		"pointer_high_address": 0x004E,
		"error": error_message,
	}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(status: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error_message}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
