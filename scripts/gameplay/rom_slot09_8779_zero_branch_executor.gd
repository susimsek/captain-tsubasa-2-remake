extends RefCounted
class_name RomSlot09Worker8779ZeroBranchExecutor
## Executes the live slot-$09 caller from $EBB3 through worker $8779's
## `$0534 == 0` and `$80 -> 0` high-bit-normalize return paths. This is a
## source-specific executor, not a 6502 core.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot09_8779_worker/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/slot09_8779_worker/"
const PREVIOUS_MANIFEST := "res://reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_N := 0x80
const P_Z := 0x02
const P_NZ_MASK := P_N | P_Z
const ROOT_ENTRY := 0xEBB3
const ROOT_RETURN := 0xEBC5
const WORKER_ENTRY := 0x8779
const WORKER_ZERO_RTS := 0x87A3
const NEXT_WORKER_ENTRY := 0x87E6

const SOURCE_SPANS := {
	"root": {"file": "fixed_root_slot09_after_86f8_EBB3_EBC5.bin",
		"start": 0xEBB3, "end": 0xEBC5, "bank": 0x1F, "window": "fixed",
		"offset": "0x03EBC3", "length": 18,
		"sha256": "5b1a5142b268e834aafe619d51b6c51a80e71c99ec269641ecb61cc6c0d50883"},
	"vector": {"file": "bank18_slot09_worker_vector_8006_8009.bin",
		"start": 0x8006, "end": 0x8009, "bank": 0x18, "window": "low",
		"offset": "0x030016", "length": 3,
		"sha256": "ec20595812bf088382eaa136f2bbf5cf9429467653f948041a7684a34e1b4fab"},
	"worker": {"file": "bank18_slot09_worker_8779_87A4.bin",
		"start": 0x8779, "end": 0x87A4, "bank": 0x18, "window": "low",
		"offset": "0x030789", "length": 43,
		"sha256": "407f2feb4cedb61c07aab10b9b39e7775d9891b04afeaa16b43ad459aeeab511"},
	"mapper": {"file": "fixed_mapper_helper_CE2D_CE4A.bin",
		"start": 0xCE2D, "end": 0xCE4A, "bank": 0x1E, "window": "fixed",
		"offset": "0x03CE3D", "length": 29,
		"sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c"},
}

var ROOT_BYTES := PackedByteArray([
	0x48, 0xA5, 0x22, 0xA9, 0x18, 0x85, 0x24, 0xA9, 0x19,
	0x85, 0x25, 0x20, 0x2D, 0xCE, 0x68, 0x20, 0x06, 0x80,
])
var VECTOR_BYTES := PackedByteArray([0x4C, 0x79, 0x87])
var WORKER_ENTRY_BYTES := PackedByteArray([0xAD, 0x34, 0x05, 0xF0, 0x25])
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
		return _fail("The slot-$09 `$8779` source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("The slot-$09 `$8779` source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var rom_variant: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-8779-worker-source-v1" \
			or not rom_variant is Dictionary \
			or String(rom_variant.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or not spans_variant is Array:
		return _fail("The slot-$09 `$8779` package targets an unsupported ROM or schema.")
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
		for field: String in ["file_offset", "length", "sha256"]:
			var expected: Variant = spec["offset"] if field == "file_offset" else spec[field]
			if found.get(field) != expected:
				return _fail("Manifest metadata differs for %s field %s." % [String(spec["file"]), field])
		if String(found.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(found.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(found.get("bank", "")) != "0x%02X" % int(spec["bank"]) \
				or String(found.get("window", "")) != String(spec["window"]):
			return _fail("Manifest CPU span/bank/window differs for %s." % String(spec["file"]))
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(spec["file"]))
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Packaged ROM bytes failed size/hash/manifest validation: %s." % String(spec["file"]))
		_sources[name] = bytes
	if not _expect("root", ROOT_ENTRY, ROOT_BYTES) \
			or not _expect("vector", 0x8006, VECTOR_BYTES) \
			or not _expect("worker", WORKER_ENTRY, WORKER_ENTRY_BYTES) \
			or not _expect("worker", WORKER_ZERO_RTS, WORKER_RTS_BYTES) \
			or not _expect("mapper", 0xCE2D, MAPPER_BYTES):
		return _fail("One or more caller, vector, mapper, or worker opcodes differ from the supported path.")
	_configured = true
	return true


## Consumes the actual return state produced by RomSlot09Worker86F8ZeroBranchExecutor.
## It executes the source caller at $EBB3, mapper helper, vector $8006, and only
## the live $0534==0 worker branch. It stops at $EBC5 before the next caller call.
func execute_from_86f8_worker_result(previous_worker_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _rejected("Configure the hash-checked `$8779` source package first.")
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
	var entry_ram_0534 := int(ram[0x0534])
	var instruction_pcs: Array[int] = []
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []

	if not _expect("root", 0xEBB3, PackedByteArray([0x48])):
		return _rejected("The source caller does not begin with `PHA` at `$EBB3`.")
	instruction_pcs.append(0xEBB3)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xEBB3, "PHA")

	if not _expect("root", 0xEBB4, PackedByteArray([0xA5, 0x22])):
		return _rejected("The caller's `$EBB4` RAM read differs from source.")
	instruction_pcs.append(0xEBB4)
	_set_a(cpu, int(ram[0x0022]))
	if not _expect("root", 0xEBB6, PackedByteArray([0xA9, 0x18])):
		return _rejected("The caller's `$EBB6` bank-low load differs from source.")
	instruction_pcs.append(0xEBB6)
	_set_a(cpu, 0x18)
	if not _expect("root", 0xEBB8, PackedByteArray([0x85, 0x24])):
		return _rejected("The caller's `$EBB8` bank-low store differs from source.")
	instruction_pcs.append(0xEBB8)
	_write_ram(ram, ram_writes, 0xEBB8, 0x0024, int(cpu["a"]))
	if not _expect("root", 0xEBBA, PackedByteArray([0xA9, 0x19])):
		return _rejected("The caller's `$EBBA` bank-high load differs from source.")
	instruction_pcs.append(0xEBBA)
	_set_a(cpu, 0x19)
	if not _expect("root", 0xEBBC, PackedByteArray([0x85, 0x25])):
		return _rejected("The caller's `$EBBC` bank-high store differs from source.")
	instruction_pcs.append(0xEBBC)
	_write_ram(ram, ram_writes, 0xEBBC, 0x0025, int(cpu["a"]))

	if not _expect("root", 0xEBBE, PackedByteArray([0x20, 0x2D, 0xCE])):
		return _rejected("The caller's `$EBBE->$CE2D` mapper-helper call differs from source.")
	instruction_pcs.append(0xEBBE)
	_push_jsr(cpu, stack, stack_writes, 0xEBBE, 0xCE2D)
	if not _execute_mapper_helper(cpu, ram, stack, mapper, ram_writes,
			stack_writes, stack_reads, mapper_writes, instruction_pcs):
		return _rejected("The source MMC3 helper did not return to `$EBC1`.")
	if not _expect("root", 0xEBC1, PackedByteArray([0x68])):
		return _rejected("The caller's `$EBC1` accumulator restore differs from source.")
	instruction_pcs.append(0xEBC1)
	var pulled_a := _pull(cpu, stack, stack_reads, 0xEBC1, "PLA")
	_set_a(cpu, pulled_a)

	if not _expect("root", 0xEBC2, PackedByteArray([0x20, 0x06, 0x80])):
		return _rejected("The caller's `$EBC2->$8006` worker call differs from source.")
	instruction_pcs.append(0xEBC2)
	_push_jsr(cpu, stack, stack_writes, 0xEBC2, 0x8006)
	if not _expect("vector", 0x8006, VECTOR_BYTES):
		return _rejected("The bank-$18 `$8006` vector is not the checked `$8779` jump.")
	instruction_pcs.append(0x8006)
	cpu["pc"] = WORKER_ENTRY
	var worker_entry_cpu: Dictionary = cpu.duplicate(true)

	if not _expect("worker", WORKER_ENTRY, PackedByteArray([0xAD, 0x34, 0x05, 0xF0, 0x25, 0x10, 0x1B, 0x29, 0x7F, 0x8D, 0x34, 0x05, 0xF0, 0x1C])):
		return _rejected("The `$8779` live-state read differs from source.")
	instruction_pcs.append(WORKER_ENTRY)
	_set_a(cpu, entry_ram_0534)
	cpu["pc"] = 0x877C
	if not _expect("worker", 0x877C, PackedByteArray([0xF0, 0x25])):
		return _rejected("The `$877C` source branch bytes differ from the checked worker.")
	instruction_pcs.append(0x877C)
	if entry_ram_0534 not in [0, 0x80]:
		cpu["pc"] = 0x877E
		return _unsupported_branch(entry_ram_0534, cpu, ram, stack, mapper,
				entry_cpu, entry_mapper, entry_ram_0534, ram_writes,
				stack_writes, stack_reads, mapper_writes, instruction_pcs)
	if entry_ram_0534 == 0x80:
		cpu["pc"] = 0x877E
		if not _expect("worker", 0x877E, PackedByteArray([0x10, 0x1B])):
			return _rejected("The `$877E` BPL bytes differ from the checked worker.")
		instruction_pcs.append(0x877E)
		# LDA $0534 set N, so BPL falls through for the high-bit-only value.
		cpu["pc"] = 0x8780
		if not _expect("worker", 0x8780, PackedByteArray([0x29, 0x7F])):
			return _rejected("The `$8780` AND bytes differ from the checked worker.")
		instruction_pcs.append(0x8780)
		_set_a(cpu, int(cpu["a"]) & 0x7F)
		cpu["pc"] = 0x8782
		if not _expect("worker", 0x8782, PackedByteArray([0x8D, 0x34, 0x05])):
			return _rejected("The `$8782` STA bytes differ from the checked worker.")
		instruction_pcs.append(0x8782)
		_write_ram(ram, ram_writes, 0x8782, 0x0534, int(cpu["a"]))
		cpu["pc"] = 0x8785
		if not _expect("worker", 0x8785, PackedByteArray([0xF0, 0x1C])) \
				or (int(cpu["p"]) & P_Z) == 0:
			return _rejected("Normalized `$0534` did not take the source `$8785->$87A3` branch.")
		instruction_pcs.append(0x8785)
	cpu["pc"] = WORKER_ZERO_RTS
	if not _expect("worker", WORKER_ZERO_RTS, WORKER_RTS_BYTES):
		return _rejected("The supported `$8779` zero branch does not land on its checked `$87A3 RTS`.")
	instruction_pcs.append(WORKER_ZERO_RTS)
	var return_word := _pop_rts(cpu, stack, stack_reads, WORKER_ZERO_RTS)
	if return_word != 0xEBC4:
		return _rejected("The `$8779` RTS did not restore caller return-minus-one `$EBC4`.")
	if int(cpu["pc"]) != ROOT_RETURN or int(cpu["sp"]) != 0x7A:
		return _rejected("The `$8779` RTS did not return to `$EBC5` with the caller's SP restored.")

	return {
		"ok": true,
		"status": "returned_before_next_worker_call",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"previous_worker_manifest": PREVIOUS_MANIFEST,
		"entry_pc": ROOT_ENTRY,
		"worker_entry_pc": WORKER_ENTRY,
		"worker_entry_registers": worker_entry_cpu,
		"exit_pc": int(cpu["pc"]),
		"next_worker_entry_pc": NEXT_WORKER_ENTRY,
		"input_ram_0534": entry_ram_0534,
		"entry_registers": entry_cpu,
		"entry_mapper": entry_mapper,
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
		"next_worker_call_executed": false,
		"next_worker_body_bytes_read": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "worker_entry": WORKER_ENTRY,
		"worker_zero_rts": WORKER_ZERO_RTS, "next_worker_entry": NEXT_WORKER_ENTRY,
		"supports_live_ram_0534_zero_or_high_bit_normalization": true}


func _validate_previous_result(result: Dictionary) -> Dictionary:
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("status", "")) != "returned_to_root_caller" \
			or String(result.get("source_manifest", "")) != PREVIOUS_MANIFEST \
			or int(result.get("entry_pc", -1)) != 0x86F8 \
			or int(result.get("exit_pc", -1)) != ROOT_ENTRY \
			or int(result.get("entry_bank", -1)) != 0x18 \
			or int(result.get("exit_bank", -1)) != 0x18 \
			or int(result.get("return_word", -1)) != 0xEBB2 \
			or int(result.get("return_pc", -1)) != ROOT_ENTRY \
			or bool(result.get("next_worker_executed", true)) \
			or bool(result.get("next_worker_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)):
		return {"ok": false, "reason": "Input is not the live `$86F8->$8722 RTS` result at `$EBB3`."}
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
	# X/Y are preserved but not consumed by the checked `$EBB3->$EBC5` path.
	# The live scenario-active `$EC08` route reaches the same source boundary
	# with X/Y=$15/$F0, so only registers consumed by this instruction span are
	# part of the dispatch contract.
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
			or int(ram[0x0023]) != 7 \
			or int(ram[0x0024]) != 0x18 \
			or int(ram[0x0025]) != 0x19 \
			or stack.slice(0x79, 0x7B) != PackedByteArray([0xB2, 0xEB]):
		return {"ok": false, "reason": "Live `$EBB3` contract differs: A/X/Y/P=%02X/%02X/%02X/%02X known=%02X SP=%02X banks=%02X/%02X sel=%02X RAM00/23/24/25=%02X/%02X/%02X/%02X stack79=%s." % [
			int(registers.get("a", -1)), int(registers.get("x", -1)), int(registers.get("y", -1)),
			int(registers.get("p", -1)), int(registers.get("p_known_mask", -1)), int(registers.get("sp", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)), int(mapper.get("select", -1)),
			int(ram[0x0000]), int(ram[0x0023]), int(ram[0x0024]), int(ram[0x0025]),
			stack.slice(0x79, 0x7B).hex_encode()]}
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
	_mapper_data(mapper, mapper_writes, 0xCE38, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0022]))
	_set_a(cpu, int(cpu["a"]) | 0x07)
	_write_ram(ram, ram_writes, 0xCE3F, 0x0023, int(cpu["a"]))
	_mapper_select(mapper, mapper_writes, 0xCE41, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0025]))
	_mapper_data(mapper, mapper_writes, 0xCE46, int(cpu["a"]))
	var return_word := _pop_rts(cpu, stack, stack_reads, 0xCE49)
	return return_word == 0xEBC0 and int(cpu["pc"]) == 0xEBC1


func _mapper_select(mapper: Dictionary, mapper_writes: Array[Dictionary],
		source_pc: int, value: int) -> void:
	var select := value & 0x07
	mapper["select"] = select
	mapper_writes.append({"pc": source_pc, "address": 0x8000,
		"value": value & 0xFF, "select": select, "kind": "register_select"})


func _mapper_data(mapper: Dictionary, mapper_writes: Array[Dictionary],
		source_pc: int, value: int) -> void:
	var select := int(mapper.get("select", -1))
	if select not in [6, 7]:
		return
	var bank_registers: Dictionary = mapper.get("bank_registers", {}).duplicate(true)
	bank_registers[select] = value & 0xFF
	mapper["bank_registers"] = bank_registers
	if select == 6:
		mapper["bank_low"] = value & 0xFF
	else:
		mapper["bank_high"] = value & 0xFF
	mapper_writes.append({"pc": source_pc, "address": 0x8001,
		"value": value & 0xFF, "select": select, "kind": "register_data"})


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
	var return_low := _pull(cpu, stack, stack_reads, source_pc, "RTS_low")
	var return_high := _pull(cpu, stack, stack_reads, source_pc, "RTS_high")
	var return_word := (return_high << 8) | return_low
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
		entry_mapper: Dictionary, entry_ram_0534: int, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		mapper_writes: Array[Dictionary], instruction_pcs: Array[int]) -> Dictionary:
	var reason := "`$0534` is nonzero; the `$877E` stream/script branch is not implemented."
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"rom_sha256": ROM_SHA256, "entry_pc": ROOT_ENTRY, "worker_entry_pc": WORKER_ENTRY,
		"exit_pc": int(cpu.get("pc", -1)), "input_ram_0534": entry_ram_0534,
		"ram_0534": value, "entry_registers": entry_cpu, "entry_mapper": entry_mapper,
		"registers": cpu, "mapper": mapper, "ram_image": ram, "stack_page": stack,
		"ram_writes": ram_writes, "stack_writes": stack_writes,
		"stack_reads": stack_reads, "mapper_writes": mapper_writes,
		"instruction_pcs": instruction_pcs, "next_worker_call_executed": false,
		"next_worker_body_bytes_read": false, "trace_state_used": false}


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
