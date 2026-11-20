extends SceneTree

const WORKER_PREFIX := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var checkpoint_path := OS.get_environment("CT2_SCENARIO18_CHECKPOINT").strip_edges()
	if checkpoint_path.is_empty():
		_fail("Set CT2_SCENARIO18_CHECKPOINT to a Godot ordinary-input route checkpoint.")
		return
	var checkpoint_file := FileAccess.open(checkpoint_path, FileAccess.READ)
	if checkpoint_file == null:
		_fail("Could not read Godot route checkpoint: " + checkpoint_path)
		return
	var parsed: Variant = JSON.parse_string(checkpoint_file.get_as_text())
	if not parsed is Dictionary:
		_fail("Godot route checkpoint is malformed JSON.")
		return
	var checkpoint: Dictionary = parsed
	var registers: Dictionary = checkpoint.get("registers", {})
	var mapper: Dictionary = checkpoint.get("mapper", {})
	var ram := String(checkpoint.get("ram_hex", "")).hex_decode()
	var stack_page := String(checkpoint.get("stack_page_hex", "")).hex_decode()
	if String(checkpoint.get("origin", "")) != "ordinary_input_godot_source_route_boundary" \
			or String(checkpoint.get("rom_sha256", "")) != ROM_SHA256 \
			or int(checkpoint.get("active_task_slot", -1)) != 0x05 \
			or int(checkpoint.get("pc", -1)) != 0x8112 \
			or int(registers.get("pc", -1)) != 0x8112 \
			or int(checkpoint.get("bank_low", -1)) != 0x1A \
			or int(checkpoint.get("bank_high", -1)) != 0x1B \
			or ram.size() != 0x800 or stack_page.size() != 0x100 \
			or ram.slice(0x0100, 0x0200) != stack_page \
			or _sha256(ram) != String(checkpoint.get("ram_sha256", "")) \
			or _sha256(stack_page) != String(checkpoint.get("stack_page_sha256", "")):
		_fail("Checkpoint is not the hash-verified live slot-$05 `$8112` state from this ROM/input route.")
		return
	var boundary := registers.duplicate(true)
	boundary.merge({"rom_sha256": ROM_SHA256, "active_task_slot": 0x05,
		"slot_base": 0x05, "pc": 0x8112, "bank_low": 0x1A, "bank_high": 0x1B,
		"mapper": mapper, "ram_image": ram, "stack_page": stack_page,
		"trace_state_used": false, "test_fixture": false}, true)
	var worker = WORKER_PREFIX.new()
	if not worker.configure_from_project_sources():
		_fail("Worker source configuration failed: " + worker.error_message)
		return
	var result: Dictionary = worker.execute_scenario18_pass_result_from_live_boundary(boundary)
	if not bool(result.get("ok", false)):
		_fail("ROM source execution stopped at `$%04X`: %s" % [
			int(result.get("exit_pc", -1)), String(result.get("error", worker.error_message))])
		return
	print("SOURCE_BOUNDARY: ", JSON.stringify({
		"status": result.get("status", ""),
		"pc": result.get("exit_pc", -1),
		"registers": result.get("registers", {}),
		"scenario_id_before_queue": result.get("scenario_id_before_queue", -1),
		"scenario_id_after_queue": result.get("scenario_id_after_queue", -1),
		"scenario_id_at_boundary": result.get("scenario_id_at_boundary", -1),
		"holder_id": result.get("holder_id", -1),
		"field_action_result": result.get("field_action_result", -1),
		"calls_to_cb0f": result.get("calls_to_cb0f", []),
		"recent_instruction_pcs": result.get("recent_instruction_pcs", []),
		"executed_source_spans": result.get("executed_source_spans", [])
	}))
	quit(0)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
