extends RefCounted
class_name RomSourceRamImage
## Sparse, provenance-carrying RAM image for ROM executors that have actually
## produced writes. Unwritten bytes remain unknown; zero-filled storage is not
## evidence that the source game held a zero there.

const RAM_BYTES := 0x800
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var error_message := ""
var _bytes := PackedByteArray()
var _known := PackedByteArray()
var _known_bit_masks := PackedByteArray()
var _known_bit_values := PackedByteArray()
var _last_write_by_address: Dictionary = {}
var _last_bit_write_by_address: Dictionary = {}
var _applied_event_counts: Dictionary = {}
var _applied_bit_event_counts: Dictionary = {}
var _write_count := 0
var _ignored_non_internal_ram_write_count := 0


func _init() -> void:
	_bytes.resize(RAM_BYTES)
	_bytes.fill(0)
	_known.resize(RAM_BYTES)
	_known.fill(0)
	_known_bit_masks.resize(RAM_BYTES)
	_known_bit_masks.fill(0)
	_known_bit_values.resize(RAM_BYTES)
	_known_bit_values.fill(0)


## Merge one successful source executor result. This accepts executor write
## receipts, not emulator snapshots, trace RAM, or inferred endpoint state.
func merge_executor_result(event_id: String, result: Dictionary) -> bool:
	error_message = ""
	if event_id.is_empty() or not bool(result.get("ok", false)):
		return _fail("RAM merge requires a named successful ROM executor result.")
	var result_rom_hash := String(result.get("source_rom_sha256", result.get("rom_sha256", "")))
	if result_rom_hash != SOURCE_ROM_SHA256:
		return _fail("RAM merge rejected a result without the pinned source ROM hash.")
	if bool(result.get("emulator_data_used", false)) or bool(result.get("trace_state_used", false)):
		return _fail("RAM merge rejected emulator-derived state.")
	var writes: Variant = result.get("ram_writes", result.get("caller_ram_writes", null))
	if not writes is Array:
		return _fail("ROM executor result has no explicit RAM-write receipt array.")
	for write_variant in writes:
		if not write_variant is Dictionary:
			return _fail("ROM RAM-write receipt contains a non-object entry.")
		if not _apply_write(event_id, write_variant):
			return false
	_applied_event_counts[event_id] = int(_applied_event_counts.get(event_id, 0)) + writes.size()
	return true


## Merge a ROM proof for selected bits without treating the entire RAM byte as
## known. This supports mode bits whose neighboring latch bits have separate
## interrupt history.
func merge_known_bits_receipt(event_id: String, result: Dictionary) -> bool:
	error_message = ""
	if event_id.is_empty() or not bool(result.get("ok", false)):
		return _fail("Bit-state merge requires a named successful ROM receipt.")
	var result_rom_hash := String(result.get("source_rom_sha256", result.get("rom_sha256", "")))
	if result_rom_hash != SOURCE_ROM_SHA256:
		return _fail("Bit-state merge rejected a receipt without the pinned source ROM hash.")
	if bool(result.get("emulator_data_used", false)) or bool(result.get("trace_state_used", false)):
		return _fail("Bit-state merge rejected emulator-derived state.")
	var writes: Variant = result.get("known_bit_writes", null)
	if not writes is Array or writes.is_empty():
		return _fail("ROM bit-state receipt has no explicit known-bit writes.")
	for write_variant in writes:
		if not write_variant is Dictionary:
			return _fail("ROM bit-state receipt contains a non-object entry.")
		if not _apply_known_bits(event_id, write_variant):
			return false
	_applied_bit_event_counts[event_id] = int(_applied_bit_event_counts.get(event_id, 0)) + writes.size()
	return true


func get_byte(address: int) -> Dictionary:
	if address < 0 or address >= RAM_BYTES:
		return {"known": false, "error": "address_out_of_range"}
	return {"known": _known[address] != 0, "value": int(_bytes[address]),
		"last_write": _last_write_by_address.get(address, {})}


func get_byte_bits(address: int) -> Dictionary:
	if address < 0 or address >= RAM_BYTES:
		return {"known_mask": 0, "known_value": 0, "error": "address_out_of_range"}
	return {
		"known_mask": int(_known_bit_masks[address]),
		"known_value": int(_known_bit_values[address]) & int(_known_bit_masks[address]),
		"last_write": _last_bit_write_by_address.get(address, {}),
	}


func get_status() -> Dictionary:
	var known_count := 0
	var known_values: Dictionary = {}
	var known_bits: Dictionary = {}
	for address in RAM_BYTES:
		if _known[address] != 0:
			known_count += 1
			known_values[address] = int(_bytes[address])
		if _known_bit_masks[address] != 0:
			known_bits[address] = {
				"known_mask": int(_known_bit_masks[address]),
				"known_value": int(_known_bit_values[address]) & int(_known_bit_masks[address]),
				"last_write": _last_bit_write_by_address.get(address, {}),
			}
	return {
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"status": "sparse_source_writes_only",
		"executes_6502": false,
		"emulator_data_used": false,
		"ram_size": RAM_BYTES,
		"known_byte_count": known_count,
		"unknown_byte_count": RAM_BYTES - known_count,
		"applied_write_count": _write_count,
		"ignored_non_internal_ram_write_count": _ignored_non_internal_ram_write_count,
		"applied_event_counts": _applied_event_counts.duplicate(true),
		"applied_bit_event_counts": _applied_bit_event_counts.duplicate(true),
		"known_values": known_values,
		"known_bit_address_count": known_bits.size(),
		"known_bits_by_address": known_bits,
		"last_write_by_address": _last_write_by_address.duplicate(true),
		"last_bit_write_by_address": _last_bit_write_by_address.duplicate(true),
		"error": error_message,
	}


func _apply_write(event_id: String, write: Dictionary) -> bool:
	var raw_address := int(write.get("address", -1))
	var value := int(write.get("value", -1))
	var pc := int(write.get("source_pc", write.get("pc", -1)))
	if raw_address < 0 or raw_address > 0xFFFF or value < 0 or value > 0xFF or pc < 0 or pc > 0xFFFF:
		return _fail("ROM RAM-write receipt has an invalid address, value, or source PC.")
	if raw_address > 0x1FFF:
		# The selector's `$6000-$7350` destination is MMC3 PRG RAM, not the
		# 2 KiB CPU RAM page tracked by this image. Keep it outside this ledger.
		_ignored_non_internal_ram_write_count += 1
		return true
	var address := raw_address & 0x07FF
	_bytes[address] = value
	_known[address] = 1
	_last_write_by_address[address] = {
		"event_id": event_id,
		"source_pc": pc,
		"value": value,
	}
	_write_count += 1
	return true


func _apply_known_bits(event_id: String, write: Dictionary) -> bool:
	var raw_address := int(write.get("address", -1))
	var mask := int(write.get("known_mask", -1))
	var value := int(write.get("known_value", -1))
	var pc := int(write.get("source_pc", write.get("pc", -1)))
	if raw_address < 0 or raw_address > 0x1FFF or mask <= 0 or mask > 0xFF \
			or value < 0 or value > 0xFF or pc < 0 or pc > 0xFFFF:
		return _fail("ROM known-bit receipt has an invalid address, mask, value, or source PC.")
	var address := raw_address & 0x07FF
	var old_mask := int(_known_bit_masks[address])
	var old_value := int(_known_bit_values[address])
	if ((old_value ^ value) & old_mask & mask) != 0:
		return _fail("ROM known-bit receipt conflicts with earlier source provenance at `$%04X`." % address)
	if _known[address] != 0 and ((int(_bytes[address]) ^ value) & mask) != 0:
		return _fail("ROM known-bit receipt conflicts with an earlier full-byte source write at `$%04X`." % address)
	_known_bit_values[address] = (old_value & old_mask) | (value & mask)
	_known_bit_masks[address] = old_mask | mask
	_last_bit_write_by_address[address] = {
		"event_id": event_id,
		"source_pc": pc,
		"known_mask": mask,
		"known_value": value & mask,
	}
	if int(_known_bit_masks[address]) == 0xFF:
		var complete_value := int(_known_bit_values[address]) & 0xFF
		if _known[address] != 0 and int(_bytes[address]) != complete_value:
			return _fail("ROM bit receipts disagree with the earlier full-byte value at `$%04X`." % address)
		_bytes[address] = complete_value
		_known[address] = 1
		_last_write_by_address[address] = {
			"event_id": event_id,
			"source_pc": pc,
			"value": complete_value,
			"derived_from_complete_known_bits": true,
		}
	return true


func _fail(message: String) -> bool:
	error_message = message
	return false
