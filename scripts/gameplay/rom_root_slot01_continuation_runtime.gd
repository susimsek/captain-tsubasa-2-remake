extends RefCounted
class_name RomRootSlot01ContinuationRuntime
## Interprets only the packaged fixed-bank caller loop at $CA4D-$CA5A.
## The caller emits requests for $EE9F and $E3CA; their bodies and side effects
## remain owned by another source runner and are never inferred here.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/root_task_continuation/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const SOURCE_FILE := "fixed_root_slot01_continuation_CA4D_CA5A.bin"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_SOURCE_SHA256 := "e57b4fe7ceb639050a5d21b6a8d4ea958c181137f63ded21388b9ad9715a094a"
const SOURCE_START_PC := 0xCA4D
const SOURCE_END_PC_EXCLUSIVE := 0xCA5B
const SOURCE_FILE_OFFSET := 0x03CA5D
const SLOT_BASE := 0x01

enum Phase { UNCONFIGURED, READY, WAITING_FOR_CALLEE, YIELD_REQUEST_READY }

const EXPECTED_SOURCE_BYTE_VALUES := [
	0xA9, 0x01, 0x20, 0x0F, 0xCB, 0x20, 0x9F,
	0xEE, 0x20, 0xCA, 0xE3, 0x4C, 0x4D, 0xCA,
]

var error_message := ""
var _configured := false
var _phase: int = Phase.UNCONFIGURED
var _source := PackedByteArray()
var _pc := 0
var _cpu_state: Dictionary = {}
var _pending_target := -1
var _pending_return_pc := -1
var _next_call_ordinal := 0


## Loads only the hash-checked, project-owned continuation span. It never reads
## the supplied ROM, emulator output, or captured RAM/PPU state.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source = PackedByteArray()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Packaged root-slot continuation manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Packaged root-slot continuation manifest is malformed.")
	var manifest: Dictionary = parsed
	var expected_source := PackedByteArray(EXPECTED_SOURCE_BYTE_VALUES)
	if String(manifest.get("schema", "")) != "root-slot01-continuation-v1" \
			or String(manifest.get("rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("Continuation manifest targets an unsupported ROM/source schema.")
	var spans: Variant = manifest.get("spans", [])
	if not spans is Array or spans.size() != 1 or not spans[0] is Dictionary:
		return _fail("Continuation manifest must contain exactly one source span.")
	var entry: Dictionary = spans[0]
	if String(entry.get("file", "")) != SOURCE_FILE \
			or String(entry.get("cpu_address", "")) != "0xCA4D" \
			or String(entry.get("cpu_end_exclusive", "")) != "0xCA5B" \
			or String(entry.get("file_offset", "")) != "0x03CA5D" \
			or int(entry.get("length", -1)) != expected_source.size() \
			or String(entry.get("sha256", "")) != EXPECTED_SOURCE_SHA256 \
			or String(entry.get("bytes", "")).replace(" ", "").to_lower() != expected_source.hex_encode():
		return _fail("Continuation source metadata does not match the audited ROM span.")
	var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + SOURCE_FILE)
	if bytes.size() != expected_source.size() \
			or bytes != expected_source \
			or _sha256(bytes) != EXPECTED_SOURCE_SHA256:
		return _fail("Packaged continuation bytes failed the exact-byte/hash check.")
	_source = bytes
	_configured = true
	_phase = Phase.READY
	return true


## Starts only from the real scheduler's yielded slot-$01 resume contract at
## $CA52. The returned call request must be fulfilled by a separate decoded
## source runner; this helper does not execute the callee body.
func begin_from_slot01_yielded_resume(dispatch: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the packaged continuation source before use.")
	if _phase not in [Phase.READY, Phase.YIELD_REQUEST_READY]:
		return _failure("The previous continuation call has not returned yet.")
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("slot_base", -1)) != SLOT_BASE \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xCA52:
		return _failure("Expected an actual yielded slot-$01 scheduler dispatch at $CA52.")
	var state := _read_cpu_state(dispatch)
	if state.is_empty():
		return _failure("Scheduler dispatch must provide byte-valued A/X/Y/SP and bank registers.")
	_cpu_state = state
	_pc = 0xCA52
	_pending_target = -1
	_pending_return_pc = -1
	_next_call_ordinal = 0
	_phase = Phase.READY
	return _advance_caller_source()


## Supplies the result of the currently requested ROM subroutine. Target and
## return address must match the caller's source JSR; register values are
## forwarded as returned by the separate callee runner.
func accept_callee_return(target_cpu_address: int, returned_pc: int,
		returned_cpu_state: Dictionary) -> Dictionary:
	if not _configured or _phase != Phase.WAITING_FOR_CALLEE:
		return _failure("No source-derived callee request is awaiting a return.")
	if target_cpu_address != _pending_target or returned_pc != _pending_return_pc:
		return _failure("Callee target/return PC does not match the pending ROM JSR.")
	var state := _read_cpu_state(returned_cpu_state)
	if state.is_empty():
		return _failure("Callee return must provide byte-valued A/X/Y/SP and bank registers.")
	_cpu_state = state
	_pc = returned_pc
	_pending_target = -1
	_pending_return_pc = -1
	_phase = Phase.READY
	return _advance_caller_source()


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"phase": _phase,
		"program_counter": _pc,
		"pending_target_cpu_address": _pending_target,
		"pending_return_pc": _pending_return_pc,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_sha256": EXPECTED_SOURCE_SHA256,
		"executes_ee9f_body": false,
		"executes_e3ca_body": false,
		"accepts_capture_ram_or_emulator_frame_input": false,
	}


func _advance_caller_source() -> Dictionary:
	while true:
		if _pc == 0xCA52 or _pc == 0xCA55:
			return _request_source_jsr()
		if _pc == 0xCA58:
			if _read_byte(_pc) != 0x4C:
				return _source_failure("Expected the packaged JMP at $CA58.")
			var jump_target := _read_word(_pc + 1)
			if jump_target != 0xCA4D:
				return _source_failure("The packaged continuation JMP no longer targets $CA4D.")
			_pc = jump_target
			continue
		if _pc == 0xCA4D:
			if _read_byte(_pc) != 0xA9 or _read_byte(_pc + 1) != 0x01:
				return _source_failure("The packaged loop no longer loads A with immediate value $01.")
			_cpu_state["a"] = _read_byte(_pc + 1)
			_pc += 2
			continue
		if _pc == 0xCA4F:
			if _read_byte(_pc) != 0x20 or _read_word(_pc + 1) != 0xCB0F:
				return _source_failure("The packaged loop no longer yields through $CB0F at $CA4F.")
			_phase = Phase.YIELD_REQUEST_READY
			return {
				"ok": true,
				"status": "yield_requested",
				"slot_base": SLOT_BASE,
				"callsite_pc": _pc,
				"target_cpu_address": 0xCB0F,
				"resume_pc": _pc + 3,
				"delay_in_a": int(_cpu_state["a"]),
				"x": int(_cpu_state["x"]),
				"y": int(_cpu_state["y"]),
				"sp": int(_cpu_state["sp"]),
				"bank_low": int(_cpu_state["bank_low"]),
				"bank_high": int(_cpu_state["bank_high"]),
				"state_source": "ROM caller bytes plus caller-supplied decoded $E3CA return registers",
				"callee_body_executed": false,
			}
		return _source_failure("Unsupported continuation PC $%04X." % _pc)
	return _failure("Continuation source loop stopped without a caller event.")


func _request_source_jsr() -> Dictionary:
	if _read_byte(_pc) != 0x20:
		return _source_failure("Expected a packaged JSR at $%04X." % _pc)
	var target := _read_word(_pc + 1)
	var expected_target := 0xEE9F if _next_call_ordinal == 0 else 0xE3CA
	if target != expected_target:
		return _source_failure("Caller JSR order/target differs from the verified ROM sequence.")
	var request := {
		"ok": true,
		"status": "call_requested",
		"slot_base": SLOT_BASE,
		"source_pc": _pc,
		"target_cpu_address": target,
		"expected_return_pc": _pc + 3,
		"call_ordinal": _next_call_ordinal,
		"a": int(_cpu_state["a"]),
		"x": int(_cpu_state["x"]),
		"y": int(_cpu_state["y"]),
		"sp": int(_cpu_state["sp"]),
		"bank_low": int(_cpu_state["bank_low"]),
		"bank_high": int(_cpu_state["bank_high"]),
		"callee_body_executed": false,
	}
	_pending_target = target
	_pending_return_pc = _pc + 3
	_next_call_ordinal += 1
	_phase = Phase.WAITING_FOR_CALLEE
	return request


func _read_cpu_state(source: Dictionary) -> Dictionary:
	var names := ["a", "x", "y", "sp", "bank_low", "bank_high"]
	var result: Dictionary = {}
	for name_variant in names:
		var name := String(name_variant)
		if not source.has(name):
			return {}
		var value := int(source[name])
		if value < 0 or value > 0xFF:
			return {}
		result[name] = value
	return result


func _read_byte(cpu_address: int) -> int:
	var offset := cpu_address - SOURCE_START_PC
	if offset < 0 or offset >= _source.size():
		return -1
	return int(_source[offset])


func _read_word(cpu_address: int) -> int:
	var low := _read_byte(cpu_address)
	var high := _read_byte(cpu_address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}


func _source_failure(message: String) -> Dictionary:
	error_message = message
	_configured = false
	_phase = Phase.UNCONFIGURED
	return {"ok": false, "error": message, "source_integrity_failure": true}


func _fail(message: String) -> bool:
	error_message = message
	return false
