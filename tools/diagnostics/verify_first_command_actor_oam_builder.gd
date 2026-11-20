extends SceneTree

const BUILDER_SCRIPT := preload("res://scripts/gameplay/gameplay_rom_actor_oam_builder.gd")
const ENDPOINT_RAM_PATH := "res://reference/diagnostics/first_command_actor_oam_20261027_113609_utc/cpu_ram_0000_07ff_frame_008953.bin"
const FRAME_8678_RAM_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008678.bin"
const FRAME_8683_RAM_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008683.bin"
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
	var route_actor := PackedByteArray()
	route_actor.resize(21)
	route_actor.fill(0)
	route_actor[0] = 0x80
	route_actor[8] = 0xE4
	route_actor[12] = 0xE4
	route_actor[0x12] = 0x7D
	var route_oam := PackedByteArray()
	route_oam.resize(64 * 4)
	route_oam.fill(0xF8)
	var route_result: Dictionary = builder.build_oam(
		[{"record_address": "frame-8663", "record_bytes": route_actor}],
		0x05, 0, 0, 0, 0xF0, route_oam, 0
	)
	if not bool(route_result.get("ok", false)):
		_fail("Frame-8663 descriptor-$7D OAM decode failed: " + str(route_result.get("error", builder.last_error)))
		return
	var route_actor_results: Array = route_result.get("actors", [])
	if route_actor_results.size() != 1 \
			or int(route_actor_results[0].get("descriptor_pointer", -1)) != 0xAA83 \
			or route_actor_results[0].get("selected_stream_roots", []) != [0xAA83] \
			or int(route_result.get("sprites_written", -1)) != 1 \
			or int((route_result["oam_bytes"] as PackedByteArray)[1]) != 0x6F:
		_fail("Frame-8663 descriptor $7D did not decode ROM pointer $AA83 and tile $6F.")
		return
	route_actor[0x12] = 0x7B
	var frame_8673_oam := PackedByteArray()
	frame_8673_oam.resize(64 * 4)
	frame_8673_oam.fill(0xF8)
	var frame_8673_result: Dictionary = builder.build_oam(
		[{"record_address": "frame-8673", "record_bytes": route_actor}],
		0x05, 0, 0, 0, 0xF0, frame_8673_oam, 0
	)
	if not bool(frame_8673_result.get("ok", false)):
		_fail("Frame-8673 descriptor-$7B OAM decode failed: " + str(frame_8673_result.get("error", builder.last_error)))
		return
	var frame_8673_actors: Array = frame_8673_result.get("actors", [])
	if frame_8673_actors.size() != 1 \
			or int(frame_8673_actors[0].get("descriptor_pointer", -1)) != 0xAA79 \
			or frame_8673_actors[0].get("selected_stream_roots", []) != [0xAA79] \
			or int(frame_8673_result.get("sprites_written", -1)) != 1 \
			or int((frame_8673_result["oam_bytes"] as PackedByteArray)[1]) != 0x67:
		_fail("Frame-8673 descriptor $7B did not decode ROM pointer $AA79 and tile $67.")
		return
	var frame_8678_ram := FileAccess.get_file_as_bytes(FRAME_8678_RAM_PATH)
	if frame_8678_ram.size() != 0x800 or int(frame_8678_ram[0x0547 + 0x12]) != 0x7A:
		_fail("The frame-8678 FCEUX actor record is missing or does not select descriptor $7A.")
		return
	var frame_8678_oam := PackedByteArray()
	frame_8678_oam.resize(64 * 4)
	frame_8678_oam.fill(0xF8)
	var frame_8678_result: Dictionary = builder.build_oam(
		[{
			"record_address": 0x0547,
			"record_bytes": frame_8678_ram.slice(0x0547, 0x0547 + 21),
		}],
		int(frame_8678_ram[0x0546]), int(frame_8678_ram[0x0517]),
		int(frame_8678_ram[0x0538]), int(frame_8678_ram[0x0540]),
		int(frame_8678_ram[0x0541]), frame_8678_oam, 0
	)
	if not bool(frame_8678_result.get("ok", false)):
		_fail("Frame-8678 descriptor-$7A OAM decode failed: " + str(frame_8678_result.get("error", builder.last_error)))
		return
	var frame_8678_actors: Array = frame_8678_result.get("actors", [])
	var frame_8678_generated: PackedByteArray = frame_8678_result.get("oam_bytes", PackedByteArray())
	var frame_8678_expected_tiles := PackedByteArray([0x3C, 0x55, 0x3E, 0x3F])
	if frame_8678_actors.size() != 1 \
			or int(frame_8678_actors[0].get("descriptor_pointer", -1)) != 0xAA6C \
			or frame_8678_actors[0].get("selected_stream_roots", []) != [0xAA6C] \
			or int(frame_8678_result.get("sprites_written", -1)) != 4 \
			or frame_8678_generated.size() != 64 * 4:
		_fail("Frame-8678 descriptor $7A did not resolve through ROM pointer $8374->$AA6C into four sprites.")
		return
	for sprite_index in frame_8678_expected_tiles.size():
		if int(frame_8678_generated[sprite_index * 4 + 1]) != int(frame_8678_expected_tiles[sprite_index]):
			_fail("Frame-8678 descriptor $7A generated the wrong ROM tile for sprite %d." % sprite_index)
			return
	var frame_8683_ram := FileAccess.get_file_as_bytes(FRAME_8683_RAM_PATH)
	if frame_8683_ram.size() != 0x800 or int(frame_8683_ram[0x0547 + 0x12]) != 0x79:
		_fail("The frame-8683 FCEUX actor record is missing or does not select descriptor $79.")
		return
	var frame_8683_oam := PackedByteArray()
	frame_8683_oam.resize(64 * 4)
	frame_8683_oam.fill(0xF8)
	var frame_8683_result: Dictionary = builder.build_oam(
		[{
			"record_address": 0x0547,
			"record_bytes": frame_8683_ram.slice(0x0547, 0x0547 + 21),
		}],
		int(frame_8683_ram[0x0546]), int(frame_8683_ram[0x0517]),
		int(frame_8683_ram[0x0538]), int(frame_8683_ram[0x0540]),
		int(frame_8683_ram[0x0541]), frame_8683_oam, 0
	)
	if not bool(frame_8683_result.get("ok", false)):
		_fail("Frame-8683 descriptor-$79 OAM decode failed: " + str(frame_8683_result.get("error", builder.last_error)))
		return
	var frame_8683_actors: Array = frame_8683_result.get("actors", [])
	var frame_8683_generated: PackedByteArray = frame_8683_result.get("oam_bytes", PackedByteArray())
	var frame_8683_expected_tiles := PackedByteArray([0x51, 0x54, 0x52, 0x53])
	if frame_8683_actors.size() != 1 \
			or int(frame_8683_actors[0].get("descriptor_pointer", -1)) != 0xAA5F \
			or frame_8683_actors[0].get("selected_stream_roots", []) != [0xAA5F] \
			or int(frame_8683_result.get("sprites_written", -1)) != 4 \
			or frame_8683_generated.size() != 64 * 4:
		_fail("Frame-8683 descriptor $79 did not resolve through ROM pointer $8372->$AA5F into four sprites.")
		return
	for sprite_index in frame_8683_expected_tiles.size():
		if int(frame_8683_generated[sprite_index * 4 + 1]) != int(frame_8683_expected_tiles[sprite_index]):
			_fail("Frame-8683 descriptor $79 generated the wrong ROM tile for sprite %d." % sprite_index)
			return
	# Validation-only FCEUX actor record at source frame 8664; this snapshot is
	# never consumed by the runtime renderer.
	var frame_8664_actor := PackedByteArray([
		0xA0, 0x98, 0xA6, 0x84, 0xAF, 0xDA, 0xD0, 0xFF, 0xAE, 0xED, 0x68,
		0xFF, 0xD2, 0x00, 0x00, 0x00, 0xFF, 0x35, 0x9F, 0x00, 0x00,
	])
	var descriptor_9f_oam := PackedByteArray()
	descriptor_9f_oam.resize(64 * 4)
	descriptor_9f_oam.fill(0xF8)
	var descriptor_9f_result: Dictionary = builder.build_oam(
		[{"record_address": 0x055C, "record_bytes": frame_8664_actor}],
		0x02, 0x40, 0, 0, 0xF0, descriptor_9f_oam, 4
	)
	if not bool(descriptor_9f_result.get("ok", false)):
		_fail("Frame-8664 descriptor-$9F OAM decode failed: " + str(descriptor_9f_result.get("error", builder.last_error)))
		return
	var descriptor_9f_actor_results: Array = descriptor_9f_result.get("actors", [])
	var descriptor_9f_generated: PackedByteArray = descriptor_9f_result["oam_bytes"]
	var frame_8664_first_three_sprites := PackedByteArray([
		0x4A, 0x95, 0x01, 0xCE, 0x52, 0x96, 0x03, 0xC6, 0x52, 0x97, 0x01, 0xCE,
	])
	if descriptor_9f_actor_results.size() != 1 \
			or int(descriptor_9f_actor_results[0].get("descriptor_pointer", -1)) != 0xB2CC \
			or descriptor_9f_actor_results[0].get("selected_stream_roots", []) != [0xB2CC, 0xB22A, 0xB287, 0xB24B] \
			or int(descriptor_9f_result.get("sprites_written", -1)) != 18 \
			or descriptor_9f_generated.slice(4, 16) != frame_8664_first_three_sprites:
		_fail("Frame-8664 descriptor $9F did not follow its ROM pointer/shared selector path or match the captured first three OAM sprites.")
		return
	# Validation-only actor from the same-ROM PASS route at FCEUX frame 9477.
	# Runtime receives this state through the ROM-derived task/actor route instead.
	var frame_9477_descriptor_cf_actor := PackedByteArray([
		0x81, 0x90, 0xA3, 0x0A, 0xB3, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00,
		0x00, 0xBB, 0x00, 0x00, 0x00, 0xFF, 0x01, 0xCF, 0x00, 0x00,
	])
	var descriptor_cf_oam := PackedByteArray()
	descriptor_cf_oam.resize(64 * 4)
	descriptor_cf_oam.fill(0xF8)
	var descriptor_cf_result: Dictionary = builder.build_oam(
		[{"record_address": 0x0547, "record_bytes": frame_9477_descriptor_cf_actor}],
		0x08, 0x00, 0x00, 0x00, 0xF0, descriptor_cf_oam, 0
	)
	if not bool(descriptor_cf_result.get("ok", false)):
		_fail("Frame-9477 descriptor-$CF OAM decode failed: " + str(descriptor_cf_result.get("error", builder.last_error)))
		return
	var descriptor_cf_actor_results: Array = descriptor_cf_result.get("actors", [])
	var descriptor_cf_generated: PackedByteArray = descriptor_cf_result.get("oam_bytes", PackedByteArray())
	var frame_9477_descriptor_cf_tiles := PackedByteArray([
		0x1B, 0x2A, 0x2B, 0x29, 0x12, 0x03, 0x08, 0x09, 0x02,
		0x0C, 0x0E, 0x0A, 0x0F, 0x0B, 0x20, 0x21, 0x22, 0x28,
	])
	if descriptor_cf_actor_results.size() != 1 \
			or int(descriptor_cf_actor_results[0].get("descriptor_pointer", -1)) != 0xBE2D \
			or descriptor_cf_actor_results[0].get("selected_stream_roots", []) != [0xBE2D, 0xBE9F, 0xBE56] \
			or int(descriptor_cf_result.get("sprites_written", -1)) != frame_9477_descriptor_cf_tiles.size():
		_fail("Frame-9477 descriptor $CF did not resolve ROM selector $08 through $BE2D->$BE9F->$BE56 into 18 sprites.")
		return
	for sprite_index in frame_9477_descriptor_cf_tiles.size():
		if int(descriptor_cf_generated[sprite_index * 4 + 1]) != int(frame_9477_descriptor_cf_tiles[sprite_index]):
			_fail("Frame-9477 descriptor $CF generated the wrong ROM tile for sprite %d." % sprite_index)
			return
	print("PASS: ROM actor descriptors generated 41 sprites (164/164 OAM bytes matched); selectors, origins, flips, and X/Y tables are source-backed.")
	print("PASS: constructed frame-8663 actor descriptor $7D resolved through ROM pointer $AA83 and emitted tile $6F.")
	print("PASS: frame-8673 descriptor $7B resolved through ROM pointer $AA79 and emitted tile $67 from ROM bytes.")
	print("PASS: frame-8678 FCEUX actor record selected descriptor $7A; ROM pointer $8374->$AA6C emitted tiles $3C/$55/$3E/$3F.")
	print("PASS: frame-8683 FCEUX actor record selected descriptor $79; ROM pointer $8372->$AA5F emitted tiles $51/$54/$52/$53.")
	print("PASS: frame-8664 descriptor $9F resolved through $83BE->$B2CC, selected shared root $B287->$B24B, emitted 18 sprites, and matched the first three captured OAM entries.")
	print("PASS: frame-9477 PASS actor descriptor $CF resolved selector $08 through ROM streams $BE2D->$BE9F->$BE56 and emitted all 18 expected ROM tiles.")
	print("LIMIT: the 41-sprite comparison uses the frame-8953 validation snapshot; full pitch/raster and generic route-time actor scheduling remain open.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
