extends SceneTree
## Focused synthetic verifier for the scenario-$1C `$71` wait-bit countdown.
## Its exact RAM fields come from a checkpoint produced by the ordinary-input
## Godot source route at frame 9205; this is not FCEUX evidence.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

const ENTRY_SCENARIO_FIELDS: Array[int] = [
	0x71, 0x40, 0x1C, 0x1B, 0xE8, 0x9B, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x3C, 0x01, 0x02, 0xBC, 0x4A, 0x78, 0x58, 0x40,
]
const ENTRY_CALLBACK_MAP_FIELDS: Array[int] = [
	0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x01, 0x00,
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dispatch := _make_dispatch()
	var input_ram: PackedByteArray = dispatch["ram_image"]
	_check(input_ram.slice(0x0516, 0x052B) == PackedByteArray(ENTRY_SCENARIO_FIELDS)
		and input_ram[0x003A] == 0x06
		and input_ram.slice(0x005D, 0x005F) == PackedByteArray([0xA5, 0xB4])
		and input_ram.slice(0x05C7, 0x05D4) == PackedByteArray(ENTRY_CALLBACK_MAP_FIELDS),
		"synthetic `$EB8B` fixture matches the ordinary-input Godot frame-9205 checkpoint signature")

	var prefix: RefCounted = PREFIX_SCRIPT.new()
	_check(bool(prefix.call("configure_from_project_sources")),
		"slot-$09 continuation prefix sources validate against the ROM manifest")
	if _failures.is_empty():
		var result: Dictionary = prefix.call("execute_from_next_task_dispatch", dispatch)
		if not bool(result.get("ok", false)):
			_failures.append("scenario-$1C `$71` prefix rejected the exact checkpoint-derived fixture: "
				+ String(result.get("reason", result.get("error", prefix.get("error_message")))))
		else:
			_verify_prefix_result(result, dispatch)
			_verify_prefix_near_misses(prefix, dispatch)
			_verify_scheduler_adoption(result, dispatch)
			_verify_scheduler_near_miss(result, dispatch)
			_verify_expired_checkpoint(prefix, dispatch)

	if _failures.is_empty():
		print("PASS: the narrow scenario-$1C `$71` wait-bit fixture decrements `$0519` and is accepted at the `$86F8` scheduler boundary.")
		print("PASS: the scenario-$1C `$71` expired checkpoint reaches the `$ED15` callback-$01 actor-seed request.")
		print("EVIDENCE: checkpoint-derived Godot source-route fields plus synthetic `$EB8B` dispatches; not FCEUX evidence.")
		print("LIMIT: expiry branch stops at `$ED15`; no slot-$11 seed, expired-state scheduler adoption, or full-route proof is performed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _make_dispatch() -> Dictionary:
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
	ram[0x005D] = 0xA5
	ram[0x005E] = 0xB4
	ram[0x0516] = 0x71
	ram[0x0517] = 0x40
	ram[0x0518] = 0x1C
	ram[0x0519] = 0x1B
	ram[0x051A] = 0xE8
	ram[0x051B] = 0x9B
	# The checkpoint's callback/event span is `$0523:$052B`; `$0522` is depth 0.
	ram[0x0522] = 0x00
	for index in range(8):
		ram[0x0523 + index] = ENTRY_SCENARIO_FIELDS[13 + index]
	ram[0x0532] = 0x00
	ram[0x0533] = 0x01
	ram[0x0534] = 0x00
	ram[0x0535] = 0x00
	ram[0x0536] = 0x00
	ram[0x0537] = 0x00
	ram[0x0538] = 0x00
	ram[0x0539] = 0x00
	for index in range(ENTRY_CALLBACK_MAP_FIELDS.size()):
		ram[0x05C7 + index] = ENTRY_CALLBACK_MAP_FIELDS[index]
	ram[0x05D4] = 0xA8
	ram[0x05D5] = 0xFF
	ram[0x05D6] = 0x00
	ram[0x05D7] = 0xFC
	ram[0x05DF] = 0xFC
	ram[0x05FB] = 0x00
	ram[0x0635] = 0x84
	ram[0x0637] = 0x54
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


func _verify_prefix_result(result: Dictionary, dispatch: Dictionary) -> void:
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var mapper: Dictionary = result.get("mapper", {})
	var pcs: Array = result.get("instruction_pcs", [])
	var required_pcs: Array[int] = [
		0xEC08, 0xEC0B, 0xEC0D, 0xEC10, 0xEC34, 0xED5B, 0xED5C,
		0xED5F, 0xED61, 0xED63, 0xED66, 0xED68, 0xED84, 0xEB9E,
		0xED85, 0xED88, 0xED8B, 0xEDF5, 0xEDF8, 0xEE31,
	]
	var cursor := 0
	for pc_variant in pcs:
		if cursor < required_pcs.size() and int(pc_variant) == required_pcs[cursor]:
			cursor += 1
	_check(String(result.get("status", "")) == "stopped_before_worker_body"
		and int(result.get("entry_pc", -1)) == 0xEB8B
		and int(result.get("exit_pc", -1)) == 0x86F8
		and cursor == required_pcs.size()
		and bool(result.get("scenario_wait_worker_executed", false))
		and not bool(result.get("scenario_active", true))
		and not bool(result.get("worker_body_executed", true))
		and not bool(result.get("worker_body_bytes_read", true))
		and not bool(result.get("trace_state_used", true)),
		"ROM-byte prefix follows the `$71 & $20` wait return through `$ED84->$EB9E->$86F8`, without reading worker bytes")
	_check(ram.size() == 0x800
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x71, 0x40, 0x1C, 0x1A])
		and ram[0x051A] == 0xE8 and ram[0x051B] == 0x9B
		and ram[0x003A] == 0x06
		and (ram[0x005D] | (ram[0x005E] << 8)) == 0xB4A5
		and ram[0x0522] == 0x00
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x3C, 0x01, 0x02, 0xBC, 0x4A, 0x78, 0x58, 0x40])
		and ram[0x05D2] == 0x01,
		"wait tick decrements only `$0519` among the scenario/event fields and preserves the callback cursor and helper mode")
	_check(_has_ram_write(result.get("writes", []), 0xED5C, 0x0519, 0x1A)
		and int(registers.get("pc", -1)) == 0x86F8
		and int(registers.get("sp", -1)) == 0x78
		and int(mapper.get("bank_low", -1)) == 0x18
		and int(mapper.get("bank_high", -1)) == 0x19
		and (result.get("scenario_runtime_events", []) as Array).is_empty(),
		"source countdown write reaches the expected bank-$18 vector boundary with the live slot-$09 stack contract")
	_check(dispatch["ram_image"] != ram,
		"executor returns a derived RAM image without mutating the caller-owned dispatch fixture")


func _verify_prefix_near_misses(prefix: RefCounted, dispatch: Dictionary) -> void:
	var mutations: Array[Dictionary] = [
		{"name": "wrong event phase", "address": 0x0525, "value": 0x00},
		{"name": "wrong callback cursor", "address": 0x005D, "value": 0xA4},
		{"name": "wrong map placement", "address": 0x05CD, "value": 0xA0},
		{"name": "wrong helper mode", "address": 0x05D2, "value": 0x00},
	]
	for mutation in mutations:
		var changed: Dictionary = dispatch.duplicate(true)
		var ram: PackedByteArray = (dispatch["ram_image"] as PackedByteArray).duplicate()
		ram[int(mutation["address"])] = int(mutation["value"])
		changed["ram_image"] = ram
		var rejected: Dictionary = prefix.call("execute_from_next_task_dispatch", changed)
		_check(not bool(rejected.get("ok", true)),
			"near-match `%s` is rejected at the source-boundary profile" % String(mutation["name"]))


func _verify_scheduler_adoption(source_result: Dictionary, dispatch: Dictionary) -> void:
	var scheduler: RefCounted = SCHEDULER_SCRIPT.new()
	if not bool(scheduler.call("configure_from_project_sources")):
		_failures.append("Scheduler ROM source setup failed: " + String(scheduler.get("error_message")))
		return
	var bootstrap: Dictionary = scheduler.call("initialize_fresh_game_bootstrap")
	if not bool(bootstrap.get("ok", false)):
		_failures.append("Scheduler bootstrap failed: " + String(scheduler.get("error_message")))
		return
	_seed_live_slot09(scheduler, dispatch)
	var adopted: bool = scheduler.call("adopt_slot09_scenario_wait_worker_state", source_result)
	_check(adopted,
		"scheduler accepts the exact source wait result through its slot-$09 `$86F8` boundary")
	if not adopted:
		_failures.append("Exact scenario-$1C `$71` scheduler adoption was rejected: " + String(scheduler.get("error_message")))
		return
	var snapshot: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var adopted_ram: PackedByteArray = snapshot.get("ram_image", PackedByteArray())
	_check(int(snapshot.get("active_task_slot", -1)) == 0x09
		and int(snapshot.get("pc", -1)) == 0x86F8
		and adopted_ram.slice(0x0516, 0x051A) == PackedByteArray([0x71, 0x40, 0x1C, 0x1A])
		and (adopted_ram[0x005D] | (adopted_ram[0x005E] << 8)) == 0xB4A5
		and adopted_ram.slice(0x0523, 0x052B) == PackedByteArray([0x3C, 0x01, 0x02, 0xBC, 0x4A, 0x78, 0x58, 0x40]),
		"scheduler preserves the scenario-$1C event/cursor state and carries the decremented wait into `$86F8`")


func _verify_scheduler_near_miss(source_result: Dictionary, dispatch: Dictionary) -> void:
	var scheduler: RefCounted = SCHEDULER_SCRIPT.new()
	if not bool(scheduler.call("configure_from_project_sources")):
		_failures.append("Scheduler ROM source setup failed for the negative fixture")
		return
	var bootstrap: Dictionary = scheduler.call("initialize_fresh_game_bootstrap")
	if not bool(bootstrap.get("ok", false)):
		_failures.append("Scheduler bootstrap failed for the negative fixture")
		return
	var changed: Dictionary = dispatch.duplicate(true)
	var ram: PackedByteArray = (dispatch["ram_image"] as PackedByteArray).duplicate()
	ram[0x0525] = 0x00
	changed["ram_image"] = ram
	_seed_live_slot09(scheduler, changed)
	var adopted: bool = scheduler.call("adopt_slot09_scenario_wait_worker_state", source_result)
	_check(not adopted,
		"scheduler rejects the source result when the live callback phase differs from `$71/$0525=$02`")


func _verify_expired_checkpoint(prefix: RefCounted, wait_dispatch: Dictionary) -> void:
	var expired_dispatch: Dictionary = wait_dispatch.duplicate(true)
	var expired_ram: PackedByteArray = (wait_dispatch["ram_image"] as PackedByteArray).duplicate()
	expired_ram[0x0519] = 0x00
	expired_ram[0x052F] = 0x2B
	expired_ram[0x0530] = 0x1D
	expired_ram[0x0531] = 0x2C
	expired_ram[0x05D4] = 0x3C
	expired_ram[0x0636] = 0xAC
	expired_dispatch["ram_image"] = expired_ram
	_check(expired_ram[0x0519] == 0
		and expired_ram[0x05CE] == 0xA0
		and expired_ram.slice(0x0523, 0x052B) == PackedByteArray([0x3C, 0x01, 0x02, 0xBC, 0x4A, 0x78, 0x58, 0x40])
		and (expired_ram[0x005D] | (expired_ram[0x005E] << 8)) == 0xB4A5,
		"synthetic frame-9232 checkpoint retains callback-$01 parameter `$58` and map-$12 helper identity at wait zero")
	_check(bool(prefix.call("_is_scenario1c_callback01_phase71_expired_profile", expired_ram))
		and not bool(prefix.call("_is_scenario1c_callback01_phase71_waitbit_profile", expired_ram)),
		"expired-profile predicate accepts frame 9232 while the positive-wait predicate rejects it")
	_verify_expired_profile_near_misses(prefix, expired_ram)

	var result: Dictionary = prefix.call("execute_from_next_task_dispatch", expired_dispatch)
	if not bool(result.get("ok", false)):
		_failures.append("Frame-9232 expired prefix did not reach its actor-seed request: "
			+ String(result.get("reason", result.get("error", prefix.get("error_message")))))
		return
	var request: Dictionary = result.get("actor_worker_seed_request", {})
	var ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var pcs: Array = result.get("instruction_pcs", [])
	var required_pcs: Array[int] = [0xEC8C, 0xEC91, 0xEC97, 0xECC1, 0xECC7,
		0xECE6, 0x8006, 0x84A1, 0xECF4, 0xED08, 0xED0F, 0xED15]
	var cursor := 0
	for pc_variant in pcs:
		if cursor < required_pcs.size() and int(pc_variant) == required_pcs[cursor]:
			cursor += 1
	_check(String(result.get("status", "")) == "slot09_actor_worker_seed_ready_before_cae7"
		and int(result.get("exit_pc", -1)) == 0xED15
		and int(request.get("source_pc", -1)) == 0xED15
		and int(request.get("actor_parameter", -1)) == 0x58
		and int(request.get("a", -1)) == 0x58
		and cursor == required_pcs.size()
		and not bool(result.get("trace_state_used", true))
		and not bool(result.get("worker_body_executed", true)),
		"expired scenario-$1C callback-$01 reaches the ROM `$ED15` request with actor parameter `$58` and checked source-PC order")
	_check(ram.size() == 0x800
		and ram[0x0516] == 0x01 and ram[0x0518] == 0x1C and ram[0x0519] == 0x3C
		and ram[0x0529] == 0x58 and ram[0x05CE] == 0xA0
		and ram.slice(0x052E, 0x053D) == PackedByteArray([
			0x00, 0x2B, 0x1D, 0x2C, 0x00, 0x01, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x78])
		and ram.slice(0x05D1, 0x05D3) == PackedByteArray([0x00, 0x00])
		and _has_ram_write(result.get("writes", []), 0xEC91, 0x0516, 0x01)
		and _has_ram_write(result.get("writes", []), 0xEC97, 0x0519, 0x3C)
		and _has_ram_write(result.get("writes", []), 0xECBE, 0x0526, 0x3C)
		and _has_ram_write(result.get("writes", []), 0xECF4, 0x05D2, 0x00)
		and _has_ram_write(result.get("writes", []), 0xED0F, 0x0517, 0x40),
		"expired callback source writes restore the wait/event state and preserve the ROM-derived `$A0/$58` actor parameters")


func _verify_expired_profile_near_misses(prefix: RefCounted, expired_ram: PackedByteArray) -> void:
	var mutations: Array[Dictionary] = [
		{"name": "event selector", "address": 0x0524, "value": 0x35},
		{"name": "event phase", "address": 0x0525, "value": 0x00},
		{"name": "map ID", "address": 0x05CC, "value": 0x13},
		{"name": "map placement", "address": 0x05CD, "value": 0xA0},
		{"name": "helper selector", "address": 0x05D2, "value": 0x00},
	]
	for mutation in mutations:
		var changed := expired_ram.duplicate()
		changed[int(mutation["address"])] = int(mutation["value"])
		_check(not bool(prefix.call("_is_scenario1c_callback01_phase71_expired_profile", changed)),
			"expired profile rejects changed %s identity" % String(mutation["name"]))


func _seed_live_slot09(scheduler: RefCounted, dispatch: Dictionary) -> void:
	var ram: PackedByteArray = (dispatch["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (dispatch["stack_page"] as PackedByteArray).duplicate()
	scheduler.set("_ram", ram)
	scheduler.set("_stack_page", stack)
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


func _has_ram_write(writes: Array, pc: int, address: int, value: int) -> bool:
	for write_variant in writes:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("pc", -1)) == pc and int(write.get("address", -1)) == address \
				and int(write.get("value", -1)) == value:
			return true
	return false


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures.append(description)


func _fail(message: String) -> void:
	_failures.append(message)
