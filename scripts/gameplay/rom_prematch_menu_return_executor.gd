extends RefCounted
class_name RomPrematchMenuReturnExecutor
## Resolves the source-owned return from the confirmed pre-match Start option.
## It validates ROM call/branch bytes and live source receipts; it does not run
## the 6502, the `$82A9` wait loop, or physical CPU timing.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MEETING_ROOT := "res://reference/rom_extract/gameplay/meeting_menu/"
const MEETING_MANIFEST := MEETING_ROOT + "manifest.json"
const RETURN_MANIFEST := MEETING_ROOT + "prematch_menu_return_manifest.json"
const CALLER_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const CALLER_MANIFEST := CALLER_ROOT + "manifest.json"
const SCENE56_EVENTS := "res://assets/gameplay/rom_logic/kickoff_meeting_scene_56_events.json"
const SCENE56_STREAM := "res://reference/rom_extract/gameplay/meeting_menu/scene_56_execution.bin"

const EXPECTED_SCENE56_MANIFEST_SHA256 := "05422d6c42961d411deb1e164fb880bd08873e3a03e32fdaf539eed304b53161"
const EXPECTED_SCENE56_STREAM_SHA256 := "d656d678df10757989b518e895a25b05f3cd335664d2df9aa45832fbf33e1536"
const EXPECTED_SCENE56_EVENT_COUNT := 17
const CUTSCENE_FINISHED_STATE := KickoffCutsceneCommandVm.RunState.FINISHED

const MEETING_CONTROLLER_FILE := "bank1_meeting_menu_controller.bin"
const MEETING_CONTROLLER_SHA256 := "c6d8c67c6ad487c11946a136fd6955f7aacd5630d77609db8a7a942b49e66482"
const KICKOFF_TABLE_FILE := "bank1_option_kickoff_match_table.bin"
const KICKOFF_TABLE_SHA256 := "dc2ac411fe0222f6c1c84d04ec7bbbc8bf207613032ebb38ee42c6ff77b2ab42"

const CALLER_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const CALLER_SHA256 := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const PREMATCH_TABLE_FILE := "bank00_pre_match_cutscene_ids_83DC_83FC.bin"
const PREMATCH_TABLE_SHA256 := "c0e1023552ed03cbf1e741956f76bdef150143848197a8da5e5000508bad2051"
const SELECT_WAIT_FILE := "bank00_select_wait_82B5_82EC.bin"
const SELECT_WAIT_SHA256 := "6b894cd9f7a0b4e6927ce98c739672b5d79627b5e138a0257898f94793a75b5c"

const NATURAL_WAIT_FILE := "bank00_natural_cutscene_wait_82A9_82B4.bin"
const NATURAL_WAIT_SHA256 := "a5de1ba379876bdf1ff68c417244633c5369e18506648a54ac6efa470d1e2e29"
const DISPATCHER_FILE := "bank00_cutscene_dispatcher_8464_84A5.bin"
const DISPATCHER_SHA256 := "5751805c7996638a8c0683ea13ae991ad88583b1703833048c9b595a9293c6ce"
const MENU_RETURN_FILE := "bank01_menu_return_tail_A715_A718.bin"
const MENU_RETURN_SHA256 := "28348feb92ef3e1b713a5ebced7f9eda134ad83b316442e0a981cb208eab915a"

const EXPECTED_CALLER_WINDOW := [
	0x24, 0xE0, 0x30, 0x06, 0xA5, 0xE4, 0xC5, 0x26, 0xB0, 0x14,
	0xAE, 0x26, 0x00, 0xBD, 0xDC, 0x83, 0xF0, 0x0C, 0x20, 0x64,
	0x84, 0x20, 0xB5, 0x82,
]
const EXPECTED_NATURAL_WAIT := [
	0xA9, 0x01, 0x20, 0xA8, 0x9F, 0xA5, 0x4D, 0x05, 0x4E, 0xD0, 0xF5, 0x60,
]
const EXPECTED_SELECT_WAIT_PREFIX := [
	0xA9, 0x01, 0x20, 0xA8, 0x9F, 0xA5, 0x4D, 0x05, 0x4E, 0xF0, 0x06,
	0xA5, 0x1E, 0x29, 0x20, 0xF0, 0xEF,
]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	if not _load_meeting_sources() or not _load_caller_sources() \
			or not _load_return_source_manifest() or not _verify_source_semantics() \
			or not _verify_scene56_manifest():
		return false
	_configured = true
	return true


## Call only after `option_confirmed` for the ROM Start row and natural VM exit.
## The returned object describes the next source dispatch; it does not claim
## that the wait, dispatcher worker, or CPU return has executed in Godot.
func resolve_after_scene56(confirmed_option_index: int,
		vm: KickoffCutsceneCommandVm, a009_transfer_receipt: Dictionary,
		source_ram: RomSourceRamImage) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if confirmed_option_index != 3:
		return _refused("The source return is only defined here for confirmed MEETING option index 3 (Start).")
	if not _validate_scene56_vm_completion(vm):
		return _refused(error_message)
	if not _validate_a009_return_frame(a009_transfer_receipt):
		return _refused(error_message)
	var source_state := _read_live_caller_state(source_ram)
	if not bool(source_state.get("ok", false)):
		return _refused(String(source_state.get("error", "ROM-derived caller RAM is unavailable.")))

	var match_index := int(source_state["match_index"])
	var scene_id := int(_sources[KICKOFF_TABLE_FILE][match_index])
	if scene_id != 0x56 or int(vm.cutscene_id) != scene_id:
		return _refused("The confirmed Start branch does not resolve to the VM's ROM-selected scene `$56`.")
	var e0_value := int(source_state["mode_e0"])
	if (e0_value & 0x80) == 0:
		return _refused("The verified `$8145` path is not the fresh-match BMI branch; its alternate `$E4` path is outside this receipt.")
	var id2 := int(_sources[PREMATCH_TABLE_FILE][match_index])
	if id2 != 0x02:
		return _refused("The source table at `$83DC[$%02X]` does not dispatch the required ID `$02`." % match_index)

	var source_path: Array[int] = [
		0xA6C4, 0xA6C9, 0x8464, 0xA6CC, 0x82A9, 0xA6CF, 0xA715, 0x9BA0, 0xA718,
		0x8145, 0x8147, 0x814F, 0x8152, 0x8155, 0x8157,
	]
	return {
		"ok": true,
		"status": "id2_dispatch_wait_contract_ready",
		"source_rom_sha256": ROM_SHA256,
		"confirmed_option_index": confirmed_option_index,
		"confirmed_option_offset": confirmed_option_index * 2,
		"scene56_completion": {
			"cutscene_id": 0x56,
			"completion": "natural_rom_ff_terminator",
			"terminator_event_index": vm.current_event_index,
			"terminator_cpu_address": vm.current_source_address,
		},
		"a64c_caller_return": {
			"caller_pc": 0x8142,
			"entry_pc": 0xA009,
			"jump_target_pc": 0xA64C,
			"logical_return_pc": 0x8145,
			"logical_stack_frame": a009_transfer_receipt["logical_stack_frame"].duplicate(true),
			"return_model": "logical_rom_jsr_frame; physical stack page/cycles not executed",
		},
		"scene56_return": {
			"scene_source_entry_pc": 0xBFBA,
			"shared_tail_pc": 0xBFD5,
			"scene_selection_lookup_pc": 0xA6C4,
			"dispatcher_call_pc": 0xA6C9,
			"dispatcher_operand_low_byte_pc": 0xA6CA,
			"natural_wait_call_pc": 0xA6CC,
			"natural_wait_operand_low_byte_pc": 0xA6CD,
			"natural_wait_target_pc": 0x82A9,
			"cleanup_tail_jump_pc": 0xA6CF,
			"cleanup_tail_target_pc": 0xA715,
			"cleanup_helper_pc": 0x9BA0,
			"returns_to_logical_pc": 0x8145,
			"wait_loop_executed": false,
			"cleanup_effects_executed": false,
		},
		"match_index": match_index,
		"match_index_source_write": source_state["match_index_write"],
		"mode_e0": e0_value,
		"id2_dispatch_receipt": {
			"cutscene_id": id2,
			"table_address": 0x83DC + match_index,
			"table_value": id2,
			"caller_pc": 0x8157,
			"target_pc": 0x8464,
			"return_pc": 0x815A,
			"dispatch_executed": false,
		},
		"wait_contract": {
			"caller_pc": 0x815A,
			"target_pc": 0x82B5,
			"return_pc": 0x815D,
			"kind": "select_aware_cutscene_wait",
			"source_tests": ["$4D|$4E == 0", "fresh `$001E & $20` Select edge"],
			"wait_loop_executed": false,
		},
		"source_path_contract": source_path,
		"source_frame": -1,
		"cpu_cycle": -1,
		"cpu_timing_verified": false,
		"executes_6502": false,
		"uses_trace_ram": false,
		"uses_emulator_data": false,
		"live_runtime_integrated": false,
	}


func _load_meeting_sources() -> bool:
	var manifest := _read_manifest(MEETING_MANIFEST)
	if manifest.is_empty() or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("MEETING source manifest targets another ROM or is malformed.")
	var entries := _index_manifest_entries(manifest, "files")
	var controller := _load_manifest_span(entries, MEETING_ROOT, MEETING_CONTROLLER_FILE, {
		"prg_bank": 1,
		"cpu_range_inclusive_start_exclusive_end": ["$A64C", "$A6D2"],
		"rom_file_range_inclusive_start_exclusive_end": ["0x00265C", "0x0026E2"],
		"length_bytes": 134,
		"sha256": MEETING_CONTROLLER_SHA256,
	})
	if controller.is_empty():
		return false
	var kickoff_table := _load_manifest_span(entries, MEETING_ROOT, KICKOFF_TABLE_FILE, {
		"prg_bank": 1,
		"cpu_range_inclusive_start_exclusive_end": ["$B41B", "$B43D"],
		"rom_file_range_inclusive_start_exclusive_end": ["0x00342B", "0x00344D"],
		"length_bytes": 34,
		"sha256": KICKOFF_TABLE_SHA256,
	})
	if kickoff_table.is_empty():
		return false
	_sources[MEETING_CONTROLLER_FILE] = controller
	_sources[KICKOFF_TABLE_FILE] = kickoff_table
	return true


func _load_caller_sources() -> bool:
	var manifest := _read_manifest(CALLER_MANIFEST)
	var rom: Dictionary = {}
	if not manifest.is_empty():
		rom = manifest.get("rom", {})
	if manifest.is_empty() or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh KICK OFF caller manifest targets another ROM or is malformed.")
	var entries := _index_manifest_entries(manifest, "spans")
	var caller := _load_manifest_span(entries, CALLER_ROOT, CALLER_FILE, {
		"cpu_start": "$80DF", "cpu_end_exclusive": "$815D", "file_offset": "0x0000EF",
		"length": 126, "sha256": CALLER_SHA256,
	})
	if caller.is_empty():
		return false
	var prematch_table := _load_manifest_span(entries, CALLER_ROOT, PREMATCH_TABLE_FILE, {
		"cpu_start": "$83DC", "cpu_end_exclusive": "$83FD", "file_offset": "0x0003EC",
		"length": 33, "sha256": PREMATCH_TABLE_SHA256,
	})
	if prematch_table.is_empty():
		return false
	var select_wait := _load_manifest_span(entries, CALLER_ROOT, SELECT_WAIT_FILE, {
		"cpu_start": "$82B5", "cpu_end_exclusive": "$82ED", "file_offset": "0x0002C5",
		"length": 56, "sha256": SELECT_WAIT_SHA256,
	})
	if select_wait.is_empty():
		return false
	_sources[CALLER_FILE] = caller
	_sources[PREMATCH_TABLE_FILE] = prematch_table
	_sources[SELECT_WAIT_FILE] = select_wait
	return true


func _load_return_source_manifest() -> bool:
	var manifest := _read_manifest(RETURN_MANIFEST)
	if manifest.is_empty() or String(manifest.get("schema", "")) != "ct2-prematch-menu-return-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(manifest.get("source_rom_size_bytes", -1)) != 393232:
		return _fail("Prematch return source manifest targets another ROM or is malformed.")
	var entries := _index_manifest_entries(manifest, "files")
	var natural_wait := _load_manifest_span(entries, MEETING_ROOT, NATURAL_WAIT_FILE, {
		"prg_bank": 0, "cpu_start": "$82A9", "cpu_end_exclusive": "$82B5",
		"rom_file_range_inclusive_start_exclusive_end": ["0x0002B9", "0x0002C5"],
		"length_bytes": 12, "sha256": NATURAL_WAIT_SHA256,
	})
	if natural_wait.is_empty():
		return false
	var dispatcher := _load_manifest_span(entries, MEETING_ROOT, DISPATCHER_FILE, {
		"prg_bank": 0, "cpu_start": "$8464", "cpu_end_exclusive": "$84A5",
		"rom_file_range_inclusive_start_exclusive_end": ["0x000474", "0x0004B5"],
		"length_bytes": 65, "sha256": DISPATCHER_SHA256,
	})
	if dispatcher.is_empty():
		return false
	var menu_return := _load_manifest_span(entries, MEETING_ROOT, MENU_RETURN_FILE, {
		"prg_bank": 1, "cpu_start": "$A715", "cpu_end_exclusive": "$A719",
		"rom_file_range_inclusive_start_exclusive_end": ["0x002725", "0x002729"],
		"length_bytes": 4, "sha256": MENU_RETURN_SHA256,
	})
	if menu_return.is_empty():
		return false
	_sources[NATURAL_WAIT_FILE] = natural_wait
	_sources[DISPATCHER_FILE] = dispatcher
	_sources[MENU_RETURN_FILE] = menu_return
	return true


func _verify_source_semantics() -> bool:
	var controller: PackedByteArray = _sources[MEETING_CONTROLLER_FILE]
	if controller.slice(0x78, 0x80) != PackedByteArray([0xA6, 0x26, 0xBD, 0x1B, 0xB4, 0x20, 0x64, 0x84]):
		return _fail("ROM `$A6C4-$A6CB` no longer looks up `tbl_B41B[$26]` and calls `$8464`.")
	if controller.slice(0x7E, 0x81) != PackedByteArray([0x64, 0x84, 0x20]):
		return _fail("ROM `$A6CA` dispatcher operand bytes no longer lead into the natural wait call.")
	if controller.slice(0x80, 0x83) != PackedByteArray([0x20, 0xA9, 0x82]):
		return _fail("ROM `$A6CC` no longer calls the natural `$82A9` waiter.")
	if controller.slice(0x83, 0x86) != PackedByteArray([0x4C, 0x15, 0xA7]):
		return _fail("ROM `$A6CF` no longer tail-jumps to `$A715`.")
	if _sources[MENU_RETURN_FILE] != PackedByteArray([0x20, 0xA0, 0x9B, 0x60]):
		return _fail("ROM `$A715-$A718` no longer calls `$9BA0` then RTS.")
	if _sources[NATURAL_WAIT_FILE] != PackedByteArray(EXPECTED_NATURAL_WAIT):
		return _fail("ROM `$82A9-$82B4` natural waiter bytes changed.")
	var dispatcher: PackedByteArray = _sources[DISPATCHER_FILE]
	if dispatcher.slice(0x3E, 0x41) != PackedByteArray([0x20, 0x69, 0x9F]):
		return _fail("ROM `$8464` dispatcher no longer installs the worker through `$9F69`.")
	var caller: PackedByteArray = _sources[CALLER_FILE]
	var caller_offset := 0x8145 - 0x80DF
	if caller.slice(caller_offset, caller_offset + EXPECTED_CALLER_WINDOW.size()) != PackedByteArray(EXPECTED_CALLER_WINDOW):
		return _fail("ROM `$8145-$815C` branch, table lookup, ID-$02 dispatch, or `$815A` wait call changed.")
	if caller.slice(0x80F1 - 0x80DF, 0x80F1 - 0x80DF + 4) \
			!= PackedByteArray([0xA9, 0xC0, 0x85, 0xE0]):
		return _fail("The caller's source `$80F3 STA $E0` value is no longer `$C0`.")
	var select_wait: PackedByteArray = _sources[SELECT_WAIT_FILE]
	if select_wait.slice(0, EXPECTED_SELECT_WAIT_PREFIX.size()) != PackedByteArray(EXPECTED_SELECT_WAIT_PREFIX):
		return _fail("ROM `$82B5` Select-aware wait contract bytes changed.")
	return true


func _verify_scene56_manifest() -> bool:
	var manifest_bytes := FileAccess.get_file_as_bytes(SCENE56_EVENTS)
	if manifest_bytes.is_empty() or _sha256(manifest_bytes) != EXPECTED_SCENE56_MANIFEST_SHA256:
		return _fail("Scene-$56 VM event manifest failed its source hash check.")
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return _fail("Scene-$56 VM event manifest is malformed.")
	var manifest: Dictionary = parsed
	var events: Variant = manifest.get("events", null)
	if String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(manifest.get("source_execution_stream_sha256", "")) != EXPECTED_SCENE56_STREAM_SHA256 \
			or String(manifest.get("source_resource", "")) != "reference/rom_extract/gameplay/meeting_menu/scene_56_execution.bin" \
			or int(manifest.get("event_count", -1)) != EXPECTED_SCENE56_EVENT_COUNT \
			or not events is Array or events.size() != EXPECTED_SCENE56_EVENT_COUNT:
		return _fail("Scene-$56 event manifest no longer identifies the byte-verified ROM execution stream.")
	var final_event: Dictionary = events[events.size() - 1]
	var final_raw: Variant = final_event.get("raw_bytes", null)
	if String(final_event.get("kind", "")) != "exit" \
			or int(final_event.get("opcode", -1)) != 0xFF \
			or int(final_event.get("cpu_address", -1)) != 0xBFF3 \
			or not final_raw is Array or final_raw.size() != 1 or int(final_raw[0]) != 0xFF:
		return _fail("Scene-$56 manifest no longer ends at ROM `$BFF3` with `$FF`.")
	var stream := FileAccess.get_file_as_bytes(SCENE56_STREAM)
	if stream.is_empty() or _sha256(stream) != EXPECTED_SCENE56_STREAM_SHA256:
		return _fail("Scene-$56 flattened ROM execution stream failed its source hash check.")
	return true


func _validate_scene56_vm_completion(vm: KickoffCutsceneCommandVm) -> bool:
	if vm == null or int(vm.cutscene_id) != 0x56 or vm.state != CUTSCENE_FINISHED_STATE:
		return _fail("The live command VM must be naturally finished on scene `$56`.")
	var events: Array = JSON.parse_string(FileAccess.get_file_as_string(SCENE56_EVENTS)).get("events", [])
	if events.is_empty():
		return _fail("Scene-$56 terminator event is unavailable.")
	var final_event: Dictionary = events[events.size() - 1]
	var active_event: Dictionary = vm.get_active_event()
	var manifest_raw: Variant = final_event.get("raw_bytes", null)
	var active_raw: Variant = active_event.get("raw_bytes", null)
	if int(vm.current_event_index) != int(final_event.get("event_index", -1)) \
			or int(vm.current_source_address) != int(final_event.get("cpu_address", -1)) \
			or String(active_event.get("kind", "")) != "exit" \
			or int(active_event.get("opcode", -1)) != 0xFF \
			or not manifest_raw is Array or manifest_raw.size() != 1 or int(manifest_raw[0]) != 0xFF \
			or not active_raw is Array or active_raw.size() != 1 or int(active_raw[0]) != 0xFF:
		return _fail("The VM completion does not end on scene-$56's ROM `$FF` event.")
	return true


func _validate_a009_return_frame(receipt: Dictionary) -> bool:
	if not bool(receipt.get("ok", false)) \
			or String(receipt.get("status", "")) != "transferred_to_prematch_body" \
			or String(receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(receipt.get("caller_pc", -1)) != 0x8142 \
			or int(receipt.get("entry_pc", -1)) != 0xA009 \
			or int(receipt.get("target_pc", -1)) != 0xA64C \
			or int(receipt.get("return_pc", -1)) != 0x8145 \
			or String(receipt.get("entry_bytes", "")) != "4c4ca6":
		return _fail("The saved `$8142->$A009->$A64C` caller-transfer receipt is missing or mismatched.")
	var frame: Dictionary = receipt.get("logical_stack_frame", {})
	var source_call: Dictionary = receipt.get("source_call", {})
	var source_frame: Dictionary = source_call.get("logical_stack_frame", {})
	var event_id := String(receipt.get("source_call", {}).get("source_event_id", ""))
	if event_id.is_empty() \
			or String(frame.get("kind", "")) != "rom_jsr" \
			or int(frame.get("caller_pc", -1)) != 0x8142 \
			or int(frame.get("target_pc", -1)) != 0xA009 \
			or int(frame.get("return_word", -1)) != 0x8144 \
			or int(frame.get("return_pc", -1)) != 0x8145 \
			or String(frame.get("source_event_id", "")) != event_id \
			or int(source_call.get("caller_pc", -1)) != 0x8142 \
			or int(source_call.get("target_pc", -1)) != 0xA009 \
			or int(source_call.get("return_pc", -1)) != 0x8145 \
			or source_frame != frame:
		return _fail("The pending logical `$8142` JSR frame does not return to `$8145`.")
	var path: Variant = receipt.get("source_path", [])
	if not path is Array or path != [0x8142, 0xA009, 0xA64C]:
		return _fail("The A009 receipt does not preserve the exact source JMP path.")
	return true


func _read_live_caller_state(source_ram: RomSourceRamImage) -> Dictionary:
	if source_ram == null:
		return {"ok": false, "error": "The sparse ROM source RAM image is missing."}
	var status: Dictionary = source_ram.get_status()
	if String(status.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(status.get("status", "")) != "sparse_source_writes_only" \
			or bool(status.get("executes_6502", true)):
		return {"ok": false, "error": "The caller RAM image is not the project's source-only sparse ledger."}
	var match_byte: Dictionary = source_ram.get_byte(0x0026)
	var e0_byte: Dictionary = source_ram.get_byte(0x00E0)
	if not bool(match_byte.get("known", false)) or not bool(e0_byte.get("known", false)):
		return {"ok": false, "error": "Source RAM `$0026/$00E0` must be known from ROM executor writes."}
	var match_write: Dictionary = match_byte.get("last_write", {})
	var e0_write: Dictionary = e0_byte.get("last_write", {})
	if String(match_write.get("event_id", "")).is_empty() \
			or int(match_write.get("source_pc", -1)) < 0 \
			or int(match_write.get("value", -1)) != int(match_byte.get("value", -1)):
		return {"ok": false, "error": "Match index `$0026` lacks source-write provenance."}
	if int(e0_byte.get("value", -1)) != 0xC0 \
			or int(e0_write.get("source_pc", -1)) != 0x80F3 \
			or String(e0_write.get("event_id", "")).is_empty():
		return {"ok": false, "error": "Fresh-match `$00E0=$C0` must come from the checked caller store at `$80F3`."}
	var match_index := int(match_byte.get("value", -1))
	if match_index < 0 or match_index >= _sources[KICKOFF_TABLE_FILE].size() \
			or match_index >= _sources[PREMATCH_TABLE_FILE].size():
		return {"ok": false, "error": "ROM-derived match index is outside the source tables."}
	return {"ok": true, "match_index": match_index,
		"match_index_write": match_write.duplicate(true), "mode_e0": int(e0_byte.get("value", -1)),
		"mode_e0_write": e0_write.duplicate(true)}


func _read_manifest(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}


func _index_manifest_entries(manifest: Dictionary, collection_key: String) -> Dictionary:
	var entries: Dictionary = {}
	var rows: Variant = manifest.get(collection_key, [])
	if not rows is Array:
		return entries
	for row_variant in rows:
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			entries[String(row.get("file", ""))] = row
	return entries


func _load_manifest_span(entries: Dictionary, resource_root: String,
		file_name: String, expected: Dictionary) -> PackedByteArray:
	if not entries.has(file_name):
		_fail("ROM source manifest omits `%s`." % file_name)
		return PackedByteArray()
	var entry: Dictionary = entries[file_name]
	for key: String in expected:
		if entry.get(key, null) != expected[key]:
			_fail("ROM source manifest metadata differs for `%s` (%s)." % [file_name, key])
			return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(resource_root + file_name)
	var expected_hash := String(expected.get("sha256", ""))
	var expected_length := int(expected.get("length", expected.get("length_bytes", -1)))
	if bytes.size() != expected_length or _sha256(bytes) != expected_hash:
		_fail("ROM source span `%s` failed its size/hash check." % file_name)
		return PackedByteArray()
	if entry.has("bytes") and String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
		_fail("ROM source manifest byte listing disagrees with `%s`." % file_name)
	return bytes


func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _refused(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_state_required_or_mismatch", "error": reason}


func _fail(reason: String) -> bool:
	error_message = reason
	return false
