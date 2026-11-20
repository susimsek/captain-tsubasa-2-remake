extends RefCounted
class_name RomScenario44PostQueueReturnExecutor
## Executes the source-owned scenario-$44 caller after `$CBC1 RTS`: hide the
## OAM sprites, select PRG banks `$1A/$1B`, reset SP, and enter `$8003`.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CALLER_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/scenario44_post_cbc1_E38F_E3A3.bin"
const CALLER_SHA256 := "7dc4f685cc530388f709b0944a932a5fb2186f702625a3ef2e9fd1db117739a6"
const OAM_HIDE_PATH := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_oam_hide_CB8B_CB99.bin"
const OAM_HIDE_SHA256 := "1b150bcd50e3652de1d27ce1c0ea43f6b691ab42e6a09be08322dd40bff1776d"
const MAPPER_PATH := "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/fixed_mapper_helper_CE2D_CE49.bin"
const MAPPER_SHA256 := "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100

var error_message := ""
var _configured := false
var _caller := PackedByteArray()
var _oam_hide := PackedByteArray()
var _mapper_helper := PackedByteArray()


func configure() -> bool:
	error_message = ""
	_configured = false
	_caller = FileAccess.get_file_as_bytes(CALLER_PATH)
	_oam_hide = FileAccess.get_file_as_bytes(OAM_HIDE_PATH)
	_mapper_helper = FileAccess.get_file_as_bytes(MAPPER_PATH)
	if _caller.size() != 20 or _sha256(_caller) != CALLER_SHA256 \
			or _caller != PackedByteArray([0x20, 0x8B, 0xCB, 0xA9, 0x1A, 0x85, 0x24,
			0xA9, 0x1B, 0x85, 0x25, 0x20, 0x2D, 0xCE, 0xA2, 0x50, 0x9A, 0x4C, 0x03, 0x80]):
		return _fail("Scenario-$44 `$E38F->$8003` caller bytes are missing or changed.")
	if _oam_hide.size() != 14 or _sha256(_oam_hide) != OAM_HIDE_SHA256 \
			or _oam_hide != PackedByteArray([0xA0, 0x00, 0xA9, 0xF8, 0x99, 0x00, 0x02,
			0xC8, 0xC8, 0xC8, 0xC8, 0xD0, 0xF7, 0x60]):
		return _fail("ROM `$CB8B` OAM-hide helper failed its source-byte check.")
	if _mapper_helper.size() != 29 or _sha256(_mapper_helper) != MAPPER_SHA256 \
			or _mapper_helper != PackedByteArray([
			0xA5, 0x22, 0x09, 0x06, 0x85, 0x23, 0x8D, 0x00, 0x80,
			0xA5, 0x24, 0x8D, 0x01, 0x80, 0xA5, 0x22, 0x09, 0x07,
			0x85, 0x23, 0x8D, 0x00, 0x80, 0xA5, 0x25, 0x8D, 0x01, 0x80, 0x60]):
		return _fail("ROM `$CE2D` mapper helper failed its source-byte check.")
	_configured = true
	return true


func execute_from_return_result(return_result: Dictionary) -> Dictionary:
	error_message = ""
	var registers: Variant = return_result.get("registers", {})
	var mapper: Variant = return_result.get("mapper", {})
	var ram: Variant = return_result.get("ram_image", PackedByteArray())
	var stack: Variant = return_result.get("stack_page", PackedByteArray())
	if not _configured:
		return _failure("Configure the checked ROM caller/helpers before execution.")
	if not registers is Dictionary or not mapper is Dictionary \
			or not ram is PackedByteArray or not stack is PackedByteArray \
			or String(return_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(return_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json" \
			or String(return_result.get("status", "")) != "returned_to_source_caller" \
			or not bool(return_result.get("returned_to_caller", false)) \
			or int(registers.get("pc", -1)) != 0xE38F or int(registers.get("sp", -1)) != 0x4E \
			or int(registers.get("bank_low", -1)) != 0x1A or int(registers.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("bank_low", -1)) != 0x1A or int(mapper.get("bank_high", -1)) != 0x1B \
			or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE or int(ram[0x0518]) != 0x44:
		return _failure("Input is not the live scenario-$44 `$CBC1 RTS->$E38F` result.")
	for stack_offset in range(STACK_SIZE):
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return _failure("Scenario-$44 caller RAM/stack mirror differs at `$%02X`." % stack_offset)
	if int(ram[0x0024]) != 0x1A or int(ram[0x0025]) != 0x1B:
		return _failure("Scenario-$44 caller did not load the ROM bank pair `$1A/$1B` before `$CBC1`.")

	var result_ram: PackedByteArray = (ram as PackedByteArray).duplicate()
	var oam_writes: Array[Dictionary] = []
	for y_index in range(64):
		var y := y_index * 4
		result_ram[0x0200 + y] = 0xF8
		oam_writes.append({"pc": 0xCB8F, "address": 0x0200 + y, "value": 0xF8})
	var mapper_writes: Array[Dictionary] = []
	var select_low := (int(result_ram[0x0022]) | 0x06) & 0xFF
	result_ram[0x0023] = select_low
	mapper_writes.append({"pc": 0xCE33, "address": 0x8000, "value": select_low,
		"select": select_low & 0x07, "kind": "register_select"})
	mapper_writes.append({"pc": 0xCE38, "address": 0x8001, "value": 0x1A,
		"select": 0x06, "kind": "register_data"})
	var select_high := (int(result_ram[0x0022]) | 0x07) & 0xFF
	result_ram[0x0023] = select_high
	mapper_writes.append({"pc": 0xCE41, "address": 0x8000, "value": select_high,
		"select": select_high & 0x07, "kind": "register_select"})
	mapper_writes.append({"pc": 0xCE46, "address": 0x8001, "value": 0x1B,
		"select": 0x07, "kind": "register_data"})
	var result_mapper: Dictionary = mapper.duplicate(true)
	var registers_out: Dictionary = registers.duplicate(true)
	var bank_registers: Dictionary = result_mapper.get("bank_registers", {})
	bank_registers[0x06] = 0x1A
	bank_registers[0x07] = 0x1B
	result_mapper["bank_registers"] = bank_registers
	result_mapper["register_select"] = select_high & 0x07
	result_mapper["bank_low"] = 0x1A
	result_mapper["bank_high"] = 0x1B
	registers_out["a"] = 0x1B
	registers_out["x"] = 0x50
	registers_out["y"] = 0
	registers_out["sp"] = 0x50
	registers_out["pc"] = 0x8003
	registers_out["bank_low"] = 0x1A
	registers_out["bank_high"] = 0x1B
	return {
		"ok": true,
		"status": "scenario44_field_runtime_entered",
		"rom_sha256": ROM_SHA256,
		"source_manifest": "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json",
		"entry_pc": 0xE38F,
		"exit_pc": 0x8003,
		"return_result": return_result.duplicate(true),
		"registers": registers_out,
		"mapper": result_mapper,
		"ram_image": result_ram,
		"stack_page": stack.duplicate(),
		"oam_writes": oam_writes,
		"mapper_writes": mapper_writes,
		"instruction_pcs": [0xE38F, 0xCB8B, 0xCB8D, 0xCB8F, 0xCB92, 0xCB93, 0xCB94,
			0xCB95, 0xCB96, 0xCB98, 0xE392, 0xE394, 0xE396, 0xE398, 0xE39A,
			0xCE2D, 0xCE2F, 0xCE31, 0xCE33, 0xCE36, 0xCE38, 0xCE3B, 0xCE3D,
			0xCE3F, 0xCE41, 0xCE44, 0xCE46, 0xCE49, 0xE39D, 0xE39F, 0xE3A0],
		"source_spans": ["scenario44_post_cbc1_E38F_E3A3.bin",
			"fixed_oam_hide_CB8B_CB99.bin", "fixed_mapper_helper_CE2D_CE49.bin"],
		"ppu_cycle_timing_modeled": false,
		"audio_effects_modeled": false,
	}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_required", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
