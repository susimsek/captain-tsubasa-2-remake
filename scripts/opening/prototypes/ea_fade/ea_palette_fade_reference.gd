extends RefCounted
class_name EAPaletteFadeReference

## Source-derived EA/$99F0 palette and PPU-clear helpers used by the opening presenter.
## Fade colors are modeled; within-frame PPU bus timing is not.
const PALETTE_LOOKUP_PATH := "res://reference/rom_extract/intro/ea_fade/palette_lut_9EA2.bin"
const PALETTE_GROUP_SIZE := 16
const PALETTE_SIZE := 32

static func build_palette(base_palette: PackedByteArray, fade_a: int, fade_b: int) -> PackedByteArray:
	assert(base_palette.size() >= PALETTE_SIZE)
	assert(fade_a >= 0 and fade_a <= 0x0F)
	assert(fade_b >= 0 and fade_b <= 0x0F)
	var lookup := FileAccess.get_file_as_bytes(PALETTE_LOOKUP_PATH)
	assert(lookup.size() == 0x40)
	var result := PackedByteArray()
	result.resize(PALETTE_SIZE)
	for index in range(PALETTE_GROUP_SIZE):
		result[index] = lookup[(base_palette[index] & 0x30) + fade_a] | (base_palette[index] & 0x0F)
	for index in range(PALETTE_GROUP_SIZE, PALETTE_SIZE):
		result[index] = lookup[(base_palette[index] & 0x30) + fade_b] | (base_palette[index] & 0x0F)
	return result

static func fade_down_tick(fade_a: int, fade_b: int) -> Vector2i:
	## $99F0 decrements each nonzero counter, rebuilds/stages all 32 colors,
	## then calls $9FA8(A=$01). Both counters are zero before it returns.
	return Vector2i(maxi(0, fade_a - 1), maxi(0, fade_b - 1))

static func has_fade_work(fade_a: int, fade_b: int) -> bool:
	return (fade_a | fade_b) != 0

static func confirmed_ea_zero_fill_addresses() -> PackedInt32Array:
	## Addresses written by EA's two source-confirmed $98E8 fills after $99F0.
	## The prototype records the fill extent, not the NMI/scanline bus schedule.
	var addresses := PackedInt32Array()
	for fill in [
		{"base_address": 0x2000, "row_count": 16},
		{"base_address": 0x2400, "row_count": 32},
	]:
		var base_address := int(fill["base_address"])
		for row in range(int(fill["row_count"])):
			for column in range(32):
				addresses.append(base_address + row * 0x20 + column)
	return addresses
