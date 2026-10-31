extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const WORKER_MANIFEST_SHA256 := "afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc"


func _init() -> void:
	if not _verify_slot05_worker_resume():
		quit(1)
		return
	quit(0)


func _verify_slot05_worker_resume() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Fresh context builder setup failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("Source-generated kickoff context failed: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Route runner setup failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("last_source_boundary", "")) != "$EB8B":
		return _fail("Fresh route did not reach its ROM-derived `$EB8B` boundary.")
	var first_nmi: Dictionary = runner.advance_on_external_nmi(1, 0x88)
	if not bool(first_nmi.get("ok", false)) \
			or not bool(first_nmi.get("awaiting_external_nmi", false)):
		return _fail("First caller-supplied NMI did not reach the checked scheduler wait boundary.")
	var second_nmi: Dictionary = runner.advance_on_external_nmi(2, 0x88)
	if not bool(second_nmi.get("ok", false)) \
			or int(second_nmi.get("selected_task_slot", -1)) != 0x01 \
			or int(second_nmi.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("Second-NMI route did not source-select slot `$05` after the root slot-$01 save.")
	var resumed: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(resumed.get("ok", false)):
		return _fail("Live slot-$05 continuation failed: " + String(resumed.get("error", runner.error_message)))
	var worker: Dictionary = resumed.get("slot05_worker_result", {})
	var dispatch: Dictionary = resumed.get("slot05_dispatch", {})
	var saved: Dictionary = resumed.get("slot05_cb0f_saved_boundary", {})
	var scan: Dictionary = resumed.get("post_slot05_scan", {})
	var slot09: Dictionary = resumed.get("next_selected_task_boundary", {})
	if String(resumed.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("bank_low", -1)) != 0x18 \
			or int(dispatch.get("bank_high", -1)) != 0x19 \
			or not bool(worker.get("ok", false)) \
			or String(worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker.get("exit_pc", -1)) != 0xC515 \
			or String(worker.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or not bool(resumed.get("slot05_worker_adopted", false)):
		return _fail("The live slot-$05 worker did not complete from its checked `$8889` dispatch through `$C515`.")
	if int(saved.get("pc", -1)) != 0xCB0F \
			or int(saved.get("slot_base", -1)) != 0x05 \
			or saved.get("record", PackedByteArray()) != PackedByteArray([0x01, 0x46, 0x18, 0x19]) \
			or int(saved.get("ram_007F", -1)) != 0x01:
		return _fail("The ROM-checked `$CB0F` handler did not save the live slot-$05 A/SP/bank state.")
	if int(scan.get("decision", -1)) != int(SCHEDULER_SCRIPT.ScanDecision.YIELDED_RESUME) \
			or scan.get("checked_slots", []) != [0x09] \
			or int(resumed.get("next_selected_task_slot", -1)) != 0x09 \
			or int(slot09.get("slot_base", -1)) != 0x09 \
			or int(slot09.get("pc", -1)) != 0xCB0F \
			or int(slot09.get("phase", -1)) != 3 \
			or int(slot09.get("pending_resume", -1)) != 2 \
			or slot09.get("record", PackedByteArray()) != PackedByteArray([0x00, 0x76, 0x18, 0x19]) \
			or bool(resumed.get("next_task_body_executed", true)) \
			or bool(resumed.get("nmi_cadence_generated", true)) \
			or bool(resumed.get("ppu_bus_events_applied", true)):
		return _fail("The post-save scan did not stop at slot `$09`'s actual pre-dispatch boundary.")
	print("PASS: live slot-$05 worker state reached the hash-checked `$CB0F` save; saved record=`%s`." % [
		(saved.get("record", PackedByteArray()) as PackedByteArray).hex_encode()])
	print("PASS: source scan decremented slot `$09` `$01->$00`, selected its yielded context, and stopped before dispatch.")
	print("STOP: no later task body, external NMI, NMI cadence, or PPU application was performed.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
