extends RefCounted
class_name RomSlot05Scenario35ReturnExecutor
## Executes only the live task's ROM-owned `$CBC1 RTS` after the scenario-$35
## `$CBB0->$CB0F` yield. The stack supplies the return address; no endpoint PC
## or register state is injected.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin"
const SOURCE_SHA256 := "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const RTS_PC := 0xCBC1
const EXPECTED_RETURN_WORD := 0xDADC

var error_message := ""
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Scenario task runtime source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary or String(parsed.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Scenario task runtime manifest targets a different ROM revision.")
	var found_source := false
	for entry_variant in parsed.get("entries", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			if String(entry.get("path", "")) == SOURCE_PATH.trim_prefix("res://"):
				found_source = String(entry.get("cpu_address", "")) == "$CBB0" \
					and String(entry.get("sha256", "")) == SOURCE_SHA256 \
					and int(entry.get("length_bytes", -1)) == 18
	if not found_source:
		return _fail("Scenario source manifest does not identify the expected `$CBB0-$CBC1` bytes.")
	var source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source.size() != 18 or _sha256(source) != SOURCE_SHA256 or int(source[17]) != 0x60:
		return _fail("The scenario-$35 `$CBC1 RTS` opcode failed its size/hash/source check.")
	_configured = true
	return true


## Continues one actual slot-$05 dispatch selected by the source scheduler.
func execute_from_live_dispatch(dispatch: Dictionary, boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _failure("Configure the hash-checked scenario source before execution.")
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != RTS_PC \
			or int(dispatch.get("sp", -1)) != 0x4E \
			or int(dispatch.get("bank_low", -1)) != 0x1C \
			or int(dispatch.get("bank_high", -1)) != 0x1D \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != RTS_PC \
			or int(boundary.get("sp", -1)) != 0x4E \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE:
		return _failure("Input is not the live slot-$05 scenario-$35 `$CBC1` return boundary.")
	for stack_offset in range(STACK_SIZE):
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return _failure("Live slot-$05 RAM and stack mirror differ at `$%02X`." % stack_offset)
	var stack_pointer := int(dispatch["sp"])
	var low := int(stack[(stack_pointer + 1) & 0xFF])
	var high := int(stack[(stack_pointer + 2) & 0xFF])
	var return_word := (high << 8) | low
	if int(dispatch.get("source_return_word", -1)) != 0xD11D \
			or return_word != EXPECTED_RETURN_WORD:
		return _failure("The live `$CBC1 RTS` stack frame differs: task seed `$%04X`, stack return-minus-one `$%04X` at SP `$%02X`." % [int(dispatch.get("source_return_word", -1)), return_word, stack_pointer])
	var result_ram: PackedByteArray = ram.duplicate()
	var result_stack: PackedByteArray = stack.duplicate()
	var registers := {
		"a": int(dispatch.get("a", -1)), "x": int(dispatch.get("x", -1)),
		"y": int(dispatch.get("y", -1)), "sp": (stack_pointer + 2) & 0xFF,
		"pc": (return_word + 1) & 0xFFFF,
		"p": int(dispatch.get("p", 0x20)),
		"p_known_mask": int(dispatch.get("p_known_mask", 0)),
		"p_known_value": int(dispatch.get("p_known_value", 0)),
		"bank_low": int(dispatch["bank_low"]), "bank_high": int(dispatch["bank_high"]),
	}
	return {
		"ok": true, "status": "returned_to_source_caller",
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"entry": {"slot_base": 0x05, "call_pc": RTS_PC,
			"target_pc": RTS_PC, "expected_return_pc": 0xDADD,
			"source": "live slot-$05 scheduler dispatch and stack page"},
		"registers": registers,
		"mapper": {"register_select": int(ram[0x0022]) & 0x07,
			"bank_low": int(dispatch["bank_low"]), "bank_high": int(dispatch["bank_high"]),
			"task_bank_low": int(dispatch["bank_low"]),
			"task_bank_high": int(dispatch["bank_high"])},
		"ram_image": result_ram, "stack_page": result_stack,
		"memory_writes": [], "instruction_pcs": [RTS_PC], "instruction_count": 1,
		"returned_to_caller": true, "ppu_bus_events": [],
		"ppu_cycle_timing_modeled": false, "audio_effects_modeled": false,
		"call_contract": {"dispatch": dispatch.duplicate(true),
			"caller_request": {"source_pc": RTS_PC,
			"target_cpu_address": RTS_PC, "return_word": return_word,
				"return_pc": (return_word + 1) & 0xFFFF,
				"sp_before": stack_pointer, "sp_after": (stack_pointer + 2) & 0xFF}},
	}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "rejected_entry_state", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
