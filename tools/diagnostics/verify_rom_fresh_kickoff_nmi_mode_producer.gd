extends SceneTree
## Verifies the hash-checked cold-start `$001B.6` source receipt.

const PRODUCER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_nmi_mode_producer.gd")
const RESET_BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const RAM_IMAGE_SCRIPT := preload("res://scripts/gameplay/rom_source_ram_image.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var reset_builder: Variant = RESET_BUILDER_SCRIPT.new()
	if not reset_builder.configure_from_project_sources():
		push_error("Reset source setup failed: " + String(reset_builder.error_message))
		quit(1)
		return
	var reset_addresses: Array[int] = [0x001B]
	var reset_receipt: Dictionary = reset_builder.build_reset_ram_zero_write_receipt(
		"verify_cold_start_001b", reset_addresses)
	_check(bool(reset_receipt.get("ok", false)), "ROM reset produces `$001B=$00`")
	var producer: Variant = PRODUCER_SCRIPT.new()
	if not producer.configure_from_project_sources():
		push_error("Cold-start mode source setup failed: " + String(producer.error_message))
		quit(1)
		return
	var mode_receipt: Dictionary = producer.build_cold_start_mode_receipt(reset_receipt)
	_check(bool(mode_receipt.get("ok", false)), "bounded ROM setup path produces the NMI mode write")
	_check(int(mode_receipt.get("known_bit_mask", 0)) == 0xFF
		and int(mode_receipt.get("known_bit_value", 0)) == 0x40
		and bool(mode_receipt.get("full_byte_known_at_setter", false)),
		"cold-start receipt proves `$001B.6=1` after the setter")
	var mode_writes: Array = mode_receipt.get("ram_writes", [])
	_check(not mode_writes.is_empty(), "mode receipt includes a source RAM write")
	if not mode_writes.is_empty():
		var mode_write: Dictionary = mode_writes[0]
		_check(int(mode_write.get("source_pc", -1)) == 0xA228
			and int(mode_write.get("post_instruction_pc", -1)) == 0xA22A,
			"receipt identifies the ROM store and observed post-instruction address")
	_check(not bool(mode_receipt.get("trace_state_used", true))
		and not bool(mode_receipt.get("emulator_data_used", true))
		and not bool(mode_receipt.get("full_byte_known_at_later_route_boundary", true)),
		"receipt is ROM-only and does not claim the later wait byte")
	var route_mode_receipt: Dictionary = producer.build_route_mode_bit_receipt(mode_receipt)
	_check(bool(route_mode_receipt.get("ok", false))
		and int(route_mode_receipt.get("known_bit_mask", 0)) == 0x7F
		and int(route_mode_receipt.get("known_bit_value", 0)) == 0x40
		and not bool(route_mode_receipt.get("full_byte_known_at_later_route_boundary", true)),
		"source writer invariants carry only `$001B.6` through the observed route")
	var ram_image: Variant = RAM_IMAGE_SCRIPT.new()
	_check(ram_image.merge_known_bits_receipt("verify_mode_bit", route_mode_receipt),
		"sparse RAM accepts the known-bit receipt")
	var full_byte: Dictionary = ram_image.get_byte(0x001B)
	var mode_bits: Dictionary = ram_image.get_byte_bits(0x001B)
	_check(not bool(full_byte.get("known", true))
		and int(mode_bits.get("known_mask", 0)) == 0x7F
		and int(mode_bits.get("known_value", 0)) == 0x40,
		"bit provenance does not fabricate the full `$001B` value")
	var missing_reset_byte := reset_receipt.duplicate(true)
	missing_reset_byte["ram_writes"] = []
	_check(not bool(producer.build_cold_start_mode_receipt(missing_reset_byte).get("ok", false)),
		"mode setter rejects a reset receipt without `$001B`")
	var trace_reset := reset_receipt.duplicate(true)
	trace_reset["trace_state_used"] = true
	_check(not bool(producer.build_cold_start_mode_receipt(trace_reset).get("ok", false)),
		"mode setter rejects trace-derived state")
	if _failures > 0:
		quit(1)
		return
	print("PASS: cold-start `$001B.6` producer is hash-checked and explicitly bounded.")
	quit(0)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("FAIL: " + label)
