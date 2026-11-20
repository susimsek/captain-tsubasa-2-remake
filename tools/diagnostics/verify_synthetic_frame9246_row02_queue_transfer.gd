extends SceneTree
## Synthetic fixture diagnostic for the frame-9246 row-$02 queue snapshot.
## This checks the ordinary NMI queue decoder's bus-event output only. It does
## not replay the route, apply PPU register effects, or establish pixel parity.

const CONSUMER_SCRIPT := preload("res://scripts/gameplay/rom_normal_nmi_ppu_queue_consumer.gd")
const CPU_RAM_SIZE := 0x0800
const PACKET_BUFFER_BASE := 0x04A5
const READY_FLAG_ADDR := 0x0515
const ENTRY_PROOF_SCHEMA := "rom-normal-nmi-c8fb-entry-proof-v1"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const FOLLOWUP_TEXT := [0x61, 0x6C, 0x69, 0x79, 0x6F, 0x72, 0x21]
const PACKET_LENGTH := 0x0E

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ram := _build_synthetic_frame_9246_queue()
	var ppu_state := {"fixture": "synthetic_frame_9246", "unchanged": true}
	var consumer: RefCounted = CONSUMER_SCRIPT.new()
	var result: Dictionary = consumer.call("consume", ram, ppu_state, _synthetic_normal_nmi_proof())

	_check(bool(result.get("ok", false)),
		"synthetic ready secondary queue passes the existing normal-NMI source contract")
	if bool(result.get("ok", false)):
		_assert_transfer(result, ram, ppu_state)

	if _failures == 0:
		print("PASS: synthetic frame-9246 row-$02 queue emits the expected normal-NMI PPU bus sequence.")
		print("LIMIT: no emulator replay, PPU state application, rendered-frame check, or pixel parity is established.")
	else:
		printerr("FAIL: %d synthetic row-$02 queue assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _build_synthetic_frame_9246_queue() -> PackedByteArray:
	var ram := PackedByteArray()
	ram.resize(CPU_RAM_SIZE)
	var queue := PackedByteArray([
		0x0E, 0xF0, 0x22,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x0E, 0x10, 0x23,
		0x61, 0x6C, 0x69, 0x79, 0x6F, 0x72, 0x21,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, # zero-length terminator
	])
	for index in queue.size():
		ram[PACKET_BUFFER_BASE + index] = queue[index]
	ram[0x0498] = 0
	ram[READY_FLAG_ADDR] = 0x80
	return ram


func _synthetic_normal_nmi_proof() -> Dictionary:
	# This proof-shaped input satisfies the consumer's gate; it is deliberately
	# synthetic and does not assert that the corresponding NMI was traced here.
	return {
		"schema": ENTRY_PROOF_SCHEMA,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"nmi_kind": "normal",
		"call_site_pc": 0xC799,
		"entry_pc": 0xC8FB,
		"ram_001b_at_dispatch": 0x00,
		"source_dispatch_observed": true,
	}


func _assert_transfer(result: Dictionary, input_ram: PackedByteArray,
		input_ppu_state: Dictionary) -> void:
	var packets: Array = result.get("packets", [])
	var events: Array = result.get("bus_events", [])
	var ppu_writes: Array = result.get("ppu_writes", [])
	var output_ram: PackedByteArray = result.get("updated_ram", PackedByteArray())
	var first_payload := PackedByteArray()
	first_payload.resize(PACKET_LENGTH)
	var second_payload := PackedByteArray(FOLLOWUP_TEXT)
	for _index in range(FOLLOWUP_TEXT.size(), PACKET_LENGTH):
		second_payload.append(0)

	_check(str(result.get("status", "")) == "transferred"
		and str(result.get("queue_kind", "")) == "secondary"
		and int(result.get("source_transfer_pc", -1)) == 0xC951,
		"consumer selects the source $C951 secondary-queue branch")
	_check(int(result.get("source_ready_flag_before", -1)) == 0x80
		and int(result.get("source_ready_flag_after", -1)) == 0
		and output_ram.size() == CPU_RAM_SIZE and output_ram[READY_FLAG_ADDR] == 0,
		"consumer clears $0515 before transferring packet contents")
	_check(packets.size() == 2 and ppu_writes.size() == 32 and events.size() == 34,
		"two 14-byte packets emit two status reads and 32 PPU writes")
	if packets.size() == 2:
		_check(int(packets[0].get("length", -1)) == PACKET_LENGTH
			and int(packets[0].get("address", -1)) == 0x22F0
			and packets[0].get("payload", []) == _as_int_array(first_payload),
			"first packet targets $22F0 with fourteen zero tile IDs")
		_check(int(packets[1].get("length", -1)) == PACKET_LENGTH
			and int(packets[1].get("address", -1)) == 0x2310
			and packets[1].get("payload", []) == _as_int_array(second_payload),
			"second packet targets $2310 with `aliyor!` bytes and seven trailing zero tile IDs")
	_check(_events_match(events, first_payload, second_payload),
		"ordered $2002/$2006/$2007 event values match both packet address/data streams")
	_check(result.get("ppu_state", {}) == input_ppu_state
		and not bool(result.get("ppu_state_applied", true)),
		"queue consumer returns ordered bus operations without applying PPU memory effects")
	_check(output_ram.size() == CPU_RAM_SIZE
		and output_ram.slice(PACKET_BUFFER_BASE, PACKET_BUFFER_BASE + 35)
			== input_ram.slice(PACKET_BUFFER_BASE, PACKET_BUFFER_BASE + 35)
		and not bool(result.get("runtime_rom_dependency", true)),
		"synthetic packet bytes stay intact and consumer has no runtime ROM dependency")


func _events_match(events: Array, first_payload: PackedByteArray,
		second_payload: PackedByteArray) -> bool:
	if events.size() != 34:
		return false
	if not _event_is(events, 0, "read", 0x2002, -1, 0xC96A, 0) \
			or not _event_is(events, 1, "write", 0x2006, 0x22, 0xC96D, 0) \
			or not _event_is(events, 2, "write", 0x2006, 0xF0, 0xC971, 0):
		return false
	for index in PACKET_LENGTH:
		if not _event_is(events, 3 + index, "write", 0x2007,
				int(first_payload[index]), 0xC978, 0):
			return false
	if not _event_is(events, 17, "read", 0x2002, -1, 0xC96A, 1) \
			or not _event_is(events, 18, "write", 0x2006, 0x23, 0xC96D, 1) \
			or not _event_is(events, 19, "write", 0x2006, 0x10, 0xC971, 1):
		return false
	for index in PACKET_LENGTH:
		if not _event_is(events, 20 + index, "write", 0x2007,
				int(second_payload[index]), 0xC978, 1):
			return false
	return true


func _event_is(events: Array, index: int, operation: String, register: int,
		value: int, source_pc: int, packet_index: int) -> bool:
	if index < 0 or index >= events.size() or not events[index] is Dictionary:
		return false
	var event: Dictionary = events[index]
	if int(event.get("sequence", -1)) != index \
			or str(event.get("operation", "")) != operation \
			or int(event.get("ppu_register", -1)) != register \
			or int(event.get("source_pc", -1)) != source_pc \
			or int(event.get("packet_index", -1)) != packet_index:
		return false
	return operation == "read" or int(event.get("value", -1)) == value


func _as_int_array(bytes: PackedByteArray) -> Array[int]:
	var values: Array[int] = []
	for value in bytes:
		values.append(int(value))
	return values


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
	else:
		print("PASS: " + label)
