extends RefCounted
class_name RomActorAnimationStreamDecoder
## Reads the preserved bank-$14 route streams and emits source-addressed events.
## This decoder also builds the ROM-source relative tick schedule: low bytes
## below $F0 load the $053B countdown, while F6 consumes an actor-record offset
## and clears that actor's active byte. It does not execute actor RAM or render
## OAM. F4 selector and F5 setup side effects remain caller-owned.

class SourceEvent:
	extends RefCounted

	enum Kind {
		STREAM_END,
		ACTOR_PACKET,
		SPRITE_CHR_SELECTORS,
		SETUP_OPERAND,
		ABSOLUTE_REDIRECT,
		OPAQUE_CONTROL,
		OPAQUE_VALUE,
		ACTOR_REMOVE,
		WAIT_TICKS,
	}

	var kind: Kind = Kind.OPAQUE_VALUE
	var selected_animation_id: int = -1
	var source_stream_id: int = -1
	var source_cpu_address: int = -1
	var source_file_offset: int = -1
	var opcode: int = -1
	var raw_bytes := PackedByteArray()
	var actor_record_index: int = -1
	var actor_active_flags: int = -1
	var motion_index: int = -1
	var appearance_index: int = -1
	var sprite_chr_selectors := PackedByteArray()
	var redirect_target_cpu_address: int = -1
	var redirect_target_stream_id: int = -1
	var redirect_target_file_offset: int = -1
	var actor_record_offset: int = -1
	var wait_ticks: int = -1
	var source_tick: int = -1


const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_MANIFEST_PATH := "res://reference/rom_extract/gameplay/first_command_actors/manifest.json"
const SOURCE_DIR := "res://reference/rom_extract/gameplay/first_command_actors/"
const EXPECTED_SCHEMA := "first-command-rom-actor-source-v1"
const BANK_14_FILE_BASE := 0x028010
const BANK_14_CPU_BASE := 0x8000
const ANIMATION_POINTER_TABLE_CPU := 0x8968
const ANIMATION_POINTER_TABLE_FILE := 0x028978
const MAX_DECODED_COMMANDS := 1024
const MAX_REDIRECTS := 16
const SEMANTIC_GAPS: Array[String] = [
	"F4 selector bytes are emitted but not applied to mapper/runtime state",
	"F5 setup operands are preserved without executing their side effects",
	"F6 actor removal and low-byte wait timing are decoded but do not mutate actor RAM",
	"The animation's relative source-tick schedule is not connected to the route scheduler or renderer",
	"Appearance/motion interpreters and live shared mirror, scroll, clipping, palette, and CHR state remain caller-owned",
]

const ROUTE_ANIMATION_IDS: Array[int] = [0x8F, 0x4E, 0x66, 0x4C, 0x78, 0x79, 0x90, 0xE6]

## The static values pin each extracted pointer-table span to the checked ROM.
## `$E6` is a five-byte redirect prefix whose target lies inside `$78`.
const STREAM_SPECS := {
	0x8F: {
		"path": "route_animation_8F.bin", "table_offset": 0x028A96,
		"start_cpu": 0x9885, "end_cpu": 0x98AB, "file_offset": 0x029895,
		"sha256": "584a6c5108c0efe657a9a8e1dc531cabb0572eebdc605540c6578a0f7d7f643f",
	},
	0x4E: {
		"path": "route_animation_4E.bin", "table_offset": 0x028A14,
		"start_cpu": 0x9261, "end_cpu": 0x926F, "file_offset": 0x029271,
		"sha256": "4f3ad199e4f138ac25c01845f8f2c36039ef5ba32047cd4d8c34a676e03d84cb",
	},
	0x66: {
		"path": "route_animation_66.bin", "table_offset": 0x028A44,
		"start_cpu": 0x9441, "end_cpu": 0x9456, "file_offset": 0x029451,
		"sha256": "535df666a3cc1cc86d51cfd093d06e7201cfd71f5b7199840cff57505eb616ff",
	},
	0x4C: {
		"path": "route_animation_4C.bin", "table_offset": 0x028A10,
		"start_cpu": 0x9245, "end_cpu": 0x9253, "file_offset": 0x029255,
		"sha256": "f0a9b91bf8a1609497efcbf54ba3b692ed204b94a5efd9fbced293fbc9211eee",
	},
	0x78: {
		"path": "route_animation_78.bin", "table_offset": 0x028A68,
		"start_cpu": 0x9618, "end_cpu": 0x9651, "file_offset": 0x029628,
		"sha256": "03760e7556e10254bff30633029d2e2bd18b39534ebb8d3c5f84c4483bd6eca9",
	},
	0x79: {
		"path": "route_animation_79.bin", "table_offset": 0x028A6A,
		"start_cpu": 0x9651, "end_cpu": 0x965F, "file_offset": 0x029661,
		"sha256": "07c30128d6fa992838e170dce98dcf41d306f73d5fde03c7a25a3e7581aacfc0",
	},
	0x90: {
		"path": "route_animation_90.bin", "table_offset": 0x028A98,
		"start_cpu": 0x98AB, "end_cpu": 0x98C5, "file_offset": 0x0298BB,
		"sha256": "34f5ad052c586a941c1541be51b06324608b5ad70ab38984b3b2467a9269a848",
	},
	0xE6: {
		"path": "route_animation_E6.bin", "table_offset": 0x028B44,
		"start_cpu": 0xA0A3, "end_cpu": 0xA0A8, "file_offset": 0x02A0B3,
		"sha256": "1a65ba372628aff0f4634033047496041fbd1b8d929f4e78c0d505b653a9a7ca",
	},
}

var last_error := ""
var is_configured := false
var _streams_by_id: Dictionary = {}


## Validates ROM identity, pointer-derived spans, and project-owned byte hashes.
func configure() -> bool:
	last_error = ""
	is_configured = false
	_streams_by_id.clear()
	var manifest_bytes := FileAccess.get_file_as_bytes(SOURCE_MANIFEST_PATH)
	if manifest_bytes.is_empty():
		return _fail("The ROM-derived actor stream manifest is missing or empty.")
	var manifest_variant: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not manifest_variant is Dictionary:
		return _fail("The ROM-derived actor stream manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("schema", "")) != EXPECTED_SCHEMA \
			or str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or bool(manifest.get("runtime_rom_dependency", true)) \
			or bool(manifest.get("capture_or_screenshot_bytes_included", true)):
		return _fail("The actor stream manifest targets the wrong ROM or violates the runtime provenance contract.")

	var table: Variant = manifest.get("route_animation_pointer_table", {})
	if not table is Dictionary \
			or _parse_hex(str(table.get("cpu_address", ""))) != ANIMATION_POINTER_TABLE_CPU \
			or _parse_hex(str(table.get("file_offset", ""))) != ANIMATION_POINTER_TABLE_FILE \
			or _parse_hex(str(table.get("file_window_base", ""))) != BANK_14_FILE_BASE \
			or str(table.get("prg_bank", "")) != "$14" \
			or int(table.get("entry_width_bytes", -1)) != 2:
		return _fail("The animation pointer table metadata does not match bank-$14 source mapping.")
	if not _same_int_array(table.get("route_animation_ids", []), ROUTE_ANIMATION_IDS):
		return _fail("The route animation ID list does not match the decoder's verified scope.")

	var entries_variant: Variant = manifest.get("entries", null)
	if not entries_variant is Array:
		return _fail("The actor source manifest has no resource entry list.")
	var entries_by_id: Dictionary = {}
	for entry_variant in entries_variant:
		if not entry_variant is Dictionary:
			return _fail("An actor source manifest entry is malformed.")
		var entry: Dictionary = entry_variant
		if not entry.has("animation_id"):
			continue
		var animation_id := _parse_hex(str(entry.get("animation_id", "")))
		if animation_id >= 0:
			if entries_by_id.has(animation_id):
				return _fail("The actor source manifest repeats an animation ID.")
			entries_by_id[animation_id] = entry

	for animation_id in ROUTE_ANIMATION_IDS:
		var spec: Dictionary = STREAM_SPECS[animation_id]
		if not entries_by_id.has(animation_id):
			return _fail("The actor source manifest is missing animation $%02X." % animation_id)
		var entry: Dictionary = entries_by_id[animation_id]
		if str(entry.get("path", "")) != "reference/rom_extract/gameplay/first_command_actors/" + str(spec["path"]) \
				or _parse_hex(str(entry.get("pointer_table_file_offset", ""))) != int(spec["table_offset"]) \
				or _parse_hex(str(entry.get("start_cpu_address", ""))) != int(spec["start_cpu"]) \
				or _parse_hex(str(entry.get("end_cpu_address_exclusive", ""))) != int(spec["end_cpu"]) \
				or _parse_hex(str(entry.get("file_offset", ""))) != int(spec["file_offset"]) \
				or int(entry.get("length_bytes", -1)) != int(spec["end_cpu"]) - int(spec["start_cpu"]) \
				or str(entry.get("sha256", "")) != str(spec["sha256"]):
			return _fail("Animation $%02X pointer span metadata differs from the byte-checked ROM table." % animation_id)

		var resource_path := SOURCE_DIR + str(spec["path"])
		var source_bytes := FileAccess.get_file_as_bytes(resource_path)
		if source_bytes.size() != int(spec["end_cpu"]) - int(spec["start_cpu"]) \
				or _sha256(source_bytes) != str(spec["sha256"]):
			return _fail("Animation $%02X source bytes fail their ROM-derived span/hash check." % animation_id)
		if animation_id == 0xE6:
			if source_bytes != PackedByteArray([0xF5, 0x87, 0xF8, 0x1A, 0x96]):
				return _fail("Animation $E6 is not the audited F5/F8 redirect prefix.")
		elif int(source_bytes[source_bytes.size() - 1]) != 0xF0:
			return _fail("Animation $%02X is not bounded by its pointer span's terminal $F0." % animation_id)
		_streams_by_id[animation_id] = {
			"id": animation_id,
			"bytes": source_bytes,
			"start_cpu": int(spec["start_cpu"]),
			"end_cpu": int(spec["end_cpu"]),
			"file_offset": int(spec["file_offset"]),
			"path": resource_path,
		}

	is_configured = true
	return true


## Decodes structural commands from a selected ROM table entry. F8 is an
## absolute stream jump, not a call; its target must fall inside a preserved span.
func decode_animation(animation_id: int) -> Dictionary:
	if not is_configured:
		return {"ok": false, "error": "Configure the ROM-derived actor streams before decoding."}
	if not _streams_by_id.has(animation_id):
		return {"ok": false, "error": "Unsupported actor animation ID: $%02X." % animation_id}

	var events: Array[SourceEvent] = []
	var visited_stream_ids: Array[int] = []
	var visited_cursors: Dictionary = {}
	var stream_id := animation_id
	var cursor := 0
	var command_count := 0
	var redirect_count := 0
	var opaque_event_count := 0
	var terminated := false

	while command_count < MAX_DECODED_COMMANDS:
		if not _streams_by_id.has(stream_id):
			return _decode_failure("Redirect selected an unpreserved stream ID.", events)
		var stream: Dictionary = _streams_by_id[stream_id]
		var bytes: PackedByteArray = stream["bytes"]
		var cursor_key := "%02X:%04X" % [stream_id, cursor]
		if visited_cursors.has(cursor_key):
			return _decode_failure("Actor animation stream revisited the same byte without termination.", events)
		visited_cursors[cursor_key] = true
		if not visited_stream_ids.has(stream_id):
			visited_stream_ids.append(stream_id)
		if cursor < 0 or cursor >= bytes.size():
			return _decode_failure("Actor animation reached a pointer-table span boundary without $F0 or $F8.", events)

		var opcode := int(bytes[cursor])
		var source_cpu := int(stream["start_cpu"]) + cursor
		var source_file := int(stream["file_offset"]) + cursor
		command_count += 1

		if opcode < 0xF0:
			var wait_event := SourceEvent.new()
			wait_event.kind = SourceEvent.Kind.WAIT_TICKS
			wait_event.selected_animation_id = animation_id
			wait_event.source_stream_id = stream_id
			wait_event.source_cpu_address = source_cpu
			wait_event.source_file_offset = source_file
			wait_event.opcode = opcode
			wait_event.raw_bytes = PackedByteArray([opcode])
			wait_event.wait_ticks = 0x100 if opcode == 0 else opcode
			events.append(wait_event)
			cursor += 1
			continue

		match opcode:
			0xF0:
				var end_event := _new_event(SourceEvent.Kind.STREAM_END, animation_id, stream_id, source_cpu, source_file, opcode, PackedByteArray([opcode]))
				events.append(end_event)
				terminated = true
				break
			0xF1:
				if cursor + 6 > bytes.size():
					return _decode_failure("$F1 actor packet crosses its pointer-bounded stream span.", events)
				var raw_packet := bytes.slice(cursor, cursor + 6)
				var packet := SourceEvent.new()
				packet.kind = SourceEvent.Kind.ACTOR_PACKET
				packet.selected_animation_id = animation_id
				packet.source_stream_id = stream_id
				packet.source_cpu_address = source_cpu
				packet.source_file_offset = source_file
				packet.opcode = opcode
				packet.raw_bytes = raw_packet
				packet.motion_index = int(raw_packet[1])
				packet.appearance_index = int(raw_packet[2])
				var record_selector := int(raw_packet[5])
				packet.actor_record_index = (record_selector & 0x1C) >> 2
				packet.actor_active_flags = 0x80 | (record_selector & 0x03)
				events.append(packet)
				cursor += 6
			0xF4:
				if cursor + 5 > bytes.size():
					return _decode_failure("$F4 selector command crosses its pointer-bounded stream span.", events)
				var raw_selectors := bytes.slice(cursor, cursor + 5)
				var selector_event := SourceEvent.new()
				selector_event.kind = SourceEvent.Kind.SPRITE_CHR_SELECTORS
				selector_event.selected_animation_id = animation_id
				selector_event.source_stream_id = stream_id
				selector_event.source_cpu_address = source_cpu
				selector_event.source_file_offset = source_file
				selector_event.opcode = opcode
				selector_event.raw_bytes = raw_selectors
				selector_event.sprite_chr_selectors = raw_selectors.slice(1, 5)
				events.append(selector_event)
				cursor += 5
			0xF5:
				if cursor + 2 > bytes.size():
					return _decode_failure("$F5 setup command crosses its pointer-bounded stream span.", events)
				var raw_setup := bytes.slice(cursor, cursor + 2)
				events.append(_new_event(SourceEvent.Kind.SETUP_OPERAND, animation_id, stream_id, source_cpu, source_file, opcode, raw_setup))
				cursor += 2
			0xF6:
				if cursor + 2 > bytes.size():
					return _decode_failure("$F6 actor-removal command crosses its pointer-bounded stream span.", events)
				var record_offset := int(bytes[cursor + 1])
				var remove_event := _new_event(
					SourceEvent.Kind.ACTOR_REMOVE,
					animation_id,
					stream_id,
					source_cpu,
					source_file,
					opcode,
					bytes.slice(cursor, cursor + 2)
				)
				remove_event.actor_record_offset = record_offset
				if record_offset % 0x15 == 0 and record_offset / 0x15 < 6:
					remove_event.actor_record_index = record_offset / 0x15
				events.append(remove_event)
				cursor += 2
			0xF8:
				if cursor + 3 > bytes.size():
					return _decode_failure("$F8 absolute redirect crosses its pointer-bounded stream span.", events)
				var target_cpu := int(bytes[cursor + 1]) | (int(bytes[cursor + 2]) << 8)
				var target := _find_stream_target(target_cpu)
				if target.is_empty():
					return _decode_failure("$F8 target $%04X is outside the preserved route-animation spans." % target_cpu, events)
				var redirect := _new_event(
					SourceEvent.Kind.ABSOLUTE_REDIRECT,
					animation_id,
					stream_id,
					source_cpu,
					source_file,
					opcode,
					bytes.slice(cursor, cursor + 3)
				)
				redirect.redirect_target_cpu_address = target_cpu
				redirect.redirect_target_stream_id = int(target["stream_id"])
				redirect.redirect_target_file_offset = int(target["file_offset"])
				events.append(redirect)
				redirect_count += 1
				if redirect_count > MAX_REDIRECTS:
					return _decode_failure("Actor animation exceeded the redirect limit.", events)
				stream_id = int(target["stream_id"])
				cursor = int(target["cursor"])
				continue
			_:
				return _decode_failure("Unsupported top-level opcode $%02X at $%04X." % [opcode, source_cpu], events)

	if command_count >= MAX_DECODED_COMMANDS:
		return _decode_failure("Actor animation exceeded the command-count safety limit.", events)
	if not terminated:
		return _decode_failure("Actor animation did not reach an explicit ROM $F0 end command.", events)
	return {
		"ok": true,
		"selected_animation_id": animation_id,
		"events": events,
		"visited_stream_ids": visited_stream_ids,
		"redirect_count": redirect_count,
		"opaque_event_count": opaque_event_count,
		"ended_at_cpu_address": events[events.size() - 1].source_cpu_address,
		"ended_at_file_offset": events[events.size() - 1].source_file_offset,
		"source_bytes_only": true,
		"actor_state_mutated": false,
		"cadence_implemented": false,
		"semantic_gaps": SEMANTIC_GAPS.duplicate(),
	}


## Builds an animation's relative ROM tick schedule. Each low byte is the
## $053B delay loaded by the bank-$14 $800F handler; the handler decrements it
## once per source actor-loop call and parses the next command when it reaches
## zero. A zero byte wraps through the eight-bit countdown and therefore waits
## 256 calls. The source tick is relative to the first $800F call that starts
## this animation, not an absolute emulator frame.
func decode_timeline(animation_id: int) -> Dictionary:
	var decoded := decode_animation(animation_id)
	if not bool(decoded.get("ok", false)):
		return decoded
	var source_tick := 0
	var events: Array = decoded["events"]
	for event_variant in events:
		if not event_variant is SourceEvent:
			return {"ok": false, "error": "Decoded animation contains a malformed source event."}
		var event: SourceEvent = event_variant
		event.source_tick = source_tick
		if event.kind == SourceEvent.Kind.WAIT_TICKS:
			source_tick += event.wait_ticks
	return {
		"ok": true,
		"selected_animation_id": animation_id,
		"events": events,
		"source_tick_count": source_tick,
		"tick_basis": "one bank-$14:$800F call per source actor-loop pass; low-byte countdown from ROM $053B",
		"source_bytes_only": true,
		"actor_state_mutated": false,
		"absolute_route_timing_implemented": false,
		"semantic_gaps": SEMANTIC_GAPS.duplicate(),
	}


## Connects an event_record token produced by Bank10ScenarioBytecodeReader to
## the ROM-selected actor stream. The scenario $0523 wait remains separate from
## animation-relative $053B delays; the caller owns the ROM worker/scheduler
## phase that decides when $EC94 loads the scenario wait and starts $800F.
func decode_scenario_event_record(record_token: Dictionary) -> Dictionary:
	if str(record_token.get("kind", "")) != "event_record":
		return {"ok": false, "error": "Expected a decoded bank-$10 event_record token."}
	var assignments_variant: Variant = record_token.get("ram_assignments", {})
	if not assignments_variant is Dictionary:
		return {"ok": false, "error": "Scenario event token has no decoded RAM assignments."}
	var assignments: Dictionary = assignments_variant
	for address in ["$0523", "$0524", "$0528", "$0529"]:
		if not assignments.has(address):
			return {"ok": false, "error": "Scenario event token is missing %s." % address}
	var animation_id := int(assignments["$0528"])
	var timeline := decode_timeline(animation_id)
	if not bool(timeline.get("ok", false)):
		return timeline
	var result := timeline.duplicate()
	result["scenario_wait_ticks"] = int(assignments["$0523"]) & 0xFF
	result["scenario_event_selector"] = int(assignments["$0524"]) & 0xFF
	result["animation_parameter"] = int(assignments["$0529"]) & 0xFF
	result["scenario_record_byte_offset"] = int(record_token.get("byte_offset", -1))
	result["event_source"] = "Bank10ScenarioBytecodeReader decoded ROM event_record"
	result["scenario_wait_basis"] = "ROM $0523 copied to $0519 at $EC94; $ED5B/$ED5F decrement once per source frame"
	return result


func _find_stream_target(cpu_address: int) -> Dictionary:
	if cpu_address < BANK_14_CPU_BASE or cpu_address >= 0xC000:
		return {}
	for animation_id in ROUTE_ANIMATION_IDS:
		var stream: Dictionary = _streams_by_id[animation_id]
		if cpu_address >= int(stream["start_cpu"]) and cpu_address < int(stream["end_cpu"]):
			var cursor := cpu_address - int(stream["start_cpu"])
			return {
				"stream_id": animation_id,
				"cursor": cursor,
				"file_offset": int(stream["file_offset"]) + cursor,
			}
	return {}


func _new_event(
		kind: SourceEvent.Kind,
		selected_animation_id: int,
		source_stream_id: int,
		source_cpu_address: int,
		source_file_offset: int,
		opcode: int,
		raw_bytes: PackedByteArray
) -> SourceEvent:
	var event := SourceEvent.new()
	event.kind = kind
	event.selected_animation_id = selected_animation_id
	event.source_stream_id = source_stream_id
	event.source_cpu_address = source_cpu_address
	event.source_file_offset = source_file_offset
	event.opcode = opcode
	event.raw_bytes = raw_bytes
	return event


func _decode_failure(message: String, events: Array[SourceEvent]) -> Dictionary:
	last_error = message
	return {
		"ok": false,
		"error": message,
		"events": events,
		"source_bytes_only": true,
		"actor_state_mutated": false,
		"cadence_implemented": false,
		"semantic_gaps": SEMANTIC_GAPS.duplicate(),
	}


func _same_int_array(candidate: Variant, expected: Array[int]) -> bool:
	if not candidate is Array or candidate.size() != expected.size():
		return false
	for index in expected.size():
		if _parse_hex(str(candidate[index])) != expected[index]:
			return false
	return true


func _parse_hex(value: String) -> int:
	var normalized := value.strip_edges().to_lower()
	if normalized.begins_with("0x"):
		normalized = normalized.substr(2)
	elif normalized.begins_with("$"):
		normalized = normalized.substr(1)
	if normalized.is_empty():
		return -1
	return normalized.hex_to_int()


func _sha256(bytes: PackedByteArray) -> String:
	if bytes.is_empty():
		return ""
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false
