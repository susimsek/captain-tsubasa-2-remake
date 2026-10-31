extends RefCounted
class_name RomFreshScenario36QueueExecutor
## Executes the fresh-match `$DB0E->$CBB0->$CB0F` caller from packaged ROM bytes.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCENARIO_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json"
const SCENARIO_ROOT_NAME := "scenario_36_fresh_kickoff"
const SCENARIO_ROOT_PATH := "reference/rom_extract/gameplay/first_command_scenarios/entry_root_scenario_36_fresh_kickoff.bin"
const SCENARIO_ROOT_RESOURCE_PATH := "res://" + SCENARIO_ROOT_PATH
const EXPECTED_CALLER_HEX := "a93620b0cb"
const EXPECTED_CALLER_SHA256 := "e5d260e080d1d429cc5e76b4685426857a78b3bc6739f9b923cc5cb3e538ed94"
const SCENARIO_QUEUE_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin"
const EXPECTED_SCENARIO_QUEUE_HEX := "8d1805a9808d1605a9008505a900200fcb60"
const EXPECTED_SCENARIO_QUEUE_SHA256 := "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32"
const RAM_SIZE := 0x0800
const STACK_PAGE_START := 0x0100

var error_message := ""
var _configured := false
var _manifest_sha256 := ""
var _caller_bytes := PackedByteArray()
var _queue_bytes := PackedByteArray()


func configure() -> bool:
	error_message = ""
	_configured = false
	var manifest_bytes := FileAccess.get_file_as_bytes(SCENARIO_MANIFEST_PATH)
	if manifest_bytes.is_empty():
		return _fail("Scenario source manifest is missing.")
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return _fail("Scenario source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("capture_or_screenshot_bytes_included", true)):
		return _fail("Scenario source manifest has an unsupported ROM or runtime contract.")
	var roots: Variant = manifest.get("entry_roots", [])
	if not roots is Array:
		return _fail("Scenario source manifest has no fixed-bank caller roots.")
	var root_found := false
	for root_variant in roots:
		if not root_variant is Dictionary:
			continue
		var root: Dictionary = root_variant
		if String(root.get("name", "")) != SCENARIO_ROOT_NAME:
			continue
		root_found = true
		if String(root.get("path", "")) != SCENARIO_ROOT_PATH \
				or String(root.get("cpu_address", "")) != "0xDB0E" \
				or String(root.get("file_offset", "")) != "0x03DB1E" \
				or String(root.get("bytes_hex", "")).replace(" ", "").to_lower() != EXPECTED_CALLER_HEX \
				or String(root.get("sha256", "")) != EXPECTED_CALLER_SHA256:
			return _fail("Scenario-$36 caller manifest entry differs from the supplied ROM bytes.")
		_caller_bytes = FileAccess.get_file_as_bytes(SCENARIO_ROOT_RESOURCE_PATH)
		if _caller_bytes.hex_encode() != EXPECTED_CALLER_HEX \
				or _sha256(_caller_bytes) != EXPECTED_CALLER_SHA256:
			return _fail("Packaged `$DB0E` caller bytes failed their ROM hash check.")
		break
	if not root_found:
		return _fail("Scenario-$36 fresh-kickoff caller is absent from the source manifest.")
	_queue_bytes = FileAccess.get_file_as_bytes(SCENARIO_QUEUE_PATH)
	if _queue_bytes.hex_encode() != EXPECTED_SCENARIO_QUEUE_HEX \
			or _sha256(_queue_bytes) != EXPECTED_SCENARIO_QUEUE_SHA256:
		return _fail("Packaged `$CBB0` queue-helper bytes failed their ROM hash check.")
	_manifest_sha256 = _sha256(manifest_bytes)
	_configured = true
	return true


func execute_from_live_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure():
		return _failure("source_integrity_failure", error_message)
	var entry_ram: Variant = boundary.get("ram_image", PackedByteArray())
	var entry_stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xDB0E \
			or int(boundary.get("sp", -1)) != 0x50 \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or not entry_ram is PackedByteArray or entry_ram.size() != RAM_SIZE \
			or not entry_stack is PackedByteArray or entry_stack.size() != 0x100:
		return _failure("source_state_required", "Scenario-$36 caller requires the live slot-$05 `$DB0E` boundary.")
	var registers := {
		"a": int(boundary.get("a", -1)),
		"x": int(boundary.get("x", -1)),
		"y": int(boundary.get("y", -1)),
		"p": int(boundary.get("p", -1)),
		"p_known_mask": int(boundary.get("p_known_mask", -1)),
		"sp": 0x50,
		"pc": 0xDB0E,
	}
	if not _valid_registers(registers):
		return _failure("source_state_required", "Scenario-$36 caller registers are incomplete.")
	var ram: PackedByteArray = entry_ram.duplicate()
	var stack: PackedByteArray = entry_stack.duplicate()
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var instructions: Array[Dictionary] = []
	var sp := 0x50
	var a := 0x36
	var x := int(registers["x"])
	var y := int(registers["y"])
	var p := _update_nz(int(registers["p"]), a)
	var p_known := int(registers["p_known_mask"]) | 0x82
	instructions.append({"pc": 0xDB0E, "bytes": PackedByteArray([0xA9, 0x36]), "next_pc": 0xDB10})
	sp = _push_jsr_return(stack, stack_writes, 0xDB10, 0xDB12, sp)
	instructions.append({"pc": 0xDB10, "bytes": PackedByteArray([0x20, 0xB0, 0xCB]), "next_pc": 0xCBB0})
	_write_ram(ram, writes, 0xCBB0, 0x0518, a)
	instructions.append({"pc": 0xCBB0, "bytes": _queue_bytes.slice(0, 3), "next_pc": 0xCBB3})
	a = 0x80
	p = _update_nz(p, a)
	instructions.append({"pc": 0xCBB3, "bytes": _queue_bytes.slice(3, 5), "next_pc": 0xCBB5})
	_write_ram(ram, writes, 0xCBB5, 0x0516, a)
	instructions.append({"pc": 0xCBB5, "bytes": _queue_bytes.slice(5, 8), "next_pc": 0xCBB8})
	a = 0
	p = _update_nz(p, a)
	instructions.append({"pc": 0xCBB8, "bytes": _queue_bytes.slice(8, 10), "next_pc": 0xCBBA})
	_write_ram(ram, writes, 0xCBBA, 0x0005, a)
	instructions.append({"pc": 0xCBBA, "bytes": _queue_bytes.slice(10, 12), "next_pc": 0xCBBC})
	# `$CBBC LDA #$00` precedes the nested JSR; it preserves A=0 and Z=1.
	instructions.append({"pc": 0xCBBC, "bytes": _queue_bytes.slice(12, 14), "next_pc": 0xCBBE})
	sp = _push_jsr_return(stack, stack_writes, 0xCBBE, 0xCBC0, sp)
	instructions.append({"pc": 0xCBBE, "bytes": _queue_bytes.slice(14, 17), "next_pc": 0xCB0F})
	var output_ram := ram.duplicate()
	for stack_index in range(0x100):
		output_ram[STACK_PAGE_START + stack_index] = stack[stack_index]
	var output_registers := {
		"a": a, "x": x, "y": y, "p": p, "p_known_mask": p_known,
		"sp": sp, "pc": 0xCB0F,
	}
	return {
		"ok": true,
		"status": "scenario36_queue_at_cb0f_entry",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SCENARIO_MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256,
		"caller_source_path": SCENARIO_ROOT_RESOURCE_PATH,
		"caller_source_sha256": EXPECTED_CALLER_SHA256,
		"queue_source_path": SCENARIO_QUEUE_PATH,
		"queue_source_sha256": EXPECTED_SCENARIO_QUEUE_SHA256,
		"entry_registers": registers,
		"entry_ram_image": entry_ram.duplicate(),
		"entry_stack_page": entry_stack.duplicate(),
		"registers": output_registers,
		"ram_image": output_ram,
		"stack_page": stack,
		"memory_writes": writes,
		"stack_writes": stack_writes,
		"instructions": instructions,
		"call_frames": [
			{"callsite": 0xDB10, "target": 0xCBB0, "return_word": 0xDB12, "return_pc": 0xDB13},
			{"callsite": 0xCBBE, "target": 0xCB0F, "return_word": 0xCBC0, "return_pc": 0xCBC1},
		],
		"trace_state_used": false,
		"captured_ram_input_used": false,
		"ppu_apu_effects_applied": false,
		"source_cycle_timing_modeled": false,
	}


func _push_jsr_return(stack: PackedByteArray, writes: Array[Dictionary], callsite: int,
		return_word: int, sp: int) -> int:
	stack[sp] = (return_word >> 8) & 0xFF
	writes.append({"pc": callsite, "address": STACK_PAGE_START + sp, "value": (return_word >> 8) & 0xFF})
	sp = (sp - 1) & 0xFF
	stack[sp] = return_word & 0xFF
	writes.append({"pc": callsite, "address": STACK_PAGE_START + sp, "value": return_word & 0xFF})
	return (sp - 1) & 0xFF


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], pc: int,
		address: int, value: int) -> void:
	ram[address] = value
	writes.append({"pc": pc, "address": address, "value": value})


func _update_nz(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0x80) != 0:
		result |= 0x80
	if (value & 0xFF) == 0:
		result |= 0x02
	return result


func _valid_registers(registers: Dictionary) -> bool:
	for key: String in ["a", "x", "y", "p", "p_known_mask", "sp", "pc"]:
		var value := int(registers.get(key, -1))
		if value < 0 or value > 0xFFFF:
			return false
	return true


func _sha256(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false
