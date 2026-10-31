extends RefCounted
class_name RomSlot15Map42FirstBatchExecutor
## Resumes the ROM map-$42 worker at $8572 and expands its first three
## metatiles through the source-defined $85C2 queue format.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_8572_85c2.bin"
const WORKER_SHA256 := "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502"
const EXPAND_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_85c2_86d3.bin"
const EXPAND_SHA256 := "1aab318fd595b2cf9f82ed8176340dfe43d4fbdc792e9204ede31c2d21c79e15"
const BLOCK_MAP_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/block_map_42_selector_01.bin"
const BLOCK_MAP_SHA256 := "0a9b49db69d34648c87f480c6eb6c5a015e4880e231f0f46b896391719f4b1ae"
const METATILE_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_14_tiles.bin"
const METATILE_TILES_SHA256 := "374708fff7719dd5979ec875d56cd2286f6d3cf7ec317a3b25632aab28ec37bb"
const METATILE_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_14_attribute.bin"
const METATILE_ATTRIBUTE_SHA256 := "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"
const METATILE_33_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_33_tiles.bin"
const METATILE_33_TILES_SHA256 := "c1b0c2097d76922820e5daf5ca095f8aa1ff51948ee1201dd5fed705fadb58fe"
const METATILE_33_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_33_attribute.bin"
const METATILE_33_ATTRIBUTE_SHA256 := "bceef655b5a034911f1c3718ce056531b45ef03b4c7b1f15629e867294011a7d"
const METATILE_15_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_15_tiles.bin"
const METATILE_15_TILES_SHA256 := "18b013f1362799dbb2a4ee3c0ba84ce6d236b7c82a89793899db4919d3dfab9f"
const METATILE_15_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_15_attribute.bin"
const METATILE_15_ATTRIBUTE_SHA256 := "aa7225e7d5b0a2552bbb58880b3ec00c286995b801a7aeb69281e76a8b4908de"
const METATILE_16_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_16_tiles.bin"
const METATILE_16_TILES_SHA256 := "f396045da5b50769278c8d36c46ec034d65d6776cec27d49d6b15581ea6a4050"
const METATILE_16_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_16_attribute.bin"
const METATILE_16_ATTRIBUTE_SHA256 := "aa7225e7d5b0a2552bbb58880b3ec00c286995b801a7aeb69281e76a8b4908de"
const METATILE_EA_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_EA_tiles.bin"
const METATILE_EA_TILES_SHA256 := "f053daa04e3c5a86cba482abca9fec2aaa68f6ef5048ed9730ea6c8d83ccfd23"
const METATILE_EA_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_EA_attribute.bin"
const METATILE_EA_ATTRIBUTE_SHA256 := "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89"
const METATILE_EB_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_EB_tiles.bin"
const METATILE_EB_TILES_SHA256 := "a2d2d606a7c02d92acce0f45be5610ef4163d77ac44ba18f33541aa074df431a"
const METATILE_EB_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_42_metatile_EB_attribute.bin"
const METATILE_EB_ATTRIBUTE_SHA256 := "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89"
const P_N := 0x80
const P_Z := 0x02
const P_C := 0x01
const P_NZ := P_N | P_Z
const QUEUE_BASE := 0x04A5

var error_message := ""


func execute_resumed_worker(dispatch: Dictionary, selected_boundary: Dictionary) -> Dictionary:
	error_message = ""
	var sources := _load_sources()
	if not bool(sources.get("ok", false)):
		return _failure(String(sources.get("error", "Map-$42 batch source load failed.")))
	var registers_variant: Variant = dispatch.get("registers", {})
	var ram_variant: Variant = selected_boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = selected_boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = selected_boundary.get("mapper", {})
	if not registers_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not mapper_variant is Dictionary:
		return _failure("Resumed map worker omits CPU, mapper, RAM, or stack state.")
	var cpu: Dictionary = registers_variant.duplicate(true)
	cpu["p"] = int(selected_boundary.get("p", cpu.get("p", 0x20)))
	cpu["p_known_mask"] = int(selected_boundary.get("p_known_mask", cpu.get("p_known_mask", P_NZ)))
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var mapper: Dictionary = mapper_variant.duplicate(true)
	if String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("slot_base", -1)) != 0x15 \
			or int(cpu.get("pc", -1)) != 0x8572 \
			or int(cpu.get("sp", -1)) != 0xED \
			or int(mapper.get("bank_low", -1)) != 0x0B \
			or not int(mapper.get("bank_high", -1)) in [0x0C, 0x12] \
			or ram.size() != 0x800 or stack.size() != 0x100:
		return _failure("Input is not the scheduler-restored slot-$15 continuation at `$8572`: path=%s slot=$%02X PC=$%04X A/X/Y/SP=$%02X/$%02X/$%02X/$%02X mapper=$%02X/$%02X RAM/stack=%d/%d." % [
			String(dispatch.get("resume_path", "")), int(dispatch.get("slot_base", -1)),
			int(cpu.get("pc", -1)), int(cpu.get("a", -1)), int(cpu.get("x", -1)),
			int(cpu.get("y", -1)), int(cpu.get("sp", -1)), int(mapper.get("bank_low", -1)),
			int(mapper.get("bank_high", -1)), ram.size(), stack.size()])
	if int(ram[0x0000]) != 0x15 or int(ram[0x0515]) != 0 \
			or int(ram[0x05C7]) not in [0, 0x36, 0x40, 0x60] \
			or int(ram[0x05CA]) != 1 \
			or int(ram[0x05CC]) != 0x42 \
			or (int(ram[0x0054]) | (int(ram[0x0055]) << 8)) != 0x93A4 \
			or int(stack[0xEE]) != 0x01:
		return _failure("Live slot-$15 batch input mismatch: current=%02X, busy=%02X, queue=%02X, placement=%02X, selector=%02X, map=%02X, pointer=%04X, stack[$EE]=%02X." % [
			int(ram[0x0000]), int(ram[0x0515]), int(ram[0x05C7]), int(ram[0x05C8]),
			int(ram[0x05CA]), int(ram[0x05CC]),
			int(ram[0x0054]) | (int(ram[0x0055]) << 8), int(stack[0xEE])])
	var source: Dictionary = sources["source"]
	var block_map: PackedByteArray = source["block_map"]
	var row_remaining := int(ram[0x05C9])
	var placement := int(ram[0x05C8])
	var placement_start := placement
	var map_start_index := 0x20 - row_remaining
	var entry_record: PackedByteArray = selected_boundary.get("record", PackedByteArray())
	var first_route_cursor := (int(ram[0x05C7]) == 0 and placement == 0) \
			or (int(ram[0x05C7]) == 0x40 and placement == 0xA0)
	var first_batch := map_start_index == 0 and first_route_cursor and row_remaining == 0x20 \
			and int(mapper.get("bank_high", -1)) == 0x0C \
			and int(cpu.get("a", -1)) == 0x08 and int(cpu.get("x", -1)) == 0x08 \
			and entry_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C])
	var continuation_placement := placement == map_start_index \
			or placement == 0xA0 + map_start_index
	var prior_batch_state := _expected_previous_batch_state(map_start_index, placement)
	var continuation_batch := map_start_index in [3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			and continuation_placement and row_remaining == 0x20 - map_start_index \
			and int(ram[0x05C7]) == int(prior_batch_state.get("queue_bytes", -1)) \
			and int(mapper.get("bank_high", -1)) == 0x12 \
			and int(cpu.get("a", -1)) == int(prior_batch_state.get("queue_bytes", -1)) \
			and int(cpu.get("x", -1)) == int(prior_batch_state.get("queue_bytes", -1)) \
			and int(cpu.get("y", -1)) == int(prior_batch_state.get("return_y", -1)) \
			and entry_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x12])
	var expected_batch := _expected_batch_metatiles(map_start_index)
	var batch_cell_count := mini(3, row_remaining)
	if block_map.size() != 0x20 or not (first_batch or continuation_batch) \
			or expected_batch.size() != batch_cell_count or batch_cell_count <= 0 \
			or block_map.slice(map_start_index, map_start_index + batch_cell_count) != expected_batch:
		return _failure("Live map-$42 cursors do not select a checked source-sized ROM batch: start=%d placement=$%02X remaining=$%02X cursor=$%02X prior=%s regs=$%02X/$%02X/$%02X mapper=$%02X/$%02X record=%s cells=%d expected=%s source=%s." % [
			map_start_index, placement, row_remaining, int(ram[0x05C7]), str(prior_batch_state),
			int(cpu.get("a", -1)), int(cpu.get("x", -1)), int(cpu.get("y", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			entry_record.hex_encode(), batch_cell_count, expected_batch.hex_encode(),
			block_map.slice(map_start_index, map_start_index + batch_cell_count).hex_encode()])

	var entry_registers := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var ram_writes: Array[Dictionary] = []
	var calls: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var queue := PackedByteArray()
	var write_index := 0
	var result_y := 0x10
	var loop_remaining := batch_cell_count

	# `$8572` polls the active NMI queue before it starts a row batch.
	if (int(ram[0x0515]) & 0xFF) != 0:
		return _failure("The `$8572` queue-busy branch is not the cleared-queue path being traced.")
	_write(ram, ram_writes, 0x0515, 0x01, 0x8577, "map_batch_busy")
	_write(ram, ram_writes, 0x05C7, 0x00, 0x857C, "map_queue_offset_reset")
	var selector := _stack_pop(stack, int(cpu["sp"]))
	cpu["sp"] = (int(cpu["sp"]) + 1) & 0xFF
	if selector != 0x01:
		return _failure("The saved map selector is not ROM-derived selector `$01`.")
	_write(ram, ram_writes, 0x05CA, selector, 0x8585, "map_selector_restore")
	stack[int(cpu["sp"])] = selector
	cpu["sp"] = (int(cpu["sp"]) - 1) & 0xFF

	for block_index in range(batch_cell_count):
		var map_index := 0x20 - row_remaining
		if map_index < 0 or map_index >= block_map.size():
			return _failure("The source map row index %d is outside the decoded map." % map_index)
		var block_id := int(block_map[map_index])
		var first_ppu_address := _tile_address(placement)
		var metatile_key := "%02X" % block_id
		if not source.has("tiles_" + metatile_key) or not source.has("attribute_" + metatile_key):
			return _failure("Map-$42 metatile `$%02X` is not covered by the current source-bound batch." % block_id)
		var metatile_tiles: PackedByteArray = source["tiles_" + metatile_key]
		var metatile_attribute := int(source["attribute_" + metatile_key][0])
		var mapper_select_value := (int(ram[0x0022]) | 0x07) & 0xFF
		_write(ram, ram_writes, 0x0023, mapper_select_value, 0x8682, "mapper_select_shadow")
		mapper_writes.append({"pc": 0x8682, "address": 0x8000,
			"value": mapper_select_value, "select": mapper_select_value & 0x07,
			"kind": "register_select"})
		var tile_bank := _selected_metatile_bank(selector, block_id)
		_write(ram, ram_writes, 0x0025, tile_bank, 0x8688, "mapper_chr_bank_shadow")
		var bank_registers: Dictionary = mapper.get("bank_registers", {}).duplicate(true)
		bank_registers[mapper_select_value & 0x07] = tile_bank
		mapper["bank_registers"] = bank_registers
		mapper["select"] = mapper_select_value & 0x07
		mapper["bank_high"] = tile_bank
		mapper_writes.append({"pc": 0x8688, "address": 0x8001,
			"value": tile_bank, "select": mapper_select_value & 0x07,
			"kind": "register_data"})
		var group := _build_metatile_packet_group(placement, metatile_tiles, metatile_attribute)
		if group.size() != 0x20:
			return _failure("`$85C2` did not produce one 32-byte metatile packet group.")
		for byte_index in group.size():
			var address := QUEUE_BASE + write_index + byte_index
			ram[address] = group[byte_index]
			ram_writes.append({"pc": 0x85C2, "address": address,
				"value": int(group[byte_index]), "kind": "metatile_packet_byte"})
		var source_terminator := QUEUE_BASE + write_index + 0x20
		ram[source_terminator] = 0
		ram_writes.append({"pc": 0x86AC, "address": source_terminator,
			"value": 0, "kind": "metatile_queue_terminator"})
		var row_wrap_compaction := (placement & 0x3F) >= 0x38
		var advance_length := 0x20
		result_y = 0x10
		if row_wrap_compaction:
			advance_length = 0x12
			result_y = write_index + 0x05
			for compact_index in range(5):
				var source_address := QUEUE_BASE + write_index + 0x1C + compact_index
				var destination_address := QUEUE_BASE + write_index + 0x0E + compact_index
				var copied_value := int(ram[source_address])
				ram[destination_address] = copied_value
				ram_writes.append({"pc": 0x86C8, "address": destination_address,
					"value": copied_value, "kind": "row_wrap_attribute_compaction"})
		var next_offset := (write_index + advance_length) & 0xFF
		_write(ram, ram_writes, 0x05C7, next_offset, 0x8597, "map_queue_offset_advance")
		_write(ram, ram_writes, 0x05C8, (placement + 1) & 0xFF, 0x859A, "map_placement_advance")
		var next_row_remaining := (row_remaining - 1) & 0xFF
		_write(ram, ram_writes, 0x05C9, next_row_remaining, 0x859D, "map_row_count_decrement")
		calls.append({"pc": 0x8592, "target": 0x85C2, "map_index": map_index,
			"block_id": block_id, "selector": selector, "placement": placement,
			"queue_offset": write_index, "queue_advance_bytes": advance_length,
			"row_wrap_compaction": row_wrap_compaction, "return_y": result_y,
			"ppu_address": first_ppu_address,
			"tile_source_sha256": _metatile_tiles_sha256(block_id),
			"attribute_source_sha256": _metatile_attribute_sha256(block_id),
			"expanded_queue_bytes": group.duplicate()})
		write_index = next_offset
		placement = (placement + 1) & 0xFF
		row_remaining = next_row_remaining
		loop_remaining -= 1

	if loop_remaining != 0:
		return _failure("The `$8572` worker did not complete the source-selected batch count.")
	# `$86AC` writes the terminator, and `$86C8` relocates it when the
	# metatile crosses the nametable row boundary at placement `$38-$3F`.
	var terminator_address := QUEUE_BASE + write_index
	if int(ram[terminator_address]) != 0:
		return _failure("`$85C2` did not leave its terminator at the returned queue cursor.")
	queue = ram.slice(QUEUE_BASE, terminator_address)
	_write(ram, ram_writes, 0x0515, 0x80, 0x85B0, "map_batch_ready")
	var carry_status := ((int(cpu.get("p", 0x20)) & ~(P_NZ | P_C)) | 0x20 | P_C) & 0xFF
	var callsite_pc := 0x85BE if row_remaining == 0 else 0x856F
	var callsite_sp := 0xEE if row_remaining == 0 else 0xED
	cpu["a"] = 0x01
	cpu["x"] = write_index
	cpu["y"] = result_y
	cpu["sp"] = callsite_sp
	cpu["p"] = carry_status
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ | P_C
	cpu["pc"] = callsite_pc
	if int(ram[0x05C7]) != write_index \
			or int(ram[0x05C8]) != ((placement_start + batch_cell_count) & 0xFF) \
			or int(ram[0x05C9]) != 0x20 - map_start_index - batch_cell_count \
			or int(ram[0x0515]) != 0x80 \
			or int(cpu["x"]) != write_index or int(cpu["y"]) != result_y:
		return _failure("The `$8572->$85C2` loop output differs from its ROM-derived write contract.")
	for stack_offset in stack.size():
		ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "map42_%d_metatiles_ready_at_yield" % batch_cell_count,
		"rom_sha256": ROM_SHA256,
		"entry_pc": 0x8572,
		"exit_pc": callsite_pc,
		"callsite_pc": callsite_pc,
		"map_exhausted_branch": row_remaining == 0,
		"entry_registers": entry_registers,
		"registers": cpu,
		"mapper": mapper,
		"mapper_writes": mapper_writes,
		"entry_ram_image": entry_ram,
		"updated_ram": ram,
		"entry_stack_page": entry_stack,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"map_calls": calls,
		"queue_bytes": queue,
		"queue_start_address": QUEUE_BASE,
		"queue_terminator_address": terminator_address,
		"row_count_remaining": row_remaining,
		"next_map_index": 0x20 - row_remaining,
		"batch_start_map_index": map_start_index,
		"batch_cell_count": batch_cell_count,
		"batch_start_placement": placement_start,
		"batch_queue_byte_count": write_index,
		"last_metatile_return_y": result_y,
		"batch_kind": "initial" if first_batch else "continuation_%02d" % int(map_start_index / 3),
		"source_hashes": {
			"worker_8572_85c2": WORKER_SHA256,
			"metatile_expand_85c2_86d3": EXPAND_SHA256,
			"block_map_42": BLOCK_MAP_SHA256,
			"metatile_14_tiles": METATILE_TILES_SHA256,
			"metatile_14_attribute": METATILE_ATTRIBUTE_SHA256,
			"metatile_33_tiles": METATILE_33_TILES_SHA256,
			"metatile_33_attribute": METATILE_33_ATTRIBUTE_SHA256,
			"metatile_15_tiles": METATILE_15_TILES_SHA256,
			"metatile_15_attribute": METATILE_15_ATTRIBUTE_SHA256,
			"metatile_16_tiles": METATILE_16_TILES_SHA256,
			"metatile_16_attribute": METATILE_16_ATTRIBUTE_SHA256,
			"metatile_EA_tiles": METATILE_EA_TILES_SHA256,
			"metatile_EA_attribute": METATILE_EA_ATTRIBUTE_SHA256,
			"metatile_EB_tiles": METATILE_EB_TILES_SHA256,
			"metatile_EB_attribute": METATILE_EB_ATTRIBUTE_SHA256,
		},
		"trace_state_used": false,
		"temporary_stack_writes_modeled": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"source_cycle_timing_modeled": false,
	}


func _expected_previous_batch_state(map_start_index: int, current_placement: int) -> Dictionary:
	if map_start_index < 3:
		return {"queue_bytes": -1, "return_y": -1}
	var previous_map_start := map_start_index - 3
	var high_page_route := current_placement >= 0xA0
	var placement := 0xA0 + previous_map_start if high_page_route else previous_map_start
	var queue_bytes := 0
	var return_y := 0x10
	for _cell_index in range(3):
		if (placement & 0x3F) >= 0x38:
			return_y = queue_bytes + 0x05
			queue_bytes += 0x12
		else:
			queue_bytes += 0x20
			return_y = 0x10
		placement = (placement + 1) & 0xFF
	return {"queue_bytes": queue_bytes, "return_y": return_y}


func _load_sources() -> Dictionary:
	var specs := {
		"worker": [WORKER_PATH, WORKER_SHA256, 0x50],
		"expand": [EXPAND_PATH, EXPAND_SHA256, 0x111],
		"block_map": [BLOCK_MAP_PATH, BLOCK_MAP_SHA256, 0x20],
		"tiles_14": [METATILE_TILES_PATH, METATILE_TILES_SHA256, 0x10],
		"attribute_14": [METATILE_ATTRIBUTE_PATH, METATILE_ATTRIBUTE_SHA256, 0x01],
		"tiles_33": [METATILE_33_TILES_PATH, METATILE_33_TILES_SHA256, 0x10],
		"attribute_33": [METATILE_33_ATTRIBUTE_PATH, METATILE_33_ATTRIBUTE_SHA256, 0x01],
		"tiles_15": [METATILE_15_TILES_PATH, METATILE_15_TILES_SHA256, 0x10],
		"attribute_15": [METATILE_15_ATTRIBUTE_PATH, METATILE_15_ATTRIBUTE_SHA256, 0x01],
		"tiles_16": [METATILE_16_TILES_PATH, METATILE_16_TILES_SHA256, 0x10],
		"attribute_16": [METATILE_16_ATTRIBUTE_PATH, METATILE_16_ATTRIBUTE_SHA256, 0x01],
		"tiles_EA": [METATILE_EA_TILES_PATH, METATILE_EA_TILES_SHA256, 0x10],
		"attribute_EA": [METATILE_EA_ATTRIBUTE_PATH, METATILE_EA_ATTRIBUTE_SHA256, 0x01],
		"tiles_EB": [METATILE_EB_TILES_PATH, METATILE_EB_TILES_SHA256, 0x10],
		"attribute_EB": [METATILE_EB_ATTRIBUTE_PATH, METATILE_EB_ATTRIBUTE_SHA256, 0x01],
	}
	var source: Dictionary = {}
	for key: String in specs:
		var spec: Array = specs[key]
		var path := String(spec[0])
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(spec[2]) or FileAccess.get_sha256(path) != String(spec[1]):
			return {"ok": false, "error": "Map-$42 source failed size/hash validation: %s" % path}
		source[key] = bytes
	var worker: PackedByteArray = source["worker"]
	var expand: PackedByteArray = source["expand"]
	if worker.slice(0, 5) != PackedByteArray([0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
			or worker.slice(0x28, 0x2B) != PackedByteArray([0x20, 0xC2, 0x85]) \
			or worker.slice(0x4C, 0x50) != PackedByteArray([0x20, 0x15, 0xC5, 0x60]) \
			or expand.slice(0, 10) != PackedByteArray([0x85, 0x56, 0x98, 0x29, 0x07,
				0x0A, 0x0A, 0x9D, 0xA6, 0x04]) \
			or expand.slice(0x10E, 0x111) != PackedByteArray([0xD0, 0xF2, 0x60]):
		return {"ok": false, "error": "Map-$42 worker spans do not contain the decoded source path."}
	return {"ok": true, "source": source}


func _build_metatile_packet_group(placement: int, tiles: PackedByteArray,
		attribute: int) -> PackedByteArray:
	var packets := PackedByteArray()
	var base_address := _tile_address(placement)
	for row in range(4):
		var address := (base_address + row * 0x20) & 0x3FFF
		packets.append(0x04)
		packets.append(address & 0xFF)
		packets.append((address >> 8) & 0xFF)
		for column in range(4):
			packets.append(int(tiles[row * 4 + column]))
	var attribute_address := 0x23C0 | (placement & 0x3F) | ((placement & 0xC0) << 4)
	packets.append(0x01)
	packets.append(attribute_address & 0xFF)
	packets.append((attribute_address >> 8) & 0xFF)
	packets.append(attribute & 0xFF)
	return packets


func _tile_address(placement: int) -> int:
	return 0x2000 | ((placement & 0x38) << 4) \
			| ((placement & 0xC0) << 4) | ((placement & 0x07) << 2)


func _expected_batch_metatiles(start_index: int) -> PackedByteArray:
	if start_index in [0, 3, 24, 27]:
		return PackedByteArray([0x14, 0x14, 0x14])
	if start_index == 6:
		return PackedByteArray([0x14, 0x14, 0x33])
	if start_index in [9, 12]:
		return PackedByteArray([0x33, 0x33, 0x33])
	if start_index == 15:
		return PackedByteArray([0x33, 0x15, 0x16])
	if start_index == 18:
		return PackedByteArray([0x15, 0xEA, 0xEB])
	if start_index == 21:
		return PackedByteArray([0x16, 0x15, 0x16])
	if start_index == 30:
		return PackedByteArray([0x14, 0x14])
	return PackedByteArray()


func _metatile_tiles_sha256(block_id: int) -> String:
	match block_id:
		0x14: return METATILE_TILES_SHA256
		0x15: return METATILE_15_TILES_SHA256
		0x16: return METATILE_16_TILES_SHA256
		0x33: return METATILE_33_TILES_SHA256
		0xEA: return METATILE_EA_TILES_SHA256
		0xEB: return METATILE_EB_TILES_SHA256
	return ""


func _metatile_attribute_sha256(block_id: int) -> String:
	match block_id:
		0x14: return METATILE_ATTRIBUTE_SHA256
		0x15: return METATILE_15_ATTRIBUTE_SHA256
		0x16: return METATILE_16_ATTRIBUTE_SHA256
		0x33: return METATILE_33_ATTRIBUTE_SHA256
		0xEA: return METATILE_EA_ATTRIBUTE_SHA256
		0xEB: return METATILE_EB_ATTRIBUTE_SHA256
	return ""


func _selected_metatile_bank(selector: int, metatile_id: int) -> int:
	var window_offset := (selector << 12) + (metatile_id << 4)
	return 0x12 + (window_offset >> 13)


func _write(ram: PackedByteArray, writes: Array[Dictionary], address: int,
		value: int, pc: int, kind: String) -> void:
	ram[address] = value & 0xFF
	writes.append({"pc": pc, "address": address, "value": value & 0xFF, "kind": kind})


func _stack_pop(stack: PackedByteArray, sp: int) -> int:
	return int(stack[(sp + 1) & 0xFF])


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}
