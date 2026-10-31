extends RefCounted
class_name RomFreshDaaaContinuation
## Byte-bounded 6502 continuation for the source-owned fresh slot-$05 task.
## Executes the synchronous match-zero dispatch and the scenario-$35 A/B wait
## exit through the checked $DC07 call request. It does not model asynchronous
## worker yields, NMI cadence, or the called position initializer here.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const RAM_SIZE := 0x800
const END_PC := 0x800C
const END_BANK := 0x18
const SOURCE_FILES := {
	"fixed_reset_ram_clear_C64E_C679.bin": {"bank": 0x1E, "start": 0xC64E, "end": 0xC67A},
	"fixed_daaa_to_first_bank18_entry_DAAA_DACC.bin": {"bank": 0x1E, "start": 0xDAAA, "end": 0xDACC},
	"fixed_scenario_wait_DADD_DAE9.bin": {"bank": 0x1E, "start": 0xDADD, "end": 0xDAE9},
	"fixed_scenario_input_exit_DAE9_DAF2.bin": {"bank": 0x1E, "start": 0xDAE9, "end": 0xDAF2},
	"fixed_position_initializer_call_DAF2_DAF5.bin": {"bank": 0x1E, "start": 0xDAF2, "end": 0xDAF5},
	"fixed_sound_queue_CBF1_CC01.bin": {"bank": 0x1E, "start": 0xCBF1, "end": 0xCC02},
	"fixed_branch_dispatch_DB24_DB62.bin": {"bank": 0x1E, "start": 0xDB24, "end": 0xDB62},
	"fixed_bank18_wrapper_EF7F_EF99.bin": {"bank": 0x1F, "start": 0xEF7F, "end": 0xEF99},
	"fixed_record_pointer_stub_C50C_C50F.bin": {"bank": 0x1E, "start": 0xC50C, "end": 0xC50F},
	"fixed_record_reset_CF4F_CF71.bin": {"bank": 0x1E, "start": 0xCF4F, "end": 0xCF72},
	"fixed_record_pointer_CD7C_CD88.bin": {"bank": 0x1E, "start": 0xCD7C, "end": 0xCD89},
	"fixed_record_pointer_table_CD89_CDB4.bin": {"bank": 0x1E, "start": 0xCD89, "end": 0xCDB5},
	"fixed_mapper_helper_CE2D_CE49.bin": {"bank": 0x1E, "start": 0xCE2D, "end": 0xCE4A},
	"bank1a_map_setup_8039_803B.bin": {"bank": 0x1A, "start": 0x8039, "end": 0x803C},
	"bank1a_fresh_gate_904E_906F.bin": {"bank": 0x1A, "start": 0x904E, "end": 0x9070},
	"bank1c_dispatch_trampoline_8003_8005.bin": {"bank": 0x1C, "start": 0x8003, "end": 0x8006},
	"bank1c_fresh_opponent_setup_8B22_8B93.bin": {"bank": 0x1C, "start": 0x8B22, "end": 0x8B94},
	"bank1d_opponent_pointer_entry_0_BAB2_BAB3.bin": {"bank": 0x1D, "start": 0xBAB2, "end": 0xBAB4},
	"bank1d_opponent_3_header_BAF6_BAFF.bin": {"bank": 0x1D, "start": 0xBAF6, "end": 0xBB00},
	"fixed_branch_table_dispatch_CB99_CBAF.bin": {"bank": 0x1E, "start": 0xCB99, "end": 0xCBB0},
}

const FLAG_C := 0x01
const FLAG_Z := 0x02
const FLAG_I := 0x04
const FLAG_D := 0x08
const FLAG_B := 0x10
const FLAG_U := 0x20
const FLAG_V := 0x40
const FLAG_N := 0x80

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _ram := PackedByteArray()
var _a := 0
var _x := 0
var _y := 0
var _p := FLAG_U
var _sp := 0
var _pc := 0
var _entry_pc := 0
var _write_trace_pc := 0
var _bank_low := 0
var _bank_high := 1
var _mmc3_select := 0
var _writes: Array[Dictionary] = []
var _mapper_writes: Array[Dictionary] = []
var _calls: Array[Dictionary] = []
var _instructions: Array[Dictionary] = []


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Fresh $DAAA source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Fresh $DAAA source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-daaa-continuation-source-v2" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Fresh $DAAA package targets an unsupported ROM/schema.")
	var by_file: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			by_file[String(span.get("file", ""))] = span
	for file_name: String in SOURCE_FILES:
		if not by_file.has(file_name):
			return _fail("Fresh $DAAA manifest omits %s." % file_name)
		var spec: Dictionary = SOURCE_FILES[file_name]
		var entry: Dictionary = by_file[file_name]
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
		if bytes.size() != int(spec["end"]) - int(spec["start"]) \
				or _sha256(bytes) != String(entry.get("sha256", "")) \
				or String(entry.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(entry.get("bank", "")) != "0x%02X" % int(spec["bank"]) \
				or String(entry.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Fresh $DAAA ROM span failed provenance/size/hash validation: %s." % file_name)
		_sources[file_name] = bytes
	if not _verify_boundaries():
		return false
	_configured = true
	return true


## Executes ROM bytes from the source-owned $DAAA task result through the
## first $EF7F wrapper's bank-$18:$800C call. The input must carry the
## scheduler dispatch that supplied the task's real entry registers and stack.
func execute_synchronous_prefix(period_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked $DAAA sources before execution.")
		return {}
	if not _validate_period_result(period_result):
		return {}
	_reset_from_period_result(period_result)
	return _execute_to_worker_entry()


## Continues from the live `$CBC1 RTS->$DADD` return after the scenario-$35
## queue. It preserves caller state and executes the ROM's `LDA #$01` through
## the `$DADF` callsite; the scheduler owns the `$CB0F` task-yield routine.
func execute_after_scenario_return(return_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked $DAAA sources before execution.")
		return {}
	var entry: Dictionary = return_result.get("entry", {})
	var registers: Dictionary = return_result.get("registers", {})
	var mapper: Dictionary = return_result.get("mapper", {})
	var ram: Variant = return_result.get("ram_image", PackedByteArray())
	var stack: Variant = return_result.get("stack_page", PackedByteArray())
	var call_contract: Dictionary = return_result.get("call_contract", {})
	var caller_request: Dictionary = call_contract.get("caller_request", {})
	if not bool(return_result.get("ok", false)) \
			or String(return_result.get("status", "")) != "returned_to_source_caller" \
			or String(return_result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json" \
			or int(entry.get("slot_base", -1)) != 0x05 \
			or int(entry.get("call_pc", -1)) != 0xCBC1 \
			or int(entry.get("expected_return_pc", -1)) != 0xDADD \
			or int(registers.get("pc", -1)) != 0xDADD \
			or int(registers.get("sp", -1)) != 0x50 \
			or int(caller_request.get("return_word", -1)) != 0xDADC \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != 0x100 \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D:
		_fail("Input is not the live ROM-derived `$CBC1->$DADD` continuation.")
		return {}
	_reset_from_scenario_return(return_result)
	var instruction_limit := 16
	while _pc != 0xDADF and _instructions.size() < instruction_limit:
		if not _execute_one():
			return {}
	if _pc != 0xDADF:
		_fail("Scenario-$35 caller did not reach the checked `$DADF->$CB0F` yield callsite.")
		return {}
	return {
		"ok": true,
		"status": "scenario35_wait_yield_callsite_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": _entry_pc,
		"exit_pc": _pc,
		"exit_sp": _sp,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "register_select": _mmc3_select},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"call_request": {"callsite_pc": 0xDADF, "target_pc": 0xCB0F,
			"return_pc": 0xDAE2, "return_minus_one": 0xDAE1},
		"scope": "ROM-byte scenario caller prefix to its scheduler yield callsite",
	}


## Replays the live `$DAE2` wait test after the scheduler's real RTS dispatch.
## A zero `$001C & $C0` result repeats the source yield at `$DADF`. A set bit
## executes the ROM branch that assigns `$0441 = $05FB + 8`, then stops before
## the verified `$DAF2 JSR $DC07` so the position initializer remains a caller.
func execute_scenario35_wait_resume(dispatch: Dictionary, boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked scenario sources before resuming the wait loop.")
		return {}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if not bool(dispatch.get("ok", false)) \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or int(dispatch.get("pc", -1)) != 0xDAE2 \
			or int(dispatch.get("sp", -1)) != 0x50 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("bank_low", -1)) != 0x1C \
			or int(dispatch.get("bank_high", -1)) != 0x1D \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xDAE2 \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != 0x100 \
			or ram.slice(0x0100, 0x0200) != stack:
		_fail("Scenario-$35 wait resume requires the live slot-$05 `$DAE2` dispatch RAM/stack boundary.")
		return {}
	_reset_from_scenario_wait_dispatch(dispatch, boundary)
	var instruction_limit := 8
	while _pc != 0xDADF and _pc != 0xDAE9 and _instructions.size() < instruction_limit:
		if not _execute_one():
			return {}
	if _pc not in [0xDADF, 0xDAE9]:
		_fail("Scenario-$35 wait test did not reach `$DADF` or the checked `$DAE9` input exit.")
		return {}
	var wait_condition_set := _pc == 0xDAE9
	var call_request: Dictionary = {}
	if wait_condition_set:
		while _pc != 0xDAF2 and _instructions.size() < instruction_limit:
			if not _execute_one():
				return {}
		if _pc != 0xDAF2:
			_fail("Set-input scenario wait path did not reach `$DAF2` within the bounded ROM span.")
			return {}
		var call_bytes: PackedByteArray = _sources["fixed_position_initializer_call_DAF2_DAF5.bin"]
		if call_bytes.size() != 3 or int(call_bytes[0]) != 0x20:
			_fail("The `$DAF2` source instruction is not a three-byte JSR.")
			return {}
		var target_pc := int(call_bytes[1]) | (int(call_bytes[2]) << 8)
		if target_pc != 0xDC07:
			_fail("The `$DAF2` ROM call no longer targets position initializer `$DC07`.")
			return {}
		call_request = {
			"kind": "rom_jsr_request",
			"source_pc": 0xDAF2,
			"target_pc": target_pc,
			"return_pc": 0xDAF5,
			"return_minus_one": 0xDAF4,
			"source_bytes": call_bytes.duplicate(),
		}
	return {
		"ok": true,
		"status": "scenario35_input_exit_dc07_callsite_ready" if wait_condition_set else "scenario35_wait_yield_callsite_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": 0xDAE2,
		"exit_pc": _pc,
		"exit_sp": _sp,
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "register_select": _mmc3_select},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"wait_flags": int(_ram[0x001C]) & 0xC0,
		"input_exit_taken": wait_condition_set,
		"ball_holder_slot_0441": int(_ram[0x0441]) if wait_condition_set else -1,
		"position_initializer_call_request": call_request,
		"scope": "ROM-byte scenario-$35 wait loop through its zero-input scheduler yield or set-input `$DAF2->$DC07` call request; `$DC07` is not executed here",
	}


func _execute_to_worker_entry() -> Dictionary:
	var instruction_limit := 4096
	while not _at_end_boundary() and _instructions.size() < instruction_limit:
		if not _execute_one():
			return {}
	if not _at_end_boundary():
		_fail("Synchronous $DAAA continuation did not reach bank-$18:$800C within its bound.")
		return {}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": _entry_pc,
		"exit_pc": _pc,
		"exit_sp": _sp,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p, "sp": _sp, "pc": _pc},
		"stack_top_sp_plus_1_to_8": _bytes_hex(0x0100 | ((_sp + 1) & 0xFF), 8),
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram": _selected_ram_state(),
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"source_context": {"entry_pc": _entry_pc, "entry_bank": _current_bank_for_pc(_entry_pc)},
		"scope": "ROM-byte continuation to the first bank-$18:$800C worker entry",
		"next_source_call": {"pc": 0x800C, "bank": 0x18, "target": 0x8851},
		"runtime_integrated": false,
		"precondition_gaps": ["The earlier route has not yet been source-executed to prove every reset-zero RAM byte remains unchanged at $DAAA.", "The bank-$18 worker yield at $8886/$C515 and its task/NMI continuation are outside this synchronous component."],
	}


func _at_end_boundary() -> bool:
	return _pc == END_PC and _current_bank_for_pc(_pc) == END_BANK


func _validate_period_result(period_result: Dictionary) -> bool:
	if not bool(period_result.get("ok", false)) \
			or String(period_result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(period_result.get("exit_pc", -1)) != 0xDAAA \
			or int(period_result.get("exit_sp", -1)) != 0x50:
		return _fail("Continuation requires the verified source-owned $DAAA result from RomFreshPeriodTask.")
	var dispatch_variant: Variant = period_result.get("scheduler_dispatch", {})
	if not dispatch_variant is Dictionary:
		return _fail("$DAAA continuation requires its ROM-derived scheduler dispatch context.")
	var dispatch: Dictionary = dispatch_variant
	var source_context_variant: Variant = period_result.get("source_context", {})
	var source_context: Dictionary = source_context_variant if source_context_variant is Dictionary else {}
	var resumed_after_scenario := String(source_context.get("source_event", "")) \
		== "ROM-byte slot-$05 `$CBC1 RTS->$D11E` live continuation"
	var expected_entry_sp := 0x50 if resumed_after_scenario else 0x52
	var expected_bank_low := 0x1C if resumed_after_scenario else 0x00
	var expected_bank_high := 0x1D if resumed_after_scenario else 0x01
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("slot_base", -1)) != 0x05 \
			or int(dispatch.get("pc", -1)) != 0xD11E or int(dispatch.get("sp", -1)) != expected_entry_sp \
			or int(dispatch.get("source_return_word", -1)) != 0xD11D \
			or int(dispatch.get("bank_low", -1)) != expected_bank_low \
			or int(dispatch.get("bank_high", -1)) != expected_bank_high:
		return _fail("The scheduler dispatch is not the checked fresh slot-$05 source state.")
	var registers_variant: Variant = period_result.get("registers", {})
	if not registers_variant is Dictionary:
		return _fail("$DAAA continuation lacks the task's source-derived CPU registers.")
	var registers: Dictionary = registers_variant
	for key: String in ["a", "x", "sp", "pc"]:
		if not registers.has(key):
			return _fail("$DAAA task result omits register %s." % key)
	if int(registers["pc"]) != 0xDAAA or int(registers["sp"]) != 0x50:
		return _fail("$DAAA task result registers disagree with the bounded source handoff.")
	if not source_context_variant is Dictionary \
			or String(source_context.get("kind", "")) != "caller_owned_decoded_game_logic":
		return _fail("$DAAA continuation requires named decoded-game-logic context, not trace state.")
	if resumed_after_scenario and not period_result.get("ram_image", PackedByteArray()) is PackedByteArray:
		return _fail("Resumed `$DAAA` continuation requires its source-derived live RAM image.")
	return true


func _reset_from_period_result(period_result: Dictionary) -> void:
	_ram.resize(RAM_SIZE)
	var source_ram: Variant = period_result.get("ram_image", PackedByteArray())
	if source_ram is PackedByteArray and source_ram.size() == RAM_SIZE:
		_ram = source_ram.duplicate()
	else:
		_ram.fill(0) # Initial route baseline; earlier pre-$DAAA writes are not part of this slice.
	_writes.clear()
	_mapper_writes.clear()
	_calls.clear()
	_instructions.clear()
	for write_variant in period_result.get("writes", []):
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		if address >= 0 and address < RAM_SIZE:
			_ram[address] = int(write.get("value", 0)) & 0xFF
	var input_ram: Dictionary = period_result.get("ram", {})
	_ram[0x0027] = int(input_ram.get("$0027", 0)) & 0xFF
	_ram[0x002B] = int(input_ram.get("$002B", 0)) & 0xFF
	var regs: Dictionary = period_result["registers"]
	var dispatch: Dictionary = period_result["scheduler_dispatch"]
	_a = int(regs["a"]) & 0xFF
	_x = int(regs["x"]) & 0xFF
	_y = int(regs.get("y", dispatch.get("y", 0))) & 0xFF
	_p = int(regs.get("p", FLAG_U)) & 0xFF
	_p |= FLAG_U
	_sp = int(regs["sp"]) & 0xFF
	_pc = 0xDAAA
	_entry_pc = 0xDAAA
	_bank_low = int(dispatch["bank_low"]) & 0xFF
	_bank_high = int(dispatch["bank_high"]) & 0xFF
	_mmc3_select = int(dispatch.get("mapper_select", 0x07)) & 0x07
	# The bootstrap's preserved slot-$05 return word is installed by the ROM
	# scheduler seed and remains below SP after RomFreshPeriodTask executes TXS.
	var return_bytes: Array = dispatch.get("source_return_bytes", [])
	if return_bytes.size() == 2:
		_ram[0x0151] = int(return_bytes[0]) & 0xFF
		_ram[0x0152] = int(return_bytes[1]) & 0xFF
	if not source_ram is PackedByteArray or source_ram.size() != RAM_SIZE:
		_ram[0x0024] = _bank_low
		_ram[0x0025] = _bank_high


func _reset_from_scenario_return(return_result: Dictionary) -> void:
	_ram = (return_result["ram_image"] as PackedByteArray).duplicate()
	_writes.clear()
	_mapper_writes.clear()
	_calls.clear()
	_instructions.clear()
	var registers: Dictionary = return_result["registers"]
	var mapper: Dictionary = return_result["mapper"]
	_a = int(registers.get("a", 0)) & 0xFF
	_x = int(registers.get("x", 0)) & 0xFF
	_y = int(registers.get("y", 0)) & 0xFF
	_p = int(registers.get("p", FLAG_U)) | FLAG_U
	_sp = int(registers["sp"]) & 0xFF
	_pc = 0xDADD
	_entry_pc = _pc
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper.get("register_select", 0x07)) & 0x07


func _reset_from_scenario_wait_dispatch(dispatch: Dictionary, boundary: Dictionary) -> void:
	_ram = (boundary["ram_image"] as PackedByteArray).duplicate()
	_writes.clear()
	_mapper_writes.clear()
	_calls.clear()
	_instructions.clear()
	_a = int(dispatch.get("a", 0)) & 0xFF
	_x = int(dispatch.get("x", 0)) & 0xFF
	_y = int(dispatch.get("y", 0)) & 0xFF
	_p = int(boundary.get("p", FLAG_U)) | FLAG_U
	_sp = int(dispatch.get("sp", 0)) & 0xFF
	_pc = 0xDAE2
	_entry_pc = _pc
	_bank_low = int(dispatch.get("bank_low", 0)) & 0xFF
	_bank_high = int(dispatch.get("bank_high", 1)) & 0xFF
	_mmc3_select = int((boundary.get("mapper", {}) as Dictionary).get("select", 0x07)) & 0x07


func _execute_one() -> bool:
	var start_pc := _pc
	var start_bank := _current_bank_for_pc(_pc)
	var opcode := _read_cpu(_pc)
	if opcode < 0:
		return false
	_write_trace_pc = (_pc + _opcode_length(opcode)) & 0xFFFF
	match opcode:
		0x01: # ORA (zero page,X)
			var zero_page_pointer := (_read_cpu(_pc + 1) + _x) & 0xFF
			if _pc + 1 > 0xFFFF:
				return _fail("ORA indexed-indirect operand escaped address space.")
			var target_low := _read_cpu(zero_page_pointer)
			var target_high := _read_cpu((zero_page_pointer + 1) & 0xFF)
			if target_low < 0 or target_high < 0:
				return false
			var target := target_low | (target_high << 8)
			var value := _read_cpu(target)
			if value < 0:
				return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0xA2: # LDX #imm
			_x = _read_cpu(_pc + 1)
			_set_nz(_x)
			_pc += 2
		0xBC: # LDY abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_y = _read_cpu((address + _x) & 0xFFFF)
			if _y < 0: return false
			_set_nz(_y)
			_pc += 3
		0xF0, 0xD0, 0x10: # BEQ, BNE, BPL
			var displacement := _read_cpu(_pc + 1)
			if displacement < 0: return false
			if displacement >= 0x80: displacement -= 0x100
			var take := (opcode == 0xF0 and (_p & FLAG_Z) != 0) \
					or (opcode == 0xD0 and (_p & FLAG_Z) == 0) \
					or (opcode == 0x10 and (_p & FLAG_N) == 0)
			_pc = _pc + 2 + displacement if take else _pc + 2
		0xE8: # INX
			_x = (_x + 1) & 0xFF
			_set_nz(_x)
			_pc += 1
		0xC8: # INY
			_y = (_y + 1) & 0xFF
			_set_nz(_y)
			_pc += 1
		0xE0: # CPX #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_x, value)
			_pc += 2
		0x9D: # STA abs,X
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu((address + _x) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 3
		0xA9: # LDA #imm
			_a = _read_cpu(_pc + 1)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x48: # PHA
			_write_trace_pc = (_pc + 1) & 0xFFFF
			if not _push(_a, start_pc, start_bank): return false
			_pc += 1
		0x20: # JSR
			_write_trace_pc = (_pc + 2) & 0xFFFF
			var target := _read_word(_pc + 1)
			if target < 0: return false
			var return_minus_one := (_pc + 2) & 0xFFFF
			if not _push((return_minus_one >> 8) & 0xFF, start_pc, start_bank) \
					or not _push(return_minus_one & 0xFF, start_pc, start_bank): return false
			_calls.append({"callsite": start_pc, "target": target, "bank": _current_bank_for_pc(target), "sp_after_push": _sp})
			_pc = target
		0x60: # RTS
			var low := _pop()
			var high := _pop()
			if low < 0 or high < 0: return false
			_pc = (((high << 8) | low) + 1) & 0xFFFF
		0xA0: # LDY #imm
			_y = _read_cpu(_pc + 1)
			if _y < 0: return false
			_set_nz(_y)
			_pc += 2
		0x0A: # ASL A
			_set_flag(FLAG_C, (_a & 0x80) != 0)
			_a = (_a << 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xA8: # TAY
			_y = _a
			_set_nz(_y)
			_pc += 1
		0x98: # TYA
			_a = _y
			_set_nz(_a)
			_pc += 1
		0xB9: # LDA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0x85: # STA zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 2
		0x91: # STA (zp),Y
			var zp := _read_cpu(_pc + 1)
			if zp < 0: return false
			var address := _read_cpu(zp) | (_read_cpu((zp + 1) & 0xFF) << 8)
			if not _write_cpu((address + _y) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 2
		0x68: # PLA
			_a = _pop()
			if _a < 0: return false
			_set_nz(_a)
			_pc += 1
		0xC9: # CMP #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x18: # CLC
			_set_flag(FLAG_C, false)
			_pc += 1
		0x69: # ADC #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			var before := _a
			var sum := before + value + (1 if (_p & FLAG_C) != 0 else 0)
			_set_flag(FLAG_C, sum > 0xFF)
			_set_flag(FLAG_V, ((~(before ^ value) & (before ^ sum)) & 0x80) != 0)
			_a = sum & 0xFF
			_set_nz(_a)
			_pc += 2
		0xA5: # LDA zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x8D: # STA abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 3
		0x09: # ORA #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0x4C: # JMP abs
			_pc = _read_word(_pc + 1)
			if _pc < 0: return false
		0x6C: # JMP (abs); this ROM pointer does not cross a page boundary.
			var pointer := _read_word(_pc + 1)
			if pointer < 0: return false
			_pc = _read_cpu(pointer) | (_read_cpu((pointer & 0xFF00) | ((pointer + 1) & 0x00FF)) << 8)
			if _pc < 0: return false
		0x2C: # BIT abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_N, (value & FLAG_N) != 0)
			_set_flag(FLAG_V, (value & FLAG_V) != 0)
			_set_flag(FLAG_Z, (_a & value) == 0)
			_pc += 3
		0xAD: # LDA abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xBD: # LDA abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _x) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xB1: # LDA (zp),Y
			var zp := _read_cpu(_pc + 1)
			if zp < 0: return false
			var address := _read_cpu(zp) | (_read_cpu((zp + 1) & 0xFF) << 8)
			_a = _read_cpu((address + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x29: # AND #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a &= value
			_set_nz(_a)
			_pc += 2
		0x4A: # LSR A
			_set_flag(FLAG_C, (_a & 0x01) != 0)
			_a = (_a >> 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0x84: # STY zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _y, start_pc, start_bank): return false
			_pc += 2
		0xA4: # LDY zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			_y = _read_cpu(address)
			if _y < 0: return false
			_set_nz(_y)
			_pc += 2
		0x8E: # STX abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _x, start_pc, start_bank): return false
			_pc += 3
		0x38: # SEC
			_set_flag(FLAG_C, true)
			_pc += 1
		0xE9: # SBC #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			var before := _a
			var complemented := value ^ 0xFF
			var sum := before + complemented + (1 if (_p & FLAG_C) != 0 else 0)
			_set_flag(FLAG_C, sum > 0xFF)
			var result := sum & 0xFF
			_set_flag(FLAG_V, (((before ^ result) & (before ^ value)) & 0x80) != 0)
			_a = result
			_set_nz(_a)
			_pc += 2
		0xAA: # TAX
			_x = _a
			_set_nz(_x)
			_pc += 1
		0xAE: # LDX abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_x = _read_cpu(address)
			if _x < 0: return false
			_set_nz(_x)
			_pc += 3
		_:
			return _fail("Unsupported ROM opcode $%02X at $%04X (bank $%02X)." % [opcode, start_pc, start_bank])
	_instructions.append({"pc": start_pc, "bank": start_bank, "opcode": opcode, "next_pc": _pc})
	return true


func _read_word(address: int) -> int:
	var low := _read_cpu(address)
	var high := _read_cpu(address + 1)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _read_cpu(address: int) -> int:
	if address < 0 or address > 0xFFFF:
		_fail("6502 read outside address space at $%X." % address)
		return -1
	if address < 0x2000:
		return int(_ram[address & 0x07FF])
	var bank := _current_bank_for_pc(address)
	for file_name: String in SOURCE_FILES:
		var spec: Dictionary = SOURCE_FILES[file_name]
		if int(spec["bank"]) == bank and address >= int(spec["start"]) and address < int(spec["end"]):
			return int((_sources[file_name] as PackedByteArray)[address - int(spec["start"])])
	_fail("ROM read $%04X in bank $%02X is outside preserved spans." % [address, bank])
	return -1


func _write_cpu(address: int, value: int, source_pc: int, source_bank: int) -> bool:
	value &= 0xFF
	if address < 0x2000:
		var mirrored := address & 0x07FF
		_ram[mirrored] = value
		_writes.append({"pc": source_pc, "trace_pc": _write_trace_pc, "bank": source_bank, "address": mirrored, "value": value})
		return true
	if address == 0x8000:
		_mmc3_select = value & 0x07
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	if address == 0x8001:
		if _mmc3_select == 6:
			_bank_low = value
		elif _mmc3_select == 7:
			_bank_high = value
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	return _fail("Unsupported memory-mapped write $%04X=$%02X at $%04X." % [address, value, source_pc])


func _push(value: int, source_pc: int, source_bank: int) -> bool:
	var address := 0x0100 | _sp
	if not _write_cpu(address, value, source_pc, source_bank): return false
	_sp = (_sp - 1) & 0xFF
	return true


func _pop() -> int:
	_sp = (_sp + 1) & 0xFF
	return int(_ram[0x0100 | _sp])


func _compare(left: int, right: int) -> void:
	var difference := (left - right) & 0xFF
	_set_flag(FLAG_C, left >= right)
	_set_nz(difference)


func _set_nz(value: int) -> void:
	_set_flag(FLAG_Z, (value & 0xFF) == 0)
	_set_flag(FLAG_N, (value & 0x80) != 0)


func _set_flag(mask: int, enabled: bool) -> void:
	if enabled: _p |= mask
	else: _p &= ~mask
	_p |= FLAG_U


func _current_bank_for_pc(address: int) -> int:
	if address >= 0xC000 and address < 0xE000: return 0x1E
	if address >= 0xE000: return 0x1F
	if address >= 0xA000 and address < 0xC000: return _bank_high
	return _bank_low


func _opcode_length(opcode: int) -> int:
	match opcode:
		0xA2, 0xF0, 0xD0, 0x10, 0xE0, 0xA9, 0xA0, 0x85, 0x91, 0xC9, 0x18, 0x69, 0xA5, 0x09, 0xB1, 0x29, 0x84, 0xA4, 0xE9:
			return 2
		0xBC, 0x9D, 0x20, 0xB9, 0x8D, 0x4C, 0x2C, 0x6C, 0xAD, 0xBD, 0x8E, 0xAE:
			return 3
		_:
			return 1


func _selected_ram_state() -> Dictionary:
	return {
		"$0022": int(_ram[0x0022]), "$0023": int(_ram[0x0023]),
		"$0024": int(_ram[0x0024]), "$0025": int(_ram[0x0025]),
		"$0034": int(_ram[0x0034]), "$0035": int(_ram[0x0035]),
		"$0036": int(_ram[0x0036]), "$0037": int(_ram[0x0037]),
		"$002E": int(_ram[0x002E]), "$002F": int(_ram[0x002F]),
		"$0446": int(_ram[0x0446]), "$0447": int(_ram[0x0447]),
		"$044B": int(_ram[0x044B]), "$044F": int(_ram[0x044F]),
		"$05FB": int(_ram[0x05FB]), "$0629": int(_ram[0x0629]),
		"$0700-$0704": _bytes_hex(0x0700, 5),
		"$0300_record_bytes": _bytes_hex(0x0300, 0x100),
	}


func _bytes_hex(start: int, count: int) -> String:
	var output := PackedByteArray()
	for offset in range(count): output.append(int(_ram[start + offset]))
	return output.hex_encode()


func _verify_boundaries() -> bool:
	var reset_bytes: PackedByteArray = _sources["fixed_reset_ram_clear_C64E_C679.bin"]
	if reset_bytes != PackedByteArray([
		0xA9, 0x08, 0x8D, 0x00, 0x20, 0x78, 0xD8, 0xA2, 0xFF, 0x9A, 0xAD, 0x02,
		0x20, 0x10, 0xFB, 0xAD, 0x02, 0x20, 0x10, 0xFB, 0xA9, 0xC0, 0x8D, 0x01,
		0xA0, 0xA9,
		0x00, 0x85, 0x00, 0x85, 0x01, 0xA8, 0xA2, 0x08, 0x91, 0x00, 0xC8, 0xD0,
		0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6,
	]):
		return _fail("The packaged cold-reset RAM-clear source changed.")
	var caller: PackedByteArray = _sources["fixed_daaa_to_first_bank18_entry_DAAA_DACC.bin"]
	var expected_caller := PackedByteArray([0xA9, 0x01, 0x20, 0xF1, 0xCB, 0x20, 0x4F, 0xCF,
		0x48, 0xA5, 0x22, 0xA9, 0x1A, 0x85, 0x24, 0xA9, 0x1B, 0x85, 0x25,
		0x20, 0x2D, 0xCE, 0x68, 0x20, 0x39, 0x80, 0x20, 0x24, 0xDB,
		0xA9, 0x00, 0x20, 0x7F, 0xEF])
	if caller != expected_caller:
		return _fail("The packaged $DAAA-to-first-wrapper caller bytes changed.")
	if (_sources["fixed_scenario_wait_DADD_DAE9.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA9, 0x01, 0x20, 0x0F, 0xCB, 0xAD, 0x1C, 0x00, 0x29, 0xC0, 0xF0, 0xF4]):
		return _fail("The scenario-$35 `$DADD->$DAE9` wait and yield bytes changed.")
	if (_sources["fixed_scenario_input_exit_DAE9_DAF2.bin"] as PackedByteArray) \
			!= PackedByteArray([0xAD, 0xFB, 0x05, 0x18, 0x69, 0x08, 0x8D, 0x41, 0x04]):
		return _fail("The scenario-$35 set-input exit no longer derives `$0441 = $05FB + 8` from ROM bytes.")
	if (_sources["fixed_position_initializer_call_DAF2_DAF5.bin"] as PackedByteArray) \
			!= PackedByteArray([0x20, 0x07, 0xDC]):
		return _fail("The source `$DAF2` instruction no longer requests `$DC07`.")
	if (_sources["fixed_sound_queue_CBF1_CC01.bin"] as PackedByteArray).size() != 17 \
			or (_sources["fixed_record_reset_CF4F_CF71.bin"] as PackedByteArray)[34] != 0x60 \
			or (_sources["fixed_record_pointer_CD7C_CD88.bin"] as PackedByteArray)[12] != 0x60 \
			or (_sources["fixed_mapper_helper_CE2D_CE49.bin"] as PackedByteArray)[28] != 0x60:
		return _fail("A helper span no longer includes its verified RTS boundary.")
	if (_sources["fixed_branch_dispatch_DB24_DB62.bin"] as PackedByteArray).slice(0, 16) != PackedByteArray([
		0xAD, 0x29, 0x06, 0x20, 0x99, 0xCB, 0x34, 0xDB, 0x9E, 0xDB, 0xFC, 0xDB, 0xF3, 0xDB, 0x03, 0xDC
	]) or (_sources["bank1c_dispatch_trampoline_8003_8005.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x22, 0x8B]):
		return _fail("Fresh selector-dispatch source bytes changed.")
	if (_sources["bank1c_fresh_opponent_setup_8B22_8B93.bin"] as PackedByteArray)[0x93 - 0x22] != 0x60 \
			or (_sources["bank1d_opponent_pointer_entry_0_BAB2_BAB3.bin"] as PackedByteArray) != PackedByteArray([0xF6, 0xBA]) \
			or (_sources["bank1d_opponent_3_header_BAF6_BAFF.bin"] as PackedByteArray)[9] != 0x0F \
			or (_sources["fixed_bank18_wrapper_EF7F_EF99.bin"] as PackedByteArray)[0x96 - 0x7F] != 0x20:
		return _fail("Fresh opponent setup or first bank-$18 wrapper boundary bytes changed.")
	return true


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
