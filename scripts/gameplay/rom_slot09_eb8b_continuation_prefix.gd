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
const SCENARIO_RUNTIME := preload("res://scripts/gameplay/rom_bank10_scenario_task_runtime.gd")
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_N := 0x80
const P_V := 0x40
const P_Z := 0x02
const P_C := 0x01
const P_NZ_MASK := P_N | P_Z
const P_NZVC_MASK := P_N | P_V | P_Z | P_C

const SCENARIO_TERMINATION_SPANS := {
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
	"event_reader": {"file": "bank10_event_reader_803F_8096.bin", "start": 0x803F, "end": 0x8097,
		"bank": 0x10, "offset": "0x02004F", "length": 88,
		"sha256": "880ad93e8e01567b7ab4d1dbd4a34e3fa0cd9b7751e14753c2bb9f1acf10d5d4"},
	"ed85": {"file": "fixed_slot09_helper_ED85_ED8A.bin", "start": 0xED85, "end": 0xED8B,
		"bank": 0x1F, "offset": "0x03ED95", "length": 6,
		"sha256": "ddb8a7b385df09529ec1aa3f5c0eecf223fb07fd30fa25a7938a897d33e68044"},
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
var _scenario36_post_callback_executed := false
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
	_configured = true
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
	_scenario36_post_callback_executed = false
	_actor_worker_seed_request.clear()
	_actor_seed_pause_ready = false

	if not _execute_root_prefix():
		return _stopped("unsupported_source_state", int(_cpu.get("pc", -1)), error_message)
	if not _actor_worker_seed_request.is_empty():
		return _build_actor_seed_pause_result()
	var stop_at_scenario36_return := int(_ram[0x0518]) == 0x36 \
		and not _scenario_seed_request.is_empty() and int(_cpu["pc"]) == 0xEB9E
	return {
		"ok": true,
		"status": "scenario36_event_seeded_at_ec74_return" if stop_at_scenario36_return else "stopped_before_worker_body",
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
		"scenario36_post_callback_executed": _scenario36_post_callback_executed,
		"scenario_active_stop_boundary": "$EC74 RTS->$EB9E" if stop_at_scenario36_return else "",
		"pending_worker_call": {} if stop_at_scenario36_return else {"source_pc": 0xEBB0, "return_word": 0xEBB2,
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
			or int(ram_variant[0x0516]) != 0x41 or int(ram_variant[0x0518]) != 0x36 \
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
	_scenario36_post_callback_executed = false
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
	var scenario_active := scenario_flag in [0x80, 0x01, 0x29, 0x41, 0x51] \
			and scenario_id in [0x35, 0x36]
	if int(ram[0x0516]) != 0 and not scenario_active:
		return _unsupported_dispatch_branch(dispatch, 0xEC0D, "$0516=$%02X is outside the decoded zero branch and preserved scenario phases." % scenario_flag)
	if scenario_flag == 0x51:
		var expected_fields := (
			PackedByteArray([0x02, 0x3A, 0x02, 0xBC, 0x2C, 0x8F, 0x73, 0x00])
			if scenario_id == 0x35 else PackedByteArray([0x10, 0x3A, 0x02, 0xBC, 0x2C, 0x8F, 0xFF, 0x00]))
		if scenario_id not in [0x35, 0x36] or int(ram[0x0519]) != 0 \
				or ram.slice(0x0523, 0x052B) != expected_fields:
			return _unsupported_dispatch_branch(dispatch, 0xEC8C, "The live `$0516=$51` callback fields do not match a bounded scenario-$35/$36 event record.")
	if int(ram[0x05D2]) != 0:
		return _unsupported_dispatch_branch(dispatch, 0xED88, "$05D2 makes the $ED85 helper branch past its decoded RTS.")
	return {"ok": true}


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
	if int(_ram[0x0518]) == 0x36 and not _scenario_seed_request.is_empty():
		# Bound scenario $36 at the audited `$EC74 RTS->$EB9E` source return.
		return _expect_pc(0xEB9E)
	return _execute_root_prefix_after_ec08()


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
	if not (scenario_flag in [0x80, 0x01, 0x29, 0x41, 0x51]) or scenario_id not in [0x35, 0x36] \
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
	elif scenario_flag in [0x01, 0x29, 0x41, 0x51]:
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
		_cpu["pc"] = 0xEC74
		_record(0xEC74)
		_rts(0xEC74)
		return _expect_pc(0xEB9E)
	_record(0xEC54)
	_set_a(int(_ram[0x0516]))
	_record(0xEC57)
	_set_a(int(_cpu["a"]) & 0x50)
	_record(0xEC59)
	_compare_a(0x50)
	_record(0xEC5B)
	if (int(_cpu["p"]) & P_Z) != 0:
		if scenario_flag != 0x51 or int(_ram[0x0518]) not in [0x35, 0x36]:
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
	if not _execute_scenario35_bank10_root_worker(): return false
	if int(_cpu["pc"]) == 0xED84:
		return _return_from_scenario_wait()
	return _expect_pc(0xEB9E)


func _return_from_scenario_wait() -> bool:
	if not _expect_span("scenario_wait", 0xED84, [0x60]): return false
	_record(0xED84)
	_rts(0xED84)
	return _expect_pc(0xEB9E)


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
	if target != 0x8837:
		return _fail("The ROM F0-FF table did not dispatch live opcode `$FB` to `$8837`.")
	_cpu["pc"] = target
	return _execute_scenario_fb_handler()


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
		return _fail("Scenario-$35/$36 post-callback caller failed its ROM source hash.")
	var scenario_id := int(_ram[0x0518])
	var expected_actor_parameter := 0x73 if scenario_id == 0x35 else 0xFF
	var expected_actor_seed_parameter := 0x00 if scenario_id == 0x35 else 0xA0
	if scenario_id not in [0x35, 0x36] or int(_ram[0x0516]) != 0x51 \
			or int(_ram[0x0519]) != 0 or int(_ram[0x05CE]) != expected_actor_seed_parameter \
			or int(_ram[0x0529]) != expected_actor_parameter:
		return _fail("The live post-`$CAF7` callback state is outside the source-bounded scenario-$35/$36 profile.")
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
	var expected_actor_y := 0xE4 if scenario_id == 0x35 else 0x74
	if int(_cpu["x"]) != expected_actor_x or int(_cpu["y"]) != expected_actor_y:
		return _fail("Bank-$0B `$84A1` input=$%02X derived X=$%02X/Y=$%02X; bounded scenario-$%02X expects input=$%02X X=$%02X/Y=$%02X." % [actor_parameter_input, int(_cpu["x"]), int(_cpu["y"]), scenario_id, expected_actor_seed_parameter, expected_actor_x, expected_actor_y])
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
	if int(_cpu["a"]) == 0x73 and scenario_id == 0x35:
		_actor_worker_seed_request = _make_actor_worker_seed_request()
		_actor_seed_pause_ready = true
		return true
	if int(_cpu["a"]) == 0xFF and scenario_id == 0x36:
		# ROM `$ED17` branches to `$ED2D` when no actor parameter is selected.
		# That shared caller tail restores scenario flags and returns to `$EB9E`.
		if not _execute_scenario35_resume_tail():
			return false
		_scenario36_post_callback_executed = true
		return true
	return _fail("The live `$ED15` actor parameter is not the bounded scenario-$35 seed or scenario-$36 no-seed selector.")


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
		"actor_parameter": 0x73,
		"a": 0x73,
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
			or int(ram[0x05EA]) != 0x73 or int(ram[0x01C9]) != 0xFF \
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
	# manifest-preserved fresh-route entries $35/$36 are accepted here.
	var scenario_id := int(_ram[0x0518])
	var pointer_bytes: PackedByteArray = _sources.get(
		"scenario_pointer_35" if scenario_id == 0x35 else "scenario_pointer_36", PackedByteArray())
	var expected_pointer := 0xB7CD if scenario_id == 0x35 else 0xB7E4
	if scenario_id not in [0x35, 0x36] or pointer_bytes.size() != 2 \
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


func _execute_scenario_reader_and_callback_seed() -> bool:
	# Require the ROM parser to derive this scenario's stream and callback contract
	# from the live `$0518` selector and `$5D/$5E` pointer resolved above.
	var scenario_id := int(_ram[0x0518])
	var source_pointer := int(_ram[0x005D]) | (int(_ram[0x005E]) << 8)
	var scenario_runtime: RefCounted = SCENARIO_RUNTIME.new()
	var started: Dictionary = scenario_runtime.begin_from_live_scenario_pointer(scenario_id, source_pointer)
	if not bool(started.get("ok", false)) \
			or int(started.get("scenario_id", -1)) != scenario_id \
			or int(started.get("source_pointer_cpu", -1)) != source_pointer:
		return _fail("ROM scenario reader rejected the live selector/pointer: %s" % str(started))
	for pc in [0x8003, 0x8021, 0x8024, 0x8027, 0x802A, 0x802C,
			0x802F, 0x8031, 0x8034, 0x8037, 0x803A, 0x803D]:
		_record(pc)
	_write_ram(0x052A, int(_ram[0x0517]), 0x8024)
	_write_ram(0x0516, int(_ram[0x0516]) & 0xFB, 0x802C)
	for address_pc in [[0x052B, 0x8031], [0x052D, 0x8034],
			[0x052C, 0x8037], [0x0530, 0x803A], [0x003A, 0x803D]]:
		_write_ram(int(address_pc[0]), 0, int(address_pc[1]))
	var source_events: Array[Dictionary] = []
	if scenario_id == 0x36:
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
	var record_result: Dictionary = scenario_runtime.advance_one()
	var expected_record_offset := expected_after_f9
	var expected_record_cursor := expected_record_offset + 4
	if not bool(record_result.get("ok", false)) \
			or String(record_result.get("status", "")) != "callback_task_seed_requested" \
			or int(record_result.get("source_byte_offset", -1)) != expected_record_offset \
			or int(record_result.get("source_byte_index_after", -1)) != expected_record_cursor:
		return _fail("The ROM-derived parser did not consume the first scenario event record.")
	var seed_contract: Dictionary = record_result.get("seed_contract_fields", {})
	var assignments: Dictionary = record_result.get("ram_state", {})
	var expected_wait_value := 0x02 if scenario_id == 0x35 else 0x10
	var expected_actor_parameter := 0x73 if scenario_id == 0x35 else 0xFF
	if seed_contract.is_empty() \
			or int(seed_contract.get("scenario_id", -1)) != scenario_id \
			or int(seed_contract.get("event_selector_ram_0524", -1)) != 0x3A \
			or int(seed_contract.get("wait_value_ram_0523", -1)) != expected_wait_value \
			or int(seed_contract.get("actor_selector_ram_0528", -1)) != 0x8F \
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
	if not _expect_pc(0xEC74): return false
	return true


func _execute_ed85() -> bool:
	if not _expect_span("ed85", 0xED85, [0xAD, 0xD2, 0x05]): return false
	_record(0xED85)
	_set_a(int(_ram[0x05D2]))
	if not _expect_span("ed85", 0xED88, [0xD0, 0x01]): return false
	_record(0xED88)
	if int(_cpu["a"]) != 0:
		return _fail("Unsupported nonzero $05D2 branch at $ED88.")
	if not _expect_span("ed85", 0xED8A, [0x60]): return false
	_record(0xED8A)
	_rts(0xED8A)
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
