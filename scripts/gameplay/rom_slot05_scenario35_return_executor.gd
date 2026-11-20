extends RefCounted
class_name RomSlot05Scenario35ReturnExecutor
## Executes the ROM-owned `$CBC1 RTS` for the supported scenario-$35/$1E/$44
## callers and the PASS scenario-$38 caller. The stack supplies the return
## address; no endpoint PC or register state is injected.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin"
const SOURCE_SHA256 := "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32"
const SCENARIO44_RETURN_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/scenario44_post_cbc1_E38F_E3A3.bin"
const SCENARIO44_RETURN_SHA256 := "7dc4f685cc530388f709b0944a932a5fb2186f702625a3ef2e9fd1db117739a6"
const PASS_HANDLER_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_action_menu_input/manifest.json"
const PASS_HANDLER_MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const PASS_HANDLER_PATH := "res://reference/rom_extract/gameplay/first_action_menu_input/pass_receiver_handler_D7E8_D8F6.bin"
const PASS_HANDLER_SHA256 := "9ccc071c8af66e997b4fe1fe3613af4e764d756c35c6c96118ceba7faf034032"
const PASS_SCENARIO18_MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_scenario_18/manifest.json"
const PASS_SCENARIO18_CALLER_PATH := "res://reference/rom_extract/gameplay/pass_scenario_18/slot05_scenario18_post_queue_caller_8188_819b.bin"
const PASS_SCENARIO18_CALLER_SHA256 := "fea79dbe1bb2ce4aa401d7b4df6c6cfd4574aa0ee0bf0fac643005b42f428245"
const PASS_SCENARIO1C_MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_scenario_1c/manifest.json"
const PASS_SCENARIO18_VECTOR_PATH := "res://reference/rom_extract/gameplay/pass_scenario_1c/fixed_C624_dispatch_vectors_C624_C64E.bin"
const PASS_SCENARIO18_VECTOR_SHA256 := "481b6bc076bd7c8d9073cfa46949fe6548c58dedb6fac84067a5c4a8effb5968"
const PASS_SCENARIO18_DCDF_PATH := "res://reference/rom_extract/gameplay/pass_scenario_1c/fixed_C624_vector0_target_DCDF_DCF0.bin"
const PASS_SCENARIO18_DCDF_SHA256 := "a43a68c0bdbf3333d386bf74dd3f201bae308948f8ea3e58bd173c32bdc46a8d"
const PASS_SCENARIO1C_HANDOFF_MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/manifest.json"
const PASS_SCENARIO1C_HANDOFF_PATH := "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/pass_holder_commit_and_scenario_handoff_DE6C_DE96.bin"
const PASS_SCENARIO1C_HANDOFF_SHA256 := "d6ab96667636645baf440cfa35b81c05279f471ee3de570af7adbea241867cfa"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const RTS_PC := 0xCBC1
const RETURN_PROFILES := {
	0xDADC: {"return_pc": 0xDADD, "scenario_id": 0x35, "entry_sp": 0x4E,
		"source_return_word": 0xD11D, "bank_low": 0x1C, "bank_high": 0x1D},
	0xE237: [
		{"return_pc": 0xE238, "scenario_id": 0x1E, "entry_sp": 0x4C,
			"source_return_word": 0xD11D, "bank_low": 0x1C, "bank_high": 0x1D,
			"caller_source": "live slot-$05 context `$D11D`; fixed caller `$E233->$E238`"},
		{"return_pc": 0xE238, "scenario_id": 0x1E, "entry_sp": 0x4C,
			"source_return_word": 0xE944, "bank_low": 0x1A, "bank_high": 0x1B,
			"caller_source": "resumed slot-$05 context `$E944`; fixed caller `$E233->$E238`"},
	],
	0xE38E: {"return_pc": 0xE38F, "scenario_id": 0x44, "entry_sp": 0x4C,
		"source_return_word": 0xD11D, "bank_low": 0x1A, "bank_high": 0x1B},
	0xD7EC: {"return_pc": 0xD7ED, "scenario_id": 0x38, "entry_sp": 0x48,
		# `$CB0F` saved the PASS caller's `$24/$25=$1C/$1D`; `$CAD4->$CE2D`
		# restores that pair before this yielded `$CBC1 RTS` dispatch.
		"source_return_word": 0xE944, "bank_low": 0x1C, "bank_high": 0x1D,
		"caller_source": "ROM `$D7E8 LDA #$38; $D7EA JSR $CBB0`; resume `$D7ED`"},
	0x8187: {"return_pc": 0x8188, "scenario_id": 0x18, "entry_sp": 0x4C,
		"source_return_word": 0xE944, "bank_low": 0x1A, "bank_high": 0x1B,
		"caller_source": "ROM bank `$1A` `$8188-$819B`; `$819B RTS` resumes `$E945`"},
	0xDE8F: {"return_pc": 0xDE90, "scenario_id": 0x1C, "entry_sp": 0x4E,
		"source_return_word": 0xE944, "bank_low": 0x1A, "bank_high": 0x1B,
		"caller_source": "ROM bank `$1E` `$DE8D JSR $CBB0`; `$CBC1 RTS` resumes `$DE90`"},
}

var error_message := ""
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Scenario task runtime source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary or String(parsed.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Scenario task runtime manifest targets a different ROM revision.")
	var found_source := false
	for entry_variant in parsed.get("entries", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			if String(entry.get("path", "")) == SOURCE_PATH.trim_prefix("res://"):
				found_source = String(entry.get("cpu_address", "")) == "$CBB0" \
					and String(entry.get("sha256", "")) == SOURCE_SHA256 \
					and int(entry.get("length_bytes", -1)) == 18
	if not found_source:
		return _fail("Scenario source manifest does not identify the expected `$CBB0-$CBC1` bytes.")
	var source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source.size() != 18 or _sha256(source) != SOURCE_SHA256 or int(source[17]) != 0x60:
		return _fail("The shared `$CBC1 RTS` source failed its size/hash/source check.")
	var return_span_found := false
	for entry_variant in parsed.get("entries", []):
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("path", "")) == SCENARIO44_RETURN_PATH.trim_prefix("res://"):
			return_span_found = String(entry.get("cpu_address", "")) == "$E38F" \
				and String(entry.get("file_offset", "")) == "0x03E39F" \
				and int(entry.get("length_bytes", -1)) == 20 \
				and String(entry.get("sha256", "")) == SCENARIO44_RETURN_SHA256
	var scenario44_return := FileAccess.get_file_as_bytes(SCENARIO44_RETURN_PATH)
	if not return_span_found or scenario44_return.size() != 20 \
			or _sha256(scenario44_return) != SCENARIO44_RETURN_SHA256 \
			or scenario44_return != PackedByteArray([0x20, 0x8B, 0xCB, 0xA9, 0x1A, 0x85, 0x24,
			0xA9, 0x1B, 0x85, 0x25, 0x20, 0x2D, 0xCE, 0xA2, 0x50, 0x9A, 0x4C, 0x03, 0x80]):
		return _fail("Scenario-$44 `$E38F->$8003` return bytes failed manifest/hash validation.")
	var pass_manifest_bytes := FileAccess.get_file_as_bytes(PASS_HANDLER_MANIFEST_PATH)
	var pass_manifest: Variant = JSON.parse_string(pass_manifest_bytes.get_string_from_utf8())
	var pass_span_found := false
	if pass_manifest is Dictionary and String(pass_manifest.get("source_rom_sha256", "")) == ROM_SHA256:
		for span_variant in pass_manifest.get("source_spans", []):
			if not span_variant is Dictionary:
				continue
			var span: Dictionary = span_variant
			if String(span.get("name", "")) == "pass_receiver_handler":
				pass_span_found = String(span.get("prg_bank", "")) == "0x1E" \
					and String(span.get("cpu_start", "")) == "0xD7E8" \
					and String(span.get("file_offset", "")) == "0x03D7F8" \
					and int(span.get("length_bytes", -1)) == 271 \
					and String(span.get("resource", "")) == "pass_receiver_handler_D7E8_D8F6.bin" \
					and String(span.get("sha256", "")) == PASS_HANDLER_SHA256 \
					and String(span.get("verified_prefix_hex", "")) == "a9 38 20 b0 cb a9 0f 20 7f ef"
	var pass_manifest_file := FileAccess.open(PASS_HANDLER_MANIFEST_PATH, FileAccess.READ)
	var pass_manifest_hash := ""
	if pass_manifest_file != null:
		pass_manifest_hash = _sha256(pass_manifest_file.get_buffer(pass_manifest_file.get_length()))
	var pass_handler := FileAccess.get_file_as_bytes(PASS_HANDLER_PATH)
	if not pass_manifest is Dictionary or not pass_span_found \
			or pass_manifest_hash != PASS_HANDLER_MANIFEST_SHA256 \
			or pass_handler.size() != 271 or _sha256(pass_handler) != PASS_HANDLER_SHA256 \
			or pass_handler.slice(0, 10) != PackedByteArray([0xA9, 0x38, 0x20, 0xB0, 0xCB,
			0xA9, 0x0F, 0x20, 0x7F, 0xEF]):
		return _fail("Scenario-$38 caller `$D7E8->$D7EA->$D7ED` is not pinned to its ROM-derived handler span.")
	if not _verify_scenario18_caller_sources():
		return false
	if not _verify_scenario1c_handoff_source():
		return false
	_configured = true
	return true


func _verify_scenario1c_handoff_source() -> bool:
	var manifest_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO1C_HANDOFF_MANIFEST_PATH)
	var manifest: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	var span_found := false
	if manifest is Dictionary:
		var source_rom: Variant = manifest.get("source_rom", {})
		if source_rom is Dictionary and String(source_rom.get("sha256", "")) == ROM_SHA256:
			for span_variant in manifest.get("spans", []):
				if not span_variant is Dictionary:
					continue
				var span: Dictionary = span_variant
				if String(span.get("name", "")) == "pass_holder_commit_and_scenario_handoff_DE6C_DE96":
					span_found = String(span.get("bank", "")) == "0x1E" \
						and String(span.get("cpu_start", "")) == "0xDE6C" \
						and String(span.get("file_offset", "")) == "0x03DE7C" \
						and int(span.get("length_bytes", -1)) == 42 \
						and String(span.get("sha256", "")) == PASS_SCENARIO1C_HANDOFF_SHA256 \
						and String(span.get("file", "")) == PASS_SCENARIO1C_HANDOFF_PATH.get_file()
	var caller := FileAccess.get_file_as_bytes(PASS_SCENARIO1C_HANDOFF_PATH)
	var expected := PackedByteArray([0xAD, 0xFC, 0x05, 0xC9, 0xFF, 0xF0, 0x23, 0x8D,
		0x41, 0x04, 0x20, 0xEC, 0xE6, 0x48, 0xA5, 0x22, 0xA9, 0x1A, 0x85, 0x24,
		0xA9, 0x1B, 0x85, 0x25, 0x20, 0x2D, 0xCE, 0x68, 0x20, 0x1E, 0x80, 0xA9,
		0x1C, 0x20, 0xB0, 0xCB, 0xA2, 0x50, 0x9A, 0x4C, 0xDF, 0xE0])
	if not span_found or caller != expected or _sha256(caller) != PASS_SCENARIO1C_HANDOFF_SHA256:
		return _fail("Scenario-$1C `$DE6C->$DE90` caller bytes failed manifest/hash validation.")
	return true


func _verify_scenario18_caller_sources() -> bool:
	var scenario_manifest_file := FileAccess.open(PASS_SCENARIO18_MANIFEST_PATH, FileAccess.READ)
	if scenario_manifest_file == null:
		return _fail("Scenario-$18 caller source manifest is unavailable.")
	var scenario_manifest: Variant = JSON.parse_string(scenario_manifest_file.get_as_text())
	var caller_found := false
	if scenario_manifest is Dictionary \
			and String(scenario_manifest.get("source_rom_sha256", "")) == ROM_SHA256:
		var caller_variant: Variant = scenario_manifest.get("slot05_post_queue_caller", {})
		if caller_variant is Dictionary:
			caller_found = String(caller_variant.get("cpu_address", "")) == "0x8188" \
					and String(caller_variant.get("file_offset", "")) == "0x034198" \
					and int(caller_variant.get("length_bytes", -1)) == 20 \
					and String(caller_variant.get("file", "")) == PASS_SCENARIO18_CALLER_PATH.get_file() \
					and String(caller_variant.get("sha256", "")) == PASS_SCENARIO18_CALLER_SHA256
	var caller := FileAccess.get_file_as_bytes(PASS_SCENARIO18_CALLER_PATH)
	if not caller_found or caller.size() != 20 or _sha256(caller) != PASS_SCENARIO18_CALLER_SHA256 \
			or caller != PackedByteArray([0xAD, 0x44, 0x04, 0x29, 0x03, 0x8D, 0x4E, 0x04,
			0x20, 0x24, 0xC6, 0xAD, 0x17, 0x06, 0x09, 0x80, 0x8D, 0x17, 0x06, 0x60]):
		return _fail("Scenario-$18 bank-$1A `$8188-$819B` caller failed manifest/hash/byte validation.")
	var helper_manifest_file := FileAccess.open(PASS_SCENARIO1C_MANIFEST_PATH, FileAccess.READ)
	if helper_manifest_file == null:
		return _fail("Pinned `$C624->$DCDF` helper source manifest is unavailable.")
	var helper_manifest: Variant = JSON.parse_string(helper_manifest_file.get_as_text())
	var vector_found := false
	var dcdf_found := false
	var helper_rom: Dictionary = helper_manifest.get("source_rom", {}) if helper_manifest is Dictionary else {}
	if helper_manifest is Dictionary and String(helper_rom.get("sha256", "")) == ROM_SHA256:
		for span_variant in helper_manifest.get("spans", []):
			if not span_variant is Dictionary:
				continue
			var span: Dictionary = span_variant
			if String(span.get("name", "")) == "fixed_C624_dispatch_vectors_C624_C64E":
				vector_found = String(span.get("bank", "")) == "0x1E" \
						and String(span.get("cpu_start", "")) == "0xC624" \
						and String(span.get("file_offset", "")) == "0x03C634" \
						and int(span.get("length_bytes", -1)) == 42 \
						and String(span.get("sha256", "")) == PASS_SCENARIO18_VECTOR_SHA256
			elif String(span.get("name", "")) == "fixed_C624_vector0_target_DCDF_DCF0":
				dcdf_found = String(span.get("bank", "")) == "0x1E" \
						and String(span.get("cpu_start", "")) == "0xDCDF" \
						and String(span.get("file_offset", "")) == "0x03DCEF" \
						and int(span.get("length_bytes", -1)) == 17 \
						and String(span.get("sha256", "")) == PASS_SCENARIO18_DCDF_SHA256
	var vector := FileAccess.get_file_as_bytes(PASS_SCENARIO18_VECTOR_PATH)
	var dcdf := FileAccess.get_file_as_bytes(PASS_SCENARIO18_DCDF_PATH)
	if not vector_found or not dcdf_found or vector.size() != 42 or dcdf.size() != 17 \
			or _sha256(vector) != PASS_SCENARIO18_VECTOR_SHA256 \
			or _sha256(dcdf) != PASS_SCENARIO18_DCDF_SHA256 \
			or vector.slice(0, 3) != PackedByteArray([0x4C, 0xDF, 0xDC]) \
			or dcdf != PackedByteArray([0xAD, 0x4E, 0x04, 0xD0, 0x0B, 0xAD, 0xE2, 0x00,
			0x29, 0x01, 0x18, 0x69, 0x01, 0x8D, 0x4E, 0x04, 0x60]):
		return _fail("Scenario-$18 caller `$C624->$DCDF` vector/helper bytes failed manifest/hash validation.")
	return true


## Continues one actual slot-$05 dispatch selected by the source scheduler.
func execute_from_live_dispatch(dispatch: Dictionary, boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _failure("Configure the hash-checked scenario source before execution.")
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var scenario_id := int(ram[0x0518]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1
	var debug_stack_pointer := int(dispatch.get("sp", -1))
	var stack_return_word := -1
	if stack is PackedByteArray and stack.size() == STACK_SIZE and debug_stack_pointer >= 0:
		var return_low := int(stack[(debug_stack_pointer + 1) & 0xFF])
		var return_high := int(stack[(debug_stack_pointer + 2) & 0xFF])
		stack_return_word = (return_high << 8) | return_low
	var profile := _profile_for_dispatch(stack_return_word, dispatch, scenario_id)
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != RTS_PC \
			or int(dispatch.get("sp", -1)) not in [0x48, 0x4C, 0x4E] \
			or profile.is_empty() \
			or (not profile.is_empty() and (int(dispatch.get("bank_low", -1)) != int(profile.get("bank_low", -2)) \
				or int(dispatch.get("bank_high", -1)) != int(profile.get("bank_high", -2)))) \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != RTS_PC \
			or int(boundary.get("sp", -1)) != int(dispatch.get("sp", -2)) \
			or int(boundary.get("sp", -1)) != int(dispatch.get("sp", -2)) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE:
		return _failure("Input is not a supported live slot-$05 `$CBC1` return boundary: scenario=$%02X stack_return=$%04X source_return=$%04X dispatch slot/path/PC/SP/banks=$%02X/%s/$%04X/$%02X/$%02X/$%02X; boundary slot/active/PC/SP=$%02X/$%02X/$%04X/$%02X; RAM/stack bytes=%d/%d." % [
			scenario_id, stack_return_word, int(dispatch.get("source_return_word", -1)),
			int(dispatch.get("slot_base", -1)), String(dispatch.get("resume_path", "")),
			int(dispatch.get("pc", -1)), int(dispatch.get("sp", -1)),
			int(dispatch.get("bank_low", -1)), int(dispatch.get("bank_high", -1)),
			int(boundary.get("slot_base", -1)), int(boundary.get("active_task_slot", -1)),
			int(boundary.get("pc", -1)), int(boundary.get("sp", -1)),
			ram.size() if ram is PackedByteArray else -1,
			stack.size() if stack is PackedByteArray else -1])
	for stack_offset in range(STACK_SIZE):
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return _failure("Live slot-$05 RAM and stack mirror differ at `$%02X`." % stack_offset)
	var stack_pointer := int(dispatch["sp"])
	var low := int(stack[(stack_pointer + 1) & 0xFF])
	var high := int(stack[(stack_pointer + 2) & 0xFF])
	var return_word := (high << 8) | low
	if profile.is_empty() \
			or int(dispatch.get("source_return_word", -1)) != int(profile.get("source_return_word", -2)) \
			or stack_pointer != int(profile.get("entry_sp", -1)) \
			or int(ram[0x0518]) != int(profile.get("scenario_id", -1)):
		return _failure("The live `$CBC1 RTS` frame does not match a known scenario profile: task seed `$%04X`, scenario `$%02X`, return-minus-one `$%04X`, SP `$%02X`." % [int(dispatch.get("source_return_word", -1)), int(ram[0x0518]), return_word, stack_pointer])
	var result_ram: PackedByteArray = ram.duplicate()
	var result_stack: PackedByteArray = stack.duplicate()
	var registers := {
		"a": int(dispatch.get("a", -1)), "x": int(dispatch.get("x", -1)),
		"y": int(dispatch.get("y", -1)), "sp": (stack_pointer + 2) & 0xFF,
		"pc": (return_word + 1) & 0xFFFF,
		"p": int(dispatch.get("p", 0x20)),
		"p_known_mask": int(dispatch.get("p_known_mask", 0)),
		"p_known_value": int(dispatch.get("p_known_value", 0)),
		"bank_low": int(dispatch["bank_low"]), "bank_high": int(dispatch["bank_high"]),
	}


	return {
		"ok": true, "status": "returned_to_source_caller",
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"entry": {"slot_base": 0x05, "call_pc": RTS_PC,
			"target_pc": RTS_PC, "expected_return_pc": int(profile["return_pc"]),
			"scenario_id": int(profile["scenario_id"]), "return_word": return_word,
			"source": "live slot-$05 scheduler dispatch and stack page",
			"caller_source": String(profile.get("caller_source", "scenario source return profile"))},
		"registers": registers,
		"mapper": {"register_select": int(ram[0x0022]) & 0x07,
			"bank_low": int(dispatch["bank_low"]), "bank_high": int(dispatch["bank_high"]),
			"task_bank_low": int(dispatch["bank_low"]),
			"task_bank_high": int(dispatch["bank_high"])},
		"ram_image": result_ram, "stack_page": result_stack,
		"memory_writes": [], "instruction_pcs": [RTS_PC], "instruction_count": 1,
		"returned_to_caller": true, "ppu_bus_events": [],
		"ppu_cycle_timing_modeled": false, "audio_effects_modeled": false,
		"call_contract": {"dispatch": dispatch.duplicate(true),
			"caller_request": {"source_pc": RTS_PC,
			"target_cpu_address": RTS_PC, "return_word": return_word,
				"return_pc": (return_word + 1) & 0xFFFF,
				"sp_before": stack_pointer, "sp_after": (stack_pointer + 2) & 0xFF}},
	}


func _profile_for_dispatch(return_word: int, dispatch: Dictionary,
		scenario_id: int) -> Dictionary:
	var profile_source: Variant = RETURN_PROFILES.get(return_word, {})
	var candidates: Array = profile_source if profile_source is Array else [profile_source]
	for candidate_variant in candidates:
		if not candidate_variant is Dictionary:
			continue
		var candidate: Dictionary = candidate_variant
		if int(candidate.get("scenario_id", -1)) == scenario_id \
				and int(candidate.get("entry_sp", -1)) == int(dispatch.get("sp", -2)) \
				and int(candidate.get("source_return_word", -1)) == int(dispatch.get("source_return_word", -2)) \
				and int(candidate.get("bank_low", -1)) == int(dispatch.get("bank_low", -2)) \
				and int(candidate.get("bank_high", -1)) == int(dispatch.get("bank_high", -2)):
			return candidate
	return {}


## Executes only the hash-pinned `$DE90: LDX #$50; TXS; JMP $E0DF` tail after
## the live `$CBC1 RTS` has returned through physical stack word `$DE8F`.
func execute_scenario1c_handoff_tail(return_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _failure("Configure the hash-checked scenario source before execution.")
	var entry: Variant = return_result.get("entry", {})
	var registers_variant: Variant = return_result.get("registers", {})
	var mapper_variant: Variant = return_result.get("mapper", {})
	var ram_variant: Variant = return_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = return_result.get("stack_page", PackedByteArray())
	if not bool(return_result.get("ok", false)) \
			or String(return_result.get("status", "")) != "returned_to_source_caller" \
			or String(return_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(return_result.get("source_manifest", "")) != MANIFEST_PATH \
			or not entry is Dictionary or int(entry.get("scenario_id", -1)) != 0x1C \
			or int(entry.get("call_pc", -1)) != RTS_PC \
			or int(entry.get("return_word", -1)) != 0xDE8F \
			or int(entry.get("expected_return_pc", -1)) != 0xDE90 \
			or not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or (ram_variant as PackedByteArray).size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or (stack_variant as PackedByteArray).size() != STACK_SIZE:
		return _failure("Scenario-$1C tail requires the live `$CBC1 RTS->$DE90` return frame.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if int(registers.get("pc", -1)) != 0xDE90 or int(registers.get("sp", -1)) != 0x50 \
			or int(mapper.get("bank_low", -1)) != 0x1A \
			or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("register_select", -1)) != (int(ram[0x0022]) & 0x07) \
			or ram.slice(0x0100, 0x0200) != stack:
		return _failure("Scenario-$1C `$DE90` registers, mapper, or RAM/stack mirror are inconsistent.")
	var caller := FileAccess.get_file_as_bytes(PASS_SCENARIO1C_HANDOFF_PATH)
	if caller.size() != 42 or _sha256(caller) != PASS_SCENARIO1C_HANDOFF_SHA256 \
			or caller.slice(36, 42) != PackedByteArray([0xA2, 0x50, 0x9A, 0x4C, 0xDF, 0xE0]):
		return _failure("Scenario-$1C `$DE90-$DE95` handoff tail failed its source check.")
	var next_registers := registers.duplicate(true)
	var status_value := int(registers.get("p", 0x20)) & 0x7D
	var status_known_mask := (int(registers.get("p_known_mask", 0)) | 0x82) & 0xFF
	# LDX #$50 sets N=0 and Z=0; all other status flags are preserved.
	next_registers["x"] = 0x50
	next_registers["p"] = status_value
	next_registers["p_known_mask"] = status_known_mask
	next_registers["p_known_value"] = status_value & status_known_mask
	next_registers["sp"] = 0x50
	next_registers["pc"] = 0xE0DF
	var output_mapper := mapper.duplicate(true)
	output_mapper["select"] = int(mapper.get("register_select", 0x07)) & 0x07
	return {"ok": true, "status": "scenario1c_pass_handoff_returned_to_e0df",
		"rom_sha256": ROM_SHA256, "source_manifest": PASS_SCENARIO1C_HANDOFF_MANIFEST_PATH,
		"source_span": PASS_SCENARIO1C_HANDOFF_PATH, "source_span_sha256": PASS_SCENARIO1C_HANDOFF_SHA256,
		"entry_pc": 0xDE90, "entry_sp": 0x50, "exit_pc": 0xE0DF, "exit_sp": 0x50,
		"source_instruction_pcs": [0xDE90, 0xDE92, 0xDE93],
		"entry_registers": registers.duplicate(true),
		"registers": next_registers, "mapper": output_mapper,
		"ram_image": ram.duplicate(), "stack_page": stack.duplicate(),
		"writes": [], "mapper_writes": [], "ppu_bus_events": [], "apu_register_writes": [],
		"cycle_timing_modeled": false, "runtime_integrated": true}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "rejected_entry_state", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
