extends RefCounted
class_name RomSlot15MapHandlerPrefixExecutor
## Executes the ROM-owned `$8327` map-handler prefix through its JSR entry at `$8525`.
## The `$8525` worker body and its cooperative yield are intentionally separate.

const MAP_2D_FIRST_BATCH_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_slot15_map2d_first_batch_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_0b_8327_8360_map_placement_writer.bin"
const SOURCE_SHA256 := "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853"
const CALLBACK_ROOT := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/"
const CALLBACK_1F_HANDLER_PATH := CALLBACK_ROOT + "bank_0b_callback_1f_handler_8358_8363.bin"
const CALLBACK_1F_HANDLER_SHA256 := "4608ed725100263c59ba0e97f43b0780557c95e00de4f2287a156c107d070b80"
const CALLBACK_POSITION_HELPER_PATH := CALLBACK_ROOT + "bank_0b_callback_position_helper_84d9_84f3.bin"
const CALLBACK_POSITION_HELPER_SHA256 := "bf21bf551725d1142b371fa5a0327548b065a47c690058fa079cbed6cb8933d7"
const CALLBACK_DATA_HELPER_PATH := CALLBACK_ROOT + "bank_0b_callback_data_helper_84f4_8501.bin"
const CALLBACK_DATA_HELPER_SHA256 := "d35e51722841a82e73b1c36aa6c10fd3ddc261922ccfb50da15f8a2c7c04b7d4"
const CALLBACK_34_STREAM_CPU := 0x89E1
const CALLBACK_34_STREAM_BYTES := [0x02, 0x00, 0x2D]
const CALLBACK_36_STREAM_CPU := 0x89E7
const CALLBACK_36_STREAM_BYTES := [0x02, 0x00, 0x2F]
const CALLBACK_63_STREAM_CPU := 0x8AD8
const CALLBACK_63_STREAM_BYTES := [0x02, 0x00, 0x51]
const PREFIX_BYTES := [
	0xA0, 0x02,             # LDY #$02
	0xB1, 0x52,             # LDA ($52),Y
	0x8D, 0xCC, 0x05,        # STA $05CC
	0xAC, 0xCD, 0x05,        # LDY $05CD
	0x20, 0x25, 0x85,        # JSR $8525
]
const P_N := 0x80
const P_Z := 0x02
const P_NZ := P_N | P_Z

var error_message := ""


func execute_from_handler_boundary(handler_result: Dictionary) -> Dictionary:
	error_message = ""
	var entry_variant: Variant = handler_result.get("registers", {})
	var ram_variant: Variant = handler_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = handler_result.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = handler_result.get("mapper", {})
	if not entry_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not mapper_variant is Dictionary:
		return _failure("The `$8327` boundary omits CPU, mapper, RAM, or stack state.")
	var cpu: Dictionary = entry_variant.duplicate(true)
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var mapper: Dictionary = mapper_variant
	var callback_id := int(handler_result.get("callback_id", -1))
	if callback_id == 0x1F:
		return _execute_callback_1f_map_entry(handler_result, cpu, ram, stack, mapper)
	var callback_34 := callback_id == 0x34
	var callback_36 := callback_id == 0x36
	var scenario1c_callback63 := callback_id == 0x63 \
			and int(handler_result.get("scenario", -1)) == 0x1C
	var scenario2e_callback36 := callback_36 and int(handler_result.get("scenario", -1)) == 0x2E
	var expected_stream_pointer := CALLBACK_63_STREAM_CPU if scenario1c_callback63 else (0x8B38 if callback_id == 0x70 else (CALLBACK_36_STREAM_CPU if scenario2e_callback36 else (CALLBACK_34_STREAM_CPU if callback_34 else (0x8911 if callback_id == 0x0C else (0x8A2A if callback_id == 0x45 else 0x89F3)))))
	var expected_stream_low := expected_stream_pointer & 0xFF
	var expected_stream_high := expected_stream_pointer >> 8
	var source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if FileAccess.get_sha256(SOURCE_PATH) != SOURCE_SHA256 or source.size() != 57 \
			or source.slice(0, PREFIX_BYTES.size()) != PackedByteArray(PREFIX_BYTES):
		return _failure("The packaged `$8327` source prefix failed its size/byte/hash check.")
	if String(handler_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(handler_result.get("status", "")) != "reached_first_callback_handler_8327" \
			or int(handler_result.get("exit_pc", -1)) != 0x8327 \
			or (callback_34 and int(handler_result.get("scenario", -1)) != 0x38) \
			or bool(handler_result.get("handler_first_source_instruction_executed", true)) \
			or int(cpu.get("pc", -1)) != 0x8327 or int(cpu.get("a", -1)) != 0x27 \
			or int(cpu.get("x", -1)) != expected_stream_low or int(cpu.get("y", -1)) != 2 \
			or int(cpu.get("sp", -1)) != 0xF0 or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != 0x0C or ram.size() != 0x800 \
			or stack.size() != 0x100 or int(ram[0x0000]) != 0x15 \
			or int(ram[0x0052]) != expected_stream_low or int(ram[0x0053]) != expected_stream_high \
			or int(ram[0x05CD]) != int(handler_result.get("incoming_05cd", -1)):
		return _failure("Input is not the live slot-$15 callback at `$8327` with its ROM-derived stream pointer.")
	var callback_bytes_variant: Variant = handler_result.get("callback_bytes", PackedByteArray())
	if not callback_bytes_variant is PackedByteArray or callback_bytes_variant.size() < 3:
		return _failure("The callback boundary omits the map-selector byte.")
	var callback_bytes: PackedByteArray = callback_bytes_variant
	var command_byte := int(callback_bytes[2])
	var stream_address := ((int(ram[0x0053]) << 8) | int(ram[0x0052])) + 2
	stream_address &= 0xFFFF
	var expected_stream_address := 0x8ADA if scenario1c_callback63 else (0x8B3A if callback_id == 0x70 else (0x89E9 if scenario2e_callback36 else (0x89E3 if callback_34 else (0x8913 if callback_id == 0x0C else (0x8A2C if callback_id == 0x45 else 0x89F5)))))
	var expected_map_selector := 0x51 if scenario1c_callback63 else (0x56 if callback_id == 0x70 else (0x2F if scenario2e_callback36 else (0x2D if callback_34 else (0x43 if callback_id == 0x0C else (0x36 if callback_id == 0x45 else 0x42)))))
	if callback_id not in [0x3A, 0x0C, 0x34, 0x36, 0x45, 0x63, 0x70] \
			or (callback_id == 0x63 and not scenario1c_callback63) \
			or (callback_36 and not scenario2e_callback36) \
			or command_byte != expected_map_selector \
			or stream_address != expected_stream_address:
		return _failure("The `$8327` operand does not resolve to the checked callback map byte for `$%02X`." % callback_id)
	if callback_34 and callback_bytes != PackedByteArray(CALLBACK_34_STREAM_BYTES):
		return _failure("Callback `$34` stream does not match the ROM-derived `02 00 2D` prefix.")
	if scenario2e_callback36 and callback_bytes != PackedByteArray(CALLBACK_36_STREAM_BYTES):
		return _failure("Scenario-$2E callback `$36` stream does not match the ROM-derived `02 00 2F` bytes.")
	if scenario1c_callback63 and callback_bytes != PackedByteArray(CALLBACK_63_STREAM_BYTES):
		return _failure("Scenario-$1C callback `$63` stream does not match the ROM-derived `02 00 51` bytes.")
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []

	# LDY #$02
	cpu["y"] = 0x02
	_set_nz(cpu, 0x02)
	# LDA ($52),Y. The checked callback record is the source of this operand.
	source_reads.append({"pc": 0x8329, "address": stream_address,
		"value": command_byte, "kind": "callback_command_byte"})
	cpu["a"] = command_byte
	_set_nz(cpu, command_byte)
	# STA $05CC
	ram[0x05CC] = command_byte
	ram_writes.append({"pc": 0x832B, "address": 0x05CC, "value": command_byte,
		"kind": "callback_map_selector"})
	# LDY $05CD. Preserve the source-owned placement input; its earlier writer
	# remains a separate provenance question.
	cpu["y"] = int(ram[0x05CD])
	_set_nz(cpu, int(cpu["y"]))
	# JSR $8525 pushes PC+2-1, high byte then low byte.
	var return_word := 0x8333
	var sp := int(cpu["sp"])
	stack[sp] = (return_word >> 8) & 0xFF
	stack_writes.append({"pc": 0x8331, "address": 0x0100 | sp,
		"value": (return_word >> 8) & 0xFF, "kind": "JSR_return_high"})
	sp = (sp - 1) & 0xFF
	stack[sp] = return_word & 0xFF
	stack_writes.append({"pc": 0x8331, "address": 0x0100 | sp,
		"value": return_word & 0xFF, "kind": "JSR_return_low"})
	sp = (sp - 1) & 0xFF
	cpu["sp"] = sp
	cpu["pc"] = 0x8525
	for stack_offset in stack.size():
		ram[0x0100 + stack_offset] = stack[stack_offset]
	var result := {
		"ok": true,
		"status": "entered_map_worker_8525",
		"rom_sha256": ROM_SHA256,
		"source_sha256": SOURCE_SHA256,
		"source_hashes": {"handler_8327": SOURCE_SHA256},
		"entry_pc": 0x8327,
		"exit_pc": 0x8525,
		"entry_registers": entry_cpu,
		"registers": cpu,
		"mapper": mapper.duplicate(true),
		"entry_ram_image": entry_ram,
		"ram_image": ram,
		"entry_stack_page": entry_stack,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"source_reads": source_reads,
		"source_bytes_executed": PackedByteArray(PREFIX_BYTES),
		"scenario": int(handler_result.get("scenario", -1)),
		"callback_id": callback_id,
		"map_selector": command_byte,
		"placement_input": int(entry_ram[0x05CD]),
		"worker_body_executed": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}
	if callback_id == 0x34:
		var first_batch_executor = MAP_2D_FIRST_BATCH_EXECUTOR_SCRIPT.new()
		var first_batch_result: Dictionary = first_batch_executor.execute_first_batch_source(result)
		if not bool(first_batch_result.get("ok", false)):
			return _failure(String(first_batch_result.get("error", "Map-$2D source resolution failed.")))
		result["map_2d_first_batch_source"] = first_batch_result
	return result


func _execute_callback_1f_map_entry(handler_result: Dictionary, cpu: Dictionary,
		ram: PackedByteArray, stack: PackedByteArray, mapper: Dictionary) -> Dictionary:
	var callback_bytes_variant: Variant = handler_result.get("callback_bytes", PackedByteArray())
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	if not callback_bytes_variant is PackedByteArray:
		return _failure("Callback `$1F` result omits its pointer-bounded data stream.")
	var callback_bytes: PackedByteArray = callback_bytes_variant
	var placement_input := int(ram[0x05CD]) if ram.size() == 0x800 else -1
	var handler_source := FileAccess.get_file_as_bytes(CALLBACK_1F_HANDLER_PATH)
	var position_source := FileAccess.get_file_as_bytes(CALLBACK_POSITION_HELPER_PATH)
	var data_source := FileAccess.get_file_as_bytes(CALLBACK_DATA_HELPER_PATH)
	var common_source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if FileAccess.get_sha256(CALLBACK_1F_HANDLER_PATH) != CALLBACK_1F_HANDLER_SHA256 \
			or FileAccess.get_sha256(CALLBACK_POSITION_HELPER_PATH) != CALLBACK_POSITION_HELPER_SHA256 \
			or FileAccess.get_sha256(CALLBACK_DATA_HELPER_PATH) != CALLBACK_DATA_HELPER_SHA256 \
			or handler_source != PackedByteArray([0x20, 0xD9, 0x84, 0xA9, 0x80, 0x8D, 0xD1, 0x05, 0xA0, 0x04, 0xD0, 0xC5]) \
			or position_source != PackedByteArray([0x20, 0xF4, 0x84, 0x2C, 0x2A, 0x05, 0x50, 0x0C, 0x8A, 0x49, 0xFF, 0xAA, 0x98, 0x49, 0xFF, 0xA8, 0xE8, 0xD0, 0x01, 0xC8, 0x8E, 0xDE, 0x05, 0x8C, 0xDF, 0x05, 0x60]) \
			or data_source != PackedByteArray([0xA0, 0x02, 0xB1, 0x52, 0xAA, 0xC8, 0xB1, 0x52, 0xA8, 0xC9, 0x80, 0xF0, 0x01, 0x60]) \
			or common_source.size() != 57 or common_source.slice(2, 13) != PackedByteArray(PREFIX_BYTES).slice(2, 13):
		return _failure("Callback `$1F` handler/helper or common map-entry ROM bytes failed verification.")
	if String(handler_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(handler_result.get("status", "")) != "reached_first_callback_handler_8358" \
			or int(handler_result.get("entry_pc", -1)) != 0x814C \
			or int(handler_result.get("exit_pc", -1)) != 0x8358 \
			or int(handler_result.get("scenario", -1)) not in [0x1C, 0x36] \
			or int(handler_result.get("callback_id", -1)) != 0x1F \
			or callback_bytes != PackedByteArray([0x02, 0x03, 0x00, 0x04, 0x52]) \
			or bool(handler_result.get("handler_first_source_instruction_executed", true)) \
			or bool(handler_result.get("trace_state_used", true)) \
			or int(cpu.get("pc", -1)) != 0x8358 or int(cpu.get("sp", -1)) != 0xF0 \
			or int(mapper.get("bank_low", -1)) != 0x0B or int(mapper.get("bank_high", -1)) != 0x0C \
			or ram.size() != 0x800 or stack.size() != 0x100 \
			or int(ram[0x052A]) != 0x40 or placement_input not in [0x80, 0xA0] \
			or int(ram[0x0052]) != 0x6A or int(ram[0x0053]) != 0x89:
		return _failure("Input is not the live callback `$1F` handler state at `$8358` for map `$52`: pc=$%04X sp=$%02X banks=$%02X/$%02X ram52A/CD=%02X/%02X ptr52/53=%02X%02X." % [
			int(cpu.get("pc", -1)), int(cpu.get("sp", -1)),
			int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1)),
			int(ram[0x052A]) if ram.size() == 0x800 else -1,
			int(ram[0x05CD]) if ram.size() == 0x800 else -1,
			int(ram[0x0053]) if ram.size() == 0x800 else -1,
			int(ram[0x0052]) if ram.size() == 0x800 else -1])
	var entry_cpu := cpu.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var stream_base := int(ram[0x0052]) | (int(ram[0x0053]) << 8)

	# `$8358 JSR $84D9`; this helper reads the callback's two position bytes.
	instruction_pcs.append(0x8358)
	_push_jsr(cpu, stack, stack_writes, 0x8358, 0x84D9)
	instruction_pcs.append_array([0x84D9, 0x84F4, 0x84F6, 0x84F8, 0x84F9, 0x84FA, 0x84FC, 0x84FD, 0x84FF, 0x8501])
	_push_jsr(cpu, stack, stack_writes, 0x84D9, 0x84F4)
	cpu["y"] = 0x02
	_set_nz(cpu, 0x02)
	var x_position := int(callback_bytes[2])
	source_reads.append({"pc": 0x84F6, "address": stream_base + 2, "value": x_position, "kind": "callback_position_x"})
	cpu["a"] = x_position
	cpu["x"] = x_position
	_set_nz(cpu, x_position)
	cpu["y"] = 0x03
	_set_nz(cpu, 0x03)
	var y_position := int(callback_bytes[3])
	source_reads.append({"pc": 0x84FA, "address": stream_base + 3, "value": y_position, "kind": "callback_position_y"})
	cpu["a"] = y_position
	cpu["y"] = y_position
	_set_nz(cpu, y_position)
	if y_position == 0x80:
		return _failure("Callback `$1F` position helper unexpectedly takes its `$84FF` early return.")
	cpu["a"] = y_position
	_set_nz(cpu, y_position)
	var data_helper_return := _rts(cpu, stack, stack_reads, 0x8501)
	if data_helper_return != 0x84DC:
		return _failure("Callback `$1F` data helper did not return to `$84DC`.")
	# BIT $052A selects the source's bit-$40 coordinate mirror path.
	instruction_pcs.append_array([0x84DC, 0x84DF, 0x84E1, 0x84E2, 0x84E4, 0x84E5, 0x84E6, 0x84E8, 0x84E9, 0x84EA, 0x84EC])
	var original_x := int(cpu["x"])
	var original_y := int(cpu["y"])
	var mirror_enabled := (int(ram[0x052A]) & 0x40) != 0
	if mirror_enabled:
		cpu["a"] = original_x ^ 0xFF
		cpu["x"] = int(cpu["a"])
		_set_nz(cpu, int(cpu["x"]))
		cpu["a"] = original_y ^ 0xFF
		cpu["y"] = int(cpu["a"])
		_set_nz(cpu, int(cpu["y"]))
		cpu["x"] = (int(cpu["x"]) + 1) & 0xFF
		_set_nz(cpu, int(cpu["x"]))
		if int(cpu["x"]) == 0:
			cpu["y"] = (int(cpu["y"]) + 1) & 0xFF
			_set_nz(cpu, int(cpu["y"]))
		var mirrored_x := int(cpu["x"])
		var mirrored_y := int(cpu["y"])
		ram[0x05DE] = mirrored_x
		ram_writes.append({"pc": 0x84ED, "address": 0x05DE, "value": mirrored_x, "kind": "mirrored_position_x"})
		ram[0x05DF] = mirrored_y
		ram_writes.append({"pc": 0x84F0, "address": 0x05DF, "value": mirrored_y, "kind": "mirrored_position_y"})
	else:
		return _failure("Callback `$1F` trace does not enable the checked `$052A` bit-$40 transform.")
	var position_return := _rts(cpu, stack, stack_reads, 0x84F3)
	if position_return != 0x835B:
		return _failure("Callback `$1F` position helper did not return to `$835B`.")

	# `$835B-$8363` sets the callback's staging byte and joins common code at `$8329`.
	instruction_pcs.append_array([0x835B, 0x835D, 0x8360, 0x8362, 0x8329, 0x832B, 0x832E, 0x8331])
	cpu["a"] = 0x80
	_set_nz(cpu, 0x80)
	ram[0x05D1] = 0x80
	ram_writes.append({"pc": 0x835D, "address": 0x05D1, "value": 0x80, "kind": "callback_staging_flag"})
	cpu["y"] = 0x04
	_set_nz(cpu, 0x04)
	var map_byte_address := stream_base + int(cpu["y"])
	var map_id := int(callback_bytes[4])
	source_reads.append({"pc": 0x8329, "address": map_byte_address, "value": map_id, "kind": "callback_map_id"})
	cpu["a"] = map_id
	_set_nz(cpu, map_id)
	ram[0x05CC] = map_id
	ram_writes.append({"pc": 0x832B, "address": 0x05CC, "value": map_id, "kind": "callback_map_selector"})
	cpu["y"] = int(ram[0x05CD])
	_set_nz(cpu, int(cpu["y"]))
	_push_jsr(cpu, stack, stack_writes, 0x8331, 0x8525)
	if map_id != 0x52 or int(ram[0x05DE]) != 0x00 or int(ram[0x05DF]) != 0xFC \
			or int(ram[0x05D1]) != 0x80 or int(ram[0x05CD]) != placement_input \
			or int(cpu["pc"]) != 0x8525 or int(cpu["a"]) != 0x52 \
			or int(cpu["x"]) != 0x00 or int(cpu["y"]) != placement_input or int(cpu["sp"]) != 0xEE:
		return _failure("Callback `$1F` `$8358->$8525` CPU or map-$52 RAM output differs from its checked source path.")
	for stack_offset in stack.size():
		ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "entered_map_worker_8525",
		"rom_sha256": ROM_SHA256,
		"source_hashes": {
			"handler_8358": CALLBACK_1F_HANDLER_SHA256,
			"position_helper_84d9": CALLBACK_POSITION_HELPER_SHA256,
			"data_helper_84f4": CALLBACK_DATA_HELPER_SHA256,
			"handler_8329_common": SOURCE_SHA256,
		},
		"entry_pc": 0x8358,
		"exit_pc": 0x8525,
		"entry_registers": entry_cpu,
		"registers": cpu,
		"mapper": mapper.duplicate(true),
		"entry_ram_image": entry_ram,
		"ram_image": ram,
		"entry_stack_page": entry_stack,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"source_bytes_executed": PackedByteArray(PREFIX_BYTES),
		"callback_id": 0x1F,
		"map_selector": map_id,
		"placement_input": int(entry_ram[0x05CD]),
		"worker_body_executed": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


func _push_jsr(cpu: Dictionary, stack: PackedByteArray, writes: Array[Dictionary],
		pc: int, target: int) -> void:
	var return_word := pc + 2
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = (return_word >> 8) & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": (return_word >> 8) & 0xFF, "kind": "JSR_return_high"})
	sp = (sp - 1) & 0xFF
	stack[sp] = return_word & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": return_word & 0xFF, "kind": "JSR_return_low"})
	cpu["sp"] = (sp - 1) & 0xFF
	cpu["pc"] = target


func _rts(cpu: Dictionary, stack: PackedByteArray, reads: Array[Dictionary], pc: int) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var low := int(stack[sp])
	reads.append({"pc": pc, "address": 0x0100 | sp, "value": low, "kind": "RTS_return_low"})
	sp = (sp + 1) & 0xFF
	var high := int(stack[sp])
	reads.append({"pc": pc, "address": 0x0100 | sp, "value": high, "kind": "RTS_return_high"})
	cpu["sp"] = sp
	return (((high << 8) | low) + 1) & 0xFFFF


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := int(cpu.get("p", 0)) & ~P_NZ
	if (value & 0x80) != 0:
		p |= P_N
	if (value & 0xFF) == 0:
		p |= P_Z
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ


func _failure(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_execution_refused", "error": reason,
		"trace_state_used": false}
