extends RefCounted
class_name RomBank10ScenarioTaskRuntime
## Source-order runtime for the fresh KICK OFF bank-$10 scenario-$35 root.
## It advances hash-checked reader tokens and emits the byte-defined callback
## task seed contract. It does not run a scheduler, callback, or actor worker.

const READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/scenario_task_runtime/"
const SOURCE_MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const TASK_CONTEXT_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const TASK_CONTEXT_MANIFEST_PATH := TASK_CONTEXT_ROOT + "manifest.json"
const SCENARIO_CONTINUATION_ROOT := "res://reference/rom_extract/gameplay/scenario_continuation/"
const FIRST_COMMAND_SCENARIOS_MANIFEST := "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json"
const FIRST_COMMAND_SCENARIOS_ROOT := "res://reference/rom_extract/gameplay/first_command_scenarios/"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_SOURCE_SCHEMA := "bank10-scenario-task-runtime-sources-v1"
const ACCEPTED_FRESH_KICKOFF_CALLER_PC := 0xDAD8
const TASK_CONTEXT_SOURCE_HASHES: Dictionary = {
	"bank10_callback_task_setup_8097_80a8.bin": "2d69d726177fe1eb737aab04622108e5860b03d4fd95a5182538c4bae7d982db",
	"fixed_task_create_C50F.bin": "0ea4efd43ee0e2e3d1b9528351bc433e11207744845df22bfaa7bf0e335f08d0",
	"fixed_task_seed_CAE7.bin": "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55",
	"bank0b_callback_entry_8009.bin": "5813c87d4f453cff4b6738bc2af1b54149488222527a69155072092c9f971fdb",
}

const SOURCE_ENTRY_REQUIREMENTS: Dictionary = {
	"reference/rom_extract/gameplay/scenario_task_runtime/fixed_kickoff_scenario35_caller_DAD8_DADC.bin": {
		"cpu_address": "$DAD8", "file_offset": "0x03DAE8", "length_bytes": 5,
		"sha256": "334e25e61f3fa69e4c51961948c06c802993d03dbf9dc2c77b1cb471d857afd5",
	},
	"reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin": {
		"cpu_address": "$CBB0", "file_offset": "0x03CBC0", "length_bytes": 18,
		"sha256": "bda16c7ced2834027dd6039a6c079a701dc8abd9c89179ba2d3c568aa0a16a32",
	},
	"reference/rom_extract/gameplay/scenario_task_runtime/bank10_reader_entry_8000_803E.bin": {
		"cpu_address": "$8000", "file_offset": "0x020010", "length_bytes": 63,
		"sha256": "8f7bdba702bda2bc20e19776e2496f96f7c1c8fad07f424e555726fb4ccc3ca5",
	},
	"reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_wait_load_EC94_EC99.bin": {
		"cpu_address": "$EC94", "file_offset": "0x03ECA4", "length_bytes": 6,
		"sha256": "4ce0089b233f2b5f9f6ada859a28f5513fcb5b83d86b83d7eb223cd0cf22ead5",
	},
	"reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_wait_decrement_ED5B_ED5E.bin": {
		"cpu_address": "$ED5B", "file_offset": "0x03ED6B", "length_bytes": 4,
		"sha256": "2c0b8598b6c79e3a686048c2acd50df9daa86671c464b557ea17429a663ac02d",
	},
	"reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_35.bin": {
		"cpu_address": "$B7CD", "file_offset": "0x020A39", "length_bytes": 2,
		"sha256": "751bb4c1d1d35f0a3f3c86304dffe714c0c1a6483af6e233ecff031004a22bc3",
	},
	"reference/rom_extract/gameplay/scenario_continuation/fixed_scenario_start_ec08_ec33.bin": {
		"cpu_address": "$EC08", "file_offset": "0x03EC18", "length_bytes": 44,
		"sha256": "c5283a9bd23ff473de0b43cfa8d98d8d5f3b78255fa75d5b66d649174218c21f",
	},
	"reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin": {
		"cpu_address": "$B7CD", "file_offset": "0x0237DD", "length_bytes": 8,
		"sha256": "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df",
	},
}

enum Status {
	READY,
	DECODED_OPERATION,
	CALLBACK_TASK_SEED_REQUESTED,
	ROOT_TERMINATED,
	UNSUPPORTED_CALLER,
	SOURCE_INTEGRITY_FAILURE,
	SOURCE_STATE_REQUIRED,
	UNSUPPORTED_OPERATION,
}


class CallbackTaskSeedContract extends RefCounted:
	var scenario_id: int = -1
	var source_record_cpu_address: int = -1
	var source_record_file_offset: int = -1
	var source_record_bytes := PackedByteArray()
	var source_event_selector_ram_0524: int = -1
	var source_wait_value_ram_0523: int = -1
	var actor_selector_ram_0528: int = -1
	var actor_parameter_ram_0529: int = -1
	var setup_cpu_address: int = 0x8097
	var task_create_cpu_address: int = 0xC50F
	var task_seed_cpu_address: int = 0xCAE7
	var task_slot_base: int = -1
	var saved_stack_pointer: int = -1
	var bank_base: int = -1
	var stack_page_write_offsets := PackedByteArray()
	var seeded_rts_return_bytes := PackedByteArray()
	var task_ready_marker: int = -1
	var scheduler_resume_cpu_address: int = -1
	var callback_entry_cpu_address: int = -1
	var scheduler_dispatched: bool = false
	var callback_executed: bool = false

	func to_dictionary() -> Dictionary:
		return {
			"scenario_id": scenario_id,
			"source_record_cpu_address": source_record_cpu_address,
			"source_record_file_offset": source_record_file_offset,
			"source_record_bytes": source_record_bytes.duplicate(),
			"event_selector_ram_0524": source_event_selector_ram_0524,
			"wait_value_ram_0523": source_wait_value_ram_0523,
			"actor_selector_ram_0528": actor_selector_ram_0528,
			"actor_parameter_ram_0529": actor_parameter_ram_0529,
			"setup_cpu_address": setup_cpu_address,
			"task_create_cpu_address": task_create_cpu_address,
			"task_seed_cpu_address": task_seed_cpu_address,
			"task_slot_base": task_slot_base,
			"saved_stack_pointer": saved_stack_pointer,
			"bank_base": bank_base,
			"stack_page_write_offsets": stack_page_write_offsets.duplicate(),
			"seeded_rts_return_bytes": seeded_rts_return_bytes.duplicate(),
			"task_ready_marker": task_ready_marker,
			"scheduler_resume_cpu_address": scheduler_resume_cpu_address,
			"callback_entry_cpu_address": callback_entry_cpu_address,
			"scheduler_dispatched": scheduler_dispatched,
			"callback_executed": callback_executed,
		}


class WaitCounterRequest extends RefCounted:
	var source_scenario_field_ram_0523: int = 0x0523
	var value: int = -1
	var load_cpu_address: int = 0xEC94
	var destination_ram_address: int = 0x0519
	var decrement_cpu_address: int = 0xED5B
	var countdown_advanced: bool = false

	func to_dictionary() -> Dictionary:
		return {
			"source_scenario_field_ram_address": source_scenario_field_ram_0523,
			"value": value,
			"load_cpu_address": load_cpu_address,
			"destination_ram_address": destination_ram_address,
			"decrement_cpu_address": decrement_cpu_address,
			"countdown_advanced": countdown_advanced,
		}


var error_message := ""
var _started := false
var _terminated := false
var _scenario_id := -1
var _source_pointer_cpu := -1
var _source_file_offset := -1
var _source_bytes := PackedByteArray()
var _tokens: Array[Dictionary] = []
var _token_index := 0
var _source_byte_cursor := 0
var _ram_state: Dictionary = {}
var _task_seed_sources: Dictionary = {}


## Accept only the target ROM's fresh kickoff callsite. Scenario ID, pointer,
## initial byte index, and continuation depth are derived from packaged source
## caller/reader bytes; emulator frame IDs and captured RAM are not accepted.
func begin_from_source_callsite(source_caller_cpu_address: int) -> Dictionary:
	_reset()
	if source_caller_cpu_address != ACCEPTED_FRESH_KICKOFF_CALLER_PC:
		return _failure(Status.UNSUPPORTED_CALLER,
			"This slice accepts only the ROM-verified fresh kickoff scenario-$35 caller at $DAD8.",
			{"source_caller_cpu_address": source_caller_cpu_address})
	var source_bundle := _load_and_verify_source_bundle()
	if not bool(source_bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, str(source_bundle.get("error", "Source bundle validation failed.")))
	var sources: Dictionary = source_bundle["sources"]
	var caller: PackedByteArray = sources["reference/rom_extract/gameplay/scenario_task_runtime/fixed_kickoff_scenario35_caller_DAD8_DADC.bin"]
	var queue_helper: PackedByteArray = sources["reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin"]
	var reader_entry: PackedByteArray = sources["reference/rom_extract/gameplay/scenario_task_runtime/bank10_reader_entry_8000_803E.bin"]
	var pointer_bytes: PackedByteArray = sources["reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_35.bin"]
	var start_helper: PackedByteArray = sources["reference/rom_extract/gameplay/scenario_continuation/fixed_scenario_start_ec08_ec33.bin"]

	if caller != PackedByteArray([0xA9, 0x35, 0x20, 0xB0, 0xCB]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Kickoff caller no longer loads ID $35 and calls $CBB0.")
	if queue_helper.slice(0, 3) != PackedByteArray([0x8D, 0x18, 0x05]) \
			or queue_helper.slice(3, 8) != PackedByteArray([0xA9, 0x80, 0x8D, 0x16, 0x05]) \
			or queue_helper.slice(8, 18) != PackedByteArray([0xA9, 0x00, 0x85, 0x05, 0xA9, 0x00, 0x20, 0x0F, 0xCB, 0x60]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "$CBB0 no longer writes the caller ID to $0518 and yields through $CB0F.")
	if reader_entry.slice(0, 6) != PackedByteArray([0x4C, 0x06, 0x80, 0x4C, 0x21, 0x80]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 entries $8000/$8003 no longer resolve pointer/state initialization paths.")
	if reader_entry.slice(6, 33) != PackedByteArray([
		0xA2, 0x89, 0xAD, 0x18, 0x05, 0x0A, 0xA8, 0x90, 0x01, 0xE8,
		0xA9, 0xBF, 0x85, 0x5D, 0x86, 0x5E, 0xB1, 0x5D, 0xAA, 0xC8,
		0xB1, 0x5D, 0x85, 0x5E, 0x86, 0x5D, 0x60,
	]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 $8006 pointer-table reader bytes changed.")
	if reader_entry.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A,
	]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 $8021 initialization no longer clears the byte index $3A.")
	if pointer_bytes != PackedByteArray([0xCD, 0xB7]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario-$35 pointer-table word no longer resolves to $B7CD.")
	if not _contains_bytes(start_helper, PackedByteArray([0xA9, 0x10, 0x85, 0x24, 0xA9, 0x11, 0x85, 0x25, 0x20, 0x2D, 0xCE, 0x68, 0x20, 0x00, 0x80])) \
			or not _contains_bytes(start_helper, PackedByteArray([0xA9, 0x00, 0x8D, 0x22, 0x05])):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Fixed $EC08 start no longer maps bank $10, calls $8000, and clears $0522.")
	if not _verify_wait_sources(sources):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)

	_scenario_id = int(caller[1])
	_source_pointer_cpu = int(pointer_bytes[0]) | (int(pointer_bytes[1]) << 8)
	_source_file_offset = 0x0237DD
	var scenario_path := "reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin"
	_source_bytes = sources[scenario_path]
	var parsed: Dictionary = READER_SCRIPT.read_project_scenario(_scenario_id, {"continuation_depth": 0})
	if int(parsed.get("terminal_status", -1)) != READER_SCRIPT.ParseStatus.SOURCE_TERMINATED:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Hash-checked scenario-$35 source did not reach its depth-zero $FB root terminator.")
	if bool(parsed.get("context_required", false)):
		return _failure(Status.SOURCE_STATE_REQUIRED, "Scenario-$35 requires caller-owned state not established by its source callsite.")
	var token_list: Variant = parsed.get("tokens", [])
	if not token_list is Array:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 reader did not return a token array.")
	for token_variant in token_list:
		if token_variant is Dictionary:
			_tokens.append(token_variant)
		else:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 reader returned a non-dictionary token.")
	_started = true
	return {
		"ok": true,
		"status": "ready",
		"scenario_id": _scenario_id,
		"source_caller_cpu_address": source_caller_cpu_address,
		"source_pointer_cpu": _source_pointer_cpu,
		"source_byte_index": _source_byte_cursor,
		"continuation_depth": 0,
		"root_state_source": "packaged $DAD8/$CBB0 caller, bank-$10 pointer reader, and $EC08 scenario-start bytes",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stream_sha256": _sha256(_source_bytes),
		"token_count": _tokens.size(),
		"emulator_frame_input_used": false,
		"capture_ram_input_used": false,
	}


## Start the reader from a live scenario selector and pointer already resolved
## by the bank-$10 `$8006` ROM path. Only preserved scenario IDs with a matching
## pointer-table manifest entry are accepted.
func begin_from_live_scenario_pointer(scenario_id: int, source_pointer_cpu: int) -> Dictionary:
	_reset()
	if scenario_id not in [0x35, 0x36]:
		return _failure(Status.UNSUPPORTED_CALLER,
			"Only the preserved fresh-route scenario-$35/$36 streams are supported.",
			{"scenario_id": scenario_id, "source_pointer_cpu": source_pointer_cpu})
	var source_bundle := _load_and_verify_source_bundle()
	if not bool(source_bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(source_bundle.get("error", "Source bundle validation failed.")))
	var sources: Dictionary = source_bundle["sources"]
	var scenario_bundle := _load_and_verify_first_command_scenarios(scenario_id)
	if not bool(scenario_bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(scenario_bundle.get("error", "Scenario source validation failed.")))
	var pointer_bytes: PackedByteArray = scenario_bundle["pointer_bytes"]
	var scenario_bytes: PackedByteArray = scenario_bundle["scenario_bytes"]
	var resolved_pointer := int(pointer_bytes[0]) | (int(pointer_bytes[1]) << 8)
	if source_pointer_cpu != resolved_pointer:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Live bank-$10 pointer differs from the manifest-checked table entry.",
			{"scenario_id": scenario_id, "live_pointer": source_pointer_cpu,
			"manifest_pointer": resolved_pointer})
	if not _verify_reader_entry(sources["reference/rom_extract/gameplay/scenario_task_runtime/bank10_reader_entry_8000_803E.bin"]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	_scenario_id = scenario_id
	_source_pointer_cpu = resolved_pointer
	_source_file_offset = 0x0237DD if scenario_id == 0x35 else 0x0237F4
	_source_bytes = scenario_bytes
	var parsed: Dictionary = READER_SCRIPT.read_project_scenario(_scenario_id, {"continuation_depth": 0})
	var terminal_status := int(parsed.get("terminal_status", -1))
	if terminal_status not in [READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
			READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED]:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Manifest-checked scenario-$%02X stream stopped at an unsupported parse status." % scenario_id)
	var token_list: Variant = parsed.get("tokens", [])
	var expected_prefix: Array = [0xF9, "event_record"] if scenario_id == 0x35 \
		else [0xF5, 0xF9, "event_record"]
	if not token_list is Array or token_list.size() < expected_prefix.size():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 reader did not return a token array.")
	for index in expected_prefix.size():
		var token_variant: Variant = token_list[index]
		if not token_variant is Dictionary:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Bank-$10 reader returned a non-dictionary token.")
		var token: Dictionary = token_variant
		if expected_prefix[index] is String:
			if String(token.get("kind", "")) != String(expected_prefix[index]):
				return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario-$%02X live prefix token order differs from its ROM bytes." % scenario_id)
		elif String(token.get("kind", "")) != "opcode" \
				or int(token.get("opcode", -1)) != int(expected_prefix[index]):
			return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario-$%02X live prefix opcode order differs from its ROM bytes." % scenario_id)
		_tokens.append(token)
	_started = true
	for path_variant in scenario_bundle["source_paths"]:
		var path := String(path_variant)
		var bytes: PackedByteArray = scenario_bundle["sources"][path]
		# The runtime result carries provenance; the caller remains responsible for
		# recording these same verified spans in its execution report.
		if bytes.is_empty():
			return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario source span is empty: %s." % path)
	return {
		"ok": true,
		"status": "ready",
		"scenario_id": _scenario_id,
		"source_caller_cpu_address": -1,
		"source_pointer_cpu": _source_pointer_cpu,
		"source_byte_index": _source_byte_cursor,
		"continuation_depth": 0,
		"root_state_source": "live `$0518` selector, ROM `$89BF` table entry, and manifest-checked bank-$10 stream",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stream_sha256": _sha256(_source_bytes),
		"token_count": _tokens.size(),
		"source_context_required_after_prefix": bool(parsed.get("context_required", false)),
		"unresolved_context_requirements": parsed.get("context_requirements", []),
		"emulator_frame_input_used": false,
		"capture_ram_input_used": false,
		"source_paths": scenario_bundle["source_paths"].duplicate(),
	}


func _verify_reader_entry(reader_entry: PackedByteArray) -> bool:
	if reader_entry.size() != 63 \
			or reader_entry.slice(0, 6) != PackedByteArray([0x4C, 0x06, 0x80, 0x4C, 0x21, 0x80]) \
			or reader_entry.slice(6, 33) != PackedByteArray([
				0xA2, 0x89, 0xAD, 0x18, 0x05, 0x0A, 0xA8, 0x90, 0x01, 0xE8,
				0xA9, 0xBF, 0x85, 0x5D, 0x86, 0x5E, 0xB1, 0x5D, 0xAA, 0xC8,
				0xB1, 0x5D, 0x85, 0x5E, 0x86, 0x5D, 0x60]):
		return _fail_bool("Bank-$10 `$8006` pointer reader bytes failed validation.")
	return true


func _load_and_verify_first_command_scenarios(scenario_id: int) -> Dictionary:
	var file := FileAccess.open(FIRST_COMMAND_SCENARIOS_MANIFEST, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "First-command scenario manifest is unavailable."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary \
			or String((parsed as Dictionary).get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String((parsed as Dictionary).get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return {"ok": false, "error": "First-command scenario manifest targets another ROM or schema."}
	var manifest: Dictionary = parsed
	var scenario_id_text := "$%02X" % scenario_id
	var pointer_row: Dictionary = {}
	var stream_row: Dictionary = {}
	for row_variant in manifest.get("pointer_table_entries", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == scenario_id_text:
			pointer_row = row_variant
			break
	for row_variant in manifest.get("scenario_streams", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == scenario_id_text:
			stream_row = row_variant
			break
	if pointer_row.is_empty() or stream_row.is_empty():
		return {"ok": false, "error": "Manifest omits scenario-$%02X pointer or stream." % scenario_id}
	var pointer_path := String(pointer_row.get("path", ""))
	var stream_path := String(stream_row.get("path", ""))
	var expected_pointer := 0xB7CD if scenario_id == 0x35 else 0xB7E4
	var expected_pointer_file_offset := "0x020A39" if scenario_id == 0x35 else "0x020A3B"
	var expected_stream_file_offset := "0x0237DD" if scenario_id == 0x35 else "0x0237F4"
	var expected_stream_hash := "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df" if scenario_id == 0x35 else "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f"
	var pointer_bytes := FileAccess.get_file_as_bytes("res://" + pointer_path)
	var scenario_bytes := FileAccess.get_file_as_bytes("res://" + stream_path)
	var expected_stream_size := 8 if scenario_id == 0x35 else 38
	var pointer_hash := "751bb4c1d1d35f0a3f3c86304dffe714c0c1a6483af6e233ecff031004a22bc3" if scenario_id == 0x35 else "5d2bc0e444947ba22ee06b40139852b88e24eb157d3175e1c6ef1c315d4d6a7a"
	if String(pointer_row.get("cpu_address", "")).to_lower() != "0x%04x" % expected_pointer \
			or String(pointer_row.get("table_cpu_address", "")).to_lower() != "0x89bf" \
			or String(pointer_row.get("table_file_offset", "")) != expected_pointer_file_offset \
			or String(pointer_row.get("sha256", "")) != pointer_hash \
			or String(stream_row.get("start_cpu_address", "")).to_lower() != "0x%04x" % expected_pointer \
			or String(stream_row.get("file_offset", "")) != expected_stream_file_offset \
			or int(stream_row.get("length_bytes", -1)) != expected_stream_size \
			or String(stream_row.get("sha256", "")) != expected_stream_hash \
			or pointer_bytes.size() != 2 or _sha256(pointer_bytes) != pointer_hash \
			or scenario_bytes.size() != expected_stream_size or _sha256(scenario_bytes) != expected_stream_hash \
			or String(pointer_row.get("bytes_hex", "")).replace(" ", "").to_lower() != pointer_bytes.hex_encode():
		return {"ok": false, "error": "Scenario-$%02X pointer/stream metadata or bytes failed manifest/hash validation." % scenario_id}
	return {"ok": true, "pointer_bytes": pointer_bytes, "scenario_bytes": scenario_bytes,
		"source_paths": [pointer_path, stream_path],
		"sources": {pointer_path: pointer_bytes, stream_path: scenario_bytes}}


## Consume one contiguous ROM-decoded token. Event records yield typed wait and
## task-seed contracts; the cooperative scheduler is deliberately not run.
func advance_one() -> Dictionary:
	if not _started:
		return _failure(Status.SOURCE_STATE_REQUIRED, "Begin from the verified fresh kickoff caller before advancing.")
	if _terminated:
		return _failure(Status.UNSUPPORTED_OPERATION, "The scenario root already terminated at $FB.")
	if _token_index >= _tokens.size():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Token cursor passed the validated stream without $FB.")
	var token: Dictionary = _tokens[_token_index]
	var offset := int(token.get("byte_offset", -1))
	var kind := str(token.get("kind", ""))
	var length := int(token.get("length_bytes", 4 if kind == "event_record" else 0))
	if offset != _source_byte_cursor or length <= 0 or offset + length > _source_bytes.size():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Next decoded token is not contiguous with the verified source cursor.")
	if kind == "event_record":
		return _consume_event_record(token, offset)
	if kind == "opcode":
		return _consume_decoded_opcode(token, offset, length)
	if kind == "control_flow" and int(token.get("opcode", -1)) == 0xFB:
		return _consume_root_fb(token, offset)
	return _failure(Status.UNSUPPORTED_OPERATION, "This task slice does not execute the returned token kind.",
		{"token_kind": kind, "source_byte_offset": offset, "cursor_advanced": false})


func get_state() -> Dictionary:
	return {
		"started": _started,
		"terminated": _terminated,
		"scenario_id": _scenario_id,
		"source_pointer_cpu": _source_pointer_cpu,
		"source_byte_index": _source_byte_cursor,
		"token_index": _token_index,
		"ram_state": _ram_state.duplicate(true),
		"scheduler_dispatched": false,
		"callback_executed": false,
		"error": error_message,
	}


func _consume_decoded_opcode(token: Dictionary, offset: int, length: int) -> Dictionary:
	var opcode := int(token.get("opcode", -1))
	var writes: Dictionary = token.get("ram_write", {})
	if writes.is_empty():
		return _failure(Status.UNSUPPORTED_OPERATION,
			"Opcode $%02X has no byte-decoded state write in this bounded runtime." % opcode,
			{"source_byte_offset": offset, "cursor_advanced": false})
	for address_variant in writes:
		var address := str(address_variant)
		_ram_state[address] = int(writes[address_variant]) & 0xFF
	_advance_cursor(length)
	return {
		"ok": true,
		"status": "decoded_byte_operation_applied",
		"scenario_id": _scenario_id,
		"opcode": opcode,
		"handler_cpu_address": int(token.get("handler_cpu_address", -1)),
		"handler_file_offset": int(token.get("handler_file_offset", -1)),
		"handler_bytes": token.get("handler_bytes", []),
		"source_byte_offset": offset,
		"source_byte_index_after": _source_byte_cursor,
		"ram_writes": writes.duplicate(true),
		"ram_state": _ram_state.duplicate(true),
		"timing_inferred": false,
	}


func _consume_event_record(token: Dictionary, offset: int) -> Dictionary:
	var raw_variant: Variant = token.get("raw_bytes", PackedByteArray())
	if not raw_variant is PackedByteArray or raw_variant.size() != 4:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "ROM scenario event record must contain four source bytes.")
	var raw: PackedByteArray = raw_variant
	if raw != _source_bytes.slice(offset, offset + 4):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Decoded event record differs from the hash-checked stream bytes.")
	var expected_offset := 3 if _scenario_id == 0x35 else 4
	var expected_record := PackedByteArray([0x02, 0x3A, 0x8F, 0x73]) if _scenario_id == 0x35 \
		else PackedByteArray([0x10, 0x3A, 0x8F, 0xF0])
	if raw != expected_record or offset != expected_offset:
		return _failure(Status.UNSUPPORTED_OPERATION,
			"Only the first preserved event record for scenario-$%02X is supported." % _scenario_id,
			{"source_byte_offset": offset, "record_bytes": raw, "cursor_advanced": false})
	var assignments: Dictionary = token.get("ram_assignments", {})
	for address_variant in assignments:
		_ram_state[str(address_variant)] = int(assignments[address_variant]) & 0xFF
	var contract := _build_seed_contract(token, raw, offset)
	if contract == null:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"The task-seed source bytes could not produce a complete typed seed contract.")
	var wait_request := WaitCounterRequest.new()
	wait_request.value = int(_ram_state.get("$0523", -1))
	if wait_request.value < 0:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario record did not decode its wait field.")
	_advance_cursor(4)
	return {
		"ok": true,
		"status": "callback_task_seed_requested",
		"scenario_id": _scenario_id,
		"source_byte_offset": offset,
		"source_byte_index_after": _source_byte_cursor,
		"seed_contract": contract,
		"seed_contract_fields": contract.to_dictionary(),
		"wait_request": wait_request,
		"wait_request_fields": wait_request.to_dictionary(),
		"ram_state": _ram_state.duplicate(true),
		"scheduler_dispatched": false,
		"callback_executed": false,
		"actor_worker_started": false,
	}


func _build_seed_contract(token: Dictionary, raw: PackedByteArray, offset: int) -> CallbackTaskSeedContract:
	if _task_seed_sources.size() != TASK_CONTEXT_SOURCE_HASHES.size():
		return null
	var setup: PackedByteArray = _task_seed_sources["bank10_callback_task_setup_8097_80a8.bin"]
	var create: PackedByteArray = _task_seed_sources["fixed_task_create_C50F.bin"]
	var seed: PackedByteArray = _task_seed_sources["fixed_task_seed_CAE7.bin"]
	var callback_entry: PackedByteArray = _task_seed_sources["bank0b_callback_entry_8009.bin"]
	if setup.size() != 18 or create.size() != 3 or seed.size() != 16 or callback_entry.size() != 3:
		return null
	if int(setup[0]) != 0xA2 or int(setup[2]) != 0xA9 or int(setup[4]) != 0x95 \
			or int(setup[6]) != 0xA9 or int(setup[8]) != 0x95 \
			or int(setup[10]) != 0xA9 or int(setup[12]) != 0xA0 \
			or int(setup[14]) != 0x20 or create != PackedByteArray([0x4C, 0xE7, 0xCA]) \
			or seed != PackedByteArray([0x48, 0x98, 0xB4, 0x01, 0x99, 0x01, 0x01, 0x68,
				0x99, 0x02, 0x01, 0xA9, 0xFF, 0x95, 0x00, 0x60]) \
			or callback_entry.size() != 3 or int(callback_entry[0]) != 0x4C:
		return null
	var task_create_target := int(setup[15]) | (int(setup[16]) << 8)
	var task_seed_target := int(create[1]) | (int(create[2]) << 8)
	var return_low := int(setup[13])
	var return_high := int(setup[11])
	var callback_entry_target := int(callback_entry[1]) | (int(callback_entry[2]) << 8)
	if task_create_target != 0xC50F or task_seed_target != 0xCAE7 \
			or int(setup[17]) != 0x60 or int(callback_entry_target) != 0x814C:
		return null
	var assignments: Dictionary = token.get("ram_assignments", {})
	if not assignments.has("$0524") or not assignments.has("$0523") \
			or not assignments.has("$0528") or not assignments.has("$0529"):
		return null
	var contract := CallbackTaskSeedContract.new()
	contract.scenario_id = _scenario_id
	contract.source_record_cpu_address = _source_pointer_cpu + offset
	contract.source_record_file_offset = _source_file_offset + offset
	contract.source_record_bytes = raw.duplicate()
	contract.source_event_selector_ram_0524 = int(assignments["$0524"])
	contract.source_wait_value_ram_0523 = int(assignments["$0523"])
	contract.actor_selector_ram_0528 = int(assignments["$0528"])
	contract.actor_parameter_ram_0529 = int(assignments["$0529"])
	contract.task_slot_base = int(setup[1])
	contract.saved_stack_pointer = int(setup[3])
	contract.bank_base = int(setup[7])
	contract.stack_page_write_offsets = PackedByteArray([
		(contract.saved_stack_pointer + 1) & 0xFF,
		(contract.saved_stack_pointer + 2) & 0xFF,
	])
	contract.seeded_rts_return_bytes = PackedByteArray([return_low, return_high])
	contract.task_ready_marker = int(seed[12])
	contract.scheduler_resume_cpu_address = ((return_low | (return_high << 8)) + 1) & 0xFFFF
	contract.callback_entry_cpu_address = callback_entry_target
	return contract


func _consume_root_fb(token: Dictionary, offset: int) -> Dictionary:
	if not bool(token.get("source_span_validated", false)) \
			or int(token.get("continuation_depth", -1)) != 0:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Root `$FB` requires the source-cleared continuation depth zero.",
			{"source_byte_offset": offset, "cursor_advanced": false})
	if offset != _source_bytes.size() - 1:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, "$FB is not the final byte of the validated root span.")
	_advance_cursor(1)
	_terminated = true
	return {
		"ok": true,
		"status": "root_scenario_terminated",
		"scenario_id": _scenario_id,
		"source_byte_offset": offset,
		"source_byte_index_after": _source_byte_cursor,
		"terminal_handler_cpu_address": 0x80CF,
		"outer_task_return_modeled": false,
		"scheduler_dispatched": false,
	}


func _load_and_verify_source_bundle() -> Dictionary:
	var manifest_file := FileAccess.open(SOURCE_MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return {"ok": false, "error": "Scenario task-runtime source manifest is missing."}
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return {"ok": false, "error": "Scenario task-runtime source manifest is malformed."}
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != EXPECTED_SOURCE_SCHEMA \
			or str(manifest.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return {"ok": false, "error": "Scenario task-runtime manifest targets another ROM revision/schema."}
	var rows: Dictionary = {}
	for row_variant in manifest.get("entries", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			rows[str(row.get("path", ""))] = row
	var sources: Dictionary = {}
	for path_variant in SOURCE_ENTRY_REQUIREMENTS:
		var path := str(path_variant)
		if not rows.has(path):
			return {"ok": false, "error": "Scenario task-runtime manifest omits %s." % path}
		var row: Dictionary = rows[path]
		var requirement: Dictionary = SOURCE_ENTRY_REQUIREMENTS[path_variant]
		if str(row.get("cpu_address", "")) != str(requirement["cpu_address"]) \
				or str(row.get("file_offset", "")) != str(requirement["file_offset"]) \
				or int(row.get("length_bytes", -1)) != int(requirement["length_bytes"]) \
				or str(row.get("sha256", "")) != str(requirement["sha256"]):
			return {"ok": false, "error": "Scenario task-runtime manifest metadata changed for %s." % path}
		var bytes := FileAccess.get_file_as_bytes("res://" + path)
		if bytes.size() != int(requirement["length_bytes"]) \
				or _sha256(bytes) != str(requirement["sha256"]):
			return {"ok": false, "error": "Scenario task-runtime source failed size/hash validation: %s." % path}
		sources[path] = bytes
	return {"ok": true, "sources": sources}


func _verify_wait_sources(sources: Dictionary) -> bool:
	var load_wait: PackedByteArray = sources["reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_wait_load_EC94_EC99.bin"]
	var decrement: PackedByteArray = sources["reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_wait_decrement_ED5B_ED5E.bin"]
	if load_wait != PackedByteArray([0xAD, 0x23, 0x05, 0x8D, 0x19, 0x05]) \
			or decrement != PackedByteArray([0xCA, 0x8E, 0x19, 0x05]):
		return _fail_bool("The source wait load/decrement handlers differ from $EC94/$ED5B.")
	return true


func _load_and_verify_task_seed_sources() -> bool:
	var manifest_file := FileAccess.open(TASK_CONTEXT_MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail_bool("ROM task-context source manifest is missing.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail_bool("ROM task-context source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail_bool("ROM task-context manifest targets another ROM revision.")
	var rows: Dictionary = {}
	for row_variant in manifest.get("spans", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			rows[str(row.get("file", ""))] = row
	for filename_variant in TASK_CONTEXT_SOURCE_HASHES:
		var filename := str(filename_variant)
		if not rows.has(filename):
			return _fail_bool("ROM task-context manifest omits %s." % filename)
		var bytes := FileAccess.get_file_as_bytes(TASK_CONTEXT_ROOT + filename)
		var row: Dictionary = rows[filename]
		var expected_hash := str(TASK_CONTEXT_SOURCE_HASHES[filename_variant])
		if bytes.is_empty() or int(row.get("length", -1)) != bytes.size() \
				or str(row.get("sha256", "")) != expected_hash or _sha256(bytes) != expected_hash:
			return _fail_bool("ROM task-seed source failed its size/hash check: %s." % filename)
		_task_seed_sources[filename] = bytes
	return true


func _contains_bytes(haystack: PackedByteArray, needle: PackedByteArray) -> bool:
	if needle.is_empty() or needle.size() > haystack.size():
		return false
	for start in range(haystack.size() - needle.size() + 1):
		if haystack.slice(start, start + needle.size()) == needle:
			return true
	return false


func _advance_cursor(byte_count: int) -> void:
	_source_byte_cursor += byte_count
	_token_index += 1


func _reset() -> void:
	error_message = ""
	_started = false
	_terminated = false
	_scenario_id = -1
	_source_pointer_cpu = -1
	_source_file_offset = -1
	_source_bytes = PackedByteArray()
	_tokens.clear()
	_token_index = 0
	_source_byte_cursor = 0
	_ram_state.clear()
	_task_seed_sources.clear()


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail_bool(message: String) -> bool:
	error_message = message
	return false


func _failure(status: int, message: String, details: Dictionary = {}) -> Dictionary:
	error_message = message
	var result := {"ok": false, "status": _status_name(status), "error": message}
	for key_variant in details:
		result[key_variant] = details[key_variant]
	return result


func _status_name(status: int) -> String:
	match status:
		Status.READY:
			return "ready"
		Status.DECODED_OPERATION:
			return "decoded_byte_operation_applied"
		Status.CALLBACK_TASK_SEED_REQUESTED:
			return "callback_task_seed_requested"
		Status.ROOT_TERMINATED:
			return "root_scenario_terminated"
		Status.UNSUPPORTED_CALLER:
			return "unsupported_caller"
		Status.SOURCE_INTEGRITY_FAILURE:
			return "source_integrity_failure"
		Status.SOURCE_STATE_REQUIRED:
			return "source_state_required"
		Status.UNSUPPORTED_OPERATION:
			return "unsupported_operation"
	return "unknown_status"
