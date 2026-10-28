extends SceneTree
## Check whether the ROM-derived background-$01 packet set contains the
## endpoint bytes that differ from the independently decoded $36/$56 maps.
## The endpoint PPU snapshot is used only for this comparison.

const LOADER := preload("res://scripts/opening/rom_background_packet_loader.gd")
const PPU_REFERENCE := "res://reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var loader: RomBackgroundPacketLoader = LOADER.new()
	if not loader.build_packets(0x01, "res://reference/rom_extract/intro"):
		push_error("ROM background-$01 decode failed: " + loader.last_error)
		quit(1)
		return
	var endpoint := FileAccess.get_file_as_bytes(PPU_REFERENCE)
	if endpoint.size() != 0x4000:
		push_error("Frame-8953 PPU validation snapshot is missing or malformed.")
		quit(1)
		return
	var background_memory: Dictionary = {}
	for packet_variant in loader.packets:
		var packet: Dictionary = packet_variant
		var address := int(packet.get("ppu_address", -1))
		var payload: PackedByteArray = packet.get("payload", PackedByteArray())
		for offset in payload.size():
			background_memory[address + offset] = int(payload[offset])
	var matched := 0
	var present := 0
	var locations: Array[String] = []
	for row in range(18, 24):
		for column in range(2, 12):
			var address := 0x2800 + row * 0x20 + column
			if background_memory.has(address):
				present += 1
				if int(background_memory[address]) == int(endpoint[address]):
					matched += 1
				else:
					locations.append("$%04X:$%02X/$%02X" % [address,
						int(background_memory[address]), int(endpoint[address])])
	print("Background-$01 ROM packets cover %d/60 residual cells and match endpoint bytes at %d/60." % [present, matched])
	if not locations.is_empty():
		print("First background-$01 mismatches: ", locations.slice(0, 12))
	quit(0)
