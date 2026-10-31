extends RefCounted
class_name RomSlot15CallbackEntryExecutor
## Executes the ROM-sourced initial slot-$15 RTS target and its three-byte
## bank-$0B JMP, then stops at callback dispatcher `$814C`.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_PATH := "res://reference/rom_extract/gameplay/task_context/bank0b_callback_entry_8009.bin"
const SOURCE_SHA256 := "5813c87d4f453cff4b6738bc2af1b54149488222527a69155072092c9f971fdb"
const ENTRY_PC := 0x8009
const DISPATCHER_PC := 0x814C

var error_message := ""


func execute_from_initial_slot15_dispatch(dispatch: Dictionary,
		boundary: Dictionary, dispatch_boundary: Dictionary = {}) -> Dictionary:
	error_message = ""
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var scenario_id := int(ram_variant[0x0518]) if ram_variant is PackedByteArray \
			and ram_variant.size() == 0x800 else -1
	var expected_bank_high := 0x0C
	var expected_boundary_bank_high := 0x12 if scenario_id == 0x36 else -1
	var expected_task_high := 0x12 if scenario_id == 0x36 else 0x00
	if not bool(dispatch.get("ok", false)) or int(dispatch.get("slot_base", -1)) != 0x15 \
			or String(dispatch.get("resume_path", "")) != "initial_rts" \
			or int(dispatch.get("pc", -1)) != ENTRY_PC \
			or int(dispatch.get("sp", -1)) != 0xF2 \
			or int(dispatch.get("a", -1)) != 0xF0 \
			or int(dispatch.get("x", -1)) != 0xF0 \
			or int(dispatch.get("bank_low", -1)) != 0x0B \
			or scenario_id not in [0x35, 0x36] \
			or int(dispatch.get("bank_high", -1)) != expected_bank_high \
			or int(boundary.get("slot_base", -1)) != 0x15 \
			or int(boundary.get("phase", -1)) != 1 \
			or int(boundary.get("pending_resume", -1)) != 1 \
			or (scenario_id == 0x36 and int(boundary.get("bank_high", -1)) != expected_boundary_bank_high) \
			or boundary.get("record", PackedByteArray()) != PackedByteArray([0xFF, 0xF0, 0x0B, expected_task_high]):
		return _failure("Unsupported initial slot-$15 boundary: scenario=$%02X dispatch=$%04X/$%02X/$%02X record=%s boundary phase/delay/resume=$%d/$%02X/$%d banks=$%02X/$%02X record=%s." % [
			scenario_id, int(dispatch.get("pc", -1)), int(dispatch.get("bank_low", -1)),
			int(dispatch.get("bank_high", -1)),
			(dispatch.get("task_record", PackedByteArray()) as PackedByteArray).hex_encode(),
			int(boundary.get("phase", -1)), int(boundary.get("ready_delay", -1)),
			int(boundary.get("pending_resume", -1)), int(boundary.get("bank_low", -1)),
			int(boundary.get("bank_high", -1)),
			(boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode()])
	var bytes := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if bytes != PackedByteArray([0x4C, 0x4C, 0x81]) \
			or FileAccess.get_sha256(SOURCE_PATH) != SOURCE_SHA256:
		return _failure("The packaged ROM-source `$8009` JMP failed its size/byte/hash check.")
	var source_boundary := dispatch_boundary if not dispatch_boundary.is_empty() else boundary
	if int(source_boundary.get("active_task_slot", -1)) != 0x15 \
			or int(source_boundary.get("phase", -1)) != 2 \
			or int(source_boundary.get("pc", -1)) != ENTRY_PC \
			or int(source_boundary.get("ram_image", PackedByteArray())[0x0000]) != 0x15:
		return _failure("Post-dispatch slot-$15 state is not active at `$8009`.")
	var output_dispatch := dispatch.duplicate(true)
	var entry_dispatch := dispatch.duplicate(true)
	entry_dispatch["p"] = int(source_boundary.get("p", 0))
	entry_dispatch["p_known_mask"] = int(source_boundary.get("p_known_mask", 0))
	output_dispatch["pc"] = DISPATCHER_PC
	output_dispatch["p"] = int(source_boundary.get("p", 0))
	output_dispatch["p_known_mask"] = int(source_boundary.get("p_known_mask", 0))
	return {
		"ok": true,
		"status": "reached_callback_dispatcher_entry",
		"rom_sha256": ROM_SHA256,
		"source_file": SOURCE_PATH,
		"source_sha256": SOURCE_SHA256,
		"entry_pc": ENTRY_PC,
		"exit_pc": DISPATCHER_PC,
		"source_bytes_executed": bytes.duplicate(),
		"instruction_pcs": [ENTRY_PC],
		"entry_dispatch": entry_dispatch,
		"dispatcher_dispatch": output_dispatch,
		"scenario_id": scenario_id,
		"ram_image": source_boundary.get("ram_image", PackedByteArray()).duplicate(),
		"stack_page": source_boundary.get("stack_page", PackedByteArray()).duplicate(),
		"callback_dispatcher_body_executed": false,
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
	}


func _failure(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "source_execution_refused", "error": reason,
		"trace_state_used": false}
