extends RefCounted
class_name RomFreshMatchHandoffExecutor
## Bounded, ROM-hash-checked projection of the fresh KICK OFF return path.
## This emits source-derived write/effect plans; it is not a general 6502 core.
## The four synchronous presentation-helper returns are explicit caller inputs.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_match_handoff/"
const MANIFEST_PATH := ROOT + "manifest.json"
const TASK_CONTEXT_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const TASK_CLEAR_MANIFEST_PATH := TASK_CONTEXT_ROOT + "manifest.json"
const TASK_CLEAR_FILE := "fixed_task_slot_clear_C6BE_C6E7.bin"
const TASK_CLEAR_SHA256 := "4e62f14d490b37ece22e2cec5f55846ddbb6235efa54100634602c20cb29f73e"
const TASK_CLEAR_LENGTH := 42

const SOURCE_SPANS := {
	"cutscene_common_cleanup": {
		"file": "bank00_cutscene2_common_cleanup_82C6_82EC.bin",
		"offset": 0x0002D6, "length": 39,
		"sha256": "85b5b1d400f0de2b0a31edc631a8768b18d3db8bc1ef92ab59beb8167dfca0ab",
	},
	"cutscene_return_caller": {
		"file": "bank00_cutscene2_return_caller_815D_8165.bin",
		"offset": 0x00016D, "length": 9,
		"sha256": "b8a1c1302e0f9c290d7fb6202291e84bafc5d0184e75a5eb32ab45ec9b1a236d",
	},
	"fresh_match_entry": {
		"file": "bank00_fresh_match_entry_8017_801E.bin",
		"offset": 0x000027, "length": 8,
		"sha256": "59dd0892f96bec849bd29a0a9cbce56298383463b36a04bbd47a9a1f82b4d1c2",
	},
	"mapper_bank_select": {
		"file": "fixed_mapper_bank_select_C4B9_C4C7.bin",
		"offset": 0x03C4C9, "length": 15,
		"sha256": "a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12",
	},
	"fresh_match_trampoline": {
		"file": "bank82_fresh_match_trampoline_A203_A205.bin",
		"offset": 0x004213, "length": 3,
		"sha256": "de965b3756cc66c3d63e12d7ac3ae0fb8ea0587d692a9c43fb58919cab462abd",
	},
	"fresh_match_setup": {
		"file": "bank82_fresh_match_setup_A2AF_A2E7.bin",
		"offset": 0x0042BF, "length": 57,
		"sha256": "cf3001b1d6b6413c2b69aa9c00b8383ccaa8a034cfd61ca1e6ebbfd97da03f45",
	},
	"zero_fill_helper": {
		"file": "bank82_zero_fill_AA06_AA1E.bin",
		"offset": 0x004A16, "length": 25,
		"sha256": "b4087f492a7a3ffb3737c7a42fd1b7fe5cf82147eab7c80eddc331740b6c38fd",
	},
	"scheduler_handoff": {
		"file": "fixed_scheduler_handoff_C557_C559.bin",
		"offset": 0x03C567, "length": 3,
		"sha256": "1db275461fac8ba20e31cc6e9fe2941b8f41e31db43f7f6d1d44d594b19df6ca",
	},
}

const HELPER_CALLS := [
	{"helper_id": "cutscene_cleanup_9ba0", "source_pc": 0x82DF, "target_pc": 0x9BA0},
	{"helper_id": "fresh_setup_palette_fade_99f0", "source_pc": 0xA2AF, "target_pc": 0x99F0},
	{"helper_id": "fresh_setup_ppu_clear_98a0", "source_pc": 0xA2B2, "target_pc": 0x98A0},
	{"helper_id": "fresh_setup_oam_clear_9b7f", "source_pc": 0xA2B5, "target_pc": 0x9B7F},
]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _task_clear_source := PackedByteArray()


static func source_span_specs() -> Dictionary:
	return SOURCE_SPANS.duplicate(true)


## Plans only the shared $82B5 return prefix for either title cutscene. It
## stops at the live $82DF->$9BA0 call and never accepts a synthetic helper
## receipt as execution evidence.
func plan_cutscene_wait_cleanup(cutscene_id: int, completion_kind: String) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(completion_kind, error_message)
	if cutscene_id not in [1, 2]:
		return _refused(completion_kind, "Expected title cutscene ID 1 or 2.")
	if completion_kind != "natural" and completion_kind != "select":
		return _refused(completion_kind, "Unsupported completion kind; expected natural or select.")
	var result := _new_result(completion_kind)
	result["cutscene_id"] = cutscene_id
	result["caller_return_pc_after_helper"] = 0x80F1 if cutscene_id == 1 else 0x815D
	_append_cutscene_cleanup_writes(result)
	result["source_path"].append_array([0x82C6, 0x82DF])
	_accept_helper_result(result, [], 0)
	result["status"] = "blocked_on_helper"
	result["ok"] = true
	result["next_step"] = "Execute the live $9BA0 effects before returning to the caller."
	return result


## Loads project-owned source bytes only; the ROM and emulator are not runtime
## inputs. The task-slot initializer is loaded from its existing verified span.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Fresh-match handoff manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Fresh-match handoff manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Handoff manifest targets a different ROM revision.")
	var entries_by_file: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for key: String in SOURCE_SPANS:
		var spec: Dictionary = SOURCE_SPANS[key]
		var file_name := String(spec["file"])
		if not entries_by_file.has(file_name):
			return _fail("Handoff manifest omits %s." % file_name)
		var manifest_entry: Dictionary = entries_by_file[file_name]
		if int(manifest_entry.get("length", -1)) != int(spec["length"]) \
				or String(manifest_entry.get("file_offset", "")) != "0x%06X" % int(spec["offset"]) \
				or String(manifest_entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Manifest offset/length/hash differs for %s." % file_name)
		var bytes := FileAccess.get_file_as_bytes(ROOT + file_name)
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]):
			return _fail("Preserved ROM source failed its size/hash check: %s." % file_name)
		_sources[key] = bytes
	if not _load_task_clear_source():
		return false
	if not _verify_source_recipes():
		return false
	_configured = true
	return true


## Follows cutscene-2 natural completion or Select completion into the fresh
## match setup. `helper_results` are named Godot-side effect receipts, not proof
## that the corresponding helper's 6502 body ran. Without a valid receipt this
## returns the exact pending source PC and does not claim `$C557` was reached.
## All write arrays are cumulative source-derived plans for the caller to apply.
func execute_cutscene2_return(completion_kind: String,
		helper_results: Array = []) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(completion_kind, error_message)
	if completion_kind != "natural" and completion_kind != "select":
		return _refused(completion_kind, "Unsupported completion kind; expected natural or select.")
	var result := _new_result(completion_kind)
	_append_cutscene_cleanup_writes(result)
	result["source_path"].append(0x82C6)
	result["source_path"].append(0x82DF)
	if not _accept_helper_result(result, helper_results, 0):
		return result

	_append_cutscene_post_helper_writes(result)
	result["source_path"].append_array([0x82EC, 0x815D, 0x8163, 0x8017, 0x8019, 0xC4B9, 0x801C, 0xA203, 0xA2AF])
	result["ram_operations"].append({
		"source_pc": 0x815D, "address": 0x00E0, "operation": "and_immediate",
		"operand": 0x7F, "result_value": null,
		"reason": "Incoming $00E0 is caller-owned; ROM masks bit 7.",
	})
	_append_mapper_bank_select(result)

	for helper_index in range(1, HELPER_CALLS.size()):
		var call: Dictionary = HELPER_CALLS[helper_index]
		result["source_pc"] = int(call["source_pc"])
		result["pending_source_pc"] = int(call["source_pc"])
		result["pending_helper_id"] = String(call["helper_id"])
		if not _accept_helper_result(result, helper_results, helper_index):
			return result
		if helper_index < HELPER_CALLS.size() - 1:
			result["source_path"].append(int(HELPER_CALLS[helper_index + 1]["source_pc"]))

	_append_fresh_setup_effects(result)
	result["source_path"].append_array([0xA2DE, 0xA2E2, 0xAA06, 0xA2E5, 0xC557, 0xC6BE])
	result["source_pc"] = 0xC6BE
	result["final_source_pc"] = 0xC6BE
	result["pending_source_pc"] = 0xC6BE
	result["pending_helper_id"] = ""
	result["c557_source_pc"] = 0xC557
	result["c557_reached"] = true
	result["status"] = "modeled_handoff_reached"
	result["ok"] = true
	result["pending_task_writes"] = _pending_task_slot_writes()
	result["c557_reached_in_live_runtime"] = false
	result["c557_is_reached_in_this_source_plan_only"] = true
	result["pending_next_call"] = {
		"source_pc": 0xC6E5, "target_pc": 0xCF1F,
		"status": "not modeled; runs after the pending C6BE task-slot stores.",
	}
	result["next_step"] = "$C6BE task-slot stores are pending, followed by the unmodeled $CF1F helper."
	return result


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"does_execute_6502": false,
		"does_execute_presentation_helpers": false,
		"does_apply_effects_to_live_ram": false,
		"requires_named_godot_helper_results": true,
	}


func _new_result(completion_kind: String) -> Dictionary:
	return {
		"ok": true,
		"status": "blocked_on_helper",
		"completion_kind": completion_kind,
		"rom_sha256": ROM_SHA256,
		"source_pc": 0x82DF,
		"final_source_pc": 0x82DF,
		"pending_source_pc": 0x82DF,
		"pending_helper_id": "",
		"source_path": [],
		"task_writes": [],
		"zero_fill_writes": [],
		"ram_writes": [],
		"ram_operations": [],
		"ppu_events": [],
		"mapper_events": [],
		"audio_stop_request": null,
		"pending_task_writes": [],
		"c557_reached": false,
		"c557_reached_in_live_runtime": false,
		"c557_is_reached_in_this_source_plan_only": false,
		"accepted_helper_results": [],
		"helper_results_are_external_effect_receipts": true,
		"helper_bytecode_executed": false,
		"source_effects_applied_by_executor": false,
		"does_execute_6502": false,
		"unresolved_state": ["Incoming $00E0 and $0020 values for source AND operations."],
	}


func _append_cutscene_cleanup_writes(result: Dictionary) -> void:
	var addresses: Array[int] = [0x0005, 0x0006, 0x0009, 0x000A, 0x0011, 0x0012, 0x000D, 0x000E, 0x004C]
	for index in range(addresses.size()):
		result["task_writes"].append({
			"source_pc": 0x82C8 + index * 2,
			"address": addresses[index], "value": 0, "applied": false,
		})
	result["audio_stop_request"] = {
		"source_pc": 0x82DC,
		"queue_address": 0x0700,
		"value": 0x01,
		"meaning": "ROM common completion cleanup stop/control request.",
		"applied": false,
	}


func _append_cutscene_post_helper_writes(result: Dictionary) -> void:
	var addresses: Array[int] = [0x0044, 0x0045, 0x007A, 0x007B]
	for index in range(addresses.size()):
		result["task_writes"].append({
			"source_pc": 0x82E4 + index * 2,
			"address": addresses[index], "value": 0, "applied": false,
		})


func _append_mapper_bank_select(result: Dictionary) -> void:
	result["ram_writes"].append({"source_pc": 0xC4B9, "address": 0x0025, "value": 0x02, "applied": false})
	result["ram_operations"].append({
		"source_pc": 0xC4BD, "address": 0x0023, "operation": "or_immediate_from_ram",
		"left_address": 0x0022, "operand": 0x07, "result_value": null,
		"reason": "Mapper select byte retains the source $0022 shadow bits.",
	})
	result["ram_writes"].append({
		"source_pc": 0xC4BF, "address": 0x0023,
		"value_expression": "$0022 | $07", "applied": false,
	})
	result["mapper_events"].append({
		"source_pc": 0xC4C1, "address": 0x8000,
		"value_expression": "$0022 | $07", "selected_register": 0x07,
		"effect": "MMC3 PRG bank-select register write.", "applied": false,
	})
	result["mapper_events"].append({
		"source_pc": 0xC4C4, "address": 0x8001, "value": 0x02,
		"effect": "Select bank 2 for the $A000-$BFFF window used by $A203.",
		"applied": false,
	})


func _append_fresh_setup_effects(result: Dictionary) -> void:
	result["source_path"].append(0xA2B8)
	result["ram_operations"].append({
		"source_pc": 0xA2B8, "address": 0x0020, "operation": "and_immediate",
		"operand": 0x7F, "result_value": null,
		"reason": "Incoming PPUCTRL shadow is caller-owned; ROM masks bit 7.",
	})
	result["ppu_events"].append({
		"source_pc": 0xA2BC, "address": 0x2000,
		"value_expression": "$0020 & $7F", "applied": false,
	})
	result["ram_operations"].append({
		"source_pc": 0xA2BF, "address": 0x0020, "operation": "store_previous_masked_value",
		"value_expression": "$0020 & $7F", "applied": false,
	})
	result["mapper_events"].append({
		"source_pc": 0xA2C1, "address": 0xE000, "value": 0x00,
		"effect": "MMC3 IRQ disable write.", "applied": false,
	})
	result["zero_fill_writes"].append({
		"source_pc": 0xA2C8, "start_address": 0x0001, "end_address_inclusive": 0x0018,
		"count": 24, "value": 0, "applied": false,
		"source_loop": "STA $FF19,Y with Y=$E8..$FF, then $00; 16-bit address wrap yields $0001..$0018 and a final mapper-bus write.",
	})
	result["mapper_events"].append({
		"source_pc": 0xA2C8, "address": 0xFF19, "source_y": 0x00,
		"mirrored_register": 0xE001, "value": 0x00,
		"effect": "MMC3 IRQ enable write caused by 16-bit indexed-address wrap.",
		"applied": false,
	})
	result["zero_fill_writes"].append({
		"source_pc": 0xA2D2, "start_address": 0x003A, "end_address_inclusive": 0x00DF,
		"count": 166, "value": 0, "applied": false,
		"source_loop": "STA $FFE0,Y with Y=$5A..$FF, then $00; 16-bit address wrap yields $003A..$00DF and a final mapper-bus write.",
	})
	result["mapper_events"].append({
		"source_pc": 0xA2D2, "address": 0xFFE0, "source_y": 0x00,
		"mirrored_register": 0xE000, "value": 0x00,
		"effect": "MMC3 IRQ disable write caused by 16-bit indexed-address wrap.",
		"applied": false,
	})
	result["ram_writes"].append({"source_pc": 0xA2DE, "address": 0x00EC, "value": 0x68, "applied": false})
	result["ram_writes"].append({"source_pc": 0xAA06, "address": 0x00ED, "value": 0x04, "applied": false})
	result["zero_fill_writes"].append({
		"source_pc": 0xAA0E, "start_address": 0x0468, "end_address_inclusive": 0x06FF,
		"count": 664, "value": 0, "applied": false,
		"source_loop": "$AA06 uses A=$98, X=2, EC=$68, ED=$04. First pass writes $98 bytes; the outer DEX/BNE returns to PHA without reloading A, so the two remaining passes each count through a full 256-byte wrap.",
	})
	result["ram_writes"].append({"source_pc": 0xAA14, "address": 0x00ED, "value": 0x05, "applied": false, "when": "after first $EC wrap"})
	result["ram_writes"].append({"source_pc": 0xAA14, "address": 0x00ED, "value": 0x06, "applied": false, "when": "after second $EC wrap"})
	result["ram_writes"].append({"source_pc": 0xAA14, "address": 0x00ED, "value": 0x07, "applied": false, "when": "after third $EC wrap"})
	result["ram_writes"].append({"source_pc": 0xAA10, "address": 0x00EC, "value": 0x00, "applied": false, "when": "after 664 increments"})


func _pending_task_slot_writes() -> Array:
	var addresses: Array[int] = [0x01, 0x02, 0x05, 0x06, 0x09, 0x0A, 0x0D, 0x0E, 0x11, 0x12, 0x15, 0x16]
	var result: Array = []
	var pc_by_address := {
		0x01: 0xC6C3, 0x02: 0xC6C5, 0x05: 0xC6C9, 0x06: 0xC6CB,
		0x09: 0xC6CF, 0x0A: 0xC6D1, 0x0D: 0xC6D5, 0x0E: 0xC6D7,
		0x11: 0xC6DB, 0x12: 0xC6DD, 0x15: 0xC6E1, 0x16: 0xC6E3,
	}
	for address in addresses:
		result.append({
			"source_pc": int(pc_by_address[address]), "address": address,
			"value": 0, "applied": false, "stage": "pending_at_C6BE",
		})
	return result


func _accept_helper_result(result: Dictionary, helper_results: Array, helper_index: int) -> bool:
	var requirement: Dictionary = HELPER_CALLS[helper_index]
	var helper_id := String(requirement["helper_id"])
	var source_pc := int(requirement["source_pc"])
	var target_pc := int(requirement["target_pc"])
	result["source_pc"] = source_pc
	result["final_source_pc"] = source_pc
	result["pending_source_pc"] = source_pc
	result["pending_helper_id"] = helper_id
	for helper_variant in helper_results:
		if not helper_variant is Dictionary:
			continue
		var helper: Dictionary = helper_variant
		if String(helper.get("helper_id", "")) != helper_id \
				or int(helper.get("source_pc", -1)) != source_pc \
				or int(helper.get("target_pc", -1)) != target_pc \
				or String(helper.get("status", "")) != "applied" \
				or String(helper.get("effect_provider", "")).strip_edges().is_empty() \
				or String(helper.get("effect_summary", "")).strip_edges().is_empty():
			continue
		result["accepted_helper_results"].append(helper.duplicate(true))
		result["source_path"].append({
			"helper_id": helper_id,
			"source_pc": source_pc,
			"target_pc": target_pc,
			"via": "named external Godot-side effect result",
		})
		result["pending_source_pc"] = -1
		result["pending_helper_id"] = ""
		return true
	result["source_pc"] = source_pc
	result["final_source_pc"] = source_pc
	result["pending_source_pc"] = source_pc
	result["pending_helper_id"] = helper_id
	result["status"] = "blocked_on_helper"
	result["ok"] = true
	return false


func _load_task_clear_source() -> bool:
	var manifest_file := FileAccess.open(TASK_CLEAR_MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Existing task-slot-clear provenance manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary or String(parsed.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Existing task-slot-clear manifest is malformed or targets a different ROM.")
	var found := false
	for entry_variant in parsed.get("spans", []):
		if entry_variant is Dictionary and String(entry_variant.get("file", "")) == TASK_CLEAR_FILE:
			var entry: Dictionary = entry_variant
			found = int(entry.get("length", -1)) == TASK_CLEAR_LENGTH \
					and String(entry.get("file_offset", "")) == "0x03C6CE" \
					and String(entry.get("sha256", "")) == TASK_CLEAR_SHA256
			break
	if not found:
		return _fail("Existing task-slot-clear manifest entry differs from the verified source span.")
	_task_clear_source = FileAccess.get_file_as_bytes(TASK_CONTEXT_ROOT + TASK_CLEAR_FILE)
	if _task_clear_source.size() != TASK_CLEAR_LENGTH or _sha256(_task_clear_source) != TASK_CLEAR_SHA256:
		return _fail("Existing C6BE task-slot-clear source span failed its size/hash check.")
	return true


func _verify_source_recipes() -> bool:
	var expected_cleanup := PackedByteArray([
		0xA9, 0x00, 0x85, 0x05, 0x85, 0x06, 0x85, 0x09, 0x85, 0x0A,
		0x85, 0x11, 0x85, 0x12, 0x85, 0x0D, 0x85, 0x0E, 0x85, 0x4C,
		0xA9, 0x01, 0x8D, 0x00, 0x07, 0x20, 0xA0, 0x9B, 0xA9, 0x00,
		0x85, 0x44, 0x85, 0x45, 0x85, 0x7A, 0x85, 0x7B, 0x60,
	])
	if _sources["cutscene_common_cleanup"] != expected_cleanup:
		return _fail("`$82C6-$82EC` cleanup instruction recipe differs from the supplied ROM.")
	if _sources["cutscene_return_caller"] != PackedByteArray([0xA5, 0xE0, 0x29, 0x7F, 0x85, 0xE0, 0x4C, 0x17, 0x80]):
		return _fail("`$815D-$8165` return caller differs from the supplied ROM.")
	if _sources["fresh_match_entry"] != PackedByteArray([0xA2, 0x02, 0x20, 0xB9, 0xC4, 0x4C, 0x03, 0xA2]):
		return _fail("`$8017-$801E` fresh-match entry differs from the supplied ROM.")
	if _sources["mapper_bank_select"] != PackedByteArray([0x86, 0x25, 0xA9, 0x07, 0x05, 0x22, 0x85, 0x23, 0x8D, 0x00, 0x80, 0x8E, 0x01, 0x80, 0x60]):
		return _fail("`$C4B9-$C4C7` mapper helper differs from the supplied ROM.")
	if _sources["fresh_match_trampoline"] != PackedByteArray([0x4C, 0xAF, 0xA2]):
		return _fail("`$A203` fresh-match trampoline differs from the supplied ROM.")
	var setup: PackedByteArray = _sources["fresh_match_setup"]
	if setup.size() != 57 or setup.slice(0, 9) != PackedByteArray([0x20, 0xF0, 0x99, 0x20, 0xA0, 0x98, 0x20, 0x7F, 0x9B]) \
			or setup.slice(9, 21) != PackedByteArray([0xA5, 0x20, 0x29, 0x7F, 0x8D, 0x00, 0x20, 0x85, 0x20, 0x8D, 0x00, 0xE0]) \
			or setup.slice(21, 35) != PackedByteArray([0xA9, 0x00, 0xA0, 0xE8, 0x99, 0x19, 0xFF, 0xC8, 0xD0, 0xFA, 0xA9, 0x00, 0xA0, 0x5A]) \
			or setup.slice(35, 57) != PackedByteArray([0x99, 0xE0, 0xFF, 0xC8, 0xD0, 0xFA, 0xA9, 0x98, 0xA2, 0x02, 0xA0, 0x68, 0x84, 0xEC, 0xA0, 0x04, 0x20, 0x06, 0xAA, 0x4C, 0x57, 0xC5]):
		return _fail("`$A2AF-$A2E7` setup/fill/call bytes differ from the supplied ROM.")
	if _sources["zero_fill_helper"] != PackedByteArray([
		0x84, 0xED, 0xE8, 0xA0, 0x00, 0x48, 0xA9, 0x00, 0x91, 0xEC,
		0xE6, 0xEC, 0xD0, 0x02, 0xE6, 0xED, 0x68, 0x38, 0xE9, 0x01,
		0xD0, 0xEF, 0xCA, 0xD0, 0xEC,
	]):
		return _fail("`$AA06-$AA1E` zero-fill helper differs from the supplied ROM.")
	if _sources["scheduler_handoff"] != PackedByteArray([0x4C, 0xBE, 0xC6]):
		return _fail("`$C557` scheduler handoff differs from the supplied ROM.")
	if _task_clear_source != PackedByteArray([
		0xA2, 0xE0, 0x9A, 0xA9, 0x00, 0x85, 0x01, 0x85, 0x02, 0xA9, 0x00,
		0x85, 0x05, 0x85, 0x06, 0xA9, 0x00, 0x85, 0x09, 0x85, 0x0A,
		0xA9, 0x00, 0x85, 0x0D, 0x85, 0x0E, 0xA9, 0x00, 0x85, 0x11,
		0x85, 0x12, 0xA9, 0x00, 0x85, 0x15, 0x85, 0x16, 0x20, 0x1F, 0xCF,
	]):
		return _fail("Existing `$C6BE-$C6E7` task-slot-clear recipe differs from the supplied ROM.")
	return true


func _refused(completion_kind: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"status": "refused",
		"completion_kind": completion_kind,
		"error": message,
		"final_source_pc": -1,
		"pending_source_pc": -1,
		"c557_reached": false,
		"task_writes": [], "zero_fill_writes": [], "audio_stop_request": null,
		"does_execute_6502": false,
	}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
