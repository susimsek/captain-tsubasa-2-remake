extends RefCounted
class_name RomSlot15CallbackDispatcherExecutor
## Executes the checked callback-$3A reader and inline vector path from
## `$814C` to the first handler entry `$8327`. It stops before handler code.

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
const VECTOR_PATH := CALLBACK_ROOT + "bank_0b_dispatch_vector_81a7.bin"
const VECTOR_SHA256 := "663e41116c23b455e418b531b39024bdc5a0c71fc022009926e8cf541f1d35c9"
const FIXED_JUMP_PATH := FIXED_ROOT + "fixed_dispatch_C509_C50C.bin"
const FIXED_JUMP_SHA256 := "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"
const INLINE_HELPER_PATH := TRAMPOLINE_ROOT + "fixed_branch_table_dispatch_CB99_CBAF.bin"
const INLINE_HELPER_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"
const POINTER_TABLE_CPU := 0x87F6
const CALLBACK_STREAM_CPU := 0x89F3
const CALLBACK_DISPATCHER_PC := 0x814C
const HANDLER_CPU := 0x8327
const P_C := 0x01
const P_Z := 0x02
const P_N := 0x80
const P_NZ := P_N | P_Z

var error_message := ""


func execute_fresh_callback_3a(dispatcher_entry: Dictionary) -> Dictionary:
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
	var expected_wait := 0x02 if scenario_id == 0x35 else 0x10
	var expected_actor_parameter := 0x73 if scenario_id == 0x35 else 0xFF
	var expected_bank_high := 0x0C
	var cpu := {
		"pc": int(entry.get("pc", -1)), "a": int(entry.get("a", -1)),
		"x": int(entry.get("x", -1)), "y": int(entry.get("y", -1)),
		"sp": int(entry.get("sp", -1)), "p": int(entry.get("p", 0)),
		"p_known_mask": int(entry.get("p_known_mask", 0)),
	}
	if String(dispatcher_entry.get("rom_sha256", "")) != ROM_SHA256 \
			or String(dispatcher_entry.get("status", "")) != "reached_callback_dispatcher_entry" \
			or int(dispatcher_entry.get("exit_pc", -1)) != CALLBACK_DISPATCHER_PC \
			or int(cpu["pc"]) != 0x814C or int(entry.get("slot_base", -1)) != 0x15 \
			or scenario_id not in [0x35, 0x36] \
			or int(entry.get("bank_low", -1)) != 0x0B or int(entry.get("bank_high", -1)) != expected_bank_high \
			or ram.size() != 0x800 or stack.size() != 0x100 \
			or int(ram[0x0524]) != 0x3A or int(ram[0x0523]) != expected_wait \
			or int(ram[0x0528]) != 0x8F or int(ram[0x0529]) != expected_actor_parameter:
		return _failure("Input is not callback `$3A` at `$814C`: result=%s exit=$%04X PC=$%04X slot=$%02X banks=$%02X/$%02X RAM=$0524:$%02X,$0523:$%02X,$0528:$%02X,$0529:$%02X size=%d/%d." % [
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
	if sources["pointer"] != PackedByteArray([0xF3, 0x89, 0xF6, 0x89]) \
			or sources["stream"] != PackedByteArray([0x02, 0x00, 0x42]) \
			or sources["vector"].slice(0, 5) != PackedByteArray([0x20, 0x09, 0xC5, 0x27, 0x83]) \
			or sources["fixed_jump"] != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or sources["inline_helper"] != PackedByteArray([
			0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36,
			0x48, 0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00]):
		return _failure("Callback `$3A`, inline vector, or `$C509->$CB99` trampoline bytes differ from the ROM package.")
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
	var pointer_low := int(sources["pointer"][0])
	var pointer_high := int(sources["pointer"][1])
	var pointer := (pointer_high << 8) | pointer_low
	if pointer != CALLBACK_STREAM_CPU:
		return _failure("Callback table `$886A` no longer resolves selector `$3A` to `$89F3`.")

	# $814C-$8176: load the callback pointer and first command byte.
	_set_a(cpu, 0xF6); _write_ram(ram, writes, 0x814C, 0x0052, int(cpu["a"]))
	_set_a(cpu, 0x87); _write_ram(ram, writes, 0x8150, 0x0053, int(cpu["a"]))
	_set_a(cpu, int(ram[0x0524]))
	if int(cpu["a"]) == 0xFF:
		return _failure("Fresh callback `$3A` unexpectedly takes the source `$8159->$819C` sentinel branch.")
	_set_a(cpu, (int(cpu["a"]) << 1) & 0xFF)
	_set_c(cpu, false)
	_set_y(cpu, int(cpu["a"]))
	var table_address := POINTER_TABLE_CPU + int(cpu["y"])
	var low_index := table_address - 0x886A
	var low_byte := int(sources["pointer"][low_index])
	source_reads.append(_read_event(0x8161, table_address, low_byte, "callback_pointer_low"))
	_set_a(cpu, low_byte)
	_set_x(cpu, int(cpu["a"]))
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var high_address := POINTER_TABLE_CPU + int(cpu["y"])
	var high_index := high_address - 0x886A
	var high_byte := int(sources["pointer"][high_index])
	source_reads.append(_read_event(0x8165, high_address, high_byte, "callback_pointer_high"))
	_set_a(cpu, high_byte)
	_write_ram(ram, writes, 0x8167, 0x0053, int(cpu["a"]))
	_write_ram(ram, writes, 0x8169, 0x0052, int(cpu["x"]))
	_set_a(cpu, 0)
	_write_ram(ram, writes, 0x816D, 0x05D1, 0)
	_write_ram(ram, writes, 0x8170, 0x003A, 0)
	_set_y(cpu, int(ram[0x003A]))
	var first_event_byte := int(sources["stream"][int(cpu["y"])])
	source_reads.append(_read_event(0x8174, CALLBACK_STREAM_CPU + int(cpu["y"]), first_event_byte, "callback_command_length"))
	_set_a(cpu, first_event_byte)
	if int(cpu["a"]) >= 0xF0:
		return _failure("Fresh callback `$3A` unexpectedly takes the source `$8178->$817A` control-record branch.")
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
	var subindex := int(sources["stream"][1])
	source_reads.append(_read_event(0x8197, CALLBACK_STREAM_CPU + 1, subindex, "callback_subindex"))
	_set_a(cpu, subindex)
	if subindex != 0:
		return _failure("Callback `$3A` selects a nonzero inline vector row outside this source slice.")

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
	var vector_low := int(sources["vector"][3])
	source_reads.append(_read_event(0xCB99, 0x81AA, vector_low, "inline_vector_low"))
	_set_a(cpu, vector_low)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCBA4, "PHA")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_high := int(sources["vector"][4])
	source_reads.append(_read_event(0xCB99, 0x81AB, vector_high, "inline_vector_high"))
	_set_a(cpu, vector_high)
	_write_ram(ram, writes, 0xCBA8, 0x0037, int(cpu["a"]))
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCBAA))
	_write_ram(ram, writes, 0xCBAB, 0x0036, int(cpu["a"]))
	var handler_pc := int(ram[0x0036]) | (int(ram[0x0037]) << 8)
	if handler_pc != HANDLER_CPU:
		return _failure("ROM inline dispatch row zero did not resolve to handler `$8327`.")
	cpu["pc"] = handler_pc
	for stack_offset in stack.size():
		ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "reached_first_callback_handler_8327",
		"rom_sha256": ROM_SHA256,
		"source_hashes": {"dispatcher": DISPATCHER_SHA256, "pointer": POINTER_SHA256,
			"stream": STREAM_SHA256, "vector": VECTOR_SHA256,
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
		"callback_id": 0x3A,
		"callback_stream_address": CALLBACK_STREAM_CPU,
		"callback_bytes": sources["stream"].duplicate(),
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
