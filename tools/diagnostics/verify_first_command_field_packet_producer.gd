extends SceneTree
## Narrow validation of the ROM-derived $F015/$F114 packet decoder.
## The trace and endpoint PPU files below are validation oracles only; the
## runtime decoder reads preserved ROM bytes and accepts route inputs explicitly.

const PRODUCER_SCRIPT := preload("res://scripts/gameplay/first_command_field_packet_producer.gd")
const FIELD_CANDIDATE_SCRIPT := preload("res://scripts/gameplay/first_match_field_candidate_presenter.gd")
const VISUALS_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_visuals.gd")
const TRACE_DIR := "res://reference/diagnostics/first_command_field_producer_input_trace_20261028_053644_utc/"
const PPU_ORACLE_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin"
const TRACE_FRAME_FIRST := 8909
const TRACE_FRAME_LAST := 8914
const EXPECTED_TRACE_DESCRIPTOR := 0x02
const EXPECTED_TRACE_PLACEMENT := 0xA0
const EXPECTED_TRACE_HOLDER_X := 0x7C
const EXPECTED_TRACE_HOLDER_Y := 0xAC
const EXPECTED_HOLDER_PPU_ADDRESS := 0x2AE6


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(FIELD_CANDIDATE_SCRIPT != null and VISUALS_SCRIPT != null,
		"Field candidate and visuals integrations must parse with the new optional source context.")
	var trace_inputs := _verify_trace_inputs()
	if trace_inputs.is_empty():
		quit(1)
		return
	var producer: RefCounted = PRODUCER_SCRIPT.new()
	_check(_verify_placement_transitions(producer),
		"The ROM-byte $8327 placement transition must reproduce every traced $05CE/$05CD callback update.")
	var packet_result: Dictionary = producer.call("build_f015_packets",
		int(trace_inputs["descriptor_id"]), int(trace_inputs["placement_05ce"]))
	_check(bool(packet_result.get("ok", false)), "F015 ROM packet decode: " + str(producer.get("last_error")))
	if not bool(packet_result.get("ok", false)):
		quit(1)
		return
	_check(int(packet_result.get("tile_write_count", -1)) == 60,
		"F015 descriptor 2 must generate exactly 60 tile writes.")
	_check(int(packet_result.get("attribute_write_count", -1)) == 6,
		"F015 descriptor 2 must generate exactly six attribute writes.")
	_check(_compare_f015_trace_batches(packet_result),
		"F015 batches must match the six source-trace producer buffers byte-for-byte.")

	var generated_ppu: Dictionary = {}
	_check(bool(producer.call("apply_packets", generated_ppu, packet_result)),
		"Decoded F015 packets must apply to a PPU-address dictionary.")
	var ppu_oracle := FileAccess.get_file_as_bytes(PPU_ORACLE_PATH)
	_check(ppu_oracle.size() >= 0x4000, "Validation PPU memory capture is missing/truncated.")
	if ppu_oracle.size() >= 0x4000:
		var tile_matches := 0
		var tile_differences: Array[int] = []
		for row in range(2, 8):
			for column in range(2, 12):
				var address := 0x2A00 + row * 0x20 + column
				if int(generated_ppu.get(address, -1)) == int(ppu_oracle[address]):
					tile_matches += 1
				else:
					tile_differences.append(address)
		_check(tile_matches == 59 and tile_differences == [EXPECTED_HOLDER_PPU_ADDRESS],
			"F015 source packets must match 59/60 endpoint tiles; only the later F0B5 holder cell may differ.")

		var expected_attribute_addresses: Array[int] = [0x2BE0, 0x2BE1, 0x2BE2, 0x2BE8, 0x2BE9, 0x2BEA]
		var attribute_matches := 0
		for address in expected_attribute_addresses:
			if int(generated_ppu.get(address, -1)) == int(ppu_oracle[address]):
				attribute_matches += 1
		_check(attribute_matches == 6,
			"F015 source packets must match all six endpoint attribute bytes.")

	var holder_result: Dictionary = producer.call("build_f0b5_holder_packet",
		int(trace_inputs["descriptor_id"]),
		int(trace_inputs["placement_05ce"]),
		int(trace_inputs["holder_x"]),
		int(trace_inputs["holder_y"]))
	_check(bool(holder_result.get("ok", false)), "F0B5 ROM math decode: " + str(producer.get("last_error")))
	if bool(holder_result.get("ok", false)):
		var holder_packet: Dictionary = holder_result["packet"]
		_check(int(holder_packet.get("address", -1)) == EXPECTED_HOLDER_PPU_ADDRESS,
			"F0B5 ROM math with trace-only inputs must target $2AE6.")
		var holder_payload: Array = holder_packet.get("payload", [])
		_check(holder_payload == [0xA2], "F0B5 source code must emit tile $A2.")
		_check(int(ppu_oracle[EXPECTED_HOLDER_PPU_ADDRESS]) == 0xA2,
			"The later F0B5 tile must match the validation PPU endpoint.")

	if _failed:
		quit(1)
	else:
		print("First-command field packet producer verification passed: six F015 buffers byte-exact; eight $8327 placement transitions match both trace passes; 59/60 base tiles plus six attributes; separate F0B5 formula reaches the validated holder cell.")
		print("Muted ROM trace confirms live producer inputs and their writers; Godot's route still needs to derive those inputs from its own source-state model.")
		quit(0)


var _failed := false


func _compare_f015_trace_batches(packet_result: Dictionary) -> bool:
	var batches: Array = packet_result.get("serialized_batches", [])
	if batches.size() != 6:
		return false
	var path := TRACE_DIR + "ppu_packet_ready_events.csv"
	if not FileAccess.file_exists(path):
		push_error("Missing muted FCEUX packet-buffer trace: " + path)
		return false
	var lines := FileAccess.get_file_as_string(path).split("\n", false)
	var matched_frames: Dictionary = {}
	for line_index in range(1, lines.size()):
		var columns := lines[line_index].split(",", true)
		if columns.size() < 10 or columns[0] != "1" or columns[5] != "$F159":
			continue
		var frame := columns[1].to_int()
		if frame < TRACE_FRAME_FIRST or frame > TRACE_FRAME_LAST:
			continue
		var batch_index := frame - TRACE_FRAME_FIRST
		var captured_bytes := _parse_hex_bytes(columns[9])
		var expected_bytes: PackedByteArray = batches[batch_index]
		if captured_bytes.size() < expected_bytes.size():
			return false
		for byte_index in expected_bytes.size():
			if int(captured_bytes[byte_index]) != int(expected_bytes[byte_index]):
				return false
		matched_frames[frame] = true
	return matched_frames.size() == 6


func _verify_trace_inputs() -> Dictionary:
	var result := {"descriptor_id": -1, "placement_05ce": -1, "holder_x": -1, "holder_y": -1}
	var entry_files := ["field_producer_entries.csv", "field_producer_entries_repeat.csv"]
	for file_index in entry_files.size():
		var rows := _read_csv_dicts(TRACE_DIR + entry_files[file_index])
		if rows.is_empty():
			_check(false, "Missing producer-entry trace: " + entry_files[file_index])
			return {}
		var f015: Array[Dictionary] = []
		var f0b5: Array[Dictionary] = []
		for row in rows:
			if row.get("entry_pc", "") == "$F015":
				f015.append(row)
			elif row.get("entry_pc", "") == "$F0B5":
				f0b5.append(row)
		if f015.size() != 6 or f0b5.size() != 1:
			_check(false, "Each source-trace pass must contain six F015 and one F0B5 entry.")
			return {}
		for index in f015.size():
			var row := f015[index]
			var expected_frame := 8908 + index
			if row.get("source_frame", "").to_int() != expected_frame \
					or row.get("cpu_a", "") != "$%02X" % index \
					or row.get("entry_prg_bank", "") != "$1F" \
					or row.get("ram_05CD", "") != "$80" \
					or row.get("ram_05CE", "") != "$A0" \
					or row.get("ram_063D", "") != "$02":
				_check(false, "F015 producer-entry source state differs from the byte-verified route trace.")
				return {}
		var holder_row := f0b5[0]
		if holder_row.get("source_frame", "").to_int() != 8915 \
				or holder_row.get("entry_prg_bank", "") != "$1F" \
				or holder_row.get("ram_05CD", "") != "$80" \
				or holder_row.get("ram_05CE", "") != "$A0" \
				or holder_row.get("ram_063D", "") != "$02" \
				or holder_row.get("ram_0635", "") != "$7C" \
				or holder_row.get("ram_0637", "") != "$AC":
			_check(false, "F0B5 producer-entry source state differs from the byte-verified route trace.")
			return {}
		if file_index == 0:
			result["descriptor_id"] = _trace_hex_to_int(f015[0]["ram_063D"])
			result["placement_05ce"] = _trace_hex_to_int(f015[0]["ram_05CE"])
			result["holder_x"] = _trace_hex_to_int(holder_row["ram_0635"])
			result["holder_y"] = _trace_hex_to_int(holder_row["ram_0637"])
		if result["descriptor_id"] != EXPECTED_TRACE_DESCRIPTOR \
				or result["placement_05ce"] != EXPECTED_TRACE_PLACEMENT \
				or result["holder_x"] != EXPECTED_TRACE_HOLDER_X \
				or result["holder_y"] != EXPECTED_TRACE_HOLDER_Y:
			_check(false, "Trace-derived fixture bytes differ from the expected source audit.")
			return {}
	if not _verify_last_source_writers():
		_check(false, "The final source writers for the packet inputs do not match the verified ROM trace.")
		return {}
	return result


func _verify_last_source_writers() -> bool:
	for file_name in ["field_producer_input_writes.csv", "field_producer_input_writes_repeat.csv"]:
		var rows := _read_csv_dicts(TRACE_DIR + file_name)
		if rows.is_empty():
			return false
		for expected in [
			{"address": "$05CE", "frame": 8905, "pc_after": "$8345", "value": "$A0", "bank": "11"},
			{"address": "$05CD", "frame": 8905, "pc_after": "$834C", "value": "$80", "bank": "11"},
			{"address": "$063D", "frame": 8908, "pc_after": "$F00C", "value": "$02", "bank": "31"},
		]:
			var last_write: Dictionary = {}
			for row in rows:
				if row.get("cpu_address", "") == expected["address"]:
					last_write = row
			if last_write.is_empty() \
					or last_write.get("source_frame", "").to_int() != expected["frame"] \
					or last_write.get("cpu_pc_after_write", "") != expected["pc_after"] \
					or last_write.get("new_value", "") != expected["value"] \
					or last_write.get("pc_prg_bank", "") != expected["bank"]:
				return false
	return true


func _verify_placement_transitions(producer: RefCounted) -> bool:
	for file_name in ["field_producer_input_writes.csv", "field_producer_input_writes_repeat.csv"]:
		var rows := _read_csv_dicts(TRACE_DIR + file_name)
		if rows.is_empty():
			return false
		var placement_writes: Array[Dictionary] = []
		for row in rows:
			if row.get("cpu_address", "") == "$05CE" \
					and row.get("pc_prg_bank", "") == "11" \
				and row.get("cpu_pc_after_write", "") == "$8345":
				placement_writes.append(row)
		if placement_writes.size() != 8:
			return false
		for placement_write in placement_writes:
			var paired_05cd: Dictionary = {}
			for row in rows:
				if row.get("source_frame", "") == placement_write["source_frame"] \
						and row.get("cpu_address", "") == "$05CD" \
						and row.get("pc_prg_bank", "") == "11" \
						and row.get("cpu_pc_after_write", "") == "$834C":
					paired_05cd = row
					break
			if paired_05cd.is_empty():
				return false
			var source_transition: Dictionary = producer.call("advance_map_placement_state",
				_trace_hex_to_int(paired_05cd["old_value"]))
			if not bool(source_transition.get("ok", false)) \
					or int(source_transition.get("written_05ce", -1)) != _trace_hex_to_int(placement_write["new_value"]) \
					or int(source_transition.get("next_05cd", -1)) != _trace_hex_to_int(paired_05cd["new_value"]):
				return false
	return true


func _read_csv_dicts(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return result
	var lines := FileAccess.get_file_as_string(path).split("\n", false)
	if lines.is_empty():
		return result
	var header := lines[0].split(",", true)
	for line_index in range(1, lines.size()):
		var values := lines[line_index].split(",", true)
		if values.size() != header.size():
			continue
		var row: Dictionary = {}
		for column in header.size():
			row[header[column]] = values[column]
		result.append(row)
	return result


func _trace_hex_to_int(value: String) -> int:
	return value.trim_prefix("$").hex_to_int()


func _parse_hex_bytes(value: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in value.strip_edges().split(" ", false):
		if not token.is_valid_hex_number(false):
			return PackedByteArray()
		result.append(token.hex_to_int())
	return result


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
