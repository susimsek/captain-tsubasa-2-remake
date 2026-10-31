extends RefCounted
class_name RomFreshMatchSpecialNmiExecutor
## Executes the ROM's special NMI service through the first queue-scan pass of
## the bank-$0C sound driver. It leaves the JSR to that driver pending, does
## not reach $C472, and does not advance the live route.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/manifest.json"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/"
const SOUND_DRIVER_METADATA_PATH := "res://reference/rom_extract/audio/intro_track_58.json"
const SOUND_DRIVER_SOURCE_PATH := "res://reference/rom_extract/audio/bank_8c_sound_driver.bin"
const SOUND_DRIVER_SHA256 := "8c5dbc34a2f4ea3e7f6bcc503dcfd032d7cb4474ebba0c6c0af90efffe7c7468"
const SOUND_DRIVER_FIRST_PASS_END_PC := 0x8061
const SOUND_DRIVER_FIRST_PASS_BYTES := [
	0xA2, 0x05, 0xBC, 0x00, 0x07, 0xC0, 0x32, 0xB0, 0x0E, 0xA0, 0x07, 0x8C, 0x00, 0x80,
	0xAC, 0xFC, 0x07, 0x8C, 0x01, 0x80, 0x4C, 0x5E, 0x80, 0xC0, 0x44, 0xB0, 0x10, 0xA0,
	0x07, 0x8C, 0x00, 0x80, 0xA0, 0x0D, 0x8C, 0x01, 0x80, 0x8C, 0xFC, 0x07, 0x4C, 0x5E,
	0x80, 0xC0, 0x51, 0xB0, 0x10, 0xA0, 0x07, 0x8C, 0x00, 0x80, 0xA0, 0x0E, 0x8C, 0x01,
	0x80, 0x8C, 0xFC, 0x07, 0x4C, 0x5E, 0x80, 0xC0, 0x5C, 0xB0, 0x10, 0xA0, 0x07, 0x8C,
	0x00, 0x80, 0xA0, 0x0F, 0x8C, 0x01, 0x80, 0x8C, 0xFC, 0x07, 0x4C, 0x5E, 0x80, 0xA0,
	0x07, 0x8C, 0x00, 0x80, 0xAC, 0xFC, 0x07, 0x8C, 0x01, 0x80, 0xCA, 0x10, 0xA1,
]
const SOURCE_SPANS := {
	"nmi_dispatch": {
		"file": "fixed_nmi_dispatch_C76E_C774.bin",
		"cpu_start": "$C76E", "cpu_end_exclusive": "$C775",
		"file_offset": "0x03C77E", "length": 7,
		"sha256": "d7d53b9d4b7243c6595b273e93d542e9760310c8592b5ec885b56f2a532bed86",
	},
	"nmi_service": {
		"file": "fixed_raster_nmi_service_C421_C472.bin",
		"cpu_start": "$C421", "cpu_end_exclusive": "$C473",
		"file_offset": "0x03C431", "length": 82,
		"sha256": "d02f695858c9d88a1cfadc63b71504cf467590449806820851d9feaab71b8673",
	},
	"bank2_setup": {
		"file": "bank02_nmi_irq_setup_A000_A13E.bin",
		"cpu_start": "$A000", "cpu_end_exclusive": "$A13F",
		"file_offset": "0x004010", "length": 319,
		"sha256": "89820a1c55e52fb9fcdb123eeed89945d187eaf4aaf5688d1869ffca612c5350",
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
			or sound_driver.slice(0, expected_driver_prefix.size()) != expected_driver_prefix:
		return _fail("The bank-$0C sound-driver bytes or first-pass prefix failed ROM-source checks.")
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
		"ram_writes": writes,
		"mapper_after": mapper,
		"mapper_bus_writes": mapper_events,
		"ppu_after": ppu,
		"ppu_bus_events": ppu_events,
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
			"source_event_id": String(context["source_event"]["source_event_id"]) + ":C449-8000"},
		"nmi_stack_frame_preserved": _nmi_stack_frame_matches(stack,
			int(context["cpu"]["sp"]), context["nmi_frame"]),
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"reaches_sound_driver_rts": false,
		"reaches_nmi_rti": false,
		"advances_live_route": false,
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
		"sound_driver_sha256": SOUND_DRIVER_SHA256,
		"executes_sound_driver_rts": false,
		"executes_special_nmi_rti": false,
		"requires_source_owned_context": true,
		"runtime_rom_dependency": false,
		"runtime_emulator_dependency": false,
		"advances_live_route": false,
	}


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
		return {"ok": false, "error": "A full 2 KiB source RAM image is required."}
	if not stack is PackedByteArray or stack.size() != 0x100:
		return {"ok": false, "error": "A physical 256-byte CPU stack page is required."}
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
	if int(ram[0x0628]) != 0:
		return {"ok": false, "error": "The bounded `$A000` path requires an empty `$0628` PPU packet queue."}
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
	# Exact $A000 branch: no queued PPU packets and positive $79, which reaches
	# the ROM's LDA #$04 / STA $78 at $A0A4-$A0A6.
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
	if int(ram[0x0628]) != 0:
		return {"ok": false, "error": "The A000 packet-queue path is not supported by this bounded source executor."}
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
	ram[0x00E1] = rng & 0xFF
	carry_rng = 1 if rng > 0xFF else 0
	_record_pc(source_path, 0xA117)
	rng = int(ram[0x00E2]) + 0x0D + carry_rng
	ram[0x00E2] = rng & 0xFF
	carry_rng = 1 if rng > 0xFF else 0
	_record_pc(source_path, 0xA11D)
	rng = int(ram[0x00E3]) + 0x11 + carry_rng
	var final_rng_left := int(ram[0x00E3])
	ram[0x00E3] = rng & 0xFF
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
	}


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
