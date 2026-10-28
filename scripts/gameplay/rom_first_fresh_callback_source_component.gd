extends RefCounted
class_name RomFirstFreshCallbackSourceComponent
## Bounded source projection for the first fresh-route scenario-$35 callback.
## It derives the callback's input $05CD through the ROM $AA06 fill routine,
## but stops before cooperative callback-task dispatch/yield/resume.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const CALLBACK_ROOT := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/"
const FRESH_SETUP_ROOT := "res://reference/rom_extract/gameplay/fresh_match_handoff/"
const CALLBACK_SOURCE_HASHES := {
	"bank_0b_event_3a_pointer_boundary.bin": "c4bf5bc239937e437da70f6a20ffa3eee46ef5694b7f1fd38115a5d693e209a0",
	"bank_0b_event_3a_stream.bin": "f619833b71e98ee35083a2777d7d6ef697470576a132939ea610025f7d7b32d8",
	"bank_0b_dispatch_vector_81a7.bin": "663e41116c23b455e418b531b39024bdc5a0c71fc022009926e8cf541f1d35c9",
}
const FRESH_SETUP_HASH := "cf3001b1d6b6413c2b69aa9c00b8383ccaa8a034cfd61ca1e6ebbfd97da03f45"
const ZERO_FILL_HELPER_HASH := "b4087f492a7a3ffb3737c7a42fd1b7fe5cf82147eab7c80eddc331740b6c38fd"
const SCENARIO_READER := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const CALLBACK_SEED_EXECUTOR := preload("res://scripts/gameplay/rom_fresh_kickoff_callback_seed_executor.gd")
const FIELD_PACKET_PRODUCER := preload("res://scripts/gameplay/first_command_field_packet_producer.gd")
const CALLBACK_POINTER_ADDRESS := 0x886A
const CALLBACK_STREAM_ADDRESS := 0x89F3
const CALLBACK_NEXT_ADDRESS := 0x89F6
const CALLBACK_HANDLER_ADDRESS := 0x8327
const ZERO_FILL_START := 0x0468
const RAM_SIZE := 0x0800

var error_message := ""
var _configured := false
var _callback_sources: Dictionary = {}
var _fresh_setup := PackedByteArray()
var _zero_fill_helper := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_callback_sources.clear()
	if not _load_callback_sources():
		return false
	if not _load_fresh_setup_sources():
		return false
	_configured = true
	return true


## Resolves the first $35/$3A operation and projects its $8327 state transition.
## The callback task is seeded from its source caller, but task dispatch and
## the $856F→$C515/$CB0F yield/resume are deliberately not executed here.
func project_first_callback_transition() -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var scenario: Dictionary = SCENARIO_READER.read_project_scenario(0x35,
		{"continuation_depth": 0})
	if int(scenario.get("terminal_status", -1)) != SCENARIO_READER.ParseStatus.SOURCE_TERMINATED:
		return _failure("Scenario $35 failed its preserved source/terminator checks.")
	var event_record := _first_event_record(scenario.get("tokens", []))
	var raw_event: PackedByteArray = event_record.get("raw_bytes", PackedByteArray())
	if int(event_record.get("byte_offset", -1)) != 3 \
			or raw_event != PackedByteArray([0x02, 0x3A, 0x8F, 0x73]):
		return _failure("The first fresh scenario event is not the source record 02 3A 8F 73 at byte offset 3.")

	var seed_executor: RefCounted = CALLBACK_SEED_EXECUTOR.new()
	if not bool(seed_executor.call("configure")):
		return _failure("The source callback-task seed helper could not initialize: " + str(seed_executor.get("error_message")))
	var seed_result: Dictionary = seed_executor.call("accept_first_scenario_event", 0x8097)
	if not bool(seed_result.get("ok", false)):
		return _failure("Scenario $35 did not seed the source callback task: " + str(seed_result.get("error", "unknown source error")))

	var callback_resolution := _resolve_callback_3a(raw_event)
	if not bool(callback_resolution.get("ok", false)):
		return _failure(str(callback_resolution.get("error", "Callback $3A source resolution failed.")))
	var zero_fill := _execute_fresh_setup_zero_fill()
	if not bool(zero_fill.get("ok", false)):
		return _failure(str(zero_fill.get("error", "Fresh setup zero fill failed.")))
	var source_ram: PackedByteArray = zero_fill.get("ram", PackedByteArray())
	var incoming_05cd := int(source_ram[0x05CD])
	var packet_producer: RefCounted = FIELD_PACKET_PRODUCER.new()
	var transition: Dictionary = packet_producer.call("advance_map_placement_state", incoming_05cd)
	if not bool(transition.get("ok", false)):
		return _failure("The ROM $8327 placement formula refused the source-derived $05CD value: " + str(transition.get("error", "unknown")))

	return {
		"ok": true,
		"status": "source_projection_waiting_for_task_body",
		"rom_sha256": ROM_SHA256,
		"scenario": {
			"id": 0x35,
			"event_record_offset": 3,
			"event_bytes": raw_event,
			"callback_id": 0x3A,
			"actor_animation_id": 0x8F,
			"animation_parameter": 0x73,
		},
		"callback_task_seed": seed_result,
		"callback": callback_resolution,
		"fresh_setup_zero_fill": _zero_fill_public_result(zero_fill),
		"incoming_05cd_source_value": incoming_05cd,
		"handler_transition_if_dispatched": transition,
		"callback_handler_executed": false,
		"yield_resume_executed": false,
		"source_boundary": "The initial scheduler scan still selects root slot $01. Root-task continuations/NMI cadence, callback slot $15 dispatch, $8327 worker progress, and the $856F→$C515/$CB0F yield/resume are not executed; this is a source plan, not a live route event.",
		"trace_data_used_as_runtime_input": false,
	}


func _resolve_callback_3a(event_bytes: PackedByteArray) -> Dictionary:
	var pointers: PackedByteArray = _callback_sources["bank_0b_event_3a_pointer_boundary.bin"]
	var callback_bytes: PackedByteArray = _callback_sources["bank_0b_event_3a_stream.bin"]
	var vector: PackedByteArray = _callback_sources["bank_0b_dispatch_vector_81a7.bin"]
	var selector := int(event_bytes[1])
	if selector != 0x3A or CALLBACK_POINTER_ADDRESS != 0x87F6 + selector * 2:
		return {"ok": false, "error": "Callback $3A pointer-table index no longer maps to $886A."}
	var target := int(pointers[0]) | (int(pointers[1]) << 8)
	var next_target := int(pointers[2]) | (int(pointers[3]) << 8)
	if target != CALLBACK_STREAM_ADDRESS or next_target != CALLBACK_NEXT_ADDRESS:
		return {"ok": false, "error": "Callback $3A pointer or the following $3B boundary changed."}
	if next_target - target != callback_bytes.size() \
			or callback_bytes != PackedByteArray([0x02, 0x00, 0x42]):
		return {"ok": false, "error": "Callback $3A's pointer-bounded first operation is not 02 00 42."}
	var dispatch_target := int(vector[3]) | (int(vector[4]) << 8)
	if dispatch_target != CALLBACK_HANDLER_ADDRESS:
		return {"ok": false, "error": "Bank-$0B inline-vector entry zero no longer resolves to $8327."}
	return {
		"ok": true,
		"pointer_table_address": CALLBACK_POINTER_ADDRESS,
		"stream_address": target,
		"next_pointer_boundary": next_target,
		"stream_bytes": callback_bytes,
		"command_0525": int(callback_bytes[0]),
		"dispatch_subindex": int(callback_bytes[1]),
		"handler_pc": dispatch_target,
		"map_selector": int(callback_bytes[2]),
		"handler_entry_provenance": "ROM $81A7 inline vector index 0",
	}


## Executes only the exact AA06 subroutine needed to establish $05CD/$05CE.
## Registers are decoded from the verified A2AF caller bytes; all stores and
## branches follow the preserved AA06 instruction bytes.
func _execute_fresh_setup_zero_fill() -> Dictionary:
	var caller_slice := _fresh_setup.slice(0x29, 0x36)
	if caller_slice != PackedByteArray([
		0xA9, 0x98, 0xA2, 0x02, 0xA0, 0x68, 0x84, 0xEC,
		0xA0, 0x04, 0x20, 0x06, 0xAA,
	]):
		return {"ok": false, "error": "Fresh setup A2AF caller does not provide the verified $AA06 inputs."}
	var ram := PackedByteArray()
	ram.resize(RAM_SIZE)
	ram.fill(0)
	var a := int(caller_slice[1])
	var x := int(caller_slice[3])
	var y := int(caller_slice[9])
	var ec := int(caller_slice[5])
	var ed := y
	var stack: Array[int] = []
	var pc := 0
	var stores := 0
	var lowest_address := RAM_SIZE
	var highest_address := -1
	var branch_counts := {"inner_taken": 0, "inner_exit": 0, "outer_taken": 0, "outer_exit": 0}
	var step_limit := 10000
	while pc < _zero_fill_helper.size() and step_limit > 0:
		step_limit -= 1
		match pc:
			0: # STY $ED
				if not _bytes_at(_zero_fill_helper, pc, [0x84, 0xED]):
					return {"ok": false, "error": "Unexpected AA06 STY $ED instruction."}
				ed = y
				pc = 2
			2: # INX
				if int(_zero_fill_helper[pc]) != 0xE8:
					return {"ok": false, "error": "Unexpected AA06 INX instruction."}
				x = (x + 1) & 0xFF
				pc = 3
			3: # LDY #$00
				if not _bytes_at(_zero_fill_helper, pc, [0xA0, 0x00]):
					return {"ok": false, "error": "Unexpected AA06 LDY #$00 instruction."}
				y = 0
				pc = 5
			5: # PHA
				if int(_zero_fill_helper[pc]) != 0x48:
					return {"ok": false, "error": "Unexpected AA06 PHA instruction."}
				stack.append(a)
				pc = 6
			6: # LDA #$00
				if not _bytes_at(_zero_fill_helper, pc, [0xA9, 0x00]):
					return {"ok": false, "error": "Unexpected AA06 LDA #$00 instruction."}
				a = 0
				pc = 8
			8: # STA ($EC),Y
				if not _bytes_at(_zero_fill_helper, pc, [0x91, 0xEC]):
					return {"ok": false, "error": "Unexpected AA06 STA ($EC),Y instruction."}
				var address := (((ed << 8) | ec) + y) & 0xFFFF
				if address >= RAM_SIZE:
					return {"ok": false, "error": "AA06 write escaped the $0000-$07FF internal RAM window."}
				ram[address] = a
				stores += 1
				lowest_address = mini(lowest_address, address)
				highest_address = maxi(highest_address, address)
				pc = 10
			10: # INC $EC
				if not _bytes_at(_zero_fill_helper, pc, [0xE6, 0xEC]):
					return {"ok": false, "error": "Unexpected AA06 INC $EC instruction."}
				ec = (ec + 1) & 0xFF
				pc = 12
			12: # BNE +2
				if not _bytes_at(_zero_fill_helper, pc, [0xD0, 0x02]):
					return {"ok": false, "error": "Unexpected AA06 inner BNE instruction."}
				if ec != 0:
					branch_counts["inner_taken"] += 1
					pc = 16
				else:
					branch_counts["inner_exit"] += 1
					pc = 14
			14: # INC $ED (only on low-byte wrap)
				if not _bytes_at(_zero_fill_helper, pc, [0xE6, 0xED]):
					return {"ok": false, "error": "Unexpected AA06 INC $ED instruction."}
				ed = (ed + 1) & 0xFF
				pc = 16
			16: # PLA
				if int(_zero_fill_helper[pc]) != 0x68 or stack.is_empty():
					return {"ok": false, "error": "Unexpected AA06 PLA or unbalanced stack state."}
				a = stack.pop_back()
				pc = 17
			17: # SEC
				if int(_zero_fill_helper[pc]) != 0x38:
					return {"ok": false, "error": "Unexpected AA06 SEC instruction."}
				pc = 18
			18: # SBC #$01; SEC guarantees no borrow.
				if not _bytes_at(_zero_fill_helper, pc, [0xE9, 0x01]):
					return {"ok": false, "error": "Unexpected AA06 SBC #$01 instruction."}
				a = (a - 1) & 0xFF
				pc = 20
			20: # BNE back to PHA
				if not _bytes_at(_zero_fill_helper, pc, [0xD0, 0xEF]):
					return {"ok": false, "error": "Unexpected AA06 inner-loop branch."}
				if a != 0:
					branch_counts["inner_taken"] += 1
					pc = 5
				else:
					branch_counts["inner_exit"] += 1
					pc = 22
			22: # DEX
				if int(_zero_fill_helper[pc]) != 0xCA:
					return {"ok": false, "error": "Unexpected AA06 DEX instruction."}
				x = (x - 1) & 0xFF
				pc = 23
			23: # BNE back to PHA; the source does not reload A.
				if not _bytes_at(_zero_fill_helper, pc, [0xD0, 0xEC]):
					return {"ok": false, "error": "Unexpected AA06 outer-loop branch."}
				if x != 0:
					branch_counts["outer_taken"] += 1
					pc = 5
				else:
					branch_counts["outer_exit"] += 1
					pc = 25
			_:
				return {"ok": false, "error": "AA06 control reached unmodeled byte offset %d." % pc}
	if step_limit <= 0 or pc != _zero_fill_helper.size() or not stack.is_empty():
		return {"ok": false, "error": "AA06 did not return cleanly within the bounded instruction loop."}
	return {
		"ok": true,
		"ram": ram,
		"initial_registers": {"a": int(caller_slice[1]), "x": int(caller_slice[3]), "y": int(caller_slice[9]), "ec": int(caller_slice[5])},
		"final_registers": {"a": a, "x": x, "y": y, "ec": ec, "ed": ed},
		"start_address": ZERO_FILL_START,
		"end_address_exclusive": (ed << 8) | ec,
		"store_count": stores,
		"lowest_address": lowest_address,
		"highest_address": highest_address,
		"write_index_05cd": 0x05CD - ZERO_FILL_START,
		"write_index_05ce": 0x05CE - ZERO_FILL_START,
		"branch_counts": branch_counts,
	}


func _load_callback_sources() -> bool:
	var manifest_path := CALLBACK_ROOT + "manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return _fail("Callback-dispatch provenance manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary or str(parsed.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Callback-dispatch manifest targets a different ROM revision.")
	var entries: Dictionary = {}
	for row_variant in parsed.get("entries", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			entries[str(row.get("path", ""))] = row
	for name_variant in CALLBACK_SOURCE_HASHES:
		var name := str(name_variant)
		var expected_hash := str(CALLBACK_SOURCE_HASHES[name_variant])
		if not entries.has(name):
			return _fail("Callback manifest omits %s." % name)
		var row: Dictionary = entries[name]
		var bytes := FileAccess.get_file_as_bytes(CALLBACK_ROOT + name)
		if str(row.get("sha256", "")) != expected_hash or FileAccess.get_sha256(CALLBACK_ROOT + name) != expected_hash \
				or bytes.size() != int(row.get("size_bytes", -1)):
			return _fail("Callback source span failed its manifest/hash check: %s." % name)
		_callback_sources[name] = bytes
	return true


func _load_fresh_setup_sources() -> bool:
	var manifest_path := FRESH_SETUP_ROOT + "manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return _fail("Fresh-match setup source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary or str(parsed.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Fresh-match setup manifest targets a different ROM revision.")
	for entry_variant in parsed.get("spans", []):
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		var name := str(entry.get("file", ""))
		if name == "bank82_fresh_match_setup_A2AF_A2E7.bin":
			_fresh_setup = FileAccess.get_file_as_bytes(FRESH_SETUP_ROOT + name)
			if _fresh_setup.size() != int(entry.get("length", -1)) \
					or FileAccess.get_sha256(FRESH_SETUP_ROOT + name) != FRESH_SETUP_HASH \
					or str(entry.get("sha256", "")) != FRESH_SETUP_HASH:
				return _fail("Fresh-match A2AF caller source failed its size/hash check.")
		elif name == "bank82_zero_fill_AA06_AA1E.bin":
			_zero_fill_helper = FileAccess.get_file_as_bytes(FRESH_SETUP_ROOT + name)
			if _zero_fill_helper.size() != int(entry.get("length", -1)) \
					or FileAccess.get_sha256(FRESH_SETUP_ROOT + name) != ZERO_FILL_HELPER_HASH \
					or str(entry.get("sha256", "")) != ZERO_FILL_HELPER_HASH:
				return _fail("AA06 zero-fill source failed its size/hash check.")
	if _fresh_setup.size() != 57 or _zero_fill_helper.size() != 25:
		return _fail("Fresh-match setup sources are incomplete.")
	return true


func _first_event_record(tokens_variant: Variant) -> Dictionary:
	if not tokens_variant is Array:
		return {}
	for token_variant in tokens_variant:
		if token_variant is Dictionary and str(token_variant.get("kind", "")) == "event_record":
			return token_variant
	return {}


func _zero_fill_public_result(result: Dictionary) -> Dictionary:
	var public_result := result.duplicate(true)
	public_result.erase("ram")
	return public_result


func _bytes_at(source: PackedByteArray, offset: int, expected: Array[int]) -> bool:
	if offset < 0 or offset + expected.size() > source.size():
		return false
	for index in expected.size():
		if int(source[offset + index]) != expected[index]:
			return false
	return true


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_projection_refused", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false
