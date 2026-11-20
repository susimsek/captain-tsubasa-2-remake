extends RefCounted
class_name RomPassWaiterFieldCallerE081Executor
## Executes ROM bytes in the `$E081-$E0DE` field caller and yields explicit
## source-call contracts. It never executes the `$E0AB JSR $8000` handoff.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_waiter_field_caller_E081/manifest.json"
const MANIFEST_SHA256 := "f30f3c014559c45a6ce6c70462d728951c25852ab622a0014b04ea484c7d1e82"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/pass_waiter_field_caller_E081/fixed_field_caller_E081_E0DE.bin"
const SOURCE_SHA256 := "d5c9912b82292028e430cba0615751ec0f95c433df07b6738118c8f9c71261b9"
const SOURCE_START := 0xE081
const SOURCE_END_EXCLUSIVE := 0xE0DF
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100

const FLAG_C := 0x01
const FLAG_Z := 0x02
const FLAG_I := 0x04
const FLAG_D := 0x08
const FLAG_B := 0x10
const FLAG_U := 0x20
const FLAG_V := 0x40
const FLAG_N := 0x80

var error_message := ""
var _configured := false
var _source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	if not FileAccess.file_exists(MANIFEST_PATH) \
			or FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		return _fail("The isolated E081 source manifest is missing or changed.")
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return _fail("The isolated E081 source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var source_rom: Dictionary = manifest.get("source_rom", {})
	var spans: Array = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-pass-waiter-field-caller-e081-source-v1" \
			or String(source_rom.get("sha256", "")) != ROM_SHA256 \
			or int(source_rom.get("size_bytes", -1)) != 393232 \
			or int(source_rom.get("mapper", -1)) != 4 \
			or spans.size() != 1:
		return _fail("The isolated E081 manifest does not identify the pinned mapper-4 ROM and one source span.")
	var span: Dictionary = spans[0]
	if String(span.get("file", "")) != SOURCE_PATH.get_file() \
			or String(span.get("bank", "")) != "0x1F" \
			or String(span.get("window", "")) != "fixed" \
			or String(span.get("cpu_start", "")) != "0xE081" \
			or String(span.get("cpu_end_exclusive", "")) != "0xE0DF" \
			or String(span.get("file_offset", "")) != "0x03E091" \
			or int(span.get("length", -1)) != 94 \
			or String(span.get("sha256", "")) != SOURCE_SHA256:
		return _fail("The E081 caller source span metadata is incomplete or changed.")
	if not FileAccess.file_exists(SOURCE_PATH) \
			or FileAccess.get_sha256(SOURCE_PATH) != SOURCE_SHA256:
		return _fail("The E081 caller source bytes are missing or changed.")
	var source_file := FileAccess.open(SOURCE_PATH, FileAccess.READ)
	if source_file == null:
		return _fail("Could not open the E081 caller source bytes.")
	_source = source_file.get_buffer(94)
	if _source.size() != 94 \
			or _source.slice(0x26, 0x29) != PackedByteArray([0x20, 0x2D, 0xCE]) \
			or _source.slice(0x2A, 0x2D) != PackedByteArray([0x20, 0x00, 0x80]) \
			or _source.slice(0x4D, 0x50) != PackedByteArray([0x20, 0x54, 0xE8]) \
			or _source.slice(0x5D, 0x5E) != PackedByteArray([0x60]):
		return _fail("The E081 caller's mapper, `$8000`, loop, or RTS source bytes differ.")
	_configured = true
	return true


## Runs ROM instructions until an external JSR or the source RTS. A resumed
## mid-span boundary requires the exact preceding call contract as proof.
func execute_until_external_call(boundary: Dictionary,
		resume_call_contract: Dictionary = {}) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var validation := _validate_boundary(boundary, resume_call_contract)
	if not bool(validation.get("ok", false)):
		return _failure("invalid_e081_boundary", String(validation.get("error", "Invalid E081 boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var cpu := {"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0)) & 0xFF}
	var reads: Array[Dictionary] = []
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var branches: Array[Dictionary] = []
	for _instruction_index in 2048:
		var pc := int(cpu["pc"])
		if pc < SOURCE_START or pc >= SOURCE_END_EXCLUSIVE:
			return _result("source_interval_exit", boundary, cpu, ram, stack,
				reads, writes, stack_reads, stack_writes, instruction_pcs, branches,
				{}, entry_ram, entry_stack)
		var opcode := _fetch(pc)
		if opcode < 0:
			return _failure("unsupported_e081_opcode", "Missing ROM opcode at `$%04X`." % pc)
		if opcode == 0x20:
			return _call_contract(boundary, cpu, ram, stack, reads, writes,
				stack_reads, stack_writes, instruction_pcs, branches,
				entry_ram, entry_stack)
		instruction_pcs.append(pc)
		cpu["pc"] = pc + 1
		var step := _step_local(opcode, pc, cpu, ram, stack,
			reads, writes, stack_reads, stack_writes, branches)
		if not bool(step.get("ok", false)):
			return _failure("unsupported_e081_instruction",
				String(step.get("error", "Unsupported instruction at `$%04X`." % pc)))
		if bool(step.get("returned", false)):
			return _result("source_function_returned", boundary, cpu, ram, stack,
				reads, writes, stack_reads, stack_writes, instruction_pcs, branches,
				{"return_word": int(step.get("return_word", -1)),
				"return_pc": int(step.get("return_pc", -1)),
				"return_bank": _bank_for_pc(int(step.get("return_pc", -1)), boundary)},
				entry_ram, entry_stack)
	return _failure("instruction_bound_exceeded", "E081 caller exceeded the 2048-instruction bound.")


func _validate_boundary(boundary: Dictionary, resume_contract: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not mapper_variant is Dictionary:
		return {"ok": false, "error": "Boundary ROM identity, RAM, stack, or mapper is invalid."}
	var pc := int(boundary.get("pc", -1))
	if pc < SOURCE_START or pc >= SOURCE_END_EXCLUSIVE:
		return {"ok": false, "error": "Boundary PC is outside `$E081-$E0DE`."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or ram.slice(0x0100, 0x0200) != stack:
		return {"ok": false, "error": "Boundary must contain synchronized 2 KiB RAM and stack page."}
	for register_name: String in ["sp", "a", "x", "y", "p", "p_known_mask"]:
		var value := int(boundary.get(register_name, -1))
		if value < 0 or value > 0xFF:
			return {"ok": false, "error": "Boundary register %s is not a byte." % register_name}
	if int(mapper.get("bank_low", -1)) != 0x1A \
			or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F:
		return {"ok": false, "error": "Boundary mapper must select `$1A/$1B/$1E/$1F`."}
	var test_fixture := bool(boundary.get("test_fixture", false))
	if pc == SOURCE_START:
		if not test_fixture:
			var dispatch: Variant = boundary.get("source_dispatch_proof", {})
			if not dispatch is Dictionary or String(dispatch.get("rom_sha256", "")) != ROM_SHA256 \
					or int(dispatch.get("callsite_pc", -1)) != 0xE07E \
					or int(dispatch.get("target_pc", -1)) != 0xE709 \
					or int(dispatch.get("return_word", -1)) != 0xE080 \
					or int(dispatch.get("return_pc", -1)) != SOURCE_START \
					or not bool(dispatch.get("rts_return_verified", false)) \
					or bool(dispatch.get("trace_state_used", true)):
				return {"ok": false, "error": "Production `$E081` entry requires the ROM-owned `$E07E->$E709 RTS` dispatch proof."}
	else:
		if not test_fixture and not _resume_contract_matches(resume_contract, pc, boundary):
			return {"ok": false, "error": "Mid-span resume requires a matching source JSR return contract."}
	return {"ok": true}


func _resume_contract_matches(contract: Dictionary, pc: int, boundary: Dictionary) -> bool:
	if String(contract.get("rom_sha256", "")) != ROM_SHA256 \
			or int(contract.get("return_pc", -1)) != pc \
			or int(contract.get("sp_before_push", -1)) != int(boundary.get("sp", -2)) \
			or not bool(contract.get("call_return_verified", false)) \
			or bool(contract.get("trace_state_used", true)):
		return false
	var callsite := int(contract.get("callsite_pc", -1))
	var target := int(contract.get("target_pc", -1))
	if callsite < SOURCE_START or callsite + 2 > SOURCE_END_EXCLUSIVE \
			or _fetch(callsite) != 0x20 \
			or _read_word(callsite + 1) != target \
			or int(contract.get("return_pc", -2)) != callsite + 3:
		return false
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not stack_variant is PackedByteArray:
		return false
	var stack: PackedByteArray = stack_variant
	var sp := int(boundary.get("sp", -1))
	var return_word := int(contract.get("return_word", -1))
	return return_word == ((callsite + 2) & 0xFFFF) \
		and int(stack[sp]) == ((return_word >> 8) & 0xFF) \
		and int(stack[(sp - 1) & 0xFF]) == (return_word & 0xFF)


func _call_contract(boundary: Dictionary, cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, reads: Array[Dictionary], writes: Array[Dictionary],
		stack_reads: Array[Dictionary], stack_writes: Array[Dictionary],
		instruction_pcs: Array[int], branches: Array[Dictionary],
		entry_ram: PackedByteArray, entry_stack: PackedByteArray) -> Dictionary:
	var pc := int(cpu["pc"])
	if instruction_pcs.is_empty() or instruction_pcs[-1] != pc:
		instruction_pcs.append(pc)
	var target := _read_word(pc + 1)
	var return_pc := pc + 3
	var return_word := return_pc - 1
	var target_bank := _bank_for_pc(target, boundary)
	var mapper: Dictionary = (boundary.get("mapper", {}) as Dictionary).duplicate(true)
	var handoff := pc == 0xE0AB and target == 0x8000
	if handoff and int(mapper.get("bank_low", -1)) != 0x1A:
		return _failure("wrong_e081_handoff_bank", "`$E0AB JSR $8000` requires low PRG bank `$1A`.")
	var call_request := {"kind": "rom_field_worker_handoff" if handoff else "rom_jsr_request",
		"rom_sha256": ROM_SHA256, "callsite_pc": pc, "target_pc": target,
		"target_bank": target_bank, "return_word": return_word,
		"return_pc": return_pc, "sp_before_push": int(cpu["sp"]),
		"sp_after_jsr": (int(cpu["sp"]) - 2) & 0xFF,
		"stack_pushes": [{"address": 0x0100 + int(cpu["sp"]),
			"value": (return_word >> 8) & 0xFF},
			{"address": 0x0100 + ((int(cpu["sp"]) - 1) & 0xFF),
			"value": return_word & 0xFF}],
		"caller_must_execute_target": true,
		"trace_state_used": bool(boundary.get("trace_state_used", false)),
		"test_fixture": bool(boundary.get("test_fixture", false))}
	return _result("source_handoff_contract_ready" if handoff else "source_call_contract_ready",
		boundary, cpu, ram, stack, reads, writes, stack_reads, stack_writes,
		instruction_pcs, branches, call_request, entry_ram, entry_stack)


func _step_local(opcode: int, pc: int, cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, reads: Array[Dictionary], writes: Array[Dictionary],
		stack_reads: Array[Dictionary], stack_writes: Array[Dictionary],
		branches: Array[Dictionary]) -> Dictionary:
	var address := -1
	var value := -1
	var old_value := -1
	var immediate := -1
	match opcode:
		0xA9, 0xA2, 0xC9, 0x49, 0x69, 0xE9:
			immediate = _fetch(int(cpu["pc"]))
			if immediate < 0: return _bad_instruction(pc)
			cpu["pc"] = int(cpu["pc"]) + 1
			match opcode:
				0xA9: cpu["a"] = immediate; _set_nz(cpu, immediate)
				0xA2: cpu["x"] = immediate; _set_nz(cpu, immediate)
				0xC9: _compare(cpu, int(cpu["a"]), immediate)
				0x49: cpu["a"] = (int(cpu["a"]) ^ immediate) & 0xFF; _set_nz(cpu, int(cpu["a"]))
				0x69, 0xE9:
					if (int(cpu["p_known_mask"]) & FLAG_C) == 0:
						return {"ok": false, "error": "Arithmetic at `$%04X` reads an unknown carry flag." % pc}
					if opcode == 0x69: _adc(cpu, immediate)
					else: _sbc(cpu, immediate)
		0xA5, 0x85, 0xAE:
			address = _fetch(int(cpu["pc"]))
			if address < 0: return _bad_instruction(pc)
			cpu["pc"] = int(cpu["pc"]) + 1
			if opcode == 0xA5:
				value = _read_ram(ram, address, pc, reads)
				cpu["a"] = value; _set_nz(cpu, value)
			elif opcode == 0x85:
				old_value = int(ram[address]); ram[address] = int(cpu["a"]) & 0xFF
				writes.append({"source_pc": pc, "address": address, "old": old_value, "value": int(cpu["a"]) & 0xFF})
			else:
				var high := _fetch(int(cpu["pc"]))
				if high < 0: return _bad_instruction(pc)
				cpu["pc"] = int(cpu["pc"]) + 1
				address |= high << 8
				value = _read_ram(ram, address, pc, reads)
				cpu["x"] = value; _set_nz(cpu, value)
		0xAD, 0x8D, 0xCD, 0x2C, 0x4E:
			address = _fetch_word(int(cpu["pc"]))
			if address < 0: return _bad_instruction(pc)
			cpu["pc"] = int(cpu["pc"]) + 2
			if opcode == 0xAD:
				value = _read_ram(ram, address, pc, reads)
				cpu["a"] = value; _set_nz(cpu, value)
			elif opcode == 0x8D:
				old_value = int(ram[address]); ram[address] = int(cpu["a"]) & 0xFF
				writes.append({"source_pc": pc, "address": address, "old": old_value, "value": int(cpu["a"]) & 0xFF})
			elif opcode == 0xCD:
				value = _read_ram(ram, address, pc, reads)
				_compare(cpu, int(cpu["a"]), value)
			elif opcode == 0x2C:
				value = _read_ram(ram, address, pc, reads)
				_set_flag(cpu, FLAG_N, (value & FLAG_N) != 0)
				_set_flag(cpu, FLAG_V, (value & FLAG_V) != 0)
				_set_flag(cpu, FLAG_Z, (int(cpu["a"]) & value) == 0)
			else:
				value = _read_ram(ram, address, pc, reads)
				_set_flag(cpu, FLAG_C, (value & 0x01) != 0)
				value = (value >> 1) & 0xFF
				old_value = int(ram[address]); ram[address] = value
				writes.append({"source_pc": pc, "address": address, "old": old_value, "value": value})
				_set_nz(cpu, value)
		0x48, 0x08:
			if opcode == 0x08 and int(cpu["p_known_mask"]) != 0xFF:
				return {"ok": false, "error": "PHP at `$%04X` would push unknown status bits." % pc}
			value = int(cpu["a"]) if opcode == 0x48 else (int(cpu["p"]) | FLAG_B | FLAG_U)
			_push(cpu, stack, ram, value, pc, stack_writes)
		0x68:
			cpu["a"] = _pop(cpu, stack, ram, pc, stack_reads); _set_nz(cpu, int(cpu["a"]))
		0x28:
			value = _pop(cpu, stack, ram, pc, stack_reads)
			cpu["p"] = (value & (~FLAG_B & 0xFF)) | FLAG_U
			cpu["p_known_mask"] = 0xFF
		0xF0, 0xD0, 0x10, 0x90:
			var displacement := _fetch(int(cpu["pc"]))
			if displacement < 0: return _bad_instruction(pc)
			cpu["pc"] = int(cpu["pc"]) + 1
			var take := false
			var required_flag := FLAG_Z if opcode == 0xF0 or opcode == 0xD0 else FLAG_N if opcode == 0x10 else FLAG_C
			if (int(cpu["p_known_mask"]) & required_flag) == 0:
				return {"ok": false, "error": "Branch at `$%04X` reads an unknown status flag." % pc}
			match opcode:
				0xF0: take = (int(cpu["p"]) & FLAG_Z) != 0
				0xD0: take = (int(cpu["p"]) & FLAG_Z) == 0
				0x10: take = (int(cpu["p"]) & FLAG_N) == 0
				0x90: take = (int(cpu["p"]) & FLAG_C) == 0
			var target := int(cpu["pc"])
			if take:
				target += displacement if displacement < 0x80 else displacement - 0x100
			cpu["pc"] = target
			branches.append({"source_pc": pc, "taken": take, "target_pc": target})
		0x18: _set_flag(cpu, FLAG_C, false)
		0x38: _set_flag(cpu, FLAG_C, true)
		0x2A:
			if (int(cpu["p_known_mask"]) & FLAG_C) == 0:
				return {"ok": false, "error": "ROL at `$%04X` reads an unknown carry flag." % pc}
			value = int(cpu["a"]); old_value = 1 if (int(cpu["p"]) & FLAG_C) != 0 else 0
			_set_flag(cpu, FLAG_C, (value & 0x80) != 0)
			cpu["a"] = ((value << 1) | old_value) & 0xFF; _set_nz(cpu, int(cpu["a"]))
		0x4C:
			address = _fetch_word(int(cpu["pc"]))
			if address < 0: return _bad_instruction(pc)
			cpu["pc"] = address
		0x60:
			var low := _pop(cpu, stack, ram, pc, stack_reads)
			var high := _pop(cpu, stack, ram, pc, stack_reads)
			var return_word := (high << 8) | low
			cpu["pc"] = return_word + 1
			return {"ok": true, "returned": true, "return_word": return_word,
				"return_pc": int(cpu["pc"])}
		_:
			return _bad_instruction(pc)
	return {"ok": true}


func _result(status: String, boundary: Dictionary, cpu: Dictionary,
		ram: PackedByteArray, stack: PackedByteArray, reads: Array[Dictionary],
		writes: Array[Dictionary], stack_reads: Array[Dictionary],
		stack_writes: Array[Dictionary], pcs: Array[int], branches: Array[Dictionary],
		call_contract: Dictionary, entry_ram: PackedByteArray,
		entry_stack: PackedByteArray) -> Dictionary:
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = int(cpu["pc"])
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte E081 field caller: %s" % status
	return {"ok": true, "status": status, "rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH, "source_manifest_sha256": MANIFEST_SHA256,
		"source_span_sha256": SOURCE_SHA256, "entry_pc": int(boundary["pc"]),
		"exit_pc": int(cpu["pc"]), "registers": cpu.duplicate(true),
		"ram_image": output_ram, "stack_page": stack.duplicate(),
		"source_reads": reads.duplicate(true), "source_writes": writes.duplicate(true),
		"source_stack_reads": stack_reads.duplicate(true),
		"source_stack_writes": stack_writes.duplicate(true),
		"source_instruction_pcs": pcs.duplicate(), "source_branches": branches.duplicate(true),
		"call_contract": call_contract.duplicate(true),
		"trace_state_used": bool(boundary.get("trace_state_used", false)),
		"emulator_data_used": bool(boundary.get("trace_state_used", false)),
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"input_boundary_unchanged": entry_ram == (boundary["ram_image"] as PackedByteArray) \
			and entry_stack == (boundary["stack_page"] as PackedByteArray),
		"ppu_effects_applied": false, "apu_effects_applied": false,
		"source_cycle_timing_modeled": false,
		"next_boundary_snapshot": next_boundary}


func _bank_for_pc(pc: int, boundary: Dictionary) -> int:
	var mapper: Dictionary = boundary.get("mapper", {})
	if pc >= 0x8000 and pc < 0xA000: return int(mapper.get("bank_low", -1))
	if pc >= 0xA000 and pc < 0xC000: return int(mapper.get("bank_high", -1))
	if pc >= 0xC000 and pc < 0xE000: return int(mapper.get("fixed_low", -1))
	if pc >= 0xE000: return int(mapper.get("fixed_high", -1))
	return -1


func _read_ram(ram: PackedByteArray, address: int, pc: int,
		reads: Array[Dictionary]) -> int:
	var value := int(ram[address & 0x07FF])
	reads.append({"source_pc": pc, "address": address & 0x07FF, "value": value})
	return value


func _push(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		value: int, pc: int, writes: Array[Dictionary]) -> void:
	var sp := int(cpu["sp"])
	stack[sp] = value & 0xFF
	ram[0x0100 + sp] = value & 0xFF
	writes.append({"source_pc": pc, "address": 0x0100 + sp, "value": value & 0xFF})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		pc: int, reads: Array[Dictionary]) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	reads.append({"source_pc": pc, "address": 0x0100 + sp, "value": value})
	return value


func _compare(cpu: Dictionary, left: int, right: int) -> void:
	var difference := (left - right) & 0x1FF
	_set_flag(cpu, FLAG_C, left >= right)
	_set_nz(cpu, difference & 0xFF)


func _adc(cpu: Dictionary, value: int) -> void:
	var left := int(cpu["a"])
	var carry := 1 if (int(cpu["p"]) & FLAG_C) != 0 else 0
	var total := left + value + carry
	var result := total & 0xFF
	_set_flag(cpu, FLAG_C, total > 0xFF)
	_set_flag(cpu, FLAG_V, ((~(left ^ value) & (left ^ result)) & 0x80) != 0)
	cpu["a"] = result
	_set_nz(cpu, result)


func _sbc(cpu: Dictionary, value: int) -> void:
	_adc(cpu, value ^ 0xFF)


func _set_nz(cpu: Dictionary, value: int) -> void:
	_set_flag(cpu, FLAG_Z, (value & 0xFF) == 0)
	_set_flag(cpu, FLAG_N, ((value & 0xFF) & 0x80) != 0)


func _set_flag(cpu: Dictionary, flag: int, value: bool) -> void:
	var status := int(cpu["p"]) & 0xFF
	if value: status |= flag
	else: status &= ~flag
	cpu["p"] = (status | FLAG_U) & 0xFF
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | flag


func _fetch(address: int) -> int:
	if address < SOURCE_START or address >= SOURCE_END_EXCLUSIVE:
		return -1
	return int(_source[address - SOURCE_START])


func _fetch_word(address: int) -> int:
	var low := _fetch(address)
	var high := _fetch(address + 1)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _read_word(address: int) -> int:
	var low := _fetch(address)
	var high := _fetch(address + 1)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _bad_instruction(pc: int) -> Dictionary:
	return {"ok": false, "error": "Unsupported source opcode `$%02X` at `$%04X`." % [_fetch(pc), pc]}


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message, "rom_sha256": ROM_SHA256,
		"trace_state_used": false, "emulator_data_used": false, "test_fixture": false}


func _fail(message: String) -> bool:
	error_message = message
	return false
