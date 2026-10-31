extends SceneTree

const CONTEXT_BUILDER := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const ROUTE_RUNNER := preload("res://scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd")
const TASK_SCHEDULER := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const FCEUX_MAP42_FIRST_BATCH_SHA256 := "1af864cf8efad02dfc1f00baf08b8c7e037c5fe931ebc1a64b49ac92b2438d52"
const FCEUX_MAP42_SECOND_BATCH_SHA256 := "0f0c448f8edac511fe7bf548ed2259a8bd4e581cdfc660221fac97a5912fdd1b"
const FCEUX_MAP42_THIRD_BATCH_SHA256 := "85c7cc381b97e49c5227d6cc9a2bd5a54a96f43ebd97fff82422f9321bbcae1e"
const FCEUX_MAP42_FOURTH_BATCH_SHA256 := "5e473377dfa6cb10a9e3706885787a62791f28381c3ffb5d8b3c5610adf5e3ab"
const FCEUX_MAP42_CONTINUATION_BATCHES := [
	{"start": 12, "ids": "33,33,33", "sha256": "a92be740e48050139c0a1ba3c4f1e2e0a60346d9b220d9973792c6675d77046e", "writes": 51},
	{"start": 15, "ids": "33,15,16", "sha256": "39ab0d71c08bb3320b40421aa3d174178e1006d05346114b16fde3efd2e54d6d", "writes": 51},
	{"start": 18, "ids": "15,EA,EB", "sha256": "cc0b05bd7e05b3ffe9b6027c7597e4bab9e7667cb55404d68420303685c209de", "writes": 51},
	{"start": 21, "ids": "16,15,16", "sha256": "10c9ebf55bd12442537d27734c3ed0558b59d22b9ce6fcb211fe8196844882d2", "writes": 51},
	{"start": 24, "ids": "14,14,14", "sha256": "5232a6f3022517566cdb4956390d8f4293c7b9883e8476dfdc15c558b35ad2b3", "writes": 51},
	{"start": 27, "ids": "14,14,14", "sha256": "1a11dd4a2b10b6f731bae110531aaf6740c40fae73daa53eee3a9b9b81e12b1e", "writes": 51},
	{"start": 30, "ids": "14,14", "sha256": "247690436ccaeabef5785af9a596a5c0f768bfbba1d4aec05a4bae2a0e004bba", "writes": 34},
]
const WORKER_MANIFEST_SHA256 := "d3f5ba788ea93fb02c6678f88efff9fe19aa303d19440b89c88ad81907a539ad"
const ROW02_FILE := "bank19_resumed_worker_descriptor01_row02_BBE3_BBE6.bin"
const ROW03_FILE := "bank19_resumed_worker_descriptor01_row03_BD9F_BDA2.bin"
const TEAM00_FILE := "fixed_team_00_name_stream_F776_F77C.bin"


func _init() -> void:
	var ok := _verify()
	quit(0 if ok else 1)


func _verify() -> bool:
	var builder = CONTEXT_BUILDER.new()
	if not builder.configure_from_project_sources():
		return _fail("Source context configuration failed: " + builder.error_message)
	var context = builder.build_fresh_kickoff_context()
	if context == null:
		return _fail("ROM-derived fresh-match context could not be built: " + builder.error_message)
	var runner = ROUTE_RUNNER.new()
	if not runner.configure_from_project_sources():
		return _fail("Source route configuration failed: " + runner.error_message)
	var begin: Dictionary = runner.begin_from_context(context)
	if not bool(begin.get("ok", false)) or String(begin.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Route did not begin from the expected ROM-derived context: " + str(begin))
	for frame in [1, 2]:
		var nmi: Dictionary = runner.advance_on_external_nmi(frame, 0x88)
		if not bool(nmi.get("ok", false)):
			return _fail("Initial caller-labeled NMI failed: " + runner.error_message)
	var first_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(first_slot05.get("ok", false)) or int(first_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Initial slot-$05 worker did not select source slot $09.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("Initial slot-$09 continuation failed: " + runner.error_message)
	var nmi3: Dictionary = runner.advance_on_external_nmi(3, 0x88)
	if not bool(nmi3.get("ok", false)) or int(nmi3.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("Caller-labeled NMI 3 did not select slot $05.")
	var second_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(second_slot05.get("ok", false)) or int(second_slot05.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Second slot-$05 worker did not select source slot $09.")
	if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
		return _fail("Second slot-$09 continuation failed: " + runner.error_message)
	var nmi4: Dictionary = runner.advance_on_external_nmi(4, 0x88)
	if not bool(nmi4.get("ok", false)) or int(nmi4.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("Caller-labeled NMI 4 did not select slot $05.")
	var slot05_boundary: Dictionary = runner.resume_selected_slot05_worker()
	if String(slot05_boundary.get("status", "")) == "slot05_saved_and_rescanned" \
			and int(slot05_boundary.get("next_selected_task_slot", -1)) == 0x09:
		if not bool(runner.resume_selected_slot09_worker().get("ok", false)):
			return _fail("Intervening slot-$09 continuation failed: " + runner.error_message)
		var nmi5: Dictionary = runner.advance_on_external_nmi(5, 0x88)
		if not bool(nmi5.get("ok", false)) or int(nmi5.get("next_selected_task_slot", -1)) != 0x05:
			return _fail("Caller-labeled NMI 5 did not select slot $05.")
		slot05_boundary = runner.resume_selected_slot05_worker()
	if not bool(slot05_boundary.get("ok", false)) \
			or String(slot05_boundary.get("status", "")) != "stopped_at_descriptor01_ee_row_boundary":
		return _fail("Live slot-$05 worker did not reach its row-00 boundary: " + str(slot05_boundary))
	var ee_row: Dictionary = runner.resume_slot05_descriptor01_ee_row00()
	if not bool(ee_row.get("ok", false)) \
			or String(ee_row.get("status", "")) != "stopped_after_descriptor01_ee_row00_yield":
		return _fail("Existing live EE00 transition failed: " + runner.error_message)
	var saved: Dictionary = runner.save_slot05_ee_row_yield_and_scan()
	if not bool(saved.get("ok", false)) or int(saved.get("next_selected_task_slot", -1)) != 0x09:
		return _fail("Slot-$05 save/scan did not select source slot $09.")
	var slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(slot09.get("ok", false)) or not bool(slot09.get("awaiting_external_nmi", false)):
		return _fail("Slot-$09 did not reach the source-owned NMI wait.")
	var prior_frame := int(runner.get_status().get("last_external_nmi_frame", -1))
	var route: Dictionary = runner.advance_on_external_nmi(prior_frame + 1, 0x88)
	if not bool(route.get("ok", false)) or int(route.get("selected_task_slot", -1)) != 0x01 \
			or int(route.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("One caller-labeled NMI did not select slot $01 and return the live slot-$05 task.")
	var before: Dictionary = runner.get_status()
	if int(before.get("pending_selected_task_slot", -1)) != 0x05:
		return _fail("Scheduler did not leave slot $05 pending after the slot-$01 return.")
	var slot05_result: Dictionary = runner.resume_selected_slot05_worker()
	var worker: Dictionary = slot05_result.get("slot05_worker_result", {})
	var worker_input: Dictionary = slot05_result.get("slot05_worker_input", {})
	var dispatch: Dictionary = slot05_result.get("slot05_dispatch", {})
	var live_slot05: Dictionary = slot05_result.get("slot05_live_boundary", {})
	var worker_ram: PackedByteArray = worker.get("ram_image", PackedByteArray())
	var input_ram: PackedByteArray = worker_input.get("ram_image", PackedByteArray())
	var input_stack: PackedByteArray = worker_input.get("stack_page", PackedByteArray())
	var writes: Array = worker.get("writes", [])
	var spans: Array = worker.get("executed_source_spans", [])
	var blocked: Dictionary = worker.get("blocked_read", {})
	var live_boundary: Dictionary = runner._scheduler.get_task_boundary_snapshot(0x05)
	var adopted_boundary: Dictionary = slot05_result.get("slot05_worker_adopted_boundary", {})
	var adopted_ram: PackedByteArray = adopted_boundary.get("ram_image", PackedByteArray())
	var found_row02 := false
	var found_row03 := false
	var found_team00 := false
	var span_hash_row02 := ""
	var span_hash_row03 := ""
	for span_variant in spans:
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		if String(span.get("file", "")) == ROW02_FILE:
			found_row02 = true
			span_hash_row02 = String(span.get("sha256", ""))
		if String(span.get("file", "")) == ROW03_FILE:
			found_row03 = true
			span_hash_row03 = String(span.get("sha256", ""))
		found_team00 = found_team00 or String(span.get("file", "")) == TEAM00_FILE
	if not bool(slot05_result.get("ok", false)) \
			or String(slot05_result.get("status", "")) != "slot05_saved_and_rescanned" \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("a", -1)) != 0x0F or int(dispatch.get("x", -1)) != 0x0F \
			or int(dispatch.get("y", -1)) != 0x03 or int(dispatch.get("sp", -1)) != 0x4A \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or PackedByteArray(live_slot05.get("record", PackedByteArray())) != PackedByteArray([0x00, 0x46, 0x18, 0x19]) \
			or input_stack.slice(0x40, 0x50) != PackedByteArray([0x00,0x81,0x8C,0xB9,0x52,0xA8,0x89,0x03,0x0F,0x88,0x88,0x98,0xEF,0x1D,0x1C,0xD0]) \
			or String(worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker.get("exit_pc", -1)) != 0xC515 \
			or String(worker.get("source_manifest_sha256", "")) != WORKER_MANIFEST_SHA256 \
			or span_hash_row02 != "ff4579caac8640e812546cc7649a99a939843eb1f972ccb5c5b715278c5dbd47" \
			or span_hash_row03 != "55535becc5335f960faf89b9118f0677f4a009dffd35466781512590f9f40291" \
			or not found_row02 or not found_row03 or not found_team00 \
			or worker_ram.size() != 0x800 or input_ram.size() != 0x800 \
			or int(input_ram[0x0629]) != 0 or int(worker_ram[0x0629]) != 0 \
			or adopted_ram != worker_ram or not bool(slot05_result.get("slot05_worker_adopted", false)):
		return _fail("Live descriptor-$01 row checks failed: %s" % str({
			"status": slot05_result.get("status"), "worker_exit": worker.get("exit_kind"),
			"exit_pc": worker.get("exit_pc"), "blocked": blocked,
			"manifest_match": String(worker.get("source_manifest_sha256", "")) == WORKER_MANIFEST_SHA256,
			"row02": found_row02, "row02_hash": span_hash_row02,
			"row03": found_row03, "row03_hash": span_hash_row03, "team00": found_team00,
			"adopted": slot05_result.get("slot05_worker_adopted"),
			"adopted_matches_worker": adopted_ram == worker_ram,
			"post_save_matches_worker": PackedByteArray(slot05_result.get("slot05_post_worker_boundary", {}).get("ram_image", PackedByteArray())) == worker_ram,
			"live_pc": live_boundary.get("pc", -1), "live_active": live_boundary.get("active_task_slot", -1),
			"input_pointer": input_ram.slice(0x003E, 0x0040).hex_encode(),
			"worker_pointer": worker_ram.slice(0x003E, 0x0040).hex_encode(),
			"input_0629": input_ram[0x0629] if input_ram.size() > 0x629 else -1,
			"worker_0629": worker_ram[0x0629] if worker_ram.size() > 0x629 else -1,
			"writes": writes.size(), "next_slot": slot05_result.get("next_selected_task_slot")}))
	var instructions: Array = worker.get("instructions", [])
	var entered_ed_handler := false
	var returned_fc := false
	for instruction_variant in instructions:
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		if int(instruction.get("pc", -1)) == 0x8AE7:
			entered_ed_handler = true
		if int(instruction.get("pc", -1)) == 0x8C52:
			returned_fc = true
	if not entered_ed_handler or not returned_fc:
		return _fail("The live worker trace lacks the ED handler entry at $8AE7 or FC return at $8C52.")
	print("PASS: slot-$05 record %s dispatched at $8889 and consumed ROM rows $BBE3 ED 01 FC and $BD9F EE 01 FC through `$C515`." % [
		PackedByteArray(live_slot05.get("record", PackedByteArray())).hex_encode()])
	print("YIELD: worker returned at `$C515`; scheduler adopted its ordered writes and selected slot $%02X. `$0629` remains zero." % [
		int(slot05_result.get("next_selected_task_slot", -1))])
	print("PROVENANCE: %s (%s), %s (%s), %s; %d ordered RAM writes." % [
		ROW02_FILE, span_hash_row02, ROW03_FILE, span_hash_row03, TEAM00_FILE, writes.size()])
	print("DISPATCH: A/X/Y/SP=%02X/%02X/%02X/%02X, banks $18/$19; stack $0140-$014F=%s." % [
		int(dispatch.get("a", -1)), int(dispatch.get("x", -1)), int(dispatch.get("y", -1)),
		int(dispatch.get("sp", -1)), input_stack.slice(0x40, 0x50).hex_encode()])
	print("INPUT/OUTPUT: $002A/$002B=%02X/%02X; $003E-$003F=%s -> %s; $003C=%02X -> %02X; $0629=%02X." % [
		int(input_ram[0x002A]),
		int(input_ram[0x002B]), input_ram.slice(0x003E, 0x0040).hex_encode(),
		worker_ram.slice(0x003E, 0x0040).hex_encode(),
		int(input_ram[0x003C]), int(worker_ram[0x003C]), int(worker_ram[0x0629])])
	print("PACKET BYTES: $04A5-$04AE=%s; `$8AE7` ED handler, `$8B2F` EE handler, and `$8C52` FC return observed." % [
		worker_ram.slice(0x04A5, 0x04AF).hex_encode()])
	var slot09_after_rows: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(slot09_after_rows.get("ok", false)) \
			or not bool(slot09_after_rows.get("awaiting_external_nmi", false)):
		return _fail("Post-row slot-$09 continuation did not reach its source-owned NMI wait.")
	var nmi_frame := int(runner.get_status().get("last_external_nmi_frame", -1)) + 1
	var post_row_nmi: Dictionary = runner.advance_on_external_nmi(nmi_frame, 0x88)
	if not bool(post_row_nmi.get("ok", false)) \
			or int(post_row_nmi.get("selected_task_slot", -1)) != 0x01 \
			or int(post_row_nmi.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("The following caller-labeled NMI did not return slot $01 and select slot $05.")
	var next_slot05: Dictionary = runner.resume_selected_slot05_worker()
	if not bool(next_slot05.get("ok", false)):
		return _fail("The next live slot-$05 continuation failed: " + str(next_slot05.get("error", runner.error_message)))
	var next_worker: Dictionary = next_slot05.get("slot05_worker_result", {})
	var next_blocked: Dictionary = next_worker.get("blocked_read", {})
	var next_ram: PackedByteArray = next_worker.get("ram_image", PackedByteArray())
	var next_pointer := -1
	if next_ram.size() == 0x800:
		next_pointer = int(next_ram[0x003E]) | (int(next_ram[0x003F]) << 8)
	if String(next_slot05.get("status", "")) != "slot05_saved_and_rescanned" \
			or String(next_worker.get("exit_kind", "")) != "yield_at_c515" \
			or int(next_worker.get("exit_pc", -1)) != 0xC515 \
			or next_pointer != 0xBD9F \
			or (next_worker.get("writes", []) as Array).size() != 92 \
			or int(next_slot05.get("next_selected_task_slot", -1)) != 0x09 \
			or next_ram.size() != 0x800 or int(next_ram[0x0629]) != 0:
		return _fail("The repeated slot-$05 continuation did not preserve the verified `$BD9F`/`$C515` boundary: %s" % str({
			"status": next_slot05.get("status"), "worker_exit": next_worker.get("exit_kind"),
			"exit_pc": next_worker.get("exit_pc"), "pointer": next_pointer,
			"writes": (next_worker.get("writes", []) as Array).size(),
			"next_slot": next_slot05.get("next_selected_task_slot"),
			"blocked": next_blocked, "ram_size": next_ram.size()}))
	print("FOLLOW-UP: slot $09 reached its NMI wait; caller-labeled frame %d returned slot $01 and selected slot $05." % nmi_frame)
	print("NEXT SLOT-$05: status=%s exit=%s pc=$%04X pointer=$%04X blocked=%s writes=%d next_slot=$%02X." % [
		String(next_slot05.get("status", "")), String(next_worker.get("exit_kind", "")),
		int(next_worker.get("exit_pc", -1)), next_pointer, str(next_blocked),
		(next_worker.get("writes", []) as Array).size(),
		int(next_slot05.get("next_selected_task_slot", -1))])
	print("NEXT STATE: $003C=%02X $0515=%02X $05C5=%02X $0629=%02X." % [
		int(next_ram[0x003C]), int(next_ram[0x0515]), int(next_ram[0x05C5]), int(next_ram[0x0629])])
	var repeat_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(repeat_slot09.get("ok", false)) \
			or not bool(repeat_slot09.get("awaiting_external_nmi", false)):
		return _fail("Repeated slot-$09 continuation did not reach its NMI wait.")
	var repeat_nmi_frame := int(runner.get_status().get("last_external_nmi_frame", -1)) + 1
	var repeat_nmi: Dictionary = runner.advance_on_external_nmi(repeat_nmi_frame, 0x88)
	if not bool(repeat_nmi.get("ok", false)) \
			or int(repeat_nmi.get("selected_task_slot", -1)) != 0x01 \
			or int(repeat_nmi.get("next_selected_task_slot", -1)) != 0x05:
		return _fail("Repeated caller-labeled NMI did not return slot $01 and select slot $05.")
	var repeated_slot05: Dictionary = runner.resume_selected_slot05_worker()
	var repeated_worker: Dictionary = repeated_slot05.get("slot05_worker_result", {})
	var repeated_ram: PackedByteArray = repeated_worker.get("ram_image", PackedByteArray())
	var scenario35_validated: bool = runner._scheduler.validate_slot05_scenario35_enqueue_worker_result(repeated_worker)
	if not bool(repeated_slot05.get("ok", false)) \
			or String(repeated_slot05.get("status", "")) != "slot05_saved_and_rescanned" \
			or String(repeated_worker.get("exit_kind", "")) != "unresolved_source_span" \
			or int(repeated_worker.get("exit_pc", -1)) != 0xCB0F \
			or int(repeated_slot05.get("next_selected_task_slot", -1)) != 0x09 \
			or not bool(repeated_slot05.get("slot05_scenario35_enqueue_validated", false)) \
			or not scenario35_validated \
			or repeated_ram.size() != 0x800 or int(repeated_ram[0x0629]) != 0:
		return _fail("ROM scenario-$35 enqueue did not save slot $05 at `$CB0F` and select slot $09: %s" % str({
			"ok": repeated_slot05.get("ok"), "status": repeated_slot05.get("status"),
			"phase": repeated_slot05.get("phase"), "error": repeated_slot05.get("error"),
			"reason": repeated_slot05.get("reason"),
			"worker_exit": repeated_worker.get("exit_kind"), "exit_pc": repeated_worker.get("exit_pc"),
			"worker_error": repeated_worker.get("error"), "blocked": repeated_worker.get("blocked_read"),
			"helper_validated": scenario35_validated,
			"worker_manifest": repeated_worker.get("source_manifest_sha256"),
			"registers": repeated_worker.get("registers"), "mapper": repeated_worker.get("mapper"),
			"executed_spans": repeated_worker.get("executed_source_spans"),
			"instruction_tail": (repeated_worker.get("instructions", []) as Array).slice(-12),
			"calls": repeated_worker.get("calls", []),
			"dispatch": repeated_slot05.get("slot05_dispatch"),
			"output_0515_0518": repeated_ram.slice(0x0515, 0x0519).hex_encode() if repeated_ram.size() == 0x800 else "",
			"output_0005": repeated_ram[0x0005] if repeated_ram.size() == 0x800 else -1,
			"output_0629": repeated_ram[0x0629] if repeated_ram.size() == 0x800 else -1,
			"input_0515_0518": (repeated_slot05.get("slot05_worker_input", {}).get("ram_image", PackedByteArray()) as PackedByteArray).slice(0x0515, 0x0519).hex_encode(),
			"adopted": repeated_slot05.get("slot05_worker_adopted"),
			"next_slot": repeated_slot05.get("next_selected_task_slot"), "ram_size": repeated_ram.size()}))
	var repeated_mapper: Dictionary = repeated_worker.get("mapper", {})
	print("SCENARIO35: caller-labeled frame %d returned slot $01; live `$DAD1->$DAD8->$DADA->$CBB0` wrote `$0518=$35`, `$0516=$80`, `$0005=$00`; slot $05 saved at `$CB0F` and selected slot $09. Worker mapper=$%02X/$%02X, `$0629=$%02X`." % [
		repeat_nmi_frame, int(repeated_mapper.get("bank_low", -1)),
		int(repeated_mapper.get("bank_high", -1)), int(repeated_ram[0x0629])])
	var active_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(active_slot09.get("ok", false)):
		return _fail("Live scenario-active slot-$09 route failed: " + str(active_slot09))
	var slot15_entry: Dictionary = runner.resume_selected_slot15_source_task()
	if not bool(slot15_entry.get("ok", false)) \
			or String(slot15_entry.get("status", "")) != "slot15_map_worker_yielded_waiting_nmi" \
			or int(slot15_entry.get("callback_entry_result", {}).get("exit_pc", -1)) != 0x814C \
			or int(slot15_entry.get("callback_handler_result", {}).get("exit_pc", -1)) != 0x8327 \
			or int(slot15_entry.get("callback_map_worker_entry_result", {}).get("exit_pc", -1)) != 0x8525 \
			or int(slot15_entry.get("map_worker_setup_result", {}).get("exit_pc", -1)) != 0x856F \
			or not bool(slot15_entry.get("callback_dispatcher_body_executed", false)) \
			or not bool(slot15_entry.get("callback_handler_prefix_executed", false)) \
			or not bool(slot15_entry.get("map_worker_setup_executed", false)) \
			or bool(slot15_entry.get("map_worker_rows_executed", true)):
		return _fail("ROM-scheduled slot-$15 callback `$3A` did not reach its first `$C515` yield: " + str(slot15_entry))
	var slot15_ram: PackedByteArray = slot15_entry.get("callback_handler_result", {}).get("ram_image", PackedByteArray())
	if slot15_ram.size() == 0x800:
		print("CALLBACK INPUT: $0524/$0523=$%02X/$%02X; live RAM $05CD=$%02X; slot $15 record=%s." % [int(slot15_ram[0x0524]), int(slot15_ram[0x0523]), int(slot15_ram[0x05CD]), slot15_entry.get("selected_slot_boundary", {}).get("record", PackedByteArray()).hex_encode()])
	var callback_registers: Dictionary = slot15_entry.get("callback_handler_result", {}).get("registers", {})
	if int(callback_registers.get("a", -1)) != 0x27 or int(callback_registers.get("x", -1)) != 0xF3 \
			or int(callback_registers.get("y", -1)) != 2 or int(callback_registers.get("sp", -1)) != 0xF0 \
			or int(slot15_ram[0x0525]) != 2 or int(slot15_ram[0x05CD]) != 0:
		return _fail("Live callback `$3A` entry state at `$8327` differs from its ROM data/trampoline contract.")
	var map_worker_result: Dictionary = slot15_entry.get("callback_map_worker_entry_result", {})
	var map_worker_registers: Dictionary = map_worker_result.get("registers", {})
	var map_worker_ram: PackedByteArray = map_worker_result.get("ram_image", PackedByteArray())
	var map_worker_stack: PackedByteArray = map_worker_result.get("stack_page", PackedByteArray())
	if int(map_worker_registers.get("a", -1)) != 0x42 or int(map_worker_registers.get("x", -1)) != 0xF3 \
			or int(map_worker_registers.get("y", -1)) != 0 or int(map_worker_registers.get("sp", -1)) != 0xEE \
			or int(map_worker_result.get("map_selector", -1)) != 0x42 \
			or map_worker_ram.size() != 0x800 or int(map_worker_ram[0x05CC]) != 0x42 \
			or map_worker_stack.size() != 0x100 or int(map_worker_stack[0xF0]) != 0x83 \
			or int(map_worker_stack[0xEF]) != 0x33:
		return _fail("The `$8327` map-handler prefix did not preserve selector `$42` and push the `$8525` return frame.")
	var map_setup: Dictionary = slot15_entry.get("map_worker_setup_result", {})
	var map_setup_registers: Dictionary = map_setup.get("registers", {})
	var map_setup_ram: PackedByteArray = map_setup.get("ram_image", PackedByteArray())
	if int(map_setup.get("exit_pc", -1)) != 0x856F or int(map_setup_registers.get("a", -1)) != 1 \
			or int(map_setup_registers.get("x", -1)) != 8 or int(map_setup_registers.get("y", -1)) != 0x10 \
			or int(map_setup_registers.get("p", -1)) != 0x20 or int(map_setup_registers.get("sp", -1)) != 0xED \
			or map_setup_ram.size() != 0x800 or int(map_setup_ram[0x0526]) != 0xBC \
			or int(map_setup_ram[0x0527]) != 0x2C or int(map_setup_ram[0x05CA]) != 1 \
			or int(map_setup_ram[0x0054]) != 0xA4 or int(map_setup_ram[0x0055]) != 0x93 \
			or int(map_setup_ram[0x05C9]) != 0x20:
		return _fail("Map-$42 `$8525->$856F` state differs from its decoded source-data contract.")
	var yielded_boundary: Dictionary = slot15_entry.get("slot15_yielded_boundary", {})
	if int(yielded_boundary.get("pc", -1)) != 0xCB0F \
			or yielded_boundary.get("record", PackedByteArray()) != PackedByteArray([0x01, 0xE9, 0x0B, 0x0C]) \
			or int(slot15_entry.get("map_worker_yield_scan", {}).get("decision", -1)) \
			!= int(TASK_SCHEDULER.ScanDecision.WAIT_FOR_NMI_READY):
		return _fail("The first `$856F->$C515->$CB0F` save did not reach the source scheduler's NMI wait.")
	var after_map_nmi: Dictionary = runner.advance_on_external_nmi(8, 0x88)
	if not bool(after_map_nmi.get("ok", false)):
		return _fail("The caller-supplied NMI after the map-worker yield did not resume the source route: " + str(after_map_nmi))
	var post_map_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(post_map_slot09.get("ok", false)):
		return _fail("The scheduler-selected slot-$09 continuation after map-worker NMI failed: %s boundary=%s" % [str(post_map_slot09), str(after_map_nmi.get("next_selected_task_boundary", {}))])
	print("SCENARIO ACTIVE: slot $09 returned through `$EC74`; slot $15 callback `$3A` reached `$8327`, resolved map `$42`, computed selector `$01` and CHR pair `$3C/$2C`, then saved the first `$8525` yield from `$856F->$C515`.")
	print("POST-YIELD: NMI selected slot $%02X; source execution then resumed slot $09 to status `%s` with next slot $%02X." % [int(after_map_nmi.get("selected_task_slot_before_resume", -1)), String(post_map_slot09.get("status", "")), int(post_map_slot09.get("next_selected_task_slot", -1))])
	var post_map_next: Dictionary = post_map_slot09.get("next_selected_task_boundary", {})
	print("NEXT BOUNDARY: slot $%02X pc=$%04X sp=$%02X a/x/y=%02X/%02X/%02X banks=$%02X/$%02X record=%s." % [int(post_map_next.get("slot_base", -1)), int(post_map_next.get("pc", -1)), int(post_map_next.get("sp", -1)), int(post_map_next.get("a", -1)), int(post_map_next.get("x", -1)), int(post_map_next.get("y", -1)), int(post_map_next.get("bank_low", -1)), int(post_map_next.get("bank_high", -1)), post_map_next.get("record", PackedByteArray()).hex_encode()])
	var post_map_ram: PackedByteArray = post_map_next.get("ram_image", PackedByteArray())
	if post_map_ram.size() == 0x800:
		print("MAP-WORKER INPUT: $0515/$05C7/$05C8/$05C9=%02X/%02X/%02X/%02X; $54/$55=%02X%02X; queue=%s." % [int(post_map_ram[0x0515]), int(post_map_ram[0x05C7]), int(post_map_ram[0x05C8]), int(post_map_ram[0x05C9]), int(post_map_ram[0x0055]), int(post_map_ram[0x0054]), post_map_ram.slice(0x04A5, 0x04AD).hex_encode()])
	var map_batch_route: Dictionary = runner.resume_selected_slot15_source_task()
	if not bool(map_batch_route.get("ok", false)) \
			or String(map_batch_route.get("status", "")) != "slot15_map42_batch_yielded" \
			or not bool(map_batch_route.get("map_worker_rows_executed", false)) \
			or int(map_batch_route.get("queue_bytes_generated", -1)) != 0x60:
		return _fail("Live slot-$15 map-$42 worker did not produce and save its source-selected 96-byte batch: %s" % str(map_batch_route))
	var map_batch: Dictionary = map_batch_route.get("map_batch_result", {})
	var map_batch_ram: PackedByteArray = map_batch.get("updated_ram", PackedByteArray())
	var first_queue_bytes: PackedByteArray = map_batch.get("queue_bytes", PackedByteArray())
	if map_batch_ram.size() != 0x800 or first_queue_bytes.size() != 0x60 \
			or _sha256_hex(first_queue_bytes) != FCEUX_MAP42_FIRST_BATCH_SHA256 \
			or first_queue_bytes.slice(0, 7) != PackedByteArray([0x04, 0x00, 0x20, 0, 0, 0, 0]) \
			or first_queue_bytes.slice(0x1C, 0x20) != PackedByteArray([0x01, 0xC0, 0x23, 0]) \
			or first_queue_bytes.slice(0x3C, 0x40) != PackedByteArray([0x01, 0xC1, 0x23, 0]) \
			or first_queue_bytes.slice(0x5C, 0x60) != PackedByteArray([0x01, 0xC2, 0x23, 0]) \
			or int(map_batch_ram[0x05C7]) != 0x60 or int(map_batch_ram[0x05C8]) != 3 \
			or int(map_batch_ram[0x05C9]) != 0x1D or int(map_batch_ram[0x0515]) != 0x80 \
			or int(map_batch_route.get("yielded_boundary", {}).get("bank_high", -1)) != 0x12:
		return _fail("Map-$42 batch bytes, source worker cursor, or mapper transition differ from the first-row contract: %s" % str(map_batch_route))
	print("MAP BATCH: resumed `$8572`, read ROM map-$42 cells %s, and expanded three `$14` metatiles into 96 queue bytes matching FCEUX snapshot 8 SHA-256 %s; `$05C7/$05C8/$05C9=$%02X/$%02X/$%02X`, mapper high bank `$%02X`." % [
		PackedByteArray([0x14, 0x14, 0x14]).hex_encode(), FCEUX_MAP42_FIRST_BATCH_SHA256,
		int(map_batch_ram[0x05C7]),
		int(map_batch_ram[0x05C8]), int(map_batch_ram[0x05C9]),
		int(map_batch_route.get("yielded_boundary", {}).get("bank_high", -1))])
	var map_batch_nmi: Dictionary = runner.advance_on_external_nmi(9, 0x88)
	if not bool(map_batch_nmi.get("ok", false)):
		return _fail("The caller-supplied NMI did not consume the ROM-generated map batch: %s" % str(map_batch_nmi))
	var map_batch_bus_events: Array = map_batch_nmi.get("ppu_bus_events", [])
	var ppu_data_write_count := 0
	for event_variant in map_batch_bus_events:
		if event_variant is Dictionary and String(event_variant.get("operation", "")) == "write" \
				and int(event_variant.get("ppu_register", -1)) == 0x2007:
			ppu_data_write_count += 1
	if ppu_data_write_count != 51:
		return _fail("Normal NMI did not convert the first map-$42 batch into 51 ordered PPU writes: %s" % str({
			"bus_events": map_batch_bus_events.size(), "ppu_data_writes": ppu_data_write_count,
			"last_source_boundary": map_batch_nmi.get("last_source_boundary", "")}))
	var after_map_nmi_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(after_map_nmi_slot09.get("ok", false)):
		return _fail("The post-map NMI slot-$09 task did not follow its live ROM path: %s" % str(after_map_nmi_slot09))
	var next_slot15_boundary: Dictionary = after_map_nmi_slot09.get("next_selected_task_boundary", {})
	var next_slot15_ram: PackedByteArray = next_slot15_boundary.get("ram_image", PackedByteArray())
	print("POST MAP NMI: slot $09 saved; next=$%02X record=%s PC=$%04X A/X/Y/SP=%02X/%02X/%02X/%02X cursor=$%02X/%02X/%02X pointer=$%02X%02X." % [
		int(after_map_nmi_slot09.get("next_selected_task_slot", -1)),
		next_slot15_boundary.get("record", PackedByteArray()).hex_encode(),
		int(next_slot15_boundary.get("pc", -1)), int(next_slot15_boundary.get("a", -1)),
		int(next_slot15_boundary.get("x", -1)), int(next_slot15_boundary.get("y", -1)),
		int(next_slot15_boundary.get("sp", -1)), int(next_slot15_ram[0x05C7]) if next_slot15_ram.size() == 0x800 else -1,
		int(next_slot15_ram[0x05C8]) if next_slot15_ram.size() == 0x800 else -1,
		int(next_slot15_ram[0x05C9]) if next_slot15_ram.size() == 0x800 else -1,
		int(next_slot15_ram[0x0055]) if next_slot15_ram.size() == 0x800 else -1,
		int(next_slot15_ram[0x0054]) if next_slot15_ram.size() == 0x800 else -1])
	if int(after_map_nmi_slot09.get("next_selected_task_slot", -1)) != 0x15 \
			or next_slot15_boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xE9, 0x0B, 0x12]) \
			or next_slot15_ram.size() != 0x800 or int(next_slot15_ram[0x05C7]) != 0x60 \
			or int(next_slot15_ram[0x05C8]) != 3 or int(next_slot15_ram[0x05C9]) != 0x1D:
		return _fail("Post-NMI route did not source-select the expected second map-$42 worker boundary: %s" % str(after_map_nmi_slot09))
	var second_map_batch_route: Dictionary = runner.resume_selected_slot15_source_task()
	if not bool(second_map_batch_route.get("ok", false)) \
			or String(second_map_batch_route.get("status", "")) != "slot15_map42_batch_yielded" \
			or int(second_map_batch_route.get("queue_bytes_generated", -1)) != 0x60:
		return _fail("Live slot-$15 map-$42 continuation did not produce the second source-selected batch: %s" % str(second_map_batch_route))
	var second_map_batch: Dictionary = second_map_batch_route.get("map_batch_result", {})
	var second_queue: PackedByteArray = second_map_batch.get("queue_bytes", PackedByteArray())
	var second_ram: PackedByteArray = second_map_batch.get("updated_ram", PackedByteArray())
	if second_queue.size() != 0x60 or _sha256_hex(second_queue) != FCEUX_MAP42_SECOND_BATCH_SHA256 \
			or second_queue.slice(0, 7) != PackedByteArray([0x04, 0x0C, 0x20, 0, 0, 0, 0]) \
			or second_queue.slice(0x1C, 0x20) != PackedByteArray([0x01, 0xC3, 0x23, 0]) \
			or second_queue.slice(0x5C, 0x60) != PackedByteArray([0x01, 0xC5, 0x23, 0]) \
			or second_ram.size() != 0x800 or int(second_ram[0x05C7]) != 0x60 \
			or int(second_ram[0x05C8]) != 6 or int(second_ram[0x05C9]) != 0x1A \
			or int(second_map_batch_route.get("yielded_boundary", {}).get("bank_high", -1)) != 0x12:
		return _fail("Second map-$42 batch bytes, map placements, or source cursor differ from FCEUX snapshot 9: %s" % str(second_map_batch_route))
	print("MAP BATCH 2: source-selected worker mapped cells 3–5 at placements 3–5; 96 ROM-derived queue bytes match FCEUX snapshot 9 SHA-256 %s; cursor=$%02X/$%02X/$%02X." % [
		FCEUX_MAP42_SECOND_BATCH_SHA256, int(second_ram[0x05C7]),
		int(second_ram[0x05C8]), int(second_ram[0x05C9])])
	var second_map_nmi: Dictionary = runner.advance_on_external_nmi(10, 0x88)
	if not bool(second_map_nmi.get("ok", false)):
		return _fail("The caller-supplied NMI did not consume the second ROM-generated map batch: %s" % str(second_map_nmi))
	var second_map_bus_events: Array = second_map_nmi.get("ppu_bus_events", [])
	var second_ppu_data_write_count := 0
	for event_variant in second_map_bus_events:
		if event_variant is Dictionary and String(event_variant.get("operation", "")) == "write" \
				and int(event_variant.get("ppu_register", -1)) == 0x2007:
			second_ppu_data_write_count += 1
	if second_ppu_data_write_count != 51:
		return _fail("Second normal NMI did not consume the map-$42 batch as 51 `$2007` writes: %s" % str(second_map_nmi))
	var third_batch_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(third_batch_slot09.get("ok", false)) \
			or int(third_batch_slot09.get("next_selected_task_slot", -1)) != 0x15:
		return _fail("The second-batch NMI route did not return to a live slot-$15 map-worker boundary: %s" % str(third_batch_slot09))
	var third_batch_boundary: Dictionary = third_batch_slot09.get("next_selected_task_boundary", {})
	var third_batch_ram: PackedByteArray = third_batch_boundary.get("ram_image", PackedByteArray())
	if third_batch_boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xE9, 0x0B, 0x12]) \
			or third_batch_ram.size() != 0x800 or int(third_batch_ram[0x05C7]) != 0x60 \
			or int(third_batch_ram[0x05C8]) != 6 or int(third_batch_ram[0x05C9]) != 0x1A:
		return _fail("The third map-$42 continuation does not have its source-produced cursor: %s" % str(third_batch_slot09))
	var third_map_batch_route: Dictionary = runner.resume_selected_slot15_source_task()
	if not bool(third_map_batch_route.get("ok", false)) \
			or String(third_map_batch_route.get("status", "")) != "slot15_map42_batch_yielded" \
			or int(third_map_batch_route.get("queue_bytes_generated", -1)) != 0x60:
		return _fail("The live map-$42 worker did not process source-selected placements 6–8: %s" % str(third_map_batch_route))
	var third_map_batch: Dictionary = third_map_batch_route.get("map_batch_result", {})
	var third_queue: PackedByteArray = third_map_batch.get("queue_bytes", PackedByteArray())
	var third_ram: PackedByteArray = third_map_batch.get("updated_ram", PackedByteArray())
	if third_queue.size() != 0x60 or _sha256_hex(third_queue) != FCEUX_MAP42_THIRD_BATCH_SHA256 \
			or third_queue.slice(0, 7) != PackedByteArray([0x04, 0x18, 0x20, 0, 0, 0, 0]) \
			or third_queue.slice(0x40, 0x47) != PackedByteArray([0x04, 0x80, 0x20, 0x81, 0x81, 0x81, 0x81]) \
			or third_queue.slice(0x5C, 0x60) != PackedByteArray([0x01, 0xC8, 0x23, 0xAA]) \
			or third_ram.size() != 0x800 or int(third_ram[0x05C7]) != 0x60 \
			or int(third_ram[0x05C8]) != 9 or int(third_ram[0x05C9]) != 0x17:
		return _fail("Third map-$42 batch does not match its ROM-derived `$14,$14,$33` queue and cursors: %s" % str(third_map_batch_route))
	print("MAP BATCH 3: cells 6–8 are `$14,$14,$33`; ROM-derived `$33` uses tile `$81` and attribute `$AA`; the 96-byte queue matches FCEUX snapshot 10 SHA-256 %s." % FCEUX_MAP42_THIRD_BATCH_SHA256)
	var third_map_nmi: Dictionary = runner.advance_on_external_nmi(11, 0x88)
	if not bool(third_map_nmi.get("ok", false)):
		return _fail("The caller-supplied NMI did not consume the third ROM-generated map batch: %s" % str(third_map_nmi))
	var third_map_bus_events: Array = third_map_nmi.get("ppu_bus_events", [])
	var third_ppu_data_write_count := 0
	for event_variant in third_map_bus_events:
		if event_variant is Dictionary and String(event_variant.get("operation", "")) == "write" \
				and int(event_variant.get("ppu_register", -1)) == 0x2007:
			third_ppu_data_write_count += 1
	if third_ppu_data_write_count != 51:
		return _fail("Third normal NMI did not consume the map-$42 batch as 51 `$2007` writes: %s" % str(third_map_nmi))
	var fourth_batch_slot09: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(fourth_batch_slot09.get("ok", false)) \
			or int(fourth_batch_slot09.get("next_selected_task_slot", -1)) != 0x15:
		return _fail("Third-batch NMI route did not select slot-$15 for map placements 9–11: %s" % str(fourth_batch_slot09))
	var fourth_boundary: Dictionary = fourth_batch_slot09.get("next_selected_task_boundary", {})
	var fourth_ram: PackedByteArray = fourth_boundary.get("ram_image", PackedByteArray())
	if fourth_boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xE9, 0x0B, 0x12]) \
			or fourth_ram.size() != 0x800 or int(fourth_ram[0x05C7]) != 0x60 \
			or int(fourth_ram[0x05C8]) != 9 or int(fourth_ram[0x05C9]) != 0x17:
		return _fail("Fourth map-$42 worker boundary does not contain the source-produced cursor: %s" % str(fourth_batch_slot09))
	var fourth_batch_route: Dictionary = runner.resume_selected_slot15_source_task()
	if not bool(fourth_batch_route.get("ok", false)) \
			or String(fourth_batch_route.get("status", "")) != "slot15_map42_batch_yielded" \
			or int(fourth_batch_route.get("queue_bytes_generated", -1)) != 0x60:
		return _fail("Live map-$42 worker did not process source-selected placements 9–11: %s" % str(fourth_batch_route))
	var fourth_batch: Dictionary = fourth_batch_route.get("map_batch_result", {})
	var fourth_queue: PackedByteArray = fourth_batch.get("queue_bytes", PackedByteArray())
	var fourth_updated_ram: PackedByteArray = fourth_batch.get("updated_ram", PackedByteArray())
	if fourth_queue.size() != 0x60 or _sha256_hex(fourth_queue) != FCEUX_MAP42_FOURTH_BATCH_SHA256 \
			or fourth_queue.slice(0, 7) != PackedByteArray([0x04, 0x84, 0x20, 0x81, 0x81, 0x81, 0x81]) \
			or fourth_queue.slice(0x5C, 0x60) != PackedByteArray([0x01, 0xCB, 0x23, 0xAA]) \
			or fourth_updated_ram.size() != 0x800 \
			or int(fourth_updated_ram[0x05C7]) != 0x60 \
			or int(fourth_updated_ram[0x05C8]) != 0x0C \
			or int(fourth_updated_ram[0x05C9]) != 0x14:
		return _fail("Fourth map-$42 batch differs from the ROM-derived `$33,$33,$33` snapshot-11 queue: %s" % str(fourth_batch_route))
	print("MAP BATCH 4: cells 9–11 are `$33,$33,$33`; 96 ROM-derived queue bytes match FCEUX snapshot 11 SHA-256 %s." % FCEUX_MAP42_FOURTH_BATCH_SHA256)
	var fourth_map_nmi: Dictionary = runner.advance_on_external_nmi(12, 0x88)
	if not bool(fourth_map_nmi.get("ok", false)):
		return _fail("The caller-supplied NMI did not consume the fourth ROM-generated map batch: %s" % str(fourth_map_nmi))
	var fourth_ppu_data_write_count := 0
	for event_variant in fourth_map_nmi.get("ppu_bus_events", []):
		if event_variant is Dictionary and String(event_variant.get("operation", "")) == "write" \
				and int(event_variant.get("ppu_register", -1)) == 0x2007:
			fourth_ppu_data_write_count += 1
	if fourth_ppu_data_write_count != 51:
		return _fail("Fourth normal NMI did not consume the map-$42 batch as 51 `$2007` writes: %s" % str(fourth_map_nmi))
	if not _verify_remaining_map42_batches(runner):
		return false
	print("NORMAL NMI: all 11 map-$42 batches, including the final two-cell batch, match FCEUX queue hashes and emit their observed `$2007` counts. Full-field rendering, active actors, command-menu output, route audio, and physical cycle timing remain unresolved.")
	return true


func _verify_remaining_map42_batches(runner: Object) -> bool:
	for batch_number in FCEUX_MAP42_CONTINUATION_BATCHES.size():
		var expected: Dictionary = FCEUX_MAP42_CONTINUATION_BATCHES[batch_number]
		var start := int(expected["start"])
		var cell_count := mini(3, 0x20 - start)
		var slot09: Dictionary = runner.resume_selected_slot09_worker()
		if not bool(slot09.get("ok", false)) \
				or int(slot09.get("next_selected_task_slot", -1)) != 0x15:
			return _fail("Map-$42 continuation start %d did not follow the source slot-$09 route: %s" % [start, str(slot09)])
		var boundary: Dictionary = slot09.get("next_selected_task_boundary", {})
		var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
		if boundary.get("record", PackedByteArray()) != PackedByteArray([0x00, 0xE9, 0x0B, 0x12]) \
				or ram.size() != 0x800 or int(ram[0x05C7]) != 0x60 \
				or int(ram[0x05C8]) != start or int(ram[0x05C9]) != 0x20 - start:
			return _fail("Map-$42 continuation start %d is not the source-produced slot-$15 cursor: %s" % [start, str(boundary)])
		var route: Dictionary = runner.resume_selected_slot15_source_task()
		if not bool(route.get("ok", false)) \
				or String(route.get("status", "")) != "slot15_map42_batch_yielded" \
				or int(route.get("queue_bytes_generated", -1)) != cell_count * 0x20:
			return _fail("Live map-$42 worker failed at source placement %d: %s" % [start, str(route)])
		var result: Dictionary = route.get("map_batch_result", {})
		var queue: PackedByteArray = result.get("queue_bytes", PackedByteArray())
		var updated_ram: PackedByteArray = result.get("updated_ram", PackedByteArray())
		var yielded_boundary: Dictionary = route.get("yielded_boundary", {})
		var expected_saved_sp := 0xEA if start == 30 else 0xE9
		if queue.size() != cell_count * 0x20 or _sha256_hex(queue) != String(expected["sha256"]) \
				or int(result.get("batch_cell_count", -1)) != cell_count \
				or updated_ram.size() != 0x800 \
				or int(updated_ram[0x05C7]) != queue.size() \
				or int(updated_ram[0x05C8]) != start + cell_count \
				or int(updated_ram[0x05C9]) != 0x20 - start - cell_count \
				or yielded_boundary.get("record", PackedByteArray()) != PackedByteArray([0x01, expected_saved_sp, 0x0B, 0x12]):
			return _fail("Map-$42 batch %s at %d differs from its ROM-derived queue/cursor contract: %s" % [String(expected["ids"]), start, str(route)])
		var nmi_frame := 13 + batch_number
		var nmi: Dictionary = runner.advance_on_external_nmi(nmi_frame, 0x88)
		if not bool(nmi.get("ok", false)):
			return _fail("Caller-labeled NMI failed to consume map-$42 batch at %d: %s" % [start, str(nmi)])
		var data_write_count := 0
		for event_variant in nmi.get("ppu_bus_events", []):
			if event_variant is Dictionary and String(event_variant.get("operation", "")) == "write" \
					and int(event_variant.get("ppu_register", -1)) == 0x2007:
				data_write_count += 1
		if data_write_count != int(expected["writes"]):
			return _fail("Map-$42 batch at %d emitted %d `$2007` writes, expected %d." % [start, data_write_count, int(expected["writes"])])
		print("MAP BATCH %d: cells %d–%d are `$%s`; %d ROM-derived queue bytes match FCEUX SHA-256 %s; saved task SP=$%02X; NMI emits %d `$2007` writes." % [
			5 + batch_number, start, start + cell_count - 1, String(expected["ids"]).replace(",", ",$").replace("$EA", "EA").replace("$EB", "EB"),
			queue.size(), String(expected["sha256"]), expected_saved_sp, data_write_count])
	var post_map_route: Dictionary = runner.resume_selected_slot09_worker()
	if not bool(post_map_route.get("ok", false)):
		return _fail("The source slot-$09 route did not resume after all 32 map-$42 cells: %s" % str(post_map_route))
	var post_map_boundary: Dictionary = post_map_route.get("next_selected_task_boundary", {})
	var post_map_ram: PackedByteArray = post_map_boundary.get("ram_image", PackedByteArray())
	print("MAP COMPLETE: source slot-$09 continuation after the final NMI reached %s; selected slot=%s." % [
		String(post_map_route.get("status", "")), str(post_map_route.get("next_selected_task_slot", "none"))])
	print("NEXT SOURCE BOUNDARY: record=%s pc=$%04X c7/c8/c9=%s." % [
		(post_map_boundary.get("record", PackedByteArray()) as PackedByteArray).hex_encode(),
		int(post_map_boundary.get("pc", -1)),
		post_map_ram.slice(0x05C7, 0x05CA).hex_encode() if post_map_ram.size() == 0x800 else "unavailable"])
	var terminal_route: Dictionary = runner.resume_selected_slot15_source_task()
	if not bool(terminal_route.get("ok", false)):
		return _fail("The exhausted map worker did not finish through its ROM callback return: %s" % str(terminal_route))
	var terminal_result: Dictionary = terminal_route.get("terminal_return_result", {})
	var terminal_registers: Dictionary = terminal_result.get("registers", {})
	var terminal_ram: PackedByteArray = terminal_result.get("updated_ram", PackedByteArray())
	var finished_record: PackedByteArray = terminal_route.get("slot15_record_after_finish", PackedByteArray())
	if int(terminal_registers.get("pc", -1)) != 0xCAF7 \
			or int(terminal_registers.get("a", -1)) != 0x51 \
			or int(terminal_registers.get("x", -1)) != 0x40 \
			or int(terminal_registers.get("y", -1)) != 0x10 \
			or int(terminal_registers.get("p", -1)) != 0x20 \
			or terminal_ram.size() != 0x800 or int(terminal_ram[0x05CD]) != 0xA0 \
			or int(terminal_ram[0x05CE]) != 0x00 or int(terminal_ram[0x0516]) != 0x51 \
			or finished_record != PackedByteArray([0x00, 0x00, 0x0B, 0x12]):
		return _fail("The callback return/task-finish result differs from the FCEUX `$CAF7` event or cleared slot record: PC/A/X/Y/P=$%04X/$%02X/$%02X/$%02X/$%02X, $05CD/$05CE/$0516=%02X/%02X/%02X, slot15=%s." % [
			int(terminal_registers.get("pc", -1)), int(terminal_registers.get("a", -1)),
			int(terminal_registers.get("x", -1)), int(terminal_registers.get("y", -1)),
			int(terminal_registers.get("p", -1)), int(terminal_ram[0x05CD]) if terminal_ram.size() == 0x800 else -1,
			int(terminal_ram[0x05CE]) if terminal_ram.size() == 0x800 else -1,
			int(terminal_ram[0x0516]) if terminal_ram.size() == 0x800 else -1, finished_record.hex_encode()])
	print("MAP WORKER FINISH: ROM callback/dispatcher returned to `$CAF7`; A/X/Y/P=%02X/%02X/%02X/%02X matches FCEUX. `$05CD/$05CE=$A0/$00`; slot-$15 task is cleared." % [
		int(terminal_registers["a"]), int(terminal_registers["x"]),
		int(terminal_registers["y"]), int(terminal_registers["p"])])
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false


func _sha256_hex(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
