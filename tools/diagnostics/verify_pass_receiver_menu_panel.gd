extends SceneTree

const PANEL_SCRIPT := preload("res://scripts/gameplay/pass_receiver_menu_panel.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Usage: --script verify_pass_receiver_menu_panel.gd -- <pre-menu-ppu.bin> <receiver-menu-ppu.bin>")
		quit(2)
		return
	var before := FileAccess.get_file_as_bytes(args[0])
	var expected := FileAccess.get_file_as_bytes(args[1])
	if before.size() != 0x4000 or expected.size() != 0x4000:
		push_error("Both FCEUX PPU validation inputs must contain exactly 16 KiB.")
		quit(2)
		return
	var panel = PANEL_SCRIPT.new()
	if not panel.rebuild():
		push_error("PASS receiver panel source validation failed: " + panel.error_message)
		quit(1)
		return
	var ppu_memory: Dictionary = {}
	for address in before.size():
		ppu_memory[address] = int(before[address])
	var applied: Dictionary = panel.apply_to_ppu_memory(ppu_memory)
	var compared := 0
	var differing := 0
	var first_difference := -1
	for packet_variant in panel.packets:
		var packet: Dictionary = packet_variant
		var address := int(packet.get("ppu_address", -1))
		var tiles: PackedByteArray = packet.get("tiles", PackedByteArray())
		for tile_index in tiles.size():
			var ppu_address := address + tile_index
			compared += 1
			if int(applied.get(ppu_address, -1)) != int(expected[ppu_address]):
				differing += 1
				if first_difference < 0:
					first_difference = ppu_address
	if differing > 0:
		push_error("PASS descriptor-$0F packet region differs at %d/%d bytes; first PPU address $%04X." % [
			differing, compared, first_difference,
		])
		quit(1)
		return
	print("PASS descriptor-$0F packet region matches same-ROM FCEUX PPU validation: %d/%d bytes." % [compared, compared])
	quit(0)
