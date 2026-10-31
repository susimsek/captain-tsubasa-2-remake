extends RefCounted
class_name RomPpuNametableWriteApplier
## Applies only the normal-NMI consumer's ordered $2002/$2006/$2007 event stream
## to the renderer's modeled nametable dictionary. Caller-supplied state owns
## PPUCTRL, current/temporary address, and the shared $2005/$2006 write toggle.
## CHR, palette, OAM, mapper, rendering, and beam/cycle effects are unsupported.

const PPU_STATUS := 0x2002
const PPU_ADDR := 0x2006
const PPU_DATA := 0x2007
const NAMETABLE_START := 0x2000
const NAMETABLE_END_EXCLUSIVE := 0x3000
const NAMETABLE_MIRROR_START := 0x3000
const NAMETABLE_MIRROR_END_EXCLUSIVE := 0x3F00
const ADDRESS_MASK := 0x7FFF
const PPU_ADDRESS_MASK := 0x3FFF

var last_error := ""


## Apply an ordered queue-consumer event list without mutating either input.
## `ppu_state` must contain:
## - `ppu_ctrl`: the current $2000 byte (bit 2 selects $2007 increment 1/32)
## - `current_address`: the 15-bit PPU v address
## - `temporary_address`: the 15-bit PPU t address
## - `write_toggle`: false means the next $2006 write is the high byte; true
##   means it is the low byte. A $2002 read resets it to false.
##
## Only canonical renderer nametable bytes $2000-$2FFF are returned. PPU's
## $3000-$3EFF nametable mirror is canonicalized by subtracting $1000. Any
## unsupported event or CHR/palette address rejects the whole batch.
func apply_bus_events(ppu_memory: Dictionary, ppu_state: Dictionary,
		bus_events: Array) -> Dictionary:
	last_error = ""
	if not _validate_state(ppu_state):
		return _rejected("invalid_ppu_state", last_error)
	if not _validate_ppu_memory(ppu_memory):
		return _rejected("invalid_nametable_memory", last_error)

	var updated_memory := ppu_memory.duplicate()
	var updated_state := ppu_state.duplicate(true)
	var applied_writes: Array[Dictionary] = []
	for event_index in bus_events.size():
		var event_variant: Variant = bus_events[event_index]
		if not event_variant is Dictionary:
			return _rejected("invalid_event", "Bus event %d is not a dictionary." % event_index)
		var event: Dictionary = event_variant
		if int(event.get("sequence", -1)) != event_index:
			return _rejected("invalid_event_order",
				"Bus event %d has a missing or noncontiguous sequence index." % event_index)
		if not _is_word_integer(event.get("source_pc", null)):
			return _rejected("invalid_event", "Bus event %d omits its 16-bit source PC." % event_index)

		var operation := str(event.get("operation", ""))
		var register := int(event.get("ppu_register", -1))
		if operation == "read" and register == PPU_STATUS:
			updated_state["write_toggle"] = false
			continue
		if operation != "write" or (register != PPU_ADDR and register != PPU_DATA):
			return _rejected("unsupported_event",
				"Bus event %d is not a supported $2002 read or $2006/$2007 write." % event_index)
		if not _is_byte_integer(event.get("value", null)):
			return _rejected("invalid_event", "Bus event %d has no byte-valued write." % event_index)
		var value := int(event["value"])

		if register == PPU_ADDR:
			var temporary_address := int(updated_state["temporary_address"])
			if not bool(updated_state["write_toggle"]):
				temporary_address = (temporary_address & 0x00FF) | ((value & 0x3F) << 8)
				updated_state["temporary_address"] = temporary_address
				updated_state["write_toggle"] = true
			else:
				temporary_address = (temporary_address & 0x7F00) | value
				if not _is_supported_nametable_address(temporary_address & PPU_ADDRESS_MASK):
					return _rejected("unsupported_ppu_address",
						"$2006 committed unsupported PPU address $%04X." % (temporary_address & PPU_ADDRESS_MASK))
				updated_state["temporary_address"] = temporary_address
				updated_state["current_address"] = temporary_address & ADDRESS_MASK
				updated_state["write_toggle"] = false
			continue

		var current_address := int(updated_state["current_address"]) & ADDRESS_MASK
		var bus_address := current_address & PPU_ADDRESS_MASK
		if not _is_supported_nametable_address(bus_address):
			return _rejected("unsupported_ppu_address",
				"$2007 targets unsupported PPU address $%04X." % bus_address)
		var canonical_address := _canonical_nametable_address(bus_address)
		updated_memory[canonical_address] = value
		applied_writes.append({
			"event_index": event_index,
			"source_pc": int(event["source_pc"]),
			"ppu_address": bus_address,
			"nametable_address": canonical_address,
			"value": value,
		})
		var increment := 32 if (int(updated_state["ppu_ctrl"]) & 0x04) != 0 else 1
		updated_state["current_address"] = (current_address + increment) & ADDRESS_MASK

	return {
		"ok": true,
		"status": "applied",
		"ppu_memory": updated_memory,
		"ppu_state": updated_state,
		"writes_applied": applied_writes,
		"write_count": applied_writes.size(),
		"runtime_rom_dependency": false,
	}


func _validate_state(state: Dictionary) -> bool:
	for key in ["ppu_ctrl", "current_address", "temporary_address"]:
		if not _is_nonnegative_integer(state.get(key, null)):
			last_error = "PPU state omits integer %s." % key
			return false
	if int(state["ppu_ctrl"]) > 0xFF:
		last_error = "PPUCTRL must fit one byte."
		return false
	for key in ["current_address", "temporary_address"]:
		if int(state[key]) > ADDRESS_MASK:
			last_error = "%s must fit the modeled 15-bit PPU address register." % key
			return false
	if typeof(state.get("write_toggle", null)) != TYPE_BOOL:
		last_error = "PPU state must supply the shared $2005/$2006 write toggle as a boolean."
		return false
	return true


func _validate_ppu_memory(ppu_memory: Dictionary) -> bool:
	for key_variant: Variant in ppu_memory:
		if typeof(key_variant) != TYPE_INT or int(key_variant) < NAMETABLE_START \
				or int(key_variant) >= NAMETABLE_END_EXCLUSIVE:
			last_error = "Renderer PPU memory contains a key outside $2000-$2FFF."
			return false
		if not _is_byte_integer(ppu_memory[key_variant]):
			last_error = "Renderer nametable value at $%04X is not a byte." % int(key_variant)
			return false
	return true


func _is_supported_nametable_address(address: int) -> bool:
	return (address >= NAMETABLE_START and address < NAMETABLE_END_EXCLUSIVE) \
		or (address >= NAMETABLE_MIRROR_START and address < NAMETABLE_MIRROR_END_EXCLUSIVE)


func _canonical_nametable_address(address: int) -> int:
	return address - 0x1000 if address >= NAMETABLE_MIRROR_START else address


func _is_byte_integer(value: Variant) -> bool:
	return _is_nonnegative_integer(value) and int(value) <= 0xFF


func _is_word_integer(value: Variant) -> bool:
	return _is_nonnegative_integer(value) and int(value) <= 0xFFFF


func _is_nonnegative_integer(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and int(value) >= 0


func _rejected(status: String, message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "status": status, "error": message}
