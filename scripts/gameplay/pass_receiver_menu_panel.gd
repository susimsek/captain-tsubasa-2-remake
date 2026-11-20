extends RefCounted
class_name PassReceiverMenuPanel
## Builds the ROM-described PASS receiver prompt packets for descriptor $0F.
## It consumes only the extracted ROM descriptor/text and the shared ROM
## window family; callers supply the current PPU memory image.

const LAYOUT_BUILDER := preload("res://scripts/gameplay/first_action_menu_rom_layout.gd")
const DATA_ROOT := "res://reference/rom_extract/gameplay/menus/pass_receiver_menu/"
const MANIFEST_PATH := DATA_ROOT + "manifest.json"
const DESCRIPTOR_PATH := DATA_ROOT + "descriptor_0F.bin"
const SHARED_WINDOW_PATH := "res://reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin"

const EXPECTED_SCHEMA := "ct2-pass-receiver-menu-rom-data-v1"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_DESCRIPTOR_ID := "0x0F"
const EXPECTED_DESCRIPTOR_CPU := "0xB58D"
const EXPECTED_DESCRIPTOR_FILE_OFFSET := "0x03359D"
const EXPECTED_DESCRIPTOR_SIZE := 21
const EXPECTED_DESCRIPTOR_SHA256 := "9e090acd306a92dd42dd00bb2558061e92def0ffe61bbd69732d92be37bd226c"
const EXPECTED_WINDOW_SIZE := 9
const EXPECTED_WINDOW_SHA256 := "dcb1f10d1a9a0fa616fa2e065790ce038722b09968d265e7901770b3bf9133e0"
const EXPECTED_ROW_SPECS := [
	{"resource": "row_00.bin", "size": 1, "sha256": "98722e2ebed8ed3d3652e11e4181f0dccc1ce7d192d8f1db370af8ec4a4e174a"},
	{"resource": "row_01.bin", "size": 7, "sha256": "b6f8de1644d9918dd20f1301c22e67c91a996d85594dabf01f1a288892f7c619"},
	{"resource": "row_02.bin", "size": 1, "sha256": "98722e2ebed8ed3d3652e11e4181f0dccc1ce7d192d8f1db370af8ec4a4e174a"},
]

var packets: Array[Dictionary] = []
var status: Dictionary = {"ok": false, "state": "not_built"}
var error_message := ""


## Load, validate, and build descriptor-$0F transfer packets from ROM bytes.
func rebuild() -> bool:
	packets.clear()
	error_message = ""
	status = {"ok": false, "state": "building"}

	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if manifest_bytes.is_empty():
		return _fail("PASS receiver-menu ROM manifest is missing or empty.")
	var manifest_variant: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if typeof(manifest_variant) != TYPE_DICTIONARY:
		return _fail("PASS receiver-menu ROM manifest is not a JSON object.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != EXPECTED_SCHEMA:
		return _fail("PASS receiver-menu ROM manifest schema is unsupported.")
	if str(manifest.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256:
		return _fail("PASS receiver-menu sources identify a different ROM revision.")

	var descriptor_variant: Variant = manifest.get("descriptor", {})
	if typeof(descriptor_variant) != TYPE_DICTIONARY:
		return _fail("PASS receiver-menu descriptor metadata is malformed.")
	var descriptor_manifest: Dictionary = descriptor_variant
	if str(descriptor_manifest.get("descriptor_id", "")) != EXPECTED_DESCRIPTOR_ID \
			or str(descriptor_manifest.get("descriptor_cpu_address", "")) != EXPECTED_DESCRIPTOR_CPU \
			or str(descriptor_manifest.get("descriptor_file_offset", "")) != EXPECTED_DESCRIPTOR_FILE_OFFSET \
			or int(descriptor_manifest.get("descriptor_length_bytes", -1)) != EXPECTED_DESCRIPTOR_SIZE \
			or str(descriptor_manifest.get("descriptor_sha256", "")) != EXPECTED_DESCRIPTOR_SHA256:
		return _fail("PASS receiver-menu descriptor metadata does not match the pinned ROM span.")

	var descriptor := FileAccess.get_file_as_bytes(DESCRIPTOR_PATH)
	if descriptor.size() != EXPECTED_DESCRIPTOR_SIZE \
			or _sha256(descriptor) != EXPECTED_DESCRIPTOR_SHA256:
		return _fail("PASS receiver-menu descriptor bytes failed size or SHA-256 validation.")
	if str(descriptor_manifest.get("descriptor_raw_hex", "")).replace(" ", "").to_lower() \
			!= descriptor.hex_encode():
		return _fail("PASS receiver-menu manifest byte listing disagrees with descriptor_0F.bin.")
	if int(descriptor[8]) != EXPECTED_ROW_SPECS.size() \
			or int(descriptor_manifest.get("row_record_count", -1)) != EXPECTED_ROW_SPECS.size():
		return _fail("PASS receiver-menu descriptor row count is not the expected three source rows.")
	if int(descriptor_manifest.get("window_width_tiles", -1)) != int(descriptor[2]) \
			or int(descriptor_manifest.get("window_height_tiles", -1)) != int(descriptor[3]):
		return _fail("PASS receiver-menu descriptor dimensions disagree with its source header.")

	var rows_variant: Variant = descriptor_manifest.get("rows", [])
	if typeof(rows_variant) != TYPE_ARRAY or rows_variant.size() != EXPECTED_ROW_SPECS.size():
		return _fail("PASS receiver-menu manifest text-row list is incomplete.")
	var row_streams: Array[PackedByteArray] = []
	for row_index in EXPECTED_ROW_SPECS.size():
		var row_metadata_variant: Variant = rows_variant[row_index]
		if typeof(row_metadata_variant) != TYPE_DICTIONARY:
			return _fail("PASS receiver-menu text-row metadata %d is malformed." % row_index)
		var row_metadata: Dictionary = row_metadata_variant
		var row_spec: Dictionary = EXPECTED_ROW_SPECS[row_index]
		var expected_resource := str(row_spec["resource"])
		if int(row_metadata.get("row_index", -1)) != row_index \
				or str(row_metadata.get("text_resource", "")) != expected_resource \
				or int(row_metadata.get("text_source_length_bytes", -1)) != int(row_spec["size"]) \
				or str(row_metadata.get("text_source_sha256", "")) != str(row_spec["sha256"]):
			return _fail("PASS receiver-menu text-row metadata %d does not match the pinned ROM span." % row_index)
		var row_bytes := FileAccess.get_file_as_bytes(DATA_ROOT + expected_resource)
		if row_bytes.size() != int(row_spec["size"]) \
				or _sha256(row_bytes) != str(row_spec["sha256"]):
			return _fail("PASS receiver-menu text row %d failed size or SHA-256 validation." % row_index)
		if str(row_metadata.get("text_source_bytes_hex", "")).replace(" ", "").to_lower() \
				!= row_bytes.hex_encode():
			return _fail("PASS receiver-menu manifest byte listing disagrees with row_%02d.bin." % row_index)
		row_streams.append(row_bytes)

	var window_family := FileAccess.get_file_as_bytes(SHARED_WINDOW_PATH)
	if window_family.size() != EXPECTED_WINDOW_SIZE \
			or _sha256(window_family) != EXPECTED_WINDOW_SHA256:
		return _fail("Shared ROM-derived menu window family failed size or SHA-256 validation.")

	var built_packets: Array[Dictionary] = LAYOUT_BUILDER.build_packets(
		descriptor,
		window_family,
		row_streams,
		Callable()
	)
	# Descriptor $0F stores a ten-row extent, not an inclusive last-row index.
	# The source PPU trace leaves the following row untouched; retaining that
	# existing row matters because it contains part of the previous panel.
	var expected_packet_count := int(descriptor[3])
	if built_packets.size() < expected_packet_count:
		return _fail("Descriptor-$0F layout builder produced %d of %d progress packets." % [
			built_packets.size(), expected_packet_count,
		])
	built_packets.resize(expected_packet_count)
	for packet in built_packets:
		var missing_dynamic_variant: Variant = packet.get("missing_dynamic", [])
		if not bool(packet.get("complete", false)) \
				or typeof(missing_dynamic_variant) != TYPE_ARRAY \
				or not (missing_dynamic_variant as Array).is_empty():
			return _fail("Descriptor-$0F contains unresolved dynamic menu text.")
	packets = built_packets
	status = {
		"ok": true,
		"state": "ready",
		"rom_sha256": EXPECTED_ROM_SHA256,
		"descriptor_id": 0x0F,
		"descriptor_cpu_address": EXPECTED_DESCRIPTOR_CPU,
		"packet_count": packets.size(),
		"dynamic_rows_missing": [],
	}
	return true


## Return a PPU-memory copy with the ROM-built descriptor-$0F packets applied.
## Invalid/incomplete panel state leaves the caller's PPU memory unchanged.
func apply_to_ppu_memory(ppu_memory: Dictionary) -> Dictionary:
	var updated := ppu_memory.duplicate()
	if not bool(status.get("ok", false)) or packets.is_empty():
		_fail("PASS receiver-menu packets are not ready; call rebuild() successfully first.")
		return updated
	for packet_record in packets:
		var address := int(packet_record.get("ppu_address", -1))
		var tiles_variant: Variant = packet_record.get("tiles", PackedByteArray())
		if address < 0 or not tiles_variant is PackedByteArray:
			_fail("A PASS receiver-menu packet has an invalid PPU address or tile payload.")
			return ppu_memory.duplicate()
		var tiles: PackedByteArray = tiles_variant
		for tile_index in tiles.size():
			updated[address + tile_index] = int(tiles[tile_index])
	status["applied"] = true
	var output_tile_count := 0
	for packet_record in packets:
		var packet_tiles: PackedByteArray = packet_record.get("tiles", PackedByteArray())
		output_tile_count += packet_tiles.size()
	status["output_tile_count"] = output_tile_count
	return updated


func _fail(message: String) -> bool:
	error_message = message
	status = {"ok": false, "state": "error", "error": message}
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK \
			or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
