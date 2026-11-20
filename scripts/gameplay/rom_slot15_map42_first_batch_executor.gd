extends RefCounted
class_name RomSlot15MapBatchExecutor
## Resumes the ROM slot-$15 map worker at $8572 and expands up to three
## metatiles through the source-defined $85C2 queue format.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_8572_85c2.bin"
const WORKER_SHA256 := "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502"
const EXPAND_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_85c2_86d3.bin"
const EXPAND_SHA256 := "1aab318fd595b2cf9f82ed8176340dfe43d4fbdc792e9204ede31c2d21c79e15"
const BLOCK_MAP_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/block_map_42_selector_01.bin"
const BLOCK_MAP_SHA256 := "0a9b49db69d34648c87f480c6eb6c5a015e4880e231f0f46b896391719f4b1ae"
const BLOCK_MAP_43_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/block_map_43_selector_01.bin"
const BLOCK_MAP_43_SHA256 := "73a85c2003d994fb328f127f4fcacaf874b1b270eca192853096f43e47b860d5"
const BLOCK_MAP_52_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/block_map_52_selector_00.bin"
const BLOCK_MAP_52_SHA256 := "4dcc97a7c5b8b591620207eb28662ac78ce6046fe2a6931d0d401b99de7322a9"
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
const MAP00_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/manifest.json"
const MAP00_MANIFEST_SHA256 := "fe247c34a0f2d7b8fb158a7abaed3c1cd6c3e0f14e728b72cdf842ab8749b272"
const METATILE_2F_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_2F_tiles.bin"
const METATILE_2F_TILES_SHA256 := "6387d6d34896ed53b64f2f1a96752f4154cf42b98c318b0c7332b6f7e313d5d1"
const METATILE_2F_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_2F_attribute.bin"
const METATILE_2F_ATTRIBUTE_SHA256 := "bceef655b5a034911f1c3718ce056531b45ef03b4c7b1f15629e867294011a7d"
const METATILE_ED_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_ED_tiles.bin"
const METATILE_ED_TILES_SHA256 := "ad46c0674e7055c03784fcfa4a019711d769523d7f04e9056c945f4d0fc43d75"
const METATILE_ED_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_ED_attribute.bin"
const METATILE_ED_ATTRIBUTE_SHA256 := "1dd8312636f6a0bf3d21fa2855e63072507453e93a5ced4301b364e91c9d87d6"
const METATILE_34_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_34_tiles.bin"
const METATILE_34_TILES_SHA256 := "7395ac315f396bba3b04405a38b8727d3a78d8d6988f2db5b65472ad18577206"
const METATILE_34_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_34_attribute.bin"
const METATILE_34_ATTRIBUTE_SHA256 := "4d4d75d742863ab9656f3d5f76dff8589c3922e95a24ea6812157ffe4aaa3b6b"
const METATILE_EC_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_EC_tiles.bin"
const METATILE_EC_TILES_SHA256 := "4e888b1b0fa283cbd5ea9d63bf1392f0d52cc124e6281cea9745e7de9ff83b1b"
const METATILE_EC_ATTRIBUTE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_43_metatile_EC_attribute.bin"
const METATILE_EC_ATTRIBUTE_SHA256 := "bceef655b5a034911f1c3718ce056531b45ef03b4c7b1f15629e867294011a7d"
const MAP52_METATILE_49_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_49_tiles.bin"
const MAP52_METATILE_49_TILES_SHA256 := "aecde50b7b8f676e52012e9b4ba2391f3045fb26027271668e6a6304e6b7ef2a"
const MAP52_METATILE_4A_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_4A_tiles.bin"
const MAP52_METATILE_4A_TILES_SHA256 := "924f1e67290a2a8ea1b459c45c689f7ad4cf448ea17993f8df5cebafc083bd18"
const MAP52_METATILE_4B_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_4B_tiles.bin"
const MAP52_METATILE_4B_TILES_SHA256 := "d26620620cc6fed2f13b9882b6972778c2601af6b5ef2967dd9febdc898a2143"
const MAP52_METATILE_C3_TILES_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_C3_tiles.bin"
const MAP52_METATILE_C3_TILES_SHA256 := "cc8cd41cef907c4d216069122c4b89936211361f9050a717a1e37ad1862e952f"
const MAP52_METATILE_ATTRIBUTE_SHA256 := "bceef655b5a034911f1c3718ce056531b45ef03b4c7b1f15629e867294011a7d"
const P_N := 0x80
const P_Z := 0x02
const P_C := 0x01
const P_NZ := P_N | P_Z
const QUEUE_BASE := 0x04A5
const MAP2D_ROOT := "res://reference/rom_extract/gameplay/slot15_callback_34/"
const MAP2D_METATILE_ROOT := MAP2D_ROOT + "map_2d_metatiles/"
const MAP2D_MANIFEST_PATH := MAP2D_METATILE_ROOT + "manifest.json"
const MAP2D_MANIFEST_SHA256 := "66f9b2ae9e60936d5bda78053ae9d62718c77da108aef3e82a9cefff453457b1"
const MAP2D_BLOCK_PATH := MAP2D_ROOT + "map_2d_block.bin"
const MAP2D_BLOCK_SHA256 := "5f2a7c9e9b42fa9860e062f8df1ee57caf1d255424d85ff884c6158f1cf8e1e9"
const MAP11_ROOT := "res://reference/rom_extract/gameplay/first_command_field/map_11/"
const MAP11_MANIFEST_PATH := MAP11_ROOT + "manifest.json"
const MAP11_MANIFEST_SHA256 := "35ad00dd6033ec33ad570739f338049ed3e49dfe68b56ab6a30b90ee9e4216d0"
const MAP11_BLOCK_SHA256 := "00b40472a12e882b278e94802d5c7c4739e0c69ed10059afdec73f49e57a2a82"
const MAP12_ROOT := "res://reference/rom_extract/gameplay/first_command_field/map_12/"
const MAP12_MANIFEST_PATH := MAP12_ROOT + "manifest.json"
const MAP12_MANIFEST_SHA256 := "547ad4e99add77cdcc29ae962b554be01914fe25d1be2a0563a7a80ff496f19f"
const MAP12_BLOCK_SHA256 := "a213277a16e544e49e47861d13a8e3c9d81a4cc0fa2005168522927e35357d5d"
const MAP51_ROOT := "res://reference/rom_extract/gameplay/first_command_field/map_51/"
const MAP51_MANIFEST_PATH := MAP51_ROOT + "manifest.json"
const MAP51_MANIFEST_SHA256 := "e432c90a40abbe701ef5b0402a897896e78639d3f04176e729f02564e5320ad7"
const MAP51_BLOCK_SHA256 := "e50fe70791780eb4d4504cbd55552131bf503422a69378ebfc14abe84b830918"
const MAP2F_ROOT := "res://reference/rom_extract/gameplay/first_command_field/map_2f_resume/"
const MAP2F_MANIFEST_PATH := MAP2F_ROOT + "manifest.json"
const MAP2F_MANIFEST_SHA256 := "0256e72af241982893680800cba4017818cf1323874f9db0a04192d986e991ac"
const MAP2F_BLOCK_MAP_SHA256 := "e95e3366fb5c90d12a136b2f7bd77a3ab36be9bc6f05f8c7ea9c06812da4157e"
const MAP2F_FIRST_BATCH_IDS_SHA256 := "89da97f620858fd7271e54cb6c00e4386d7ed3bb7401687b4ee7a4efda2f0d92"
const MAP2F_FIRST_BATCH_RECORDS_SHA256 := "78fad2eb9e6a59b793250275f378cd60de12f72d7fcd09d9f75f5e859450b6a8"

var error_message := ""


func execute_resumed_worker(dispatch: Dictionary, selected_boundary: Dictionary) -> Dictionary:
	error_message = ""
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
	var map_id := int(ram[0x05CC]) if ram.size() == 0x800 else -1
	if map_id not in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x42, 0x43, 0x51, 0x52, 0x56]:
		return _failure("The resumed map worker does not carry a supported map ID.")
	var sources := _load_sources(map_id)
	if not bool(sources.get("ok", false)):
		return _failure(String(sources.get("error", "Map batch source load failed.")))
	var expected_map_data_pointer := 0x8B64 + ((map_id >> 3) << 8) + ((map_id & 0x07) << 5)
	var expected_selector := 0x02 if map_id in [0x2D, 0x56] else (0x00 if map_id in [0x00, 0x0E, 0x11, 0x12, 0x51, 0x52] else 0x01)
	var expected_entry_sp := 0xED
	var resume_path := String(dispatch.get("resume_path", ""))
	var active_nmi_return := resume_path == "active_nmi_return"
	if resume_path not in ["yielded_rts", "active_nmi_return"] \
			or int(dispatch.get("slot_base", -1)) != 0x15 \
			or int(cpu.get("pc", -1)) != 0x8572 \
			or int(cpu.get("sp", -1)) != expected_entry_sp \
			or (active_nmi_return and not bool(dispatch.get("external_nmi_return_observed", false))) \
			or (not active_nmi_return and bool(dispatch.get("external_nmi_return_observed", false))) \
			or int(mapper.get("bank_low", -1)) != 0x0B \
			or not int(mapper.get("bank_high", -1)) in [0x0C, 0x12, 0x13] \
			or ram.size() != 0x800 or stack.size() != 0x100:
		return _failure("Input is not the scheduler-restored slot-$15 continuation at `$8572`: path=%s slot=$%02X PC=$%04X A/X/Y/SP=$%02X/$%02X/$%02X/$%02X mapper=$%02X/$%02X RAM/stack=%d/%d." % [
			String(dispatch.get("resume_path", "")), int(dispatch.get("slot_base", -1)),
			int(cpu.get("pc", -1)), int(cpu.get("a", -1)), int(cpu.get("x", -1)),
			int(cpu.get("y", -1)), int(cpu.get("sp", -1)), int(mapper.get("bank_low", -1)),
			int(mapper.get("bank_high", -1)), ram.size(), stack.size()])
	var selector_stack_index := (expected_entry_sp + 1) & 0xFF
	if int(ram[0x0000]) != 0x15 \
			or int(ram[0x05C7]) not in [0, 0x24, 0x36, 0x40, 0x60] \
			or int(ram[0x05CA]) != expected_selector \
			or (int(ram[0x0054]) | (int(ram[0x0055]) << 8)) != expected_map_data_pointer \
			or int(stack[selector_stack_index]) != expected_selector:
		return _failure("Live slot-$15 map-$%02X batch input mismatch: current=%02X, busy=%02X, queue=%02X, placement=%02X, selector=%02X, map=%02X, pointer=%04X, stack[$%02X]=%02X." % [
			map_id,
			int(ram[0x0000]), int(ram[0x0515]), int(ram[0x05C7]), int(ram[0x05C8]),
			int(ram[0x05CA]), int(ram[0x05CC]),
			int(ram[0x0054]) | (int(ram[0x0055]) << 8), (expected_entry_sp + 1) & 0xFF,
			int(stack[(expected_entry_sp + 1) & 0xFF])])
	var source: Dictionary = sources["source"]
	var block_map: PackedByteArray = source["block_map"]
	var row_remaining := int(ram[0x05C9])
	var placement := int(ram[0x05C8])
	var placement_start := placement
	var map_start_index := 0x20 - row_remaining
	var entry_record: PackedByteArray = selected_boundary.get("record", PackedByteArray())
	var first_route_cursor := ((map_id in [0x00, 0x0E, 0x11, 0x12, 0x2F] and int(ram[0x05C7]) == 0x40 and placement == 0xA0) \
			or (map_id == 0x42 and int(ram[0x05C7]) == 0 and placement == 0) \
			or (map_id == 0x42 and int(ram[0x05C7]) == 0x40 and placement == 0xA0) \
			or (map_id in [0x2D, 0x36, 0x43, 0x52] and int(ram[0x05C7]) == 0x24 and placement == 0x80) \
			or (map_id == 0x51 and int(ram[0x05C7]) == 0x40 and placement == 0xA0) \
			or (map_id in [0x52, 0x56] and int(ram[0x05C7]) == 0x40 and placement == 0xA0))
	var first_batch := map_start_index == 0 and first_route_cursor and row_remaining == 0x20 \
			and int(mapper.get("bank_high", -1)) == 0x0C \
			and entry_record == PackedByteArray([0x00, 0xE9, 0x0B, 0x0C])
	var continuation_placement := (map_id in [0x00, 0x0E, 0x11, 0x12, 0x2F] and placement == 0xA0 + map_start_index) \
			or (map_id == 0x42 and (placement == map_start_index \
			or placement == 0xA0 + map_start_index)) \
		or (map_id in [0x2D, 0x36, 0x43] and placement == 0x80 + map_start_index) \
		or (map_id == 0x51 and placement == 0xA0 + map_start_index) \
		or (map_id in [0x52, 0x56] and placement in [0x80 + map_start_index,
			0xA0 + map_start_index])
	var prior_batch_state := _expected_previous_batch_state(map_id, map_start_index, placement)
	var expected_continuation_record := PackedByteArray([0x00, 0xE9, 0x0B, 0x13]) \
		if map_id in [0x2D, 0x56] else PackedByteArray([0x00, 0xE9, 0x0B, 0x12])
	var continuation_batch := map_start_index in [3, 6, 9, 12, 15, 18, 21, 24, 27, 30] \
			and continuation_placement and row_remaining == 0x20 - map_start_index \
			and int(ram[0x05C7]) == int(prior_batch_state.get("queue_bytes", -1)) \
			and int(mapper.get("bank_high", -1)) == (0x13 if map_id in [0x2D, 0x56] else 0x12) \
			and int(cpu.get("a", -1)) == int(prior_batch_state.get("queue_bytes", -1)) \
			and int(cpu.get("x", -1)) == int(prior_batch_state.get("queue_bytes", -1)) \
			and int(cpu.get("y", -1)) == int(prior_batch_state.get("return_y", -1)) \
			and entry_record == expected_continuation_record
	var batch_cell_count := mini(3, row_remaining)
	var expected_batch := _expected_batch_metatiles(map_id, map_start_index)
	if map_id in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x51, 0x52, 0x56]:
		expected_batch = block_map.slice(map_start_index, map_start_index + batch_cell_count)
	if block_map.size() != 0x20 or not (first_batch or continuation_batch) \
			or expected_batch.size() != batch_cell_count or batch_cell_count <= 0 \
			or block_map.slice(map_start_index, map_start_index + batch_cell_count) != expected_batch:
		return _failure("Live map-$%02X cursors do not select a checked source-sized ROM batch: start=%d placement=$%02X remaining=$%02X cursor=$%02X prior=%s regs=$%02X/$%02X/$%02X mapper=$%02X/$%02X record=%s cells=%d expected=%s source=%s." % [
			map_id,
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
	var map00_hashes: Dictionary = source.get("source_hashes", {})
	var queue := PackedByteArray()
	var write_index := 0
	var result_y := 0x10
	var loop_remaining := batch_cell_count

	# The ROM branch is `LDA $0515 / BNE $856D / LDA #$01`, where `$856D`
	# calls `$C515`. A busy secondary queue therefore yields the active slot-$15
	# task at `$856F`; it does not keep the task active across the next NMI.
	if (int(ram[0x0515]) & 0xFF) != 0:
		var busy_registers := cpu.duplicate(true)
		busy_registers["pc"] = 0x856F
		busy_registers["a"] = 0x01
		busy_registers["p"] = int(cpu.get("p", 0x20)) & ~P_NZ
		busy_registers["p_known_mask"] = int(cpu.get("p_known_mask", P_NZ)) | P_NZ
		return {
			"ok": true,
			"status": "map_worker_queue_busy_yield_at_856F",
			"rom_sha256": ROM_SHA256,
			"entry_pc": 0x8572,
			"exit_pc": 0x856F,
			"callsite_pc": 0x856F,
			"map_id": map_id,
			"mapper": mapper.duplicate(true),
			"entry_registers": cpu.duplicate(true),
			"registers": busy_registers,
			"entry_ram_image": ram.duplicate(),
			"updated_ram": ram.duplicate(),
			"entry_stack_page": stack.duplicate(),
			"stack_page": stack.duplicate(),
			"queue_busy_flag": int(ram[0x0515]),
			"batch_start_map_index": map_start_index,
			"batch_start_placement": placement,
			"ram_writes": [],
			"stack_writes": [],
			"mapper_writes": [],
			"calls": [],
			"source_hashes": {
				"worker_8572_85c2": WORKER_SHA256,
				"yield_callsite": "59653ff81dfe5c01f141d4ee69bb4832290c727091c41b92a71a6b0e2400a837",
			},
			"trace_state_used": false,
			"source_cycle_timing_modeled": false,
		}
	_write(ram, ram_writes, 0x0515, 0x01, 0x8577, "map_batch_busy")
	_write(ram, ram_writes, 0x05C7, 0x00, 0x857C, "map_queue_offset_reset")
	var selector := _stack_pop(stack, int(cpu["sp"]))
	cpu["sp"] = (int(cpu["sp"]) + 1) & 0xFF
	if selector != expected_selector:
		return _failure("The saved map selector does not match the ROM-derived map-$%02X selector `$%02X`." % [map_id, expected_selector])
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
			return _failure("Map-$%02X metatile `$%02X` is not covered by the current source-bound batch." % [map_id, block_id])
		var metatile_tiles: PackedByteArray = source["tiles_" + metatile_key]
		var metatile_attribute := int(source["attribute_" + metatile_key][0])
		# `$85C2` leaves its source tile-record pointer in zero-page `$56/$57`.
		# Reproduce the final `$8665/$866D` writes from the selector/metatile
		# formula pinned by the ROM extraction manifest.
		var metatile_window_offset := (selector << 12) + (block_id << 4)
		var metatile_source_pointer := 0xA000 + (metatile_window_offset & 0x1FFF)
		_write(ram, ram_writes, 0x0056, metatile_source_pointer & 0xFF,
			0x8665, "metatile_tile_record_pointer_low")
		_write(ram, ram_writes, 0x0057, (metatile_source_pointer >> 8) & 0xFF,
			0x866D, "metatile_tile_record_pointer_high")
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
			"tile_source_sha256": map00_hashes.get("metatile_%02X_tiles" % block_id,
				_metatile_tiles_sha256(block_id)),
			"attribute_source_sha256": map00_hashes.get("metatile_%02X_attribute" % block_id,
				_metatile_attribute_sha256(block_id)),
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
	var callsite_sp := (expected_entry_sp + 1) & 0xFF if row_remaining == 0 else expected_entry_sp
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
	var batch_result := {
		"ok": true,
		"status": "map%02X_%d_metatiles_ready_at_yield" % [map_id, batch_cell_count],
		"rom_sha256": ROM_SHA256,
		"entry_pc": 0x8572,
		"exit_pc": callsite_pc,
		"map_id": map_id,
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
		"source_hashes": {"worker_8572_85c2": WORKER_SHA256,
			"metatile_expand_85c2_86d3": EXPAND_SHA256},
		"trace_state_used": false,
		"temporary_stack_writes_modeled": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"source_cycle_timing_modeled": false,
	}
	var source_hashes: Dictionary = batch_result["source_hashes"]
	if map_id in [0x00, 0x0E, 0x11, 0x12, 0x2D, 0x2F, 0x36, 0x51, 0x52, 0x56]:
		source_hashes.merge(source.get("source_hashes", {}), true)
	else:
		source_hashes.merge({
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
		}, true)
		source_hashes["block_map_%02X" % map_id] = BLOCK_MAP_SHA256 if map_id == 0x42 else BLOCK_MAP_43_SHA256
	if map_id == 0x43:
		source_hashes.merge({
			"metatile_2F_tiles": METATILE_2F_TILES_SHA256,
			"metatile_2F_attribute": METATILE_2F_ATTRIBUTE_SHA256,
			"metatile_ED_tiles": METATILE_ED_TILES_SHA256,
			"metatile_ED_attribute": METATILE_ED_ATTRIBUTE_SHA256,
			"metatile_34_tiles": METATILE_34_TILES_SHA256,
			"metatile_34_attribute": METATILE_34_ATTRIBUTE_SHA256,
			"metatile_EC_tiles": METATILE_EC_TILES_SHA256,
			"metatile_EC_attribute": METATILE_EC_ATTRIBUTE_SHA256,
		}, true)
	batch_result["source_hashes"] = source_hashes
	return batch_result


func _expected_previous_batch_state(map_id: int, map_start_index: int,
		current_placement: int) -> Dictionary:
	if map_start_index < 3:
		return {"queue_bytes": -1, "return_y": -1}
	var previous_map_start := map_start_index - 3
	var page_base := 0x00
	if map_id in [0x2D, 0x36, 0x43]:
		page_base = 0x80
	elif map_id in [0x51, 0x52]:
		page_base = 0xA0 if current_placement >= 0xA0 else 0x80
	elif map_id == 0x00 or current_placement >= 0xA0:
		page_base = 0xA0
	var placement := page_base + previous_map_start
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


func _load_sources(map_id: int) -> Dictionary:
	if map_id == 0x2F:
		return _load_map2f_sources()
	if map_id == 0x2D:
		return _load_map2d_sources()
	if map_id == 0x11:
		return _load_map11_sources()
	if map_id == 0x12:
		return _load_map12_sources()
	if map_id in [0x00, 0x0E]:
		return _load_map00_sources(map_id)
	if map_id == 0x56:
		return _load_map00_sources(map_id, 0x02)
	if map_id == 0x36:
		return _load_map36_sources()
	if map_id == 0x52:
		return _load_map52_sources()
	if map_id == 0x51:
		return _load_map51_sources()
	var block_map_path := BLOCK_MAP_PATH if map_id == 0x42 else BLOCK_MAP_43_PATH
	var block_map_hash := BLOCK_MAP_SHA256 if map_id == 0x42 else BLOCK_MAP_43_SHA256
	var specs := {
		"worker": [WORKER_PATH, WORKER_SHA256, 0x50],
		"expand": [EXPAND_PATH, EXPAND_SHA256, 0x111],
		"block_map": [block_map_path, block_map_hash, 0x20],
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
	if map_id == 0x43:
		specs.merge({
			"tiles_2F": [METATILE_2F_TILES_PATH, METATILE_2F_TILES_SHA256, 0x10],
			"attribute_2F": [METATILE_2F_ATTRIBUTE_PATH, METATILE_2F_ATTRIBUTE_SHA256, 0x01],
			"tiles_ED": [METATILE_ED_TILES_PATH, METATILE_ED_TILES_SHA256, 0x10],
			"attribute_ED": [METATILE_ED_ATTRIBUTE_PATH, METATILE_ED_ATTRIBUTE_SHA256, 0x01],
			"tiles_34": [METATILE_34_TILES_PATH, METATILE_34_TILES_SHA256, 0x10],
			"attribute_34": [METATILE_34_ATTRIBUTE_PATH, METATILE_34_ATTRIBUTE_SHA256, 0x01],
			"tiles_EC": [METATILE_EC_TILES_PATH, METATILE_EC_TILES_SHA256, 0x10],
			"attribute_EC": [METATILE_EC_ATTRIBUTE_PATH, METATILE_EC_ATTRIBUTE_SHA256, 0x01],
		}, true)
	var source: Dictionary = {}
	for key: String in specs:
		var spec: Array = specs[key]
		var path := String(spec[0])
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(spec[2]) or FileAccess.get_sha256(path) != String(spec[1]):
			return {"ok": false, "error": "Map-$%02X source failed size/hash validation: %s" % [map_id, path]}
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


func _load_map11_sources() -> Dictionary:
	if FileAccess.get_sha256(MAP11_MANIFEST_PATH) != MAP11_MANIFEST_SHA256:
		return {"ok": false, "error": "Map-$11 source manifest failed its pinned ROM hash."}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP11_MANIFEST_PATH))
	if not parsed is Dictionary:
		return {"ok": false, "error": "Map-$11 source manifest is invalid JSON."}
	var manifest: Dictionary = parsed
	var map_record: Dictionary = manifest.get("map", {})
	if String(manifest.get("schema", "")) != "ct2-first-command-map-11-rom-sources-v1" \
			or String(manifest.get("rom", {}).get("sha256", "")) != ROM_SHA256 \
			or String(map_record.get("map_id", "")) != "0x11" \
			or String(map_record.get("resolved_selector", "")) != "0x00" \
			or String(map_record.get("block_map_path", "")) != "block_map_11_selector_00.bin" \
			or String(map_record.get("chr_pair_path", "")) != "chr_pair_11.bin":
		return {"ok": false, "error": "Map-$11 manifest does not identify the checked ROM, map, selector, or source files."}
	var block_path := MAP11_ROOT + String(map_record["block_map_path"])
	var block_map := FileAccess.get_file_as_bytes(block_path)
	var chr_pair_variant: Variant = map_record.get("chr_pair", [])
	if not chr_pair_variant is Array or chr_pair_variant != ["0x3C", "0x4A"] \
			or block_map.size() != 0x20 or FileAccess.get_sha256(block_path) != MAP11_BLOCK_SHA256:
		return {"ok": false, "error": "Map-$11 selector-$00 block map or CHR pair failed source validation."}
	var source: Dictionary = {"worker": FileAccess.get_file_as_bytes(WORKER_PATH),
		"expand": FileAccess.get_file_as_bytes(EXPAND_PATH), "block_map": block_map}
	var source_hashes := {"map_manifest": MAP11_MANIFEST_SHA256, "block_map_11": MAP11_BLOCK_SHA256,
		"worker_8572_85c2": WORKER_SHA256, "metatile_expand_85c2_86d3": EXPAND_SHA256}
	var records_variant: Variant = manifest.get("entries", [])
	if not records_variant is Array:
		return {"ok": false, "error": "Map-$11 source manifest has no entry list."}
	var found_ids: Dictionary = {}
	for record_variant in records_variant:
		if not record_variant is Dictionary:
			return {"ok": false, "error": "Map-$11 source manifest has a malformed entry."}
		var record: Dictionary = record_variant
		var path := String(record.get("path", ""))
		if path in ["selector_logic_86d3.bin", "selector_proof.bin", "block_map_11_selector_00.bin", "chr_pair_11.bin"]:
			continue
		var filename_parts := path.trim_suffix(".bin").split("_")
		if filename_parts.size() != 3 or filename_parts[0] != "metatile" \
				or filename_parts[2] not in ["tiles", "attribute"]:
			return {"ok": false, "error": "Map-$11 manifest contains an unexpected runtime entry: %s" % path}
		var id_text := String(filename_parts[1]).to_upper()
		var metatile_id := id_text.hex_to_int()
		var kind := String(filename_parts[2])
		if record.get("map_id", "") != "0x11" or record.get("selector", "") != "0x00" \
				or String(record.get("metatile_id", "")).to_upper() != ("0x" + id_text).to_upper() \
				or String(record.get("prg_bank", "")) != ("0x12" if kind == "tiles" else "0x0B"):
			return {"ok": false, "error": "Map-$11 metatile `$%02X` has invalid ROM provenance." % metatile_id}
		var source_path := MAP11_ROOT + path
		var expected_size := 0x10 if kind == "tiles" else 0x01
		var digest := String(record.get("sha256", ""))
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if bytes.size() != expected_size or FileAccess.get_sha256(source_path) != digest:
			return {"ok": false, "error": "Map-$11 metatile `$%02X` %s failed size/hash validation." % [metatile_id, kind]}
		var source_key := ("tiles_" if kind == "tiles" else "attribute_") + id_text
		source[source_key] = bytes
		source_hashes["metatile_%s_%s" % [id_text, kind]] = digest
		found_ids[metatile_id] = int(found_ids.get(metatile_id, 0)) | (1 if kind == "tiles" else 2)
	var block_ids: Dictionary = {}
	for value in block_map:
		block_ids[int(value)] = true
	if found_ids.size() != block_ids.size():
		return {"ok": false, "error": "Map-$11 metatile manifest does not cover its block-map IDs."}
	for id_variant in block_ids:
		if int(found_ids.get(int(id_variant), 0)) != 3:
			return {"ok": false, "error": "Map-$11 metatile `$%02X` lacks tile or attribute bytes." % int(id_variant)}
	var worker: PackedByteArray = source["worker"]
	var expand: PackedByteArray = source["expand"]
	if worker.size() != 0x50 or FileAccess.get_sha256(WORKER_PATH) != WORKER_SHA256 \
			or expand.size() != 0x111 or FileAccess.get_sha256(EXPAND_PATH) != EXPAND_SHA256:
		return {"ok": false, "error": "Map-$11 shared worker source failed its hash check."}
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source}


func _load_map12_sources() -> Dictionary:
	if FileAccess.get_sha256(MAP12_MANIFEST_PATH) != MAP12_MANIFEST_SHA256:
		return {"ok": false, "error": "Map-$12 source manifest failed its pinned ROM hash."}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP12_MANIFEST_PATH))
	if not parsed is Dictionary:
		return {"ok": false, "error": "Map-$12 source manifest is invalid JSON."}
	var manifest: Dictionary = parsed
	var map_record: Dictionary = manifest.get("map", {})
	if String(manifest.get("schema", "")) != "ct2-first-command-map-12-rom-sources-v1" \
			or String(manifest.get("rom", {}).get("sha256", "")) != ROM_SHA256 \
			or String(map_record.get("map_id", "")) != "0x12" \
			or String(map_record.get("resolved_selector", "")) != "0x00" \
			or String(map_record.get("block_map_path", "")) != "block_map_12_selector_00.bin" \
			or String(map_record.get("chr_pair_path", "")) != "chr_pair_12.bin":
		return {"ok": false, "error": "Map-$12 manifest does not identify the checked ROM, map, selector, or source files."}
	var block_path := MAP12_ROOT + String(map_record["block_map_path"])
	var block_map := FileAccess.get_file_as_bytes(block_path)
	var chr_pair_variant: Variant = map_record.get("chr_pair", [])
	if not chr_pair_variant is Array or chr_pair_variant != ["0x3C", "0x4A"] \
			or block_map.size() != 0x20 or FileAccess.get_sha256(block_path) != MAP12_BLOCK_SHA256:
		return {"ok": false, "error": "Map-$12 selector-$00 block map or CHR pair failed source validation."}
	var source: Dictionary = {"worker": FileAccess.get_file_as_bytes(WORKER_PATH),
		"expand": FileAccess.get_file_as_bytes(EXPAND_PATH), "block_map": block_map}
	var source_hashes := {"map_manifest": MAP12_MANIFEST_SHA256, "block_map_12": MAP12_BLOCK_SHA256,
		"worker_8572_85c2": WORKER_SHA256, "metatile_expand_85c2_86d3": EXPAND_SHA256}
	var records_variant: Variant = manifest.get("entries", [])
	if not records_variant is Array:
		return {"ok": false, "error": "Map-$12 source manifest has no entry list."}
	var found_ids: Dictionary = {}
	for record_variant in records_variant:
		if not record_variant is Dictionary:
			return {"ok": false, "error": "Map-$12 source manifest has a malformed entry."}
		var record: Dictionary = record_variant
		var path := String(record.get("path", ""))
		if path in ["selector_logic_86d3.bin", "selector_proof.bin", "route_map_lookup_proof.bin",
				"block_map_12_selector_00.bin", "chr_pair_12.bin"]:
			continue
		var filename_parts := path.trim_suffix(".bin").split("_")
		if filename_parts.size() != 3 or filename_parts[0] != "metatile" \
				or filename_parts[2] not in ["tiles", "attribute"]:
			return {"ok": false, "error": "Map-$12 manifest contains an unexpected runtime entry: %s" % path}
		var id_text := String(filename_parts[1]).to_upper()
		var metatile_id := id_text.hex_to_int()
		var kind := String(filename_parts[2])
		if record.get("map_id", "") != "0x12" or record.get("selector", "") != "0x00" \
				or String(record.get("metatile_id", "")).to_upper() != ("0x" + id_text).to_upper() \
				or String(record.get("prg_bank", "")) != ("0x12" if kind == "tiles" else "0x0B"):
			return {"ok": false, "error": "Map-$12 metatile `$%02X` has invalid ROM provenance." % metatile_id}
		var source_path := MAP12_ROOT + path
		var expected_size := 0x10 if kind == "tiles" else 0x01
		var digest := String(record.get("sha256", ""))
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if bytes.size() != expected_size or FileAccess.get_sha256(source_path) != digest:
			return {"ok": false, "error": "Map-$12 metatile `$%02X` %s failed size/hash validation." % [metatile_id, kind]}
		var source_key := ("tiles_" if kind == "tiles" else "attribute_") + id_text
		source[source_key] = bytes
		source_hashes["metatile_%s_%s" % [id_text, kind]] = digest
		found_ids[metatile_id] = int(found_ids.get(metatile_id, 0)) | (1 if kind == "tiles" else 2)
	var block_ids: Dictionary = {}
	for value in block_map:
		block_ids[int(value)] = true
	if found_ids.size() != block_ids.size():
		return {"ok": false, "error": "Map-$12 metatile manifest does not cover its block-map IDs."}
	for id_variant in block_ids:
		if int(found_ids.get(int(id_variant), 0)) != 3:
			return {"ok": false, "error": "Map-$12 metatile `$%02X` lacks tile or attribute bytes." % int(id_variant)}
	var worker: PackedByteArray = source["worker"]
	var expand: PackedByteArray = source["expand"]
	if worker.size() != 0x50 or FileAccess.get_sha256(WORKER_PATH) != WORKER_SHA256 \
			or expand.size() != 0x111 or FileAccess.get_sha256(EXPAND_PATH) != EXPAND_SHA256:
		return {"ok": false, "error": "Map-$12 shared worker source failed its hash check."}
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source}


func _load_map52_sources() -> Dictionary:
	var specs := {
		"worker": [WORKER_PATH, WORKER_SHA256, 0x50],
		"expand": [EXPAND_PATH, EXPAND_SHA256, 0x111],
		"block_map": [BLOCK_MAP_52_PATH, BLOCK_MAP_52_SHA256, 0x20],
		"tiles_49": [MAP52_METATILE_49_TILES_PATH, MAP52_METATILE_49_TILES_SHA256, 0x10],
		"attribute_49": ["res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_49_attribute.bin", MAP52_METATILE_ATTRIBUTE_SHA256, 0x01],
		"tiles_4A": [MAP52_METATILE_4A_TILES_PATH, MAP52_METATILE_4A_TILES_SHA256, 0x10],
		"attribute_4A": ["res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_4A_attribute.bin", MAP52_METATILE_ATTRIBUTE_SHA256, 0x01],
		"tiles_4B": [MAP52_METATILE_4B_TILES_PATH, MAP52_METATILE_4B_TILES_SHA256, 0x10],
		"attribute_4B": ["res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_4B_attribute.bin", MAP52_METATILE_ATTRIBUTE_SHA256, 0x01],
		"tiles_C3": [MAP52_METATILE_C3_TILES_PATH, MAP52_METATILE_C3_TILES_SHA256, 0x10],
		"attribute_C3": ["res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/map_52_metatile_C3_attribute.bin", MAP52_METATILE_ATTRIBUTE_SHA256, 0x01],
	}
	var source: Dictionary = {}
	var source_hashes := {"block_map_52": BLOCK_MAP_52_SHA256}
	for key: String in specs:
		var spec: Array = specs[key]
		var path := String(spec[0])
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(spec[2]) or FileAccess.get_sha256(path) != String(spec[1]):
			return {"ok": false, "error": "Map-$52 source failed size/hash validation: %s" % path}
		source[key] = bytes
		if key.begins_with("tiles_") or key.begins_with("attribute_"):
			var suffix := "tiles" if key.begins_with("tiles_") else "attribute"
			var metatile_id := key.trim_prefix("tiles_").trim_prefix("attribute_")
			source_hashes["metatile_%s_%s" % [metatile_id, suffix]] = String(spec[1])
	var worker: PackedByteArray = source["worker"]
	var expand: PackedByteArray = source["expand"]
	if worker.slice(0, 5) != PackedByteArray([0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
			or worker.slice(0x28, 0x2B) != PackedByteArray([0x20, 0xC2, 0x85]) \
			or worker.slice(0x4C, 0x50) != PackedByteArray([0x20, 0x15, 0xC5, 0x60]) \
			or expand.slice(0, 10) != PackedByteArray([0x85, 0x56, 0x98, 0x29, 0x07,
				0x0A, 0x0A, 0x9D, 0xA6, 0x04]) \
			or expand.slice(0x10E, 0x111) != PackedByteArray([0xD0, 0xF2, 0x60]):
		return {"ok": false, "error": "Map-$52 worker spans do not contain the decoded source path."}
	source_hashes["worker_8572_85c2"] = WORKER_SHA256
	source_hashes["metatile_expand_85c2_86d3"] = EXPAND_SHA256
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source}


func _load_map51_sources() -> Dictionary:
	if FileAccess.get_sha256(MAP51_MANIFEST_PATH) != MAP51_MANIFEST_SHA256:
		return {"ok": false, "error": "Map-$51 ROM-source manifest failed its pinned hash check."}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP51_MANIFEST_PATH))
	if not parsed is Dictionary:
		return {"ok": false, "error": "Map-$51 ROM-source manifest is invalid JSON."}
	var manifest: Dictionary = parsed
	var rom: Dictionary = manifest.get("rom", {})
	var map_record: Dictionary = manifest.get("map", {})
	var selector_proof: Dictionary = map_record.get("selector_proof", {})
	if String(manifest.get("schema", "")) != "ct2-first-command-map-51-rom-sources-v1" \
			or String(rom.get("sha256", "")) != ROM_SHA256 \
			or String(map_record.get("map_id", "")) != "0x51" \
			or String(map_record.get("callback_id", "")) != "0x63" \
			or String(map_record.get("resolved_selector", "")) != "0x00" \
			or String(map_record.get("block_map_path", "")) != "block_map_51_selector_00.bin" \
			or String(map_record.get("block_map_cpu_address", "")) != "0x9584" \
			or String(map_record.get("block_map_file_offset", "")) != "0x017594" \
			or String(selector_proof.get("logic_path", "")) != "selector_logic_86d3.bin" \
			or String(selector_proof.get("logic_cpu_address", "")) != "0x86D3" \
			or String(selector_proof.get("table_byte_path", "")) != "selector_proof.bin" \
			or String(selector_proof.get("table_entry_cpu_address", "")) != "0x8B56" \
			or String(selector_proof.get("table_entry_file_offset", "")) != "0x016B66" \
			or int(selector_proof.get("table_index", -1)) != 20 \
			or String(selector_proof.get("packed_byte", "")) != "0x80" \
			or String(selector_proof.get("result", "")) != "0x00" \
			or int(selector_proof.get("shift", -1)) != 2:
		return {"ok": false, "error": "Map-$51 manifest does not pin the callback, selector proof, or block-map ROM pointer."}
	var entries_variant: Variant = manifest.get("entries", [])
	if not entries_variant is Array:
		return {"ok": false, "error": "Map-$51 source manifest has no entry table."}
	var entries_by_path: Dictionary = {}
	for entry_variant in entries_variant:
		if entry_variant is Dictionary:
			entries_by_path[String(entry_variant.get("path", ""))] = entry_variant
	var selector_logic_path := MAP51_ROOT + String(selector_proof["logic_path"])
	var selector_logic := FileAccess.get_file_as_bytes(selector_logic_path)
	var selector_logic_entry: Dictionary = entries_by_path.get(String(selector_proof["logic_path"]), {})
	if selector_logic.size() != 27 \
			or int(selector_logic_entry.get("size_bytes", -1)) != 27 \
			or FileAccess.get_sha256(selector_logic_path) != String(selector_logic_entry.get("sha256", "")) \
			or String(selector_logic_entry.get("file_offset", "")) != "0x0166E3" \
			or String(selector_logic_entry.get("cpu_address", "")) != "0x86D3" \
			or String(selector_logic_entry.get("prg_bank", "")) != "0x0B" \
			or selector_logic != PackedByteArray([0x48, 0x29, 0x03, 0xAA, 0x68, 0x48,
				0x4A, 0x4A, 0xA8, 0xB9, 0x42, 0x8B, 0xCA, 0x30, 0x05, 0x4A,
				0x4A, 0x4C, 0xDF, 0x86, 0x29, 0x03, 0x8D, 0xCA, 0x05, 0x68, 0x60]):
		return {"ok": false, "error": "Map-$51 selector routine differs from the pinned bank-$0B `$86D3` bytes."}
	var selector_proof_path := MAP51_ROOT + String(selector_proof["table_byte_path"])
	var selector_byte := FileAccess.get_file_as_bytes(selector_proof_path)
	var selector_entry: Dictionary = entries_by_path.get(String(selector_proof["table_byte_path"]), {})
	if selector_byte != PackedByteArray([0x80]) \
			or int(selector_entry.get("size_bytes", -1)) != 1 \
			or FileAccess.get_sha256(selector_proof_path) != String(selector_entry.get("sha256", "")) \
			or String(selector_entry.get("file_offset", "")) != "0x016B66" \
			or String(selector_entry.get("cpu_address", "")) != "0x8B56" \
			or String(selector_entry.get("prg_bank", "")) != "0x0B" \
			or String(selector_entry.get("map_id", "")) != "0x51":
		return {"ok": false, "error": "Map-$51 selector proof is not the packed bank-$0B table byte at `$8B56`."}
	var block_map_record: Dictionary = entries_by_path.get(String(map_record["block_map_path"]), {})
	var block_map_path := MAP51_ROOT + String(map_record["block_map_path"])
	var block_map := FileAccess.get_file_as_bytes(block_map_path)
	if block_map.size() != 0x20 or FileAccess.get_sha256(block_map_path) != MAP51_BLOCK_SHA256 \
			or int(map_record.get("block_map_length_bytes", -1)) != 0x20 \
			or String(map_record.get("block_map_dimensions", "")) != "8x4 metatiles" \
			or int(block_map_record.get("size_bytes", -1)) != 0x20 \
			or String(block_map_record.get("sha256", "")) != MAP51_BLOCK_SHA256 \
			or String(block_map_record.get("file_offset", "")) != "0x017594" \
			or String(block_map_record.get("cpu_address", "")) != "0x9584" \
			or String(block_map_record.get("prg_bank", "")) != "0x0B" \
			or String(block_map_record.get("map_id", "")) != "0x51" \
			or String(block_map_record.get("selector", "")) != "0x00":
		return {"ok": false, "error": "Map-$51 block map failed its hash or bank-$0B pointer provenance check."}
	var expected_block_ids: Array = ["0x48", "0x49", "0x4A", "0x7F", "0x80", "0x81", "0x82", "0xC3"]
	var referenced_ids: Variant = map_record.get("metatile_ids_referenced", [])
	var metatile_records: Variant = map_record.get("metatiles", [])
	if referenced_ids != expected_block_ids or not metatile_records is Array \
			or metatile_records.size() != expected_block_ids.size():
		return {"ok": false, "error": "Map-$51 block-map metatile coverage differs from the pinned eight source records."}
	var source: Dictionary = {"block_map": block_map}
	var source_hashes := {
		"map_manifest": MAP51_MANIFEST_SHA256,
		"block_map_51": MAP51_BLOCK_SHA256,
	}
	var seen_ids: Dictionary = {}
	for record_variant in metatile_records:
		if not record_variant is Dictionary:
			return {"ok": false, "error": "Map-$51 manifest contains a malformed metatile source record."}
		var record: Dictionary = record_variant
		var id_text := String(record.get("metatile_id", ""))
		if not id_text.begins_with("0x"):
			return {"ok": false, "error": "Map-$51 manifest contains a noncanonical metatile ID."}
		var block_id := id_text.trim_prefix("0x").hex_to_int()
		var id_key := "%02X" % block_id
		if seen_ids.has(block_id) or not block_map.has(block_id):
			return {"ok": false, "error": "Map-$51 manifest repeats or invents metatile `$%s`." % id_key}
		seen_ids[block_id] = true
		var tile_name := String(record.get("tiles_path", ""))
		var attribute_name := String(record.get("attribute_path", ""))
		var tile_entry: Dictionary = entries_by_path.get(tile_name, {})
		var attribute_entry: Dictionary = entries_by_path.get(attribute_name, {})
		var tile_path := MAP51_ROOT + tile_name
		var attribute_path := MAP51_ROOT + attribute_name
		var tiles := FileAccess.get_file_as_bytes(tile_path)
		var attribute := FileAccess.get_file_as_bytes(attribute_path)
		var tile_hash := String(record.get("tiles_sha256", ""))
		var attribute_hash := String(record.get("attribute_sha256", ""))
		var tile_window_offset := block_id << 4
		var tile_file_offset := 0x024010 + tile_window_offset
		var tile_cpu_address := 0xA000 + (tile_window_offset & 0x1FFF)
		var attribute_file_offset := 0x017BF4 + block_id
		var attribute_cpu_address := 0x9BE4 + block_id
		if String(record.get("tiles_file_offset", "")) != "0x%06X" % tile_file_offset \
				or String(record.get("tiles_cpu_address", "")) != "0x%04X" % tile_cpu_address \
				or String(record.get("tiles_prg_bank", "")) != "0x12" \
				or String(record.get("attribute_file_offset", "")) != "0x%06X" % attribute_file_offset \
				or String(record.get("attribute_cpu_address", "")) != "0x%04X" % attribute_cpu_address \
				or String(tile_entry.get("file_offset", "")) != "0x%06X" % tile_file_offset \
				or String(tile_entry.get("cpu_address", "")) != "0x%04X" % tile_cpu_address \
				or String(tile_entry.get("prg_bank", "")) != "0x12" \
				or String(tile_entry.get("map_id", "")) != "0x51" \
				or String(tile_entry.get("selector", "")) != "0x00" \
				or String(tile_entry.get("metatile_id", "")) != id_text \
				or String(attribute_entry.get("file_offset", "")) != "0x%06X" % attribute_file_offset \
				or String(attribute_entry.get("cpu_address", "")) != "0x%04X" % attribute_cpu_address \
				or String(attribute_entry.get("prg_bank", "")) != "0x0B" \
				or String(attribute_entry.get("map_id", "")) != "0x51" \
				or String(attribute_entry.get("selector", "")) != "0x00" \
				or String(attribute_entry.get("metatile_id", "")) != id_text \
				or tiles.size() != 0x10 or attribute.size() != 1 \
				or String(tile_entry.get("sha256", "")) != tile_hash \
				or String(attribute_entry.get("sha256", "")) != attribute_hash \
				or FileAccess.get_sha256(tile_path) != tile_hash \
				or FileAccess.get_sha256(attribute_path) != attribute_hash:
			return {"ok": false, "error": "Map-$51 metatile `$%s` failed ROM formula, bank, size, or hash validation." % id_key}
		source["tiles_" + id_key] = tiles
		source["attribute_" + id_key] = attribute
		source_hashes["metatile_%s_tiles" % id_key] = tile_hash
		source_hashes["metatile_%s_attribute" % id_key] = attribute_hash
	if seen_ids.size() != expected_block_ids.size():
		return {"ok": false, "error": "Map-$51 source records do not cover every block-map metatile."}
	var chr_pair_path := MAP51_ROOT + String(map_record.get("chr_pair_path", ""))
	var chr_pair := FileAccess.get_file_as_bytes(chr_pair_path)
	var chr_pair_entry: Dictionary = entries_by_path.get(String(map_record.get("chr_pair_path", "")), {})
	if String(map_record.get("chr_pair_path", "")) != "chr_pair_51.bin" \
			or String(map_record.get("chr_pair_cpu_address", "")) != "0x8790" \
			or String(map_record.get("chr_pair_file_offset", "")) != "0x0167A0" \
			or String(chr_pair_entry.get("prg_bank", "")) != "0x0B" \
			or String(chr_pair_entry.get("map_id", "")) != "0x51" \
			or int(chr_pair_entry.get("size_bytes", -1)) != 2 \
			or chr_pair != PackedByteArray([0x3C, 0x4A]) \
			or FileAccess.get_sha256(chr_pair_path) != String(chr_pair_entry.get("sha256", "")):
		return {"ok": false, "error": "Map-$51 CHR pair failed its bank-$0B source-data check."}
	var worker := FileAccess.get_file_as_bytes(WORKER_PATH)
	var expand := FileAccess.get_file_as_bytes(EXPAND_PATH)
	if worker.size() != 0x50 or FileAccess.get_sha256(WORKER_PATH) != WORKER_SHA256 \
			or expand.size() != 0x111 or FileAccess.get_sha256(EXPAND_PATH) != EXPAND_SHA256 \
			or worker.slice(0, 5) != PackedByteArray([0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
			or worker.slice(0x28, 0x2B) != PackedByteArray([0x20, 0xC2, 0x85]) \
			or worker.slice(0x4C, 0x50) != PackedByteArray([0x20, 0x15, 0xC5, 0x60]) \
			or expand.slice(0, 10) != PackedByteArray([0x85, 0x56, 0x98, 0x29, 0x07,
				0x0A, 0x0A, 0x9D, 0xA6, 0x04]) \
			or expand.slice(0x10E, 0x111) != PackedByteArray([0xD0, 0xF2, 0x60]):
		return {"ok": false, "error": "Map-$51 shared worker/expander source failed its pinned byte checks."}
	source["worker"] = worker
	source["expand"] = expand
	source_hashes["worker_8572_85c2"] = WORKER_SHA256
	source_hashes["metatile_expand_85c2_86d3"] = EXPAND_SHA256
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source}


func _load_map2f_sources() -> Dictionary:
	if FileAccess.get_sha256(MAP2F_MANIFEST_PATH) != MAP2F_MANIFEST_SHA256:
		return {"ok": false, "error": "Map-$2F ROM-source manifest failed its pinned hash check."}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP2F_MANIFEST_PATH))
	if not parsed is Dictionary:
		return {"ok": false, "error": "Map-$2F ROM-source manifest is invalid JSON."}
	var manifest: Dictionary = parsed
	var route: Dictionary = manifest.get("route_context", {})
	var mapping: Dictionary = manifest.get("mapping", {})
	var block_record: Dictionary = manifest.get("block_map", {})
	var first_batch: Dictionary = manifest.get("first_batch", {})
	if String(manifest.get("schema", "")) != "ct2-slot15-callback36-map2f-resume-sources-v1" \
			or String(manifest.get("source_rom", {}).get("sha256", "")) != ROM_SHA256 \
			or String(route.get("scenario_id", "")) != "0x2E" \
			or String(route.get("callback_id", "")) != "0x36" \
			or String(route.get("map_id", "")) != "0x2F" \
			or String(mapping.get("resolved_selector", "")) != "0x01" \
			or String(mapping.get("block_map_cpu_address", "")) != "0x9144" \
			or String(mapping.get("block_map_file_offset", "")) != "0x017154" \
			or String(block_record.get("path", "")) != "map_2f_block_map.bin" \
			or String(block_record.get("sha256", "")) != MAP2F_BLOCK_MAP_SHA256 \
			or String(first_batch.get("metatile_ids_hex", "")).replace(" ", "").to_lower() != "151615" \
			or String(first_batch.get("expanded_source_records_sha256", "")) != MAP2F_FIRST_BATCH_RECORDS_SHA256:
		return {"ok": false, "error": "Map-$2F manifest does not pin scenario/callback, selector, block map, or first batch."}
	var block_map_path := MAP2F_ROOT + String(block_record.get("path", ""))
	var block_map := FileAccess.get_file_as_bytes(block_map_path)
	var expected_map_hex := String(block_record.get("bytes_hex", "")).replace(" ", "").to_lower()
	if block_map.size() != 0x20 or FileAccess.get_sha256(block_map_path) != MAP2F_BLOCK_MAP_SHA256 \
			or block_map.hex_encode().to_lower() != expected_map_hex:
		return {"ok": false, "error": "Map-$2F block map differs from its hash-pinned ROM bytes."}
	var worker := FileAccess.get_file_as_bytes(WORKER_PATH)
	var expand := FileAccess.get_file_as_bytes(EXPAND_PATH)
	if worker.size() != 0x50 or FileAccess.get_sha256(WORKER_PATH) != WORKER_SHA256 \
			or expand.size() != 0x111 or FileAccess.get_sha256(EXPAND_PATH) != EXPAND_SHA256:
		return {"ok": false, "error": "Map-$2F shared `$8572/$85C2` worker source failed its hash check."}
	var source: Dictionary = {"worker": worker, "expand": expand, "block_map": block_map}
	var source_hashes := {
		"map_manifest": MAP2F_MANIFEST_SHA256,
		"block_map_2F": MAP2F_BLOCK_MAP_SHA256,
		"first_batch_metatile_ids": MAP2F_FIRST_BATCH_IDS_SHA256,
		"first_batch_metatile_source_records": MAP2F_FIRST_BATCH_RECORDS_SHA256,
		"worker_8572_85c2": WORKER_SHA256,
		"metatile_expand_85c2_86d3": EXPAND_SHA256,
	}
	var metatile_records: Variant = manifest.get("metatile_sources_for_all_map_cells", [])
	if not metatile_records is Array:
		return {"ok": false, "error": "Map-$2F manifest omits the source records for its block map."}
	var seen_ids: Dictionary = {}
	for record_variant in metatile_records:
		if not record_variant is Dictionary:
			return {"ok": false, "error": "Map-$2F manifest contains a malformed metatile record."}
		var record: Dictionary = record_variant
		var id_text := String(record.get("metatile_id", ""))
		if not id_text.begins_with("0x"):
			return {"ok": false, "error": "Map-$2F manifest contains a noncanonical metatile ID."}
		var metatile_id := id_text.trim_prefix("0x").hex_to_int()
		var id_key := "%02X" % metatile_id
		if seen_ids.has(metatile_id) or not block_map.has(metatile_id):
			return {"ok": false, "error": "Map-$2F manifest repeats or invents metatile `$%s`." % id_key}
		seen_ids[metatile_id] = true
		var tile_record: Dictionary = record.get("tile_record", {})
		var attribute_record: Dictionary = record.get("attribute", {})
		var tile_path := MAP2F_ROOT + String(tile_record.get("path", ""))
		var attribute_path := MAP2F_ROOT + String(attribute_record.get("path", ""))
		var tiles := FileAccess.get_file_as_bytes(tile_path)
		var attribute := FileAccess.get_file_as_bytes(attribute_path)
		var tile_hash := String(tile_record.get("sha256", ""))
		var attribute_hash := String(attribute_record.get("sha256", ""))
		var expected_tile_hex := String(tile_record.get("bytes_hex", "")).replace(" ", "").to_lower()
		var expected_attribute_hex := String(attribute_record.get("bytes_hex", "")).replace(" ", "").to_lower()
		if String(tile_record.get("prg_bank", "")) != "0x12" \
				or String(attribute_record.get("prg_bank", "")) != "0x0B" \
				or tiles.size() != 0x10 or attribute.size() != 1 \
				or FileAccess.get_sha256(tile_path) != tile_hash \
				or FileAccess.get_sha256(attribute_path) != attribute_hash \
				or tiles.hex_encode().to_lower() != expected_tile_hex \
				or attribute.hex_encode().to_lower() != expected_attribute_hex:
			return {"ok": false, "error": "Map-$2F metatile `$%s` failed byte/hash/bank validation." % id_key}
		source["tiles_" + id_key] = tiles
		source["attribute_" + id_key] = attribute
		source_hashes["metatile_%s_tiles" % id_key] = tile_hash
		source_hashes["metatile_%s_attribute" % id_key] = attribute_hash
	if seen_ids.size() != 6:
		return {"ok": false, "error": "Map-$2F source package does not cover each block-map metatile."}
	var ids_path := MAP2F_ROOT + String(first_batch.get("metatile_ids_path", ""))
	var ids := FileAccess.get_file_as_bytes(ids_path)
	if ids != PackedByteArray([0x15, 0x16, 0x15]) \
			or FileAccess.get_sha256(ids_path) != MAP2F_FIRST_BATCH_IDS_SHA256 \
			or block_map.slice(0, 3) != ids:
		return {"ok": false, "error": "Map-$2F first three cells differ from the pinned `$15/$16/$15` source."}
	var records_path := MAP2F_ROOT + String(first_batch.get("expanded_source_records_path", ""))
	var records := FileAccess.get_file_as_bytes(records_path)
	var expected_records := PackedByteArray()
	for metatile_id in ids:
		var id_key := "%02X" % metatile_id
		expected_records.append(metatile_id)
		expected_records.append_array(source["tiles_" + id_key])
		expected_records.append(int(source["attribute_" + id_key][0]))
	if records.size() != 54 or records != expected_records \
			or FileAccess.get_sha256(records_path) != MAP2F_FIRST_BATCH_RECORDS_SHA256:
		return {"ok": false, "error": "Map-$2F first-batch source records failed their reconstructed ROM-byte check."}
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source}


func _load_map2d_sources() -> Dictionary:
	if FileAccess.get_sha256(MAP2D_MANIFEST_PATH) != MAP2D_MANIFEST_SHA256:
		return {"ok": false, "error": "Map-$2D metatile manifest failed its pinned hash check."}
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP2D_MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return {"ok": false, "error": "Map-$2D metatile manifest is invalid JSON."}
	var manifest: Dictionary = manifest_variant
	var map_source: Dictionary = manifest.get("map_source", {})
	if String(manifest.get("schema", "")) != "ct2-slot15-callback-34-map-2d-metatiles-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(map_source.get("map_id", "")) != "0x2D" \
			or String(map_source.get("resolved_selector", "")) != "0x02" \
			or String(map_source.get("block_map_sha256", "")) != MAP2D_BLOCK_SHA256:
		return {"ok": false, "error": "Map-$2D metatile manifest does not match the pinned ROM/map/selector."}
	var block_map := FileAccess.get_file_as_bytes(MAP2D_BLOCK_PATH)
	var expected_block_hex := String(map_source.get("block_map_bytes_hex", "")).replace(" ", "").to_upper()
	if block_map.size() != 0x20 or FileAccess.get_sha256(MAP2D_BLOCK_PATH) != MAP2D_BLOCK_SHA256 \
			or block_map.hex_encode().to_upper() != expected_block_hex:
		return {"ok": false, "error": "Map-$2D block map failed its ROM-source hash/byte check."}
	var worker := FileAccess.get_file_as_bytes(WORKER_PATH)
	var expand := FileAccess.get_file_as_bytes(EXPAND_PATH)
	if worker.size() != 0x50 or FileAccess.get_sha256(WORKER_PATH) != WORKER_SHA256 \
			or expand.size() != 0x111 or FileAccess.get_sha256(EXPAND_PATH) != EXPAND_SHA256:
		return {"ok": false, "error": "Map-$2D shared `$8572/$85C2` worker source failed its hash check."}
	var source: Dictionary = {"worker": worker, "expand": expand, "block_map": block_map}
	var source_hashes := {"map_manifest": MAP2D_MANIFEST_SHA256,
		"block_map_2D": MAP2D_BLOCK_SHA256,
		"worker_8572_85c2": WORKER_SHA256,
		"metatile_expand_85c2_86d3": EXPAND_SHA256}
	var records_variant: Variant = manifest.get("metatiles", [])
	if not records_variant is Array:
		return {"ok": false, "error": "Map-$2D manifest omits its metatile records."}
	var seen_ids: Dictionary = {}
	for record_variant in records_variant:
		if not record_variant is Dictionary:
			return {"ok": false, "error": "Map-$2D manifest contains a malformed metatile record."}
		var record: Dictionary = record_variant
		var metatile_id_text := String(record.get("metatile_id", ""))
		if not metatile_id_text.begins_with("0x"):
			return {"ok": false, "error": "Map-$2D metatile ID is not canonical hexadecimal."}
		var metatile_id := metatile_id_text.trim_prefix("0x").hex_to_int()
		var id_key := "%02X" % metatile_id
		if seen_ids.has(metatile_id) or not block_map.has(metatile_id):
			return {"ok": false, "error": "Map-$2D manifest repeats or invents metatile `$%s`." % id_key}
		seen_ids[metatile_id] = true
		var tiles_record: Dictionary = record.get("tiles", {})
		var attribute_record: Dictionary = record.get("attribute", {})
		var tiles_path := MAP2D_METATILE_ROOT + String(tiles_record.get("path", ""))
		var attribute_path := MAP2D_METATILE_ROOT + String(attribute_record.get("path", ""))
		var tiles := FileAccess.get_file_as_bytes(tiles_path)
		var attribute := FileAccess.get_file_as_bytes(attribute_path)
		var tiles_hash := String(tiles_record.get("sha256", ""))
		var attribute_hash := String(attribute_record.get("sha256", ""))
		if tiles.size() != 0x10 or attribute.size() != 1 \
				or FileAccess.get_sha256(tiles_path) != tiles_hash \
				or FileAccess.get_sha256(attribute_path) != attribute_hash \
				or String(tiles_record.get("prg_bank", "")) != "0x13" \
				or String(attribute_record.get("prg_bank", "")) != "0x0B":
			return {"ok": false, "error": "Map-$2D metatile `$%s` failed byte/bank provenance checks." % id_key}
		source["tiles_" + id_key] = tiles
		source["attribute_" + id_key] = attribute
		source_hashes["metatile_%s_tiles" % id_key] = tiles_hash
		source_hashes["metatile_%s_attribute" % id_key] = attribute_hash
	var unique_block_ids: Dictionary = {}
	for id_variant in block_map:
		unique_block_ids[int(id_variant)] = true
	if seen_ids.size() != unique_block_ids.size():
		return {"ok": false, "error": "Map-$2D tile manifest does not cover every unique block ID."}
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source}


func _load_map36_sources() -> Dictionary:
	if FileAccess.get_sha256(MAP00_MANIFEST_PATH) != MAP00_MANIFEST_SHA256:
		return {"ok": false, "error": "Map-$36 manifest hash differs from the pinned ROM extraction."}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP00_MANIFEST_PATH))
	if not parsed is Dictionary:
		return {"ok": false, "error": "Map-$36 source manifest is not valid JSON."}
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "first-command-page-correct-field-map-sources-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "Map-$36 source manifest does not identify the pinned ROM."}
	var entries_variant: Variant = manifest.get("entries", [])
	if not entries_variant is Array:
		return {"ok": false, "error": "Map-$36 source manifest has no entry table."}
	var entries_by_path: Dictionary = {}
	for entry_variant in entries_variant:
		if entry_variant is Dictionary:
			entries_by_path[String(entry_variant.get("path", ""))] = entry_variant
	var source: Dictionary = {}
	var source_hashes := {"map_manifest": MAP00_MANIFEST_SHA256}
	var block_map_path := "block_map_36_selector_01.bin"
	var block_entry_variant: Variant = entries_by_path.get(block_map_path, {})
	if not block_entry_variant is Dictionary:
		return {"ok": false, "error": "Map-$36 block-map entry is missing from the pinned manifest."}
	var block_entry: Dictionary = block_entry_variant
	if String(block_entry.get("block_map_id", "")) != "0x36" \
			or String(block_entry.get("selector", "")) != "0x01" \
			or String(block_entry.get("cpu_address", "")) != "0x9224" \
			or String(block_entry.get("file_offset", "")) != "0x017234" \
			or int(block_entry.get("size_bytes", -1)) != 0x20:
		return {"ok": false, "error": "Map-$36 block-map provenance differs from its ROM pointer."}
	var root := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/"
	var block_map := FileAccess.get_file_as_bytes(root + block_map_path)
	if block_map.size() != 0x20 or FileAccess.get_sha256(root + block_map_path) != String(block_entry.get("sha256", "")):
		return {"ok": false, "error": "Map-$36 block-map bytes failed manifest size/hash validation."}
	source["block_map"] = block_map
	source_hashes["block_map_36"] = String(block_entry["sha256"])
	var unique_ids: Dictionary = {}
	for block_id in block_map:
		unique_ids[int(block_id)] = true
	for block_id_variant in unique_ids.keys():
		var block_id := int(block_id_variant)
		var tile_window_offset := 0x1000 + (block_id << 4)
		var tile_file_offset := 0x024010 + tile_window_offset
		var tile_cpu_address := 0xA000 + (tile_window_offset & 0x1FFF)
		var attribute_file_offset := 0x017BF4 + 0x100 + block_id
		var attribute_cpu_address := 0x9BE4 + 0x100 + block_id
		for suffix in ["tiles", "attribute"]:
			var filename := "map_36_metatile_%02X_%s.bin" % [block_id, suffix]
			var entry_variant: Variant = entries_by_path.get(filename, {})
			if not entry_variant is Dictionary:
				return {"ok": false, "error": "Map-$36 metatile `$%02X` %s is missing from the pinned manifest." % [block_id, suffix]}
			var entry: Dictionary = entry_variant
			var expected_offset := tile_file_offset if suffix == "tiles" else attribute_file_offset
			var expected_cpu := tile_cpu_address if suffix == "tiles" else attribute_cpu_address
			var expected_size := 0x10 if suffix == "tiles" else 0x01
			if String(entry.get("block_map_id", "")) != "0x36" \
					or String(entry.get("selector", "")) != "0x01" \
					or String(entry.get("metatile_id", "")) != "0x%02X" % block_id \
					or String(entry.get("file_offset", "")) != "0x%06X" % expected_offset \
					or String(entry.get("cpu_address", "")) != "0x%04X" % expected_cpu \
					or int(entry.get("size_bytes", -1)) != expected_size:
				return {"ok": false, "error": "Map-$36 metatile `$%02X` %s provenance differs from the selector-$01 ROM formula." % [block_id, suffix]}
			var bytes_path := root + filename
			var bytes := FileAccess.get_file_as_bytes(bytes_path)
			if bytes.size() != expected_size or FileAccess.get_sha256(bytes_path) != String(entry.get("sha256", "")):
				return {"ok": false, "error": "Map-$36 metatile `$%02X` %s failed manifest size/hash validation." % [block_id, suffix]}
			source["%s_%02X" % [suffix, block_id]] = bytes
			source_hashes["metatile_%02X_%s" % [block_id, suffix]] = String(entry["sha256"])
	for key in ["worker", "expand"]:
		var path := WORKER_PATH if key == "worker" else EXPAND_PATH
		var expected_hash := WORKER_SHA256 if key == "worker" else EXPAND_SHA256
		var expected_size := 0x50 if key == "worker" else 0x111
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != expected_size or FileAccess.get_sha256(path) != expected_hash:
			return {"ok": false, "error": "Map-$36 shared worker source failed size/hash validation: %s" % path}
		source[key] = bytes
	source_hashes["worker_8572_85c2"] = WORKER_SHA256
	source_hashes["metatile_expand_85c2_86d3"] = EXPAND_SHA256
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source, "source_hashes": source_hashes}


func _load_map00_sources(map_id: int = 0x00, selector: int = 0x00) -> Dictionary:
	if FileAccess.get_sha256(MAP00_MANIFEST_PATH) != MAP00_MANIFEST_SHA256:
		return {"ok": false, "error": "Selector-$%02X field manifest hash differs from the pinned ROM extraction." % selector}
	var manifest_text := FileAccess.get_file_as_string(MAP00_MANIFEST_PATH)
	var parsed: Variant = JSON.parse_string(manifest_text)
	if not parsed is Dictionary:
		return {"ok": false, "error": "Selector-$%02X field manifest is not valid JSON." % selector}
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "first-command-page-correct-field-map-sources-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "Selector-$%02X field manifest does not identify the pinned ROM source." % selector}
	var entries_variant: Variant = manifest.get("entries", [])
	if not entries_variant is Array:
		return {"ok": false, "error": "Selector-$%02X field manifest has no source entry table." % selector}
	var entries_by_path: Dictionary = {}
	for entry_variant in entries_variant:
		if entry_variant is Dictionary:
			entries_by_path[String(entry_variant.get("path", ""))] = entry_variant
	var source: Dictionary = {}
	var source_hashes := {"map_manifest": MAP00_MANIFEST_SHA256}
	var block_path := "block_map_%02X_selector_%02X.bin" % [map_id, selector]
	var block_entry_variant: Variant = entries_by_path.get(block_path, {})
	if not block_entry_variant is Dictionary:
		return {"ok": false, "error": "Map-$%02X block-map entry is missing from the pinned manifest." % map_id}
	var block_entry: Dictionary = block_entry_variant
	var expected_map_cpu_address := 0x8B64 + ((map_id >> 3) << 8) + ((map_id & 0x07) << 5)
	var expected_map_file_offset := 0x016010 + expected_map_cpu_address - 0x8000
	if String(block_entry.get("block_map_id", "")) != "0x%02X" % map_id \
		or String(block_entry.get("selector", "")) != "0x%02X" % selector \
			or String(block_entry.get("cpu_address", "")) != "0x%04X" % expected_map_cpu_address \
			or String(block_entry.get("file_offset", "")) != "0x%06X" % expected_map_file_offset \
			or int(block_entry.get("size_bytes", -1)) != 0x20:
		return {"ok": false, "error": "Map-$%02X block-map provenance fields differ from its ROM pointer formula." % map_id}
	var block_path_full := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/" + block_path
	var block_map := FileAccess.get_file_as_bytes(block_path_full)
	if block_map.size() != 0x20 or FileAccess.get_sha256(block_path_full) != String(block_entry.get("sha256", "")):
		return {"ok": false, "error": "Map-$%02X block-map bytes failed manifest size/hash validation." % map_id}
	source["block_map"] = block_map
	source_hashes["block_map_%02X" % map_id] = String(block_entry["sha256"])
	for block_id_variant in block_map:
		var block_id := int(block_id_variant)
		var id_key := "%02X" % block_id
		for suffix: String in ["tiles", "attribute"]:
			var filename := "map_%02X_metatile_%s_%s.bin" % [map_id, id_key, suffix]
			var row_variant: Variant = entries_by_path.get(filename, {})
			if not row_variant is Dictionary:
				return {"ok": false, "error": "Map-$%02X metatile `$%02X` %s row is missing." % [map_id, block_id, suffix]}
			var row: Dictionary = row_variant
			var tile_window_offset := (selector << 12) + (block_id * 0x10)
			var expected_cpu := (0xA000 + (tile_window_offset & 0x1FFF)) if suffix == "tiles" else (0x9BE4 + (selector << 8) + block_id)
			var expected_offset := (0x024010 + tile_window_offset) if suffix == "tiles" else (0x017BF4 + (selector << 8) + block_id)
			var expected_size := 0x10 if suffix == "tiles" else 1
			if String(row.get("block_map_id", "")) != "0x%02X" % map_id \
				or String(row.get("selector", "")) != "0x%02X" % selector \
				or String(row.get("metatile_id", "")) != "0x%02X" % block_id \
				or String(row.get("cpu_address", "")) != "0x%04X" % expected_cpu \
				or String(row.get("file_offset", "")) != "0x%06X" % expected_offset \
				or int(row.get("size_bytes", -1)) != expected_size:
				return {"ok": false, "error": "Map-$%02X metatile `$%02X` %s provenance does not match the selector-$%02X address formula." % [map_id, block_id, suffix, selector]}
			var path := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/" + filename
			var bytes := FileAccess.get_file_as_bytes(path)
			if bytes.size() != expected_size or FileAccess.get_sha256(path) != String(row.get("sha256", "")):
				return {"ok": false, "error": "Map-$%02X metatile `$%02X` %s bytes failed manifest size/hash validation." % [map_id, block_id, suffix]}
			source["%s_%s" % ["tiles" if suffix == "tiles" else "attribute", id_key]] = bytes
			source_hashes["metatile_%s_%s" % [id_key, suffix]] = String(row["sha256"])
	var shared_specs := {
		"worker": [WORKER_PATH, WORKER_SHA256, 0x50],
		"expand": [EXPAND_PATH, EXPAND_SHA256, 0x111],
	}
	for key: String in shared_specs:
		var spec: Array = shared_specs[key]
		var bytes := FileAccess.get_file_as_bytes(String(spec[0]))
		if bytes.size() != int(spec[2]) or FileAccess.get_sha256(String(spec[0])) != String(spec[1]):
			return {"ok": false, "error": "Map-$%02X shared worker source failed size/hash validation: %s" % [map_id, String(spec[0])]}
		source[key] = bytes
	source["source_hashes"] = source_hashes
	return {"ok": true, "source": source, "source_hashes": source_hashes}


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


func _expected_batch_metatiles(map_id: int, start_index: int) -> PackedByteArray:
	if map_id == 0x11:
		return PackedByteArray()
	if map_id == 0x43:
		match start_index:
			0, 3, 24, 27: return PackedByteArray([0x14, 0x14, 0x14])
			6: return PackedByteArray([0x14, 0x14, 0x33])
			9: return PackedByteArray([0x33, 0x2F, 0x33])
			12: return PackedByteArray([0xED, 0x33, 0x34])
			15: return PackedByteArray([0x33, 0x15, 0x16])
			18: return PackedByteArray([0x15, 0xEA, 0xEC])
			21: return PackedByteArray([0x16, 0x15, 0x16])
			30: return PackedByteArray([0x14, 0x14])
		return PackedByteArray()
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
		0x2F: return METATILE_2F_TILES_SHA256
		0x14: return METATILE_TILES_SHA256
		0x15: return METATILE_15_TILES_SHA256
		0x16: return METATILE_16_TILES_SHA256
		0x33: return METATILE_33_TILES_SHA256
		0xEA: return METATILE_EA_TILES_SHA256
		0xEB: return METATILE_EB_TILES_SHA256
		0x34: return METATILE_34_TILES_SHA256
		0xEC: return METATILE_EC_TILES_SHA256
		0xED: return METATILE_ED_TILES_SHA256
	return ""


func _metatile_attribute_sha256(block_id: int) -> String:
	match block_id:
		0x2F: return METATILE_2F_ATTRIBUTE_SHA256
		0x14: return METATILE_ATTRIBUTE_SHA256
		0x15: return METATILE_15_ATTRIBUTE_SHA256
		0x16: return METATILE_16_ATTRIBUTE_SHA256
		0x33: return METATILE_33_ATTRIBUTE_SHA256
		0xEA: return METATILE_EA_ATTRIBUTE_SHA256
		0xEB: return METATILE_EB_ATTRIBUTE_SHA256
		0x34: return METATILE_34_ATTRIBUTE_SHA256
		0xEC: return METATILE_EC_ATTRIBUTE_SHA256
		0xED: return METATILE_ED_ATTRIBUTE_SHA256
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
