extends RefCounted
class_name RomMapperShadowSourceState
## Derives the fresh KICK OFF MMC3 select-shadow byte from the supplied ROM's
## reset/initializer stores. Emulator captures are validation only.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const BOOT_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_1b6_boot_producer_20261029/"
const RESET_ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_entry_context/"
const BOOT_MANIFEST := BOOT_ROOT + "manifest.json"
const RESET_CLEAR_FILE := RESET_ROOT + "reset_ram_clear_C64E_C679.bin"
const RESET_TAIL_FILE := BOOT_ROOT + "fixed_reset_tail_C67A_C6BE.bin"
const MAPPER_INIT_FILE := BOOT_ROOT + "fixed_mapper_wrapper_C400_C41E.bin"

const RESET_CLEAR_SHA256 := "8315e93ae660d302632f7bfeffc9db002b3f1c1643ae2b6936d3ce5703e6f75a"
const RESET_TAIL_SHA256 := "67b813ea10823b567758336a7dc96e3eca11d6800ea7d6c6e2186076e8e3d3d4"
const MAPPER_INIT_SHA256 := "b202c40966101d2332de8c9ac85dac12ad69665579e933455b8572760f91292d"

var error_message := ""


func derive_fresh_kickoff_id1() -> Dictionary:
	error_message = ""
	var clear := FileAccess.get_file_as_bytes(RESET_CLEAR_FILE)
	var reset_tail := FileAccess.get_file_as_bytes(RESET_TAIL_FILE)
	var mapper_init := FileAccess.get_file_as_bytes(MAPPER_INIT_FILE)
	if clear.size() != 44 or _sha256(clear) != RESET_CLEAR_SHA256:
		return _failure("The ROM reset RAM-clear source span failed its size/hash check.")
	if reset_tail.size() != 68 or _sha256(reset_tail) != RESET_TAIL_SHA256:
		return _failure("The ROM reset-tail source span failed its size/hash check.")
	if mapper_init.size() != 30 or _sha256(mapper_init) != MAPPER_INIT_SHA256:
		return _failure("The ROM mapper-initializer source span failed its size/hash check.")
	if not _verify_manifest():
		return _failure(error_message)
	var zero_fill := PackedByteArray([
		0xA9, 0x00, 0x85, 0x00, 0x85, 0x01, 0xA8, 0xA2, 0x08, 0x91,
		0x00, 0xC8, 0xD0, 0xFB, 0xE6, 0x01, 0xCA, 0xD0, 0xF6,
	])
	if clear.slice(25, 44) != zero_fill:
		return _failure("The reset source no longer contains the checked eight-page RAM zero-fill loop.")
	var reset_ram := PackedByteArray()
	reset_ram.resize(0x800)
	reset_ram.fill(0xFF)
	var fill_value := int(clear[26])
	for page in range(8):
		for offset in range(0x100):
			reset_ram[(page << 8) | offset] = fill_value
	var reset_store_offset := 0xC6A2 - 0xC67A
	if reset_tail.slice(reset_store_offset - 2, reset_store_offset + 3) \
			!= PackedByteArray([0xA9, 0x00, 0x8D, 0x22, 0x00]):
		return _failure("The reset-tail source no longer stores zero to MMC3 shadow `$0022` at `$C6A2`.")
	reset_ram[0x0022] = int(reset_tail[reset_store_offset - 1])
	var init_store_offset := 0xC411 - 0xC400
	if mapper_init.slice(init_store_offset - 2, init_store_offset + 2) \
			!= PackedByteArray([0xA9, 0x00, 0x85, 0x22]):
		return _failure("The `$C400` initializer no longer stores zero to MMC3 shadow `$0022` at `$C411`.")
	reset_ram[0x0022] = int(mapper_init[init_store_offset - 1])
	# The reset loop directly writes RAM[$0022]=0; both later source stores
	# preserve that value. A same-input, two-pass FCEUX trace corroborates no
	# further writes through frame 7300; it is not read by this runtime method.
	return {
		"ok": true,
		"value": int(reset_ram[0x0022]),
		"ram_address": 0x0022,
		"match_index_0026": int(reset_ram[0x0026]),
		"match_index_provenance": "the same verified reset loop zero-fills RAM `$0000-$07FF`",
		"source_events": [
			{"pc": 0xC670, "operation": "reset indirect zero-fill", "value": 0},
			{"pc": 0xC6A2, "operation": "LDA #$00 / STA $0022", "value": 0},
			{"pc": 0xC411, "operation": "LDA #$00 / STA $22", "value": 0},
		],
		"route_scope": "cold-start fresh KICK OFF through ID-1 Select cleanup",
		"source_rom_sha256": ROM_SHA256,
		"emulator_data_used": false,
		"observation_corroboration": "two identical muted passes from frame 4692 through 7300 recorded no later $0022 writes; validation only",
		"general_path_proof": false,
	}


func _verify_manifest() -> bool:
	if not FileAccess.file_exists(BOOT_MANIFEST):
		return _fail("The checked fresh KICK OFF boot-source manifest is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BOOT_MANIFEST))
	if not parsed is Dictionary:
		return _fail("The checked fresh KICK OFF boot-source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The boot-source manifest targets another ROM revision.")
	var expected := {
		"fixed_reset_tail_C67A_C6BE.bin": {"cpu_start": "0xC67A", "file_offset": "0x03C68A", "length": 68, "sha256": RESET_TAIL_SHA256},
		"fixed_mapper_wrapper_C400_C41E.bin": {"cpu_start": "0xC400", "file_offset": "0x03C410", "length": 30, "sha256": MAPPER_INIT_SHA256},
	}
	var found: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			found[String(span.get("file", ""))] = span
	for file_name: String in expected:
		if not found.has(file_name):
			return _fail("The boot-source manifest omits %s." % file_name)
		var entry: Dictionary = found[file_name]
		var spec: Dictionary = expected[file_name]
		for key: String in ["cpu_start", "file_offset", "sha256"]:
			if String(entry.get(key, "")) != String(spec[key]):
				return _fail("The boot-source manifest metadata differs for %s (%s)." % [file_name, key])
		if int(entry.get("length", -1)) != int(spec["length"]):
			return _fail("The boot-source manifest length differs for %s." % file_name)
	return true


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message, "emulator_data_used": false}
