extends RefCounted
class_name RomSlot15CallbackDispatcherExecutor
## Executes checked fresh callback readers and inline vector dispatch from
## `$814C` to their ROM handler entry. It stops before handler code.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CALLBACK_ROOT := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/"
const FIXED_ROOT := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/"
const TRAMPOLINE_ROOT := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/"
const DISPATCHER_PATH := CALLBACK_ROOT + "bank_0b_dispatcher_814c_81a6.bin"
const DISPATCHER_SHA256 := "c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6"
const POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_3a_pointer_boundary.bin"
const POINTER_SHA256 := "c4bf5bc239937e437da70f6a20ffa3eee46ef5694b7f1fd38115a5d693e209a0"
const STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_3a_stream.bin"
const STREAM_SHA256 := "f619833b71e98ee35083a2777d7d6ef697470576a132939ea610025f7d7b32d8"
const CALLBACK_0C_POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_0c_pointer_boundary.bin"
const CALLBACK_0C_POINTER_SHA256 := "ff44046c3970d617ef6b005c70dfa7457b2412445ecf08abdc0c682b1c0aefd4"
const CALLBACK_0C_STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_0c_stream.bin"
const CALLBACK_0C_STREAM_SHA256 := "7d36f5ebd4ffbf366b3ac53cd8808e57f49cbc157240795808c62980d2a60999"
const CALLBACK_1F_POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_1f_pointer_boundary.bin"
const CALLBACK_1F_POINTER_SHA256 := "5a8d9325acca91aa9334cda4443ef504f78dd1f7819c0687dec529a36b7f8fd2"
const CALLBACK_1F_STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_1f_stream.bin"
const CALLBACK_1F_STREAM_SHA256 := "8f64a5237eca4cbf00510780bb7a8059a60c34ec0ace94cb57b4c7c218e269cf"
const CALLBACK_45_POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_45_pointer_boundary.bin"
const CALLBACK_45_POINTER_SHA256 := "c47887871fd1395ea85b2adf1c683a43c8092859d497fd89070de1652af927bc"
const CALLBACK_45_STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_45_stream.bin"
const CALLBACK_45_STREAM_SHA256 := "a338daef97f1529da31483000bbdc227e53a40852662a5671b8a2ff7c57c1d90"
const CALLBACK_70_POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_70_pointer.bin"
const CALLBACK_70_POINTER_SHA256 := "bc885b8008d1b96fcf6d97162721b5a11856643ad80359e925298b87765e39cb"
const CALLBACK_70_STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_70_stream.bin"
const CALLBACK_70_STREAM_SHA256 := "0356c29ad2d677b4aa64102937c1b3cefc4212f0fe6f4bce0c3fc53ef184f9e5"
const CALLBACK_63_POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_63_pointer_boundary.bin"
const CALLBACK_63_POINTER_SHA256 := "9809adbf9e01314d334616274822da4f3236d502df6cf394e5330ca5a0b76c74"
const CALLBACK_63_STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_63_stream.bin"
const CALLBACK_63_STREAM_SHA256 := "9d2066a00be92403af4c988c62e1630c7b6bed5f91918b9934c35b58303ffd0f"
const CALLBACK_36_POINTER_PATH := CALLBACK_ROOT + "bank_0b_event_36_pointer_boundary.bin"
const CALLBACK_36_POINTER_SHA256 := "aeb3e470d501911d2e44f80ada32a8cae2da4549baa3d14486656505043607df"
const CALLBACK_36_STREAM_PATH := CALLBACK_ROOT + "bank_0b_event_36_stream.bin"
const CALLBACK_36_STREAM_SHA256 := "4470eb249b4005c5eee6fa30b4c78d40754603cdd77ee68811ff0c184055b9da"
const CALLBACK_34_ROOT := "res://reference/rom_extract/gameplay/slot15_callback_34/"
const CALLBACK_34_POINTER_PATH := CALLBACK_34_ROOT + "callback_34_script_pointer.bin"
const CALLBACK_34_POINTER_SHA256 := "f287538c65456d2234e6d47bce379df09af4207af9ac4a1a6dea54486d59a931"
const CALLBACK_34_STREAM_PATH := CALLBACK_34_ROOT + "callback_34_map_2d_script.bin"
const CALLBACK_34_STREAM_SHA256 := "530988962b3acfb674a6c3a9b9a16cdb2ae2e81c6f3b2ce3883de4137585dacf"
const CALLBACK_34_POINTER_TABLE_CPU := 0x885E
const CALLBACK_34_STREAM_CPU := 0x89E1
const VECTOR_PATH := CALLBACK_ROOT + "bank_0b_dispatch_vector_81a7.bin"
const VECTOR_SHA256 := "663e41116c23b455e418b531b39024bdc5a0c71fc022009926e8cf541f1d35c9"
const FIXED_JUMP_PATH := FIXED_ROOT + "fixed_dispatch_C509_C50C.bin"
const FIXED_JUMP_SHA256 := "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"
const INLINE_HELPER_PATH := TRAMPOLINE_ROOT + "fixed_branch_table_dispatch_CB99_CBAF.bin"
const INLINE_HELPER_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"
const POINTER_TABLE_CPU := 0x87F6
const CALLBACK_STREAM_CPU := 0x89F3
const CALLBACK_0C_POINTER_TABLE_CPU := 0x880E
const CALLBACK_0C_STREAM_CPU := 0x8911
const CALLBACK_1F_POINTER_TABLE_CPU := 0x8834
const CALLBACK_1F_STREAM_CPU := 0x896A
const CALLBACK_36_POINTER_TABLE_CPU := 0x8862
const CALLBACK_36_STREAM_CPU := 0x89E7
const CALLBACK_DISPATCHER_PC := 0x814C
const CALLBACK_1F_HANDLER_CPU := 0x8358
const P_C := 0x01
const P_Z := 0x02
const P_N := 0x80
const P_NZ := P_N | P_Z

var error_message := ""


func execute_fresh_callback_3a(dispatcher_entry: Dictionary) -> Dictionary:
	return execute_fresh_callback(dispatcher_entry)


func execute_fresh_callback(dispatcher_entry: Dictionary) -> Dictionary:
	error_message = ""
	var loaded := _load_sources()
	if not bool(loaded.get("ok", false)):
		return _failure(String(loaded.get("error", "Callback source validation failed.")))
	var sources: Dictionary = loaded["sources"]
	var entry_variant: Variant = dispatcher_entry.get("dispatcher_dispatch", {})
	var ram_variant: Variant = dispatcher_entry.get("ram_image", PackedByteArray())
	var stack_variant: Variant = dispatcher_entry.get("stack_page", PackedByteArray())
	if not entry_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _failure("Callback entry result omits dispatched CPU, RAM, or stack state.")
	var entry: Dictionary = entry_variant
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var scenario_id := int(ram[0x0518]) if ram.size() == 0x800 else -1
	var callback_id := int(ram[0x0524]) if ram.size() == 0x800 else -1
	var callback_70 := callback_id == 0x70
	var callback_34 := callback_id == 0x34
	var callback_0c := callback_id == 0x0C
	var callback_1f := callback_id == 0x1F
	var callback_45 := callback_id == 0x45
	var callback_36 := callback_id == 0x36
	var scenario1c_callback63 := scenario_id == 0x1C and callback_id == 0x63
	var scenario2e_callback36 := scenario_id == 0x2E and callback_36
	var expected_wait := 0x38 if scenario1c_callback63 else (0x78 if scenario2e_callback36 else (0x02 if scenario_id in [0x35, 0x44] else (0x30 if scenario_id == 0x1C and callback_1f else (0x20 if callback_0c else (0x32 if callback_1f else 0x10)))))
	var expected_actor_selector := 0x7A if scenario1c_callback63 else (0x8B if callback_36 else (0x5C if callback_70 else (0x4E if callback_0c else (0x4C if callback_1f else 0x8F))))
	var expected_actor_parameter := 0x58 if scenario1c_callback63 else (0x6D if callback_36 else (0x73 if scenario_id == 0x35 else (0x00 if scenario_id == 0x1C and callback_1f else (0x74 if callback_0c else 0xFF))))
	var expected_bank_high := 0x0C
	var pointer_table_cpu := 0x886A
	var callback_stream_cpu := CALLBACK_STREAM_CPU
	var pointer_bytes: PackedByteArray = sources["pointer"]
	var stream: PackedByteArray = sources["stream"]
	var pointer_hash := POINTER_SHA256
	var stream_hash := STREAM_SHA256
	var expected_pointer_bytes := PackedByteArray([0xF3, 0x89, 0xF6, 0x89])
	var expected_callback_bytes := PackedByteArray([0x02, 0x00, 0x42])
	if scenario1c_callback63:
		pointer_table_cpu = 0x88BC
		callback_stream_cpu = 0x8AD8
		pointer_bytes = sources["pointer_63"]
		stream = sources["stream_63"]
		pointer_hash = CALLBACK_63_POINTER_SHA256
		stream_hash = CALLBACK_63_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0xD8, 0x8A, 0xDB, 0x8A])
		expected_callback_bytes = PackedByteArray([0x02, 0x00, 0x51])
	elif callback_36:
		pointer_table_cpu = CALLBACK_36_POINTER_TABLE_CPU
		callback_stream_cpu = CALLBACK_36_STREAM_CPU
		pointer_bytes = sources["pointer_36"]
		stream = sources["stream_36"]
		pointer_hash = CALLBACK_36_POINTER_SHA256
		stream_hash = CALLBACK_36_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0xE7, 0x89, 0xEA, 0x89])
		expected_callback_bytes = PackedByteArray([0x02, 0x00, 0x2F])
	elif callback_70:
		pointer_table_cpu = 0x88D6
		callback_stream_cpu = 0x8B38
		pointer_bytes = sources["pointer_70"]
		stream = sources["stream_70"]
		pointer_hash = CALLBACK_70_POINTER_SHA256
		stream_hash = CALLBACK_70_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0x38, 0x8B])
		expected_callback_bytes = PackedByteArray([0x06, 0x00, 0x56, 0x02, 0x00, 0x80])
	elif callback_34:
		pointer_table_cpu = CALLBACK_34_POINTER_TABLE_CPU
		callback_stream_cpu = CALLBACK_34_STREAM_CPU
		pointer_bytes = sources["pointer_34"]
		stream = sources["stream_34"]
		pointer_hash = CALLBACK_34_POINTER_SHA256
		stream_hash = CALLBACK_34_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0xE1, 0x89])
		expected_callback_bytes = PackedByteArray([0x02, 0x00, 0x2D])
	elif callback_0c:
		pointer_table_cpu = CALLBACK_0C_POINTER_TABLE_CPU
		callback_stream_cpu = CALLBACK_0C_STREAM_CPU
		pointer_bytes = sources["pointer_0c"]
		stream = sources["stream_0c"]
		pointer_hash = CALLBACK_0C_POINTER_SHA256
		stream_hash = CALLBACK_0C_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0x11, 0x89, 0x14, 0x89])
		expected_callback_bytes = PackedByteArray([0x02, 0x00, 0x43])
	elif callback_1f:
		pointer_table_cpu = CALLBACK_1F_POINTER_TABLE_CPU
		callback_stream_cpu = CALLBACK_1F_STREAM_CPU
		pointer_bytes = sources["pointer_1f"]
		stream = sources["stream_1f"]
		pointer_hash = CALLBACK_1F_POINTER_SHA256
		stream_hash = CALLBACK_1F_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0x6A, 0x89, 0x6F, 0x89])
		expected_callback_bytes = PackedByteArray([0x02, 0x03, 0x00, 0x04, 0x52])
	elif callback_45:
		pointer_table_cpu = 0x8880
		callback_stream_cpu = 0x8A2A
		pointer_bytes = sources["pointer_45"]
		stream = sources["stream_45"]
		pointer_hash = CALLBACK_45_POINTER_SHA256
		stream_hash = CALLBACK_45_STREAM_SHA256
		expected_pointer_bytes = PackedByteArray([0x2A, 0x8A, 0x2D, 0x8A])
		expected_callback_bytes = PackedByteArray([0x06, 0x00, 0x36])
	var cpu := {
		"pc": int(entry.get("pc", -1)), "a": int(entry.get("a", -1)),
		"x": int(entry.get("x", -1)), "y": int(entry.get("y", -1)),
		"sp": int(entry.get("sp", -1)), "p": int(entry.get("p", 0)),
		"p_known_mask": int(entry.get("p_known_mask", 0)),
	}
	# Scenario-$38's root starts with an `$F7` record. Its wait and actor-field
	# semantics are not modeled, so callback-$34 validation is limited to the
	# selected scenario, callback pointer/script, and the shared dispatcher path.
	if String(dispatcher_entry.get("rom_sha256", "")) != ROM_SHA256 \
			or String(dispatcher_entry.get("status", "")) != "reached_callback_dispatcher_entry" \
			or int(dispatcher_entry.get("exit_pc", -1)) != CALLBACK_DISPATCHER_PC \
			or int(cpu["pc"]) != 0x814C or int(entry.get("slot_base", -1)) != 0x15 \
			or (scenario_id not in [0x1C, 0x1E, 0x35, 0x36, 0x44] and not scenario2e_callback36 \
				and not (callback_34 and scenario_id == 0x38)) \
			or callback_id not in [0x3A, 0x0C, 0x1F, 0x34, 0x36, 0x45, 0x63, 0x70] \
			or (callback_36 and scenario_id != 0x2E) \
			or (callback_id == 0x63 and not scenario1c_callback63) \
			or (callback_70 and scenario_id != 0x44) \
			or (callback_34 and scenario_id != 0x38) \
			or (callback_0c and scenario_id != 0x36) \
			or (callback_1f and scenario_id not in [0x1C, 0x36]) \
			or int(entry.get("bank_low", -1)) != 0x0B or int(entry.get("bank_high", -1)) != expected_bank_high \
			or ram.size() != 0x800 or stack.size() != 0x100 \
			or (scenario2e_callback36 and (int(ram[0x0516]) != 0x41 or int(ram[0x052A]) != 0x00)) \
			or (not callback_45 and not callback_34 and int(ram[0x0523]) != expected_wait) \
			or (not callback_45 and not callback_34 and (int(ram[0x0528]) != expected_actor_selector \
			or int(ram[0x0529]) != expected_actor_parameter)):
		return _failure("Input is not a supported callback at `$814C`: result=%s exit=$%04X PC=$%04X slot=$%02X banks=$%02X/$%02X RAM=$0524:$%02X,$0523:$%02X,$0528:$%02X,$0529:$%02X size=%d/%d." % [
			String(dispatcher_entry.get("status", "")), int(dispatcher_entry.get("exit_pc", -1)),
			int(cpu["pc"]), int(entry.get("slot_base", -1)), int(entry.get("bank_low", -1)),
			int(entry.get("bank_high", -1)), int(ram[0x0524]) if ram.size() == 0x800 else -1,
			int(ram[0x0523]) if ram.size() == 0x800 else -1,
			int(ram[0x0528]) if ram.size() == 0x800 else -1,
			int(ram[0x0529]) if ram.size() == 0x800 else -1, ram.size(), stack.size()])
	if not _require_span(sources["dispatcher"], 0x814C,
			[[0x814C, [0xA9, 0xF6]], [0x8154, [0xAD, 0x24, 0x05]],
			[0x8159, [0xF0, 0x41]], [0x815B, [0x0A]], [0x815C, [0x90, 0x02]],
			[0x8161, [0xB1, 0x52]], [0x8174, [0xB1, 0x52]],
			[0x8178, [0x90, 0x0E]], [0x8188, [0x8D, 0x25, 0x05]],
			[0x8199, [0x20, 0xA7, 0x81]]]):
		return _failure("The executed `$814C` source opcodes differ from the checked dispatcher span.")
	if pointer_bytes != expected_pointer_bytes or stream != expected_callback_bytes \
			or sources["vector"].slice(0, 5) != PackedByteArray([0x20, 0x09, 0xC5, 0x27, 0x83]) \
			or sources["fixed_jump"] != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or sources["inline_helper"] != PackedByteArray([
			0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36,
			0x48, 0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00]):
		return _failure("Callback, inline vector, or `$C509->$CB99` trampoline bytes differ from the ROM package.")
	var entry_cpu := cpu.duplicate(true)
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [
		0x814C, 0x814E, 0x8150, 0x8152, 0x8154, 0x8157, 0x8159, 0x815B, 0x815C,
		0x8160, 0x8161, 0x8163, 0x8164, 0x8165, 0x8167, 0x8169, 0x816B, 0x816D,
		0x8170, 0x8172, 0x8174, 0x8176, 0x8178, 0x8188, 0x818B, 0x818C, 0x818D,
		0x818F, 0x8191, 0x8195, 0x8197, 0x8199, 0x81A7, 0xC509, 0xCB99,
		0xCB9A, 0xCB9B, 0xCB9C, 0xCB9E, 0xCB9F, 0xCBA1, 0xCBA2, 0xCBA4,
		0xCBA5, 0xCBA6, 0xCBA8, 0xCBAA, 0xCBAB, 0xCBAD,
	]
	var pointer_low := int(pointer_bytes[0])
	var pointer_high := int(pointer_bytes[1])
	var resolved_pointer := (pointer_high << 8) | pointer_low
	if resolved_pointer != callback_stream_cpu:
		return _failure("Callback table no longer resolves selector `$%02X` to `$%04X`." % [callback_id, callback_stream_cpu])

	# $814C-$8176: load the callback pointer and first command byte.
	_set_a(cpu, 0xF6); _write_ram(ram, writes, 0x814C, 0x0052, int(cpu["a"]))
	_set_a(cpu, 0x87); _write_ram(ram, writes, 0x8150, 0x0053, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0524]))
	if int(cpu["a"]) == 0xFF:
		return _failure("Callback `$%02X` unexpectedly takes the source `$8159->$819C` sentinel branch." % callback_id)
	_set_a(cpu, (int(cpu["a"]) << 1) & 0xFF)
	_set_c(cpu, false)
	_set_y(cpu, int(cpu["a"]))
	var table_address := POINTER_TABLE_CPU + int(cpu["y"])
	var low_index := table_address - pointer_table_cpu
	var low_byte := int(pointer_bytes[low_index])
	source_reads.append(_read_event(0x8161, table_address, low_byte, "callback_pointer_low"))
	_set_a(cpu, low_byte)
	_set_x(cpu, int(cpu["a"]))
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var high_address := POINTER_TABLE_CPU + int(cpu["y"])
	var high_index := high_address - pointer_table_cpu
	var high_byte := int(pointer_bytes[high_index])
	source_reads.append(_read_event(0x8165, high_address, high_byte, "callback_pointer_high"))
	_set_a(cpu, high_byte)
	_write_ram(ram, writes, 0x8167, 0x0053, int(cpu["a"]))
	_write_ram(ram, writes, 0x8169, 0x0052, int(cpu["x"]))
	_set_a(cpu, 0)
	_write_ram(ram, writes, 0x816D, 0x05D1, 0)
	_write_ram(ram, writes, 0x8170, 0x003A, 0)
	_set_y(cpu, int(ram[0x003A]))
	var first_event_byte := int(stream[int(cpu["y"])])
	source_reads.append(_read_event(0x8174, callback_stream_cpu + int(cpu["y"]), first_event_byte, "callback_command_length"))
	_set_a(cpu, first_event_byte)
	if int(cpu["a"]) >= 0xF0:
		return _failure("Callback `$%02X` unexpectedly takes the source `$8178->$817A` control-record branch." % callback_id)
	_write_ram(ram, writes, 0x8188, 0x0525, int(cpu["a"]))
	_set_a(cpu, int(cpu["y"]))
	_set_c(cpu, false)
	var adjusted_low_sum := int(cpu["a"]) + int(ram[0x0052])
	_set_a(cpu, adjusted_low_sum & 0xFF)
	_set_c(cpu, adjusted_low_sum > 0xFF)
	_write_ram(ram, writes, 0x818F, 0x0052, int(cpu["a"]))
	if bool(int(cpu["p"]) & P_C):
		return _failure("Callback pointer adjustment unexpectedly crosses into its high byte.")
	_set_y(cpu, 1)
	var subindex := int(stream[1])
	source_reads.append(_read_event(0x8197, callback_stream_cpu + 1, subindex, "callback_subindex"))
	_set_a(cpu, subindex)
	var expected_subindex := 3 if callback_1f else 0
	if subindex != expected_subindex:
		return _failure("Callback `$%02X` selects inline vector row $%02X, expected $%02X." % [callback_id, subindex, expected_subindex])

	# `$8199 JSR $81A7`, `$81A7 JSR $C509`, then the checked inline-table
	# trampoline `$C509->$CB99` pops its own return address and jumps via row 0.
	_push_jsr(cpu, stack, stack_writes, 0x8199, 0x81A7)
	_push_jsr(cpu, stack, stack_writes, 0x81A7, 0xC509)
	_set_a(cpu, (int(cpu["a"]) << 1) & 0xFF)
	_set_y(cpu, int(cpu["a"]))
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCB9B))
	# The trampoline's two PLAs consume the return word pushed by its own JSR.
	# Inline return-minus-one `$81A9` is source-derived by those actual bytes.
	var trampoline_low := 0xA9
	var trampoline_high := 0x81
	if int(cpu["a"]) != trampoline_low:
		return _failure("The `$CB99` trampoline did not pop its source `$81A9` return-low byte.")
	_write_ram(ram, writes, 0xCB99, 0x0036, trampoline_low)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCB9E))
	if int(cpu["a"]) != trampoline_high:
		return _failure("The `$CB99` trampoline did not pop its source `$81A9` return-high byte.")
	_write_ram(ram, writes, 0xCB99, 0x0037, trampoline_high)
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_table_offset := 3 + 2 * subindex
	var vector_low := int(sources["vector"][vector_table_offset])
	source_reads.append(_read_event(0xCB99, 0x81AA + 2 * subindex, vector_low, "inline_vector_low"))
	_set_a(cpu, vector_low)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCBA4, "PHA")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_high := int(sources["vector"][vector_table_offset + 1])
	source_reads.append(_read_event(0xCB99, 0x81AB + 2 * subindex, vector_high, "inline_vector_high"))
	_set_a(cpu, vector_high)
	_write_ram(ram, writes, 0xCBA8, 0x0037, int(cpu["a"]))
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCBAA))
	_write_ram(ram, writes, 0xCBAB, 0x0036, int(cpu["a"]))
	var handler_pc := int(ram[0x0036]) | (int(ram[0x0037]) << 8)
	var expected_handler_pc := CALLBACK_1F_HANDLER_CPU if callback_1f else 0x8327
	if handler_pc != expected_handler_pc:
		return _failure("ROM inline dispatch row $%02X resolved to `$%04X`, expected `$%04X`." % [subindex, handler_pc, expected_handler_pc])
	cpu["pc"] = handler_pc
	for stack_offset in stack.size():
		ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "reached_first_callback_handler_%04X" % handler_pc,
		"rom_sha256": ROM_SHA256,
		"source_hashes": {"dispatcher": DISPATCHER_SHA256, "pointer": pointer_hash,
			"stream": stream_hash, "vector": VECTOR_SHA256,
			"fixed_jump": FIXED_JUMP_SHA256, "inline_helper": INLINE_HELPER_SHA256},
		"entry_pc": 0x814C,
		"exit_pc": handler_pc,
		"entry_registers": entry_cpu,
		"registers": cpu,
		"entry_mapper": entry.duplicate(true),
		"mapper": {"bank_low": int(entry.get("bank_low", -1)),
			"bank_high": int(entry.get("bank_high", -1)),
			"select": 7},
		"ram_image": ram,
		"stack_page": stack,
		"ram_writes": writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"scenario": scenario_id,
		"callback_id": callback_id,
		"callback_context_unresolved": [
			"Callback-$36 stream byte $2F has not been traced through handler `$8327`; its meaning is unresolved.",
			"Scenario-$2E callback scheduling and continuation are not modeled here.",
		] if callback_36 else ([
			"Callback-$63 map-$51 worker data and continuation are not modeled here.",
		] if scenario1c_callback63 else ([
			"Scenario-$38 `$F7` wait-field interpretation at RAM `$0523` is unresolved.",
			"Scenario-$38 actor-field interpretation at RAM `$0528/$0529` is unresolved.",
			"Scenario-to-callback scheduling and the callback's continuation are not modeled here.",
		] if callback_34 else [])),
		"callback_stream_address": callback_stream_cpu,
		"callback_bytes": stream.duplicate(),
		"callback_command_byte": first_event_byte,
		"callback_subindex": subindex,
		"handler_pc": handler_pc,
		"handler_first_source_instruction_executed": false,
		"incoming_05cd": int(ram[0x05CD]),
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}


func _load_sources() -> Dictionary:
	var paths := {
		"dispatcher": [DISPATCHER_PATH, DISPATCHER_SHA256],
		"pointer": [POINTER_PATH, POINTER_SHA256],
		"stream": [STREAM_PATH, STREAM_SHA256],
		"pointer_0c": [CALLBACK_0C_POINTER_PATH, CALLBACK_0C_POINTER_SHA256],
		"stream_0c": [CALLBACK_0C_STREAM_PATH, CALLBACK_0C_STREAM_SHA256],
		"pointer_1f": [CALLBACK_1F_POINTER_PATH, CALLBACK_1F_POINTER_SHA256],
		"stream_1f": [CALLBACK_1F_STREAM_PATH, CALLBACK_1F_STREAM_SHA256],
		"pointer_45": [CALLBACK_45_POINTER_PATH, CALLBACK_45_POINTER_SHA256],
		"stream_45": [CALLBACK_45_STREAM_PATH, CALLBACK_45_STREAM_SHA256],
		"pointer_70": [CALLBACK_70_POINTER_PATH, CALLBACK_70_POINTER_SHA256],
		"stream_70": [CALLBACK_70_STREAM_PATH, CALLBACK_70_STREAM_SHA256],
		"pointer_63": [CALLBACK_63_POINTER_PATH, CALLBACK_63_POINTER_SHA256],
		"stream_63": [CALLBACK_63_STREAM_PATH, CALLBACK_63_STREAM_SHA256],
		"pointer_36": [CALLBACK_36_POINTER_PATH, CALLBACK_36_POINTER_SHA256],
		"stream_36": [CALLBACK_36_STREAM_PATH, CALLBACK_36_STREAM_SHA256],
		"pointer_34": [CALLBACK_34_POINTER_PATH, CALLBACK_34_POINTER_SHA256],
		"stream_34": [CALLBACK_34_STREAM_PATH, CALLBACK_34_STREAM_SHA256],
		"vector": [VECTOR_PATH, VECTOR_SHA256],
		"fixed_jump": [FIXED_JUMP_PATH, FIXED_JUMP_SHA256],
		"inline_helper": [INLINE_HELPER_PATH, INLINE_HELPER_SHA256],
	}
	var sources: Dictionary = {}
	for key_variant in paths:
		var key := String(key_variant)
		var path: String = paths[key][0]
		var expected_hash: String = paths[key][1]
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != expected_hash:
			return {"ok": false, "error": "Callback source failed its packaged SHA-256 check: %s" % path}
		sources[key] = FileAccess.get_file_as_bytes(path)
	return {"ok": true, "sources": sources}


func _require_span(source: PackedByteArray, base: int, expected: Array) -> bool:
	for row_variant in expected:
		var row: Array = row_variant
		var offset := int(row[0]) - base
		var bytes: Array = row[1]
		if offset < 0 or offset + bytes.size() > source.size():
			return false
		for index in bytes.size():
			if int(source[offset + index]) != int(bytes[index]):
				return false
	return true


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], pc: int,
		address: int, value: int) -> void:
	ram[address] = value & 0xFF
	writes.append({"pc": pc, "address": address, "value": value & 0xFF})


func _push_jsr(cpu: Dictionary, stack: PackedByteArray,
		writes: Array[Dictionary], pc: int, target: int) -> void:
	var return_word := (pc + 2) & 0xFFFF
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = (return_word >> 8) & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": (return_word >> 8) & 0xFF, "kind": "JSR_high"})
	sp = (sp - 1) & 0xFF
	stack[sp] = return_word & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": return_word & 0xFF, "kind": "JSR_low"})
	cpu["sp"] = (sp - 1) & 0xFF
	cpu["pc"] = target


func _push(cpu: Dictionary, stack: PackedByteArray,
		writes: Array[Dictionary], value: int, pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = value & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp,
		"value": value & 0xFF, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop(cpu: Dictionary, stack: PackedByteArray, unused_reads: Array[Dictionary],
		pc: int) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var value := int(stack[sp])
	cpu["sp"] = sp
	unused_reads.append({"pc": pc, "address": 0x0100 | sp, "value": value, "kind": "PLA"})
	return value


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_x(cpu: Dictionary, value: int) -> void:
	cpu["x"] = value & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _set_y(cpu: Dictionary, value: int) -> void:
	cpu["y"] = value & 0xFF
	_set_nz(cpu, int(cpu["y"]))


func _set_c(cpu: Dictionary, set: bool) -> void:
	var p := (int(cpu["p"]) & ~P_C) | 0x20
	if set:
		p |= P_C
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | P_C


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := (int(cpu["p"]) & ~P_NZ) | 0x20
	if (value & 0x80) != 0:
		p |= P_N
	if (value & 0xFF) == 0:
		p |= P_Z
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | P_NZ


func _read_event(pc: int, address: int, value: int, kind: String) -> Dictionary:
	return {"pc": pc, "address": address, "value": value & 0xFF, "kind": kind}


func _failure(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_execution_refused", "error": reason,
		"trace_state_used": false}
