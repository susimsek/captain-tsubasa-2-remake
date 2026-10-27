extends RefCounted
class_name RomEcStreamPlayer
## Stateful model of the opening EC stream consumer. It uses the byte-preserved
## decoder and exposes the three staged PPU packets; it is not a CPU/NMI
## emulator. The caller advances it only at ROM `$89FF` calls from the text
## speed helper, after each `$9FA8(A=1)` wait.

const DECODER := preload("res://scripts/opening/rom_ec_stream_decoder.gd")
const STREAM_CPU_START := 0xBD0C
const CAPTURED_POINTER_TABLE_INDICES: Array[int] = [0, 2, 4, 5]
const INITIAL_RAM_0653 := 0x01
const PPU_CONTROL := 0x84 # PPUDATA increment +32, four writes per record.
const PPU_PACKET_BASE_ADDRESSES: Array[int] = [0x2302, 0x2303, 0x2304]

var active := false
var ram_0652 := 0
var ram_0653 := 0
var next_record_source_frame := -1
var records_staged := 0
var loop_count := 0
var last_event: Dictionary = {}
var last_error := ""

var _decoder: RomEcStreamDecoder
var _stream_base_cpu_pointer := STREAM_CPU_START
var _first_record_source_frame := -1
var _last_consumer_tick_source_frame := -1
var _consumer_tick_count := 0
var _staged_packets: Array[Dictionary] = []
var _staged_group_source_frame := -1


## Start an EC stream from its ROM pointer-table entry. Its first record is
## consumed at the first later `$89FF` tick, not at a capture-supplied frame.
func start(pointer_table_index: int) -> bool:
	_reset()
	if not CAPTURED_POINTER_TABLE_INDICES.has(pointer_table_index):
		return _fail("Only EC pointer-table entries 0, 2, 4, and 5 have synchronized opening captures.")
	_decoder = DECODER.new()
	if not _decoder.load_ec_stream(pointer_table_index):
		return _fail("Could not load the hash-checked ROM EC stream.")
	_stream_base_cpu_pointer = int(_decoder.stream_base_cpu_pointer)
	ram_0652 = 0x80
	ram_0653 = INITIAL_RAM_0653
	active = true
	last_event = {
		"kind": "started",
		"pointer_table_index": pointer_table_index,
		"stream_base_pointer": "$%04X" % _stream_base_cpu_pointer,
		"stream_pointer": "$%04X" % int(_decoder.stream_cpu_pointer),
		"first_record_source_frame": -1,
		"first_record_frame_is_capture_anchor": false,
		"first_record_trigger": "$89FF after a text glyph's $9FA8(A=1) speed-wait tick",
		"ram_0652": ram_0652,
		"ram_0653": ram_0653,
	}
	return true


## Call once for each source `$89FF` invocation. The ROM only reaches this
## routine through `$84FC -> $895D`; `$895D` invokes `$89FF` once per
## `$9FA8(A=1)` text-speed wait. Commit pending packets first at the frame's
## NMI boundary, then call this method for any consumer tick in that frame.
func advance_consumer_tick(source_frame: int) -> Dictionary:
	if not active:
		return {"kind": "inactive", "source_frame": source_frame}
	if source_frame <= _last_consumer_tick_source_frame:
		return {"kind": "duplicate_or_reversed_frame", "source_frame": source_frame}
	_last_consumer_tick_source_frame = source_frame
	_consumer_tick_count += 1
	if not _staged_packets.is_empty():
		return {
			"kind": "waiting_for_nmi_commit",
			"source_frame": source_frame,
			"staged_source_frame": _staged_group_source_frame,
			"expected_commit_source_frame": _staged_group_source_frame + 1,
		}
	if records_staged > 0 and ram_0653 > 1:
		ram_0653 -= 1
		next_record_source_frame = source_frame + ram_0653
		last_event = {
			"kind": "delay_countdown",
			"source_frame": source_frame,
			"next_record_source_frame": next_record_source_frame,
			"ram_0652": ram_0652,
			"ram_0653": ram_0653,
		}
		return last_event.duplicate(true)

	var pointer_before := int(_decoder.stream_cpu_pointer)
	var decoded: Dictionary = _decoder.decode_next()
	if decoded.is_empty():
		active = false
		return _fail_event("ROM EC decoder returned an invalid stream record.", source_frame)
	match str(decoded.get("kind", "")):
		"record":
			return _stage_record(decoded, pointer_before, source_frame)
		"stop":
			active = false
			ram_0652 = 0
			last_event = {
				"kind": "stopped",
				"source_frame": source_frame,
				"stream_pointer": str(decoded.get("pointer", "")),
				"ram_0652": ram_0652,
				"ram_0653": ram_0653,
				"bank_restore_source_ram_0056": true,
				"ram_0653_cleared_by_source": false,
			}
			return last_event.duplicate(true)
		_:
			active = false
			return _fail_event("Unknown decoded EC stream event.", source_frame)


## Apply the staged 3×4 tile group at the next NMI boundary. The packet bytes
## themselves are from the ROM; addresses and +32 stepping are capture-backed.
func commit_pending_packets(source_frame: int, ppu_memory: Dictionary) -> Dictionary:
	if _staged_packets.is_empty():
		return {"kind": "no_pending_packets", "source_frame": source_frame}
	if source_frame <= _staged_group_source_frame:
		return {
			"kind": "commit_not_due",
			"source_frame": source_frame,
			"staged_source_frame": _staged_group_source_frame,
			"expected_commit_source_frame": _staged_group_source_frame + 1,
		}
	var writes: Array[Dictionary] = []
	for packet in _staged_packets:
		var address := int(packet["ppu_address"])
		var payload: PackedByteArray = packet["payload"]
		for payload_index in range(payload.size()):
			var destination := address + payload_index * 0x20
			var value := int(payload[payload_index])
			ppu_memory[destination] = value
			writes.append({"ppu_address": destination, "value": value})
	var result := {
		"kind": "committed",
		"source_frame": source_frame,
		"staged_source_frame": _staged_group_source_frame,
		"packet_count": _staged_packets.size(),
		"ppu_write_count": writes.size(),
		"control_byte": PPU_CONTROL,
		"writes": writes,
		"capture_matched_frame_delay": source_frame == _staged_group_source_frame + 1,
		"ppu_pixel_edge_measured": false,
	}
	_staged_packets.clear()
	_staged_group_source_frame = -1
	return result


func get_pending_packets() -> Array[Dictionary]:
	return _staged_packets.duplicate(true)


## The script command EC FF clears the stream-active byte ($0652). The source
## replay shows that a record staged earlier in the same frame is not committed
## by a later NMI after this stop; discard the presenter's pending copy here.
func stop_from_command(source_frame: int = -1) -> Dictionary:
	var canceled_packet_count := _staged_packets.size()
	active = false
	ram_0652 = 0
	_staged_packets.clear()
	_staged_group_source_frame = -1
	last_event = {
		"kind": "stopped_by_ec_ff_command",
		"source_frame": source_frame,
		"ram_0652": ram_0652,
		"ram_0653": ram_0653,
		"stream_base_pointer": "$%04X" % _stream_base_cpu_pointer,
		"canceled_pending_packet_count": canceled_packet_count,
		"pending_packet_count": 0,
		"pending_packet_cancel_source": "same-input FCEUX PPU trace shows the following EE $9953 zero fill remains final",
	}
	return last_event.duplicate(true)


func get_state() -> Dictionary:
	return {
		"active": active,
		"ram_0652": ram_0652,
		"ram_0653": ram_0653,
		"next_record_source_frame": next_record_source_frame,
		"next_record_source_frame_is_uninterrupted_tick_estimate": records_staged > 0,
		"records_staged": records_staged,
		"loop_count": loop_count,
		"consumer_tick_count": _consumer_tick_count,
		"staged_packet_count": _staged_packets.size(),
		"staged_group_source_frame": _staged_group_source_frame,
		"last_event": last_event.duplicate(true),
		"last_error": last_error,
		"stream_base_pointer": "$%04X" % _stream_base_cpu_pointer,
		"first_record_source_frame": _first_record_source_frame,
		"first_record_frame_is_capture_anchor": false,
		"first_record_trigger": "$89FF after a text glyph's $9FA8(A=1) speed-wait tick",
	}


func _stage_record(decoded: Dictionary, pointer_before: int, source_frame: int) -> Dictionary:
	var payload_quads: Array = decoded.get("payload_quads", [])
	if payload_quads.size() != PPU_PACKET_BASE_ADDRESSES.size():
		active = false
		return _fail_event("EC record does not contain three four-byte PPU payloads.", source_frame)
	var packets: Array[Dictionary] = []
	for packet_index in range(PPU_PACKET_BASE_ADDRESSES.size()):
		var payload: PackedByteArray = payload_quads[packet_index]
		if payload.size() != 4:
			active = false
			return _fail_event("EC record packet payload must be exactly four bytes.", source_frame)
		var address := PPU_PACKET_BASE_ADDRESSES[packet_index]
		var encoded := PackedByteArray([PPU_CONTROL, address & 0xFF, (address >> 8) & 0xFF])
		encoded.append_array(payload)
		packets.append({
			"control": PPU_CONTROL,
			"ppu_address": address,
			"payload": payload.duplicate(),
			"queue_bytes": encoded,
			"queue_encoded_bytes": encoded.size(),
		})
	_staged_packets = packets
	_staged_group_source_frame = source_frame
	var is_first_record := records_staged == 0
	records_staged += 1
	var lookahead_delay := int(decoded.get("lookahead_delay_low3", 0))
	# All reachable regular bytes in the selected streams have nonzero delays
	# (3–7). This is the nominal due frame; task suspension can stretch it.
	if lookahead_delay <= 0:
		active = false
		return _fail_event("EC record has an unmodeled zero delay.", source_frame)
	var pointer_after := int(_decoder.stream_cpu_pointer)
	if pointer_after < pointer_before:
		loop_count += 1
	if is_first_record:
		_first_record_source_frame = source_frame
	ram_0652 = 0x80 | ((pointer_after - _stream_base_cpu_pointer) & 0x3F)
	ram_0653 = lookahead_delay
	next_record_source_frame = source_frame + lookahead_delay
	last_event = {
		"kind": "record_staged",
		"source_frame": source_frame,
		"stream_pointer": str(decoded.get("pointer", "")),
		"stream_base_pointer": "$%04X" % _stream_base_cpu_pointer,
		"next_stream_pointer": "$%04X" % pointer_after,
		"group_index": int(decoded.get("group_index", -1)),
		"group_pointer": str(decoded.get("group_pointer", "")),
		"stream_byte": str(decoded.get("stream_byte", "")),
		"lookahead_delay": lookahead_delay,
		"consumer_tick_count": _consumer_tick_count,
		"ram_0652": ram_0652,
		"ram_0653": ram_0653,
		"next_record_source_frame": next_record_source_frame,
		"next_record_source_frame_is_uninterrupted_tick_estimate": true,
		"loop_restarted": pointer_after < pointer_before,
		"loop_count": loop_count,
		"packet_count": packets.size(),
		"ppu_addresses": PPU_PACKET_BASE_ADDRESSES.duplicate(),
		"packets": packets.duplicate(true),
		"nmi_commit_source_frame": source_frame + 1,
		"queue_control_byte": PPU_CONTROL,
		"queue_control_meaning": "capture-backed $2000=$84: +32 PPUDATA increment; four writes",
		"packet_addresses_source": "capture of first group and repeated later groups; range is fixed by ROM call arguments and bus snapshots",
		"first_record_on_this_tick": is_first_record,
		"first_record_source_frame": _first_record_source_frame,
		"first_record_frame_is_capture_anchor": false,
	}
	return last_event.duplicate(true)


func _reset() -> void:
	active = false
	ram_0652 = 0
	ram_0653 = 0
	next_record_source_frame = -1
	records_staged = 0
	loop_count = 0
	last_event.clear()
	last_error = ""
	_decoder = null
	_stream_base_cpu_pointer = STREAM_CPU_START
	_first_record_source_frame = -1
	_last_consumer_tick_source_frame = -1
	_consumer_tick_count = 0
	_staged_packets.clear()
	_staged_group_source_frame = -1


func _fail(message: String) -> bool:
	last_error = message
	push_error(message)
	return false


func _fail_event(message: String, source_frame: int) -> Dictionary:
	last_error = message
	last_event = {"kind": "error", "source_frame": source_frame, "error": message}
	push_error(message)
	return last_event.duplicate(true)
