extends SceneTree
## Focused source-byte contract for the PASS no-candidates caller continuation.
## This isolated ROM-derived fixture is not a production route/FCEUX RAM seed.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_pass_no_candidates_continuation_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	if not executor.configure_from_project_sources():
		_fail("ROM span setup failed: " + String(executor.error_message))
		return
	var source_state := _source_fixture()
	var entry: Dictionary = source_state["entry"]
	var returned: Dictionary = source_state["returned"]
	var receipt: Dictionary = source_state["receipt"]
	var invalid_receipt := receipt.duplicate(true)
	invalid_receipt["return_pc"] = 0xD6BE
	var refused: Dictionary = executor.execute_from_live_e945_renderer_return(entry, invalid_receipt)
	if bool(refused.get("ok", true)) or bool(refused.get("d6c7_reached", true)):
		_fail("The executor accepted a renderer receipt that did not return to D68A.")
		return
	var result: Dictionary = executor.execute_from_live_e945_renderer_return(entry, receipt)
	if not bool(result.get("ok", false)):
		_fail("Source-byte PASS continuation did not complete: " + String(result.get("error", "unknown")))
		return
	var regs: Dictionary = result.get("registers", {})
	var output: Dictionary = result.get("d6c7_boundary", {})
	var output_ram: PackedByteArray = output.get("ram_image", PackedByteArray())
	var mapper: Dictionary = result.get("mapper", {})
	if String(result.get("status", "")) != "pass_no_candidates_reached_live_d6c7" \
			or int(result.get("source_boundary_pc", -1)) != 0xD68A \
			or int(result.get("source_exit_pc", -1)) != 0xD6C7 \
			or int(output.get("pc", -1)) != 0xD6C7 \
			or int(regs.get("a", -1)) != 0x01 \
			or int(regs.get("x", -1)) != 0x04 \
			or int(regs.get("y", -1)) != 0x02 \
			or int(regs.get("p", -1)) != 0x31 \
			or int(regs.get("sp", -1)) != 0x4A \
			or int(result.get("final_sp", -1)) != 0x4A \
			or output_ram.size() != 0x800 \
			or int(output_ram[0x0430]) != 0 \
			or int(output_ram[0x043B]) != 1 \
			or int(output_ram[0x043C]) != 0 \
			or int(output_ram[0x0024]) != 0x1C or int(output_ram[0x0025]) != 0x1D \
			or int(mapper.get("bank_registers_at_d6c7", {}).get(6, -1)) != 0x1C \
			or int(mapper.get("bank_registers_at_d6c7", {}).get(7, -1)) != 0x1D \
			or mapper.get("saved_task_bank_pair", []) != [0x1A, 0x1B] \
			or not result.get("ppu_events", []).is_empty() \
			or not result.get("apu_events", []).is_empty() \
			or bool(result.get("ppu_apu_effects_applied", true)) \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)) \
			or bool(result.get("source_cycle_timing_modeled", true)) \
			or bool(result.get("instruction_level_parity_claimed", true)):
		_fail("The source-derived D6C7 output/register/mapper contract differs from the observed no-candidates boundary: " + str(result))
		return
	if not result.get("source_instruction_pcs", []).has(0x8C26) \
			or not result.get("source_instruction_pcs", []).has(0x819D) \
			or not result.get("source_instruction_pcs", []).has(0xD76B) \
			or not result.get("source_instruction_pcs", []).has(0xD6C4) \
			or result.get("mapper", {}).get("mapper_events", []).size() != 8:
		_fail("The PASS continuation omitted a required source branch or mapper receipt.")
		return
	var unsupported_action := returned.duplicate(true)
	var unsupported_ram: PackedByteArray = unsupported_action["ram_image"]
	unsupported_ram[0x043B] = 2
	unsupported_action["ram_image"] = unsupported_ram
	var unsupported_entry := entry.duplicate(true)
	var entry_ram: PackedByteArray = unsupported_entry["ram_image"]
	entry_ram[0x043B] = 2
	unsupported_entry["ram_image"] = entry_ram
	var unsupported_return := receipt.duplicate(true)
	unsupported_return["entry_boundary"] = unsupported_entry
	unsupported_return["returned_boundary"] = unsupported_action
	var unsupported: Dictionary = executor.execute_from_live_e945_renderer_return(
		unsupported_entry, unsupported_return)
	if bool(unsupported.get("ok", true)) \
			or String(unsupported.get("status", "")) != "unsupported_route_variant" \
			or bool(unsupported.get("d6c7_reached", true)):
		_fail("A non-PASS action variant was not rejected explicitly.")
		return
	var candidate_entry := entry.duplicate(true)
	var candidate_ram: PackedByteArray = candidate_entry["ram_image"].duplicate()
	candidate_ram[0x0348] = 1 # ROM slot-6 record changed only to exercise a nonempty ROM table.
	candidate_entry["ram_image"] = candidate_ram.duplicate()
	var candidate_return := returned.duplicate(true)
	candidate_return["ram_image"] = candidate_ram.duplicate()
	var candidate_receipt := receipt.duplicate(true)
	candidate_receipt["entry_boundary"] = candidate_entry.duplicate(true)
	candidate_receipt["returned_boundary"] = candidate_return.duplicate(true)
	var candidate_result: Dictionary = executor.execute_from_live_e945_renderer_return(
		candidate_entry, candidate_receipt)
	if bool(candidate_result.get("ok", true)) \
			or String(candidate_result.get("status", "")) != "unsupported_candidate_branch" \
			or bool(candidate_result.get("d6c7_reached", true)):
		_fail("A ROM candidate-found branch was not stopped explicitly: " + str(candidate_result))
		return
	print("PASS: extracted ROM bytes execute `$D68A->$8009->$8C06` through the `$0430==0` branch, then `$D717->$8012->$819D->$D76B->$D6C7`.")
	print("PASS: final CPU registers match the observed D6C7 hook `$A/$X/$Y/$P/$SP=$01/$04/$02/$31/$4A`; task banks and mapped banks are reported separately.")
	print("PASS: bad renderer receipts, non-PASS actions, and the ROM candidate-found branch stop before D6C7; no FCEUX state, PPU/APU output, or cycle-accuracy claim is used.")
	print("LIMIT: this source fixture verifies the bounded executor only; production E945/NMI route adoption and whole-route output remain parent integration work.")
	quit(0)


func _source_fixture() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	ram[0x0348] = 8 # ROM match-00 home-roster slot 6 maps to player ID 8.
	ram[0x0349] = 90 # Isolated fixture value; production input is the scheduler's live RAM.
	ram[0x034A] = 0
	ram[0x043B] = 1
	ram[0x0441] = 6
	ram[0x044E] = 0
	ram[0x061E] = 0x81
	ram[0x0022] = 0
	ram[0x0024] = 0x1A
	ram[0x0025] = 0x1B
	var entry := _boundary(0xE945, ram, stack)
	var returned := _boundary(0xD68A, ram, stack)
	var receipt := {
		"ok": true,
		"status": "pass_action_menu_renderer_returned",
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"entry_pc": 0xE945,
		"callsite_pc": 0xD687,
		"return_pc": 0xD68A,
		"returned_via_rts": true,
		"source_instruction_pcs": [0xE945, 0xE948, 0xE94B],
		"entry_boundary": entry.duplicate(true),
		"returned_boundary": returned.duplicate(true),
		"receipt_id": "rom-byte-e945-return-fixture",
	}
	return {"entry": entry, "returned": returned, "receipt": receipt}


func _boundary(pc: int, ram: PackedByteArray, stack: PackedByteArray) -> Dictionary:
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": pc,
		"sp": 0x4A,
		"a": 0,
		"x": 0,
		"y": 0,
		"p": 0x30,
		"p_known_mask": 0xFF,
		"bank_low": 0x1A,
		"bank_high": 0x1B,
		"ram_image": ram.duplicate(),
		"stack_page": stack.duplicate(),
		"mapper": {"bank_low": 0x1A, "bank_high": 0x1B,
			"bank_registers": {6: 0x1A, 7: 0x1B}, "select": 0},
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
