extends RefCounted
class_name RomFreshKickoffPostwaitCaller
## Source-executes the fresh-match caller from its genuine `$8117` return
## through the bank-$01 `$A006->$A4EB` transfer. It deliberately stops before
## the unresolved `$A4EB` body can return to `$811F`.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CALLER_SOURCE_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/bank00_title_to_first_match_setup_80DF_815C.bin"
const CALLER_SOURCE_SHA256 := "a4b5afda1800eb4b500c95748497e22cb6467d90d1e99c56d4578b98db996a7b"
const CALLER_SOURCE_START_PC := 0x80DF
const POSTWAIT_PC := 0x8117
const CALLER_OFFSET := POSTWAIT_PC - CALLER_SOURCE_START_PC
const POSTWAIT_BYTES := [
	0xA2, 0x01, # $8117 LDX #$01
	0x20, 0xB9, 0xC4, # $8119 JSR $C4B9
	0x20, 0x06, 0xA0, # $811C JSR $A006
	0x20, 0x72, 0xC5, # $811F JSR $C572 (not reached by this bounded executor)
]
const A006_SCRIPT := preload("res://scripts/gameplay/rom_fresh_prematch_a006_entry.gd")
const MAPPER_SCRIPT := preload("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd")

var error_message := ""
var _configured := false
var _caller_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var a006_source: Variant = A006_SCRIPT.new()
	if not a006_source.configure_from_project_sources():
		return _fail("Could not configure the hash-checked `$A006` entry: " + a006_source.error_message)
	var mapper_source: Variant = MAPPER_SCRIPT.new()
	if not mapper_source.configure_from_project_sources():
		return _fail("Could not configure the hash-checked `$C4B9` helper: " + mapper_source.error_message)
	_caller_source = FileAccess.get_file_as_bytes(CALLER_SOURCE_PATH)
	if _caller_source.size() != 126 or _sha256(_caller_source) != CALLER_SOURCE_SHA256:
		return _fail("The `$80DF-$815C` caller span failed its source size/hash check.")
	if CALLER_OFFSET + POSTWAIT_BYTES.size() > _caller_source.size() \
			or _caller_source.slice(CALLER_OFFSET, CALLER_OFFSET + POSTWAIT_BYTES.size()) != PackedByteArray(POSTWAIT_BYTES):
		return _fail("The `$8117-$8121` source bytes differ from the reviewed LDX/JSR sequence.")
	_configured = true
	return true


## Consumes only a successful result from execute_after_wait_release(). The
## release receipt must already be represented in that result; this executor
## never manufactures a wait value, IRQ receipt, or candidate route state.
func execute_from_preset_tail_result(tail_result: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(tail_result.get("ok", false)) \
			or String(tail_result.get("status", "")) != "returned_to_fresh_match_caller" \
			or String(tail_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(tail_result.get("final_source_pc", -1)) != POSTWAIT_PC:
		return _refused("A successful source-tail result returning to `$8117` is required.")
	if bool(tail_result.get("trace_state_used", true)) \
			or bool(tail_result.get("emulator_data_used", true)) \
			or bool(tail_result.get("candidate_state_used", false)) \
			or bool(tail_result.get("live_mapper_updated", true)):
		return _refused("Trace, emulator, and candidate state cannot supply caller inputs.")
	if String(tail_result.get("stack_model", "")) != "logical_source_jsr_frames":
		return _refused("The prefix must return its checked logical-source stack model.")
	var stack_after: Variant = tail_result.get("stack_after")
	if not stack_after is Array or not stack_after.is_empty():
		return _refused("The `$8114->$8920->$8117` source returns must leave no pending frame.")
	var source_id := String(tail_result.get("source_event_id", "")).strip_edges()
	var wait_release_id := String(tail_result.get("wait_release_event_id", "")).strip_edges()
	if source_id.is_empty() or wait_release_id.is_empty() \
			or not wait_release_id.begins_with(source_id + ":893B"):
		return _refused("The real source event and wait-release event identities must be preserved.")
	var receipt_variant: Variant = tail_result.get("source_return_receipt", {})
	if not receipt_variant is Dictionary:
		return _refused("The prefix `$8117` source-return receipt is missing.")
	var receipt: Dictionary = receipt_variant
	if int(receipt.get("caller_pc", -1)) != 0x8114 \
			or int(receipt.get("target_pc", -1)) != 0x8920 \
			or int(receipt.get("return_pc", -1)) != POSTWAIT_PC \
			or String(receipt.get("status", "")) != "returned" \
			or String(receipt.get("source_event_id", "")) != source_id:
		return _refused("The `$8114->$8920->$8117` return receipt does not match this tail result.")

	var registers_variant: Variant = tail_result.get("boundary_registers", {})
	var ram_variant: Variant = tail_result.get("caller_ram_after", {})
	if not registers_variant is Dictionary or not ram_variant is Dictionary:
		return _refused("Source-derived return registers and RAM are required.")
	var registers: Dictionary = registers_variant.duplicate(true)
	var ram: Dictionary = ram_variant.duplicate(true)
	if int(registers.get("pc", -1)) != POSTWAIT_PC:
		return _refused("The `$8117` return register contract has the wrong PC.")
	for register_name: String in ["a", "x", "y"]:
		var value := int(registers.get(register_name, -1))
		if value < 0 or value > 0xFF:
			return _refused("Source-derived `%s` must be an explicit byte." % register_name)
	var p_mask := int(registers.get("p_known_mask", -1))
	var p_value := int(registers.get("p_known_value", -1))
	if p_mask < 0 or p_mask > 0xFF or p_value < 0 or p_value > 0xFF:
		return _refused("The `$8117` return requires a partial P known-mask/value contract.")
	if not ram.has(0x0022):
		return _refused("MMC3 select shadow `$0022` must come from the source-tail RAM.")

	# ROM `$8117: A2 01` is LDX #$01; it changes only N/Z among the tracked flags.
	registers["x"] = 1
	registers["p_known_mask"] = p_mask | 0x82
	registers["p_known_value"] = p_value & (p_mask | 0x82) & 0x7D
	registers["pc"] = 0x8119
	var cycles := 2
	var source_path: Array[int] = [0x8117]
	var source_event_ids: Array[String] = [source_id, wait_release_id]
	var mapper: Variant = MAPPER_SCRIPT.new()
	var mapper_call_id := wait_release_id + ":8119-C4B9"
	var mapper_call := _logical_call(0x8119, 0xC4B9, 0x811C, mapper_call_id)
	registers["pc"] = 0xC4B9
	var mapper_result: Dictionary = mapper.execute_logical_source_call(mapper_call, registers, ram)
	if not bool(mapper_result.get("ok", false)):
		return _refused("The `$8119->$C4B9->$811C` source call failed: " + String(mapper_result.get("error", "unknown error")))
	cycles += 6 + int(mapper_result.get("cpu_cycles", -1))
	source_path.append_array(mapper_result.get("executed_instruction_pcs", []))
	source_path.append(0x811C)
	source_event_ids.append(mapper_call_id)
	registers = mapper_result.get("return_registers", {}).duplicate(true)
	ram = mapper_result.get("ram_after", {}).duplicate(true)
	if int(registers.get("pc", -1)) != 0x811C:
		return _refused("The hash-checked `$C4B9 RTS` did not return to `$811C`.")
	var mapper_bus_writes: Array = mapper_result.get("mapper_bus_writes", [])
	var select_value := int(mapper_bus_writes[0].get("value", -1)) if not mapper_bus_writes.is_empty() else -1
	if mapper_bus_writes.size() != 2 \
			or int(mapper_bus_writes[0].get("address", -1)) != 0x8000 \
			or (select_value & 0x07) != 0x07 \
			or (select_value & 0x40) != 0 \
			or int(mapper_bus_writes[1].get("address", -1)) != 0x8001 \
			or int(mapper_bus_writes[1].get("value", -1)) != 1:
		return _refused("The source helper did not select MMC3 register 7 with bank `$01`.")
	var mapper_state := {
		"a000_prg_bank": 1,
		"selected_register": 7,
		"register7_prg_bank": 1,
		"prg_mode": (select_value >> 6) & 1,
		"source_event_id": mapper_call_id,
		"source_mapper_bus_writes": mapper_bus_writes.duplicate(true),
		"live_mapper_updated": false,
	}
	registers["pc"] = 0x811C
	var a006_call_id := wait_release_id + ":811C-A006"
	var a006_call := _logical_call(0x811C, 0xA006, 0x811F, a006_call_id)
	cycles += 6
	registers["pc"] = 0xA006
	var a006: Variant = A006_SCRIPT.new()
	var a006_result: Dictionary = a006.execute_logical_source_call(
		a006_call, registers, ram, mapper_state)
	if not bool(a006_result.get("ok", false)):
		return _refused("The `$811C->$A006` vector transfer failed: " + String(a006_result.get("error", "unknown error")))
	var a006_path: Array = a006_result.get("source_path", [])
	if a006_path.size() != 3 or int(a006_path[0]) != 0x811C \
			or int(a006_path[1]) != 0xA006 or int(a006_path[2]) != 0xA4EB:
		return _refused("The hash-checked `$A006` vector transfer path is malformed.")
	cycles += int(a006_result.get("cpu_cycles", -1))
	source_path.append_array([0xA006, 0xA4EB])
	source_event_ids.append(a006_call_id)
	var next_cpu: Dictionary = a006_result.get("next_cpu_state", {}).duplicate(true)
	var pending_frames: Array = a006_result.get("logical_stack_frames", []).duplicate(true)
	if int(next_cpu.get("pc", -1)) != 0xA4EB \
			or pending_frames.size() != 1 \
			or int(pending_frames[0].get("return_pc", -1)) != 0x811F:
		return _refused("The `$A006` transfer did not preserve its caller frame at `$A4EB`.")

	return {
		"ok": true,
		"status": "stopped_at_unexecuted_a006_body",
		"completed": false,
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": source_id,
		"wait_release_event_id": wait_release_id,
		"source_event_ids": source_event_ids,
		"source_path": source_path,
		"executed_caller_source_pcs": [0x8117, 0x8119, 0x811C],
		"next_source_call": {
			"caller_pc": 0x811F, "target_pc": 0xC572, "return_pc": 0x8122,
			"caller_bytes": [0x20, 0x72, 0xC5],
			"status": "verified_in_rom_but_not_reached",
			"reason": "The `$A4EB` target body is not executed and has not returned to `$811F`.",
		},
		"entry_registers": registers,
		"next_cpu_state": next_cpu,
		"ram_after": ram,
		"mapper_state_after": mapper_state,
		"mapper_bus_writes": mapper_bus_writes,
		"logical_stack_frames": pending_frames,
		"stack_model": "logical_source_jsr_frames",
		"cpu_cycles_through_a006_jmp": cycles,
		"source_receipts": [mapper_result["source_return_receipt"], a006_result["source_transfer_receipt"]],
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
	}


func _logical_call(caller_pc: int, target_pc: int, return_pc: int,
		event_id: String) -> Dictionary:
	return {
		"caller_pc": caller_pc,
		"target_pc": target_pc,
		"return_pc": return_pc,
		"source_event_id": event_id,
		"logical_stack_frame": {
			"kind": "rom_jsr",
			"caller_pc": caller_pc,
			"target_pc": target_pc,
			"return_pc": return_pc,
			"return_word": caller_pc + 2,
			"source_event_id": event_id,
		},
	}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	error_message = message
	return {
		"ok": false,
		"status": "source_state_required_or_mismatch",
		"error": message,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
	}
