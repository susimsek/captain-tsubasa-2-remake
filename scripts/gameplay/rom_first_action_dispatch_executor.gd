extends RefCounted
## Executes bounded ROM-derived first-action input and CB99 dispatch slices.
## It does not emulate the unimplemented D5C3-to-D6C7 helper path or handler.

enum Status {
	SOURCE_NOT_READY,
	SOURCE_INTEGRITY_FAILURE,
	WAITING_FOR_SOURCE_INPUT_POLL,
	WAITING_FOR_A_EDGE,
	WAITING_FOR_PASS_SELECTION,
	UNSUPPORTED_COMBINED_INPUT,
	INVALID_LIVE_BOUNDARY,
	INVALID_INPUT_SAMPLE,
}

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/first_action_menu_input/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const INPUT_SPAN_PATH := SOURCE_ROOT + "action_input_dispatch_D5E0_D6E7.bin"
const INPUT_SPAN_SHA256 := "ad109ac091d382e1dca97d8d9c596617187b6f37e0ea0a965cc090066822d101"
const HANDLER_SPAN_PATH := SOURCE_ROOT + "pass_receiver_handler_D7E8_D8F6.bin"
const HANDLER_SPAN_SHA256 := "9ccc071c8af66e997b4fe1fe3613af4e764d756c35c6c96118ceba7faf034032"
const DIRECTION_TABLE_PATH := SOURCE_ROOT + "direction_action_ids_context_00_D6E8.bin"
const DIRECTION_TABLE_SHA256 := "dce8e125cc41a56ea02407a10727c0fbced6827fea37a619f5c3cc98f1ee4968"
const INLINE_DISPATCH_PATH := "res://reference/rom_extract/gameplay/field_entry_window_00/fixed_inline_dispatch_CB99_CBB0.bin"
const INLINE_DISPATCH_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"

const NES_A_EDGE := 0x80
const NES_LEFT_EDGE := 0x02
const PASS_ACTION_ID := 1
const PASS_DIRECTION_INDEX := 1
const SOURCE_INPUT_WAIT_PC := 0xD5EA
const ACTION_DISPATCH_CALL_PC := 0xD6C7
const ACTION_DISPATCH_TABLE_PC := 0xD6CA
const ACTION_DISPATCH_RETURN_BASE_PC := 0xD6C9
const PASS_ACTION_TABLE_ENTRY_PC := 0xD6CC
const PASS_HANDLER_PC := 0xD7E8
const BOUNDARY_PHASE_RUNNING := 2
const STATUS_FLAG_NEGATIVE := 0x80
const STATUS_FLAG_ZERO := 0x02
const STATUS_FLAG_CARRY := 0x01
const PASS_HANDLER_PREFIX := [0xA9, 0x38, 0x20, 0xB0, 0xCB, 0xA9, 0x0F, 0x20, 0x7F, 0xEF]
const ACTION_DISPATCH_TABLE := [
	0x92, 0xD7, 0xE8, 0xD7, 0x0C, 0xD7, 0x79, 0xD9,
	0x0C, 0xD7, 0x65, 0xDA, 0x0C, 0xD7, 0x0C, 0xD7,
]

var source_ready := false
var error_message := ""
var _input_span := PackedByteArray()
var _handler_span := PackedByteArray()
var _direction_ids := PackedByteArray()
var _pending_pass_confirmation: Dictionary = {}


func configure_from_project_sources() -> bool:
	source_ready = false
	error_message = ""
	if not FileAccess.file_exists(MANIFEST_PATH) \
			or not FileAccess.file_exists(INPUT_SPAN_PATH) \
			or not FileAccess.file_exists(HANDLER_SPAN_PATH) \
			or not FileAccess.file_exists(DIRECTION_TABLE_PATH) \
			or not FileAccess.file_exists(INLINE_DISPATCH_PATH):
		return _source_failure("One or more ROM-derived first-action dispatch resources are missing.")
	if FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		return _source_failure("First-action menu ROM manifest SHA-256 mismatch.")
	if FileAccess.get_sha256(INPUT_SPAN_PATH) != INPUT_SPAN_SHA256 \
			or FileAccess.get_sha256(HANDLER_SPAN_PATH) != HANDLER_SPAN_SHA256 \
			or FileAccess.get_sha256(DIRECTION_TABLE_PATH) != DIRECTION_TABLE_SHA256 \
			or FileAccess.get_sha256(INLINE_DISPATCH_PATH) != INLINE_DISPATCH_SHA256:
		return _source_failure("ROM-derived first-action dispatch span SHA-256 mismatch.")
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _source_failure("Could not read first-action menu ROM manifest.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _source_failure("First-action menu ROM manifest is not a JSON object.")
	var manifest: Dictionary = manifest_variant
	if String(manifest.get("schema", "")) != "ct2-first-action-menu-input-rom-data-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(manifest.get("source_rom_size_bytes", -1)) != 0x60010:
		return _source_failure("First-action menu ROM manifest does not identify the pinned source ROM.")
	if not _manifest_span_matches(manifest, "action_input_loop_and_dispatch", "0xD5E0", "0xD6E8", "0x03D5F0", 264, INPUT_SPAN_PATH.get_file(), INPUT_SPAN_SHA256) \
			or not _manifest_span_matches(manifest, "pass_receiver_handler", "0xD7E8", "0xD8F7", "0x03D7F8", 271, HANDLER_SPAN_PATH.get_file(), HANDLER_SPAN_SHA256):
		return _source_failure("Input or PASS handler ROM span metadata differs from its pinned CPU/file mapping.")
	_input_span = FileAccess.get_file_as_bytes(INPUT_SPAN_PATH)
	_handler_span = FileAccess.get_file_as_bytes(HANDLER_SPAN_PATH)
	_direction_ids = FileAccess.get_file_as_bytes(DIRECTION_TABLE_PATH)
	if _input_span.size() != 264 or _handler_span.size() != 271 \
			or _direction_ids != PackedByteArray([0x00, 0x01, 0x03, 0x02]):
		return _source_failure("ROM-derived dispatch spans have unexpected lengths or direction IDs.")
	# `$D6C7` is the JSR opcode for `$CB99`; the inline targets start at `$D6CA`.
	# CB99 uses the JSR return address `$D6C9` as its lookup base; action 1 reads `$D6CC/$D6CD`.
	var call_offset := ACTION_DISPATCH_CALL_PC - 0xD5E0
	var table_offset := ACTION_DISPATCH_TABLE_PC - 0xD5E0
	if _input_span.slice(call_offset, call_offset + 3) != PackedByteArray([0x20, 0x99, 0xCB]) \
			or _input_span.slice(table_offset, table_offset + ACTION_DISPATCH_TABLE.size()) != PackedByteArray(ACTION_DISPATCH_TABLE) \
			or _handler_span.slice(0, PASS_HANDLER_PREFIX.size()) != PackedByteArray(PASS_HANDLER_PREFIX) \
			or FileAccess.get_file_as_bytes(INLINE_DISPATCH_PATH) != PackedByteArray([
				0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36, 0x48,
				0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00,
			]):
		return _source_failure("PASS dispatch call, action target table, or handler prefix differs from ROM bytes.")
	var selection_source_bytes := PackedByteArray([
		0xA2, 0x00, 0x4A, 0xB0, 0x03, 0xE8, 0xD0, 0xFA, 0x86, 0x3A,
		0xAD, 0x21, 0x06, 0x0A, 0x0A, 0x65, 0x3A, 0xAA, 0xBD, 0xE8,
		0xD6, 0xC9, 0xFF, 0xF0, 0x1C, 0x8D, 0x3B, 0x04, 0xA6, 0x3A,
		0xAD, 0x1E, 0x06, 0x8E, 0x1E, 0x06, 0x48, 0x29, 0x03, 0xCD,
		0x1E, 0x06, 0xF0, 0x03, 0x68, 0x8A, 0x48, 0x68, 0x09, 0x80,
		0x8D, 0x1E, 0x06,
	])
	var confirm_source_bytes := PackedByteArray([
		0xA9, 0x80, 0x2D, 0x1E, 0x00, 0xF0, 0x0B, 0x2C, 0x1E,
		0x06, 0x10, 0x06, 0x20, 0x7C, 0xD6, 0x4C, 0xC3, 0xD5,
	])
	if _input_span.slice(0x11, 0x11 + selection_source_bytes.size()) != selection_source_bytes \
			or _input_span.slice(0x46, 0x46 + confirm_source_bytes.size()) != confirm_source_bytes:
		return _source_failure("Direction-selection writes or A-confirm branch no longer match the ROM instruction bytes.")
	source_ready = true
	return true


## Replays one controller receipt at the live slot-$05 `$D5EA` poll.
## The scheduler remains the authority for applying the returned write events.
func execute_from_live_action_menu_boundary(boundary: Dictionary,
		input_sample: Dictionary) -> Dictionary:
	if not source_ready:
		return _result(Status.SOURCE_NOT_READY, "ROM-derived dispatch resources are not configured.")
	if not _live_menu_boundary_matches(boundary, SOURCE_INPUT_WAIT_PC):
		return _result(Status.INVALID_LIVE_BOUNDARY,
			"Input execution requires the live slot-$05 `$D5EA` context-zero boundary.")
	if not _input_receipt_matches(boundary, input_sample):
		return _result(Status.INVALID_INPUT_SAMPLE,
			"Input sample receipt does not match the live `$001C/$001E` and current pad state.")
	var result := _base_live_result(boundary, input_sample)
	var edge := int(input_sample["newly_pressed"]) & 0xFF
	if edge == 0:
		result["status"] = "no_source_input_edge"
		result["ok"] = true
		return result
	if edge == NES_LEFT_EDGE:
		if (int(input_sample["current"]) & NES_A_EDGE) != 0:
			return _result(Status.UNSUPPORTED_COMBINED_INPUT,
				"The verified route separates Left selection and A confirmation across source polls.")
		var selected_id := int(_direction_ids[PASS_DIRECTION_INDEX])
		if selected_id != PASS_ACTION_ID:
			return _result(Status.SOURCE_INTEGRITY_FAILURE,
				"The ROM context-zero direction table no longer maps Left to PASS action ID 1.")
		result["ok"] = true
		result["status"] = "pass_selection_applied"
		result["selected_action_id"] = PASS_ACTION_ID
		result["selected_direction_index"] = PASS_DIRECTION_INDEX
		result["source_writes"] = [
			{"source_pc": 0xD60A, "address": 0x043B, "value": 0x01},
			{"source_pc": 0xD612, "address": 0x061E, "value": 0x01},
			{"source_pc": 0xD623, "address": 0x061E, "value": 0x81},
		]
		result["source_stack_writes"] = []
		result["resume_pc"] = 0xD5E5
		result["next_wait_pc"] = SOURCE_INPUT_WAIT_PC
		return result
	if edge == NES_A_EDGE:
		if _ram_byte(boundary, 0x043B) != PASS_ACTION_ID \
				or _ram_byte(boundary, 0x061E) != 0x81:
			return _result(Status.WAITING_FOR_PASS_SELECTION,
				"A is gated by a live PASS action ID 1 and `$061E` selection latch `$81`.")
		if not _input_span_matches_confirmation_dispatch():
			return _result(Status.SOURCE_INTEGRITY_FAILURE,
				"ROM bytes no longer establish the A-confirm `$D632->$D67C` call path.")
		_pending_pass_confirmation = {
			"sample_receipt_id": int(input_sample["sample_receipt_id"]),
			"input_sample_receipt": result["input_sample_receipt"].duplicate(true),
			"selected_action_id": PASS_ACTION_ID,
			"selected_direction_index": PASS_DIRECTION_INDEX,
			"source_boundary": _compact_boundary_proof(boundary),
		}
		result["ok"] = true
		# Keep the poll-result contract distinct from scheduler adoption: the
		# scheduler returns `pass_confirmation_pending_source_execution` after
		# consuming this source-confirmation receipt.
		result["status"] = "pass_confirmation_handoff_resolved"
		result["selected_action_id"] = PASS_ACTION_ID
		result["source_writes"] = []
		result["source_stack_writes"] = []
		result["handler_span_sha256"] = HANDLER_SPAN_SHA256
		# This receipt proves the D5EA A edge only. D632/D67C and the route to
		# D6C7 have not executed in this bounded result, so it has no resume or
		# handler target.
		result["handler_dispatch_executed"] = false
		result["pending_dispatch_required"] = true
		return result
	return _result(Status.UNSUPPORTED_COMBINED_INPUT,
		"This bounded route supports one context-zero direction edge or a separate A edge.")


## Continues a pending PASS confirmation on a later source tick. Only the
## CB99 inline dispatcher is modeled here; upstream calls are listed as
## verified control-flow boundaries and are not fabricated as executed state.
func resume_pending_first_action_menu_pass_dispatch(live_boundary: Dictionary) -> Dictionary:
	if not source_ready:
		return _result(Status.SOURCE_NOT_READY, "ROM-derived dispatch resources are not configured.")
	if _pending_pass_confirmation.is_empty():
		return _result(Status.INVALID_LIVE_BOUNDARY,
			"No one-use PASS confirmation is pending from a validated `$D5EA` sample.")
	if not _live_menu_boundary_matches(live_boundary, 0xD5C3):
		return _result(Status.INVALID_LIVE_BOUNDARY,
			"PASS continuation requires the current scheduler-owned slot-$05 `$D5C3` boundary.")
	if _ram_byte(live_boundary, 0x043B) != PASS_ACTION_ID \
			or _ram_byte(live_boundary, 0x061E) != 0x81:
		return _result(Status.INVALID_LIVE_BOUNDARY,
			"PASS selection changed between confirmation and continuation.")
	if not _input_span_matches_confirmation_dispatch():
		return _result(Status.SOURCE_INTEGRITY_FAILURE,
			"ROM input/dispatch bytes differ from the verified PASS source path.")
	return {
		"ok": false,
		"status": "pass_dispatch_source_gap",
		"error": "The live `$D5C3` snapshot does not prove execution of `$D632->$D67C`, `$D717->$8012`, and the `$D6C7` call. Refusing to synthesize a `$D6C7` state or adopt `$D7E8`.",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": MANIFEST_SHA256,
		"input_span_sha256": INPUT_SPAN_SHA256,
		"direction_table_sha256": DIRECTION_TABLE_SHA256,
		"source_boundary_pc": 0xD5C3,
		"source_bytes_verified": true,
		"missing_live_source_steps": [0xD632, 0xD67C, 0xE93D, 0xCE2D, 0x8009,
			0x8C06, 0xD717, 0xCE2D, 0x8012, 0x819D, 0xD76B, 0xD6C7],
		"handler_entry_pc": -1,
		"target_not_emitted": true,
		"source_writes": [],
		"source_stack_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}


## Executes only the byte-verified `$D6C7->$CB99->$D7E8` slice from a live
## source-owned CPU/task boundary. It cannot substitute for the D5C3 bridge.
func execute_pass_cb99_from_live_d6c7_boundary(boundary: Dictionary) -> Dictionary:
	if not source_ready:
		return _result(Status.SOURCE_NOT_READY, "ROM-derived dispatch resources are not configured.")
	if _pending_pass_confirmation.is_empty():
		return _result(Status.INVALID_LIVE_BOUNDARY,
			"The CB99 path requires the one-use PASS confirmation established at `$D5EA`.")
	if not _live_d6c7_boundary_matches(boundary):
		return _result(Status.INVALID_LIVE_BOUNDARY,
			"CB99 execution requires the live slot-$05 `$D6C7` CPU, stack, RAM, and mapper boundary.")
	if not _input_span_matches_confirmation_dispatch():
		return _result(Status.SOURCE_INTEGRITY_FAILURE,
			"ROM input/dispatch bytes differ from the pinned action-1 target mapping.")
	var incoming_registers := {
		"a": int(boundary.get("a", -1)),
		"x": int(boundary.get("x", -1)),
		"y": int(boundary.get("y", -1)),
		"p": int(boundary.get("p", -1)),
		"p_known_mask": int(boundary.get("p_known_mask", 0)),
		"x_known": boundary.has("x"),
		"x_provenance": "source-owned live `$D6C7` task context",
	}
	var entry_sp := int(boundary.get("sp", -1))
	var cb99 := _execute_pass_cb99(incoming_registers, entry_sp, false)
	if not bool(cb99.get("ok", false)):
		return cb99
	var result := _base_live_result(boundary, {})
	result["ok"] = true
	result["status"] = "pass_cb99_dispatched"
	result["source_boundary_pc"] = 0xD6C7
	result["resume_pc"] = PASS_HANDLER_PC
	result["handler_entry_pc"] = PASS_HANDLER_PC
	result["caller_return_pc"] = 0xD6C9
	result["outer_caller_return_pc"] = 0xD634
	result["entry_sp"] = entry_sp
	result["final_sp"] = int(cb99["final_sp"])
	result["source_reads"] = cb99["source_reads"]
	result["source_writes"] = cb99["source_writes"]
	result["source_stack_writes"] = cb99["source_stack_writes"]
	result["registers"] = cb99["registers"]
	result["source_pc_history"] = [0xD6C7, 0xCB99, 0xD7E8]
	result["source_manifest_sha256"] = MANIFEST_SHA256
	result["input_span_sha256"] = INPUT_SPAN_SHA256
	result["direction_table_sha256"] = DIRECTION_TABLE_SHA256
	result["handler_span_sha256"] = HANDLER_SPAN_SHA256
	result["inline_dispatch_span_sha256"] = INLINE_DISPATCH_SHA256
	result["mapper"] = {"banks_at_task_boundary": [0x1A, 0x1B],
		"bank_registers_at_d6c7": {6: 0x1C, 7: 0x1D}, "fixed_bank": 0x1E}
	result["handler_instructions_executed"] = false
	result["trace_state_used"] = false
	result["ppu_apu_effects_applied"] = false
	_pending_pass_confirmation.clear()
	return result


func _live_menu_boundary_matches(boundary: Dictionary, expected_pc: int) -> bool:
	var banks_variant: Variant = boundary.get("banks", [])
	var banks_match := int(boundary.get("bank_low", -1)) == 0x1A \
			and int(boundary.get("bank_high", -1)) == 0x1B
	if banks_variant is Array and banks_variant.size() == 2:
		banks_match = int(banks_variant[0]) == 0x1A and int(banks_variant[1]) == 0x1B
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	if ram_variant is not PackedByteArray or ram_variant.size() != 0x800:
		return false
	var ram: PackedByteArray = ram_variant
	return String(boundary.get("rom_sha256", "")) == ROM_SHA256 \
			and int(boundary.get("slot_base", -1)) == 0x05 \
			and int(boundary.get("active_task_slot", -1)) == 0x05 \
			and int(boundary.get("phase", -1)) == BOUNDARY_PHASE_RUNNING \
			and int(boundary.get("pc", -1)) == expected_pc \
			and banks_match \
			and _ram_byte(boundary, 0x0621) == 0 \
			and _ram_byte(boundary, 0x043B) >= 0 \
			and _ram_byte(boundary, 0x061E) >= 0 \
			and _ram_byte(boundary, 0x001C) >= 0 \
			and _ram_byte(boundary, 0x001E) >= 0 \
			and ram.size() == 0x800


func _live_d6c7_boundary_matches(boundary: Dictionary) -> bool:
	if not _live_menu_boundary_matches(boundary, ACTION_DISPATCH_CALL_PC) \
			or int(boundary.get("sp", -1)) != 0x4A \
			or int(boundary.get("a", -1)) != PASS_ACTION_ID \
			or int(boundary.get("y", -1)) != 0x02 \
			or int(boundary.get("x", -1)) < 0 or int(boundary.get("x", -1)) > 0xFF \
			or _ram_byte(boundary, 0x043B) != PASS_ACTION_ID \
			or _ram_byte(boundary, 0x061E) != 0x81 \
			or _ram_byte(boundary, 0x001C) != 0x80 \
			or _ram_byte(boundary, 0x001E) != 0x80:
		return false
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not stack_variant is PackedByteArray or stack_variant.size() != 0x100:
		return false
	var stack_page: PackedByteArray = stack_variant
	if int(stack_page[0x4C]) != 0xD6 or int(stack_page[0x4B]) != 0x34:
		return false
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not mapper_variant is Dictionary:
		return false
	var bank_registers_variant: Variant = (mapper_variant as Dictionary).get("bank_registers", {})
	if not bank_registers_variant is Dictionary:
		return false
	var bank_registers: Dictionary = bank_registers_variant
	return int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x1C \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x1D


func _input_receipt_matches(boundary: Dictionary, input_sample: Dictionary) -> bool:
	for key in ["sample_receipt_id", "previous", "current", "newly_pressed",
			"held_ram_001c", "edge_ram_001e"]:
		if not input_sample.has(key):
			return false
	var receipt_id := int(input_sample.get("sample_receipt_id", -1))
	var previous := int(input_sample.get("previous", -1)) & 0xFF
	var current := int(input_sample.get("current", -1)) & 0xFF
	var newly_pressed := int(input_sample.get("newly_pressed", -1)) & 0xFF
	return receipt_id > 0 \
			and newly_pressed == ((previous ^ current) & current) \
			and int(input_sample.get("held_ram_001c", -1)) == _ram_byte(boundary, 0x001C) \
			and int(input_sample.get("edge_ram_001e", -1)) == _ram_byte(boundary, 0x001E) \
			and newly_pressed == _ram_byte(boundary, 0x001E) \
			and current == _ram_byte(boundary, 0x001C)


func _input_span_matches_confirmation_dispatch() -> bool:
	if _input_span.size() != 264:
		return false
	return _input_span.slice(0x52, 0x55) == PackedByteArray([0x20, 0x7C, 0xD6]) \
			and _input_span.slice(0xE1, 0xE4) == PackedByteArray([0x20, 0x17, 0xD7]) \
			and _input_span.slice(0xE4, 0xE7) == PackedByteArray([0xAD, 0x3B, 0x04]) \
			and _input_span.slice(0xE7, 0xEA) == PackedByteArray([0x20, 0x99, 0xCB]) \
			and _input_span.slice(0xEA, 0xEC) == PackedByteArray([0x92, 0xD7]) \
			and _input_span.slice(0xEC, 0xEE) == PackedByteArray([0xE8, 0xD7])


func _base_live_result(boundary: Dictionary, input_sample: Dictionary) -> Dictionary:
	var base := {
		"ok": false,
		"status": "invalid_live_boundary",
		"rom_sha256": ROM_SHA256,
		"source_rom_sha256": ROM_SHA256,
		"source_manifest_sha256": MANIFEST_SHA256,
		"input_span_sha256": INPUT_SPAN_SHA256,
		"direction_table_sha256": DIRECTION_TABLE_SHA256,
		"boundary_proof": _compact_boundary_proof(boundary),
		"source_writes": [],
		"source_stack_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}
	if not input_sample.is_empty():
		base["input_sample_receipt"] = {
			"sample_receipt_id": int(input_sample.get("sample_receipt_id", -1)),
			"previous": int(input_sample.get("previous", -1)) & 0xFF,
			"current": int(input_sample.get("current", -1)) & 0xFF,
			"newly_pressed": int(input_sample.get("newly_pressed", -1)) & 0xFF,
			"held_ram_001c": int(input_sample.get("held_ram_001c", -1)) & 0xFF,
			"edge_ram_001e": int(input_sample.get("edge_ram_001e", -1)) & 0xFF,
		}
	return base


func _compact_boundary_proof(boundary: Dictionary) -> Dictionary:
	var banks_variant: Variant = boundary.get("banks", [])
	var banks: Array = [int(boundary.get("bank_low", -1)), int(boundary.get("bank_high", -1))]
	if banks_variant is Array and banks_variant.size() == 2:
		banks = [int(banks_variant[0]), int(banks_variant[1])]
	return {
		"slot_base": int(boundary.get("slot_base", -1)),
		"active_task_slot": int(boundary.get("active_task_slot", -1)),
		"phase": int(boundary.get("phase", -1)),
		"pc": int(boundary.get("pc", -1)),
		"sp": int(boundary.get("sp", -1)),
		"banks": banks,
		"menu_context": _ram_byte(boundary, 0x0621),
		"source_selected_action_id": _ram_byte(boundary, 0x043B),
		"source_selection_latch": _ram_byte(boundary, 0x061E),
		"held_ram_001c": _ram_byte(boundary, 0x001C),
		"edge_ram_001e": _ram_byte(boundary, 0x001E),
	}


func _execute_pass_cb99(registers_at_call: Dictionary, entry_sp: int,
		include_outer_call: bool = true) -> Dictionary:
	if int(registers_at_call.get("a", -1)) != PASS_ACTION_ID \
			or int(registers_at_call.get("y", -1)) != 2:
		return {"ok": false, "status": "invalid_source_dispatch_registers",
			"error": "The byte-derived `$CB99` path requires action A=1 and Y=2 at its JSR entry."}
	var table_offset := ACTION_DISPATCH_TABLE_PC + PASS_ACTION_ID * 2 - 0xD5E0
	var target_low := int(_input_span[table_offset])
	var target_high := int(_input_span[table_offset + 1])
	var target := target_low | (target_high << 8)
	if target != PASS_HANDLER_PC:
		return {"ok": false, "status": "source_integrity_failure",
			"error": "CB99 inline table entry for action 1 does not target `$D7E8`."}
	var sp := entry_sp & 0xFF
	var stack_writes: Array[Dictionary] = []
	if include_outer_call:
		# Outer JSR at $D632 stores return address $D634, high byte then low byte.
		stack_writes.append(_stack_push_event(0xD632, sp, 0xD6, "jsr_push_high")); sp = (sp - 1) & 0xFF
		stack_writes.append(_stack_push_event(0xD632, sp, 0x34, "jsr_push_low")); sp = (sp - 1) & 0xFF
	# Inner JSR at $D6C7 stores return address $D6C9.
	stack_writes.append(_stack_push_event(0xD6C7, sp, 0xD6, "jsr_push_high")); sp = (sp - 1) & 0xFF
	stack_writes.append(_stack_push_event(0xD6C7, sp, 0xC9, "jsr_push_low")); sp = (sp - 1) & 0xFF
	stack_writes.append(_stack_push_event(0xCBA4, sp, target_low, "pha")); sp = (sp - 1) & 0xFF
	# CB99 consumes its own PHA and JSR return word before JMP ($0036).
	sp = (sp + 3) & 0xFF
	var p_known_mask := STATUS_FLAG_NEGATIVE | STATUS_FLAG_ZERO | STATUS_FLAG_CARRY
	var output_p := (int(registers_at_call.get("p", 0)) & ~p_known_mask) | STATUS_FLAG_NEGATIVE
	var source_writes: Array[Dictionary] = [
		{"source_pc": 0xCB9C, "address": 0x0036, "value": 0xC9},
		{"source_pc": 0xCB9F, "address": 0x0037, "value": 0xD6},
		{"source_pc": 0xCBA8, "address": 0x0037, "value": target_high},
		{"source_pc": 0xCBAB, "address": 0x0036, "value": target_low},
	]
	var source_reads: Array[Dictionary] = [
		{"source_pc": 0xCBA2, "address": 0xD6CC, "value": target_low},
		{"source_pc": 0xCBA6, "address": 0xD6CD, "value": target_high},
	]
	return {
		"ok": true,
		"handler_entry_pc": target,
		"final_sp": sp,
		"source_writes": source_writes,
		"source_reads": source_reads,
		"source_stack_writes": stack_writes,
		"registers": {"a": target_low, "x": int(registers_at_call.get("x", -1)),
			"y": 4, "p": output_p, "pc": target, "sp": sp,
			"p_known_mask": p_known_mask,
			"x_known": bool(registers_at_call.get("x_known", false)),
			"x_provenance": String(registers_at_call.get("x_provenance", "unknown"))},
	}


func _stack_push_event(source_pc: int, sp: int, value: int, operation: String) -> Dictionary:
	return {"source_pc": source_pc, "address": 0x0100 | (sp & 0xFF),
		"value": value & 0xFF, "operation": operation}


func _ram_byte(boundary: Dictionary, address: int) -> int:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != 0x800 \
			or address < 0 or address >= 0x800:
		return -1
	var ram: PackedByteArray = ram_variant
	return int(ram[address])


func _manifest_span_matches(manifest: Dictionary, span_name: String, cpu_start: String,
		cpu_end: String, file_offset: String, length: int, resource: String, sha256: String) -> bool:
	var spans: Variant = manifest.get("source_spans", [])
	if not spans is Array:
		return false
	for span_variant in spans:
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("name", "")) != span_name:
			continue
		return String(span.get("prg_bank", "")) == "0x1E" \
				and String(span.get("cpu_start", "")) == cpu_start \
				and String(span.get("cpu_end_exclusive", "")) == cpu_end \
				and String(span.get("file_offset", "")) == file_offset \
				and int(span.get("length_bytes", -1)) == length \
				and String(span.get("resource", "")) == resource \
				and String(span.get("sha256", "")) == sha256
	return false


func _source_failure(message: String) -> bool:
	error_message = message
	return false


func _result(status: Status, message: String) -> Dictionary:
	return {"ok": false, "status": _status_name(status), "error": message,
		"source_rom_sha256": ROM_SHA256, "rom_sha256": ROM_SHA256,
		"trace_state_used": false}


func _status_name(status: Status) -> String:
	match status:
		Status.SOURCE_NOT_READY:
			return "source_not_ready"
		Status.SOURCE_INTEGRITY_FAILURE:
			return "source_integrity_failure"
		Status.WAITING_FOR_SOURCE_INPUT_POLL:
			return "waiting_for_source_input_poll"
		Status.WAITING_FOR_PASS_SELECTION:
			return "waiting_for_pass_selection"
		Status.WAITING_FOR_A_EDGE:
			return "waiting_for_a_edge"
		Status.UNSUPPORTED_COMBINED_INPUT:
			return "unsupported_combined_input"
		Status.INVALID_LIVE_BOUNDARY:
			return "invalid_live_boundary"
		Status.INVALID_INPUT_SAMPLE:
			return "invalid_input_sample"
		_:
			return "unknown"
