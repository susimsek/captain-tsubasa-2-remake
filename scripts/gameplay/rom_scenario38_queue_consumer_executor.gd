extends RefCounted
class_name RomScenario38QueueConsumerExecutor
## Decodes the queued PASS scenario-$38 bytes only from a scheduler-owned live
## slot-$09 bank-$10 `$803F` boundary. It emits a source receipt for `$8097`
## task creation; the scheduler adopter remains a separate integration step.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCHEDULER_SCRIPT_PATH := "res://scripts/gameplay/rom_gameplay_task_scheduler.gd"
const SLOT09_MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json"
const SLOT09_MANIFEST_SHA256 := "c706469923fd8a94410ea670502b5e471c8d98a68f523593a957153a917acaff"
const SCENARIO_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json"
const SCENARIO_MANIFEST_SHA256 := "8787974cbd268a91e36c5cc82783a348edf6132f21c2109a709d8b13a43a1162"
const SCENARIO_CONTINUATION_MANIFEST_PATH := "res://reference/rom_extract/gameplay/scenario_continuation/manifest.json"
const SCENARIO_CONTINUATION_MANIFEST_SHA256 := "26b581f2f7df914e599b73a95be96349c456b52e27f446795400bf09aebbb28b"
const TASK_CONTEXT_MANIFEST_PATH := "res://reference/rom_extract/gameplay/task_context/manifest.json"
const TASK_CONTEXT_MANIFEST_SHA256 := "5975db3b40e865f321930b5b70d905b002d8929d1e06bdda7d64586064d1bbe7"

const SCENARIO38_PATH := "res://reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin"
const SCENARIO38_SHA256 := "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76"
const SCENARIO38_POINTER := 0xB7C6
const SCENARIO38_POINTER_BYTES := [0xC6, 0xB7]
const SCENARIO38_POINTER_SHA256 := "06c441c4f9845c69b60a2967047bc5e2a878f296f2d6a975b3ed4b537a63aaac"
const EVENT_READER_PATH := "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/bank10_event_reader_803F_8096.bin"
const EVENT_READER_SHA256 := "880ad93e8e01567b7ab4d1dbd4a34e3fa0cd9b7751e14753c2bb9f1acf10d5d4"
const F7_HANDLER_PATH := "res://reference/rom_extract/gameplay/scenario_continuation/bank10_f7_handler_87f5_87ff.bin"
const F7_HANDLER_SHA256 := "42f86ca3e1cfb75bedfacafd80b7ec80e34b52582be56d1457a3ce5d4b51f2da"
const OPCODE_DISPATCH_PATH := "res://reference/rom_extract/gameplay/scenario_continuation/bank10_scenario_opcode_dispatch_80a9_80ce.bin"
const OPCODE_DISPATCH_SHA256 := "b22a45b7a2f1c6edc80a9fd896bac16792341761384fe9cb56e8525738465cb3"
const OPCODE_TABLE_PATH := "res://reference/rom_extract/gameplay/scenario_continuation/fixed_scenario_opcode_table_dispatch_CB99_CBAF.bin"
const OPCODE_TABLE_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"
const TASK_SETUP_PATH := "res://reference/rom_extract/gameplay/task_context/bank10_callback_task_setup_8097_80a8.bin"
const TASK_SETUP_SHA256 := "2d69d726177fe1eb737aab04622108e5860b03d4fd95a5182538c4bae7d982db"
const TASK_CREATE_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_task_create_C50F.bin"
const TASK_CREATE_SHA256 := "0ea4efd43ee0e2e3d1b9528351bc433e11207744845df22bfaa7bf0e335f08d0"
const TASK_SEED_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_task_seed_CAE7.bin"
const TASK_SEED_SHA256 := "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55"
const CALLBACK_ENTRY_PATH := "res://reference/rom_extract/gameplay/task_context/bank0b_callback_entry_8009.bin"
const CALLBACK_ENTRY_SHA256 := "5813c87d4f453cff4b6738bc2af1b54149488222527a69155072092c9f971fdb"

const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const SLOT09 := 0x09
const SLOT15 := 0x15
const RUNNING_PHASE := 2
const SCENARIO_RUNTIME_SCRIPT := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")

var error_message := ""
var _configured := false
var _source_hashes: Dictionary = {}
var _scenario38 := PackedByteArray()
var _pointer_bytes := PackedByteArray()
var _event_reader := PackedByteArray()
var _f7_handler := PackedByteArray()
var _opcode_dispatch := PackedByteArray()
var _opcode_table := PackedByteArray()
var _task_setup := PackedByteArray()
var _task_create := PackedByteArray()
var _task_seed := PackedByteArray()
var _callback_entry := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source_hashes.clear()
	for manifest_spec in [
		[SLOT09_MANIFEST_PATH, SLOT09_MANIFEST_SHA256],
		[SCENARIO_MANIFEST_PATH, SCENARIO_MANIFEST_SHA256],
		[SCENARIO_CONTINUATION_MANIFEST_PATH, SCENARIO_CONTINUATION_MANIFEST_SHA256],
		[TASK_CONTEXT_MANIFEST_PATH, TASK_CONTEXT_MANIFEST_SHA256],
	]:
		var manifest_path: String = manifest_spec[0]
		var expected_hash: String = manifest_spec[1]
		if not FileAccess.file_exists(manifest_path) \
				or FileAccess.get_sha256(manifest_path) != expected_hash:
			return _fail("ROM source manifest is missing or differs from its pinned SHA-256: " + manifest_path)
		_source_hashes[manifest_path] = expected_hash
	var scenario_manifest := _read_json(SCENARIO_MANIFEST_PATH)
	var slot09_manifest := _read_json(SLOT09_MANIFEST_PATH)
	var continuation_manifest := _read_json(SCENARIO_CONTINUATION_MANIFEST_PATH)
	var task_manifest := _read_json(TASK_CONTEXT_MANIFEST_PATH)
	if scenario_manifest.is_empty() or slot09_manifest.is_empty() \
			or continuation_manifest.is_empty() or task_manifest.is_empty():
		return _fail("A pinned source manifest is malformed.")
	if String(scenario_manifest.get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String(scenario_manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(slot09_manifest.get("schema", "")) != "ct2-slot09-eb8b-continuation-source-v1" \
			or String(slot09_manifest.get("rom", {}).get("sha256", "")) != ROM_SHA256 \
			or String(continuation_manifest.get("schema", "")) != "bank10-scenario-continuation-sources-v1" \
			or String(continuation_manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(task_manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("A ROM source manifest targets another ROM or schema.")
	if not _manifest_scenario38_matches(scenario_manifest):
		return _fail("Scenario-$38 pointer/stream provenance differs from the pinned source manifest.")
	_scenario38 = _read_span(SCENARIO38_PATH, SCENARIO38_SHA256, 7)
	_pointer_bytes = PackedByteArray(SCENARIO38_POINTER_BYTES)
	_event_reader = _read_manifest_span(slot09_manifest, EVENT_READER_PATH, "bank10_event_reader_803F_8096.bin",
		"0x803F", "0x02004F", 88, EVENT_READER_SHA256)
	_f7_handler = _read_manifest_span(continuation_manifest, F7_HANDLER_PATH, "bank10_f7_handler_87f5_87ff.bin",
		"0x87F5", "0x020805", 10, F7_HANDLER_SHA256)
	_opcode_dispatch = _read_manifest_path_span(continuation_manifest,
		"bank10_scenario_opcode_dispatch_80a9_80ce.bin", "0x80A9", "0x0200B9", 38,
		OPCODE_DISPATCH_SHA256, SCENARIO_CONTINUATION_MANIFEST_PATH.get_base_dir() + "/bank10_scenario_opcode_dispatch_80a9_80ce.bin")
	_opcode_table = _read_manifest_path_span(continuation_manifest,
		"fixed_scenario_opcode_table_dispatch_CB99_CBAF.bin", "0xCB99", "0x03CBA9", 23,
		OPCODE_TABLE_SHA256, SCENARIO_CONTINUATION_MANIFEST_PATH.get_base_dir() + "/fixed_scenario_opcode_table_dispatch_CB99_CBAF.bin")
	_task_setup = _read_task_span(task_manifest, "bank10_callback_task_setup_8097_80a8.bin",
		"0x8097", "0x0200A7", 18, TASK_SETUP_SHA256)
	_task_create = _read_task_span(task_manifest, "fixed_task_create_C50F.bin",
		"0xC50F", "0x03C51F", 3, TASK_CREATE_SHA256)
	_task_seed = _read_task_span(task_manifest, "fixed_task_seed_CAE7.bin",
		"0xCAE7", "0x03CAF7", 16, TASK_SEED_SHA256)
	_callback_entry = _read_task_span(task_manifest, "bank0b_callback_entry_8009.bin",
		"0x8009", "0x016019", 3, CALLBACK_ENTRY_SHA256)
	if _scenario38.size() != 7 or _pointer_bytes != PackedByteArray([0xC6, 0xB7]) \
			or _event_reader.size() != 88 or _f7_handler.size() != 10 \
			or _opcode_dispatch.size() != 38 or _opcode_table.size() != 23 \
			or _task_setup.size() != 18 or _task_create.size() != 3 \
			or _task_seed.size() != 16 or _callback_entry.size() != 3:
		return _fail(error_message if not error_message.is_empty() else "A ROM source byte span failed its pinned integrity check.")
	if _scenario38 != PackedByteArray([0xF7, 0x17, 0x01, 0x34, 0x00, 0xF0, 0xFB]) \
			or _event_reader.slice(0, 16) != PackedByteArray([0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]) \
			or _f7_handler != PackedByteArray([0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60]) \
			or _task_setup != PackedByteArray([0xA2, 0x15, 0xA9, 0xF0, 0x95, 0x01, 0xA9, 0x0B, 0x95,
			0x02, 0xA9, 0x80, 0xA0, 0x08, 0x20, 0x0F, 0xC5, 0x60]) \
			or _task_create != PackedByteArray([0x4C, 0xE7, 0xCA]) \
			or _task_seed != PackedByteArray([0x48, 0x98, 0xB4, 0x01, 0x99, 0x01, 0x01, 0x68,
			0x99, 0x02, 0x01, 0xA9, 0xFF, 0x95, 0x00, 0x60]) \
			or _callback_entry != PackedByteArray([0x4C, 0x4C, 0x81]):
		return _fail("A verified scenario-$38 reader, task seed, or callback entry span changed bytes.")
	if _sha256(_pointer_bytes) != SCENARIO38_POINTER_SHA256:
		return _fail("Scenario-$38 root pointer bytes do not match their manifest hash.")
	_source_hashes[SCENARIO38_PATH] = SCENARIO38_SHA256
	_source_hashes[EVENT_READER_PATH] = EVENT_READER_SHA256
	_source_hashes[F7_HANDLER_PATH] = F7_HANDLER_SHA256
	_source_hashes[OPCODE_DISPATCH_PATH] = OPCODE_DISPATCH_SHA256
	_source_hashes[OPCODE_TABLE_PATH] = OPCODE_TABLE_SHA256
	_source_hashes[TASK_SETUP_PATH] = TASK_SETUP_SHA256
	_source_hashes[TASK_CREATE_PATH] = TASK_CREATE_SHA256
	_source_hashes[TASK_SEED_PATH] = TASK_SEED_SHA256
	_source_hashes[CALLBACK_ENTRY_PATH] = CALLBACK_ENTRY_SHA256
	_configured = true
	return true


## Accepts a RAM image only when it exactly matches the supplied real scheduler's
## live slot-$09 boundary. It does not accept trace dumps, synthetic endpoints,
## caller-injected memory, or a boundary with a different task/source context.
func execute_from_live_slot09_boundary(boundary: Dictionary, scheduler: Object) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _refused("source_integrity_failure", error_message)
	var validation := _validate_live_boundary(boundary, scheduler)
	if not bool(validation.get("ok", false)):
		return _refused("source_state_required", String(validation.get("error", "Invalid live scenario-$38 boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var scenario_runtime: RefCounted = SCENARIO_RUNTIME_SCRIPT.new()
	var started: Dictionary = scenario_runtime.call("begin_from_live_scenario_pointer",
		0x38, int(ram[0x005D]) | (int(ram[0x005E]) << 8))
	if not bool(started.get("ok", false)) or int(started.get("source_pointer_cpu", -1)) != SCENARIO38_POINTER \
			or int(started.get("source_byte_index", -1)) != int(ram[0x003A]) \
			or String(started.get("source_stream_sha256", "")) != SCENARIO38_SHA256:
		return _refused("scenario_source_state_required", "Bank-$10 scenario parser did not accept the live selector/pointer/cursor.")
	var f7_result: Dictionary = scenario_runtime.call("advance_one")
	var f7_writes: Dictionary = f7_result.get("ram_writes", {})
	if not bool(f7_result.get("ok", false)) or String(f7_result.get("status", "")) != "decoded_byte_operation_applied" \
			or int(f7_result.get("opcode", -1)) != 0xF7 or int(f7_result.get("operand", -1)) != 0x17 \
			or int(f7_result.get("source_byte_index_after", -1)) != 2 or f7_writes != {"$052B": 0x17}:
		return _refused("scenario_source_integrity_failure", "Scenario-$38 `$F7 $17` no longer resolves to the verified `$87F5` byte read.")
	var record_result: Dictionary = scenario_runtime.call("advance_one")
	var contract: Dictionary = record_result.get("seed_contract_fields", {})
	var assignments: Dictionary = record_result.get("ram_state", {})
	if not bool(record_result.get("ok", false)) \
			or String(record_result.get("status", "")) != "callback_task_seed_requested" \
			or int(record_result.get("source_byte_offset", -1)) != 2 \
			or PackedByteArray(contract.get("source_record_bytes", PackedByteArray())) != PackedByteArray([0x01, 0x34, 0x00, 0xF0]) \
			or int(contract.get("event_selector_ram_0524", -1)) != 0x34 \
			or int(contract.get("wait_value_ram_0523", -1)) != 0x01 \
			or int(contract.get("actor_selector_ram_0528", -1)) != 0x00 \
			or int(contract.get("actor_parameter_ram_0529", -1)) != 0xFF \
			or int(contract.get("task_slot_base", -1)) != SLOT15 \
			or int(contract.get("callback_entry_cpu_address", -1)) != 0x814C \
			or assignments != {"$0523": 0x01, "$0524": 0x34, "$0528": 0x00, "$0529": 0xFF, "$052B": 0x17}:
		return _refused("scenario_source_integrity_failure", "Scenario-$38 event record does not produce the pinned callback-$34 seed contract.")
	var source_writes: Array[Dictionary] = []
	_append_write(source_writes, 0x8041, 0x003A, 0x01)
	_append_write(source_writes, 0x87F7, 0x003A, 0x02)
	_append_write(source_writes, 0x87FB, 0x052B, 0x17)
	_append_write(source_writes, 0x8041, 0x003A, 0x03)
	_append_write(source_writes, 0x804F, 0x0523, 0x01)
	_append_write(source_writes, 0x8059, 0x0516, 0x41)
	_append_write(source_writes, 0x805E, 0x003A, 0x04)
	_append_write(source_writes, 0x8069, 0x0524, 0x34)
	_append_write(source_writes, 0x806E, 0x003A, 0x05)
	_append_write(source_writes, 0x8079, 0x0528, 0x00)
	_append_write(source_writes, 0x807E, 0x003A, 0x06)
	_append_write(source_writes, 0x8089, 0x0529, 0xFF)
	_append_write(source_writes, 0x8091, 0x005D, 0xCC)
	_append_write(source_writes, 0x809B, 0x0016, 0xF0)
	_append_write(source_writes, 0x809F, 0x0017, 0x0B)
	_append_write(source_writes, 0xCAEB, 0x01F1, 0x08)
	_append_write(source_writes, 0xCAEF, 0x01F2, 0x80)
	_append_write(source_writes, 0xCAF4, 0x0015, 0xFF)
	for write_variant: Variant in source_writes:
		var write: Dictionary = write_variant
		ram[int(write["address"])] = int(write["value"])
		if int(write["address"]) >= 0x0100 and int(write["address"]) < 0x0200:
			stack[int(write["address"]) & 0xFF] = int(write["value"])
	var return_low := int(_task_setup[13])
	var return_high := int(_task_setup[11])
	var task_record := PackedByteArray([0xFF, 0xF0, 0x0B, int(ram[0x0018])])
	var task_seed: Dictionary = contract.duplicate(true)
	task_seed["task_record"] = task_record.duplicate()
	task_seed["source_return_word"] = (return_high << 8) | return_low
	task_seed["initial_rts_pc"] = ((return_high << 8) | return_low) + 1
	task_seed["callback_reader_pc"] = int(_callback_entry[1]) | (int(_callback_entry[2]) << 8)
	return {
		"ok": true,
		"status": "pass_scenario38_slot15_seed_receipt_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest_hashes": _source_hashes.duplicate(true),
		"source_boundary": {
			"slot_base": SLOT09, "active_task_slot": SLOT09, "phase": RUNNING_PHASE,
			"pc": 0x803F, "sp": int(boundary["sp"]), "bank_low": 0x10, "bank_high": 0x11,
			"executing_cpu_bank": 0x10, "scenario_id": 0x38,
			"scenario_root_pointer": SCENARIO38_POINTER, "scenario_cursor": 0,
			"caller_return_pc": 0xEC74,
		},
		"source_hashes": {
			"scenario38_stream": SCENARIO38_SHA256,
			"scenario38_pointer": SCENARIO38_POINTER_SHA256,
			"bank10_event_reader_803f_8096": EVENT_READER_SHA256,
			"bank10_f7_handler_87f5_87ff": F7_HANDLER_SHA256,
			"bank10_opcode_dispatch_80a9_80ce": OPCODE_DISPATCH_SHA256,
			"fixed_opcode_table_cb99_cbaf": OPCODE_TABLE_SHA256,
			"callback_task_setup_8097_80a8": TASK_SETUP_SHA256,
			"fixed_task_create_c50f": TASK_CREATE_SHA256,
			"fixed_task_seed_cae7": TASK_SEED_SHA256,
			"callback_entry_8009": CALLBACK_ENTRY_SHA256,
		},
		"scenario_token_receipts": [
			{"kind": "opcode", "pc": 0x803F, "source_pointer": SCENARIO38_POINTER,
				"source_bytes": PackedByteArray([0xF7, 0x17]), "resolved_handler_pc": 0x87F5,
				"ram_writes": f7_writes.duplicate(true),
				"handler_source_bytes": _f7_handler.duplicate()},
			{"kind": "event_record", "pc": 0x804F, "source_pointer": SCENARIO38_POINTER + 2,
				"source_bytes": PackedByteArray([0x01, 0x34, 0x00, 0xF0]),
				"ram_assignments": assignments.duplicate(true),
				"transformer": {"source_pc": 0x89A7, "target_pc": 0x89B1,
					"target_bytes": PackedByteArray([0xA9, 0xFF, 0x60])}},
		],
		"source_reads": [
			{"source_pc": 0x8043, "address": 0xB7C6, "value": 0xF7},
			{"source_pc": 0x87F9, "address": 0xB7C7, "value": 0x17},
			{"source_pc": 0x8043, "address": 0xB7C8, "value": 0x01},
			{"source_pc": 0x8060, "address": 0xB7C9, "value": 0x34},
			{"source_pc": 0x8070, "address": 0xB7CA, "value": 0x00},
			{"source_pc": 0x8080, "address": 0xB7CB, "value": 0xF0},
		],
		"source_writes": source_writes,
		"task_seed_stack_page_writes": [
			{"source_pc": 0xCAEB, "address": 0x01F1, "value": 0x08},
			{"source_pc": 0xCAEF, "address": 0x01F2, "value": 0x80},
		],
		"slot15_seed_request": task_seed,
		"next_source_pc": 0x80A8,
		"effect_receipt_only": true,
		"complete_6502_call_stack_mutations_modeled": false,
		"slot15_scheduler_adoption_performed": false,
		"callback_dispatched": false,
		"callback_executed": false,
		"runtime_rom_dependency": false,
		"trace_state_used": false,
		"memory_image_returned": false,
		"limitation": "The route must adopt this receipt into scheduler-owned RAM/task state before dispatching slot $15.",
	}


func _validate_live_boundary(boundary: Dictionary, scheduler: Object) -> Dictionary:
	for forbidden in ["synthetic_endpoint", "endpoint_injected", "fceux_ram", "captured_ram",
			"emulator_snapshot", "trace_ram", "source_ram_image"]:
		if boundary.has(forbidden):
			return {"ok": false, "error": "Boundary explicitly claims synthetic or emulator memory: " + forbidden}
	if scheduler == null or not scheduler.has_method("get_task_boundary_snapshot") \
			or not scheduler.has_method("get_status"):
		return {"ok": false, "error": "A live ROM task scheduler object is required; a boundary dictionary alone is not accepted."}
	var scheduler_script_variant: Variant = scheduler.get_script()
	if not scheduler_script_variant is Script \
			or String((scheduler_script_variant as Script).resource_path) != SCHEDULER_SCRIPT_PATH:
		return {"ok": false, "error": "Boundary producer is not the project's ROM gameplay scheduler script."}
	var status_variant: Variant = scheduler.call("get_status")
	var live_variant: Variant = scheduler.call("get_task_boundary_snapshot", SLOT09)
	if not status_variant is Dictionary or not live_variant is Dictionary:
		return {"ok": false, "error": "Scheduler did not provide a live slot-$09 snapshot."}
	var status: Dictionary = status_variant
	var live: Dictionary = live_variant
	if not bool(status.get("configured", false)) or not bool(status.get("initialized", false)) \
			or String(status.get("rom_sha256", "")) != ROM_SHA256 \
			or int(status.get("active_task_slot", -1)) != SLOT09:
		return {"ok": false, "error": "Scheduler is not live on the pinned ROM's slot-$09 source task."}
	for key in ["rom_sha256", "slot_base", "phase", "pc", "sp", "a", "x", "y", "p",
			"p_known_mask", "bank_low", "bank_high", "record", "ram_image", "stack_page",
			"active_task_slot"]:
		if not boundary.has(key) or not live.has(key) or boundary[key] != live[key]:
			return {"ok": false, "error": "Caller boundary differs from scheduler-owned live field: " + key}
	var ram_variant: Variant = live.get("ram_image", PackedByteArray())
	var stack_variant: Variant = live.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE:
		return {"ok": false, "error": "Scheduler snapshot has malformed CPU RAM or stack memory."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var sp := int(live.get("sp", -1))
	if int(live.get("slot_base", -1)) != SLOT09 or int(live.get("active_task_slot", -1)) != SLOT09 \
			or int(live.get("phase", -1)) != RUNNING_PHASE or int(live.get("pc", -1)) != 0x803F \
			or int(live.get("bank_low", -1)) != 0x10 or int(live.get("bank_high", -1)) != 0x11 \
			or sp < 0 or sp > 0xFF or int(ram[0x0000]) != SLOT09 \
			or int(ram[0x0024]) != 0x10 or int(ram[0x0025]) != 0x11 \
			or int(ram[0x0516]) != 0x01 or int(ram[0x0518]) != 0x38 \
			or int(ram[0x0519]) != 0 or int(ram[0x0539]) != 0 \
			or int(ram[0x003A]) != 0 \
			or (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) != SCENARIO38_POINTER \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(stack[(sp + 1) & 0xFF]) != 0x73 or int(stack[(sp + 2) & 0xFF]) != 0xEC \
			or ram.slice(SLOT15, SLOT15 + 4) != PackedByteArray([0, 0, 0, 0]):
		return {"ok": false, "error": "Live slot-$09 state does not prove the unconsumed scenario-$38 `$803F` caller boundary."}
	var record_variant: Variant = live.get("record", PackedByteArray())
	if not record_variant is PackedByteArray \
			or record_variant != ram.slice(SLOT09, SLOT09 + 4):
		return {"ok": false, "error": "Slot-$09 task record does not match its scheduler-owned RAM mirror."}
	return {"ok": true}


func _manifest_scenario38_matches(manifest: Dictionary) -> bool:
	for row_variant in manifest.get("scenario_streams", []):
		if not row_variant is Dictionary or String(row_variant.get("scenario_id", "")) != "$38":
			continue
		var row: Dictionary = row_variant
		var pointer_entry: Dictionary = row.get("start_pointer_entry", {})
		return String(row.get("path", "")) == "reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin" \
				and String(row.get("start_cpu_address", "")) == "0xB7C6" \
				and String(row.get("file_offset", "")) == "0x0237D6" \
				and int(row.get("length_bytes", -1)) == 7 \
				and String(row.get("sha256", "")) == SCENARIO38_SHA256 \
				and String(pointer_entry.get("table_cpu_address", "")) == "0x89BF" \
				and String(pointer_entry.get("table_file_offset", "")) == "0x020A3F" \
				and String(pointer_entry.get("bytes_hex", "")).replace(" ", "").to_lower() == "c6b7" \
				and String(pointer_entry.get("sha256", "")) == SCENARIO38_POINTER_SHA256
	return false


func _read_manifest_span(manifest: Dictionary, absolute_path: String, filename: String,
		cpu_start: String, file_offset: String, length: int, digest: String) -> PackedByteArray:
	return _read_manifest_path_span(manifest, filename, cpu_start, file_offset, length,
		digest, absolute_path)


func _read_manifest_path_span(manifest: Dictionary, filename: String, cpu_start: String,
		file_offset: String, length: int, digest: String, absolute_path: String) -> PackedByteArray:
	for row_variant in manifest.get("entries", manifest.get("spans", [])):
		if not row_variant is Dictionary:
			continue
		var row: Dictionary = row_variant
		if String(row.get("file", row.get("path", ""))).get_file() != filename:
			continue
		var row_cpu := String(row.get("cpu_start", row.get("cpu_address", "")))
		var row_offset := String(row.get("file_offset", ""))
		var row_length := int(row.get("length", row.get("length_bytes", row.get("size_bytes", -1))))
		if row_cpu.to_lower() != cpu_start.to_lower() or row_offset.to_lower() != file_offset.to_lower() \
				or row_length != length or String(row.get("sha256", "")) != digest:
			error_message = "Manifest source metadata changed for " + filename
			return PackedByteArray()
		var bytes := FileAccess.get_file_as_bytes(absolute_path)
		if bytes.size() != length or _sha256(bytes) != digest:
			error_message = "ROM-derived source bytes failed size/hash validation: " + absolute_path
			return PackedByteArray()
		return bytes
	error_message = "ROM source manifest omits " + filename
	return PackedByteArray()


func _read_task_span(manifest: Dictionary, filename: String, cpu_address: String,
		file_offset: String, length: int, digest: String) -> PackedByteArray:
	return _read_manifest_path_span(manifest, filename, cpu_address, file_offset,
		length, digest, TASK_CONTEXT_MANIFEST_PATH.get_base_dir() + "/" + filename)


func _read_span(path: String, digest: String, length: int) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		error_message = "ROM-derived source file is missing: " + path
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() != length or _sha256(bytes) != digest:
		error_message = "ROM-derived source file failed size/hash validation: " + path
		return PackedByteArray()
	return bytes


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _append_write(writes: Array[Dictionary], pc: int, address: int, value: int) -> void:
	writes.append({"source_pc": pc, "address": address, "value": value})


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(status: String, message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": status, "error": message,
		"rom_sha256": ROM_SHA256, "trace_state_used": false,
		"memory_image_returned": false, "scheduler_state_changed": false}
