extends RefCounted
class_name RomClockTickD193Worker
## Executes the normal fresh-match clock tick from a ROM-produced $D193 entry.
## The source-owned $EF7F renderer dispatch is followed through its real
## $C515->$CB0F yield handoff. Scheduler resume and the later $E1F1 return are
## intentionally left to the caller.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/clock_tick_d193/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const CODE_FILE := "fixed_clock_tick_D193_D299.bin"
const CODE_START := 0xD193
const CODE_END_EXCLUSIVE := 0xD29A
const CODE_LENGTH := CODE_END_EXCLUSIVE - CODE_START
const CODE_SHA256 := "0de1ae062da8a31a6c880faf16b20783941bad266539895c817d1fede1bf9e57"
const RECORD_RESOLVER_FILE := "fixed_record_pointer_resolver_CD7C_CD89.bin"
const RECORD_TABLE_FILE := "fixed_record_pointer_table_CD89_CDB5.bin"
const RECORD_RESOLVER_SHA256 := "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24"
const RECORD_TABLE_SHA256 := "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"
const FIELD_CALLER_FILE := "fixed_field_entry_setup_E0E9_E349.bin"
const FIELD_CALLER_SHA256 := "069aa6c733b9de0a6070e280f89277a4ec192f1c551001fb787e9038244806de"
const BANK18_WORKER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const RAM_SIZE := 0x800
const STACK_PAGE_SIZE := 0x100

const FLAG_C := 0x01
const FLAG_Z := 0x02
const FLAG_U := 0x20
const FLAG_V := 0x40
const FLAG_N := 0x80

var error_message := ""
var _configured := false
var _code := PackedByteArray()
var _record_resolver := PackedByteArray()
var _record_table := PackedByteArray()
var _ram := PackedByteArray()
var _a := 0
var _x := 0
var _y := 0
var _p := FLAG_U
var _p_known_mask := 0xFF
var _sp := 0
var _pc := 0
var _bank_low := 0
var _bank_high := 1
var _mmc3_select := 0
var _writes: Array[Dictionary] = []
var _calls: Array[Dictionary] = []
var _instructions: Array[Dictionary] = []
var _read_dependencies: Dictionary = {}
var _handoff_requested := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_code.clear()
	_record_resolver.clear()
	_record_table.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Clock-tick D193 source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Clock-tick D193 source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fixed-clock-tick-d193-source-v1" \
			or String(manifest.get("rom", {}).get("sha256", "")) != ROM_SHA256:
		return _fail("Clock-tick D193 source manifest targets an unsupported ROM revision/schema.")
	var found_span: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == CODE_FILE:
			found_span = span_variant
			break
	if found_span.is_empty() \
			or String(found_span.get("bank", "")) != "0x1E" \
			or String(found_span.get("cpu_start", "")) != "0xD193" \
			or String(found_span.get("cpu_end_exclusive", "")) != "0xD29A" \
			or String(found_span.get("file_offset", "")) != "0x03D1A3" \
			or int(found_span.get("length", -1)) != CODE_LENGTH \
			or String(found_span.get("sha256", "")) != CODE_SHA256:
		return _fail("Clock-tick D193 span metadata differs from its source contract.")
	_code = FileAccess.get_file_as_bytes(SOURCE_ROOT + CODE_FILE)
	if _code.size() != CODE_LENGTH or _sha256(_code) != CODE_SHA256 \
			or String(found_span.get("bytes", "")).to_lower().replace(" ", "") != _code.hex_encode():
		return _fail("Clock-tick D193 source bytes failed size/hash/manifest validation.")
	var worker := BANK18_WORKER_SCRIPT.new()
	if not bool(worker.configure_from_project_sources()):
		return _fail("Existing ROM renderer/record-pointer sources failed configuration: " \
				+ String(worker.get("error_message")))
	var sources_variant: Variant = worker.get("_sources")
	if not sources_variant is Dictionary:
		return _fail("Existing ROM worker did not expose its configured source map.")
	var sources: Dictionary = sources_variant
	_record_resolver = sources.get(RECORD_RESOLVER_FILE, PackedByteArray())
	_record_table = sources.get(RECORD_TABLE_FILE, PackedByteArray())
	if _record_resolver.size() != 13 or _sha256(_record_resolver) != RECORD_RESOLVER_SHA256 \
			or _record_table.size() != 44 or _sha256(_record_table) != RECORD_TABLE_SHA256:
		return _fail("Existing $CD7C/$CD89 ROM dependencies failed their source hash checks.")
	_configured = true
	return true


## Executes only from the live, source-produced unresolved $D193 boundary.
## `boundary` is the ROM-byte field-worker result, not a checkpoint file or
## emulator state. The $EF7F bank-$18 worker is run until its real $CB0F handoff.
func execute_live_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure the hash-checked D193 and renderer sources before execution.")
		return {}
	if not _validate_live_boundary(boundary):
		return {}
	_load_boundary(boundary)
	var instruction_limit := 1024
	while not _handoff_requested and _instructions.size() < instruction_limit:
		if not _execute_d193_one():
			return _failed_execution_result(boundary)
	if not _handoff_requested:
		_fail("D193 did not reach the source $D1CF->$EF7F renderer call within its instruction bound.")
		return _failed_execution_result(boundary)
	return _run_renderer_to_yield(boundary)


func _validate_live_boundary(boundary: Dictionary) -> bool:
	var registers_variant: Variant = boundary.get("registers", {})
	var mapper_variant: Variant = boundary.get("mapper", {})
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var dispatch_variant: Variant = boundary.get("source_dispatch", {})
	var blocked_variant: Variant = boundary.get("blocked_read", {})
	var calls_variant: Variant = boundary.get("calls", [])
	var instructions_variant: Variant = boundary.get("instructions", [])
	var spans_variant: Variant = boundary.get("executed_source_spans", [])
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not dispatch_variant is Dictionary or not blocked_variant is Dictionary \
			or not calls_variant is Array or not instructions_variant is Array \
			or not spans_variant is Array:
		return _fail("Live D193 boundary omits its registers, mapper, RAM, stack, dispatch proof, or source trace.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var dispatch: Dictionary = dispatch_variant
	var blocked: Dictionary = blocked_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or String(boundary.get("exit_kind", "")) != "unresolved_source_span" \
			or int(boundary.get("exit_pc", -1)) != CODE_START \
			or int(boundary.get("exit_bank", -1)) != 0x1E \
			or int(blocked.get("instruction_pc", -1)) != CODE_START \
			or int(blocked.get("requested_address", -1)) != CODE_START \
			or int(blocked.get("bank", -1)) != 0x1E \
			or int(registers.get("pc", -1)) != CODE_START \
			or int(registers.get("a", -1)) != 0x01 \
			or int(registers.get("x", -1)) != 0x01 \
			or int(registers.get("sp", -1)) != 0x4E \
			or int(mapper.get("bank_low", -1)) < 0 or int(mapper.get("bank_low", -1)) > 0xFF \
			or int(mapper.get("bank_high", -1)) < 0 or int(mapper.get("bank_high", -1)) > 0xFF \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F \
			or int(mapper.get("select", -1)) < 0 or int(mapper.get("select", -1)) > 0x07 \
			or String(dispatch.get("rom_sha256", "")) != ROM_SHA256 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xE14A \
			or int(dispatch.get("bank", -1)) != 0x1F \
			or not bool(dispatch.get("source_dispatch_observed", false)) \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE:
		return _fail("Live D193 boundary is not the supported ordinary-input slot-$05 call entry.")
	if ram.slice(0x0100, 0x0200) != stack:
		return _fail("Live D193 RAM and stack-page snapshots do not match.")
	if int(stack[0x4F]) != 0xF0 or int(stack[0x50]) != 0xE1:
		return _fail("Live D193 stack does not preserve the $E1F0 return word from the $E1EE call.")
	var caller_span_seen := false
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			if String(span.get("file", "")) == FIELD_CALLER_FILE \
					and String(span.get("sha256", "")) == FIELD_CALLER_SHA256:
				caller_span_seen = true
	if not caller_span_seen:
		return _fail("Live D193 boundary omits the hash-checked $E1EE caller span.")
	var caller_call_seen := false
	for call_variant in calls_variant:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) == 0xE1EE \
					and int(call.get("target", -1)) == CODE_START \
					and int(call.get("bank", -1)) == 0x1E \
					and int(call.get("sp_after_push", -1)) == 0x4E:
				caller_call_seen = true
	if not caller_call_seen:
		return _fail("Live D193 boundary does not contain the source $E1EE->$D193 JSR frame.")
	var caller_instruction_seen := false
	for instruction_variant in instructions_variant:
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			if int(instruction.get("pc", -1)) == 0xE1EE \
					and int(instruction.get("opcode", -1)) == 0x20 \
					and int(instruction.get("next_pc", -1)) == CODE_START:
				caller_instruction_seen = true
	if not caller_instruction_seen:
		return _fail("Live D193 boundary omits the executed $E1EE JSR instruction.")
	return true


func _load_boundary(boundary: Dictionary) -> void:
	var ram: PackedByteArray = boundary["ram_image"]
	_ram = ram.duplicate()
	var stack: PackedByteArray = boundary["stack_page"]
	for index in range(STACK_PAGE_SIZE):
		_ram[0x0100 + index] = stack[index]
	var registers: Dictionary = boundary["registers"]
	var mapper: Dictionary = boundary["mapper"]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = (int(registers.get("p", FLAG_U)) | FLAG_U) & 0xFF
	_p_known_mask = (int(registers.get("p_known_mask", 0xFF)) | FLAG_U) & 0xFF
	_sp = int(registers["sp"]) & 0xFF
	_pc = CODE_START
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF
	_writes.clear()
	_calls.clear()
	_instructions.clear()
	_read_dependencies.clear()
	_handoff_requested = false


func _execute_d193_one() -> bool:
	var start_pc := _pc
	var opcode := _read_program_byte(_pc)
	if opcode < 0:
		return false
	var branch_taken: Variant = null
	var branch_displacement := 0
	var operand := _read_program_byte(_pc + 1) if _instruction_length(opcode) >= 2 else 0
	var address := _read_program_word(_pc + 1) if _instruction_length(opcode) == 3 else -1
	if _instruction_length(opcode) >= 2 and operand < 0:
		return false
	if _instruction_length(opcode) == 3 and address < 0:
		return false
	match opcode:
		0x0A: # ASL A
			_set_flag(FLAG_C, (_a & FLAG_N) != 0)
			_a = (_a << 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xAA: # TAX
			_x = _a
			_set_nz(_x)
			_pc += 1
		0x8A: # TXA
			_a = _x
			_set_nz(_a)
			_pc += 1
		0xA8: # TAY
			_y = _a
			_set_nz(_y)
			_pc += 1
		0xA0: # LDY #imm
			_y = operand
			_set_nz(_y)
			_pc += 2
		0xA9: # LDA #imm
			_a = operand
			_set_nz(_a)
			_pc += 2
		0xAD: # LDA abs
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xB9: # LDA abs,Y
			_a = _read_cpu((address + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xAE: # LDX abs
			_x = _read_cpu(address)
			if _x < 0: return false
			_set_nz(_x)
			_pc += 3
		0x8E: # STX abs
			if not _write_cpu(address, _x, start_pc): return false
			_pc += 3
		0x8D: # STA abs
			if not _write_cpu(address, _a, start_pc): return false
			_pc += 3
		0x85: # STA zero page
			if not _write_cpu(operand, _a, start_pc): return false
			_pc += 2
		0x91: # STA (zp),Y
			var target := _indirect_target(operand)
			if target < 0 or not _write_cpu((target + _y) & 0xFFFF, _a, start_pc): return false
			_pc += 2
		0xB1: # LDA (zp),Y
			var target := _indirect_target(operand)
			if target < 0: return false
			_a = _read_cpu((target + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x71: # ADC (zp),Y
			var target := _indirect_target(operand)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_adc(value)
			_pc += 2
		0x18: # CLC
			_set_flag(FLAG_C, false)
			_pc += 1
		0x38: # SEC
			_set_flag(FLAG_C, true)
			_pc += 1
		0x6D: # ADC abs
			var value := _read_cpu(address)
			if value < 0: return false
			_adc(value)
			_pc += 3
		0x69: # ADC #imm
			_adc(operand)
			_pc += 2
		0xE9: # SBC #imm
			_sbc(operand)
			_pc += 2
		0x49: # EOR #imm
			_a = (_a ^ operand) & 0xFF
			_set_nz(_a)
			_pc += 2
		0x0D: # ORA abs
			var value := _read_cpu(address)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 3
		0x29: # AND #imm
			_a &= operand
			_set_nz(_a)
			_pc += 2
		0x2C: # BIT abs
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_N, (value & FLAG_N) != 0)
			_set_flag(FLAG_V, (value & FLAG_V) != 0)
			_set_flag(FLAG_Z, (_a & value) == 0)
			_pc += 3
		0xC9: # CMP #imm
			_compare(_a, operand)
			_pc += 2
		0xEC: # CPX abs
			var value := _read_cpu(address)
			if value < 0: return false
			_compare(_x, value)
			_pc += 3
		0x10, 0x30, 0x90, 0xB0, 0xD0, 0xF0: # branches
			var branch_mask := FLAG_N if opcode in [0x10, 0x30] else \
				FLAG_C if opcode in [0x90, 0xB0] else FLAG_Z
			if (_p_known_mask & branch_mask) != branch_mask:
				return _fail("D193 branch at $%04X depends on an unknown P bit." % start_pc)
			var branch := (opcode == 0x10 and (_p & FLAG_N) == 0) \
				or (opcode == 0x30 and (_p & FLAG_N) != 0) \
				or (opcode == 0x90 and (_p & FLAG_C) == 0) \
				or (opcode == 0xB0 and (_p & FLAG_C) != 0) \
				or (opcode == 0xD0 and (_p & FLAG_Z) == 0) \
			or (opcode == 0xF0 and (_p & FLAG_Z) != 0)
			branch_taken = branch
			var displacement := operand - 0x100 if operand >= 0x80 else operand
			branch_displacement = displacement
			if branch:
				_pc = (_pc + 2 + displacement) & 0xFFFF
			else:
				_pc += 2
		0x48: # PHA
			if not _push(_a, start_pc): return false
			_pc += 1
		0x68: # PLA
			_a = _pop(start_pc)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 1
		0x20: # JSR; EF7F is the explicit asynchronous handoff boundary.
			if address < 0: return false
			var return_minus_one := (_pc + 2) & 0xFFFF
			if not _push((return_minus_one >> 8) & 0xFF, start_pc) \
					or not _push(return_minus_one & 0xFF, start_pc): return false
			_calls.append({"callsite": start_pc, "target": address,
				"bank": _bank_for_cpu(address), "sp_after_push": _sp})
			if address == 0xEF7F and start_pc == 0xD1CF:
				if _a != 0:
					return _fail("D193 renderer handoff did not carry descriptor A=$00.")
				_handoff_requested = true
				_pc = address
			else:
				_pc = address
		0x4C: # JMP abs
			_pc = address
		0x60: # RTS
			var low := _pop(start_pc)
			var high := _pop(start_pc)
			if low < 0 or high < 0: return false
			_pc = (((high << 8) | low) + 1) & 0xFFFF
		_:
			return _fail("Unsupported D193 worker opcode $%02X at $%04X." % [opcode, start_pc])
	_instructions.append({"pc": start_pc, "bank": 0x1E, "opcode": opcode,
		"next_pc": _pc, "a": _a, "x": _x, "y": _y, "p": _p,
		"operand": operand, "branch_displacement": branch_displacement,
		"branch_taken": branch_taken})
	return true


func _run_renderer_to_yield(boundary: Dictionary) -> Dictionary:
	var renderer_worker := BANK18_WORKER_SCRIPT.new()
	if not bool(renderer_worker.configure_from_project_sources()):
		_fail("Renderer worker sources failed configuration: " + String(renderer_worker.get("error_message")))
		return _failed_execution_result(boundary)
	var renderer_ram := _ram.duplicate()
	var renderer_spans: Array = []
	var renderer_calls: Array = []
	var renderer_instructions: Array = []
	var renderer_writes: Array = []
	var renderer_mapper_writes: Array = []
	var renderer_error := ""
	renderer_worker.set("_ram", renderer_ram)
	renderer_worker.set("_a", _a)
	renderer_worker.set("_x", _x)
	renderer_worker.set("_y", _y)
	renderer_worker.set("_p", _p)
	renderer_worker.set("_p_known_mask", _p_known_mask)
	renderer_worker.set("_sp", _sp)
	renderer_worker.set("_pc", 0xEF7F)
	renderer_worker.set("_bank_low", _bank_low)
	renderer_worker.set("_bank_high", _bank_high)
	renderer_worker.set("_mmc3_select", _mmc3_select)
	renderer_worker.call("_reset_execution_trace")
	var instruction_limit := 8192
	var reached_yield_target := false
	for unused in range(instruction_limit):
		var current_pc := int(renderer_worker.get("_pc"))
		if current_pc == 0xCB0F and int(renderer_worker.call("_current_bank_for_pc", current_pc)) == 0x1E:
			reached_yield_target = true
			break
		if not bool(renderer_worker.call("_execute_one")):
			renderer_error = String(renderer_worker.get("error_message"))
			break
	if not reached_yield_target:
		if renderer_error.is_empty():
			renderer_error = "Renderer worker did not reach its source $C515->$CB0F handoff within 8192 instructions."
		_fail(renderer_error)
		return _failed_renderer_result(boundary, renderer_worker)
	var renderer_registers := {
		"a": int(renderer_worker.get("_a")), "x": int(renderer_worker.get("_x")),
		"y": int(renderer_worker.get("_y")), "p": int(renderer_worker.get("_p")),
		"p_known_mask": int(renderer_worker.get("_p_known_mask")),
		"sp": int(renderer_worker.get("_sp")), "pc": 0xCB0F,
	}
	var renderer_mapper := {
		"bank_low": int(renderer_worker.get("_bank_low")),
		"bank_high": int(renderer_worker.get("_bank_high")),
		"select": int(renderer_worker.get("_mmc3_select")),
		"fixed_low": 0x1E, "fixed_high": 0x1F,
	}
	var renderer_out_ram: PackedByteArray = renderer_worker.get("_ram")
	renderer_calls = renderer_worker.get("_calls").duplicate(true)
	renderer_instructions = renderer_worker.get("_instructions").duplicate(true)
	renderer_writes = renderer_worker.get("_writes").duplicate(true)
	renderer_mapper_writes = renderer_worker.get("_mapper_writes").duplicate(true)
	renderer_spans = renderer_worker.call("_executed_source_span_records")
	var prefix_calls: Array = boundary.get("calls", [])
	var all_calls: Array = prefix_calls.duplicate(true)
	all_calls.append_array(_calls.duplicate(true))
	all_calls.append_array(renderer_calls)
	var prefix_instructions: Array = boundary.get("instructions", [])
	var all_instructions: Array = prefix_instructions.duplicate(true)
	all_instructions.append_array(_instructions.duplicate(true))
	all_instructions.append_array(renderer_instructions)
	var prefix_writes: Array = boundary.get("writes", [])
	var all_writes: Array = prefix_writes.duplicate(true)
	all_writes.append_array(_writes.duplicate(true))
	all_writes.append_array(renderer_writes)
	var all_mapper_writes: Array[Dictionary] = []
	var prefix_mapper_writes: Array = boundary.get("mapper_writes", [])
	for mapper_write_variant in prefix_mapper_writes:
		if mapper_write_variant is Dictionary:
			all_mapper_writes.append((mapper_write_variant as Dictionary).duplicate(true))
	all_mapper_writes.append_array(renderer_mapper_writes)
	var prefix_spans: Array = boundary.get("executed_source_spans", [])
	var all_spans: Array = []
	for span_variant in prefix_spans:
		if span_variant is Dictionary:
			all_spans.append((span_variant as Dictionary).duplicate(true))
	all_spans.append_array(_executed_d193_span_records())
	all_spans.append_array(_executed_dependency_span_records())
	all_spans.append_array(renderer_spans)
	var yield_callsite := _callsite_for_target(all_calls, 0xC515)
	if yield_callsite < 0 or not _instruction_seen(renderer_instructions, 0xC515, 0x4C, 0xCB0F):
		_fail("Renderer worker reached $CB0F without the source $C515 yield-trampoline jump proof.")
		return _failed_renderer_result(boundary, renderer_worker)
	var incoming_dispatch: Dictionary = boundary.get("source_dispatch", {})
	var entry_state := {"a": int(boundary["registers"].get("a", -1)),
		"x": int(boundary["registers"].get("x", -1)),
		"y": int(boundary["registers"].get("y", -1)),
		"p": int(boundary["registers"].get("p", -1)),
		"sp": int(boundary["registers"].get("sp", -1)),
		"pc": CODE_START, "bank": 0x1E}
	var entry_ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	var clock_before := {"$05F7": int(entry_ram[0x05F7]),
		"$05F8": int(entry_ram[0x05F8]), "$05FF": int(entry_ram[0x05FF])}
	var clock_after := {"$05F7": int(renderer_out_ram[0x05F7]),
		"$05F8": int(renderer_out_ram[0x05F8]), "$05FF": int(renderer_out_ram[0x05FF])}
	var caller_return_preserved := int(renderer_out_ram[0x014F]) == 0xF0 \
		and int(renderer_out_ram[0x0150]) == 0xE1
	if not caller_return_preserved:
		_fail("Renderer yield overwrote the original $E1F0 D193 caller return word.")
		return _failed_renderer_result(boundary, renderer_worker)
	return {
		"ok": true,
		"status": "ef7f_async_task_yield",
		"exit_kind": "source_handoff_at_cb0f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"entry": entry_state,
		"exit_pc": 0xCB0F,
		"exit_bank": 0x1E,
		"registers": renderer_registers,
		"mapper": renderer_mapper,
		"ram_image": renderer_out_ram.duplicate(),
		"stack_page": renderer_out_ram.slice(0x0100, 0x0200),
		"writes": all_writes,
		"mapper_writes": all_mapper_writes,
		"calls": all_calls,
		"instructions": all_instructions,
		"executed_source_spans": all_spans,
		"source_dispatch": incoming_dispatch.duplicate(true),
		"source_boundary": boundary.duplicate(true),
		"source_write_counts": {
			"field_e14a_to_d193": prefix_writes.size(),
			"d193_to_ef7f": _writes.size(),
			"renderer_to_cb0f": renderer_writes.size(),
		},
		"clock_before": clock_before,
		"clock_after": clock_after,
		"handoff": {
			"kind": "async_renderer_worker_task_yield",
			"renderer_callsite": 0xD1CF,
			"renderer_entry_pc": 0xEF7F,
			"renderer_return_pc": 0xD1D2,
			"worker_callsite": 0xEF96,
			"worker_entry_pc": 0x800C,
			"yield_jsr_callsite": yield_callsite,
			"yield_trampoline_pc": 0xC515,
			"yield_target_pc": 0xCB0F,
			"yield_target_bank": 0x1E,
			"d193_resume_pc_after_renderer": 0xD1D2,
			"outer_caller_return_pc": 0xE1F1,
			"callee_rts_observed": false,
			"outer_caller_return_word_preserved": true,
		},
		"runtime_integrated": false,
		"scheduler_resume_required": true,
	}


func _failed_execution_result(boundary: Dictionary) -> Dictionary:
	return {"ok": false, "status": "d193_source_execution_failed", "error": error_message,
		"rom_sha256": ROM_SHA256, "entry_pc": CODE_START,
		"exit_pc": _pc, "exit_bank": _bank_for_cpu(_pc),
		"registers": _current_registers(), "mapper": _current_mapper(),
		"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true), "calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"source_dispatch": boundary.get("source_dispatch", {}).duplicate(true)}


func _failed_renderer_result(boundary: Dictionary, renderer_worker: Object) -> Dictionary:
	var failed_ram: PackedByteArray = renderer_worker.get("_ram")
	var calls: Array = _calls.duplicate(true)
	calls.append_array(renderer_worker.get("_calls").duplicate(true))
	var instructions: Array = _instructions.duplicate(true)
	instructions.append_array(renderer_worker.get("_instructions").duplicate(true))
	var writes: Array = _writes.duplicate(true)
	writes.append_array(renderer_worker.get("_writes").duplicate(true))
	return {"ok": false, "status": "renderer_worker_did_not_reach_yield", "error": error_message,
		"rom_sha256": ROM_SHA256, "entry_pc": CODE_START,
		"exit_pc": int(renderer_worker.get("_pc")),
		"exit_bank": int(renderer_worker.call("_current_bank_for_pc", int(renderer_worker.get("_pc")))),
		"registers": {"a": int(renderer_worker.get("_a")), "x": int(renderer_worker.get("_x")),
			"y": int(renderer_worker.get("_y")), "p": int(renderer_worker.get("_p")),
			"p_known_mask": int(renderer_worker.get("_p_known_mask")),
			"sp": int(renderer_worker.get("_sp")), "pc": int(renderer_worker.get("_pc"))},
		"mapper": {"bank_low": int(renderer_worker.get("_bank_low")),
			"bank_high": int(renderer_worker.get("_bank_high")),
			"select": int(renderer_worker.get("_mmc3_select"))},
		"ram_image": failed_ram.duplicate(), "stack_page": failed_ram.slice(0x0100, 0x0200),
		"writes": writes, "calls": calls, "instructions": instructions,
		"source_dispatch": boundary.get("source_dispatch", {}).duplicate(true),
		"blocked_read": renderer_worker.get("_blocked_read").duplicate(true),
		"unsupported_opcode": renderer_worker.get("_unsupported_opcode").duplicate(true)}


func _read_program_byte(address: int) -> int:
	if address >= CODE_START and address < CODE_END_EXCLUSIVE:
		return int(_code[address - CODE_START])
	if address >= 0xCD7C and address < 0xCD89:
		_read_dependencies["record_resolver"] = true
		return int(_record_resolver[address - 0xCD7C])
	if address >= 0xCD89 and address < 0xCDB5:
		_read_dependencies["record_table"] = true
		return int(_record_table[address - 0xCD89])
	_fail("D193 program read $%04X outside the preserved tick/helper spans at PC $%04X." % [address, _pc])
	return -1


func _read_program_word(address: int) -> int:
	var low := _read_program_byte(address)
	var high := _read_program_byte(address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _read_cpu(address: int) -> int:
	if address >= 0 and address < 0x2000:
		return int(_ram[address & 0x07FF])
	if address >= 0xCD7C and address < 0xCDB5:
		return _read_program_byte(address)
	_fail("D193 data read $%04X is outside its 2 KiB RAM/source-table contract." % address)
	return -1


func _write_cpu(address: int, value: int, source_pc: int) -> bool:
	if address < 0 or address >= 0x2000:
		return _fail("D193 write $%04X=$%02X is outside its RAM-only clock path." % [address, value & 0xFF])
	var target := address & 0x07FF
	_ram[target] = value & 0xFF
	_writes.append({"pc": source_pc, "bank": 0x1E, "address": target, "value": value & 0xFF})
	return true


func _indirect_target(zero_page_address: int) -> int:
	if zero_page_address < 0 or zero_page_address > 0xFF:
		return -1
	return int(_ram[zero_page_address]) | (int(_ram[(zero_page_address + 1) & 0xFF]) << 8)


func _push(value: int, source_pc: int) -> bool:
	if not _write_cpu(0x0100 | _sp, value, source_pc):
		return false
	_sp = (_sp - 1) & 0xFF
	return true


func _pop(source_pc: int) -> int:
	_sp = (_sp + 1) & 0xFF
	return _read_cpu(0x0100 | _sp)


func _adc(value: int) -> void:
	var before := _a
	var sum := before + value + (1 if (_p & FLAG_C) != 0 else 0)
	var result := sum & 0xFF
	_set_flag(FLAG_C, sum > 0xFF)
	_set_flag(FLAG_V, ((~(before ^ value) & (before ^ result)) & 0x80) != 0)
	_a = result
	_set_nz(_a)


func _sbc(value: int) -> void:
	var before := _a
	var difference := before - value - (0 if (_p & FLAG_C) != 0 else 1)
	var result := difference & 0xFF
	_set_flag(FLAG_C, difference >= 0)
	_set_flag(FLAG_V, (((before ^ result) & (before ^ value)) & 0x80) != 0)
	_a = result
	_set_nz(_a)


func _compare(register_value: int, value: int) -> void:
	var difference := (register_value & 0xFF) - (value & 0xFF)
	_set_flag(FLAG_C, difference >= 0)
	_set_nz(difference & 0xFF)


func _set_nz(value: int) -> void:
	_set_flag(FLAG_Z, (value & 0xFF) == 0)
	_set_flag(FLAG_N, (value & FLAG_N) != 0)


func _set_flag(mask: int, enabled: bool) -> void:
	if enabled:
		_p |= mask
	else:
		_p &= ~mask
	_p |= FLAG_U
	_p_known_mask |= mask | FLAG_U


func _instruction_length(opcode: int) -> int:
	match opcode:
		0x0A, 0x18, 0x38, 0x48, 0x60, 0x68, 0x8A, 0xAA, 0xA8:
			return 1
		0x10, 0x30, 0x49, 0x69, 0xE9, 0x29, 0x85, 0xA0, 0xA9, 0x71, 0x91, 0xB1, 0x90, 0xB0, 0xD0, 0xF0:
			return 2
		0x0D, 0x20, 0x2C, 0x4C, 0x6D, 0x8D, 0x8E, 0xAD, 0xAE, 0xB9, 0xC9, 0xEC:
			return 3
		_:
			return 0


func _current_registers() -> Dictionary:
	return {"a": _a, "x": _x, "y": _y, "p": _p,
		"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc}


func _current_mapper() -> Dictionary:
	return {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
		"fixed_low": 0x1E, "fixed_high": 0x1F}


func _bank_for_cpu(address: int) -> int:
	if address >= 0xC000 and address < 0xE000:
		return 0x1E
	if address >= 0xE000:
		return 0x1F
	if address >= 0xA000 and address < 0xC000:
		return _bank_high
	return _bank_low


func _executed_d193_span_records() -> Array[Dictionary]:
	return [{"file": CODE_FILE, "bank": 0x1E, "cpu_start": CODE_START,
		"cpu_end_exclusive": CODE_END_EXCLUSIVE, "file_offset": "0x03D1A3",
		"length": CODE_LENGTH, "sha256": CODE_SHA256}]


func _executed_dependency_span_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _read_dependencies.has("record_resolver"):
		result.append({"file": RECORD_RESOLVER_FILE, "bank": 0x1E,
			"cpu_start": 0xCD7C, "cpu_end_exclusive": 0xCD89,
			"file_offset": "0x03CD8C", "length": 13, "sha256": RECORD_RESOLVER_SHA256})
	if _read_dependencies.has("record_table"):
		result.append({"file": RECORD_TABLE_FILE, "bank": 0x1E,
			"cpu_start": 0xCD89, "cpu_end_exclusive": 0xCDB5,
			"file_offset": "0x03CD99", "length": 44, "sha256": RECORD_TABLE_SHA256})
	return result


func _callsite_for_target(calls: Array, target: int) -> int:
	for call_variant in calls:
		if call_variant is Dictionary and int(call_variant.get("target", -1)) == target:
			return int(call_variant.get("callsite", -1))
	return -1


func _instruction_seen(instructions: Array, pc: int, opcode: int, next_pc: int) -> bool:
	for instruction_variant in instructions:
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			if int(instruction.get("pc", -1)) == pc \
					and int(instruction.get("opcode", -1)) == opcode \
					and int(instruction.get("next_pc", -1)) == next_pc:
				return true
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _manifest_sha256() -> String:
	return FileAccess.get_sha256(MANIFEST_PATH)


func _fail(message: String) -> bool:
	error_message = message
	return false
