extends SceneTree

const BUILDER_SCRIPT := preload("res://scripts/gameplay/gameplay_rom_actor_oam_builder.gd")
const ENDPOINT_RAM_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/cpu_ram_0000_07ff_frame_008953.bin"
const ACTOR_RECORD_ADDRESSES: Array[int] = [0x0547, 0x055C, 0x0586]
const EXPECTED_SPRITE_COUNTS: Array[int] = [6, 13, 22]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var endpoint_ram := FileAccess.get_file_as_bytes(ENDPOINT_RAM_PATH)
	if endpoint_ram.size() != 0x800:
		_fail("Validation-only endpoint RAM fixture is missing or malformed.")
		return
	var actors: Array[Dictionary] = []
	for record_address in ACTOR_RECORD_ADDRESSES:
		actors.append({
			"record_address": record_address,
			"record_bytes": endpoint_ram.slice(record_address, record_address + 21),
		})
	var initial_oam := PackedByteArray()
	initial_oam.resize(64 * 4)
	initial_oam.fill(0)
	for slot in 64:
		initial_oam[slot * 4] = 0xF8

	var builder = BUILDER_SCRIPT.new()
	var result: Dictionary = builder.build_oam(
		actors,
		int(endpoint_ram[0x0546]),
		int(endpoint_ram[0x0517]),
		int(endpoint_ram[0x0538]),
		int(endpoint_ram[0x0540]),
		int(endpoint_ram[0x0541]),
		initial_oam,
		0
	)
	if not bool(result.get("ok", false)):
		_fail("ROM actor OAM builder failed: " + str(result.get("error", builder.last_error)))
		return
	if int(result.get("sprites_written", -1)) != 41 or int(result.get("next_oam_byte_index", -1)) != 164:
		_fail("Source parser did not emit the expected 41 sprite slots / 164 OAM bytes.")
		return
	var actor_results: Array = result.get("actors", [])
	if actor_results.size() != EXPECTED_SPRITE_COUNTS.size():
		_fail("ROM draw list did not produce exactly three active actor records.")
		return
	var expected_start_index := 0
	for actor_index in actor_results.size():
		var actor_result: Dictionary = actor_results[actor_index]
		var expected_bytes := EXPECTED_SPRITE_COUNTS[actor_index] * 4
		if int(actor_result.get("start_oam_byte_index", -1)) != expected_start_index \
				or int(actor_result.get("next_oam_byte_index", -1)) != expected_start_index + expected_bytes \
				or int(actor_result.get("sprites_written", -1)) != EXPECTED_SPRITE_COUNTS[actor_index]:
			_fail("Actor %d produced an incorrect source OAM range." % actor_index)
			return
		expected_start_index += expected_bytes

	var generated_oam: PackedByteArray = result["oam_bytes"]
	var captured_oam := endpoint_ram.slice(0x0200, 0x0300)
	var matching_bytes := 0
	for byte_index in 164:
		if generated_oam[byte_index] != captured_oam[byte_index]:
			_fail("Source-generated OAM differs at shadow byte $%02X: got $%02X expected $%02X." % [byte_index, generated_oam[byte_index], captured_oam[byte_index]])
			return
		matching_bytes += 1
	print("PASS: ROM actor descriptors generated 41 sprites (164/164 OAM bytes matched); selectors, origins, flips, and X/Y tables are source-backed.")
	print("LIMIT: actor records were supplied from the frame-8953 validation snapshot; route-time actor-state/animation production and the complete pitch/raster are still open.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
