extends RefCounted
class_name RomNormalNmiPpuQueueConsumer
## Source-byte model of the normal-NMI $C8FB primary/secondary PPU queue paths.
## It emits ordered PPU bus operations; PPU hardware side effects remain with
## the caller that owns the source-derived PPU model.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/normal_nmi_ppu_queue_transfer/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_SCHEMA := "rom-normal-nmi-ppu-queue-transfer-sources-v1"
const ENTRY_GATE_SOURCE := "normal_nmi_c8fb_transfer_gate_and_consumer.bin"
const NMI_CALL_SOURCE := "normal_nmi_call_c799_to_c8fb.bin"
const EXPECTED_SOURCE_HASHES := {
	ENTRY_GATE_SOURCE: "7509e02000e7dde21037b3c3532265f784744e51fa0aa03ee5edeb778e2aecb7",
	NMI_CALL_SOURCE: "77d15140839e5c0213db71f8555d4e6d19b5a903c8bdbc85f39058c5baedce8a",
}

const CPU_RAM_SIZE := 0x0800
const CALLER_QUEUE_COUNT_ADDR := 0x0498
const PRIMARY_QUEUE_RECORDS_BASE := 0x0499
const PRIMARY_QUEUE_RECORDS_END := 0x04A5
const PACKET_BUFFER_BASE := 0x04A5
const PACKET_READY_FLAG_ADDR := 0x0515
const PACKET_READY_MASK := 0x80
const CALLER_PC := 0xC8FB
const TRANSFER_PC := 0xC951
const NORMAL_NMI_CALL_PC := 0xC799
const PRIMARY_QUEUE_PC := 0xC900
const ENTRY_PROOF_SCHEMA := "rom-normal-nmi-c8fb-entry-proof-v1"
const MAX_OUTER_PACKETS := 0x100
const MAX_PRIMARY_QUEUE_RECORDS := 4
const MAX_PRIMARY_PACKETS := 0x100
const MAX_PRIMARY_PAYLOAD_BYTES := 0x100

const EXPECTED_GATE_BYTES := [0xAD, 0x98, 0x04, 0xF0, 0x51]
const EXPECTED_TRANSFER_BYTES := [
	0xAD, 0x15, 0x05, # LDA $0515
	0x10, 0x2B, # BPL $C981
	0xA2, 0x00, # LDX #$00
	0x8E, 0x15, 0x05, # STX $0515
	0xBD, 0xA5, 0x04, # LDA $04A5,X (packet length)
	0xF0, 0x21, # BEQ $C981
	0xA8, # TAY
	0xE8, # INX
	0xBD, 0xA5, 0x04, # LDA $04A5,X (address low)
	0x48, # PHA
	0xE8, # INX
	0xBD, 0xA5, 0x04, # LDA $04A5,X (address high)
	0x2C, 0x02, 0x20, # BIT $2002
	0x8D, 0x06, 0x20, # STA $2006
	0x68, # PLA
	0x8D, 0x06, 0x20, # STA $2006
	0xE8, # INX
	0xBD, 0xA5, 0x04, # LDA $04A5,X
	0x8D, 0x07, 0x20, # STA $2007
	0xE8, # INX
	0x88, # DEY
	0xD0, 0xF6, # BNE $C975
	0xF0, 0xDA, # BEQ $C95B (Y is zero after payload)
	0x60, # RTS
]
const EXPECTED_NORMAL_NMI_CALL_BYTES := [0x20, 0xFB, 0xC8]

var last_error := ""
var _source_bytes: Dictionary = {}


## Consume one source-owned normal-NMI transfer boundary.
##
## `ram_state` is the 2 KiB CPU-RAM image indexed by CPU address modulo $0800.
## `ppu_state` is opaque caller-owned PPU state. This component returns it
## unchanged because it emits the source CPU's ordered bus operations rather
## than emulating RP2C02 register side effects.
##
## `normal_nmi_proof` must carry the source event contract: normal NMI, call
## site $C799, entry $C8FB, $001B.6 clear, and this ROM hash.
func consume(ram_state: PackedByteArray, ppu_state: Dictionary,
		normal_nmi_proof: Dictionary) -> Dictionary:
	last_error = ""
	if not _load_sources():
		return _rejected("source_unavailable", last_error)
	if ram_state.size() != CPU_RAM_SIZE:
		return _rejected("invalid_ram_state", "Expected a 2 KiB source-owned CPU-RAM image.")
	if not _valid_normal_nmi_proof(normal_nmi_proof):
		return _rejected("missing_normal_nmi_proof",
			"Expected a source-owned normal-NMI proof for the $C799->$C8FB call on this ROM.")

	var primary_count := int(ram_state[CALLER_QUEUE_COUNT_ADDR])
	if primary_count != 0:
		return _consume_primary_queue(ram_state, ppu_state, primary_count)
	var ready_flag := int(ram_state[PACKET_READY_FLAG_ADDR])
	if (ready_flag & PACKET_READY_MASK) == 0:
		return _rejected("secondary_queue_not_ready",
			"The $C951 source routine returns when $0515.7 is clear.")

	var updated_ram := ram_state.duplicate()
	# Source $C958 executes STX $0515 with X=$00 before reading any packet bytes.
	updated_ram[PACKET_READY_FLAG_ADDR] = 0
	var bus_events: Array[Dictionary] = []
	var ppu_writes: Array[Dictionary] = []
	var packet_summaries: Array[Dictionary] = []
	var cursor := 0
	var outer_indices_seen: Dictionary = {}
	var packet_index := 0
	var sequence := 0

	while packet_index < MAX_OUTER_PACKETS:
		if outer_indices_seen.has(cursor):
			return _rejected("unterminated_packet_list",
				"The source's 8-bit X index revisited an outer packet cursor without encountering a zero length.")
		outer_indices_seen[cursor] = true
		var length := _read_indexed_ram(updated_ram, cursor)
		if length == 0:
			return {
				"ok": true,
				"status": "transferred",
				"queue_kind": "secondary",
				"source_rom_sha256": EXPECTED_ROM_SHA256,
				"source_entry_pc": CALLER_PC,
				"source_transfer_pc": TRANSFER_PC,
				"source_nmi_call_pc": NORMAL_NMI_CALL_PC,
				"source_gate_value_0498": primary_count,
				"source_ready_flag_before": ready_flag,
				"source_ready_flag_after": int(updated_ram[PACKET_READY_FLAG_ADDR]),
				"packets": packet_summaries,
				"bus_events": bus_events,
				"ppu_writes": ppu_writes,
				"ppu_write_count": ppu_writes.size(),
				"ppu_state": ppu_state.duplicate(true),
				"ppu_state_applied": false,
				"updated_ram": updated_ram,
				"runtime_rom_dependency": false,
			}

		var packet_start_cursor := cursor
		cursor = _increment_x(cursor)
		var address_low := _read_indexed_ram(updated_ram, cursor)
		cursor = _increment_x(cursor)
		var address_high := _read_indexed_ram(updated_ram, cursor)
		var packet_address := (address_high << 8) | address_low
		var packet_summary := {
			"index": packet_index,
			"buffer_offset": packet_start_cursor,
			"length": length,
			"address_high": address_high,
			"address_low": address_low,
			"address": packet_address,
		}
		packet_summaries.append(packet_summary)

		bus_events.append(_bus_read(sequence, 0xC96A, 0x2002, packet_index,
			"status_read_before_ppuaddr_writes"))
		sequence += 1
		var high_write := _bus_write(sequence, 0xC96D, 0x2006, address_high,
			packet_index, "address_high")
		bus_events.append(high_write)
		ppu_writes.append(high_write.duplicate())
		sequence += 1
		var low_write := _bus_write(sequence, 0xC971, 0x2006, address_low,
			packet_index, "address_low")
		bus_events.append(low_write)
		ppu_writes.append(low_write.duplicate())
		sequence += 1
		cursor = _increment_x(cursor)

		var payload_values: Array[int] = []
		for payload_index in range(length):
			var value := _read_indexed_ram(updated_ram, cursor)
			payload_values.append(value)
			var data_write := _bus_write(sequence, 0xC978, 0x2007, value,
				packet_index, "data")
			bus_events.append(data_write)
			ppu_writes.append(data_write.duplicate())
			sequence += 1
			cursor = _increment_x(cursor)
		packet_summary["payload"] = payload_values
		packet_index += 1

	return _rejected("unterminated_packet_list",
		"The packet count exceeded the source's 8-bit X index without finding a zero length.")


## Models the source's `$C900-$C950` branch selected by nonzero `$0498`.
## This bounded runtime consumer supports the observed positive CPU-RAM pointer
## form. Bank-switched pointers and records beyond the four-byte slots reserved
## at `$0499-$04A4` fail closed until their source mapping is implemented.
func _consume_primary_queue(ram_state: PackedByteArray, ppu_state: Dictionary,
		primary_count: int) -> Dictionary:
	if primary_count > MAX_PRIMARY_QUEUE_RECORDS:
		return _rejected("primary_queue_count_out_of_supported_range",
			"The source queue count exceeds the four records occupying `$0499-$04A4`.")
	var record_offset := PRIMARY_QUEUE_RECORDS_BASE + 3 * (primary_count - 1)
	if record_offset + 2 >= PRIMARY_QUEUE_RECORDS_END:
		return _rejected("primary_queue_record_out_of_range",
			"The `$C900` indexed record would overlap the secondary queue buffer.")
	var bank := int(ram_state[record_offset])
	var pointer_low := int(ram_state[record_offset + 1])
	var pointer_high := int(ram_state[record_offset + 2])
	if (pointer_high & 0x80) != 0:
		return _rejected("primary_queue_banked_pointer_unsupported",
			"The `$C91B` mapper-switch branch is ROM-confirmed but is outside this RAM-pointer consumer.")
	var pointer := (pointer_high << 8) | pointer_low
	if pointer > 0x1FFF:
		return _rejected("primary_queue_pointer_outside_cpu_ram",
			"The supported `$C900` path currently requires a pointer inside the 2 KiB CPU-RAM image.")
	if pointer + 0xFF >= CPU_RAM_SIZE:
		return _rejected("primary_queue_pointer_range_unavailable",
			"The indexed source packet range crosses the captured CPU-RAM image.")

	var updated_ram := ram_state.duplicate()
	var decremented_count := (primary_count - 1) & 0xFF
	updated_ram[CALLER_QUEUE_COUNT_ADDR] = decremented_count
	updated_ram[0x0077] = pointer_low
	updated_ram[0x0078] = pointer_high
	var ram_writes: Array[Dictionary] = [
		{"source_pc": 0xC900, "address": CALLER_QUEUE_COUNT_ADDR,
			"old": primary_count, "new": decremented_count},
		{"source_pc": 0xC912, "address": 0x0077,
			"old": int(ram_state[0x0077]), "new": pointer_low},
		{"source_pc": 0xC917, "address": 0x0078,
			"old": int(ram_state[0x0078]), "new": pointer_high},
	]
	var bus_events: Array[Dictionary] = []
	var ppu_writes: Array[Dictionary] = []
	var packet_summaries: Array[Dictionary] = []
	var cursor := 0
	var packet_index := 0
	var payload_total := 0
	var sequence := 0
	while packet_index < MAX_PRIMARY_PACKETS:
		var length := _read_primary_pointer_ram(ram_state, pointer, cursor)
		if length == 0:
			return {
				"ok": true,
				"status": "primary_queue_consumed" if not ppu_writes.is_empty() else "primary_queue_consumed_empty",
				"queue_kind": "primary",
				"source_rom_sha256": EXPECTED_ROM_SHA256,
				"source_entry_pc": CALLER_PC,
				"source_transfer_pc": PRIMARY_QUEUE_PC,
				"source_nmi_call_pc": NORMAL_NMI_CALL_PC,
				"source_gate_value_0498": primary_count,
				"primary_queue_count_before": primary_count,
				"primary_queue_count_after": decremented_count,
				"primary_record_index": primary_count - 1,
				"primary_record_bank": bank,
				"primary_record_address": record_offset,
				"primary_buffer_pointer": pointer,
				"source_ready_flag_before": int(ram_state[PACKET_READY_FLAG_ADDR]),
				"source_ready_flag_after": int(updated_ram[PACKET_READY_FLAG_ADDR]),
				"packets": packet_summaries,
				"bus_events": bus_events,
				"ppu_writes": ppu_writes,
				"ppu_write_count": ppu_writes.size(),
				"ram_writes": ram_writes,
				"ppu_state": ppu_state.duplicate(true),
				"ppu_state_applied": false,
				"updated_ram": updated_ram,
				"runtime_rom_dependency": false,
			}
		var packet_start_cursor := cursor
		cursor = (cursor + 1) & 0xFF
		var address_low := _read_primary_pointer_ram(ram_state, pointer, cursor)
		cursor = (cursor + 1) & 0xFF
		var address_high := _read_primary_pointer_ram(ram_state, pointer, cursor)
		var packet_address := (address_high << 8) | address_low
		if payload_total + length > MAX_PRIMARY_PAYLOAD_BYTES:
			return _rejected("primary_queue_payload_limit_exceeded",
				"The primary queue source stream exceeded the bounded 256-byte payload window.")
		var packet_summary := {
			"index": packet_index,
			"buffer_address": pointer + packet_start_cursor,
			"buffer_offset": packet_start_cursor,
			"length": length,
			"address_high": address_high,
			"address_low": address_low,
			"address": packet_address,
		}
		packet_summaries.append(packet_summary)
		bus_events.append(_bus_read(sequence, 0xC93A, 0x2002, packet_index,
			"status_read_before_ppuaddr_writes"))
		sequence += 1
		var high_write := _bus_write(sequence, 0xC93D, 0x2006, address_high,
			packet_index, "address_high")
		bus_events.append(high_write)
		ppu_writes.append(high_write.duplicate())
		sequence += 1
		cursor = (cursor + 1) & 0xFF
		var low_write := _bus_write(sequence, 0xC941, 0x2006, address_low,
			packet_index, "address_low")
		bus_events.append(low_write)
		ppu_writes.append(low_write.duplicate())
		sequence += 1
		var payload_values: Array[int] = []
		for payload_index in range(length):
			var value := _read_primary_pointer_ram(ram_state, pointer, cursor)
			payload_values.append(value)
			var data_write := _bus_write(sequence, 0xC947, 0x2007, value,
				packet_index, "data")
			bus_events.append(data_write)
			ppu_writes.append(data_write.duplicate())
			sequence += 1
			cursor = (cursor + 1) & 0xFF
		payload_total += length
		packet_summary["payload"] = payload_values
		packet_index += 1
	return _rejected("primary_queue_packet_limit_exceeded",
		"The primary queue source stream exceeded 256 packet headers without a zero terminator.")


func _read_primary_pointer_ram(ram: PackedByteArray, pointer: int, y: int) -> int:
	return int(ram[pointer + (y & 0xFF)])


func _valid_normal_nmi_proof(proof: Dictionary) -> bool:
	return str(proof.get("schema", "")) == ENTRY_PROOF_SCHEMA \
		and str(proof.get("rom_sha256", "")) == EXPECTED_ROM_SHA256 \
		and str(proof.get("nmi_kind", "")) == "normal" \
		and int(proof.get("call_site_pc", -1)) == NORMAL_NMI_CALL_PC \
		and int(proof.get("entry_pc", -1)) == CALLER_PC \
		and (int(proof.get("ram_001b_at_dispatch", -1)) & 0x40) == 0 \
		and bool(proof.get("source_dispatch_observed", false))


func _read_indexed_ram(ram: PackedByteArray, x: int) -> int:
	return int(ram[PACKET_BUFFER_BASE + (x & 0xFF)])


func _increment_x(value: int) -> int:
	return (value + 1) & 0xFF


func _bus_read(sequence: int, source_pc: int, address: int, packet_index: int,
		effect: String) -> Dictionary:
	return {
		"sequence": sequence,
		"operation": "read",
		"source_pc": source_pc,
		"ppu_register": address,
		"packet_index": packet_index,
		"side_effect": effect,
	}


func _bus_write(sequence: int, source_pc: int, address: int, value: int,
		packet_index: int, role: String) -> Dictionary:
	return {
		"sequence": sequence,
		"operation": "write",
		"source_pc": source_pc,
		"ppu_register": address,
		"value": value,
		"packet_index": packet_index,
		"role": role,
	}


func _load_sources() -> bool:
	if not _source_bytes.is_empty():
		return true
	if not FileAccess.file_exists(MANIFEST_PATH):
		return _fail("The normal-NMI PPU queue source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("The normal-NMI PPU queue source manifest is malformed.")
	var manifest: Dictionary = parsed
	if str(manifest.get("schema", "")) != SOURCE_SCHEMA \
			or str(manifest.get("rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("The source manifest targets an unexpected ROM revision.")
	var entries_by_path: Dictionary = {}
	for entry_variant in manifest.get("entries", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_path[str(entry.get("path", ""))] = entry
	for filename_variant in EXPECTED_SOURCE_HASHES:
		var filename := str(filename_variant)
		var entry: Dictionary = entries_by_path.get(filename, {})
		var resource_path := SOURCE_ROOT + filename
		var expected_hash := str(EXPECTED_SOURCE_HASHES[filename])
		if entry.is_empty() or not FileAccess.file_exists(resource_path):
			return _fail("A preserved ROM source span is missing: %s" % filename)
		var bytes := FileAccess.get_file_as_bytes(resource_path)
		if bytes.size() != int(entry.get("size_bytes", -1)) \
				or FileAccess.get_sha256(resource_path) != expected_hash \
				or str(entry.get("sha256", "")) != expected_hash:
			return _fail("A ROM source span failed size/hash validation: %s" % filename)
		_source_bytes[filename] = bytes

	var combined: PackedByteArray = _source_bytes[ENTRY_GATE_SOURCE]
	var gate_offset := 0xC8FB - 0xC8FB
	var transfer_offset := 0xC951 - 0xC8FB
	if not _bytes_match(combined, gate_offset, EXPECTED_GATE_BYTES) \
			or not _bytes_match(combined, transfer_offset, EXPECTED_TRANSFER_BYTES):
		return _fail("The preserved C8FB/C951 instructions differ from the verified source bytes.")
	if not _bytes_match(_source_bytes[NMI_CALL_SOURCE], 0, EXPECTED_NORMAL_NMI_CALL_BYTES):
		return _fail("The preserved C799 normal-NMI call bytes do not target C8FB.")
	return true


func _bytes_match(source: PackedByteArray, offset: int, expected: Array) -> bool:
	if offset < 0 or offset + expected.size() > source.size():
		return false
	for index in expected.size():
		if int(source[offset + index]) != int(expected[index]):
			return false
	return true


func _fail(message: String) -> bool:
	last_error = message
	return false


func _rejected(status: String, message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "status": status, "error": message}
