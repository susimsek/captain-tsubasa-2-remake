extends "res://scripts/gameplay/rom_ee9f_empty_actor_call_executor.gd"
class_name RomEe9fActorInit80Executor
## Extends the checked $EE9F executor for one live slot-$01 first call:
## `$053A=$80` selects animation `$8F`; it executes `$F5 $0A`, `$F4`, five
## `$F1` record constructors, and `$F0`, stopping at `$EEB1` before actor work.

const EXTENSION_ROOT := "res://reference/rom_extract/gameplay/ee9f_actor_init_80/"
const EXTENSION_MANIFEST := EXTENSION_ROOT + "manifest.json"
const EXTENSION_SCHEMA := "ct2-ee9f-actor-init-80-source-v1"
const STREAM_PATH := "res://reference/rom_extract/gameplay/first_command_actors/route_animation_8F.bin"
const STREAM_SHA256 := "584a6c5108c0efe657a9a8e1dc531cabb0572eebdc605540c6578a0f7d7f643f"
const STREAM_DECODER := preload("res://scripts/gameplay/rom_actor_animation_stream_decoder.gd")
const F1_CONSTRUCTOR := preload("res://scripts/gameplay/rom_f1_actor_record_constructor.gd")
const ACTOR_INTERPRETER := preload("res://scripts/gameplay/rom_actor_state_interpreter.gd")
const ACTOR_OAM_BUILDER := preload("res://scripts/gameplay/gameplay_rom_actor_oam_builder.gd")
const PALETTE_HELPER_PATH := "res://reference/rom_extract/gameplay/slot09_eb8b_continuation/fixed_palette_fill_helper_CC02_CC45.bin"
const PALETTE_HELPER_SHA256 := "9fa6a2837a6bcf360ccc1df464b2242fe4a287330b8173c4415718e7fc9cfc68"
const INLINE_APPEND_HELPER_PATH := "res://reference/rom_extract/gameplay/slot09_86f8_worker/fixed_inline_record_append_handler_CCD2_CD0C.bin"
const INLINE_APPEND_HELPER_SHA256 := "7c23b91502ce9ebf01c18cbf401030f35181dbdc359d245cc7d7d57dd2cbc37b"
const EXTENSION_SPANS := {
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
	"fixed_palette_vectors_C530_C536.bin": {
		"bank": "$1E", "start": 0xC530, "end": 0xC536,
		"file_offset": 0x03C540, "length": 6,
		"sha256": "a8e8cc65722c34d77be8b617a0bd428012a3d4d94e4bc854e170a0be25363193",
	},
	"fixed_palette_table_FC44_FC50.bin": {
		"bank": "$1F", "start": 0xFC44, "end": 0xFC50,
		"file_offset": 0x03FC54, "length": 12,
		"sha256": "249458e73da7f4ef10e9919831c71d8aeb5fde9fd0c829dfa096dd23ba03921b",
	},
}

var _extension_sources: Dictionary = {}
var _extension_configured := false
var _animation_8f := PackedByteArray()
var _stream_decoder
var _f1_constructor
var _palette_helper := PackedByteArray()
var _inline_append_helper := PackedByteArray()
var _initial_append_cursor := -1


func configure_from_project_sources() -> bool:
	_extension_configured = false
	_extension_sources.clear()
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
	if _sha256(_palette_helper) != PALETTE_HELPER_SHA256 \
			or _sha256(_inline_append_helper) != INLINE_APPEND_HELPER_SHA256:
		return _fail("A reused fixed-bank helper failed its source-byte hash check.")
	_animation_8f = FileAccess.get_file_as_bytes(STREAM_PATH)
	if _animation_8f.size() != 38 or _sha256(_animation_8f) != STREAM_SHA256 \
			or not _expect_stream_prefix():
		return _fail("Existing animation-$8F source bytes do not match their checked manifest span.")
	_extension_configured = true
	return true


func execute_from_source_call(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary) -> Dictionary:
	return _execute_source_call(dispatch, boundary, callee_request, false)


## Executes the active `$8F` actor loop after the verified `$F0->$EEB1` seed
## prefix and returns through the real `$CA52` caller stack to `$CA55`.
func execute_to_source_caller(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary) -> Dictionary:
	return _execute_source_call(dispatch, boundary, callee_request, true)


func _execute_source_call(dispatch: Dictionary, boundary: Dictionary,
		callee_request: Dictionary, continue_actor_loop: bool) -> Dictionary:
	if not _extension_configured:
		return _failure("Configure the checked actor-init source package first.")
	var base_result: Dictionary = super.execute_from_source_call(dispatch, boundary, callee_request)
	if bool(base_result.get("ok", false)):
		return base_result
	var base_status := String(base_result.get("status", ""))
	if base_status == "stopped_at_first_active_actor" and continue_actor_loop:
		return _resume_active_actor_loop_from_stop(dispatch, callee_request, base_result)
	if base_status != "unsupported_bank14_gate":
		return base_result
	if not _validate_actor_init_gate(dispatch, boundary, callee_request, base_result):
		return _failure(error_message)
	if not _execute_actor_init_to_ee_b1():
		return _stopped("unsupported_actor_init_source", int(_cpu.get("pc", 0)), error_message)
	var seed_result := _finish_actor_init_return(dispatch, callee_request)
	if not continue_actor_loop or not bool(seed_result.get("ok", false)):
		return seed_result
	return _execute_active_actor_loop_to_caller(dispatch, callee_request, seed_result)


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
		return _stopped("unsupported_actor_mode", 0xEF45,
			"The source `$062D.7` branch after actor drawing is outside this route slice.")
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
	status["supports_live_053a_80_animation_8f_first_call"] = _extension_configured
	status["active_actor_init_stop"] = "$EEB1 after ROM `$F5`, `$F4`, five `$F1` packets and `$F0`; `$EEB1` itself is not executed"
	return status


func _validate_actor_init_gate(dispatch: Dictionary, boundary: Dictionary,
		request: Dictionary, result: Dictionary) -> bool:
	var partial: Dictionary = result.get("partial_state", {})
	var registers: Dictionary = partial.get("registers", {})
	var ram: PackedByteArray = partial.get("ram_image", PackedByteArray())
	if ram.size() == RAM_SIZE:
		_initial_append_cursor = int(ram[0x0498])
	var source_dispatch: Dictionary = result.get("call_contract", {}).get("dispatch", {})
	if int(result.get("stop_pc", -1)) != 0x8012 \
			or int(registers.get("pc", -1)) != 0x8012 \
			or ram.size() != RAM_SIZE or int(ram[0x053A]) != 0x80 \
			or int(ram[0x053B]) != 0 or int(ram[0x053C]) != 0x8F \
			or int(ram[0x053D]) != 0 or int(ram[0x0000]) != 0x01 \
			or int(dispatch.get("pc", -1)) != 0xCA52 \
			or int(boundary.get("active_task_slot", -1)) != 0x01 \
			or int(request.get("source_pc", -1)) != 0xCA52 \
			or int(request.get("target_cpu_address", -1)) != 0xEE9F \
			or int(request.get("call_ordinal", -1)) != 0 \
			or source_dispatch != dispatch:
		error_message = "Live `$CA52->$EE9F` boundary does not prove the first `$053A=$80/$053C=$8F` actor-init call."
		return false
	for name: String in ["a", "x", "y", "sp", "bank_low", "bank_high"]:
		if not boundary.has(name) or not dispatch.has(name) \
				or int(boundary[name]) != int(dispatch[name]):
			error_message = "Live scheduler snapshot and yielded dispatch disagree on `%s`." % name
			return false
	return true


func _validate_animation_stream_source() -> bool:
	return _animation_8f.size() == 38 \
			and _animation_8f.slice(0, 7) == PackedByteArray([0xF5, 0x0A, 0xF4, 0x2C, 0x0B, 0x05, 0x07])


func _expect_stream_prefix() -> bool:
	return _validate_animation_stream_source()


func _read_stream_at_live_pointer(offset: int) -> int:
	var stream_pointer := int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)
	var stream_offset := stream_pointer - 0x9885 + offset
	if stream_offset < 0 or stream_offset >= _animation_8f.size():
		return -1
	return int(_animation_8f[stream_offset])


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


func _execute_actor_init_to_ee_b1() -> bool:
	if not _validate_actor_init_source_bytes():
		return false
	var decoded: Dictionary = _stream_decoder.decode_animation(0x8F)
	if not bool(decoded.get("ok", false)) or not _validate_decoded_events(decoded.get("events", [])):
		return _stop_error("Checked `$8F` decode is not the audited F5/F4/five-F1/F0 stream.")
	if not _execute_actor_init_prelude():
		return false
	var events: Array = decoded["events"]
	if not _execute_f5_event(events[0]) or int(_cpu["pc"]) != 0x8078:
		return false
	_record(0x8078)
	if not _execute_f4_event(events[1]) or int(_cpu["pc"]) != 0x8078:
		return false
	_record(0x8078)
	for index in range(5):
		if not _execute_f1_event(events[index + 2]) or int(_cpu["pc"]) != 0x8078:
			return false
		_record(0x8078)
	if not _execute_f0_event(events[7]):
		return false
	if int(_cpu["pc"]) != 0xEEB1 or int(_cpu["sp"]) != 0x28:
		return _stop_error("F0 boundary registers differ: PC=$%04X SP=$%02X." % [int(_cpu["pc"]), int(_cpu["sp"])])
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
			and _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x80A2,
			[0x68, 0x68, 0xA9, 0x00, 0x8D, 0x3A, 0x05, 0x60]) \
			and _expect_extension("bank14_animation_dispatch_8084_8164.bin", 0x80AA,
			[0xA0, 0x05, 0xB1, 0x4C, 0x29, 0x1C, 0x4A, 0xAA, 0xBD, 0xE4, 0x88, 0x85, 0x3A, 0xBD, 0xE5, 0x88, 0x85, 0x3B]) \
			and _expect_extension("fixed_palette_vectors_C530_C536.bin", 0xC530,
			[0x4C, 0x02, 0xCC, 0x4C, 0xD2, 0xCC]) \
			and _expect_extension("fixed_palette_table_FC44_FC50.bin", 0xFC44,
			[0x0F, 0x0F, 0x36, 0x0F, 0x30, 0x36, 0x0F, 0x17, 0x36, 0x0F, 0x31, 0x30])


func _validate_decoded_events(events_variant: Variant) -> bool:
	if not events_variant is Array:
		return false
	var events: Array = events_variant
	if events.size() != 8:
		return false
	if events[0].kind != STREAM_DECODER.SourceEvent.Kind.SETUP_OPERAND \
			or events[0].raw_bytes != PackedByteArray([0xF5, 0x0A]) \
			or events[1].kind != STREAM_DECODER.SourceEvent.Kind.SPRITE_CHR_SELECTORS \
			or events[1].raw_bytes != PackedByteArray([0xF4, 0x2C, 0x0B, 0x05, 0x07]):
		return false
	var expected_addresses: Array[int] = [0x988C, 0x9892, 0x9898, 0x989E, 0x98A4]
	for index in range(5):
		var event = events[index + 2]
		if event.kind != STREAM_DECODER.SourceEvent.Kind.ACTOR_PACKET \
				or int(event.source_cpu_address) != expected_addresses[index] \
				or event.raw_bytes.size() != 6:
			return false
	return events[7].kind == STREAM_DECODER.SourceEvent.Kind.STREAM_END \
			and int(events[7].source_cpu_address) == 0x98AA


func _execute_actor_init_prelude() -> bool:
	if int(_cpu.get("a", -1)) != 0x80 or not _flag(0x80):
		return _stop_error("The live `$8012` branch no longer has the negative `$80` selector.")
	_record(0x8012)
	_record(0x8014)
	_record(0x8016); _set_x(1)
	_record(0x8018); _write_ram(0x053A, 1, 0x8018)
	_record(0x801B); _set_a(int(_ram[0x053C]))
	_record(0x801E); _set_x(0x68)
	_record(0x8020); _write_ram(0x004C, 0x68, 0x8020)
	_record(0x8022); _set_x(0x89)
	_record(0x8024); _write_ram(0x004D, 0x89, 0x8024)
	_record(0x8026); _asl_a()
	_record(0x8027)
	if not _flag(0x01):
		return _stop_error("ROM animation lookup did not carry `$8F<<1` into `$4D`.")
	_record(0x8029); _write_ram(0x004D, (int(_ram[0x004D]) + 1) & 0xFF, 0x8029)
	_set_nz(int(_ram[0x004D]))
	_record(0x802B); _set_y(int(_cpu["a"]))
	var table_address := ((int(_ram[0x004D]) << 8) | int(_ram[0x004C])) + int(_cpu["y"])
	if table_address != 0x8A86:
		return _stop_error("The `$8F` animation pointer lookup missed `$8A86`.")
	_record(0x802C); _set_a(_extra_byte("bank14_animation_pointer_8F_90_8A86.bin", table_address))
	_record(0x802E); _set_x(int(_cpu["a"]))
	_record(0x802F); _set_y((int(_cpu["y"]) + 1) & 0xFF)
	_record(0x8030); _set_a(_extra_byte("bank14_animation_pointer_8F_90_8A86.bin", table_address + 1))
	_record(0x8032); _write_ram(0x004C, int(_cpu["x"]), 0x8032)
	_record(0x8034); _write_ram(0x004D, int(_cpu["a"]), 0x8034)
	if int(_ram[0x004C]) != 0x85 or int(_ram[0x004D]) != 0x98:
		return _stop_error("The `$8F` pointer table did not select stream `$9885`.")
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
	if event.raw_bytes != PackedByteArray([0xF5, 0x0A]) \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != 0x9885:
		return _stop_error("The live `$F5 $0A` command does not begin at `$9885`.")
	if not _begin_stream_command(0x8153):
		return false
	_record(0x8153); _set_y(1)
	_record(0x8155); _set_a(_read_stream_at_live_pointer(1))
	_record(0x8157)
	if int(_cpu["a"]) != 0x0A or _flag(0x80):
		return _stop_error("The ROM `$F5` positive-operand path is not selected for `$0A`.")
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
			and (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) == 0x9887


func _execute_f4_event(event) -> bool:
	if event.raw_bytes != PackedByteArray([0xF4, 0x2C, 0x0B, 0x05, 0x07]) \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != 0x9887:
		return _stop_error("The live `$F4` selector command does not begin at `$9887`.")
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
			and (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) == 0x988C


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
	if event.kind != STREAM_DECODER.SourceEvent.Kind.STREAM_END \
			or int(event.source_cpu_address) != 0x98AA \
			or (int(_ram[0x004C]) | (int(_ram[0x004D]) << 8)) != 0x98AA:
		return _stop_error("The source `$F0` byte does not match live stream cursor `$98AA`.")
	if not _begin_stream_command(0x80A2):
		return false
	_record(0x80A2); _set_a(_pop(0x80A2))
	_record(0x80A3); _set_a(_pop(0x80A3))
	_record(0x80A4); _set_a(0)
	_record(0x80A6); _write_ram(0x053A, 0, 0x80A6)
	_record(0x80A9); _rts(0x80A9)
	return int(_cpu["pc"]) == 0xEEB1


func _execute_palette_fill_helper() -> bool:
	if _palette_helper.size() != 0x44 or _sha256(_palette_helper) != PALETTE_HELPER_SHA256 \
			or int(_cpu["a"]) != 0x0A or int(_cpu["x"]) != 0x10:
		return _stop_error("The reused `$CC02` helper or its `$F5 $0A` entry state is invalid.")
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
	if int(_ram[0x0065]) != 0x44 or int(_ram[0x0066]) != 0xFC:
		return _stop_error("`$CC02` did not compute the ROM palette row at `$FC44`.")
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
			_set_a(int(_extra_byte("fixed_palette_table_FC44_FC50.bin", 0xFC44 + table_index)))
			table_index += 1
			_record(0xCC30); _set_y((int(_cpu["y"]) + 1) & 0xFF)
			_record(0xCC31)
		_record(0xCC35); _write_ram(0x046F + x_value, int(_cpu["a"]), 0xCC35)
		_record(0xCC38); _set_x(x_value + 1)
		_record(0xCC39); _write_ram(0x046C, 15 - palette_index, 0xCC39)
		_set_nz(int(_ram[0x046C]))
		_record(0xCC3C)
	if table_index != 12:
		return _stop_error("`$CC02` did not consume exactly twelve palette bytes from `$FC44`.")
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
	var append_base := 0x0499 + _initial_append_cursor * 3
	if int(_cpu.get("pc", -1)) != 0xEEB1 or int(_cpu.get("sp", -1)) != 0x28 \
			or pointer != 0x98AA or int(_ram[0x053A]) != 0 \
			or int(_ram[0x053B]) != 0 or int(_ram[0x053C]) != 0x8F \
			or int(_ram[0x053D]) != 0 or int(_ram[0x0498]) != _initial_append_cursor + 1 \
			or _ram.slice(0x0494, 0x0498) != PackedByteArray([0x2C, 0x0B, 0x05, 0x07]) \
			or _ram.slice(append_base, append_base + 3) != PackedByteArray([0x00, 0x6C, 0x04]):
		return _stopped("source_state_uncertainty", int(_cpu.get("pc", 0)),
			"Final first-call state mismatch: PC=$%04X SP=$%02X stream=$%04X 053A-D=%s 0494-9B=%s 0498=%02X." % [
			int(_cpu.get("pc", 0)), int(_cpu.get("sp", 0)), pointer,
			_ram.slice(0x053A, 0x053E).hex_encode(), _ram.slice(0x0494, 0x049C).hex_encode(), int(_ram[0x0498])])
	var actor_records: Array[Dictionary] = []
	for actor_index in range(5):
		var address := 0x0547 + actor_index * 0x15
		actor_records.append({"actor_index": actor_index, "cpu_address": address,
			"bytes": _ram.slice(address, address + 0x15), "active_flags": int(_ram[address]),
			"motion_pointer": int(_ram[address + 1]) | (int(_ram[address + 2]) << 8),
			"appearance_pointer": int(_ram[address + 3]) | (int(_ram[address + 4]) << 8)})
	var result := {
		"ok": true, "status": "returned_to_ee9f_actor_loop", "stop_pc": 0xEEB1,
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
		"returned_to_caller": false, "returned_to_ee9f_actor_loop": true,
		"call_contract": {"dispatch": dispatch.duplicate(true), "caller_request": request.duplicate(true)},
		"ppu_bus_events": [], "ppu_cycle_timing_modeled": false, "audio_effects_modeled": false,
		"active_actor_init": {"status": "returned_to_ee9f_actor_loop", "active_animation_id": 0x8F,
			"stream_start": 0x9885, "stream_pointer_after_f0": pointer,
			"f5_operands": PackedByteArray([0x0A]), "f4_operands": PackedByteArray([0x2C, 0x0B, 0x05, 0x07]),
			"inline_append_cursor_before": _initial_append_cursor,
			"inline_append_cursor_after": int(_ram[0x0498]),
			"actor_packets_executed": 5, "actor_records": actor_records,
			"bounded_stop": "`$F0` returns from bank `$14` to `$EEB1`; `$EEB1` is not executed"}
	}
	return result


func _execute_active_actor_loop_to_caller(dispatch: Dictionary, request: Dictionary,
		seed_result: Dictionary) -> Dictionary:
	if int(_cpu.get("pc", -1)) != 0xEEB1 or int(_cpu.get("sp", -1)) != 0x28 \
			or String(seed_result.get("status", "")) != "returned_to_ee9f_actor_loop":
		return _stopped("actor_loop_entry_mismatch", int(_cpu.get("pc", 0)),
			"The live `$8F` seed prefix did not stop at `$EEB1` with its caller frame intact.")
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
		return _stopped("unsupported_actor_mode", 0xEF45,
			"The source `$062D.7` branch after actor drawing is outside this route slice.")
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
	else:
		_record(0x8000); _record(0x8003)
	return true


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
