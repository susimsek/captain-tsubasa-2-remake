extends RefCounted
class_name RomFirstActionConfirmationBridgeExecutor
## Executes the ROM-owned PASS A-confirm prefix through its first real CB0F
## yield and returns the scheduler handoff. It intentionally stops before NMI
## scheduling resumes E93D at $E945; it never synthesizes a $D6C7 boundary.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const INPUT_ROOT := "res://reference/rom_extract/gameplay/first_action_menu_input/"
const INPUT_MANIFEST_PATH := INPUT_ROOT + "manifest.json"
const INPUT_MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const INPUT_SPAN_PATH := INPUT_ROOT + "action_input_dispatch_D5E0_D6E7.bin"
const INPUT_SPAN_SHA256 := "ad109ac091d382e1dca97d8d9c596617187b6f37e0ea0a965cc090066822d101"
const BLINK_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const BLINK_AUDIT_PATH := BLINK_ROOT + "action_blink_source_audit.json"
const BLINK_AUDIT_SHA256 := "72b7cac439df171fe3cad8098335037167f62a678f6edad3f31983b48f6fbf38"
const RENDERER_PREFIX_PATH := BLINK_ROOT + "action_menu_renderer_prefix_E93D_E945.bin"
const RENDERER_PREFIX_SHA256 := "1f0810acea31b9f800ad5c84a5560de4114dcd1e2de48ae5679a0e92bc5e57d2"
const TASK_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const TASK_MANIFEST_PATH := TASK_ROOT + "manifest.json"
const TASK_MANIFEST_SHA256 := "5975db3b40e865f321930b5b70d905b002d8929d1e06bdda7d64586064d1bbe7"
const TASK_YIELD_PATH := TASK_ROOT + "fixed_task_yield_save_CB0F.bin"
const TASK_YIELD_SHA256 := "b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc"
const ACTION_WAIT_PC := 0xD5EA
const ACTION_ID_PASS := 1
const PASS_DIRECTION_LATCH := 0x81
const SLOT_05 := 0x05
const FLAG_CARRY := 0x01
const FLAG_ZERO := 0x02
const FLAG_OVERFLOW := 0x40
const FLAG_NEGATIVE := 0x80
const RUNNING_PHASE := 2

var error_message := ""
var _configured := false
var _input_span := PackedByteArray()
var _renderer_prefix := PackedByteArray()
var _task_yield := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	for path in [INPUT_MANIFEST_PATH, INPUT_SPAN_PATH, BLINK_AUDIT_PATH,
			RENDERER_PREFIX_PATH, TASK_MANIFEST_PATH, TASK_YIELD_PATH]:
		if not FileAccess.file_exists(path):
			return _fail("Required ROM-derived source is missing: " + path)
	if FileAccess.get_sha256(INPUT_MANIFEST_PATH) != INPUT_MANIFEST_SHA256 \
			or FileAccess.get_sha256(INPUT_SPAN_PATH) != INPUT_SPAN_SHA256 \
			or FileAccess.get_sha256(BLINK_AUDIT_PATH) != BLINK_AUDIT_SHA256 \
			or FileAccess.get_sha256(RENDERER_PREFIX_PATH) != RENDERER_PREFIX_SHA256 \
			or FileAccess.get_sha256(TASK_MANIFEST_PATH) != TASK_MANIFEST_SHA256 \
			or FileAccess.get_sha256(TASK_YIELD_PATH) != TASK_YIELD_SHA256:
		return _fail("A ROM-derived bridge manifest or byte-span SHA-256 mismatch was found.")
	var input_manifest := _read_json_object(INPUT_MANIFEST_PATH)
	var blink_audit := _read_json_object(BLINK_AUDIT_PATH)
	var task_manifest := _read_json_object(TASK_MANIFEST_PATH)
	if input_manifest.is_empty() or blink_audit.is_empty() or task_manifest.is_empty():
		return _fail("A ROM-derived bridge manifest is malformed.")
	if String(input_manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(input_manifest.get("source_rom_size_bytes", -1)) != 0x60010 \
			or String(task_manifest.get("rom_sha256", "")) != ROM_SHA256 \
			or String(blink_audit.get("target_rom_sha256", "")) != ROM_SHA256:
		return _fail("ROM-derived bridge sources do not identify the pinned supplied ROM.")
	var renderer_source: Dictionary = blink_audit.get("source", {})
	if renderer_source.get("action_renderer_cpu_range", []) != ["$E93D", "$E9D9"] \
			or String(renderer_source.get("action_renderer_sha256", "")) \
			!= "b2044af0dd910252ca0884ef835c15b9755febf4147f7fb105d03745faad5b33":
		return _fail("The action-renderer prefix provenance no longer maps to ROM bank $1E.")
	_input_span = FileAccess.get_file_as_bytes(INPUT_SPAN_PATH)
	_renderer_prefix = FileAccess.get_file_as_bytes(RENDERER_PREFIX_PATH)
	_task_yield = FileAccess.get_file_as_bytes(TASK_YIELD_PATH)
	if _input_span.size() != 264 or _renderer_prefix != PackedByteArray([
			0x48, 0x8A, 0x48, 0xA9, 0x01, 0x20, 0x0F, 0xCB]) \
			or _task_yield != PackedByteArray([
			0x85, 0x7F, 0x8A, 0x48, 0x98, 0x48, 0xA6, 0x00, 0xA5, 0x24,
			0x95, 0x02, 0xA5, 0x25, 0x95, 0x03, 0xA5, 0x7F, 0x95, 0x00,
			0x8A, 0xA8, 0xBA, 0x96, 0x01, 0xA6, 0x00, 0x4C, 0xA5, 0xCA]):
		return _fail("ROM-derived bridge instruction spans have unexpected bytes or lengths.")
	if not _expect_input_bytes(0xD5EA, [0xA9, 0x0F, 0x2D, 0x1E, 0x00, 0xF0, 0x35]) \
			or not _expect_input_bytes(0xD626, [0xA9, 0x80, 0x2D, 0x1E, 0x00,
			0xF0, 0x0B, 0x2C, 0x1E, 0x06, 0x10, 0x06, 0x20, 0x7C, 0xD6,
			0x4C, 0xC3, 0xD5]) \
			or not _expect_input_bytes(0xD67C, [0xAE, 0x3B, 0x04, 0xBD, 0xDE, 0xD6,
			0xA2, 0x00, 0x8E, 0x3C, 0x04, 0x20, 0x3D, 0xE9]):
		return _fail("D5EA/D67C source instructions differ from the pinned ROM bytes.")
	_configured = true
	return true


## Starts only after the scheduler has consumed a distinct A receipt at D5EA.
## The input dispatcher is not repeated here; only its adopted source boundary,
## receipt, and pending confirmation handoff are accepted.
func execute_from_consumed_pass_confirmation(boundary: Dictionary,
		input_sample: Dictionary, confirmation_adoption: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	var precondition := _validate_live_confirmation(boundary, input_sample,
		confirmation_adoption)
	if not bool(precondition.get("ok", false)):
		return _refused(String(precondition.get("error", "Invalid live confirmation boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var initial_sp := int(boundary["sp"]) & 0xFF
	var cpu := {
		"pc": ACTION_WAIT_PC,
		"sp": initial_sp,
		"a": int(boundary.get("a", 0)) & 0xFF,
		"x": int(boundary.get("x", 0)) & 0xFF,
		"y": int(boundary.get("y", 0)) & 0xFF,
		"p": int(boundary.get("p", 0x20)) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0)) & 0xFF,
	}
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var source_pc_history: Array[int] = []
	var source_instruction_pcs: Array[int] = [
		0xD5EA, 0xD5EC, 0xD5EF, 0xD626, 0xD628, 0xD62B, 0xD62D, 0xD630,
		0xD632, 0xD67C, 0xD67F, 0xD682, 0xD684, 0xD687, 0xE93D, 0xE93E,
		0xE93F, 0xE940, 0xE942, 0xCB0F, 0xCB11, 0xCB12, 0xCB13, 0xCB14,
		0xCB15, 0xCB17, 0xCB19, 0xCB1B, 0xCB1D, 0xCB1F, 0xCB21, 0xCB23,
		0xCB24, 0xCB25, 0xCB26, 0xCB28, 0xCB2A, 0xCAA5]
	var mapper_events: Array[Dictionary] = []

	# D5EA: the A edge has no low direction bits, so the first BEQ reaches D626.
	_source_pc(source_pc_history, cpu, 0xD5EA)
	_lda(cpu, 0x0F)
	var low_edge := int(ram[0x001E]) & int(cpu["a"])
	source_reads.append(_read_event(0xD5EC, 0x001E, int(ram[0x001E])))
	_and(cpu, low_edge)
	if int(cpu["p"]) & FLAG_ZERO == 0:
		return _refused("The live D5EA edge did not take the ROM's low-direction skip branch.")
	cpu["pc"] = 0xD626
	_source_pc(source_pc_history, cpu, 0xD626)
	_lda(cpu, 0x80)
	var a_edge := int(ram[0x001E]) & int(cpu["a"])
	source_reads.append(_read_event(0xD628, 0x001E, int(ram[0x001E])))
	_and(cpu, a_edge)
	if int(cpu["p"]) & FLAG_ZERO != 0:
		return _refused("The live D5EA receipt no longer takes the A-confirm branch.")
	source_reads.append(_read_event(0xD62D, 0x061E, int(ram[0x061E])))
	_bit(cpu, int(ram[0x061E]))
	if int(cpu["p"]) & FLAG_NEGATIVE == 0:
		return _refused("The live selection latch does not take the source BPL-to-return branch.")

	# D632 JSR $D67C, then the ROM-owned PASS setup through JSR $E93D.
	_source_pc(source_pc_history, cpu, 0xD632)
	_push_jsr(cpu, stack, ram, stack_writes, 0xD632)
	_source_pc(source_pc_history, cpu, 0xD67C)
	source_reads.append(_read_event(0xD67C, 0x043B, int(ram[0x043B])))
	_cpu_ldx(cpu, int(ram[0x043B]))
	var action_table_index := 0xD6DE - 0xD5E0 + int(cpu["x"])
	var action_variant := int(_input_span[action_table_index])
	source_reads.append(_read_event(0xD67F, 0xD6DE + int(cpu["x"]), action_variant))
	_lda(cpu, action_variant)
	_cpu_ldx(cpu, 0)
	_write_ram(ram, ram_writes, 0xD684, 0x043C, int(cpu["x"]))
	_source_pc(source_pc_history, cpu, 0xD687)
	_push_jsr(cpu, stack, ram, stack_writes, 0xD687)

	# E93D prefix is source-executed up to its JSR $CB0F. The yield is real;
	# without a scheduler/NMI continuation, E93D must not be advanced to E945.
	_source_pc(source_pc_history, cpu, 0xE93D)
	_pha(cpu, stack, ram, stack_writes, 0xE93D)
	_cpu_txa(cpu)
	_pha(cpu, stack, ram, stack_writes, 0xE93F)
	_lda(cpu, 0x01)
	_source_pc(source_pc_history, cpu, 0xE942)
	_push_jsr(cpu, stack, ram, stack_writes, 0xE942)
	_source_pc(source_pc_history, cpu, 0xCB0F)

	# CB0F: execute each pinned instruction through its JMP $CAA5.
	_write_ram(ram, ram_writes, 0xCB0F, 0x007F, int(cpu["a"]))
	_cpu_txa(cpu)
	_pha(cpu, stack, ram, stack_writes, 0xCB12)
	_cpu_tya(cpu)
	_pha(cpu, stack, ram, stack_writes, 0xCB14)
	source_reads.append(_read_event(0xCB15, 0x0000, int(ram[0x0000])))
	_cpu_ldx(cpu, int(ram[0x0000]))
	source_reads.append(_read_event(0xCB17, 0x0024, int(ram[0x0024])))
	_lda(cpu, int(ram[0x0024]))
	_write_ram(ram, ram_writes, 0xCB19, 0x0002 + int(cpu["x"]), int(cpu["a"]))
	source_reads.append(_read_event(0xCB1B, 0x0025, int(ram[0x0025])))
	_lda(cpu, int(ram[0x0025]))
	_write_ram(ram, ram_writes, 0xCB1D, 0x0003 + int(cpu["x"]), int(cpu["a"]))
	source_reads.append(_read_event(0xCB1F, 0x007F, int(ram[0x007F])))
	_lda(cpu, int(ram[0x007F]))
	_write_ram(ram, ram_writes, 0xCB21, int(cpu["x"]), int(cpu["a"]))
	_cpu_txa(cpu)
	_cpu_tay(cpu)
	_cpu_tsx(cpu)
	_write_ram(ram, ram_writes, 0xCB26, 0x0001 + int(cpu["y"]), int(cpu["x"]))
	source_reads.append(_read_event(0xCB28, 0x0000, int(ram[0x0000])))
	_cpu_ldx(cpu, int(ram[0x0000]))
	cpu["pc"] = 0xCAA5
	source_pc_history.append(0xCAA5)

	var saved_sp := int(ram[SLOT_05 + 1])
	var task_low := int(stack[(saved_sp + 3) & 0xFF])
	var task_high := int(stack[(saved_sp + 4) & 0xFF])
	var resume_pc := (((task_high << 8) | task_low) + 1) & 0xFFFF
	if resume_pc != 0xE945 or int(ram[SLOT_05]) != 1 \
			or int(ram[SLOT_05 + 2]) != 0x1A or int(ram[SLOT_05 + 3]) != 0x1B:
		return _refused("The ROM CB0F save did not preserve the expected E945/$1A/$1B slot-$05 continuation.")
	var entry_mapper: Variant = boundary.get("mapper", {})
	var mapper_state := {"execution_bank": 0x1E,
		"slot05_saved_bank_pair": [int(ram[SLOT_05 + 2]), int(ram[SLOT_05 + 3])],
		"switchable_window_shadow_pair": [int(ram[0x0024]), int(ram[0x0025])],
		"entry_mapper_proof": entry_mapper.duplicate(true) if entry_mapper is Dictionary else {},
		"mapper_writes_during_slice": mapper_events}
	return {
		"ok": true,
		"status": "pass_confirmation_yielded_waiting_for_scheduler_nmi",
		"rom_sha256": ROM_SHA256,
		"source_hashes": {
			"input_manifest_sha256": INPUT_MANIFEST_SHA256,
			"input_span_sha256": INPUT_SPAN_SHA256,
			"blink_audit_sha256": BLINK_AUDIT_SHA256,
			"renderer_prefix_sha256": RENDERER_PREFIX_SHA256,
			"task_manifest_sha256": TASK_MANIFEST_SHA256,
			"cb0f_span_sha256": TASK_YIELD_SHA256,
		},
		"consumed_sample_receipt_id": int(input_sample["sample_receipt_id"]),
		"source_pc_history": source_pc_history,
		"source_instruction_pcs": source_instruction_pcs,
		"source_reads": source_reads,
		"source_writes": ram_writes,
		"source_stack_writes": stack_writes,
		"registers": cpu.duplicate(true),
		"entry_sp": initial_sp,
		"saved_task_sp": saved_sp,
		"final_sp": int(cpu["sp"]),
		"saved_task_record": [int(ram[SLOT_05]), int(ram[SLOT_05 + 1]),
			int(ram[SLOT_05 + 2]), int(ram[SLOT_05 + 3])],
		"task_resume_pc_after_scheduler": resume_pc,
		"scheduler_handoff": {"pc": 0xCAA5, "phase": "rom_task_scheduler_scan_entry",
			"active_task_slot": -1, "scheduler_x": int(cpu["x"]),
			"yielded_slot": SLOT_05, "next_scan_slot_after_caa5": 0x09,
			"nmi_wait_reached": false, "resume_worker_pc_after_dispatch": resume_pc,
			"next_required_action": "execute the ROM scheduler scan from CAA5, process ready tasks, then use normal NMI delivery/queue service as needed before dispatching slot-$05 at $E945"},
		"mapper_state": mapper_state,
		"ram_write_count": ram_writes.size(),
		"stack_write_count": stack_writes.size(),
		"d6c7_reached": false,
		"handler_dispatch_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"missing_producer": {"kind": "scheduler_scan_and_worker_resume",
			"first_unexecuted_pc": 0xCAA5, "nmi_entry_pc": 0xC76E,
			"resume_worker_pc": 0xE945,
			"reason": "The source task has yielded. The scheduler scan has not run; normal NMI queue service and slot-$05 dispatch at E945 are later source transitions."},
	}


func _validate_live_confirmation(boundary: Dictionary, input_sample: Dictionary,
		confirmation_adoption: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != 0x800 \
			or not stack_variant is PackedByteArray or stack_variant.size() != 0x100:
		return {"ok": false, "error": "A complete scheduler-owned RAM/stack boundary is required."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if ram.slice(0x0100, 0x0200) != stack:
		return {"ok": false, "error": "The live scheduler stack page and RAM mirror differ."}
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_05 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_05 \
			or int(boundary.get("phase", -1)) != RUNNING_PHASE \
			or int(boundary.get("pc", -1)) != ACTION_WAIT_PC \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("sp", -1)) < 0 or int(boundary.get("sp", -1)) > 0xFF:
		return {"ok": false, "error": "The bridge requires the current slot-$05 running `$D5EA`, bank `$1A/$1B` source boundary."}
	if int(ram[0x0000]) != SLOT_05 or int(ram[0x0024]) != 0x1A \
			or int(ram[0x0025]) != 0x1B or int(ram[0x0621]) != 0 \
			or int(ram[0x043B]) != ACTION_ID_PASS \
			or int(ram[0x061E]) != PASS_DIRECTION_LATCH \
			or int(ram[0x001C]) != 0x80 or int(ram[0x001E]) != 0x80:
		return {"ok": false, "error": "Live RAM does not contain the adopted context-0 PASS selection and A edge."}
	if int(input_sample.get("sample_receipt_id", -1)) <= 0 \
			or int(input_sample.get("sample_receipt_id", -1)) \
			!= int(confirmation_adoption.get("sample_receipt_id", -2)) \
			or int(input_sample.get("previous", -1)) < 0 \
			or int(input_sample.get("current", -1)) != 0x80 \
			or int(input_sample.get("newly_pressed", -1)) != 0x80 \
			or ((int(input_sample.get("previous", 0)) ^ int(input_sample.get("current", 0))) \
			& int(input_sample.get("current", 0))) != 0x80 \
			or int(input_sample.get("held_ram_001c", -1)) != 0x80 \
			or int(input_sample.get("edge_ram_001e", -1)) != 0x80:
		return {"ok": false, "error": "The latest consumed A sample receipt is incomplete or inconsistent."}
	if String(confirmation_adoption.get("status", "")) \
			!= "pass_confirmation_pending_source_execution" \
			or int(confirmation_adoption.get("source_boundary_pc", -1)) != ACTION_WAIT_PC \
			or int(confirmation_adoption.get("active_task_slot", -1)) != SLOT_05 \
			or int(confirmation_adoption.get("selected_action_id", -1)) != ACTION_ID_PASS \
			or not bool(confirmation_adoption.get("source_execution_pending", false)) \
			or bool(confirmation_adoption.get("handler_dispatch_executed", true)) \
			or confirmation_adoption.has("resume_pc") \
			or confirmation_adoption.has("handler_entry_pc"):
		return {"ok": false, "error": "The scheduler did not return the one-use pending A-confirmation receipt at D5EA."}
	return {"ok": true}


func _expect_input_bytes(cpu_start: int, expected: Array[int]) -> bool:
	var offset := cpu_start - 0xD5E0
	return offset >= 0 and offset + expected.size() <= _input_span.size() \
			and _input_span.slice(offset, offset + expected.size()) == PackedByteArray(expected)


func _read_json_object(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _source_pc(history: Array[int], cpu: Dictionary, pc: int) -> void:
	cpu["pc"] = pc
	history.append(pc)


func _read_event(source_pc: int, address: int, value: int) -> Dictionary:
	return {"source_pc": source_pc, "address": address, "value": value & 0xFF}


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	var normalized := value & 0xFF
	ram[address] = normalized
	writes.append({"source_pc": source_pc, "address": address, "value": normalized})


func _push_jsr(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		writes: Array[Dictionary], source_pc: int) -> void:
	var return_minus_one := (source_pc + 2) & 0xFFFF
	_push_stack(cpu, stack, ram, writes, source_pc, (return_minus_one >> 8) & 0xFF, "jsr_push_high")
	_push_stack(cpu, stack, ram, writes, source_pc, return_minus_one & 0xFF, "jsr_push_low")


func _pha(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		writes: Array[Dictionary], source_pc: int) -> void:
	_push_stack(cpu, stack, ram, writes, source_pc, int(cpu["a"]), "pha")


func _push_stack(cpu: Dictionary, stack: PackedByteArray, ram: PackedByteArray,
		writes: Array[Dictionary], source_pc: int, value: int, operation: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	var address := 0x0100 | sp
	var normalized := value & 0xFF
	stack[sp] = normalized
	ram[address] = normalized
	writes.append({"source_pc": source_pc, "address": address,
		"value": normalized, "operation": operation})
	cpu["sp"] = (sp - 1) & 0xFF


func _lda(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _and(cpu: Dictionary, value: int) -> void:
	cpu["a"] = (int(cpu["a"]) & value) & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _cpu_ldx(cpu: Dictionary, value: int) -> void:
	cpu["x"] = value & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _cpu_txa(cpu: Dictionary) -> void:
	cpu["a"] = int(cpu["x"]) & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _cpu_tya(cpu: Dictionary) -> void:
	cpu["a"] = int(cpu["y"]) & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _cpu_tay(cpu: Dictionary) -> void:
	cpu["y"] = int(cpu["a"]) & 0xFF
	_set_nz(cpu, int(cpu["y"]))


func _cpu_tsx(cpu: Dictionary) -> void:
	cpu["x"] = int(cpu["sp"]) & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _bit(cpu: Dictionary, value: int) -> void:
	var a := int(cpu["a"]) & 0xFF
	var p := int(cpu["p"]) & (0xFF ^ (FLAG_NEGATIVE | FLAG_OVERFLOW | FLAG_ZERO))
	if (value & FLAG_NEGATIVE) != 0:
		p |= FLAG_NEGATIVE
	if (value & FLAG_OVERFLOW) != 0:
		p |= FLAG_OVERFLOW
	if (a & value & 0xFF) == 0:
		p |= FLAG_ZERO
	cpu["p"] = p
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | FLAG_NEGATIVE | FLAG_OVERFLOW | FLAG_ZERO


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := int(cpu["p"]) & (0xFF ^ (FLAG_NEGATIVE | FLAG_ZERO))
	if (value & 0x80) != 0:
		p |= FLAG_NEGATIVE
	if (value & 0xFF) == 0:
		p |= FLAG_ZERO
	cpu["p"] = p
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | FLAG_NEGATIVE | FLAG_ZERO


func _refused(message: String) -> Dictionary:
	return {"ok": false, "status": "source_state_required", "error": message,
		"rom_sha256": ROM_SHA256, "trace_state_used": false,
		"emulator_data_used": false, "d6c7_reached": false}


func _fail(message: String) -> bool:
	error_message = message
	return false
