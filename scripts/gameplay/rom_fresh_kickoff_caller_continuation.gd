extends RefCounted
class_name RomFreshKickoffCallerContinuation
## Bounded projection of the bank-$00 KICK OFF caller from title selection
## through the automatic cutscene-$02 dispatch. It is not a 6502/task runner.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const RESET_SPAN_SHA256 := "8315e93ae660d302632f7bfeffc9db002b3f1c1643ae2b6936d3ce5703e6f75a"
const RESET_SPAN_LENGTH := 44

const CALLER_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const WAIT_FILE := "bank00_select_wait_82B5_82EC.bin"
const TABLE_FILE := "bank00_pre_match_cutscene_ids_83DC_83FC.bin"
const MAPPER_FILE := "fixed_mapper_select_C4B9_C4C7.bin"

const SOURCE_SPANS := {
	CALLER_FILE: {
		"cpu_start": "$80DF", "cpu_end_exclusive": "$815D", "file_offset": "0x0000EF",
		"length": 126, "sha256": "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b",
	},
	WAIT_FILE: {
		"cpu_start": "$82B5", "cpu_end_exclusive": "$82ED", "file_offset": "0x0002C5",
		"length": 56, "sha256": "6b894cd9f7a0b4e6927ce98c739672b5d79627b5e138a0257898f94793a75b5c",
	},
	TABLE_FILE: {
		"cpu_start": "$83DC", "cpu_end_exclusive": "$83FD", "file_offset": "0x0003EC",
		"length": 33, "sha256": "c0e1023552ed03cbf1e741956f76bdef150143848197a8da5e5000508bad2051",
	},
	MAPPER_FILE: {
		"cpu_start": "$C4B9", "cpu_end_exclusive": "$C4C8", "file_offset": "0x03C4C9",
		"length": 15, "sha256": "a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12",
	},
}

const CALLS_BEFORE_MATCH_MUSIC := [
	{"caller_pc": 0x80E6, "target_pc": 0x9BA0, "return_pc": 0x80E9, "call_id": "title_presentation_clear"},
	{"caller_pc": 0x80EB, "target_pc": 0x8464, "return_pc": 0x80EE, "call_id": "dispatch_cutscene_1", "cutscene_id": 1},
	{"caller_pc": 0x82DF, "target_pc": 0x9BA0, "return_pc": 0x82E2, "call_id": "cutscene_1_wait_presentation_clear"},
	{"caller_pc": 0x80F7, "target_pc": 0xC4B9, "return_pc": 0x80FA, "call_id": "select_bank_02_before_match_lookup"},
	{"caller_pc": 0x80FA, "target_pc": 0xA20F, "return_pc": 0x80FD, "call_id": "resolve_fresh_match_roster"},
	{"caller_pc": 0x810C, "target_pc": 0xC4B9, "return_pc": 0x810F, "call_id": "select_bank_02_before_roster_normalize"},
	{"caller_pc": 0x810F, "target_pc": 0xA20C, "return_pc": 0x8112, "call_id": "normalize_roster"},
	{"caller_pc": 0x8114, "target_pc": 0x8920, "return_pc": 0x8117, "call_id": "clear_goal_and_period_state"},
	{"caller_pc": 0x8119, "target_pc": 0xC4B9, "return_pc": 0x811C, "call_id": "select_bank_01_before_prematch_setup"},
	{"caller_pc": 0x811C, "target_pc": 0xA006, "return_pc": 0x811F, "call_id": "prematch_setup_a006"},
	{"caller_pc": 0x811F, "target_pc": 0xC572, "return_pc": 0x8122, "call_id": "prematch_setup_c572"},
]

const CALLS_AFTER_MATCH_MUSIC := [
	{"caller_pc": 0x813F, "target_pc": 0xC4B9, "return_pc": 0x8142, "call_id": "select_bank_01_before_cutscene_table"},
	{"caller_pc": 0x8142, "target_pc": 0xA009, "return_pc": 0x8145, "call_id": "prematch_dispatch_setup_a009"},
	{"caller_pc": 0x8157, "target_pc": 0x8464, "return_pc": 0x815A, "call_id": "dispatch_table_cutscene", "cutscene_id_from_rom_table": true},
]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _reset_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Fresh KICK OFF caller-source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh KICK OFF caller-source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-caller-source-v1":
		return _fail("Fresh KICK OFF caller-source manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Caller-source manifest targets a different ROM revision.")
	var entries_by_file: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for file_name: String in SOURCE_SPANS:
		var expected: Dictionary = SOURCE_SPANS[file_name]
		if not entries_by_file.has(file_name):
			return _fail("Caller-source manifest omits %s." % file_name)
		var entry: Dictionary = entries_by_file[file_name]
		for key: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(key, -1)) == int(expected[key]) \
					if key == "length" else String(entry.get(key, "")) == String(expected[key])
			if not matches:
				return _fail("Caller-source manifest metadata differs for %s (%s)." % [file_name, key])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]):
			return _fail("Packaged caller-source ROM span failed its size/hash check: %s." % file_name)
		if String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Caller-source manifest byte listing disagrees with %s." % file_name)
		_sources[file_name] = bytes
	if not _verify_source_semantics():
		return false
	if not _load_reset_source(manifest):
		return false
	_configured = true
	return true


## Projects the decoded KICK OFF caller. Each unmodeled JSR return must be
## supplied as a named source-return receipt; there are no elapsed-frame gates.
## The ID-1 wait result must come from the decoded script-end or fresh-Select
## edge. Audio events are emitted only if the instruction path reaches a store.
func execute_fresh_kickoff(caller_inputs: Dictionary, source_returns: Array) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	var result := _new_result()
	if not bool(caller_inputs.get("start_press_accepted", false)):
		return _refused("The title caller has not accepted a Start edge.")
	if String(caller_inputs.get("title_input_event_id", "")).is_empty():
		return _refused("The title Start edge must have a decoded input-event identity.")
	var title_ed := int(caller_inputs.get("title_state_ed", -1))
	if title_ed < 0 or title_ed > 0xFF:
		return _refused("Caller must supply the title `$ED` state at `$80DF`.")
	if (title_ed & 0x40) != 0:
		return _refused("`$80DF` selects Continue when `$ED.6` is set; this component follows KICK OFF only.")
	var reset_match_index := _derive_reset_match_index()
	var match_index := int(caller_inputs.get("match_index_0026", reset_match_index))
	if match_index != reset_match_index:
		return _refused("Fresh caller `$0026` differs from the ROM reset-derived match index.")
	var completion_variant: Variant = caller_inputs.get("cutscene1_wait_return", {})
	if not completion_variant is Dictionary:
		return _refused("The `$82B5` cutscene-1 return event is missing.")
	var completion: Dictionary = completion_variant
	if not _validate_cutscene1_wait_return(completion):
		return _refused("Cutscene-1 wait return is not backed by its natural-end or Select condition.")
	var branch_state_variant: Variant = caller_inputs.get("ram_at_8145", {})
	if not branch_state_variant is Dictionary:
		return _refused("The caller-owned RAM state at `$8145` is missing.")
	var branch_state: Dictionary = branch_state_variant
	if int(branch_state.get("$0026", -1)) != match_index \
			or int(branch_state.get("$00E0", -1)) != 0xC0 \
			or String(branch_state.get("provenance", "")) != "rom_derived_caller_state":
		return _refused("`$8145` needs the source-derived `$26` and `$E0` values; trace RAM is not an input.")

	result["source_path"] = [0x80DF, 0x80E1]
	if not _consume_returns(result, source_returns, CALLS_BEFORE_MATCH_MUSIC.slice(0, 2)):
		return result

	# `$82B5` returns through the shared cleanup only when one of its own
	# source exit predicates is supplied. Preserve the exact write PCs.
	var wait_writes := _cutscene_wait_cleanup_writes()
	result["source_path"].append_array([0x80EE, 0x82B5, 0x82B7, 0x82BA, 0x82BC])
	if String(completion.get("kind", "")) == "natural":
		result["source_path"].append(0x82BE)
	if String(completion.get("kind", "")) == "select":
		result["source_path"].append_array([0x82BE, 0x82C0, 0x82C2, 0x82C4])
	result["source_path"].append(0x82C6)
	result["ram_writes"].append_array(wait_writes["ram_writes"])
	result["source_path"].append_array([0x82DA, 0x82DC])
	result["queue_events"].append(_queue_event(0x01, 0x82DC, 0x82DF, "cutscene_wait_cleanup"))
	var wait_cleanup_return := {
		"caller_pc": 0x82DF, "target_pc": 0x9BA0, "return_pc": 0x82E2,
		"call_id": "cutscene_1_wait_presentation_clear",
	}
	if not _consume_returns(result, source_returns, [wait_cleanup_return]):
		return result
	result["source_path"].append_array([0x82E4, 0x82E6, 0x82E8, 0x82EA, 0x82EC, 0x80F1])
	result["ram_writes"].append_array([
		{"source_pc": 0x82E4, "address": 0x0044, "value": 0x00},
		{"source_pc": 0x82E6, "address": 0x0045, "value": 0x00},
		{"source_pc": 0x82E8, "address": 0x007A, "value": 0x00},
		{"source_pc": 0x82EA, "address": 0x007B, "value": 0x00},
	])

	result["source_path"].append_array([0x80F3, 0x80F5])
	if not _consume_returns(result, source_returns, [CALLS_BEFORE_MATCH_MUSIC[3], CALLS_BEFORE_MATCH_MUSIC[4]]):
		return result
	result["source_path"].append_array([0x80FD, 0x80FF, 0x8101, 0x8103, 0x8105, 0x8107, 0x810A])
	result["ram_writes"].append_array([
		{"source_pc": 0x80FF, "address": 0x0028, "value": 0x00},
		{"source_pc": 0x8101, "address": 0x0029, "value": 0x00},
		{"source_pc": 0x8103, "address": 0x0027, "value": 0x00},
	])
	result["queue_events"].append(_queue_event(0x01, 0x8107, 0x810A, "fresh_match_setup_stop"))

	if not _consume_returns(result, source_returns, CALLS_BEFORE_MATCH_MUSIC.slice(5, 7)):
		return result
	result["source_path"].append(0x8112)
	if not _consume_returns(result, source_returns, [CALLS_BEFORE_MATCH_MUSIC[7]]):
		return result
	result["source_path"].append(0x8117)
	if not _consume_returns(result, source_returns, CALLS_BEFORE_MATCH_MUSIC.slice(8, 11)):
		return result
	result["source_path"].append_array([0x8122, 0x8124, 0x8126, 0x8128])
	var music_id := resolve_match_setup_music_id(match_index)
	var queue_store_pc := 0x812C
	if music_id == 0x4C:
		result["source_path"].append_array([0x812A, queue_store_pc])
	else:
		result["source_path"].append(queue_store_pc)
	result["queue_events"].append(_queue_event(music_id, queue_store_pc, 0x812F, "fresh_match_setup_music"))
	result["source_path"].append_array([0x812F, 0x8131, 0x8134, 0x8137, 0x813A, 0x813D])
	result["ram_writes"].append_array([
		{"source_pc": 0x8131, "address": 0x0450, "value": 0x00},
		{"source_pc": 0x8134, "address": 0x0451, "value": 0x00},
		{"source_pc": 0x8137, "address": 0x0452, "value": 0x00},
		{"source_pc": 0x813A, "address": 0x0453, "value": 0x00},
	])
	if not _consume_returns(result, source_returns, CALLS_AFTER_MATCH_MUSIC.slice(0, 2)):
		return result

	result["source_path"].append_array([0x8147, 0x814F, 0x8152, 0x8155])
	var cutscene_id := resolve_pre_match_cutscene_id(match_index)
	if cutscene_id == 0:
		result["source_path"].append(0x8163)
		result["status"] = "caller_return_without_cutscene_2"
		result["final_source_pc"] = 0x8163
		return result
	if not _consume_returns(result, source_returns, [CALLS_AFTER_MATCH_MUSIC[2]], cutscene_id):
		return result
	result["cutscene_dispatch_events"].append({
		"cutscene_id": cutscene_id,
		"caller_pc": 0x8157,
		"dispatch_target_pc": 0x8464,
		"return_pc": 0x815A,
		"source_rom_sha256": ROM_SHA256,
		"source_timing_verified": false,
	})
	result["pending_call"] = {"caller_pc": 0x815A, "target_pc": 0x82B5, "return_pc": 0x815D, "purpose": "cutscene_2_wait"}
	result["status"] = "cutscene_2_dispatched_wait_pending"
	result["final_source_pc"] = 0x815A
	return result


## Replays only the bytes at `$8122-$812F`. This helper never creates an event.
func resolve_match_setup_music_id(match_index: int) -> int:
	if not _configured:
		return -1
	if match_index < 0 or match_index > 0xFF:
		return -1
	var caller: PackedByteArray = _sources[CALLER_FILE]
	var immediate := int(caller[_offset(0x8122) + 1])
	var threshold := int(caller[_offset(0x8126) + 1])
	var final_id := int(caller[_offset(0x812A) + 1])
	return immediate if match_index < threshold else final_id


## Reads the pre-match cutscene byte from the ROM table at `$83DC + match_index`.
func resolve_pre_match_cutscene_id(match_index: int) -> int:
	if not _configured or match_index < 0 or match_index >= _sources[TABLE_FILE].size():
		return -1
	return int(_sources[TABLE_FILE][match_index])


func required_source_return_contract() -> Array[Dictionary]:
	var contract: Array[Dictionary] = []
	contract.append_array(CALLS_BEFORE_MATCH_MUSIC.slice(0, 2))
	contract.append({
		"caller_pc": 0x82DF, "target_pc": 0x9BA0, "return_pc": 0x82E2,
		"call_id": "cutscene_1_wait_presentation_clear",
	})
	contract.append_array(CALLS_BEFORE_MATCH_MUSIC.slice(3, 11))
	contract.append_array(CALLS_AFTER_MATCH_MUSIC)
	return contract.duplicate(true)


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"does_execute_6502": false,
		"does_execute_helper_bodies": false,
		"does_execute_wait_loop_or_yield_ticks": false,
		"does_model_stack_or_exact_cpu_timing": false,
		"uses_trace_ram_or_trace_frame_as_input": false,
		"live_runtime_integrated": false,
	}


func _new_result() -> Dictionary:
	return {
		"ok": true,
		"status": "blocked_on_source_return",
		"source_rom_sha256": ROM_SHA256,
		"source_path": [],
		"final_source_pc": 0x80DF,
		"pending_call": {},
		"queue_events": [],
		"ram_writes": [],
		"cutscene_dispatch_events": [],
		"accepted_source_returns": [],
		"helper_returns_are_external_inputs": true,
		"helper_bodies_executed": false,
		"wait_loop_timing_executed": false,
		"source_frame": -1,
		"cpu_cycle": -1,
		"timing_verified": false,
		"live_runtime_integrated": false,
	}


func _consume_returns(result: Dictionary, supplied: Array, required: Array,
		expected_cutscene_id: int = -1) -> bool:
	for call_variant in required:
		if not call_variant is Dictionary:
			continue
		var call: Dictionary = call_variant
		var found := false
		for receipt_variant in supplied:
			if not receipt_variant is Dictionary:
				continue
			var receipt: Dictionary = receipt_variant
			if int(receipt.get("caller_pc", -1)) != int(call["caller_pc"]) \
					or int(receipt.get("target_pc", -1)) != int(call["target_pc"]) \
					or int(receipt.get("return_pc", -1)) != int(call["return_pc"]) \
					or String(receipt.get("status", "")) != "returned" \
					or String(receipt.get("source_event_id", "")).is_empty():
				continue
			var required_id := int(call.get("cutscene_id", expected_cutscene_id))
			if required_id >= 0 and int(receipt.get("cutscene_id", -1)) != required_id:
				continue
			result["accepted_source_returns"].append({
				"caller_pc": int(call["caller_pc"]),
				"target_pc": int(call["target_pc"]),
				"return_pc": int(call["return_pc"]),
				"call_id": String(call.get("call_id", "")),
				"source_event_id": String(receipt["source_event_id"]),
			})
			result["source_path"].append(int(call["caller_pc"]))
			result["source_path"].append(int(call["target_pc"]))
			result["source_path"].append(int(call["return_pc"]))
			result["final_source_pc"] = int(call["return_pc"])
			found = true
			break
		if not found:
			result["status"] = "blocked_on_source_return"
			result["final_source_pc"] = int(call["caller_pc"])
			if result["source_path"].is_empty() or int(result["source_path"][-1]) != int(call["caller_pc"]):
				result["source_path"].append(int(call["caller_pc"]))
			result["pending_call"] = {
				"caller_pc": int(call["caller_pc"]),
				"target_pc": int(call["target_pc"]),
				"return_pc": int(call["return_pc"]),
				"call_id": String(call.get("call_id", "")),
			}
			return false
	return true


func _validate_cutscene1_wait_return(completion: Dictionary) -> bool:
	if int(completion.get("cutscene_id", -1)) != 1 \
			or String(completion.get("source_event_id", "")).is_empty():
		return false
	var kind := String(completion.get("kind", ""))
	if kind == "natural":
		return bool(completion.get("script_pointer_ended", false)) \
				and int(completion.get("newly_pressed_buttons", -1)) >= 0 \
				and int(completion.get("newly_pressed_buttons", 0)) <= 0xFF
	if kind == "select":
		var newly_pressed := int(completion.get("newly_pressed_buttons", -1))
		return not bool(completion.get("script_pointer_ended", false)) \
				and newly_pressed >= 0 and newly_pressed <= 0xFF \
				and (newly_pressed & 0x20) != 0
	return false


func _cutscene_wait_cleanup_writes() -> Dictionary:
	var waits: PackedByteArray = _sources[WAIT_FILE]
	var addresses: Array[int] = [0x0005, 0x0006, 0x0009, 0x000A, 0x0011, 0x0012, 0x000D, 0x000E, 0x004C]
	var writes: Array[Dictionary] = []
	for index in range(addresses.size()):
		writes.append({"source_pc": 0x82C8 + index * 2, "address": addresses[index], "value": 0})
	# Verify that the stop store is still the exact wait-subroutine instruction.
	var stop_offset := 0x82DC - 0x82B5
	if waits.slice(stop_offset, stop_offset + 3) != PackedByteArray([0x8D, 0x00, 0x07]):
		return {"ram_writes": []}
	return {"ram_writes": writes}


func _queue_event(queue_id: int, store_pc: int, post_store_pc: int, source_role: String) -> Dictionary:
	return {
		"event_id": "%s:%04X:%04X:%02X" % [source_role, store_pc, post_store_pc, queue_id],
		"event_origin": "rom_direct_queue_store",
		"source_role": source_role,
		"source_rom_sha256": ROM_SHA256,
		"queue_address": 0x0700,
		"queue_id": queue_id,
		"queue_store_instruction_pc": store_pc,
		"post_store_pc": post_store_pc,
		"source_frame": -1,
		"cpu_cycle": -1,
		"timing_verified": false,
	}


func _derive_reset_match_index() -> int:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0xFF)
	# This bounded interpreter is accepted only after `_load_reset_source` has
	# byte-checked the exact eight-page reset clear loop.
	for address in range(0x0000, 0x0800):
		ram[address] = 0
	return int(ram[0x0026])


func _load_reset_source(manifest: Dictionary) -> bool:
	var dependencies: Dictionary = {}
	for dep_variant in manifest.get("dependencies", []):
		if dep_variant is Dictionary:
			var dependency: Dictionary = dep_variant
			dependencies[String(dependency.get("path", ""))] = dependency
	var reset_relative := "../fresh_kickoff_entry_context/reset_ram_clear_C64E_C679.bin"
	if not dependencies.has(reset_relative):
		return _fail("Caller manifest omits the reset-state dependency for `$0026`.")
	var dependency: Dictionary = dependencies[reset_relative]
	if int(dependency.get("length", -1)) != RESET_SPAN_LENGTH \
			or String(dependency.get("sha256", "")) != RESET_SPAN_SHA256 \
			or String(dependency.get("cpu_start", "")) != "$C64E" \
			or String(dependency.get("file_offset", "")) != "0x03C65E":
		return _fail("Reset-state dependency metadata differs from the checked ROM span.")
	_reset_source = FileAccess.get_file_as_bytes("res://reference/rom_extract/gameplay/fresh_kickoff_entry_context/reset_ram_clear_C64E_C679.bin")
	if _reset_source.size() != RESET_SPAN_LENGTH or _sha256(_reset_source) != RESET_SPAN_SHA256:
		return _fail("Reset-state source failed its size/hash check.")
	if _reset_source.slice(25, 44) != PackedByteArray([0xA9, 0x00, 0x85, 0x00, 0x85, 0x01, 0xA8, 0xA2, 0x08, 0x91, 0x00, 0xC8, 0xD0, 0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6]):
		return _fail("Reset-state zero-fill instructions differ from the eight-page RAM clear.")
	return true


func _verify_source_semantics() -> bool:
	var caller: PackedByteArray = _sources[CALLER_FILE]
	if caller.slice(_offset(0x80DF), _offset(0x80E6)) != PackedByteArray([0x24, 0xED, 0x50, 0x03, 0x4C, 0x6A, 0x82]):
		return _fail("Title branch bytes no longer send `$ED.6=0` to fresh KICK OFF at `$80E6`.")
	if caller.slice(_offset(0x80E6), _offset(0x80F1)) != PackedByteArray([0x20, 0xA0, 0x9B, 0xA9, 0x01, 0x20, 0x64, 0x84, 0x20, 0xB5, 0x82]):
		return _fail("KICK OFF `$80E6/$80EE` caller no longer dispatches ID 1 and waits at `$82B5`.")
	if caller.slice(_offset(0x8122), _offset(0x812F)) != PackedByteArray([0xA2, 0x55, 0xA5, 0x26, 0xC9, 0x20, 0x90, 0x02, 0xA2, 0x4C, 0x8E, 0x00, 0x07]):
		return _fail("ROM `$8122-$812F` music branch/store bytes changed.")
	if caller.slice(_offset(0x8145), _offset(0x815D)) != PackedByteArray([0x24, 0xE0, 0x30, 0x06, 0xA5, 0xE4, 0xC5, 0x26, 0xB0, 0x14, 0xAE, 0x26, 0x00, 0xBD, 0xDC, 0x83, 0xF0, 0x0C, 0x20, 0x64, 0x84, 0x20, 0xB5, 0x82]):
		return _fail("ROM `$8145-$815C` pre-match cutscene branch changed.")
	var wait: PackedByteArray = _sources[WAIT_FILE]
	if wait.slice(0, 17) != PackedByteArray([0xA9, 0x01, 0x20, 0xA8, 0x9F, 0xA5, 0x4D, 0x05, 0x4E, 0xF0, 0x06, 0xA5, 0x1E, 0x29, 0x20, 0xF0, 0xEF]):
		return _fail("Select-aware wait loop `$82B5-$82C4` differs from the checked code.")
	if wait.slice(0x11, 0x38) != PackedByteArray([0xA9, 0x00, 0x85, 0x05, 0x85, 0x06, 0x85, 0x09, 0x85, 0x0A, 0x85, 0x11, 0x85, 0x12, 0x85, 0x0D, 0x85, 0x0E, 0x85, 0x4C, 0xA9, 0x01, 0x8D, 0x00, 0x07, 0x20, 0xA0, 0x9B, 0xA9, 0x00, 0x85, 0x44, 0x85, 0x45, 0x85, 0x7A, 0x85, 0x7B, 0x60]):
		return _fail("Shared wait cleanup and `$0700` stop write differ from the checked ROM bytes.")
	var table: PackedByteArray = _sources[TABLE_FILE]
	if table.is_empty() or int(table[0]) != 0x02:
		return _fail("Fresh match index zero no longer selects pre-match cutscene ID 2.")
	var mapper: PackedByteArray = _sources[MAPPER_FILE]
	if mapper != PackedByteArray([0x86, 0x25, 0xA9, 0x07, 0x05, 0x22, 0x85, 0x23, 0x8D, 0x00, 0x80, 0x8E, 0x01, 0x80, 0x60]):
		return _fail("Fixed-bank `$C4B9` mapper helper bytes changed.")
	return true


func _caller_imm8(address: int) -> int:
	var caller: PackedByteArray = _sources[CALLER_FILE]
	return int(caller[_offset(address) + 1])


func _offset(address: int) -> int:
	return address - 0x80DF


func _refused(reason: String) -> Dictionary:
	var result := _new_result()
	result["ok"] = false
	result["status"] = "refused"
	result["error"] = reason
	error_message = reason
	return result


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
