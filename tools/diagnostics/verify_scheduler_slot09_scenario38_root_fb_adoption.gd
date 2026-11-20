extends SceneTree
## Focused scheduler-adoption verifier for the observed scenario-$38 `$B7CC/$FB` path.
## The bounded RAM/map signature comes from the ordinary-input Godot route report;
## the scheduler container is synthetic because no full live RAM/stack receipt is persisted.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const OBSERVED_INPUT_FLAGS: Array[int] = [0x01, 0x40, 0x38, 0x01]
const OBSERVED_CALLBACK_FIELDS: Array[int] = [0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x40]
const OBSERVED_MAP2D: Array[int] = [
	0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dispatch := _make_observed_signature_dispatch()
	var dispatch_ram: PackedByteArray = dispatch["ram_image"]
	_check(dispatch_ram.slice(0x0516, 0x051A) == PackedByteArray(OBSERVED_INPUT_FLAGS)
		and dispatch_ram[0x003A] == 0x06
		and (dispatch_ram[0x005D] | (dispatch_ram[0x005E] << 8)) == 0xB7CC
		and dispatch_ram[0x0522] == 0
		and dispatch_ram.slice(0x0523, 0x052B) == PackedByteArray(OBSERVED_CALLBACK_FIELDS)
		and dispatch_ram.slice(0x05C7, 0x05D3) == PackedByteArray(OBSERVED_MAP2D),
		"fixture is gated by the ordinary-input route's reported `$EB8B` scenario-$38/map-$2D signature")

	var prefix: RefCounted = PREFIX_SCRIPT.new()
	_check(bool(prefix.call("configure_from_project_sources")),
		"slot-$09 prefix ROM spans and manifest validate")
	var source_result: Dictionary = prefix.call("execute_from_next_task_dispatch", dispatch)
	_check(bool(source_result.get("ok", false))
		and int(source_result.get("exit_pc", -1)) == 0x86F8
		and bool(source_result.get("scenario_route_state_executed", false))
		and bool(source_result.get("scenario_wait_worker_executed", false))
		and not bool(source_result.get("scenario_active", true)),
		"ROM-derived prefix returns the `$B7CC/$FB` scenario-$38 result at `$EB9E->$86F8"
			+ _source_detail(source_result))
	if bool(source_result.get("ok", false)):
		var result_ram: PackedByteArray = source_result.get("ram_image", PackedByteArray())
		_check(result_ram.size() == 0x800
			and result_ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x38, 0x00])
			and result_ram[0x003A] == 0x01
			and (result_ram[0x005D] | (result_ram[0x005E] << 8)) == 0xB7CC,
			"prefix output matches the ordinary-input report: `$29/$38`, wait `$00`, cursor `$01`, pointer `$B7CC`")
		_verify_scheduler_adoption(source_result, dispatch, false)
		_verify_scheduler_adoption(source_result, dispatch, true)

	if _failures.is_empty():
		print("PASS: the strict scenario-$38 `$B7CC/$FB` source result is adopted by the slot-$09 scheduler.")
		print("EVIDENCE: input/output fields are from the ordinary-input route report; the focused scheduler RAM/stack container is synthetic.")
		print("LIMIT: use the full recorded-input route replay as live scheduler acceptance; this verifier does not claim a persisted full-state checkpoint.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _make_observed_signature_dispatch() -> Dictionary:
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram[0x0000] = 0x09
	ram[0x0009] = 0x00
	ram[0x000A] = 0x76
	ram[0x000B] = 0x18
	ram[0x000C] = 0x19
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
	for index in range(OBSERVED_CALLBACK_FIELDS.size()):
		ram[0x0523 + index] = OBSERVED_CALLBACK_FIELDS[index]
	ram[0x052B] = 0x17
	ram[0x052F] = 0x2C
	ram[0x0531] = 0x2C
	ram[0x0532] = 0x17
	ram[0x0533] = 0x04
	for index in range(OBSERVED_MAP2D.size()):
		ram[0x05C7 + index] = OBSERVED_MAP2D[index]
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0x77] = 0x05
	stack[0x78] = 0x78
	stack[0x79] = 0x8A
	stack[0x7A] = 0xEB
	for index in range(4):
		ram[0x0177 + index] = stack[0x77 + index]
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


func _verify_scheduler_adoption(source_result: Dictionary, dispatch: Dictionary, near_match: bool) -> void:
	var scheduler: RefCounted = SCHEDULER_SCRIPT.new()
	if not bool(scheduler.call("configure_from_project_sources")):
		_failures.append("Scheduler ROM source setup failed: " + String(scheduler.get("error_message")))
		return
	var bootstrap: Dictionary = scheduler.call("initialize_fresh_game_bootstrap")
	if not bool(bootstrap.get("ok", false)):
		_failures.append("Scheduler bootstrap failed: " + String(scheduler.get("error_message")))
		return
	var ram: PackedByteArray = dispatch["ram_image"].duplicate()
	if near_match:
		ram[0x0524] = 0x35
	scheduler.set("_ram", ram)
	scheduler.set("_stack_page", dispatch["stack_page"].duplicate())
	scheduler.set("_active_task_slot", 0x09)
	var contexts: Dictionary = scheduler.get("_contexts")
	var context: Object = contexts.get(0x09)
	if context == null:
		_failures.append("Initialized scheduler has no root slot-$09 context")
		return
	context.set("phase", SCHEDULER_SCRIPT.ContextPhase.RUNNING)
	context.set("program_counter", 0xEB8B)
	context.set("stack_pointer", 0x7A)
	context.set("accumulator", 0x78)
	context.set("x_register", 0x78)
	context.set("y_register", 0x05)
	context.set("status_register", 0x00)
	context.set("status_known_mask", 0x00)
	context.set("bank_low", 0x18)
	context.set("bank_high", 0x19)
	context.set("mapper_state", {"bank_low": 0x18, "bank_high": 0x19, "select": 0x07})
	var adopted: bool = scheduler.call("adopt_slot09_scenario_wait_worker_state", source_result)
	if near_match:
		_check(not adopted,
			"near-match callback selector `$35` is rejected rather than entering the scenario-$38 case")
		return
	if not adopted:
		_failures.append("Exact scenario-$38 live signature was rejected by scheduler: " + String(scheduler.get("error_message")))
		return
	var snapshot: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var adopted_ram: PackedByteArray = snapshot.get("ram_image", PackedByteArray())
	_check(int(snapshot.get("active_task_slot", -1)) == 0x09
		and int(snapshot.get("pc", -1)) == 0x86F8
		and adopted_ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x38, 0x00])
		and adopted_ram[0x003A] == 0x01
		and (adopted_ram[0x005D] | (adopted_ram[0x005E] << 8)) == 0xB7CC,
		"scheduler adopts only source writes and preserves the scenario-$38 root-terminator boundary")


func _source_detail(result: Dictionary) -> String:
	if bool(result.get("ok", false)):
		return ""
	return ": " + String(result.get("reason", "prefix source execution failed"))


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures.append(description)

