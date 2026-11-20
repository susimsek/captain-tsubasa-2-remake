extends SceneTree
## Focused scheduler verifier for ordinary PASS scenario-$38 `$EB8B->$86F8`.
## The RAM/stack boundary is a clearly marked synthetic fixture derived from
## the route's observed live signature; it is not a persisted full-state capture.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const PREFIX_SCRIPT := preload("res://scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dispatch := _make_live_pass_dispatch()
	var prefix: RefCounted = PREFIX_SCRIPT.new()
	_check(bool(prefix.call("configure_from_project_sources")),
		"slot-$09 prefix ROM spans and manifest validate")
	if not _failures.is_empty():
		_finish()
		return
	var source_result: Dictionary = prefix.call("execute_from_next_task_dispatch", dispatch)
	_check(bool(source_result.get("ok", false))
		and String(source_result.get("status", "")) == "stopped_before_worker_body"
		and int(source_result.get("entry_pc", -1)) == 0xEB8B
		and int(source_result.get("exit_pc", -1)) == 0x86F8
		and not bool(source_result.get("trace_state_used", true))
		and not bool(source_result.get("worker_body_executed", true)),
		"ROM-byte prefix reaches `$86F8` without worker execution or emulator state"
			+ _source_detail(source_result))
	if bool(source_result.get("ok", false)):
		_verify_successful_adoption(dispatch, source_result)
		_verify_zero_count_adoption(dispatch, source_result)
		_verify_afee_stream_pointer_adoption(dispatch, source_result)
		_verify_aff1_stream_pointer_adoption(dispatch, source_result)
		_verify_aff4_selector_pointer_adoption(dispatch, source_result)
		_verify_scratch_cursor_adoption(dispatch, source_result)
		_verify_near_match_rejected(dispatch, source_result)
	_finish()


func _verify_successful_adoption(dispatch: Dictionary, source_result: Dictionary) -> void:
	var scheduler := _make_scheduler(dispatch)
	if scheduler == null:
		return
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", source_result)
	if not adopted:
		_failures.append("Exact live-PASS fixture was rejected: " + String(scheduler.get("error_message")))
		return
	var boundary: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	_check(int(boundary.get("active_task_slot", -1)) == 0x09
		and int(boundary.get("pc", -1)) == 0x86F8
		and int(boundary.get("sp", -1)) == 0x78
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x00, 0x40, 0x38, 0x00])
		and ram[0x0441] == 0x06 and ram[0x0532] == 0x01 and ram[0x0533] == 0x03
		and (ram[0x0079] | (ram[0x007A] << 8)) == 0xAFE9
		and ram[0x003A] == 0x06 and ram[0x0498] == 0x00
		and ram.slice(0x0499, 0x04A0) == PackedByteArray([0x00, 0x6C, 0x04, 0x00, 0x6C, 0x04, 0x00])
		and ram[0x047F] == 0x0F,
		"scheduler adopts the full ROM replay and exposes the live PASS state at `$86F8`")


func _verify_scratch_cursor_adoption(dispatch: Dictionary, source_result: Dictionary) -> void:
	var scratch_dispatch := dispatch.duplicate(true)
	var dispatch_ram: PackedByteArray = scratch_dispatch["ram_image"].duplicate()
	dispatch_ram[0x003A] = 0x0F
	scratch_dispatch["ram_image"] = dispatch_ram
	var scratch_result := source_result.duplicate(true)
	var result_ram: PackedByteArray = scratch_result["ram_image"].duplicate()
	result_ram[0x003A] = 0x0F
	scratch_result["ram_image"] = result_ram
	var scheduler := _make_scheduler(scratch_dispatch)
	if scheduler == null:
		return
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", scratch_result)
	if not adopted:
		_failures.append("The live `$86F8` prefix incorrectly depends on unused `$003A`: " \
			+ String(scheduler.get("error_message")))
		return
	var boundary: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	_check(ram.size() == 0x800 and ram[0x003A] == 0x0F,
		"scheduler adopts and preserves the source scratch value without normalizing it")


func _verify_zero_count_adoption(dispatch: Dictionary, source_result: Dictionary) -> void:
	var zero_dispatch := dispatch.duplicate(true)
	var dispatch_ram: PackedByteArray = zero_dispatch["ram_image"].duplicate()
	dispatch_ram[0x0533] = 0x00
	zero_dispatch["ram_image"] = dispatch_ram
	var zero_result := source_result.duplicate(true)
	var result_ram: PackedByteArray = zero_result["ram_image"].duplicate()
	result_ram[0x0533] = 0x00
	zero_result["ram_image"] = result_ram
	var scheduler := _make_scheduler(zero_dispatch)
	if scheduler == null:
		return
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", zero_result)
	if not adopted:
		_failures.append("The live zero-count `$86F8->$8722` stream-reader phase was rejected: " \
			+ String(scheduler.get("error_message")))
		return
	var boundary: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	_check(ram.size() == 0x800 and ram[0x0533] == 0x00
		and int(boundary.get("pc", -1)) == 0x86F8,
		"scheduler admits the source zero-count phase without normalizing `$0533`")


func _verify_afee_stream_pointer_adoption(dispatch: Dictionary, source_result: Dictionary) -> void:
	var next_batch_dispatch := dispatch.duplicate(true)
	var dispatch_ram: PackedByteArray = next_batch_dispatch["ram_image"].duplicate()
	dispatch_ram[0x0079] = 0xEE
	dispatch_ram[0x007A] = 0xAF
	dispatch_ram[0x0533] = 0x01
	next_batch_dispatch["ram_image"] = dispatch_ram
	var next_batch_result := source_result.duplicate(true)
	var result_ram: PackedByteArray = next_batch_result["ram_image"].duplicate()
	result_ram[0x0079] = 0xEE
	result_ram[0x007A] = 0xAF
	result_ram[0x0533] = 0x01
	next_batch_result["ram_image"] = result_ram
	var scheduler := _make_scheduler(next_batch_dispatch)
	if scheduler == null:
		return
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", next_batch_result)
	if not adopted:
		_failures.append("The source `$AFEE` continuation was rejected by live scenario adoption: " \
			+ String(scheduler.get("error_message")))
		return
	var boundary: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	_check(ram.size() == 0x800 and (ram[0x0079] | (ram[0x007A] << 8)) == 0xAFEE
		and ram[0x0533] == 0x01,
		"scheduler adopts the next ROM stream pointer and its live countdown unchanged")


func _verify_aff1_stream_pointer_adoption(dispatch: Dictionary, source_result: Dictionary) -> void:
	var next_group_dispatch := dispatch.duplicate(true)
	var dispatch_ram: PackedByteArray = next_group_dispatch["ram_image"].duplicate()
	dispatch_ram[0x0079] = 0xF1
	dispatch_ram[0x007A] = 0xAF
	dispatch_ram[0x0533] = 0x07
	next_group_dispatch["ram_image"] = dispatch_ram
	var next_group_result := source_result.duplicate(true)
	var result_ram: PackedByteArray = next_group_result["ram_image"].duplicate()
	result_ram[0x0079] = 0xF1
	result_ram[0x007A] = 0xAF
	result_ram[0x0533] = 0x07
	next_group_result["ram_image"] = result_ram
	var scheduler := _make_scheduler(next_group_dispatch)
	if scheduler == null:
		return
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", next_group_result)
	if not adopted:
		_failures.append("The source `$AFF1` continuation was rejected by live scenario adoption: " \
			+ String(scheduler.get("error_message")))
		return
	var boundary: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	_check(ram.size() == 0x800 and (ram[0x0079] | (ram[0x007A] << 8)) == 0xAFF1
		and ram[0x0533] == 0x07,
		"scheduler preserves the next ROM batch pointer and countdown-seven phase")


func _verify_aff4_selector_pointer_adoption(dispatch: Dictionary, source_result: Dictionary) -> void:
	var selector_dispatch := dispatch.duplicate(true)
	var dispatch_ram: PackedByteArray = selector_dispatch["ram_image"].duplicate()
	dispatch_ram[0x0079] = 0xF4
	dispatch_ram[0x007A] = 0xAF
	dispatch_ram[0x0533] = 0x02
	selector_dispatch["ram_image"] = dispatch_ram
	var selector_result := source_result.duplicate(true)
	var result_ram: PackedByteArray = selector_result["ram_image"].duplicate()
	result_ram[0x0079] = 0xF4
	result_ram[0x007A] = 0xAF
	result_ram[0x0533] = 0x02
	selector_result["ram_image"] = result_ram
	var scheduler := _make_scheduler(selector_dispatch)
	if scheduler == null:
		return
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", selector_result)
	if not adopted:
		_failures.append("The source `$AFF4` selector countdown was rejected by live scenario adoption: " \
			+ String(scheduler.get("error_message")))
		return
	var boundary: Dictionary = scheduler.call("get_task_boundary_snapshot", 0x09)
	var ram: PackedByteArray = boundary.get("ram_image", PackedByteArray())
	_check(ram.size() == 0x800 and (ram[0x0079] | (ram[0x007A] << 8)) == 0xAFF4
		and ram[0x0533] == 0x02,
		"scheduler admits the ROM-derived selector countdown at `$AFF4` unchanged")


func _verify_near_match_rejected(dispatch: Dictionary, source_result: Dictionary) -> void:
	var scheduler := _make_scheduler(dispatch)
	if scheduler == null:
		return
	var near_match := source_result.duplicate(true)
	var ram: PackedByteArray = near_match["ram_image"].duplicate()
	ram[0x0441] = 0x0A
	near_match["ram_image"] = ram
	var adopted: bool = scheduler.call(
		"adopt_slot09_live_pass_scenario38_worker_vector_state", near_match)
	_check(not adopted,
		"prefix with a transferred holder `$0A` is rejected before scheduler mutation")


func _make_scheduler(dispatch: Dictionary) -> RefCounted:
	var scheduler: RefCounted = SCHEDULER_SCRIPT.new()
	if not bool(scheduler.call("configure_from_project_sources")):
		_failures.append("Scheduler ROM source setup failed: " + String(scheduler.get("error_message")))
		return null
	var bootstrap: Dictionary = scheduler.call("initialize_fresh_game_bootstrap")
	if not bool(bootstrap.get("ok", false)):
		_failures.append("Scheduler bootstrap failed: " + String(scheduler.get("error_message")))
		return null
	scheduler.set("_ram", dispatch["ram_image"].duplicate())
	scheduler.set("_stack_page", dispatch["stack_page"].duplicate())
	scheduler.set("_active_task_slot", 0x09)
	var contexts: Dictionary = scheduler.get("_contexts")
	var context: Object = contexts.get(0x09)
	if context == null:
		_failures.append("Initialized scheduler has no root slot-$09 context")
		return null
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
	context.set("mapper_state", {"bank_low": 0x18, "bank_high": 0x19,
		"select": 0x07, "bank_registers": {6: 0x18, 7: 0x19}})
	return scheduler


func _make_live_pass_dispatch() -> Dictionary:
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
	ram[0x0441] = 0x06
	ram[0x047F] = 0x0F
	ram[0x0498] = 0x00
	ram[0x0499] = 0x00
	ram[0x049A] = 0x6C
	ram[0x049B] = 0x04
	ram[0x049C] = 0x00
	ram[0x049D] = 0x6C
	ram[0x049E] = 0x04
	ram[0x049F] = 0x00
	ram[0x0516] = 0x00
	ram[0x0517] = 0x40
	ram[0x0518] = 0x38
	ram[0x0519] = 0x00
	ram[0x0532] = 0x01
	ram[0x0533] = 0x03
	var stack := PackedByteArray()
	stack.resize(0x100)
	stack[0x77] = 0x05
	stack[0x78] = 0x78
	stack[0x79] = 0x8A
	stack[0x7A] = 0xEB
	for offset in range(4):
		ram[0x0177 + offset] = stack[0x77 + offset]
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


func _source_detail(result: Dictionary) -> String:
	if bool(result.get("ok", false)):
		return ""
	return ": " + String(result.get("reason", "prefix source execution failed"))


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures.append(description)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: scheduler adopts the ordinary PASS scenario-$38 `$EB8B->$86F8` source prefix.")
		print("LIMIT: scheduler pre-state is a marked synthetic RAM/stack fixture; full recorded-input route remains the live boundary check.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
