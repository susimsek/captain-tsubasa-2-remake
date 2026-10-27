extends RefCounted
class_name RomEcStreamDecoder
## Decodes the byte records selected by the opening's EC command.
## This resolves ROM data structure only; frame cadence and PPU packet effects
## are handled by RomEcStreamPlayer, with cooperative scheduling caller-driven.

const SOURCE_PATH := "res://reference/rom_extract/intro/ec_bank6_bd00_beff.bin"
const SOURCE_SHA256 := "2d794632b7681192ade347ec004d15397726952c67c820bf104391894d27d2e1"
const SOURCE_CPU_START := 0xBD00
const SOURCE_BYTES := 0x200
const STREAM_CPU_START := 0xBD0C
const STREAM_CPU_END_EXCLUSIVE := 0xBD80
const GROUP_CPU_START := 0xBD80
const GROUP_RECORD_BYTES := 12
const GROUP_COUNT := 32

var _source_bytes := PackedByteArray()
var stream_base_cpu_pointer := STREAM_CPU_START
var stream_cpu_pointer := STREAM_CPU_START
var stream_finished := false


func load_ec_stream(pointer_table_index: int) -> bool:
	if not _load_source_bytes():
		return false
	if pointer_table_index < 0 or pointer_table_index >= 6:
		push_error("EC stream pointer-table index is outside the six verified entries.")
		return false
	var pointer_offset := pointer_table_index * 2
	var pointer := int(_source_bytes[pointer_offset]) | (int(_source_bytes[pointer_offset + 1]) << 8)
	return set_stream_pointer(pointer)


func set_stream_pointer(cpu_pointer: int) -> bool:
	if _source_bytes.is_empty() and not _load_source_bytes():
		return false
	if cpu_pointer < STREAM_CPU_START or cpu_pointer >= STREAM_CPU_END_EXCLUSIVE:
		push_error("EC stream pointer must address the decoded bank-6 command area.")
		return false
	stream_base_cpu_pointer = cpu_pointer
	stream_cpu_pointer = cpu_pointer
	stream_finished = false
	return true


## Decode one stream command without applying its timing or PPU effects.
## `$FE` resets the cursor to the selected stream's base pointer and immediately
## decodes its first byte. `$FF` terminates.
func decode_next() -> Dictionary:
	if _source_bytes.is_empty() and not _load_source_bytes():
		return {}
	if stream_finished:
		return {"kind": "finished", "pointer": _format_cpu_pointer(stream_cpu_pointer)}
	for _control_budget in range(2):
		var stream_offset := stream_cpu_pointer - SOURCE_CPU_START
		if stream_offset < 0 or stream_offset >= STREAM_CPU_END_EXCLUSIVE - SOURCE_CPU_START:
			return {}
		var stream_byte := int(_source_bytes[stream_offset])
		if stream_byte == 0xFF:
			stream_finished = true
			return {
				"kind": "stop",
				"opcode": "$FF",
				"pointer": _format_cpu_pointer(stream_cpu_pointer),
			}
		if stream_byte == 0xFE:
			# EC's base pointer is held separately in $0654/$0655; $FE clears
			# the progress index in $0652, so the next read returns to that base.
			stream_cpu_pointer = stream_base_cpu_pointer
			continue
		var group_index := (stream_byte & 0xF8) >> 3
		if group_index < 0 or group_index >= GROUP_COUNT:
			return {}
		var lookahead_offset := stream_offset + 1
		if lookahead_offset >= STREAM_CPU_END_EXCLUSIVE - SOURCE_CPU_START:
			return {}
		var lookahead_byte := int(_source_bytes[lookahead_offset])
		var group_offset := (GROUP_CPU_START - SOURCE_CPU_START) + group_index * GROUP_RECORD_BYTES
		var group_bytes := _source_bytes.slice(group_offset, group_offset + GROUP_RECORD_BYTES)
		var current_pointer := stream_cpu_pointer
		stream_cpu_pointer += 1
		return {
			"kind": "record",
			"pointer": _format_cpu_pointer(current_pointer),
			"stream_byte": "$%02X" % stream_byte,
			"group_index": group_index,
			"group_pointer": _format_cpu_pointer(GROUP_CPU_START + group_index * GROUP_RECORD_BYTES),
			"group_bytes": group_bytes,
			"payload_quads": [group_bytes.slice(0, 4), group_bytes.slice(4, 8), group_bytes.slice(8, 12)],
			"lookahead_byte": "$%02X" % lookahead_byte,
			"lookahead_delay_low3": lookahead_byte & 0x07,
			"next_pointer": _format_cpu_pointer(stream_cpu_pointer),
			"ppu_addresses": [],
			"note": "Payload bytes decoded; addresses/timing are supplied by the separate consumer model.",
		}
	return {}


func _load_source_bytes() -> bool:
	_source_bytes = FileAccess.get_file_as_bytes(SOURCE_PATH)
	if _source_bytes.size() != SOURCE_BYTES:
		push_error("Extracted EC pointer/stream/group data has an unexpected size.")
		_source_bytes.clear()
		return false
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK or hash_context.update(_source_bytes) != OK:
		push_error("Could not hash the extracted EC data.")
		_source_bytes.clear()
		return false
	if hash_context.finish().hex_encode() != SOURCE_SHA256:
		push_error("Extracted EC data does not match its recorded ROM source hash.")
		_source_bytes.clear()
		return false
	return true


func _format_cpu_pointer(address: int) -> String:
	return "$%04X" % address
