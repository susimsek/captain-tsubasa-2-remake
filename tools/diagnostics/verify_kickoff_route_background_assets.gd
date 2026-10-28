extends SceneTree

const BACKGROUND_LOADER := preload("res://scripts/opening/rom_background_packet_loader.gd")
const BACKGROUND_RENDERER := preload("res://scripts/opening/rom_ppu_nametable_screen_renderer.gd")
const DATA_ROOT := "res://reference/rom_extract/gameplay/backgrounds"
const EVENT_MANIFESTS := [
	"res://assets/gameplay/rom_logic/kickoff_cutscene_01_events.json",
	"res://assets/gameplay/rom_logic/kickoff_cutscene_02_events.json",
]
const EXPECTED_IDS: Array[int] = [0x02, 0x04, 0x12, 0x13, 0x14, 0x15, 0x19, 0x2D, 0x5C, 0x5D, 0x5E]


func _initialize() -> void:
	var manifest_ids := _manifest_background_ids()
	if manifest_ids != EXPECTED_IDS:
		push_error("Kickoff background ID index differs from the ROM event manifests.")
		quit(1)
		return
	var supported_ids := BACKGROUND_LOADER.get_supported_background_ids(DATA_ROOT)
	for background_id in EXPECTED_IDS:
		if not supported_ids.has(background_id):
			push_error("ROM event manifest background $%02X has no preserved layout source." % background_id)
			quit(1)
			return
		var loader = BACKGROUND_LOADER.new()
		if not loader.build_packets(background_id, DATA_ROOT):
			push_error("Could not rebuild ROM background $%02X: %s" % [background_id, loader.last_error])
			quit(1)
			return
		if loader.packets.is_empty() or loader.payload_byte_count <= 0:
			push_error("ROM background $%02X generated no PPU packets." % background_id)
			quit(1)
			return
	print("Verified %d KICK OFF route backgrounds and ROM-derived packet streams." % EXPECTED_IDS.size())
	quit()


func _manifest_background_ids() -> Array[int]:
	var result: Array[int] = []
	for manifest_path in EVENT_MANIFESTS:
		if not FileAccess.file_exists(manifest_path):
			push_error("Missing ROM-derived cutscene event manifest: %s" % manifest_path)
			return []
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not parsed is Dictionary:
			push_error("Malformed ROM-derived cutscene event manifest: %s" % manifest_path)
			return []
		for event_variant in parsed.get("events", []):
			if not event_variant is Dictionary:
				continue
			var event: Dictionary = event_variant
			if not str(event.get("kind", "")).begins_with("background_"):
				continue
			var background_id := int(event.get("id", -1))
			if background_id < 0 or background_id > 0xFF:
				push_error("ROM-derived cutscene event has an invalid background ID.")
				return []
			if not result.has(background_id):
				result.append(background_id)
	result.sort()
	return result
