extends RefCounted
class_name RomE3caNoDirectionCallExecutor
## Executes the source-derived fresh-match `$CA55->$E3CA` no-direction path.
## This is a narrow byte-checked executor, not a general 6502 emulator.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/e3ca_no_direction_call/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

const EXPECTED_SPANS := {
	"entry": {
		"file": "fixed_entry_E3CA_E3D5.bin",
		"cpu_start": "0xE3CA",
		"cpu_end_exclusive": "0xE3D6",
		"file_offset": "0x03E3DA",
		"length": 12,
		"sha256": "7100463bf16eadd91886eeb73c7afadd11972c955be5a29b99fa79d5a1afc2b1",
	},
	"return": {
		"file": "fixed_return_E406.bin",
		"cpu_start": "0xE406",
		"cpu_end_exclusive": "0xE407",
		"file_offset": "0x03E416",
		"length": 1,
		"sha256": "8d33f520a3c4cef80d2453aef81b612bfe1cb44c8b2025630ad38662763f13d3",
	},
}
const SOURCE_STARTS := {"entry": 0xE3CA, "return": 0xE406}
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const EXPECTED_EE9F_MANIFEST := "res://reference/rom_extract/gameplay/ee9f_empty_actor_call/manifest.json"
const EXPECTED_EE9F_ACTOR_INIT_MANIFEST := "res://reference/rom_extract/gameplay/ee9f_actor_init_80/manifest.json"

var error_message := ""
var _configured := false
var _source: Dictionary = {}
var _ram := PackedByteArray()
var _stack := PackedByteArray()
var _cpu: Dictionary = {}
var _mapper: Dictionary = {}
var _writes: Array[Dictionary] = []
var _instruction_pcs: Array[int] = []


## Loads only the project's hash-checked ROM-byte spans; runtime never reads the ROM file.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The `$E3CA` source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The `$E3CA` source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	var spans: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-e3ca-no-direction-source-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256 \
			or not spans is Array or spans.size() != EXPECTED_SPANS.size():
		return _fail("The `$E3CA` manifest targets an unsupported ROM or source schema.")
	for name_variant in EXPECTED_SPANS:
		var name := String(name_variant)
		var expected: Dictionary = EXPECTED_SPANS[name]
		var found: Dictionary = {}
		for span_variant in spans:
			if span_variant is Dictionary and String(span_variant.get("file", "")) == String(expected["file"]):
				found = span_variant
				break
		if found.is_empty():
			return _fail("The source manifest omits `%s`." % String(expected["file"]))
		for key: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			if found.get(key) != expected[key]:
				return _fail("Manifest metadata differs for `%s` field `%s`." % [String(expected["file"]), key])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(expected["file"]))
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Source bytes failed length, hash, or manifest-byte validation: `%s`." % String(expected["file"]))
		_source[name] = bytes
	if not _verify_instruction_recipes():
		return false
	_configured = true
	return true


## Takes only an `$EE9F` source result and its actual `$CA55->$E3CA` ROM caller request.
## The result's RAM and stack are the executor's sole machine-state inputs.
func execute_from_source_call(ee9f_result: Dictionary, caller_request: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked `$E3CA` source package first.")
	var preflight := _validate_entry(ee9f_result, caller_request)
	if not bool(preflight.get("ok", false)):
		return preflight
	var source_ram: PackedByteArray = ee9f_result["ram_image"]
	var source_stack: PackedByteArray = ee9f_result["stack_page"]
	_ram = source_ram.duplicate()
	_stack = source_stack.duplicate()
	var returned_registers: Dictionary = ee9f_result["registers"]
	var source_mapper: Dictionary = ee9f_result["mapper"]
	_cpu = {
		"a": int(caller_request["a"]), "x": int(caller_request["x"]),
		"y": int(caller_request["y"]), "sp": int(caller_request["sp"]),
		"pc": 0xCA55,
		"bank_low": int(caller_request["bank_low"]),
		"bank_high": int(caller_request["bank_high"]),
		"p": int(returned_registers.get("p_known_value", 0)),
		"p_known_mask": int(returned_registers.get("p_known_mask", 0)),
	}
	_mapper = source_mapper.duplicate(true)
	_writes.clear()
	_instruction_pcs.clear()

	# Execute the caller's JSR and the supported no-direction callee branch.
	_jsr(0xCA55, 0xE3CA)
	if not _expect(0xE3CA, [0xAD, 0xFB, 0x05]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3CA)
	_set_a(int(_ram[0x05FB]))
	if not _expect(0xE3CD, [0xD0, 0x07]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3CD)
	if int(_cpu["a"]) != 0:
		_cpu["pc"] = 0xE3D6
		return _stopped("unsupported_nonfresh_match_branch", 0xE3D6,
			"`$05FB` is nonzero; the alternate `$E3D6` branch is outside this source slice.")

	if not _expect(0xE3CF, [0xAD, 0x1C, 0x00]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3CF)
	_set_a(int(_ram[0x001C]))
	if not _expect(0xE3D2, [0x29, 0x0F]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3D2)
	_set_a(int(_cpu["a"]) & 0x0F)
	if not _expect(0xE3D4, [0xF0, 0x30]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3D4)
	if int(_cpu["a"]) != 0:
		_cpu["pc"] = 0xE3D6
		return _stopped("unsupported_directional_input", 0xE3D6,
			"`$001C & $0F` is nonzero; movement and the `$E3D6` path are not implemented.",
			{"controller_value": int(_ram[0x001C]), "masked_direction_bits": int(_cpu["a"])})
	var branch_target := 0xE3D6 + _signed_byte(0x30)
	if branch_target != 0xE406:
		return _stopped("source_state_uncertainty", 0xE3D4,
			"ROM-derived BEQ displacement no longer resolves to `$E406`.")
	_cpu["pc"] = branch_target
	if not _expect(0xE406, [0x60]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE406)
	_rts(0xE406)
	if int(_cpu["pc"]) != 0xCA58 or int(_cpu["sp"]) != 0x2A:
		return _stopped("source_state_uncertainty", int(_cpu["pc"]),
			"`$E3CA` RTS did not restore caller PC `$CA58` and SP `$2A`.")
	return {
		"ok": true,
		"status": "returned_to_source_caller",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry": {"slot_base": 0x01, "call_pc": 0xCA55, "target_pc": 0xE3CA,
			"expected_return_pc": 0xCA58,
			"source": "ROM-byte `$EE9F` return state and root caller's `$CA55->$E3CA` request"},
		"registers": _register_snapshot(),
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"memory_writes": _writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"instruction_count": _instruction_pcs.size(),
		"returned_to_caller": true,
		"movement_applied": false,
		"field_input_branch": "no_direction",
		"ppu_bus_events": [],
		"ppu_cycle_timing_modeled": false,
		"audio_effects_modeled": false,
	}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"supports_only_fresh_no_direction_branch": true,
		"executes_general_6502": false,
		"reads_supplied_rom_at_runtime": false,
		"reads_trace_ram_or_images": false,
	}


func _validate_entry(ee9f_result: Dictionary, caller_request: Dictionary) -> Dictionary:
	var ee9f_manifest := String(ee9f_result.get("source_manifest", ""))
	var has_live_actor_init := ee9f_manifest == EXPECTED_EE9F_ACTOR_INIT_MANIFEST
	if not bool(ee9f_result.get("ok", false)) \
			or (ee9f_manifest != EXPECTED_EE9F_MANIFEST and not has_live_actor_init) \
			or not bool(ee9f_result.get("returned_to_caller", false)):
		return _failure("Input is not the successful ROM-derived `$EE9F` call result.")
	if has_live_actor_init:
		var actor_init_variant: Variant = ee9f_result.get("active_actor_init", {})
		if not actor_init_variant is Dictionary:
			return _failure("The `$053A=$80` `$EE9F` result omits its actor-init provenance.")
		var actor_init: Dictionary = actor_init_variant
		var actor_init_status := String(actor_init.get("status", ""))
		if actor_init_status == "returned_to_ee9f_actor_loop":
			if int(actor_init.get("active_animation_id", -1)) != 0x8F \
					or int(actor_init.get("stream_start", -1)) != 0x9885 \
					or int(actor_init.get("stream_pointer_after_f0", -1)) != 0x98AA \
					or int(actor_init.get("actor_packets_executed", -1)) != 5:
				return _failure("The `$053A=$80` `$EE9F` result lacks the verified five-packet `$8F` seed path.")
		elif actor_init_status == "existing_actor_state":
			if int(actor_init.get("continuation_from", -1)) != 0xEEFD \
					or String(actor_init.get("source", "")) != "live actor record at the `$EEFD` continuation":
				return _failure("The `$EE9F` result omits provenance for its existing active-actor continuation.")
		else:
			return _failure("The `$EE9F` result has an unsupported actor-state provenance.")
	var entry_variant: Variant = ee9f_result.get("entry", {})
	var registers_variant: Variant = ee9f_result.get("registers", {})
	var mapper_variant: Variant = ee9f_result.get("mapper", {})
	var ram_variant: Variant = ee9f_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = ee9f_result.get("stack_page", PackedByteArray())
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _failure("`$EE9F` result omits its source return, registers, mapper, RAM, or stack state.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram_image: PackedByteArray = ram_variant
	var stack_page: PackedByteArray = stack_variant
	if String(entry.get("source", "")) != "live slot-$01 scheduler dispatch and RAM/stack snapshot" \
			or int(entry.get("slot_base", -1)) != 0x01 \
			or int(entry.get("call_pc", -1)) != 0xCA52 \
			or int(entry.get("target_pc", -1)) != 0xEE9F \
			or int(entry.get("expected_return_pc", -1)) != 0xCA55 \
			or int(registers.get("pc", -1)) != 0xCA55 \
			or int(registers.get("sp", -1)) != 0x2A \
			or int(registers.get("a", -1)) != 0xF8 \
			or int(registers.get("p_known_mask", -1)) != 0xC3 \
			or int(registers.get("p_known_value", -1)) != 0x03 \
			or int(mapper.get("task_bank_low", -1)) != 0x00 \
			or int(mapper.get("task_bank_high", -1)) != 0x01:
		return _failure("`$EE9F` returned state does not match the live fresh-route caller boundary.")
	if ram_image.size() != RAM_SIZE or stack_page.size() != STACK_SIZE:
		return _failure("`$EE9F` return must contain a 2 KiB CPU RAM image and 256-byte stack page.")
	for stack_offset in range(STACK_SIZE):
		if int(ram_image[0x0100 + stack_offset]) != int(stack_page[stack_offset]):
			return _failure("`$EE9F` RAM and stack-page mirrors disagree at `$%02X`." % stack_offset)
	if int(ram_image[0x05FB]) != 0 or (int(ram_image[0x001C]) & 0x0F) != 0:
		return _failure("Live `$EE9F` state does not satisfy the ROM-observed fresh/no-direction branch.")
	if has_live_actor_init:
		var oam_cursor := int(ram_image[0x003B])
		var sprite_count := int(ram_image[0x0048])
		if int(ram_image[0x053A]) != 0 or int(ram_image[0x053B]) != 0 \
				or int(ram_image[0x053C]) != 0x8F or int(ram_image[0x053D]) != 0 \
				or ram_image.slice(0x0494, 0x0498) != PackedByteArray([0x2C, 0x0B, 0x05, 0x07]) \
				or int(ram_image[0x004C]) != 0xAA or int(ram_image[0x004D]) != 0x98 \
				or int(ram_image[0x003A]) != 6 \
				or oam_cursor > 0x100 or (oam_cursor & 0x03) != 0 \
				or sprite_count != oam_cursor / 4:
			var state_summary := PackedByteArray([
				int(ram_image[0x053A]), int(ram_image[0x053B]),
				int(ram_image[0x053C]), int(ram_image[0x053D]),
				int(ram_image[0x004C]), int(ram_image[0x004D]),
				int(ram_image[0x003A]), int(ram_image[0x003B]),
				int(ram_image[0x0048]), int(ram_image[0x0547]),
				int(ram_image[0x055C]), int(ram_image[0x0571]),
				int(ram_image[0x0586]), int(ram_image[0x059B]),
				int(ram_image[0x05B0]),
			])
			return _failure("Live `$EE9F` actor state mismatch; fields `$053A-$053D,$004C-$004D,$003A,$003B,$0048,record flags` = " + state_summary.hex_encode() + "; packet=`" + ram_image.slice(0x0494, 0x0498).hex_encode() + "`.")
		var expected_actor_flags: Array[int] = [0x81, 0x81, 0x80, 0x80, 0x80, 0x00]
		for actor_index in range(expected_actor_flags.size()):
			var returned_flags := int(ram_image[0x0547 + actor_index * 0x15])
			if (returned_flags & 0x80) != (expected_actor_flags[actor_index] & 0x80):
				return _failure("The ROM `$F1` actor at index %d has returned active bit `$%02X`; expected `$%02X`." % [
					actor_index, returned_flags & 0x80, expected_actor_flags[actor_index] & 0x80])
	if not bool(caller_request.get("ok", false)) \
			or String(caller_request.get("status", "")) != "call_requested" \
			or int(caller_request.get("slot_base", -1)) != 0x01 \
			or int(caller_request.get("source_pc", -1)) != 0xCA55 \
			or int(caller_request.get("target_cpu_address", -1)) != 0xE3CA \
			or int(caller_request.get("expected_return_pc", -1)) != 0xCA58 \
			or int(caller_request.get("call_ordinal", -1)) != 1 \
			or int(caller_request.get("a", -1)) != int(registers.get("a", -2)) \
			or int(caller_request.get("x", -1)) != int(registers.get("x", -2)) \
			or int(caller_request.get("y", -1)) != int(registers.get("y", -2)) \
			or int(caller_request.get("sp", -1)) != int(registers.get("sp", -2)) \
			or int(caller_request.get("bank_low", -1)) != int(registers.get("bank_low", -2)) \
			or int(caller_request.get("bank_high", -1)) != int(registers.get("bank_high", -2)):
		return _failure("Caller request is not the exact ROM-owned `$CA55->$E3CA` second call.")
	return {"ok": true}


func _verify_instruction_recipes() -> bool:
	if _source_byte("entry", 0xE3CA) != 0xAD or _source_byte("entry", 0xE3CD) != 0xD0 \
			or _source_byte("entry", 0xE3CF) != 0xAD or _source_byte("entry", 0xE3D2) != 0x29 \
			or _source_byte("entry", 0xE3D4) != 0xF0 or _source_byte("return", 0xE406) != 0x60:
		return _fail("ROM source bytes do not match the documented `$E3CA` no-direction recipe.")
	return true


func _expect(cpu_address: int, expected: Array[int]) -> bool:
	var source_name := "entry" if cpu_address < 0xE406 else "return"
	for offset in range(expected.size()):
		if _source_byte(source_name, cpu_address + offset) != expected[offset]:
			return _set_error("Unsupported `$E3CA` source byte at `$%04X` (expected `$%02X`)." % [cpu_address + offset, expected[offset]])
	return true


func _source_byte(name: String, cpu_address: int) -> int:
	var bytes: PackedByteArray = _source.get(name, PackedByteArray())
	var start := int(SOURCE_STARTS.get(name, -1))
	var offset := cpu_address - start
	if offset < 0 or offset >= bytes.size():
		return -1
	return int(bytes[offset])


func _signed_byte(value: int) -> int:
	return value - 0x100 if value >= 0x80 else value


func _jsr(call_pc: int, target: int) -> void:
	_record(call_pc)
	var return_address := call_pc + 2
	_push((return_address >> 8) & 0xFF, call_pc)
	_push(return_address & 0xFF, call_pc)
	_cpu["pc"] = target


func _rts(pc: int) -> void:
	var low := _pop(pc)
	var high := _pop(pc)
	_cpu["pc"] = (((high << 8) | low) + 1) & 0xFFFF


func _push(value: int, pc: int) -> void:
	var sp := int(_cpu["sp"]) & 0xFF
	_write_ram(0x0100 + sp, value, pc)
	_cpu["sp"] = (sp - 1) & 0xFF


func _pop(_pc: int) -> int:
	var sp := (int(_cpu["sp"]) + 1) & 0xFF
	_cpu["sp"] = sp
	return int(_ram[0x0100 + sp])


func _write_ram(address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	_ram[address] = byte_value
	if address >= 0x0100 and address < 0x0200:
		_stack[address & 0xFF] = byte_value
	_writes.append({"space": "cpu_ram", "address": address, "value": byte_value, "pc": pc})


func _set_a(value: int) -> void:
	_cpu["a"] = value & 0xFF
	_set_nz(int(_cpu["a"]))


func _set_nz(value: int) -> void:
	var flags := int(_cpu.get("p", 0)) & 0xFF
	flags &= ~0x82
	if (value & 0x80) != 0:
		flags |= 0x80
	if (value & 0xFF) == 0:
		flags |= 0x02
	_cpu["p"] = flags


func _record(cpu_address: int) -> void:
	_instruction_pcs.append(cpu_address)
	_cpu["pc"] = cpu_address


func _register_snapshot() -> Dictionary:
	var registers := _cpu.duplicate(true)
	var known_mask := int(_cpu.get("p_known_mask", 0)) & 0xFF
	registers.erase("p")
	registers["p_known_value"] = int(_cpu.get("p", 0)) & known_mask
	registers["p_known_mask"] = known_mask
	registers["p_unknown_mask"] = (~known_mask) & 0xFF
	return registers


func _stopped(status: String, stop_pc: int, reason: String,
		detail: Dictionary = {}) -> Dictionary:
	_cpu["pc"] = stop_pc
	return {
		"ok": false,
		"status": status,
		"stop_pc": stop_pc,
		"reason": reason,
		"partial_state": {"registers": _register_snapshot(), "mapper": _mapper.duplicate(true),
			"ram_image": _ram.duplicate(), "stack_page": _stack.duplicate(),
			"memory_writes": _writes.duplicate(true), "instruction_pcs": _instruction_pcs.duplicate()},
		"detail": detail,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
	}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "rejected_entry_state", "error": message}


func _set_error(message: String) -> bool:
	error_message = message
	return false


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()
