extends RefCounted
class_name RomSlot09Worker87E6ZeroBranchExecutor
## Executes the live root caller from $EBC5 through the $87E6 zero or
## high-bit-normalize branch. This is source-specific, not a general 6502 core.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/slot09_87e6_worker/"
const PREVIOUS_MANIFEST := "res://reference/rom_extract/gameplay/slot09_8779_worker/manifest.json"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_N := 0x80
const P_Z := 0x02
const P_NZ_MASK := P_N | P_Z
const ROOT_ENTRY := 0xEBC5
const WORKER_ENTRY := 0x87E6
const WORKER_BRANCH := 0x87E9
const WORKER_ZERO_STORE := 0x8811
const WORKER_ZERO_RTS := 0x8814
const ROOT_RETURN := 0xEBD7

const SOURCE_SPANS := {
	"root": {"file": "fixed_root_slot09_after_8779_EBC5_EBD7.bin",
		"start": 0xEBC5, "end": 0xEBD7, "bank": 0x1F,
		"offset": "0x03EBD5", "length": 18,
		"sha256": "75ff2ee06764439aecb4eae84c694e1f99b083d7b21a92c9ad5e41baa09b304e"},
	"vector": {"file": "bank18_slot09_vector_8009_800B.bin",
		"start": 0x8009, "end": 0x800C, "bank": 0x18,
		"offset": "0x030019", "length": 3,
		"sha256": "ee600ed5f0ff7a46e0b9a1d41acb3615828d6c635eee42c16598839227a71e27"},
	"worker": {"file": "bank18_slot09_worker_87E6_8850.bin",
		"start": 0x87E6, "end": 0x8851, "bank": 0x18,
		"offset": "0x0307F6", "length": 107,
		"sha256": "879cfbc3684874aa7a857d9ee294755cbb773b616d5815335a2208d414799509"},
	"table": {"file": "bank19_slot09_worker_pointer_table_AD54_AD5D.bin",
		"start": 0xAD54, "end": 0xAD5E, "bank": 0x19,
		"offset": "0x032D64", "length": 10,
		"sha256": "8d1c08abdc6be570a1a0e8304738c995c09856b4081e0962f15db579cb95f7b5"},
	"mapper": {"file": "fixed_mapper_helper_CE2D_CE4A.bin",
		"start": 0xCE2D, "end": 0xCE4A, "bank": 0x1E,
		"offset": "0x03CE3D", "length": 29,
		"sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c"},
}

var ROOT_BYTES := PackedByteArray([
	0x48, 0xA5, 0x22, 0xA9, 0x18, 0x85, 0x24, 0xA9, 0x19,
	0x85, 0x25, 0x20, 0x2D, 0xCE, 0x68, 0x20, 0x09, 0x80,
])
var VECTOR_BYTES := PackedByteArray([0x4C, 0xE6, 0x87])
var WORKER_ENTRY_BYTES := PackedByteArray([0xAD, 0x36, 0x05])
var WORKER_BRANCH_BYTES := PackedByteArray([0xF0, 0x26])
var WORKER_ZERO_STORE_BYTES := PackedByteArray([0x8D, 0x38, 0x05])
var WORKER_RTS_BYTES := PackedByteArray([0x60])
var MAPPER_BYTES := PackedByteArray([
	0xA5, 0x22, 0x09, 0x06, 0x85, 0x23, 0x8D, 0x00, 0x80,
	0xA5, 0x24, 0x8D, 0x01, 0x80, 0xA5, 0x22, 0x09, 0x07,
	0x85, 0x23, 0x8D, 0x00, 0x80, 0xA5, 0x25, 0x8D, 0x01,
	0x80, 0x60,
])

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The slot-$09 `$87E6` source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("The slot-$09 `$87E6` source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var rom_variant: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-87e6-worker-source-v1" \
			or not rom_variant is Dictionary \
			or String(rom_variant.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or not spans_variant is Array:
		return _fail("The slot-$09 `$87E6` package targets an unsupported ROM or schema.")
	for name_variant in SOURCE_SPANS:
		var name := String(name_variant)
		var spec: Dictionary = SOURCE_SPANS[name]
		var found: Dictionary = {}
		for span_variant in spans_variant:
			if span_variant is Dictionary and String(span_variant.get("file", "")) == String(spec["file"]):
				found = span_variant
				break
		if found.is_empty():
			return _fail("The manifest omits the `%s` source span." % String(spec["file"]))
		if String(found.get("file_offset", "")) != String(spec["offset"]) \
				or int(found.get("length", -1)) != int(spec["length"]) \
				or String(found.get("sha256", "")) != String(spec["sha256"]) \
				or String(found.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(found.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(found.get("bank", "")) != "0x%02X" % int(spec["bank"]):
			return _fail("Manifest metadata differs for %s." % String(spec["file"]))
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(spec["file"]))
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Packaged ROM bytes failed size/hash/manifest validation: %s." % String(spec["file"]))
		_sources[name] = bytes
	if not _expect("root", ROOT_ENTRY, ROOT_BYTES) \
			or not _expect("vector", 0x8009, VECTOR_BYTES) \
			or not _expect("worker", WORKER_ENTRY, WORKER_ENTRY_BYTES) \
			or not _expect("worker", WORKER_BRANCH, WORKER_BRANCH_BYTES) \
			or not _expect("worker", 0x87EB, PackedByteArray([0x10, 0x1B, 0x29, 0x7F, 0x8D, 0x36, 0x05, 0xF0, 0x1D])) \
			or not _expect("worker", WORKER_ZERO_STORE, WORKER_ZERO_STORE_BYTES) \
			or not _expect("worker", WORKER_ZERO_RTS, WORKER_RTS_BYTES) \
			or not _expect("mapper", 0xCE2D, MAPPER_BYTES):
		return _fail("One or more root, vector, mapper, or worker opcodes differ from the checked source path.")
	var table_bytes: PackedByteArray = _sources.get("table", PackedByteArray())
	if table_bytes != PackedByteArray([0x5E, 0xAD, 0x61, 0xAD, 0x68, 0xAD, 0x6B, 0xAD, 0x6E, 0xAD]):
		return _fail("The bank-$19 `$AD54` pointer table bytes differ from the static audit.")
	_configured = true
	return true


## Consumes the actual result emitted by the live `$8779` executor. It follows
## the root caller through `$EBD4->$8009`, then takes only live `$0536 == 0`.
## It stops at `$EBD7`, before the root loop's next state check.
func execute_from_8779_worker_result(previous_worker_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _rejected("Configure the hash-checked `$87E6` source package first.")
	var contract := _validate_previous_result(previous_worker_result)
	if not bool(contract.get("ok", false)):
		return _rejected(String(contract.get("reason", "Invalid previous live worker result.")))
	var input_ram: PackedByteArray = previous_worker_result["ram_image"]
	var input_stack: PackedByteArray = previous_worker_result["stack_page"]
	var input_cpu: Dictionary = previous_worker_result["registers"]
	var input_mapper: Dictionary = previous_worker_result["mapper"]
	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = input_cpu.duplicate(true)
	var mapper: Dictionary = input_mapper.duplicate(true)
	var entry_cpu: Dictionary = cpu.duplicate(true)
	var entry_mapper: Dictionary = mapper.duplicate(true)
	var entry_ram_0536 := int(ram[0x0536])
	var instruction_pcs: Array[int] = []
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []

	if not _expect("root", 0xEBC5, PackedByteArray([0x48])):
		return _rejected("The root continuation does not begin with `PHA` at `$EBC5`.")
	instruction_pcs.append(0xEBC5)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xEBC5, "PHA")

	if not _expect("root", 0xEBC6, PackedByteArray([0xA5, 0x22])):
		return _rejected("The root caller's `$EBC6` RAM read differs from source.")
	instruction_pcs.append(0xEBC6)
	_set_a(cpu, int(ram[0x0022]))
	if not _expect("root", 0xEBC8, PackedByteArray([0xA9, 0x18])):
		return _rejected("The root caller's `$EBC8` low-bank load differs from source.")
	instruction_pcs.append(0xEBC8)
	_set_a(cpu, 0x18)
	if not _expect("root", 0xEBCA, PackedByteArray([0x85, 0x24])):
		return _rejected("The root caller's `$EBCA` low-bank store differs from source.")
	instruction_pcs.append(0xEBCA)
	_write_ram(ram, ram_writes, 0xEBCA, 0x0024, int(cpu["a"]))
	if not _expect("root", 0xEBCC, PackedByteArray([0xA9, 0x19])):
		return _rejected("The root caller's `$EBCC` high-bank load differs from source.")
	instruction_pcs.append(0xEBCC)
	_set_a(cpu, 0x19)
	if not _expect("root", 0xEBCE, PackedByteArray([0x85, 0x25])):
		return _rejected("The root caller's `$EBCE` high-bank store differs from source.")
	instruction_pcs.append(0xEBCE)
	_write_ram(ram, ram_writes, 0xEBCE, 0x0025, int(cpu["a"]))

	if not _expect("root", 0xEBD0, PackedByteArray([0x20, 0x2D, 0xCE])):
		return _rejected("The `$EBD0->$CE2D` mapper-helper call differs from source.")
	instruction_pcs.append(0xEBD0)
	_push_jsr(cpu, stack, stack_writes, 0xEBD0, 0xCE2D)
	if not _execute_mapper_helper(cpu, ram, stack, mapper, ram_writes,
			stack_writes, stack_reads, mapper_writes, instruction_pcs):
		return _rejected("The ROM mapper helper did not return to `$EBD3`.")
	if not _expect("root", 0xEBD3, PackedByteArray([0x68])):
		return _rejected("The root caller's `$EBD3` accumulator restore differs from source.")
	instruction_pcs.append(0xEBD3)
	_set_a(cpu, _pull(cpu, stack, stack_reads, 0xEBD3, "PLA"))

	if not _expect("root", 0xEBD4, PackedByteArray([0x20, 0x09, 0x80])):
		return _rejected("The root `$EBD4->$8009` worker call differs from source.")
	instruction_pcs.append(0xEBD4)
	_push_jsr(cpu, stack, stack_writes, 0xEBD4, 0x8009)
	if not _expect("vector", 0x8009, VECTOR_BYTES):
		return _rejected("The bank-$18 `$8009` vector does not jump to `$87E6`.")
	instruction_pcs.append(0x8009)
	cpu["pc"] = WORKER_ENTRY
	var worker_entry_cpu: Dictionary = cpu.duplicate(true)
	var worker_entry_mapper: Dictionary = mapper.duplicate(true)

	if not _expect("worker", WORKER_ENTRY, WORKER_ENTRY_BYTES):
		return _rejected("The `$87E6` live-state load differs from source.")
	instruction_pcs.append(WORKER_ENTRY)
	_set_a(cpu, entry_ram_0536)
	cpu["pc"] = WORKER_BRANCH
	if not _expect("worker", WORKER_BRANCH, WORKER_BRANCH_BYTES):
		return _rejected("The `$87E9` zero-test branch differs from source.")
	instruction_pcs.append(WORKER_BRANCH)
	if entry_ram_0536 not in [0, 0x80]:
		cpu["pc"] = 0x87EB
		return _unsupported_branch(entry_ram_0536, cpu, ram, stack, mapper,
				entry_cpu, entry_mapper, worker_entry_cpu, worker_entry_mapper,
				ram_writes, stack_writes, stack_reads, mapper_writes, instruction_pcs)
	if entry_ram_0536 == 0x80:
		cpu["pc"] = 0x87EB
		if not _expect("worker", 0x87EB, PackedByteArray([0x10, 0x1B])):
			return _rejected("The `$87EB` BPL bytes differ from the checked worker.")
		instruction_pcs.append(0x87EB)
		# LDA $0536 set N, so BPL falls through for this high-bit-only value.
		cpu["pc"] = 0x87ED
		if not _expect("worker", 0x87ED, PackedByteArray([0x29, 0x7F])):
			return _rejected("The `$87ED` AND bytes differ from the checked worker.")
		instruction_pcs.append(0x87ED)
		_set_a(cpu, int(cpu["a"]) & 0x7F)
		cpu["pc"] = 0x87EF
		if not _expect("worker", 0x87EF, PackedByteArray([0x8D, 0x36, 0x05])):
			return _rejected("The `$87EF` STA bytes differ from the checked worker.")
		instruction_pcs.append(0x87EF)
		_write_ram(ram, ram_writes, 0x87EF, 0x0536, int(cpu["a"]))
		cpu["pc"] = 0x87F2
		if not _expect("worker", 0x87F2, PackedByteArray([0xF0, 0x1D])) \
				or (int(cpu["p"]) & P_Z) == 0:
			return _rejected("Normalized `$0536` did not take the source `$87F2->$8811` branch.")
		instruction_pcs.append(0x87F2)
	# BEQ $8811 is taken after either zero or source high-bit normalization.
	cpu["pc"] = WORKER_ZERO_STORE
	if not _expect("worker", WORKER_ZERO_STORE, WORKER_ZERO_STORE_BYTES):
		return _rejected("The supported zero branch does not land on `STA $0538` at `$8811`.")
	instruction_pcs.append(WORKER_ZERO_STORE)
	_write_ram(ram, ram_writes, WORKER_ZERO_STORE, 0x0538, int(cpu["a"]))
	cpu["pc"] = WORKER_ZERO_RTS
	if not _expect("worker", WORKER_ZERO_RTS, WORKER_RTS_BYTES):
		return _rejected("The supported zero branch does not end at the checked `$8814 RTS`.")
	instruction_pcs.append(WORKER_ZERO_RTS)
	var return_word := _pop_rts(cpu, stack, stack_reads, WORKER_ZERO_RTS)
	if return_word != 0xEBD6 or int(cpu["pc"]) != ROOT_RETURN:
		return _rejected("The worker RTS did not return through `$EBD6` to `$EBD7`.")

	return {
		"ok": true,
		"status": "returned_before_root_loop_check",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"previous_worker_manifest": PREVIOUS_MANIFEST,
		"previous_worker_result_status": String(previous_worker_result.get("status", "")),
		"entry_pc": ROOT_ENTRY,
		"worker_entry_pc": WORKER_ENTRY,
		"input_ram_0536": entry_ram_0536,
		"entry_registers": entry_cpu,
		"entry_mapper": entry_mapper,
		"worker_entry_registers": worker_entry_cpu,
		"worker_entry_mapper": worker_entry_mapper,
		"exit_pc": int(cpu["pc"]),
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"instruction_pcs": instruction_pcs,
		"worker_return_word": return_word,
		"worker_return_pc": int(cpu["pc"]),
		"next_root_check_executed": false,
		"next_root_body_bytes_read": false,
		"next_worker_call_executed": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "worker_entry": WORKER_ENTRY,
		"supported_live_branch": "$0536 == 0 or $80 normalized to 0", "root_return": ROOT_RETURN,
		"next_root_check_executed": false}


func _validate_previous_result(result: Dictionary) -> Dictionary:
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("status", "")) != "returned_before_next_worker_call" \
			or String(result.get("source_manifest", "")) != PREVIOUS_MANIFEST \
			or int(result.get("entry_pc", -1)) != 0xEBB3 \
			or int(result.get("worker_entry_pc", -1)) != 0x8779 \
			or int(result.get("exit_pc", -1)) != 0xEBC5 \
			or int(result.get("next_worker_entry_pc", -1)) != WORKER_ENTRY \
			or int(result.get("worker_return_word", -1)) != 0xEBC4 \
			or int(result.get("worker_return_pc", -1)) != 0xEBC5 \
			or bool(result.get("next_worker_call_executed", true)) \
			or bool(result.get("next_worker_body_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("nmi_cadence_generated", true)):
		return {"ok": false, "reason": "Input is not the live `$8779->$87A3 RTS` result at `$EBC5`."}
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return {"ok": false, "reason": "Previous worker result must carry CPU, mapper, full RAM, and stack state."}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	if not bank_registers_variant is Dictionary:
		return {"ok": false, "reason": "Previous worker result omits MMC3 bank-register state."}
	var bank_registers: Dictionary = bank_registers_variant
	# This source span reads $0536, writes $0538, and returns; X/Y pass
	# through untouched and are not part of its branch contract.
	if registers.size() == 0 or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or int(registers.get("pc", -1)) != ROOT_ENTRY \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("sp", -1)) != 0x7A \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & P_NZ_MASK) != P_NZ_MASK \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 7 \
			or int(bank_registers.get(6, -1)) != 0x18 \
			or int(bank_registers.get(7, -1)) != 0x19 \
			or int(ram[0x0000]) != 0x09 \
			or int(ram[0x0022]) != 0 \
			or int(ram[0x0023]) != 7 \
			or int(ram[0x0024]) != 0x18 \
			or int(ram[0x0025]) != 0x19 \
			or stack.slice(0x78, 0x7B) != PackedByteArray([0xC0, 0xC4, 0xEB]):
		return {"ok": false, "reason": "Live `$EBC5` CPU, mapper, RAM, or return-stack contract differs from `$8779` result."}
	return {"ok": true}


func _execute_mapper_helper(cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, mapper: Dictionary, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		mapper_writes: Array[Dictionary], instruction_pcs: Array[int]) -> bool:
	var expected_pcs: Array[int] = [0xCE2D, 0xCE2F, 0xCE31, 0xCE33, 0xCE36,
		0xCE38, 0xCE3B, 0xCE3D, 0xCE3F, 0xCE41, 0xCE44, 0xCE46, 0xCE49]
	for source_pc in expected_pcs:
		instruction_pcs.append(source_pc)
	if not _expect("mapper", 0xCE2D, PackedByteArray([0xA5, 0x22])) \
			or not _expect("mapper", 0xCE2F, PackedByteArray([0x09, 0x06])) \
			or not _expect("mapper", 0xCE31, PackedByteArray([0x85, 0x23])) \
			or not _expect("mapper", 0xCE33, PackedByteArray([0x8D, 0x00, 0x80])) \
			or not _expect("mapper", 0xCE36, PackedByteArray([0xA5, 0x24])) \
			or not _expect("mapper", 0xCE38, PackedByteArray([0x8D, 0x01, 0x80])) \
			or not _expect("mapper", 0xCE3B, PackedByteArray([0xA5, 0x22])) \
			or not _expect("mapper", 0xCE3D, PackedByteArray([0x09, 0x07])) \
			or not _expect("mapper", 0xCE3F, PackedByteArray([0x85, 0x23])) \
			or not _expect("mapper", 0xCE41, PackedByteArray([0x8D, 0x00, 0x80])) \
			or not _expect("mapper", 0xCE44, PackedByteArray([0xA5, 0x25])) \
			or not _expect("mapper", 0xCE46, PackedByteArray([0x8D, 0x01, 0x80])) \
			or not _expect("mapper", 0xCE49, PackedByteArray([0x60])):
		return false
	_set_a(cpu, int(ram[0x0022]))
	_set_a(cpu, int(cpu["a"]) | 0x06)
	_write_ram(ram, ram_writes, 0xCE31, 0x0023, int(cpu["a"]))
	_mapper_select(mapper, mapper_writes, 0xCE33, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0024]))
	if not _mapper_data(mapper, mapper_writes, 0xCE38, int(cpu["a"])):
		return false
	_set_a(cpu, int(ram[0x0022]))
	_set_a(cpu, int(cpu["a"]) | 0x07)
	_write_ram(ram, ram_writes, 0xCE3F, 0x0023, int(cpu["a"]))
	_mapper_select(mapper, mapper_writes, 0xCE41, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0025]))
	if not _mapper_data(mapper, mapper_writes, 0xCE46, int(cpu["a"])):
		return false
	var return_word := _pop_rts(cpu, stack, stack_reads, 0xCE49)
	return return_word == 0xEBD2 and int(cpu["pc"]) == 0xEBD3


func _mapper_select(mapper: Dictionary, mapper_writes: Array[Dictionary],
		source_pc: int, value: int) -> void:
	var select := value & 0x07
	mapper["select"] = select
	mapper_writes.append({"pc": source_pc, "address": 0x8000,
		"value": value & 0xFF, "select": select, "kind": "register_select"})


func _mapper_data(mapper: Dictionary, mapper_writes: Array[Dictionary],
		source_pc: int, value: int) -> bool:
	var select := int(mapper.get("select", -1))
	if select not in [6, 7]:
		return false
	var bank_registers: Dictionary = mapper.get("bank_registers", {}).duplicate(true)
	bank_registers[select] = value & 0xFF
	mapper["bank_registers"] = bank_registers
	if select == 6:
		mapper["bank_low"] = value & 0xFF
	else:
		mapper["bank_high"] = value & 0xFF
	mapper_writes.append({"pc": source_pc, "address": 0x8001,
		"value": value & 0xFF, "select": select, "kind": "register_data"})
	return true


func _push_jsr(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], source_pc: int, target_pc: int) -> void:
	var return_word := (source_pc + 2) & 0xFFFF
	_push(cpu, stack, stack_writes, (return_word >> 8) & 0xFF, source_pc, "JSR_high")
	_push(cpu, stack, stack_writes, return_word & 0xFF, source_pc, "JSR_low")
	cpu["pc"] = target_pc


func _push(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], value: int, source_pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = value & 0xFF
	stack_writes.append({"pc": source_pc, "address": 0x0100 | sp,
		"value": value & 0xFF, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pull(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary], source_pc: int, kind: String) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	stack_reads.append({"pc": source_pc, "address": 0x0100 | sp,
		"value": value, "kind": kind})
	return value


func _pop_rts(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary], source_pc: int) -> int:
	var low := _pull(cpu, stack, stack_reads, source_pc, "RTS_low")
	var high := _pull(cpu, stack, stack_reads, source_pc, "RTS_high")
	var return_word := (high << 8) | low
	cpu["pc"] = (return_word + 1) & 0xFFFF
	return return_word


func _write_ram(ram: PackedByteArray, ram_writes: Array[Dictionary],
		source_pc: int, address: int, value: int) -> void:
	ram[address] = value & 0xFF
	ram_writes.append({"pc": source_pc, "address": address,
		"value": value & 0xFF, "kind": "ram"})


func _set_a(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	cpu["a"] = value
	var p := int(cpu.get("p", 0)) & ~P_NZ_MASK
	if (value & 0x80) != 0:
		p |= P_N
	if value == 0:
		p |= P_Z
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ_MASK


func _expect(name: String, address: int, expected: PackedByteArray) -> bool:
	var bytes: PackedByteArray = _sources.get(name, PackedByteArray())
	var spec: Dictionary = SOURCE_SPANS[name]
	var offset := address - int(spec["start"])
	if offset < 0 or offset + expected.size() > bytes.size():
		return false
	for index in range(expected.size()):
		if int(bytes[offset + index]) != expected[index]:
			return false
	return true


func _unsupported_branch(value: int, cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, mapper: Dictionary, entry_cpu: Dictionary,
		entry_mapper: Dictionary, worker_entry_cpu: Dictionary,
		worker_entry_mapper: Dictionary, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		mapper_writes: Array[Dictionary], instruction_pcs: Array[int]) -> Dictionary:
	var reason := "Live `$0536=$%02X` leaves the supported `$87E9 BEQ $8811` path; worker stream execution is not implemented." % value
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"previous_worker_manifest": PREVIOUS_MANIFEST,
		"entry_pc": ROOT_ENTRY, "worker_entry_pc": WORKER_ENTRY,
		"input_ram_0536": value, "entry_registers": entry_cpu,
		"entry_mapper": entry_mapper, "worker_entry_registers": worker_entry_cpu,
		"worker_entry_mapper": worker_entry_mapper,
		"exit_pc": int(cpu.get("pc", -1)), "registers": cpu, "mapper": mapper,
		"ram_image": ram, "stack_page": stack, "ram_writes": ram_writes,
		"stack_writes": stack_writes, "stack_reads": stack_reads,
		"mapper_writes": mapper_writes, "instruction_pcs": instruction_pcs,
		"next_root_check_executed": false, "next_root_body_bytes_read": false,
		"next_worker_call_executed": false, "trace_state_used": false}


func _rejected(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_input", "reason": reason,
		"trace_state_used": false}


func _fail(reason: String) -> bool:
	error_message = reason
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
