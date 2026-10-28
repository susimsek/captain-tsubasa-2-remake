extends RefCounted
class_name FirstCommandFieldPacketProducer
## Byte-preserved, ROM-logic decoder for bank-$1F $F015/$F114.
## Callers must supply descriptor $063D and placement byte $05CE from a
## source-driven route model. This class never reads emulator captures.

const RESOURCE_ROOT := "res://reference/rom_extract/gameplay/first_command_field/packet_producer/"
const MANIFEST_PATH := RESOURCE_ROOT + "manifest.json"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

const SOURCE_HASHES := {
	"bank_1f_f015_f159_code.bin": "df7c650c952fb5dfc9a8a10de43f739c9fc4cbdef343bae7ba70c4921a281dc9",
	"bank_1f_f10e_column_offsets.bin": "1c846bd6348a9804749036a00066f0ed14056c3460e99b3db213fb29495d3428",
	"bank_1f_f15a_descriptor_addresses.bin": "d765b599dadfd6746f01ca5b98b7da7a1f805567f273a47f3c75fe27f15df95e",
	"bank_1f_f16a_descriptor_tiles.bin": "2f6df5e795164038a6a2e2880eb60163a05ddebdfec1bd08e572d05e786afdae",
	"bank_1f_f182_packet_pointers.bin": "2ae69763add6f9e22f4ae522b3b325c406270612d77551c8a39a74c754532359",
	"bank_1f_f18e_packet_streams.bin": "af16320fffdd68422d11c2d198a93b84abba67e2d2e07e1d26441da0d1e50fc0",
	"bank_0b_8327_8360_map_placement_writer.bin": "e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853",
	"bank_0b_animation_70_route_prefix.bin": "cde9952f184fd4cebc101a1a51f1286f417e7412c58ad66e1118c99bc97c9219",
}

const STREAM_BASE_CPU := 0xF18E
const STREAM_END_CPU_EXCLUSIVE := 0xF206
const COLUMN_OFFSETS_CPU := 0xF10E
const DESCRIPTOR_ADDRESSES_CPU := 0xF15A
const DESCRIPTOR_TILES_CPU := 0xF16A
const STREAM_POINTERS_CPU := 0xF182
const DESCRIPTOR_SPECIAL := 0x03
const MAP_PLACEMENT_CODE_OFFSET := 18
const MAP_PLACEMENT_SOURCE_BYTES := [
	0xAD, 0xCD, 0x05, # LDA $05CD
	0xF0, 0x04, # BEQ $8342
	0x29, 0x20, # AND #$20
	0x09, 0x80, # ORA #$80
	0x8D, 0xCE, 0x05, # STA $05CE
	0x09, 0x80, # ORA #$80
	0x49, 0x20, # EOR #$20
	0x8D, 0xCD, 0x05, # STA $05CD
]

var last_error := ""
var _sources: Dictionary = {}


## Decode the six F015 iterations into the exact PPU transfer packet bytes.
## `source_05ce` is an input from the live ROM route; it is intentionally not
## guessed from an endpoint capture or defaulted here.
func build_f015_packets(descriptor_id: int, source_05ce: int) -> Dictionary:
	last_error = ""
	if descriptor_id < 0 or descriptor_id >= DESCRIPTOR_SPECIAL:
		return _fail_result("F015 source decoder supports descriptors $00-$02; descriptor $03 has a separate ROM branch.")
	if source_05ce < 0 or source_05ce > 0xFF:
		return _fail_result("F015 requires a byte-valued, source-derived $05CE placement input.")
	if not _load_sources():
		return _fail_result(last_error)

	var column_offsets: PackedByteArray = _sources["bank_1f_f10e_column_offsets.bin"]
	var descriptor_addresses: PackedByteArray = _sources["bank_1f_f15a_descriptor_addresses.bin"]
	var descriptor_tiles: PackedByteArray = _sources["bank_1f_f16a_descriptor_tiles.bin"]
	var pointer_table: PackedByteArray = _sources["bank_1f_f182_packet_pointers.bin"]
	var streams: PackedByteArray = _sources["bank_1f_f18e_packet_streams.bin"]
	var descriptor_offset := descriptor_id * 4
	var tile_descriptor_offset := descriptor_id * 6
	if descriptor_offset + 3 >= descriptor_addresses.size() or tile_descriptor_offset + 5 >= descriptor_tiles.size():
		return _fail_result("Descriptor index exceeds the preserved F015 source tables.")

	var base_tile_low := int(descriptor_addresses[descriptor_offset])
	var base_tile_high := int(descriptor_addresses[descriptor_offset + 1])
	var base_attribute_low := int(descriptor_addresses[descriptor_offset + 2])
	var base_attribute_high := int(descriptor_addresses[descriptor_offset + 3])
	var packets: Array[Dictionary] = []
	var serialized_batches: Array[PackedByteArray] = []
	var tile_write_count := 0
	var attribute_write_count := 0
	var stream_signatures: Array[Dictionary] = []
	var page_nibble := source_05ce >> 4

	for stream_index in range(6):
		var batch_serialized := PackedByteArray()
		var attribute_low := (base_attribute_low + int(column_offsets[stream_index])) & 0xFF
		attribute_low |= source_05ce & 0x20
		var attribute_high := base_attribute_high | page_nibble
		var attribute_tile := int(descriptor_tiles[tile_descriptor_offset + stream_index])
		var attribute_packet := _make_packet(attribute_low, attribute_high, [attribute_tile], "attribute")
		packets.append(attribute_packet)
		batch_serialized.append_array(_serialize_packet(attribute_packet))
		attribute_write_count += 1

		var pointer_index := stream_index * 2
		var stream_cpu := int(pointer_table[pointer_index]) | (int(pointer_table[pointer_index + 1]) << 8)
		if stream_cpu < STREAM_BASE_CPU or stream_cpu >= STREAM_END_CPU_EXCLUSIVE:
			return _fail_result("F015 pointer $%04X is outside the preserved packet-stream range." % stream_cpu)
		var stream_offset := stream_cpu - STREAM_BASE_CPU
		var stream_packets := 0
		var stream_tiles := 0
		var found_terminator := false
		while stream_offset < streams.size():
			var payload_length := int(streams[stream_offset])
			stream_offset += 1
			if payload_length == 0:
				found_terminator = true
				batch_serialized.append(0)
				break
			if payload_length > 0x20 or stream_offset + 2 + payload_length > streams.size():
				return _fail_result("F114 stream at $%04X has a malformed packet length." % stream_cpu)
			var low_delta := int(streams[stream_offset])
			var high_delta := int(streams[stream_offset + 1])
			stream_offset += 2
			var address_sum := base_tile_low + low_delta
			var output_low := address_sum & 0xFF
			var output_carry := 1 if address_sum > 0xFF else 0
			# F114 ORs the packet's high-byte delta with $05CE's high nibble
			# when the descriptor base is below $2200, then restores low-byte carry.
			var placement_high := page_nibble if base_tile_high < 0x22 else 0
			var output_high := base_tile_high + (placement_high | high_delta) + output_carry
			var payload: Array[int] = []
			for payload_index in range(payload_length):
				payload.append(int(streams[stream_offset + payload_index]))
			stream_offset += payload_length
			var tile_packet := _make_packet(output_low, output_high & 0xFF, payload, "tile")
			packets.append(tile_packet)
			batch_serialized.append_array(_serialize_packet(tile_packet))
			tile_write_count += payload_length
			stream_tiles += payload_length
			stream_packets += 1
		if not found_terminator:
			return _fail_result("F114 stream at $%04X has no 00 terminator." % stream_cpu)
		serialized_batches.append(batch_serialized)
		stream_signatures.append({
			"input_index": stream_index,
			"source_pointer": "0x%04X" % stream_cpu,
			"packet_count": stream_packets,
			"tile_write_count": stream_tiles,
		})

	if descriptor_id == 2 and (tile_write_count != 60 or attribute_write_count != 6):
		return _fail_result("Descriptor $02 must decode to the observed 60 tile and six attribute writes.")
	return {
		"ok": true,
		"descriptor_id": descriptor_id,
		"source_05ce": source_05ce,
		"packets": packets,
		"serialized_batches": serialized_batches,
		"tile_write_count": tile_write_count,
		"attribute_write_count": attribute_write_count,
		"stream_signatures": stream_signatures,
		"source_inputs_runtime_ready": false,
		"runtime_gap": "The active route must supply ROM-derived $063D and $05CE; this decoder deliberately does not infer either from endpoint RAM/PPU captures.",
	}


## Execute the placement-state portion of bank-$0B $8327 for one ROM map
## callback. The caller owns the previous $05CD value and decides when the
## decoded callback invokes this transition; this function never schedules or
## invents a callback event.
func advance_map_placement_state(previous_05cd: int) -> Dictionary:
	last_error = ""
	if previous_05cd < 0 or previous_05cd > 0xFF:
		return _fail_result("The map-placement transition requires a byte-valued source $05CD state.")
	if not _load_sources():
		return _fail_result(last_error)
	var source: PackedByteArray = _sources["bank_0b_8327_8360_map_placement_writer.bin"]
	var end_offset := MAP_PLACEMENT_CODE_OFFSET + MAP_PLACEMENT_SOURCE_BYTES.size()
	if end_offset > source.size():
		return _fail_result("The preserved bank-$0B placement handler is truncated.")
	for index in MAP_PLACEMENT_SOURCE_BYTES.size():
		if int(source[MAP_PLACEMENT_CODE_OFFSET + index]) != int(MAP_PLACEMENT_SOURCE_BYTES[index]):
			return _fail_result("Bank-$0B $8327 placement instructions differ from the verified ROM source bytes.")
	var written_05ce := 0
	if previous_05cd != 0:
		written_05ce = (previous_05cd & 0x20) | 0x80
	var next_05cd := ((written_05ce | 0x80) ^ 0x20) & 0xFF
	return {
		"ok": true,
		"previous_05cd": previous_05cd,
		"written_05ce": written_05ce,
		"next_05cd": next_05cd,
		"source_bank": 0x0B,
		"source_entry_pc": 0x8327,
		"source_05ce_write_pc": 0x8342,
		"source_05cd_write_pc": 0x8349,
	}


## Apply a previously decoded F015 packet set to a PPU-address dictionary.
## This is deliberately separate from `build_f015_packets()` so the caller
## cannot accidentally apply packets before validating route state.
func apply_packets(ppu_memory: Dictionary, packet_result: Dictionary) -> bool:
	if not bool(packet_result.get("ok", false)):
		return false
	for packet_variant in packet_result.get("packets", []):
		if not packet_variant is Dictionary:
			return false
		var packet: Dictionary = packet_variant
		var address := int(packet.get("address", -1))
		var payload: Array = packet.get("payload", [])
		if address < 0 or payload.is_empty():
			return false
		for index in payload.size():
			ppu_memory[address + index] = int(payload[index]) & 0xFF
	return true


## Decode the separate F0B5 holder-tile write from already source-derived
## coordinates. This routine never chooses the holder or coordinates itself.
func build_f0b5_holder_packet(descriptor_id: int, source_05ce: int,
		source_x: int, source_y: int) -> Dictionary:
	last_error = ""
	if descriptor_id < 0 or descriptor_id >= 4 or source_05ce < 0 or source_05ce > 0xFF:
		return _fail_result("F0B5 inputs are outside their byte ranges.")
	if source_x < 0 or source_x > 0xFF or source_y < 0 or source_y > 0xFF:
		return _fail_result("F0B5 requires byte-valued, ROM-derived holder coordinates.")
	if not _load_sources():
		return _fail_result(last_error)
	var descriptor_addresses: PackedByteArray = _sources["bank_1f_f15a_descriptor_addresses.bin"]
	var descriptor_offset := descriptor_id * 4
	var row_delta := ((source_y - 0x50) & 0xFF) & 0xF0
	var address_offset := (row_delta << 1) & 0xFF
	var high_offset := 1 if (row_delta & 0x80) != 0 else 0
	var column_delta := ((source_x - 0x30) & 0xFF) >> 4
	var address_sum := address_offset + column_delta
	address_offset = address_sum & 0xFF
	if address_sum > 0xFF:
		high_offset = (high_offset + 1) & 0xFF
	var base_low := int(descriptor_addresses[descriptor_offset])
	var base_high := int(descriptor_addresses[descriptor_offset + 1])
	address_sum = base_low + address_offset
	var output_low := address_sum & 0xFF
	var output_high := (base_high + high_offset + (1 if address_sum > 0xFF else 0)) & 0xFF
	output_high |= source_05ce >> 4
	var packet := _make_packet(output_low, output_high, [0xA2], "holder")
	return {
		"ok": true,
		"packet": packet,
		"source_x": source_x,
		"source_y": source_y,
		"source_05ce": source_05ce,
		"source_inputs_runtime_ready": false,
		"runtime_gap": "The caller must derive holder slot/coordinates and $05CE through live ROM state before applying this packet.",
	}


func _make_packet(low: int, high: int, payload: Array, kind: String) -> Dictionary:
	return {
		"address": ((high & 0xFF) << 8) | (low & 0xFF),
		"payload": payload,
		"kind": kind,
	}


func _serialize_packet(packet: Dictionary) -> PackedByteArray:
	var result := PackedByteArray()
	var payload: Array = packet["payload"]
	result.append(payload.size() & 0xFF)
	result.append(int(packet["address"]) & 0xFF)
	result.append((int(packet["address"]) >> 8) & 0xFF)
	for value in payload:
		result.append(int(value) & 0xFF)
	return result


func _load_sources() -> bool:
	if not _sources.is_empty():
		return true
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("The F015 source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("The F015 source manifest is malformed.")
	var manifest: Dictionary = parsed
	if str(manifest.get("rom_sha256", "")) != EXPECTED_ROM_SHA256 or \
			str(manifest.get("schema", "")) != "first-command-field-packet-producer-sources-v1":
		return _fail("The F015 source manifest targets an unexpected ROM/revision.")
	var rows_by_path: Dictionary = {}
	for row_variant in manifest.get("entries", []):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			rows_by_path[str(row.get("path", ""))] = row
	for filename in SOURCE_HASHES:
		var filename_text: String = str(filename)
		var row: Dictionary = rows_by_path.get(filename_text, {})
		var path: String = RESOURCE_ROOT + filename_text
		if row.is_empty() or not FileAccess.file_exists(path):
			return _fail("Missing preserved F015 ROM source: %s" % filename_text)
		var bytes := FileAccess.get_file_as_bytes(path)
		var expected_hash := str(SOURCE_HASHES[filename])
		if bytes.size() != int(row.get("size_bytes", -1)) or \
				FileAccess.get_sha256(path) != expected_hash or \
				str(row.get("sha256", "")) != expected_hash:
			return _fail("F015 ROM source failed size/hash validation: %s" % filename_text)
		_sources[filename_text] = bytes
	return true


func _fail(message: String) -> bool:
	last_error = message
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	return {"ok": false, "error": message}
