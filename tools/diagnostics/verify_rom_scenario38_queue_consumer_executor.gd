extends SceneTree
## Verifies ROM provenance and the scenario-$38 reader receipt contract. The
## current route does not produce a scheduler-owned live `$803F` slot-$09
## boundary, so this diagnostic intentionally does not claim a positive route
## execution or slot-$15 scheduler adoption.

const EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_scenario38_queue_consumer_executor.gd")
const RUNTIME_SCRIPT := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")
const EXPECTED_STREAM_SHA256 := "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor: RefCounted = EXECUTOR_SCRIPT.new()
	if not executor.call("configure_from_project_sources"):
		_fail("Scenario-$38 executor sources failed integrity validation: " + String(executor.get("error_message")))
		return

	var runtime: RefCounted = RUNTIME_SCRIPT.new()
	var started: Dictionary = runtime.call("begin_from_live_scenario_pointer", 0x38, 0xB7C6)
	if not bool(started.get("ok", false)) \
			or int(started.get("scenario_id", -1)) != 0x38 \
			or int(started.get("source_pointer_cpu", -1)) != 0xB7C6 \
			or String(started.get("source_stream_sha256", "")) != EXPECTED_STREAM_SHA256 \
			or bool(started.get("capture_ram_input_used", true)) \
			or bool(started.get("emulator_frame_input_used", true)):
		_fail("Scenario-$38 source parser did not validate the pinned stream independently: " + str(started))
		return
	var opcode: Dictionary = runtime.call("advance_one")
	var opcode_writes: Dictionary = opcode.get("ram_writes", {})
	if not bool(opcode.get("ok", false)) \
			or String(opcode.get("status", "")) != "decoded_byte_operation_applied" \
			or int(opcode.get("opcode", -1)) != 0xF7 \
			or int(opcode.get("operand", -1)) != 0x17 \
			or int(opcode.get("source_byte_index_after", -1)) != 2 \
			or opcode_writes != {"$052B": 0x17}:
		_fail("Scenario-$38 `$F7 $17` receipt differs from the decoded `$87F5` handler: " + str(opcode))
		return
	var record: Dictionary = runtime.call("advance_one")
	var contract: Dictionary = record.get("seed_contract_fields", {})
	if not bool(record.get("ok", false)) \
			or String(record.get("status", "")) != "callback_task_seed_requested" \
			or PackedByteArray(contract.get("source_record_bytes", PackedByteArray())) != PackedByteArray([0x01, 0x34, 0x00, 0xF0]) \
			or int(contract.get("source_record_cpu_address", -1)) != 0xB7C8 \
			or int(contract.get("wait_value_ram_0523", -1)) != 0x01 \
			or int(contract.get("event_selector_ram_0524", -1)) != 0x34 \
			or int(contract.get("actor_selector_ram_0528", -1)) != 0x00 \
			or int(contract.get("actor_parameter_ram_0529", -1)) != 0xFF \
			or int(contract.get("task_slot_base", -1)) != 0x15 \
			or int(contract.get("callback_entry_cpu_address", -1)) != 0x814C:
		_fail("Scenario-$38 event record no longer resolves its source callback seed contract: " + str(record))
		return

	var synthetic: Dictionary = {"pc": 0x803F, "synthetic_endpoint": true,
		"ram_image": PackedByteArray(), "stack_page": PackedByteArray()}
	var synthetic_result: Dictionary = executor.call("execute_from_live_slot09_boundary", synthetic, null)
	if bool(synthetic_result.get("ok", true)) \
			or String(synthetic_result.get("status", "")) != "source_state_required" \
			or not String(synthetic_result.get("error", "")).contains("synthetic") \
			or bool(synthetic_result.get("scheduler_state_changed", true)):
		_fail("Executor accepted or mutated state from a synthetic endpoint claim: " + str(synthetic_result))
		return
	var standalone_ram: Dictionary = {"pc": 0x803F, "ram_image": PackedByteArray(),
		"stack_page": PackedByteArray(), "rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"}
	var standalone_result: Dictionary = executor.call("execute_from_live_slot09_boundary", standalone_ram, null)
	if bool(standalone_result.get("ok", true)) \
			or not String(standalone_result.get("error", "")).contains("live ROM task scheduler") \
			or bool(standalone_result.get("memory_image_returned", true)):
		_fail("Executor accepted a caller-supplied RAM image without a scheduler-owned boundary: " + str(standalone_result))
		return

	print("PASS: pinned scenario-$38, bank-$10 reader/opcode, and slot-$15 seed sources validate against the supplied ROM manifest/hash.")
	print("PASS: `$F7 $17` resolves `$052B=$17`; record `$01 $34 $00 $F0` resolves wait `$01`, callback `$34`, and slot-$15/$8097 seed data.")
	print("PASS: the consumer rejects synthetic endpoints and standalone RAM images; it returns no memory snapshot and changes no scheduler state.")
	print("LIMIT: the route currently has no source-produced live slot-$09 `$803F` boundary. This verifier makes no live route, callback dispatch, or slot-$15 adoption claim.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
