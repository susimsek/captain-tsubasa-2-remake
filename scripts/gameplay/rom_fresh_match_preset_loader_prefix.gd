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
const MULTIPLY_CALLER_PC := 0x8922
const MULTIPLY_ENTRY_PC := 0x9DEE
const MULTIPLY_RETURN_PC := 0x8925
const MAPPER_CALLER_PC := 0x8938
const MAPPER_RETURN_PC := 0x893B
const BANK2 := 2
const PRESET_BANK := 6
const BANK_SELECT_REGISTER_ID := 0x07

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
const WAIT_SOURCE_MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/manifest.json"
const WAIT_TAIL_SOURCE_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/bank00_preset_copy_tail_893F_895C.bin"
const WAIT_TAIL_SOURCE_SHA256 := "a59af362a985b858db682fb6f99cb85c8e817eb403c25df5484cb87076877001"
const PRESET_RECORD_SOURCE_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/bank06_preset_record_BF00_BF12.bin"
const PRESET_RECORD_SOURCE_SHA256 := "d6fd62f5ce537d90ea3ea45841b17f34d727bcbc4128748cba14fb87c0ffd9d1"
const EXPECTED_WAIT_TAIL_BYTES := [
	0xA0, 0x00, 0xB1, 0xEC, 0x8D, 0x79, 0x00, 0xA9, 0x00, 0x8D, 0x7A, 0x00,
	0xC8, 0xA2, 0x12, 0xB1, 0xEC, 0x99, 0x7B, 0x00, 0xC8, 0xCA, 0xD0, 0xF7,
	0xA6, 0xEA, 0x20, 0xB9, 0xC4, 0x60,
]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _caller_source := PackedByteArray()
var _wait_tail_source := PackedByteArray()
var _preset_record_source := PackedByteArray()
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
	if not FileAccess.file_exists(WAIT_SOURCE_MANIFEST_PATH):
		return _fail("The ROM wait/continuation source manifest is unavailable.")
	var wait_manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(WAIT_SOURCE_MANIFEST_PATH))
	if not wait_manifest_variant is Dictionary:
		return _fail("The ROM wait/continuation source manifest is malformed.")
	var wait_manifest: Dictionary = wait_manifest_variant
	var wait_rom: Variant = wait_manifest.get("rom", {})
	if not wait_rom is Dictionary or String(wait_rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The ROM wait/continuation package targets a different ROM revision.")
	var tail_entry: Dictionary = {}
	var preset_entry: Dictionary = {}
	for span_variant in wait_manifest.get("spans", []):
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		var source_file := String(span.get("file", ""))
		if source_file.ends_with("bank00_preset_copy_tail_893F_895C.bin"):
			tail_entry = span
		elif source_file.ends_with("bank06_preset_record_BF00_BF12.bin"):
			preset_entry = span
	if tail_entry.is_empty() \
			or String(tail_entry.get("cpu_start", "")) != "$893F" \
			or String(tail_entry.get("cpu_end_exclusive", "")) != "$895D" \
			or String(tail_entry.get("file_offset", "")) != "0x00094F" \
			or int(tail_entry.get("length", -1)) != 30 \
			or String(tail_entry.get("sha256", "")) != WAIT_TAIL_SOURCE_SHA256:
		return _fail("The `$893F-$895C` continuation span metadata differs from the audited ROM range.")
	_wait_tail_source = FileAccess.get_file_as_bytes(WAIT_TAIL_SOURCE_PATH)
	if _wait_tail_source.size() != 30 or _sha256(_wait_tail_source) != WAIT_TAIL_SOURCE_SHA256 \
			or String(tail_entry.get("bytes", "")).to_lower().replace(" ", "") != _wait_tail_source.hex_encode():
		return _fail("Packaged `$893F-$895C` continuation bytes failed exact hash/manifest checks.")
	if preset_entry.is_empty() \
			or String(preset_entry.get("cpu_start", "")) != "$BF00" \
			or String(preset_entry.get("cpu_end_exclusive", "")) != "$BF13" \
			or String(preset_entry.get("file_offset", "")) != "0x00DF10" \
			or int(preset_entry.get("length", -1)) != 19 \
			or String(preset_entry.get("sha256", "")) != PRESET_RECORD_SOURCE_SHA256:
		return _fail("The bank-$06 preset record metadata differs from the audited ROM range.")
	_preset_record_source = FileAccess.get_file_as_bytes(PRESET_RECORD_SOURCE_PATH)
	if _preset_record_source.size() != 19 or _sha256(_preset_record_source) != PRESET_RECORD_SOURCE_SHA256 \
			or String(preset_entry.get("bytes", "")).to_lower().replace(" ", "") != _preset_record_source.hex_encode():
		return _fail("Packaged bank-$06 preset record failed exact hash/manifest checks.")
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
	if String(normalizer_result.get("stack_model", "")) == "logical_source_jsr_frames":
		return _execute_from_logical_normalizer_return(normalizer_result)
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
		"stack_contract": {
			"model": "physical_stack_page",
			"sp_delta_from_8112_pre_call": -2,
			"sp_at_893b": int(mapper_registers.get("sp", -1)),
			"absolute_sp_known": true,
			"physical_stack_page_known": true,
			"pending_jsr_count": 1,
			"pending_frame": {
				"caller_pc": SETUP_CALLER_PC,
				"target_pc": SETUP_ENTRY_PC,
				"return_pc": SETUP_RETURN_PC,
				"return_word": SETUP_RETURN_PC - 1,
				"source_event_id": source_event_id,
			},
		},
		"cpu_cycles_without_interrupts_from_8112": cycles,
		"return_receipt": {},
		"live_mapper_updated": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


## Resumes the hash-checked mainline tail only after an independent ROM-source
## interrupt executor supplies a matching release receipt. This method consumes
## the receipt; it does not synthesize the NMI/IRQ, PPU, or MMC3 event.
func execute_after_wait_release(prefix_result: Dictionary, wait_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var checked := _validate_wait_release(prefix_result, wait_receipt)
	if not bool(checked.get("ok", false)):
		return _failure(String(checked.get("error", "Wait-release receipt is invalid.")))
	if _wait_tail_source != PackedByteArray(EXPECTED_WAIT_TAIL_BYTES):
		return _failure("The continuation instructions differ from the checked `$893F-$895C` bytes.")
	var source_event_id := String(prefix_result["source_event_id"])
	var release_event_id := String(wait_receipt["source_event_id"])
	var registers: Dictionary = prefix_result["boundary_registers"].duplicate(true)
	var ram_after: Dictionary = prefix_result["caller_ram_after"].duplicate(true)
	var pending_frames: Array[Dictionary] = []
	for frame_variant in prefix_result.get("logical_stack_frames", []):
		pending_frames.append(frame_variant.duplicate(true))
	var source_path: Array[int] = []
	var writes: Array[Dictionary] = []
	var cycles := int(prefix_result.get("cpu_cycles_without_interrupts_from_8112", -1))
	if cycles < 0:
		return _failure("The prefix's ROM-source cycle count is invalid.")

	# IRQ owns the $78 write. The final LDA/BNE iteration sees zero and falls
	# through to the copy routine; it never seeds an unowned latch here.
	var release_write: Dictionary = checked["release_write"]
	ram_after[0x0078] = 0
	writes.append({"source_pc": 0xA1C3, "address": 0x0078,
		"old": 4, "value": 0, "producer_event_id": release_event_id})
	registers["pc"] = 0x893F
	registers["a"] = 0
	_set_nz_contract(registers, 0)
	source_path.append_array([0x893B, 0x893D, 0x893F])
	cycles += 5 # Final LDA $78 plus not-taken BNE.
	if int(release_write.get("before", -1)) != 4 or int(release_write.get("value", -1)) != 0:
		return _failure("The ROM IRQ receipt did not release the expected `$78=4` wait.")
	if int(ram_after.get(0x00EC, -1)) != 0 \
			or int(ram_after.get(0x00ED, -1)) != 0xBF \
			or int(ram_after.get(0x00EA, -1)) != BANK2 \
			or int(ram_after.get(0x0025, -1)) != PRESET_BANK:
		return _failure("The `$893F` entry lost the ROM-derived `$BF00` pointer or saved bank.")
	if _preset_record_source.size() != 19:
		return _failure("The checked bank-$06 preset record is unavailable.")

	# $893F LDY #0; $8941 LDA ($EC),Y; $8943 STA $79.
	registers["y"] = 0
	_set_nz_contract(registers, 0)
	source_path.append_array([0x8941, 0x8943])
	cycles += 2 + 5 + 4
	var first_value := int(_preset_record_source[0])
	ram_after[0x0079] = first_value
	registers["a"] = first_value
	_set_nz_contract(registers, first_value)
	writes.append({"source_pc": 0x8943, "address": 0x0079, "value": first_value})

	# $8946 LDA #0 / $8948 STA $7A; $894B INY / $894C LDX #$12.
	registers["a"] = 0
	_set_nz_contract(registers, 0)
	ram_after[0x007A] = 0
	writes.append({"source_pc": 0x8948, "address": 0x007A, "value": 0})
	registers["y"] = 1
	_set_nz_contract(registers, 1)
	registers["x"] = 0x12
	_set_nz_contract(registers, 0x12)
	source_path.append_array([0x8946, 0x8948, 0x894B, 0x894C])
	cycles += 2 + 4 + 2 + 2

	# $894E-$8955 copies BF01..BF12 into $7C..$8D. Y addresses the
	# destination; X counts down. The source's $7B byte remains untouched.
	for record_index in range(1, 19):
		var destination_address := 0x007B + record_index
		var value := int(_preset_record_source[record_index])
		registers["a"] = value
		_set_nz_contract(registers, value)
		ram_after[destination_address] = value
		writes.append({"source_pc": 0x8950, "address": destination_address,
			"value": value, "record_index": record_index})
		registers["y"] = record_index + 1
		_set_nz_contract(registers, int(registers["y"]))
		registers["x"] = 0x12 - record_index
		_set_nz_contract(registers, int(registers["x"]))
		source_path.append_array([0x894E, 0x8950, 0x8953, 0x8954, 0x8955])
		cycles += 5 + 5 + 2 + 2 + (3 if record_index < 18 else 2)

	# Restore the caller's saved bank with the checked $8959->$C4B9 JSR.
	registers["x"] = int(ram_after[0x00EA])
	_set_nz_contract(registers, int(registers["x"]))
	var mapper_event_id := release_event_id + ":8959-C4B9"
	var mapper_frame := {"kind": "rom_jsr", "caller_pc": 0x8959,
		"target_pc": 0xC4B9, "return_pc": 0x895C,
		"return_word": 0x895B, "source_event_id": mapper_event_id}
	var mapper_call := {"caller_pc": 0x8959, "target_pc": 0xC4B9,
		"return_pc": 0x895C, "source_event_id": mapper_event_id,
		"logical_stack_frame": mapper_frame}
	registers["pc"] = 0xC4B9
	pending_frames.append(mapper_frame)
	var mapper_result: Dictionary = _mapper_helper.execute_logical_source_call(
		mapper_call, registers, ram_after)
	if not bool(mapper_result.get("ok", false)):
		return _failure("The `$8959->$C4B9` bank restore failed: " + String(mapper_result.get("error", "unknown error")))
	var mapper_registers: Dictionary = mapper_result.get("return_registers", {}).duplicate(true)
	var mapper_ram: Dictionary = mapper_result.get("ram_after", {}).duplicate(true)
	var bus_writes: Array = mapper_result.get("mapper_bus_writes", [])
	var expected_select := BANK_SELECT_REGISTER_ID | int(mapper_ram.get(0x0022, 0))
	if int(mapper_registers.get("pc", -1)) != 0x895C \
			or int(mapper_registers.get("x", -1)) != BANK2 \
			or int(mapper_ram.get(0x0025, -1)) != BANK2 \
			or int(mapper_ram.get(0x0023, -1)) != expected_select \
			or not _mapper_selected_bank_value(bus_writes, expected_select, BANK2):
		return _failure("The ROM mapper helper did not restore the saved bank `$02`.")
	cycles += 3 + 6 + int(mapper_result.get("cpu_cycles", -1))
	source_path.append_array([0x8957, 0x8959, 0xC4B9, 0xC4BB, 0xC4BD,
		0xC4BF, 0xC4C1, 0xC4C4, 0xC4C7, 0x895C])
	var mapper_return := _pop_logical_rts(pending_frames)
	if int(mapper_return.get("return_pc", -1)) != 0x895C:
		return _failure("The `$C4B9 RTS` did not return to `$895C`.")
	var outer_return := _pop_logical_rts(pending_frames)
	if int(outer_return.get("return_pc", -1)) != SETUP_RETURN_PC or not pending_frames.is_empty():
		return _failure("The `$895C RTS` did not return through the `$8114` caller frame.")
	mapper_registers["pc"] = SETUP_RETURN_PC
	cycles += 6
	source_path.append(SETUP_RETURN_PC)
	writes.append_array(mapper_result.get("ram_writes", []))
	return {"ok": true, "status": "returned_to_fresh_match_caller",
		"source_event_id": source_event_id, "wait_release_event_id": release_event_id,
		"source_rom_sha256": ROM_SHA256, "source_path": source_path,
		"entry_wait_boundary": PRESET_WAIT_PC, "final_source_pc": SETUP_RETURN_PC,
		"cpu_cycles_excluding_wait_and_interrupts_from_8112": cycles,
		"source_return_receipt": {"caller_pc": SETUP_CALLER_PC,
			"target_pc": SETUP_ENTRY_PC, "return_pc": SETUP_RETURN_PC,
			"rts_pc": 0x895C, "status": "returned",
			"stack_model": "logical_source_jsr_frames", "source_event_id": source_event_id},
		"boundary_registers": mapper_registers, "caller_ram_writes": writes,
		"caller_ram_after": mapper_ram, "mapper_bus_writes": bus_writes,
		"stack_after": pending_frames, "stack_model": "logical_source_jsr_frames",
		"live_mapper_updated": false, "trace_state_used": false,
		"emulator_data_used": false}


func _validate_wait_release(prefix_result: Dictionary, receipt: Dictionary) -> Dictionary:
	if not bool(prefix_result.get("ok", false)) \
			or String(prefix_result.get("status", "")) != "stopped_at_unresolved_source_predicate" \
			or String(prefix_result.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "A successful `$893B` prefix for the supplied ROM is required."}
	if bool(prefix_result.get("trace_state_used", true)) or bool(prefix_result.get("emulator_data_used", true)):
		return {"ok": false, "error": "The source prefix must be independent of trace/emulator state."}
	if String(prefix_result.get("stack_model", "")) != "logical_source_jsr_frames":
		return {"ok": false, "error": "The pending source caller must use explicit logical JSR frames."}
	var source_event_id := String(prefix_result.get("source_event_id", "")).strip_edges()
	if source_event_id.is_empty():
		return {"ok": false, "error": "The prefix's source event identity is missing."}
	var boundary: Dictionary = prefix_result.get("boundary", {})
	var registers: Dictionary = prefix_result.get("boundary_registers", {})
	if int(boundary.get("pc", -1)) != PRESET_WAIT_PC \
			or int(registers.get("pc", -1)) != PRESET_WAIT_PC \
			or String(boundary.get("operation", "")) != "LDA $78; BNE $893B":
		return {"ok": false, "error": "The prefix is not stopped at the audited `$893B` wait predicate."}
	var expected_outer_id := source_event_id + ":8114-8920"
	var frames: Array = prefix_result.get("logical_stack_frames", [])
	if frames.size() != 1:
		return {"ok": false, "error": "Exactly one pending `$8114->$8920` source frame is required."}
	var outer_frame: Dictionary = frames[0]
	if String(outer_frame.get("kind", "")) != "rom_jsr" \
			or int(outer_frame.get("caller_pc", -1)) != SETUP_CALLER_PC \
			or int(outer_frame.get("target_pc", -1)) != SETUP_ENTRY_PC \
			or int(outer_frame.get("return_pc", -1)) != SETUP_RETURN_PC \
			or int(outer_frame.get("return_word", -1)) != SETUP_CALLER_PC + 2 \
			or String(outer_frame.get("source_event_id", "")) != expected_outer_id:
		return {"ok": false, "error": "The outstanding `$8114` logical return frame differs from the ROM caller."}
	var prefix_mask := int(registers.get("p_known_mask", 0))
	var prefix_flags := int(registers.get("p_known_value", 0))
	if (prefix_mask & 0x04) == 0 or (prefix_flags & 0x04) != 0:
		return {"ok": false, "error": "The source prefix must carry forward a known clear I flag."}
	var prefix_ram: Dictionary = prefix_result.get("caller_ram_after", {})
	if int(prefix_ram.get(0x0025, -1)) != PRESET_BANK \
			or int(prefix_ram.get(0x00EA, -1)) != BANK2:
		return {"ok": false, "error": "The `$893B` caller RAM lost the preset bank or saved bank state."}

	if not bool(receipt.get("ok", false)) \
			or String(receipt.get("kind", "")) != "rom_irq_wait_release" \
			or String(receipt.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "A successful ROM-source IRQ wait-release receipt for this ROM is required."}
	if bool(receipt.get("trace_state_used", true)) or bool(receipt.get("emulator_data_used", true)):
		return {"ok": false, "error": "FCEUX trace, save-state, screenshot, or emulator state cannot release the runtime wait."}
	var release_event_id := String(receipt.get("source_event_id", "")).strip_edges()
	if release_event_id.is_empty() or not release_event_id.begins_with(source_event_id + ":893B"):
		return {"ok": false, "error": "The IRQ receipt must descend from this route's `$893B` source event."}
	if String(receipt.get("interrupt", "")) != "IRQ" \
			or int(receipt.get("wait_pc", -1)) != PRESET_WAIT_PC \
			or int(receipt.get("return_pc", -1)) != PRESET_WAIT_PC \
			or not bool(receipt.get("interrupt_stack_balanced", false)):
		return {"ok": false, "error": "The IRQ must return to `$893B` with its interrupt stack balanced."}
	var required_path: Array[int] = [0xC506, 0xC821, 0xC478, 0xC491, 0xA160, 0xA1C3, 0xC4AD]
	if not _contains_path_in_order(receipt.get("source_path", []), required_path):
		return {"ok": false, "error": "The ROM IRQ receipt omits the checked vector/wrapper/release/RTI path."}
	var wait_ram: Dictionary = receipt.get("ram_at_wait", {})
	if int(wait_ram.get(0x001B, -1)) != 0xC0 \
			or int(wait_ram.get(0x0078, -1)) != 4 \
			or int(wait_ram.get(0x0079, -1)) != 0x40 \
			or int(wait_ram.get(0x003B, -1)) != 0x55:
		return {"ok": false, "error": "The ROM IRQ receipt lacks the source-derived `$893B` RAM precondition."}
	var release_writes: Array = []
	for write_variant in receipt.get("ram_writes", []):
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("source_pc", -1)) == 0xA1C3 \
				and int(write.get("address", -1)) == 0x0078:
			release_writes.append(write)
	if release_writes.size() != 1:
		return {"ok": false, "error": "Exactly one ROM-owned `$A1C3` write must release `$78`."}
	var release_write: Dictionary = release_writes[0]
	if int(release_write.get("before", -1)) != 4 or int(release_write.get("value", -1)) != 0:
		return {"ok": false, "error": "The `$A1C3` receipt does not show `$78:4->$00`."}
	if String(release_write.get("source_event_id", "")) != release_event_id:
		return {"ok": false, "error": "The `$A1C3` RAM write is not bound to the supplied IRQ event identity."}
	var irq_return: Dictionary = receipt.get("return_registers", {})
	if int(irq_return.get("pc", -1)) != PRESET_WAIT_PC:
		return {"ok": false, "error": "The IRQ return register receipt does not resume at `$893B`."}
	for register_name: String in ["a", "x", "y"]:
		if int(irq_return.get(register_name, -1)) != int(registers.get(register_name, -2)):
			return {"ok": false, "error": "IRQ return register `%s` does not restore the interrupted caller." % register_name}
	var irq_mask := int(irq_return.get("p_known_mask", 0))
	var irq_flags := int(irq_return.get("p_known_value", 0))
	if (irq_mask & prefix_mask) != prefix_mask \
			or ((irq_flags ^ prefix_flags) & prefix_mask) != 0 \
			or (irq_mask & 0x04) == 0 or (irq_flags & 0x04) != 0:
		return {"ok": false, "error": "IRQ RTI did not restore the source-known processor status contract."}
	return {"ok": true, "release_write": release_write,
		"release_event_id": release_event_id}


func _contains_path_in_order(actual_variant: Variant, required: Array[int]) -> bool:
	if not actual_variant is Array:
		return false
	var actual: Array = actual_variant
	var expected_index := 0
	for pc_variant in actual:
		if int(pc_variant) == required[expected_index]:
			expected_index += 1
			if expected_index == required.size():
				return true
	return false


func _pop_logical_rts(frames: Array[Dictionary]) -> Dictionary:
	if frames.is_empty():
		return {}
	var frame: Dictionary = frames.pop_back()
	return {"return_pc": int(frame.get("return_pc", -1)),
		"source_event_id": String(frame.get("source_event_id", ""))}


## Executes the same ROM-owned prefix with symbolic JSR frames. The `$8114`
## Executes the same ROM-owned prefix with symbolic JSR frames. The `$8114`
## outer frame remains pending at `$893B`; no absolute SP or stack-page byte
## is inferred. The unknown `$78` predicate is not read.
func _execute_from_logical_normalizer_return(normalizer_result: Dictionary) -> Dictionary:
	var checked := _validate_logical_normalizer_result(normalizer_result)
	if not bool(checked.get("ok", false)):
		return _failure(String(checked.get("error", "Logical normalizer result is invalid.")))
	var source_event_id := String(checked["source_event_id"])
	var registers: Dictionary = checked["registers"].duplicate(true)
	var ram_after: Dictionary = checked["ram_after"].duplicate(true)
	var writes: Array[Dictionary] = []
	var source_path: Array[int] = []
	var cycles := 0

	# Caller $8112 LDA #$00 / $8114 JSR $8920.
	registers["pc"] = CALLER_ENTRY_PC
	registers["a"] = 0
	_set_nz_contract(registers, 0)
	cycles += 2
	var outer_event_id := source_event_id + ":8114-8920"
	var outer_frame := {
		"kind": "rom_jsr", "caller_pc": SETUP_CALLER_PC,
		"target_pc": SETUP_ENTRY_PC, "return_pc": SETUP_RETURN_PC,
		"return_word": SETUP_CALLER_PC + 2,
		"source_event_id": outer_event_id,
	}
	registers["pc"] = SETUP_ENTRY_PC
	cycles += 6
	source_path.append_array([CALLER_ENTRY_PC, SETUP_CALLER_PC, SETUP_ENTRY_PC])

	# $8920 LDX #$13 / JSR $9DEE. The multiplication helper's source loop is
	# ROM-hash checked above and runs with the caller-derived A=0.
	registers["x"] = 0x13
	_set_nz_contract(registers, 0x13)
	registers["pc"] = MULTIPLY_ENTRY_PC
	cycles += 2
	var multiply_event_id := outer_event_id + ":8922-9DEE"
	var multiply_frame := {
		"kind": "rom_jsr", "caller_pc": 0x8922,
		"target_pc": MULTIPLY_ENTRY_PC, "return_pc": MULTIPLY_RETURN_PC,
		"return_word": MULTIPLY_CALLER_PC + 2,
		"source_event_id": multiply_event_id,
	}
	var multiply_result := _execute_logical_multiply_helper(multiply_frame, registers, ram_after)
	if not bool(multiply_result.get("ok", false)):
		return _failure(String(multiply_result.get("error", "Logical `$9DEE` execution failed.")))
	registers = multiply_result["return_registers"].duplicate(true)
	ram_after = multiply_result["ram_after"].duplicate(true)
	writes.append_array(multiply_result.get("ram_writes", []))
	cycles += 6 + int(multiply_result.get("cpu_cycles", -1))
	source_path.append_array(multiply_result.get("source_path", []))

	if int(registers.get("pc", -1)) != MULTIPLY_RETURN_PC \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("x", -1)) != 0x13 \
			or int(registers.get("y", -1)) != 0:
		return _failure("The logical `$9DEE` return differs from the fresh zero-index source path.")
	var arithmetic_registers := registers.duplicate(true)
	# The pointer routine begins with LDA/CLC and then defines N/Z/C/V. Its
	# arithmetic depends only on known C; unknown status bits are excluded.
	var arithmetic_known_mask := int(registers.get("p_known_mask", 0)) | 0xC3
	arithmetic_registers["p"] = int(registers.get("p_known_value", 0)) & int(registers.get("p_known_mask", 0))
	var arithmetic := _execute_preset_pointer_arithmetic(arithmetic_registers, ram_after)
	if not arithmetic.has("registers"):
		return _failure(String(arithmetic.get("error", "Preset pointer arithmetic failed.")))
	registers = arithmetic["registers"].duplicate(true)
	registers["p_known_mask"] = arithmetic_known_mask
	registers["p_known_value"] = int(registers.get("p", 0)) & arithmetic_known_mask
	registers.erase("p")
	ram_after = arithmetic["ram_after"].duplicate(true)
	writes.append_array(arithmetic.get("ram_writes", []))
	cycles += int(arithmetic.get("cpu_cycles", -1))
	source_path.append_array(arithmetic.get("source_path", []))
	if int(registers.get("a", -1)) != BANK2 \
			or int(registers.get("x", -1)) != PRESET_BANK \
			or int(registers.get("y", -1)) != 0 \
			or int(ram_after.get(0x00EC, -1)) != 0 \
			or int(ram_after.get(0x00ED, -1)) != 0xBF \
			or int(ram_after.get(0x00EA, -1)) != BANK2:
		return _failure("Fresh `$8920` logical source arithmetic did not yield BF00 and prior bank `$02`.")

	# `$8938 JSR $C4B9` selects preset bank `$06`; this nested call returns at
	# `$893B`, leaving only the outer `$8114` frame outstanding.
	var mapper_event_id := outer_event_id + ":8938-C4B9"
	var mapper_call := {
		"caller_pc": MAPPER_CALLER_PC, "target_pc": 0xC4B9,
		"return_pc": MAPPER_RETURN_PC, "source_event_id": mapper_event_id,
		"logical_stack_frame": {
			"kind": "rom_jsr", "caller_pc": MAPPER_CALLER_PC,
			"target_pc": 0xC4B9, "return_pc": MAPPER_RETURN_PC,
			"return_word": MAPPER_CALLER_PC + 2,
			"source_event_id": mapper_event_id,
		},
	}
	var mapper_cpu := registers.duplicate(true)
	mapper_cpu["pc"] = 0xC4B9
	var mapper_result: Dictionary = _mapper_helper.execute_logical_source_call(mapper_call, mapper_cpu, ram_after)
	if not bool(mapper_result.get("ok", false)):
		return _failure("The `$8938->$C4B9` logical source call did not return: " + String(mapper_result.get("error", "unknown error")))
	var mapper_registers: Dictionary = mapper_result.get("return_registers", {}).duplicate(true)
	var mapper_ram: Dictionary = mapper_result.get("ram_after", {}).duplicate(true)
	var mapper_writes: Array = mapper_result.get("mapper_bus_writes", [])
	var expected_select: int = BANK_SELECT_REGISTER_ID | int(mapper_ram.get(0x0022, -1))
	if not _mapper_selected_value(mapper_writes, expected_select) \
			or int(mapper_ram.get(0x0025, -1)) != PRESET_BANK \
			or int(mapper_registers.get("pc", -1)) != MAPPER_RETURN_PC \
			or int(mapper_registers.get("a", -1)) != expected_select \
			or int(mapper_registers.get("x", -1)) != PRESET_BANK \
			or int(mapper_registers.get("y", -1)) != 0 \
			or (int(mapper_registers.get("p_known_mask", -1)) & 0xC3) != 0xC3 \
			or (int(mapper_registers.get("p_known_value", -1)) & 0xC3) != 0:
		return _failure("The `$8938` mapper helper did not return at `$893B` with bank `$06` and a known partial P contract.")
	cycles += 6 + int(mapper_result.get("cpu_cycles", -1))
	source_path.append_array([MAPPER_CALLER_PC, 0xC4B9, 0xC4BB, 0xC4BD,
		0xC4BF, 0xC4C1, 0xC4C4, 0xC4C7, PRESET_WAIT_PC])
	writes.append_array(mapper_result.get("ram_writes", []))

	var pending_frames: Array[Dictionary] = [outer_frame.duplicate(true)]
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
				"return_pc": MULTIPLY_RETURN_PC, "rts_pc": 0x9E0B,
				"stack_model": "logical_source_jsr_frames"},
			mapper_result["source_return_receipt"],
		],
		"boundary": {
			"pc": PRESET_WAIT_PC,
			"next_opcode_bytes": [0xA5, 0x78, 0xD0, 0xFC],
			"operation": "LDA $78; BNE $893B",
			"required_ram_address": 0x0078,
			"required_value_source": "source-owned NMI/IRQ or scheduler event not present in the verified normalizer return",
			"zero_successor_pc": 0x893F,
			"nonzero_successor_pc": PRESET_WAIT_PC,
		},
		"entry_registers": checked["registers"],
		"boundary_registers": mapper_registers,
		"caller_ram_after": mapper_ram,
		"caller_ram_writes": writes,
		"mapper_bus_writes": mapper_writes,
		"stack_after": pending_frames,
		"logical_stack_frames": pending_frames,
		"stack_model": "logical_source_jsr_frames",
		"stack_contract": {
			"model": "logical_source_jsr_frames",
			"sp_delta_from_8112_pre_call": -2,
			"absolute_sp_known": false,
			"physical_stack_page_known": false,
			"pending_jsr_count": pending_frames.size(),
			"pending_frame": pending_frames[0].duplicate(true),
		},
		"cpu_cycles_without_interrupts_from_8112": cycles,
		"return_receipt": {},
		"live_mapper_updated": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _validate_logical_normalizer_result(result: Dictionary) -> Dictionary:
	if not bool(result.get("ok", false)) \
			or String(result.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "A successful logical return for the supplied ROM is required from the A20C normalizer."}
	if bool(result.get("trace_state_used", true)) or bool(result.get("emulator_data_used", true)):
		return {"ok": false, "error": "The normalizer result must not depend on emulator or trace state."}
	if String(result.get("stack_model", "")) != "logical_source_jsr_frames":
		return {"ok": false, "error": "The logical source-stack model must be explicit."}
	var receipt: Dictionary = result.get("normalize_source_return_receipt", {})
	if int(receipt.get("caller_pc", -1)) != 0x810F \
			or int(receipt.get("target_pc", -1)) != 0xA20C \
			or int(receipt.get("return_pc", -1)) != CALLER_ENTRY_PC \
			or int(receipt.get("rts_pc", -1)) != 0xA8B6 \
			or String(receipt.get("stack_model", "")) != "logical_source_jsr_frame":
		return {"ok": false, "error": "A logical `$810F->$A20C->$8112` return receipt is required."}
	var source_event_id := String(result.get("source_event_id", "")).strip_edges()
	if source_event_id.is_empty() \
			or String(receipt.get("source_event_id", "")) != source_event_id + ":810F-A20C":
		return {"ok": false, "error": "The original source event identity must continue through the logical return receipt."}
	var hashes: Dictionary = result.get("source_span_hashes", {})
	if String(hashes.get("title_caller", "")) != CALLER_SHA256:
		return {"ok": false, "error": "The normalizer omitted the hash-checked `$80DF-$815C` caller."}
	var registers: Dictionary = result.get("return_registers", {})
	var p_mask := int(registers.get("p_known_mask", -1))
	var p_value := int(registers.get("p_known_value", -1))
	if int(registers.get("pc", -1)) != CALLER_ENTRY_PC \
			or int(registers.get("a", -1)) != 3 \
			or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 0x84 \
			or (p_mask & 0xC3) != 0xC3 \
			or p_value < 0 or p_value > 0xFF:
		return {"ok": false, "error": "The `$8112` caller CPU return/partial-P contract is invalid."}
	var ram: Dictionary = result.get("caller_ram_after", {})
	for address: int in [0x0022, 0x0023, 0x0025, 0x0026, 0x002A, 0x002B]:
		if not ram.has(address):
			return {"ok": false, "error": "Normalizer RAM is missing `$%04X`." % address}
	var expected_select: int = BANK_SELECT_REGISTER_ID | int(ram[0x0022])
	if int(ram[0x0023]) != expected_select \
			or int(ram[0x0025]) != BANK2 \
			or int(ram[0x0026]) != 0 \
			or int(ram[0x002A]) != 0 \
			or int(ram[0x002B]) != 3:
		return {"ok": false, "error": "Normalizer RAM does not satisfy the ROM-derived fresh match-zero contract."}
	if ram.has(0x0078):
		return {"ok": false, "error": "Incoming `$0078` has no source provenance; refusing an unowned wait state."}
	var stack: Variant = result.get("stack_after")
	if not stack is Array or not stack.is_empty():
		return {"ok": false, "error": "The prior logical JSR frame must be balanced at `$8112`."}
	return {"ok": true, "source_event_id": source_event_id,
		"registers": registers, "ram_after": ram, "stack_after": stack}


func _execute_logical_multiply_helper(frame: Dictionary, registers_in: Dictionary,
		ram_in: Dictionary) -> Dictionary:
	var source_event_id := String(frame.get("source_event_id", ""))
	if String(frame.get("kind", "")) != "rom_jsr" \
			or int(frame.get("caller_pc", -1)) != 0x8922 \
			or int(frame.get("target_pc", -1)) != MULTIPLY_ENTRY_PC \
			or int(frame.get("return_pc", -1)) != MULTIPLY_RETURN_PC \
			or int(frame.get("return_word", -1)) != 0x8924 \
			or source_event_id.is_empty():
		return {"ok": false, "error": "The logical `$8922->$9DEE->$8925` frame differs from ROM caller bytes."}
	if int(registers_in.get("pc", -1)) != MULTIPLY_ENTRY_PC \
			or int(registers_in.get("a", -1)) != 0 \
			or int(registers_in.get("x", -1)) != 0x13 \
			or (int(registers_in.get("p_known_mask", 0)) & 0x82) != 0x82:
		return {"ok": false, "error": "The `$9DEE` source input requires A=0, X=$13 and known N/Z flags."}
	var registers := registers_in.duplicate(true)
	var ram_after := ram_in.duplicate(true)
	var writes: Array[Dictionary] = []
	var path: Array[int] = [MULTIPLY_ENTRY_PC, 0x9DF0, 0x9DF2, 0x9DF4]
	ram_after[0x00ED] = 0
	writes.append({"source_pc": 0x9DEE, "address": 0x00ED, "value": 0})
	registers["a"] = 0
	_set_nz_contract(registers, 0)
	ram_after[0x00EC] = 0
	writes.append({"source_pc": 0x9DF2, "address": 0x00EC, "value": 0})
	registers["y"] = 8
	_set_nz_contract(registers, 8)
	var cycles := 3 + 2 + 3 + 2
	for iteration in range(8):
		path.append_array([0x9DF6, 0x9DF8, 0x9DFA, 0x9E08, 0x9E09])
		var ec := int(ram_after[0x00EC])
		var ed := int(ram_after[0x00ED])
		var asl_carry := (ec & 0x80) != 0
		ec = (ec << 1) & 0xFF
		ram_after[0x00EC] = ec
		writes.append({"source_pc": 0x9DF6, "address": 0x00EC, "value": ec})
		_set_c_contract(registers, asl_carry)
		_set_nz_contract(registers, ec)
		var rol_carry := (ed & 0x80) != 0
		ed = ((ed << 1) | (1 if asl_carry else 0)) & 0xFF
		ram_after[0x00ED] = ed
		writes.append({"source_pc": 0x9DF8, "address": 0x00ED, "value": ed})
		_set_c_contract(registers, rol_carry)
		_set_nz_contract(registers, ed)
		if rol_carry:
			return {"ok": false, "error": "The `$9DEE` BCC branch became unresolved; only fresh zero-input is supported."}
		cycles += 5 + 5 + 3
		registers["y"] = (int(registers["y"]) - 1) & 0xFF
		_set_nz_contract(registers, int(registers["y"]))
		cycles += 2 + (3 if iteration < 7 else 2)
	if int(registers["y"]) != 0:
		return {"ok": false, "error": "The `$9DEE` source loop did not finish after eight decrements."}
	registers["pc"] = MULTIPLY_RETURN_PC
	cycles += 6
	return {"ok": true, "return_registers": registers,
		"ram_after": ram_after, "ram_writes": writes,
		"source_path": path, "cpu_cycles": cycles,
		"source_return_receipt": {"caller_pc": 0x8922,
			"target_pc": MULTIPLY_ENTRY_PC, "return_pc": MULTIPLY_RETURN_PC,
			"rts_pc": 0x9E0B, "source_event_id": source_event_id,
			"stack_model": "logical_source_jsr_frame", "status": "returned"}}


func _set_nz_contract(registers: Dictionary, value: int) -> void:
	var mask := int(registers.get("p_known_mask", 0)) | 0x82
	var flags := int(registers.get("p_known_value", 0)) & mask & 0x7D
	if (value & 0x80) != 0:
		flags |= 0x80
	if (value & 0xFF) == 0:
		flags |= 0x02
	registers["p_known_mask"] = mask
	registers["p_known_value"] = flags & mask


func _set_c_contract(registers: Dictionary, set_flag: bool) -> void:
	var mask := int(registers.get("p_known_mask", 0)) | 0x01
	var flags := int(registers.get("p_known_value", 0)) & mask
	flags = (flags | 0x01) if set_flag else (flags & 0xFE)
	registers["p_known_mask"] = mask
	registers["p_known_value"] = flags & mask


func _mapper_selected_value(bus_writes: Array, expected_value: int) -> bool:
	var select_seen := false
	var data_seen := false
	for write_variant in bus_writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x8000 and int(write.get("value", -1)) == expected_value:
			select_seen = true
		if select_seen and int(write.get("address", -1)) == 0x8001 \
				and int(write.get("value", -1)) == PRESET_BANK:
			data_seen = true
	return select_seen and data_seen


func _mapper_selected_bank_value(bus_writes: Array, expected_select: int, expected_bank: int) -> bool:
	var select_seen := false
	var data_seen := false
	for write_variant in bus_writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x8000 \
				and int(write.get("value", -1)) == expected_select:
			select_seen = true
		if select_seen and int(write.get("address", -1)) == 0x8001 \
				and int(write.get("value", -1)) == expected_bank:
			data_seen = true
	return select_seen and data_seen

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
