extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const PERIOD_TASK := preload("res://scripts/gameplay/rom_fresh_period_task.gd")
const CONTINUATION := preload("res://scripts/gameplay/rom_fresh_daaa_continuation.gd")
const WORKER_PREFIX := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")

var _checks := 0


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: ROM-byte slot-$05 worker resume validates caller state and follows the nonzero-$0515 re-yield branch.")
	print("PASS: zero-$0515 execution source-runs the `$EF` callback, text conversion, `$FC` return, and shared menu-worker path through its `$8886->$C515` yield call.")
	quit(0)


func _verify() -> bool:
	var worker = WORKER_PREFIX.new()
	if not worker.configure_from_project_sources():
		return _fail("Worker source setup failed: " + worker.error_message)
	var source_c515 := _build_source_c515_state()
	if source_c515.is_empty():
		return false
	var resume := _resume_state(source_c515)
	if not _check_invalid_inputs(worker, resume):
		return false
	if not _check_nonzero_reyield(worker, resume):
		return false
	if not _check_zero_proceed(worker, resume):
		return false
	print("PASS: %d focused worker-resume checks." % _checks)
	return true


func _build_source_c515_state() -> Dictionary:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		_fail("Fresh route context source setup failed: " + builder.error_message)
		return {}
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		_fail("Could not derive source-owned kickoff context: " + builder.error_message)
		return {}
	var period = PERIOD_TASK.new()
	if not period.configure_from_project_sources():
		_fail("Fresh-period source setup failed: " + period.error_message)
		return {}
	var period_result: Dictionary = period.execute_fresh_match_zero(context.to_period_task_inputs())
	if not bool(period_result.get("ok", false)):
		_fail("Fresh-period source execution failed: " + period.error_message)
		return {}
	var continuation = CONTINUATION.new()
	if not continuation.configure_from_project_sources():
		_fail("Fresh continuation source setup failed: " + continuation.error_message)
		return {}
	var worker_entry: Dictionary = continuation.execute_synchronous_prefix(period_result)
	if not bool(worker_entry.get("ok", false)):
		_fail("Could not derive ROM-source worker entry: " + continuation.error_message)
		return {}
	var worker_prefix = WORKER_PREFIX.new()
	if not worker_prefix.configure_from_project_sources():
		_fail("Bank-$18 worker source setup failed: " + worker_prefix.error_message)
		return {}
	var result: Dictionary = worker_prefix.execute_to_yield_trampoline(worker_entry)
	if not bool(result.get("ok", false)) or int(result.get("exit_pc", -1)) != 0xC515:
		_fail("ROM-byte worker prefix did not reach $C515: " + worker_prefix.error_message)
		return {}
	return result


func _resume_state(source_c515: Dictionary) -> Dictionary:
	var registers: Dictionary = (source_c515["registers"] as Dictionary).duplicate(true)
	registers["pc"] = 0x8889
	registers["sp"] = 0x4A
	registers.erase("p") # the scheduler does not preserve P; the worker path does not consume it before setting N/Z
	var mapper: Dictionary = (source_c515["mapper"] as Dictionary).duplicate(true)
	var ram: PackedByteArray = (source_c515["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (source_c515["stack_page"] as PackedByteArray).duplicate()
	var dispatch := {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"slot_base": 0x05,
		"resume_path": "yielded_rts",
		"pc": 0x8889,
		"bank": 0x18,
		"source_dispatch_observed": true,
	}
	return {"source_dispatch": dispatch, "registers": registers, "mapper": mapper,
		"ram_image": ram, "stack_page": stack}


func _check_invalid_inputs(worker, resume: Dictionary) -> bool:
	var invalid_proof := resume.duplicate(true)
	(invalid_proof["source_dispatch"] as Dictionary)["slot_base"] = 0x06
	var rejected: Dictionary = worker.resume_dispatched_slot05_worker(invalid_proof)
	if not rejected.is_empty() or worker.error_message.find("slot-$05 yielded_rts") < 0:
		return _fail("Resume accepted a mismatched source-dispatch proof.")
	_checks += 1

	var invalid_ram := resume.duplicate(true)
	invalid_ram["ram_image"] = PackedByteArray()
	rejected = worker.resume_dispatched_slot05_worker(invalid_ram)
	if not rejected.is_empty() or worker.error_message.find("2 KiB RAM") < 0:
		return _fail("Resume accepted an incomplete RAM image.")
	_checks += 1

	var invalid_stack := resume.duplicate(true)
	var stack: PackedByteArray = invalid_stack["stack_page"]
	stack[0x40] ^= 0xFF
	invalid_stack["stack_page"] = stack
	rejected = worker.resume_dispatched_slot05_worker(invalid_stack)
	if not rejected.is_empty() or worker.error_message.find("does not match") < 0:
		return _fail("Resume accepted a stack page that differs from its RAM image.")
	_checks += 1
	return true


func _check_nonzero_reyield(worker, source_resume: Dictionary) -> bool:
	var resume := source_resume.duplicate(true)
	var ram: PackedByteArray = resume["ram_image"]
	ram[0x0515] = 0x01
	resume["ram_image"] = ram
	var result: Dictionary = worker.resume_dispatched_slot05_worker(resume)
	if not bool(result.get("ok", false)):
		return _fail("Nonzero-$0515 source re-yield failed: " + worker.error_message)
	if String(result.get("exit_kind", "")) != "yield_at_c515" \
			or int(result.get("exit_pc", -1)) != 0xC515 \
			or int((result.get("registers", {}) as Dictionary).get("sp", -1)) != 0x48:
		return _fail("Nonzero-$0515 did not source-execute the $8884/$8886 re-yield path.")
	var instruction_pcs: Array[int] = []
	for instruction: Dictionary in result.get("instructions", []):
		instruction_pcs.append(int(instruction.get("pc", -1)))
	if instruction_pcs != [0x8889, 0x888C, 0x8884, 0x8886]:
		return _fail("Nonzero-$0515 executed an unexpected instruction path: %s." % str(instruction_pcs))
	var registers: Dictionary = result.get("registers", {})
	if int(registers.get("p_known_mask", 0)) != 0xA2:
		return _fail("Omitted incoming P did not expose the N/Z/U status validity mask.")
	var stack_page: PackedByteArray = result.get("stack_page", PackedByteArray())
	if stack_page.size() != 0x100 or int(stack_page[0x49]) != 0x88 or int(stack_page[0x4A]) != 0x88:
		return _fail("The source $8886 JSR did not produce the verified return-minus-one bytes on the caller stack.")
	_checks += 1
	return true


func _check_zero_proceed(worker, source_resume: Dictionary) -> bool:
	var resume := source_resume.duplicate(true)
	var ram: PackedByteArray = resume["ram_image"]
	ram[0x0515] = 0
	resume["ram_image"] = ram
	var result: Dictionary = worker.resume_dispatched_slot05_worker(resume)
	if not bool(result.get("ok", false)) or String(result.get("exit_kind", "")) != "yield_at_c515" \
			or int(result.get("exit_pc", -1)) != 0xC515:
		return _fail("Zero-$0515 did not complete the source-supported callback path through `$C515`: " + worker.error_message)
	var ram_out: PackedByteArray = result.get("ram_image", PackedByteArray())
	var expected_first_two_packets := PackedByteArray([
		0x07, 0x21, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x07, 0x41, 0x22, 0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D,
	])
	if ram_out.size() != 0x800 or int(ram_out[0x0515]) != 0x80 \
			or int(ram_out[0x05C5]) != 0x02 or int(ram_out[0x05C6]) != 0x00 \
			or ram_out.slice(0x04A5, 0x04A5 + expected_first_two_packets.size()) != expected_first_two_packets:
		return _fail("Source route did not emit the verified first two window packets into `$04A5` and raise `$0515=$80`.")
	var result_regs: Dictionary = result.get("registers", {})
	var result_stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var saved_sp := int(result_regs.get("sp", -1))
	if saved_sp != 0x48 or result_stack.size() != 0x100 \
			or int(result_stack[(saved_sp + 1) & 0xFF]) != 0x88 \
			or int(result_stack[(saved_sp + 2) & 0xFF]) != 0x88:
		return _fail("The resumed worker did not preserve the real `$8886->$C515` return word on its task stack.")
	var spans: Array = result.get("executed_source_spans", [])
	if not _contains_span(spans, "bank18_worker_resume_8889_89D7.bin") \
			or not _contains_span(spans, "bank19_match_descriptor_B453_B464.bin") \
			or not _contains_span(spans, "bank19_resumed_worker_text_lead_BBDC_BBDE.bin") \
			or not _contains_span(spans, "fixed_dispatch_C509_C50C.bin") \
			or not _contains_span(spans, "fixed_text_token_converter_CBC2_CBF1.bin") \
			or not _contains_span(spans, "bank18_special_handler_8B48_8B77.bin") \
			or not _contains_span(spans, "bank18_window_3x3_tile_ids_8D9E_8DA7.bin"):
		return _fail("Zero-$0515 path is missing executed-source provenance for its worker, text stream, or `$EF` callback chain.")
	if String(result.get("source_manifest_sha256", "")).length() != 64:
		return _fail("Worker resume result omitted the source manifest digest.")
	if (result.get("writes", []) as Array).is_empty():
		return _fail("Zero-$0515 partial result omitted its source-derived RAM write history.")
	var saw_reservation := false
	for write_variant in result.get("writes", []):
		if write_variant is Dictionary and int(write_variant.get("address", -1)) == 0x0515 \
				and int(write_variant.get("value", -1)) == 0x01 \
				and int(write_variant.get("pc", -1)) == 0x8890:
			saw_reservation = true
	if not saw_reservation:
		return _fail("Zero-$0515 path did not record the source store that reserves the queue flag.")
	_checks += 1
	return true


func _contains_span(spans: Array, file_name: String) -> bool:
	for span_variant in spans:
		if span_variant is Dictionary and String(span_variant.get("file", "")) == file_name:
			return true
	return false


func _fail(message: String) -> bool:
	push_error(message)
	return false
