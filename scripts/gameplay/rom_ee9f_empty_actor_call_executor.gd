extends RefCounted
class_name RomEe9fEmptyActorCallExecutor
## Executes source-generated actor-order checks at `$CA52->$EE9F`, including
## the first live active-actor flag branch. This is not a general 6502 interpreter.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/ee9f_empty_actor_call/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100

const SOURCE_SPANS := {
	"fixed": {
		"file": "fixed_actor_loop_EE9F_EF80.bin",
		"cpu_start": "0xEE9F",
		"cpu_end_exclusive": "0xEF81",
		"file_offset": "0x03EEAF",
		"length": 226,
		"sha256": "f2bc95b5fc4ee2ad1c558e64c942be24f99ced8af4784f4bb0a51c423bb48bbd",
	},
	"bank14": {
		"file": "bank14_actor_gate_8000_8083.bin",
		"cpu_start": "0x8000",
		"cpu_end_exclusive": "0x8084",
		"file_offset": "0x028010",
		"length": 132,
		"sha256": "bff58de8e06e64719aa1bab3af55e5e5348ede7ffe7812b6ec4f515ab0f787c9",
	},
	"mapper": {
		"file": "fixed_mapper_helper_CE2D_CE49.bin",
		"cpu_start": "0xCE2D",
		"cpu_end_exclusive": "0xCE4A",
		"file_offset": "0x03CE3D",
		"length": 29,
		"sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
	},
}
const SOURCE_STARTS := {"fixed": 0xEE9F, "bank14": 0x8000, "mapper": 0xCE2D}

var error_message := ""
var _configured := false
var _source: Dictionary = {}
var _ram := PackedByteArray()
var _stack := PackedByteArray()
var _cpu: Dictionary = {}
var _mapper := {"select": -1, "bank_registers": {}}
var _writes: Array[Dictionary] = []
var _instruction_pcs: Array[int] = []
var _actor_visits: Array[Dictionary] = []
var _call_contract: Dictionary = {}


## Validates all extracted bytes against the supplied-ROM identity and manifest.
## Runtime loading reads only the project-owned source package, never the ROM.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source.clear()
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return _fail("The `$EE9F` source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The `$EE9F` source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	var spans: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-ee9f-empty-actor-call-source-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256 \
			or not spans is Array or spans.size() != SOURCE_SPANS.size():
		return _fail("The `$EE9F` manifest targets an unsupported ROM or schema.")
	for name_variant in SOURCE_SPANS:
		var name := String(name_variant)
		var expected: Dictionary = SOURCE_SPANS[name]
		var found: Dictionary = {}
		for item_variant in spans:
			if item_variant is Dictionary and String(item_variant.get("file", "")) == String(expected["file"]):
				found = item_variant
				break
		if found.is_empty():
			return _fail("The manifest omits source span `%s`." % String(expected["file"]))
		for key: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			if found.get(key) != expected[key]:
				return _fail("Manifest metadata differs for `%s` field `%s`." % [String(expected["file"]), key])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(expected["file"]))
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Extracted ROM bytes failed length, hash, or manifest-byte validation: `%s`." % String(expected["file"]))
		_source[name] = bytes
	if not _verify_instruction_recipes():
		return false
	_configured = true
	return true


## Accepts only the actual dispatch, live scheduler snapshot, and caller request
## returned by `RomFreshKickoffSourceRouteRunner.advance_on_external_nmi()`.
func execute_from_source_call(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked ROM source package first.")
	var preflight := _validate_entry(dispatch, boundary, callee_request)
	if not bool(preflight.get("ok", false)):
		return preflight
	var boundary_ram: PackedByteArray = boundary["ram_image"]
	var boundary_stack: PackedByteArray = boundary["stack_page"]
	_ram = boundary_ram.duplicate()
	_stack = boundary_stack.duplicate()
	_cpu = {
		"a": int(dispatch["a"]), "x": int(dispatch["x"]), "y": int(dispatch["y"]),
		"sp": int(dispatch["sp"]), "pc": 0xCA52,
		"bank_low": int(dispatch["bank_low"]), "bank_high": int(dispatch["bank_high"]),
		"p": 0, "p_known_mask": 0,
	}
	_mapper = {"select": -1, "bank_registers": {}}
	_writes.clear()
	_instruction_pcs.clear()
	_actor_visits.clear()
	_call_contract = {
		"dispatch": dispatch.duplicate(true),
		"scheduler_record": (boundary.get("record", PackedByteArray()) as PackedByteArray).duplicate(),
		"caller_request": callee_request.duplicate(true),
		"machine_state_source": "live RomGameplayTaskScheduler boundary",
	}

	# Caller JSR `$CA52->$EE9F`, including the real 6502 return-address bytes.
	_jsr(0xCA52, 0xEE9F)
	_cpu["pc"] = 0xEE9F
	if not _execute_prologue():
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	if int(_ram[0x053A]) != 0:
		return _stopped("unsupported_bank14_gate", 0x8012,
			"`$800F` loaded nonzero `$053A`; only its source-derived zero/RTS branch is implemented.")
	if int(_ram[0x053D]) != 0:
		return _stopped("unsupported_actor_count", 0xEEBB,
			"`$EEB8` loaded nonzero `$053D`; only the source-generated zero-worker branch is implemented.")
	var actor_result := _execute_empty_actor_loop()
	if not bool(actor_result.get("ok", false)):
		return actor_result
	return _finish_empty_actor_path()


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"supports_source_generated_actor_order_and_first_active_flag": true,
		"executes_general_6502": false,
		"reads_supplied_rom_at_runtime": false,
		"reads_trace_ram_or_images": false,
	}


func _validate_entry(dispatch: Dictionary, boundary: Dictionary, request: Dictionary) -> Dictionary:
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("slot_base", -1)) != 0x01 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xCA52 \
			or int(dispatch.get("sp", -1)) != 0x2A \
			or int(dispatch.get("bank_low", -1)) != 0x00 \
			or int(dispatch.get("bank_high", -1)) != 0x01:
		return _failure("Expected an actual yielded slot-$01 scheduler dispatch at `$CA52`.")
	if not bool(request.get("ok", false)) or int(request.get("slot_base", -1)) != 0x01 \
			or int(request.get("call_ordinal", -1)) != 0 \
			or int(request.get("source_pc", -1)) != 0xCA52 \
			or int(request.get("target_cpu_address", -1)) != 0xEE9F \
			or int(request.get("expected_return_pc", -1)) != 0xCA55 \
			or bool(request.get("callee_body_executed", true)):
		return _failure("Expected the live caller's first `$CA52 JSR $EE9F` request.")
	if int(boundary.get("slot_base", -1)) != 0x01 \
			or int(boundary.get("pc", -1)) != 0xCA52 \
			or int(boundary.get("sp", -1)) != int(dispatch.get("sp", -2)) \
			or int(boundary.get("active_task_slot", -1)) != 0x01:
		return _failure("Scheduler boundary does not preserve the dispatched slot-$01 `$CA52` state.")
	for name: String in ["a", "x", "y", "sp", "bank_low", "bank_high"]:
		if not dispatch.has(name) or not request.has(name) \
				or int(dispatch[name]) < 0 or int(dispatch[name]) > 0xFF \
				or int(request[name]) != int(dispatch[name]):
			return _failure("Caller request and live dispatch disagree on `%s`." % name)
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return _failure("Live scheduler boundary must provide 2 KiB RAM and its 256-byte stack page.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE:
		return _failure("Live scheduler boundary must provide 2 KiB RAM and its 256-byte stack page.")
	var record_variant: Variant = boundary.get("record", PackedByteArray())
	if not record_variant is PackedByteArray \
			or record_variant != PackedByteArray([0x00, 0x26, 0x00, 0x01]):
		return _failure("Live scheduler boundary has an unexpected slot-$01 task record.")
	for index in range(STACK_SIZE):
		if ram[0x0100 + index] != stack[index]:
			return _failure("Scheduler RAM and stack-page snapshots disagree at `$%04X`." % (0x0100 + index))
	if int(ram[0x0000]) != 0x01:
		return _failure("Live scheduler RAM does not identify slot-$01 as the active source task.")
	if int(ram[0x0543]) != 0x01 or int(ram[0x0544]) != 0x23 \
			or int(ram[0x0545]) != 0x45:
		return _failure("Live source ordering bytes `$0543-$0545` differ from the packaged six-actor table order.")
	return {"ok": true}


func _execute_prologue() -> bool:
	# PHA; LDA $22; LDA #$14; STA $24; LDA #$15; STA $25; JSR $CE2D.
	if not _expect(0xEE9F, [0x48]): return false
	_record(0xEE9F)
	_push(int(_cpu["a"]), 0xEE9F)
	if not _expect(0xEEA0, [0xA5, 0x22]): return false
	_record(0xEEA0)
	_set_a(int(_ram[0x0022]))
	if not _expect(0xEEA2, [0xA9, 0x14]): return false
	_record(0xEEA2)
	_set_a(0x14)
	if not _expect(0xEEA4, [0x85, 0x24]): return false
	_record(0xEEA4)
	_write_ram(0x0024, int(_cpu["a"]), 0xEEA4)
	if not _expect(0xEEA6, [0xA9, 0x15]): return false
	_record(0xEEA6)
	_set_a(0x15)
	if not _expect(0xEEA8, [0x85, 0x25]): return false
	_record(0xEEA8)
	_write_ram(0x0025, int(_cpu["a"]), 0xEEA8)
	if not _expect(0xEEAA, [0x20, 0x2D, 0xCE]): return false
	_record(0xEEAA)
	_jsr(0xEEAA, 0xCE2D)
	if not _execute_mapper_helper(): return false
	# RTS in `$CE49` returns to `$EEAD`; then PLA restores the caller's A.
	if not _expect_mapper(0xCE49, [0x60]): return false
	_record(0xCE49)
	_rts(0xCE49)
	if int(_cpu["pc"]) != 0xEEAD: return _stop_error("Mapper RTS did not return to `$EEAD`.")
	if not _expect(0xEEAD, [0x68]): return false
	_record(0xEEAD)
	_set_a(_pop(0xEEAD))
	if not _expect(0xEEAE, [0x20, 0x00, 0x80]): return false
	_record(0xEEAE)
	_jsr(0xEEAE, 0x8000)
	# Bank-$14 JMP `$8000->$800F`, then LDA `$053A`; BEQ `$8083`.
	if not _expect_bank14(0x8000, [0x4C, 0x0F, 0x80]) \
			or not _expect_bank14(0x800F, [0xAD, 0x3A, 0x05]) \
			or not _expect_bank14(0x8012, [0xF0, 0x6F]) \
			or not _expect_bank14(0x8083, [0x60]):
		return _stop_error("Bank-$14 gate instruction bytes differ from the verified `$800F` zero path.")
	_record(0x8000)
	_record(0x800F)
	_set_a(int(_ram[0x053A]))
	_record(0x8012)
	if int(_ram[0x053A]) != 0:
		_cpu["pc"] = 0x8012
		return true
	_cpu["pc"] = 0x8083
	_record(0x8083)
	_rts(0x8083)
	if int(_cpu["pc"]) != 0xEEB1: return _stop_error("Bank-$14 RTS did not return to `$EEB1`.")
	# Main routine's LDA #0; STA $3A; STA $48; LDX $053D; BEQ `$EEDA`.
	if not _expect(0xEEB1, [0xA9, 0x00]) \
			or not _expect(0xEEB3, [0x85, 0x3A]) \
			or not _expect(0xEEB5, [0x85, 0x48]) \
			or not _expect(0xEEB7, [0xAE, 0x3D, 0x05]) \
			or not _expect(0xEEBA, [0xF0, 0x1E]):
		return _stop_error("Actor-loop prologue opcodes differ from the packaged `$EE9F` span.")
	for pc: int in [0xEEB1, 0xEEB3, 0xEEB5, 0xEEB7, 0xEEBA]: _record(pc)
	_set_a(0)
	_write_ram(0x003A, 0, 0xEEB3)
	_write_ram(0x0048, 0, 0xEEB5)
	_set_x(int(_ram[0x053D]))
	_cpu["pc"] = 0xEEDA
	return true


func _execute_mapper_helper() -> bool:
	var code: PackedByteArray = _source["mapper"]
	var pc := 0xCE2D
	var offset := 0
	# Execute the ROM sequence instruction by instruction, including the four
	# actual MMC3 register-select/data writes performed through `$8000/$8001`.
	while offset < code.size():
		var opcode := int(code[offset])
		if opcode == 0x60:
			return pc == 0xCE49
		_record(pc)
		match opcode:
			0xA5: # LDA zp
				var zp := int(code[offset + 1]); _set_a(int(_ram[zp])); offset += 2; pc += 2
			0x09: # ORA #imm
				_set_a(int(_cpu["a"]) | int(code[offset + 1])); offset += 2; pc += 2
			0x85: # STA zp
				_write_ram(int(code[offset + 1]), int(_cpu["a"]), pc); offset += 2; pc += 2
			0x8D: # STA abs (mapper register writes in this verified span)
				var address := int(code[offset + 1]) | (int(code[offset + 2]) << 8)
				_write_bus(address, int(_cpu["a"]), pc); offset += 3; pc += 3
			_:
				return _stop_error("Unsupported mapper-helper opcode `$%02X` at `$%04X`." % [opcode, pc])
	return _stop_error("Mapper helper ended without its source RTS.")


func _execute_empty_actor_loop() -> Dictionary:
	var expected_indices := [0, 1, 2, 3, 4, 5]
	if not _expect(0xEEDA, [0x85, 0x3B]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xEEDA)
	_write_ram(0x003B, int(_cpu["a"]), 0xEEDA)
	for ordinal in range(6):
		if not _expect(0xEEDC, [0xA5, 0x3A]) \
				or not _expect(0xEEDE, [0x4A]) \
				or not _expect(0xEEDF, [0xAA]) \
				or not _expect(0xEEE0, [0xBD, 0x43, 0x05]) \
				or not _expect(0xEEE3, [0xB0, 0x04]) \
				or not _expect(0xEEE5, [0x4A, 0x4A, 0x4A, 0x4A]) \
				or not _expect(0xEEE9, [0x29, 0x0F]) \
				or not _expect(0xEEEB, [0x0A]) \
				or not _expect(0xEEEC, [0xAA]) \
				or not _expect(0xEEED, [0xBD, 0x73, 0xEF]) \
				or not _expect(0xEEF0, [0x85, 0x3C]) \
				or not _expect(0xEEF2, [0xBD, 0x74, 0xEF]) \
				or not _expect(0xEEF5, [0x85, 0x3D]) \
				or not _expect(0xEEF7, [0xA0, 0x00]) \
				or not _expect(0xEEF9, [0xB1, 0x3C]) \
				or not _expect(0xEEFB, [0x10, 0x3B]):
			return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
		_record(0xEEDC); _set_a(int(_ram[0x003A]))
		_record(0xEEDE); _lsr_a()
		_record(0xEEDF); _set_x(int(_cpu["a"]))
		var packed_address := 0x0543 + int(_cpu["x"])
		_record(0xEEE0); _set_a(int(_ram[packed_address]))
		_record(0xEEE3)
		if _flag(0x01):
			_cpu["pc"] = 0xEEE9
		else:
			for shift_pc in [0xEEE5, 0xEEE6, 0xEEE7, 0xEEE8]:
				_record(shift_pc); _lsr_a()
		_record(0xEEE9); _set_a(int(_cpu["a"]) & 0x0F)
		_record(0xEEEB); _asl_a()
		_record(0xEEEC); _set_x(int(_cpu["a"]))
		var actor_index := int(_cpu["x"]) >> 1
		if actor_index < 0 or actor_index >= 6 or actor_index != expected_indices[ordinal]:
			return _stopped("unsupported_actor_order", 0xEEED,
				"ROM-derived actor-order nibble `%d` is outside the verified six-entry order." % actor_index)
		_record(0xEEED)
		var pointer_low := int(_source_byte("fixed", 0xEF73 + actor_index * 2))
		_set_a(pointer_low)
		_record(0xEEF0); _write_ram(0x003C, pointer_low, 0xEEF0)
		var pointer_high := int(_source_byte("fixed", 0xEF74 + actor_index * 2))
		_record(0xEEF2); _set_a(pointer_high)
		_record(0xEEF5); _write_ram(0x003D, pointer_high, 0xEEF5)
		var actor_pointer := int(_ram[0x003C]) | (int(_ram[0x003D]) << 8)
		_record(0xEEF7); _set_y(0)
		_record(0xEEF9)
		var actor_flag := int(_ram[actor_pointer])
		_set_a(actor_flag)
		_record(0xEEFB)
		if (actor_flag & 0x80) != 0:
			_cpu["pc"] = 0xEEFD
			return _stopped("stopped_at_first_active_actor", 0xEEFD,
				"The ROM-derived actor flag is active; stopped before `$EEFD BIT $0615` and actor processing.",
				{"actor_ordinal": ordinal, "actor_index": actor_index,
				"actor_pointer": actor_pointer, "actor_flag": actor_flag,
				"actor_record": _ram.slice(actor_pointer, actor_pointer + 21),
				"actor_order_bytes": _ram.slice(0x0543, 0x0546),
				"stack_pointer_at_stop": int(_cpu["sp"]),
				"flag_test_pc": 0xEEFB,
				"next_source_pc": 0xEEFD})
		_actor_visits.append({"ordinal": ordinal, "actor_index": actor_index,
			"actor_pointer": actor_pointer, "flag": actor_flag, "inactive": true})
		# BPL -> `$EF38`; then increment/check six entries.
		_cpu["pc"] = 0xEF38
		if not _expect(0xEF38, [0xE6, 0x3A]) \
				or not _expect(0xEF3A, [0xA5, 0x3A]) \
				or not _expect(0xEF3C, [0xC9, 0x06]) \
				or not _expect(0xEF3E, [0xD0, 0x9C]):
			return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
		_record(0xEF38); _inc_ram(0x003A)
		_record(0xEF3A); _set_a(int(_ram[0x003A]))
		_record(0xEF3C); _cmp(int(_cpu["a"]), 0x06)
		_record(0xEF3E)
		if ordinal < 5:
			_cpu["pc"] = 0xEEDC
		else:
			_cpu["pc"] = 0xEF40
	if int(_ram[0x003A]) != 6:
		return _stopped("source_state_uncertainty", int(_cpu["pc"]), "The ROM loop did not derive six inactive actor visits.")
	if not _expect(0xEF40, [0x2C, 0x2D, 0x06]) or not _expect(0xEF43, [0x10, 0x12]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xEF40)
	var mode_value := int(_ram[0x062D])
	_set_bit_flags(int(_cpu["a"]), mode_value)
	_record(0xEF43)
	if (mode_value & 0x80) != 0:
		_cpu["pc"] = 0xEF45
		return _stopped("unsupported_actor_mode", 0xEF45,
			"All six actors are inactive, but `$062D.7` selects an unimplemented source branch.")
	_cpu["pc"] = 0xEF57
	return {"ok": true}


func _finish_empty_actor_path() -> Dictionary:
	if not _expect(0xEF57, [0xA9, 0x40, 0x38, 0xE5, 0x48, 0x8D, 0x3F, 0x05]) \
			or not _expect(0xEF5F, [0x90, 0x11]) \
			or not _expect(0xEF61, [0xF0, 0x0F]) \
			or not _expect(0xEF63, [0xA8]) \
			or not _expect(0xEF64, [0xA6, 0x3B]) \
			or not _expect(0xEF66, [0xA9, 0xF8]) \
			or not _expect(0xEF68, [0x9D, 0x00, 0x02]) \
			or not _expect(0xEF6B, [0xE8, 0xE8, 0xE8, 0xE8, 0x88, 0xD0, 0xF6]) \
			or not _expect(0xEF72, [0x60]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xEF57); _set_a(0x40)
	_record(0xEF59); _set_flag(0x01, true)
	_record(0xEF5A); _sbc(int(_ram[0x0048]))
	_record(0xEF5C); _write_ram(0x053F, int(_cpu["a"]), 0xEF5C)
	_record(0xEF5F)
	if not _flag(0x01): return _stopped("unsupported_oam_length", 0xEF72, "Source OAM loop underflow path is unsupported.")
	_record(0xEF61)
	if _flag(0x02): return _stopped("unsupported_oam_length", 0xEF72, "Source OAM loop zero-length path is unsupported.")
	_record(0xEF63); _set_y(int(_cpu["a"]))
	_record(0xEF64); _set_x(int(_ram[0x003B]))
	_record(0xEF66); _set_a(0xF8)
	for iteration in range(64):
		var x_value := int(_cpu["x"])
		if x_value != iteration * 4:
			return _stopped("source_state_uncertainty", 0xEF69, "OAM index did not follow the source four-byte stride.")
		_record(0xEF68)
		_write_ram(0x0200 + x_value, int(_cpu["a"]), 0xEF68)
		for pc in [0xEF6B, 0xEF6C, 0xEF6D, 0xEF6E]:
			_record(pc); _set_x((int(_cpu["x"]) + 1) & 0xFF)
		_record(0xEF6F); _set_y((int(_cpu["y"]) - 1) & 0xFF)
		_record(0xEF70)
	if int(_cpu["y"]) != 0 or int(_cpu["x"]) != 0:
		return _stopped("source_state_uncertainty", 0xEF72, "Source OAM loop did not terminate after 64 entries.")
	_record(0xEF72)
	_rts(0xEF72)
	if int(_cpu["pc"]) != 0xCA55 or int(_cpu["sp"]) != 0x2A:
		return _stopped("source_state_uncertainty", int(_cpu["pc"]), "Final RTS did not restore `$CA55` and scheduler SP `$2A`.")
	var final_registers := _register_snapshot()
	var final_banks: Dictionary = _mapper.get("bank_registers", {})
	return {
		"ok": true,
		"status": "returned_to_source_caller",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry": {"slot_base": 0x01, "call_pc": 0xCA52, "target_pc": 0xEE9F,
			"expected_return_pc": 0xCA55, "source": "live slot-$01 scheduler dispatch and RAM/stack snapshot"},
		"registers": final_registers,
		"mapper": {"register_select": int(_mapper["select"]),
			"bank_registers": final_banks.duplicate(true),
			"task_bank_low": int(_cpu["bank_low"]), "task_bank_high": int(_cpu["bank_high"])},
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"memory_writes": _writes.duplicate(true),
		"actor_visits": _actor_visits.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"instruction_count": _instruction_pcs.size(),
		"returned_to_caller": true,
		"ppu_bus_events": [],
		"ppu_cycle_timing_modeled": false,
		"audio_effects_modeled": false,
	}


func _verify_instruction_recipes() -> bool:
	if not _expect(0xEE9F, [0x48, 0xA5, 0x22, 0xA9, 0x14, 0x85, 0x24, 0xA9, 0x15, 0x85, 0x25, 0x20, 0x2D, 0xCE, 0x68, 0x20, 0x00, 0x80]):
		return _fail("The `$EE9F` entry prologue differs from the expected ROM bytes.")
	if not _expect_mapper(0xCE2D, [0xA5, 0x22, 0x09, 0x06, 0x85, 0x23, 0x8D, 0x00, 0x80,
			0xA5, 0x24, 0x8D, 0x01, 0x80, 0xA5, 0x22, 0x09, 0x07, 0x85, 0x23,
			0x8D, 0x00, 0x80, 0xA5, 0x25, 0x8D, 0x01, 0x80, 0x60]):
		return _fail("The mapper helper differs from its exact extracted bytes.")
	if not _expect_bank14(0x8000, [0x4C, 0x0F, 0x80]) \
			or not _expect_bank14(0x800F, [0xAD, 0x3A, 0x05, 0xF0, 0x6F]) \
			or not _expect_bank14(0x8083, [0x60]):
		return _fail("The bank-$14 `$8000->$800F` zero-gate bytes differ.")
	return true


func _expect(pc: int, expected: Array[int]) -> bool:
	for index in range(expected.size()):
		if _source_byte("fixed", pc + index) != expected[index]:
			return _stop_error("ROM byte mismatch at `$%04X`: expected `$%02X`." % [pc + index, expected[index]])
	return true


func _expect_mapper(pc: int, expected: Array[int]) -> bool:
	for index in range(expected.size()):
		if _source_byte("mapper", pc + index) != expected[index]:
			return _stop_error("Mapper ROM byte mismatch at `$%04X`: expected `$%02X`." % [pc + index, expected[index]])
	return true


func _expect_bank14(pc: int, expected: Array[int]) -> bool:
	for index in range(expected.size()):
		if _source_byte("bank14", pc + index) != expected[index]:
			return _stop_error("Bank-$14 ROM byte mismatch at `$%04X`: expected `$%02X`." % [pc + index, expected[index]])
	return true


func _source_byte(name: String, address: int) -> int:
	var bytes: PackedByteArray = _source.get(name, PackedByteArray())
	var start := int(SOURCE_STARTS.get(name, -1))
	var offset := address - start
	if offset < 0 or offset >= bytes.size(): return -1
	return int(bytes[offset])


func _record(pc: int) -> void:
	_instruction_pcs.append(pc)
	_cpu["pc"] = pc


func _jsr(pc: int, target: int) -> void:
	var return_address := pc + 2
	_push((return_address >> 8) & 0xFF, pc)
	_push(return_address & 0xFF, pc)
	_cpu["pc"] = target


func _rts(pc: int) -> void:
	var low := _pop(pc)
	var high := _pop(pc)
	_cpu["pc"] = (((high << 8) | low) + 1) & 0xFFFF


func _push(value: int, pc: int) -> void:
	var sp := int(_cpu["sp"]) & 0xFF
	_write_ram(0x0100 + sp, value, pc)
	_cpu["sp"] = (sp - 1) & 0xFF


func _pop(pc: int) -> int:
	var sp := (int(_cpu["sp"]) + 1) & 0xFF
	_cpu["sp"] = sp
	return int(_ram[0x0100 + sp])


func _write_ram(address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	_ram[address] = byte_value
	if address >= 0x0100 and address < 0x0200:
		_stack[address & 0xFF] = byte_value
	_writes.append({"space": "cpu_ram", "address": address, "value": byte_value, "pc": pc})


func _write_bus(address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	if address == 0x8000:
		_mapper["select"] = byte_value & 0x07
	elif address == 0x8001:
		var banks: Dictionary = _mapper["bank_registers"]
		banks[int(_mapper["select"])] = byte_value
	else:
		error_message = "Unexpected non-RAM bus write `$%04X` at `$%04X`." % [address, pc]
	_writes.append({"space": "mmc3", "address": address, "value": byte_value, "pc": pc})


func _set_a(value: int) -> void:
	_cpu["a"] = value & 0xFF
	_set_nz(int(_cpu["a"]))


func _set_x(value: int) -> void:
	_cpu["x"] = value & 0xFF
	_set_nz(int(_cpu["x"]))


func _set_y(value: int) -> void:
	_cpu["y"] = value & 0xFF
	_set_nz(int(_cpu["y"]))


func _set_nz(value: int) -> void:
	_set_flag(0x80, (value & 0x80) != 0)
	_set_flag(0x02, (value & 0xFF) == 0)


func _set_flag(mask: int, enabled: bool) -> void:
	var p := int(_cpu["p"])
	_cpu["p"] = (p | mask) if enabled else (p & ~mask)
	_cpu["p_known_mask"] = int(_cpu["p_known_mask"]) | mask


func _flag(mask: int) -> bool:
	return (int(_cpu["p"]) & mask) != 0


func _lsr_a() -> void:
	var old := int(_cpu["a"])
	_set_flag(0x01, (old & 1) != 0)
	_set_a(old >> 1)


func _asl_a() -> void:
	var old := int(_cpu["a"])
	_set_flag(0x01, (old & 0x80) != 0)
	_set_a((old << 1) & 0xFF)


func _inc_ram(address: int) -> void:
	var value := (int(_ram[address]) + 1) & 0xFF
	_write_ram(address, value, 0xEF38)
	_set_nz(value)


func _cmp(left: int, right: int) -> void:
	var result := (left - right) & 0xFF
	_set_flag(0x01, left >= right)
	_set_nz(result)


func _set_bit_flags(accumulator: int, memory_value: int) -> void:
	_set_flag(0x80, (memory_value & 0x80) != 0)
	_set_flag(0x40, (memory_value & 0x40) != 0)
	_set_flag(0x02, (accumulator & memory_value) == 0)


func _sbc(value: int) -> void:
	var accumulator := int(_cpu["a"])
	var borrow := 0 if _flag(0x01) else 1
	var result_full := accumulator - value - borrow
	var result := result_full & 0xFF
	_set_flag(0x01, result_full >= 0)
	_set_flag(0x40, ((accumulator ^ result) & (accumulator ^ value) & 0x80) != 0)
	_set_a(result)


func _stopped(status: String, stop_pc: int, reason: String,
		detail: Dictionary = {}) -> Dictionary:
	_cpu["pc"] = stop_pc
	var partial_banks: Dictionary = _mapper.get("bank_registers", {})
	return {
		"ok": false, "status": status, "stop_pc": stop_pc, "reason": reason,
		"partial_state": {"registers": _register_snapshot(),
			"mapper": {"register_select": int(_mapper["select"]),
				"bank_registers": partial_banks.duplicate(true)},
			"ram_image": _ram.duplicate(), "stack_page": _stack.duplicate(),
			"memory_writes": _writes.duplicate(true),
			"actor_visits": _actor_visits.duplicate(true),
			"instruction_pcs": _instruction_pcs.duplicate()},
		"detail": detail,
		"call_contract": _call_contract.duplicate(true),
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
	}


func _register_snapshot() -> Dictionary:
	var registers := _cpu.duplicate(true)
	var known_mask := int(_cpu.get("p_known_mask", 0)) & 0xFF
	registers.erase("p")
	registers["p_known_value"] = int(_cpu.get("p", 0)) & known_mask
	registers["p_known_mask"] = known_mask
	registers["p_unknown_mask"] = (~known_mask) & 0xFF
	return registers


func _failure(message: String) -> Dictionary:
	return {"ok": false, "status": "rejected_entry_state", "error": message}


func _stop_error(message: String) -> bool:
	error_message = message
	return false


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK: return ""
	hash.update(bytes)
	return hash.finish().hex_encode()
