extends RefCounted
class_name RomFreshKickoffTitleStackContext
## Derives the physical JSR return frame supplied to the fresh-match selector.
## It models only stack bytes written by the checked ROM task seed and the
## three balanced caller calls; it does not claim the whole historical stack.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const LEGACY_ROOT := "res://reference/rom_extract/gameplay/legacy_title_task_seed/"
const LEGACY_MANIFEST := LEGACY_ROOT + "manifest.json"
const LEGACY_SEED_FILE := "bank02_slot01_create_A281_A291.bin"
const CALLER_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const CALLER_MANIFEST := CALLER_ROOT + "manifest.json"
const CALLER_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const RESUME_FILE := "fixed_old_task_resume_9F52_9F69.bin"
const CREATE_FILE := "fixed_old_task_create_9F69_9F7E.bin"
const LEGACY_SEED_HEX := "a201a91e9500a9809501a028a90020699f"
const RESUME_HEX := "8600a906052285238d0080b50285248d0180b501aa9a60"
const CREATE_HEX := "95028888b500990101b5019902019401a9ff950060"
const CALLER_SHA256 := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const LEGACY_SEED_SHA256 := "3d32f102f7038143e3c764416a8cbb092c782b613d815c306967ccbb1dd0b7d6"
const CREATE_SHA256 := "d770ececa16cd65aba4d88cf917105d695f1d5df1977dc15e693a2eac62a7239"
const RESUME_SHA256 := "2134f1155ca3fd4be0f366fe8f00b293e041f45d870360737333d39d83fa2e4a"

var error_message := ""
var _configured := false
var _caller_bytes := PackedByteArray()
var _seed_bytes := PackedByteArray()
var _resume_bytes := PackedByteArray()
var _create_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	if not _load_manifest_span(LEGACY_MANIFEST, LEGACY_ROOT, LEGACY_SEED_FILE,
			"$A281", "$A292", "0x004291", 17, LEGACY_SEED_SHA256):
		return false
	_seed_bytes = FileAccess.get_file_as_bytes(LEGACY_ROOT + LEGACY_SEED_FILE)
	if _seed_bytes.hex_encode() != LEGACY_SEED_HEX:
		return _fail("The old title task seed at `$A281` changed from its verified bytes.")
	if not _load_manifest_span(CALLER_MANIFEST, CALLER_ROOT, CALLER_FILE,
			"$80DF", "$815D", "0x0000EF", 126, CALLER_SHA256):
		return false
	_caller_bytes = FileAccess.get_file_as_bytes(CALLER_ROOT + CALLER_FILE)
	if not _load_manifest_span(CALLER_MANIFEST, CALLER_ROOT, RESUME_FILE,
			"$9F52", "$9F69", "0x001F62", 23, RESUME_SHA256):
		return false
	_resume_bytes = FileAccess.get_file_as_bytes(CALLER_ROOT + RESUME_FILE)
	if _resume_bytes.hex_encode() != RESUME_HEX:
		return _fail("Old-task restore `$9F52-$9F68` differs from the checked source.")
	if not _load_manifest_span(CALLER_MANIFEST, CALLER_ROOT, CREATE_FILE,
			"$9F69", "$9F7E", "0x001F79", 21, CREATE_SHA256):
		return false
	_create_bytes = FileAccess.get_file_as_bytes(CALLER_ROOT + CREATE_FILE)
	if _create_bytes.hex_encode() != CREATE_HEX:
		return _fail("Old-task creation `$9F69-$9F7D` differs from the checked source.")
	if not _verify_caller_callsites():
		return false
	_configured = true
	return true


## Return the physical caller stack at `$A20F` only after the source caller and
## `$C4B9` helper have returned to their checked ROM call sites.
func build_selector_call_context(caller_result: Dictionary, mapper_result: Dictionary,
		source_event_id: String) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if source_event_id.strip_edges().is_empty():
		return _refused("A route-owned selector call event identity is required.")
	if not bool(caller_result.get("ok", false)) \
			or String(caller_result.get("status", "")) != "stopped_at_source_call_entry" \
			or int(caller_result.get("final_source_pc", -1)) != 0x80F7:
		return _refused("Caller must reach its ROM `$80F7 JSR $C4B9` entry.")
	var caller_pending: Dictionary = caller_result.get("pending_call", {})
	if int(caller_pending.get("caller_pc", -1)) != 0x80F7 \
			or int(caller_pending.get("target_pc", -1)) != 0xC4B9 \
			or int(caller_pending.get("return_pc", -1)) != 0x80FA:
		return _refused("The pending caller handoff is not the checked `$80F7->$C4B9` call.")
	var mapper_call: Dictionary = mapper_result.get("source_call", {})
	var mapper_return: Dictionary = mapper_result.get("return_registers", {})
	if not bool(mapper_result.get("ok", false)) \
			or String(mapper_result.get("status", "")) != "returned" \
			or int(mapper_call.get("caller_pc", -1)) != 0x80F7 \
			or int(mapper_call.get("target_pc", -1)) != 0xC4B9 \
			or int(mapper_return.get("pc", -1)) != 0x80FA:
		return _refused("The checked `$C4B9` helper has not returned to `$80FA`.")

	var task_seed := _derive_root_slot01_resume()
	if not bool(task_seed.get("ok", false)):
		return _refused(String(task_seed.get("error", "Old title root task seed failed.")))
	var stack_page: PackedByteArray = task_seed["stack_page"].duplicate()
	var sp := int(task_seed["resume_sp"])
	var stack_calls: Array[Dictionary] = []
	var wait_call := _push_and_return(stack_page, sp, 0x80EE, 0x82B5, 0x80F1)
	if not bool(wait_call.get("ok", false)):
		return _refused(String(wait_call.get("error", "The cutscene waiter stack frame failed.")))
	stack_calls.append(wait_call)
	sp = int(wait_call["sp_after_return"])
	var mapper_frame := _push_and_return(stack_page, sp, 0x80F7, 0xC4B9, 0x80FA)
	if not bool(mapper_frame.get("ok", false)):
		return _refused(String(mapper_frame.get("error", "The mapper helper stack frame failed.")))
	stack_calls.append(mapper_frame)
	sp = int(mapper_frame["sp_after_return"])
	var selector_call := _push_jsr(stack_page, sp, 0x80FA, 0xA20F, 0x80FD)
	if not bool(selector_call.get("ok", false)):
		return _refused(String(selector_call.get("error", "The selector JSR stack frame failed.")))
	stack_calls.append(selector_call)
	sp = int(selector_call["sp_after_call"])
	if sp != 0x26 or _peek_word(stack_page, sp) != 0x80FC:
		return _refused("Physical `$80FA->$A20F` JSR did not produce SP `$26` and return word `$80FC`.")

	var source_call := {
		"caller_pc": 0x80FA,
		"target_pc": 0xA20F,
		"return_pc": 0x80FD,
		"source_event_id": source_event_id,
		"pre_call_sp": int(selector_call["sp_before"]),
		"stack_page": stack_page,
		"stack_known_page_offsets": [0x27, 0x28],
		"partial_status": true,
		"stack_source_scope": "ROM task seed plus checked, balanced caller JSR/RTS frames; unrelated stack bytes are not asserted",
	}
	return {
		"ok": true,
		"kind": "rom_fresh_kickoff_selector_physical_stack_context",
		"source_rom_sha256": ROM_SHA256,
		"selector_source_call": source_call,
		"entry_sp": sp,
		"pre_call_sp": int(selector_call["sp_before"]),
		"stack_page": stack_page,
		"stack_known_page_offsets": [0x27, 0x28],
		"known_stack_bytes_at_entry": {0x27: int(stack_page[0x27]), 0x28: int(stack_page[0x28])},
		"root_task_resume": task_seed["resume_receipt"],
		"balanced_source_calls": stack_calls,
		"full_historical_stack_claimed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _derive_root_slot01_resume() -> Dictionary:
	# The checked A281 block installs the old root task with Y=$28. The common
	# $9F69 helper stages the ROM return word at stack offsets $27/$28, saves
	# SP=$26, and the $9F52 restore's RTS resumes at $801F with SP=$28.
	if _seed_bytes.size() != 17 or _create_bytes.size() != 21 or _resume_bytes.size() != 23:
		return {"ok": false, "error": "Old-task source spans are not fully configured."}
	var stack_page := PackedByteArray()
	stack_page.resize(0x100)
	stack_page.fill(0)
	var task_ram := PackedByteArray()
	task_ram.resize(4)
	task_ram.fill(0)
	task_ram[1] = 0x1E # `$A283 LDA #$1E; STA $00,X`.
	task_ram[2] = 0x80 # `$A287 LDA #$80; STA $01,X` (staged return high).
	task_ram[3] = 0x00 # `$A28D LDA #$00`, passed to `$9F69`.
	task_ram[2] = 0x26 # `$9F69 DEY; DEY; STY $01,X`.
	stack_page[0x27] = task_ram[1] # `$9F69 STA $0101,Y` at Y=$26.
	stack_page[0x28] = 0x80 # `$9F69 STA $0102,Y`.
	task_ram[1] = 0xFF # `$9F69 LDA #$FF; STA $00,X`.
	var saved_sp := int(task_ram[2])
	var low := int(stack_page[(saved_sp + 1) & 0xFF])
	var high := int(stack_page[(saved_sp + 2) & 0xFF])
	var resume_pc := (((high << 8) | low) + 1) & 0xFFFF # `$9F52 RTS`.
	var resume_sp := (saved_sp + 2) & 0xFF
	if task_ram[1] != 0xFF or task_ram[3] != 0 \
			or saved_sp != 0x26 or resume_pc != 0x801F or resume_sp != 0x28:
		return {"ok": false, "error": "ROM-derived slot-$01 create/restore did not resume at `$801F`/SP `$28`."}
	return {
		"ok": true,
		"stack_page": stack_page,
		"resume_sp": resume_sp,
		"resume_receipt": {
			"task_slot": 0x01, "saved_sp": saved_sp,
			"return_word": 0x801E, "resume_pc": resume_pc, "resume_sp": resume_sp,
			"source_path": [0xA281, 0x9F69, 0x9F52, 0x801F],
			"stack_page_offsets_written": [0x27, 0x28],
			"trace_state_used": false, "emulator_data_used": false,
		},
	}


func _push_and_return(stack_page: PackedByteArray, sp_before: int, caller_pc: int,
		target_pc: int, return_pc: int) -> Dictionary:
	var pushed := _push_jsr(stack_page, sp_before, caller_pc, target_pc, return_pc)
	if not bool(pushed.get("ok", false)):
		return pushed
	var word := _peek_word(stack_page, int(pushed["sp_after_call"]))
	var rts_pc := (word + 1) & 0xFFFF
	var sp_after_return := (int(pushed["sp_after_call"]) + 2) & 0xFF
	if rts_pc != return_pc or sp_after_return != sp_before:
		return {"ok": false, "error": "ROM JSR/RTS did not balance at `$%04X`." % caller_pc}
	var receipt := pushed.duplicate(true)
	receipt["rts_pc"] = rts_pc
	receipt["sp_after_return"] = sp_after_return
	receipt["stack_model"] = "physical_rom_jsr_rts"
	return receipt


func _push_jsr(stack_page: PackedByteArray, sp_before: int, caller_pc: int,
		target_pc: int, return_pc: int) -> Dictionary:
	if sp_before < 2 or sp_before > 0xFF or return_pc != caller_pc + 3:
		return {"ok": false, "error": "Invalid ROM JSR stack inputs at `$%04X`." % caller_pc}
	var return_word := return_pc - 1
	stack_page[sp_before] = (return_word >> 8) & 0xFF
	stack_page[(sp_before - 1) & 0xFF] = return_word & 0xFF
	return {
		"ok": true, "caller_pc": caller_pc, "target_pc": target_pc,
		"return_pc": return_pc, "return_word": return_word,
		"sp_before": sp_before, "sp_after_call": (sp_before - 2) & 0xFF,
		"stack_writes": [
			{"page_offset": sp_before, "value": (return_word >> 8) & 0xFF},
			{"page_offset": (sp_before - 1) & 0xFF, "value": return_word & 0xFF},
		],
	}


func _peek_word(stack_page: PackedByteArray, sp: int) -> int:
	var low := int(stack_page[(sp + 1) & 0xFF])
	var high := int(stack_page[(sp + 2) & 0xFF])
	return low | (high << 8)


func _verify_caller_callsites() -> bool:
	for callsite: Dictionary in [
		{"pc": 0x80EE, "target": 0x82B5},
		{"pc": 0x80F7, "target": 0xC4B9},
		{"pc": 0x80FA, "target": 0xA20F},
	]:
		var offset := int(callsite["pc"]) - 0x80DF
		var target := int(callsite["target"])
		if _caller_bytes.slice(offset, offset + 3) != PackedByteArray([
				0x20, target & 0xFF, (target >> 8) & 0xFF]):
			return _fail("Caller JSR at `$%04X` differs from its source target." % int(callsite["pc"]))
	return true


func _load_manifest_span(manifest_path: String, source_root: String, file_name: String,
		cpu_start: String, cpu_end: String, file_offset: String, length: int,
		expected_sha256: String) -> bool:
	if not FileAccess.file_exists(manifest_path):
		return _fail("ROM task/caller source manifest is missing: " + manifest_path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		return _fail("ROM task/caller source manifest is malformed: " + manifest_path)
	var document: Dictionary = parsed
	var rom: Variant = document.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("ROM task/caller manifest targets a different ROM revision.")
	for span_variant in document.get("spans", []):
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("file", "")) != file_name:
			continue
		if String(span.get("cpu_start", "")) != cpu_start \
				or String(span.get("cpu_end_exclusive", "")) != cpu_end \
				or String(span.get("file_offset", "")) != file_offset \
				or int(span.get("length", -1)) != length \
				or String(span.get("sha256", "")) != expected_sha256:
			return _fail("ROM task/caller source metadata differs for " + file_name)
		var bytes := FileAccess.get_file_as_bytes(source_root + file_name)
		if bytes.size() != length or _sha256(bytes) != expected_sha256 \
				or String(span.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("ROM task/caller bytes failed hash or manifest validation: " + file_name)
		return true
	return _fail("ROM task/caller manifest omits " + file_name)


func _refused(reason: String) -> Dictionary:
	return {"ok": false, "status": "refused", "error": reason,
		"trace_state_used": false, "emulator_data_used": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
