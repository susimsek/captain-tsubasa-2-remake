extends RefCounted
class_name RomSlot09Worker86F8ZeroBranchExecutor
## Executes the live slot-$09 worker's zero, `$80 -> 0`, observed `$82`, and
## bounded scenario-$38 `$97->$17` callback stream paths at `$86F8`.
## This source-specific executor is not a general 6502 emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/slot09_86f8_worker/"
const WORKER_FILE := "bank18_slot09_worker_86F8_8778.bin"
const WORKER_START := 0x86F8
const WORKER_END_EXCLUSIVE := 0x8779
const WORKER_BANK := 0x18
const WORKER_OFFSET := "0x030708"
const WORKER_LENGTH := WORKER_END_EXCLUSIVE - WORKER_START
const WORKER_SHA256 := "ae998967ec1bb0e39ffcc72c8670a393946cfe233ad6845dc524870bd3264d23"
const SCRIPT82_POINTER_FILE := "bank19_slot09_worker_pointer_entry_AD70.bin"
const SCRIPT82_POINTER_START := 0xAD70
const SCRIPT82_POINTER_OFFSET := "0x032D80"
const SCRIPT82_POINTER_LENGTH := 2
const SCRIPT82_POINTER_SHA256 := "5f24206f29d50d608ef61ffb2f9769bc6b45c1a19b18c83fad005d1776fe5246"
const SCRIPT82_FILE := "bank19_slot09_worker_script82_ADFC_AE03.bin"
const SCRIPT82_START := 0xADFC
const SCRIPT82_OFFSET := "0x032E0C"
const SCRIPT82_LENGTH := 8
const SCRIPT82_SHA256 := "971e8ea5097a3c29ce567e8576135650c776555a9f6702c9211c5e90f95929c5"
const SCENARIO36_STREAM_FILE := "bank19_scenario36_worker_stream_AE03_AE0F.bin"
const SCENARIO36_STREAM_START := 0xAE03
const SCENARIO36_STREAM_END_EXCLUSIVE := 0xAE10
const SCENARIO36_STREAM_OFFSET := "0x032E13"
const SCENARIO36_STREAM_LENGTH := 0x0D
const SCENARIO36_STREAM_SHA256 := "702dadc3d845b2a68e10bbfcaa48c7f17483e3edb62cdb075850d2b7c4bccce6"
const SCENARIO1E_POINTER_FILE := "bank19_slot09_worker_pointer_entry_AD6E.bin"
const SCENARIO1E_POINTER_START := 0xAD6E
const SCENARIO1E_POINTER_OFFSET := "0x032D7E"
const SCENARIO1E_POINTER_SHA256 := "c8f33227c8180de1bf13f0f7aa7646a8b71d34414b68798f29adcd0121288dc8"
const SCENARIO1E_STREAM_FILE := "bank19_slot09_worker_stream_ADF6_AE0F.bin"
const SCENARIO1E_STREAM_START := 0xADF6
const SCENARIO1E_STREAM_END_EXCLUSIVE := 0xAE10
const SCENARIO1E_STREAM_OFFSET := "0x032E06"
const SCENARIO1E_STREAM_LENGTH := 0x1A
const SCENARIO1E_STREAM_SHA256 := "4c75eb86df7ce70a5474869459e14f5b9ff6b85b93dfdf3520f72106bf3e7ecb"
const SCENARIO38_POINTER_FILE := "bank19_slot09_worker_pointer_entries_AD9A_AD9E.bin"
const SCENARIO38_POINTER_START := 0xAD9A
const SCENARIO38_POINTER_OFFSET := "0x032DAA"
const SCENARIO38_POINTER_SHA256 := "349113b6943fd413d3fbf284b054e979a177c0ad91d360b25d68871a238a7dea"
const SCENARIO38_STREAM_FILE := "bank19_slot09_worker_stream_AFE6_AFF7.bin"
const SCENARIO38_STREAM_START := 0xAFE6
const SCENARIO38_STREAM_END_EXCLUSIVE := 0xAFF7
const SCENARIO38_STREAM_OFFSET := "0x032FF6"
const SCENARIO38_STREAM_LENGTH := 0x11
const SCENARIO38_STREAM_SHA256 := "948e5cc52fb136c62825d789cbda13529b5c7a29a93d7c7723d55990fbfe71b4"
const SCENARIO38_CALLBACK34_WORKER_RAM := [
	0x01, 0x40, 0x38, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x40, 0x17, 0x00, 0x00,
	0x00, 0x2C, 0x00, 0x2C, 0x97, 0x06, 0x80, 0x00, 0x80, 0x00, 0x00, 0x00]
const SCENARIO38_CALLBACK34_MAP2D := [
	0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00]
const APPEND_VECTOR_FILE := "fixed_inline_record_append_vector_C533.bin"
const APPEND_VECTOR_SHA256 := "447b2945aa7e5040be16cfa5135a9b4be42dac48166c962c6ae65c11fd443e74"
const APPEND_HANDLER_FILE := "fixed_inline_record_append_handler_CCD2_CD0C.bin"
const APPEND_HANDLER_SHA256 := "7c23b91502ce9ebf01c18cbf401030f35181dbdc359d245cc7d7d57dd2cbc37b"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_C := 0x01
const P_N := 0x80
const P_Z := 0x02
const P_V := 0x40
const P_NZ_MASK := P_N | P_Z

var error_message := ""
var _configured := false
var _worker_bytes := PackedByteArray()
var _script82_pointer_bytes := PackedByteArray()
var _script82_bytes := PackedByteArray()
var _scenario36_stream_bytes := PackedByteArray()
var _scenario1e_pointer_bytes := PackedByteArray()
var _scenario1e_stream_bytes := PackedByteArray()
var _scenario38_pointer_bytes := PackedByteArray()
var _scenario38_stream_bytes := PackedByteArray()
var _append_vector_bytes := PackedByteArray()
var _append_handler_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_worker_bytes = PackedByteArray()
	_script82_pointer_bytes = PackedByteArray()
	_script82_bytes = PackedByteArray()
	_scenario36_stream_bytes = PackedByteArray()
	_scenario1e_pointer_bytes = PackedByteArray()
	_scenario1e_stream_bytes = PackedByteArray()
	_scenario38_pointer_bytes = PackedByteArray()
	_scenario38_stream_bytes = PackedByteArray()
	_append_vector_bytes = PackedByteArray()
	_append_handler_bytes = PackedByteArray()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The `$86F8` worker source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("The `$86F8` worker source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var rom_variant: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-86f8-worker-source-v1" \
			or not rom_variant is Dictionary \
			or String(rom_variant.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or not spans_variant is Array:
		return _fail("The `$86F8` package targets an unsupported ROM or schema.")
	var worker_spec: Dictionary = {}
	for span_variant in spans_variant:
		if span_variant is Dictionary and String(span_variant.get("file", "")) == WORKER_FILE:
			worker_spec = span_variant
			break
	if worker_spec.is_empty():
		return _fail("The manifest omits the `$86F8` worker span.")
	if String(worker_spec.get("cpu_start", "")) != "0x86F8" \
			or String(worker_spec.get("cpu_end_exclusive", "")) != "0x8779" \
			or String(worker_spec.get("bank", "")) != "0x18" \
			or String(worker_spec.get("file_offset", "")) != WORKER_OFFSET \
			or int(worker_spec.get("length", -1)) != WORKER_LENGTH \
			or String(worker_spec.get("sha256", "")) != WORKER_SHA256:
		return _fail("The `$86F8` worker manifest mapping or hash does not match the supported ROM span.")
	_worker_bytes = FileAccess.get_file_as_bytes(SOURCE_ROOT + WORKER_FILE)
	if _worker_bytes.size() != WORKER_LENGTH \
			or _sha256(_worker_bytes) != WORKER_SHA256 \
			or String(worker_spec.get("bytes", "")).replace(" ", "").to_lower() != _worker_bytes.hex_encode():
		_worker_bytes = PackedByteArray()
		return _fail("The packaged `$86F8` worker bytes failed size/hash/manifest validation.")
	if not _expect_worker_bytes(WORKER_START, [0xAD, 0x32, 0x05, 0xF0, 0x25, 0x10, 0x1B, 0x29, 0x7F, 0x8D, 0x32, 0x05, 0xF0, 0x1C]) \
			or not _expect_worker_bytes(0x8722, [0x60]):
		_worker_bytes = PackedByteArray()
		return _fail("The zero-branch instruction bytes differ from `$86F8` LDA/BEQ and `$8722` RTS.")
	_script82_pointer_bytes = _load_manifest_span(manifest, SCRIPT82_POINTER_FILE,
		"0xAD70", "0xAD72", "0x19", SCRIPT82_POINTER_OFFSET,
		SCRIPT82_POINTER_LENGTH, SCRIPT82_POINTER_SHA256)
	_script82_bytes = _load_manifest_span(manifest, SCRIPT82_FILE,
		"0xADFC", "0xAE04", "0x19", SCRIPT82_OFFSET,
		SCRIPT82_LENGTH, SCRIPT82_SHA256)
	_scenario36_stream_bytes = _load_manifest_span(manifest, SCENARIO36_STREAM_FILE,
		"0xAE03", "0xAE10", "0x19", SCENARIO36_STREAM_OFFSET,
		SCENARIO36_STREAM_LENGTH, SCENARIO36_STREAM_SHA256)
	_scenario1e_pointer_bytes = _load_manifest_span(manifest, SCENARIO1E_POINTER_FILE,
		"0xAD6E", "0xAD70", "0x19", SCENARIO1E_POINTER_OFFSET,
		2, SCENARIO1E_POINTER_SHA256)
	_scenario1e_stream_bytes = _load_manifest_span(manifest, SCENARIO1E_STREAM_FILE,
		"0xADF6", "0xAE10", "0x19", SCENARIO1E_STREAM_OFFSET,
		SCENARIO1E_STREAM_LENGTH, SCENARIO1E_STREAM_SHA256)
	_scenario38_pointer_bytes = _load_manifest_span(manifest, SCENARIO38_POINTER_FILE,
		"0xAD9A", "0xAD9E", "0x19", SCENARIO38_POINTER_OFFSET,
		4, SCENARIO38_POINTER_SHA256)
	_scenario38_stream_bytes = _load_manifest_span(manifest, SCENARIO38_STREAM_FILE,
		"0xAFE6", "0xAFF7", "0x19", SCENARIO38_STREAM_OFFSET,
		SCENARIO38_STREAM_LENGTH, SCENARIO38_STREAM_SHA256)
	_append_vector_bytes = _load_manifest_span(manifest, APPEND_VECTOR_FILE,
		"0xC533", "0xC536", "0x1E", "0x03C543", 3, APPEND_VECTOR_SHA256)
	_append_handler_bytes = _load_manifest_span(manifest, APPEND_HANDLER_FILE,
		"0xCCD2", "0xCD0D", "0x1E", "0x03CCE2", 59, APPEND_HANDLER_SHA256)
	if _script82_pointer_bytes.size() != SCRIPT82_POINTER_LENGTH \
			or _script82_bytes.size() != SCRIPT82_LENGTH \
			or _append_vector_bytes != PackedByteArray([0x4C, 0xD2, 0xCC]) \
			or _append_handler_bytes.size() != 59 \
			or _script82_pointer_bytes != PackedByteArray([0xFC, 0xAD]) \
			or _script82_bytes != PackedByteArray([0x33, 0x0D, 0x1A, 0x0E, 0x1A, 0x0F, 0x3A, 0x32]) \
			or _scenario36_stream_bytes != PackedByteArray([
				0x32, 0x0E, 0x3A, 0x0F, 0x1A, 0x32, 0x0D, 0x3A, 0x0E, 0x1A, 0x01, 0xFC, 0xAD]) \
			or _scenario1e_pointer_bytes != PackedByteArray([0xF6, 0xAD]) \
			or _scenario1e_stream_bytes != PackedByteArray([
				0x21, 0x10, 0x0F, 0x09, 0x1F, 0x11, 0x33, 0x0D, 0x1A, 0x0E, 0x1A, 0x0F, 0x3A,
				0x32, 0x0E, 0x3A, 0x0F, 0x1A, 0x32, 0x0D, 0x3A, 0x0E, 0x1A, 0x01, 0xFC, 0xAD]) \
			or _scenario38_pointer_bytes != PackedByteArray([0xE6, 0xAF, 0xF7, 0xAF]) \
			or _scenario38_stream_bytes != PackedByteArray([
				0x21, 0x10, 0x0F, 0x0A, 0x1F, 0x11, 0x16, 0x30, 0x39,
				0x16, 0x30, 0x19, 0x16, 0x0F, 0x01, 0xEE, 0xAF]):
		return _fail("The ROM pointer, `$82` stream, or reused `$C533->$CCD2` helper source failed validation.")
	_configured = true
	return true


## Consumes `slot09_resume_result` from the live source-route runner. RAM,
## stack, mapper, and pending return state are copied from that result only.
func execute_from_slot09_resume_result(slot09_resume_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _rejected("Configure the hash-checked `$86F8` source span first.")
	var contract := _validate_live_resume_result(slot09_resume_result)
	if not bool(contract.get("ok", false)):
		return _rejected(String(contract.get("reason", "Invalid live slot-$09 resume result.")))
	var input_ram: PackedByteArray = slot09_resume_result["ram_image"]
	var input_stack: PackedByteArray = slot09_resume_result["stack_page"]
	var value := int(input_ram[0x0532])
	var scenario_id := int(input_ram[0x0518])
	if value not in [0, 0x01, 0x02, 0x17, 0x80, 0x81, 0x82, 0x97]:
		return _unsupported_branch(value,
			"The observed `$0532` value is outside the decoded zero, script, scenario-$1E, scenario-$36, and scenario-$38 branches.")
	if scenario_id == 0x38 and value == 0x97:
		return _execute_slot09_stream_followup(slot09_resume_result, input_ram, input_stack, false, true)
	if scenario_id == 0x38 and value == 0x17:
		return _execute_scenario38_countdown(slot09_resume_result, input_ram, input_stack)
	if scenario_id == 0x38 and value == 0x01:
		if int(input_ram[0x0533]) > 0:
			return _execute_scenario38_live_countdown(slot09_resume_result, input_ram, input_stack)
		return _execute_scenario38_next_stream_batch(slot09_resume_result, input_ram, input_stack)
	if scenario_id == 0x1E and value == 0x81:
		return _execute_slot09_stream_followup(slot09_resume_result, input_ram, input_stack, true)
	if scenario_id == 0x1E and value == 0x01:
		if int(input_ram[0x0533]) == 0:
			return _execute_slot09_stream_followup(slot09_resume_result, input_ram, input_stack, false)
		return _execute_scenario1e_countdown(slot09_resume_result, input_ram, input_stack)
	if value == 0x02:
		if int(input_ram[0x0533]) == 0:
			return _execute_slot09_stream_followup(slot09_resume_result, input_ram, input_stack, false)
		return _execute_scenario36_countdown(slot09_resume_result, input_ram, input_stack)
	if value == 0x82:
		return _execute_script82(slot09_resume_result, input_ram, input_stack)

	var output_ram := input_ram.duplicate()
	var output_stack := input_stack.duplicate()
	var cpu: Dictionary = slot09_resume_result["registers"].duplicate(true)
	var mapper: Dictionary = slot09_resume_result["mapper"].duplicate(true)
	var entry_registers: Dictionary = cpu.duplicate(true)
	var entry_pc := int(cpu["pc"])
	var stack_reads: Array[Dictionary] = []
	var executed_pcs: Array[int] = []

	# $86F8: LDA $0532. Only N/Z are defined by this instruction here.
	if not _expect_worker_bytes(entry_pc, [0xAD, 0x32, 0x05]):
		return _rejected("The live worker entry does not match the hash-checked `$86F8` source bytes.")
	executed_pcs.append(entry_pc)
	cpu["a"] = value
	cpu["p"] = _with_nz(int(cpu.get("p", 0)), value)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ_MASK
	cpu["pc"] = 0x86FB

	# $86FB: BEQ $8722. Zero returns directly; $80 follows the source
	# BPL/AND/STA/BEQ path, clearing only the high bit before returning.
	if not _expect_worker_bytes(0x86FB, [0xF0, 0x25]):
		return _rejected("The `$86FB` branch bytes differ from the hash-checked worker span.")
	executed_pcs.append(0x86FB)
	if value == 0:
		cpu["pc"] = 0x8722
	else:
		cpu["pc"] = 0x86FD
		if not _expect_worker_bytes(0x86FD, [0x10, 0x1B]):
			return _rejected("The `$86FD` BPL bytes differ from the hash-checked worker span.")
		executed_pcs.append(0x86FD)
		# A clear marker takes BPL to the countdown branch at `$871A`.
		# Only high-bit reset markers fall through to AND #$7F.
		if (int(cpu["p"]) & P_N) == 0:
			cpu["pc"] = 0x871A
			var stack_pointer := int(entry_registers.get("sp", -1))
			var stack_return := []
			if stack_pointer >= 0 and stack_pointer <= 0xFD:
				stack_return = [int(input_stack[(stack_pointer + 1) & 0xFF]),
					int(input_stack[(stack_pointer + 2) & 0xFF])]
			var live_profile := {
				"scenario_fields_0516_0519": input_ram.slice(0x0516, 0x051A).hex_encode(),
				"marker_0532": value, "countdown_0533": int(input_ram[0x0533]),
				"stream_pointer_0079_007a": int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8),
				"callback_cursor_003a": int(input_ram[0x003A]),
				"stream_control_046f_047f": input_ram.slice(0x046F, 0x0480).hex_encode(),
				"queue_cursor_0498": int(input_ram[0x0498]),
				"queue_bytes_0498_049f": input_ram.slice(0x0498, 0x04A0).hex_encode(),
				"queue_records_0499_04a5": input_ram.slice(0x0499, 0x04A5).hex_encode(),
				"queue_control_0515_0519": input_ram.slice(0x0515, 0x0519).hex_encode(),
				"slot09_record_0009_000c": input_ram.slice(0x0009, 0x000D).hex_encode(),
				"cpu": entry_registers, "stack_sp": stack_pointer,
				"stack_return_bytes": stack_return,
				"mapper": mapper, "trace_state_used": false,
			}
			return _unsupported_branch(value,
				"The live positive `$0532` marker takes the source `$86FD->$871A` countdown branch: " \
					+ JSON.stringify(live_profile), 0x871A)
		cpu["pc"] = 0x86FF
		if not _expect_worker_bytes(0x86FF, [0x29, 0x7F]):
			return _rejected("The `$86FF` AND bytes differ from the hash-checked worker span.")
		executed_pcs.append(0x86FF)
		_set_a(cpu, int(cpu["a"]) & 0x7F)
		cpu["pc"] = 0x8701
		if not _expect_worker_bytes(0x8701, [0x8D, 0x32, 0x05]):
			return _rejected("The `$8701` STA bytes differ from the hash-checked worker span.")
		executed_pcs.append(0x8701)
		_write_ram(output_ram, 0x8701, 0x0532, int(cpu["a"]))
		cpu["pc"] = 0x8704
		if not _expect_worker_bytes(0x8704, [0xF0, 0x1C]) or (int(cpu["p"]) & P_Z) == 0:
			return _rejected("Normalized `$0532` did not take the source `$8704->$8722` branch.")
		executed_pcs.append(0x8704)
		cpu["pc"] = 0x8722

	# $8722: RTS. Pop the caller's actual $EBB2 return word; do not erase the
	# stack bytes, and do not execute the following $8006/$8779 worker call.
	if not _expect_worker_bytes(0x8722, [0x60]):
		return _rejected("The `$8722` return opcode differs from the hash-checked worker span.")
	executed_pcs.append(0x8722)
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var return_low := int(output_stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp, "value": return_low, "kind": "RTS_low"})
	sp = (sp + 1) & 0xFF
	var return_high := int(output_stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp, "value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if int(cpu["pc"]) != 0xEBB3:
		return _rejected("The source RTS did not return to the verified `$EBB3` caller boundary.")

	return {
		"ok": true,
		"status": "returned_to_root_caller",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]),
		"entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)),
		"input_ram_0532": value,
		"output_ram_0532": int(output_ram[0x0532]),
		"entry_registers": entry_registers,
		"registers": cpu,
		"mapper": mapper,
		"ram_image": output_ram,
		"stack_page": output_stack,
		"memory_writes": ([{"pc": 0x8701, "address": 0x0532,
			"value": 0, "kind": "ram"}] if value == 0x80 else []),
		"stack_reads": stack_reads,
		"stack_writes": [],
		"instruction_pcs": executed_pcs,
		"return_word": return_word,
		"return_pc": int(cpu["pc"]),
		"next_worker_executed": false,
		"next_worker_bytes_read": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


## Executes the scenario-$38 callback-$34 timer tick after its first `$AFE6`
## stream batch. The ROM's positive-marker path decrements `$0533` at `$871F`
## and returns at `$8722`; a zero countdown takes the separate `$8723` parser
## path and is intentionally left to a later bounded increment.
func _execute_scenario38_countdown(resume_result: Dictionary,
		input_ram: PackedByteArray, input_stack: PackedByteArray) -> Dictionary:
	var countdown := int(input_ram[0x0533])
	var pointer := int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8)
	var callback34_base_profile := int(input_ram[0x0516]) == 0x29 \
			and input_ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x38, 0x00]) \
			and input_ram.slice(0x0523, 0x052B) == PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x00]) \
			and input_ram.slice(0x05C7, 0x05D3) == PackedByteArray(SCENARIO38_CALLBACK34_MAP2D) \
			and int(input_ram[0x0522]) == 0 \
			and int(input_ram[0x052B]) == 0 \
			and int(input_ram[0x0532]) == 0x17 \
			and pointer == 0xAFE9 and int(input_ram[0x003A]) == 0x01
	var ordinary_route_countdown_queue := countdown > 0 \
			and int(input_ram[0x0498]) == 0x02 \
			and input_ram.slice(0x049C, 0x049F) == PackedByteArray([0x00, 0x6C, 0x04]) \
			and int(input_ram[0x047F]) == 0x0F
	var synthetic_drained_queue := countdown == 0 \
			and input_ram.slice(0x0498, 0x049C) == PackedByteArray([0x00, 0x00, 0x00, 0x00]) \
			and int(input_ram[0x047F]) == 0x00
	if not callback34_base_profile or not (ordinary_route_countdown_queue or synthetic_drained_queue):
		return _unsupported_branch(0x17,
			"Scenario-$38 `$86F8` countdown input does not match the post-`$B7CC/$FB` callback-$34/descriptor-queue signature: phase=$%02X/$%02X/$%02X/$%02X countdown=$%02X pointer=$%04X append=$%02X queue=$%s palette=$%02X cursor=$%02X." % [
			int(input_ram[0x0516]), int(input_ram[0x0517]), int(input_ram[0x0518]),
			int(input_ram[0x0519]), countdown, pointer, int(input_ram[0x0498]),
			input_ram.slice(0x049C, 0x049F).hex_encode(), int(input_ram[0x047F]), int(input_ram[0x003A])])
	if countdown == 0:
		return _execute_scenario38_next_stream_batch(resume_result, input_ram, input_stack)
	if countdown < 1 or countdown > 4:
		return _unsupported_branch(0x17,
			"Scenario-$38 callback-$34 countdown is outside the first ROM `$AFE6` batch range 1..4.",
			0x871A)
	if not _expect_worker_bytes(0x86F8, [0xAD, 0x32, 0x05, 0xF0, 0x25, 0x10, 0x1B]) \
			or not _expect_worker_bytes(0x871A, [0xAD, 0x33, 0x05, 0xF0, 0x04, 0xCE, 0x33, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x8722, [0x60]):
		return _rejected("The scenario-$38 countdown differs from the hash-checked `$86F8->$871A->$8722` bytes.")
	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = (resume_result["registers"] as Dictionary).duplicate(true)
	var mapper: Dictionary = (resume_result["mapper"] as Dictionary).duplicate(true)
	var entry_registers := cpu.duplicate(true)
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D, 0x871F, 0x8722]
	_set_a(cpu, int(ram[0x0532]))
	if (int(cpu["p"]) & P_Z) != 0 or (int(cpu["p"]) & P_N) != 0:
		return _rejected("Scenario-$38 marker `$17` did not take the ROM `$86FD->$871A` positive-countdown branch.")
	_set_a(cpu, int(ram[0x0533]))
	if (int(cpu["p"]) & P_Z) != 0:
		return _rejected("The source scenario-$38 countdown unexpectedly selected the `$8723` stream reader.")
	var next_countdown := (countdown - 1) & 0xFF
	_set_nz(cpu, next_countdown)
	_write_with_log(ram, writes, 0x871F, 0x0533, next_countdown)
	var return_sp := (int(cpu["sp"]) + 1) & 0xFF
	var return_low := int(stack[return_sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | return_sp,
		"value": return_low, "kind": "RTS_low"})
	return_sp = (return_sp + 1) & 0xFF
	var return_high := int(stack[return_sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | return_sp,
		"value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = return_sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if int(cpu["pc"]) != 0xEBB3:
		return _rejected("Scenario-$38 `$8722` RTS did not return to the verified `$EBB3` caller boundary.")
	return {
		"ok": true, "status": "returned_after_countdown", "rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH, "entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]), "entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)), "input_ram_0532": 0x17,
		"output_ram_0532": int(ram[0x0532]), "input_ram_0533": countdown,
		"countdown_before": countdown, "countdown_after": next_countdown,
		"stream_pointer": pointer, "entry_registers": entry_registers,
		"registers": cpu, "mapper": mapper, "ram_image": ram, "stack_page": stack,
		"memory_writes": writes.duplicate(true), "ram_writes": writes.duplicate(true),
		"mapper_writes": [], "stack_reads": stack_reads.duplicate(true), "stack_writes": [],
		"instruction_pcs": instruction_pcs.duplicate(), "return_word": return_word,
		"return_pc": int(cpu["pc"]), "next_worker_executed": false,
		"next_worker_bytes_read": false, "ppu_bus_events": [], "apu_register_writes": [],
		"ppu_apu_effects_applied": false, "trace_state_used": false,
		"nmi_cadence_generated": false,
	}


## Executes the ordinary PASS route's live `$0532=$01` timer tick. This is a
## separate profile from callback-$34's `$17` marker above: the source path is
## `$86F8->$86FD->$871A`, where ROM `$871F` decrements only `$0533` before the
## real `$8722` RTS. The source route supplies the complete CPU/RAM/stack state.
func _execute_scenario38_live_countdown(resume_result: Dictionary,
		input_ram: PackedByteArray, input_stack: PackedByteArray) -> Dictionary:
	var countdown := int(input_ram[0x0533])
	var pointer := int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8)
	# ROM `$871A` reads only `$0533` on this positive-count path. The later
	# `$8723` parser overwrites `$003A` with the pair count before its first use.
	var live_pass_profile := input_ram.slice(0x0516, 0x051A) \
			== PackedByteArray([0x00, 0x40, 0x38, 0x00]) \
			and int(input_ram[0x0532]) == 0x01 and countdown > 0 \
			and pointer in [0xAFE9, 0xAFEE, 0xAFF1, 0xAFF4] \
			and int(input_ram[0x0498]) == 0x00 \
			and input_ram.slice(0x0499, 0x04A0) \
			== PackedByteArray([0x00, 0x6C, 0x04, 0x00, 0x6C, 0x04, 0x00])
	if not live_pass_profile:
		return _unsupported_branch(0x01,
			"The scenario-$38 live timer tick does not match the recorded source route: phase=$%s countdown=$%02X pointer=$%04X cursor=$%02X queue=$%s." % [
			input_ram.slice(0x0516, 0x051A).hex_encode(), countdown, pointer,
			int(input_ram[0x003A]), input_ram.slice(0x0498, 0x04A0).hex_encode()], 0x871A)
	if not _expect_worker_bytes(0x86F8, [0xAD, 0x32, 0x05, 0xF0, 0x25, 0x10, 0x1B]) \
			or not _expect_worker_bytes(0x871A, [0xAD, 0x33, 0x05, 0xF0, 0x04, 0xCE, 0x33, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x8722, [0x60]):
		return _rejected("The live scenario-$38 timer tick differs from the hash-checked `$86F8->$871A->$8722` ROM bytes.")
	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = (resume_result["registers"] as Dictionary).duplicate(true)
	var mapper: Dictionary = (resume_result["mapper"] as Dictionary).duplicate(true)
	var entry_registers := cpu.duplicate(true)
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D, 0x871F, 0x8722]
	_set_a(cpu, int(ram[0x0532]))
	if (int(cpu["p"]) & P_Z) != 0 or (int(cpu["p"]) & P_N) != 0:
		return _rejected("The live scenario-$38 `$01` marker did not take `$86FD->$871A`.")
	_set_a(cpu, int(ram[0x0533]))
	if (int(cpu["p"]) & P_Z) != 0:
		return _rejected("The positive live countdown unexpectedly selected the `$8723` parser.")
	var next_countdown := (countdown - 1) & 0xFF
	_set_nz(cpu, next_countdown)
	_write_with_log(ram, writes, 0x871F, 0x0533, next_countdown)
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var return_low := int(stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp,
		"value": return_low, "kind": "RTS_low"})
	sp = (sp + 1) & 0xFF
	var return_high := int(stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp,
		"value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if int(cpu["pc"]) != 0xEBB3:
		return _rejected("The live scenario-$38 `$8722` RTS did not return to `$EBB3`.")
	return {
		"ok": true, "status": "returned_after_countdown", "rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH, "entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]), "entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)), "input_ram_0532": 0x01,
		"output_ram_0532": int(ram[0x0532]), "input_ram_0533": countdown,
		"countdown_before": countdown, "countdown_after": next_countdown,
		"stream_pointer": pointer, "entry_registers": entry_registers,
		"registers": cpu, "mapper": mapper, "ram_image": ram, "stack_page": stack,
		"memory_writes": writes.duplicate(true), "ram_writes": writes.duplicate(true),
		"mapper_writes": [], "stack_reads": stack_reads.duplicate(true), "stack_writes": [],
		"instruction_pcs": instruction_pcs, "return_word": return_word,
		"return_pc": int(cpu["pc"]), "next_worker_executed": false,
		"next_worker_bytes_read": false, "ppu_bus_events": [], "apu_register_writes": [],
		"ppu_apu_effects_applied": false, "trace_state_used": false,
		"nmi_cadence_generated": false,
	}


## Executes scenario-$38's bounded `$8723` batch at `$AFE9` for either the
## callback-$34 fixture profile or the ordinary-input PASS route. Each profile
## has its own strict RAM gate; both then share the hash-checked ROM parser and
## inline queue append path.
func _execute_scenario38_next_stream_batch(resume_result: Dictionary,
		input_ram: PackedByteArray, input_stack: PackedByteArray) -> Dictionary:
	var pointer := int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8)
	var callback34_profile := int(input_ram[0x0516]) == 0x29 \
			and input_ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x38, 0x00]) \
			and input_ram.slice(0x0523, 0x052B) == PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x00]) \
			and input_ram.slice(0x05C7, 0x05D3) == PackedByteArray(SCENARIO38_CALLBACK34_MAP2D) \
			and int(input_ram[0x0522]) == 0 and int(input_ram[0x052B]) == 0 \
			and int(input_ram[0x0532]) == 0x17 and int(input_ram[0x0533]) == 0 \
			and pointer == 0xAFE9 and int(input_ram[0x003A]) == 0x01 \
			and input_ram.slice(0x0498, 0x049C) == PackedByteArray([0x00, 0x00, 0x00, 0x00]) \
			and int(input_ram[0x047F]) == 0x00
	var live_pass_profile := input_ram.slice(0x0516, 0x051A) \
			== PackedByteArray([0x00, 0x40, 0x38, 0x00]) \
			and int(input_ram[0x0532]) == 0x01 and int(input_ram[0x0533]) == 0 \
			and pointer in [0xAFE9, 0xAFEE, 0xAFF1, 0xAFF4] \
			and int(input_ram[0x0498]) == 0x00 \
			and input_ram.slice(0x0499, 0x04A0) \
			== PackedByteArray([0x00, 0x6C, 0x04, 0x00, 0x6C, 0x04, 0x00]) \
			and int(input_ram[0x047F]) == 0x0F
	if not callback34_profile and not live_pass_profile:
		return _unsupported_branch(0x01 if int(input_ram[0x0532]) == 0x01 else 0x17,
			"Scenario-$38 `$8723` input does not match either the callback-$34 or live PASS `$AFE9` profile: phase=$%s marker=$%02X countdown=$%02X pointer=$%04X queue=$%s cursor=$%02X." % [
			input_ram.slice(0x0516, 0x051A).hex_encode(), int(input_ram[0x0532]),
			int(input_ram[0x0533]), pointer, input_ram.slice(0x0498, 0x04A0).hex_encode(),
			int(input_ram[0x003A])], 0x8723)
	var selector_redirect := pointer == 0xAFF4
	var stream_pointer := pointer
	var selector_low := -1
	var selector_high := -1
	if selector_redirect:
		selector_low = _scenario36_stream_byte(0xAFF5)
		selector_high = _scenario36_stream_byte(0xAFF6)
		if _scenario36_stream_byte(0xAFF4) != 0x01 \
				or selector_low != 0xEE or selector_high != 0xAF:
			return _rejected("The live scenario-$38 `$AFF4` selector no longer redirects through its ROM bytes `$01,$EE,$AF`.")
		stream_pointer = selector_low | (selector_high << 8)
	var expected_control := -1
	var expected_pair_bytes := PackedByteArray()
	var expected_pair_count := -1
	var expected_countdown := -1
	match stream_pointer:
		0xAFE9:
			expected_control = 0x0A
			expected_pair_bytes = PackedByteArray([0x1F, 0x11, 0x16, 0x30])
			expected_pair_count = 2
			expected_countdown = 1
		0xAFEE:
			expected_control = 0x39
			expected_pair_bytes = PackedByteArray([0x16, 0x30])
			expected_pair_count = 1
			expected_countdown = 7
		0xAFF1:
			expected_control = 0x19
			expected_pair_bytes = PackedByteArray([0x16, 0x0F])
			expected_pair_count = 1
			expected_countdown = 3
		_:
			return _unsupported_branch(0x17,
				"The live scenario-$38 stream pointer `$%04X` is not in a decoded batch profile." % stream_pointer, 0x8723)
	var source_pair_bytes := PackedByteArray()
	for byte_index in expected_pair_bytes.size():
		source_pair_bytes.append(_scenario36_stream_byte(stream_pointer + 1 + byte_index))
	if _scenario38_stream_bytes.size() != SCENARIO38_STREAM_LENGTH \
			or _scenario36_stream_byte(stream_pointer) != expected_control \
			or source_pair_bytes != expected_pair_bytes:
		return _rejected("The scenario-$38 `$%04X` control and pair bytes differ from the pinned ROM stream." % stream_pointer)
	if not _expect_worker_bytes(0x86F8, [0xAD, 0x32, 0x05, 0xF0, 0x25, 0x10, 0x1B]) \
			or not _expect_worker_bytes(0x871A, [0xAD, 0x33, 0x05, 0xF0, 0x04, 0xCE, 0x33, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x8723, [0xA0, 0x00, 0xB1, 0x79, 0x29, 0x07]) \
			or not _expect_worker_bytes(0x873C, [0x8D, 0x33, 0x05, 0xB1, 0x79, 0x29, 0x07, 0x85, 0x3A]) \
			or not _expect_worker_bytes(0x8745, [0xC8, 0xB1, 0x79, 0xAA, 0xC8, 0xB1, 0x79, 0x9D, 0x6F, 0x04]) \
			or not _expect_worker_bytes(0x8752, [0xD0, 0xF2, 0x98, 0x18, 0x65, 0x79, 0x85, 0x79, 0x90, 0x02, 0xE6, 0x7A]) \
			or not _expect_worker_bytes(0x875E, [0x20, 0x33, 0xC5]) \
			or not _expect_worker_bytes(0x8761, [0x00, 0x6C, 0x04, 0x60]):
		return _rejected("The `$8723->$8764` stream batch or append return bytes differ from the hash-checked ROM worker.")
	if _append_vector_bytes != PackedByteArray([0x4C, 0xD2, 0xCC]) \
			or _append_handler_bytes.size() != 59:
		return _rejected("The source `$C533->$CCD2` append helper is unavailable for the `$AFE9` batch.")

	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = (resume_result["registers"] as Dictionary).duplicate(true)
	var mapper: Dictionary = (resume_result["mapper"] as Dictionary).duplicate(true)
	var entry_registers := cpu.duplicate(true)
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D]
	if selector_redirect:
		instruction_pcs.append_array([0x8723, 0x8725, 0x8727, 0x8729, 0x872A,
			0x872C, 0x872D, 0x872E, 0x872F, 0x8731, 0x8733, 0x8735, 0x8737,
			0x876B, 0x876C, 0x876E, 0x876F, 0x8770, 0x8772, 0x8774, 0x8776])
		source_reads.append(_source_read(0x8725, 0xAFF4, 0x01, "scenario_stream_selector"))
		source_reads.append(_source_read(0x876C, 0xAFF5, selector_low, "stream_redirect_low"))
		source_reads.append(_source_read(0x8770, 0xAFF6, selector_high, "stream_redirect_high"))
		_set_y(cpu, 1)
		_set_x(cpu, selector_low)
		_set_y(cpu, 2)
		_set_a(cpu, selector_high)
		_write_with_log(ram, writes, 0x8772, 0x007A, selector_high)
		_write_with_log(ram, writes, 0x8774, 0x0079, selector_low)
		cpu["pc"] = 0x8723
	instruction_pcs.append_array([0x8723, 0x8725, 0x8727, 0x8729, 0x872A,
		0x872C, 0x872D, 0x872E, 0x872F])
	_set_a(cpu, int(ram[0x0532]))
	if (int(cpu["p"]) & P_Z) != 0 or (int(cpu["p"]) & P_N) != 0:
		return _rejected("Scenario-$38 marker did not take the source `$86FD->$871A` path.")
	_set_a(cpu, int(ram[0x0533]))
	if (int(cpu["p"]) & P_Z) == 0:
		return _rejected("The source `$871D` branch did not select `$8723` with zero countdown.")
	_set_y(cpu, 0)

	var control := _scenario36_stream_byte(stream_pointer)
	source_reads.append(_source_read(0x8725, stream_pointer, control, "scenario_stream_control"))
	_set_a(cpu, control & 0x07)
	_set_x(cpu, int(cpu["a"]))
	_set_a(cpu, control)
	for _shift in 3:
		_lsr_a(cpu)
	var countdown := int(cpu["a"])
	var pair_count := int(cpu["x"])
	if pair_count != expected_pair_count or countdown != expected_countdown:
		return _unsupported_branch(0x17,
			"The scenario-$38 `$%04X` control is outside its verified pair/countdown batch." % pointer, 0x8723)
	_write_with_log(ram, writes, 0x873C, 0x0533, countdown)
	_set_a(cpu, control & 0x07)
	_write_with_log(ram, writes, 0x8743, 0x003A, pair_count)
	_set_y(cpu, 1)
	instruction_pcs.append_array([0x873C, 0x873F, 0x8741, 0x8743, 0x8745])
	for _pair_index in range(pair_count):
		var index_address := stream_pointer + int(cpu["y"])
		var ram_index := _scenario36_stream_byte(index_address)
		if ram_index < 0:
			return _unsupported_branch(0x17, "The `$AFE9` index byte is outside the checked ROM stream.", 0x8723)
		source_reads.append(_source_read(0x8746, index_address, ram_index, "ram_destination_index"))
		_set_a(cpu, ram_index)
		_set_x(cpu, int(cpu["a"]))
		_set_y(cpu, int(cpu["y"]) + 1)
		var value_address := stream_pointer + int(cpu["y"])
		var ram_value := _scenario36_stream_byte(value_address)
		if ram_value < 0:
			return _unsupported_branch(0x17, "The `$AFE9` value byte is outside the checked ROM stream.", 0x8723)
		source_reads.append(_source_read(0x8749, value_address, ram_value, "ram_destination_value"))
		_set_a(cpu, ram_value)
		_write_with_log(ram, writes, 0x874C, 0x046F + int(cpu["x"]), int(cpu["a"]))
		_set_y(cpu, int(cpu["y"]) + 1)
		var remaining := (int(ram[0x003A]) - 1) & 0xFF
		_write_with_log(ram, writes, 0x8752, 0x003A, remaining)
		instruction_pcs.append_array([0x8746, 0x8748, 0x8749, 0x874B, 0x874C, 0x874F, 0x8750, 0x8752])
		_set_nz(cpu, remaining)
	if int(ram[0x003A]) != 0 or int(cpu["y"]) != 1 + 2 * pair_count:
		return _rejected("The `$AFE9` pair loop did not finish at its source Y/count boundary.")
	instruction_pcs.append_array([0x8754, 0x8755, 0x8756, 0x8758, 0x875E])
	_set_a(cpu, int(cpu["y"]))
	_set_flag(cpu, P_C, false)
	var low_sum := int(ram[0x0079]) + int(cpu["a"])
	_set_a(cpu, low_sum)
	_set_flag(cpu, P_C, low_sum > 0xFF)
	_write_with_log(ram, writes, 0x8758, 0x0079, int(cpu["a"]))
	if low_sum > 0xFF:
		var high_pointer := (int(ram[0x007A]) + 1) & 0xFF
		_write_with_log(ram, writes, 0x875C, 0x007A, high_pointer)
		_set_nz(cpu, high_pointer)
	stream_pointer = int(ram[0x0079]) | (int(ram[0x007A]) << 8)
	var inline_result := _append_worker_inline_record(cpu, ram, stack,
		writes, stack_writes, stack_reads, source_reads, instruction_pcs)
	if not bool(inline_result.get("ok", false)):
		return _rejected(String(inline_result.get("reason", "Scenario-$38 inline queue append failed.")))
	var root_return_result := _return_worker_to_root(cpu, stack, stack_reads, instruction_pcs)
	if not bool(root_return_result.get("ok", false)):
		return _rejected(String(root_return_result.get("reason", "Scenario-$38 stream RTS failed.")))
	var result := _scenario_stream_result("returned_after_stream_batch", pointer, stream_pointer,
		control, pair_count, countdown, entry_registers, cpu, mapper, ram, stack,
		writes, stack_writes, stack_reads, source_reads, instruction_pcs,
		inline_result.get("queue_record", PackedByteArray()), int(ram[0x0532]), 0)
	if selector_redirect:
		result["selector_redirect_from"] = 0xAFF4
		result["selector_redirect_to"] = 0xAFEE
		result["selector_arm_appended_queue"] = false
	return result


func _execute_scenario36_countdown(resume_result: Dictionary,
		input_ram: PackedByteArray, input_stack: PackedByteArray) -> Dictionary:
	var countdown := int(input_ram[0x0533])
	var pointer := int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8)
	var is_f7_marker := int(input_ram[0x0523]) == 0x32 and int(input_ram[0x0524]) == 0x1F \
			and int(input_ram[0x0528]) == 0x4C and int(input_ram[0x0529]) == 0xFF \
			and countdown >= 1 and countdown <= 6 \
			and pointer in [0xAE03, 0xAE08, 0xAE0D] and int(input_ram[0x003A]) == 0x06
	var f9_stream_tick := pointer in [0xAE03, 0xAE08, 0xAE0D] \
			and countdown >= 1 and countdown <= 6 and int(input_ram[0x003A]) == 0x06
	var f9_ae08_cursor_carryover := pointer == 0xAE08 and countdown == 3 \
			and int(input_ram[0x003A]) == 0x07
	var is_f9_followup_marker := int(input_ram[0x0523]) == 0x3E and int(input_ram[0x0524]) == 0x01 \
			and int(input_ram[0x0528]) == 0xE6 and int(input_ram[0x0529]) == 0x75 \
			and (f9_stream_tick or f9_ae08_cursor_carryover)
	if int(input_ram[0x0516]) not in [0x01, 0x61, 0x71] or int(input_ram[0x0518]) != 0x36 \
			or not (is_f7_marker or is_f9_followup_marker):
		return _unsupported_branch(0x02,
			"The live `$02` marker signature differs: scenario=$%02X/$%02X fields=$%02X/$%02X/$%02X/$%02X countdown=$%02X pointer=$%04X cursor=$%02X." % [
			int(input_ram[0x0516]), int(input_ram[0x0518]), int(input_ram[0x0523]),
			int(input_ram[0x0524]), int(input_ram[0x0528]), int(input_ram[0x0529]),
			countdown, pointer, int(input_ram[0x003A])])
	if not _expect_worker_bytes(0x86F8, [0xAD, 0x32, 0x05, 0xF0, 0x25, 0x10, 0x1B]) \
			or not _expect_worker_bytes(0x871A, [0xAD, 0x33, 0x05, 0xF0, 0x04, 0xCE, 0x33, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x8722, [0x60]):
		return _rejected("The scenario-$36 countdown branch differs from the hash-checked `$86F8` bytes.")
	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = resume_result["registers"].duplicate(true)
	var mapper: Dictionary = resume_result["mapper"].duplicate(true)
	var entry_registers: Dictionary = cpu.duplicate(true)
	var executed_pcs: Array[int] = [0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D, 0x871F, 0x8722]
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	_set_a(cpu, int(ram[0x0532]))
	cpu["pc"] = 0x86FB
	if (int(cpu["p"]) & P_Z) != 0:
		return _rejected("The live `$86FB` BEQ unexpectedly selects the zero return for `$0532=$02`.")
	cpu["pc"] = 0x86FD
	if (int(cpu["p"]) & P_N) != 0:
		return _rejected("The live `$86FD` BPL does not select the `$871A` countdown path.")
	_set_a(cpu, int(ram[0x0533]))
	cpu["pc"] = 0x871D
	if (int(cpu["p"]) & P_Z) != 0:
		return _unsupported_branch(0x02,
			"The `$0533=0` stream-reader successor at `$8723` is not implemented.")
	var next_countdown := (int(ram[0x0533]) - 1) & 0xFF
	_set_nz(cpu, next_countdown)
	_write_with_log(ram, writes, 0x871F, 0x0533, next_countdown)
	cpu["pc"] = 0x8722
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var return_low := int(stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp,
		"value": return_low, "kind": "RTS_low"})
	sp = (sp + 1) & 0xFF
	var return_high := int(stack[sp])
	stack_reads.append({"pc": 0x8722, "address": 0x0100 | sp,
		"value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if int(cpu["pc"]) != 0xEBB3:
		return _rejected("The scenario-$36 countdown RTS did not return to `$EBB3`.")
	return {
		"ok": true,
		"status": "returned_after_countdown",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]),
		"entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)),
		"input_ram_0532": 0x02,
		"output_ram_0532": int(ram[0x0532]),
		"entry_registers": entry_registers,
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"memory_writes": writes.duplicate(true),
		"ram_writes": writes.duplicate(true),
		"stack_reads": stack_reads,
		"stack_writes": [],
		"instruction_pcs": executed_pcs,
		"return_word": return_word,
		"return_pc": int(cpu["pc"]),
		"countdown_before": countdown,
		"countdown_after": next_countdown,
		"stream_pointer": pointer,
		"next_worker_executed": false,
		"next_worker_bytes_read": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


func _execute_scenario1e_countdown(resume_result: Dictionary,
		input_ram: PackedByteArray, input_stack: PackedByteArray) -> Dictionary:
	var countdown := int(input_ram[0x0533])
	var pointer := int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8)
	var callback45_profile := int(input_ram[0x0518]) == 0x1E \
			and int(input_ram[0x0516]) in [0x01, 0x29] \
			and int(input_ram[0x0519]) <= 0x07 \
			and input_ram.slice(0x0523, 0x052A) == PackedByteArray([0x07, 0x45, 0x06, 0x00, 0x3C, 0x90, 0xFF]) \
			and int(input_ram[0x05CE]) == 0x80 \
			and pointer in [0xADF9, 0xADFC, 0xAE03, 0xAE08, 0xAE0D] \
			and countdown >= 1 and countdown <= 6
	if int(input_ram[0x0532]) != 0x01 or not callback45_profile:
		return _unsupported_branch(0x01,
			"The scenario-$1E countdown does not match callback-$45 RAM, stream pointer, and positive `$0533` evidence.")
	if not _expect_worker_bytes(0x871A, [0xAD, 0x33, 0x05, 0xF0, 0x04, 0xCE, 0x33, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x8722, [0x60]):
		return _rejected("The scenario-$1E countdown differs from hash-checked `$871A->$8722` ROM bytes.")
	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = (resume_result["registers"] as Dictionary).duplicate(true)
	var mapper: Dictionary = (resume_result["mapper"] as Dictionary).duplicate(true)
	var entry_registers := cpu.duplicate(true)
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D, 0x871F, 0x8722]
	_set_a(cpu, int(ram[0x0532]))
	if (int(cpu["p"]) & P_Z) != 0 or (int(cpu["p"]) & P_N) != 0:
		return _rejected("The recorded scenario-$1E `$01` marker did not take the `$871A` countdown path.")
	_set_a(cpu, int(ram[0x0533]))
	if (int(cpu["p"]) & P_Z) != 0:
		return _rejected("The positive scenario-$1E countdown unexpectedly selected `$8723`.")
	var next_countdown := (countdown - 1) & 0xFF
	_set_nz(cpu, next_countdown)
	_write_with_log(ram, writes, 0x871F, 0x0533, next_countdown)
	var returned := _return_worker_to_root(cpu, stack, stack_reads, instruction_pcs)
	if not bool(returned.get("ok", false)):
		return _rejected(String(returned.get("reason", "Scenario-$1E countdown RTS failed.")))
	return {
		"ok": true, "status": "returned_after_countdown", "rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH, "entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]), "entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)), "input_ram_0532": 0x01,
		"output_ram_0532": int(ram[0x0532]), "input_ram_0533": countdown,
		"countdown_before": countdown, "countdown_after": next_countdown,
		"stream_pointer": pointer, "entry_registers": entry_registers,
		"registers": cpu, "mapper": mapper, "ram_image": ram, "stack_page": stack,
		"memory_writes": writes.duplicate(true), "ram_writes": writes.duplicate(true),
		"mapper_writes": [], "stack_reads": stack_reads.duplicate(true), "stack_writes": [],
		"instruction_pcs": instruction_pcs.duplicate(), "return_word": int(returned.get("return_word", -1)),
		"return_pc": int(cpu["pc"]), "next_worker_executed": false,
		"next_worker_bytes_read": false, "ppu_bus_events": [], "apu_register_writes": [],
		"ppu_apu_effects_applied": false, "trace_state_used": false,
		"nmi_cadence_generated": false,
	}


## Resumes the ROM's `$8723` stream reader when the scenario-$36 countdown
## reaches zero. Only the checked `$AE03/$AE08/$AE0D -> $ADFC` stream cycle is
## accepted; the control byte, RAM writes, queue append, and RTS all come from
## the live source state and ROM-derived bytes.
func _execute_slot09_stream_followup(resume_result: Dictionary,
		input_ram: PackedByteArray, input_stack: PackedByteArray,
		scenario1e_initial_marker: bool = false,
		scenario38_initial_marker: bool = false) -> Dictionary:
	var scenario_id := int(input_ram[0x0518])
	var input_marker := int(input_ram[0x0532])
	var input_countdown := int(input_ram[0x0533])
	var ram_pointer := int(input_ram[0x0079]) | (int(input_ram[0x007A]) << 8)
	var scenario1e_callback45_profile := scenario_id == 0x1E \
			and int(input_ram[0x0516]) in [0x01, 0x29] \
			and int(input_ram[0x0519]) <= 0x07 \
			and input_ram.slice(0x0523, 0x052A) == PackedByteArray([0x07, 0x45, 0x06, 0x00, 0x3C, 0x90, 0xFF]) \
			and int(input_ram[0x05CE]) == 0x80
	var scenario1e_marker_profile := scenario1e_initial_marker and input_marker == 0x81 \
			and scenario1e_callback45_profile and int(input_ram[0x0516]) == 0x01 \
			and input_ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x40, 0x1E, 0x07])
	var scenario1e_followup_profile := not scenario1e_initial_marker and input_marker == 0x01 \
			and scenario1e_callback45_profile and ram_pointer in [0xADF9, 0xADFC, 0xAE03, 0xAE08, 0xAE0D]
	var scenario38_callback34_profile := scenario_id == 0x38 \
			and int(input_ram[0x0516]) == 0x01 \
			and input_ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x40, 0x38, 0x01]) \
			and input_ram.slice(0x0523, 0x052A) == PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF]) \
			and int(input_ram[0x052B]) == 0x17 and int(input_ram[0x052E]) == 0 \
			and int(input_ram[0x05CC]) == 0x2D and int(input_ram[0x05CE]) == 0x80
	var scenario38_marker_profile := scenario38_initial_marker and input_marker == 0x97 \
			and scenario38_callback34_profile and int(input_ram[0x0533]) == 0 \
			and int(input_ram[0x0534]) == 0x80 and int(input_ram[0x0536]) == 0x80
	var scenario38_callback34_reset_profile := scenario38_initial_marker and input_marker == 0x97 \
			and input_countdown == 0x06 \
			and input_ram.slice(0x0516, 0x053A) == PackedByteArray(SCENARIO38_CALLBACK34_WORKER_RAM) \
			and input_ram.slice(0x05C7, 0x05D3) == PackedByteArray(SCENARIO38_CALLBACK34_MAP2D) \
			and int(input_ram[0x0498]) == 0x01 \
			and input_ram.slice(0x0499, 0x049C) == PackedByteArray([0x00, 0x6C, 0x04])
	var scenario38_reset_marker_profile := scenario38_marker_profile \
			or scenario38_callback34_reset_profile
	var initial_pointer := SCENARIO38_STREAM_START if scenario38_reset_marker_profile \
			else (SCENARIO1E_STREAM_START if scenario1e_marker_profile else ram_pointer)
	var is_f7_marker := int(input_ram[0x0523]) == 0x32 and int(input_ram[0x0524]) == 0x1F \
			and int(input_ram[0x0528]) == 0x4C and int(input_ram[0x0529]) == 0xFF \
			and initial_pointer in [0xAE03, 0xAE08, 0xAE0D] and int(input_ram[0x003A]) == 0x06
	var is_f9_followup_marker := int(input_ram[0x0523]) == 0x3E and int(input_ram[0x0524]) == 0x01 \
			and int(input_ram[0x0528]) == 0xE6 and int(input_ram[0x0529]) == 0x75 \
			and ((initial_pointer in [0xAE03, 0xAE0D] and int(input_ram[0x003A]) == 0x06) \
			or (initial_pointer == 0xAE08 and int(input_ram[0x003A]) in [0x06, 0x07]))
	var scenario36_stream_profile := int(input_ram[0x0516]) in [0x01, 0x61, 0x71] \
			and scenario_id == 0x36 and (is_f7_marker or is_f9_followup_marker)
	if not (scenario36_stream_profile or scenario1e_marker_profile or scenario1e_followup_profile \
			or scenario38_reset_marker_profile):
		return _unsupported_branch(0x02,
			"The live zero-count stream signature differs: scenario=$%02X/$%02X fields=$%02X/$%02X/$%02X/$%02X marker=$%02X countdown=$%02X pointer=$%04X cursor=$%02X." % [
			int(input_ram[0x0516]), int(input_ram[0x0518]), int(input_ram[0x0523]),
			int(input_ram[0x0524]), int(input_ram[0x0528]), int(input_ram[0x0529]), input_marker, input_countdown,
			initial_pointer, int(input_ram[0x003A])])
	if not _expect_worker_bytes(0x871A, [0xAD, 0x33, 0x05, 0xF0, 0x04, 0xCE, 0x33, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x8723, [0xA0, 0x00, 0xB1, 0x79, 0x29, 0x07]) \
			or not _expect_worker_bytes(0x873C, [0x8D, 0x33, 0x05, 0xB1, 0x79, 0x29, 0x07, 0x85, 0x3A]) \
			or not _expect_worker_bytes(0x8745, [0xC8, 0xB1, 0x79, 0xAA, 0xC8, 0xB1, 0x79, 0x9D, 0x6F, 0x04]) \
			or not _expect_worker_bytes(0x8752, [0xD0, 0xF2, 0x98, 0x18, 0x65, 0x79, 0x85, 0x79, 0x90, 0x02, 0xE6, 0x7A]) \
			or not _expect_worker_bytes(0x8706, [0x38, 0xE9, 0x01, 0x0A, 0xAA, 0xBD, 0x6E, 0xAD]) \
		or not _expect_worker_bytes(0x870B, [0xBD, 0x6E, 0xAD, 0x85, 0x79]) \
		or not _expect_worker_bytes(0x8715, [0xA9, 0x00, 0x8D, 0x33, 0x05, 0xAD, 0x33, 0x05, 0xF0, 0x04]) \
			or not _expect_worker_bytes(0x8765, [0xA9, 0x00, 0x8D, 0x32, 0x05, 0x60]) \
			or not _expect_worker_bytes(0x876B, [0xC8, 0xB1, 0x79, 0xAA, 0xC8, 0xB1, 0x79, 0x85, 0x7A, 0x86, 0x79, 0x4C, 0x23, 0x87]):
		return _rejected("The live `$8723` stream reader or its zero-count selector tails differ from the checked bank-$18 bytes.")
	if scenario1e_marker_profile and (_scenario1e_pointer_bytes != PackedByteArray([0xF6, 0xAD]) \
			or _scenario1e_stream_bytes.size() != SCENARIO1E_STREAM_LENGTH):
		return _rejected("Scenario-$1E marker `$81` lacks its verified `$AD6E->$ADF6` pointer or stream bytes.")
	if scenario38_reset_marker_profile and (_scenario38_pointer_bytes.size() != 4 \
			or _scenario38_stream_bytes.size() != SCENARIO38_STREAM_LENGTH):
		return _rejected("Scenario-$38 marker `$97` lacks its verified `$AD9A->$AFE6` pointer or stream bytes.")
	if int(input_ram[0x0498]) > 0x54:
		return _rejected("The live `$0498` append cursor exceeds the `$CCD2` buffer bound.")

	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = (resume_result["registers"] as Dictionary).duplicate(true)
	var mapper: Dictionary = (resume_result["mapper"] as Dictionary).duplicate(true)
	var entry_registers: Dictionary = cpu.duplicate(true)
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	if scenario1e_marker_profile or scenario38_reset_marker_profile:
		instruction_pcs.append_array([0x86F8, 0x86FB, 0x86FD, 0x86FF, 0x8701, 0x8704,
			0x8706, 0x8707, 0x8709, 0x870A, 0x870B, 0x870E, 0x8710, 0x8713,
			0x8715, 0x8717, 0x871A, 0x871D])
		_set_a(cpu, int(ram[0x0532]))
		if (int(cpu["p"]) & P_N) == 0:
			return _rejected("The reset marker did not take the ROM high-bit normalization branch.")
		_set_a(cpu, int(cpu["a"]) & 0x7F)
		_write_with_log(ram, writes, 0x8701, 0x0532, int(cpu["a"]))
		_set_flag(cpu, P_C, true)
		_sbc(cpu, 0x01)
		_set_a(cpu, (int(cpu["a"]) << 1) & 0xFF)
		_set_x(cpu, int(cpu["a"]))
		var pointer_bytes := _scenario1e_pointer_bytes
		var pointer_address := SCENARIO1E_POINTER_START
		if scenario38_reset_marker_profile:
			if int(cpu["x"]) != SCENARIO38_POINTER_START - SCENARIO1E_POINTER_START:
				return _rejected("Scenario-$38 `$97->$17` did not select `$AD9A` from `$AD6E,X`.")
			pointer_address = SCENARIO38_POINTER_START
			pointer_bytes = _scenario38_pointer_bytes.slice(0, 2)
		else:
			if int(cpu["x"]) != 0:
				return _rejected("Scenario-$1E `$81` did not select the first `$AD6E` pointer entry.")
		source_reads.append(_source_read(0x870B, pointer_address,
			int(pointer_bytes[0]), "stream_pointer_low"))
		source_reads.append(_source_read(0x8710, pointer_address + 1,
			int(pointer_bytes[1]), "stream_pointer_high"))
		_write_with_log(ram, writes, 0x870E, 0x0079, int(pointer_bytes[0]))
		_write_with_log(ram, writes, 0x8713, 0x007A, int(pointer_bytes[1]))
		_write_with_log(ram, writes, 0x8717, 0x0533, 0)
		initial_pointer = int(pointer_bytes[0]) | (int(pointer_bytes[1]) << 8)
	else:
		instruction_pcs.append_array([0x86F8, 0x86FB, 0x86FD, 0x871A, 0x871D])
		_set_a(cpu, int(ram[0x0532]))
		if (int(cpu["p"]) & P_N) != 0:
			return _unsupported_branch(input_marker, "The live positive marker does not take the source `$86FD` BPL-to-countdown path.")
	_set_a(cpu, int(ram[0x0533]))
	if (int(cpu["p"]) & P_Z) == 0:
		return _rejected("The `$0533` countdown is no longer zero at the `$8723` stream-reader entry.")
	instruction_pcs.append_array([0x8723, 0x8725])
	var stream_pointer := initial_pointer
	var loop_count := 0
	while loop_count < 4:
		loop_count += 1
		var control := _scenario36_stream_byte(stream_pointer)
		if control < 0:
			return _unsupported_branch(input_marker, "The live stream pointer `$%04X` is outside the hash-checked scenario stream spans." % stream_pointer)
		source_reads.append(_source_read(0x8725, stream_pointer, control, "scenario_stream_control"))
		_set_a(cpu, control & 0x07)
		_set_x(cpu, int(cpu["a"]))
		_set_a(cpu, control)
		instruction_pcs.append_array([0x8727, 0x8729, 0x872A, 0x872C, 0x872D, 0x872E, 0x872F])
		for _shift in 3:
			_lsr_a(cpu)
		var countdown := int(cpu["a"])
		var pair_count := int(cpu["x"])
		if countdown > 0:
			var scenario1e_batch := scenario1e_callback45_profile \
				and ((stream_pointer == 0xADF6 and control == 0x21 and pair_count == 1 and countdown == 4) \
				or (stream_pointer == 0xADF9 and control == 0x09 and pair_count == 1 and countdown == 1) \
				or (stream_pointer == 0xADFC and control == 0x33 and pair_count == 3 and countdown == 6) \
				or (stream_pointer in [0xAE03, 0xAE08] and control == 0x32 and pair_count == 2 and countdown == 6))
			var scenario36_batch := scenario36_stream_profile \
				and ((stream_pointer == 0xADFC and control == 0x33 and pair_count == 3 and countdown == 6) \
				or (stream_pointer in [0xAE03, 0xAE08] and control == 0x32 and pair_count == 2 and countdown == 6))
			var scenario38_batch := scenario38_reset_marker_profile \
					and stream_pointer == SCENARIO38_STREAM_START and control == 0x21 \
					and pair_count == 1 and countdown == 4
			if not (scenario1e_batch or scenario36_batch or scenario38_batch):
				return _unsupported_branch(input_marker,
					"The stream control `$%02X` at `$%04X` is outside the source-verified callback batches." % [control, stream_pointer])
			_write_with_log(ram, writes, 0x873C, 0x0533, countdown)
			_set_a(cpu, control & 0x07)
			_write_with_log(ram, writes, 0x8743, 0x003A, pair_count)
			_set_y(cpu, 1)
			instruction_pcs.append_array([0x873C, 0x873F, 0x8741, 0x8743, 0x8745])
			for pair_index in range(pair_count):
				var index_address := stream_pointer + int(cpu["y"])
				var ram_index := _scenario36_stream_byte(index_address)
				if ram_index < 0:
					return _unsupported_branch(input_marker, "The stream pair index at `$%04X` is outside the decoded ROM stream." % index_address)
				source_reads.append(_source_read(0x8746, index_address, ram_index, "ram_destination_index"))
				_set_a(cpu, ram_index)
				_set_x(cpu, int(cpu["a"]))
				_set_y(cpu, int(cpu["y"]) + 1)
				var value_address := stream_pointer + int(cpu["y"])
				var ram_value := _scenario36_stream_byte(value_address)
				if ram_value < 0:
					return _unsupported_branch(input_marker, "The stream pair value at `$%04X` is outside the decoded ROM stream." % value_address)
				source_reads.append(_source_read(0x8749, value_address, ram_value, "ram_destination_value"))
				_set_a(cpu, ram_value)
				_write_with_log(ram, writes, 0x874C, 0x046F + int(cpu["x"]), int(cpu["a"]))
				_set_y(cpu, int(cpu["y"]) + 1)
				var remaining := (int(ram[0x003A]) - 1) & 0xFF
				_write_with_log(ram, writes, 0x8752, 0x003A, remaining)
				instruction_pcs.append_array([0x8746, 0x8748, 0x8749, 0x874B, 0x874C, 0x874F, 0x8750, 0x8752])
				_set_nz(cpu, remaining)
			if int(ram[0x003A]) != 0 or int(cpu["y"]) != 1 + 2 * pair_count:
				return _rejected("The ROM stream pair loop did not finish at its source Y/count boundary.")
			instruction_pcs.append_array([0x8754, 0x8755, 0x8756, 0x8758, 0x875E])
			_set_a(cpu, int(cpu["y"]))
			_set_flag(cpu, P_C, false)
			var low_sum := int(ram[0x0079]) + int(cpu["a"])
			_set_a(cpu, low_sum)
			_set_flag(cpu, P_C, low_sum > 0xFF)
			_write_with_log(ram, writes, 0x8758, 0x0079, int(cpu["a"]))
			if low_sum > 0xFF:
				var high_pointer := (int(ram[0x007A]) + 1) & 0xFF
				_write_with_log(ram, writes, 0x875C, 0x007A, high_pointer)
				_set_nz(cpu, high_pointer)
			stream_pointer = int(ram[0x0079]) | (int(ram[0x007A]) << 8)
			var inline_result := _append_worker_inline_record(cpu, ram, stack,
				writes, stack_writes, stack_reads, source_reads, instruction_pcs)
			if not bool(inline_result.get("ok", false)):
				return _rejected(String(inline_result.get("reason", "ROM stream inline queue append failed.")))
			instruction_pcs.append(0x8764)
			var root_return_result := _return_worker_to_root(cpu, stack, stack_reads, instruction_pcs)
			if not bool(root_return_result.get("ok", false)):
				return _rejected(String(root_return_result.get("reason", "ROM stream worker root RTS failed.")))
			return _scenario_stream_result("returned_after_stream_batch", initial_pointer, stream_pointer,
				control, pair_count, countdown, entry_registers, cpu, mapper, ram, stack,
				writes, stack_writes, stack_reads, source_reads, instruction_pcs,
				inline_result.get("queue_record", PackedByteArray()), input_marker, input_countdown)
		if pair_count == 0:
			instruction_pcs.append_array([0x8731, 0x8733, 0x8765, 0x8767, 0x876A])
			_set_a(cpu, 0)
			_write_with_log(ram, writes, 0x8767, 0x0532, 0)
			var return_result := _return_worker_to_root(cpu, stack, stack_reads, instruction_pcs)
			if not bool(return_result.get("ok", false)):
				return _rejected(String(return_result.get("reason", "Scenario-$36 stream terminator RTS failed.")))
				return _scenario_stream_result("returned_after_stream_terminator", initial_pointer, stream_pointer,
				control, 0, 0, entry_registers, cpu, mapper, ram, stack,
					writes, stack_writes, stack_reads, source_reads, instruction_pcs, PackedByteArray(),
					input_marker, input_countdown)
		if pair_count == 1:
			instruction_pcs.append_array([0x8735, 0x8737, 0x876B, 0x876C, 0x876E, 0x876F, 0x8770, 0x8772, 0x8774, 0x8776])
			var low_address := stream_pointer + 1
			var target_low := _scenario36_stream_byte(low_address)
			var high_address := stream_pointer + 2
			var target_high := _scenario36_stream_byte(high_address)
			if stream_pointer != 0xAE0D or target_low != 0xFC or target_high != 0xAD:
				return _unsupported_branch(input_marker, "The selector-$01 redirect at `$%04X` is outside the verified `$AE0D->$ADFC` edge." % stream_pointer)
			source_reads.append(_source_read(0x876C, low_address, target_low, "stream_redirect_low"))
			source_reads.append(_source_read(0x8770, high_address, target_high, "stream_redirect_high"))
			_set_y(cpu, 1)
			_set_x(cpu, target_low)
			_set_y(cpu, 2)
			_set_a(cpu, target_high)
			_write_with_log(ram, writes, 0x8772, 0x007A, target_high)
			_write_with_log(ram, writes, 0x8774, 0x0079, target_low)
			stream_pointer = 0xADFC
			cpu["pc"] = 0x8723
			continue
		return _unsupported_branch(input_marker,
			"The zero-count stream selector %d at `$%04X` is not in the verified loop." % [pair_count, stream_pointer])
	return _unsupported_branch(input_marker, "Stream redirects exceeded the checked `$AE0D->$ADFC` loop bound.")


func _scenario36_stream_byte(cpu_address: int) -> int:
	if cpu_address >= SCENARIO38_STREAM_START and cpu_address < SCENARIO38_STREAM_END_EXCLUSIVE:
		return int(_scenario38_stream_bytes[cpu_address - SCENARIO38_STREAM_START])
	if cpu_address >= SCENARIO1E_STREAM_START and cpu_address < SCENARIO1E_STREAM_END_EXCLUSIVE:
		return int(_scenario1e_stream_bytes[cpu_address - SCENARIO1E_STREAM_START])
	if cpu_address >= SCRIPT82_START and cpu_address < SCRIPT82_START + _script82_bytes.size():
		return int(_script82_bytes[cpu_address - SCRIPT82_START])
	if cpu_address >= SCENARIO36_STREAM_START and cpu_address < SCENARIO36_STREAM_END_EXCLUSIVE:
		return int(_scenario36_stream_bytes[cpu_address - SCENARIO36_STREAM_START])
	return -1


func _append_worker_inline_record(cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_reads: Array[Dictionary], source_reads: Array[Dictionary],
		instruction_pcs: Array[int]) -> Dictionary:
	var append_cursor := int(ram[0x0498])
	if append_cursor > 0x54:
		return {"ok": false, "reason": "The live `$0498` append cursor exceeds the `$CCD2` buffer bound."}
	instruction_pcs.append_array([0xCCD2, 0xCCD3, 0xCCD6, 0xCCD8, 0xCCDC, 0xCCDE, 0xCCE0, 0xCCE2,
		0xCCE5, 0xCCEA, 0xCCEB, 0xCCEC, 0xCCEF, 0xCCF0, 0xCCF3, 0xCCF4,
		0xCCF6, 0xCCFC, 0xCD02, 0xCD07, 0xCD0A, 0xCD0C, 0x8764])
	_push_stack(cpu, stack, stack_writes, 0x87, 0x875E, "JSR_high")
	_push_stack(cpu, stack, stack_writes, 0x60, 0x875E, "JSR_low")
	_set_x(cpu, int(cpu["sp"]))
	var jsr_sp := int(cpu["x"])
	var return_low := int(stack[(jsr_sp + 1) & 0xFF])
	var return_high := int(stack[(jsr_sp + 2) & 0xFF])
	_set_a(cpu, return_low)
	_write_with_log(ram, writes, 0xCCD6, 0x0075, return_low)
	_push_stack(cpu, stack, stack_writes, return_low, 0xCCD8, "PHA_return_low")
	_set_a(cpu, return_high)
	_write_with_log(ram, writes, 0xCCDC, 0x0076, return_high)
	var saved_low := _pop_stack(cpu, stack, stack_reads, 0xCCDE, "PLA_return_low")
	_set_a(cpu, saved_low)
	_set_flag(cpu, P_C, false)
	_adc(cpu, 3)
	stack[(jsr_sp + 1) & 0xFF] = int(cpu["a"])
	stack_writes.append({"pc": 0xCCE2, "address": 0x0100 | ((jsr_sp + 1) & 0xFF),
		"value": int(cpu["a"]), "kind": "return_low_skip_inline"})
	_set_a(cpu, int(cpu["y"]))
	_push_stack(cpu, stack, stack_writes, int(cpu["a"]), 0xCCEB, "PHA_Y")
	_set_a(cpu, int(ram[0x0498]))
	_asl_a(cpu)
	_adc(cpu, int(ram[0x0498]))
	_set_x(cpu, int(cpu["a"]))
	_set_y(cpu, 1)
	var queue_base := 0x0499 + int(cpu["x"])
	var queue_record := PackedByteArray()
	for offset in range(3):
		var inline_value := int(_worker_bytes[0x8761 + offset - WORKER_START])
		source_reads.append(_source_read(0xCCF6 + offset * 6, 0x8761 + offset,
			inline_value, "inline_queue_byte"))
		_write_with_log(ram, writes, 0xCCF8 + offset * 6,
			queue_base + offset, inline_value)
		queue_record.append(inline_value)
		_set_a(cpu, inline_value)
		if offset < 2:
			_set_y(cpu, int(cpu["y"]) + 1)
	var next_append_cursor := (append_cursor + 1) & 0xFF
	_write_with_log(ram, writes, 0xCD07, 0x0498, next_append_cursor)
	_set_nz(cpu, next_append_cursor)
	var saved_y := _pop_stack(cpu, stack, stack_reads, 0xCD0A, "PLA_Y")
	_set_a(cpu, saved_y)
	_set_y(cpu, int(cpu["a"]))
	var helper_low := _pop_stack(cpu, stack, stack_reads, 0xCD0C, "RTS_low")
	var helper_high := _pop_stack(cpu, stack, stack_reads, 0xCD0C, "RTS_high")
	var helper_return := ((((helper_high << 8) | helper_low) + 1) & 0xFFFF)
	cpu["pc"] = helper_return
	if helper_return != 0x8764:
		return {"ok": false, "reason": "The source queue helper did not return past the inline payload at `$8764`."}
	return {"ok": true, "queue_record": queue_record}


func _return_worker_to_root(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary], instruction_pcs: Array[int]) -> Dictionary:
	var low := _pop_stack(cpu, stack, stack_reads, 0x876A, "RTS_low")
	var high := _pop_stack(cpu, stack, stack_reads, 0x876A, "RTS_high")
	var return_word := (high << 8) | low
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if int(cpu["pc"]) != 0xEBB3:
		return {"ok": false, "reason": "The scenario stream RTS did not return to `$EBB3`."}
	return {"ok": true, "return_word": return_word}


func _scenario_stream_result(status: String, initial_pointer: int, stream_pointer: int, control: int,
		pair_count: int, countdown: int, entry_registers: Dictionary, cpu: Dictionary,
		mapper: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		writes: Array[Dictionary], stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		source_reads: Array[Dictionary], instruction_pcs: Array[int],
		queue_record: PackedByteArray, input_marker: int, input_countdown: int) -> Dictionary:
	for stack_write_variant in stack_writes:
		var stack_write: Dictionary = stack_write_variant
		ram[int(stack_write["address"])] = int(stack_write["value"]) & 0xFF
	return {
		"ok": true, "status": status, "rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH, "entry_pc": WORKER_START,
		"exit_pc": int(cpu["pc"]), "entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)),
		"input_ram_0532": input_marker, "output_ram_0532": int(ram[0x0532]),
		"entry_registers": entry_registers, "registers": cpu,
		"mapper": mapper, "ram_image": ram, "stack_page": stack,
		"memory_writes": writes.duplicate(true), "ram_writes": writes.duplicate(true),
		"mapper_writes": [], "stack_reads": stack_reads.duplicate(true),
		"stack_writes": stack_writes.duplicate(true),
		"instruction_pcs": instruction_pcs.duplicate(),
		"return_word": int(stack_reads[stack_reads.size() - 2].get("value", -1)) \
			| (int(stack_reads[stack_reads.size() - 1].get("value", -1)) << 8),
		"return_pc": int(cpu["pc"]), "input_ram_0533": input_countdown,
		"countdown_before": 0, "countdown_after": countdown,
		"stream_control": control, "stream_pair_count": pair_count,
		"stream_pointer_before": initial_pointer,
		"stream_pointer_after": int(ram[0x0079]) | (int(ram[0x007A]) << 8),
		"source_reads": source_reads.duplicate(true),
		"inline_queue_record": queue_record.duplicate(),
		"next_worker_executed": false, "next_worker_bytes_read": false,
		"ppu_bus_events": [], "apu_register_writes": [],
		"ppu_apu_effects_applied": false, "trace_state_used": false,
		"nmi_cadence_generated": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "worker_start": WORKER_START,
		"worker_end_exclusive": WORKER_END_EXCLUSIVE,
		"supports_ram_0532_zero_high_bit_normalization_script82_and_scenario36_countdown": true,
		"supports_scenario38_callback34_marker97_input_countdown_06_reset_to_afe6": true,
		"supports_scenario38_marker17_timer_afe6_to_afe9": true,
		"supports_scenario38_afe9_two_pair_batch_return_to_ebb3": true,
		"next_scenario38_stream_pointer": 0xAFEE}


func _execute_script82(resume_result: Dictionary, input_ram: PackedByteArray,
		input_stack: PackedByteArray) -> Dictionary:
	if not _expect_worker_bytes(0x8701, [0x8D, 0x32, 0x05]) \
			or not _expect_worker_bytes(0x870B, [0xBD, 0x6E, 0xAD]) \
			or not _expect_worker_bytes(0x8723, [0xA0, 0x00, 0xB1, 0x79, 0x29, 0x07]) \
			or not _expect_worker_bytes(0x875E, [0x20, 0x33, 0xC5]) \
			or not _expect_worker_bytes(0x8761, [0x00, 0x6C, 0x04, 0x60]) \
			or not _expect_worker_bytes(0x8765, [0xA9, 0x00, 0x8D, 0x32, 0x05, 0x60]):
		return _rejected("The traced `$82` worker, inline packet, or source return bytes changed.")
	if _append_vector_bytes != PackedByteArray([0x4C, 0xD2, 0xCC]) \
			or _append_handler_bytes.size() != 59:
		return _rejected("The source `$C533->$CCD2` append helper is unavailable.")
	var append_cursor := int(input_ram[0x0498])
	if append_cursor > 0x54:
		return _rejected("The live `$0498` append cursor exceeds the `$CCD2` buffer bound.")

	var ram := input_ram.duplicate()
	var stack := input_stack.duplicate()
	var cpu: Dictionary = resume_result["registers"].duplicate(true)
	var mapper: Dictionary = resume_result["mapper"].duplicate(true)
	var entry_registers: Dictionary = cpu.duplicate(true)
	var executed_pcs: Array[int] = []
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []

	# $86F8-$8717: high-bit marker selects table entry 1 ($AD70), then
	# stores its little-endian stream pointer and resets the stream countdown.
	executed_pcs.append_array([0x86F8, 0x86FB, 0x86FD, 0x86FF, 0x8701,
		0x8704, 0x8706, 0x8707, 0x8709, 0x870A, 0x870B, 0x870E,
		0x8710, 0x8713, 0x8715, 0x8717, 0x871A, 0x871D])
	_set_a(cpu, int(ram[0x0532]))
	if (int(cpu["p"]) & P_N) == 0:
		return _rejected("The live `$82` value does not take `$86FD`'s BPL fall-through.")
	_set_a(cpu, int(cpu["a"]) & 0x7F)
	_write_with_log(ram, writes, 0x8701, 0x0532, int(cpu["a"]))
	_set_flag(cpu, P_C, true) # SEC
	_sbc(cpu, 0x01)
	_asl_a(cpu)
	_set_x(cpu, int(cpu["a"]))
	if int(cpu["x"]) != 0x02:
		return _rejected("The source `$82 -> 2 -> X=2` pointer-table index changed.")
	var pointer := int(_script82_pointer_bytes[0]) | (int(_script82_pointer_bytes[1]) << 8)
	if pointer != SCRIPT82_START:
		return _rejected("The checked `$AD70` pointer no longer resolves to `$ADFC`.")
	source_reads.append(_source_read(0x870B, SCRIPT82_POINTER_START,
		int(_script82_pointer_bytes[0]), "script_pointer_low"))
	source_reads.append(_source_read(0x8710, SCRIPT82_POINTER_START + 1,
		int(_script82_pointer_bytes[1]), "script_pointer_high"))
	_set_a(cpu, int(_script82_pointer_bytes[0]))
	_write_with_log(ram, writes, 0x870E, 0x0079, int(cpu["a"]))
	_set_a(cpu, int(_script82_pointer_bytes[1]))
	_write_with_log(ram, writes, 0x8713, 0x007A, int(cpu["a"]))
	_set_a(cpu, 0)
	_write_with_log(ram, writes, 0x8717, 0x0533, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0533]))
	if (int(cpu["p"]) & P_Z) == 0:
		return _rejected("The source `$871D` countdown branch no longer enters the stream reader.")
	_set_y(cpu, 0)

	# $8725-$873C reads the same stream control byte twice: low three bits
	# select three index/value pairs, while high bits seed $0533 with six.
	executed_pcs.append_array([0x8723, 0x8725, 0x8727, 0x8729, 0x872A,
		0x872C, 0x872D, 0x872E, 0x872F, 0x8731, 0x8733, 0x873C,
		0x873F, 0x8741, 0x8743])
	var control := int(_script82_bytes[0])
	source_reads.append(_source_read(0x8725, SCRIPT82_START, control, "stream_control_selector"))
	_set_a(cpu, control & 0x07)
	_set_x(cpu, int(cpu["a"]))
	source_reads.append(_source_read(0x872A, SCRIPT82_START, control, "stream_control_countdown"))
	_set_a(cpu, control)
	for _shift in range(3):
		_lsr_a(cpu)
	var countdown := int(cpu["a"])
	if countdown != 6 or int(cpu["x"]) != 3:
		return _rejected("The checked `$ADFC` control byte no longer selects three entries/countdown six.")
	_set_a(cpu, countdown)
	_write_with_log(ram, writes, 0x873C, 0x0533, int(cpu["a"]))
	source_reads.append(_source_read(0x873F, SCRIPT82_START, control, "stream_entry_count"))
	_set_a(cpu, control & 0x07)
	_write_with_log(ram, writes, 0x8743, 0x003A, int(cpu["a"]))
	var stream_cursor := 1
	while int(ram[0x003A]) > 0:
		_set_y(cpu, stream_cursor)
		var tile_index := int(_script82_bytes[stream_cursor])
		source_reads.append(_source_read(0x8746, SCRIPT82_START + stream_cursor,
			tile_index, "stream_destination_index"))
		_set_a(cpu, tile_index)
		_set_x(cpu, int(cpu["a"]))
		stream_cursor += 1
		_set_y(cpu, stream_cursor)
		var tile_value := int(_script82_bytes[stream_cursor])
		source_reads.append(_source_read(0x8749, SCRIPT82_START + stream_cursor,
			tile_value, "stream_destination_value"))
		_set_a(cpu, tile_value)
		_write_with_log(ram, writes, 0x874C, 0x046F + int(cpu["x"]), int(cpu["a"]))
		stream_cursor += 1
		_set_y(cpu, stream_cursor)
		var remaining := (int(ram[0x003A]) - 1) & 0xFF
		_write_with_log(ram, writes, 0x8752, 0x003A, remaining)
		executed_pcs.append_array([0x8745, 0x8746, 0x8748, 0x8749, 0x874B, 0x874C, 0x874F, 0x8750, 0x8752])
		_set_nz(cpu, remaining)
	if stream_cursor != 7:
		return _rejected("The `$82` stream did not consume exactly three index/value pairs.")

	# $8754-$875C advances the ROM pointer past those six values, then
	# JSR $C533 copies the three inline bytes into the live $0499 queue.
	executed_pcs.append_array([0x8754, 0x8755, 0x8756, 0x8758, 0x875A, 0x875C, 0x875E])
	_set_a(cpu, int(cpu["y"]))
	_set_flag(cpu, P_C, false)
	_adc(cpu, int(ram[0x0079]))
	_write_with_log(ram, writes, 0x8758, 0x0079, int(cpu["a"]))
	if (int(cpu["p"]) & P_C) != 0:
		var high_pointer := (int(ram[0x007A]) + 1) & 0xFF
		_write_with_log(ram, writes, 0x875C, 0x007A, high_pointer)
		_set_nz(cpu, high_pointer)
	_push_stack(cpu, stack, stack_writes, 0x87, 0x875E, "JSR_high")
	_push_stack(cpu, stack, stack_writes, 0x60, 0x875E, "JSR_low")
	cpu["pc"] = 0xC533
	if int(_append_vector_bytes[0]) != 0x4C or int(_append_vector_bytes[1]) != 0xD2 \
			or int(_append_vector_bytes[2]) != 0xCC:
		return _rejected("The `$C533` helper vector no longer jumps to `$CCD2`.")

	# Hash-checked `$CCD2-$CD0C` helper semantics: stage the return pointer,
	# skip the inline payload on return, append three bytes, then RTS to $8764.
	executed_pcs.append_array([0xCCD2, 0xCCD3, 0xCCD6, 0xCCD8, 0xCCD9,
		0xCCDC, 0xCCDE, 0xCCDF, 0xCCE0, 0xCCE2, 0xCCE5, 0xCCEA,
		0xCCEB, 0xCCEC, 0xCCEF, 0xCCF0, 0xCCF3, 0xCCF4, 0xCCF6,
		0xCCF8, 0xCCFB, 0xCCFC, 0xCCFE, 0xCD01, 0xCD02, 0xCD04,
		0xCD07, 0xCD0A, 0xCD0B, 0xCD0C, 0x8764])
	_set_x(cpu, int(cpu["sp"])) # TSX
	var jsr_sp := int(cpu["x"])
	var return_low := int(stack[(jsr_sp + 1) & 0xFF])
	var return_high := int(stack[(jsr_sp + 2) & 0xFF])
	_set_a(cpu, return_low)
	_write_with_log(ram, writes, 0xCCD6, 0x0075, int(cpu["a"]))
	_push_stack(cpu, stack, stack_writes, int(cpu["a"]), 0xCCD8, "PHA")
	_set_a(cpu, return_high)
	_write_with_log(ram, writes, 0xCCDC, 0x0076, int(cpu["a"]))
	var saved_return_low := _pop_stack(cpu, stack, stack_reads, 0xCCDE, "PLA")
	_set_a(cpu, saved_return_low)
	_set_flag(cpu, P_C, false)
	_adc(cpu, 3)
	stack[(jsr_sp + 1) & 0xFF] = int(cpu["a"])
	stack_writes.append({"pc": 0xCCE2, "address": 0x0100 | ((jsr_sp + 1) & 0xFF),
		"value": int(cpu["a"]), "kind": "return_low_skip_inline"})
	_set_a(cpu, int(cpu["y"]))
	_push_stack(cpu, stack, stack_writes, int(cpu["a"]), 0xCCEB, "PHA_Y")
	_set_a(cpu, int(ram[0x0498]))
	_asl_a(cpu)
	_adc(cpu, int(ram[0x0498]))
	_set_x(cpu, int(cpu["a"]))
	_set_y(cpu, 1)
	var inline_start := int(ram[0x0075]) | (int(ram[0x0076]) << 8)
	if inline_start != 0x8760:
		return _rejected("The inline queue helper did not point at `$86F8`'s `$8760` return word.")
	for offset in range(3):
		var inline_value := int(_worker_bytes[0x8761 + offset - WORKER_START])
		_set_a(cpu, inline_value)
		source_reads.append(_source_read(0xCCF6 + offset * 6, 0x8761 + offset,
			inline_value, "inline_queue_byte"))
		_write_with_log(ram, writes, 0xCCF8 + offset * 6, 0x0499 + int(cpu["x"]) + offset,
			int(cpu["a"]))
		if offset < 2:
			_set_y(cpu, int(cpu["y"]) + 1)
	var new_append_cursor := (int(ram[0x0498]) + 1) & 0xFF
	_write_with_log(ram, writes, 0xCD07, 0x0498, new_append_cursor)
	_set_nz(cpu, new_append_cursor)
	var saved_y := _pop_stack(cpu, stack, stack_reads, 0xCD0A, "PLA_Y")
	_set_a(cpu, saved_y)
	_set_y(cpu, int(cpu["a"]))
	var helper_low := _pop_stack(cpu, stack, stack_reads, 0xCD0C, "RTS_low")
	var helper_high := _pop_stack(cpu, stack, stack_reads, 0xCD0C, "RTS_high")
	var helper_return := (((helper_high << 8) | helper_low) + 1) & 0xFFFF
	cpu["pc"] = helper_return
	if helper_return != 0x8764:
		return _rejected("The append helper did not return past the inline payload at `$8764`.")
	var root_low := _pop_stack(cpu, stack, stack_reads, 0x8764, "RTS_low")
	var root_high := _pop_stack(cpu, stack, stack_reads, 0x8764, "RTS_high")
	var root_return := (((root_high << 8) | root_low) + 1) & 0xFFFF
	cpu["pc"] = root_return
	if root_return != 0xEBB3:
		return _rejected("The `$82` worker did not return to the verified `$EBB3` caller.")
	for stack_write_variant in stack_writes:
		var stack_write: Dictionary = stack_write_variant
		ram[int(stack_write["address"])] = int(stack_write["value"]) & 0xFF

	return {
		"ok": true,
		"status": "returned_after_script82",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": WORKER_START,
		"exit_pc": root_return,
		"entry_bank": WORKER_BANK,
		"exit_bank": int(mapper.get("bank_low", -1)),
		"input_ram_0532": 0x82,
		"output_ram_0532": int(ram[0x0532]),
		"entry_registers": entry_registers,
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"memory_writes": writes,
		"ram_writes": writes.duplicate(true),
		"source_reads": source_reads,
		"stack_reads": stack_reads,
		"stack_writes": stack_writes,
		"instruction_pcs": executed_pcs,
		"return_word": 0xEBB2,
		"return_pc": root_return,
		"stream_pointer_start": SCRIPT82_START,
		"stream_pointer_after_records": int(ram[0x0079]) | (int(ram[0x007A]) << 8),
		"inline_queue_record": ram.slice(0x0499 + append_cursor * 3, 0x049C + append_cursor * 3),
		"next_worker_executed": false,
		"next_worker_bytes_read": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
	}


func _validate_live_resume_result(result: Dictionary) -> Dictionary:
	var result_status := String(result.get("status", ""))
	var result_entry_pc := int(result.get("entry_pc", -1))
	var is_legacy_entry := result_status == "stopped_before_worker_body" and result_entry_pc == 0xEB8B
	var is_actor_seed_continuation := result_status == "slot09_actor_seed_continuation_to_worker_vector" \
			and result_entry_pc == 0xED2D and int(result.get("caller_entry_pc", -1)) == 0xEB8B
	var result_ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var is_scenario36_continuation: bool = result_status == "scenario36_event_returned_to_worker_vector" \
			and result_entry_pc == 0xEB9E and int(result.get("caller_entry_pc", -1)) == 0xEB8B \
			and result_ram_variant is PackedByteArray and result_ram_variant.size() == RAM_SIZE \
			and int(result_ram_variant[0x0518]) == 0x36
	var is_scenario2e_continuation: bool = result_status == "scenario2e_event_returned_to_worker_vector" \
			and result_entry_pc == 0xEB9E and int(result.get("caller_entry_pc", -1)) == 0xEB8B \
			and result_ram_variant is PackedByteArray and result_ram_variant.size() == RAM_SIZE \
			and int(result_ram_variant[0x0518]) == 0x2E
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or not (is_legacy_entry or is_actor_seed_continuation \
				or is_scenario36_continuation or is_scenario2e_continuation) \
			or String(result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json" \
			or int(result.get("exit_pc", -1)) != WORKER_START \
			or int(result.get("exit_bank", -1)) != WORKER_BANK \
			or bool(result.get("worker_body_executed", true)) \
			or bool(result.get("worker_body_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)):
		return {"ok": false, "reason": "Input is not the live runner's hash-checked slot-$09 result stopped at `$86F8`."}
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	var pending_variant: Variant = result.get("pending_worker_call", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not pending_variant is Dictionary:
		return {"ok": false, "reason": "Live slot-$09 result must carry registers, mapper, complete RAM/stack, and pending JSR data."}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var pending: Dictionary = pending_variant
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	if not bank_registers_variant is Dictionary:
		return {"ok": false, "reason": "Live slot-$09 result is missing MMC3 bank-register state."}
	var bank_registers: Dictionary = bank_registers_variant
	if registers.size() == 0 or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or int(registers.get("pc", -1)) != WORKER_START \
			or int(registers.get("sp", -1)) != 0x78 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 7 \
			or int(bank_registers.get(6, -1)) != 0x18 \
			or int(bank_registers.get(7, -1)) != 0x19 \
			or int(ram[0x0000]) != 0x09 \
			or int(ram[0x0024]) != 0x18 or int(ram[0x0025]) != 0x19 \
			or stack.slice(0x79, 0x7B) != PackedByteArray([0xB2, 0xEB]) \
			or int(pending.get("source_pc", -1)) != 0xEBB0 \
			or int(pending.get("return_word", -1)) != 0xEBB2 \
			or int(pending.get("return_pc", -1)) != 0xEBB3 \
			or int(pending.get("target_pc", -1)) != WORKER_START \
			or int(pending.get("target_bank", -1)) != WORKER_BANK:
		return {"ok": false, "reason": "Live worker context mismatch: PC/SP=$%04X/$%02X banks=$%02X/$%02X select=$%02X regs=$%02X/$%02X RAM=$%02X/$%02X stack=%s pending=%s." % [
			int(registers.get("pc", -1)), int(registers.get("sp", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			int(mapper.get("select", -1)), int(bank_registers.get(6, -1)), int(bank_registers.get(7, -1)),
			int(ram[0x0024]), int(ram[0x0025]), stack.slice(0x79, 0x7B).hex_encode(), JSON.stringify(pending)]}
	return {"ok": true}


func _write_ram(ram: PackedByteArray, source_pc: int, address: int, value: int) -> void:
	ram[address] = value & 0xFF


func _write_with_log(ram: PackedByteArray, writes: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	var stored := value & 0xFF
	writes.append({"pc": source_pc, "address": address,
		"old_value": int(ram[address]), "value": stored, "kind": "ram"})
	ram[address] = stored


func _source_read(pc: int, address: int, value: int, kind: String) -> Dictionary:
	return {"pc": pc, "address": address, "value": value & 0xFF, "kind": kind}


func _load_manifest_span(manifest: Dictionary, file_name: String, cpu_start: String,
		cpu_end_exclusive: String, bank: String, file_offset: String,
		length: int, expected_sha256: String) -> PackedByteArray:
	var spans_variant: Variant = manifest.get("spans", [])
	if not spans_variant is Array:
		_fail("The `$86F8` manifest has no ROM source-span list.")
		return PackedByteArray()
	var row: Dictionary = {}
	for span_variant in spans_variant:
		if span_variant is Dictionary and String(span_variant.get("file", "")) == file_name:
			row = span_variant
			break
	if row.is_empty() \
			or String(row.get("cpu_start", "")) != cpu_start \
			or String(row.get("cpu_end_exclusive", "")) != cpu_end_exclusive \
			or String(row.get("bank", "")) != bank \
			or String(row.get("file_offset", "")) != file_offset \
			or int(row.get("length", -1)) != length \
			or String(row.get("sha256", "")) != expected_sha256:
		_fail("ROM manifest mapping/hash differs for `%s`." % file_name)
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + file_name)
	if bytes.size() != length or _sha256(bytes) != expected_sha256 \
			or String(row.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
		_fail("Packaged ROM bytes failed validation for `%s`." % file_name)
		return PackedByteArray()
	return bytes


func _set_a(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	cpu["a"] = value
	_set_nz(cpu, value)


func _set_x(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	cpu["x"] = value
	_set_nz(cpu, value)


func _set_y(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	cpu["y"] = value
	_set_nz(cpu, value)


func _set_nz(cpu: Dictionary, value: int) -> void:
	cpu["p"] = _with_nz(int(cpu.get("p", 0)), value)
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ_MASK


func _set_flag(cpu: Dictionary, mask: int, enabled: bool) -> void:
	var status := int(cpu.get("p", 0))
	status = (status | mask) if enabled else (status & ~mask)
	cpu["p"] = status & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | mask


func _adc(cpu: Dictionary, value: int) -> void:
	var left := int(cpu["a"]) & 0xFF
	var right := value & 0xFF
	var carry := 1 if (int(cpu["p"]) & P_C) != 0 else 0
	var total := left + right + carry
	var result := total & 0xFF
	_set_flag(cpu, P_C, total > 0xFF)
	_set_flag(cpu, P_V, ((~(left ^ right) & (left ^ result)) & 0x80) != 0)
	_set_a(cpu, result)


func _sbc(cpu: Dictionary, value: int) -> void:
	var left := int(cpu["a"]) & 0xFF
	var right := value & 0xFF
	var borrow := 0 if (int(cpu["p"]) & P_C) != 0 else 1
	var difference := left - right - borrow
	var result := difference & 0xFF
	_set_flag(cpu, P_C, difference >= 0)
	_set_flag(cpu, P_V, (((left ^ result) & (left ^ right)) & 0x80) != 0)
	_set_a(cpu, result)


func _asl_a(cpu: Dictionary) -> void:
	var value := int(cpu["a"]) & 0xFF
	_set_flag(cpu, P_C, (value & 0x80) != 0)
	_set_a(cpu, (value << 1) & 0xFF)


func _lsr_a(cpu: Dictionary) -> void:
	var value := int(cpu["a"]) & 0xFF
	_set_flag(cpu, P_C, (value & 0x01) != 0)
	_set_a(cpu, value >> 1)


func _push_stack(cpu: Dictionary, stack: PackedByteArray, writes: Array[Dictionary],
		value: int, source_pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = value & 0xFF
	writes.append({"pc": source_pc, "address": 0x0100 | sp,
		"value": value & 0xFF, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop_stack(cpu: Dictionary, stack: PackedByteArray, reads: Array[Dictionary],
		source_pc: int, kind: String) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	reads.append({"pc": source_pc, "address": 0x0100 | sp,
		"value": value, "kind": kind})
	return value


func _expect_worker_bytes(cpu_address: int, expected: Array[int]) -> bool:
	var offset := cpu_address - WORKER_START
	if offset < 0 or offset + expected.size() > _worker_bytes.size():
		return false
	for index in range(expected.size()):
		if int(_worker_bytes[offset + index]) != expected[index]:
			return false
	return true


func _with_nz(status: int, value: int) -> int:
	var result := status & ~P_NZ_MASK
	if (value & 0x80) != 0:
		result |= P_N
	if (value & 0xFF) == 0:
		result |= P_Z
	return result & 0xFF


func _rejected(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_input", "reason": reason,
		"trace_state_used": false}


func _unsupported_branch(value: int, reason: String, exit_pc: int = 0x86FD) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"entry_pc": WORKER_START, "exit_pc": exit_pc,
		"ram_0532": value, "trace_state_used": false}


func _fail(reason: String) -> bool:
	error_message = reason
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
