extends SceneTree
## Verifies the source-byte holder-copy execution from a constructed live
## $E6EC call boundary; no emulator memory or display capture is loaded.

const EXECUTOR := preload("res://scripts/gameplay/rom_fresh_e6ec_holder_copy_executor.gd")
const POSITION_INITIALIZER := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")
const RAM_SIZE := 0x0800


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_context := {
		"kind": "caller_owned_decoded_game_logic",
		"label": "fresh-match-zero-holder-copy-source-verification",
	}
	var initializer = POSITION_INITIALIZER.new()
	if not initializer.configure():
		_fail("Position ROM sources failed: " + String(initializer.error_message))
		return
	var position_result: Dictionary = initializer.initialize_positions(0, 0, 0, 0, source_context)
	if not bool(position_result.get("ok", false)):
		_fail("Match-zero positions failed: " + String(position_result.get("error", "unknown")))
		return
	var ram := PackedByteArray()
	ram.resize(RAM_SIZE)
	ram.fill(0)
	for position_variant in position_result.get("positions", []):
		var position: Dictionary = position_variant
		var record := int(position["record_address"])
		ram[record + 0x06] = int(position["x"])
		ram[record + 0x08] = int(position["y"])
	ram[0x0441] = 8
	ram[0x05FC] = 5
	ram[0x014F] = 0x0D
	ram[0x0150] = 0xDB
	var stack := ram.slice(0x0100, 0x0200)
	var boundary := {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"active_task_slot": 0x05, "slot_base": 0x05,
		"pc": 0xE6EC, "sp": 0x4E,
		"bank_low": 0x1C, "bank_high": 0x1D,
		"a": 5, "x": 0, "y": 6, "p": 0x20, "p_known_mask": 0xFF,
		"ram_image": ram, "stack_page": stack,
	}
	var match_context := {
		"match_index": 0, "formation_002c": 0, "formation_002e": 0,
		"possession_side_05fb": 0, "source_context": source_context,
	}
	var executor = EXECUTOR.new()
	if not executor.configure():
		_fail("Holder-copy sources failed: " + String(executor.error_message))
		return
	var result: Dictionary = executor.execute_from_live_boundary(boundary, match_context)
	if not bool(result.get("ok", false)):
		_fail("$E6EC execution failed: " + String(result.get("error", executor.error_message)))
		return
	var result_ram: PackedByteArray = result.get("ram_image", PackedByteArray())
	var registers: Dictionary = result.get("registers", {})
	var holder: Dictionary = result.get("holder_copy", {})
	var calls: Array = result.get("calls", [])
	var writes: Array = result.get("memory_writes", [])
	var stack_writes: Array = result.get("stack_writes", [])
	if String(result.get("status", "")) != "returned_to_slot05_db0e_before_scenario36" \
			or int(registers.get("pc", -1)) != 0xDB0E or int(registers.get("sp", -1)) != 0x50:
		_fail("The holder-copy route must return to $DB0E / SP $50 before scenario $36.")
		return
	if int(holder.get("holder_slot_0441", -1)) != 8 \
			or int(holder.get("record_pointer", -1)) != 0x0360 \
			or int(holder.get("x_0635", -1)) != 0x7C \
			or int(holder.get("y_0637", -1)) != 0x7C \
			or int(holder.get("tile_index_05fe", -1)) != 0x71:
		_fail("Source-derived holder 8 should copy $7C/$7C and calculate tile index $71.")
		return
	if result_ram.size() != RAM_SIZE or result_ram[0x0034] != 0x60 \
			or result_ram[0x0035] != 0x03 or result_ram[0x0635] != 0x7C \
			or result_ram[0x0637] != 0x7C or result_ram[0x05FE] != 0x71:
		_fail("$CD7C/$E6EC/$CDE2 RAM writes do not match the live source result.")
		return
	if calls.size() != 2 or int(calls[0].get("callsite", -1)) != 0xE6EF \
			or int(calls[0].get("target", -1)) != 0xCD7C \
			or int(calls[1].get("callsite", -1)) != 0xE702 \
			or int(calls[1].get("target", -1)) != 0xCDE2 \
			or writes.size() != 5 or stack_writes.size() != 4:
		_fail("Holder-copy call, ordered RAM, or nested JSR stack effects differ from ROM instructions.")
		return
	if result_ram.slice(0x0100, 0x0200) != result.get("stack_page", PackedByteArray()) \
			or not (result.get("ppu_bus_events", []) as Array).is_empty() \
			or not (result.get("apu_register_writes", []) as Array).is_empty():
		_fail("The result must preserve the stack/RAM mirror and report no unrelated PPU/APU effects.")
		return
	print("PASS: hash-checked $E6EC/$CDE2 bytes and $CD89 pointers execute from live slot-$05 state to $DB0E; holder 8 writes record pointer $0360, coordinates $7C/$7C, and tile index $71.")
	print("LIMIT: route RNG still supplies $E2=$00 rather than the recorded ROM run's $BE; scenario-$36 enqueue and first command menu remain open.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
