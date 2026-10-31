extends RefCounted
class_name RomSlot15MapHandlerPrefixExecutor
## Executes the ROM-owned `$8327` map-handler prefix through its JSR entry at `$8525`.
## The `$8525` worker body and its cooperative yield are intentionally separate.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_0b_8327_8360_map_placement_writer.bin"
const SOURCE_SHA256 := "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853"
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
	var source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if FileAccess.get_sha256(SOURCE_PATH) != SOURCE_SHA256 or source.size() != 57 \
			or source.slice(0, PREFIX_BYTES.size()) != PackedByteArray(PREFIX_BYTES):
		return _failure("The packaged `$8327` source prefix failed its size/byte/hash check.")
	if String(handler_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(handler_result.get("status", "")) != "reached_first_callback_handler_8327" \
			or int(handler_result.get("exit_pc", -1)) != 0x8327 \
			or bool(handler_result.get("handler_first_source_instruction_executed", true)) \
			or int(cpu.get("pc", -1)) != 0x8327 or int(cpu.get("a", -1)) != 0x27 \
			or int(cpu.get("x", -1)) != 0xF3 or int(cpu.get("y", -1)) != 2 \
			or int(cpu.get("sp", -1)) != 0xF0 or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != 0x0C or ram.size() != 0x800 \
			or stack.size() != 0x100 or int(ram[0x0000]) != 0x15 \
			or int(ram[0x0052]) != 0xF3 or int(ram[0x0053]) != 0x89 \
			or int(ram[0x05CD]) != int(handler_result.get("incoming_05cd", -1)):
		return _failure("Input is not the live slot-$15 callback at `$8327` with its ROM-derived stream pointer.")
	var command_byte := int(handler_result.get("callback_bytes", PackedByteArray())[2])
	var stream_address := ((int(ram[0x0053]) << 8) | int(ram[0x0052])) + 2
	stream_address &= 0xFFFF
	if command_byte != 0x42 or stream_address != 0x89F5:
		return _failure("The `$8327` operand does not resolve to callback `$3A` byte `$42` at `$89F5`.")
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
	return {
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
		"map_selector": command_byte,
		"placement_input": int(entry_ram[0x05CD]),
		"worker_body_executed": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


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
