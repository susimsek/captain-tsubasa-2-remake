extends RefCounted
class_name RomPassNoCandidatesContinuationExecutor
## Bounded ROM-byte 6502 continuation for PASS action 1 / holder slot 6.
## Starts only from a scheduler-owned D68A boundary proven to follow the real
## E945 renderer RTS, and stops at D6C7 before CB99. This is not cycle accurate.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/pass_no_candidates_continuation/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const MANIFEST_SHA256 := "36dd9b74944ef15accef3ccc5cc4bce3b691af99856886fb7a2d89a03a178fa8"
const FIXED_BANK := 0x1E
const SOURCE_BANK := 0x1C
const ENTRY_PC := 0xD68A
const EXIT_PC := 0xD6C7
const PASS_ACTION_ID := 1
const HOLDER_SLOT := 6
const STATUS_CARRY := 0x01
const STATUS_ZERO := 0x02
const STATUS_INTERRUPT := 0x04
const STATUS_DECIMAL := 0x08
const STATUS_BREAK := 0x10
const STATUS_UNUSED := 0x20
const STATUS_OVERFLOW := 0x40
const STATUS_NEGATIVE := 0x80
const MAX_INSTRUCTIONS := 600

var error_message := ""
var _configured := false
var _rom_spans: Array[Dictionary] = []
var _last_result: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_rom_spans.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("The ROM-derived PASS continuation manifest is missing.")
	if FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		return _fail("The PASS continuation manifest SHA-256 differs from the pinned extraction.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("The PASS continuation manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-pass-no-candidates-continuation-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256 \
			or int(manifest.get("rom_size_bytes", -1)) != 0x60010 \
			or String(manifest.get("runtime_source_kind", "")) \
			!= "ROM-derived code and lookup bytes; no emulator state/capture":
		return _fail("The PASS continuation manifest does not identify the pinned ROM-derived source.")
	var rows: Variant = manifest.get("resources", [])
	if not rows is Array or rows.size() != 20:
		return _fail("The PASS continuation manifest has an unexpected ROM span set.")
	for row_variant: Variant in rows:
		if not row_variant is Dictionary:
			return _fail("A PASS continuation source row is malformed.")
		var row: Dictionary = row_variant
		var path := SOURCE_ROOT + String(row.get("resource", ""))
		var bank := String(row.get("prg_bank", "0x00")).hex_to_int()
		var start := String(row.get("cpu_start", "0x0000")).hex_to_int()
		var end_exclusive := String(row.get("cpu_end_exclusive", "0x0000")).hex_to_int()
		var bytes := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		if bytes.size() != int(row.get("length_bytes", -1)) \
				or FileAccess.get_sha256(path) != String(row.get("sha256", "")) \
				or start < 0x8000 or end_exclusive <= start \
				or bytes.size() != end_exclusive - start:
			return _fail("A PASS continuation ROM span is missing, corrupt, or incorrectly mapped: " + path)
		_rom_spans.append({"bank": bank, "start": start, "end": end_exclusive, "bytes": bytes})
	if not _span_prefix_matches(0x1E, 0xD68A, [0xAE, 0x3B, 0x04, 0xE0, 0x02, 0xD0, 0x05]) \
			or not _span_prefix_matches(0x1E, 0xD717, [0x48, 0xA5, 0x22, 0xA9, 0x1C, 0x85, 0x24]) \
			or not _span_prefix_matches(0x1C, 0x8009, [0x4C, 0x06, 0x8C]) \
			or not _span_prefix_matches(0x1C, 0x8012, [0x4C, 0x9D, 0x81]) \
			or not _span_prefix_matches(0x1C, 0x8F07, [0x00, 0x00, 0x00, 0x00]):
		return _fail("PASS caller, bank-$1C vectors, or the holder-$06 empty-candidate table changed.")
	_configured = true
	return true


## `boundary` must be a fresh scheduler snapshot at D68A. `renderer_return`
## must be the one-use proof for D687 JSR E945 -> E945 RTS -> D68A.
func execute_from_live_e945_renderer_return(boundary: Dictionary,
		renderer_return: Dictionary) -> Dictionary:
	_last_result.clear()
	if not _configured and not configure_from_project_sources():
		return _refused("source_not_ready", error_message)
	var worker_boundary := boundary
	if int(boundary.get("pc", -1)) == 0xE945:
		var entry_check := _validate_renderer_entry_boundary(boundary)
		if not bool(entry_check.get("ok", false)):
			return _refused("invalid_live_boundary", String(entry_check.get("error", "Invalid live E945 boundary.")))
		var receipt_entry: Variant = renderer_return.get("entry_boundary", {})
		if not receipt_entry is Dictionary or not _same_boundary_fingerprint(boundary, receipt_entry):
			return _refused("invalid_renderer_return_receipt",
				"Renderer return receipt is not bound to the scheduler-owned live E945 entry snapshot.")
		var returned: Variant = renderer_return.get("returned_boundary", {})
		if not returned is Dictionary:
			return _refused("invalid_renderer_return_receipt",
				"Renderer return receipt omits the scheduler-owned post-RTS D68A boundary.")
		worker_boundary = returned
	var precondition := _validate_boundary(worker_boundary, renderer_return)
	if not bool(precondition.get("ok", false)):
		return _refused(String(precondition.get("status", "invalid_live_boundary")),
			String(precondition.get("error", "Invalid PASS continuation boundary.")))
	var ram := (worker_boundary["ram_image"] as PackedByteArray).duplicate()
	var stack := (worker_boundary["stack_page"] as PackedByteArray).duplicate()
	var cpu := {"pc": ENTRY_PC, "sp": int(worker_boundary["sp"]) & 0xFF,
		"a": int(worker_boundary.get("a", 0)) & 0xFF,
		"x": int(worker_boundary.get("x", 0)) & 0xFF,
		"y": int(worker_boundary.get("y", 0)) & 0xFF,
		"p": (int(worker_boundary.get("p", STATUS_UNUSED)) | STATUS_UNUSED) & 0xFF,
		"p_known_mask": int(worker_boundary.get("p_known_mask", 0)) & 0xFF}
	var source_reads: Array[Dictionary] = []
	var source_writes: Array[Dictionary] = []
	var source_stack_writes: Array[Dictionary] = []
	var source_stack_reads: Array[Dictionary] = []
	var source_pc_history: Array[int] = []
	var source_instruction_pcs: Array[int] = []
	var mapper_events: Array[Dictionary] = []
	var mapper_registers := _mapper_registers_from_boundary(worker_boundary)
	var mapper_select := int((worker_boundary.get("mapper", {}) as Dictionary).get("select", 0))
	var unsupported := ""
	var instruction_count := 0
	while int(cpu["pc"]) != EXIT_PC and instruction_count < MAX_INSTRUCTIONS:
		var current_pc := int(cpu["pc"])
		if current_pc >= 0x8C2C and current_pc < 0x8C3B:
			unsupported = "The ROM selected the candidate-found branch at $8C2C; only the observed no-candidates branch is supported."
			break
		if current_pc >= 0xD6B0 and current_pc < 0xD6BE:
			unsupported = "The PASS caller left its source no-candidates branch for an unsupported candidate continuation at $%04X (`$0430=$%02X`, `$48/$49=$%02X/$%02X`, `A/P=$%02X/$%02X`)." % [current_pc, int(ram[0x0430]), int(ram[0x0048]), int(ram[0x0049]), int(cpu["a"]), int(cpu["p"])]
			break
		if not _execute_one(cpu, ram, stack, source_reads, source_writes,
				source_stack_writes, source_stack_reads, mapper_events,
				mapper_registers, mapper_select, source_instruction_pcs,
				source_pc_history):
			return _refused("unsupported_rom_instruction", error_message)
		mapper_select = int(cpu.get("mapper_select", mapper_select))
		instruction_count += 1
	if not unsupported.is_empty():
		return _refused("unsupported_candidate_branch", unsupported)
	if int(cpu["pc"]) != EXIT_PC:
		return _refused("source_step_limit", "The bounded ROM continuation did not reach $D6C7 within the instruction limit.")
	if int(ram[0x0430]) != 0 or int(ram[0x043B]) != PASS_ACTION_ID \
			or int(ram[0x043C]) != 0 or int(ram[0x0441]) != HOLDER_SLOT:
		return _refused("source_branch_mismatch", "The ROM no-candidates path did not leave the expected PASS/holder RAM signature.")
	var start_sp := int(worker_boundary["sp"]) & 0xFF
	var end_mapper := {"bank_registers": mapper_registers.duplicate(true),
		"select_register": mapper_select, "fixed_bank": FIXED_BANK,
		"bank_registers_at_d6c7": mapper_registers.duplicate(true),
		"mapper_events": mapper_events.duplicate(true),
		"saved_task_bank_pair": [int(worker_boundary.get("bank_low", -1)), int(worker_boundary.get("bank_high", -1))],
		"switchable_window_shadow_pair": [int(ram[0x0024]), int(ram[0x0025])]}
	var d6c7_boundary := worker_boundary.duplicate(true)
	d6c7_boundary["pc"] = EXIT_PC
	d6c7_boundary["sp"] = int(cpu["sp"])
	d6c7_boundary["a"] = int(cpu["a"])
	d6c7_boundary["x"] = int(cpu["x"])
	d6c7_boundary["y"] = int(cpu["y"])
	d6c7_boundary["p"] = int(cpu["p"])
	d6c7_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	d6c7_boundary["ram_image"] = ram.duplicate()
	d6c7_boundary["stack_page"] = stack.duplicate()
	d6c7_boundary["ram_007F"] = int(ram[0x007F])
	d6c7_boundary["mapper"] = end_mapper.duplicate(true)
	d6c7_boundary["source_label"] = "ROM-byte PASS no-candidates continuation `$D68A->$D6C7`"
	var result := {
		"ok": true,
		"status": "pass_no_candidates_reached_live_d6c7",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": MANIFEST_SHA256,
		"source_boundary_pc": ENTRY_PC,
		"renderer_entry_boundary_pc": 0xE945 if int(boundary.get("pc", -1)) == 0xE945 else -1,
		"renderer_return_receipt_id": String(renderer_return.get("receipt_id", "")),
		"source_exit_pc": EXIT_PC,
		"entry_sp": start_sp,
		"final_sp": int(cpu["sp"]),
		"registers": cpu.duplicate(true),
		"source_pc_history": source_pc_history,
		"source_instruction_pcs": source_instruction_pcs,
		"source_reads": source_reads,
		"source_writes": source_writes,
		"source_stack_writes": source_stack_writes,
		"source_stack_reads": source_stack_reads,
		"renderer_return": _renderer_return_summary(renderer_return),
		"mapper": end_mapper,
		"ppu_events": [],
		"apu_events": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"instruction_level_parity_claimed": false,
		"candidate_branch_supported": false,
		"no_candidates_ram_signature": {"0430": int(ram[0x0430]),
			"043B": int(ram[0x043B]), "043C": int(ram[0x043C]),
			"0441": int(ram[0x0441])},
		"d6c7_boundary": d6c7_boundary,
		"instruction_count": instruction_count,
	}
	_last_result = result.duplicate(true)
	return result


func get_last_result() -> Dictionary:
	return _last_result.duplicate(true)


func _validate_boundary(boundary: Dictionary, renderer_return: Dictionary) -> Dictionary:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram is PackedByteArray or ram.size() != 0x800 \
			or not stack is PackedByteArray or stack.size() != 0x100:
		return {"ok": false, "error": "PASS continuation requires live 2 KiB RAM and a 256-byte stack page."}
	if String(boundary.get("rom_sha256", boundary.get("source_rom_sha256", ""))) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != ENTRY_PC \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or (ram as PackedByteArray).slice(0x0100, 0x0200) != stack:
		return {"ok": false, "error": "The live boundary is not scheduler-owned slot-$05 `$D68A` with its original `$1A/$1B` task bank pair and synchronized stack."}
	for forbidden_key in ["fceux_ram", "captured_ram", "emulator_snapshot", "trace_ram"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "error": "Emulator/capture RAM is forbidden as continuation input."}
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not mapper_variant is Dictionary:
		return {"ok": false, "error": "The D68A boundary omits its live mapper snapshot."}
	var registers := _mapper_registers_from_boundary(boundary)
	if int(registers.get(6, -1)) != 0x1A or int(registers.get(7, -1)) != 0x1B:
		return {"ok": false, "error": "The live D68A mapper proof does not show source banks `$1A/$1B`."}
	var return_pcs: Variant = renderer_return.get("source_instruction_pcs", [])
	if not return_pcs is Array:
		return {"ok": false, "error": "The renderer return receipt omits its source instruction history."}
	if not bool(renderer_return.get("ok", false)) \
			or String(renderer_return.get("rom_sha256", "")) != ROM_SHA256 \
			or int(renderer_return.get("slot_base", -1)) != 0x05 \
			or int(renderer_return.get("entry_pc", -1)) != 0xE945 \
			or int(renderer_return.get("callsite_pc", -1)) != 0xD687 \
			or int(renderer_return.get("return_pc", -1)) != ENTRY_PC \
			or not bool(renderer_return.get("returned_via_rts", false)) \
			or not return_pcs.has(0xE945):
		return {"ok": false, "error": "A genuine one-use `$D687->E945->D68A` ROM renderer-return receipt is required."}
	var returned_boundary: Variant = renderer_return.get("returned_boundary", {})
	if returned_boundary is Dictionary and not returned_boundary.is_empty():
		if int(returned_boundary.get("pc", -1)) != ENTRY_PC \
				or int(returned_boundary.get("sp", -1)) != int(boundary.get("sp", -2)) \
				or _ram_hash(returned_boundary.get("ram_image", PackedByteArray())) != _ram_hash(ram) \
				or _stack_hash(returned_boundary.get("stack_page", PackedByteArray())) != _stack_hash(stack):
			return {"ok": false, "error": "Renderer return receipt is not bound to this exact live D68A RAM/stack boundary."}
	if int((ram as PackedByteArray)[0x043B]) != PASS_ACTION_ID \
			or int((ram as PackedByteArray)[0x0441]) != HOLDER_SLOT \
			or int((ram as PackedByteArray)[0x061E]) != 0x81:
		return {"ok": false, "status": "unsupported_route_variant",
			"error": "This executor supports only PASS action 1, the observed holder slot 6, and its confirmed selection latch."}
	return {"ok": true}


func _validate_renderer_entry_boundary(boundary: Dictionary) -> Dictionary:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram is PackedByteArray or ram.size() != 0x800 \
			or not stack is PackedByteArray or stack.size() != 0x100 \
			or String(boundary.get("rom_sha256", boundary.get("source_rom_sha256", ""))) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 or int(boundary.get("pc", -1)) != 0xE945 \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or (ram as PackedByteArray).slice(0x0100, 0x0200) != stack:
		return {"ok": false, "error": "The renderer input is not the live scheduler slot-$05 `$E945` boundary with synchronized stack and `$1A/$1B` task banks."}
	var registers := _mapper_registers_from_boundary(boundary)
	if int(registers.get(6, -1)) != 0x1A or int(registers.get(7, -1)) != 0x1B:
		return {"ok": false, "error": "The live E945 mapper proof does not show source banks `$1A/$1B`."}
	return {"ok": true}


func _mapper_registers_from_boundary(boundary: Dictionary) -> Dictionary:
	var mapper: Variant = boundary.get("mapper", {})
	if not mapper is Dictionary:
		return {}
	var registers: Variant = mapper.get("bank_registers", {})
	if not registers is Dictionary:
		return {}
	return {6: int(registers.get(6, registers.get("6", -1))),
		7: int(registers.get(7, registers.get("7", -1)))}


func _same_boundary_fingerprint(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("pc", -1)) == int(right.get("pc", -2)) \
			and int(left.get("sp", -1)) == int(right.get("sp", -2)) \
			and int(left.get("slot_base", -1)) == int(right.get("slot_base", -2)) \
			and int(left.get("active_task_slot", -1)) == int(right.get("active_task_slot", -2)) \
			and _ram_hash(left.get("ram_image", PackedByteArray())) \
			== _ram_hash(right.get("ram_image", PackedByteArray())) \
			and _stack_hash(left.get("stack_page", PackedByteArray())) \
			== _stack_hash(right.get("stack_page", PackedByteArray()))


func _execute_one(cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		reads: Array[Dictionary], writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		mapper_events: Array[Dictionary], mapper_registers: Dictionary,
		mapper_select: int, instruction_pcs: Array[int], history: Array[int]) -> bool:
	var pc := int(cpu["pc"]) & 0xFFFF
	var opcode := _read_rom_byte(pc)
	if opcode < 0:
		return _fail("ROM source bytes are not available at CPU `$%04X` for the bounded PASS continuation." % pc)
	instruction_pcs.append(pc)
	history.append(pc)
	var next_pc := (pc + 1) & 0xFFFF
	var value := 0
	var address := 0
	var carry := 0
	match opcode:
		0xA9, 0xA2, 0xA0, 0x69, 0xE9, 0xC0, 0xC9, 0xE0, 0x29, 0x09:
			value = _read_rom_byte(next_pc)
			if value < 0:
				return _fail("Immediate operand missing at `$%04X`." % pc)
			next_pc += 1
			match opcode:
				0xA9:
					cpu["a"] = value; _set_nz(cpu, value)
				0xA2:
					cpu["x"] = value; _set_nz(cpu, value)
				0xA0:
					cpu["y"] = value; _set_nz(cpu, value)
				0x69:
					_adc(cpu, value)
				0xE9:
					_sbc(cpu, value)
				0xC0:
					_compare(cpu, int(cpu["y"]), value)
				0xC9:
					_compare(cpu, int(cpu["a"]), value)
				0xE0:
					_compare(cpu, int(cpu["x"]), value)
				0x29:
					cpu["a"] = int(cpu["a"]) & value; _set_nz(cpu, int(cpu["a"]))
				0x09:
					cpu["a"] = int(cpu["a"]) | value; _set_nz(cpu, int(cpu["a"]))
		0xAD, 0xAE, 0xAC, 0x8D, 0x8E, 0x6D, 0xED, 0xCD:
			address = _fetch_word(next_pc); next_pc += 2
			if address < 0:
				return _fail("Absolute address is missing at `$%04X`." % pc)
			if opcode == 0x8D or opcode == 0x8E:
				value = int(cpu["a"] if opcode == 0x8D else cpu["x"])
				if not _write_byte(address, value, pc, ram, writes, mapper_events, mapper_registers, mapper_select):
					return false
				if address == 0x8000:
					mapper_select = value
				elif address == 0x8001:
					mapper_select = int(cpu.get("mapper_select", mapper_select))
					mapper_registers[mapper_select & 7] = value
				cpu["mapper_select"] = mapper_select
			else:
				value = _read_data(address, pc, ram, reads)
				if value < 0:
					return _fail("Source data read at `$%04X` is outside extracted ROM spans." % address)
				match opcode:
					0xAD:
						cpu["a"] = value; _set_nz(cpu, value)
					0xAE:
						cpu["x"] = value; _set_nz(cpu, value)
					0xAC:
						cpu["y"] = value; _set_nz(cpu, value)
					0x6D:
						_adc(cpu, value)
					0xED:
						_sbc(cpu, value)
					0xCD:
						_compare(cpu, int(cpu["a"]), value)
		0xA4, 0xA5, 0x84, 0x85, 0x86, 0x65, 0xE5, 0xC5, 0x26:
			address = _read_rom_byte(next_pc); next_pc += 1
			if address < 0:
				return _fail("Zero-page operand is missing at `$%04X`." % pc)
			if opcode == 0x84 or opcode == 0x85 or opcode == 0x86:
				value = int(cpu["y"] if opcode == 0x84 else (cpu["a"] if opcode == 0x85 else cpu["x"]))
				if not _write_byte(address, value, pc, ram, writes, mapper_events, mapper_registers, mapper_select):
					return false
			else:
				value = _read_data(address, pc, ram, reads)
				if value < 0:
					return _fail("Zero-page data read is outside RAM at `$%04X`." % address)
				match opcode:
					0xA4:
						cpu["y"] = value; _set_nz(cpu, value)
					0xA5:
						cpu["a"] = value; _set_nz(cpu, value)
					0x65:
						_adc(cpu, value)
					0xE5:
						_sbc(cpu, value)
					0xC5:
						_compare(cpu, int(cpu["a"]), value)
					0x26:
						var new_carry := 1 if (value & 0x80) != 0 else 0
						value = ((value << 1) | (1 if (int(cpu["p"]) & STATUS_CARRY) != 0 else 0)) & 0xFF
						cpu["p"] = (int(cpu["p"]) & ~STATUS_CARRY) | new_carry
						cpu["p_known_mask"] = int(cpu["p_known_mask"]) | STATUS_CARRY
						_set_nz(cpu, value)
						if not _write_byte(address, value, pc, ram, writes, mapper_events, mapper_registers, mapper_select):
							return false
		0xBD, 0xB9, 0xBE, 0x79:
			address = _fetch_word(next_pc); next_pc += 2
			if address < 0:
				return _fail("Indexed absolute address is missing at `$%04X`." % pc)
			var index := int(cpu["x"]) if opcode == 0xBD else int(cpu["y"])
			address = (address + index) & 0xFFFF
			value = _read_data(address, pc, ram, reads)
			if value < 0:
				return _fail("Indexed ROM/RAM read is outside extracted spans at `$%04X`." % address)
			match opcode:
				0xBD, 0xB9:
					cpu["a"] = value; _set_nz(cpu, value)
				0xBE:
					cpu["x"] = value; _set_nz(cpu, value)
				0x79:
					_adc(cpu, value)
		0xB1, 0xD1:
			var zp := _read_rom_byte(next_pc); next_pc += 1
			if zp < 0:
				return _fail("Indirect-indexed operand is missing at `$%04X`." % pc)
			var pointer := _read_data(zp, pc, ram, reads)
			var pointer_high := _read_data((zp + 1) & 0xFF, pc, ram, reads)
			if pointer < 0 or pointer_high < 0:
				return _fail("Indirect pointer escaped source RAM at `$%04X`." % zp)
			address = (((pointer_high << 8) | pointer) + int(cpu["y"])) & 0xFFFF
			value = _read_data(address, pc, ram, reads)
			if value < 0:
				return _fail("Indirect-indexed read escaped source spans at `$%04X`." % address)
			if opcode == 0xB1:
				cpu["a"] = value; _set_nz(cpu, value)
			else:
				_compare(cpu, int(cpu["a"]), value)
		0x20:
			var target := _fetch_word(next_pc)
			if target < 0:
				return _fail("JSR target is missing at `$%04X`." % pc)
			var return_address := (next_pc + 1) & 0xFFFF
			if not _push(cpu, stack, ram, stack_writes, pc, (return_address >> 8) & 0xFF, "jsr_push_high") \
					or not _push(cpu, stack, ram, stack_writes, pc, return_address & 0xFF, "jsr_push_low"):
				return false
			next_pc = target
		0x4C:
			var target := _fetch_word(next_pc)
			if target < 0:
				return _fail("JMP target is missing at `$%04X`." % pc)
			next_pc = target
		0x60:
			var low := _pop(cpu, stack, ram, stack_reads, pc)
			var high := _pop(cpu, stack, ram, stack_reads, pc)
			if low < 0 or high < 0:
				return false
			next_pc = (((high << 8) | low) + 1) & 0xFFFF
		0x48:
			if not _push(cpu, stack, ram, stack_writes, pc, int(cpu["a"]), "pha"):
				return false
		0x68:
			value = _pop(cpu, stack, ram, stack_reads, pc)
			if value < 0:
				return false
			cpu["a"] = value; _set_nz(cpu, value)
		0x08:
			if not _push(cpu, stack, ram, stack_writes, pc,
					(int(cpu["p"]) | STATUS_BREAK | STATUS_UNUSED) & 0xFF, "php"):
				return false
		0x28:
			value = _pop(cpu, stack, ram, stack_reads, pc)
			if value < 0:
				return false
			cpu["p"] = (value | STATUS_UNUSED) & 0xFF
			cpu["p_known_mask"] = 0xFF
		0x0A:
			value = int(cpu["a"])
			cpu["p"] = (int(cpu["p"]) & ~STATUS_CARRY) | (1 if (value & 0x80) != 0 else 0)
			cpu["p_known_mask"] = int(cpu["p_known_mask"]) | STATUS_CARRY
			cpu["a"] = (value << 1) & 0xFF; _set_nz(cpu, int(cpu["a"]))
		0x4A:
			value = int(cpu["a"])
			cpu["p"] = (int(cpu["p"]) & ~STATUS_CARRY) | (1 if (value & 1) != 0 else 0)
			cpu["p_known_mask"] = int(cpu["p_known_mask"]) | STATUS_CARRY
			cpu["a"] = (value >> 1) & 0xFF; _set_nz(cpu, int(cpu["a"]))
		0xAA:
			cpu["x"] = int(cpu["a"]); _set_nz(cpu, int(cpu["x"]))
		0x8A:
			cpu["a"] = int(cpu["x"]); _set_nz(cpu, int(cpu["a"]))
		0xA8:
			cpu["y"] = int(cpu["a"]); _set_nz(cpu, int(cpu["y"]))
		0x98:
			cpu["a"] = int(cpu["y"]); _set_nz(cpu, int(cpu["a"]))
		0xC8:
			cpu["y"] = (int(cpu["y"]) + 1) & 0xFF; _set_nz(cpu, int(cpu["y"]))
		0x38:
			cpu["p"] = int(cpu["p"]) | STATUS_CARRY
			cpu["p_known_mask"] = int(cpu["p_known_mask"]) | STATUS_CARRY
		0x18:
			cpu["p"] = int(cpu["p"]) & ~STATUS_CARRY
			cpu["p_known_mask"] = int(cpu["p_known_mask"]) | STATUS_CARRY
		0x10, 0x30, 0x90, 0xB0, 0xF0, 0xD0:
			var displacement := _read_rom_byte(next_pc)
			if displacement < 0:
				return _fail("Branch operand is missing at `$%04X`." % pc)
			next_pc += 1
			var take := false
			match opcode:
				0x10: take = (int(cpu["p"]) & STATUS_NEGATIVE) == 0
				0x30: take = (int(cpu["p"]) & STATUS_NEGATIVE) != 0
				0x90: take = (int(cpu["p"]) & STATUS_CARRY) == 0
				0xB0: take = (int(cpu["p"]) & STATUS_CARRY) != 0
				0xF0: take = (int(cpu["p"]) & STATUS_ZERO) != 0
				0xD0: take = (int(cpu["p"]) & STATUS_ZERO) == 0
			if take:
				if displacement & 0x80:
					displacement -= 0x100
				next_pc = (next_pc + displacement) & 0xFFFF
		0xEA:
			pass
		_:
			return _fail("Unsupported ROM opcode `$%02X` at `$%04X`; executor refuses to invent a helper result." % [opcode, pc])
	cpu["pc"] = next_pc & 0xFFFF
	cpu["p"] = (int(cpu["p"]) | STATUS_UNUSED) & 0xFF
	return true


func _read_rom_byte(address: int) -> int:
	var wanted_bank := FIXED_BANK if address >= 0xC000 and address <= 0xDFFF \
		else 0x1D if address >= 0xA000 and address <= 0xBFFF else SOURCE_BANK
	for span in _rom_spans:
		if int(span["bank"]) == wanted_bank and address >= int(span["start"]) \
				and address < int(span["end"]):
			return int((span["bytes"] as PackedByteArray)[address - int(span["start"])])
	return -1


func _fetch_word(address: int) -> int:
	var low := _read_rom_byte(address)
	var high := _read_rom_byte(address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _read_data(address: int, pc: int, ram: PackedByteArray,
		reads: Array[Dictionary]) -> int:
	var value := -1
	if address >= 0 and address < ram.size():
		value = int(ram[address])
	else:
		value = _read_rom_byte(address)
	if value >= 0:
		reads.append({"source_pc": pc, "address": address, "value": value})
	return value


func _write_byte(address: int, value: int, pc: int, ram: PackedByteArray,
		writes: Array[Dictionary], mapper_events: Array[Dictionary],
		mapper_registers: Dictionary, mapper_select: int) -> bool:
	value &= 0xFF
	if address == 0x8000:
		mapper_events.append({"source_pc": pc, "address": address, "value": value,
			"operation": "mmc3_select"})
		return true
	if address == 0x8001:
		mapper_events.append({"source_pc": pc, "address": address, "value": value,
			"register": mapper_select & 7, "operation": "mmc3_bank_write"})
		return true
	if address < 0 or address >= ram.size():
		return _fail("Source write to unsupported memory `$%04X` at `$%04X`." % [address, pc])
	ram[address] = value
	writes.append({"source_pc": pc, "address": address, "value": value})
	return true


func _push(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		writes: Array[Dictionary], pc: int, value: int, operation: String) -> bool:
	var sp := int(cpu["sp"]) & 0xFF
	var address := 0x0100 | sp
	stack[sp] = value & 0xFF
	ram[address] = value & 0xFF
	writes.append({"source_pc": pc, "address": address,
		"value": value & 0xFF, "operation": operation})
	cpu["sp"] = (sp - 1) & 0xFF
	return true


func _pop(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		reads: Array[Dictionary], pc: int) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	if value != int(ram[0x0100 | sp]):
		_fail("Source stack mirror differs while returning from `$%04X`." % pc)
		return -1
	reads.append({"source_pc": pc, "address": 0x0100 | sp, "value": value})
	return value


func _set_nz(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	var p := int(cpu["p"]) & ~(STATUS_NEGATIVE | STATUS_ZERO)
	if value == 0:
		p |= STATUS_ZERO
	if (value & 0x80) != 0:
		p |= STATUS_NEGATIVE
	cpu["p"] = p | STATUS_UNUSED
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | STATUS_NEGATIVE | STATUS_ZERO


func _compare(cpu: Dictionary, left: int, right: int) -> void:
	var result := (left - right) & 0xFF
	var p := int(cpu["p"]) & ~STATUS_CARRY
	if left >= right:
		p |= STATUS_CARRY
	cpu["p"] = p
	_set_nz(cpu, result)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | STATUS_CARRY | STATUS_NEGATIVE | STATUS_ZERO


func _adc(cpu: Dictionary, value: int) -> void:
	var a := int(cpu["a"]) & 0xFF
	var carry := 1 if (int(cpu["p"]) & STATUS_CARRY) != 0 else 0
	var total := a + (value & 0xFF) + carry
	var result := total & 0xFF
	var p := int(cpu["p"]) & ~(STATUS_CARRY | STATUS_OVERFLOW)
	if total > 0xFF:
		p |= STATUS_CARRY
	if ((~(a ^ value) & (a ^ result)) & 0x80) != 0:
		p |= STATUS_OVERFLOW
	cpu["p"] = p
	cpu["a"] = result
	_set_nz(cpu, result)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | STATUS_CARRY | STATUS_OVERFLOW | STATUS_NEGATIVE | STATUS_ZERO


func _sbc(cpu: Dictionary, value: int) -> void:
	var a := int(cpu["a"]) & 0xFF
	var operand := value & 0xFF
	var borrow := 0 if (int(cpu["p"]) & STATUS_CARRY) != 0 else 1
	var total := a - operand - borrow
	var result := total & 0xFF
	var p := int(cpu["p"]) & ~(STATUS_CARRY | STATUS_OVERFLOW)
	if total >= 0:
		p |= STATUS_CARRY
	if (((a ^ result) & (a ^ operand)) & 0x80) != 0:
		p |= STATUS_OVERFLOW
	cpu["p"] = p
	cpu["a"] = result
	_set_nz(cpu, result)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | STATUS_CARRY | STATUS_OVERFLOW | STATUS_NEGATIVE | STATUS_ZERO


func _renderer_return_summary(receipt: Dictionary) -> Dictionary:
	var instruction_pcs: Variant = receipt.get("source_instruction_pcs", [])
	var summary := {
		"receipt_id": String(receipt.get("receipt_id", "")),
		"entry_pc": int(receipt.get("entry_pc", -1)),
		"callsite_pc": int(receipt.get("callsite_pc", -1)),
		"return_pc": int(receipt.get("return_pc", -1)),
		"returned_via_rts": bool(receipt.get("returned_via_rts", false)),
		"source_instruction_pcs": instruction_pcs.duplicate() if instruction_pcs is Array else [],
		"source_reads": receipt.get("source_reads", []).duplicate(true),
		"source_writes": receipt.get("source_writes", []).duplicate(true),
		"source_stack_reads": receipt.get("source_stack_reads", []).duplicate(true),
		"source_stack_writes": receipt.get("source_stack_writes", []).duplicate(true),
		"mapper_events": receipt.get("mapper_events", []).duplicate(true),
		"ppu_events": receipt.get("ppu_events", []).duplicate(true),
		"apu_events": receipt.get("apu_events", []).duplicate(true),
		"state_change_count": int(receipt.get("state_change_count", -1)),
	}
	return summary


func _span_prefix_matches(bank: int, address: int, prefix: Array[int]) -> bool:
	var span_bytes := PackedByteArray()
	for span in _rom_spans:
		if int(span["bank"]) == bank and address >= int(span["start"]) \
				and address + prefix.size() <= int(span["end"]):
			span_bytes = (span["bytes"] as PackedByteArray).slice(
				address - int(span["start"]), address - int(span["start"]) + prefix.size())
			break
	return span_bytes == PackedByteArray(prefix)


func _ram_hash(value: Variant) -> String:
	if not value is PackedByteArray:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value)
	return context.finish().hex_encode()


func _stack_hash(value: Variant) -> String:
	return _ram_hash(value)


func _refused(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message,
		"rom_sha256": ROM_SHA256, "source_manifest_sha256": MANIFEST_SHA256,
		"d6c7_reached": false, "trace_state_used": false,
		"emulator_data_used": false, "source_cycle_timing_modeled": false}


func _fail(message: String) -> bool:
	error_message = message
	return false
