extends SceneTree
## Focused ROM-source verifier for both normal-NMI PPU queue paths.
## All runtime inputs below are explicit source-state vectors, never captures.

const CONSUMER_SCRIPT := preload("res://scripts/gameplay/rom_normal_nmi_ppu_queue_consumer.gd")
const CPU_RAM_SIZE := 0x0800
const ENTRY_PROOF_SCHEMA := "rom-normal-nmi-c8fb-entry-proof-v1"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ppu_state := {
		"source_owner": "test_fixture",
		"ppu_memory": PackedByteArray([0x11, 0x22, 0x33]),
		"register_shadow": {"$2000": 0x80, "$2006": 0x24},
	}
	var proof := _valid_proof()
	var ram := _new_ram()
	ram[0x04A5] = 2
	ram[0x04A6] = 0x34
	ram[0x04A7] = 0x21
	ram[0x04A8] = 0xAA
	ram[0x04A9] = 0xBB
	ram[0x04AA] = 1
	ram[0x04AB] = 0xE5
	ram[0x04AC] = 0x23
	ram[0x04AD] = 0xCC
	ram[0x04AE] = 0
	ram[0x0515] = 0x80
	var consumer: RefCounted = CONSUMER_SCRIPT.new()
	var result: Dictionary = consumer.call("consume", ram, ppu_state, proof)
	_check(bool(result.get("ok", false)), "source-owned normal-NMI event consumes valid secondary queue")
	if bool(result.get("ok", false)):
		var writes: Array = result.get("ppu_writes", [])
		var events: Array = result.get("bus_events", [])
		var updated_ram: PackedByteArray = result.get("updated_ram", PackedByteArray())
		_check(writes.size() == 7, "two packet headers produce seven ordered PPU writes")
		_check(events.size() == 9, "each packet emits the source $2002 read before its writes")
		_check(_event_is(events, 0, "read", 0x2002, -1, 0xC96A),
			"first packet begins with the source BIT $2002 read")
		_check(_event_is(events, 1, "write", 0x2006, 0x21, 0xC96D)
			and _event_is(events, 2, "write", 0x2006, 0x34, 0xC971),
			"packet header is length, low address, high address; PPUADDR writes high then low")
		_check(_event_is(events, 3, "write", 0x2007, 0xAA, 0xC978)
			and _event_is(events, 4, "write", 0x2007, 0xBB, 0xC978),
			"packet payload bytes become ordered PPUDATA writes")
		_check(_event_is(events, 5, "read", 0x2002, -1, 0xC96A)
			and _event_is(events, 8, "write", 0x2007, 0xCC, 0xC978),
			"second packet begins at the next length record and ends at its payload")
		_check(updated_ram.size() == CPU_RAM_SIZE and updated_ram[0x0515] == 0,
			"ROM STX $0515 clears the complete ready byte before packet parsing")
		_check(updated_ram[0x04A5] == ram[0x04A5]
			and updated_ram[0x04AE] == ram[0x04AE], "packet bytes remain source-owned and unchanged")
		_check(result.get("ppu_state", {}) == ppu_state and not bool(result.get("ppu_state_applied", true)),
			"PPU state is passed through; no unverified PPU side effects are invented")
		_check(not bool(result.get("runtime_rom_dependency", true)),
			"runtime reads preserved source bytes, not the original ROM file")

	var gate_ram := _new_ram()
	gate_ram[0x0498] = 2
	gate_ram[0x049C] = 0
	gate_ram[0x049D] = 0x6C
	gate_ram[0x049E] = 0x04
	gate_ram[0x046C] = 2
	gate_ram[0x046D] = 0x00
	gate_ram[0x046E] = 0x20
	gate_ram[0x046F] = 0xAA
	gate_ram[0x0470] = 0xBB
	gate_ram[0x0471] = 0
	gate_ram[0x0515] = 0x80
	var gate_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var gate_result: Dictionary = gate_consumer.call("consume", gate_ram, ppu_state, proof)
	_check(bool(gate_result.get("ok", false))
		and str(gate_result.get("queue_kind", "")) == "primary"
		and int(gate_result.get("source_transfer_pc", -1)) == 0xC900,
		"nonzero $0498 enters the ROM primary queue routine at $C900")
	if bool(gate_result.get("ok", false)):
		var primary_events: Array = gate_result.get("bus_events", [])
		var primary_ram: PackedByteArray = gate_result.get("updated_ram", PackedByteArray())
		_check(primary_events.size() == 5
			and _event_is(primary_events, 0, "read", 0x2002, -1, 0xC93A)
			and _event_is(primary_events, 1, "write", 0x2006, 0x20, 0xC93D)
			and _event_is(primary_events, 2, "write", 0x2006, 0x00, 0xC941)
			and _event_is(primary_events, 3, "write", 0x2007, 0xAA, 0xC947)
			and _event_is(primary_events, 4, "write", 0x2007, 0xBB, 0xC947),
			"primary packets preserve ROM $2002/$2006/$2007 bus order")
		_check(primary_ram.size() == CPU_RAM_SIZE
			and primary_ram[0x0498] == 1
			and primary_ram[0x0077] == 0x6C and primary_ram[0x0078] == 0x04
			and primary_ram[0x0515] == 0x80,
			"primary source decrements $0498, loads $77/$78, and preserves $0515")
		_check(gate_result.get("ppu_state", {}) == ppu_state
			and not bool(gate_result.get("ppu_state_applied", true)),
			"primary source emits bus writes without guessing PPU memory effects")
	var banked_primary_ram := gate_ram.duplicate()
	banked_primary_ram[0x049E] = 0x84
	var banked_primary_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var banked_primary_result: Dictionary = banked_primary_consumer.call(
		"consume", banked_primary_ram, ppu_state, proof)
	_check(not bool(banked_primary_result.get("ok", true))
		and str(banked_primary_result.get("status", "")) == "primary_queue_banked_pointer_unsupported",
		"bank-switching pointer path fails closed before partial RAM mutation")
	var oversized_primary_ram := gate_ram.duplicate()
	oversized_primary_ram[0x0498] = 5
	var oversized_primary_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var oversized_primary_result: Dictionary = oversized_primary_consumer.call(
		"consume", oversized_primary_ram, ppu_state, proof)
	_check(not bool(oversized_primary_result.get("ok", true))
		and str(oversized_primary_result.get("status", "")) == "primary_queue_count_out_of_supported_range",
		"primary count beyond the four-record RAM window is rejected safely")

	var not_ready_ram := _new_ram()
	not_ready_ram[0x0515] = 0x7F
	var not_ready_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var not_ready_result: Dictionary = not_ready_consumer.call("consume", not_ready_ram, ppu_state, proof)
	_check(not bool(not_ready_result.get("ok", true))
		and str(not_ready_result.get("status", "")) == "secondary_queue_not_ready",
		"$0515 with bit 7 clear rejects even when lower flag bits are nonzero")

	var missing_proof_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var missing_proof_result: Dictionary = missing_proof_consumer.call("consume", ram, ppu_state, {})
	_check(not bool(missing_proof_result.get("ok", true))
		and str(missing_proof_result.get("status", "")) == "missing_normal_nmi_proof",
		"the consumer rejects without the normal-NMI $C799->$C8FB source event")
	var wrong_mode_proof := _valid_proof()
	wrong_mode_proof["ram_001b_at_dispatch"] = 0x40
	var wrong_mode_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var wrong_mode_result: Dictionary = wrong_mode_consumer.call("consume", ram, ppu_state, wrong_mode_proof)
	_check(not bool(wrong_mode_result.get("ok", true))
		and str(wrong_mode_result.get("status", "")) == "missing_normal_nmi_proof",
		"the consumer rejects the alternate NMI path when $001B.6 is set")

	var empty_ram := _new_ram()
	empty_ram[0x0515] = 0x80
	var empty_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var empty_result: Dictionary = empty_consumer.call("consume", empty_ram, ppu_state, proof)
	_check(bool(empty_result.get("ok", false))
		and empty_result.get("ppu_writes", []).is_empty()
		and int(empty_result.get("updated_ram", PackedByteArray())[0x0515]) == 0,
		"a zero first length terminates after the ROM clears $0515")

	var boundary_ram := _new_ram()
	boundary_ram[0x04A5] = 109
	boundary_ram[0x04A6] = 0x08
	boundary_ram[0x04A7] = 0x20
	for index in range(109):
		boundary_ram[0x04A8 + index] = index & 0xFF
	boundary_ram[0x0515] = 0x80
	var boundary_consumer: RefCounted = CONSUMER_SCRIPT.new()
	var boundary_result: Dictionary = boundary_consumer.call("consume", boundary_ram, ppu_state, proof)
	_check(bool(boundary_result.get("ok", false))
		and boundary_result.get("packets", []).size() == 1,
		"the ready byte at $0515 is cleared before the next outer length read")
	if bool(boundary_result.get("ok", false)):
		var boundary_events: Array = boundary_result.get("bus_events", [])
		_check(boundary_events.size() == 112
			and _event_is(boundary_events, 111, "write", 0x2007, 108, 0xC978),
			"the 109-byte payload is fully emitted before the cleared $0515 terminator")

	if _failures == 0:
		print("PASS: source-byte primary/secondary NMI gates, ready handling, packet parsing, and ordered PPU bus events.")
		print("LIMIT: bank-switched primary pointers and PPU register side effects remain outside this consumer.")
	else:
		printerr("FAIL: %d normal-NMI PPU queue assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _event_is(events: Array, index: int, operation: String, register: int,
		value: int, source_pc: int) -> bool:
	if index < 0 or index >= events.size() or not events[index] is Dictionary:
		return false
	var event: Dictionary = events[index]
	return str(event.get("operation", "")) == operation \
		and int(event.get("ppu_register", -1)) == register \
		and int(event.get("value", -1)) == value \
		and int(event.get("source_pc", -1)) == source_pc


func _valid_proof() -> Dictionary:
	return {
		"schema": ENTRY_PROOF_SCHEMA,
		"rom_sha256": EXPECTED_ROM_SHA256,
		"nmi_kind": "normal",
		"call_site_pc": 0xC799,
		"entry_pc": 0xC8FB,
		"ram_001b_at_dispatch": 0x00,
		"source_dispatch_observed": true,
	}


func _new_ram() -> PackedByteArray:
	var ram := PackedByteArray()
	ram.resize(CPU_RAM_SIZE)
	return ram


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
	else:
		print("PASS: " + label)
