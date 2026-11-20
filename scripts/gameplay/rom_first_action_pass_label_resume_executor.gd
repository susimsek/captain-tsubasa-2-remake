extends RefCounted
class_name RomFirstActionPassLabelResumeExecutor
## Executes the source-derived slot-$05 `$E945-$E9D9` action-label renderer
## from a scheduler-produced resume. It writes only the secondary PPU queue;
## the caller owns NMI delivery and applying those packets to the PPU.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const SOURCE_MANIFEST_PATH := SOURCE_ROOT + "action_menu_renderer_resume_source.json"
const SOURCE_MANIFEST_SHA256 := "17ac6aa70af227f9a2b4748cf393e3a6f29e82192abe7d783dbeb6b0221da174"
const SOURCE_SPAN_PATH := SOURCE_ROOT + "action_menu_renderer_E945_E9D9.bin"
const SOURCE_SPAN_SHA256 := "7ed917d625d40ecc484ada8cf7910ffcb950d0de319daff7db66603004248417"
const BLINK_AUDIT_PATH := SOURCE_ROOT + "action_blink_source_audit.json"
const BLINK_AUDIT_SHA256 := "72b7cac439df171fe3cad8098335037167f62a678f6edad3f31983b48f6fbf38"
const ACTION_MAP_PATH := SOURCE_ROOT + "action_id_to_render_variant_context_00.bin"
const ACTION_MAP_SHA256 := "9d154b311f10f5a25ae835854853e99223ec66f254251a5e1ff366fc334a740e"
const POINTER_TABLE_PATH := SOURCE_ROOT + "action_render_variant_pointer_table_00_03.bin"
const POINTER_TABLE_SHA256 := "41f429b2ca2e143fb59e023bc886350b20135197e1bcfe7c5b837127fa662f42"
const LABEL_STREAMS_PATH := SOURCE_ROOT + "action_label_render_streams_EA1C_EA45.bin"
const LABEL_STREAMS_SHA256 := "97ad1d49bafb4111180337fc8378ce31a3ac80bca6dccee238c08da423c34b11"
const RENDERER_PREFIX_PATH := SOURCE_ROOT + "action_menu_renderer_prefix_E93D_E945.bin"
const RENDERER_PREFIX_SHA256 := "1f0810acea31b9f800ad5c84a5560de4114dcd1e2de48ae5679a0e92bc5e57d2"
const ENTRY_PC := 0xE945
const RESUME_PC := 0xE945
const BUSY_YIELD_CALLSITE_PC := 0xE940
const BUSY_YIELD_TARGET_PC := 0xCB0F
const EXIT_PC := 0xD68A
const RENDER_VARIANT_POINTER_TABLE_PC := 0xE9DA
const LABEL_STREAMS_PC := 0xEA1C
const SLOT_05 := 0x05
const PASS_ACTION_ID := 0x01
const PASS_RENDER_VARIANT := 0x01
const RAM_SIZE := 0x800
const FLAG_CARRY := 0x01
const FLAG_ZERO := 0x02
const FLAG_OVERFLOW := 0x40
const FLAG_NEGATIVE := 0x80
const FLAG_NZ := FLAG_NEGATIVE | FLAG_ZERO
const FLAG_CZVN := FLAG_CARRY | FLAG_ZERO | FLAG_OVERFLOW | FLAG_NEGATIVE

var error_message := ""
var _configured := false
var _renderer_code := PackedByteArray()
var _action_map := PackedByteArray()
var _pointer_table := PackedByteArray()
var _label_streams := PackedByteArray()
var _renderer_prefix := PackedByteArray()
var _audit := {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	for path in [SOURCE_MANIFEST_PATH, SOURCE_SPAN_PATH, BLINK_AUDIT_PATH,
			ACTION_MAP_PATH, POINTER_TABLE_PATH, LABEL_STREAMS_PATH, RENDERER_PREFIX_PATH]:
		if not FileAccess.file_exists(path):
			return _fail("ROM-derived action-label source is missing: " + path)
	if FileAccess.get_sha256(SOURCE_MANIFEST_PATH) != SOURCE_MANIFEST_SHA256 \
			or FileAccess.get_sha256(SOURCE_SPAN_PATH) != SOURCE_SPAN_SHA256 \
			or FileAccess.get_sha256(BLINK_AUDIT_PATH) != BLINK_AUDIT_SHA256 \
			or FileAccess.get_sha256(ACTION_MAP_PATH) != ACTION_MAP_SHA256 \
			or FileAccess.get_sha256(POINTER_TABLE_PATH) != POINTER_TABLE_SHA256 \
			or FileAccess.get_sha256(LABEL_STREAMS_PATH) != LABEL_STREAMS_SHA256 \
			or FileAccess.get_sha256(RENDERER_PREFIX_PATH) != RENDERER_PREFIX_SHA256:
		return _fail("A ROM-derived action-label code, manifest, or table hash mismatch was found.")
	var resume_manifest := _read_json(SOURCE_MANIFEST_PATH)
	_audit = _read_json(BLINK_AUDIT_PATH)
	if resume_manifest.is_empty() or _audit.is_empty():
		return _fail("A ROM-derived action-label provenance manifest is malformed.")
	var code_source: Dictionary = resume_manifest.get("source_code", {})
	var audit_source: Dictionary = _audit.get("source", {})
	if String(resume_manifest.get("schema", "")) != "ct2-first-action-renderer-resume-source-v1" \
			or String(resume_manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(code_source.get("cpu_start", "")) != "$E945" \
			or String(code_source.get("cpu_end_inclusive", "")) != "$E9D9" \
			or String(code_source.get("prg_bank", "")) != "$1E" \
			or String(code_source.get("file_offset", "")) != "0x03E955" \
			or int(code_source.get("length_bytes", -1)) != 0x95 \
			or String(code_source.get("sha256", "")) != SOURCE_SPAN_SHA256 \
			or String(_audit.get("target_rom_sha256", "")) != ROM_SHA256 \
			or audit_source.get("action_renderer_cpu_range", []) != ["$E93D", "$E9D9"] \
			or String(audit_source.get("action_renderer_sha256", "")) \
			!= "b2044af0dd910252ca0884ef835c15b9755febf4147f7fb105d03745faad5b33":
		return _fail("The action-label resume span no longer resolves to the audited supplied-ROM renderer.")
	_renderer_code = FileAccess.get_file_as_bytes(SOURCE_SPAN_PATH)
	_action_map = FileAccess.get_file_as_bytes(ACTION_MAP_PATH)
	_pointer_table = FileAccess.get_file_as_bytes(POINTER_TABLE_PATH)
	_label_streams = FileAccess.get_file_as_bytes(LABEL_STREAMS_PATH)
	_renderer_prefix = FileAccess.get_file_as_bytes(RENDERER_PREFIX_PATH)
	if _renderer_code.size() != 0x95 or _action_map != PackedByteArray([0x02, 0x01, 0x00, 0x03]) \
			or _pointer_table != PackedByteArray([0x1C, 0xEA, 0x29, 0xEA,
			0x34, 0xEA, 0x3D, 0xEA]) or _renderer_prefix != PackedByteArray([
			0x48, 0x8A, 0x48, 0xA9, 0x01, 0x20, 0x0F, 0xCB]):
		return _fail("The checked source code or action-label ROM tables have unexpected bytes.")
	_configured = true
	return true


## Executes only from the scheduler's yielded RTS result and immediate live
## boundary snapshot. The input task record is the CB0F save produced by the
## PASS-confirmation bridge; no emulator RAM, stack, or rendered pixels enter.
func execute_from_scheduler_dispatched_pass_label(dispatch_result: Dictionary,
		live_boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	var precondition := _validate_dispatched_pass_label(dispatch_result, live_boundary)
	if not bool(precondition.get("ok", false)):
		return _refused(String(precondition.get("error", "Invalid slot-$05 renderer resume.")))
	var ram: PackedByteArray = (live_boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (live_boundary["stack_page"] as PackedByteArray).duplicate()
	var cpu := {
		"pc": ENTRY_PC,
		"sp": int(live_boundary.get("sp", -1)) & 0xFF,
		"a": int(live_boundary.get("a", 0)) & 0xFF,
		"x": int(live_boundary.get("x", 0)) & 0xFF,
		"y": int(live_boundary.get("y", 0)) & 0xFF,
		"p": int(live_boundary.get("p", 0x20)) & 0xFF,
		"p_known_mask": int(live_boundary.get("p_known_mask", 0)) & 0xFF,
	}
	var writes: Array[Dictionary] = []
	var reads: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var step_count := 0
	var entry_ram_0515 := int(ram[0x0515])
	while int(cpu["pc"]) != EXIT_PC and step_count < 512:
		var pc := int(cpu["pc"])
		if pc < ENTRY_PC or pc > 0xE9D9:
			return _refused("Renderer execution escaped its pinned `$E945-$E9D9` span at `$%04X`." % pc)
		instruction_pcs.append(pc)
		step_count += 1
		var opcode := _code_byte(pc)
		var next_pc := pc + 1
		match opcode:
			0xAD: # LDA absolute
				var address := _word_at(pc + 1)
				var read_result := _read_source_memory(address, ram, pc)
				if not bool(read_result.get("ok", false)):
					return _refused(String(read_result.get("error", "Unsupported renderer source read.")))
				var value := int(read_result["value"])
				reads.append(read_result.get("event", {}))
				_set_a(cpu, value)
				next_pc += 2
			0xD0, 0xF0, 0x30: # BNE, BEQ, BMI
				var offset := _code_byte(pc + 1)
				if offset >= 0x80:
					offset -= 0x100
				var take_branch := (opcode == 0xD0 and (int(cpu["p"]) & FLAG_ZERO) == 0) \
						or (opcode == 0xF0 and (int(cpu["p"]) & FLAG_ZERO) != 0) \
						or (opcode == 0x30 and (int(cpu["p"]) & FLAG_NEGATIVE) != 0)
				next_pc += 1
				if take_branch:
					next_pc += offset
				if pc == 0xE948 and take_branch:
					if entry_ram_0515 == 0:
						return _refused("The `$0515` busy branch was reached even though its live entry byte was clear.")
					_advance_pc(cpu, pc, next_pc)
					return _busy_wait_result(dispatch_result, live_boundary,
						cpu, reads, instruction_pcs, entry_ram_0515)
			0xA9: # LDA immediate
				_set_a(cpu, _code_byte(pc + 1))
				next_pc += 1
			0xA5: # LDA zero page
				var address := _code_byte(pc + 1)
				reads.append(_ram_read_event(pc, address, int(ram[address])))
				_set_a(cpu, int(ram[address]))
				next_pc += 1
			0x8D, 0x85: # STA absolute / zero page
				var address := _code_byte(pc + 1) if opcode == 0x85 else _word_at(pc + 1)
				if address >= RAM_SIZE:
					return _refused("Renderer wrote outside internal RAM at `$%04X`." % address)
				var value := int(cpu["a"]) & 0xFF
				ram[address] = value
				writes.append({"source_pc": pc, "address": address, "value": value})
				next_pc += 1 if opcode == 0x85 else 2
			0x68: # PLA
				var popped := _pop_stack(cpu, stack, reads, stack_reads, pc)
				if not bool(popped.get("ok", false)):
					return _refused(String(popped.get("error", "Renderer stack pop failed.")))
				_set_a(cpu, int(popped["value"]))
			0x4A: # LSR A
				var old_a := int(cpu["a"]) & 0xFF
				_set_flag(cpu, FLAG_CARRY, (old_a & 0x01) != 0)
				_set_a(cpu, old_a >> 1)
			0x66: # ROR zero page
				var address := _code_byte(pc + 1)
				var old_value := int(ram[address])
				var old_carry := (int(cpu["p"]) & FLAG_CARRY) != 0
				_set_flag(cpu, FLAG_CARRY, (old_value & 0x01) != 0)
				var value := (old_value >> 1) | (0x80 if old_carry else 0)
				ram[address] = value
				writes.append({"source_pc": pc, "address": address, "value": value})
				_set_nz(cpu, value)
				next_pc += 1
			0x0A: # ASL A
				var old_a := int(cpu["a"]) & 0xFF
				_set_flag(cpu, FLAG_CARRY, (old_a & 0x80) != 0)
				_set_a(cpu, (old_a << 1) & 0xFF)
			0xA8: # TAY
				cpu["y"] = int(cpu["a"]) & 0xFF
				_set_nz(cpu, int(cpu["y"]))
			0x18: # CLC
				_set_flag(cpu, FLAG_CARRY, false)
			0xB9: # LDA absolute,Y
				var address := (_word_at(pc + 1) + int(cpu["y"])) & 0xFFFF
				var read_result := _read_source_memory(address, ram, pc)
				if not bool(read_result.get("ok", false)):
					return _refused(String(read_result.get("error", "Unsupported renderer table read.")))
				reads.append(read_result.get("event", {}))
				_set_a(cpu, int(read_result["value"]))
				next_pc += 2
			0x65: # ADC zero page
				var address := _code_byte(pc + 1)
				reads.append(_ram_read_event(pc, address, int(ram[address])))
				_adc(cpu, int(ram[address]))
				next_pc += 1
			0xA0: # LDY immediate
				cpu["y"] = _code_byte(pc + 1)
				_set_nz(cpu, int(cpu["y"]))
				next_pc += 1
			0xB1: # LDA (zero page),Y
				var pointer_address := _code_byte(pc + 1)
				var pointer_low := int(ram[pointer_address])
				var pointer_high := int(ram[(pointer_address + 1) & 0xFF])
				var address := (((pointer_high << 8) | pointer_low) + int(cpu["y"])) & 0xFFFF
				var read_result := _read_source_memory(address, ram, pc)
				if not bool(read_result.get("ok", false)):
					return _refused(String(read_result.get("error", "Unsupported renderer stream read.")))
				reads.append(_ram_read_event(pc, pointer_address, pointer_low))
				reads.append(_ram_read_event(pc, (pointer_address + 1) & 0xFF, pointer_high))
				reads.append(read_result.get("event", {}))
				_set_a(cpu, int(read_result["value"]))
				next_pc += 1
			0x29: # AND immediate
				_set_a(cpu, int(cpu["a"]) & _code_byte(pc + 1))
				next_pc += 1
			0xA2: # LDX immediate
				cpu["x"] = _code_byte(pc + 1)
				_set_nz(cpu, int(cpu["x"]))
				next_pc += 1
			0x9D: # STA absolute,X
				var address := (_word_at(pc + 1) + int(cpu["x"])) & 0xFFFF
				if address >= RAM_SIZE:
					return _refused("Renderer queue store escaped internal RAM at `$%04X`." % address)
				var value := int(cpu["a"]) & 0xFF
				ram[address] = value
				writes.append({"source_pc": pc, "address": address, "value": value})
				next_pc += 2
			0x69: # ADC immediate
				_adc(cpu, _code_byte(pc + 1))
				next_pc += 1
			0xE8: # INX
				cpu["x"] = (int(cpu["x"]) + 1) & 0xFF
				_set_nz(cpu, int(cpu["x"]))
			0x2C: # BIT absolute
				var address := _word_at(pc + 1)
				var read_result := _read_source_memory(address, ram, pc)
				if not bool(read_result.get("ok", false)):
					return _refused(String(read_result.get("error", "Unsupported BIT operand.")))
				var value := int(read_result["value"])
				reads.append(read_result.get("event", {}))
				_set_flag(cpu, FLAG_ZERO, (int(cpu["a"]) & value) == 0)
				_set_flag(cpu, FLAG_NEGATIVE, (value & 0x80) != 0)
				_set_flag(cpu, FLAG_OVERFLOW, (value & 0x40) != 0)
				next_pc += 2
			0xC9: # CMP immediate
				var value := _code_byte(pc + 1)
				var difference := (int(cpu["a"]) - value) & 0xFF
				_set_flag(cpu, FLAG_CARRY, int(cpu["a"]) >= value)
				_set_nz(cpu, difference)
				next_pc += 1
			0xC8: # INY
				cpu["y"] = (int(cpu["y"]) + 1) & 0xFF
				_set_nz(cpu, int(cpu["y"]))
			0xC6: # DEC zero page
				var address := _code_byte(pc + 1)
				var value := (int(ram[address]) - 1) & 0xFF
				ram[address] = value
				writes.append({"source_pc": pc, "address": address, "value": value})
				_set_nz(cpu, value)
				next_pc += 1
			0x60: # RTS
				var low := _pop_stack(cpu, stack, reads, stack_reads, pc)
				var high := _pop_stack(cpu, stack, reads, stack_reads, pc)
				if not bool(low.get("ok", false)) or not bool(high.get("ok", false)):
					return _refused("Renderer RTS could not read its caller return word.")
				next_pc = ((((int(high["value"]) << 8) | int(low["value"])) + 1) & 0xFFFF)
			_:
				return _refused("Unsupported ROM renderer opcode `$%02X` at `$%04X`." % [opcode, pc])
		_advance_pc(cpu, pc, next_pc)
	if int(cpu["pc"]) != EXIT_PC:
		return _refused("ROM action-label renderer did not return to `$D68A` within the bounded instruction budget.")
	var queue := _decode_queue_packets(ram)
	if not bool(queue.get("ok", false)):
		return _refused(String(queue.get("error", "Renderer emitted an invalid PPU queue.")))
	var source_queue_writes: Array[Dictionary] = []
	for write_variant in writes:
		if write_variant is Dictionary:
			var write: Dictionary = write_variant
			if int(write.get("address", -1)) >= 0x04A5 and int(write.get("address", -1)) <= int(queue.get("queue_end_address", 0x04A4)):
				source_queue_writes.append(write.duplicate(true))
	var final_sp := int(cpu["sp"]) & 0xFF
	var result := {
		"ok": true,
		"status": "pass_action_label_queued",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": SOURCE_MANIFEST_SHA256,
		"source_code_sha256": SOURCE_SPAN_SHA256,
		"action_audit_sha256": BLINK_AUDIT_SHA256,
		"action_map_sha256": ACTION_MAP_SHA256,
		"pointer_table_sha256": POINTER_TABLE_SHA256,
		"label_streams_sha256": LABEL_STREAMS_SHA256,
		"slot_base": SLOT_05,
		"dispatch_resume_path": "yielded_rts",
		"entry_pc": ENTRY_PC,
		"exit_pc": int(cpu["pc"]),
		"source_return_word": int(dispatch_result.get("source_return_word", -1)),
		"source_instruction_pcs": instruction_pcs,
		"instruction_count": step_count,
		"source_reads": reads,
		"source_writes": writes,
		"stack_reads": stack_reads,
		"stack_writes": [],
		"ppu_queue_buffer_writes": source_queue_writes,
		"ppu_queue_packets": queue.get("packets", []),
		"ppu_queue_buffer_address": 0x04A5,
		"ppu_queue_buffer_bytes": queue.get("buffer_bytes", PackedByteArray()),
		"ppu_queue_buffer_length": int(queue.get("buffer_length", 0)),
		"ppu_bus_writes_applied": false,
		"queue_ready_flag_before": entry_ram_0515,
		"queue_ready_flag_after": int(ram[0x0515]),
		"row_count": int(queue.get("packet_count", 0)),
		"rendered_action_id": PASS_ACTION_ID,
		"render_variant": PASS_RENDER_VARIANT,
		"stream_cpu_address": 0xEA29,
		"registers": cpu.duplicate(true),
		"entry_sp": int(live_boundary.get("sp", -1)),
		"exit_sp": final_sp,
		"entry_task_record": PackedByteArray(live_boundary.get("record", PackedByteArray())),
		"runtime_mutation_applied": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"normal_nmi_applied": false,
	}
	if int(cpu["sp"]) != ((int(live_boundary.get("sp", -1)) + 4) & 0xFF) \
			or int(ram[0x0515]) != 0x80 or int(queue.get("packet_count", 0)) != 2:
		return _refused("Renderer exit stack, `$0515` ready state, or PASS packet count differs from its ROM path.")
	return result


func _validate_dispatched_pass_label(dispatch_result: Dictionary,
		boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["ram_image", "stack_page", "fceux_ram", "captured_ram",
			"emulator_snapshot", "screenshot", "capture_image"]:
		if dispatch_result.has(forbidden_key):
			return {"ok": false, "error": "Dispatch receipt contains forbidden captured memory/media input."}
	for forbidden_key in ["fceux_ram", "captured_ram", "emulator_snapshot",
			"screenshot", "capture_image"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "error": "Live scheduler boundary contains forbidden emulator capture input."}
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != 0x100:
		return {"ok": false, "error": "Live scheduler boundary must contain scheduler-owned 2 KiB RAM and 256-byte stack."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var entry_sp := int(boundary.get("sp", -1)) & 0xFF
	var slot_record: PackedByteArray = boundary.get("record", PackedByteArray())
	var action_id := int(ram[0x043B])
	var variant := int(_action_map[action_id]) if action_id >= 0 and action_id < _action_map.size() else -1
	var action_variant_at_stack := int(stack[(entry_sp + 2) & 0xFF])
	var caller_low := int(stack[(entry_sp + 3) & 0xFF])
	var caller_high := int(stack[(entry_sp + 4) & 0xFF])
	var caller_word := (caller_high << 8) | caller_low
	if not bool(dispatch_result.get("ok", false)) \
			or int(dispatch_result.get("slot_base", -1)) != SLOT_05 \
			or String(dispatch_result.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch_result.get("pc", -1)) != ENTRY_PC \
			or int(dispatch_result.get("source_return_word", -1)) != 0xE944 \
			or int(dispatch_result.get("sp", -1)) != entry_sp \
			or int(dispatch_result.get("bank_low", -1)) != 0x1A \
			or int(dispatch_result.get("bank_high", -1)) != 0x1B \
			or int(dispatch_result.get("phase", -1)) != 2 \
			or int(boundary.get("slot_base", -1)) != SLOT_05 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("pc", -1)) != ENTRY_PC \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(ram[0x0000]) != SLOT_05 \
			or int(ram[0x0024]) != 0x1A or int(ram[0x0025]) != 0x1B \
			or ram.slice(0x0100, 0x0200) != stack \
			or slot_record.size() != 4 or slot_record != PackedByteArray([0,
				int(boundary.get("sp", -1)) - 4 & 0xFF, 0x1A, 0x1B]) \
			or int(dispatch_result.get("a", -1)) != int(boundary.get("a", -2)) \
			or int(dispatch_result.get("x", -1)) != int(boundary.get("x", -2)) \
			or int(dispatch_result.get("y", -1)) != int(boundary.get("y", -2)) \
			or action_id != PASS_ACTION_ID or variant != PASS_RENDER_VARIANT \
			or int(stack[(entry_sp + 1) & 0xFF]) != 0 \
			or action_variant_at_stack != variant or caller_word != 0xD689:
		return {"ok": false, "error": "Renderer requires a genuine scheduler-dispatched PASS `$E945` continuation with its ROM-saved variant and `$D689` caller word."}
	return {"ok": true}


func _read_source_memory(address: int, ram: PackedByteArray, pc: int) -> Dictionary:
	if address >= 0 and address < RAM_SIZE:
		return {"ok": true, "value": int(ram[address]),
			"event": _ram_read_event(pc, address, int(ram[address]))}
	if address >= RENDER_VARIANT_POINTER_TABLE_PC \
			and address < RENDER_VARIANT_POINTER_TABLE_PC + _pointer_table.size():
		var table_value := int(_pointer_table[address - RENDER_VARIANT_POINTER_TABLE_PC])
		return {"ok": true, "value": table_value, "event": {
			"source_pc": pc, "address": address, "value": table_value,
			"source_kind": "ROM_fixed_bank_1E_pointer_table"}}
	if address >= LABEL_STREAMS_PC and address < LABEL_STREAMS_PC + _label_streams.size():
		var stream_value := int(_label_streams[address - LABEL_STREAMS_PC])
		return {"ok": true, "value": stream_value, "event": {
			"source_pc": pc, "address": address, "value": stream_value,
			"source_kind": "ROM_fixed_bank_1E_label_stream"}}
	return {"ok": false, "error": "Renderer read unsupported CPU address `$%04X` at `$%04X`." % [address, pc]}


func _decode_queue_packets(ram: PackedByteArray) -> Dictionary:
	var cursor := 0
	var packets: Array[Dictionary] = []
	var bytes := PackedByteArray()
	var found_terminator := false
	while cursor < 0x100:
		var queue_address := 0x04A5 + cursor
		var payload_width := int(ram[queue_address])
		if payload_width == 0:
			if packets.is_empty():
				return {"ok": false, "error": "Renderer queue begins with an empty terminator."}
			bytes.append(0)
			found_terminator = true
			break
		if payload_width != 5 or cursor + payload_width + 3 >= 0x100:
			return {"ok": false, "error": "Renderer emitted an unsupported action-label packet width or extent."}
		var low := int(ram[queue_address + 1])
		var high := int(ram[queue_address + 2])
		var ppu_address := (high << 8) | low
		var tiles := ram.slice(queue_address + 3, queue_address + 3 + payload_width)
		var packet_bytes := ram.slice(queue_address, queue_address + 3 + payload_width)
		packets.append({"ppu_address": ppu_address, "payload_width": payload_width,
			"tiles": tiles, "packet_bytes": packet_bytes,
			"buffer_address": queue_address})
		bytes.append_array(packet_bytes)
		cursor += packet_bytes.size()
	return {"ok": found_terminator and packets.size() == 2 and packets[0]["ppu_address"] == 0x22AC \
		and packets[1]["ppu_address"] == 0x22CC,
		"packets": packets, "packet_count": packets.size(),
		"buffer_bytes": bytes, "buffer_length": bytes.size(),
		"queue_end_address": 0x04A5 + bytes.size() - 1}


func _busy_wait_result(dispatch_result: Dictionary, boundary: Dictionary,
		cpu: Dictionary, reads: Array[Dictionary], instruction_pcs: Array[int],
		entry_flag: int) -> Dictionary:
	return {
		"ok": true,
		"status": "waiting_for_0515_clear",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": SOURCE_MANIFEST_SHA256,
		"source_code_sha256": SOURCE_SPAN_SHA256,
		"slot_base": SLOT_05,
		"dispatch_resume_path": "yielded_rts",
		"entry_pc": ENTRY_PC,
		"exit_pc": int(cpu["pc"]),
		"source_return_word": int(dispatch_result.get("source_return_word", -1)),
		"source_instruction_pcs": instruction_pcs,
		"instruction_count": instruction_pcs.size(),
		"source_reads": reads,
		"source_writes": [],
		"stack_reads": [],
		"stack_writes": [],
		"ppu_queue_buffer_writes": [],
		"ppu_queue_packets": [],
		"ppu_queue_buffer_address": 0x04A5,
		"ppu_queue_buffer_bytes": PackedByteArray(),
		"ppu_queue_buffer_length": 0,
		"ppu_bus_writes_applied": false,
		"queue_ready_flag_before": entry_flag,
		"queue_ready_flag_after": entry_flag,
		"yield_callsite_pc": BUSY_YIELD_CALLSITE_PC,
		"yield_target_pc": BUSY_YIELD_TARGET_PC,
		"resume_pc_after_yield": RESUME_PC,
		"source_reyield_required": true,
		"yield_reason": "ROM `$E945->$E940` busy-buffer poll; `$CB0F` must save the task and a caller-owned NMI must clear `$0515` before a later scheduler dispatch",
		"state_mutated": false,
		"runtime_mutation_applied": false,
		"scheduler_dispatch_consumed": true,
		"active_task_slot": int(boundary.get("active_task_slot", -1)),
		"registers": cpu.duplicate(true),
		"entry_sp": int(boundary.get("sp", -1)),
		"exit_sp": int(cpu.get("sp", -1)),
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"normal_nmi_applied": false,
	}


func _pop_stack(cpu: Dictionary, stack: PackedByteArray, reads: Array[Dictionary],
		stack_reads: Array[Dictionary], pc: int) -> Dictionary:
	var next_sp := (int(cpu["sp"]) + 1) & 0xFF
	var value := int(stack[next_sp])
	cpu["sp"] = next_sp
	var event := {"source_pc": pc, "address": 0x0100 | next_sp,
		"value": value, "operation": "pla_stack_read"}
	reads.append(event.duplicate(true))
	stack_reads.append(event)
	return {"ok": true, "value": value}


func _ram_read_event(pc: int, address: int, value: int) -> Dictionary:
	return {"source_pc": pc, "address": address, "value": value,
		"source_kind": "scheduler_owned_ram"}


func _code_byte(pc: int) -> int:
	var index := pc - ENTRY_PC
	return int(_renderer_code[index]) if index >= 0 and index < _renderer_code.size() else -1


func _word_at(pc: int) -> int:
	return _code_byte(pc) | (_code_byte(pc + 1) << 8)


func _advance_pc(cpu: Dictionary, _pc: int, next_pc: int) -> void:
	cpu["pc"] = next_pc & 0xFFFF


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_nz(cpu: Dictionary, value: int) -> void:
	_set_flag(cpu, FLAG_ZERO, (value & 0xFF) == 0)
	_set_flag(cpu, FLAG_NEGATIVE, (value & 0x80) != 0)


func _set_flag(cpu: Dictionary, mask: int, enabled: bool) -> void:
	var p := int(cpu["p"]) & 0xFF
	cpu["p"] = (p | mask) if enabled else (p & (0xFF ^ mask))
	cpu["p_known_mask"] = (int(cpu.get("p_known_mask", 0)) | mask) & 0xFF


func _adc(cpu: Dictionary, value: int) -> void:
	var old_a := int(cpu["a"]) & 0xFF
	var operand := value & 0xFF
	var carry_in := 1 if (int(cpu["p"]) & FLAG_CARRY) != 0 else 0
	var sum := old_a + operand + carry_in
	var result := sum & 0xFF
	_set_flag(cpu, FLAG_CARRY, sum > 0xFF)
	_set_flag(cpu, FLAG_OVERFLOW, ((~(old_a ^ operand) & (old_a ^ result)) & 0x80) != 0)
	cpu["a"] = result
	_set_nz(cpu, result)


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_resume_rejected", "error": message,
		"rom_sha256": ROM_SHA256, "trace_state_used": false,
		"emulator_data_used": false}
