extends RefCounted
class_name RomFreshBank18WorkerPrefix
## Source-byte execution from bank-$18:$800C to the first worker's $C515
## yield-trampoline entry. The task-save handler and scheduler are out of scope.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const RAM_SIZE := 0x800
const ENTRY_PC := 0x800C
const ENTRY_BANK := 0x18
const END_PC := 0xC515
const END_BANK := 0x1E
const SOURCE_FILES := {
	"bank18_worker_entry_to_yield_call_800C_8889.bin": {"bank": 0x18, "start": 0x800C, "end": 0x8889},
	"bank19_worker_lookup_B3BD_B3D1.bin": {"bank": 0x19, "start": 0xB3BD, "end": 0xB3D1},
	"fixed_task_yield_trampoline_C515_C518.bin": {"bank": 0x1E, "start": 0xC515, "end": 0xC518},
}

const FLAG_C := 0x01
const FLAG_Z := 0x02
const FLAG_U := 0x20
const FLAG_V := 0x40
const FLAG_N := 0x80

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _ram := PackedByteArray()
var _a := 0
var _x := 0
var _y := 0
var _p := FLAG_U
var _sp := 0
var _pc := 0
var _write_trace_pc := 0
var _bank_low := 0
var _bank_high := 1
var _mmc3_select := 0
var _writes: Array[Dictionary] = []
var _mapper_writes: Array[Dictionary] = []
var _calls: Array[Dictionary] = []
var _instructions: Array[Dictionary] = []


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Fresh bank-$18 worker source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Fresh bank-$18 worker source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-bank18-worker-prefix-source-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Fresh bank-$18 worker package targets an unsupported ROM/schema.")
	var by_file: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			by_file[String(span.get("file", ""))] = span
	for file_name: String in SOURCE_FILES:
		if not by_file.has(file_name):
			return _fail("Fresh bank-$18 worker manifest omits %s." % file_name)
		var spec: Dictionary = SOURCE_FILES[file_name]
		var entry: Dictionary = by_file[file_name]
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if bytes.size() != int(spec["end"]) - int(spec["start"]) \
				or _sha256(bytes) != String(entry.get("sha256", "")) \
				or String(entry.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(entry.get("bank", "")) != "0x%02X" % int(spec["bank"]) \
				or String(entry.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Fresh bank-$18 worker ROM span failed provenance/size/hash validation: %s." % file_name)
		_sources[file_name] = bytes
	if not _verify_source_boundaries():
		return false
	_configured = true
	return true


## Executes only the source bytes between the prior ROM-derived worker-entry
## state and the $C515 trampoline entry. $C515/$CB0F are not executed.
func execute_to_yield_trampoline(worker_entry: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	if not _validate_worker_entry(worker_entry):
		return {}
	_load_worker_entry(worker_entry)
	var instruction_limit := 256
	while not _at_end_boundary() and _instructions.size() < instruction_limit:
		if not _execute_one():
			return {}
	if not _at_end_boundary():
		_fail("Bank-$18 worker prefix did not reach the source $C515 boundary within its bound.")
		return {}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": ENTRY_PC,
		"entry_bank": ENTRY_BANK,
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram": _selected_ram_state(),
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"stack_top_sp_plus_1_to_8": _bytes_hex(0x0100 | ((_sp + 1) & 0xFF), 8),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"scope": "ROM-byte execution of bank-$18:$800C->$8851 worker setup through JSR $C515; stops at the $CB0F yield trampoline entry",
		"next_source_call": {"pc": 0xC515, "bank": 0x1E, "target": 0xCB0F},
		"runtime_integrated": false,
		"precondition_gaps": ["This standalone prefix consumes a prior ROM-source state; no asynchronous task save/resume, scheduler scan, or NMI cadence is modeled."],
	}


func _validate_worker_entry(worker_entry: Dictionary) -> bool:
	if not bool(worker_entry.get("ok", false)) \
			or String(worker_entry.get("rom_sha256", "")) != ROM_SHA256 \
			or int(worker_entry.get("exit_pc", -1)) != ENTRY_PC \
			or int(worker_entry.get("exit_bank", -1)) != ENTRY_BANK:
		return _fail("Worker prefix requires the source-owned bank-$18:$800C result from RomFreshDaaaContinuation.")
	var registers_variant: Variant = worker_entry.get("registers", {})
	var mapper_variant: Variant = worker_entry.get("mapper", {})
	var ram_variant: Variant = worker_entry.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_entry.get("stack_page", PackedByteArray())
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return _fail("Worker entry lacks source-derived registers, mapper, full RAM image, or stack page.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	if int(registers.get("a", -1)) != 0x00 or int(registers.get("x", -1)) != 0x00 \
			or int(registers.get("y", -1)) != 0x00 or int(registers.get("p", -1)) != 0x23 \
			or int(registers.get("sp", -1)) != 0x4A \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("Worker input CPU/mapper state is not the first source-owned bank-$18:$800C entry.")
	if (ram_variant as PackedByteArray).size() != RAM_SIZE or (stack_variant as PackedByteArray).size() != 0x100:
		return _fail("Worker input RAM or stack-page size is incomplete.")
	return true


func _load_worker_entry(worker_entry: Dictionary) -> void:
	var registers: Dictionary = worker_entry["registers"]
	var mapper: Dictionary = worker_entry["mapper"]
	_ram = (worker_entry["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = worker_entry["stack_page"]
	for index in range(0x100):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = (int(registers["p"]) | FLAG_U) & 0xFF
	_sp = int(registers["sp"]) & 0xFF
	_pc = ENTRY_PC
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF
	_writes.clear()
	_mapper_writes.clear()
	_calls.clear()
	_instructions.clear()


func _at_end_boundary() -> bool:
	return _pc == END_PC and _current_bank_for_pc(_pc) == END_BANK


func _execute_one() -> bool:
	var start_pc := _pc
	var start_bank := _current_bank_for_pc(_pc)
	var opcode := _read_cpu(_pc)
	if opcode < 0:
		return false
	_write_trace_pc = (_pc + _opcode_length(opcode)) & 0xFFFF
	match opcode:
		0x4C: # JMP abs
			_pc = _read_word(_pc + 1)
			if _pc < 0: return false
		0xA8: # TAY
			_y = _a
			_set_nz(_y)
			_pc += 1
		0x0A: # ASL A
			_set_flag(FLAG_C, (_a & 0x80) != 0)
			_a = (_a << 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xAA: # TAX
			_x = _a
			_set_nz(_x)
			_pc += 1
		0xBD: # LDA abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _x) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0x85: # STA zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 2
		0x98: # TYA
			_a = _y
			_set_nz(_a)
			_pc += 1
		0x29: # AND #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a &= value
			_set_nz(_a)
			_pc += 2
		0x4A: # LSR A
			_set_flag(FLAG_C, (_a & 0x01) != 0)
			_a = (_a >> 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xB9: # LDA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xCA: # DEX
			_x = (_x - 1) & 0xFF
			_set_nz(_x)
			_pc += 1
		0x30: # BMI
			var displacement := _read_cpu(_pc + 1)
			if displacement < 0: return false
			if displacement >= 0x80: displacement -= 0x100
			_pc = _pc + 2 + displacement if (_p & FLAG_N) != 0 else _pc + 2
		0x8D: # STA abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 3
		0x6D: # ADC abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 3
		0xA9: # LDA #imm
			_a = _read_cpu(_pc + 1)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x20: # JSR
			_write_trace_pc = (_pc + 2) & 0xFFFF
			var target := _read_word(_pc + 1)
			if target < 0: return false
			var return_minus_one := (_pc + 2) & 0xFFFF
			if not _push((return_minus_one >> 8) & 0xFF, start_pc, start_bank) \
					or not _push(return_minus_one & 0xFF, start_pc, start_bank): return false
			_calls.append({"callsite": start_pc, "target": target,
				"bank": _current_bank_for_pc(target), "sp_after_push": _sp})
			_pc = target
		_:
			return _fail("Unsupported worker-prefix opcode $%02X at $%04X (bank $%02X)." % [opcode, start_pc, start_bank])
	_instructions.append({"pc": start_pc, "bank": start_bank, "opcode": opcode, "next_pc": _pc})
	return true


func _add_with_carry(value: int) -> void:
	var before := _a
	var sum := before + value + (1 if (_p & FLAG_C) != 0 else 0)
	_set_flag(FLAG_C, sum > 0xFF)
	_set_flag(FLAG_V, ((~(before ^ value) & (before ^ sum)) & 0x80) != 0)
	_a = sum & 0xFF
	_set_nz(_a)


func _read_word(address: int) -> int:
	var low := _read_cpu(address)
	var high := _read_cpu(address + 1)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _read_cpu(address: int) -> int:
	if address < 0 or address > 0xFFFF:
		_fail("Worker-prefix read outside address space at $%X." % address)
		return -1
	if address < 0x2000:
		return int(_ram[address & 0x07FF])
	var bank := _current_bank_for_pc(address)
	for file_name: String in SOURCE_FILES:
		var spec: Dictionary = SOURCE_FILES[file_name]
		if int(spec["bank"]) == bank and address >= int(spec["start"]) and address < int(spec["end"]):
			return int((_sources[file_name] as PackedByteArray)[address - int(spec["start"])])
	_fail("Worker-prefix ROM read $%04X in bank $%02X is outside preserved spans." % [address, bank])
	return -1


func _write_cpu(address: int, value: int, source_pc: int, source_bank: int) -> bool:
	value &= 0xFF
	if address < 0x2000:
		var mirrored := address & 0x07FF
		_ram[mirrored] = value
		_writes.append({"pc": source_pc, "trace_pc": _write_trace_pc, "bank": source_bank,
			"address": mirrored, "value": value})
		return true
	if address == 0x8000:
		_mmc3_select = value & 0x07
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	if address == 0x8001:
		if _mmc3_select == 6: _bank_low = value
		elif _mmc3_select == 7: _bank_high = value
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	return _fail("Unsupported worker-prefix memory-mapped write $%04X=$%02X at $%04X." % [address, value, source_pc])


func _push(value: int, source_pc: int, source_bank: int) -> bool:
	if not _write_cpu(0x0100 | _sp, value, source_pc, source_bank): return false
	_sp = (_sp - 1) & 0xFF
	return true


func _set_nz(value: int) -> void:
	_set_flag(FLAG_Z, (value & 0xFF) == 0)
	_set_flag(FLAG_N, (value & 0x80) != 0)


func _set_flag(mask: int, enabled: bool) -> void:
	if enabled: _p |= mask
	else: _p &= ~mask
	_p |= FLAG_U


func _current_bank_for_pc(address: int) -> int:
	if address >= 0xC000 and address < 0xE000: return 0x1E
	if address >= 0xE000: return 0x1F
	if address >= 0xA000 and address < 0xC000: return _bank_high
	return _bank_low


func _opcode_length(opcode: int) -> int:
	match opcode:
		0x29, 0x30, 0x85, 0xA9:
			return 2
		0x20, 0x4C, 0x6D, 0x8D, 0xB9, 0xBD:
			return 3
		_:
			return 1


func _selected_ram_state() -> Dictionary:
	return {
		"$0022": int(_ram[0x0022]), "$0023": int(_ram[0x0023]),
		"$0024": int(_ram[0x0024]), "$0025": int(_ram[0x0025]),
		"$0050": int(_ram[0x0050]), "$0051": int(_ram[0x0051]),
		"$05C5": int(_ram[0x05C5]), "$05C6": int(_ram[0x05C6]),
		"$0700-$0704": _bytes_hex(0x0700, 5),
	}


func _bytes_hex(start: int, count: int) -> String:
	var output := PackedByteArray()
	for offset in range(count): output.append(int(_ram[start + offset]))
	return output.hex_encode()


func _verify_source_boundaries() -> bool:
	var worker_bytes: PackedByteArray = _sources["bank18_worker_entry_to_yield_call_800C_8889.bin"]
	var call_offset := 0x8886 - 0x800C
	if worker_bytes.slice(0, 3) != PackedByteArray([0x4C, 0x51, 0x88]) \
			or worker_bytes.slice(call_offset - 2, call_offset + 3) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _fail("Bank-$18 worker entry or $8886 JSR boundary bytes changed.")
	if (_sources["bank19_worker_lookup_B3BD_B3D1.bin"] as PackedByteArray).slice(18, 20) != PackedByteArray([0x53, 0xB4]) \
			or (_sources["fixed_task_yield_trampoline_C515_C518.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x0F, 0xCB]):
		return _fail("Bank-$19 lookup pointer or fixed $C515->$CB0F trampoline bytes changed.")
	return true


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
