extends RefCounted
class_name RomFreshKickoffEntryContextBuilder
## Derives fresh-match task inputs from preserved ROM bytes and the bounded
## ROM-derived scheduler projection. No trace RAM, frame number, or endpoint
## fixture is accepted as an input.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_entry_context/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const SOURCE_EXPECTATIONS := {
	"reset_vector_FFFC.bin": {
		"cpu_start": "$FFFC", "cpu_end_exclusive": "$FFFE", "file_offset": "0x04000C",
		"length": 2, "sha256": "def1e0885184cca73afc582c50470a0c10851a849027a1dd1d2aacc482b2516a",
	},
	"reset_entry_FFF0_FFF7.bin": {
		"cpu_start": "$FFF0", "cpu_end_exclusive": "$FFF8", "file_offset": "0x040000",
		"length": 8, "sha256": "95925881564c84710f0f280e12ddf5913882b5d9cf59cd89eabdf47442f9b122",
	},
	"reset_jump_C503.bin": {
		"cpu_start": "$C503", "cpu_end_exclusive": "$C506", "file_offset": "0x03C513",
		"length": 3, "sha256": "1af2205ae6c5e64cd5a956e38ab915e5f3049b2c6e40ed85803c3c8b6abbdf3d",
	},
	"reset_ram_clear_C64E_C679.bin": {
		"cpu_start": "$C64E", "cpu_end_exclusive": "$C67A", "file_offset": "0x03C65E",
		"length": 44, "sha256": "8315e93ae660d302632f7bfeffc9db002b3f1c1643ae2b6936d3ce5703e6f75a",
	},
	"title_kickoff_branch_80DF_8104.bin": {
		"cpu_start": "$80DF", "cpu_end_exclusive": "$8105", "file_offset": "0x0000EF",
		"length": 38, "sha256": "9644d6c798c23b733a43b63e67b2216ffe0aacc8a36ae8a636e7f0fd66b00dd8",
	},
	"match_selector_trampoline_A20F.bin": {
		"cpu_start": "$A20F", "cpu_end_exclusive": "$A212", "file_offset": "0x00421F",
		"length": 3, "sha256": "51244f9af68e818db390d67b69d822597a021d99bb35339132f4ce2dfde5430d",
	},
	"match_selector_A86E_A8CD.bin": {
		"cpu_start": "$A86E", "cpu_end_exclusive": "$A8CE", "file_offset": "0x00487E",
		"length": 96, "sha256": "f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123",
	},
}

const TASK_SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ENTRY_CONTEXT_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context.gd")
const SLOT_01 := 0x01
const SLOT_05 := 0x05
const FRESH_MATCH_INDEX := 0
const SUPPORTED_OPPONENT_ID := 0x03
const SLOT_05_ENTRY_PC := 0xD11E

var error_message := ""
var _configured := false
var _source_bytes: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source_bytes.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Fresh KICK OFF entry-context manifest is missing.")
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return _fail("Fresh KICK OFF entry-context manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-entry-context-source-v1":
		return _fail("Fresh KICK OFF entry-context manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Entry-context source manifest targets a different ROM revision.")
	var entries_by_file: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for file_name: String in SOURCE_EXPECTATIONS:
		var expected: Dictionary = SOURCE_EXPECTATIONS[file_name]
		if not entries_by_file.has(file_name):
			return _fail("Entry-context manifest omits %s." % file_name)
		var entry: Dictionary = entries_by_file[file_name]
		for key: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(key, -1)) == int(expected[key]) \
					if key == "length" else String(entry.get(key, "")) == String(expected[key])
			if not matches:
				return _fail("Entry-context manifest metadata differs for %s (%s)." % [file_name, key])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]):
			return _fail("Packaged entry-context ROM span failed its size/hash check: %s." % file_name)
		if String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Entry-context manifest byte listing disagrees with %s." % file_name)
		_source_bytes[file_name] = bytes
	if not _verify_source_semantics():
		return false
	_configured = true
	return true


## Derives values only after the existing scheduler has produced its genuine
## source-byte slot-$05 dispatch. The scheduler projection remains bounded and
## does not model actual NMI cadence or route timing.
func build_fresh_kickoff_context() -> Variant:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked fresh KICK OFF source spans first.")
		return null
	var scheduler_result := _derive_slot05_dispatch()
	if not bool(scheduler_result.get("ok", false)):
		_fail("ROM task scheduler could not produce slot-$05 entry: %s" % String(scheduler_result.get("error", "unknown scheduler error")))
		return null
	var match_index := _derive_match_index_from_reset()
	var period := _derive_period_from_kickoff_store()
	var opponent_id := _derive_opponent_from_selector(match_index)
	if match_index != FRESH_MATCH_INDEX or opponent_id != SUPPORTED_OPPONENT_ID:
		_fail("The bounded fresh-match executor supports only ROM-derived match 0 / opponent $03.")
		return null
	var slot_base := int(scheduler_result.get("slot_base", -1))
	var entry_pc := int(scheduler_result.get("pc", -1))
	var entry_sp := int(scheduler_result.get("sp", -1))
	if slot_base != SLOT_05 or entry_pc != SLOT_05_ENTRY_PC or entry_sp < 0 or entry_sp > 0xFF:
		_fail("Scheduler result is not the source-derived slot-$05 `$D11E` entry.")
		return null
	var context: Variant = ENTRY_CONTEXT_SCRIPT.new()
	context.match_index = match_index
	context.period_0027 = period
	context.opponent_id_002b = opponent_id
	context.task_slot_base = slot_base
	context.entry_pc = entry_pc
	context.entry_sp = entry_sp
	context.scheduler_dispatch = scheduler_result.duplicate(true)
	context.provenance = {
		"kind": "caller_owned_decoded_game_logic",
		"label": "fresh KICK OFF context derived from reset, title branch, match selector, and task scheduler ROM sources",
		"source_event": "fresh KICK OFF context from reset, title branch, match selector, and slot-$05 scheduler dispatch",
		"rom_sha256": ROM_SHA256,
		"match_index": "reset vector $FFFC -> $FFF0 -> $C503 -> $C64E clears internal RAM; KICK OFF branch $80DF->$80E6 reaches $A20F->$A86E selector",
		"period_0027": "$80FD LDA #$00 followed by $8103 STA $0027",
		"opponent_002b": "$A20F JMP $A86E; $A8AF LDA $0026 / CLC / ADC #$03 / STA $002B",
		"task_entry": "RomGameplayTaskScheduler source-byte bootstrap, slot-$01 first yield, and slot-$05 dispatch",
		"route_timing": "source order is folded at the Godot cutscene-2 return; exact ROM scheduler/NMI timing is not represented",
	}
	return context


func _derive_slot05_dispatch() -> Dictionary:
	var scheduler = TASK_SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources():
		return {"ok": false, "error": scheduler.error_message}
	var bootstrap: Dictionary = scheduler.initialize_fresh_game_bootstrap()
	if not bool(bootstrap.get("ok", false)):
		return {"ok": false, "error": scheduler.error_message}
	var first_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(first_scan.get("ok", false)) or int(first_scan.get("selected_slot_base", -1)) != SLOT_01:
		return {"ok": false, "error": scheduler.error_message if not scheduler.error_message.is_empty() else "slot $01 was not selected"}
	var first_dispatch: Dictionary = scheduler.dispatch_pending_task(SLOT_01)
	if not bool(first_dispatch.get("ok", false)):
		return {"ok": false, "error": scheduler.error_message}
	var first_yield: Dictionary = scheduler.execute_root_slot01_startup_to_first_yield()
	if not bool(first_yield.get("ok", false)):
		return {"ok": false, "error": scheduler.error_message}
	var slot5_scan: Dictionary = scheduler.scan_ready_tasks_once()
	if not bool(slot5_scan.get("ok", false)) or int(slot5_scan.get("selected_slot_base", -1)) != SLOT_05:
		return {"ok": false, "error": scheduler.error_message if not scheduler.error_message.is_empty() else "slot $05 was not selected after slot $01 yield"}
	var dispatch: Dictionary = scheduler.dispatch_pending_task(SLOT_05)
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("pc", -1)) != SLOT_05_ENTRY_PC:
		return {"ok": false, "error": scheduler.error_message if not scheduler.error_message.is_empty() else "slot $05 did not dispatch at $D11E"}
	var result := dispatch.duplicate(true)
	result["slot01_yield_pc"] = int(first_yield.get("yield_callsite_pc", -1))
	result["slot05_scan_cursor"] = int(slot5_scan.get("scheduler_scan_cursor", -1))
	result["bounded_source_projection"] = true
	result["nmi_cadence_executed"] = false
	result["slot05_task_dispatched_by_general_cpu"] = false
	return result


func _derive_match_index_from_reset() -> int:
	# Interpret only the verified reset clear loop: LDA #0, pointer $00:$01=0,
	# Y=0, X=8, then STA ($00),Y / INY / wrap-page / DEX. Fill nonzero first so
	# the returned selector value is the result of this source operation.
	var reset_code: PackedByteArray = _source_bytes["reset_ram_clear_C64E_C679.bin"]
	var loop_source := reset_code.slice(25, 44)
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0xFF)
	var accumulator := int(loop_source[1])
	var page_count := int(loop_source[8])
	for page in range(page_count):
		for offset in range(0x100):
			ram[(page << 8) | offset] = accumulator
	return int(ram[0x0026])


func _derive_period_from_kickoff_store() -> int:
	var title: PackedByteArray = _source_bytes["title_kickoff_branch_80DF_8104.bin"]
	var load_store_offset := 0x80FD - 0x80DF
	return int(title[load_store_offset + 1])


func _derive_opponent_from_selector(match_index: int) -> int:
	var selector: PackedByteArray = _source_bytes["match_selector_A86E_A8CD.bin"]
	var formula_offset := 0xA8AF - 0xA86E
	var base_id := int(selector[formula_offset + 4])
	return (match_index + base_id) & 0xFF


func _verify_source_semantics() -> bool:
	if _source_bytes["reset_vector_FFFC.bin"] != PackedByteArray([0xF0, 0xFF]) \
			or _source_bytes["reset_entry_FFF0_FFF7.bin"] != PackedByteArray([0xA9, 0x00, 0x8D, 0x00, 0x80, 0x4C, 0x03, 0xC5]) \
			or _source_bytes["reset_jump_C503.bin"] != PackedByteArray([0x4C, 0x4E, 0xC6]):
		return _fail("Cold-reset vector/jump chain no longer reaches the verified RAM clear.")
	var clear_code: PackedByteArray = _source_bytes["reset_ram_clear_C64E_C679.bin"]
	if clear_code != PackedByteArray([
		0xA9, 0x08, 0x8D, 0x00, 0x20, 0x78, 0xD8, 0xA2, 0xFF, 0x9A, 0xAD, 0x02, 0x20, 0x10, 0xFB,
		0xAD, 0x02, 0x20, 0x10, 0xFB, 0xA9, 0xC0, 0x8D, 0x01, 0xA0, 0xA9, 0x00, 0x85, 0x00, 0x85,
		0x01, 0xA8, 0xA2, 0x08, 0x91, 0x00, 0xC8, 0xD0, 0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6,
	]):
		return _fail("Cold-start RAM clear bytes differ from the verified eight-page reset routine.")
	var title: PackedByteArray = _source_bytes["title_kickoff_branch_80DF_8104.bin"]
	if title.slice(0, 7) != PackedByteArray([0x24, 0xED, 0x50, 0x03, 0x4C, 0x6A, 0x82]) \
			or title.slice(7, 10) != PackedByteArray([0x20, 0xA0, 0x9B]) \
			or title.slice(0x1B, 0x1E) != PackedByteArray([0x20, 0x0F, 0xA2]):
		return _fail("Title KICK OFF branch no longer targets the verified new-game/selector path.")
	var period_offset := 0x80FD - 0x80DF
	if title.slice(period_offset, period_offset + 8) != PackedByteArray([0xA9, 0x00, 0x85, 0x28, 0x85, 0x29, 0x85, 0x27]):
		return _fail("Title route period load/store sequence changed from `$80FD`/`$8103`.")
	if _source_bytes["match_selector_trampoline_A20F.bin"] != PackedByteArray([0x4C, 0x6E, 0xA8]):
		return _fail("Bank-$02 `$A20F` no longer jumps to `$A86E`.")
	var selector: PackedByteArray = _source_bytes["match_selector_A86E_A8CD.bin"]
	var formula_offset := 0xA8AF - 0xA86E
	if selector.slice(formula_offset, formula_offset + 7) != PackedByteArray([0xA5, 0x26, 0x18, 0x69, 0x03, 0x85, 0x2B]):
		return _fail("Match selector no longer derives `$002B = $0026 + 3` from ROM instructions.")
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false
