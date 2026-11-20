extends RefCounted
class_name RomPassPostScenarioContinuationExecutor
## Continues the PASS handler from a scheduler-owned `$D7ED` return through
## descriptor `$0F`, `$E6EC`, and the `$D80C->$CB0F` call-entry boundary.
## `$EF7F` renderer completion is an explicit input receipt; this component
## does not fabricate its asynchronous worker or PPU effects.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const HANDLER_PATH := "res://reference/rom_extract/gameplay/first_action_menu_input/pass_receiver_handler_D7E8_D8F6.bin"
const HANDLER_SHA256 := "9ccc071c8af66e997b4fe1fe3613af4e764d756c35c6c96118ceba7faf034032"
const HOLDER_ROOT := "res://reference/rom_extract/gameplay/first_command_field/holder_coordinates/"
const HOLDER_MANIFEST_PATH := HOLDER_ROOT + "manifest.json"
const HOLDER_MANIFEST_SHA256 := "aa951660b645d51a2c8fbfa6fbbc44026c478daea8bd8068b8afedf1a08b2bf3"
const E6EC_PATH := HOLDER_ROOT + "bank_1f_e6ec_holder_coordinate_copy.bin"
const E6EC_SHA256 := "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c"
const CDE2_PATH := HOLDER_ROOT + "bank_1f_cde2_coordinate_index_helper.bin"
const CDE2_SHA256 := "e5f6dcb9f5d2451ba1770add2906daa504befaf7800e3bfe2e1b163708e58a83"
const POSITION_ROOT := "res://reference/rom_extract/gameplay/first_command_field/player_record_positions/"
const CD7C_PATH := POSITION_ROOT + "bank_1f_cd7c_record_pointer_lookup_code.bin"
const CD7C_SHA256 := "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24"
const POINTERS_PATH := POSITION_ROOT + "bank_1f_cd89_record_pointer_table_22.bin"
const POINTERS_SHA256 := "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"
const PASS_PANEL_SCRIPT := preload("res://scripts/gameplay/pass_receiver_menu_panel.gd")

const ENTRY_PC := 0xD7ED
const RENDERER_ENTRY_PC := 0xEF7F
const RENDERER_RETURN_PC := 0xD7F2
const RECEIVER_WAIT_CALL_PC := 0xD80C
const RECEIVER_INPUT_PC := 0xD80F
const YIELD_PC := 0xCB0F
const RAM_SIZE := 0x0800
const STACK_SIZE := 0x0100
const CARRY := 0x01
const ZERO := 0x02
const OVERFLOW := 0x40
const NEGATIVE := 0x80

var error_message := ""
var _configured := false
var _handler := PackedByteArray()
var _e6ec := PackedByteArray()
var _cde2 := PackedByteArray()
var _cd7c := PackedByteArray()
var _pointers := PackedByteArray()
var _panel_packets: Array[Dictionary] = []


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var holder_manifest := _read_checked(HOLDER_MANIFEST_PATH, HOLDER_MANIFEST_SHA256)
	if holder_manifest.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(holder_manifest.get_string_from_utf8())
	if not parsed is Dictionary \
			or String(parsed.get("schema", "")) != "ct2-first-command-holder-coordinate-copy-v1" \
			or String(parsed.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Holder-coordinate provenance does not identify the supplied ROM.")
	_handler = _read_checked(HANDLER_PATH, HANDLER_SHA256)
	_e6ec = _read_checked(E6EC_PATH, E6EC_SHA256)
	_cde2 = _read_checked(CDE2_PATH, CDE2_SHA256)
	_cd7c = _read_checked(CD7C_PATH, CD7C_SHA256)
	_pointers = _read_checked(POINTERS_PATH, POINTERS_SHA256)
	if _handler.size() != 271 or _e6ec.size() != 29 or _cde2.size() != 38 \
			or _cd7c.size() != 13 or _pointers.size() != 44:
		return _fail("A ROM-derived PASS handler or holder-copy source span is missing or has the wrong length.")
	if not _bytes_at(_handler, 0xD7ED - 0xD7E8, [0xA9, 0x0F, 0x20, 0x7F, 0xEF]) \
			or not _bytes_at(_handler, 0xD7F2 - 0xD7E8,
				[0xA9, 0x81, 0x8D, 0x2D, 0x06, 0xA9, 0x1F, 0x8D, 0x94, 0x04, 0x20, 0xEC, 0xE6]) \
			or not _bytes_at(_handler, 0xD7FF - 0xD7E8,
				[0xA9, 0x00, 0x8D, 0x25, 0x06, 0xAD, 0xFE, 0x05, 0x8D, 0x24, 0x06, 0xA9, 0x01, 0x20, 0x0F, 0xCB]) \
			or _e6ec.hex_encode() != "ad4104207ccda006b1348d3506aaa008b1348d3706a820e2cd8dfe0560" \
			or _cd7c.hex_encode() != "0aa8b989cd8534b98acd853560" \
			or _cde2.hex_encode() != "8a38e930901dc9a0b0194a4a4aaa9838e950900fc960b00b4a4a4aca300718690cd0f8a9ff60":
		return _fail("PASS continuation or `$CD7C/$E6EC/$CDE2` instruction bytes differ from the pinned ROM spans.")
	var panel = PASS_PANEL_SCRIPT.new()
	if not panel.rebuild():
		return _fail("ROM-derived descriptor-$0F panel data failed to build: " + String(panel.error_message))
	_panel_packets = panel.packets.duplicate(true)
	if _panel_packets.size() != 10 or int(panel.status.get("descriptor_id", -1)) != 0x0F:
		return _fail("Descriptor-$0F packet construction did not produce the source-sized receiver prompt.")
	_configured = true
	return true


## Renderer return must be supplied by the `$EF7F` owner. A fixture receipt is
## accepted only when the boundary is explicitly marked test-only.
func execute_from_live_boundary(boundary: Dictionary,
		renderer_return_receipt: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var validation := _validate_live_boundary(boundary)
	if not bool(validation.get("ok", false)):
		return _failure("source_state_required", String(validation.get("error", "Invalid `$D7ED` boundary.")))
	if not _validate_renderer_receipt(renderer_return_receipt, bool(boundary.get("test_fixture", false))):
		return _failure("renderer_receipt_required",
			"A source-owned `$EF7F` descriptor-$0F return to `$D7F2` is required before executing the caller continuation.")

	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_sp := int(boundary["sp"]) & 0xFF
	var cpu := {"a": int(boundary.get("a", 0)) & 0xFF,
		"x": int(boundary.get("x", 0)) & 0xFF,
		"y": int(boundary.get("y", 0)) & 0xFF,
		"p": (int(boundary.get("p", 0x20)) | 0x20) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0)) & 0xFF,
		"sp": entry_sp, "pc": ENTRY_PC}
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var calls: Array[Dictionary] = []

	# The first JSR/RTS frame is byte-executed here; the renderer body is
	# represented by the separately validated return receipt.
	_set_a(cpu, _handler[0xD7EE - 0xD7E8])
	instruction_pcs.append_array([0xD7ED, 0xD7EF])
	_push_jsr(cpu, ram, stack, stack_writes, 0xD7EF, 0xD7F1)
	cpu["pc"] = RENDERER_ENTRY_PC
	instruction_pcs.append(RENDERER_ENTRY_PC)
	calls.append({"callsite": 0xD7EF, "target": RENDERER_ENTRY_PC,
		"descriptor_id": int(cpu["a"]), "return_pc": RENDERER_RETURN_PC,
		"entry_sp": int(cpu["sp"]), "completion_source": String(renderer_return_receipt.get("source_kind", "fixture"))})
	if int(cpu["a"]) != 0x0F:
		return _failure("source_opcode_mismatch", "The live `$D7ED` handler did not pass descriptor `$0F` to `$EF7F`.")
	var renderer_return_sp := (int(cpu["sp"]) + 1) & 0xFF
	var renderer_return_low := int(stack[renderer_return_sp])
	var renderer_return_high := int(stack[(renderer_return_sp + 1) & 0xFF])
	var renderer_return := (((renderer_return_high << 8) | renderer_return_low) + 1) & 0xFFFF
	if renderer_return != RENDERER_RETURN_PC or renderer_return_sp != ((entry_sp - 1) & 0xFF):
		return _failure("renderer_return_mismatch", "The descriptor renderer did not restore the caller stack and return at `$D7F2`.")
	# The renderer receipt owns its internal RTS site and bus reads. Its balanced
	# caller frame is retained in the stack image; its RTS bus reads remain the
	# renderer producer's evidence rather than this continuation's.
	cpu["sp"] = entry_sp
	cpu["pc"] = RENDERER_RETURN_PC
	instruction_pcs.append(RENDERER_RETURN_PC)

	# `$D7F2-$D7FB`: receiver-window mode and holder-placement selector.
	_set_a(cpu, 0x81)
	instruction_pcs.append_array([0xD7F2, 0xD7F4])
	_write_ram(ram, writes, 0xD7F4, 0x062D, int(cpu["a"]))
	_set_a(cpu, 0x1F)
	instruction_pcs.append_array([0xD7F7, 0xD7F9])
	_write_ram(ram, writes, 0xD7F9, 0x0494, int(cpu["a"]))

	# `$D7FC JSR $E6EC`; execute the ROM copy through its two nested helpers.
	cpu["pc"] = 0xD7FC
	_push_jsr(cpu, ram, stack, stack_writes, 0xD7FC, 0xD7FE)
	cpu["pc"] = 0xE6EC
	calls.append({"callsite": 0xD7FC, "target": 0xE6EC,
		"return_pc": 0xD7FF, "entry_sp": int(cpu["sp"])})
	var holder_result := _execute_e6ec(ram, stack, cpu, writes, stack_writes,
		stack_reads, source_reads, instruction_pcs, calls)
	if not bool(holder_result.get("ok", false)):
		return _failure("holder_copy_failed", String(holder_result.get("error", "`$E6EC` source execution failed.")))
	var holder_slot := int(holder_result["holder_slot"])

	# `$D7FF-$D80C` prepares the receiver cursor, then enters (but does not run)
	# the scheduler's `$CB0F` yield routine.
	_set_a(cpu, 0x00)
	instruction_pcs.append_array([0xD7FF, 0xD801])
	_write_ram(ram, writes, 0xD801, 0x0625, 0x00)
	_set_a(cpu, int(ram[0x05FE]))
	instruction_pcs.append_array([0xD804, 0xD807])
	_write_ram(ram, writes, 0xD807, 0x0624, int(cpu["a"]))
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xD80A)
	_push_jsr(cpu, ram, stack, stack_writes, RECEIVER_WAIT_CALL_PC, 0xD80E)
	calls.append({"callsite": RECEIVER_WAIT_CALL_PC, "target": YIELD_PC,
		"return_pc": RECEIVER_INPUT_PC, "entry_sp": int(cpu["sp"]),
		"scheduler_yield_executed": false})
	cpu["pc"] = YIELD_PC
	instruction_pcs.append(RECEIVER_WAIT_CALL_PC)
	var output_ram := ram.duplicate()
	for index in STACK_SIZE:
		output_ram[0x0100 + index] = stack[index]
	var registers := {"a": int(cpu["a"]), "x": int(cpu["x"]),
		"y": int(cpu["y"]), "p": int(cpu["p"]),
		"p_known_mask": int(cpu["p_known_mask"]), "sp": int(cpu["sp"]), "pc": YIELD_PC}
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = YIELD_PC
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS continuation `$D7ED->$EF7F->$E6EC->$D80C->$CB0F`"
	return {
		"ok": true,
		"status": "pass_receiver_wait_yield_at_cb0f_call_entry",
		"rom_sha256": ROM_SHA256,
		"entry_pc": ENTRY_PC, "entry_sp": entry_sp,
		"renderer_entry_pc": RENDERER_ENTRY_PC,
		"renderer_descriptor_id": 0x0F,
		"renderer_return_pc": RENDERER_RETURN_PC,
		"renderer_body_executed_by_this_component": false,
		"renderer_return_fixture": bool(renderer_return_receipt.get("fixture_only", false)),
		"renderer_return_receipt": renderer_return_receipt.duplicate(true),
		"descriptor_panel_packets": _panel_packets.duplicate(true),
		"holder_copy": {"holder_slot_0441": holder_slot,
			"record_pointer": int(holder_result["record_pointer"]),
			"x_0635": int(ram[0x0635]), "y_0637": int(ram[0x0637]),
			"tile_index_05fe": int(ram[0x05FE])},
		"cursor": {"tile_index_0624": int(ram[0x0624]), "candidate_count_0430": int(ram[0x0430]),
			"selectable_count_0625": int(ram[0x0625])},
		"exit_pc": YIELD_PC, "resume_pc_after_yield": RECEIVER_INPUT_PC,
		"entry_to_yield_instructions": instruction_pcs,
		"source_reads": source_reads, "source_writes": writes,
		"source_stack_writes": stack_writes, "source_stack_reads": stack_reads,
		"calls": calls, "registers": registers,
		"next_boundary_snapshot": next_boundary,
		"scheduler_yield_executed": false,
		"receiver_input_poll_executed": false,
		"ppu_effects_applied": false, "apu_effects_applied": false,
		"trace_state_used": false, "emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"runtime_integrated": false,
	}


func get_source_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "handler_span_sha256": _sha256(_handler) if not _handler.is_empty() else "",
		"holder_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"e6ec_sha256": _sha256(_e6ec) if not _e6ec.is_empty() else "",
		"cd7c_sha256": _sha256(_cd7c) if not _cd7c.is_empty() else "",
		"cde2_sha256": _sha256(_cde2) if not _cde2.is_empty() else "",
		"cd89_sha256": _sha256(_pointers) if not _pointers.is_empty() else "",
		"stop_boundary_pc": YIELD_PC, "stop_boundary_is_call_entry": true}


func _validate_live_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "error": "Emulator/trace captures cannot seed the PASS continuation."}
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper_proof", {})
	if not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE \
			or not mapper_variant is Dictionary:
		return {"ok": false, "error": "A complete scheduler-owned RAM/stack/mapper boundary is required."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var banks: Variant = mapper.get("banks_at_fixed_dispatch", [])
	var sp := int(boundary.get("sp", -1))
	var fixture := bool(boundary.get("test_fixture", false))
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != ENTRY_PC \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("executing_cpu_bank", -1)) != 0x1E \
			or banks != [0x1C, 0x1D] or int(mapper.get("fixed_bank", -1)) != 0x1E \
			or sp < 0 or sp > 0xFF or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x0000]) != 0x05 or int(ram[0x0518]) != 0x38 \
			or int(ram[0x0441]) >= 22 \
			or int(stack[(sp + 1) & 0xFF]) != 0x34 \
			or int(stack[(sp + 2) & 0xFF]) != 0xD6 \
			or bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "error": "Boundary does not match the supplied-ROM slot-$05 `$D7ED` scheduler return signature."}
	if fixture and String(boundary.get("fixture_label", "")) != "synthetic D7ED scheduler-return fixture; not a route result":
		return {"ok": false, "error": "A synthetic source boundary must be explicitly marked as a test fixture."}
	if not fixture and String(boundary.get("source_label", "")).is_empty():
		return {"ok": false, "error": "A live boundary must carry its scheduler source label."}
	return {"ok": true}


func _validate_renderer_receipt(receipt: Dictionary, fixture_boundary: bool) -> bool:
	if not bool(receipt.get("ok", false)) or String(receipt.get("rom_sha256", "")) != ROM_SHA256 \
			or int(receipt.get("callsite_pc", -1)) != 0xD7EF \
			or int(receipt.get("entry_pc", -1)) != RENDERER_ENTRY_PC \
			or int(receipt.get("descriptor_id", -1)) != 0x0F \
			or int(receipt.get("return_pc", -1)) != RENDERER_RETURN_PC \
			or not bool(receipt.get("returned_via_rts", false)) \
			or bool(receipt.get("trace_state_used", true)):
		return false
	if bool(receipt.get("fixture_only", false)):
		return fixture_boundary and String(receipt.get("fixture_label", "")) \
				== "synthetic EF7F descriptor-0F return receipt; not a renderer result"
	return bool(receipt.get("renderer_source_executed", false)) \
			and String(receipt.get("source_kind", "")) == "rom_byte_renderer_execution"


func _execute_e6ec(ram: PackedByteArray, stack: PackedByteArray, cpu: Dictionary,
		writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_reads: Array[Dictionary], source_reads: Array[Dictionary],
		instruction_pcs: Array[int], calls: Array[Dictionary]) -> Dictionary:
	var holder_slot := int(ram[0x0441])
	if holder_slot < 0 or holder_slot >= 22:
		return {"ok": false, "error": "`$E6EC` holder slot `$0441` is outside the 22 source records."}
	if not _bytes_at(_e6ec, 0, [0xAD, 0x41, 0x04, 0x20, 0x7C, 0xCD]) \
			or not _bytes_at(_cd7c, 0, [0x0A, 0xA8, 0xB9, 0x89, 0xCD, 0x85, 0x34,
				0xB9, 0x8A, 0xCD, 0x85, 0x35, 0x60]):
		return {"ok": false, "error": "`$E6EC/$CD7C` caller and pointer lookup bytes changed."}
	cpu["pc"] = 0xE6EC
	instruction_pcs.append(0xE6EC)
	source_reads.append({"source_pc": 0xE6EC, "address": 0x0441,
		"value": holder_slot, "role": "holder_slot"})
	_set_a(cpu, holder_slot)
	cpu["pc"] = 0xE6EF
	_push_jsr(cpu, ram, stack, stack_writes, 0xE6EF, 0xE6F1)
	calls.append({"callsite": 0xE6EF, "target": 0xCD7C, "return_pc": 0xE6F2,
		"holder_slot": holder_slot, "entry_sp": int(cpu["sp"])})
	instruction_pcs.append_array([0xE6EF, 0xCD7C, 0xCD7D, 0xCD7E, 0xCD80,
		0xCD83, 0xCD84, 0xCD86, 0xCD89])
	# `$CD7C`: ASL A; TAY; read low/high pointer bytes through Y.
	var doubled_slot := (int(cpu["a"]) << 1) & 0xFF
	_set_flag(cpu, CARRY, (int(cpu["a"]) & 0x80) != 0)
	_set_a(cpu, doubled_slot)
	cpu["y"] = doubled_slot
	_set_nz(cpu, doubled_slot)
	var table_offset := holder_slot * 2
	var record_pointer := int(_pointers[table_offset]) | (int(_pointers[table_offset + 1]) << 8)
	if record_pointer != 0x0300 + holder_slot * 0x0C:
		return {"ok": false, "error": "`$CD7C` pointer table entry disagrees with the 12-byte player-record layout."}
	source_reads.append({"source_pc": 0xCD80, "cpu_address": 0xCD89 + table_offset,
		"value": int(_pointers[table_offset]), "role": "record_pointer_low"})
	source_reads.append({"source_pc": 0xCD83, "cpu_address": 0xCD89 + table_offset + 1,
		"value": int(_pointers[table_offset + 1]), "role": "record_pointer_high"})
	_set_a(cpu, int(_pointers[table_offset]))
	_write_ram(ram, writes, 0xCD80, 0x0034, record_pointer & 0xFF)
	_set_a(cpu, int(_pointers[table_offset + 1]))
	_write_ram(ram, writes, 0xCD83, 0x0035, (record_pointer >> 8) & 0xFF)
	cpu["pc"] = 0xCD89
	var lookup_return := _pop_rts(cpu, stack, stack_reads)
	if lookup_return != 0xE6F2:
		return {"ok": false, "error": "`$CD7C` did not return to the live `$E6F2` continuation."}
	cpu["pc"] = 0xE6F2
	cpu["y"] = 0x06
	_set_nz(cpu, 0x06)
	var x_coordinate := int(ram[(record_pointer + 0x06) & 0x07FF])
	instruction_pcs.append_array([0xE6F2, 0xE6F4, 0xE6F6, 0xE6F9])
	source_reads.append({"source_pc": 0xE6F4, "address": (record_pointer + 0x06) & 0x07FF,
		"value": x_coordinate, "role": "holder_record_x_plus_06"})
	_set_a(cpu, x_coordinate)
	_write_ram(ram, writes, 0xE6F6, 0x0635, x_coordinate)
	cpu["pc"] = 0xE6F9
	cpu["x"] = x_coordinate
	_set_nz(cpu, x_coordinate)
	cpu["pc"] = 0xE6FA
	cpu["y"] = 0x08
	_set_nz(cpu, 0x08)
	var y_coordinate := int(ram[(record_pointer + 0x08) & 0x07FF])
	instruction_pcs.append_array([0xE6FA, 0xE6FC, 0xE6FE, 0xE701])
	source_reads.append({"source_pc": 0xE6FC, "address": (record_pointer + 0x08) & 0x07FF,
		"value": y_coordinate, "role": "holder_record_y_plus_08"})
	_set_a(cpu, y_coordinate)
	_write_ram(ram, writes, 0xE6FE, 0x0637, y_coordinate)
	cpu["pc"] = 0xE701
	cpu["y"] = y_coordinate
	_set_nz(cpu, y_coordinate)
	cpu["pc"] = 0xE702
	instruction_pcs.append(0xE702)
	_push_jsr(cpu, ram, stack, stack_writes, 0xE702, 0xE704)
	calls.append({"callsite": 0xE702, "target": 0xCDE2, "return_pc": 0xE705,
		"x": x_coordinate, "y": y_coordinate, "entry_sp": int(cpu["sp"])})
	var tile_result := _execute_cde2(cpu, stack, stack_reads, instruction_pcs)
	if not bool(tile_result.get("ok", false)):
		return tile_result
	cpu["pc"] = 0xE705
	_write_ram(ram, writes, 0xE705, 0x05FE, int(cpu["a"]))
	cpu["pc"] = 0xE708
	var holder_return := _pop_rts(cpu, stack, stack_reads)
	if holder_return != 0xD7FF:
		return {"ok": false, "error": "`$E6EC` did not return to the PASS handler at `$D7FF`."}
	cpu["pc"] = 0xD7FF
	instruction_pcs.append_array([0xE705, 0xE708])
	return {"ok": true, "holder_slot": holder_slot, "record_pointer": record_pointer,
		"tile_index": int(cpu["a"]), "error": ""}


func _execute_cde2(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary], instruction_pcs: Array[int]) -> Dictionary:
	if _cde2.size() != 38:
		return {"ok": false, "error": "`$CDE2` instruction source is unavailable."}
	var pc := 0xCDE2
	for _step in 128:
		if pc < 0xCDE2 or pc > 0xCE07:
			return {"ok": false, "error": "`$CDE2` branch escaped its source span."}
		var offset := pc - 0xCDE2
		var opcode := int(_cde2[offset])
		cpu["pc"] = pc
		instruction_pcs.append(pc)
		match opcode:
			0x8A: # TXA
				cpu["a"] = int(cpu["x"])
				_set_nz(cpu, int(cpu["a"]))
				pc += 1
			0x38: # SEC
				_set_flag(cpu, CARRY, true)
				pc += 1
			0x18: # CLC
				_set_flag(cpu, CARRY, false)
				pc += 1
			0xE9: # SBC #imm
				var operand := int(_cde2[offset + 1])
				var previous := int(cpu["a"])
				var borrow := 0 if (int(cpu["p"]) & CARRY) != 0 else 1
				var difference := previous - operand - borrow
				cpu["a"] = difference & 0xFF
				_set_flag(cpu, CARRY, difference >= 0)
				_set_flag(cpu, OVERFLOW, (((previous ^ int(cpu["a"])) \
						& (previous ^ operand) & 0x80) != 0))
				_set_nz(cpu, int(cpu["a"]))
				pc += 2
			0x90, 0xB0, 0x30, 0xD0: # BCC, BCS, BMI, BNE
				var displacement := int(_cde2[offset + 1])
				if displacement >= 0x80:
					displacement -= 0x100
				var take := false
				match opcode:
					0x90: take = (int(cpu["p"]) & CARRY) == 0
					0xB0: take = (int(cpu["p"]) & CARRY) != 0
					0x30: take = (int(cpu["p"]) & NEGATIVE) != 0
					0xD0: take = (int(cpu["p"]) & ZERO) == 0
				pc = (pc + 2 + displacement) & 0xFFFF if take else pc + 2
			0xC9: # CMP #imm
				var difference := int(cpu["a"]) - int(_cde2[offset + 1])
				_set_flag(cpu, CARRY, difference >= 0)
				_set_nz(cpu, difference & 0xFF)
				pc += 2
			0x4A: # LSR A
				var previous := int(cpu["a"])
				_set_flag(cpu, CARRY, (previous & 1) != 0)
				cpu["a"] = previous >> 1
				_set_nz(cpu, int(cpu["a"]))
				pc += 1
			0xAA: # TAX
				cpu["x"] = int(cpu["a"])
				_set_nz(cpu, int(cpu["x"]))
				pc += 1
			0x98: # TYA
				cpu["a"] = int(cpu["y"])
				_set_nz(cpu, int(cpu["a"]))
				pc += 1
			0xCA: # DEX
				cpu["x"] = (int(cpu["x"]) - 1) & 0xFF
				_set_nz(cpu, int(cpu["x"]))
				pc += 1
			0x69: # ADC #imm
				var previous := int(cpu["a"])
				var operand := int(_cde2[offset + 1])
				var total := previous + operand + (1 if (int(cpu["p"]) & CARRY) != 0 else 0)
				cpu["a"] = total & 0xFF
				_set_flag(cpu, CARRY, total > 0xFF)
				_set_flag(cpu, OVERFLOW, (((~(previous ^ operand)) \
						& (previous ^ int(cpu["a"])) & 0x80) != 0))
				_set_nz(cpu, int(cpu["a"]))
				pc += 2
			0xA9: # LDA #imm; invalid coordinate path returns $FF
				_set_a(cpu, int(_cde2[offset + 1]))
				pc += 2
			0x60: # RTS
				var return_pc := _pop_rts(cpu, stack, stack_reads)
				if return_pc != 0xE705:
					return {"ok": false, "error": "`$CDE2` returned to an unexpected caller address."}
				if int(cpu["a"]) == 0xFF:
					return {"ok": false, "error": "`$CDE2` rejected the live holder coordinate pair."}
				return {"ok": true, "return_pc": return_pc}
			_:
				return {"ok": false, "error": "Unsupported `$CDE2` opcode `$%02X` at `$%04X`." % [opcode, pc]}
	return {"ok": false, "error": "`$CDE2` exceeded its bounded instruction count."}


func _push_jsr(cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		stack_writes: Array[Dictionary], callsite: int, return_word: int) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	_write_stack(cpu, ram, stack, stack_writes, callsite, sp, (return_word >> 8) & 0xFF)
	sp = (sp - 1) & 0xFF
	_write_stack(cpu, ram, stack, stack_writes, callsite, sp, return_word & 0xFF)
	cpu["sp"] = (sp - 1) & 0xFF


func _pop_rts(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary]) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var low := int(stack[sp])
	stack_reads.append({"pc": int(cpu.get("pc", 0)), "address": 0x0100 + sp, "value": low})
	sp = (sp + 1) & 0xFF
	var high := int(stack[sp])
	stack_reads.append({"pc": int(cpu.get("pc", 0)), "address": 0x0100 + sp, "value": high})
	cpu["sp"] = sp
	return (((high << 8) | low) + 1) & 0xFFFF


func _write_stack(cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		writes: Array[Dictionary], source_pc: int, sp: int, value: int) -> void:
	var address := sp & 0xFF
	stack[address] = value & 0xFF
	ram[0x0100 + address] = value & 0xFF
	writes.append({"source_pc": source_pc, "address": 0x0100 + address,
		"value": value & 0xFF, "operation": "jsr_push_high" if sp == int(cpu["sp"]) else "jsr_push_low"})


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary],
		source_pc: int, address: int, value: int) -> void:
	ram[address & 0x07FF] = value & 0xFF
	writes.append({"source_pc": source_pc, "address": address & 0x07FF, "value": value & 0xFF})


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_nz(cpu: Dictionary, value: int) -> void:
	_set_flag(cpu, ZERO, (value & 0xFF) == 0)
	_set_flag(cpu, NEGATIVE, (value & 0x80) != 0)


func _set_flag(cpu: Dictionary, flag: int, enabled: bool) -> void:
	var p := int(cpu["p"]) & ~flag
	if enabled:
		p |= flag
	cpu["p"] = (p | 0x20) & 0xFF
	cpu["p_known_mask"] = (int(cpu["p_known_mask"]) | flag) & 0xFF


func _read_checked(path: String, expected_hash: String) -> PackedByteArray:
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != expected_hash:
		_fail("ROM source file is missing or failed its SHA-256 check: " + path)
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)


func _bytes_at(bytes: PackedByteArray, offset: int, expected: Array[int]) -> bool:
	if offset < 0 or offset + expected.size() > bytes.size():
		return false
	for index in expected.size():
		if int(bytes[offset + index]) != expected[index]:
			return false
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false
