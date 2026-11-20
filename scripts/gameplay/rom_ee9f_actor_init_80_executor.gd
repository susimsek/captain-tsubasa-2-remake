extends "res://scripts/gameplay/rom_ee9f_empty_actor_call_executor.gd"
class_name RomEe9fActorInit80Executor
## Extends the checked $EE9F executor for one live slot-$01 first call:
## `$053A=$80` selects animation `$8F`; it executes `$F5 $0A`, `$F4`, five
## `$F1` record constructors, and `$F0`, stopping at `$EEB1` before actor work.

const EXTENSION_ROOT := "res://reference/rom_extract/gameplay/ee9f_actor_init_80/"
const EXTENSION_MANIFEST := EXTENSION_ROOT + "manifest.json"
const EXTENSION_SCHEMA := "ct2-ee9f-actor-init-80-source-v1"
const ANIMATION_STREAM_SPECS := {
	0x00: {"path": "res://reference/rom_extract/gameplay/ee9f_actor_init_80/bank14_animation_00_stream_8B48_8B5C.bin",
		"start": 0x8B48, "end": 0x8B5C,
		"sha256": "078e47a4949689c08670624ef54e480a5705db28ebe3f8263599b275cc41d340"},
	0x8F: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_8F.bin",
		"start": 0x9885, "end": 0x98AB,
		"sha256": "584a6c5108c0efe657a9a8e1dc531cabb0572eebdc605540c6578a0f7d7f643f"},
	0x90: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_90.bin",
		"start": 0x98AB, "end": 0x98C5,
		"sha256": "34f5ad052c586a941c1541be51b06324608b5ad70ab38984b3b2467a9269a848"},
	0x8B: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_8B.bin",
		"start": 0x9827, "end": 0x9835,
		"sha256": "137fcb64fd80bc0cabb276fac8817ec7457e05a9ef8d5838dbf21d0bd7164d12"},
	0x5C: {"path": "res://reference/rom_extract/gameplay/first_command_actors/animation_5C_actor_packets_9357.bin",
		"start": 0x9357, "end": 0x9371,
		"sha256": "421e49f864693c445615f708234ce96bbca517cd7256a656dfe5eee3248d1603"},
	0x4E: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_4E.bin",
		"start": 0x9261, "end": 0x926F,
		"sha256": "4f3ad199e4f138ac25c01845f8f2c36039ef5ba32047cd4d8c34a676e03d84cb"},
	0x66: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_66.bin",
		"start": 0x9441, "end": 0x9456,
		"sha256": "535df666a3cc1cc86d51cfd093d06e7201cfd71f5b7199840cff57505eb616ff"},
	0x4C: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_4C.bin",
		"start": 0x9245, "end": 0x9253,
		"sha256": "f0a9b91bf8a1609497efcbf54ba3b692ed204b94a5efd9fbced293fbc9211eee"},
	0xE6: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_E6.bin",
		"start": 0xA0A3, "end": 0xA0A8,
		"sha256": "1a65ba372628aff0f4634033047496041fbd1b8d929f4e78c0d505b653a9a7ca"},
	0x78: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_78.bin",
		"start": 0x9618, "end": 0x9651,
		"sha256": "03760e7556e10254bff30633029d2e2bd18b39534ebb8d3c5f84c4483bd6eca9"},
	0x7A: {"path": "res://reference/rom_extract/gameplay/first_command_actors/route_animation_7A.bin",
		"start": 0x965F, "end": 0x9689,
		"sha256": "2109241cccc2bea34f4f5545be60f2983a174baed4d0f5924cdd2e589b284db5"},
}
const STREAM_DECODER := preload("res://scripts/gameplay/rom_actor_animation_stream_decoder.gd")
const F1_CONSTRUCTOR := preload("res://scripts/gameplay/rom_f1_actor_record_constructor.gd")
const ACTOR_INTERPRETER := preload("res://scripts/gameplay/rom_actor_state_interpreter.gd")
const ACTOR_OAM_BUILDER := preload("res://scripts/gameplay/gameplay_rom_actor_oam_builder.gd")
const PALETTE_HELPER_PATH := "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/fixed_palette_fill_helper_CC02_CC45.bin"
const PALETTE_HELPER_SHA256 := "9fa6a2837a6bcf360ccc1df464b2242fe4a287330b8173c4415718e7fc9cfc68"
const INLINE_APPEND_HELPER_PATH := "res://reference/rom_extract/gameplay/slot09_86f8_worker/fixed_inline_record_append_handler_CCD2_CD0C.bin"
const INLINE_APPEND_HELPER_SHA256 := "7c23b91502ce9ebf01c18cbf401030f35181dbdc359d245cc7d7d57dd2cbc37b"
const PLAYER_PALETTE_CODE_PATH := EXTENSION_ROOT + "bank14_f5_player_palette_81BA_82AF.bin"
const PLAYER_PALETTE_CODE_SHA256 := "a93d0f002b1a3c2c52fe2c14a7f94c10742b6ff2400f01f807fc67482d9a0ad4"
const PLAYER_RECORD_POINTERS_PATH := "res://reference/rom_extract/gameplay/first_command_field/player_record_positions/bank_1f_cd89_record_pointer_table_22.bin"
const PLAYER_RECORD_POINTERS_SHA256 := "b09fe4a47e9910198fc6b2599caebe85071c4292d6f07f089d8dd7848b2e7185"
const PLAYER_GRAPHIC_CLASS_PATH := "res://reference/rom_extract/gameplay/first_command_actors/player_graphic_class_table_88F0_ids_00_22.bin"
const PLAYER_GRAPHIC_CLASS_SHA256 := "9c159d7a0b3c4737eaf6b50c97e870a5e98e796b0fb0e88422fc207e990d59dd"
const NORMAL_PLAYER_PALETTE_PATH := "res://reference/rom_extract/gameplay/first_command_actors/normal_player_palette_table_B80C_ids_00_22.bin"
const NORMAL_PLAYER_PALETTE_SHA256 := "b6c3c9045f74bdf720ec8455dd283cd97619087758f523b28620e353f76a8732"
const FIELD_MARKER_DIV12_VECTOR_PATH := "res://reference/rom_extract/gameplay/scenario36_fd00_mirror/fixed_value_div12_vector_C536_C539.bin"
const FIELD_MARKER_DIV12_VECTOR_SHA256 := "45c5f5dc3181044f55e152be9dd6ec1c7f9664fb4a87340dc5ac758ccc0bc775"
const FIELD_MARKER_DIV12_HELPER_PATH := "res://reference/rom_extract/gameplay/scenario36_fd00_mirror/fixed_value_div12_helper_CDC9_CDE2.bin"
const FIELD_MARKER_DIV12_HELPER_SHA256 := "45eb9e048e38d5655178886e5c61d4245720493c9044e2acc2f180f8c76eba7c"
const EXTENSION_SPANS := {
	"bank14_animation_pointer_entries_00_01_8968.bin": {
		"bank": "$14", "start": 0x8968, "end": 0x896C,
		"file_offset": 0x028978, "length": 4,
		"sha256": "f6ac0c09de712c717a47f603036bb9daa7e9b534bd3891ca06987fc32841fbd8",
	},
	"bank14_animation_00_stream_8B48_8B5C.bin": {
		"bank": "$14", "start": 0x8B48, "end": 0x8B5C,
		"file_offset": 0x028B58, "length": 20,
		"sha256": "078e47a4949689c08670624ef54e480a5705db28ebe3f8263599b275cc41d340",
	},
	"fixed_palette_row_FC50_FC5C.bin": {
		"bank": "$1F", "start": 0xFC50, "end": 0xFC5C,
		"file_offset": 0x03FC60, "length": 12,
		"sha256": "72819f2c36672a1ebd02b00f71e34ec3d55d0825b2cb496ac7e7a06625181ff7",
	},
	"bank14_field_marker_renderer_8624_86DB.bin": {
		"bank": "$14", "start": 0x8624, "end": 0x86DB,
		"file_offset": 0x028634, "length": 0xB7,
		"sha256": "7ddd0958ed7c2601d1fa368e3a7fb02e2f65e25294028a4032bf4b56e8257a82",
	},
	"bank14_field_marker_filters_86DB_871F.bin": {
		"bank": "$14", "start": 0x86DB, "end": 0x871F,
		"file_offset": 0x0286EB, "length": 0x44,
		"sha256": "6e7ec14e25fcfb03924a04a94717f04191bccbb6edb17770a80425de51d2c040",
	},
	"bank14_field_marker_mode_table_8753_8768.bin": {
		"bank": "$14", "start": 0x8753, "end": 0x8768,
		"file_offset": 0x028763, "length": 0x15,
		"sha256": "4a2d98dac6c9f9458e20126c19c5b9d92a0bc65439cda55a0b670fe28c6085d4",
	},
	"bank14_field_marker_mode1_8768_8771.bin": {
		"bank": "$14", "start": 0x8768, "end": 0x8771,
		"file_offset": 0x028778, "length": 0x09,
		"sha256": "13625db542d3c47bef0ac10643e3e85e5d80c7a0d104151e97da775c4264cbab",
	},
	"bank14_field_marker_oam_writer_87E7_881D.bin": {
		"bank": "$14", "start": 0x87E7, "end": 0x881D,
		"file_offset": 0x0287F7, "length": 0x36,
		"sha256": "d689034b7f37f9c39c3d19a39234a7d24a7286696b9fa5242e91101732270c3b",
	},
	"bank14_field_marker_holder_blink_881D_8861.bin": {
		"bank": "$14", "start": 0x881D, "end": 0x8861,
		"file_offset": 0x02882D, "length": 0x44,
		"sha256": "417c3c20f61a58d985c34003632f22c5a5b4e60b7a945729db65a117ecc187f3",
	},
	"bank14_field_marker_position_offsets_88DA_88E4.bin": {
		"bank": "$14", "start": 0x88DA, "end": 0x88E4,
		"file_offset": 0x0288EA, "length": 0x0A,
		"sha256": "9f9a63359392b862a5f366d1169f9be8fc6920da2c2b2fbc84e24a64240f7d1f",
	},
	"fixed_record_pointer_vector_C50C_C50F.bin": {
		"bank": "$1E", "start": 0xC50C, "end": 0xC50F,
		"file_offset": 0x03C51C, "length": 0x03,
		"sha256": "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44",
	},
	"fixed_record_pointer_resolver_CD7C_CD89.bin": {
		"bank": "$1E", "start": 0xCD7C, "end": 0xCD89,
		"file_offset": 0x03CD8C, "length": 0x0D,
		"sha256": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
	},
	"bank14_animation_dispatch_8084_8164.bin": {
		"bank": "$14", "start": 0x8084, "end": 0x8164,
		"file_offset": 0x028094, "length": 0xE0,
		"sha256": "ceed933768c37a2ec41eb1d842271629033a76c2964a4e4c5e957351c1e90040",
	},
	"bank14_animation_pointer_8F_90_8A86.bin": {
		"bank": "$14", "start": 0x8A86, "end": 0x8A8A,
		"file_offset": 0x028A96, "length": 4,
		"sha256": "5472f22efccee0df74f7c3315e6f6286cd3059738f62de03ad91518f5ed752bf",
	},
	"bank14_stream_advance_83CF_83D9.bin": {
		"bank": "$14", "start": 0x83CF, "end": 0x83D9,
		"file_offset": 0x0283DF, "length": 10,
		"sha256": "1bc0ccc250cbd3437f1876e7ecf97fc99b1749a0407e2843420b8c19c9bdd078",
	},
	"fixed_dispatch_C509_C50C.bin": {
		"bank": "$1F", "start": 0xC509, "end": 0xC50C,
		"file_offset": 0x03C519, "length": 3,
		"sha256": "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441",
	},
	"fixed_dispatch_CB99_CBB0.bin": {
		"bank": "$1F", "start": 0xCB99, "end": 0xCBB0,
		"file_offset": 0x03CBA9, "length": 23,
		"sha256": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54",
	},
	"bank14_f5_tail_8164_8171.bin": {
		"bank": "$14", "start": 0x8164, "end": 0x8171,
		"file_offset": 0x028174, "length": 13,
		"sha256": "f58ff4484a0b641cf7c6ae2177af87f4e2d86bcfac612857cb676ab248e731aa",
	},
	"bank14_f8_redirect_816F_817C.bin": {
		"bank": "$14", "start": 0x816F, "end": 0x817C,
		"file_offset": 0x02817F, "length": 13,
		"sha256": "298b3571e8e151db41ba18f0b69f4ad21d2a079bc24f3606ac02b038b9519967",
	},
	"bank14_f6_actor_remove_83AE_83BD.bin": {
		"bank": "$14", "start": 0x83AE, "end": 0x83BD,
		"file_offset": 0x0283BE, "length": 15,
		"sha256": "9491d3c17008fc33fb0f9d7b15779b8a368dec51a8d7aa37182a1038cb76ac75",
	},
	"fixed_palette_vectors_C530_C536.bin": {
		"bank": "$1E", "start": 0xC530, "end": 0xC536,
		"file_offset": 0x03C540, "length": 6,
		"sha256": "a8e8cc65722c34d77be8b617a0bd428012a3d4d94e4bc854e170a0be25363193",
	},
	"fixed_palette_table_FC38_FC50.bin": {
		"bank": "$1F", "start": 0xFC38, "end": 0xFC50,
		"file_offset": 0x03FC48, "length": 24,
		"sha256": "58a59654ad8e2b645032765c7ac634bf700459d40a6fc06def33577f9b731c05",
	},
	"bank14_f5_player_palette_81BA_82AF.bin": {
		"bank": "$14", "start": 0x81BA, "end": 0x82AF,
		"file_offset": 0x0281CA, "length": 0xF5,
		"sha256": "a93d0f002b1a3c2c52fe2c14a7f94c10742b6ff2400f01f807fc67482d9a0ad4",
	},
}

var _extension_sources: Dictionary = {}
var _extension_configured := false
var _animation_streams: Dictionary = {}
var _active_animation_id := -1
var _active_stream_id := -1
var _active_actor_packet_count := 0
var _stream_decoder
var _f1_constructor
var _palette_helper := PackedByteArray()
var _inline_append_helper := PackedByteArray()
var _player_palette_code := PackedByteArray()
var _player_record_pointer_bytes := PackedByteArray()
var _player_graphic_class_bytes := PackedByteArray()
var _normal_player_palette_bytes := PackedByteArray()
var _field_marker_div12_vector := PackedByteArray()
var _field_marker_div12_helper := PackedByteArray()
var _initial_append_cursor := -1
var _animation_call_is_resume := false
var _animation_waiting := false
var _animation_terminal := false


func configure_from_project_sources() -> bool:
	_extension_configured = false
	_extension_sources.clear()
	_animation_streams.clear()
	_active_animation_id = -1
	_active_stream_id = -1
	_active_actor_packet_count = 0
	if not super.configure_from_project_sources():
		return false
	var manifest_file := FileAccess.open(EXTENSION_MANIFEST, FileAccess.READ)
	if manifest_file == null:
		return _fail("The checked active-actor initialization manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The active-actor initialization manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	var spans: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != EXTENSION_SCHEMA \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("trace_state_included", true)) \
			or not spans is Array or spans.size() != EXTENSION_SPANS.size():
		return _fail("The active-actor source manifest targets the wrong ROM, scope, or schema.")
	for filename_variant in EXTENSION_SPANS:
		var filename := String(filename_variant)
		var spec: Dictionary = EXTENSION_SPANS[filename]
		var found: Dictionary = {}
		for item_variant in spans:
			if item_variant is Dictionary and String(item_variant.get("file", "")) == filename:
				found = item_variant
				break
		if found.is_empty():
			return _fail("The active-actor manifest omits `%s`." % filename)
		if String(found.get("bank", "")) != String(spec["bank"]) \
				or _hex_value(String(found.get("cpu_start", ""))) != int(spec["start"]) \
				or _hex_value(String(found.get("cpu_end_exclusive", ""))) != int(spec["end"]) \
				or _hex_value(String(found.get("file_offset", ""))) != int(spec["file_offset"]) \
				or int(found.get("length", -1)) != int(spec["length"]) \
				or String(found.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Active-actor manifest metadata differs for `%s`." % filename)
		var bytes := FileAccess.get_file_as_bytes(EXTENSION_ROOT + filename)
		if bytes.size() != int(spec["length"]) \
				or _sha256(bytes) != String(spec["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Active-actor source bytes failed size/hash/manifest validation: `%s`." % filename)
		_extension_sources[filename] = bytes
	var stream_decoder = STREAM_DECODER.new()
	if not stream_decoder.configure():
		return _fail("The existing animation-stream package failed validation: " + stream_decoder.last_error)
	_stream_decoder = stream_decoder
	_f1_constructor = F1_CONSTRUCTOR.new()
	if not _f1_constructor.configure():
		return _fail("The existing F1 constructor package failed validation: " + _f1_constructor.last_error)
	_palette_helper = FileAccess.get_file_as_bytes(PALETTE_HELPER_PATH)
	_inline_append_helper = FileAccess.get_file_as_bytes(INLINE_APPEND_HELPER_PATH)
	_player_palette_code = FileAccess.get_file_as_bytes(PLAYER_PALETTE_CODE_PATH)
	_player_record_pointer_bytes = FileAccess.get_file_as_bytes(PLAYER_RECORD_POINTERS_PATH)
	_player_graphic_class_bytes = FileAccess.get_file_as_bytes(PLAYER_GRAPHIC_CLASS_PATH)
	_normal_player_palette_bytes = FileAccess.get_file_as_bytes(NORMAL_PLAYER_PALETTE_PATH)
	_field_marker_div12_vector = FileAccess.get_file_as_bytes(FIELD_MARKER_DIV12_VECTOR_PATH)
	_field_marker_div12_helper = FileAccess.get_file_as_bytes(FIELD_MARKER_DIV12_HELPER_PATH)
	if _sha256(_palette_helper) != PALETTE_HELPER_SHA256 \
			or _sha256(_inline_append_helper) != INLINE_APPEND_HELPER_SHA256 \
			or _sha256(_player_palette_code) != PLAYER_PALETTE_CODE_SHA256 \
			or _sha256(_player_record_pointer_bytes) != PLAYER_RECORD_POINTERS_SHA256 \
			or _sha256(_player_graphic_class_bytes) != PLAYER_GRAPHIC_CLASS_SHA256 \
			or _sha256(_normal_player_palette_bytes) != NORMAL_PLAYER_PALETTE_SHA256 \
			or _field_marker_div12_vector != PackedByteArray([0x4C, 0xC9, 0xCD]) \
			or _sha256(_field_marker_div12_vector) != FIELD_MARKER_DIV12_VECTOR_SHA256 \
			or _field_marker_div12_helper != PackedByteArray([0xA2, 0x00, 0xC9, 0x0C,
				0x90, 0x05, 0xE9, 0x0C, 0xE8, 0xD0, 0xF7, 0x0A, 0x0A, 0x0A,
				0x69, 0x54, 0xA8, 0x8A, 0x0A, 0x0A, 0x0A, 0x69, 0x34, 0xAA, 0x60]) \
			or _sha256(_field_marker_div12_helper) != FIELD_MARKER_DIV12_HELPER_SHA256:
		return _fail("A reused fixed-bank helper failed its source-byte hash check.")
	for animation_id_variant: Variant in ANIMATION_STREAM_SPECS:
		var animation_id := int(animation_id_variant)
		var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[animation_id]
		var animation_bytes := FileAccess.get_file_as_bytes(String(stream_spec["path"]))
		if animation_bytes.size() != int(stream_spec["end"]) - int(stream_spec["start"]) \
				or _sha256(animation_bytes) != String(stream_spec["sha256"]):
			return _fail("Animation-$%02X source bytes do not match the checked pointer-bounded stream." % animation_id)
		_animation_streams[animation_id] = animation_bytes
	if not _validate_animation_stream_source(0x00) \
			or not _validate_animation_stream_source(0x8F) \
			or not _validate_animation_stream_source(0x90) \
			or not _validate_animation_stream_source(0x4E) \
			or not _validate_animation_stream_source(0x66) \
			or not _validate_animation_stream_source(0x4C) \
			or not _validate_animation_stream_source(0xE6) \
			or not _validate_animation_stream_source(0x78) \
			or not _validate_animation_stream_source(0x7A):
		return _fail("A checked actor stream differs from its decoded command structure.")
	_extension_configured = true
	return true


func execute_from_source_call(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary) -> Dictionary:
	return _execute_source_call(dispatch, boundary, callee_request, false)


## Executes checked `$8F`/`$4E` actor initialization and the bounded `$66`
## source-wait path, then returns through the live `$CA52` caller boundary.
func execute_to_source_caller(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary) -> Dictionary:
	return _execute_source_call(dispatch, boundary, callee_request, true)


func _execute_source_call(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary, continue_actor_loop: bool) -> Dictionary:
	if not _extension_configured:
		return _failure("Configure the checked actor-init source package first.")
	_animation_call_is_resume = false
	_animation_waiting = false
	_animation_terminal = false
	var base_result: Dictionary = super.execute_from_source_call(dispatch, boundary, callee_request)
	if bool(base_result.get("ok", false)):
		return base_result
	var base_status := String(base_result.get("status", ""))
	if base_status == "stopped_at_first_active_actor" and continue_actor_loop:
		return _resume_active_actor_loop_from_stop(dispatch, callee_request, base_result)
	if base_status == "unsupported_actor_mode" and continue_actor_loop:
		return _resume_empty_actor_marker_branch(dispatch, callee_request, base_result)
	if base_status != "unsupported_bank14_gate":
		return base_result
	if not _validate_actor_init_gate(dispatch, boundary, callee_request, base_result):
		return _failure(error_message)
	_animation_call_is_resume = int(_ram[0x053A]) == 0x01
	_active_animation_id = int(_ram[0x053C])
	_active_stream_id = 0x78 if _active_animation_id == 0xE6 and _animation_call_is_resume else _active_animation_id
	if not _execute_actor_init_to_ee_b1(_active_animation_id):
		return _stopped("unsupported_actor_init_source", int(_cpu.get("pc", 0)), error_message)
	var seed_result := _finish_actor_init_return(dispatch, callee_request)
	if not continue_actor_loop or not bool(seed_result.get("ok", false)):
		return seed_result
	if bool(seed_result.get("returned_to_caller", false)):
		return seed_result
	return _execute_active_actor_loop_to_caller(dispatch, callee_request, seed_result)


## Continues the source `$062D.7` branch when the base executor has already
## visited six inactive actors and stopped at the marker-renderer JSR `$EF45`.
func _resume_empty_actor_marker_branch(dispatch: Dictionary, request: Dictionary,
		base_result: Dictionary) -> Dictionary:
	var partial: Dictionary = base_result.get("partial_state", {})
	var visits: Array = partial.get("actor_visits", [])
	var addresses: Array[int] = []
	if String(base_result.get("status", "")) != "unsupported_actor_mode" \
			or int(base_result.get("stop_pc", -1)) != 0xEF45 \
			or int(_cpu.get("pc", -1)) != 0xEF45 \
			or (int(_ram[0x062D]) & 0x80) == 0 \
			or (int(_ram[0x062D]) & 0x0F) != 1 \
			or int(_ram[0x003A]) != 6 \
			or visits.size() != 6:
		return _stopped("unsupported_empty_actor_marker_entry", int(_cpu.get("pc", 0xEF45)),
			"The stopped source state is not the six-inactive-actor, mode-one `$EF45` branch.")
	for ordinal in range(6):
		var visit_variant: Variant = visits[ordinal]
		if not visit_variant is Dictionary:
			return _stopped("unsupported_empty_actor_marker_entry", 0xEF45,
				"The base actor-loop result omitted an ordered actor visit.")
		var visit: Dictionary = visit_variant
		var actor_address := int(visit.get("actor_pointer", -1))
		if int(visit.get("ordinal", -1)) != ordinal \
				or int(visit.get("actor_index", -1)) != ordinal \
				or not bool(visit.get("inactive", false)) \
				or actor_address < 0 or actor_address + 0x15 > _ram.size() \
				or (int(_ram[actor_address]) & 0x80) != 0:
			return _stopped("unsupported_empty_actor_marker_entry", 0xEF45,
				"The source actor visits do not prove the required ordered all-inactive loop.")
		addresses.append(actor_address)
	if not _execute_actor_mapper_call(0xEF45, 0xEF54, 0x14, 0x15, 0x8009):
		return _stopped("unsupported_field_marker_call", int(_cpu.get("pc", 0xEF45)), error_message)
	if not _execute_field_player_marker_mode_one():
		return _stopped("unsupported_field_marker_source", int(_cpu.get("pc", 0x8624)), error_message)
	if int(_cpu.get("pc", -1)) != 0xEF57:
		return _stopped("field_marker_return_mismatch", int(_cpu.get("pc", -1)),
			"The source field-marker renderer did not return to `$EF57` through its stack.")
	var draw_state := _finish_actor_oam_shadow_to_caller()
	if not bool(draw_state.get("ok", false)):
		return draw_state
	draw_state["actor_records"] = _current_actor_records(addresses)
	draw_state["source_manifest"] = EXTENSION_MANIFEST
	draw_state["actor_loop"] = {
		"status": "returned_to_source_caller", "entry_pc": 0xEEB1,
		"return_pc": 0xCA55, "ordered_record_addresses": addresses,
		"active_actor_count": 0, "actor_outputs": [],
		"sprite_selector": int(_ram[0x0546]), "mirror_mode": int(_ram[0x0517]),
		"scroll_x": int(_ram[0x0538]), "clip_y_min": int(_ram[0x0540]),
		"clip_y_max": int(_ram[0x0541]), "sprites_written": int(_ram[0x0048]),
		"final_oam_cursor": int(_ram[0x003B]), "oam_shadow": _ram.slice(0x0200, 0x0300),
		"source_cycles_modeled": false,
	}
	draw_state["actor_visits"] = visits.duplicate(true)
	draw_state["returned_to_caller"] = true
	draw_state["call_contract"] = base_result.get("call_contract", {}).duplicate(true)
	draw_state["empty_actor_marker_resume"] = {
		"status": "source_marker_branch_executed", "source_stop_pc": 0xEF45,
		"renderer_entry_pc": 0x8624, "mode_dispatch_call_pc": 0x8758,
		"mode_dispatch_target": 0x8768, "position_vector_pc": 0xC536,
		"position_helper_pc": 0xCDC9, "oam_writer_pc": 0x87E7,
		"oam_writer_return_pc": 0x8633, "actor_loop_return_pc": 0xEF57,
		"return_pc": 0xEF57, "mode": int(_ram[0x062D]), "trace_state_used": false,
	}
	draw_state["active_actor_init"] = {
		"status": "field_marker_mode_one", "marker_mode": int(_ram[0x062D]) & 0x0F,
		"mode_value": int(_ram[0x062D]), "source_stop_pc": 0xEF45,
		"renderer_entry_pc": 0x8624, "mode_dispatch_target": 0x8768,
		"position_vector_pc": 0xC536, "position_helper_pc": 0xCDC9,
		"oam_writer_pc": 0x87E7, "oam_writer_return_pc": 0x8633,
		"actor_loop_return_pc": 0xEF57, "cursor_tile": int(_ram[0x0624]),
		"trace_state_used": false,
	}
	return draw_state


## Continues the source loop at `$EEFD` after the base executor reached the
## first active actor in a later `$EE9F` call. This preserves the live prefix
## state instead of replaying the actor loop or injecting a caller endpoint.
func _resume_active_actor_loop_from_stop(dispatch: Dictionary, request: Dictionary,
		base_result: Dictionary) -> Dictionary:
	var detail: Dictionary = base_result.get("detail", {})
	var ordinal := int(detail.get("actor_ordinal", -1))
	var actor_index := int(detail.get("actor_index", -1))
	var actor_address := int(detail.get("actor_pointer", -1))
	if String(base_result.get("status", "")) != "stopped_at_first_active_actor" \
			or int(_cpu.get("pc", -1)) != 0xEEFD \
			or ordinal < 0 or ordinal >= 6 or actor_index != ordinal \
			or _read_actor_pointer_from_rom(actor_index) != actor_address \
			or int(_ram[actor_address]) != int(detail.get("actor_flag", -1)) \
			or int(_ram[0x003A]) != ordinal:
		return base_result
	var interpreter = ACTOR_INTERPRETER.new()
	if not interpreter.configure():
		return _stopped("actor_interpreter_unavailable", 0xEEFD, interpreter.last_error)
	var oam_builder = ACTOR_OAM_BUILDER.new()
	var current_oam: PackedByteArray = _ram.slice(0x0200, 0x0300)
	if current_oam.size() != 0x100:
		return _stopped("actor_oam_shadow_unavailable", 0xEEFD,
			"The live `$0200-$02FF` OAM shadow is missing from the source result.")
	var oam_cursor := int(_ram[0x003B])
	var sprite_count := int(_ram[0x0048])
	var ordered_record_addresses: Array[int] = []
	for index in range(6):
		ordered_record_addresses.append(_read_actor_pointer_from_rom(index))
	var actor_outputs: Array[Dictionary] = []
	for visit_variant in _actor_visits:
		var visit: Dictionary = visit_variant
		var previous_ordinal := int(visit.get("ordinal", -1))
		if previous_ordinal >= 0 and previous_ordinal < 6:
			ordered_record_addresses[previous_ordinal] = int(visit.get("actor_pointer", -1))
	for current_ordinal in range(ordinal, 6):
		var current_index := _resolve_actor_order_index(current_ordinal)
		if current_index != current_ordinal:
			return _stopped("unsupported_actor_order", 0xEEED,
				"The source actor-order nibble at ordinal %d is outside the verified route." % current_ordinal)
		var current_address := _read_actor_pointer_from_rom(current_index)
		if current_address < 0 or current_address + 0x15 > _ram.size():
			return _stopped("unsupported_actor_pointer", 0xEEED,
				"The ROM pointer table returned an invalid actor record address.")
		if current_ordinal == ordinal:
			if current_address != actor_address or int(_cpu.get("pc", -1)) != 0xEEFD:
				return base_result
		else:
			if not _expect_actor_bytes(0xEEDC, [0xA5, 0x3A, 0x4A, 0xAA, 0xBD, 0x43, 0x05,
					0xB0, 0x04, 0x4A, 0x4A, 0x4A, 0x4A, 0x29, 0x0F, 0x0A, 0xAA,
					0xBD, 0x73, 0xEF, 0x85, 0x3C, 0xBD, 0x74, 0xEF, 0x85, 0x3D,
					0xA0, 0x00, 0xB1, 0x3C, 0x10, 0x3B]):
				return _stopped("unsupported_actor_loop_source", 0xEEDC, error_message)
			_record(0xEEDC); _set_a(int(_ram[0x003A]))
			_record(0xEEDE); _lsr_a()
			_record(0xEEDF); _set_x(int(_cpu["a"]))
			_record(0xEEE0); _set_a(int(_ram[0x0543 + int(_cpu["x"])]))
			_record(0xEEE3)
			if _flag(0x01):
				_cpu["pc"] = 0xEEE9
			else:
				for shift_pc in [0xEEE5, 0xEEE6, 0xEEE7, 0xEEE8]:
					_record(shift_pc); _lsr_a()
			_record(0xEEE9); _set_a(int(_cpu["a"]) & 0x0F)
			_record(0xEEEB); _asl_a()
			_record(0xEEEC); _set_x(int(_cpu["a"]))
			if int(_cpu["x"]) >> 1 != current_index:
				return _stopped("unsupported_actor_order", 0xEEED,
					"The executed ROM order nibble does not match the pointer table.")
			_record(0xEEED); _set_a(_source_byte("fixed", 0xEF73 + current_index * 2))
			_record(0xEEF0); _write_ram(0x003C, int(_cpu["a"]), 0xEEF0)
			_record(0xEEF2); _set_a(_source_byte("fixed", 0xEF74 + current_index * 2))
			_record(0xEEF5); _write_ram(0x003D, int(_cpu["a"]), 0xEEF5)
			_record(0xEEF7); _set_y(0)
			_record(0xEEF9); _set_a(int(_ram[current_address]))
			_record(0xEEFB)
		var record_before: PackedByteArray = _ram.slice(current_address, current_address + 0x15)
		if (int(_ram[current_address]) & 0x80) != 0:
			var actor_result := _execute_one_active_actor(current_address, record_before,
				interpreter, oam_builder, current_oam, oam_cursor, sprite_count)
			if not bool(actor_result.get("ok", false)):
				return _stopped(String(actor_result.get("status", "actor_tick_failed")),
					int(actor_result.get("stop_pc", 0xEEFD)),
					String(actor_result.get("error", "The ROM actor update/renderer stopped.")),
					actor_result.get("detail", {}))
			current_oam = actor_result["oam_bytes"]
			oam_cursor = int(actor_result["oam_cursor"])
			sprite_count = int(actor_result["sprite_count"])
			actor_outputs.append(actor_result.get("actor", {}))
			_actor_visits.append({"ordinal": current_ordinal, "actor_index": current_index,
				"actor_pointer": current_address, "flag": int(_ram[current_address]),
				"inactive": false, "appearance_events": actor_result.get("appearance_events", []),
				"motion_events": actor_result.get("motion_events", []),
				"oam": actor_result.get("draw_result", {})})
		else:
			_actor_visits.append({"ordinal": current_ordinal, "actor_index": current_index,
				"actor_pointer": current_address, "flag": int(_ram[current_address]), "inactive": true})
		_record(0xEF38); _inc_ram(0x003A)
		_record(0xEF3A); _set_a(int(_ram[0x003A]))
		_record(0xEF3C); _cmp(int(_cpu["a"]), 0x06)
		_record(0xEF3E)
		if current_ordinal < 5:
			_cpu["pc"] = 0xEEDC
		ordered_record_addresses[current_ordinal] = current_address
	if int(_ram[0x003A]) != 6:
		return _stopped("actor_loop_incomplete", int(_cpu.get("pc", 0xEF40)),
			"The source actor loop did not visit all six ordered records.")
	if not _expect_actor_bytes(0xEF40, [0x2C, 0x2D, 0x06, 0x10, 0x12]):
		return _stopped("unsupported_actor_loop_source", 0xEF40, error_message)
	_record(0xEF40); _set_bit_flags(int(_cpu["a"]), int(_ram[0x062D]))
	_record(0xEF43)
	if (int(_ram[0x062D]) & 0x80) != 0:
		if not _execute_actor_mapper_call(0xEF45, 0xEF54, 0x14, 0x15, 0x8009):
			return _stopped("unsupported_field_marker_call", int(_cpu.get("pc", 0xEF45)), error_message)
		if not _execute_field_player_marker_renderer():
			return _stopped("unsupported_field_marker_source", int(_cpu.get("pc", 0x8624)), error_message)
		if int(_cpu.get("pc", -1)) != 0xEF57:
			return _stopped("field_marker_return_mismatch", int(_cpu.get("pc", -1)),
				"The ROM field-marker renderer did not return to `$EF57` through its source stack.")
		current_oam = _ram.slice(0x0200, 0x0300)
		oam_cursor = int(_ram[0x003B])
		sprite_count = int(_ram[0x0048])
	else:
		_write_ram(0x003B, oam_cursor, 0xEF38)
		_write_ram(0x0048, sprite_count, 0xEF35)
	var draw_state := _finish_actor_oam_shadow_to_caller()
	if not bool(draw_state.get("ok", false)):
		return draw_state
	draw_state["actor_records"] = _current_actor_records(ordered_record_addresses)
	draw_state["source_manifest"] = EXTENSION_MANIFEST
	draw_state["actor_loop"] = {"status": "returned_to_source_caller",
		"entry_pc": 0xEEFD, "continuation_from": 0xEEFD, "return_pc": 0xCA55,
		"ordered_record_addresses": ordered_record_addresses,
		"active_actor_count": actor_outputs.size(), "actor_outputs": actor_outputs,
		"sprite_selector": int(_ram[0x0546]), "mirror_mode": int(_ram[0x0517]),
		"scroll_x": int(_ram[0x0538]), "clip_y_min": int(_ram[0x0540]),
		"clip_y_max": int(_ram[0x0541]), "sprites_written": sprite_count,
		"final_oam_cursor": oam_cursor, "oam_shadow": _ram.slice(0x0200, 0x0300),
		"source_cycles_modeled": false}
	draw_state["active_actor_init"] = {"status": "existing_actor_state",
		"continuation_from": 0xEEFD,
		"source": "live actor record at the `$EEFD` continuation"}
	draw_state["returned_to_caller"] = true
	draw_state["status"] = "returned_to_source_caller"
	draw_state["call_contract"] = _call_contract.duplicate(true)
	return draw_state


func get_status() -> Dictionary:
	var status: Dictionary = super.get_status()
	status["decodes_animation_66_and_e6_source_wait_sequences"] = _extension_configured
	status["active_actor_init_stop"] = "$EEB1 after checked ROM actor commands and source waits; `$EEB1` itself is not executed"
	return status


func _validate_actor_init_gate(dispatch: Dictionary, boundary: Dictionary,
		request: Dictionary, result: Dictionary) -> bool:
	var partial: Dictionary = result.get("partial_state", {})
	var registers: Dictionary = partial.get("registers", {})
	var ram: PackedByteArray = partial.get("ram_image", PackedByteArray())
	var is_resume := ram.size() == RAM_SIZE and int(ram[0x053A]) == 0x01
	if ram.size() == RAM_SIZE:
		_initial_append_cursor = int(ram[0x0498])
	var animation_id := int(ram[0x053C]) if ram.size() == RAM_SIZE else -1
	var stream_cursor := int(ram[0x004C]) | (int(ram[0x004D]) << 8) if ram.size() == RAM_SIZE else -1
	var selector_bytes := ram.slice(0x0494, 0x0498) if ram.size() == RAM_SIZE else PackedByteArray()
	var record1_active := ram.size() == RAM_SIZE and (int(ram[0x055C]) & 0x80) != 0
	var valid_initial_00 := not is_resume and ram.size() == RAM_SIZE \
			and animation_id == 0x00 \
			and ram.slice(0x053A, 0x053E) == PackedByteArray([0x80, 0x00, 0x00, 0x00]) \
			and stream_cursor == 0x9370 \
			and selector_bytes == PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) \
			and int(ram[0x0498]) == 0x01 \
			and int(ram[0x0547]) == 0x81 and int(ram[0x055C]) == 0x81
	var valid_initial_78 := not is_resume and ram.size() == RAM_SIZE \
			and int(ram[0x0518]) == 0x1C \
			and ram.slice(0x0523, 0x052A) == PackedByteArray([0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58]) \
			and ram.slice(0x053A, 0x053E) == PackedByteArray([0x80, 0x00, 0x78, 0x00]) \
			and stream_cursor == 0x9252 \
			and selector_bytes == PackedByteArray([0x04, 0x05, 0x00, 0x00]) \
			and int(ram[0x0498]) == 0x00 \
			and int(ram[0x0547]) == 0x91 and int(ram[0x055C]) == 0x00
	var valid_initial_7A := not is_resume and ram.size() == RAM_SIZE \
			and int(ram[0x0518]) == 0x1C \
			and ram.slice(0x0523, 0x052A) == PackedByteArray([0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58]) \
			and ram.slice(0x053A, 0x053E) == PackedByteArray([0x80, 0x00, 0x7A, 0x00]) \
			and stream_cursor == 0x9252 \
			and selector_bytes == PackedByteArray([0x04, 0x05, 0x00, 0x00]) \
			and int(ram[0x0498]) == 0x00 \
			and int(ram[0x0547]) == 0x91 and int(ram[0x055C]) == 0x00
	var valid_initial_8B := not is_resume and ram.size() == RAM_SIZE \
			and ram.slice(0x053A, 0x053E) == PackedByteArray([0x80, 0x00, 0x8B, 0x00]) \
			and stream_cursor == 0x98C4 \
			and selector_bytes == PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) \
			and int(ram[0x0498]) == 0x00 \
			and int(ram[0x0547]) == 0x81 and int(ram[0x055C]) == 0x81
	var valid_initial := not is_resume and ram.size() == RAM_SIZE \
			and int(ram[0x053A]) == 0x80 and int(ram[0x053B]) == 0 \
			and (animation_id in [0x8F, 0x90, 0x5C, 0x4E, 0x66, 0x4C, 0xE6] \
			or valid_initial_00 or valid_initial_78 or valid_initial_7A or valid_initial_8B)
	var valid_resume_66 := is_resume and animation_id == 0x66 \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 6 \
			and stream_cursor == 0x944F \
			and selector_bytes == PackedByteArray([0x04, 0x05, 0x22, 0x00]) \
			and record1_active
	var valid_resume_e6_first := is_resume and animation_id == 0xE6 \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 0x14 \
			and stream_cursor == 0x9638 \
			and selector_bytes == PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) \
			and record1_active
	var valid_resume_e6_second := is_resume and animation_id == 0xE6 \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 2 \
			and stream_cursor == 0x964A \
			and selector_bytes == PackedByteArray([0x0A, 0x0B, 0x00, 0x00]) \
			and record1_active
	var valid_resume_78_first := is_resume and animation_id == 0x78 \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 0x14 \
			and stream_cursor == 0x9638 \
			and selector_bytes == PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) \
			and record1_active
	var valid_resume_78_second := is_resume and animation_id == 0x78 \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 2 \
			and stream_cursor == 0x964A \
			and selector_bytes == PackedByteArray([0x0A, 0x0B, 0x00, 0x00]) \
			and record1_active
	var valid_resume_7A_first := is_resume and animation_id == 0x7A \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 0x14 \
			and stream_cursor == 0x9673 \
			and selector_bytes == PackedByteArray([0x0C, 0x0D, 0x0E, 0x0F]) \
			and (int(ram[0x0547]) & 0x80) != 0 and record1_active
	var valid_resume_7A_second := is_resume and animation_id == 0x7A \
			and int(ram[0x053B]) >= 1 and int(ram[0x053B]) <= 0x04 \
			and stream_cursor == 0x967C \
			and selector_bytes == PackedByteArray([0x0C, 0x0D, 0x0E, 0x0F]) \
			and (int(ram[0x0547]) & 0x80) == 0 and record1_active
	var valid_resume := valid_resume_66 or valid_resume_e6_first or valid_resume_e6_second \
			or valid_resume_78_first or valid_resume_78_second \
			or valid_resume_7A_first or valid_resume_7A_second
	var source_dispatch: Dictionary = result.get("call_contract", {}).get("dispatch", {})
	if int(result.get("stop_pc", -1)) != 0x8012 \
			or int(registers.get("pc", -1)) != 0x8012 \
			or ram.size() != RAM_SIZE \
			or not valid_initial and not valid_resume \
			or int(ram[0x053D]) != 0 or int(ram[0x0000]) != 0x01 \
			or int(dispatch.get("pc", -1)) != 0xCA52 \
			or int(boundary.get("active_task_slot", -1)) != 0x01 \
			or int(request.get("source_pc", -1)) != 0xCA52 \
			or int(request.get("target_cpu_address", -1)) != 0xEE9F \
			or int(request.get("call_ordinal", -1)) != 0 \
			or source_dispatch != dispatch:
		var animation_init_bytes := ram.slice(0x053A, 0x053E).hex_encode() if ram.size() == RAM_SIZE else "invalid"
		var stream_cursor_text := "$%04X" % stream_cursor if ram.size() == RAM_SIZE else "invalid"
		var selector_text := selector_bytes.hex_encode() if ram.size() == RAM_SIZE else "invalid"
		var append_cursor := int(ram[0x0498]) if ram.size() == RAM_SIZE else -1
		var record0_flag := int(ram[0x0547]) if ram.size() == RAM_SIZE else -1
		var record1_flag := int(ram[0x055C]) if ram.size() == RAM_SIZE else -1
		error_message = "Live `$CA52->$EE9F` boundary does not prove a supported animation-init call or source wait resume: stop=$%04X dispatch_pc=$%04X dispatch_sp=$%02X request_ordinal=%d init[$053A:$053E]=%s resume=%s valid_initial=%s valid_resume=%s source_dispatch_matches=%s cursor=%s selectors=%s append=$%02X actor_flags=[$%02X,$%02X]." % [
			int(result.get("stop_pc", -1)), int(dispatch.get("pc", -1)), int(dispatch.get("sp", -1)),
			int(request.get("call_ordinal", -1)), animation_init_bytes, str(is_resume), str(valid_initial),
			str(valid_resume), str(source_dispatch == dispatch), stream_cursor_text, selector_text,
			append_cursor, record0_flag, record1_flag]
		return false
	for name: String in ["a", "x", "y", "sp", "bank_low", "bank_high"]:
		if not boundary.has(name) or not dispatch.has(name) \
				or int(boundary[name]) != int(dispatch[name]):
			error_message = "Live scheduler snapshot and yielded dispatch disagree on `%s`." % name
			return false
	return true


func _validate_animation_stream_source(animation_id: int) -> bool:
	if not ANIMATION_STREAM_SPECS.has(animation_id) or not _animation_streams.has(animation_id):
		return false
	var spec: Dictionary = ANIMATION_STREAM_SPECS[animation_id]
	var stream: PackedByteArray = _animation_streams[animation_id]
	if stream.size() != int(spec["end"]) - int(spec["start"]):
		return false
	if animation_id == 0x00:
		var pointer_bytes: PackedByteArray = _extension_sources.get(
			"bank14_animation_pointer_entries_00_01_8968.bin", PackedByteArray())
		return stream == PackedByteArray([
			0xF5, 0x0B, 0xF4, 0x1F, 0x00, 0x00, 0x00,
			0xF6, 0x00, 0xF6, 0x15, 0xF6, 0x2A,
			0xF6, 0x3F, 0xF6, 0x54, 0xF6, 0x69, 0xF0]) \
			and pointer_bytes == PackedByteArray([0x48, 0x8B, 0x5C, 0x8B])
	if animation_id == 0x66:
		return stream.slice(0, 7) == PackedByteArray([0xF5, 0x80, 0xF4, 0x04, 0x05, 0x22, 0x00])
	if animation_id == 0x90:
		return stream == PackedByteArray([
			0xF5, 0x80, 0xF4, 0x08, 0x09, 0x0A, 0x0B,
			0xF1, 0x00, 0x58, 0x00, 0xC3, 0x09,
			0xF1, 0x00, 0x4B, 0x00, 0xC3, 0x01,
			0xF1, 0x00, 0x4D, 0x00, 0xC3, 0x05, 0xF0])
	if animation_id == 0x8B:
		return stream == PackedByteArray([
			0xF5, 0x80, 0xF4, 0x20, 0x21, 0x00, 0x00,
			0xF1, 0x00, 0x8F, 0x10, 0xBB, 0x01, 0xF0])
	if animation_id == 0x5C:
		return stream == PackedByteArray([
			0xF5, 0x80, 0xF4, 0x08, 0x09, 0x0A, 0x0B,
			0xF1, 0x00, 0xCD, 0x00, 0xC3, 0x0D,
			0xF1, 0x00, 0xCA, 0x00, 0xC3, 0x01,
			0xF1, 0x00, 0xCB, 0x00, 0xC3, 0x05, 0xF0])
	if animation_id == 0x4C:
		return stream.slice(0, 7) == PackedByteArray([0xF5, 0x09, 0xF4, 0x04, 0x05, 0x00, 0x00])
	if animation_id == 0xE6:
		return stream == PackedByteArray([0xF5, 0x87, 0xF8, 0x1A, 0x96])
	if animation_id == 0x7A:
		return stream == PackedByteArray([
			0xF5, 0x80, 0xF4, 0x0C, 0x0D, 0x0E, 0x0F,
			0xF1, 0x65, 0x1E, 0xD0, 0x93, 0x00,
			0xF1, 0x64, 0x1D, 0x1F, 0xB7, 0x05, 0x14,
			0xF6, 0x00,
			0xF1, 0x00, 0x3F, 0x16, 0xB3, 0x05, 0x04,
			0xF1, 0x66, 0x1D, 0x16, 0xB3, 0x05,
			0xF1, 0xA7, 0x22, 0x0E, 0xAF, 0x01, 0xF0])
	if animation_id == 0x78:
		return stream.slice(0, 7) == PackedByteArray([0xF5, 0x80, 0xF4, 0x08, 0x09, 0x0A, 0x0B]) \
			and int(stream[stream.size() - 1]) == 0xF0
	return stream.slice(0, 7) == PackedByteArray([0xF5, 0x0A, 0xF4, 0x2C, 0x0B, 0x05, 0x07])


func _read_stream_at_live_pointer(offset: int) -> int:
	if not ANIMATION_STREAM_SPECS.has(_active_stream_id) \
			or not _animation_streams.has(_active_stream_id):
		return -1
	var spec: Dictionary = ANIMATION_STREAM_SPECS[_active_stream_id]
	var stream: PackedByteArray = _animation_streams[_active_stream_id]
	var stream_pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var stream_offset := stream_pointer - int(spec["start"]) + offset
	if stream_offset < 0 or stream_offset >= stream.size():
		return -1
	return int(stream[stream_offset])


func _expect_extension(filename: String, pc: int, expected: Array[int]) -> bool:
	for index in range(expected.size()):
		if _extra_byte(filename, pc + index) != expected[index]:
			return _stop_error("Extension ROM byte mismatch at `$%04X` in `%s`." % [pc + index, filename])
	return true


func _extra_byte(filename: String, pc: int) -> int:
	if not _extension_sources.has(filename) or not EXTENSION_SPANS.has(filename):
		return -1
	var spec: Dictionary = EXTENSION_SPANS[filename]
	var offset := pc - int(spec["start"])
	var bytes: PackedByteArray = _extension_sources[filename]
	if offset < 0 or offset >= bytes.size():
		return -1
	return int(bytes[offset])


func _hex_value(value: String) -> int:
	var normalized := value.strip_edges().to_lower()
	if normalized.begins_with("0x"):
		normalized = normalized.substr(2)
	return normalized.hex_to_int()


func _execute_actor_init_to_ee_b1(animation_id: int) -> bool:
	_active_actor_packet_count = 0
	if not _validate_actor_init_source_bytes():
		return false
	if not _validate_animation_stream_source(animation_id):
		return _stop_error("The live actor-init animation `$%02X` has no checked command stream." % animation_id)
	if animation_id == 0x00:
		return _execute_animation_00_to_ee_b1()
	var decoded: Dictionary = _stream_decoder.decode_animation(animation_id)
	if not bool(decoded.get("ok", false)) \
			or not _validate_decoded_events(decoded.get("events", []), animation_id):
		return _stop_error("Checked animation `$%02X` decode is outside the audited F5/F4/F1/F0 forms." % animation_id)
	var events: Array = decoded["events"]
	if _animation_call_is_resume and animation_id == 0x66:
		return _resume_animation_66_to_ee_b1(events)
	if _animation_call_is_resume and animation_id == 0xE6:
		return _resume_animation_e6_to_ee_b1(events)
	if _animation_call_is_resume and animation_id == 0x78:
		return _resume_animation_78_to_ee_b1(events)
	if _animation_call_is_resume and animation_id == 0x7A:
		return _resume_animation_7A_to_ee_b1(events)
	if not _execute_actor_init_prelude(animation_id):
		return false
	if not _execute_f5_event(events[0]) or int(_cpu["pc"]) != 0x8078:
		return false
	_record(0x8078)
	if animation_id == 0xE6:
		if not _execute_redirect_event(events[1]) or int(_cpu["pc"]) != 0x8078:
			return false
		_record(0x8078)
		return _execute_e6_events_until_wait_or_end(events, 2)
	if animation_id == 0x78:
		return _execute_animation_78_events_until_wait_or_end(events, 1)
	if animation_id == 0x7A:
		if not _execute_f4_event(events[1]) or int(_cpu["pc"]) != 0x8078:
			return false
		_record(0x8078)
		return _execute_animation_7A_events_until_wait_or_end(events, 2)
	if not _execute_f4_event(events[1]) or int(_cpu["pc"]) != 0x8078:
		return false
	_record(0x8078)
	for index in range(2, events.size()):
		var event = events[index]
		if event.kind == STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET:
			if not _execute_f1_event(event):
				if error_message.is_empty():
					return _stop_error("F1 handler stopped without a diagnostic for animation `$%02X` packet `$%04X` (%s)." % [
						animation_id, int(event.source_cpu_address), event.raw_bytes.hex_encode()])
				return false
			if int(_cpu["pc"]) != 0x8078:
				return _stop_error("ROM `$80AA` returned to `$%04X` after animation `$%02X` F1 at `$%04X`; expected `$8078`." % [
					int(_cpu["pc"]), animation_id, int(event.source_cpu_address)])
			_record(0x8078)
		elif event.kind == STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS:
			return _execute_wait_event(event)
		elif event.kind == STREAM_DECODER.SourceEvent.Kind.STREAM_END:
			if not _execute_f0_event(event):
				return false
			_animation_terminal = true
			return true
		else:
			return _stop_error("Animation `$%02X` emitted an unsupported live command kind %s." % [animation_id, str(event.kind)])
	return _stop_error("Animation `$%02X` event sequence ended without `$F0` or a source wait." % animation_id)


## Executes only the live scenario-$38 animation-$00 reset stream. The pointer
## table, pointer-bounded bytes, F5 palette row, and each F6 record offset are
## pinned to this ROM-derived call profile.
func _execute_animation_00_to_ee_b1() -> bool:
	if _animation_call_is_resume or _active_animation_id != 0x00 \
			or _active_stream_id != 0x00 \
			or not _validate_animation_stream_source(0x00) \
			or not _expect_extension("bank14_animation_pointer_entries_00_01_8968.bin", 0x8968,
				[0x48, 0x8B, 0x5C, 0x8B]) \
			or not _expect_extension("fixed_palette_row_FC50_FC5C.bin", 0xFC50,
				[0x36, 0x31, 0x30, 0x07, 0x18, 0x28, 0x00, 0x00, 0x00, 0x0F, 0x30, 0x11]):
		return _stop_error("The live scenario-$38 animation-$00 source profile is not byte-verified.")
	if not _execute_actor_init_prelude(0x00):
		return false
	var stream: PackedByteArray = _animation_streams[0x00]
	var f5: Variant = _make_animation_source_event(STREAM_DECODER.SourceEvent.Kind.SETUP_OPERAND,
		0x8B48, stream.slice(0, 2))
	if not _execute_f5_event(f5) or int(_cpu.get("pc", -1)) != 0x8078:
		return false
	_record(0x8078)
	var f4: Variant = _make_animation_source_event(STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS,
		0x8B4A, stream.slice(2, 7))
	if not _execute_f4_event(f4) or int(_cpu.get("pc", -1)) != 0x8078:
		return false
	_record(0x8078)
	var expected_offsets: Array[int] = [0x00, 0x15, 0x2A, 0x3F, 0x54, 0x69]
	for index in range(expected_offsets.size()):
		var stream_offset := 7 + index * 2
		var packet := stream.slice(stream_offset, stream_offset + 2)
		if packet != PackedByteArray([0xF6, expected_offsets[index]]):
			return _stop_error("Animation-$00 F6 packet %d differs from its pointer-bounded source bytes." % index)
		var remove_event: Variant = _make_animation_source_event(STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE,
			0x8B48 + stream_offset, packet, expected_offsets[index])
		if not _execute_f6_event(remove_event) or int(_cpu.get("pc", -1)) != 0x8078:
			return false
		_record(0x8078)
	var end_event: Variant = _make_animation_source_event(STREAM_DECODER.SourceEvent.Kind.STREAM_END,
		0x8B5B, stream.slice(19, 20))
	if not _execute_f0_event(end_event):
		return false
	return true


func _make_animation_source_event(kind: int, source_cpu_address: int,
		raw_bytes: PackedByteArray, actor_record_offset: int = -1):
	var event = STREAM_DECODER.SourceEvent.new()
	event.kind = kind
	event.selected_animation_id = 0x00
	event.source_stream_id = 0x00
	event.source_cpu_address = source_cpu_address
	event.source_file_offset = 0x028B58 + source_cpu_address - 0x8B48
	event.opcode = int(raw_bytes[0]) if not raw_bytes.is_empty() else -1
	event.raw_bytes = raw_bytes
	event.actor_record_offset = actor_record_offset
	return event


func _execute_wait_event(event) -> bool:
	var stream_pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var expected_wait_byte := -1
	if _active_animation_id == 0x66:
		if int(event.source_cpu_address) == 0x944E:
			expected_wait_byte = 0x06
	elif _active_animation_id == 0x7A and _active_stream_id == 0x7A:
		if int(event.source_cpu_address) == 0x9672:
			expected_wait_byte = 0x14
		elif int(event.source_cpu_address) == 0x967B:
			expected_wait_byte = 0x04
	elif _active_animation_id == 0xE6 and _active_stream_id == 0x78:
		if int(event.source_cpu_address) == 0x9637:
			expected_wait_byte = 0x14
		elif int(event.source_cpu_address) == 0x9649:
			expected_wait_byte = 0x02
	elif _active_animation_id == 0x78 and _active_stream_id == 0x78:
		if int(event.source_cpu_address) == 0x9637:
			expected_wait_byte = 0x14
		elif int(event.source_cpu_address) == 0x9649:
			expected_wait_byte = 0x02
	if expected_wait_byte < 0 \
			or event.kind != STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS \
			or event.source_stream_id != _active_stream_id \
			or event.raw_bytes != PackedByteArray([expected_wait_byte]) \
			or int(event.wait_ticks) != expected_wait_byte \
			or stream_pointer != int(event.source_cpu_address) \
			or _read_stream_at_live_pointer(0) != expected_wait_byte \
			or not _expect_bank14(0x8067, [0xCE, 0x3B, 0x05, 0xF0, 0x01, 0x60,
				0xA0, 0x00, 0xB1, 0x4C, 0xC9, 0xF0, 0x90, 0x06, 0x20, 0x84, 0x80,
				0x4C, 0x6D, 0x80, 0x8D, 0x3B, 0x05, 0xA9, 0x01, 0x20, 0xCF, 0x83, 0x60]):
		return _stop_error("The live low-byte animation wait no longer matches ROM `$8067->$8083` or its source cursor.")
	_record(0x806D); _set_y(0)
	_record(0x806F); _set_a(_read_stream_at_live_pointer(0))
	_record(0x8071); _cmp(int(_cpu["a"]), 0xF0)
	_record(0x8073)
	if _flag(0x01) or int(_cpu["a"]) >= 0xF0:
		return _stop_error("ROM wait byte `$06` unexpectedly entered the animation opcode dispatch path.")
	_record(0x807B); _write_ram(0x053B, int(_cpu["a"]), 0x807B)
	_record(0x807E); _set_a(1)
	_record(0x8080); _jsr(0x8080, 0x83CF)
	if not _advance_stream_helper_for(1):
		return false
	_record(0x8083); _rts(0x8083)
	_animation_waiting = true
	var expected_countdown := expected_wait_byte
	var expected_cursor := stream_pointer + 1
	if int(_cpu["pc"]) != 0xEEB1 or int(_ram[0x053B]) != expected_countdown \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != expected_cursor:
		return _stop_error("Animation wait returned to `$%04X` / SP `$%02X`, countdown=$%02X cursor=$%04X; expected `$EEB1` / `$28`, %d ticks, and `$%04X`." % [
			int(_cpu["pc"]), int(_cpu["sp"]), int(_ram[0x053B]),
			int(_ram[0x004C]) | (int(_ram[0x004D]) << 8), expected_countdown, expected_cursor])
	return true


func _execute_redirect_event(event) -> bool:
	var stream_pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	if _active_animation_id != 0xE6 or _active_stream_id != 0xE6 \
			or event.kind != STREAM_DECODER.SourceEvent.Kind.ABSOLUTE_REDIRECT \
			or event.source_stream_id != 0xE6 or int(event.source_cpu_address) != 0xA0A5 \
			or event.raw_bytes != PackedByteArray([0xF8, 0x1A, 0x96]) \
			or int(event.redirect_target_cpu_address) != 0x961A \
			or int(event.redirect_target_stream_id) != 0x78 or stream_pointer != 0xA0A5 \
			or not _expect_extension("bank14_f8_redirect_816F_817C.bin", 0x816F,
				[0xA0, 0x01, 0xB1, 0x4C, 0xAA, 0xC8, 0xB1, 0x4C, 0x86, 0x4C, 0x85, 0x4D, 0x60]):
		return _stop_error("The live `$F8` command does not prove the ROM `$A0A5->$961A` redirect and `$816F` handler.")
	if not _begin_stream_command(0x816F):
		return false
	_record(0x816F); _set_y(1)
	_record(0x8171); _set_a(_read_stream_at_live_pointer(int(_cpu["y"])))
	_record(0x8173); _set_x(int(_cpu["a"]))
	_record(0x8174); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0x8175); _set_a(_read_stream_at_live_pointer(int(_cpu["y"])))
	_record(0x8177); _write_ram(0x004C, int(_cpu["x"]), 0x8177)
	_record(0x8179); _write_ram(0x004D, int(_cpu["a"]), 0x8179)
	_record(0x817B); _rts(0x817B)
	_active_stream_id = int(event.redirect_target_stream_id)
	if int(_cpu.get("pc", -1)) != 0x8078 \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != int(event.redirect_target_cpu_address):
		return _stop_error("The ROM `$816F` redirect returned to `$%04X` with stream cursor `$%04X`; expected `$8078/$961A`." % [
			int(_cpu.get("pc", -1)), int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)])
	return true


func _execute_f6_event(event) -> bool:
	var stream_pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var expected_offsets := {0x8B4F: 0x00, 0x8B51: 0x15, 0x8B53: 0x2A,
		0x8B55: 0x3F, 0x8B57: 0x54, 0x8B59: 0x69} if _active_animation_id == 0x00 \
		else ({0x9673: 0x00} if _active_animation_id == 0x7A \
		else {0x963D: 0x00, 0x963F: 0x2A, 0x9641: 0x3F})
	var valid_animation_stream := (_active_animation_id == 0x00 and _active_stream_id == 0x00) \
		or (_active_animation_id == 0x7A and _active_stream_id == 0x7A) \
		or (_active_animation_id == 0xE6 and _active_stream_id == 0x78) \
		or (_active_animation_id == 0x78 and _active_stream_id == 0x78)
	if not valid_animation_stream \
			or event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE \
			or event.source_stream_id != _active_stream_id or not expected_offsets.has(int(event.source_cpu_address)) \
			or stream_pointer != int(event.source_cpu_address) \
			or int(event.actor_record_offset) != int(expected_offsets.get(int(event.source_cpu_address), -1)) \
			or event.raw_bytes != PackedByteArray([0xF6, int(event.actor_record_offset)]) \
			or int(event.actor_record_offset) >= 0x6A \
			or not _expect_extension("bank14_f6_actor_remove_83AE_83BD.bin", 0x83AE,
				[0xA0, 0x01, 0xB1, 0x4C, 0xAA, 0xA9, 0x00, 0x9D, 0x47, 0x05, 0xA9, 0x02, 0x4C, 0xCF, 0x83]):
		return _stop_error("The live `$F6` command does not match the selected source animation's actor-record removals.")
	if not _begin_stream_command(0x83AE):
		return false
	_record(0x83AE); _set_y(1)
	_record(0x83B0); _set_a(_read_stream_at_live_pointer(int(_cpu["y"])))
	_record(0x83B2); _set_x(int(_cpu["a"]))
	_record(0x83B3); _set_a(0)
	_record(0x83B5); _write_ram(0x0547 + int(_cpu["x"]), int(_cpu["a"]), 0x83B8)
	_record(0x83B8); _set_a(2)
	_record(0x83BA); _cpu["pc"] = 0x83CF
	if not _advance_stream_helper_for(2):
		return false
	return int(_cpu.get("pc", -1)) == 0x8078


func _execute_e6_events_until_wait_or_end(events: Array, start_index: int) -> bool:
	for index in range(start_index, events.size()):
		var event = events[index]
		var executed := false
		match event.kind:
			STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS:
				executed = _execute_f4_event(event)
			STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET:
				executed = _execute_f1_event(event)
			STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE:
				executed = _execute_f6_event(event)
			STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS:
				return _execute_wait_event(event)
			STREAM_DECODER.SourceEvent.Kind.STREAM_END:
				if not _execute_f0_event(event):
					return false
				_animation_terminal = true
				return true
			_:
				return _stop_error("Animation `$E6` emitted an unsupported redirected command kind %s at `$%04X`." % [
					str(event.kind), int(event.source_cpu_address)])
		if not executed:
			return false
		if int(_cpu.get("pc", -1)) != 0x8078:
			return _stop_error("Animation `$E6` command at `$%04X` returned to `$%04X`, expected `$8078`." % [
				int(event.source_cpu_address), int(_cpu.get("pc", -1))])
		_record(0x8078)
	return _stop_error("Animation `$E6` redirected command stream ended without a source wait or `$F0`.")


func _execute_animation_78_events_until_wait_or_end(events: Array, start_index: int) -> bool:
	for index in range(start_index, events.size()):
		var event = events[index]
		var executed := false
		match event.kind:
			STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS:
				executed = _execute_f4_event(event)
			STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET:
				executed = _execute_f1_event(event)
			STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE:
				executed = _execute_f6_event(event)
			STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS:
				return _execute_wait_event(event)
			STREAM_DECODER.SourceEvent.Kind.STREAM_END:
				if not _execute_f0_event(event):
					return false
				_animation_terminal = true
				return true
			_:
				return _stop_error("Animation `$78` emitted an unsupported source command kind %s at `$%04X`." % [
					str(event.kind), int(event.source_cpu_address)])
		if not executed:
			return false
		if int(_cpu.get("pc", -1)) != 0x8078:
			return _stop_error("Animation `$78` command at `$%04X` returned to `$%04X`, expected `$8078`." % [
				int(event.source_cpu_address), int(_cpu.get("pc", -1))])
		_record(0x8078)
	return _stop_error("Animation `$78` source stream ended without a wait or `$F0`.")


func _execute_animation_7A_events_until_wait_or_end(events: Array, start_index: int) -> bool:
	for index in range(start_index, events.size()):
		var event = events[index]
		var executed := false
		match event.kind:
			STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET:
				executed = _execute_f1_event(event)
			STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE:
				executed = _execute_f6_event(event)
			STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS:
				return _execute_wait_event(event)
			STREAM_DECODER.SourceEvent.Kind.STREAM_END:
				if not _execute_f0_event(event):
					return false
				_animation_terminal = true
				return true
			_:
				return _stop_error("Animation `$7A` emitted an unsupported source command kind %s at `$%04X`." % [
					str(event.kind), int(event.source_cpu_address)])
		if not executed:
			return false
		if int(_cpu.get("pc", -1)) != 0x8078:
			return _stop_error("Animation `$7A` command at `$%04X` returned to `$%04X`, expected `$8078`." % [
				int(event.source_cpu_address), int(_cpu.get("pc", -1))])
		_record(0x8078)
	return _stop_error("Animation `$7A` source stream ended without a wait or `$F0`.")


func _resume_animation_7A_to_ee_b1(events: Array) -> bool:
	var pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var first_wait := pointer == 0x9673
	var max_ticks := 0x14 if first_wait else 0x04
	if _active_animation_id != 0x7A or _active_stream_id != 0x7A or events.size() != 11 \
			or pointer not in [0x9673, 0x967C] or int(_cpu.get("pc", -1)) != 0x8012 \
			or int(_ram[0x053A]) != 1 or int(_ram[0x053B]) < 1 or int(_ram[0x053B]) > max_ticks \
			or _ram.slice(0x0494, 0x0498) != PackedByteArray([0x0C, 0x0D, 0x0E, 0x0F]) \
			or (int(_ram[0x055C]) & 0x80) == 0 \
			or not _expect_bank14(0x8067, [0xCE, 0x3B, 0x05, 0xF0, 0x01, 0x60,
				0xA0, 0x00, 0xB1, 0x4C, 0xC9, 0xF0, 0x90, 0x06, 0x20, 0x84, 0x80,
				0x4C, 0x6D, 0x80, 0x8D, 0x3B, 0x05, 0xA9, 0x01, 0x20, 0xCF, 0x83, 0x60]):
		return _stop_error("The live `$7A` resume does not match one of its two source countdown cursors.")
	_record(0x8012); _record(0x8014)
	if int(_cpu.get("a", -1)) != 1 or _flag(0x80):
		return _stop_error("The resumed `$800F` call did not take the positive `$053A` countdown branch for `$7A`.")
	_record(0x8067); _write_ram(0x053B, int(_ram[0x053B]) - 1, 0x8067)
	_set_nz(int(_ram[0x053B]))
	_record(0x806A)
	if int(_ram[0x053B]) > 0:
		_record(0x806C); _rts(0x806C)
		_animation_waiting = true
		return int(_cpu.get("pc", -1)) == 0xEEB1 and int(_cpu.get("sp", -1)) == 0x28
	return _execute_animation_7A_events_until_wait_or_end(events, 5 if first_wait else 8)


func _resume_animation_e6_to_ee_b1(events: Array) -> bool:
	var pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var first_wait := pointer == 0x9638
	var expected_selectors := PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) if first_wait \
			else PackedByteArray([0x0A, 0x0B, 0x00, 0x00])
	var max_ticks := 0x14 if first_wait else 0x02
	if _active_animation_id != 0xE6 or _active_stream_id != 0x78 or events.size() != 16 \
			or pointer not in [0x9638, 0x964A] or int(_cpu.get("pc", -1)) != 0x8012 \
			or int(_ram[0x053A]) != 1 or int(_ram[0x053B]) < 1 or int(_ram[0x053B]) > max_ticks \
			or _ram.slice(0x0494, 0x0498) != expected_selectors \
			or (int(_ram[0x055C]) & 0x80) == 0 \
			or not _expect_bank14(0x8067, [0xCE, 0x3B, 0x05, 0xF0, 0x01, 0x60,
				0xA0, 0x00, 0xB1, 0x4C, 0xC9, 0xF0, 0x90, 0x06, 0x20, 0x84, 0x80,
				0x4C, 0x6D, 0x80, 0x8D, 0x3B, 0x05, 0xA9, 0x01, 0x20, 0xCF, 0x83, 0x60]):
		return _stop_error("The live `$E6` resume does not match one of the two source countdown cursors.")
	_record(0x8012); _record(0x8014)
	if int(_cpu.get("a", -1)) != 1 or _flag(0x80):
		return _stop_error("The resumed `$800F` call did not take the positive `$053A` countdown branch for `$E6`.")
	_record(0x8067); _write_ram(0x053B, int(_ram[0x053B]) - 1, 0x8067)
	_set_nz(int(_ram[0x053B]))
	_record(0x806A)
	if int(_ram[0x053B]) > 0:
		_record(0x806C); _rts(0x806C)
		_animation_waiting = true
		return int(_cpu.get("pc", -1)) == 0xEEB1 and int(_cpu.get("sp", -1)) == 0x28
	var continue_index := 8 if first_wait else 14
	return _execute_e6_events_until_wait_or_end(events, continue_index)


func _resume_animation_78_to_ee_b1(events: Array) -> bool:
	var pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var first_wait := pointer == 0x9638
	var expected_selectors := PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) if first_wait \
			else PackedByteArray([0x0A, 0x0B, 0x00, 0x00])
	var max_ticks := 0x14 if first_wait else 0x02
	if _active_animation_id != 0x78 or _active_stream_id != 0x78 or events.size() != 15 \
			or pointer not in [0x9638, 0x964A] or int(_cpu.get("pc", -1)) != 0x8012 \
			or int(_ram[0x053A]) != 1 or int(_ram[0x053B]) < 1 or int(_ram[0x053B]) > max_ticks \
			or _ram.slice(0x0494, 0x0498) != expected_selectors \
			or (int(_ram[0x055C]) & 0x80) == 0 \
			or not _expect_bank14(0x8067, [0xCE, 0x3B, 0x05, 0xF0, 0x01, 0x60,
				0xA0, 0x00, 0xB1, 0x4C, 0xC9, 0xF0, 0x90, 0x06, 0x20, 0x84, 0x80,
				0x4C, 0x6D, 0x80, 0x8D, 0x3B, 0x05, 0xA9, 0x01, 0x20, 0xCF, 0x83, 0x60]):
		return _stop_error("The live `$78` resume does not match one of its two source countdown cursors.")
	_record(0x8012); _record(0x8014)
	if int(_cpu.get("a", -1)) != 1 or _flag(0x80):
		return _stop_error("The resumed `$800F` call did not take the positive `$053A` countdown branch for `$78`.")
	_record(0x8067); _write_ram(0x053B, int(_ram[0x053B]) - 1, 0x8067)
	_set_nz(int(_ram[0x053B]))
	_record(0x806A)
	if int(_ram[0x053B]) > 0:
		_record(0x806C); _rts(0x806C)
		_animation_waiting = true
		return int(_cpu.get("pc", -1)) == 0xEEB1 and int(_cpu.get("sp", -1)) == 0x28
	var continue_index := 7 if first_wait else 13
	return _execute_animation_78_events_until_wait_or_end(events, continue_index)


func _resume_animation_66_to_ee_b1(events: Array) -> bool:
	if _active_animation_id != 0x66 or events.size() != 6 \
			or int(_cpu.get("pc", -1)) != 0x8012 \
			or int(_ram[0x053A]) != 1 or int(_ram[0x053B]) < 1 or int(_ram[0x053B]) > 6 \
			or int(_ram[0x004C]) != 0x4F or int(_ram[0x004D]) != 0x94 \
			or not _expect_bank14(0x8067, [0xCE, 0x3B, 0x05, 0xF0, 0x01, 0x60,
				0xA0, 0x00, 0xB1, 0x4C, 0xC9, 0xF0, 0x90, 0x06, 0x20, 0x84, 0x80,
				0x4C, 0x6D, 0x80, 0x8D, 0x3B, 0x05, 0xA9, 0x01, 0x20, 0xCF, 0x83, 0x60]):
		return _stop_error("The live `$66` continuation does not match the ROM countdown state at `$8012`.")
	_record(0x8012); _record(0x8014)
	if int(_cpu.get("a", -1)) != 1 or _flag(0x80):
		return _stop_error("The resumed `$800F` call did not take the positive `$053A` countdown branch.")
	_record(0x8067); _write_ram(0x053B, (int(_ram[0x053B]) - 1) & 0xFF, 0x8067)
	_set_nz(int(_ram[0x053B]))
	_record(0x806A)
	if int(_ram[0x053B]) != 0:
		_record(0x806C); _rts(0x806C)
		_animation_waiting = true
		if int(_cpu.get("pc", -1)) != 0xEEB1 or int(_cpu.get("sp", -1)) != 0x28:
			return _stop_error("ROM `$806C` countdown RTS returned to `$%04X` / SP `$%02X`; expected `$EEB1` / `$28` with `$053B=$%02X`." % [
				int(_cpu.get("pc", -1)), int(_cpu.get("sp", -1)), int(_ram[0x053B])])
		return true
	if events[4].kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
			or int(events[4].source_cpu_address) != 0x944F \
			or events[5].kind != STREAM_DECODER.SourceEvent.Kind.STREAM_END:
		return _stop_error("The final `$66` countdown tick is not followed by the checked `$944F` packet and `$F0`.")
	if not _execute_f1_event(events[4]):
		if error_message.is_empty():
			return _stop_error("Resumed F1 handler stopped without a diagnostic at animation `$66` packet `$944F` (%s)." % events[4].raw_bytes.hex_encode())
		return false
	if int(_cpu["pc"]) != 0x8078:
		return _stop_error("ROM `$80AA` returned to `$%04X` after resumed animation `$66` F1 at `$944F`; expected `$8078`." % int(_cpu["pc"]))
	_record(0x8078)
	if not _execute_f0_event(events[5]):
		return false
	_animation_terminal = true
	return true


func _validate_actor_init_source_bytes() -> bool:
	return _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x8084,
			[0x38, 0xE9, 0xF0, 0x20, 0x09, 0xC5, 0xA2, 0x80, 0xAA, 0x80, 0x2B, 0x81]) \
			and _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x8142,
			[0xA0, 0x01, 0xB1, 0x4C, 0x99, 0x93, 0x04, 0xC8, 0xC0, 0x05, 0xD0, 0xF6,
			0xA9, 0x05, 0x4C, 0xCF, 0x83]) \
			and _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x8153,
			[0xA0, 0x01, 0xB1, 0x4C, 0x10, 0x06, 0x20, 0xBA, 0x81, 0x4C, 0x64, 0x81,
			0xA2, 0x10, 0x20, 0x30, 0xC5]) \
			and _expect_extension("bank14_f5_tail_8164_8171.bin", 0x8164,
			[0x20, 0x33, 0xC5, 0x00, 0x6C, 0x04, 0xA9, 0x02, 0x4C, 0xCF, 0x83]) \
			and _expect_extension("bank14_f8_redirect_816F_817C.bin", 0x816F,
			[0xA0, 0x01, 0xB1, 0x4C, 0xAA, 0xC8, 0xB1, 0x4C, 0x86, 0x4C, 0x85, 0x4D, 0x60]) \
			and _expect_extension("bank14_f6_actor_remove_83AE_83BD.bin", 0x83AE,
			[0xA0, 0x01, 0xB1, 0x4C, 0xAA, 0xA9, 0x00, 0x9D, 0x47, 0x05, 0xA9, 0x02, 0x4C, 0xCF, 0x83]) \
			and _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x80A2,
			[0x68, 0x68, 0xA9, 0x00, 0x8D, 0x3A, 0x05, 0x60]) \
			and _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x80AA,
			[0xA0, 0x05, 0xB1, 0x4C, 0x29, 0x1C, 0x4A, 0xAA, 0xBD, 0xE4, 0x88, 0x85, 0x3A, 0xBD, 0xE5, 0x88, 0x85, 0x3B]) \
			and _expect_extension("fixed_palette_vectors_C530_C536.bin", 0xC530,
			[0x4C, 0x02, 0xCC, 0x4C, 0xD2, 0xCC]) \
			and _expect_extension("fixed_palette_table_FC38_FC50.bin", 0xFC38,
			[0x0F, 0x10, 0x30, 0x0F, 0x30, 0x00, 0x31, 0x30, 0x10, 0x0F, 0x30, 0x00,
			0x0F, 0x0F, 0x36, 0x0F, 0x30, 0x36, 0x0F, 0x17, 0x36, 0x0F, 0x31, 0x30])


func _validate_decoded_events(events_variant: Variant, animation_id: int) -> bool:
	if not events_variant is Array or not ANIMATION_STREAM_SPECS.has(animation_id):
		return false
	var events: Array = events_variant
	if animation_id == 0xE6:
		return _validate_e6_decoded_events(events)
	if animation_id == 0x78:
		return _validate_78_decoded_events(events)
	if animation_id == 0x7A:
		return _validate_7A_decoded_events(events)
	var expected_packet_addresses: Array[int]
	var expected_f5 := PackedByteArray([0xF5, 0x0A])
	var expected_f4 := PackedByteArray([0xF4, 0x2C, 0x0B, 0x05, 0x07])
	if animation_id == 0x8F:
		expected_packet_addresses = [0x988C, 0x9892, 0x9898, 0x989E, 0x98A4]
	elif animation_id == 0x90:
		expected_packet_addresses = [0x98B2, 0x98B8, 0x98BE]
		expected_f5 = PackedByteArray([0xF5, 0x80])
		expected_f4 = PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B])
	elif animation_id == 0x8B:
		expected_packet_addresses = [0x982E]
		expected_f5 = PackedByteArray([0xF5, 0x80])
		expected_f4 = PackedByteArray([0xF4, 0x20, 0x21, 0x00, 0x00])
	elif animation_id == 0x5C:
		expected_packet_addresses = [0x935E, 0x9364, 0x936A]
		expected_f5 = PackedByteArray([0xF5, 0x80])
		expected_f4 = PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B])
	elif animation_id == 0x4E:
		expected_packet_addresses = [0x9268]
	elif animation_id == 0x66:
		expected_packet_addresses = [0x9448, 0x944F]
		expected_f5 = PackedByteArray([0xF5, 0x80])
		expected_f4 = PackedByteArray([0xF4, 0x04, 0x05, 0x22, 0x00])
	elif animation_id == 0x4C:
		expected_packet_addresses = [0x924C]
		expected_f5 = PackedByteArray([0xF5, 0x09])
		expected_f4 = PackedByteArray([0xF4, 0x04, 0x05, 0x00, 0x00])
	else:
		return false
	var expected_event_count := expected_packet_addresses.size() + 3
	if animation_id == 0x66:
		expected_event_count = 6
	if events.size() != expected_event_count \
			or events[0].kind != STREAM_DECODER.SourceEvent.Kind.SETUP_OPERAND \
			or events[0].raw_bytes != expected_f5 \
			or events[1].kind != STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS \
			or events[1].raw_bytes != expected_f4:
		return false
	var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[animation_id]
	if int(events[0].source_cpu_address) != int(stream_spec["start"]):
		return false
	var packet_event_indices: Array[int] = []
	if animation_id == 0x66:
		if events[3].kind != STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS \
				or int(events[3].source_cpu_address) != 0x944E \
				or events[3].raw_bytes != PackedByteArray([0x06]) \
				or int(events[3].wait_ticks) != 6:
			return false
		packet_event_indices = [2, 4]
	else:
		for index in range(expected_packet_addresses.size()):
			packet_event_indices.append(index + 2)
	for index in range(expected_packet_addresses.size()):
		var event = events[packet_event_indices[index]]
		if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
				or int(event.source_cpu_address) != expected_packet_addresses[index] \
				or event.raw_bytes.size() != 6:
			return false
	var end_event = events[events.size() - 1]
	return end_event.kind == STREAM_DECODER.SourceEvent.Kind.STREAM_END \
			and int(end_event.source_cpu_address) == int(stream_spec["end"]) - 1


func _validate_7A_decoded_events(events: Array) -> bool:
	if events.size() != 11:
		return false
	var expected_kinds: Array[int] = [
		STREAM_DECODER.SourceEvent.Kind.SETUP_OPERAND,
		STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS,
		STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET,
		STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET,
		STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS,
		STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE,
		STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET,
		STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS,
		STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET,
		STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET,
		STREAM_DECODER.SourceEvent.Kind.STREAM_END,
	]
	var expected_addresses: Array[int] = [
		0x965F, 0x9661, 0x9666, 0x966C, 0x9672, 0x9673,
		0x9675, 0x967B, 0x967C, 0x9682, 0x9688,
	]
	var expected_bytes: Array[PackedByteArray] = [
		PackedByteArray([0xF5, 0x80]),
		PackedByteArray([0xF4, 0x0C, 0x0D, 0x0E, 0x0F]),
		PackedByteArray([0xF1, 0x65, 0x1E, 0xD0, 0x93, 0x00]),
		PackedByteArray([0xF1, 0x64, 0x1D, 0x1F, 0xB7, 0x05]),
		PackedByteArray([0x14]),
		PackedByteArray([0xF6, 0x00]),
		PackedByteArray([0xF1, 0x00, 0x3F, 0x16, 0xB3, 0x05]),
		PackedByteArray([0x04]),
		PackedByteArray([0xF1, 0x66, 0x1D, 0x16, 0xB3, 0x05]),
		PackedByteArray([0xF1, 0xA7, 0x22, 0x0E, 0xAF, 0x01]),
		PackedByteArray([0xF0]),
	]
	for index in range(events.size()):
		var event = events[index]
		if event.kind != expected_kinds[index] or event.source_stream_id != 0x7A \
				or int(event.source_cpu_address) != expected_addresses[index] \
				or event.raw_bytes != expected_bytes[index]:
			return false
	if int(events[4].wait_ticks) != 0x14 or int(events[7].wait_ticks) != 0x04 \
			or int(events[5].actor_record_offset) != 0x00:
		return false
	return true


func _validate_78_decoded_events(events: Array) -> bool:
	if events.size() != 15:
		return false
	var packet_addresses: Array[int] = [0x961F, 0x9625, 0x962B, 0x9631]
	var packet_bytes: Array[PackedByteArray] = [
		PackedByteArray([0xF1, 0x62, 0x5E, 0x20, 0xBB, 0x0D]),
		PackedByteArray([0xF1, 0x62, 0x5D, 0x20, 0xBB, 0x09]),
		PackedByteArray([0xF1, 0x62, 0x5C, 0x20, 0xBB, 0x05]),
		PackedByteArray([0xF1, 0x63, 0x49, 0xA0, 0x9F, 0x00]),
	]
	if events[0].kind != STREAM_DECODER.SourceEvent.Kind.SETUP_OPERAND \
			or events[0].source_stream_id != 0x78 or int(events[0].source_cpu_address) != 0x9618 \
			or events[0].raw_bytes != PackedByteArray([0xF5, 0x80]) \
			or events[1].kind != STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS \
			or events[1].source_stream_id != 0x78 or int(events[1].source_cpu_address) != 0x961A \
			or events[1].raw_bytes != PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B]):
		return false
	for index in range(packet_addresses.size()):
		var event = events[index + 2]
		if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
				or event.source_stream_id != 0x78 \
				or int(event.source_cpu_address) != packet_addresses[index] \
				or event.raw_bytes != packet_bytes[index]:
			return false
	if events[6].kind != STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS \
			or events[6].source_stream_id != 0x78 or int(events[6].source_cpu_address) != 0x9637 \
			or events[6].raw_bytes != PackedByteArray([0x14]) or int(events[6].wait_ticks) != 0x14 \
			or events[7].kind != STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS \
			or events[7].source_stream_id != 0x78 or int(events[7].source_cpu_address) != 0x9638 \
			or events[7].raw_bytes != PackedByteArray([0xF4, 0x0A, 0x0B, 0x00, 0x00]):
		return false
	var remove_addresses: Array[int] = [0x963D, 0x963F, 0x9641]
	var remove_offsets: Array[int] = [0x00, 0x2A, 0x3F]
	for index in range(remove_addresses.size()):
		var event = events[index + 8]
		if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE \
				or event.source_stream_id != 0x78 \
				or int(event.source_cpu_address) != remove_addresses[index] \
				or int(event.actor_record_offset) != remove_offsets[index] \
				or event.raw_bytes != PackedByteArray([0xF6, remove_offsets[index]]):
			return false
	if events[11].kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
			or events[11].source_stream_id != 0x78 or int(events[11].source_cpu_address) != 0x9643 \
			or events[11].raw_bytes != PackedByteArray([0xF1, 0x00, 0x85, 0x08, 0xBB, 0x05]) \
			or events[12].kind != STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS \
			or events[12].source_stream_id != 0x78 or int(events[12].source_cpu_address) != 0x9649 \
			or events[12].raw_bytes != PackedByteArray([0x02]) or int(events[12].wait_ticks) != 0x02 \
			or events[13].kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
			or events[13].source_stream_id != 0x78 or int(events[13].source_cpu_address) != 0x964A \
			or events[13].raw_bytes != PackedByteArray([0xF1, 0x8E, 0x84, 0x0C, 0xBB, 0x05]):
		return false
	return events[14].kind == STREAM_DECODER.SourceEvent.Kind.STREAM_END \
			and events[14].source_stream_id == 0x78 \
			and int(events[14].source_cpu_address) == 0x9650


func _validate_e6_decoded_events(events: Array) -> bool:
	if events.size() != 16:
		return false
	if events[0].kind != STREAM_DECODER.SourceEvent.Kind.SETUP_OPERAND \
			or events[0].source_stream_id != 0xE6 or int(events[0].source_cpu_address) != 0xA0A3 \
			or events[0].raw_bytes != PackedByteArray([0xF5, 0x87]):
		return false
	if events[1].kind != STREAM_DECODER.SourceEvent.Kind.ABSOLUTE_REDIRECT \
			or events[1].source_stream_id != 0xE6 or int(events[1].source_cpu_address) != 0xA0A5 \
			or events[1].raw_bytes != PackedByteArray([0xF8, 0x1A, 0x96]) \
			or int(events[1].redirect_target_cpu_address) != 0x961A \
			or int(events[1].redirect_target_stream_id) != 0x78:
		return false
	if events[2].kind != STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS \
			or events[2].source_stream_id != 0x78 or int(events[2].source_cpu_address) != 0x961A \
			or events[2].raw_bytes != PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B]):
		return false
	var first_packet_addresses: Array[int] = [0x961F, 0x9625, 0x962B, 0x9631]
	var first_packet_bytes: Array[PackedByteArray] = [
		PackedByteArray([0xF1, 0x62, 0x5E, 0x20, 0xBB, 0x0D]),
		PackedByteArray([0xF1, 0x62, 0x5D, 0x20, 0xBB, 0x09]),
		PackedByteArray([0xF1, 0x62, 0x5C, 0x20, 0xBB, 0x05]),
		PackedByteArray([0xF1, 0x63, 0x49, 0xA0, 0x9F, 0x00]),
	]
	for index in range(4):
		var event = events[index + 3]
		if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
				or event.source_stream_id != 0x78 \
				or int(event.source_cpu_address) != first_packet_addresses[index] \
				or event.raw_bytes != first_packet_bytes[index]:
			return false
	if events[7].kind != STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS \
			or events[7].source_stream_id != 0x78 or int(events[7].source_cpu_address) != 0x9637 \
			or events[7].raw_bytes != PackedByteArray([0x14]) or int(events[7].wait_ticks) != 0x14:
		return false
	if events[8].kind != STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS \
			or events[8].source_stream_id != 0x78 or int(events[8].source_cpu_address) != 0x9638 \
			or events[8].raw_bytes != PackedByteArray([0xF4, 0x0A, 0x0B, 0x00, 0x00]):
		return false
	var remove_addresses: Array[int] = [0x963D, 0x963F, 0x9641]
	var remove_offsets: Array[int] = [0x00, 0x2A, 0x3F]
	for index in range(3):
		var event = events[index + 9]
		if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_REMOVE \
				or event.source_stream_id != 0x78 \
				or int(event.source_cpu_address) != remove_addresses[index] \
				or int(event.actor_record_offset) != remove_offsets[index] \
				or event.raw_bytes != PackedByteArray([0xF6, remove_offsets[index]]):
			return false
	if events[12].kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
			or events[12].source_stream_id != 0x78 or int(events[12].source_cpu_address) != 0x9643 \
			or events[12].raw_bytes != PackedByteArray([0xF1, 0x00, 0x85, 0x08, 0xBB, 0x05]):
		return false
	if events[13].kind != STREAM_DECODER.SourceEvent.Kind.WAIT_TICKS \
			or events[13].source_stream_id != 0x78 or int(events[13].source_cpu_address) != 0x9649 \
			or events[13].raw_bytes != PackedByteArray([0x02]) or int(events[13].wait_ticks) != 2:
		return false
	if events[14].kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
			or events[14].source_stream_id != 0x78 or int(events[14].source_cpu_address) != 0x964A \
			or events[14].raw_bytes != PackedByteArray([0xF1, 0x8E, 0x84, 0x0C, 0xBB, 0x05]):
		return false
	return events[15].kind == STREAM_DECODER.SourceEvent.Kind.STREAM_END \
			and events[15].source_stream_id == 0x78 \
			and int(events[15].source_cpu_address) == 0x9650


func _execute_actor_init_prelude(animation_id: int) -> bool:
	if int(_cpu.get("a", -1)) != 0x80 or not _flag(0x80):
		return _stop_error("The live `$8012` branch no longer has the negative `$80` selector.")
	_record(0x8012)
	_record(0x8014)
	_record(0x8016); _set_x(1)
	_record(0x8018); _write_ram(0x053A, 1, 0x8018)
	_record(0x801B); _set_a(int(_ram[0x053C]))
	if int(_cpu["a"]) != animation_id:
		return _stop_error("Live actor-init selector differs from animation `$%02X`." % animation_id)
	_record(0x801E); _set_x(0x68)
	_record(0x8020); _write_ram(0x004C, 0x68, 0x8020)
	_record(0x8022); _set_x(0x89)
	_record(0x8024); _write_ram(0x004D, 0x89, 0x8024)
	_record(0x8026); _asl_a()
	_record(0x8027)
	if _flag(0x01):
		_record(0x8029); _write_ram(0x004D, (int(_ram[0x004D]) + 1) & 0xFF, 0x8029)
		_set_nz(int(_ram[0x004D]))
	else:
		_cpu["pc"] = 0x802B
	_record(0x802B); _set_y(int(_cpu["a"]))
	var table_address := ((int(_ram[0x004D]) << 8) | int(_ram[0x004C])) + int(_cpu["y"])
	var expected_table_address := 0x8968 + (animation_id << 1)
	var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[animation_id]
	var stream_start := int(stream_spec["start"])
	if table_address != expected_table_address:
		return _stop_error("Animation `$%02X` pointer-table lookup missed `$%04X`." % [animation_id, expected_table_address])
	_record(0x802C); _set_a(stream_start & 0xFF)
	_record(0x802E); _set_x(int(_cpu["a"]))
	_record(0x802F); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0x8030); _set_a((stream_start >> 8) & 0xFF)
	_record(0x8032); _write_ram(0x004C, int(_cpu["x"]), 0x8032)
	_record(0x8034); _write_ram(0x004D, int(_cpu["a"]), 0x8034)
	if (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != stream_start:
		return _stop_error("Animation `$%02X` pointer table did not select its checked stream start." % animation_id)
	_record(0x8036); _set_x(0)
	_record(0x8038); _set_a(0)
	for actor_index in range(6):
		var actor_offset := int(_cpu["x"])
		_record(0x803A); _write_ram(0x0547 + actor_offset, 0, 0x803A)
		_record(0x803D); _set_a(int(_cpu["x"]))
		_record(0x803E); _set_flag(0x01, false)
		_record(0x803F)
		var next_offset := int(_cpu["a"]) + 0x15
		_set_flag(0x01, next_offset > 0xFF)
		_set_a(next_offset)
		_record(0x8041); _set_x(int(_cpu["a"]))
		_record(0x8042); _cmp(int(_cpu["x"]), 0x7E)
		_record(0x8044)
	if int(_cpu["x"]) != 0x7E:
		return _stop_error("The source actor-clear loop did not traverse six `$15`-byte records.")
	_record(0x8046); _set_a(1)
	_record(0x8048); _write_ram(0x053B, 1, 0x8048)
	_record(0x804B); _set_a(0)
	_record(0x804D); _write_ram(0x053D, 0, 0x804D)
	_record(0x8050); _write_ram(0x0540, 0, 0x8050)
	_record(0x8053); _set_a(0xFF)
	_record(0x8055); _write_ram(0x0541, 0xFF, 0x8055)
	_record(0x8058); _set_a(1)
	_record(0x805A); _write_ram(0x0543, 1, 0x805A)
	_record(0x805D); _set_a(0x23)
	_record(0x805F); _write_ram(0x0544, 0x23, 0x805F)
	_record(0x8062); _set_a(0x45)
	_record(0x8064); _write_ram(0x0545, 0x45, 0x8064)
	_record(0x8067); _write_ram(0x053B, (int(_ram[0x053B]) - 1) & 0xFF, 0x8067)
	_set_nz(int(_ram[0x053B]))
	_record(0x806A)
	return int(_ram[0x053B]) == 0


func _execute_f5_event(event) -> bool:
	var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[_active_stream_id]
	var stream_start := int(stream_spec["start"])
	var palette_operand := 0x0B if _active_animation_id == 0x00 else (0x09 if _active_animation_id == 0x4C else 0x0A)
	var holder_palette_branch: bool = _active_animation_id in [0x66, 0x78, 0x7A] \
			and event.raw_bytes == PackedByteArray([0xF5, 0x80])
	var fresh_lineup_palette_branch: bool = _active_animation_id == 0x90 \
			and event.raw_bytes == PackedByteArray([0xF5, 0x80])
	var scenario44_holder_palette_branch: bool = _active_animation_id == 0x5C \
			and event.raw_bytes == PackedByteArray([0xF5, 0x80])
	var scenario2e_holder_palette_branch: bool = _active_animation_id == 0x8B \
			and event.raw_bytes == PackedByteArray([0xF5, 0x80])
	var scenario_slot_palette_branch: bool = _active_animation_id == 0xE6 \
			and event.raw_bytes == PackedByteArray([0xF5, 0x87])
	if (event.raw_bytes != PackedByteArray([0xF5, palette_operand]) \
			and not holder_palette_branch and not fresh_lineup_palette_branch \
			and not scenario44_holder_palette_branch \
			and not scenario2e_holder_palette_branch \
			and not scenario_slot_palette_branch) \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != stream_start:
		return _stop_error("The live `$F5` command does not begin at the checked animation `$%02X` start `$%04X`." % [_active_animation_id, stream_start])
	if not _begin_stream_command(0x8153):
		return false
	_record(0x8153); _set_y(1)
	_record(0x8155); _set_a(_read_stream_at_live_pointer(1))
	_record(0x8157)
	if holder_palette_branch or fresh_lineup_palette_branch \
			or scenario44_holder_palette_branch or scenario2e_holder_palette_branch \
			or scenario_slot_palette_branch:
		var expected_operand := 0x87 if scenario_slot_palette_branch else 0x80
		if int(_cpu["a"]) != expected_operand or not _flag(0x80):
			return _stop_error("The ROM `$F5 $%02X` negative-operand branch is not selected." % expected_operand)
		_record(0x8159); _jsr(0x8159, 0x81BA)
		var palette_ok := _execute_player_slot_palette(0x05FC, 7, 0x81D5) \
				if scenario_slot_palette_branch else _execute_player_slot_palette(0x0441, 0, 0x81CF)
		if not palette_ok:
			return false
		if int(_cpu["pc"]) != 0x815C:
			return _stop_error("The ROM negative `$F5` palette routine did not return to `$815C`.")
		_record(0x815C); _cpu["pc"] = 0x8164
	else:
		if int(_cpu["a"]) != palette_operand or _flag(0x80):
			return _stop_error("The ROM `$F5` positive-operand path is not selected for `$%02X`." % palette_operand)
		_record(0x815F); _set_x(0x10)
		_record(0x8161); _jsr(0x8161, 0xC530)
		if not _execute_palette_fill_helper():
			return false
		if int(_cpu["pc"]) != 0x8164:
			return _stop_error("`$C530->$CC02` did not return to the inline-record JSR at `$8164`.")
		_record(0x8164)
	if not _execute_inline_append_helper():
		return false
	if int(_cpu["pc"]) != 0x816A:
		return _stop_error("`$C533->$CCD2` did not skip the three source inline bytes.")
	_record(0x816A); _set_a(2)
	_cpu["pc"] = 0x83CF
	if not _advance_stream_helper_for(2):
		return false
	return int(_cpu["pc"]) == 0x8078 \
			and (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) == stream_start + 2


## Applies the negative `$F5` player-slot forms: selector zero reads `$0441`,
## while selector seven reads the fresh-match slot at `$05FC`. Both resolve
## player data and palettes through the same checked ROM pointer/data tables.
func _execute_player_slot_palette(slot_address: int, selector: int,
		selector_handler: int) -> bool:
	if _player_palette_code.size() != 0xF5 \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x81BA,
			[0x29, 0x7F, 0x20, 0x09, 0xC5, 0xCF, 0x81, 0xE9, 0x81, 0xDB, 0x81, 0xE1, 0x81, 0xBC, 0x82]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x81CF,
			[0xAD, 0x41, 0x04, 0x4C, 0xEC, 0x81]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x81D5,
			[0xAD, 0xFC, 0x05, 0x4C, 0xEC, 0x81]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x81EC,
			[0x85, 0x3A, 0x20, 0x0C, 0xC5, 0x20, 0x6A, 0x82, 0xA0, 0x00, 0xB1, 0x34]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x8264,
			[0x0C, 0xB8, 0xC7, 0xB6, 0x67, 0xB7]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x826A,
			[0xA0, 0x00, 0xB1, 0x34, 0x08, 0xAA, 0xBD, 0xF0, 0x88, 0x28]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x8282,
			[0xA2, 0x01, 0x85, 0x3B, 0xC9, 0x01, 0xF0, 0x0C, 0xA2, 0x00, 0xC9, 0x0F, 0x90, 0x06, 0xC9, 0x17, 0xB0, 0x02, 0xA2, 0x02]) \
			or not _expect_extension("bank14_f5_player_palette_81BA_82AF.bin", 0x82A3,
			[0xA9, 0x01, 0xAE, 0x2A, 0x00, 0xF0, 0x02, 0xA9, 0x76, 0x60]) \
			or _player_record_pointer_bytes.size() != 44 \
			or _player_graphic_class_bytes.size() != 35 \
			or _normal_player_palette_bytes.size() != 175:
		return _stop_error("ROM `$F5 $80` selector, player-record, graphic-class, or palette bytes are not validated.")
	if selector not in [0, 7] or slot_address not in [0x0441, 0x05FC] \
			or selector_handler not in [0x81CF, 0x81D5]:
		return _stop_error("The ROM `$F5` player-palette selector does not match its supported live slot.")
	var holder_slot := int(_ram[slot_address])
	if holder_slot >= 22:
		return _stop_error("The live `$%04X` player slot is outside the 22-entry ROM player-record table." % slot_address)
	var record_pointer := int(_player_record_pointer_bytes[holder_slot * 2]) \
		| (int(_player_record_pointer_bytes[holder_slot * 2 + 1]) << 8)
	var expected_record_pointer := 0x0300 + holder_slot * 0x0C
	if record_pointer != expected_record_pointer:
		return _stop_error("The ROM `$CD89` pointer for holder `$%02X` does not resolve to its source player record." % holder_slot)
	var player_id := int(_ram[record_pointer])
	if player_id < 0x02 or player_id > 0x0E or int(_ram[0x002A]) != 0x00:
		return _stop_error("The bounded ROM `$F5` palette branch requires a live normal player ID `$02-$0E` and `$002A=$00`; got ID `$%02X`, slot `$%02X`, mode `$%02X`." % [player_id, holder_slot, int(_ram[0x002A])])
	var graphic_class := int(_player_graphic_class_bytes[player_id])
	var palette_row := _normal_player_palette_bytes.slice(player_id * 5, player_id * 5 + 5)

	_record(0x81BA); _set_a(selector)
	_record(0x81BC); _record(0xC509)
	var handler_offset := 0x05 + selector * 2
	var selected_handler := int(_player_palette_code[handler_offset]) \
			| (int(_player_palette_code[handler_offset + 1]) << 8)
	if selected_handler != selector_handler:
		return _stop_error("ROM `$81BA` selector `$%02X` selected `$%04X`, expected `$%04X`." % [selector, selected_handler, selector_handler])
	_record(selected_handler); _set_a(holder_slot)
	_record(0x81D2 if selector == 0 else 0x81D8)
	_record(0x81EC); _write_ram(0x003A, holder_slot, 0x81EC)
	_record(0x81EE); _record(0xCD7C)
	_write_ram(0x0034, record_pointer & 0xFF, 0xCD83)
	_write_ram(0x0035, (record_pointer >> 8) & 0xFF, 0xCD86)
	_record(0x81F1); _record(0x826A); _record(0x826C); _set_a(player_id)
	_record(0x8270); _set_a(graphic_class)
	_write_ram(0x0546, graphic_class, 0x827E)
	_record(0x8281); _record(0x81F4); _record(0x81F6); _set_a(player_id)
	_record(0x81F8); _record(0x81FA); _record(0x8282); _record(0x8296)
	var palette_address := 0xB80C + player_id * 5
	if palette_address < 0xB816 or palette_address + 5 > 0xB867:
		return _stop_error("The ROM ordinary-player palette index escaped its checked `$B80C-$B866` table.")
	_record(0x8213); _write_ram(0x003A, palette_address & 0xFF, 0x8213)
	_write_ram(0x003B, (palette_address >> 8) & 0xFF, 0x8228)
	for index in range(16):
		match index & 0x03:
			0:
				_record(0x8244)
			1:
				_record(0x8246); _write_ram(0x047F + index, 0x0F, 0x825A)
			2:
				var color_index := 1 + (index >> 2)
				_record(0x8253); _write_ram(0x047F + index, int(palette_row[color_index]), 0x825A)
			3:
				_record(0x824E); _write_ram(0x047F + index, int(palette_row[0]), 0x825A)
	_record(0x8262); _set_x(0x10); _set_y(1); _set_a(int(palette_row[0]))
	_rts(0x8263)
	return int(_cpu.get("pc", -1)) == 0x815C


func _execute_f4_event(event) -> bool:
	var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[_active_stream_id]
	var stream_start := int(stream_spec["start"])
	var expected_selectors := PackedByteArray([0xF4, 0x2C, 0x0B, 0x05, 0x07])
	var expected_cursor := stream_start + 2
	if _active_animation_id == 0x66:
		expected_selectors = PackedByteArray([0xF4, 0x04, 0x05, 0x22, 0x00])
	elif _active_animation_id == 0x90:
		expected_selectors = PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B])
	elif _active_animation_id == 0x5C:
		expected_selectors = PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B])
	elif _active_animation_id == 0x8B:
		expected_selectors = PackedByteArray([0xF4, 0x20, 0x21, 0x00, 0x00])
	elif _active_animation_id == 0x4C:
		expected_selectors = PackedByteArray([0xF4, 0x04, 0x05, 0x00, 0x00])
	elif _active_animation_id == 0x00:
		expected_selectors = PackedByteArray([0xF4, 0x1F, 0x00, 0x00, 0x00])
	elif _active_animation_id == 0xE6:
		if int(event.source_cpu_address) == 0x961A:
			expected_selectors = PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B])
			expected_cursor = 0x961A
		elif int(event.source_cpu_address) == 0x9638:
			expected_selectors = PackedByteArray([0xF4, 0x0A, 0x0B, 0x00, 0x00])
			expected_cursor = 0x9638
		else:
			return _stop_error("The live `$E6` route selected an unverified `$F4` source address.")
	elif _active_animation_id == 0x78:
		if int(event.source_cpu_address) == 0x961A:
			expected_selectors = PackedByteArray([0xF4, 0x08, 0x09, 0x0A, 0x0B])
			expected_cursor = 0x961A
		elif int(event.source_cpu_address) == 0x9638:
			expected_selectors = PackedByteArray([0xF4, 0x0A, 0x0B, 0x00, 0x00])
			expected_cursor = 0x9638
		else:
			return _stop_error("The live `$78` route selected an unverified `$F4` source address.")
	elif _active_animation_id == 0x7A:
		expected_selectors = PackedByteArray([0xF4, 0x0C, 0x0D, 0x0E, 0x0F])
	if event.raw_bytes != expected_selectors \
			or event.source_stream_id != _active_stream_id \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != expected_cursor:
		return _stop_error("The live `$F4` selector command does not begin at the checked animation cursor.")
	if not _begin_stream_command(0x8142):
		return false
	_record(0x8142); _set_y(1)
	while int(_cpu["y"]) < 5:
		var y_value := int(_cpu["y"])
		_record(0x8144); _set_a(_read_stream_at_live_pointer(y_value))
		_record(0x8146); _write_ram(0x0493 + y_value, int(_cpu["a"]), 0x8146)
		_record(0x8149); _set_y((y_value + 1) & 0xFF)
		_record(0x814A); _cmp(int(_cpu["y"]), 0x05)
		_record(0x814C)
	_record(0x814E); _set_a(5)
	_cpu["pc"] = 0x83CF
	if not _advance_stream_helper_for(5):
		return false
	return int(_cpu["pc"]) == 0x8078 \
			and (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) == expected_cursor + 5


func _execute_f1_event(event) -> bool:
	var stream_pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
			or int(event.source_cpu_address) != stream_pointer \
			or _read_stream_at_live_pointer(0) != 0xF1:
		return _stop_error("The live stream cursor does not match the next decoded `$F1` packet.")
	if not _begin_stream_command(0x80AA):
		return false
	var actor = _f1_constructor.construct(event)
	if actor == null:
		return _stop_error("The checked `$F1` constructor rejected the decoded source packet: " + _f1_constructor.last_error)
	if not _apply_f1_actor_record(event, actor):
		return false
	_active_actor_packet_count += 1
	_record(0x8125); _set_a(6)
	_record(0x8127); _jsr(0x8127, 0x83CF)
	if not _advance_stream_helper_for(6):
		return false
	if int(_cpu["pc"]) != 0x812A:
		return _stop_error("The `$F1` source helper returned to an unexpected caller PC.")
	_record(0x812A); _rts(0x812A)
	return int(_cpu["pc"]) == 0x8078


func _begin_stream_command(handler: int) -> bool:
	_record(0x806D); _set_y(0)
	_record(0x806F); _set_a(_read_stream_at_live_pointer(0))
	_record(0x8071); _cmp(int(_cpu["a"]), 0xF0)
	_record(0x8073)
	if not _flag(0x01) or int(_cpu["a"]) < 0xF0:
		return _stop_error("This bounded first call only supports the audited `$F0-$FF` command path.")
	_jsr(0x8075, 0x8084)
	return _dispatch_animation_opcode_for(handler)


func _execute_f0_event(event) -> bool:
	var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[_active_stream_id]
	var stream_end_command := int(stream_spec["end"]) - 1
	if event.kind != STREAM_DECODER.SourceEvent.Kind.STREAM_END \
			or event.source_stream_id != _active_stream_id \
			or int(event.source_cpu_address) != stream_end_command \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != stream_end_command:
		return _stop_error("The source `$F0` byte does not match the live animation stream end cursor.")
	if not _begin_stream_command(0x80A2):
		return false
	_record(0x80A2); _set_a(_pop(0x80A2))
	_record(0x80A3); _set_a(_pop(0x80A3))
	_record(0x80A4); _set_a(0)
	_record(0x80A6); _write_ram(0x053A, 0, 0x80A6)
	_record(0x80A9); _rts(0x80A9)
	_animation_terminal = true
	if not ((int(_cpu["pc"]) == 0xCA55 and int(_cpu["sp"]) == 0x2A) \
			or (int(_cpu["pc"]) == 0xEEB1 and int(_cpu["sp"]) == 0x28)):
		return _stop_error("ROM `$F0` returned to `$%04X` / SP `$%02X`; expected one of the verified `$EEB1/$28` or `$CA55/$2A` stack boundaries." % [
			int(_cpu["pc"]), int(_cpu["sp"])])
	return true


func _execute_palette_fill_helper() -> bool:
	var palette_operand := int(_cpu.get("a", -1))
	if _palette_helper.size() != 0x44 or _sha256(_palette_helper) != PALETTE_HELPER_SHA256 \
			or palette_operand not in [0x09, 0x0A, 0x0B] or int(_cpu["x"]) != 0x10:
		return _stop_error("The reused `$CC02` helper or its supported `$F5 $09/$0A/$0B` entry state is invalid.")
	if not _expect_extension("fixed_palette_vectors_C530_C536.bin", 0xC530, [0x4C, 0x02, 0xCC]):
		return false
	_record(0xC530); _cpu["pc"] = 0xCC02
	_record(0xCC02); _set_y(0)
	_record(0xCC04); _write_ram(0x0066, int(_cpu["y"]), 0xCC04)
	_record(0xCC06); _asl_a()
	_record(0xCC07); _rol_ram(0x0066)
	_record(0xCC09); _asl_a()
	_record(0xCC0A); _set_y(int(_cpu["a"]))
	_record(0xCC0B); _rol_ram(0x0066)
	_record(0xCC0D); _asl_a()
	_record(0xCC0E); _rol_ram(0x0066)
	_record(0xCC10); _write_ram(0x0065, int(_cpu["a"]), 0xCC10)
	_record(0xCC12); _set_a(int(_cpu["y"]))
	_record(0xCC13); _adc(int(_ram[0x0065]))
	_record(0xCC15)
	if not _flag(0x01):
		_cpu["pc"] = 0xCC19
	else:
		_record(0xCC17); _write_ram(0x0066, (int(_ram[0x0066]) + 1) & 0xFF, 0xCC17)
		_set_nz(int(_ram[0x0066]))
	_record(0xCC19); _set_flag(0x01, false)
	_record(0xCC1A); _adc(0xCC)
	_record(0xCC1C); _write_ram(0x0065, int(_cpu["a"]), 0xCC1C)
	_record(0xCC1E); _set_a(int(_ram[0x0066]))
	_record(0xCC20); _adc(0xFB)
	_record(0xCC22); _write_ram(0x0066, int(_cpu["a"]), 0xCC22)
	var palette_table_start := 0xFC38 if palette_operand == 0x09 else (0xFC44 if palette_operand == 0x0A else 0xFC50)
	if (int(_ram[0x0065]) | (int(_ram[0x0066]) << 8)) != palette_table_start:
		return _stop_error("`$CC02` computed palette row `$%04X`, expected `$%04X` for `$F5 $%02X`." % [
			int(_ram[0x0065]) | (int(_ram[0x0066]) << 8), palette_table_start, palette_operand])
	_record(0xCC24); _set_a(0x10)
	_record(0xCC26); _write_ram(0x046C, 0x10, 0xCC26)
	_record(0xCC27); _set_y(0)
	var table_index := 0
	for palette_index in range(16):
		var x_value := 0x10 + palette_index
		_record(0xCC29); _set_a(x_value)
		_record(0xCC2A); _set_a(int(_cpu["a"]) & 0x03)
		_record(0xCC2C)
		if int(_cpu["a"]) == 0:
			_record(0xCC33); _set_a(0x0F)
		else:
			_record(0xCC2E)
			var palette_filename := "fixed_palette_table_FC38_FC50.bin" if palette_operand != 0x0B else "fixed_palette_row_FC50_FC5C.bin"
			_set_a(int(_extra_byte(palette_filename, palette_table_start + table_index)))
			table_index += 1
			_record(0xCC30); _set_y((int(_cpu["y"]) + 1) & 0xFF)
			_record(0xCC31)
		_record(0xCC35); _write_ram(0x046F + x_value, int(_cpu["a"]), 0xCC35)
		_record(0xCC38); _set_x(x_value + 1)
		_record(0xCC39); _write_ram(0x046C, 15 - palette_index, 0xCC39)
		_set_nz(int(_ram[0x046C]))
		_record(0xCC3C)
	if table_index != 12:
		return _stop_error("`$CC02` did not consume exactly twelve bytes from palette row `$%04X`." % palette_table_start)
	_record(0xCC3E); _set_a(0x20)
	_record(0xCC40); _write_ram(0x046C, 0x20, 0xCC40)
	_record(0xCC43); _rts(0xCC43)
	return int(_cpu["pc"]) == 0x8164


func _rol_ram(address: int) -> void:
	var old_value := int(_ram[address])
	var old_carry := 1 if _flag(0x01) else 0
	_set_flag(0x01, (old_value & 0x80) != 0)
	var result := ((old_value << 1) | old_carry) & 0xFF
	_write_ram(address, result, int(_cpu["pc"]))
	_set_nz(result)


func _adc(value: int) -> void:
	var accumulator := int(_cpu["a"])
	var carry_in := 1 if _flag(0x01) else 0
	var result_full := accumulator + value + carry_in
	var result := result_full & 0xFF
	_set_flag(0x01, result_full > 0xFF)
	_set_flag(0x40, ((~(accumulator ^ value) & (accumulator ^ result)) & 0x80) != 0)
	_set_a(result)


func _execute_inline_append_helper() -> bool:
	if _inline_append_helper.size() != 0x3B \
			or _sha256(_inline_append_helper) != INLINE_APPEND_HELPER_SHA256 \
			or int(_ram[0x0498]) != _initial_append_cursor \
			or _initial_append_cursor < 0 or _initial_append_cursor > 0x54:
		return _stop_error("The reused `$CCD2` append helper or live `$0498` cursor is unsupported.")
	if not _expect_extension("fixed_palette_vectors_C530_C536.bin", 0xC533, [0x4C, 0xD2, 0xCC]):
		return false
	_jsr(0x8164, 0xC533)
	_record(0xC533); _cpu["pc"] = 0xCCD2
	_record(0xCCD2); _set_x(int(_cpu["sp"]))
	var stack_index := int(_cpu["x"])
	_record(0xCCD3); _set_a(int(_ram[0x0100 + ((stack_index + 1) & 0xFF)]))
	_record(0xCCD6); _write_ram(0x0075, int(_cpu["a"]), 0xCCD6)
	_record(0xCCD8); _push(int(_cpu["a"]), 0xCCD8)
	_record(0xCCD9); _set_a(int(_ram[0x0100 + ((stack_index + 2) & 0xFF)]))
	_record(0xCCDC); _write_ram(0x0076, int(_cpu["a"]), 0xCCDC)
	_record(0xCCDE); _set_a(_pop(0xCCDE))
	_record(0xCCDF); _set_flag(0x01, false)
	_record(0xCCE0); _adc(3)
	_record(0xCCE2); _write_ram(0x0100 + ((stack_index + 1) & 0xFF), int(_cpu["a"]), 0xCCE2)
	_record(0xCCE5)
	if _flag(0x01):
		var high_address := 0x0100 + ((stack_index + 2) & 0xFF)
		_record(0xCCE7); _write_ram(high_address, (int(_ram[high_address]) + 1) & 0xFF, 0xCCE7)
		_set_nz(int(_ram[high_address]))
	_record(0xCCEA); _set_a(int(_cpu["y"]))
	_record(0xCCEB); _push(int(_cpu["a"]), 0xCCEB)
	_record(0xCCEC); _set_a(int(_ram[0x0498]))
	_record(0xCCEF); _asl_a()
	_record(0xCCF0); _adc(int(_ram[0x0498]))
	_record(0xCCF3); _set_x(int(_cpu["a"]))
	_record(0xCCF4); _set_y(1)
	var inline_start := int(_ram[0x0075]) | (int(_ram[0x0076]) << 8)
	if inline_start != 0x8166:
		return _stop_error("The append helper stack pointer does not identify the source `$8166` JSR return.")
	_record(0xCCF6); _set_a(_extra_byte("bank14_f5_tail_8164_8171.bin", inline_start + int(_cpu["y"])))
	_record(0xCCF8); _write_ram(0x0499 + int(_cpu["x"]), int(_cpu["a"]), 0xCCF8)
	_record(0xCCFB); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0xCCFC); _set_a(_extra_byte("bank14_f5_tail_8164_8171.bin", inline_start + int(_cpu["y"])))
	_record(0xCCFE); _write_ram(0x049A + int(_cpu["x"]), int(_cpu["a"]), 0xCCFE)
	_record(0xCD01); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0xCD02); _set_a(_extra_byte("bank14_f5_tail_8164_8171.bin", inline_start + int(_cpu["y"])))
	_record(0xCD04); _write_ram(0x049B + int(_cpu["x"]), int(_cpu["a"]), 0xCD04)
	_record(0xCD07); _write_ram(0x0498, (int(_ram[0x0498]) + 1) & 0xFF, 0xCD07)
	_set_nz(int(_ram[0x0498]))
	_record(0xCD0A); _set_a(_pop(0xCD0A))
	_record(0xCD0B); _set_y(int(_cpu["a"]))
	_record(0xCD0C); _rts(0xCD0C)
	return int(_cpu["pc"]) == 0x816A


func _apply_f1_actor_record(event, actor) -> bool:
	var actor_index := int(actor.actor_index)
	var record_address := int(actor.record_cpu_address)
	if record_address != 0x0547 + actor_index * 0x15 or actor.bytes.size() != 0x15:
		return _stop_error("The constructor returned an invalid ROM actor-record address or length.")
	_record(0x80AA); _record(0x80AC); _record(0x80AE); _record(0x80B0); _record(0x80B1)
	_record(0x80B2); _write_ram(0x003A, record_address & 0xFF, 0x80B5)
	_record(0x80B5); _record(0x80B7)
	_write_ram(0x003B, (record_address >> 8) & 0xFF, 0x80BA)
	_record(0x80BA); _record(0x80BC)
	for offset in range(0x15):
		_record(0x80BE)
		_write_ram(record_address + offset, 0, 0x80C1)
		_record(0x80C3); _record(0x80C4); _record(0x80C6)
	_record(0x80C8); _record(0x80CA); _record(0x80CC)
	_record(0x80CE); _write_ram(0x003E, 0xB4, 0x80CE)
	_record(0x80D0); _record(0x80D2); _record(0x80D3)
	_record(0x80D4); _write_ram(0x003F, 0xA1, 0x80D4)
	_record(0x80D6); _record(0x80D7); _record(0x80D9); _record(0x80DA); _record(0x80DB); _record(0x80DD)
	_write_ram(record_address + 2, int(actor.bytes[2]), 0x80DF)
	_record(0x80DF); _record(0x80E1); _record(0x80E2)
	_write_ram(record_address + 1, int(actor.bytes[1]), 0x80E3)
	_record(0x80E3); _record(0x80E5); _record(0x80E7); _record(0x80E9)
	_record(0x80EB); _write_ram(0x003E, 0x47, 0x80EB)
	_record(0x80ED); _record(0x80EF); _record(0x80F0)
	_record(0x80F2); _write_ram(0x003F, 0xAC, 0x80F2)
	_record(0x80F4); _record(0x80F6); _record(0x80F8); _record(0x80F9); _record(0x80FA); _record(0x80FC)
	_write_ram(record_address + 4, int(actor.bytes[4]), 0x80FE)
	_record(0x80FE); _record(0x8100); _record(0x8101)
	_write_ram(record_address + 3, int(actor.bytes[3]), 0x8102)
	_record(0x8102); _record(0x8104); _record(0x8106); _record(0x8108)
	_write_ram(record_address + 8, int(actor.bytes[8]), 0x810A)
	_record(0x810A); _record(0x810C); _record(0x810E); _record(0x8110)
	_write_ram(record_address + 0x0C, int(actor.bytes[0x0C]), 0x8112)
	_record(0x8112); _record(0x8114); _record(0x8116); _set_a(int(event.raw_bytes[5]))
	_record(0x8118); _set_x(int(_cpu["a"]))
	_record(0x8119); _set_a(int(_cpu["a"]) & 0x03)
	_write_ram(0x003C, int(_cpu["a"]), 0x811B)
	_record(0x811B); _set_a(int(_cpu["a"]) | int(_ram[0x003C]))
	_record(0x811D); _set_a(int(_cpu["a"]) | 0x80)
	_record(0x811F); _set_y(0)
	_write_ram(record_address, int(_cpu["a"]), 0x8123)
	_record(0x8123)
	if _ram.slice(record_address, record_address + 0x15) != actor.bytes:
		return _stop_error("Ordered ROM `$80AA` record writes differ from the checked F1 constructor output.")
	return true


func _dispatch_animation_opcode_for(expected_handler: int) -> bool:
	if not _expect_extension("fixed_dispatch_C509_C50C.bin", 0xC509, [0x4C, 0x99, 0xCB]) \
			or not _expect_extension("fixed_dispatch_CB99_CBB0.bin", 0xCB99,
			[0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36, 0x48,
			0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00]):
		return false
	_record(0x8084); _set_flag(0x01, true)
	_record(0x8085); _sbc(0xF0)
	var command_index := int(_cpu["a"])
	if command_index < 0 or command_index > 0x0F:
		return _stop_error("Animation command index fell outside the ROM `$F0-$FF` dispatcher table.")
	_record(0x8087); _jsr(0x8087, 0xC509)
	_record(0xC509); _cpu["pc"] = 0xCB99
	_record(0xCB99); _asl_a()
	_record(0xCB9A); _set_y(int(_cpu["a"]))
	_record(0xCB9B); _set_a(_pop(0xCB9B))
	_record(0xCB9C); _write_ram(0x0036, int(_cpu["a"]), 0xCB9C)
	_record(0xCB9E); _set_a(_pop(0xCB9E))
	_record(0xCB9F); _write_ram(0x0037, int(_cpu["a"]), 0xCB9F)
	_record(0xCBA1); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	var table_base := int(_ram[0x0036]) | (int(_ram[0x0037]) << 8)
	_record(0xCBA2); _set_a(_extra_byte("bank14_animation_dispatch_8084_8164.bin", table_base + int(_cpu["y"])))
	_record(0xCBA4); _push(int(_cpu["a"]), 0xCBA4)
	_record(0xCBA5); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0xCBA6); _set_a(_extra_byte("bank14_animation_dispatch_8084_8164.bin", table_base + int(_cpu["y"])))
	_record(0xCBA8); _write_ram(0x0037, int(_cpu["a"]), 0xCBA8)
	_record(0xCBAA); _set_a(_pop(0xCBAA))
	_record(0xCBAB); _write_ram(0x0036, int(_cpu["a"]), 0xCBAB)
	var handler := int(_ram[0x0036]) | (int(_ram[0x0037]) << 8)
	_record(0xCBAD); _cpu["pc"] = handler
	if handler != expected_handler:
		return _stop_error("ROM opcode dispatch selected `$%04X`; expected `$%04X`." % [handler, expected_handler])
	return true


func _advance_stream_helper_for(increment: int) -> bool:
	if int(_cpu.get("a", -1)) != increment \
			or not _expect_extension("bank14_stream_advance_83CF_83D9.bin", 0x83CF,
			[0x18, 0x65, 0x4C, 0x85, 0x4C, 0x90, 0x02, 0xE6, 0x4D, 0x60]):
		return _stop_error("The ROM `$83CF` helper received an unexpected stream increment.")
	_record(0x83CF); _set_flag(0x01, false)
	_record(0x83D0)
	var sum := int(_cpu["a"]) + int(_ram[0x004C])
	_set_flag(0x01, sum > 0xFF)
	_set_a(sum)
	_record(0x83D2); _write_ram(0x004C, int(_cpu["a"]), 0x83D2)
	_record(0x83D4)
	if _flag(0x01):
		_record(0x83D6); _write_ram(0x004D, (int(_ram[0x004D]) + 1) & 0xFF, 0x83D6)
		_set_nz(int(_ram[0x004D]))
	else:
		_cpu["pc"] = 0x83D8
	_record(0x83D8); _rts(0x83D8)
	return true


func _finish_actor_init_return(dispatch: Dictionary, request: Dictionary) -> Dictionary:
	var pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var stream_spec: Dictionary = ANIMATION_STREAM_SPECS[_active_stream_id]
	var expected_return_pc := 0xEEB1
	var expected_return_sp := 0x28
	var stream_end_command := int(stream_spec["end"]) - 1
	var append_base := 0x0499 + _initial_append_cursor * 3
	var expected_selectors := PackedByteArray([0x2C, 0x0B, 0x05, 0x07])
	var expected_packet_count := 5
	var expected_f5_operand := 0x0A
	var expected_stream_pointer := stream_end_command
	var expected_053a := 0
	var expected_053b := 0
	var expected_append_cursor := _initial_append_cursor + 1
	var expected_call_packets := expected_packet_count
	var active_init_status := "returned_to_ee9f_actor_loop"
	var bounded_stop := "`$F0` returns from bank `$14` to `$EEB1`; `$EEB1` is not executed"
	if _active_animation_id == 0x00:
		expected_selectors = PackedByteArray([0x1F, 0x00, 0x00, 0x00])
		expected_packet_count = 0
		expected_call_packets = 0
		expected_f5_operand = 0x0B
		bounded_stop = "Scenario-$38 animation `$00` applies `$F5 $0B`, `$F4`, six `$F6` removals, and `$F0` to `$EEB1`"
	if _animation_terminal:
		if int(_cpu.get("pc", -1)) == 0xCA55 and int(_cpu.get("sp", -1)) == 0x2A:
			expected_return_pc = 0xCA55
			expected_return_sp = 0x2A
			active_init_status = "returned_to_source_caller"
			bounded_stop = "ROM `$F0` discards the stream-dispatch and bank-call return words, then returns to `$CA55`"
		elif int(_cpu.get("pc", -1)) != 0xEEB1 or int(_cpu.get("sp", -1)) != 0x28:
			return _stopped("source_state_uncertainty", int(_cpu.get("pc", 0)),
				"ROM `$F0` returned outside the verified `$EEB1/$28` and `$CA55/$2A` stack boundaries.")
	if _active_animation_id == 0x4E:
		expected_packet_count = 1
		expected_call_packets = 1
	if _active_animation_id == 0x4C:
		expected_selectors = PackedByteArray([0x04, 0x05, 0x00, 0x00])
		expected_packet_count = 1
		expected_f5_operand = 0x09
		expected_call_packets = 1
	if _active_animation_id == 0x8B:
		expected_selectors = PackedByteArray([0x20, 0x21, 0x00, 0x00])
		expected_packet_count = 1
		expected_f5_operand = 0x80
		expected_call_packets = 1
	if _active_animation_id == 0x66:
		expected_selectors = PackedByteArray([0x04, 0x05, 0x22, 0x00])
		expected_packet_count = 2
		expected_f5_operand = 0x80
		if _animation_call_is_resume and _animation_waiting:
			expected_stream_pointer = 0x944F
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			expected_append_cursor = _initial_append_cursor
			expected_call_packets = 0
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "`$806C RTS` returns from bank `$14` to `$EEB1` with the source countdown pending"
		elif _animation_call_is_resume and _animation_terminal:
			expected_stream_pointer = stream_end_command
			expected_append_cursor = _initial_append_cursor
			expected_call_packets = 1
		else:
			expected_stream_pointer = 0x944F
			expected_053a = 1
			expected_053b = 6
			expected_append_cursor = _initial_append_cursor + 1
			expected_call_packets = 1
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "ROM `$06` loads `$053B=6`, advances to `$944F`, and returns to `$EEB1`"
	if _active_animation_id in [0x90, 0x5C]:
		expected_selectors = PackedByteArray([0x08, 0x09, 0x0A, 0x0B])
		expected_packet_count = 3
		expected_call_packets = 3
		expected_f5_operand = 0x80
	if _active_animation_id == 0xE6:
		expected_f5_operand = 0x87
		expected_call_packets = 0
		expected_append_cursor = _initial_append_cursor if _animation_call_is_resume else _initial_append_cursor + 1
		if pointer == 0x9638:
			expected_selectors = PackedByteArray([0x08, 0x09, 0x0A, 0x0B])
			expected_stream_pointer = 0x9638
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			expected_call_packets = 4 if not _animation_call_is_resume else 0
			if expected_053b < 1 or expected_053b > 0x14:
				return _stopped("source_state_uncertainty", pointer,
					"The first `$E6->$78` source wait returned with an invalid `$14` countdown.")
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "ROM `$14` loads `$053B=$14`, advances to `$9638`, and returns to `$EEB1`"
		elif pointer == 0x964A:
			expected_selectors = PackedByteArray([0x0A, 0x0B, 0x00, 0x00])
			expected_stream_pointer = 0x964A
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			expected_call_packets = 1 if expected_053b == 2 else 0
			if expected_053b < 1 or expected_053b > 2:
				return _stopped("source_state_uncertainty", pointer,
					"The second `$E6->$78` source wait returned with an invalid `$02` countdown.")
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "ROM `$02` loads `$053B=2`, advances to `$964A`, and returns to `$EEB1`"
		elif pointer == 0x9650 and _animation_terminal:
			expected_selectors = PackedByteArray([0x0A, 0x0B, 0x00, 0x00])
			expected_stream_pointer = 0x9650
			expected_053a = 0
			expected_053b = 0
			expected_call_packets = 1
			active_init_status = "returned_to_source_caller" if int(_cpu.get("pc", -1)) == 0xCA55 else "returned_to_ee9f_actor_loop"
			bounded_stop = "The final `$E6->$78` F1 packet and ROM `$F0` return through the live caller"
		else:
			return _stopped("source_state_uncertainty", pointer,
				"The `$E6->$78` worker stopped outside its two verified waits or terminal `$F0`.")
	if _active_animation_id == 0x78:
		expected_selectors = PackedByteArray([0x08, 0x09, 0x0A, 0x0B]) if pointer == 0x9638 \
				else PackedByteArray([0x0A, 0x0B, 0x00, 0x00])
		expected_packet_count = 6
		expected_f5_operand = 0x80
		expected_append_cursor = _initial_append_cursor if _animation_call_is_resume else _initial_append_cursor + 1
		if pointer == 0x9638:
			expected_stream_pointer = 0x9638
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			expected_call_packets = 4 if not _animation_call_is_resume else 0
			if expected_053b < 1 or expected_053b > 0x14:
				return _stopped("source_state_uncertainty", pointer,
					"The direct `$78` first wait did not retain its ROM `$14` countdown.")
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "Direct scenario-$1C animation `$78` created four source actors and reached its `$14` wait"
		elif pointer == 0x964A:
			expected_stream_pointer = 0x964A
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			expected_call_packets = _active_actor_packet_count
			if not _animation_call_is_resume or expected_053b < 1 or expected_053b > 2 \
					or expected_call_packets not in [0, 1]:
				return _stopped("source_state_uncertainty", pointer,
					"The direct `$78` second wait did not follow its source `$9643` packet or countdown resume.")
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "Direct animation `$78` reached its `$02` wait after the ROM removal/actor packet sequence"
		elif pointer == 0x9650 and _animation_terminal:
			expected_stream_pointer = 0x9650
			expected_053a = 0
			expected_053b = 0
			expected_call_packets = 1
			active_init_status = "returned_to_source_caller" if int(_cpu.get("pc", -1)) == 0xCA55 else "returned_to_ee9f_actor_loop"
			bounded_stop = "Direct scenario-$1C animation `$78` completed its final ROM actor packet and `$F0`"
		else:
			return _stopped("source_state_uncertainty", pointer,
				"The direct `$78` worker stopped outside its two source waits or terminal `$F0`.")
	if _active_animation_id == 0x7A:
		expected_selectors = PackedByteArray([0x0C, 0x0D, 0x0E, 0x0F])
		expected_packet_count = 5
		expected_f5_operand = 0x80
		expected_call_packets = _active_actor_packet_count
		expected_append_cursor = _initial_append_cursor if _animation_call_is_resume else _initial_append_cursor + 1
		if pointer == 0x9673 and _animation_waiting:
			expected_stream_pointer = 0x9673
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			if expected_053b < 1 or expected_053b > 0x14 \
					or _active_actor_packet_count != (0 if _animation_call_is_resume else 2):
				return _stopped("source_state_uncertainty", pointer,
					"The `$7A` `$14` wait did not follow its two initial source packets or a countdown-only resume.")
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "Animation `$7A` created its two source actors and reached the `$14` wait"
		elif pointer == 0x967C and _animation_waiting:
			expected_stream_pointer = 0x967C
			expected_053a = 1
			expected_053b = int(_ram[0x053B])
			if expected_053b < 1 or expected_053b > 0x04 \
					or _active_actor_packet_count not in [0, 1] \
					or (_active_actor_packet_count == 1 and not _animation_call_is_resume):
				return _stopped("source_state_uncertainty", pointer,
					"The `$7A` `$04` wait did not follow the source removal/packet or a countdown-only resume.")
			active_init_status = "waiting_for_source_animation_ticks"
			bounded_stop = "Animation `$7A` removed its first actor, created the next actor, and reached the `$04` wait"
		elif pointer == 0x9688 and _animation_terminal:
			expected_stream_pointer = 0x9688
			expected_053a = 0
			expected_053b = 0
			expected_call_packets = 2
			active_init_status = "returned_to_source_caller" if int(_cpu.get("pc", -1)) == 0xCA55 else "returned_to_ee9f_actor_loop"
			bounded_stop = "Animation `$7A` completed its final two source actor packets and `$F0`"
		else:
			return _stopped("source_state_uncertainty", pointer,
				"The `$7A` worker stopped outside its two source waits or terminal `$F0`.")
	if not _animation_waiting and not _animation_terminal:
		return _stopped("source_state_uncertainty", int(_cpu.get("pc", 0)),
			"Animation `$%02X` returned without a verified wait or terminal command." % _active_animation_id)
	var cursor_unchanged_for_resume := _active_animation_id in [0x66, 0xE6, 0x78, 0x7A] and _animation_call_is_resume
	var append_cursor_valid := int(_ram[0x0498]) == expected_append_cursor
	var appended_record_valid := cursor_unchanged_for_resume or _ram.slice(append_base, append_base + 3) == PackedByteArray([0x00, 0x6C, 0x04])
	if int(_cpu.get("pc", -1)) != expected_return_pc \
			or int(_cpu.get("sp", -1)) != expected_return_sp \
			or pointer != expected_stream_pointer or int(_ram[0x053A]) != expected_053a \
			or int(_ram[0x053B]) != expected_053b or int(_ram[0x053C]) != _active_animation_id \
			or int(_ram[0x053D]) != 0 or not append_cursor_valid \
			or _ram.slice(0x0494, 0x0498) != expected_selectors \
			or not appended_record_valid or _active_actor_packet_count != expected_call_packets:
		return _stopped("source_state_uncertainty", int(_cpu.get("pc", 0)),
			"Animation call state mismatch: PC=$%04X SP=$%02X stream=$%04X 053A-D=%s 0494-9B=%s 0498=%02X packets=%d waiting=%s terminal=%s." % [
			int(_cpu.get("pc", 0)), int(_cpu.get("sp", 0)), pointer,
			_ram.slice(0x053A, 0x053E).hex_encode(), _ram.slice(0x0494, 0x049C).hex_encode(), int(_ram[0x0498]),
			_active_actor_packet_count, str(_animation_waiting), str(_animation_terminal)])
	var actor_records: Array[Dictionary] = []
	for actor_index in range(6):
		var address := 0x0547 + actor_index * 0x15
		if (int(_ram[address]) & 0x80) == 0:
			continue
		actor_records.append({"actor_index": actor_index, "cpu_address": address,
			"bytes": _ram.slice(address, address + 0x15), "active_flags": int(_ram[address]),
			"motion_pointer": int(_ram[address + 1]) | (int(_ram[address + 2]) << 8),
			"appearance_pointer": int(_ram[address + 3]) | (int(_ram[address + 4]) << 8)})
	var returned_to_caller := expected_return_pc == 0xCA55
	var result := {
		"ok": true,
		"status": "returned_to_source_caller" if returned_to_caller else "returned_to_ee9f_actor_loop",
		"stop_pc": expected_return_pc,
		"rom_sha256": ROM_SHA256, "source_manifest": EXTENSION_MANIFEST,
		"entry": {"slot_base": 0x01, "call_pc": 0xCA52, "target_pc": 0xEE9F,
			"expected_return_pc": 0xCA55, "source": "live slot-$01 scheduler dispatch and RAM/stack snapshot"},
		"registers": _register_snapshot(),
		"mapper": {"register_select": int(_mapper["select"]),
			"bank_registers": (_mapper.get("bank_registers", {}) as Dictionary).duplicate(true),
			"task_bank_low": int(_cpu["bank_low"]), "task_bank_high": int(_cpu["bank_high"])},
		"ram_image": _ram.duplicate(), "stack_page": _stack.duplicate(),
		"memory_writes": _writes.duplicate(true), "actor_records": actor_records,
		"instruction_pcs": _instruction_pcs.duplicate(), "instruction_count": _instruction_pcs.size(),
		"returned_to_caller": returned_to_caller,
		"returned_to_ee9f_actor_loop": not returned_to_caller,
		"call_contract": {"dispatch": dispatch.duplicate(true), "caller_request": request.duplicate(true)},
		"ppu_bus_events": [], "ppu_cycle_timing_modeled": false, "audio_effects_modeled": false,
		"active_actor_init": {"status": active_init_status, "active_animation_id": _active_animation_id,
			"active_stream_id": _active_stream_id, "stream_start": int(stream_spec["start"]), "stream_pointer_after_f0": pointer,
			"stream_pointer_after_current_call": pointer,
			"f5_operands": PackedByteArray([expected_f5_operand]), "f4_operands": expected_selectors,
			"inline_append_cursor_before": _initial_append_cursor,
			"inline_append_cursor_after": int(_ram[0x0498]),
			"actor_packets_executed": _active_actor_packet_count,
			"actor_records": actor_records,
			"bounded_stop": bounded_stop}
	}
	return result


func _execute_active_actor_loop_to_caller(dispatch: Dictionary, request: Dictionary,
		seed_result: Dictionary) -> Dictionary:
	if int(_cpu.get("pc", -1)) != 0xEEB1 or int(_cpu.get("sp", -1)) != 0x28 \
			or String(seed_result.get("status", "")) != "returned_to_ee9f_actor_loop":
		return _stopped("actor_loop_entry_mismatch", int(_cpu.get("pc", 0)),
			"The live animation `$%02X` seed prefix did not stop at `$EEB1` with its caller frame intact." % _active_animation_id)
	var interpreter = ACTOR_INTERPRETER.new()
	if not interpreter.configure():
		return _stopped("actor_interpreter_unavailable", 0xEEB1, interpreter.last_error)
	var oam_builder = ACTOR_OAM_BUILDER.new()
	var source_loop_bytes := [
		{ "pc": 0xEEB1, "bytes": [0xA9, 0x00, 0x85, 0x3A, 0x85, 0x48, 0xAE, 0x3D, 0x05, 0xF0, 0x1E] },
		{ "pc": 0xEEDA, "bytes": [0x85, 0x3B] },
		{ "pc": 0xEEDC, "bytes": [0xA5, 0x3A, 0x4A, 0xAA, 0xBD, 0x43, 0x05, 0xB0, 0x04,
			0x4A, 0x4A, 0x4A, 0x4A, 0x29, 0x0F, 0x0A, 0xAA, 0xBD, 0x73, 0xEF,
			0x85, 0x3C, 0xBD, 0x74, 0xEF, 0x85, 0x3D, 0xA0, 0x00, 0xB1, 0x3C, 0x10, 0x3B] },
		{ "pc": 0xEEFD, "bytes": [0x2C, 0x15, 0x06, 0x70, 0x12] },
		{ "pc": 0xEF38, "bytes": [0xE6, 0x3A, 0xA5, 0x3A, 0xC9, 0x06, 0xD0, 0x9C] },
		{ "pc": 0xEF40, "bytes": [0x2C, 0x2D, 0x06, 0x10, 0x12] },
	]
	for span_variant in source_loop_bytes:
		var span: Dictionary = span_variant
		if not _expect_actor_bytes(int(span["pc"]), span["bytes"]):
			return _stopped("unsupported_actor_loop_source", int(span["pc"]), error_message)

	var ordered_record_addresses: Array[int] = []
	var actor_outputs: Array[Dictionary] = []
	var current_oam: PackedByteArray = _ram.slice(0x0200, 0x0300)
	if current_oam.size() != 0x100:
		return _stopped("actor_oam_shadow_unavailable", 0xEEB1,
			"The live `$0200-$02FF` OAM shadow is missing from the source result.")
	var oam_cursor := 0
	var sprite_count := 0
	_record(0xEEB1); _set_a(0)
	_record(0xEEB3); _write_ram(0x003A, 0, 0xEEB3)
	_record(0xEEB5); _write_ram(0x0048, 0, 0xEEB5)
	_record(0xEEB7); _set_x(int(_ram[0x053D]))
	_record(0xEEBA)
	if int(_ram[0x053D]) != 0:
		return _stopped("unsupported_actor_count", 0xEEBB,
			"The `$EEB1` worker count is nonzero; only the live `$053D=$00` branch is checked.")
	_record(0xEEDA); _write_ram(0x003B, 0, 0xEEDA)

	for ordinal in range(6):
		var actor_index := _resolve_actor_order_index(ordinal)
		if actor_index != ordinal:
			return _stopped("unsupported_actor_order", 0xEEED,
				"The ROM order nibble at ordinal %d resolves to actor %d, outside this recorded route." % [ordinal, actor_index])
		var actor_address := _read_actor_pointer_from_rom(actor_index)
		if actor_address < 0 or actor_address + 0x15 > _ram.size():
			return _stopped("unsupported_actor_pointer", 0xEEED,
				"The source actor pointer table returned an invalid record address.")
		ordered_record_addresses.append(actor_address)
		_record(0xEEDC); _set_a(ordinal)
		_record(0xEEDE); _set_flag(0x01, (ordinal & 1) != 0); _set_a(ordinal >> 1)
		_record(0xEEDF); _set_x(int(_cpu["a"]))
		var packed_order_address := 0x0543 + int(_cpu["x"])
		_record(0xEEE0); _set_a(int(_ram[packed_order_address]))
		_record(0xEEE3)
		var order_byte := int(_cpu["a"])
		var actor_nibble := order_byte >> 4 if (ordinal & 1) == 0 else order_byte & 0x0F
		_record(0xEEE9); _set_a(actor_nibble)
		_record(0xEEEB); _set_a((actor_nibble << 1) & 0xFF)
		_record(0xEEEC); _set_x(int(_cpu["a"]))
		_record(0xEEED); _set_a(actor_address & 0xFF)
		_write_ram(0x003C, int(_cpu["a"]), 0xEEF0)
		_set_a((actor_address >> 8) & 0xFF)
		_write_ram(0x003D, int(_cpu["a"]), 0xEEF5)
		_record(0xEEF7); _set_y(0)
		_record(0xEEF9); _set_a(int(_ram[actor_address]))
		_record(0xEEFB)
		var record_before: PackedByteArray = _ram.slice(actor_address, actor_address + 0x15)
		if (int(_cpu["a"]) & 0x80) != 0:
			var actor_result := _execute_one_active_actor(actor_address, record_before,
				interpreter, oam_builder, current_oam, oam_cursor, sprite_count)
			if not bool(actor_result.get("ok", false)):
				return _stopped(String(actor_result.get("status", "actor_tick_failed")),
					int(actor_result.get("stop_pc", 0xEEFD)),
					String(actor_result.get("error", "The ROM actor update/renderer stopped.")),
					actor_result.get("detail", {}))
			current_oam = actor_result["oam_bytes"]
			oam_cursor = int(actor_result["oam_cursor"])
			sprite_count = int(actor_result["sprite_count"])
			actor_outputs.append(actor_result.get("actor", {}))
			_actor_visits.append({"ordinal": ordinal, "actor_index": actor_index,
				"actor_pointer": actor_address, "flag": int(_ram[actor_address]),
				"inactive": false, "appearance_events": actor_result.get("appearance_events", []),
				"motion_events": actor_result.get("motion_events", []),
				"oam": actor_result.get("draw_result", {})})
		else:
			_actor_visits.append({"ordinal": ordinal, "actor_index": actor_index,
				"actor_pointer": actor_address, "flag": int(_ram[actor_address]), "inactive": true})
		_record(0xEF38); _inc_ram(0x003A)
		_record(0xEF3A); _set_a(int(_ram[0x003A]))
		_record(0xEF3C); _cmp(int(_cpu["a"]), 0x06)
		_record(0xEF3E)

	if int(_ram[0x003A]) != 6:
		return _stopped("actor_loop_incomplete", int(_cpu.get("pc", 0xEF40)),
			"The source actor loop did not visit all six ordered record pointers.")
	_record(0xEF40); _set_bit_flags(int(_cpu["a"]), int(_ram[0x062D]))
	_record(0xEF43)
	if (int(_ram[0x062D]) & 0x80) != 0:
		if not _execute_actor_mapper_call(0xEF45, 0xEF54, 0x14, 0x15, 0x8009):
			return _stopped("unsupported_field_marker_call", int(_cpu.get("pc", 0xEF45)), error_message)
		if not _execute_field_player_marker_renderer():
			return _stopped("unsupported_field_marker_source", int(_cpu.get("pc", 0x8624)), error_message)
		if int(_cpu.get("pc", -1)) != 0xEF57:
			return _stopped("field_marker_return_mismatch", int(_cpu.get("pc", -1)),
				"The ROM field-marker renderer did not return to `$EF57` through its source stack.")
		current_oam = _ram.slice(0x0200, 0x0300)
		oam_cursor = int(_ram[0x003B])
		sprite_count = int(_ram[0x0048])
	else:
		_write_ram(0x003B, oam_cursor, 0xEF38)
		_write_ram(0x0048, sprite_count, 0xEF35)
	var draw_state := _finish_actor_oam_shadow_to_caller()
	if not bool(draw_state.get("ok", false)):
		return draw_state
	draw_state["actor_records"] = _current_actor_records(ordered_record_addresses)
	draw_state["source_manifest"] = EXTENSION_MANIFEST
	draw_state["actor_loop"] = {
		"status": "returned_to_source_caller", "entry_pc": 0xEEB1,
		"return_pc": 0xCA55, "ordered_record_addresses": ordered_record_addresses,
		"active_actor_count": actor_outputs.size(), "actor_outputs": actor_outputs,
		"sprite_selector": int(_ram[0x0546]), "mirror_mode": int(_ram[0x0517]),
		"scroll_x": int(_ram[0x0538]), "clip_y_min": int(_ram[0x0540]),
		"clip_y_max": int(_ram[0x0541]), "sprites_written": sprite_count,
		"final_oam_cursor": oam_cursor, "oam_shadow": _ram.slice(0x0200, 0x0300),
		"source_cycles_modeled": false,
	}
	draw_state["active_actor_init"] = seed_result.get("active_actor_init", {})
	draw_state["returned_to_caller"] = true
	draw_state["status"] = "returned_to_source_caller"
	draw_state["call_contract"] = seed_result.get("call_contract", {})
	return draw_state


func _execute_one_active_actor(actor_address: int, source_record: PackedByteArray,
		interpreter, oam_builder, initial_oam: PackedByteArray, start_cursor: int,
		initial_sprite_count: int) -> Dictionary:
	if not _expect(0xEEFD, [0x2C, 0x15, 0x06, 0x70, 0x12]):
		return {"ok": false, "status": "unsupported_actor_branch", "stop_pc": 0xEEFD, "error": error_message}
	_record(0xEEFD); _set_bit_flags(int(_cpu["a"]), int(_ram[0x0615]))
	_record(0xEF00)
	var appearance_events: Array[String] = []
	var motion_events: Array[String] = []
	var working_record := source_record.duplicate()
	if (int(_ram[0x0615]) & 0x40) == 0:
		if not _execute_actor_mapper_call(0xEF02, 0xEF11, 0x14, 0x15, 0x8006):
			return {"ok": false, "status": "unsupported_appearance_call", "stop_pc": 0xEF02, "error": error_message}
		var appearance_result = interpreter.tick_appearance_only(working_record)
		if not appearance_result.ok:
			return {"ok": false, "status": "unsupported_appearance_script", "stop_pc": 0x83D9, "error": appearance_result.error}
		var appearance_record: PackedByteArray = appearance_result.actor_record
		_rts(0x84DB)
		_apply_actor_record_diff(actor_address, working_record, appearance_record, 0x83D9)
		working_record = appearance_record
		appearance_events = appearance_result.appearance_events
		for shared_write_variant in appearance_result.shared_ram_writes:
			if not shared_write_variant is Dictionary:
				return {"ok": false, "status": "unsupported_appearance_shared_write", "stop_pc": 0x83D9,
					"error": "Appearance interpreter emitted a malformed shared-RAM write."}
			var shared_write: Dictionary = shared_write_variant
			var shared_address := int(shared_write.get("address", -1))
			var shared_value := int(shared_write.get("value", -1))
			var shared_pc := int(shared_write.get("source_pc", -1))
			if shared_address != 0x0546 or shared_value < 0 or shared_value > 0xFF or shared_pc != 0x84D8:
				return {"ok": false, "status": "unsupported_appearance_shared_write", "stop_pc": 0x83D9,
					"error": "Appearance command attempted an unverified shared-RAM write."}
			_write_ram(shared_address, shared_value, shared_pc)
	else:
		appearance_events.append("skip:$0615.6")
	if not _execute_actor_mapper_call(0xEF14, 0xEF23, 0x14, 0x15, 0x8003):
		return {"ok": false, "status": "unsupported_motion_call", "stop_pc": 0xEF14, "error": error_message}
	var motion_result = interpreter.tick_motion_only(working_record)
	if not motion_result.ok:
		return {"ok": false, "status": "unsupported_motion_script", "stop_pc": 0x84DC, "error": motion_result.error}
	var updated_record: PackedByteArray = motion_result.actor_record
	_rts(0x8623)
	_apply_actor_record_diff(actor_address, working_record, updated_record, 0x84DC)
	working_record = updated_record
	motion_events = motion_result.motion_events
	if not _execute_actor_mapper_call(0xEF26, 0xEF35, 0x16, 0x17, 0x8000):
		return {"ok": false, "status": "unsupported_oam_call", "stop_pc": 0xEF26, "error": error_message}
	var draw_input := [{"record_address": actor_address, "record_bytes": working_record}]
	var draw_result: Dictionary = oam_builder.build_oam(draw_input, int(_ram[0x0546]),
		int(_ram[0x0517]), int(_ram[0x0538]), int(_ram[0x0540]), int(_ram[0x0541]),
		initial_oam, start_cursor)
	if not bool(draw_result.get("ok", false)):
		return {"ok": false, "status": "unsupported_actor_oam", "stop_pc": 0x8000,
			"error": str(draw_result.get("error", oam_builder.last_error))}
	var output_oam: PackedByteArray = draw_result["oam_bytes"]
	_rts(0x8185)
	for index in range(output_oam.size()):
		if initial_oam[index] != output_oam[index]:
			_write_ram(0x0200 + index, int(output_oam[index]), 0x8000)
	var actor_draw: Dictionary = draw_result["actors"][0]
	var next_cursor := int(draw_result["next_oam_byte_index"])
	var next_sprite_count := initial_sprite_count + int(draw_result["sprites_written"])
	_write_ram(0x003B, next_cursor, 0x8000)
	_write_ram(0x0048, next_sprite_count, 0x8000)
	return {"ok": true, "actor": {"record_address": actor_address,
		"record_bytes": working_record.duplicate(), "appearance_events": appearance_events,
		"motion_events": motion_events, "draw_result": actor_draw}, "appearance_events": appearance_events,
		"motion_events": motion_events, "draw_result": actor_draw,
		"oam_bytes": output_oam, "oam_cursor": next_cursor,
		"sprite_count": next_sprite_count}


func _execute_actor_mapper_call(block_start: int, callsite: int, bank_low: int,
		bank_high: int, target: int) -> bool:
	var block := [0x48, 0xA5, 0x22, 0xA9, bank_low, 0x85, 0x24,
		0xA9, bank_high, 0x85, 0x25, 0x20, 0x2D, 0xCE, 0x68,
		0x20, target & 0xFF, (target >> 8) & 0xFF]
	if not _expect_actor_bytes(block_start, block):
		return false
	if target == 0x8006 and not _expect_bank14(0x8006, [0x4C, 0xD9, 0x83]): return false
	if target == 0x8003 and not _expect_bank14(0x8003, [0x4C, 0xDC, 0x84]): return false
	if target == 0x8000 and not _expect_oam_entry([0x4C, 0x03, 0x80]): return false
	if target == 0x8009 and not _expect_bank14(0x8009, [0x4C, 0x24, 0x86]): return false
	_record(block_start); _push(int(_cpu["a"]), block_start)
	_record(block_start + 1); _set_a(int(_ram[0x0022]))
	_record(block_start + 3); _set_a(bank_low)
	_record(block_start + 5); _write_ram(0x0024, bank_low, block_start + 5)
	_record(block_start + 7); _set_a(bank_high)
	_record(block_start + 9); _write_ram(0x0025, bank_high, block_start + 9)
	_record(block_start + 11); _jsr(block_start + 11, 0xCE2D)
	if not _execute_mapper_helper(): return false
	_rts(0xCE49)
	_record(block_start + 14); _set_a(_pop(block_start + 14))
	_record(callsite); _jsr(callsite, target)
	if target == 0x8006:
		_record(0x8006); _record(0x83D9)
	elif target == 0x8003:
		_record(0x8003); _record(0x84DC)
	elif target == 0x8009:
		_record(0x8009); _record(0x8624)
	else:
		_record(0x8000); _record(0x8003)
	return true


func _execute_field_player_marker_renderer() -> bool:
	if not _validate_field_marker_source_bytes():
		return false
	if (int(_ram[0x062D]) & 0x0F) != 0:
		return _stop_error("The live field-player marker mode is not the verified ROM mode zero.")
	_record(0x8624); _set_a(int(_ram[0x062D]))
	_record(0x8627); _set_a(int(_cpu["a"]) & 0x0F)
	_record(0x8629); _cmp(int(_cpu["a"]), 0x05)
	_record(0x862B)
	if _flag(0x02):
		return _stop_error("The source mode-five `$8624->$8861` renderer is outside the current route mode.")
	_record(0x8630); _jsr(0x8630, 0x8753)
	_record(0x8753); _set_a(int(_ram[0x062D]))
	_record(0x8756); _set_a(int(_cpu["a"]) & 0x0F)
	var setup_target := _execute_field_marker_inline_vector(0x8758, 0x8767,
		"bank14_field_marker_mode_table_8753_8768.bin")
	if setup_target != 0x8767:
		return false
	_record(0x8767); _rts(0x8767)
	if int(_cpu.get("pc", -1)) != 0x8633:
		return _stop_error("The source mode-zero vector did not return to `$8633`.")
	return _execute_field_marker_actor_loop()


func _execute_field_marker_actor_loop() -> bool:
	if int(_cpu.get("pc", -1)) != 0x8633:
		return _stop_error("The source field-marker dispatcher did not enter its actor loop at `$8633`.")
	_record(0x8633); _set_a(0)
	_record(0x8635); _write_ram(0x0046, 0, 0x8635)
	for expected_index in range(22):
		if int(_ram[0x0046]) != expected_index:
			return _stop_error("The ROM field-marker loop index diverged from `$%02X`." % expected_index)
		_record(0x8637); _set_a(int(_ram[0x0046]))
		_record(0x8639)
		if int(_cpu["a"]) == 0:
			_record(0x863B); _cpu["pc"] = 0x86CF
		else:
			_record(0x863E); _cmp(int(_cpu["a"]), 0x0B)
			_record(0x8640)
			if _flag(0x02):
				_record(0x8642); _cpu["pc"] = 0x86CF
			else:
				if not _execute_field_marker_visibility(expected_index):
					return false
				_record(0x8648)
				if not _flag(0x01):
					_record(0x864A); _cpu["pc"] = 0x86CF
				else:
					if not _write_one_field_player_marker(expected_index):
						return false
			_record(0x86CF)
		var next_index := (int(_ram[0x0046]) + 1) & 0xFF
		_write_ram(0x0046, next_index, 0x86CF); _set_nz(next_index)
		_record(0x86D1); _set_a(int(_ram[0x0046]))
		_record(0x86D3); _cmp(int(_cpu["a"]), 0x16)
		_record(0x86D5)
		if _flag(0x02):
			_record(0x86DA); _rts(0x86DA)
			return int(_cpu.get("pc", -1)) == 0xEF57
		_record(0x86D7); _cpu["pc"] = 0x8637
	return _stop_error("The ROM field-marker loop did not return after 22 indices.")


func _execute_field_player_marker_mode_one() -> bool:
	if not _validate_field_marker_source_bytes() \
			or not _expect_extension("bank14_field_marker_mode1_8768_8771.bin", 0x8768,
				[0xAD, 0x24, 0x06, 0x20, 0x36, 0xC5, 0x4C, 0xE7, 0x87]) \
			or not _expect_extension("bank14_field_marker_oam_writer_87E7_881D.bin", 0x87E7,
				[0x8A, 0x18, 0x69, 0xFD, 0xA6, 0x3B, 0x9D, 0x03, 0x02,
				0x98, 0x18, 0x69, 0xC7, 0x9D, 0x00, 0x02, 0xA9, 0x3C,
				0xAC, 0x2D, 0x06, 0xC0, 0x83, 0x08, 0xA0, 0x01, 0x28,
				0xD0, 0x04, 0xA0, 0x03, 0xA9, 0x11, 0x9D, 0x01, 0x02,
				0x98, 0x9D, 0x02, 0x02, 0xE8, 0xE8, 0xE8, 0xE8, 0x86,
				0x3B, 0xE6, 0x48, 0xA9, 0x01, 0x8D, 0x32, 0x05, 0x60]) \
			or (int(_ram[0x062D]) & 0x0F) != 1:
		return _stop_error("The live field-player marker mode is not the source-verified mode one.")
	_record(0x8624); _set_a(int(_ram[0x062D]))
	_record(0x8627); _set_a(int(_cpu["a"]) & 0x0F)
	_record(0x8629); _cmp(int(_cpu["a"]), 0x05)
	_record(0x862B)
	if _flag(0x02):
		return _stop_error("Mode one unexpectedly selected the `$8624->$8861` mode-five branch.")
	_record(0x8630); _jsr(0x8630, 0x8753)
	_record(0x8753); _set_a(int(_ram[0x062D]))
	_record(0x8756); _set_a(int(_cpu["a"]) & 0x0F)
	var dispatch_target := _execute_field_marker_inline_vector(0x8758, 0x8768,
		"bank14_field_marker_mode_table_8753_8768.bin")
	if dispatch_target != 0x8768 or int(_cpu.get("pc", -1)) != 0x8768:
		return _stop_error("The ROM mode-one vector did not select `$8768`.")
	_record(0x8768); _set_a(int(_ram[0x0624]))
	_record(0x876B); _jsr(0x876B, 0xC536)
	if _field_marker_div12_vector != PackedByteArray([0x4C, 0xC9, 0xCD]) \
			or _field_marker_div12_helper.size() != 0x19:
		return _stop_error("The ROM `$C536->$CDC9` field-marker position helper is unavailable.")
	_record(0xC536); _cpu["pc"] = 0xCDC9
	_record(0xCDC9); _set_x(0)
	while true:
		_record(0xCDCB); _cmp(int(_cpu["a"]), 0x0C)
		_record(0xCDCD)
		if not _flag(0x01):
			_cpu["pc"] = 0xCDD4
			break
		_record(0xCDCF); _sbc(0x0C)
		_record(0xCDD1); _set_x(int(_cpu["x"]) + 1)
		_record(0xCDD2)
		if int(_cpu["x"]) == 0:
			break
	_record(0xCDD4); _asl_a()
	_record(0xCDD5); _asl_a()
	_record(0xCDD6); _asl_a()
	_record(0xCDD7); _adc(0x54)
	_record(0xCDD9); _set_y(int(_cpu["a"]))
	_record(0xCDDA); _set_a(int(_cpu["x"]))
	_record(0xCDDB); _asl_a()
	_record(0xCDDC); _asl_a()
	_record(0xCDDD); _asl_a()
	_record(0xCDDE); _adc(0x34)
	_record(0xCDE0); _set_x(int(_cpu["a"]))
	_record(0xCDE1); _rts(0xCDE1)
	if int(_cpu.get("pc", -1)) != 0x876E:
		return _stop_error("The ROM `$CDC9` coordinate helper did not return to `$876E`.")
	_record(0x876E); _cpu["pc"] = 0x87E7
	_record(0x87E7); _set_a(int(_cpu["x"]))
	_record(0x87E8); _set_flag(0x01, false)
	_record(0x87E9); _adc(0xFD)
	_record(0x87EB); _set_x(int(_ram[0x003B]))
	_record(0x87ED); _write_ram(0x0200 + int(_cpu["x"]) + 3, int(_cpu["a"]), 0x87ED)
	_record(0x87F0); _set_a(int(_cpu["y"]))
	_record(0x87F1); _set_flag(0x01, false)
	_record(0x87F2); _adc(0xC7)
	_record(0x87F4); _write_ram(0x0200 + int(_cpu["x"]), int(_cpu["a"]), 0x87F4)
	_record(0x87F7); _set_a(0x3C)
	_record(0x87F9); _set_y(int(_ram[0x062D]))
	_record(0x87FC); _cmp(int(_cpu["y"]), 0x83)
	var saved_p := int(_cpu["p"])
	var saved_p_known := int(_cpu["p_known_mask"])
	_record(0x87FE); _push(saved_p | 0x30, 0x87FE)
	_record(0x87FF); _set_y(0x01)
	_record(0x8801)
	var popped_p := _pop(0x8801)
	_cpu["p"] = (popped_p | 0x20) & ~0x10
	_cpu["p_known_mask"] = saved_p_known | 0x20
	_record(0x8802)
	if not _flag(0x02):
		_cpu["pc"] = 0x8806
	else:
		_record(0x8804); _set_y(0x03)
	_record(0x8806); _set_a(0x11)
	_record(0x8808); _write_ram(0x0200 + int(_cpu["x"]) + 1, int(_cpu["a"]), 0x8808)
	_record(0x880B); _set_a(int(_cpu["y"]))
	_record(0x880C); _write_ram(0x0200 + int(_cpu["x"]) + 2, int(_cpu["a"]), 0x880C)
	for pc in [0x880F, 0x8810, 0x8811, 0x8812]:
		_record(pc); _set_x(int(_cpu["x"]) + 1)
	_record(0x8813); _write_ram(0x003B, int(_cpu["x"]), 0x8813)
	_record(0x8815); _inc_ram(0x0048)
	_record(0x8817); _set_a(0x01)
	_record(0x8819); _write_ram(0x0532, int(_cpu["a"]), 0x8819)
	_record(0x881C); _rts(0x881C)
	if int(_cpu.get("pc", -1)) != 0x8633:
		return _stop_error("The ROM mode-one marker writer did not return to the shared `$8633` actor loop.")
	return _execute_field_marker_actor_loop()


func _validate_field_marker_source_bytes() -> bool:
	return _expect_extension("bank14_field_marker_renderer_8624_86DB.bin", 0x8624,
			[0xAD, 0x2D, 0x06, 0x29, 0x0F, 0xC9, 0x05, 0xD0, 0x03, 0x4C, 0x61, 0x88,
			0x20, 0x53, 0x87, 0xA9, 0x00, 0x85, 0x46]) \
		and _expect_extension("bank14_field_marker_renderer_8624_86DB.bin", 0x86CF,
			[0xE6, 0x46, 0xA5, 0x46, 0xC9, 0x16, 0xF0, 0x03, 0x4C, 0x37, 0x86, 0x60]) \
		and _expect_extension("bank14_field_marker_filters_86DB_871F.bin", 0x86DB,
			[0x20, 0x0C, 0xC5, 0xAD, 0x2D, 0x06, 0x29, 0x0F, 0x20, 0x09, 0xC5]) \
		and _expect_extension("bank14_field_marker_filters_86DB_871F.bin", 0x86E6,
			[0x1D, 0x87, 0x1D, 0x87, 0x1F, 0x87, 0x3B, 0x87, 0x1D, 0x87]) \
		and _expect_extension("bank14_field_marker_filters_86DB_871F.bin", 0x871D, [0x38, 0x60]) \
		and _expect_extension("bank14_field_marker_mode_table_8753_8768.bin", 0x8753,
			[0xAD, 0x2D, 0x06, 0x29, 0x0F, 0x20, 0x09, 0xC5]) \
		and _expect_extension("bank14_field_marker_mode_table_8753_8768.bin", 0x875B,
			[0x67, 0x87, 0x68, 0x87, 0x71, 0x87, 0x84, 0x87, 0x67, 0x87, 0x00, 0x00, 0x60]) \
		and _expect_extension("bank14_field_marker_mode1_8768_8771.bin", 0x8768,
			[0xAD, 0x24, 0x06, 0x20, 0x36, 0xC5, 0x4C, 0xE7, 0x87]) \
		and _expect_extension("bank14_field_marker_oam_writer_87E7_881D.bin", 0x87E7,
			[0x8A, 0x18, 0x69, 0xFD, 0xA6, 0x3B, 0x9D, 0x03, 0x02, 0x98, 0x18, 0x69, 0xC7]) \
		and _expect_extension("bank14_field_marker_holder_blink_881D_8861.bin", 0x881D,
			[0xAC, 0x40, 0x06, 0xD0, 0x12, 0xAC, 0x41, 0x06, 0xC8, 0xC0, 0x03]) \
		and _expect_extension("bank14_field_marker_holder_blink_881D_8861.bin", 0x885B,
			[0x36, 0x37, 0x3D, 0x3D, 0x37, 0x36]) \
		and _expect_extension("bank14_field_marker_position_offsets_88DA_88E4.bin", 0x88DA,
			[0x1D, 0xFD, 0xFD, 0xFD, 0xFD, 0x2C, 0xC7, 0xC7, 0xC7, 0xC7]) \
		and _expect_extension("fixed_record_pointer_vector_C50C_C50F.bin", 0xC50C, [0x4C, 0x7C, 0xCD]) \
		and _expect_extension("fixed_record_pointer_resolver_CD7C_CD89.bin", 0xCD7C,
			[0x0A, 0xA8, 0xB9, 0x89, 0xCD, 0x85, 0x34, 0xB9, 0x8A, 0xCD, 0x85, 0x35, 0x60]) \
		and _expect_extension("fixed_dispatch_C509_C50C.bin", 0xC509, [0x4C, 0x99, 0xCB]) \
		and _expect_extension("fixed_dispatch_CB99_CBB0.bin", 0xCB99,
			[0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36,
			0x48, 0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00])


func _execute_field_marker_visibility(player_index: int) -> bool:
	_record(0x8645); _jsr(0x8645, 0x86DB)
	_record(0x86DB); _jsr(0x86DB, 0xC50C)
	_record(0xC50C); _cpu["pc"] = 0xCD7C
	_record(0xCD7C); _asl_a()
	_record(0xCD7D); _set_y(int(_cpu["a"]))
	var pointer_offset := int(_cpu["y"])
	if pointer_offset + 1 >= _player_record_pointer_bytes.size():
		return _stop_error("The source `$CD7C` player-record index is outside the 22-entry ROM table.")
	var player_record := int(_player_record_pointer_bytes[pointer_offset]) \
		| (int(_player_record_pointer_bytes[pointer_offset + 1]) << 8)
	var expected_record := 0x0300 + player_index * 0x0C
	if player_record != expected_record:
		return _stop_error("ROM player-record pointer %d differs from the source match-zero record map." % player_index)
	_record(0xCD7E); _set_a(int(_player_record_pointer_bytes[pointer_offset]))
	_record(0xCD81); _write_ram(0x0034, int(_cpu["a"]), 0xCD81)
	_record(0xCD83); _set_a(int(_player_record_pointer_bytes[pointer_offset + 1]))
	_record(0xCD86); _write_ram(0x0035, int(_cpu["a"]), 0xCD86)
	_record(0xCD88); _rts(0xCD88)
	if int(_cpu.get("pc", -1)) != 0x86DE:
		return _stop_error("The source player-record resolver did not return to `$86DE`.")
	_record(0x86DE); _set_a(int(_ram[0x062D]))
	_record(0x86E1); _set_a(int(_cpu["a"]) & 0x0F)
	var dispatch_target := _execute_field_marker_inline_vector(0x86E3, 0x871D,
		"bank14_field_marker_filters_86DB_871F.bin")
	if dispatch_target != 0x871D:
		return _stop_error("The mode-zero ROM filter selected `$%04X`, expected `$871D`." % dispatch_target)
	_record(0x871D); _set_flag(0x01, true)
	_record(0x871E); _rts(0x871E)
	return int(_cpu.get("pc", -1)) == 0x8648


func _execute_field_marker_inline_vector(callsite: int, expected_target: int,
		table_file: String) -> int:
	_record(callsite); _jsr(callsite, 0xC509)
	_record(0xC509); _cpu["pc"] = 0xCB99
	_record(0xCB99); _asl_a()
	_record(0xCB9A); _set_y(int(_cpu["a"]))
	_record(0xCB9B); _set_a(_pop(0xCB9B))
	_record(0xCB9C); _write_ram(0x0036, int(_cpu["a"]), 0xCB9C)
	_record(0xCB9E); _set_a(_pop(0xCB9E))
	_record(0xCB9F); _write_ram(0x0037, int(_cpu["a"]), 0xCB9F)
	_record(0xCBA1); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	var table_base := int(_ram[0x0036]) | (int(_ram[0x0037]) << 8)
	var high_byte := _field_marker_source_byte(table_file, table_base + int(_cpu["y"]))
	if high_byte < 0:
		_stop_error("The `$C509` ROM callback table lookup is outside its checked source span.")
		return -1
	_record(0xCBA2); _set_a(high_byte)
	_record(0xCBA4); _push(int(_cpu["a"]), 0xCBA4)
	_record(0xCBA5); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	var low_byte := _field_marker_source_byte(table_file, table_base + int(_cpu["y"]))
	if low_byte < 0:
		_stop_error("The `$C509` ROM callback target lookup is outside its checked source span.")
		return -1
	_record(0xCBA6); _set_a(low_byte)
	_record(0xCBA8); _write_ram(0x0037, int(_cpu["a"]), 0xCBA8)
	_record(0xCBAA); _set_a(_pop(0xCBAA))
	_record(0xCBAB); _write_ram(0x0036, int(_cpu["a"]), 0xCBAB)
	var target := int(_ram[0x0036]) | (int(_ram[0x0037]) << 8)
	_record(0xCBAD); _cpu["pc"] = target
	if target != expected_target:
		_stop_error("The ROM inline callback selected `$%04X`; expected `$%04X`." % [target, expected_target])
		return -1
	return target


func _field_marker_source_byte(filename: String, address: int) -> int:
	if not EXTENSION_SPANS.has(filename):
		return -1
	var spec: Dictionary = EXTENSION_SPANS[filename]
	if address < int(spec["start"]) or address >= int(spec["end"]):
		return -1
	return _extra_byte(filename, address)


func _write_one_field_player_marker(player_index: int) -> bool:
	var x := int(_ram[0x003B])
	if x > 0xF8 or x & 0x03 != 0 or int(_ram[0x0048]) >= 64:
		return _stop_error("The ROM field-player marker would exceed the OAM sprite limit.")
	_record(0x864D); _set_x(x)
	_record(0x864F); _set_y(0x06)
	var record_address := int(_ram[0x0034]) | (int(_ram[0x0035]) << 8)
	if record_address + 8 >= _ram.size():
		return _stop_error("The ROM field-player marker record pointer is outside CPU RAM.")
	_record(0x8651); _set_a(int(_ram[record_address + 6]))
	_record(0x8653); _cmp(int(_cpu["a"]), 0x34)
	_record(0x8655)
	if not _flag(0x01):
		_record(0x8657); _set_a(0x34)
	_record(0x8659); _cmp(int(_cpu["a"]), 0xCC)
	_record(0x865B)
	if _flag(0x01):
		_record(0x865D); _set_a(0xCC)
	_record(0x865F); _push(int(_cpu["a"]), 0x865F)
	_record(0x8660); _set_a(int(_ram[0x062D]))
	_record(0x8663); _set_a(int(_cpu["a"]) & 0x0F)
	_record(0x8665); _set_y(int(_cpu["a"]))
	_record(0x8666); _set_a(_pop(0x8666))
	_record(0x8667); _set_flag(0x01, false)
	var y_offset := _field_marker_source_byte("bank14_field_marker_position_offsets_88DA_88E4.bin", 0x88DA + int(_cpu["y"]))
	if y_offset < 0: return _stop_error("The ROM Y-offset table read is outside its checked span.")
	_record(0x8668); _adc_field_marker_value(y_offset)
	_record(0x866B); _write_ram(0x0200 + int(_cpu["x"]) + 3, int(_cpu["a"]), 0x866B)
	_record(0x866E); _set_y(0x08)
	_record(0x8670); _set_a(int(_ram[record_address + 8]))
	_record(0x8672); _cmp(int(_cpu["a"]), 0x54)
	_record(0x8674)
	if not _flag(0x01):
		_record(0x8676); _set_a(0x54)
	_record(0x8678); _cmp(int(_cpu["a"]), 0xAC)
	_record(0x867A)
	if _flag(0x01):
		_record(0x867C); _set_a(0xAC)
	_record(0x867E); _push(int(_cpu["a"]), 0x867E)
	_record(0x867F); _set_a(int(_ram[0x062D]))
	_record(0x8682); _set_a(int(_cpu["a"]) & 0x0F)
	_record(0x8684); _set_y(int(_cpu["a"]))
	_record(0x8685); _set_a(_pop(0x8685))
	_record(0x8686); _set_flag(0x01, false)
	var x_offset := _field_marker_source_byte("bank14_field_marker_position_offsets_88DA_88E4.bin", 0x88DF + int(_cpu["y"]))
	if x_offset < 0: return _stop_error("The ROM X-offset table read is outside its checked span.")
	_record(0x8687); _adc_field_marker_value(x_offset)
	_record(0x868A); _write_ram(0x0200 + int(_cpu["x"]), int(_cpu["a"]), 0x868A)
	_record(0x868D); _set_a(0x03)
	_record(0x868F); _write_ram(0x0200 + int(_cpu["x"]) + 2, int(_cpu["a"]), 0x868F)
	_record(0x8692); _set_bit_flags(int(_cpu["a"]), int(_ram[0x0615]))
	_record(0x8695)
	var holder_index := int(_ram[0x0441])
	if _flag(0x80) and int(_ram[0x05FB]) != 0 and player_index < 0x0B:
		return _stop_error("The ROM `$86F2` secondary holder-animation path is not yet implemented for live `$05FB!=0`.")
	_record(0x86A8); _set_a(int(_ram[0x0046]))
	_record(0x86AA); _cmp(int(_cpu["a"]), holder_index)
	_record(0x86AD)
	if _flag(0x02):
		_record(0x86AF); _jsr(0x86AF, 0x881D)
		if not _execute_field_marker_holder_blink(int(_cpu["x"])):
			return false
		_record(0x885A); _rts(0x885A)
		if int(_cpu.get("pc", -1)) != 0x86B2:
			return _stop_error("The holder-marker blink helper did not return to `$86B2`.")
		_record(0x86B2); _cpu["pc"] = 0x86C4
	else:
		_record(0x86B5); _cmp(int(_cpu["a"]), 0x0B)
		_record(0x86B7)
		if _flag(0x01):
			_record(0x86B9); _sbc(0x01)
		_record(0x86BB); _set_flag(0x01, false)
		_record(0x86BC); _adc_field_marker_value(0x11)
		_record(0x86BE); _cmp(int(_cpu["a"]), 0x20)
		_record(0x86C0)
		if _flag(0x01):
			_record(0x86C2); _adc_field_marker_value(0x0F)
	_record(0x86C4); _write_ram(0x0200 + int(_cpu["x"]) + 1, int(_cpu["a"]), 0x86C4)
	for pc in [0x86C7, 0x86C8, 0x86C9, 0x86CA]:
		_record(pc); _set_x((int(_cpu["x"]) + 1) & 0xFF)
	_record(0x86CB); _write_ram(0x003B, int(_cpu["x"]), 0x86CB)
	_record(0x86CD)
	var next_count := (int(_ram[0x0048]) + 1) & 0xFF
	_write_ram(0x0048, next_count, 0x86CD); _set_nz(next_count)
	return true


func _execute_field_marker_holder_blink(oam_x: int) -> bool:
	_record(0x881D); _set_y(int(_ram[0x0640]))
	_record(0x8820)
	if int(_cpu["y"]) == 0:
		_record(0x8822); _set_y(int(_ram[0x0641]))
		_record(0x8825); _set_y((int(_cpu["y"]) + 1) & 0xFF)
		_record(0x8826); _cmp(int(_cpu["y"]), 0x03)
		_record(0x8828)
		if not _flag(0x02):
			_record(0x882A); _set_y(0)
		_record(0x882C); _write_ram(0x0641, int(_cpu["y"]), 0x882C)
		_record(0x882F); _set_a(0x04)
		_record(0x8831); _write_ram(0x0640, int(_cpu["a"]), 0x8831)
	_record(0x8834); _set_a(0x00)
	_record(0x8836); _set_y(int(_ram[0x05FB]))
	var saved_p := int(_cpu["p"])
	var saved_p_known := int(_cpu["p_known_mask"])
	_record(0x8839); _push(saved_p | 0x30, 0x8839)
	_record(0x883A); _set_y(int(_ram[0x0641]))
	_record(0x883D)
	var popped_p := _pop(0x883D)
	_cpu["p"] = (popped_p | 0x20) & ~0x10
	_cpu["p_known_mask"] = saved_p_known | 0x20
	_record(0x883E)
	if int(_ram[0x05FB]) == 0:
		_record(0x8840); _set_a(int(_cpu["y"]))
		_record(0x8841); _set_flag(0x01, false)
		_record(0x8842); _adc_field_marker_value(0x03)
		_record(0x8844); _set_y(int(_cpu["a"]))
		_record(0x8845); _set_a(0x80)
	_record(0x8847); _set_bit_flags(int(_cpu["a"]), int(_ram[0x0637]))
	_record(0x884A)
	if not _flag(0x80):
		_record(0x884C); _set_a(int(_cpu["a"]) ^ 0x80)
	_record(0x884E); _set_a(int(_cpu["a"]) | int(_ram[0x0200 + oam_x + 2]))
	_record(0x8851); _write_ram(0x0200 + oam_x + 2, int(_cpu["a"]), 0x8851)
	var blink_index := int(_cpu["y"])
	var blink_tile := _field_marker_source_byte("bank14_field_marker_holder_blink_881D_8861.bin", 0x885B + blink_index)
	if blink_index < 0 or blink_index >= 6 or blink_tile < 0:
		return _stop_error("The ROM holder-blink sequence index is outside the verified six-byte table.")
	_record(0x8854); _set_a(blink_tile)
	_record(0x8857)
	var countdown := (int(_ram[0x0640]) - 1) & 0xFF
	_write_ram(0x0640, countdown, 0x8857); _set_nz(countdown)
	return true


func _adc_field_marker_value(value: int) -> void:
	var left := int(_cpu["a"])
	var carry := 1 if _flag(0x01) else 0
	var total := left + (value & 0xFF) + carry
	var result := total & 0xFF
	_set_flag(0x01, total > 0xFF)
	_set_flag(0x40, ((~(left ^ value) & (left ^ result)) & 0x80) != 0)
	_set_a(result)


func _expect_oam_entry(expected: Array) -> bool:
	var bytes := FileAccess.get_file_as_bytes("res://reference/rom_extract/gameplay/actor_oam/bank16_sprite_engine_8000_8185.bin")
	if bytes.size() != 0x186 or _sha256(bytes) != "4c8913c90c578a7924f74b8a94b91ff5ac4b059c7c9e7304d3f48a7ae67f9894":
		return _stop_error("The ROM-derived bank-$16 actor renderer failed its source hash.")
	for index in range(expected.size()):
		if int(bytes[index]) != expected[index]:
			return _stop_error("The bank-$16 actor renderer entry differs at `$8000`.")
	return true


func _expect_actor_bytes(pc: int, expected: Array) -> bool:
	var typed_bytes: Array[int] = []
	for value_variant in expected:
		typed_bytes.append(int(value_variant))
	return _expect(pc, typed_bytes)


func _finish_actor_oam_shadow_to_caller() -> Dictionary:
	if not _expect_actor_bytes(0xEF57, [0xA9, 0x40, 0x38, 0xE5, 0x48, 0x8D, 0x3F, 0x05]) \
			or not _expect_actor_bytes(0xEF5F, [0x90, 0x11]) \
			or not _expect_actor_bytes(0xEF61, [0xF0, 0x0F]) \
			or not _expect_actor_bytes(0xEF63, [0xA8, 0xA6, 0x3B, 0xA9, 0xF8, 0x9D, 0x00, 0x02,
			0xE8, 0xE8, 0xE8, 0xE8, 0x88, 0xD0, 0xF6, 0x60]):
		return _stopped("unsupported_oam_shadow_clear", int(_cpu.get("pc", 0xEF57)), error_message)
	_record(0xEF57); _set_a(0x40)
	_record(0xEF59); _set_flag(0x01, true)
	_record(0xEF5A); _sbc(int(_ram[0x0048]))
	_record(0xEF5C); _write_ram(0x053F, int(_cpu["a"]), 0xEF5C)
	_record(0xEF5F)
	if not _flag(0x01):
		return _stopped("unsupported_oam_length", 0xEF5F,
			"The ROM OAM shadow clear underflowed because its sprite count exceeds 64.")
	_record(0xEF61)
	if _flag(0x02):
		_record(0xEF72)
	else:
		_record(0xEF63); _set_y(int(_cpu["a"]))
		_record(0xEF64); _set_x(int(_ram[0x003B]))
		_record(0xEF66); _set_a(0xF8)
		var remaining := int(_cpu["y"])
		for iteration in range(remaining):
			var x_value := int(_cpu["x"])
			_record(0xEF68); _write_ram(0x0200 + x_value, 0xF8, 0xEF68)
			for pc in [0xEF6B, 0xEF6C, 0xEF6D, 0xEF6E]:
				_record(pc); _set_x((int(_cpu["x"]) + 1) & 0xFF)
			_record(0xEF6F); _set_y((int(_cpu["y"]) - 1) & 0xFF)
			_record(0xEF70)
		_record(0xEF72)
	_rts(0xEF72)
	if int(_cpu["pc"]) != 0xCA55 or int(_cpu["sp"]) != 0x2A:
		return _stopped("source_state_uncertainty", int(_cpu["pc"]),
			"The active-actor `$EE9F` RTS did not restore `$CA55` / `$2A`.")
	return {"ok": true, "status": "returned_to_source_caller",
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"entry": {"slot_base": 0x01, "call_pc": 0xCA52, "target_pc": 0xEE9F,
			"expected_return_pc": 0xCA55,
			"source": "live slot-$01 scheduler dispatch and RAM/stack snapshot"},
		"registers": _register_snapshot(),
		"mapper": {"register_select": int(_mapper["select"]),
			"bank_registers": (_mapper.get("bank_registers", {}) as Dictionary).duplicate(true),
			"task_bank_low": int(_cpu["bank_low"]), "task_bank_high": int(_cpu["bank_high"])},
		"ram_image": _ram.duplicate(), "stack_page": _stack.duplicate(),
		"memory_writes": _writes.duplicate(true), "actor_visits": _actor_visits.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(), "instruction_count": _instruction_pcs.size(),
		"returned_to_caller": true, "ppu_bus_events": [],
		"ppu_cycle_timing_modeled": false, "audio_effects_modeled": false}


func _apply_actor_record_diff(actor_address: int, before: PackedByteArray,
		after: PackedByteArray, source_pc: int) -> void:
	for index in range(min(before.size(), after.size())):
		if before[index] != after[index]:
			_write_ram(actor_address + index, int(after[index]), source_pc)


func _resolve_actor_order_index(ordinal: int) -> int:
	if ordinal < 0 or ordinal >= 6: return -1
	var order_byte := int(_ram[0x0543 + (ordinal >> 1)])
	return (order_byte >> 4) & 0x0F if (ordinal & 1) == 0 else order_byte & 0x0F


func _read_actor_pointer_from_rom(actor_index: int) -> int:
	var source := _source.get("fixed", PackedByteArray()) as PackedByteArray
	var offset := 0xEF73 - int(SOURCE_STARTS.get("fixed", 0)) + actor_index * 2
	if actor_index < 0 or actor_index >= 6 or offset < 0 or offset + 1 >= source.size(): return -1
	return int(source[offset]) | (int(source[offset + 1]) << 8)


func _current_actor_records(addresses: Array[int]) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for index in range(addresses.size()):
		var address := addresses[index]
		var bytes: PackedByteArray = _ram.slice(address, address + 0x15)
		records.append({"actor_index": index, "cpu_address": address, "bytes": bytes,
			"active_flags": int(bytes[0]),
			"motion_pointer": int(bytes[1]) | (int(bytes[2]) << 8),
			"appearance_pointer": int(bytes[3]) | (int(bytes[4]) << 8)})
	return records
