extends SceneTree

const SOURCE_RAM_IMAGE_SCRIPT := preload("res://scripts/gameplay/rom_source_ram_image.gd")
const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


func _initialize() -> void:
	var image: RomSourceRamImage = SOURCE_RAM_IMAGE_SCRIPT.new()
	var receipt := {
		"ok": true,
		"source_rom_sha256": SOURCE_ROM_SHA256,
		"ram_writes": [
			{"pc": 0xC4B9, "address": 0x0025, "value": 0x06},
			{"source_pc": 0xC4BF, "address": 0x0023, "value": 0x06},
			{"source_pc": 0xA14A, "address": 0x6000, "value": 0x42},
		],
		"emulator_data_used": false,
		"trace_state_used": false,
	}
	if not image.merge_executor_result("synthetic_contract_fixture", receipt):
		_fail("Valid source-write receipt was rejected: " + image.error_message)
		return
	var known_value := image.get_byte(0x0025)
	var unknown_value := image.get_byte(0x0024)
	var status := image.get_status()
	if not bool(known_value.get("known", false)) or int(known_value.get("value", -1)) != 0x06 \
			or bool(unknown_value.get("known", true)) \
			or int(status.get("known_byte_count", -1)) != 2 \
			or int(status.get("unknown_byte_count", -1)) != 0x7FE \
			or int(status.get("ignored_non_internal_ram_write_count", -1)) != 1:
		_fail("Sparse RAM knownness/value accounting is incorrect.")
		return
	var trace_receipt := receipt.duplicate(true)
	trace_receipt["trace_state_used"] = true
	if image.merge_executor_result("trace_fixture", trace_receipt):
		_fail("Trace-derived state was incorrectly accepted as a ROM executor receipt.")
		return
	print("PASS: source RAM image records explicit writes, keeps other bytes unknown, and rejects trace-derived state (contract fixture only).")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
