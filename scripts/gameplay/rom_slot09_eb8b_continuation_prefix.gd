extends RefCounted
class_name RomSlot09Eb8bContinuationPrefix
## Executes the verified fresh-route slot-$09 continuation through its first
## unsupported bank-$18 worker entry. The live source-route runner composes
## this narrow executor; it is not a general 6502 emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const ROOT_LOOP_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_root_slot09_loop_EB86_EC07.bin"
const ROOT_LOOP_MANIFEST := "res://reference/rom_extract/gameplay/task_context/manifest.json"
const ROOT_LOOP_SHA256 := "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917"
const ROOT_LOOP_OFFSET := "0x03EB96"
const ROOT_LOOP_LENGTH := 130
const APPEND_MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json"
const APPEND_SOURCE_PATH := "res://reference/rom_extract/gameplay/slot09_86f8_worker/fixed_inline_record_append_handler_CCD2_CD0C.bin"
const APPEND_SOURCE_SHA256 := "7c23b91502ce9ebf01c18cbf401030f35181dbdc359d245cc7d7d57dd2cbc37b"
const TASK_CONTEXT_MANIFEST_PATH := "res://reference/rom_extract/gameplay/task_context/manifest.json"
const ACTOR_CALLER_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_scenario_actor_worker_seed_ED15_ED2C.bin"
const ACTOR_CALLER_SHA256 := "61ef48dd58901f95f2c20f7f4a8bc1bb850221cb403f6bfbd52a65a12e33f551"
const TASK_SEED_HELPER_PATH := "res://reference/rom_extract/gameplay/task_context/fixed_task_seed_CAE7.bin"
const TASK_SEED_HELPER_SHA256 := "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55"
const SCENARIO_CONTINUATION_ROOT := "res://reference/rom_extract/gameplay/scenario_continuation/"
const SCENARIO_CONTINUATION_MANIFEST := SCENARIO_CONTINUATION_ROOT + "manifest.json"
const SCENARIO_TASK_RUNTIME_MANIFEST := "res://reference/rom_extract/gameplay/scenario_task_runtime/manifest.json"
const FIRST_COMMAND_SCENARIOS_MANIFEST := "res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json"
const FIRST_COMMAND_SCENARIOS_ROOT := "res://reference/rom_extract/gameplay/first_command_scenarios/"
const PASS_SCENARIO_18_MANIFEST := "res://reference/rom_extract/gameplay/pass_scenario_18/manifest.json"
const PASS_SCENARIO_18_ROOT := "res://reference/rom_extract/gameplay/pass_scenario_18/"
const PASS_SCENARIO_18_STREAM_SHA256 := "8e79217a8131e753b6a194df0ca5eb8e916b11d1bd537c06a4541583161bb81b"
const PASS_SCENARIO_18_POINTER_SHA256 := "3101454d77028d7505313ba354609954498f92a503e65b791b076e04219f3d9b"
const PASS_SCENARIO_18_AF51_SHA256 := "162fe60677bbd4a6f06415055195215d0a39860746a52816598badfc7571cb8a"
const PASS_SCENARIO_1C_MANIFEST := "res://reference/rom_extract/gameplay/pass_scenario_1c/manifest.json"
const PASS_SCENARIO_1C_ROOT := "res://reference/rom_extract/gameplay/pass_scenario_1c/"
const PASS_SCENARIO_1C_STREAM_SHA256 := "68d8512ef76afc90deee499c53952f8cf27d4c4473749a571ef1ed9deca132e2"
const PASS_SCENARIO_1C_POINTER_SHA256 := "0aebdd98608aa88311ca8ab9bedd486c26160ed4a842df5297fd8572eb568bf4"
const PASS_SCENARIO_1C_B49E_SHA256 := "1a650937b1815dc4ab5a30a1da70eb4e3c4bad7059005d1fbb585995936db5e2"
const PASS_SCENARIO_1C_B4B6_SHA256 := "c2b1fab616d39995a449dc04d7893b270cb637df53a52ba54954c96de5d42915"
const PASS_SCENARIO_1C_FA_BRANCH_SHA256 := "d39d9c4feecbd6f52b00d87bc8402f8a265fd173fb392b2066bcd08c2b9dce4c"
const PASS_SCENARIO_1C_FA_WRAPPER_SHA256 := "e5944e698c99067bb0a5921b8823e977dcd92bcb83c8dcb593bdc49651fd5275"
const SCENARIO_2E_ROOT := "res://reference/rom_extract/gameplay/scenario_2e/"
const SCENARIO_2E_MANIFEST := SCENARIO_2E_ROOT + "manifest.json"
const SCENARIO_2E_POINTER_SHA256 := "89ac76264b830ae1361eae0ff3195e173fb7d45b9a0e8754db0986cb14623202"
const SCENARIO_2E_STREAM_SHA256 := "1a8acb72b1adf0fd4059eb2a0a8c27b0e93778b9a3a3a82886aa0818c5722630"
const MAP2F_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_2f_resume/manifest.json"
const MAP2F_BLOCK_MAP_PATH := "res://reference/rom_extract/gameplay/first_command_field/map_2f_resume/map_2f_block_map.bin"
const MAP2F_MANIFEST_SHA256 := "0256e72af241982893680800cba4017818cf1323874f9db0a04192d986e991ac"
const MAP2F_BLOCK_MAP_SHA256 := "e95e3366fb5c90d12a136b2f7bd77a3ab36be9bc6f05f8c7ea9c06812da4157e"
const SCENARIO_RUNTIME := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")
const SCENARIO_BYTECODE_READER := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const SCENARIO36_FD00_RESOLVER := preload("res://scripts/gameplay/rom_scenario36_fd00_mirror_resolver.gd")
const SCENARIO_CONTINUATION_STACK := preload("res://scripts/gameplay/bank10_scenario_continuation_stack.gd")
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_N := 0x80
const P_V := 0x40
const P_Z := 0x02
const P_C := 0x01
const P_NZ_MASK := P_N | P_Z
const P_NZVC_MASK := P_N | P_V | P_Z | P_C

const SCENARIO_TERMINATION_SPANS := {
	"f7_handler": {"file": "bank10_f7_handler_87f5_87ff.bin", "start": 0x87F5, "end": 0x87FF,
		"bank": "$10", "offset": "0x020805", "length": 10,
		"sha256": "42f86ca3e1cfb75bedfacafd80b7ec80e34b52582be56d1457a3ce5d4b51f2da"},
	"scenario_opcode_dispatch": {"file": "bank10_scenario_opcode_dispatch_80a9_80ce.bin", "start": 0x80A9, "end": 0x80CF,
		"bank": "$10", "offset": "0x0200B9", "length": 38,
		"sha256": "b22a45b7a2f1c6edc80a9fd896bac16792341761384fe9cb56e8525738465cb3"},
	"fb_handler": {"file": "bank10_fb_handler_8837_8852.bin", "start": 0x8837, "end": 0x8853,
		"bank": "$10", "offset": "0x020847", "length": 28,
		"sha256": "34e0466b33439d4de66876bdb757e2fb8600498f1cc3cf0968d612266af02866"},
	"f0_terminal": {"file": "bank10_f0_terminal_80cf_80f5.bin", "start": 0x80CF, "end": 0x80F6,
		"bank": "$10", "offset": "0x0200DF", "length": 39,
		"sha256": "f94d098b6341f36b79782f12a2e090196443f13bea8bf09e13f1d29d2a07fb44"},
	"finish_dispatch": {"file": "fixed_scenario_finish_dispatch_C51B_C51D.bin", "start": 0xC51B, "end": 0xC51E,
		"bank": "fixed bank $1E", "offset": "0x03C52B", "length": 3,
		"sha256": "5b312ff9181495afda470931d5318fb5926ffb53600a7208dbd9e22b7c035f85"},
	"delay_increment": {"file": "fixed_scenario_task_delay_increment_CB02_CB0C.bin", "start": 0xCB02, "end": 0xCB0D,
		"bank": "fixed bank $1E", "offset": "0x03CB12", "length": 11,
		"sha256": "d3b6aa196eb016728ca4f136afe446ead03d794aaf405a8b2a1d45dd3c8e5a79"},
	"opcode_dispatch_vector": {"file": "fixed_scenario_opcode_dispatch_vector_C509_C50B.bin", "start": 0xC509, "end": 0xC50C,
		"bank": "fixed bank $1E", "offset": "0x03C519", "length": 3,
		"sha256": "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"},
	"opcode_table_helper": {"file": "fixed_scenario_opcode_table_dispatch_CB99_CBAF.bin", "start": 0xCB99, "end": 0xCBB0,
		"bank": "fixed bank $1E", "offset": "0x03CBA9", "length": 23,
		"sha256": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"},
}

const SCENARIO_TASK_SOURCE_REQUIREMENTS := {
	"reference/rom_extract/gameplay/scenario_task_runtime/bank10_reader_entry_8000_803E.bin": {
		"cpu_address": "$8000", "file_offset": "0x020010", "length": 63,
		"sha256": "8f7bdba702bda2bc20e19776e2496f96f7c1c8fad07f424e555726fb4ccc3ca5"},
	"reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_35.bin": {
		"cpu_address": "$B7CD", "file_offset": "0x020A39", "length": 2,
		"sha256": "751bb4c1d1d35f0a3f3c86304dffe714c0c1a6483af6e233ecff031004a22bc3"},
	"reference/rom_extract/gameplay/first_command_scenarios/scenario_35.bin": {
		"cpu_address": "$B7CD", "file_offset": "0x0237DD", "length": 8,
		"sha256": "02848b8b324fe6c120e6eb26bca5d0c08cab23baa91cf7820db454a3f78544df"},
}

const SOURCE_SPANS := {
	"ec08": {"file": "fixed_slot09_helper_EC08_EC0F.bin", "start": 0xEC08, "end": 0xEC10,
		"bank": 0x1F, "offset": "0x03EC18", "length": 8,
		"sha256": "ffe577104f3ec43bdd7af0ed111ca5096c0685d8c5d40f5831984b5ee511976d"},
	"scenario_active": {"file": "fixed_scenario_active_EC10_EC74.bin", "start": 0xEC10, "end": 0xEC75,
		"bank": 0x1F, "offset": "0x03EC20", "length": 101,
		"sha256": "585277fd74fa83ff9380fed5b2be6941f352e825ca9a3b419eac174f0fd3f0ab"},
	"scenario_active_tail": {"file": "fixed_scenario_active_EC75_EC8C.bin", "start": 0xEC75, "end": 0xEC8C,
		"bank": 0x1F, "offset": "0x03EC85", "length": 23,
		"sha256": "1e33f4a7152b408675388c1bc17d0b70ad0b933d6854024424a0be1e75ee93e1"},
	"event_reader": {"file": "bank10_event_reader_803F_8096.bin", "start": 0x803F, "end": 0x8097,
		"bank": 0x10, "offset": "0x02004F", "length": 88,
		"sha256": "880ad93e8e01567b7ab4d1dbd4a34e3fa0cd9b7751e14753c2bb9f1acf10d5d4"},
	"ed85": {"file": "fixed_slot09_helper_ED85_EE9E.bin", "start": 0xED85, "end": 0xEE9F,
		"bank": 0x1F, "offset": "0x03ED95", "length": 0x11A,
		"sha256": "831d01144fe8571139ad5b7a9bc328e72f9da49df06dad398cd9c5ae45bc3a7a"},
	"mapper": {"file": "fixed_mapper_helper_CE2D_CE49.bin", "start": 0xCE2D, "end": 0xCE4A,
		"bank": 0x1E, "offset": "0x03CE3D", "length": 29,
		"sha256": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c"},
	"vector": {"file": "bank18_slot09_vector_8003_8005.bin", "start": 0x8003, "end": 0x8006,
		"bank": 0x18, "offset": "0x030013", "length": 3,
		"sha256": "bebc313ee43ac49e4e74dbab33cea40cff8dd41c6705ad17b644715d9e29c2af"},
	"scenario_post_callback": {"file": "fixed_scenario_post_callback_EC8C_ED2C.bin", "start": 0xEC8C, "end": 0xED2D,
		"bank": 0x1F, "offset": "0x03EC9C", "length": 161,
		"sha256": "b371428c3f42ad83d893a9737c4b4f78f160449cab9874bd13785f6946898fd3"},
	"palette_fill": {"file": "fixed_palette_fill_helper_CC02_CC45.bin", "start": 0xCC02, "end": 0xCC46,
		"bank": 0x1E, "offset": "0x03CC12", "length": 68,
		"sha256": "9fa6a2837a6bcf360ccc1df464b2242fe4a287330b8173c4415718e7fc9cfc68"},
	"palette_table": {"file": "palette_values_FBE4_FBEF.bin", "start": 0xFBE4, "end": 0xFBF0,
		"bank": 0x1F, "offset": "0x03FBF4", "length": 12,
		"sha256": "75f74037d95cd7cb0a1e71a783d1ed3237a4295fdb03f0dfd12f2bba9541d8af"},
	"palette_table_scenario1e": {"file": "palette_values_FC14_FC23.bin", "start": 0xFC14, "end": 0xFC24,
		"bank": 0x1F, "offset": "0x03FC24", "length": 16,
		"sha256": "d0a064967d00c369f35f09a62c5439b9dca1549dc4eea76e91e03ebbf4c7eab5"},
	"actor_param_vector": {"file": "bank0b_actor_parameter_vector_8006_8008.bin", "start": 0x8006, "end": 0x8009,
		"bank": 0x0B, "offset": "0x016016", "length": 3,
		"sha256": "952b6553ea3154a4a0a16388be54e49efea62ff8a62da5ef67f9c5fb94b7cf00"},
	"actor_param_worker": {"file": "bank0b_actor_parameter_helper_84A1_84CE.bin", "start": 0x84A1, "end": 0x84CF,
		"bank": 0x0B, "offset": "0x0164B1", "length": 46,
		"sha256": "ffb326f2f98df5d00e3e282b42e1eef57b5c3f065b5c09a079d8cc3d92704a2a"},
	"scenario_resume": {"file": "fixed_scenario_resume_ED2D_ED5A.bin", "start": 0xED2D, "end": 0xED5B,
		"bank": 0x1F, "offset": "0x03ED3D", "length": 46,
		"sha256": "d06c6c1049fe7469ecdd6c0ee4b48d22afdb20268987035223e78a2a961b71ac"},
	"root_loop": {"file": "fixed_root_slot09_loop_EB86_EC07.bin", "start": 0xEB86, "end": 0xEC08,
		"bank": 0x1F, "offset": "0x03EB96", "length": 130,
		"sha256": "91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917"},
	"inline_append": {"file": "fixed_inline_record_append_handler_CCD2_CD0C.bin", "start": 0xCCD2, "end": 0xCD0D,
		"bank": 0x1E, "offset": "0x03CCE2", "length": 59,
		"sha256": "7c23b91502ce9ebf01c18cbf401030f35181dbdc359d245cc7d7d57dd2cbc37b"},
	"actor_seed_caller": {"file": "fixed_scenario_actor_worker_seed_ED15_ED2C.bin", "start": 0xED15, "end": 0xED2D,
		"bank": 0x1F, "offset": "0x03ED25", "length": 24,
		"sha256": "61ef48dd58901f95f2c20f7f4a8bc1bb850221cb403f6bfbd52a65a12e33f551"},
	"task_seed_helper": {"file": "fixed_task_seed_CAE7.bin", "start": 0xCAE7, "end": 0xCAF7,
		"bank": 0x1E, "offset": "0x03CAF7", "length": 16,
		"sha256": "139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55"},
	"scenario_wait": {"file": "fixed_scenario_wait_handler_ED5B_ED84.bin", "start": 0xED5B, "end": 0xED85,
		"bank": 0x1F, "offset": "0x03ED6B", "length": 42,
		"sha256": "6a8872b8888dab2fa3ab8ed9dcb76236a6616d2d727f7174a5ed0af57bcb5ad8"},
}

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _root_loop := PackedByteArray()
var _ram := PackedByteArray()
var _stack := PackedByteArray()
var _cpu: Dictionary = {}
var _mapper: Dictionary = {}
var _writes: Array[Dictionary] = []
var _stack_writes: Array[Dictionary] = []
var _mapper_writes: Array[Dictionary] = []
var _instruction_pcs: Array[int] = []
var _calls: Array[Dictionary] = []
var _returns: Array[Dictionary] = []
var _scenario_seed_request: Dictionary = {}
var _scenario_runtime_events: Array[Dictionary] = []
var _scenario_wait_worker_executed := false
var _scenario_route_state_executed := false
var _scenario_post_callback_executed := false
var _scenario_idle_worker_vector_ready := false
var _actor_worker_seed_request: Dictionary = {}
var _entry_registers: Dictionary = {}
var _source_span_hashes: Dictionary = {}
var _append_handler := PackedByteArray()
var _actor_seed_caller := PackedByteArray()
var _task_seed_helper := PackedByteArray()
var _actor_seed_pause_ready := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Slot-$09 continuation source manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("Slot-$09 continuation source manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var rom: Variant = manifest.get("rom", {})
	var entries: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-slot09-eb8b-continuation-source-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256 \
			or not entries is Array or entries.size() != SOURCE_SPANS.size():
		return _fail("Slot-$09 continuation manifest targets an unsupported ROM or schema.")
	_source_span_hashes.clear()
	if not _load_root_loop_dependency(manifest.get("root_loop_dependency", {})):
		return false
	for name_variant in SOURCE_SPANS:
		var name := String(name_variant)
		var spec: Dictionary = SOURCE_SPANS[name]
		var found: Dictionary = {}
		for entry_variant in entries:
			if entry_variant is Dictionary and String(entry_variant.get("file", "")) == String(spec["file"]):
				found = entry_variant
				break
		if found.is_empty():
			return _fail("Manifest omits source span %s." % String(spec["file"]))
		for field: String in ["file_offset", "length", "sha256"]:
			var expected: Variant = spec["offset"] if field == "file_offset" else spec[field]
			if found.get(field) != expected:
				return _fail("Manifest metadata differs for %s field %s." % [String(spec["file"]), field])
		if String(found.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(found.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(found.get("bank", "")) != "0x%02X" % int(spec["bank"]):
			return _fail("Manifest CPU span or bank differs for %s." % String(spec["file"]))
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(spec["file"]))
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Source bytes failed size/hash/manifest validation: %s." % String(spec["file"]))
		_sources[name] = bytes
		_source_span_hashes[String(spec["file"])] = String(spec["sha256"])
	if not _load_inline_append_dependency(manifest.get("inline_append_dependency", {})):
		return false
	if not _load_actor_seed_dependencies(manifest.get("actor_seed_dependencies", {})):
		return false
	if not _load_scenario_termination_sources():
		return false
	if not _load_scenario36_sources():
		return false
	if not _load_scenario1e_sources():
		return false
	if not _load_scenario44_sources():
		return false
	if not _load_scenario38_pointer_source():
		return false
	if not _load_scenario18_source():
		return false
	if not _load_scenario1c_source():
		return false
	if not _load_scenario2e_source():
		return false
	_configured = true
	return true


func _load_scenario2e_source() -> bool:
	var manifest_file := FileAccess.open(SCENARIO_2E_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("Scenario-$2E ROM source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Scenario-$2E ROM source manifest is malformed.")
	var manifest: Dictionary = parsed
	var scenario_variant: Variant = manifest.get("scenario", {})
	var scenario: Dictionary = scenario_variant if scenario_variant is Dictionary else {}
	if String(manifest.get("schema", "")) != "ct2-bank10-scenario-2e-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(scenario.get("scenario_id", "")) != "$2E" \
			or String(scenario.get("prg_bank", "")) != "$10" \
			or String(scenario.get("pointer_table_cpu_address", "")) != "0x89BF" \
			or String(scenario.get("pointer_entry_file_offset", "")) != "0x020A2B" \
			or String(scenario.get("pointer_entry_bytes_hex", "")).replace(" ", "").to_lower() != "4eb7" \
			or String(scenario.get("pointer_entry_sha256", "")) != SCENARIO_2E_POINTER_SHA256 \
			or String(scenario.get("start_cpu_address", "")) != "0xB74E" \
			or String(scenario.get("end_cpu_address_exclusive", "")) != "0xB754" \
			or String(scenario.get("stream_file_offset", "")) != "0x02375E" \
			or String(scenario.get("stream_end_file_offset_exclusive", "")) != "0x023764" \
			or int(scenario.get("length_bytes", -1)) != 6 \
			or String(scenario.get("stream_sha256", "")) != SCENARIO_2E_STREAM_SHA256 \
			or String(scenario.get("stream_bytes_hex", "")).replace(" ", "").to_lower() != "f578368b6dfb":
		return _fail("Scenario-$2E source manifest does not match the pinned bank-$10 pointer and stream span.")
	var pointer_bytes := FileAccess.get_file_as_bytes(SCENARIO_2E_ROOT + "scenario_pointer_2E.bin")
	var stream_bytes := FileAccess.get_file_as_bytes(SCENARIO_2E_ROOT + "scenario_2E.bin")
	if pointer_bytes != PackedByteArray([0x4E, 0xB7]) \
			or _sha256(pointer_bytes) != SCENARIO_2E_POINTER_SHA256 \
			or stream_bytes != PackedByteArray([0xF5, 0x78, 0x36, 0x8B, 0x6D, 0xFB]) \
			or _sha256(stream_bytes) != SCENARIO_2E_STREAM_SHA256:
		return _fail("Scenario-$2E pointer or stream bytes failed manifest/hash validation.")
	_sources["scenario_pointer_2E"] = pointer_bytes
	_sources["scenario_2E"] = stream_bytes
	var map_manifest_bytes := FileAccess.get_file_as_bytes(MAP2F_MANIFEST_PATH)
	var map_manifest: Variant = JSON.parse_string(map_manifest_bytes.get_string_from_utf8())
	var map_source: Dictionary = {}
	if map_manifest is Dictionary:
		for row_variant in (map_manifest as Dictionary).get("extracted_files", []):
			if row_variant is Dictionary and String((row_variant as Dictionary).get("path", "")) == "map_2f_block_map.bin":
				map_source = row_variant
				break
	var map_bytes := FileAccess.get_file_as_bytes(MAP2F_BLOCK_MAP_PATH)
	if map_manifest_bytes.is_empty() or _sha256(map_manifest_bytes) != MAP2F_MANIFEST_SHA256 \
			or not map_manifest is Dictionary \
			or String((map_manifest as Dictionary).get("schema", "")) != "ct2-slot15-callback36-map2f-resume-sources-v1" \
			or String(((map_manifest as Dictionary).get("source_rom", {}) as Dictionary).get("sha256", "")) != ROM_SHA256 \
			or map_source.is_empty() or int(map_source.get("size_bytes", -1)) != 0x20 \
			or String(map_source.get("sha256", "")) != MAP2F_BLOCK_MAP_SHA256 \
			or map_bytes.size() != 0x20 or _sha256(map_bytes) != MAP2F_BLOCK_MAP_SHA256:
		return _fail("Map-$2F metatile pointer source failed ROM manifest/hash validation.")
	_sources["map_2f_block_map"] = map_bytes
	return true


func _load_scenario36_sources() -> bool:
	var manifest_file := FileAccess.open(FIRST_COMMAND_SCENARIOS_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("First-command scenario source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary \
			or String((parsed as Dictionary).get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String((parsed as Dictionary).get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("First-command scenario source manifest targets another ROM or schema.")
	var manifest: Dictionary = parsed
	var pointer_row: Dictionary = {}
	var stream_row: Dictionary = {}
	for row_variant in manifest.get("pointer_table_entries", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$36":
			pointer_row = row_variant
			break
	for row_variant in manifest.get("scenario_streams", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$36":
			stream_row = row_variant
			break
	if pointer_row.is_empty() or stream_row.is_empty() \
			or String(pointer_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_36.bin" \
			or String(pointer_row.get("cpu_address", "")).to_lower() != "0xb7e4" \
			or String(pointer_row.get("table_cpu_address", "")).to_lower() != "0x89bf" \
			or String(pointer_row.get("table_file_offset", "")) != "0x020A3B" \
			or String(pointer_row.get("sha256", "")) != "5d2bc0e444947ba22ee06b40139852b88e24eb157d3175e1c6ef1c315d4d6a7a" \
			or String(stream_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_36.bin" \
			or String(stream_row.get("start_cpu_address", "")).to_lower() != "0xb7e4" \
			or String(stream_row.get("file_offset", "")) != "0x0237F4" \
			or int(stream_row.get("length_bytes", -1)) != 38 \
			or String(stream_row.get("sha256", "")) != "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f":
		return _fail("Scenario-$36 manifest source pointers or stream metadata changed.")
	var pointer_bytes := FileAccess.get_file_as_bytes(FIRST_COMMAND_SCENARIOS_ROOT + "scenario_pointer_36.bin")
	var stream_bytes := FileAccess.get_file_as_bytes(FIRST_COMMAND_SCENARIOS_ROOT + "scenario_36.bin")
	if pointer_bytes != PackedByteArray([0xE4, 0xB7]) \
			or _sha256(pointer_bytes) != String(pointer_row["sha256"]) \
			or stream_bytes.size() != 38 \
			or _sha256(stream_bytes) != String(stream_row["sha256"]):
		return _fail("Scenario-$36 pointer or stream bytes failed manifest/hash validation.")
	_sources["scenario_pointer_36"] = pointer_bytes
	_sources["scenario_36"] = stream_bytes
	return true


func _load_scenario1e_sources() -> bool:
	var manifest_file := FileAccess.open(FIRST_COMMAND_SCENARIOS_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("First-command scenario source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary \
			or String((parsed as Dictionary).get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String((parsed as Dictionary).get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("First-command scenario source manifest targets another ROM or schema.")
	var manifest: Dictionary = parsed
	var pointer_row: Dictionary = {}
	var stream_row: Dictionary = {}
	for row_variant in manifest.get("pointer_table_entries", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$1E":
			pointer_row = row_variant
			break
	for row_variant in manifest.get("scenario_streams", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$1E":
			stream_row = row_variant
			break
	if pointer_row.is_empty() or stream_row.is_empty() \
			or String(pointer_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_1E.bin" \
			or String(pointer_row.get("cpu_address", "")).to_lower() != "0xb7da" \
			or String(pointer_row.get("table_cpu_address", "")).to_lower() != "0x89bf" \
			or String(pointer_row.get("table_file_offset", "")) != "0x020A0B" \
			or String(pointer_row.get("sha256", "")) != "72ac1108e6817858f37ce9d95f78b8d0c5dfc6e01041261f2684e0d47c2ecd1f" \
			or String(stream_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_1E.bin" \
			or String(stream_row.get("start_cpu_address", "")).to_lower() != "0xb7da" \
			or String(stream_row.get("file_offset", "")) != "0x0237EA" \
			or int(stream_row.get("length_bytes", -1)) != 10 \
			or String(stream_row.get("sha256", "")) != "383f2248d753ef12b325c98238ee1c0eaa96c693ca427a5885536e1c16f1a496":
		return _fail("Scenario-$1E manifest source pointers or stream metadata changed.")
	var pointer_bytes := FileAccess.get_file_as_bytes(FIRST_COMMAND_SCENARIOS_ROOT + "scenario_pointer_1E.bin")
	var stream_bytes := FileAccess.get_file_as_bytes(FIRST_COMMAND_SCENARIOS_ROOT + "scenario_1E.bin")
	if pointer_bytes != PackedByteArray([0xDA, 0xB7]) \
			or _sha256(pointer_bytes) != String(pointer_row["sha256"]) \
			or stream_bytes != PackedByteArray([0xFD, 0x02, 0xF6, 0xF7, 0x01, 0x07, 0x45, 0x90, 0xF0, 0xFB]) \
			or _sha256(stream_bytes) != String(stream_row["sha256"]):
		return _fail("Scenario-$1E pointer or stream bytes failed manifest/hash validation.")
	_sources["scenario_pointer_1E"] = pointer_bytes
	_sources["scenario_1E"] = stream_bytes
	return true


func _load_scenario44_sources() -> bool:
	var manifest_file := FileAccess.open(FIRST_COMMAND_SCENARIOS_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("First-command scenario source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary \
			or String((parsed as Dictionary).get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String((parsed as Dictionary).get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("First-command scenario manifest targets another ROM or schema.")
	var manifest: Dictionary = parsed
	var pointer_row: Dictionary = {}
	var stream_row: Dictionary = {}
	for row_variant in manifest.get("pointer_table_entries", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$44":
			pointer_row = row_variant
			break
	for row_variant in manifest.get("scenario_streams", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$44":
			stream_row = row_variant
			break
	if pointer_row.is_empty() or stream_row.is_empty() \
			or String(pointer_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_pointer_44.bin" \
			or String(pointer_row.get("cpu_address", "")).to_lower() != "0xb7d5" \
			or String(pointer_row.get("table_cpu_address", "")).to_lower() != "0x89bf" \
			or String(pointer_row.get("table_file_offset", "")) != "0x020A57" \
			or String(pointer_row.get("sha256", "")) != "dc9cfca9f5d0360d2026365799680a485504e2a2d4fc29281a1e27d18371f768" \
			or String(stream_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_44.bin" \
			or String(stream_row.get("start_cpu_address", "")).to_lower() != "0xb7d5" \
			or String(stream_row.get("file_offset", "")) != "0x0237E5" \
			or int(stream_row.get("length_bytes", -1)) != 5 \
			or String(stream_row.get("sha256", "")) != "22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f":
		return _fail("Scenario-$44 manifest source pointers or stream metadata changed.")
	var pointer_bytes := FileAccess.get_file_as_bytes(FIRST_COMMAND_SCENARIOS_ROOT + "scenario_pointer_44.bin")
	var stream_bytes := FileAccess.get_file_as_bytes(FIRST_COMMAND_SCENARIOS_ROOT + "scenario_44.bin")
	if pointer_bytes != PackedByteArray([0xD5, 0xB7]) \
			or _sha256(pointer_bytes) != String(pointer_row["sha256"]) \
			or stream_bytes != PackedByteArray([0x02, 0x70, 0x5C, 0xF0, 0xFB]) \
			or _sha256(stream_bytes) != String(stream_row["sha256"]):
		return _fail("Scenario-$44 pointer or stream bytes failed manifest/hash validation.")
	_sources["scenario_pointer_44"] = pointer_bytes
	_sources["scenario_44"] = stream_bytes
	return true


func _load_scenario38_pointer_source() -> bool:
	var manifest_file := FileAccess.open(FIRST_COMMAND_SCENARIOS_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("First-command scenario source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary \
			or String((parsed as Dictionary).get("schema", "")) != "first-command-bank10-scenario-sources-v1" \
			or String((parsed as Dictionary).get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("First-command scenario source manifest targets another ROM or schema.")
	var manifest: Dictionary = parsed
	var stream_row: Dictionary = {}
	for row_variant in manifest.get("scenario_streams", []):
		if row_variant is Dictionary and String((row_variant as Dictionary).get("scenario_id", "")) == "$38":
			stream_row = row_variant
			break
	var pointer_variant: Variant = stream_row.get("start_pointer_entry", {})
	var pointer_entry: Dictionary = pointer_variant if pointer_variant is Dictionary else {}
	if stream_row.is_empty() \
			or String(stream_row.get("path", "")) != "reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin" \
			or String(stream_row.get("start_cpu_address", "")).to_lower() != "0xb7c6" \
			or String(stream_row.get("file_offset", "")) != "0x0237D6" \
			or int(stream_row.get("length_bytes", -1)) != 7 \
			or String(stream_row.get("sha256", "")) != "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76" \
			or String(pointer_entry.get("table_cpu_address", "")).to_lower() != "0x89bf" \
			or String(pointer_entry.get("table_file_offset", "")) != "0x020A3F" \
			or int(pointer_entry.get("length_bytes", -1)) != 2 \
			or String(pointer_entry.get("bytes_hex", "")).replace(" ", "").to_lower() != "c6b7" \
			or String(pointer_entry.get("sha256", "")) != "06c441c4f9845c69b60a2967047bc5e2a878f296f2d6a975b3ed4b537a63aaac":
		return _fail("Scenario-$38 `$89BF` pointer entry or root stream provenance changed.")
	var pointer_bytes := PackedByteArray([0xC6, 0xB7])
	if _sha256(pointer_bytes) != String(pointer_entry["sha256"]):
		return _fail("Scenario-$38 pointer bytes failed their manifest hash.")
	var stream_bytes := FileAccess.get_file_as_bytes("res://" + String(stream_row["path"]))
	if stream_bytes != PackedByteArray([0xF7, 0x17, 0x01, 0x34, 0x00, 0xF0, 0xFB]) \
			or stream_bytes.size() != 7 \
			or _sha256(stream_bytes) != String(stream_row["sha256"]) \
			or String(stream_row.get("bytes_hex", "")).replace(" ", "").to_lower() != stream_bytes.hex_encode():
		return _fail("Scenario-$38 root stream bytes failed their pinned ROM manifest/hash check.")
	_sources["scenario_pointer_38"] = pointer_bytes
	_sources["scenario_38"] = stream_bytes
	return true


func _load_scenario18_source() -> bool:
	var manifest_file := FileAccess.open(PASS_SCENARIO_18_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("PASS scenario-$18 source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("PASS scenario-$18 source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-pass-scenario-18-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or String(manifest.get("scenario_id", "")) != "$18" \
			or String(manifest.get("start_cpu_address", "")) != "0x9E3E" \
			or String(manifest.get("pointer_entry_cpu_address", "")) != "0x89EF" \
			or String(manifest.get("pointer_entry_file_offset", "")) != "0x0209FF" \
			or String(manifest.get("pointer_entry_bytes_hex", "")).replace(" ", "") != "3E9E" \
			or String(manifest.get("pointer_entry_sha256", "")) != PASS_SCENARIO_18_POINTER_SHA256 \
			or String(manifest.get("file_offset", "")) != "0x021E4E" \
			or int(manifest.get("length_bytes", -1)) != 25 \
			or String(manifest.get("sha256", "")) != PASS_SCENARIO_18_STREAM_SHA256:
		return _fail("PASS scenario-$18 manifest pointer, ROM identity, bounds, or hash metadata changed.")
	var pointer_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_18_ROOT + "scenario_pointer_18.bin")
	var stream_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_18_ROOT + "scenario_18.bin")
	if pointer_bytes != PackedByteArray([0x3E, 0x9E]) \
			or _sha256(pointer_bytes) != PASS_SCENARIO_18_POINTER_SHA256 \
			or stream_bytes != PackedByteArray([0xFD, 0x00, 0xF3, 0xB4, 0x03, 0x02, 0x0B,
				0xF3, 0x1E, 0x51, 0xAF, 0x59, 0xAF, 0x90, 0xAF, 0xAA, 0xAF,
				0xF9, 0x15, 0x2B, 0x3F, 0x2A, 0x19, 0x47, 0xFB]) \
			or stream_bytes.size() != 25 or _sha256(stream_bytes) != PASS_SCENARIO_18_STREAM_SHA256:
		return _fail("PASS scenario-$18 pointer or stream bytes failed their manifest/hash check.")
	_sources["scenario_pointer_18"] = pointer_bytes
	_sources["scenario_18"] = stream_bytes
	return true


func _load_scenario1c_source() -> bool:
	var manifest_file := FileAccess.open(PASS_SCENARIO_1C_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("PASS scenario-$1C source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("PASS scenario-$1C source manifest is malformed.")
	var manifest: Dictionary = parsed
	var source_rom_variant: Variant = manifest.get("source_rom", {})
	var scenario_variant: Variant = manifest.get("scenario_1C", {})
	var source_rom: Dictionary = source_rom_variant if source_rom_variant is Dictionary else {}
	var scenario: Dictionary = scenario_variant if scenario_variant is Dictionary else {}
	var pointer_row: Dictionary = {}
	var stream_row: Dictionary = {}
	var branch_row: Dictionary = {}
	var b49e_row: Dictionary = {}
	var b4b6_row: Dictionary = {}
	var wrapper_row: Dictionary = {}
	var selector10_row: Dictionary = {}
	var selector1e_row: Dictionary = {}
	for row_variant in manifest.get("spans", []):
		if not row_variant is Dictionary:
			continue
		var row: Dictionary = row_variant
		match String(row.get("name", "")):
			"scenario_1C_pointer_entry": pointer_row = row
			"scenario_1C_root_stream": stream_row = row
			"scenario_1C_FA_branch_BB4B_BB50": branch_row = row
			"bank10_F3_root_F2_target_B49E_B4A6": b49e_row = row
			"bank10_F3_root_F2_target_B4B6_B4BE": b4b6_row = row
			"scenario_1C_FA_dispatch_wrapper_9F3E_9F54": wrapper_row = row
			"bank10_F3_selector10_helper_836E_837C": selector10_row = row
			"bank10_F3_selector1E_helper_8401_840A": selector1e_row = row
	if String(manifest.get("schema", "")) != "ct2-pass-scenario-1c-source-v1" \
			or String(source_rom.get("sha256", "")) != ROM_SHA256 \
			or String(scenario.get("pointer_table_cpu_address", "")) != "0x89BF" \
			or String(scenario.get("pointer_entry_cpu_address", "")) != "0x89F7" \
			or String(scenario.get("pointer_entry_file_offset", "")) != "0x020A07" \
			or String(scenario.get("pointer_entry_bytes", "")).replace(" ", "") != "E39B" \
			or String(scenario.get("stream_cpu_address", "")) != "0x9BE3" \
			or String(scenario.get("stream_file_offset", "")) != "0x021BF3" \
			or int(scenario.get("length_bytes", -1)) != 15 \
			or String(scenario.get("sha256", "")) != PASS_SCENARIO_1C_STREAM_SHA256 \
			or pointer_row.is_empty() or stream_row.is_empty():
		return _fail("PASS scenario-$1C manifest ROM identity, pointer, bounds, or hashes changed.")
	if String(pointer_row.get("cpu_start", "")) != "0x89F7" \
			or String(pointer_row.get("file_offset", "")) != "0x020A07" \
			or int(pointer_row.get("length_bytes", -1)) != 2 \
			or String(pointer_row.get("sha256", "")) != PASS_SCENARIO_1C_POINTER_SHA256 \
			or String(stream_row.get("cpu_start", "")) != "0x9BE3" \
			or String(stream_row.get("file_offset", "")) != "0x021BF3" \
			or int(stream_row.get("length_bytes", -1)) != 15 \
			or String(stream_row.get("sha256", "")) != PASS_SCENARIO_1C_STREAM_SHA256:
		return _fail("PASS scenario-$1C manifest span metadata changed.")
	var pointer_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "scenario_1C_pointer_entry.bin")
	var stream_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "scenario_1C.bin")
	var branch_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_FA_branch_BB4B_BB50.bin")
	var b49e_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_root_target_B49E_B4A6.bin")
	var b4b6_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_root_target_B4B6_B4BE.bin")
	var wrapper_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_FA_dispatch_wrapper_9F3E_9F54.bin")
	var selector10_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_selector10_helper_836E_837C.bin")
	var selector1e_bytes := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_selector1E_helper_8401_840A.bin")
	if pointer_bytes != PackedByteArray([0xE3, 0x9B]) \
			or _sha256(pointer_bytes) != PASS_SCENARIO_1C_POINTER_SHA256 \
			or stream_bytes != PackedByteArray([0xFD, 0x00, 0xFA, 0x3E, 0x9F, 0xF3, 0x84, 0x02,
				0x04, 0xF2, 0x9E, 0xB4, 0xF2, 0xB6, 0xB4]) \
			or stream_bytes.size() != 15 or _sha256(stream_bytes) != PASS_SCENARIO_1C_STREAM_SHA256 \
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
			or b49e_bytes != PackedByteArray([0xF9, 0x1D, 0x2C, 0x3C, 0x01, 0x78, 0x58, 0xFB]) \
			or _sha256(b49e_bytes) != PASS_SCENARIO_1C_B49E_SHA256 \
			or String(b4b6_row.get("cpu_start", "")) != "0xB4B6" \
			or String(b4b6_row.get("file_offset", "")) != "0x0234C6" \
			or int(b4b6_row.get("length_bytes", -1)) != 8 \
			or String(b4b6_row.get("sha256", "")) != PASS_SCENARIO_1C_B4B6_SHA256 \
			or b4b6_bytes != PackedByteArray([0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB]) \
			or _sha256(b4b6_bytes) != PASS_SCENARIO_1C_B4B6_SHA256 \
			or String(wrapper_row.get("cpu_start", "")) != "0x9F3E" \
			or int(wrapper_row.get("length_bytes", -1)) != 22 \
			or String(wrapper_row.get("sha256", "")) != PASS_SCENARIO_1C_FA_WRAPPER_SHA256 \
			or wrapper_bytes != PackedByteArray([0xF3, 0x10, 0x4A, 0x9F, 0x4B, 0xBB,
				0x4B, 0xBB, 0x4B, 0xBB, 0x4B, 0xBB, 0xF3, 0x1E, 0x4B, 0xBB,
				0x02, 0xB5, 0x4F, 0xB5, 0x50, 0xBB]) \
			or _sha256(wrapper_bytes) != PASS_SCENARIO_1C_FA_WRAPPER_SHA256 \
			or String(selector10_row.get("cpu_start", "")) != "0x836E" \
			or int(selector10_row.get("length_bytes", -1)) != 14 \
			or String(selector10_row.get("sha256", "")) != "e4c9d33a634f25658a0a01bfc64004d2db1a2d1ef7ecb2628ce2c0b02b99f71e" \
			or selector10_bytes != PackedByteArray([0xA2, 0x00, 0xAD, 0x3B, 0x04, 0xC9, 0x01,
				0xF0, 0x04, 0x20, 0x77, 0x86, 0xE8, 0x60]) \
			or _sha256(selector10_bytes) != String(selector10_row.get("sha256", "")) \
			or String(selector1e_row.get("cpu_start", "")) != "0x8401" \
			or int(selector1e_row.get("length_bytes", -1)) != 9 \
			or String(selector1e_row.get("sha256", "")) != "3ecd15e61abde841fad2c69ced09a68ec0856d74fb3cd0ab12b045d6429d5a63" \
			or selector1e_bytes != PackedByteArray([0xAD, 0x3C, 0x04, 0x29, 0x7F, 0xAA, 0x4C, 0x11, 0x82]) \
			or _sha256(selector1e_bytes) != String(selector1e_row.get("sha256", "")):
		return _fail("PASS scenario-$1C pointer or stream bytes failed manifest/hash validation.")
	_sources["scenario_pointer_1C"] = pointer_bytes
	_sources["scenario_1C"] = stream_bytes
	_sources["scenario_1C_branch_BB4B"] = branch_bytes
	_sources["scenario_1C_branch_B49E"] = b49e_bytes
	_sources["scenario_1C_branch_B4B6"] = b4b6_bytes
	_sources["scenario_1C_fa_wrapper"] = wrapper_bytes
	_sources["scenario_1C_f3_selector10"] = selector10_bytes
	_sources["scenario_1C_f3_selector1E"] = selector1e_bytes
	return true


func _load_scenario_termination_sources() -> bool:
	var continuation_file := FileAccess.open(SCENARIO_CONTINUATION_MANIFEST, FileAccess.READ)
	if continuation_file == null:
		return _fail("Scenario termination source manifest is unavailable.")
	var continuation_variant: Variant = JSON.parse_string(continuation_file.get_as_text())
	if not continuation_variant is Dictionary:
		return _fail("Scenario termination source manifest is malformed.")
	var continuation_manifest: Dictionary = continuation_variant
	if String(continuation_manifest.get("schema", "")) != "bank10-scenario-continuation-sources-v1" \
			or String(continuation_manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Scenario termination manifest targets another ROM or schema.")
	var continuation_rows: Dictionary = {}
	for row_variant in continuation_manifest.get("entries", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			continuation_rows[String(row.get("path", ""))] = row
	for name_variant in SCENARIO_TERMINATION_SPANS:
		var name := String(name_variant)
		var spec: Dictionary = SCENARIO_TERMINATION_SPANS[name]
		var filename := String(spec["file"])
		if not continuation_rows.has(filename):
			return _fail("Scenario termination manifest omits %s." % filename)
		var row: Dictionary = continuation_rows[filename]
		if int(row.get("size_bytes", -1)) != int(spec["length"]) \
				or String(row.get("sha256", "")) != String(spec["sha256"]) \
				or String(row.get("prg_bank", "")) != String(spec["bank"]) \
				or String(row.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(row.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(row.get("file_offset", "")) != String(spec["offset"]):
			return _fail("Scenario termination manifest metadata differs for %s." % filename)
		var source_bytes := FileAccess.get_file_as_bytes(SCENARIO_CONTINUATION_ROOT + filename)
		if source_bytes.size() != int(spec["length"]) \
				or _sha256(source_bytes) != String(spec["sha256"]):
			return _fail("Scenario termination source failed its size/hash check: %s." % filename)
		_sources[name] = source_bytes

	var task_manifest_file := FileAccess.open(SCENARIO_TASK_RUNTIME_MANIFEST, FileAccess.READ)
	if task_manifest_file == null:
		return _fail("Scenario task-runtime source manifest is unavailable.")
	var task_manifest_variant: Variant = JSON.parse_string(task_manifest_file.get_as_text())
	if not task_manifest_variant is Dictionary:
		return _fail("Scenario task-runtime source manifest is malformed.")
	var task_manifest: Dictionary = task_manifest_variant
	if String(task_manifest.get("schema", "")) != "bank10-scenario-task-runtime-sources-v1" \
			or String(task_manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Scenario task-runtime manifest targets another ROM or schema.")
	var task_rows: Dictionary = {}
	for row_variant in task_manifest.get("entries", []):
		if row_variant is Dictionary:
			var task_row: Dictionary = row_variant
			task_rows[String(task_row.get("path", ""))] = task_row
	for path_variant in SCENARIO_TASK_SOURCE_REQUIREMENTS:
		var path := String(path_variant)
		var requirement: Dictionary = SCENARIO_TASK_SOURCE_REQUIREMENTS[path]
		if not task_rows.has(path):
			return _fail("Scenario task-runtime manifest omits %s." % path)
		var task_row: Dictionary = task_rows[path]
		if String(task_row.get("cpu_address", "")) != String(requirement["cpu_address"]) \
				or String(task_row.get("file_offset", "")) != String(requirement["file_offset"]) \
				or int(task_row.get("length_bytes", -1)) != int(requirement["length"]) \
				or String(task_row.get("sha256", "")) != String(requirement["sha256"]):
			return _fail("Scenario task-runtime metadata differs for %s." % path)
		var task_bytes := FileAccess.get_file_as_bytes("res://" + path)
		if task_bytes.size() != int(requirement["length"]) \
				or _sha256(task_bytes) != String(requirement["sha256"]) \
				or String(task_row.get("bytes_hex", "")).replace(" ", "").to_lower() != task_bytes.hex_encode():
			return _fail("Scenario task-runtime bytes failed size/hash/manifest validation: %s." % path)
		var key := "bank10_reader" if path.ends_with("bank10_reader_entry_8000_803E.bin") \
			else "scenario_pointer_35" if path.ends_with("scenario_pointer_35.bin") else "scenario_35"
		_sources[key] = task_bytes
	return true


func _load_inline_append_dependency(dependency_variant: Variant) -> bool:
	if not dependency_variant is Dictionary:
		return _fail("Manifest omits the existing ROM inline-record append dependency.")
	var dependency: Dictionary = dependency_variant
	if String(dependency.get("manifest", "")) != APPEND_MANIFEST_PATH \
			or String(dependency.get("file", "")) != "fixed_inline_record_append_handler_CCD2_CD0C.bin" \
			or String(dependency.get("cpu_start", "")) != "0xCCD2" \
			or String(dependency.get("cpu_end_exclusive", "")) != "0xCD0D" \
			or String(dependency.get("file_offset", "")) != "0x03CCE2" \
			or int(dependency.get("length", -1)) != 59 \
			or String(dependency.get("sha256", "")) != APPEND_SOURCE_SHA256:
		return _fail("Inline-record append dependency metadata differs from its checked ROM source.")
	var dependency_manifest_file := FileAccess.open(APPEND_MANIFEST_PATH, FileAccess.READ)
	if dependency_manifest_file == null:
		return _fail("Existing slot-$09 inline-record append manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(dependency_manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _fail("Existing slot-$09 inline-record append manifest is malformed.")
	var source_manifest: Dictionary = manifest_variant
	var rom_variant: Variant = source_manifest.get("rom", {})
	if not rom_variant is Dictionary:
		return _fail("Inline-record append manifest has no ROM identity block.")
	var append_rom: Dictionary = rom_variant
	if String(source_manifest.get("schema", "")) != "ct2-slot09-86f8-worker-source-v1" \
			or String(append_rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Inline-record append manifest targets another source ROM.")
	var found := false
	for span_variant in source_manifest.get("spans", []):
		if span_variant is Dictionary and String(span_variant.get("file", "")) == String(dependency["file"]):
			var span: Dictionary = span_variant
			if String(span.get("file_offset", "")) != String(dependency["file_offset"]) \
					or int(span.get("length", -1)) != int(dependency["length"]) \
					or String(span.get("sha256", "")) != APPEND_SOURCE_SHA256 \
					or String(span.get("cpu_start", "")) != String(dependency["cpu_start"]) \
					or String(span.get("cpu_end_exclusive", "")) != String(dependency["cpu_end_exclusive"]):
				return _fail("Inline-record append span metadata changed in its owning manifest.")
			found = true
			break
	if not found:
		return _fail("Owning slot-$09 manifest omits the CCD2 append-handler span.")
	_append_handler = FileAccess.get_file_as_bytes(APPEND_SOURCE_PATH)
	if _append_handler.size() != 59 or _sha256(_append_handler) != APPEND_SOURCE_SHA256:
		return _fail("ROM-derived CCD2 append-handler bytes failed validation.")
	_source_span_hashes[String(dependency["file"])] = APPEND_SOURCE_SHA256
	return true


func _load_actor_seed_dependencies(dependencies_variant: Variant) -> bool:
	if not dependencies_variant is Dictionary:
		return _fail("Manifest omits the scheduler-owned actor seed source dependencies.")
	var dependencies: Dictionary = dependencies_variant
	var task_manifest_file := FileAccess.open(TASK_CONTEXT_MANIFEST_PATH, FileAccess.READ)
	if task_manifest_file == null:
		return _fail("Task-context actor seed manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(task_manifest_file.get_as_text())
	if not manifest_variant is Dictionary \
			or String((manifest_variant as Dictionary).get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Task-context actor seed manifest targets another source ROM.")
	var task_manifest: Dictionary = manifest_variant
	for name in ["caller", "helper"]:
		var spec_variant: Variant = dependencies.get(name, {})
		if not spec_variant is Dictionary:
			return _fail("Actor seed dependency is missing: %s." % name)
		var spec: Dictionary = spec_variant
		var expected_file := "fixed_scenario_actor_worker_seed_ED15_ED2C.bin" if name == "caller" else "fixed_task_seed_CAE7.bin"
		var expected_path := ACTOR_CALLER_PATH if name == "caller" else TASK_SEED_HELPER_PATH
		var expected_hash := ACTOR_CALLER_SHA256 if name == "caller" else TASK_SEED_HELPER_SHA256
		var expected_start := "0xED15" if name == "caller" else "0xCAE7"
		var expected_end := "0xED2D" if name == "caller" else "0xCAF7"
		var expected_offset := "0x03ED25" if name == "caller" else "0x03CAF7"
		var expected_length := 24 if name == "caller" else 16
		if String(spec.get("manifest", "")) != TASK_CONTEXT_MANIFEST_PATH \
				or String(spec.get("file", "")) != expected_file \
				or String(spec.get("cpu_start", "")) != expected_start \
				or String(spec.get("cpu_end_exclusive", "")) != expected_end \
				or String(spec.get("file_offset", "")) != expected_offset \
				or int(spec.get("length", -1)) != expected_length \
				or String(spec.get("sha256", "")) != expected_hash:
			return _fail("Actor seed dependency metadata differs for %s." % expected_file)
		var found := false
		for span_variant in task_manifest.get("spans", []):
			if span_variant is Dictionary and String(span_variant.get("file", "")) == expected_file:
				var span: Dictionary = span_variant
				if String(span.get("cpu_address", "")) != expected_start \
						or String(span.get("file_offset", "")) != expected_offset \
						or int(span.get("length", -1)) != expected_length \
						or String(span.get("sha256", "")) != expected_hash:
					return _fail("Task-context actor seed span metadata changed for %s." % expected_file)
				found = true
				break
		if not found:
			return _fail("Task-context manifest omits actor seed dependency %s." % expected_file)
		var bytes := FileAccess.get_file_as_bytes(expected_path)
		if bytes.size() != expected_length or _sha256(bytes) != expected_hash:
			return _fail("Actor seed dependency bytes failed validation: %s." % expected_file)
		_sources["actor_seed_%s" % name] = bytes
		_source_span_hashes[expected_file] = expected_hash
	return true


## Consumes the live dispatch dictionary emitted by RomFreshKickoffSourceRouteRunner.
## RAM and stack are copied only from that dictionary; trace state is never used.
func execute_from_next_task_dispatch(next_task_dispatch: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked slot-$09 source package first.")
	var preflight := _validate_dispatch(next_task_dispatch)
	if not bool(preflight.get("ok", false)):
		return preflight
	_ram = (next_task_dispatch["ram_image"] as PackedByteArray).duplicate()
	_stack = (next_task_dispatch["stack_page"] as PackedByteArray).duplicate()
	var mapper_input: Dictionary = next_task_dispatch["mapper"]
	_cpu = {
		"a": int(next_task_dispatch["a"]), "x": int(next_task_dispatch["x"]),
		"y": int(next_task_dispatch["y"]), "sp": int(next_task_dispatch["sp"]),
		"pc": 0xEB8B, "p": 0, "p_known_mask": 0,
		"bank_low": int(next_task_dispatch["bank_low"]),
		"bank_high": int(next_task_dispatch["bank_high"]),
	}
	_mapper = {"bank_low": int(mapper_input["bank_low"]),
		"bank_high": int(mapper_input["bank_high"]), "select": int(mapper_input["select"]),
		"bank_registers": {6: int(mapper_input["bank_low"]), 7: int(mapper_input["bank_high"])}}
	_entry_registers = {"a": int(_cpu["a"]), "x": int(_cpu["x"]),
		"y": int(_cpu["y"]), "p": int(next_task_dispatch.get("p", 0)),
		"p_known_mask": int(next_task_dispatch.get("p_known_mask", 0)),
		"sp": int(_cpu["sp"]), "pc": int(_cpu["pc"])}
	_cpu["p"] = int(_entry_registers["p"])
	_cpu["p_known_mask"] = int(_entry_registers["p_known_mask"])
	_writes.clear()
	_stack_writes.clear()
	_mapper_writes.clear()
	_instruction_pcs.clear()
	_calls.clear()
	_returns.clear()
	_scenario_seed_request.clear()
	_scenario_runtime_events.clear()
	_scenario_wait_worker_executed = false
	_scenario_route_state_executed = false
	_scenario_post_callback_executed = false
	_scenario_idle_worker_vector_ready = false
	_actor_worker_seed_request.clear()
	_actor_seed_pause_ready = false

	if not _execute_root_prefix():
		return _stopped("unsupported_source_state", int(_cpu.get("pc", -1)), error_message)
	if _is_scenario1e_callback45_zero_phase_worker_vector_profile(_ram):
		_scenario_idle_worker_vector_ready = true
	if not _actor_worker_seed_request.is_empty():
		return _build_actor_seed_pause_result()
	var scenario36_event_seed_return := int(_ram[0x0518]) == 0x36 \
		and not _scenario_seed_request.is_empty() and int(_cpu["pc"]) == 0xEB9E
	var scenario2e_event_seed_return := int(_ram[0x0518]) == 0x2E \
		and not _scenario_seed_request.is_empty() and int(_cpu["pc"]) == 0xEB9E
	var stop_at_scenario_event_seed_return := scenario36_event_seed_return or scenario2e_event_seed_return
	return {
		"ok": true,
		"status": "scenario36_event_seeded_at_ec74_return" if scenario36_event_seed_return \
			else ("scenario2e_event_seeded_at_ec74_return" if scenario2e_event_seed_return else "stopped_before_worker_body"),
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"entry_registers": _entry_registers.duplicate(true),
		"entry_pc": 0xEB8B,
		"exit_pc": int(_cpu["pc"]),
		"exit_bank": int(_mapper["bank_low"]),
		"registers": {"a": int(_cpu["a"]), "x": int(_cpu["x"]), "y": int(_cpu["y"]),
			"sp": int(_cpu["sp"]), "pc": int(_cpu["pc"]), "p": int(_cpu["p"]),
			"p_known_mask": int(_cpu["p_known_mask"])},
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"writes": _writes.duplicate(true),
		"stack_writes": _stack_writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"calls": _calls.duplicate(true),
		"returns": _returns.duplicate(true),
		"scenario_active": not _scenario_seed_request.is_empty(),
		"scenario_seed_request": _scenario_seed_request.duplicate(true),
		"scenario_runtime_events": _scenario_runtime_events.duplicate(true),
		"scenario_wait_worker_executed": _scenario_wait_worker_executed,
		"scenario_route_state_executed": _scenario_route_state_executed,
		"scenario_post_callback_executed": _scenario_post_callback_executed,
		"scenario_idle_worker_vector_ready": _scenario_idle_worker_vector_ready,
		"scenario_idle_worker_vector_profile_matches": _is_scenario1e_callback45_zero_phase_worker_vector_profile(_ram),
		"scenario_active_stop_boundary": "$EC74 RTS->$EB9E" if stop_at_scenario_event_seed_return else "",
		"pending_worker_call": {} if stop_at_scenario_event_seed_return else {"source_pc": 0xEBB0, "return_word": 0xEBB2,
			"return_pc": 0xEBB3, "target_pc": 0x86F8, "target_bank": 0x18},
		"worker_body_executed": false,
		"worker_body_bytes_read": false,
		"trace_state_used": false,
		"runtime_integrated": false,
	}


## Continues scenario `$36` from the already-adopted `$EC74 RTS->$EB9E`
## boundary through the live root caller and mapper restore. Stops at vector
## `$86F8` before reading the bank-$18 worker body.
func resume_scenario36_after_event(slot09_snapshot: Dictionary,
		event_result: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked slot-$09 source package first.")
	var registers := {
		"a": int(slot09_snapshot.get("a", -1)),
		"x": int(slot09_snapshot.get("x", -1)),
		"y": int(slot09_snapshot.get("y", -1)),
		"sp": int(slot09_snapshot.get("sp", -1)),
		"p": int(slot09_snapshot.get("p", 0)),
		"p_known_mask": int(slot09_snapshot.get("p_known_mask", 0)),
	}
	var mapper_variant: Variant = slot09_snapshot.get("mapper", {})
	var ram_variant: Variant = slot09_snapshot.get("ram_image", PackedByteArray())
	var stack_variant: Variant = slot09_snapshot.get("stack_page", PackedByteArray())
	var seed_variant: Variant = event_result.get("scenario_seed_request", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var seed: Dictionary = seed_variant if seed_variant is Dictionary else {}
	var scenario_flag := int(ram_variant[0x0516]) if ram_variant is PackedByteArray and ram_variant.size() == RAM_SIZE else -1
	var seed_record_variant: Variant = seed.get("source_record_bytes", PackedByteArray())
	var seed_record: PackedByteArray = seed_record_variant if seed_record_variant is PackedByteArray else PackedByteArray()
	var first_event_state: bool = scenario_flag == 0x41 and seed_record == PackedByteArray([0x10, 0x3A, 0x8F, 0xF0]) \
			and int(ram_variant[0x0519]) == 0 \
			and int(ram_variant[0x0523]) == 0x10 and int(ram_variant[0x0524]) == 0x3A \
			and int(ram_variant[0x0528]) == 0x8F and int(ram_variant[0x0529]) == 0xFF
	var followup_event_state: bool = scenario_flag == 0x61 and seed_record == PackedByteArray([0x20, 0x0C, 0x4E, 0x74]) \
			and int(ram_variant[0x0519]) > 0 and int(ram_variant[0x0519]) <= 0x20 \
			and int(ram_variant[0x0523]) == 0x20 and int(ram_variant[0x0524]) == 0x0C \
			and int(ram_variant[0x0528]) == 0x4E and int(ram_variant[0x0529]) == 0x74
	var scenario36_f9_followup_state: bool = scenario_flag == 0x61 \
			and seed_record == PackedByteArray([0x3E, 0x01, 0xE6, 0x75]) \
			and int(ram_variant[0x0519]) > 0 and int(ram_variant[0x0519]) <= 0x3E \
			and int(ram_variant[0x0523]) == 0x3E and int(ram_variant[0x0524]) == 0x01 \
			and int(ram_variant[0x0528]) == 0xE6 and int(ram_variant[0x0529]) == 0x75 \
			and int(ram_variant[0x052B]) == 0 and int(ram_variant[0x003A]) == 0x07 \
			and (int(ram_variant[0x005D]) | (int(ram_variant[0x005E]) << 8)) == 0xB809
	var scenario36_f7_event_state: bool = scenario_flag == 0x61 \
			and seed_record == PackedByteArray([0x32, 0x1F, 0x4C, 0xF0]) \
			and int(ram_variant[0x0519]) > 0 and int(ram_variant[0x0519]) < 0x28 \
			and int(ram_variant[0x0523]) == 0x32 and int(ram_variant[0x0524]) == 0x1F \
			and int(ram_variant[0x0528]) == 0x4C and int(ram_variant[0x0529]) == 0xFF \
			and int(ram_variant[0x052B]) == 0x02 and int(ram_variant[0x003A]) == 0x06 \
			and (int(ram_variant[0x005D]) | (int(ram_variant[0x005E]) << 8)) == 0xB802
	var mirror_event_state: bool = scenario_flag == 0x61 and seed_record == PackedByteArray([0x32, 0x72, 0x66, 0xF0]) \
			and int(ram_variant[0x0519]) > 0 and int(ram_variant[0x0519]) <= 0x20 \
			and int(ram_variant[0x0523]) == 0x32 and int(ram_variant[0x0524]) == 0x72 \
			and int(ram_variant[0x0528]) == 0x66 and int(ram_variant[0x0529]) == 0xFF \
			and int(ram_variant[0x052A]) == 0x40
	if String(event_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(event_result.get("status", "")) != "scenario36_event_seeded_at_ec74_return" \
			or int(event_result.get("exit_pc", -1)) != 0xEB9E \
			or int(seed.get("scenario_id", -1)) != 0x36 \
			or int(slot09_snapshot.get("slot_base", -1)) != 0x09 \
			or int(slot09_snapshot.get("active_task_slot", -1)) != 0x09 \
			or int(slot09_snapshot.get("pc", -1)) != 0xEB9E \
			or int(slot09_snapshot.get("bank_low", -1)) != 0x10 \
			or int(slot09_snapshot.get("bank_high", -1)) != 0x11 \
			or not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE \
			or ram_variant != event_result.get("ram_image", PackedByteArray()) \
			or stack_variant != event_result.get("stack_page", PackedByteArray()) \
			or int(ram_variant[0x0518]) != 0x36 \
			or not (first_event_state or followup_event_state or mirror_event_state \
				or scenario36_f7_event_state or scenario36_f9_followup_state) \
			or int(ram_variant[0x0015]) != 0xFF or int(ram_variant[0x0016]) != 0xF0 \
			or int(ram_variant[0x0017]) != 0x0B:
		return _failure("Post-event continuation requires unchanged live `$EB9E`: slot/active/pc=$%02X/$%02X/$%04X, context banks=$%02X/$%02X, mapper=$%02X/$%02X, ram/stack match=%s/%s, scenario=$%02X/$%02X, slot15=%s." % [
			int(slot09_snapshot.get("slot_base", -1)), int(slot09_snapshot.get("active_task_slot", -1)),
			int(slot09_snapshot.get("pc", -1)), int(slot09_snapshot.get("bank_low", -1)),
			int(slot09_snapshot.get("bank_high", -1)), 0x10, 0x11,
			str(ram_variant == event_result.get("ram_image", PackedByteArray())),
			str(stack_variant == event_result.get("stack_page", PackedByteArray())),
			int(ram_variant[0x0516]) if ram_variant is PackedByteArray and ram_variant.size() == RAM_SIZE else -1,
			int(ram_variant[0x0518]) if ram_variant is PackedByteArray and ram_variant.size() == RAM_SIZE else -1,
			(ram_variant.slice(0x0015, 0x0019) as PackedByteArray).hex_encode() if ram_variant is PackedByteArray and ram_variant.size() == RAM_SIZE else "missing"])
	_cpu = {"a": int(registers.get("a", -1)), "x": int(registers.get("x", -1)),
		"y": int(registers.get("y", -1)), "sp": int(registers.get("sp", -1)),
		"pc": 0xEB9E, "p": int(registers.get("p", 0)),
		"p_known_mask": int(registers.get("p_known_mask", 0)),
		"bank_low": 0x10, "bank_high": 0x11}
	_ram = (ram_variant as PackedByteArray).duplicate()
	_stack = (stack_variant as PackedByteArray).duplicate()
	_mapper = {"bank_low": 0x10, "bank_high": 0x11, "select": 7,
		"bank_registers": {6: 0x10, 7: 0x11}}
	_entry_registers = {"a": int(_cpu["a"]), "x": int(_cpu["x"]),
		"y": int(_cpu["y"]), "p": int(_cpu["p"]),
		"p_known_mask": int(_cpu["p_known_mask"]), "sp": int(_cpu["sp"]),
		"pc": int(_cpu["pc"])}
	_writes.clear()
	_stack_writes.clear()
	_mapper_writes.clear()
	_instruction_pcs.clear()
	_calls.clear()
	_returns.clear()
	_scenario_seed_request = seed.duplicate(true)
	_scenario_runtime_events = (event_result.get("scenario_runtime_events", []) as Array).duplicate(true)
	_scenario_wait_worker_executed = false
	_scenario_route_state_executed = false
	_scenario_post_callback_executed = false
	_scenario_idle_worker_vector_ready = false
	if not _execute_root_prefix_after_ec08():
		return _stopped("unsupported_scenario36_post_event_state", int(_cpu.get("pc", -1)), error_message)
	return {
		"ok": true,
		"status": "scenario36_event_returned_to_worker_vector",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"entry_pc": 0xEB9E,
		"caller_entry_pc": 0xEB8B,
		"exit_pc": int(_cpu["pc"]),
		"exit_bank": int(_mapper["bank_low"]),
		"entry_registers": _entry_registers.duplicate(true),
		"registers": {"a": int(_cpu["a"]), "x": int(_cpu["x"]),
			"y": int(_cpu["y"]), "sp": int(_cpu["sp"]), "pc": int(_cpu["pc"]),
			"p": int(_cpu["p"]), "p_known_mask": int(_cpu["p_known_mask"])},
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"writes": _writes.duplicate(true),
		"stack_writes": _stack_writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"calls": _calls.duplicate(true),
		"returns": _returns.duplicate(true),
		"scenario_active": true,
		"scenario_seed_request": _scenario_seed_request.duplicate(true),
		"scenario_runtime_events": _scenario_runtime_events.duplicate(true),
		"pending_worker_call": {"source_pc": 0xEBB0, "return_word": 0xEBB2,
			"return_pc": 0xEBB3, "target_pc": 0x86F8, "target_bank": 0x18},
		"worker_body_executed": false,
		"worker_body_bytes_read": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


## Continues scenario `$2E` from the verified `$EC74 RTS->$EB9E` return through
## the shared slot-$09 caller. The ROM reads `$05D2`, returns on the observed
## zero branch, restores mapper banks `$18/$19`, and stops at vector `$86F8`.
func resume_scenario2e_after_event(slot09_snapshot: Dictionary,
		event_result: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked slot-$09 source package first.")
	var registers_variant: Variant = event_result.get("registers", {})
	var mapper_variant: Variant = event_result.get("mapper", {})
	var ram_variant: Variant = event_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = event_result.get("stack_page", PackedByteArray())
	var seed_variant: Variant = event_result.get("scenario_seed_request", {})
	var events_variant: Variant = event_result.get("scenario_runtime_events", [])
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not seed_variant is Dictionary or not events_variant is Array:
		return _failure("Scenario-$2E event result omits its source CPU, mapper, memory, seed, or event contract.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var seed: Dictionary = seed_variant
	var source_record_variant: Variant = seed.get("source_record_bytes", PackedByteArray())
	var source_record: PackedByteArray = source_record_variant if source_record_variant is PackedByteArray else PackedByteArray()
	var source_hashes_variant: Variant = event_result.get("source_span_hashes", {})
	var snapshot_mapper_low := int(slot09_snapshot.get("bank_low", -1))
	var snapshot_mapper_high := int(slot09_snapshot.get("bank_high", -1))
	var snapshot_ram_variant: Variant = slot09_snapshot.get("ram_image", PackedByteArray())
	var snapshot_stack_variant: Variant = slot09_snapshot.get("stack_page", PackedByteArray())
	var matching_event_record := false
	for event_variant in events_variant:
		if not event_variant is Dictionary:
			return _failure("Scenario-$2E event history contains a malformed source event.")
		var source_event: Dictionary = event_variant
		var event_record_variant: Variant = source_event.get("source_bytes", PackedByteArray())
		var event_record: PackedByteArray = event_record_variant if event_record_variant is PackedByteArray else PackedByteArray()
		var event_seed_variant: Variant = source_event.get("seed_contract", {})
		if String(source_event.get("kind", "")) == "event_record" \
				and int(source_event.get("source_pointer", -1)) == 0xB74F \
				and event_record == PackedByteArray([0x78, 0x36, 0x8B, 0x6D]) \
				and event_seed_variant is Dictionary and (event_seed_variant as Dictionary) == seed:
			matching_event_record = true
	var source_entry_state_is_exact := int(slot09_snapshot.get("a", -1)) == int(registers.get("a", -2)) \
		and int(slot09_snapshot.get("x", -1)) == int(registers.get("x", -2)) \
		and int(slot09_snapshot.get("y", -1)) == int(registers.get("y", -2)) \
		and int(slot09_snapshot.get("sp", -1)) == int(registers.get("sp", -2))
	if String(event_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(event_result.get("source_manifest", "")) != MANIFEST_PATH \
			or not source_hashes_variant is Dictionary or source_hashes_variant != _source_span_hashes \
			or String(event_result.get("status", "")) != "scenario2e_event_seeded_at_ec74_return" \
			or not bool(event_result.get("scenario_active", false)) \
			or bool(event_result.get("worker_body_executed", true)) \
			or bool(event_result.get("worker_body_bytes_read", true)) \
			or int(event_result.get("entry_pc", -1)) != 0xEB8B \
			or int(event_result.get("exit_pc", -1)) != 0xEB9E \
			or int(slot09_snapshot.get("slot_base", -1)) != 0x09 \
			or int(slot09_snapshot.get("active_task_slot", -1)) != 0x09 \
			or int(slot09_snapshot.get("pc", -1)) != 0xEB9E \
			or not source_entry_state_is_exact \
			or snapshot_mapper_low != 0x10 or snapshot_mapper_high != 0x11 \
			or int(mapper.get("bank_low", -1)) != 0x10 \
			or int(mapper.get("bank_high", -1)) != 0x11 \
			or int(mapper.get("select", -1)) != 0x07 \
			or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or not snapshot_ram_variant is PackedByteArray or snapshot_ram_variant != ram \
			or not snapshot_stack_variant is PackedByteArray or snapshot_stack_variant != stack \
			or int(ram[0x0516]) != 0x41 or int(ram[0x0517]) != 0x40 \
			or int(ram[0x0518]) != 0x2E or int(ram[0x0519]) != 0x00 \
			or ram.slice(0x051A, 0x051C) != PackedByteArray([0xE8, 0x9B]) \
			or int(ram[0x0523]) != 0x78 or int(ram[0x0524]) != 0x36 \
			or int(ram[0x0528]) != 0x8B or int(ram[0x0529]) != 0x6D \
			or int(ram[0x052A]) != 0x00 or int(ram[0x05D2]) != 0x00 \
			or int(ram[0x003A]) != 0x05 \
			or ram.slice(0x005D, 0x005F) != PackedByteArray([0x53, 0xB7]) \
			or int(registers.get("a", -1)) != 0xFF \
			or int(registers.get("x", -1)) != 0x15 \
			or int(registers.get("y", -1)) != 0xF0 \
			or int(registers.get("sp", -1)) != 0x7A \
			or int(registers.get("pc", -1)) != 0xEB9E \
			or int(registers.get("p_known_mask", -1)) != 0xC3 \
			or int(seed.get("scenario_id", -1)) != 0x2E \
			or int(seed.get("source_record_cpu_address", -1)) != 0xB74F \
			or int(seed.get("source_record_file_offset", -1)) != 0x02375F \
			or source_record != PackedByteArray([0x78, 0x36, 0x8B, 0x6D]) \
			or int(seed.get("wait_value_ram_0523", -1)) != 0x78 \
			or int(seed.get("event_selector_ram_0524", -1)) != 0x36 \
			or int(seed.get("actor_selector_ram_0528", -1)) != 0x8B \
			or int(seed.get("actor_parameter_ram_0529", -1)) != 0x6D \
			or int(seed.get("setup_cpu_address", -1)) != 0x8097 \
			or int(seed.get("task_create_cpu_address", -1)) != 0xC50F \
			or int(seed.get("task_seed_cpu_address", -1)) != 0xCAE7 \
			or int(seed.get("task_slot_base", -1)) != 0x15 \
			or int(seed.get("saved_stack_pointer", -1)) != 0xF0 \
			or int(seed.get("bank_base", -1)) != 0x0B \
			or int(seed.get("callback_entry_cpu_address", -1)) != 0x814C \
			or not matching_event_record \
			or int(ram[0x0015]) != 0xFF or int(ram[0x0016]) != 0xF0 \
			or int(ram[0x0017]) != 0x0B or stack[0xF1] != 0x08 or stack[0xF2] != 0x80:
		return _failure("Scenario-$2E continuation requires the exact ROM-derived `$EB9E` seed state, RAM, mapper, and stack contract.")
	_cpu = {"a": int(registers.get("a", -1)), "x": int(registers.get("x", -1)),
		"y": int(registers.get("y", -1)), "sp": int(registers.get("sp", -1)),
		"pc": 0xEB9E, "p": int(registers.get("p", 0)),
		"p_known_mask": int(registers.get("p_known_mask", 0)),
		"bank_low": 0x10, "bank_high": 0x11}
	_ram = ram.duplicate()
	_stack = stack.duplicate()
	_mapper = {"bank_low": 0x10, "bank_high": 0x11, "select": 7,
		"bank_registers": {6: 0x10, 7: 0x11}}
	_entry_registers = {"a": int(_cpu["a"]), "x": int(_cpu["x"]),
		"y": int(_cpu["y"]), "p": int(_cpu["p"]),
		"p_known_mask": int(_cpu["p_known_mask"]), "sp": int(_cpu["sp"]),
		"pc": int(_cpu["pc"])}
	_writes.clear()
	_stack_writes.clear()
	_mapper_writes.clear()
	_instruction_pcs.clear()
	_calls.clear()
	_returns.clear()
	_scenario_seed_request = seed.duplicate(true)
	_scenario_runtime_events.clear()
	for event_variant in events_variant:
		_scenario_runtime_events.append((event_variant as Dictionary).duplicate(true))
	_scenario_wait_worker_executed = false
	_scenario_route_state_executed = false
	_scenario_post_callback_executed = false
	_scenario_idle_worker_vector_ready = false
	if not _execute_root_prefix_after_ec08():
		return _stopped("unsupported_scenario2e_post_event_state", int(_cpu.get("pc", -1)), error_message)
	return {
		"ok": true,
		"status": "scenario2e_event_returned_to_worker_vector",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"entry_pc": 0xEB9E,
		"caller_entry_pc": 0xEB8B,
		"exit_pc": int(_cpu["pc"]),
		"exit_bank": int(_mapper["bank_low"]),
		"entry_registers": _entry_registers.duplicate(true),
		"registers": {"a": int(_cpu["a"]), "x": int(_cpu["x"]),
			"y": int(_cpu["y"]), "sp": int(_cpu["sp"]), "pc": int(_cpu["pc"]),
			"p": int(_cpu["p"]), "p_known_mask": int(_cpu["p_known_mask"])},
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"writes": _writes.duplicate(true),
		"stack_writes": _stack_writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"calls": _calls.duplicate(true),
		"returns": _returns.duplicate(true),
		"scenario_active": true,
		"scenario_seed_request": _scenario_seed_request.duplicate(true),
		"scenario_runtime_events": _scenario_runtime_events.duplicate(true),
		"pending_worker_call": {"source_pc": 0xEBB0, "return_word": 0xEBB2,
			"return_pc": 0xEBB3, "target_pc": 0x86F8, "target_bank": 0x18},
		"worker_body_executed": false,
		"worker_body_bytes_read": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
	}


func _validate_dispatch(dispatch: Dictionary) -> Dictionary:
	var bank_low := int(dispatch.get("bank_low", -1))
	var bank_high := int(dispatch.get("bank_high", -1))
	var task_record_variant: Variant = dispatch.get("task_record", PackedByteArray())
	var task_record: PackedByteArray = task_record_variant if task_record_variant is PackedByteArray else PackedByteArray()
	var supported_bootstrap_resume := bank_low == 0x00 and bank_high == 0x01 \
			and task_record == PackedByteArray([0x00, 0x76, 0x00, 0x01])
	var supported_fresh_match_resume := bank_low == 0x18 and bank_high == 0x19 \
			and task_record == PackedByteArray([0x00, 0x76, 0x18, 0x19])
	if String(dispatch.get("rom_sha256", ROM_SHA256)) != ROM_SHA256 \
			or int(dispatch.get("slot_base", -1)) != 0x09 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0xEB8B \
			or int(dispatch.get("sp", -1)) != 0x7A \
			or not (supported_bootstrap_resume or supported_fresh_match_resume):
		return _failure("Expected a live slot-$09 `$EB8B` resume with its source-supported `$00/$01` bootstrap or `$18/$19` fresh-match task record; got slot=$%02X path=%s pc=$%04X sp=$%02X y=$%02X banks=$%02X/$%02X record=%s active=$%02X stack76=%s." % [
		int(dispatch.get("slot_base", -1)), String(dispatch.get("resume_path", "")),
		int(dispatch.get("pc", -1)), int(dispatch.get("sp", -1)), int(dispatch.get("y", -1)),
		bank_low, bank_high, task_record.hex_encode(),
		int((dispatch.get("ram_image", PackedByteArray()) as PackedByteArray)[0]) if (dispatch.get("ram_image", PackedByteArray()) as PackedByteArray).size() == RAM_SIZE else -1,
		((dispatch.get("stack_page", PackedByteArray()) as PackedByteArray).slice(0x76, 0x7B).hex_encode()) if (dispatch.get("stack_page", PackedByteArray()) as PackedByteArray).size() == STACK_SIZE else "invalid"])
	var ram_variant: Variant = dispatch.get("ram_image", PackedByteArray())
	var stack_variant: Variant = dispatch.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = dispatch.get("mapper", {})
	if not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE \
			or not mapper_variant is Dictionary:
		return _failure("Live dispatch must carry its full RAM image, stack page, and mapper state.")
	var mapper: Dictionary = mapper_variant
	if int(mapper.get("bank_low", -1)) != bank_low \
			or int(mapper.get("bank_high", -1)) != bank_high \
			or int(mapper.get("select", -1)) != 7:
		return _failure("Live dispatch mapper context does not match its saved slot-$09 bank pair.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var saved_sp := int(task_record[1]) if task_record.size() == 4 else -1
	var resume_y_index := (saved_sp + 1) & 0xFF
	var resume_x_index := (saved_sp + 2) & 0xFF
	var return_low_index := (saved_sp + 3) & 0xFF
	var return_high_index := (saved_sp + 4) & 0xFF
	if task_record.is_empty() or task_record.size() != 4 \
			or int(ram[0x0000]) != 0x09 \
			or int(dispatch.get("sp", -1)) != return_high_index \
			or int(stack[resume_y_index]) != int(dispatch.get("y", -1)) \
			or int(stack[resume_x_index]) != int(dispatch.get("x", -1)) \
			or int(stack[return_low_index]) != 0x8A \
			or int(stack[return_high_index]) != 0xEB:
		return _failure("Live slot-$09 task record/active-slot/stack differs: record=%s active=$%02X stack76=%s." % [
			task_record.hex_encode(), int(ram[0x0000]), stack.slice(0x76, 0x7B).hex_encode()])
	if int(ram[0x0539]) != 0:
		return _unsupported_dispatch_branch(dispatch, 0xEB92, "$0539 is nonzero; the XOR path is outside this component.")
	var scenario_flag := int(ram[0x0516])
	var scenario_id := int(ram[0x0518])
	var scenario18_callback72_initial_profile := _is_scenario18_callback72_initial_profile(ram)
	var scenario18_callback72_post_return_profile := _is_scenario18_callback72_post_return_profile(ram)
	var scenario18_callback72_countdown_profile := _is_scenario18_callback72_countdown_profile(ram)
	var scenario18_callback72_phase29_profile := _is_scenario18_callback72_phase29_profile(ram)
	var scenario38_callback34_map2d_profile := _is_scenario38_callback34_map2d_profile(ram)
	var scenario38_callback34_live_wait_profile := _is_scenario38_callback34_live_wait_profile(ram)
	var scenario38_callback34_phase29_return_profile := _is_scenario38_callback34_phase29_return_profile(ram)
	var scenario2e_root_init_profile := scenario_id == 0x2E and scenario_flag == 0x80 \
		and int(ram[0x0519]) == 0
	var scenario2e_callback36_map2f_wait_profile := _is_scenario2e_callback36_map2f_wait_profile(ram)
	var scenario2e_callback36_map2f_post_callback_profile := \
		_is_scenario2e_callback36_map2f_post_callback_profile(ram)
	var scenario2e_callback36_map2f_countdown_profile := \
		_is_scenario2e_callback36_map2f_countdown_profile(ram)
	var scenario2e_callback36_map2f_phase29_wait_profile := \
		_is_scenario2e_callback36_map2f_phase29_wait_profile(ram)
	var scenario2e_callback36_map2f_phase29_expired_profile := \
		_is_scenario2e_callback36_map2f_phase29_expired_profile(ram)
	var scenario1c_callback1f_live_wait_profile := _is_scenario1c_callback1f_live_wait_profile(ram)
	var scenario1c_callback1f_expired_profile := _is_scenario1c_callback1f_expired_profile(ram)
	var scenario1c_callback63_phase61_wait_profile := _is_scenario1c_callback63_phase61_wait_profile(ram)
	var scenario1c_callback63_phase29_wait_profile := _is_scenario1c_callback63_phase29_wait_profile(ram)
	var scenario1c_callback63_phase71_wait_profile := _is_scenario1c_callback63_phase71_wait_profile(ram)
	var scenario1c_callback63_phase71_expired_profile := _is_scenario1c_callback63_phase71_expired_profile(ram)
	var scenario1c_callback01_waitbit_profile := _is_scenario1c_callback01_waitbit_profile(ram)
	var scenario1c_callback01_phase71_waitbit_profile := _is_scenario1c_callback01_phase71_waitbit_profile(ram)
	var scenario1c_callback01_phase71_expired_profile := _is_scenario1c_callback01_phase71_expired_profile(ram)
	var scenario1c_callback01_phase29_waitbit_profile := _is_scenario1c_callback01_phase29_waitbit_profile(ram)
	var scenario1c_callback01_phase29_expired_profile := _is_scenario1c_callback01_phase29_expired_profile(ram)
	var scenario_active := scenario_flag in [0x80, 0x01, 0x29, 0x41, 0x51, 0x61, 0x71] \
		and ((scenario_id == 0x18 and scenario_flag == 0x80) \
			or scenario2e_root_init_profile \
			or scenario2e_callback36_map2f_wait_profile \
			or scenario2e_callback36_map2f_post_callback_profile \
			or scenario2e_callback36_map2f_countdown_profile \
			or scenario2e_callback36_map2f_phase29_wait_profile \
			or scenario2e_callback36_map2f_phase29_expired_profile \
			or scenario18_callback72_initial_profile \
			or scenario18_callback72_post_return_profile \
			or scenario18_callback72_countdown_profile \
			or scenario18_callback72_phase29_profile \
			or (scenario_id == 0x1C and scenario_flag in [0x80, 0x01]) \
			or scenario1c_callback1f_live_wait_profile \
			or scenario1c_callback1f_expired_profile \
			or scenario1c_callback63_phase61_wait_profile \
			or scenario1c_callback63_phase29_wait_profile \
			or scenario1c_callback63_phase71_wait_profile \
			or scenario1c_callback63_phase71_expired_profile \
			or scenario1c_callback01_waitbit_profile \
			or scenario1c_callback01_phase71_waitbit_profile \
			or scenario1c_callback01_phase71_expired_profile \
			or scenario1c_callback01_phase29_waitbit_profile \
			or scenario1c_callback01_phase29_expired_profile \
			or scenario_id in [0x1E, 0x35, 0x36, 0x44] \
			or (scenario_id == 0x38 and scenario_flag in [0x80, 0x41]) \
			or scenario38_callback34_map2d_profile \
			or scenario38_callback34_live_wait_profile \
			or scenario38_callback34_phase29_return_profile)
	if int(ram[0x0516]) != 0 and not scenario_active:
		return _unsupported_dispatch_branch(dispatch, 0xEC0D, "$0516=$%02X is outside the decoded zero branch and preserved scenario phases." % scenario_flag)
	if scenario_flag in [0x51, 0x61]:
		var expected_fields := PackedByteArray()
		var callback_wait_valid := false
		var callback_fields_valid := false
		var callback_45_profile := false
		if scenario_flag == 0x51:
			if scenario_id == 0x35:
				expected_fields = PackedByteArray([0x02, 0x3A, 0x02, 0xBC, 0x2C, 0x8F, 0x73, 0x00])
			elif scenario2e_callback36_map2f_post_callback_profile:
				expected_fields = PackedByteArray([0x78, 0x36, 0x02, 0xBC, 0x4A, 0x8B, 0x6D, 0x00])
			elif scenario_id == 0x44:
				expected_fields = PackedByteArray([0x02, 0x70, 0x00, 0x00, 0x00, 0x5C, 0xFF, 0x00])
			elif scenario_id == 0x38:
				expected_fields = PackedByteArray([0x01, 0x34, 0x02, 0x80, 0x02, 0x00, 0xFF, 0x00])
			else:
				expected_fields = PackedByteArray([0x10, 0x3A, 0x02, 0xBC, 0x2C, 0x8F, 0xFF, 0x00])
			callback_wait_valid = int(ram[0x0519]) == 0
			callback_fields_valid = ram.slice(0x0523, 0x0525) == expected_fields.slice(0, 2) \
				and ram.slice(0x0528, 0x052A) == expected_fields.slice(5, 7)
			if scenario_id == 0x38:
				callback_wait_valid = scenario38_callback34_map2d_profile
				callback_fields_valid = scenario38_callback34_map2d_profile \
					and ram.slice(0x0523, 0x052A) == PackedByteArray([0x01, 0x34, 0x02, 0x80, 0x02, 0x00, 0xFF])
		else:
			callback_wait_valid = int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x20
			# Callback `$72` leaves the live scenario-$36 continuation signature
			# Keep the earlier `$20/$0C` + `$4E/$74` producer profile and also
			# accept callback `$72`'s `$32/$72` + `$66/$FF` signature after its
			# ROM-derived map worker returns.
			var callback_0c_profile := int(ram[0x0523]) == 0x20 \
				and int(ram[0x0524]) == 0x0C \
				and int(ram[0x0528]) == 0x4E and int(ram[0x0529]) == 0x74
			var callback_72_profile := int(ram[0x0523]) == 0x32 \
				and int(ram[0x0524]) == 0x72 \
				and int(ram[0x0528]) == 0x66 and int(ram[0x0529]) == 0xFF
			var callback_1f_profile := int(ram[0x0523]) == 0x32 \
				and int(ram[0x0524]) == 0x1F \
				and int(ram[0x0528]) == 0x4C and int(ram[0x0529]) == 0xFF
			var callback_01_profile := int(ram[0x0523]) == 0x3E \
				and int(ram[0x0524]) == 0x01 \
				and int(ram[0x0528]) == 0xE6 and int(ram[0x0529]) == 0x75
			var callback_1c_profile := scenario_id == 0x1C \
				and scenario1c_callback1f_live_wait_profile
			var callback_1c_map_profile := scenario_id == 0x1C \
				and (scenario1c_callback01_waitbit_profile \
					or scenario1c_callback01_phase71_waitbit_profile)
			var callback_1c_callback63_profile := scenario_id == 0x1C \
				and scenario1c_callback63_phase61_wait_profile
			callback_45_profile = scenario_id == 0x1E \
				and int(ram[0x0523]) == 0x07 and int(ram[0x0524]) == 0x45 \
				and ram.slice(0x0525, 0x0528) == PackedByteArray([0x06, 0x80, 0x3C]) \
				and int(ram[0x0528]) == 0x90 and int(ram[0x0529]) == 0xFF
			if callback_1f_profile:
				callback_wait_valid = int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x28
			elif callback_1c_profile:
				callback_wait_valid = int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x30
			elif callback_1c_map_profile:
				callback_wait_valid = int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x27
			elif callback_1c_callback63_profile:
				callback_wait_valid = int(ram[0x0519]) >= 0x1C and int(ram[0x0519]) <= 0x27
			elif callback_01_profile:
				callback_wait_valid = int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x3E
			callback_fields_valid = callback_45_profile or callback_1c_profile \
				or callback_1c_map_profile or callback_1c_callback63_profile or (scenario_id == 0x36 \
				and (callback_0c_profile or callback_72_profile or callback_1f_profile or callback_01_profile))
		if scenario18_callback72_post_return_profile:
			callback_wait_valid = true
			callback_fields_valid = true
		if scenario_id not in [0x18, 0x1C, 0x1E, 0x2E, 0x35, 0x36, 0x38, 0x44] or not callback_wait_valid \
				or (scenario_flag == 0x61 and scenario_id not in [0x1C, 0x36] and not callback_45_profile) \
				or not callback_fields_valid:
			return _unsupported_dispatch_branch(dispatch, 0xEC8C, "The live callback fields do not match a bounded scenario-$18/$1E/$35/$36 event record.")
	var helper_flags := int(ram[0x05D2])
	var scenario1c_callback1f_post_seed_profile := _is_scenario1c_callback1f_post_seed_profile(ram)
	var scenario1c_callback01_map12_post_seed_profile := _is_scenario1c_callback01_map12_post_seed_profile(ram)
	if helper_flags not in [0x00, 0x01, 0x80] \
			or (helper_flags != 0 and scenario_id != 0x36 \
				and not (helper_flags == 0x01 \
					and (scenario1c_callback1f_post_seed_profile \
						or scenario1c_callback01_map12_post_seed_profile \
						or _is_scenario1c_callback63_post_seed_profile(ram)))):
		return _unsupported_dispatch_branch(dispatch, 0xED88,
			"$05D2=$%02X is outside the decoded zero, scenario-$36, and exact scenario-$1C post-seed branches." % helper_flags)
	return {"ok": true}


## The live scenario-$1C root resumes after `$ED15->$CAE7` installs slot `$11`.
## `$ECF1->$ECF4` has copied `$05D1=$80` to `$05D2=$01` on this path.
func _is_scenario1c_callback1f_post_seed_profile(ram: PackedByteArray) -> bool:
	return ram.size() == 0x800 \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x40, 0x1C]) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x30 \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x051B]) == 0x9B \
		and int(ram[0x0522]) == 0x02 \
		and (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) == 0xBB4F \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x30, 0x1F, 0x02, 0x3C, 0x4A, 0x4C, 0x00, 0x40]) \
		and int(ram[0x0539]) == 0 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x00, 0x01, 0x52, 0xA0, 0x80, 0x00, 0x02, 0x80, 0x01]) \
		and int(ram[0x05CE]) == 0x80


## Callback `$01`'s map-$12 route also reaches the shared `$ED85->$EDF5->$EE31`
## coordinate helper with `$05D2=$01`. The source helper updates the live
## `$05D3-$05D5` accumulator each call, so `$05D4` is deliberately not pinned;
## the callback identity, map selector, and ROM-produced movement delta are.
func _is_scenario1c_callback01_map12_post_seed_profile(ram: PackedByteArray) -> bool:
	return (_is_scenario1c_callback01_waitbit_profile(ram) \
		or _is_scenario1c_callback01_phase71_waitbit_profile(ram) \
		or _is_scenario1c_callback01_phase71_expired_profile(ram)) \
		and int(ram[0x05D1]) == 0x00 and int(ram[0x05D2]) == 0x01 \
		and int(ram[0x05D3]) == 0x00 and int(ram[0x05D5]) == 0xFF \
		and ram.slice(0x05D6, 0x05DB) == PackedByteArray([0x00, 0xFC, 0x00, 0x00, 0x00]) \
		and ram.slice(0x05DB, 0x05E3) == PackedByteArray([
			0x00, 0x00, 0x00, 0x00, 0xFC, 0x00, 0x00, 0x00])


## Callback `$63`'s source-derived actor post-seed state, observed at frames
## 9191–9255 while map `$51` and the `$B4BD` parent cursor remain live.
func _is_scenario1c_callback63_post_seed_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and _is_scenario1c_callback63_source_context(ram) \
		and int(ram[0x05D1]) == 0x00 and int(ram[0x05D2]) == 0x01 \
		and int(ram[0x05D3]) == 0x00 \
		and ((ram.slice(0x05CD, 0x05CF) == PackedByteArray([0xA0, 0x80])) \
			or (ram.slice(0x05CD, 0x05CF) == PackedByteArray([0x80, 0xA0])))


## Scenario-$1C callback-$01 has entered the ROM wait-bit branch after the
## holder-coordinate lookup selected map $12. `$ED5B->$ED68` decrements only
## `$0519` on this path while bit `$20` remains set. The map worker owns the
## advancing queue cursor bytes; this profile pins `$05CA`'s selector, map ID,
## placement, and holder coordinates while leaving only that cursor mutable.
func _is_scenario1c_callback01_waitbit_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x61, 0x40, 0x1C]) \
		and int(ram[0x0519]) <= 0x27 \
		and int(ram[0x051B]) == 0x9B \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x0522]) == 0x00 \
		and (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) == 0xB4A5 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x3C, 0x01, 0x00, 0xBC, 0x4A, 0x78, 0x58, 0x40]) \
		and int(ram[0x0539]) == 0x00 \
		and int(ram[0x05CA]) == 0x00 and int(ram[0x05CC]) == 0x12 \
		and int(ram[0x05CD]) == 0xA0 \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


## The ordinary-input PASS route reaches the same map-$12 callback-$01 wait
## with mode `$71`. ROM `$ED5B->$ED68` decrements only `$0519` while bit `$20`
## is set, then returns to the root. This exact profile is tied to the retained
## Godot source-route checkpoint; the complete mode `$71` input does not yet
## have an independently matching FCEUX RAM snapshot.
func _is_scenario1c_callback01_phase71_waitbit_profile(ram: PackedByteArray) -> bool:
	return _is_scenario1c_callback01_phase71_metadata_profile(ram) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x27


func _is_scenario1c_callback01_phase71_expired_profile(ram: PackedByteArray) -> bool:
	return _is_scenario1c_callback01_phase71_metadata_profile(ram) \
		and int(ram[0x0519]) == 0


func _is_scenario1c_callback01_phase71_metadata_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x71, 0x40, 0x1C]) \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x0522]) == 0x00 \
		and (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) == 0xB4A5 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x3C, 0x01, 0x02, 0xBC, 0x4A, 0x78, 0x58, 0x40]) \
		and ram.slice(0x0532, 0x053A) == PackedByteArray([0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x01]) \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


## The PASS route's scenario-$1C event at `$B49E` has loaded its `$3C` wait.
## This phase-$29 signature is from the live Godot source-route boundary; it is
## not an independent FCEUX RAM profile. `$ED5B` decrements `$0519` and, while
## bit `$20` remains set, returns without consuming the `$FB` at `$B4A5`.
func _is_scenario1c_callback01_phase29_waitbit_profile(ram: PackedByteArray) -> bool:
	return (_is_scenario1c_callback01_phase29_metadata_profile(ram) \
		or _is_scenario1c_callback01_phase29_cursor10_metadata_profile(ram) \
		or _is_scenario1c_callback01_phase29_cursor00_metadata_profile(ram)) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x3C


func _is_scenario1c_callback01_phase29_expired_profile(ram: PackedByteArray) -> bool:
	return (_is_scenario1c_callback01_phase29_metadata_profile(ram) \
		or _is_scenario1c_callback01_phase29_cursor10_metadata_profile(ram) \
		or _is_scenario1c_callback01_phase29_cursor00_metadata_profile(ram)) \
		and int(ram[0x0519]) == 0


func _is_scenario1c_callback01_phase29_metadata_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x40, 0x1C]) \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x0522]) == 0x00 \
		and (int(ram[0x005D]) | (int(ram[0x005E]) << 8)) == 0xB4A5 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x00]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


## After the live descriptor-$00 worker reads row `$BBDE`, the scenario-$1C
## callback-$01 countdown resumes at `$EB8B` with event cursor `$0A`; its
## source pointer remains `$005D/$005E=$B4A5`. ROM `$ED5B` only decrements
## `$0519` on the bit-$20 return branch, so keep this separate from cursor `$06`.
func _is_scenario1c_callback01_phase29_cursor10_metadata_profile(
		ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x40, 0x1C]) \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and int(ram[0x003A]) == 0x0A \
		and int(ram[0x0522]) == 0x00 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0xA5, 0xB4]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x00]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


## The source reader's high-bit `$F3 $84` branch clears `$003A`; the following
## `$F2` root path reaches `$B4A5`. Keep this continuation separate from the
## cursor-$06 and cursor-$0A profiles.
func _is_scenario1c_callback01_phase29_cursor00_metadata_profile(
		ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x40, 0x1C]) \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and int(ram[0x003A]) == 0x00 \
		and int(ram[0x0522]) == 0x00 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0xA5, 0xB4]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x00]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


func _is_scenario38_callback34_map2d_profile(ram: PackedByteArray) -> bool:
	return ram.size() == 0x800 \
		and ram.slice(0x0516, 0x053A) == PackedByteArray([
			0x51, 0x40, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x01, 0x34, 0x02, 0x80, 0x02, 0x00, 0xFF, 0x40, 0x17, 0x00, 0x00,
			0x00, 0x2C, 0x00, 0x2C, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00])


## Same-ROM scenario-$2E callback-$36 loop while map-$2F is being expanded.
## `$EC0D` takes the active-state branch, and `$EC60` returns through `$EC74`
## because phase `$41` has V set. The map cursor advances only at the source
## worker's three-cell batch boundaries.
func _is_scenario2e_callback36_map2f_wait_profile(ram: PackedByteArray) -> bool:
	if ram.size() != RAM_SIZE \
			or ram.slice(0x0516, 0x051A) != PackedByteArray([0x41, 0x40, 0x2E, 0x00]) \
			or ram.slice(0x0523, 0x052B) != PackedByteArray([
				0x78, 0x36, 0x02, 0xBC, 0x4A, 0x8B, 0x6D, 0x00]) \
			or int(ram[0x0522]) != 0 or int(ram[0x052B]) != 0 \
			or int(ram[0x0539]) != 0 \
			or int(ram[0x003A]) != 0x06 \
			or ram.slice(0x0052, 0x0054) != PackedByteArray([0xE7, 0x89]) \
			or ram.slice(0x0054, 0x0056) != PackedByteArray([0x44, 0x91]) \
			or ram.slice(0x005D, 0x005F) != PackedByteArray([0x53, 0xB7]) \
			or ram.slice(0x0079, 0x007B) != PackedByteArray([0x03, 0xAE]) \
			or int(ram[0x05CA]) != 0x01 or int(ram[0x05CC]) != 0x2F \
			or int(ram[0x05CD]) != 0xA0 or int(ram[0x05CE]) != 0x80 \
			or int(ram[0x05D2]) != 0:
		return false
	var remaining := int(ram[0x05C9])
	var map_index := 0x20 - remaining
	# Index 32 is the exhausted `$8572` map-worker boundary. The next source
	# owner is the slot-$15 terminal callback; `$0056/$0057` still name cell 31.
	if remaining > 0x20 or map_index not in [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 32] \
			or int(ram[0x05C8]) != 0xA0 + map_index:
		return false
	var expected_pointer := 0xB310 if map_index == 0 else _scenario2e_previous_metatile_pointer(map_index)
	return expected_pointer >= 0 and ram.slice(0x0056, 0x0058) == PackedByteArray([
		expected_pointer & 0xFF, (expected_pointer >> 8) & 0xFF])


## FCEUX frame 9476 records the terminal callback's phase-$51 result before
## the scenario root runs `$EC8C`.
func _is_scenario2e_callback36_map2f_post_callback_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x51, 0x40, 0x2E, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x78, 0x36, 0x02, 0xBC, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0539]) == 0 and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x0052, 0x0056) == PackedByteArray([0xE7, 0x89, 0x44, 0x91]) \
		and ram.slice(0x0056, 0x0058) == PackedByteArray([0x50, 0xB2]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x53, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


## `$EC8C` sets phase `$01` and timer `$78`; `$ED5B` decrements this timer
## while the completed map-$2F result remains live.
func _is_scenario2e_callback36_map2f_countdown_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x00, 0x2E]) \
		and int(ram[0x0519]) >= 1 and int(ram[0x0519]) <= 0x78 \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0539]) == 0 and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x0052, 0x0056) == PackedByteArray([0xE7, 0x89, 0x44, 0x91]) \
		and ram.slice(0x0056, 0x0058) == PackedByteArray([0x50, 0xB2]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x53, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


## The `$ED5B` threshold is crossed at `$28->$27`; the source then reads the
## terminal `$FB` at `$B753`, whose `$80CF` handler enters the phase-$29 wait.
func _is_scenario2e_callback36_map2f_terminal_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x21, 0x00, 0x2E, 0x27]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0539]) == 0 and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x0052, 0x0056) == PackedByteArray([0xE7, 0x89, 0x44, 0x91]) \
		and ram.slice(0x0056, 0x0058) == PackedByteArray([0x50, 0xB2]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x53, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


## After `$FB`, phase `$29` holds the completed map/callback state while its
## ROM wait counts from `$27` to `$00`. `$003A` remains live and is validated
## by ordered source-write replay rather than fixed to one captured value.
func _is_scenario2e_callback36_map2f_phase29_wait_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x00, 0x2E]) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x27 \
		and int(ram[0x0522]) == 0 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x052B]) == 0 and int(ram[0x0539]) == 0 \
		and ram.slice(0x0052, 0x0056) == PackedByteArray([0xE7, 0x89, 0x44, 0x91]) \
		and ram.slice(0x0056, 0x0058) == PackedByteArray([0x50, 0xB2]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x53, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


func _is_scenario2e_callback36_map2f_phase29_expired_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x00, 0x2E, 0x00]) \
		and int(ram[0x0522]) == 0 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x052B]) == 0 and int(ram[0x0539]) == 0 \
		and ram.slice(0x0052, 0x0056) == PackedByteArray([0xE7, 0x89, 0x44, 0x91]) \
		and ram.slice(0x0056, 0x0058) == PackedByteArray([0x50, 0xB2]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x53, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


func _scenario2e_previous_metatile_pointer(map_index: int) -> int:
	var block_map: PackedByteArray = _sources.get("map_2f_block_map", PackedByteArray())
	if block_map.size() != 0x20 or map_index <= 0 or map_index > block_map.size():
		return -1
	var metatile_id := int(block_map[map_index - 1])
	var window_offset := (0x01 << 12) + (metatile_id << 4)
	return 0xA000 + (window_offset & 0x1FFF)


func _is_scenario18_callback72_initial_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and int(ram[0x0516]) == 0x41 and int(ram[0x0518]) == 0x18 \
		and int(ram[0x0519]) <= 0x3C \
		and int(ram[0x0523]) == 0x3C and int(ram[0x0524]) == 0x72 \
		and int(ram[0x0528]) == 0x66 and int(ram[0x0529]) == 0x47 \
		and int(ram[0x0539]) == 0


func _is_scenario18_callback72_post_return_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x51, 0x40, 0x18, 0x00]) \
		and ram.slice(0x0052, 0x0054) == PackedByteArray([0x3E, 0x8B]) \
		and ram.slice(0x0523, 0x052A) == PackedByteArray([
			0x3C, 0x72, 0x02, 0xBC, 0x4A, 0x66, 0x47]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x58, 0xAF]) \
		and int(ram[0x0539]) == 0 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x11, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


func _is_scenario18_callback72_countdown_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x00, 0x18]) \
		and int(ram[0x0519]) >= 0x28 and int(ram[0x0519]) <= 0x3C \
		and ram.slice(0x0523, 0x052A) == PackedByteArray([
			0x3C, 0x72, 0x02, 0x3C, 0x4A, 0x66, 0x47]) \
		and int(ram[0x003A]) == 0x06 and int(ram[0x0539]) == 0 \
		and int(ram[0x05CE]) == 0xA0


## PASS callback `$72` has consumed its local `$FB` at `$AF58`; the scenario
## root preserves phase `$29` and counts `$0519` down before the next source event.
func _is_scenario18_callback72_phase29_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x00, 0x18]) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x27 \
		and int(ram[0x0522]) == 0 \
		and ram.slice(0x0523, 0x052A) == PackedByteArray([0x3C, 0x72, 0x02, 0x3C, 0x4A, 0x66, 0x47]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x58, 0xAF]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x11, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


## Exact post-callback scenario-$38 profile observed at the live slot-$09
## `$EB8B` resume. `$EC0D` must take the active branch, decrement the one-frame
## `$0519` wait, then read the scenario's final `$FB` at `$B7CC`; this profile
## is not interchangeable with the earlier `$51/$00` map-builder state.
func _is_scenario38_callback34_live_wait_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x40, 0x38, 0x01]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x40]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00]) \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x005D]) == 0xCC and int(ram[0x005E]) == 0xB7 \
		and int(ram[0x0079]) == 0xE9 and int(ram[0x007A]) == 0xAF \
		and int(ram[0x0522]) == 0 \
		and int(ram[0x052B]) == 0x17 \
		and int(ram[0x0532]) == 0x17 and int(ram[0x0533]) == 0x04 \
		and int(ram[0x0539]) == 0


## PASS callback `$1F` runs with phase bit `$20` set. `$ED5B` decrements the
## live wait, then returns at `$ED61` for counts >= `$28` or at `$ED68` when
## the phase bit is set; both paths leave the `$BB4F` stream untouched.
func _is_scenario1c_callback1f_live_wait_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and int(ram[0x0516]) in [0x61, 0x71] \
		and ram.slice(0x0517, 0x0519) == PackedByteArray([0x00, 0x1C]) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x30 \
		and int(ram[0x0522]) == 0x02 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x30, 0x1F, 0x02, 0xBC, 0x4A, 0x4C, 0x00, 0x40]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x4F, 0xBB]) \
		and int(ram[0x0539]) == 0x00


## The scenario-$1C callback-$1F wait has expired. `$EC34` now takes its
## zero-wait callback path; retain the exact event fields/cursor before `$EC8C`.
func _is_scenario1c_callback1f_expired_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and int(ram[0x0516]) == 0x71 and int(ram[0x0517]) == 0x00 \
		and int(ram[0x0518]) == 0x1C and int(ram[0x0519]) == 0x00 \
		and int(ram[0x0522]) == 0x02 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x30, 0x1F, 0x02, 0xBC, 0x4A, 0x4C, 0x00, 0x40]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x4F, 0xBB]) \
		and int(ram[0x0539]) == 0x00


## The ROM-derived `$B4B6` callback-$63 map event leaves its terminal `$FB` at
## `$B4BD`. The repeated muted trace shows the phase-$61 wait counting down to
## `$1C`, then phase `$71` counting `$1B..$01`; the fixed `$ED5B` worker changes
## only `$0519` while bit `$20` is set. Keep the map, parent cursor, callback
## record, and event reader cursor pinned to this source branch.
func _is_scenario1c_callback63_phase61_wait_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x61, 0x40, 0x1C]) \
		and int(ram[0x0519]) >= 0x1C and int(ram[0x0519]) <= 0x27 \
		and _is_scenario1c_callback63_source_context(ram)


## Frame 9249's callback-$63/map-$51 route returns to the shared `$ED5B`
## wait worker in phase `$29`. Keep this early `$B4BD` continuation separate
## from the later `$61/$71` callback signature, whose event bytes differ.
func _is_scenario1c_callback63_phase29_wait_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x40, 0x1C]) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x27 \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and int(ram[0x0522]) == 0x00 \
		and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x00]) \
		and int(ram[0x052B]) == 0x00 and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


func _is_scenario1c_callback63_phase71_wait_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x71, 0x40, 0x1C]) \
		and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x1B \
		and _is_scenario1c_callback63_source_context(ram)


func _is_scenario1c_callback63_phase71_expired_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x71, 0x40, 0x1C]) \
		and int(ram[0x0519]) == 0 \
		and _is_scenario1c_callback63_source_context(ram)


## The phase-$01 scenario wait crosses `$28->$27` through `$ED5B`, then the
## bank-$10 reader reaches the `$B4BD` `$FB` cursor on map `$51`. This exact
## callback-$63 root cursor is distinct from the later phase-$71 expired path.
func _is_scenario1c_callback63_b4bd_wait_terminal_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x21, 0x40, 0x1C, 0x27]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
		and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and int(ram[0x052B]) == 0x00 and int(ram[0x0539]) == 0x00 \
		and int(ram[0x05FB]) == 0x00 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


func _is_scenario1c_callback63_source_context(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x051A, 0x051C) == PackedByteArray([0xE8, 0x9B]) \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x0522]) in [0x00, 0x02] \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0xBD, 0xB4]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x38, 0x63, 0x02, 0xBC, 0x4A, 0x7A, 0x58, 0x40]) \
		and int(ram[0x0539]) == 0x00 \
		and int(ram[0x05CA]) == 0x00 and int(ram[0x05CC]) == 0x51 \
		and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54


## Exact scenario-$38 callback-$34 phase-$29 state observed before the root's
## `$EC75` clear tail. The routine clears `$0516` and returns to `$EB9E`.
func _is_scenario38_callback34_phase29_return_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x38, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0532]) == 0x17 and int(ram[0x0533]) == 0x03 \
		and int(ram[0x0539]) == 0 and int(ram[0x05D2]) == 0 \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0xE9, 0xAF]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00])


## Exact scenario-$35 callback-$3A phase-$29 dispatch observed on the recorded
## PASS route. `$EC75` consumes only the phase bit; unrelated scenario-$38
## callback fields must not be used as a proxy for this live source state.
func _is_scenario35_callback3a_phase29_return_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x00, 0x35, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x02, 0x3A, 0x02, 0x3C, 0x2C, 0x8F, 0x73, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0539]) == 0 and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x00, 0x00]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0x20, 0x00, 0x01, 0x01, 0x42, 0xA0, 0x00, 0x00, 0x00, 0x00, 0x00])


## Exact scenario-$1E callback-$45 phase-$29 dispatch observed after the PASS
## handler's first map wait. The shared `$EC75` tail consumes this live phase.
func _is_scenario1e_callback45_phase29_return_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x1E, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x07, 0x45, 0x06, 0x00, 0x3C, 0x90, 0xFF, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0539]) == 0 and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0xE3, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x01, 0x01, 0x36, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00])


## Exact scenario-$44 callback-$70 phase-$29 dispatch observed at the field
## entry. The shared `$EC75` tail consumes this phase and preserves its cursor.
func _is_scenario44_callback70_phase29_return_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x29, 0x40, 0x44, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x02, 0x70, 0x06, 0x3C, 0x2E, 0x5C, 0xFF, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and int(ram[0x0539]) == 0 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0xD9, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x02, 0x01, 0x56, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00])


## Exact slot-$09 zero-phase redispatch after the phase-$29 tail. It carries
## scenario `$1E`'s callback-$45 state to the ordinary `$86F8` worker boundary.
## `$003A` is the live bank-$10 event cursor, so its changing source value is
## validated by ordered-write replay rather than pinned in this profile.
func _is_scenario1e_callback45_zero_phase_worker_vector_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x00, 0x40, 0x1E, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x07, 0x45, 0x06, 0x00, 0x3C, 0x90, 0xFF, 0x00]) \
		and int(ram[0x0522]) == 0 and int(ram[0x052B]) == 0 \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0xE3, 0xB7]) \
		and ram.slice(0x0079, 0x007B) == PackedByteArray([0x03, 0xAE]) \
		and ram.slice(0x0532, 0x053A) == PackedByteArray([0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x01, 0x01, 0x36, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00])


func _execute_root_prefix() -> bool:
	if not _expect_root(0xEB8B, [0xA5, 0x21]): return false
	_record(0xEB8B)
	_set_a(int(_ram[0x0021]))
	if not _expect_root(0xEB8D, [0x29, 0x1E]): return false
	_record(0xEB8D)
	_set_a(int(_cpu["a"]) & 0x1E)
	if not _expect_root(0xEB8F, [0xAE, 0x39, 0x05]): return false
	_record(0xEB8F)
	_set_x(int(_ram[0x0539]))
	if not _expect_root(0xEB92, [0xF0, 0x05]): return false
	_record(0xEB92)
	if int(_cpu["x"]) != 0:
		return _fail("Unsupported nonzero $0539 branch at $EB92.")
	_cpu["pc"] = 0xEB99
	if not _expect_root(0xEB99, [0x85, 0x21]): return false
	_record(0xEB99)
	_write_ram(0x0021, int(_cpu["a"]), 0xEB99)
	if not _expect_root(0xEB9B, [0x20, 0x08, 0xEC]): return false
	_record(0xEB9B)
	_jsr(0xEB9B, 0xEC08)
	if not _execute_ec08(): return false
	if not _actor_worker_seed_request.is_empty():
		return true
	if int(_ram[0x0518]) in [0x2E, 0x36] and not _scenario_seed_request.is_empty():
		# Bound scenario roots at the `$EC74 RTS->$EB9E` return after their
		# source-derived event record requests a callback task seed.
		return _expect_pc(0xEB9E)
	var root_prefix_completed := _execute_root_prefix_after_ec08()
	if root_prefix_completed and _is_scenario1e_callback45_zero_phase_worker_vector_profile(_ram):
		_scenario_idle_worker_vector_ready = true
	return root_prefix_completed


func _execute_root_prefix_after_ec08() -> bool:
	if not _expect_pc(0xEB9E): return false
	if not _expect_root(0xEB9E, [0x20, 0x85, 0xED]): return false
	_record(0xEB9E)
	_jsr(0xEB9E, 0xED85)
	if not _execute_ed85(): return false
	if not _expect_pc(0xEBA1): return false
	if not _expect_root(0xEBA1, [0x48]): return false
	_record(0xEBA1)
	_push(int(_cpu["a"]), 0xEBA1, "PHA")
	if not _expect_root(0xEBA2, [0xA5, 0x22]): return false
	_record(0xEBA2)
	_set_a(int(_ram[0x0022]))
	if not _expect_root(0xEBA4, [0xA9, 0x18]): return false
	_record(0xEBA4)
	_set_a(0x18)
	if not _expect_root(0xEBA6, [0x85, 0x24]): return false
	_record(0xEBA6)
	_write_ram(0x0024, int(_cpu["a"]), 0xEBA6)
	if not _expect_root(0xEBA8, [0xA9, 0x19]): return false
	_record(0xEBA8)
	_set_a(0x19)
	if not _expect_root(0xEBAA, [0x85, 0x25]): return false
	_record(0xEBAA)
	_write_ram(0x0025, int(_cpu["a"]), 0xEBAA)
	if not _expect_root(0xEBAC, [0x20, 0x2D, 0xCE]): return false
	_record(0xEBAC)
	_jsr(0xEBAC, 0xCE2D)
	if not _execute_mapper_helper(): return false
	if not _expect_pc(0xEBAF): return false
	if not _expect_root(0xEBAF, [0x68]): return false
	_record(0xEBAF)
	_set_a(_pop(0xEBAF))
	if not _expect_root(0xEBB0, [0x20, 0x03, 0x80]): return false
	_record(0xEBB0)
	_jsr(0xEBB0, 0x8003)
	if int(_mapper["bank_low"]) != 0x18:
		return _fail("The source $8003 vector is not mapped in bank $18.")
	if not _expect_vector_8003(): return false
	_record(0x8003)
	_cpu["pc"] = 0x86F8 # The checked vector JMP target; do not read its body.
	return true


func _execute_ec08() -> bool:
	if not _expect_span("ec08", 0xEC08, [0xAD, 0x16, 0x05]): return false
	_record(0xEC08)
	_set_a(int(_ram[0x0516]))
	if not _expect_span("ec08", 0xEC0B, [0x29, 0x81]): return false
	_record(0xEC0B)
	_set_a(int(_cpu["a"]) & 0x81)
	if not _expect_span("ec08", 0xEC0D, [0xD0, 0x01]): return false
	_record(0xEC0D)
	if int(_cpu["a"]) != 0:
		return _execute_scenario_active_ec08_path()
	if not _expect_span("ec08", 0xEC0F, [0x60]): return false
	_record(0xEC0F)
	_rts(0xEC0F)
	return true


func _execute_scenario_active_ec08_path() -> bool:
	var active_code: PackedByteArray = _sources.get("scenario_active", PackedByteArray())
	var record_code: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	if active_code.size() != 101 or record_code.size() != 88 \
			or _sha256(active_code) != String(SOURCE_SPANS["scenario_active"]["sha256"]) \
			or _sha256(record_code) != String(SOURCE_SPANS["event_reader"]["sha256"]):
		return _fail("Scenario-active fixed helper or bank-$10 record reader failed its source hash.")
	var scenario_flag := int(_ram[0x0516])
	var scenario_id := int(_ram[0x0518])
	var scenario18_callback72_initial_profile := _is_scenario18_callback72_initial_profile(_ram)
	var scenario18_callback72_post_return_profile := _is_scenario18_callback72_post_return_profile(_ram)
	var scenario18_callback72_countdown_profile := _is_scenario18_callback72_countdown_profile(_ram)
	var scenario18_callback72_phase29_profile := _is_scenario18_callback72_phase29_profile(_ram)
	var scenario1c_callback1f_live_wait_profile := _is_scenario1c_callback1f_live_wait_profile(_ram)
	var scenario1c_callback1f_expired_profile := _is_scenario1c_callback1f_expired_profile(_ram)
	var scenario1c_callback63_phase61_wait_profile := _is_scenario1c_callback63_phase61_wait_profile(_ram)
	var scenario1c_callback63_phase29_wait_profile := _is_scenario1c_callback63_phase29_wait_profile(_ram)
	var scenario1c_callback63_phase71_wait_profile := _is_scenario1c_callback63_phase71_wait_profile(_ram)
	var scenario1c_callback63_phase71_expired_profile := _is_scenario1c_callback63_phase71_expired_profile(_ram)
	var scenario1c_callback01_waitbit_profile := _is_scenario1c_callback01_waitbit_profile(_ram)
	var scenario1c_callback01_phase71_waitbit_profile := _is_scenario1c_callback01_phase71_waitbit_profile(_ram)
	var scenario1c_callback01_phase71_expired_profile := _is_scenario1c_callback01_phase71_expired_profile(_ram)
	var scenario1c_callback01_phase29_waitbit_profile := _is_scenario1c_callback01_phase29_waitbit_profile(_ram)
	var scenario1c_callback01_phase29_expired_profile := _is_scenario1c_callback01_phase29_expired_profile(_ram)
	var scenario2e_root_init_profile := scenario_id == 0x2E and scenario_flag == 0x80 \
		and int(_ram[0x0519]) == 0
	var scenario2e_callback36_map2f_wait_profile := _is_scenario2e_callback36_map2f_wait_profile(_ram)
	var scenario2e_callback36_map2f_post_callback_profile := \
		_is_scenario2e_callback36_map2f_post_callback_profile(_ram)
	var scenario2e_callback36_map2f_countdown_profile := \
		_is_scenario2e_callback36_map2f_countdown_profile(_ram)
	var scenario2e_callback36_map2f_phase29_wait_profile := \
		_is_scenario2e_callback36_map2f_phase29_wait_profile(_ram)
	var scenario2e_callback36_map2f_phase29_expired_profile := \
		_is_scenario2e_callback36_map2f_phase29_expired_profile(_ram)
	# Pin the dispatch RAM before the `$EC3C` stores clear `$0532/$0534/$0536/$0538`.
	var scenario38_callback34_phase29_return_profile := _is_scenario38_callback34_phase29_return_profile(_ram)
	var scenario35_callback3a_phase29_return_profile := _is_scenario35_callback3a_phase29_return_profile(_ram)
	var scenario1e_callback45_phase29_return_profile := _is_scenario1e_callback45_phase29_return_profile(_ram)
	var scenario44_callback70_phase29_return_profile := _is_scenario44_callback70_phase29_return_profile(_ram)
	if not (scenario_flag in [0x80, 0x01, 0x29, 0x41, 0x51, 0x61, 0x71]) \
			or not ((scenario_id == 0x18 and scenario_flag == 0x80) \
				or scenario2e_root_init_profile \
				or scenario2e_callback36_map2f_wait_profile \
				or scenario2e_callback36_map2f_post_callback_profile \
				or scenario2e_callback36_map2f_countdown_profile \
				or scenario2e_callback36_map2f_phase29_wait_profile \
				or scenario2e_callback36_map2f_phase29_expired_profile \
				or scenario18_callback72_initial_profile \
				or scenario18_callback72_post_return_profile \
				or scenario18_callback72_countdown_profile \
				or scenario18_callback72_phase29_profile \
				or (scenario_id == 0x1C and scenario_flag in [0x80, 0x01]) \
				or scenario1c_callback1f_live_wait_profile \
				or scenario1c_callback1f_expired_profile \
				or scenario1c_callback63_phase61_wait_profile \
				or scenario1c_callback63_phase29_wait_profile \
				or scenario1c_callback63_phase71_wait_profile \
				or scenario1c_callback63_phase71_expired_profile \
				or scenario1c_callback01_waitbit_profile \
				or scenario1c_callback01_phase71_waitbit_profile \
				or scenario1c_callback01_phase71_expired_profile \
				or scenario1c_callback01_phase29_waitbit_profile \
				or scenario1c_callback01_phase29_expired_profile \
				or scenario_id in [0x1E, 0x35, 0x36, 0x44] \
				or (scenario_id == 0x38 and scenario_flag in [0x80, 0x41]) \
				or _is_scenario38_callback34_map2d_profile(_ram) \
			or _is_scenario38_callback34_live_wait_profile(_ram) \
			or _is_scenario38_callback34_phase29_return_profile(_ram)) \
			or int(_ram[0x0539]) != 0:
		return _fail("The active scenario path requires a preserved ID, decoded `$0516` phase, and live `$0518/$0519/$0539` gates.")
	_scenario_route_state_executed = scenario_flag in [0x01, 0x29]
	if not _expect_span("scenario_active", 0xEC10, [0x2C, 0x16, 0x05, 0x10, 0x1F]):
		return false
	_record(0xEC10)
	_record(0xEC13) # BIT/BPL selects one-time initialization or the shared running path.
	if scenario_flag == 0x80:
		if (int(_ram[0x0516]) & 0x80) == 0:
			return _fail("The source `$EC13` BPL path does not match fresh-init `$0516=$80`.")
		_record(0xEC15)
		_set_a(0x01)
		_write_ram(0x0516, 0x01, 0xEC17)
		_record(0xEC1A)
		_push(int(_cpu["a"]), 0xEC1A, "PHA")
		_record(0xEC1B)
		_set_a(int(_ram[0x0022]))
		_record(0xEC1D)
		_set_a(0x10)
		_write_ram(0x0024, 0x10, 0xEC1F)
		_record(0xEC21)
		_set_a(0x11)
		_write_ram(0x0025, 0x11, 0xEC23)
		_jsr(0xEC25, 0xCE2D)
		if not _execute_mapper_helper(0xEC28): return false
		_record(0xEC28)
		_set_a(_pop(0xEC28))
		_jsr(0xEC29, 0x8000)
		if not _execute_scenario_pointer_reader(): return false
		_record(0xEC2C)
		_set_a(0)
		_write_ram(0x0022, 0, 0xEC2E)
		_write_ram(0x0539, 0, 0xEC31)
	elif scenario_flag in [0x01, 0x29, 0x41, 0x51, 0x61, 0x71]:
		if (int(_ram[0x0516]) & 0x80) != 0:
			return _fail("The source `$EC13` BPL path does not match the live scenario-running flag.")
		# BPL at `$EC13` branches directly to the shared per-frame path at `$EC34`.
	else:
		return _fail("Unsupported scenario-$%02X `$0516` phase `$%02X`." % [scenario_id, scenario_flag])
	_record(0xEC34)
	_set_x(int(_ram[0x0519]))
	_record(0xEC37)
	if not _expect_span("scenario_active", 0xEC37, [0xF0, 0x03, 0x4C, 0x5B, 0xED]): return false
	if int(_cpu["x"]) != 0:
		if not _expect_span("scenario_wait", 0xED5B, [0xCA, 0x8E, 0x19, 0x05]): return false
		_record(0xEC39) # The live BNE is not taken; execute the ROM JMP to `$ED5B`.
		_cpu["pc"] = 0xED5B
		return _execute_scenario_wait_worker()
	_record(0xEC3C)
	_set_a(0)
	for address in [0x0532, 0x0534, 0x0536, 0x0538, 0x0539]:
		var store_pc: int = 0xEC3E + (address - 0x0532) # checked below against the instruction stream
		match address:
			0x0532: store_pc = 0xEC3E
			0x0534: store_pc = 0xEC41
			0x0536: store_pc = 0xEC44
			0x0538: store_pc = 0xEC47
			0x0539: store_pc = 0xEC4A
		_write_ram(address, 0, store_pc)
	_record(0xEC4D)
	_set_a(0x08)
	_record(0xEC4F)
	_bit_ram(0x0516)
	_record(0xEC52)
	if (int(_cpu["p"]) & P_Z) == 0:
		# The exact dispatch profile above is cached before the source's per-frame clears.
		if not (scenario18_callback72_phase29_profile \
				or scenario38_callback34_phase29_return_profile or scenario35_callback3a_phase29_return_profile \
				or scenario1e_callback45_phase29_return_profile or scenario44_callback70_phase29_return_profile \
				or scenario1c_callback01_phase29_expired_profile \
				or scenario2e_callback36_map2f_phase29_expired_profile):
			return _fail("The live `$EC52->$EC75` branch is outside the pinned scenario-$18/$1C/$1E/$35/$38/$44 callback phase-$29 profiles.")
		return _execute_scenario38_callback34_phase29_return_tail()
	_record(0xEC54)
	_set_a(int(_ram[0x0516]))
	_record(0xEC57)
	_set_a(int(_cpu["a"]) & 0x50)
	_record(0xEC59)
	_compare_a(0x50)
	_record(0xEC5B)
	if (int(_cpu["p"]) & P_Z) != 0:
		var scenario1e_callback45_no_seed_profile := scenario_flag == 0x71 \
				and scenario_id == 0x1E and int(_ram[0x0519]) == 0 \
				and _ram.slice(0x0523, 0x052A) == PackedByteArray([0x07, 0x45, 0x06, 0x80, 0x3C, 0x90, 0xFF]) \
				and int(_ram[0x05CE]) == 0x80 \
				and _ram.slice(0x05D1, 0x05D3) == PackedByteArray([0x00, 0x00])
		var scenario44_callback70_no_seed_profile := scenario_flag == 0x51 \
				and scenario_id == 0x44 and int(_ram[0x0519]) == 0 \
				and _ram.slice(0x0523, 0x0525) == PackedByteArray([0x02, 0x70]) \
				and _ram.slice(0x0528, 0x052A) == PackedByteArray([0x5C, 0xFF]) \
				and int(_ram[0x05CE]) == 0xA0 and int(_ram[0x05CD]) == 0x80
		var scenario2e_callback36_post_return_profile := scenario2e_callback36_map2f_post_callback_profile
		var scenario38_callback34_no_seed_profile := _is_scenario38_callback34_map2d_profile(_ram)
		if (scenario_flag not in [0x51, 0x71] or scenario_id not in [0x35, 0x36]) \
				and not scenario18_callback72_post_return_profile \
				and not scenario1e_callback45_no_seed_profile \
				and not scenario44_callback70_no_seed_profile \
				and not scenario2e_callback36_post_return_profile \
				and not scenario1c_callback1f_expired_profile \
				and not scenario1c_callback63_phase71_expired_profile \
				and not scenario1c_callback01_phase71_expired_profile \
				and not scenario38_callback34_no_seed_profile:
			return _fail("The live mode takes the decoded `$EC8C` branch with an unsupported callback state.")
		_cpu["pc"] = 0xEC8C
		return _execute_scenario_post_callback_path()
	_record(0xEC5D)
	_bit_ram(0x0516)
	_record(0xEC60) # BVS branches to `$EC74` when the live mode's bit 6 is set.
	if (int(_cpu["p"]) & P_V) != 0:
		_record(0xEC74)
		_rts(0xEC74)
		return _expect_pc(0xEB9E)
	_record(0xEC62)
	_push(int(_cpu["a"]), 0xEC62, "PHA")
	_record(0xEC63)
	_set_a(int(_ram[0x0022]))
	_record(0xEC65)
	_set_a(0x10)
	_write_ram(0x0024, 0x10, 0xEC67)
	_record(0xEC69)
	_set_a(0x11)
	_write_ram(0x0025, 0x11, 0xEC6B)
	_jsr(0xEC6D, 0xCE2D)
	if not _execute_mapper_helper(0xEC70): return false
	_record(0xEC70)
	_set_a(_pop(0xEC70))
	_jsr(0xEC71, 0x8003)
	if not _execute_scenario_reader_and_callback_seed(): return false
	_record(0xEC74)
	_rts(0xEC74)
	return _expect_pc(0xEB9E)


func _execute_scenario38_callback34_phase29_return_tail() -> bool:
	var source: PackedByteArray = _sources.get("scenario_active_tail", PackedByteArray())
	if source.size() != 23 \
			or _sha256(source) != String(SOURCE_SPANS["scenario_active_tail"]["sha256"]) \
			or not _expect_span("scenario_active_tail", 0xEC75,
				[0x4D, 0x16, 0x05, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0xD2, 0x05,
					0xA9, 0x00, 0x85, 0x0D, 0x85, 0x0E, 0xA9, 0x00, 0x8D, 0x16, 0x05, 0x60]):
		return false
	_record(0xEC75)
	_set_a(int(_cpu["a"]) ^ int(_ram[0x0516]))
	_record(0xEC78)
	_write_ram(0x0516, int(_cpu["a"]), 0xEC78)
	_record(0xEC7B)
	_set_a(0)
	_record(0xEC7D)
	_write_ram(0x05D2, 0, 0xEC7D)
	_record(0xEC80)
	_set_a(0)
	_record(0xEC82)
	_write_ram(0x000D, 0, 0xEC82)
	_record(0xEC84)
	_write_ram(0x000E, 0, 0xEC84)
	_record(0xEC86)
	_set_a(0)
	_record(0xEC88)
	_write_ram(0x0516, 0, 0xEC88)
	_record(0xEC8B)
	_rts(0xEC8B)
	return _expect_pc(0xEB9E)


func _execute_scenario_wait_worker() -> bool:
	if not _expect_span("scenario_wait", 0xED5B, [
		0xCA, 0x8E, 0x19, 0x05, 0xE0, 0x28, 0xB0, 0x21,
		0xAD, 0x16, 0x05, 0x29, 0x20, 0xD0, 0x1A,
		0xAD, 0x16, 0x05, 0x09, 0x20, 0x8D, 0x16, 0x05,
		0x48, 0xA5, 0x22, 0xA9, 0x10, 0x85, 0x24,
		0xA9, 0x11, 0x85, 0x25, 0x20, 0x2D, 0xCE,
		0x68, 0x20, 0x03, 0x80, 0x60]):
		return false
	if int(_cpu["x"]) != int(_ram[0x0519]) or int(_cpu["x"]) == 0:
		return _fail("The `$ED5B` source wait branch requires the live nonzero `$0519` value in X.")
	_scenario_wait_worker_executed = true
	_record(0xED5B)
	_set_x(int(_cpu["x"]) - 1)
	_record(0xED5C)
	_write_ram(0x0519, int(_cpu["x"]), 0xED5C)
	_record(0xED5F)
	_compare_x(0x28)
	_record(0xED61)
	if (int(_cpu["p"]) & P_C) != 0:
		_cpu["pc"] = 0xED84
		return _return_from_scenario_wait()
	_record(0xED63)
	_set_a(int(_ram[0x0516]))
	_record(0xED66)
	_set_a(int(_cpu["a"]) & 0x20)
	_record(0xED68)
	if (int(_cpu["p"]) & P_Z) == 0:
		_cpu["pc"] = 0xED84
		return _return_from_scenario_wait()
	_record(0xED6A)
	_set_a(int(_ram[0x0516]))
	_record(0xED6D)
	_set_a(int(_cpu["a"]) | 0x20)
	_record(0xED6F)
	_write_ram(0x0516, int(_cpu["a"]), 0xED6F)
	_record(0xED72)
	_push(int(_cpu["a"]), 0xED72, "PHA")
	_record(0xED73)
	_set_a(int(_ram[0x0022]))
	_record(0xED75)
	_set_a(0x10)
	_record(0xED77)
	_write_ram(0x0024, 0x10, 0xED77)
	_record(0xED79)
	_set_a(0x11)
	_record(0xED7B)
	_write_ram(0x0025, 0x11, 0xED7B)
	_jsr(0xED7D, 0xCE2D)
	if not _execute_mapper_helper(0xED80): return false
	_record(0xED80)
	_set_a(_pop(0xED80))
	if int(_mapper["bank_low"]) != 0x10 or int(_mapper["bank_high"]) != 0x11:
		return _fail("The `$ED5B` worker did not map scenario banks `$10/$11`.")
	_jsr(0xED81, 0x8003)
	if int(_ram[0x0518]) in [0x18, 0x1C, 0x1E, 0x44]:
		if not _execute_scenario_reader_and_callback_seed(0xED84): return false
	elif int(_ram[0x0518]) == 0x2E:
		if not _is_scenario2e_callback36_map2f_terminal_profile(_ram):
			return _fail("The scenario-$2E `$ED5B` threshold did not produce the checked map-$2F root-terminal state.")
		if not _execute_scenario2e_root_terminal_worker(): return false
	elif int(_ram[0x0518]) == 0x36:
		if not _execute_scenario36_followup_event_worker(): return false
	elif int(_ram[0x0518]) == 0x35:
		if not _execute_scenario35_bank10_root_worker(): return false
	elif int(_ram[0x0518]) == 0x38:
		if not _execute_scenario38_root_terminal_worker(): return false
	else:
		return _fail("The `$ED5B` worker has no source-bounded bank-$10 continuation for scenario `$%02X`." % int(_ram[0x0518]))
	if int(_cpu["pc"]) == 0xED84:
		return _return_from_scenario_wait()
	return _expect_pc(0xEB9E)


func _return_from_scenario_wait() -> bool:
	if not _expect_span("scenario_wait", 0xED84, [0x60]): return false
	_record(0xED84)
	_rts(0xED84)
	return _expect_pc(0xEB9E)


func _execute_scenario36_followup_event_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var stream: PackedByteArray = _sources.get("scenario_36", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var f7_handler: PackedByteArray = _sources.get("f7_handler", PackedByteArray())
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if pointer == 0xB809:
		return _execute_scenario36_root_terminal_worker(reader, stream, event_reader)
	var is_f7_event := pointer == 0xB7FC
	var is_f9_followup := pointer == 0xB802
	var is_mirror_followup := pointer == 0xB7F3
	var event_start_offset := 30 if is_f9_followup else (24 if is_f7_event else (17 if is_mirror_followup else 8))
	var record_offset := 33 if is_f9_followup else (26 if is_f7_event else event_start_offset + 3)
	if reader.size() != 63 or stream.size() != 38 or event_reader.size() != 88 \
			or _sha256(stream) != "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f" \
			or int(_ram[0x0518]) != 0x36 \
			or (pointer != 0xB7EC and not is_mirror_followup and not is_f7_event and not is_f9_followup) \
			or int(_ram[0x003A]) != 0x06 \
			or (is_f7_event and (f7_handler != PackedByteArray([
				0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60]) \
				or _sha256(f7_handler) != "42f86ca3e1cfb75bedfacafd80b7ec80e34b52582be56d1457a3ce5d4b51f2da")) \
			or reader.slice(33, 63) != PackedByteArray([
				0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
				0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
				0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or stream.slice(8, 15) != PackedByteArray([0xF9, 0x02, 0x66, 0x20, 0x0C, 0x4E, 0x74]) \
			or stream.slice(15, 24) != PackedByteArray([0xFD, 0x00, 0xF9, 0x09, 0x2B, 0x32, 0x72, 0x66, 0xF0]) \
			or stream.slice(24, 38) != PackedByteArray([
				0xF7, 0x02, 0x32, 0x1F, 0x4C, 0xF0, 0xF9, 0x1D, 0x2C, 0x3E, 0x01, 0xE6, 0x75, 0xFB]):
		return _fail("The live scenario-$36 continuation is outside the verified `$B7EC`, `$B7F3`, `$B7FC`, and `$B802` source prefixes: pointer=$%04X scenario=$%02X mode=$%02X fields=$%02X/$%02X/$%02X/$%02X count=$%02X cursor=$%02X pc=$%04X." % [
			pointer, int(_ram[0x0518]), int(_ram[0x0516]), int(_ram[0x0523]),
			int(_ram[0x0524]), int(_ram[0x0528]), int(_ram[0x0529]),
			int(_ram[0x0533]), int(_ram[0x003A]), int(_cpu.get("pc", -1))])
	var parsed: Dictionary = SCENARIO_BYTECODE_READER.read_project_scenario(0x36,
		{"continuation_depth": 0})
	var fd_token: Dictionary = {}
	var f9_token: Dictionary = {}
	var f7_token: Dictionary = {}
	var record_token: Dictionary = {}
	for token_variant in parsed.get("tokens", []):
		if not token_variant is Dictionary:
			continue
		var token: Dictionary = token_variant
		if int(token.get("byte_offset", -1)) == 15 and int(token.get("opcode", -1)) == 0xFD:
			fd_token = token
		elif int(token.get("byte_offset", -1)) == event_start_offset and int(token.get("opcode", -1)) == 0xF7:
			f7_token = token
		elif int(token.get("byte_offset", -1)) == event_start_offset and int(token.get("opcode", -1)) == 0xF9:
			f9_token = token
		elif int(token.get("byte_offset", -1)) == record_offset and String(token.get("kind", "")) == "event_record":
			record_token = token
	var raw_record_variant: Variant = record_token.get("raw_bytes", PackedByteArray())
	var raw_record: PackedByteArray = raw_record_variant if raw_record_variant is PackedByteArray else PackedByteArray()
	var assignments_variant: Variant = record_token.get("ram_assignments", {})
	var assignments: Dictionary = assignments_variant if assignments_variant is Dictionary else {}
	var expected_word := 0x2B09 if is_mirror_followup else (0x2C1D if is_f9_followup else 0x6602)
	var expected_record := PackedByteArray([0x32, 0x1F, 0x4C, 0xF0]) if is_f7_event \
		else PackedByteArray([0x32, 0x72, 0x66, 0xF0]) if is_mirror_followup \
		else PackedByteArray([0x3E, 0x01, 0xE6, 0x75]) if is_f9_followup \
		else PackedByteArray([0x20, 0x0C, 0x4E, 0x74])
	var expected_assignments: Dictionary = {"$0523": 0x32, "$0524": 0x1F, "$0528": 0x4C, "$0529": 0xFF} if is_f7_event \
		else {"$0523": 0x32, "$0524": 0x72, "$0528": 0x66, "$0529": 0xFF} if is_mirror_followup \
		else {"$0523": 0x3E, "$0524": 0x01, "$0528": 0xE6, "$0529": 0x75} if is_f9_followup \
		else {"$0523": 0x20, "$0524": 0x0C, "$0528": 0x4E, "$0529": 0x74}
	if not bool(parsed.get("context_required", false)) \
			or int(parsed.get("terminal_status", -1)) != SCENARIO_BYTECODE_READER.ParseStatus.SOURCE_TERMINATED \
			or raw_record != expected_record:
		return _fail("The ROM parser did not resolve the live scenario-$36 F9/event record from its source bytes.")
	if is_f7_event:
		var f7_writes_variant: Variant = f7_token.get("ram_write", {})
		var f7_writes: Dictionary = f7_writes_variant if f7_writes_variant is Dictionary else {}
		if int(f7_token.get("handler_cpu_address", -1)) != 0x87F5 \
				or int(f7_token.get("operand", -1)) != 0x02 \
				or int(f7_writes.get("$052B", -1)) != 0x02 \
				or f7_token.get("handler_bytes", []) != [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60]:
			return _fail("Scenario-$36 `$F7 02` did not resolve to the source `$87F5` write of `$052B=$02`.")
	elif int(f9_token.get("operand_word_little_endian", -1)) != expected_word:
		return _fail("The ROM parser did not resolve the live scenario-$36 F9 operand from its source bytes.")
	for address_variant in expected_assignments:
		var address := String(address_variant)
		if int(assignments.get(address, -1)) != int(expected_assignments[address]):
			return _fail("Scenario-$36 event field %s did not match the decoded source record." % address)
	var fd00_result: Dictionary = {}
	if is_mirror_followup:
		if int(fd_token.get("operand", -1)) != 0x00 \
				or String(fd_token.get("status", "")) != "context_required" \
				or int(fd_token.get("handler_target_cpu_address", -1)) != 0x8877:
			return _fail("Scenario-$36 `$FD 00` parser token does not select ROM handler `$8877`.")
		var fd00_resolver: RefCounted = SCENARIO36_FD00_RESOLVER.new()
		if not fd00_resolver.configure():
			return _fail("Scenario-$36 `$FD 00` source setup failed: " + fd00_resolver.last_error)
		fd00_result = fd00_resolver.execute(_ram)
		if not bool(fd00_result.get("ok", false)):
			return _fail("Scenario-$36 `$FD 00` execution stopped: " + String(fd00_result.get("error", "unknown source state")))

	# `$8003->$8021` starts a fresh bank-$10 reader pass at the saved scenario
	# pointer. `$B7FC` resolves `$F7 02`; the next pass at `$B802` decodes
	# `$F9 $1D $2C` and the `$3E $01 $E6 $75` record. `$B7F3` has `$FD 00`.
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034], [0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), 0, int(address_pc[1]))

	# `$803F` consumes the first opcode. ROM `$87F5` handles `$F7` by advancing
	# the cursor and copying its operand into `$052B`; F9/FD paths use `$8809`.
	_record(0x803F)
	_set_y(0)
	_record(0x8041)
	_write_ram(0x003A, 1, 0x8041)
	if is_f7_event:
		for pc in [0x80A9, 0xC509, 0xCB99, 0x87F5, 0x87F7, 0x87F9, 0x87FB, 0x87FE]:
			_record(pc)
		_set_y(1)
		_write_ram(0x003A, 2, 0x87F7)
		_set_a(int(stream[event_start_offset + 1]))
		_write_ram(0x052B, int(_cpu["a"]), 0x87FB)
		_record(0x803F)
		_set_y(2)
		_write_ram(0x003A, 3, 0x8041)
	elif is_mirror_followup:
		_record(0x885D)
		_write_ram(0x003A, 2, 0x8861)
		_write_ram(0x052A, int(fd00_result["mirror_flag"]), 0x8869)
		_record(0x803F)
		_set_y(2)
		_record(0x8041)
		_write_ram(0x003A, 3, 0x8041)
		_record(0x8809)
		_write_ram(0x0530, int(stream[event_start_offset + 1]), 0x8810)
		_write_ram(0x0531, int(stream[event_start_offset + 2]), 0x8816)
		_write_ram(0x003A, 5, 0x8819)
		_record(0x803F)
		_set_y(5)
		_record(0x8041)
		_write_ram(0x003A, 6, 0x8041)
	else:
		_record(0x8809)
		_write_ram(0x0530, int(stream[event_start_offset + 1]), 0x8810)
		_write_ram(0x0531, int(stream[event_start_offset + 2]), 0x8816)
		_write_ram(0x003A, 3, 0x8819)
		_record(0x803F)
		_set_y(3)
		_record(0x8041)
		_write_ram(0x003A, 4, 0x8041)
	for pc in [0x804F, 0x8052, 0x8059, 0x805C, 0x8069, 0x806C, 0x8079, 0x807C, 0x8089, 0x808C]:
		_record(pc)
	_write_ram(0x0523, int(assignments["$0523"]), 0x804F)
	_write_ram(0x0516, (int(_ram[0x0516]) | 0x40) & 0xEF, 0x8059)
	_write_ram(0x0524, int(assignments["$0524"]), 0x8069)
	_write_ram(0x0528, int(assignments["$0528"]), 0x8079)
	_write_ram(0x0529, int(assignments["$0529"]), 0x8089)
	var cursor_after_record := 6 if is_f7_event else (9 if is_mirror_followup else 7)
	_write_ram(0x003A, cursor_after_record, 0x808C)
	var next_pointer := pointer + cursor_after_record
	var pointer_low_sum := int(_ram[0x005D]) + cursor_after_record
	var pointer_carry := pointer_low_sum > 0xFF
	_write_ram(0x005D, next_pointer & 0xFF, 0x8091)
	if pointer_carry:
		# ROM `$8093/$8095` increments `$005E` when `$8091`'s low-byte add carries.
		_record(0x8093)
		_record(0x8095)
		_write_ram(0x005E, (int(_ram[0x005E]) + 1) & 0xFF, 0x8095)
	if int(_ram[0x005E]) != ((next_pointer >> 8) & 0xFF):
		return _fail("Scenario-$36 source-pointer high byte differs after the ROM `$8091->$8095` carry path.")
	_record(0x8091)
	_set_x(0x15)
	_set_a(0xF0)
	_write_ram(0x0016, 0xF0, 0x809B)
	_set_a(0x0B)
	_write_ram(0x0017, 0x0B, 0x809F)
	_set_a(0x80)
	_cpu["y"] = 0x08
	_jsr(0x80A5, 0xC50F)
	_record(0xC50F)
	_record(0xCAE7)
	_push(int(_cpu["a"]), 0xCAE7, "PHA")
	_set_a(int(_cpu["y"]))
	_cpu["y"] = int(_ram[(0x0001 + int(_cpu["x"])) & 0x07FF])
	_write_ram(0x0100 | ((0x01 + int(_cpu["y"])) & 0xFF), int(_cpu["a"]), 0xCAEB)
	_set_a(_pop(0xCAEE))
	_write_ram(0x0100 | ((0x02 + int(_cpu["y"])) & 0xFF), int(_cpu["a"]), 0xCAEF)
	_set_a(0xFF)
	_write_ram(0x0015, 0xFF, 0xCAF4)
	_record(0xCAF6)
	_rts(0xCAF6)
	if not _expect_pc(0x80A8): return false
	_record(0x80A8)
	_rts(0x80A8)
	_scenario_seed_request = {
		"scenario_id": 0x36,
		"source_record_cpu_address": 0xB7E4 + record_offset,
		"source_record_file_offset": 0x0237F4 + record_offset,
		"source_record_bytes": raw_record.duplicate(),
		"event_selector_ram_0524": int(assignments["$0524"]),
		"wait_value_ram_0523": int(assignments["$0523"]),
		"actor_selector_ram_0528": int(assignments["$0528"]),
		"actor_parameter_ram_0529": int(assignments["$0529"]),
		"setup_cpu_address": 0x8097,
		"task_create_cpu_address": 0xC50F,
		"task_seed_cpu_address": 0xCAE7,
		"task_slot_base": 0x15,
		"saved_stack_pointer": 0xF0,
		"bank_base": 0x0B,
		"callback_entry_cpu_address": 0x814C,
	}
	_scenario_runtime_events = []
	if is_f7_event:
		_scenario_runtime_events.append({"kind": "opcode", "source_pointer": pointer,
			"source_bytes": PackedByteArray([0xF7, 0x02]),
			"ram_writes": {"$052B": 0x02}, "handler_cpu_address": 0x87F5,
			"handler_source_file": "bank10_f7_handler_87f5_87ff.bin"})
	if is_mirror_followup:
		_scenario_runtime_events.append({"kind": "fd_operand", "source_pointer": pointer,
			"source_bytes": PackedByteArray([0xFD, 0x00]), "resolver": fd00_result.duplicate(true)})
	var f9_operand := PackedByteArray([0xF9, int(stream[event_start_offset + 1]), int(stream[event_start_offset + 2])])
	_scenario_runtime_events.append({"kind": "f9_operand", "source_pointer": 0xB7E4 + event_start_offset,
		"source_bytes": f9_operand, "ram_writes": {"$0530": int(stream[event_start_offset + 1]),
			"$0531": int(stream[event_start_offset + 2])}})
	_scenario_runtime_events.append({"kind": "event_record", "source_pointer": 0xB7E4 + record_offset,
		"source_bytes": raw_record.duplicate(), "seed_contract": _scenario_seed_request.duplicate(true)})
	return _expect_pc(0xED84)


## Executes scenario-$36's ROM `$FB` root terminator at `$B809` after the live
## `$E6/$75` event has advanced the scenario cursor to the end of its stream.
## Executes the live one-tick scenario-$38 wait branch. The callback-$34/map-$2D
## work has already advanced the ROM stream to `$B7CC`; this worker reads its
## final `$FB` and returns to `$EB9E` without reseeding callback `$34`.
func _execute_scenario38_root_terminal_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var stream: PackedByteArray = _sources.get("scenario_38", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	var expected_live_fields := PackedByteArray([0x01, 0x34, 0x02, 0x00, 0x02, 0x00, 0xFF, 0x40])
	var expected_map_signature := PackedByteArray([
		0x40, 0xA0, 0x00, 0x02, 0x01, 0x2D, 0xA0, 0x80, 0x00, 0x02, 0x00, 0x00])
	if reader.size() != 63 or stream != PackedByteArray([0xF7, 0x17, 0x01, 0x34, 0x00, 0xF0, 0xFB]) \
			or _sha256(stream) != "63ad2f03483843a538c92e33da4917356fce555fb8b69875b042be85fa77bc76" \
			or event_reader.size() != 88 or int(_ram[0x0516]) != 0x21 \
			or int(_ram[0x0517]) != 0x40 or int(_ram[0x0518]) != 0x38 \
			or int(_ram[0x0519]) != 0 or int(_ram[0x0522]) != 0 \
			or _ram.slice(0x0523, 0x052B) != expected_live_fields \
			or _ram.slice(0x05C7, 0x05D3) != expected_map_signature \
			or int(_ram[0x003A]) != 0x06 or pointer != 0xB7CC \
			or int(_ram[0x0079]) != 0xE9 or int(_ram[0x007A]) != 0xAF \
			or int(_ram[0x052B]) != 0x17 or int(_ram[0x0532]) != 0x17 \
			or int(_ram[0x0533]) != 0x04 or int(_ram[0x0539]) != 0 \
			or int(_cpu.get("pc", -1)) != 0x8003:
		return _fail("Scenario-$38 terminal worker requires the exact `$ED5B->$8003` callback-$34/map-$2D profile at `$B7CC`.")
	var parsed: Dictionary = SCENARIO_BYTECODE_READER.read_project_scenario(0x38,
		{"continuation_depth": 0})
	var tokens_variant: Variant = parsed.get("tokens", [])
	if not tokens_variant is Array \
			or int(parsed.get("terminal_status", -1)) != SCENARIO_BYTECODE_READER.ParseStatus.SOURCE_TERMINATED \
			or bool(parsed.get("context_required", true)):
		return _fail("The supplied-ROM scenario-$38 parser did not resolve its root `$FB` terminator.")
	var tokens: Array = tokens_variant
	var event_record: Dictionary = {}
	var terminal: Dictionary = {}
	for token_variant in tokens:
		if not token_variant is Dictionary:
			return _fail("Scenario-$38 terminal parse returned a non-dictionary token.")
		var token: Dictionary = token_variant
		if String(token.get("kind", "")) == "event_record":
			event_record = token
		elif String(token.get("kind", "")) == "control_flow" and int(token.get("opcode", -1)) == 0xFB:
			terminal = token
	var record_bytes: Variant = event_record.get("raw_bytes", PackedByteArray())
	if int(parsed.get("scenario_id", -1)) != 0x38 or tokens.size() != 3 \
			or int(event_record.get("byte_offset", -1)) != 2 \
			or not record_bytes is PackedByteArray \
			or record_bytes != PackedByteArray([0x01, 0x34, 0x00, 0xF0]) \
			or int(terminal.get("byte_offset", -1)) != 6 \
			or not bool(terminal.get("source_span_validated", false)) \
			or int(terminal.get("continuation_depth", -1)) != 0:
		return _fail("Scenario-$38 source tokens do not prove callback `$34` then root `$FB` at offset `$06`.")
	if reader.size() != 63 or reader.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("The checked bank-$10 reader/event-reader spans changed before scenario-$38 `$FB` dispatch.")
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	var live_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if int(_cpu["y"]) != 0 or live_pointer + int(_cpu["y"]) != 0xB7CC:
		return _fail("The ROM `$803F` reader no longer addresses the live scenario-$38 terminal at `$B7CC`.")
	_set_a(int(stream[6]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$38 `$B7CC` did not enter the ROM `$F0-$FF` opcode dispatch.")
	_scenario_runtime_events = [{"kind": "root_terminator", "source_pointer": 0xB7CC,
		"source_bytes": PackedByteArray([0xFB]),
		"result": {"status": "root_scenario_terminated", "scenario_id": 0x38,
			"source_byte_offset": 6, "terminal_handler_cpu_address": 0x80CF,
			"source_rom_sha256": ROM_SHA256}}]
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	return _execute_scenario_opcode_dispatch()


## Executes the live scenario-$2E map-$2F root `$FB` at `$B753`. The parsed
## source stream, current cursor, and mapped reader bytes must all agree before
## the common ROM `$8837->$80CF` handler is allowed to run.
func _execute_scenario2e_root_terminal_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var stream := FileAccess.get_file_as_bytes(SCENARIO_2E_ROOT + "scenario_2E.bin")
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if reader.size() != 63 or event_reader.size() != 88 \
			or stream != PackedByteArray([0xF5, 0x78, 0x36, 0x8B, 0x6D, 0xFB]) \
			or _sha256(stream) != SCENARIO_2E_STREAM_SHA256 \
			or int(_ram[0x0518]) != 0x2E or int(_ram[0x0522]) != 0 \
			or pointer != 0xB753 or int(_cpu.get("pc", -1)) != 0x8003 \
			or not _is_scenario2e_callback36_map2f_terminal_profile(_ram):
		return _fail("Scenario-$2E root terminal requires the exact phase-$21 map-$2F callback state and checked `$B753` stream.")
	var parsed: Dictionary = SCENARIO_BYTECODE_READER.read_project_scenario(0x2E,
		{"continuation_depth": 0})
	var tokens_variant: Variant = parsed.get("tokens", [])
	if not tokens_variant is Array \
			or int(parsed.get("scenario_id", -1)) != 0x2E \
			or int(parsed.get("terminal_status", -1)) != SCENARIO_BYTECODE_READER.ParseStatus.SOURCE_TERMINATED \
			or bool(parsed.get("context_required", true)):
		return _fail("The supplied-ROM scenario-$2E reader did not resolve its source stream to the root `$FB`.")
	var event_record: Dictionary = {}
	var terminal: Dictionary = {}
	for token_variant in tokens_variant:
		if not token_variant is Dictionary:
			return _fail("Scenario-$2E parser returned a malformed source token.")
		var token: Dictionary = token_variant
		if String(token.get("kind", "")) == "event_record":
			event_record = token
		elif String(token.get("kind", "")) == "control_flow" and int(token.get("opcode", -1)) == 0xFB:
			terminal = token
	var record_bytes: Variant = event_record.get("raw_bytes", PackedByteArray())
	if int(event_record.get("byte_offset", -1)) != 1 \
			or not record_bytes is PackedByteArray \
			or record_bytes != PackedByteArray([0x78, 0x36, 0x8B, 0x6D]) \
			or int(terminal.get("byte_offset", -1)) != 5 \
			or not bool(terminal.get("source_span_validated", false)) \
			or int(terminal.get("continuation_depth", -1)) != 0:
		return _fail("Scenario-$2E parser did not prove callback `$36` followed by root `$FB` at stream offset `$05`.")
	if reader.slice(33, 63) != PackedByteArray([
			0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
			0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
			0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("The checked bank-$10 reader/event-reader spans changed before scenario-$2E `$FB` dispatch.")
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	var live_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if int(_cpu["y"]) != 0 or live_pointer != 0xB753:
		return _fail("The ROM `$803F` reader did not address scenario-$2E's live `$B753` terminal byte.")
	_set_a(int(stream[5]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$2E `$B753` did not enter the ROM `$F0-$FF` opcode dispatch.")
	_scenario_runtime_events = [{"kind": "root_terminator", "source_pointer": 0xB753,
		"source_bytes": PackedByteArray([0xFB]),
		"result": {"status": "root_scenario_terminated", "scenario_id": 0x2E,
			"source_byte_offset": 5, "terminal_handler_cpu_address": 0x80CF,
			"source_rom_sha256": ROM_SHA256}}]
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	return _execute_scenario_opcode_dispatch()


func _execute_scenario36_root_terminal_worker(reader: PackedByteArray,
		stream: PackedByteArray, event_reader: PackedByteArray) -> bool:
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if reader.size() != 63 or stream.size() != 38 or event_reader.size() != 88 \
			or _sha256(stream) != "948f05adfcd95e7fe76759534449f31f4194aed3521389934ee793e8f22e367f" \
			or int(_ram[0x0518]) != 0x36 or int(_ram[0x0522]) != 0 \
			or pointer != 0xB809 or int(stream[37]) != 0xFB \
			or int(_cpu.get("pc", -1)) != 0x8003:
		return _fail("Scenario-$36 `$FB` root at `$B809` lacks its checked source stream, empty root depth, or live `$8003` entry.")
	var parsed: Dictionary = SCENARIO_BYTECODE_READER.read_project_scenario(0x36,
		{"continuation_depth": 0})
	var tokens_variant: Variant = parsed.get("tokens", [])
	if not tokens_variant is Array \
			or int(parsed.get("terminal_status", -1)) != SCENARIO_BYTECODE_READER.ParseStatus.SOURCE_TERMINATED:
		return _fail("The ROM bytecode reader did not identify scenario-$36 `$B809` as the checked root terminator.")
	var tokens: Array = tokens_variant
	var terminal: Dictionary = tokens[tokens.size() - 1] if not tokens.is_empty() else {}
	if int(terminal.get("opcode", -1)) != 0xFB or int(terminal.get("byte_offset", -1)) != 37:
		return _fail("The source `$FB` terminator is not the final byte at scenario-$36 offset `$25`.")

	# `$8003->$8021` starts the next bank-$10 reader pass at the saved `$B809`.
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034], [0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	if reader.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("The ROM reader/event-reader bytes changed before scenario-$36 `$FB` dispatch.")
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, int(_ram[0x003A]) + 1, 0x8041)
	_record(0x8043)
	var live_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if int(_cpu["y"]) != 0 or live_pointer != 0xB809:
		return _fail("The ROM `$803F` reader did not address the live `$B809` `$FB` byte.")
	_set_a(int(stream[37]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$36 `$B809` did not enter the ROM `$F0–$FF` opcode dispatch.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	return _execute_scenario_opcode_dispatch()


## Executes the live `$AF58` `$FB` cursor at the end of scenario `$18`'s
## manifest-checked `$AF51` child stream, using the same bank-$10 reader path.
func _execute_scenario18_branch_terminal_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var branch_path := PASS_SCENARIO_18_ROOT + "scenario_18_branch_af51.bin"
	var branch: PackedByteArray = FileAccess.get_file_as_bytes(branch_path)
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if reader.size() != 63 or event_reader.size() != 88 \
			or branch != PackedByteArray([0xF9, 0x05, 0x2B, 0x3C, 0x72, 0x66, 0x47, 0xFB]) \
			or _sha256(branch) != PASS_SCENARIO_18_AF51_SHA256 \
			or int(_ram[0x0518]) != 0x18 or int(_ram[0x0522]) != 0 \
			or pointer != 0xAF58 or int(_cpu.get("pc", -1)) != 0x8003:
		return _fail("Scenario-$18 `$FB` terminal worker requires the live `$ED5B->$8003` `$AF58` cursor and its checked `$AF51` source.")
	var parser: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = parser.begin_from_live_scenario_pointer(0x18, pointer,
		{"ram_0522": int(_ram[0x0522])})
	if not bool(started.get("ok", false)) \
			or int(started.get("source_root_pointer_cpu", -1)) != 0xAF51 \
			or int(started.get("source_byte_index", -1)) != 7:
		return _fail("Bank-$10 parser did not bind scenario-$18 `$AF58` to the terminal cursor of `$AF51`: %s" % str(started))
	var terminal: Dictionary = parser.advance_one()
	if not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "root_scenario_terminated" \
			or int(terminal.get("source_byte_offset", -1)) != 7 \
			or int(terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF:
		return _fail("Scenario-$18 live `$AF58` cursor did not decode its final ROM `$FB` to `$80CF`.")
	if reader.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("Scenario-$18 terminal path no longer matches the checked bank-$10 source reader bytes.")
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	if int(_cpu["y"]) != 0 or pointer + int(_cpu["y"]) != 0xAF58:
		return _fail("The ROM `$803F` reader did not address scenario-$18 `$AF58` `$FB`.")
	_set_a(int(branch[7]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$18 `$AF58` did not enter the ROM `$F0–$FF` opcode dispatch.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	_scenario_runtime_events = [{"kind": "root_terminator", "source_pointer": pointer,
		"source_bytes": PackedByteArray([0xFB]), "result": terminal.duplicate(true),
		"branch_sha256": PASS_SCENARIO_18_AF51_SHA256}]
	return _execute_scenario_opcode_dispatch()


## Resume scenario-$1C after the actor-$78 wait. The event reader advanced the
## parent `$B49E` pointer by seven bytes at `$8091`, so `$B4A5` is the next
## source byte. `$8021` resets the reused live `$003A` scratch before the reader
## consumes this standalone `$FB`; its pre-entry value is not treated as a
## bytecode cursor.
func _execute_scenario1c_b49e_root_terminal_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var branch := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_root_target_B49E_B4A6.bin")
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if reader.size() != 63 or event_reader.size() != 88 \
			or branch != PackedByteArray([0xF9, 0x1D, 0x2C, 0x3C, 0x01, 0x78, 0x58, 0xFB]) \
			or _sha256(branch) != PASS_SCENARIO_1C_B49E_SHA256 \
			or int(_ram[0x0516]) != 0x21 or int(_ram[0x0517]) != 0x40 \
			or int(_ram[0x0518]) != 0x1C or int(_ram[0x0519]) != 0x27 \
			or int(_ram[0x0522]) != 0 or pointer != 0xB4A5 \
			or _ram.slice(0x0523, 0x052B) != PackedByteArray([
				0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			or int(_cpu.get("pc", -1)) != 0x8003:
		return _fail("Scenario-$1C `$B4A5` terminal requires the live `$ED5B->$8003` actor-$78 post-wait state and checked `$B49E` parent bytes.")
	if pointer != 0xB49E + 7 or branch[7] != 0xFB:
		return _fail("Scenario-$1C live `$B4A5` is not the exact next byte after the consumed `$B49E` event record.")
	var parser: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = parser.begin_from_live_scenario_pointer(0x1C, 0xB49E,
		{"continuation_depth": 0})
	if not bool(started.get("ok", false)) \
			or String(started.get("status", "")) != "scenario1c_b49e_f2_branch_admitted":
		return _fail("Scenario-$1C parent stream failed admission before resolving live `$B4A5`: %s" % str(started))
	var f9: Dictionary = parser.advance_one()
	var record: Dictionary = parser.advance_one()
	var terminal: Dictionary = parser.advance_one()
	var record_seed: Dictionary = record.get("seed_contract_fields", {})
	if not bool(f9.get("ok", false)) or int(f9.get("source_byte_index_after", -1)) != 3 \
			or not bool(record.get("ok", false)) \
			or String(record.get("status", "")) != "callback_task_seed_requested" \
			or int(record.get("source_byte_index_after", -1)) != 7 \
			or record_seed.get("source_record_bytes", PackedByteArray()) != PackedByteArray([0x3C, 0x01, 0x78, 0x58]) \
			or not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "root_scenario_terminated" \
			or int(terminal.get("source_byte_offset", -1)) != 7 \
			or int(terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF:
		return _fail("Scenario-$1C parent F9/record path did not resolve its ROM `$B4A5` `$FB`: %s / %s / %s" % [str(f9), str(record), str(terminal)])
	if reader.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("Scenario-$1C root terminal no longer matches the checked bank-$10 reader bytes.")
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	if int(_cpu["y"]) != 0 or pointer + int(_cpu["y"]) != 0xB4A5:
		return _fail("Scenario-$1C `$803F` did not read the live `$B4A5` terminal byte after the ROM cursor reset.")
	_set_a(int(branch[7]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$1C `$B4A5` did not enter the ROM `$F0-$FF` opcode dispatch.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	_scenario_runtime_events = [
		{"kind": "root_terminator", "source_pointer": pointer,
			"source_bytes": PackedByteArray([0xFB]), "result": terminal.duplicate(true),
			"parent_pointer": 0xB49E, "parent_offset": 7,
			"parent_sha256": PASS_SCENARIO_1C_B49E_SHA256}]
	return _execute_scenario_opcode_dispatch()


## At the exact scenario-$1C callback-$63 wait expiry, the live bank-$10
## pointer is `$B4BD`, the terminal `$FB` byte of the selected `$B4B6` branch.
## The wait routine owns the countdown; this parser call only validates and
## consumes the source terminator. It deliberately does not model the outer
## scenario return.
func _consume_scenario1c_callback63_fb_terminal() -> bool:
	var branch: PackedByteArray = _sources.get("scenario_1C_branch_B4B6", PackedByteArray())
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if not _is_scenario1c_callback63_phase71_expired_profile(_ram) \
			or int(_ram[0x0519]) != 0 or pointer != 0xB4BD \
			or branch != PackedByteArray([0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB]) \
			or _sha256(branch) != PASS_SCENARIO_1C_B4B6_SHA256:
		return _fail("Scenario-$1C callback-$63 terminal requires the live `$B4BD` cursor after the source `$ED5B` wait expired.")
	var parser: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = parser.begin_from_live_scenario_pointer(0x1C, 0xB4BD,
		{"continuation_depth": 0, "ram_0518": int(_ram[0x0518]),
			"ram_0524": int(_ram[0x0524])})
	if not bool(started.get("ok", false)) \
			or String(started.get("status", "")) != "scenario1c_b4bd_fb_cursor_admitted" \
			or int(started.get("source_pointer_cpu", -1)) != 0xB4BD \
			or int(started.get("source_byte_index", -1)) != 7 \
			or String(started.get("source_span_sha256", "")) != PASS_SCENARIO_1C_B4B6_SHA256:
		return _fail("Scenario-$1C callback-$63 parser did not admit the checked `$B4BD` terminal cursor: %s" % str(started))
	var terminal: Dictionary = parser.advance_one()
	if not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "root_scenario_terminated" \
			or int(terminal.get("source_byte_offset", -1)) != 7 \
			or int(terminal.get("source_byte_index_after", -1)) != 8 \
			or int(terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF \
			or bool(terminal.get("outer_task_return_modeled", true)):
		return _fail("Scenario-$1C callback-$63 `$B4BD` did not resolve to the checked root `$FB`: %s" % str(terminal))
	_scenario_runtime_events.append({"kind": "root_terminator", "source_pointer": 0xB4BD,
		"source_bytes": PackedByteArray([0xFB]), "result": terminal.duplicate(true),
		"parent_pointer": 0xB4B6, "parent_offset": 7,
		"parent_sha256": PASS_SCENARIO_1C_B4B6_SHA256})
	return true


## Executes scenario-$44's final `$FB` at its live post-record cursor `$B7D9`.
func _execute_scenario44_root_terminal_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var stream: PackedByteArray = _sources.get("scenario_44", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if reader.size() != 63 or stream != PackedByteArray([0x02, 0x70, 0x5C, 0xF0, 0xFB]) \
			or event_reader.size() != 88 or int(_ram[0x0518]) != 0x44 \
			or int(_ram[0x0522]) != 0 or pointer != 0xB7D9 \
			or int(_cpu.get("pc", -1)) != 0x8003:
		return _fail("Scenario-$44 `$FB` root lacks its checked stream, zero root depth, or live `$8003/$B7D9` continuation.")
	var parser: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = parser.begin_from_live_scenario_pointer(0x44, pointer)
	if not bool(started.get("ok", false)) or int(started.get("source_root_pointer_cpu", -1)) != 0xB7D5:
		return _fail("Bank-$10 parser did not bind live cursor `$B7D9` to the manifest ROM root `$B7D5`.")
	var terminal: Dictionary = parser.advance_one()
	if not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "root_scenario_terminated" \
			or int(terminal.get("source_byte_offset", -1)) != 4 \
			or int(terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF:
		return _fail("Scenario-$44 live cursor did not decode its final ROM `$FB` to `$80CF`.")
	if reader.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("Scenario-$44 root termination no longer matches checked bank-$10 reader bytes.")
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	if int(_cpu["y"]) != 0 or pointer + int(_cpu["y"]) != 0xB7D9:
		return _fail("The ROM `$803F` reader did not address the live `$B7D9` `$FB` byte.")
	_set_a(int(stream[4]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$44 `$B7D9` did not enter the ROM `$F0-$FF` opcode dispatch.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	_scenario_runtime_events = [{"kind": "root_terminator", "source_pointer": pointer,
		"source_bytes": PackedByteArray([0xFB]), "result": terminal.duplicate(true)}]
	return _execute_scenario_opcode_dispatch()


## Executes scenario-$1E's terminal `$FB` at its live post-record cursor `$B7E3`.
func _execute_scenario1e_root_terminal_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var stream: PackedByteArray = _sources.get("scenario_1E", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	var pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if reader.size() != 63 or stream != PackedByteArray([
		0xFD, 0x02, 0xF6, 0xF7, 0x01, 0x07, 0x45, 0x90, 0xF0, 0xFB]) \
			or event_reader.size() != 88 or int(_ram[0x0518]) != 0x1E \
			or int(_ram[0x0522]) != 0 or pointer != 0xB7E3 \
			or int(_cpu.get("pc", -1)) != 0x8003:
		return _fail("Scenario-$1E `$FB` root lacks its checked stream, zero root depth, or live `$8003`/$B7E3 continuation.")
	var parser: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = parser.begin_from_live_scenario_pointer(0x1E, pointer,
		{"ram_05FB": int(_ram[0x05FB])})
	if not bool(started.get("ok", false)) \
			or int(started.get("source_root_pointer_cpu", -1)) != 0xB7DA:
		return _fail("Bank-$10 parser did not bind live cursor `$B7E3` to the manifest ROM root `$B7DA`.")
	var terminal: Dictionary = parser.advance_one()
	if not bool(terminal.get("ok", false)) \
			or String(terminal.get("status", "")) != "root_scenario_terminated" \
			or int(terminal.get("source_byte_offset", -1)) != 9 \
			or int(terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF:
		return _fail("Scenario-$1E live cursor did not decode its final ROM `$FB` to `$80CF`.")
	if reader.slice(33, 63) != PackedByteArray([
		0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
		0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
		0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or event_reader.slice(0, 16) != PackedByteArray([
			0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
			0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("Scenario-$1E root termination no longer matches checked bank-$10 reader bytes.")
	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), int(_cpu["a"]), int(address_pc[1]))
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	if int(_cpu["y"]) != 0 or pointer + int(_cpu["y"]) != 0xB7E3:
		return _fail("The ROM `$803F` reader did not address scenario-$1E `$FB` at `$B7E3`.")
	_set_a(int(stream[9]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("Scenario-$1E `$B7E3` did not select the ROM `$F0-$FF` opcode dispatch.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	_scenario_runtime_events = [{"kind": "root_terminator", "source_pointer": pointer,
		"source_bytes": PackedByteArray([0xFB]), "result": terminal.duplicate(true)}]
	return _execute_scenario_opcode_dispatch()


func _execute_scenario35_bank10_root_worker() -> bool:
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var stream: PackedByteArray = _sources.get("scenario_35", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	if reader.size() != 63 or stream.size() != 8 or event_reader.size() != 88 \
			or int(_mapper["bank_low"]) != 0x10 or int(_mapper["bank_high"]) != 0x11:
		return _fail("Scenario-$35 bank-$10 worker lacks its verified reader, stream, event reader, or mapper context.")
	if reader.slice(3, 6) != PackedByteArray([0x4C, 0x21, 0x80]) \
			or reader.slice(33, 63) != PackedByteArray([
				0xAD, 0x17, 0x05, 0x8D, 0x2A, 0x05, 0xAD, 0x16, 0x05, 0x29,
				0xFB, 0x8D, 0x16, 0x05, 0xA9, 0x00, 0x8D, 0x2B, 0x05, 0x8D,
				0x2D, 0x05, 0x8D, 0x2C, 0x05, 0x8D, 0x30, 0x05, 0x85, 0x3A]) \
			or stream != PackedByteArray([0xF9, 0xEB, 0x44, 0x02, 0x3A, 0x8F, 0x73, 0xFB]):
		return _fail("Bank-$10 reader setup or scenario-$35 root stream bytes differ from their checked ROM source.")
	var parser: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = parser.begin_from_source_callsite(0xDAD8)
	if not bool(started.get("ok", false)):
		return _fail("The ROM scenario parser could not validate the live bank-$10 worker: %s" % str(started))
	var token_f9: Dictionary = parser.advance_one()
	var token_record: Dictionary = parser.advance_one()
	var token_fb: Dictionary = parser.advance_one()
	if not bool(token_f9.get("ok", false)) or int(token_f9.get("opcode", -1)) != 0xF9 \
			or not bool(token_record.get("ok", false)) \
			or String(token_record.get("status", "")) != "callback_task_seed_requested" \
			or not bool(token_fb.get("ok", false)) \
			or String(token_fb.get("status", "")) != "root_scenario_terminated" \
			or int(token_fb.get("source_byte_offset", -1)) != 7 \
			or int(token_fb.get("terminal_handler_cpu_address", -1)) != 0x80CF:
		return _fail("The source parser did not validate the F9/event/FB chain to the ROM's $80CF terminal.")
	if (int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)) != 0xB7D4 \
			or int(stream[7]) != 0xFB:
		return _fail("The live bank-$10 reader cursor does not point to scenario-$35 root byte $FB at $B7D4.")

	_record(0x8003)
	_record(0x8021)
	_set_a(int(_ram[0x0517]))
	_record(0x8024)
	_write_ram(0x052A, int(_cpu["a"]), 0x8024)
	_record(0x8027)
	_set_a(int(_ram[0x0516]))
	_record(0x802A)
	_set_a(int(_cpu["a"]) & 0xFB)
	_record(0x802C)
	_write_ram(0x0516, int(_cpu["a"]), 0x802C)
	_record(0x802F)
	_set_a(0)
	_record(0x8031)
	_write_ram(0x052B, 0, 0x8031)
	_record(0x8034)
	_write_ram(0x052D, 0, 0x8034)
	_record(0x8037)
	_write_ram(0x052C, 0, 0x8037)
	_record(0x803A)
	_write_ram(0x0530, 0, 0x803A)
	_record(0x803D)
	_write_ram(0x003A, 0, 0x803D)
	if event_reader.slice(0, 16) != PackedByteArray([
		0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0xC9, 0xF0,
		0x90, 0x06, 0x20, 0xA9, 0x80, 0x4C, 0x3F, 0x80]):
		return _fail("The bank-$10 event reader no longer has the checked root-control dispatch sequence.")
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	var live_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	if int(_cpu["y"]) != 0 or live_pointer + int(_cpu["y"]) != 0xB7D4:
		return _fail("The `$803F` event reader did not address the current scenario root byte at `$B7D4`.")
	_set_a(int(stream[7]))
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
		return _fail("The live scenario byte does not take the source `$8047` opcode-dispatch branch.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	return _execute_scenario_opcode_dispatch()


func _execute_scenario_opcode_dispatch() -> bool:
	var dispatch: PackedByteArray = _sources.get("scenario_opcode_dispatch", PackedByteArray())
	var vector: PackedByteArray = _sources.get("opcode_dispatch_vector", PackedByteArray())
	var helper: PackedByteArray = _sources.get("opcode_table_helper", PackedByteArray())
	if dispatch.size() != 38 or vector != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or helper != PackedByteArray([
				0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36,
				0x48, 0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00]):
		return _fail("The ROM scenario opcode dispatcher or inline-table helper failed its source check.")
	if dispatch.slice(0, 6) != PackedByteArray([0x38, 0xE9, 0xF0, 0x20, 0x09, 0xC5]) \
			or int(_cpu["a"]) < 0xF0:
		return _fail("The scenario opcode did not enter the ROM's checked `$F0` dispatch callsite.")
	_record(0x80A9)
	_set_c(true)
	_record(0x80AA)
	var old_a := int(_cpu["a"])
	var sbc_result := old_a - 0xF0
	_set_c(sbc_result >= 0)
	_set_v((((old_a ^ (sbc_result & 0xFF)) & (old_a ^ 0xF0)) & 0x80) != 0)
	_set_a(sbc_result)
	_record(0x80AC)
	if not _expect_scenario_source("scenario_opcode_dispatch", 0x80AC, [0x20, 0x09, 0xC5]): return false
	_jsr(0x80AC, 0xC509)
	_record(0xC509)
	_cpu["pc"] = 0xCB99
	var index := int(_cpu["a"]) & 0xFF
	_set_a((index << 1) & 0xFF)
	_record(0xCB99)
	_set_y(int(_cpu["a"]))
	_record(0xCB9A)
	_set_a(_pop(0xCB9B))
	_record(0xCB9C)
	_write_ram(0x0036, int(_cpu["a"]), 0xCB9C)
	_record(0xCB9E)
	_set_a(_pop(0xCB9F))
	_record(0xCB9F)
	_write_ram(0x0037, int(_cpu["a"]), 0xCB9F)
	_record(0xCBA1)
	_set_y((int(_cpu["y"]) + 1) & 0xFF)
	var table_pointer := int(_ram[0x0036]) | (int(_ram[0x0037]) << 8)
	if table_pointer != 0x80AE:
		return _fail("The ROM opcode-table helper did not recover the `$80AE` inline-table return address.")
	_record(0xCBA2)
	var table_offset := table_pointer + int(_cpu["y"]) - 0x80A9
	if table_offset < 6 or table_offset + 1 >= dispatch.size():
		return _fail("The ROM opcode dispatch index escaped the hash-checked inline table.")
	_set_a(int(dispatch[table_offset]))
	_record(0xCBA4)
	_push(int(_cpu["a"]), 0xCBA4, "PHA")
	_record(0xCBA5)
	_set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0xCBA6)
	_set_a(int(dispatch[table_offset + 1]))
	_record(0xCBA8)
	_write_ram(0x0037, int(_cpu["a"]), 0xCBA8)
	_record(0xCBAA)
	_set_a(_pop(0xCBAA))
	_record(0xCBAB)
	_write_ram(0x0036, int(_cpu["a"]), 0xCBAB)
	_record(0xCBAD)
	var target := int(_ram[0x0036]) | (int(_ram[0x0037]) << 8)
	_cpu["pc"] = target
	match target:
		0x8837:
			return _execute_scenario_fb_handler()
		0x8105:
			if int(_ram[0x0518]) == 0x1C:
				return _execute_scenario1c_f3_84_handler()
		0x80F4:
			if int(_ram[0x0518]) == 0x1C:
				return _execute_scenario1c_f2_handler()
	return _fail("The ROM F0-FF table selected an unsupported live handler `$%04X`." % target)


func _execute_scenario1c_f3_84_handler() -> bool:
	var handler := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_handler_context_8105_8138.bin")
	var selector := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F3_selector04_helper_8259_8260.bin")
	var root := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "scenario_1C.bin")
	var live_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	var live_044e := int(_ram[0x044E])
	if live_044e not in [0x01, 0x02]:
		return _fail("Scenario-$1C `$F3 $84` only has a source-verified live selector for `$044E=$01/$02`.")
	var expected_selector_x := live_044e - 1
	var skip_byte_offset := 0x07 + expected_selector_x
	var skip_byte := int(root[skip_byte_offset]) if skip_byte_offset < root.size() else -1
	var resume_offset := skip_byte_offset + skip_byte
	var expected_f2_target := (int(root[resume_offset + 1]) | (int(root[resume_offset + 2]) << 8)) \
		if resume_offset >= 0 and resume_offset + 2 < root.size() else -1
	var expected_resume_pointer := 0x9BE3 + resume_offset
	var expected_skip_byte := 0x02 if live_044e == 0x01 else 0x04
	var expected_target := 0xB49E if live_044e == 0x01 else 0xB4B6
	if handler.size() != 51 or selector != PackedByteArray([0xAE, 0x4E, 0x04, 0xF0, 0x01, 0xCA, 0x60]) \
			or root != PackedByteArray([0xFD, 0x00, 0xFA, 0x3E, 0x9F, 0xF3, 0x84, 0x02,
				0x04, 0xF2, 0x9E, 0xB4, 0xF2, 0xB6, 0xB4]) \
			or _sha256(root) != PASS_SCENARIO_1C_STREAM_SHA256 \
			or live_pointer != 0x9BE8 or int(_ram[0x003A]) != 1 \
			or skip_byte != expected_skip_byte or resume_offset != (0x09 if live_044e == 0x01 else 0x0C) \
			or expected_f2_target != expected_target:
		return _fail("Scenario-$1C `$F3 $84` requires its pinned handler and a live `$9BE8/$3A=1` branch supported by `$044E`.")
	var parse_context := {"ram_0441": int(_ram[0x0441]), "ram_044E": live_044e,
		"ram_043B": int(_ram[0x043B]), "ram_043C": int(_ram[0x043C]),
		"ram_0516": int(_ram[0x0516]), "ram_0638": int(_ram[0x0638])}
	var fd00_resolver: RefCounted = SCENARIO36_FD00_RESOLVER.new()
	if not fd00_resolver.configure():
		return _fail("Scenario-$1C `$F3 $84` source context could not configure `$FD $00`: " + fd00_resolver.last_error)
	var fd00_result: Dictionary = fd00_resolver.execute(_ram)
	if not bool(fd00_result.get("ok", false)):
		return _fail("Scenario-$1C `$F3 $84` source context rejected live holder state: " + String(fd00_result.get("error", "unknown error")))
	parse_context["ram_fd00_mirror_flag"] = int(fd00_result["mirror_flag"])
	var parsed: Dictionary = SCENARIO_BYTECODE_READER.read_project_scenario(0x1C, parse_context)
	var selected_f3: Dictionary = {}
	for token_variant in parsed.get("tokens", []):
		if token_variant is Dictionary and int((token_variant as Dictionary).get("opcode", -1)) == 0xF3 \
				and int((token_variant as Dictionary).get("byte_offset", -1)) == 5:
			selected_f3 = token_variant
			break
	if selected_f3.is_empty() or String(selected_f3.get("status", "")) != "selected" \
			or int(selected_f3.get("ram_044E", -1)) != live_044e \
			or int(selected_f3.get("selector_result_x", -1)) != expected_selector_x \
			or int(selected_f3.get("skip_byte", -1)) != expected_skip_byte \
			or int(selected_f3.get("resume_byte_offset", -1)) != resume_offset \
			or int(selected_f3.get("selected_f2_pointer", -1)) != expected_target:
		return _fail("Scenario-$1C `$F3 $84` did not select the branch backed by live `$044E`.")
	if handler.slice(0, 19) != PackedByteArray([0xA4, 0x3A, 0xB1, 0x5D, 0x48, 0x20, 0x6E, 0x81,
		0x68, 0x10, 0x1F, 0x8A, 0x38, 0x65, 0x3A, 0x18, 0x65, 0x5D, 0x85]) \
			or handler[19] != 0x5D or handler[20] != 0x90 or handler[21] != 0x02:
		return _fail("Scenario-$1C `$F3 $84` handler bytes differ from the ROM branch sequence.")
	_record(0x8105)
	_set_y(int(_ram[0x003A]))
	_record(0x8107)
	_set_a(int(root[6]))
	_record(0x8109)
	_push(int(_cpu["a"]), 0x8109, "PHA")
	_jsr(0x810A, 0x816E)
	_record(0x816E)
	if int(selector[2]) != 0x04 or int(selector[3]) != 0xF0 or int(_ram[0x044E]) != live_044e:
		return _fail("Scenario-$1C `$8259` selector helper no longer receives the live `$044E` value.")
	_set_x(live_044e)
	if live_044e != 0:
		_set_x(int(_cpu["x"]) - 1)
	_rts(0x816E)
	if not _expect_pc(0x810D): return false
	_record(0x810D)
	_set_a(_pop(0x810D))
	_record(0x810E)
	if (int(_cpu["p"]) & P_N) == 0:
		return _fail("Live `$F3 $84` high-bit operand did not select the ROM skip handler.")
	_record(0x8110)
	_set_a(int(_cpu["x"]))
	_record(0x8111)
	_set_c(true)
	_record(0x8112)
	_adc(int(_ram[0x003A]))
	_record(0x8114)
	_set_c(false)
	_record(0x8115)
	_adc(int(_ram[0x005D]))
	_record(0x8117)
	_write_ram(0x005D, int(_cpu["a"]), 0x8117)
	if (int(_cpu["p"]) & P_C) != 0:
		_record(0x811B)
		_write_ram(0x005E, (int(_ram[0x005E]) + 1) & 0xFF, 0x811B)
	else:
		_record(0x8119)
	_record(0x811D)
	_set_y(0)
	_record(0x811F)
	_set_a(int(root[skip_byte_offset]))
	_record(0x8121)
	_set_c(false)
	_record(0x8122)
	_adc(int(_ram[0x005D]))
	_record(0x8124)
	_write_ram(0x005D, int(_cpu["a"]), 0x8124)
	if (int(_cpu["p"]) & P_C) != 0:
		_record(0x8128)
		_write_ram(0x005E, (int(_ram[0x005E]) + 1) & 0xFF, 0x8128)
	else:
		_record(0x8126)
	_record(0x812A)
	_set_a(0)
	_record(0x812C)
	_write_ram(0x003A, 0, 0x812C)
	_record(0x812E)
	_rts(0x812E)
	return _expect_pc(0x804C) and int(_ram[0x003A]) == 0 \
		and (int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)) == expected_resume_pointer


func _execute_scenario1c_f2_handler() -> bool:
	var handler := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "bank10_F2_handler_80F4_8105.bin")
	var root := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "scenario_1C.bin")
	var source_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	var live_044e := int(_ram[0x044E])
	var source_offset := source_pointer - 0x9BE3
	var target_low_offset := source_offset + 1
	var target_high_offset := source_offset + 2
	var target_pointer := (int(root[target_low_offset]) | (int(root[target_high_offset]) << 8)) \
		if target_low_offset >= 0 and target_high_offset < root.size() else -1
	var source_opcode := int(root[source_offset]) if source_offset >= 0 and source_offset < root.size() else -1
	var expected_source_pointer := 0x9BEC if live_044e == 0x01 else (0x9BEF if live_044e == 0x02 else -1)
	var expected_target_pointer := 0xB49E if live_044e == 0x01 else (0xB4B6 if live_044e == 0x02 else -1)
	if handler != PackedByteArray([0xA4, 0x3A, 0xB1, 0x5D, 0xAA, 0xC8, 0xB1, 0x5D,
		0x85, 0x5E, 0x86, 0x5D, 0xA9, 0x00, 0x85, 0x3A, 0x60]) \
			or root != PackedByteArray([0xFD, 0x00, 0xFA, 0x3E, 0x9F, 0xF3, 0x84, 0x02,
				0x04, 0xF2, 0x9E, 0xB4, 0xF2, 0xB6, 0xB4]) \
			or _sha256(root) != PASS_SCENARIO_1C_STREAM_SHA256 \
			or source_pointer != expected_source_pointer or int(_ram[0x003A]) != 1 \
			or source_opcode != 0xF2 or target_pointer != expected_target_pointer:
		return _fail("Scenario-$1C `$F2` handler requires the ROM operand cursor selected by live `$044E`.")
	_record(0x80F4)
	_set_y(int(_ram[0x003A]))
	_record(0x80F6)
	_set_a(int(root[target_low_offset]))
	_record(0x80F8)
	_set_x(int(_cpu["a"]))
	_record(0x80F9)
	_set_y(int(_cpu["y"]) + 1)
	_record(0x80FA)
	_set_a(int(root[target_high_offset]))
	_record(0x80FC)
	_write_ram(0x005E, int(_cpu["a"]), 0x80FC)
	_record(0x80FE)
	_write_ram(0x005D, int(_cpu["x"]), 0x80FE)
	_record(0x8100)
	_set_a(0)
	_record(0x8102)
	_write_ram(0x003A, 0, 0x8102)
	_record(0x8104)
	_rts(0x8104)
	return _expect_pc(0x804C) and int(_ram[0x003A]) == 0 \
		and (int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)) == target_pointer


func _execute_scenario_fb_handler() -> bool:
	var handler: PackedByteArray = _sources.get("fb_handler", PackedByteArray())
	if handler.size() != 28 or handler.slice(0, 16) != PackedByteArray([
		0xAE, 0x22, 0x05, 0xCA, 0xCA, 0x8E, 0x22, 0x05,
		0x10, 0x03, 0x4C, 0xCF, 0x80, 0xBD, 0x1A, 0x05]):
		return _fail("The ROM `$FB` scenario handler failed its source check.")
	_record(0x8837)
	_set_x(int(_ram[0x0522]))
	_record(0x883A)
	_set_x(int(_cpu["x"]) - 1)
	_record(0x883B)
	_set_x(int(_cpu["x"]) - 1)
	_record(0x883C)
	_write_ram(0x0522, int(_cpu["x"]), 0x883C)
	_record(0x883F)
	if (int(_cpu["p"]) & P_N) == 0:
		_cpu["pc"] = 0x8844
		return _execute_nonroot_fb_handler(handler)
	_record(0x8841)
	_cpu["pc"] = 0x80CF
	return _execute_scenario_root_terminal()


func _execute_nonroot_fb_handler(handler: PackedByteArray) -> bool:
	if handler.slice(13, 15) != PackedByteArray([0xBD, 0x1A]):
		return _fail("The nested `$FB` continuation does not match the checked handler bytes.")
	var indexed_address := (0x051A + int(_cpu["x"])) & 0x07FF
	_record(0x8844)
	_set_a(int(_ram[indexed_address]))
	_record(0x8847)
	_write_ram(0x005D, int(_cpu["a"]), 0x8847)
	_record(0x8849)
	_set_a(int(_ram[(0x051B + int(_cpu["x"])) & 0x07FF]))
	_record(0x884C)
	_write_ram(0x005E, int(_cpu["a"]), 0x884C)
	_record(0x884E)
	_set_a(0)
	_record(0x8850)
	_write_ram(0x003A, 0, 0x8850)
	_record(0x8852)
	_rts(0x8852)
	return _expect_pc(0x804C)


func _execute_scenario_root_terminal() -> bool:
	var terminal: PackedByteArray = _sources.get("f0_terminal", PackedByteArray())
	if terminal.size() != 39 or terminal != PackedByteArray([
		0xA9, 0x00, 0x8D, 0x2A, 0x05, 0xA9, 0x08, 0x2C, 0x16, 0x05,
		0xD0, 0x0B, 0x0D, 0x16, 0x05, 0x8D, 0x16, 0x05, 0xA2, 0x05,
		0x20, 0x1B, 0xC5, 0xA9, 0x00, 0x8D, 0x22, 0x05, 0xA5, 0x21,
		0x29, 0x1E, 0x85, 0x21, 0x68, 0x68, 0x60, 0xA4, 0x3A]):
		return _fail("The ROM root-terminal `$80CF` source failed its 39-byte check.")
	_record(0x80CF)
	_set_a(0)
	_record(0x80D1)
	_write_ram(0x052A, 0, 0x80D1)
	_record(0x80D4)
	_set_a(0x08)
	_record(0x80D6)
	_bit_ram(0x0516)
	_record(0x80D9)
	if (int(_cpu["p"]) & P_Z) == 0:
		_cpu["pc"] = 0x80E6
	else:
		_record(0x80DB)
		_set_a(int(_cpu["a"]) | int(_ram[0x0516]))
		_record(0x80DE)
		_write_ram(0x0516, int(_cpu["a"]), 0x80DE)
		_record(0x80E1)
		_set_x(5)
		if not _execute_scenario_finish_delay_helper(): return false
	if int(_cpu["pc"]) != 0x80E6:
		return _fail("The `$80CF` source terminal did not return from fixed `$C51B` at `$80E6`.")
	_record(0x80E6)
	_set_a(0)
	_record(0x80E8)
	_write_ram(0x0522, 0, 0x80E8)
	_record(0x80EB)
	_set_a(int(_ram[0x0021]))
	_record(0x80ED)
	_set_a(int(_cpu["a"]) & 0x1E)
	_record(0x80EF)
	_write_ram(0x0021, int(_cpu["a"]), 0x80EF)
	_record(0x80F1)
	_set_a(_pop(0x80F1))
	_record(0x80F2)
	_set_a(_pop(0x80F2))
	_record(0x80F3)
	_rts(0x80F3)
	return _expect_pc(0xED84)


func _execute_scenario_finish_delay_helper() -> bool:
	var vector: PackedByteArray = _sources.get("finish_dispatch", PackedByteArray())
	var increment: PackedByteArray = _sources.get("delay_increment", PackedByteArray())
	if vector != PackedByteArray([0x4C, 0x02, 0xCB]) \
			or increment != PackedByteArray([0xB5, 0x01, 0xF0, 0x06, 0xB5, 0x00,
				0xD0, 0x02, 0xF6, 0x00, 0x60]):
		return _fail("The fixed `$C51B->$CB02` scenario-finish delay helper failed its byte check.")
	_jsr(0x80E3, 0xC51B)
	_record(0xC51B)
	_cpu["pc"] = 0xCB02
	_record(0xCB02)
	_set_a(int(_ram[(0x0001 + int(_cpu["x"])) & 0x07FF]))
	_record(0xCB04)
	if (int(_cpu["p"]) & P_Z) == 0:
		_record(0xCB06)
		_set_a(int(_ram[int(_cpu["x"]) & 0x07FF]))
		_record(0xCB08)
		if (int(_cpu["p"]) & P_Z) != 0:
			_record(0xCB0A)
			var address := int(_cpu["x"]) & 0xFF
			_write_ram(address, (int(_ram[address]) + 1) & 0xFF, 0xCB0A)
			_set_nz(int(_ram[address]))
	_record(0xCB0C)
	_rts(0xCB0C)
	return _expect_pc(0x80E6)


func _execute_scenario_post_callback_path() -> bool:
	var source: PackedByteArray = _sources.get("scenario_post_callback", PackedByteArray())
	if source.size() != 161 or _sha256(source) != String(SOURCE_SPANS["scenario_post_callback"]["sha256"]):
		return _fail("Scenario post-callback caller failed its ROM source hash.")
	var scenario_id := int(_ram[0x0518])
	var scenario_flag := int(_ram[0x0516])
	var scenario1c_callback63_expired_profile := _is_scenario1c_callback63_phase71_expired_profile(_ram)
	if scenario1c_callback63_expired_profile \
			and not _consume_scenario1c_callback63_fb_terminal():
		return false
	var scenario18_callback72_profile := _is_scenario18_callback72_post_return_profile(_ram)
	var scenario1c_callback1f_expired_profile := _is_scenario1c_callback1f_expired_profile(_ram)
	var scenario1c_callback01_phase71_expired_profile := _is_scenario1c_callback01_phase71_expired_profile(_ram)
	var scenario2e_callback36_map2f_post_callback_profile := \
		_is_scenario2e_callback36_map2f_post_callback_profile(_ram)
	var scenario1e_callback45_no_seed_profile := scenario_id == 0x1E and scenario_flag == 0x71 \
			and int(_ram[0x0519]) == 0 \
			and _ram.slice(0x0523, 0x052A) == PackedByteArray([0x07, 0x45, 0x06, 0x80, 0x3C, 0x90, 0xFF]) \
			and int(_ram[0x05CE]) == 0x80 \
			and _ram.slice(0x05D1, 0x05D3) == PackedByteArray([0x00, 0x00])
	var scenario36_f9_actor_profile := scenario_id == 0x36 and scenario_flag == 0x71 \
			and int(_ram[0x0519]) == 0 and int(_ram[0x0528]) == 0xE6 \
			and int(_ram[0x05CE]) == 0xA0 and int(_ram[0x0529]) == 0x75
	var scenario38_callback34_no_seed_profile := _is_scenario38_callback34_map2d_profile(_ram)
	var expected_actor_parameter := 0xFF
	if scenario18_callback72_profile:
		expected_actor_parameter = 0x47
	elif scenario1c_callback1f_expired_profile:
		expected_actor_parameter = 0x00
	elif scenario1c_callback63_expired_profile:
		expected_actor_parameter = 0x58
	elif scenario1c_callback01_phase71_expired_profile:
		expected_actor_parameter = 0x58
	elif scenario_id == 0x35:
		expected_actor_parameter = 0x73
	elif scenario36_f9_actor_profile:
		expected_actor_parameter = 0x75
	elif scenario_id == 0x36 and scenario_flag == 0x71:
		expected_actor_parameter = 0x74
	elif scenario2e_callback36_map2f_post_callback_profile:
		expected_actor_parameter = 0x6D
	var expected_actor_seed_parameter := 0xA0
	if scenario18_callback72_profile:
		expected_actor_seed_parameter = 0xA0
	elif scenario1c_callback1f_expired_profile:
		expected_actor_seed_parameter = 0x80
	elif scenario1c_callback63_expired_profile:
		expected_actor_seed_parameter = 0xA0
	elif scenario1c_callback01_phase71_expired_profile:
		expected_actor_seed_parameter = 0xA0
	elif scenario_id == 0x35:
		expected_actor_seed_parameter = 0x00
	elif scenario1e_callback45_no_seed_profile or scenario38_callback34_no_seed_profile:
		expected_actor_seed_parameter = 0x80
	elif scenario36_f9_actor_profile:
		expected_actor_seed_parameter = 0xA0
	elif scenario_flag == 0x71:
		expected_actor_seed_parameter = 0x80
	# ROM `$ED15` routes scenario `$36` with actor parameter `$FF` through its
	# no-seed tail. `$05CE` is a separate global placement value written by the
	# `$8327` callback path; both `$A0` and the recorded `$80` placement are
	# source-observed before this continuation, including frames 8681-8707.
	var scenario36_no_seed_callback_profile := scenario_id == 0x36 \
			and scenario_flag == 0x71 and int(_ram[0x0519]) == 0 \
			and int(_ram[0x05CE]) in [0x80, 0xA0] and int(_ram[0x0529]) == 0xFF
	var scenario44_callback70_profile := scenario_id == 0x44 and scenario_flag == 0x51 \
			and int(_ram[0x0519]) == 0 \
			and _ram.slice(0x0523, 0x0525) == PackedByteArray([0x02, 0x70]) \
			and _ram.slice(0x0528, 0x052A) == PackedByteArray([0x5C, 0xFF]) \
			and int(_ram[0x05CE]) == 0xA0 and int(_ram[0x05CD]) == 0x80
	if (scenario_id not in [0x35, 0x36] and not scenario18_callback72_profile \
			and not scenario1c_callback1f_expired_profile \
			and not scenario1c_callback63_expired_profile \
			and not scenario1c_callback01_phase71_expired_profile \
			and not scenario1e_callback45_no_seed_profile \
			and not scenario44_callback70_profile and not scenario38_callback34_no_seed_profile \
			and not scenario2e_callback36_map2f_post_callback_profile) \
			or scenario_flag not in [0x51, 0x71] \
			or (not scenario36_no_seed_callback_profile and not scenario1e_callback45_no_seed_profile \
				and not scenario44_callback70_profile \
				and (int(_ram[0x0519]) != 0 \
				or int(_ram[0x05CE]) != expected_actor_seed_parameter \
				or int(_ram[0x0529]) != expected_actor_parameter)):
		return _fail("The live post-`$CAF7` callback state is outside a source-bounded profile: id=$%02X flag=$%02X marker=$%02X actor_seed=$%02X actor_parameter=$%02X expected_seed=$%02X expected_parameter=$%02X." % [
			scenario_id, scenario_flag, int(_ram[0x0519]), int(_ram[0x05CE]),
			int(_ram[0x0529]), expected_actor_seed_parameter, expected_actor_parameter])
	if not _expect_span("scenario_post_callback", 0xEC8C, [0xAD, 0x16, 0x05, 0x29, 0x8F, 0x8D, 0x16, 0x05]): return false
	_record(0xEC8C)
	_set_a(int(_ram[0x0516]))
	_record(0xEC8F)
	_set_a(int(_cpu["a"]) & 0x8F)
	_record(0xEC91)
	_write_ram(0x0516, int(_cpu["a"]), 0xEC91)
	if int(_ram[0x0516]) != 0x01:
		return _fail("`$EC8C` did not clear the callback mode bits to `$0516=$01`.")
	_record(0xEC94)
	_set_a(int(_ram[0x0523]))
	_record(0xEC97)
	_write_ram(0x0519, int(_cpu["a"]), 0xEC97)
	_record(0xEC9A)
	_set_a(int(_ram[0x0524]))
	_record(0xEC9D)
	_compare_a(0xFF)
	_record(0xEC9F)
	if (int(_cpu["p"]) & P_Z) != 0:
		return _fail("The `$0524=$FF` callback exit branch is outside this bounded path.")
	_cpu["pc"] = 0xECA1
	_record(0xECA1)
	_set_a(0x04)
	_record(0xECA3)
	_bit_ram(0x0516)
	_record(0xECA6)
	if (int(_cpu["p"]) & P_Z) == 0:
		return _fail("`$0516` bit 2 selects the unresolved `$CC46` source helper.")
	_cpu["pc"] = 0xECB7
	_record(0xECB7)
	_set_a(int(_ram[0x0526]))
	_record(0xECBA)
	if (int(_cpu["p"]) & P_N) == 0:
		_cpu["pc"] = 0xECCA
	else:
		_record(0xECBC)
		_set_a(int(_cpu["a"]) & 0x7F)
		_record(0xECBE)
		_write_ram(0x0526, int(_cpu["a"]), 0xECBE)
		_record(0xECC1)
		_write_ram(0x0490, int(_cpu["a"]), 0xECC1)
		_record(0xECC4)
		_set_a(int(_ram[0x0527]))
		_record(0xECC7)
		_write_ram(0x0491, int(_cpu["a"]), 0xECC7)
		_cpu["pc"] = 0xECCA
	_record(0xECCA)
	_set_a(int(_ram[0x0525]))
	_record(0xECCD)
	_set_x(0)
	_record(0xECCF)
	_jsr(0xECCF, 0xCC02)
	if not _execute_rom_subroutine("palette_fill", 0xCC02, 0xCC46, 0xECD2): return false
	_record(0xECD2)
	_jsr(0xECD2, 0xCCD2)
	if not _execute_rom_subroutine("inline_append", 0xCCD2, 0xCD0D, 0xECD8): return false
	_record(0xECD8)
	_set_a(int(_ram[0x05CE]))
	_push(int(_cpu["a"]), 0xECD8, "PHA")
	_record(0xECDC)
	_set_a(int(_ram[0x0022]))
	_record(0xECDE)
	_set_a(0x0B)
	_record(0xECE0)
	_write_ram(0x0024, int(_cpu["a"]), 0xECE0)
	_record(0xECE2)
	_set_a(0x0C)
	_record(0xECE4)
	_write_ram(0x0025, int(_cpu["a"]), 0xECE4)
	_record(0xECE6)
	_jsr(0xECE6, 0xCE2D)
	if not _execute_mapper_helper(0xECE9): return false
	_record(0xECE9)
	_set_a(_pop(0xECE9))
	var actor_parameter_input := int(_cpu["a"])
	_record(0xECEA)
	_jsr(0xECEA, 0x8006)
	if int(_mapper["bank_low"]) != 0x0B or int(_mapper["bank_high"]) != 0x0C \
			or not _expect_span("actor_param_vector", 0x8006, [0x4C, 0xA1, 0x84]):
		return _fail("The `$8006` actor-parameter vector is not mapped to bank-$0B `$84A1`.")
	_record(0x8006)
	_cpu["pc"] = 0x84A1
	if not _execute_rom_subroutine("actor_param_worker", 0x84A1, 0x84CF, 0xECED): return false
	var expected_actor_x := 0x02
	if actor_parameter_input < 0x80:
		expected_actor_x -= 1
	if actor_parameter_input < 0x40:
		expected_actor_x -= 1
	var actor_low_six_bits := actor_parameter_input & 0x3F
	var expected_actor_y := 0x74 if actor_low_six_bits >= 0x20 else 0xE4
	if actor_low_six_bits < 0x20:
		expected_actor_x ^= 0x02
	if int(_cpu["x"]) != expected_actor_x or int(_cpu["y"]) != expected_actor_y:
		return _fail("Bank-$0B `$84A1` input=$%02X derived X=$%02X/Y=$%02X; ROM branch calculation expects X=$%02X/Y=$%02X (scenario $%02X)." % [actor_parameter_input, int(_cpu["x"]), int(_cpu["y"]), expected_actor_x, expected_actor_y, scenario_id])
	_record(0xECED)
	_set_a(0)
	_record(0xECEF)
	_write_ram(0x004A, 0, 0xECEF)
	_record(0xECF1)
	_set_a(int(_ram[0x05D1]))
	_record(0xECF4)
	_write_ram(0x05D2, int(_cpu["a"]), 0xECF4)
	_record(0xECF7)
	_set_a(int(_ram[0x0528]))
	_record(0xECFA)
	_compare_a(0xFF)
	_record(0xECFC)
	if (int(_cpu["p"]) & P_Z) == 0:
		_record(0xECFE)
		_write_ram(0x053C, int(_cpu["a"]), 0xECFE)
		_record(0xED01)
		_set_a(0x80)
		_record(0xED03)
		_write_ram(0x053A, int(_cpu["a"]), 0xED03)
	else:
		_cpu["pc"] = 0xED06
	_record(0xED06)
	_set_a(0)
	_record(0xED08)
	_write_ram(0x000D, 0, 0xED08)
	_record(0xED0A)
	_write_ram(0x000E, 0, 0xED0A)
	_record(0xED0C)
	_set_a(int(_ram[0x052A]))
	_record(0xED0F)
	_write_ram(0x0517, int(_cpu["a"]), 0xED0F)
	_record(0xED12)
	_set_a(int(_ram[0x0529]))
	_cpu["pc"] = 0xED15
	if not _expect_span("scenario_post_callback", 0xED15, [0xC9, 0xFF, 0xF0, 0x14]): return false
	_record(0xED15)
	_compare_a(0xFF)
	if (int(_cpu["p"]) & P_Z) != 0:
		_cpu["pc"] = 0xED2D
	var supported_actor_parameter := -1
	if scenario18_callback72_profile:
		supported_actor_parameter = 0x47
	elif scenario1c_callback1f_expired_profile:
		supported_actor_parameter = 0x00
	elif scenario1c_callback63_expired_profile:
		supported_actor_parameter = 0x58
	elif scenario1c_callback01_phase71_expired_profile:
		supported_actor_parameter = 0x58
	elif scenario_id == 0x35:
		supported_actor_parameter = 0x73
	elif scenario36_f9_actor_profile:
		supported_actor_parameter = 0x75
	elif scenario_id == 0x36 and scenario_flag == 0x71:
		supported_actor_parameter = 0x74
	elif scenario2e_callback36_map2f_post_callback_profile:
		# The completed map-$2F callback carries the ROM record's actor `$6D`.
		supported_actor_parameter = 0x6D
	if int(_cpu["a"]) == supported_actor_parameter and supported_actor_parameter >= 0:
		_actor_worker_seed_request = _make_actor_worker_seed_request()
		_actor_seed_pause_ready = true
		return true
	if int(_cpu["a"]) == 0xFF and (scenario_id == 0x36 or scenario1e_callback45_no_seed_profile \
			or scenario44_callback70_profile or scenario38_callback34_no_seed_profile):
		# ROM `$ED17` branches to the shared `$ED2D` caller tail when no actor
		# parameter is selected; the tail restores scenario flags and returns to `$EB9E`.
		if not _execute_scenario35_resume_tail():
			return false
		_scenario_post_callback_executed = true
		return true
	return _fail("The live `$ED15` actor parameter is not a bounded scenario actor seed or recorded no-seed selector.")


func _execute_rom_subroutine(source_name: String, start_pc: int, end_pc: int, expected_return_pc: int) -> bool:
	var step_limit := 1024
	for _step in range(step_limit):
		var pc := int(_cpu.get("pc", -1))
		if pc < start_pc or pc >= end_pc:
			return _fail("ROM helper `%s` escaped its checked source span at `$%04X`." % [source_name, pc])
		var opcode := _read_rom_source_byte(pc)
		if opcode < 0:
			return _fail("ROM helper `%s` has no source byte at `$%04X`." % [source_name, pc])
		_record(pc)
		var operand := _read_rom_source_byte(pc + 1)
		var operand_hi := _read_rom_source_byte(pc + 2)
		var next_pc := pc + 1
		match opcode:
			0xA0, 0xA2: # LDY/LDX immediate
				if operand < 0: return _fail("Truncated immediate load at `$%04X`." % pc)
				if opcode == 0xA0: _set_y(operand)
				else: _set_x(operand)
				next_pc = pc + 2
			0xA5: # LDA zero page
				_set_a(int(_ram[operand]))
				next_pc = pc + 2
			0xA9: # LDA immediate
				_set_a(operand)
				next_pc = pc + 2
			0xAD: # LDA absolute
				_set_a(int(_ram[operand | (operand_hi << 8)]))
				next_pc = pc + 3
			0xB1: # LDA (zero-page),Y; data may be an inline ROM byte.
				var pointer := int(_ram[operand]) | (int(_ram[(operand + 1) & 0xFF]) << 8)
				var indirect_value := _read_rom_source_byte(pointer + int(_cpu["y"]))
				if indirect_value < 0: return _fail("ROM helper `%s` indirect read escaped checked source at `$%04X`." % [source_name, pointer + int(_cpu["y"])])
				_set_a(indirect_value)
				next_pc = pc + 2
			0x84: # STY zero page
				_write_ram(operand, int(_cpu["y"]), pc)
				next_pc = pc + 2
			0x85: # STA zero page
				_write_ram(operand, int(_cpu["a"]), pc)
				next_pc = pc + 2
			0x8D: # STA absolute
				_write_indexed_address(operand | (operand_hi << 8), int(_cpu["a"]), pc, "absolute_store")
				next_pc = pc + 3
			0x9D: # STA absolute,X
				_write_indexed_address((operand | (operand_hi << 8)) + int(_cpu["x"]), int(_cpu["a"]), pc, "indexed_store")
				next_pc = pc + 3
			0xFE: # INC absolute,X
				var indexed_increment_address := (operand | (operand_hi << 8)) + int(_cpu["x"])
				_write_indexed_address(indexed_increment_address, (int(_ram[indexed_increment_address]) + 1) & 0xFF, pc, "indexed_increment")
				_set_nz(int(_ram[indexed_increment_address]))
				next_pc = pc + 3
			0xCE: # DEC absolute
				var absolute_decrement_address := operand | (operand_hi << 8)
				_write_ram(absolute_decrement_address, (int(_ram[absolute_decrement_address]) - 1) & 0xFF, pc)
				_set_nz(int(_ram[absolute_decrement_address]))
				next_pc = pc + 3
			0xE6: # INC zero page
				_write_ram(operand, (int(_ram[operand]) + 1) & 0xFF, pc)
				_set_nz(int(_ram[operand]))
				next_pc = pc + 2
			0xEE: # INC absolute
				var absolute_increment_address := operand | (operand_hi << 8)
				_write_ram(absolute_increment_address, (int(_ram[absolute_increment_address]) + 1) & 0xFF, pc)
				_set_nz(int(_ram[absolute_increment_address]))
				next_pc = pc + 3
			0xBD: # LDA absolute,X
				_set_a(int(_ram[(operand | (operand_hi << 8)) + int(_cpu["x"])]))
				next_pc = pc + 3
			0x0A: # ASL A
				var shift_value := int(_cpu["a"])
				_set_c((shift_value & 0x80) != 0)
				_set_a((shift_value << 1) & 0xFF)
				next_pc = pc + 1
			0x26: # ROL zero page
				var rotate_value := int(_ram[operand])
				var carry_in := int(_cpu["p"]) & P_C
				_set_c((rotate_value & 0x80) != 0)
				_write_ram(operand, ((rotate_value << 1) | carry_in) & 0xFF, pc)
				_set_nz(int(_ram[operand]))
				next_pc = pc + 2
			0x18: # CLC
				_set_c(false)
				next_pc = pc + 1
			0x69: # ADC immediate
				_adc(operand)
				next_pc = pc + 2
			0x65: # ADC zero page
				_adc(int(_ram[operand]))
				next_pc = pc + 2
			0x6D: # ADC absolute
				_adc(int(_ram[operand | (operand_hi << 8)]))
				next_pc = pc + 3
			0x29: # AND immediate
				_set_a(int(_cpu["a"]) & operand)
				next_pc = pc + 2
			0x09: # ORA immediate
				_set_a(int(_cpu["a"]) | operand)
				next_pc = pc + 2
			0x05: # ORA zero page
				_set_a(int(_cpu["a"]) | int(_ram[operand]))
				next_pc = pc + 2
			0x49: # EOR immediate
				_set_a(int(_cpu["a"]) ^ operand)
				next_pc = pc + 2
			0xC9: # CMP immediate
				_compare_a(operand)
				next_pc = pc + 2
			0x8A: # TXA
				_set_a(int(_cpu["x"]))
				next_pc = pc + 1
			0x98: # TYA
				_set_a(int(_cpu["y"]))
				next_pc = pc + 1
			0xA8: # TAY
				_set_y(int(_cpu["a"]))
				next_pc = pc + 1
			0xAA: # TAX
				_set_x(int(_cpu["a"]))
				next_pc = pc + 1
			0xBA: # TSX
				_set_x(int(_cpu["sp"]))
				next_pc = pc + 1
			0xE8: # INX
				_set_x((int(_cpu["x"]) + 1) & 0xFF)
				next_pc = pc + 1
			0xC8: # INY
				_set_y((int(_cpu["y"]) + 1) & 0xFF)
				next_pc = pc + 1
			0xCA: # DEX
				_set_x((int(_cpu["x"]) - 1) & 0xFF)
				next_pc = pc + 1
			0x48: # PHA
				_push(int(_cpu["a"]), pc, "PHA")
				next_pc = pc + 1
			0x68: # PLA
				_set_a(_pop(pc))
				next_pc = pc + 1
			0x90, 0xB0, 0xD0, 0xF0: # BCC/BCS/BNE/BEQ
				var required_mask := P_C if opcode in [0x90, 0xB0] else P_Z
				if (int(_cpu["p_known_mask"]) & required_mask) == 0:
					return _fail("ROM helper `%s` branches on an unknown status flag at `$%04X`." % [source_name, pc])
				var branch_taken := false
				match opcode:
					0x90: branch_taken = (int(_cpu["p"]) & P_C) == 0
					0xB0: branch_taken = (int(_cpu["p"]) & P_C) != 0
					0xD0: branch_taken = (int(_cpu["p"]) & P_Z) == 0
					0xF0: branch_taken = (int(_cpu["p"]) & P_Z) != 0
				var relative := operand if operand < 0x80 else operand - 0x100
				next_pc = pc + 2 + relative if branch_taken else pc + 2
			0x60: # RTS
				_rts(pc)
				if not _expect_pc(expected_return_pc): return false
				return true
			_:
				return _fail("ROM helper `%s` opcode $%02X is outside its modeled subset at `$%04X`." % [source_name, opcode, pc])
		_cpu["pc"] = next_pc & 0xFFFF
	return _fail("ROM helper `%s` exceeded its bounded instruction count." % source_name)


func _read_rom_source_byte(address: int) -> int:
	for name_variant in SOURCE_SPANS:
		var name := String(name_variant)
		var spec: Dictionary = SOURCE_SPANS[name]
		if address >= int(spec["start"]) and address < int(spec["end"]):
			var bytes: PackedByteArray = _sources.get(name, PackedByteArray())
			return int(bytes[address - int(spec["start"])]) if address - int(spec["start"]) < bytes.size() else -1
	if address >= 0xCCD2 and address < 0xCCD2 + _append_handler.size():
		return int(_append_handler[address - 0xCCD2])
	return -1


func _make_actor_worker_seed_request() -> Dictionary:
	var actor_parameter := int(_cpu["a"])
	var registers := {"a": int(_cpu["a"]), "x": int(_cpu["x"]), "y": int(_cpu["y"]),
		"p": int(_cpu["p"]), "p_known_mask": int(_cpu["p_known_mask"]),
		"sp": int(_cpu["sp"]), "pc": 0xED15}
	return {
		"schema": "rom-slot11-actor-seed-request-v1",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"source_pc": 0xED15,
		"call_pc": 0xED2A,
		"return_pc": 0xED2D,
		"active_slot": 0x09,
		"actor_parameter": actor_parameter,
		"a": actor_parameter,
		"source_sha256": ACTOR_CALLER_SHA256,
		"helper_sha256": TASK_SEED_HELPER_SHA256,
		"entry_registers": registers.duplicate(true),
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"trace_state_used": false,
		"fixture_only": false,
	}


func _build_actor_seed_pause_result() -> Dictionary:
	return {
		"ok": true,
		"status": "slot09_actor_worker_seed_ready_before_cae7",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"source_spans": _source_spans_payload(),
		"entry_pc": 0xEB8B,
		"exit_pc": 0xED15,
		"exit_bank": int(_mapper["bank_low"]),
		"active_slot": 0x09,
		"fixture_only": false,
		"entry_registers": _entry_registers.duplicate(true),
		"registers": {"a": int(_cpu["a"]), "x": int(_cpu["x"]), "y": int(_cpu["y"]),
			"sp": int(_cpu["sp"]), "pc": int(_cpu["pc"]), "p": int(_cpu["p"]),
			"p_known_mask": int(_cpu["p_known_mask"])},
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"writes": _writes.duplicate(true),
		"stack_writes": _stack_writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"calls": _calls.duplicate(true),
		"returns": _returns.duplicate(true),
		"actor_worker_seed_request": _actor_worker_seed_request.duplicate(true),
		"scenario_active": false,
		"worker_body_executed": false,
		"worker_body_bytes_read": false,
		"trace_state_used": false,
		"runtime_integrated": false,
	}


func resume_after_actor_worker_seed(slot09_snapshot: Dictionary) -> Dictionary:
	if not _configured or not _actor_seed_pause_ready or _actor_worker_seed_request.is_empty() \
			or int(_cpu.get("pc", -1)) != 0xED15:
		return _failure("A validated live `$ED15` actor-seed pause is required before resuming its caller.")
	var actor_parameter := int(_actor_worker_seed_request.get("actor_parameter", -1))
	var ram_variant: Variant = slot09_snapshot.get("ram_image", PackedByteArray())
	var stack_variant: Variant = slot09_snapshot.get("stack_page", PackedByteArray())
	if String(slot09_snapshot.get("rom_sha256", "")) != ROM_SHA256 \
			or int(slot09_snapshot.get("slot_base", -1)) != 0x09 \
			or int(slot09_snapshot.get("pc", -1)) != 0xED2D \
			or int(slot09_snapshot.get("sp", -1)) != 0x78 \
			or int(slot09_snapshot.get("a", -1)) != 0xFF \
			or int(slot09_snapshot.get("x", -1)) != 0x11 \
			or int(slot09_snapshot.get("y", -1)) != 0xC8 \
			or not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE:
		return _failure("Scheduler did not return the live slot-$09 caller at `$ED2D` with the source `$CAE7` register/stack shape.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var allowed_mutations := {0x0011: true, 0x0012: true, 0x0013: true, 0x0176: true,
		0x0177: true, 0x0178: true, 0x01C9: true, 0x01CA: true, 0x05EA: true}
	for address in range(RAM_SIZE):
		if not allowed_mutations.has(address) and int(ram[address]) != int(_ram[address]):
			return _failure("Scheduler post-seed RAM differs from the `$ED15` source state at `$%04X`." % address)
	for index in range(STACK_SIZE):
		if not allowed_mutations.has(0x0100 | index) and int(stack[index]) != int(_stack[index]):
			return _failure("Scheduler post-seed stack differs from the `$ED15` source state at `$01%02X`." % index)
	if int(ram[0x0011]) != 0xFF or int(ram[0x0012]) != 0xC8 or int(ram[0x0013]) != 0x18 \
			or int(ram[0x05EA]) != actor_parameter or int(ram[0x01C9]) != 0xFF \
			or int(ram[0x01CA]) != 0x7F or int(stack[0x76]) != 0x7F \
			or int(stack[0x77]) != 0x2C or int(stack[0x78]) != 0xED:
		return _failure("Scheduler `$CAE7` result does not contain the source-derived slot-$11 record and caller stack bytes.")
	var mapper_variant: Variant = slot09_snapshot.get("mapper", {})
	var bank_low := int(slot09_snapshot.get("bank_low", -1))
	var bank_high := int(slot09_snapshot.get("bank_high", -1))
	if mapper_variant is Dictionary:
		var snapshot_mapper: Dictionary = mapper_variant
		bank_low = int(snapshot_mapper.get("bank_low", bank_low))
		bank_high = int(snapshot_mapper.get("bank_high", bank_high))
	if bank_low != 0x0B or bank_high != 0x0C:
		return _failure("Scheduler changed the active parent mapper before the `$ED2D` caller continuation.")
	_ram = ram.duplicate()
	_stack = stack.duplicate()
	_cpu = {"a": int(slot09_snapshot["a"]), "x": int(slot09_snapshot["x"]),
		"y": int(slot09_snapshot["y"]), "sp": int(slot09_snapshot["sp"]),
		"pc": int(slot09_snapshot["pc"]), "p": int(slot09_snapshot.get("p", 0)),
		"p_known_mask": int(slot09_snapshot.get("p_known_mask", 0)),
		"bank_low": bank_low, "bank_high": bank_high}
	_mapper["bank_low"] = bank_low
	_mapper["bank_high"] = bank_high
	_mapper["bank_registers"][6] = bank_low
	_mapper["bank_registers"][7] = bank_high
	_entry_registers = {"a": int(_cpu["a"]), "x": int(_cpu["x"]), "y": int(_cpu["y"]),
		"p": int(_cpu["p"]), "p_known_mask": int(_cpu["p_known_mask"]),
		"sp": int(_cpu["sp"]), "pc": int(_cpu["pc"])}
	_writes.clear()
	_stack_writes.clear()
	_mapper_writes.clear()
	_instruction_pcs.clear()
	_calls.clear()
	_returns.clear()
	if not _execute_scenario35_resume_tail():
		return _stopped("unsupported_resume_state", int(_cpu.get("pc", -1)), error_message)
	if not _execute_root_prefix_after_ec08():
		return _stopped("unsupported_resume_state", int(_cpu.get("pc", -1)), error_message)
	return {
		"ok": true,
		"status": "slot09_actor_seed_continuation_to_worker_vector",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"source_spans": _source_spans_payload(),
		"active_slot": 0x09,
		"fixture_only": false,
		"entry_pc": 0xED2D,
		"caller_entry_pc": 0xEB8B,
		"exit_pc": int(_cpu["pc"]),
		"exit_bank": int(_mapper["bank_low"]),
		"entry_registers": _entry_registers.duplicate(true),
		"registers": {"a": int(_cpu["a"]), "x": int(_cpu["x"]), "y": int(_cpu["y"]),
			"sp": int(_cpu["sp"]), "pc": int(_cpu["pc"]), "p": int(_cpu["p"]),
			"p_known_mask": int(_cpu["p_known_mask"])},
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"writes": _writes.duplicate(true),
		"stack_writes": _stack_writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"calls": _calls.duplicate(true),
		"returns": _returns.duplicate(true),
		"source_actor_seed_request": _actor_worker_seed_request.duplicate(true),
		"pending_worker_call": {"source_pc": 0xEBB0, "return_word": 0xEBB2,
			"return_pc": 0xEBB3, "target_pc": 0x86F8, "target_bank": 0x18},
		"worker_body_executed": false,
		"worker_body_bytes_read": false,
		"trace_state_used": false,
		"runtime_integrated": false,
	}


func _execute_scenario35_resume_tail() -> bool:
	var source: PackedByteArray = _sources.get("scenario_resume", PackedByteArray())
	if source.size() != 46 or _sha256(source) != String(SOURCE_SPANS["scenario_resume"]["sha256"]):
		return _fail("Scenario-$35 post-seed caller tail failed its ROM source hash.")
	var instruction_rows := [
		[0xED2D, [0xAD, 0x2B, 0x05], "load", 0x052B], [0xED30, [0x09, 0x80], "ora", 0x80],
		[0xED32, [0x8D, 0x32, 0x05], "store", 0x0532], [0xED35, [0xAD, 0x2C, 0x05], "load", 0x052C],
		[0xED38, [0x09, 0x80], "ora", 0x80], [0xED3A, [0x8D, 0x36, 0x05], "store", 0x0536],
		[0xED3D, [0xAD, 0x2D, 0x05], "load", 0x052D], [0xED40, [0x09, 0x80], "ora", 0x80],
		[0xED42, [0x8D, 0x34, 0x05], "store", 0x0534], [0xED45, [0xAD, 0x30, 0x05], "load", 0x0530],
		[0xED48, [0x8D, 0x2E, 0x05], "store", 0x052E], [0xED4B, [0xAD, 0x31, 0x05], "load", 0x0531],
		[0xED4E, [0x8D, 0x2F, 0x05], "store", 0x052F], [0xED51, [0xA9, 0x00], "immediate", 0x00],
		[0xED53, [0x85, 0x8E], "store", 0x008E], [0xED55, [0xA9, 0x01], "immediate", 0x01],
		[0xED57, [0x8D, 0x69, 0x04], "store", 0x0469],
	]
	for row_variant in instruction_rows:
		var row: Array = row_variant
		var pc := int(row[0])
		var opcode_bytes: Array = row[1]
		if not _expect_span("scenario_resume", pc, row[1]): return false
		_record(pc)
		match String(row[2]):
			"load": _set_a(int(_ram[int(row[3])]))
			"ora": _set_a(int(_cpu["a"]) | int(row[3]))
			"immediate": _set_a(int(row[3]))
			"store": _write_ram(int(row[3]), int(_cpu["a"]), pc)
		_cpu["pc"] = pc + opcode_bytes.size()
	if not _expect_span("scenario_resume", 0xED5A, [0x60]): return false
	_record(0xED5A)
	_rts(0xED5A)
	return _expect_pc(0xEB9E)


func _execute_scenario_pointer_reader() -> bool:
	# `$8000->$8006` indexes `$89BF` with the live scenario selector. Only
	# manifest-preserved scenario entries supported by this route are accepted.
	var scenario_id := int(_ram[0x0518])
	var pointer_keys := {
		0x18: "scenario_pointer_18", 0x1C: "scenario_pointer_1C",
		0x1E: "scenario_pointer_1E", 0x2E: "scenario_pointer_2E", 0x35: "scenario_pointer_35",
		0x36: "scenario_pointer_36", 0x38: "scenario_pointer_38",
		0x44: "scenario_pointer_44",
	}
	var expected_pointers := {
		0x18: 0x9E3E, 0x1C: 0x9BE3, 0x1E: 0xB7DA,
		0x2E: 0xB74E, 0x35: 0xB7CD, 0x36: 0xB7E4, 0x38: 0xB7C6, 0x44: 0xB7D5,
	}
	if not pointer_keys.has(scenario_id):
		return _fail("The live scenario selector is unsupported (id=$%02X)." % scenario_id)
	var pointer_key: String = pointer_keys[scenario_id]
	var pointer_bytes: PackedByteArray = _sources.get(pointer_key, PackedByteArray())
	var expected_pointer: int = expected_pointers[scenario_id]
	if pointer_bytes.size() != 2 \
			or (int(pointer_bytes[0]) | (int(pointer_bytes[1]) << 8)) != expected_pointer:
		return _fail("The live scenario selector or its manifest-checked `$89BF` pointer entry is unsupported (id=$%02X bytes=%s expected=$%04X)." % [
			scenario_id, pointer_bytes.hex_encode(), expected_pointer])
	for pc in [0x8000, 0x8006, 0x8008, 0x800B, 0x800C, 0x800D, 0x8010]:
		_record(pc)
	_write_ram(0x005D, 0xBF, 0x8012)
	_write_ram(0x005E, 0x89, 0x8014)
	for pc in [0x8016, 0x8018, 0x8019, 0x801A]:
		_record(pc)
	_write_ram(0x005E, int(pointer_bytes[1]), 0x801C)
	_write_ram(0x005D, int(pointer_bytes[0]), 0x801E)
	_record(0x8020)
	_rts(0x8020)
	return _expect_pc(0xEC2C)


func _execute_scenario1c_bb4f_to_f2_target_handoff() -> bool:
	var live_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	var live_044e := int(_ram[0x044E])
	if live_044e not in [0x01, 0x02]:
		return _fail("Scenario-$1C `$F3 $84` handoff requires the live ROM-supported `$044E=$01/$02` selector.")
	var expected_selector_x := live_044e - 1
	var expected_resume_offset := 0x09 if live_044e == 0x01 else 0x0C
	var expected_f2_target := 0xB49E if live_044e == 0x01 else 0xB4B6
	var expected_skip_byte := 0x02 if live_044e == 0x01 else 0x04
	var child_runtime: RefCounted = SCENARIO_RUNTIME.new()
	if int(_ram[0x0518]) != 0x1C or live_pointer != 0xBB4F \
			or int(_ram[0x0522]) != 0x02 \
			or _ram.slice(0x051A, 0x051C) != PackedByteArray([0xE8, 0x9B]):
		return _fail("Scenario-$1C `$BB4F` return requires the observed live selector, pointer, and continuation stack.")
	var child_start: Dictionary = child_runtime.begin_scenario_1c_fa_branch_from_live_source(0xBB4B, _ram)
	var child_tokens: Array = child_start.get("reader_tokens", [])
	if not bool(child_start.get("ok", false)) or child_tokens.size() != 2 \
			or int(child_tokens[0].get("opcode", -1)) != -1 \
			or String(child_tokens[0].get("kind", "")) != "event_record" \
			or child_tokens[0].get("raw_bytes", PackedByteArray()) != PackedByteArray([0x30, 0x1F, 0x4C, 0x00]) \
			or int(child_tokens[1].get("opcode", -1)) != 0xFB:
		return _fail("Scenario-$1C `$BB4F` does not match the already-consumed `$BB4B` child record and `$FB`.")
	var continuation: RefCounted = SCENARIO_CONTINUATION_STACK.new()
	var stack_result: Dictionary = continuation.execute_fb(0xBB4B, 5, 2,
		_ram.slice(0x051A, 0x0522))
	if not bool(stack_result.get("ok", false)) \
			or String(stack_result.get("status", "")) != "subroutine_return" \
			or int(stack_result.get("script_pointer_after", -1)) != 0x9BE8 \
			or int(stack_result.get("stack_depth_after", -1)) != 0:
		return _fail("Scenario-$1C `$BB4F` ROM stack model did not restore the live `$9BE8` caller cursor.")
	var reader: PackedByteArray = _sources.get("bank10_reader", PackedByteArray())
	var event_reader: PackedByteArray = _sources.get("event_reader", PackedByteArray())
	if reader.size() != 63 or event_reader.size() != 88 \
			or _sha256(event_reader) != String(SOURCE_SPANS["event_reader"]["sha256"]):
		return _fail("Scenario-$1C `$BB4F` handoff lacks the hash-checked bank-$10 reader/event loop.")
	# Execute the same bank-$10 reader initialization used by the ordinary source route.
	for pc in [0x8003, 0x8021, 0x8024, 0x8027, 0x802A, 0x802C,
			0x802F, 0x8031, 0x8034, 0x8037, 0x803A, 0x803D]:
		_record(pc)
	_write_ram(0x052A, int(_ram[0x0517]), 0x8024)
	_write_ram(0x0516, int(_ram[0x0516]) & 0xFB, 0x802C)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), 0, int(address_pc[1]))
	# `$BB4B`'s event record has already been applied. The live reader is positioned
	# on its final `$FB`; only execute that return, then follow the restored root.
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	if int(_cpu["y"]) != 0 or _ram.slice(0x005D, 0x005F) != PackedByteArray([0x4F, 0xBB]):
		return _fail("Scenario-$1C event reader did not address the live `$BB4F` `$FB` byte.")
	_set_a(0xFB)
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	if (int(_cpu["p"]) & P_C) == 0:
		return _fail("Scenario-$1C `$BB4F` did not enter the ROM opcode dispatcher.")
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	if not _execute_scenario_opcode_dispatch(): return false
	if int(_cpu["pc"]) != 0x804C \
			or (int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)) != 0x9BE8 \
			or int(_ram[0x0522]) != 0 or int(_ram[0x003A]) != 0:
		return _fail("Scenario-$1C `$FB` did not restore `$9BE8`, depth zero, and cursor zero.")
	var root := FileAccess.get_file_as_bytes(PASS_SCENARIO_1C_ROOT + "scenario_1C.bin")
	var parse_context := {"ram_0441": int(_ram[0x0441]), "ram_044E": int(_ram[0x044E]),
		"ram_043B": int(_ram[0x043B]), "ram_043C": int(_ram[0x043C]),
		"ram_0516": int(_ram[0x0516]), "ram_0638": int(_ram[0x0638])}
	var fd00_resolver: RefCounted = SCENARIO36_FD00_RESOLVER.new()
	if not fd00_resolver.configure():
		return _fail("Scenario-$1C root branch could not configure `$FD $00`: " + fd00_resolver.last_error)
	var fd00_result: Dictionary = fd00_resolver.execute(_ram)
	if not bool(fd00_result.get("ok", false)):
		return _fail("Scenario-$1C root branch rejected live holder state: " + String(fd00_result.get("error", "unknown error")))
	parse_context["ram_fd00_mirror_flag"] = int(fd00_result["mirror_flag"])
	var root_parse: Dictionary = SCENARIO_BYTECODE_READER.read_project_scenario(0x1C, parse_context)
	var selected_f3: Dictionary = {}
	var selected_f2: Dictionary = {}
	var selected_f2_offset := expected_resume_offset
	for token_variant in root_parse.get("tokens", []):
		if not token_variant is Dictionary: continue
		var token: Dictionary = token_variant
		if int(token.get("opcode", -1)) == 0xF3 and int(token.get("byte_offset", -1)) == 5:
			selected_f3 = token
		if int(token.get("opcode", -1)) == 0xF2 and int(token.get("byte_offset", -1)) == selected_f2_offset:
			selected_f2 = token
	if selected_f3.is_empty() or selected_f2.is_empty() \
			or String(selected_f3.get("status", "")) != "selected" \
			or int(selected_f3.get("ram_044E", -1)) != live_044e \
			or int(selected_f3.get("selector_result_x", -1)) != expected_selector_x \
			or int(selected_f3.get("skip_byte", -1)) != expected_skip_byte \
			or int(selected_f3.get("resume_byte_offset", -1)) != expected_resume_offset \
			or int(selected_f3.get("selected_f2_pointer", -1)) != expected_f2_target \
			or int(selected_f2.get("target_cpu_address", -1)) != expected_f2_target:
		return _fail("Scenario-$1C root F3/F2 parser did not follow the live `$044E` source branch.")
	# The event reader loops at $804C. F3 $84 selects $8259 and its source-derived
	# skip byte; its handler replaces the current script pointer with the selected F2.
	_record(0x804C)
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	_set_a(root[5])
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	if not _execute_scenario_opcode_dispatch(): return false
	if int(_cpu["pc"]) != 0x804C \
			or (int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)) != 0x9BE3 + expected_resume_offset \
			or int(_ram[0x003A]) != 0:
		return _fail("Scenario-$1C `$F3 $84` did not resume at its live branch's F2 source with a cleared cursor.")
	# The selected F2 operand resolves one of the manifest-pinned root prefixes.
	_record(0x803F)
	_set_y(int(_ram[0x003A]))
	_record(0x8041)
	_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
	_record(0x8043)
	_set_a(root[expected_resume_offset])
	_record(0x8045)
	_compare_a(0xF0)
	_record(0x8047)
	_record(0x8049)
	_jsr(0x8049, 0x80A9)
	if not _execute_scenario_opcode_dispatch(): return false
	if int(_cpu["pc"]) != 0x804C \
			or (int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)) != expected_f2_target \
			or int(_ram[0x003A]) != 0:
		return _fail("Scenario-$1C `$F2` did not install the live `$044E`-selected ROM pointer.")
	_scenario_runtime_events = [
		{"kind": "fb_subroutine_return", "source_pointer": 0xBB4F,
			"source_bytes": PackedByteArray([0xFB]), "result": stack_result.duplicate(true),
			"already_applied_record": PackedByteArray([0x30, 0x1F, 0x4C, 0x00])},
		{"kind": "f3_nested_branch", "source_pointer": 0x9BE8,
			"source_bytes": PackedByteArray([0xF3, 0x84, 0x02]),
			"selector_result_x": int(selected_f3["selector_result_x"]),
			"selected_target": int(selected_f3["selected_f2_pointer"])},
		{"kind": "f2_external_branch_entry", "source_pointer": 0x9BE3 + expected_resume_offset,
			"source_bytes": PackedByteArray([0xF2,
				int(root[expected_resume_offset + 1]), int(root[expected_resume_offset + 2])]),
			"target_pointer": expected_f2_target,
			"target_prefix_sha256": PASS_SCENARIO_1C_B49E_SHA256 if expected_f2_target == 0xB49E \
				else PASS_SCENARIO_1C_B4B6_SHA256},
	]
	return true


func _execute_scenario_reader_and_callback_seed(caller_return_pc: int = 0xEC74) -> bool:
	# Require the ROM parser to derive this scenario's stream and callback contract
	# from the live `$0518` selector and `$5D/$5E` pointer resolved above.
	var scenario_id := int(_ram[0x0518])
	var source_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	var scenario18_root_pointer := source_pointer
	var scenario1c_f2_branch_selected := false
	var scenario1c_callback63_b4bd_terminal_cursor := scenario_id == 0x1C \
		and source_pointer == 0xB4BD and caller_return_pc == 0xED84 \
		and _is_scenario1c_callback63_b4bd_wait_terminal_profile(_ram)
	if scenario_id == 0x18 and caller_return_pc == 0xED84 and source_pointer == 0xAF58:
		return _execute_scenario18_branch_terminal_worker()
	if scenario_id == 0x1C and caller_return_pc == 0xED84 and source_pointer == 0xB4A5:
		return _execute_scenario1c_b49e_root_terminal_worker()
	if scenario_id == 0x1E and caller_return_pc == 0xED84 and source_pointer == 0xB7E3:
		return _execute_scenario1e_root_terminal_worker()
	if scenario_id == 0x44 and caller_return_pc == 0xED84 and source_pointer == 0xB7D9:
		return _execute_scenario44_root_terminal_worker()
	if scenario_id == 0x1C and caller_return_pc == 0xED84 and source_pointer == 0xBB4F:
		if not _execute_scenario1c_bb4f_to_f2_target_handoff(): return false
		source_pointer = int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
		scenario1c_f2_branch_selected = source_pointer in [0xB49E, 0xB4B6]
		if not scenario1c_f2_branch_selected:
			return _fail("Scenario-$1C `$BB4F` continuation did not advance to a manifest-pinned live `$F3 $84` target.")
	var scenario_runtime: RefCounted = SCENARIO_RUNTIME.new()
	var live_context: Dictionary = {"ram_05FB": int(_ram[0x05FB])} if scenario_id == 0x1E else {}
	var scenario18_fd00_result: Dictionary = {}
	if scenario_id == 0x18:
		for address: int in [0x0441, 0x044E, 0x043C, 0x0516, 0x0638]:
			live_context["ram_%04X" % address] = int(_ram[address])
		var fd00_resolver: RefCounted = SCENARIO36_FD00_RESOLVER.new()
		if not fd00_resolver.configure():
			return _fail("Scenario-$18 `$FD $00` source setup failed: " + fd00_resolver.last_error)
		scenario18_fd00_result = fd00_resolver.execute(_ram)
		if not bool(scenario18_fd00_result.get("ok", false)):
			return _fail("Scenario-$18 `$FD $00` source stopped on live RAM: " \
				+ String(scenario18_fd00_result.get("error", "unknown source state")))
		live_context["ram_fd00_mirror_flag"] = int(scenario18_fd00_result["mirror_flag"])
	elif scenario_id == 0x1C:
		if scenario1c_f2_branch_selected:
			live_context["continuation_depth"] = 0
		elif scenario1c_callback63_b4bd_terminal_cursor:
			live_context["continuation_depth"] = 0
			live_context["ram_0518"] = int(_ram[0x0518])
			live_context["ram_0524"] = int(_ram[0x0524])
		for address: int in [0x0441, 0x044E, 0x043B, 0x043C, 0x0516, 0x0638]:
			live_context["ram_%04X" % address] = int(_ram[address])
		var fd00_resolver: RefCounted = SCENARIO36_FD00_RESOLVER.new()
		if not fd00_resolver.configure():
			return _fail("Scenario-$1C `$FD $00` source setup failed: " + fd00_resolver.last_error)
		var scenario1c_fd00_result: Dictionary = fd00_resolver.execute(_ram)
		if not bool(scenario1c_fd00_result.get("ok", false)):
			return _fail("Scenario-$1C `$FD $00` source stopped on live RAM: " \
				+ String(scenario1c_fd00_result.get("error", "unknown source state")))
		live_context["ram_fd00_mirror_flag"] = int(scenario1c_fd00_result["mirror_flag"])
	var started: Dictionary = scenario_runtime.begin_from_live_scenario_pointer(scenario_id,
		source_pointer, live_context)
	if not bool(started.get("ok", false)) \
			or int(started.get("scenario_id", -1)) != scenario_id \
			or int(started.get("source_pointer_cpu", -1)) != source_pointer:
		return _fail("ROM scenario reader rejected the live selector/pointer: %s" % str(started))
	if not scenario1c_f2_branch_selected:
		for pc in [0x8003, 0x8021, 0x8024, 0x8027, 0x802A, 0x802C,
				0x802F, 0x8031, 0x8034, 0x8037, 0x803A, 0x803D]:
			_record(pc)
		_write_ram(0x052A, int(_ram[0x0517]), 0x8024)
		_write_ram(0x0516, int(_ram[0x0516]) & 0xFB, 0x802C)
		for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
				[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
			_write_ram(int(address_pc[0]), 0, int(address_pc[1]))
	var source_events: Array[Dictionary] = []
	if scenario1c_f2_branch_selected:
		for event_variant in _scenario_runtime_events:
			if event_variant is Dictionary:
				source_events.append((event_variant as Dictionary).duplicate(true))
	var scenario1c_record_result: Dictionary = {}
	if scenario1c_callback63_b4bd_terminal_cursor:
		var callback63_terminal: Dictionary = scenario_runtime.advance_one()
		var callback63_terminal_branch: PackedByteArray = _sources.get(
			"scenario_1C_branch_B4B6", PackedByteArray())
		if String(started.get("status", "")) != "scenario1c_b4bd_fb_cursor_admitted" \
				or int(started.get("source_byte_index", -1)) != 7 \
				or not bool(callback63_terminal.get("ok", false)) \
				or String(callback63_terminal.get("status", "")) != "root_scenario_terminated" \
				or int(callback63_terminal.get("source_byte_offset", -1)) != 7 \
				or int(callback63_terminal.get("source_byte_index_after", -1)) != 8 \
				or int(callback63_terminal.get("terminal_handler_cpu_address", -1)) != 0x80CF \
				or callback63_terminal_branch != PackedByteArray([0xF9, 0x11, 0x2C, 0x38, 0x63, 0x7A, 0x58, 0xFB]) \
				or callback63_terminal_branch[7] != 0xFB \
				or int(_ram[0x003A]) != 0:
			return _fail("Scenario-$1C callback-$63 `$B4BD` root cursor differs from the checked map-$51 `$FB` state: %s" % str(callback63_terminal))
		for pc in [0x803F, 0x8041, 0x8043]:
			_record(pc)
		_set_y(int(_ram[0x003A]))
		_write_ram(0x003A, (int(_ram[0x003A]) + 1) & 0xFF, 0x8041)
		if int(_cpu["y"]) != 0:
			return _fail("Scenario-$1C callback-$63 `$803F` did not read the `$B4BD` terminal byte at cursor zero.")
		_set_a(int(callback63_terminal_branch[7]))
		_record(0x8045)
		_compare_a(0xF0)
		_record(0x8047)
		if (int(_cpu["p"]) & P_C) == 0 or int(_cpu["a"]) != 0xFB:
			return _fail("Scenario-$1C callback-$63 `$B4BD` did not take the ROM `$F0-$FF` opcode path.")
		_record(0x8049)
		_jsr(0x8049, 0x80A9)
		_scenario_runtime_events = [{"kind": "root_terminator", "source_pointer": 0xB4BD,
			"source_bytes": PackedByteArray([0xFB]), "result": callback63_terminal.duplicate(true),
			"parent_pointer": 0xB4B6, "parent_offset": 7,
			"parent_sha256": PASS_SCENARIO_1C_B4B6_SHA256}]
		return _execute_scenario_opcode_dispatch()
	elif scenario_id == 0x1C and scenario1c_f2_branch_selected:
		var f9_result: Dictionary = scenario_runtime.advance_one()
		var f9_writes: Dictionary = f9_result.get("ram_writes", {})
		var f9_operand_bytes := PackedByteArray([0x1D, 0x2C]) if source_pointer == 0xB49E \
			else PackedByteArray([0x11, 0x2C])
		var record_bytes := PackedByteArray([0x3C, 0x01, 0x78, 0x58]) if source_pointer == 0xB49E \
			else PackedByteArray([0x38, 0x63, 0x7A, 0x58])
		if not bool(f9_result.get("ok", false)) \
				or int(f9_result.get("opcode", -1)) != 0xF9 \
				or int(f9_result.get("source_byte_offset", -1)) != 0 \
				or int(f9_result.get("operand_word_little_endian", -1)) != (int(f9_operand_bytes[0]) | (int(f9_operand_bytes[1]) << 8)) \
				or int(f9_result.get("source_byte_index_after", -1)) != 3 \
				or f9_writes != {"$0530": int(f9_operand_bytes[0]), "$0531": int(f9_operand_bytes[1])}:
			return _fail("Scenario-$1C selected `$F2` target `$F9` operands differ from its pinned ROM bytes: %s" % str(f9_result))
		_record(0x803F)
		_write_ram(0x003A, 1, 0x8041)
		_record(0x8809)
		_write_ram(0x003A, 2, 0x8809)
		_write_ram(0x0530, int(f9_operand_bytes[0]), 0x880C)
		_record(0x8812)
		_write_ram(0x0531, int(f9_operand_bytes[1]), 0x8812)
		_write_ram(0x003A, 3, 0x8041)
		source_events.append({"kind": "f9_operand", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xF9, int(f9_operand_bytes[0]), int(f9_operand_bytes[1])]),
			"ram_writes": f9_writes.duplicate(true),
			"handler_cpu_address": 0x8809, "handler_file_offset": 0x020819})
		scenario1c_record_result = scenario_runtime.advance_one()
		var branch_assignments: Dictionary = scenario1c_record_result.get("ram_state", {})
		if not bool(scenario1c_record_result.get("ok", false)) \
				or String(scenario1c_record_result.get("status", "")) != "callback_task_seed_requested" \
				or int(scenario1c_record_result.get("source_byte_offset", -1)) != 3 \
				or int(scenario1c_record_result.get("source_byte_index_after", -1)) != 7 \
				or branch_assignments.get("$0523", -1) != int(record_bytes[0]) \
				or branch_assignments.get("$0524", -1) != int(record_bytes[1]) \
				or branch_assignments.get("$0528", -1) != int(record_bytes[2]) \
				or branch_assignments.get("$0529", -1) != 0x58:
			return _fail("Scenario-$1C selected `$F2` event record did not produce its ROM-derived callback seed: %s" % str(scenario1c_record_result))
		source_events.append({"kind": "event_record", "source_pointer": source_pointer + 3,
			"source_bytes": record_bytes,
			"seed_contract": scenario1c_record_result.get("seed_contract_fields", {}).duplicate(true)})
	elif scenario_id == 0x1C:
		if source_pointer != 0x9BE3 or int(_ram[0x003A]) != 0:
			return _fail("Scenario-$1C initial reader requires its live `$9BE3` root pointer and zero byte cursor.")
		var fd_result: Dictionary = scenario_runtime.advance_one()
		var fd_writes: Dictionary = fd_result.get("ram_writes", {})
		var fd_flag := int(fd_writes.get("$052A", -1))
		if not bool(fd_result.get("ok", false)) \
				or String(fd_result.get("status", "")) != "scenario1c_fd00_live_result_applied" \
				or int(fd_result.get("handler_target_cpu_address", -1)) != 0x8877 \
				or fd_flag not in [0x00, 0x40]:
			return _fail("Scenario-$1C `$FD $00` did not apply the live holder/record result: %s" % str(fd_result))
		for pc in [0x803F, 0x8041, 0x885D, 0x8861, 0x8869]:
			_record(pc)
		if int(_ram[0x003A]) != 0:
			return _fail("Scenario-$1C `$FD $00` began with a nonzero byte cursor.")
		_write_ram(0x003A, 1, 0x8041)
		_write_ram(0x003A, 2, 0x8861)
		_write_ram(0x052A, fd_flag, 0x8869)
		source_events.append({"kind": "fd_operand", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xFD, 0x00]),
			"handler_target_cpu_address": 0x8877,
			"ram_writes": {"$052A": fd_flag},
			"resolver": "live RAM through pinned $8877/$C50C/$CD89/$C536 source"})
		var root_tokens: Array = started.get("reader_tokens", [])
		if root_tokens.size() < 2 or not root_tokens[1] is Dictionary:
			return _fail("Scenario-$1C root parser did not expose the pinned `$FA $3E $9F` token.")
		var fa_token: Dictionary = root_tokens[1]
		var nested_variant: Variant = fa_token.get("f3_dispatch_tokens", [])
		if not nested_variant is Array or (nested_variant as Array).size() != 2:
			return _fail("Scenario-$1C `$FA` did not resolve both ROM `$F3` dispatches.")
		var nested_tokens: Array = nested_variant
		var outer_token: Dictionary = nested_tokens[0]
		var inner_token: Dictionary = nested_tokens[1]
		if String(outer_token.get("status", "")) != "external_continuation_required" \
				or int(outer_token.get("incoming_ram_043B", -1)) != 0x01 \
				or int(outer_token.get("selector_result", -1)) != 0 \
				or int(outer_token.get("selected_target_cpu_address", -1)) != 0x9F4A \
				or String(inner_token.get("status", "")) != "external_continuation_required" \
				or int(inner_token.get("selector_result", -1)) != 0 \
				or int(inner_token.get("selected_target_cpu_address", -1)) != 0xBB4B:
			return _fail("Scenario-$1C nested `$F3` handlers selected an unsupported live branch: %s" % str(nested_tokens))
		var continuation: RefCounted = SCENARIO_CONTINUATION_STACK.new()
		var root_source: PackedByteArray = _sources.get("scenario_1C", PackedByteArray())
		var stack_memory := _ram.slice(0x051A, 0x0522)
		var fa_stack_result: Dictionary = continuation.execute_fa(root_source, 0x9BE3, 3,
			int(_ram[0x0522]), stack_memory)
		if not bool(fa_stack_result.get("ok", false)) \
				or int(fa_stack_result.get("target_pointer", -1)) != 0x9F3E \
				or int(fa_stack_result.get("return_pointer", -1)) != 0x9BE8 \
				or int(fa_stack_result.get("stack_depth_after", -1)) != int(_ram[0x0522]) + 2:
			return _fail("Scenario-$1C `$FA` caller-stack result differs from pinned ROM: %s" % str(fa_stack_result))
		_record(0x881A)
		var stack_depth_before := int(_ram[0x0522])
		var stack_after: PackedByteArray = fa_stack_result.get("stack_memory_after", PackedByteArray())
		if stack_after.size() != 8:
			return _fail("Scenario-$1C `$FA` stack executor returned an invalid 8-byte source stack.")
		# The ROM writes only the pushed pointer's two bytes. Preserve stale stack
		# bytes; `$8825/$882C` are the actual indexed stores and `$8831` updates depth.
		_write_ram(0x051A + stack_depth_before, int(stack_after[stack_depth_before]), 0x8825)
		_write_ram(0x051B + stack_depth_before, int(stack_after[stack_depth_before + 1]), 0x882C)
		_write_ram(0x0522, int(fa_stack_result["stack_depth_after"]), 0x8831)
		_record(0x80F6)
		_write_ram(0x005E, 0x9F, 0x80FC)
		_write_ram(0x005D, 0x3E, 0x80FE)
		_write_ram(0x003A, 0, 0x8102)
		source_events.append({"kind": "fa_subroutine_call", "source_pointer": 0x9BE3,
			"source_bytes": PackedByteArray([0xFA, 0x3E, 0x9F]),
			"target_pointer": 0x9F3E, "return_pointer": 0x9BE8,
			"stack_depth_after": int(_ram[0x0522])})
		var wrapper: PackedByteArray = _sources.get("scenario_1C_fa_wrapper", PackedByteArray())
		var selector10: PackedByteArray = _sources.get("scenario_1C_f3_selector10", PackedByteArray())
		var selector1e: PackedByteArray = _sources.get("scenario_1C_f3_selector1E", PackedByteArray())
		if wrapper.size() != 22 or selector10.size() != 14 or selector1e.size() != 9 \
				or _sha256(selector10) != "e4c9d33a634f25658a0a01bfc64004d2db1a2d1ef7ecb2628ce2c0b02b99f71e" \
				or _sha256(selector1e) != "3ecd15e61abde841fad2c69ced09a68ec0856d74fb3cd0ab12b045d6429d5a63":
			return _fail("Scenario-$1C nested selector sources failed their ROM-pinned byte checks.")
		_record(0x8105)
		_record(0x816E)
		_record(0x836E)
		_set_x(0)
		var outer_pointer := int(wrapper[2]) | (int(wrapper[3]) << 8)
		if outer_pointer != 0x9F4A:
			return _fail("Scenario-$1C `$836E` live `$043B=$01` path did not resolve `$9F4A`.")
		_write_ram(0x005D, outer_pointer & 0xFF, 0x8124)
		_write_ram(0x005E, outer_pointer >> 8, 0x8128)
		_write_ram(0x003A, 0, 0x812C)
		_record(0x8105)
		_record(0x816E)
		_record(0x8401)
		var inner_selector := int(_ram[0x043C]) & 0x7F
		if inner_selector != 0:
			return _fail("Scenario-$1C `$8401` supports only the live `$043C&$7F=$00` branch here.")
		var inner_table_offset := 14 + inner_selector * 2
		var child_pointer := int(wrapper[inner_table_offset]) | (int(wrapper[inner_table_offset + 1]) << 8)
		if child_pointer != 0xBB4B:
			return _fail("Scenario-$1C `$8401` live selector did not resolve the pinned `$BB4B` branch.")
		_write_ram(0x005D, child_pointer & 0xFF, 0x8124)
		_write_ram(0x005E, child_pointer >> 8, 0x8128)
		_write_ram(0x003A, 0, 0x812C)
		source_events.append({"kind": "f3_nested_branch", "source_pointer": 0x9F3E,
			"wrapper_sha256": PASS_SCENARIO_1C_FA_WRAPPER_SHA256,
			"selector10_return_x": 0, "selector10_target": 0x9F4A,
			"selector1e_result": inner_selector, "selected_target": child_pointer})
		var child_runtime: RefCounted = SCENARIO_RUNTIME.new()
		var child_start: Dictionary = child_runtime.begin_scenario_1c_fa_branch_from_live_source(child_pointer, _ram)
		if not bool(child_start.get("ok", false)):
			return _fail("Scenario-$1C selected child stream failed source admission: " + String(child_start.get("error", "unknown error")))
		scenario1c_record_result = child_runtime.advance_one()
		if not bool(scenario1c_record_result.get("ok", false)) \
				or String(scenario1c_record_result.get("status", "")) != "callback_task_seed_requested":
			return _fail("Scenario-$1C `$BB4B` event record did not produce its source-derived seed contract: %s" % str(scenario1c_record_result))
		for pc in [0xBB4B, 0x803F, 0x804F, 0x8069, 0x8079, 0x8089, 0x808C]:
			_record(pc)
		_write_ram(0x0523, 0x30, 0x804F)
		_write_ram(0x0524, 0x1F, 0x8069)
		_write_ram(0x0528, 0x4C, 0x8079)
		_write_ram(0x0529, 0x00, 0x8089)
		_write_ram(0x003A, 4, 0x808C)
		source_pointer = child_pointer
		scenario_runtime = child_runtime
	elif scenario_id == 0x18:
		var fd_result: Dictionary = scenario_runtime.advance_one()
		var fd_writes: Dictionary = fd_result.get("ram_writes", {})
		if not bool(fd_result.get("ok", false)) \
				or int(fd_result.get("opcode", -1)) != 0xFD \
				or int(fd_result.get("operand", -1)) != 0x00 \
				or int(fd_result.get("handler_target_cpu_address", -1)) != 0x8877 \
				or int(fd_writes.get("$052A", -1)) != int(scenario18_fd00_result.get("mirror_flag", -2)):
			return _fail("Scenario-$18 `$FD $00` did not apply the shared ROM `$8877` result from live RAM.")
		_record(0x803F)
		_write_ram(0x003A, 1, 0x8041)
		_record(0x885D)
		_write_ram(0x003A, 2, 0x8861)
		_write_ram(0x052A, int(fd_writes["$052A"]), 0x8869)
		source_events.append({"kind": "fd_operand", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xFD, 0x00]), "ram_writes": fd_writes.duplicate(true),
			"rom_resolver": scenario18_fd00_result.duplicate(true)})
		var f3_result: Dictionary = scenario_runtime.advance_one()
		if not bool(f3_result.get("ok", false)) \
				or String(f3_result.get("status", "")) != "scenario18_f3_branch_selected" \
				or int(f3_result.get("source_byte_offset", -1)) != 2 \
				or int(f3_result.get("ram_044E", -1)) != int(_ram[0x044E]):
			return _fail("Scenario-$18 `$F3 $B4` branch did not follow live RAM `$044E`: %s" % str(f3_result))
		var resume_offset := int(f3_result.get("source_byte_index_after", -1))
		var scenario18_external_branch_pointer := -1
		if resume_offset not in [7, 17]:
			return _fail("Scenario-$18 `$F3 $B4` resumed at unsupported source offset %d." % resume_offset)
		var skip_table_offset := int(f3_result.get("skip_byte_offset", -1))
		var skip_byte := int(f3_result.get("skip_byte", -1))
		var skip_table_pointer := (source_pointer + skip_table_offset) & 0xFFFF
		var skipped_source_pointer := (skip_table_pointer + skip_byte) & 0xFFFF
		var expected_skipped_pointer := (scenario18_root_pointer + resume_offset) & 0xFFFF
		if skip_table_offset < 0 or skip_byte < 0 \
				or skipped_source_pointer != expected_skipped_pointer:
			return _fail("Scenario-$18 `$F3 $B4` skip operands do not resolve to the live ROM source pointer.")
		# The ROM's high-bit handler first advances to the selected skip byte at
		# $8117, adds that byte at $8124, then clears $3A at $812C. The parser's
		# resume offset is a logical source offset; $3A itself is reset to zero.
		_record(0x8117)
		_write_ram(0x005D, skip_table_pointer & 0xFF, 0x8117)
		if (skip_table_pointer >> 8) != (source_pointer >> 8):
			_record(0x811B)
			_write_ram(0x005E, (skip_table_pointer >> 8) & 0xFF, 0x811B)
		_record(0x8124)
		_write_ram(0x005D, skipped_source_pointer & 0xFF, 0x8124)
		if (skipped_source_pointer >> 8) != (skip_table_pointer >> 8):
			_record(0x8128)
			_write_ram(0x005E, (skipped_source_pointer >> 8) & 0xFF, 0x8128)
		_record(0x812C)
		_write_ram(0x003A, 0, 0x812C)
		source_pointer = skipped_source_pointer
		if resume_offset == 7:
			_record(0x8105)
			_record(0x816E)
			_record(0x8401)
			_record(0x8211)
			_record(0x812F)
			_record(0x8130)
			_record(0x8131)
			_record(0x8132)
			_record(0x8134)
			_record(0x8135)
			_record(0x803F)
			var branch_entry: Dictionary = scenario_runtime.advance_one()
			if not bool(branch_entry.get("ok", false)) \
					or String(branch_entry.get("status", "")) != "scenario18_external_branch_entered":
				return _fail("Scenario-$18 `$F3 $1E` did not enter its selected ROM child source: %s" % str(branch_entry))
			scenario18_external_branch_pointer = int(branch_entry.get("source_pointer_cpu", -1))
			if scenario18_external_branch_pointer != 0xAF51 \
					or int(branch_entry.get("selector_result", -1)) != 0:
				return _fail("Scenario-$18 selected an external child outside the implemented `$AF51` branch: %s" % str(branch_entry))
			# $8401 only selects the table entry; $8211 sets $0516 only for a
			# nonzero selector. The actual pointer replacement is the shared $80F6
			# loader, whose stores are at $80FC/$80FE and whose cursor clear is $8102.
			_record(0x80F6)
			_record(0x80F8)
			_record(0x80F9)
			_record(0x80FA)
			_record(0x80FC)
			_write_ram(0x005E, (scenario18_external_branch_pointer >> 8) & 0xFF, 0x80FC)
			_record(0x80FE)
			_write_ram(0x005D, scenario18_external_branch_pointer & 0xFF, 0x80FE)
			_record(0x8100)
			_record(0x8102)
			_write_ram(0x003A, 0, 0x8102)
			_record(0x8104)
			var scenario18_parent_branch_pointer := source_pointer
			source_pointer = scenario18_external_branch_pointer
			source_events.append({"kind": "external_branch_entry", "source_pointer": scenario18_parent_branch_pointer,
				"source_bytes": PackedByteArray([0xF3, 0x1E]), "result": branch_entry.duplicate(true),
				"branch_sha256": PASS_SCENARIO_18_AF51_SHA256})
		source_events.append({"kind": "control_flow", "source_pointer": scenario18_root_pointer + 2,
			"source_bytes": PackedByteArray([0xF3, 0xB4]), "result": f3_result.duplicate(true)})
		if resume_offset == 17:
			_record(0x8105)
			_record(0x816E)
			_record(0x856C)
		var f9_result: Dictionary = scenario_runtime.advance_one()
		var f9_writes: Dictionary = f9_result.get("ram_writes", {})
		if not bool(f9_result.get("ok", false)) or int(f9_result.get("opcode", -1)) != 0xF9 \
				or int(f9_result.get("operand_word_little_endian", -1)) != (0x2B05 if resume_offset == 7 else 0x2B15) \
				or int(f9_result.get("source_byte_index_after", -1)) != (3 if resume_offset == 7 else 20) \
				or f9_writes != ({"$0530": 0x05, "$0531": 0x2B} if resume_offset == 7 \
					else {"$0530": 0x15, "$0531": 0x2B}):
			return _fail("Scenario-$18 selected branch `$F9` operands differ from their hash-checked ROM bytes: %s" % str(f9_result))
		_record(0x803F)
		var f9_cursor_before := 0 if resume_offset == 7 else 17
		_write_ram(0x003A, f9_cursor_before + 1, 0x8041)
		_record(0x8809)
		_write_ram(0x003A, f9_cursor_before + 2, 0x8809)
		_write_ram(0x0530, 0x05 if resume_offset == 7 else 0x15, 0x880C)
		_write_ram(0x0531, 0x2B, 0x8812)
		var f9_cursor_after := 3 if resume_offset == 7 else 20
		_write_ram(0x003A, f9_cursor_after, 0x8041)
		source_events.append({"kind": "f9_operand", "source_pointer": source_pointer + f9_cursor_before,
			"source_bytes": PackedByteArray([0xF9, 0x05 if resume_offset == 7 else 0x15, 0x2B]),
			"ram_writes": f9_writes.duplicate(true)})
	elif scenario_id == 0x36:
		var f5_result: Dictionary = scenario_runtime.advance_one()
		var f5_writes: Dictionary = f5_result.get("ram_writes", {})
		var f5_handler_variant: Variant = f5_result.get("handler_bytes", [])
		var f5_handler := PackedByteArray(f5_handler_variant) if f5_handler_variant is Array else PackedByteArray()
		if not bool(f5_result.get("ok", false)) or int(f5_result.get("opcode", -1)) != 0xF5 \
				or int(f5_result.get("handler_cpu_address", -1)) != 0x87E6 \
				or int(f5_writes.get("$052A", -1)) != 0 \
				or f5_handler != PackedByteArray([0xA9, 0x00, 0x8D, 0x2A, 0x05, 0x60]):
			return _fail("Scenario-$36's source `$F5` opcode did not resolve the ROM `$87E6` clear of `$052A`.")
		for pc in [0x803F, 0x8042, 0x8045, 0x8048, 0x804B, 0xCB99, 0x87E6, 0x87E8, 0x87EB]:
			_record(pc)
		_write_ram(0x052A, 0, 0x87E8)
		_write_ram(0x003A, int(f5_result.get("source_byte_index_after", -1)), 0x87EB)
		source_events.append({"kind": "opcode", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xF5]), "ram_writes": f5_writes.duplicate(true)})
	elif scenario_id == 0x2E:
		var f5_result: Dictionary = scenario_runtime.advance_one()
		var f5_writes: Dictionary = f5_result.get("ram_writes", {})
		var f5_handler_variant: Variant = f5_result.get("handler_bytes", [])
		var f5_handler := PackedByteArray(f5_handler_variant) if f5_handler_variant is Array else PackedByteArray()
		if not bool(f5_result.get("ok", false)) or int(f5_result.get("opcode", -1)) != 0xF5 \
				or int(f5_result.get("handler_cpu_address", -1)) != 0x87E6 \
				or int(f5_result.get("source_byte_offset", -1)) != 0 \
				or int(f5_result.get("source_byte_index_after", -1)) != 1 \
				or int(f5_writes.get("$052A", -1)) != 0 \
				or f5_handler != PackedByteArray([0xA9, 0x00, 0x8D, 0x2A, 0x05, 0x60]):
			return _fail("Scenario-$2E root `$F5` did not resolve to the ROM `$87E6` clear of `$052A`.")
		for pc in [0x803F, 0x8042, 0x8045, 0x8048, 0x804B, 0xCB99, 0x87E6, 0x87E8, 0x87EB]:
			_record(pc)
		_write_ram(0x052A, 0, 0x87E8)
		_write_ram(0x003A, 1, 0x87EB)
		source_events.append({"kind": "opcode", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xF5]), "ram_writes": f5_writes.duplicate(true),
			"handler_cpu_address": 0x87E6, "handler_bytes": f5_handler.duplicate()})
	elif scenario_id == 0x38:
		var f7_result: Dictionary = scenario_runtime.advance_one()
		var f7_writes: Dictionary = f7_result.get("ram_writes", {})
		var f7_handler_variant: Variant = f7_result.get("handler_bytes", [])
		var f7_handler: Array = f7_handler_variant if f7_handler_variant is Array else []
		if not bool(f7_result.get("ok", false)) \
				or String(f7_result.get("status", "")) != "decoded_byte_operation_applied" \
				or int(f7_result.get("opcode", -1)) != 0xF7 \
				or int(f7_result.get("operand", -1)) != 0x17 \
				or int(f7_result.get("handler_cpu_address", -1)) != 0x87F5 \
				or int(f7_result.get("handler_file_offset", -1)) != 0x020805 \
				or int(f7_result.get("source_byte_index_after", -1)) != 2 \
				or f7_writes != {"$052B": 0x17} \
				or f7_handler != [0xA4, 0x3A, 0xE6, 0x3A, 0xB1, 0x5D, 0x8D, 0x2B, 0x05, 0x60]:
			return _fail("Scenario-$38 `$F7 $17` did not resolve to the pinned ROM `$87F5` reader and `$052B` write.")
		for pc in [0x803F, 0x8042, 0x8045, 0x8048, 0x804B, 0x80A9, 0xC509, 0xCB99,
				0x87F5, 0x87F7, 0x87F9, 0x87FB, 0x87FE]:
			_record(pc)
		_set_y(0)
		_write_ram(0x003A, 1, 0x8041)
		_set_y(1)
		_write_ram(0x003A, 2, 0x87F7)
		_set_a(0x17)
		_write_ram(0x052B, int(f7_writes["$052B"]), 0x87FB)
		_record(0x803F)
		_set_y(2)
		_write_ram(0x003A, 3, 0x8041)
		source_events.append({"kind": "opcode", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xF7, 0x17]), "ram_writes": f7_writes.duplicate(true),
			"handler_cpu_address": 0x87F5, "handler_bytes": PackedByteArray(f7_handler)})
	var expected_record_offset := (3 if source_pointer == 0xAF51 else 20) if scenario_id == 0x18 \
		else ((3 if scenario1c_f2_branch_selected else 0) if scenario_id == 0x1C \
		else (5 if scenario_id == 0x1E else (1 if scenario_id == 0x2E else (3 if scenario_id == 0x35 \
		else (4 if scenario_id == 0x36 else (2 if scenario_id == 0x38 else 0))))))
	if scenario_id == 0x1E:
		var fd_result: Dictionary = scenario_runtime.advance_one()
		var fd_writes: Dictionary = fd_result.get("ram_writes", {})
		if not bool(fd_result.get("ok", false)) or int(fd_result.get("opcode", -1)) != 0xFD \
				or int(fd_result.get("operand", -1)) != 0x02 \
				or int(fd_result.get("handler_target_cpu_address", -1)) != 0x88B5 \
				or int(fd_writes.get("$052A", -1)) != (0x00 if int(_ram[0x05FB]) == 0 else 0x40):
			return _fail("Scenario-$1E `$FD $02` did not resolve its `$052A` result from live `$05FB`.")
		_record(0x803F)
		_record(0x8041)
		_write_ram(0x003A, 2, 0x8861)
		_write_ram(0x052A, int(fd_writes["$052A"]), 0x8869)
		source_events.append({"kind": "fd_operand", "source_pointer": source_pointer,
			"source_bytes": PackedByteArray([0xFD, 0x02]), "ram_writes": fd_writes.duplicate(true),
			"live_ram_05FB": int(_ram[0x05FB])})
		var f6_result: Dictionary = scenario_runtime.advance_one()
		var f6_writes: Dictionary = f6_result.get("ram_writes", {})
		if not bool(f6_result.get("ok", false)) or int(f6_result.get("opcode", -1)) != 0xF6 \
				or int(f6_writes.get("$052A", -1)) != (int(fd_writes["$052A"]) ^ 0x40):
			return _fail("Scenario-$1E `$F6` did not XOR the source `$052A` state by `$40`.")
		_record(0x803F)
		_record(0x8041)
		_write_ram(0x003A, 3, 0x8041)
		_write_ram(0x052A, int(f6_writes["$052A"]), 0x87F4)
		source_events.append({"kind": "opcode", "source_pointer": source_pointer + 2,
			"source_bytes": PackedByteArray([0xF6]), "ram_writes": f6_writes.duplicate(true)})
		var f7_result: Dictionary = scenario_runtime.advance_one()
		var f7_writes: Dictionary = f7_result.get("ram_writes", {})
		if not bool(f7_result.get("ok", false)) or int(f7_result.get("opcode", -1)) != 0xF7 \
				or int(f7_result.get("operand", -1)) != 0x01 \
				or int(f7_writes.get("$052B", -1)) != 0x01:
			return _fail("Scenario-$1E `$F7 01` did not write its ROM operand to `$052B`.")
		_record(0x803F)
		_record(0x8041)
		_write_ram(0x003A, 4, 0x8041)
		_record(0x87F5)
		_write_ram(0x003A, 5, 0x87F8)
		_write_ram(0x052B, int(f7_writes["$052B"]), 0x87FE)
		source_events.append({"kind": "opcode", "source_pointer": source_pointer + 3,
			"source_bytes": PackedByteArray([0xF7, 0x01]), "ram_writes": f7_writes.duplicate(true)})
	elif scenario_id in [0x35, 0x36]:
		var f9_result: Dictionary = scenario_runtime.advance_one()
		var expected_after_f9 := 3 if scenario_id == 0x35 else 4
		if not bool(f9_result.get("ok", false)) or int(f9_result.get("opcode", -1)) != 0xF9 \
				or int(f9_result.get("source_byte_index_after", -1)) != expected_after_f9:
			return _fail("The ROM-derived scenario parser did not consume the first `$F9` token.")
		var f9_writes: Dictionary = f9_result.get("ram_writes", {})
		var expected_f9 := PackedByteArray([0xEB, 0x44]) if scenario_id == 0x35 else PackedByteArray([0x02, 0x7F])
		if int(f9_writes.get("$0530", -1)) != int(expected_f9[0]) \
				or int(f9_writes.get("$0531", -1)) != int(expected_f9[1]):
			return _fail("The first `$F9` token operands differ from the hash-checked scenario stream.")
		_write_ram(0x0530, int(expected_f9[0]), 0x880D)
		_write_ram(0x0531, int(expected_f9[1]), 0x8812)
		_write_ram(0x003A, expected_after_f9, 0x803F)
		source_events.append({"kind": "f9_operand", "source_pointer": source_pointer + (1 if scenario_id == 0x36 else 0),
			"source_bytes": PackedByteArray([0xF9, expected_f9[0], expected_f9[1]]),
			"ram_writes": f9_writes.duplicate(true)})
	var record_result: Dictionary = scenario1c_record_result if scenario_id == 0x1C \
		else scenario_runtime.advance_one()
	var expected_record_cursor := expected_record_offset + 4
	if not bool(record_result.get("ok", false)) \
			or String(record_result.get("status", "")) != "callback_task_seed_requested" \
			or int(record_result.get("source_byte_offset", -1)) != expected_record_offset \
			or int(record_result.get("source_byte_index_after", -1)) != expected_record_cursor:
		return _fail("The ROM-derived parser did not consume the first scenario event record.")
	var seed_contract: Dictionary = record_result.get("seed_contract_fields", {})
	var assignments: Dictionary = record_result.get("ram_state", {})
	var expected_wait_value := int(assignments.get("$0523", -1)) if scenario_id in [0x18, 0x1C] \
		else (0x78 if scenario_id == 0x2E else (0x07 if scenario_id == 0x1E else (0x01 if scenario_id == 0x38 \
		else (0x02 if scenario_id in [0x35, 0x44] else 0x10))))
	var expected_event_selector := int(assignments.get("$0524", -1)) if scenario_id in [0x18, 0x1C] \
		else (0x36 if scenario_id == 0x2E else (0x45 if scenario_id == 0x1E else (0x34 if scenario_id == 0x38 \
		else (0x70 if scenario_id == 0x44 else 0x3A))))
	var expected_actor_selector := int(assignments.get("$0528", -1)) if scenario_id in [0x18, 0x1C] \
		else (0x8B if scenario_id == 0x2E else (0x90 if scenario_id == 0x1E else (0x00 if scenario_id == 0x38 \
		else (0x5C if scenario_id == 0x44 else 0x8F))))
	var expected_actor_parameter := int(assignments.get("$0529", -1)) if scenario_id in [0x18, 0x1C] \
		else (0x6D if scenario_id == 0x2E else (0x73 if scenario_id == 0x35 else 0xFF))
	if seed_contract.is_empty() \
			or int(seed_contract.get("scenario_id", -1)) != scenario_id \
			or int(seed_contract.get("event_selector_ram_0524", -1)) != expected_event_selector \
			or int(seed_contract.get("wait_value_ram_0523", -1)) != expected_wait_value \
			or int(seed_contract.get("actor_selector_ram_0528", -1)) != expected_actor_selector \
			or int(seed_contract.get("actor_parameter_ram_0529", -1)) != expected_actor_parameter \
			or int(seed_contract.get("task_slot_base", -1)) != 0x15:
		return _fail("Scenario-$%02X record did not produce the verified slot-$15 seed contract." % scenario_id)
	for pc in [0x803F, 0x804F, 0x8052, 0x8059, 0x805C, 0x8069,
			0x806C, 0x8079, 0x807C, 0x8089, 0x808C, 0x8091, 0x8095, 0x8097]:
		_record(pc)
	_write_ram(0x0523, int(assignments.get("$0523", -1)), 0x804F)
	_write_ram(0x0516, (int(_ram[0x0516]) | 0x40) & 0xEF, 0x8059)
	_write_ram(0x0524, int(assignments.get("$0524", -1)), 0x8069)
	_write_ram(0x0528, int(assignments.get("$0528", -1)), 0x8079)
	_write_ram(0x0529, int(assignments.get("$0529", -1)), 0x8089)
	_write_ram(0x003A, expected_record_cursor, 0x808C)
	var next_pointer := source_pointer + expected_record_cursor
	if next_pointer > 0xFFFF:
		return _fail("Scenario stream cursor overflowed the source pointer range.")
	_write_ram(0x005D, next_pointer & 0xFF, 0x8091)
	if int(_ram[0x005E]) != ((next_pointer >> 8) & 0xFF):
		return _fail("Scenario stream pointer high byte changed outside the verified no-carry update.")
	_scenario_seed_request = seed_contract.duplicate(true)
	source_events.append({"kind": "event_record", "source_pointer": source_pointer + expected_record_offset,
		"source_bytes": record_result.get("seed_contract_fields", {}).get("source_record_bytes", PackedByteArray()),
		"seed_contract": seed_contract.duplicate(true)})
	_scenario_runtime_events = source_events
	# Execute the verified $8097 -> $C50F -> $CAE7 task setup and return chain.
	_set_x(0x15)
	_set_a(0xF0)
	_write_ram(0x0016, 0xF0, 0x809B)
	_set_a(0x0B)
	_write_ram(0x0017, 0x0B, 0x809F)
	_set_a(0x80)
	_cpu["y"] = 0x08
	_jsr(0x80A5, 0xC50F)
	_record(0xC50F)
	_record(0xCAE7)
	_push(int(_cpu["a"]), 0xCAE7, "PHA")
	_set_a(int(_cpu["y"]))
	_cpu["y"] = int(_ram[(0x0001 + int(_cpu["x"])) & 0x07FF])
	_write_ram(0x0100 | ((0x01 + int(_cpu["y"])) & 0xFF),
		int(_cpu["a"]), 0xCAEB)
	_set_a(_pop(0xCAEE))
	_write_ram(0x0100 | ((0x02 + int(_cpu["y"])) & 0xFF),
		int(_cpu["a"]), 0xCAEF)
	_set_a(0xFF)
	_write_ram(0x0015, 0xFF, 0xCAF4)
	_record(0xCAF6)
	_rts(0xCAF6)
	if not _expect_pc(0x80A8): return false
	_record(0x80A8)
	_rts(0x80A8)
	if not _expect_pc(caller_return_pc): return false
	return true


func _execute_ed85() -> bool:
	if not _expect_span("ed85", 0xED85, [0xAD, 0xD2, 0x05]): return false
	_record(0xED85)
	_set_a(int(_ram[0x05D2]))
	if not _expect_span("ed85", 0xED88, [0xD0, 0x01]): return false
	_record(0xED88)
	if int(_cpu["a"]) == 0:
		if not _expect_span("ed85", 0xED8A, [0x60]): return false
		_record(0xED8A)
		_rts(0xED8A)
		return true
	if int(_ram[0x05D2]) == 0x01:
		return _execute_ed85_normalized_coordinate_branch()
	if int(_ram[0x05D2]) != 0x80:
		return _fail("Only the recorded scenario-$36 `$05D2=$01/$80` helper branches are decoded.")
	return _execute_ed85_scenario36_highbit_branch()


func _execute_ed85_normalized_coordinate_branch() -> bool:
	# `$ED94` may already have normalized `$05D2` from `$80` to `$01` in an
	# earlier helper call. The ROM then branches directly from `$ED8B` to `$EDF5`.
	if not _expect_span("ed85", 0xED8B, [0x10, 0x68]): return false
	_record(0xED8B)
	if (int(_cpu["p"]) & P_N) != 0:
		return _fail("The live `$ED8B` BPL condition does not select `$EDF5` for `$05D2=$01`.")
	if not _expect_span("ed85", 0xEDF5, [0x2C, 0xD2, 0x05, 0x50, 0x37]): return false
	_record(0xEDF5)
	_bit_ram(0x05D2)
	_record(0xEDF8)
	if (int(_cpu["p"]) & P_V) != 0:
		return _fail("The live `$EDF8` BVC condition does not select `$EE31` for `$05D2=$01`.")
	return _execute_ed85_coordinate_tail()


func _execute_ed85_scenario36_highbit_branch() -> bool:
	# The matched route enters with $05D2=$80. The ROM normalizes this to $01,
	# copies the live helper fields, then takes the BVC/$EE31 coordinate path.
	if not _expect_span("ed85", 0xED8B, [0x10, 0x68, 0x29, 0x7F, 0x09, 0x01, 0x8D, 0xD2, 0x05]):
		return false
	_record(0xED8B)
	if (int(_cpu["p"]) & P_N) == 0:
		return _fail("The live `$ED8B` BPL condition differs from source value `$05D2=$80`.")
	_record(0xED8D)
	_set_a(int(_cpu["a"]) & 0x7F)
	_record(0xED8F)
	_set_a(int(_cpu["a"]) | 0x01)
	_record(0xED91)
	_write_ram(0x05D2, int(_cpu["a"]), 0xED91)

	var copy_specs: Array[Dictionary] = [
		{"load_pc": 0xED94, "store_pc": 0xED97, "source": 0x05DB, "target": 0x05D3, "op": [0xAD, 0xDB, 0x05, 0x8D, 0xD3, 0x05]},
		{"load_pc": 0xED9A, "store_pc": 0xED9D, "source": 0x05DC, "target": 0x05D4, "op": [0xAD, 0xDC, 0x05, 0x8D, 0xD4, 0x05]},
		{"load_pc": 0xEDA0, "store_pc": 0xEDA3, "source": 0x05DD, "target": 0x05D5, "op": [0xAD, 0xDD, 0x05, 0x8D, 0xD5, 0x05]},
	]
	for spec_variant in copy_specs:
		var spec: Dictionary = spec_variant
		if not _expect_span("ed85", int(spec["load_pc"]), spec["op"]): return false
		_record(int(spec["load_pc"]))
		_set_a(int(_ram[int(spec["source"])]))
		_record(int(spec["store_pc"]))
		_write_ram(int(spec["target"]), int(_cpu["a"]), int(spec["store_pc"]))
	if not _expect_span("ed85", 0xEDA6, [0xAE, 0xDE, 0x05, 0xAC, 0xDF, 0x05,
			0x8E, 0xD6, 0x05, 0x8C, 0xD7, 0x05]): return false
	_record(0xEDA6)
	_set_x(int(_ram[0x05DE]))
	_record(0xEDA9)
	_set_y(int(_ram[0x05DF]))
	_record(0xEDAC)
	_write_ram(0x05D6, int(_cpu["x"]), 0xEDAC)
	_record(0xEDAF)
	_write_ram(0x05D7, int(_cpu["y"]), 0xEDAF)
	var tail_copy_specs: Array[Dictionary] = [
		{"load_pc": 0xEDB2, "store_pc": 0xEDB5, "source": 0x05E0, "target": 0x05D8, "op": [0xAD, 0xE0, 0x05, 0x8D, 0xD8, 0x05]},
		{"load_pc": 0xEDB8, "store_pc": 0xEDBB, "source": 0x05E1, "target": 0x05D9, "op": [0xAD, 0xE1, 0x05, 0x8D, 0xD9, 0x05]},
		{"load_pc": 0xEDBE, "store_pc": 0xEDC1, "source": 0x05E2, "target": 0x05DA, "op": [0xAD, 0xE2, 0x05, 0x8D, 0xDA, 0x05]},
	]
	for spec_variant in tail_copy_specs:
		var spec: Dictionary = spec_variant
		if not _expect_span("ed85", int(spec["load_pc"]), spec["op"]): return false
		_record(int(spec["load_pc"]))
		_set_a(int(_ram[int(spec["source"])]))
		_record(int(spec["store_pc"]))
		_write_ram(int(spec["target"]), int(_cpu["a"]), int(spec["store_pc"]))

	if not _expect_span("ed85", 0xEDC4, [0xAD, 0xD2, 0x05, 0x29, 0x02, 0xF0, 0x2A]): return false
	_record(0xEDC4)
	_set_a(int(_ram[0x05D2]))
	_record(0xEDC7)
	_set_a(int(_cpu["a"]) & 0x02)
	_record(0xEDC9)
	if int(_cpu["a"]) != 0:
		return _fail("The scenario-$36 `$EDC9` branch does not select the recorded `$EDF5` path.")
	if not _expect_span("ed85", 0xEDF5, [0x2C, 0xD2, 0x05, 0x50, 0x37]): return false
	_record(0xEDF5)
	_bit_ram(0x05D2)
	_record(0xEDF8)
	if (int(_cpu["p"]) & P_V) != 0:
		return _fail("The live `$EDF8` BVC condition does not select the recorded `$EE31` path.")
	return _execute_ed85_coordinate_tail()


func _execute_ed85_coordinate_tail() -> bool:
	if not _expect_span("ed85", 0xEE31, [0xA5, 0x20, 0x29, 0xFE, 0x85, 0x20,
			0x18, 0xAD, 0xD6, 0x05, 0x6D, 0xD3, 0x05, 0x8D, 0xD3, 0x05,
			0xAD, 0xD7, 0x05, 0x6D, 0xD4, 0x05, 0x8D, 0xD4, 0x05, 0x85, 0x4A]):
		return false
	_record(0xEE31)
	_set_a(int(_ram[0x0020]))
	_record(0xEE33)
	_set_a(int(_cpu["a"]) & 0xFE)
	_record(0xEE35)
	_write_ram(0x0020, int(_cpu["a"]), 0xEE35)
	_record(0xEE37)
	_set_c(false)
	_record(0xEE38)
	_set_a(int(_ram[0x05D6]))
	_record(0xEE3B)
	_adc(int(_ram[0x05D3]))
	_record(0xEE3E)
	_write_ram(0x05D3, int(_cpu["a"]), 0xEE3E)
	_record(0xEE41)
	_set_a(int(_ram[0x05D7]))
	_record(0xEE44)
	_adc(int(_ram[0x05D4]))
	_record(0xEE47)
	_write_ram(0x05D4, int(_cpu["a"]), 0xEE47)
	_record(0xEE4A)
	_write_ram(0x004A, int(_cpu["a"]), 0xEE4A)
	_record(0xEE4C)
	_set_x(int(_cpu["a"]))
	_record(0xEE4D)
	_set_a(0)
	_record(0xEE4F)
	_bit_ram(0x05D7)
	_record(0xEE52)
	if (int(_cpu["p"]) & P_N) == 0:
		return _fail("The live `$EE52` BPL condition differs from the recorded negative `$05D7` value.")
	if not _expect_span("ed85", 0xEE54, [0xA9, 0xFF, 0x08, 0xAA, 0x6D, 0xD5, 0x05,
			0x8D, 0xD5, 0x05, 0x29, 0x01, 0x05, 0x20, 0x85, 0x20,
			0x8A, 0x28, 0x69, 0x00, 0xAA, 0x20, 0x6D, 0xEE]): return false
	_record(0xEE54)
	_set_a(0xFF)
	_record(0xEE56)
	_push(int(_cpu["p"]) | 0x30, 0xEE56, "PHP")
	_record(0xEE57)
	_set_x(int(_cpu["a"]))
	_record(0xEE58)
	_adc(int(_ram[0x05D5]))
	_record(0xEE5B)
	_write_ram(0x05D5, int(_cpu["a"]), 0xEE5B)
	_record(0xEE5E)
	_set_a(int(_cpu["a"]) & 0x01)
	_record(0xEE60)
	_set_a(int(_cpu["a"]) | int(_ram[0x0020]))
	_record(0xEE62)
	_write_ram(0x0020, int(_cpu["a"]), 0xEE62)
	_record(0xEE64)
	_set_a(int(_cpu["x"]))
	_record(0xEE65)
	_cpu["p"] = (_pop(0xEE65) & ~0x10) | 0x20
	_cpu["p_known_mask"] = int(_cpu["p_known_mask"]) | P_NZ_MASK | P_V | P_C
	_record(0xEE66)
	_adc(0)
	_record(0xEE68)
	_set_x(int(_cpu["a"]))
	_record(0xEE69)
	_jsr(0xEE69, 0xEE6D)
	_record(0xEE6D)
	_set_a(int(_ram[0x05D2]))
	_record(0xEE70)
	_set_a(int(_cpu["a"]) & 0x02)
	_record(0xEE72)
	if int(_cpu["a"]) != 0:
		return _fail("The live `$EE72` branch does not select the verified `$EE9E` return.")
	if not _expect_span("ed85", 0xEE9E, [0x60]): return false
	_record(0xEE9E)
	_rts(0xEE9E)
	if not _expect_pc(0xEE6C): return false
	if not _expect_span("ed85", 0xEE30, [0x60]): return false
	_record(0xEE30)
	_rts(0xEE30)
	return true


func _execute_mapper_helper(expected_return_pc: int = 0xEBAF) -> bool:
	var code: PackedByteArray = _sources["mapper"]
	var pc := 0xCE2D
	var offset := 0
	while pc < 0xCE49:
		var opcode := int(code[offset])
		_record(pc)
		match opcode:
			0xA5: # LDA zero page
				var address := int(code[offset + 1])
				_set_a(int(_ram[address]))
				pc += 2
				offset += 2
			0x09: # ORA immediate
				_set_a(int(_cpu["a"]) | int(code[offset + 1]))
				pc += 2
				offset += 2
			0x85: # STA zero page
				var address := int(code[offset + 1])
				_write_ram(address, int(_cpu["a"]), pc)
				pc += 2
				offset += 2
			0x8D: # STA absolute: MMC3 register select/data port
				var address := int(code[offset + 1]) | (int(code[offset + 2]) << 8)
				if not _write_mapper_bus(address, int(_cpu["a"]), pc): return false
				pc += 3
				offset += 3
			_:
				return _fail("Unsupported mapper-helper opcode $%02X at $%04X." % [opcode, pc])
	# Check the exact source RTS, then return to the fixed caller.
	if not _expect_span("mapper", 0xCE49, [0x60]): return false
	_record(0xCE49)
	_rts(0xCE49)
	return _expect_pc(expected_return_pc)


func _write_mapper_bus(address: int, value: int, pc: int) -> bool:
	value &= 0xFF
	if address == 0x8000:
		_mapper["select"] = value & 0x07
		_mapper_writes.append({"pc": pc, "address": address, "value": value,
			"select": int(_mapper["select"]), "kind": "register_select"})
		return true
	if address != 0x8001:
		return _fail("Unsupported mapper bus write $%04X at $%04X." % [address, pc])
	var selected := int(_mapper["select"])
	if selected not in [6, 7]:
		return _fail("Mapper data write selected unsupported MMC3 register %d at $%04X." % [selected, pc])
	_mapper["bank_registers"][selected] = value
	if selected == 6:
		_mapper["bank_low"] = value
		_cpu["bank_low"] = value
	else:
		_mapper["bank_high"] = value
		_cpu["bank_high"] = value
	_mapper_writes.append({"pc": pc, "address": address, "value": value,
		"select": selected, "kind": "register_data"})
	return true


func _source_spans_payload() -> Array[Dictionary]:
	var spans: Array[Dictionary] = []
	for name_variant in SOURCE_SPANS:
		var name := String(name_variant)
		var spec: Dictionary = SOURCE_SPANS[name]
		spans.append({"name": name, "file": String(spec["file"]),
			"cpu_start": int(spec["start"]), "cpu_end_exclusive": int(spec["end"]),
			"bank": int(spec["bank"]), "file_offset": String(spec["offset"]),
			"sha256": String(spec["sha256"])})
	return spans


func _load_root_loop_dependency(dependency_variant: Variant) -> bool:
	if not dependency_variant is Dictionary:
		return _fail("Manifest omits its existing root-loop source dependency.")
	var dependency: Dictionary = dependency_variant
	if String(dependency.get("manifest", "")) != ROOT_LOOP_MANIFEST \
			or String(dependency.get("file", "")) != "fixed_root_slot09_loop_EB86_EC07.bin" \
			or String(dependency.get("file_offset", "")) != ROOT_LOOP_OFFSET \
			or int(dependency.get("length", -1)) != ROOT_LOOP_LENGTH \
			or String(dependency.get("sha256", "")) != ROOT_LOOP_SHA256:
		return _fail("Manifest root-loop dependency differs from the checked task-context span.")
	var task_manifest_file := FileAccess.open(ROOT_LOOP_MANIFEST, FileAccess.READ)
	if task_manifest_file == null:
		return _fail("Existing root slot-$09 task-context manifest is unavailable.")
	var task_manifest_variant: Variant = JSON.parse_string(task_manifest_file.get_as_text())
	if not task_manifest_variant is Dictionary \
			or String((task_manifest_variant as Dictionary).get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Existing task-context manifest targets a different ROM revision.")
	var found := false
	for entry_variant in (task_manifest_variant as Dictionary).get("spans", []):
		if entry_variant is Dictionary and String(entry_variant.get("file", "")) == String(dependency["file"]):
			var entry: Dictionary = entry_variant
			if String(entry.get("file_offset", "")) != ROOT_LOOP_OFFSET \
					or int(entry.get("length", -1)) != ROOT_LOOP_LENGTH \
					or String(entry.get("sha256", "")) != ROOT_LOOP_SHA256:
				return _fail("Existing task-context root-loop span metadata changed.")
			found = true
			break
	if not found:
		return _fail("Existing task-context manifest omits the root slot-$09 loop span.")
	_root_loop = FileAccess.get_file_as_bytes(ROOT_LOOP_PATH)
	if _root_loop.size() != ROOT_LOOP_LENGTH or _sha256(_root_loop) != ROOT_LOOP_SHA256:
		return _fail("Existing root slot-$09 loop bytes failed size/hash validation.")
	_source_span_hashes["fixed_root_slot09_loop_EB86_EC07.bin"] = ROOT_LOOP_SHA256
	return true


func _validate_root(pc: int, expected: Array) -> bool:
	var offset := pc - 0xEB86
	if offset < 0 or offset + expected.size() > _root_loop.size():
		return _fail("Root slot-$09 instruction at $%04X is outside its checked span." % pc)
	for index in range(expected.size()):
		if int(_root_loop[offset + index]) != int(expected[index]):
			return _fail("Root slot-$09 opcode mismatch at $%04X." % pc)
	return true


func _expect_root(pc: int, expected: Array) -> bool:
	return _validate_root(pc, expected)


func _expect_span(name: String, pc: int, expected: Array) -> bool:
	var spec: Dictionary = SOURCE_SPANS.get(name, {})
	var source: PackedByteArray = _sources.get(name, PackedByteArray())
	var offset := pc - int(spec.get("start", -1))
	if offset < 0 or offset + expected.size() > source.size():
		return _fail("Source instruction at $%04X is outside span %s." % [pc, name])
	for index in range(expected.size()):
		if int(source[offset + index]) != int(expected[index]):
			return _fail("Source opcode mismatch at $%04X in span %s." % [pc, name])
	return true


func _expect_scenario_source(name: String, pc: int, expected: Array) -> bool:
	var spec: Dictionary = SCENARIO_TERMINATION_SPANS.get(name, {})
	var source: PackedByteArray = _sources.get(name, PackedByteArray())
	var offset := pc - int(spec.get("start", -1))
	if offset < 0 or offset + expected.size() > source.size():
		return _fail("Source instruction at $%04X is outside scenario dependency %s." % [pc, name])
	for index in range(expected.size()):
		if int(source[offset + index]) != int(expected[index]):
			return _fail("Scenario dependency opcode mismatch at $%04X in %s." % [pc, name])
	return true


func _expect_vector_8003() -> bool:
	var source: PackedByteArray = _sources["vector"]
	if source != PackedByteArray([0x4C, 0xF8, 0x86]):
		return _fail("Bank-$18 vector $8003 no longer targets the bounded $86F8 stop.")
	return true


func _record(pc: int) -> void:
	_instruction_pcs.append(pc)
	_cpu["pc"] = pc


func _set_a(value: int) -> void:
	_cpu["a"] = value & 0xFF
	_set_nz(int(_cpu["a"]))


func _set_x(value: int) -> void:
	_cpu["x"] = value & 0xFF
	_set_nz(int(_cpu["x"]))


func _set_y(value: int) -> void:
	_cpu["y"] = value & 0xFF
	_set_nz(int(_cpu["y"]))


func _set_nz(value: int) -> void:
	var flags := int(_cpu["p"]) & ~P_NZ_MASK
	if (value & 0x80) != 0: flags |= P_N
	if (value & 0xFF) == 0: flags |= P_Z
	_cpu["p"] = flags
	_cpu["p_known_mask"] = int(_cpu["p_known_mask"]) | P_NZ_MASK


func _set_c(enabled: bool) -> void:
	var flags := int(_cpu["p"])
	if enabled: flags |= P_C
	else: flags &= ~P_C
	_cpu["p"] = flags
	_cpu["p_known_mask"] = int(_cpu["p_known_mask"]) | P_C


func _set_v(enabled: bool) -> void:
	var flags := int(_cpu["p"])
	if enabled: flags |= P_V
	else: flags &= ~P_V
	_cpu["p"] = flags
	_cpu["p_known_mask"] = int(_cpu["p_known_mask"]) | P_V


func _compare_a(value: int) -> void:
	var result := (int(_cpu["a"]) - (value & 0xFF)) & 0xFF
	_set_c(int(_cpu["a"]) >= (value & 0xFF))
	_set_nz(result)


func _compare_x(value: int) -> void:
	var result := (int(_cpu["x"]) - (value & 0xFF)) & 0xFF
	_set_c(int(_cpu["x"]) >= (value & 0xFF))
	_set_nz(result)


func _bit_ram(address: int) -> void:
	var value := int(_ram[address])
	var flags := int(_cpu["p"]) & ~(P_N | P_V | P_Z)
	flags |= value & (P_N | P_V)
	if (int(_cpu["a"]) & value) == 0:
		flags |= P_Z
	_cpu["p"] = flags
	_cpu["p_known_mask"] = int(_cpu["p_known_mask"]) | (P_N | P_V | P_Z)


func _adc(value: int) -> void:
	var old_a := int(_cpu["a"])
	var operand := value & 0xFF
	var carry := int(_cpu["p"]) & P_C
	var sum := old_a + operand + carry
	var result := sum & 0xFF
	_set_c(sum > 0xFF)
	_set_v(((~(old_a ^ operand) & (old_a ^ result)) & 0x80) != 0)
	_set_a(result)


func _write_indexed_address(address: int, value: int, pc: int, kind: String) -> void:
	_write_ram(address, value, pc)
	if address >= 0x0100 and address <= 0x01FF:
		_stack_writes.append({"pc": pc, "address": address, "value": value & 0xFF, "kind": kind})


func _write_ram(address: int, value: int, pc: int) -> void:
	value &= 0xFF
	_ram[address] = value
	if address >= 0x0100 and address <= 0x01FF:
		_stack[address & 0xFF] = value
	_writes.append({"pc": pc, "address": address, "value": value, "kind": "ram"})


func _push(value: int, pc: int, kind: String) -> void:
	var sp := int(_cpu["sp"]) & 0xFF
	var address := 0x0100 | sp
	value &= 0xFF
	_ram[address] = value
	_stack[sp] = value
	_stack_writes.append({"pc": pc, "address": address, "value": value, "kind": kind})
	_cpu["sp"] = (sp - 1) & 0xFF


func _pop(pc: int) -> int:
	var sp := (int(_cpu["sp"]) + 1) & 0xFF
	_cpu["sp"] = sp
	return int(_stack[sp])


func _jsr(source_pc: int, target: int) -> void:
	var return_word := source_pc + 2
	_push((return_word >> 8) & 0xFF, source_pc, "JSR_high")
	_push(return_word & 0xFF, source_pc, "JSR_low")
	_calls.append({"source_pc": source_pc, "target_pc": target,
		"return_word": return_word, "return_pc": return_word + 1})
	_cpu["pc"] = target


func _rts(source_pc: int) -> void:
	var low := _pop(source_pc)
	var high := _pop(source_pc)
	var return_word := (high << 8) | low
	var return_pc := (return_word + 1) & 0xFFFF
	_returns.append({"source_pc": source_pc, "return_word": return_word, "return_pc": return_pc})
	_cpu["pc"] = return_pc


func _expect_pc(expected: int) -> bool:
	if int(_cpu.get("pc", -1)) != expected:
		return _fail("Source return reached $%04X; expected $%04X." % [int(_cpu.get("pc", -1)), expected])
	return true


func _stopped(status: String, pc: int, reason: String) -> Dictionary:
	var result := {"ok": false, "status": status, "rom_sha256": ROM_SHA256,
		"exit_pc": pc, "reason": reason, "trace_state_used": false,
		"runtime_integrated": false, "source_manifest": MANIFEST_PATH,
		"source_span_hashes": _source_span_hashes.duplicate(true),
		"source_spans": _source_spans_payload(),
		"entry_registers": _entry_registers.duplicate(true)}
	if pc == 0xED5B:
		result["source_stop_boundary"] = "before_ED5B_Dex"
		result["scenario_wait_handler_executed"] = false
		result["wait_decrement_applied"] = false
	if not _cpu.is_empty():
		result["registers"] = {"a": int(_cpu.get("a", -1)), "x": int(_cpu.get("x", -1)),
			"y": int(_cpu.get("y", -1)), "sp": int(_cpu.get("sp", -1)),
			"pc": int(_cpu.get("pc", pc)), "p": int(_cpu.get("p", 0)),
			"p_known_mask": int(_cpu.get("p_known_mask", 0))}
		result["mapper"] = _mapper.duplicate(true)
		result["ram_image"] = _ram.duplicate()
		result["stack_page"] = _stack.duplicate()
		result["writes"] = _writes.duplicate(true)
		result["stack_writes"] = _stack_writes.duplicate(true)
		result["mapper_writes"] = _mapper_writes.duplicate(true)
	return result


func _unsupported_branch(pc: int, reason: String) -> Dictionary:
	error_message = reason
	return _stopped("unsupported_branch", pc, reason)


func _unsupported_dispatch_branch(dispatch: Dictionary, pc: int, reason: String) -> Dictionary:
	error_message = reason
	var result := _stopped("unsupported_branch", pc, reason)
	var ram_variant: Variant = dispatch.get("ram_image", PackedByteArray())
	var stack_variant: Variant = dispatch.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = dispatch.get("mapper", {})
	if ram_variant is PackedByteArray: result["ram_image"] = ram_variant.duplicate()
	if stack_variant is PackedByteArray: result["stack_page"] = stack_variant.duplicate()
	if mapper_variant is Dictionary: result["mapper"] = (mapper_variant as Dictionary).duplicate(true)
	var registers := {"a": int(dispatch.get("a", -1)), "x": int(dispatch.get("x", -1)),
		"y": int(dispatch.get("y", -1)), "p": int(dispatch.get("p", 0)),
		"p_known_mask": int(dispatch.get("p_known_mask", 0)), "sp": int(dispatch.get("sp", -1)),
		"pc": int(dispatch.get("pc", -1))}
	result["entry_registers"] = registers.duplicate(true)
	result["registers"] = registers.duplicate(true)
	result["active_slot"] = int(dispatch.get("active_task_slot", -1))
	result["fixture_only"] = false
	return result


func _failure(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_input", "reason": reason,
		"rom_sha256": ROM_SHA256, "trace_state_used": false}


func _fail(reason: String) -> bool:
	error_message = reason
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()
