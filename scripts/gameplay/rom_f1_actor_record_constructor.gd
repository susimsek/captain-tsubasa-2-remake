extends RefCounted
class_name RomF1ActorRecordConstructor
## Constructs the 21-byte actor record written by bank-$14 $80AA for the
## source F1 packets in fresh-start scenario $35 / animation $8F.
## It does not schedule packet events, tick appearance/motion, or render OAM.

class ActorRecord:
	extends RefCounted

	var bytes := PackedByteArray()
	var actor_index: int = -1
	var record_cpu_address: int = -1
	var motion_index: int = -1
	var motion_cpu_address: int = -1
	var appearance_index: int = -1
	var appearance_cpu_address: int = -1
	var active_flags: int = -1
	var source_animation_id: int = -1
	var source_stream_id: int = -1
	var source_file_offset: int = -1


const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_DIR := "res://reference/rom_extract/gameplay/actor_packet_constructor/"
const MANIFEST_PATH := SOURCE_DIR + "manifest.json"
const RECORD_TABLE_NAME := "actor_record_pointer_table_88E4_00_05.bin"
const MOTION_TABLE_NAME := "motion_pointer_table_A1B4_00_71.bin"
const APPEARANCE_TABLE_NAME := "appearance_pointer_table_AC47_00_93.bin"
const RECORD_COUNT := 6
const ACTOR_RECORD_BYTES := 21
const ROUTE_ANIMATION_ID := 0x8F
const ROUTE_MOTION_MAX_INDEX := 0x71
const ROUTE_APPEARANCE_MAX_INDEX := 0x93
const MOTION_POINTER_MIN := 0x8000
const MOTION_POINTER_MAX_EXCLUSIVE := 0xC000
const APPEARANCE_POINTER_MIN := 0x8000
const APPEARANCE_POINTER_MAX_EXCLUSIVE := 0xC000

const RESOURCE_SPECS := {
	RECORD_TABLE_NAME: {
		"file_offset": 0x0288F4, "cpu_address": "$88E4", "length_bytes": 12,
		"sha256": "c099278e38811268e12679a668fd59f7b3c909ffcedec441c8e60c51514968b6",
		"last_index": 5,
	},
	MOTION_TABLE_NAME: {
		"file_offset": 0x02A1C4, "cpu_address": "$A1B4", "length_bytes": 0xE4,
		"sha256": "15171701bd415846f98c0bfe2ab119db90987f426bf16908705e0ba868088c11",
		"last_index": ROUTE_MOTION_MAX_INDEX,
	},
	APPEARANCE_TABLE_NAME: {
		"file_offset": 0x02AC57, "cpu_address": "$AC47", "length_bytes": 0x128,
		"sha256": "a0638cdcc481955ac46aac1576d50ec40786c023c4d8f21867b2e4728691453f",
		"last_index": ROUTE_APPEARANCE_MAX_INDEX,
	},
}

var last_error: String = ""
var is_configured: bool = false
var _record_table := PackedByteArray()
var _motion_table := PackedByteArray()
var _appearance_table := PackedByteArray()


## Loads byte-preserved table prefixes. The ROM itself is never opened here.
func configure() -> bool:
	last_error = ""
	is_configured = false
	_record_table = PackedByteArray()
	_motion_table = PackedByteArray()
	_appearance_table = PackedByteArray()
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var manifest_variant: Variant = JSON.parse_string(manifest_text)
	if not manifest_variant is Dictionary:
		return _fail("F1 actor-record source manifest is missing or malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != "ct2-rom-f1-actor-record-constructor-v1" \
			or str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("capture_or_screenshot_bytes_included", true)):
		return _fail("F1 actor-record manifest does not match the target-ROM runtime provenance contract.")
	var resources_variant: Variant = manifest.get("resources", null)
	if not resources_variant is Array:
		return _fail("F1 actor-record manifest has no resource list.")
	var entries_by_name: Dictionary = {}
	for entry_variant in resources_variant:
		if not entry_variant is Dictionary:
			return _fail("F1 actor-record manifest contains a malformed resource entry.")
		var entry: Dictionary = entry_variant
		var name := str(entry.get("name", ""))
		if entries_by_name.has(name):
			return _fail("F1 actor-record manifest repeats resource " + name + ".")
		entries_by_name[name] = entry

	for name_variant in RESOURCE_SPECS:
		var name := str(name_variant)
		if not entries_by_name.has(name):
			return _fail("F1 actor-record source is missing table " + name + ".")
		var spec: Dictionary = RESOURCE_SPECS[name]
		var entry: Dictionary = entries_by_name[name]
		if str(entry.get("path", "")) != "reference/rom_extract/gameplay/actor_packet_constructor/" + name \
				or str(entry.get("cpu_address", "")) != str(spec["cpu_address"]) \
				or _parse_hex(str(entry.get("file_offset", ""))) != int(spec["file_offset"]) \
				or int(entry.get("length_bytes", -1)) != int(spec["length_bytes"]) \
				or int(entry.get("first_index", -1)) != 0 \
				or int(entry.get("last_index", -1)) != int(spec["last_index"]) \
				or int(entry.get("entry_width_bytes", -1)) != 2 \
				or str(entry.get("sha256", "")) != str(spec["sha256"]):
			return _fail("F1 actor-record table metadata differs from its checked ROM span: " + name)
		var bytes := FileAccess.get_file_as_bytes(SOURCE_DIR + name)
		if bytes.size() != int(spec["length_bytes"]) or _sha256(bytes) != str(spec["sha256"]):
			return _fail("F1 actor-record table failed its preserved-byte hash check: " + name)
		match name:
			RECORD_TABLE_NAME:
				_record_table = bytes
			MOTION_TABLE_NAME:
				_motion_table = bytes
			APPEARANCE_TABLE_NAME:
				_appearance_table = bytes

	if _record_table.size() != RECORD_COUNT * 2 \
			or _motion_table.size() != (ROUTE_MOTION_MAX_INDEX + 1) * 2 \
			or _appearance_table.size() != (ROUTE_APPEARANCE_MAX_INDEX + 1) * 2:
		return _fail("F1 actor-record tables do not cover the source-selected $8F indexes.")
	is_configured = true
	return true


## Applies the ROM $80AA constructor to a decoded $F1 event. Only animation
## $8F is accepted so unsupported later route indexes cannot silently pass.
func construct(event: RomActorAnimationStreamDecoder.SourceEvent) -> ActorRecord:
	last_error = ""
	if not is_configured:
		_fail("Configure the checked actor pointer tables before constructing records.")
		return null
	if event == null or event.kind != RomActorAnimationStreamDecoder.SourceEvent.Kind.ACTOR_PACKET:
		_fail("Expected a decoded ROM $F1 actor-packet event.")
		return null
	if event.selected_animation_id != ROUTE_ANIMATION_ID or event.opcode != 0xF1 \
			or event.raw_bytes.size() != 6 or int(event.raw_bytes[0]) != 0xF1:
		_fail("The constructor only accepts a complete source $F1 packet from animation $8F.")
		return null
	var motion_index := int(event.raw_bytes[1])
	var appearance_index := int(event.raw_bytes[2])
	var selector := int(event.raw_bytes[5])
	var actor_index := (selector & 0x1C) >> 2
	var active_flags := 0x80 | (selector & 0x03)
	if event.motion_index != motion_index or event.appearance_index != appearance_index \
			or event.actor_record_index != actor_index or event.actor_active_flags != active_flags:
		_fail("Decoded $F1 fields disagree with their preserved raw operands.")
		return null
	if actor_index < 0 or actor_index >= RECORD_COUNT:
		_fail("F1 selector resolves outside the six ROM actor records.")
		return null
	if motion_index < 0 or motion_index > ROUTE_MOTION_MAX_INDEX \
			or appearance_index < 0 or appearance_index > ROUTE_APPEARANCE_MAX_INDEX:
		_fail("F1 script index is outside the extracted animation-$8F pointer-table prefixes.")
		return null
	var record_address := _read_u16(_record_table, actor_index * 2)
	var motion_address := _read_u16(_motion_table, motion_index * 2)
	var appearance_address := _read_u16(_appearance_table, appearance_index * 2)
	if record_address < 0x0547 or record_address > 0x05B0 \
			or motion_address < MOTION_POINTER_MIN or motion_address >= MOTION_POINTER_MAX_EXCLUSIVE \
			or appearance_address < APPEARANCE_POINTER_MIN or appearance_address >= APPEARANCE_POINTER_MAX_EXCLUSIVE:
		_fail("F1 pointer-table lookup returned an address outside the source CPU windows.")
		return null

	var actor := ActorRecord.new()
	actor.bytes.resize(ACTOR_RECORD_BYTES)
	actor.bytes.fill(0)
	actor.bytes[0] = active_flags
	_write_u16(actor.bytes, 1, motion_address)
	_write_u16(actor.bytes, 3, appearance_address)
	actor.bytes[8] = int(event.raw_bytes[3])
	actor.bytes[12] = int(event.raw_bytes[4])
	actor.actor_index = actor_index
	actor.record_cpu_address = record_address
	actor.motion_index = motion_index
	actor.motion_cpu_address = motion_address
	actor.appearance_index = appearance_index
	actor.appearance_cpu_address = appearance_address
	actor.active_flags = active_flags
	actor.source_animation_id = event.selected_animation_id
	actor.source_stream_id = event.source_stream_id
	actor.source_file_offset = event.source_file_offset
	return actor


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	if offset < 0 or offset + 1 >= bytes.size():
		return -1
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _write_u16(bytes: PackedByteArray, offset: int, value: int) -> void:
	bytes[offset] = value & 0xFF
	bytes[offset + 1] = (value >> 8) & 0xFF


func _parse_hex(value: String) -> int:
	var normalized := value.strip_edges().to_lower()
	if normalized.begins_with("0x"):
		normalized = normalized.substr(2)
	return normalized.hex_to_int()


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false
