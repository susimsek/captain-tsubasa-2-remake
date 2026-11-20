extends RefCounted
class_name RomSlot15Map2DFirstBatchExecutor
## Resolves the first three ROM map-block IDs for callback-$34 / map-$2D.
## It validates source inputs without claiming scheduler timing, tile expansion,
## PPU writes, or task continuation.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/slot15_callback_34/"
const MANIFEST_PATH := ROOT + "manifest.json"
const MANIFEST_SHA256 := "212c07b3c6230340e469a113cbe9af4e3889a1f0d4a7e7b602e74c056d9d7bf8"
const POINTER_PATH := ROOT + "callback_34_script_pointer.bin"
const POINTER_SHA256 := "f287538c65456d2234e6d47bce379df09af4207af9ac4a1a6dea54486d59a931"
const SCRIPT_PATH := ROOT + "callback_34_map_2d_script.bin"
const SCRIPT_SHA256 := "530988962b3acfb674a6c3a9b9a16cdb2ae2e81c6f3b2ce3883de4137585dacf"
const SELECTOR_PATH := ROOT + "map_2d_selector_source.bin"
const SELECTOR_SHA256 := "189f40034be7a199f1fa9891668ee3ab6049f82d38c68be70f596eab2e1857b7"
const CHR_PAIR_PATH := ROOT + "map_2d_chr_pair.bin"
const CHR_PAIR_SHA256 := "fcf0a6c700dd13e274b6fba8deea8dd9b26e4eedde3495717cac8408c9c5177f"
const BLOCK_PATH := ROOT + "map_2d_block.bin"
const BLOCK_SHA256 := "5f2a7c9e9b42fa9860e062f8df1ee57caf1d255424d85ff884c6158f1cf8e1e9"

const CALLBACK_ID := 0x34
const SCENARIO_ID := 0x38
const MAP_ID := 0x2D
const CALLBACK_POINTER_CPU := 0x885E
const CALLBACK_POINTER_FILE := 0x01686E
const CALLBACK_SCRIPT_CPU := 0x89E1
const CALLBACK_SCRIPT_FILE := 0x0169F1
const SELECTOR_TABLE_CPU := 0x8B42
const SELECTOR_CPU := 0x8B4D
const SELECTOR_FILE := 0x016B5D
const CHR_PAIR_TABLE_CPU := 0x86EE
const CHR_PAIR_CPU := 0x8748
const CHR_PAIR_FILE := 0x016758
const MAP_BLOCK_CPU := 0x9104
const MAP_BLOCK_FILE := 0x017114
const NEIGHBOR_MAP_ID := 0x28
const NEIGHBOR_MAP_CPU := 0x9064
const NEIGHBOR_MAP_FILE := 0x017074
const MAP_BLOCK_LENGTH := 0x20
const MAP_FIRST_BATCH_MAX_CELLS := 3
const PREFIX_BYTES := [0xA0, 0x02, 0xB1, 0x52,
	0x8D, 0xCC, 0x05, 0xAC, 0xCD, 0x05, 0x20, 0x25, 0x85]

var error_message := ""


func execute_first_batch_source(handler_prefix_result: Dictionary) -> Dictionary:
	error_message = ""
	var loaded := _load_sources()
	if not bool(loaded.get("ok", false)):
		return _failure(String(loaded.get("error", "Callback-$34 map-$2D sources failed validation.")))
	var sources: Dictionary = loaded["sources"]
	var cpu_variant: Variant = handler_prefix_result.get("registers", {})
	var ram_variant: Variant = handler_prefix_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = handler_prefix_result.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = handler_prefix_result.get("mapper", {})
	if not cpu_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not mapper_variant is Dictionary:
		return _failure("The callback-$34 map-handler prefix omits CPU, RAM, stack, or mapper state.")
	var cpu: Dictionary = cpu_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var source_reads_variant: Variant = handler_prefix_result.get("source_reads", [])
	if not source_reads_variant is Array:
		return _failure("The callback-$34 map-handler result omits ROM source reads.")
	var callback_map_read := false
	for read_variant in source_reads_variant:
		if not read_variant is Dictionary:
			continue
		var read: Dictionary = read_variant
		if int(read.get("pc", -1)) == 0x8329 \
				and int(read.get("address", -1)) == CALLBACK_SCRIPT_CPU + 2 \
				and int(read.get("value", -1)) == MAP_ID \
				and String(read.get("kind", "")) == "callback_command_byte":
			callback_map_read = true
			break
	if String(handler_prefix_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(handler_prefix_result.get("status", "")) != "entered_map_worker_8525" \
			or int(handler_prefix_result.get("scenario", -1)) != SCENARIO_ID \
			or int(handler_prefix_result.get("callback_id", -1)) != CALLBACK_ID \
			or int(handler_prefix_result.get("map_selector", -1)) != MAP_ID \
			or int(handler_prefix_result.get("entry_pc", -1)) != 0x8327 \
			or int(handler_prefix_result.get("exit_pc", -1)) != 0x8525 \
			or bool(handler_prefix_result.get("trace_state_used", true)) \
			or bool(handler_prefix_result.get("worker_body_executed", true)) \
			or int(cpu.get("pc", -1)) != 0x8525 or int(cpu.get("a", -1)) != MAP_ID \
			or int(cpu.get("x", -1)) != (CALLBACK_SCRIPT_CPU & 0xFF) \
			or int(cpu.get("sp", -1)) != 0xEE \
			or int(mapper.get("bank_low", -1)) != 0x0B \
			or int(mapper.get("bank_high", -1)) != 0x0C \
			or ram.size() != 0x800 or stack.size() != 0x100 \
			or int(ram[0x0000]) != 0x15 or int(ram[0x05CC]) != MAP_ID \
			or not callback_map_read or handler_prefix_result.get("source_bytes_executed", PackedByteArray()) != PackedByteArray(PREFIX_BYTES):
		return _failure("Input is not the source-only callback-$34 -> map-$2D worker entry at `$8525`.")

	var map_block: PackedByteArray = sources["map_block"]
	var first_batch_count := mini(MAP_FIRST_BATCH_MAX_CELLS, map_block.size())
	var first_batch_ids := map_block.slice(0, first_batch_count)
	var source_hashes: Dictionary = loaded["source_hashes"]
	var source_offsets := {
		"callback_pointer": CALLBACK_POINTER_FILE,
		"callback_script": CALLBACK_SCRIPT_FILE,
		"selector_byte": SELECTOR_FILE,
		"chr_pair": CHR_PAIR_FILE,
		"map_block": MAP_BLOCK_FILE,
	}
	return {
		"ok": true,
		"status": "slot15_map_2d_first_batch_source_resolved",
		"rom_sha256": ROM_SHA256,
		"scenario_id": SCENARIO_ID,
		"callback_id": CALLBACK_ID,
		"map_id": MAP_ID,
		"map_selector": int(sources["resolved_selector"]),
		"chr_pair": sources["chr_pair"].duplicate(),
		"staged_chr_pair": PackedByteArray([int(sources["chr_pair"][0]) | 0x80,
			int(sources["chr_pair"][1])]),
		"map_block_cpu_address": MAP_BLOCK_CPU,
		"map_block_file_offset": MAP_BLOCK_FILE,
		"map_block_length_bytes": map_block.size(),
		"first_batch_start_index": 0,
		"first_batch_cell_ids": first_batch_ids,
		"source_file_offsets": source_offsets,
		"source_hashes": source_hashes,
		"worker_execution_or_queue_packet_emitted": false,
		"scheduler_return_modeled": false,
		"frame_cycle_timing_modeled": false,
		"trace_state_used": false,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"unresolved": [
			"This result resolves the first three source block IDs only; it does not execute the resumed `$8572` task or `$85C2` metatile expansion.",
			"Live source-read order, cooperative yield/continuation, PPU queue writes, and frame timing remain unmodeled.",
		],
	}


func _load_sources() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH) \
			or FileAccess.get_sha256(MANIFEST_PATH) != MANIFEST_SHA256:
		return {"ok": false, "error": "Callback-$34 map-$2D manifest failed its SHA-256 check."}
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return {"ok": false, "error": "Callback-$34 map-$2D manifest is invalid JSON."}
	var manifest: Dictionary = manifest_variant
	if String(manifest.get("schema", "")) != "slot15-callback-34-map-2d-rom-sources-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(manifest.get("source_rom_size_bytes", -1)) != 393232:
		return {"ok": false, "error": "Callback-$34 source manifest does not identify the canonical ROM."}
	var mapping: Dictionary = manifest.get("bank_mapping", {})
	if String(mapping.get("prg_bank", "")) != "$0B" \
			or String(mapping.get("cpu_window", "")) != "0x8000-0x9FFF" \
			or String(mapping.get("file_window_base", "")) != "0x016010":
		return {"ok": false, "error": "Callback-$34 source bank mapping is inconsistent."}
	var map_source: Dictionary = manifest.get("map_2d_resolution", {})
	if String(map_source.get("map_id", "")) != "$2D" \
			or String(map_source.get("map_block_cpu_address", "")) != "0x9104" \
			or String(map_source.get("map_block_file_offset", "")) != "0x017114" \
			or String(map_source.get("map_block_address_formula", "")) != \
				"0x8B64 + ((map ID >> 3) << 8) + ((map ID & 7) << 5)":
		return {"ok": false, "error": "Map-$2D block mapping does not match the `$8525` source formula."}
	var neighbor_note := String(map_source.get("neighboring_block_note", ""))
	if not neighbor_note.contains("0x28") or not neighbor_note.contains("0x9064"):
		return {"ok": false, "error": "The nearby map-$28 block is not distinguished from map-$2D source data."}
	var span_entries_variant: Variant = manifest.get("source_spans", [])
	if not span_entries_variant is Array:
		return {"ok": false, "error": "Callback-$34 manifest omits its source span table."}
	var span_by_path: Dictionary = {}
	for span_variant in span_entries_variant:
		if span_variant is Dictionary:
			span_by_path[String(span_variant.get("path", ""))] = span_variant
	var specs := {
		"callback_pointer": [POINTER_PATH, POINTER_SHA256, 2, CALLBACK_POINTER_CPU, CALLBACK_POINTER_FILE, "E1 89"],
		"callback_script": [SCRIPT_PATH, SCRIPT_SHA256, 3, CALLBACK_SCRIPT_CPU, CALLBACK_SCRIPT_FILE, "02 00 2D"],
		"selector_byte": [SELECTOR_PATH, SELECTOR_SHA256, 1, SELECTOR_CPU, SELECTOR_FILE, "6A"],
		"chr_pair": [CHR_PAIR_PATH, CHR_PAIR_SHA256, 2, CHR_PAIR_CPU, CHR_PAIR_FILE, "00 02"],
		"map_block": [BLOCK_PATH, BLOCK_SHA256, MAP_BLOCK_LENGTH, MAP_BLOCK_CPU, MAP_BLOCK_FILE,
			"00 71 72 72 73 72 74 00 00 75 76 77 78 79 7A 00 00 7B 7C 7D 7E 7F 80 00 00 81 82 82 83 82 84 00"],
	}
	var source: Dictionary = {}
	var source_hashes := {"manifest": MANIFEST_SHA256}
	for key: String in specs:
		var spec: Array = specs[key]
		var path := String(spec[0])
		var expected_hash := String(spec[1])
		var expected_size := int(spec[2])
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() != expected_size or FileAccess.get_sha256(path) != expected_hash \
				or bytes.hex_encode().to_upper() != String(spec[5]).replace(" ", ""):
			return {"ok": false, "error": "Callback-$34 map-$2D ROM input failed byte/hash validation: %s" % path}
		var span_variant: Variant = span_by_path.get(path.trim_prefix("res://"), {})
		if not span_variant is Dictionary:
			return {"ok": false, "error": "Callback-$34 manifest entry is missing for %s" % path}
		var span: Dictionary = span_variant
		if String(span.get("prg_bank", "")) != "$0B" \
				or String(span.get("cpu_address", "")) != "0x%04X" % int(spec[3]) \
				or String(span.get("file_offset", "")) != "0x%06X" % int(spec[4]) \
				or int(span.get("length_bytes", -1)) != expected_size \
				or String(span.get("sha256", "")) != expected_hash:
			return {"ok": false, "error": "Callback-$34 manifest provenance differs for %s" % path}
		source[key] = bytes
		source_hashes[key] = expected_hash
	var selector_index := MAP_ID >> 2
	var selector_shift := 2 * (MAP_ID & 0x03)
	var selector_source: PackedByteArray = source["selector_byte"]
	var resolved_selector := (int(selector_source[0]) >> selector_shift) & 0x03
	var calculated_selector_cpu := SELECTOR_TABLE_CPU + selector_index
	var calculated_chr_cpu := CHR_PAIR_TABLE_CPU + MAP_ID * 2
	var calculated_map_cpu := 0x8B64 + ((MAP_ID >> 3) << 8) + ((MAP_ID & 0x07) << 5)
	var calculated_neighbor_cpu := 0x8B64 + ((NEIGHBOR_MAP_ID >> 3) << 8) + ((NEIGHBOR_MAP_ID & 0x07) << 5)
	if (int(source["callback_pointer"][0]) | (int(source["callback_pointer"][1]) << 8)) != CALLBACK_SCRIPT_CPU \
			or source["callback_script"] != PackedByteArray([0x02, 0x00, MAP_ID]) \
			or calculated_selector_cpu != SELECTOR_CPU or resolved_selector != 0x02 \
			or calculated_chr_cpu != CHR_PAIR_CPU or calculated_map_cpu != MAP_BLOCK_CPU \
			or calculated_neighbor_cpu != NEIGHBOR_MAP_CPU:
		return {"ok": false, "error": "Callback-$34 map-$2D pointer/table resolution failed."}
	source["resolved_selector"] = resolved_selector
	source["source_hashes"] = source_hashes
	return {"ok": true, "sources": source, "source_hashes": source_hashes}


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_execution_refused", "error": message,
		"trace_state_used": false}
