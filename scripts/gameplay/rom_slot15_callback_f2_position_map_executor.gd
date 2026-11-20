extends RefCounted
class_name RomSlot15CallbackF2PositionMapExecutor
## Executes callback `$72`'s `$F2` control route from `$814C` through the
## holder-relative map selection and into the shared worker at `$8525`.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CONTROL_ROOT := "res://reference/rom_extract/gameplay/first_command_field/callback_f2_control/"
const DISPATCH_ROOT := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/"
const POSITIONS_ROOT := "res://reference/rom_extract/gameplay/first_command_field/player_record_positions/"
const SCENARIO_ROOT := "res://reference/rom_extract/gameplay/scenario36_fd00_mirror/"
const FIXED_WORKER_ROOT := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/"
const TRAMPOLINE_ROOT := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/"
const MAP_SELECTOR_ROOT := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/"
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_C := 0x01
const P_Z := 0x02
const P_V := 0x40
const P_N := 0x80
const P_NZ := P_N | P_Z
const P_CVNZ := P_C | P_V | P_N | P_Z

const SOURCE_SPECS := {
	"dispatcher": [DISPATCH_ROOT + "bank_0b_dispatcher_814c_81a6.bin", 91, "c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6"],
	"callback_pointer": [DISPATCH_ROOT + "bank_0b_event_72_pointer.bin", 2, "97cff6d36c832c828115df1ffd59b87b00aa1a1bcbe5d81a65bad438687ea59a"],
	"callback_01_pointer": [DISPATCH_ROOT + "bank_0b_event_01_pointer_boundary.bin", 4, "353ac46a0f0784e23d33906840fbee88130f649ae7a70061cd4ecc47746b25aa"],
	"callback_01_stream": [DISPATCH_ROOT + "bank_0b_event_01_stream.bin", 1, "fde502858306c235a3121e42326b53228b7ef4690eeed92a2b2eafe73c03a3ef"],
	"control_vector": [CONTROL_ROOT + "bank_0b_control_dispatch_81bc_81cc.bin", 16, "3b2227a888e3fd009e9424dc707ff4bf84e3b67780bb2b7bcaca1637a5ec58aa"],
	"control_map_entry": [CONTROL_ROOT + "bank_0b_control_map_entry_81cc_81d5.bin", 9, "f226d993329fa907bdb11ff0bc336fb19e5307928e469347f2ee24a811718528"],
	"control_map_lookup": [CONTROL_ROOT + "bank_0b_control_map_lookup_81d5_824d.bin", 120, "ae4dd691e5f708b402cf886d6b83abad73c5119bf80d75d40d78b1f70d2524cf"],
	"position_entry": [CONTROL_ROOT + "bank_0b_position_map_entry_82f7_82fe.bin", 7, "8b82b02a9c95a0a72f19fa02665f4d5214f1bb5cf50d7937e02d2ceea5d887af"],
	"position_handler": [CONTROL_ROOT + "bank_0b_position_map_handler_824d_827f.bin", 50, "6f616bc8cc0ef15e25703cedee73678fc54678bf3ee085d381448fb1285e7181"],
	"position_lookup": [CONTROL_ROOT + "bank_0b_position_map_lookup_827f_82f7.bin", 120, "0afc2355fe2554eb66a383d198c828fc379167aa1a7bd6bc0d030e032279e7bf"],
	"position_helper": [CONTROL_ROOT + "bank_0b_position_map_index_helper_82fe_8327.bin", 41, "114b9799d2d9f076eb4cff9311613157ff63809527ec8e643468821abb310359"],
	"control_byte": [CONTROL_ROOT + "bank_0b_event_72_control_f2.bin", 1, "966c7c47125c74575a9a1153b799faf55be33a04e3d9f98760a3eeac377103df"],
	"map00_chr_pair": [CONTROL_ROOT + "bank_0b_map_00_chr_pair_86ee_86f0.bin", 2, "cab590fcde8cf68ac09914f68ae356b7ca9587e2366db966ad506569d6603a19"],
	"record_pointers": [POSITIONS_ROOT + "bank_1f_cd89_record_pointer_table_22.bin", 44, "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"],
	"record_pointer_helper": [POSITIONS_ROOT + "bank_1f_cd7c_record_pointer_lookup_code.bin", 13, "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24"],
	"c50c_vector": [SCENARIO_ROOT + "fixed_record_pointer_vector_C50C_C50F.bin", 3, "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44"],
	"c536_vector": [SCENARIO_ROOT + "fixed_value_div12_vector_C536_C539.bin", 3, "45c5f5dc3181044f55e152be9dd6ec1c7f9664fb4a87340dc5ac758ccc0bc775"],
	"div12_helper": [SCENARIO_ROOT + "fixed_value_div12_helper_CDC9_CDE2.bin", 25, "45eb9e048e38d5655178886e5c61d4245720493c9044e2acc2f180f8c76eba7c"],
	"c509_jump": [FIXED_WORKER_ROOT + "fixed_dispatch_C509_C50C.bin", 3, "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"],
	"cb99_trampoline": [TRAMPOLINE_ROOT + "fixed_branch_table_dispatch_CB99_CBAF.bin", 23, "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"],
	"packed_selectors": [MAP_SELECTOR_ROOT + "packed_map_selectors_8B42.bin", 34, "2dac66189d5f3d9e733016f5005bb1b667822781cf5be50e27753f3b814c170e"],
}

var error_message := ""


func execute_from_callback_dispatcher(entry_result: Dictionary) -> Dictionary:
	error_message = ""
	var loaded := _load_sources()
	if not bool(loaded.get("ok", false)):
		return _failure(String(loaded.get("error", "Callback-$72 source loading failed.")))
	var source: Dictionary = loaded["source"]
	var entry_variant: Variant = entry_result.get("dispatcher_dispatch", {})
	var ram_variant: Variant = entry_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = entry_result.get("stack_page", PackedByteArray())
	if not entry_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _failure("Callback-$72 entry omits CPU, RAM, or stack state.")
	var cpu: Dictionary = entry_variant.duplicate(true)
	var dispatch_entry: Dictionary = entry_variant
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var callback_id := int(ram[0x0524]) if ram.size() == RAM_SIZE else -1
	var scenario_id := int(ram[0x0518]) if ram.size() == RAM_SIZE else -1
	var scenario18_pass_profile := scenario_id == 0x18 \
			and int(ram[0x0523]) == 0x3C and int(ram[0x0528]) == 0x66 \
			and int(ram[0x0529]) == 0x47
	var scenario36_profile := scenario_id == 0x36 \
			and int(ram[0x0523]) == 0x32 and int(ram[0x0528]) == 0x66 \
			and int(ram[0x0529]) == 0xFF
	if String(entry_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(entry_result.get("status", "")) != "reached_callback_dispatcher_entry" \
			or int(entry_result.get("exit_pc", -1)) != 0x814C \
			or int(cpu.get("pc", -1)) != 0x814C or int(dispatch_entry.get("slot_base", -1)) != 0x15 \
			or int(dispatch_entry.get("bank_low", -1)) != 0x0B \
			or int(dispatch_entry.get("bank_high", -1)) != 0x0C \
			or callback_id != 0x72 or not (scenario18_pass_profile or scenario36_profile) \
			or ram.size() != RAM_SIZE \
			or stack.size() != STACK_SIZE:
		return _failure("Input is not a source-verified scenario-$18 PASS or scenario-$36 callback-$72 entry at `$814C`.")
	if not _source_matches(source):
		return _failure("Callback-$72 source bytes do not match the checked F2 dispatcher and map routine.")

	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var executed_pcs: Array[int] = []

	# `$814C` resolves callback `$72` through the bank-$0B pointer table.
	executed_pcs.append_array([0x814C, 0x814E, 0x8150, 0x8152, 0x8154, 0x8157, 0x8159, 0x815B, 0x815C])
	_set_a(cpu, 0xF6); _write_ram(ram, writes, 0x814E, 0x0052, int(cpu["a"]))
	_set_a(cpu, 0x87); _write_ram(ram, writes, 0x8152, 0x0053, int(cpu["a"]))
	_set_a(cpu, callback_id)
	_cmp(cpu, int(cpu["a"]), 0xFF)
	if callback_id == 0xFF:
		return _failure("Callback `$FF` takes a different `$8159` sentinel route.")
	var callback_index := (callback_id << 1) & 0xFF
	_set_c(cpu, (int(cpu["a"]) & 0x80) != 0)
	_set_a(cpu, callback_index)
	_set_c(cpu, false) # source `$815E CLC`
	_set_y(cpu, int(cpu["a"]))
	var pointer_table_address := 0x87F6 + int(cpu["y"])
	var pointer_bytes: PackedByteArray = source["callback_pointer"]
	if pointer_table_address != 0x88DA or pointer_bytes != PackedByteArray([0x3E, 0x8B]):
		return _failure("Callback `$72` pointer-table lookup no longer resolves `$88DA->$8B3E`.")
	source_reads.append(_read(0x8161, pointer_table_address, int(pointer_bytes[0]), "callback_72_pointer_low"))
	_set_a(cpu, int(pointer_bytes[0])); _set_x(cpu, int(cpu["a"]))
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	source_reads.append(_read(0x8165, pointer_table_address + 1, int(pointer_bytes[1]), "callback_72_pointer_high"))
	_set_a(cpu, int(pointer_bytes[1]))
	_write_ram(ram, writes, 0x8167, 0x0053, int(cpu["a"]))
	_write_ram(ram, writes, 0x8169, 0x0052, int(cpu["x"]))
	_set_a(cpu, 0)
	_write_ram(ram, writes, 0x816D, 0x05D1, 0)
	_write_ram(ram, writes, 0x8170, 0x003A, 0)
	_set_y(cpu, int(ram[0x003A]))
	var control_byte := int(source["control_byte"][0])
	source_reads.append(_read(0x8174, 0x8B3E, control_byte, "callback_72_control"))
	_set_a(cpu, control_byte)
	_cmp(cpu, int(cpu["a"]), 0xF0)
	if control_byte < 0xF0:
		return _failure("Callback `$72` no longer selects the source `$817A` control branch.")

	# `$817A->$81BC->$C509->$CB99` dispatches F2's low nibble 2 to `$824D`.
	executed_pcs.append_array([0x817A, 0x81BC, 0x81BE, 0x81C1, 0x81C3, 0xC509, 0xCB99])
	_push_jsr(cpu, stack, stack_writes, 0x817A, 0x81BC)
	_set_x(cpu, 0); _write_ram(ram, writes, 0x81BE, 0x0525, 0)
	_set_a(cpu, int(cpu["a"]) & 0x0F)
	if int(cpu["a"]) != 2:
		return _failure("Callback `$72` F2 control nibble is not vector row 2.")
	_push_jsr(cpu, stack, stack_writes, 0x81C3, 0xC509)
	_asl_a(cpu); _set_y(cpu, int(cpu["a"]))
	var trampoline_low := _pop(cpu, stack, stack_reads, 0xCB9B)
	_write_ram(ram, writes, 0xCB9B, 0x0036, trampoline_low)
	var trampoline_high := _pop(cpu, stack, stack_reads, 0xCB9E)
	_write_ram(ram, writes, 0xCB9E, 0x0037, trampoline_high)
	if (trampoline_high << 8 | trampoline_low) != 0x81C5:
		return _failure("The inline dispatcher did not recover its `$81C5` return-minus-one base.")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_low_address := 0x81C5 + int(cpu["y"])
	var vector_low := int(source["control_vector"][vector_low_address - 0x81BC])
	source_reads.append(_read(0xCB99, vector_low_address, vector_low, "f2_vector_low"))
	_push(cpu, stack, stack_writes, vector_low, 0xCBA4, "inline_vector_low")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_high_address := 0x81C5 + int(cpu["y"])
	var vector_high := int(source["control_vector"][vector_high_address - 0x81BC])
	source_reads.append(_read(0xCB99, vector_high_address, vector_high, "f2_vector_high"))
	_write_ram(ram, writes, 0xCBA8, 0x0037, vector_high)
	var popped_vector_low := _pop(cpu, stack, stack_reads, 0xCBAA)
	_write_ram(ram, writes, 0xCBAB, 0x0036, popped_vector_low)
	var handler_pc := int(ram[0x0036]) | (int(ram[0x0037]) << 8)
	if handler_pc != 0x824D or vector_low != 0x4D or vector_high != 0x82:
		return _failure("F2's inline vector no longer resolves to `$824D`.")
	cpu["pc"] = handler_pc

	# `$824D->$CDC9` resolves the holder's match-zero record and divides live $0638 by 12.
	executed_pcs.append_array([0x824D, 0x8250, 0xC50C, 0xCD7C])
	_set_a(cpu, int(ram[0x0441]))
	var holder_id := int(cpu["a"])
	if holder_id >= 22:
		return _failure("Live `$0441` holder ID lies outside the 22-entry `$CD89` record table.")
	_push_jsr(cpu, stack, stack_writes, 0x8250, 0xC50C)
	var record_pointer_bytes: PackedByteArray = source["record_pointers"]
	var record_low := int(record_pointer_bytes[holder_id * 2])
	var record_high := int(record_pointer_bytes[holder_id * 2 + 1])
	var record_address := record_low | (record_high << 8)
	if record_address != 0x0300 + holder_id * 0x0C:
		return _failure("ROM `$CD89` pointer does not match the live holder record layout.")
	source_reads.append(_read(0xCD7E, 0xCD89 + holder_id * 2, record_low, "holder_record_pointer_low"))
	source_reads.append(_read(0xCD83, 0xCD8A + holder_id * 2, record_high, "holder_record_pointer_high"))
	_set_a(cpu, record_low); _write_ram(ram, writes, 0xCD81, 0x0034, int(cpu["a"]))
	_set_a(cpu, record_high); _write_ram(ram, writes, 0xCD86, 0x0035, int(cpu["a"]))
	if not _rts(cpu, stack, stack_reads, 0xCD88, 0x8253):
		return _failure("ROM `$CD7C` did not return to the callback's `$8252` continuation.")

	executed_pcs.append_array([0x8253, 0x8256, 0xC536, 0xCDC9])
	_set_a(cpu, int(ram[0x0638]))
	_push_jsr(cpu, stack, stack_writes, 0x8256, 0xC536)
	_execute_div12(cpu, int(cpu["a"]), executed_pcs)
	if not _rts(cpu, stack, stack_reads, 0xCDC9, 0x8259):
		return _failure("ROM `$CDC9` did not return to `$8258`.")

	# Compare the holder-relative X field and apply the ROM mirror-side adjustment.
	executed_pcs.append_array([0x8259, 0x825A, 0x825C, 0x825D, 0x825F, 0x8262])
	_set_a(cpu, int(cpu["x"]))
	_set_y(cpu, 0x06)
	_set_c(cpu, true)
	var record_x := int(ram[record_address + 6])
	source_reads.append(_read(0x825D, record_address + 6, record_x, "holder_record_x"))
	_sbc(cpu, record_x)
	_set_y(cpu, int(ram[0x05FB]))
	if int(cpu["y"]) != 0:
		executed_pcs.append_array([0x8264, 0x8266, 0x8267])
		_set_a(cpu, int(cpu["a"]) ^ 0xFF)
		_set_c(cpu, false)
		_adc(cpu, 0x01)
	executed_pcs.append_array([0x8269, 0x826A])
	_set_x(cpu, int(cpu["a"]))
	if (int(cpu["p"]) & P_N) != 0:
		executed_pcs.append_array([0x826C, 0x826D, 0x826F])
		_set_a(cpu, int(cpu["y"]))
		_set_a(cpu, int(cpu["a"]) ^ 0x0B)
		_set_y(cpu, int(cpu["a"]))

	# `$82FE` maps live holder coordinates to the ROM's 120-byte map-ID table.
	executed_pcs.append_array([0x8270, 0x82FE])
	_push_jsr(cpu, stack, stack_writes, 0x8270, 0x82FE)
	var position_index := _execute_position_index(cpu, ram, writes, executed_pcs)
	if not _rts(cpu, stack, stack_reads, 0x8326, 0x8273):
		return _failure("ROM `$82FE` did not return to `$8273`.")
	if position_index < 0 or position_index >= int(source["position_lookup"].size()):
		return _failure("ROM coordinate transform selected an out-of-range map lookup row.")
	executed_pcs.append_array([0x8273, 0x8279, 0x827C])
	_set_a(cpu, int(source["position_lookup"][position_index]))
	var map_id := int(cpu["a"])
	source_reads.append(_read(0x8279, 0x827F + position_index, map_id, "position_map_lookup"))
	cpu["pc"] = 0x832B
	_write_ram(ram, writes, 0x832B, 0x05CC, map_id)
	_set_y(cpu, int(ram[0x05CD]))
	_push_jsr(cpu, stack, stack_writes, 0x8331, 0x8525)
	cpu["pc"] = 0x8525
	for offset in stack.size():
		ram[0x0100 + offset] = stack[offset]

	var final_mapper: Dictionary = {"bank_low": int(dispatch_entry.get("bank_low", -1)),
		"bank_high": int(dispatch_entry.get("bank_high", -1)), "select": 7}
	return {
		"ok": true,
		"status": "entered_map_worker_8525",
		"rom_sha256": ROM_SHA256,
		"source_hashes": loaded["hashes"],
		"entry_pc": 0x814C,
		"exit_pc": 0x8525,
		"entry_registers": entry_cpu,
		"registers": cpu,
		"mapper": final_mapper,
		"entry_ram_image": entry_ram,
		"ram_image": ram,
		"entry_stack_page": entry_stack,
		"stack_page": stack,
		"ram_writes": writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": executed_pcs,
		"callback_id": 0x72,
		"callback_stream_address": 0x8B3E,
		"callback_bytes": PackedByteArray([0xF2]),
		"map_id": map_id,
		"map_selector": map_id,
		"map_position_index": position_index,
		"placement_input": int(ram[0x05CD]),
		"holder_id": holder_id,
		"holder_record_address": record_address,
		"worker_body_executed": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
	}


## Executes callback `$01`'s `$F0` control-vector row zero through the ROM map
## lookup and into `$8525`. This is the source path reached by the fresh
## match route; it does not borrow the callback-$72 holder-relative selector.
func execute_callback_01_from_dispatcher(entry_result: Dictionary) -> Dictionary:
	error_message = ""
	var loaded := _load_sources()
	if not bool(loaded.get("ok", false)):
		return _failure(String(loaded.get("error", "Callback-$01 source loading failed.")))
	var source: Dictionary = loaded["source"]
	var dispatch_variant: Variant = entry_result.get("dispatcher_dispatch", {})
	var ram_variant: Variant = entry_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = entry_result.get("stack_page", PackedByteArray())
	if not dispatch_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _failure("Callback-$01 entry omits CPU, RAM, or stack state.")
	var cpu: Dictionary = dispatch_variant.duplicate(true)
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE:
		return _failure("Callback-$01 entry must carry the complete live RAM and stack pages.")
	var scenario36_callback01_profile: bool = int(ram[0x0518]) == 0x36 \
		and int(ram[0x0523]) == 0x3E and int(ram[0x0524]) == 0x01 \
		and int(ram[0x0528]) == 0xE6 and int(ram[0x0529]) == 0x75 \
		and int(ram[0x052B]) == 0x00 and int(ram[0x003A]) == 0x07 \
		and (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) == 0xB809
	var scenario1c_callback01_profile: bool = \
		ram.slice(0x0516, 0x052C) == PackedByteArray([
			0x61, 0x40, 0x1C, 0x27, 0xE8, 0x9B, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x3C, 0x01, 0x02,
			0x3C, 0x4A, 0x78, 0x58, 0x40, 0x00]) \
		and int(ram[0x003A]) == 0x07 \
		and (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) == 0xB4A5 \
		and int(ram[0x05CD]) == 0xA0 and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54
	if String(entry_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(entry_result.get("status", "")) != "reached_callback_dispatcher_entry" \
			or int(entry_result.get("exit_pc", -1)) != 0x814C \
			or int(cpu.get("pc", -1)) != 0x814C \
			or int(dispatch_variant.get("slot_base", -1)) != 0x15 \
			or int(dispatch_variant.get("bank_low", -1)) != 0x0B \
			or int(dispatch_variant.get("bank_high", -1)) != 0x0C \
			or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or not (scenario36_callback01_profile or scenario1c_callback01_profile):
		return _failure("Input is not a supported live scenario-$36 or scenario-$1C callback-$01 entry at `$814C`.")
	if not _callback_01_sources_match(source):
		return _failure("Callback-$01 `$F0` control/map bytes differ from the checked ROM spans.")

	var entry_cpu := cpu.duplicate(true)
	var entry_ram: PackedByteArray = ram.duplicate()
	var entry_stack: PackedByteArray = stack.duplicate()
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var executed_pcs: Array[int] = []

	# `$814C` reads callback `$01` from `$87F8`, then follows its `$F0` byte.
	executed_pcs.append_array([0x814C, 0x814E, 0x8150, 0x8152, 0x8154, 0x8157,
		0x8159, 0x815B, 0x815C, 0x815E, 0x8160, 0x8161, 0x8163, 0x8164,
		0x8165, 0x8167, 0x8169, 0x816B, 0x816D, 0x8170, 0x8172, 0x8174,
		0x8176, 0x8178, 0x817A])
	_set_a(cpu, 0xF6); _write_ram(ram, writes, 0x814E, 0x0052, int(cpu["a"]))
	_set_a(cpu, 0x87); _write_ram(ram, writes, 0x8152, 0x0053, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0524])); _cmp(cpu, int(cpu["a"]), 0xFF)
	_set_c(cpu, false); _set_a(cpu, (int(cpu["a"]) << 1) & 0xFF)
	_set_y(cpu, int(cpu["a"]))
	var pointer_table_address := 0x87F6 + int(cpu["y"])
	var pointer_bytes: PackedByteArray = source["callback_01_pointer"]
	var pointer_offset := pointer_table_address - 0x87F8
	var pointer_low := int(pointer_bytes[pointer_offset])
	var pointer_high := int(pointer_bytes[pointer_offset + 1])
	if pointer_table_address != 0x87F8 or pointer_low != 0xE3 or pointer_high != 0x88:
		return _failure("Callback `$01` pointer-table lookup no longer resolves `$87F8->$88E3`.")
	source_reads.append(_read(0x8161, pointer_table_address, pointer_low, "callback_01_pointer_low"))
	_set_a(cpu, pointer_low); _set_x(cpu, int(cpu["a"]))
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	source_reads.append(_read(0x8165, pointer_table_address + 1, pointer_high, "callback_01_pointer_high"))
	_set_a(cpu, pointer_high)
	_write_ram(ram, writes, 0x8167, 0x0053, int(cpu["a"]))
	_write_ram(ram, writes, 0x8169, 0x0052, int(cpu["x"]))
	_set_a(cpu, 0); _write_ram(ram, writes, 0x816D, 0x05D1, 0)
	_write_ram(ram, writes, 0x8170, 0x003A, 0); _set_y(cpu, int(ram[0x003A]))
	var callback_byte := int(source["callback_01_stream"][int(cpu["y"])])
	source_reads.append(_read(0x8174, 0x88E3, callback_byte, "callback_01_control_byte"))
	_set_a(cpu, callback_byte); _cmp(cpu, int(cpu["a"]), 0xF0)
	if callback_byte != 0xF0:
		return _failure("Callback `$01` no longer selects control byte `$F0`.")

	# The `$F0` low nibble selects inline vector row zero at `$81C6/$81C7`.
	executed_pcs.append_array([0x81BC, 0x81BE, 0x81C1, 0x81C3, 0xC509, 0xCB99])
	_push_jsr(cpu, stack, stack_writes, 0x817A, 0x81BC)
	_set_x(cpu, 0); _write_ram(ram, writes, 0x81BE, 0x0525, 0)
	_set_a(cpu, int(cpu["a"]) & 0x0F)
	if int(cpu["a"]) != 0:
		return _failure("Callback `$01` F0 control nibble is not vector row zero.")
	_push_jsr(cpu, stack, stack_writes, 0x81C3, 0xC509)
	_set_y(cpu, 0)
	var trampoline_low := _pop(cpu, stack, stack_reads, 0xCB9B)
	_write_ram(ram, writes, 0xCB9B, 0x0036, trampoline_low)
	var trampoline_high := _pop(cpu, stack, stack_reads, 0xCB9E)
	_write_ram(ram, writes, 0xCB9E, 0x0037, trampoline_high)
	if (trampoline_high << 8 | trampoline_low) != 0x81C5:
		return _failure("Callback `$01` trampoline did not recover its `$81C5` return-minus-one base.")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_low_address := 0x81C5 + int(cpu["y"])
	var vector_low := int(source["control_vector"][vector_low_address - 0x81BC])
	source_reads.append(_read(0xCB99, vector_low_address, vector_low, "callback_01_vector_low"))
	_set_a(cpu, vector_low); _push(cpu, stack, stack_writes, int(cpu["a"]), 0xCBA4, "inline_vector_low")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_high_address := 0x81C5 + int(cpu["y"])
	var vector_high := int(source["control_vector"][vector_high_address - 0x81BC])
	source_reads.append(_read(0xCB99, vector_high_address, vector_high, "callback_01_vector_high"))
	_write_ram(ram, writes, 0xCBA8, 0x0037, vector_high)
	var popped_vector_low := _pop(cpu, stack, stack_reads, 0xCBAA)
	_write_ram(ram, writes, 0xCBAB, 0x0036, popped_vector_low)
	var handler_pc := int(ram[0x0036]) | (int(ram[0x0037]) << 8)
	if handler_pc != 0x81CC or vector_low != 0xCC or vector_high != 0x81:
		return _failure("Callback `$01` F0 vector no longer resolves to `$81CC`.")
	cpu["pc"] = handler_pc

	# `$81CC` calls `$82F7`; that wrapper seeds Y from `$05FB` and runs the
	# shared ROM coordinate-index helper before indexing the control map table.
	executed_pcs.append_array([0x81CC, 0x82F7, 0x82FA, 0x82FE])
	_push_jsr(cpu, stack, stack_writes, 0x81CC, 0x82F7)
	var position_input := int(ram[0x05FB])
	source_reads.append(_read(0x82F7, 0x05FB, position_input, "callback_01_position_input"))
	_set_y(cpu, position_input)
	_push_jsr(cpu, stack, stack_writes, 0x82FA, 0x82FE)
	var position_index := _execute_position_index(cpu, ram, writes, executed_pcs)
	if not _rts(cpu, stack, stack_reads, 0x8326, 0x82FD) \
			or not _rts(cpu, stack, stack_reads, 0x82FD, 0x81CF):
		return _failure("Callback `$01` coordinate helper did not return to `$81CF`.")
	if position_index < 0 or position_index >= int(source["control_map_lookup"].size()):
		return _failure("Callback `$01` selected an out-of-range ROM control-map index.")
	executed_pcs.append_array([0x81CF, 0x81D2, 0x81D5])
	var map_id := int(source["control_map_lookup"][position_index])
	_set_a(cpu, map_id)
	source_reads.append(_read(0x81CF, 0x81D5 + position_index, map_id, "callback_01_control_map_lookup"))
	if scenario1c_callback01_profile and (position_index != 0x05 or map_id != 0x12):
		return _failure("Scenario-$1C callback `$01` coordinates no longer resolve index `$05` to ROM map `$12`.")
	executed_pcs.append_array([0x832B, 0x832E, 0x8331])
	cpu["pc"] = 0x832B
	_write_ram(ram, writes, 0x832B, 0x05CC, map_id)
	_set_y(cpu, int(ram[0x05CD]))
	_push_jsr(cpu, stack, stack_writes, 0x8331, 0x8525)
	cpu["pc"] = 0x8525
	for index in stack.size():
		ram[0x0100 + index] = stack[index]

	return {
		"ok": true,
		"status": "entered_map_worker_8525",
		"rom_sha256": ROM_SHA256,
		"source_hashes": loaded["hashes"],
		"entry_pc": 0x814C,
		"exit_pc": 0x8525,
		"entry_registers": entry_cpu,
		"registers": cpu,
		"mapper": {"bank_low": int(dispatch_variant.get("bank_low", -1)),
			"bank_high": int(dispatch_variant.get("bank_high", -1)), "select": 7},
		"entry_ram_image": entry_ram,
		"ram_image": ram,
		"entry_stack_page": entry_stack,
		"stack_page": stack,
		"ram_writes": writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": executed_pcs,
		"callback_id": 0x01,
		"callback_stream_address": 0x88E3,
		"callback_bytes": PackedByteArray([0xF0]),
		"map_id": map_id,
		"map_selector": map_id,
		"map_position_index": position_index,
		"placement_input": int(ram[0x05CD]),
		"position_input": position_input,
		"holder_id": -1,
		"holder_record_address": -1,
		"worker_body_executed": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
	}


func _load_sources() -> Dictionary:
	var source: Dictionary = {}
	var hashes: Dictionary = {}
	for name_variant in SOURCE_SPECS:
		var name := String(name_variant)
		var spec: Array = SOURCE_SPECS[name]
		var path := String(spec[0])
		if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path).size() != int(spec[1]) \
				or FileAccess.get_sha256(path) != String(spec[2]):
			return {"ok": false, "error": "F2 route source failed size/hash validation: %s" % path}
		source[name] = FileAccess.get_file_as_bytes(path)
		hashes[name] = String(spec[2])
	return {"ok": true, "source": source, "hashes": hashes}


func _callback_01_sources_match(source: Dictionary) -> bool:
	return source["dispatcher"].slice(0x2E, 0x31) == PackedByteArray([0x20, 0xBC, 0x81]) \
			and source["callback_01_pointer"] == PackedByteArray([0xE3, 0x88, 0xE4, 0x88]) \
			and source["callback_01_stream"] == PackedByteArray([0xF0]) \
			and source["control_vector"] == PackedByteArray([
			0xA2, 0x00, 0x8E, 0x25, 0x05, 0x29, 0x0F, 0x20, 0x09, 0xC5,
			0xCC, 0x81, 0x76, 0x82, 0x4D, 0x82]) \
			and source["control_map_entry"] == PackedByteArray([0x20, 0xF7, 0x82, 0xBD, 0xD5, 0x81, 0x4C, 0x2B, 0x83]) \
			and source["position_entry"] == PackedByteArray([0xAC, 0xFB, 0x05, 0x20, 0xFE, 0x82, 0x60]) \
			and source["position_helper"].size() == 41


func _source_matches(source: Dictionary) -> bool:
	return source["dispatcher"].slice(0x2E, 0x31) == PackedByteArray([0x20, 0xBC, 0x81]) \
			and source["control_vector"] == PackedByteArray([
			0xA2, 0x00, 0x8E, 0x25, 0x05, 0x29, 0x0F, 0x20, 0x09, 0xC5,
			0xCC, 0x81, 0x76, 0x82, 0x4D, 0x82]) \
			and source["position_handler"].slice(0, 3) == PackedByteArray([0xAD, 0x41, 0x04]) \
			and source["position_handler"].slice(0x23, 0x32) == PackedByteArray([
			0x20, 0xFE, 0x82, 0x4C, 0x79, 0x82, 0x20, 0xF7, 0x82, 0xBD, 0x7F, 0x82, 0x4C, 0x2B, 0x83]) \
			and source["position_helper"].slice(0, 3) == PackedByteArray([0xAD, 0x37, 0x06]) \
			and source["control_byte"] == PackedByteArray([0xF2]) \
			and source["map00_chr_pair"] == PackedByteArray([0x3C, 0x4A]) \
			and source["record_pointer_helper"] == PackedByteArray([0x0A, 0xA8, 0xB9, 0x89, 0xCD, 0x85, 0x34, 0xB9, 0x8A, 0xCD, 0x85, 0x35, 0x60]) \
			and source["c50c_vector"] == PackedByteArray([0x4C, 0x7C, 0xCD]) \
			and source["c536_vector"] == PackedByteArray([0x4C, 0xC9, 0xCD]) \
			and source["c509_jump"] == PackedByteArray([0x4C, 0x99, 0xCB])


func _execute_div12(cpu: Dictionary, value: int, executed_pcs: Array[int]) -> void:
	var remainder := value & 0xFF
	var quotient := 0
	executed_pcs.append_array([0xCDC9, 0xCDCB, 0xCDCD])
	_set_x(cpu, 0)
	while remainder >= 0x0C:
		executed_pcs.append_array([0xCDCF, 0xCDD1, 0xCDD2, 0xCDCB, 0xCDCD])
		remainder -= 0x0C
		quotient += 1
		_set_x(cpu, quotient)
	executed_pcs.append_array([0xCDD4, 0xCDD5, 0xCDD6, 0xCDD7, 0xCDD9, 0xCDDA, 0xCDDB, 0xCDDC, 0xCDDD, 0xCDDE, 0xCDE0])
	_set_a(cpu, remainder)
	for _shift in 3:
		_asl_a(cpu)
	_adc(cpu, 0x54)
	_set_y(cpu, int(cpu["a"]))
	_set_a(cpu, int(cpu["x"]))
	for _shift in 3:
		_asl_a(cpu)
	_adc(cpu, 0x34)
	_set_x(cpu, int(cpu["a"]))


func _execute_position_index(cpu: Dictionary, ram: PackedByteArray,
		writes: Array[Dictionary], executed_pcs: Array[int]) -> int:
	executed_pcs.append_array([0x82FE, 0x8301, 0x8302, 0x8304, 0x8306])
	_set_a(cpu, int(ram[0x0637])); _set_c(cpu, true); _sbc(cpu, 0x50)
	_set_a(cpu, int(cpu["a"]) & 0xF0)
	_lsr_a(cpu)
	_write_ram(ram, writes, 0x8307, 0x003A, int(cpu["a"]))
	executed_pcs.append_array([0x8307, 0x8309, 0x830A, 0x830B])
	_lsr_a(cpu)
	_lsr_a(cpu)
	_adc(cpu, int(ram[0x003A]))
	_write_ram(ram, writes, 0x830D, 0x003A, int(cpu["a"]))
	executed_pcs.append_array([0x830D, 0x830F, 0x8312, 0x8313, 0x8315])
	_set_a(cpu, int(ram[0x0635])); _set_c(cpu, true); _sbc(cpu, 0x30)
	_set_a(cpu, int(cpu["a"]) & 0xF0)
	executed_pcs.append_array([0x8317, 0x8318, 0x8319, 0x831A, 0x831B])
	for _shift in 4:
		_lsr_a(cpu)
	_adc(cpu, int(ram[0x003A]))
	_set_x(cpu, int(cpu["a"]))
	executed_pcs.append_array([0x831D, 0x831E, 0x831F])
	_set_a(cpu, int(cpu["y"]))
	if int(cpu["a"]) != 0:
		executed_pcs.append_array([0x8321, 0x8322, 0x8323, 0x8325])
		_set_a(cpu, int(cpu["x"]))
		_set_c(cpu, false)
		_adc(cpu, 0x3C)
		_set_x(cpu, int(cpu["a"]))
	executed_pcs.append(0x8326)
	return int(cpu["x"])


func _rts(cpu: Dictionary, stack: PackedByteArray, reads: Array[Dictionary],
		pc: int, expected_return: int) -> bool:
	var low := _pop(cpu, stack, reads, pc)
	var high := _pop(cpu, stack, reads, pc)
	var return_pc := (((high << 8) | low) + 1) & 0xFFFF
	cpu["pc"] = return_pc
	return return_pc == expected_return


func _push_jsr(cpu: Dictionary, stack: PackedByteArray, writes: Array[Dictionary],
		pc: int, target: int) -> void:
	var return_word := (pc + 2) & 0xFFFF
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = (return_word >> 8) & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": (return_word >> 8) & 0xFF, "kind": "JSR_high"})
	sp = (sp - 1) & 0xFF
	stack[sp] = return_word & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": return_word & 0xFF, "kind": "JSR_low"})
	cpu["sp"] = (sp - 1) & 0xFF
	cpu["pc"] = target


func _push(cpu: Dictionary, stack: PackedByteArray, writes: Array[Dictionary],
		value: int, pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = value & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": value & 0xFF, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop(cpu: Dictionary, stack: PackedByteArray, reads: Array[Dictionary], pc: int) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var value := int(stack[sp])
	cpu["sp"] = sp
	reads.append({"pc": pc, "address": 0x0100 | sp, "value": value, "kind": "PLA"})
	return value


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], pc: int,
		address: int, value: int) -> void:
	ram[address] = value & 0xFF
	writes.append({"pc": pc, "address": address, "value": value & 0xFF})


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_x(cpu: Dictionary, value: int) -> void:
	cpu["x"] = value & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _set_y(cpu: Dictionary, value: int) -> void:
	cpu["y"] = value & 0xFF
	_set_nz(cpu, int(cpu["y"]))


func _set_c(cpu: Dictionary, enabled: bool) -> void:
	var p := (int(cpu.get("p", 0x20)) & ~P_C) | 0x20
	if enabled:
		p |= P_C
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_C


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := (int(cpu.get("p", 0x20)) & ~P_NZ) | 0x20
	if (value & 0x80) != 0:
		p |= P_N
	if (value & 0xFF) == 0:
		p |= P_Z
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ


func _cmp(cpu: Dictionary, left: int, right: int) -> void:
	var result := (left - right) & 0xFF
	_set_c(cpu, left >= right)
	_set_nz(cpu, result)


func _asl_a(cpu: Dictionary) -> void:
	var old := int(cpu["a"])
	_set_c(cpu, (old & 0x80) != 0)
	_set_a(cpu, (old << 1) & 0xFF)


func _lsr_a(cpu: Dictionary) -> void:
	var old := int(cpu["a"])
	_set_c(cpu, (old & 1) != 0)
	_set_a(cpu, old >> 1)


func _adc(cpu: Dictionary, value: int) -> void:
	var old := int(cpu["a"])
	var carry := int(cpu["p"]) & P_C
	var total := old + value + carry
	var result := total & 0xFF
	var p := (int(cpu.get("p", 0x20)) & ~P_CVNZ) | 0x20
	if total > 0xFF:
		p |= P_C
	if ((~(old ^ value) & (old ^ result)) & 0x80) != 0:
		p |= P_V
	if (result & 0x80) != 0:
		p |= P_N
	if result == 0:
		p |= P_Z
	cpu["a"] = result
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_CVNZ


func _sbc(cpu: Dictionary, value: int) -> void:
	var old := int(cpu["a"])
	var borrow := 0 if (int(cpu["p"]) & P_C) != 0 else 1
	var total := old - value - borrow
	var result := total & 0xFF
	var p := (int(cpu.get("p", 0x20)) & ~P_CVNZ) | 0x20
	if total >= 0:
		p |= P_C
	if (((old ^ result) & (old ^ value)) & 0x80) != 0:
		p |= P_V
	if (result & 0x80) != 0:
		p |= P_N
	if result == 0:
		p |= P_Z
	cpu["a"] = result
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_CVNZ


func _read(pc: int, address: int, value: int, kind: String) -> Dictionary:
	return {"pc": pc, "address": address, "value": value & 0xFF, "kind": kind}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_execution_refused", "error": message,
		"trace_state_used": false}
