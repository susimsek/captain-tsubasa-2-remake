extends RefCounted
class_name RomE3caNoDirectionCallExecutor
## Executes the source-derived fresh-match `$CA55->$E3CA` no-direction path.
## This is a narrow byte-checked executor, not a general 6502 emulator.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/e3ca_no_direction_call/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

const EXPECTED_SPANS := {
	"entry": {
		"file": "fixed_entry_E3CA_E3D5.bin",
		"cpu_start": "0xE3CA",
		"cpu_end_exclusive": "0xE3D6",
		"file_offset": "0x03E3DA",
		"length": 12,
		"sha256": "7100463bf16eadd91886eeb73c7afadd11972c955be5a29b99fa79d5a1afc2b1",
	},
	"return": {
		"file": "fixed_return_E406.bin",
		"cpu_start": "0xE406",
		"cpu_end_exclusive": "0xE407",
		"file_offset": "0x03E416",
		"length": 1,
		"sha256": "8d33f520a3c4cef80d2453aef81b612bfe1cb44c8b2025630ad38662763f13d3",
	},
}
const SOURCE_STARTS := {"entry": 0xE3CA, "return": 0xE406}
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const EXPECTED_EE9F_MANIFEST := "res://reference/rom_extract/gameplay/ee9f_empty_actor_call/manifest.json"
const EXPECTED_EE9F_ACTOR_INIT_MANIFEST := "res://reference/rom_extract/gameplay/ee9f_actor_init_80/manifest.json"

var error_message := ""
var _configured := false
var _source: Dictionary = {}
var _ram := PackedByteArray()
var _stack := PackedByteArray()
var _cpu: Dictionary = {}
var _mapper: Dictionary = {}
var _writes: Array[Dictionary] = []
var _instruction_pcs: Array[int] = []


## Loads only the project's hash-checked ROM-byte spans; runtime never reads the ROM file.
func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_source.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The `$E3CA` source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The `$E3CA` source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	var spans: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-e3ca-no-direction-source-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256 \
			or not spans is Array or spans.size() != EXPECTED_SPANS.size():
		return _fail("The `$E3CA` manifest targets an unsupported ROM or source schema.")
	for name_variant in EXPECTED_SPANS:
		var name := String(name_variant)
		var expected: Dictionary = EXPECTED_SPANS[name]
		var found: Dictionary = {}
		for span_variant in spans:
			if span_variant is Dictionary and String(span_variant.get("file", "")) == String(expected["file"]):
				found = span_variant
				break
		if found.is_empty():
			return _fail("The source manifest omits `%s`." % String(expected["file"]))
		for key: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			if found.get(key) != expected[key]:
				return _fail("Manifest metadata differs for `%s` field `%s`." % [String(expected["file"]), key])
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + String(expected["file"]))
		if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Source bytes failed length, hash, or manifest-byte validation: `%s`." % String(expected["file"]))
		_source[name] = bytes
	if not _verify_instruction_recipes():
		return false
	_configured = true
	return true


## Takes only an `$EE9F` source result and its actual `$CA55->$E3CA` ROM caller request.
## The result's RAM and stack are the executor's sole machine-state inputs.
func execute_from_source_call(ee9f_result: Dictionary, caller_request: Dictionary) -> Dictionary:
	if not _configured:
		return _failure("Configure the hash-checked `$E3CA` source package first.")
	var preflight := _validate_entry(ee9f_result, caller_request)
	if not bool(preflight.get("ok", false)):
		return preflight
	var source_ram: PackedByteArray = ee9f_result["ram_image"]
	var source_stack: PackedByteArray = ee9f_result["stack_page"]
	_ram = source_ram.duplicate()
	_stack = source_stack.duplicate()
	var returned_registers: Dictionary = ee9f_result["registers"]
	var source_mapper: Dictionary = ee9f_result["mapper"]
	_cpu = {
		"a": int(caller_request["a"]), "x": int(caller_request["x"]),
		"y": int(caller_request["y"]), "sp": int(caller_request["sp"]),
		"pc": 0xCA55,
		"bank_low": int(caller_request["bank_low"]),
		"bank_high": int(caller_request["bank_high"]),
		"p": int(returned_registers.get("p_known_value", 0)),
		"p_known_mask": int(returned_registers.get("p_known_mask", 0)),
	}
	_mapper = source_mapper.duplicate(true)
	_writes.clear()
	_instruction_pcs.clear()

	# Execute the caller's JSR and the supported no-direction callee branch.
	_jsr(0xCA55, 0xE3CA)
	if not _expect(0xE3CA, [0xAD, 0xFB, 0x05]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3CA)
	_set_a(int(_ram[0x05FB]))
	if not _expect(0xE3CD, [0xD0, 0x07]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3CD)
	if int(_cpu["a"]) != 0:
		_cpu["pc"] = 0xE3D6
		return _stopped("unsupported_nonfresh_match_branch", 0xE3D6,
			"`$05FB` is nonzero; the alternate `$E3D6` branch is outside this source slice.")

	if not _expect(0xE3CF, [0xAD, 0x1C, 0x00]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3CF)
	_set_a(int(_ram[0x001C]))
	if not _expect(0xE3D2, [0x29, 0x0F]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3D2)
	_set_a(int(_cpu["a"]) & 0x0F)
	if not _expect(0xE3D4, [0xF0, 0x30]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE3D4)
	if int(_cpu["a"]) != 0:
		_cpu["pc"] = 0xE3D6
		return _stopped("unsupported_directional_input", 0xE3D6,
			"`$001C & $0F` is nonzero; movement and the `$E3D6` path are not implemented.",
			{"controller_value": int(_ram[0x001C]), "masked_direction_bits": int(_cpu["a"])})
	var branch_target := 0xE3D6 + _signed_byte(0x30)
	if branch_target != 0xE406:
		return _stopped("source_state_uncertainty", 0xE3D4,
			"ROM-derived BEQ displacement no longer resolves to `$E406`.")
	_cpu["pc"] = branch_target
	if not _expect(0xE406, [0x60]):
		return _stopped("unsupported_source_opcode", int(_cpu["pc"]), error_message)
	_record(0xE406)
	_rts(0xE406)
	if int(_cpu["pc"]) != 0xCA58 or int(_cpu["sp"]) != 0x2A:
		return _stopped("source_state_uncertainty", int(_cpu["pc"]),
			"`$E3CA` RTS did not restore caller PC `$CA58` and SP `$2A`.")
	return {
		"ok": true,
		"status": "returned_to_source_caller",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry": {"slot_base": 0x01, "call_pc": 0xCA55, "target_pc": 0xE3CA,
			"expected_return_pc": 0xCA58,
			"source": "ROM-byte `$EE9F` return state and root caller's `$CA55->$E3CA` request"},
		"registers": _register_snapshot(),
		"mapper": _mapper.duplicate(true),
		"ram_image": _ram.duplicate(),
		"stack_page": _stack.duplicate(),
		"memory_writes": _writes.duplicate(true),
		"instruction_pcs": _instruction_pcs.duplicate(),
		"instruction_count": _instruction_pcs.size(),
		"returned_to_caller": true,
		"movement_applied": false,
		"field_input_branch": "no_direction",
		"ppu_bus_events": [],
		"ppu_cycle_timing_modeled": false,
		"audio_effects_modeled": false,
	}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"supports_only_fresh_no_direction_branch": true,
		"executes_general_6502": false,
		"reads_supplied_rom_at_runtime": false,
		"reads_trace_ram_or_images": false,
	}


func _validate_entry(ee9f_result: Dictionary, caller_request: Dictionary) -> Dictionary:
	var ee9f_manifest := String(ee9f_result.get("source_manifest", ""))
	var has_live_actor_init := ee9f_manifest == EXPECTED_EE9F_ACTOR_INIT_MANIFEST
	var actor_init_status := ""
	if not bool(ee9f_result.get("ok", false)) \
			or (ee9f_manifest != EXPECTED_EE9F_MANIFEST and not has_live_actor_init) \
			or not bool(ee9f_result.get("returned_to_caller", false)):
		return _failure("Input is not the successful ROM-derived `$EE9F` call result.")
	if has_live_actor_init:
		var actor_init_variant: Variant = ee9f_result.get("active_actor_init", {})
		if not actor_init_variant is Dictionary:
			return _failure("The `$053A=$80` `$EE9F` result omits its actor-init provenance.")
		var actor_init: Dictionary = actor_init_variant
		actor_init_status = String(actor_init.get("status", ""))
		if actor_init_status == "returned_to_ee9f_actor_loop":
			var animation_id := int(actor_init.get("active_animation_id", -1))
			var expected_seed: Dictionary = {
				0x00: {"stream_start": 0x8B48, "stream_pointer_after_f0": 0x8B5B,
					"actor_packets_executed": 0},
				0x8F: {"stream_start": 0x9885, "stream_pointer_after_f0": 0x98AA,
					"actor_packets_executed": 5},
				0x90: {"stream_start": 0x98AB, "stream_pointer_after_f0": 0x98C4,
					"actor_packets_executed": 3},
				0x8B: {"stream_start": 0x9827, "stream_pointer_after_f0": 0x9834,
					"actor_packets_executed": 1},
				0x5C: {"stream_start": 0x9357, "stream_pointer_after_f0": 0x9370,
					"actor_packets_executed": 3},
				0x4E: {"stream_start": 0x9261, "stream_pointer_after_f0": 0x926E,
					"actor_packets_executed": 1},
				0x66: {"stream_start": 0x9441, "stream_pointer_after_f0": 0x9455,
					"actor_packets_executed": 1},
				0x4C: {"stream_start": 0x9245, "stream_pointer_after_f0": 0x9252,
					"actor_packets_executed": 1},
				0xE6: {"stream_start": 0x9618, "stream_pointer_after_f0": 0x9650,
					"active_stream_id": 0x78, "actor_packets_executed": 1},
				0x78: {"stream_start": 0x9618, "stream_pointer_after_f0": 0x9650,
					"active_stream_id": 0x78, "actor_packets_executed": 1},
				0x7A: {"stream_start": 0x965F, "stream_pointer_after_f0": 0x9688,
					"active_stream_id": 0x7A, "actor_packets_executed": 2},
			}.get(animation_id, {})
			if expected_seed.is_empty():
				return _failure("The `$053A=$80` `$EE9F` result uses unsupported animation `$%02X`." % animation_id)
			for field: String in expected_seed:
				if int(actor_init.get(field, -1)) != int(expected_seed[field]):
					return _failure("The `$053A=$80` `$EE9F` animation `$%02X` seed field `%s` does not match its ROM stream." % [animation_id, field])
			if animation_id == 0x00 \
					and (int(actor_init.get("active_stream_id", -1)) != 0x00 \
					or actor_init.get("f5_operands", PackedByteArray()) != PackedByteArray([0x0B]) \
					or actor_init.get("f4_operands", PackedByteArray()) != PackedByteArray([0x1F, 0x00, 0x00, 0x00]) \
					or not (actor_init.get("actor_records", []) as Array).is_empty()):
				return _failure("The live animation-$00 actor-loop result differs from the checked F5/F4/F6/F0 source profile.")
			if animation_id == 0x8B:
				var actor_records_variant: Variant = actor_init.get("actor_records", [])
				if not actor_records_variant is Array or (actor_records_variant as Array).size() != 1 \
						or int(actor_init.get("active_stream_id", -1)) != 0x8B \
						or actor_init.get("f5_operands", PackedByteArray()) != PackedByteArray([0x80]) \
						or actor_init.get("f4_operands", PackedByteArray()) != PackedByteArray([0x20, 0x21, 0x00, 0x00]):
					return _failure("The scenario-$2E animation-$8B result differs from its source F5/F4/F1/F0 stream.")
				var actor_record_variant: Variant = (actor_records_variant as Array)[0]
				if not actor_record_variant is Dictionary:
					return _failure("The scenario-$2E animation-$8B actor record is malformed.")
				var actor_record: Dictionary = actor_record_variant
				if int(actor_record.get("actor_index", -1)) != 0 \
						or int(actor_record.get("cpu_address", -1)) != 0x0547 \
						or int(actor_record.get("active_flags", -1)) != 0x81 \
						or int(actor_record.get("motion_pointer", -1)) != 0xA38A \
						or int(actor_record.get("appearance_pointer", -1)) != 0xB30A:
					return _failure("The scenario-$2E animation-$8B record does not match its ROM F1 pointer-table resolution.")
			if animation_id == 0x7A \
					and (actor_init.get("f5_operands", PackedByteArray()) != PackedByteArray([0x80]) \
					or actor_init.get("f4_operands", PackedByteArray()) != PackedByteArray([0x0C, 0x0D, 0x0E, 0x0F])):
				return _failure("The scenario-$1C animation-$7A result differs from its source F5/F4/F1/F0 stream.")
		elif actor_init_status == "returned_to_source_caller":
			# Scenario-$38 animation $00 has F5/F4/F6/F0 only. Its F0
			# discards the animation dispatch frames and returns straight to $CA55.
			if int(actor_init.get("active_animation_id", -1)) != 0x00 \
					or int(actor_init.get("active_stream_id", -1)) != 0x00 \
					or int(actor_init.get("stream_start", -1)) != 0x8B48 \
					or int(actor_init.get("stream_pointer_after_f0", -1)) != 0x8B5B \
					or int(actor_init.get("actor_packets_executed", -1)) != 0 \
					or actor_init.get("f5_operands", PackedByteArray()) != PackedByteArray([0x0B]) \
					or actor_init.get("f4_operands", PackedByteArray()) != PackedByteArray([0x1F, 0x00, 0x00, 0x00]) \
					or not (actor_init.get("actor_records", []) as Array).is_empty():
				return _failure("The direct `$EE9F->$CA55` result is not the checked scenario-$38 animation-$00 F5/F4/F6/F0 return.")
		elif actor_init_status == "waiting_for_source_animation_ticks":
			var pending_animation_id := int(actor_init.get("active_animation_id", -1))
			var pending_stream_start := int(actor_init.get("stream_start", -1))
			var pending_stream_pointer := int(actor_init.get("stream_pointer_after_current_call", -1))
			var valid_66_wait := pending_animation_id == 0x66 \
					and pending_stream_start == 0x9441 and pending_stream_pointer == 0x944F
			var valid_e6_wait := pending_animation_id == 0xE6 \
					and pending_stream_start == 0x9618 \
					and pending_stream_pointer in [0x9638, 0x964A]
			var valid_78_wait := pending_animation_id == 0x78 \
					and pending_stream_start == 0x9618 \
					and pending_stream_pointer in [0x9638, 0x964A]
			var valid_7a_wait := pending_animation_id == 0x7A \
					and pending_stream_start == 0x965F \
					and pending_stream_pointer in [0x9673, 0x967C]
			if not valid_66_wait and not valid_e6_wait and not valid_78_wait and not valid_7a_wait:
				return _failure("The pending actor-animation result does not match a checked `$66`, `$78`, `$7A`, or `$E6` wait boundary.")
		elif actor_init_status == "existing_actor_state":
			if int(actor_init.get("continuation_from", -1)) != 0xEEFD \
					or String(actor_init.get("source", "")) != "live actor record at the `$EEFD` continuation":
				return _failure("The `$EE9F` result omits provenance for its existing active-actor continuation.")
		elif actor_init_status == "field_marker_mode_one":
			if int(actor_init.get("marker_mode", -1)) != 1 \
					or int(actor_init.get("mode_value", -1)) != 0x81 \
					or int(actor_init.get("source_stop_pc", -1)) != 0xEF45 \
					or int(actor_init.get("renderer_entry_pc", -1)) != 0x8624 \
					or int(actor_init.get("mode_dispatch_target", -1)) != 0x8768 \
					or int(actor_init.get("position_vector_pc", -1)) != 0xC536 \
					or int(actor_init.get("position_helper_pc", -1)) != 0xCDC9 \
					or int(actor_init.get("oam_writer_pc", -1)) != 0x87E7 \
					or int(actor_init.get("oam_writer_return_pc", -1)) != 0x8633 \
					or int(actor_init.get("actor_loop_return_pc", -1)) != 0xEF57 \
					or bool(actor_init.get("trace_state_used", true)):
				return _failure("The empty-actor source result omits the ROM mode-one field-marker path provenance.")
		else:
			return _failure("The `$EE9F` result has an unsupported actor-state provenance.")
	var entry_variant: Variant = ee9f_result.get("entry", {})
	var registers_variant: Variant = ee9f_result.get("registers", {})
	var mapper_variant: Variant = ee9f_result.get("mapper", {})
	var ram_variant: Variant = ee9f_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = ee9f_result.get("stack_page", PackedByteArray())
	if not entry_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _failure("`$EE9F` result omits its source return, registers, mapper, RAM, or stack state.")
	var entry: Dictionary = entry_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram_image: PackedByteArray = ram_variant
	var stack_page: PackedByteArray = stack_variant
	if String(entry.get("source", "")) != "live slot-$01 scheduler dispatch and RAM/stack snapshot" \
			or int(entry.get("slot_base", -1)) != 0x01 \
			or int(entry.get("call_pc", -1)) != 0xCA52 \
			or int(entry.get("target_pc", -1)) != 0xEE9F \
			or int(entry.get("expected_return_pc", -1)) != 0xCA55 \
			or int(registers.get("pc", -1)) != 0xCA55 \
			or int(registers.get("sp", -1)) != 0x2A \
			or int(registers.get("a", -1)) != 0xF8 \
			or (int(registers.get("p_known_mask", -1)) & 0xC3) != 0xC3 \
			or (int(registers.get("p_known_value", -1)) & 0xC3) != 0x03 \
			or int(mapper.get("task_bank_low", -1)) != 0x00 \
			or int(mapper.get("task_bank_high", -1)) != 0x01:
		var returned_boundary := {
			"entry_source": entry.get("source", ""),
			"slot_base": entry.get("slot_base", -1),
			"call_pc": entry.get("call_pc", -1),
			"target_pc": entry.get("target_pc", -1),
			"return_pc": entry.get("expected_return_pc", -1),
			"pc": registers.get("pc", -1), "sp": registers.get("sp", -1),
			"a": registers.get("a", -1), "x": registers.get("x", -1),
			"y": registers.get("y", -1), "p": registers.get("p", -1),
			"p_known_mask": registers.get("p_known_mask", -1),
			"p_known_value": registers.get("p_known_value", -1),
			"task_bank_low": mapper.get("task_bank_low", -1),
			"task_bank_high": mapper.get("task_bank_high", -1),
		}
		return _failure("`$EE9F` returned state does not match the live fresh-route caller boundary: %s" % JSON.stringify(returned_boundary))
	if ram_image.size() != RAM_SIZE or stack_page.size() != STACK_SIZE:
		return _failure("`$EE9F` return must contain a 2 KiB CPU RAM image and 256-byte stack page.")
	for stack_offset in range(STACK_SIZE):
		if int(ram_image[0x0100 + stack_offset]) != int(stack_page[stack_offset]):
			return _failure("`$EE9F` RAM and stack-page mirrors disagree at `$%02X`." % stack_offset)
	if int(ram_image[0x05FB]) != 0 or (int(ram_image[0x001C]) & 0x0F) != 0:
		return _failure("Live `$EE9F` state does not satisfy the ROM-observed fresh/no-direction branch.")
	if has_live_actor_init and actor_init_status != "field_marker_mode_one":
		var oam_cursor := int(ram_image[0x003B])
		var sprite_count := int(ram_image[0x0048])
		var actor_init: Dictionary = ee9f_result["active_actor_init"]
		var active_animation_id := int(actor_init.get("active_animation_id", -1))
		var actor_state_mismatches: Array[String] = []
		var animation_is_waiting := actor_init_status == "waiting_for_source_animation_ticks"
		var expected_stream_pointer := int(actor_init.get("stream_pointer_after_current_call",
			actor_init.get("stream_pointer_after_f0", -1)))
		if String(actor_init.get("status", "")) == "existing_actor_state":
			active_animation_id = int(ram_image[0x053C])
			if active_animation_id == 0x8F:
				expected_stream_pointer = 0x98AA
			elif active_animation_id == 0x8B:
				expected_stream_pointer = 0x9834
			elif active_animation_id == 0x90:
				# The checked scenario-$1E lineup stream ends at `$F0` `$98C3`; the
				# live actor loop preserves the cursor immediately after it.
				expected_stream_pointer = 0x98C4
			elif active_animation_id == 0x5C:
				# Scenario-$44's checked three-packet stream ends at `$F0` `$9370`.
				expected_stream_pointer = 0x9370
			elif active_animation_id == 0x4E:
				# The checked animation-$4E stream runs from $9261 through its $F0
				# command at $926E; the live actor loop preserves that ROM pointer.
				expected_stream_pointer = 0x926E
			elif active_animation_id == 0x66:
				# The checked animation-$66 stream ends at $9455 after its $F0
				# command; the live actor loop preserves that source cursor.
				expected_stream_pointer = 0x9455
			elif active_animation_id == 0x4C:
				# Scenario-$36 animation-$4C ends at $9252 after its source $F0.
				expected_stream_pointer = 0x9252
			elif active_animation_id == 0xE6:
				# Scenario-$36's one-packet animation reaches its source $F0 at $9650.
				expected_stream_pointer = 0x9650
			elif active_animation_id == 0x78:
				# Scenario-$1C selects this ROM stream directly and it terminates at $9650.
				expected_stream_pointer = 0x9650
			elif active_animation_id == 0x7A:
				# Scenario-$1C's two-actor stream has already executed its terminal $F0 at $9687.
				expected_stream_pointer = 0x9688
		var expected_animation_id := active_animation_id
		if active_animation_id != 0x00 and active_animation_id != 0x8F and active_animation_id != 0x90 and active_animation_id != 0x8B and active_animation_id != 0x5C \
				and active_animation_id != 0x4E \
				and active_animation_id != 0x66 and active_animation_id != 0x4C \
				and active_animation_id != 0x7A and active_animation_id != 0xE6 and active_animation_id != 0x78:
			actor_state_mismatches.append("unsupported seed animation $%02X" % active_animation_id)
		var expected_animation_active := 1 if animation_is_waiting else 0
		var max_wait_ticks := 6
		if active_animation_id == 0xE6 or active_animation_id == 0x78:
			max_wait_ticks = 0x14 if int(actor_init.get("stream_pointer_after_current_call", -1)) == 0x9638 else 2
		elif active_animation_id == 0x7A:
			max_wait_ticks = 0x14 if expected_stream_pointer == 0x9673 else 0x04
		var countdown_valid := int(ram_image[0x053B]) >= 1 and int(ram_image[0x053B]) <= max_wait_ticks \
			if animation_is_waiting else int(ram_image[0x053B]) == 0
		if int(ram_image[0x053A]) != expected_animation_active or not countdown_valid \
				or int(ram_image[0x053C]) != expected_animation_id or int(ram_image[0x053D]) != 0:
			actor_state_mismatches.append("active animation fields $053A-$053D=%s do not match active=%d countdown-valid=%s ID=$%02X" % [
				ram_image.slice(0x053A, 0x053E).hex_encode(), expected_animation_active,
				str(countdown_valid), expected_animation_id])
		var expected_selectors := PackedByteArray([0x2C, 0x0B, 0x05, 0x07])
		if active_animation_id == 0x00:
			expected_selectors = PackedByteArray([0x1F, 0x00, 0x00, 0x00])
		elif active_animation_id == 0x66:
			expected_selectors = PackedByteArray([0x04, 0x05, 0x22, 0x00])
		elif active_animation_id == 0x90 or active_animation_id == 0x5C:
			expected_selectors = PackedByteArray([0x08, 0x09, 0x0A, 0x0B])
		elif active_animation_id == 0x8B:
			expected_selectors = PackedByteArray([0x20, 0x21, 0x00, 0x00])
		elif active_animation_id == 0x4C:
			expected_selectors = PackedByteArray([0x04, 0x05, 0x00, 0x00])
		elif active_animation_id == 0x7A:
			expected_selectors = PackedByteArray([0x0C, 0x0D, 0x0E, 0x0F])
		elif active_animation_id == 0xE6 or active_animation_id == 0x78:
			expected_selectors = PackedByteArray([0x0A, 0x0B, 0x00, 0x00]) \
				if expected_stream_pointer in [0x964A, 0x9650] else PackedByteArray([0x08, 0x09, 0x0A, 0x0B])
		if ram_image.slice(0x0494, 0x0498) != expected_selectors:
			actor_state_mismatches.append("F4 packet=%s expected %s" % [
				ram_image.slice(0x0494, 0x0498).hex_encode(), expected_selectors.hex_encode()])
		if int(ram_image[0x004C]) != (expected_stream_pointer & 0xFF) \
				or int(ram_image[0x004D]) != (expected_stream_pointer >> 8):
			actor_state_mismatches.append("stream pointer=$%04X expected $%04X" % [
				int(ram_image[0x004C]) | (int(ram_image[0x004D]) << 8), expected_stream_pointer])
		if active_animation_id == 0x8F:
			if expected_stream_pointer != 0x98AA or int(ram_image[0x003A]) != 6:
				actor_state_mismatches.append("$8F seed metadata/passes=$%04X/%02X" % [expected_stream_pointer, int(ram_image[0x003A])])
		elif active_animation_id == 0x4E:
			if expected_stream_pointer != 0x926E:
				actor_state_mismatches.append("$4E seed metadata pointer=$%04X expected $926E" % expected_stream_pointer)
		elif active_animation_id == 0x8B:
			var expected_8b_append_cursor := 1 if actor_init_status == "returned_to_ee9f_actor_loop" else 0
			if expected_stream_pointer != 0x9834 or int(ram_image[0x0498]) != expected_8b_append_cursor:
				actor_state_mismatches.append("$8B stream metadata pointer/count=$%04X/%02X expected $9834/%02X" % [
					expected_stream_pointer, int(ram_image[0x0498]), expected_8b_append_cursor])
		elif active_animation_id == 0x90:
			if expected_stream_pointer != 0x98C4:
				actor_state_mismatches.append("$90 seed metadata pointer=$%04X expected $98C4" % expected_stream_pointer)
		elif active_animation_id == 0x5C:
			if expected_stream_pointer != 0x9370:
				actor_state_mismatches.append("$5C seed metadata pointer=$%04X expected $9370" % expected_stream_pointer)
		elif active_animation_id == 0x66:
			var expected_66_pointer := 0x944F if animation_is_waiting else 0x9455
			if expected_stream_pointer != expected_66_pointer:
				actor_state_mismatches.append("$66 stream pointer=$%04X expected $%04X" % [expected_stream_pointer, expected_66_pointer])
		elif active_animation_id == 0x4C:
			if expected_stream_pointer != 0x9252:
				actor_state_mismatches.append("$4C stream pointer=$%04X expected $9252" % expected_stream_pointer)
		elif active_animation_id == 0xE6 or active_animation_id == 0x78:
			var valid_e6_pointer := expected_stream_pointer == 0x9650 if not animation_is_waiting \
				else expected_stream_pointer == 0x9638 or expected_stream_pointer == 0x964A
			if not valid_e6_pointer:
				actor_state_mismatches.append("$%02X stream pointer=$%04X is outside its checked wait/end addresses" % [active_animation_id, expected_stream_pointer])
		elif active_animation_id == 0x7A:
			var completed_7a := not animation_is_waiting \
				and expected_stream_pointer == 0x9688 \
				and actor_init_status in ["returned_to_ee9f_actor_loop", "existing_actor_state"]
			if not completed_7a and (not animation_is_waiting \
					or expected_stream_pointer not in [0x9673, 0x967C]):
				actor_state_mismatches.append("$7A stream pointer=$%04X is outside its two checked waits and terminal" % expected_stream_pointer)
			# The initial $9673 wait appends one queue record. Countdown resumes
			# keep the cursor at zero; the terminal $9688 return has consumed its
			# two ROM F1 packets and leaves both source actors active.
			var initial_9673_emission := animation_is_waiting \
				and expected_stream_pointer == 0x9673 and int(ram_image[0x053B]) == 0x14
			var expected_append_cursor := 1 if initial_9673_emission else 0
			var expected_actor0_flag := 0x80 if completed_7a or expected_stream_pointer == 0x9673 else 0x00
			if int(ram_image[0x0498]) != expected_append_cursor \
					or (int(ram_image[0x0547]) & 0x80) != expected_actor0_flag \
					or (int(ram_image[0x055C]) & 0x80) != 0x80:
				actor_state_mismatches.append("$7A wait/terminal side effects disagree at cursor=$%04X, append=$%02X, actor flags=$%02X/$%02X" % [
					expected_stream_pointer, int(ram_image[0x0498]),
					int(ram_image[0x0547]) & 0x80, int(ram_image[0x055C]) & 0x80])
		if oam_cursor > 0x100 or (oam_cursor & 0x03) != 0:
			actor_state_mismatches.append("OAM cursor=$%02X is outside aligned OAM range" % oam_cursor)
		if sprite_count != oam_cursor / 4:
			actor_state_mismatches.append("OAM sprite count=%d disagrees with cursor=%d" % [sprite_count, oam_cursor])
		if not actor_state_mismatches.is_empty():
			var state_summary := PackedByteArray([
				int(ram_image[0x053A]), int(ram_image[0x053B]),
				int(ram_image[0x053C]), int(ram_image[0x053D]),
				int(ram_image[0x004C]), int(ram_image[0x004D]),
				int(ram_image[0x003A]), int(ram_image[0x003B]),
				int(ram_image[0x0048]), int(ram_image[0x0547]),
				int(ram_image[0x055C]), int(ram_image[0x0571]),
				int(ram_image[0x0586]), int(ram_image[0x059B]),
				int(ram_image[0x05B0]),
			])
			return _failure("Live `$EE9F` actor state mismatch: %s; fields `$053A-$053D,$004C-$004D,$003A,$003B,$0048,record flags` = %s; packet=`%s`." % [
				"; ".join(actor_state_mismatches), state_summary.hex_encode(), ram_image.slice(0x0494, 0x0498).hex_encode()])
		if active_animation_id == 0x8F:
			var expected_actor_flags: Array[int] = [0x81, 0x81, 0x80, 0x80, 0x80, 0x00]
			for actor_index in range(expected_actor_flags.size()):
				var returned_flags := int(ram_image[0x0547 + actor_index * 0x15])
				if (returned_flags & 0x80) != (expected_actor_flags[actor_index] & 0x80):
					return _failure("The ROM `$F1` actor at index %d has returned active bit `$%02X`; expected `$%02X`." % [
						actor_index, returned_flags & 0x80, expected_actor_flags[actor_index] & 0x80])
		if active_animation_id == 0x90:
			var expected_actor_flags_90: Array[int] = [0x81, 0x81, 0x81, 0x00, 0x00, 0x00]
			for actor_index in range(expected_actor_flags_90.size()):
				var returned_flags_90 := int(ram_image[0x0547 + actor_index * 0x15])
				if (returned_flags_90 & 0x80) != (expected_actor_flags_90[actor_index] & 0x80):
					return _failure("The ROM `$90` actor at index %d has returned active bit `$%02X`; expected `$%02X`." % [
						actor_index, returned_flags_90 & 0x80, expected_actor_flags_90[actor_index] & 0x80])
		if active_animation_id == 0x5C:
			var expected_actor_flags_5c: Array[int] = [0x81, 0x81, 0x00, 0x81, 0x00, 0x00]
			for actor_index in range(expected_actor_flags_5c.size()):
				var returned_flags_5c := int(ram_image[0x0547 + actor_index * 0x15])
				if (returned_flags_5c & 0x80) != (expected_actor_flags_5c[actor_index] & 0x80):
					return _failure("The ROM `$5C` actor at index %d has returned active bit `$%02X`; expected `$%02X`." % [
						actor_index, returned_flags_5c & 0x80, expected_actor_flags_5c[actor_index] & 0x80])
		if active_animation_id == 0x00:
			for actor_index in range(6):
				var returned_flags_00 := int(ram_image[0x0547 + actor_index * 0x15])
				if returned_flags_00 != 0:
					return _failure("ROM animation `$00` F6 removal left actor record %d flags at `$%02X`; expected `$00`." % [
						actor_index, returned_flags_00])
	if has_live_actor_init and actor_init_status == "field_marker_mode_one":
		var actor_init: Dictionary = ee9f_result["active_actor_init"]
		var marker_resume: Dictionary = ee9f_result.get("empty_actor_marker_resume", {})
		var actor_loop: Dictionary = ee9f_result.get("actor_loop", {})
		var actor_visits: Array = ee9f_result.get("actor_visits", [])
		var actor_records: Array = ee9f_result.get("actor_records", [])
		var oam_cursor := int(ram_image[0x003B])
		var sprite_count := int(ram_image[0x0048])
		if int(ram_image[0x062D]) != 0x81 \
				or int(actor_init.get("cursor_tile", -1)) != int(ram_image[0x0624]) \
				or int(marker_resume.get("mode_dispatch_target", -1)) != 0x8768 \
				or int(marker_resume.get("oam_writer_return_pc", -1)) != 0x8633 \
				or int(marker_resume.get("actor_loop_return_pc", -1)) != 0xEF57 \
				or actor_loop.is_empty() or int(actor_loop.get("active_actor_count", -1)) != 0 \
				or actor_visits.size() != 6 or actor_records.size() != 6 \
				or int(ram_image[0x0532]) != 1 \
				or oam_cursor > 0x100 or (oam_cursor & 0x03) != 0 \
				or sprite_count != oam_cursor / 4:
			return _failure("Live mode-one field-marker state does not match its ROM `$EF45->$8768->$87E7->$8633` path.")
		for actor_index in range(6):
			var visit_variant: Variant = actor_visits[actor_index]
			var record_variant: Variant = actor_records[actor_index]
			if not visit_variant is Dictionary or not record_variant is Dictionary:
				return _failure("The mode-one marker result omits an ordered ROM actor record.")
			var visit: Dictionary = visit_variant
			var record: Dictionary = record_variant
			if int(visit.get("ordinal", -1)) != actor_index \
					or int(visit.get("actor_index", -1)) != actor_index \
					or not bool(visit.get("inactive", false)) \
					or int(record.get("actor_index", -1)) != actor_index \
					or int(record.get("cpu_address", -1)) != 0x0547 + actor_index * 0x15 \
					or (int(record.get("active_flags", 0)) & 0x80) != 0:
				return _failure("The source mode-one marker loop did not preserve the six inactive actor records in ROM order.")
	if not bool(caller_request.get("ok", false)) \
			or String(caller_request.get("status", "")) != "call_requested" \
			or int(caller_request.get("slot_base", -1)) != 0x01 \
			or int(caller_request.get("source_pc", -1)) != 0xCA55 \
			or int(caller_request.get("target_cpu_address", -1)) != 0xE3CA \
			or int(caller_request.get("expected_return_pc", -1)) != 0xCA58 \
			or int(caller_request.get("call_ordinal", -1)) != 1 \
			or int(caller_request.get("a", -1)) != int(registers.get("a", -2)) \
			or int(caller_request.get("x", -1)) != int(registers.get("x", -2)) \
			or int(caller_request.get("y", -1)) != int(registers.get("y", -2)) \
			or int(caller_request.get("sp", -1)) != int(registers.get("sp", -2)) \
			or int(caller_request.get("bank_low", -1)) != int(registers.get("bank_low", -2)) \
			or int(caller_request.get("bank_high", -1)) != int(registers.get("bank_high", -2)):
		return _failure("Caller request is not the exact ROM-owned `$CA55->$E3CA` second call.")
	return {"ok": true}


func _verify_instruction_recipes() -> bool:
	if _source_byte("entry", 0xE3CA) != 0xAD or _source_byte("entry", 0xE3CD) != 0xD0 \
			or _source_byte("entry", 0xE3CF) != 0xAD or _source_byte("entry", 0xE3D2) != 0x29 \
			or _source_byte("entry", 0xE3D4) != 0xF0 or _source_byte("return", 0xE406) != 0x60:
		return _fail("ROM source bytes do not match the documented `$E3CA` no-direction recipe.")
	return true


func _expect(cpu_address: int, expected: Array[int]) -> bool:
	var source_name := "entry" if cpu_address < 0xE406 else "return"
	for offset in range(expected.size()):
		if _source_byte(source_name, cpu_address + offset) != expected[offset]:
			return _set_error("Unsupported `$E3CA` source byte at `$%04X` (expected `$%02X`)." % [cpu_address + offset, expected[offset]])
	return true


func _source_byte(name: String, cpu_address: int) -> int:
	var bytes: PackedByteArray = _source.get(name, PackedByteArray())
	var start := int(SOURCE_STARTS.get(name, -1))
	var offset := cpu_address - start
	if offset < 0 or offset >= bytes.size():
		return -1
	return int(bytes[offset])


func _signed_byte(value: int) -> int:
	return value - 0x100 if value >= 0x80 else value


func _jsr(call_pc: int, target: int) -> void:
	_record(call_pc)
	var return_address := call_pc + 2
	_push((return_address >> 8) & 0xFF, call_pc)
	_push(return_address & 0xFF, call_pc)
	_cpu["pc"] = target


func _rts(pc: int) -> void:
	var low := _pop(pc)
	var high := _pop(pc)
	_cpu["pc"] = (((high << 8) | low) + 1) & 0xFFFF


func _push(value: int, pc: int) -> void:
	var sp := int(_cpu["sp"]) & 0xFF
	_write_ram(0x0100 + sp, value, pc)
	_cpu["sp"] = (sp - 1) & 0xFF


func _pop(_pc: int) -> int:
	var sp := (int(_cpu["sp"]) + 1) & 0xFF
	_cpu["sp"] = sp
	return int(_ram[0x0100 + sp])


func _write_ram(address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	_ram[address] = byte_value
	if address >= 0x0100 and address < 0x0200:
		_stack[address & 0xFF] = byte_value
	_writes.append({"space": "cpu_ram", "address": address, "value": byte_value, "pc": pc})


func _set_a(value: int) -> void:
	_cpu["a"] = value & 0xFF
	_set_nz(int(_cpu["a"]))


func _set_nz(value: int) -> void:
	var flags := int(_cpu.get("p", 0)) & 0xFF
	flags &= ~0x82
	if (value & 0x80) != 0:
		flags |= 0x80
	if (value & 0xFF) == 0:
		flags |= 0x02
	_cpu["p"] = flags


func _record(cpu_address: int) -> void:
	_instruction_pcs.append(cpu_address)
	_cpu["pc"] = cpu_address


func _register_snapshot() -> Dictionary:
	var registers := _cpu.duplicate(true)
	var known_mask := int(_cpu.get("p_known_mask", 0)) & 0xFF
	registers.erase("p")
	registers["p_known_value"] = int(_cpu.get("p", 0)) & known_mask
	registers["p_known_mask"] = known_mask
	registers["p_unknown_mask"] = (~known_mask) & 0xFF
	return registers


func _stopped(status: String, stop_pc: int, reason: String,
		detail: Dictionary = {}) -> Dictionary:
	_cpu["pc"] = stop_pc
	return {
		"ok": false,
		"status": status,
		"stop_pc": stop_pc,
		"reason": reason,
		"partial_state": {"registers": _register_snapshot(), "mapper": _mapper.duplicate(true),
			"ram_image": _ram.duplicate(), "stack_page": _stack.duplicate(),
			"memory_writes": _writes.duplicate(true), "instruction_pcs": _instruction_pcs.duplicate()},
		"detail": detail,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
	}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "rejected_entry_state", "error": message}


func _set_error(message: String) -> bool:
	error_message = message
	return false


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()
