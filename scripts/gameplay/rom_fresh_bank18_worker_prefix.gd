extends RefCounted
class_name RomFreshBank18WorkerPrefix
## Source-byte execution from bank-$18:$800C to the first worker's $C515
## yield-trampoline entry. The task-save handler and scheduler are out of scope.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const RAM_SIZE := 0x800
const ENTRY_PC := 0x800C
const ENTRY_BANK := 0x18
const END_PC := 0xC515
const END_BANK := 0x1E
const SOURCE_FILES := {
	"bank18_worker_entry_to_yield_call_800C_8889.bin": {"bank": 0x18, "start": 0x800C, "end": 0x8889},
	"bank18_worker_resume_8889_89D7.bin": {"bank": 0x18, "start": 0x8889, "end": 0x89D7},
	"bank19_resumed_worker_text_lead_BBDC_BBDE.bin": {"bank": 0x19, "start": 0xBBDC, "end": 0xBBDE},
	"bank19_resumed_worker_text_row01_BBDE_BBE0.bin": {"bank": 0x19, "start": 0xBBDE, "end": 0xBBE0},
	"bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin": {
		"bank": 0x19, "start": 0xBBE0, "end": 0xBBE3,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_00.bin",
	},
	"bank19_resumed_worker_descriptor01_row02_BBE3_BBE6.bin": {
		"bank": 0x19, "start": 0xBBE3, "end": 0xBBE6,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_02.bin",
	},
	"bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin": {
		"bank": 0x19, "start": 0xBD9C, "end": 0xBD9F,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_01.bin",
	},
	"bank19_resumed_worker_descriptor01_row03_BD9F_BDA2.bin": {
		"bank": 0x19, "start": 0xBD9F, "end": 0xBDA2,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_03.bin",
	},
	"bank19_worker_lookup_B3BD_B3D1.bin": {"bank": 0x19, "start": 0xB3BD, "end": 0xB3D1},
	"bank19_match_descriptor_B453_B464.bin": {"bank": 0x19, "start": 0xB453, "end": 0xB464},
	"bank19_worker_lookup_tail_B3D1_B3D3.bin": {
		"bank": 0x19, "start": 0xB3D1, "end": 0xB3D3,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/bank19_worker_lookup_tail_B3D1_B3D3.bin",
	},
	"bank19_match_descriptor_B464_B475.bin": {
		"bank": 0x19, "start": 0xB464, "end": 0xB475,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/bank19_match_descriptor_B464_B475.bin",
	},
	"bank19_match_descriptor_B475_B47D.bin": {
		"bank": 0x19, "start": 0xB475, "end": 0xB47D,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01.bin",
		"source_offset": 17,
		"source_file_sha256": "f6812eef1a546a57f38689c72882108c959ac740e3ffea93288355cc6765bb82",
	},
	"fixed_task_yield_trampoline_C515_C518.bin": {"bank": 0x1E, "start": 0xC515, "end": 0xC518},
	"fixed_dispatch_C509_C50C.bin": {"bank": 0x1E, "start": 0xC509, "end": 0xC50C},
	"shared_fixed_branch_table_dispatch_CB99_CBAF.bin": {
		"bank": 0x1E, "start": 0xCB99, "end": 0xCBB0,
		"path": "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_branch_table_dispatch_CB99_CBAF.bin",
	},
	"bank18_callback_pointer_89D8_89DA.bin": {"bank": 0x18, "start": 0x89D8, "end": 0x89DA},
	"bank18_resumed_worker_vector_tail_89D7_89DC.bin": {"bank": 0x18, "start": 0x89D7, "end": 0x89DC},
	"bank18_special_handler_8B48_8B77.bin": {"bank": 0x18, "start": 0x8B48, "end": 0x8B77},
	"bank18_f0_match_clock_handler_8B8B_8BD5.bin": {"bank": 0x18, "start": 0x8B8B, "end": 0x8BD5},
	"bank18_f0_decimal_formatter_8C55_8C85.bin": {"bank": 0x18, "start": 0x8C55, "end": 0x8C85},
	"fixed_text_helper_vector_C524_C527.bin": {"bank": 0x1E, "start": 0xC524, "end": 0xC527},
	"fixed_division_dispatch_C51E_C521.bin": {"bank": 0x1E, "start": 0xC51E, "end": 0xC521},
	"fixed_division_16bit_CD3C_CD77.bin": {"bank": 0x1E, "start": 0xCD3C, "end": 0xCD77},
	"fixed_text_token_converter_CBC2_CBF1.bin": {"bank": 0x1E, "start": 0xCBC2, "end": 0xCBF1},
	"bank18_inline_callback_pointer_89F2_89F4.bin": {"bank": 0x18, "start": 0x89F2, "end": 0x89F4},
	"bank18_ed_text_loop_8A56_8A86.bin": {
		"bank": 0x18, "start": 0x8A56, "end": 0x8A86,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ed_text_loop_8A56_8A86.bin",
	},
	"bank18_ed_team_handler_8AE7_8B0A.bin": {
		"bank": 0x18, "start": 0x8AE7, "end": 0x8B0A,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ed_team_handler_8AE7_8B0A.bin",
	},
	"bank18_ed_team_name_lengths_8B0A_8B0E.bin": {
		"bank": 0x18, "start": 0x8B0A, "end": 0x8B0E,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ed_team_name_lengths_8B0A_8B0E.bin",
	},
	"bank18_ee_numeric_handler_8B2F_8B48.bin": {
		"bank": 0x18, "start": 0x8B2F, "end": 0x8B48,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ee_numeric_handler_8B2F_8B48.bin",
	},
	"fixed_team_name_dispatch_C53C_C53F.bin": {
		"bank": 0x1E, "start": 0xC53C, "end": 0xC53F,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_dispatch_C53C_C53F.bin",
	},
	"fixed_team_name_lookup_F30F_F329.bin": {
		"bank": 0x1F, "start": 0xF30F, "end": 0xF329,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_lookup_F30F_F329.bin",
	},
	"fixed_team_name_pointer_entries_76_79_F415_F41D.bin": {
		"bank": 0x1F, "start": 0xF415, "end": 0xF41D,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_pointer_entries_76_79_F415_F41D.bin",
	},
	"fixed_team_00_name_stream_F776_F77C.bin": {
		"bank": 0x1F, "start": 0xF776, "end": 0xF77C,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/team_00_name_stream.bin",
	},
	"bank18_character_buffer_helper_8C85_8C9F.bin": {"bank": 0x18, "start": 0x8C85, "end": 0x8C9F},
	"bank18_character_emit_wrapper_8C9F_8CA5.bin": {"bank": 0x18, "start": 0x8C9F, "end": 0x8CA5},
	"bank18_fc_callback_return_8C52_8C55.bin": {"bank": 0x18, "start": 0x8C52, "end": 0x8C55},
	"bank18_window_3x3_tile_ids_8D9E_8DA7.bin": {
		"bank": 0x18, "start": 0x8D9E, "end": 0x8DA7,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin",
	},
	"fixed_wrapper_return_EF99_EFA2.bin": {
		"bank": 0x1F, "start": 0xEF99, "end": 0xEFA2,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/fixed_wrapper_return_EF99_EFA2.bin",
	},
	"fixed_bank18_wrapper_EF7F_EF99.bin": {
		"bank": 0x1F, "start": 0xEF7F, "end": 0xEF99,
		"path": "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_bank18_wrapper_EF7F_EF99.bin",
	},
	"fixed_mapper_helper_CE2D_CE4A.bin": {
		"bank": 0x1E, "start": 0xCE2D, "end": 0xCE4A,
		"path": "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_mapper_helper_CE2D_CE49.bin",
	},
	"fixed_second_wrapper_caller_DACC_DAD1.bin": {
		"bank": 0x1E, "start": 0xDACC, "end": 0xDAD1,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/fixed_second_wrapper_caller_DACC_DAD1.bin",
	},
	"fixed_kickoff_caller_DAD1_DAD8.bin": {
		"bank": 0x1E, "start": 0xDAD1, "end": 0xDAD8,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/fixed_kickoff_caller_DAD1_DAD8.bin",
	},
	"fixed_kickoff_scenario35_caller_DAD8_DADC.bin": {
		"bank": 0x1E, "start": 0xDAD8, "end": 0xDADD,
		"path": "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_kickoff_scenario35_caller_DAD8_DADC.bin",
	},
	"fixed_scenario_queue_CBB0_CBC1.bin": {
		"bank": 0x1E, "start": 0xCBB0, "end": 0xCBC2,
		"path": "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin",
	},
}

const FLAG_C := 0x01
const FLAG_Z := 0x02
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
var _p_known_mask := 0xFF
var _sp := 0
var _pc := 0
var _write_trace_pc := 0
var _bank_low := 0
var _bank_high := 1
var _mmc3_select := 0
var _writes: Array[Dictionary] = []
var _mapper_writes: Array[Dictionary] = []
var _calls: Array[Dictionary] = []
var _instructions: Array[Dictionary] = []
var _executed_source_files: Dictionary = {}
var _blocked_read: Dictionary = {}
var _unsupported_opcode: Dictionary = {}
var _bounded_source_stop_address := -1
var _bounded_source_stop_reached := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Fresh bank-$18 worker source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Fresh bank-$18 worker source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-bank18-worker-prefix-source-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Fresh bank-$18 worker package targets an unsupported ROM/schema.")
	var by_file: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			by_file[String(span.get("file", ""))] = span
	for file_name: String in SOURCE_FILES:
		if not by_file.has(file_name):
			return _fail("Fresh bank-$18 worker manifest omits %s." % file_name)
		var spec: Dictionary = SOURCE_FILES[file_name]
		var entry: Dictionary = by_file[file_name]
		var source_path := String(spec.get("path", SOURCE_ROOT + file_name))
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if spec.has("source_offset"):
			if _sha256(bytes) != String(spec.get("source_file_sha256", "")):
				return _fail("Fresh bank-$18 worker parent source failed full-file hash validation: %s." % file_name)
			var source_offset := int(spec["source_offset"])
			var source_end := source_offset + int(spec["end"]) - int(spec["start"])
			if source_offset < 0 or source_end > bytes.size():
				return _fail("Fresh bank-$18 worker parent source slice is out of bounds: %s." % file_name)
			bytes = bytes.slice(source_offset, source_end)
		if bytes.size() != int(spec["end"]) - int(spec["start"]) \
				or _sha256(bytes) != String(entry.get("sha256", "")) \
				or String(entry.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(entry.get("bank", "")) != "0x%02X" % int(spec["bank"]) \
				or String(entry.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Fresh bank-$18 worker ROM span failed provenance/size/hash validation: %s." % file_name)
		_sources[file_name] = bytes
	if not _verify_source_boundaries():
		return false
	_configured = true
	return true


## Executes only the source bytes between the prior ROM-derived worker-entry
## state and the $C515 trampoline entry. $C515/$CB0F are not executed.
func execute_to_yield_trampoline(worker_entry: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	if not _validate_worker_entry(worker_entry):
		return {}
	_load_worker_entry(worker_entry)
	var instruction_limit := 256
	while not _at_end_boundary() and _instructions.size() < instruction_limit:
		if not _execute_one():
			return {}
	if not _at_end_boundary():
		_fail("Bank-$18 worker prefix did not reach the source $C515 boundary within its bound.")
		return {}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": ENTRY_PC,
		"entry_bank": ENTRY_BANK,
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p, "p_known_mask": _p_known_mask,
			"sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram": _selected_ram_state(),
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"stack_top_sp_plus_1_to_8": _bytes_hex(0x0100 | ((_sp + 1) & 0xFF), 8),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"scope": "ROM-byte execution of bank-$18:$800C->$8851 worker setup through JSR $C515; stops at the $CB0F yield trampoline entry",
		"next_source_call": {"pc": 0xC515, "bank": 0x1E, "target": 0xCB0F},
		"runtime_integrated": false,
		"precondition_gaps": ["This standalone prefix consumes a prior ROM-source state; no asynchronous task save/resume, scheduler scan, or NMI cadence is modeled."],
	}


## Resumes the source-dispatched slot-$05 worker after the task scheduler has
## restored its yielded RTS continuation at bank-$18:$8889. The caller owns and
## must supply the CPU/mapper/RAM/stack state. P may be omitted because the
## first LDA establishes N/Z before the branch and later carry-dependent ADCs
## clear C; when omitted, the result exposes which P bits are known.
func resume_dispatched_slot05_worker(resume_state: Dictionary,
		stop_before_source_address: int = -1) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	if not _validate_resume_state(resume_state):
		return {}
	_load_resume_state(resume_state)
	_bounded_source_stop_address = stop_before_source_address
	_bounded_source_stop_reached = false
	var instruction_limit := 8192
	while not _at_resume_boundary() and _instructions.size() < instruction_limit:
		if not _execute_one():
			return _incomplete_resume_result(resume_state)
	if not _at_resume_boundary():
		_fail("Resumed slot-$05 worker did not reach its source $C515 yield boundary within its bound.")
		return {}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"executed_source_spans": _executed_source_span_records(),
		"source_dispatch": (resume_state["source_dispatch"] as Dictionary).duplicate(true),
		"exit_kind": "yield_at_c515",
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"runtime_integrated": false,
		"status_contract": "Incoming P is optional: $8889 LDA sets N/Z before the first branch; subsequent ADC paths clear C; p_known_mask marks output bits established by executed source instructions.",
		"precondition_gaps": ["The caller must produce the yielded_rts dispatch proof and complete restored state from the live source scheduler/NMI composition."],
	}



## Continue the active slot-$05 worker from its currently adopted scheduler
## boundary. The old worker result proves continuity only; the current snapshot
## supplies every CPU, RAM, stack, and bank input.
func resume_slot05_live_worker_boundary(live_boundary: Dictionary,
		previous_worker_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	var previous_blocked: Dictionary = previous_worker_result.get("blocked_read", {})
	var previous_registers: Dictionary = previous_worker_result.get("registers", {})
	var previous_mapper: Dictionary = previous_worker_result.get("mapper", {})
	var previous_ram: PackedByteArray = previous_worker_result.get("ram_image", PackedByteArray())
	var previous_stack: PackedByteArray = previous_worker_result.get("stack_page", PackedByteArray())
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var live_stack: PackedByteArray = live_boundary.get("stack_page", PackedByteArray())
	if String(previous_worker_result.get("exit_kind", "")) != "source_read_boundary" \
			or int(previous_worker_result.get("exit_pc", -1)) != 0x89A0 \
			or int(previous_blocked.get("requested_address", -1)) != 0xBD9C \
			or int(live_boundary.get("slot_base", -1)) != 0x05 \
			or int(live_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(live_boundary.get("phase", -1)) != 2 \
			or int(live_boundary.get("pc", -1)) != 0x89A0 \
			or live_ram.size() != RAM_SIZE or live_stack.size() != 0x100 \
			or previous_ram != live_ram or previous_stack != live_stack \
			or int(live_boundary.get("a", -1)) != int(previous_registers.get("a", -2)) \
			or int(live_boundary.get("x", -1)) != int(previous_registers.get("x", -2)) \
			or int(live_boundary.get("y", -1)) != int(previous_registers.get("y", -2)) \
			or int(live_boundary.get("p", -1)) != int(previous_registers.get("p", -2)) \
			or int(live_boundary.get("p_known_mask", -1)) != int(previous_registers.get("p_known_mask", -2)) \
			or int(live_boundary.get("sp", -1)) != int(previous_registers.get("sp", -2)) \
			or int(live_boundary.get("bank_low", -1)) != int(previous_mapper.get("bank_low", -2)) \
			or int(live_boundary.get("bank_high", -1)) != int(previous_mapper.get("bank_high", -2)) \
			or int(previous_mapper.get("select", -1)) < 0 or int(previous_mapper.get("select", -1)) > 0xFF \
			or int(live_ram[0x0028]) != 0 or int(live_ram[0x003C]) != 1 \
			or int(live_ram[0x003E]) != 0x9C or int(live_ram[0x003F]) != 0xBD:
		_fail("Slot-$05 continuation is not the live adopted `$89A0->$BD9C` boundary.")
		return {}
	_ram = live_ram.duplicate()
	_a = int(live_boundary["a"]) & 0xFF
	_x = int(live_boundary["x"]) & 0xFF
	_y = int(live_boundary["y"]) & 0xFF
	_p = (int(live_boundary["p"]) | FLAG_U) & 0xFF
	_p_known_mask = int(live_boundary["p_known_mask"]) & 0xFF
	_sp = int(live_boundary["sp"]) & 0xFF
	_pc = 0x89A0
	_bank_low = int(live_boundary["bank_low"]) & 0xFF
	_bank_high = int(live_boundary["bank_high"]) & 0xFF
	_mmc3_select = int(previous_mapper["select"]) & 0xFF
	_bounded_source_stop_address = -1
	_bounded_source_stop_reached = false
	_reset_execution_trace()
	for unused in range(8192):
		if _at_resume_boundary():
			return {
				"ok": true, "rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
				"source_manifest_sha256": _manifest_sha256(),
				"executed_source_spans": _executed_source_span_records(),
				"source_continuation": {"entry_pc": 0x89A0, "source_pointer": 0xBD9C,
					"parent_blocked_address": int(previous_blocked["requested_address"])},
				"exit_kind": "yield_at_c515", "exit_pc": _pc,
				"exit_bank": _current_bank_for_pc(_pc),
				"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
					"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
				"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
					"fixed_low": 0x1E, "fixed_high": 0x1F},
				"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
				"writes": _writes.duplicate(true), "mapper_writes": _mapper_writes.duplicate(true),
				"calls": _calls.duplicate(true), "instructions": _instructions.duplicate(true),
				"instruction_count": _instructions.size(), "runtime_integrated": false,
			}
		if not _execute_one():
			return {
				"ok": false, "rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
				"source_manifest_sha256": _manifest_sha256(),
				"executed_source_spans": _executed_source_span_records(),
				"source_continuation": {"entry_pc": 0x89A0, "source_pointer": 0xBD9C,
					"parent_blocked_address": int(previous_blocked["requested_address"])},
				"exit_kind": "unresolved_source_span" if not _blocked_read.is_empty() else "unsupported_source_opcode",
				"exit_pc": _pc, "exit_bank": _current_bank_for_pc(_pc),
				"blocked_read": _blocked_read.duplicate(true), "unsupported_opcode": _unsupported_opcode.duplicate(true),
				"error": error_message,
				"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
					"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
				"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
					"fixed_low": 0x1E, "fixed_high": 0x1F},
				"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
				"writes": _writes.duplicate(true), "mapper_writes": _mapper_writes.duplicate(true),
				"calls": _calls.duplicate(true), "instructions": _instructions.duplicate(true),
				"instruction_count": _instructions.size(), "runtime_integrated": false,
			}
	_fail("Slot-$05 live continuation exceeded its instruction bound.")
	return {}


## Validates the ROM-owned descriptor path before the resumed worker is allowed
## to read its dynamic text tokens. This proves the live `$0515` branch and the
## hash-checked lookup/descriptor/text/callback bytes; it does not synthesize
## the pointer or claim that an unexecuted `$F0` row was consumed.
func validate_resumed_worker_descriptor_contract(resume_state: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return {"ok": false, "status": "unconfigured", "reason": "Configure hash-checked worker spans first."}
	if not _validate_resume_state(resume_state):
		return {"ok": false, "status": "invalid_live_resume_state", "reason": error_message}
	var registers: Dictionary = resume_state["registers"]
	var mapper: Dictionary = resume_state["mapper"]
	var ram: PackedByteArray = resume_state["ram_image"]
	var flag_0515 := int(ram[0x0515])
	if flag_0515 != 0:
		return {
			"ok": true,
			"status": "source_reyield_before_descriptor",
			"live_flag_0515": flag_0515,
			"worker_branch_pc": 0x8889,
			"descriptor_tokens_reached": false,
		}
	if int(mapper.get("bank_high", -1)) != 0x19:
		return {"ok": false, "status": "unsupported_descriptor_bank", "reason": "Live descriptor table must be mapped in bank $19."}
	var lookup: PackedByteArray = _sources["bank19_worker_lookup_B3BD_B3D1.bin"]
	var descriptor: PackedByteArray = _sources["bank19_match_descriptor_B453_B464.bin"]
	var lookup_second: PackedByteArray = _sources["bank19_worker_lookup_tail_B3D1_B3D3.bin"]
	var descriptor01: PackedByteArray = _sources["bank19_match_descriptor_B464_B475.bin"]
	var descriptor01_row00: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin"]
	var text_lead: PackedByteArray = _sources["bank19_resumed_worker_text_lead_BBDC_BBDE.bin"]
	var text_second_row: PackedByteArray = _sources["bank19_resumed_worker_text_row01_BBDE_BBE0.bin"]
	var ef_callback: PackedByteArray = _sources["bank18_callback_pointer_89D8_89DA.bin"]
	var fc_callback: PackedByteArray = _sources["bank18_fc_callback_return_8C52_8C55.bin"]
	var descriptor_pointer := int(lookup[18]) | (int(lookup[19]) << 8)
	var text_pointer := int(descriptor[11]) | (int(descriptor[12]) << 8)
	var descriptor01_pointer := int(lookup_second[0]) | (int(lookup_second[1]) << 8)
	var descriptor01_text_pointer := int(descriptor01[11]) | (int(descriptor01[12]) << 8)
	var descriptor01_next_row_pointer := int(descriptor01[15]) | (int(descriptor01[16]) << 8)
	if descriptor_pointer != 0xB453 or text_pointer != 0xBBDC \
			or descriptor01_pointer != 0xB464 or descriptor01_text_pointer != 0xBBE0 \
			or descriptor01_next_row_pointer != 0xBD9C \
			or descriptor01_row00 != PackedByteArray([0xED, 0x00, 0xFC]) \
			or text_lead != PackedByteArray([0xEF, 0xFC]) \
			or text_second_row != PackedByteArray([0xF0, 0xFC]) \
			or ef_callback != PackedByteArray([0x48, 0x8B]) \
			or fc_callback != PackedByteArray([0x68, 0x68, 0x60]):
		return {"ok": false, "status": "unsupported_descriptor_source", "reason": "Hash-checked lookup, descriptor, text lead, or callback bytes differ from the resumed worker contract."}
	return {
		"ok": true,
		"status": "descriptor_source_validated_for_live_worker",
		"live_flag_0515": flag_0515,
		"live_cpu": {"a": int(registers["a"]), "x": int(registers["x"]),
			"y": int(registers["y"]), "sp": int(registers["sp"]), "pc": int(registers["pc"])},
		"live_bank_pair": [int(mapper["bank_low"]), int(mapper["bank_high"])],
		"descriptor_table_pointer_cpu": 0xB453,
		"descriptor_text_pointer_cpu": text_pointer,
		"second_descriptor_pointer_cpu": descriptor01_pointer,
		"descriptor01_text_pointer_cpu": descriptor01_text_pointer,
		"descriptor01_row00_hex": descriptor01_row00.hex_encode(),
		"descriptor01_next_row_pointer_cpu": descriptor01_next_row_pointer,
		"descriptor01_next_row_executed": false,
		"descriptor_text_lead_hex": text_lead.hex_encode(),
		"descriptor_second_row_hex": text_second_row.hex_encode(),
		"descriptor_second_row_source_validated": true,
		"ef_callback_cpu": int(ef_callback[0]) | (int(ef_callback[1]) << 8),
		"fc_callback_cpu": 0x8C52,
		"descriptor_tokens_expected": [0xEF, 0xFC],
		"next_descriptor_row_token": 0xF0,
		"next_descriptor_row_executed": false,
		"source_manifest_sha256": _manifest_sha256(),
	}


## Validates the ROM `$EE 00 FC` handler/formatter return from the adopted live `$BD9C` boundary.
## The worker reaches `$C515`; the descriptor identifies `$BBE3` as the following row, but
## the live text pointer does not advance to it within this worker invocation.
func validate_descriptor01_ee_row00_boundary(live_boundary: Dictionary,
		previous_worker_result: Dictionary, worker_result: Dictionary) -> Dictionary:
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var continuation_variant: Variant = worker_result.get("source_continuation", {})
	var previous_blocked_variant: Variant = previous_worker_result.get("blocked_read", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not continuation_variant is Dictionary or not previous_blocked_variant is Dictionary:
		return {"ok": false, "status": "malformed_live_continuation"}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var continuation: Dictionary = continuation_variant
	var previous_blocked: Dictionary = previous_blocked_variant
	var input_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var descriptor_tail: PackedByteArray = _sources["bank19_match_descriptor_B475_B47D.bin"]
	if String(worker_result.get("source_manifest_sha256", "")) != _manifest_sha256() \
			or String(previous_worker_result.get("source_manifest_sha256", "")) != _manifest_sha256() \
			or String(previous_worker_result.get("exit_kind", "")) != "source_read_boundary" \
			or int(previous_worker_result.get("exit_pc", -1)) != 0x89A0 \
			or int(previous_blocked.get("requested_address", -1)) != 0xBD9C \
			or int(live_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(live_boundary.get("pc", -1)) != 0x89A0 \
			or input_ram.size() != RAM_SIZE or int(input_ram[0x0028]) != 0 \
			or int(input_ram[0x003C]) != 1 \
			or int(continuation.get("entry_pc", -1)) != 0x89A0 \
			or int(continuation.get("source_pointer", -1)) != 0xBD9C \
			or not bool(worker_result.get("ok", false)) \
			or String(worker_result.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker_result.get("exit_pc", -1)) != 0xC515 \
			or int(registers.get("pc", -1)) != 0xC515 \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or ram.size() != RAM_SIZE or stack.size() != 0x100 \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x003E]) != 0x9C or int(ram[0x003F]) != 0xBD \
			or int(ram[0x003C]) != 1 or int(ram[0x0515]) != 0x80 \
			or int(ram[0x05C5]) != 2:
		return {"ok": false, "status": "descriptor01_ee_row00_boundary_mismatch",
			"exit_pc": int(worker_result.get("exit_pc", -1)),
			"live_text_pointer": int(ram[0x003E]) | (int(ram[0x003F]) << 8),
			"previous_exit_kind": String(previous_worker_result.get("exit_kind", "")),
			"previous_blocked": previous_blocked.duplicate(true),
			"live": {"slot": int(live_boundary.get("active_task_slot", -1)),
				"pc": int(live_boundary.get("pc", -1)), "selector": int(input_ram[0x0028]),
				"progress": int(input_ram[0x003C])},
			"worker": {"ok": bool(worker_result.get("ok", false)),
				"kind": String(worker_result.get("exit_kind", "")),
				"pc": int(worker_result.get("exit_pc", -1)),
				"manifest_match": String(worker_result.get("source_manifest_sha256", "")) == _manifest_sha256(),
				"parent_manifest_match": String(previous_worker_result.get("source_manifest_sha256", "")) == _manifest_sha256(),
				"register_pc": int(registers.get("pc", -1)),
				"banks": [int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))],
				"progress": int(ram[0x003C]), "ready": int(ram[0x0515]), "progress_state": int(ram[0x05C5]),
				"stack_matches": ram.slice(0x0100, 0x0200) == stack}}
	var pcs := {}
	var early_branch := false
	var fc_return := false
	for instruction_variant in worker_result.get("instructions", []):
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		var pc := int(instruction.get("pc", -1))
		pcs[pc] = true
		if pc == 0x8C58 and int(instruction.get("next_pc", -1)) == 0x8C84:
			early_branch = true
		if pc == 0x8C54 and int(instruction.get("next_pc", -1)) == 0x896C:
			fc_return = true
	for required_pc in [0x8B2F, 0x8C55, 0x8C58, 0x8C84, 0x8C52, 0x8C54, 0x896C]:
		if not pcs.has(required_pc):
			return {"ok": false, "status": "missing_source_pc", "pc": required_pc}
	var early_rts := false
	for instruction_variant in worker_result.get("instructions", []):
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			if int(instruction.get("pc", -1)) == 0x8C84 \
					and int(instruction.get("opcode", -1)) == 0x60:
				early_rts = true
	if not early_branch or not fc_return or not early_rts:
		return {"ok": false, "status": "ee_early_return_or_fc_chain_mismatch",
			"early_branch": early_branch, "fc_return": fc_return,
			"early_rts": early_rts,
			"trace_tail": (worker_result.get("instructions", []) as Array).slice(-16)}
	if descriptor_tail.size() != 8 \
			or (int(descriptor_tail[2]) | (int(descriptor_tail[3]) << 8)) != 0xBBE3:
		return {"ok": false, "status": "next_descriptor_row_source_mismatch"}
	var required_spans := {
		"bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin": false,
		"bank18_ee_numeric_handler_8B2F_8B48.bin": false,
		"bank18_f0_decimal_formatter_8C55_8C85.bin": false,
	}
	for span_variant in worker_result.get("executed_source_spans", []):
		if span_variant is Dictionary:
			var name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(name):
				required_spans[name] = true
	for name in required_spans:
		if not bool(required_spans[name]):
			return {"ok": false, "status": "missing_source_span", "file": name}
	return {"ok": true, "status": "descriptor01_ee_row00_yielded_at_c515",
		"row_cpu": 0xBD9C, "row_bytes_hex": "ee00fc", "ee_handler_cpu": 0x8B2F,
		"formatter_cpu": 0x8C55, "formatter_early_return_pc": 0x8C84,
		"fc_return_cpu": 0x8C52, "fc_return_to_pc": 0x896C,
		"worker_yield_pc": 0xC515, "live_text_pointer_after_row": 0xBD9C,
		"next_descriptor_row_cpu": 0xBBE3, "next_descriptor_row_pointer_live": false,
		"next_row_bytes_read": false,
		"live_team_selector_0028": int(input_ram[0x0028]),
		"source_progress_input": int(input_ram[0x003C]),
		"source_progress_output": int(ram[0x003C]),
		"source_manifest_sha256": _manifest_sha256()}


## Accepts only the live worker result that has consumed `$BBE0: ED 00 FC`,
## returned through the ROM inline `$FC` handler, and is blocked before the
## next row at `$BD9C`. The `$EE` row itself is deliberately not supplied.
func validate_descriptor01_ed_row00_boundary(worker_input: Dictionary,
		worker_result: Dictionary) -> Dictionary:
	var input_ram_variant: Variant = worker_input.get("ram_image", PackedByteArray())
	var result_ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var result_stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var blocked_variant: Variant = worker_result.get("blocked_read", {})
	var source_stop_variant: Variant = worker_result.get("source_boundary_stop", {})
	if not input_ram_variant is PackedByteArray or not result_ram_variant is PackedByteArray \
			or not result_stack_variant is PackedByteArray or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not blocked_variant is Dictionary \
			or not source_stop_variant is Dictionary:
		return {"ok": false, "status": "malformed_worker_boundary"}
	var input_ram: PackedByteArray = input_ram_variant
	var result_ram: PackedByteArray = result_ram_variant
	var result_stack: PackedByteArray = result_stack_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var blocked: Dictionary = blocked_variant
	var source_stop: Dictionary = source_stop_variant
	var valid := not bool(worker_result.get("ok", true)) \
		and String(worker_result.get("exit_kind", "")) == "source_read_boundary" \
		and int(source_stop.get("address", -1)) == 0xBD9C \
		and bool(source_stop.get("source_bytes_available", false)) \
		and String(worker_result.get("source_manifest_sha256", "")) == _manifest_sha256() \
		and int(worker_result.get("exit_pc", -1)) == 0x89A0 \
		and int(blocked.get("instruction_pc", -1)) == 0x89A0 \
		and int(blocked.get("requested_address", -1)) == 0xBD9C \
		and int(blocked.get("bank", -1)) == 0x19 \
		and int(registers.get("pc", -1)) == 0x89A0 \
		and int(mapper.get("bank_low", -1)) == 0x18 \
		and int(mapper.get("bank_high", -1)) == 0x19 \
		and input_ram.size() == RAM_SIZE and result_ram.size() == RAM_SIZE \
		and result_stack.size() == 0x100 \
		and int(input_ram[0x002A]) == 0 \
		and int(result_ram[0x002A]) == 0 \
		and int(result_ram[0x003C]) == 1 \
		and int(result_ram[0x0515]) == 1 \
		and int(result_ram[0x05C5]) == 0 \
		and int(result_ram[0x003E]) == 0x9C and int(result_ram[0x003F]) == 0xBD
	if not valid:
		return {"ok": false, "status": "descriptor01_ed_row00_boundary_mismatch",
			"blocked_read": blocked.duplicate(true), "result_pointer": [int(result_ram[0x003E]), int(result_ram[0x003F])]}
	for index in range(0x100):
		if result_ram[0x0100 + index] != result_stack[index]:
			return {"ok": false, "status": "stack_page_mismatch", "index": index}
	var required_pcs := {0x89A0: false, 0x896C: false, 0x8AE7: false, 0x8A6F: false,
		0x8B03: false, 0xC524: false, 0xCBC2: false, 0x8C9F: false,
		0x8C52: false, 0x8C54: false, 0x89A9: false}
	var return_index := -1
	var ee_handler_entered := false
	var instructions_variant: Variant = worker_result.get("instructions", [])
	if not instructions_variant is Array:
		return {"ok": false, "status": "missing_worker_instructions"}
	var instructions: Array = instructions_variant
	for index in range(instructions.size()):
		var instruction_variant: Variant = instructions[index]
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		var pc := int(instruction.get("pc", -1))
		if pc == 0x8B2F:
			ee_handler_entered = true
		if required_pcs.has(pc):
			required_pcs[pc] = true
		if pc == 0x8C54 and int(instruction.get("next_pc", -1)) == 0x896C:
			return_index = index
	for required_pc in required_pcs:
		if not bool(required_pcs[required_pc]):
			return {"ok": false, "status": "missing_source_pc", "pc": required_pc}
	if ee_handler_entered:
		return {"ok": false, "status": "ee_handler_was_executed"}
	if return_index < 0:
		return {"ok": false, "status": "fc_return_not_observed"}
	var required_spans := {
		"bank19_match_descriptor_B464_B475.bin": false,
		"bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin": false,
		"bank18_ed_text_loop_8A56_8A86.bin": false,
		"bank18_ed_team_handler_8AE7_8B0A.bin": false,
		"bank18_ed_team_name_lengths_8B0A_8B0E.bin": false,
		"fixed_team_name_dispatch_C53C_C53F.bin": false,
		"fixed_team_name_lookup_F30F_F329.bin": false,
		"fixed_team_name_pointer_entries_76_79_F415_F41D.bin": false,
		"fixed_team_00_name_stream_F776_F77C.bin": false,
		"fixed_text_token_converter_CBC2_CBF1.bin": false,
	}
	var spans_variant: Variant = worker_result.get("executed_source_spans", [])
	if not spans_variant is Array:
		return {"ok": false, "status": "missing_executed_source_spans"}
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			var file_name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(file_name):
				required_spans[file_name] = true
	for file_name in required_spans:
		if not bool(required_spans[file_name]):
			return {"ok": false, "status": "missing_source_span", "file": file_name}
	var row_clear_seen := false
	var row_increment_seen := false
	var writes_variant: Variant = worker_result.get("writes", [])
	if not writes_variant is Array:
		return {"ok": false, "status": "missing_source_writes"}
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x003C and int(write.get("pc", -1)) == 0x8954 \
				and int(write.get("value", -1)) == 0:
			row_clear_seen = true
		if int(write.get("address", -1)) == 0x003C and int(write.get("pc", -1)) == 0x8960 \
				and int(write.get("value", -1)) == 1:
			row_increment_seen = true
	if not row_clear_seen or not row_increment_seen:
		return {"ok": false, "status": "row_progress_not_source_produced"}
	return {
		"ok": true,
		"status": "descriptor01_ed_row00_returned_before_ee_row",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": _manifest_sha256(),
		"row_cpu": 0xBBE0,
		"row_bytes_hex": "ed00fc",
		"ed_handler_cpu": 0x8AE7,
		"ed_text_loop_cpu": 0x8A6F,
		"fc_return_cpu": 0x8C52,
		"fc_return_to_pc": 0x896C,
		"next_row_cpu": 0xBD9C,
		"next_row_read_executed": false,
		"live_home_team_id": int(input_ram[0x002A]),
		"source_produced_row_progress": int(result_ram[0x003C]),
		"next_text_pointer": int(result_ram[0x003E]) | (int(result_ram[0x003F]) << 8),
		"result_flag_0515": int(result_ram[0x0515]),
		"source_produced_writes": {"row_clear_pc": 0x8954, "row_increment_pc": 0x8960},
	}


func _validate_resume_state(resume_state: Dictionary) -> bool:
	var dispatch_variant: Variant = resume_state.get("source_dispatch", {})
	var registers_variant: Variant = resume_state.get("registers", {})
	var mapper_variant: Variant = resume_state.get("mapper", {})
	var ram_variant: Variant = resume_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = resume_state.get("stack_page", PackedByteArray())
	if not dispatch_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _fail("Worker resume requires source-dispatch proof, complete CPU/mapper state, full RAM image, and stack page.")
	var dispatch: Dictionary = dispatch_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	if String(dispatch.get("rom_sha256", "")) != ROM_SHA256 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("bank", -1)) != 0x18 \
			or not bool(dispatch.get("source_dispatch_observed", false)):
		return _fail("Worker resume proof must identify a source-observed slot-$05 yielded_rts dispatch at bank-$18:$8889 for the target ROM.")
	for name: String in ["a", "x", "y", "sp", "pc"]:
		if not registers.has(name) or int(registers[name]) < 0 or int(registers[name]) > 0xFFFF:
			return _fail("Worker resume CPU state is incomplete or invalid at register %s." % name)
	if registers.has("p") and (int(registers["p"]) < 0 or int(registers["p"]) > 0xFF):
		return _fail("Worker resume status register P must be an 8-bit value when supplied.")
	if int(registers["pc"]) != 0x8889:
		return _fail("Worker resume CPU PC must match the verified $8889 continuation.")
	if int(registers["a"]) > 0xFF or int(registers["x"]) > 0xFF \
			or int(registers["y"]) > 0xFF or int(registers["sp"]) > 0xFF:
		return _fail("Worker resume CPU registers must be 8-bit values.")
	if int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) < 0 or int(mapper.get("select", -1)) > 0xFF:
		return _fail("Worker resume mapper state must preserve the source $18/$19 slot-$05 mapping and an 8-bit MMC3 selector.")
	if (ram_variant as PackedByteArray).size() != RAM_SIZE \
			or (stack_variant as PackedByteArray).size() != 0x100:
		return _fail("Worker resume requires an 2 KiB RAM image and a 256-byte stack page.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if ram.slice(0x0100, 0x0200) != stack:
		return _fail("Worker resume stack page does not match bytes $0100-$01FF in its RAM image.")
	return true


func _load_resume_state(resume_state: Dictionary) -> void:
	var registers: Dictionary = resume_state["registers"]
	var mapper: Dictionary = resume_state["mapper"]
	_ram = (resume_state["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = resume_state["stack_page"]
	for index in range(0x100):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = (int(registers["p"]) | FLAG_U) & 0xFF if registers.has("p") else FLAG_U
	_p_known_mask = 0xFF if registers.has("p") else FLAG_U
	_sp = int(registers["sp"]) & 0xFF
	_pc = 0x8889
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF
	_reset_execution_trace()


func _reset_execution_trace() -> void:
	_writes.clear()
	_mapper_writes.clear()
	_calls.clear()
	_instructions.clear()
	_executed_source_files.clear()
	_blocked_read.clear()
	_unsupported_opcode.clear()


func _at_resume_boundary() -> bool:
	return _pc == 0xC515 and _current_bank_for_pc(_pc) == 0x1E


func _validate_worker_entry(worker_entry: Dictionary) -> bool:
	if not bool(worker_entry.get("ok", false)) \
			or String(worker_entry.get("rom_sha256", "")) != ROM_SHA256 \
			or int(worker_entry.get("exit_pc", -1)) != ENTRY_PC \
			or int(worker_entry.get("exit_bank", -1)) != ENTRY_BANK:
		return _fail("Worker prefix requires the source-owned bank-$18:$800C result from RomFreshDaaaContinuation.")
	var registers_variant: Variant = worker_entry.get("registers", {})
	var mapper_variant: Variant = worker_entry.get("mapper", {})
	var ram_variant: Variant = worker_entry.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_entry.get("stack_page", PackedByteArray())
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return _fail("Worker entry lacks source-derived registers, mapper, full RAM image, or stack page.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	if int(registers.get("a", -1)) != 0x00 or int(registers.get("x", -1)) != 0x00 \
			or int(registers.get("y", -1)) != 0x00 or int(registers.get("p", -1)) != 0x23 \
			or int(registers.get("sp", -1)) != 0x4A \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("Worker input CPU/mapper state is not the first source-owned bank-$18:$800C entry.")
	if (ram_variant as PackedByteArray).size() != RAM_SIZE or (stack_variant as PackedByteArray).size() != 0x100:
		return _fail("Worker input RAM or stack-page size is incomplete.")
	return true


func _load_worker_entry(worker_entry: Dictionary) -> void:
	var registers: Dictionary = worker_entry["registers"]
	var mapper: Dictionary = worker_entry["mapper"]
	_ram = (worker_entry["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = worker_entry["stack_page"]
	for index in range(0x100):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = (int(registers["p"]) | FLAG_U) & 0xFF
	_p_known_mask = 0xFF
	_sp = int(registers["sp"]) & 0xFF
	_pc = ENTRY_PC
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF
	_reset_execution_trace()


func _at_end_boundary() -> bool:
	return _pc == END_PC and _current_bank_for_pc(_pc) == END_BANK


func _execute_one() -> bool:
	var start_pc := _pc
	var start_bank := _current_bank_for_pc(_pc)
	var opcode := _read_cpu(_pc)
	if opcode < 0:
		return false
	_write_trace_pc = (_pc + _opcode_length(opcode)) & 0xFFFF
	match opcode:
		0x4C: # JMP abs
			_pc = _read_word(_pc + 1)
			if _pc < 0: return false
		0x6C: # JMP (abs), including the 6502 page-wrap behavior
			var pointer := _read_word(_pc + 1)
			if pointer < 0: return false
			var low := _read_cpu(pointer)
			var high_address := (pointer & 0xFF00) | ((pointer + 1) & 0x00FF)
			var high := _read_cpu(high_address)
			if low < 0 or high < 0: return false
			_pc = low | (high << 8)
		0x10, 0x30, 0x50, 0x70, 0x90, 0xB0, 0xD0, 0xF0: # conditional branches
			var displacement := _read_cpu(_pc + 1)
			if displacement < 0: return false
			if displacement >= 0x80: displacement -= 0x100
			var branch := (opcode == 0x10 and (_p & FLAG_N) == 0) \
				or (opcode == 0x30 and (_p & FLAG_N) != 0) \
				or (opcode == 0x50 and (_p & FLAG_V) == 0) \
				or (opcode == 0x70 and (_p & FLAG_V) != 0) \
				or (opcode == 0x90 and (_p & FLAG_C) == 0) \
				or (opcode == 0xB0 and (_p & FLAG_C) != 0) \
				or (opcode == 0xD0 and (_p & FLAG_Z) == 0) \
				or (opcode == 0xF0 and (_p & FLAG_Z) != 0)
			_pc = _pc + 2 + displacement if branch else _pc + 2
		0x18: # CLC
			_set_flag(FLAG_C, false)
			_pc += 1
		0x38: # SEC
			_set_flag(FLAG_C, true)
			_pc += 1
		0x60: # RTS
			var return_low := _pop(start_pc, start_bank)
			var return_high := _pop(start_pc, start_bank)
			if return_low < 0 or return_high < 0: return false
			_pc = ((return_high << 8) | return_low) + 1
		0x48: # PHA
			if not _push(_a, start_pc, start_bank): return false
			_pc += 1
		0x68: # PLA
			_a = _pop(start_pc, start_bank)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 1
		0xA8: # TAY
			_y = _a
			_set_nz(_y)
			_pc += 1
		0x88: # DEY
			_y = (_y - 1) & 0xFF
			_set_nz(_y)
			_pc += 1
		0xC8: # INY
			_y = (_y + 1) & 0xFF
			_set_nz(_y)
			_pc += 1
		0x0A: # ASL A
			_set_flag(FLAG_C, (_a & 0x80) != 0)
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
		0xBD: # LDA abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _x) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0x85: # STA zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 2
		0x98: # TYA
			_a = _y
			_set_nz(_a)
			_pc += 1
		0x29: # AND #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a &= value
			_set_nz(_a)
			_pc += 2
		0x09: # ORA #imm; fixed mapper helper $CE2D
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0xC5: # CMP zp; used by the ROM match-clock divider
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x4A: # LSR A
			_set_flag(FLAG_C, (_a & 0x01) != 0)
			_a = (_a >> 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xB9: # LDA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xCA: # DEX
			_x = (_x - 1) & 0xFF
			_set_nz(_x)
			_pc += 1
		0x8D: # STA abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 3
		0x99: # STA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu((address + _y) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 3
		0x9D: # STA abs,X
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu((address + _x) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 3
		0x86: # STX zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _x, start_pc, start_bank): return false
			_pc += 2
		0x84: # STY zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _y, start_pc, start_bank): return false
			_pc += 2
		0xAD: # LDA abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xAE: # LDX abs; source $ED team-name handler reads the live home-team selector
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_x = _read_cpu(address)
			if _x < 0: return false
			_set_nz(_x)
			_pc += 3
		0xA5: # LDA zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0xA4, 0xA6: # LDY zp, LDX zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			if opcode == 0xA4:
				_y = value
				_set_nz(_y)
			else:
				_x = value
				_set_nz(_x)
			_pc += 2
		0xAC: # LDY abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_y = _read_cpu(address)
			if _y < 0: return false
			_set_nz(_y)
			_pc += 3
		0xA0, 0xA2: # LDY #, LDX #
			var immediate := _read_cpu(_pc + 1)
			if immediate < 0: return false
			if opcode == 0xA0:
				_y = immediate
				_set_nz(_y)
			else:
				_x = immediate
				_set_nz(_x)
			_pc += 2
		0xB1: # LDA (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_a = value
			_set_nz(_a)
			_pc += 2
		0x71: # ADC (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 2
		0xD1: # CMP (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x6D: # ADC abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 3
		0x65: # ADC zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 2
		0xA9: # LDA #imm
			_a = _read_cpu(_pc + 1)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x69: # ADC #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 2
		0xE9: # SBC #imm; 2A03 ignores decimal mode
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_add_with_carry(value ^ 0xFF)
			_pc += 2
		0xE5: # SBC zp; used by the ROM match-clock divider
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value ^ 0xFF)
			_pc += 2
		0xE8: # INX
			_x = (_x + 1) & 0xFF
			_set_nz(_x)
			_pc += 1
		0xE6, 0xC6: # INC zp, DEC zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			value = (value + (1 if opcode == 0xE6 else -1)) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 2
		0xEE, 0xCE: # INC abs, DEC abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			value = (value + (1 if opcode == 0xEE else -1)) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 3
		0xE0: # CPX #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_x, value)
			_pc += 2
		0xC0: # CPY #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_y, value)
			_pc += 2
		0xC9: # CMP #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x49: # EOR #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a = (_a ^ value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0xCD: # CMP abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_compare(_a, value)
			_pc += 3
		0x24: # BIT zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_N, (value & 0x80) != 0)
			_set_flag(FLAG_V, (value & 0x40) != 0)
			_set_flag(FLAG_Z, (_a & value) == 0)
			_pc += 2
		0x66: # ROR zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			var carry_in := 0x80 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (value & 0x01) != 0)
			value = ((value >> 1) | carry_in) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 2
		0x26: # ROL zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			var carry_in := 1 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (value & 0x80) != 0)
			value = ((value << 1) | carry_in) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 2
		0x1D: # ORA abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu((address + _x) & 0xFFFF)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 3
		0xD8: # CLD
			_p &= ~0x08
			_p |= FLAG_U
			_p_known_mask |= 0x28
			_pc += 1
		0x20: # JSR
			_write_trace_pc = (_pc + 2) & 0xFFFF
			var target := _read_word(_pc + 1)
			if target < 0: return false
			var return_minus_one := (_pc + 2) & 0xFFFF
			if not _push((return_minus_one >> 8) & 0xFF, start_pc, start_bank) \
					or not _push(return_minus_one & 0xFF, start_pc, start_bank): return false
			_calls.append({"callsite": start_pc, "target": target,
				"bank": _current_bank_for_pc(target), "sp_after_push": _sp})
			_pc = target
		_:
			_unsupported_opcode = {"pc": start_pc, "bank": start_bank, "opcode": opcode}
			return _fail("Unsupported worker-prefix opcode $%02X at $%04X (bank $%02X)." % [opcode, start_pc, start_bank])
	_instructions.append({"pc": start_pc, "bank": start_bank, "opcode": opcode, "next_pc": _pc})
	return true


func _add_with_carry(value: int) -> void:
	var before := _a
	var sum := before + value + (1 if (_p & FLAG_C) != 0 else 0)
	_set_flag(FLAG_C, sum > 0xFF)
	_set_flag(FLAG_V, ((~(before ^ value) & (before ^ sum)) & 0x80) != 0)
	_a = sum & 0xFF
	_set_nz(_a)


func _compare(register_value: int, operand: int) -> void:
	var difference := (register_value & 0xFF) - (operand & 0xFF)
	_set_flag(FLAG_C, difference >= 0)
	_set_nz(difference & 0xFF)


func _read_word(address: int) -> int:
	var low := _read_cpu(address)
	var high := _read_cpu(address + 1)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _indirect_target(operand_pc: int) -> int:
	var zp_address := _read_cpu(operand_pc)
	if zp_address < 0:
		return -1
	return int(_ram[zp_address & 0xFF]) | (int(_ram[(zp_address + 1) & 0xFF]) << 8)


func _read_cpu(address: int) -> int:
	if address < 0 or address > 0xFFFF:
		_fail("Worker-prefix read outside address space at $%X." % address)
		return -1
	if _pc == 0x89A0 and _bounded_source_stop_address >= 0 \
			and address == _bounded_source_stop_address:
		_bounded_source_stop_reached = true
		_blocked_read = {"instruction_pc": _pc, "requested_address": address,
			"bank": _current_bank_for_pc(address),
			"reason": "Caller-selected stop before this mapped source row."}
		return -1
	if address < 0x2000:
		return int(_ram[address & 0x07FF])
	var bank := _current_bank_for_pc(address)
	for file_name: String in SOURCE_FILES:
		var spec: Dictionary = SOURCE_FILES[file_name]
		if int(spec["bank"]) == bank and address >= int(spec["start"]) and address < int(spec["end"]):
			_executed_source_files[file_name] = true
			return int((_sources[file_name] as PackedByteArray)[address - int(spec["start"])])
	_blocked_read = {"instruction_pc": _pc, "requested_address": address, "bank": bank,
		"reason": "ROM byte is not present in the hash-checked source manifest."}
	_fail("Worker-prefix ROM read $%04X in bank $%02X is outside preserved spans while executing $%04X." % [address, bank, _pc])
	return -1


func _incomplete_resume_result(resume_state: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"executed_source_spans": _executed_source_span_records(),
		"source_dispatch": (resume_state["source_dispatch"] as Dictionary).duplicate(true),
		"exit_kind": "source_read_boundary" if _bounded_source_stop_reached else \
			("unresolved_source_span" if not _blocked_read.is_empty() else "unsupported_source_opcode"),
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"blocked_read": _blocked_read.duplicate(true),
		"source_boundary_stop": {"address": _bounded_source_stop_address,
			"source_bytes_available": true} if _bounded_source_stop_reached else {},
		"unsupported_opcode": _unsupported_opcode.duplicate(true),
		"error": error_message,
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"runtime_integrated": false,
	}


func _write_cpu(address: int, value: int, source_pc: int, source_bank: int) -> bool:
	value &= 0xFF
	if address < 0x2000:
		var mirrored := address & 0x07FF
		_ram[mirrored] = value
		_writes.append({"pc": source_pc, "trace_pc": _write_trace_pc, "bank": source_bank,
			"address": mirrored, "value": value})
		return true
	if address == 0x8000:
		_mmc3_select = value & 0x07
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	if address == 0x8001:
		if _mmc3_select == 6: _bank_low = value
		elif _mmc3_select == 7: _bank_high = value
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	return _fail("Unsupported worker-prefix memory-mapped write $%04X=$%02X at $%04X." % [address, value, source_pc])


func _push(value: int, source_pc: int, source_bank: int) -> bool:
	if not _write_cpu(0x0100 | _sp, value, source_pc, source_bank): return false
	_sp = (_sp - 1) & 0xFF
	return true


func _pop(source_pc: int, source_bank: int) -> int:
	_sp = (_sp + 1) & 0xFF
	var value := _read_cpu(0x0100 | _sp)
	if value < 0:
		_fail("Worker resume stack pop failed at $%04X (bank $%02X)." % [source_pc, source_bank])
	return value


func _set_nz(value: int) -> void:
	_set_flag(FLAG_Z, (value & 0xFF) == 0)
	_set_flag(FLAG_N, (value & 0x80) != 0)


func _set_flag(mask: int, enabled: bool) -> void:
	if enabled: _p |= mask
	else: _p &= ~mask
	_p |= FLAG_U
	_p_known_mask |= mask | FLAG_U


func _current_bank_for_pc(address: int) -> int:
	if address >= 0xC000 and address < 0xE000: return 0x1E
	if address >= 0xE000: return 0x1F
	if address >= 0xA000 and address < 0xC000: return _bank_high
	return _bank_low


func _opcode_length(opcode: int) -> int:
	match opcode:
		0x09, 0x10, 0x24, 0x26, 0x29, 0x30, 0x49, 0x50, 0x65, 0x66, 0x69, 0x70, 0x71, \
			0x84, 0x85, 0x86, 0x90, 0xA0, 0xA2, 0xA4, 0xA5, 0xA6, 0xA9, 0xB0, 0xB1, \
			0xC0, 0xC5, 0xC6, 0xC9, 0xD0, 0xD1, 0xE0, 0xE5, 0xE6, 0xE9, 0xF0:
			return 2
		0x1D, 0x20, 0x4C, 0x6C, 0x6D, 0x8D, 0x99, 0x9D, 0xAC, 0xAD, 0xAE, 0xB9, 0xBD, 0xCD, 0xCE, 0xEE:
			return 3
		_:
			return 1


func _selected_ram_state() -> Dictionary:
	return {
		"$0022": int(_ram[0x0022]), "$0023": int(_ram[0x0023]),
		"$0024": int(_ram[0x0024]), "$0025": int(_ram[0x0025]),
		"$0050": int(_ram[0x0050]), "$0051": int(_ram[0x0051]),
		"$05C5": int(_ram[0x05C5]), "$05C6": int(_ram[0x05C6]),
		"$0700-$0704": _bytes_hex(0x0700, 5),
	}


func _bytes_hex(start: int, count: int) -> String:
	var output := PackedByteArray()
	for offset in range(count): output.append(int(_ram[start + offset]))
	return output.hex_encode()


func _verify_source_boundaries() -> bool:
	var worker_bytes: PackedByteArray = _sources["bank18_worker_entry_to_yield_call_800C_8889.bin"]
	var resume_bytes: PackedByteArray = _sources["bank18_worker_resume_8889_89D7.bin"]
	var descriptor01_row00: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin"]
	var descriptor01_row02: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row02_BBE3_BBE6.bin"]
	var descriptor01_row01: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin"]
	var descriptor01_row03: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row03_BD9F_BDA2.bin"]
	var descriptor01_tail: PackedByteArray = _sources["bank19_match_descriptor_B475_B47D.bin"]
	var ee_handler: PackedByteArray = _sources["bank18_ee_numeric_handler_8B2F_8B48.bin"]
	var call_offset := 0x8886 - 0x800C
	if worker_bytes.slice(0, 3) != PackedByteArray([0x4C, 0x51, 0x88]) \
			or worker_bytes.slice(call_offset - 2, call_offset + 3) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _fail("Bank-$18 worker entry or $8886 JSR boundary bytes changed.")
	var ed_vector_offset := (0x89BA - 0x8889) + ((0xED - 0xE0) * 2)
	if descriptor01_row00 != PackedByteArray([0xED, 0x00, 0xFC]) \
			or descriptor01_row02 != PackedByteArray([0xED, 0x01, 0xFC]) \
			or descriptor01_row01 != PackedByteArray([0xEE, 0x00, 0xFC]) \
			or descriptor01_row03 != PackedByteArray([0xEE, 0x01, 0xFC]) \
			or descriptor01_tail != PackedByteArray([0x03, 0x01, 0xE3, 0xBB, 0x03, 0x05, 0x9F, 0xBD]) \
			or ee_handler != PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xB1, 0x3E, 0xAA,
				0xBD, 0x28, 0x00, 0xAC, 0x27, 0x00, 0xC0, 0x04, 0xD0, 0x03,
				0xBD, 0x10, 0x06, 0xA2, 0x00, 0x4C, 0x55, 0x8C]) \
			or resume_bytes.slice(ed_vector_offset, ed_vector_offset + 2) != PackedByteArray([0xE7, 0x8A]) \
			or (_sources["bank18_ed_team_handler_8AE7_8B0A.bin"] as PackedByteArray).slice(0, 6) \
			!= PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xAE, 0x2A]) \
			or (_sources["bank18_ed_team_name_lengths_8B0A_8B0E.bin"] as PackedByteArray) \
			!= PackedByteArray([0x03, 0x04, 0x03, 0x03]) \
			or (_sources["fixed_team_name_pointer_entries_76_79_F415_F41D.bin"] as PackedByteArray).slice(0, 2) \
			!= PackedByteArray([0x76, 0xF7]) \
			or (_sources["fixed_team_00_name_stream_F776_F77C.bin"] as PackedByteArray).slice(0, 3) \
			!= PackedByteArray([0x53, 0x41, 0x4F]):
		return _fail("Descriptor-$01 ED row bytes, team handler vector, or ROM team-name source bytes changed.")
	if (_sources["bank18_ed_text_loop_8A56_8A86.bin"] as PackedByteArray).size() != 0x30 \
			or (_sources["fixed_team_name_lookup_F30F_F329.bin"] as PackedByteArray).size() != 0x1A \
			or (_sources["fixed_team_name_dispatch_C53C_C53F.bin"] as PackedByteArray).size() != 3:
		return _fail("Descriptor-$01 `$ED` name converter/lookup source spans changed size.")
	if (_sources["bank19_worker_lookup_B3BD_B3D1.bin"] as PackedByteArray).slice(18, 20) != PackedByteArray([0x53, 0xB4]) \
			or (_sources["fixed_task_yield_trampoline_C515_C518.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x0F, 0xCB]):
		return _fail("Bank-$19 lookup pointer or fixed $C515->$CB0F trampoline bytes changed.")
	if (_sources["bank18_worker_resume_8889_89D7.bin"] as PackedByteArray).slice(0, 5) != PackedByteArray([0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
		or (_sources["bank19_resumed_worker_text_lead_BBDC_BBDE.bin"] as PackedByteArray) != PackedByteArray([0xEF, 0xFC]) \
		or (_sources["bank19_resumed_worker_text_row01_BBDE_BBE0.bin"] as PackedByteArray) != PackedByteArray([0xF0, 0xFC]) \
			or (_sources["bank19_match_descriptor_B453_B464.bin"] as PackedByteArray).slice(0, 4) != PackedByteArray([0x21, 0x22, 0x07, 0x04]):
		return _fail("Resumed worker or descriptor source bytes changed.")
	if (_sources["fixed_dispatch_C509_C50C.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or (_sources["shared_fixed_branch_table_dispatch_CB99_CBAF.bin"] as PackedByteArray).size() != 23 \
			or (_sources["bank18_callback_pointer_89D8_89DA.bin"] as PackedByteArray) != PackedByteArray([0x48, 0x8B]) \
			or (_sources["bank18_resumed_worker_vector_tail_89D7_89DC.bin"] as PackedByteArray).slice(1, 5) != PackedByteArray([0x48, 0x8B, 0x8B, 0x8B]) \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray).size() != 47 \
			or (_sources["bank18_f0_match_clock_handler_8B8B_8BD5.bin"] as PackedByteArray).slice(0, 3) != PackedByteArray([0xA2, 0x00, 0xAD]) \
			or (_sources["bank18_f0_decimal_formatter_8C55_8C85.bin"] as PackedByteArray).size() != 48 \
			or (_sources["fixed_division_dispatch_C51E_C521.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x3C, 0xCD]) \
			or (_sources["fixed_division_16bit_CD3C_CD77.bin"] as PackedByteArray).size() != 59 \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray)[0] != 0xA9 \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray)[42] != 0xFF \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray)[46] != 0xFF \
			or (_sources["bank18_inline_callback_pointer_89F2_89F4.bin"] as PackedByteArray) != PackedByteArray([0x52, 0x8C]) \
			or (_sources["bank18_fc_callback_return_8C52_8C55.bin"] as PackedByteArray) != PackedByteArray([0x68, 0x68, 0x60]) \
			or (_sources["bank18_window_3x3_tile_ids_8D9E_8DA7.bin"] as PackedByteArray) != PackedByteArray([0x9C, 0xA8, 0x9D, 0xAA, 0x00, 0xAB, 0x9E, 0xA9, 0x9F]):
		return _fail("The `$C509->$CB99->$8B48` match-zero callback path failed its source-boundary checks.")
	if (_sources["fixed_wrapper_return_EF99_EFA2.bin"] as PackedByteArray) \
			!= PackedByteArray([0x68, 0x85, 0x25, 0x68, 0x85, 0x24, 0x4C, 0x2D, 0xCE]) \
			or (_sources["fixed_mapper_helper_CE2D_CE4A.bin"] as PackedByteArray).size() != 29 \
			or (_sources["fixed_second_wrapper_caller_DACC_DAD1.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA9, 0x01, 0x20, 0x7F, 0xEF]) \
			or (_sources["fixed_kickoff_caller_DAD1_DAD8.bin"] as PackedByteArray) \
			!= PackedByteArray([0xAD, 0x29, 0x06, 0xC9, 0x04, 0xF0, 0x11]) \
			or (_sources["fixed_kickoff_scenario35_caller_DAD8_DADC.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA9, 0x35, 0x20, 0xB0, 0xCB]) \
			or (_sources["fixed_scenario_queue_CBB0_CBC1.bin"] as PackedByteArray) \
			!= PackedByteArray([0x8D, 0x18, 0x05, 0xA9, 0x80, 0x8D, 0x16, 0x05,
				0xA9, 0x00, 0x85, 0x05, 0xA9, 0x00, 0x20, 0x0F, 0xCB, 0x60]):
		return _fail("The wrapper return, second caller, scenario-$35 branch, or enqueue source bytes changed.")
	return true


func _manifest_sha256() -> String:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return ""
	return _sha256(file.get_buffer(file.get_length()))


func _executed_source_span_records() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return output
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return output
	for span_variant in parsed.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			var file_name := String(span.get("file", ""))
			if _executed_source_files.has(file_name):
				output.append({"file": file_name, "bank": span.get("bank", ""),
					"cpu_start": span.get("cpu_start", ""), "cpu_end_exclusive": span.get("cpu_end_exclusive", ""),
					"sha256": span.get("sha256", "")})
	return output


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
