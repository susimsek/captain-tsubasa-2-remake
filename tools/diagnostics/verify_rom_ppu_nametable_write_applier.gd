extends SceneTree
## Focused verifier for applying the ROM normal-NMI consumer's bus events to
## renderer nametable memory. The packet fixture is the source-executed worker
## output recorded in fresh_worker_resume_and_second_wrapper_source_20261029.md.

const QUEUE_CONSUMER := preload("res://scripts/gameplay/rom_normal_nmi_ppu_queue_consumer.gd")
const WRITE_APPLIER := preload("res://scripts/gameplay/rom_ppu_nametable_write_applier.gd")
const CPU_RAM_SIZE := 0x0800
const ENTRY_PROOF_SCHEMA := "rom-normal-nmi-c8fb-entry-proof-v1"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ram := PackedByteArray()
	ram.resize(CPU_RAM_SIZE)
	ram.fill(0)
	var observed_packets := PackedByteArray([
		0x07, 0x21, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x07, 0x41, 0x22, 0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D,
	])
	for index in observed_packets.size():
		ram[0x04A5 + index] = observed_packets[index]
	ram[0x04A5 + observed_packets.size()] = 0
	ram[0x0515] = 0x80
	var source_ppu_state := {
		"ppu_ctrl": 0x88,
		"current_address": 0x0000,
		"temporary_address": 0x0000,
		"write_toggle": true,
	}
	var proof := _valid_proof()
	var consumer: RefCounted = QUEUE_CONSUMER.new()
	var consumed: Dictionary = consumer.call("consume", ram, {}, proof)
	_check(bool(consumed.get("ok", false)), "observed two-packet $04A5 fixture passes the ROM queue consumer")
	if not bool(consumed.get("ok", false)):
		_finish()
		return
	var events: Array = consumed.get("bus_events", [])
	_check(events.size() == 20, "two seven-byte packets emit 20 ordered bus events including $2002 reads")
	var applier: RefCounted = WRITE_APPLIER.new()
	var ppu_memory: Dictionary = {}
	var applied: Dictionary = applier.call("apply_bus_events", ppu_memory, source_ppu_state, events)
	_check(bool(applied.get("ok", false)), "queue-consumer events apply to supported renderer nametable state")
	if bool(applied.get("ok", false)):
		var updated: Dictionary = applied.get("ppu_memory", {})
		var final_state: Dictionary = applied.get("ppu_state", {})
		_check(int(applied.get("write_count", -1)) == 14, "14 payload bytes become nametable writes")
		_check(int(final_state.get("current_address", -1)) == 0x2248
			and int(final_state.get("temporary_address", -1)) == 0x2241
			and not bool(final_state.get("write_toggle", true)),
			"$2002 resets the latch and $2006/$2007 preserve final v/t state")
		var first_packet_ok := true
		for offset in 7:
			first_packet_ok = first_packet_ok and int(updated.get(0x2221 + offset, -1)) == 0
		_check(first_packet_ok, "first packet writes seven zero tiles to $2221-$2227")
		var expected_second := [0x9C, 0xA8, 0x20, 0x34, 0x2E, 0xA8, 0x9D]
		var second_packet_ok := true
		for offset in expected_second.size():
			second_packet_ok = second_packet_ok \
				and int(updated.get(0x2241 + offset, -1)) == int(expected_second[offset])
		_check(second_packet_ok, "second packet writes its seven observed bytes to $2241-$2247")
		_check(ppu_memory.is_empty() and source_ppu_state["current_address"] == 0
			and bool(source_ppu_state["write_toggle"]), "applier leaves caller-owned memory and PPU state unchanged")

	var stride_events: Array[Dictionary] = [
		{"sequence": 0, "operation": "read", "ppu_register": 0x2002, "source_pc": 0xC96A},
		{"sequence": 1, "operation": "write", "ppu_register": 0x2006, "value": 0x22, "source_pc": 0xC96D},
		{"sequence": 2, "operation": "write", "ppu_register": 0x2006, "value": 0x21, "source_pc": 0xC971},
		{"sequence": 3, "operation": "write", "ppu_register": 0x2007, "value": 0xEA, "source_pc": 0xC978},
	]
	var stride_state := source_ppu_state.duplicate(true)
	stride_state["ppu_ctrl"] = 0x8C
	var stride_applier: RefCounted = WRITE_APPLIER.new()
	var stride_result: Dictionary = stride_applier.call("apply_bus_events", {}, stride_state, stride_events)
	_check(bool(stride_result.get("ok", false))		and int(stride_result.get("ppu_memory", {}).get(0x2221, -1)) == 0xEA
		and int(stride_result.get("ppu_state", {}).get("current_address", -1)) == 0x2241,
		"PPUCTRL bit 2 advances $2007 by 32")

	var palette_events := stride_events.duplicate(true)
	palette_events[1]["value"] = 0x3F
	palette_events[2]["value"] = 0x00
	var rejected_applier: RefCounted = WRITE_APPLIER.new()
	var palette_result: Dictionary = rejected_applier.call("apply_bus_events", {}, source_ppu_state, palette_events)
	_check(not bool(palette_result.get("ok", true))
		and str(palette_result.get("status", "")) == "unsupported_ppu_address",
		"palette writes reject without guessing unsupported PPU behavior")

	_finish()


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


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("PASS: observed $04A5 packets become source-ordered renderer nametable writes.")
		print("LIMIT: this applier is not wired to the live route and does not model CHR, palette, or raster timing.")
	else:
		printerr("FAIL: %d PPU nametable write applier assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)
