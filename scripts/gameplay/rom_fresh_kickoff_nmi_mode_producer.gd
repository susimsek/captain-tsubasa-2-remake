extends RefCounted
class_name RomFreshKickoffNmiModeProducer
## Derives the cold-start `$001B.6` mode write from the checked ROM setup path.
## This bounded source receipt does not claim to execute the full boot route.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const BOOT_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_1b6_boot_producer_20261029/"
const BOOT_MANIFEST := BOOT_ROOT + "manifest.json"
const MODE_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_audio_wait_inputs_20261029/"
const MODE_MANIFEST := MODE_ROOT + "manifest.json"
const CALLER_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_caller/"
const CALLER_MANIFEST := CALLER_ROOT + "manifest.json"
const WAIT_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/"
const WAIT_MANIFEST := WAIT_ROOT + "manifest.json"
const MODE_MASK := 0x40
const ROUTE_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const SOURCE_STEPPER_SHA256 := "233a721c91b17b56e3527bfc336ab47d020186b44a7da15f322224aa674e493a"
const SOURCE_SCHEDULE_BUILDER_SHA256 := "2b9e1acbb15d19dc51ddf85820c32929e4e52d0078211f9e07eb459d143140f5"

const EXPECTED_SPANS := {
	"fixed_setup_helper_CEFE_CF1F.bin": {
		"root": BOOT_ROOT, "start": "0xCEFE", "end": "0xCF1F", "offset": "0x03CF0E",
		"length": 33, "sha256": "39e08d07dea9aaecf0e7e69a5f29bfb673b8d682387c78a8ee3a70c699bde5e7",
	},
	"fixed_mapper_wrapper_C400_C41E.bin": {
		"root": BOOT_ROOT, "start": "0xC400", "end": "0xC41E", "offset": "0x03C410",
		"length": 30, "sha256": "b202c40966101d2332de8c9ac85dac12ad69665579e933455b8572760f91292d",
	},
	"fixed_reset_tail_C67A_C6BE.bin": {
		"root": BOOT_ROOT, "start": "0xC67A", "end": "0xC6BE", "offset": "0x03C68A",
		"length": 68, "sha256": "67b813ea10823b567758336a7dc96e3eca11d6800ea7d6c6e2186076e8e3d3d4",
	},
	"fixed_C41E_mode_dispatch_bridge.bin": {
		"root": MODE_ROOT, "start": "0xC41E", "end": "0xC421", "offset": "0x03C42E",
		"length": 3, "sha256": "c36deaf930bda84f02962a47f1dab95b08c06d433abbc79b975a54b4db604363",
	},
	"bank02_mode_setter_dispatch_A200_A22A.bin": {
		"root": MODE_ROOT, "start": "0xA200", "end": "0xA22A", "offset": "0x004210",
		"length": 42, "sha256": "3f4ddbdf38609b69daaadfcae493258520ebc3563925d5137eb14efd9c02fa5a",
	},
	"fixed_mapper_select_C4B9_C4C7.bin": {
		"root": CALLER_ROOT, "start": "$C4B9", "end": "$C4C8", "offset": "0x03C4C9",
		"length": 15, "sha256": "a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12",
	},
	"fixed_ready_latch_clear_9F04_9F0C.bin": {
		"root": MODE_ROOT, "start": "0x9F04", "end": "0x9F0C", "offset": "0x001F14",
		"length": 8, "sha256": "6d9092a528c7998a0aa7a304ee551b15472319037b947d3f77de333592635cb3",
	},
}

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	for pair in [[BOOT_MANIFEST, BOOT_ROOT], [MODE_MANIFEST, MODE_ROOT], [CALLER_MANIFEST, CALLER_ROOT]]:
		var manifest_path := String(pair[0])
		if not FileAccess.file_exists(manifest_path):
			return _fail("NMI mode producer source manifest is missing: " + manifest_path)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not parsed is Dictionary:
			return _fail("NMI mode producer source manifest is malformed.")
		var document: Dictionary = parsed
		var rom: Variant = document.get("rom", {})
		if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
			return _fail("NMI mode producer manifest targets a different ROM revision.")
		for span_variant in document.get("spans", []):
			if not span_variant is Dictionary:
				continue
			var span: Dictionary = span_variant
			var file_name := String(span.get("file", ""))
			if not EXPECTED_SPANS.has(file_name):
				continue
			var expected: Dictionary = EXPECTED_SPANS[file_name]
			if String(expected["root"]) != String(pair[1]):
				continue
			for field: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
				var expected_field := field
				if field == "cpu_start":
					expected_field = "start"
				elif field == "cpu_end_exclusive":
					expected_field = "end"
				elif field == "file_offset":
					expected_field = "offset"
				var matches := int(span.get(field, -1)) == int(expected[expected_field]) \
						if field == "length" else String(span.get(field, "")) == String(expected[expected_field])
				if not matches:
					return _fail("NMI mode producer span metadata differs for %s (%s)." % [file_name, field])
			var bytes := FileAccess.get_file_as_bytes(String(expected["root"]) + file_name)
			if bytes.size() != int(expected["length"]) or _sha256(bytes) != String(expected["sha256"]):
				return _fail("Hash-checked NMI mode source span failed: " + file_name)
			if String(span.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
				return _fail("NMI mode manifest byte listing differs for " + file_name)
			_sources[file_name] = bytes
	for file_name: String in EXPECTED_SPANS:
		if not _sources.has(file_name):
			return _fail("NMI mode producer source package omits " + file_name)
	if not _load_special_nmi_writer_source():
		return false
	if not _verify_source_path():
		return false
	_configured = true
	return true


## Consumes the reset RAM-clear write receipt and emits only the ROM-derived
## mode-setter write. It rejects emulator/trace state and any nonzero `$001B`
## precondition, since the OR instruction preserves the input's other bits.
func build_cold_start_mode_receipt(reset_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(reset_receipt.get("ok", false)) \
			or String(reset_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(reset_receipt.get("emulator_data_used", false)) \
			or bool(reset_receipt.get("trace_state_used", false)):
		return _refused("Mode setter requires a successful ROM-only reset receipt.")
	var reset_1b_found := false
	for write_variant in reset_receipt.get("ram_writes", []):
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x001B:
			if int(write.get("value", -1)) != 0 or int(write.get("source_pc", -1)) != 0xC670:
				return _refused("Reset receipt does not establish `$001B=$00` at the ROM fill loop.")
			reset_1b_found = true
	if not reset_1b_found:
		return _refused("Reset receipt omitted `$001B` from the source RAM-clear writes.")
	return {
		"ok": true,
		"kind": "rom_cold_start_nmi_mode_setter",
		"source_rom_sha256": ROM_SHA256,
		"source_path": [0xFFFC, 0xFFF0, 0xC503, 0xC64E, 0xC670, 0xC6B9, 0xCEFE,
			0xC400, 0xC4B9, 0xC41E, 0xA200, 0xA21B, 0xA228],
		"ram_writes": [{"source_pc": 0xA228, "post_instruction_pc": 0xA22A,
			"address": 0x001B, "value": MODE_MASK}],
		"known_bit_mask": 0xFF,
		"known_bit_value": MODE_MASK,
		"full_byte_known_at_setter": true,
		"full_byte_known_at_later_route_boundary": false,
		"later_mode_bit_clears_source_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
		"source_note": "ROM bytes derive the cold-start setter; the FCEUX trace is separate validation. This receipt does not execute intervening title-route writes.",
	}


## Extends the cold-start mode-bit proof through the two source writers observed
## on the retained same-input route. Their exact instructions preserve bits 0–6;
## This generic route receipt preserves only bits 0–6; the frame-7266
## candidate-specific bit-7 state is proved by a separate source-history receipt.
func build_route_mode_bit_receipt(cold_start_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(cold_start_receipt.get("ok", false)) \
			or String(cold_start_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(cold_start_receipt.get("known_bit_mask", 0)) != 0xFF \
			or int(cold_start_receipt.get("known_bit_value", 0)) != MODE_MASK \
			or bool(cold_start_receipt.get("trace_state_used", true)) \
			or bool(cold_start_receipt.get("emulator_data_used", true)):
		return _refused("Route mode-bit continuation requires the ROM-derived cold-start setter receipt.")
	return {
		"ok": true,
		"kind": "rom_mode_bit_preservation_invariant",
		"source_rom_sha256": ROM_SHA256,
		"known_bit_writes": [{"address": 0x001B, "known_mask": 0x7F,
			"known_value": MODE_MASK, "source_pc": 0xA228}],
		"known_bit_mask": 0x7F,
		"known_bit_value": MODE_MASK,
		"source_preserving_writers": [
			{"source_pc": 0xA133, "instruction": "LDA $001B; ORA #$80; STA $001B",
				"preserves_mask": 0x7F, "source_span": "bank02_nmi_irq_setup_A000_A13E.bin"},
			{"source_pc": 0x9F0A, "instruction": "LDA $001B; BMI loop; AND #$7F; STA $001B",
				"preserves_mask": 0x7F, "source_span": "fixed_ready_latch_clear_9F04_9F0C.bin"},
		],
		"known_full_byte": false,
		"full_byte_known_at_later_route_boundary": false,
		"route_writer_set_validation": "Muted two-pass same-input FCEUX write census, frames 4693-7409, observes `$A135` and `$9F0C` as the `$001B` writers; this evidence is not consumed at runtime.",
		"other_mode_clear_paths": "ROM contains `$A5C0` and downstream `$C6E8` clear paths; the retained route writer census does not reach them before `$893B`.",
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
	}


## Combines the ROM-preserved low-seven-bit invariant with the route-bound
## stepper history at the candidate selector NMI. The source bytes for both
## `$A133` set and `$9F0A` clear paths are validated during configuration.
func build_pre_candidate_mode_bit7_receipt(route_mode_receipt: Dictionary,
		source_history_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(route_mode_receipt.get("ok", false)) \
			or String(route_mode_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(route_mode_receipt.get("known_bit_mask", 0)) != 0x7F \
			or int(route_mode_receipt.get("known_bit_value", 0)) != MODE_MASK \
			or bool(route_mode_receipt.get("trace_state_used", true)) \
			or bool(route_mode_receipt.get("emulator_data_used", true)):
		return _refused("Candidate mode-bit completion requires the ROM-derived `$001B & $7F` invariant.")
	if String(source_history_receipt.get("kind", "")) \
			!= "rom_stepper_pre_candidate_001b_bit7_history" \
			or String(source_history_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(source_history_receipt.get("source_stepper_sha256", "")) != SOURCE_STEPPER_SHA256 \
			or String(source_history_receipt.get("source_schedule_builder_sha256", "")) != SOURCE_SCHEDULE_BUILDER_SHA256 \
			or String(source_history_receipt.get("input_route_sha256", "")) != ROUTE_INPUT_SHA256 \
			or int(source_history_receipt.get("candidate_source_frame", -1)) != 7266 \
			or int(source_history_receipt.get("candidate_source_cycle", -1)) != 216355361 \
			or int(source_history_receipt.get("candidate_source_pc", -1)) != 0xC421 \
			or int(source_history_receipt.get("nmi_candidate_source_frame", -1)) != 7266 \
			or int(source_history_receipt.get("nmi_candidate_source_cycle", -1)) != 216355343 \
			or int(source_history_receipt.get("nmi_candidate_source_pc", -1)) != 0xA15B \
			or int(source_history_receipt.get("mode_001b_value_at_candidate", -1)) != 0xC0 \
			or int(source_history_receipt.get("write_count_before_candidate", -1)) != 14508:
		return _refused("ROM-stepper history does not identify the reviewed frame-7266 `$001B` boundary.")
	var writer_summary: Variant = source_history_receipt.get("writer_summary", [])
	var latest_writer: Variant = source_history_receipt.get("latest_writer_before_candidate", {})
	if not writer_summary is Array or writer_summary.size() != 9 \
			or not latest_writer is Dictionary \
			or int(latest_writer.get("source_pc", -1)) != 0xA133 \
			or int(latest_writer.get("prg_bank", -1)) != 0x02 \
			or int(latest_writer.get("value", -1)) != 0xC0 \
			or int(latest_writer.get("last_source_frame", -1)) != 7265 \
			or int(latest_writer.get("last_source_cycle", -1)) != 216326882 \
			or int(latest_writer.get("last_source_cycle", -1)) >= 216355343 \
			or not bool(source_history_receipt.get("no_mode_writer_between_nmi_candidate_and_boundary", false)):
		return _refused("The final source writer before candidate `$C421` is not the checked `$A133` set path.")
	if bool(source_history_receipt.get("trace_state_used", true)) \
			or bool(source_history_receipt.get("emulator_data_used", true)) \
			or bool(source_history_receipt.get("candidate_state_used", true)) \
			or bool(source_history_receipt.get("candidate_nmi_executed", true)):
		return _refused("Candidate mode-bit provenance cannot depend on emulator or injected endpoint state.")
	return {
		"ok": true,
		"kind": "rom_source_candidate_001b_bit7",
		"source_rom_sha256": ROM_SHA256,
		"input_route_sha256": ROUTE_INPUT_SHA256,
		"source_event_id": String(source_history_receipt.get("source_event_id", "")),
		"candidate_source_frame": 7266,
		"candidate_source_cycle": 216355361,
		"candidate_source_pc": 0xC421,
		"nmi_candidate_source_frame": 7266,
		"nmi_candidate_source_cycle": 216355343,
		"nmi_candidate_source_pc": 0xA15B,
		"known_bit_writes": [{"address": 0x001B, "known_mask": 0x80,
			"known_value": 0x80, "source_pc": 0xA133}],
		"known_bit_mask": 0xFF,
		"known_bit_value": 0xC0,
		"mode_001b_value_at_candidate": 0xC0,
		"last_writer_before_candidate": latest_writer.duplicate(true),
		"writer_summary": writer_summary.duplicate(true),
		"no_mode_writer_between_nmi_candidate_and_boundary": true,
		"rom_source_spans": ["bank02_nmi_irq_setup_A000_A13E.bin",
			"fixed_ready_latch_clear_9F04_9F0C.bin"],
		"candidate_nmi_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"physical_nes_timing_proven": false,
	}


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"source_rom_sha256": ROM_SHA256,
		"source_bit": "$001B.6",
		"source_setter_pc": "$A228",
		"source_post_instruction_pc": "$A22A",
		"runtime_rom_dependency": false,
		"runtime_emulator_dependency": false,
		"error": error_message,
	}


func _load_special_nmi_writer_source() -> bool:
	if not FileAccess.file_exists(WAIT_MANIFEST):
		return _fail("Special NMI writer source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WAIT_MANIFEST))
	if not parsed is Dictionary:
		return _fail("Special NMI writer source manifest is malformed.")
	var document: Dictionary = parsed
	var rom: Variant = document.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Special NMI writer source targets a different ROM revision.")
	for span_variant in document.get("spans", []):
		if not span_variant is Dictionary:
			continue
		var span: Dictionary = span_variant
		var source_path := String(span.get("file", ""))
		if not source_path.ends_with("bank02_nmi_irq_setup_A000_A13E.bin"):
			continue
		if String(span.get("cpu_start", "")) != "$A000" \
				or String(span.get("cpu_end_exclusive", "")) != "$A13F" \
				or String(span.get("file_offset", "")) != "0x004010" \
				or int(span.get("length", -1)) != 319 \
				or String(span.get("sha256", "")) != "89820a1c55e52fb9fcdb123eeed89945d187eaf4aaf5688d1869ffca612c5350":
			return _fail("Special NMI writer source span metadata differs from the checked ROM span.")
		var bytes := FileAccess.get_file_as_bytes("res://" + source_path)
		if bytes.size() != 319 or _sha256(bytes) != String(span["sha256"]) \
				or String(span.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Special NMI writer source span failed its manifest/hash check.")
		_sources["bank02_nmi_irq_setup_A000_A13E.bin"] = bytes
		return true
	return _fail("Special NMI writer source span is missing from its manifest.")


func _verify_source_path() -> bool:
	var reset_tail: PackedByteArray = _sources["fixed_reset_tail_C67A_C6BE.bin"]
	var reset_call := PackedByteArray([0xA9, 0x00, 0x4C, 0xFE, 0xCE])
	if reset_tail.slice(0x3F, 0x44) != reset_call:
		return _fail("Cold reset no longer passes `$00` into `$CEFE` and `$C400`.")
	var setup: PackedByteArray = _sources["fixed_setup_helper_CEFE_CF1F.bin"]
	if setup.slice(0, 1) != PackedByteArray([0x48]) or setup.slice(27, 33) \
			!= PackedByteArray([0x85, 0x20, 0x68, 0x4C, 0x00, 0xC4]):
		return _fail("`$CEFE` no longer preserves A and jumps to `$C400`.")
	var mapper_wrapper: PackedByteArray = _sources["fixed_mapper_wrapper_C400_C41E.bin"]
	if mapper_wrapper.slice(24, 30) != PackedByteArray([0xA2, 0x02, 0x20, 0xB9, 0xC4, 0x98]):
		return _fail("`$C400` no longer selects bank `$02` then restores A before `$C41E`.")
	var mapper_helper: PackedByteArray = _sources["fixed_mapper_select_C4B9_C4C7.bin"]
	if mapper_helper != PackedByteArray([0x86, 0x25, 0xA9, 0x07, 0x05, 0x22, 0x85, 0x23,
			0x8D, 0x00, 0x80, 0x8E, 0x01, 0x80, 0x60]):
		return _fail("Fixed mapper helper no longer selects MMC3 register `$07` from X.")
	if _sources["fixed_C41E_mode_dispatch_bridge.bin"] != PackedByteArray([0x4C, 0x00, 0xA2]):
		return _fail("`$C41E` no longer jumps to bank-$02 `$A200`.")
	var mode_dispatch: PackedByteArray = _sources["bank02_mode_setter_dispatch_A200_A22A.bin"]
	if mode_dispatch.slice(0, 3) != PackedByteArray([0x4C, 0x1B, 0xA2]) \
			or mode_dispatch.slice(27, 42) != PackedByteArray([
				0xA2, 0xFF, 0x9A, 0x48, 0xA9, 0x00, 0x8D, 0x00, 0xA0,
				0xA5, 0x1B, 0x09, 0x40, 0x85, 0x1B]):
		return _fail("Bank-$02 `$A21B` stack/mode-setter bytes differ from the audited ROM path.")
	var special_nmi: PackedByteArray = _sources["bank02_nmi_irq_setup_A000_A13E.bin"]
	if special_nmi.slice(0x12F, 0x135) != PackedByteArray([0xA5, 0x1B, 0x09, 0x80, 0x85, 0x1B]):
		return _fail("Bank-$02 `$A133` ready-latch writer no longer preserves `$001B.6`.")
	var ready_latch_clear: PackedByteArray = _sources["fixed_ready_latch_clear_9F04_9F0C.bin"]
	if ready_latch_clear != PackedByteArray([0xA5, 0x1B, 0x10, 0xFC, 0x29, 0x7F, 0x85, 0x1B]):
		return _fail("Fixed `$9F0A` ready-latch clear no longer preserves `$001B.6`.")
	return true


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
