extends RefCounted
class_name RomPassReceiverInputExecutor
## Executes the source-derived receiver poll semantics for the recorded PASS
## Down/A path. Entry is after the scheduler-backed `$CB0F` input poll at `$D80F`.
## Renderer calls are returned as pending events; holder transfer starts at `$D70C`.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_receiver_input/manifest.json"
const MANIFEST_SHA256 := "ddd9f9841da3dc79c36644a3f5baf58508c0acf35733e360e8cd2758132be510"
const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/pass_receiver_input/"

const ENTRY_PC := 0xD80F
const CONFIRM_EXIT_PC := 0xD70C
const FIXED_C000_BANK := 0x1E
const FIXED_E000_BANK := 0x1F
const RAM_SIZE := 0x0800
const STACK_SIZE := 0x0100
const PLAYER_RECORD_BASE := 0x0300
const PLAYER_RECORD_STRIDE := 0x0C
const MAX_RECEIVER_CANDIDATES := 4

const POLL_PREFIX := [
	0xAD, 0x1C, 0x00, 0x29, 0x0F, 0xF0, 0x21, 0xA2, 0x00, 0x4A,
	0xB0, 0x03, 0xE8, 0xD0, 0xFA, 0xBD, 0x4E, 0xD8,
]
const SCAN_PREFIX := [
	0xA9, 0x00, 0x8D, 0x30, 0x04, 0x8D, 0x25, 0x06, 0x48,
	0xCD, 0x41, 0x04, 0xF0, 0x3C, 0xC9, 0x00,
]
const CONFIRM_PREFIX := [
	0xA9, 0xFF, 0xAE, 0x25, 0x06, 0xF0, 0x09, 0xAE,
	0x30, 0x04, 0xCA, 0xD0, 0x09, 0xAD, 0x31, 0x04,
	0x8D, 0xFC, 0x05,
]
const RENDERER_RETURN_A_PREFIX := [
	0xA9, 0x40, 0x2D, 0x1E, 0x00, 0xF0, 0x01, 0x60,
	0xA9, 0x80, 0x2D, 0x1E, 0x00, 0xF0, 0xC4, 0x20,
	0x52, 0xD8, 0x90, 0xBF, 0x4C, 0x0C, 0xD7,
]
const CONFIRM_JUMP_TO_CURSOR_COMMIT := [0x4C, 0xD2, 0xD8]
const CONFIRM_CURSOR_COMMIT_TAIL := [0xAD, 0x24, 0x06, 0x8D, 0x38, 0x06, 0x38, 0x60]
const RECORD_POINTER_CODE := [
	0x0A, 0xA8, 0xB9, 0x89, 0xCD, 0x85, 0x34, 0xB9,
	0x8A, 0xCD, 0x85, 0x35, 0x60,
]
const COORDINATE_HELPER_PREFIX := [
	0x8A, 0x38, 0xE9, 0x30, 0x90, 0x1D, 0xC9, 0xA0,
	0xB0, 0x19, 0x4A, 0x4A, 0x4A, 0xAA, 0x98, 0x38,
	0xE9, 0x50, 0x90, 0x0F, 0xC9, 0x60, 0xB0, 0x0B,
]

var error_message := ""
var _configured := false
var _handler_bytes := PackedByteArray()
var _scan_bytes := PackedByteArray()
var _record_pointer_code := PackedByteArray()
var _record_pointer_table := PackedByteArray()
var _coordinate_helper := PackedByteArray()
var _manifest: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_manifest.clear()
	if not FileAccess.file_exists(MANIFEST_PATH) \
			or FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		return _fail("PASS receiver-input source manifest is missing or differs from the pinned extraction.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("PASS receiver-input source manifest is malformed.")
	_manifest = parsed
	if String(_manifest.get("schema", "")) != "ct2-pass-receiver-input-source-v1" \
			or String(_manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(_manifest.get("source_rom_size_bytes", -1)) != 393232:
		return _fail("PASS receiver-input sources do not identify the pinned supplied ROM revision.")
	var spans: Variant = _manifest.get("spans", [])
	if not spans is Array or spans.size() != 5:
		return _fail("PASS receiver-input manifest must identify the five required ROM spans.")
	var loaded: Dictionary = {}
	for row_variant: Variant in spans:
		if not row_variant is Dictionary:
			return _fail("PASS receiver-input manifest contains a malformed source span.")
		var row: Dictionary = row_variant
		var resource_path := RESOURCE_ROOT + String(row.get("resource", ""))
		var normalized_path := resource_path.simplify_path()
		if not FileAccess.file_exists(normalized_path):
			return _fail("A pinned PASS receiver-input ROM span is missing: " + normalized_path)
		var bytes := FileAccess.get_file_as_bytes(normalized_path)
		if bytes.size() != int(row.get("length_bytes", -1)) \
				or FileAccess.get_sha256(normalized_path) != String(row.get("sha256", "")):
			return _fail("A PASS receiver-input ROM span differs from its recorded byte length or hash: " + normalized_path)
		loaded[String(row.get("name", ""))] = bytes
	_handler_bytes = loaded.get("pass_receiver_handler_and_direction_delta_table", PackedByteArray())
	_scan_bytes = loaded.get("receiver_candidate_scan", PackedByteArray())
	_record_pointer_code = loaded.get("player_record_pointer_resolver", PackedByteArray())
	_record_pointer_table = loaded.get("player_record_pointer_table", PackedByteArray())
	_coordinate_helper = loaded.get("coordinate_to_field_tile_helper", PackedByteArray())
	if not _source_bytes_equal(_handler_bytes, 0xD80F - 0xD7E8, POLL_PREFIX) \
			or not _source_bytes_equal(_handler_bytes, 0xD84E - 0xD7E8, [0x0C, 0xF4, 0x01, 0xFF]) \
			or not _source_bytes_equal(_handler_bytes, 0xD852 - 0xD7E8, CONFIRM_PREFIX) \
			or not _source_bytes_equal(_handler_bytes, 0xD837 - 0xD7E8, RENDERER_RETURN_A_PREFIX) \
			or not _source_bytes_equal(_handler_bytes, 0xD865 - 0xD7E8, CONFIRM_JUMP_TO_CURSOR_COMMIT) \
			or not _source_bytes_equal(_handler_bytes, 0xD8D2 - 0xD7E8, CONFIRM_CURSOR_COMMIT_TAIL) \
			or not _source_bytes_equal(_scan_bytes, 0, SCAN_PREFIX) \
			or _record_pointer_code != PackedByteArray(RECORD_POINTER_CODE) \
			or not _source_bytes_equal(_coordinate_helper, 0, COORDINATE_HELPER_PREFIX) \
			or not _pointer_table_matches_source_code():
		return _fail("A receiver-poll opcode, helper, direction table, or player-record pointer table no longer matches the ROM-derived source.")
	_configured = true
	return true


## Accepts a scheduler-owned CPU/RAM/mapper boundary after `$CB0F` has returned
## and the live controller poll has populated `$001C/$001E`.
func execute_after_input_poll(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var validation := _validate_live_boundary(boundary)
	if not bool(validation.get("ok", false)):
		return _failure(String(validation.get("status", "invalid_live_boundary")),
			String(validation.get("error", "Invalid PASS receiver input boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_sp := int(boundary["sp"]) & 0xFF
	var final_sp := entry_sp
	var cpu := {
		"a": int(boundary["a"]) & 0xFF,
		"x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF,
		"p": (int(boundary["p"]) | 0x20) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF,
		"sp": entry_sp,
		"pc": ENTRY_PC,
	}
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var renderer_requests: Array[Dictionary] = []
	var pad: Dictionary = boundary["polled_controller"]
	var held_mask := int(pad["direction_mask"]) & 0xFF
	var direction := held_mask & 0x0F
	var buttons := int(pad["button_mask"]) & 0xFF
	var status := ""
	var exit_pc := CONFIRM_EXIT_PC

	# Same-ROM FCEUX shows Down at frame 9068 with both held `$001C` and
	# newly-pressed `$001E` equal to `$04`; `$D80F` follows `$001C` for the
	# direction branch, so preserve and accept the matching direction edge.
	if direction == 0x04 and buttons in [0, 0x04]:
		if int(ram[0x0624]) != 0x77 or int(ram[0x0430]) != 0 \
				or int(ram[0x0441]) != 0x06:
			return _failure("unsupported_receiver_scan_state",
				"Recorded Down support requires the live initial cursor `$77`, no candidates, and holder `$06`.")
		var old_cursor := int(ram[0x0624])
		var delta := int(_handler_bytes[0xD84E - 0xD7E8 + 2])
		var next_cursor := (old_cursor + delta) & 0xFF
		if next_cursor >= 0xF0:
			next_cursor = old_cursor
		instruction_pcs.append_array([0xD80F, 0xD812, 0xD816, 0xD818, 0xD81B,
			0xD81C, 0xD81E, 0xD821, 0xD822, 0xD825, 0xD82C, 0xD82F, 0xD834])
		_append_read(reads, 0xD80F, 0x001C, direction)
		_append_read(reads, 0xD822, 0x0624, old_cursor)
		_append_write(ram, writes, 0xD82F, 0x0624, next_cursor)
		cpu["a"] = 0x80
		cpu["x"] = 0x02
		cpu["p"] = ((int(cpu["p"]) & ~0xC2) | 0x23) & 0xFF
		cpu["p_known_mask"] = int(cpu["p_known_mask"]) | 0xC3
		if next_cursor != old_cursor:
			final_sp = _push_jsr_frame(stack, stack_writes, ram,
				0xD834, 0xD8F7, 0xD836, final_sp)
			var scan := _scan_receivers_at_cursor(ram, stack, writes, reads,
				stack_writes, stack_reads, instruction_pcs, final_sp)
			if not bool(scan.get("ok", false)):
				return _failure(String(scan.get("status", "unsupported_candidate_scan")),
					String(scan.get("error", "ROM candidate scan refused this source state.")))
			final_sp = int(scan.get("final_sp", -1))
			if final_sp != entry_sp - 2:
				return _failure("source_stack_mismatch", "ROM `$D8F7` did not return at the expected `$D837` stack depth.")
			renderer_requests.append_array(scan.get("renderer_requests", []))
			if renderer_requests.size() != 1:
				return _failure("unsupported_renderer_call_count",
					"The scanned receiver source path must reach one verified `$EF7F` descriptor call.")
			var renderer_request: Dictionary = renderer_requests[0]
			var renderer_callsite := int(renderer_request["source_pc"])
			var renderer_return_pc := renderer_callsite + 2
			var last_y := int(scan.get("last_y", -1))
			if last_y < 0 or last_y > 0xFF:
				return _failure("missing_live_scan_register", "The ROM candidate scan did not produce the live final Y register.")
			instruction_pcs.append_array([0xD949, 0xD94C, 0xD954, 0xD957,
				0xD961, 0xD962, 0xD964, 0xD967, 0xD96A, 0xD96C])
			final_sp = _push_jsr_frame(stack, stack_writes, ram, renderer_callsite,
				0xEF7F, renderer_return_pc, final_sp)
			cpu["a"] = int(renderer_request["descriptor_id"])
			cpu["x"] = 0
			cpu["y"] = last_y
			cpu["p"] = ((int(cpu["p"]) & ~0x82) | 0x21) & 0xFF
			cpu["p_known_mask"] = int(cpu["p_known_mask"]) | 0x83
			cpu["sp"] = final_sp
			exit_pc = 0xEF7F
			cpu["pc"] = exit_pc
			renderer_request["entry_pc"] = exit_pc
			renderer_request["return_pc"] = renderer_return_pc + 1
			renderer_request["entry_sp"] = final_sp
			renderer_request["entry_registers"] = cpu.duplicate(true)
			status = "receiver_down_scan_stopped_at_renderer_call"
	else:
		if direction != 0 or buttons != 0x80:
			return _failure("unsupported_receiver_input",
				"This bounded executor supports only the recorded Down-only poll and a later A-only poll.")
		if int(ram[0x0624]) != 0x78 or int(ram[0x0441]) != 0x06 \
				or int(ram[0x0430]) != 1 or int(ram[0x0431]) != 0x0A \
				or int(ram[0x0625]) != 1 or int(ram[0x05FC]) != 0x0A:
			return _failure("unsupported_receiver_confirm_state",
				"A confirmation requires the live `$D8F7` result: cursor `$78`, one candidate `$0A`, and selectable count `$01`.")
		instruction_pcs.append_array([0xD80F, 0xD812, 0xD814, 0xD837, 0xD839,
			0xD83F, 0xD841, 0xD846, 0xD852, 0xD854, 0xD857, 0xD859,
			0xD85C, 0xD85D, 0xD85F, 0xD862, 0xD8D2, 0xD8D5, 0xD8D8, 0xD849, 0xD84B])
		_append_read(reads, 0xD841, 0x001E, buttons)
		_append_read(reads, 0xD859, 0x0430, int(ram[0x0430]))
		_append_read(reads, 0xD85F, 0x0431, int(ram[0x0431]))
		_append_write(ram, writes, 0xD862, 0x05FC, int(ram[0x0431]))
		_append_read(reads, 0xD8D2, 0x0624, int(ram[0x0624]))
		_append_write(ram, writes, 0xD8CF, 0x02FC, 0xF8)
		_append_write(ram, writes, 0xD8D5, 0x0638, int(ram[0x0624]))
		cpu["a"] = int(ram[0x0624])
		cpu["x"] = 0
		cpu["p"] = ((int(cpu["p"]) & ~0xC2) | 0x21) & 0xFF
		cpu["p_known_mask"] = int(cpu["p_known_mask"]) | 0xC3
		status = "receiver_confirmed_at_d70c_before_holder_transfer"
		exit_pc = CONFIRM_EXIT_PC

	cpu["pc"] = exit_pc
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = exit_pc
	next_boundary["sp"] = final_sp
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM `$D80F` receiver input body"
	return {
		"ok": true,
		"status": status,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": ENTRY_PC,
		"exit_pc": exit_pc,
		"entry_sp": entry_sp,
		"final_sp": final_sp,
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": instruction_pcs,
		"source_reads": reads,
		"source_writes": writes,
		"source_stack_writes": stack_writes,
		"source_stack_reads": stack_reads,
		"source_stack_page_unchanged": stack_writes.is_empty(),
		"renderer_requests": renderer_requests,
		"ppu_events": [],
		"apu_events": [],
		"ppu_effects_applied": false,
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"next_boundary_snapshot": next_boundary,
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"instruction_level_parity_claimed": false,
		"unresolved": [
			"Descriptor renderer calls are returned as pending events; EF7F/PPU packet writes are not executed here.",
			"The A path stops at $D70C before holder transfer, actor movement, or the next decision wait.",
		],
	}


## Continues only the source-owned receiver A path from the `$D96F->$D837`
## renderer-return boundary. The `$D80F` poll route remains a separate entry.
func execute_after_receiver_renderer_return(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var validation := _validate_receiver_renderer_return_boundary(boundary)
	if not bool(validation.get("ok", false)):
		return _failure(String(validation.get("status", "invalid_receiver_return_boundary")),
			String(validation.get("error", "Invalid `$D837` receiver-return boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var mapper: Dictionary = (boundary["mapper"] as Dictionary).duplicate(true)
	var entry_sp := int(boundary["sp"]) & 0xFF
	var final_sp := entry_sp
	var entry_a := int(boundary["a"]) & 0xFF
	var entry_x := int(boundary["x"]) & 0xFF
	var entry_y := int(boundary["y"]) & 0xFF
	var p := (int(boundary["p"]) | 0x20) & 0xFF
	var p_known_mask := int(boundary.get("p_known_mask", 0xFF)) & 0xFF
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xD837, 0xD839, 0xD83C, 0xD83F, 0xD841,
		0xD844, 0xD846, 0xD852, 0xD854, 0xD857, 0xD859, 0xD85C,
		0xD85D, 0xD85F, 0xD862, 0xD865, 0xD8D2, 0xD8D5,
		0xD8D8, 0xD8D9, 0xD849, 0xD84B]

	# `$D837` first tests B, then A. This task supports only the observed
	# A-only mask `$001E=$80`; all branches and the D852 call are byte-checked.
	reads.append({"source_pc": 0xD839, "address": 0x001E, "value": int(ram[0x001E])})
	reads.append({"source_pc": 0xD841, "address": 0x001E, "value": int(ram[0x001E])})
	reads.append({"source_pc": 0xD854, "address": 0x0625, "value": int(ram[0x0625])})
	reads.append({"source_pc": 0xD859, "address": 0x0430, "value": int(ram[0x0430])})
	reads.append({"source_pc": 0xD85F, "address": 0x0431, "value": int(ram[0x0431])})
	reads.append({"source_pc": 0xD8D2, "address": 0x0624, "value": int(ram[0x0624])})

	# The JSR at `$D846` pushes `$D848`; the ROM commit routine's RTS returns to
	# `$D849`, sets carry, and the following BCC falls through to JMP `$D70C`.
	final_sp = _push_jsr_frame(stack, stack_writes, ram,
		0xD846, 0xD852, 0xD848, final_sp)
	_append_write(ram, writes, 0xD862, 0x05FC, int(ram[0x0431]))
	_append_write(ram, writes, 0xD8D5, 0x0638, int(ram[0x0624]))
	var subroutine_return := _pop_jsr_frame(stack, stack_reads, 0xD8D9,
		0xD848, final_sp)
	if not bool(subroutine_return.get("ok", false)) \
			or int(subroutine_return.get("resume_pc", -1)) != 0xD849:
		return _failure("source_stack_mismatch",
			"ROM `$D8D9` RTS did not return from `$D852` to the observed `$D849` carry branch.")
	final_sp = int(subroutine_return["sp"])
	p = ((p & ~0xC2) | 0x21) & 0xFF # final LDA leaves N/Z clear; SEC leaves carry set.
	p_known_mask = (p_known_mask | 0xC3) & 0xFF
	var cpu := {"a": int(ram[0x0624]), "x": 0, "y": entry_y,
		"p": p, "p_known_mask": p_known_mask, "sp": final_sp, "pc": 0xD70C}
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = 0xD70C
	next_boundary["sp"] = final_sp
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram.duplicate()
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM `$D837->$D846->$D852` A confirmation stopped at `$D70C`"
	return {
		"ok": true,
		"status": "receiver_confirmed_at_d70c_from_renderer_return",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": MANIFEST_SHA256,
		"entry_pc": 0xD837,
		"entry_sp": entry_sp,
		"exit_pc": 0xD70C,
		"final_sp": final_sp,
		"registers": cpu.duplicate(true),
		"mapper": mapper,
		"source_instruction_pcs": instruction_pcs,
		"source_reads": reads,
		"source_writes": writes,
		"source_stack_writes": stack_writes,
		"source_stack_reads": stack_reads,
		"source_stack_page_unchanged": false,
		"source_call": {"source_pc": 0xD846, "target_pc": 0xD852,
			"return_word": 0xD848, "resume_pc": 0xD849},
		"next_boundary_snapshot": next_boundary,
		"trace_state_used": false,
		"emulator_data_used": false,
		"source_cycle_timing_modeled": false,
		"ppu_events": [],
		"apu_events": [],
		"ppu_effects_applied": false,
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"runtime_integrated": false,
	}


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"rom_sha256": ROM_SHA256,
		"manifest": MANIFEST_PATH,
		"manifest_sha256": MANIFEST_SHA256,
		"handler_span_sha256": String(_span_row("pass_receiver_handler_and_direction_delta_table").get("sha256", "")),
		"scan_span_sha256": String(_span_row("receiver_candidate_scan").get("sha256", "")),
		"record_pointer_code_sha256": String(_span_row("player_record_pointer_resolver").get("sha256", "")),
		"coordinate_helper_sha256": String(_span_row("coordinate_to_field_tile_helper").get("sha256", "")),
	}


func _scan_receivers_at_cursor(ram: PackedByteArray, stack: PackedByteArray,
		writes: Array[Dictionary], reads: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		instruction_pcs: Array[int], start_sp: int) -> Dictionary:
	_append_write(ram, writes, 0xD8F9, 0x0430, 0)
	_append_write(ram, writes, 0xD8FC, 0x0625, 0)
	instruction_pcs.append_array([0xD8F7, 0xD8F9, 0xD8FC, 0xD8FF])
	var scan_sp := start_sp & 0xFF
	var count := 0
	var selectable_count := 0
	var last_y := -1
	var candidate_slots: Array[int] = []
	for slot in 0x16:
		var current_slot := slot
		instruction_pcs.append_array([0xD8FF, 0xD900, 0xD903])
		scan_sp = _push_stack_byte(stack, stack_writes, ram, 0xD8FF,
			"pha_player_slot", current_slot, scan_sp)
		if current_slot == int(ram[0x0441]):
			instruction_pcs.append(0xD941)
		var skipped_holder := current_slot == int(ram[0x0441])
		var skipped_zero := false
		var skipped_sentinel := false
		if skipped_holder:
			var holder_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
				"pla_player_slot", scan_sp)
			scan_sp = int(holder_pop["sp"])
			continue
		instruction_pcs.append_array([0xD905, 0xD907])
		if current_slot == 0:
			instruction_pcs.append(0xD941)
			skipped_zero = true
		if skipped_zero:
			var zero_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
				"pla_player_slot", scan_sp)
			scan_sp = int(zero_pop["sp"])
			continue
		instruction_pcs.append_array([0xD909, 0xD90B])
		if current_slot == 0x0B:
			instruction_pcs.append(0xD941)
			skipped_sentinel = true
		if skipped_sentinel:
			var sentinel_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
				"pla_player_slot", scan_sp)
			scan_sp = int(sentinel_pop["sp"])
			continue
		var record_pointer := _record_pointer_for_slot(current_slot)
		if record_pointer < PLAYER_RECORD_BASE or record_pointer + 8 >= RAM_SIZE:
			return {"ok": false, "status": "invalid_player_pointer", "error": "ROM `$CD7C/$CD89` resolved an invalid live record pointer for slot `$%02X`." % current_slot}
		var x := int(ram[record_pointer + 6])
		var y := int(ram[record_pointer + 8])
		last_y = y
		_append_read(reads, 0xD90D, 0xCD89 + current_slot * 2, record_pointer & 0xFF)
		_append_read(reads, 0xD90D, 0xCD8A + current_slot * 2, (record_pointer >> 8) & 0xFF)
		_append_read(reads, 0xD913, record_pointer + 6, x)
		_append_read(reads, 0xD918, record_pointer + 8, y)
		instruction_pcs.append_array([0xD90D, 0xCD7C, 0xCD7D, 0xCD80, 0xCD83,
			0xCD86, 0xCD88, 0xD910, 0xD912, 0xD915, 0xD917, 0xD91A,
			0xD91D, 0xD920])
		scan_sp = _push_jsr_frame(stack, stack_writes, ram, 0xD90D,
			0xCD7C, 0xD90F, scan_sp)
		var record_return := _pop_jsr_frame(stack, stack_reads, 0xCD88,
			0xD90F, scan_sp)
		if not bool(record_return.get("ok", false)):
			return {"ok": false, "status": "source_stack_mismatch", "error": "ROM `$CD7C` RTS returned to an unexpected D8F7 instruction."}
		scan_sp = int(record_return["sp"])
		var tile_index := _coordinate_to_tile_index_from_source(x, y)
		_append_coordinate_helper_path(instruction_pcs, x, y)
		scan_sp = _push_jsr_frame(stack, stack_writes, ram, 0xD91A,
			0xCDE2, 0xD91C, scan_sp)
		var coordinate_return := _pop_jsr_frame(stack, stack_reads, 0xCE07,
			0xD91C, scan_sp)
		if not bool(coordinate_return.get("ok", false)):
			return {"ok": false, "status": "source_stack_mismatch", "error": "ROM `$CDE2` RTS returned to an unexpected D8F7 instruction."}
		scan_sp = int(coordinate_return["sp"])
		if tile_index != int(ram[0x0624]):
			instruction_pcs.append(0xD941)
			var mismatch_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
				"pla_player_slot", scan_sp)
			scan_sp = int(mismatch_pop["sp"])
			continue
		instruction_pcs.append_array([0xD922, 0xD924, 0xD927])
		if count >= MAX_RECEIVER_CANDIDATES:
			instruction_pcs.append(0xD941)
			var full_list_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
				"pla_player_slot", scan_sp)
			scan_sp = int(full_list_pop["sp"])
			continue
		instruction_pcs.append_array([0xD929, 0xD92A, 0xD92C, 0xD92D])
		var candidate_pop := _pop_stack_byte(stack, stack_reads, 0xD929,
			"pla_candidate_slot", scan_sp)
		scan_sp = int(candidate_pop["sp"])
		scan_sp = _push_stack_byte(stack, stack_writes, ram, 0xD92A,
			"pha_candidate_slot", int(candidate_pop["value"]), scan_sp)
		if current_slot >= 0x0B and selectable_count != 0:
			instruction_pcs.append_array([0xD92F, 0xD932, 0xD941])
			var filtered_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
				"pla_player_slot", scan_sp)
			scan_sp = int(filtered_pop["sp"])
			continue
		candidate_slots.append(current_slot)
		_append_write(ram, writes, 0xD934, 0x0431 + count, current_slot)
		count += 1
		_append_write(ram, writes, 0xD937, 0x0430, count)
		instruction_pcs.append_array([0xD934, 0xD937, 0xD93A, 0xD93C])
		if current_slot < 0x0B:
			selectable_count += 1
			_append_write(ram, writes, 0xD93E, 0x0625, selectable_count)
			instruction_pcs.append(0xD93E)
		instruction_pcs.append_array([0xD941, 0xD942, 0xD944, 0xD945, 0xD947])
		var candidate_loop_pop := _pop_stack_byte(stack, stack_reads, 0xD941,
			"pla_player_slot", scan_sp)
		scan_sp = int(candidate_loop_pop["sp"])
	if count == 0:
		return {"ok": true, "candidate_slots": candidate_slots,
			"last_y": last_y,
			"final_sp": scan_sp,
			"renderer_requests": [_renderer_request(0xD950, 0x1C)]}
	if selectable_count == 0:
		return {"ok": true, "candidate_slots": candidate_slots,
			"last_y": last_y,
			"final_sp": scan_sp,
			"renderer_requests": [_renderer_request(0xD95D, count + 0x1F)]}
	if count == 1:
		_append_write(ram, writes, 0xD967, 0x05FC, candidate_slots[0])
		return {"ok": true, "candidate_slots": candidate_slots,
			"last_y": last_y,
			"final_sp": scan_sp,
			"renderer_requests": [_renderer_request(0xD96C, 0x1D)]}
	return {"ok": true, "candidate_slots": candidate_slots,
		"last_y": last_y,
		"final_sp": scan_sp,
		"renderer_requests": [_renderer_request(0xD974, count + 0x18)]}


func _coordinate_to_tile_index_from_source(x: int, y: int) -> int:
	# `$CDE2` checks the ROM bounds, shifts each coordinate by three, and adds
	# twelve per X tile column. This is its byte-level arithmetic, not a trace lookup.
	var x_delta := (x - 0x30) & 0xFF
	if x < 0x30 or x_delta >= 0xA0:
		return 0xFF
	var y_delta := (y - 0x50) & 0xFF
	if y < 0x50 or y_delta >= 0x60:
		return 0xFF
	var x_tile := x_delta >> 3
	var y_tile := y_delta >> 3
	return (x_tile * 0x0C + y_tile) & 0xFF


func _append_coordinate_helper_path(instruction_pcs: Array[int], x: int, y: int) -> void:
	instruction_pcs.append_array([0xCDE2, 0xCDE3, 0xCDE4, 0xCDE6])
	var x_delta := (x - 0x30) & 0xFF
	if x < 0x30:
		instruction_pcs.append_array([0xCE05, 0xCE07])
		return
	instruction_pcs.append_array([0xCDE8, 0xCDEA])
	if x_delta >= 0xA0:
		instruction_pcs.append_array([0xCE05, 0xCE07])
		return
	instruction_pcs.append_array([0xCDEC, 0xCDED, 0xCDEE, 0xCDEF,
		0xCDF0, 0xCDF1, 0xCDF2, 0xCDF4])
	var y_delta := (y - 0x50) & 0xFF
	if y < 0x50:
		instruction_pcs.append_array([0xCE05, 0xCE07])
		return
	instruction_pcs.append_array([0xCDF6, 0xCDF8])
	if y_delta >= 0x60:
		instruction_pcs.append_array([0xCE05, 0xCE07])
		return
	instruction_pcs.append_array([0xCDFA, 0xCDFB, 0xCDFC])
	var x_tile := x_delta >> 3
	var accumulator := y_delta >> 3
	var remaining := x_tile
	while true:
		instruction_pcs.append_array([0xCDFD, 0xCDFE])
		remaining -= 1
		if remaining < 0:
			break
		instruction_pcs.append_array([0xCE00, 0xCE01, 0xCE03])
		accumulator = (accumulator + 0x0C) & 0xFF
		if accumulator == 0:
			break
	instruction_pcs.append(0xCE07)


func _record_pointer_for_slot(slot: int) -> int:
	if slot < 0 or slot >= 0x16:
		return -1
	var offset := slot * 2
	return int(_record_pointer_table[offset]) \
		| (int(_record_pointer_table[offset + 1]) << 8)


func _pointer_table_matches_source_code() -> bool:
	if _record_pointer_table.size() != 0x2C:
		return false
	for slot in 0x16:
		if _record_pointer_for_slot(slot) != PLAYER_RECORD_BASE + slot * PLAYER_RECORD_STRIDE:
			return false
	return true


func _validate_live_boundary(boundary: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	var input_variant: Variant = boundary.get("polled_controller", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("pc", -1)) != ENTRY_PC:
		return {"ok": false, "status": "invalid_live_boundary", "error": "Input must be the pinned ROM's live post-`$CB0F` `$D80F` boundary."}
	if not ram_variant is PackedByteArray or (ram_variant as PackedByteArray).size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or (stack_variant as PackedByteArray).size() != STACK_SIZE:
		return {"ok": false, "status": "invalid_live_boundary", "error": "Receiver polling requires live 2 KiB RAM and a 256-byte CPU stack page."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if ram.slice(0x0100, 0x0200) != stack:
		return {"ok": false, "status": "stack_mirror_mismatch", "error": "The scheduler-owned stack image must match the RAM stack-page mirror."}
	var sp := int(boundary.get("sp", -1))
	if sp < 0 or sp > 0xFF:
		return {"ok": false, "status": "invalid_live_boundary", "error": "The live 6502 stack pointer is missing or outside one byte."}
	for register_name: String in ["a", "x", "y", "p"]:
		var register_value := int(boundary.get(register_name, -1))
		if register_value < 0 or register_value > 0xFF:
			return {"ok": false, "status": "invalid_live_boundary", "error": "Live CPU register `%s` must be supplied as a byte." % register_name}
	var mapper: Dictionary
	if not mapper_variant is Dictionary:
		return {"ok": false, "status": "invalid_mapper_state", "error": "The boundary omits its live MMC3 fixed-bank mapping."}
	mapper = mapper_variant
	if int(boundary.get("executing_cpu_bank", -1)) != FIXED_C000_BANK \
			or int(mapper.get("cpu_c000_bank", -1)) != FIXED_C000_BANK \
			or int(mapper.get("cpu_e000_bank", -1)) != FIXED_E000_BANK:
		return {"ok": false, "status": "invalid_mapper_state", "error": "The D8 handler and EF7F renderer call require live MMC3 `$C000=$1E` and `$E000=$1F` mappings."}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary:
		return {"ok": false, "status": "invalid_mapper_state", "error": "The boundary omits MMC3 bank registers needed to validate the ROM mapping."}
	var registers: Dictionary = registers_variant
	if int(registers.get(6, registers.get("6", -1))) != int(ram[0x0024]) \
			or int(registers.get(7, registers.get("7", -1))) != int(ram[0x0025]):
		return {"ok": false, "status": "invalid_mapper_state", "error": "Live MMC3 registers 6/7 must match the source bank shadows `$0024/$0025`."}
	if not input_variant is Dictionary:
		return {"ok": false, "status": "invalid_polled_input", "error": "The post-`$CB0F` boundary requires its explicit polled controller masks."}
	var pad: Dictionary = input_variant
	var direction := int(pad.get("direction_mask", -1))
	var buttons := int(pad.get("button_mask", -1))
	if direction < 0 or direction > 0xFF or buttons < 0 or buttons > 0xFF \
			or direction != int(ram[0x001C]) or buttons != int(ram[0x001E]):
		return {"ok": false, "status": "input_latch_mismatch", "error": "Polled controller masks must equal the source input-latch bytes `$001C/$001E`."}
	for forbidden_key: String in ["fceux_ram", "captured_ram", "emulator_snapshot", "trace_ram"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "trace_state_forbidden", "error": "Emulator or trace memory cannot seed the source executor."}
	if bool(boundary.get("trace_state_used", false)) or bool(boundary.get("emulator_data_used", false)):
		return {"ok": false, "status": "trace_state_forbidden", "error": "The receiver input boundary cannot be trace-seeded."}
	return {"ok": true}


func _validate_receiver_renderer_return_boundary(boundary: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	var registers_variant: Variant = boundary.get("registers", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("pc", -1)) != 0xD837 \
			or String(boundary.get("source_label", "")) \
			!= "ROM `$D96F` RTS returned from PASS receiver descriptor renderer to `$D837`" \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("executing_cpu_bank", -1)) != FIXED_C000_BANK:
		return {"ok": false, "status": "invalid_receiver_return_boundary",
			"error": "A-edge continuation requires the bridge-produced slot-$05 `$D96F RTS->$D837` boundary."}
	if not ram_variant is PackedByteArray or (ram_variant as PackedByteArray).size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or (stack_variant as PackedByteArray).size() != STACK_SIZE \
			or not mapper_variant is Dictionary or not registers_variant is Dictionary:
		return {"ok": false, "status": "invalid_receiver_return_boundary",
			"error": "The `$D837` boundary must include complete live RAM, stack, registers, and MMC3 mapping."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var registers: Dictionary = registers_variant
	var sp := int(boundary.get("sp", -1))
	if ram.slice(0x0100, 0x0200) != stack:
		return {"ok": false, "status": "stack_mirror_mismatch",
			"error": "The bridge-return stack page must match RAM `$0100-$01FF`."}
	if sp < 0 or sp > 0xFF or int(mapper.get("fixed_low", -1)) != FIXED_C000_BANK \
			or int(mapper.get("fixed_high", -1)) != FIXED_E000_BANK \
			or int(mapper.get("bank_low", -1)) != int(boundary.get("bank_low", -2)) \
			or int(mapper.get("bank_high", -1)) != int(boundary.get("bank_high", -2)) \
			or int(mapper.get("bank_low", -1)) != int(ram[0x0024]) \
			or int(mapper.get("bank_high", -1)) != int(ram[0x0025]) \
			or int(mapper.get("select", -1)) < 0 or int(mapper.get("select", -1)) > 0xFF:
		return {"ok": false, "status": "invalid_mapper_state",
			"error": "The bridge-return boundary must preserve a coherent MMC3 bank pair and fixed `$1E/$1F` banks."}
	for register_name: String in ["a", "x", "y", "p"]:
		var value := int(boundary.get(register_name, -1))
		if value < 0 or value > 0xFF \
				or value != int(registers.get(register_name, -2)):
			return {"ok": false, "status": "invalid_receiver_return_registers",
				"error": "Top-level and nested `$D837` CPU register `%s` must be present and match." % register_name}
	if int(boundary.get("p_known_mask", -1)) != int(registers.get("p_known_mask", -2)) \
			or (int(boundary.get("p", -1)) & 0x20) == 0 \
			or (int(boundary.get("p_known_mask", -1)) & 0x20) == 0:
		return {"ok": false, "status": "invalid_receiver_return_registers",
			"error": "The bridge-return status flags must include the known 6502 unused bit."}
	if int(registers.get("pc", -1)) != 0xD837 or int(registers.get("sp", -1)) != sp:
		return {"ok": false, "status": "invalid_receiver_return_registers",
			"error": "Nested CPU registers must point at `$D837` with the boundary stack pointer."}
	if int(ram[0x001E]) != 0x80:
		return {"ok": false, "status": "unsupported_receiver_input",
			"error": "This continuation supports the recorded A-edge branch `$001E=$80` only."}
	if int(ram[0x0624]) != 0x78 or int(ram[0x0441]) != 0x06 \
			or int(ram[0x0430]) != 1 or int(ram[0x0431]) != 0x0A \
			or int(ram[0x0625]) != 1 or int(ram[0x05FC]) != 0x0A:
		return {"ok": false, "status": "unsupported_receiver_confirm_state",
			"error": "The `$D837` A path requires cursor `$78`, one selectable candidate `$0A`, and holder `$06`."}
	# `$D96F` returned through `$D836`; its consumed word and the stale nested
	# renderer word remain in RAM below the new SP. Validate both before JSR D852.
	if int(stack[(sp - 3) & 0xFF]) != 0x6E or int(stack[(sp - 2) & 0xFF]) != 0xD9 \
			or int(stack[(sp - 1) & 0xFF]) != 0x36 or int(stack[sp & 0xFF]) != 0xD8:
		return {"ok": false, "status": "invalid_receiver_return_stack",
			"error": "The `$D837` stack must retain the exact `$D96E` renderer and consumed `$D836` return words."}
	if bool(boundary.get("trace_state_used", true)) or bool(boundary.get("emulator_data_used", true)):
		return {"ok": false, "status": "trace_state_forbidden",
			"error": "The receiver A continuation cannot use emulator or trace memory as runtime input."}
	for forbidden_key: String in ["fceux_ram", "captured_ram", "emulator_snapshot", "trace_ram"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "trace_state_forbidden",
				"error": "Emulator snapshots cannot seed the receiver A continuation."}
	if not _source_bytes_equal(_handler_bytes, 0xD837 - 0xD7E8, RENDERER_RETURN_A_PREFIX) \
			or not _source_bytes_equal(_handler_bytes, 0xD852 - 0xD7E8, CONFIRM_PREFIX) \
			or not _source_bytes_equal(_handler_bytes, 0xD865 - 0xD7E8, CONFIRM_JUMP_TO_CURSOR_COMMIT) \
			or not _source_bytes_equal(_handler_bytes, 0xD8D2 - 0xD7E8, CONFIRM_CURSOR_COMMIT_TAIL):
		return {"ok": false, "status": "source_integrity_failure",
			"error": "The ROM-backed `$D837->$D846->$D852->$D70C` source bytes no longer match the pinned handler."}
	return {"ok": true}


func _renderer_request(source_pc: int, descriptor: int) -> Dictionary:
	return {
		"source_pc": source_pc,
		"callee_pc": 0xEF7F,
		"descriptor_id": descriptor & 0xFF,
		"source_span": "D8F7-D978",
		"pending": true,
		"ppu_effects_applied": false,
	}


func _append_read(reads: Array[Dictionary], source_pc: int, address: int, value: int) -> void:
	reads.append({"source_pc": source_pc, "address": address, "value": value & 0xFF})


func _append_write(ram: PackedByteArray, writes: Array[Dictionary],
		source_pc: int, address: int, value: int) -> void:
	var byte_value := value & 0xFF
	ram[address] = byte_value
	writes.append({"source_pc": source_pc, "trace_pc": (source_pc + 3) & 0xFFFF,
		"address": address, "value": byte_value})


func _push_jsr_frame(stack: PackedByteArray, stack_writes: Array[Dictionary],
		ram: PackedByteArray, source_pc: int, target_pc: int,
		return_pc: int, stack_pointer: int) -> int:
	var sp := stack_pointer & 0xFF
	var high := (return_pc >> 8) & 0xFF
	var low := return_pc & 0xFF
	stack[sp] = high
	ram[0x0100 + sp] = high
	stack_writes.append({"source_pc": source_pc, "target_pc": target_pc,
		"address": 0x0100 + sp, "value": high, "operation": "jsr_push_high"})
	sp = (sp - 1) & 0xFF
	stack[sp] = low
	ram[0x0100 + sp] = low
	stack_writes.append({"source_pc": source_pc, "target_pc": target_pc,
		"address": 0x0100 + sp, "value": low, "operation": "jsr_push_low"})
	return (sp - 1) & 0xFF


func _push_stack_byte(stack: PackedByteArray, stack_writes: Array[Dictionary],
		ram: PackedByteArray, source_pc: int, operation: String,
		value: int, stack_pointer: int) -> int:
	var sp := stack_pointer & 0xFF
	var byte_value := value & 0xFF
	stack[sp] = byte_value
	ram[0x0100 + sp] = byte_value
	stack_writes.append({"source_pc": source_pc, "address": 0x0100 + sp,
		"value": byte_value, "operation": operation})
	return (sp - 1) & 0xFF


func _pop_stack_byte(stack: PackedByteArray, stack_reads: Array[Dictionary],
		source_pc: int, operation: String, stack_pointer: int) -> Dictionary:
	var sp := (stack_pointer + 1) & 0xFF
	var value := int(stack[sp])
	stack_reads.append({"source_pc": source_pc, "address": 0x0100 + sp,
		"value": value, "operation": operation})
	return {"sp": sp, "value": value}


func _pop_jsr_frame(stack: PackedByteArray, stack_reads: Array[Dictionary],
		source_pc: int, expected_return_word: int, stack_pointer: int) -> Dictionary:
	var low_read := _pop_stack_byte(stack, stack_reads, source_pc,
		"rts_pop_return_low", stack_pointer)
	var high_read := _pop_stack_byte(stack, stack_reads, source_pc,
		"rts_pop_return_high", int(low_read["sp"]))
	var return_word := (int(high_read["value"]) << 8) | int(low_read["value"])
	return {"ok": return_word == expected_return_word,
		"sp": high_read["sp"], "return_word": return_word,
		"resume_pc": (return_word + 1) & 0xFFFF}


func _source_bytes_equal(source: PackedByteArray, offset: int, expected: Array) -> bool:
	if offset < 0 or offset + expected.size() > source.size():
		return false
	for index in expected.size():
		if int(source[offset + index]) != int(expected[index]):
			return false
	return true


func _span_row(name: String) -> Dictionary:
	var spans: Variant = _manifest.get("spans", [])
	if not spans is Array:
		return {}
	for row_variant: Variant in spans:
		if row_variant is Dictionary and String((row_variant as Dictionary).get("name", "")) == name:
			return row_variant
	return {}


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {
		"ok": false,
		"status": status,
		"error": message,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func _fail(message: String) -> bool:
	error_message = message
	return false
