extends RefCounted
class_name RomFreshMatchSelectorExecutor
## Executes the supplied ROM's fresh-match-index-zero selector through both
## real RTS instructions. The caller event, entry registers, RAM, and stack
## remain explicit inputs; no trace state or elapsed-frame guess is accepted.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_match_selector/"
const MANIFEST_PATH := ROOT + "manifest.json"
const SOURCE_EXPECTATIONS := {
	"title_caller": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_caller/bank00_title_to_first_match_setup_80DF_815C.bin",
		"cpu_start": "$80DF", "cpu_end_exclusive": "$815D", "file_offset": "0x0000EF",
		"length": 126, "sha256": "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b",
	},
	"selector_trampoline": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_entry_context/match_selector_trampoline_A20F.bin",
		"cpu_start": "$A20F", "cpu_end_exclusive": "$A212", "file_offset": "0x00421F",
		"length": 3, "sha256": "51244f9af68e818db390d67b69d822597a021d99bb35339132f4ce2dfde5430d",
	},
	"selector_code": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_entry_context/match_selector_A86E_A8CD.bin",
		"cpu_start": "$A86E", "cpu_end_exclusive": "$A8CE", "file_offset": "0x00487E",
		"length": 96, "sha256": "f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123",
	},
	"home_roster_match_00": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_position_context/bank_02_match_00_home_roster_AA47.bin",
		"cpu_start": "$AA47", "cpu_end_exclusive": "$AA53", "file_offset": "0x004A57",
		"length": 12, "sha256": "dcb5f0103eaecbc9785e947085b02cd6b56f7d31e6671a699d82b22d80a3b123",
	},
	"home_team_match_table": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_position_context/bank_02_match_00_home_team_id_AA75.bin",
		"cpu_start": "$AA75", "cpu_end_exclusive": "$AA76", "file_offset": "0x004A85",
		"length": 1, "sha256": "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
	},
	"selector_copy_scan_code": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_copy_scan_code_A138_A15D.bin",
		"cpu_start": "$A138", "cpu_end_exclusive": "$A15E", "file_offset": "0x004148",
		"length": 38, "sha256": "b804ba6ac3153232ebaaee331380502f3b117a140a56d5f6d16d0c0fe15ca558",
	},
	"selector_copy_finish_code": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_copy_finish_code_A1E4_A1EA.bin",
		"cpu_start": "$A1E4", "cpu_end_exclusive": "$A1EB", "file_offset": "0x0041F4",
		"length": 7, "sha256": "1716d9bfa1de42ac3cf63f561a3d19e7702b16caf606337c984f6f94f0effc6f",
	},
	"selector_copy_increment_code": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_copy_increment_code_A1EB_A1F9.bin",
		"cpu_start": "$A1EB", "cpu_end_exclusive": "$A1FA", "file_offset": "0x0041FB",
		"length": 15, "sha256": "73b6baf63eff25c7e38d9c496e2d925fab95a3f2001945fb37fbcc9708cb1f02",
	},
	"selector_copy_source": {
		"path": "reference/rom_extract/gameplay/fresh_kickoff_match_selector/selector_prg_ram_copy_source_ACB0_BFFF.bin",
		"cpu_start": "$ACB0", "cpu_end_exclusive": "$C000", "file_offset": "0x004CC0",
		"length": 0x1350, "sha256": "e1288622a02fa918c7793d7e3d6415c6edd94929d020fa7e56187c9d0d764415",
	},
}

const CALLER_PC := 0x80FA
const RETURN_PC := 0x80FD
const SELECTOR_ENTRY_PC := 0xA20F
const SELECTOR_BODY_PC := 0xA86E
const ROSTER_COPY_TRAMPOLINE_PC := 0xA8B7
const ROSTER_COPY_PC := 0xA8BB
const SOURCE_COPY_START := 0xACB0
const SOURCE_COPY_END_EXCLUSIVE := 0xC000
const PRG_RAM_COPY_DESTINATION := 0x6000
const FRESH_MATCH_INDEX := 0

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _copy_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	_copy_source = PackedByteArray()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Fresh match-selector source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh match-selector source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-match-selector-executable-v1":
		return _fail("Fresh match-selector source manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Match-selector manifest targets a different ROM revision.")
	var entries: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			entries[String(span.get("id", ""))] = span
	for span_id: String in SOURCE_EXPECTATIONS:
		var expected: Dictionary = SOURCE_EXPECTATIONS[span_id]
		if not entries.has(span_id):
			return _fail("Match-selector manifest omits `%s`." % span_id)
		var entry: Dictionary = entries[span_id]
		for field: String in ["path", "cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(field, -1)) == int(expected[field]) \
					if field == "length" else String(entry.get(field, "")) == String(expected[field])
			if not matches:
				return _fail("Selector manifest metadata differs for `%s` (%s)." % [span_id, field])
		var bytes := FileAccess.get_file_as_bytes("res://" + String(expected["path"]))
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]):
			return _fail("ROM source span `%s` failed its size/hash check." % span_id)
		if String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Manifest byte listing differs from source span `%s`." % span_id)
		_sources[span_id] = bytes
	_copy_source = _sources["selector_copy_source"]
	if not _verify_instruction_spans():
		return false
	_configured = true
	return true


## `source_call` identifies the actual `$80FA` JSR and includes the caller's
## post-JSR stack page/SP. `cpu_state` is the exact `$A20F` entry state after
## the preceding ROM `$C4B9` call. `ram_before` must include `$22/$23/$25/$26`.
## The only supported path is fresh `$26=0`, with `$Y=0` required by the
## `$A138` indirect-indexed ROM-to-PRG-RAM copy.
func execute_source_call(source_call: Dictionary, cpu_state: Dictionary,
		ram_before: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if int(source_call.get("caller_pc", -1)) != CALLER_PC \
			or int(source_call.get("target_pc", -1)) != SELECTOR_ENTRY_PC \
			or int(source_call.get("return_pc", -1)) != RETURN_PC:
		return _failure("The call must be the source-verified `$80FA JSR $A20F` continuation at `$80FD`.")
	var source_event_id := String(source_call.get("source_event_id", "")).strip_edges()
	if source_event_id.is_empty():
		return _failure("A source-owned caller event identity is required; this executor does not create call events.")
	var pre_call_sp := int(source_call.get("pre_call_sp", -1))
	if pre_call_sp < 0 or pre_call_sp > 0xFF:
		return _failure("Caller must supply its byte-valued pre-JSR stack pointer.")
	var entry_sp := (pre_call_sp - 2) & 0xFF
	if int(cpu_state.get("sp", -1)) != entry_sp or int(cpu_state.get("pc", -1)) != SELECTOR_ENTRY_PC:
		return _failure("CPU PC/SP do not match the `$A20F` post-JSR entry state.")
	var stack_variant: Variant = source_call.get("stack_page")
	if not stack_variant is PackedByteArray or stack_variant.size() != 0x100:
		return _failure("The decoded 256-byte stack page is required for the nested and outer RTS instructions.")
	var stack: PackedByteArray = stack_variant.duplicate()
	var stacked_return := _peek_return_word(stack, entry_sp)
	if stacked_return != CALLER_PC + 2:
		return _failure("The caller's stacked JSR return word does not match `$80FA->$A20F`.")
	for register_name: String in ["a", "x", "y", "p"]:
		var value := int(cpu_state.get(register_name, -1))
		if value < 0 or value > 0xFF:
			return _failure("CPU register `%s` must be supplied as an explicit source byte." % register_name)
	for address: int in [0x0022, 0x0023, 0x0025, 0x0026]:
		if not ram_before.has(address):
			return _failure("Caller-owned RAM `$%04X` is required." % address)
		var byte_value := int(ram_before[address])
		if byte_value < 0 or byte_value > 0xFF:
			return _failure("Caller-owned RAM `$%04X` must fit one byte." % address)
	if int(ram_before[0x0026]) != FRESH_MATCH_INDEX:
		return _failure("Only ROM-derived fresh match index `$0026=0` is supported.")
	var mapper_shadow := int(ram_before[0x0022])
	var expected_mapper_value := 0x07 | mapper_shadow
	if int(ram_before[0x0023]) != expected_mapper_value \
			or int(ram_before[0x0025]) != 0x02 \
			or int(cpu_state["x"]) != 0x02 \
			or int(cpu_state["a"]) != expected_mapper_value:
		return _failure("Caller state does not match `$80F7->$C4B9` bank-$02 select output.")
	if (int(cpu_state["p"]) & 0x82) != _nz_bits(expected_mapper_value):
		return _failure("Caller N/Z flags do not match the preceding ROM mapper-select helper.")
	if int(cpu_state["y"]) != 0:
		return _failure("ROM `$A138` uses `(pointer),Y` while copying `$ACB0-$BFFF`; this bounded route requires explicit Y=0.")

	var registers := {
		"a": int(cpu_state["a"]), "x": int(cpu_state["x"]),
		"y": int(cpu_state["y"]), "p": int(cpu_state["p"]),
		"sp": entry_sp, "pc": SELECTOR_ENTRY_PC,
	}
	var ram_after := ram_before.duplicate(true)
	var writes: Array[Dictionary] = []
	var cpu_cycles := 0
	var instruction_count := 0
	var source_path: Array[int] = [SELECTOR_ENTRY_PC, SELECTOR_BODY_PC, 0xA870, 0xA872, 0xA87C, 0xA87E, ROSTER_COPY_TRAMPOLINE_PC, 0xA138]
	# Execute the match-zero branch and nested call. `$A8B7` is a tail jump,
	# therefore the JSR return word stays on the stack during `$A138`'s copy.
	cpu_cycles += 3 # `$A20F JMP $A86E`
	instruction_count += 1
	registers["a"] = int(ram_after[0x0026])
	registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
	cpu_cycles += 3 # LDA $26
	instruction_count += 1
	registers["p"] = _compare(int(registers["p"]), int(registers["a"]), 0x06)
	cpu_cycles += 2 # CMP #$06
	instruction_count += 1
	if (int(registers["p"]) & 0x01) != 0:
		return _failure("Fresh `$0026=0` unexpectedly does not take ROM `$A872 BCC`.")
	cpu_cycles += 3 # BCC `$A87C`
	instruction_count += 1
	registers["x"] = 0
	registers["p"] = _set_nz(int(registers["p"]), 0)
	cpu_cycles += 2 # LDX #$00
	instruction_count += 1
	if not _push_jsr(stack, int(registers["sp"]), 0xA880):
		return _failure("Nested `$A87E JSR $A8B7` could not push its ROM return word.")
	registers["sp"] = (int(registers["sp"]) - 2) & 0xFF
	registers["pc"] = ROSTER_COPY_TRAMPOLINE_PC
	cpu_cycles += 6 + 3 # JSR `$A8B7`; its ROM instruction is JMP `$A138`.
	instruction_count += 2
	registers["pc"] = 0xA138

	# `$A138` writes four caller-independent pointer bytes, but its Y-indexed
	# accesses require the explicit Y=0 precondition checked above.
	var pointer_setup := [
		{"pc": 0xA138, "address": 0x00D0, "value": 0xB0},
		{"pc": 0xA13C, "address": 0x00D1, "value": 0xAC},
		{"pc": 0xA140, "address": 0x00D2, "value": 0x00},
		{"pc": 0xA144, "address": 0x00D3, "value": 0x60},
	]
	for item_variant in pointer_setup:
		var item: Dictionary = item_variant
		var load_immediate := int(item["value"])
		registers["a"] = load_immediate
		registers["p"] = _set_nz(int(registers["p"]), load_immediate)
		ram_after[int(item["address"])] = load_immediate
		writes.append({"source_pc": int(item["pc"]) + 2, "address": int(item["address"]), "value": load_immediate})
		cpu_cycles += 5
		instruction_count += 2
		registers["pc"] = int(item["pc"]) + 4

	var copy_iterations := 0
	var copy_loop_cycles := 0
	var loop_guard := 0
	while true:
		loop_guard += 1
		if loop_guard > _copy_source.size():
			return _failure("ROM pointer walk exceeded its hash-checked `$ACB0-$BFFF` source span.")
		var source_low := int(ram_after[0x00D0])
		var source_high := int(ram_after[0x00D1])
		var destination_low := int(ram_after[0x00D2])
		var destination_high := int(ram_after[0x00D3])
		var source_address := (source_high << 8) | source_low
		var destination_address := (destination_high << 8) | destination_low
		var expected_source_address := SOURCE_COPY_START + copy_iterations
		var expected_destination_address := PRG_RAM_COPY_DESTINATION + copy_iterations
		if source_address != expected_source_address \
				or destination_address != expected_destination_address \
				or copy_iterations >= _copy_source.size():
			return _failure("Source pointer state escaped the ROM-derived copy span or PRG-RAM destination.")
		var copied_byte := int(_copy_source[copy_iterations])
		registers["a"] = copied_byte
		registers["p"] = _set_nz(int(registers["p"]), copied_byte)
		ram_after[destination_address] = copied_byte
		writes.append({"source_pc": 0xA14A, "address": destination_address, "value": copied_byte})
		copy_loop_cycles += 5 + 6
		instruction_count += 2
		copy_iterations += 1

		# `$A14C LDA $D0; $A14E CMP #$FF; $A150 BNE $A15B`.
		registers["a"] = source_low
		registers["p"] = _set_nz(int(registers["p"]), source_low)
		registers["p"] = _compare(int(registers["p"]), source_low, 0xFF)
		copy_loop_cycles += 3 + 2
		instruction_count += 2
		var terminates := false
		if source_low != 0xFF:
			copy_loop_cycles += 3 + 3 # taken BNE, then JMP `$A1EB`
			instruction_count += 2
		else:
			copy_loop_cycles += 2
			instruction_count += 1
			registers["a"] = source_high
			registers["p"] = _set_nz(int(registers["p"]), source_high)
			registers["p"] = _compare(int(registers["p"]), source_high, 0xBF)
			copy_loop_cycles += 3 + 2
			instruction_count += 2
			if source_high != 0xBF:
				copy_loop_cycles += 3 + 3 # taken BNE, then JMP `$A1EB`
				instruction_count += 2
			else:
				copy_loop_cycles += 2 + 3 # not-taken BNE, then JMP `$A1E4`
				instruction_count += 2
				terminates = true
		if terminates:
			break

		# `$A1EB-$A1F9`: increment source and destination pointer bytes and
		# jump back to `$A148`. INC updates N/Z only; branches use those flags.
		var next_source_low := (source_low + 1) & 0xFF
		ram_after[0x00D0] = next_source_low
		registers["p"] = _set_nz(int(registers["p"]), next_source_low)
		copy_loop_cycles += 5
		instruction_count += 1
		if next_source_low != 0:
			copy_loop_cycles += 3
			instruction_count += 1
		else:
			copy_loop_cycles += 2 + 5
			instruction_count += 2
			var next_source_high := (source_high + 1) & 0xFF
			ram_after[0x00D1] = next_source_high
			registers["p"] = _set_nz(int(registers["p"]), next_source_high)

		var next_destination_low := (destination_low + 1) & 0xFF
		ram_after[0x00D2] = next_destination_low
		registers["p"] = _set_nz(int(registers["p"]), next_destination_low)
		copy_loop_cycles += 5
		instruction_count += 1
		if next_destination_low != 0:
			copy_loop_cycles += 3
			instruction_count += 1
		else:
			copy_loop_cycles += 2 + 5
			instruction_count += 2
			var next_destination_high := (destination_high + 1) & 0xFF
			ram_after[0x00D3] = next_destination_high
			registers["p"] = _set_nz(int(registers["p"]), next_destination_high)
		copy_loop_cycles += 3 # JMP `$A148`
		instruction_count += 1

	if copy_iterations != _copy_source.size() \
			or int(ram_after[0x00D0]) != 0xFF or int(ram_after[0x00D1]) != 0xBF \
			or int(ram_after[0x00D2]) != 0x4F or int(ram_after[0x00D3]) != 0x73:
		return _failure("ROM `$A138` did not terminate at `$BFFF` with the expected post-copy pointers.")
	source_path.append_array([0xA148, 0xA150, 0xA15B, 0xA1EB, 0xA148, 0xA158, 0xA1E4, ROSTER_COPY_PC])
	cpu_cycles += copy_loop_cycles + 8 # `$A1E4 LDA/STA/JMP $A8BB`
	instruction_count += 3
	writes.append({"source_pc": 0xA1E6, "address": 0x00ED, "value": 0x0B})
	ram_after[0x00ED] = 0x0B
	registers["a"] = 0x0B
	registers["p"] = _set_nz(int(registers["p"]), 0x0B)
	registers["pc"] = ROSTER_COPY_PC

	# The ROM's in-span `$A8BB-$A8CD` loop copies the eleven match-zero
	# player IDs to the +0 byte of each twelve-byte CPU record.
	registers["pc"] = ROSTER_COPY_PC
	cpu_cycles += 2
	instruction_count += 1
	registers["y"] = 0
	registers["p"] = _set_nz(int(registers["p"]), 0)
	var roster: PackedByteArray = _sources["home_roster_match_00"]
	for player_index in range(11):
		var player_id := int(roster[player_index])
		registers["a"] = player_id
		registers["p"] = _set_nz(int(registers["p"]), player_id)
		var record_offset := player_index * 0x0C
		var record_address := 0x0300 + record_offset
		ram_after[record_address] = player_id
		writes.append({"source_pc": 0xA8C0, "address": record_address, "value": player_id})
		cpu_cycles += 4 + 5 + 2 + 2 + 2 + 2 + 2 + 2 + (3 if player_index < 10 else 2)
		instruction_count += 9
		registers["x"] = (int(registers["x"]) + 1) & 0xFF
		registers["p"] = _set_nz(int(registers["p"]), int(registers["x"]))
		registers["a"] = int(registers["y"])
		registers["p"] = _set_nz(int(registers["p"]), int(registers["a"]))
		registers["p"] = int(registers["p"]) & 0xFE # CLC
		var next_y := (int(registers["a"]) + 0x0C) & 0xFF
		registers["a"] = next_y
		registers["p"] = _adc_imm(int(registers["p"]), int(registers["y"]), 0x0C, false)
		registers["y"] = next_y
		registers["p"] = _set_nz(int(registers["p"]), next_y)
		registers["p"] = _compare(int(registers["p"]), next_y, 0x84)
		registers["pc"] = ROSTER_COPY_PC + 18
		registers["y"] = next_y
		registers["a"] = next_y
	if int(registers["x"]) != 11 or int(registers["y"]) != 0x84:
		return _failure("The `$A8BB` roster loop did not reach its ROM `$84` Y sentinel.")
	var nested_return := _pop_rts(stack, int(registers["sp"]))
	if int(nested_return["return_pc"]) != 0xA881:
		return _failure("The internal `$A8CD RTS` did not return to `$A881`.")
	registers["sp"] = int(nested_return["sp"])
	registers["pc"] = 0xA881
	cpu_cycles += 6
	instruction_count += 1
	source_path.append_array([0xA8CD, 0xA881, 0xA8A3, 0xA8A6, 0xA8A8, 0xA8AA, 0xA8AD, 0xA8AF, 0xA8B1, 0xA8B2, 0xA8B4, 0xA8B6])
	cpu_cycles += 3 # `$A881 JMP $A8A3`
	instruction_count += 1

	var formation := int(roster[11])
	registers["a"] = formation
	registers["p"] = _set_nz(int(registers["p"]), formation)
	ram_after[0x002C] = formation
	writes.append({"source_pc": 0xA8A6, "address": 0x002C, "value": formation})
	cpu_cycles += 4 + 3
	instruction_count += 2
	registers["x"] = int(ram_after[0x0026])
	registers["p"] = _set_nz(int(registers["p"]), int(registers["x"]))
	cpu_cycles += 3
	instruction_count += 1
	var home_team_id := int(_sources["home_team_match_table"][0])
	registers["a"] = home_team_id
	registers["p"] = _set_nz(int(registers["p"]), home_team_id)
	ram_after[0x002A] = home_team_id
	writes.append({"source_pc": 0xA8AD, "address": 0x002A, "value": home_team_id})
	cpu_cycles += 4 + 3
	instruction_count += 2
	var match_index := int(ram_after[0x0026])
	registers["a"] = match_index
	registers["p"] = _set_nz(int(registers["p"]), match_index)
	cpu_cycles += 3
	instruction_count += 1
	registers["p"] = int(registers["p"]) & 0xFE # CLC
	cpu_cycles += 2
	instruction_count += 1
	registers["p"] = _adc_imm(int(registers["p"]), match_index, 0x03, false)
	registers["a"] = (match_index + 3) & 0xFF
	cpu_cycles += 2
	instruction_count += 1
	ram_after[0x002B] = int(registers["a"])
	writes.append({"source_pc": 0xA8B4, "address": 0x002B, "value": int(registers["a"])})
	cpu_cycles += 3
	instruction_count += 1
	var outer_return := _pop_rts(stack, int(registers["sp"]))
	if int(outer_return["return_pc"]) != RETURN_PC \
			or int(outer_return["sp"]) != pre_call_sp:
		return _failure("The outer `$A8B6 RTS` did not return to the caller with a balanced stack.")
	registers["sp"] = int(outer_return["sp"])
	registers["pc"] = RETURN_PC
	cpu_cycles += 6
	instruction_count += 1

	return {
		"ok": true,
		"status": "returned",
		"source_call": source_call.duplicate(true),
		"source_return_receipt": {
			"caller_pc": CALLER_PC,
			"target_pc": SELECTOR_ENTRY_PC,
			"return_pc": RETURN_PC,
			"status": "returned",
			"source_event_id": source_event_id,
			"source_execution": "hash_checked_6502_subset_through_real_rts",
			"nested_jsr_return": {"caller_pc": 0xA87E, "target_pc": ROSTER_COPY_TRAMPOLINE_PC,
				"body_tailcall_pc": 0xA8B7, "return_pc": 0xA881, "rts_pc": 0xA8CD},
			"post_registers": registers.duplicate(true),
		},
		"source_rom_sha256": ROM_SHA256,
		"source_span_hashes": _source_hashes(),
		"source_path": source_path,
		"copy_loop_iterations": copy_iterations,
		"roster_loop_iterations": 11,
		"instruction_count": instruction_count,
		"cpu_cycles_without_interrupts": cpu_cycles,
		"entry_registers": cpu_state.duplicate(true),
		"return_registers": registers,
		"ram_writes": writes,
		"ram_after": ram_after,
		"stack_after": stack,
		"live_mapper_updated": false,
		"emulator_data_used": false,
		"trace_state_used": false,
	}


func _verify_instruction_spans() -> bool:
	var caller: PackedByteArray = _sources["title_caller"]
	var caller_offset := CALLER_PC - 0x80DF
	if caller.slice(caller_offset - 5, caller_offset + 3) != PackedByteArray([0xA2, 0x02, 0x20, 0xB9, 0xC4, 0x20, 0x0F, 0xA2]):
		return _fail("Caller bytes no longer execute bank-$02 select followed by `$80FA JSR $A20F`.")
	if _sources["selector_trampoline"] != PackedByteArray([0x4C, 0x6E, 0xA8]):
		return _fail("`$A20F` is no longer a JMP to `$A86E`.")
	var code: PackedByteArray = _sources["selector_code"]
	var checks := [
		[0xA86E, [0xA5, 0x26, 0xC9, 0x06, 0x90, 0x08]],
		[0xA87C, [0xA2, 0x00, 0x20, 0xB7, 0xA8, 0x4C, 0xA3, 0xA8]],
		[0xA8B7, [0x4C, 0x38, 0xA1]],
		[0xA8BB, [0xA0, 0x00, 0xBD, 0x47, 0xAA, 0x99, 0x00, 0x03, 0xE8, 0x98, 0x18, 0x69, 0x0C, 0xA8, 0xC9, 0x84, 0x90, 0xF0, 0x60]],
		[0xA8A3, [0xBD, 0x47, 0xAA, 0x85, 0x2C, 0xA6, 0x26, 0xBD, 0x75, 0xAA, 0x85, 0x2A, 0xA5, 0x26, 0x18, 0x69, 0x03, 0x85, 0x2B, 0x60]],
	]
	for check_variant in checks:
		var check: Array = check_variant
		if not _bytes_at(code, int(check[0]) - SELECTOR_BODY_PC, PackedByteArray(check[1])):
			return _fail("Selector path bytes differ at `$%04X`." % int(check[0]))
	if _sources["selector_copy_scan_code"] != PackedByteArray([
		0xA9, 0xB0, 0x85, 0xD0, 0xA9, 0xAC, 0x85, 0xD1, 0xA9, 0x00, 0x85, 0xD2,
		0xA9, 0x60, 0x85, 0xD3, 0xB1, 0xD0, 0x91, 0xD2, 0xA5, 0xD0, 0xC9, 0xFF,
		0xD0, 0x09, 0xA5, 0xD1, 0xC9, 0xBF, 0xD0, 0x03, 0x4C, 0xE4, 0xA1, 0x4C,
		0xEB, 0xA1,
	]):
		return _fail("Packaged ROM `$A138` source-copy scan bytes differ.")
	if _sources["selector_copy_finish_code"] != PackedByteArray([0xA9, 0x0B, 0x85, 0xED, 0x4C, 0xBB, 0xA8]):
		return _fail("Packaged ROM `$A1E4` no longer resumes the `$A8BB` roster-copy body.")
	if _sources["selector_copy_increment_code"] != PackedByteArray([
		0xE6, 0xD0, 0xD0, 0x02, 0xE6, 0xD1, 0xE6, 0xD2, 0xD0, 0x02, 0xE6, 0xD3, 0x4C, 0x48, 0xA1,
	]):
		return _fail("Packaged ROM `$A1EB` pointer incrementer bytes differ.")
	if _copy_source.size() != SOURCE_COPY_END_EXCLUSIVE - SOURCE_COPY_START:
		return _fail("Selector's PRG-RAM source block has the wrong bounds.")
	return true


func _bytes_at(bytes: PackedByteArray, offset: int, expected: PackedByteArray) -> bool:
	return offset >= 0 and offset + expected.size() <= bytes.size() \
			and bytes.slice(offset, offset + expected.size()) == expected


func _push_jsr(stack: PackedByteArray, sp: int, pushed_return: int) -> bool:
	if stack.size() != 0x100:
		return false
	stack[sp] = (pushed_return >> 8) & 0xFF
	var next_sp := (sp - 1) & 0xFF
	stack[next_sp] = pushed_return & 0xFF
	return true


func _pop_rts(stack: PackedByteArray, sp: int) -> Dictionary:
	var low_index := (sp + 1) & 0xFF
	var low := int(stack[low_index])
	var high_index := (sp + 2) & 0xFF
	var high := int(stack[high_index])
	return {"return_pc": ((high << 8) | low) + 1, "sp": (sp + 2) & 0xFF}


func _peek_return_word(stack: PackedByteArray, entry_sp: int) -> int:
	var low := int(stack[(entry_sp + 1) & 0xFF])
	var high := int(stack[(entry_sp + 2) & 0xFF])
	return low | (high << 8)


func _set_nz(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0x80) != 0:
		result |= 0x80
	if (value & 0xFF) == 0:
		result |= 0x02
	return result


func _nz_bits(value: int) -> int:
	return 0x80 if (value & 0x80) != 0 else 0


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
