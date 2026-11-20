extends RefCounted
class_name RomFreshKickoffCutsceneWorkerSeed
## Reconstructs the ROM-created slot-$05 worker stack from `$8464/$9F69`.
## It does not model the caller task, scheduler timing, or the cutscene VM.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const CALLER_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const SETUP_FILE := "bank00_cutscene_task_setup_8494_84A5.bin"
const RESUME_FILE := "fixed_old_task_resume_9F52_9F69.bin"
const CREATE_FILE := "fixed_old_task_create_9F69_9F7E.bin"
const MAPPER_SHADOW_SOURCE_STATE_SCRIPT := preload("res://scripts/gameplay/rom_mapper_shadow_source_state.gd")

const EXPECTED_SPANS := {
	CALLER_FILE: {"start": "$80DF", "end": "$815D", "offset": "0x0000EF",
		"length": 126, "sha256": "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"},
	SETUP_FILE: {"start": "$8494", "end": "$84A5", "offset": "0x0004A4",
		"length": 17, "sha256": "29f3d7fb20d1f4421cd292902d480531c2d82bda9f83718b2299031337a991be"},
	RESUME_FILE: {"start": "$9F52", "end": "$9F69", "offset": "0x001F62",
		"length": 23, "sha256": "2134f1155ca3fd4be0f366fe8f00b293e041f45d870360737333d39d83fa2e4a"},
	CREATE_FILE: {"start": "$9F69", "end": "$9F7E", "offset": "0x001F79",
		"length": 21, "sha256": "d770ececa16cd65aba4d88cf917105d695f1d5df1977dc15e693a2eac62a7239"},
}
const SETUP_HEX := "a205a9c59500a9849501a050a90020699f"
const TITLE_CALL_HEX := "a901206484"
const RESUME_HEX := "8600a906052285238d0080b50285248d0180b501aa9a60"
const CREATE_HEX := "95028888b500990101b5019902019401a9ff950060"

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Cutscene worker seed manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Cutscene worker seed manifest is malformed.")
	var document: Dictionary = parsed
	var rom: Variant = document.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Cutscene worker seed source targets a different ROM revision.")
	for span_variant in document.get("spans", []):
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		var file_name := String(span.get("file", ""))
		if not EXPECTED_SPANS.has(file_name):
			continue
		var expected: Dictionary = EXPECTED_SPANS[file_name]
		if String(span.get("cpu_start", "")) != expected["start"] \
				or String(span.get("cpu_end_exclusive", "")) != expected["end"] \
				or String(span.get("file_offset", "")) != expected["offset"] \
				or int(span.get("length", -1)) != int(expected["length"]) \
				or String(span.get("sha256", "")) != expected["sha256"]:
			return _fail("Cutscene worker seed manifest metadata differs for " + file_name)
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if bytes.size() != int(expected["length"]) \
				or _sha256(bytes) != String(expected["sha256"]) \
				or String(span.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Hash-checked cutscene worker seed span failed: " + file_name)
		_sources[file_name] = bytes
	for file_name: String in EXPECTED_SPANS:
		if not _sources.has(file_name):
			return _fail("Cutscene worker seed package omits " + file_name)
	if _sources[SETUP_FILE].hex_encode() != SETUP_HEX \
			or _sources[RESUME_FILE].hex_encode() != RESUME_HEX \
			or _sources[CREATE_FILE].hex_encode() != CREATE_HEX:
		return _fail("Cutscene worker seed source bytes differ from the supported ROM path.")
	var caller_bytes: PackedByteArray = _sources[CALLER_FILE]
	if caller_bytes.slice(0x0A, 0x0F).hex_encode() != TITLE_CALL_HEX:
		return _fail("KICK OFF title caller no longer loads cutscene `$01` and calls `$8464`.")
	_configured = true
	return true


func build_title_cutscene1_seed(title_handoff: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(title_handoff.get("ok", false)) \
			or String(title_handoff.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(title_handoff.get("selected_option", "")) != "KICK OFF" \
			or bool(title_handoff.get("trace_state_used", true)) \
			or bool(title_handoff.get("emulator_data_used", true)):
		return _refused("Slot-$05 seed requires the live ROM title KICK OFF handoff.")
	var mapper_shadow_builder: Variant = MAPPER_SHADOW_SOURCE_STATE_SCRIPT.new()
	var mapper_shadow: Dictionary = mapper_shadow_builder.derive_fresh_kickoff_id1()
	if not bool(mapper_shadow.get("ok", false)) \
			or String(mapper_shadow.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(mapper_shadow.get("ram_address", -1)) != 0x0022 \
			or int(mapper_shadow.get("value", -1)) < 0 \
			or int(mapper_shadow.get("value", -1)) > 0xFF \
			or bool(mapper_shadow.get("emulator_data_used", true)):
		return _refused("The `$9F52` worker restore needs the ROM-derived MMC3 shadow `$0022`.")
	var setup_bytes: PackedByteArray = _sources[SETUP_FILE]
	var initial_sp := int(setup_bytes[11])
	var saved_sp := (initial_sp - 2) & 0xFF
	var return_low := int(setup_bytes[3])
	var return_high := int(setup_bytes[7])
	var staged_return_word := return_low | (return_high << 8)
	var stack_low_address := 0x0101 + saved_sp
	var stack_high_address := 0x0102 + saved_sp
	var resumed_pc := (staged_return_word + 1) & 0xFFFF
	var resumed_sp := (saved_sp + 2) & 0xFF
	if staged_return_word != 0x84C5 or resumed_pc != 0x84C6 or resumed_sp != 0x50:
		return _refused("Source-derived task restore did not return to `$84C6` with SP `$50`.")
	var mapper_select := (0x06 | int(mapper_shadow["value"])) & 0xFF
	# `$8494` loads A with the bank byte immediately before JSR `$9F69`.
	# Offset 7 is the return-address high byte `$84`, not the bank value.
	var bank_low := int(setup_bytes[13])
	var task_record_writes: Array[Dictionary] = [
		{"source_pc": 0x9F69, "address": 0x0007, "value": bank_low},
		{"source_pc": 0x9F6F, "address": stack_low_address, "value": return_low},
		{"source_pc": 0x9F74, "address": stack_high_address, "value": return_high},
		{"source_pc": 0x9F77, "address": 0x0006, "value": saved_sp},
		{"source_pc": 0x9F7B, "address": 0x0005, "value": 0xFF},
	]
	var resume_ram_writes: Array[Dictionary] = [
		{"source_pc": 0x9F52, "address": 0x0000, "value": 0x05},
		{"source_pc": 0x9F58, "address": 0x0023, "value": mapper_select},
		{"source_pc": 0x9F5F, "address": 0x0024, "value": bank_low},
	]
	var all_ram_writes := task_record_writes.duplicate(true)
	all_ram_writes.append_array(resume_ram_writes)
	return {
		"ok": true,
		"kind": "rom_cutscene_worker_slot05_seed",
		"source_rom_sha256": ROM_SHA256,
		"caller_event": {"caller_pc": 0x80EB, "target_pc": 0x8464,
			"return_pc": 0x80EE, "cutscene_id": 1},
		"source_path": [0x80E9, 0x80EB, 0x8464, 0x8494, 0x9F69, 0x9F52, resumed_pc],
		"scheduler_dispatch_pc": 0x9EED,
		"scheduler_dispatch_executed": false,
		"old_task_resume_executed": true,
		"task_record_writes": task_record_writes,
		"worker_entry_stack_bytes": [
			{"address": stack_low_address, "value": return_low, "source_pc": 0x9F6F},
			{"address": stack_high_address, "value": return_high, "source_pc": 0x9F74},
		],
		"resume_ram_writes": resume_ram_writes,
		"ram_writes": all_ram_writes,
		"mapper_bus_writes": [
			{"source_pc": 0x9F5A, "address": 0x8000, "value": mapper_select},
			{"source_pc": 0x9F61, "address": 0x8001, "value": bank_low},
		],
		"mapper_shadow_state": mapper_shadow.duplicate(true),
		"slot_offset": 0x05,
		"ready_value": 0xFF,
		"saved_sp": saved_sp,
		"bank_low": bank_low,
		"stack_return_address": staged_return_word,
		"resume_pc": resumed_pc,
		"resume_sp": resumed_sp,
		"worker_entry_cpu": {
			"pc": resumed_pc, "a": saved_sp, "x": saved_sp,
			"y": saved_sp, "sp": resumed_sp,
			"p_known_mask": 0x82, "p_known_value": 0x00,
			"status_provenance": "N/Z from `$9F66 TAX` after loading saved SP `$4E`; other flags are preserved",
		},
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
		"cutscene_vm_uses_source_worker_seed": true,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "source_rom_sha256": ROM_SHA256,
		"error": error_message, "runtime_rom_dependency": false,
		"runtime_emulator_dependency": false}


func _refused(reason: String) -> Dictionary:
	return {"ok": false, "status": "refused", "error": reason,
		"source_rom_sha256": ROM_SHA256, "trace_state_used": false,
		"emulator_data_used": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
