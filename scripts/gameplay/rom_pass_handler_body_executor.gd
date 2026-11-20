extends RefCounted
class_name RomPassHandlerBodyExecutor
## Executes the PASS handler's verified synchronous prefix from a live slot-$05
## `$D7E8` boundary through the `$CBBE->$CB0F` scheduler-yield call entry.
## It deliberately stops before `$CB0F` runs or any queued work is dispatched.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const HANDLER_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_action_menu_input/manifest.json"
const HANDLER_MANIFEST_SHA256 := "5e3a87d63733ecedb4fdbab7265ecca0d3d6ce3a4ae60ac016df1c80ed5b59f8"
const HANDLER_PATH := "res://reference/rom_extract/gameplay/first_action_menu_input/pass_receiver_handler_D7E8_D8F6.bin"
const HANDLER_SHA256 := "9ccc071c8af66e997b4fe1fe3613af4e764d756c35c6c96118ceba7faf034032"
const SCENARIO_RUNTIME_MANIFEST_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json"
const SCENARIO_RUNTIME_MANIFEST_SHA256 := "5628913db6f1579f2155b127fe59b755924951039fcd21b241eaec732b01bee6"
const QUEUE_HELPER_PATH := "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin"
const QUEUE_HELPER_SHA256 := "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32"
const SCENARIO_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json"
const SCENARIO_MANIFEST_SHA256 := "8787974cbd268a91e36c5cc82783a348edf6132f21c2109a709d8b13a43a1162"
const SCENARIO_STREAM_PATH := "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin"
const SCENARIO_STREAM_SHA256 := "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76"

const INPUT_PC := 0xD7E8
const OUTER_RETURN_PC := 0xD634
const SCENARIO_ID := 0x38
const YIELD_CALL_PC := 0xCBBE
const YIELD_TARGET_PC := 0xCB0F
const RAM_SIZE := 0x0800
const STACK_PAGE_SIZE := 0x0100
const STACK_PAGE_BASE := 0x0100
const FLAG_NZ_MASK := 0x82

const HANDLER_PREFIX: Array[int] = [0xA9, 0x38, 0x20, 0xB0, 0xCB]
const QUEUE_HELPER_BYTES: Array[int] = [
	0x8D, 0x18, 0x05, 0xA9, 0x80, 0x8D, 0x16, 0x05, 0xA9,
	0x00, 0x85, 0x05, 0xA9, 0x00, 0x20, 0x0F, 0xCB, 0x60,
]
const SCENARIO38_BYTES: Array[int] = [0xF7, 0x17, 0x01, 0x34, 0x00, 0xF0, 0xFB]

var error_message := ""
var _configured := false
var _handler_bytes := PackedByteArray()
var _queue_helper_bytes := PackedByteArray()
var _scenario38_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var handler_manifest_bytes := _read_checked_file(HANDLER_MANIFEST_PATH, HANDLER_MANIFEST_SHA256)
	var scenario_runtime_manifest_bytes := _read_checked_file(
		SCENARIO_RUNTIME_MANIFEST_PATH, SCENARIO_RUNTIME_MANIFEST_SHA256)
	var scenario_manifest_bytes := _read_checked_file(SCENARIO_MANIFEST_PATH, SCENARIO_MANIFEST_SHA256)
	if handler_manifest_bytes.is_empty() or scenario_runtime_manifest_bytes.is_empty() \
			or scenario_manifest_bytes.is_empty():
		return false
	_handler_bytes = _read_checked_file(HANDLER_PATH, HANDLER_SHA256)
	_queue_helper_bytes = _read_checked_file(QUEUE_HELPER_PATH, QUEUE_HELPER_SHA256)
	_scenario38_bytes = _read_checked_file(SCENARIO_STREAM_PATH, SCENARIO_STREAM_SHA256)
	if _handler_bytes.size() != 271 \
			or _queue_helper_bytes != PackedByteArray(QUEUE_HELPER_BYTES) \
			or _scenario38_bytes != PackedByteArray(SCENARIO38_BYTES):
		return _fail("A preserved PASS handler, CBB0 queue helper, or scenario-$38 span differs from the pinned ROM bytes.")
	if _handler_bytes.slice(0, HANDLER_PREFIX.size()) != PackedByteArray(HANDLER_PREFIX):
		return _fail("The PASS handler no longer requests scenario-$38 before the CBB0 queue call.")
	if not _manifest_has_handler_span(handler_manifest_bytes) \
			or not _manifest_has_queue_helper(scenario_runtime_manifest_bytes) \
			or not _manifest_has_scenario38(scenario_manifest_bytes):
		return _fail("A source manifest no longer maps the expected ROM bank/address/bytes to the packaged spans.")
	_configured = true
	return true


## Requires the ordinary-input scheduler snapshot after the ROM CB99 dispatcher
## has actually reached `$D7E8`. No emulator capture or arbitrary endpoint image
## can be used as a substitute for that live boundary.
func execute_from_live_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var validation := _validate_live_boundary(boundary)
	if not bool(validation.get("ok", false)):
		return _failure("source_state_required", String(validation.get("error", "Invalid live PASS boundary.")))
	var entry_ram: PackedByteArray = boundary["ram_image"]
	var entry_stack: PackedByteArray = boundary["stack_page"]
	var ram := entry_ram.duplicate()
	var stack := entry_stack.duplicate()
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var entry_sp := int(boundary["sp"])
	var sp := entry_sp
	var x := int(boundary["x"])
	var y := int(boundary["y"])
	var p := int(boundary["p"])
	var p_known_mask := int(boundary["p_known_mask"])

	# `$D7E8 LDA #$38; $D7EA JSR $CBB0`.
	var a := SCENARIO_ID
	p = _update_nz(p, a)
	p_known_mask |= FLAG_NZ_MASK
	sp = _push_jsr(stack, stack_writes, 0xD7EA, 0xD7EC, sp)

	# `$CBB0` stores the requested scenario and enables the scenario queue.
	_write_ram(ram, writes, 0xCBB0, 0x0518, a)
	a = 0x80
	p = _update_nz(p, a)
	p_known_mask |= FLAG_NZ_MASK
	_write_ram(ram, writes, 0xCBB5, 0x0516, a)
	a = 0
	p = _update_nz(p, a)
	p_known_mask |= FLAG_NZ_MASK
	_write_ram(ram, writes, 0xCBBA, 0x0005, a)
	# `$CBBC LDA #$00; $CBBE JSR $CB0F`; stop at callee entry before it runs.
	sp = _push_jsr(stack, stack_writes, YIELD_CALL_PC, 0xCBC0, sp)
	var output_ram := ram.duplicate()
	for index in STACK_PAGE_SIZE:
		output_ram[STACK_PAGE_BASE + index] = stack[index]
	var output_registers := {
		"a": a, "x": x, "y": y, "p": p, "p_known_mask": p_known_mask,
		"sp": sp, "pc": YIELD_TARGET_PC,
	}
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = YIELD_TARGET_PC
	next_boundary["sp"] = sp
	next_boundary["a"] = a
	next_boundary["x"] = x
	next_boundary["y"] = y
	next_boundary["p"] = p
	next_boundary["p_known_mask"] = p_known_mask
	next_boundary["ram_image"] = output_ram.duplicate()
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS handler `$D7E8->$CBB0->$CBBE->$CB0F` call entry"
	return {
		"ok": true,
		"status": "pass_scenario38_queue_at_cb0f_call_entry",
		"rom_sha256": ROM_SHA256,
		"handler_manifest_sha256": HANDLER_MANIFEST_SHA256,
		"handler_span_sha256": HANDLER_SHA256,
		"scenario_runtime_manifest_sha256": SCENARIO_RUNTIME_MANIFEST_SHA256,
		"scenario_queue_helper_sha256": QUEUE_HELPER_SHA256,
		"scenario38_manifest_sha256": SCENARIO_MANIFEST_SHA256,
		"scenario38_stream_sha256": SCENARIO_STREAM_SHA256,
		"entry_pc": INPUT_PC,
		"entry_sp": entry_sp,
		"final_sp": sp,
		"resume_pc": YIELD_TARGET_PC,
		"executed_source_pcs": [0xD7E8, 0xD7EA, 0xCBB0, 0xCBB3, 0xCBB5,
			0xCBB8, 0xCBBA, 0xCBBC, YIELD_CALL_PC],
		"source_writes": writes,
		"source_stack_writes": stack_writes,
		"registers": output_registers,
		"next_boundary_snapshot": next_boundary,
		"executing_cpu_bank": 0x1E,
		"mapper_proof": boundary["mapper_proof"].duplicate(true),
		"scenario_id_queued": SCENARIO_ID,
		"stop_reason": "`$CBBE` has called `$CB0F`; the CB0F scheduler save and later resume are not executed here.",
		"scenario38_stream_validated_but_not_advanced": true,
		"descriptor_0f_executed": false,
		"holder_copy_executed": false,
		"cursor_input_read": false,
		"input_wait_reached": false,
		"scheduler_yield_executed": false,
		"scheduler_resume_or_elapsed_wait_fabricated": false,
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
	}


func get_source_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"handler_manifest_sha256": HANDLER_MANIFEST_SHA256,
		"handler_span_sha256": _sha256(_handler_bytes) if not _handler_bytes.is_empty() else "",
		"scenario_runtime_manifest_sha256": SCENARIO_RUNTIME_MANIFEST_SHA256,
		"queue_helper_sha256": _sha256(_queue_helper_bytes) if not _queue_helper_bytes.is_empty() else "",
		"scenario38_manifest_sha256": SCENARIO_MANIFEST_SHA256,
		"scenario38_sha256": _sha256(_scenario38_bytes) if not _scenario38_bytes.is_empty() else "",
		"stop_boundary_pc": YIELD_TARGET_PC,
		"stop_boundary_is_call_entry": true,
	}


func _validate_live_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "emulator_snapshot", "trace_ram_image"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "error": "Emulator trace/snapshot inputs are not valid runtime boundary state."}
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper_proof", {})
	if not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_PAGE_SIZE \
			or not mapper_variant is Dictionary:
		return {"ok": false, "error": "A full scheduler-owned RAM/stack mirror and explicit mapper proof are required."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var bank_window: Variant = mapper.get("banks_at_fixed_dispatch", [])
	var sp := int(boundary.get("sp", -1))
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != INPUT_PC \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(boundary.get("executing_cpu_bank", -1)) != 0x1E \
			or bank_window != [0x1C, 0x1D] \
			or int(mapper.get("fixed_bank", -1)) != 0x1E \
			or sp < 0 or sp > 0xFF \
			or int(boundary.get("a", -1)) != 0xE8 \
			or int(boundary.get("y", -1)) != 0x04 \
			or int(boundary.get("x", -1)) < 0 or int(boundary.get("x", -1)) > 0xFF \
			or not _flags_match(boundary) \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x043B]) != 1 or int(ram[0x061E]) != 0x81 \
			or int(ram[0x0621]) != 0 \
			or int(ram[0x0036]) != 0xE8 or int(ram[0x0037]) != 0xD7:
		return {"ok": false, "error": "Boundary is not the source-owned slot-$05 `$D7E8` PASS dispatch state."}
	var outer_return_low := int(stack[(sp + 1) & 0xFF])
	var outer_return_high := int(stack[(sp + 2) & 0xFF])
	if outer_return_low != (OUTER_RETURN_PC & 0xFF) \
			or outer_return_high != ((OUTER_RETURN_PC >> 8) & 0xFF):
		return {"ok": false, "error": "The live stack does not retain the `$D634` caller frame from the PASS handler dispatch."}
	if bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "error": "Trace-derived state cannot seed the ROM handler runtime."}
	return {"ok": true}


func _manifest_has_handler_span(bytes: PackedByteArray) -> bool:
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return false
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-first-action-menu-input-rom-data-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		return false
	var spans: Variant = manifest.get("source_spans", [])
	if not spans is Array:
		return false
	for span_variant in spans:
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("name", "")) == "pass_receiver_handler":
			return String(span.get("cpu_start", "")) == "0xD7E8" \
					and String(span.get("cpu_end_exclusive", "")) == "0xD8F7" \
					and String(span.get("prg_bank", "")) == "0x1E" \
					and String(span.get("file_offset", "")) == "0x03D7F8" \
					and String(span.get("sha256", "")) == HANDLER_SHA256
	return false


func _manifest_has_queue_helper(bytes: PackedByteArray) -> bool:
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return false
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "bank10-scenario-task-runtime-sources-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)):
		return false
	var entries: Variant = manifest.get("entries", [])
	if not entries is Array:
		return false
	for entry_variant in entries:
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("path", "")) == QUEUE_HELPER_PATH.trim_prefix("res://"):
			return String(entry.get("cpu_address", "")) == "$CBB0" \
					and String(entry.get("file_offset", "")) == "0x03CBC0" \
					and int(entry.get("length_bytes", -1)) == QUEUE_HELPER_BYTES.size() \
					and String(entry.get("sha256", "")) == QUEUE_HELPER_SHA256
	return false


func _manifest_has_scenario38(bytes: PackedByteArray) -> bool:
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return false
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)):
		return false
	var streams: Variant = manifest.get("scenario_streams", [])
	if not streams is Array:
		return false
	for stream_variant in streams:
		if not stream_variant is Dictionary:
			continue
		var stream: Dictionary = stream_variant
		if String(stream.get("scenario_id", "")) == "$38":
			return String(stream.get("path", "")) == SCENARIO_STREAM_PATH.trim_prefix("res://") \
					and String(stream.get("start_cpu_address", "")) == "0xB7C6" \
					and String(stream.get("file_offset", "")) == "0x0237D6" \
					and int(stream.get("length_bytes", -1)) == SCENARIO38_BYTES.size() \
					and String(stream.get("sha256", "")) == SCENARIO_STREAM_SHA256 \
					and String(stream.get("bytes_hex", "")).replace(" ", "").to_lower() \
						== PackedByteArray(SCENARIO38_BYTES).hex_encode()
	return false


func _push_jsr(stack: PackedByteArray, events: Array[Dictionary], source_pc: int,
		return_word: int, sp: int) -> int:
	var return_address := return_word & 0xFFFF
	var high_address := STACK_PAGE_BASE + sp
	stack[sp] = (return_address >> 8) & 0xFF
	events.append({"source_pc": source_pc, "address": high_address,
		"value": (return_address >> 8) & 0xFF, "operation": "jsr_push_high"})
	sp = (sp - 1) & 0xFF
	var low_address := STACK_PAGE_BASE + sp
	stack[sp] = return_address & 0xFF
	events.append({"source_pc": source_pc, "address": low_address,
		"value": return_address & 0xFF, "operation": "jsr_push_low"})
	return (sp - 1) & 0xFF


func _write_ram(ram: PackedByteArray, events: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	ram[address] = value & 0xFF
	events.append({"source_pc": source_pc, "address": address, "value": value & 0xFF})


func _update_nz(status: int, value: int) -> int:
	var updated := status & ~(0x80 | 0x02)
	if (value & 0x80) != 0:
		updated |= 0x80
	if (value & 0xFF) == 0:
		updated |= 0x02
	return updated & 0xFF


func _flags_match(boundary: Dictionary) -> bool:
	var status := int(boundary.get("p", -1))
	var known := int(boundary.get("p_known_mask", -1))
	return status >= 0 and status <= 0xFF and known >= 0 and known <= 0xFF \
			and (known & 0x83) == 0x83 and (status & 0x83) == 0x80


func _read_checked_file(path: String, expected_sha256: String) -> PackedByteArray:
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != expected_sha256:
		_fail("Source file is missing or failed its SHA-256 check: " + path)
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK \
			or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message, "trace_state_used": false}
