extends RefCounted
class_name RomFreshE6ecHolderCopyExecutor
## Executes the byte-checked $E6EC holder copy, its $CD7C pointer lookup, and
## the compact $CDE2 coordinate-to-field-index routine from live route RAM.

const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const HOLDER_RESOLVER_SCRIPT := preload("res://scripts/gameplay/rom_first_command_holder_coordinate_resolver.gd")
const HOLDER_ROOT := "res://reference/rom_extract/gameplay/first_command_field/holder_coordinates/"
const E6EC_PATH := HOLDER_ROOT + "bank_1f_e6ec_holder_coordinate_copy.bin"
const CDE2_PATH := HOLDER_ROOT + "bank_1f_cde2_coordinate_index_helper.bin"
const POSITION_ROOT := "res://reference/rom_extract/gameplay/first_command_field/player_record_positions/"
const POINTERS_PATH := POSITION_ROOT + "bank_1f_cd89_record_pointer_table_22.bin"
const E6EC_SHA256 := "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c"
const E6EC_HEX := "ad4104207ccda006b1348d3506aaa008b1348d3706a820e2cd8dfe0560"
const CDE2_SHA256 := "e5f6dcb9f5d2451ba1770add2906daa504befaf7800e3bfe2e1b163708e58a83"
const CDE2_HEX := "8a38e930901dc9a0b0194a4a4aaa9838e950900fc960b00b4a4a4aca300718690cd0f8a9ff60"
const POINTERS_SHA256 := "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"
const STACK_PAGE_SIZE := 0x0100
const RAM_SIZE := 0x0800

var error_message := ""
var _configured := false
var _e6ec := PackedByteArray()
var _cde2 := PackedByteArray()
var _pointers := PackedByteArray()


func configure() -> bool:
	error_message = ""
	_configured = false
	var holder_resolver = HOLDER_RESOLVER_SCRIPT.new()
	if not holder_resolver.configure():
		return _fail("Holder-copy source package failed: " + String(holder_resolver.last_error))
	_e6ec = FileAccess.get_file_as_bytes(E6EC_PATH)
	_cde2 = FileAccess.get_file_as_bytes(CDE2_PATH)
	_pointers = FileAccess.get_file_as_bytes(POINTERS_PATH)
	if _e6ec.size() != 29 or _e6ec.hex_encode() != E6EC_HEX \
			or _sha256(_e6ec) != E6EC_SHA256:
		return _fail("The supplied-ROM $E6EC holder-copy instructions failed their exact span checks.")
	if _cde2.size() != 38 or _cde2.hex_encode() != CDE2_HEX \
			or _sha256(_cde2) != CDE2_SHA256:
		return _fail("The supplied-ROM $CDE2 coordinate-index instructions failed their exact span checks.")
	if _pointers.size() != 44 or _sha256(_pointers) != POINTERS_SHA256:
		return _fail("The supplied-ROM $CD89 player-record pointer table failed its source check.")
	_configured = true
	return true


## Runs from the live slot-$05 JSR $DB0B->$E6EC boundary and returns at $DB0E,
## before the caller loads or queues scenario $36.
func execute_from_live_boundary(boundary: Dictionary, match_context: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked holder-copy ROM sources first.")
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_PAGE_SIZE:
		return _failure("The live $E6EC boundary must include complete RAM and stack images.")
	if String(boundary.get("rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xE6EC \
			or int(boundary.get("sp", -1)) != 0x4E \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D:
		return _failure("Holder copying requires live slot-$05 $E6EC / SP $4E / bank $1C/$1D.")
	var source_context: Dictionary = match_context.get("source_context", {})
	if int(match_context.get("match_index", -1)) != 0 \
			or int(match_context.get("formation_002c", -1)) != 0 \
			or int(match_context.get("formation_002e", -1)) != 0 \
			or int(match_context.get("possession_side_05fb", -1)) != 0 \
			or String(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or String(source_context.get("label", "")).is_empty():
		return _failure("Holder copying requires named source-derived match-zero state, not capture data.")

	var ram := (ram_variant as PackedByteArray).duplicate()
	var stack := (stack_variant as PackedByteArray).duplicate()
	if ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x014F]) != 0x0D or int(ram[0x0150]) != 0xDB \
			or int(ram[0x05FC]) != int(boundary.get("a", -1)):
		return _failure("The $E6EC input does not retain the caller's verified $DB0D return frame and receiver A.")
	var holder_slot := int(ram[0x0441])
	if holder_slot < 0 or holder_slot >= 22:
		return _failure("The live $0441 holder index is outside the 22 source player records.")
	var record_pointer := int(_pointers[holder_slot * 2]) \
		| (int(_pointers[holder_slot * 2 + 1]) << 8)
	if record_pointer != 0x0300 + holder_slot * 0x0C:
		return _failure("The live $CD89 table entry disagrees with the 12-byte player-record layout.")

	var cpu := {
		"a": int(boundary.get("a", 0)) & 0xFF,
		"x": int(boundary.get("x", 0)) & 0xFF,
		"y": int(boundary.get("y", 0)) & 0xFF,
		"p": int(boundary.get("p", 0x20)) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0)) & 0xFF,
		"sp": 0x4E,
	}
	var memory_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var calls: Array[Dictionary] = []
	var source_instructions: Array[Dictionary] = []

	# $E6EC: LDA $0441
	_cpu_lda(cpu, holder_slot)
	source_instructions.append({"pc": 0xE6EC, "opcode": 0xAD})
	# $E6EF: JSR $CD7C; the callee is the checked 13-byte lookup in the
	# existing position-source package and indexes the checked $CD89 table.
	_push_jsr(cpu, ram, stack, stack_writes, 0xE6EF, 0xE6F1)
	calls.append({"callsite": 0xE6EF, "target": 0xCD7C,
		"return_word": 0xE6F1, "return_pc": 0xE6F2, "sp_after_push": 0x4C})
	var doubled_slot := (int(cpu["a"]) << 1) & 0xFF
	_cpu_set_nz(cpu, doubled_slot)
	cpu["a"] = doubled_slot
	cpu["y"] = doubled_slot
	_cpu_set_nz(cpu, doubled_slot)
	var record_low := int(_pointers[int(cpu["y"])])
	_cpu_lda(cpu, record_low)
	_write_ram(ram, memory_writes, 0xCD81, 0x0034, int(cpu["a"]))
	var high_index := (0x01 + int(cpu["y"])) & 0xFF
	var record_high := int(_pointers[high_index])
	_cpu_lda(cpu, record_high)
	_write_ram(ram, memory_writes, 0xCD86, 0x0035, int(cpu["a"]))
	var cd7c_return := _pop_rts(cpu, stack)
	if cd7c_return != 0xE6F2 or int(cpu["sp"]) != 0x4E:
		return _failure("The $CD7C source lookup did not RTS to $E6F2 with the original stack depth.")

	# $E6F2-$E701: read record +6/+8 into $0635/$0637, preserving source order.
	cpu["y"] = 0x06
	_cpu_set_nz(cpu, 0x06)
	var pointer_after_lookup := int(ram[0x0034]) | (int(ram[0x0035]) << 8)
	_cpu_lda(cpu, int(ram[(pointer_after_lookup + int(cpu["y"])) & 0x07FF]))
	_write_ram(ram, memory_writes, 0xE6F6, 0x0635, int(cpu["a"]))
	cpu["x"] = int(cpu["a"])
	_cpu_set_nz(cpu, int(cpu["x"]))
	cpu["y"] = 0x08
	_cpu_set_nz(cpu, 0x08)
	_cpu_lda(cpu, int(ram[(pointer_after_lookup + int(cpu["y"])) & 0x07FF]))
	_write_ram(ram, memory_writes, 0xE6FE, 0x0637, int(cpu["a"]))
	cpu["y"] = int(cpu["a"])
	_cpu_set_nz(cpu, int(cpu["y"]))

	# $E702: JSR $CDE2. Its 38 checked bytes are interpreted until RTS.
	_push_jsr(cpu, ram, stack, stack_writes, 0xE702, 0xE704)
	calls.append({"callsite": 0xE702, "target": 0xCDE2,
		"return_word": 0xE704, "return_pc": 0xE705, "sp_after_push": 0x4C})
	var cde2_result := _execute_cde2(cpu, stack)
	if not bool(cde2_result.get("ok", false)):
		return _failure(String(cde2_result.get("error", "The $CDE2 byte interpreter failed.")))
	source_instructions.append_array(cde2_result.get("instructions", []))
	_write_ram(ram, memory_writes, 0xE705, 0x05FE, int(cpu["a"]))
	var outer_return := _pop_rts(cpu, stack)
	if outer_return != 0xDB0E:
		return _failure("The $E6EC RTS did not return to the caller's pre-$36 boundary $DB0E.")
	if int(cpu["sp"]) != 0x50:
		return _failure("The nested $E6EC calls did not restore the incoming SP $50.")

	return {
		"ok": true,
		"status": "returned_to_slot05_db0e_before_scenario36",
		"rom_sha256": EXPECTED_ROM_SHA256,
		"source_manifest": HOLDER_ROOT + "manifest.json",
		"source_manifest_sha256": "aa951660b645d51a2c8fbfa6fbbc44026c478daea8bd8068b8afedf1a08b2bf3",
		"source_hashes": {"E6EC": E6EC_SHA256, "CDE2": CDE2_SHA256,
			"CD89": POINTERS_SHA256},
		"entry": {"pc": 0xE6EC, "sp": 0x4E, "holder_slot_0441": holder_slot,
			"receiver_slot_05fc": int(ram[0x05FC])},
		"holder_copy": {"holder_slot_0441": holder_slot, "record_pointer": record_pointer,
			"x_0635": int(ram[0x0635]), "y_0637": int(ram[0x0637]),
			"tile_index_05fe": int(ram[0x05FE])},
		"registers": {"pc": outer_return, "sp": int(cpu["sp"]),
			"a": int(cpu["a"]), "x": int(cpu["x"]), "y": int(cpu["y"]),
			"p": int(cpu["p"]), "p_known_mask": int(cpu["p_known_mask"])},
		"ram_image": ram,
		"stack_page": stack,
		"memory_writes": memory_writes,
		"stack_writes": stack_writes,
		"calls": calls,
		"instruction_events": source_instructions,
		"ppu_bus_events": [], "apu_register_writes": [],
		"source_cycle_timing_modeled": false,
		"holder_selection_derived": false,
		"source_context": source_context.duplicate(true),
		"error": "",
	}


func _execute_cde2(cpu: Dictionary, stack: PackedByteArray) -> Dictionary:
	var instructions: Array[Dictionary] = []
	var pc := 0xCDE2
	for _step in 128:
		if pc < 0xCDE2 or pc > 0xCE07:
			return {"ok": false, "error": "$CDE2 branch escaped its verified source span."}
		var offset := pc - 0xCDE2
		var opcode := int(_cde2[offset])
		instructions.append({"pc": pc, "opcode": opcode})
		match opcode:
			0x8A: # TXA
				cpu["a"] = int(cpu["x"])
				_cpu_set_nz(cpu, int(cpu["a"]))
				pc += 1
			0x38: # SEC
				_cpu_set_flag(cpu, 0x01, true)
				pc += 1
			0xE9: # SBC #imm
				var operand := int(_cde2[offset + 1])
				var old_a := int(cpu["a"])
				var borrow := 0 if (int(cpu["p"]) & 0x01) != 0 else 1
				var difference := old_a - operand - borrow
				var result := difference & 0xFF
				_cpu_set_flag(cpu, 0x01, difference >= 0)
				_cpu_set_flag(cpu, 0x40, (((old_a ^ result) & (old_a ^ operand) & 0x80) != 0))
				cpu["a"] = result
				_cpu_set_nz(cpu, result)
				pc += 2
			0x90, 0xB0, 0x30, 0xD0: # BCC, BCS, BMI, BNE
				var displacement := int(_cde2[offset + 1])
				if displacement >= 0x80:
					displacement -= 0x100
				var take := false
				match opcode:
					0x90: take = (int(cpu["p"]) & 0x01) == 0
					0xB0: take = (int(cpu["p"]) & 0x01) != 0
					0x30: take = (int(cpu["p"]) & 0x80) != 0
					0xD0: take = (int(cpu["p"]) & 0x02) == 0
				pc = (pc + 2 + displacement) & 0xFFFF if take else pc + 2
			0xC9: # CMP #imm
				var compare_result := (int(cpu["a"]) - int(_cde2[offset + 1])) & 0xFF
				_cpu_set_flag(cpu, 0x01, int(cpu["a"]) >= int(_cde2[offset + 1]))
				_cpu_set_nz(cpu, compare_result)
				pc += 2
			0x4A: # LSR A
				var old_a := int(cpu["a"])
				_cpu_set_flag(cpu, 0x01, (old_a & 0x01) != 0)
				cpu["a"] = old_a >> 1
				_cpu_set_nz(cpu, int(cpu["a"]))
				pc += 1
			0xAA: # TAX
				cpu["x"] = int(cpu["a"])
				_cpu_set_nz(cpu, int(cpu["x"]))
				pc += 1
			0x98: # TYA
				cpu["a"] = int(cpu["y"])
				_cpu_set_nz(cpu, int(cpu["a"]))
				pc += 1
			0xCA: # DEX
				cpu["x"] = (int(cpu["x"]) - 1) & 0xFF
				_cpu_set_nz(cpu, int(cpu["x"]))
				pc += 1
			0x18: # CLC
				_cpu_set_flag(cpu, 0x01, false)
				pc += 1
			0x69: # ADC #imm
				var old_a := int(cpu["a"])
				var operand := int(_cde2[offset + 1])
				var sum := old_a + operand + (1 if (int(cpu["p"]) & 0x01) != 0 else 0)
				var result := sum & 0xFF
				_cpu_set_flag(cpu, 0x01, sum > 0xFF)
				_cpu_set_flag(cpu, 0x40, ((~(old_a ^ operand) & (old_a ^ result) & 0x80) != 0))
				cpu["a"] = result
				_cpu_set_nz(cpu, result)
				pc += 2
			0xA9: # LDA #imm
				_cpu_lda(cpu, int(_cde2[offset + 1]))
				pc += 2
			0x60: # RTS
				var return_pc := _pop_rts(cpu, stack)
				if return_pc != 0xE705:
					return {"ok": false, "error": "$CDE2 RTS did not return to $E705."}
				return {"ok": true, "return_pc": return_pc,
					"instructions": instructions, "error": ""}
			_:
				return {"ok": false, "error": "Unsupported $CDE2 opcode $%02X at $%04X." % [opcode, pc]}
	return {"ok": false, "error": "$CDE2 did not RTS within its bounded instruction count."}


func _push_jsr(cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		stack_writes: Array[Dictionary], callsite: int, return_word: int) -> void:
	var sp := int(cpu["sp"])
	_write_stack(stack, ram, stack_writes, callsite, sp, (return_word >> 8) & 0xFF)
	sp = (sp - 1) & 0xFF
	_write_stack(stack, ram, stack_writes, callsite, sp, return_word & 0xFF)
	cpu["sp"] = (sp - 1) & 0xFF


func _pop_rts(cpu: Dictionary, stack: PackedByteArray) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var low := int(stack[sp])
	sp = (sp + 1) & 0xFF
	var high := int(stack[sp])
	cpu["sp"] = sp
	return (((high << 8) | low) + 1) & 0xFFFF


func _write_stack(stack: PackedByteArray, ram: PackedByteArray,
		stack_writes: Array[Dictionary], pc: int, sp: int, value: int) -> void:
	var address := 0x0100 + (sp & 0xFF)
	stack[sp & 0xFF] = value & 0xFF
	ram[address] = value & 0xFF
	stack_writes.append({"pc": pc, "address": address, "value": value & 0xFF})


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary],
		pc: int, address: int, value: int) -> void:
	ram[address & 0x07FF] = value & 0xFF
	writes.append({"pc": pc, "address": address & 0x07FF, "value": value & 0xFF})


func _cpu_lda(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_cpu_set_nz(cpu, int(cpu["a"]))


func _cpu_set_nz(cpu: Dictionary, value: int) -> void:
	_cpu_set_flag(cpu, 0x02, (value & 0xFF) == 0)
	_cpu_set_flag(cpu, 0x80, (value & 0x80) != 0)


func _cpu_set_flag(cpu: Dictionary, flag: int, enabled: bool) -> void:
	var p := int(cpu["p"]) & ~flag
	if enabled:
		p |= flag
	cpu["p"] = (p | 0x20) & 0xFF
	cpu["p_known_mask"] = (int(cpu["p_known_mask"]) | flag) & 0xFF


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
