extends RefCounted
class_name RomCutsceneSelectWaitTask
## Cooperative source-state model of the caller's bank-$00 $82B5 wait loop.
## It polls a live script-active flag and a newly-pressed Select edge; it does
## not invent an elapsed-frame timeout or execute the shared cleanup routine.

const SOURCE_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/bank00_select_wait_82B5_82EC.bin"
const EXPECTED_SOURCE_SHA256 := "6b894cd9f7a0b4e6927ce98c739672b5d79627b5e138a0257898f94793a75b5c"
const EXPECTED_LOOP_PREFIX_BYTES := [
	0xA9, 0x01, 0x20, 0xA8, 0x9F, # LDA #$01 / JSR $9FA8
	0xA5, 0x4D, 0x05, 0x4E, 0xF0, 0x06, # LDA $4D / ORA $4E / BEQ cleanup
	0xA5, 0x1E, 0x29, 0x20, 0xF0, 0xEF, # LDA $1E / AND #$20 / BEQ $82B5
]
const SELECT_EDGE_MASK := 0x20

var error_message := ""
var _configured := false
var _waiting := false
var _yield_count := 0
var _completion_kind := ""


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var source_bytes := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source_bytes.size() != 56 or _sha256(source_bytes) != EXPECTED_SOURCE_SHA256:
		return _fail("The packaged $82B5-$82EC source span failed its size/hash check.")
	if source_bytes.slice(0, EXPECTED_LOOP_PREFIX_BYTES.size()) != PackedByteArray(EXPECTED_LOOP_PREFIX_BYTES):
		return _fail("The packaged $82B5 wait-loop bytes differ from the supported source path.")
	_configured = true
	return true


## Enter at $82B5. The first $9FA8($01) call yields before the next input poll.
func begin() -> bool:
	if not _configured and not configure_from_project_sources():
		return false
	_waiting = true
	_yield_count = 1
	_completion_kind = ""
	return true


## Resume after one scheduler/NMI yield. `script_pointer_nonzero` represents
## source-owned active interpreter state; `newly_pressed_buttons` is NES $001E.
func resume(script_pointer_nonzero: bool, newly_pressed_buttons: int) -> Dictionary:
	if not _waiting:
		return {"ok": false, "status": "not_waiting", "yield_count": _yield_count}
	if newly_pressed_buttons < 0 or newly_pressed_buttons > 0xFF:
		return {"ok": false, "status": "invalid_input_mask", "yield_count": _yield_count}
	if not script_pointer_nonzero:
		return _complete("natural")
	if (newly_pressed_buttons & SELECT_EDGE_MASK) != 0:
		return _complete("select")
	_yield_count += 1
	return {
		"ok": true,
		"status": "yielded",
		"yield_count": _yield_count,
		"next_source_pc": 0x82B5,
		"yield_callsite_pc": 0x82B7,
		"yield_delay": 1,
	}


func is_waiting() -> bool:
	return _waiting


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"waiting": _waiting,
		"yield_count": _yield_count,
		"completion_kind": _completion_kind,
		"source_entry_pc": 0x82B5,
		"source_select_mask": SELECT_EDGE_MASK,
		"error": error_message,
	}


func _complete(kind: String) -> Dictionary:
	_waiting = false
	_completion_kind = kind
	return {
		"ok": true,
		"status": "returned_%s" % kind,
		"completion_kind": kind,
		"yield_count": _yield_count,
		"return_source_pc": 0x82C6,
		"cleanup_source_pc": 0x82C6,
	}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
