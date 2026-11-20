extends SceneTree
## Verifies the hash-checked PASS scenario-$38 stream through its callback seed
## request and root terminator. It does not run the callback, map worker, field
## movement, PPU/APU events, or source timing.

const RUNTIME_SCRIPT := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")
const EXPECTED_STREAM_SHA256 := "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76"
const EXPECTED_RECORD_HEX := "013400f0"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runtime = RUNTIME_SCRIPT.new()
	var started: Dictionary = runtime.begin_from_live_scenario_pointer(0x38, 0xB7C6)
	if not bool(started.get("ok", false)):
		_fail("Scenario-$38 source start failed: " + String(started.get("error", "unknown")))
		return
	if int(started.get("scenario_id", -1)) != 0x38 \
			or int(started.get("source_pointer_cpu", -1)) != 0xB7C6 \
			or int(started.get("source_root_pointer_cpu", -1)) != 0xB7C6 \
			or int(started.get("source_byte_index", -1)) != 0 \
			or String(started.get("source_stream_sha256", "")) != EXPECTED_STREAM_SHA256 \
			or int(started.get("token_count", -1)) != 3 \
			or bool(started.get("emulator_frame_input_used", true)) \
			or bool(started.get("capture_ram_input_used", true)):
		_fail("Scenario-$38 root pointer, source hash, token count, or source independence differs: " + str(started))
		return

	var f7_result: Dictionary = runtime.advance_one()
	var f7_writes: Dictionary = f7_result.get("ram_writes", {})
	if not bool(f7_result.get("ok", false)) \
			or String(f7_result.get("status", "")) != "decoded_byte_operation_applied" \
			or int(f7_result.get("opcode", -1)) != 0xF7 \
			or int(f7_result.get("operand", -1)) != 0x17 \
			or int(f7_result.get("source_byte_offset", -1)) != 0 \
			or f7_writes != {"$052B": 0x17} \
			or int(f7_result.get("source_byte_index_after", -1)) != 2:
		_fail("ROM `$87F5` `$F7 $17` operation differs: " + str(f7_result))
		return

	var event_result: Dictionary = runtime.advance_one()
	var contract: Dictionary = event_result.get("seed_contract_fields", {})
	var ram_state: Dictionary = event_result.get("ram_state", {})
	if not bool(event_result.get("ok", false)) \
			or String(event_result.get("status", "")) != "callback_task_seed_requested" \
			or int(event_result.get("source_byte_offset", -1)) != 2 \
			or event_result.get("seed_contract", null) == null \
			or PackedByteArray(contract.get("source_record_bytes", PackedByteArray())).hex_encode() != EXPECTED_RECORD_HEX \
			or int(contract.get("scenario_id", -1)) != 0x38 \
			or int(contract.get("source_record_cpu_address", -1)) != 0xB7C8 \
			or int(contract.get("source_record_file_offset", -1)) != 0x0237D8 \
			or int(contract.get("event_selector_ram_0524", -1)) != 0x34 \
			or int(contract.get("wait_value_ram_0523", -1)) != 0x01 \
			or int(contract.get("actor_selector_ram_0528", -1)) != 0x00 \
			or int(contract.get("actor_parameter_ram_0529", -1)) != 0xFF \
			or int(ram_state.get("$052B", -1)) != 0x17 \
			or int(ram_state.get("$0524", -1)) != 0x34 \
			or bool(event_result.get("scheduler_dispatched", true)) \
			or bool(event_result.get("callback_executed", true)) \
			or bool(event_result.get("actor_worker_started", true)):
		_fail("Scenario-$38 callback seed contract differs: " + str(event_result))
		return

	var terminal: Dictionary = runtime.advance_one()
	var state: Dictionary = runtime.get_state()
	if not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "root_scenario_terminated" \
			or int(terminal.get("source_byte_offset", -1)) != 6 \
			or int(terminal.get("source_byte_index_after", -1)) != 7 \
			or int(terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF \
			or not bool(state.get("terminated", false)) \
			or bool(state.get("scheduler_dispatched", true)) \
			or bool(state.get("callback_executed", true)):
		_fail("Scenario-$38 root `$FB` termination differs: " + str(terminal))
		return

	var wrong_pointer_runtime = RUNTIME_SCRIPT.new()
	var wrong_pointer: Dictionary = wrong_pointer_runtime.begin_from_live_scenario_pointer(0x38, 0xB7C7)
	if bool(wrong_pointer.get("ok", true)) \
			or String(wrong_pointer.get("status", "")) != "source_state_required":
		_fail("Scenario-$38 accepted a non-root live pointer: " + str(wrong_pointer))
		return

	print("PASS: scenario-$38 root pointer and seven-byte stream validate against ROM manifest/hash.")
	print("PASS: `$F7 $17` writes `$052B`; record `$01 $34 $00 $F0` requests callback `$34` with a ROM-derived seed contract.")
	print("PASS: root `$FB` terminates at `$80CF`; invalid pointer is rejected and no callback/scheduler runs.")
	print("LIMIT: the live PASS input route, callback/map worker, receiver transfer, field animation, PPU/APU output, and timing are not covered.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
