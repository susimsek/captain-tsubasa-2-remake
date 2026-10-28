extends SceneTree

const RUNTIME_SCRIPT := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")
const SOURCE_MANIFEST := "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var wrong_caller := RUNTIME_SCRIPT.new()
	var rejected: Dictionary = wrong_caller.begin_from_source_callsite(0xDAD9)
	_check(not bool(rejected.get("ok", true))
		and str(rejected.get("status", "")) == "unsupported_caller",
		"unsupported caller PCs are refused instead of seeding an assumed scenario")

	var runtime := RUNTIME_SCRIPT.new()
	var started: Dictionary = runtime.begin_from_source_callsite(0xDAD8)
	_check(bool(started.get("ok", false)),
		"hash-checked kickoff caller and scenario source bundle initialize")
	_check(int(started.get("scenario_id", -1)) == 0x35
		and int(started.get("source_pointer_cpu", -1)) == 0xB7CD
		and int(started.get("source_byte_index", -1)) == 0
		and int(started.get("continuation_depth", -1)) == 0,
		"scenario ID/pointer/index/depth derive from packaged caller, pointer, reader, and fixed-start bytes")
	_check(not bool(started.get("emulator_frame_input_used", true))
		and not bool(started.get("capture_ram_input_used", true)),
		"source-root initialization uses no emulator frame or capture RAM inputs")

	var f9: Dictionary = runtime.advance_one()
	_check(bool(f9.get("ok", false))
		and int(f9.get("opcode", -1)) == 0xF9
		and int(f9.get("source_byte_offset", -1)) == 0
		and int(f9.get("source_byte_index_after", -1)) == 3,
		"cursor consumes the source $F9 at byte zero and advances to byte three")
	var f9_writes: Dictionary = f9.get("ram_writes", {})
	_check(int(f9_writes.get("$0530", -1)) == 0xEB
		and int(f9_writes.get("$0531", -1)) == 0x44,
		"$F9 applies the ROM-decoded little-endian write EB/44 to $0530/$0531")

	var seed_result: Dictionary = runtime.advance_one()
	_check(bool(seed_result.get("ok", false))
		and str(seed_result.get("status", "")) == "callback_task_seed_requested"
		and int(seed_result.get("source_byte_offset", -1)) == 3
		and int(seed_result.get("source_byte_index_after", -1)) == 7,
		"source record at byte three advances cursor and emits the callback-task seed request")
	var contract_variant: Variant = seed_result.get("seed_contract")
	_check(contract_variant is RefCounted and contract_variant.has_method("to_dictionary"),
		"callback seed output is a typed contract instance")
	var contract: Dictionary = seed_result.get("seed_contract_fields", {})
	_check(int(contract.get("source_record_cpu_address", -1)) == 0xB7D0
		and int(contract.get("source_record_file_offset", -1)) == 0x0237E0
		and contract.get("source_record_bytes", PackedByteArray()) == PackedByteArray([0x02, 0x3A, 0x8F, 0x73]),
		"typed seed contract points to the exact ROM event record 02 3A 8F 73")
	_check(int(contract.get("event_selector_ram_0524", -1)) == 0x3A
		and int(contract.get("wait_value_ram_0523", -1)) == 0x02
		and int(contract.get("actor_selector_ram_0528", -1)) == 0x8F
		and int(contract.get("actor_parameter_ram_0529", -1)) == 0x73,
		"event, wait, actor selector, and parameter remain distinct decoded fields")
	_check(int(contract.get("setup_cpu_address", -1)) == 0x8097
		and int(contract.get("task_create_cpu_address", -1)) == 0xC50F
		and int(contract.get("task_seed_cpu_address", -1)) == 0xCAE7
		and int(contract.get("task_slot_base", -1)) == 0x15
		and int(contract.get("saved_stack_pointer", -1)) == 0xF0
		and int(contract.get("bank_base", -1)) == 0x0B
		and contract.get("stack_page_write_offsets", PackedByteArray()) == PackedByteArray([0xF1, 0xF2])
		and contract.get("seeded_rts_return_bytes", PackedByteArray()) == PackedByteArray([0x08, 0x80])
		and int(contract.get("task_ready_marker", -1)) == 0xFF,
		"seed contract matches the verified $8097/$C50F/$CAE7 task setup operands and writes")
	_check(int(contract.get("scheduler_resume_cpu_address", -1)) == 0x8009
		and int(contract.get("callback_entry_cpu_address", -1)) == 0x814C
		and not bool(contract.get("scheduler_dispatched", true))
		and not bool(contract.get("callback_executed", true)),
		"seed return resolves $8009->$814C without simulating scheduler dispatch or callback execution")
	var wait_request: Dictionary = seed_result.get("wait_request_fields", {})
	_check(int(wait_request.get("value", -1)) == 2
		and int(wait_request.get("load_cpu_address", -1)) == 0xEC94
		and int(wait_request.get("destination_ram_address", -1)) == 0x0519
		and int(wait_request.get("decrement_cpu_address", -1)) == 0xED5B
		and not bool(wait_request.get("countdown_advanced", true)),
		"wait is exposed from source handoff bytes but no frame-based countdown is synthesized")

	var terminal: Dictionary = runtime.advance_one()
	_check(bool(terminal.get("ok", false))
		and str(terminal.get("status", "")) == "root_scenario_terminated"
		and int(terminal.get("source_byte_offset", -1)) == 7
		and int(terminal.get("source_byte_index_after", -1)) == 8
		and int(terminal.get("terminal_handler_cpu_address", -1)) == 0x80CF
		and not bool(terminal.get("outer_task_return_modeled", true)),
		"final root $FB terminates at $80CF while keeping outer task return unresolved")
	var after_terminal: Dictionary = runtime.advance_one()
	_check(not bool(after_terminal.get("ok", true)),
		"runtime refuses to advance past the root terminator")

	_check(_source_order_matches_manifest(),
		"source manifest order matches caller, scenario start, F9, event seed, and FB sequence")
	if _failures.is_empty():
		print("PASS: ROM-derived scenario-$35 source order reaches the exact callback-task seed contract and root $FB")
		print("LIMIT: cooperative scheduler, callback $814C/$8327, field-loop wait cadence, actor worker, and outer task return remain unexecuted")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: " + failure)
		quit(1)


func _source_order_matches_manifest() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_MANIFEST))
	if not parsed is Dictionary:
		return false
	var manifest: Dictionary = parsed
	var expected: Array[String] = [
		"kickoff callsite $DAD8 loads $35 and calls $CBB0",
		"$CBB0 writes $0518 and yields via $CB0F",
		"$EC08 maps bank $10, calls $8000, then clears $0522",
		"$8000 resolves pointer-table entry $35; $8003 initializes $3A to zero",
		"scenario $35 processes $F9, then record 02 3A 8F 73, then root $FB",
		"record setup at $8097 calls $C50F; the callback task source contract resumes at $8009->$814C",
		"$EC94 copies $0523 into $0519; $ED5B is the source countdown decrement, but this slice does not synthesize its field-loop cadence",
	]
	return manifest.get("source_order", []) == expected


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
