extends RefCounted
class_name RomFieldEntryWindow01PacketSource
## Builds only the ROM descriptor-$01 field-entry window packets.
## ED/EE rows are complete solely for the source-derived fresh-match inputs.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/field_entry_window_01/"
const MANIFEST_PATH := ROOT + "manifest.json"
const MANIFEST_SHA256 := "9e675240b8994f5956ca0939202b7841e2b833568103dbfc6567d5a21980beb1"
const FRESH_SETUP_ROOT := "res://reference/rom_extract/gameplay/fresh_match_handoff/"
const FRESH_SETUP_MANIFEST := FRESH_SETUP_ROOT + "manifest.json"
const FRESH_SETUP_SHA256 := "cf3001b1d6b6413c2b69aa9c00b8383ccaa8a034cfd61ca1e6ebbfd97da03f45"
const ZERO_FILL_SHA256 := "b4087f492a7a3ffb3737c7a42fd1b7fe5cf82147eab7c80eddc331740b6c38fd"
const SELECTOR_CODE_SHA256 := "f9b27195e6d6c9163d55ee6161fbf8d4d795537df2f2347d3e4c406765033123"
const HOME_TEAM_TABLE_SHA256 := "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"
const PERIOD_CODE_SHA256 := "28895a5c3512a45e1b1a59c4324654ec03bb5f2ea413445e32333aa3bd6b87cc"
const PERIOD_TABLE_SHA256 := "0e1862b77227e30a4b6f6d40295f173db76d2473f8b9e31b241239c07a5837fa"
const LAYOUT_BUILDER := preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const DESCRIPTOR_CPU := 0xB464
const POINTER_CPU := 0xB3D1
const SELECTOR_RAM_KEYS := [0x002A, 0x002B]
const SUPPORTED_TEAM_IDS := [0, 3]
const ZERO_FILL_CALLER: Array[int] = [
	0xA9, 0x98, 0xA2, 0x02, 0xA0, 0x68, 0x84, 0xEC,
	0xA0, 0x04, 0x20, 0x06, 0xAA,
]
const ZERO_FILL_HELPER: Array[int] = [
	0x84, 0xED, 0xE8, 0xA0, 0x00, 0x48, 0xA9, 0x00, 0x91,
	0xEC, 0xE6, 0xEC, 0xD0, 0x02, 0xE6, 0xED, 0x68, 0x38,
	0xE9, 0x01, 0xD0, 0xEF, 0xCA, 0xD0, 0xEC,
]

var last_error := ""
var status: Dictionary = {}
var packet_records: Array[Dictionary] = []


## Selector and period results must be the direct outputs of the existing
## hash-checked source executors. The setup zero-fill is re-derived from the
## preserved $A2AF/$AA06 bytes, never from capture state.
func build_descriptor_01(selector_result: Dictionary = {},
		fresh_period_result: Dictionary = {}) -> Dictionary:
	last_error = ""
	status.clear()
	packet_records.clear()
	var manifest := _load_manifest()
	if manifest.is_empty():
		return _fail_result(last_error)
	var resources := _resources_by_path(manifest)
	var pointer := _load_resource(resources, "descriptor_01_pointer.bin", 2)
	var descriptor := _load_resource(resources, "descriptor_01.bin", 25)
	if pointer.size() != 2 or descriptor.size() != 25:
		return _fail_result(last_error)
	if (int(pointer[0]) | (int(pointer[1]) << 8)) != DESCRIPTOR_CPU:
		return _fail_result("Descriptor-table entry no longer selects descriptor $01 at $B464.")
	if descriptor.slice(0, 9) != PackedByteArray([0xC1, 0x22, 0x07, 0x07, 0x00, 0x00, 0x07, 0x04, 0x04]):
		return _fail_result("Descriptor-$01 header no longer matches the checked ROM contract.")
	var row_names := ["descriptor_01_row_00.bin", "descriptor_01_row_01.bin",
		"descriptor_01_row_02.bin", "descriptor_01_row_03.bin"]
	var rows: Array[PackedByteArray] = []
	for name: String in row_names:
		var row := _load_resource(resources, name, 3)
		if row.size() != 3:
			return _fail_result(last_error)
		rows.append(row)
	if rows[0] != PackedByteArray([0xED, 0x00, 0xFC]) \
			or rows[1] != PackedByteArray([0xEE, 0x00, 0xFC]) \
			or rows[2] != PackedByteArray([0xED, 0x01, 0xFC]) \
			or rows[3] != PackedByteArray([0xEE, 0x01, 0xFC]):
		return _fail_result("Descriptor-$01 row tokens or one-byte operands changed.")
	if not _verify_descriptor_rows(descriptor):
		return _fail_result(last_error)
	var family := _load_resource(resources, "descriptor_frame_family_selector_B3BD.bin", 1)
	if family.size() != 1 or ((int(family[0]) >> 2) & 0x03) != 0:
		return _fail_result("Descriptor-$01 no longer selects the checked window-frame family zero.")
	var frame_spec: Dictionary = manifest.get("shared_frame_family", {})
	var frame_path := "res://" + str(frame_spec.get("path_from_project_root", ""))
	var frame := FileAccess.get_file_as_bytes(frame_path) if FileAccess.file_exists(frame_path) else PackedByteArray()
	if frame.size() != 9 or FileAccess.get_sha256(frame_path) != str(frame_spec.get("sha256", "")):
		return _fail_result("Shared ROM window-frame resource failed its size/hash check.")
	if not _verify_token_sources(resources):
		return _fail_result(last_error)

	var selector_inputs := _read_selector_inputs(selector_result)
	var period_inputs := _read_fresh_period_inputs(fresh_period_result)
	var setup_inputs := _derive_setup_zero_fill()
	var blank_rows: Array[PackedByteArray] = []
	for _row in 4:
		blank_rows.append(PackedByteArray([0xFC]))
	packet_records = LAYOUT_BUILDER.build_packets(descriptor, frame, blank_rows)
	if packet_records.size() != 8:
		return _fail_result("ROM layout builder did not emit all eight descriptor-$01 progress packets.")

	var known_source_inputs_ready := bool(selector_inputs.get("ok", false)) \
		and bool(period_inputs.get("ok", false)) and bool(setup_inputs.get("ok", false))
	var unresolved: Array[Dictionary] = []
	var row_outputs: Array[Dictionary] = []
	for row_index in 4:
		var row := rows[row_index]
		var token := int(row[0])
		var operand := int(row[1])
		var progress := int(descriptor[9 + row_index * 4])
		var packet_index := progress
		var output: Dictionary = {}
		var missing := ""
		if token == 0xED:
			if not bool(selector_inputs.get("ok", false)):
				missing = String(selector_inputs.get("missing", "hash-checked selector result"))
			else:
				var team_id := int(selector_inputs["team_ids"][operand])
				output = _resolve_team_name(team_id, resources)
				if not bool(output.get("ok", false)):
					missing = String(output.get("error", "supported ROM team-name stream"))
				else:
					var start_column := int(descriptor[4]) + int(descriptor[10 + row_index * 4])
					if not _write_forward_tiles(packet_records[packet_index], start_column,
							output.get("emitted_tiles", PackedByteArray())):
						missing = "ROM-emitted team-name tiles fit within descriptor-$01 row width"
		elif token == 0xEE:
			if not bool(setup_inputs.get("ok", false)) or not bool(period_inputs.get("ok", false)):
				missing = "source-owned fresh setup and period results for $0628/$0629"
			else:
				var value := int(setup_inputs["ram_values"][0x0628]) if operand == 0 \
					else int(period_inputs["ram_values"][0x0629])
				output = _resolve_ee_value(value)
				if not bool(output.get("ok", false)):
					missing = String(output.get("error", "supported zero-valued $EE input"))
		else:
			return _fail_result("Descriptor-$01 contains unsupported token $%02X." % token)

		var record: Dictionary = packet_records[packet_index]
		if not missing.is_empty():
			record["complete"] = false
			var missing_record := {"row": row_index, "progress": progress,
				"token": "$%02X" % token, "operand": operand, "needs": missing}
			record["missing_dynamic"] = [missing_record]
			unresolved.append(missing_record)
		else:
			output["token"] = token
			output["operand"] = operand
			output["progress"] = progress
			output["handler_cpu"] = "$8AE7" if token == 0xED else "$8B2F"
			output["writes"] = output.get("emitted_tiles", PackedByteArray())
			row_outputs.append(output)
			if record.has("source_token_outputs"):
				record["source_token_outputs"].append(output)
			else:
				record["source_token_outputs"] = [output]
			if not record.has("missing_dynamic") or record["missing_dynamic"].is_empty():
				record["complete"] = true
				record["missing_dynamic"] = []

	var all_complete := unresolved.is_empty()
	var source_inputs_ready := known_source_inputs_ready and all_complete
	var resolved_team_ids: Array = selector_inputs.get("team_ids", [])
	var home_team_id := int(resolved_team_ids[0]) if resolved_team_ids.size() > 0 else -1
	var away_team_id := int(resolved_team_ids[1]) if resolved_team_ids.size() > 1 else -1
	status = {
		"ok": true,
		"descriptor_id": 0x01,
		"descriptor_cpu_address": DESCRIPTOR_CPU,
		"packet_record_format": "payload length, PPU address low, PPU address high, tile payload",
		"progress_packet_count": packet_records.size(),
		"packet_data_complete": all_complete,
		"queue_submission_ready": all_complete,
		"ready_flag_0515": "caller-owned; this source does not write it",
		"source_inputs_ready": source_inputs_ready,
		"known_dynamic_inputs_ready": known_source_inputs_ready,
		"source_inputs": {
			"$002A": home_team_id,
			"$002B": away_team_id,
			"$0628": setup_inputs.get("ram_values", {}).get(0x0628, -1),
			"$0629": period_inputs.get("ram_values", {}).get(0x0629, -1),
			"$003C": -1,
		},
		"source_input_missing": {
			"selector": selector_inputs.get("missing", ""),
			"fresh_period": period_inputs.get("missing", ""),
			"fresh_setup_zero_fill": setup_inputs.get("missing", ""),
			"$003C": "ROM $8C55 formatter caller state is not produced by these source results",
		},
		"source_input_provenance": {
			"selector": selector_inputs.get("provenance", {}),
			"fresh_period": period_inputs.get("provenance", {}),
			"fresh_setup_zero_fill": setup_inputs.get("provenance", {}),
		},
		"source_token_outputs": row_outputs,
		"packet_records": packet_records.duplicate(true),
		"complete_packet_records": _complete_records(),
		"unresolved_source_tokens": unresolved,
		"stop_boundary": "descriptor-$01 ED/EE row substitutions only; no field map, palette, OAM, scroll, or raster output",
		"runtime_rom_dependency": false,
	}
	return status


func _resolve_team_name(team_id: int, resources: Dictionary) -> Dictionary:
	if not SUPPORTED_TEAM_IDS.has(team_id):
		return {"ok": false, "error": "ROM team-name lookup is verified only for fresh-match team IDs 0 and 3"}
	var lengths := _load_resource(resources, "ed_team_name_lengths_8B0A_8B0E.bin", 4)
	var pointers := _load_resource(resources, "fixed_team_name_pointer_entries_76_79_F415_F41D.bin", 8)
	var name_file := "team_00_name_stream.bin" if team_id == 0 else "team_03_name_stream.bin"
	var name_bytes := _load_resource(resources, name_file, -1)
	if lengths.size() != 4 or pointers.size() != 8 or name_bytes.is_empty():
		return {"ok": false, "error": last_error if not last_error.is_empty() else "complete ROM team-name source bytes"}
	var encoded_selector := 0x76 + team_id
	var pointer_offset := (encoded_selector - 0x76) * 2
	var string_pointer := int(pointers[pointer_offset]) | (int(pointers[pointer_offset + 1]) << 8)
	var expected_pointer := 0xF776 if team_id == 0 else 0xF785
	var count := int(lengths[team_id])
	if string_pointer != expected_pointer or count != 3 or name_bytes.size() <= count \
			or int(name_bytes[name_bytes.size() - 1]) != 0xFC:
		return {"ok": false, "error": "ROM team selector, length, or name terminator differs from the supported source contract"}
	var helper_vector := _load_resource(resources, "fixed_text_helper_vector_C524_C527.bin", 3)
	var converter := _load_resource(resources, "fixed_text_converter_CBC2_CBF1.bin", 47)
	if helper_vector != PackedByteArray([0x4C, 0xC2, 0xCB]) \
			or converter.slice(0, 6) != PackedByteArray([0xA0, 0x00, 0xC9, 0xA0, 0x90, 0x28]) \
			or converter.slice(14, 24) != PackedByteArray([0xE9, 0xAE, 0xC9, 0x1F, 0x90, 0x1A, 0xE9, 0x05, 0xB0, 0x13]) \
			or converter.slice(43, 47) != PackedByteArray([0x18, 0x69, 0x40, 0x60]):
		return {"ok": false, "error": "ROM character converter does not prove the supported ASCII tile path"}
	var emitted := PackedByteArray()
	for index in count:
		var source_byte := int(name_bytes[index])
		var converted := _convert_uppercase_ascii_tile(source_byte)
		if converted < 0:
			return {"ok": false, "error": "The ROM character converter output is not established for this name byte"}
		emitted.append(converted)
	return {
		"ok": true, "team_id": team_id, "encoded_selector": encoded_selector,
		"name_pointer": string_pointer, "length": count,
		"source_name_bytes": name_bytes.duplicate(), "emitted_tiles": emitted,
		"text_loop_cpu": "$8A6F", "text_converter_cpu": "$CBC2",
		"output_order": "ROM string order; $8A6F increments the character index after each emit",
		"converter_rule": "For these A-Z source bytes, $CBC2 follows SBC #$AE, SBC #$05, CLC/ADC #$40; output is source byte + $8C.",
	}


func _convert_uppercase_ascii_tile(source_byte: int) -> int:
	if source_byte < 0x41 or source_byte > 0x5A or source_byte >= 0xA0:
		return -1
	# The verified $CBC2 branches for A-Z clear carry at CMP #$A0, then
	# subtract $AE with borrow, subtract $05, and add $40 after CLC.
	var accumulator := (source_byte - 0xAE - 1) & 0xFF
	if accumulator < 0x1F:
		return -1
	accumulator = (accumulator - 0x05) & 0xFF
	if accumulator < 0x05:
		return -1
	accumulator = (accumulator + 0x40) & 0xFF
	return accumulator


func _resolve_ee_value(value: int) -> Dictionary:
	if value != 0:
		return {"ok": false, "error": "The $EE formatter is implemented only for source value zero in descriptor $01"}
	var current_manifest := _load_manifest()
	var current_resources := _resources_by_path(current_manifest)
	var formatter := _load_resource(current_resources, "decimal_formatter_8C55_8C85.bin", 48)
	if formatter.size() != 48 or formatter.slice(0, 5) != PackedByteArray([0xA4, 0x3C, 0x88, 0xF0, 0x2A]) \
			or formatter.slice(29, 33) != PackedByteArray([0xA5, 0x6F, 0xF0, 0x0E]):
		return {"ok": false, "error": "ROM decimal formatter does not establish the value-zero no-digit path"}
	return {"ok": false, "error": "ROM $8C55 also reads caller-owned $003C: value 1 returns before formatting; other values may emit the zero tile $33"}


func _read_selector_inputs(result: Dictionary) -> Dictionary:
	if result.is_empty() or not bool(result.get("ok", false)):
		return {"ok": false, "missing": "direct hash-checked RomFreshMatchSelectorExecutor result"}
	if str(result.get("source_rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "missing": "selector result for the checked target ROM"}
	var receipt: Dictionary = result.get("source_return_receipt", {})
	var hashes: Dictionary = result.get("source_span_hashes", {})
	var ram: Dictionary = result.get("ram_after", {})
	var path: Array = result.get("source_path", [])
	if int(receipt.get("target_pc", -1)) != 0xA20F or int(receipt.get("return_pc", -1)) != 0x80FD \
			or str(receipt.get("source_execution", "")) != "hash_checked_6502_subset_through_real_rts" \
			or str(receipt.get("status", "")) != "returned":
		return {"ok": false, "missing": "source selector return $A20F->$A8B6->$80FD"}
	if str(hashes.get("selector_code", "")) != SELECTOR_CODE_SHA256 \
			or str(hashes.get("home_team_match_table", "")) != HOME_TEAM_TABLE_SHA256:
		return {"ok": false, "missing": "hash-checked ROM selector code and team table"}
	if not path.has(0xA8AD) or not path.has(0xA8B4) or not path.has(0xA8B6):
		return {"ok": false, "missing": "ROM stores to $002A/$002B and selector RTS"}
	for address in SELECTOR_RAM_KEYS:
		if not ram.has(address):
			return {"ok": false, "missing": "selector-produced RAM $%04X" % address}
	var home := int(ram[0x002A])
	var away := int(ram[0x002B])
	if int(ram.get(0x0026, -1)) != 0 or home != 0 or away != 3:
		return {"ok": false, "missing": "supported fresh match-zero team IDs $002A=0 and $002B=3"}
	return {"ok": true, "team_ids": [home, away], "provenance": {
		"source_rom_sha256": ROM_SHA256, "selector_code_sha256": SELECTOR_CODE_SHA256,
		"home_team_table_sha256": HOME_TEAM_TABLE_SHA256, "match_index": 0,
		"source_rts": "$A8B6->$80FD"}}


func _read_fresh_period_inputs(result: Dictionary) -> Dictionary:
	if result.is_empty() or not bool(result.get("ok", false)) \
			or str(result.get("rom_sha256", "")) != ROM_SHA256 \
			or str(result.get("source_code_sha256", "")) != PERIOD_CODE_SHA256 \
			or str(result.get("camera_table_sha256", "")) != PERIOD_TABLE_SHA256 \
			or int(result.get("exit_pc", -1)) != 0xDAAA:
		return {"ok": false, "missing": "hash-checked fresh-period execution through $DAAA"}
	var entry: Dictionary = result.get("entry", {})
	var context: Dictionary = result.get("source_context", {})
	var ram: Dictionary = result.get("ram", {})
	if int(entry.get("pc", -1)) != 0xD11E or int(entry.get("slot_base", -1)) != 5 \
			or str(context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(context.get("rom_sha256", "")) != ROM_SHA256 \
			or str(context.get("source_event", "")).is_empty():
		return {"ok": false, "missing": "source-owned slot-$05 $D11E caller context"}
	if int(ram.get("$0027", -1)) != 0 or int(ram.get("$0629", -1)) != 0:
		return {"ok": false, "missing": "fresh-period source writes $0027=$00 and $0629=$00"}
	return {"ok": true, "ram_values": {0x0629: int(ram["$0629"])}, "provenance": {
		"rom_sha256": ROM_SHA256, "entry_pc": 0xD11E, "exit_pc": 0xDAAA,
		"source_code_sha256": PERIOD_CODE_SHA256, "camera_table_sha256": PERIOD_TABLE_SHA256,
		"source_event": str(context["source_event"])}}


func _derive_setup_zero_fill() -> Dictionary:
	var setup_manifest := _read_json(FRESH_SETUP_MANIFEST)
	if setup_manifest.is_empty() or str(setup_manifest.get("rom_sha256", "")) != ROM_SHA256:
		return {"ok": false, "missing": "hash-checked fresh setup $A2AF/$AA06 sources"}
	var setup := FileAccess.get_file_as_bytes(FRESH_SETUP_ROOT + "bank82_fresh_match_setup_A2AF_A2E7.bin")
	var helper := FileAccess.get_file_as_bytes(FRESH_SETUP_ROOT + "bank82_zero_fill_AA06_AA1E.bin")
	if setup.size() != 57:
		return {"ok": false, "missing": "verified $A2AF caller size"}
	if FileAccess.get_sha256(FRESH_SETUP_ROOT + "bank82_fresh_match_setup_A2AF_A2E7.bin") != FRESH_SETUP_SHA256:
		return {"ok": false, "missing": "verified $A2AF caller hash"}
	if not _bytes_equal(helper, ZERO_FILL_HELPER):
		return {"ok": false, "missing": "verified $AA06 zero-fill byte sequence"}
	if FileAccess.get_sha256(FRESH_SETUP_ROOT + "bank82_zero_fill_AA06_AA1E.bin") != ZERO_FILL_SHA256:
		return {"ok": false, "missing": "verified $AA06 zero-fill hash"}
	if not _bytes_equal(setup.slice(0x29, 0x36), ZERO_FILL_CALLER):
		return {"ok": false, "missing": "ROM $A2AF caller registers and JSR $AA06"}
	var stores := 0x98 + 0x100 + 0x100
	var start := 0x0468
	var end_exclusive := start + stores
	if stores != 664 or end_exclusive != 0x0700 or not (0x0628 >= start and 0x0628 < end_exclusive):
		return {"ok": false, "missing": "source-derived zero-fill range includes $0628"}
	return {"ok": true, "ram_values": {0x0628: 0}, "provenance": {
		"rom_sha256": ROM_SHA256, "caller_cpu": "$A2AF", "helper_cpu": "$AA06",
		"caller_sha256": FRESH_SETUP_SHA256, "helper_sha256": ZERO_FILL_SHA256,
		"stores": stores, "range": "$0468..$06FF", "store_value": "ROM LDA #$00 before each STA ($EC),Y"}}


func _verify_descriptor_rows(descriptor: PackedByteArray) -> bool:
	var expected := [
		[1, 1, 0xBBE0], [1, 5, 0xBD9C], [3, 1, 0xBBE3], [3, 5, 0xBD9F],
	]
	for index in expected.size():
		var offset := 9 + index * 4
		var entry: Array = expected[index]
		var pointer := int(descriptor[offset + 2]) | (int(descriptor[offset + 3]) << 8)
		if int(descriptor[offset]) != int(entry[0]) or int(descriptor[offset + 1]) != int(entry[1]) \
				or pointer != int(entry[2]):
			last_error = "Descriptor-$01 row %d does not match its source progress/column/stream." % index
			return false
	return true


func _verify_token_sources(resources: Dictionary) -> bool:
	var vectors := _load_resource(resources, "token_dispatch_vectors_E0_F0_89BA_89DC.bin", 34)
	var parser := _load_resource(resources, "token_parser_8986_89BA.bin", 52)
	var ed := _load_resource(resources, "ed_team_handler_8AE7_8B0A.bin", 35)
	var ee := _load_resource(resources, "ee_numeric_handler_8B2F_8B48.bin", 25)
	var text_loop := _load_resource(resources, "ed_text_loop_8A56_8A86.bin", 48)
	var lengths := _load_resource(resources, "ed_team_name_lengths_8B0A_8B0E.bin", 4)
	var writer := _load_resource(resources, "character_buffer_writer_8C85_8CA5.bin", 32)
	var decimal_formatter := _load_resource(resources, "decimal_formatter_8C55_8C85.bin", 48)
	var lookup := _load_resource(resources, "fixed_team_name_lookup_F30F_F329.bin", 26)
	var dispatch := _load_resource(resources, "fixed_team_name_dispatch_C53C_C53F.bin", 3)
	var pointers := _load_resource(resources, "fixed_team_name_pointer_entries_76_79_F415_F41D.bin", 8)
	if vectors.size() != 34 or parser.size() != 52 or ed.size() != 35 or ee.size() != 25 \
			or text_loop.size() != 48 or lengths.size() != 4 or writer.size() != 32 or decimal_formatter.size() != 48 \
			or lookup.size() != 26 or dispatch.size() != 3 or pointers.size() != 8:
		return false
	var ed_target := int(vectors[26]) | (int(vectors[27]) << 8)
	var ee_target := int(vectors[28]) | (int(vectors[29]) << 8)
	if ed_target != 0x8AE7 or ee_target != 0x8B2F \
			or parser.slice(22, 32) != PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xB1, 0x3E, 0xC9, 0xE0, 0x90, 0x06]) \
			or ed.slice(0, 18) != PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xAE, 0x2A, 0x00, 0xB1, 0x3E, 0xF0, 0x03, 0xAE, 0x2B, 0x00, 0xBD, 0x0A, 0x8B, 0x48]) \
			or ee.slice(0, 25) != PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xB1, 0x3E, 0xAA, 0xBD, 0x28, 0x00, 0xAC, 0x27, 0x00, 0xC0, 0x04, 0xD0, 0x03, 0xBD, 0x10, 0x06, 0xA2, 0x00, 0x4C, 0x55, 0x8C]):
		last_error = "ROM $ED/$EE dispatch or operand-consuming handler bytes differ from the supported contract."
		return false
	if text_loop.slice(25, 29) != PackedByteArray([0x85, 0x49, 0xA9, 0x00]) \
			or text_loop.slice(35, 41) != PackedByteArray([0x20, 0x24, 0xC5, 0x20, 0x9F, 0x8C]):
		last_error = "ROM $ED character scan or emit callsite changed."
		return false
	if int(lengths[0]) != 3 or int(lengths[3]) != 3:
		last_error = "ROM team-name length table changed for IDs 0 or 3."
		return false
	if dispatch != PackedByteArray([0x4C, 0x0F, 0xF3]) or lookup.slice(0, 8) != PackedByteArray([0xA0, 0x29, 0x84, 0x30, 0xA0, 0xF3, 0x84, 0x31]):
		last_error = "ROM team-name dispatch or pointer lookup prologue changed."
		return false
	if writer.slice(0, 3) != PackedByteArray([0xA6, 0x3D, 0xC6]):
		last_error = "ROM character-buffer writer prologue changed."
		return false
	if decimal_formatter.slice(0, 5) != PackedByteArray([0xA4, 0x3C, 0x88, 0xF0, 0x2A]) \
			or decimal_formatter.slice(29, 33) != PackedByteArray([0xA5, 0x6F, 0xF0, 0x0E]):
		last_error = "ROM decimal formatter's zero-value return path changed."
		return false
	return true


func _write_forward_tiles(record: Dictionary, start_column: int, tiles_variant: Variant) -> bool:
	if not (tiles_variant is PackedByteArray or tiles_variant is Array):
		return false
	var tiles: PackedByteArray = record.get("tiles", PackedByteArray()).duplicate()
	var packet: PackedByteArray = record.get("packet", PackedByteArray()).duplicate()
	for index in tiles_variant.size():
		var column: int = start_column + index
		if column < 0 or column >= tiles.size():
			return false
		var tile := int(tiles_variant[index])
		tiles[column] = tile & 0xFF
		packet[3 + column] = tile & 0xFF
	record["tiles"] = tiles
	record["packet"] = packet
	return true


func _complete_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in packet_records:
		if bool(record.get("complete", false)):
			result.append(record.duplicate(true))
	return result


func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH) or FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		last_error = "Descriptor-$01 ROM-source manifest failed its fixed hash check."
		return {}
	var parsed := _read_json(MANIFEST_PATH)
	if parsed.is_empty() or str(parsed.get("schema", "")) != "ct2-field-entry-window-01-rom-sources-v1":
		last_error = "Descriptor-$01 ROM-source manifest is missing or unsupported."
		return {}
	var rom: Dictionary = parsed.get("source_rom", {})
	if str(rom.get("sha256", "")) != ROM_SHA256 or bool(rom.get("runtime_dependency", true)):
		last_error = "Descriptor-$01 source manifest targets another ROM or marks it as a runtime dependency."
	return parsed if last_error.is_empty() else {}


func _resources_by_path(manifest: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in manifest.get("resources", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			result[str(entry.get("path", ""))] = entry
	return result


func _load_resource(resources: Dictionary, name: String, expected_size: int) -> PackedByteArray:
	var entry: Dictionary = resources.get(name, {})
	var path := ROOT + name
	if entry.is_empty() or not FileAccess.file_exists(path):
		last_error = "Missing descriptor-$01 ROM resource: " + name
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(path)
	if (expected_size >= 0 and bytes.size() != expected_size) \
			or bytes.size() != int(entry.get("size_bytes", -1)) \
			or FileAccess.get_sha256(path) != str(entry.get("sha256", "")):
		last_error = "Descriptor-$01 ROM resource failed size/hash validation: " + name
		return PackedByteArray()
	return bytes


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _bytes_equal(bytes: PackedByteArray, expected: Array[int]) -> bool:
	if bytes.size() != expected.size():
		return false
	for index in expected.size():
		if int(bytes[index]) != expected[index]:
			return false
	return true


func _fail_result(message: String) -> Dictionary:
	last_error = message
	status = {"ok": false, "error": message}
	return status
