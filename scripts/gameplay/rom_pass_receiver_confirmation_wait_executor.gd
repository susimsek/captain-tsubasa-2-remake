extends RefCounted
class_name RomPassReceiverConfirmationWaitExecutor
## Executes the ROM's post-confirm `$D70C` call into the shared `$CC46` waiter
## up to its first `$CC50` callsite before the scheduler-owned JSR/save.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/manifest.json"
const MANIFEST_SHA256 := "a5222fd8d3573e27fb2f530ea9c9baebe9eeb091f26a52ae9f861f8dd9a4f403"
const CONFIRMATION_CALLER_PATH := "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/pass_confirmation_wait_return_D70C_D717.bin"
const SHARED_WAITER_PATH := "res://reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_shared_waiter_CC46_CCD2.bin"
const CONFIRMATION_CALLER_SHA256 := "19344ff4a339d04a6004f5ab7d4656bfe2a017f3e51c63770f5d4e300f723aa4"
const SHARED_WAITER_SHA256 := "21a4cd33eb56fe3d4da516e0eff910ff375a8d7c3ff42bfa46dfb691a846d5cc"

const ENTRY_PC := 0xD70C
const WAITER_PC := 0xCC46
const FIRST_YIELD_CALLSITE_PC := 0xCC50
const FIRST_YIELD_TARGET_PC := 0xCB0F
const RAM_SIZE := 0x0800
const STACK_SIZE := 0x0100
const STACK_BASE := 0x0100

const CALLER_PREFIX := [0x20, 0x46, 0xCC]
const WAITER_PREFIX := [
	0xA9, 0x00, 0x8D, 0xF4, 0x05, 0xA9, 0x06, 0x48,
	0xA9, 0x01, 0x20, 0x0F, 0xCB,
]

var error_message := ""
var _configured := false
var _caller_bytes := PackedByteArray()
var _waiter_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	if not FileAccess.file_exists(MANIFEST_PATH) \
			or FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		return _fail("PASS holder-transfer manifest is missing or differs from the pinned source package.")
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return _fail("PASS holder-transfer manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var source_rom: Dictionary = manifest.get("source_rom", {})
	if String(manifest.get("schema", "")) != "ct2-pass-receiver-holder-transfer-source-v1" \
			or String(source_rom.get("sha256", "")) != ROM_SHA256 \
			or int(source_rom.get("size_bytes", -1)) != 393232 \
			or int(source_rom.get("mapper", -1)) != 4:
		return _fail("PASS holder-transfer sources do not identify the pinned mapper-4 ROM revision.")
	_caller_bytes = _load_manifest_span(manifest, "pass_confirmation_wait_return_D70C_D717",
		CONFIRMATION_CALLER_PATH, CONFIRMATION_CALLER_SHA256, 11)
	if _caller_bytes.is_empty():
		return false
	_waiter_bytes = _load_fixed_dependency(SHARED_WAITER_PATH, SHARED_WAITER_SHA256, 140)
	if _waiter_bytes.is_empty():
		return false
	if _caller_bytes.slice(0, CALLER_PREFIX.size()) != PackedByteArray(CALLER_PREFIX) \
			or _waiter_bytes.slice(0, WAITER_PREFIX.size()) != PackedByteArray(WAITER_PREFIX):
		return _fail("The `$D70C->$CC46->$CC50` caller/waiter opcodes differ from the manifest-pinned ROM bytes.")
	_configured = true
	return true


## Consumes a scheduler-owned PASS confirmation boundary and returns the real
## ROM callsite state immediately before `$CC50: JSR $CB0F`. The scheduler
## performs that JSR/save. No NMI, PPU transfer, or later waiter instruction runs.
func execute_from_live_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var validation := _validate_boundary(boundary)
	if not bool(validation.get("ok", false)):
		return _failure(String(validation.get("status", "invalid_live_boundary")),
			String(validation.get("error", "Invalid PASS confirmation boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var cpu := {
		"a": int(boundary.get("a", 0)) & 0xFF,
		"x": int(boundary.get("x", 0)) & 0xFF,
		"y": int(boundary.get("y", 0)) & 0xFF,
		"p": (int(boundary.get("p", 0x20)) | 0x20) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF,
		"sp": int(boundary.get("sp", -1)) & 0xFF,
		"pc": ENTRY_PC,
	}
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instructions: Array[Dictionary] = []
	var calls: Array[Dictionary] = []
	var entry_sp := int(cpu["sp"])
	var old_wait_flag := int(ram[0x05F4])

	# `$D70C: JSR $CC46`; execute the call frame, then interpret the waiter prefix.
	_record_instruction(instructions, ENTRY_PC, 0x1E, _caller_bytes, 0, 3)
	_push_jsr(ram, stack, stack_writes, cpu, ENTRY_PC, WAITER_PC, 0xD70F)
	calls.append({"bank": 0x1E, "callsite": ENTRY_PC, "target": WAITER_PC,
		"return_word": 0xD70E, "return_pc": 0xD70F,
		"sp_after_push": int(cpu["sp"]), "purpose": "shared_pass_confirmation_waiter"})
	cpu["pc"] = WAITER_PC

	# `$CC46:$ LDA #$00; STA $05F4; LDA #$06; PHA; LDA #$01`.
	_record_instruction(instructions, 0xCC46, 0x1E, _waiter_bytes, 0, 2)
	_set_lda(cpu, 0x00)
	_record_instruction(instructions, 0xCC48, 0x1E, _waiter_bytes, 2, 3)
	source_reads.append({"source_pc": 0xCC48, "address": 0x05F4,
		"value": old_wait_flag, "role": "prior_wait_flag"})
	_write_ram(ram, writes, 0xCC48, 0x05F4, 0x00)
	_record_instruction(instructions, 0xCC4B, 0x1E, _waiter_bytes, 5, 2)
	_set_lda(cpu, 0x06)
	_record_instruction(instructions, 0xCC4D, 0x1E, _waiter_bytes, 7, 1)
	_push_value(ram, stack, stack_writes, cpu, 0xCC4D, int(cpu["a"]), "pha")
	_record_instruction(instructions, 0xCC4E, 0x1E, _waiter_bytes, 8, 2)
	_set_lda(cpu, 0x01)

	# Stop before the actual ROM JSR; the scheduler owns its stack writes/save.
	_record_instruction(instructions, FIRST_YIELD_CALLSITE_PC, 0x1E,
		_waiter_bytes, 10, 3)
	var yield_sp_before := int(cpu["sp"])
	cpu["pc"] = FIRST_YIELD_CALLSITE_PC
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[STACK_BASE + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = FIRST_YIELD_CALLSITE_PC
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS confirmation waiter reached `$CC50` before scheduler-owned JSR/save"
	return {
		"ok": true,
		"status": "pass_confirmation_wait_callsite_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": MANIFEST_SHA256,
		"entry_pc": ENTRY_PC,
		"entry_bank": 0x1E,
		"entry_sp": entry_sp,
		"exit_pc": FIRST_YIELD_CALLSITE_PC,
		"exit_bank": 0x1E,
		"mapper": (boundary["mapper"] as Dictionary).duplicate(true),
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": [ENTRY_PC, 0xCC46, 0xCC48, 0xCC4B,
			0xCC4D, 0xCC4E, FIRST_YIELD_CALLSITE_PC],
		"instructions": instructions,
		"source_reads": source_reads,
		"source_writes": writes,
		"source_stack_writes": stack_writes,
		"calls": calls,
		"call_request": {"kind": "rom_jsr_request", "callsite_pc": FIRST_YIELD_CALLSITE_PC,
			"target_pc": FIRST_YIELD_TARGET_PC, "target_bank": 0x1E,
			"return_pc": 0xCC53, "return_word": 0xCC52,
			"sp_before_push": yield_sp_before, "scheduler_must_push_call_frame": true},
		"next_boundary_snapshot": next_boundary,
		"task_save_executed": false,
		"external_nmi_consumed": false,
		"ppu_bus_events": [],
		"apu_events": [],
		"ppu_effects_applied": false,
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"instruction_level_parity_claimed": false,
		"input_boundary_fixture": bool(boundary.get("test_fixture", false)),
		"scope": "ROM instructions through the `$CC50` callsite; the scheduler performs the JSR/save and subsequent NMI/waiter resumes remain caller-owned.",
	}


func _validate_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "capture_state_rejected",
				"error": "Emulator captures cannot seed a PASS confirmation waiter boundary."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var fixture := bool(boundary.get("test_fixture", false))
	var source_label := String(boundary.get("source_label", ""))
	var source_label_valid := source_label.begins_with("ROM-byte PASS receiver A confirmation") \
		or (fixture and source_label == "synthetic D70C waiter fixture; not a route result")
	if not bool(boundary.get("ok", true)) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != ENTRY_PC \
			or int(boundary.get("sp", -1)) != 0x4A \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or not mapper is Dictionary \
			or int(mapper.get("fixed_bank", mapper.get("fixed_low", -1))) != 0x1E \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or (ram as PackedByteArray).slice(0x0100, 0x0200) != stack \
			or int((ram as PackedByteArray)[0x0000]) != 0x05 \
			or int((ram as PackedByteArray)[0x0441]) != 0x06 \
			or int((ram as PackedByteArray)[0x05FC]) != 0x0A \
			or int((ram as PackedByteArray)[0x0638]) != 0x78 \
			or int((ram as PackedByteArray)[0x062D]) != 0x81 \
			or int((ram as PackedByteArray)[0x0024]) != 0x1C \
			or int((ram as PackedByteArray)[0x0025]) != 0x1D \
			or bool(boundary.get("trace_state_used", true)) \
			or bool(boundary.get("test_fixture", false)) != fixture \
			or not source_label_valid:
		return {"ok": false, "status": "invalid_live_boundary",
			"error": "Confirmation waiter requires the live slot-$05 `$D70C` `$1C/$1D` boundary and its RAM/stack source label."}
	return {"ok": true}


func _load_manifest_span(manifest: Dictionary, name: String, path: String,
		expected_sha: String, expected_size: int) -> PackedByteArray:
	var spans: Variant = manifest.get("spans", [])
	if not spans is Array:
		_fail("PASS holder-transfer manifest has no ROM span list.")
		return PackedByteArray()
	for row_variant: Variant in spans:
		if row_variant is Dictionary and String((row_variant as Dictionary).get("name", "")) == name:
			var row: Dictionary = row_variant
			var bytes := _read_pinned_bytes(path, expected_sha, expected_size)
			if bytes.is_empty():
				return bytes
			if String(row.get("cpu_start", "")) != "0xD70C" \
					or String(row.get("cpu_end_exclusive", "")) != "0xD717" \
					or int(row.get("length_bytes", -1)) != expected_size \
					or String(row.get("sha256", "")) != expected_sha:
				_fail("PASS waiter caller span metadata differs from its pinned CPU interval or hash.")
				return PackedByteArray()
			return bytes
	_fail("PASS holder-transfer manifest is missing span `%s`." % name)
	return PackedByteArray()


func _load_fixed_dependency(path: String, expected_sha: String,
		expected_size: int) -> PackedByteArray:
	var bytes := _read_pinned_bytes(path, expected_sha, expected_size)
	if bytes.is_empty():
		return bytes
	return bytes


func _read_pinned_bytes(path: String, expected_sha: String,
		expected_size: int) -> PackedByteArray:
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != expected_sha:
		_fail("A hash-pinned PASS waiter source file is missing or changed: " + path)
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() != expected_size:
		_fail("A hash-pinned PASS waiter source span has the wrong length: " + path)
		return PackedByteArray()
	return bytes


func _record_instruction(events: Array[Dictionary], pc: int, bank: int,
		source: PackedByteArray, offset: int, length: int) -> void:
	events.append({"pc": pc, "bank": bank,
		"bytes": source.slice(offset, offset + length)})


func _push_jsr(ram: PackedByteArray, stack: PackedByteArray,
		stack_writes: Array[Dictionary], cpu: Dictionary, callsite: int,
		target: int, return_pc: int) -> void:
	var return_word := (return_pc - 1) & 0xFFFF
	_push_value(ram, stack, stack_writes, cpu, callsite,
		(return_word >> 8) & 0xFF, "jsr_push_high")
	_push_value(ram, stack, stack_writes, cpu, callsite,
		return_word & 0xFF, "jsr_push_low")
	cpu["pc"] = target


func _push_value(ram: PackedByteArray, stack: PackedByteArray,
		stack_writes: Array[Dictionary], cpu: Dictionary, source_pc: int,
		value: int, role: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	var address := STACK_BASE + sp
	stack[sp] = value & 0xFF
	ram[address] = value & 0xFF
	stack_writes.append({"source_pc": source_pc, "address": address,
		"value": value & 0xFF, "role": role})
	cpu["sp"] = (sp - 1) & 0xFF


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary],
		source_pc: int, address: int, value: int) -> void:
	var previous := int(ram[address])
	ram[address] = value & 0xFF
	writes.append({"source_pc": source_pc, "trace_pc": (source_pc + 3) & 0xFFFF,
		"address": address, "old": previous, "value": value & 0xFF})


func _set_lda(cpu: Dictionary, value: int) -> void:
	var result := value & 0xFF
	cpu["a"] = result
	var p := int(cpu["p"]) & 0xFF
	p = (p & ~0x82) | (0x02 if result == 0 else 0) | (0x80 if (result & 0x80) != 0 else 0)
	cpu["p"] = (p | 0x20) & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | 0x82


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message}
