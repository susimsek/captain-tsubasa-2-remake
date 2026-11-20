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

	var scenario_1e := RUNTIME_SCRIPT.new()
	var missing_context: Dictionary = scenario_1e.begin_from_live_scenario_pointer(0x1E, 0xB7DA)
	_check(not bool(missing_context.get("ok", true))
		and str(missing_context.get("status", "")) == "source_state_required",
		"scenario-$1E refuses to guess the `$FD $02` result without live RAM `$05FB`")
	var scenario_1e_ready: Dictionary = scenario_1e.begin_from_live_scenario_pointer(0x1E, 0xB7DA,
		{"ram_05FB": 0x00})
	_check(bool(scenario_1e_ready.get("ok", false))
		and int(scenario_1e_ready.get("source_pointer_cpu", -1)) == 0xB7DA
		and not bool(scenario_1e_ready.get("source_context_required_after_prefix", true)),
		"scenario-$1E pointer and `$FD $02` decode from its manifest entry plus live `$05FB=$00`")
	var scenario_1e_fd: Dictionary = scenario_1e.advance_one()
	var scenario_1e_fd_writes: Dictionary = scenario_1e_fd.get("ram_writes", {})
	_check(bool(scenario_1e_fd.get("ok", false))
		and int(scenario_1e_fd.get("opcode", -1)) == 0xFD
		and int(scenario_1e_fd_writes.get("$052A", -1)) == 0,
		"scenario-$1E `$FD $02` applies the source handler's zero result")
	var scenario_1e_f6: Dictionary = scenario_1e.advance_one()
	var scenario_1e_f6_writes: Dictionary = scenario_1e_f6.get("ram_writes", {})
	_check(bool(scenario_1e_f6.get("ok", false))
		and int(scenario_1e_f6.get("opcode", -1)) == 0xF6
		and int(scenario_1e_f6_writes.get("$052A", -1)) == 0x40,
		"scenario-$1E `$F6` applies the decoded XOR-$40 to the live `$052A` value")
	var scenario_1e_f7: Dictionary = scenario_1e.advance_one()
	var scenario_1e_f7_writes: Dictionary = scenario_1e_f7.get("ram_writes", {})
	_check(bool(scenario_1e_f7.get("ok", false))
		and int(scenario_1e_f7.get("opcode", -1)) == 0xF7
		and int(scenario_1e_f7_writes.get("$052B", -1)) == 0x01,
		"scenario-$1E `$F7 01` applies its ROM stream operand to `$052B`")
	var scenario_1e_record: Dictionary = scenario_1e.advance_one()
	var scenario_1e_contract: Dictionary = scenario_1e_record.get("seed_contract_fields", {})
	_check(bool(scenario_1e_record.get("ok", false))
		and int(scenario_1e_record.get("source_byte_offset", -1)) == 5
		and scenario_1e_contract.get("source_record_bytes", PackedByteArray()) == PackedByteArray([0x07, 0x45, 0x90, 0xF0])
		and int(scenario_1e_contract.get("source_record_cpu_address", -1)) == 0xB7DF
		and int(scenario_1e_contract.get("source_record_file_offset", -1)) == 0x0237EF
		and int(scenario_1e_contract.get("wait_value_ram_0523", -1)) == 0x07
		and int(scenario_1e_contract.get("event_selector_ram_0524", -1)) == 0x45
		and int(scenario_1e_contract.get("actor_selector_ram_0528", -1)) == 0x90
		and int(scenario_1e_contract.get("actor_parameter_ram_0529", -1)) == 0xFF,
		"scenario-$1E record `$07 45 90 F0` yields the source-derived wait and callback seed fields")
	var scenario_1e_terminal: Dictionary = scenario_1e.advance_one()
	_check(bool(scenario_1e_terminal.get("ok", false))
		and str(scenario_1e_terminal.get("status", "")) == "root_scenario_terminated"
		and int(scenario_1e_terminal.get("source_byte_index_after", -1)) == 10,
		"scenario-$1E root stops at the manifest-checked trailing `$FB`: %s" % str(scenario_1e_terminal))

	var scenario_1c_b49e := RUNTIME_SCRIPT.new()
	var b49e_started: Dictionary = scenario_1c_b49e.begin_from_live_scenario_pointer(
		0x1C, 0xB49E, {"continuation_depth": 0})
	_check(bool(b49e_started.get("ok", false))
		and str(b49e_started.get("status", "")) == "scenario1c_b49e_f2_branch_admitted"
		and int(b49e_started.get("source_file_offset", -1)) == 0x0234AE,
		"scenario-$1C admits only the manifest-pinned `$B49E` F2 target after zero-depth return")
	var b49e_f9: Dictionary = scenario_1c_b49e.advance_one()
	_check(bool(b49e_f9.get("ok", false))
		and int(b49e_f9.get("opcode", -1)) == 0xF9
		and int(b49e_f9.get("source_byte_index_after", -1)) == 3
		and b49e_f9.get("ram_writes", {}) == {"$0530": 0x1D, "$0531": 0x2C},
		"scenario-$1C `$B49E` `$F9` decodes its ROM operands `$1D/$2C`")
	var b49e_record: Dictionary = scenario_1c_b49e.advance_one()
	var b49e_contract: Dictionary = b49e_record.get("seed_contract_fields", {})
	_check(bool(b49e_record.get("ok", false))
		and str(b49e_record.get("status", "")) == "callback_task_seed_requested"
		and int(b49e_record.get("source_byte_offset", -1)) == 3
		and int(b49e_record.get("source_byte_index_after", -1)) == 7
		and b49e_contract.get("source_record_bytes", PackedByteArray()) == PackedByteArray([0x3C, 0x01, 0x78, 0x58])
		and int(b49e_contract.get("source_record_cpu_address", -1)) == 0xB4A1
		and int(b49e_contract.get("source_record_file_offset", -1)) == 0x0234B1
		and int(b49e_contract.get("wait_value_ram_0523", -1)) == 0x3C
		and int(b49e_contract.get("event_selector_ram_0524", -1)) == 0x01
		and int(b49e_contract.get("actor_selector_ram_0528", -1)) == 0x78
		and int(b49e_contract.get("actor_parameter_ram_0529", -1)) == 0x58
		and int(b49e_contract.get("task_slot_base", -1)) == 0x15
		and not bool(b49e_contract.get("scheduler_dispatched", true))
		and not bool(b49e_contract.get("callback_executed", true)),
		"scenario-$1C `$B49E` record produces the exact `$3C/$01/$78/$58` slot-$15 seed without dispatching it")
	var b49e_terminal: Dictionary = scenario_1c_b49e.advance_one()
	_check(bool(b49e_terminal.get("ok", false))
		and str(b49e_terminal.get("status", "")) == "root_scenario_terminated"
		and int(b49e_terminal.get("source_byte_index_after", -1)) == 8,
		"scenario-$1C `$B49E` root terminates at its exact trailing `$FB`")

	_check(_source_order_matches_manifest(),
		"source manifest order matches caller, scenario start, F9, event seed, and FB sequence")
	if _failures.is_empty():
		print("PASS: ROM-derived scenario-$35/$1E seeds and scenario-$1C `$B49E` seed/terminal are source-bounded")
		print("LIMIT: cooperative scheduler, callback dispatch, field-loop wait cadence, actor worker, and outer task return remain unexecuted")
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
