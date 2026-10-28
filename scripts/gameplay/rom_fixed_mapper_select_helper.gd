extends RefCounted
class_name RomFixedMapperSelectHelper
## Executes the supplied ROM's bounded fixed-bank MMC3 select helper at
## $C4B9-$C4C7. Caller input and stack return bytes must come from a decoded
## source call event; this does not simulate its caller or update a live mapper.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const MANIFEST_PATH := ROOT + "manifest.json"
const SOURCE_FILE := "fixed_mapper_select_C4B9_C4C7.bin"
const SOURCE_SHA256 := "a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12"
const CALLER_SOURCE_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const CALLER_SOURCE_SHA256 := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const CALLER_SOURCE_START_PC := 0x80DF
const CALLER_SOURCE_END_PC_EXCLUSIVE := 0x815D
const CALLER_SOURCE_FILE_OFFSET := "0x0000EF"
const PRESET_CALLER_SOURCE_FILE := "bank00_match_setup_preset_8920_893F.bin"
const PRESET_CALLER_SOURCE_START_PC := 0x8920
const PRESET_CALLER_SOURCE_END_PC_EXCLUSIVE := 0x893F
const PRESET_CALLER_SOURCE_FILE_OFFSET := "0x000930"
const PRESET_CALLER_SOURCE_SHA256 := "6f4f250519c608d82a9a58aa154e87070a7e6563341a4ec32ae78aa23ee51b12"
const EXPECTED_CALLER_BYTE_VALUES := [
	0x24, 0xED, 0x50, 0x03, 0x4C, 0x6A, 0x82, 0x20, 0xA0, 0x9B, 0xA9, 0x01, 0x20, 0x64, 0x84, 0x20,
	0xB5, 0x82, 0xA9, 0xC0, 0x85, 0xE0, 0xA2, 0x02, 0x20, 0xB9, 0xC4, 0x20, 0x0F, 0xA2, 0xA9, 0x00,
	0x85, 0x28, 0x85, 0x29, 0x85, 0x27, 0xA9, 0x01, 0x8D, 0x00, 0x07, 0xA2, 0x02, 0x20, 0xB9, 0xC4,
	0x20, 0x0C, 0xA2, 0xA9, 0x00, 0x20, 0x20, 0x89, 0xA2, 0x01, 0x20, 0xB9, 0xC4, 0x20, 0x06, 0xA0,
	0x20, 0x72, 0xC5, 0xA2, 0x55, 0xA5, 0x26, 0xC9, 0x20, 0x90, 0x02, 0xA2, 0x4C, 0x8E, 0x00, 0x07,
	0xA9, 0x00, 0x8D, 0x50, 0x04, 0x8D, 0x51, 0x04, 0x8D, 0x52, 0x04, 0x8D, 0x53, 0x04, 0xA2, 0x01,
	0x20, 0xB9, 0xC4, 0x20, 0x09, 0xA0, 0x24, 0xE0, 0x30, 0x06, 0xA5, 0xE4, 0xC5, 0x26, 0xB0, 0x14,
	0xAE, 0x26, 0x00, 0xBD, 0xDC, 0x83, 0xF0, 0x0C, 0x20, 0x64, 0x84, 0x20, 0xB5, 0x82,
]
const EXPECTED_BYTE_VALUES := [
	0x86, 0x25, # STX $25
	0xA9, 0x07, # LDA #$07
	0x05, 0x22, # ORA $22
	0x85, 0x23, # STA $23
	0x8D, 0x00, 0x80, # STA $8000
	0x8E, 0x01, 0x80, # STX $8001
	0x60, # RTS
]
const SOURCE_START_PC := 0xC4B9
const SOURCE_END_PC_EXCLUSIVE := 0xC4C8
const SOURCE_FILE_OFFSET := "0x03C4C9"
const MAPPER_SELECT_REGISTER := 0x8000
const MAPPER_DATA_REGISTER := 0x8001
const BANK_SELECT_REGISTER_ID := 0x07

const CALLSITE_RETURNS := {
	0x80F7: 0x80FA,
	0x810C: 0x810F,
	0x8119: 0x811C,
	0x813F: 0x8142,
	0x8938: 0x893B,
}

var error_message := ""
var _configured := false
var _source := PackedByteArray()
var _caller_source := PackedByteArray()
var _preset_caller_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source = PackedByteArray()
	_caller_source = PackedByteArray()
	_preset_caller_source = PackedByteArray()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Packaged caller-source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Packaged caller-source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Mapper-helper manifest targets a different ROM revision.")
	var entry: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == SOURCE_FILE:
			entry = span_variant
			break
	if entry.is_empty() \
			or String(entry.get("cpu_start", "")) != "$C4B9" \
			or String(entry.get("cpu_end_exclusive", "")) != "$C4C8" \
			or String(entry.get("file_offset", "")) != SOURCE_FILE_OFFSET \
			or int(entry.get("length", -1)) != EXPECTED_BYTE_VALUES.size() \
			or String(entry.get("sha256", "")) != SOURCE_SHA256:
		return _fail("Mapper-helper source-span metadata differs from the audited ROM range.")
	_source = FileAccess.get_file_as_bytes(ROOT + SOURCE_FILE)
	if _source != PackedByteArray(EXPECTED_BYTE_VALUES) or _sha256(_source) != SOURCE_SHA256:
		return _fail("Packaged `$C4B9` instruction bytes failed exact-byte/hash validation.")
	if String(entry.get("bytes", "")).to_lower().replace(" ", "") != _source.hex_encode():
		return _fail("Manifest byte listing differs from the packaged mapper-helper code.")
	var caller_entry: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == CALLER_SOURCE_FILE:
			caller_entry = span_variant
			break
	if caller_entry.is_empty() \
			or String(caller_entry.get("cpu_start", "")) != "$80DF" \
			or String(caller_entry.get("cpu_end_exclusive", "")) != "$815D" \
			or String(caller_entry.get("file_offset", "")) != CALLER_SOURCE_FILE_OFFSET \
			or int(caller_entry.get("length", -1)) != EXPECTED_CALLER_BYTE_VALUES.size() \
			or String(caller_entry.get("sha256", "")) != CALLER_SOURCE_SHA256:
		return _fail("Mapper-helper caller-span metadata differs from the audited ROM range.")
	_caller_source = FileAccess.get_file_as_bytes(ROOT + CALLER_SOURCE_FILE)
	if _caller_source != PackedByteArray(EXPECTED_CALLER_BYTE_VALUES) \
			or _sha256(_caller_source) != CALLER_SOURCE_SHA256:
		return _fail("Packaged fresh-start caller bytes failed exact-byte/hash validation.")
	if String(caller_entry.get("bytes", "")).to_lower().replace(" ", "") != _caller_source.hex_encode():
		return _fail("Manifest byte listing differs from the packaged fresh-start caller code.")
	var preset_caller_entry: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == PRESET_CALLER_SOURCE_FILE:
			preset_caller_entry = span_variant
			break
	if preset_caller_entry.is_empty() \
			or String(preset_caller_entry.get("cpu_start", "")) != "$8920" \
			or String(preset_caller_entry.get("cpu_end_exclusive", "")) != "$893F" \
			or String(preset_caller_entry.get("file_offset", "")) != PRESET_CALLER_SOURCE_FILE_OFFSET \
			or int(preset_caller_entry.get("length", -1)) != 31 \
			or String(preset_caller_entry.get("sha256", "")) != PRESET_CALLER_SOURCE_SHA256:
		return _fail("Fresh-match `$8920` mapper caller-span metadata is missing or differs.")
	_preset_caller_source = FileAccess.get_file_as_bytes(ROOT + PRESET_CALLER_SOURCE_FILE)
	if _preset_caller_source.size() != 31 or _sha256(_preset_caller_source) != PRESET_CALLER_SOURCE_SHA256:
		return _fail("Fresh-match `$8920` mapper caller bytes failed exact hash validation.")
	if String(preset_caller_entry.get("bytes", "")).to_lower().replace(" ", "") != _preset_caller_source.hex_encode():
		return _fail("Manifest byte listing differs from the packaged `$8920` mapper caller span.")
	for caller_pc: int in CALLSITE_RETURNS:
		var callsite_source := _caller_source
		var callsite_source_start := CALLER_SOURCE_START_PC
		if caller_pc == 0x8938:
			callsite_source = _preset_caller_source
			callsite_source_start = PRESET_CALLER_SOURCE_START_PC
		var offset := caller_pc - callsite_source_start
		if offset < 0 or offset + 2 >= callsite_source.size() \
				or int(callsite_source[offset]) != 0x20 \
				or int(callsite_source[offset + 1]) != (SOURCE_START_PC & 0xFF) \
				or int(callsite_source[offset + 2]) != ((SOURCE_START_PC >> 8) & 0xFF) \
				or int(CALLSITE_RETURNS[caller_pc]) != caller_pc + 3:
			return _fail("Caller `$%04X` is not a byte-verified JSR to `$C4B9` with the expected continuation." % caller_pc)
	_configured = true
	return true


## Executes the helper's exact instructions against a decoded JSR entry.
## `source_call` must contain caller_pc, target_pc, return_pc, source_event_id,
## pre_call_sp and a 256-byte `stack_page`. `cpu_state.sp` is the SP at $C4B9.
## The result is a plan plus an RTS receipt; mapper writes are not applied.
func execute_source_call(source_call: Dictionary, cpu_state: Dictionary,
		ram_before: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var caller_pc := int(source_call.get("caller_pc", -1))
	if not CALLSITE_RETURNS.has(caller_pc):
		return _failure("The callsite is outside the checked fresh KICK OFF `$C4B9` callers.")
	var return_pc := int(CALLSITE_RETURNS[caller_pc])
	if int(source_call.get("target_pc", -1)) != SOURCE_START_PC \
			or int(source_call.get("return_pc", -1)) != return_pc:
		return _failure("Call target/return PC does not match the ROM caller's JSR bytes.")
	var source_event_id := String(source_call.get("source_event_id", "")).strip_edges()
	if source_event_id.is_empty():
		return _failure("A decoded source-call event identity is required; a trace frame is not a substitute.")
	var pre_call_sp := int(source_call.get("pre_call_sp", -1))
	if pre_call_sp < 0 or pre_call_sp > 0xFF:
		return _failure("Caller must supply its byte-valued pre-JSR stack pointer.")
	var entry_sp := (pre_call_sp - 2) & 0xFF
	if int(cpu_state.get("sp", -1)) != entry_sp:
		return _failure("CPU SP at `$C4B9` does not follow the JSR's two stack pushes.")
	var stack_variant: Variant = source_call.get("stack_page")
	if not stack_variant is PackedByteArray or stack_variant.size() != 0x100:
		return _failure("The decoded 256-byte stack page is required to execute RTS.")
	var stack_page: PackedByteArray = stack_variant
	var stack_low := int(stack_page[(entry_sp + 1) & 0xFF])
	var stack_high := int(stack_page[(entry_sp + 2) & 0xFF])
	var stacked_return_word := stack_low | (stack_high << 8)
	if stacked_return_word != caller_pc + 2:
		return _failure("Stack return word does not match the caller's source JSR continuation.")
	for register_name: String in ["a", "x", "y", "p"]:
		var value := int(cpu_state.get(register_name, -1))
		if value < 0 or value > 0xFF:
			return _failure("CPU register `%s` must be an explicit byte from the source call state." % register_name)
	if not ram_before.has(0x0022):
		return _failure("MMC3 `$0022` select-shadow byte must come from caller-owned source state.")
	var select_shadow := int(ram_before[0x0022])
	if select_shadow < 0 or select_shadow > 0xFF:
		return _failure("MMC3 `$0022` select-shadow must fit one byte.")

	var registers := {
		"a": int(cpu_state["a"]),
		"x": int(cpu_state["x"]),
		"y": int(cpu_state["y"]),
		"p": int(cpu_state["p"]),
		"sp": entry_sp,
		"pc": SOURCE_START_PC,
	}
	var ram_after := ram_before.duplicate(true)
	var bus_writes: Array[Dictionary] = []
	var executed_pcs: Array[int] = []
	var selected_bank := int(registers["x"])
	var mapper_select := -1
	var cycles := 0
	var pc := SOURCE_START_PC
	var code_offset := 0
	while pc < SOURCE_END_PC_EXCLUSIVE:
		executed_pcs.append(pc)
		var opcode := int(_source[code_offset])
		match opcode:
			0x86: # STX $25
				if code_offset + 1 >= _source.size() or int(_source[code_offset + 1]) != 0x25:
					return _failure("Unexpected instruction operand at `$%04X`." % pc)
				ram_after[0x0025] = selected_bank
				pc += 2
				code_offset += 2
				cycles += 3
			0xA9: # LDA #$07
				if code_offset + 1 >= _source.size() or int(_source[code_offset + 1]) != BANK_SELECT_REGISTER_ID:
					return _failure("Unexpected bank-select immediate at `$%04X`." % pc)
				registers["a"] = BANK_SELECT_REGISTER_ID
				registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
				pc += 2
				code_offset += 2
				cycles += 2
			0x05: # ORA $22
				if code_offset + 1 >= _source.size() or int(_source[code_offset + 1]) != 0x22:
					return _failure("Unexpected MMC3 select-shadow operand at `$%04X`." % pc)
				registers["a"] = (int(registers["a"]) | select_shadow) & 0xFF
				registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
				pc += 2
				code_offset += 2
				cycles += 3
			0x85: # STA $23
				if code_offset + 1 >= _source.size() or int(_source[code_offset + 1]) != 0x23:
					return _failure("Unexpected MMC3 select-shadow destination at `$%04X`." % pc)
				mapper_select = int(registers["a"])
				ram_after[0x0023] = mapper_select
				pc += 2
				code_offset += 2
				cycles += 3
			0x8D: # STA $8000
				if _read_source_word(code_offset + 1) != MAPPER_SELECT_REGISTER or mapper_select < 0:
					return _failure("Unexpected MMC3 select-bus store at `$%04X`." % pc)
				bus_writes.append({"pc": pc, "address": MAPPER_SELECT_REGISTER, "value": mapper_select})
				pc += 3
				code_offset += 3
				cycles += 4
			0x8E: # STX $8001
				if _read_source_word(code_offset + 1) != MAPPER_DATA_REGISTER:
					return _failure("Unexpected MMC3 data-bus store at `$%04X`." % pc)
				bus_writes.append({"pc": pc, "address": MAPPER_DATA_REGISTER, "value": selected_bank})
				pc += 3
				code_offset += 3
				cycles += 4
			0x60: # RTS
				if code_offset != _source.size() - 1:
					return _failure("RTS is not the final source byte in the bounded helper.")
				var expected_return_pc := stacked_return_word + 1
				if expected_return_pc != return_pc:
					return _failure("RTS stack word computes a different source return PC.")
				pc = return_pc
				code_offset += 1
				cycles += 6
				break
			_:
				return _failure("Unsupported ROM opcode `$%02X` at `$%04X`." % [opcode, pc])
	if code_offset != _source.size() or pc != return_pc:
		return _failure("Bounded helper did not execute through RTS to its source return PC.")
	registers["sp"] = pre_call_sp
	registers["pc"] = return_pc
	var receipt := {
		"caller_pc": caller_pc,
		"target_pc": SOURCE_START_PC,
		"return_pc": return_pc,
		"status": "returned",
		"source_event_id": source_event_id,
		"helper_execution": "rom_fixed_mapper_select_helper",
		"post_registers": registers.duplicate(true),
		"mapper_bus_writes": bus_writes.duplicate(true),
	}
	return {
		"ok": true,
		"status": "returned",
		"source_call": source_call.duplicate(true),
		"source_return_receipt": receipt,
		"source_rom_sha256": ROM_SHA256,
		"source_span": {"cpu_start": SOURCE_START_PC, "cpu_end_exclusive": SOURCE_END_PC_EXCLUSIVE,
			"file_offset": SOURCE_FILE_OFFSET, "sha256": SOURCE_SHA256},
		"executed_instruction_pcs": executed_pcs,
		"cpu_cycles": cycles,
		"entry_registers": cpu_state.duplicate(true),
		"return_registers": registers,
		"ram_writes": [
			{"pc": 0xC4B9, "address": 0x0025, "value": selected_bank},
			{"pc": 0xC4BF, "address": 0x0023, "value": mapper_select},
		],
		"ram_after": ram_after,
		"mapper_bus_writes": bus_writes,
		"live_mapper_updated": false,
		"emulator_data_used": false,
	}


func _read_source_word(offset: int) -> int:
	if offset < 0 or offset + 1 >= _source.size():
		return -1
	return int(_source[offset]) | (int(_source[offset + 1]) << 8)


func _set_nz(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0x80) != 0:
		result |= 0x80
	if value == 0:
		result |= 0x02
	return result


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_required_or_mismatch", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
