extends RefCounted
class_name RomMmc3ChrMapper
## Maps a ROM-derived MMC3 CHR image into the eight visible 1 KiB PPU slots.

const CHR_BANK_SIZE := 0x0400
const PATTERN_TABLE_SIZE := 0x2000


static func map_pattern_table(chr_bytes: PackedByteArray, registers: Array,
		command: int) -> Dictionary:
	if chr_bytes.is_empty() or chr_bytes.size() % CHR_BANK_SIZE != 0:
		return {"ok": false, "error": "CHR source must contain complete 1 KiB banks."}
	if registers.size() != 8 or command < 0 or command > 0xFF:
		return {"ok": false, "error": "MMC3 requires eight byte registers and a byte command."}
	var bank_count := int(chr_bytes.size() / CHR_BANK_SIZE)
	if bank_count <= 0 or (bank_count & (bank_count - 1)) != 0:
		return {"ok": false, "error": "CHR bank count must be a positive power of two."}
	for value_variant in registers:
		var value := int(value_variant)
		if value < 0 or value > 0xFF:
			return {"ok": false, "error": "MMC3 register values must fit in one byte."}

	var raw_slots: Array[int] = []
	var bank_0 := int(registers[0]) & 0xFE
	var bank_1 := int(registers[1]) & 0xFE
	if (command & 0x80) == 0:
		raw_slots = [bank_0, bank_0 + 1, bank_1, bank_1 + 1,
			int(registers[2]), int(registers[3]), int(registers[4]), int(registers[5])]
	else:
		raw_slots = [int(registers[2]), int(registers[3]), int(registers[4]),
			int(registers[5]), bank_0, bank_0 + 1, bank_1, bank_1 + 1]

	var bank_mask := bank_count - 1
	var banks: Array[int] = []
	var pattern_table := PackedByteArray()
	pattern_table.resize(PATTERN_TABLE_SIZE)
	for slot in range(8):
		var physical_bank := raw_slots[slot] & bank_mask
		banks.append(physical_bank)
		var source_start := physical_bank * CHR_BANK_SIZE
		var destination_start := slot * CHR_BANK_SIZE
		for offset in range(CHR_BANK_SIZE):
			pattern_table[destination_start + offset] = chr_bytes[source_start + offset]
	return {"ok": true, "chr_1k_banks": banks, "pattern_table": pattern_table,
		"chr_bank_count": bank_count, "chr_address_mask": bank_mask,
		"chr_mode_inverted": (command & 0x80) != 0}
