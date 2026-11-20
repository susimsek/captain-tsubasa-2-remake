extends RefCounted
class_name RomSlot05Scenario18PostQueueCallerExecutor
## Executes the bank-$1A scenario-$18 caller after `$CBC1 RTS`, including the
## fixed `$C624->$DCDF` helper and the caller-owned RTS back to `$8112`.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCENARIO18_MANIFEST := "res://reference/rom_extract/gameplay/pass_scenario_18/manifest.json"
const CALLER_PATH := "res://reference/rom_extract/gameplay/pass_scenario_18/slot05_scenario18_post_queue_caller_8188_819b.bin"
const CALLER_SHA256 := "fea79dbe1bb2ce4aa401d7b4df6c6cfd4574aa0ee0bf0fac643005b42f428245"
const SCENARIO1C_MANIFEST := "res://reference/rom_extract/gameplay/pass_scenario_1c/manifest.json"
const VECTOR_PATH := "res://reference/rom_extract/gameplay/pass_scenario_1c/fixed_C624_dispatch_vectors_C624_C64E.bin"
const VECTOR_SHA256 := "481b6bc076bd7c8d9073cfa46949fe6548c58dedb6fac84067a5c4a8effb5968"
const DCDF_PATH := "res://reference/rom_extract/gameplay/pass_scenario_1c/fixed_C624_vector0_target_DCDF_DCF0.bin"
const DCDF_SHA256 := "a43a68c0bdbf3333d386bf74dd3f201bae308948f8ea3e58bd173c32bdc46a8d"
const CALLER_BYTES := [
	0xAD, 0x44, 0x04, 0x29, 0x03, 0x8D, 0x4E, 0x04, 0x20, 0x24,
	0xC6, 0xAD, 0x17, 0x06, 0x09, 0x80, 0x8D, 0x17, 0x06, 0x60,
]
const VECTOR_BYTES := [0x4C, 0xDF, 0xDC]
const DCDF_BYTES := [
	0xAD, 0x4E, 0x04, 0xD0, 0x0B, 0xAD, 0xE2, 0x00, 0x29,
	0x01, 0x18, 0x69, 0x01, 0x8D, 0x4E, 0x04, 0x60,
]
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const ENTRY_PC := 0x8188
const EXPECTED_EXIT_PC := 0x8112
const STATUS_CARRY := 0x01
const STATUS_ZERO := 0x02
const STATUS_OVERFLOW := 0x40
const STATUS_NEGATIVE := 0x80
const STATUS_NZ := STATUS_NEGATIVE | STATUS_ZERO
const STATUS_CVZN := STATUS_CARRY | STATUS_OVERFLOW | STATUS_ZERO | STATUS_NEGATIVE

var error_message := ""
var _configured := false


func configure() -> bool:
	error_message = ""
	_configured = false
	if not _verify_manifest_span(SCENARIO18_MANIFEST, "slot05_post_queue_caller",
			CALLER_PATH.get_file(), "0x8188", "0x034198", 20, CALLER_SHA256):
		return false
	if not _verify_manifest_span(SCENARIO1C_MANIFEST, "fixed_C624_dispatch_vectors_C624_C64E",
			VECTOR_PATH.get_file(), "0xC624", "0x03C634", 42, VECTOR_SHA256):
		return false
	if not _verify_manifest_span(SCENARIO1C_MANIFEST, "fixed_C624_vector0_target_DCDF_DCF0",
			DCDF_PATH.get_file(), "0xDCDF", "0x03DCEF", 17, DCDF_SHA256):
		return false
	var caller := FileAccess.get_file_as_bytes(CALLER_PATH)
	var vector := FileAccess.get_file_as_bytes(VECTOR_PATH)
	var dcdf := FileAccess.get_file_as_bytes(DCDF_PATH)
	if caller != PackedByteArray(CALLER_BYTES) or _sha256(caller) != CALLER_SHA256 \
			or vector.size() != 42 or vector.slice(0, 3) != PackedByteArray(VECTOR_BYTES) \
			or _sha256(vector) != VECTOR_SHA256 \
			or dcdf != PackedByteArray(DCDF_BYTES) or _sha256(dcdf) != DCDF_SHA256:
		return _fail("Scenario-$18 `$8188`, `$C624`, or `$DCDF` source bytes failed validation.")
	_configured = true
	return true


func execute_from_live_return(return_result: Dictionary, boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _failure("Configure the hash-pinned caller sources before execution.")
	var entry: Dictionary = return_result.get("entry", {})
	var registers: Dictionary = return_result.get("registers", {})
	var mapper: Dictionary = return_result.get("mapper", {})
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var dispatch: Dictionary = return_result.get("call_contract", {}).get("dispatch", {})
	var source_return_word := int(dispatch.get("source_return_word", -1))
	if String(return_result.get("status", "")) != "returned_to_source_caller" \
			or String(return_result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(entry.get("scenario_id", -1)) != 0x18 \
			or int(entry.get("return_word", -1)) != 0x8187 \
			or int(registers.get("pc", -1)) != ENTRY_PC \
			or int(registers.get("sp", -1)) != 0x4E \
			or source_return_word != 0xE944 \
			or int(registers.get("bank_low", -1)) != 0x1A \
			or int(registers.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != ENTRY_PC \
			or int(boundary.get("sp", -1)) != 0x4E \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0518]) != 0x18 \
			or int(stack[0x4D]) != 0x87 or int(stack[0x4E]) != 0x81:
		return _failure("Input is not the live scenario-$18 `$CBC1 RTS->$8188` continuation boundary.")
	var boundary_return_word := (int(stack[0x50]) << 8) | int(stack[0x4F])
	if boundary_return_word != 0x8111:
		return _failure("The `$819B RTS` frame is not the live `$8111->$8112` caller return: stack=$%04X." % boundary_return_word)
	for index in range(STACK_SIZE):
		if int(ram[0x0100 + index]) != int(stack[index]):
			return _failure("Live scenario-$18 RAM/stack mirrors differ at `$%02X`." % index)

	var output_ram: PackedByteArray = ram.duplicate()
	var output_stack: PackedByteArray = stack.duplicate()
	var source_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var ram_reads: Array[Dictionary] = []
	var source_pcs: Array[int] = []
	var a := int(registers.get("a", 0)) & 0xFF
	var x := int(registers.get("x", 0)) & 0xFF
	var y := int(registers.get("y", 0)) & 0xFF
	var p := int(registers.get("p", 0x20)) & 0xFF
	var p_known_mask := int(registers.get("p_known_mask", 0)) & 0xFF
	var p_known_value := int(registers.get("p_known_value", 0)) & 0xFF
	var status_state := {"p": p, "known_mask": p_known_mask, "known_value": p_known_value}
	var sp := int(registers["sp"])

	_source_pc(source_pcs, 0x8188)
	a = int(output_ram[0x0444])
	_ram_read(ram_reads, 0x8188, 0x0444, a)
	_apply_nz(status_state, a)
	_source_pc(source_pcs, 0x818B)
	a &= 0x03
	_apply_nz(status_state, a)
	_source_pc(source_pcs, 0x818D)
	_write_ram(output_ram, source_writes, 0x044E, a, 0x818D)

	_source_pc(source_pcs, 0x8190)
	var jsr_return_word := 0x8192
	sp = _push_jsr(output_ram, output_stack, source_writes, stack_writes, sp, jsr_return_word, 0x8190)
	_source_pc(source_pcs, 0xC624)
	_source_pc(source_pcs, 0xDCDF)
	_source_pc(source_pcs, 0xDCE2)
	var mode_value := int(output_ram[0x044E])
	_ram_read(ram_reads, 0xDCDF, 0x044E, mode_value)
	var helper_rts_pc := 0xDCEF
	if mode_value == 0:
		_source_pc(source_pcs, 0xDCE4)
		a = int(output_ram[0x00E2])
		_ram_read(ram_reads, 0xDCE4, 0x00E2, a)
		_apply_nz(status_state, a)
		_source_pc(source_pcs, 0xDCE7)
		a &= 0x01
		_apply_nz(status_state, a)
		_source_pc(source_pcs, 0xDCE9)
		status_state["p"] = (int(status_state["p"]) & ~STATUS_CARRY) & 0xFF
		status_state["known_mask"] = int(status_state["known_mask"]) | STATUS_CARRY
		status_state["known_value"] = (int(status_state["known_value"]) & ~STATUS_CARRY) & 0xFF
		_source_pc(source_pcs, 0xDCEA)
		var adc_input := a
		a = (adc_input + 1) & 0xFF
		status_state["p"] = _adc_status(int(status_state["p"]), adc_input, 1, a)
		status_state["known_mask"] = int(status_state["known_mask"]) | STATUS_CVZN
		status_state["known_value"] = (int(status_state["known_value"]) & ~STATUS_CVZN) \
				| (int(status_state["p"]) & STATUS_CVZN)
		_source_pc(source_pcs, 0xDCEC)
		_write_ram(output_ram, source_writes, 0x044E, a, 0xDCEC)

	_source_pc(source_pcs, helper_rts_pc)
	var helper_return_low := int(output_stack[(sp + 1) & 0xFF])
	var helper_return_high := int(output_stack[(sp + 2) & 0xFF])
	var helper_return_word := (helper_return_high << 8) | helper_return_low
	if helper_return_word != jsr_return_word:
		return _failure("The `$DCDF RTS` stack frame did not return to `$8193`: stack=$%04X." % helper_return_word)
	sp = (sp + 2) & 0xFF
	if sp != 0x4E:
		return _failure("The fixed helper returned with an unexpected slot-$05 SP `$%02X`." % sp)

	_source_pc(source_pcs, 0x8193)
	a = int(output_ram[0x0617])
	_ram_read(ram_reads, 0x8193, 0x0617, a)
	_apply_nz(status_state, a)
	_source_pc(source_pcs, 0x8196)
	a |= 0x80
	_apply_nz(status_state, a)
	_source_pc(source_pcs, 0x8198)
	_write_ram(output_ram, source_writes, 0x0617, a, 0x8198)
	_source_pc(source_pcs, 0x819B)
	var caller_return_low := int(output_stack[(sp + 1) & 0xFF])
	var caller_return_high := int(output_stack[(sp + 2) & 0xFF])
	var caller_return_word := (caller_return_high << 8) | caller_return_low
	if caller_return_word != 0x8111:
		return _failure("The `$819B RTS` did not pop the source caller word `$8111`: stack=$%04X." % caller_return_word)
	sp = (sp + 2) & 0xFF
	p = int(status_state["p"]) & 0xFF
	p_known_mask = int(status_state["known_mask"]) & 0xFF
	p_known_value = int(status_state["known_value"]) & 0xFF

	var source_span_hashes := {
		CALLER_PATH.get_file(): CALLER_SHA256,
		VECTOR_PATH.get_file(): VECTOR_SHA256,
		DCDF_PATH.get_file(): DCDF_SHA256,
	}
	return {
		"ok": true,
		"status": "scenario18_post_queue_caller_returned",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SCENARIO18_MANIFEST,
		"slot_base": 0x05,
		"entry_pc": ENTRY_PC,
		"exit_pc": EXPECTED_EXIT_PC,
		"entry_sp": int(registers["sp"]),
		"source_return_word": source_return_word,
		"popped_cbc1_return_word": int(entry.get("return_word", -1)),
		"popped_caller_return_word": caller_return_word,
		"helper_return_word": helper_return_word,
		"registers": {"a": a, "x": x, "y": y, "sp": sp, "pc": EXPECTED_EXIT_PC,
			"p": p, "p_known_mask": p_known_mask, "p_known_value": p_known_value,
			"bank_low": 0x1A, "bank_high": 0x1B},
		"entry_ram_image": ram.duplicate(),
		"ram_image": output_ram,
		"entry_stack_page": stack.duplicate(),
		"stack_page": output_stack,
		"ram_reads": ram_reads,
		"ram_writes": source_writes,
		"stack_writes": stack_writes,
		"source_instruction_pcs": source_pcs,
		"source_span_hashes": source_span_hashes,
		"mapper": mapper.duplicate(true),
		"trace_state_used": false,
		"emulator_data_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"source_cycle_timing_modeled": false,
		"call_contract": {"helper_call_pc": 0x8190,
			"helper_target_pc": 0xDCDF, "helper_return_word": helper_return_word,
			"helper_return_pc": 0x8193, "outer_return_word": caller_return_word,
			"outer_return_pc": EXPECTED_EXIT_PC, "sp_before": int(registers["sp"]),
			"sp_after": sp, "branch_mode_initial": mode_value},
	}


func _verify_manifest_span(path: String, span_name: String, file_name: String,
		cpu_start: String, file_offset: String, length: int, sha256: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("ROM source manifest is unavailable: %s." % path)
	var manifest: Variant = JSON.parse_string(file.get_as_text())
	if not manifest is Dictionary or _manifest_rom_sha256(manifest) != ROM_SHA256:
		return _fail("ROM source manifest targets an unexpected ROM: %s." % path)
	var spans: Array = manifest.get("source_spans", manifest.get("spans", []))
	for span_variant in spans:
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("name", "")) == span_name:
			if String(span.get("file", "")) == file_name \
					and String(span.get("cpu_start", "")) == cpu_start \
					and String(span.get("file_offset", "")) == file_offset \
					and int(span.get("length_bytes", -1)) == length \
					and String(span.get("sha256", "")) == sha256:
				return true
			return _fail("ROM source manifest span differs from the expected bytes: %s." % span_name)
	return _fail("ROM source manifest is missing the expected span: %s." % span_name)


func _manifest_rom_sha256(manifest: Dictionary) -> String:
	if manifest.has("source_rom_sha256"):
		return String(manifest.get("source_rom_sha256", ""))
	var source_rom: Variant = manifest.get("source_rom", {})
	return String(source_rom.get("sha256", "")) if source_rom is Dictionary else ""


func _push_jsr(ram: PackedByteArray, stack: PackedByteArray,
		ram_writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_pointer: int, return_word: int, pc: int) -> int:
	var high := (return_word >> 8) & 0xFF
	var low := return_word & 0xFF
	_write_ram(ram, ram_writes, 0x0100 + stack_pointer, high, pc)
	_write_stack(stack, stack_writes, stack_pointer, high, pc)
	stack_pointer = (stack_pointer - 1) & 0xFF
	_write_ram(ram, ram_writes, 0x0100 + stack_pointer, low, pc)
	_write_stack(stack, stack_writes, stack_pointer, low, pc)
	stack_pointer = (stack_pointer - 1) & 0xFF
	return stack_pointer


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], address: int,
		value: int, pc: int) -> void:
	ram[address] = value & 0xFF
	writes.append({"pc": pc, "address": address, "value": value & 0xFF,
		"kind": "rom_source_write"})


func _write_stack(stack: PackedByteArray, writes: Array[Dictionary], offset: int,
		value: int, pc: int) -> void:
	stack[offset & 0xFF] = value & 0xFF
	writes.append({"pc": pc, "address": 0x0100 + (offset & 0xFF),
		"stack_offset": offset & 0xFF, "value": value & 0xFF,
		"kind": "rom_jsr_stack_push"})


func _ram_read(reads: Array[Dictionary], pc: int, address: int, value: int) -> void:
	reads.append({"pc": pc, "address": address, "value": value & 0xFF,
		"kind": "rom_source_ram_read"})


func _source_pc(pcs: Array[int], pc: int) -> void:
	pcs.append(pc)


func _apply_nz(status: Dictionary, value: int) -> void:
	var p := int(status["p"]) & ~STATUS_NZ
	if (value & 0x80) != 0:
		p |= STATUS_NEGATIVE
	if (value & 0xFF) == 0:
		p |= STATUS_ZERO
	status["p"] = p & 0xFF
	status["known_mask"] = int(status["known_mask"]) | STATUS_NZ
	status["known_value"] = (int(status["known_value"]) & ~STATUS_NZ) | (p & STATUS_NZ)


func _adc_status(status: int, lhs: int, rhs: int, result: int) -> int:
	var carry := 1 if lhs + rhs > 0xFF else 0
	var overflow := ((~(lhs ^ rhs) & (lhs ^ result)) & 0x80) != 0
	status &= ~STATUS_CVZN
	if carry != 0:
		status |= STATUS_CARRY
	if result == 0:
		status |= STATUS_ZERO
	if overflow:
		status |= STATUS_OVERFLOW
	if (result & 0x80) != 0:
		status |= STATUS_NEGATIVE
	return status & 0xFF


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "rejected_entry_state", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
