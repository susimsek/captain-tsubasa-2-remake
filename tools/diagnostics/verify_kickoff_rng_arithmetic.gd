extends SceneTree

const RNG_ARITHMETIC := preload("res://scripts/gameplay/rom_kickoff_rng_arithmetic.gd")
const ROM_PATH := "res://Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const A117_SPAN_PATH := "res://reference/rom_extract/gameplay/rng_arithmetic/a117_rng_update.bin"
const A117_SPAN_OFFSET := 0x4126
const A117_SPAN_SHA256 := "96d2e722dfb21bf4b41493960cfee8035306d9de9f87a1516da655a2831c5fa9"
const C9C5_SPAN_PATH := "res://reference/rom_extract/gameplay/rng_arithmetic/c9c5_rng_update.bin"
const C9C5_SPAN_OFFSET := 0x3C9D5
const C9C5_SPAN_SHA256 := "7989c2867a7687a0a79daed64aa10950f5222678cdafa871a7aab8a374f07de0"
const RAM_SIZE := 0x0800
const BYTE_MASK := 0x00FF
const RAM_ADDRESS_MASK := 0x07FF


func _initialize() -> void:
	if not _verify_pinned_rom_spans():
		return
	var a117_span := FileAccess.get_file_as_bytes(A117_SPAN_PATH)
	var c9c5_span := FileAccess.get_file_as_bytes(C9C5_SPAN_PATH)
	var a117_cases := _verify_a117(a117_span)
	if a117_cases < 0:
		return
	var c9c5_cases := _verify_c9c5(c9c5_span)
	if c9c5_cases < 0:
		return
	print("KICKOFF RNG arithmetic parity: A117=%d C9C5=%d byte-stepped cases; ROM spans and hashes verified." % [a117_cases, c9c5_cases])
	quit(0)


func _verify_pinned_rom_spans() -> bool:
	if not FileAccess.file_exists(ROM_PATH):
		return _fail("Supplied ROM is required for this source-span verifier.")
	var rom := FileAccess.get_file_as_bytes(ROM_PATH)
	if _sha256(rom) != ROM_SHA256:
		return _fail("Supplied ROM SHA-256 differs from the audited Turkish revision.")
	if not _span_matches_rom(A117_SPAN_PATH, rom, A117_SPAN_OFFSET, 0x13, A117_SPAN_SHA256):
		return false
	if not _span_matches_rom(C9C5_SPAN_PATH, rom, C9C5_SPAN_OFFSET, 0x24, C9C5_SPAN_SHA256):
		return false
	return true


func _span_matches_rom(path: String, rom: PackedByteArray, offset: int, length: int, expected_hash: String) -> bool:
	var span := FileAccess.get_file_as_bytes(path)
	if span.size() != length:
		return _fail("ROM instruction span has an unexpected size: %s" % path)
	if _sha256(span) != expected_hash:
		return _fail("ROM instruction span hash mismatch: %s" % path)
	if offset + length > rom.size():
		return _fail("ROM instruction span exceeds the supplied ROM: %s" % path)
	for index in range(length):
		if span[index] != rom[offset + index]:
			return _fail("Preserved bytes differ from the supplied ROM at file offset $%06X." % (offset + index))
	return true


func _verify_a117(span: PackedByteArray) -> int:
	var cases := 0
	var edges: Array[int] = [0x00, 0x01, 0x7B, 0x7C, 0x7D, 0x80, 0xF2, 0xF3, 0xFF]
	for e1 in edges:
		for e2 in edges:
			for e3 in edges:
				var actual: Vector4i = RNG_ARITHMETIC.step_a117(e1, e2, e3)
				var source_result := _execute_a117_bytes(span, e1, e2, e3)
				if actual != source_result:
					_fail("A117 helper differs from byte stepping for E1/E2/E3=$%02X/$%02X/$%02X." % [e1, e2, e3])
					return -1
				cases += 1
	return cases


func _execute_a117_bytes(span: PackedByteArray, initial_e1: int, initial_e2: int, initial_e3: int) -> Vector4i:
	var registers: Array[int] = [initial_e1, initial_e2, initial_e3]
	var accumulator := 0
	var carry := 0
	var pc := 0
	while pc < span.size():
		var opcode := int(span[pc])
		pc += 1
		match opcode:
			0x18: # CLC at $A116.
				carry = 0
			0xA5: # LDA zero page.
				var address_lda := int(span[pc])
				pc += 1
				if address_lda < 0xE1 or address_lda > 0xE3:
					return Vector4i(-1, -1, -1, -1)
				accumulator = registers[address_lda - 0xE1]
			0x69: # ADC immediate.
				var operand := int(span[pc])
				pc += 1
				var sum := accumulator + operand + carry
				accumulator = sum & BYTE_MASK
				carry = 1 if sum > BYTE_MASK else 0
			0x85: # STA zero page.
				var address_sta := int(span[pc])
				pc += 1
				if address_sta < 0xE1 or address_sta > 0xE3:
					return Vector4i(-1, -1, -1, -1)
				registers[address_sta - 0xE1] = accumulator
			_:
				return Vector4i(-1, -1, -1, -1)
	return Vector4i(registers[0], registers[1], registers[2], carry)


func _verify_c9c5(span: PackedByteArray) -> int:
	var cases := 0
	var e1_values: Array[int] = [0x00, 0x01, 0x7E, 0x7F, 0x80, 0xF9, 0xFA, 0xFE, 0xFF]
	var e2_values: Array[int] = [0x00, 0x01, 0x7F, 0x80, 0xF2, 0xFE]
	var e3_values: Array[int] = [0x00, 0x5A, 0xFF]
	for ram_case in range(5):
		var ram := _make_operand_ram(ram_case)
		for e1 in e1_values:
			for e2 in e2_values:
				for e3 in e3_values:
					for carry in range(2):
						var actual: Vector4i = RNG_ARITHMETIC.step_c9c5(e1, e2, e3, carry, ram)
						var source_result := _execute_c9c5_bytes(span, e1, e2, e3, carry, ram)
						if actual != source_result:
							_fail("C9C5 helper differs from byte stepping for E1/E2/E3/C=$%02X/$%02X/$%02X/%d (RAM pattern %d)." % [e1, e2, e3, carry, ram_case])
							return -1
						cases += 1
	return cases


func _execute_c9c5_bytes(span: PackedByteArray, initial_e1: int, initial_e2: int, initial_e3: int, initial_carry: int, initial_ram: PackedByteArray) -> Vector4i:
	var ram := initial_ram.duplicate()
	ram[0x00E1] = initial_e1
	ram[0x00E2] = initial_e2
	ram[0x00E3] = initial_e3
	var accumulator := 0
	var x := 0
	var carry := initial_carry
	var pc := 0
	while pc < span.size():
		var opcode := int(span[pc])
		pc += 1
		match opcode:
			0xAE: # LDX absolute.
				var address_ldx := _read_absolute_operand(span, pc)
				pc += 2
				x = int(ram[address_ldx & RAM_ADDRESS_MASK])
			0xBD: # LDA absolute,X.
				var address_lda_x := _read_absolute_operand(span, pc) + x
				pc += 2
				accumulator = int(ram[address_lda_x & RAM_ADDRESS_MASK])
			0x7D, 0x6D: # ADC absolute,X / ADC absolute.
				var address_adc := _read_absolute_operand(span, pc)
				pc += 2
				if opcode == 0x7D:
					address_adc += x
				var sum := accumulator + int(ram[address_adc & RAM_ADDRESS_MASK]) + carry
				accumulator = sum & BYTE_MASK
				carry = 1 if sum > BYTE_MASK else 0
			0x2E: # ROL absolute.
				var address_rol := _read_absolute_operand(span, pc)
				pc += 2
				var ram_index_rol := address_rol & RAM_ADDRESS_MASK
				var old_value := int(ram[ram_index_rol])
				ram[ram_index_rol] = ((old_value << 1) | carry) & BYTE_MASK
				carry = (old_value >> 7) & 1
			0x49: # EOR immediate.
				accumulator ^= int(span[pc])
				pc += 1
			0x8D: # STA absolute.
				var address_sta := _read_absolute_operand(span, pc)
				pc += 2
				ram[address_sta & RAM_ADDRESS_MASK] = accumulator
			0xFD: # SBC absolute,X.
				var address_sbc_x := _read_absolute_operand(span, pc) + x
				pc += 2
				var difference := accumulator - int(ram[address_sbc_x & RAM_ADDRESS_MASK]) - (1 - carry)
				accumulator = difference & BYTE_MASK
				carry = 1 if difference >= 0 else 0
			0xEE: # INC absolute; its N/Z flags are not consumed by this routine.
				var address_inc := _read_absolute_operand(span, pc)
				pc += 2
				var ram_index_inc := address_inc & RAM_ADDRESS_MASK
				ram[ram_index_inc] = (int(ram[ram_index_inc]) + 1) & BYTE_MASK
			0x60: # RTS.
				return Vector4i(int(ram[0x00E1]), int(ram[0x00E2]), int(ram[0x00E3]), carry)
			_:
				return Vector4i(-1, -1, -1, -1)
	return Vector4i(-1, -1, -1, -1)


func _read_absolute_operand(span: PackedByteArray, pc: int) -> int:
	return int(span[pc]) | (int(span[pc + 1]) << 8)


func _make_operand_ram(pattern: int) -> PackedByteArray:
	var ram := PackedByteArray()
	ram.resize(RAM_SIZE)
	var state := 0x5EED + (pattern * 0x1234)
	for address in range(RAM_SIZE):
		state = ((state * 109) + 89) & 0xFFFF
		ram[address] = (state >> 8) & BYTE_MASK
	return ram


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	printerr("KICKOFF RNG arithmetic verification failed: " + message)
	quit(1)
	return false
