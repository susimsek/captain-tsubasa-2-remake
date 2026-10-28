extends RefCounted
class_name RomFreshMatchPresetLoaderPrefix
## Continues the fresh-match caller from $8112 through the executable prefix
## of $8920. It stops before the unresolved LDA $78 / BNE wait predicate.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_match_setup/manifest.json"
const CALLER_MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/manifest.json"
const CALLER_FILE := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/bank00_title_to_first_match_setup_80DF_815C.bin"
const CALLER_SHA256 := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const CALLER_START_PC := 0x80DF
const CALLER_ENTRY_PC := 0x8112
const SETUP_CALLER_PC := 0x8114
const SETUP_ENTRY_PC := 0x8920
const SETUP_RETURN_PC := 0x8117
const PRESET_WAIT_PC := 0x893B
const MULTIPLY_ENTRY_PC := 0x9DEE
const MULTIPLY_RETURN_PC := 0x8925
const MAPPER_CALLER_PC := 0x8938
const MAPPER_RETURN_PC := 0x893B
const BANK2 := 2
const PRESET_BANK := 6

const SOURCE_EXPECTATIONS := {
	"preset_loader_prefix": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_setup/preset_loader_prefix_A920_893E.bin",
		"cpu_start": "$8920", "cpu_end_exclusive": "$893F", "file_offset": "0x000930",
		"length": 31, "sha256": "6f4f250519c608d82a9a58aa154e87070a7e6563341a4ec32ae78aa23ee51b12",
	},
	"multiply_by_x_helper": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_setup/multiply_by_x_helper_9DEE_9E0B.bin",
		"cpu_start": "$9DEE", "cpu_end_exclusive": "$9E0C", "file_offset": "0x001DFE",
		"length": 30, "sha256": "274c1ff01f655cdaf900689a6b938df2f67d5d0c16713760e4d6074c5f684f79",
	},
}
const EXPECTED_SETUP_PREFIX := [
	0xA2, 0x13, 0x20, 0xEE, 0x9D, # LDX #$13 / JSR $9DEE
	0xA5, 0xEC, 0x18, 0x69, 0x00, 0x85, 0xEC,
	0xA5, 0xED, 0x69, 0xBF, 0x85, 0xED,
	0xA5, 0x25, 0x85, 0xEA, 0xA2, 0x06,
	0x20, 0xB9, 0xC4, # JSR $C4B9 at $8938
	0xA5, 0x78, 0xD0, 0xFC, # first unknown read and wait branch
]
const EXPECTED_MULTIPLY_CODE := [
	0x85, 0xED, 0xA9, 0x00, 0x85, 0xEC, 0xA0, 0x08,
	0x06, 0xEC, 0x26, 0xED, 0x90, 0x0C, 0x8A, 0x18,
	0x65, 0xEC, 0x85, 0xEC, 0xA5, 0xED, 0x69, 0x00,
	0x85, 0xED, 0x88, 0xD0, 0xEB, 0x60,
]
const EXPECTED_CALLER_START := [0xA9, 0x00, 0x20, 0x20, 0x89] # $8112 LDA #$00 / JSR $8920

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _caller_source := PackedByteArray()
var _mapper_helper: Variant


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Fresh-match setup source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh-match setup source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-match-setup-sources-v1":
		return _fail("Fresh-match setup source manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh-match setup sources target a different ROM revision.")
	var entries: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			entries[String(span.get("id", ""))] = span
	for span_id: String in SOURCE_EXPECTATIONS:
		var expected: Dictionary = SOURCE_EXPECTATIONS[span_id]
		if not entries.has(span_id):
			return _fail("Fresh-match setup manifest omits `%s`." % span_id)
		var entry: Dictionary = entries[span_id]
		for field: String in ["path", "cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(field, -1)) == int(expected[field]) \
					if field == "length" else String(entry.get(field, "")) == String(expected[field])
			if not matches:
				return _fail("Fresh-match setup metadata differs for `%s` (%s)." % [span_id, field])
		var bytes := FileAccess.get_file_as_bytes("res://" + String(expected["path"]))
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]):
			return _fail("ROM source span `%s` failed its size/hash check." % span_id)
		if String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Manifest byte listing differs from `%s`." % span_id)
		_sources[span_id] = bytes
	if _sources["preset_loader_prefix"] != PackedByteArray(EXPECTED_SETUP_PREFIX) \
			or _sources["multiply_by_x_helper"] != PackedByteArray(EXPECTED_MULTIPLY_CODE):
		return _fail("Packaged `$8920/$9DEE` instruction bytes differ from the audited ROM spans.")
	if not FileAccess.file_exists(CALLER_MANIFEST_PATH):
		return _fail("The source caller manifest is missing.")
	var caller_manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(CALLER_MANIFEST_PATH))
	if not caller_manifest_variant is Dictionary:
		return _fail("The source caller manifest is malformed.")
	var caller_manifest: Dictionary = caller_manifest_variant
	var caller_rom: Variant = caller_manifest.get("rom", {})
	if not caller_rom is Dictionary or String(caller_rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Caller manifest targets a different ROM revision.")
	_caller_source = FileAccess.get_file_as_bytes(CALLER_FILE)
	if _caller_source.size() != 126 or _sha256(_caller_source) != CALLER_SHA256:
		return _fail("Hash-checked `$80DF-$815C` caller bytes are missing or changed.")
	var caller_manifest_entry: Dictionary = {}
	for span_variant in caller_manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == "bank00_title_to_first_match_setup_80DF_815C.bin":
			caller_manifest_entry = span_variant
			break
	if caller_manifest_entry.is_empty() \
			or String(caller_manifest_entry.get("bytes", "")).to_lower().replace(" ", "") != _caller_source.hex_encode():
		return _fail("Caller manifest bytes differ from the packaged `$80DF-$815C` source span.")
	var caller_offset := CALLER_ENTRY_PC - CALLER_START_PC
	if _caller_source.slice(caller_offset, caller_offset + EXPECTED_CALLER_START.size()) \
			!= PackedByteArray(EXPECTED_CALLER_START):
		return _fail("Caller `$8112` no longer executes `LDA #$00; JSR $8920`.")
	_mapper_helper = load("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd").new()
	if not _mapper_helper.configure_from_project_sources():
		return _fail("The fixed mapper helper could not validate its source/callsite spans: " + _mapper_helper.error_message)
	_configured = true
	return true


## Consumes the prior `$810F->$A20C->$8112` source execution result. `$78` is
## intentionally not read from that result: no provenance-bearing event for
## the preset-loader wait latch is currently part of the caller contract.
func execute_from_normalizer_return(normalizer_result: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var checked := _validate_normalizer_result(normalizer_result)
	if not bool(checked.get("ok", false)):
		return _failure(String(checked.get("error", "Normalization return contract is invalid.")))
	var source_event_id := String(checked["source_event_id"])
	var registers: Dictionary = checked["registers"].duplicate(true)
	var ram_after: Dictionary = checked["ram_after"].duplicate(true)
	var stack: PackedByteArray = checked["stack_after"].duplicate()
	var outer_pre_call_sp := int(registers["sp"])
	var writes: Array[Dictionary] = []
	var source_path: Array[int] = []
	var cycles := 0

	# Caller $8112 LDA #$00 / $8114 JSR $8920.
	registers["pc"] = CALLER_ENTRY_PC
	registers["a"] = 0
	registers["p"] = _set_nz(int(registers["p"]), 0)
	cycles += 2
	if not _push_jsr(stack, outer_pre_call_sp, SETUP_CALLER_PC + 2):
		return _failure("The full caller stack is required to push `$8114 JSR $8920`.")
	var outer_entry_sp := (outer_pre_call_sp - 2) & 0xFF
	var outer_return_word := _peek_return_word(stack, outer_entry_sp)
	if outer_return_word != SETUP_CALLER_PC + 2:
		return _failure("The `$8114` source JSR return word does not resolve to `$8116`.")
	registers["pc"] = SETUP_ENTRY_PC
	registers["sp"] = outer_entry_sp
	cycles += 6
	source_path.append_array([CALLER_ENTRY_PC, SETUP_CALLER_PC, SETUP_ENTRY_PC])

	# $8920 LDX #$13 / JSR $9DEE.
	registers["x"] = 0x13
	registers["p"] = _set_nz(int(registers["p"]), 0x13)
	cycles += 2
	var multiply_call_stack := stack.duplicate()
	if not _push_jsr(multiply_call_stack, int(registers["sp"]), MULTIPLY_RETURN_PC - 1):
		return _failure("The `$9DEE` nested JSR could not push its ROM return word.")
	var multiply_entry_sp := (int(registers["sp"]) - 2) & 0xFF
	var multiply_call := {
		"caller_pc": 0x8922,
		"target_pc": MULTIPLY_ENTRY_PC,
		"return_pc": MULTIPLY_RETURN_PC,
		"source_event_id": source_event_id,
		"pre_call_sp": int(registers["sp"]),
		"stack_page": multiply_call_stack,
	}
	var multiply_entry := registers.duplicate(true)
	multiply_entry["pc"] = MULTIPLY_ENTRY_PC
	multiply_entry["sp"] = multiply_entry_sp
	var multiply_result := _execute_multiply_helper(multiply_call, multiply_entry, ram_after, multiply_call_stack)
	if not bool(multiply_result.get("ok", false)):
		return multiply_result
	registers = multiply_result["return_registers"].duplicate(true)
	ram_after = multiply_result["ram_after"].duplicate(true)
	stack = multiply_result["stack_after"].duplicate()
	writes.append_array(multiply_result["ram_writes"])
	cycles += 6 + int(multiply_result["cpu_cycles"])
	source_path.append_array(multiply_result["source_path"])

	# Continue source bytes $8925-$8937 to the mapper call. This fresh caller
	# supplies A=0, so $9DEE computes EC/ED=0/0 and $8920 forms pointer BF00.
	if int(registers["pc"]) != MULTIPLY_RETURN_PC or int(registers["a"]) != 0 \
			or int(registers["x"]) != 0x13 or int(registers["y"]) != 0 \
			or int(registers["p"]) != 0x26:
		return _failure("The `$9DEE` source return differs from its fresh zero-index execution.")
	var arithmetic := _execute_preset_pointer_arithmetic(registers, ram_after)
	registers = arithmetic["registers"]
	ram_after = arithmetic["ram_after"]
	writes.append_array(arithmetic["ram_writes"])
	cycles += int(arithmetic["cpu_cycles"])
	source_path.append_array(arithmetic["source_path"])
	var mapper_pre_call_sp := int(registers["sp"])
	var mapper_stack := stack.duplicate()
	if not _push_jsr(mapper_stack, mapper_pre_call_sp, MAPPER_CALLER_PC + 2):
		return _failure("The `$8938` mapper helper JSR could not push its return word.")
	var mapper_call := {
		"caller_pc": MAPPER_CALLER_PC,
		"target_pc": 0xC4B9,
		"return_pc": MAPPER_RETURN_PC,
		"source_event_id": source_event_id,
		"pre_call_sp": mapper_pre_call_sp,
		"stack_page": mapper_stack,
	}
	var mapper_cpu := registers.duplicate(true)
	mapper_cpu["pc"] = 0xC4B9
	mapper_cpu["sp"] = (mapper_pre_call_sp - 2) & 0xFF
	var mapper_result: Dictionary = _mapper_helper.execute_source_call(mapper_call, mapper_cpu, ram_after)
	if not bool(mapper_result.get("ok", false)):
		return _failure("The `$8938->$C4B9` source mapper call did not return: " + String(mapper_result.get("error", "unknown error")))
	var mapper_registers: Dictionary = mapper_result["return_registers"].duplicate(true)
	var mapper_ram: Dictionary = mapper_result["ram_after"].duplicate(true)
	var mapper_writes: Array = mapper_result.get("mapper_bus_writes", [])
	if not _mapper_selected_bank(mapper_writes, PRESET_BANK) \
			or int(mapper_ram.get(0x0025, -1)) != PRESET_BANK \
			or int(mapper_registers.get("pc", -1)) != MAPPER_RETURN_PC \
			or int(mapper_registers.get("sp", -1)) != mapper_pre_call_sp:
		return _failure("The `$8938` mapper helper did not return at `$893B` with bank `$06` selected.")
	cycles += 6 + int(mapper_result.get("cpu_cycles", -1))
	source_path.append_array([MAPPER_CALLER_PC, 0xC4B9, 0xC4BC, 0xC4BE,
		0xC4C0, 0xC4C2, 0xC4C5, 0xC4C8, PRESET_WAIT_PC])
	writes.append_array(mapper_result.get("ram_writes", []))

	# At $893B the next instruction reads $78 and branches back while it is
	# nonzero. No source event in the incoming result owns this byte, so stop
	# before consuming it or claiming that the callee returns.
	return {
		"ok": true,
		"status": "stopped_at_unresolved_source_predicate",
		"completed": false,
		"source_event_id": source_event_id,
		"source_rom_sha256": ROM_SHA256,
		"source_span_hashes": _source_hashes(),
		"source_path": source_path,
		"prefix_returns": [
			{"caller_pc": 0x8922, "target_pc": MULTIPLY_ENTRY_PC,
				"return_pc": MULTIPLY_RETURN_PC, "rts_pc": 0x9E0B},
			mapper_result["source_return_receipt"],
		],
		"boundary": {
			"pc": PRESET_WAIT_PC,
			"next_opcode_bytes": [0xA5, 0x78, 0xD0, 0xFC],
			"operation": "LDA $78; BNE $893B",
			"required_ram_address": 0x0078,
			"required_value_source": "source-owned caller/scheduler event not present in the verified A20C continuation",
			"zero_successor_pc": 0x893F,
			"nonzero_successor_pc": PRESET_WAIT_PC,
		},
		"entry_registers": checked["registers"],
		"boundary_registers": mapper_registers,
		"caller_ram_after": mapper_ram,
		"caller_ram_writes": writes,
		"mapper_bus_writes": mapper_writes,
		"stack_after": mapper_stack,
		"cpu_cycles_without_interrupts_from_8112": cycles,
		"return_receipt": {},
		"live_mapper_updated": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _execute_multiply_helper(source_call: Dictionary, entry_registers: Dictionary,
		ram_before: Dictionary, stack: PackedByteArray) -> Dictionary:
	var entry_sp := int(source_call.get("pre_call_sp", -1)) - 2 & 0xFF
	if int(source_call.get("caller_pc", -1)) != 0x8922 \
			or int(source_call.get("target_pc", -1)) != MULTIPLY_ENTRY_PC \
			or int(source_call.get("return_pc", -1)) != MULTIPLY_RETURN_PC \
			or int(entry_registers.get("pc", -1)) != MULTIPLY_ENTRY_PC \
			or int(entry_registers.get("sp", -1)) != entry_sp \
			or int(entry_registers.get("a", -1)) != 0 \
			or int(entry_registers.get("x", -1)) != 0x13:
		return _failure("Only the source-derived `$8920` A=0/X=$13 `$9DEE` entry is supported.")
	if stack.size() != 0x100 or _peek_return_word(stack, entry_sp) != MULTIPLY_RETURN_PC - 1:
		return _failure("The `$9DEE` call does not have its exact `$8924` stacked return word.")
	var registers := entry_registers.duplicate(true)
	var ram_after := ram_before.duplicate(true)
	var writes: Array[Dictionary] = []
	var source_path: Array[int] = [MULTIPLY_ENTRY_PC, 0x9DF0, 0x9DF2, 0x9DF4]
	ram_after[0x00ED] = 0
	writes.append({"source_pc": 0x9DEE, "address": 0x00ED, "value": 0})
	registers["a"] = 0
	registers["p"] = _set_nz(int(registers["p"]), 0)
	ram_after[0x00EC] = 0
	writes.append({"source_pc": 0x9DF2, "address": 0x00EC, "value": 0})
	registers["y"] = 8
	registers["p"] = _set_nz(int(registers["p"]), 8)
	var cycles := 3 + 2 + 3 + 2
	for iteration in range(8):
		source_path.append_array([0x9DF6, 0x9DF8, 0x9DFA, 0x9E08, 0x9E09])
		# ASL $EC and ROL $ED are ROM instructions. Since the source caller
		# supplies A=0, both bytes remain zero and BCC is taken each iteration.
		registers["a"] = 0
		registers["p"] = _set_nz(int(registers["p"]) & 0xFE, 0)
		registers["p"] = _set_nz(int(registers["p"]) & 0xFE, 0)
		ram_after[0x00EC] = 0
		ram_after[0x00ED] = 0
		writes.append({"source_pc": 0x9DF6, "address": 0x00EC, "value": 0})
		writes.append({"source_pc": 0x9DF8, "address": 0x00ED, "value": 0})
		registers["y"] = (int(registers["y"]) - 1) & 0xFF
		registers["p"] = _set_nz(int(registers["p"]), int(registers["y"]))
		cycles += 5 + 5 + 3 + 2 + (3 if iteration < 7 else 2)
	var returned := _pop_rts(stack, entry_sp)
	if int(returned["return_pc"]) != MULTIPLY_RETURN_PC \
			or int(returned["sp"]) != int(source_call["pre_call_sp"]):
		return _failure("The ROM `$9DEE RTS` did not return to `$8925` with a balanced nested stack.")
	registers["pc"] = MULTIPLY_RETURN_PC
	registers["sp"] = int(returned["sp"])
	cycles += 6
	return {
		"ok": true,
		"return_registers": registers,
		"ram_after": ram_after,
		"ram_writes": writes,
		"stack_after": stack,
		"source_path": source_path,
		"cpu_cycles": cycles,
	}


func _execute_preset_pointer_arithmetic(registers_in: Dictionary, ram_in: Dictionary) -> Dictionary:
	var registers := registers_in.duplicate(true)
	var ram_after := ram_in.duplicate(true)
	var writes: Array[Dictionary] = []
	var source_path: Array[int] = [0x8925, 0x8927, 0x8928, 0x892A, 0x892C, 0x892E, 0x8930, 0x8932, 0x8934, 0x8936]
	var cycles := 0
	registers["a"] = int(ram_after.get(0x00EC, -1))
	registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
	cycles += 3
	registers["p"] = int(registers["p"]) & 0xFE
	cycles += 2
	registers["a"] = int(registers["a"]) & 0xFF
	registers["p"] = _adc_imm(int(registers["p"]), int(registers["a"]), 0, false)
	cycles += 2
	ram_after[0x00EC] = int(registers["a"])
	writes.append({"source_pc": 0x892A, "address": 0x00EC, "value": int(registers["a"])})
	cycles += 3
	registers["a"] = int(ram_after.get(0x00ED, -1))
	registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
	cycles += 3
	registers["a"] = (int(registers["a"]) + 0xBF) & 0xFF
	registers["p"] = _adc_imm(int(registers["p"]), int(ram_after[0x00ED]), 0xBF, false)
	cycles += 2
	ram_after[0x00ED] = int(registers["a"])
	writes.append({"source_pc": 0x8930, "address": 0x00ED, "value": int(registers["a"])})
	cycles += 3
	registers["a"] = int(ram_after.get(0x0025, -1))
	registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
	cycles += 3
	ram_after[0x00EA] = int(registers["a"])
	writes.append({"source_pc": 0x8934, "address": 0x00EA, "value": int(registers["a"])})
	cycles += 3
	registers["x"] = PRESET_BANK
	registers["p"] = _set_nz(int(registers["p"]), PRESET_BANK)
	cycles += 2
	registers["pc"] = MAPPER_CALLER_PC
	if int(ram_after[0x00EC]) != 0 or int(ram_after[0x00ED]) != 0xBF \
			or int(ram_after[0x00EA]) != BANK2 \
			or int(registers["a"]) != BANK2 or int(registers["y"]) != 0:
		return {"ok": false, "error": "Fresh `$8920` source arithmetic did not yield BF00 and prior bank `$02`."}
	return {"registers": registers, "ram_after": ram_after, "ram_writes": writes,
		"source_path": source_path, "cpu_cycles": cycles}


func _validate_normalizer_result(result: Dictionary) -> Dictionary:
	if not bool(result.get("ok", false)) or String(result.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "A successful result for the supplied ROM is required from the A20C normalizer."}
	if bool(result.get("trace_state_used", true)) or bool(result.get("emulator_data_used", true)):
		return {"ok": false, "error": "The prior normalizer result must not depend on trace/emulator state."}
	var receipt: Dictionary = result.get("normalize_source_return_receipt", {})
	if int(receipt.get("caller_pc", -1)) != 0x810F \
			or int(receipt.get("target_pc", -1)) != 0xA20C \
			or int(receipt.get("return_pc", -1)) != CALLER_ENTRY_PC \
			or int(receipt.get("rts_pc", -1)) != 0xA8B6:
		return {"ok": false, "error": "Previous return must be verified `$810F->$A20C->$8112` source execution."}
	var source_event_id := String(result.get("source_event_id", "")).strip_edges()
	if source_event_id.is_empty() or source_event_id != String(receipt.get("source_event_id", "")):
		return {"ok": false, "error": "The original source-event identity must be preserved."}
	var source_hashes: Dictionary = result.get("source_span_hashes", {})
	if String(source_hashes.get("title_caller", "")) != CALLER_SHA256:
		return {"ok": false, "error": "The predecessor did not preserve hash-checked title caller bytes."}
	var registers: Dictionary = result.get("return_registers", {})
	if int(registers.get("pc", -1)) != CALLER_ENTRY_PC \
			or int(registers.get("sp", -1)) < 2 or int(registers.get("sp", -1)) > 0xFF \
			or int(registers.get("a", -1)) != 3 or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 0x84 or int(registers.get("p", -1)) != 0x24:
		return {"ok": false, "error": "The A20C return CPU state differs from the verified caller boundary."}
	var ram: Dictionary = result.get("caller_ram_after", {})
	for address: int in [0x0022, 0x0023, 0x0025, 0x0026, 0x002A, 0x002B]:
		if not ram.has(address):
			return {"ok": false, "error": "Predecessor RAM is missing `$%04X`." % address}
	if int(ram[0x0022]) != 0x80 or int(ram[0x0023]) != 0x87 \
			or int(ram[0x0025]) != 2 or int(ram[0x0026]) != 0 \
			or int(ram[0x002A]) != 0 or int(ram[0x002B]) != 3:
		return {"ok": false, "error": "Predecessor RAM/map state does not satisfy the fresh match-zero setup contract."}
	if ram.has(0x0078):
		return {"ok": false, "error": "Incoming `$0078` lacks an explicit source provenance event; refusing snapshot or unowned wait state."}
	var stack: Variant = result.get("stack_after")
	if not stack is PackedByteArray or stack.size() != 0x100:
		return {"ok": false, "error": "The source caller's complete 256-byte stack page is required."}
	return {"ok": true, "source_event_id": source_event_id,
		"registers": registers, "ram_after": ram, "stack_after": stack}


func _mapper_selected_bank(bus_writes: Array, expected_bank: int) -> bool:
	var select_seen := false
	var data_seen := false
	for write_variant in bus_writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x8000 and int(write.get("value", -1)) == 0x87:
			select_seen = true
		if select_seen and int(write.get("address", -1)) == 0x8001 \
				and int(write.get("value", -1)) == expected_bank:
			data_seen = true
	return select_seen and data_seen


func _push_jsr(stack: PackedByteArray, sp: int, pushed_return: int) -> bool:
	if stack.size() != 0x100 or sp < 0 or sp > 0xFF:
		return false
	stack[sp] = (pushed_return >> 8) & 0xFF
	stack[(sp - 1) & 0xFF] = pushed_return & 0xFF
	return true


func _peek_return_word(stack: PackedByteArray, entry_sp: int) -> int:
	return int(stack[(entry_sp + 1) & 0xFF]) | (int(stack[(entry_sp + 2) & 0xFF]) << 8)


func _pop_rts(stack: PackedByteArray, sp: int) -> Dictionary:
	return {"return_pc": _peek_return_word(stack, sp) + 1, "sp": (sp + 2) & 0xFF}


func _set_nz(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0x80) != 0:
		result |= 0x80
	if (value & 0xFF) == 0:
		result |= 0x02
	return result


func _adc_imm(status: int, left: int, right: int, carry_in: bool) -> int:
	var sum_value := left + right + (1 if carry_in else 0)
	var result := sum_value & 0xFF
	var flags := 0
	if sum_value > 0xFF:
		flags |= 0x01
	if result == 0:
		flags |= 0x02
	if ((~(left ^ right) & (left ^ result)) & 0x80) != 0:
		flags |= 0x40
	if (result & 0x80) != 0:
		flags |= 0x80
	return (status & 0x3C) | flags


func _source_hashes() -> Dictionary:
	var hashes: Dictionary = {}
	for source_id: String in _sources:
		hashes[source_id] = _sha256(_sources[source_id])
	return hashes


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
