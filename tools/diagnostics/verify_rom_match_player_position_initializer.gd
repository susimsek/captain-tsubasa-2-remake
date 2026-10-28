extends SceneTree
## Focused check for the ROM-byte-backed match-0 initial player positions.
## A local RAM capture, when present, is read only as an optional validation oracle.

const InitializerScript := preload("res://scripts/gameplay/rom_match_player_position_initializer.gd")
const OPTIONAL_RAM_ORACLE := "res://reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var initializer = InitializerScript.new()
	assert(initializer.configure(), "Preserved ROM position spans and manifest must pass hash checks.")
	var status: Dictionary = initializer.get_source_status()
	assert(bool(status.get("configured", false)), "Initializer status should report configured.")
	assert(int(status.get("formation_row_stride", -1)) == 11,
		"ROM code must derive an 11-entry formation stride.")

	# These values are explicit decoded-logic test inputs. The capture is not an input.
	var source_context := {
		"kind": "caller_owned_decoded_game_logic",
		"label": "match-0-initializer-verification-case",
	}
	var home_setup: Dictionary = initializer.initialize_positions(0, 0, 0, 0, source_context)
	assert(bool(home_setup.get("ok", false)), "Explicit match-0 home-side source inputs must resolve.")
	var home_positions: Array = home_setup.get("positions", [])
	assert(home_positions.size() == 22, "The initializer should produce 22 record positions.")
	assert(str(home_positions[6].get("table_id", "")) == "$DC87",
		"Home slot 6 with home possession should use the primary source table.")
	assert(int(home_positions[6].get("table_index", -1)) == 6,
		"Formation zero, local slot six should index the seventh table byte.")
	assert(int(home_positions[6].get("record_address", -1)) == 0x0348,
		"Slot six's record pointer should come from the preserved $CD89 table.")

	# Exercise all table rows and the side-dependent selection/mirroring branch.
	var away_setup: Dictionary = initializer.initialize_positions(0, 0, 0, 11, source_context)
	assert(bool(away_setup.get("ok", false)), "Explicit away-side source inputs must resolve.")
	var away_positions: Array = away_setup.get("positions", [])
	assert(str(away_positions[6].get("table_id", "")) == "$DCB3",
		"Home slot 6 with away possession should use the secondary source table.")
	assert(str(away_positions[17].get("table_id", "")) == "$DC87",
		"Away slot 17 with away possession should use the primary source table.")
	for formation_index in range(4):
		var formation_result: Dictionary = initializer.initialize_positions(
			0, formation_index, formation_index, 0, source_context)
		assert(bool(formation_result.get("ok", false)),
			"Formation row %d should be backed by preserved table bytes." % formation_index)
		var formation_positions: Array = formation_result.get("positions", [])
		assert(int(formation_positions[10].get("table_index", -1)) == formation_index * 11 + 10,
			"Home formation row %d should use the 11-slot stride." % formation_index)
		assert(int(formation_positions[21].get("table_index", -1)) == formation_index * 11 + 10,
			"Away formation row %d should use its local 0..10 slot." % formation_index)

	var invalid_match: Dictionary = initializer.initialize_positions(1, 0, 0, 0, source_context)
	assert(not bool(invalid_match.get("ok", true)), "Unmodeled match contexts must fail explicitly.")
	var invalid_formation: Dictionary = initializer.initialize_positions(0, 4, 0, 0, source_context)
	assert(not bool(invalid_formation.get("ok", true)), "Formation rows beyond the source table must fail.")
	var invalid_side: Dictionary = initializer.initialize_positions(0, 0, 0, 1, source_context)
	assert(not bool(invalid_side.get("ok", true)), "Unsupported possession-side values must fail.")
	var capture_context: Dictionary = initializer.initialize_positions(
		0, 0, 0, 0, {"kind": "emulator_capture", "label": "forbidden-input"})
	assert(not bool(capture_context.get("ok", true)),
		"An emulator capture cannot be passed as source-state authority.")

	var slot_six: Dictionary = home_positions[6]
	var slot_six_x := int(slot_six.get("x", -1))
	var slot_six_y := int(slot_six.get("y", -1))
	var capture_match := _compare_optional_ram_oracle(slot_six, slot_six_x, slot_six_y)
	if capture_match == "mismatch":
		push_error("Calculated slot 6 differs from the optional diagnostic RAM oracle.")
		quit(1)
		return
	print("ROM position initializer verified: 4 formation rows × 11 players; 22 ROM pointers; ",
		"slot 6 calculated from source byte = ($%02X,$%02X); optional diagnostic RAM comparison: %s." % [
			slot_six_x, slot_six_y, capture_match,
		])
	quit(0)


func _compare_optional_ram_oracle(slot_position: Dictionary, computed_x: int, computed_y: int) -> String:
	if not FileAccess.file_exists(OPTIONAL_RAM_ORACLE):
		return "not available"
	var ram := FileAccess.get_file_as_bytes(OPTIONAL_RAM_ORACLE)
	if ram.size() != 0x0800:
		return "skipped (unexpected capture size)"
	var record_address := int(slot_position.get("record_address", -1))
	var x_offset := int(slot_position.get("x_record_offset", -1))
	var y_offset := int(slot_position.get("y_record_offset", -1))
	if record_address < 0 or record_address + max(x_offset, y_offset) >= ram.size():
		return "skipped (record pointer outside capture)"
	if computed_x != int(ram[record_address + x_offset]) \
			or computed_y != int(ram[record_address + y_offset]):
		return "mismatch"
	return "matched (diagnostic-only)"
