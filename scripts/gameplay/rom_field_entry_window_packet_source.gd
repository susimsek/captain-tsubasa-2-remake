extends RefCounted
class_name RomFieldEntryWindowPacketSource
## Hash-checks field-entry window descriptor $00 and builds its ROM row packets.
## Dynamic rows resolve only from the source-owned fresh-period result;
## missing or mismatched caller state leaves the records fail-closed.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/field_entry_window_00/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const SOURCE_MANIFEST_SHA256 := "fe9d47fff258a2ee092969b2a5c64d0bce24a99193e89f63954408fc3407dd00"
const LAYOUT_BUILDER := preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const PERIOD_TASK_CODE_SHA256 := "28895a5c3512a45e1b1a59c4324654ec03bb5f2ea413445e32333aa3bd6b87cc"
const PERIOD_TASK_TABLE_SHA256 := "0e1862b77227e30a4b6f6d40295f173db76d2473f8b9e31b241239c07a5837fa"
const DESCRIPTOR_ID := 0x00
const DESCRIPTOR_CPU := 0xB453
const DESCRIPTOR_POINTER_CPU := 0xB3CF
const WINDOW_FRAME_SHA256 := "dcb1f10d1a9a0fa616fa2e065790ce038722b09968d265e7901770b3bf9133e0"
const DYNAMIC_HANDLER_RESOURCES := {
	"token_dispatch_vectors_EF_F0_89BA_89DC.bin": {"size": 34, "sha256": "74f4bd039c15b503a6b4d4a71652c4c957a179f05cf105c142c04eb740759ebe"},
	"ef_match_period_handler_8B48_8B77.bin": {"size": 47, "sha256": "cdf517738c475cd7991746f6213fea50152fa0b1d3863d77f4d7e618d1d63af3"},
	"f0_match_clock_handler_8B8B_8BD5.bin": {"size": 74, "sha256": "90eca873b94249d9b8c6b70885e9383a118c6af988ce56bd88301b07e912eb2e"},
	"decimal_tile_formatter_8C55_8CA5.bin": {"size": 80, "sha256": "f2b7c31fe7df259b3a72ce0b8a2fef86ad4a586d49a30df3d1d8cd272434a61e"},
	"fixed_text_dispatch_C509_C50C.bin": {"size": 3, "sha256": "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"},
	"fixed_inline_dispatch_CB99_CBB0.bin": {"size": 23, "sha256": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"},
	"fixed_division_dispatch_C51E_C521.bin": {"size": 3, "sha256": "7b0a50829c23361f1f95e0b52657262d62358c50623da017b3c721ba27ba81e1"},
	"fixed_division_16bit_CD3C_CD77.bin": {"size": 59, "sha256": "2d996c8e5e587175f76672794f405945b4c1c981fa6775cf93b8971f1f39a008"},
}

var last_error := ""
var status: Dictionary = {}
var packet_records: Array[Dictionary] = []


## Build descriptor-$00 $04A5 records. Pass the direct result from
## RomFreshPeriodTask.execute_fresh_match_zero() to resolve $EF/$F0.
## Missing or mismatched period-task state keeps both rows incomplete.
func build_descriptor_00(fresh_period_result: Dictionary = {}) -> Dictionary:
	last_error = ""
	status.clear()
	packet_records.clear()
	var manifest := _read_manifest()
	if manifest.is_empty():
		return _fail_result("Field-entry descriptor manifest is missing or malformed.")
	if FileAccess.get_sha256(MANIFEST_PATH) != SOURCE_MANIFEST_SHA256:
		return _fail_result("Field-entry descriptor manifest failed its hash check.")
	if str(manifest.get("schema", "")) != "ct2-field-entry-window-00-rom-sources-v1":
		return _fail_result("Field-entry descriptor manifest schema is unsupported.")
	var rom_info: Dictionary = manifest.get("source_rom", {})
	if str(rom_info.get("sha256", "")) != SOURCE_ROM_SHA256 \
			or bool(rom_info.get("runtime_dependency", true)):
		return _fail_result("Field-entry source manifest targets a different ROM or declares a runtime ROM dependency.")

	var resources_by_path := _resources_by_path(manifest)
	var pointer := _load_verified_resource(resources_by_path, "descriptor_00_pointer.bin", 2)
	var descriptor := _load_verified_resource(resources_by_path, "descriptor_00.bin", 17)
	var first_row := _load_verified_resource(resources_by_path, "descriptor_00_row_00.bin", 2)
	var second_row := _load_verified_resource(resources_by_path, "descriptor_00_row_01.bin", 2)
	if pointer.size() != 2 or descriptor.size() != 17 \
			or first_row.size() != 2 or second_row.size() != 2:
		return _fail_result(last_error if not last_error.is_empty() \
			else "Field-entry descriptor source bytes have an unexpected size.")
	var descriptor_pointer := int(pointer[0]) | (int(pointer[1]) << 8)
	if descriptor_pointer != DESCRIPTOR_CPU:
		return _fail_result("ROM pointer-table entry no longer selects descriptor $00 at $B453.")
	if int(manifest.get("descriptor_frame_family_index", -1)) != 0:
		return _fail_result("Descriptor $00 no longer selects the verified ROM frame family zero.")
	if int(descriptor[8]) != 2 or first_row[0] != 0xEF or first_row[1] != 0xFC \
			or second_row[0] != 0xF0 or second_row[1] != 0xFC:
		return _fail_result("Descriptor $00 header or row tokens differ from the checked source.")
	for row_index in 2:
		var record_offset := 9 + row_index * 4
		var row_pointer := int(descriptor[record_offset + 2]) \
			| (int(descriptor[record_offset + 3]) << 8)
		var expected_row_pointer := 0xBBDC if row_index == 0 else 0xBBDE
		if row_pointer != expected_row_pointer:
			return _fail_result("Descriptor $00 row %d pointer is outside the checked source contract." % row_index)

	var frame_resource: Dictionary = manifest.get("shared_frame_family", {})
	if int(frame_resource.get("size_bytes", -1)) != 9 \
			or str(frame_resource.get("sha256", "")) != WINDOW_FRAME_SHA256:
		return _fail_result("Shared ROM window frame metadata is invalid.")
	var frame_path := "res://" + str(frame_resource.get("path_from_project_root", ""))
	if not FileAccess.file_exists(frame_path):
		return _fail_result("Shared ROM window frame resource is missing.")
	var frame_tiles := FileAccess.get_file_as_bytes(frame_path)
	if frame_tiles.size() != 9 or FileAccess.get_sha256(frame_path) != WINDOW_FRAME_SHA256:
		return _fail_result("Shared ROM window frame resource failed its size/hash check.")
	var handler_sources := _load_handler_sources(resources_by_path)
	if handler_sources.is_empty():
		return _fail_result(last_error if not last_error.is_empty() \
			else "The ROM $EF/$F0 handler source package is incomplete.")
	if not _verify_handler_dispatch(handler_sources):
		return _fail_result(last_error)

	var rows: Array[PackedByteArray] = [first_row, second_row]
	packet_records = LAYOUT_BUILDER.build_packets(descriptor, frame_tiles, rows)
	if packet_records.size() != int(descriptor[3]) + 1:
		return _fail_result("ROM layout builder did not emit every descriptor $00 progress row.")

	var source_inputs := _read_fresh_period_inputs(fresh_period_result)
	var unresolved_tokens: Array[Dictionary] = []
	var all_rows_complete := true
	for record in packet_records:
		var packet: PackedByteArray = record.get("packet", PackedByteArray())
		var payload_width := int(descriptor[2])
		if packet.size() != payload_width + 3 or int(packet[0]) != payload_width:
			return _fail_result("ROM layout builder returned a malformed $04A5 record.")
		var progress := int(record.get("progress", -1))
		var source_row := -1
		for row_index in 2:
			if progress == int(descriptor[9 + row_index * 4]):
				source_row = row_index
		if source_row < 0:
			continue
		var token := int(rows[source_row][0])
		if not bool(source_inputs.get("ok", false)):
			var unresolved := {
				"progress": progress,
				"token": token,
				"row": source_row,
				"handler_cpu": "$8B48" if token == 0xEF else "$8B8B",
				"needs": String(source_inputs.get("missing", "hash-checked fresh-period result")),
			}
			record["complete"] = false
			record["missing_dynamic"] = [unresolved]
			unresolved_tokens.append(unresolved)
			all_rows_complete = false
			continue
		if token == 0xEF:
			# With fresh period zero, the ROM's first special-text byte is $FF.
			# $8B48 returns without emitting a tile.
			record["source_token_output"] = {
				"token": token,
				"handler_cpu": "$8B48",
				"caller_$0027": int(source_inputs["period"]),
				"emitted_tiles": [],
			}
		elif token == 0xF0:
			var output := _decode_f0_clock_row(
				int(source_inputs["clock_low"]), int(source_inputs["clock_high"]),
				handler_sources["f0_match_clock_handler_8B8B_8BD5.bin"])
			if not bool(output.get("ok", false)):
				var unsupported := {
					"progress": progress, "token": token, "row": source_row,
					"handler_cpu": "$8B8B", "needs": String(output.get("error", "supported $F0 source output")),
				}
				record["complete"] = false
				record["missing_dynamic"] = [unsupported]
				unresolved_tokens.append(unsupported)
				all_rows_complete = false
				continue
			if not _apply_reverse_token_writes(record, descriptor, source_row,
					output.get("writes_reversed", [])):
				return _fail_result("The source $F0 handler writes outside its descriptor packet.")
			record["source_token_output"] = output
		else:
			return _fail_result("Descriptor $00 contains an unhandled source token $%02X." % token)
		record["complete"] = true
		record["missing_dynamic"] = []

	var complete_records: Array[Dictionary] = []
	for record in packet_records:
		if bool(record.get("complete", false)):
			complete_records.append(record)
		else:
			all_rows_complete = false

	status = {
		"ok": true,
		"descriptor_id": DESCRIPTOR_ID,
		"descriptor_cpu_address": DESCRIPTOR_CPU,
		"packet_record_format": "length, PPU address low, PPU address high, tile payload",
		"progress_packet_count": packet_records.size(),
		"packet_data_complete": all_rows_complete,
		"queue_submission_ready": all_rows_complete,
		"ready_flag_0515": "caller-owned; this component never writes it",
		"source_inputs_ready": bool(source_inputs.get("ok", false)),
		"source_input_producer": "RomFreshPeriodTask.execute_fresh_match_zero at $D11E->$DAAA",
		"source_inputs": source_inputs.get("values", {}),
		"source_input_provenance": source_inputs.get("provenance", {}),
		"packet_records": packet_records.duplicate(true),
		"complete_packet_records": complete_records,
		"unresolved_source_tokens": unresolved_tokens,
		"stop_boundary": "descriptor-$00 $EF/$F0 handlers are decoded for source period 0 and clock $00B4; unsupported caller inputs fail closed",
		"descriptor_01_supported": false,
		"descriptor_01_reason": "its $ED/$EE tokens carry operands outside this checked packet contract",
	}
	return status


func _load_handler_sources(resources: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for path: String in DYNAMIC_HANDLER_RESOURCES:
		var spec: Dictionary = DYNAMIC_HANDLER_RESOURCES[path]
		var bytes := _load_verified_resource(resources, path, int(spec["size"]))
		if bytes.is_empty() or FileAccess.get_sha256(SOURCE_ROOT + path) != str(spec["sha256"]):
			last_error = "ROM dynamic-handler source failed its fixed hash check: " + path
			return {}
		result[path] = bytes
	return result


func _verify_handler_dispatch(sources: Dictionary) -> bool:
	var vectors: PackedByteArray = sources["token_dispatch_vectors_EF_F0_89BA_89DC.bin"]
	var ef_target := int(vectors[0x0F * 2]) | (int(vectors[0x0F * 2 + 1]) << 8)
	var f0_target := int(vectors[0x10 * 2]) | (int(vectors[0x10 * 2 + 1]) << 8)
	if ef_target != 0x8B48 or f0_target != 0x8B8B:
		last_error = "ROM token vectors no longer dispatch $EF->$8B48 and $F0->$8B8B."
		return false
	var ef_handler: PackedByteArray = sources["ef_match_period_handler_8B48_8B77.bin"]
	var f0_handler: PackedByteArray = sources["f0_match_clock_handler_8B8B_8BD5.bin"]
	var decimal_formatter: PackedByteArray = sources["decimal_tile_formatter_8C55_8CA5.bin"]
	var text_dispatch: PackedByteArray = sources["fixed_text_dispatch_C509_C50C.bin"]
	var inline_dispatch: PackedByteArray = sources["fixed_inline_dispatch_CB99_CBB0.bin"]
	var division_dispatch: PackedByteArray = sources["fixed_division_dispatch_C51E_C521.bin"]
	var division: PackedByteArray = sources["fixed_division_16bit_CD3C_CD77.bin"]
	if ef_handler.slice(0, 6) != PackedByteArray([0xA9, 0x00, 0x85, 0x47, 0xAD, 0x27]) \
			or ef_handler.slice(42, 47) != PackedByteArray([0xFF, 0x20, 0x34, 0x2E, 0xFF]) \
			or f0_handler.slice(0, 10) != PackedByteArray([0xA2, 0x00, 0xAD, 0xF7, 0x05, 0xAC, 0xF8, 0x05, 0x38, 0xE9]) \
			or f0_handler.slice(47, 62) != PackedByteArray([0xA9, 0x77, 0xA0, 0x00, 0x20, 0x85, 0x8C, 0xC6, 0x3D, 0x68, 0xA2, 0x00, 0x4C, 0x55, 0x8C]) \
			or decimal_formatter.slice(0, 17) != PackedByteArray([0xA4, 0x3C, 0x88, 0xF0, 0x2A, 0x85, 0x6F, 0x86, 0x70, 0xA9, 0x0A, 0x85, 0x71, 0xA9, 0x00, 0x85, 0x74]) \
			or text_dispatch != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or inline_dispatch.size() != 23 or division_dispatch != PackedByteArray([0x4C, 0x3C, 0xCD]) \
			or division.size() != 59 or division[0] != 0x8A or division[1] != 0x48 \
			or division[division.size() - 1] != 0x60:
		last_error = "ROM dynamic-handler bytes differ from the checked $EF/$F0 execution contract."
		return false
	return true


func _read_fresh_period_inputs(result: Dictionary) -> Dictionary:
	if result.is_empty():
		return {"ok": false, "missing": "direct RomFreshPeriodTask result carrying $0027/$05F7/$05F8"}
	if not bool(result.get("ok", false)) \
			or str(result.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(result.get("source_code_sha256", "")) != PERIOD_TASK_CODE_SHA256 \
			or str(result.get("camera_table_sha256", "")) != PERIOD_TASK_TABLE_SHA256 \
			or int(result.get("exit_pc", -1)) != 0xDAAA:
		return {"ok": false, "missing": "hash-checked fresh-period source result through $DAAA"}
	var entry: Dictionary = result.get("entry", {})
	var context: Dictionary = result.get("source_context", {})
	var ram: Dictionary = result.get("ram", {})
	if int(entry.get("pc", -1)) != 0xD11E or int(entry.get("slot_base", -1)) != 0x05 \
			or str(context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or str(context.get("rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or str(context.get("source_event", "")).is_empty():
		return {"ok": false, "missing": "source-owned slot-$05 $D11E caller context"}
	for address: String in ["$0027", "$05F7", "$05F8"]:
		if not ram.has(address) or int(ram[address]) < 0:
			return {"ok": false, "missing": "source RAM input " + address}
	if int(ram["$0027"]) != 0x00 or int(ram["$05F7"]) != 0xB4 or int(ram["$05F8"]) != 0x00:
		return {"ok": false, "missing": "supported fresh-match values $0027=$00, $05F7=$B4, $05F8=$00"}
	return {
		"ok": true,
		"values": {"$0027": int(ram["$0027"]), "$05F7": int(ram["$05F7"]), "$05F8": int(ram["$05F8"])},
		"period": int(ram["$0027"]),
		"clock_low": int(ram["$05F7"]),
		"clock_high": int(ram["$05F8"]),
		"producer": "$D11E reads period $0027; $D183/$D184 supplies $B4/$00 to $05F7/$05F8",
		"provenance": {
			"rom_sha256": str(result["rom_sha256"]),
			"slot_base": int(entry["slot_base"]),
			"entry_pc": int(entry["pc"]),
			"exit_pc": int(result["exit_pc"]),
			"source_code_sha256": str(result["source_code_sha256"]),
			"camera_table_sha256": str(result["camera_table_sha256"]),
			"source_event": str(context["source_event"]),
		},
	}


func _decode_f0_clock_row(clock_low: int, clock_high: int,
		rom_handler: PackedByteArray) -> Dictionary:
	var source_value := (clock_low & 0xFF) | ((clock_high & 0xFF) << 8)
	if source_value != 0x00B4 or rom_handler.size() != 74:
		return {"ok": false, "error": "ROM $F0 handler is decoded only for its sourced clock input $00B4"}
	var fractional_units := source_value % 6
	var decimal_value := int(source_value / 6)
	var table_offset := 0x8BC9 - 0x8B8B
	var fractional_table := rom_handler.slice(table_offset, table_offset + 12)
	if fractional_table.size() != 12:
		return {"ok": false, "error": "ROM $F0 fractional tile table is incomplete"}
	var writes_reversed: Array[int] = [
		int(fractional_table[fractional_units * 2]),
		int(fractional_table[fractional_units * 2 + 1]),
		int(rom_handler[0x8BBB - 0x8B8B]),
	]
	var remaining := decimal_value
	while remaining >= 10:
		writes_reversed.append(0x33 + remaining % 10)
		remaining = int(remaining / 10)
	if remaining > 0:
		writes_reversed.append(0x33 + remaining)
	var row_tiles_forward: Array[int] = []
	for index in range(writes_reversed.size() - 1, -1, -1):
		row_tiles_forward.append(writes_reversed[index])
	return {
		"ok": true,
		"token": 0xF0,
		"handler_cpu": "$8B8B",
		"formatter_cpu": "$8C55",
		"source_clock_value": source_value,
		"divide_by_six_quotient": decimal_value,
		"divide_by_six_remainder": fractional_units,
		"writes_reversed": writes_reversed,
		"row_tiles_forward": row_tiles_forward,
	}


func _apply_reverse_token_writes(record: Dictionary, descriptor: PackedByteArray,
		row_index: int, writes: Array) -> bool:
	var record_offset := 9 + row_index * 4
	var cursor := int(descriptor[4]) + int(descriptor[record_offset + 1])
	var tiles: PackedByteArray = record.get("tiles", PackedByteArray()).duplicate()
	var packet: PackedByteArray = record.get("packet", PackedByteArray()).duplicate()
	for offset in writes.size():
		var write: Variant = writes[offset]
		var tile := int(write) if write is int else -1
		var column := cursor - offset
		if tile < 0 or column < 0 or column >= tiles.size():
			return false
		tiles[column] = tile & 0xFF
		packet[3 + column] = tile & 0xFF
	record["tiles"] = tiles
	record["packet"] = packet
	return true


func _read_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		last_error = "Missing source manifest: " + MANIFEST_PATH
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		last_error = "Malformed source manifest: " + MANIFEST_PATH
		return {}
	return parsed


func _resources_by_path(manifest: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_entry in manifest.get("resources", []):
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			result[str(entry.get("path", ""))] = entry
	return result


func _load_verified_resource(resources: Dictionary, path: String,
		expected_size: int) -> PackedByteArray:
	var entry: Dictionary = resources.get(path, {})
	var resource_path := SOURCE_ROOT + path
	if entry.is_empty() or int(entry.get("size_bytes", -1)) != expected_size \
			or not FileAccess.file_exists(resource_path):
		last_error = "Missing or malformed field-entry resource: " + path
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(resource_path)
	if bytes.size() != expected_size \
			or FileAccess.get_sha256(resource_path) != str(entry.get("sha256", "")):
		last_error = "Field-entry resource failed its size/hash check: " + path
		return PackedByteArray()
	return bytes


func _fail_result(message: String) -> Dictionary:
	last_error = message
	status = {"ok": false, "error": message}
	return status
