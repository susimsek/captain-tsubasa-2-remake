extends SceneTree
## Verifies the bounded ROM-byte `$D96F` RTS bridge from a synthetic worker
## source-read boundary. The fixture is not emulator state or route evidence.

const WORKER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_MANIFEST := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var worker = WORKER_SCRIPT.new()
	if not worker.configure_from_project_sources():
		_fail("Worker sources including the pass receiver scan span did not validate: " + worker.error_message)
		return
	var initial := _make_partial_worker_result(worker.source_manifest_sha256())
	var original_ram: PackedByteArray = initial["ram_image"].duplicate()
	var original_stack: PackedByteArray = initial["stack_page"].duplicate()
	var result: Dictionary = worker.execute_pass_receiver_scan_return_bridge(initial)
	if not bool(result.get("ok", false)) \
			or String(result.get("status", "")) != "pass_receiver_scan_returned_to_d837" \
			or String(result.get("exit_kind", "")) != "source_return_boundary" \
			or int(result.get("entry_pc", -1)) != 0xD96F \
			or int(result.get("exit_pc", -1)) != 0xD837:
		_fail("The bridge did not execute the checked `$D96F` RTS to `$D837`: " + str(result))
		return
	var receipt: Dictionary = result.get("return_receipt", {})
	var registers: Dictionary = result.get("registers", {})
	var output_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var output_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var spans: Array = result.get("executed_source_spans", [])
	var has_scan_source := false
	for span_variant: Variant in spans:
		if span_variant is Dictionary \
				and String(span_variant.get("file", "")) == "receiver_candidate_scan" \
				and String(span_variant.get("sha256", "")) \
				== "516f3edfaef0868e42229d5f75c609596a21991962647d720037cd041c2d079a" \
				and Array(span_variant.get("executed_cpu_addresses", [])) == [0xD96F]:
			has_scan_source = true
	if int(receipt.get("opcode", -1)) != 0x60 \
			or int(receipt.get("target_pc", -1)) != 0xD837 \
			or int(receipt.get("sp_before", -1)) != 0x3E \
			or int(receipt.get("sp_after", -1)) != 0x40 \
			or receipt.get("consumed_return_word", PackedByteArray()) != PackedByteArray([0x36, 0xD8]) \
			or receipt.get("stale_renderer_return_word", PackedByteArray()) != PackedByteArray([0x6E, 0xD9]) \
			or not bool(receipt.get("ram_unchanged", false)) \
			or not bool(receipt.get("registers_a_x_y_unchanged", false)) \
			or not bool(receipt.get("flags_unchanged", false)) \
			or int(registers.get("sp", -1)) != 0x40 \
			or int(registers.get("pc", -1)) != 0xD837 \
			or int(registers.get("p", -1)) != int(initial["registers"]["p"]) \
			or int(registers.get("p_known_mask", -1)) != int(initial["registers"]["p_known_mask"]) \
			or output_ram != original_ram or output_stack != original_stack \
			or not result.get("writes", []).is_empty() \
			or not result.get("mapper_writes", []).is_empty() \
			or not has_scan_source \
			or bool(result.get("trace_state_used", true)) \
			or not bool(result.get("input_boundary_fixture", false)):
		_fail("The bounded RTS result changed RAM/flags, consumed the wrong frame, or omitted its checked source receipt: " + str(result))
		return
	if original_ram != initial["ram_image"] or original_stack != initial["stack_page"]:
		_fail("The bridge mutated its input worker result.")
		return

	var wrong_return := _make_partial_worker_result(worker.source_manifest_sha256())
	var wrong_stack: PackedByteArray = wrong_return["stack_page"].duplicate()
	wrong_stack[0x3F] = 0x37
	wrong_return["stack_page"] = wrong_stack
	var wrong_ram: PackedByteArray = wrong_return["ram_image"].duplicate()
	for index in range(0x100):
		wrong_ram[0x0100 + index] = wrong_stack[index]
	wrong_return["ram_image"] = wrong_ram
	if bool(worker.execute_pass_receiver_scan_return_bridge(wrong_return).get("ok", true)):
		_fail("The bridge accepted an unrelated outer return word instead of `$D836`.")
		return

	var wrong_pc := _make_partial_worker_result(worker.source_manifest_sha256())
	wrong_pc["exit_pc"] = 0xD970
	wrong_pc["registers"]["pc"] = 0xD970
	if bool(worker.execute_pass_receiver_scan_return_bridge(wrong_pc).get("ok", true)):
		_fail("The bridge accepted a worker boundary other than `$D96F`.")
		return

	print("PASS: hash-checked pass_receiver_input manifest maps bank-$1E `$D96F` to ROM `$60`; one source RTS consumes `$D836` and returns at `$D837`.")
	print("PASS: live-like stack frame is checked; RAM, A/X/Y, P, mapper, and all memory bytes remain unchanged, with SP increasing by exactly two.")
	print("LIMIT: the input is a synthetic worker boundary; this does not prove live route integration or renderer/NMI/PPU parity.")
	quit(0)


func _make_partial_worker_result(worker_manifest_sha256: String) -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	ram[0x0000] = 0x05
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack.fill(0)
	# The stale `$D96C->$EF7F` JSR frame remains below SP after the renderer RTS.
	stack[0x3D] = 0x6E
	stack[0x3E] = 0xD9
	# The live outer `$D834->$D8F7` frame is consumed by the `$D96F` RTS.
	stack[0x3F] = 0x36
	stack[0x40] = 0xD8
	for index in range(0x100):
		ram[0x0100 + index] = stack[index]
	return {
		"ok": false,
		"test_fixture": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": WORKER_MANIFEST,
		"source_manifest_sha256": worker_manifest_sha256,
		"exit_kind": "unresolved_source_span",
		"exit_pc": 0xD96F,
		"exit_bank": 0x1E,
		"blocked_read": {"instruction_pc": 0xD96F, "requested_address": 0xD96F, "bank": 0x1E},
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": 0x05,
			"resume_path": "yielded_rts", "pc": 0x8889, "bank": 0x18,
			"source_dispatch_observed": true},
		"registers": {"a": 0x1D, "x": 0x00, "y": 0x67, "p": 0xE5,
			"p_known_mask": 0xFF, "sp": 0x3E, "pc": 0xD96F},
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": ram,
		"stack_page": stack,
	}


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
