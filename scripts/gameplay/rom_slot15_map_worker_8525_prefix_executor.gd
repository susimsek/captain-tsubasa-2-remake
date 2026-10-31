extends RefCounted
class_name RomSlot15MapWorker8525PrefixExecutor
## Runs fresh callback `$42` in `$8525` through the first `$856F JSR $C515`
## callsite. It stops before yielding; map-row queue construction is later work.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/first_command_field/map_worker_8525/"
const WORKER_PATH := ROOT + "bank_0b_8525_856f_pre_yield.bin"
const WORKER_SHA256 := "1b406e85c56269d2369ebe99eb26c662b48fe32aedfb55c40e654bf3bc4e0f8a"
const SELECTOR_ROUTINE_PATH := ROOT + "bank_0b_86d3_86ee_map_selector_lookup.bin"
const SELECTOR_ROUTINE_SHA256 := "08c5584a0bae0feb953cd6f98c7a8dc792d1304c047872dd8f6b145ac7a555b7"
const CHR_PAIR_PATH := ROOT + "bank_0b_86ee_map_42_chr_pair.bin"
const CHR_PAIR_SHA256 := "50ccd3ef9e7c33fc6961800add05d3ed815ad357d03d7fbfcb74354a40986c46"
const YIELD_CALLSITE_PATH := ROOT + "bank_0b_856f_8572_c515_callsite.bin"
const YIELD_CALLSITE_SHA256 := "59653ff81dfe5c01f141d4ee69bb4832290c727091c41b92a71a6b0e2400a837"
const SELECTOR_TABLE_PATH := "res://reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/packed_map_selectors_8B42.bin"
const SELECTOR_TABLE_SHA256 := "2dac66189d5f3d9e733016f5005bb1b667822781cf5be50e27753f3b814c170e"
const P_N := 0x80
const P_V := 0x40
const P_Z := 0x02
const P_C := 0x01
const P_NZ := P_N | P_Z

var error_message := ""


func execute_map_42_to_first_yield_callsite(worker_entry: Dictionary) -> Dictionary:
	error_message = ""
	var loaded := _load_sources()
	if not bool(loaded.get("ok", false)):
		return _failure(String(loaded.get("error", "Map-worker source load failed.")))
	var source: Dictionary = loaded["source"]
	var entry_variant: Variant = worker_entry.get("registers", {})
	var ram_variant: Variant = worker_entry.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_entry.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = worker_entry.get("mapper", {})
	if not entry_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not mapper_variant is Dictionary:
		return _failure("Map worker `$8525` entry omits CPU, RAM, stack, or mapper state.")
	var cpu: Dictionary = entry_variant.duplicate(true)
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var mapper: Dictionary = mapper_variant
	if ram.size() != 0x800 or stack.size() != 0x100:
		return _failure("Map-worker entry has the wrong RAM or stack-page size.")
	if String(worker_entry.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_entry.get("status", "")) != "entered_map_worker_8525" \
			or int(worker_entry.get("exit_pc", -1)) != 0x8525 \
			or int(cpu.get("pc", -1)) != 0x8525 or int(cpu.get("a", -1)) != 0x42 \
			or int(cpu.get("x", -1)) != 0xF3 or int(cpu.get("y", -1)) != int(ram[0x05CD]) \
			or int(cpu.get("sp", -1)) != 0xEE or int(ram[0x0000]) != 0x15 \
			or int(ram[0x05CC]) != 0x42 or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != 0x0C or ram.size() != 0x800 \
			or stack.size() != 0x100 or bool(worker_entry.get("trace_state_used", true)):
		return _failure("Input is not the active slot-$15 fresh map-$42 worker at `$8525`.")
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var map_id := int(ram[0x05CC])
	if map_id != 0x42:
		return _failure("This bounded source path is limited to fresh callback map `$42`.")

	# `$8525`: retain placement in `$05C8`, save map ID, and load CHR selector pair.
	instruction_pcs.append(0x8525) # STY $05C8
	_write_ram(ram, ram_writes, 0x05C8, int(cpu["y"]), 0x8525, "map_placement_copy")
	instruction_pcs.append(0x8528) # PHA
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0x8528, "map_id")
	instruction_pcs.append(0x8529) # TAX
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0x852A) # LDA #$EE
	_set_a(cpu, 0xEE)
	instruction_pcs.append(0x852C) # STA $54
	_write_ram(ram, ram_writes, 0x0054, int(cpu["a"]), 0x852C, "chr_pair_pointer_low")
	instruction_pcs.append(0x852E) # LDA #$86
	_set_a(cpu, 0x86)
	instruction_pcs.append(0x8530) # STA $55
	_write_ram(ram, ram_writes, 0x0055, int(cpu["a"]), 0x8530, "chr_pair_pointer_high")
	instruction_pcs.append(0x8532) # TXA
	_set_a(cpu, int(cpu["x"]))
	instruction_pcs.append(0x8533) # ASL A
	_asl_a(cpu)
	instruction_pcs.append(0x8534) # BCC $8538; map $42 takes this path
	if (int(cpu["p"]) & P_C) != 0:
		return _failure("Map `$42` unexpectedly carries out of the CHR-pair index shift.")
	instruction_pcs.append(0x8538) # TAY
	_set_y(cpu, int(cpu["a"]))
	var pair_address := 0x86EE + int(cpu["y"])
	source_reads.append(_read(pair_address, int(source["chr_pair"][0]), "map_42_chr_pair_first"))
	instruction_pcs.append(0x8539) # LDA ($54),Y
	_set_a(cpu, int(source["chr_pair"][0]))
	instruction_pcs.append(0x853B) # ORA #$80
	_set_a(cpu, int(cpu["a"]) | 0x80)
	instruction_pcs.append(0x853D) # STA $0526
	_write_ram(ram, ram_writes, 0x0526, int(cpu["a"]), 0x853D, "staged_chr_selector_a")
	instruction_pcs.append(0x8540) # INY
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	source_reads.append(_read(pair_address + 1, int(source["chr_pair"][1]), "map_42_chr_pair_second"))
	instruction_pcs.append(0x8541) # LDA ($54),Y
	_set_a(cpu, int(source["chr_pair"][1]))
	instruction_pcs.append(0x8543) # STA $0527
	_write_ram(ram, ram_writes, 0x0527, int(cpu["a"]), 0x8543, "staged_chr_selector_b")
	instruction_pcs.append(0x8546) # PLA
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x8546, "map_id"))

	# `$86D3`: resolve map $42's packed selector using the actual ROM table.
	instruction_pcs.append(0x8547) # JSR $86D3
	var selector_return := 0x8549
	_push(cpu, stack, stack_writes, (selector_return >> 8) & 0xFF, 0x8547, "selector_jsr_return_high")
	_push(cpu, stack, stack_writes, selector_return & 0xFF, 0x8547, "selector_jsr_return_low")
	instruction_pcs.append(0x86D3) # PHA
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0x86D3, "selector_map_id")
	instruction_pcs.append(0x86D4) # AND #$03
	_set_a(cpu, int(cpu["a"]) & 0x03)
	instruction_pcs.append(0x86D6) # TAX
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0x86D7) # PLA
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x86D7, "selector_map_id"))
	instruction_pcs.append(0x86D8) # PHA
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0x86D8, "selector_shift_input")
	instruction_pcs.append_array([0x86D9, 0x86DA]) # LSR A twice
	_lsr_a(cpu)
	_lsr_a(cpu)
	instruction_pcs.append(0x86DB) # TAY
	_set_y(cpu, int(cpu["a"]))
	var selector_index := map_id >> 2
	var selector_value := int(source["selector_table"][selector_index])
	source_reads.append(_read(0x8B42 + selector_index, selector_value, "packed_map_selector"))
	instruction_pcs.append(0x86DC) # LDA $8B42,Y
	_set_a(cpu, selector_value)
	while true:
		instruction_pcs.append(0x86DF) # DEX
		_set_x(cpu, (int(cpu["x"]) - 1) & 0xFF)
		instruction_pcs.append(0x86E0) # BMI $86E7
		if (int(cpu["p"]) & P_N) != 0:
			break
		instruction_pcs.append_array([0x86E2, 0x86E3]) # LSR A twice
		_lsr_a(cpu)
		_lsr_a(cpu)
		instruction_pcs.append(0x86E4) # JMP $86DF
	instruction_pcs.append(0x86E7) # AND #$03
	_set_a(cpu, int(cpu["a"]) & 0x03)
	instruction_pcs.append(0x86E9) # STA $05CA
	_write_ram(ram, ram_writes, 0x05CA, int(cpu["a"]), 0x86E9, "block_map_selector")
	instruction_pcs.append(0x86EC) # PLA
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x86EC, "selector_shift_input"))
	instruction_pcs.append(0x86ED) # RTS
	var low_return := _pop(cpu, stack, stack_reads, 0x86ED, "selector_jsr_return_low")
	var high_return := _pop(cpu, stack, stack_reads, 0x86ED, "selector_jsr_return_high")
	if ((high_return << 8) | low_return) + 1 != 0x854A:
		return _failure("The `$86D3` RTS did not restore `$854A` from its JSR frame.")
	
	# Finish `$8525`'s tile-map pointer arithmetic and stop before JSR `$C515`.
	instruction_pcs.append(0x854A) # LDX #$00
	_set_x(cpu, 0)
	instruction_pcs.append(0x854C) # STX $54
	_write_ram(ram, ram_writes, 0x0054, int(cpu["x"]), 0x854C, "map_pointer_low_clear")
	for pc: int in [0x854E, 0x8551, 0x8554]:
		instruction_pcs.append(pc) # LSR A
		_lsr_a(cpu)
		instruction_pcs.append(pc + 1) # ROR $54
		_ror_ram(cpu, ram, ram_writes, 0x0054, pc + 1)
	instruction_pcs.append(0x8557) # TAX
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0x8558) # LDA $54
	_set_a(cpu, int(ram[0x0054]))
	instruction_pcs.append(0x855A) # CLC
	_set_c(cpu, false)
	instruction_pcs.append(0x855B) # ADC #$64
	_adc(cpu, 0x64)
	instruction_pcs.append(0x855D) # STA $54
	_write_ram(ram, ram_writes, 0x0054, int(cpu["a"]), 0x855D, "map_row_pointer_low")
	instruction_pcs.append(0x855F) # TXA
	_set_a(cpu, int(cpu["x"]))
	instruction_pcs.append(0x8560) # ADC #$8B
	_adc(cpu, 0x8B)
	instruction_pcs.append(0x8562) # STA $55
	_write_ram(ram, ram_writes, 0x0055, int(cpu["a"]), 0x8562, "map_row_pointer_high")
	instruction_pcs.append(0x8564) # LDA #$20
	_set_a(cpu, 0x20)
	instruction_pcs.append(0x8566) # STA $05C9
	_write_ram(ram, ram_writes, 0x05C9, int(cpu["a"]), 0x8566, "map_row_count")
	instruction_pcs.append(0x8569) # LDA $05CA
	_set_a(cpu, int(ram[0x05CA]))
	instruction_pcs.append(0x856C) # PHA
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0x856C, "map_selector_for_worker")
	instruction_pcs.append(0x856D) # LDA #$01
	_set_a(cpu, 0x01)
	cpu["pc"] = 0x856F
	if int(cpu["a"]) != 1 or int(cpu["x"]) != 8 or int(cpu["y"]) != 0x10 \
			or int(cpu["sp"]) != 0xED or int(cpu["p"]) != 0x20 \
			or int(ram[0x05CA]) != 1 or int(ram[0x0526]) != 0xBC \
			or int(ram[0x0527]) != 0x2C or int(ram[0x0054]) != 0xA4 \
			or int(ram[0x0055]) != 0x93 or int(ram[0x05C9]) != 0x20:
		return _failure("Map `$42` worker setup disagrees at `$856F`: CPU=%s RAM={0526:%02X,0527:%02X,05CA:%02X,0054:%02X,0055:%02X,05C9:%02X}." % [str(cpu), int(ram[0x0526]), int(ram[0x0527]), int(ram[0x05CA]), int(ram[0x0054]), int(ram[0x0055]), int(ram[0x05C9])])
	for stack_offset in stack.size():
		ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "reached_first_map_worker_yield_callsite",
		"rom_sha256": ROM_SHA256,
		"source_hashes": {"worker_8525": WORKER_SHA256,
			"selector_routine_86d3": SELECTOR_ROUTINE_SHA256,
			"chr_pair_42": CHR_PAIR_SHA256,
			"packed_selector_table": SELECTOR_TABLE_SHA256,
			"yield_callsite": YIELD_CALLSITE_SHA256},
		"entry_pc": 0x8525,
		"exit_pc": 0x856F,
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
		"source_bytes_executed": source["worker"].duplicate(),
		"map_id": map_id,
		"map_selector": int(ram[0x05CA]),
		"chr_pair": PackedByteArray([int(source["chr_pair"][0]), int(source["chr_pair"][1])]),
		"staged_chr_pair": PackedByteArray([int(ram[0x0526]), int(ram[0x0527])]),
		"map_data_pointer": int(ram[0x0054]) | (int(ram[0x0055]) << 8),
		"placement": int(ram[0x05C8]),
		"row_count": int(ram[0x05C9]),
		"yield_callsite": 0x856F,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


func _load_sources() -> Dictionary:
	var paths := {
		"worker": [WORKER_PATH, WORKER_SHA256, 0x4A],
		"selector_routine": [SELECTOR_ROUTINE_PATH, SELECTOR_ROUTINE_SHA256, 0x1B],
		"chr_pair": [CHR_PAIR_PATH, CHR_PAIR_SHA256, 0x02],
		"selector_table": [SELECTOR_TABLE_PATH, SELECTOR_TABLE_SHA256, 0x22],
		"yield_callsite": [YIELD_CALLSITE_PATH, YIELD_CALLSITE_SHA256, 0x03],
	}
	var source: Dictionary = {}
	for key: String in paths:
		var item: Array = paths[key]
		var path := String(item[0])
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != int(item[2]) or FileAccess.get_sha256(path) != String(item[1]):
			return {"ok": false, "error": "Map-worker ROM bytes failed size/hash validation: %s" % path}
		source[key] = bytes
	if source["worker"].slice(0x22, 0x25) != PackedByteArray([0x20, 0xD3, 0x86]) \
			or source["selector_routine"].slice(0, 5) != PackedByteArray([0x48, 0x29, 0x03, 0xAA, 0x68]) \
			or source["chr_pair"] != PackedByteArray([0x3C, 0x2C]) \
			or source["yield_callsite"] != PackedByteArray([0x20, 0x15, 0xC5]):
		return {"ok": false, "error": "Map `$42` worker code or source table entry differs from the decoded ROM path."}
	return {"ok": true, "source": source}


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], address: int,
		value: int, pc: int, kind: String) -> void:
	ram[address] = value & 0xFF
	writes.append({"pc": pc, "address": address, "value": value & 0xFF, "kind": kind})


func _push(cpu: Dictionary, stack: PackedByteArray, writes: Array[Dictionary],
		value: int, pc: int, kind: String) -> void:
	var sp := int(cpu["sp"])
	stack[sp] = value & 0xFF
	writes.append({"pc": pc, "address": 0x0100 | sp, "value": value & 0xFF, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop(cpu: Dictionary, stack: PackedByteArray, reads: Array[Dictionary],
		pc: int, kind: String) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	var value := int(stack[sp])
	cpu["sp"] = sp
	reads.append({"pc": pc, "address": 0x0100 | sp, "value": value, "kind": kind})
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


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := (int(cpu.get("p", 0)) & ~P_NZ) | 0x20
	if (value & 0x80) != 0:
		p |= P_N
	if (value & 0xFF) == 0:
		p |= P_Z
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ


func _set_c(cpu: Dictionary, carry: bool) -> void:
	var p := (int(cpu.get("p", 0)) & ~P_C) | 0x20
	if carry:
		p |= P_C
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_C


func _asl_a(cpu: Dictionary) -> void:
	var value := int(cpu["a"])
	var result := (value << 1) & 0xFF
	_set_c(cpu, (value & 0x80) != 0)
	_set_a(cpu, result)


func _lsr_a(cpu: Dictionary) -> void:
	var value := int(cpu["a"])
	_set_c(cpu, (value & 1) != 0)
	_set_a(cpu, value >> 1)


func _ror_ram(cpu: Dictionary, ram: PackedByteArray, writes: Array[Dictionary],
		address: int, pc: int) -> void:
	var old_value := int(ram[address])
	var carry_in := 0x80 if (int(cpu["p"]) & P_C) != 0 else 0
	_set_c(cpu, (old_value & 1) != 0)
	var value := (old_value >> 1) | carry_in
	_write_ram(ram, writes, address, value, pc, "map_pointer_rotate")
	_set_nz(cpu, value)


func _set_c_with_v(cpu: Dictionary, carry: bool, overflow: bool) -> void:
	var p := (int(cpu.get("p", 0)) & ~(P_C | P_V)) | 0x20
	if carry:
		p |= P_C
	if overflow:
		p |= P_V
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_C | P_V


func _adc(cpu: Dictionary, value: int) -> void:
	var a := int(cpu["a"])
	var carry_in := 1 if (int(cpu["p"]) & P_C) != 0 else 0
	var total := a + (value & 0xFF) + carry_in
	var result := total & 0xFF
	var overflow := ((~(a ^ value) & (a ^ result)) & 0x80) != 0
	_set_c_with_v(cpu, total > 0xFF, overflow)
	_set_a(cpu, result)


func _read(address: int, value: int, kind: String) -> Dictionary:
	return {"address": address, "value": value & 0xFF, "kind": kind}


func _failure(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_execution_refused", "error": reason,
		"trace_state_used": false}
