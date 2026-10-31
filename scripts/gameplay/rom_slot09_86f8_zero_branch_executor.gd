extends RefCounted
class_name RomSlot09Worker86F8ZeroBranchExecutor
## Executes the live slot-$09 worker's `$0532 == 0` and `$80 -> 0`
## high-bit-normalization paths at `$86F8`.
## This source-specific executor is not a general 6502 emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/slot09_86f8_worker/"
const WORKER_FILE := "bank18_slot09_worker_86F8_8778.bin"
const WORKER_START := 0x86F8
const WORKER_END_EXCLUSIVE := 0x8779
const WORKER_BANK := 0x18
const WORKER_OFFSET := "0x030708"
const WORKER_LENGTH := WORKER_END_EXCLUSIVE - WORKER_START
const WORKER_SHA256 := "ae998967ec1bb0e39ffcc72c8670a393946cfe233ad6845dc524870bd3264d23"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_N := 0x80
const P_Z := 0x02
const P_NZ_MASK := P_N | P_Z

var error_message := ""
var _configured := false
var _worker_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_worker_bytes = PackedByteArray()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The `$86F8` worker source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("The `$86F8` worker source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var rom_variant: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-86f8-worker-source-v1" \
			or not rom_variant is Dictionary \
			or String(rom_variant.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or not spans_variant is Array:
		return _fail("The `$86F8` package targets an unsupported ROM or schema.")
	var worker_spec: Dictionary = {}
	for span_variant in spans_variant:
		if span_variant is Dictionary and String(span_variant.get("file", "")) == WORKER_FILE:
			worker_spec = span_variant
			break
	if worker_spec.is_empty():
		return _fail("The manifest omits the `$86F8` worker span.")
	if String(worker_spec.get("cpu_start", "")) != "0x86F8" \
			or String(worker_spec.get("cpu_end_exclusive", "")) != "0x8779" \
			or String(worker_spec.get("bank", "")) != "0x18" \
			or String(worker_spec.get("file_offset", "")) != WORKER_OFFSET \
			or int(worker_spec.get("length", -1)) != WORKER_LENGTH \
			or String(worker_spec.get("sha256", "")) != WORKER_SHA256:
		return _fail("The `$86F8` worker manifest mapping or hash does not match the supported ROM span.")
	_worker_bytes = FileAccess.get_file_as_bytes(SOURCE_ROOT + WORKER_FILE)
	if _worker_bytes.size() != WORKER_LENGTH \
			or _sha256(_worker_bytes) != WORKER_SHA256 \
			or String(worker_spec.get("bytes", "")).replace(" ", "").to_lower() != _worker_bytes.hex_encode():
		_worker_bytes = PackedByteArray()
		return _fail("The packaged `$86F8` worker bytes failed size/hash/manifest validation.")
	if not _expect_worker_bytes(WORKER_START, [0xAD, 0x32, 0x05, 0xF0, 0x25, 0x10, 0x1B, 0x29, 0x7F, 0x8D, 0x32, 0x05, 0xF0, 0x1C]) \
			or not _expect_worker_bytes(0x8722, [0x60]):
		_worker_bytes = PackedByteArray()
		return _fail("The zero-branch instruction bytes differ from `$86F8` LDA/BEQ and `$8722` RTS.")
	_configured = true
	return true


## Consumes `slot09_resume_result` from the live source-route runner. RAM,
## stack, mapper, and pending return state are copied from that result only.
func execute_from_slot09_resume_result(slot09_resume_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _rejected("Configure the hash-checked `$86F8` source span first.")
	var contract := _validate_live_resume_result(slot09_resume_result)
	if not bool(contract.get("ok", false)):
		return _rejected(String(contract.get("reason", "Invalid live slot-$09 resume result.")))
	var input_ram: PackedByteArray = slot09_resume_result["ram_image"]
	var input_stack: PackedByteArray = slot09_resume_result["stack_page"]
	var value := int(input_ram[0x0532])
	if value not in [0, 0x80]:
		return _unsupported_branch(value,
			"Only `$0532 == 0` and the ROM's `$80 -> 0` high-bit normalization are decoded.")

	var output_ram := input_ram.duplicate()
	var output_stack := input_stack.duplicate()
	var cpu: Dictionary = slot09_resume_result["registers"].duplicate(true)
	var mapper: Dictionary = slot09_resume_result["mapper"].duplicate(true)
	var entry_registers: Dictionary = cpu.duplicate(true)
	var entry_pc := int(cpu["pc"])
	var stack_reads: Array[Dictionary] = []
	var executed_pcs: Array[int] = []

	# $86F8: LDA $0532. Only N/Z are defined by this instruction here.
	if not _expect_worker_bytes(entry_pc, [0xAD, 0x32, 0x05]):
		return _rejected("The live worker entry does not match the hash-checked `$86F8` source bytes.")
	executed_pcs.append(entry_pc)
	cpu["a"] = value
	cpu["p"] = _with_nz(int(cpu.get("p", 0)), value)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ_MASK
	cpu["pc"] = 0x86FB

	# $86FB: BEQ $8722. Zero returns directly; $80 follows the source
	# BPL/AND/STA/BEQ path, clearing only the high bit before returning.
	if not _expect_worker_bytes(0x86FB, [0xF0, 0x25]):
		return _rejected("The `$86FB` branch bytes differ from the hash-checked worker span.")
	executed_pcs.append(0x86FB)
	if value == 0:
		cpu["pc"] = 0x8722
	else:
		cpu["pc"] = 0x86FD
		if not _expect_worker_bytes(0x86FD, [0x10, 0x1B]):
			return _rejected("The `$86FD` BPL bytes differ from the hash-checked worker span.")
		executed_pcs.append(0x86FD)
		# LDA set N for $80, so BPL falls through to AND #$7F.
		cpu["pc"] = 0x86FF
		if not _expect_worker_bytes(0x86FF, [0x29, 0x7F]):
			return _rejected("The `$86FF` AND bytes differ from the hash-checked worker span.")
		executed_pcs.append(0x86FF)
		_set_a(cpu, int(cpu["a"]) & 0x7F)
		cpu["pc"] = 0x8701
		if not _expect_worker_bytes(0x8701, [0x8D, 0x32, 0x05]):
			return _rejected("The `$8701` STA bytes differ from the hash-checked worker span.")
		executed_pcs.append(0x8701)
		_write_ram(output_ram, 0x8701, 0x0532, int(cpu["a"]))
		cpu["pc"] = 0x8704
		if not _expect_worker_bytes(0x8704, [0xF0, 0x1C]) or (int(cpu["p"]) & P_Z) == 0:
			return _rejected("Normalized `$0532` did not take the source `$8704->$8722` branch.")
		executed_pcs.append(0x8704)
		cpu["pc"] = 0x8722

	# $8722: RTS. Pop the caller's actual $EBB2 return word; do not erase the
	# stack bytes, and do not execute the following $8006/$8779 worker call.
	if not _expect_worker_bytes(0x8722, [0x60]):
		return _rejected("The `$8722` return opcode differs from the hash-checked worker span.")
	executed_pcs.append(0x8722)
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var return_low := int(output_stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp, "value": return_low, "kind": "RTS_low"})
	sp = (sp + 1) & 0xFF
	var return_high := int(output_stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp, "value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if int(cpu["pc"]) != 0xEBB3:
		return _rejected("The source RTS did not return to the verified `$EBB3` caller boundary.")

	return {
		"ok": true,
		"status": "returned_to_root_caller",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]),
		"entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)),
		"input_ram_0532": value,
		"output_ram_0532": int(output_ram[0x0532]),
		"entry_registers": entry_registers,
		"registers": cpu,
		"mapper": mapper,
		"ram_image": output_ram,
		"stack_page": output_stack,
		"memory_writes": ([{"pc": 0x8701, "address": 0x0532,
			"value": 0, "kind": "ram"}] if value == 0x80 else []),
		"stack_reads": stack_reads,
		"stack_writes": [],
		"instruction_pcs": executed_pcs,
		"return_word": return_word,
		"return_pc": int(cpu["pc"]),
		"next_worker_executed": false,
		"next_worker_bytes_read": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "worker_start": WORKER_START,
		"worker_end_exclusive": WORKER_END_EXCLUSIVE,
		"supports_ram_0532_zero_or_high_bit_normalization": true}


func _validate_live_resume_result(result: Dictionary) -> Dictionary:
	var result_status := String(result.get("status", ""))
	var result_entry_pc := int(result.get("entry_pc", -1))
	var is_legacy_entry := result_status == "stopped_before_worker_body" and result_entry_pc == 0xEB8B
	var is_actor_seed_continuation := result_status == "slot09_actor_seed_continuation_to_worker_vector" \
			and result_entry_pc == 0xED2D and int(result.get("caller_entry_pc", -1)) == 0xEB8B
	var result_ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var is_scenario36_continuation: bool = result_status == "scenario36_event_returned_to_worker_vector" \
			and result_entry_pc == 0xEB9E and int(result.get("caller_entry_pc", -1)) == 0xEB8B \
			and result_ram_variant is PackedByteArray and result_ram_variant.size() == RAM_SIZE \
			and int(result_ram_variant[0x0518]) == 0x36
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or not (is_legacy_entry or is_actor_seed_continuation or is_scenario36_continuation) \
			or String(result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or int(result.get("exit_pc", -1)) != WORKER_START \
			or int(result.get("exit_bank", -1)) != WORKER_BANK \
			or bool(result.get("worker_body_executed", true)) \
			or bool(result.get("worker_body_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)):
		return {"ok": false, "reason": "Input is not the live runner's hash-checked slot-$09 result stopped at `$86F8`."}
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	var pending_variant: Variant = result.get("pending_worker_call", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not pending_variant is Dictionary:
		return {"ok": false, "reason": "Live slot-$09 result must carry registers, mapper, complete RAM/stack, and pending JSR data."}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var pending: Dictionary = pending_variant
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	if not bank_registers_variant is Dictionary:
		return {"ok": false, "reason": "Live slot-$09 result is missing MMC3 bank-register state."}
	var bank_registers: Dictionary = bank_registers_variant
	if registers.size() == 0 or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or int(registers.get("pc", -1)) != WORKER_START \
			or int(registers.get("sp", -1)) != 0x78 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 7 \
			or int(bank_registers.get(6, -1)) != 0x18 \
			or int(bank_registers.get(7, -1)) != 0x19 \
			or int(ram[0x0000]) != 0x09 \
			or int(ram[0x0024]) != 0x18 or int(ram[0x0025]) != 0x19 \
			or stack.slice(0x79, 0x7B) != PackedByteArray([0xB2, 0xEB]) \
			or int(pending.get("source_pc", -1)) != 0xEBB0 \
			or int(pending.get("return_word", -1)) != 0xEBB2 \
			or int(pending.get("return_pc", -1)) != 0xEBB3 \
			or int(pending.get("target_pc", -1)) != WORKER_START \
			or int(pending.get("target_bank", -1)) != WORKER_BANK:
		return {"ok": false, "reason": "Live worker context mismatch: PC/SP=$%04X/$%02X banks=$%02X/$%02X select=$%02X regs=$%02X/$%02X RAM=$%02X/$%02X stack=%s pending=%s." % [
			int(registers.get("pc", -1)), int(registers.get("sp", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			int(mapper.get("select", -1)), int(bank_registers.get(6, -1)), int(bank_registers.get(7, -1)),
			int(ram[0x0024]), int(ram[0x0025]), stack.slice(0x79, 0x7B).hex_encode(), JSON.stringify(pending)]}
	return {"ok": true}


func _write_ram(ram: PackedByteArray, source_pc: int, address: int, value: int) -> void:
	ram[address] = value & 0xFF


func _set_a(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	cpu["a"] = value
	cpu["p"] = _with_nz(int(cpu.get("p", 0)), value)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ_MASK


func _expect_worker_bytes(cpu_address: int, expected: Array[int]) -> bool:
	var offset := cpu_address - WORKER_START
	if offset < 0 or offset + expected.size() > _worker_bytes.size():
		return false
	for index in range(expected.size()):
		if int(_worker_bytes[offset + index]) != expected[index]:
			return false
	return true


func _with_nz(status: int, value: int) -> int:
	var result := status & ~P_NZ_MASK
	if (value & 0x80) != 0:
		result |= P_N
	if (value & 0xFF) == 0:
		result |= P_Z
	return result & 0xFF


func _rejected(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_input", "reason": reason,
		"trace_state_used": false}


func _unsupported_branch(value: int, reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"entry_pc": WORKER_START, "exit_pc": 0x86FD,
		"ram_0532": value, "trace_state_used": false}


func _fail(reason: String) -> bool:
	error_message = reason
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
