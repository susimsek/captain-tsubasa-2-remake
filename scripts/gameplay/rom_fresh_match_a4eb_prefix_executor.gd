extends RefCounted
class_name RomFreshMatchA4ebPrefixExecutor
## Applies the hash-checked opening instructions and direct helpers in $A4EB.
## This is a bounded ROM-semantic model, not a general 6502 emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/"
const BODY_FILE := ROOT + "bank01_prematch_setup_body_A4EB_A610.bin"
const BODY_SHA256 := "1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587"
const HELPER_MANIFEST := ROOT + "a4eb_prefix_helpers_manifest.json"
const CLEANUP_HELPER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_cleanup_clear_task.gd")
const BODY_PREFIX := [
	0xA2, 0x6A, 0xA0, 0x6B, 0x20, 0x6F, 0x9B,
	0xA2, 0x7A, 0xA0, 0x7B, 0x20, 0x74, 0x9B,
	0x20, 0x7F, 0x9B, 0xA0, 0x05, 0xA2, 0xB3, 0x20, 0xC0, 0xB0,
]
const HELPER_SPECS := {
	"bank00_match_pointer_pair_store_9B6F_9B74.bin": {
		"start": "$9B6F", "end": "$9B74", "offset": "0x001B7F", "length": 5,
		"sha256": "23095e4aa356a47eac7312411861abb877a4ac6a0176553590cccbac1ba21701",
		"bytes": "869e849f60",
	},
	"bank00_match_pointer_enable_flag_9B74_9B7F.bin": {
		"start": "$9B74", "end": "$9B7F", "offset": "0x001B84", "length": 11,
		"sha256": "0385f9c6291457e0b0bdf7dab7362e788fc2d270185fd3650f155feb1f129a5d",
		"bytes": "86a084a1a59e0980859e60",
	},
}

var error_message := ""
var _configured := false
var _body := PackedByteArray()
var _helpers: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_body = FileAccess.get_file_as_bytes(BODY_FILE)
	if _body.size() != 0x126 or _sha256(_body) != BODY_SHA256:
		return _fail("The preserved A4EB body failed its pinned size/hash check.")
	if not _bytes_match(_body, 0, BODY_PREFIX):
		return _fail("The A4EB entry prefix or B0C0 callsite differs from the pinned ROM bytes.")
	var manifest_file := FileAccess.open(HELPER_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("The A4EB helper-source manifest is missing.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The A4EB helper-source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if String(manifest.get("schema", "")) != "ct2-fresh-match-a4eb-prefix-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The A4EB helper manifest targets another ROM revision.")
	var entries: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries[String(entry.get("file", ""))] = entry
	_helpers.clear()
	for file_name: String in HELPER_SPECS:
		var spec: Dictionary = HELPER_SPECS[file_name]
		if not entries.has(file_name):
			return _fail("The A4EB helper manifest omits %s." % file_name)
		var entry: Dictionary = entries[file_name]
		if String(entry.get("cpu_start", "")) != String(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != String(spec["end"]) \
				or String(entry.get("file_offset", "")) != String(spec["offset"]) \
				or int(entry.get("length", -1)) != int(spec["length"]) \
				or String(entry.get("sha256", "")) != String(spec["sha256"]) \
				or String(entry.get("bytes", "")) != String(spec["bytes"]):
			return _fail("Manifest provenance differs for %s." % file_name)
		var bytes := FileAccess.get_file_as_bytes(ROOT + file_name)
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]) \
				or bytes.hex_encode() != String(spec["bytes"]):
			return _fail("Packaged A4EB helper failed its size/hash/byte check: %s." % file_name)
		_helpers[file_name] = bytes
	var cleanup: Variant = CLEANUP_HELPER_SCRIPT.new()
	if not cleanup.configure_from_project_sources():
		return _fail("Direct $9B7F source failed verification: " + cleanup.error_message)
	_configured = true
	return true


## Consumes the live $811F caller result and the IRQ's source-derived mapper
## state. It runs the two tiny register helpers and the direct OAM clear, then
## stops immediately before the still-unimplemented $A500 JSR $B0C0.
func execute_from_postwait_result(postwait: Dictionary, irq_mapper: Dictionary,
		source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(postwait.get("ok", false)) \
			or String(postwait.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(postwait.get("status", "")) != "stopped_at_unexecuted_a006_body":
		return _refused("A successful live post-wait caller at the A4EB body is required.")
	if bool(postwait.get("trace_state_used", true)) \
			or bool(postwait.get("emulator_data_used", true)) \
			or bool(postwait.get("candidate_state_used", true)):
		return _refused("Trace, emulator, or candidate state cannot supply the A4EB entry.")
	var cpu_variant: Variant = postwait.get("next_cpu_state", {})
	var ram_variant: Variant = postwait.get("ram_after", {})
	var frames_variant: Variant = postwait.get("logical_stack_frames", [])
	var mapper_after_variant: Variant = postwait.get("mapper_state_after", {})
	if not cpu_variant is Dictionary or not ram_variant is Dictionary \
			or not frames_variant is Array or not mapper_after_variant is Dictionary:
		return _refused("The A4EB caller must carry source CPU, RAM, mapper, and logical-stack state.")
	var cpu: Dictionary = cpu_variant.duplicate(true)
	var ram: Dictionary = ram_variant.duplicate(true)
	var frames: Array = frames_variant.duplicate(true)
	var mapper_after: Dictionary = mapper_after_variant
	if int(cpu.get("pc", -1)) != 0xA4EB or frames.size() != 1 \
			or int(frames[0].get("return_pc", -1)) != 0x811F:
		return _refused("The caller must be at A4EB with its original $811F return frame pending.")
	if String(postwait.get("stack_model", "")) != "logical_source_jsr_frames":
		return _refused("The A4EB prefix requires the explicit logical-source JSR stack model.")
	if int(mapper_after.get("a000_prg_bank", -1)) != 0x01 \
			or int(irq_mapper.get("8000_prg_bank", -1)) != 0x00 \
			or bool(irq_mapper.get("prg_mode", true)):
		return _refused("The source mapper state does not map bank $01 at A000 and bank $00 at 8000.")
	for register_name: String in ["a", "x", "y", "p_known_mask", "p_known_value"]:
		var register_value := int(cpu.get(register_name, -1))
		if register_value < 0 or register_value > 0xFF:
			return _refused("A4EB CPU register/known-status field %s is not a byte." % register_name)
	var event_id := String(postwait.get("source_event_id", "")).strip_edges()
	if event_id.is_empty() or source_frame < 0:
		return _refused("The live source event identity and frame are required.")

	var writes: Array[Dictionary] = []
	var source_path: Array[int] = [0xA4EB, 0xA4ED, 0xA4EF, 0x9B6F, 0x9B71, 0x9B73,
		0xA4F2, 0xA4F4, 0xA4F6, 0x9B74, 0x9B76, 0x9B78, 0x9B7A, 0x9B7C, 0x9B7E,
		0xA4F9, 0x9B7F, 0x9B81, 0x9B83, 0x9B86, 0x9B87, 0x9B89, 0x9B8B, 0x9B8E,
		0x9B8F, 0x9B91, 0x9B93, 0x9B96, 0x9B99, 0x9B9C, 0x9B9F, 0xA4FC, 0xA4FE]

	cpu["x"] = 0x6A
	_set_nz_contract(cpu, 0x6A)
	cpu["y"] = 0x6B
	_set_nz_contract(cpu, 0x6B)
	ram[0x009E] = 0x6A
	ram[0x009F] = 0x6B
	writes.append({"source_pc": 0x9B6F, "address": 0x009E, "value": 0x6A})
	writes.append({"source_pc": 0x9B71, "address": 0x009F, "value": 0x6B})
	cpu["y"] = 0x7B
	_set_nz_contract(cpu, 0x7B)
	cpu["x"] = 0x7A
	_set_nz_contract(cpu, 0x7A)
	ram[0x00A0] = 0x7A
	ram[0x00A1] = 0x7B
	writes.append({"source_pc": 0x9B74, "address": 0x00A0, "value": 0x7A})
	writes.append({"source_pc": 0x9B76, "address": 0x00A1, "value": 0x7B})
	cpu["a"] = int(ram[0x009E]) | 0x80
	_set_nz_contract(cpu, int(cpu["a"]))
	ram[0x009E] = int(cpu["a"])
	writes.append({"source_pc": 0x9B7C, "address": 0x009E, "value": int(cpu["a"])})
	var flag_helper := {
		"a": int(cpu["a"]), "x": int(cpu["x"]), "y": int(cpu["y"]),
		"p_known_mask": int(cpu["p_known_mask"]),
		"p_known_value": int(cpu["p_known_value"]),
	}
	var clear_helper: Variant = CLEANUP_HELPER_SCRIPT.new()
	var clear_result: Dictionary = clear_helper.execute_direct_9b7f_oam_clear(flag_helper)
	if not bool(clear_result.get("ok", false)):
		return _refused("Direct ROM $9B7F OAM helper stopped: " + String(clear_result.get("error", "source state rejected")))
	var clear_writes: Array = clear_result.get("ram_writes", [])
	for write_variant in clear_writes:
		if not write_variant is Dictionary:
			return _refused("The direct OAM helper returned a malformed RAM write.")
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		var value := int(write.get("value", -1))
		if address < 0 or address >= 0x800 or value < 0 or value > 0xFF:
			return _refused("The direct OAM helper returned an out-of-range RAM write.")
		ram[address] = value
		writes.append(write.duplicate(true))
	cpu = clear_result.get("registers_after", {}).duplicate(true)
	cpu["y"] = 0x05
	_set_nz_contract(cpu, 0x05)
	cpu["x"] = 0xB3
	_set_nz_contract(cpu, 0xB3)
	cpu["pc"] = 0xA500
	for write in writes.slice(0, 5):
		write["source_event_id"] = event_id + ":A4EB-prefix"

	return {
		"ok": true,
		"status": "stopped_before_b0c0_stream",
		"completed": false,
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": event_id,
		"source_frame": source_frame,
		"source_path": source_path + [0xA500],
		"entry_cpu_state": cpu_variant.duplicate(true),
		"next_cpu_state": cpu,
		"entry_ram": ram_variant.duplicate(true),
		"ram_after": ram,
		"ram_writes": writes,
		"logical_stack_frames": frames,
		"next_source_call": {"caller_pc": 0xA500, "target_pc": 0xB0C0,
			"return_pc": 0xA503, "status": "not_executed"},
		"direct_oam_helper_result": clear_result,
		"helper_source_hashes": {
			"body": BODY_SHA256,
			"pointer_pair": String(HELPER_SPECS["bank00_match_pointer_pair_store_9B6F_9B74.bin"]["sha256"]),
			"pointer_flag": String(HELPER_SPECS["bank00_match_pointer_enable_flag_9B74_9B7F.bin"]["sha256"]),
		},
		"source_instruction_cycle_sum": 5210,
		"timing_scope": "Instruction-cycle sum for the bounded source path; FCEUX callback timing is not treated as physical NES timing.",
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"executes_6502": false,
	}


func _set_nz_contract(cpu: Dictionary, value: int) -> void:
	var mask := int(cpu.get("p_known_mask", 0)) | 0x82
	var known_value := int(cpu.get("p_known_value", 0)) & int(cpu.get("p_known_mask", 0))
	known_value &= 0x7D
	if (value & 0xFF) == 0:
		known_value |= 0x02
	if (value & 0x80) != 0:
		known_value |= 0x80
	cpu["p_known_mask"] = mask
	cpu["p_known_value"] = known_value & mask


func _bytes_match(source: PackedByteArray, start: int, expected: Array) -> bool:
	if start < 0 or start + expected.size() > source.size():
		return false
	for index in expected.size():
		if int(source[start + index]) != int(expected[index]):
			return false
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	return {"ok": false, "status": "source_state_rejected", "error": message,
		"source_rom_sha256": ROM_SHA256, "trace_state_used": false,
		"emulator_data_used": false, "executes_6502": false}
