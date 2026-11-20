extends RefCounted
class_name RomBank10ScenarioTaskRuntime
## Source-order runtime for verified bank-$10 scenario roots. Scenario $35
## advances its supported byte operations; scenario $1C is admitted for source
## inspection and stops at its unresolved holder/control-flow boundary. It does
## not run a scheduler, callback, or actor worker.

const READER_SCRIPT := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/scenario_task_runtime/"
const SOURCE_MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const TASK_CONTEXT_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const TASK_CONTEXT_MANIFEST_PATH := TASK_CONTEXT_ROOT + "manifest.json"
const SCENARIO_CONTINUATION_ROOT := "res://reference/rom_extract/gameplay/scenario_continuation/"
const FIRST_COMMAND_SCENARIOS_MANIFEST := "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json"
const FIRST_COMMAND_SCENARIOS_ROOT := "res://reference/rom_extract/gameplay/first_command_scenarios/"
const PASS_SCENARIO_1C_ROOT := "res://reference/rom_extract/gameplay/pass_scenario_1c/"
const PASS_SCENARIO_1C_MANIFEST := PASS_SCENARIO_1C_ROOT + "manifest.json"
const PASS_SCENARIO_1C_STREAM_PATH := PASS_SCENARIO_1C_ROOT + "scenario_1C.bin"
const PASS_SCENARIO_1C_POINTER_PATH := PASS_SCENARIO_1C_ROOT + "scenario_1C_pointer_entry.bin"
const PASS_SCENARIO_1C_STREAM_SHA256 := "68d8512ef76afc90deee499c53952f8cf27d4c4473749a571ef1ed9deca132e2"
const PASS_SCENARIO_1C_POINTER_SHA256 := "0aebdd98608aa88311ca8ab9bedd486c26160ed4a842df5297fd8572eb568bf4"
const PASS_SCENARIO_1C_FA_BRANCH_PATH := PASS_SCENARIO_1C_ROOT + "bank10_FA_branch_BB4B_BB50.bin"
const PASS_SCENARIO_1C_FA_BRANCH_SHA256 := "d39d9c4feecbd6f52b00d87bc8402f8a265fd173fb392b2066bcd08c2b9dce4c"
const PASS_SCENARIO_1C_B49E_PATH := PASS_SCENARIO_1C_ROOT + "bank10_F3_root_target_B49E_B4A6.bin"
const PASS_SCENARIO_1C_B49E_SHA256 := "1a650937b1815dc4ab5a30a1da70eb4e3c4bad7059005d1fbb585995936db5e2"
const PASS_SCENARIO_1C_B4B6_PATH := PASS_SCENARIO_1C_ROOT + "bank10_F3_root_target_B4B6_B4BE.bin"
const PASS_SCENARIO_1C_B4B6_SHA256 := "c2b1fab616d39995a449dc04d7893b270cb637df53a52ba54954c96de5d42915"
const PASS_SCENARIO_18_ROOT := "res://reference/rom_extract/gameplay/pass_scenario_18/"
const PASS_SCENARIO_18_MANIFEST := PASS_SCENARIO_18_ROOT + "manifest.json"
const PASS_SCENARIO_18_STREAM_SHA256 := "8e79217a8131e753b6a194df0ca5eb8e916b11d1bd537c06a4541583161bb81b"
const PASS_SCENARIO_18_POINTER_SHA256 := "3101454d77028d7505313ba354609954498f92a503e65b791b076e04219f3d9b"
const PASS_SCENARIO_18_AF51_SHA256 := "162fe60677bbd4a6f06415055195215d0a39860746a52816598badfc7571cb8a"
const SCENARIO_2E_ROOT := "res://reference/rom_extract/gameplay/scenario_2e/"
const SCENARIO_2E_MANIFEST := SCENARIO_2E_ROOT + "manifest.json"
const SCENARIO_2E_POINTER_PATH := SCENARIO_2E_ROOT + "scenario_pointer_2E.bin"
const SCENARIO_2E_STREAM_PATH := SCENARIO_2E_ROOT + "scenario_2E.bin"
const SCENARIO_2E_POINTER_SHA256 := "89ac76264b830ae1361eae0ff3195e173fb7d45b9a0e8754db0986cb14623202"
const SCENARIO_2E_STREAM_SHA256 := "1a8acb72b1adf0fd4059eb2a0a8c27b0e93778b9a3a3a82886aa0818c5722630"
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
	CONTEXT_REQUIRED,
	EXTERNAL_CONTINUATION_REQUIRED,
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
var _source_root_pointer_cpu := -1
var _source_file_offset := -1
var _source_bytes := PackedByteArray()
var _scenario18_branch_af51 := PackedByteArray()
var _scenario18_parent_root_pointer_cpu := -1
var _scenario18_active_external_branch := false
var _tokens: Array[Dictionary] = []
var _scenario_1c_reader_status := ""
var _scenario_1c_terminal_status := ""
var _scenario_1c_child_branch_active := false
var _scenario_1c_context_requirements: Array = []
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
	_source_root_pointer_cpu = _source_pointer_cpu
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
func begin_from_live_scenario_pointer(scenario_id: int, source_pointer_cpu: int,
		live_context: Dictionary = {}) -> Dictionary:
	_reset()
	if scenario_id == 0x1C:
		return _begin_scenario_1c_from_live_pointer(source_pointer_cpu, live_context)
	if scenario_id not in [0x18, 0x1E, 0x2E, 0x35, 0x36, 0x38, 0x44]:
		return _failure(Status.UNSUPPORTED_CALLER,
			"Only preserved fresh-route scenario-$1E/$2E/$35/$36/$38/$44 streams are supported.",
			{"scenario_id": scenario_id, "source_pointer_cpu": source_pointer_cpu})
	var source_bundle := _load_and_verify_source_bundle()
	if not bool(source_bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(source_bundle.get("error", "Source bundle validation failed.")))
	var sources: Dictionary = source_bundle["sources"]
	var scenario_bundle: Dictionary = _load_and_verify_pass_scenario_18() \
		if scenario_id == 0x18 else (_load_and_verify_scenario_2e() if scenario_id == 0x2E \
		else _load_and_verify_first_command_scenarios(scenario_id))
	if not bool(scenario_bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(scenario_bundle.get("error", "Scenario source validation failed.")))
	var pointer_bytes: PackedByteArray = scenario_bundle["pointer_bytes"]
	var scenario_bytes: PackedByteArray = scenario_bundle["scenario_bytes"]
	var scenario18_branch_terminal_cursor := scenario_id == 0x18 and source_pointer_cpu == 0xAF58
	if scenario_id == 0x18:
		_scenario18_branch_af51 = scenario_bundle["scenario18_branch_af51"].duplicate()
	var resolved_pointer := int(pointer_bytes[0]) | (int(pointer_bytes[1]) << 8)
	var source_byte_offset := source_pointer_cpu - resolved_pointer
	var valid_source_cursor := source_byte_offset == 0 \
			or scenario18_branch_terminal_cursor \
			or scenario_id == 0x1E and source_byte_offset == 9 \
			or scenario_id == 0x44 and source_byte_offset == 4
	if not valid_source_cursor:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Live bank-$10 pointer is not a manifest-checked root or supported scenario terminal cursor.",
			{"scenario_id": scenario_id, "live_pointer": source_pointer_cpu,
			"manifest_root_pointer": resolved_pointer,
			"source_byte_offset": source_byte_offset})
	if not _verify_reader_entry(sources["reference/rom_extract/gameplay/scenario_task_runtime/bank10_reader_entry_8000_803E.bin"]):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	_scenario_id = scenario_id
	_source_pointer_cpu = source_pointer_cpu
	_source_root_pointer_cpu = resolved_pointer
	_source_file_offset = int({0x18: 0x021E4E, 0x1E: 0x0237EA, 0x2E: 0x02375E,
		0x35: 0x0237DD, 0x36: 0x0237F4, 0x38: 0x0237D6, 0x44: 0x0237E5}.get(scenario_id, -1))
	_source_bytes = scenario_bytes
	var parse_context := {"continuation_depth": 0}
	if live_context.has("ram_05FB"):
		parse_context["ram_05FB"] = int(live_context["ram_05FB"]) & 0xFF
		_ram_state["$05FB"] = int(live_context["ram_05FB"]) & 0xFF
	for context_key: String in ["ram_0441", "ram_044E", "ram_043C", "ram_0516", "ram_0522",
			"ram_0638", "ram_fd00_mirror_flag"]:
		if live_context.has(context_key):
			var context_value := int(live_context[context_key]) & 0xFF
			parse_context[context_key] = context_value
			_ram_state["$" + context_key.trim_prefix("ram_")] = context_value
	var parsed: Dictionary
	if scenario18_branch_terminal_cursor:
		if not live_context.has("ram_0522") or int(live_context["ram_0522"]) != 0:
			return _failure(Status.SOURCE_STATE_REQUIRED,
				"Scenario-$18 `$AF58` needs live `$0522=0` to prove the caller-owned continuation stack is empty.",
				{"scenario_id": scenario_id, "source_pointer_cpu": source_pointer_cpu,
				"live_ram_0522": int(live_context.get("ram_0522", -1))})
		parse_context["scenario18_live_terminal_cursor"] = true
		var branch_bytes: PackedByteArray = scenario_bundle["scenario18_branch_af51"]
		if branch_bytes != PackedByteArray([0xF9, 0x05, 0x2B, 0x3C, 0x72, 0x66, 0x47, 0xFB]) \
				or _sha256(branch_bytes) != PASS_SCENARIO_18_AF51_SHA256:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$18 live `$AF58` cursor is not backed by the hash-checked `$AF51` child stream.")
		_source_root_pointer_cpu = 0xAF51
		_source_file_offset = 0x022F61
		_source_bytes = branch_bytes.duplicate()
		source_byte_offset = 7
		_scenario18_active_external_branch = true
		_scenario18_parent_root_pointer_cpu = resolved_pointer
		parsed = READER_SCRIPT.parse_bytes(_scenario_id, _source_bytes,
			"res://reference/rom_extract/gameplay/pass_scenario_18/scenario_18_branch_af51.bin",
			parse_context)
	else:
		parsed = READER_SCRIPT.read_project_scenario(_scenario_id, parse_context)
	var terminal_status := int(parsed.get("terminal_status", -1))
	if terminal_status not in [READER_SCRIPT.ParseStatus.SOURCE_TERMINATED,
			READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED]:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Manifest-checked scenario-$%02X stream stopped at parser status %d (%s), cursor +0x%04X; live $044E=$%02X $043C=$%02X; context=%s." % [
				scenario_id, terminal_status, String(parsed.get("message", "")),
				int(parsed.get("cursor_offset", -1)), int(live_context.get("ram_044E", -1)) & 0xFF,
				int(live_context.get("ram_043C", -1)) & 0xFF,
				str(parsed.get("context_requirements", []))])
	var token_list: Variant = parsed.get("tokens", [])
	var expected_prefix: Array = [0xF9, "event_record"] if scenario18_branch_terminal_cursor \
		else ([0xFD, 0xF3] if scenario_id == 0x18 \
		else ([0xFD, 0xF6, 0xF7, "event_record"] if scenario_id == 0x1E \
		else ([0xF5, "event_record"] if scenario_id == 0x2E \
		else ([0xF9, "event_record"] if scenario_id == 0x35 \
		else ([0xF5, 0xF9, "event_record"] if scenario_id == 0x36 \
		else ([0xF7, "event_record"] if scenario_id == 0x38 else ["event_record"]))))))
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
		elif scenario_id == 0x18 and not scenario18_branch_terminal_cursor and index == 1:
			if String(token.get("kind", "")) != "control_flow" \
					or int(token.get("opcode", -1)) != 0xF3 \
					or int(token.get("operand", -1)) != 0xB4:
				return _failure(Status.SOURCE_INTEGRITY_FAILURE,
					"Scenario-$18 live prefix does not match `$FD $00; $F3 $B4`." )
		elif String(token.get("kind", "")) != "opcode" \
				or int(token.get("opcode", -1)) != int(expected_prefix[index]):
			return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario-$%02X live prefix opcode order differs from its ROM bytes." % scenario_id)
		_tokens.append(token)
	if scenario_id == 0x18:
		for token_index in range(expected_prefix.size(), token_list.size()):
			var token_variant: Variant = token_list[token_index]
			if not token_variant is Dictionary:
				return _failure(Status.SOURCE_INTEGRITY_FAILURE, "Scenario-$18 reader returned a non-dictionary branch token.")
			_tokens.append(token_variant)
	if scenario_id in [0x1E, 0x2E, 0x38, 0x44]:
		if token_list.size() != expected_prefix.size() + 1:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$%02X root token count differs from its ROM-terminated source span." % scenario_id)
		var terminal_variant: Variant = token_list[expected_prefix.size()]
		if not terminal_variant is Dictionary or String(terminal_variant.get("kind", "")) != "control_flow" \
				or int(terminal_variant.get("opcode", -1)) != 0xFB \
				or not bool(terminal_variant.get("source_span_validated", false)) \
				or int(terminal_variant.get("continuation_depth", -1)) != 0:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$%02X trailing `$FB` is not a validated root termination token." % scenario_id)
		_tokens.append(terminal_variant)
	if scenario18_branch_terminal_cursor:
		var branch_terminal: Variant = token_list.back() if token_list is Array and not token_list.is_empty() else null
		if token_list.size() != 3 or not branch_terminal is Dictionary \
				or String(branch_terminal.get("kind", "")) != "control_flow" \
				or int(branch_terminal.get("opcode", -1)) != 0xFB \
				or int(branch_terminal.get("byte_offset", -1)) != 7 \
				or not bool(branch_terminal.get("source_span_validated", false)) \
				or int(branch_terminal.get("continuation_depth", -1)) != 0:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$18 `$AF58` is not the validated terminal byte of the selected `$AF51` branch: token_count=%d tokens=%s." % [
				token_list.size() if token_list is Array else -1, JSON.stringify(token_list)])
	if scenario_id == 0x18 and not scenario18_branch_terminal_cursor \
			and terminal_status == READER_SCRIPT.ParseStatus.SOURCE_TERMINATED:
		if token_list.size() < expected_prefix.size() + 3:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$18 terminated without its ROM-selected branch and event tokens.")
		var terminal_variant: Variant = token_list.back()
		if not terminal_variant is Dictionary or String(terminal_variant.get("kind", "")) != "control_flow" \
				or int(terminal_variant.get("opcode", -1)) != 0xFB \
				or not bool(terminal_variant.get("source_span_validated", false)) \
				or int(terminal_variant.get("continuation_depth", -1)) != 0:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$18 `$FB` is not the source-validated root terminator after the selected branch.")
	if scenario_id == 0x1E and (not live_context.has("ram_05FB") \
			or bool(parsed.get("context_required", true))):
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Scenario-$1E requires the live field value `$05FB` to resolve `$FD $02`.",
			{"scenario_id": scenario_id, "context_requirements": parsed.get("context_requirements", [])})
	if source_byte_offset > 0:
		var cursor_found := false
		for index in _tokens.size():
			if int(_tokens[index].get("byte_offset", -1)) == source_byte_offset:
				_token_index = index
				_source_byte_cursor = source_byte_offset
				cursor_found = true
				break
		if not cursor_found:
			return _failure(Status.SOURCE_STATE_REQUIRED,
				"The live bank-$10 cursor does not land on a decoded ROM token boundary.",
				{"scenario_id": scenario_id, "source_byte_offset": source_byte_offset})
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
		"source_root_pointer_cpu": _source_root_pointer_cpu,
		"source_byte_index": _source_byte_cursor,
		"continuation_depth": 0,
		"root_state_source": "live `$0518` selector, ROM `$89BF` table entry, manifest-checked bank-$10 stream, and required field context",
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


func _begin_scenario_1c_from_live_pointer(source_pointer_cpu: int,
		live_context: Dictionary) -> Dictionary:
	if source_pointer_cpu == 0xB4BD:
		return _begin_scenario_1c_b4bd_terminal_cursor(live_context)
	if source_pointer_cpu == 0xB49E:
		return _begin_scenario_1c_b49e_branch(source_pointer_cpu, live_context)
	if source_pointer_cpu == 0xB4B6:
		return _begin_scenario_1c_b4b6_branch(source_pointer_cpu, live_context)
	var bundle := _load_and_verify_pass_scenario_1c()
	if not bool(bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(bundle.get("error", "Scenario-$1C source validation failed.")))
	var pointer_cpu := int(bundle["pointer_cpu"])
	if source_pointer_cpu != pointer_cpu:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Live bank-$10 pointer does not match scenario-$1C's manifest-checked root pointer.",
			{"scenario_id": 0x1C, "live_pointer": source_pointer_cpu,
			"manifest_root_pointer": pointer_cpu})
	_scenario_id = 0x1C
	_source_pointer_cpu = source_pointer_cpu
	_source_root_pointer_cpu = pointer_cpu
	_source_file_offset = 0x021BF3
	_source_bytes = bundle["scenario_bytes"]
	var parse_context: Dictionary = {}
	for key in ["ram_0441", "ram_044E", "ram_043B", "ram_043C", "ram_0516", "ram_0638",
			"ram_fd00_mirror_flag"]:
		if live_context.has(key):
			parse_context[key] = int(live_context[key]) & 0xFF
			_ram_state["$" + key.trim_prefix("ram_")] = int(live_context[key]) & 0xFF
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	var parsed: Dictionary = READER_SCRIPT.read_project_scenario(0x1C, parse_context)
	var terminal_status := int(parsed.get("terminal_status", -1))
	var parsed_status := int(parsed.get("status", -1))
	if terminal_status != READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED \
			or parsed_status not in [READER_SCRIPT.ParseStatus.CONTEXT_REQUIRED,
			READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED]:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C reader did not preserve its expected context/external boundary.",
			{"reader_status": READER_SCRIPT.status_name(parsed_status),
			"terminal_status": READER_SCRIPT.status_name(terminal_status)})
	var token_list: Variant = parsed.get("tokens", [])
	if not token_list is Array or token_list.size() < 3:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C reader did not provide its source-verified FD/FA/F3 prefix.")
	var expected_opcodes := [0xFD, 0xFA, 0xF3]
	var expected_offsets := [0, 2, 5]
	for index in expected_opcodes.size():
		var token_variant: Variant = token_list[index]
		if not token_variant is Dictionary:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$1C reader returned a non-dictionary prefix token.")
		var token: Dictionary = token_variant
		if int(token.get("opcode", -1)) != expected_opcodes[index] \
				or int(token.get("byte_offset", -1)) != expected_offsets[index]:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$1C reader prefix token does not match its pinned source bytes.")
	for token_variant in token_list:
		if not token_variant is Dictionary:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$1C reader returned a non-dictionary token.")
		var token: Dictionary = token_variant
		if int(token.get("opcode", -1)) == 0xF2:
			var target := int(token.get("target_cpu_address", -1))
			var expected_offset := 9 if target == 0xB49E else (12 if target == 0xB4B6 else -1)
			if expected_offset < 0 or int(token.get("byte_offset", -1)) != expected_offset \
					or str(token.get("status", "")) != "external_continuation_required":
				return _failure(Status.SOURCE_INTEGRITY_FAILURE,
					"Scenario-$1C F2 target is not one of the source-proven external branches.")
		_tokens.append(token)
	_source_byte_cursor = 0
	_token_index = 0
	_scenario_1c_reader_status = READER_SCRIPT.status_name(parsed_status)
	_scenario_1c_terminal_status = READER_SCRIPT.status_name(terminal_status)
	var requirements: Variant = parsed.get("context_requirements", [])
	_scenario_1c_context_requirements = requirements.duplicate() if requirements is Array else []
	_started = true
	return {
		"ok": true,
		"admitted": true,
		"status": _scenario_1c_reader_status,
		"admission_status": "source_verified",
		"scenario_id": 0x1C,
		"source_pointer_cpu": _source_pointer_cpu,
		"source_byte_index": _source_byte_cursor,
		"continuation_depth": 0,
		"reader_status": _scenario_1c_reader_status,
		"terminal_status": _scenario_1c_terminal_status,
		"context_requirements": _scenario_1c_context_requirements.duplicate(),
		"reader_tokens": _tokens.duplicate(true),
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_stream_sha256": _sha256(_source_bytes),
		"source_paths": [PASS_SCENARIO_1C_POINTER_PATH, PASS_SCENARIO_1C_STREAM_PATH],
		"callback_executed": false,
		"scheduler_dispatched": false,
		"emulator_frame_input_used": false,
		"capture_ram_input_used": false,
	}


func _begin_scenario_1c_b49e_branch(source_pointer_cpu: int,
		live_context: Dictionary) -> Dictionary:
	var bundle := _load_and_verify_pass_scenario_1c()
	if not bool(bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(bundle.get("error", "Scenario-$1C source validation failed.")))
	var target_bytes: PackedByteArray = bundle.get("b49e_bytes", PackedByteArray())
	if source_pointer_cpu != 0xB49E or target_bytes != PackedByteArray([
		0xF9, 0x1D, 0x2C, 0x3C, 0x01, 0x78, 0x58, 0xFB]) \
			or _sha256(target_bytes) != PASS_SCENARIO_1C_B49E_SHA256 \
			or int(live_context.get("continuation_depth", -1)) != 0:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Scenario-$1C `$B49E` requires its hash-pinned F2 target and restored zero-depth `$FB` context.",
			{"live_pointer": source_pointer_cpu,
			"continuation_depth": int(live_context.get("continuation_depth", -1))})
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	var parsed := READER_SCRIPT.parse_bytes(0x1C, target_bytes, PASS_SCENARIO_1C_B49E_PATH,
		{"continuation_depth": 0})
	var token_variant: Variant = parsed.get("tokens", [])
	if int(parsed.get("terminal_status", -1)) != READER_SCRIPT.ParseStatus.SOURCE_TERMINATED \
			or bool(parsed.get("context_required", false)) \
			or not token_variant is Array or token_variant.size() != 3:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$B49E` target did not decode to its pinned F9/record/root-FB prefix.",
			{"reader_status": READER_SCRIPT.status_name(int(parsed.get("status", -1))),
			"terminal_status": READER_SCRIPT.status_name(int(parsed.get("terminal_status", -1)))})
	var f9: Dictionary = token_variant[0]
	var record: Dictionary = token_variant[1]
	var fb: Dictionary = token_variant[2]
	if String(f9.get("kind", "")) != "opcode" or int(f9.get("opcode", -1)) != 0xF9 \
			or int(f9.get("byte_offset", -1)) != 0 \
			or f9.get("operand_bytes", []) != [0x1D, 0x2C] \
			or String(record.get("kind", "")) != "event_record" \
			or int(record.get("byte_offset", -1)) != 3 \
			or record.get("raw_bytes", PackedByteArray()) != PackedByteArray([0x3C, 0x01, 0x78, 0x58]) \
			or record.get("ram_assignments", {}) != {"$0523": 0x3C, "$0524": 0x01,
				"$0528": 0x78, "$0529": 0x58} \
			or int(fb.get("opcode", -1)) != 0xFB or int(fb.get("byte_offset", -1)) != 7:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$B49E` token fields differ from the pinned ROM prefix.")
	_scenario_id = 0x1C
	_source_pointer_cpu = 0xB49E
	_source_root_pointer_cpu = 0xB49E
	_source_file_offset = 0x0234AE
	_source_bytes = target_bytes.duplicate()
	_tokens.clear()
	for token in token_variant:
		_tokens.append(token)
	for address_variant in live_context:
		var address_text := String(address_variant)
		if address_text.begins_with("ram_"):
			_ram_state["$" + address_text.trim_prefix("ram_")] = int(live_context[address_variant]) & 0xFF
	_scenario_1c_child_branch_active = false
	_scenario_1c_reader_status = READER_SCRIPT.status_name(int(parsed.get("status", -1)))
	_scenario_1c_terminal_status = READER_SCRIPT.status_name(int(parsed.get("terminal_status", -1)))
	_scenario_1c_context_requirements.clear()
	_started = true
	return {"ok": true, "admitted": true,
		"status": "scenario1c_b49e_f2_branch_admitted",
		"scenario_id": _scenario_id, "source_pointer_cpu": _source_pointer_cpu,
		"source_file_offset": _source_file_offset,
		"source_stream_sha256": PASS_SCENARIO_1C_B49E_SHA256,
		"reader_tokens": _tokens.duplicate(true),
		"continuation_depth": 0, "source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_paths": [PASS_SCENARIO_1C_MANIFEST, PASS_SCENARIO_1C_B49E_PATH],
		"callback_executed": false, "scheduler_dispatched": false,
		"emulator_frame_input_used": false, "capture_ram_input_used": false}


func _begin_scenario_1c_b4b6_branch(source_pointer_cpu: int,
		live_context: Dictionary) -> Dictionary:
	var bundle := _load_and_verify_pass_scenario_1c()
	if not bool(bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(bundle.get("error", "Scenario-$1C source validation failed.")))
	var target_bytes: PackedByteArray = bundle.get("b4b6_bytes", PackedByteArray())
	if source_pointer_cpu != 0xB4B6 or target_bytes != PackedByteArray([
		0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB]) \
			or _sha256(target_bytes) != PASS_SCENARIO_1C_B4B6_SHA256 \
			or int(live_context.get("continuation_depth", -1)) != 0:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Scenario-$1C `$B4B6` requires its hash-pinned F2 target and restored zero-depth `$FB` context.",
			{"live_pointer": source_pointer_cpu,
			"continuation_depth": int(live_context.get("continuation_depth", -1))})
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	var parsed := READER_SCRIPT.parse_bytes(0x1C, target_bytes, PASS_SCENARIO_1C_B4B6_PATH,
		{"continuation_depth": 0})
	var token_variant: Variant = parsed.get("tokens", [])
	if int(parsed.get("terminal_status", -1)) != READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED \
			or bool(parsed.get("context_required", false)) \
			or not token_variant is Array or token_variant.size() != 3:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$B4B6` target did not decode to its pinned F9/record/FB prefix.",
			{"reader_status": READER_SCRIPT.status_name(int(parsed.get("status", -1))),
			"terminal_status": READER_SCRIPT.status_name(int(parsed.get("terminal_status", -1)))})
	var f9: Dictionary = token_variant[0]
	var record: Dictionary = token_variant[1]
	var fb: Dictionary = token_variant[2]
	if String(f9.get("kind", "")) != "opcode" or int(f9.get("opcode", -1)) != 0xF9 \
			or int(f9.get("byte_offset", -1)) != 0 \
			or f9.get("operand_bytes", []) != [0x11, 0x2C] \
			or String(record.get("kind", "")) != "event_record" \
			or int(record.get("byte_offset", -1)) != 3 \
			or record.get("raw_bytes", PackedByteArray()) != PackedByteArray([0x38, 0x63, 0x7A, 0x58]) \
			or record.get("ram_assignments", {}) != {"$0523": 0x38, "$0524": 0x63,
				"$0528": 0x7A, "$0529": 0x58} \
			or int(fb.get("opcode", -1)) != 0xFB or int(fb.get("byte_offset", -1)) != 7 \
			or bool(fb.get("source_span_validated", true)) \
			or int(fb.get("continuation_depth", -1)) != 0:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$B4B6` token fields differ from the pinned ROM prefix.")
	# The generic reader marks a local `$FB` as external unless the branch hash is
	# in its root whitelist. This consumer independently validated the exact
	# manifest span above and received the caller's zero-depth return context, so
	# the same bounded `$80CF` terminal contract used by `$B49E` applies here.
	fb["source_span_validated"] = true
	fb["continuation_depth"] = 0
	token_variant[2] = fb
	_scenario_id = 0x1C
	_source_pointer_cpu = 0xB4B6
	_source_root_pointer_cpu = 0xB4B6
	_source_file_offset = 0x0234C6
	_source_bytes = target_bytes.duplicate()
	_tokens.clear()
	for token in token_variant:
		_tokens.append(token)
	for address_variant in live_context:
		var address_text := String(address_variant)
		if address_text.begins_with("ram_"):
			_ram_state["$" + address_text.trim_prefix("ram_")] = int(live_context[address_variant]) & 0xFF
	_scenario_1c_child_branch_active = false
	_scenario_1c_reader_status = READER_SCRIPT.status_name(int(parsed.get("status", -1)))
	_scenario_1c_terminal_status = READER_SCRIPT.status_name(READER_SCRIPT.ParseStatus.SOURCE_TERMINATED)
	_scenario_1c_context_requirements.clear()
	_started = true
	return {"ok": true, "admitted": true,
		"status": "scenario1c_b4b6_f2_branch_admitted",
		"scenario_id": _scenario_id, "source_pointer_cpu": _source_pointer_cpu,
		"source_file_offset": _source_file_offset,
		"source_stream_sha256": PASS_SCENARIO_1C_B4B6_SHA256,
		"reader_tokens": _tokens.duplicate(true),
		"continuation_depth": 0, "source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_paths": [PASS_SCENARIO_1C_MANIFEST, PASS_SCENARIO_1C_B4B6_PATH],
		"callback_executed": false, "scheduler_dispatched": false,
		"emulator_frame_input_used": false, "capture_ram_input_used": false}


## Admit the live post-record cursor at the final `$FB` in the hash-pinned
## `$B4B6` target. The caller owns the wait/phase proof; this method only binds
## the live pointer and callback identity to ROM bytes and positions the reader
## at the source terminator.
func _begin_scenario_1c_b4bd_terminal_cursor(live_context: Dictionary) -> Dictionary:
	if int(live_context.get("continuation_depth", -1)) != 0 \
			or int(live_context.get("ram_0518", -1)) != 0x1C \
			or int(live_context.get("ram_0524", -1)) != 0x63:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Scenario-$1C `$B4BD` requires the live callback-$63 state and zero-depth source context.",
			{"source_pointer_cpu": 0xB4BD,
			"continuation_depth": int(live_context.get("continuation_depth", -1)),
			"scenario_id": int(live_context.get("ram_0518", -1)),
			"callback_id": int(live_context.get("ram_0524", -1))})
	var admitted := _begin_scenario_1c_b4b6_branch(0xB4B6, live_context)
	if not bool(admitted.get("ok", false)):
		return admitted
	if _source_bytes != PackedByteArray([
			0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB]) \
			or _sha256(_source_bytes) != PASS_SCENARIO_1C_B4B6_SHA256 \
			or _tokens.size() != 3 \
			or int(_tokens[2].get("byte_offset", -1)) != 7 \
			or int(_tokens[2].get("opcode", -1)) != 0xFB \
			or not bool(_tokens[2].get("source_span_validated", false)) \
			or int(_tokens[2].get("continuation_depth", -1)) != 0:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$B4BD` is not the validated final `$FB` byte of the `$B4B6` source span.")
	_source_pointer_cpu = 0xB4BD
	_source_byte_cursor = 7
	_token_index = 2
	_source_file_offset = 0x0234CD
	return {
		"ok": true,
		"admitted": true,
		"status": "scenario1c_b4bd_fb_cursor_admitted",
		"scenario_id": 0x1C,
		"source_pointer_cpu": _source_pointer_cpu,
		"source_root_pointer_cpu": _source_root_pointer_cpu,
		"source_file_offset": _source_file_offset,
		"source_byte_index": _source_byte_cursor,
		"source_span_cpu_start": 0xB4B6,
		"source_span_sha256": PASS_SCENARIO_1C_B4B6_SHA256,
		"continuation_depth": 0,
		"reader_tokens": _tokens.duplicate(true),
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_paths": [PASS_SCENARIO_1C_MANIFEST, PASS_SCENARIO_1C_B4B6_PATH],
		"callback_executed": false,
		"scheduler_dispatched": false,
		"emulator_frame_input_used": false,
		"capture_ram_input_used": false,
	}


## Start the bounded nested scenario-$1C event selected by live `$F3` handler
## results. This accepts only the single verified `$BB4B` child span.
func begin_scenario_1c_fa_branch_from_live_source(source_pointer_cpu: int,
		live_ram: PackedByteArray) -> Dictionary:
	_reset()
	if source_pointer_cpu != 0xBB4B or live_ram.size() != 0x800:
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Scenario-$1C child reader requires live `$BB4B` and the full 2 KiB RAM image.",
			{"live_pointer": source_pointer_cpu, "ram_size": live_ram.size()})
	var bundle := _load_and_verify_pass_scenario_1c()
	if not bool(bundle.get("ok", false)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			str(bundle.get("error", "Scenario-$1C source validation failed.")))
	var branch_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_FA_BRANCH_PATH)
	if branch_bytes != PackedByteArray([0x30, 0x1F, 0x4C, 0x00, 0xFB]) \
			or _sha256(branch_bytes) != PASS_SCENARIO_1C_FA_BRANCH_SHA256:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$BB4B` child bytes failed their ROM hash check.")
	if not _load_and_verify_task_seed_sources():
		return _failure(Status.SOURCE_INTEGRITY_FAILURE, error_message)
	var live_context := {
		"continuation_depth": 1,
		"ram_0516": int(live_ram[0x0516]),
		"ram_0441": int(live_ram[0x0441]),
		"ram_044E": int(live_ram[0x044E]),
		"ram_043B": int(live_ram[0x043B]),
		"ram_043C": int(live_ram[0x043C]),
		"ram_0638": int(live_ram[0x0638]),
		"ram_052A": int(live_ram[0x052A]),
	}
	var parsed := READER_SCRIPT.parse_bytes(0x1C, branch_bytes,
		PASS_SCENARIO_1C_FA_BRANCH_PATH, live_context)
	var tokens_variant: Variant = parsed.get("tokens", [])
	if int(parsed.get("terminal_status", -1)) != READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED \
			or not tokens_variant is Array or tokens_variant.size() != 2 \
			or String(tokens_variant[0].get("kind", "")) != "event_record" \
			or tokens_variant[0].get("raw_bytes", PackedByteArray()) != PackedByteArray([0x30, 0x1F, 0x4C, 0x00]) \
			or int(tokens_variant[1].get("opcode", -1)) != 0xFB:
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$1C `$BB4B` child did not parse to the pinned event record plus `$FB` return.",
			{"parse_status": parsed.get("status_name", ""), "message": parsed.get("message", "")})
	_scenario_id = 0x1C
	_source_pointer_cpu = 0xBB4B
	_source_root_pointer_cpu = 0xBB4B
	_source_file_offset = 0x023B5B
	_source_bytes = branch_bytes
	_tokens.clear()
	for token_variant in tokens_variant:
		_tokens.append(token_variant)
	for address in range(0x0516, 0x053A):
		_ram_state["$%04X" % address] = int(live_ram[address])
	for address in [0x0441, 0x044E, 0x043B, 0x043C, 0x0638, 0x052A]:
		_ram_state["$%04X" % address] = int(live_ram[address])
	_scenario_1c_child_branch_active = true
	_scenario_1c_reader_status = READER_SCRIPT.status_name(int(parsed.get("status", -1)))
	_scenario_1c_terminal_status = READER_SCRIPT.status_name(int(parsed.get("terminal_status", -1)))
	_started = true
	return {"ok": true, "status": "scenario1c_selected_child_admitted",
		"scenario_id": 0x1C, "source_pointer_cpu": _source_pointer_cpu,
		"source_file_offset": _source_file_offset,
		"source_stream_sha256": PASS_SCENARIO_1C_FA_BRANCH_SHA256,
		"reader_tokens": _tokens.duplicate(true),
		"continuation_depth": 1, "source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_paths": [PASS_SCENARIO_1C_FA_BRANCH_PATH],
		"emulator_frame_input_used": false, "capture_ram_input_used": false}


func _load_and_verify_pass_scenario_1c() -> Dictionary:
	var manifest_file := FileAccess.open(PASS_SCENARIO_1C_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return {"ok": false, "error": "Scenario-$1C ROM source manifest is unavailable."}
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return {"ok": false, "error": "Scenario-$1C ROM source manifest is malformed."}
	var manifest: Dictionary = manifest_variant
	var rom: Dictionary = manifest.get("source_rom", {})
	var scenario: Dictionary = manifest.get("scenario_1C", {})
	if str(manifest.get("schema", "")) != "ct2-pass-scenario-1c-source-v1" \
			or str(rom.get("sha256", "")) != EXPECTED_ROM_SHA256 \
			or int(rom.get("mapper", -1)) != 4 \
			or str(scenario.get("pointer_entry_bytes", "")) != "E3 9B" \
			or str(scenario.get("stream_cpu_address", "")) != "0x9BE3" \
			or str(scenario.get("stream_file_offset", "")) != "0x021BF3" \
			or int(scenario.get("length_bytes", -1)) != 15 \
			or str(scenario.get("sha256", "")) != PASS_SCENARIO_1C_STREAM_SHA256:
		return {"ok": false, "error": "Scenario-$1C manifest targets a different ROM, pointer, or stream."}
	if str(scenario.get("pointer_entry_cpu_address", "")) != "0x89F7" \
			or str(scenario.get("pointer_entry_file_offset", "")) != "0x020A07":
		return {"ok": false, "error": "Scenario-$1C manifest pointer-entry provenance changed."}
	var pointer_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_POINTER_PATH)
	var scenario_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_STREAM_PATH)
	var branch_row: Dictionary = {}
	var b49e_row: Dictionary = {}
	var b4b6_row: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		match String(span.get("name", "")):
			"scenario_1C_FA_branch_BB4B_BB50": branch_row = span
			"bank10_F3_root_F2_target_B49E_B4A6": b49e_row = span
			"bank10_F3_root_F2_target_B4B6_B4BE": b4b6_row = span
	var branch_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_FA_BRANCH_PATH)
	var b49e_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_B49E_PATH)
	var b4b6_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_B4B6_PATH)
	if pointer_bytes != PackedByteArray([0xE3, 0x9B]) \
			or _sha256(pointer_bytes) != PASS_SCENARIO_1C_POINTER_SHA256 \
			or scenario_bytes != PackedByteArray([0xFD, 0x00, 0xFA, 0x3E, 0x9F,
			0xF3, 0x84, 0x02, 0x04, 0xF2, 0x9E, 0xB4, 0xF2, 0xB6, 0xB4]) \
			or _sha256(scenario_bytes) != PASS_SCENARIO_1C_STREAM_SHA256 \
			or String(branch_row.get("cpu_start", "")) != "0xBB4B" \
			or String(branch_row.get("file_offset", "")) != "0x023B5B" \
			or int(branch_row.get("length_bytes", -1)) != 5 \
			or String(branch_row.get("sha256", "")) != PASS_SCENARIO_1C_FA_BRANCH_SHA256 \
			or branch_bytes != PackedByteArray([0x30, 0x1F, 0x4C, 0x00, 0xFB]) \
			or _sha256(branch_bytes) != PASS_SCENARIO_1C_FA_BRANCH_SHA256 \
			or String(b49e_row.get("cpu_start", "")) != "0xB49E" \
			or String(b49e_row.get("file_offset", "")) != "0x0234AE" \
			or int(b49e_row.get("length_bytes", -1)) != 8 \
			or String(b49e_row.get("sha256", "")) != PASS_SCENARIO_1C_B49E_SHA256 \
			or String(b49e_row.get("bytes_hex", "")).replace(" ", "") != "F91D2C3C017858FB" \
			or b49e_bytes != PackedByteArray([0xF9, 0x1D, 0x2C, 0x3C, 0x01, 0x78, 0x58, 0xFB]) \
			or _sha256(b49e_bytes) != PASS_SCENARIO_1C_B49E_SHA256 \
			or String(b4b6_row.get("cpu_start", "")) != "0xB4B6" \
			or String(b4b6_row.get("file_offset", "")) != "0x0234C6" \
			or int(b4b6_row.get("length_bytes", -1)) != 8 \
			or String(b4b6_row.get("sha256", "")) != PASS_SCENARIO_1C_B4B6_SHA256 \
			or String(b4b6_row.get("bytes_hex", "")).replace(" ", "") != "F9112C38637A58FB" \
			or b4b6_bytes != PackedByteArray([0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB]) \
			or _sha256(b4b6_bytes) != PASS_SCENARIO_1C_B4B6_SHA256:
		return {"ok": false, "error": "Scenario-$1C pointer/root/child/B49E/B4B6 bytes failed exact manifest/hash validation."}
	return {"ok": true, "pointer_cpu": 0x9BE3,
		"pointer_bytes": pointer_bytes, "scenario_bytes": scenario_bytes,
		"b49e_bytes": b49e_bytes, "b4b6_bytes": b4b6_bytes}


func _stop_scenario_1c_token(token: Dictionary, offset: int) -> Dictionary:
	var opcode := int(token.get("opcode", -1))
	var token_status := str(token.get("status", ""))
	if opcode == 0xFD and int(token.get("operand", -1)) == 0x00:
		var writes: Dictionary = token.get("ram_write", {})
		var mirror_flag := int(token.get("result", -1))
		if offset != 0 or token_status != "transformed" \
				or int(token.get("handler_target_cpu_address", -1)) != 0x8877 \
				or not bool(token.get("has_result", false)) or mirror_flag not in [0x00, 0x40] \
				or int(writes.get("$052A", -1)) != mirror_flag:
			return _failure(Status.CONTEXT_REQUIRED,
				"Scenario-$1C `$FD $00` needs the live ROM `$8877` result from holder/player-record/$0638 state.",
				{"source_byte_offset": offset, "cursor_advanced": false,
				"reader_status": "context_required",
				"terminal_status": _scenario_1c_terminal_status,
				"required_context": token.get("required_context", [])})
		_ram_state["$052A"] = mirror_flag
		_advance_cursor(int(token.get("length_bytes", 2)))
		return {"ok": true, "status": "scenario1c_fd00_live_result_applied",
			"scenario_id": _scenario_id, "source_byte_offset": offset,
			"source_byte_index_after": _source_byte_cursor,
			"handler_target_cpu_address": 0x8877,
			"ram_writes": {"$052A": mirror_flag},
			"timing_inferred": false}
	if opcode == 0xF2:
		return _failure(Status.EXTERNAL_CONTINUATION_REQUIRED,
			"Scenario-$1C `$F2` changes the source pointer to an external stream; execution is not modeled.",
			{"source_byte_offset": offset, "cursor_advanced": false,
			"reader_status": token_status,
			"terminal_status": "external_continuation_required",
			"target_cpu_address": token.get("target_cpu_address", -1)})
	var nested_requires_context := false
	if opcode == 0xFA:
		for nested_variant in token.get("f3_dispatch_tokens", []):
			if nested_variant is Dictionary and str((nested_variant as Dictionary).get("status", "")).contains("context_required"):
				nested_requires_context = true
	if token_status.contains("context_required") or nested_requires_context:
		return _failure(Status.CONTEXT_REQUIRED,
			"Scenario-$1C dispatch requires source caller context that has not been fully resolved.",
			{"source_byte_offset": offset, "cursor_advanced": false,
			"reader_status": "context_required",
			"terminal_status": _scenario_1c_terminal_status,
			"context_requirements": _scenario_1c_context_requirements.duplicate()})
	return _failure(Status.EXTERNAL_CONTINUATION_REQUIRED,
		"Scenario-$1C selected a nested/external source branch that this runtime does not execute.",
		{"source_byte_offset": offset, "cursor_advanced": false,
		"reader_status": token_status,
		"terminal_status": _scenario_1c_terminal_status,
		"target_cpu_address": token.get("target_cpu_address", -1)})


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
	if stream_row.is_empty() or (pointer_row.is_empty() and scenario_id != 0x38):
		return {"ok": false, "error": "Manifest omits scenario-$%02X pointer or stream." % scenario_id}
	var start_pointer_variant: Variant = stream_row.get("start_pointer_entry", {})
	var start_pointer_entry: Dictionary = start_pointer_variant if start_pointer_variant is Dictionary else {}
	var pointer_path := String(pointer_row.get("path", ""))
	var stream_path := String(stream_row.get("path", ""))
	var expected_pointer := int({0x1E: 0xB7DA, 0x35: 0xB7CD,
		0x36: 0xB7E4, 0x38: 0xB7C6, 0x44: 0xB7D5}.get(scenario_id, -1))
	var expected_pointer_file_offset := String({0x1E: "0x020A0B",
		0x35: "0x020A39", 0x36: "0x020A3B", 0x38: "0x020A3F", 0x44: "0x020A57"}.get(scenario_id, ""))
	var expected_stream_file_offset := String({0x1E: "0x0237EA",
		0x35: "0x0237DD", 0x36: "0x0237F4", 0x38: "0x0237D6", 0x44: "0x0237E5"}.get(scenario_id, ""))
	var expected_stream_hash := String({0x1E: "383f2248d753ef12b325c98238ee1c0eaa96c693ca427a5885536e1c16f1a496",
		0x35: "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df",
		0x36: "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f",
		0x38: "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76",
		0x44: "22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f"}.get(scenario_id, ""))
	var pointer_hash := String({0x1E: "72ac1108e6817858f37ce9d95f78b8d0c5dfc6e01041261f2684e0d47c2ecd1f",
		0x35: "751bb4c1d1d35f0a3f3c86304dffe714c0c1a6483af6e233ecff031004a22bc3",
		0x36: "5d2bc0e444947ba22ee06b40139852b88e24eb157d3175e1c6ef1c315d4d6a7a",
		0x38: "06c441c4f9845c69b60a2967047bc5e2a878f296f2d6a975b3ed4b537a63aaac",
		0x44: "dc9cfca9f5d0360d2026365799680a485504e2a2d4fc29281a1e27d18371f768"}.get(scenario_id, ""))
	var pointer_bytes := PackedByteArray()
	if scenario_id == 0x38:
		if start_pointer_entry.is_empty():
			return {"ok": false, "error": "Scenario-$38 manifest omits its root pointer metadata."}
		pointer_bytes = String(start_pointer_entry.get("bytes_hex", "")).replace(" ", "").hex_decode()
	else:
		pointer_bytes = FileAccess.get_file_as_bytes("res://" + pointer_path)
	var scenario_bytes := FileAccess.get_file_as_bytes("res://" + stream_path)
	var expected_stream_size := int({0x1E: 10, 0x35: 8,
		0x36: 38, 0x38: 7, 0x44: 5}.get(scenario_id, -1))
	var expected_pointer_path := String({0x1E: "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_1E.bin",
		0x35: "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_35.bin",
		0x36: "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_36.bin",
		0x38: "", 0x44: "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_44.bin"}.get(scenario_id, ""))
	var expected_stream_path := String({0x1E: "reference/rom_extract/gameplay/first_command_scenarios/scenario_1E.bin",
		0x35: "reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin",
		0x36: "reference/rom_extract/gameplay/first_command_scenarios/scenario_36.bin",
		0x38: "reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin",
		0x44: "reference/rom_extract/gameplay/first_command_scenarios/scenario_44.bin"}.get(scenario_id, ""))
	var pointer_cpu_text := String(pointer_row.get("cpu_address", "")) if not pointer_row.is_empty() else String(stream_row.get("start_cpu_address", ""))
	var pointer_table_cpu_text := String(pointer_row.get("table_cpu_address", "")) if not pointer_row.is_empty() else String(start_pointer_entry.get("table_cpu_address", ""))
	var pointer_table_file_offset := String(pointer_row.get("table_file_offset", "")) if not pointer_row.is_empty() else String(start_pointer_entry.get("table_file_offset", ""))
	var pointer_row_hash := String(pointer_row.get("sha256", "")) if not pointer_row.is_empty() else String(start_pointer_entry.get("sha256", ""))
	var pointer_row_bytes_hex := String(pointer_row.get("bytes_hex", "")) if not pointer_row.is_empty() else String(start_pointer_entry.get("bytes_hex", ""))
	var pointer_row_size := int(pointer_row.get("length_bytes", -1)) if not pointer_row.is_empty() else int(start_pointer_entry.get("length_bytes", -1))
	var pointer_row_valid := pointer_row_size == 2 \
			and pointer_cpu_text.to_lower() == "0x%04x" % expected_pointer \
			and pointer_table_cpu_text.to_lower() == "0x89bf" \
			and pointer_table_file_offset == expected_pointer_file_offset \
			and pointer_row_hash == pointer_hash \
			and pointer_row_bytes_hex.replace(" ", "").to_lower() == pointer_bytes.hex_encode()
	var verified_source_paths := [stream_path] if pointer_path.is_empty() else [pointer_path, stream_path]
	var verified_sources := {stream_path: scenario_bytes}
	if not pointer_path.is_empty():
		verified_sources[pointer_path] = pointer_bytes
	if not pointer_row_valid \
			or pointer_path != expected_pointer_path or stream_path != expected_stream_path \
			or String(stream_row.get("start_cpu_address", "")).to_lower() != "0x%04x" % expected_pointer \
			or String(stream_row.get("file_offset", "")) != expected_stream_file_offset \
			or int(stream_row.get("length_bytes", -1)) != expected_stream_size \
			or String(stream_row.get("sha256", "")) != expected_stream_hash \
			or pointer_bytes.size() != 2 or _sha256(pointer_bytes) != pointer_hash \
			or pointer_row_bytes_hex.replace(" ", "").to_lower() != pointer_bytes.hex_encode() \
			or scenario_bytes.size() != expected_stream_size or _sha256(scenario_bytes) != expected_stream_hash:
		return {"ok": false, "error": "Scenario-$%02X pointer/stream metadata or bytes failed manifest/hash validation." % scenario_id}
	return {"ok": true, "pointer_bytes": pointer_bytes, "scenario_bytes": scenario_bytes,
		"source_paths": verified_source_paths,
		"sources": verified_sources}


func _load_and_verify_scenario_2e() -> Dictionary:
	var manifest_file := FileAccess.open(SCENARIO_2E_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return {"ok": false, "error": "Scenario-$2E source manifest is unavailable."}
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return {"ok": false, "error": "Scenario-$2E source manifest is malformed."}
	var manifest: Dictionary = manifest_variant
	var scenario_variant: Variant = manifest.get("scenario", {})
	var scenario: Dictionary = scenario_variant if scenario_variant is Dictionary else {}
	if String(manifest.get("schema", "")) != "ct2-bank10-scenario-2e-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or int(manifest.get("source_rom_size_bytes", -1)) != 393232 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or String(scenario.get("scenario_id", "")) != "$2E" \
			or String(scenario.get("prg_bank", "")) != "$10" \
			or String(scenario.get("pointer_table_cpu_address", "")) != "0x89BF" \
			or String(scenario.get("pointer_table_file_offset", "")) != "0x0209CF" \
			or String(scenario.get("pointer_entry_file_offset", "")) != "0x020A2B" \
			or String(scenario.get("pointer_entry_path", "")) != SCENARIO_2E_POINTER_PATH.trim_prefix("res://") \
			or String(scenario.get("pointer_entry_bytes_hex", "")).replace(" ", "").to_lower() != "4eb7" \
			or String(scenario.get("pointer_entry_sha256", "")) != SCENARIO_2E_POINTER_SHA256 \
			or String(scenario.get("start_cpu_address", "")) != "0xB74E" \
			or scenario.get("end_boundary_pointer_entry_ids", []) != ["$3F"] \
			or String(scenario.get("end_cpu_address_exclusive", "")) != "0xB754" \
			or String(scenario.get("stream_file_offset", "")) != "0x02375E" \
			or String(scenario.get("stream_end_file_offset_exclusive", "")) != "0x023764" \
			or String(scenario.get("stream_path", "")) != SCENARIO_2E_STREAM_PATH.trim_prefix("res://") \
			or int(scenario.get("length_bytes", -1)) != 6 \
			or String(scenario.get("stream_sha256", "")) != SCENARIO_2E_STREAM_SHA256 \
			or String(scenario.get("stream_bytes_hex", "")).replace(" ", "").to_lower() != "f578368b6dfb":
		return {"ok": false, "error": "Scenario-$2E manifest metadata differs from the source-pinned ROM span."}
	var pointer_bytes := FileAccess.get_file_as_bytes(SCENARIO_2E_POINTER_PATH)
	var scenario_bytes := FileAccess.get_file_as_bytes(SCENARIO_2E_STREAM_PATH)
	if pointer_bytes != PackedByteArray([0x4E, 0xB7]) \
			or _sha256(pointer_bytes) != SCENARIO_2E_POINTER_SHA256 \
			or scenario_bytes != PackedByteArray([0xF5, 0x78, 0x36, 0x8B, 0x6D, 0xFB]) \
			or _sha256(scenario_bytes) != SCENARIO_2E_STREAM_SHA256:
		return {"ok": false, "error": "Scenario-$2E packaged pointer or stream failed byte/hash validation."}
	var pointer_relative_path := SCENARIO_2E_POINTER_PATH.trim_prefix("res://")
	var stream_relative_path := SCENARIO_2E_STREAM_PATH.trim_prefix("res://")
	return {"ok": true, "pointer_bytes": pointer_bytes, "scenario_bytes": scenario_bytes,
		"source_paths": [pointer_relative_path, stream_relative_path],
		"sources": {pointer_relative_path: pointer_bytes, stream_relative_path: scenario_bytes}}


func _load_and_verify_pass_scenario_18() -> Dictionary:
	var manifest_file := FileAccess.open(PASS_SCENARIO_18_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return {"ok": false, "error": "PASS scenario-$18 source manifest is unavailable."}
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "error": "PASS scenario-$18 source manifest is malformed."}
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-pass-scenario-18-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or String(manifest.get("scenario_id", "")) != "$18" \
			or String(manifest.get("start_cpu_address", "")) != "0x9E3E" \
			or String(manifest.get("pointer_entry_cpu_address", "")) != "0x89EF" \
			or String(manifest.get("pointer_entry_file_offset", "")) != "0x0209FF" \
			or String(manifest.get("pointer_entry_bytes_hex", "")).replace(" ", "") != "3E9E" \
			or String(manifest.get("pointer_entry_sha256", "")) != PASS_SCENARIO_18_POINTER_SHA256 \
			or String(manifest.get("end_boundary_pointer_entry_id", "")) != "$32" \
			or String(manifest.get("end_cpu_address_exclusive", "")) != "0x9E57" \
			or String(manifest.get("file_offset", "")) != "0x021E4E" \
			or String(manifest.get("end_file_offset_exclusive", "")) != "0x021E67" \
			or int(manifest.get("length_bytes", -1)) != 25 \
			or String(manifest.get("sha256", "")) != PASS_SCENARIO_18_STREAM_SHA256:
		return {"ok": false, "error": "PASS scenario-$18 manifest pointer, bound, ROM, or hash metadata changed."}
	var pointer_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_18_ROOT + "scenario_pointer_18.bin")
	var scenario_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_18_ROOT + "scenario_18.bin")
	var branch_manifest: Dictionary = {}
	for branch_variant in manifest.get("external_branches", []):
		if branch_variant is Dictionary and String((branch_variant as Dictionary).get("target_cpu_address", "")) == "0xAF51":
			branch_manifest = branch_variant
			break
	var branch_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_18_ROOT + "scenario_18_branch_af51.bin")
	if pointer_bytes != PackedByteArray([0x3E, 0x9E]) \
			or _sha256(pointer_bytes) != PASS_SCENARIO_18_POINTER_SHA256 \
			or scenario_bytes.size() != 25 or _sha256(scenario_bytes) != PASS_SCENARIO_18_STREAM_SHA256 \
			or scenario_bytes != PackedByteArray([0xFD, 0x00, 0xF3, 0xB4, 0x03, 0x02, 0x0B,
				0xF3, 0x1E, 0x51, 0xAF, 0x59, 0xAF, 0x90, 0xAF, 0xAA, 0xAF,
				0xF9, 0x15, 0x2B, 0x3F, 0x2A, 0x19, 0x47, 0xFB]) \
			or String(branch_manifest.get("file", "")) != "scenario_18_branch_af51.bin" \
			or String(branch_manifest.get("file_offset", "")) != "0x022F61" \
			or int(branch_manifest.get("length_bytes", -1)) != 8 \
			or String(branch_manifest.get("sha256", "")) != PASS_SCENARIO_18_AF51_SHA256 \
			or branch_bytes != PackedByteArray([0xF9, 0x05, 0x2B, 0x3C, 0x72, 0x66, 0x47, 0xFB]) \
			or _sha256(branch_bytes) != PASS_SCENARIO_18_AF51_SHA256:
		return {"ok": false, "error": "PASS scenario-$18 root or selected `$AF51` branch bytes failed manifest/hash validation."}
	return {"ok": true, "pointer_bytes": pointer_bytes, "scenario_bytes": scenario_bytes,
		"scenario18_branch_af51": branch_bytes,
		"source_paths": ["scenario_pointer_18.bin", "scenario_18.bin", "scenario_18_branch_af51.bin"],
		"sources": {"scenario_pointer_18.bin": pointer_bytes, "scenario_18.bin": scenario_bytes,
			"scenario_18_branch_af51.bin": branch_bytes}}


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
	if _scenario_id == 0x1C and kind == "event_record":
		return _consume_event_record(token, offset)
	if _scenario_id == 0x1C:
		if _source_pointer_cpu in [0xB49E, 0xB4B6] and kind == "opcode" \
				and int(token.get("opcode", -1)) == 0xF9:
			return _consume_decoded_opcode(token, offset, length)
		if _source_pointer_cpu in [0xB49E, 0xB4B6, 0xB4BD] and kind == "control_flow" \
				and int(token.get("opcode", -1)) == 0xFB:
			return _consume_root_fb(token, offset)
		return _stop_scenario_1c_token(token, offset)
	if _scenario_id == 0x18 and kind == "control_flow" \
			and int(token.get("opcode", -1)) == 0xF3:
		return _consume_scenario18_f3(token, offset)
	if kind == "event_record":
		return _consume_event_record(token, offset)
	if kind == "opcode":
		return _consume_decoded_opcode(token, offset, length)
	if kind == "control_flow" and int(token.get("opcode", -1)) == 0xFB:
		return _consume_root_fb(token, offset)
	return _failure(Status.UNSUPPORTED_OPERATION, "This task slice does not execute the returned token kind.",
		{"token_kind": kind, "source_byte_offset": offset, "cursor_advanced": false})


func _consume_scenario18_f3(token: Dictionary, offset: int) -> Dictionary:
	var operand := int(token.get("operand", -1))
	if operand == 0x1E:
		var target := int(token.get("selected_target_cpu_address", -1))
		if String(token.get("status", "")) != "external_continuation_required" \
				or int(token.get("selector_result", -1)) != 0 \
				or target != 0xAF51 or _scenario18_branch_af51.size() != 8 \
				or _sha256(_scenario18_branch_af51) != PASS_SCENARIO_18_AF51_SHA256:
			return _failure(Status.EXTERNAL_CONTINUATION_REQUIRED,
				"Scenario-$18 `$F3 $1E` selected an unimplemented external source branch.",
				{"source_byte_offset": offset, "selected_target_cpu_address": target,
				"selector_result": int(token.get("selector_result", -1)),
				"cursor_advanced": false, "token": token.duplicate(true)})
		var parent_pointer := _source_root_pointer_cpu
		var parsed_branch: Dictionary = READER_SCRIPT.parse_bytes(0x18, _scenario18_branch_af51,
			"res://reference/rom_extract/gameplay/pass_scenario_18/scenario_18_branch_af51.bin",
			{"continuation_depth": 0, "ram_0516": int(_ram_state.get("$0516", 0))})
		var branch_tokens: Variant = parsed_branch.get("tokens", [])
		if int(parsed_branch.get("terminal_status", -1)) != READER_SCRIPT.ParseStatus.EXTERNAL_CONTINUATION_REQUIRED \
				or not branch_tokens is Array or branch_tokens.size() != 3 \
				or String(branch_tokens[0].get("kind", "")) != "opcode" \
				or int(branch_tokens[0].get("opcode", -1)) != 0xF9 \
				or String(branch_tokens[1].get("kind", "")) != "event_record" \
				or int(branch_tokens[1].get("byte_offset", -1)) != 3 \
				or branch_tokens[1].get("raw_bytes", PackedByteArray()) != PackedByteArray([0x3C, 0x72, 0x66, 0x47]) \
				or String(branch_tokens[2].get("kind", "")) != "control_flow" \
				or int(branch_tokens[2].get("opcode", -1)) != 0xFB \
				or int(branch_tokens[2].get("byte_offset", -1)) != 7:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$18 `$AF51` branch did not decode to its pinned `$F9`, event, and local `$FB` bytes.",
				{"target_cpu_address": target, "parse_message": parsed_branch.get("message", ""),
				"terminal_status": parsed_branch.get("terminal_status", -1)})
		_scenario18_parent_root_pointer_cpu = parent_pointer
		_scenario18_active_external_branch = true
		_source_pointer_cpu = target
		_source_root_pointer_cpu = target
		_source_file_offset = 0x022F61
		_source_bytes = _scenario18_branch_af51.duplicate()
		_tokens.clear()
		for branch_token: Variant in branch_tokens:
			_tokens.append(branch_token)
		_source_byte_cursor = 0
		_token_index = 0
		return {"ok": true, "status": "scenario18_external_branch_entered",
			"scenario_id": 0x18, "parent_source_pointer_cpu": parent_pointer,
			"source_pointer_cpu": target, "source_file_offset": _source_file_offset,
			"source_stream_sha256": PASS_SCENARIO_18_AF51_SHA256,
			"source_byte_offset": offset, "selector_result": 0,
			"source_cursor_reset": true, "local_branch_terminator_is_root_terminator": false,
			"timing_inferred": false}
	if operand != 0xB4 or String(token.get("status", "")) != "selected":
		return _failure(Status.SOURCE_STATE_REQUIRED,
			"Scenario-$18 `$F3 $B4` requires its live `$044E` branch selection.",
			{"source_byte_offset": offset, "cursor_advanced": false})
	var resume_offset := int(token.get("resume_byte_offset", -1))
	var selector := int(token.get("ram_044E", -1))
	if selector not in [0, 1, 2] or resume_offset not in [7, 17] \
			or int(token.get("skip_byte_offset", -1)) != 4 + selector \
			or int(token.get("skip_byte", -1)) != int(_source_bytes[4 + selector]) \
			or resume_offset != int(token.get("skip_byte_offset", -1)) + int(token.get("skip_byte", -1)):
		return _failure(Status.SOURCE_INTEGRITY_FAILURE,
			"Scenario-$18 `$F3 $B4` branch result differs from the pinned inline ROM bytes.",
			{"source_byte_offset": offset, "cursor_advanced": false})
	_source_byte_cursor = resume_offset
	_token_index += 1
	return {"ok": true, "status": "scenario18_f3_branch_selected",
		"scenario_id": 0x18, "source_byte_offset": offset,
		"source_byte_index_after": _source_byte_cursor,
		"ram_044E": selector, "skip_byte_offset": int(token["skip_byte_offset"]),
		"skip_byte": int(token["skip_byte"]),
		"branch_kind": "f9_event_root" if resume_offset == 17 else "f3_1e_external_dispatch",
		"timing_inferred": false}


func get_state() -> Dictionary:
	return {
		"started": _started,
		"terminated": _terminated,
		"scenario_id": _scenario_id,
		"source_pointer_cpu": _source_pointer_cpu,
		"source_byte_index": _source_byte_cursor,
		"token_index": _token_index,
		"ram_state": _ram_state.duplicate(true),
		"reader_status": _scenario_1c_reader_status,
		"terminal_status": _scenario_1c_terminal_status,
		"context_requirements": _scenario_1c_context_requirements.duplicate(),
		"scheduler_dispatched": false,
		"callback_executed": false,
		"error": error_message,
	}


func _consume_decoded_opcode(token: Dictionary, offset: int, length: int) -> Dictionary:
	var opcode := int(token.get("opcode", -1))
	var writes: Dictionary = token.get("ram_write", {}).duplicate(true)
	if _scenario_id == 0x18 and opcode == 0xFD:
		if offset != 0 or length != 2 or int(token.get("operand", -1)) != 0x00 \
				or int(token.get("handler_target_cpu_address", -1)) != 0x8877 \
				or String(token.get("destination", "")) != "$052A" \
				or not bool(token.get("has_result", false)):
			return _failure(Status.SOURCE_STATE_REQUIRED,
				"Scenario-$18 `$FD $00` requires the shared ROM `$8877` resolver on live holder state.",
				{"source_byte_offset": offset, "cursor_advanced": false})
		writes["$052A"] = int(token.get("result", -1)) & 0xFF
	if _scenario_id == 0x38 and opcode == 0xF7:
		if offset != 0 or length != 2 or int(token.get("operand", -1)) != 0x17 \
				or int(token.get("handler_cpu_address", -1)) != 0x87F5 \
				or int(token.get("handler_file_offset", -1)) != 0x020805 \
				or token.get("handler_bytes", []) != [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60] \
				or writes != {"$052B": 0x17}:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$38 `$F7 $17` does not match its ROM-verified `$87F5` operand reader.",
				{"source_byte_offset": offset, "cursor_advanced": false})
	if _scenario_id == 0x1E and opcode == 0xFD:
		if int(token.get("operand", -1)) != 0x02 \
				or int(token.get("handler_target_cpu_address", -1)) != 0x88B5 \
				or String(token.get("destination", "")) != "$052A" \
				or not bool(token.get("has_result", false)):
			return _failure(Status.SOURCE_STATE_REQUIRED,
				"Scenario-$1E `$FD $02` has no source-resolved result from live `$05FB`.",
				{"source_byte_offset": offset, "cursor_advanced": false})
		writes["$052A"] = int(token.get("result", -1)) & 0xFF
	elif _scenario_id == 0x1E and opcode == 0xF6:
		var effect: Dictionary = token.get("ram_effect", {})
		if String(effect.get("operation", "")) != "xor" or int(effect.get("mask", -1)) != 0x40 \
				or not _ram_state.has("$052A"):
			return _failure(Status.SOURCE_STATE_REQUIRED,
				"Scenario-$1E `$F6` requires its preceding ROM-derived `$052A` value.",
				{"source_byte_offset": offset, "cursor_advanced": false})
		var result := int(_ram_state["$052A"]) ^ 0x40
		if bool(effect.has("result")) and int(effect["result"]) != result:
			return _failure(Status.SOURCE_INTEGRITY_FAILURE,
				"Scenario-$1E `$F6` parser result differs from the live byte-runtime state.",
				{"source_byte_offset": offset, "parser_result": effect["result"], "runtime_result": result})
		writes["$052A"] = result
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
		"operand": token.get("operand", -1),
		"operand_bytes": token.get("operand_bytes", []),
		"operand_word_little_endian": token.get("operand_word_little_endian", -1),
		"handler_target_cpu_address": token.get("handler_target_cpu_address", -1),
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
	var expected_offset := int({0x1E: 5, 0x2E: 1, 0x35: 3, 0x36: 4, 0x38: 2, 0x44: 0}.get(_scenario_id, -1))
	var expected_record := PackedByteArray()
	if _scenario_id == 0x1C:
		match _source_pointer_cpu:
			0xB49E:
				expected_offset = 3
				expected_record = PackedByteArray([0x3C, 0x01, 0x78, 0x58])
			0xB4B6:
				expected_offset = 3
				expected_record = PackedByteArray([0x38, 0x63, 0x7A, 0x58])
			0xBB4B:
				expected_offset = 0
				expected_record = PackedByteArray([0x30, 0x1F, 0x4C, 0x00])
			_:
				return _failure(Status.UNSUPPORTED_OPERATION,
					"Scenario-$1C event record is outside the admitted ROM branch targets.",
					{"source_pointer_cpu": _source_pointer_cpu, "cursor_advanced": false})
	elif _scenario_id == 0x18:
		expected_offset = 3 if _source_pointer_cpu == 0xAF51 else 20
		expected_record = PackedByteArray([0x3C, 0x72, 0x66, 0x47]) \
			if _source_pointer_cpu == 0xAF51 else PackedByteArray([0x3F, 0x2A, 0x19, 0x47])
	else:
		expected_record = {
			0x1E: PackedByteArray([0x07, 0x45, 0x90, 0xF0]),
			0x2E: PackedByteArray([0x78, 0x36, 0x8B, 0x6D]),
			0x35: PackedByteArray([0x02, 0x3A, 0x8F, 0x73]),
			0x36: PackedByteArray([0x10, 0x3A, 0x8F, 0xF0]),
			0x38: PackedByteArray([0x01, 0x34, 0x00, 0xF0]),
			0x44: PackedByteArray([0x02, 0x70, 0x5C, 0xF0]),
		}.get(_scenario_id, PackedByteArray())
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
	contract.source_record_cpu_address = _source_root_pointer_cpu + offset
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
	_scenario_1c_reader_status = ""
	_scenario_1c_terminal_status = ""
	_scenario_1c_context_requirements.clear()
	_scenario_1c_child_branch_active = false
	_source_pointer_cpu = -1
	_source_root_pointer_cpu = -1
	_source_file_offset = -1
	_source_bytes = PackedByteArray()
	_scenario18_branch_af51 = PackedByteArray()
	_scenario18_parent_root_pointer_cpu = -1
	_scenario18_active_external_branch = false
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
		Status.CONTEXT_REQUIRED:
			return "context_required"
		Status.EXTERNAL_CONTINUATION_REQUIRED:
			return "external_continuation_required"
	return "unknown_status"
