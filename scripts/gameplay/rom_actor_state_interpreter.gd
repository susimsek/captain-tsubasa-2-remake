extends RefCounted
class_name RomActorStateInterpreter
## Executes the preserved bank-$14 appearance/motion actor script slice.
## This is a bounded source interpreter, not the route scheduler or an OAM renderer.

class TickResult:
	extends RefCounted

	var ok: bool = false
	var actor_record: PackedByteArray = PackedByteArray()
	var appearance_events: Array[String] = []
	var motion_events: Array[String] = []
	var shared_ram_writes: Array[Dictionary] = []
	var error: String = ""


const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_DIR := "res://reference/rom_extract/gameplay/actor_state_interpreter/"
const MANIFEST_PATH := SOURCE_DIR + "manifest.json"
const EXPECTED_SCHEMA := "ct2-bank14-actor-interpreter-source-v1"
const ACTOR_RECORD_BYTES := 21
const APPEARANCE_TIMER_OFFSET := 0x10
const MOTION_TIMER_OFFSET := 0x11
const APPEARANCE_POINTER_OFFSET := 0x03
const MOTION_POINTER_OFFSET := 0x01
const APPEARANCE_DESCRIPTOR_OFFSET := 0x12
const MOTION_X_DELTA_LOW_OFFSET := 0x05
const MOTION_X_DELTA_HIGH_OFFSET := 0x07
const MOTION_Y_DELTA_LOW_OFFSET := 0x09
const MOTION_Y_DELTA_HIGH_OFFSET := 0x0B

const RESOURCE_SPECS := {
	"appearance_interpreter_83D9_84DB.bin": {
		"file_offset": 0x0283E9, "length_bytes": 0x0103,
		"cpu_start": "$83D9", "cpu_end_exclusive": "$84DC",
		"sha256": "776dad1dab540ed1151725c48ea4be2b99dd0f75a27bee293b0b523760eec411",
	},
	"motion_interpreter_84DC_8623.bin": {
		"file_offset": 0x0284EC, "length_bytes": 0x0148,
		"cpu_start": "$84DC", "cpu_end_exclusive": "$8624",
		"sha256": "3f9bb278daab82f6b76b2d89cbd91d327dd0202b3bc6e594dd1734fa1882f380",
	},
	"appearance_loop_B026_B030.bin": {
		"file_offset": 0x02B036, "length_bytes": 0x000B,
		"cpu_start": "$B026", "cpu_end_exclusive": "$B031",
		"sha256": "ddadf844964526d70fe2b454781c33d00d0038447290a4132699f633f3c7ec7c",
	},
	"appearance_hold_B5AC_B5B3.bin": {
		"file_offset": 0x02B5BC, "length_bytes": 0x0008,
		"cpu_start": "$B5AC", "cpu_end_exclusive": "$B5B4",
		"sha256": "271792914b8d88c9f0df0d1bb6571ebf4bbec5785eadbb2b934872fedc155af2",
	},
	"fresh_actor_appearance_sequence_B30E_B315.bin": {
		"file_offset": 0x02B31E, "length_bytes": 0x0008,
		"cpu_start": "$B30E", "cpu_end_exclusive": "$B316",
		"sha256": "57431468f0d18accdab301e3a1ca93d09c45a8db6f1049e8668286291dcafa72",
	},
	"slot11_actor_appearance_sequence_B2E0_B30D.bin": {
		"file_offset": 0x02B2F0, "length_bytes": 0x002E,
		"cpu_start": "$B2E0", "cpu_end_exclusive": "$B30E",
		"sha256": "4205a3a6d3cc2555f1b00e47ceeae9921e51eb422c12f09b0b63ecde03c38e4e",
	},
	"scenario_36_animation_4E_appearance_AF5F_AF60.bin": {
		"file_offset": 0x02AF6F, "length_bytes": 2,
		"cpu_start": "$AF5F", "cpu_end_exclusive": "$AF61",
		"sha256": "9cfd8ffe4aa61b6edb3ce004a5a9abe416ccdab9d90f177bbec3197615f6fcfd",
	},
	"animation_66_appearance_AF81_AF94.bin": {
		"file_offset": 0x02AF91, "length_bytes": 0x13,
		"cpu_start": "$AF81", "cpu_end_exclusive": "$AF94",
		"sha256": "60c29f39eba84271190bd6c544e2302871fd0a691d968e415175427c40f65b16",
	},
	"scenario_1C_animation_7A_appearance_AF11_AF12.bin": {
		"file_offset": 0x02AF21, "length_bytes": 0x02,
		"cpu_start": "$AF11", "cpu_end_exclusive": "$AF13",
		"sha256": "3e2a438a1a6f8a2b41460d685c0453bbd4b5f4dc82fb26d51987f7d1ae032913",
	},
	"scenario_1C_animation_7A_appearance_AF13_AF1A.bin": {
		"file_offset": 0x02AF23, "length_bytes": 0x08,
		"cpu_start": "$AF13", "cpu_end_exclusive": "$AF1B",
		"sha256": "8d20c58f02bb52efbec6ceb3f5c0d5c717afa09dcfac5f72194fdac1b4293abe",
	},
	"scenario_1C_animation_7A_appearance_AFDB_AFE2.bin": {
		"file_offset": 0x02AFEB, "length_bytes": 0x08,
		"cpu_start": "$AFDB", "cpu_end_exclusive": "$AFE3",
		"sha256": "ca0b7aa48f8b4b20c274cdf7ea139bd94e24d6411aa06aedb8631346828a8e2a",
	},
	"scenario_1C_animation_7A_appearance_AF23_AF25.bin": {
		"file_offset": 0x02AF33, "length_bytes": 0x03,
		"cpu_start": "$AF23", "cpu_end_exclusive": "$AF26",
		"sha256": "1ba1825c6b7038c2d78b602a3a7d7ce9490e8b0c98b4ac52ee9c92c10eed12a0",
	},
	"motion_step_A38A_A390.bin": {
		"file_offset": 0x02A39A, "length_bytes": 0x0007,
		"cpu_start": "$A38A", "cpu_end_exclusive": "$A391",
		"sha256": "95a66c8108f14acbb8740fd154087efd6230f204ceec3dcf198c3ac07ac31e7f",
	},
	"fresh_actor_motion_roots_A723_A734.bin": {
		"file_offset": 0x02A733, "length_bytes": 0x0012,
		"cpu_start": "$A723", "cpu_end_exclusive": "$A735",
		"sha256": "c68a7d28f793918e44b5b1362ba62a9ab07001d8f1ea2d9177672dd544b0d10e",
	},
	"slot11_actor_motion_sequence_A865_A86B.bin": {
		"file_offset": 0x02A875, "length_bytes": 0x0007,
		"cpu_start": "$A865", "cpu_end_exclusive": "$A86C",
		"sha256": "65eaf22a3ed5bcf5f3c15794d7a247998076950f1e5b6e818630446db47089d5",
	},
	"animation_66_motion_A692_A699.bin": {
		"file_offset": 0x02A6A2, "length_bytes": 0x0007,
		"cpu_start": "$A692", "cpu_end_exclusive": "$A699",
		"sha256": "9f1f35e832dde821c89483f639dd5f7c59692637d858fc40385bb54cbb2f8c60",
	},
	"appearance_pair_B537_B538.bin": {
		"file_offset": 0x02B547, "length_bytes": 0x0002,
		"cpu_start": "$B537", "cpu_end_exclusive": "$B539",
		"sha256": "ac3dd553691cfc83e2d0c9e5aa3033a0577ee305ae7ead73be1cd5708ac21595",
	},
	"appearance_sequence_B539_B5AB.bin": {
		"file_offset": 0x02B549, "length_bytes": 0x0073,
		"cpu_start": "$B539", "cpu_end_exclusive": "$B5AC",
		"sha256": "71395ce43a704960a998018087add1fe2f6f618fc72eb385af5129c661ebe2f0",
	},
	"motion_command_03_A96E_A973.bin": {
		"file_offset": 0x02A97E, "length_bytes": 0x0006,
		"cpu_start": "$A96E", "cpu_end_exclusive": "$A974",
		"sha256": "070a2a73ec593855c684bcffed54024678247eb2791225270800611bc0131dbc",
	},
	"scenario_36_animation_4C_appearance_B43E_B43F.bin": {
		"file_offset": 0x02B44E, "length_bytes": 0x0002,
		"cpu_start": "$B43E", "cpu_end_exclusive": "$B440",
		"sha256": "73e9fd069fa62aaaa639c7aeaede40153dc5f44ec1cbc398ca83b11f70320255",
	},
	"scenario_36_animation_4C_appearance_B440_B470.bin": {
		"file_offset": 0x02B450, "length_bytes": 0x0031,
		"cpu_start": "$B440", "cpu_end_exclusive": "$B471",
		"sha256": "d1d6fd4e587eb100a03da9f0d3938de255df0b8a20cdc9787c66fdabf37a99ab",
	},
	"scenario_36_animation_4C_motion_A79B_A7A0.bin": {
		"file_offset": 0x02A7AB, "length_bytes": 0x0006,
		"cpu_start": "$A79B", "cpu_end_exclusive": "$A7A1",
		"sha256": "c0dc4422d717c9f1b17e4c53af92eae754d7debb337333447a3f8bf9550f9051",
	},
	"scenario_36_animation_E6_appearance_B01E_B0BA.bin": {
		"file_offset": 0x02B02E, "length_bytes": 0x009C,
		"cpu_start": "$B01E", "cpu_end_exclusive": "$B0BA",
		"sha256": "0c2fd8b94a88e80668eebde45c6db9849222428952d609a80be87c4a519d6948",
	},
	"scenario_36_animation_E6_motion_A6C7_A6D5.bin": {
		"file_offset": 0x02A6D7, "length_bytes": 0x000E,
		"cpu_start": "$A6C7", "cpu_end_exclusive": "$A6D5",
		"sha256": "02024591d4bf91c9854c9f052f68b68f8a1467b262866585786791c306bb3e05",
	},
	"scenario_1C_animation_7A_motion_A6D5_A6DB.bin": {
		"file_offset": 0x02A6E5, "length_bytes": 0x07,
		"cpu_start": "$A6D5", "cpu_end_exclusive": "$A6DC",
		"sha256": "912f0675f3e4746a851bac12caaa38578e30531f952789edec3a43f67aa5c158",
	},
	"scenario_1C_animation_7A_motion_A6DC_A6E2.bin": {
		"file_offset": 0x02A6EC, "length_bytes": 0x07,
		"cpu_start": "$A6DC", "cpu_end_exclusive": "$A6E3",
		"sha256": "6107cd3acf7812fa2724fdfb900f23a00d171bb8b7153dd4daf84df194f6c4c7",
	},
	"scenario_1C_animation_7A_motion_A6E3_A6E9.bin": {
		"file_offset": 0x02A6F3, "length_bytes": 0x07,
		"cpu_start": "$A6E3", "cpu_end_exclusive": "$A6EA",
		"sha256": "e7924ca949656222eb4e3c63cd03ec3dc92e3a2935c00ef42665c6e4f5a33a42",
	},
	"scenario_1C_pass_motion_A95C_A966.bin": {
		"file_offset": 0x02A96C, "length_bytes": 0x0B,
		"cpu_start": "$A95C", "cpu_end_exclusive": "$A967",
		"sha256": "b23a445c2705fe05f18f3ead4e5cc57f839081d75824e9f1f1b591582bb523cc",
	},
}

const APPEARANCE_LOOP_CPU_START := 0xB026
const APPEARANCE_LOOP_CPU_END := 0xB031
const APPEARANCE_HOLD_CPU_START := 0xB5AC
const APPEARANCE_HOLD_CPU_END := 0xB5B4
const FRESH_APPEARANCE_ROOT_CPU_START := 0xB30E
const FRESH_APPEARANCE_ROOT_CPU_END := 0xB316
const SLOT11_APPEARANCE_SEQUENCE_CPU_START := 0xB2E0
const SLOT11_APPEARANCE_SEQUENCE_CPU_END := 0xB30E
const MOTION_STEP_CPU_START := 0xA38A
const MOTION_STEP_CPU_END := 0xA391
const FRESH_MOTION_ROOTS_CPU_START := 0xA723
const FRESH_MOTION_ROOTS_CPU_END := 0xA735
const SLOT11_MOTION_ROOT_CPU_START := 0xA865
const SLOT11_MOTION_ROOT_CPU_END := 0xA86C
const ANIMATION_66_APPEARANCE_CPU_START := 0xAF81
const ANIMATION_66_APPEARANCE_CPU_END := 0xAF94
const ANIMATION_66_MOTION_CPU_START := 0xA692
const ANIMATION_66_MOTION_CPU_END := 0xA699
const APPEARANCE_PAIR_7D_CPU_START := 0xB537
const APPEARANCE_PAIR_7D_CPU_END := 0xB539
const APPEARANCE_SEQUENCE_CPU_START := 0xB539
const APPEARANCE_SEQUENCE_CPU_END := 0xB5AC
const ROUTE_MOTION_COMMAND_03_CPU_START := 0xA96E
const ROUTE_MOTION_COMMAND_03_CPU_END := 0xA974
const SCENARIO_36_4C_APPEARANCE_START := 0xB43E
const SCENARIO_36_4C_APPEARANCE_END := 0xB440
const SCENARIO_36_4C_APPEARANCE_CONTINUATION_START := 0xB440
const SCENARIO_36_4C_APPEARANCE_CONTINUATION_END := 0xB471
const SCENARIO_36_4C_MOTION_START := 0xA79B
const SCENARIO_36_4C_MOTION_END := 0xA7A1
const SCENARIO_36_E6_APPEARANCE_START := 0xB01E
const SCENARIO_36_E6_APPEARANCE_END := 0xB0BA
const SCENARIO_36_E6_MOTION_START := 0xA6C7
const SCENARIO_36_E6_MOTION_END := 0xA6D5
const SCENARIO_1C_7A_APPEARANCE_1D_START := 0xAF11
const SCENARIO_1C_7A_APPEARANCE_1D_END := 0xAF13
const SCENARIO_1C_7A_APPEARANCE_1E_START := 0xAF13
const SCENARIO_1C_7A_APPEARANCE_1E_END := 0xAF1B
const SCENARIO_1C_7A_APPEARANCE_LIVE_START := 0xAFDB
const SCENARIO_1C_7A_APPEARANCE_LIVE_END := 0xAFE3
const SCENARIO_1C_7A_APPEARANCE_INDEX_22_START := 0xAF23
const SCENARIO_1C_7A_APPEARANCE_INDEX_22_END := 0xAF26
const SCENARIO_1C_7A_MOTION_64_START := 0xA6D5
const SCENARIO_1C_7A_MOTION_64_END := 0xA6DC
const SCENARIO_1C_7A_MOTION_65_START := 0xA6DC
const SCENARIO_1C_7A_MOTION_65_END := 0xA6E3
const SCENARIO_1C_7A_MOTION_66_START := 0xA6E3
const SCENARIO_1C_7A_MOTION_66_END := 0xA6EA
const SCENARIO_1C_PASS_MOTION_START := 0xA95C
const SCENARIO_1C_PASS_MOTION_END := 0xA967

var last_error: String = ""
var is_configured: bool = false
var _resources: Dictionary = {}


## Loads only project-owned, SHA-256-pinned ROM source spans.
func configure() -> bool:
	last_error = ""
	is_configured = false
	_resources.clear()
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var manifest_variant: Variant = JSON.parse_string(manifest_text)
	if not manifest_variant is Dictionary:
		return _fail("Actor interpreter source manifest is missing or malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != EXPECTED_SCHEMA \
			or str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(manifest.get("prg_bank", "")) != "$14" \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("capture_or_screenshot_bytes_included", true)):
		return _fail("Actor interpreter manifest does not match the target-ROM source contract.")
	var resources_variant: Variant = manifest.get("resources", null)
	if not resources_variant is Array:
		return _fail("Actor interpreter manifest has no resource list.")
	var entries_by_name: Dictionary = {}
	for entry_variant in resources_variant:
		if not entry_variant is Dictionary:
			return _fail("Actor interpreter manifest contains a malformed resource entry.")
		var entry: Dictionary = entry_variant
		var name := str(entry.get("name", ""))
		if entries_by_name.has(name):
			return _fail("Actor interpreter manifest repeats resource " + name + ".")
		entries_by_name[name] = entry

	for name_variant in RESOURCE_SPECS:
		var resource_name := str(name_variant)
		if not entries_by_name.has(resource_name):
			return _fail("Actor interpreter source span is missing: " + resource_name)
		var spec: Dictionary = RESOURCE_SPECS[resource_name]
		var entry: Dictionary = entries_by_name[resource_name]
		if int(entry.get("file_offset", -1)) != int(spec["file_offset"]) \
				or int(entry.get("length_bytes", -1)) != int(spec["length_bytes"]) \
				or str(entry.get("cpu_start", "")) != str(spec["cpu_start"]) \
				or str(entry.get("cpu_end_exclusive", "")) != str(spec["cpu_end_exclusive"]) \
				or str(entry.get("sha256", "")) != str(spec["sha256"]) \
				or str(entry.get("prg_bank", "")) != "$14":
			return _fail("Actor interpreter source metadata differs from the pinned ROM span: " + resource_name)
		var resource_path := SOURCE_DIR + resource_name
		var source_bytes := FileAccess.get_file_as_bytes(resource_path)
		if source_bytes.size() != int(spec["length_bytes"]) \
				or _sha256(source_bytes) != str(spec["sha256"]):
			return _fail("Actor interpreter byte span failed its length/SHA-256 check: %s (bytes %d/%d, SHA-256 %s/%s)." % [
				resource_name, source_bytes.size(), int(spec["length_bytes"]),
				_sha256(source_bytes), str(spec["sha256"])])
		_resources[resource_name] = source_bytes

	if not _matches_motion_step(_resources["motion_step_A38A_A390.bin"]):
		return _fail("The motion-step fixture bytes differ from the exact source sequence.")
	var slot11_appearance: PackedByteArray = _resources["slot11_actor_appearance_sequence_B2E0_B30D.bin"]
	if slot11_appearance.size() != 0x2E \
			or slot11_appearance.slice(0, 0x12) != PackedByteArray([
				0xF1, 0x01, 0x10, 0xF4, 0x01, 0xF1, 0x01, 0x11, 0xF1,
				0x01, 0x12, 0xF5, 0xF1, 0xF7, 0x10, 0xF1, 0xF7, 0x0F,
			]):
		return _fail("Slot-$11 actor appearance commands at `$B2E0` differ from the ROM timed-pair/F4/F5/F7 bytes.")
	if _resources["scenario_36_animation_4E_appearance_AF5F_AF60.bin"] \
			!= PackedByteArray([0xF7, 0xB7]):
		return _fail("Scenario-$36 animation-$4E appearance root is not the source `$F7 $B7` held-descriptor command.")
	if _resources["animation_66_appearance_AF81_AF94.bin"] != PackedByteArray([
		0xF1, 0x06, 0x9E, 0xF1, 0xF7, 0x9F, 0xF7, 0x93, 0xF7, 0x94,
		0xF7, 0x71, 0x01, 0x90, 0x01, 0x91, 0xF3, 0x8D, 0xAF,
	]):
		return _fail("Animation-$66 appearance root `$AF81` differs from the ROM's flip/pair/hold/jump sequence.")
	if _resources["scenario_1C_animation_7A_appearance_AF11_AF12.bin"] != PackedByteArray([0xF7, 0x14]) \
			or _resources["scenario_1C_animation_7A_appearance_AF13_AF1A.bin"] != PackedByteArray([
				0x02, 0x18, 0xF2, 0x02, 0x18, 0xF3, 0x13, 0xAF,
			]):
		return _fail("Scenario-$1C animation-$7A appearances at `$AF11/$AF13` differ from their pointer-bounded ROM commands.")
	if not _matches_fresh_motion_roots(_resources["fresh_actor_motion_roots_A723_A734.bin"]):
		return _fail("The animation-$8F motion-root bytes differ from the exact source loops.")
	if _resources["slot11_actor_motion_sequence_A865_A86B.bin"] != PackedByteArray([
		0x01, 0x0A, 0x30, 0x00, 0x00, 0x00, 0x00,
	]):
		return _fail("Slot-$11 actor motion root `$A865` differs from the ROM `$01` packet and `$00` hold.")
	if _resources["animation_66_motion_A692_A699.bin"] != PackedByteArray([
		0x01, 0x3C, 0xDA, 0xFF, 0xED, 0xFF, 0x00,
	]):
		return _fail("Animation-$66 motion root `$A692` differs from the source `$01` step and `$00` hold.")
	if _resources["appearance_pair_B537_B538.bin"] != PackedByteArray([0x04, 0x7D]):
		return _fail("The frame-8663 appearance pair at `$B537` differs from the ROM `$04 $7D` source bytes.")
	if _resources["motion_command_03_A96E_A973.bin"] != PackedByteArray([
		0x03, 0x3C, 0x84, 0x00, 0x34, 0xFF,
	]):
		return _fail("The frame-8663 motion command at `$A96E` differs from the ROM `$03` packet.")
	if _resources["scenario_36_animation_4C_appearance_B43E_B43F.bin"] != PackedByteArray([0x03, 0x7D]):
		return _fail("Scenario-$36 animation-$4C appearance root `$B43E` differs from the ROM `$03 $7D` pair.")
	var scenario_36_4c_continuation: PackedByteArray = _resources["scenario_36_animation_4C_appearance_B440_B470.bin"]
	if scenario_36_4c_continuation.size() != 0x31 \
			or scenario_36_4c_continuation.slice(0x2E, 0x31) != PackedByteArray([0xF3, 0x62, 0xB4]):
		return _fail("Scenario-$36 animation-$4C continuation does not end in the ROM `$B46E->$B462` source loop.")
	if _resources["scenario_36_animation_4C_motion_A79B_A7A0.bin"] != PackedByteArray([
		0x03, 0x32, 0xD1, 0x00, 0xCD, 0xFC,
	]):
		return _fail("Scenario-$36 animation-$4C motion root `$A79B` differs from its ROM `$03` packet.")
	var e6_appearance: PackedByteArray = _resources["scenario_36_animation_E6_appearance_B01E_B0BA.bin"]
	if e6_appearance.slice(0, 8) != PackedByteArray([0x01, 0xCA, 0xF2, 0x01, 0xCA, 0xF3, 0x1E, 0xB0]) \
			or e6_appearance.slice(0x93, 0x9C) != PackedByteArray([0xF3, 0x28, 0xB0, 0xF3, 0x42, 0xB0, 0xF3, 0x5C, 0xB0]):
		return _fail("Scenario-$36 animation-$E6 appearance roots or shared jump table differ from the ROM bytes.")
	if _resources["scenario_36_animation_E6_motion_A6C7_A6D5.bin"] != PackedByteArray([
		0x01, 0x14, 0xC0, 0xFD, 0x00, 0x00, 0x00,
		0x01, 0x16, 0x80, 0x03, 0x80, 0x03, 0x00,
	]):
		return _fail("Scenario-$36 animation-$E6 motion roots `$A6C7/$A6CE` differ from their ROM source packets.")
	if _resources["scenario_1C_animation_7A_motion_A6D5_A6DB.bin"] != PackedByteArray([
		0x01, 0x14, 0x80, 0xFF, 0xC0, 0xFF, 0x00,
	]) or _resources["scenario_1C_animation_7A_motion_A6DC_A6E2.bin"] != PackedByteArray([
		0x01, 0x14, 0x80, 0x02, 0x40, 0x01, 0x00,
	]) or _resources["scenario_1C_animation_7A_motion_A6E3_A6E9.bin"] != PackedByteArray([
		0x01, 0x28, 0xE0, 0xFF, 0x20, 0x00, 0x00,
	]):
		return _fail("Scenario-$1C animation-$7A motion roots `$A6D5/$A6DC/$A6E3` differ from their pointer-bounded ROM steps.")
	is_configured = true
	return true


## Executes one appearance update followed by one motion update, matching the
## order used for each active actor record in the ROM's $EE9F loop.
func tick_actor(source_record: PackedByteArray) -> TickResult:
	var result := tick_appearance_only(source_record)
	if not result.ok:
		return result
	if not _tick_motion(result.actor_record, result):
		return result
	result.ok = true
	return result


## Advances only the source appearance stream. This is useful when an actor's
## selected motion cursor is outside the separately verified motion slice; it
## never silently applies a substitute movement model.
func tick_appearance_only(source_record: PackedByteArray) -> TickResult:
	var result := TickResult.new()
	result.actor_record = source_record.duplicate()
	if not is_configured:
		result.error = "Configure the hash-checked ROM actor source before ticking."
		return result
	if result.actor_record.size() != ACTOR_RECORD_BYTES:
		result.error = "A ROM actor record must contain exactly 21 bytes."
		return result
	if not _tick_appearance(result.actor_record, result):
		return result
	result.ok = true
	return result


## Advances only the source motion stream, for the ROM's `$0615.6` branch that
## skips appearance but still calls the `$84DC` updater.
func tick_motion_only(source_record: PackedByteArray) -> TickResult:
	var result := TickResult.new()
	result.actor_record = source_record.duplicate()
	if not is_configured:
		result.error = "Configure the hash-checked ROM actor source before ticking."
		return result
	if result.actor_record.size() != ACTOR_RECORD_BYTES:
		result.error = "A ROM actor record must contain exactly 21 bytes."
		return result
	if not _tick_motion(result.actor_record, result):
		return result
	result.ok = true
	return result


func _tick_appearance(record: PackedByteArray, result: TickResult) -> bool:
	var timer := int(record[APPEARANCE_TIMER_OFFSET])
	if timer != 0:
		if timer == 0xFF:
			result.appearance_events.append("hold")
			return true
		record[APPEARANCE_TIMER_OFFSET] = timer - 1
		result.appearance_events.append("timer:%d->%d" % [timer, timer - 1])
		return true

	# `$83E9-$83EF` clears the prior horizontal-flip bit before dispatching the
	# next appearance command. The ROM does this only when the appearance timer
	# reaches zero; timed countdown and `$FF` hold returns skip the clear.
	record[0] &= 0x9F
	var cursor := _read_u16(record, APPEARANCE_POINTER_OFFSET)
	for _command_index in 64:
		var opcode := _source_byte_at(cursor)
		if opcode < 0:
			result.error = "Appearance stream pointer $%04X is outside the preserved source spans." % cursor
			return false
		if opcode < 0xF0:
			var descriptor := _source_byte_at(cursor + 1)
			if descriptor < 0:
				result.error = "Appearance timed pair at $%04X is truncated." % cursor
				return false
			record[APPEARANCE_TIMER_OFFSET] = opcode
			record[APPEARANCE_DESCRIPTOR_OFFSET] = descriptor
			_write_u16(record, APPEARANCE_POINTER_OFFSET, cursor + 2)
			result.appearance_events.append("pair:$%04X wait=%d descriptor=$%02X" % [cursor, opcode, descriptor])
			return true
		match opcode:
			0xF0:
				record[APPEARANCE_TIMER_OFFSET] = 0xFF
				result.appearance_events.append("hold-command:$%04X" % cursor)
				return true
			0xF1:
				record[0] |= 0x20
				result.appearance_events.append("flip-x:$%04X" % cursor)
				cursor += 1
				continue
			0xF2:
				record[0] |= 0x40
				result.appearance_events.append("flip-y:$%04X" % cursor)
				cursor += 1
				continue
			0xF3:
				var target := _source_word_at(cursor + 1)
				if target < 0:
					result.error = "Appearance $F3 absolute stream pointer at $%04X is truncated." % cursor
					return false
				result.appearance_events.append("jump:$%04X->$%04X" % [cursor, target])
				cursor = target
				continue
			0xF4:
				var loop_count := _source_byte_at(cursor + 1)
				if loop_count < 0:
					result.error = "Appearance $F4 loop counter at $%04X is truncated." % cursor
					return false
				record[0x0D] = loop_count
				_write_u16(record, 0x0E, cursor + 2)
				result.appearance_events.append("loop-start:$%04X count=$%02X resume=$%04X" % [
					cursor, loop_count, cursor + 2])
				cursor += 2
				continue
			0xF5:
				var remaining := (int(record[0x0D]) - 1) & 0xFF
				if remaining != 0:
					record[0x0D] = remaining
					var target := _read_u16(record, 0x0E)
					if target < 0x8000 or _source_byte_at(target) < 0:
						result.error = "Appearance $F5 loop at $%04X has invalid saved source pointer $%04X." % [cursor, target]
						return false
					result.appearance_events.append("loop-back:$%04X->$%04X remaining=$%02X" % [
						cursor, target, remaining])
					cursor = target
				else:
					result.appearance_events.append("loop-end:$%04X" % cursor)
					cursor += 1
				continue
			0xF6:
				var local_x := _source_byte_at(cursor + 1)
				var local_y := _source_byte_at(cursor + 2)
				if local_x < 0 or local_y < 0:
					result.error = "Appearance $F6 at $%04X is missing its two local offsets." % cursor
					return false
				record[0x13] = local_x
				record[0x14] = local_y
				result.appearance_events.append("local-offset:$%04X x=$%02X y=$%02X" % [cursor, local_x, local_y])
				cursor += 3
				continue
			0xF7:
				var descriptor := _source_byte_at(cursor + 1)
				if descriptor < 0:
					result.error = "Appearance $F7 at $%04X is missing its descriptor." % cursor
					return false
				record[APPEARANCE_DESCRIPTOR_OFFSET] = descriptor
				record[APPEARANCE_TIMER_OFFSET] = 0xFF
				result.appearance_events.append("descriptor-hold:$%04X=$%02X" % [cursor, descriptor])
				return true
			0xF8:
				var selector := _source_byte_at(cursor + 1)
				if selector < 0:
					result.error = "Appearance $F8 at $%04X is missing its shared selector." % cursor
					return false
				result.shared_ram_writes.append({"address": 0x0546, "value": selector, "source_pc": 0x84D8})
				result.appearance_events.append("shared-selector:$%04X=$%02X" % [cursor, selector])
				cursor += 2
				continue
			_:
				result.error = "Appearance opcode $%02X at $%04X is outside this interpreter slice." % [opcode, cursor]
				return false
	result.error = "Appearance stream exceeded the bounded source-command budget."
	return false


func _tick_motion(record: PackedByteArray, result: TickResult) -> bool:
	var timer := int(record[MOTION_TIMER_OFFSET])
	if timer == 0xFF:
		result.motion_events.append("hold")
		return true
	var scenario_1c_pass_motion_cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	if scenario_1c_pass_motion_cursor == SCENARIO_1C_PASS_MOTION_START \
			or scenario_1c_pass_motion_cursor == SCENARIO_1C_PASS_MOTION_START + 6:
		return _tick_scenario_1c_pass_motion(
			record, result, scenario_1c_pass_motion_cursor, timer)
	var e6_motion_root := _e6_motion_root_for_cursor(_read_u16(record, MOTION_POINTER_OFFSET))
	if e6_motion_root >= 0:
		return _tick_e6_route_motion(record, result, e6_motion_root, timer)
	var scenario_1c_7a_motion_root := _scenario_1c_7a_motion_root_for_cursor(
		_read_u16(record, MOTION_POINTER_OFFSET))
	if scenario_1c_7a_motion_root >= 0:
		return _tick_scenario_1c_7a_motion(record, result, scenario_1c_7a_motion_root, timer)
	var route_root := _fresh_motion_root_for_cursor(_read_u16(record, MOTION_POINTER_OFFSET))
	if route_root >= 0:
		return _tick_fresh_route_motion(record, result, route_root, timer)
	var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	if cursor == SLOT11_MOTION_ROOT_CPU_START \
			or cursor == SLOT11_MOTION_ROOT_CPU_END - 1:
		return _tick_slot11_motion(record, result, cursor, timer)
	if cursor == ANIMATION_66_MOTION_CPU_START + 6 and timer > 0:
		if timer > 0x3C or record[5] != 0xDA or record[7] != 0xFF \
				or record[9] != 0xED or record[11] != 0xFF:
			result.error = "Animation-$66 motion countdown at $A698 lost its source timer/velocity state."
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$A692 timer=$%02X->$%02X" % [timer, timer - 1])
		return true
	if cursor == ROUTE_MOTION_COMMAND_03_CPU_START + 6 and timer > 0:
		if timer > 0x3C or (record[0] & 0x10) == 0 \
				or record[5] != 0x84 or record[7] != 0x00 \
				or record[9] != 0x34 or record[11] != 0xFF:
			result.error = "Route motion countdown at $A974 lost the source $03 timer/velocity/flag state."
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$A96E timer=$%02X->$%02X" % [timer, timer - 1])
		return true
	if cursor == SCENARIO_36_4C_MOTION_START + 6 and timer > 0:
		if timer > 0x32 or (record[0] & 0x10) == 0 \
				or record[5] != 0xD1 or record[7] != 0x00 \
				or record[9] != 0xCD or record[11] != 0xFC:
			result.error = "Scenario-$36 animation-$4C motion countdown at `$A7A1` lost its source timer/velocity state."
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$A79B timer=$%02X->$%02X" % [timer, timer - 1])
		return true
	if timer != 0:
		if timer != 1 or cursor != MOTION_STEP_CPU_START + 6 or not _motion_deltas_are_zero(record):
			result.error = "Motion timer $%02X requires unsupported nonzero/general fixed-point integration." % timer
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		# The $A38A command loaded four zero deltas into the ROM's X/Y motion
		# lanes. The $852A integration path therefore leaves visible coordinates
		# unchanged while the one-count timer reaches zero.
		result.motion_events.append("integrate:$A390 timer=1->0 delta=(0,0)")
		return true

	if cursor == ANIMATION_66_MOTION_CPU_START:
		var source_motion: PackedByteArray = _resources["animation_66_motion_A692_A699.bin"]
		if source_motion != PackedByteArray([0x01, 0x3C, 0xDA, 0xFF, 0xED, 0xFF, 0x00]):
			result.error = "Animation-$66 motion $01 bytes failed their source signature."
			return false
		record[MOTION_TIMER_OFFSET] = int(source_motion[1])
		record[5] = int(source_motion[2])
		record[7] = int(source_motion[3])
		record[9] = int(source_motion[4])
		record[11] = int(source_motion[5])
		_write_u16(record, MOTION_POINTER_OFFSET, ANIMATION_66_MOTION_CPU_START + 6)
		_integrate_source_motion_lanes(record)
		result.motion_events.append("step:$A692 timer=60 velocity=(FF:DA,FF:ED) cursor=$A698")
		return true
	if cursor == ROUTE_MOTION_COMMAND_03_CPU_START:
		var route_motion: PackedByteArray = _resources["motion_command_03_A96E_A973.bin"]
		if route_motion != PackedByteArray([0x03, 0x3C, 0x84, 0x00, 0x34, 0xFF]):
			result.error = "Route motion `$03` packet at `$A96E` failed its source signature."
			return false
		record[MOTION_TIMER_OFFSET] = int(route_motion[1])
		record[MOTION_X_DELTA_LOW_OFFSET] = int(route_motion[2])
		record[MOTION_X_DELTA_HIGH_OFFSET] = int(route_motion[3])
		record[MOTION_Y_DELTA_LOW_OFFSET] = int(route_motion[4])
		record[MOTION_Y_DELTA_HIGH_OFFSET] = int(route_motion[5])
		_write_u16(record, MOTION_POINTER_OFFSET, ROUTE_MOTION_COMMAND_03_CPU_END)
		record[0] |= 0x10
		result.motion_events.append("step:$A96E opcode=$03 timer=60 velocity=(00:84,FF:34) cursor=$A974 flag=$10")
		return true
	if cursor == SCENARIO_36_4C_MOTION_START:
		var route_4c_motion: PackedByteArray = _resources["scenario_36_animation_4C_motion_A79B_A7A0.bin"]
		if route_4c_motion != PackedByteArray([0x03, 0x32, 0xD1, 0x00, 0xCD, 0xFC]):
			result.error = "Scenario-$36 animation-$4C motion `$03` packet at `$A79B` failed its source signature."
			return false
		record[MOTION_TIMER_OFFSET] = int(route_4c_motion[1])
		record[MOTION_X_DELTA_LOW_OFFSET] = int(route_4c_motion[2])
		record[MOTION_X_DELTA_HIGH_OFFSET] = int(route_4c_motion[3])
		record[MOTION_Y_DELTA_LOW_OFFSET] = int(route_4c_motion[4])
		record[MOTION_Y_DELTA_HIGH_OFFSET] = int(route_4c_motion[5])
		_write_u16(record, MOTION_POINTER_OFFSET, SCENARIO_36_4C_MOTION_END)
		record[0] |= 0x10
		_integrate_source_motion_lanes(record)
		result.motion_events.append("step:$A79B opcode=$03 timer=50 velocity=(00:D1,FC:CD) cursor=$A7A1 flag=$10")
		return true
	if cursor == MOTION_STEP_CPU_START:
		var step_bytes: PackedByteArray = _resources["motion_step_A38A_A390.bin"]
		if not _matches_motion_step(step_bytes):
			result.error = "Motion $01 step bytes failed their source signature."
			return false
		# Bank-$14 $85A9 calls $85E7 to load the next byte as +$11, then reads
		# two zero-byte pairs into the X/Y motion lanes and advances to $A390.
		record[MOTION_TIMER_OFFSET] = int(step_bytes[1])
		record[MOTION_X_DELTA_LOW_OFFSET] = int(step_bytes[2])
		record[MOTION_X_DELTA_HIGH_OFFSET] = int(step_bytes[3])
		record[MOTION_Y_DELTA_LOW_OFFSET] = int(step_bytes[4])
		record[MOTION_Y_DELTA_HIGH_OFFSET] = int(step_bytes[5])
		_write_u16(record, MOTION_POINTER_OFFSET, MOTION_STEP_CPU_START + 6)
		result.motion_events.append("step:$A38A timer=1 deltas=(0,0) cursor=$A390")
		return true
	if cursor == MOTION_STEP_CPU_START + 6:
		if _source_byte_at(cursor) != 0:
			result.error = "Motion stream at $A390 is not the source $00 hold command."
			return false
		record[MOTION_TIMER_OFFSET] = 0xFF
		result.motion_events.append("end-hold:$A390")
		return true
	if cursor == ANIMATION_66_MOTION_CPU_START + 6 and _source_byte_at(cursor) == 0:
		record[MOTION_TIMER_OFFSET] = 0xFF
		result.motion_events.append("end-hold:$A698")
		return true
	result.error = "Motion stream pointer $%04X is outside this interpreter slice." % cursor
	return false


## Executes the frame-8781 slot-$11 $01 packet, its countdown/integration, and
## the following source $00 hold. The checked FCEUX RAM frames corroborate the
## command result and per-frame fixed-point updates; runtime inputs remain ROM bytes.
func _tick_slot11_motion(record: PackedByteArray, result: TickResult, cursor: int, timer: int) -> bool:
	var source_motion: PackedByteArray = _resources["slot11_actor_motion_sequence_A865_A86B.bin"]
	if source_motion != PackedByteArray([0x01, 0x0A, 0x30, 0x00, 0x00, 0x00, 0x00]):
		result.error = "Slot-$11 motion source `$A865` differs from the checked ROM packet and hold."
		return false
	if cursor == SLOT11_MOTION_ROOT_CPU_START:
		if timer != 0:
			result.error = "Slot-$11 motion root `$A865` was entered with nonzero timer $%02X." % timer
			return false
		record[MOTION_TIMER_OFFSET] = int(source_motion[1])
		record[MOTION_X_DELTA_LOW_OFFSET] = int(source_motion[2])
		record[MOTION_X_DELTA_HIGH_OFFSET] = int(source_motion[3])
		record[MOTION_Y_DELTA_LOW_OFFSET] = int(source_motion[4])
		record[MOTION_Y_DELTA_HIGH_OFFSET] = int(source_motion[5])
		_write_u16(record, MOTION_POINTER_OFFSET, SLOT11_MOTION_ROOT_CPU_START + 6)
		_integrate_source_motion_lanes(record)
		result.motion_events.append("step:$A865 timer=10 velocity=(00:30,00:00) cursor=$A86B")
		return true
	if cursor != SLOT11_MOTION_ROOT_CPU_END - 1:
		result.error = "Slot-$11 motion cursor `$%04X` is outside its checked `$A865` packet." % cursor
		return false
	if timer == 0:
		record[MOTION_TIMER_OFFSET] = 0xFF
		result.motion_events.append("end-hold:$A86B")
		return true
	if timer > 0x0A or record[MOTION_X_DELTA_LOW_OFFSET] != 0x30 \
			or record[MOTION_X_DELTA_HIGH_OFFSET] != 0 \
			or record[MOTION_Y_DELTA_LOW_OFFSET] != 0 \
			or record[MOTION_Y_DELTA_HIGH_OFFSET] != 0:
		result.error = "Slot-$11 motion countdown at `$A86B` lost its ROM timer or velocity state."
		return false
	record[MOTION_TIMER_OFFSET] = timer - 1
	_integrate_source_motion_lanes(record)
	result.motion_events.append("integrate:$A865 timer=$%02X->$%02X" % [timer, timer - 1])
	return true


## Executes the exact initial $01 velocity command and self-targeting $04 loop
## selected by animation $8F. Only the two preserved roots are accepted.
func _tick_fresh_route_motion(record: PackedByteArray, result: TickResult, root: int, timer: int) -> bool:
	var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	if timer != 0:
		if cursor != root + 6:
			result.error = "Fresh motion timer $%02X is not paired with the source post-$01 cursor $%04X." % [timer, root + 6]
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$%04X timer=$%02X->$%02X" % [root, timer, timer - 1])
		return true

	if cursor == root + 6:
		var jump_opcode := _source_byte_at(cursor)
		var jump_target := _source_word_at(cursor + 1)
		if jump_opcode != 0x04 or jump_target != root:
			result.error = "Fresh motion cursor $%04X is not the byte-verified self-loop command." % cursor
			return false
		result.motion_events.append("jump:$%04X->$%04X" % [cursor, jump_target])
		cursor = jump_target
	if cursor != root or _source_byte_at(cursor) != 0x01:
		result.error = "Fresh motion root $%04X does not begin with the supported source $01 command." % root
		return false

	var duration := _source_byte_at(cursor + 1)
	var x_low := _source_byte_at(cursor + 2)
	var x_high := _source_byte_at(cursor + 3)
	var y_low := _source_byte_at(cursor + 4)
	var y_high := _source_byte_at(cursor + 5)
	if min(duration, min(x_low, min(x_high, min(y_low, y_high)))) < 0:
		result.error = "Fresh motion $01 command at $%04X is truncated." % cursor
		return false
	record[MOTION_TIMER_OFFSET] = duration
	record[MOTION_X_DELTA_LOW_OFFSET] = x_low
	record[MOTION_X_DELTA_HIGH_OFFSET] = x_high
	record[MOTION_Y_DELTA_LOW_OFFSET] = y_low
	record[MOTION_Y_DELTA_HIGH_OFFSET] = y_high
	_write_u16(record, MOTION_POINTER_OFFSET, root + 6)
	_integrate_source_motion_lanes(record)
	result.motion_events.append("step:$%04X timer=$%02X velocity=(%02X:%02X,%02X:%02X) cursor=$%04X" % [
		root, duration, x_high, x_low, y_high, y_low, root + 6,
	])
	return true


## Executes the two scenario-$36 `$E6` source `$01` motion roots, their ROM
## countdown/integration updates, and the following `$00` hold command.
func _tick_e6_route_motion(record: PackedByteArray, result: TickResult, root: int, timer: int) -> bool:
	var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	var source_motion: PackedByteArray = _resources["scenario_36_animation_E6_motion_A6C7_A6D5.bin"]
	var source_offset := root - SCENARIO_36_E6_MOTION_START
	var expected_packet := PackedByteArray([0x01, 0x14, 0xC0, 0xFD, 0x00, 0x00]) \
			if root == 0xA6C7 else PackedByteArray([0x01, 0x16, 0x80, 0x03, 0x80, 0x03])
	if source_offset < 0 or source_offset + 6 > source_motion.size() \
			or source_motion.slice(source_offset, source_offset + 6) != expected_packet:
		result.error = "Scenario-$36 animation-$E6 motion root `$%04X` differs from its checked ROM `$01` packet." % root
		return false
	if timer > 0:
		if cursor != root + 6 or timer > int(expected_packet[1]) \
				or record[5] != expected_packet[2] or record[7] != expected_packet[3] \
				or record[9] != expected_packet[4] or record[11] != expected_packet[5]:
			result.error = "Scenario-$36 animation-$E6 countdown at `$%04X` lost its source timer or velocity." % (root + 6)
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$%04X timer=$%02X->$%02X" % [root, timer, timer - 1])
		return true
	if cursor == root + 6:
		if _source_byte_at(cursor) != 0:
			result.error = "Scenario-$36 animation-$E6 motion at `$%04X` is not the checked `$00` hold." % cursor
			return false
		record[MOTION_TIMER_OFFSET] = 0xFF
		result.motion_events.append("end-hold:$%04X" % cursor)
		return true
	if cursor != root:
		result.error = "Scenario-$36 animation-$E6 motion cursor `$%04X` is outside its root and hold." % cursor
		return false
	record[MOTION_TIMER_OFFSET] = int(expected_packet[1])
	record[MOTION_X_DELTA_LOW_OFFSET] = int(expected_packet[2])
	record[MOTION_X_DELTA_HIGH_OFFSET] = int(expected_packet[3])
	record[MOTION_Y_DELTA_LOW_OFFSET] = int(expected_packet[4])
	record[MOTION_Y_DELTA_HIGH_OFFSET] = int(expected_packet[5])
	_write_u16(record, MOTION_POINTER_OFFSET, root + 6)
	_integrate_source_motion_lanes(record)
	result.motion_events.append("step:$%04X timer=$%02X velocity=(%02X:%02X,%02X:%02X) cursor=$%04X" % [
		root, expected_packet[1], expected_packet[3], expected_packet[2],
		expected_packet[5], expected_packet[4], root + 6,
	])
	return true


## Executes the pointer-selected animation-$7A `$01` motion packets and holds.
## The ROM motion table maps actor indices `$64/$65/$66` to distinct roots.
func _tick_scenario_1c_7a_motion(record: PackedByteArray, result: TickResult,
		root: int, timer: int) -> bool:
	var source_name := ""
	var expected_packet := PackedByteArray()
	if root == SCENARIO_1C_7A_MOTION_64_START:
		source_name = "scenario_1C_animation_7A_motion_A6D5_A6DB.bin"
		expected_packet = PackedByteArray([0x01, 0x14, 0x80, 0xFF, 0xC0, 0xFF])
	elif root == SCENARIO_1C_7A_MOTION_65_START:
		source_name = "scenario_1C_animation_7A_motion_A6DC_A6E2.bin"
		expected_packet = PackedByteArray([0x01, 0x14, 0x80, 0x02, 0x40, 0x01])
	else:
		source_name = "scenario_1C_animation_7A_motion_A6E3_A6E9.bin"
		expected_packet = PackedByteArray([0x01, 0x28, 0xE0, 0xFF, 0x20, 0x00])
	var source_motion: PackedByteArray = _resources[source_name]
	var cursor := _read_u16(record, MOTION_POINTER_OFFSET)
	if source_motion.size() != 7 or source_motion.slice(0, 6) != expected_packet:
		result.error = "Scenario-$1C animation-$7A motion root `$%04X` differs from its checked `$01` packet." % root
		return false
	if timer > 0:
		if cursor != root + 6 or timer > int(expected_packet[1]) \
				or record[5] != expected_packet[2] or record[7] != expected_packet[3] \
				or record[9] != expected_packet[4] or record[11] != expected_packet[5]:
			result.error = "Animation-$7A motion countdown at `$%04X` lost its ROM timer or velocity." % (root + 6)
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$%04X timer=$%02X->$%02X" % [root, timer, timer - 1])
		return true
	if cursor == root + 6:
		if _source_byte_at(cursor) != 0:
			result.error = "Animation-$7A motion at `$%04X` is not the source `$00` hold." % cursor
			return false
		record[MOTION_TIMER_OFFSET] = 0xFF
		result.motion_events.append("end-hold:$%04X" % cursor)
		return true
	if cursor != root:
		result.error = "Animation-$7A motion cursor `$%04X` is outside root `$%04X` and its hold." % [cursor, root]
		return false
	record[MOTION_TIMER_OFFSET] = int(expected_packet[1])
	record[MOTION_X_DELTA_LOW_OFFSET] = int(expected_packet[2])
	record[MOTION_X_DELTA_HIGH_OFFSET] = int(expected_packet[3])
	record[MOTION_Y_DELTA_LOW_OFFSET] = int(expected_packet[4])
	record[MOTION_Y_DELTA_HIGH_OFFSET] = int(expected_packet[5])
	_write_u16(record, MOTION_POINTER_OFFSET, root + 6)
	_integrate_source_motion_lanes(record)
	result.motion_events.append("step:$%04X timer=$%02X velocity=(%02X:%02X,%02X:%02X) cursor=$%04X" % [
		root, expected_packet[1], expected_packet[3], expected_packet[2], expected_packet[5], expected_packet[4], root + 6,
	])
	return true


## Executes the live PASS actor's ROM `$03` velocity packet at `$A95C`, its
## `$852A/$85F2` fixed-point updates, and the following source `$00` hold.
func _tick_scenario_1c_pass_motion(record: PackedByteArray, result: TickResult,
		cursor: int, timer: int) -> bool:
	var source_motion: PackedByteArray = _resources["scenario_1C_pass_motion_A95C_A966.bin"]
	if source_motion != PackedByteArray([0x03, 0x32, 0xD0, 0xFF, 0x95, 0xFF, 0x00, 0x00, 0x04, 0x00, 0x00]):
		result.error = "PASS actor motion source `$A95C` differs from its `$A1B4`-bounded ROM entry."
		return false
	if cursor == SCENARIO_1C_PASS_MOTION_START + 6:
		if timer == 0xFF:
			result.motion_events.append("hold:$A962")
			return true
		if timer == 0:
			if source_motion.slice(6, 10) != PackedByteArray([0x00, 0x00, 0x04, 0x00]) \
					or source_motion[10] != 0 or (record[0] & 0x10) == 0:
				result.error = "PASS actor motion at `$A962` lost the ROM `$04` source skip or `$A966` `$00` hold."
				return false
			record[0] &= 0xEF
			record[MOTION_TIMER_OFFSET] = 0xFF
			result.motion_events.append("end-hold:$A966 skipped=4")
			return true
		if timer > 0x32 or (record[0] & 0x10) == 0 \
				or record[MOTION_X_DELTA_LOW_OFFSET] != 0xD0 \
				or record[MOTION_X_DELTA_HIGH_OFFSET] != 0xFF \
				or record[MOTION_Y_DELTA_LOW_OFFSET] != 0x95 \
				or record[MOTION_Y_DELTA_HIGH_OFFSET] != 0xFF:
			result.error = "PASS actor motion countdown at `$A962` lost the source `$03` timer or velocity lanes."
			return false
		record[MOTION_TIMER_OFFSET] = timer - 1
		_integrate_source_motion_lanes(record)
		result.motion_events.append("integrate:$A95C timer=$%02X->$%02X" % [timer, timer - 1])
		return true
	if cursor != SCENARIO_1C_PASS_MOTION_START or timer != 0:
		result.error = "PASS actor motion cursor `$%04X` is outside the `$A95C` root/hold state." % cursor
		return false
	if source_motion.slice(0, 6) != PackedByteArray([0x03, 0x32, 0xD0, 0xFF, 0x95, 0xFF]):
		result.error = "PASS actor motion `$03` packet at `$A95C` failed its source signature."
		return false
	record[MOTION_TIMER_OFFSET] = int(source_motion[1])
	record[MOTION_X_DELTA_LOW_OFFSET] = int(source_motion[2])
	record[MOTION_X_DELTA_HIGH_OFFSET] = int(source_motion[3])
	record[MOTION_Y_DELTA_LOW_OFFSET] = int(source_motion[4])
	record[MOTION_Y_DELTA_HIGH_OFFSET] = int(source_motion[5])
	_write_u16(record, MOTION_POINTER_OFFSET, SCENARIO_1C_PASS_MOTION_START + 6)
	record[0] |= 0x10
	_integrate_source_motion_lanes(record)
	result.motion_events.append("step:$A95C opcode=$03 timer=50 velocity=(FF:D0,FF:95) cursor=$A962 flag=$10")
	return true


## Mirrors $852A/$85F2's two fixed-point lane updates, including the two
## high-coordinate bits packed into actor byte +$00.
func _integrate_source_motion_lanes(record: PackedByteArray) -> void:
	var high_x := int(record[0]) & 0x01
	var high_y := (int(record[0]) >> 1) & 0x01
	high_x = _integrate_source_motion_axis(record, 0x05, high_x)
	high_y = _integrate_source_motion_axis(record, 0x09, high_y)
	record[0] = (int(record[0]) & 0xFC) | (high_x & 0x01) | ((high_y & 0x01) << 1)


func _integrate_source_motion_axis(record: PackedByteArray, velocity_low_offset: int, high_coordinate: int) -> int:
	var fractional_offset := velocity_low_offset + 1
	var velocity_high_offset := velocity_low_offset + 2
	var integer_position_offset := velocity_low_offset + 3
	var fractional_sum := int(record[fractional_offset]) + int(record[velocity_low_offset])
	record[fractional_offset] = fractional_sum & 0xFF
	var carry := fractional_sum >> 8
	var signed_high_delta := int(record[velocity_high_offset])
	if signed_high_delta >= 0x80:
		high_coordinate = (high_coordinate - 1) & 0xFF
	var integer_sum := int(record[integer_position_offset]) + signed_high_delta + carry
	record[integer_position_offset] = integer_sum & 0xFF
	high_coordinate = (high_coordinate + (integer_sum >> 8)) & 0xFF
	return high_coordinate


func _motion_deltas_are_zero(record: PackedByteArray) -> bool:
	return record[MOTION_X_DELTA_LOW_OFFSET] == 0 \
			and record[MOTION_X_DELTA_HIGH_OFFSET] == 0 \
			and record[MOTION_Y_DELTA_LOW_OFFSET] == 0 \
			and record[MOTION_Y_DELTA_HIGH_OFFSET] == 0


func _source_byte_at(cpu_address: int) -> int:
	var source_name := ""
	var span_start := 0
	var span_end := 0
	if cpu_address >= SCENARIO_1C_7A_APPEARANCE_1D_START \
			and cpu_address < SCENARIO_1C_7A_APPEARANCE_1D_END:
		source_name = "scenario_1C_animation_7A_appearance_AF11_AF12.bin"
		span_start = SCENARIO_1C_7A_APPEARANCE_1D_START
		span_end = SCENARIO_1C_7A_APPEARANCE_1D_END
	elif cpu_address >= SCENARIO_1C_7A_APPEARANCE_1E_START \
			and cpu_address < SCENARIO_1C_7A_APPEARANCE_1E_END:
		source_name = "scenario_1C_animation_7A_appearance_AF13_AF1A.bin"
		span_start = SCENARIO_1C_7A_APPEARANCE_1E_START
		span_end = SCENARIO_1C_7A_APPEARANCE_1E_END
	elif cpu_address >= SCENARIO_1C_7A_APPEARANCE_LIVE_START \
			and cpu_address < SCENARIO_1C_7A_APPEARANCE_LIVE_END:
		source_name = "scenario_1C_animation_7A_appearance_AFDB_AFE2.bin"
		span_start = SCENARIO_1C_7A_APPEARANCE_LIVE_START
		span_end = SCENARIO_1C_7A_APPEARANCE_LIVE_END
	elif cpu_address >= SCENARIO_1C_7A_APPEARANCE_INDEX_22_START \
			and cpu_address < SCENARIO_1C_7A_APPEARANCE_INDEX_22_END:
		source_name = "scenario_1C_animation_7A_appearance_AF23_AF25.bin"
		span_start = SCENARIO_1C_7A_APPEARANCE_INDEX_22_START
		span_end = SCENARIO_1C_7A_APPEARANCE_INDEX_22_END
	elif cpu_address >= SCENARIO_36_E6_APPEARANCE_START and cpu_address < SCENARIO_36_E6_APPEARANCE_END:
		source_name = "scenario_36_animation_E6_appearance_B01E_B0BA.bin"
		span_start = SCENARIO_36_E6_APPEARANCE_START
		span_end = SCENARIO_36_E6_APPEARANCE_END
	elif cpu_address >= SCENARIO_36_E6_MOTION_START and cpu_address < SCENARIO_36_E6_MOTION_END:
		source_name = "scenario_36_animation_E6_motion_A6C7_A6D5.bin"
		span_start = SCENARIO_36_E6_MOTION_START
		span_end = SCENARIO_36_E6_MOTION_END
	elif cpu_address >= SCENARIO_1C_7A_MOTION_64_START \
			and cpu_address < SCENARIO_1C_7A_MOTION_64_END:
		source_name = "scenario_1C_animation_7A_motion_A6D5_A6DB.bin"
		span_start = SCENARIO_1C_7A_MOTION_64_START
		span_end = SCENARIO_1C_7A_MOTION_64_END
	elif cpu_address >= SCENARIO_1C_7A_MOTION_65_START \
			and cpu_address < SCENARIO_1C_7A_MOTION_65_END:
		source_name = "scenario_1C_animation_7A_motion_A6DC_A6E2.bin"
		span_start = SCENARIO_1C_7A_MOTION_65_START
		span_end = SCENARIO_1C_7A_MOTION_65_END
	elif cpu_address >= SCENARIO_1C_7A_MOTION_66_START \
			and cpu_address < SCENARIO_1C_7A_MOTION_66_END:
		source_name = "scenario_1C_animation_7A_motion_A6E3_A6E9.bin"
		span_start = SCENARIO_1C_7A_MOTION_66_START
		span_end = SCENARIO_1C_7A_MOTION_66_END
	elif cpu_address >= APPEARANCE_LOOP_CPU_START and cpu_address < APPEARANCE_LOOP_CPU_END:
		source_name = "appearance_loop_B026_B030.bin"
		span_start = APPEARANCE_LOOP_CPU_START
		span_end = APPEARANCE_LOOP_CPU_END
	elif cpu_address >= APPEARANCE_HOLD_CPU_START and cpu_address < APPEARANCE_HOLD_CPU_END:
		source_name = "appearance_hold_B5AC_B5B3.bin"
		span_start = APPEARANCE_HOLD_CPU_START
		span_end = APPEARANCE_HOLD_CPU_END
	elif cpu_address >= FRESH_APPEARANCE_ROOT_CPU_START and cpu_address < FRESH_APPEARANCE_ROOT_CPU_END:
		source_name = "fresh_actor_appearance_sequence_B30E_B315.bin"
		span_start = FRESH_APPEARANCE_ROOT_CPU_START
		span_end = FRESH_APPEARANCE_ROOT_CPU_END
	elif cpu_address >= SLOT11_APPEARANCE_SEQUENCE_CPU_START \
			and cpu_address < SLOT11_APPEARANCE_SEQUENCE_CPU_END:
		source_name = "slot11_actor_appearance_sequence_B2E0_B30D.bin"
		span_start = SLOT11_APPEARANCE_SEQUENCE_CPU_START
		span_end = SLOT11_APPEARANCE_SEQUENCE_CPU_END
	elif cpu_address >= 0xAF5F and cpu_address < 0xAF61:
		source_name = "scenario_36_animation_4E_appearance_AF5F_AF60.bin"
		span_start = 0xAF5F
		span_end = 0xAF61
	elif cpu_address >= ANIMATION_66_APPEARANCE_CPU_START \
			and cpu_address < ANIMATION_66_APPEARANCE_CPU_END:
		source_name = "animation_66_appearance_AF81_AF94.bin"
		span_start = ANIMATION_66_APPEARANCE_CPU_START
		span_end = ANIMATION_66_APPEARANCE_CPU_END
	elif cpu_address >= MOTION_STEP_CPU_START and cpu_address < MOTION_STEP_CPU_END:
		source_name = "motion_step_A38A_A390.bin"
		span_start = MOTION_STEP_CPU_START
		span_end = MOTION_STEP_CPU_END
	elif cpu_address >= FRESH_MOTION_ROOTS_CPU_START and cpu_address < FRESH_MOTION_ROOTS_CPU_END:
		source_name = "fresh_actor_motion_roots_A723_A734.bin"
		span_start = FRESH_MOTION_ROOTS_CPU_START
		span_end = FRESH_MOTION_ROOTS_CPU_END
	elif cpu_address >= SLOT11_MOTION_ROOT_CPU_START and cpu_address < SLOT11_MOTION_ROOT_CPU_END:
		source_name = "slot11_actor_motion_sequence_A865_A86B.bin"
		span_start = SLOT11_MOTION_ROOT_CPU_START
		span_end = SLOT11_MOTION_ROOT_CPU_END
	elif cpu_address >= ANIMATION_66_MOTION_CPU_START \
			and cpu_address < ANIMATION_66_MOTION_CPU_END:
		source_name = "animation_66_motion_A692_A699.bin"
		span_start = ANIMATION_66_MOTION_CPU_START
		span_end = ANIMATION_66_MOTION_CPU_END
	elif cpu_address >= APPEARANCE_PAIR_7D_CPU_START \
			and cpu_address < APPEARANCE_PAIR_7D_CPU_END:
		source_name = "appearance_pair_B537_B538.bin"
		span_start = APPEARANCE_PAIR_7D_CPU_START
		span_end = APPEARANCE_PAIR_7D_CPU_END
	elif cpu_address >= APPEARANCE_SEQUENCE_CPU_START \
			and cpu_address < APPEARANCE_SEQUENCE_CPU_END:
		source_name = "appearance_sequence_B539_B5AB.bin"
		span_start = APPEARANCE_SEQUENCE_CPU_START
		span_end = APPEARANCE_SEQUENCE_CPU_END
	elif cpu_address >= SCENARIO_1C_PASS_MOTION_START \
			and cpu_address < SCENARIO_1C_PASS_MOTION_END:
		source_name = "scenario_1C_pass_motion_A95C_A966.bin"
		span_start = SCENARIO_1C_PASS_MOTION_START
		span_end = SCENARIO_1C_PASS_MOTION_END
	elif cpu_address >= ROUTE_MOTION_COMMAND_03_CPU_START \
			and cpu_address < ROUTE_MOTION_COMMAND_03_CPU_END:
		source_name = "motion_command_03_A96E_A973.bin"
		span_start = ROUTE_MOTION_COMMAND_03_CPU_START
		span_end = ROUTE_MOTION_COMMAND_03_CPU_END
	elif cpu_address >= SCENARIO_36_4C_APPEARANCE_START \
			and cpu_address < SCENARIO_36_4C_APPEARANCE_END:
		source_name = "scenario_36_animation_4C_appearance_B43E_B43F.bin"
		span_start = SCENARIO_36_4C_APPEARANCE_START
		span_end = SCENARIO_36_4C_APPEARANCE_END
	elif cpu_address >= SCENARIO_36_4C_APPEARANCE_CONTINUATION_START \
			and cpu_address < SCENARIO_36_4C_APPEARANCE_CONTINUATION_END:
		source_name = "scenario_36_animation_4C_appearance_B440_B470.bin"
		span_start = SCENARIO_36_4C_APPEARANCE_CONTINUATION_START
		span_end = SCENARIO_36_4C_APPEARANCE_CONTINUATION_END
	elif cpu_address >= SCENARIO_36_4C_MOTION_START \
			and cpu_address < SCENARIO_36_4C_MOTION_END:
		source_name = "scenario_36_animation_4C_motion_A79B_A7A0.bin"
		span_start = SCENARIO_36_4C_MOTION_START
		span_end = SCENARIO_36_4C_MOTION_END
	if source_name.is_empty() or cpu_address >= span_end:
		return -1
	var source_bytes: PackedByteArray = _resources[source_name]
	var source_offset := cpu_address - span_start
	if source_offset < 0 or source_offset >= source_bytes.size():
		return -1
	return int(source_bytes[source_offset])


func _source_word_at(cpu_address: int) -> int:
	var low := _source_byte_at(cpu_address)
	var high := _source_byte_at(cpu_address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _matches_motion_step(bytes: PackedByteArray) -> bool:
	var expected := [0x01, 0x01, 0, 0, 0, 0, 0]
	if bytes.size() != expected.size():
		return false
	for index in expected.size():
		if int(bytes[index]) != int(expected[index]):
			return false
	return true


func _matches_fresh_motion_roots(bytes: PackedByteArray) -> bool:
	var expected := [
		0x01, 0xEF, 0x26, 0x00, 0x00, 0x00, 0x04, 0x23, 0xA7,
		0x01, 0xA0, 0x40, 0x00, 0x00, 0x00, 0x04, 0x2C, 0xA7,
	]
	if bytes.size() != expected.size():
		return false
	for index in expected.size():
		if int(bytes[index]) != int(expected[index]):
			return false
	return true


func _fresh_motion_root_for_cursor(cursor: int) -> int:
	if cursor == 0xA723 or cursor == 0xA729:
		return 0xA723
	if cursor == 0xA72C or cursor == 0xA732:
		return 0xA72C
	return -1


func _e6_motion_root_for_cursor(cursor: int) -> int:
	if cursor in [0xA6C7, 0xA6CD]:
		return 0xA6C7
	if cursor in [0xA6CE, 0xA6D4]:
		return 0xA6CE
	return -1


func _scenario_1c_7a_motion_root_for_cursor(cursor: int) -> int:
	if cursor in [SCENARIO_1C_7A_MOTION_64_START, SCENARIO_1C_7A_MOTION_64_END - 1]:
		return SCENARIO_1C_7A_MOTION_64_START
	if cursor in [SCENARIO_1C_7A_MOTION_65_START, SCENARIO_1C_7A_MOTION_65_END - 1]:
		return SCENARIO_1C_7A_MOTION_65_START
	if cursor in [SCENARIO_1C_7A_MOTION_66_START, SCENARIO_1C_7A_MOTION_66_END - 1]:
		return SCENARIO_1C_7A_MOTION_66_START
	return -1


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _write_u16(bytes: PackedByteArray, offset: int, value: int) -> void:
	bytes[offset] = value & 0xFF
	bytes[offset + 1] = (value >> 8) & 0xFF


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false
