extends SceneTree
## Focused ROM-source verifier for scenario $38 / callback $34 after map $2D.
## The dispatch fixture is synthetic and tests only the bounded continuation;
## it is not a live route observation or emulator-state input.

const PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const SCENARIO_RUNTIME_SCRIPT := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")
const WORKER86_SCRIPT := preload("res://scripts/gameplay/rom_slot09_86f8_zero_branch_executor.gd")
const WORKER8779_SCRIPT := preload("res://scripts/gameplay/rom_slot09_8779_zero_branch_executor.gd")
const WORKER87E6_SCRIPT := preload("res://scripts/gameplay/rom_slot09_87e6_zero_branch_executor.gd")
const ROOT_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_slot09_ebd7_root_zero_counter_executor.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_EVENT_RECORD := [0x01, 0x34, 0x00, 0xF0]
const EXPECTED_CALLBACK_FIELDS := [0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF]
const EXPECTED_PRE_CALLBACK_RAM := [
	0x51, 0x40, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x01, 0x34, 0x02, 0x80, 0x02, 0x00, 0xFF, 0x40, 0x17, 0x00, 0x00,
	0x00, 0x2C, 0x00, 0x2C, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
const EXPECTED_PRE_CALLBACK_MAP2D := [
	0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenario_runtime: RefCounted = SCENARIO_RUNTIME_SCRIPT.new()
	var started: Dictionary = scenario_runtime.call("begin_from_live_scenario_pointer", 0x38, 0xB7C6)
	_check(bool(started.get("ok", false))
		and String(started.get("source_stream_sha256", "")) == "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76",
		"scenario-$38 stream/pointer validates against the supplied-ROM hash")
	if bool(started.get("ok", false)):
		var opcode: Dictionary = scenario_runtime.call("advance_one")
		var record: Dictionary = scenario_runtime.call("advance_one")
		var contract: Dictionary = record.get("seed_contract_fields", {})
		_check(bool(opcode.get("ok", false)) and int(opcode.get("opcode", -1)) == 0xF7
			and int(opcode.get("operand", -1)) == 0x17
			and int(opcode.get("ram_writes", {}).get("$052B", -1)) == 0x17,
			"ROM `$F7 $17` derives `$052B=$17`")
		_check(bool(record.get("ok", false))
			and Array(contract.get("source_record_bytes", PackedByteArray())) == EXPECTED_EVENT_RECORD
			and int(contract.get("wait_value_ram_0523", -1)) == 0x01
			and int(contract.get("event_selector_ram_0524", -1)) == 0x34
			and int(contract.get("actor_selector_ram_0528", -1)) == 0x00
			and int(contract.get("actor_parameter_ram_0529", -1)) == 0xFF,
			"ROM event record derives callback-$34 no-actor fields")

	var executor: RefCounted = PREFIX_SCRIPT.new()
	var configured := bool(executor.call("configure_from_project_sources"))
	_check(configured,
		"slot-$09 caller, callback, palette, actor-parameter, and no-seed-tail sources validate")
	if configured:
		var dispatch := _make_dispatch()
		var input_ram: PackedByteArray = dispatch["ram_image"].duplicate()
		var input_stack: PackedByteArray = dispatch["stack_page"].duplicate()
		_check(input_ram.slice(0x0516, 0x053A) == PackedByteArray(EXPECTED_PRE_CALLBACK_RAM)
			and input_ram.slice(0x05C7, 0x05D3) == PackedByteArray(EXPECTED_PRE_CALLBACK_MAP2D),
			"synthetic fixture matches the observed live `$EB8B` source-boundary scenario and map-$2D RAM signature")
		var result: Dictionary = executor.call("execute_from_next_task_dispatch", dispatch)
		if not bool(result.get("ok", false)):
			_failures.append("Synthetic source route failed: " + String(result.get("reason", result.get("error", executor.get("error_message")))))
		_check(bool(result.get("ok", false))
			and String(result.get("status", "")) == "stopped_before_worker_body"
			and int(result.get("entry_pc", -1)) == 0xEB8B
			and int(result.get("exit_pc", -1)) == 0x86F8
			and bool(result.get("scenario_post_callback_executed", false))
			and not bool(result.get("scenario_active", true))
			and not bool(result.get("worker_body_executed", true))
			and not bool(result.get("worker_body_bytes_read", true))
			and not bool(result.get("trace_state_used", true)),
			"source continuation executes `$EC8C->$ED15->$ED2D->$EB9E->$86F8` and stops before worker bytes")
		if bool(result.get("ok", false)):
			_verify_output(result)
			_verify_worker_chain(result)
			_check(dispatch["ram_image"] == input_ram and dispatch["stack_page"] == input_stack,
				"executor leaves its caller-owned RAM and stack images unchanged")
			_verify_rejected_near_matches(executor, dispatch)
		_verify_live_wait_profile()

	if _failures.is_empty():
		print("PASS: ROM-derived scenario-$38 callback `$34` follows the observed `$EB8B` source-boundary profile through `$86F8->$8779->$87E6->$CB0F`.")
		print("LIMIT: initial `$EB8B` RAM/CPU/stack is an explicit synthetic fixture using observed route values. This verifies the bounded callback/worker chain, not ordinary-input route timing, PPU/APU output, or visual parity.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _make_dispatch() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x09
	ram[0x0021] = 0x1E
	ram[0x0022] = 0x00
	ram[0x0516] = 0x51
	ram[0x0517] = 0x40
	ram[0x0518] = 0x38
	ram[0x0519] = 0x00
	ram[0x0523] = 0x01
	ram[0x0524] = 0x34
	ram[0x0525] = 0x02
	ram[0x0526] = 0x80
	ram[0x0527] = 0x02
	ram[0x0528] = 0x00
	ram[0x0529] = 0xFF
	ram[0x052A] = 0x40
	ram[0x052B] = 0x17
	ram[0x052F] = 0x2C
	ram[0x0531] = 0x2C
	ram[0x0532] = 0x00
	ram[0x0533] = 0x06
	ram[0x05C7] = 0x40
	ram[0x05C8] = 0xA0
	ram[0x05C9] = 0x00
	ram[0x05CA] = 0x02
	ram[0x05CB] = 0x01
	ram[0x05CC] = 0x2D
	ram[0x05CD] = 0xA0
	ram[0x05CE] = 0x80
	ram[0x05D0] = 0x02
	ram[0x05D1] = 0x00
	ram[0x05D2] = 0x00
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0x77] = 0x05
	stack[0x78] = 0x78
	stack[0x79] = 0x8A
	stack[0x7A] = 0xEB
	ram[0x0177] = 0x05
	ram[0x0178] = 0x78
	ram[0x0179] = 0x8A
	ram[0x017A] = 0xEB
	return {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x09,
		"resume_path": "yielded_rts",
		"pc": 0xEB8B,
		"sp": 0x7A,
		"a": 0x78,
		"x": 0x78,
		"y": 0x05,
		"p": 0x00,
		"p_known_mask": 0,
		"bank_low": 0x18,
		"bank_high": 0x19,
		"task_record": PackedByteArray([0x00, 0x76, 0x18, 0x19]),
		"mapper": {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07},
		"ram_image": ram,
		"stack_page": stack,
		"fixture_only": true,
		"trace_state_used": false,
	}


func _make_live_wait_dispatch() -> Dictionary:
	var dispatch := _make_dispatch()
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x09
	ram[0x0021] = 0x1E
	ram[0x0022] = 0x00
	ram[0x003A] = 0x06
	ram[0x005D] = 0xCC
	ram[0x005E] = 0xB7
	ram[0x0079] = 0xE9
	ram[0x007A] = 0xAF
	ram[0x0516] = 0x01
	ram[0x0517] = 0x40
	ram[0x0518] = 0x38
	ram[0x0519] = 0x01
	ram[0x0522] = 0x00
	ram[0x0523] = 0x01
	ram[0x0524] = 0x34
	ram[0x0525] = 0x02
	ram[0x0526] = 0x00
	ram[0x0527] = 0x02
	ram[0x0528] = 0x00
	ram[0x0529] = 0xFF
	ram[0x052A] = 0x40
	ram[0x052B] = 0x17
	ram[0x052F] = 0x2C
	ram[0x0531] = 0x2C
	ram[0x0532] = 0x17
	ram[0x0533] = 0x04
	ram[0x05C7] = 0x40
	ram[0x05C8] = 0xA0
	ram[0x05C9] = 0x00
	ram[0x05CA] = 0x02
	ram[0x05CB] = 0x01
	ram[0x05CC] = 0x2D
	ram[0x05CD] = 0xA0
	ram[0x05CE] = 0x80
	ram[0x05D0] = 0x02
	ram[0x05D1] = 0x00
	ram[0x05D2] = 0x00
	ram[0x0177] = 0x05
	ram[0x0178] = 0x78
	ram[0x0179] = 0x8A
	ram[0x017A] = 0xEB
	dispatch["ram_image"] = ram
	dispatch["fixture_only"] = true
	dispatch["trace_state_used"] = false
	return dispatch


func _verify_live_wait_profile() -> void:
	var executor: RefCounted = PREFIX_SCRIPT.new()
	if not bool(executor.call("configure_from_project_sources")):
		_failures.append("Live scenario-$38 one-tick wait sources failed to configure")
		return
	var dispatch := _make_live_wait_dispatch()
	var result: Dictionary = executor.call("execute_from_next_task_dispatch", dispatch)
	if not bool(result.get("ok", false)):
		_failures.append("Live scenario-$38 `$EC0D->$B7CC` source profile failed: "
			+ String(result.get("reason", result.get("error", executor.get("error_message")))))
		return
	var pcs: Array = result.get("instruction_pcs", [])
	var required_pcs: Array[int] = [0xEC0D, 0xEC34, 0xED5B, 0xED5C, 0xED6F,
		0x8003, 0x803F, 0x8045, 0x80CF, 0xED84, 0xEB9E, 0xED85]
	var cursor := 0
	for pc_variant in pcs:
		if cursor < required_pcs.size() and int(pc_variant) == required_pcs[cursor]:
			cursor += 1
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var terminal_events: Array = result.get("scenario_runtime_events", [])
	var terminal_event: Dictionary = terminal_events.back() if not terminal_events.is_empty() else {}
	var terminal_result: Dictionary = terminal_event.get("result", {})
	var live_profile_ok: bool = (cursor == required_pcs.size()
		and String(result.get("status", "")) == "stopped_before_worker_body"
		and int(result.get("exit_pc", -1)) == 0x86F8
		and bool(result.get("scenario_wait_worker_executed", false))
		and bool(result.get("scenario_route_state_executed", false))
		and not bool(result.get("scenario_post_callback_executed", true))
		and ram.size() == 0x800 and ram[0x0516] == 0x29 and ram[0x0519] == 0
		and ram[0x0522] == 0 and ram[0x003A] == 1
		and int(terminal_event.get("source_pointer", -1)) == 0xB7CC
		and terminal_event.get("source_bytes", PackedByteArray()) == PackedByteArray([0xFB])
		and String(terminal_result.get("status", "")) == "root_scenario_terminated"
		and int(terminal_result.get("source_byte_offset", -1)) == 6)
	var detail := "pcs=%s exit=$%04X status=%s phase=$%02X wait=$%02X cursor=$%02X terminal=$%04X/%02X@%d" % [
		str(pcs), int(result.get("exit_pc", -1)), String(result.get("status", "")),
		int(ram[0x0516]) if ram.size() == 0x800 else -1,
		int(ram[0x0519]) if ram.size() == 0x800 else -1,
		int(ram[0x003A]) if ram.size() == 0x800 else -1,
		int(terminal_event.get("source_pointer", -1)),
		int((terminal_event.get("source_bytes", PackedByteArray()) as PackedByteArray)[0]) if not (terminal_event.get("source_bytes", PackedByteArray()) as PackedByteArray).is_empty() else -1,
		int(terminal_result.get("source_byte_offset", -1))]
	_check(live_profile_ok,
		"exact live callback-$34/map-$2D profile takes `$EC0D->$ED5B->$B7CC->$80CF->$EB9E->$86F8` without reseeding callback `$34` (" + detail + ")")


func _verify_output(result: Dictionary) -> void:
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = result.get("stack_page", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var pcs: Array = result.get("instruction_pcs", [])
	var expected_subsequence: Array[int] = [0xEC8C, 0xED15, 0xED2D, 0xED5A, 0xEB9E, 0xED85, 0x8003]
	var subsequence_index := 0
	for pc_variant in pcs:
		if subsequence_index < expected_subsequence.size() \
				and int(pc_variant) == expected_subsequence[subsequence_index]:
			subsequence_index += 1
	_check(subsequence_index == expected_subsequence.size(),
		"executed-PC log preserves the ROM callback, no-seed tail, root return, and `$8003->$86F8` vector order")
	_check(ram.size() == 0x800
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x40, 0x38, 0x01])
		and ram.slice(0x0523, 0x052A) == PackedByteArray(EXPECTED_CALLBACK_FIELDS)
		and ram[0x052A] == 0x40 and ram[0x0526] == 0x00
		and ram[0x0532] == 0x97 and ram[0x0534] == 0x80 and ram[0x0536] == 0x80
		and ram[0x0533] == 0x06
		and ram[0x0469] == 0x01 and ram[0x046C] == 0x20 and ram[0x046F] == 0x0F
		and ram[0x0490] == 0x00 and ram[0x0491] == 0x02
		and ram[0x05CC] == 0x2D and ram[0x05CD] == 0xA0 and ram[0x05CE] == 0x80
		and ram[0x05D2] == 0x00,
		"ROM writes clear only `$0526` bit 7, preserve `$052A/$0533`, write `$0490/$0491`, and derive the palette fill and `$0532=$97`")
	var writes: Array = result.get("writes", [])
	_check(_has_ram_write(writes, 0xECBE, 0x0526, 0x00)
		and _has_ram_write(writes, 0xECC1, 0x0490, 0x00)
		and _has_ram_write(writes, 0xECC7, 0x0491, 0x02)
		and not _has_ram_write_to_address(writes, 0x0533),
		"ROM `$ECBE/$ECC1/$ECC7` writes match the `$0526=$80` mask branch and leave `$0533` untouched")
	_check(int(registers.get("pc", -1)) == 0x86F8
		and int(registers.get("sp", -1)) == 0x78
		and int(mapper.get("bank_low", -1)) == 0x18
		and int(mapper.get("bank_high", -1)) == 0x19
		and int(mapper.get("select", -1)) == 0x07
		and int(stack[0x79]) == 0xB2 and int(stack[0x7A]) == 0xEB,
		"result retains the ROM `$86F8` vector call and stack return word `$EBB2`")
	var span_hashes: Dictionary = result.get("source_span_hashes", {})
	_check(String(span_hashes.get("fixed_scenario_post_callback_EC8C_ED2C.bin", ""))
			== "b371428c3f42ad83d893a9737c4b4f78f160449cab9874bd13785f6946898fd3"
		and String(span_hashes.get("fixed_scenario_resume_ED2D_ED5A.bin", ""))
			== "d06c6c1049fe7469ecdd6c0ee4b48d22afdb20268987035223e78a2a961b71ac",
		"result records both pinned source span hashes")


func _verify_worker_chain(prefix_result: Dictionary) -> void:
	var worker86: RefCounted = WORKER86_SCRIPT.new()
	_check(bool(worker86.call("configure_from_project_sources")),
		"slot-$09 `$86F8` ROM worker source package validates")
	var worker86_result: Dictionary = worker86.call("execute_from_slot09_resume_result", prefix_result)
	if not bool(worker86_result.get("ok", false)):
		_failures.append("Scenario-$38 `$86F8` worker failed: " + String(worker86_result.get("reason", "unknown error")))
		return
	var worker8779: RefCounted = WORKER8779_SCRIPT.new()
	var worker87e6: RefCounted = WORKER87E6_SCRIPT.new()
	var root_executor: RefCounted = ROOT_EXECUTOR_SCRIPT.new()
	for configured in [
		bool(worker8779.call("configure_from_project_sources")),
		bool(worker87e6.call("configure_from_project_sources")),
		bool(root_executor.call("configure_from_project_sources")),
	]:
		_check(configured, "each slot-$09 worker/source package validates against its ROM manifest")
	if not _failures.is_empty():
		return
	var worker_ram: PackedByteArray = worker86_result["ram_image"]
	_check(String(worker86_result.get("status", "")) == "returned_after_stream_batch"
		and int(worker86_result.get("input_ram_0532", -1)) == 0x97
		and int(worker86_result.get("output_ram_0532", -1)) == 0x17
		and int(worker86_result.get("stream_pointer_before", -1)) == 0xAFE6
		and int(worker86_result.get("stream_pointer_after", -1)) == 0xAFE9
		and int(worker86_result.get("stream_control", -1)) == 0x21
		and int(worker86_result.get("stream_pair_count", -1)) == 1
		and int(worker86_result.get("countdown_after", -1)) == 4
		and worker_ram[0x047F] == 0x0F and worker_ram[0x0533] == 4
		and worker_ram.slice(0x0499, 0x049C) == PackedByteArray([0x00, 0x6C, 0x04])
		and int(worker86_result.get("exit_pc", -1)) == 0xEBB3
		and bool(worker86_result.get("trace_state_used", true)) == false,
		"`$97` selects the checked `$AD9A->$AFE6` reset-marker batch and appends its ROM inline queue record")
	var worker8779_result: Dictionary = worker8779.call("execute_from_86f8_worker_result", worker86_result)
	if not bool(worker8779_result.get("ok", false)):
		_failures.append("Scenario-$38 `$8779` continuation failed: " + String(worker8779_result.get("reason", "unknown error")))
		return
	var worker8779_ram: PackedByteArray = worker8779_result["ram_image"]
	_check(int(worker8779_result.get("input_ram_0534", -1)) == 0x80
		and worker8779_ram[0x0534] == 0 and int(worker8779_result.get("exit_pc", -1)) == 0xEBC5,
		"`$8779` normalizes `$0534=$80` and returns through the decoded root caller")
	var worker87e6_result: Dictionary = worker87e6.call("execute_from_8779_worker_result", worker8779_result)
	if not bool(worker87e6_result.get("ok", false)):
		_failures.append("Scenario-$38 `$87E6` continuation failed: " + String(worker87e6_result.get("reason", "unknown error")))
		return
	var worker87e6_ram: PackedByteArray = worker87e6_result["ram_image"]
	_check(worker87e6_ram[0x0536] == 0 and worker87e6_ram[0x0538] == 0
		and int(worker87e6_result.get("exit_pc", -1)) == 0xEBD7,
		"`$87E6` normalizes `$0536=$80`, stores `$0538=0`, and returns to the root loop")
	var root_result: Dictionary = root_executor.call("execute_from_87e6_result", worker87e6_result)
	if not bool(root_result.get("ok", false)):
		_failures.append("Scenario-$38 root continuation failed: " + String(root_result.get("reason", "unknown error")))
		return
	_check(String(root_result.get("status", "")) == "reached_scheduler_yield_handler_entry"
		and int(root_result.get("exit_pc", -1)) == 0xCB0F
		and int(root_result.get("source_yield_request", {}).get("callsite_pc", -1)) == 0xEB88
		and not bool(root_result.get("yield_handler_executed", true))
		and not bool(root_result.get("next_root_check_executed", true)),
		"bounded route stops at the next `$CB0F` scheduler entry without executing or injecting its endpoint")


func _has_ram_write(writes: Array, pc: int, address: int, value: int) -> bool:
	for write_variant in writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("pc", -1)) == pc and int(write.get("address", -1)) == address \
				and int(write.get("value", -1)) == value:
			return true
	return false


func _has_ram_write_to_address(writes: Array, address: int) -> bool:
	for write_variant in writes:
		if write_variant is Dictionary and int(write_variant.get("address", -1)) == address:
			return true
	return false


func _verify_rejected_near_matches(executor: RefCounted, dispatch: Dictionary) -> void:
	for mutation in [
		{"name": "wrong callback", "address": 0x0524, "value": 0x35},
		{"name": "wrong masked actor Y", "address": 0x0526, "value": 0x00},
		{"name": "wrong actor state", "address": 0x052A, "value": 0x00},
		{"name": "wrong map batch countdown", "address": 0x0533, "value": 0x05},
		{"name": "wrong scenario map", "address": 0x05CC, "value": 0x36},
		{"name": "wrong map cursor", "address": 0x05C8, "value": 0x20},
		{"name": "actor-seed request", "address": 0x0529, "value": 0x73},
	]:
		var changed := dispatch.duplicate(true)
		var ram: PackedByteArray = (dispatch["ram_image"] as PackedByteArray).duplicate()
		ram[int(mutation["address"])] = int(mutation["value"])
		changed["ram_image"] = ram
		var rejected: Dictionary = executor.call("execute_from_next_task_dispatch", changed)
		_check(not bool(rejected.get("ok", true)),
			"source gate rejects the %s near-match" % String(mutation["name"]))


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
