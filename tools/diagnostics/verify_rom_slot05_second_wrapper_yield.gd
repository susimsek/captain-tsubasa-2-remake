extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_MANIFEST_SHA256 := "afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc"


func _init() -> void:
	var result := _verify_second_wrapper_yield_and_next_blocker()
	quit(0 if result else 1)


func _verify_second_wrapper_yield_and_next_blocker() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh KICK OFF context sources failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Could not produce the fresh KICK OFF source context: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route configuration failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)):
		return _fail("Source route did not begin: " + String(begin.get("error", runner.error_message)))
	for frame in [1, 2]:
		var nmi: Dictionary = runner.advance_on_external_nmi(frame, 0x88)
		if not bool(nmi.get("ok", false)):
			return _fail("External NMI %d was not consumed at the recorded scheduler boundary." % frame)
	var first_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(first_slot05.get("ok", false)) \
			or String(first_slot05.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(first_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("The first slot-$05 worker did not preserve the existing slot-$09 handoff.")
	var first_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(first_slot09.get("ok", false)) \
			or String(first_slot09.get("status", "")) != "slot09_saved_and_rescanned":
		return _fail("The first selected slot-$09 continuation did not reach its existing save boundary.")
	var nmi3: Dictionary = runner.advance_on_external_nmi(3, 0x88)
	if not bool(nmi3.get("ok", false)) or int(nmi3.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("External NMI 3 did not select the source slot-$05 continuation.")
	var second_wrapper: Dictionary = runner.resume_selected_slot05_worker()
	var worker: Dictionary = second_wrapper.get("slot05_worker_result", {})
	if not bool(second_wrapper.get("ok", false)) \
			or String(second_wrapper.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(second_wrapper.get("next_selected_task_slot", -1)) != 0x09 \
			or String(worker.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or int(worker.get("exit_pc", -1)) != 0xC515 \
			or String(worker.get("exit_kind", "")) != "yield_at_c515":
		return _fail("The live second wrapper worker did not reach and save its source `$C515` yield.")
	var regs: Dictionary = worker.get("registers", {})
	var mapper: Dictionary = worker.get("mapper", {})
	var ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	if int(regs.get("a", -1)) != 0x01 or int(regs.get("sp", -1)) != 0x48 \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or ram.size() != 0x800 or int(ram[0x0629]) != 0 \
			or int(ram[0x0515]) != 0x80:
		return _fail("The second wrapper's source yield registers, mapper, or fresh-match RAM inputs changed.")
	var saw_second_call := false
	var saw_wrapper_worker_entry := false
	var returned_to_second_wrapper_caller := false
	for call_variant in worker.get("calls", []):
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) == 0xDACE and int(call.get("target", -1)) == 0xEF7F:
				saw_second_call = true
			if int(call.get("callsite", -1)) == 0xEF96 and int(call.get("target", -1)) == 0x800C:
				saw_wrapper_worker_entry = true
	for instruction_variant in worker.get("instructions", []):
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			if int(instruction.get("pc", -1)) == 0xCE49 and int(instruction.get("next_pc", -1)) == 0xDACC:
				returned_to_second_wrapper_caller = true
	if not saw_second_call or not saw_wrapper_worker_entry or not returned_to_second_wrapper_caller:
		return _fail("The executed call stream omitted the source `$DACE->$EF7F->$800C` second wrapper invocation.")
	print("PASS: source route executed the second `$DACE->$EF7F->$800C` worker and scheduler-saved its source `$C515` yield.")
	print("STOP: this verifier ends at the second wrapper yield. Later descriptor-row execution is covered separately.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
