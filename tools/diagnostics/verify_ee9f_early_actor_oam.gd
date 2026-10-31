extends SceneTree

const BUILDER_SCRIPT := preload("res://scripts/gameplay/gameplay_rom_actor_oam_builder.gd")
const CAPTURE_CSV_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/actor_draw_calls.csv"
const TARGET_FRAME := "8481"
const EXPECTED_RECORDS: Array[int] = [0x0547, 0x055C, 0x0571, 0x0586, 0x059B]
const EXPECTED_COUNTS: Array[int] = [25, 5, 0, 4, 0]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rows := _capture_rows()
	if rows.size() != EXPECTED_RECORDS.size():
		_fail("Frame-8481 validation trace does not contain exactly five actor draw calls.")
		return
	var actors: Array[Dictionary] = []
	var expected_oam_entries: Array[Dictionary] = []
	var expected_start_indices: Array[int] = []
	var expected_end_indices: Array[int] = []
	var expected_counts: Array[int] = []
	for actor_index in rows.size():
		var row: Dictionary = rows[actor_index]
		if _hex_value(str(row["actor_record"])) != EXPECTED_RECORDS[actor_index]:
			_fail("Frame-8481 actor order differs at record %d." % actor_index)
			return
		var record_bytes := _parse_hex_bytes(str(row["actor_record_21_bytes"]))
		if record_bytes.size() != 21:
			_fail("Frame-8481 actor record %d is malformed." % actor_index)
			return
		actors.append({"record_address": EXPECTED_RECORDS[actor_index], "record_bytes": record_bytes})
		expected_oam_entries.append(_parse_oam_entries(str(row["changed_oam_entries"])))
		expected_start_indices.append(int(row["oam_index_before"]))
		expected_end_indices.append(int(row["oam_index_after"]))
		expected_counts.append(EXPECTED_COUNTS[actor_index])
		if int(row["graphic_selector_0546"]) != 0:
			_fail("Frame-8481 did not use selector zero for the early actor streams.")
			return

	var initial_oam := PackedByteArray()
	initial_oam.resize(64 * 4)
	initial_oam.fill(0xF8)
	var builder = BUILDER_SCRIPT.new()
	var result: Dictionary = builder.build_oam(actors, 0, 0, 0, 0, 0xF0, initial_oam)
	if not bool(result.get("ok", false)):
		_fail("Early actor ROM OAM build failed: " + str(result.get("error", builder.last_error)))
		return
	if int(result.get("sprites_written", -1)) != 34 \
			or int(result.get("next_oam_byte_index", -1)) != 136:
		_fail("Early actor streams did not emit the captured 34 visible sprites / 136-byte cursor.")
		return
	var actor_results: Array = result.get("actors", [])
	if actor_results.size() != EXPECTED_RECORDS.size():
		_fail("The ROM OAM builder did not return five actor results.")
		return
	var output_oam: PackedByteArray = result["oam_bytes"]
	var matched_entries := 0
	for actor_index in actor_results.size():
		var actor_result: Dictionary = actor_results[actor_index]
		if int(actor_result.get("descriptor", -1)) != [0xB8, 0xBA, 0xBA, 0xB9, 0xB9][actor_index] \
				or int(actor_result.get("sprites_written", -1)) != expected_counts[actor_index] \
				or int(actor_result.get("start_oam_byte_index", -1)) != expected_start_indices[actor_index] \
				or int(actor_result.get("next_oam_byte_index", -1)) != expected_end_indices[actor_index]:
			_fail("Actor %d descriptor, visible sprite count, or OAM cursor differs from the FCEUX trace." % actor_index)
			return
		var captured_entries: Dictionary = expected_oam_entries[actor_index]
		for entry_index_variant in captured_entries:
			var entry_index := int(entry_index_variant)
			var expected_tuple: PackedInt32Array = captured_entries[entry_index]
			var base := entry_index * 4
			for byte_offset in 4:
				if output_oam[base + byte_offset] != expected_tuple[byte_offset]:
					_fail("Actor %d OAM entry $%02X byte %d differs from the FCEUX validation trace." % [actor_index, entry_index, byte_offset])
					return
			matched_entries += 1
	if matched_entries != 34:
		_fail("Expected 34 captured OAM tuples, found %d." % matched_entries)
		return
	print("PASS: ROM descriptors $B8/$BA/$B9 generated 34 visible sprites; 34/34 captured OAM tuples and all five per-actor cursor boundaries matched frame 8481.")
	print("LIMIT: FCEUX data is validation-only. This verifier establishes the early descriptor streams and hidden-X cursor rule for the captured selector-zero boundary, not route-time shared-state production or full-screen equivalence.")
	quit(0)


func _capture_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(CAPTURE_CSV_PATH, FileAccess.READ)
	if file == null:
		return rows
	var header := file.get_csv_line()
	var header_index: Dictionary = {}
	for column in header.size():
		header_index[str(header[column])] = column
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.size() != header.size() or str(values[0]) != TARGET_FRAME:
			continue
		var row: Dictionary = {}
		for key_variant in header_index:
			var key := str(key_variant)
			row[key] = values[int(header_index[key])]
		rows.append(row)
	return rows


func _parse_hex_bytes(text: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	for token in text.strip_edges().split(" ", false):
		bytes.append(_hex_value(token))
	return bytes


func _parse_oam_entries(text: String) -> Dictionary:
	var entries: Dictionary = {}
	for token in text.strip_edges().split("|", false):
		var parts := token.split(":", false)
		if parts.size() != 2:
			continue
		var tuple_tokens := parts[1].split("/", false)
		if tuple_tokens.size() != 4:
			continue
		var tuple := PackedInt32Array()
		for byte_text in tuple_tokens:
			tuple.append(_hex_value(byte_text))
		entries[_hex_value(parts[0])] = tuple
	return entries


func _hex_value(text: String) -> int:
	return text.trim_prefix("$").hex_to_int()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
