extends RefCounted
class_name RomFreshDaf5ReceiverCaller
## Executes the ROM-derived `$DAF5-$DB0E` receiver-selection caller and stops
## at the `$E6EC` holder-copy entry. It consumes live route RAM, never captures.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_daf5_receiver_setup/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const MANIFEST_SHA256 := "41725f1115032b26c9499409a3e496aeffac9119ab651b2139003f5d07d285bf"
const CALLER_FILE := "fixed_receiver_selection_DAF5_DB0E.bin"
const CALLER_SHA256 := "c57c49c5a00e1a91f54394dc2bad024a1f8ceaf0d6bd2961268c62866f4ab22a"
const CALLER_HEX := "ade2002907c9059002e905aabd82dc186dfb058dfc0520ece6"
const CALLER_LENGTH := 25
const RECEIVER_TABLE_PATH := "res://reference/rom_extract/gameplay/menus/first_action_menu/first_match_receiver_offsets_DC82.bin"
const RECEIVER_TABLE_SHA256 := "2784104ad143ec88dc701b76946cf13dfe9bbe799d90e5f4cb00bf97cf5abcb8"
const EXPECTED_RECEIVER_OFFSETS: Array[int] = [0x05, 0x06, 0x07, 0x09, 0x0A]

var error_message := ""
var _configured := false


func configure() -> bool:
	error_message = ""
	_configured = false
	if not FileAccess.file_exists(MANIFEST_PATH) or not FileAccess.file_exists(SOURCE_ROOT + CALLER_FILE):
		return _fail("The preserved `$DAF5-$DB0E` receiver-caller package is missing.")
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if _sha256(manifest_bytes) != MANIFEST_SHA256:
		return _fail("The `$DAF5` caller source manifest failed its hash check.")
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return _fail("The `$DAF5` caller source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-daf5-receiver-setup-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("The `$DAF5` caller source manifest targets the wrong ROM or schema.")
	var spans: Array = manifest.get("spans", [])
	if spans.size() != 1 or not spans[0] is Dictionary:
		return _fail("The `$DAF5` caller manifest must contain exactly the bounded caller span.")
	var span: Dictionary = spans[0]
	if String(span.get("file", "")) != CALLER_FILE \
			or String(span.get("cpu_start", "")) != "0xDAF5" \
			or String(span.get("cpu_end_exclusive", "")) != "0xDB0E" \
			or String(span.get("file_offset", "")) != "0x03DB05" \
			or int(span.get("length", -1)) != CALLER_LENGTH \
			or String(span.get("sha256", "")) != CALLER_SHA256 \
			or String(span.get("bytes", "")).replace(" ", "").to_lower() != CALLER_HEX:
		return _fail("The `$DAF5-$DB0E` caller span metadata or byte listing is incorrect.")
	var caller_bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + CALLER_FILE)
	if caller_bytes.hex_encode() != CALLER_HEX or _sha256(caller_bytes) != CALLER_SHA256:
		return _fail("The preserved `$DAF5-$DB0E` caller bytes failed their hash or instruction check.")
	var receiver_bytes := FileAccess.get_file_as_bytes(RECEIVER_TABLE_PATH)
	if receiver_bytes != PackedByteArray(EXPECTED_RECEIVER_OFFSETS) \
			or _sha256(receiver_bytes) != RECEIVER_TABLE_SHA256:
		return _fail("The `$DC82` receiver-offset table failed its ROM-source check.")
	_configured = true
	return true


func execute_from_live_boundary(boundary: Dictionary, match_context: Dictionary) -> Dictionary:
	if not _configured:
		return _fail_result("Configure the checked caller and `$DC82` source bytes first.")
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not ram_variant is PackedByteArray or ram_variant.size() != 0x0800 \
			or not stack_variant is PackedByteArray or stack_variant.size() != 0x0100:
		return _fail_result("The live `$DAF5` boundary must include complete scheduler RAM and stack images.")
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("pc", -1)) != 0xDAF5 \
			or int(boundary.get("sp", -1)) != 0x50 \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D:
		return _fail_result("Receiver selection requires live slot-$05 `$DAF5` / SP `$50` / bank `$1C/$1D`.")
	var ram := (ram_variant as PackedByteArray).duplicate()
	var source_context: Dictionary = match_context.get("source_context", {})
	var side := int(ram[0x05FB])
	if int(match_context.get("match_index", -1)) != 0 \
			or side not in [0, 11] \
			or side != int(match_context.get("possession_side_05fb", -1)) \
			or String(source_context.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or String(source_context.get("label", "")).is_empty():
		return _fail_result("Receiver selection requires ROM-derived match-zero side and named caller-owned context.")
	var rng_byte := int(ram[0x00E2])
	var reduced_index := rng_byte & 0x07
	if reduced_index >= EXPECTED_RECEIVER_OFFSETS.size():
		reduced_index -= EXPECTED_RECEIVER_OFFSETS.size()
	var receiver_offsets := FileAccess.get_file_as_bytes(RECEIVER_TABLE_PATH)
	var receiver_offset := int(receiver_offsets[reduced_index])
	var receiver_slot := (receiver_offset + side) & 0xFF
	var ram_after := ram.duplicate()
	ram_after[0x05FC] = receiver_slot
	var stack_after := (stack_variant as PackedByteArray).duplicate()
	var stack_writes: Array[Dictionary] = [
		{"pc": 0xDB0B, "address": 0x0150, "value": 0xDB},
		{"pc": 0xDB0B, "address": 0x014F, "value": 0x0D},
	]
	for write: Dictionary in stack_writes:
		var offset := int(write["address"]) & 0xFF
		stack_after[offset] = int(write["value"])
		ram_after[0x0100 + offset] = int(write["value"])
	var entry_p := int(boundary.get("p", 0x20)) & 0xFF
	var return_p := (entry_p & 0x3C) | 0x20
	if receiver_slot == 0:
		return_p |= 0x02
	return {
		"ok": true,
		"status": "stopped_at_slot05_e6ec_holder_call_boundary",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": MANIFEST_SHA256,
		"caller_source_sha256": CALLER_SHA256,
		"receiver_table_source_sha256": RECEIVER_TABLE_SHA256,
		"entry": {"pc": 0xDAF5, "sp": 0x50, "e2": rng_byte,
			"receiver_index": reduced_index, "receiver_offset": receiver_offset,
			"receiver_slot": receiver_slot, "side_05fb": side},
		"registers": {"pc": 0xE6EC, "sp": 0x4E, "a": receiver_slot,
			"x": reduced_index, "y": int(boundary.get("y", 0x06)),
			"p": return_p, "p_known_mask": (int(boundary.get("p_known_mask", 0)) | 0xE3) & 0xFF},
		"ram_image": ram_after,
		"stack_page": stack_after,
		"memory_writes": [{"pc": 0xDB08, "address": 0x05FC, "value": receiver_slot}],
		"stack_writes": stack_writes,
		"calls": [{"callsite": 0xDB0B, "target": 0xE6EC,
			"return_word": 0xDB0D, "return_pc": 0xDB0E, "sp_after_push": 0x4E}],
		"ppu_bus_events": [], "apu_register_writes": [],
		"source_cycle_timing_modeled": false,
		"source_context": source_context.duplicate(true),
		"error": "",
	}


func get_source_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"manifest_path": MANIFEST_PATH, "manifest_sha256": MANIFEST_SHA256,
		"rom_sha256": ROM_SHA256, "caller_sha256": CALLER_SHA256,
		"receiver_table_sha256": RECEIVER_TABLE_SHA256}


func _fail_result(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
