extends RefCounted
class_name RomSlot11ActorWorkerPrefixExecutor
## Executes the observed bank-$18 slot-$11 actor setup through `$8047`, where
## the scheduler consumer performs the verified `$C515->$CB0F` task save.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/task_context/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const WORKER_FILE := "bank18_actor_worker_entry_8000_804A.bin"
const POINTER_FILE := "bank18_actor_parameter_73_pointer_9306.bin"
const WORKER_START := 0x8000
const WORKER_END_EXCLUSIVE := 0x804A
const WORKER_BANK := 0x18
const WORKER_OFFSET := "0x030010"
const WORKER_LENGTH := WORKER_END_EXCLUSIVE - WORKER_START
const WORKER_SHA256 := "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c"
const POINTER_SHA256 := "03f3c4278cc253614b622fa856993e8b325eb061a29e54685038771778377938"
const RAM_SIZE := 0x800
const STACK_PAGE_SIZE := 0x100
const SLOT_11 := 0x11
const ENTRY_RECORD := [0xFF, 0xC8, 0x18, 0x00]
const P_C := 0x01
const P_Z := 0x02
const P_V := 0x40
const P_N := 0x80
const P_NZ_MASK := P_N | P_Z
const P_BIT_MASK := P_N | P_V | P_Z

var error_message := ""
var _configured := false
var _worker := PackedByteArray()
var _pointer_73 := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_worker.clear()
	_pointer_73.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Task-context source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Task-context source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Task-context manifest targets another ROM revision.")
	var spans_by_file: Dictionary = {}
	for span_variant: Variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			spans_by_file[String(span.get("file", ""))] = span
	var worker_spec: Dictionary = spans_by_file.get(WORKER_FILE, {})
	if worker_spec.is_empty() or String(worker_spec.get("cpu_address", "")) != "0x8000" \
			or String(worker_spec.get("file_offset", "")) != WORKER_OFFSET \
			or int(worker_spec.get("length", -1)) != WORKER_LENGTH \
			or String(worker_spec.get("sha256", "")) != WORKER_SHA256:
		return _fail("Bank-$18 actor worker mapping or hash differs from the verified source span.")
	_worker = FileAccess.get_file_as_bytes(SOURCE_ROOT + WORKER_FILE)
	if _worker.size() != WORKER_LENGTH or _sha256(_worker) != WORKER_SHA256 \
			or String(worker_spec.get("bytes", "")).replace(" ", "").to_lower() != _worker.hex_encode():
		_worker.clear()
		return _fail("Packaged bank-$18 actor worker bytes failed manifest validation.")
	var pointer_spec: Dictionary = spans_by_file.get(POINTER_FILE, {})
	if pointer_spec.is_empty() or String(pointer_spec.get("cpu_address", "")) != "0x9306" \
			or String(pointer_spec.get("file_offset", "")) != "0x031316" \
			or int(pointer_spec.get("length", -1)) != 2 \
			or String(pointer_spec.get("sha256", "")) != POINTER_SHA256:
		return _fail("Parameter-$73 actor pointer manifest mapping is unsupported.")
	_pointer_73 = FileAccess.get_file_as_bytes(SOURCE_ROOT + POINTER_FILE)
	if _pointer_73 != PackedByteArray([0x42, 0x9F]) or _sha256(_pointer_73) != POINTER_SHA256 \
			or String(pointer_spec.get("bytes", "")).replace(" ", "").to_lower() != _pointer_73.hex_encode():
		_pointer_73.clear()
		return _fail("Parameter-$73 pointer bytes do not resolve to `$9F42`.")
	if not _expect(0x8000, [0x4C, 0x0F, 0x80]) \
			or not _expect(0x800F, [0x2C, 0x3F, 0x06, 0x10, 0x03, 0x4C, 0x12, 0xC5]) \
			or not _expect(0x8047, [0x20, 0x15, 0xC5]):
		_worker.clear()
		_pointer_73.clear()
		return _fail("Actor-worker dispatch, branch, or `$8047` yield callsite changed.")
	_configured = true
	return true


## Consumes a live scheduler snapshot after slot `$11`'s source-derived initial
## task RTS. It refuses captured endpoint state and unsupported actor parameters.
func execute_from_dispatched_slot11(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure the hash-checked actor-worker source spans first.")
	var contract := _validate_boundary(boundary)
	if not bool(contract.get("ok", false)):
		return _reject(String(contract.get("reason", "Invalid slot-$11 dispatch snapshot.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var registers := {
		"a": int(boundary["a"]), "x": int(boundary["x"]),
		"y": int(boundary["y"]), "p": int(boundary["p"]),
		"p_known_mask": int(boundary["p_known_mask"]),
		"sp": int(boundary["sp"]), "pc": int(boundary["pc"]),
	}
	var mapper := {"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"])}
	var input_registers := registers.duplicate(true)
	var entry_ram := ram.duplicate()
	var writes: Array[Dictionary] = []
	var executed: Array[int] = []
	var pc := WORKER_START
	var a := int(registers["a"]) & 0xFF
	var x := int(registers["x"]) & 0xFF
	var y := int(registers["y"]) & 0xFF
	var p := int(registers.get("p", 0)) & 0xFF
	var p_known := int(registers.get("p_known_mask", 0)) & 0xFF
	var sp := int(registers["sp"]) & 0xFF

	# $8000: JMP $800F.
	executed.append(pc)
	pc = _word_at(0x8000)
	if pc != 0x800F:
		return _reject("The bank-$18 task entry no longer jumps to `$800F`.")

	# $800F: BIT $063F; BPL $8017. The observed route takes this branch.
	executed.append(pc)
	if not _expect(pc, [0x2C, 0x3F, 0x06]):
		return _reject("Actor-worker `$800F` BIT opcode differs from its packaged source.")
	var bit_value := int(ram[0x063F])
	p = (p & 0x3D) | (bit_value & P_N) | (bit_value & P_V)
	if (a & bit_value) == 0:
		p |= P_Z
	p_known |= P_BIT_MASK
	pc = 0x8012
	if not _expect(pc, [0x10, 0x03]):
		return _reject("Actor-worker `$8012` branch opcode differs from its packaged source.")
	executed.append(pc)
	if (p & P_N) != 0:
		return _unsupported("The live `$063F` value selects the `$C512` finish branch; only the observed setup path is implemented.")
	pc = 0x8017

	# $8017-$8030 resolves the actor data pointer from the ROM table at $9220.
	if not _expect(pc, [0xA9, 0x20, 0x85, 0x5F, 0xA9, 0x92, 0x85, 0x60,
			0xAD, 0xEA, 0x05, 0x0A, 0x90, 0x02, 0xE6, 0x60, 0xA8,
			0xB1, 0x5F, 0xAA, 0xC8, 0xB1, 0x5F, 0x85, 0x60, 0x86, 0x5F]):
		return _reject("Actor-worker pointer resolver bytes changed.")
	executed.append(0x8017) # LDA #$20
	a = 0x20
	p = _set_nz(p, a)
	p_known |= P_NZ_MASK
	executed.append(0x8019) # STA $5F
	_write(ram, writes, 0x005F, a, 0x8019)
	executed.append(0x801B) # LDA #$92
	a = 0x92
	p = _set_nz(p, a)
	executed.append(0x801D) # STA $60
	_write(ram, writes, 0x0060, a, 0x801D)
	executed.append(0x801F)
	a = int(ram[0x05EA])
	if a != 0x73:
		return _unsupported("Only live actor parameter `$73` has a packaged pointer-table entry.")
	p = _set_nz(p, a)
	executed.append(0x8022) # ASL A
	var doubled := a << 1
	var carry := 1 if doubled > 0xFF else 0
	a = doubled & 0xFF
	p = _set_nz(p, a)
	p = (p & 0xFE) | carry
	p_known |= P_C
	if carry != 0:
		return _unsupported("The actor pointer-table high-page carry path is not packaged for parameter `$73`.")
	executed.append(0x8023) # BCC $8027
	y = a
	p = _set_nz(p, y)
	executed.append(0x8027) # TAY
	# The indexed read is deliberately restricted to the manifest-backed $9306 entry.
	var table_base := 0x9220
	var pointer_index := y
	var table_address := (table_base + pointer_index) & 0xFFFF
	if table_address != 0x9306:
		return _unsupported("The live actor parameter resolves outside the packaged `$9306` pointer entry.")
	executed.append(0x8028) # LDA ($5F),Y
	a = int(_pointer_73[0])
	p = _set_nz(p, a)
	executed.append(0x802A) # TAX
	x = a
	p = _set_nz(p, x)
	executed.append(0x802B) # INY
	y = (y + 1) & 0xFF
	p = _set_nz(p, y)
	executed.append(0x802C) # LDA ($5F),Y
	table_address = (table_base + y) & 0xFFFF
	if table_address != 0x9307:
		return _reject("Pointer-table high-byte read is not adjacent to `$9306`.")
	a = int(_pointer_73[1])
	p = _set_nz(p, a)
	executed.append(0x802E) # STA $60
	_write(ram, writes, 0x0060, a, 0x802E)
	executed.append(0x8030) # STX $5F
	_write(ram, writes, 0x005F, x, 0x8030)

	# $8032-$8046 clears only the worker-owned setup bytes, then sets $05E3.
	if not _expect(0x8032, [0xA9, 0x00, 0x8D, 0xE9, 0x05, 0x8D, 0xE5, 0x05,
			0x8D, 0xE4, 0x05, 0x8D, 0xF4, 0x05, 0xA9, 0x01, 0x8D, 0xE3, 0x05,
			0xA9, 0x01]):
		return _reject("Actor-worker state initialization bytes changed.")
	executed.append(0x8032)
	a = 0
	p = _set_nz(p, a)
	p_known |= P_NZ_MASK
	for write_pc: int in [0x8034, 0x8037, 0x803A, 0x803D]:
		executed.append(write_pc)
		var address := _absolute_operand(write_pc + 1)
		_write(ram, writes, address, a, write_pc)
	executed.append(0x8040)
	a = 1
	p = _set_nz(p, a)
	executed.append(0x8042)
	_write(ram, writes, 0x05E3, a, 0x8042)
	executed.append(0x8045)
	a = 1
	p = _set_nz(p, a)
	pc = 0x8047
	registers["a"] = a
	registers["x"] = x
	registers["y"] = y
	registers["p"] = p
	registers["p_known_mask"] = p_known
	registers["sp"] = sp
	registers["pc"] = pc

	if x != 0x42 or y != 0xE7 or a != 0x01:
		return _reject("Actor prefix did not derive the trace-matched `$42/$E7/$01` callsite registers.")
	return {
		"ok": true,
		"status": "slot11_actor_worker_at_8047_before_jsr",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_pointer_file": POINTER_FILE,
		"source_pointer_sha256": POINTER_SHA256,
		"source_file": WORKER_FILE,
		"source_sha256": WORKER_SHA256,
		"entry_pc": WORKER_START,
		"exit_pc": pc,
		"yield_callsite_pc": pc,
		"yield_target_pc": 0xC515,
		"slot_base": SLOT_11,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": input_registers,
		"entry_ram_image": entry_ram,
		"entry_stack_page": stack.duplicate(),
		"registers": registers,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"memory_writes": writes,
		"instruction_pcs": executed,
		"resolved_actor_stream_pointer": 0x9F42,
		"resolved_parameter": 0x73,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}


func _validate_boundary(boundary: Dictionary) -> Dictionary:
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != WORKER_START \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "The live scheduler snapshot is not the dispatched slot-$11 `$8000` task."}
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_low := int(boundary.get("bank_low", -1))
	var mapper_high := int(boundary.get("bank_high", -1))
	if not record is PackedByteArray or record != PackedByteArray(ENTRY_RECORD) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_PAGE_SIZE \
			or not boundary.has("a") or not boundary.has("x") \
			or not boundary.has("y") or not boundary.has("p") \
			or not boundary.has("p_known_mask") or not boundary.has("sp") \
			or not boundary.has("pc"):
		return {"ok": false, "reason": "Slot-$11 snapshot lacks the exact task, RAM, stack, registers, or mapper data."}
	if int(ram[0x05EA]) != 0x73 or (int(ram[0x063F]) & P_N) != 0 \
			or int(stack[0xC9]) != 0xFF or int(stack[0xCA]) != 0x7F \
			or mapper_low != 0x18 or mapper_high != 0x19:
		return {"ok": false, "reason": "Live actor parameter, branch state, seeded RTS stack, or mapper pair is unsupported."}
	return {"ok": true}


func _expect(cpu_address: int, expected: Array[int]) -> bool:
	var offset := cpu_address - WORKER_START
	if offset < 0 or offset + expected.size() > _worker.size():
		return false
	for index: int in expected.size():
		if int(_worker[offset + index]) != expected[index]:
			return false
	return true


func _word_at(cpu_address: int) -> int:
	return int(_worker[cpu_address - WORKER_START + 1]) \
		| (int(_worker[cpu_address - WORKER_START + 2]) << 8)


func _absolute_operand(operand_address: int) -> int:
	var offset := operand_address - WORKER_START
	return int(_worker[offset]) | (int(_worker[offset + 1]) << 8)


func _write(ram: PackedByteArray, writes: Array[Dictionary], address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	ram[address] = byte_value
	writes.append({"pc": pc, "address": address, "value": byte_value})


func _set_nz(p: int, value: int) -> int:
	var result := p & 0x7D
	if (value & 0x80) != 0:
		result |= P_N
	if (value & 0xFF) == 0:
		result |= P_Z
	return result


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _reject(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "error": reason, "source_manifest": MANIFEST_PATH}


func _unsupported(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "unsupported_live_branch", "error": reason}


func _fail(message: String) -> bool:
	error_message = message
	return false
