extends RefCounted
class_name RomFreshPrematchA009Entry
## Executes the checked bank-$01 `$A009 JMP $A64C` entry transfer.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/"
const SOURCE_MANIFEST := SOURCE_ROOT + "manifest.json"
const SOURCE_FILE := "bank01_prematch_dispatch_entry_A009_A00C.bin"
const SOURCE_HASH := "d06ea7b10903702d0e149ef83ded6b610ed0fb9be8867ab24539bbaae8011524"
const CALLER_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const CALLER_MANIFEST := CALLER_ROOT + "manifest.json"
const CALLER_FILE := "bank00_title_to_first_match_setup_80DF_815C.bin"
const CALLER_HASH := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const ENTRY_PC := 0xA009
const TARGET_PC := 0xA64C
const CALLER_PC := 0x8142
const RETURN_PC := 0x8145

var error_message := ""
var _entry := PackedByteArray()
var _caller := PackedByteArray()
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_MANIFEST))
	if not manifest_variant is Dictionary:
		return _fail("Fresh prematch entry manifest is missing or malformed.")
	var manifest: Dictionary = manifest_variant
	var rom: Dictionary = manifest.get("rom", {})
	if String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh prematch entry manifest targets a different ROM.")
	var span: Dictionary = {}
	for row_variant in manifest.get("spans", []):
		if row_variant is Dictionary and String(row_variant.get("file", "")) == SOURCE_FILE:
			span = row_variant
			break
	if span.is_empty() or String(span.get("cpu_start", "")) != "$A009" \
			or String(span.get("cpu_end_exclusive", "")) != "$A00C" \
			or String(span.get("file_offset", "")) != "0x002019" \
			or int(span.get("length", -1)) != 3 or String(span.get("sha256", "")) != SOURCE_HASH:
		return _fail("The `$A009-$A00B` source manifest metadata differs from the audited ROM span.")
	_entry = FileAccess.get_file_as_bytes(SOURCE_ROOT + SOURCE_FILE)
	if _entry != PackedByteArray([0x4C, 0x4C, 0xA6]) or _sha256(_entry) != SOURCE_HASH \
			or String(span.get("bytes", "")).to_lower().replace(" ", "") != _entry.hex_encode():
		return _fail("ROM `$A009` JMP bytes failed exact-byte/hash validation.")
	var caller_manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(CALLER_MANIFEST))
	if not caller_manifest_variant is Dictionary:
		return _fail("Fresh KICK OFF caller manifest is missing or malformed.")
	var caller_manifest: Dictionary = caller_manifest_variant
	var caller_rom: Dictionary = caller_manifest.get("rom", {})
	if String(caller_rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Fresh KICK OFF caller manifest targets a different ROM.")
	var caller_span: Dictionary = {}
	for row_variant in caller_manifest.get("spans", []):
		if row_variant is Dictionary and String(row_variant.get("file", "")) == CALLER_FILE:
			caller_span = row_variant
			break
	if caller_span.is_empty() or String(caller_span.get("sha256", "")) != CALLER_HASH:
		return _fail("Fresh caller source span failed metadata validation.")
	_caller = FileAccess.get_file_as_bytes(CALLER_ROOT + CALLER_FILE)
	if _caller.size() != 126 or _sha256(_caller) != CALLER_HASH \
			or _caller.slice(CALLER_PC - 0x80DF, CALLER_PC - 0x80DF + 3) != PackedByteArray([0x20, 0x09, 0xA0]):
		return _fail("Caller `$8142` is not the checked `JSR $A009` instruction.")
	_configured = true
	return true


## Transfers through the ROM JMP while preserving the pending logical caller JSR.
func execute_logical_source_call(source_call: Dictionary, cpu_contract: Dictionary,
		mapper_state: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	var event_id := String(source_call.get("source_event_id", ""))
	var frame_variant: Variant = source_call.get("logical_stack_frame", {})
	if int(source_call.get("caller_pc", -1)) != CALLER_PC \
			or int(source_call.get("target_pc", -1)) != ENTRY_PC \
			or int(source_call.get("return_pc", -1)) != RETURN_PC \
			or event_id.is_empty() or not frame_variant is Dictionary:
		return _refused("The `$8142->$A009` call requires its checked logical JSR frame.")
	var frame: Dictionary = frame_variant
	if String(frame.get("kind", "")) != "rom_jsr" \
			or int(frame.get("caller_pc", -1)) != CALLER_PC \
			or int(frame.get("target_pc", -1)) != ENTRY_PC \
			or int(frame.get("return_pc", -1)) != RETURN_PC \
			or int(frame.get("return_word", -1)) != CALLER_PC + 2 \
			or String(frame.get("source_event_id", "")) != event_id:
		return _refused("Logical stack frame disagrees with the ROM `$8142` JSR bytes.")
	if int(cpu_contract.get("pc", -1)) != ENTRY_PC \
			or int(mapper_state.get("a000_prg_bank", -1)) != 0x01:
		return _refused("The `$A009` entry requires its source PC and the selected bank-$01 window.")
	for register_name: String in ["a", "x", "y"]:
		var value := int(cpu_contract.get(register_name, -1))
		if value < 0 or value > 0xFF:
			return _refused("Entry register `%s` must be a source-derived byte." % register_name)
	var mask := int(cpu_contract.get("p_known_mask", -1))
	var value := int(cpu_contract.get("p_known_value", -1))
	if mask < 0 or mask > 0xFF or value < 0 or value > 0xFF:
		return _refused("Entry processor flags need a known-mask/value contract.")
	return {
		"ok": true,
		"status": "transferred_to_prematch_body",
		"source_rom_sha256": ROM_SHA256,
		"caller_pc": CALLER_PC,
		"entry_pc": ENTRY_PC,
		"target_pc": TARGET_PC,
		"return_pc": RETURN_PC,
		"entry_bytes": _entry.hex_encode(),
		"source_call": source_call.duplicate(true),
		"logical_stack_frame": frame.duplicate(true),
		"next_cpu_contract": {"pc": TARGET_PC, "a": int(cpu_contract["a"]),
			"x": int(cpu_contract["x"]), "y": int(cpu_contract["y"]),
			"p_known_mask": mask, "p_known_value": value & mask,
			"stack": "logical `$8142->$A009` JSR remains pending"},
		"source_path": [CALLER_PC, ENTRY_PC, TARGET_PC],
		"cpu_cycles": 3,
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
	}


func _refused(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_state_required_or_mismatch", "error": reason}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
