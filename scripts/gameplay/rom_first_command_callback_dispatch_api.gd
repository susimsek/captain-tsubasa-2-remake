extends RefCounted
class_name RomFirstCommandCallbackDispatchApi
## Resolves source bytes for scenario-$44 callback $70. This is a bounded
## callback API, not a task scheduler or a live route integration.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/first_command_field/callback_dispatch/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_SCHEMA := "first-command-callback-dispatch-sources-v1"
const SCENARIO_READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const PLACEMENT_PRODUCER_SCRIPT := preload("res://scripts/gameplay/first_command_field_packet_producer.gd")

const SOURCE_HASHES := {
	"bank_0b_dispatcher_814c_81a6.bin": "c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6",
	"bank_0b_dispatch_vector_81a7.bin": "663e41116c23b455e418b531b39024bdc5a0c71fc022009926e8cf541f1d35c9",
	"bank_0b_event_70_pointer.bin": "bc885b8008d1b96fcf6d97162721b5a11856643ad80359e925298b87765e39cb",
	"bank_0b_event_72_pointer.bin": "97cff6d36c832c828115df1ffd59b87b00aa1a1bcbe5d81a65bad438687ea59a",
	"bank_0b_event_70_stream.bin": "0356c29ad2d677b4aa64102937c1b3cefc4212f0fe6f4bce0c3fc53ef184f9e5",
}

const EXPECTED_SCENARIO_RECORD := [0x02, 0x70, 0x5C, 0xF0]
const CALLBACK_POINTER_CPU := 0x8B38
const CALLBACK_FIRST_HANDLER_CPU := 0x8327
const CALLBACK_FIRST_MAP_SELECTOR := 0x56

var error_message := ""
var _sources: Dictionary = {}
var _callback_request_resolved := false


## Read scenario-$44 source bytes, resolve callback selector $70 through
## bank-$0B's pointer table, then resolve sub-index zero at $81A7. No timing,
## continuation-stack state, or incoming global $05CD is inferred here.
func resolve_scenario_44_callback() -> Dictionary:
	error_message = ""
	if not _load_sources():
		return _failure(error_message)
	var scenario_result: Dictionary = SCENARIO_READER_SCRIPT.read_project_scenario(
		0x44, {"continuation_depth": 0})
	if int(scenario_result.get("terminal_status", -1)) != SCENARIO_READER_SCRIPT.ParseStatus.SOURCE_TERMINATED:
		return _failure("Scenario $44 did not reach its validated root $FB terminator at depth zero.")
	var record: Dictionary = _find_scenario_record(scenario_result.get("tokens", []))
	if record.is_empty():
		return _failure("Scenario $44 has no decoded four-byte event record.")
	var raw_record: PackedByteArray = record.get("raw_bytes", PackedByteArray())
	if raw_record != PackedByteArray(EXPECTED_SCENARIO_RECORD):
		return _failure("Scenario $44 record differs from the supplied-ROM bytes 02 70 5C F0.")
	var assignments: Dictionary = record.get("ram_assignments", {})
	if int(assignments.get("$0524", -1)) != 0x70 or \
			int(assignments.get("$0528", -1)) != 0x5C or \
			int(assignments.get("$0529", -1)) != 0xFF:
		return _failure("Scenario $44 callback/animation fields did not resolve through the byte reader.")

	var pointer_bytes: PackedByteArray = _sources["bank_0b_event_70_pointer.bin"]
	var pointer_cpu := int(pointer_bytes[0]) | (int(pointer_bytes[1]) << 8)
	if pointer_cpu != CALLBACK_POINTER_CPU:
		return _failure("Bank-$0B callback pointer entry $70 no longer resolves to $8B38.")
	var vector: PackedByteArray = _sources["bank_0b_dispatch_vector_81a7.bin"]
	var handler_table_offset := 3
	var handler_cpu := int(vector[handler_table_offset]) | (int(vector[handler_table_offset + 1]) << 8)
	if handler_cpu != CALLBACK_FIRST_HANDLER_CPU:
		return _failure("Bank-$0B inline dispatch index zero no longer resolves to $8327.")
	var callback_bytes: PackedByteArray = _sources["bank_0b_event_70_stream.bin"]
	var next_pointer_bytes: PackedByteArray = _sources["bank_0b_event_72_pointer.bin"]
	var next_pointer_cpu := int(next_pointer_bytes[0]) | (int(next_pointer_bytes[1]) << 8)
	if next_pointer_cpu - pointer_cpu != callback_bytes.size():
		return _failure("The callback-$70 source span does not end at the following callback pointer $72.")
	if callback_bytes.slice(0, 3) != PackedByteArray([0x06, 0x00, 0x56]):
		return _failure("Callback-$70's first three-byte source record changed.")
	_callback_request_resolved = true

	return {
		"ok": true,
		"status": "callback_source_resolved_waiting_for_live_route_state",
		"scenario_id": 0x44,
		"scenario_record": raw_record,
		"callback_id_0524": 0x70,
		"animation_id_0528": 0x5C,
		"callback_pointer_cpu": pointer_cpu,
		"callback_stream": callback_bytes,
		"first_callback_command": {
			"ram_0525_value": int(callback_bytes[0]),
			"handler_subindex": int(callback_bytes[1]),
			"handler_cpu": handler_cpu,
			"map_selector": int(callback_bytes[2]),
			"source_record": callback_bytes.slice(0, 3),
		},
		"unresolved_callback_tail": callback_bytes.slice(3, callback_bytes.size()),
		"continuation_status": "scenario $44 ends at root $FB; the caller supplied source-start depth $0522=0; outer task return remains unmodeled",
		"continuation_depth": 0,
		"outer_cpu_task_return_modeled": false,
		"scheduler_verified": false,
		"required_live_inputs": ["scheduler dispatch of the callback task", "global RAM $05CD immediately before $8327"],
		"runtime_gap": "This API resolves ROM bytes only; it does not schedule the callback or derive prior global $05CD state.",
	}


## Apply the already-resolved $8327 state transition from an explicit live
## global-RAM value. This does not prove that a task is currently scheduled.
func compute_8327_placement_transition(previous_05cd: int) -> Dictionary:
	if not _callback_request_resolved:
		return {
			"ok": false,
			"status": "callback_source_required",
			"error": "Resolve the scenario-$44 callback source before requesting its $8327 placement transition.",
		}
	if previous_05cd < 0 or previous_05cd > 0xFF:
		return {
			"ok": false,
			"status": "source_state_required",
			"required_input": "$05CD immediately before bank-$0B $8327",
			"error": "The source route must supply a byte-valued global $05CD; no default is used.",
		}
	var producer: RefCounted = PLACEMENT_PRODUCER_SCRIPT.new()
	var result: Dictionary = producer.call("advance_map_placement_state", previous_05cd)
	if not bool(result.get("ok", false)):
		return {"ok": false, "status": "rom_transition_failed", "error": str(result.get("error", producer.get("last_error")))}
	result["status"] = "computed_from_explicit_global_05cd"
	result["scheduler_verified"] = false
	return result


func get_source_status() -> Dictionary:
	return {
		"configured": not _sources.is_empty(),
		"error": error_message,
		"source_manifest": MANIFEST_PATH,
		"source_rom_sha256": SOURCE_ROM_SHA256,
	}


func _load_sources() -> bool:
	if not _sources.is_empty():
		return true
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Callback-dispatch source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Callback-dispatch source manifest is malformed.")
	var manifest: Dictionary = parsed
	if str(manifest.get("schema", "")) != SOURCE_SCHEMA or str(manifest.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("Callback-dispatch source manifest targets another ROM/revision.")
	var rows_by_path: Dictionary = {}
	for row_variant in manifest.get("entries", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			rows_by_path[str(row.get("path", ""))] = row
	for filename_variant in SOURCE_HASHES:
		var filename := str(filename_variant)
		var path := SOURCE_ROOT + filename
		var expected_hash := str(SOURCE_HASHES[filename_variant])
		if not FileAccess.file_exists(path) or not rows_by_path.has(filename):
			return _fail("Missing preserved callback-dispatch source: %s" % filename)
		var bytes := FileAccess.get_file_as_bytes(path)
		var row: Dictionary = rows_by_path[filename]
		if bytes.size() != int(row.get("size_bytes", -1)) or \
				str(row.get("sha256", "")) != expected_hash or FileAccess.get_sha256(path) != expected_hash:
			return _fail("Callback-dispatch source failed size/hash validation: %s" % filename)
		_sources[filename] = bytes
	return true


func _find_scenario_record(tokens_variant: Variant) -> Dictionary:
	if not tokens_variant is Array:
		return {}
	for token_variant in tokens_variant:
		if token_variant is Dictionary and str(token_variant.get("kind", "")) == "event_record":
			return token_variant
	return {}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_resolution_failed", "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false
