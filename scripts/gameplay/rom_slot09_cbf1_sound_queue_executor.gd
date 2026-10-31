extends RefCounted
class_name RomSlot09Cbf1SoundQueueExecutor
## Executes the source helper at $CBF1 from the live slot-$09 root caller.
## This is a bounded instruction interpreter for one ROM span, not a CPU core.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const PACKAGE_MANIFEST := "res://reference/rom_extract/gameplay/slot09_cbf1_sound_queue/manifest.json"
const PACKAGE_MANIFEST_SHA256 := "28ce64890bfd3b4f0d6c3ab60d9b189c15adcb3a732881f93e2ff2927f399c2f"
const SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/"
const SOURCE_FILE := "fixed_sound_queue_CBF1_CC01.bin"
const HELPER_SOURCE_SHA256 := "fc6689183aa19a053b44b44571a373ebb48b3bf940f299fb10623c61da4791ce"
const SOURCE_MANIFEST_SHA256 := "01b60a8cf91bfde2c6ff02098f50fe4851aca50aea5d43fffb792516dc53e0ea"
const HELPER_FILE_OFFSET := "0x03CC01"
const HELPER_LENGTH := 17
const HELPER_START := 0xCBF1
const HELPER_END_EXCLUSIVE := 0xCC02
const ROOT_SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json"
const ROOT_SOURCE_FILE := "fixed_root_slot09_loop_EB86_EC07.bin"
const ROOT_SOURCE_SHA256 := "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917"
const ROOT_MANIFEST_SHA256 := "d5e9c83f09faab5a9b2c9fdb9e74b07c983be97a67da05bea9714d705773313a"
const ROOT_SOURCE_OFFSET := "0x03EB96"
const ROOT_SOURCE_LENGTH := 130
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const QUEUE_START := 0x0700
const QUEUE_SIZE := 5
const FLAG_C := 0x01
const FLAG_Z := 0x02
const FLAG_V := 0x40
const FLAG_N := 0x80
const FLAG_NZ := FLAG_N | FLAG_Z
const CALLER_FLAGS := FLAG_C | FLAG_Z | FLAG_V | FLAG_N

var error_message := ""
var _configured := false
var _helper_bytes := PackedByteArray()
var _root_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_helper_bytes = PackedByteArray()
	_root_bytes = PackedByteArray()
	if not _load_dependency_manifest():
		return false
	if not _load_root_caller_source():
		return false
	if not _expect_helper(HELPER_START, PackedByteArray([
			0xA2, 0x00, 0xBC, 0x00, 0x07, 0xF0, 0x06, 0xE8, 0xE0,
			0x05, 0xD0, 0xF6, 0x60, 0x9D, 0x00, 0x07, 0x60])):
		return _fail("The `$CBF1-$CC01` helper instruction bytes differ from the packaged ROM source.")
	if not _expect_root(0xEBD7, PackedByteArray([
			0xAD, 0x2E, 0x05, 0xF0, 0x29, 0xCE, 0x2E, 0x05,
			0xD0, 0x24, 0xAD, 0x2F, 0x05, 0xC9, 0x7E, 0x90,
			0x11])) \
			or not _expect_root(0xEBF9, PackedByteArray([0x2C, 0x3F, 0x06, 0x10, 0x04])) \
			or not _expect_root(0xEC02, PackedByteArray([0x20, 0xF1, 0xCB])):
		return _fail("The slot-$09 root caller path into `$CBF1` differs from the checked ROM source.")
	_configured = true
	return true


## Consumes the nested `source_cbf1_call` object emitted by the live root
## executor at `$EC02->$CBF1`. It reads its queue from complete source RAM.
func execute_from_root_cbf1_call(source_cbf1_call: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _rejected("Configure the hash-checked `$CBF1` helper source first.")
	var contract := _validate_source_call(source_cbf1_call)
	if not bool(contract.get("ok", false)):
		return _rejected(String(contract.get("reason", "Invalid root-produced `$CBF1` call boundary.")))
	var ram: PackedByteArray = source_cbf1_call["ram_image"].duplicate()
	var stack: PackedByteArray = source_cbf1_call["stack_page"].duplicate()
	var cpu: Dictionary = source_cbf1_call["registers"].duplicate(true)
	var mapper: Dictionary = source_cbf1_call["mapper"].duplicate(true)
	var entry_cpu := cpu.duplicate(true)
	var input_queue := ram.slice(QUEUE_START, QUEUE_START + QUEUE_SIZE)
	var memory_reads: Array[Dictionary] = []
	var memory_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var selected_index := -1
	var rts_pc := -1

	# $CBF1: LDX #$00.
	if not _expect_helper(0xCBF1, PackedByteArray([0xA2, 0x00])):
		return _rejected("The `$CBF1 LDX #$00` opcode differs from source.")
	instruction_pcs.append(0xCBF1)
	cpu["x"] = 0
	_set_nz(cpu, 0)
	cpu["pc"] = 0xCBF3

	for index in range(QUEUE_SIZE):
		if int(cpu["x"]) != index:
			return _rejected("The ROM queue scan did not advance its X index in source order.")
		# $CBF3: LDY $0700,X.
		if not _expect_helper(0xCBF3, PackedByteArray([0xBC, 0x00, 0x07])):
			return _rejected("The `$CBF3 LDY $0700,X` opcode differs from source.")
		instruction_pcs.append(0xCBF3)
		var queue_address := QUEUE_START + index
		var queue_value := int(ram[queue_address])
		memory_reads.append({"pc": 0xCBF3, "address": queue_address,
			"value": queue_value, "kind": "queue_read"})
		cpu["y"] = queue_value
		_set_nz(cpu, queue_value)
		cpu["pc"] = 0xCBF6

		# $CBF6: BEQ $CBFE uses the loaded Y value.
		if not _expect_helper(0xCBF6, PackedByteArray([0xF0, 0x06])):
			return _rejected("The `$CBF6 BEQ $CBFE` opcode differs from source.")
		instruction_pcs.append(0xCBF6)
		if queue_value == 0:
			selected_index = index
			cpu["pc"] = 0xCBFE
			break

		# $CBF8/$CBF9/$CBFB: INX; CPX #$05; BNE $CBF3.
		if not _expect_helper(0xCBF8, PackedByteArray([0xE8, 0xE0, 0x05, 0xD0, 0xF6])):
			return _rejected("The `$CBF8` queue-scan control bytes differ from source.")
		instruction_pcs.append(0xCBF8)
		var next_index := (int(cpu["x"]) + 1) & 0xFF
		cpu["x"] = next_index
		_set_nz(cpu, next_index)
		cpu["pc"] = 0xCBF9
		instruction_pcs.append(0xCBF9)
		_compare_x(cpu, 0x05)
		cpu["pc"] = 0xCBFB
		instruction_pcs.append(0xCBFB)
		if next_index == QUEUE_SIZE:
			cpu["pc"] = 0xCBFD
			rts_pc = 0xCBFD
			break
		cpu["pc"] = 0xCBF3

	if selected_index >= 0:
		# $CBFE: STA $0700,X, then $CC01 RTS.
		if not _expect_helper(0xCBFE, PackedByteArray([0x9D, 0x00, 0x07])) \
				or not _expect_helper(0xCC01, PackedByteArray([0x60])):
			return _rejected("The first-empty-slot store/RTS bytes differ from source.")
		instruction_pcs.append(0xCBFE)
		var write_address := QUEUE_START + selected_index
		ram[write_address] = int(cpu["a"]) & 0xFF
		memory_writes.append({"pc": 0xCBFE, "address": write_address,
			"value": int(cpu["a"]) & 0xFF, "kind": "queue_write"})
		cpu["pc"] = 0xCC01
		instruction_pcs.append(0xCC01)
		rts_pc = 0xCC01
	else:
		# The fifth nonzero slot falls through to $CBFD RTS without a write.
		if int(cpu["x"]) != QUEUE_SIZE or rts_pc != 0xCBFD \
				or not _expect_helper(0xCBFD, PackedByteArray([0x60])):
			return _rejected("The full queue did not reach the checked `$CBFD RTS`.")
		instruction_pcs.append(0xCBFD)

	var sp := int(cpu["sp"]) & 0xFF
	sp = (sp + 1) & 0xFF
	var return_low := int(stack[sp])
	stack_reads.append({"pc": rts_pc, "address": 0x0100 | sp,
		"value": return_low, "kind": "RTS_low"})
	sp = (sp + 1) & 0xFF
	var return_high := int(stack[sp])
	stack_reads.append({"pc": rts_pc, "address": 0x0100 | sp,
		"value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if return_word != 0xEC04 or int(cpu["pc"]) != 0xEC05:
		return _rejected("The helper RTS did not return through `$EC04` to `$EC05`.")

	var queue_full := selected_index < 0
	var output_queue := ram.slice(QUEUE_START, QUEUE_START + QUEUE_SIZE)
	var expected_queue := input_queue.duplicate()
	if not queue_full:
		expected_queue[selected_index] = int(cpu["a"]) & 0xFF
	if output_queue != expected_queue:
		return _rejected("The helper changed a queue byte other than the first empty slot.")
	if queue_full and not memory_writes.is_empty():
		return _rejected("The full queue path must not write a sound request.")

	return {
		"ok": true,
		"status": "queue_full_no_write" if queue_full else "queued_sound_request",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"source_manifest_sha256": SOURCE_MANIFEST_SHA256,
		"dependency_manifest": PACKAGE_MANIFEST,
		"dependency_manifest_sha256": PACKAGE_MANIFEST_SHA256,
		"source_file": SOURCE_FILE,
		"source_span_sha256": HELPER_SOURCE_SHA256,
		"root_source_manifest": ROOT_SOURCE_MANIFEST,
		"root_source_span_sha256": ROOT_SOURCE_SHA256,
		"root_source_manifest_sha256": ROOT_MANIFEST_SHA256,
		"source_call_status": "source_cbf1_call_entry",
		"caller_pc": 0xEC02,
		"target_pc": HELPER_START,
		"entry_pc": HELPER_START,
		"exit_pc": int(cpu["pc"]),
		"return_word": return_word,
		"return_pc": int(cpu["pc"]),
		"rts_pc": rts_pc,
		"entry_registers": entry_cpu,
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"input_queue": input_queue,
		"output_queue": output_queue,
		"queue_index": selected_index,
		"queue_full": queue_full,
		"sound_request_value": int(entry_cpu["a"]) & 0xFF,
		"memory_reads": memory_reads,
		"memory_writes": memory_writes,
		"entry_stack_writes": source_cbf1_call.get("stack_writes", []).duplicate(true),
		"stack_reads": stack_reads,
		"stack_writes": [],
		"instruction_pcs": instruction_pcs,
		"apu_register_writes": [],
		"ppu_bus_events": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
		"runtime_rom_dependency": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "source_span_sha256": HELPER_SOURCE_SHA256,
		"helper_start": HELPER_START, "helper_end_exclusive": HELPER_END_EXCLUSIVE,
		"runtime_rom_dependency": false}


func _validate_source_call(source_call: Dictionary) -> Dictionary:
	if String(source_call.get("rom_sha256", "")) != ROM_SHA256 \
			or String(source_call.get("source_manifest", "")) != ROOT_SOURCE_MANIFEST \
			or String(source_call.get("status", "")) != "source_cbf1_call_entry" \
			or int(source_call.get("caller_pc", -1)) != 0xEC02 \
			or int(source_call.get("target_pc", -1)) != HELPER_START \
			or int(source_call.get("entry_pc", -1)) != HELPER_START \
			or int(source_call.get("return_word", -1)) != 0xEC04 \
			or int(source_call.get("return_pc", -1)) != 0xEC05 \
			or bool(source_call.get("trace_state_used", false)):
		return {"ok": false, "reason": "Input lacks the hash-checked root executor's `$EC02->$CBF1` source call contract."}
	var registers_variant: Variant = source_call.get("registers", {})
	var mapper_variant: Variant = source_call.get("mapper", {})
	var ram_variant: Variant = source_call.get("ram_image", PackedByteArray())
	var stack_variant: Variant = source_call.get("stack_page", PackedByteArray())
	var stack_writes_variant: Variant = source_call.get("stack_writes", [])
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not stack_writes_variant is Array:
		return {"ok": false, "reason": "Root `$CBF1` boundary omits full CPU/mapper/RAM/stack or ordered caller writes."}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var stack_writes: Array = stack_writes_variant
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	if not bank_registers_variant is Dictionary:
		return {"ok": false, "reason": "Root `$CBF1` boundary omits MMC3 bank-register state."}
	var bank_registers: Dictionary = bank_registers_variant
	var known := int(registers.get("p_known_mask", -1))
	var status := int(registers.get("p", -1))
	var sound_request := int(registers.get("a", -1))
	var sound_flags := int(ram[0x063F]) if ram.size() == RAM_SIZE else -1
	var expected_zero := ((sound_request & sound_flags) == 0) if sound_request >= 0 and sound_flags >= 0 else false
	var expected_v := (sound_flags & 0x40) != 0
	var expected_p_flags := (FLAG_Z if expected_zero else 0) | (FLAG_V if expected_v else 0)
	var expected_stack_writes: Array[Dictionary] = [
		{"pc": 0xEC02, "address": 0x017A, "value": 0xEC, "kind": "JSR_high"},
		{"pc": 0xEC02, "address": 0x0179, "value": 0x04, "kind": "JSR_low"},
	]
	if registers.size() == 0 or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or int(registers.get("pc", -1)) != HELPER_START \
			or sound_request < 0 or sound_request >= 0x7E \
			or int(registers.get("sp", -1)) != 0x78 \
			or status < 0 or status > 0xFF or known > 0xFF \
			or int(registers.get("x", -1)) < 0 or int(registers.get("x", -1)) > 0xFF \
			or int(registers.get("y", -1)) < 0 or int(registers.get("y", -1)) > 0xFF \
			or known < 0 or (known & CALLER_FLAGS) != CALLER_FLAGS \
			or (status & CALLER_FLAGS) != expected_p_flags \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) < 0 \
			or int(mapper.get("select", -1)) > 7 \
			or int(bank_registers.get(6, bank_registers.get("6", -1))) != 0x18 \
			or int(bank_registers.get(7, bank_registers.get("7", -1))) != 0x19 \
			or int(ram[0x0000]) != 0x09 \
			or int(ram[0x052E]) != 0 \
			or int(ram[0x052F]) != sound_request \
			or (sound_flags & 0x80) != 0 \
			or stack[0x79] != 0x04 or stack[0x7A] != 0xEC \
			or stack_writes != expected_stack_writes:
		return {"ok": false, "reason": "Root `$CBF1` registers, mapper, BIT flags, caller stack, RAM or JSR writes do not match the source `$052F/$063F` contract."}
	return {"ok": true}


func _load_dependency_manifest() -> bool:
	var package_file := FileAccess.open(PACKAGE_MANIFEST, FileAccess.READ)
	if package_file == null:
		return _fail("The `$CBF1` consumer dependency manifest is unavailable.")
	var package_variant: Variant = JSON.parse_string(package_file.get_as_text())
	if not package_variant is Dictionary:
		return _fail("The `$CBF1` consumer dependency manifest is malformed.")
	var package: Dictionary = package_variant
	var dependencies_variant: Variant = package.get("dependencies", [])
	if String(package.get("schema", "")) != "ct2-slot09-cbf1-sound-queue-consumer-v1" \
			or String(package.get("rom_sha256", "")) != ROM_SHA256 \
			or _sha256(package_file.get_as_text().to_utf8_buffer()) != PACKAGE_MANIFEST_SHA256 \
			or bool(package.get("runtime_rom_dependency", true)) \
			or not dependencies_variant is Array or dependencies_variant.size() != 1 \
			or not dependencies_variant[0] is Dictionary:
		return _fail("The `$CBF1` consumer manifest targets the wrong ROM or dependency schema.")
	var dependency: Dictionary = dependencies_variant[0]
	if String(dependency.get("manifest", "")) != SOURCE_MANIFEST \
			or String(dependency.get("file", "")) != SOURCE_FILE \
			or String(dependency.get("bank", "")) != "0x1E" \
			or String(dependency.get("window", "")) != "fixed" \
			or String(dependency.get("cpu_start", "")) != "0xCBF1" \
			or String(dependency.get("cpu_end_exclusive", "")) != "0xCC02" \
			or String(dependency.get("file_offset", "")) != HELPER_FILE_OFFSET \
			or int(dependency.get("length", -1)) != HELPER_LENGTH \
			or String(dependency.get("sha256", "")) != HELPER_SOURCE_SHA256:
		return _fail("The `$CBF1` consumer manifest dependency metadata differs from the shared extracted source span.")
	var source_file := FileAccess.open(SOURCE_MANIFEST, FileAccess.READ)
	if source_file == null:
		return _fail("The original fresh-route source manifest is unavailable.")
	var source_variant: Variant = JSON.parse_string(source_file.get_as_text())
	if not source_variant is Dictionary:
		return _fail("The original fresh-route source manifest is malformed.")
	var source_manifest: Dictionary = source_variant
	if String(source_manifest.get("schema", "")) != "ct2-fresh-daaa-continuation-source-v2" \
			or String(source_manifest.get("rom_sha256", "")) != ROM_SHA256 \
			or _sha256(source_file.get_as_text().to_utf8_buffer()) != SOURCE_MANIFEST_SHA256:
		return _fail("The shared `$CBF1` source manifest targets a different ROM revision.")
	var found: Dictionary = {}
	for span_variant in source_manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == SOURCE_FILE:
			found = span_variant
			break
	if String(found.get("cpu_start", "")) != "0xCBF1" \
			or String(found.get("cpu_end_exclusive", "")) != "0xCC02" \
			or String(found.get("bank", "")) != "0x1E" \
			or String(found.get("window", "")) != "fixed" \
			or String(found.get("file_offset", "")) != HELPER_FILE_OFFSET \
			or int(found.get("length", -1)) != HELPER_LENGTH \
			or String(found.get("sha256", "")) != HELPER_SOURCE_SHA256:
		return _fail("The original source manifest omits or changes the `$CBF1` dependency.")
	_helper_bytes = FileAccess.get_file_as_bytes(SOURCE_ROOT + SOURCE_FILE)
	if _helper_bytes.size() != HELPER_LENGTH or _sha256(_helper_bytes) != HELPER_SOURCE_SHA256 \
			or String(found.get("bytes", "")).replace(" ", "").to_lower() != _helper_bytes.hex_encode():
		_helper_bytes = PackedByteArray()
		return _fail("The shared `$CBF1` extracted bytes failed size/hash/manifest validation.")
	return true


func _load_root_caller_source() -> bool:
	var manifest_file := FileAccess.open(ROOT_SOURCE_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("The slot-$09 root-caller source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("The slot-$09 root-caller source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	if String(manifest.get("schema", "")) != "ct2-slot09-ebd7-root-checks-v1" \
			or String(manifest.get("rom", {}).get("sha256", "")) != ROM_SHA256 \
			or _sha256(manifest_file.get_as_text().to_utf8_buffer()) != ROOT_MANIFEST_SHA256:
		return _fail("The slot-$09 root-caller source manifest targets a different ROM revision.")
	var found: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == ROOT_SOURCE_FILE:
			found = span_variant
			break
	if String(found.get("file_offset", "")) != ROOT_SOURCE_OFFSET \
			or int(found.get("length", -1)) != ROOT_SOURCE_LENGTH \
			or String(found.get("sha256", "")) != ROOT_SOURCE_SHA256:
		return _fail("The root-caller manifest omits or changes the fixed `$EB86-$EC07` span.")
	_root_bytes = FileAccess.get_file_as_bytes("res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/" + ROOT_SOURCE_FILE)
	if _root_bytes.size() != ROOT_SOURCE_LENGTH or _sha256(_root_bytes) != ROOT_SOURCE_SHA256 \
			or String(found.get("bytes", "")).replace(" ", "").to_lower() != _root_bytes.hex_encode():
		_root_bytes = PackedByteArray()
		return _fail("The root-caller source bytes failed size/hash/manifest validation.")
	return true


func _expect_helper(address: int, expected: PackedByteArray) -> bool:
	var offset := address - HELPER_START
	if offset < 0 or offset + expected.size() > _helper_bytes.size():
		return false
	for index in range(expected.size()):
		if int(_helper_bytes[offset + index]) != expected[index]:
			return false
	return true


func _expect_root(address: int, expected: PackedByteArray) -> bool:
	var offset := address - 0xEB86
	if offset < 0 or offset + expected.size() > _root_bytes.size():
		return false
	for index in range(expected.size()):
		if int(_root_bytes[offset + index]) != expected[index]:
			return false
	return true


func _set_nz(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	var status := int(cpu.get("p", 0)) & ~FLAG_NZ
	if (value & 0x80) != 0:
		status |= FLAG_N
	if value == 0:
		status |= FLAG_Z
	cpu["p"] = status & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | FLAG_NZ


func _compare_x(cpu: Dictionary, value: int) -> void:
	var x_value := int(cpu.get("x", 0)) & 0xFF
	var result := (x_value - value) & 0xFF
	var status := int(cpu.get("p", 0)) & ~(FLAG_NZ | FLAG_C)
	if (result & 0x80) != 0:
		status |= FLAG_N
	if result == 0:
		status |= FLAG_Z
	if x_value >= value:
		status |= FLAG_C
	cpu["p"] = status & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | FLAG_NZ | FLAG_C


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
