extends RefCounted
class_name FirstMatchFieldCandidatePresenter
## Builds the best source-backed first-command field candidate from preserved
## ROM bytes. It deliberately does not consume PPU/OAM dumps or screenshots.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const BACKGROUND_PACKET_LOADER := preload("res://scripts/opening/rom_background_packet_loader.gd")
const FIELD_PACKET_PRODUCER := preload("res://scripts/gameplay/first_command_field_packet_producer.gd")
const FIELD_DESCRIPTOR_RESOLVER := preload("res://scripts/gameplay/rom_first_command_field_descriptor_resolver.gd")
const CALLBACK_DISPATCH_API := preload("res://scripts/gameplay/rom_first_command_callback_dispatch_api.gd")
const BG01_LAYOUT_PATH := "res://reference/rom_extract/intro/background_01_layout.json"
const CANDIDATE_PATH := "res://reference/rom_extract/gameplay/first_command_bg70_block56_rom_candidate.json"
const FIELD_DATA_ROOT := "res://reference/rom_extract/gameplay/first_command_field"
const PAGE_CORRECT_DATA_ROOT := FIELD_DATA_ROOT + "/page_correct_map_sources"
const PAGE_CORRECT_MANIFEST_PATH := PAGE_CORRECT_DATA_ROOT + "/manifest.json"
const BG01_DATA_ROOT := "res://reference/rom_extract/intro"

const FIELD_MAPS := [
	{
		"map_id": 0x36,
		"animation_id": 0x45,
		"animation_file_offset": 0x016A3A,
		"map_file_offset": 0x017234,
		"selector": 0x01,
		"tile_origin": 0x2800,
		"attribute_origin": 0x2BC0,
		"animation_hex": "06 00 36",
		"map_hex": "2B 2B 2B 2B EE 2B 2B 2B 2D 2E 2E 2E EF 2E 2E 2E 30 30 30 30 30 30 30 30 31 31 31 31 31 31 31 31",
	},
	{
		"map_id": 0x56,
		"animation_id": 0x70,
		"animation_file_offset": 0x016B48,
		"map_file_offset": 0x017634,
		"selector": 0x02,
		"tile_origin": 0x2A00,
		"attribute_origin": 0x2BE0,
		"animation_hex": "06 00 56",
		"map_hex": "15 16 15 15 1A 16 15 15 AD AD AD AD AD AD AD AD AE AE AE AE AE AE AE AE AF AF AF AF AF AF AF AF",
	},
]

var last_error := ""
var status: Dictionary = {}
var ppu_memory: Dictionary = {}


## `source_packet_context` must be produced by a live source-state model at the
## decoded $8327 callback and contain $0621, $0600, and previous $05CD. The
## presenter derives $063D/$05CE from preserved ROM code; resolved constants
## and emulator snapshots are not accepted as substitutes.
func build_and_apply(screen: RomPpuNametableScreenRenderer,
		source_packet_context: Dictionary = {}) -> bool:
	last_error = ""
	status.clear()
	ppu_memory.clear()
	if screen == null or not is_instance_valid(screen):
		return _fail("First-match field presenter received no PPU renderer.")

	var route_manifest := _read_json(CANDIDATE_PATH)
	if route_manifest.is_empty() or not _validate_route_manifest(route_manifest):
		return false
	if not _append_background_01_candidate(ppu_memory):
		return false
	var field_map_result := _append_source_field_maps(ppu_memory)
	if not bool(field_map_result.get("ok", false)):
		return false
	var packet_status := _append_source_packet_layer(source_packet_context)

	# The ROM's background-animation pair table resolves $56 to MMC3 R0/R1
	# selectors $3C/$2E. R0 and R1 each cover an aligned pair of 1 KiB CHR banks.
	# The selector is source-derived; its per-fetch timing is still unresolved.
	screen.begin_state_update()
	if not screen.set_background_profile(0x01, PackedByteArray(), BG01_DATA_ROOT):
		screen.end_state_update()
		return _fail("PPU renderer rejected the ROM background-$01 candidate.")
	var initial_chr_selectors: Array[int] = [0x3C, 0x2E]
	var no_chr_raster_writes: Array[Dictionary] = []
	var pair_ok := screen.set_source_mmc3_chr_writes(initial_chr_selectors,
		no_chr_raster_writes)
	if not pair_ok:
		screen.end_state_update()
		return _fail("PPU renderer rejected the ROM $70/$56 CHR selector pair.")
	# Background animation $70 enters ROM handler $83D2, whose $8386 continuation
	# calls $84A1 with A=$A0. That path selects PPUCTRL nametable page 2 and
	# scroll Y=$74; the fixed NMI writes those shadows to $2000/$2005. Keep this
	# source state local to the gameplay field candidate rather than changing the
	# opening renderer's generic background-$01 defaults.
	screen.set_source_raster_events([{
		"kind": "scroll",
		"scanline": 0,
		"scroll_x": 0x00,
		"control_nametable_bit": 0,
		"ppuctrl_nametable_bit_observed": 0,
		# The handler owns only PPUCTRL nametable bits 0–1; other control bits
		# retain their independent runtime state and are not copied from a dump.
		"control_value": 0x02,
		"scroll_y_base": 0x74,
		"source_pc": "$70 → $83D2/$8386/$8393 → $84A1(A=$A0), NMI $C7AF",
	}, {
		"kind": "ppu_address",
		"scanline": 124,
		"address": 0x2200,
		"source_pc": "FCEUX NewPPU same-input frame 8953: IRQ $C821/$C852, $2006=$22/$00 at line 124 dots 274/292",
	}, {
		"kind": "scroll",
		"scanline": 125,
		"scroll_x": 0x00,
		"control_nametable_bit": 0,
		"source_pc": "FCEUX NewPPU same-input frame 8953: $2000=$8A at line 124 dot 320; $2005=$00/$00 at line 125 dots 8/20",
	}])
	screen.set_ppu_memory(ppu_memory)
	screen.end_state_update()

	status = {
		"ok": true,
		"background_id": "0x01 (candidate; full active map selection unproven)",
		"palette_id": "0x02",
		"background_packets": 320,
		"field_maps": field_map_result.get("maps", []),
		"residual_packet_producer": packet_status,
		"ppu_tile_origin": "0x2800 / 0x2A00",
		"ppu_attribute_origins": "0x2BC0 / 0x2BE0",
		"chr_pair_selectors": [0x3C, 0x2E],
		"chr_pair_applied_as_static_profile": true,
		"viewport_source": {
			"nametable_select_bits": 0x02,
			"scroll_x": 0x00,
			"scroll_y": 0x74,
			"source": "$70 opcode $06 → $83D2 → $8386 → $84A1(A=$A0); NMI $C7AF",
		},
		"irq_viewport_source": {
			"ppu_address": 0x2200,
			"fceux_newppu_irq_line": 123,
			"fceux_newppu_address_write_line_dot": [124, 274],
			"fceux_newppu_scroll_write_line_dots": [[125, 8], [125, 20]],
			"renderer_application": "line-level approximation; exact first affected pixel unresolved",
		},
		"gaps": [
			"Background $01 is a ROM-backed field candidate; its complete active loader, map transform, and attribute history are not established.",
			"The frame-8953 IRQ reload and scroll reset are now represented at FCEUX NewPPU line granularity; first affected pixel and physical 2C02 timing remain unresolved. The $70/$56 CHR pair is still applied statically.",
			"The bank-$1F $F015/$F114 decoder derives $063D from source $0621/$0600 and $05CE from source $05CD, but the production route does not yet deliver a decoded $8327 callback state.",
			"The separate $F0B5 holder tile requires source-derived active-holder coordinates ($0635/$0637) plus $05CE; it is not inferred from endpoint RAM/PPU data.",
			"The endpoint viewport is sourced from the $70/$A0 ROM path; later gameplay scroll/raster changes and per-fetch timing remain untraced.",
			"ROM actor descriptor streams and a frozen $44/$5C endpoint pose are decoded by FirstCommandActorSourcePresenter and GameplayRomActorOamBuilder, but they are not wired here because route-time actor state, committed $0517 mirror state, and render cadence are not supplied; no actor sprites are drawn.",
		],
	}
	return true


func _append_background_01_candidate(ppu_memory: Dictionary) -> bool:
	var layout := _read_json(BG01_LAYOUT_PATH)
	if layout.is_empty() or str(layout.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("Background-$01 layout is missing or belongs to another ROM revision.")
	var loader: RomBackgroundPacketLoader = BACKGROUND_PACKET_LOADER.new()
	if not loader.build_packets(0x01, BG01_DATA_ROOT):
		return _fail("ROM background-$01 row/block producer failed: %s" % loader.last_error)
	for packet in loader.packets:
		var address := int(packet.get("ppu_address", -1))
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		if address < 0 or payload.is_empty():
			return _fail("Background-$01 producer emitted a malformed PPU packet.")
		for byte_index in payload.size():
			ppu_memory[address + byte_index] = int(payload[byte_index])
	return true


func _append_source_field_maps(ppu_memory: Dictionary) -> Dictionary:
	var manifest := _read_json(PAGE_CORRECT_MANIFEST_PATH)
	if manifest.is_empty() or str(manifest.get("schema", "")) != \
			"first-command-page-correct-field-map-sources-v1" or \
			str(manifest.get("rom_sha256", "")) != SOURCE_ROM_SHA256:
		_fail("Selector-correct first-command field source manifest is missing or targets another ROM.")
		return {"ok": false}
	var entries_by_path: Dictionary = {}
	for raw_entry in manifest.get("entries", []):
		if not raw_entry is Dictionary:
			continue
		var entry: Dictionary = raw_entry
		entries_by_path[str(entry.get("path", ""))] = entry
	var selector_table := _read_manifest_source(entries_by_path,
		"packed_map_selectors_8B42.bin", 0x22, 0x016B52)
	if selector_table.size() != 0x22:
		return {"ok": false}

	var map_write_batches: Array[Dictionary] = []
	var map_status: Array[Dictionary] = []
	for map_spec_variant in FIELD_MAPS:
		var map_spec: Dictionary = map_spec_variant
		var map_id := int(map_spec["map_id"])
		var animation_id := int(map_spec["animation_id"])
		var selector := int(map_spec["selector"])
		var animation_name := "background_animation_%02X_record.bin" % animation_id
		var animation_entry: Dictionary = entries_by_path.get(animation_name, {})
		var animation_data := _read_manifest_source(entries_by_path, animation_name, 3,
			int(map_spec["animation_file_offset"]))
		if animation_data != _parse_hex_bytes(str(map_spec["animation_hex"])):
			_fail("ROM background animation $%02X record does not match its decoded map ID." % animation_id)
			return {"ok": false}

		var selector_value := (int(selector_table[map_id >> 2]) >> (2 * (map_id & 3))) & 0x03
		if selector_value != selector:
			_fail("ROM selector table resolves map $%02X to $%02X, expected $%02X." % [map_id, selector_value, selector])
			return {"ok": false}
		var map_name := "block_map_%02X_selector_%02X.bin" % [map_id, selector]
		var map_entry: Dictionary = entries_by_path.get(map_name, {})
		var map_data := _read_manifest_source(entries_by_path, map_name, 0x20,
			int(map_spec["map_file_offset"]))
		if map_data != _parse_hex_bytes(str(map_spec["map_hex"])):
			_fail("ROM block map $%02X differs from the byte-checked source map." % map_id)
			return {"ok": false}
		if _parse_hex_byte(str(map_entry.get("block_map_id", ""))) != map_id or \
				_parse_hex_byte(str(map_entry.get("selector", ""))) != selector:
			_fail("ROM map manifest metadata does not match map $%02X selector $%02X." % [map_id, selector])
			return {"ok": false}

		var tile_rows: Array[PackedByteArray] = []
		var attribute_bytes := PackedByteArray()
		for block_row in 4:
			for tile_row in 4:
				tile_rows.append(PackedByteArray())
			for block_column in 8:
				var metatile_id := int(map_data[block_row * 8 + block_column])
				var tile_name := "map_%02X_metatile_%02X_tiles.bin" % [map_id, metatile_id]
				var tile_entry: Dictionary = entries_by_path.get(tile_name, {})
				var tile_data := _read_manifest_source(entries_by_path, tile_name, 0x10, _manifest_offset(tile_entry))
				if tile_data.size() != 0x10 or not _validate_metatile_entry(tile_entry, map_id, selector, metatile_id, true):
					return {"ok": false}
				for tile_row in 4:
					var row: PackedByteArray = tile_rows[block_row * 4 + tile_row]
					for tile_column in 4:
						row.append(int(tile_data[tile_row * 4 + tile_column]))
					tile_rows[block_row * 4 + tile_row] = row
				var attribute_name := "map_%02X_metatile_%02X_attribute.bin" % [map_id, metatile_id]
				var attribute_entry: Dictionary = entries_by_path.get(attribute_name, {})
				var attribute_data := _read_manifest_source(entries_by_path, attribute_name, 1, _manifest_offset(attribute_entry))
				if attribute_data.size() != 1 or not _validate_metatile_entry(attribute_entry, map_id, selector, metatile_id, false):
					return {"ok": false}
				attribute_bytes.append(int(attribute_data[0]))

		for tile_row_index in 16:
			var tile_row_payload := tile_rows[tile_row_index]
			if tile_row_payload.size() != 32:
				_fail("ROM block-$%02X row %d did not expand to 32 tile IDs." % [map_id, tile_row_index])
				return {"ok": false}
		for attribute_row in 4:
			var start := attribute_row * 8
			if attribute_bytes.slice(start, start + 8).size() != 8:
				_fail("ROM block-$%02X attribute row %d did not expand to eight bytes." % [map_id, attribute_row])
				return {"ok": false}
		map_write_batches.append({
			"map_id": map_id,
			"tile_origin": int(map_spec["tile_origin"]),
			"attribute_origin": int(map_spec["attribute_origin"]),
			"tile_rows": tile_rows,
			"attribute_bytes": attribute_bytes,
		})
		map_status.append({
			"animation_id": "0x%02X" % animation_id,
			"map_id": "0x%02X" % map_id,
			"selector": "0x%02X" % selector,
			"tile_origin": "0x%04X" % int(map_spec["tile_origin"]),
			"attribute_origin": "0x%04X" % int(map_spec["attribute_origin"]),
			"source_tiles": 512,
		})

	# Expand both layers first, then write the separately decoded attribute planes.
	# The tile packets extend into nametable tail rows; these are outside visible
	# rows 0-29 and the source attribute writes own $2BC0-$2BFF.
	for batch in map_write_batches:
		var origin := int(batch["tile_origin"])
		var rows: Array = batch["tile_rows"]
		for row_index in 16:
			var payload: PackedByteArray = rows[row_index]
			for column in 32:
				ppu_memory[origin + row_index * 0x20 + column] = int(payload[column])
	for batch in map_write_batches:
		var origin := int(batch["attribute_origin"])
		var attributes: PackedByteArray = batch["attribute_bytes"]
		for offset in attributes.size():
			ppu_memory[origin + offset] = int(attributes[offset])
	return {"ok": true, "maps": map_status}


func _append_source_packet_layer(source_packet_context: Dictionary) -> Dictionary:
	var source_inputs := _resolve_source_packet_inputs(source_packet_context)
	if not bool(source_inputs.get("ok", false)):
		return {
			"applied": false,
			"status": str(source_inputs.get("status", "awaiting_route_source_state")),
			"required_inputs": source_inputs.get("required_inputs", []),
			"error": str(source_inputs.get("error", "")),
		}
	var producer: RefCounted = FIELD_PACKET_PRODUCER.new()
	var descriptor_id := int(source_inputs["descriptor_id"])
	var placement_05ce := int(source_inputs["placement_05ce"])
	var packet_result: Dictionary = producer.call("build_f015_packets", descriptor_id, placement_05ce)
	if not bool(packet_result.get("ok", false)):
		last_error = str(packet_result.get("error", producer.get("last_error")))
		return {"applied": false, "status": "source_packet_build_failed", "error": last_error}
	if not bool(producer.call("apply_packets", ppu_memory, packet_result)):
		last_error = "The F015 source packet set could not be applied to the candidate PPU memory."
		return {"applied": false, "status": "source_packet_apply_failed", "error": last_error}
	var holder_status := "awaiting_source_holder_coordinates"
	if source_packet_context.has("holder_x_0635") and source_packet_context.has("holder_y_0637"):
		var holder_result: Dictionary = producer.call("build_f0b5_holder_packet",
			descriptor_id,
			placement_05ce,
			int(source_packet_context["holder_x_0635"]),
			int(source_packet_context["holder_y_0637"]))
		if not bool(holder_result.get("ok", false)):
			last_error = str(holder_result.get("error", producer.get("last_error")))
			return {"applied": false, "status": "holder_packet_build_failed", "error": last_error}
		var holder_packet: Dictionary = holder_result["packet"]
		var holder_address := int(holder_packet["address"])
		var holder_payload: Array = holder_packet["payload"]
		for index in holder_payload.size():
			ppu_memory[holder_address + index] = int(holder_payload[index])
		holder_status = "applied_from_source_coordinates"
	return {
		"applied": true,
		"status": "rom_source_packets_applied",
		"descriptor_id": descriptor_id,
		"placement_05ce": placement_05ce,
		"source_derivation": source_inputs.get("derivation", {}),
		"tile_write_count": int(packet_result.get("tile_write_count", 0)),
		"attribute_write_count": int(packet_result.get("attribute_write_count", 0)),
		"holder_overlay": holder_status,
	}


## Derive the F015 inputs from explicit source-state variables. A caller must
## only pass these values at a decoded $8327 callback; endpoint RAM/PPU values
## and pre-resolved descriptor/placement constants are not accepted here.
func _resolve_source_packet_inputs(source_state: Dictionary) -> Dictionary:
	var required := [
		"menu_context_0621",
		"defender_count_0600",
		"previous_05cd",
		"callback_handler_pc",
	]
	for key_variant in required:
		if not source_state.has(key_variant):
			return {
				"ok": false,
				"status": "awaiting_route_source_state",
				"required_inputs": required,
			}
	if int(source_state["callback_handler_pc"]) != 0x8327:
		return {
			"ok": false,
			"status": "not_at_field_map_callback",
			"error": "F015 source state may only be consumed at the decoded bank-$0B $8327 callback.",
		}

	var callback_api: RefCounted = CALLBACK_DISPATCH_API.new()
	var callback_result: Dictionary = callback_api.call("resolve_scenario_44_callback")
	if not bool(callback_result.get("ok", false)):
		return {"ok": false, "status": "callback_source_failed", "error": str(callback_result.get("error", ""))}
	var callback_command: Dictionary = callback_result.get("first_callback_command", {})
	if int(callback_command.get("handler_cpu", -1)) != 0x8327:
		return {"ok": false, "status": "unexpected_callback_handler", "error": "ROM scenario $44 no longer resolves to handler $8327."}

	var descriptor_resolver: RefCounted = FIELD_DESCRIPTOR_RESOLVER.new()
	if not bool(descriptor_resolver.call("configure")):
		return {"ok": false, "status": "descriptor_source_failed", "error": str(descriptor_resolver.get("error_message"))}
	var descriptor_result: Dictionary = descriptor_resolver.call("resolve_descriptor",
		int(source_state["menu_context_0621"]), int(source_state["defender_count_0600"]))
	if not bool(descriptor_result.get("ok", false)):
		return {"ok": false, "status": "descriptor_state_failed", "error": str(descriptor_result.get("error", ""))}

	var producer: RefCounted = FIELD_PACKET_PRODUCER.new()
	var placement_result: Dictionary = producer.call("advance_map_placement_state",
		int(source_state["previous_05cd"]))
	if not bool(placement_result.get("ok", false)):
		return {"ok": false, "status": "placement_state_failed", "error": str(placement_result.get("error", producer.get("last_error")))}
	return {
		"ok": true,
		"descriptor_id": int(descriptor_result["descriptor_id"]),
		"placement_05ce": int(placement_result["written_05ce"]),
		"derivation": {
			"descriptor_source_pc": "$EFFC/$EFF9/$F00F-$F012",
			"descriptor_menu_context_0621": int(source_state["menu_context_0621"]),
			"descriptor_defender_count_0600": int(source_state["defender_count_0600"]),
			"placement_source_pc": "$8327/$8342-$8349",
			"placement_previous_05cd": int(source_state["previous_05cd"]),
			"callback_handler_pc": "$8327",
			"callback_source_record": callback_command.get("source_record", PackedByteArray()),
		},
	}


func _read_manifest_source(entries_by_path: Dictionary, file_name: String,
		expected_size: int, file_offset: int) -> PackedByteArray:
	var entry: Dictionary = entries_by_path.get(file_name, {})
	if entry.is_empty() or int(entry.get("size_bytes", -1)) != expected_size or \
			_manifest_offset(entry) != file_offset:
		_fail("ROM source manifest has no valid range record for %s." % file_name)
		return PackedByteArray()
	var resource_path := PAGE_CORRECT_DATA_ROOT + "/" + file_name
	if not FileAccess.file_exists(resource_path):
		_fail("ROM-derived selector-correct field bytes are missing: %s" % resource_path)
		return PackedByteArray()
	var data := FileAccess.get_file_as_bytes(resource_path)
	if data.size() != expected_size or FileAccess.get_sha256(resource_path) != str(entry.get("sha256", "")):
		_fail("ROM-derived field source failed size/hash validation: %s" % file_name)
		return PackedByteArray()
	return data


func _validate_metatile_entry(entry: Dictionary, map_id: int, selector: int,
		metatile_id: int, tile_record: bool) -> bool:
	if entry.is_empty() or _parse_hex_byte(str(entry.get("block_map_id", ""))) != map_id or \
			_parse_hex_byte(str(entry.get("selector", ""))) != selector or \
			_parse_hex_byte(str(entry.get("metatile_id", ""))) != metatile_id:
		_fail("ROM manifest metatile metadata does not match map $%02X selector $%02X ID $%02X." % [map_id, selector, metatile_id])
		return false
	var expected_offset := 0x024010 + (selector << 12) + (metatile_id << 4) if tile_record else \
		0x017BF4 + (selector << 8) + metatile_id
	if _manifest_offset(entry) != expected_offset:
		_fail("ROM manifest metatile file offset is inconsistent with the selector formula.")
		return false
	return true


func _manifest_offset(entry: Dictionary) -> int:
	var value := str(entry.get("file_offset", ""))
	return value.trim_prefix("0x").hex_to_int() if value.begins_with("0x") else -1


func _validate_route_manifest(manifest: Dictionary) -> bool:
	var rom_metadata: Dictionary = manifest.get("rom", {})
	if str(rom_metadata.get("sha256", "")) != SOURCE_ROM_SHA256:
		return _fail("Animation-$70 manifest ROM SHA-256 does not match the supplied revision.")
	var route: Dictionary = manifest.get("selection_route", {})
	if str(route.get("event_bytes", "")).to_lower() != "02 70 5c f0":
		return _fail("Fresh-match scenario does not select animation $70 from the byte-checked event.")
	if str(route.get("background_animation_record_header_hex", "")).to_lower() != "06 00 56 02 00":
		return _fail("Animation-$70 record header does not select block $56.")
	var pair: Dictionary = manifest.get("chr_pair", {})
	var selectors: Array = pair.get("selectors", [])
	if selectors.size() != 2 or _parse_hex_byte(str(selectors[0])) != 0x3C \
			or _parse_hex_byte(str(selectors[1])) != 0x2E:
		return _fail("ROM pair-table entry $56 does not resolve to selectors $3C/$2E.")
	var block: Dictionary = manifest.get("decoded_block", {})
	if str(block.get("block_map_raw_hex", "")).to_lower() != \
			"15 16 15 15 1a 16 15 15 ad ad ad ad ad ad ad ad ae ae ae ae ae ae ae ae af af af af af af af af":
		return _fail("Block-$56 map bytes differ from the target-ROM decode.")
	return true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("Missing ROM-derived field manifest: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_fail("Malformed ROM-derived field manifest: %s" % path)
		return {}
	return parsed


func _parse_hex_byte(text: String) -> int:
	var value := text.strip_edges().trim_prefix("0x").trim_prefix("0X")
	if value.is_empty() or not value.is_valid_hex_number(false):
		return -1
	var parsed := value.hex_to_int()
	return parsed if parsed >= 0 and parsed <= 0xFF else -1


func _parse_hex_bytes(text: String) -> PackedByteArray:
	var result := PackedByteArray()
	for token in text.split(" ", false):
		var value := _parse_hex_byte(token)
		if value < 0:
			return PackedByteArray()
		result.append(value)
	return result


func _fail(message: String) -> bool:
	last_error = message
	return false
