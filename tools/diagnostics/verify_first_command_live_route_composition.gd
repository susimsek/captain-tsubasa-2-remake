extends SceneTree
## Composes source-only scenario, task, scheduler, callback-table, and $8327
## helpers, then reports the first state boundary that blocks live integration.
## It never feeds trace RAM/PPU/cycle values into any source model.

const SCENARIO_READER := preload("res://scripts/gameplay/bank10_scenario_bytecode_reader.gd")
const PREFIX_MODEL := preload("res://tools/diagnostics/rom_first_command_callback_prefix_model.gd")
const TASK_MODEL := preload("res://tools/diagnostics/rom_gameplay_task_context_model.gd")
const SCHEDULER_MODEL := preload("res://tools/diagnostics/rom_gameplay_scheduler_scan_model.gd")
const ROOT_TASK_BOOTSTRAP_MODEL := preload("res://tools/diagnostics/rom_gameplay_root_task_bootstrap_model.gd")
const CALLBACK_API := preload("res://scripts/gameplay/rom_first_command_callback_dispatch_api.gd")

const ROM_PATH := "res://Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SCENARIO_ROOT := "res://reference/rom_extract/gameplay/first_command_scenarios/"
const TASK_ROOT := "res://reference/rom_extract/gameplay/task_context/"
const TRACE_ROOT := "res://reference/diagnostics/first_command_task_boundary_20261028_070655_utc/"
const TRACE_EVENT_SHA256 := "5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a"
const TRACE_WRITE_SHA256 := "c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22"
const BANK0B_FILE_BASE := 0x016010
const BANK0B_POINTER_TABLE_CPU := 0x87F6
const SCENARIO_ORDER := [0x35, 0x36, 0x1E, 0x44]

const CALLBACK_SOURCE_EXPECTATIONS := {
	0x3A: {"cpu": 0x89F3, "header": [0x02, 0x00, 0x42]},
	0x0C: {"cpu": 0x8911, "header": [0x02, 0x00, 0x43]},
	0x72: {"cpu": 0x8B3E, "header": [0xF2, 0x19, 0x00]},
	0x1F: {"cpu": 0x896A, "header": [0x02, 0x03, 0x00]},
	0x01: {"cpu": 0x88E3, "header": [0xF0, 0x02, 0x00]},
	0x45: {"cpu": 0x8A2A, "header": [0x06, 0x00, 0x36]},
	0x70: {"cpu": 0x8B38, "header": [0x06, 0x00, 0x56]},
}

var _failures: Array[String] = []
var _scenario_context_requirements: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rom := _load_verified_rom()
	if rom.is_empty():
		_finish()
		return
	var scenario_events := _decode_scenario_events(rom)
	if scenario_events.is_empty():
		_finish()
		return
	if not _verify_callback_sources(rom, scenario_events):
		_finish()
		return
	if not _verify_trace_selectors(scenario_events):
		_finish()
		return
	if not _verify_composed_boundary(rom):
		_finish()
		return

	print("PASS: ROM scenario records and callback selectors match both muted trace passes; root seeds derive slots $01/$05/$09 and select slot $01 for the first scheduler dispatch.")
	print("NOT INTEGRATED: the live route still does not execute the source task bodies/scheduler, so this diagnostic bootstrap does not advance the Godot route.")
	print("NEXT BLOCKERS: scenario $36/$1E context still requires $0441/player record/$0638 and $05FB; later `$8327` still needs prior `$05CD` plus callback worker/continuation state.")
	for requirement: String in _scenario_context_requirements:
		print("SCENARIO CONTEXT GAP: " + requirement)
	print("LIMIT: diagnostic only; no route integration, endpoint RAM/PPU input, replayed trace constants, holder coordinate, or RNG state was used.")
	_finish()


func _load_verified_rom() -> PackedByteArray:
	if not FileAccess.file_exists(ROM_PATH):
		_fail("Supplied ROM is missing.")
		return PackedByteArray()
	var rom := FileAccess.get_file_as_bytes(ROM_PATH)
	if _sha256(rom) != ROM_SHA256:
		_fail("Supplied ROM SHA-256 differs from the audited Turkish revision.")
		return PackedByteArray()
	return rom


func _decode_scenario_events(rom: PackedByteArray) -> Array[Dictionary]:
	var manifest_file := FileAccess.open(SCENARIO_ROOT + "manifest.json", FileAccess.READ)
	if manifest_file == null:
		_fail("Preserved scenario source manifest is missing.")
		return []
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	if String(manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		_fail("Scenario manifest names another ROM revision.")
		return []
	var result: Array[Dictionary] = []
	for scenario_id: int in SCENARIO_ORDER:
		var entry := _find_scenario_entry(manifest, scenario_id)
		if entry.is_empty():
			_fail("Scenario manifest omits route scenario $%02X." % scenario_id)
			return []
		var file_path: String = String(entry.get("path", ""))
		var source: PackedByteArray = FileAccess.get_file_as_bytes("res://" + file_path)
		var file_offset := _hex(String(entry.get("file_offset", "")))
		var length := int(entry.get("length_bytes", -1))
		if source.size() != length or _sha256(source) != String(entry.get("sha256", "")):
			_fail("Scenario $%02X preserved stream failed its manifest length/hash check." % scenario_id)
			return []
		if file_offset < 0 or file_offset + length > rom.size():
			_fail("Scenario $%02X manifest offset is outside the supplied ROM." % scenario_id)
			return []
		for index in range(length):
			if source[index] != rom[file_offset + index]:
				_fail("Scenario $%02X preserved bytes differ from the supplied ROM." % scenario_id)
				return []

		var parsed: Dictionary = SCENARIO_READER.read_project_scenario(scenario_id,
			{"continuation_depth": 0})
		if int(parsed.get("terminal_status", -1)) != SCENARIO_READER.ParseStatus.SOURCE_TERMINATED:
			_fail("Scenario $%02X did not reach its hash-checked root terminator." % scenario_id)
			return []
		for requirement: String in parsed.get("context_requirements", []):
			_scenario_context_requirements.append("scenario $%02X: %s" % [scenario_id, requirement])
		var records: Array[Dictionary] = []
		for token: Dictionary in parsed.get("tokens", []):
			if token.get("kind", "") != "event_record":
				continue
			var raw: PackedByteArray = token.get("raw_bytes", PackedByteArray())
			if raw.size() != 4:
				_fail("Scenario $%02X yielded a malformed four-byte event record." % scenario_id)
				return []
			records.append({
				"scenario_id": scenario_id,
				"byte_offset": int(token.get("byte_offset", -1)),
				"callback_id": int(raw[1]),
				"actor_id_raw": int(raw[2]),
				"raw_bytes": raw,
			})
		result.append_array(records)
	return result


func _find_scenario_entry(manifest: Dictionary, scenario_id: int) -> Dictionary:
	var id_text := "$%02X" % scenario_id
	for entry: Dictionary in manifest.get("scenario_streams", []):
		if String(entry.get("scenario_id", "")) == id_text:
			return entry
	return {}


func _verify_callback_sources(rom: PackedByteArray,
		scenario_events: Array[Dictionary]) -> bool:
	var unique_ids: Dictionary = {}
	for event: Dictionary in scenario_events:
		unique_ids[int(event["callback_id"])] = true
	for callback_id: int in unique_ids:
		if not CALLBACK_SOURCE_EXPECTATIONS.has(callback_id):
			_fail("No byte-audited callback pointer expectation is recorded for selector $%02X." % callback_id)
			return false
		var table_file := BANK0B_FILE_BASE + (BANK0B_POINTER_TABLE_CPU - 0x8000)
		var pointer_offset := table_file + 2 * callback_id
		if pointer_offset + 1 >= rom.size():
			_fail("Callback selector $%02X points outside the supplied ROM table." % callback_id)
			return false
		var target := int(rom[pointer_offset]) | (int(rom[pointer_offset + 1]) << 8)
		var expected: Dictionary = CALLBACK_SOURCE_EXPECTATIONS[callback_id]
		if target != int(expected["cpu"]):
			_fail("Callback selector $%02X resolves to unexpected ROM pointer $%04X." % [callback_id, target])
			return false
		var stream_offset := BANK0B_FILE_BASE + target - 0x8000
		var expected_header := PackedByteArray(expected["header"])
		if stream_offset < 0 or stream_offset + expected_header.size() > rom.size() \
				or rom.slice(stream_offset, stream_offset + expected_header.size()) != expected_header:
			_fail("Callback selector $%02X stream header differs from its ROM source." % callback_id)
			return false
	return true


func _verify_trace_selectors(expected_events: Array[Dictionary]) -> bool:
	var validation_file := FileAccess.open(TRACE_ROOT + "validation.json", FileAccess.READ)
	if validation_file == null:
		_fail("The retained task-boundary two-pass validation record is missing.")
		return false
	var validation: Dictionary = JSON.parse_string(validation_file.get_as_text())
	if int(validation.get("checkpoint_frame", -1)) != 8399 \
			or int(validation.get("replays", 0)) != 2 \
			or not bool(validation.get("checkpoint_signature_verified_after_both_loads", false)) \
			or String(validation.get("normalized_event_sha256", "")) != TRACE_EVENT_SHA256 \
			or String(validation.get("normalized_write_sha256", "")) != TRACE_WRITE_SHA256:
		_fail("Task-boundary trace metadata does not match the retained two-pass checkpoint audit.")
		return false
	var first := _callback_trace_projection(TRACE_ROOT + "task_events.csv")
	var second := _callback_trace_projection(TRACE_ROOT + "task_events_repeat.csv")
	if first.is_empty() or second.is_empty():
		_fail("One of the retained task-boundary callback trace passes is missing or empty.")
		return false
	if first != second:
		_fail("Callback selector observations differ between the two trace passes.")
		return false
	if first.size() != expected_events.size():
		_fail("Trace contains %d callback reads; the source scenario streams contain %d event records." % [first.size(), expected_events.size()])
		return false
	for index in expected_events.size():
		var wanted: Dictionary = expected_events[index]
		var observed: Dictionary = first[index]
		if int(observed["scenario_id"]) != int(wanted["scenario_id"]) \
				or int(observed["callback_id"]) != int(wanted["callback_id"]):
			_fail("Trace callback record %d differs from the byte-decoded scenario sequence." % index)
			return false
	return true


func _callback_trace_projection(path: String) -> Array[Dictionary]:
	var rows := _read_csv(path)
	var result: Array[Dictionary] = []
	for row: Dictionary in rows:
		if row.get("kind", "") != "callback_read_814C":
			continue
		var scenario_fields := _parse_hex_bytes(String(row.get("scenario_0516_0518", "")))
		var record_fields := _parse_hex_bytes(String(row.get("record_fields_0523_0529", "")))
		if scenario_fields.size() < 2 or record_fields.size() < 2:
			return []
		result.append({
			"scenario_id": scenario_fields[1],
			"callback_id": record_fields[1],
		})
	return result


func _verify_composed_boundary(rom: PackedByteArray) -> bool:
	if not _has_scenario_context("scenario $36", "$FD $00 at +0x000F") \
			or not _has_scenario_context("scenario $1E", "$FD $02 at +0x0000"):
		_fail("The composed scenario reader did not expose its first route context requirements.")
		return false
	# The stack argument is a test-only sentinel to prove a depth-zero root `$FB`
	# leaves caller-owned bytes untouched. It is not reused by another component.
	var prefix_model: RefCounted = PREFIX_MODEL.new()
	var prefix_fixture := PackedByteArray([0xA5, 0x5A, 0xC3, 0x3C, 0x96, 0x69, 0xF0, 0x0F])
	var prefix: Dictionary = prefix_model.call("resolve_scenario44_callback_prefix", prefix_fixture)
	if not bool(prefix.get("ok", false)) or not bool(prefix.get("scenario", {}).get("stack_payload_preserved", false)):
		_fail("Source-only scenario-$44/callback prefix did not resolve within its diagnostic fixture.")
		return false
	if not bool(prefix.get("callback", {}).get("handler_cpu", -1) == 0x8327):
		_fail("Scenario-$44 prefix did not resolve callback selector $70 to $8327.")
		return false

	var task_spans := _load_task_context_spans(rom)
	if task_spans.is_empty():
		return false
	var task_model: RefCounted = TASK_MODEL.new()
	if not bool(task_model.call("configure", task_spans)):
		_fail("ROM-backed one-slot task model rejected its preserved spans: " + str(task_model.get("error_message")))
		return false
	var seeded_context: RefCounted = task_model.call("seed_scenario_callback_task")
	if seeded_context == null or int(seeded_context.get("slot_offset")) != 0x15 \
			or seeded_context.get("record").call("to_bytes") != PackedByteArray([0xFF, 0xF0, 0x0B, 0x00]):
		_fail("The source setup did not produce the known single slot-$15 seed.")
		return false

	var scheduler_model: RefCounted = SCHEDULER_MODEL.new()
	if not bool(scheduler_model.call("configure", task_spans["scheduler"])):
		_fail("Six-slot scheduler model rejected its preserved source: " + str(scheduler_model.get("error_message")))
		return false
	var scan_order: Array[int] = scheduler_model.call("slot_bases")

	var bootstrap_spans := _load_source_span_set(rom,
		ROOT_TASK_BOOTSTRAP_MODEL.source_span_specs(), "root-task bootstrap")
	if bootstrap_spans.is_empty():
		return false
	var bootstrap_model: RefCounted = ROOT_TASK_BOOTSTRAP_MODEL.new()
	if not bool(bootstrap_model.call("configure", bootstrap_spans)):
		_fail("ROM root-task bootstrap model rejected its preserved spans: " + str(bootstrap_model.get("error_message")))
		return false
	var bootstrap_state: Dictionary = bootstrap_model.call("derive_bootstrap")
	if not bool(bootstrap_state.get("ok", false)):
		_fail("ROM root-task bootstrap did not derive source task state: " + str(bootstrap_model.get("error_message")))
		return false
	var initial_ready := PackedByteArray([0, 0, 0, 0, 0, 0])
	for task_variant in bootstrap_state.get("root_tasks", []):
		if not task_variant is Dictionary:
			_fail("Root bootstrap returned a malformed task record.")
			return false
		var task: Dictionary = task_variant
		var slot_base := int(task.get("slot", -1))
		var slot_index := scan_order.find(slot_base)
		var record: PackedByteArray = task.get("record", PackedByteArray())
		if slot_index < 0 or record.size() != 4:
			_fail("Root bootstrap task does not map onto one of the six scheduler records.")
			return false
		initial_ready[slot_index] = int(record[0])
	var initial_scan: Dictionary = scheduler_model.call("scan_once", initial_ready,
		int(bootstrap_state.get("latch_001b", 0)))
	if int(initial_scan.get("decision", -1)) != SCHEDULER_MODEL.Decision.INITIAL_DISPATCH \
			or int(initial_scan.get("selected_slot_base", -1)) != 0x01:
		_fail("ROM-derived root tasks do not select slot `$01` at the first scheduler scan.")
		return false

	var callback_api: RefCounted = CALLBACK_API.new()
	var callback: Dictionary = callback_api.call("resolve_scenario_44_callback")
	if not bool(callback.get("ok", false)):
		_fail("Callback-$70 source table did not resolve: " + str(callback.get("error", "")))
		return false
	var no_placement_input: Dictionary = callback_api.call("compute_8327_placement_transition", -1)
	if bool(no_placement_input.get("ok", true)) \
			or String(no_placement_input.get("status", "")) != "source_state_required" \
			or String(no_placement_input.get("required_input", "")) != "$05CD immediately before bank-$0B $8327":
		_fail("The placement API did not identify caller-owned `$05CD` as the next required input.")
		return false
	return true


func _has_scenario_context(scenario_prefix: String, requirement_prefix: String) -> bool:
	for requirement: String in _scenario_context_requirements:
		if requirement.begins_with(scenario_prefix + ": ") \
				and requirement.contains(requirement_prefix):
			return true
	return false


func _load_task_context_spans(rom: PackedByteArray) -> Dictionary:
	return _load_source_span_set(rom, TASK_MODEL.source_span_specs(), "task-context")


func _load_source_span_set(rom: PackedByteArray, specs: Dictionary, label: String) -> Dictionary:
	var manifest_file := FileAccess.open(TASK_ROOT + "manifest.json", FileAccess.READ)
	if manifest_file == null:
		_fail("Task-context source manifest is missing for %s." % label)
		return {}
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		_fail("Task-context manifest names another ROM revision for %s." % label)
		return {}
	var by_file: Dictionary = {}
	for entry: Dictionary in manifest.get("spans", []):
		by_file[String(entry.get("file", ""))] = entry
	var result: Dictionary = {}
	for key: String in specs:
		var spec: Dictionary = specs[key]
		var file_name: String = String(spec["path"]).get_file()
		if not by_file.has(file_name):
			_fail("Task-context manifest omits %s." % file_name)
			return {}
		var entry: Dictionary = by_file[file_name]
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(String(spec["path"]))
		var offset: int = int(spec["offset"])
		var length: int = int(spec["length"])
		if bytes.size() != length or _sha256(bytes) != String(spec["sha256"]) \
				or String(entry.get("sha256", "")) != String(spec["sha256"]) \
				or int(entry.get("length", -1)) != length \
				or String(entry.get("file_offset", "")) != "0x%06X" % offset:
			_fail("Task-context span %s failed manifest/hash provenance for %s." % [file_name, label])
			return {}
		for index in length:
			if bytes[index] != rom[offset + index]:
				_fail("Task-context span %s differs from the supplied ROM for %s." % [file_name, label])
				return {}
		result[key] = bytes
	return result


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.is_empty() or values.size() != headers.size():
			continue
		var row: Dictionary = {}
		for index in range(headers.size()):
			row[headers[index]] = values[index]
		rows.append(row)
	return rows


func _parse_hex_bytes(value: String) -> Array[int]:
	var result: Array[int] = []
	for item: String in value.split(" ", false):
		result.append(item.trim_prefix("$").hex_to_int())
	return result


func _hex(value: String) -> int:
	return value.trim_prefix("0x").hex_to_int()


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message: String in _failures:
		printerr("FAIL: " + message)
	quit(1)
