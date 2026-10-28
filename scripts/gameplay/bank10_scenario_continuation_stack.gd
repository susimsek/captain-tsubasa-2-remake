extends RefCounted
class_name Bank10ScenarioContinuationStack
## Source-byte model of bank-$10 `$FA`/`$FB` script-pointer stack effects.
## This is not the scenario VM, CPU task stack, mapper scheduler, or callback runner.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/scenario_continuation/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_SCHEMA := "bank10-scenario-continuation-sources-v1"

const SOURCE_HASHES := {
	"bank10_fa_handler_881a_8836.bin": "25c007a559b5f85da1cd991874f85c2c9fa77d68a3b0647cfc347bc0f147aa68",
	"bank10_fa_target_loader_80f6_8104.bin": "6b735a94e9738de7eebcad8d843c80f5149dac71a2fd846060adbebcd9dea089",
	"bank10_fb_handler_8837_8852.bin": "34e0466b33439d4de66876bdb757e2fb8600498f1cc3cf0968d612266af02866",
	"bank10_f0_terminal_80cf_80f5.bin": "f94d098b6341f36b79782f12a2e090196443f13bea8bf09e13f1d29d2a07fb44",
	"fixed_scenario_start_ec08_ec33.bin": "c5283a9bd23ff473de0b43cfa8d98d8d5f3b78255fa75d5b66d649174218c21f",
}

const SCRIPT_BANK_START := 0x8000
const SCRIPT_BANK_END_EXCLUSIVE := 0xC000
const CONTINUATION_STACK_BASE := 0x051A
const CONTINUATION_STACK_BYTES := 8
const MAX_STACK_DEPTH := 8

var error_message := ""
var _sources: Dictionary = {}


## Apply the byte-verified fixed-bank `$EC2E` store after the `$EC08` scenario
## start path has loaded the bank-$10 pointer. Stale `$051A-$0521` bytes are
## deliberately preserved; only the depth byte `$0522` is cleared by the ROM.
func initialize_from_source_scenario_start(stack_memory: PackedByteArray) -> Dictionary:
	if not _load_sources():
		return _failure(error_message)
	if stack_memory.size() != CONTINUATION_STACK_BYTES:
		return _failure("Scenario continuation memory must contain the eight bytes $051A-$0521.")
	return {
		"ok": true,
		"status": "scenario_stack_initialized",
		"stack_base": CONTINUATION_STACK_BASE,
		"stack_memory": stack_memory.duplicate(),
		"stack_depth": 0,
		"source_file_offset": "0x03EC3E",
		"source_cpu_address": "$EC2E",
		"effect": "STA $0522=$00; stack payload bytes are not cleared",
	}


## Execute the stack and pointer effects of `$FA` at bank-$10 `$881A` followed
## by `$80F6`. `source_index` is the `$3A` byte index at the start of the two
## pointer operands. The caller owns the selected scenario stream and its base
## CPU pointer; no frame timing or outer task return is inferred.
func execute_fa(source_stream: PackedByteArray, stream_cpu_base: int,
		source_index: int, stack_depth: int, stack_memory: PackedByteArray) -> Dictionary:
	if not _load_sources():
		return _failure(error_message)
	if not _valid_stack(stack_depth, stack_memory, true):
		return _failure("$FA requires an even depth in 0..6 and an eight-byte $051A stack.")
	if stream_cpu_base < SCRIPT_BANK_START or stream_cpu_base >= SCRIPT_BANK_END_EXCLUSIVE:
		return _failure("$FA source pointer must belong to bank-$10 CPU window $8000-$BFFF.")
	if source_index < 1 or source_index + 1 >= source_stream.size() or \
			int(source_stream[source_index - 1]) != 0xFA:
		return _failure("$FA needs its opcode and both target operand bytes around the supplied $3A index.")
	var return_pointer := stream_cpu_base + source_index + 2
	if return_pointer >= SCRIPT_BANK_END_EXCLUSIVE:
		return _failure("$FA continuation pointer would leave the mapped bank-$10 window.")
	var target_pointer := int(source_stream[source_index]) | (int(source_stream[source_index + 1]) << 8)
	if target_pointer < SCRIPT_BANK_START or target_pointer >= SCRIPT_BANK_END_EXCLUSIVE:
		return _failure("$FA target pointer is outside the bank-$10 CPU window.")
	var next_memory := stack_memory.duplicate()
	next_memory[stack_depth] = return_pointer & 0xFF
	next_memory[stack_depth + 1] = return_pointer >> 8
	return {
		"ok": true,
		"status": "subroutine_call",
		"opcode": 0xFA,
		"script_pointer_before": stream_cpu_base,
		"source_index_before": source_index,
		"target_pointer": target_pointer,
		"return_pointer": return_pointer,
		"script_pointer_after": target_pointer,
		"source_index_after": 0,
		"stack_depth_before": stack_depth,
		"stack_depth_after": stack_depth + 2,
		"stack_memory_after": next_memory,
		"stack_slot_address": CONTINUATION_STACK_BASE + stack_depth,
		"source_handler_cpu": 0x881A,
		"source_loader_cpu": 0x80F6,
	}


## Execute the source `$FB` pop. At depth zero the ROM underflows to `$80CF`,
## whose terminal handler clears `$0522`; it does not restore `$051A-$0521`.
## `$80CF` also unwinds the CPU/task call context, which this helper leaves to
## its caller.
func execute_fb(script_pointer: int, source_index_after_opcode: int,
		stack_depth: int, stack_memory: PackedByteArray) -> Dictionary:
	if not _load_sources():
		return _failure(error_message)
	if not _valid_stack(stack_depth, stack_memory, false):
		return _failure("$FB requires an even depth in 0..8 and an eight-byte $051A stack.")
	if script_pointer < SCRIPT_BANK_START or script_pointer >= SCRIPT_BANK_END_EXCLUSIVE:
		return _failure("$FB current pointer must belong to bank-$10 CPU window $8000-$BFFF.")
	if source_index_after_opcode < 0 or source_index_after_opcode > 0xFF:
		return _failure("$FB source index must fit the ROM's byte-valued `$3A` register.")
	if stack_depth == 0:
		return {
			"ok": true,
			"status": "scenario_termination",
			"opcode": 0xFB,
			"script_pointer_after": script_pointer,
			"source_index_after": source_index_after_opcode,
			"stack_depth_before": 0,
			"stack_depth_after": 0,
			"underflow_value_before_terminal_reset": 0xFE,
			"terminal_handler_cpu": 0x80CF,
			"stack_memory_after": stack_memory.duplicate(),
			"outer_cpu_task_return_modeled": false,
		}
	var restored_depth := stack_depth - 2
	var restored_pointer := int(stack_memory[restored_depth]) | (int(stack_memory[restored_depth + 1]) << 8)
	if restored_pointer < SCRIPT_BANK_START or restored_pointer >= SCRIPT_BANK_END_EXCLUSIVE:
		return _failure("$FB saved pointer is outside the bank-$10 CPU window.")
	return {
		"ok": true,
		"status": "subroutine_return",
		"opcode": 0xFB,
		"script_pointer_after": restored_pointer,
		"source_index_after": 0,
		"stack_depth_before": stack_depth,
		"stack_depth_after": restored_depth,
		"stack_memory_after": stack_memory.duplicate(),
		"restored_stack_slot_address": CONTINUATION_STACK_BASE + restored_depth,
		"source_handler_cpu": 0x8837,
		"outer_cpu_task_return_modeled": false,
	}


func get_source_status() -> Dictionary:
	var ready := _load_sources()
	return {
		"configured": ready and _sources.size() == SOURCE_HASHES.size(),
		"source_manifest": MANIFEST_PATH,
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"error": error_message,
	}


func _valid_stack(stack_depth: int, stack_memory: PackedByteArray,
		allow_push: bool) -> bool:
	if stack_memory.size() != CONTINUATION_STACK_BYTES:
		return false
	if stack_depth < 0 or stack_depth > MAX_STACK_DEPTH or stack_depth % 2 != 0:
		return false
	return not allow_push or stack_depth < MAX_STACK_DEPTH


func _load_sources() -> bool:
	if _sources.size() == SOURCE_HASHES.size():
		return true
	error_message = ""
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Scenario continuation source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Scenario continuation source manifest is malformed.")
	var manifest: Dictionary = parsed
	if str(manifest.get("schema", "")) != EXPECTED_SCHEMA or \
			str(manifest.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("Scenario continuation source manifest targets another ROM revision.")
	var rows_by_path: Dictionary = {}
	for row_variant in manifest.get("entries", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			rows_by_path[str(row.get("path", ""))] = row
	for filename_variant in SOURCE_HASHES:
		var filename := str(filename_variant)
		var path := SOURCE_ROOT + filename
		var expected_hash := str(SOURCE_HASHES[filename_variant])
		if not FileAccess.file_exists(path) or not rows_by_path.has(filename):
			return _fail("Missing preserved scenario continuation source: %s" % filename)
		var bytes := FileAccess.get_file_as_bytes(path)
		var row: Dictionary = rows_by_path[filename]
		if bytes.size() != int(row.get("size_bytes", -1)) or \
				str(row.get("sha256", "")) != expected_hash or \
				_sha256(bytes) != expected_hash:
			return _fail("Scenario continuation source failed size/hash validation: %s" % filename)
		_sources[filename] = bytes
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_required", "error": message}
