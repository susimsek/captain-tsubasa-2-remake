extends RefCounted
class_name RomKickoffRngArithmetic
## Byte-level arithmetic for the supplied ROM's A117 and C9C5 RNG updates.
## This helper deliberately does not choose calls or produce C9C5 operand RAM.

const RAM_SIZE := 0x0800
const BYTE_MASK := 0x00FF
const ADDRESS_MASK := 0x07FF


## Executes the A117 arithmetic body. The ROM's CLC is at $A116 immediately
## before the first load at $A117, so the first ADC always starts with carry 0.
## Returns Vector4i(E1, E2, E3, carry after the final ADC).
static func step_a117(e1: int, e2: int, e3: int) -> Vector4i:
	assert(_is_byte(e1) and _is_byte(e2) and _is_byte(e3))
	var carry := 0
	var result := _adc(e1, 0x83, carry)
	e1 = result.x
	carry = result.y
	result = _adc(e2, 0x0D, carry)
	e2 = result.x
	carry = result.y
	result = _adc(e3, 0x11, carry)
	e3 = result.x
	carry = result.y
	return Vector4i(e1, e2, e3, carry)


## Executes the source instruction sequence at fixed-bank $C9C5-$C9E8.
## `ram` is the current 2 KiB NES internal RAM image. Each indexed source
## address is mirrored with CPU-address & $07FF, including $0780,X when X >= $80.
## Returns Vector4i(E1, E2, E3, carry after the final ADC).
static func step_c9c5(
		e1: int,
		e2: int,
		e3: int,
		incoming_carry: int,
		ram: PackedByteArray
) -> Vector4i:
	assert(_is_byte(e1) and _is_byte(e2) and _is_byte(e3))
	assert(incoming_carry == 0 or incoming_carry == 1)
	assert(ram.size() == RAM_SIZE)

	var x := e1
	var accumulator := _read_ram(ram, 0x0300 + x)
	var result := _adc(accumulator, _read_ram(ram, 0x0700 + x), incoming_carry)
	accumulator = result.x
	var carry := result.y

	var rotated_e2 := ((e2 << 1) | carry) & BYTE_MASK
	carry = (e2 >> 7) & 1
	accumulator ^= BYTE_MASK
	var prior_rotated_e2 := rotated_e2
	rotated_e2 = ((prior_rotated_e2 << 1) | carry) & BYTE_MASK
	carry = (prior_rotated_e2 >> 7) & 1

	result = _adc(accumulator, rotated_e2, carry)
	e2 = result.x
	carry = result.y

	var difference := result.x - _read_ram(ram, 0x0780 + x) - (1 - carry)
	accumulator = difference & BYTE_MASK
	carry = 1 if difference >= 0 else 0

	result = _adc(accumulator, e1, carry)
	e3 = result.x
	carry = result.y
	e1 = (e1 + 1) & BYTE_MASK
	return Vector4i(e1, e2, e3, carry)


static func _read_ram(ram: PackedByteArray, cpu_address: int) -> int:
	return int(ram[cpu_address & ADDRESS_MASK])


static func _adc(left: int, right: int, carry_in: int) -> Vector2i:
	var sum := left + right + carry_in
	return Vector2i(sum & BYTE_MASK, 1 if sum > BYTE_MASK else 0)


static func _is_byte(value: int) -> bool:
	return value >= 0 and value <= BYTE_MASK
