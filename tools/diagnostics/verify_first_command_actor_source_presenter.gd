extends SceneTree
## Capture-only parity check for FirstCommandActorSourcePresenter.
## The presenter itself reads only hash-checked ROM-derived source resources.
## This diagnostic opens captured OAM/PPU memory only as expected-value data.

const PRESENTER_SCRIPT := preload("res://scripts/gameplay/first_command_actor_source_presenter.gd")
const ENDPOINT_RAM_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/cpu_ram_0000_07ff_frame_008953.bin"
const ENDPOINT_PPU_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/ppu_memory_frame_008953.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var presenter: Variant = PRESENTER_SCRIPT.new()
	root.add_child(presenter)
	await process_frame
	if not presenter.configure_endpoint_pose(0x08, 0x08, 0x40, 0x0F):
		_fail("Source presenter setup failed: " + presenter.last_error)
		return
	if presenter.last_sprite_chr_banks != [0x08, 0x09, 0x0A, 0x0B]:
		_fail("Source F4 packet did not produce the audited sprite CHR banks.")
		return
	var endpoint_ppu := FileAccess.get_file_as_bytes(ENDPOINT_PPU_PATH)
	if endpoint_ppu.size() < 0x3F20:
		_fail("Diagnostic endpoint PPU-memory snapshot is missing or truncated.")
		return
	var expected_palette := endpoint_ppu.slice(0x3F10, 0x3F20)
	if presenter.last_sprite_palette != expected_palette:
		_fail("ROM normal-player palette writer output differs from the frame-8953 PPU palette bytes.")
		return
	if int(presenter.last_build_result.get("sprites_written", -1)) != 41:
		_fail("ROM actor descriptors did not produce the 41-sprite endpoint pose.")
		return
	var endpoint_ram := FileAccess.get_file_as_bytes(ENDPOINT_RAM_PATH)
	if endpoint_ram.size() < 0x2A4:
		_fail("Diagnostic endpoint RAM snapshot is missing or truncated.")
		return
	var expected_oam := endpoint_ram.slice(0x200, 0x2A4)
	var generated_oam: PackedByteArray = presenter.last_oam_bytes.slice(0, 0xA4)
	if expected_oam != generated_oam:
		var first_difference := -1
		for index in expected_oam.size():
			if expected_oam[index] != generated_oam[index]:
				first_difference = index
				break
		_fail("Source-generated OAM differs from frame-8953 capture at byte %d: expected $%02X, got $%02X." % [
			first_difference,
			expected_oam[first_difference],
			generated_oam[first_difference],
		])
		return
	print("PASS: ROM-built actor records and descriptors generated 41 sprites; first 164 OAM bytes and all 16 sprite-palette bytes match the frame-8953 diagnostics. CHR bank selectors match the byte-checked endpoint values.")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
