extends RefCounted
class_name RomFreshPeriodTask
## Bounded ROM-byte execution of the initial slot-$05 fresh-period path.
## Supports only period 0 and opponent ID $03, ending at JMP $DAAA. This is
## not a general CPU interpreter, scheduler, or route executor.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_period_task/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const CODE_FILE := "slot05_D11E_D182.bin"
const TABLE_FILE := "camera_table_D183_D184.bin"
const CODE_START := 0xD11E
const CODE_END := 0xD182
const CAMERA_TABLE_START := 0xD183
const EXIT_PC := 0xDAAA
const RAM_SIZE := 0x800

const SOURCE_SPANS := {
	"slot05_code": {
		"file": CODE_FILE,
		"cpu_start": "$D11E",
		"cpu_end_inclusive": "$D182",
		"file_offset": "0x03D12E",
		"length": 101,
		"sha256": "28895a5c3512a45e1b1a59c4324654ec03bb5f2ea413445e32333aa3bd6b87cc",
	},
	"opponent_camera_table": {
		"file": TABLE_FILE,
		"cpu_start": "$D183",
		"cpu_end_inclusive": "$D184",
		"file_offset": "0x03D193",
		"length": 2,
		"sha256": "0e1862b77227e30a4b6f6d40295f173db76d2473f8b9e31b241239c07a5837fa",
	},
}

var error_message := ""
var _configured := false
var _code := PackedByteArray()
var _camera_table := PackedByteArray()
var _ram: Dictionary = {}
var _a := 0
var _x := 0
var _y := 0
var _sp := 0
var _pc := 0
var _zero := false
var _carry := false
var _writes: Array[Dictionary] = []
var _instructions: Array[Dictionary] = []


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_code.clear()
	_camera_table.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Fresh-period source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Fresh-period source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh-period source manifest targets a different ROM revision.")
	var entries_by_file: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for key: String in SOURCE_SPANS:
		var spec: Dictionary = SOURCE_SPANS[key]
		var file_name := String(spec["file"])
		if not entries_by_file.has(file_name):
			return _fail("Fresh-period source manifest omits %s." % file_name)
		var manifest_entry: Dictionary = entries_by_file[file_name]
		for metadata_key: String in ["cpu_start", "cpu_end_inclusive", "file_offset", "length", "sha256"]:
			var metadata_matches := int(manifest_entry.get(metadata_key, -1)) == int(spec[metadata_key]) \
					if metadata_key == "length" else str(manifest_entry.get(metadata_key, "")) == str(spec[metadata_key])
			if not metadata_matches:
				return _fail("Fresh-period source metadata differs for %s (%s)." % [file_name, metadata_key])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]):
			return _fail("Fresh-period source span failed its size/hash check: %s." % file_name)
		var manifest_hex := String(manifest_entry.get("bytes", "")).to_lower().replace(" ", "")
		if manifest_hex != bytes.hex_encode():
			return _fail("Fresh-period manifest byte listing differs for %s." % file_name)
		if key == "slot05_code":
			_code = bytes
		else:
			_camera_table = bytes
	if not _verify_source_boundaries():
		return false
	_configured = true
	return true


## Executes the bounded initial slot-$05 fresh-game path. The caller must pass
## the decoded scheduler entry state and match inputs; no endpoint RAM or trace
## snapshot values are accepted as implicit defaults.
func execute_fresh_match_zero(source_inputs: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure the hash-checked fresh-period source before execution.")
		return {}
	if not _validate_caller_inputs(source_inputs):
		return {}
	_reset_execution_state(source_inputs)
	var instruction_limit := 128
	while _pc != EXIT_PC and _instructions.size() < instruction_limit:
		if not _execute_one_instruction():
			return {}
	if _pc != EXIT_PC:
		_fail("Slot-$05 source slice did not reach its verified $DAAA handoff.")
		return {}
	var ram_result := {
		"$0027": int(_ram.get(0x0027, -1)),
		"$002B": int(_ram.get(0x002B, -1)),
		"$003A": int(_ram.get(0x003A, -1)),
		"$0613": int(_ram.get(0x0613, -1)),
		"$0629": int(_ram.get(0x0629, -1)),
		"$063E": int(_ram.get(0x063E, -1)),
		"$0640": int(_ram.get(0x0640, -1)),
		"$0641": int(_ram.get(0x0641, -1)),
		"$05F7": int(_ram.get(0x05F7, -1)),
		"$05F8": int(_ram.get(0x05F8, -1)),
		"$05F9": int(_ram.get(0x05F9, -1)),
	}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_code_sha256": String(SOURCE_SPANS["slot05_code"]["sha256"]),
		"camera_table_sha256": String(SOURCE_SPANS["opponent_camera_table"]["sha256"]),
		"source_context": source_inputs["source_context"].duplicate(true),
		"entry": {"pc": CODE_START, "slot_base": 0x05, "sp": int(source_inputs["entry_sp"])},
		"exit_pc": _pc,
		"exit_sp": _sp,
		"registers": {
			"a": _a, "x": _x, "y": _y,
			"p": 0x20 | (0x01 if _carry else 0) | (0x02 if _zero else 0),
			"sp": _sp, "pc": _pc,
		},
		"scheduler_dispatch": source_inputs.get("scheduler_dispatch", {}).duplicate(true),
		"ram_image": _ram_image(),
		"ram": ram_result,
		"writes": _writes.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"scope": "initial slot-$05 fresh period 0 / opponent $03 only; stops at JMP $DAAA",
	}


func _validate_caller_inputs(source_inputs: Dictionary) -> bool:
	var source_context: Variant = source_inputs.get("source_context")
	if not source_context is Dictionary:
		return _fail("Caller must provide a decoded-game-logic source_context.")
	if String(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or String(source_context.get("source_event", "")).is_empty():
		return _fail("Caller source_context must identify its decoded source event.")
	if int(source_inputs.get("task_slot_base", -1)) != 0x05 \
			or int(source_inputs.get("entry_pc", -1)) != CODE_START:
		return _fail("This slice requires the initial slot-$05 dispatch at $D11E.")
	if int(source_inputs.get("period_0027", -1)) != 0:
		return _fail("This slice supports only caller-derived fresh period $0027=0.")
	if int(source_inputs.get("opponent_id_002b", -1)) != 3:
		return _fail("This slice supports only caller-derived opponent ID $002B=$03.")
	var entry_sp := int(source_inputs.get("entry_sp", -1))
	if entry_sp < 0 or entry_sp > 0xFF:
		return _fail("Caller must provide an 8-bit slot-$05 entry SP.")
	return true


func _reset_execution_state(source_inputs: Dictionary) -> void:
	_ram.clear()
	var source_ram: Variant = source_inputs.get("ram_image", PackedByteArray())
	if source_ram is PackedByteArray and source_ram.size() == RAM_SIZE:
		for address in range(RAM_SIZE):
			_ram[address] = int(source_ram[address])
	_ram[0x0027] = int(source_inputs["period_0027"])
	_ram[0x002B] = int(source_inputs["opponent_id_002b"])
	var scheduler_dispatch: Variant = source_inputs.get("scheduler_dispatch", {})
	_a = int(scheduler_dispatch.get("a", 0)) if scheduler_dispatch is Dictionary else 0
	_x = int(scheduler_dispatch.get("x", 0)) if scheduler_dispatch is Dictionary else 0
	_y = int(scheduler_dispatch.get("y", source_inputs.get("entry_y", 0))) \
			if scheduler_dispatch is Dictionary else int(source_inputs.get("entry_y", 0))
	_sp = int(source_inputs["entry_sp"])
	_pc = int(source_inputs.get("entry_pc", CODE_START))
	_zero = false
	_carry = false
	_writes.clear()
	_instructions.clear()


func _execute_one_instruction() -> bool:
	var start_pc := _pc
	var opcode := _read_code_byte(_pc)
	if opcode < 0:
		return false
	match opcode:
		0xAD: # LDA absolute
			var address := _read_word(_pc + 1)
			if address < 0:
				return false
			var value := _read_ram(address)
			if value < 0:
				return false
			_a = value
			_zero = _a == 0
			_pc += 3
		0xC9: # CMP immediate
			var value := _read_code_byte(_pc + 1)
			if value < 0:
				return false
			_zero = _a == value
			_carry = _a >= value
			_pc += 2
		0xD0, 0xF0, 0xB0: # BNE, BEQ, BCS
			var displacement := _read_code_byte(_pc + 1)
			if displacement < 0:
				return false
			if displacement >= 0x80:
				displacement -= 0x100
			var take_branch := (opcode == 0xD0 and not _zero) \
					or (opcode == 0xF0 and _zero) \
					or (opcode == 0xB0 and _carry)
			_pc = _pc + 2 + displacement if take_branch else _pc + 2
		0x4C: # JMP absolute; only the verified $DAAA exit is supported
			var target := _read_word(_pc + 1)
			if target != EXIT_PC:
				return _fail("Unexpected slot-$05 jump target `$%04X`." % target)
			_pc = target
		0xA9: # LDA immediate
			_a = _read_code_byte(_pc + 1)
			if _a < 0:
				return false
			_zero = _a == 0
			_pc += 2
		0x8D: # STA absolute
			var address := _read_word(_pc + 1)
			if address < 0 or address >= RAM_SIZE:
				return _fail("Slot-$05 store is outside modeled internal RAM.")
			_ram[address] = _a
			_writes.append({"pc": start_pc, "address": address, "value": _a})
			_pc += 3
		0x0A: # ASL A
			_carry = (_a & 0x80) != 0
			_a = (_a << 1) & 0xFF
			_zero = _a == 0
			_pc += 1
		0x85: # STA zero page
			var address := _read_code_byte(_pc + 1)
			if address < 0:
				return false
			_ram[address] = _a
			_writes.append({"pc": start_pc, "address": address, "value": _a})
			_pc += 2
		0xAE: # LDX absolute
			var address := _read_word(_pc + 1)
			if address < 0:
				return false
			_x = _read_ram(address)
			if _x < 0:
				return false
			_zero = _x == 0
			_pc += 3
		0xE0: # CPX immediate
			var value := _read_code_byte(_pc + 1)
			if value < 0:
				return false
			_zero = _x == value
			_carry = _x >= value
			_pc += 2
		0x18: # CLC
			_carry = false
			_pc += 1
		0x65: # ADC zero page
			var address := _read_code_byte(_pc + 1)
			if address < 0:
				return false
			var value := _read_ram(address)
			if value < 0:
				return false
			var total := _a + value + (1 if _carry else 0)
			_carry = total > 0xFF
			_a = total & 0xFF
			_zero = _a == 0
			_pc += 2
		0xAA: # TAX
			_x = _a
			_zero = _x == 0
			_pc += 1
		0xBD: # LDA absolute,X; the selected table must be the preserved D183-D184 span
			var address := _read_word(_pc + 1)
			if address < 0:
				return false
			var source_address := address + _x
			var value := _read_rom_source_byte(source_address)
			if value < 0:
				return false
			_a = value
			_zero = _a == 0
			_pc += 3
		0xA2: # LDX immediate
			_x = _read_code_byte(_pc + 1)
			if _x < 0:
				return false
			_zero = _x == 0
			_pc += 2
		0x9A: # TXS
			_sp = _x
			_pc += 1
		_:
			return _fail("Unsupported opcode `$%02X` at `$%04X` in bounded slot-$05 path." % [opcode, _pc])
	_instructions.append({"pc": start_pc, "opcode": opcode, "next_pc": _pc})
	return true


func _read_ram(address: int) -> int:
	if address < 0 or address >= RAM_SIZE:
		_fail("Slot-$05 read is outside modeled internal RAM at `$%04X`." % address)
		return -1
	if not _ram.has(address):
		_fail("Slot-$05 path read caller-owned RAM `$%04X` without an explicit source input." % address)
		return -1
	return int(_ram[address])


func _ram_image() -> PackedByteArray:
	var image := PackedByteArray()
	image.resize(RAM_SIZE)
	for address in range(RAM_SIZE):
		image[address] = int(_ram.get(address, 0)) & 0xFF
	return image


func _read_code_byte(address: int) -> int:
	if address < CODE_START or address > CODE_END:
		_fail("Slot-$05 instruction/operand read escaped the hash-checked code span at `$%04X`." % address)
		return -1
	return int(_code[address - CODE_START])


func _read_word(address: int) -> int:
	var low := _read_code_byte(address)
	var high := _read_code_byte(address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _read_rom_source_byte(address: int) -> int:
	if address < CAMERA_TABLE_START or address >= CAMERA_TABLE_START + _camera_table.size():
		_fail("Slot-$05 indexed ROM read escaped the hash-checked camera table at `$%04X`." % address)
		return -1
	return int(_camera_table[address - CAMERA_TABLE_START])


func _verify_source_boundaries() -> bool:
	if _code.size() != 101 or _camera_table.size() != 2:
		return _fail("Fresh-period source span lengths changed.")
	if _code[0] != 0xAD or _code[0x51] != 0x8D or _code[0x61] != 0x9A \
			or _code[0x62] != 0x4C or _code[0x63] != 0xAA or _code[0x64] != 0xDA:
		return _fail("Fresh-period source no longer begins at $D11E or ends in JMP $DAAA.")
	if _camera_table != PackedByteArray([0xB4, 0x00]):
		return _fail("Opponent-$03 camera-table entry changed from its verified ROM bytes.")
	return true


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
