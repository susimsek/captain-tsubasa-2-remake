extends RefCounted
class_name RomFreshMatchA503EntryExecutor
## Applies the bounded, ROM-checked A503 setup through its first descriptor decode.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_a503/"
const MANIFEST_PATH := ROOT + "manifest.json"
const BODY_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/bank01_prematch_setup_body_A4EB_A610.bin"
const BODY_SHA256 := "1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587"
const QUEUE_WRITER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_eb_post_wait_source_task.gd")
const SPECIAL_NMI_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd")
const BODY_PREFIX := [
	0xA9, 0x00, 0x85, 0x44, 0x85, 0x45, 0xA0, 0xCC,
	0xB9, 0x71, 0xB2, 0x99, 0x9C, 0x03, 0xC8, 0xD0,
	0xF7, 0xA6, 0x26, 0xBD, 0xD1, 0xBC, 0x29, 0xF0,
	0x4A, 0x4A, 0x4A, 0xAA, 0xBC, 0xF3, 0xBC, 0xBD,
	0xF4, 0xBC, 0xAA, 0x20, 0x27, 0x9D,
]
const NEXT_SETUP_PREFIX := [
	0xA6, 0x26, 0xBD, 0xD1, 0xBC, 0x29, 0x0F, 0x0A, 0xAA, 0xBC,
	0x64, 0xBD, 0xBD, 0x65, 0xBD, 0xAA, 0xA9, 0x07, 0x85, 0xE8,
	0xA9, 0x22, 0x85, 0xE9, 0x20, 0x50, 0x9D, 0xA5, 0x2A, 0xA0,
	0xD0, 0xA2, 0x21, 0x20, 0x3C, 0xA6, 0xA9, 0x24, 0xC5, 0x2B,
	0xA5, 0x2B, 0xE9, 0x00, 0xA0, 0x50, 0xA2, 0x22, 0x20, 0x3C,
	0xA6, 0xA9, 0x00, 0x85, 0x7B, 0xA9, 0x00, 0x85, 0x8E, 0xA9,
	0x2E, 0x85, 0x8F, 0xA9, 0x04, 0xA2, 0x37, 0x20, 0x7A, 0x99,
]
const SPAN_SPECS := {
	"bank01_match_setup_copy_B33D_B371.bin": {
		"start": "$B33D", "end": "$B371", "offset": "0x00334D",
		"length": 52, "sha256": "007f707f65416ecdff6639a2e819e5eac3a7a9bf482b492e3bb095375bff1e24",
		"bytes": "30df027838f1026838f4027038f5027838f8028038f9028838fc029040f3026840f6027040f7027840fa028040fb028840fe0290",
	},
	"bank01_match_index_descriptor_BCD1_BCD2.bin": {
		"start": "$BCD1", "end": "$BCD2", "offset": "0x003CE1",
		"length": 1, "sha256": "4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a",
		"bytes": "01",
	},
	"bank01_match_descriptor_pointer_BCF3_BCF5.bin": {
		"start": "$BCF3", "end": "$BCF5", "offset": "0x003D03",
		"length": 2, "sha256": "420e35ef6c540790a6f673c4bee8a76af9bd2e6f1d7eb6d23766cbb33aae63b9",
		"bytes": "ffbc",
	},
	"bank01_match_descriptor_data_BCFF_BD0C.bin": {
		"start": "$BCFF", "end": "$BD0C", "offset": "0x003D0F",
		"length": 13, "sha256": "d702a9ecf77ff6a5205a0fc65e922c1a2d7db7067a750ebef6d8c53e3dfb5748",
		"bytes": "6a21420b7a0d096f20437570ff",
	},
	"bank00_ppu_descriptor_decoder_9D27_9D50.bin": {
		"start": "$9D27", "end": "$9D50", "offset": "0x001D37",
		"length": 41, "sha256": "94a6f54f43bc9ea6e0d214e9de9808898f2cb7744ad9bd5ffc249b56ffc58c2d",
		"bytes": "84e686e7a000b1e685e8c8b1e685e984eb20589daae6eba5eb1865e685e6a5e7690085e7e0ffd0dc60",
	},
	"bank00_ppu_descriptor_inner_reader_9D58_9D73.bin": {
		"start": "$9D58", "end": "$9D73", "offset": "0x001D68",
		"length": 27, "sha256": "0a25ab537c78a9e938afc197d9a7162873208cebbdd9a96ef718ed2d9be89ac8",
		"bytes": "e6eba4ebb1e6c9fcb010a4e8a6e920ca88e6e8d002e6e94c589d60",
	},
	"bank00_ppu_tile_write_helper_88CA_88FB.bin": {
		"start": "$88CA", "end": "$88FB", "offset": "0x0008DA",
		"length": 49, "sha256": "2d776ddf3e137d3abdf965f574c2a782b5ba6388f19b6ed55ba4445b211b160f",
		"bytes": "48a98220289b68c9a0901848c9c8a99469009de805e868a8b9148a9de805e8205e9b609de905a9009de805e8e8205e9b60",
	},
	"bank00_ppu_text_reader_wrapper_9D50_9D58.bin": {
		"start": "$9D50", "end": "$9D58", "offset": "0x001D60",
		"length": 8, "sha256": "a9fdcc0f1952369a874656d34671da311e5790f0b9246cf6830b12b617a40ba5",
		"bytes": "84e686e7a9ff85eb",
	},
	"bank01_match_second_descriptor_pointer_table_BD64_BD68.bin": {
		"start": "$BD64", "end": "$BD68", "offset": "0x003D74",
		"length": 4, "sha256": "4def2928bbaa89e5e5c223a2d4fa573bb56229db8b40d2d11992399d41f7477b",
		"bytes": "74bd7cbd",
	},
	"bank01_match_second_descriptor_text_BD7C_BD82.bin": {
		"start": "$BD7C", "end": "$BD82", "offset": "0x003D8C",
		"length": 6, "sha256": "5004e7a86cb18c83b6f611ae0c4e82de4563a558d292a97ca6bd54c21b19e8d6",
		"bytes": "342e4d6163ff",
	},
	"bank01_match_text_pointer_table_BDA8_BDB0.bin": {
		"start": "$BDA8", "end": "$BDB0", "offset": "0x003DB8",
		"length": 8, "sha256": "4830b8a966036c4ee677721ed81b181584357470044dac22003d56e385fda2df",
		"bytes": "f2bdf9bd00be09be",
	},
	"bank01_match_text_id_00_BDF2_BDF9.bin": {
		"start": "$BDF2", "end": "$BDF9", "offset": "0x003E02",
		"length": 7, "sha256": "f29654b9ddf2baccdaa88e6d919681c74b0f3c362ed74b2d5619bda9db3635f4",
		"bytes": "036f201c757dff",
	},
	"bank01_match_text_id_03_BE09_BE11.bin": {
		"start": "$BE09", "end": "$BE11", "offset": "0x003E19",
		"length": 8, "sha256": "6e855be38b078932eb1a218123e3f1d9ceeafdc745b470e5e4a849d9da28446e",
		"bytes": "466c751f7c6e0eff",
	},
	"bank01_match_text_pointer_resolver_A63C_A64C.bin": {
		"start": "$A63C", "end": "$A64C", "offset": "0x00264C",
		"length": 16, "sha256": "9380ddd106f69ca46d45d5c0a48c0dd760a1c5eaba79aaf0ffc11f6aaebdb972",
		"bytes": "84e886e90aaabca8bdbda9bdaa4c509d",
	},
}

var error_message := ""
var _configured := false
var _body := PackedByteArray()
var _copy_data := PackedByteArray()
var _index_descriptor := PackedByteArray()
var _descriptor_pointer := PackedByteArray()
var _descriptor_data := PackedByteArray()
var _descriptor_decoder := PackedByteArray()
var _descriptor_inner_reader := PackedByteArray()
var _tile_write_helper := PackedByteArray()
var _text_reader_wrapper := PackedByteArray()
var _second_descriptor_pointer_table := PackedByteArray()
var _second_descriptor_text := PackedByteArray()
var _text_pointer_table := PackedByteArray()
var _text_id_00 := PackedByteArray()
var _text_id_03 := PackedByteArray()
var _text_pointer_resolver := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_body = FileAccess.get_file_as_bytes(BODY_PATH)
	if _body.size() != 0x126 or _sha256(_body) != BODY_SHA256 \
			or not _bytes_match(_body, 0xA503 - 0xA4EB, BODY_PREFIX):
		return _fail("The preserved A4EB body does not match the bounded A503 instruction span.")
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return _fail("The A503 ROM-table manifest is missing.")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The A503 ROM-table manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if String(manifest.get("schema", "")) != "ct2-fresh-match-a503-entry-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The A503 table manifest targets another ROM revision.")
	var entries: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries[String(entry.get("file", ""))] = entry
	var loaded: Dictionary = {}
	for file_name: String in SPAN_SPECS:
		var spec: Dictionary = SPAN_SPECS[file_name]
		if not entries.has(file_name):
			return _fail("The A503 manifest omits %s." % file_name)
		var entry: Dictionary = entries[file_name]
		if String(entry.get("cpu_start", "")) != String(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != String(spec["end"]) \
				or String(entry.get("file_offset", "")) != String(spec["offset"]) \
				or int(entry.get("length", -1)) != int(spec["length"]) \
				or String(entry.get("sha256", "")) != String(spec["sha256"]) \
				or String(entry.get("bytes", "")) != String(spec["bytes"]):
			return _fail("Manifest provenance differs for %s." % file_name)
		var bytes := FileAccess.get_file_as_bytes(ROOT + file_name)
		if bytes.size() != int(spec["length"]) \
				or _sha256(bytes) != String(spec["sha256"]) \
				or bytes.hex_encode() != String(spec["bytes"]):
			return _fail("A503 source data failed its size/hash/byte check: %s." % file_name)
		loaded[file_name] = bytes
	_copy_data = loaded["bank01_match_setup_copy_B33D_B371.bin"]
	_index_descriptor = loaded["bank01_match_index_descriptor_BCD1_BCD2.bin"]
	_descriptor_pointer = loaded["bank01_match_descriptor_pointer_BCF3_BCF5.bin"]
	_descriptor_data = loaded["bank01_match_descriptor_data_BCFF_BD0C.bin"]
	_descriptor_decoder = loaded["bank00_ppu_descriptor_decoder_9D27_9D50.bin"]
	_descriptor_inner_reader = loaded["bank00_ppu_descriptor_inner_reader_9D58_9D73.bin"]
	_tile_write_helper = loaded["bank00_ppu_tile_write_helper_88CA_88FB.bin"]
	_text_reader_wrapper = loaded["bank00_ppu_text_reader_wrapper_9D50_9D58.bin"]
	_second_descriptor_pointer_table = loaded["bank01_match_second_descriptor_pointer_table_BD64_BD68.bin"]
	_second_descriptor_text = loaded["bank01_match_second_descriptor_text_BD7C_BD82.bin"]
	_text_pointer_table = loaded["bank01_match_text_pointer_table_BDA8_BDB0.bin"]
	_text_id_00 = loaded["bank01_match_text_id_00_BDF2_BDF9.bin"]
	_text_id_03 = loaded["bank01_match_text_id_03_BE09_BE11.bin"]
	_text_pointer_resolver = loaded["bank01_match_text_pointer_resolver_A63C_A64C.bin"]
	var queue_writer: Variant = QUEUE_WRITER_SCRIPT.new()
	if not queue_writer.configure_from_project_sources():
		return _fail("Shared `$9B28-$9B6E` queue-writer source failed verification: " + queue_writer.error_message)
	_configured = true
	return true


## Executes A503 through the instruction immediately before JSR $9D27.
## The helper's compressed-data semantics are deliberately left as the next boundary.
func execute_from_b0c0_stream_result(stream_result: Dictionary, source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(stream_result.get("ok", false)) \
			or String(stream_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(stream_result.get("status", "")) != "returned_to_A503_after_b0c0_stream" \
			or bool(stream_result.get("trace_state_used", true)) \
			or bool(stream_result.get("emulator_data_used", true)) \
			or bool(stream_result.get("candidate_state_used", true)):
		return _refused("A successful source-owned B0C0 return to A503 is required.")
	var cpu_variant: Variant = stream_result.get("next_cpu_state", {})
	var ram_variant: Variant = stream_result.get("ram_after", {})
	var frames_variant: Variant = stream_result.get("logical_stack_frames", [])
	if not cpu_variant is Dictionary or not ram_variant is Dictionary or not frames_variant is Array:
		return _refused("The A503 continuation requires the source CPU, RAM, and logical stack.")
	var cpu: Dictionary = cpu_variant.duplicate(true)
	var ram: Dictionary = ram_variant.duplicate(true)
	var frames: Array = frames_variant.duplicate(true)
	if int(cpu.get("pc", -1)) != 0xA503 or int(cpu.get("a", -1)) != 0xB1 \
			or int(cpu.get("x", -1)) != 0x1E or int(cpu.get("y", -1)) != 0 \
			or frames.size() != 1 or int(frames[0].get("return_pc", -1)) != 0x811F:
		return _refused("The B0C0 result does not carry the verified A503 CPU and $811F return context.")
	var match_index := int(ram.get(0x0026, -1))
	if match_index != 0:
		return _refused("This fresh-match A503 table slice only supports source-derived $0026=$00.")
	if _copy_data.size() != 0x34 or _index_descriptor.size() != 1 \
			or _descriptor_pointer.size() != 2:
		return _refused("The extracted A503 tables have an unexpected size.")
	var event_id := String(stream_result.get("source_event_id", "")) + ":a503-entry"
	if event_id.strip_edges().is_empty() or source_frame < 0:
		return _refused("The A503 event identity and source frame are required.")
	var writes: Array[Dictionary] = []
	for address: int in [0x0044, 0x0045]:
		ram[address] = 0
		writes.append(_ram_write(event_id, 0xA505 if address == 0x0044 else 0xA507,
			address, 0))
	for y in range(0xCC, 0x100):
		var destination := 0x039C + y
		var value := int(_copy_data[y - 0xCC])
		ram[destination] = value
		writes.append(_ram_write(event_id, 0xA50E, destination, value))
	var descriptor := int(_index_descriptor[match_index])
	var descriptor_index := (descriptor >> 4) * 2
	if descriptor_index != 0:
		return _refused("Only the fresh-match descriptor group backed by the extracted pointer pair is supported.")
	var pointer_low := int(_descriptor_pointer[descriptor_index])
	var pointer_high := int(_descriptor_pointer[descriptor_index + 1])
	var next_cpu: Dictionary = cpu.duplicate(true)
	next_cpu["a"] = pointer_high
	next_cpu["x"] = pointer_high
	next_cpu["y"] = pointer_low
	next_cpu["pc"] = 0xA526
	_set_known_status(next_cpu, 0x83, 0x80)
	var source_path: Array = stream_result.get("source_path", []).duplicate()
	source_path.append_array([0xA503, 0xA505, 0xA507, 0xA509, 0xA50B, 0xA50E,
		0xA511, 0xA512, 0xA514, 0xA516, 0xA519, 0xA51B, 0xA51C,
		0xA51D, 0xA51E, 0xA51F, 0xA522, 0xA525])
	return {
		"ok": true,
		"status": "stopped_before_a503_first_data_decoder",
		"completed": false,
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": event_id,
		"source_frame": source_frame,
		"source_path": source_path,
		"entry_cpu_state": cpu_variant.duplicate(true),
		"next_cpu_state": next_cpu,
		"entry_ram": ram_variant.duplicate(true),
		"ram_after": ram,
		"ram_writes": writes,
		"logical_stack_frames": frames,
		"copy_contract": {"source_start": 0xB33D, "source_end_exclusive": 0xB371,
			"source_y_start": 0xCC, "source_y_end_exclusive": 0x100,
			"destination_start": 0x0468, "destination_end_exclusive": 0x049C,
			"byte_count": _copy_data.size()},
		"first_decoder_call": {"call_pc": 0xA526, "target_pc": 0x9D27,
			"return_pc": 0xA529, "table_pointer": pointer_low | (pointer_high << 8),
			"status": "pending_not_executed"},
		"source_instruction_cycles_to_decoder_call": 816,
		"timing_scope": "Independent py65 instruction-cycle count for the bounded A503 path; no per-frame or physical NES timing claim.",
		"span_hashes": {"copy_data": String(SPAN_SPECS["bank01_match_setup_copy_B33D_B371.bin"]["sha256"]),
			"match_descriptor": String(SPAN_SPECS["bank01_match_index_descriptor_BCD1_BCD2.bin"]["sha256"]),
			"descriptor_pointer": String(SPAN_SPECS["bank01_match_descriptor_pointer_BCF3_BCF5.bin"]["sha256"])},
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"executes_6502": false,
	}


## Executes the fresh-match $BCFF descriptor and $9D27->$88CA queue path.
## The queued update is left pending; no PPU bus event or video frame is fabricated.
func execute_descriptor_decoder(prefix_result: Dictionary, queue_state_evidence: Dictionary,
		source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(prefix_result.get("ok", false)) \
			or String(prefix_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(prefix_result.get("status", "")) != "stopped_before_a503_first_data_decoder" \
			or bool(prefix_result.get("trace_state_used", true)) \
			or bool(prefix_result.get("emulator_data_used", true)) \
			or bool(prefix_result.get("candidate_state_used", true)):
		return _refused("The source-owned A503 prefix must stop at its first decoder call.")
	var cpu_variant: Variant = prefix_result.get("next_cpu_state", {})
	var ram_variant: Variant = prefix_result.get("ram_after", {})
	var frames_variant: Variant = prefix_result.get("logical_stack_frames", [])
	var known_variant: Variant = queue_state_evidence.get("known_values", {})
	var writers_variant: Variant = queue_state_evidence.get("last_write_by_address", {})
	if not cpu_variant is Dictionary or not ram_variant is Dictionary \
			or not frames_variant is Array or not known_variant is Dictionary \
			or not writers_variant is Dictionary:
		return _refused("The descriptor decoder needs the caller CPU/RAM and source-owned PPU queue evidence.")
	var cpu: Dictionary = cpu_variant.duplicate(true)
	var ram: Dictionary = ram_variant.duplicate(true)
	var frames: Array = frames_variant.duplicate(true)
	if int(cpu.get("pc", -1)) != 0xA526 or int(cpu.get("x", -1)) != 0xBC \
			or int(cpu.get("y", -1)) != 0xFF or frames.size() != 1 \
			or int(frames[0].get("return_pc", -1)) != 0x811F:
		return _refused("The A503 prefix does not carry the expected $BCFF decoder call context.")
	var call: Dictionary = prefix_result.get("first_decoder_call", {})
	if int(call.get("call_pc", -1)) != 0xA526 \
			or int(call.get("target_pc", -1)) != 0x9D27 \
			or int(call.get("return_pc", -1)) != 0xA529 \
			or int(call.get("table_pointer", -1)) != 0xBCFF:
		return _refused("The selected source descriptor no longer resolves to $BCFF->$9D27.")
	if _descriptor_data.size() != 13 or _descriptor_decoder.size() != 41 \
			or _descriptor_inner_reader.size() != 27 or _tile_write_helper.size() != 49:
		return _refused("The descriptor data or helper spans have unexpected sizes.")
	var queue_cursor := int(known_variant.get(0x0628, -1))
	var queue_control := int(known_variant.get(0x0629, -1))
	var cursor_writer: Dictionary = writers_variant.get(0x0628, {})
	var control_writer: Dictionary = writers_variant.get(0x0629, {})
	if queue_cursor != 0 or queue_control != 0x20 \
			or int(cursor_writer.get("source_pc", -1)) != 0xA04A \
			or int(control_writer.get("source_pc", -1)) != 0x9B6B \
			or not String(cursor_writer.get("event_id", "")).begins_with("cutscene_cleanup_palette_packet_consumer_") \
			or not String(control_writer.get("event_id", "")).begins_with("cleanup_palette_queue_flag_"):
		return _refused("The source ledger does not prove a drained $0628 queue and $0629=$20 control state.")
	if int(ram.get(0x0628, queue_cursor)) != queue_cursor \
			or int(ram.get(0x0629, queue_control)) != queue_control:
		return _refused("The A503 RAM image disagrees with its source queue-state receipts.")
	ram[0x0628] = queue_cursor
	ram[0x0629] = queue_control
	var payload: Array[int] = []
	var terminator_index := -1
	for index in range(2, _descriptor_data.size()):
		var value := int(_descriptor_data[index])
		if value >= 0xFC:
			terminator_index = index
			break
		payload.append(value)
	if terminator_index != _descriptor_data.size() - 1 \
			or int(_descriptor_data[terminator_index]) != 0xFF \
			or payload.size() != 10:
		return _refused("The first $BCFF descriptor does not end in the checked ten-byte $FF-terminated block.")
	for value: int in payload:
		if value >= 0xA0:
			return _refused("This semantic port only handles the $88CA low-tile branch for the source block.")
	var destination_low := int(_descriptor_data[0])
	var destination_high := int(_descriptor_data[1])
	var destination_start := destination_low | (destination_high << 8)
	if destination_start != 0x216A or queue_cursor + payload.size() * 5 >= 0x3D \
			or (queue_control & 0x40) != 0:
		return _refused("The $BCFF destination or queue-capacity state differs from the decoded fresh route.")
	var event_id := String(prefix_result.get("source_event_id", "")) + ":9d27-descriptor"
	var writes: Array[Dictionary] = []
	_ram_store(ram, writes, event_id, 0x9D27, 0x00E6, 0xFF)
	_ram_store(ram, writes, event_id, 0x9D29, 0x00E7, 0xBC)
	_ram_store(ram, writes, event_id, 0x9D2F, 0x00E8, destination_low)
	_ram_store(ram, writes, event_id, 0x9D34, 0x00E9, destination_high)
	_ram_store(ram, writes, event_id, 0x9D36, 0x00EB, 0x01)
	var queue_bytes: PackedByteArray = PackedByteArray()
	var cursor := queue_cursor
	for payload_index in payload.size():
		var eb_value := payload_index + 2
		_ram_store(ram, writes, event_id, 0x9D58, 0x00EB, eb_value)
		if (int(ram[0x0629]) & 0x40) != 0 \
				or cursor + (0x82 & 0x3F) >= 0x3D:
			return _refused("$9B28 reaches a capacity wait not modeled by this bounded decoder step.")
		var queue_header := 0x82
		_ram_store(ram, writes, event_id, 0x9B44, 0x0629, queue_header | 0x40)
		_ram_store(ram, writes, event_id, 0x9B4B, 0x05EA + cursor, destination_high)
		_ram_store(ram, writes, event_id, 0x9B50, 0x05E9 + cursor, destination_low + payload_index)
		_ram_store(ram, writes, event_id, 0x9B57, 0x05E8 + cursor, queue_header)
		_ram_store(ram, writes, event_id, 0x88ED, 0x05E9 + cursor + 3, payload[payload_index])
		_ram_store(ram, writes, event_id, 0x88F2, 0x05E8 + cursor + 3, 0x00)
		_ram_store(ram, writes, event_id, 0x9B60, 0x05E8 + cursor + 5, 0x00)
		cursor += 5
		_ram_store(ram, writes, event_id, 0x9B63, 0x0628, cursor)
		_ram_store(ram, writes, event_id, 0x9B6B, 0x0629, queue_header)
		_ram_store(ram, writes, event_id, 0x9D69, 0x00E8, destination_low + payload_index + 1)
		queue_bytes.append(queue_header)
		queue_bytes.append(destination_low + payload_index)
		queue_bytes.append(destination_high)
		queue_bytes.append(0x00)
		queue_bytes.append(payload[payload_index])
	_ram_store(ram, writes, event_id, 0x9D58, 0x00EB, terminator_index)
	queue_bytes.append(0x00)
	_ram_store(ram, writes, event_id, 0x9D3C, 0x00EB, terminator_index + 1)
	_ram_store(ram, writes, event_id, 0x9D43, 0x00E6, 0x0C)
	_ram_store(ram, writes, event_id, 0x9D49, 0x00E7, 0xBD)
	var next_cpu: Dictionary = cpu.duplicate(true)
	next_cpu["a"] = 0xBD
	next_cpu["x"] = 0xFF
	next_cpu["y"] = 0x0C
	next_cpu["pc"] = 0xA529
	_set_known_status(next_cpu, 0x83, 0x03)
	var source_path: Array = prefix_result.get("source_path", []).duplicate()
	source_path.append_array([0xA526, 0x9D27, 0x9D2B, 0x9D2D, 0x9D2F,
		0x9D31, 0x9D32, 0x9D34, 0x9D36])
	for index in payload.size():
		source_path.append_array([0x9D58, 0x9D5A, 0x9D5C, 0x9D5E, 0x9D62,
			0x9D64, 0x88CA, 0x88CB, 0x88CD, 0x9B28, 0x9B37, 0x9B41,
			0x9B44, 0x9B47, 0x9B4B, 0x9B4E, 0x9B50, 0x9B52, 0x9B55,
			0x9B57, 0x88D0, 0x88D1, 0x88ED, 0x88F0, 0x88F2, 0x88F5,
			0x88F6, 0x88F7, 0x9B5E, 0x9B60, 0x9B63, 0x9B66, 0x9B69,
			0x9B6B, 0x9B6E, 0x88FA, 0x9D69])
	source_path.append_array([0x9D58, 0x9D5A, 0x9D5C, 0x9D5E, 0x9D72,
		0x9D3B, 0x9D3C, 0x9D3E, 0x9D40, 0x9D41, 0x9D43, 0x9D45,
		0x9D47, 0x9D49, 0x9D4B, 0x9D4D, 0x9D4F, 0xA529])
	return {
		"ok": true,
		"status": "stopped_before_a503_next_setup_block",
		"completed": false,
		"source_rom_sha256": ROM_SHA256,
		"source_event_id": event_id,
		"source_frame": source_frame,
		"source_path": source_path,
		"entry_cpu_state": cpu_variant.duplicate(true),
		"next_cpu_state": next_cpu,
		"entry_ram": ram_variant.duplicate(true),
		"ram_after": ram,
		"ram_writes": writes,
		"logical_stack_frames": frames,
		"prefix_result": prefix_result.duplicate(true),
		"queue_state_evidence": queue_state_evidence.duplicate(true),
		"decoder_result": {"source_start": 0xBCFF, "source_end_exclusive": 0xBD0C,
			"terminator": 0xFF, "payload_bytes": payload, "payload_count": payload.size(),
			"destination_start": destination_start, "destination_end_exclusive": destination_start + payload.size(),
			"queue_start": 0x05E8, "queue_byte_count": queue_bytes.size(),
			"queue_cursor_before": queue_cursor, "queue_cursor_after": cursor,
			"queue_control_before": queue_control, "queue_control_after": int(ram[0x0629]),
			"queue_bytes": queue_bytes, "ppu_bus_events_emitted": 0,
			"capacity_yields": 0, "buffer_pending_for_rom_nmi": true},
		"source_instruction_cycles_to_return_pc": 2809,
		"independent_py65_instruction_count": 791,
		"timing_scope": "Independent py65 instruction-cycle count for A503 through the $9D27 RTS; metadata only, no route delay or physical NES timing claim.",
		"physical_stack_page_modeled": false,
		"span_hashes": {"descriptor_data": String(SPAN_SPECS["bank01_match_descriptor_data_BCFF_BD0C.bin"]["sha256"]),
			"descriptor_decoder": String(SPAN_SPECS["bank00_ppu_descriptor_decoder_9D27_9D50.bin"]["sha256"]),
			"inner_reader": String(SPAN_SPECS["bank00_ppu_descriptor_inner_reader_9D58_9D73.bin"]["sha256"]),
			"tile_write_helper": String(SPAN_SPECS["bank00_ppu_tile_write_helper_88CA_88FB.bin"]["sha256"])},
		"trace_state_used": false,
		"emulator_data_used": false,
		"candidate_state_used": false,
		"executes_6502": false,
	}


## Continues the checked A503 body from `$A529` through the three ROM text
## readers. Queue-full branches yield to a bounded `$A000` queue drain and
## resume from the same ROM text byte; this does not claim a complete NMI.
func advance_text_setup(previous_result: Dictionary, source_frame: int,
		ppu_shadow_input: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not _bytes_match(_body, 0xA529 - 0xA4EB, NEXT_SETUP_PREFIX):
		return _refused("The preserved A503 caller bytes `$A529-$A56C` differ from the checked ROM stream.")
	if source_frame < 0:
		return _refused("The A503 text continuation requires a source-frame label.")
	var prior_status := String(previous_result.get("status", ""))
	var state: Dictionary = {}
	var writes: Array[Dictionary] = []
	var ppu_bus_events: Array[Dictionary] = []
	var queue_drains: Array[Dictionary] = []
	var source_path: Array[int] = []
	var event_id := ""
	if prior_status == "stopped_before_a503_next_setup_block":
		var prior_cpu: Variant = previous_result.get("next_cpu_state", {})
		var prior_ram: Variant = previous_result.get("ram_after", {})
		if not prior_cpu is Dictionary or not prior_ram is Dictionary \
				or int(prior_cpu.get("pc", -1)) != 0xA529 \
				or String(previous_result.get("source_rom_sha256", "")) != ROM_SHA256 \
				or bool(previous_result.get("trace_state_used", true)) \
				or bool(previous_result.get("emulator_data_used", true)):
			return _refused("The first descriptor result must return to ROM `$A529` without trace-derived state.")
		state = _new_text_setup_state(previous_result)
		if not bool(state.get("ok", false)):
			return _refused(String(state.get("error", "A503 text source state is invalid.")))
		event_id = String(previous_result.get("source_event_id", "")) + ":a529-text"
		source_path = previous_result.get("source_path", []).duplicate()
		source_path.append_array([0xA529, 0xA52B, 0xA52E, 0xA530, 0xA531,
			0xA532, 0xA535, 0xA538, 0xA539, 0xA53B, 0xA53D, 0xA53F, 0xA541])
	elif prior_status == "waiting_for_a503_queue_drain":
		var prior_state: Variant = previous_result.get("continuation_state", {})
		if not prior_state is Dictionary or not bool(prior_state.get("queue_wait_pending", false)) \
				or source_frame <= int(previous_result.get("source_frame", -1)) \
				or not bool(ppu_shadow_input.get("ok", false)):
			return _refused("A queue-capacity yield needs source frame > %d (got %d) and a valid PPU-shadow receipt (ok=%s)." % [
				int(previous_result.get("source_frame", -1)), source_frame,
				str(bool(ppu_shadow_input.get("ok", false)))])
		state = prior_state.duplicate(true)
		event_id = String(previous_result.get("source_event_id", ""))
		source_path = state.get("source_path", []).duplicate()
		var drain_id := event_id + ":a000-queue-drain-%d" % int(state.get("capacity_yield_count", 0))
		var queue_ram := _queue_ram_values(state.get("ram_after", {}))
		var nmi_executor: Variant = SPECIAL_NMI_EXECUTOR_SCRIPT.new()
		var drain: Dictionary = nmi_executor.execute_source_ppu_packet_queue(
			queue_ram, ppu_shadow_input, source_frame, drain_id)
		if not bool(drain.get("ok", false)):
			return _refused("The ROM `$A000` queue drain refused the source-produced queue: "
				+ String(drain.get("error", "unknown queue error")))
		var ram: Dictionary = state.get("ram_after", {}).duplicate(true)
		for write_variant in drain.get("ram_writes", []):
			if not write_variant is Dictionary:
				return _refused("The bounded `$A000` drain returned a malformed RAM receipt.")
			var drain_write: Dictionary = write_variant
			var address := int(drain_write.get("address", -1))
			var value := int(drain_write.get("value", -1))
			if address < 0 or address >= 0x800 or value < 0 or value > 0xFF:
				return _refused("The bounded `$A000` drain returned an invalid RAM write.")
			ram[address] = value
			writes.append(_ram_write(drain_id, int(drain_write.get("source_pc", -1)), address, value))
		for event_variant in drain.get("ppu_bus_events", []):
			if event_variant is Dictionary:
				ppu_bus_events.append(event_variant.duplicate(true))
		state["ram_after"] = ram
		state["queue_wait_pending"] = false
		state["capacity_yield_count"] = int(state.get("capacity_yield_count", 0)) + 1
		var prior_history: Array = state.get("queue_drain_history", []).duplicate(true)
		prior_history.append({"source_frame": source_frame, "event_id": drain_id,
			"queue_cursor_before": int(drain.get("queue_ram_before", {}).get("cursor", -1)),
			"queue_control_before": int(drain.get("queue_ram_before", {}).get("control", -1)),
			"ppu_packet_queue": drain.get("ppu_packet_queue", {}).duplicate(true),
			"ppu_bus_events": drain.get("ppu_bus_events", []).duplicate(true),
			"surrounding_nmi_executed": false,
			"physical_nes_timing_proven": false})
		state["queue_drain_history"] = prior_history
		queue_drains.append(prior_history.back().duplicate(true))
		source_path.append_array([0x9FA8, 0xA000, 0xA00A, 0xA014, 0xA01B,
			0xA026, 0xA02A, 0xA030, 0xA039, 0xA040, 0xA043, 0xA04A,
			0xA04F, 0xA054, 0xA057, 0xA05A, 0xA05F])
	else:
		return _refused("A503 text continuation accepts only the `$A529` entry or a pending queue-capacity yield.")

	var ram_after: Dictionary = state.get("ram_after", {}).duplicate(true)
	var stream_data: PackedByteArray = PackedByteArray()
	var stream_pointer := -1
	var destination := -1
	while int(state.get("segment_index", -1)) < 3:
		var segment_index := int(state["segment_index"])
		if not bool(state.get("stream_active", false)):
			var stream := _resolve_text_setup_stream(segment_index, ram_after)
			if not bool(stream.get("ok", false)):
				return _refused(String(stream.get("error", "ROM text stream could not be resolved.")))
			stream_data = stream.get("text_bytes", PackedByteArray())
			stream_pointer = int(stream.get("source_pointer", -1))
			destination = int(stream.get("ppu_destination", -1))
			state["active_text_bytes"] = stream_data
			state["active_source_pointer"] = stream_pointer
			state["active_destination"] = destination
			state["text_cursor"] = 0
			state["stream_active"] = true
			_ram_store(ram_after, writes, event_id, 0x9D50, 0x00E6, stream_pointer & 0xFF)
			_ram_store(ram_after, writes, event_id, 0x9D52, 0x00E7, stream_pointer >> 8)
			_ram_store(ram_after, writes, event_id, 0x9D56, 0x00EB, 0xFF)
			_ram_store(ram_after, writes, event_id, 0xA53B if segment_index == 0 else 0xA546 if segment_index == 1 else 0xA553,
				0x00E8, destination & 0xFF)
			_ram_store(ram_after, writes, event_id, 0xA53F if segment_index == 0 else 0xA548 if segment_index == 1 else 0xA557,
				0x00E9, destination >> 8)
			source_path.append_array([0x9D50, 0x9D52, 0x9D54, 0x9D58])
		stream_data = state.get("active_text_bytes", PackedByteArray())
		stream_pointer = int(state.get("active_source_pointer", -1))
		destination = int(state.get("active_destination", -1))
		var cursor := int(state.get("text_cursor", -1))
		if cursor < 0 or cursor > stream_data.size():
			return _refused("The A503 ROM text cursor escaped its bounded source stream.")
		if cursor >= stream_data.size():
			_ram_store(ram_after, writes, event_id, 0x9D3C, 0x00EB, cursor)
			state["segment_index"] = segment_index + 1
			state["stream_active"] = false
			continue
		var queue_cursor := int(ram_after.get(0x0628, -1))
		var queue_control := int(ram_after.get(0x0629, -1))
		if queue_cursor < 0 or queue_cursor >= 0x40 or queue_control < 0 or queue_control > 0xFF:
			return _refused("A503 text cannot continue without a known ROM queue cursor/control byte.")
		if (queue_control & 0x40) != 0 or queue_cursor + (0x82 & 0x3F) >= 0x3D:
			if queue_cursor <= 0 or not _has_queue_terminator(ram_after, queue_cursor):
				var terminator_address := 0x05E8 + queue_cursor
				return _refused("ROM `$9B28` capacity wait at cursor `$%02X` found no source terminator at `$%04X` (known=%s value=$%02X)." % [
					queue_cursor, terminator_address, str(ram_after.has(terminator_address)),
					int(ram_after.get(terminator_address, -1)) & 0xFF])
			state["ram_after"] = ram_after
			state["queue_wait_pending"] = true
			state["source_path"] = source_path.duplicate()
			state["last_source_frame"] = source_frame
			state["source_event_id"] = event_id
			state["capacity_yield_count"] = int(state.get("capacity_yield_count", 0)) + 0
			var wait_cpu: Dictionary = state.get("cpu", {}).duplicate(true)
			wait_cpu["pc"] = 0x9FA8
			wait_cpu["a"] = 0x01
			return _text_setup_result("waiting_for_a503_queue_drain", state, writes,
				ppu_bus_events, queue_drains, source_path, source_frame, event_id,
				wait_cpu,
			{"queue_cursor": queue_cursor, "queue_control": queue_control,
				"segment_index": segment_index, "text_cursor": cursor,
				"source_pointer": stream_pointer, "ppu_destination": destination})
		var tile_value := int(stream_data[cursor])
		if tile_value >= 0xA0:
			return _refused("ROM `$88CA` text queue path encountered an unsupported high-valued control byte.")
		var queue_header := 0x82
		_ram_store(ram_after, writes, event_id, 0x9D58, 0x00EB, cursor + 1)
		_ram_store(ram_after, writes, event_id, 0x9B44, 0x0629, queue_header | 0x40)
		_ram_store(ram_after, writes, event_id, 0x9B4B, 0x05EA + queue_cursor, destination >> 8)
		_ram_store(ram_after, writes, event_id, 0x9B50, 0x05E9 + queue_cursor, destination & 0xFF)
		_ram_store(ram_after, writes, event_id, 0x9B57, 0x05E8 + queue_cursor, queue_header)
		_ram_store(ram_after, writes, event_id, 0x88F2, 0x05EB + queue_cursor, 0)
		_ram_store(ram_after, writes, event_id, 0x88ED, 0x05EC + queue_cursor, tile_value)
		_ram_store(ram_after, writes, event_id, 0x9B60, 0x05ED + queue_cursor, 0)
		queue_cursor += 5
		_ram_store(ram_after, writes, event_id, 0x9B63, 0x0628, queue_cursor)
		_ram_store(ram_after, writes, event_id, 0x9B6B, 0x0629, queue_header)
		_ram_store(ram_after, writes, event_id, 0x9D69, 0x00E8, (destination + 1) & 0xFF)
		source_path.append_array([0x9D58, 0x9D5A, 0x9D5C, 0x9D5E, 0x9D62,
			0x9D64, 0x88CA, 0x88CD, 0x9B28, 0x9B37, 0x9B41,
			0x9B44, 0x9B4B, 0x9B50, 0x9B57, 0x88ED, 0x88F2,
			0x9B60, 0x9B63, 0x9B6B, 0x9D69])
		state["text_cursor"] = cursor + 1
		state["active_destination"] = (destination + 1) & 0xFFFF
		state["ram_after"] = ram_after

	_ram_store(ram_after, writes, event_id, 0xA55E, 0x007B, 0x00)
	_ram_store(ram_after, writes, event_id, 0xA562, 0x008E, 0x00)
	_ram_store(ram_after, writes, event_id, 0xA566, 0x008F, 0x2E)
	var final_cpu := Dictionary(state.get("cpu", {})).duplicate(true)
	final_cpu["a"] = 0x04
	final_cpu["x"] = 0x37
	final_cpu["y"] = 0x07
	final_cpu["pc"] = 0xA56C
	state["ram_after"] = ram_after
	state["source_path"] = source_path.duplicate()
	state["queue_wait_pending"] = false
	state["last_source_frame"] = source_frame
	state["cpu"] = final_cpu.duplicate(true)
	source_path.append_array([0xA544, 0xA546, 0xA548, 0xA54A, 0xA63C,
		0xA54D, 0xA54F, 0xA551, 0xA553, 0xA555, 0xA557, 0xA559, 0xA63C,
		0xA55C, 0xA55E, 0xA560, 0xA562, 0xA564, 0xA566, 0xA568, 0xA56A])
	return _text_setup_result("stopped_before_a503_fade_helper", state, writes,
		ppu_bus_events, queue_drains, source_path, source_frame, event_id, final_cpu,
		{"queue_cursor": int(ram_after.get(0x0628, -1)),
			"queue_control": int(ram_after.get(0x0629, -1)), "next_source_pc": 0xA56C})


func _new_text_setup_state(descriptor_result: Dictionary) -> Dictionary:
	var ram: Dictionary = descriptor_result.get("ram_after", {}).duplicate(true)
	for address in [0x0026, 0x002A, 0x002B, 0x0628, 0x0629]:
		if not ram.has(address):
			return {"ok": false, "error": "A503 text setup lacks source RAM `$%04X`." % address}
	if int(ram[0x0026]) != 0 or int(ram[0x002A]) != 0 or int(ram[0x002B]) != 3 \
			or int(ram[0x0628]) != 0x32 or int(ram[0x0629]) != 0x82:
		return {"ok": false, "error": "The fresh-match A503 text selector or pending queue differs from the decoded route."}
	var cpu: Dictionary = descriptor_result.get("next_cpu_state", {}).duplicate(true)
	return {"ok": true, "ram_after": ram, "cpu": cpu, "segment_index": 0,
		"text_cursor": 0, "stream_active": false, "capacity_yield_count": 0,
		"queue_wait_pending": false, "queue_drain_history": [],
		"source_path": descriptor_result.get("source_path", []).duplicate()}


func _resolve_text_setup_stream(segment_index: int, ram: Dictionary) -> Dictionary:
	var pointer := -1
	var text := PackedByteArray()
	var destination := -1
	if segment_index == 0:
		var descriptor_byte := int(_index_descriptor[int(ram[0x0026])])
		var text_index := descriptor_byte & 0x0F
		var table_offset := text_index * 2
		if table_offset + 1 >= _second_descriptor_pointer_table.size():
			return {"ok": false, "error": "A503 text selector escapes the verified `$BD64` pointer table."}
		pointer = int(_second_descriptor_pointer_table[table_offset]) \
			| (int(_second_descriptor_pointer_table[table_offset + 1]) << 8)
		if pointer != 0xBD7C or int(_second_descriptor_text[_second_descriptor_text.size() - 1]) != 0xFF:
			return {"ok": false, "error": "Fresh-match text selector no longer resolves to the terminated `$BD7C` ROM stream."}
		text = _second_descriptor_text.slice(0, _second_descriptor_text.size() - 1)
		destination = 0x2207
	elif segment_index in [1, 2]:
		var text_id := int(ram[0x002A]) if segment_index == 1 else int(ram[0x002B])
		var expected_id := 0x00 if segment_index == 1 else 0x03
		if text_id != expected_id:
			return {"ok": false, "error": "Fresh-match text ID $%02X has no bounded ROM text payload." % text_id}
		var table_offset := text_id * 2
		if table_offset + 1 >= _text_pointer_table.size():
			return {"ok": false, "error": "A503 text ID escapes the verified `$BDA8` pointer table."}
		pointer = int(_text_pointer_table[table_offset]) \
			| (int(_text_pointer_table[table_offset + 1]) << 8)
		if segment_index == 1 and pointer == 0xBDF2:
			text = _text_id_00
			destination = 0x21D0
		elif segment_index == 2 and pointer == 0xBE09:
			text = _text_id_03
			destination = 0x2250
		else:
			return {"ok": false, "error": "A503 text ID pointer `$%04X` has no hash-checked payload." % pointer}
		if text.is_empty() or int(text[text.size() - 1]) != 0xFF:
			return {"ok": false, "error": "A503 participant text lacks its ROM `$FF` terminator."}
		text = text.slice(0, text.size() - 1)
	else:
		return {"ok": false, "error": "A503 text setup requested an unsupported segment."}
	return {"ok": true, "source_pointer": pointer, "ppu_destination": destination,
		"text_bytes": text, "terminator": 0xFF}


func _queue_ram_values(ram_values: Dictionary) -> Dictionary:
	var selected: Dictionary = {}
	for address in [0x0020, 0x0021, 0x0628, 0x0629]:
		if not ram_values.has(address) or int(ram_values[address]) < 0 \
				or int(ram_values[address]) > 0xFF:
			selected[address] = -1
		else:
			selected[address] = int(ram_values[address])
	var cursor := int(selected.get(0x0628, -1))
	if cursor >= 0 and cursor < 0x40:
		for address in range(0x05E8, 0x05E8 + cursor + 1):
			selected[address] = int(ram_values.get(address, -1))
	return selected


func _has_queue_terminator(ram: Dictionary, cursor: int) -> bool:
	return ram.has(0x05E8 + cursor) and int(ram[0x05E8 + cursor]) == 0


func _text_setup_result(status: String, state: Dictionary, writes: Array[Dictionary],
		ppu_events: Array[Dictionary], drains: Array[Dictionary], source_path: Array[int],
		source_frame: int, event_id: String, cpu: Dictionary, boundary: Dictionary) -> Dictionary:
	var ram_after: Dictionary = state.get("ram_after", {}).duplicate(true)
	var all_drains: Array = state.get("queue_drain_history", []).duplicate(true)
	return {"ok": true, "status": status, "completed": false,
		"source_rom_sha256": ROM_SHA256, "source_event_id": event_id,
		"source_frame": source_frame, "source_path": source_path.duplicate(),
		"entry_source_pc": 0xA529, "next_cpu_state": cpu.duplicate(true),
		"ram_after": ram_after, "ram_writes": writes.duplicate(true),
		"queue_boundary": boundary.duplicate(true),
		"ppu_bus_events": ppu_events.duplicate(true),
		"queue_drain": drains.duplicate(true), "queue_drain_history": all_drains,
		"capacity_yield_count": int(state.get("capacity_yield_count", 0)),
		"continuation_state": state.duplicate(true),
		"surrounding_nmi_executed": false, "controller_scan_executed": false,
		"sound_driver_executed": false, "physical_nes_timing_proven": false,
		"trace_state_used": false, "emulator_data_used": false,
		"candidate_state_used": false, "executes_6502": false}


func _ram_write(event_id: String, source_pc: int, address: int, value: int) -> Dictionary:
	return {"source_event_id": event_id, "source_pc": source_pc,
		"address": address, "value": value}


func _ram_store(ram: Dictionary, writes: Array[Dictionary], event_id: String,
		source_pc: int, address: int, value: int) -> void:
	ram[address] = value & 0xFF
	writes.append(_ram_write(event_id, source_pc, address, value & 0xFF))


func _set_known_status(cpu: Dictionary, mask: int, value: int) -> void:
	var prior_mask := int(cpu.get("p_known_mask", 0)) & 0xFF
	var prior_value := int(cpu.get("p_known_value", 0)) & prior_mask
	var merged_mask := prior_mask | mask
	cpu["p_known_mask"] = merged_mask & 0xFF
	cpu["p_known_value"] = (((prior_value & ~mask) | (value & mask)) & merged_mask) & 0xFF


func _bytes_match(source: PackedByteArray, start: int, expected: Array) -> bool:
	if start < 0 or start + expected.size() > source.size():
		return false
	for index in expected.size():
		if int(source[start + index]) != int(expected[index]):
			return false
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_rejected", "error": error_message,
		"trace_state_used": false, "emulator_data_used": false,
		"candidate_state_used": false, "executes_6502": false}
