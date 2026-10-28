extends RefCounted
class_name RomFreshMatchNormalizeExecutor
## Continues a verified fresh-match selector return through the caller's
## $80FD-$810F bytes, the second $C4B9 call, and the ROM's $A20C RTS path.
## $E4 is treated symbolically: the checked $26=0 branch is proven invariant
## for every byte value, so no trace or guessed RAM value is needed.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_match_selector/manifest.json"
const CALLER_START_PC := 0x80DF
const CALLER_END_PC_EXCLUSIVE := 0x815D
const SELECTOR_RETURN_PC := 0x80FD
const MAPPER_CALLER_PC := 0x810C
const MAPPER_RETURN_PC := 0x810F
const NORMALIZE_CALLER_PC := 0x810F
const NORMALIZE_ENTRY_PC := 0xA20C
const NORMALIZE_BODY_PC := 0xA855
const NORMALIZE_BRANCH_PC := 0xA859
const NORMALIZE_TAIL_PC := 0xA8A8
const NORMALIZE_RTS_PC := 0xA8B6
const NORMALIZE_RETURN_PC := 0x8112
const FRESH_MATCH_INDEX := 0

const SOURCE_EXPECTATIONS := {
	"title_caller": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_caller/bank00_title_to_first_match_setup_80DF_815C.bin",
		"cpu_start": "$80DF", "cpu_end_exclusive": "$815D", "file_offset": "0x0000EF",
		"length": 126, "sha256": "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b",
	},
	"selector_normalize_trampoline": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_normalize_trampoline_A20C_A20E.bin",
		"cpu_start": "$A20C", "cpu_end_exclusive": "$A20F", "file_offset": "0x00421C",
		"length": 3, "sha256": "fd63c4efff31a65f750b91006a64e730ba7c8bb4e2a3ca1ab612762808d7b433",
	},
	"selector_normalize_branch": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_normalize_branch_A855_A86D.bin",
		"cpu_start": "$A855", "cpu_end_exclusive": "$A86E", "file_offset": "0x004865",
		"length": 25, "sha256": "f43346f767ca9308764322a418899da490fca7537eb40096fcac8529a7c917e3",
	},
	"selector_code": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_entry_context/match_selector_A86E_A8CD.bin",
		"cpu_start": "$A86E", "cpu_end_exclusive": "$A8CE", "file_offset": "0x00487E",
		"length": 96, "sha256": "f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123",
	},
	"home_team_match_table": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_position_context/bank_02_match_00_home_team_id_AA75.bin",
		"cpu_start": "$AA75", "cpu_end_exclusive": "$AA76", "file_offset": "0x004A85",
		"length": 1, "sha256": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
	},
}

const EXPECTED_CALLER_CONTINUATION := [
	0xA9, 0x00, 0x85, 0x28, 0x85, 0x29, 0x85, 0x27,
	0xA9, 0x01, 0x8D, 0x00, 0x07, 0xA2, 0x02,
	0x20, 0xB9, 0xC4, 0x20, 0x0C, 0xA2,
]
const EXPECTED_NORMALIZE_TRAMPOLINE := [0x4C, 0x55, 0xA8]
const EXPECTED_NORMALIZE_BRANCH := [
	0xA5, 0xE4, # LDA $E4
	0xC5, 0x26, # CMP $26
	0xB0, 0x4D, # BCS $A8A8
	0xA5, 0x26, 0xF0, 0x1D, 0xC9, 0x06, 0xF0, 0x21,
	0xC9, 0x0C, 0xF0, 0x15, 0xC9, 0x10, 0xF0, 0x21,
	0x4C, 0xA8, 0xA8,
]
const EXPECTED_NORMALIZE_TAIL := [
	0xA6, 0x26, 0xBD, 0x75, 0xAA, 0x85, 0x2A,
	0xA5, 0x26, 0x18, 0x69, 0x03, 0x85, 0x2B, 0x60,
]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _mapper_helper: Variant


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Fresh-match selector manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh-match selector manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-match-selector-executable-v1":
		return _fail("Fresh-match selector manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Normalization sources target a different ROM revision.")
	var entries: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			entries[String(span.get("id", ""))] = span
	for span_id: String in SOURCE_EXPECTATIONS:
		var expected: Dictionary = SOURCE_EXPECTATIONS[span_id]
		if not entries.has(span_id):
			return _fail("Normalization manifest omits `%s`." % span_id)
		var entry: Dictionary = entries[span_id]
		for field: String in ["path", "cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(field, -1)) == int(expected[field]) \
					if field == "length" else String(entry.get(field, "")) == String(expected[field])
			if not matches:
				return _fail("Normalization source metadata differs for `%s` (%s)." % [span_id, field])
		var bytes := FileAccess.get_file_as_bytes("res://" + String(expected["path"]))
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]):
			return _fail("ROM source span `%s` failed its size/hash check." % span_id)
		if String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Manifest byte listing differs from `%s`." % span_id)
		_sources[span_id] = bytes
	if _sources["selector_normalize_trampoline"] != PackedByteArray(EXPECTED_NORMALIZE_TRAMPOLINE) \
			or _sources["selector_normalize_branch"] != PackedByteArray(EXPECTED_NORMALIZE_BRANCH):
		return _fail("Packaged `$A20C->$A855` normalization bytes differ from the audited ROM path.")
	if _sources["title_caller"].slice(SELECTOR_RETURN_PC - CALLER_START_PC,
			SELECTOR_RETURN_PC - CALLER_START_PC + EXPECTED_CALLER_CONTINUATION.size()) != PackedByteArray(EXPECTED_CALLER_CONTINUATION):
		return _fail("Caller bytes `$80FD-$8111` no longer contain the expected setup and two JSRs.")
	var selector_tail_offset := NORMALIZE_TAIL_PC - 0xA86E
	if _sources["selector_code"].slice(selector_tail_offset,
			selector_tail_offset + EXPECTED_NORMALIZE_TAIL.size()) != PackedByteArray(EXPECTED_NORMALIZE_TAIL):
		return _fail("Packaged `$A8A8-$A8B6` common tail differs from the audited ROM instructions.")
	if int(_sources["home_team_match_table"][0]) != 0:
		return _fail("Match-zero home-team table no longer contains the ROM value `$00`.")
	_mapper_helper = load("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd").new()
	if not _mapper_helper.configure_from_project_sources():
		return _fail("The fixed mapper helper could not validate its ROM and caller sources: " + _mapper_helper.error_message)
	_configured = true
	return true


## Consumes a successful `$80FA->$A20F->$80FD` source execution result. All
## caller RAM, registers, mapper shadow and stack are carried from that result;
## `$E4` is not supplied because an exhaustive byte proof establishes that its
## value cannot affect this fresh `$26=0` return path.
func execute_from_selector_return(selector_result: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var result_check := _validate_selector_result(selector_result)
	if not bool(result_check.get("ok", false)):
		return _failure(String(result_check.get("error", "Selector return contract is invalid.")))
	var source_event_id := String(result_check["source_event_id"])
	var registers: Dictionary = result_check["registers"].duplicate(true)
	var ram_after: Dictionary = result_check["ram_after"].duplicate(true)
	var stack: PackedByteArray = result_check["stack_after"].duplicate()
	var pre_call_sp := int(registers["sp"])
	var writes: Array[Dictionary] = []
	var source_path: Array[int] = []
	var cycles := 0

	# Execute exact caller instructions $80FD-$810B.
	registers["pc"] = SELECTOR_RETURN_PC
	registers["a"] = 0
	registers["p"] = _set_nz(int(registers["p"]), 0)
	source_path.append_array([0x80FD, 0x80FF, 0x8101, 0x8103])
	writes.append_array([
		{"source_pc": 0x80FF, "address": 0x0028, "value": 0},
		{"source_pc": 0x8101, "address": 0x0029, "value": 0},
		{"source_pc": 0x8103, "address": 0x0027, "value": 0},
	])
	ram_after[0x0028] = 0
	ram_after[0x0029] = 0
	ram_after[0x0027] = 0
	cycles += 2 + 3 + 3 + 3
	registers["a"] = 1
	registers["p"] = _set_nz(int(registers["p"]), 1)
	ram_after[0x0700] = 1
	writes.append({"source_pc": 0x8109, "address": 0x0700, "value": 1})
	registers["x"] = 2
	registers["p"] = _set_nz(int(registers["p"]), 2)
	cycles += 2 + 4 + 2
	registers["pc"] = MAPPER_CALLER_PC
	source_path.append_array([0x8105, 0x8107, 0x810A, MAPPER_CALLER_PC])
	var mapper_stack := stack.duplicate()
	if not _push_jsr(mapper_stack, pre_call_sp, MAPPER_CALLER_PC + 2):
		return _failure("The caller stack page is not a decoded 256-byte stack.")
	var mapper_call := {
		"caller_pc": MAPPER_CALLER_PC,
		"target_pc": 0xC4B9,
		"return_pc": MAPPER_RETURN_PC,
		"source_event_id": source_event_id,
		"pre_call_sp": pre_call_sp,
		"stack_page": mapper_stack,
	}
	var mapper_cpu := registers.duplicate(true)
	mapper_cpu["pc"] = 0xC4B9
	mapper_cpu["sp"] = (pre_call_sp - 2) & 0xFF
	var mapper_result: Dictionary = _mapper_helper.execute_source_call(mapper_call, mapper_cpu, ram_after)
	if not bool(mapper_result.get("ok", false)):
		return _failure("Caller `$810C->$C4B9` did not return from its source helper: " + String(mapper_result.get("error", "unknown error")))
	var mapper_registers: Dictionary = mapper_result["return_registers"].duplicate(true)
	var mapper_ram: Dictionary = mapper_result["ram_after"].duplicate(true)
	var mapper_bus_writes: Array = mapper_result.get("mapper_bus_writes", [])
	if not _mapper_selected_bank_two(mapper_bus_writes):
		return _failure("The `$810C` ROM mapper helper did not select bank `$02` before `$A20C`.")
	if int(mapper_registers.get("pc", -1)) != MAPPER_RETURN_PC \
			or int(mapper_registers.get("sp", -1)) != pre_call_sp \
			or int(mapper_registers.get("a", -1)) != 0x87 \
			or int(mapper_registers.get("x", -1)) != 2 \
			or int(mapper_registers.get("y", -1)) != 0x84 \
			or int(mapper_registers.get("p", -1)) != 0xA4:
		return _failure("The `$C4B9` return registers/stack do not match the `$810F` bank-$02 entry contract.")
	cycles += 6 + int(mapper_result.get("cpu_cycles", -1))
	source_path.append_array([0xC4B9, 0xC4BC, 0xC4BE, 0xC4C0, 0xC4C2, 0xC4C5, 0xC4C8, 0x810F])

	var normalize_pre_sp := int(mapper_registers["sp"])
	var normalize_stack: PackedByteArray = mapper_stack.duplicate()
	if not normalize_stack is PackedByteArray or normalize_stack.size() != 0x100:
		return _failure("The mapper helper did not preserve its caller's complete stack page.")
	normalize_stack = normalize_stack.duplicate()
	if not _push_jsr(normalize_stack, normalize_pre_sp, NORMALIZE_CALLER_PC + 2):
		return _failure("The normalization caller stack could not accept its verified JSR.")
	var normalize_call := {
		"caller_pc": NORMALIZE_CALLER_PC,
		"target_pc": NORMALIZE_ENTRY_PC,
		"return_pc": NORMALIZE_RETURN_PC,
		"source_event_id": source_event_id,
		"pre_call_sp": normalize_pre_sp,
		"stack_page": normalize_stack,
	}
	var normalize_entry := mapper_registers.duplicate(true)
	normalize_entry["pc"] = NORMALIZE_ENTRY_PC
	normalize_entry["sp"] = (normalize_pre_sp - 2) & 0xFF
	var normalize_result := _execute_normalize(normalize_call, normalize_entry, mapper_ram, normalize_stack)
	if not bool(normalize_result.get("ok", false)):
		return normalize_result
	cycles += 6 + int(normalize_result["cpu_cycles"])
	source_path.append_array(normalize_result["source_path"])

	var final_registers: Dictionary = normalize_result["return_registers"]
	var final_ram: Dictionary = normalize_result["ram_after"]
	writes.append_array(mapper_result.get("ram_writes", []))
	writes.append_array(normalize_result.get("ram_writes", []))
	return {
		"ok": true,
		"status": "returned",
		"source_event_id": source_event_id,
		"source_rom_sha256": ROM_SHA256,
		"source_span_hashes": _source_hashes(),
		"source_path": source_path,
		"selector_return_input": {"caller_pc": 0x80FA, "return_pc": SELECTOR_RETURN_PC,
			"source_event_id": source_event_id},
		"mapper_helper_receipt": mapper_result["source_return_receipt"],
		"normalize_source_return_receipt": normalize_result["source_return_receipt"],
		"e4_branch_proof": normalize_result["e4_branch_proof"],
		"caller_ram_writes": writes,
		"caller_ram_after": final_ram,
		"caller_mapper_bus_writes": mapper_bus_writes,
		"return_registers": final_registers,
		"stack_after": normalize_result["stack_after"],
		"cpu_cycles_without_interrupts_from_80FD": cycles,
		"live_mapper_updated": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _validate_selector_result(selector_result: Dictionary) -> Dictionary:
	if not bool(selector_result.get("ok", false)) \
			or String(selector_result.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "A successful result for the supplied ROM is required from the `$A20F` executor."}
	if bool(selector_result.get("trace_state_used", true)) or bool(selector_result.get("emulator_data_used", true)):
		return {"ok": false, "error": "The `$A20F` result must not depend on trace or emulator state."}
	var receipt: Dictionary = selector_result.get("source_return_receipt", {})
	if int(receipt.get("caller_pc", -1)) != 0x80FA \
			or int(receipt.get("target_pc", -1)) != 0xA20F \
			or int(receipt.get("return_pc", -1)) != SELECTOR_RETURN_PC \
			or String(receipt.get("status", "")) != "returned":
		return {"ok": false, "error": "The previous source return must be the verified `$80FA->$A20F->$80FD` call."}
	var source_event_id := String(receipt.get("source_event_id", "")).strip_edges()
	if source_event_id.is_empty():
		return {"ok": false, "error": "The `$A20F` source event identity must be preserved across the synchronous caller continuation."}
	var hashes: Dictionary = selector_result.get("source_span_hashes", {})
	for required_id: String in ["title_caller", "selector_code", "home_team_match_table"]:
		if String(hashes.get(required_id, "")) != String(SOURCE_EXPECTATIONS[required_id]["sha256"]):
			return {"ok": false, "error": "The prior selector receipt is missing verified `%s` source bytes." % required_id}
	var registers: Dictionary = selector_result.get("return_registers", {})
	if int(registers.get("pc", -1)) != SELECTOR_RETURN_PC \
			or int(registers.get("sp", -1)) < 0 or int(registers.get("sp", -1)) > 0xFF \
			or int(registers.get("a", -1)) != 3 or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 0x84 or int(registers.get("p", -1)) != 0x24:
		return {"ok": false, "error": "The `$A20F` returned CPU state does not match the verified fresh match-zero contract."}
	var ram_after: Dictionary = selector_result.get("ram_after", {})
	for address: int in [0x0022, 0x0023, 0x0025, 0x0026, 0x002A, 0x002B]:
		if not ram_after.has(address):
			return {"ok": false, "error": "Prior selector state is missing caller RAM `$%04X`." % address}
	if int(ram_after[0x0022]) != 0x80 or int(ram_after[0x0023]) != 0x87 \
			or int(ram_after[0x0025]) != 2 or int(ram_after[0x0026]) != FRESH_MATCH_INDEX \
			or int(ram_after[0x002A]) != 0 or int(ram_after[0x002B]) != 3:
		return {"ok": false, "error": "The prior selector RAM/map shadows do not satisfy the fresh match-zero caller contract."}
	var stack: Variant = selector_result.get("stack_after")
	if not stack is PackedByteArray or stack.size() != 0x100:
		return {"ok": false, "error": "The full source stack page from the `$A20F` return is required."}
	var pre_call_sp := int(registers["sp"])
	if int(stack[(pre_call_sp - 1) & 0xFF]) != 0xFC \
			or int(stack[pre_call_sp]) != 0x80:
		return {"ok": false, "error": "The outer `$80FA` JSR stack continuation was not preserved at `$80FD`."}
	return {"ok": true, "source_event_id": source_event_id, "registers": registers,
		"ram_after": ram_after, "stack_after": stack}


func _execute_normalize(source_call: Dictionary, entry_registers: Dictionary,
		ram_before: Dictionary, stack: PackedByteArray) -> Dictionary:
	if int(source_call.get("caller_pc", -1)) != NORMALIZE_CALLER_PC \
			or int(source_call.get("target_pc", -1)) != NORMALIZE_ENTRY_PC \
			or int(source_call.get("return_pc", -1)) != NORMALIZE_RETURN_PC:
		return _failure("Normalization call does not match ROM `$810F JSR $A20C`.")
	var entry_sp := (int(source_call["pre_call_sp"]) - 2) & 0xFF
	if int(entry_registers.get("pc", -1)) != NORMALIZE_ENTRY_PC \
			or int(entry_registers.get("sp", -1)) != entry_sp:
		return _failure("Normalization PC/SP do not match the source JSR entry.")
	if stack.size() != 0x100 or _peek_return_word(stack, entry_sp) != NORMALIZE_CALLER_PC + 2:
		return _failure("Normalization call does not have its exact `$8111` stacked JSR return word.")
	if int(ram_before.get(0x0026, -1)) != FRESH_MATCH_INDEX:
		return _failure("Only source-derived fresh match index `$0026=0` is supported.")
	if int(entry_registers.get("x", -1)) != 2 \
			or int(entry_registers.get("a", -1)) != 0x87 \
			or int(ram_before.get(0x0023, -1)) != 0x87 \
			or int(ram_before.get(0x0025, -1)) != 2:
		return _failure("The `$A20C` entry does not follow the ROM `$810C->$C4B9` bank-$02 helper.")
	var branch_proof := _prove_e4_branch_invariance(int(ram_before[0x0026]),
			int(entry_registers.get("p", -1)), int(_sources["home_team_match_table"][0]))
	if not bool(branch_proof.get("ok", false)):
		return _failure("The `$E4`-independent branch proof failed: " + String(branch_proof.get("error", "unknown error")))

	var registers := entry_registers.duplicate(true)
	var ram_after := ram_before.duplicate(true)
	var writes: Array[Dictionary] = []
	var source_path: Array[int] = [NORMALIZE_ENTRY_PC, NORMALIZE_BODY_PC, 0xA857,
		NORMALIZE_BRANCH_PC, NORMALIZE_TAIL_PC, 0xA8AA, 0xA8AD, 0xA8AF,
		0xA8B1, 0xA8B2, 0xA8B4, NORMALIZE_RTS_PC]
	# At A855, E4 is an unconstrained input. The exhaustive proof above shows
	# CMP E4,$26 sets carry for all values when $26=0; branch outcomes and the
	# post-tail state match for every E4 candidate.
	var cycles := 3 + 3 + 3 + 3 # JMP, LDA zp, CMP zp, taken BCS
	registers["pc"] = NORMALIZE_TAIL_PC
	registers["x"] = FRESH_MATCH_INDEX
	registers["p"] = int(branch_proof["flags_after_ldx_overwrite"])
	cycles += 3 # LDX $26
	var home_team := int(_sources["home_team_match_table"][0])
	registers["a"] = home_team
	registers["p"] = _set_nz(int(registers["p"]), home_team)
	cycles += 4 # LDA $AA75,X (match zero)
	ram_after[0x002A] = home_team
	writes.append({"source_pc": 0xA8AD, "address": 0x002A, "value": home_team})
	cycles += 3 # STA $2A
	var match_index := int(ram_after[0x0026])
	registers["a"] = match_index
	registers["p"] = _set_nz(int(registers["p"]), match_index)
	cycles += 3 # LDA $26
	registers["p"] = int(registers["p"]) & 0xFE
	cycles += 2 # CLC
	registers["a"] = (match_index + 3) & 0xFF
	registers["p"] = _adc_imm(int(registers["p"]), match_index, 3, false)
	cycles += 2 # ADC #$03
	ram_after[0x002B] = int(registers["a"])
	writes.append({"source_pc": 0xA8B4, "address": 0x002B, "value": int(registers["a"])})
	cycles += 3 # STA $2B
	var returned := _pop_rts(stack, entry_sp)
	if int(returned["return_pc"]) != NORMALIZE_RETURN_PC \
			or int(returned["sp"]) != int(source_call["pre_call_sp"]):
		return _failure("The source `$A8B6 RTS` did not return to `$8112` with a balanced stack.")
	registers["sp"] = int(returned["sp"])
	registers["pc"] = NORMALIZE_RETURN_PC
	cycles += 6
	return {
		"ok": true,
		"status": "returned",
		"source_return_receipt": {
			"caller_pc": NORMALIZE_CALLER_PC,
			"target_pc": NORMALIZE_ENTRY_PC,
			"return_pc": NORMALIZE_RETURN_PC,
			"status": "returned",
			"source_event_id": String(source_call["source_event_id"]),
			"source_execution": "hash_checked_symbolic_branch_6502_subset_through_real_rts",
			"rts_pc": NORMALIZE_RTS_PC,
			"post_registers": registers.duplicate(true),
		},
		"entry_registers": entry_registers.duplicate(true),
		"return_registers": registers,
		"ram_after": ram_after,
		"ram_writes": writes,
		"stack_after": stack,
		"source_path": source_path,
		"cpu_cycles": cycles,
		"e4_branch_proof": branch_proof,
	}


func _prove_e4_branch_invariance(match_index: int, input_p: int, home_team: int) -> Dictionary:
	if match_index != FRESH_MATCH_INDEX:
		return {"ok": false, "error": "Expected match zero."}
	if input_p < 0 or input_p > 0xFF or home_team < 0 or home_team > 0xFF:
		return {"ok": false, "error": "Entry P and ROM team byte must be explicit bytes."}
	var reference_return_p := -1
	for e4_candidate in range(0x100):
		var after_lda := _set_nz(input_p, e4_candidate)
		var after_cmp := _compare(after_lda, e4_candidate, match_index)
		if (after_cmp & 0x01) == 0:
			return {"ok": false, "error": "BCS is not taken for E4 candidate `$%02X`." % e4_candidate}
		var after_ldx := _set_nz(after_cmp, match_index)
		var after_team_lda := _set_nz(after_ldx, home_team)
		var after_match_lda := _set_nz(after_team_lda, match_index)
		var after_clc := after_match_lda & 0xFE
		var after_adc := _adc_imm(after_clc, match_index, 3, false)
		if reference_return_p < 0:
			reference_return_p = after_adc
		elif after_adc != reference_return_p:
			return {"ok": false, "error": "Return flags differ for E4 candidate `$%02X`." % e4_candidate}
	return {
		"ok": true,
		"method": "exhaustive_symbolic_byte_domain",
		"input_value_supplied": false,
		"candidate_values_checked": 0x100,
		"match_index": match_index,
		"branch_pc": NORMALIZE_BRANCH_PC,
		"branch_target_pc": NORMALIZE_TAIL_PC,
		"branch_taken_for_all_candidates": true,
		"flags_after_ldx_overwrite": (input_p & 0x7C) | 0x03,
		"return_register_a": (match_index + 3) & 0xFF,
		"return_register_x": match_index,
		"return_flags": reference_return_p,
	}


func _mapper_selected_bank_two(bus_writes: Array) -> bool:
	var select_seen := false
	var data_seen := false
	for write_variant in bus_writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x8000 and int(write.get("value", -1)) == 0x87:
			select_seen = true
		if select_seen and int(write.get("address", -1)) == 0x8001 and int(write.get("value", -1)) == 2:
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
	var return_word := _peek_return_word(stack, sp)
	return {"return_pc": return_word + 1, "sp": (sp + 2) & 0xFF}


func _set_nz(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0x80) != 0:
		result |= 0x80
	if (value & 0xFF) == 0:
		result |= 0x02
	return result


func _compare(status: int, left: int, right: int) -> int:
	var result := (left - right) & 0xFF
	var flags := 0
	if left >= right:
		flags |= 0x01
	if result == 0:
		flags |= 0x02
	if (result & 0x80) != 0:
		flags |= 0x80
	return (status & 0x7C) | flags


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
