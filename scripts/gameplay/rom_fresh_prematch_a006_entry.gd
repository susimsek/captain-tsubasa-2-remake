extends RefCounted
class_name RomFreshPrematchA006Entry
## Executes the bank-$01 `$A006 JMP $A4EB` entry of the fresh pre-match setup.
## It transfers control only; it does not emulate the `$A4EB` target body.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const CALLER_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const CALLER_MANIFEST_PATH := CALLER_ROOT + "manifest.json"

const CALLER_PC := 0x811C
const TARGET_PC := 0xA006
const RETURN_PC := 0x811F
const BODY_PC := 0xA4EB
const A000_PRG_BANK := 1
const PREMACH_SETUP_MAPPER_SHADOW := 0x0025

const SOURCE_EXPECTATIONS := {
	"a006_vector": {
		"file": "bank01_prematch_setup_vector_A006_A009.bin",
		"cpu_start": "$A006", "cpu_end_exclusive": "$A009",
		"file_offset": "0x002016", "length": 3,
		"sha256": "d823d82f6c345fe92558a284727617cdea76ce9d9c6b32bdd01e44a18bfd8af3",
		"bytes": "4ceba4",
	},
	"a4eb_body": {
		"file": "bank01_prematch_setup_body_A4EB_A610.bin",
		"cpu_start": "$A4EB", "cpu_end_exclusive": "$A611",
		"file_offset": "0x0024FB", "length": 0x126,
		"sha256": "1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587",
	},
}

const CALLER_SOURCE_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const CALLER_SOURCE_SHA256 := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const CALLER_SOURCE_START_PC := 0x80DF
const CALLER_SOURCE_FILE_OFFSET := "0x0000EF"
const CALLER_SOURCE_LENGTH := 126
const CALLER_SOURCE_OFFSET := CALLER_PC - CALLER_SOURCE_START_PC

var error_message := ""
var _configured := false
var _vector := PackedByteArray()
var _target_body := PackedByteArray()
var _caller_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_vector = PackedByteArray()
	_target_body = PackedByteArray()
	_caller_source = PackedByteArray()
	if not _load_a006_sources():
		return false
	if not _load_caller_source():
		return false
	if _vector != PackedByteArray([0x4C, 0xEB, 0xA4]):
		return _fail("The bank-$01 `$A006` vector is not `JMP $A4EB`.")
	if _target_body.size() != 0x126 or int(_target_body[_target_body.size() - 1]) != 0x60:
		return _fail("The preserved `$A4EB-$A610` target body does not end at the expected RTS byte.")
	var call_offset := CALLER_SOURCE_OFFSET
	if _caller_source.slice(call_offset, call_offset + 3) != PackedByteArray([0x20, 0x06, 0xA0]):
		return _fail("The bank-$00 caller no longer contains `$811C JSR $A006`.")
	_configured = true
	return true


## Executes only the checked JMP at `$A006`. `source_call` identifies the
## caller JSR and its already-pushed return word. `mapper_state.a000_prg_bank`
## must come from the preceding source-owned `$C4B9` result. The registers,
## stack, RAM, and mapper selection pass through unchanged; no RTS is claimed.
func execute_source_call(source_call: Dictionary, cpu_state: Dictionary,
		ram_before: Dictionary, mapper_state: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if int(source_call.get("caller_pc", -1)) != CALLER_PC \
			or int(source_call.get("target_pc", -1)) != TARGET_PC \
			or int(source_call.get("return_pc", -1)) != RETURN_PC:
		return _refused("The event must identify `$811C JSR $A006` returning to `$811F`.")
	var event_id := String(source_call.get("source_event_id", "")).strip_edges()
	if event_id.is_empty():
		return _refused("A source-owned caller event identity is required.")
	var pre_call_sp := int(source_call.get("pre_call_sp", -1))
	if pre_call_sp < 0 or pre_call_sp > 0xFF:
		return _refused("The caller's pre-JSR stack pointer must be provided as a byte.")
	var stack_variant: Variant = source_call.get("stack_page")
	if not stack_variant is PackedByteArray or stack_variant.size() != 0x100:
		return _refused("The source caller's 256-byte stack page is required.")
	var stack: PackedByteArray = stack_variant.duplicate()
	var entry_sp := (pre_call_sp - 2) & 0xFF
	if int(cpu_state.get("pc", -1)) != TARGET_PC or int(cpu_state.get("sp", -1)) != entry_sp:
		return _refused("CPU PC/SP do not match the post-JSR `$A006` entry.")
	if int(stack[(entry_sp + 1) & 0xFF]) != ((CALLER_PC + 2) & 0xFF) \
			or int(stack[(entry_sp + 2) & 0xFF]) != (((CALLER_PC + 2) >> 8) & 0xFF):
		return _refused("The stacked JSR return word does not match `$811E`.")
	for register_name: String in ["a", "x", "y", "p"]:
		var register_value := int(cpu_state.get(register_name, -1))
		if register_value < 0 or register_value > 0xFF:
			return _refused("CPU register `%s` must be supplied as a byte." % register_name)
	if int(mapper_state.get("a000_prg_bank", -1)) != A000_PRG_BANK:
		return _refused("The bank-$01 `$A000` mapping required by `$A006` is not established.")
	if not ram_before.has(PREMACH_SETUP_MAPPER_SHADOW) \
			or int(ram_before[PREMACH_SETUP_MAPPER_SHADOW]) != A000_PRG_BANK:
		return _refused("RAM `$0025` must carry the source mapper-select value `$01`.")

	var next_cpu := cpu_state.duplicate(true)
	next_cpu["pc"] = BODY_PC
	var result_stack := stack.duplicate()
	return {
		"ok": true,
		"status": "transferred_to_body",
		"next_pc": BODY_PC,
		"next_cpu_state": next_cpu,
		"ram_after": ram_before.duplicate(true),
		"stack_after": result_stack,
		"mapper_state_after": mapper_state.duplicate(true),
		"cpu_cycles": 3,
		"instruction_count": 1,
		"source_path": [CALLER_PC, TARGET_PC, BODY_PC],
		"source_transfer_receipt": {
			"source_event_id": event_id,
			"caller_pc": CALLER_PC,
			"target_pc": TARGET_PC,
			"return_pc": RETURN_PC,
			"vector_bytes": _vector.hex_encode(),
			"target_body_pc": BODY_PC,
			"status": "entered_target",
		},
		"trace_state_used": false,
		"emulator_data_used": false,
	}


## Executes the same checked JMP when the caller route carries logical JSR
## frames rather than an absolute 6502 stack. The body still owns the pending
## `$811C->$A006` return; this method does not synthesize an RTS receipt.
func execute_logical_source_call(source_call: Dictionary, cpu_contract: Dictionary,
		ram_before: Dictionary, mapper_state: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if int(source_call.get("caller_pc", -1)) != CALLER_PC \
			or int(source_call.get("target_pc", -1)) != TARGET_PC \
			or int(source_call.get("return_pc", -1)) != RETURN_PC:
		return _refused("The logical event must identify `$811C JSR $A006` returning to `$811F`.")
	var event_id := String(source_call.get("source_event_id", "")).strip_edges()
	if event_id.is_empty():
		return _refused("A source-owned caller event identity is required.")
	var frame_variant: Variant = source_call.get("logical_stack_frame", {})
	if not frame_variant is Dictionary:
		return _refused("The logical `$811C` JSR frame is required; physical SP is not inferred.")
	var frame: Dictionary = frame_variant
	if String(frame.get("kind", "")) != "rom_jsr" \
			or int(frame.get("caller_pc", -1)) != CALLER_PC \
			or int(frame.get("target_pc", -1)) != TARGET_PC \
			or int(frame.get("return_pc", -1)) != RETURN_PC \
			or int(frame.get("return_word", -1)) != (CALLER_PC + 2) \
			or String(frame.get("source_event_id", "")) != event_id:
		return _refused("The logical frame does not match the checked `$811C` JSR and `$811F` return.")
	if int(cpu_contract.get("pc", -1)) != TARGET_PC:
		return _refused("CPU contract PC must be the `$A006` entry.")
	for register_name: String in ["a", "x", "y"]:
		var register_value := int(cpu_contract.get(register_name, -1))
		if register_value < 0 or register_value > 0xFF:
			return _refused("CPU register `%s` must be supplied as a byte." % register_name)
	var p_mask := int(cpu_contract.get("p_known_mask", -1))
	var p_value := int(cpu_contract.get("p_known_value", -1))
	if p_mask < 0 or p_mask > 0xFF or p_value < 0 or p_value > 0xFF:
		return _refused("CPU status must carry an explicit known-mask/value contract.")
	if int(mapper_state.get("a000_prg_bank", -1)) != A000_PRG_BANK:
		return _refused("The bank-$01 `$A000` mapping required by `$A006` is not established.")
	if not ram_before.has(PREMACH_SETUP_MAPPER_SHADOW) \
			or int(ram_before[PREMACH_SETUP_MAPPER_SHADOW]) != A000_PRG_BANK:
		return _refused("RAM `$0025` must carry the source mapper-select value `$01`.")

	var next_cpu := cpu_contract.duplicate(true)
	next_cpu["pc"] = BODY_PC
	var pending_frames: Array[Dictionary] = [frame.duplicate(true)]
	return {
		"ok": true,
		"status": "transferred_to_body",
		"next_pc": BODY_PC,
		"next_cpu_state": next_cpu,
		"ram_after": ram_before.duplicate(true),
		"mapper_state_after": mapper_state.duplicate(true),
		"logical_stack_frames": pending_frames,
		"stack_model": "logical_source_jsr_frames",
		"cpu_cycles": 3,
		"instruction_count": 1,
		"source_path": [CALLER_PC, TARGET_PC, BODY_PC],
		"source_transfer_receipt": {
			"source_event_id": event_id,
			"caller_pc": CALLER_PC,
			"target_pc": TARGET_PC,
			"return_pc": RETURN_PC,
			"vector_bytes": _vector.hex_encode(),
			"target_body_pc": BODY_PC,
			"stack_model": "logical_source_jsr_frames",
			"status": "entered_target",
		},
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _load_a006_sources() -> bool:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Fresh pre-match `$A006` source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh pre-match `$A006` source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-a006-source-v1":
		return _fail("Fresh pre-match `$A006` source manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh pre-match `$A006` manifest targets another ROM revision.")
	var entries: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var entry: Dictionary = span_variant
			entries[String(entry.get("id", ""))] = entry
	for span_id: String in SOURCE_EXPECTATIONS:
		var expected: Dictionary = SOURCE_EXPECTATIONS[span_id]
		if not entries.has(span_id):
			return _fail("Fresh pre-match `$A006` manifest omits `%s`." % span_id)
		var entry: Dictionary = entries[span_id]
		for field: String in ["file", "cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(field, -1)) == int(expected[field]) \
					if field == "length" else String(entry.get(field, "")) == String(expected[field])
			if not matches:
				return _fail("Fresh pre-match `$A006` metadata differs for `%s` (%s)." % [span_id, field])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(expected["file"]))
		if bytes.size() != int(expected["length"]) \
				or _sha256(bytes) != String(expected["sha256"]):
			return _fail("Fresh pre-match `$A006` source span `%s` failed size/hash validation." % span_id)
		if String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Manifest byte listing differs from source span `%s`." % span_id)
		if expected.has("bytes") and bytes.hex_encode() != String(expected["bytes"]):
			return _fail("Source bytes differ from the reviewed `$A006` vector.")
		if span_id == "a006_vector":
			_vector = bytes
		else:
			_target_body = bytes
	return true


func _load_caller_source() -> bool:
	if not FileAccess.file_exists(CALLER_MANIFEST_PATH):
		return _fail("Fresh KICK OFF caller manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CALLER_MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Fresh KICK OFF caller manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh KICK OFF caller manifest targets another ROM revision.")
	var caller_entry: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == CALLER_SOURCE_FILE:
			caller_entry = span_variant
			break
	if caller_entry.is_empty() \
			or String(caller_entry.get("cpu_start", "")) != "$80DF" \
			or String(caller_entry.get("cpu_end_exclusive", "")) != "$815D" \
			or String(caller_entry.get("file_offset", "")) != CALLER_SOURCE_FILE_OFFSET \
			or int(caller_entry.get("length", -1)) != CALLER_SOURCE_LENGTH \
			or String(caller_entry.get("sha256", "")) != CALLER_SOURCE_SHA256:
		return _fail("Fresh caller span metadata differs from the audited `$80DF-$815C` bytes.")
	_caller_source = FileAccess.get_file_as_bytes(CALLER_ROOT + CALLER_SOURCE_FILE)
	if _caller_source.size() != CALLER_SOURCE_LENGTH \
			or _sha256(_caller_source) != CALLER_SOURCE_SHA256:
		return _fail("Fresh caller source failed size/hash validation.")
	if String(caller_entry.get("bytes", "")).to_lower().replace(" ", "") != _caller_source.hex_encode():
		return _fail("Fresh caller manifest byte listing differs from the packaged source.")
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	return {"ok": false, "error": message}
