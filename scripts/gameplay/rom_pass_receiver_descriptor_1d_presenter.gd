class_name RomPassReceiverDescriptor1DPresenter
extends RefCounted
## Builds the first two descriptor-$1D packet candidates from a real pending
## $D96C->$EF7F receipt and its live RAM. This is not a 6502 renderer or PPU
## queue executor: it stops before the asynchronous bank-$18/$C515 worker.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/menus/pass_receiver_down_menu/manifest.json"
const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/menus/pass_receiver_down_menu/"
const MENU_ROOT := "res://reference/rom_extract/gameplay/menus/first_action_menu/"
const EXPECTED_MANIFEST_SHA256 := "a992da14cb1ed1aede98098928a1f496949ab0927b479190e393cc8883d0a7aa"
const LAYOUT_SCRIPT := preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const MATCH_PLAYER_STATE_SCRIPT := preload("res://scripts/gameplay/first_action_menu_match_player_state.gd")
const DYNAMIC_RESOLVER_SCRIPT := preload("res://scripts/gameplay/first_action_menu_dynamic_resolver.gd")
const HEADER_SIZE := 9
const RECEIVER_SLOT_RAM := 0x05FC
const PLAYER_RECORD_BASE := 0x0300
const PLAYER_RECORD_SIZE := 0x0C
const PLAYER_RECORD_MIN_SIZE := 4

const SOURCE_HASHES := {
	"window_3x3_tile_ids.bin": "dcb1f10d1a9a0fa616fa2e065790ce038722b09968d265e7901770b3bf9133e0",
	"player_record_pointer_table_22.bin": "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185",
	"player_position_table_11.bin": "59b7c4f0b0547e653a067cd2736c0118db1ec4b12cef3a260f952d0ad1027252",
	"player_name_pointer_table_00_ef.bin": "9009e3d6f66a170b0f1d6405894645d119f36caf100552581b4d5faba51b1dd7",
	"player_name_streams_f509_fd14.bin": "391afd3e6077ebba2f5e211d6d1baec33a70a4989937e6c231cdb83e26778e90",
	"guest_player_name_tiles_11x4.bin": "e1dbb6d11eae6e821f31e2f5d664da38ef2c95797b357a38c2cb1a42b99d3e76",
	"player_stat_profile_map_00_22.bin": "a16ef4a351fe79c6465741d75e3700b1bfe84f6a28ddee5e837aba226cb4ff48",
	"player_stat_profile_map_23_ef.bin": "1462cd0ec2b9c92890e8ec90835be5075cbb78d2998ff34a03ccb91526b7372d",
	"player_stat_profiles_00_8c.bin": "3236a005cc380c17351cf6ebac20f3f090be2a0a67ba6d8849cd8e6bcaf95fff",
	"player_stat_value_curve_00_bf.bin": "2fceb02fec4ccf3bf8b9bade56d96aa16e20a1e690da4564fce45ed9c8cf1170",
}

var error_message := ""
var _configured := false
var _manifest: Dictionary = {}
var _descriptor := PackedByteArray()
var _rows: Array[PackedByteArray] = []
var _frame_tiles := PackedByteArray()
var _record_pointers := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	if not FileAccess.file_exists(MANIFEST_PATH) \
			or FileAccess.get_sha256(MANIFEST_PATH) != EXPECTED_MANIFEST_SHA256:
		return _fail("Descriptor-$1D manifest is missing or differs from the pinned ROM export.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Descriptor-$1D manifest is malformed.")
	_manifest = parsed
	if String(_manifest.get("schema", "")) != "ct2-pass-receiver-descriptor-1d-source-v1" \
			or String(_manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(_manifest.get("source_rom_size_bytes", -1)) != 393232:
		return _fail("Descriptor-$1D sources do not identify the pinned supplied ROM.")
	var span_rows: Variant = _manifest.get("spans", [])
	if not span_rows is Array or span_rows.size() != 12:
		return _fail("Descriptor-$1D manifest must pin its 12 raw source spans.")
	var loaded: Dictionary = {}
	for row_variant: Variant in span_rows:
		if not row_variant is Dictionary:
			return _fail("Descriptor-$1D manifest contains a malformed source span.")
		var row: Dictionary = row_variant
		var name := String(row.get("name", ""))
		var path := (RESOURCE_ROOT + String(row.get("resource", ""))).simplify_path()
		if not FileAccess.file_exists(path):
			return _fail("A pinned descriptor-$1D ROM span is missing: " + path)
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(row.get("length_bytes", -1)) \
				or FileAccess.get_sha256(path) != String(row.get("sha256", "")):
			return _fail("A descriptor-$1D span differs from its byte length or manifest hash: " + path)
		loaded[name] = bytes
	for name: String in ["token_dispatch_prefix", "token_vector_E0_E3",
			"token_handlers_E0_E3", "descriptor_style_selector"]:
		if not loaded.has(name) or not _token_span_matches(name, loaded[name]):
			return _fail("ROM token/style source no longer proves the E2/E3 dispatch and alias mapping: " + name)
	var selector: PackedByteArray = loaded.get("descriptor_style_table_entry", PackedByteArray())
	if selector != PackedByteArray([0x02]):
		return _fail("Descriptor $1D packed style byte at $B3C4 is not $02.")
	var pointer_entry: PackedByteArray = loaded.get("descriptor_pointer_entry_1D", PackedByteArray())
	if pointer_entry != PackedByteArray([0xC7, 0xB6]):
		return _fail("Descriptor $1D pointer entry no longer resolves to $B6C7.")
	_descriptor = loaded.get("descriptor_1D", PackedByteArray())
	if _descriptor.size() != 29 or _descriptor[8] != 5:
		return _fail("Descriptor $1D has an unexpected header or row count.")
	var descriptor_id := 0x1D
	var style_entry_index := descriptor_id >> 2
	var packed_selector := descriptor_id & 0x03
	var selected_family := (int(selector[0]) >> (packed_selector * 2)) & 0x03
	if style_entry_index != 7 or packed_selector != 1 or selected_family != 0:
		return _fail("Descriptor $1D does not select the shared ROM window family zero.")
	_rows.clear()
	for row_index in 5:
		_rows.append(loaded.get("row_%02d" % row_index, PackedByteArray()))
		if _rows[row_index].is_empty() or _rows[row_index][_rows[row_index].size() - 1] != 0xFC:
			return _fail("Descriptor $1D text row %d is missing its ROM $FC terminator." % row_index)
	_frame_tiles = FileAccess.get_file_as_bytes(MENU_ROOT + "window_3x3_tile_ids.bin")
	_record_pointers = FileAccess.get_file_as_bytes(MENU_ROOT + "player_record_pointer_table_22.bin")
	if _frame_tiles.size() != 9 \
			or FileAccess.get_sha256(MENU_ROOT + "window_3x3_tile_ids.bin") != SOURCE_HASHES["window_3x3_tile_ids.bin"]:
		return _fail("The shared ROM window frame family is missing or differs from its pinned bytes.")
	for filename: String in SOURCE_HASHES:
		var path := MENU_ROOT + filename
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != SOURCE_HASHES[filename]:
			return _fail("A dynamic E2/E3 ROM table is missing or differs from the pinned bytes: " + filename)
	if _record_pointers.size() != 0x2C:
		return _fail("The ROM player-record pointer table must contain 22 pointers.")
	_configured = true
	return true


## Consumes the receiver executor's exact pending call receipt and derives only
## progress packets 0 and 1. It never accepts a detached slot or renderer
## endpoint; descriptor, CPU boundary and player record come from live output.
func present_first_queue_batch(down_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var boundary_check := _validate_pending_call(down_result)
	if not bool(boundary_check.get("ok", false)):
		return _failure(String(boundary_check.get("status", "invalid_pending_call")),
			String(boundary_check.get("error", "Invalid descriptor-$1D renderer call receipt.")))
	var boundary: Dictionary = down_result["next_boundary_snapshot"]
	var ram: PackedByteArray = boundary["ram_image"]
	var scan_y_receipt: Dictionary = boundary_check.get("scan_y_receipt", {})
	var slot := int(ram[RECEIVER_SLOT_RAM])
	if slot < 0 or slot >= 0x16:
		return _failure("unsupported_receiver_slot", "Live $05FC receiver slot is outside ROM's 22-player pointer table.")
	var pointer_offset := slot * 2
	var record_address := int(_record_pointers[pointer_offset]) | (int(_record_pointers[pointer_offset + 1]) << 8)
	if record_address != PLAYER_RECORD_BASE + slot * PLAYER_RECORD_SIZE \
			or record_address + PLAYER_RECORD_MIN_SIZE > ram.size():
		return _failure("player_record_pointer_mismatch", "ROM pointer table does not resolve the live receiver to its expected record.")
	var state := MATCH_PLAYER_STATE_SCRIPT.new() as FirstActionMenuMatchPlayerState
	state.player_slot_index = slot
	state.player_id = int(ram[record_address])
	state.current_energy = int(ram[record_address + 1]) | (int(ram[record_address + 2]) << 8)
	state.level = int(ram[record_address + 3])
	var resolver := DYNAMIC_RESOLVER_SCRIPT.new() as FirstActionMenuDynamicResolver
	resolver.configure(state)
	if not resolver.has_source_tables():
		return _failure("dynamic_source_tables_missing", "The ROM name, position and stat resolver inputs are incomplete.")
	var normalized_rows: Array[PackedByteArray] = []
	for row in _rows:
		var normalized := row.duplicate()
		for i in normalized.size():
			if normalized[i] == 0xE2:
				normalized[i] = 0xE0
			elif normalized[i] == 0xE3:
				normalized[i] = 0xE1
		normalized_rows.append(normalized)
	var packets: Array[Dictionary] = LAYOUT_SCRIPT.build_packets(
		_descriptor, _frame_tiles, normalized_rows,
		Callable(resolver, "resolve_token"))
	if packets.size() != 11:
		return _failure("renderer_packet_derivation_failed", "The decoded descriptor did not produce progress rows 0 through 10.")
	var first_batch: Array[Dictionary] = [packets[0].duplicate(true), packets[1].duplicate(true)]
	if int(first_batch[0].get("progress", -1)) != 0 \
			or int(first_batch[0].get("ppu_address", -1)) != 0x2232 \
			or int(first_batch[1].get("progress", -1)) != 1 \
			or int(first_batch[1].get("ppu_address", -1)) != 0x2252 \
			or not bool(first_batch[0].get("complete", false)) \
			or not bool(first_batch[1].get("complete", false)):
		return _failure("first_batch_incomplete", "The first descriptor batch lacks its complete blank/top-border and E2 player-line packets.")
	return {
		"ok": true,
		"status": "descriptor_1d_first_packet_batch_derived",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_call": {
			"source_pc": 0xD96C,
			"callee_pc": 0xEF7F,
			"descriptor_id": 0x1D,
			"registers": (down_result["registers"] as Dictionary).duplicate(true),
			"stack_pointer": int(boundary["sp"]),
			"scan_y_receipt": scan_y_receipt.duplicate(true),
		},
		"source_scan_record": {
			"player_slot": int(scan_y_receipt.get("player_slot", -1)),
			"record_address": int(scan_y_receipt.get("record_address", -1)),
			"record_bytes": (ram as PackedByteArray).slice(
				int(scan_y_receipt.get("record_address", -1)),
				int(scan_y_receipt.get("record_address", -1)) + PLAYER_RECORD_SIZE),
			"y": int(scan_y_receipt.get("value", -1)),
			"source_read": scan_y_receipt.get("source_read", {}).duplicate(true),
		},
		"live_player_record": {
			"slot": slot,
			"record_address": record_address,
			"record_bytes": ram.slice(record_address, record_address + PLAYER_RECORD_MIN_SIZE),
			"player_id": state.player_id,
			"energy": state.current_energy,
			"level": state.level,
		},
		"dynamic_token_mapping": {
			"E2": "ROM $8A06 reads live $05FC and enters existing E0 position/name resolver $8CDC",
			"E3": "ROM $8A0C reads live $05FC and enters existing E1 stat resolver $8CA5",
		},
		"frame_family": 0,
		"descriptor_progress_packet_count": packets.size(),
		"first_queue_batch_candidates": first_batch,
		"all_packet_candidates": packets.duplicate(true),
		"ppu_effects_applied": false,
		"renderer_worker_executed": false,
		"scheduler_continuation_executed": false,
		"nmi_or_ppu_transfer_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"unresolved": [
			"This presenter constructs the first two ROM-derived packet candidates; it does not execute $EF7F/$800C as 6502.",
			"The queued $04A5 packet wait, bank-$18 $C515 continuation, scheduler/NMI, and actual PPU transfer remain unmodeled.",
		],
	}


func _validate_pending_call(result: Dictionary) -> Dictionary:
	var entry_sp := int(result.get("entry_sp", -1))
	var final_sp := int(result.get("final_sp", -1))
	var expected_final_sp := entry_sp - 4
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "receiver_down_scan_stopped_at_renderer_call" \
			or String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or int(result.get("entry_pc", -1)) != 0xD80F \
			or int(result.get("exit_pc", -1)) != 0xEF7F \
			or entry_sp < 4 or entry_sp > 0xFF \
			or final_sp != expected_final_sp \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)) \
			or bool(result.get("ppu_effects_applied", true)):
		return {"ok": false, "status": "invalid_pending_call", "error": "Presenter requires the receiver executor's unseeded Down result stopped at its descriptor call with two source JSR frames (entry SP minus four)."}
	var requests: Variant = result.get("renderer_requests", [])
	if not requests is Array or requests.size() != 1 or not requests[0] is Dictionary:
		return {"ok": false, "status": "invalid_pending_call", "error": "Exactly one pending renderer request is required."}
	var request: Dictionary = requests[0]
	var result_registers_variant: Variant = result.get("registers", {})
	if not result_registers_variant is Dictionary:
		return {"ok": false, "status": "invalid_pending_call", "error": "The receiver executor omitted the final live CPU registers."}
	var result_registers: Dictionary = result_registers_variant
	var scan_y_receipt := _receiver_scan_y_receipt(result, int(result_registers.get("y", -1)))
	if not bool(scan_y_receipt.get("ok", false)):
		return {"ok": false, "status": "invalid_scan_y_receipt",
			"error": String(scan_y_receipt.get("error", "Receiver scan Y lacks a source read."))}
	var source_y := int(result_registers.get("y", -1))
	var expected_registers := {"a": 0x1D, "x": 0, "y": source_y, "pc": 0xEF7F, "sp": final_sp}
	var call_regs: Variant = request.get("entry_registers", {})
	if not call_regs is Dictionary:
		return {"ok": false, "status": "invalid_pending_call", "error": "The receiver executor omitted live EF7F entry registers."}
	for key: String in expected_registers:
		if int(call_regs.get(key, -1)) != int(expected_registers[key]):
			return {"ok": false, "status": "renderer_entry_register_mismatch", "error": "The $D96C call entry register %s differs from the source receipt." % key}
	if int(request.get("source_pc", -1)) != 0xD96C \
			or int(request.get("callee_pc", -1)) != 0xEF7F \
			or int(request.get("entry_pc", -1)) != 0xEF7F \
			or int(request.get("return_pc", -1)) != 0xD96F \
			or int(request.get("entry_sp", -1)) != final_sp \
			or int(request.get("descriptor_id", -1)) != 0x1D \
			or not bool(request.get("pending", false)) \
			or bool(request.get("ppu_effects_applied", true)):
		return {"ok": false, "status": "invalid_pending_call", "error": "The pending request does not match the ROM $D96C->$EF7F descriptor-$1D JSR boundary."}
	var boundary: Variant = result.get("next_boundary_snapshot", {})
	if not boundary is Dictionary:
		return {"ok": false, "status": "invalid_pending_call", "error": "The receiver executor omitted the output boundary snapshot."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram is PackedByteArray or (ram as PackedByteArray).size() != 0x800 \
			or not stack is PackedByteArray or (stack as PackedByteArray).size() != 0x100 \
			or (ram as PackedByteArray).slice(0x0100, 0x0200) != stack \
			or (ram as PackedByteArray)[0x05FC] != 0x0A \
			or (ram as PackedByteArray)[0x0430] != 1 \
			or (ram as PackedByteArray)[0x0431] != 0x0A \
			or (ram as PackedByteArray)[0x0624] != 0x78 \
			or (ram as PackedByteArray)[0x0441] != 0x06:
		return {"ok": false, "status": "invalid_pending_call_ram", "error": "The live Down scan result does not contain its one slot-$0A candidate/cursor state."}
	var stack_page: PackedByteArray = stack
	if stack_page[final_sp + 1] != 0x6E or stack_page[final_sp + 2] != 0xD9 \
			or stack_page[final_sp + 3] != 0x36 or stack_page[final_sp + 4] != 0xD8:
		return {"ok": false, "status": "invalid_pending_call_stack", "error": "The stack does not preserve both live source JSR frames: `$D96C->$EF7F` at SP+1/+2 and `$D834->$D8F7` at SP+3/+4."}
	var stack_writes_variant: Variant = result.get("source_stack_writes", [])
	if not stack_writes_variant is Array:
		return {"ok": false, "status": "invalid_pending_call_stack", "error": "The Down executor omitted ordered source stack writes for the live JSR proof."}
	var stack_writes: Array = stack_writes_variant
	if stack_writes.size() < 6 \
			or not _source_jsr_stack_write_matches(stack_writes[0], 0xD834, 0xD8F7,
				0x0100 + entry_sp, 0xD8, "jsr_push_high") \
			or not _source_jsr_stack_write_matches(stack_writes[1], 0xD834, 0xD8F7,
				0x0100 + entry_sp - 1, 0x36, "jsr_push_low") \
			or not _source_jsr_stack_write_matches(stack_writes[stack_writes.size() - 2],
				0xD96C, 0xEF7F, 0x0100 + final_sp + 2, 0xD9, "jsr_push_high") \
			or not _source_jsr_stack_write_matches(stack_writes[stack_writes.size() - 1],
				0xD96C, 0xEF7F, 0x0100 + final_sp + 1, 0x6E, "jsr_push_low"):
		return {"ok": false, "status": "invalid_pending_call_stack", "error": "Ordered stack writes do not prove the live `$D834->$D8F7` and `$D96C->$EF7F` JSR frames at the returned SP."}
	if int(boundary.get("pc", -1)) != 0xEF7F or int(boundary.get("sp", -1)) != final_sp \
			or int(boundary.get("a", -1)) != 0x1D \
			or int(boundary.get("y", -1)) != source_y:
		return {"ok": false, "status": "boundary_call_mismatch", "error": "Boundary CPU state differs from its recorded EF7F call request and dynamic stack pointer."}
	return {"ok": true, "scan_y_receipt": scan_y_receipt}


func _receiver_scan_y_receipt(result: Dictionary, source_y: int) -> Dictionary:
	if source_y < 0 or source_y > 0xFF:
		return {"ok": false, "error": "The receiver scan did not supply an 8-bit live Y register."}
	var reads_variant: Variant = result.get("source_reads", [])
	var instruction_pcs_variant: Variant = result.get("source_instruction_pcs", [])
	var ram_variant: Variant = result.get("next_boundary_snapshot", {}).get("ram_image", PackedByteArray())
	if not reads_variant is Array or not instruction_pcs_variant is Array \
			or not ram_variant is PackedByteArray:
		return {"ok": false, "error": "The receiver executor omitted its ordered scan reads/instructions or live RAM."}
	var expected_tail := [0xD949, 0xD94C, 0xD954, 0xD957, 0xD961,
		0xD962, 0xD964, 0xD967, 0xD96A, 0xD96C]
	var instruction_pcs: Array = instruction_pcs_variant
	if instruction_pcs.size() < expected_tail.size():
		return {"ok": false, "error": "The ROM candidate scan did not execute the `$D949->$D96C` renderer call tail."}
	for index in expected_tail.size():
		if int(instruction_pcs[instruction_pcs.size() - expected_tail.size() + index]) \
				!= expected_tail[index]:
			return {"ok": false, "error": "The ROM candidate scan instruction tail differs at `$D949->$D96C`."}
	var ram: PackedByteArray = ram_variant
	var last_y_read: Dictionary = {}
	for read_variant: Variant in reads_variant:
		if read_variant is Dictionary \
				and int((read_variant as Dictionary).get("source_pc", -1)) == 0xD918:
			last_y_read = (read_variant as Dictionary).duplicate(true)
	if last_y_read.is_empty():
		return {"ok": false, "error": "No `$D918` record-Y source read explains the live renderer-entry Y."}
	var read_address := int(last_y_read.get("address", -1))
	var record_address := read_address - 8
	var record_delta := record_address - PLAYER_RECORD_BASE
	if read_address < PLAYER_RECORD_BASE + 8 or read_address >= ram.size() \
			or record_delta < 0 or record_delta % PLAYER_RECORD_SIZE != 0 \
			or record_delta / PLAYER_RECORD_SIZE >= 0x16 \
			or int(last_y_read.get("value", -1)) != source_y \
			or int(ram[read_address]) != source_y:
		return {"ok": false, "error": "The last `$D918` record-Y read does not match the live renderer-entry Y or a player record."}
	var record_slot := int(record_delta / PLAYER_RECORD_SIZE)
	if _record_pointers.size() != 0x2C:
		return {"ok": false, "error": "The ROM record pointer table is unavailable to validate scan Y provenance."}
	var pointer_offset := record_slot * 2
	var pointer_record_address := int(_record_pointers[pointer_offset]) \
		| (int(_record_pointers[pointer_offset + 1]) << 8)
	if pointer_record_address != record_address:
		return {"ok": false, "error": "The final `$D918` Y read does not use the ROM pointer table's player record."}
	return {"ok": true, "player_slot": record_slot,
		"record_address": record_address, "value": source_y,
		"source_read": last_y_read}


func _source_jsr_stack_write_matches(write_variant: Variant, source_pc: int,
		target_pc: int, address: int, value: int, operation: String) -> bool:
	if not write_variant is Dictionary:
		return false
	var write: Dictionary = write_variant
	return int(write.get("source_pc", -1)) == source_pc \
		and int(write.get("target_pc", -1)) == target_pc \
		and int(write.get("address", -1)) == address \
		and int(write.get("value", -1)) == value \
		and String(write.get("operation", "")) == operation


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message,
		"ppu_effects_applied": false, "trace_state_used": false,
		"emulator_data_used": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _token_span_matches(name: String, actual: PackedByteArray) -> bool:
	var expected := PackedByteArray()
	match name:
		"token_dispatch_prefix":
			expected = PackedByteArray([0x38, 0xE9, 0xE0, 0x20, 0x09, 0xC5])
		"token_vector_E0_E3":
			expected = PackedByteArray([0xFA, 0x89, 0x00, 0x8A, 0x06, 0x8A, 0x0C, 0x8A])
		"token_handlers_E0_E3":
			expected = PackedByteArray([
				0xAD, 0x41, 0x04, 0x4C, 0xDC, 0x8C,
				0xAD, 0x41, 0x04, 0x4C, 0xA5, 0x8C,
				0xAD, 0xFC, 0x05, 0x4C, 0xDC, 0x8C,
				0xAD, 0xFC, 0x05, 0x4C, 0xA5, 0x8C,
			])
		"descriptor_style_selector":
			expected = PackedByteArray([
				0x98, 0x29, 0x03, 0xAA, 0x98, 0x4A, 0x4A, 0xA8,
				0xB9, 0xBD, 0xB3, 0xCA, 0x30, 0x05, 0x4A, 0x4A,
				0x4C, 0x69, 0x88, 0x29, 0x03, 0x8D, 0xC6, 0x05,
			])
	return actual == expected
