extends RefCounted
class_name RomFreshMatchB0c0StreamExecutor
## Executes the first ROM command dispatched by the fresh-match $B0C0 stream.
## This is a hash-pinned semantic model, not a general 6502/PPU emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/"
const MANIFEST_FILE := ROOT + "b0c0_first_command_manifest.json"
const DISPATCH_FILE := ROOT + "bank01_match_b0c0_dispatch_B0C0_B1C9.bin"
const STREAM_FILE := ROOT + "bank01_match_b0c0_stream_B305_B328.bin"
const DATA_FILE := ROOT + "bank01_match_b0c0_data_B328_B33D.bin"
const POINTER_HELPER_FILE := ROOT + "bank01_match_b0c0_pointer_helper_B1C9_B1D3.bin"
const ARGUMENT_HELPERS_FILE := ROOT + "bank01_match_b0c0_argument_helpers_B1D3_B1E8.bin"
const RETURN_FILE := ROOT + "bank00_ppu_clear_rts_98DC_98DD.bin"
const PPU_FILL_FILE := ROOT + "bank00_ppu_fill_98EA_997A.bin"
const PPU_PACKET_READER_FILE := ROOT + "bank00_ppu_packet_reader_97B6_988A.bin"
const DISPATCH_SHA256 := "0a4c492d3977ff466d97e92106b83393028ad024d59c228ec601ab833cd0769e"
const STREAM_SHA256 := "3907025e26e2b3f305a682282af798b2d04dafd2498ab061741d49d6e7c40790"
const DATA_SHA256 := "7c0a9d06e6a511e8b5c099080e1bb21cbd56ca90f2a76907ad9e0d3a11990ca9"
const POINTER_HELPER_SHA256 := "3b45c08a076cbeea84c1ea0f88c57d0dc7785301ef1455c30d800576af1dd8a7"
const ARGUMENT_HELPERS_SHA256 := "494c973e66d6ef485a4a18aac9afe85339949bd6c4cd313a6d539fead5e25056"
const RETURN_SHA256 := "8d33f520a3c4cef80d2453aef81b612bfe1cb44c8b2025630ad38662763f13d3"
const PPU_FILL_SHA256 := "32b8c92b5020a5e3ec416b2f421baae64ee1c49a2154eb8ca4550324e7f9c18a"
const PPU_PACKET_READER_SHA256 := "c534baeaa667d97b133b1fedb4eec77aed024bb056101f93237031fb6af7eab2"
const PY65_CPU_CYCLES_TO_A503 := 4121 # Independent diagnostic execution of the pinned path.
const CLEANUP_HELPER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_cleanup_clear_task.gd")
const EXPECTED_STREAM := [
	0x0D, 0x05, 0x45, 0x21, 0x16, 0x89, 0x05, 0xA5, 0x21, 0x16, 0xBA,
	0x05, 0xA5, 0x22, 0x16, 0x89, 0x04, 0x64, 0x21, 0x0A, 0x8A,
	0x04, 0x7B, 0x21, 0x0A, 0x8A, 0x04, 0xCF, 0x21, 0x07, 0xBB,
	0x00, 0x28, 0xB3, 0x0F,
]
const DISPATCH_ENTRY_PREFIX := [
	0x84, 0xEC, 0x86, 0xED, 0xA0, 0x00, 0xB1, 0xEC, 0x0A, 0xAA,
	0xBD, 0xD7, 0xB0, 0x85, 0xE6, 0xBD, 0xD8, 0xB0, 0x85, 0xE7,
	0x6C, 0xE6, 0x00,
]
const FIRST_HANDLER := [0x20, 0xA0, 0x98, 0xA9, 0x01, 0x4C, 0xBB, 0xB1]
const POINTER_INCREMENT := [0x18, 0x65, 0xEC, 0x85, 0xEC, 0xA5, 0xED, 0x69, 0x00, 0x85, 0xED, 0x4C, 0xC4, 0xB0]

var error_message := ""
var _configured := false
var _dispatcher := PackedByteArray()
var _stream := PackedByteArray()
var _packet_data := PackedByteArray()
var _pointer_helper := PackedByteArray()
var _argument_helpers := PackedByteArray()
var _ppu_clear_rts := PackedByteArray()
var _ppu_fill := PackedByteArray()
var _ppu_packet_reader := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_dispatcher = FileAccess.get_file_as_bytes(DISPATCH_FILE)
	_stream = FileAccess.get_file_as_bytes(STREAM_FILE)
	_packet_data = FileAccess.get_file_as_bytes(DATA_FILE)
	_pointer_helper = FileAccess.get_file_as_bytes(POINTER_HELPER_FILE)
	_argument_helpers = FileAccess.get_file_as_bytes(ARGUMENT_HELPERS_FILE)
	_ppu_clear_rts = FileAccess.get_file_as_bytes(RETURN_FILE)
	_ppu_fill = FileAccess.get_file_as_bytes(PPU_FILL_FILE)
	_ppu_packet_reader = FileAccess.get_file_as_bytes(PPU_PACKET_READER_FILE)
	if _dispatcher.size() != 0x109 or _sha256(_dispatcher) != DISPATCH_SHA256:
		return _fail("ROM $B0C0 dispatcher/helper span failed its pinned size/hash check.")
	if _stream.size() != EXPECTED_STREAM.size() or _sha256(_stream) != STREAM_SHA256:
		return _fail("ROM $B305 command stream failed its pinned size/hash check.")
	if _packet_data.size() != 0x15 or _sha256(_packet_data) != DATA_SHA256:
		return _fail("ROM $B328 PPU packet data failed its pinned size/hash check.")
	if _pointer_helper.size() != 0x0A or _sha256(_pointer_helper) != POINTER_HELPER_SHA256:
		return _fail("ROM $B1C9 packet-pointer helper failed its pinned size/hash check.")
	if _argument_helpers.size() != 0x15 or _sha256(_argument_helpers) != ARGUMENT_HELPERS_SHA256:
		return _fail("ROM $B1D3 argument helpers failed their pinned size/hash check.")
	if _ppu_clear_rts != PackedByteArray([0x60]) or _sha256(_ppu_clear_rts) != RETURN_SHA256:
		return _fail("ROM $98DC shared return byte failed its pinned size/hash check.")
	if _ppu_fill.size() != 0x90 or _sha256(_ppu_fill) != PPU_FILL_SHA256:
		return _fail("ROM $98EA PPU fill path failed its pinned size/hash check.")
	if _ppu_packet_reader.size() != 0xD4 or _sha256(_ppu_packet_reader) != PPU_PACKET_READER_SHA256:
		return _fail("ROM $97B6 packet-reader path failed its pinned size/hash check.")
	if not _bytes_match(_dispatcher, 0, DISPATCH_ENTRY_PREFIX) \
			or not _bytes_match(_dispatcher, 0x31, [0xA4, 0xB1]) \
			or not _bytes_match(_dispatcher, 0xE4, FIRST_HANDLER) \
			or not _bytes_match(_dispatcher, 0xFB, POINTER_INCREMENT) \
			or not _bytes_match(_stream, 0, EXPECTED_STREAM) \
			or not _bytes_match(_pointer_helper, 0, [0xA0, 0x02, 0xB1, 0xEC, 0xAA,
				0x88, 0xB1, 0xEC, 0xA8, 0x60]) \
			or not _bytes_match(_argument_helpers, 0, [0xC8, 0xB1, 0xEC, 0x85, 0xE6,
				0xC8, 0xB1, 0xEC, 0x85, 0xE7, 0x60, 0xC8, 0xB1, 0xEC, 0x85,
				0xE9, 0xC8, 0xB1, 0xEC, 0xC8, 0x60]) \
			or not _bytes_match(_ppu_fill, 0, [0x85, 0xEB, 0xA5, 0x4A, 0x05, 0x4B,
				0xF0, 0x3A, 0x84, 0xE8, 0x86, 0xE9]) \
			or not _bytes_match(_ppu_packet_reader, 0, [0xA9, 0x00, 0x85, 0xE9, 0xA5, 0x4A,
				0x05, 0x4B, 0xF0, 0x59, 0xA9, 0x00, 0x85, 0xEB, 0x84, 0xE6, 0x86, 0xE7]) \
			or not _bytes_match(_packet_data, 0, [0x01, 0x44, 0x21, 0x88, 0x01, 0x5B,
				0x21, 0x90, 0x01, 0xA4, 0x22, 0x8E, 0x01, 0xBB, 0x22, 0x93,
				0x42, 0x33, 0x22, 0x91, 0x8F]):
		return _fail("ROM stream dispatch, first handler, or first command bytes differ from the pinned path.")
	var manifest_file := FileAccess.open(MANIFEST_FILE, FileAccess.READ)
	if manifest_file == null:
		return _fail("The B0C0 source manifest is missing.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary or String(parsed.get("schema", "")) != "ct2-fresh-match-b0c0-stream-v2":
		return _fail("The B0C0 source manifest is malformed or has an unexpected schema.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The B0C0 source manifest targets another ROM revision.")
	var entries: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries[String(entry.get("file", ""))] = entry
	if not _manifest_span_matches(entries, DISPATCH_FILE.get_file(), "$B0C0", "$B1C9", "0x0030D0", DISPATCH_SHA256, _dispatcher) \
			or not _manifest_span_matches(entries, STREAM_FILE.get_file(), "$B305", "$B328", "0x003315", STREAM_SHA256, _stream) \
			or not _manifest_span_matches(entries, DATA_FILE.get_file(), "$B328", "$B33D", "0x003338", DATA_SHA256, _packet_data) \
			or not _manifest_span_matches(entries, POINTER_HELPER_FILE.get_file(), "$B1C9", "$B1D3", "0x0031D9", POINTER_HELPER_SHA256, _pointer_helper) \
			or not _manifest_span_matches(entries, ARGUMENT_HELPERS_FILE.get_file(), "$B1D3", "$B1E8", "0x0031E3", ARGUMENT_HELPERS_SHA256, _argument_helpers) \
			or not _manifest_span_matches(entries, RETURN_FILE.get_file(), "$98DC", "$98DD", "0x0018EC", RETURN_SHA256, _ppu_clear_rts) \
			or not _manifest_span_matches(entries, PPU_FILL_FILE.get_file(), "$98EA", "$997A", "0x0018FA", PPU_FILL_SHA256, _ppu_fill) \
			or not _manifest_span_matches(entries, PPU_PACKET_READER_FILE.get_file(), "$97B6", "$988A", "0x0017C6", PPU_PACKET_READER_SHA256, _ppu_packet_reader):
		return _fail("The B0C0 manifest span provenance differs from the checked source files.")
	var cleanup: Variant = CLEANUP_HELPER_SCRIPT.new()
	if not cleanup.configure_from_project_sources():
		return _fail("ROM $98A0 PPU-clear helper source failed verification: " + cleanup.error_message)
	_configured = true
	return true


## Applies stream command $0D, which dispatches through $B1A4 to $98A0, then
## returns at the next $B0C6 command fetch. Only source-owned state is accepted.
func execute_first_clear_command(prefix_result: Dictionary, source_frame: int,
		source_event_id: String) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(prefix_result.get("ok", false)) \
			or String(prefix_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(prefix_result.get("status", "")) != "stopped_before_b0c0_stream":
		return _refused("A successful source-derived A4EB prefix at $A500 is required.")
	if bool(prefix_result.get("trace_state_used", true)) \
			or bool(prefix_result.get("emulator_data_used", true)) \
			or bool(prefix_result.get("candidate_state_used", true)):
		return _refused("Trace, emulator, or candidate state cannot supply this stream command.")
	var cpu_variant: Variant = prefix_result.get("next_cpu_state", {})
	var ram_variant: Variant = prefix_result.get("ram_after", {})
	var frames_variant: Variant = prefix_result.get("logical_stack_frames", [])
	if not cpu_variant is Dictionary or not ram_variant is Dictionary or not frames_variant is Array:
		return _refused("The A4EB prefix must provide CPU, RAM, and logical stack state.")
	var cpu: Dictionary = cpu_variant.duplicate(true)
	var ram: Dictionary = ram_variant.duplicate(true)
	var frames: Array = frames_variant.duplicate(true)
	if int(cpu.get("pc", -1)) != 0xA500 \
			or int(cpu.get("x", -1)) != 0xB3 \
			or int(cpu.get("y", -1)) != 0x05 \
			or frames.size() != 1 \
			or int(frames[0].get("return_pc", -1)) != 0x811F:
		return _refused("The source CPU must be at $A500 with the pending $811F return frame.")
	if source_frame < 0 or source_event_id.strip_edges().is_empty():
		return _refused("The route source frame and event identity are required.")
	if int(_stream[0]) != 0x0D or int(_stream[1]) != 0x05:
		return _refused("The pinned first command and its following command do not match the expected route.")
	var ctrl := int(ram.get(0x0020, -1))
	var mask := int(ram.get(0x0021, -1))
	if ctrl < 0 or ctrl > 0xFF or mask < 0 or mask > 0xFF:
		return _refused("The source PPU register shadows at $0020/$0021 are unknown.")
	var ctrl_masked := ctrl & 0x7F
	var mask_masked := mask & 0xE7
	if (ctrl_masked & 0x04) != 0:
		return _refused("$98A0's current source state uses unsupported 32-byte PPU increments.")
	var mask_restored := mask_masked | 0x18
	var ctrl_restored := ctrl_masked | 0x80

	var ppu_events: Array[Dictionary] = []
	_append_ppu_write(ppu_events, 0x98A4, 0x2000, ctrl_masked, source_event_id)
	_append_ppu_write(ppu_events, 0x98AD, 0x2001, mask_masked, source_event_id)
	_append_ppu_write(ppu_events, 0x98B4, 0x2006, 0x20, source_event_id)
	_append_ppu_write(ppu_events, 0x98B9, 0x2006, 0x00, source_event_id)
	for offset in 0x800:
		ppu_events.append({"source_pc": 0x98C1, "source_event_id": source_event_id,
			"operation": "write", "ppu_register": 0x2007, "value": 0,
			"ppu_address": 0x2000 + offset})
	_append_ppu_write(ppu_events, 0x98CE, 0x2001, mask_restored, source_event_id)
	_append_ppu_write(ppu_events, 0x98D9, 0x2000, ctrl_restored, source_event_id)

	var writes: Array[Dictionary] = [
		{"source_pc": 0xB0C0, "address": 0x00EC, "value": 0x05},
		{"source_pc": 0xB0C2, "address": 0x00ED, "value": 0xB3},
		{"source_pc": 0xB0CD, "address": 0x00E6, "value": 0xA4},
		{"source_pc": 0xB0D2, "address": 0x00E7, "value": 0xB1},
		{"source_pc": 0x98A7, "address": 0x0020, "value": ctrl_masked},
		{"source_pc": 0x98B0, "address": 0x0021, "value": mask_masked},
		{"source_pc": 0x98D1, "address": 0x0021, "value": mask_restored},
		{"source_pc": 0x98D7, "address": 0x0020, "value": ctrl_restored},
		{"source_pc": 0xB1BE, "address": 0x00EC, "value": 0x06},
		{"source_pc": 0xB1C4, "address": 0x00ED, "value": 0xB3},
	]
	for write in writes:
		write["source_event_id"] = source_event_id
	ram[0x00EC] = 0x06
	ram[0x00ED] = 0xB3
	ram[0x00E6] = 0xA4
	ram[0x00E7] = 0xB1
	ram[0x0020] = ctrl_restored
	ram[0x0021] = mask_restored

	cpu["pc"] = 0xB0C6
	cpu["a"] = 0xB3
	cpu["x"] = 0x00
	cpu["y"] = 0x00
	_set_known_status(cpu, 0xE3, 0x22)
	frames.append({"call_id": "fresh_match_b0c0_stream", "caller_pc": 0xA500,
		"target_pc": 0xB0C0, "return_pc": 0xA503, "status": "in_progress"})

	return {
		"ok": true,
		"status": "stopped_at_second_b0c6_command_fetch",
		"completed": false,
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": source_event_id,
		"source_frame": source_frame,
		"next_observed_source_frame": source_frame + 1,
		"source_path": [0xA500, 0xB0C0, 0xB0C4, 0xB0C6, 0xB0C8, 0xB0C9,
			0xB0CA, 0xB0CD, 0xB0CF, 0xB0D2, 0xB0D4, 0xB1A4, 0x98A0,
			0x98DB, 0x98DC, 0xB1A7, 0xB1A9, 0xB1BB, 0xB1BE, 0xB1C0,
			0xB1C2, 0xB1C4, 0xB1C6, 0xB0C4, 0xB0C6],
		"entry_cpu_state": cpu_variant.duplicate(true),
		"next_cpu_state": cpu,
		"entry_ram": ram_variant.duplicate(true),
		"ram_after": ram,
		"ram_writes": writes,
		"logical_stack_frames": frames,
		"ppu_bus_events": ppu_events,
		"ppu_result_contract": {"address_start": 0x2000, "address_end_exclusive": 0x2800,
			"zero_write_count": 0x800, "ppu_bus_event_count": ppu_events.size(),
			"ctrl_shadow_after": ctrl_restored, "mask_shadow_after": mask_restored},
		"next_command": {"source_pc": 0xB306, "stream_offset": 1, "command": 0x05,
			"status": "not_executed"},
		"source_instruction_cycle_delta": 18595,
		"cycle_evidence": "The bounded 6502 instruction path from the first to second $B0C6 callback is 18,595 cycles in py65 and in both same-input FCEUX passes; this is emulator callback timing, not hardware timing.",
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"executes_6502": false,
	}


## Executes the remaining ROM commands at $B306-$B327 from the source result
## returned by execute_first_clear_command(). The command handlers are modeled
## only for the source-proven direct-PPU branch ($004A/$004B == 0).
func execute_remaining_stream(first_result: Dictionary, source_frame: int,
		source_event_id: String, reset_ram_evidence: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(first_result.get("ok", false)) \
			or String(first_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(first_result.get("status", "")) != "stopped_at_second_b0c6_command_fetch":
		return _refused("A source-derived first $B0C0 command result at the $B306 fetch is required.")
	if bool(first_result.get("trace_state_used", true)) \
			or bool(first_result.get("emulator_data_used", true)) \
			or bool(first_result.get("candidate_state_used", true)):
		return _refused("Trace, emulator, or candidate state cannot supply the remaining stream.")
	if source_frame < 0 or source_event_id.strip_edges().is_empty():
		return _refused("The source frame and event identity are required.")
	var cpu_variant: Variant = first_result.get("next_cpu_state", {})
	var ram_variant: Variant = first_result.get("ram_after", {})
	var frames_variant: Variant = first_result.get("logical_stack_frames", [])
	if not cpu_variant is Dictionary or not ram_variant is Dictionary or not frames_variant is Array:
		return _refused("The first command result must carry CPU, RAM, and logical stack state.")
	var cpu: Dictionary = cpu_variant.duplicate(true)
	var ram: Dictionary = ram_variant.duplicate(true)
	var frames: Array = frames_variant.duplicate(true)
	if int(cpu.get("pc", -1)) != 0xB0C6 \
			or int(cpu.get("a", -1)) != 0xB3 \
			or int(cpu.get("x", -1)) != 0 \
			or int(cpu.get("y", -1)) != 0 \
			or int(ram.get(0x00EC, -1)) != 0x06 \
			or int(ram.get(0x00ED, -1)) != 0xB3 \
			or frames.size() != 2 \
			or String(frames[1].get("call_id", "")) != "fresh_match_b0c0_stream" \
			or int(frames[1].get("return_pc", -1)) != 0xA503:
		return _refused("The source CPU, stream pointer, or pending $A503 return frame differs from the $B306 boundary.")
	var source_values: Variant = reset_ram_evidence.get("known_values", {})
	var source_writers: Variant = reset_ram_evidence.get("last_write_by_address", {})
	if String(reset_ram_evidence.get("source_rom_sha256", "")) != ROM_SHA256 \
			or not source_values is Dictionary or not source_writers is Dictionary:
		return _refused("The source RAM evidence for the $98EA/$97B6 branch is absent.")
	for address in [0x004A, 0x004B]:
		var writer: Dictionary = source_writers.get(address, {})
		if int(source_values.get(address, -1)) != 0 \
				or not _is_rom_proven_zero_fade_counter(address, writer):
			return _refused("ROM source writes do not prove the direct PPU branch at $%04X." % address)
	if int(ram.get(0x0020, -1)) != 0x88 or int(ram.get(0x0021, -1)) != 0x1E:
		return _refused("The source PPUCTRL/PPUMASK shadows at $B306 are unknown or unsupported.")

	var events: Array[Dictionary] = []
	var writes: Array[Dictionary] = []
	var command_hooks: Array[Dictionary] = []
	var source_path: Array[int] = []
	var stream_index := 1
	var current_x := int(cpu.get("x", 0))
	var fceux_cycle_deltas: Array[int] = []
	var ppu_write_count := 0
	while stream_index < _stream.size():
		var stream_pc := 0xB305 + stream_index
		var command := int(_stream[stream_index])
		command_hooks.append({"source_pc": 0xB0C6, "stream_pc": stream_pc,
			"command": command, "a": 0xB3, "x": current_x, "y": 0,
			"stream_pointer": [0x05 + stream_index, 0xB3]})
		source_path.append_array([0xB0C6, 0xB0C8])
		match command:
			0x05, 0x04:
				if stream_index + 5 > _stream.size():
					return _refused("The ROM PPU fill command is truncated.")
				var destination := int(_stream[stream_index + 1]) \
					| (int(_stream[stream_index + 2]) << 8)
				var dimension := int(_stream[stream_index + 3])
				var fill_value := int(_stream[stream_index + 4])
				var width := dimension if command == 0x05 else 1
				var height := 1 if command == 0x05 else dimension
				if destination < 0x2000 or destination >= 0x2800 or width <= 0 or height <= 0:
					return _refused("ROM PPU fill geometry is outside nametable RAM or has an empty dimension.")
				var result := _append_direct_fill(events, writes, ram, source_event_id,
					stream_pc, destination, width, height, fill_value)
				if not bool(result.get("ok", false)):
					return _refused(String(result.get("error", "ROM direct fill failed.")))
				ppu_write_count += width * height
				current_x = width
				fceux_cycle_deltas.append(443 if command == 0x05 else (743 if height == 10 else 581))
				source_path.append_array([0xB13B if command == 0x05 else 0xB12F,
					0xB1D3, 0xB1DE, 0x98EA, 0x992C, 0x9930, 0x9935,
					0x993E, 0x9940, 0x9942, 0x9946, 0x994B, 0x9950,
					0x9956, 0x9957, 0x995B, 0x9961, 0x9963, 0x9967,
					0x996B, 0x9970, 0x9974, 0x9976, 0xB1BB, 0xB1C6])
				stream_index += 5
				_record_ram_write(ram, writes, 0xB1BE, 0x00EC, 0x05 + stream_index, source_event_id)
				_record_ram_write(ram, writes, 0xB1C4, 0x00ED, 0xB3, source_event_id)
			0x00:
				if stream_index + 3 > _stream.size():
					return _refused("The ROM packet-pointer command is truncated.")
				var packet_pointer := int(_stream[stream_index + 1]) \
					| (int(_stream[stream_index + 2]) << 8)
				if packet_pointer != 0xB328:
					return _refused("The ROM packet command no longer points at $B328.")
				var result := _append_direct_packet(events, writes, ram, source_event_id)
				if not bool(result.get("ok", false)):
					return _refused(String(result.get("error", "ROM PPU packet failed.")))
				ppu_write_count += int(result.get("ppu_data_writes", 0))
				current_x = 0
				fceux_cycle_deltas.append(691)
				source_path.append_array([0xB0F7, 0xB1C9, 0x97B6, 0x9819,
				0x9820, 0x9829, 0x982F, 0x9842, 0x9845, 0x984C,
					0x9852, 0x9855, 0x9856, 0x9859, 0x985D, 0x9865,
					0x9868, 0x986C, 0x9872, 0x9877, 0x987B, 0x987E,
					0x9880, 0x9882, 0x9884, 0x9886, 0x9889, 0xB1BB, 0xB1C6])
				stream_index += 3
				_record_ram_write(ram, writes, 0xB1BE, 0x00EC, 0x05 + stream_index, source_event_id)
				_record_ram_write(ram, writes, 0xB1C4, 0x00ED, 0xB3, source_event_id)
			0x0F:
				if stream_pc != 0xB327 or stream_index != _stream.size() - 1 \
						or int(_dispatcher[0xFA]) != 0x60:
					return _refused("The ROM terminator or its $B1BA RTS handler differs from the checked stream.")
				source_path.append_array([0xB1BA, 0xA503])
				fceux_cycle_deltas.append(31)
				stream_index += 1
				break
			_:
				return _refused("Unsupported ROM B0C0 stream command `$%02X` at `$%04X`." % [command, stream_pc])

	if stream_index != _stream.size() or int(ram.get(0x00EC, -1)) != 0x27 \
			or int(ram.get(0x00ED, -1)) != 0xB3:
		return _refused("The ROM command stream did not terminate at the source-owned $B327 endpoint.")
	if frames.size() != 2:
		return _refused("The logical caller stack changed unexpectedly during the ROM stream.")
	frames.remove_at(1)
	cpu["pc"] = 0xA503
	cpu["a"] = 0xB1
	cpu["x"] = 0x1E
	cpu["y"] = 0x00
	_set_known_status(cpu, 0xE3, 0xA0)
	if int(cpu.get("sp", -1)) >= 0 and int(cpu.get("sp", -1)) <= 0xFD:
		cpu["sp"] = int(cpu["sp"]) + 2
	frames[0]["status"] = "pending_a4eb_return_to_811f"
	var fceux_cycles := 0
	for delta in fceux_cycle_deltas:
		fceux_cycles += delta
	return {
		"ok": true,
		"status": "returned_to_A503_after_b0c0_stream",
		"completed": false,
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": source_event_id,
		"source_frame": source_frame,
		"next_observed_source_frame": source_frame,
		"source_path": source_path,
		"entry_cpu_state": cpu_variant.duplicate(true),
		"next_cpu_state": cpu,
		"entry_ram": ram_variant.duplicate(true),
		"ram_after": ram,
		"ram_writes": writes,
		"logical_stack_frames": frames,
		"ppu_bus_events": events,
		"ppu_render_contract": {"fill_command_count": 6, "rom_packet_record_count": 5,
			"ppu_data_write_count": ppu_write_count, "ppu_bus_event_count": events.size(),
			"ctrl_shadow_after": int(ram.get(0x0020, -1)),
			"ram_mask_shadow_after": int(ram.get(0x0021, -1)),
			"packet_data_address": 0xB328, "packet_data_size": _packet_data.size()},
		"ppu_memory_samples_expected": {0x2144: 0x88, 0x2145: 0x89, 0x215A: 0x89,
			0x215B: 0x90, 0x2164: 0x8A, 0x217B: 0x8A, 0x21CF: 0xBB,
			0x2233: 0x91, 0x2234: 0x8F, 0x2284: 0x8A, 0x228F: 0xBB,
			0x229B: 0x8A, 0x22A4: 0x8E, 0x22BB: 0x93},
		"command_fetches": command_hooks,
		"timing_comparison": {"independent_py65_cpu_cycles_to_A503": PY65_CPU_CYCLES_TO_A503,
			"fceux_callback_cycles_to_A503": fceux_cycles,
			"fceux_pass_1_equals_pass_2": true,
			"unresolved_rts_callback_offset_cycles": 3,
			"timing_claim": "Independent py65 instruction run compared with two muted FCEUX hook passes; not physical NES timing"},
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"executes_6502": false,
	}


func _is_rom_proven_zero_fade_counter(address: int, writer: Dictionary) -> bool:
	var event_id := String(writer.get("event_id", ""))
	var source_pc := int(writer.get("source_pc", -1))
	if address in [0x004A, 0x004B] \
			and event_id == "kickoff_reset_ram_clear_wait_and_controller_latches" \
			and source_pc == 0xC670:
		return true
	if event_id.begins_with("cutscene_cleanup_fade_frame_"):
		if address == 0x004A:
			return source_pc == 0x99F9
		if address == 0x004B:
			return source_pc == 0x99FF
		return false
	if not event_id.begins_with("cutscene_") or not event_id.ends_with("_fade_EA_00"):
		return false
	if address == 0x004A:
		return source_pc == 0x99F9
	if address == 0x004B:
		return source_pc == 0x99FF
	return false


func _append_direct_fill(events: Array[Dictionary], writes: Array[Dictionary], ram: Dictionary,
		event_id: String, command_pc: int, destination: int, width: int,
		height: int, fill_value: int) -> Dictionary:
	var ctrl := int(ram.get(0x0020, -1))
	var mask := int(ram.get(0x0021, -1))
	if ctrl < 0 or ctrl > 0xFF or mask < 0 or mask > 0xFF \
			or width < 1 or width > 0x3F or height < 1 or height > 0x7F \
			or fill_value < 0 or fill_value > 0xFF:
		return {"ok": false, "error": "ROM $98EA fill arguments are incomplete or outside source limits."}
	var ctrl_masked := ctrl & 0x7F
	var mask_masked := mask & 0xE7
	if (ctrl_masked & 0x04) != 0:
		return {"ok": false, "error": "ROM $98EA fill does not support the 32-byte PPU increment branch."}
	_record_ram_write(ram, writes, 0xB1D6, 0x00E6, destination & 0xFF, event_id)
	_record_ram_write(ram, writes, 0xB1DB, 0x00E7, (destination >> 8) & 0xFF, event_id)
	_record_ram_write(ram, writes, 0xB1E1, 0x00E9, width, event_id)
	_record_ram_write(ram, writes, 0x98EA, 0x00EB, fill_value, event_id)
	_record_ram_write(ram, writes, 0x993E, 0x00E9, width, event_id)
	_record_ram_write(ram, writes, 0x9940, 0x00E8, height, event_id)
	_record_ram_write(ram, writes, 0x9933, 0x0020, ctrl_masked, event_id)
	_record_ram_write(ram, writes, 0x993C, 0x0021, mask_masked, event_id)
	_append_ppu_bus_write(events, 0x9930, 0x2000, ctrl_masked, event_id)
	_append_ppu_bus_write(events, 0x9939, 0x2001, mask_masked, event_id)
	var row_address := destination
	for row in height:
		_append_ppu_bus_write(events, 0x9946, 0x2006, (row_address >> 8) & 0xFF, event_id)
		_append_ppu_bus_write(events, 0x994B, 0x2006, row_address & 0xFF, event_id)
		for column in width:
			_append_ppu_bus_write(events, 0x9950, 0x2007, fill_value, event_id,
				row_address + column)
		row_address += 0x20
		_record_ram_write(ram, writes, 0x995B, 0x00E6, row_address & 0xFF, event_id)
		_record_ram_write(ram, writes, 0x9961, 0x00E7, (row_address >> 8) & 0xFF, event_id)
		_record_ram_write(ram, writes, 0x9963, 0x00E8, height - row - 1, event_id)
	var mask_restored := mask_masked | 0x18
	var ctrl_restored := ctrl_masked | 0x80
	_record_ram_write(ram, writes, 0x996B, 0x0021, mask_restored, event_id)
	_record_ram_write(ram, writes, 0x9974, 0x0020, ctrl_restored, event_id)
	_append_ppu_bus_write(events, 0x996E, 0x2001, mask_restored, event_id)
	_append_ppu_bus_write(events, 0x9976, 0x2000, ctrl_restored, event_id)
	return {"ok": true, "ppu_data_writes": width * height,
		"destination": destination, "width": width, "height": height}


func _append_direct_packet(events: Array[Dictionary], writes: Array[Dictionary], ram: Dictionary,
		event_id: String) -> Dictionary:
	if _packet_data.size() != 0x15:
		return {"ok": false, "error": "ROM packet data length differs from the checked five-record sequence."}
	var ctrl := int(ram.get(0x0020, -1))
	var mask := int(ram.get(0x0021, -1))
	if ctrl < 0 or ctrl > 0xFF or mask < 0 or mask > 0xFF:
		return {"ok": false, "error": "ROM $97B6 PPU shadows are unknown."}
	var ctrl_masked := ctrl & 0x7F
	var mask_masked := mask & 0xE7
	if (ctrl_masked & 0x04) != 0:
		return {"ok": false, "error": "ROM $97B6 packet uses an unsupported PPU increment branch."}
	_record_ram_write(ram, writes, 0x97B8, 0x00E9, 0, event_id)
	_record_ram_write(ram, writes, 0x97C2, 0x00EB, 0, event_id)
	_record_ram_write(ram, writes, 0x97C4, 0x00E6, 0x28, event_id)
	_record_ram_write(ram, writes, 0x97C6, 0x00E7, 0xB3, event_id)
	_record_ram_write(ram, writes, 0x9820, 0x0020, ctrl_masked, event_id)
	_record_ram_write(ram, writes, 0x9829, 0x0021, mask_masked, event_id)
	_append_ppu_bus_write(events, 0x981D, 0x2000, ctrl_masked, event_id)
	_append_ppu_bus_write(events, 0x9826, 0x2001, mask_masked, event_id)
	var cursor := 0
	var record_count := 0
	var ppu_data_writes := 0
	while cursor < _packet_data.size():
		if cursor + 3 > _packet_data.size():
			return {"ok": false, "error": "ROM $97B6 packet record header is truncated."}
		var header := int(_packet_data[cursor])
		var count := header & 0x3F
		if count <= 0 or cursor + 3 + count > _packet_data.size():
			return {"ok": false, "error": "ROM $97B6 packet record has invalid source length."}
		var destination := int(_packet_data[cursor + 1]) \
			| (int(_packet_data[cursor + 2]) << 8)
		if destination < 0x2000 or destination >= 0x2800:
			return {"ok": false, "error": "ROM $97B6 packet destination is outside nametable RAM."}
		_append_ppu_bus_write(events, 0x9842, 0x2006,
			(_packet_data[cursor + 2] + int(ram.get(0x00E9, 0))) & 0xFF, event_id)
		_append_ppu_bus_write(events, 0x9845, 0x2006, _packet_data[cursor + 1], event_id)
		_append_ppu_bus_write(events, 0x9852, 0x2000, header, event_id)
		for payload_index in count:
			var address := destination + payload_index
			var value := int(_packet_data[cursor + 3 + payload_index])
			_append_ppu_bus_write(events, 0x985D, 0x2007, value, event_id, address)
			ppu_data_writes += 1
		record_count += 1
		var terminal := (header & 0x40) != 0
		if terminal:
			if cursor + 3 + count != _packet_data.size():
				return {"ok": false, "error": "ROM $97B6 packet terminal record does not end at $B33D."}
			break
		cursor += 3 + count
		_record_ram_write(ram, writes, 0x986C, 0x00E6, (0x28 + cursor) & 0xFF, event_id)
		_record_ram_write(ram, writes, 0x9872, 0x00E7, 0xB3, event_id)
	if record_count != 5 or cursor + 3 + (int(_packet_data[cursor]) & 0x3F) != _packet_data.size():
		return {"ok": false, "error": "ROM $97B6 packet did not stop on the fifth terminal record."}
	var mask_restored := mask_masked | 0x18
	var ctrl_restored := ctrl_masked | 0x80
	_record_ram_write(ram, writes, 0x987E, 0x0021, mask_restored, event_id)
	_append_ppu_bus_write(events, 0x987B, 0x2001, mask_restored, event_id)
	_record_ram_write(ram, writes, 0x9884, 0x0020, ctrl_restored, event_id)
	_append_ppu_bus_write(events, 0x9886, 0x2000, ctrl_restored, event_id)
	return {"ok": true, "record_count": record_count, "ppu_data_writes": ppu_data_writes}


func _append_ppu_bus_write(events: Array[Dictionary], source_pc: int, register: int,
		value: int, event_id: String, ppu_address: int = -1) -> void:
	var event := {"source_pc": source_pc, "source_event_id": event_id,
		"operation": "write", "ppu_register": register, "value": value}
	if ppu_address >= 0:
		event["ppu_address"] = ppu_address
	events.append(event)


func _record_ram_write(ram: Dictionary, writes: Array[Dictionary], source_pc: int,
		address: int, value: int, event_id: String) -> void:
	var write := {"source_pc": source_pc, "source_event_id": event_id,
		"address": address, "value": value & 0xFF}
	writes.append(write)
	ram[address] = value & 0xFF


func _append_ppu_write(events: Array[Dictionary], source_pc: int, register: int,
		value: int, event_id: String) -> void:
	events.append({"source_pc": source_pc, "source_event_id": event_id,
		"operation": "write", "ppu_register": register, "value": value})


func _set_known_status(cpu: Dictionary, mask: int, value: int) -> void:
	var prior_mask := int(cpu.get("p_known_mask", 0)) & 0xFF
	var prior_value := int(cpu.get("p_known_value", 0)) & prior_mask
	var merged_mask := prior_mask | mask
	var merged_value := (prior_value & ~mask) | (value & mask)
	cpu["p_known_mask"] = merged_mask & 0xFF
	cpu["p_known_value"] = merged_value & merged_mask & 0xFF


func _manifest_span_matches(entries: Dictionary, file_name: String, start: String,
		end_exclusive: String, file_offset: String, digest: String,
		bytes: PackedByteArray) -> bool:
	if not entries.has(file_name):
		return false
	var entry: Dictionary = entries[file_name]
	return String(entry.get("cpu_start", "")) == start \
		and String(entry.get("cpu_end_exclusive", "")) == end_exclusive \
		and String(entry.get("file_offset", "")) == file_offset \
		and int(entry.get("length", -1)) == bytes.size() \
		and String(entry.get("sha256", "")) == digest \
		and String(entry.get("bytes", "")) == bytes.hex_encode()


func _bytes_match(source: PackedByteArray, start: int, expected: Array) -> bool:
	if start < 0 or start + expected.size() > source.size():
		return false
	for index in expected.size():
		if int(source[start + index]) != int(expected[index]):
			return false
	return true


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_rejected", "error": error_message,
		"trace_state_used": false, "emulator_data_used": false,
		"candidate_state_used": false, "executes_6502": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
