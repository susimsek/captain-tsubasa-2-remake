extends RefCounted
class_name RomFreshMatchSpecialNmiExecutor
## Executes bounded parts of the ROM's special NMI service and bank-$0C sound
## driver. It can follow the empty-slot continuation to $80CA or the queued
## stop-ID clear prefix to $8350; these bounded paths do not advance the route.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/manifest.json"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/"
const SOUND_DRIVER_METADATA_PATH := "res://reference/rom_extract/audio/intro_track_58.json"
const SOUND_DRIVER_SOURCE_PATH := "res://reference/rom_extract/audio/bank_8c_sound_driver.bin"
const SOUND_DRIVER_SHA256 := "8c5dbc34a2f4ea3e7f6bcc503dcfd032d7cb4474ebba0c6c0af90efffe7c7468"
const SELECTOR_CLOCK_ROM_SHA256 := ROM_SHA256
const SELECTOR_CLOCK_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const SELECTOR_CLOCK_MODEL_SHA256 := "b0f528dfd73f79cf7148a5a2f6a9f0683cde22a03c1705deb8e5215864d888db"
const SOUND_DRIVER_FIRST_PASS_END_PC := 0x8061
const SOUND_DRIVER_EMPTY_SECOND_PASS_END_PC := 0x80CA
const SOUND_DRIVER_EMPTY_SECOND_PASS_SHA256 := "1a518def8e0027e3159f29c6a5015f3706a1f17ce1a51bfe4f20577fe8cd231f"
const SOUND_DRIVER_QUEUE_CONSUMER_SCAN_END_OFFSET := 0xBA
const SOUND_DRIVER_QUEUE_CONSUMER_SCAN_SHA256 := "aadad6b2b15b9ffeb51a1c6c4456acc0a726c32a6941d12dadf5449ad4d2bcb1"
const SOUND_DRIVER_ID1_CLEAR_PREFIX_END_OFFSET := 0x350
const SOUND_DRIVER_ID1_CLEAR_PREFIX_SHA256 := "8be56a788481343bcc864bffdb78f10e3585b3da411e99c7c39306857e793c26"
const SOUND_DRIVER_ZERO_MASK_TAIL_END_OFFSET := 0x16E
const SOUND_DRIVER_ZERO_MASK_TAIL_SHA256 := "1c22dffb62011c5196215db45fb212e6c05ae09469b23f0416b6e3b1f21a18cb"
const SPECIAL_NMI_WRAPPER_TAIL_SHA256 := "6f3a0222d1a89bfeede6a5c294257ec02ab581d6ee3da8deb78d240a874dc30c"
const SOUND_DRIVER_FIRST_PASS_BYTES := [
	0xA2, 0x05, 0xBC, 0x00, 0x07, 0xC0, 0x32, 0xB0, 0x0E, 0xA0, 0x07, 0x8C, 0x00, 0x80,
	0xAC, 0xFC, 0x07, 0x8C, 0x01, 0x80, 0x4C, 0x5E, 0x80, 0xC0, 0x44, 0xB0, 0x10, 0xA0,
	0x07, 0x8C, 0x00, 0x80, 0xA0, 0x0D, 0x8C, 0x01, 0x80, 0x8C, 0xFC, 0x07, 0x4C, 0x5E,
	0x80, 0xC0, 0x51, 0xB0, 0x10, 0xA0, 0x07, 0x8C, 0x00, 0x80, 0xA0, 0x0E, 0x8C, 0x01,
	0x80, 0x8C, 0xFC, 0x07, 0x4C, 0x5E, 0x80, 0xC0, 0x5C, 0xB0, 0x10, 0xA0, 0x07, 0x8C,
	0x00, 0x80, 0xA0, 0x0F, 0x8C, 0x01, 0x80, 0x8C, 0xFC, 0x07, 0x4C, 0x5E, 0x80, 0xA0,
	0x07, 0x8C, 0x00, 0x80, 0xAC, 0xFC, 0x07, 0x8C, 0x01, 0x80, 0xCA, 0x10, 0xA1,
]
## Sparse entry RAM bytes read by the source-verified special NMI and its
## zero-mask sound-driver continuation, before those bytes are written on this
## route. This is not a complete CPU/PPU/APU checkpoint.
const SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS: Array[int] = [
	0x001B, 0x001C, 0x001D, 0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025,
	0x003A, 0x003B, 0x0044, 0x0045, 0x0079, 0x007A, 0x007B, 0x008E, 0x008F,
	0x009E, 0x009F, 0x00A0, 0x00A1, 0x00E1, 0x00E2, 0x00E3, 0x0628,
	0x0700, 0x0701, 0x0702, 0x0703, 0x0704, 0x0705, 0x0706, 0x07E9, 0x07FC,
]
const SOURCE_SPANS := {
	"nmi_dispatch": {
		"file": "fixed_nmi_dispatch_C76E_C774.bin",
		"cpu_start": "$C76E", "cpu_end_exclusive": "$C775",
		"file_offset": "0x03C77E", "length": 7,
		"sha256": "d7d53b9d4b7243c6595b273e93d542e9760310c8592b5ec885b56f2a532bed86",
	},
	"nmi_vector_trampoline": {
		"file": "fixed_vector_trampolines_C500_C508.bin",
		"cpu_start": "$C500", "cpu_end_exclusive": "$C509",
		"file_offset": "0x03C510", "length": 9,
		"sha256": "4cacda47b1a9af1bdc11c78e5dc06357d5e8dfa4819ecf8f9c98bfe15b79151f",
	},
	"interrupt_vectors": {
		"file": "fixed_nmi_irq_vectors_FFFA_FFFF.bin",
		"cpu_start": "$FFFA", "cpu_end_exclusive": "$10000",
		"file_offset": "0x04000A", "length": 6,
		"sha256": "72925dda7194399d7eb27eb4a7d41a2b4d4b8be47b049bc1fd06f95f6627edec",
	},
	"nmi_service": {
		"file": "fixed_raster_nmi_service_C421_C472.bin",
		"cpu_start": "$C421", "cpu_end_exclusive": "$C473",
		"file_offset": "0x03C431", "length": 82,
		"sha256": "d02f695858c9d88a1cfadc63b71504cf467590449806820851d9feaab71b8673",
	},
	"irq_service": {
		"file": "fixed_raster_irq_service_C478_C4AD.bin",
		"cpu_start": "$C478", "cpu_end_exclusive": "$C4AE",
		"file_offset": "0x03C488", "length": 54,
		"sha256": "3bd224939351f06a7ff6e8138b52b8d8744c40b92bc955fe4b28e68b82c6917d",
	},
	"bank2_setup": {
		"file": "bank02_nmi_irq_setup_A000_A13E.bin",
		"cpu_start": "$A000", "cpu_end_exclusive": "$A13F",
		"file_offset": "0x004010", "length": 319,
		"sha256": "89820a1c55e52fb9fcdb123eeed89945d187eaf4aaf5688d1869ffca612c5350",
	},
	"bank2_boot_counter_clear": {
		"file": "bank02_boot_counter_clear_A234_A23E.bin",
		"cpu_start": "$A234", "cpu_end_exclusive": "$A23E",
		"file_offset": "0x004244", "length": 10,
		"sha256": "6d7887ce24131537fb91f69ed32775333e10e902eb4eb0c93dbe7c400a034604",
	},
	"bank2_mapper_pair": {
		"file": "bank02_irq_event_consumer_A160_A1E1.bin",
		"cpu_start": "$A160", "cpu_end_exclusive": "$A1E2",
		"file_offset": "0x004170", "length": 130,
		"sha256": "50a0bf6f80ee2c2ca1e1f2034e6328b6f447a73838bb833fb0041fc9455b191a",
	},
	"bank2_mapper_pair_tail": {
		"file": "bank02_mapper_pair_tail_A1E2_A1E4.bin",
		"cpu_start": "$A1E2", "cpu_end_exclusive": "$A1E4",
		"file_offset": "0x0041F2", "length": 2,
		"sha256": "322d846034eb1504f862d69cc84c8c42cf29fe205cae5962a7bf54618672d0ba",
	},
}

const BANK2_MAPPER_PAIR_BYTES := [
	0xB6, 0x78, 0xA9, 0x00, 0x05, 0x22, 0x8D, 0x00, 0x80,
	0x8E, 0x01, 0x80, 0xB6, 0x79, 0xA9, 0x01, 0x05, 0x22,
	0x8D, 0x00, 0x80, 0x8E, 0x01, 0x80,
]

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("Special-NMI source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Special-NMI source manifest is malformed JSON.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-0078-wait-source-v1":
		return _fail("Special-NMI source manifest schema is unsupported.")
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("Special-NMI source manifest targets a different ROM revision.")
	var entries: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			entries[String(span.get("file", "")).get_file()] = span
	for source_id: String in SOURCE_SPANS:
		var expected: Dictionary = SOURCE_SPANS[source_id]
		var file_name := String(expected["file"])
		if not entries.has(file_name):
			return _fail("Special-NMI manifest omits `%s`." % file_name)
		var entry: Dictionary = entries[file_name]
		for field: String in ["cpu_start", "cpu_end_exclusive", "file_offset", "length", "sha256"]:
			var matches := int(entry.get(field, -1)) == int(expected[field]) \
					if field == "length" else String(entry.get(field, "")) == String(expected[field])
			if not matches:
				return _fail("Special-NMI manifest metadata differs for `%s/%s`." % [source_id, field])
		var source_path := ROOT + file_name
		if not FileAccess.file_exists(source_path):
			return _fail("Special-NMI source bytes `%s` are missing." % file_name)
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if bytes.size() != int(expected["length"]) \
				or _sha256(bytes) != String(expected["sha256"]) \
				or String(entry.get("bytes", "")).to_lower().replace(" ", "") != bytes.hex_encode():
			return _fail("Special-NMI source bytes `%s` failed manifest/hash checks." % file_name)
		_sources[source_id] = bytes
	var audio_metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		SOUND_DRIVER_METADATA_PATH)) if FileAccess.file_exists(SOUND_DRIVER_METADATA_PATH) else null
	if not audio_metadata is Dictionary \
			or String(audio_metadata.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Sound-driver metadata is missing or targets a different ROM revision.")
	var driver_metadata: Variant = audio_metadata.get("driver", {})
	if not driver_metadata is Dictionary \
			or String(driver_metadata.get("entry_cpu_address", "")) != "$8000" \
			or String(driver_metadata.get("entry_file_offset", "")) != "0x018010" \
			or String(driver_metadata.get("prg_bank", "")) != "0x0C (bank 8C)":
		return _fail("Sound-driver entry metadata does not identify ROM bank `$0C:$8000`.")
	var driver_file: Variant = driver_metadata.get("file", {})
	if not driver_file is Dictionary \
			or String(driver_file.get("path", "")) != "reference/rom_extract/audio/bank_8c_sound_driver.bin" \
			or int(driver_file.get("size_bytes", -1)) != 0x2000 \
			or String(driver_file.get("sha256", "")) != SOUND_DRIVER_SHA256 \
			or not FileAccess.file_exists(SOUND_DRIVER_SOURCE_PATH):
		return _fail("The extracted bank-$0C sound-driver source metadata is incomplete.")
	var sound_driver := FileAccess.get_file_as_bytes(SOUND_DRIVER_SOURCE_PATH)
	var expected_driver_prefix := PackedByteArray(SOUND_DRIVER_FIRST_PASS_BYTES)
	if sound_driver.size() != 0x2000 or _sha256(sound_driver) != SOUND_DRIVER_SHA256 \
			or sound_driver.slice(0, expected_driver_prefix.size()) != expected_driver_prefix \
			or _sha256(sound_driver.slice(0x61, 0xCB)) != SOUND_DRIVER_EMPTY_SECOND_PASS_SHA256 \
			or _sha256(sound_driver.slice(0x61, SOUND_DRIVER_QUEUE_CONSUMER_SCAN_END_OFFSET)) \
			!= SOUND_DRIVER_QUEUE_CONSUMER_SCAN_SHA256 \
			or _sha256(sound_driver.slice(0x349, SOUND_DRIVER_ID1_CLEAR_PREFIX_END_OFFSET)) \
			!= SOUND_DRIVER_ID1_CLEAR_PREFIX_SHA256 \
			or _sha256(sound_driver.slice(0xCA, SOUND_DRIVER_ZERO_MASK_TAIL_END_OFFSET)) \
			!= SOUND_DRIVER_ZERO_MASK_TAIL_SHA256:
		return _fail("The bank-$0C sound-driver bytes, queue consumer, ID-$01 clear path, or zero-mask prefix failed ROM-source checks.")
	_sources["sound_driver"] = sound_driver
	var mapper_pair: PackedByteArray = _sources["bank2_mapper_pair"]
	var mapper_pair_tail: PackedByteArray = _sources["bank2_mapper_pair_tail"]
	var helper_start := 0xA1CB - 0xA160
	var checked_helper_prefix := PackedByteArray(BANK2_MAPPER_PAIR_BYTES.slice(0,
			BANK2_MAPPER_PAIR_BYTES.size() - 1))
	if mapper_pair.slice(helper_start, helper_start + checked_helper_prefix.size()) \
			!= checked_helper_prefix \
			or int(mapper_pair_tail[0]) != int(BANK2_MAPPER_PAIR_BYTES[-1]) \
			or int(mapper_pair_tail[1]) != 0x60:
		return _fail("The bank-$02 `$A1CB` mapper-pair helper differs from checked bytes.")
	_configured = true
	return true


## Completes the bank-$0C driver's saved MMC3-bank byte from its ROM-stepper
## write history and the checked `STY $07FC` writer instructions.
func build_pre_candidate_saved_bank_07fc_receipt(history: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if String(history.get("kind", "")) != "rom_stepper_pre_candidate_saved_bank_07fc_history" \
			or String(history.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(history.get("source_stepper_sha256", "")) != "233a721c91b17b56e3527bfc336ab47d020186b44a7da15f322224aa674e493a" \
			or String(history.get("source_schedule_builder_sha256", "")) != "2b9e1acbb15d19dc51ddf85820c32929e4e52d0078211f9e07eb459d143140f5" \
			or String(history.get("input_route_sha256", "")) != SELECTOR_CLOCK_INPUT_SHA256 \
			or int(history.get("candidate_source_frame", -1)) != 7266 \
			or int(history.get("candidate_source_cycle", -1)) != 216355361 \
			or int(history.get("candidate_source_pc", -1)) != 0xC421 \
			or int(history.get("saved_bank_07fc_value", -1)) != 0x0F \
			or int(history.get("write_count_before_candidate", -1)) != 4:
		return _failure("The route-bound `$07FC` history does not identify the audited frame-7266 `$C421` boundary.")
	var summary: Variant = history.get("writer_summary", [])
	var latest: Variant = history.get("latest_writer_before_candidate", {})
	var expected_counts := {"804D:0C:0F": 3, "C670:1E:00": 1}
	if not summary is Array or summary.size() != 2 or not latest is Dictionary:
		return _failure("The route-bound `$07FC` writer summary is malformed.")
	var observed_counts: Dictionary = {}
	var total := 0
	for row_variant in summary:
		if not row_variant is Dictionary:
			return _failure("A route-bound `$07FC` writer row is malformed.")
		var row: Dictionary = row_variant
		var signature := "%04X:%02X:%02X" % [int(row.get("source_pc", -1)),
			int(row.get("prg_bank", -1)), int(row.get("value", -1))]
		var count := int(row.get("count", -1))
		if int(row.get("address", -1)) != 0x07FC or not expected_counts.has(signature) \
				or count <= 0 or int(row.get("last_source_cycle", -1)) >= 216355361:
			return _failure("A `$07FC` writer does not match the source route or precede `$C421`.")
		observed_counts[signature] = count
		total += count
	if observed_counts != expected_counts or total != 4 \
			or int(latest.get("source_pc", -1)) != 0x804D \
			or int(latest.get("prg_bank", -1)) != 0x0C \
			or int(latest.get("value", -1)) != 0x0F \
			or int(latest.get("last_source_frame", -1)) != 4817 \
			or int(latest.get("last_source_cycle", -1)) != 143424443:
		return _failure("The last ROM-stepper `$07FC` write is not bank-$0C `$804D` value `$0F`.")
	var driver: PackedByteArray = _sources.get("sound_driver", PackedByteArray())
	var saved_bank_store := PackedByteArray([0x8C, 0xFC, 0x07]) # STY $07FC.
	for source_offset in [0x25, 0x39, 0x4D]:
		if driver.slice(source_offset, source_offset + 3) != saved_bank_store:
			return _failure("Bank-$0C `$%04X` no longer contains the checked `STY $07FC` store." % (0x8000 + source_offset))
	if bool(history.get("trace_state_used", true)) \
			or bool(history.get("emulator_data_used", true)) \
			or bool(history.get("candidate_state_used", true)) \
			or bool(history.get("candidate_nmi_executed", true)):
		return _failure("The `$07FC` receipt cannot depend on emulator or candidate endpoint state.")
	return {
		"ok": true,
		"kind": "rom_source_candidate_saved_bank_07fc",
		"source_rom_sha256": ROM_SHA256,
		"source_stepper_sha256": String(history["source_stepper_sha256"]),
		"source_schedule_builder_sha256": String(history["source_schedule_builder_sha256"]),
		"input_route_sha256": SELECTOR_CLOCK_INPUT_SHA256,
		"source_event_id": String(history.get("source_event_id", "")),
		"candidate_source_frame": 7266,
		"candidate_source_cycle": 216355361,
		"candidate_source_pc": 0xC421,
		"known_byte_values": [{"address": 0x07FC, "known_mask": 0xFF,
			"known_value": 0x0F, "source_pc": 0x804D}],
		"saved_bank_07fc_value": 0x0F,
		"write_count_before_candidate": 4,
		"latest_writer_before_candidate": latest.duplicate(true),
		"writer_summary": summary.duplicate(true),
		"source_instruction": "bank-$0C `$804D: STY $07FC`; `$Y=$0F` on the route branch, with reset `$C670` zero and three prior bank-$0C `$804D` stores",
		"candidate_nmi_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
	}


## Confirms that the candidate checkpoint knows every entry-RAM byte read by
## the bounded special-NMI/empty-sound-queue source path. Other machine state
## is deliberately left unresolved.
func build_zero_mask_entry_ram_read_contract(candidate_source_frame: int,
		candidate_checkpoint: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var cpu_checkpoint: Variant = candidate_checkpoint.get("cpu_checkpoint", {})
	if candidate_source_frame != 7266 \
			or String(candidate_checkpoint.get("status", "")) \
			!= "rom_selector_cpu_checkpoint_ready_candidate_nmi_not_dispatched" \
			or int(candidate_checkpoint.get("candidate_source_frame", -1)) != candidate_source_frame \
			or not cpu_checkpoint is Dictionary:
		return _failure("The RAM-read contract requires the route-bound frame-7266 candidate before NMI dispatch.")
	var registers: Variant = cpu_checkpoint.get("registers", {})
	var known_values: Variant = cpu_checkpoint.get("ram_known_values", {})
	if not registers is Dictionary or int(registers.get("pc", -1)) != 0xA15B \
			or not known_values is Dictionary:
		return _failure("The candidate checkpoint lacks its ROM-source `$A15B` PC or sparse RAM values.")
	var missing: Array[String] = []
	var read_values: Array[Dictionary] = []
	for address in SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS:
		if not known_values.has(address):
			missing.append("$%04X" % address)
			continue
		read_values.append({"address": address, "known_mask": 0xFF,
			"known_value": int(known_values[address]) & 0xFF})
	if not missing.is_empty():
		return _failure("Candidate checkpoint is missing zero-mask entry RAM reads: %s" % ", ".join(missing))
	if int(known_values[0x001B]) != 0xC0 \
			or int(known_values[0x003B]) != 0x55 \
			or int(known_values[0x003A]) != 0x57 \
			or int(known_values[0x001C]) != 0 \
			or int(known_values[0x001D]) != 0 \
			or int(known_values[0x0079]) != 0x40 \
			or int(known_values[0x0628]) != 0 \
			or int(known_values[0x0706]) != 0 \
			or int(known_values[0x07E9]) != 0 \
			or int(known_values[0x07FC]) != 0x0F:
		return _failure("Known entry RAM values do not select the audited special-NMI/zero-mask route.")
	if (int(known_values[0x001B]) & 0x40) == 0 \
			or (int(known_values[0x003B]) & 0x80) != 0 \
			or int(known_values[0x0079]) == 0 \
			or (int(known_values[0x0079]) & 0x80) != 0:
		return _failure("Entry RAM does not satisfy the ROM special-NMI and positive-preset branch guards.")
	for address in range(0x0700, 0x0706):
		if int(known_values[address]) != 0:
			return _failure("Sound queue slot `$%04X` is not empty on the audited route." % address)
	return {
		"ok": true,
		"kind": "rom_source_special_nmi_zero_mask_entry_ram_read_contract",
		"source_rom_sha256": ROM_SHA256,
		"source_frame": candidate_source_frame,
		"candidate_pc": 0xA15B,
		"candidate_nmi_not_dispatched": true,
		"required_entry_ram_read_count": SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size(),
		"known_entry_ram_read_count": read_values.size(),
		"entry_ram_read_addresses": SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.duplicate(),
		"known_entry_ram_values": read_values,
		"empty_packet_queue": true,
		"empty_sound_slots": true,
		"zero_sound_mask": true,
		"full_ram_image_complete": false,
		"cpu_stack_mapper_ppu_apu_context_complete": false,
		"candidate_nmi_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
	}


## Dispatches the frame-8 selector NMI from route-owned ROM execution state.
## Unknown RAM and stack bytes are explicit workspace placeholders; every
## entry read in the bounded handler must be covered by the checked sparse
## read contract, and the result never claims a complete machine snapshot.
func execute_source_clock_candidate_nmi(candidate_checkpoint: Dictionary,
		event: Dictionary, entry_ram_contract: Dictionary,
		controller_buttons: int, ppu_shadows: Dictionary,
		selector_entry_p_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var context_result := _build_source_clock_candidate_nmi_context(candidate_checkpoint,
		event, entry_ram_contract, controller_buttons, ppu_shadows,
		selector_entry_p_receipt)
	if not bool(context_result.get("ok", false)):
		return _failure(String(context_result.get("error", "Candidate NMI context was rejected.")))
	var context: Dictionary = context_result["context"]
	var entry_result := execute_from_c421(context)
	if not bool(entry_result.get("ok", false)):
		return _failure(String(entry_result.get("error", "ROM NMI entry execution stopped.")))
	var resumed := resume_empty_sound_slots_to_queue_head(entry_result)
	if not bool(resumed.get("ok", false)):
		return _failure(String(resumed.get("error", "ROM NMI sound-driver continuation stopped.")))
	resumed["candidate_nmi_dispatched"] = true
	resumed["source_event"] = context["source_event"].duplicate(true)
	resumed["entry_context_receipt"] = context_result["receipt"].duplicate(true)
	resumed["entry_executor_status"] = entry_result.get("status", "")
	resumed["source_clock_return_cycle"] = int(event.get("return_cycle", -1))
	resumed["physical_nes_timing_proven"] = false
	resumed["input_context_complete"] = false
	resumed["trace_state_used"] = false
	resumed["emulator_data_used"] = false
	resumed["candidate_state_used"] = false
	return resumed


func _build_source_clock_candidate_nmi_context(candidate_checkpoint: Dictionary,
		event: Dictionary, entry_ram_contract: Dictionary,
		controller_buttons: int, ppu_shadows: Dictionary,
		selector_entry_p_receipt: Dictionary) -> Dictionary:
	var registers: Variant = candidate_checkpoint.get("registers", {})
	var known_values: Variant = candidate_checkpoint.get("ram_known_values", {})
	var stack_value: Variant = candidate_checkpoint.get("stack_page", PackedByteArray())
	var stack_offsets: Variant = candidate_checkpoint.get("stack_page_known_offsets", [])
	if not registers is Dictionary or not known_values is Dictionary \
			or not stack_value is PackedByteArray or stack_value.size() != 0x100 \
			or not stack_offsets is Array \
			or int(candidate_checkpoint.get("sp", -1)) != 0x24 \
			or int(registers.get("pc", -1)) != 0xA15B \
			or int(candidate_checkpoint.get("ram_known_byte_count", 0)) <= 0:
		return {"ok": false, "error": "The frame-7266 `$A15B` ROM-source checkpoint lacks CPU, sparse RAM, or stack-page state."}
	if not bool(candidate_checkpoint.get("ram_image_complete", false)) \
			and int(candidate_checkpoint.get("ram_known_byte_count", 0)) <= 0:
		return {"ok": false, "error": "Sparse candidate RAM has no known-byte provenance."}
	if not bool(entry_ram_contract.get("ok", false)) \
			or String(entry_ram_contract.get("kind", "")) \
			!= "rom_source_special_nmi_zero_mask_entry_ram_read_contract" \
			or int(entry_ram_contract.get("source_frame", -1)) != 7266 \
			or int(entry_ram_contract.get("known_entry_ram_read_count", -1)) \
			!= SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size():
		return {"ok": false, "error": "The source-owned 35-byte NMI entry RAM contract is missing or incomplete."}
	if not bool(selector_entry_p_receipt.get("ok", false)) \
			or String(selector_entry_p_receipt.get("kind", "")) != "rom_source_selector_call_entry_p_byte" \
			or int(selector_entry_p_receipt.get("known_mask", 0)) != 0xFF \
			or int(selector_entry_p_receipt.get("known_value", -1)) != 0x30 \
			or int(selector_entry_p_receipt.get("source_cycle", -1)) != 216143875:
		return {"ok": false, "error": "The hash-bound selector-call status/cycle receipt is unavailable."}
	if String(event.get("kind", "")) != "NMI" \
			or int(event.get("frame_offset", -1)) != 8 \
			or int(event.get("elapsed_cycle", -1)) != 211468 \
			or int(event.get("return_cycle", -1)) != 213730 \
			or String(event.get("pc_before", "")) != "$A15B" \
			or String(event.get("vector_pc", "")) != "$C500" \
			or String(event.get("return_pc", "")) != "$A15B":
		return {"ok": false, "error": "The selected frame-8 NMI event differs from the validated source-clock record."}
	if controller_buttons != 0:
		return {"ok": false, "error": "The frame-7266 source route requires both controllers released; held buttons cannot be inferred from a trace RAM snapshot."}
	var vector_bytes: PackedByteArray = _sources.get("interrupt_vectors", PackedByteArray())
	var trampoline: PackedByteArray = _sources.get("nmi_vector_trampoline", PackedByteArray())
	var dispatch: PackedByteArray = _sources.get("nmi_dispatch", PackedByteArray())
	if vector_bytes.size() != 6 or trampoline.size() != 9 or dispatch.size() != 7 \
			or (int(vector_bytes[0]) | (int(vector_bytes[1]) << 8)) != 0xC500 \
			or trampoline.slice(0, 3) != PackedByteArray([0x4C, 0x6E, 0xC7]) \
			or dispatch != PackedByteArray([0x24, 0x1B, 0x50, 0x03, 0x4C, 0x21, 0xC4]):
		return {"ok": false, "error": "The ROM NMI vector/trampoline/dispatch bytes do not resolve to `$C421`."}
	var entry_reads_variant: Variant = entry_ram_contract.get("known_entry_ram_values", [])
	if not entry_reads_variant is Array or entry_reads_variant.size() != SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size():
		return {"ok": false, "error": "The sparse NMI entry-read values do not cover the audited source read set."}
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	for address_variant in known_values:
		var address := int(address_variant)
		var value := int(known_values[address_variant])
		if address < 0 or value < 0 or value > 0xFF:
			return {"ok": false, "error": "ROM-source RAM entry `%s` has invalid address/value %d/$%X." % [str(address_variant), address, value]}
		if address <= 0x1FFF:
			ram[address & 0x07FF] = value
	var expected_read_values: Dictionary = {}
	for read_variant in entry_reads_variant:
		if not read_variant is Dictionary:
			return {"ok": false, "error": "The sparse NMI entry-read list contains a malformed value."}
		var read: Dictionary = read_variant
		var address := int(read.get("address", -1))
		var value := int(read.get("known_value", -1))
		if address not in SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS \
				or int(read.get("known_mask", 0)) != 0xFF \
				or not known_values.has(address) \
				or value != int(known_values[address]):
			return {"ok": false, "error": "The NMI entry-read contract conflicts with the sparse source RAM byte at `$%04X`." % address}
		expected_read_values[address] = value
	if expected_read_values.size() != SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size():
		return {"ok": false, "error": "The NMI entry-read contract has duplicate or missing RAM addresses."}
	for address in SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS:
		if not expected_read_values.has(address) or int(ram[address]) != int(expected_read_values[address]):
			return {"ok": false, "error": "The NMI workspace byte `$%04X` is not source-known." % address}
	var ppu_ctrl := int(ppu_shadows.get("ctrl_shadow", -1))
	var ppu_mask := int(ppu_shadows.get("mask_shadow", -1))
	if ppu_ctrl < 0 or ppu_ctrl > 0xFF or ppu_mask < 0 or ppu_mask > 0xFF \
			or ppu_ctrl != int(ram[0x0020]) or ppu_mask != int(ram[0x0021]):
		return {"ok": false, "error": "Source PPU shadow state does not match `$0020/$0021`."}
	for shadow_address in [0x0022, 0x0023, 0x0024, 0x0025]:
		if not known_values.has(shadow_address):
			return {"ok": false, "error": "MMC3 source shadow `$%04X` is unknown at the NMI entry." % shadow_address}
	var registers_after_reset: Array[int] = [-1, -1, -1, -1, -1, -1,
		int(ram[0x0024]), int(ram[0x0025])]
	var select_shadow := int(ram[0x0022])
	var command := int(ram[0x0023])
	var mapper := {
		"registers": registers_after_reset,
		"known_register_mask": 0xC0,
		"command": command,
		"prg_mode": (command & 0x40) != 0,
		"chr_inversion": (command & 0x80) != 0,
		"8000_prg_bank": int(ram[0x0024]) if (command & 0x40) == 0 else int(ram[0x0025]),
		"a000_prg_bank": int(ram[0x0025]) if (command & 0x40) == 0 else int(ram[0x0024]),
		"irq_enabled": false,
		"irq_reload_requested": false,
		"irq_latch": 0,
		"select_shadow": select_shadow,
	}
	var interrupted_p := int(registers.get("p", -1))
	var interrupted_pc := int(registers.get("pc", -1))
	var interrupted_sp := int(candidate_checkpoint.get("sp", -1))
	if interrupted_pc != 0xA15B or interrupted_sp != 0x24 \
			or interrupted_p != 0x30 \
			or int(registers.get("a", -1)) != 0x1F \
			or int(registers.get("x", -1)) != 0 \
			or int(registers.get("y", -1)) != 0:
		return {"ok": false, "error": "The route-owned `$A15B` CPU registers differ from the reviewed NMI candidate."}
	var pushed_p := ((interrupted_p & 0xEF) | 0x20) & 0xFF
	var stack: PackedByteArray = stack_value.duplicate()
	stack[interrupted_sp] = (interrupted_pc >> 8) & 0xFF
	stack[(interrupted_sp - 1) & 0xFF] = interrupted_pc & 0xFF
	stack[(interrupted_sp - 2) & 0xFF] = pushed_p
	var nmi_entry_sp := (interrupted_sp - 3) & 0xFF
	var cpu := {"pc": 0xC421, "a": int(registers["a"]), "x": int(registers["x"]),
		"y": int(registers["y"]), "p": (((interrupted_p & 0xCF) | 0x24) & 0xFF),
		"sp": nmi_entry_sp}
	_apply_bit(cpu, int(ram[0x001B]))
	if int(cpu["p"]) != 0xE6:
		return {"ok": false, "error": "The source `$C76E BIT $1B` dispatch does not produce the reviewed `$C421` P byte."}
	var source_cycle := int(selector_entry_p_receipt["source_cycle"]) + int(event["elapsed_cycle"])
	var c421_cycle := source_cycle + 18
	var source_event_id := "selector_frame8_nmi_%d_A15B_C421" % source_cycle
	var context := {
		"source_rom_sha256": ROM_SHA256,
		"provenance": {"kind": "rom_source_execution", "source_sha256": ROM_SHA256,
			"input_route_sha256": SELECTOR_CLOCK_INPUT_SHA256,
			"trace_state_used": false, "emulator_data_used": false,
			"candidate_state_used": false, "rom_model_checkpoint_used": true},
		"source_event": {"kind": "NMI", "source_event_id": source_event_id,
			"source_frame": 7266, "interrupted_pc": interrupted_pc,
			"entry_pc": 0xC421, "vector_pc": 0xC500,
			"dispatch_pc": 0xC76E, "entry_cycle": source_cycle,
			"dispatch_cycle": c421_cycle, "entry_dispatch_cycles": 18,
			"source_clock_elapsed_cycle": int(event["elapsed_cycle"])},
		"nmi_frame": {"interrupted_pc": interrupted_pc,
			"interrupted_p": pushed_p, "interrupted_sp": interrupted_sp,
			"pre_interrupt_p": interrupted_p, "entry_sp": nmi_entry_sp,
			"hardware_push_order": ["PCH", "PCL", "P"],
			"hardware_entry_cycles": 7},
		"cpu": cpu,
		"ram": ram,
		"ram_known_values": known_values.duplicate(true),
		"ram_entry_read_contract": entry_ram_contract.duplicate(true),
		"ram_workspace_fill_value": 0,
		"ram_source_image_complete": false,
		"stack_page": stack,
		"stack_page_known_offsets": stack_offsets.duplicate(),
		"stack_page_complete": false,
		"mapper": mapper,
		"ppu": {"ctrl_shadow": ppu_ctrl, "mask_shadow": ppu_mask},
		"controller_inputs": {"port1_buttons": controller_buttons,
			"port2_buttons": 0, "route_input_held_bits": controller_buttons,
			"route_input_source": "current recorded Godot input state", "input_bytes_known": true},
		"source_context_completeness": {"ram_image_complete": false,
			"stack_page_complete": false, "mmc3_registers_complete_at_entry": false,
			"ppu_pipeline_complete": false, "apu_state_complete": false,
			"entry_ram_reads_complete": true, "source_clock_event_complete": true},
	}
	return {"ok": true, "context": context,
		"receipt": {"ok": true, "kind": "rom_source_candidate_nmi_dispatch_context",
			"source_rom_sha256": ROM_SHA256, "source_frame": 7266,
			"interrupted_pc": interrupted_pc, "interrupted_p": interrupted_p,
			"pushed_status": pushed_p, "entry_pc": 0xC421,
			"vector_pc": 0xC500, "dispatch_pc": 0xC76E,
			"dispatch_cycles_after_accept": 18,
			"entry_source_cycle": source_cycle,
			"c421_source_cycle": c421_cycle,
			"entry_ram_read_count": expected_read_values.size(),
			"ram_source_image_complete": false,
			"stack_page_complete": false,
			"mmc3_registers_known_at_entry_mask": 0xC0,
			"physical_nes_timing_proven": false,
			"trace_state_used": false, "emulator_data_used": false,
			"candidate_state_used": false}}


## Context is a source-produced NMI boundary. It must include a physical stack
## page, full 2 KiB CPU RAM, current MMC3 registers, PPU shadows, and the two
## serial controller states. Emulator/candidate state is rejected.
func execute_from_c421(context: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var checked := _validate_context(context)
	if not bool(checked.get("ok", false)):
		return _failure(String(checked.get("error", "Input source context is invalid.")))
	var cpu: Dictionary = context["cpu"].duplicate(true)
	var ram: PackedByteArray = context["ram"].duplicate()
	var stack: PackedByteArray = context["stack_page"].duplicate()
	var mapper: Dictionary = context["mapper"].duplicate(true)
	var controller: Dictionary = context["controller_inputs"].duplicate(true)
	var ppu: Dictionary = context["ppu"].duplicate(true)
	var writes: Array[Dictionary] = []
	var mapper_events: Array[Dictionary] = []
	var ppu_events: Array[Dictionary] = []
	var source_path: Array[int] = []
	var sp := int(cpu["sp"])

	# C421: BIT $3B / BMI $C472. This executor handles only the accepted-call path.
	_record_pc(source_path, 0xC421)
	_apply_bit(cpu, int(ram[0x003B]))
	if (int(cpu["p"]) & 0x80) != 0:
		return _failure("The ROM `$C421` `$003B.7` guard selects the RTI-only path; `$A000` is not entered.")

	# SEC / ROR $3B / STA $3C / STX $3D / STY $3E.
	_record_pc(source_path, 0xC423)
	cpu["p"] = int(cpu["p"]) | 0x01
	var old_3b := int(ram[0x003B])
	var rotated_3b := ((old_3b >> 1) | ((int(cpu["p"]) & 0x01) << 7)) & 0xFF
	cpu["p"] = (int(cpu["p"]) & 0xFE) | (old_3b & 0x01)
	_set_nz(cpu, rotated_3b)
	_ram_write(ram, writes, 0xC426, 0x003B, rotated_3b)
	_ram_write(ram, writes, 0xC428, 0x003C, int(cpu["a"]))
	_ram_write(ram, writes, 0xC42A, 0x003D, int(cpu["x"]))
	_ram_write(ram, writes, 0xC42C, 0x003E, int(cpu["y"]))

	# Select bank $02 in MMC3 R7 and call the source routine in the $A000 slot.
	_mapper_write(mapper, mapper_events, 0xC432, 0x8000, int(ram[0x0022]) | 0x07)
	_mapper_write(mapper, mapper_events, 0xC437, 0x8001, 0x02)
	if int(mapper.get("a000_prg_bank", -1)) != 0x02:
		return _failure("ROM `$C421` selected MMC3 bank `$02`, but the mapper model did not expose it at `$A000`.")
	_record_pc(source_path, 0xC43A)
	var jsr := _stack_jsr(stack, sp, 0xA000, 0xC43C)
	if not bool(jsr.get("ok", false)):
		return _failure(String(jsr.get("error", "Could not push the `$C43A` JSR frame.")))
	sp = int(jsr["sp"])
	cpu["pc"] = 0xA000
	var body := _execute_bank2_setup_through_rts(ram, stack, sp, cpu, mapper,
		controller, ppu, writes, mapper_events, ppu_events, source_path)
	if not bool(body.get("ok", false)):
		return _failure(String(body.get("error", "Bank-$02 NMI setup stopped.")))
	ram = body["ram"]
	stack = body["stack_page"]
	sp = int(body["sp"])
	cpu = body["cpu"]
	mapper = body["mapper"]
	controller = body["controller_inputs"]
	ppu = body["ppu"]
	if int(cpu.get("pc", -1)) != 0xC43D:
		return _failure("The bank-$02 `$A000 RTS` did not return to `$C43D`.")

	# The wrapper's first return-side call enters the bank-$0C sound driver.
	# Execute its checked six-slot bank-selection scan from the supplied full RAM,
	# stack, CPU, and MMC3 state. Stop before the second driver pass/APU work.
	_record_pc(source_path, 0xC43D)
	cpu["a"] = int(ram[0x0022])
	_set_nz(cpu, int(cpu["a"]))
	cpu["a"] = (int(cpu["a"]) | 0x06) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	_mapper_write(mapper, mapper_events, 0xC441, 0x8000, int(cpu["a"]))
	_record_pc(source_path, 0xC444)
	cpu["a"] = 0x0C
	_set_nz(cpu, int(cpu["a"]))
	_mapper_write(mapper, mapper_events, 0xC446, 0x8001, int(cpu["a"]))
	_record_pc(source_path, 0xC449)
	cpu["pc"] = 0xC449
	if int(mapper.get("8000_prg_bank", -1)) != 0x0C:
		return _failure("The ROM `$C449 JSR $8000` call is not mapped to physical bank `$0C`.")
	if int(ram[0x0078]) != 0x04:
		return _failure("The ROM `$A0A6` write did not leave the source wait latch at `$04`.")
	var driver_jsr := _stack_jsr(stack, sp, 0x8000, 0xC44B)
	if not bool(driver_jsr.get("ok", false)):
		return _failure(String(driver_jsr.get("error", "Could not push the `$C449` sound-driver JSR frame.")))
	sp = int(driver_jsr["sp"])
	cpu["pc"] = 0x8000
	var sound_prefix := _execute_sound_driver_first_pass(ram, stack, sp, cpu, mapper)
	if not bool(sound_prefix.get("ok", false)):
		return _failure(String(sound_prefix.get("error", "The sound-driver first pass stopped.")))
	ram = sound_prefix["ram"]
	stack = sound_prefix["stack_page"]
	sp = int(sound_prefix["sp"])
	cpu = sound_prefix["cpu"]
	mapper = sound_prefix["mapper"]
	source_path.append_array(sound_prefix["source_path"])
	writes.append_array(sound_prefix["ram_writes"])
	mapper_events.append_array(sound_prefix["mapper_bus_writes"])
	return {
		"ok": true,
		"status": "stopped_after_sound_driver_first_queue_scan",
		"completed": false,
		"source_event_id": String(context["source_event"]["source_event_id"]),
		"source_rom_sha256": ROM_SHA256,
		"source_path": source_path,
		"ram_after": ram,
		"stack_page_after": stack,
		"ram_writes": writes,
		"mapper_after": mapper,
		"mapper_bus_writes": mapper_events,
		"ppu_after": ppu,
		"ppu_bus_events": ppu_events,
		"ppu_packet_queue": body.get("ppu_packet_queue", {}),
		"controller_reads_consumed": int(body["controller_reads_consumed"]),
		"cpu_at_sound_driver_boundary": {"pc": SOUND_DRIVER_FIRST_PASS_END_PC,
			"a": int(cpu["a"]), "x": int(cpu["x"]), "y": int(cpu["y"]),
			"p": int(cpu["p"]), "p_known_mask": 0xFF, "sp": sp,
			"other_registers_known": true},
		"sound_driver_first_pass": {"completed": true,
			"queue_slots_scanned": 6, "apu_state_required_for_this_prefix": false,
			"second_pass_started": false},
		"pending_rom_call": {"caller_pc": 0xC449, "target_pc": 0x8000,
			"physical_prg_bank": 0x0C, "return_pc": 0xC44C,
			"jsr_frame_pending": true,
			"source_event_id": String(context["source_event"]["source_event_id"]) + ":C449-8000",
			"nmi_entry_sp": int(context["cpu"]["sp"]),
			"nmi_frame": context["nmi_frame"].duplicate(true),
			"interrupted_3b": int(context["ram"][0x003B]),
			"saved_a": int(ram[0x003C]), "saved_x": int(ram[0x003D]),
			"saved_y": int(ram[0x003E])},
		"nmi_stack_frame_preserved": _nmi_stack_frame_matches(stack,
			int(context["cpu"]["sp"]), context["nmi_frame"]),
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"reaches_sound_driver_rts": false,
		"reaches_nmi_rti": false,
		"advances_live_route": false,
	}


## Executes the ROM `$A00A-$A05A` packet consumer for one palette packet built
## by the source cleanup-fade task. This is only the bounded queue subroutine;
## it does not claim that the surrounding NMI, controller scan, or sound driver
## ran. The queue bytes must come from a ROM-derived producer receipt.
func execute_source_ppu_packet_queue(queue_ram_values: Dictionary,
		ppu_shadow_input: Dictionary, source_frame: int, event_id: String) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if source_frame < 0 or event_id.strip_edges().is_empty() \
			or not bool(ppu_shadow_input.get("ok", false)):
		return _failure("The bounded ROM PPU-queue consumer needs a named source event, frame, and PPU-shadow receipt.")
	var ctrl_shadow := int(ppu_shadow_input.get("ctrl_shadow", -1))
	var mask_shadow := int(ppu_shadow_input.get("mask_shadow", -1))
	if ctrl_shadow < 0 or ctrl_shadow > 0xFF or mask_shadow < 0 or mask_shadow > 0xFF:
		return _failure("The ROM PPU-queue consumer needs source-known `$0020/$0021` shadows.")
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	for address_variant in queue_ram_values:
		var address := int(address_variant)
		var value := int(queue_ram_values[address_variant])
		if address < 0 or address >= ram.size() or value < 0 or value > 0xFF:
			return _failure("ROM PPU-queue source RAM contains an invalid byte at `$%04X`." % address)
		ram[address] = value
	var queued_bytes := int(ram[0x0628])
	if queued_bytes <= 0 or queued_bytes >= 0x40 or (int(ram[0x0629]) & 0x40) != 0:
		return _failure("ROM `$A000` packet drain requires a nonempty queue below its `$40` buffer limit and bit 6 clear.")
	if not queue_ram_values.has(0x05E8 + queued_bytes) \
			or int(ram[0x05E8 + queued_bytes]) != 0:
		return _failure("The ROM PPU queue has no source-produced zero terminator at `$05E8+$0628`.")
	if int(queue_ram_values.get(0x0020, -1)) != ctrl_shadow \
			or int(queue_ram_values.get(0x0021, -1)) != mask_shadow:
		return _failure("The source queue RAM and PPU shadow receipt disagree at `$0020/$0021`.")
	var ppu := {"ctrl_shadow": ctrl_shadow, "mask_shadow": mask_shadow}
	var writes: Array[Dictionary] = []
	var ppu_events: Array[Dictionary] = []
	var source_path: Array[int] = []
	var queue_result := _execute_a000_ppu_packet_queue(ram, ppu, writes,
		ppu_events, source_path)
	if not bool(queue_result.get("ok", false)) \
			or String(queue_result.get("status", "")) != "packet_buffer_drained" \
			or int(ram[0x0628]) != 0:
		return _failure("ROM `$A00A-$A05A` did not drain the produced PPU queue: "
			+ String(queue_result.get("error", queue_result.get("status", "unknown queue error"))))
	_ppu_write(ppu, ppu_events, 0xA05F, 0x2001, mask_shadow)
	return {
		"ok": true,
		"kind": "rom_a000_bounded_source_ppu_queue_consumer",
		"status": "packet_buffer_drained",
		"source_event_id": event_id,
		"source_frame": source_frame,
		"source_rom_sha256": ROM_SHA256,
		"queue_ram_before": {"cursor": queued_bytes, "control": int(queue_ram_values[0x0629]),
			"buffer_start": 0x05E8, "terminator_address": 0x05E8 + queued_bytes},
		"ppu_packet_queue": queue_result,
		"ram_writes": writes,
		"ppu_bus_events": ppu_events,
		"ppu_after_bounded_queue_consumer": ppu.duplicate(true),
		"source_path": source_path,
		"surrounding_nmi_executed": false,
		"controller_scan_executed": false,
		"sound_driver_executed": false,
		"physical_nes_timing_proven": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


func execute_cleanup_fade_palette_packet(packet: PackedByteArray,
		ppu_shadow_input: Dictionary = {}) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if packet.size() != 0x23 or packet.slice(0, 3) != PackedByteArray([0x20, 0x00, 0x3F]):
		return _failure("The ROM cleanup fade must provide a 35-byte `$3F00` palette packet.")
	var ctrl_shadow := int(ppu_shadow_input.get("ctrl_shadow", 0))
	var mask_shadow := int(ppu_shadow_input.get("mask_shadow", 0))
	if ctrl_shadow < 0 or ctrl_shadow > 0xFF or mask_shadow < 0 or mask_shadow > 0xFF:
		return _failure("The ROM cleanup-fade queue needs byte PPU shadows.")
	var ram := PackedByteArray()
	ram.resize(0x800)
	ram.fill(0)
	ram[0x0628] = packet.size()
	ram[0x0629] = 0x20
	for index in packet.size():
		ram[0x05E8 + index] = packet[index]
	ram[0x05E8 + packet.size()] = 0
	var ppu := {"ctrl_shadow": ctrl_shadow, "mask_shadow": mask_shadow}
	var writes: Array[Dictionary] = []
	var ppu_events: Array[Dictionary] = []
	var source_path: Array[int] = []
	var queue_result := _execute_a000_ppu_packet_queue(
		ram, ppu, writes, ppu_events, source_path)
	if not bool(queue_result.get("ok", false)) \
			or String(queue_result.get("status", "")) != "packet_buffer_drained" \
			or int(queue_result.get("packet_count", -1)) != 1 \
			or int(queue_result.get("payload_bytes", -1)) != 32 \
			or int(queue_result.get("source_bytes_consumed", -1)) != packet.size():
		return _failure("ROM `$A000` did not consume the source fade packet as one 32-byte record.")
	var payload_events: Array[Dictionary] = []
	for event_variant in ppu_events:
		if event_variant is Dictionary and int(event_variant.get("address", -1)) == 0x2007:
			payload_events.append(event_variant)
	if payload_events.size() != 32:
		return _failure("ROM `$A000` did not emit 32 `$2007` writes for the fade packet.")
	for index in 32:
		var event: Dictionary = payload_events[index]
		if int(event.get("source_pc", -1)) != 0xA039 \
				or int(event.get("ppu_address", -1)) != 0x3F00 + index \
				or int(event.get("value", -1)) != int(packet[index + 3]):
			return _failure("ROM `$A000` palette write %d differs from its source packet byte." % index)
	if writes.size() != 1 or int(writes[0].get("source_pc", -1)) != 0xA04A \
			or int(writes[0].get("address", -1)) != 0x0628 \
			or int(writes[0].get("before", -1)) != packet.size() \
			or int(writes[0].get("value", -1)) != 0:
		return _failure("ROM `$A04A` did not clear the consumed `$0628` queue marker.")
	return {
		"ok": true,
		"kind": "rom_a000_cleanup_fade_palette_packet_consumer",
		"source_rom_sha256": ROM_SHA256,
		"source_path": source_path,
		"source_event": {"kind": "cleanup_fade_palette_packet",
			"packet_source": "ROM-derived `$99F0->$9A71` cleanup-fade task",
			"queued_bytes": packet.size(), "consumer_entry_pc": 0xA00A},
		"ram_writes": writes,
		"ppu_bus_events": ppu_events,
		"ppu_packet_queue": queue_result,
		"ppu_after_bounded_queue_consumer": ppu.duplicate(true),
		"ram_after_0628": int(ram[0x0628]),
		"surrounding_nmi_executed": false,
		"controller_scan_executed": false,
		"sound_driver_executed": false,
		"physical_nes_timing_proven": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


## Resumes the checked sound-driver state at $8061 only when all six
## source-owned sound slots are empty. It executes the ROM's DEX loop and the
## $F0-$F3 queue-pointer setup, then stops before reading $0706 or touching APU.
func resume_empty_sound_slots_to_queue_head(nmi_result: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if not bool(nmi_result.get("ok", false)) \
			or String(nmi_result.get("status", "")) != "stopped_after_sound_driver_first_queue_scan" \
			or String(nmi_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(nmi_result.get("trace_state_used", true)) \
			or bool(nmi_result.get("emulator_data_used", true)) \
			or bool(nmi_result.get("candidate_state_used", true)) \
			or bool(nmi_result.get("advances_live_route", true)):
		return _failure("The sound-driver continuation requires a successful ROM-source NMI result, not trace or candidate state.")
	var boundary: Dictionary = nmi_result.get("cpu_at_sound_driver_boundary", {})
	var pending: Dictionary = nmi_result.get("pending_rom_call", {})
	var ram_value: Variant = nmi_result.get("ram_after", PackedByteArray())
	var stack_value: Variant = nmi_result.get("stack_page_after", PackedByteArray())
	var mapper_value: Variant = nmi_result.get("mapper_after", {})
	if not ram_value is PackedByteArray or ram_value.size() != 0x800 \
			or not stack_value is PackedByteArray or stack_value.size() != 0x100 \
			or not mapper_value is Dictionary or not boundary.has("sp") \
			or int(boundary.get("pc", -1)) != SOUND_DRIVER_FIRST_PASS_END_PC \
			or String(pending.get("source_event_id", "")).is_empty() \
			or int(pending.get("caller_pc", -1)) != 0xC449 \
			or int(pending.get("return_pc", -1)) != 0xC44C \
			or not bool(pending.get("jsr_frame_pending", false)):
		return _failure("The NMI result is missing the complete pending `$C449->$8000` sound-driver state.")
	var ram: PackedByteArray = ram_value.duplicate()
	var stack: PackedByteArray = stack_value.duplicate()
	var mapper: Dictionary = mapper_value.duplicate(true)
	var cpu: Dictionary = boundary.duplicate(true)
	var sp := int(cpu["sp"])
	if sp < 0 or sp > 0xFD or int(cpu.get("a", -1)) < 0 \
			or int(cpu.get("a", -1)) > 0xFF \
			or int(cpu.get("p", -1)) < 0 or int(cpu.get("p", -1)) > 0xFF:
		return _failure("The `$8061` CPU boundary has invalid register state.")
	var return_word := int(stack[sp + 1]) | (int(stack[sp + 2]) << 8)
	if return_word != 0xC44B:
		return _failure("The pending bank-$0C sound-driver JSR does not return to `$C44C`.")
	var mapper_registers: Variant = mapper.get("registers", [])
	if not mapper_registers is Array or mapper_registers.size() != 8 \
			or bool(mapper.get("prg_mode", true)) \
			or int(mapper_registers[6]) != 0x0C \
			or int(mapper.get("8000_prg_bank", -1)) != 0x0C:
		return _failure("The `$8061` sound-driver state no longer maps bank `$0C` at `$8000`.")
	var driver_bytes: PackedByteArray = _sources.get("sound_driver", PackedByteArray())
	if driver_bytes.size() != 0x2000 \
			or _sha256(driver_bytes.slice(0x61, 0xCB)) != SOUND_DRIVER_EMPTY_SECOND_PASS_SHA256:
		return _failure("The empty-slot second-pass instructions failed the ROM source hash.")
	var source_path: Array[int] = nmi_result.get("source_path", []).duplicate()
	var queue_ids: Array[int] = []
	var cycles := 2 # LDX #$05 at $8061.
	cpu["x"] = 0x05
	_set_nz(cpu, 0x05)
	_record_pc(source_path, 0x8061)
	for slot_index in range(5, -1, -1):
		var queue_id := int(ram[0x0700 + slot_index])
		queue_ids.append(queue_id)
		if queue_id != 0:
			return _failure("The ROM sound slot `$%04X` is $%02X; only the source-proven empty-slot path is implemented." % [0x0700 + slot_index, queue_id])
		_record_pc(source_path, 0x8063)
		cpu["y"] = queue_id
		_set_nz(cpu, queue_id)
		cycles += 4 # LDY $0700,X; no page crossing in this six-byte slot range.
		_record_pc(source_path, 0x8066)
		cycles += 3 # BEQ $80B7, taken for the source-owned zero slot.
		_record_pc(source_path, 0x80B7)
		cpu["x"] = (int(cpu["x"]) - 1) & 0xFF
		_set_nz(cpu, int(cpu["x"]))
		cycles += 2 # DEX.
		_record_pc(source_path, 0x80B8)
		if slot_index > 0:
			cycles += 3 # BPL $8063, taken.
		else:
			cycles += 2 # BPL not taken after X wraps to $FF.
			break

	var writes: Array[Dictionary] = nmi_result.get("ram_writes", []).duplicate(true)
	cpu["a"] = 0x27
	_set_nz(cpu, 0x27)
	_record_pc(source_path, 0x80BA)
	_ram_write(ram, writes, 0x80BC, 0x00F0, 0x27)
	cycles += 5 # LDA #$27 / STA $F0.
	cpu["a"] = 0x07
	_set_nz(cpu, 0x07)
	_record_pc(source_path, 0x80BE)
	_ram_write(ram, writes, 0x80C0, 0x00F1, 0x07)
	cycles += 5 # LDA #$07 / STA $F1.
	cpu["a"] = 0x00
	_set_nz(cpu, 0x00)
	_record_pc(source_path, 0x80C2)
	_ram_write(ram, writes, 0x80C4, 0x00F2, 0x00)
	cycles += 5 # LDA #$00 / STA $F2.
	cpu["y"] = 0x08
	_set_nz(cpu, 0x08)
	_record_pc(source_path, 0x80C6)
	_ram_write(ram, writes, 0x80C8, 0x00F3, 0x08)
	cycles += 5 # LDY #$08 / STY $F3.
	cpu["pc"] = SOUND_DRIVER_EMPTY_SECOND_PASS_END_PC
	_record_pc(source_path, SOUND_DRIVER_EMPTY_SECOND_PASS_END_PC)
	var queue_head_cpu := cpu.duplicate(true)
	var mapper_events: Array[Dictionary] = nmi_result.get("mapper_bus_writes", []).duplicate(true)
	var tail := _execute_zero_mask_sound_driver_tail(ram, stack, sp, cpu,
		mapper, mapper_events, cycles, source_path, writes, pending)
	if not bool(tail.get("ok", false)):
		return _failure(String(tail.get("error", "The zero-mask sound-driver tail stopped.")))
	tail["queue_slot_ids_scanned_reverse"] = queue_ids
	tail["cpu_at_queue_head"] = queue_head_cpu
	tail["second_pass_span_sha256"] = SOUND_DRIVER_EMPTY_SECOND_PASS_SHA256
	return tail


## Follows the bank-$0C second-pass scan for a source-owned stop/control ID
## `$01` in `$0700`. It executes the ROM branch at `$806E->$80AF` and the
## handler prefix through `$834D STA $0700,X`, then stops at its observed
## post-store PC `$8350` with the callee continuation still pending.
func resume_stop_id_one_queue_clear(nmi_result: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if not bool(nmi_result.get("ok", false)) \
			or String(nmi_result.get("status", "")) != "stopped_after_sound_driver_first_queue_scan" \
			or String(nmi_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(nmi_result.get("trace_state_used", true)) \
			or bool(nmi_result.get("emulator_data_used", true)) \
			or bool(nmi_result.get("candidate_state_used", true)) \
			or bool(nmi_result.get("advances_live_route", true)):
		return _failure("The ID-$01 sound consumer requires a ROM-source NMI result, not trace or candidate state.")
	var boundary: Dictionary = nmi_result.get("cpu_at_sound_driver_boundary", {})
	var pending: Dictionary = nmi_result.get("pending_rom_call", {})
	var ram_value: Variant = nmi_result.get("ram_after", PackedByteArray())
	var stack_value: Variant = nmi_result.get("stack_page_after", PackedByteArray())
	var mapper_value: Variant = nmi_result.get("mapper_after", {})
	if not ram_value is PackedByteArray or ram_value.size() != 0x800 \
			or not stack_value is PackedByteArray or stack_value.size() != 0x100 \
			or not mapper_value is Dictionary \
			or int(boundary.get("pc", -1)) != SOUND_DRIVER_FIRST_PASS_END_PC \
			or int(boundary.get("x", -1)) != 0xFF \
			or int(ram_value[0x0700]) != 0x01 \
			or String(pending.get("source_event_id", "")).is_empty() \
			or int(pending.get("caller_pc", -1)) != 0xC449 \
			or int(pending.get("return_pc", -1)) != 0xC44C \
			or not bool(pending.get("jsr_frame_pending", false)):
		return _failure("The ID-$01 continuation needs the live `$8061` boundary and `$0700=$01` queue entry.")
	var mapper: Dictionary = mapper_value.duplicate(true)
	var registers: Variant = mapper.get("registers", [])
	if not registers is Array or registers.size() != 8 \
			or bool(mapper.get("prg_mode", true)) \
			or int(registers[6]) != 0x0C \
			or int(mapper.get("8000_prg_bank", -1)) != 0x0C:
		return _failure("The ID-$01 sound consumer no longer maps bank `$0C` at `$8000`.")
	var driver_bytes: PackedByteArray = _sources.get("sound_driver", PackedByteArray())
	if driver_bytes.size() != 0x2000 \
			or _sha256(driver_bytes.slice(0x61, SOUND_DRIVER_QUEUE_CONSUMER_SCAN_END_OFFSET)) \
			!= SOUND_DRIVER_QUEUE_CONSUMER_SCAN_SHA256 \
			or _sha256(driver_bytes.slice(0x349, SOUND_DRIVER_ID1_CLEAR_PREFIX_END_OFFSET)) \
			!= SOUND_DRIVER_ID1_CLEAR_PREFIX_SHA256:
		return _failure("The `$8061->$80B8` scan or `$8349->$8350` ID-$01 clear prefix failed its ROM source hashes.")
	var ram: PackedByteArray = ram_value.duplicate()
	for address in range(0x0701, 0x0706):
		if int(ram[address]) != 0:
			return _failure("The bounded ID-$01 path requires the other sound queue slots to be empty.")
	var stack: PackedByteArray = stack_value.duplicate()
	var cpu: Dictionary = boundary.duplicate(true)
	var sp := int(cpu.get("sp", -1))
	if sp < 2 or sp > 0xFD:
		return _failure("The `$8061` sound-driver continuation has no physical stack space for the `$80AF` JSR.")
	var pending_driver_return := int(stack[sp + 1]) | (int(stack[sp + 2]) << 8)
	if pending_driver_return != 0xC44B:
		return _failure("The pending bank-$0C driver call does not retain the checked `$C449->$8000` return frame.")
	var source_path: Array[int] = nmi_result.get("source_path", []).duplicate()
	var writes: Array[Dictionary] = nmi_result.get("ram_writes", []).duplicate(true)
	var queue_before := ram.slice(0x0700, 0x0706)
	var slots_scanned: Array[int] = []
	var cycles := 2 # LDX #$05 at $8061.
	cpu["x"] = 0x05
	_set_nz(cpu, 0x05)
	_record_pc(source_path, 0x8061)
	for slot_index in range(5, 0, -1):
		_record_pc(source_path, 0x8063)
		cpu["y"] = int(ram[0x0700 + slot_index])
		_set_nz(cpu, int(cpu["y"]))
		slots_scanned.append(int(cpu["y"]))
		cycles += 4 # LDY $0700,X.
		_record_pc(source_path, 0x8066)
		if int(cpu["y"]) != 0:
			return _failure("A nonzero queue ID above slot 0 is outside the bounded ID-$01 path.")
		cpu["pc"] = 0x80B7 # BEQ $80B7.
		cycles += 3
		_record_pc(source_path, 0x80B7)
		cpu["x"] = (int(cpu["x"]) - 1) & 0xFF
		_set_nz(cpu, int(cpu["x"]))
		cycles += 2 # DEX.
		_record_pc(source_path, 0x80B8)
		cpu["pc"] = 0x8063 # BPL $8063, taken for X=4..0.
		cycles += 3
		_record_pc(source_path, 0x8063)
	if int(cpu["x"]) != 0 or int(ram[0x0700]) != 0x01:
		return _failure("The reverse sound-slot scan did not arrive at slot 0 with ID `$01`.")
	cpu["y"] = int(ram[0x0700])
	_set_nz(cpu, int(cpu["y"]))
	slots_scanned.append(int(cpu["y"]))
	cycles += 4 # LDY $0700,X.
	_record_pc(source_path, 0x8066)
	cycles += 2 # BEQ $80B7 not taken.
	_record_pc(source_path, 0x8068)
	_compare(cpu, int(cpu["y"]), 0x72)
	cycles += 2 # CPY #$72.
	_record_pc(source_path, 0x806A)
	if (int(cpu["p"]) & 0x01) != 0:
		return _failure("ID `$01` unexpectedly selected the `$72+` sound-slot branch.")
	cycles += 2 # BCS $80B7 not taken.
	_record_pc(source_path, 0x806C)
	_compare(cpu, int(cpu["y"]), 0x31)
	cycles += 2 # CPY #$31.
	_record_pc(source_path, 0x806E)
	if (int(cpu["p"]) & 0x02) != 0:
		return _failure("ID `$01` unexpectedly selected the special `$31` initialization branch.")
	cpu["pc"] = 0x80AF # BNE $80AF.
	cycles += 3
	_record_pc(source_path, 0x80AF)
	var jsr := _stack_jsr(stack, sp, 0x8349, 0x80B1)
	if not bool(jsr.get("ok", false)):
		return _failure(String(jsr.get("error", "Could not enter the ROM ID-$01 handler.")))
	cycles += 6 # JSR $8349.
	sp = int(jsr["sp"])
	cpu["pc"] = 0x8349
	_record_pc(source_path, 0x8349)
	var stack_writes: Array[Dictionary] = [
		{"source_pc": 0x80AF, "address": 0x0100 | (sp + 2),
			"value": 0x80, "kind": "JSR_high"},
		{"source_pc": 0x80AF, "address": 0x0100 | (sp + 1),
			"value": 0xB1, "kind": "JSR_low"},
	]
	cpu["sp"] = sp
	cpu["pc"] = 0x8349
	cpu["x"] = 0
	_set_nz(cpu, 0)
	_ram_write(ram, writes, 0x8349, 0x00F5, 0x00) # STX $F5.
	cycles += 3
	cpu["pc"] = 0x834B
	cpu["a"] = 0
	_set_nz(cpu, 0)
	_record_pc(source_path, 0x834B)
	cycles += 2 # LDA #$00.
	cpu["pc"] = 0x834D
	_ram_write(ram, writes, 0x834D, 0x0700, 0x00) # STA $0700,X consumes ID $01.
	cycles += 5
	cpu["pc"] = 0x8350
	_record_pc(source_path, 0x8350)
	return {
		"ok": true,
		"kind": "rom_bank_0c_id1_sound_queue_consumer_prefix",
		"status": "stopped_after_id_one_queue_clear_at_8350",
		"completed": false,
		"source_event_id": String(nmi_result.get("source_event_id", "")) + ":8061-834D",
		"source_rom_sha256": ROM_SHA256,
		"sound_driver_source_sha256": SOUND_DRIVER_SHA256,
		"queue_consumer_scan_sha256": SOUND_DRIVER_QUEUE_CONSUMER_SCAN_SHA256,
		"id1_clear_prefix_sha256": SOUND_DRIVER_ID1_CLEAR_PREFIX_SHA256,
		"source_path": source_path,
		"queue_before": queue_before,
		"queue_after": ram.slice(0x0700, 0x0706),
		"queue_ids_scanned_reverse": slots_scanned,
		"ram_after": ram,
		"ram_writes": writes,
		"stack_page_after": stack,
		"stack_writes": stack_writes,
		"cpu_at_id_one_clear": {"pc": int(cpu["pc"]), "a": int(cpu["a"]),
			"x": int(cpu["x"]), "y": int(cpu["y"]), "p": int(cpu["p"]),
			"sp": sp, "p_known_mask": 0xFF},
		"continuation": {"pc": 0x8350, "callee": 0x8349,
			"caller_return_word": 0x80B1, "caller_return_pc": 0x80B2,
			"jsr_pending": true, "next_instruction": "DEY"},
		"cpu_cycles_from_8061_to_8350": cycles,
		"apu_writes": [],
		"apu_path_executed": false,
		"nmi_rti_reached": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"live_route_advanced": false,
	}


## Executes only the byte-checked zero-mask branch from $80CA through the
## bank-$0C driver's RTS. Nonzero $0706 or $07E9 needs the unimplemented APU
## command path and is rejected instead of being approximated.
func _execute_zero_mask_sound_driver_tail(ram_input: PackedByteArray,
		stack_input: PackedByteArray, sp_input: int, cpu_input: Dictionary,
		mapper_input: Dictionary, mapper_events_input: Array[Dictionary],
		cycles_input: int, source_path_input: Array[int], writes_input: Array[Dictionary],
		pending_call: Dictionary) -> Dictionary:
	var driver_bytes: PackedByteArray = _sources.get("sound_driver", PackedByteArray())
	if driver_bytes.size() != 0x2000 \
			or _sha256(driver_bytes.slice(0xCA, SOUND_DRIVER_ZERO_MASK_TAIL_END_OFFSET)) \
			!= SOUND_DRIVER_ZERO_MASK_TAIL_SHA256:
		return {"ok": false, "error": "The sound-driver `$80CA-$816D` source span failed its ROM hash."}
	if ram_input.size() != 0x800 or stack_input.size() != 0x100 \
			or int(cpu_input.get("pc", -1)) != SOUND_DRIVER_EMPTY_SECOND_PASS_END_PC \
			or int(cpu_input.get("x", -1)) != 0xFF \
			or int(cpu_input.get("y", -1)) != 0x08 \
			or int(ram_input[0x00F0]) != 0x27 \
			or int(ram_input[0x00F1]) != 0x07 \
			or int(ram_input[0x00F2]) != 0x00 \
			or int(ram_input[0x00F3]) != 0x08:
		return {"ok": false, "error": "The `$80CA` sound-driver continuation does not have the checked queue-head registers and pointers."}
	if int(ram_input[0x0706]) != 0:
		return {"ok": false, "error": "ROM `$80CA` has a nonzero `$0706` sound mask; its active-channel/APU path is not implemented."}
	if int(ram_input[0x07E9]) != 0:
		return {"ok": false, "error": "ROM `$8163` has a nonzero `$07E9` APU-enable latch; its disable write is not implemented."}
	var ram := ram_input.duplicate()
	var stack := stack_input.duplicate()
	var cpu: Dictionary = cpu_input.duplicate(true)
	var mapper: Dictionary = mapper_input.duplicate(true)
	var mapper_events := mapper_events_input.duplicate(true)
	var source_path := source_path_input.duplicate()
	var writes := writes_input.duplicate(true)
	var cycles := cycles_input
	var pc_cycle_offsets: Array[Dictionary] = []
	var first_80ca_cycle := -1
	var first_810c_cycle := -1

	# $80CA-$80D7: zero sound mask skips channel work and repeats eight times.
	for channel in range(8):
		if int(ram[0x0706]) != 0:
			return {"ok": false, "error": "The sound mask changed during the ROM's eight-channel scan."}
		if first_80ca_cycle < 0:
			first_80ca_cycle = cycles
		pc_cycle_offsets.append({"pc": 0x80CA, "cycles": cycles})
		cpu["pc"] = 0x80CA
		_record_pc(source_path, 0x80CA)
		cpu["a"] = int(ram[0x0706])
		_set_nz(cpu, int(cpu["a"]))
		cycles += 4 # LDA $0706.
		_record_pc(source_path, 0x80CD)
		var old_a := int(cpu["a"])
		var carry := old_a & 0x01
		cpu["a"] = old_a >> 1
		cpu["p"] = _set_nz_value(int(cpu["p"]), int(cpu["a"]))
		cpu["p"] = (int(cpu["p"]) & 0xFE) | carry
		cycles += 2 # LSR A.
		_record_pc(source_path, 0x80CE)
		if carry != 0:
			return {"ok": false, "error": "ROM `$80CE` did not take the source-proven BCC zero-mask branch."}
		cpu["pc"] = 0x80D2
		cycles += 3 # BCC $80D2, taken.
		_record_pc(source_path, 0x80D2)
		_ram_write(ram, writes, 0x80D2, 0x0706, int(cpu["a"]))
		cycles += 4 # STA $0706.
		_record_pc(source_path, 0x80D5)
		cpu["pc"] = 0x810C
		cycles += 4 # BCC $810C, taken with a page crossing.
		_record_pc(source_path, 0x810C)
		pc_cycle_offsets.append({"pc": 0x810C, "cycles": cycles})
		if first_810c_cycle < 0:
			first_810c_cycle = cycles

		# $810C-$811B advances the source stream pointers and returns to $80CA.
		cpu["p"] = int(cpu["p"]) & 0xFE # CLC.
		cycles += 2
		_record_pc(source_path, 0x810D)
		cpu["a"] = 0x10
		_set_nz(cpu, 0x10) # LDA #$10.
		cycles += 2
		_record_pc(source_path, 0x810F)
		_adc(cpu, int(ram[0x00F0]))
		cycles += 3 # ADC $F0.
		_record_pc(source_path, 0x8111)
		_ram_write(ram, writes, 0x8111, 0x00F0, int(cpu["a"]))
		cycles += 3 # STA $F0.
		_record_pc(source_path, 0x8113)
		cpu["a"] = 0x04
		_set_nz(cpu, 0x04) # LDA #$04.
		cycles += 2
		_record_pc(source_path, 0x8115)
		_adc(cpu, int(ram[0x00F2]))
		cycles += 3 # ADC $F2.
		_record_pc(source_path, 0x8117)
		_ram_write(ram, writes, 0x8117, 0x00F2, int(cpu["a"]))
		cycles += 3 # STA $F2.
		_record_pc(source_path, 0x8119)
		var next_f3 := (int(ram[0x00F3]) - 1) & 0xFF
		_ram_write(ram, writes, 0x8119, 0x00F3, next_f3)
		_set_nz(cpu, next_f3) # DEC $F3.
		cycles += 5
		_record_pc(source_path, 0x811B)
		if next_f3 != 0:
			cpu["pc"] = 0x80CA
			cycles += 4 # BNE $80CA, taken with a page crossing.
		else:
			cpu["pc"] = 0x811D
			cycles += 2 # BNE not taken.
		_record_pc(source_path, int(cpu["pc"]))
		if channel < 7 and next_f3 == 0 or channel == 7 and next_f3 != 0:
			return {"ok": false, "error": "The ROM `$80CA` sound-mask loop did not execute exactly eight source iterations."}

	# $811D-$8131 initializes the second, four-channel mask scan.
	for instruction: Dictionary in [
		{"pc": 0x811D, "a": 0x27, "cycles": 2},
		{"pc": 0x8123, "a": 0x07, "cycles": 2},
		{"pc": 0x8129, "a": 0x03, "cycles": 2},
		{"pc": 0x812D, "a": 0x11, "cycles": 2},
	]:
		cpu["pc"] = int(instruction["pc"])
		_record_pc(source_path, int(cpu["pc"]))
		cpu["a"] = int(instruction["a"])
		_set_nz(cpu, int(cpu["a"]))
		cycles += int(instruction["cycles"])
		_record_pc(source_path, int(cpu["pc"]) + 2)
		var store_address := 0
		match int(instruction["pc"]):
			0x811D: store_address = 0x00F0
			0x8123: store_address = 0x00F1
			0x8129: store_address = 0x00F2
			0x812D: store_address = 0x00F3
		_ram_write(ram, writes, int(cpu["pc"]) + 2, store_address, int(cpu["a"]))
		cycles += 3 # STA $F0/$FC, $F1/$FD, $F2, or $F3.
		if int(instruction["pc"]) == 0x811D:
			_record_pc(source_path, 0x8121)
			_ram_write(ram, writes, 0x8121, 0x00FC, int(cpu["a"]))
			cycles += 3
		elif int(instruction["pc"]) == 0x8123:
			_record_pc(source_path, 0x8127)
			_ram_write(ram, writes, 0x8127, 0x00FD, int(cpu["a"]))
			cycles += 3
	_record_pc(source_path, 0x8131)

	# $8131-$8161 examines four channel bits. Zero $0706 skips $816E/APU work.
	for channel in range(4):
		pc_cycle_offsets.append({"pc": 0x8131, "cycles": cycles})
		cpu["pc"] = 0x8131
		_record_pc(source_path, 0x8131)
		cpu["a"] = int(ram[0x0706])
		_set_nz(cpu, int(cpu["a"]))
		cycles += 4 # LDA $0706.
		_record_pc(source_path, 0x8134)
		cpu["a"] = int(cpu["a"]) & int(ram[0x00F3])
		_set_nz(cpu, int(cpu["a"]))
		cycles += 3 # AND $F3.
		_record_pc(source_path, 0x8136)
		if int(cpu["a"]) != 0:
			return {"ok": false, "error": "ROM `$8136` selected the unsupported active-channel/APU branch."}
		cpu["pc"] = 0x814C
		cycles += 3 # BEQ $814C, taken.
		_record_pc(source_path, 0x814C)
		cpu["p"] = int(cpu["p"]) & 0xFE # CLC.
		cycles += 2
		_record_pc(source_path, 0x814D)
		cpu["a"] = 0x10
		_set_nz(cpu, 0x10)
		cycles += 2 # LDA #$10.
		_record_pc(source_path, 0x814F)
		_adc(cpu, int(ram[0x00FC]))
		cycles += 3
		_record_pc(source_path, 0x8151)
		_ram_write(ram, writes, 0x8151, 0x00FC, int(cpu["a"]))
		_ram_write(ram, writes, 0x8153, 0x00F0, int(cpu["a"]))
		cycles += 6 # STA $FC / STA $F0.
		_record_pc(source_path, 0x8155)
		cpu["a"] = 0x00
		_set_nz(cpu, 0x00)
		cycles += 2 # LDA #$00.
		_record_pc(source_path, 0x8157)
		_adc(cpu, int(ram[0x00FD]))
		cycles += 3
		_record_pc(source_path, 0x8159)
		_ram_write(ram, writes, 0x8159, 0x00FD, int(cpu["a"]))
		_ram_write(ram, writes, 0x815B, 0x00F1, int(cpu["a"]))
		cycles += 6 # STA $FD / STA $F1.
		_record_pc(source_path, 0x815D)
		var old_f3 := int(ram[0x00F3])
		var next_f3 := (old_f3 << 1) & 0xFF
		cpu["p"] = _set_nz_value(int(cpu["p"]), next_f3)
		cpu["p"] = (int(cpu["p"]) & 0xFE) | ((old_f3 >> 7) & 0x01)
		_ram_write(ram, writes, 0x815D, 0x00F3, next_f3) # ASL $F3.
		cycles += 5
		_record_pc(source_path, 0x815F)
		var next_f2 := (int(ram[0x00F2]) - 1) & 0xFF
		_ram_write(ram, writes, 0x815F, 0x00F2, next_f2) # DEC $F2.
		_set_nz(cpu, next_f2)
		cycles += 5
		_record_pc(source_path, 0x8161)
		if (int(cpu["p"]) & 0x80) == 0:
			cpu["pc"] = 0x8131
			cycles += 3 # BPL $8131, taken within page.
		else:
			cpu["pc"] = 0x8163
			cycles += 2 # BPL not taken on the fourth iteration.
		_record_pc(source_path, int(cpu["pc"]))
		if channel < 3 and next_f2 == 0xFF or channel == 3 and next_f2 != 0xFF:
			return {"ok": false, "error": "The ROM `$8131` channel-mask loop did not execute exactly four source iterations."}

	pc_cycle_offsets.append({"pc": 0x8163, "cycles": cycles})
	cpu["pc"] = 0x8163
	_record_pc(source_path, 0x8163)
	cpu["a"] = int(ram[0x07E9])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 4 # LDA $07E9.
	_record_pc(source_path, 0x8166)
	if (int(cpu["p"]) & 0x02) == 0:
		return {"ok": false, "error": "ROM `$8166` selected the unsupported `$4015` disable write."}
	cpu["pc"] = 0x816D
	cycles += 3 # BEQ $816D, taken.
	_record_pc(source_path, 0x816D)
	var driver_return := _stack_rts(stack, sp_input)
	if not bool(driver_return.get("ok", false)) \
			or int(driver_return.get("pc", -1)) != 0xC44C:
		return {"ok": false, "error": "The bank-$0C driver RTS did not return to its checked `$C44C` caller."}
	cpu["sp"] = int(driver_return["sp"])
	cpu["pc"] = int(driver_return["pc"])
	cycles += 6 # RTS.
	_record_pc(source_path, 0xC44C)
	pc_cycle_offsets.append({"pc": 0xC44C, "cycles": cycles})
	if cycles != 669:
		return {"ok": false, "error": "The source-derived zero-mask sound-driver cycle count differs from 669."}
	var caller_return_cpu := cpu.duplicate(true)
	var wrapper := _execute_special_nmi_wrapper_tail(ram, stack, cpu, mapper,
		mapper_events, cycles, source_path, writes, pc_cycle_offsets, pending_call)
	if not bool(wrapper.get("ok", false)):
		return wrapper
	wrapper["cpu_at_sound_driver_caller_return"] = caller_return_cpu
	return wrapper


## Restores the MMC3 shadows and saved A/X/Y, then consumes the hardware NMI
## frame with the ROM's RTI. The source span is hash-bound and the return PC/P
## must match the interrupted instruction captured by the ROM-only context.
func _execute_special_nmi_wrapper_tail(ram_input: PackedByteArray,
		stack_input: PackedByteArray, cpu_input: Dictionary,
		mapper_input: Dictionary, mapper_events_input: Array[Dictionary],
		cycles_input: int, source_path_input: Array[int],
		writes_input: Array[Dictionary], pc_offsets_input: Array[Dictionary],
		pending_call: Dictionary) -> Dictionary:
	var nmi_bytes: PackedByteArray = _sources.get("nmi_service", PackedByteArray())
	if nmi_bytes.size() != 82 \
			or _sha256(nmi_bytes.slice(0x2B, 0x52)) != SPECIAL_NMI_WRAPPER_TAIL_SHA256:
		return {"ok": false, "error": "The fixed-bank `$C44C-$C471` NMI wrapper tail failed its ROM hash."}
	if ram_input.size() != 0x800 or stack_input.size() != 0x100 \
			or int(cpu_input.get("pc", -1)) != 0xC44C \
			or int(cpu_input.get("sp", -1)) != int(pending_call.get("nmi_entry_sp", -2)):
		return {"ok": false, "error": "The `$C44C` wrapper tail lacks the returned sound-driver CPU/stack state."}
	var nmi_frame: Variant = pending_call.get("nmi_frame", {})
	if not nmi_frame is Dictionary:
		return {"ok": false, "error": "The NMI wrapper return lacks its ROM-source interrupted PC/P receipt."}
	var ram := ram_input.duplicate()
	var stack := stack_input.duplicate()
	var cpu: Dictionary = cpu_input.duplicate(true)
	var mapper: Dictionary = mapper_input.duplicate(true)
	var source_path := source_path_input.duplicate()
	var writes := writes_input.duplicate(true)
	var mapper_events := mapper_events_input.duplicate(true)
	var pc_offsets := pc_offsets_input.duplicate(true)
	var cycles := cycles_input
	var registers: Variant = mapper.get("registers", [])
	if not registers is Array or registers.size() != 8:
		return {"ok": false, "error": "The `$C44C` wrapper cannot restore an incomplete MMC3 register image."}

	# $C44C-$C466 restores MMC3 R6, R7, and the saved command shadow.
	_record_pc(source_path, 0xC44C)
	cpu["pc"] = 0xC44C
	cpu["a"] = int(ram[0x0022])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3 # LDA $22.
	_record_pc(source_path, 0xC44E)
	cpu["a"] = (int(cpu["a"]) | 0x06) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	cycles += 2 # ORA #$06.
	_record_pc(source_path, 0xC450)
	_mapper_write(mapper, mapper_events, 0xC450, 0x8000, int(cpu["a"]))
	cycles += 4 # STA $8000.
	_record_pc(source_path, 0xC453)
	cpu["a"] = int(ram[0x0024])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3 # LDA $24.
	_record_pc(source_path, 0xC455)
	_mapper_write(mapper, mapper_events, 0xC455, 0x8001, int(cpu["a"]))
	cycles += 4 # STA $8001.
	_record_pc(source_path, 0xC458)
	cpu["a"] = int(ram[0x0022])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3 # LDA $22.
	_record_pc(source_path, 0xC45A)
	cpu["a"] = (int(cpu["a"]) | 0x07) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	cycles += 2 # ORA #$07.
	_record_pc(source_path, 0xC45C)
	_mapper_write(mapper, mapper_events, 0xC45C, 0x8000, int(cpu["a"]))
	cycles += 4 # STA $8000.
	_record_pc(source_path, 0xC45F)
	cpu["a"] = int(ram[0x0025])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3 # LDA $25.
	_record_pc(source_path, 0xC461)
	_mapper_write(mapper, mapper_events, 0xC461, 0x8001, int(cpu["a"]))
	cycles += 4 # STA $8001.
	_record_pc(source_path, 0xC464)
	cpu["a"] = int(ram[0x0023])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3 # LDA $23.
	_record_pc(source_path, 0xC466)
	_mapper_write(mapper, mapper_events, 0xC466, 0x8000, int(cpu["a"]))
	cycles += 4 # STA $8000.
	var restored_registers: Array = mapper["registers"]
	if int(restored_registers[6]) != int(ram[0x0024]) \
			or int(restored_registers[7]) != int(ram[0x0025]) \
			or int(mapper.get("command", -1)) != int(ram[0x0023]):
		return {"ok": false, "error": "The `$C44C-$C466` wrapper did not restore MMC3 R6/R7/command shadows."}
	if int(mapper.get("known_register_mask", 0xFF)) != 0xFF:
		return {"ok": false, "error": "ROM NMI writes did not make all eight MMC3 register values known before RTI."}

	# $C469-$C471 restores A/Y/X scratch and shifts the shared NMI flag back.
	_record_pc(source_path, 0xC469)
	cpu["y"] = int(ram[0x003E])
	_set_nz(cpu, int(cpu["y"]))
	cycles += 3 # LDY $3E.
	_record_pc(source_path, 0xC46B)
	cpu["x"] = int(ram[0x003D])
	_set_nz(cpu, int(cpu["x"]))
	cycles += 3 # LDX $3D.
	_record_pc(source_path, 0xC46D)
	cpu["a"] = int(ram[0x003C])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3 # LDA $3C.
	_record_pc(source_path, 0xC46F)
	var old_3b := int(ram[0x003B])
	var shifted_3b := old_3b >> 1
	cpu["p"] = _set_nz_value(int(cpu["p"]), shifted_3b)
	cpu["p"] = (int(cpu["p"]) & 0xFE) | (old_3b & 0x01)
	_ram_write(ram, writes, 0xC46F, 0x003B, shifted_3b)
	cycles += 5 # LSR $3B.
	_record_pc(source_path, 0xC471)
	var rti := _stack_rti(stack, int(cpu["sp"]))
	if not bool(rti.get("ok", false)):
		return {"ok": false, "error": String(rti.get("error", "The ROM NMI RTI failed."))}
	var expected_sp := (int(pending_call.get("nmi_entry_sp", -3)) + 3) & 0xFF
	if int(rti.get("pc", -1)) != int(nmi_frame.get("interrupted_pc", -2)) \
			or int(rti.get("p", -1)) != int(nmi_frame.get("interrupted_p", -2)) \
			or int(rti.get("sp", -1)) != expected_sp:
		return {"ok": false, "error": "The ROM `$C471 RTI` did not restore the source-owned interrupted PC/P/SP."}
	cpu["pc"] = int(rti["pc"])
	cpu["p"] = int(rti["p"])
	cpu["sp"] = int(rti["sp"])
	cycles += 6 # RTI.
	_record_pc(source_path, int(cpu["pc"]))
	pc_offsets.append({"pc": 0xC471, "cycles": cycles - 6})
	pc_offsets.append({"pc": int(cpu["pc"]), "cycles": cycles})
	if int(ram[0x003B]) != int(pending_call.get("interrupted_3b", -1)):
		return {"ok": false, "error": "The `$C421/$C46F` NMI flag rotation did not restore `$003B`."}
	return {
		"ok": true,
		"status": "returned_from_special_nmi_to_interrupted_pc",
		"completed": true,
		"source_event_id": String(pending_call.get("source_event_id", "")) + ":C44C-C472",
		"source_rom_sha256": ROM_SHA256,
		"sound_driver_source_sha256": SOUND_DRIVER_SHA256,
		"zero_mask_tail_span_sha256": SOUND_DRIVER_ZERO_MASK_TAIL_SHA256,
		"nmi_wrapper_tail_span_sha256": SPECIAL_NMI_WRAPPER_TAIL_SHA256,
		"source_path": source_path,
		"ram_after": ram,
		"ram_writes": writes,
		"stack_page_after": stack,
		"cpu_after_nmi_rti": cpu,
		"mapper_after": mapper,
		"mapper_bus_writes": mapper_events,
		"pending_rom_call": pending_call.duplicate(true),
		"cpu_cycles_from_8061": cycles,
		"pc_cycle_offsets_from_8061": pc_offsets,
		"apu_writes": [],
		"queue_data_0706_read": true,
		"sound_driver_rts_reached": true,
		"nmi_rti_reached": true,
		"nmi_stack_frame_restored": true,
		"live_route_advanced": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
	}
func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"error": error_message,
		"rom_sha256": ROM_SHA256,
		"executes_general_6502": false,
		"executes_special_nmi_through_sound_driver_first_queue_scan": true,
		"sound_driver_entry_pc": 0x8000,
		"sound_driver_prefix_end_pc": SOUND_DRIVER_FIRST_PASS_END_PC,
		"can_resume_stop_id_one_queue_clear": true,
		"stop_id_one_queue_clear_end_pc": 0x8350,
		"stop_id_one_queue_clear_completes_sound_driver": false,
		"empty_slot_second_pass_end_pc": SOUND_DRIVER_EMPTY_SECOND_PASS_END_PC,
		"empty_slot_second_pass_span_sha256": SOUND_DRIVER_EMPTY_SECOND_PASS_SHA256,
		"zero_mask_tail_end_pc": 0x816D,
		"zero_mask_tail_span_sha256": SOUND_DRIVER_ZERO_MASK_TAIL_SHA256,
		"can_resume_empty_sound_slots_to_queue_head": true,
		"executes_zero_mask_sound_driver_to_caller_return": true,
		"sound_driver_sha256": SOUND_DRIVER_SHA256,
		"executes_sound_driver_rts": true,
		"executes_special_nmi_rti": true,
		"requires_source_owned_context": true,
		"runtime_rom_dependency": false,
		"runtime_emulator_dependency": false,
		"advances_live_route": false,
	}


## Derive only the converged $003B byte before the hash-bound frame-8 NMI.
## The accepted selector clock supplies 14 completed prior NMI/IRQ events;
## both ROM wrappers apply f(x)=(x>>2)|$40, which maps every possible input
## byte to $55 after four services. This does not execute or stand in for the
## handlers' other CPU, RAM, mapper, PPU, or APU effects.
func derive_pre_candidate_interrupt_counter_receipt(clock_status: Dictionary,
		interrupt_events: Array[Dictionary], candidate_event: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "error": error_message}
	if not bool(clock_status.get("ok", false)) \
			or String(clock_status.get("source_rom_sha256", "")) != SELECTOR_CLOCK_ROM_SHA256 \
			or String(clock_status.get("input_route_sha256", "")) != SELECTOR_CLOCK_INPUT_SHA256 \
			or String(clock_status.get("source_model_sha256", "")) != SELECTOR_CLOCK_MODEL_SHA256 \
			or bool(clock_status.get("runtime_rom_dependency", true)) \
			or bool(clock_status.get("runtime_emulator_dependency", true)):
		return {"ok": false, "error": "Counter convergence requires the audited ROM/input selector clock."}
	if not _wrapper_counter_bytes_match_rom():
		return {"ok": false, "error": "NMI/IRQ wrapper instructions no longer match the checked ROM source bytes."}
	if String(candidate_event.get("kind", "")) != "NMI" \
			or int(candidate_event.get("frame_offset", -1)) != 8 \
			or String(candidate_event.get("pc_before", "")) != "$A15B" \
			or String(candidate_event.get("vector_pc", "")) != "$C500" \
			or String(candidate_event.get("return_pc", "")) != "$A15B":
		return {"ok": false, "error": "Counter convergence candidate is not the frame-8 `$A15B` NMI."}
	var candidate_cycle := int(candidate_event.get("elapsed_cycle", -1))
	if candidate_cycle < 0 or interrupt_events.size() != 15:
		return {"ok": false, "error": "Selector clock event count/candidate cycle is incomplete."}
	var prior_service_count := 0
	var prior_nmi_count := 0
	var prior_irq_count := 0
	var previous_return_cycle := -1
	var candidate_seen := false
	for event in interrupt_events:
		var kind := String(event.get("kind", ""))
		var start_cycle := int(event.get("elapsed_cycle", -1))
		var return_cycle := int(event.get("return_cycle", -1))
		if kind == String(candidate_event.get("kind", "")) \
				and int(event.get("frame_offset", -1)) == int(candidate_event.get("frame_offset", -2)) \
				and start_cycle == candidate_cycle:
			if event != candidate_event:
				return {"ok": false, "error": "Candidate event differs from the selector clock event list."}
			candidate_seen = true
			break
		if kind not in ["NMI", "IRQ"] or start_cycle < 0 or return_cycle <= start_cycle \
				or return_cycle > candidate_cycle or start_cycle < previous_return_cycle \
				or String(event.get("pc_before", "")) != String(event.get("return_pc", "")):
			return {"ok": false, "error": "A prior selector interrupt is malformed or overlaps the candidate."}
		var expected_vector := "$C500" if kind == "NMI" else "$C506"
		if String(event.get("vector_pc", "")) != expected_vector:
			return {"ok": false, "error": "A prior selector interrupt has an unsupported ROM vector."}
		prior_service_count += 1
		if kind == "NMI":
			prior_nmi_count += 1
		else:
			prior_irq_count += 1
		previous_return_cycle = return_cycle
	if not candidate_seen or prior_service_count != 14 \
			or prior_nmi_count != 7 or prior_irq_count != 7 \
			or String(interrupt_events[13].get("kind", "")) != "IRQ":
		return {"ok": false, "error": "The frame-8 candidate must follow 7 completed NMI and 7 completed IRQ services."}
	var converged_value := -1
	for initial_value in range(0x100):
		var value := initial_value
		for _service_index in range(prior_service_count):
			value = (value >> 2) | 0x40
		if converged_value < 0:
			converged_value = value
		elif value != converged_value:
			return {"ok": false, "error": "The prior ROM wrapper sequence does not converge independently of its initial byte."}
	if converged_value != 0x55:
		return {"ok": false, "error": "ROM interrupt history converged to an unexpected `$003B` value."}
	return {
		"ok": true,
		"kind": "rom_wrapper_interrupt_counter_convergence",
		"source_rom_sha256": ROM_SHA256,
		"source_model_sha256": SELECTOR_CLOCK_MODEL_SHA256,
		"input_route_sha256": SELECTOR_CLOCK_INPUT_SHA256,
		"candidate_source_event": candidate_event.duplicate(true),
		"prior_completed_nmi_count": prior_nmi_count,
		"prior_completed_irq_count": prior_irq_count,
		"prior_completed_service_count": prior_service_count,
		"initial_counter_value_known": false,
		"convergence_after_services": 4,
		"converged_counter_value": converged_value,
		"known_bit_writes": [{"address": 0x003B, "known_mask": 0xFF,
			"known_value": converged_value, "source_pc": 0xC4AD}],
		"wrapper_source_spans": ["$C421-$C472", "$C478-$C4AD"],
		"handlers_executed": false,
		"other_interrupt_effects_executed": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"physical_nes_timing_proven": false,
		"advances_live_route": false,
	}


## Derive the sound driver's `$003A` input from reset/boot zeroing and the
## ROM-stepper's prior special-NMI calls. This does not execute the candidate NMI.
func derive_pre_candidate_sound_frame_counter_receipt(reset_receipt: Dictionary,
		history_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	if not bool(reset_receipt.get("ok", false)) \
			or String(reset_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(reset_receipt.get("trace_state_used", true)) \
			or bool(reset_receipt.get("emulator_data_used", true)):
		return _failure("`$003A` derivation requires the ROM-only cold-reset receipt.")
	if String(history_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(history_receipt.get("source_stepper_sha256", "")) != "233a721c91b17b56e3527bfc336ab47d020186b44a7da15f322224aa674e493a" \
			or String(history_receipt.get("input_route_sha256", "")) != SELECTOR_CLOCK_INPUT_SHA256 \
			or int(history_receipt.get("candidate_source_frame", -1)) != 7266 \
			or int(history_receipt.get("increment_source_pc", -1)) != 0xA135 \
			or int(history_receipt.get("increment_prg_bank", -1)) != 2 \
			or int(history_receipt.get("increment_count", -1)) != 7255 \
			or int(history_receipt.get("unexpected_writer_count", -1)) != 0 \
			or bool(history_receipt.get("trace_state_used", true)) \
			or bool(history_receipt.get("emulator_data_used", true)) \
			or bool(history_receipt.get("candidate_state_used", true)):
		return _failure("`$003A` history is not the audited ROM/input-bound source-stepper result.")
	var reset_writes: Variant = reset_receipt.get("ram_writes", [])
	if not reset_writes is Array:
		return _failure("Cold-reset receipt has no RAM write list.")
	var reset_zero_proven := false
	for write_variant in reset_writes:
		if write_variant is Dictionary \
				and int(write_variant.get("address", -1)) == 0x003A \
				and int(write_variant.get("value", -1)) == 0 \
				and int(write_variant.get("source_pc", -1)) == 0xC670:
			reset_zero_proven = true
			break
	if not reset_zero_proven:
		return _failure("Cold-reset receipt does not prove the `$C670` zero write to `$003A`.")
	var initializers: Variant = history_receipt.get("initialization_writes", [])
	if not initializers is Array or initializers.size() != 2:
		return _failure("Source history does not contain both `$003A` initialization writes.")
	var expected_initializers := [
		{"source_frame": 4, "source_pc": 0xC670, "prg_bank": 30,
			"address": 0x003A, "value": 0},
		{"source_frame": 6, "source_pc": 0xA238, "prg_bank": 2,
			"address": 0x003A, "value": 0},
	]
	for index in range(expected_initializers.size()):
		var actual_variant: Variant = initializers[index]
		if not actual_variant is Dictionary:
			return _failure("`$003A` initialization history contains a malformed write.")
		var expected: Dictionary = expected_initializers[index]
		for field: String in expected:
			if int(actual_variant.get(field, -1)) != int(expected[field]):
				return _failure("`$003A` initialization write %d differs at `%s`." % [index, field])
	var boot_clear: PackedByteArray = _sources.get("bank2_boot_counter_clear", PackedByteArray())
	var expected_boot_clear := PackedByteArray([
		0xA9, 0x00, 0xA0, 0x5A, 0x99, 0xE0, 0xFF, 0xC8, 0xD0, 0xFA,
	])
	if boot_clear != expected_boot_clear or ((0xFFE0 + 0x5A) & 0xFFFF) != 0x003A:
		return _failure("Bank-$02 `$A238` does not source-prove the boot zero write to `$003A`.")
	var bank2_setup: PackedByteArray = _sources.get("bank2_setup", PackedByteArray())
	var expected_nmi_tail := PackedByteArray([
		0x18, 0xA5, 0xE1, 0x69, 0x83, 0x85, 0xE1, 0xA5, 0xE2, 0x69, 0x0D,
		0x85, 0xE2, 0xA5, 0xE3, 0x69, 0x11, 0x85, 0xE3, 0xA9, 0x00, 0x85,
		0x46, 0x85, 0x47, 0xA5, 0x1B, 0x09, 0x80, 0x85, 0x1B, 0xE6, 0x3A, 0x60,
	])
	if bank2_setup.slice(0xA116 - 0xA000, 0xA138 - 0xA000) != expected_nmi_tail:
		return _failure("Bank-$02 `$A116-$A137` no longer proves A117-to-A135 fallthrough and `INC $003A`.")
	var increment_runs: Variant = history_receipt.get("increment_frame_runs_inclusive", [])
	if not increment_runs is Array or increment_runs.is_empty():
		return _failure("`$003A` increment history has no source-frame ranges.")
	var last_increment_frame := -1
	for run_variant in increment_runs:
		if not run_variant is Array or run_variant.size() != 2:
			return _failure("`$003A` increment history contains a malformed source-frame range.")
		last_increment_frame = int(run_variant[1])
	if last_increment_frame != 7265:
		return _failure("The final pre-candidate `$003A` increment is not on source frame 7265.")
	var value := (int(initializers[1].get("value", -1)) \
			+ int(history_receipt["increment_count"])) & 0xFF
	if value != 0x57:
		return _failure("ROM-derived `$003A` counter does not resolve to the expected modulo-$100 value.")
	return {
		"ok": true,
		"kind": "rom_pre_candidate_sound_frame_counter",
		"source_rom_sha256": ROM_SHA256,
		"source_stepper_sha256": String(history_receipt["source_stepper_sha256"]),
		"input_route_sha256": SELECTOR_CLOCK_INPUT_SHA256,
		"candidate_source_frame": 7266,
		"known_bit_writes": [{"address": 0x003A, "known_mask": 0xFF,
			"known_value": value, "source_pc": 0xA135}],
		"initialization_writes": initializers.duplicate(true),
		"increment_source_pc": 0xA135,
		"increment_count": int(history_receipt["increment_count"]),
		"increment_frame_runs_inclusive": increment_runs.duplicate(true),
		"rom_source_spans": ["$C64E-$C679", "$A234-$A23D", "$A116-$A137"],
		"nmi_handler_executed_for_candidate": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"physical_nes_timing_proven": false,
	}


## Proves that the special-NMI controller routine preserves the reset-zero
## `$001C/$001D` saved samples for every serial input. A stable sample stores
## only the value it just compared equal to; four mismatches branch around both
## stores. This is a RAM invariant, not an input-trace value.
func derive_controller_latch_zero_invariant(reset_receipt: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "error": error_message}
	if not bool(reset_receipt.get("ok", false)) \
			or String(reset_receipt.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(reset_receipt.get("trace_state_used", true)) \
			or bool(reset_receipt.get("emulator_data_used", true)):
		return {"ok": false, "error": "Controller-latch invariant requires a ROM-only reset receipt."}
	var reset_addresses: Dictionary = {}
	var reset_writes: Variant = reset_receipt.get("ram_writes", [])
	if not reset_writes is Array:
		return {"ok": false, "error": "Reset receipt has no explicit RAM-write list."}
	for write_variant in reset_writes:
		if not write_variant is Dictionary:
			return {"ok": false, "error": "Reset receipt contains a malformed RAM write."}
		var write: Dictionary = write_variant
		var address := int(write.get("address", -1))
		if address in [0x001C, 0x001D] and int(write.get("value", -1)) == 0 \
				and int(write.get("source_pc", -1)) == 0xC670:
			reset_addresses[address] = true
	if not reset_addresses.has(0x001C) or not reset_addresses.has(0x001D):
		return {"ok": false, "error": "Reset receipt must zero-fill both controller sample bytes `$001C/$001D`."}
	var source: PackedByteArray = _sources.get("bank2_setup", PackedByteArray())
	if source.size() != 319 \
			or source.slice(0x00D7, 0x00E1) != PackedByteArray([
				0xA2, 0x02, 0xA9, 0x04, 0x85, 0x40, 0xB5, 0x1B, 0x85, 0x41]) \
			or source.slice(0x00FC, 0x0107) != PackedByteArray([
				0xC5, 0x41, 0xF0, 0x07, 0xC6, 0x40, 0xD0, 0xDB, 0x4C, 0x13, 0xA1]) \
			or source.slice(0x0107, 0x0113) != PackedByteArray([
				0xB5, 0x1B, 0x45, 0x3F, 0x25, 0x3F, 0x95, 0x1D, 0xA5, 0x3F, 0x95, 0x1B]) \
			or source.slice(0x0113, 0x0116) != PackedByteArray([0xCA, 0xD0, 0xC7]):
		return {"ok": false, "error": "Bank-$02 `$A0D7-$A115` controller polling instructions differ from the checked ROM path."}
	return {
		"ok": true,
		"kind": "rom_controller_saved_sample_zero_invariant",
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": String(reset_receipt.get("source_event_id", "")),
		"source_span": "bank-$02 `$A0D7-$A115`",
		"known_bit_writes": [
			{"address": 0x001C, "known_mask": 0xFF, "known_value": 0x00, "source_pc": 0xA0FC},
			{"address": 0x001D, "known_mask": 0xFF, "known_value": 0x00, "source_pc": 0xA0FC},
		],
		"invariant_reason": "The equality branch stores the saved sample unchanged; the mismatch exit skips `$A10D/$A111`. Starting from reset zero, `$001C/$001D` remain zero for any controller input.",
		"trace_state_used": false,
		"emulator_data_used": false,
		"controller_input_trace_used": false,
		"physical_nes_timing_proven": false,
		"advances_live_route": false,
	}


func _wrapper_counter_bytes_match_rom() -> bool:
	var nmi_bytes: PackedByteArray = _sources.get("nmi_service", PackedByteArray())
	var irq_bytes: PackedByteArray = _sources.get("irq_service", PackedByteArray())
	var wrapper_prefix := PackedByteArray([0x38, 0x66, 0x3B]) # SEC / ROR $003B
	var wrapper_tail := PackedByteArray([0x46, 0x3B, 0x40]) # LSR $003B / RTI
	return nmi_bytes.size() == 82 and irq_bytes.size() == 54 \
			and nmi_bytes.slice(4, 7) == wrapper_prefix \
			and irq_bytes.slice(4, 7) == wrapper_prefix \
			and nmi_bytes.slice(78, 81) == wrapper_tail \
			and irq_bytes.slice(51, 54) == wrapper_tail


## Executes only the byte-checked first pass at bank-$0C `$8000`. The caller
## supplies a complete source state after pushing the `$C449` JSR. This prefix
## reads `$0700-$0705` and `$07FC`, writes MMC3 R7 and `$07FC`, and stops before
## the second pass at `$8061`; it performs no APU access and cannot return.
func _execute_sound_driver_first_pass(ram_input: PackedByteArray,
		stack_input: PackedByteArray, sp_input: int, cpu_input: Dictionary,
		mapper_input: Dictionary) -> Dictionary:
	if not _sources.has("sound_driver"):
		return {"ok": false, "error": "Hash-checked bank-$0C sound-driver bytes are unavailable."}
	if ram_input.size() != 0x800 or stack_input.size() != 0x100 \
			or sp_input < 0 or sp_input > 0xFF:
		return {"ok": false, "error": "The sound-driver prefix requires full 2 KiB RAM and a physical 256-byte stack."}
	for register_name: String in ["pc", "a", "x", "y", "p"]:
		var cpu_value := int(cpu_input.get(register_name, -1))
		if cpu_value < 0 or cpu_value > (0xFFFF if register_name == "pc" else 0xFF):
			return {"ok": false, "error": "The sound-driver prefix requires complete byte registers and a 16-bit PC."}
	if int(cpu_input["pc"]) != 0x8000:
		return {"ok": false, "error": "The bank-$0C sound-driver must enter at `$8000`."}
	var mapper: Variant = mapper_input.duplicate(true)
	if not mapper is Dictionary:
		return {"ok": false, "error": "The sound-driver MMC3 state is missing."}
	var registers: Variant = mapper.get("registers", [])
	if not registers is Array or registers.size() != 8 \
			or bool(mapper.get("prg_mode", true)) \
			or int(mapper.get("command", -1)) < 0 \
			or (int(mapper.get("command", -1)) & 0x07) != 0x06 \
			or int(registers[6]) != 0x0C \
			or int(mapper.get("8000_prg_bank", -1)) != 0x0C:
		return {"ok": false, "error": "The sound-driver call requires bank `$0C` mapped at `$8000` through MMC3 R6."}
	if sp_input > 0xFD:
		return {"ok": false, "error": "The pending `$C449` JSR frame is incomplete on the physical stack."}
	var pending_return := int(stack_input[sp_input + 1]) \
			| (int(stack_input[sp_input + 2]) << 8)
	if pending_return != 0xC44B:
		return {"ok": false, "error": "The sound-driver prefix requires the real `$C449` JSR return word `$C44B`."}
	var ram := ram_input.duplicate()
	var stack := stack_input.duplicate()
	var cpu: Dictionary = cpu_input.duplicate(true)
	var mapper_after: Dictionary = mapper
	var ram_writes: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_path: Array[int] = []
	var driver_bytes: PackedByteArray = _sources["sound_driver"]
	var first_pass_prefix := PackedByteArray(SOUND_DRIVER_FIRST_PASS_BYTES)
	if driver_bytes.slice(0, first_pass_prefix.size()) != first_pass_prefix:
		return {"ok": false, "error": "The bank-$0C first-pass instruction bytes changed after source validation."}
	_record_pc(source_path, 0x8000)
	cpu["x"] = 0x05
	_set_nz(cpu, 0x05)
	while true:
		_record_pc(source_path, 0x8002)
		var queue_id := int(ram[0x0700 + int(cpu["x"])])
		cpu["y"] = queue_id
		_set_nz(cpu, queue_id)

		_record_pc(source_path, 0x8005)
		_compare(cpu, queue_id, 0x32)
		_record_pc(source_path, 0x8007)
		var selected_bank := -1
		var low_range := false
		if (int(cpu["p"]) & 0x01) == 0:
			# $8009-$8014: select MMC3 R7 and restore `$07FC`.
			low_range = true
			_record_pc(source_path, 0x8009)
			cpu["y"] = 0x07
			_set_nz(cpu, 0x07)
			_record_pc(source_path, 0x800B)
			_mapper_write(mapper_after, mapper_writes, 0x800B, 0x8000, 0x07)
			_record_pc(source_path, 0x800E)
			cpu["y"] = int(ram[0x07FC])
			_set_nz(cpu, int(cpu["y"]))
			_record_pc(source_path, 0x8011)
			_mapper_write(mapper_after, mapper_writes, 0x8011, 0x8001, int(cpu["y"]))
			_record_pc(source_path, 0x8014)
		else:
			_record_pc(source_path, 0x8017)
			_compare(cpu, queue_id, 0x44)
			_record_pc(source_path, 0x8019)
			if (int(cpu["p"]) & 0x01) == 0:
				selected_bank = 0x0D
			else:
				_record_pc(source_path, 0x802B)
				_compare(cpu, queue_id, 0x51)
				_record_pc(source_path, 0x802D)
				if (int(cpu["p"]) & 0x01) == 0:
					selected_bank = 0x0E
				else:
					_record_pc(source_path, 0x803F)
					_compare(cpu, queue_id, 0x5C)
					_record_pc(source_path, 0x8041)
					if (int(cpu["p"]) & 0x01) == 0:
						selected_bank = 0x0F

		if selected_bank >= 0:
			var selector_pc := 0x801B if selected_bank == 0x0D else (0x802F if selected_bank == 0x0E else 0x8043)
			var data_pc := 0x8020 if selected_bank == 0x0D else (0x8034 if selected_bank == 0x0E else 0x8048)
			var mapper_select_pc := selector_pc + 2
			var mapper_data_pc := data_pc + 2
			var saved_bank_pc := data_pc + 5
			_record_pc(source_path, selector_pc)
			cpu["y"] = 0x07
			_set_nz(cpu, 0x07)
			_record_pc(source_path, mapper_select_pc)
			_mapper_write(mapper_after, mapper_writes, mapper_select_pc, 0x8000, 0x07)
			_record_pc(source_path, data_pc)
			cpu["y"] = selected_bank
			_set_nz(cpu, selected_bank)
			_record_pc(source_path, mapper_data_pc)
			_mapper_write(mapper_after, mapper_writes, mapper_data_pc, 0x8001, selected_bank)
			_record_pc(source_path, saved_bank_pc)
			_ram_write(ram, ram_writes, saved_bank_pc, 0x07FC, selected_bank)
			var jump_pc := 0x8028 if selected_bank == 0x0D else (0x803C if selected_bank == 0x0E else 0x8050)
			_record_pc(source_path, jump_pc)
		elif not low_range:
			# `$5C+` restores the saved bank after selecting MMC3 R7.
			_record_pc(source_path, 0x8053)
			cpu["y"] = 0x07
			_set_nz(cpu, 0x07)
			_record_pc(source_path, 0x8055)
			_mapper_write(mapper_after, mapper_writes, 0x8055, 0x8000, 0x07)
			_record_pc(source_path, 0x8058)
			cpu["y"] = int(ram[0x07FC])
			_set_nz(cpu, int(cpu["y"]))
			_record_pc(source_path, 0x805B)
			_mapper_write(mapper_after, mapper_writes, 0x805B, 0x8001, int(cpu["y"]))

		_record_pc(source_path, 0x805E)
		cpu["x"] = (int(cpu["x"]) - 1) & 0xFF
		_set_nz(cpu, int(cpu["x"]))
		_record_pc(source_path, 0x805F)
		if (int(cpu["p"]) & 0x80) != 0:
			cpu["pc"] = SOUND_DRIVER_FIRST_PASS_END_PC
			break
		cpu["pc"] = 0x8002
	
	var r7 := int(mapper_after["registers"][7])
	if int(mapper_after.get("a000_prg_bank", -1)) != r7:
		return {"ok": false, "error": "The sound-driver first pass left an inconsistent MMC3 R7 mapping."}
	return {
		"ok": true,
		"status": "stopped_before_second_sound_driver_pass",
		"ram": ram,
		"stack_page": stack,
		"sp": sp_input,
		"cpu": cpu,
		"mapper": mapper_after,
		"source_path": source_path,
		"ram_writes": ram_writes,
		"mapper_bus_writes": mapper_writes,
		"queue_slots_scanned": 6,
		"apu_state_required_for_this_prefix": false,
	}


func _validate_context(context: Dictionary) -> Dictionary:
	if String(context.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "error": "Input context targets a different ROM revision."}
	var provenance: Variant = context.get("provenance", {})
	if not provenance is Dictionary \
			or String(provenance.get("kind", "")) != "rom_source_execution" \
			or String(provenance.get("source_sha256", "")) != ROM_SHA256 \
			or String(provenance.get("input_route_sha256", "")).length() != 64:
		return {"ok": false, "error": "A ROM-source execution provenance contract is required."}
	if bool(provenance.get("trace_state_used", true)) \
			or bool(provenance.get("emulator_data_used", true)) \
			or bool(provenance.get("candidate_state_used", true)):
		return {"ok": false, "error": "FCEUX or candidate state cannot be supplied as runtime NMI input."}
	var event: Variant = context.get("source_event", {})
	if not event is Dictionary \
			or String(event.get("kind", "")) != "NMI" \
			or String(event.get("source_event_id", "")).is_empty() \
			or int(event.get("entry_pc", -1)) != 0xC421 \
			or int(event.get("vector_pc", -1)) != 0xC500 \
			or int(event.get("dispatch_pc", -1)) != 0xC76E:
		return {"ok": false, "error": "A source-owned special NMI event at `$C421` is required."}
	var nmi_frame: Variant = context.get("nmi_frame", {})
	if not nmi_frame is Dictionary:
		return {"ok": false, "error": "The NMI interrupt stack frame is missing."}
	var cpu: Variant = context.get("cpu", {})
	if not cpu is Dictionary \
			or int(cpu.get("pc", -1)) != 0xC421 \
			or int(cpu.get("a", -1)) < 0 or int(cpu.get("a", -1)) > 0xFF \
			or int(cpu.get("x", -1)) < 0 or int(cpu.get("x", -1)) > 0xFF \
			or int(cpu.get("y", -1)) < 0 or int(cpu.get("y", -1)) > 0xFF \
			or int(cpu.get("p", -1)) < 0 or int(cpu.get("p", -1)) > 0xFF \
			or int(cpu.get("sp", -1)) < 0 or int(cpu.get("sp", -1)) > 0xFF:
		return {"ok": false, "error": "CPU registers at `$C421` are incomplete or outside byte range."}
	if (int(cpu["p"]) & 0x04) == 0:
		return {"ok": false, "error": "The 2A03 must have I set after accepting the NMI before `$C421`."}
	var ram: Variant = context.get("ram", PackedByteArray())
	var stack: Variant = context.get("stack_page", PackedByteArray())
	if not ram is PackedByteArray or ram.size() != 0x800:
		return {"ok": false, "error": "A 2 KiB RAM workspace is required for this bounded executor."}
	if not bool(context.get("ram_source_image_complete", true)):
		var known_values: Variant = context.get("ram_known_values", {})
		var read_contract: Variant = context.get("ram_entry_read_contract", {})
		var read_values: Variant = []
		if read_contract is Dictionary:
			read_values = read_contract.get("known_entry_ram_values", [])
		if not known_values is Dictionary or not read_contract is Dictionary \
				or String(read_contract.get("kind", "")) \
				!= "rom_source_special_nmi_zero_mask_entry_ram_read_contract" \
				or int(read_contract.get("known_entry_ram_read_count", -1)) \
				!= SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size() \
				or not read_values is Array or read_values.size() != SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size():
			return {"ok": false, "error": "Sparse RAM workspace lacks the complete source-verified NMI entry read contract."}
		var known_read_values: Dictionary = {}
		for read_variant in read_values:
			if not read_variant is Dictionary:
				return {"ok": false, "error": "Sparse RAM entry-read contract contains a malformed value."}
			var read: Dictionary = read_variant
			var address := int(read.get("address", -1))
			var value := int(read.get("known_value", -1))
			if address not in SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS \
					or int(read.get("known_mask", 0)) != 0xFF \
					or value < 0 or value > 0xFF \
					or not known_values.has(address) \
					or int(known_values[address]) != value \
					or int(ram[address]) != value:
				return {"ok": false, "error": "Sparse RAM entry byte `$%04X` is missing or conflicts with its source receipt." % address}
			known_read_values[address] = value
		if known_read_values.size() != SPECIAL_NMI_ZERO_MASK_ENTRY_RAM_READS.size():
			return {"ok": false, "error": "Sparse RAM entry-read contract contains duplicate addresses."}
	if not stack is PackedByteArray or stack.size() != 0x100:
		return {"ok": false, "error": "A 256-byte CPU stack workspace is required for this bounded executor."}
	if not bool(context.get("stack_page_complete", true)):
		var stack_offsets: Variant = context.get("stack_page_known_offsets", [])
		if not stack_offsets is Array:
			return {"ok": false, "error": "Sparse stack workspace lacks its source-known byte list."}
		for known_offset in stack_offsets:
			if int(known_offset) < 0 or int(known_offset) > 0xFF:
				return {"ok": false, "error": "Sparse stack workspace has an invalid known-byte offset."}
	var frame_sp := int(cpu["sp"])
	var expected_status := int(nmi_frame.get("interrupted_p", -1))
	var expected_pc := int(nmi_frame.get("interrupted_pc", -1))
	if expected_status < 0 or expected_status > 0xFF \
			or expected_pc < 0 or expected_pc > 0xFFFF:
		return {"ok": false, "error": "The interrupted PC/status provenance is incomplete."}
	var pushed_status := int(stack[(frame_sp + 1) & 0xFF])
	var pushed_pc := int(stack[(frame_sp + 2) & 0xFF]) \
			| (int(stack[(frame_sp + 3) & 0xFF]) << 8)
	if pushed_pc != expected_pc or pushed_status != expected_status \
			or (pushed_status & 0x30) != 0x20:
		return {"ok": false, "error": "The physical NMI stack bytes do not match the source event frame."}
	if (int(ram[0x001B]) & 0x40) == 0:
		return {"ok": false, "error": "The ROM `$C76E` special NMI route requires `$001B.6` set."}
	if (int(ram[0x003B]) & 0x80) != 0:
		return {"ok": false, "error": "The ROM `$C421` re-entry guard skips `$A000` when `$003B.7` is set."}
	if int(ram[0x0079]) == 0 or (int(ram[0x0079]) & 0x80) != 0:
		return {"ok": false, "error": "The bounded `$A0A6` path requires nonzero, nonnegative `$0079`."}
	var mapper: Variant = context.get("mapper", {})
	if not mapper is Dictionary:
		return {"ok": false, "error": "MMC3 mapper state is missing."}
	var registers: Variant = mapper.get("registers", [])
	if not registers is Array or registers.size() != 8 \
			or int(mapper.get("command", -1)) < 0 or int(mapper.get("command", -1)) > 0xFF \
			or bool(mapper.get("prg_mode", true)):
		return {"ok": false, "error": "MMC3 requires eight registers and PRG mode 0 for this `$A000` banked call."}
	var known_register_mask := int(mapper.get("known_register_mask", 0xFF))
	if (known_register_mask & 0xC0) != 0xC0:
		return {"ok": false, "error": "MMC3 R6/R7 must be source-known before the special NMI can bank-call `$A000`."}
	if int(registers[6]) != int(ram[0x0024]) \
			or int(registers[7]) != int(ram[0x0025]) \
			or int(mapper.get("a000_prg_bank", -1)) != int(registers[7]) \
			or int(mapper.get("8000_prg_bank", -1)) != int(registers[6]) \
			or int(mapper.get("command", -1)) != int(ram[0x0023]):
		return {"ok": false, "error": "MMC3 registers do not match the ROM shadow bytes `$22-$25`."}
	var ppu: Variant = context.get("ppu", {})
	if not ppu is Dictionary \
			or int(ppu.get("ctrl_shadow", -1)) != int(ram[0x0020]) \
			or int(ppu.get("mask_shadow", -1)) != int(ram[0x0021]):
		return {"ok": false, "error": "PPU control/mask shadows do not match source RAM `$20/$21`."}
	var controller: Variant = context.get("controller_inputs", {})
	if not controller is Dictionary \
			or int(controller.get("port1_buttons", -1)) < 0 \
			or int(controller.get("port1_buttons", -1)) > 0xFF \
			or int(controller.get("port2_buttons", -1)) < 0 \
			or int(controller.get("port2_buttons", -1)) > 0xFF:
		return {"ok": false, "error": "Source-owned NES controller latch bytes are required."}
	if _reverse_bits(int(controller["port2_buttons"])) != int(ram[0x001D]) \
			or _reverse_bits(int(controller["port1_buttons"])) != int(ram[0x001C]):
		return {"ok": false, "error": "The bounded NMI path requires each controller sample to match its saved state on the first ROM poll."}
	return {"ok": true}


func _execute_bank2_setup_through_rts(ram: PackedByteArray, stack: PackedByteArray,
		sp: int, cpu: Dictionary, mapper: Dictionary, controller: Dictionary,
		ppu: Dictionary, writes: Array[Dictionary], mapper_events: Array[Dictionary],
		ppu_events: Array[Dictionary], source_path: Array[int]) -> Dictionary:
	# The checked $A000 path drains the source packet buffer before reaching the
	# positive-$79 branch and ROM's LDA #$04 / STA $78 at $A0A4-$A0A6.
	var read_count := 0
	var a := 0
	var x := 0
	var y := 0
	var p := int(cpu.get("p", 0x20))
	var pc := 0xA000
	_record_pc(source_path, pc)
	a = 0
	_ppu_write(ppu, ppu_events, 0xA002, 0x2003, a)
	a = 2
	_ppu_events_add(ppu_events, 0xA007, 0x4014, a, {"page": 0x02, "oam_bytes": ram.slice(0x0200, 0x0300)})
	var queue_result := _execute_a000_ppu_packet_queue(ram, ppu, writes,
		ppu_events, source_path)
	if not bool(queue_result.get("ok", false)):
		return queue_result
	a = int(ram[0x0021])
	p = _set_nz_value(p, a)
	_ppu_write(ppu, ppu_events, 0xA05F, 0x2001, a)
	a = int(ram[0x0079])
	p = _set_nz_value(p, a)
	if (a & 0x80) != 0 or a == 0:
		return {"ok": false, "error": "The A000 alternate-scroll/zero-preset paths are outside this bounded `$A0A6` branch."}
	for iteration in range(2):
		var old_scroll := int(ram[0x0020])
		p = (p & 0xFE) | (old_scroll & 0x01)
		ram[0x0020] = old_scroll >> 1
		p = _set_nz_value(p, int(ram[0x0020]))
		_ram_write(ram, writes, 0xA073 + iteration * 2, 0x0020, int(ram[0x0020]))
	a = int(ram[0x0045])
	var carry := a & 1
	a >>= 1
	p = (p & 0xFE) | carry
	p = _set_nz_value(p, a)
	var rol_scroll_old := int(ram[0x0020])
	var rolled_out := (rol_scroll_old >> 7) & 0x01
	ram[0x0020] = ((rol_scroll_old << 1) | carry) & 0xFF
	p = (p & 0xFE) | rolled_out
	p = _set_nz_value(p, int(ram[0x0020]))
	_ram_write(ram, writes, 0xA07A, 0x0020, int(ram[0x0020]))
	a = int(ram[0x007B])
	carry = a & 1
	a >>= 1
	p = (p & 0xFE) | carry
	p = _set_nz_value(p, a)
	rol_scroll_old = int(ram[0x0020])
	rolled_out = (rol_scroll_old >> 7) & 0x01
	ram[0x0020] = ((rol_scroll_old << 1) | carry) & 0xFF
	p = (p & 0xFE) | rolled_out
	p = _set_nz_value(p, int(ram[0x0020]))
	_ram_write(ram, writes, 0xA07F, 0x0020, int(ram[0x0020]))
	_ppu_write(ppu, ppu_events, 0xA083, 0x2000, int(ram[0x0020]))
	_ppu_write(ppu, ppu_events, 0xA088, 0x2005, int(ram[0x007A]))
	x = (int(ram[0x0044]) - 1) & 0xFF
	_set_nz_value(p, x)
	_ppu_write(ppu, ppu_events, 0xA08E, 0x2005, x)
	y = 0x16
	_set_nz_value(p, y)
	_record_pc(source_path, 0xA093)
	var nested_jsr := _stack_jsr(stack, sp, 0xA1CB, 0xA095)
	if not bool(nested_jsr.get("ok", false)):
		return nested_jsr
	sp = int(nested_jsr["sp"])
	for helper_pc: int in [0xA1CB, 0xA1CD, 0xA1CF, 0xA1D1, 0xA1D4, 0xA1D7,
			0xA1D9, 0xA1DB, 0xA1DD, 0xA1E0, 0xA1E3]:
		_record_pc(source_path, helper_pc)
	var r0_index := (0x0078 + y) & 0x07FF
	x = int(ram[r0_index])
	a = int(ram[0x0022])
	_mapper_write(mapper, mapper_events, 0xA1D1, 0x8000, a | 0x00)
	_mapper_write(mapper, mapper_events, 0xA1D4, 0x8001, x)
	var r1_index := (0x0079 + y) & 0x07FF
	x = int(ram[r1_index])
	_mapper_write(mapper, mapper_events, 0xA1DD, 0x8000, int(ram[0x0022]) | 0x01)
	_mapper_write(mapper, mapper_events, 0xA1E0, 0x8001, x)
	var nested_rts := _stack_rts(stack, sp)
	if not bool(nested_rts.get("ok", false)) or int(nested_rts.get("pc", -1)) != 0xA096:
		return {"ok": false, "error": "ROM `$A1CB RTS` did not return to `$A096`."}
	sp = int(nested_rts["sp"])
	_record_pc(source_path, 0xA096)
	a = int(ram[0x0079])
	if a == 0:
		return {"ok": false, "error": "The `$A096` branch unexpectedly selected the zero-preset path."}
	carry = (a >> 7) & 1
	a = (a << 1) & 0xFF
	p = (p & 0xFE) | carry
	p = _set_nz_value(p, a)
	_mapper_write(mapper, mapper_events, 0xA09B, 0xC000, a)
	_mapper_write(mapper, mapper_events, 0xA09E, 0xC001, a)
	_mapper_write(mapper, mapper_events, 0xA0A1, 0xE001, a)
	a = 0x04
	p = _set_nz_value(p, a)
	_record_pc(source_path, 0xA0A4)
	_ram_write(ram, writes, 0xA0A6, 0x0078, a)
	_record_pc(source_path, 0xA0A8)

	# Continue the same ROM routine to RTS. Its later effects are needed to
	# produce a balanced $C472 receipt rather than an injected endpoint state.
	var mapper_select_pcs := [0xA0B1, 0xA0BB, 0xA0C5, 0xA0CF]
	var mapper_data_pcs := [0xA0B6, 0xA0C0, 0xA0CA, 0xA0D4]
	for register_index in range(2, 6):
		var value := int(ram[0x009C + register_index])
		_mapper_write(mapper, mapper_events, int(mapper_select_pcs[register_index - 2]),
			0x8000, int(ram[0x0022]) | register_index)
		_mapper_write(mapper, mapper_events, int(mapper_data_pcs[register_index - 2]),
			0x8001, value)
	_record_pc(source_path, 0xA0D7)
	x = 2
	a = 4
	_ram_write(ram, writes, 0xA0DB, 0x0040, a)
	var buttons: Array[int] = [int(controller["port2_buttons"]), int(controller["port1_buttons"])]
	while x > 0:
		var player_ram := 0x001B + x
		_ram_write(ram, writes, 0xA0DF, 0x0041, int(ram[player_ram]))
		_ppu_events_add(ppu_events, 0xA0E3, 0x4016, 0x01)
		_ppu_events_add(ppu_events, 0xA0E8, 0x4016, 0x00)
		var found_equal := false
		for _attempt in range(1):
			var serial := buttons[2 - x]
			var assembled := 0
			for _bit in range(8):
				var serial_bit := serial & 1
				serial >>= 1
				assembled = ((assembled << 1) | serial_bit) & 0xFF
				read_count += 1
				_ppu_events_add(ppu_events, 0xA0ED, 0x4015 + x, serial_bit)
			if assembled == int(ram[0x0041]):
				found_equal = true
				_ram_write(ram, writes, 0xA10D, 0x001D + x,
					((int(ram[player_ram]) ^ assembled) & assembled))
				_ram_write(ram, writes, 0xA111, player_ram, assembled)
				break
			_ram_write(ram, writes, 0xA100, 0x0040,
				(int(ram[0x0040]) - 1) & 0xFF)
		x -= 1
	_record_pc(source_path, 0xA116)
	var carry_rng := 0
	var rng := int(ram[0x00E1]) + 0x83
	_ram_write(ram, writes, 0xA11B, 0x00E1, rng & 0xFF)
	carry_rng = 1 if rng > 0xFF else 0
	_record_pc(source_path, 0xA117)
	rng = int(ram[0x00E2]) + 0x0D + carry_rng
	_ram_write(ram, writes, 0xA121, 0x00E2, rng & 0xFF)
	carry_rng = 1 if rng > 0xFF else 0
	_record_pc(source_path, 0xA11D)
	var final_rng_left := int(ram[0x00E3])
	rng = final_rng_left + 0x11 + carry_rng
	_ram_write(ram, writes, 0xA127, 0x00E3, rng & 0xFF)
	var final_rng_overflow := ((~(final_rng_left ^ 0x11) \
			& (final_rng_left ^ int(ram[0x00E3]))) & 0x80) != 0
	_record_pc(source_path, 0xA123)
	_ram_write(ram, writes, 0xA12B, 0x0046, 0)
	_ram_write(ram, writes, 0xA12D, 0x0047, 0)
	_ram_write(ram, writes, 0xA133, 0x001B, int(ram[0x001B]) | 0x80)
	_ram_write(ram, writes, 0xA135, 0x003A, (int(ram[0x003A]) + 1) & 0xFF)
	_record_pc(source_path, 0xA137)
	var banked_rts := _stack_rts(stack, sp)
	if not bool(banked_rts.get("ok", false)) or int(banked_rts.get("pc", -1)) != 0xC43D:
		return {"ok": false, "error": "ROM `$A137 RTS` did not return to `$C43D`."}
	p = 0x20 | (int(cpu.get("p", 0)) & 0x0C) | carry_rng
	if final_rng_overflow:
		p |= 0x40
	return {
		"ok": true, "ram": ram, "stack_page": stack, "sp": int(banked_rts["sp"]),
		"cpu": {"pc": 0xC43D, "a": a, "x": 0, "y": 0, "p": p},
		"mapper": mapper, "controller_inputs": controller, "ppu": ppu,
		"controller_reads_consumed": read_count,
		"ppu_packet_queue": queue_result,
	}


## Executes the ROM's `$A00A-$A05A` packet-buffer transfer. `$0628` is the
## queued byte count/active marker; each buffer record is a header, PPU address
## low/high pair, and payload. The verified KICK OFF palette packet is the
## `$3F00` record with a 32-byte payload. Unsupported/truncated queue layouts
## stop rather than being silently treated as an empty queue.
func _execute_a000_ppu_packet_queue(ram: PackedByteArray, ppu: Dictionary,
		writes: Array[Dictionary], ppu_events: Array[Dictionary],
		source_path: Array[int]) -> Dictionary:
	const PACKET_BUFFER_START := 0x05E8
	const PACKET_BUFFER_END_EXCLUSIVE := 0x0628
	var declared_size := int(ram[0x0628])
	_record_pc(source_path, 0xA00A)
	if declared_size == 0:
		return {"ok": true, "status": "empty_packet_queue", "packet_count": 0,
			"payload_bytes": 0, "source_bytes_consumed": 0}
	_record_pc(source_path, 0xA00F)
	if (int(ram[0x0629]) & 0x40) != 0:
		return {"ok": true, "status": "packet_queue_skipped_by_bit6", "packet_count": 0,
			"payload_bytes": 0, "source_bytes_consumed": 0}
	if declared_size >= PACKET_BUFFER_END_EXCLUSIVE - PACKET_BUFFER_START:
		return {"ok": false, "error": "ROM `$A000` packet length exceeds its `$05E8-$0627` buffer."}

	_record_pc(source_path, 0xA014)
	_ppu_write(ppu, ppu_events, 0xA016, 0x2001, 0x00)
	var cursor := 0
	var packet_count := 0
	var payload_total := 0
	while true:
		if cursor > declared_size or PACKET_BUFFER_START + cursor >= PACKET_BUFFER_END_EXCLUSIVE:
			return {"ok": false, "error": "ROM `$A000` packet buffer ended without its zero record terminator."}
		_record_pc(source_path, 0xA01B)
		var header := int(ram[PACKET_BUFFER_START + cursor])
		if header == 0:
			if cursor != declared_size:
				return {"ok": false, "error": "ROM `$A000` packet terminator differs from `$0628` byte count."}
			break
		var data_count := header
		var ctrl_value := 0x80
		if (header & 0x80) != 0:
			data_count = header & 0x3F
			ctrl_value = 0x84
			if data_count == 0:
				return {"ok": false, "error": "ROM `$A000` 256-byte packet form exceeds the verified bounded queue model."}
		if data_count < 1 or data_count > 0x7F:
			return {"ok": false, "error": "ROM `$A000` packet header has an unsupported payload length."}
		var record_end := cursor + 3 + data_count
		if record_end > declared_size:
			return {"ok": false, "error": "ROM `$A000` packet payload exceeds `$0628`'s queued length."}
		if PACKET_BUFFER_START + record_end > PACKET_BUFFER_END_EXCLUSIVE:
			return {"ok": false, "error": "ROM `$A000` packet payload escapes `$05E8-$0627`."}
		_record_pc(source_path, 0xA026)
		_ppu_write(ppu, ppu_events, 0xA026, 0x2000, ctrl_value)
		var address_high := int(ram[PACKET_BUFFER_START + cursor + 2])
		_record_pc(source_path, 0xA02A)
		_ppu_write(ppu, ppu_events, 0xA02D, 0x2006, address_high)
		var address_low := int(ram[PACKET_BUFFER_START + cursor + 1])
		_record_pc(source_path, 0xA030)
		_ppu_write(ppu, ppu_events, 0xA033, 0x2006, address_low)
		for payload_index in data_count:
			var payload_value := int(ram[PACKET_BUFFER_START + cursor + 3 + payload_index])
			var ppu_increment := 32 if (ctrl_value & 0x04) != 0 else 1
			_ppu_events_add(ppu_events, 0xA039, 0x2007, payload_value, {
				"packet_index": packet_count,
				"payload_index": payload_index,
				"ppu_address": ((address_high << 8) | address_low)
						+ payload_index * ppu_increment,
			})
		_record_pc(source_path, 0xA040)
		cursor = record_end
		packet_count += 1
		payload_total += data_count
		_record_pc(source_path, 0xA043)
	if cursor != declared_size:
		return {"ok": false, "error": "ROM `$A000` consumed a different byte count from `$0628`."}
	_ram_write(ram, writes, 0xA04A, 0x0628, 0x00)
	_ppu_write(ppu, ppu_events, 0xA04F, 0x2006, 0x3F)
	_ppu_write(ppu, ppu_events, 0xA054, 0x2006, 0x00)
	_ppu_write(ppu, ppu_events, 0xA057, 0x2006, 0x00)
	_ppu_write(ppu, ppu_events, 0xA05A, 0x2006, 0x00)
	return {"ok": true, "status": "packet_buffer_drained", "packet_count": packet_count,
		"payload_bytes": payload_total, "source_bytes_consumed": cursor,
		"ppu_address_reinitialized": true}


func _mapper_write(mapper: Dictionary, events: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	var normalized := value & 0xFF
	events.append({"source_pc": source_pc, "address": address, "value": normalized})
	var regs: Array = mapper["registers"]
	if address == 0x8000:
		mapper["command"] = normalized
		mapper["prg_mode"] = (normalized & 0x40) != 0
		mapper["chr_inversion"] = (normalized & 0x80) != 0
	elif address == 0x8001:
		var register_index := int(mapper.get("command", 0)) & 0x07
		regs[register_index] = normalized
		mapper["registers"] = regs
		mapper["known_register_mask"] = int(mapper.get("known_register_mask", 0xFF)) | (1 << register_index)
		if register_index == 6:
			mapper["8000_prg_bank"] = normalized if not bool(mapper.get("prg_mode", false)) else int(mapper.get("a000_prg_bank", -1))
		elif register_index == 7:
			mapper["a000_prg_bank"] = normalized if not bool(mapper.get("prg_mode", false)) else int(mapper.get("8000_prg_bank", -1))
	elif address == 0xC000:
		mapper["irq_latch"] = normalized
	elif address == 0xC001:
		mapper["irq_reload_requested"] = true
	elif address == 0xE000:
		mapper["irq_enabled"] = false
	elif address == 0xE001:
		mapper["irq_enabled"] = true


func _ppu_write(ppu: Dictionary, events: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	var normalized := value & 0xFF
	_ppu_events_add(events, source_pc, address, normalized)
	match address:
		0x2000:
			ppu["ctrl_shadow"] = normalized
		0x2001:
			ppu["mask_shadow"] = normalized
		0x2005:
			ppu["scroll_last"] = normalized


func _ppu_events_add(events: Array[Dictionary], source_pc: int, address: int,
		value: int, extra: Dictionary = {}) -> void:
	var event := {"source_pc": source_pc, "address": address, "value": value & 0xFF}
	for key: Variant in extra:
		event[key] = extra[key]
	events.append(event)


func _ram_write(ram: PackedByteArray, writes: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	var old_value := int(ram[address])
	var new_value := value & 0xFF
	ram[address] = new_value
	writes.append({"source_pc": source_pc, "address": address,
		"before": old_value, "value": new_value})


func _stack_jsr(stack: PackedByteArray, sp: int, target_pc: int,
		return_word: int) -> Dictionary:
	if sp < 2:
		return {"ok": false, "error": "The physical stack does not have room for a ROM JSR."}
	stack[sp] = (return_word >> 8) & 0xFF
	stack[sp - 1] = return_word & 0xFF
	return {"ok": true, "sp": sp - 2, "pc": target_pc}


func _stack_rts(stack: PackedByteArray, sp: int) -> Dictionary:
	if sp > 0xFD:
		return {"ok": false, "error": "The physical stack cannot pop a ROM RTS frame."}
	var next_sp := (sp + 1) & 0xFF
	var low := int(stack[next_sp])
	next_sp = (next_sp + 1) & 0xFF
	var high := int(stack[next_sp])
	return {"ok": true, "sp": next_sp, "pc": (((high << 8) | low) + 1) & 0xFFFF}


func _stack_rti(stack: PackedByteArray, sp: int) -> Dictionary:
	if stack.size() != 0x100 or sp > 0xFC:
		return {"ok": false, "error": "The physical stack cannot pop a ROM RTI frame."}
	var next_sp := (sp + 1) & 0xFF
	var status := int(stack[next_sp])
	var low := int(stack[(next_sp + 1) & 0xFF])
	var high := int(stack[(next_sp + 2) & 0xFF])
	return {"ok": true, "sp": (sp + 3) & 0xFF,
		"pc": ((high << 8) | low) & 0xFFFF, "p": status}


func _apply_bit(cpu: Dictionary, value: int) -> void:
	var accumulator := int(cpu["a"])
	var status := int(cpu["p"]) & 0x3D
	status |= value & 0xC0
	if (accumulator & value) == 0:
		status |= 0x02
	cpu["p"] = status


func _set_nz(cpu: Dictionary, value: int) -> void:
	cpu["p"] = _set_nz_value(int(cpu["p"]), value)


func _compare(cpu: Dictionary, left: int, right: int) -> void:
	var difference := (left - right) & 0xFF
	var status := _set_nz_value(int(cpu["p"]), difference)
	if left >= right:
		status |= 0x01
	else:
		status &= 0xFE
	cpu["p"] = status


func _adc(cpu: Dictionary, value: int) -> void:
	var left := int(cpu["a"]) & 0xFF
	var right := value & 0xFF
	var carry := int(cpu["p"]) & 0x01
	var sum := left + right + carry
	var result := sum & 0xFF
	var status := int(cpu["p"]) & 0xBE # ADC replaces C and V, then N/Z.
	if sum > 0xFF:
		status |= 0x01
	if ((~(left ^ right) & (left ^ result)) & 0x80) != 0:
		status |= 0x40
	cpu["a"] = result
	cpu["p"] = _set_nz_value(status, result)


func _set_nz_value(status: int, value: int) -> int:
	var result := status & 0x7D
	if (value & 0xFF) == 0:
		result |= 0x02
	if (value & 0x80) != 0:
		result |= 0x80
	return result


func _reverse_bits(value: int) -> int:
	var reversed := 0
	for bit_index in range(8):
		reversed = (reversed << 1) | ((value >> bit_index) & 0x01)
	return reversed


func _nmi_stack_frame_matches(stack: PackedByteArray, sp: int,
		nmi_frame: Dictionary) -> bool:
	var expected_status := int(nmi_frame.get("interrupted_p", -1))
	var expected_pc := int(nmi_frame.get("interrupted_pc", -1))
	if expected_status < 0 or expected_pc < 0:
		return false
	var current_status := int(stack[(sp + 1) & 0xFF])
	var current_pc := int(stack[(sp + 2) & 0xFF]) | (int(stack[(sp + 3) & 0xFF]) << 8)
	return current_status == expected_status and current_pc == expected_pc


func _record_pc(source_path: Array[int], pc: int) -> void:
	if source_path.is_empty() or source_path[-1] != pc:
		source_path.append(pc)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message, "trace_state_used": false,
		"emulator_data_used": false, "candidate_state_used": false,
		"advances_live_route": false}
