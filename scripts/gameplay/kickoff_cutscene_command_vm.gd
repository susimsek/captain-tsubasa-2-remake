extends Node
class_name KickoffCutsceneCommandVm
## Source-byte-preserving scheduler for the two fresh-start KICK OFF scripts.
## Presentation commands are forwarded; this VM does not draw or play anything.

signal presenter_event(event: Dictionary)
signal text_glyph_requested(tile_id: int, source_cpu_address: int, event_index: int, glyph_index: int)
signal wait_started(wait_kind: String, ticks: int, event: Dictionary)
signal wait_completed(wait_kind: String, event: Dictionary)
signal cutscene_started(cutscene_id: int)
signal cutscene_finished(cutscene_id: int)
signal done(cutscene_id: int)
signal unsupported_opcode(event: Dictionary)
signal vm_error(message: String)
signal scheduler_tick_processed(tick_index: int, event_index: int, source_cpu_address: int)
signal screen_fade_palette_step_requested(event: Dictionary, level: int)
signal screen_off_clear_completed(event: Dictionary)

enum RunState {
	STOPPED,
	RUNNING,
	WAITING_TICKS,
	WAITING_INPUT,
	FINISHED,
	FAILED,
}

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const NES_A_PRESSED_EDGE := 0x80
const FC_YIELD_TICKS := 4
const SCREEN_ON_PRE_WAIT_TICKS := 2
const SCREEN_ON_FADE_LEVELS := 15
const MAX_EVENTS_PER_PUMP := 4096
const INITIAL_TEXT_SPEED := 8

const EXPECTED_MANIFEST_SHA256 := {
	1: "e596286e60d4ccfd01dcc3c03f5c48f911f236978b4896f68bff62e28a56765d",
	2: "fc943538831c90103b6fe91b2244de6a003489e254b95c5e8980234e895a5ebc",
	0x44: "95442a61b4c8c7a97781efe59ad9eb0ada544895076c46efeac405d0d282f6a7",
}
const EXPECTED_STREAM_SHA256 := {
	1: "acf2618fa8a93c9b25e9b91f803d69e9073a7aa670919d1b7c9d06320596926b",
	2: "2909bce2e1ef5f25c383b9fe7de8b2b226acf4f50e83b85d9a30d83d7de5affe",
	0x44: "f1c60b3e4f92dee044189bc94e89197439decab3881bb946f483e7899faa861b",
}
const EXPECTED_EVENT_COUNTS := {1: 222, 2: 45, 0x44: 12}

const CUTSCENE_MANIFESTS := {
	1: "res://assets/gameplay/rom_logic/kickoff_cutscene_01_events.json",
	2: "res://assets/gameplay/rom_logic/kickoff_cutscene_02_events.json",
	0x44: "res://assets/gameplay/rom_logic/kickoff_meeting_scene_44_events.json",
}
const CUTSCENE_NAMES := {
	1: "kickoff_cutscene_01",
	2: "kickoff_cutscene_02",
	0x44: "kickoff_meeting_scene_44",
}
const CUTSCENE_SOURCE_STARTS := {
	1: {"cpu": 0xA2A1, "file": 0x0062B1},
	2: {"cpu": 0xA626, "file": 0x006636},
	0x44: {"cpu": 0xBE84, "file": 0x00BE94},
}

const COMPACT_PAUSE_TICKS := {
	0xD8: 1,
	0xD9: 10,
	0xDA: 20,
	0xDB: 40,
	0xDC: 60,
	0xDD: 80,
	0xDE: 120,
	0xDF: 240,
}

const ALLOWED_EVENT_KINDS := [
	"animations",
	"background_1",
	"background_2",
	"clear_text",
	"compact_pause",
	"dialog_window",
	"exit",
	"fc_handler",
	"jump",
	"palette_command",
	"pause_frames",
	"screen_off_clear",
	"screen_on",
	"sound_command",
	"text_brightness_command",
	"text_base_ppu_address",
	"text_cursor_back",
	"text_speed",
	"text_tile_ids",
	"toggle_camera",
	"visual_flag",
	"visual_preset",
	"wait_for_input",
]

const VM_HANDLED_KINDS := [
	"compact_pause",
	"dialog_window",
	"exit",
	"fc_handler",
	"jump",
	"pause_frames",
	"screen_off_clear",
	"screen_on",
	"text_speed",
	"text_base_ppu_address",
	"text_tile_ids",
	"wait_for_input",
]

var state: RunState = RunState.STOPPED
var cutscene_id: int = 0
var scheduler_tick_index: int = 0
var current_event_index: int = -1
var current_source_address: int = 0
var text_speed: int = 0
var error_message: String = ""

var _events: Array = []
var _next_event_index: int = 0
var _active_event: Dictionary = {}
var _wait_kind: String = ""
var _wait_remaining: int = 0
var _text_tiles: Array = []
var _text_glyph_index: int = 0
var _screen_palette_level: int = 0


## Loads and validates one of the ROM-derived event streams, then dispatches
## immediate commands until the first source wait. `pressed_edges` supplied to
## advance_scheduler_tick() must contain NES newly-pressed bits, not held state.
func start_cutscene(requested_cutscene_id: int) -> bool:
	_reset_runtime_state()
	if not CUTSCENE_MANIFESTS.has(requested_cutscene_id):
		return _fail("Unsupported KICK OFF cutscene id: %d" % requested_cutscene_id)

	var manifest_path: String = CUTSCENE_MANIFESTS[requested_cutscene_id]
	var manifest_bytes := _read_resource_bytes(manifest_path)
	if manifest_bytes.is_empty():
		return _fail("Unable to read cutscene manifest: %s" % manifest_path)
	if _sha256(manifest_bytes) != str(EXPECTED_MANIFEST_SHA256[requested_cutscene_id]):
		return _fail("Cutscene manifest data hash mismatch for id %d" % requested_cutscene_id)
	var manifest_variant: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not manifest_variant is Dictionary:
		return _fail("Cutscene manifest is not a JSON object: %s" % manifest_path)
	var manifest: Dictionary = manifest_variant
	var loaded_events := _validate_manifest(requested_cutscene_id, manifest)
	if loaded_events.is_empty():
		if state != RunState.FAILED:
			return _fail("Cutscene manifest has no executable events: %s" % manifest_path)
		return false

	cutscene_id = requested_cutscene_id
	_events = loaded_events
	state = RunState.RUNNING
	cutscene_started.emit(cutscene_id)
	_pump_events()
	return state != RunState.FAILED


## Advances exactly one cooperative ROM scheduler tick. A wait-for-input
## resumes only when this call contains the NES A newly-pressed edge ($80).
func advance_scheduler_tick(pressed_edges: int = 0) -> void:
	if state != RunState.WAITING_TICKS and state != RunState.WAITING_INPUT:
		return
	scheduler_tick_index += 1

	if state == RunState.WAITING_INPUT:
		if (pressed_edges & NES_A_PRESSED_EDGE) != 0:
			_complete_wait()
	else:
		_wait_remaining -= 1
		if _wait_remaining <= 0:
			_complete_wait()

	scheduler_tick_processed.emit(scheduler_tick_index, current_event_index, current_source_address)


## Cancels playback and clears all source/runtime state.
func stop() -> void:
	_reset_runtime_state()


func is_running() -> bool:
	return state == RunState.RUNNING or state == RunState.WAITING_TICKS or state == RunState.WAITING_INPUT


## The supported E9/EA model uses one level for the two ROM fade counters.
## Callers may seed a source-owned helper only from this VM state.
func get_rom_modeled_fade_counters() -> Vector2i:
	return Vector2i(_screen_palette_level, _screen_palette_level)


func is_waiting() -> bool:
	return state == RunState.WAITING_TICKS or state == RunState.WAITING_INPUT


func _validate_manifest(requested_cutscene_id: int, manifest: Dictionary) -> Array:
	if str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256:
		_fail("Cutscene source ROM hash mismatch for id %d" % requested_cutscene_id)
		return []
	var expected_name := str(CUTSCENE_NAMES[requested_cutscene_id])
	if str(manifest.get("name", "")) != expected_name:
		_fail("Cutscene manifest name mismatch: expected %s" % expected_name)
		return []
	if manifest.get("event_boundaries_byte_verified", false) != true:
		_fail("Cutscene event boundaries are not marked byte-verified: %s" % expected_name)
		return []

	var resource_path := str(manifest.get("source_resource", ""))
	if not resource_path.begins_with("reference/rom_extract/gameplay/") or resource_path.contains(".."):
		_fail("Cutscene source resource path is outside the preserved gameplay extract")
		return []
	var stream := _read_resource_bytes("res://" + resource_path)
	if stream.is_empty():
		_fail("Unable to read preserved source stream: %s" % resource_path)
		return []
	var stream_hash := _sha256(stream)
	var expected_stream_hash: String = EXPECTED_STREAM_SHA256[requested_cutscene_id]
	if str(manifest.get("source_execution_stream_sha256", "")) != expected_stream_hash or stream_hash != expected_stream_hash:
		_fail("Cutscene execution-stream hash mismatch for id %d" % requested_cutscene_id)
		return []

	var cpu_range: Array = manifest.get("execution_stream_cpu_range", [])
	var file_range: Array = manifest.get("execution_stream_file_range", [])
	if cpu_range.size() != 2 or file_range.size() != 2:
		_fail("Cutscene source address ranges are malformed for id %d" % requested_cutscene_id)
		return []
	var source_start: Dictionary = CUTSCENE_SOURCE_STARTS[requested_cutscene_id]
	var cpu_base := int(source_start["cpu"])
	var file_base := int(source_start["file"])
	if _hex_to_int(str(cpu_range[0])) != cpu_base or _hex_to_int(str(file_range[0])) != file_base:
		_fail("Cutscene source start address mismatch for id %d" % requested_cutscene_id)
		return []
	var source_segments: Array = manifest.get("execution_segments", [])
	if source_segments.is_empty():
		if _hex_to_int(str(cpu_range[1])) != cpu_base + stream.size() - 1:
			_fail("Cutscene CPU range does not match stream size for id %d" % requested_cutscene_id)
			return []
		if _hex_to_int(str(file_range[1])) != file_base + stream.size():
			_fail("Cutscene file range does not match stream size for id %d" % requested_cutscene_id)
			return []
	elif not _validate_execution_segments(source_segments, stream, requested_cutscene_id):
		return []

	var events_variant: Variant = manifest.get("events", null)
	if not events_variant is Array:
		_fail("Cutscene event list is missing for id %d" % requested_cutscene_id)
		return []
	var events: Array = events_variant
	if events.size() != int(manifest.get("event_count", -1)) or events.size() != int(EXPECTED_EVENT_COUNTS[requested_cutscene_id]):
		_fail("Cutscene event count mismatch for id %d" % requested_cutscene_id)
		return []
	if events.is_empty():
		_fail("Cutscene event list is empty for id %d" % requested_cutscene_id)
		return []

	var expected_offset := 0
	for event_index in events.size():
		var event_variant: Variant = events[event_index]
		if not event_variant is Dictionary:
			_fail("Cutscene event %d is not an object" % event_index)
			return []
		var event: Dictionary = event_variant
		var kind := str(event.get("kind", ""))
		if not ALLOWED_EVENT_KINDS.has(kind):
			_fail("Unknown cutscene event kind '%s' at event %d" % [kind, event_index])
			return []
		if int(event.get("event_index", -1)) != event_index:
			_fail("Cutscene event index discontinuity at event %d" % event_index)
			return []
		if int(event.get("script_offset", -1)) != expected_offset:
			_fail("Cutscene byte-boundary discontinuity at event %d" % event_index)
			return []
		var expected_source := _source_address_for_offset(source_segments, expected_offset, cpu_base, file_base)
		if expected_source.is_empty():
			_fail("Cutscene source segment map has a gap at event %d" % event_index)
			return []
		if _numeric_or_hex(event.get("cpu_address", -1)) != int(expected_source["cpu"]):
			_fail("Cutscene CPU source address mismatch at event %d" % event_index)
			return []
		if _numeric_or_hex(event.get("file_offset", -1)) != int(expected_source["file"]):
			_fail("Cutscene file source address mismatch at event %d" % event_index)
			return []
		var raw_variant: Variant = event.get("raw_bytes", null)
		if not raw_variant is Array or raw_variant.is_empty():
			_fail("Cutscene event %d has no raw source bytes" % event_index)
			return []
		var raw_bytes := PackedByteArray()
		for byte_value in raw_variant:
			if int(byte_value) < 0 or int(byte_value) > 255:
				_fail("Cutscene event %d contains an invalid source byte" % event_index)
				return []
			raw_bytes.append(int(byte_value))
		if expected_offset + raw_bytes.size() > stream.size():
			_fail("Cutscene event %d extends past its source stream" % event_index)
			return []
		for byte_index in raw_bytes.size():
			if raw_bytes[byte_index] != stream[expected_offset + byte_index]:
				_fail("Cutscene event %d raw bytes differ from preserved source" % event_index)
				return []
		var normalized_hex := str(event.get("raw_hex", "")).replace(" ", "").to_lower()
		if normalized_hex != raw_bytes.hex_encode():
			_fail("Cutscene event %d raw_hex does not match raw_bytes" % event_index)
			return []
		if not _validate_event_payload(event, raw_bytes, event_index):
			return []
		expected_offset += raw_bytes.size()

	if expected_offset != stream.size():
		_fail("Cutscene event boundaries do not cover the source stream exactly")
		return []
	var last_event: Dictionary = events.back()
	if str(last_event.get("kind", "")) != "exit" or int(last_event.get("opcode", -1)) != 0xFF:
		_fail("Cutscene stream lacks its source FF terminator")
		return []
	if int(last_event["raw_bytes"][0]) != 0xFF:
		_fail("Cutscene terminal event does not preserve FF")
		return []
	for event_index in events.size() - 1:
		if str(events[event_index].get("kind", "")) == "exit":
			_fail("Cutscene stream contains an early terminator at event %d" % event_index)
			return []
	return events


func _validate_event_payload(event: Dictionary, raw_bytes: PackedByteArray, event_index: int) -> bool:
	var kind := str(event["kind"])
	match kind:
		"compact_pause":
			if raw_bytes.size() != 1 or not COMPACT_PAUSE_TICKS.has(raw_bytes[0]):
				return _fail("Invalid compact-pause opcode at event %d" % event_index)
			if int(event.get("ticks", -1)) != int(COMPACT_PAUSE_TICKS[raw_bytes[0]]):
				return _fail("Compact-pause duration mismatch at event %d" % event_index)
		"fc_handler":
			if raw_bytes.size() != 1 or raw_bytes[0] != 0xFC:
				return _fail("Invalid FC handler bytes at event %d" % event_index)
		"wait_for_input":
			if raw_bytes.size() != 1 or raw_bytes[0] != 0xEB:
				return _fail("Invalid EB wait bytes at event %d" % event_index)
		"pause_frames":
			if raw_bytes.size() != 2 or raw_bytes[0] != 0xF6 or int(event.get("frame_count_operand", -1)) != raw_bytes[1]:
				return _fail("Invalid F6 pause bytes at event %d" % event_index)
			if raw_bytes[1] == 0:
				return _fail("Zero-count F6 semantics are not verified (event %d)" % event_index)
		"text_speed":
			var arguments: Array = event.get("arguments", [])
			if raw_bytes.size() != 2 or raw_bytes[0] != 0xF2 or arguments.size() != 1 or int(arguments[0]) != raw_bytes[1]:
				return _fail("Invalid F2 text-speed bytes at event %d" % event_index)
		"text_tile_ids":
			var tile_ids: Array = event.get("tile_ids", [])
			if tile_ids.size() != raw_bytes.size():
				return _fail("Text tile byte count mismatch at event %d" % event_index)
			for tile_index in tile_ids.size():
				if int(tile_ids[tile_index]) != raw_bytes[tile_index] or raw_bytes[tile_index] >= 0xD8:
					return _fail("Invalid text tile byte at event %d" % event_index)
		"exit":
			if raw_bytes.size() != 1 or raw_bytes[0] != 0xFF:
				return _fail("Invalid FF terminator at event %d" % event_index)
	return true


func _validate_execution_segments(raw_segments: Array, stream: PackedByteArray,
		requested_cutscene_id: int) -> bool:
	var expected_stream_offset := 0
	for segment_index in raw_segments.size():
		var segment_variant: Variant = raw_segments[segment_index]
		if not segment_variant is Dictionary:
			return _fail("Cutscene %d execution segment %d is malformed" % [requested_cutscene_id, segment_index])
		var segment: Dictionary = segment_variant
		var range_variant: Variant = segment.get("execution_stream_offset_range", [])
		if not range_variant is Array or range_variant.size() != 2:
			return _fail("Cutscene %d execution segment %d has no offset range" % [requested_cutscene_id, segment_index])
		var start_offset := int(range_variant[0])
		var end_offset := int(range_variant[1])
		if start_offset != expected_stream_offset or end_offset <= start_offset or end_offset > stream.size():
			return _fail("Cutscene %d execution segments do not exactly cover the flattened stream" % requested_cutscene_id)
		var source_path := str(segment.get("source_resource", ""))
		if not source_path.begins_with("reference/rom_extract/gameplay/meeting_menu/") or source_path.contains(".."):
			return _fail("Cutscene %d execution segment points outside its preserved ROM source folder" % requested_cutscene_id)
		var source_bytes := _read_resource_bytes("res://" + source_path)
		var expected_bytes := stream.slice(start_offset, end_offset)
		if source_bytes.size() != end_offset - start_offset or source_bytes != expected_bytes:
			return _fail("Cutscene %d execution segment %d differs from its preserved source bytes" % [requested_cutscene_id, segment_index])
		if _sha256(source_bytes) != str(segment.get("sha256", "")):
			return _fail("Cutscene %d execution segment %d SHA-256 mismatch" % [requested_cutscene_id, segment_index])
		var cpu_start := _hex_to_int(str(segment.get("cpu_start", "")))
		var file_start := _hex_to_int(str(segment.get("file_start", "")))
		if cpu_start < 0 or file_start < 0:
			return _fail("Cutscene %d execution segment %d source address is malformed" % [requested_cutscene_id, segment_index])
		expected_stream_offset = end_offset
	if expected_stream_offset != stream.size():
		return _fail("Cutscene %d execution segments leave trailing stream bytes" % requested_cutscene_id)
	return true


func _source_address_for_offset(raw_segments: Array, stream_offset: int,
		cpu_base: int, file_base: int) -> Dictionary:
	if raw_segments.is_empty():
		return {"cpu": cpu_base + stream_offset, "file": file_base + stream_offset}
	for segment_variant in raw_segments:
		if not segment_variant is Dictionary:
			continue
		var segment: Dictionary = segment_variant
		var range_variant: Variant = segment.get("execution_stream_offset_range", [])
		if not range_variant is Array or range_variant.size() != 2:
			continue
		var start_offset := int(range_variant[0])
		var end_offset := int(range_variant[1])
		if stream_offset < start_offset or stream_offset >= end_offset:
			continue
		return {
			"cpu": _hex_to_int(str(segment.get("cpu_start", ""))) + stream_offset - start_offset,
			"file": _hex_to_int(str(segment.get("file_start", ""))) + stream_offset - start_offset,
		}
	return {}


func _pump_events() -> void:
	var budget := MAX_EVENTS_PER_PUMP
	while state == RunState.RUNNING and budget > 0:
		budget -= 1
		if _next_event_index >= _events.size():
			_fail("Cutscene stream ended without dispatching FF")
			return
		_active_event = _events[_next_event_index]
		current_event_index = int(_active_event["event_index"])
		current_source_address = int(_active_event["cpu_address"])
		var kind := str(_active_event["kind"])
		presenter_event.emit(_active_event.duplicate(true))
		if not VM_HANDLED_KINDS.has(kind):
			unsupported_opcode.emit(_active_event.duplicate(true))
		match kind:
			"screen_on":
				if int(_active_event.get("opcode", -1)) != 0xE9:
					_fail("Screen-on event is not backed by ROM opcode $E9.")
					return
				_begin_timed_wait("screen_on_pre_wait", SCREEN_ON_PRE_WAIT_TICKS)
				return
			"screen_off_clear":
				if int(_active_event.get("opcode", -1)) != 0xEA:
					_fail("Screen-off/clear event is not backed by ROM opcode $EA.")
					return
				_begin_timed_wait("screen_off_pre_wait", 1)
				return
			"compact_pause":
				_begin_timed_wait("compact_pause", int(_active_event["ticks"]))
				return
			"fc_handler":
				_begin_timed_wait("fc_handler", FC_YIELD_TICKS)
				return
			"pause_frames":
				_begin_timed_wait("pause_frames", int(_active_event["frame_count_operand"]))
				return
			"wait_for_input":
				_wait_kind = "wait_for_input"
				state = RunState.WAITING_INPUT
				wait_started.emit(_wait_kind, -1, _active_event.duplicate(true))
				return
			"text_speed":
				var arguments: Array = _active_event.get("arguments", [])
				text_speed = int(arguments[0])
				_advance_active_event()
			"text_tile_ids":
				if _begin_text_run(_active_event):
					return
			"exit":
				state = RunState.FINISHED
				cutscene_finished.emit(cutscene_id)
				done.emit(cutscene_id)
				return
			_:
				_advance_active_event()
	if budget == 0 and state == RunState.RUNNING:
		_fail("Cutscene command pump exceeded its event budget")


func _begin_text_run(event: Dictionary) -> bool:
	_text_tiles = event.get("tile_ids", []).duplicate()
	_text_glyph_index = 0
	if text_speed == 0:
		while _text_glyph_index < _text_tiles.size():
			_emit_text_glyph(event)
		_advance_active_event()
		return false
	_emit_text_glyph(event)
	_begin_wait("text_speed", text_speed, event)
	return true


func _emit_text_glyph(event: Dictionary) -> void:
	var glyph_index := _text_glyph_index
	var tile_id := int(_text_tiles[glyph_index])
	_text_glyph_index += 1
	text_glyph_requested.emit(tile_id, int(event["cpu_address"]), int(event["event_index"]), glyph_index)


func _begin_timed_wait(kind: String, ticks: int) -> void:
	_begin_wait(kind, ticks, _active_event)


func _begin_wait(kind: String, ticks: int, event: Dictionary) -> void:
	_wait_kind = kind
	_wait_remaining = ticks
	state = RunState.WAITING_TICKS
	wait_started.emit(kind, ticks, event.duplicate(true))


func _complete_wait() -> void:
	var completed_kind := _wait_kind
	var completed_event := _active_event.duplicate(true)
	wait_completed.emit(completed_kind, completed_event)
	_wait_kind = ""
	_wait_remaining = 0
	if completed_kind == "screen_on_pre_wait":
		if _screen_palette_level < SCREEN_ON_FADE_LEVELS:
			_screen_palette_level += 1
			screen_fade_palette_step_requested.emit(completed_event, _screen_palette_level)
			_begin_wait("screen_on_fade_up", 1, completed_event)
			return
	if completed_kind == "screen_on_fade_up":
		if _screen_palette_level < SCREEN_ON_FADE_LEVELS:
			_screen_palette_level += 1
			screen_fade_palette_step_requested.emit(completed_event, _screen_palette_level)
			_begin_wait("screen_on_fade_up", 1, completed_event)
			return
	if completed_kind == "screen_off_pre_wait":
		if _screen_palette_level > 0:
			_screen_palette_level -= 1
			screen_fade_palette_step_requested.emit(completed_event, _screen_palette_level)
			_begin_wait("screen_off_fade_down", 1, completed_event)
			return
		_finish_screen_off_clear(completed_event)
		return
	if completed_kind == "screen_off_fade_down":
		if _screen_palette_level > 0:
			_screen_palette_level -= 1
			screen_fade_palette_step_requested.emit(completed_event, _screen_palette_level)
			_begin_wait("screen_off_fade_down", 1, completed_event)
			return
		_finish_screen_off_clear(completed_event)
		return
	if completed_kind == "text_speed" and _text_glyph_index < _text_tiles.size():
		_emit_text_glyph(_active_event)
		_begin_wait("text_speed", text_speed, _active_event)
		return
	if completed_kind == "text_speed":
		_text_tiles.clear()
		_text_glyph_index = 0
	state = RunState.RUNNING
	_advance_active_event()
	_pump_events()


func _advance_active_event() -> void:
	_next_event_index += 1
	_active_event = {}
	current_event_index = _next_event_index - 1


func _finish_screen_off_clear(event: Dictionary) -> void:
	screen_off_clear_completed.emit(event.duplicate(true))
	state = RunState.RUNNING
	_advance_active_event()
	_pump_events()
	if current_event_index >= 0 and current_event_index < _events.size():
		current_source_address = int(_events[current_event_index]["cpu_address"]) + int(_events[current_event_index]["raw_bytes"].size())


func _read_resource_bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return bytes


func _sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _hex_to_int(value: String) -> int:
	var normalized := value.to_lower().trim_prefix("0x")
	return normalized.hex_to_int()


func _numeric_or_hex(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	return _hex_to_int(str(value))


func _fail(message: String) -> bool:
	error_message = message
	state = RunState.FAILED
	vm_error.emit(message)
	return false


func _reset_runtime_state() -> void:
	state = RunState.STOPPED
	cutscene_id = 0
	scheduler_tick_index = 0
	current_event_index = -1
	current_source_address = 0
	# Route RAM snapshots show $55=8 at frames 4708 (ID 1) and 8124 (ID 2).
	text_speed = INITIAL_TEXT_SPEED
	error_message = ""
	_events.clear()
	_next_event_index = 0
	_active_event.clear()
	_wait_kind = ""
	_wait_remaining = 0
	_screen_palette_level = 0
	_text_tiles.clear()
	_text_glyph_index = 0
