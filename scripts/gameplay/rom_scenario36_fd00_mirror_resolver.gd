extends RefCounted
class_name RomScenario36Fd00MirrorResolver
## Executes scenario $36's ROM-derived $FD $00 mirror calculation from live RAM.

const SOURCE_ROOT := "res://reference/rom_extract/gameplay/scenario36_fd00_mirror/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_SPANS := {
	"bank10_fd00_handler_8877_88AA.bin": {"start": 0x8877, "end": 0x88AA,
		"offset": 0x020887, "length": 51, "sha256": "7b056de209aff026982fabb5e945f5aee9a032e0876588dfd76485bb42260f21"},
	"fixed_record_pointer_helper_CD7C_CD89.bin": {"start": 0xCD7C, "end": 0xCD89,
		"offset": 0x03CD8C, "length": 13, "sha256": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24"},
	"fixed_player_record_pointer_table_CD89_CDC9.bin": {"start": 0xCD89, "end": 0xCDC9,
		"offset": 0x03CD99, "length": 64, "sha256": "69928f23546876b56ef0e1c47913e5bcf8b34d2aaab39f521916e8e028cf0dba"},
	"fixed_value_div12_helper_CDC9_CDE2.bin": {"start": 0xCDC9, "end": 0xCDE2,
		"offset": 0x03CDD9, "length": 25, "sha256": "45eb9e048e38d5655178886e5c61d4245720493c9044e2acc2f180f8c76eba7c"},
	"fixed_record_pointer_vector_C50C_C50F.bin": {"start": 0xC50C, "end": 0xC50F,
		"offset": 0x03C51C, "length": 3, "sha256": "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44"},
	"fixed_value_div12_vector_C536_C539.bin": {"start": 0xC536, "end": 0xC539,
		"offset": 0x03C546, "length": 3, "sha256": "45c5f5dc3181044f55e152be9dd6ec1c7f9664fb4a87340dc5ac758ccc0bc775"},
}
const RAM_SIZE := 0x800

var last_error := ""
var _configured := false
var _source: Dictionary = {}


func configure() -> bool:
	last_error = ""
	_configured = false
	_source.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Scenario-$36 `$FD $00` source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Scenario-$36 `$FD $00` source manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	var spans: Variant = manifest.get("spans", [])
	if String(manifest.get("schema", "")) != "ct2-scenario36-fd00-mirror-source-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("trace_state_included", true)) \
			or not spans is Array or spans.size() != EXPECTED_SPANS.size():
		return _fail("Scenario-$36 `$FD $00` manifest has the wrong ROM, scope, or schema.")
	for filename_variant in EXPECTED_SPANS:
		var filename := String(filename_variant)
		var spec: Dictionary = EXPECTED_SPANS[filename]
		var found: Dictionary = {}
		for span_variant in spans:
			if span_variant is Dictionary and String(span_variant.get("file", "")) == filename:
				found = span_variant
				break
		if found.is_empty() or _hex(String(found.get("cpu_start", ""))) != int(spec["start"]) \
				or _hex(String(found.get("cpu_end_exclusive", ""))) != int(spec["end"]) \
				or _hex(String(found.get("file_offset", ""))) != int(spec["offset"]) \
				or int(found.get("length", -1)) != int(spec["length"]) \
				or String(found.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Scenario-$36 `$FD $00` metadata differs for `%s`." % filename)
		var bytes := FileAccess.get_file_as_bytes(SOURCE_ROOT + filename)
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]) \
				or String(found.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Scenario-$36 `$FD $00` source bytes failed validation for `%s`." % filename)
		_source[filename] = bytes
	if not _verify_recipes():
		return false
	_configured = true
	return true


func execute(ram_image: PackedByteArray) -> Dictionary:
	if not _configured:
		return _rejected("Configure the hash-checked scenario-$36 `$FD $00` sources first.")
	if ram_image.size() != RAM_SIZE:
		return _rejected("Scenario-$36 `$FD $00` requires the complete 2 KiB live RAM image.")
	var holder_index := int(ram_image[0x0441])
	var record_table: PackedByteArray = _source["fixed_player_record_pointer_table_CD89_CDC9.bin"]
	if holder_index < 0 or holder_index >= record_table.size() / 2:
		return _rejected("Live ball-holder index `$%02X` is outside the ROM `$CD89` pointer table." % holder_index)
	var table_offset := holder_index * 2
	var record_base := int(record_table[table_offset]) | (int(record_table[table_offset + 1]) << 8)
	if record_base < 0x0300 or record_base + 0x09 >= ram_image.size():
		return _rejected("ROM `$C50C->$CD7C` resolved an unsupported player-record address `$%04X`." % record_base)
	var value := int(ram_image[0x0638])
	var quotient := int(value / 12)
	var remainder := value - quotient * 12
	# ROM `$CDC9` returns Y=`$54 + 8*remainder` and X=`$34 + 8*quotient`.
	# `$8877` compares Y against record +8, then X against record +6.
	var compare_field_08 := 0x54 + remainder * 8
	var compare_field_06 := 0x34 + quotient * 8
	var first_borrow := compare_field_08 < int(ram_image[record_base + 8])
	var second_borrow := compare_field_06 < int(ram_image[record_base + 6])
	var comparison_count := (1 if first_borrow else 0) + (2 if second_borrow else 0)
	var mirror_flag := 0x40 if comparison_count == 0 or comparison_count == 3 else 0x00
	return {
		"ok": true,
		"status": "fd00_mirror_resolved",
		"source_manifest": MANIFEST_PATH,
		"rom_sha256": ROM_SHA256,
		"ball_holder_index": holder_index,
		"player_record_cpu_address": record_base,
		"comparison_ram_0638": value,
		"division_quotient": quotient,
		"division_remainder": remainder,
		"compare_value_for_record_08": compare_field_08,
		"compare_value_for_record_06": compare_field_06,
		"record_field_06": int(ram_image[record_base + 6]),
		"record_field_08": int(ram_image[record_base + 8]),
		"borrow_flags": [first_borrow, second_borrow],
		"comparison_count": comparison_count,
		"mirror_flag": mirror_flag,
		"source_pc_sequence": [0x8877, 0x887B, 0x887E, 0x8881, 0x8884, 0x888A, 0x8891, 0x8894, 0x889D, 0x889F, 0x88A1],
		"cpu_timing_modeled": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH, "reads_supplied_rom_at_runtime": false,
		"reads_trace_ram_or_images": false}


func _verify_recipes() -> bool:
	if _source["bank10_fd00_handler_8877_88AA.bin"] != PackedByteArray([
		0xA9, 0x00, 0x85, 0x3B, 0xAD, 0x41, 0x04, 0x20, 0x0C, 0xC5, 0xAD, 0x38, 0x06, 0x20, 0x36, 0xC5,
		0x98, 0xA0, 0x08, 0x38, 0xF1, 0x34, 0xB0, 0x02, 0xE6, 0x3B, 0x8A, 0xA0, 0x06, 0x38, 0xF1, 0x34,
		0xB0, 0x04, 0xE6, 0x3B, 0xE6, 0x3B, 0xA2, 0x40, 0xA5, 0x3B, 0xF0, 0x06, 0xC9, 0x03, 0xF0, 0x02,
		0xA2, 0x00, 0x60]) \
			or _source["fixed_record_pointer_helper_CD7C_CD89.bin"] != PackedByteArray([
			0x0A, 0xA8, 0xB9, 0x89, 0xCD, 0x85, 0x34, 0xB9, 0x8A, 0xCD, 0x85, 0x35, 0x60]) \
			or _source["fixed_value_div12_helper_CDC9_CDE2.bin"] != PackedByteArray([
			0xA2, 0x00, 0xC9, 0x0C, 0x90, 0x05, 0xE9, 0x0C, 0xE8, 0xD0, 0xF7, 0x0A, 0x0A, 0x0A,
			0x69, 0x54, 0xA8, 0x8A, 0x0A, 0x0A, 0x0A, 0x69, 0x34, 0xAA, 0x60]) \
			or _source["fixed_record_pointer_vector_C50C_C50F.bin"] != PackedByteArray([0x4C, 0x7C, 0xCD]) \
			or _source["fixed_value_div12_vector_C536_C539.bin"] != PackedByteArray([0x4C, 0xC9, 0xCD]):
		return _fail("Scenario-$36 `$FD $00` routine or fixed-vector bytes do not match the supported ROM recipe.")
	var table: PackedByteArray = _source["fixed_player_record_pointer_table_CD89_CDC9.bin"]
	var previous_pointer := -1
	for index in range(32):
		var offset := index * 2
		var pointer := int(table[offset]) | (int(table[offset + 1]) << 8)
		if pointer < 0x0300 or pointer + 0x09 >= RAM_SIZE or pointer <= previous_pointer:
			return _fail("ROM `$CD89` player pointer %d is outside the ordered CPU-RAM record table." % index)
		previous_pointer = pointer
	return true


func _hex(value: String) -> int:
	return value.to_lower().trim_prefix("0x").hex_to_int()


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false


func _rejected(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "status": "source_state_rejected", "error": message}
