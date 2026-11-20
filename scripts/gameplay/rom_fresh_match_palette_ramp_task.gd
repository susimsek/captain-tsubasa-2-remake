extends RefCounted
class_name RomFreshMatchPaletteRampTask
## Runs the source-backed $997A match-palette ramp, yielding through the
## existing bounded $A000 packet consumer once per ROM $9FA8 wait.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const ROOT := "res://reference/rom_extract/gameplay/fresh_kickoff_a503/"
const MANIFEST_PATH := ROOT + "manifest.json"
const MAPPER_HELPER_SCRIPT := preload("res://scripts/gameplay/rom_fixed_mapper_select_helper.gd")
const SPECIAL_NMI_EXECUTOR_SCRIPT := preload("res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd")
const ITERATION_LIMIT := 15
const PALETTE_BUFFER := 0x062A
const UPDATE_QUEUE := 0x05E8
const QUEUE_CURSOR := 0x0628
const QUEUE_CONTROL := 0x0629

const SPAN_SPECS := {
	"bank06_match_palette_ramp_source_B040_B050.bin": {
		"start": "$B040", "end": "$B050", "offset": "0x00D050", "bank": "$06",
		"length": 16, "sha256": "c51fe488692967f8f23c855b6509b5849cf667e66742a26c7ffbe5df0481c4ff",
	},
	"bank06_match_palette_ramp_source_B370_B380.bin": {
		"start": "$B370", "end": "$B380", "offset": "0x00D380", "bank": "$06",
		"length": 16, "sha256": "150799fde48c92af98f99041f6214d03d63bbd064e83c72c2068132d34ccd957",
	},
	"bank00_match_palette_ramp_997A_99AE.bin": {
		"start": "$997A", "end": "$99AE", "offset": "0x00198A", "bank": "$00",
		"length": 52, "sha256": "a093deb6860ffdfcef31ee67ef56bf544433c37472192b8fdd4170550ad3ddf8",
	},
	"bank00_match_palette_buffer_copy_9AB8_9B07.bin": {
		"start": "$9AB8", "end": "$9B07", "offset": "0x001AC8", "bank": "$00",
		"length": 79, "sha256": "dcc3d3197e7c9418325d14332c97d65437b45e150c0d55739efddb4d1a59d639",
	},
	"bank00_match_palette_bank_select_9B07_9B11.bin": {
		"start": "$9B07", "end": "$9B11", "offset": "0x001B17", "bank": "$00",
		"length": 10, "sha256": "2f3885476925a6902b67428ff471d12e3f3006aaf92cc87c82ab060f48e4f707",
	},
	"bank00_match_palette_transform_9A71_9AB8.bin": {
		"start": "$9A71", "end": "$9AB8", "offset": "0x001A81", "bank": "$00",
		"length": 71, "sha256": "dd544a728f87bd8795ca241fef9640a4114fe3ba22b6a79ae11f3eac17fddb01",
	},
	"bank00_match_palette_lookup_9EA2_9EE2.bin": {
		"start": "$9EA2", "end": "$9EE2", "offset": "0x001EB2", "bank": "$00",
		"length": 64, "sha256": "8b6a7afaf8ffbffa5f9a87f297bcd0f2d9308cce31a1704639f6148ec834cb4b",
	},
}

var error_message := ""
var _configured := false
var _table_a := PackedByteArray()
var _table_b := PackedByteArray()
var _lookup := PackedByteArray()
var _state: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The A503 palette-ramp manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The A503 palette-ramp manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if String(manifest.get("schema", "")) != "ct2-fresh-match-a503-entry-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The A503 palette-ramp manifest targets another ROM revision.")
	var entries: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries[String(entry.get("file", ""))] = entry
	var loaded: Dictionary = {}
	for file_name: String in SPAN_SPECS:
		var spec: Dictionary = SPAN_SPECS[file_name]
		if not entries.has(file_name):
			return _fail("The A503 palette-ramp manifest omits %s." % file_name)
		var entry: Dictionary = entries[file_name]
		if String(entry.get("cpu_start", "")) != String(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != String(spec["end"]) \
				or String(entry.get("file_offset", "")) != String(spec["offset"]) \
				or String(entry.get("bank", "")) != String(spec["bank"]) \
				or int(entry.get("length", -1)) != int(spec["length"]) \
				or String(entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("A503 palette-ramp provenance differs for %s." % file_name)
		var bytes := FileAccess.get_file_as_bytes(ROOT + file_name)
		if bytes.size() != int(spec["length"]) or _sha256(bytes) != String(spec["sha256"]) \
				or String(entry.get("bytes", "")) != bytes.hex_encode():
			return _fail("A503 palette-ramp source failed its size/hash/byte check: %s." % file_name)
		loaded[file_name] = bytes
	_table_a = loaded["bank06_match_palette_ramp_source_B040_B050.bin"]
	_table_b = loaded["bank06_match_palette_ramp_source_B370_B380.bin"]
	_lookup = loaded["bank00_match_palette_lookup_9EA2_9EE2.bin"]
	var mapper_helper: Variant = MAPPER_HELPER_SCRIPT.new()
	if not mapper_helper.configure_from_project_sources():
		return _fail("The $997A caller's $C4B9 mapper helper failed verification: " + mapper_helper.error_message)
	_configured = true
	return true


## Starts at the source caller's $A56C -> $997A JSR. Source RAM is supplied by
## the route's provenance ledger; no emulator snapshot is accepted as input.
func begin(text_setup_result: Dictionary, source_ram_status: Dictionary,
		cleanup_fade_status: Dictionary, source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(text_setup_result.get("ok", false)) \
			or String(text_setup_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(text_setup_result.get("status", "")) != "stopped_before_a503_fade_helper" \
			or bool(text_setup_result.get("trace_state_used", true)) \
			or bool(text_setup_result.get("emulator_data_used", true)):
		return _refused("The ROM text setup must return to $A56C without trace-derived state.")
	var cpu: Dictionary = text_setup_result.get("next_cpu_state", {})
	if int(cpu.get("pc", -1)) != 0xA56C or int(cpu.get("a", -1)) != 0x04 \
			or int(cpu.get("x", -1)) != 0x37 or int(cpu.get("y", -1)) != 0x07:
		return _refused("The $A56C caller register contract does not match the checked $997A callsite.")
	if source_frame < 0 or not bool(cleanup_fade_status.get("configured", false)) \
			or String(cleanup_fade_status.get("state", "")) != "returned" \
			or int(cleanup_fade_status.get("counter_a", -1)) != 0 \
			or int(cleanup_fade_status.get("counter_b", -1)) != 0:
		return _refused("The previous source cleanup must have returned with its paired $004A/$004B counters at zero.")
	var known_values: Variant = source_ram_status.get("known_values", {})
	if not known_values is Dictionary:
		return _refused("The $997A caller needs the source RAM ledger's known bytes.")
	var ram: Dictionary = known_values.duplicate(true)
	for address_variant in text_setup_result.get("ram_after", {}):
		ram[int(address_variant)] = text_setup_result["ram_after"][address_variant]
	for address in [0x0022, 0x0025, 0x004A, 0x004B, 0x05E8, 0x0628, 0x0629]:
		if not ram.has(address):
			return _refused("The $997A source continuation lacks RAM `$%04X`." % address)
	if int(ram[0x0022]) < 0 or int(ram[0x0022]) > 0xFF \
			or int(ram[0x0025]) != 0x01 \
			or int(ram[0x004A]) != 0 or int(ram[0x004B]) != 0 \
			or int(ram[0x0628]) != 0x14 or int(ram[0x0629]) != 0x82:
		return _refused("The source bank, zero fade counters, or final A503 queue differs from the checked route state ($22=$%02X, $25=$%02X, $4A/$4B=$%02X/$%02X, $0628/$0629=$%02X/$%02X)." % [
			int(ram[0x0022]) & 0xFF, int(ram[0x0025]) & 0xFF,
			int(ram[0x004A]) & 0xFF, int(ram[0x004B]) & 0xFF,
			int(ram[0x0628]) & 0xFF, int(ram[0x0629]) & 0xFF])
	var cursor := int(ram[0x0628])
	if not _has_queue_terminator(ram, cursor):
		return _refused("The four pending A503 text records have no source queue terminator.")
	var writes: Array[Dictionary] = []
	var mapper_bus_writes: Array[Dictionary] = []
	var source_path: Array[int] = [0xA56C, 0x997A, 0x997C, 0x997E, 0x9B07, 0x9B09, 0x9B0B, 0xC4B9, 0xC4BF]
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x997A, 0x0048, 0x04)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x997C, 0x0049, 0x37)
	var mode_bits := int(ram[0x0022])
	var prior_bank := int(ram[0x0025])
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B09, 0x00E9, prior_bank)
	_apply_bank_select(ram, writes, mapper_bus_writes, "fresh_match_a503_palette_ramp", 0x06, mode_bits)
	for index in 16:
		_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9AFD,
			PALETTE_BUFFER + index, int(_table_a[index]))
	for index in 16:
		_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9AFD,
			PALETTE_BUFFER + 16 + index, int(_table_b[index]))
	_apply_bank_select(ram, writes, mapper_bus_writes, "fresh_match_a503_palette_ramp", prior_bank, mode_bits)
	_state = {
		"ram_after": ram,
		"counter_a": int(ram[0x004A]),
		"counter_b": int(ram[0x004B]),
		"iterations": 0,
		"source_frame": source_frame,
		"queue_drains": [],
		"source_path": source_path,
		"mapper_bus_writes": mapper_bus_writes,
		"pending_yield": false,
	}
	var stage := _stage_palette_step(source_frame, writes)
	if not bool(stage.get("ok", false)):
		return _refused(String(stage.get("error", "The first ROM palette iteration failed.")))
	_state["pending_yield"] = true
	_state["ram_after"] = ram
	return _result("waiting_for_a503_palette_ramp_nmi", writes, [], source_frame,
		{"cpu": {"pc": 0x9FA8, "a": 0x01}, "palette_step": 1})


## Resume once the ROM's cooperative $9FA8 yield has exposed the queued PPU
## packet to the next frame-level NMI. Repeated calls are strictly frame-ordered.
func advance_source_tick(source_frame: int, ppu_shadow_input: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if _state.is_empty() or not bool(_state.get("pending_yield", false)):
		return _refused("The $997A palette task has no pending $9FA8 continuation.")
	if source_frame <= int(_state.get("source_frame", -1)):
		return _refused("The $997A continuation requires a later source frame.")
	if not bool(ppu_shadow_input.get("ok", false)):
		return _refused("The bounded $A000 drain needs source-owned PPU shadow bytes.")
	var writes: Array[Dictionary] = []
	var events: Array[Dictionary] = []
	var drain_history: Array[Dictionary] = []
	var ram: Dictionary = _state["ram_after"].duplicate(true)
	var drain_id := "fresh_match_a503_palette_ramp_%02d_drain" % int(_state["iterations"])
	var palette_payload: PackedByteArray = _state.get("last_palette_payload", PackedByteArray())
	var nmi_executor: Variant = SPECIAL_NMI_EXECUTOR_SCRIPT.new()
	if not nmi_executor.configure_from_project_sources():
		return _refused("The bounded $A000 packet consumer failed verification: " + nmi_executor.error_message)
	var drain: Dictionary = nmi_executor.execute_source_ppu_packet_queue(
		_queue_ram_values(ram), ppu_shadow_input, source_frame, drain_id)
	if not bool(drain.get("ok", false)):
		return _refused("The ROM $A000 packet consumer rejected the $997A queue: " + String(drain.get("error", "unknown error")))
	for write_variant in drain.get("ram_writes", []):
		if not write_variant is Dictionary:
			return _refused("The bounded $A000 consumer returned a malformed RAM write.")
		var item: Dictionary = write_variant
		var address := int(item.get("address", -1))
		var value := int(item.get("value", -1))
		if address < 0 or address >= 0x800 or value < 0 or value > 0xFF:
			return _refused("The bounded $A000 consumer returned an invalid RAM write.")
		ram[address] = value
		writes.append(_write_receipt(drain_id, int(item.get("source_pc", -1)), address, value))
	for event_variant in drain.get("ppu_bus_events", []):
		if event_variant is Dictionary:
			events.append(event_variant.duplicate(true))
	drain_history.append({
		"producer_source_frame": int(_state.get("source_frame", -1)),
		"consumer_source_frame": source_frame,
		"queue_cursor_before": int(drain.get("queue_ram_before", {}).get("cursor", -1)),
		"palette_payload_writes": 32,
		"palette_payload_hex": palette_payload.hex_encode(),
		"ppu_bus_events": events.duplicate(true),
		"bounded_queue_only": true,
		"surrounding_nmi_executed": false,
	})
	_state["queue_drains"].append(drain_history.back().duplicate(true))
	_state["ram_after"] = ram
	_state["source_frame"] = source_frame
	_state["pending_yield"] = false
	if int(_state.get("counter_a", 0)) + int(_state.get("counter_b", 0)) >= 0x1E:
		var source_path: Array = _state.get("source_path", []).duplicate()
		source_path.append_array([0x99A4, 0x99A6, 0x99A7, 0x99A9, 0x99AB, 0x99AD,
			0xA56F, 0xA571])
		_state["source_path"] = source_path
		var cpu := {"pc": 0xA571, "a": 0x1E, "x": 0xF0, "y": 0x20}
		return _result("returned_to_a503_wait_loop", writes, events, source_frame,
			{"cpu": cpu, "iterations": int(_state["iterations"])})
	var step := _stage_palette_step(source_frame, writes)
	if not bool(step.get("ok", false)):
		return _refused(String(step.get("error", "ROM palette step failed.")))
	_state["pending_yield"] = true
	_state["source_frame"] = source_frame
	_state["ram_after"] = ram
	return _result("waiting_for_a503_palette_ramp_nmi", writes, events, source_frame,
		{"cpu": {"pc": 0x9FA8, "a": 0x01}, "palette_step": int(_state["iterations"])})


func get_status() -> Dictionary:
	return {
		"configured": _configured,
		"state": "waiting_for_nmi" if bool(_state.get("pending_yield", false)) else "returned" if not _state.is_empty() else "unstarted",
		"iterations": int(_state.get("iterations", 0)),
		"counter_a": int(_state.get("counter_a", 0)),
		"counter_b": int(_state.get("counter_b", 0)),
		"source_frame": int(_state.get("source_frame", -1)),
		"queue_drain_count": _state.get("queue_drains", []).size(),
		"source_rom_sha256": ROM_SHA256,
	}


func _stage_palette_step(source_frame: int, writes: Array[Dictionary]) -> Dictionary:
	if int(_state.get("iterations", 0)) >= ITERATION_LIMIT:
		return {"ok": false, "error": "The source $997A loop exceeded its paired-counter bound."}
	var ram: Dictionary = _state["ram_after"]
	var counter_a := int(_state.get("counter_a", 0))
	var counter_b := int(_state.get("counter_b", 0))
	if counter_a < 0x0F:
		counter_a += 1
		_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9992, 0x004A, counter_a)
	if counter_b < 0x0F:
		counter_b += 1
		_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x999A, 0x004B, counter_b)
	var cursor := int(ram.get(QUEUE_CURSOR, -1))
	var control := int(ram.get(QUEUE_CONTROL, -1))
	if cursor < 0 or cursor >= 0x40 or control < 0 or control > 0xFF \
			or (control & 0x40) != 0 or cursor + 0x20 >= 0x3D:
		return {"ok": false, "error": "ROM $9B28 would yield for queue capacity; this continuation lacks a separate capacity-wait phase."}
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B44, QUEUE_CONTROL, 0x60)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B4B, UPDATE_QUEUE + cursor + 2, 0x3F)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B50, UPDATE_QUEUE + cursor + 1, 0x00)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B57, UPDATE_QUEUE + cursor, 0x20)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B57, QUEUE_CONTROL, 0x20)
	var palette_payload := PackedByteArray()
	for index in 32:
		var source_value := int(ram.get(PALETTE_BUFFER + index, -1))
		if source_value < 0 or source_value > 0xFF:
			return {"ok": false, "error": "ROM $9A71 lacks palette RAM byte `$%04X`." % (PALETTE_BUFFER + index)}
		var counter := counter_a if index < 16 else counter_b
		var lut_index := (source_value & 0x30) + counter
		if lut_index < 0 or lut_index >= _lookup.size():
			return {"ok": false, "error": "ROM $9AA2 LUT index escaped the checked 64-byte table."}
		var converted := int(_lookup[lut_index]) | (source_value & 0x0F)
		palette_payload.append(converted)
		_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9AA3, 0x00E6, int(_lookup[lut_index]))
		_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9AB1, UPDATE_QUEUE + cursor + 3 + index, converted)
	var new_cursor := cursor + 3 + palette_payload.size()
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B5E, UPDATE_QUEUE + new_cursor, 0x00)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B63, QUEUE_CURSOR, new_cursor)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9B6B, QUEUE_CONTROL, 0x20)
	_ram_store(ram, writes, "fresh_match_a503_palette_ramp", 0x9FA8, 0x0019, 0x01)
	_state["counter_a"] = counter_a
	_state["counter_b"] = counter_b
	_state["iterations"] = int(_state.get("iterations", 0)) + 1
	var source_path: Array = _state.get("source_path", []).duplicate()
	source_path.append_array([0x998C, 0x998E, 0x9990, 0x9992, 0x9994, 0x9996,
		0x9998, 0x999A, 0x999C, 0x9A71, 0x9A77, 0x9B28, 0x9B37,
		0x9B41, 0x9B44, 0x9B4B, 0x9B50, 0x9B57, 0x9A7E,
		0x9A84, 0x9AA2, 0x9AA3, 0x9AA6, 0x9AAF, 0x9AB1, 0x9B5E, 0x9FA8])
	_state["source_path"] = source_path
	_state["last_palette_payload"] = palette_payload
	return {"ok": true, "status": "yielded_after_palette_step", "source_frame": source_frame,
		"iterations": int(_state["iterations"]), "counter_a": counter_a, "counter_b": counter_b,
		"palette_payload": palette_payload, "queue_cursor": new_cursor}


func _apply_bank_select(ram: Dictionary, writes: Array[Dictionary], bus_writes: Array[Dictionary],
		event_id: String, bank: int, mode_bits: int) -> void:
	var select_value := 0x07 | mode_bits
	_ram_store(ram, writes, event_id, 0xC4B9, 0x0025, bank)
	_ram_store(ram, writes, event_id, 0xC4BF, 0x0023, select_value)
	bus_writes.append({"source_pc": 0xC4C1, "address": 0x8000, "value": select_value})
	bus_writes.append({"source_pc": 0xC4C4, "address": 0x8001, "value": bank})


func _result(status: String, writes: Array[Dictionary], events: Array[Dictionary],
		source_frame: int, details: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"kind": "rom_fresh_match_a503_palette_ramp",
		"status": status,
		"source_rom_sha256": ROM_SHA256,
		"source_frame": source_frame,
		"iterations": int(_state.get("iterations", 0)),
		"counter_a": int(_state.get("counter_a", 0)),
		"counter_b": int(_state.get("counter_b", 0)),
		"ram_writes": writes.duplicate(true),
		"ram_after": _state.get("ram_after", {}).duplicate(true),
		"ppu_bus_events": events.duplicate(true),
		"queue_drain_history": _state.get("queue_drains", []).duplicate(true),
		"source_path": _state.get("source_path", []).duplicate(),
		"mapper_bus_writes": _state.get("mapper_bus_writes", []).duplicate(true),
		"details": details.duplicate(true),
		"trace_state_used": false,
		"emulator_data_used": false,
		"physical_nes_timing_proven": false,
	}


func _queue_ram_values(ram_values: Dictionary) -> Dictionary:
	var queue_values: Dictionary = {}
	var cursor := int(ram_values.get(QUEUE_CURSOR, -1))
	if cursor < 0 or cursor >= 0x40:
		return queue_values
	for address in range(0x0000, 0x0080):
		if ram_values.has(address):
			queue_values[address] = int(ram_values[address])
	for address in range(UPDATE_QUEUE, UPDATE_QUEUE + cursor + 1):
		if ram_values.has(address):
			queue_values[address] = int(ram_values[address])
	queue_values[QUEUE_CURSOR] = cursor
	queue_values[QUEUE_CONTROL] = int(ram_values.get(QUEUE_CONTROL, -1))
	return queue_values


func _has_queue_terminator(ram: Dictionary, cursor: int) -> bool:
	return cursor >= 0 and cursor < 0x40 and ram.has(UPDATE_QUEUE + cursor) \
			and int(ram[UPDATE_QUEUE + cursor]) == 0


func _ram_store(ram: Dictionary, writes: Array[Dictionary], event_id: String,
		source_pc: int, address: int, value: int) -> void:
	value &= 0xFF
	ram[address] = value
	writes.append(_write_receipt(event_id, source_pc, address, value))


func _write_receipt(event_id: String, source_pc: int, address: int, value: int) -> Dictionary:
	return {"event_id": event_id, "source_pc": source_pc, "address": address,
		"value": value & 0xFF, "applied": true}


func _refused(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "status": "source_state_rejected", "error": message,
		"source_rom_sha256": ROM_SHA256, "trace_state_used": false, "emulator_data_used": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
