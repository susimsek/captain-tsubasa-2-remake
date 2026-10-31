extends SceneTree
## Verifies the scheduler-owned normal-NMI PPU queue and ready-latch ordering.
## RAM packet fixtures exercise bounded branches; they are not route-state proof.

const SCHEDULER_SCRIPT := preload("res://scripts/gameplay/rom_gameplay_task_scheduler.gd")
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failures := 0


func _initialize() -> void:
	if not _run_verification():
		quit(1)
		return
	print("PASS: scheduler-owned NMI gate, primary/secondary queues, and $001B.7 writer order.")
	print("LIMIT: external NMI delivery remains caller-supplied; PPU register side effects and full-route RAM provenance remain outside this verifier.")	
	quit(0)


func _run_verification() -> bool:
	var transferred = _new_scheduler()
	if transferred == null:
		return false
	var transfer_ram := _ram_for(transferred)
	transfer_ram[0x04A5] = 2
	transfer_ram[0x04A6] = 0x34
	transfer_ram[0x04A7] = 0x21
	transfer_ram[0x04A8] = 0xAA
	transfer_ram[0x04A9] = 0xBB
	transfer_ram[0x04AA] = 0
	transfer_ram[0x0515] = 0x80
	_set_ram(transferred, transfer_ram)
	var transfer: Dictionary = transferred.call("service_external_nmi_delivery", 100, 0x88, true)
	_check(bool(transfer.get("ok", false)) and bool(transfer.get("serviced", false))
		and transfer.get("path", "") == "fixed_normal",
		"valid normal external NMI enters the source-owned queue service")
	_check(int(_ram_for(transferred)[0x0515]) == 0
		and int(_ram_for(transferred)[0x001B]) == 0x80,
		"NMI consumer clears $0515 before the scheduler-ready latch is set")
	_check(int(_ram_for(transferred)[0x0020]) == 0x88
		and int(_ram_for(transferred)[0x0019]) == 0x88,
		"normal NMI return restores the ROM PPUCTRL shadow and scheduler resume byte")
	_check(bool(transfer.get("secondary_queue", {}).get("transfer_performed", false))
		and transfer.get("secondary_queue", {}).get("branch", "") == "secondary_queue_consumed"
		and transfer.get("ppu_bus_events", []).size() == 5,
		"ready secondary packet returns PPU operations and applies the consumer RAM image")
	if not _verify_event_order(transfer, [
		"normal_nmi_dispatch", "normal_nmi_queue_call",
		"secondary_queue_consumed", "scheduler_ready_latch_set",
		"normal_nmi_return_shadow_restored",
	], [0xC76E, 0xC799, 0xC958, 0xC7F0, 0xC816]):
		return false

	var primary_selected = _new_scheduler()
	if primary_selected == null:
		return false
	var primary_ram := _ram_for(primary_selected)
	primary_ram[0x0498] = 2
	primary_ram[0x049C] = 0
	primary_ram[0x049D] = 0x6C
	primary_ram[0x049E] = 0x04
	primary_ram[0x046C] = 2
	primary_ram[0x046D] = 0x00
	primary_ram[0x046E] = 0x20
	primary_ram[0x046F] = 0xAA
	primary_ram[0x0470] = 0xBB
	primary_ram[0x0471] = 0
	primary_ram[0x0515] = 0x80
	_set_ram(primary_selected, primary_ram)
	var primary: Dictionary = primary_selected.call("service_external_nmi_delivery", 101, 0x88, true)
	_check(bool(primary.get("ok", false))
		and primary.get("secondary_queue", {}).get("branch", "") == "primary_queue_consumed"
		and bool(primary.get("secondary_queue", {}).get("primary_transfer_modeled", false))
		and bool(primary.get("secondary_queue", {}).get("transfer_performed", false))
		and primary.get("ppu_bus_events", []).size() == 5,
		"nonzero $0498 runs the source primary-queue transfer and returns ordered PPU bus events")
	_check(int(_ram_for(primary_selected)[0x0498]) == 1
		and int(_ram_for(primary_selected)[0x0515]) == 0x80
		and int(_ram_for(primary_selected)[0x001B]) == 0x80,
		"primary-queue branch decrements its count, preserves $0515, and sets scheduler-ready")
	if not _verify_event_order(primary, [
		"normal_nmi_dispatch", "normal_nmi_queue_call",
		"primary_queue_consumed", "scheduler_ready_latch_set",
		"normal_nmi_return_shadow_restored",
	], [0xC76E, 0xC799, 0xC900, 0xC7F0, 0xC816]):
		return false

	var no_packet = _new_scheduler()
	if no_packet == null:
		return false
	var no_packet_ram := _ram_for(no_packet)
	no_packet_ram[0x0515] = 0x01
	_set_ram(no_packet, no_packet_ram)
	var not_ready: Dictionary = no_packet.call("service_external_nmi_delivery", 102, 0x88, true)
	_check(bool(not_ready.get("ok", false))
		and not_ready.get("secondary_queue", {}).get("branch", "") == "secondary_queue_not_ready"
		and not bool(not_ready.get("secondary_queue", {}).get("transfer_performed", true))
		and not_ready.get("ppu_bus_events", []).is_empty(),
		"bit-7-clear $0515 reports the $C951 return branch without a transfer")
	_check(int(_ram_for(no_packet)[0x0515]) == 0x01
		and int(_ram_for(no_packet)[0x001B]) == 0x80,
		"not-ready branch preserves $0515 and continues to the scheduler-ready write")
	if not _verify_event_order(not_ready, [
		"normal_nmi_dispatch", "normal_nmi_queue_call",
		"secondary_queue_not_ready", "scheduler_ready_latch_set",
		"normal_nmi_return_shadow_restored",
	], [0xC76E, 0xC799, 0xC951, 0xC7F0, 0xC816]):
		return false

	var empty_packet = _new_scheduler()
	if empty_packet == null:
		return false
	var empty_packet_ram := _ram_for(empty_packet)
	empty_packet_ram[0x0515] = 0x80
	_set_ram(empty_packet, empty_packet_ram)
	var empty_result: Dictionary = empty_packet.call(
		"service_external_nmi_delivery", 102, 0x88, true)
	_check(bool(empty_result.get("ok", false))
		and empty_result.get("secondary_queue", {}).get("branch", "") == "secondary_queue_empty"
		and not bool(empty_result.get("secondary_queue", {}).get("transfer_performed", true))
		and empty_result.get("ppu_bus_events", []).is_empty(),
		"ready flag with an empty packet list clears the flag without claiming a PPU transfer")
	_check(int(_ram_for(empty_packet)[0x0515]) == 0
		and int(_ram_for(empty_packet)[0x001B]) == 0x80,
		"empty-list return applies the source flag clear before scheduler-ready")
	if not _verify_event_order(empty_result, [
		"normal_nmi_dispatch", "normal_nmi_queue_call",
		"secondary_queue_empty", "scheduler_ready_latch_set",
		"normal_nmi_return_shadow_restored",
	], [0xC76E, 0xC799, 0xC958, 0xC7F0, 0xC816]):
		return false

	var special = _new_scheduler()
	if special == null:
		return false
	var special_ram := _ram_for(special)
	special_ram[0x001B] = 0x40
	special_ram[0x0515] = 0x80
	_set_ram(special, special_ram)
	var special_result: Dictionary = special.call("service_external_nmi_delivery", 103, 0x88, true)
	_check(bool(special_result.get("ok", false))
		and special_result.get("path", "") == "bank02_mode6"
		and int(special_result.get("writer_pc", -1)) == 0xA135
		and special_result.get("secondary_queue", {}).get("branch", "") == "special_mode_bypass"
		and not bool(special_result.get("secondary_queue", {}).get("transfer_performed", true)),
		"special NMI mode bypasses $C799->$C8FB and uses the bank-$02 ready writer")
	_check(int(_ram_for(special)[0x0515]) == 0x80
		and int(_ram_for(special)[0x001B]) == 0xC0,
		"special mode preserves the secondary buffer flag and sets only the ready bit")
	if not _verify_event_order(special_result,
		["special_nmi_dispatch", "scheduler_ready_latch_set"], [0xC76E, 0xA135]):
		return false

	var no_edge = _new_scheduler()
	if no_edge == null:
		return false
	var no_edge_ram := _ram_for(no_edge)
	no_edge_ram[0x0515] = 0x80
	_set_ram(no_edge, no_edge_ram)
	var no_delivery: Dictionary = no_edge.call("service_external_nmi_delivery", 104, 0x88, false)
	_check(bool(no_delivery.get("ok", false)) and not bool(no_delivery.get("serviced", true))
		and int(_ram_for(no_edge)[0x0515]) == 0x80
		and int(_ram_for(no_edge)[0x001B]) == 0,
		"without an external NMI delivery the queue and ready latch remain untouched")

	var legacy_api = _new_scheduler()
	if legacy_api == null:
		return false
	var legacy: Dictionary = legacy_api.call("apply_external_nmi_delivery", 105, 0x88, true)
	_check(bool(legacy.get("ok", false)) and bool(legacy.get("serviced", false))
		and legacy.get("path", "") == "fixed_normal"
		and int(legacy.get("writer_pc", -1)) == 0xC7F0
		and int(legacy.get("latch_after", -1)) == 0x80,
		"existing apply_external_nmi_delivery API retains its normal-path result fields")

	if _failures > 0:
		return false
	return true


func _new_scheduler() -> Variant:
	var scheduler = SCHEDULER_SCRIPT.new()
	if not scheduler.configure_from_project_sources():
		_fail("Scheduler could not load verified project source spans: " + scheduler.error_message)
		return null
	var bootstrap: Dictionary = scheduler.initialize_fresh_game_bootstrap()
	if not bool(bootstrap.get("ok", false)):
		_fail("Scheduler bootstrap failed: " + scheduler.error_message)
		return null
	return scheduler


func _ram_for(scheduler: Variant) -> PackedByteArray:
	return scheduler.get("_ram")


func _set_ram(scheduler: Variant, ram: PackedByteArray) -> void:
	scheduler.set("_ram", ram)


func _verify_event_order(result: Dictionary, expected_events: Array[String],
		expected_pcs: Array[int]) -> bool:
	var events: Array = result.get("source_events", [])
	if events.size() != expected_events.size() or expected_pcs.size() != expected_events.size():
		return _fail("NMI source event count differs from the expected ROM branch sequence.")
	for index in expected_events.size():
		if not events[index] is Dictionary:
			return _fail("NMI source event %d is malformed." % index)
		var event: Dictionary = events[index]
		if int(event.get("sequence", -1)) != index \
				or String(event.get("event", "")) != expected_events[index] \
				or int(event.get("source_pc", -1)) != expected_pcs[index]:
			return _fail("NMI event %d differs from the expected source order/PC." % index)
	return true


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		_fail(label)


func _fail(message: String) -> bool:
	_failures += 1
	printerr("FAIL: " + message)
	return false
