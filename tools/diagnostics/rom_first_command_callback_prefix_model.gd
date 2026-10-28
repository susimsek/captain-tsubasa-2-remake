extends RefCounted
## Diagnostic-only source prefix for scenario-$44 → callback-$70 → $8327.
## It does not schedule tasks, execute the callback worker, or feed captures
## into route state. Keep separate from the fixed-bank scheduler model.

const READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const STACK_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_continuation_stack.gd")
const CALLBACK_API_SCRIPT := preload("res://scripts/gameplay/rom_first_command_callback_dispatch_api.gd")

const SCENARIO_44_CPU := 0xB7D5
const SCENARIO_44_EXPECTED := [0x02, 0x70, 0x5C, 0xF0, 0xFB]
const CALLBACK_70_CPU := 0x8B38
const CALLBACK_70_PREFIX := [0x06, 0x00, 0x56]
const CALLBACK_70_FIRST_HANDLER_CPU := 0x8327
const F015_CODE_PATH := "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_1f_f015_f159_code.bin"
const F015_CODE_SHA256 := "df7c650c952fb5dfc9a8a10de43f739c9fc4cbdef343bae7ba70c4921a281dc9"
const F015_INDEX_LOOP_OFFSET := 0x7F
const F015_INDEX_LOOP_BYTES := [
	0x68, 0x18, 0x69, 0x01, 0xC9, 0x06, 0xF0, 0x03, 0x4C, 0x15, 0xF0,
]

var error_message := ""
var _f015_code := PackedByteArray()


## Resolve only the ROM-owned prefix. `stack_payload` is explicit harness input;
## depth zero means root `$FB` does not consume or restore those bytes.
func resolve_scenario44_callback_prefix(stack_payload: PackedByteArray) -> Dictionary:
	error_message = ""
	if stack_payload.size() != 8:
		return _fail_result("The continuation harness requires exactly eight caller-owned payload bytes ($051A-$0521).")

	var scenario: Dictionary = READER_SCRIPT.read_project_scenario(0x44, {"continuation_depth": 0})
	if int(scenario.get("terminal_status", -1)) != int(READER_SCRIPT.ParseStatus.SOURCE_TERMINATED):
		return _fail_result("The preserved scenario-$44 stream did not terminate at root depth zero.")
	if int(scenario.get("next_byte_offset", -1)) != 5:
		return _fail_result("Scenario-$44 source cursor did not stop immediately after its five-byte span.")
	var scenario_bytes := FileAccess.get_file_as_bytes(READER_SCRIPT.SOURCE_PATHS[0x44])
	if scenario_bytes != PackedByteArray(SCENARIO_44_EXPECTED):
		return _fail_result("Scenario-$44 bytes differ from the preserved 02 70 5C F0 FB stream.")
	var fb_token := _find_fb_token(scenario.get("tokens", []))
	if fb_token.is_empty() or int(fb_token.get("byte_offset", -1)) != 4:
		return _fail_result("Scenario-$44 root $FB token is missing at source offset four.")

	var stack_model: RefCounted = STACK_SCRIPT.new()
	var initialized: Dictionary = stack_model.call("initialize_from_source_scenario_start", stack_payload)
	if not bool(initialized.get("ok", false)):
		return _fail_result("Source scenario-start stack initialization failed: " + str(initialized.get("error", stack_model.get("error_message"))))
	var root_return: Dictionary = stack_model.call("execute_fb", SCENARIO_44_CPU, 5,
		int(initialized.get("stack_depth", -1)), initialized.get("stack_memory", PackedByteArray()))
	if not bool(root_return.get("ok", false)) or str(root_return.get("status", "")) != "scenario_termination":
		return _fail_result("Root $FB did not terminate through the bounded source-stack helper.")
	if root_return.get("stack_memory_after", PackedByteArray()) != stack_payload:
		return _fail_result("Depth-zero root $FB unexpectedly changed caller-owned stack payload bytes.")

	var callback_api: RefCounted = CALLBACK_API_SCRIPT.new()
	var callback: Dictionary = callback_api.call("resolve_scenario_44_callback")
	if not bool(callback.get("ok", false)):
		return _fail_result("Scenario-$44 callback source resolution failed: " + str(callback.get("error", callback_api.get("error_message"))))
	var first: Dictionary = callback.get("first_callback_command", {})
	var stream: PackedByteArray = callback.get("callback_stream", PackedByteArray())
	if int(callback.get("callback_pointer_cpu", -1)) != CALLBACK_70_CPU or \
			stream.slice(0, 3) != PackedByteArray(CALLBACK_70_PREFIX) or \
			int(first.get("handler_cpu", -1)) != CALLBACK_70_FIRST_HANDLER_CPU:
		return _fail_result("Callback-$70 source cursor no longer resolves offsets 0/1/2 to $06/$00/$56 and handler $8327.")

	var missing_placement: Dictionary = callback_api.call("compute_8327_placement_transition", -1)
	if bool(missing_placement.get("ok", true)) or str(missing_placement.get("status", "")) != "source_state_required":
		return _fail_result("The callback API no longer requires the caller-owned incoming global $05CD.")
	return {
		"ok": true,
		"status": "source_prefix_resolved_waiting_for_route_state",
		"scenario": {
			"cpu_pointer": SCENARIO_44_CPU,
			"source_bytes": scenario_bytes,
			"record_cursor_start": 0,
			"record_cursor_after": 4,
			"root_fb_cursor": 4,
			"source_cursor_after_fb": int(scenario.get("next_byte_offset", -1)),
			"stack_depth_before_fb": 0,
			"stack_depth_after_fb": int(root_return.get("stack_depth_after", -1)),
			"stack_payload_preserved": true,
			"outer_cpu_task_return_modeled": false,
		},
		"callback": {
			"pointer_cpu": CALLBACK_70_CPU,
			"cursor_003a": 0,
			"read_offsets": [0, 1, 2],
			"read_bytes": PackedByteArray(CALLBACK_70_PREFIX),
			"command_0525": 0x06,
			"dispatch_subindex": 0x00,
			"map_selector": 0x56,
			"handler_cpu": CALLBACK_70_FIRST_HANDLER_CPU,
			"unresolved_tail": callback.get("unresolved_callback_tail", PackedByteArray()),
		},
		"missing_predecessor_state": {
			"required": ["global $05CD immediately before $8327", "callback task/stack/bank context", "worker continuation state"],
			"status": str(missing_placement.get("status", "")),
		},
		"scheduler_or_worker_executed": false,
		"f015_causal_link_from_callback_proven": false,
		"trace_inputs_used": false,
	}


## Decode the bounded `$F094-$F09E` index recurrence for an explicit entry A.
## Source bytes establish increment-and-stop-at-six, but not who supplies the
## initial A for this route; no trace value is defaulted here.
func derive_f015_entry_indices(initial_a: int) -> Dictionary:
	error_message = ""
	if initial_a < 0 or initial_a > 5:
		return _fail_result("The bounded F015 loop model accepts an explicit initial A in 0..5 only.")
	if not _load_f015_code():
		return _fail_result(error_message)
	if _f015_code.slice(F015_INDEX_LOOP_OFFSET,
			F015_INDEX_LOOP_OFFSET + F015_INDEX_LOOP_BYTES.size()) != PackedByteArray(F015_INDEX_LOOP_BYTES):
		return _fail_result("The preserved F015 loop instructions at CPU $F094 no longer match the verified sequence.")
	var indices: Array[int] = []
	var accumulator := initial_a
	while true:
		indices.append(accumulator)
		accumulator = (accumulator + 1) & 0xFF
		if accumulator == 6:
			break
		if indices.size() >= 6:
			return _fail_result("F015 loop did not reach its source terminal comparison within six route indices.")
	return {
		"ok": true,
		"entry_a": initial_a,
		"indices": indices,
		"terminal_a": accumulator,
		"source_loop_cpu": 0xF094,
		"source_loop_offset": F015_INDEX_LOOP_OFFSET,
		"initial_a_source_proven": false,
		"route_caller_modeled": false,
	}


func _load_f015_code() -> bool:
	if not _f015_code.is_empty():
		return true
	if not FileAccess.file_exists(F015_CODE_PATH):
		return _fail("Preserved F015 source code span is missing.")
	_f015_code = FileAccess.get_file_as_bytes(F015_CODE_PATH)
	if _sha256(_f015_code) != F015_CODE_SHA256:
		_f015_code.clear()
		return _fail("Preserved F015 source code failed its ROM hash check.")
	return true


func _find_fb_token(tokens_variant: Variant) -> Dictionary:
	if not tokens_variant is Array:
		return {}
	for token_variant in tokens_variant:
		if token_variant is Dictionary and int(token_variant.get("opcode", -1)) == 0xFB:
			return token_variant
	return {}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _fail_result(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_resolution_failed", "error": message}
