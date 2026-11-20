extends RefCounted
class_name RomSlot09Ebd7RootZeroCounterExecutor
## Executes the live zero-$052E root-loop branch from $EBD7 to the next
## $CB0F scheduler-call entry. It does not execute the scheduler save handler.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/manifest.json"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/slot09_ebd7_root_checks/"
const ROUTE_MANIFEST := "res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json"
const ROOT_SPAN_FILE := "fixed_root_slot09_loop_EB86_EC07.bin"
const ROOT_SPAN_SHA256 := "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917"
const ROOT_SPAN_OFFSET := "0x03EB96"
const ROOT_SPAN_LENGTH := 130
const ROOT_SPAN_START := 0xEB86
const ROOT_RETURN_PC := 0xEBD7
const LIVE_BRANCH_ADDRESS := 0x052E
const CBF1_SOUND_QUEUE_EXECUTOR := preload("res://scripts/gameplay/rom_slot09_cbf1_sound_queue_executor.gd")
const D093_MANIFEST := "res://reference/rom_extract/gameplay/slot09_d093_sound_request/manifest.json"
const D093_ROOT := "res://reference/rom_extract/gameplay/slot09_d093_sound_request/"
const D093_CODE_FILE := "fixed_d093_sound_request_D093_D0AC.bin"
const D093_TABLE_FILE := "fixed_d093_sound_index_table_D0AC_D0D1.bin"
const D093_CODE_SHA256 := "f40f3cd4e1dd98e081463a5b9e9e3651e65533b495f2b437a9fee4e2cbf311d8"
const D093_TABLE_SHA256 := "191bf1e01cc7ffe6bad62ff05d6c756ada5ff5d5821a7b9c1581919029fb378e"
const D093_CODE_OFFSET := "0x03D0A3"
const D093_TABLE_OFFSET := "0x03D0BC"
const D093_CODE_LENGTH := 25
const D093_TABLE_LENGTH := 37
const P_N := 0x80
const P_Z := 0x02
const P_C := 0x01
const P_V := 0x40
const P_NZ_MASK := P_N | P_Z
const P_CNZV_MASK := P_C | P_N | P_Z | P_V

var error_message := ""
var _configured := false
var _root_bytes := PackedByteArray()
var _d093_code_bytes := PackedByteArray()
var _d093_table_bytes := PackedByteArray()
var _cbf1_sound_queue_executor: Variant = null


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_file := FileAccess.open(SOURCE_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("The `$EBD7` root-check source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("The `$EBD7` root-check source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var rom_variant: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-ebd7-root-checks-v1" \
			or not rom_variant is Dictionary \
			or String(rom_variant.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or not spans_variant is Array:
		return _fail("The `$EBD7` source package targets an unsupported ROM or schema.")
	var span: Dictionary = {}
	for candidate in spans_variant:
		if candidate is Dictionary and String(candidate.get("file", "")) == ROOT_SPAN_FILE:
			span = candidate
			break
	if span.is_empty() \
			or String(span.get("cpu_start", "")) != "0xEB86" \
			or String(span.get("cpu_end_exclusive", "")) != "0xEC08" \
			or String(span.get("bank", "")) != "0x1F" \
			or String(span.get("file_offset", "")) != ROOT_SPAN_OFFSET \
			or int(span.get("length", -1)) != ROOT_SPAN_LENGTH \
			or String(span.get("sha256", "")) != ROOT_SPAN_SHA256:
		return _fail("The `$EB86-$EC07` root-loop source metadata differs from the static audit.")
	_root_bytes = FileAccess.get_file_as_bytes(SOURCE_ROOT + ROOT_SPAN_FILE)
	if _root_bytes.size() != ROOT_SPAN_LENGTH \
			or _sha256(_root_bytes) != ROOT_SPAN_SHA256 \
			or String(span.get("bytes", "")).replace(" ", "").to_lower() != _root_bytes.hex_encode():
		return _fail("The `$EB86-$EC07` root-loop bytes failed size/hash/manifest validation.")
	if not _expect(0xEBD7, PackedByteArray([0xAD, 0x2E, 0x05, 0xF0, 0x29])) \
			or not _expect(0xEBDC, PackedByteArray([0xCE, 0x2E, 0x05, 0xD0, 0x24])) \
			or not _expect(0xEBE1, PackedByteArray([0xAD, 0x2F, 0x05, 0xC9, 0x7E, 0x90, 0x11])) \
			or not _expect(0xEBF9, PackedByteArray([0x2C, 0x3F, 0x06, 0x10, 0x04])) \
			or not _expect(0xEC02, PackedByteArray([0x20, 0xF1, 0xCB])) \
			or not _expect(0xEC05, PackedByteArray([0x4C, 0x86, 0xEB])) \
			or not _expect(0xEB86, PackedByteArray([0xA9, 0x01])) \
			or not _expect(0xEB88, PackedByteArray([0x20, 0x0F, 0xCB])):
		return _fail("The live `$EBD7` countdown, `$CBF1` caller, or `$CB0F` root-loop bytes changed.")
	var route_file := FileAccess.open(ROUTE_MANIFEST, FileAccess.READ)
	if route_file == null:
		return _fail("The preceding `$87E6` route source manifest is unavailable.")
	var route_manifest: Variant = JSON.parse_string(route_file.get_as_text())
	if not route_manifest is Dictionary \
			or String((route_manifest as Dictionary).get("rom", {}).get("sha256", "")) != ROM_SHA256:
		return _fail("The preceding `$87E6` source package targets a different ROM.")
	_cbf1_sound_queue_executor = CBF1_SOUND_QUEUE_EXECUTOR.new()
	if not _cbf1_sound_queue_executor.configure_from_project_sources():
		return _fail("The `$CBF1` sound queue helper source package failed: " + _cbf1_sound_queue_executor.error_message)
	if not _load_d093_sources():
		return false
	_configured = true
	return true


func _load_d093_sources() -> bool:
	var manifest_file := FileAccess.open(D093_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("The ROM-derived `$D093` helper manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The ROM-derived `$D093` helper manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom_info: Variant = manifest.get("rom", {})
	var spans_variant: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-d093-sound-request-v1" \
			or not rom_info is Dictionary \
			or String(rom_info.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("trace_state_included", true)) \
			or not spans_variant is Array:
		return _fail("The `$D093` source package targets the wrong ROM or schema.")
	var code_meta: Dictionary = {}
	var table_meta: Dictionary = {}
	for span_variant in spans_variant:
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("file", "")) == D093_CODE_FILE:
			code_meta = span
		elif String(span.get("file", "")) == D093_TABLE_FILE:
			table_meta = span
	if not _load_d093_span(code_meta, D093_CODE_FILE, "0xD093", "0xD0AC",
			D093_CODE_OFFSET, D093_CODE_LENGTH, D093_CODE_SHA256, true) \
			or not _load_d093_span(table_meta, D093_TABLE_FILE, "0xD0AC", "0xD0D1",
			D093_TABLE_OFFSET, D093_TABLE_LENGTH, D093_TABLE_SHA256, false):
		return false
	if _d093_code_bytes != PackedByteArray([
			0xA9, 0x32, 0x2C, 0x3E, 0x06, 0x30, 0x0E, 0xAE, 0xFB, 0x05,
			0xF0, 0x02, 0xA2, 0x01, 0xBD, 0x2A, 0x00, 0xAA, 0xBD, 0xAC,
			0xD0, 0x20, 0xF1, 0xCB, 0x60]):
		return _fail("The `$D093-$D0AB` instruction bytes differ from the checked ROM source.")
	return true


func _load_d093_span(meta: Dictionary, file_name: String, cpu_start: String,
		cpu_end: String, file_offset: String, length: int, expected_hash: String,
		is_code: bool) -> bool:
	if String(meta.get("cpu_start", "")) != cpu_start \
			or String(meta.get("cpu_end_exclusive", "")) != cpu_end \
			or String(meta.get("bank", "")) != "0x1E" \
			or String(meta.get("window", "")) != "fixed" \
			or String(meta.get("file_offset", "")) != file_offset \
			or int(meta.get("length", -1)) != length \
			or String(meta.get("sha256", "")) != expected_hash:
		return _fail("The `$D093` source metadata differs for %s." % file_name)
	var bytes := FileAccess.get_file_as_bytes(D093_ROOT + file_name)
	if bytes.size() != length or _sha256(bytes) != expected_hash \
			or String(meta.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
		return _fail("The extracted `$D093` bytes failed size/hash/manifest validation: %s." % file_name)
	if is_code:
		_d093_code_bytes = bytes
	else:
		_d093_table_bytes = bytes
	return true


## Consumes only the actual result returned by the live `$87E6` executor.
## Supports a zero counter or a nonzero countdown that remains nonzero after
## DEC, then stops at the `$CB0F` JSR target entry.
func execute_from_87e6_result(previous_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _rejected("Configure the hash-checked root-loop source package first.")
	var contract := _validate_previous_result(previous_result)
	if not bool(contract.get("ok", false)):
		return _rejected(String(contract.get("reason", "Invalid live `$87E6` result.")))
	var ram: PackedByteArray = previous_result["ram_image"].duplicate()
	var stack: PackedByteArray = previous_result["stack_page"].duplicate()
	var cpu: Dictionary = previous_result["registers"].duplicate(true)
	var mapper: Dictionary = previous_result["mapper"].duplicate(true)
	var entry_cpu: Dictionary = cpu.duplicate(true)
	var entry_ram_052e := int(ram[LIVE_BRANCH_ADDRESS])
	var instruction_pcs: Array[int] = []
	var stack_writes: Array[Dictionary] = []

	if not _expect(ROOT_RETURN_PC, PackedByteArray([0xAD, 0x2E, 0x05])):
		return _rejected("The root-loop `$EBD7` load differs from the checked ROM bytes.")
	instruction_pcs.append(ROOT_RETURN_PC)
	_set_a(cpu, entry_ram_052e)
	cpu["pc"] = 0xEBDA
	if not _expect(0xEBDA, PackedByteArray([0xF0, 0x29])):
		return _rejected("The root-loop `$EBDA` zero branch differs from the checked ROM bytes.")
	instruction_pcs.append(0xEBDA)
	if entry_ram_052e == 0:
		# BEQ $EC05 skips countdown and later root checks.
		cpu["pc"] = 0xEC05
	else:
		cpu["pc"] = 0xEBDC
		if not _expect(0xEBDC, PackedByteArray([0xCE, 0x2E, 0x05])):
			return _rejected("The root-loop `$EBDC DEC $052E` bytes differ from the checked ROM span.")
		instruction_pcs.append(0xEBDC)
		var decremented_counter := (entry_ram_052e - 1) & 0xFF
		ram[LIVE_BRANCH_ADDRESS] = decremented_counter
		_set_nz(cpu, decremented_counter)
		cpu["pc"] = 0xEBDF
		if not _expect(0xEBDF, PackedByteArray([0xD0, 0x24])):
			return _rejected("The root-loop `$EBDF BNE $EC05` bytes differ from the checked ROM span.")
		instruction_pcs.append(0xEBDF)
		if decremented_counter == 0:
			cpu["pc"] = 0xEBE1
			if entry_ram_052e == 0x01:
				if int(ram[0x052F]) == 0x7F:
					return _execute_counter_one_d093_path(previous_result, cpu,
						ram, stack, mapper, entry_cpu, instruction_pcs)
				return _execute_counter_one_sound_queue_path(previous_result,
					cpu, ram, stack, mapper, entry_cpu, instruction_pcs)
			return _unsupported_counter_branch(entry_ram_052e, decremented_counter,
					cpu, ram, stack, mapper, entry_cpu, instruction_pcs)
		cpu["pc"] = 0xEC05
	if not _expect(0xEC05, PackedByteArray([0x4C, 0x86, 0xEB])):
		return _rejected("The root loop does not reach the checked `$EC05 JMP $EB86`.")
	instruction_pcs.append(0xEC05)
	cpu["pc"] = 0xEB86
	if not _expect(0xEB86, PackedByteArray([0xA9, 0x01])):
		return _rejected("The next root-loop iteration no longer starts with `LDA #$01`.")
	instruction_pcs.append(0xEB86)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0xEB88
	if not _expect(0xEB88, PackedByteArray([0x20, 0x0F, 0xCB])):
		return _rejected("The next root-loop yield callsite differs from `JSR $CB0F`.")
	instruction_pcs.append(0xEB88)
	_push_jsr(cpu, stack, stack_writes, 0xEB88, 0xCB0F)
	return {
		"ok": true,
		"status": "reached_scheduler_yield_handler_entry",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"previous_result_manifest": String(previous_result.get("source_manifest", "")),
		"entry_pc": ROOT_RETURN_PC,
		"input_ram_052e": entry_ram_052e,
		"output_ram_052e": int(ram[LIVE_BRANCH_ADDRESS]),
		"entry_registers": entry_cpu,
		"exit_pc": int(cpu["pc"]),
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"stack_writes": stack_writes,
		"instruction_pcs": instruction_pcs,
		"source_yield_request": {
			"slot_base": 0x09,
			"callsite_pc": 0xEB88,
			"target_pc": 0xCB0F,
			"delay_in_a": 0x01,
			"pre_jsr_sp": int(entry_cpu["sp"]),
			"x": int(entry_cpu["x"]),
			"y": int(entry_cpu["y"]),
			"bank_low": int(mapper.get("bank_low", -1)),
			"bank_high": int(mapper.get("bank_high", -1)),
			"resume_pc": 0xEB8B,
		},
		"worker_return_pc": int(cpu["pc"]),
		"yield_handler_executed": false,
		"next_root_check_executed": false,
		"later_root_checks_executed": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


## Executes the source `$052E=$01` countdown exit through `$D093` when the
## live `$052F=$7F` selector is reached. The helper queues its ROM-selected
## request through `$CBF1`, then returns to the next root `$CB0F` yield.
func _execute_counter_one_d093_path(previous_result: Dictionary,
		cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		mapper: Dictionary, entry_cpu: Dictionary,
		instruction_pcs: Array[int]) -> Dictionary:
	if not _expect(0xEBE1, PackedByteArray([0xAD, 0x2F, 0x05, 0xC9, 0x7E, 0x90, 0x11])) \
			or not _expect(0xEBE8, PackedByteArray([0xC9, 0x7F, 0xF0, 0x07, 0xAD, 0x27, 0x00, 0xC9, 0x04, 0xF0, 0x12])) \
			or not _expect(0xEBF3, PackedByteArray([0x20, 0x93, 0xD0, 0x4C, 0x05, 0xEC])):
		return _rejected("The live `$052F=$7F` path into `$D093` differs from the verified root-loop bytes.")
	var d093_stack_writes: Array[Dictionary] = []
	instruction_pcs.append(0xEBE1)
	_set_a(cpu, int(ram[0x052F]))
	cpu["pc"] = 0xEBE4
	instruction_pcs.append(0xEBE4)
	_compare_a(cpu, 0x7E)
	cpu["pc"] = 0xEBE6
	instruction_pcs.append(0xEBE6)
	if int(cpu["a"]) < 0x7E:
		return _rejected("The live `$D093` branch no longer follows `$052F=$7F` through the equal-`$7F` test.")
	cpu["pc"] = 0xEBE8
	instruction_pcs.append(0xEBE8)
	_compare_a(cpu, 0x7F)
	cpu["pc"] = 0xEBEA
	instruction_pcs.append(0xEBEA)
	if int(cpu["a"]) != 0x7F:
		return _rejected("The `$EBEA` branch did not select `$D093` for the live `$052F` value.")
	cpu["pc"] = 0xEBF3
	instruction_pcs.append(0xEBF3)
	_push_jsr(cpu, stack, d093_stack_writes, 0xEBF3, 0xD093)

	var d093_reads: Array[Dictionary] = []
	if not _expect_d093(0xD093, PackedByteArray([0xA9, 0x32, 0x2C, 0x3E, 0x06, 0x30, 0x0E])):
		return _rejected("The `$D093` entry bytes differ from the extracted ROM span.")
	instruction_pcs.append(0xD093)
	_set_a(cpu, 0x32)
	cpu["pc"] = 0xD095
	var bit_value := int(ram[0x063E])
	d093_reads.append({"pc": 0xD095, "address": 0x063E, "value": bit_value, "kind": "BIT_zero_page"})
	instruction_pcs.append(0xD095)
	var p := int(cpu.get("p", 0)) & ~(P_N | P_Z | P_V)
	if (0x32 & bit_value) == 0:
		p |= P_Z
	if (bit_value & 0x80) != 0:
		p |= P_N
	if (bit_value & 0x40) != 0:
		p |= P_V
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | (P_N | P_Z | P_V)
	cpu["pc"] = 0xD098
	instruction_pcs.append(0xD098)
	var bit_bypass := (bit_value & 0x80) != 0
	if bit_bypass:
		cpu["pc"] = 0xD0A8
	else:
		if not _expect_d093(0xD09A, PackedByteArray([0xAE, 0xFB, 0x05, 0xF0, 0x02, 0xA2, 0x01,
				0xBD, 0x2A, 0x00, 0xAA, 0xBD, 0xAC, 0xD0])):
			return _rejected("The `$D093` selector and table lookup bytes differ from the extracted ROM span.")
		instruction_pcs.append(0xD09A)
		var selector := int(ram[0x05FB])
		d093_reads.append({"pc": 0xD09A, "address": 0x05FB, "value": selector, "kind": "selector_read"})
		cpu["x"] = selector
		_set_nz(cpu, selector)
		cpu["pc"] = 0xD09D
		instruction_pcs.append(0xD09D)
		# $D09D BEQ $D0A1 skips the following LDX #$01 when the selector is
		# zero. Only a nonzero selector executes that load and selects $002B.
		if selector != 0:
			cpu["pc"] = 0xD09F
			instruction_pcs.append(0xD09F)
			cpu["x"] = 0x01
			_set_nz(cpu, 0x01)
		cpu["pc"] = 0xD0A1
		instruction_pcs.append(0xD0A1)
		var indexed_address := 0x002A + int(cpu["x"])
		if indexed_address >= ram.size():
			return _rejected("The `$D093` selector indexes outside the source RAM image.")
		var table_index := int(ram[indexed_address])
		d093_reads.append({"pc": 0xD0A1, "address": indexed_address, "value": table_index, "kind": "sound_index_read"})
		cpu["a"] = table_index
		_set_nz(cpu, table_index)
		cpu["pc"] = 0xD0A4
		instruction_pcs.append(0xD0A4)
		cpu["x"] = table_index
		_set_nz(cpu, table_index)
		cpu["pc"] = 0xD0A5
		instruction_pcs.append(0xD0A5)
		if table_index >= _d093_table_bytes.size():
			return _unsupported_d093_table_index(selector, table_index, bit_value,
				cpu, ram, stack, mapper, entry_cpu, instruction_pcs)
		cpu["a"] = int(_d093_table_bytes[table_index])
		_set_nz(cpu, int(cpu["a"]))
		cpu["pc"] = 0xD0A8
	var sound_request := int(cpu["a"]) & 0xFF
	instruction_pcs.append(0xD0A8)
	var nested_stack_writes: Array[Dictionary] = d093_stack_writes.duplicate(true)
	_push_jsr(cpu, stack, nested_stack_writes, 0xD0A8, 0xCBF1)
	var source_cbf1_call := {
		"status": "source_cbf1_call_entry",
		"rom_sha256": ROM_SHA256,
		"source_manifest": D093_MANIFEST,
		"caller_pc": 0xD0A8,
		"caller_source_span_sha256": D093_CODE_SHA256,
		"d093_bit_bypass": bit_bypass,
		"target_pc": 0xCBF1,
		"entry_pc": 0xCBF1,
		"return_word": 0xD0AA,
		"return_pc": 0xD0AB,
		"registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": ram.duplicate(),
		"stack_page": stack.duplicate(),
		"stack_writes": nested_stack_writes,
		"trace_state_used": false,
	}
	var queue_result: Dictionary = _cbf1_sound_queue_executor.execute_from_d093_sound_request_call(source_cbf1_call)
	if not bool(queue_result.get("ok", false)) or int(queue_result.get("exit_pc", -1)) != 0xD0AB:
		return _rejected("The ROM-derived `$CBF1` consumer rejected the live `$D093` request: "
				+ String(queue_result.get("reason", _cbf1_sound_queue_executor.error_message)))
	cpu = queue_result["registers"].duplicate(true)
	ram = queue_result["ram_image"].duplicate()
	stack = queue_result["stack_page"].duplicate()
	if not _expect_d093(0xD0AB, PackedByteArray([0x60])):
		return _rejected("The `$D093` helper no longer ends with its checked RTS.")
	instruction_pcs.append(0xD0AB)
	var d093_rts_reads: Array[Dictionary] = []
	var return_sp := (int(cpu["sp"]) + 1) & 0xFF
	var return_low := int(stack[return_sp])
	d093_rts_reads.append({"pc": 0xD0AB, "address": 0x0100 | return_sp, "value": return_low, "kind": "RTS_low"})
	return_sp = (return_sp + 1) & 0xFF
	var return_high := int(stack[return_sp])
	d093_rts_reads.append({"pc": 0xD0AB, "address": 0x0100 | return_sp, "value": return_high, "kind": "RTS_high"})
	var return_word := (return_high << 8) | return_low
	cpu["sp"] = return_sp
	cpu["pc"] = (return_word + 1) & 0xFFFF
	if return_word != 0xEBF5 or int(cpu["pc"]) != 0xEBF6:
		return _rejected("The `$D093 RTS` did not resume the source `$EBF3` caller through its live stack word.")
	if not _expect(0xEBF6, PackedByteArray([0x4C, 0x05, 0xEC])) \
			or not _expect(0xEC05, PackedByteArray([0x4C, 0x86, 0xEB])) \
			or not _expect(0xEB86, PackedByteArray([0xA9, 0x01])) \
			or not _expect(0xEB88, PackedByteArray([0x20, 0x0F, 0xCB])):
		return _rejected("The `$D093` return does not reach the checked root-loop `$EB88->$CB0F` yield.")
	instruction_pcs.append_array([0xEBF6, 0xEC05, 0xEB86, 0xEB88])
	cpu["pc"] = 0xEB88
	_set_a(cpu, 0x01)
	var pre_jsr_sp := int(cpu["sp"])
	var root_stack_writes: Array[Dictionary] = []
	_push_jsr(cpu, stack, root_stack_writes, 0xEB88, 0xCB0F)
	return {
		"ok": true,
		"status": "reached_scheduler_yield_handler_entry",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"previous_result_manifest": String(previous_result.get("source_manifest", "")),
		"entry_pc": ROOT_RETURN_PC,
		"input_ram_052e": 0x01,
		"output_ram_052e": int(ram[LIVE_BRANCH_ADDRESS]),
		"entry_registers": entry_cpu,
		"exit_pc": int(cpu["pc"]),
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"stack_writes": root_stack_writes,
		"instruction_pcs": instruction_pcs,
		"source_d093_call": {"caller_pc": 0xEBF3, "target_pc": 0xD093,
			"return_word": 0xEBF5, "return_pc": 0xEBF6,
			"stack_writes": d093_stack_writes, "ram_reads": d093_reads,
			"rts_stack_reads": d093_rts_reads, "entry_pc": 0xD093,
			"exit_pc": 0xEBF6, "bit_bypass": bit_bypass,
			"sound_request": sound_request, "table_sha256": D093_TABLE_SHA256},
		"previous_source_result": previous_result.duplicate(true),
		"source_cbf1_call": source_cbf1_call,
		"cbf1_helper_result": queue_result,
		"source_yield_request": {"slot_base": 0x09, "callsite_pc": 0xEB88,
			"target_pc": 0xCB0F, "delay_in_a": 0x01,
			"pre_jsr_sp": pre_jsr_sp, "x": int(cpu["x"]), "y": int(cpu["y"]),
			"bank_low": int(mapper.get("bank_low", -1)),
			"bank_high": int(mapper.get("bank_high", -1)), "resume_pc": 0xEB8B},
		"worker_return_pc": int(cpu["pc"]), "yield_handler_executed": false,
		"next_root_check_executed": false, "later_root_checks_executed": false,
		"trace_state_used": false, "nmi_cadence_generated": false,
		"ppu_bus_events": [], "apu_register_writes": [],
	}


## Executes the source `$052E=$01` countdown exit only for the audited
## `$052F=$44/$063F=$00` caller state. The root caller runs `$EC02->$CBF1`,
## adopts that helper's ordered queue result, then takes `$EC05->$EB86` and
## returns at the next `$CB0F` call entry.
func _execute_counter_one_sound_queue_path(previous_result: Dictionary,
		cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		mapper: Dictionary, entry_cpu: Dictionary,
		instruction_pcs: Array[int]) -> Dictionary:
	if not _expect(0xEBE1, PackedByteArray([0xAD, 0x2F, 0x05])) \
			or not _expect(0xEBE4, PackedByteArray([0xC9, 0x7E, 0x90, 0x11])) \
			or not _expect(0xEBF9, PackedByteArray([0x2C, 0x3F, 0x06, 0x10, 0x04])) \
			or not _expect(0xEC02, PackedByteArray([0x20, 0xF1, 0xCB])):
		return _rejected("The `$052E=$01` helper caller bytes differ from the verified fixed-bank span.")
	var sound_request := int(ram[0x052F])
	var sound_flags := int(ram[0x063F])
	instruction_pcs.append(0xEBE1)
	_set_a(cpu, sound_request)
	cpu["pc"] = 0xEBE4
	instruction_pcs.append(0xEBE4)
	var compare_result := (int(cpu["a"]) - 0x7E) & 0xFF
	var p := int(cpu.get("p", 0)) & ~(P_C | P_NZ_MASK)
	if int(cpu["a"]) >= 0x7E:
		p |= P_C
	if compare_result == 0:
		p |= 0x02
	if (compare_result & 0x80) != 0:
		p |= P_N
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | (P_C | P_NZ_MASK)
	cpu["pc"] = 0xEBE6
	instruction_pcs.append(0xEBE6)
	if sound_request >= 0x7E:
		return _unsupported_counter_branch(0x01, 0,
				cpu, ram, stack, mapper, entry_cpu, instruction_pcs)
	# BCC `$EBF9`; the current bounded caller contract has a source `$44` request.
	cpu["pc"] = 0xEBF9
	instruction_pcs.append(0xEBF9)
	var bit_result := int(cpu["a"]) & sound_flags
	p = int(cpu.get("p", 0)) & ~(P_N | P_Z | P_V)
	if bit_result == 0:
		p |= P_Z
	if (sound_flags & 0x80) != 0:
		p |= P_N
	if (sound_flags & 0x40) != 0:
		p |= P_V
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | (P_N | P_Z | P_V)
	cpu["pc"] = 0xEBFC
	instruction_pcs.append(0xEBFC)
	# BPL reaches `$EC02` when `$063F.7` is clear. The helper's A value is the
	# caller's `$052F` sound request and may be zero (a source-valid no-op write).
	if sound_request >= 0x7E or (sound_flags & 0x80) != 0:
		return _unsupported_sound_helper_input(sound_request, sound_flags,
				cpu, ram, stack, mapper, entry_cpu, instruction_pcs)
	cpu["pc"] = 0xEC02
	instruction_pcs.append(0xEC02)
	var call_stack_writes: Array[Dictionary] = []
	_push_jsr(cpu, stack, call_stack_writes, 0xEC02, 0xCBF1)
	var source_call := {
		"status": "source_cbf1_call_entry",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"caller_pc": 0xEC02,
		"target_pc": 0xCBF1,
		"entry_pc": 0xCBF1,
		"return_word": 0xEC04,
		"return_pc": 0xEC05,
		"registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": ram.duplicate(),
		"stack_page": stack.duplicate(),
		"stack_writes": call_stack_writes.duplicate(true),
		"trace_state_used": false,
	}
	var helper: Dictionary = _cbf1_sound_queue_executor.execute_from_root_cbf1_call(source_call)
	if not bool(helper.get("ok", false)) or int(helper.get("exit_pc", -1)) != 0xEC05:
		return _rejected("The ROM-derived `$CBF1` consumer rejected the root's live call: "
				+ String(helper.get("reason", _cbf1_sound_queue_executor.error_message)))
	cpu = helper["registers"].duplicate(true)
	ram = helper["ram_image"].duplicate()
	stack = helper["stack_page"].duplicate()
	if not _expect(0xEC05, PackedByteArray([0x4C, 0x86, 0xEB])) \
			or not _expect(0xEB86, PackedByteArray([0xA9, 0x01])) \
			or not _expect(0xEB88, PackedByteArray([0x20, 0x0F, 0xCB])):
		return _rejected("The `$CBF1` return does not resume the checked `$EC05->$EB86->$CB0F` root path.")
	instruction_pcs.append(0xEC05)
	cpu["pc"] = 0xEB86
	instruction_pcs.append(0xEB86)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0xEB88
	instruction_pcs.append(0xEB88)
	var root_stack_writes: Array[Dictionary] = []
	var pre_jsr_sp := int(cpu["sp"])
	_push_jsr(cpu, stack, root_stack_writes, 0xEB88, 0xCB0F)
	return {
		"ok": true,
		"status": "reached_scheduler_yield_handler_entry",
		"rom_sha256": ROM_SHA256,
		"source_manifest": SOURCE_MANIFEST,
		"previous_result_manifest": String(previous_result.get("source_manifest", "")),
		"entry_pc": ROOT_RETURN_PC,
		"input_ram_052e": 0x01,
		"output_ram_052e": int(ram[LIVE_BRANCH_ADDRESS]),
		"entry_registers": entry_cpu,
		"exit_pc": int(cpu["pc"]),
		"registers": cpu,
		"mapper": mapper,
		"ram_image": ram,
		"stack_page": stack,
		"stack_writes": root_stack_writes,
		"instruction_pcs": instruction_pcs,
		"source_cbf1_call": source_call,
		"cbf1_helper_result": helper,
		"source_yield_request": {
			"slot_base": 0x09,
			"callsite_pc": 0xEB88,
			"target_pc": 0xCB0F,
			"delay_in_a": 0x01,
			"pre_jsr_sp": pre_jsr_sp,
			"x": int(cpu["x"]),
			"y": int(cpu["y"]),
			"bank_low": int(mapper.get("bank_low", -1)),
			"bank_high": int(mapper.get("bank_high", -1)),
			"resume_pc": 0xEB8B,
		},
		"worker_return_pc": int(cpu["pc"]),
		"yield_handler_executed": false,
		"next_root_check_executed": false,
		"later_root_checks_executed": false,
		"trace_state_used": false,
		"nmi_cadence_generated": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


func _unsupported_sound_helper_input(sound_request: int, sound_flags: int,
		cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		mapper: Dictionary, entry_cpu: Dictionary,
		instruction_pcs: Array[int]) -> Dictionary:
	var reason := "`$EBF9` reached an unsupported `$CBF1` input (request `$%02X`, flags `$%02X`); supported source path requires `$052F<$7E` and `$063F.7=0`." % [sound_request, sound_flags]
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"rom_sha256": ROM_SHA256, "source_manifest": SOURCE_MANIFEST,
		"entry_pc": ROOT_RETURN_PC, "input_ram_052e": 0x01,
		"output_ram_052e": int(ram[LIVE_BRANCH_ADDRESS]),
		"entry_registers": entry_cpu, "exit_pc": int(cpu.get("pc", -1)),
		"registers": cpu, "mapper": mapper, "ram_image": ram,
		"stack_page": stack, "instruction_pcs": instruction_pcs,
		"next_root_check_executed": false, "trace_state_used": false}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"rom_sha256": ROM_SHA256, "live_branch": "$052E == 0, countdown remains nonzero, or bounded counter-one `$CBF1` request path",
		"entry_pc": ROOT_RETURN_PC, "scheduler_boundary": "$CB0F"}


func _validate_previous_result(result: Dictionary) -> Dictionary:
	if String(result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(result.get("status", "")) != "returned_before_root_loop_check" \
			or String(result.get("source_manifest", "")) != "res://reference/rom_extract/gameplay/slot09_87e6_worker/manifest.json" \
			or int(result.get("entry_pc", -1)) != 0xEBC5 \
			or int(result.get("exit_pc", -1)) != ROOT_RETURN_PC \
			or int(result.get("worker_return_pc", -1)) != ROOT_RETURN_PC \
			or bool(result.get("next_root_check_executed", true)) \
			or bool(result.get("next_root_body_bytes_read", true)) \
			or bool(result.get("trace_state_used", true)):
		return {"ok": false, "reason": "Input is not the live `$87E6` return at `$EBD7`."}
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return {"ok": false, "reason": "The live result must carry CPU, mapper, RAM, and stack state."}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	if not bank_registers_variant is Dictionary:
		return {"ok": false, "reason": "The live result omits MMC3 bank-register state."}
	var bank_registers: Dictionary = bank_registers_variant
	# The bounded `$EBD7` root loop consumes A/Z and task/stack state. X/Y
	# are preserved from the scenario callback setup and are never read here.
	if ram.size() != 0x800 or stack.size() != 0x100 \
			or int(registers.get("pc", -1)) != ROOT_RETURN_PC \
			or int(registers.get("a", -1)) != 0 \
			or int(registers.get("sp", -1)) != 0x7A \
			or (int(registers.get("p", -1)) & P_Z) == 0 \
			or (int(registers.get("p", -1)) & P_N) != 0 \
			or (int(registers.get("p_known_mask", -1)) & P_NZ_MASK) != P_NZ_MASK \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(bank_registers.get(6, -1)) != 0x18 \
			or int(bank_registers.get(7, -1)) != 0x19 \
			or int(ram[0x0000]) != 0x09 \
			or stack.slice(0x78, 0x7B) != PackedByteArray([0xD2, 0xD6, 0xEB]):
		return {"ok": false, "reason": "The live `$EBD7` CPU, mapper, task slot, or return stack differs from the `$87E6` contract."}
	return {"ok": true}


func _unsupported_counter_branch(value: int, decremented_counter: int,
		cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, mapper: Dictionary, entry_cpu: Dictionary,
		instruction_pcs: Array[int]) -> Dictionary:
	var reason := "Live `$052E=$%02X` decrements to `$%02X` and reaches `$EBE1`; helper inputs are `$052F=$%02X`, `$0027=$%02X`, `$063F=$%02X`; the selected helper branch remains unresolved." % [
		value, decremented_counter, int(ram[0x052F]), int(ram[0x0027]), int(ram[0x063F])]
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"rom_sha256": ROM_SHA256, "source_manifest": SOURCE_MANIFEST,
		"entry_pc": ROOT_RETURN_PC, "input_ram_052e": value,
		"output_ram_052e": int(ram[LIVE_BRANCH_ADDRESS]),
		"entry_registers": entry_cpu, "exit_pc": int(cpu.get("pc", -1)),
		"registers": cpu, "mapper": mapper, "ram_image": ram,
		"stack_page": stack, "instruction_pcs": instruction_pcs,
		"next_root_check_executed": false, "trace_state_used": false}


func _unsupported_d093_table_index(selector: int, table_index: int, bit_value: int,
		cpu: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		mapper: Dictionary, entry_cpu: Dictionary,
		instruction_pcs: Array[int]) -> Dictionary:
	var index_value := -1
	if selector + 0x2A < ram.size():
		index_value = int(ram[0x2A + selector])
	var reason := "ROM `$D093` selected `$05FB=$%02X` then `$002A,X=$%02X`; index `$%02X` exceeds the checked `$D0AC-$D0D0` table (BIT `$063E=$%02X`)." % [
		selector, index_value, table_index, bit_value]
	error_message = reason
	return {"ok": false, "status": "unsupported_branch", "reason": reason,
		"rom_sha256": ROM_SHA256, "source_manifest": SOURCE_MANIFEST,
		"entry_pc": ROOT_RETURN_PC, "input_ram_052e": 0x01,
		"output_ram_052e": int(ram[LIVE_BRANCH_ADDRESS]),
		"entry_registers": entry_cpu, "exit_pc": int(cpu.get("pc", -1)),
		"registers": cpu, "mapper": mapper, "ram_image": ram,
		"stack_page": stack, "instruction_pcs": instruction_pcs,
		"next_root_check_executed": false, "trace_state_used": false}


func _expect(address: int, expected: PackedByteArray) -> bool:
	var offset := address - ROOT_SPAN_START
	if offset < 0 or offset + expected.size() > _root_bytes.size():
		return false
	for index in range(expected.size()):
		if int(_root_bytes[offset + index]) != expected[index]:
			return false
	return true


func _expect_d093(address: int, expected: PackedByteArray) -> bool:
	var offset := address - 0xD093
	if offset < 0 or offset + expected.size() > _d093_code_bytes.size():
		return false
	for index in range(expected.size()):
		if int(_d093_code_bytes[offset + index]) != expected[index]:
			return false
	return true


func _set_a(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	cpu["a"] = value
	_set_nz(cpu, value)


func _compare_a(cpu: Dictionary, value: int) -> void:
	var a := int(cpu.get("a", 0)) & 0xFF
	value &= 0xFF
	var result := (a - value) & 0xFF
	var p := int(cpu.get("p", 0)) & ~(P_C | P_NZ_MASK)
	if a >= value:
		p |= P_C
	if result == 0:
		p |= P_Z
	if (result & 0x80) != 0:
		p |= P_N
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | (P_C | P_NZ_MASK)


func _set_nz(cpu: Dictionary, value: int) -> void:
	value &= 0xFF
	var p := int(cpu.get("p", 0)) & ~P_NZ_MASK
	if (value & 0x80) != 0:
		p |= P_N
	if value == 0:
		p |= P_Z
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu.get("p_known_mask", 0)) | P_NZ_MASK


func _push_jsr(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], source_pc: int, target_pc: int) -> void:
	var return_word := (source_pc + 2) & 0xFFFF
	_push(cpu, stack, stack_writes, (return_word >> 8) & 0xFF, source_pc, "JSR_high")
	_push(cpu, stack, stack_writes, return_word & 0xFF, source_pc, "JSR_low")
	cpu["pc"] = target_pc


func _push(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], value: int, source_pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = value & 0xFF
	stack_writes.append({"pc": source_pc, "address": 0x0100 | sp,
		"value": value & 0xFF, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _rejected(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_input", "reason": reason,
		"trace_state_used": false}


func _fail(reason: String) -> bool:
	error_message = reason
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
