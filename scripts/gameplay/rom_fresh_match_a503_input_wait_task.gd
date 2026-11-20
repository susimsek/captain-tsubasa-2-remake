extends RefCounted
class_name RomFreshMatchA503InputWaitTask
## Executes the bounded caller loop at ROM bank-$01 `$A571-$A57C`.
## `$9FA8` is represented as one source-frame yield; NMI/CPU phase is outside
## this task and the input edge comes from the live frame input adapter.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/manifest.json"
const BODY_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_a006/bank01_prematch_setup_body_A4EB_A610.bin"
const BODY_SHA256 := "1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587"
const BODY_START := 0xA4EB
const BODY_END := 0xA611
const WAIT_START := 0xA571
const WAIT_BYTES := [0xA9, 0x01, 0x20, 0xA8, 0x9F, 0xA5,
	0x1E, 0x30, 0x03, 0xCA, 0xD0, 0xF4]
const NES_A_EDGE := 0x80
const INITIAL_TIMEOUT := 0xF0

var error_message := ""
var _configured := false
var _state: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("The fresh KICK OFF A006 manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("The fresh KICK OFF A006 manifest is malformed.")
	var manifest: Dictionary = parsed
	var rom: Variant = manifest.get("rom", {})
	if String(manifest.get("schema", "")) != "ct2-fresh-kickoff-a006-source-v1" \
			or not rom is Dictionary or String(rom.get("sha256", "")) != ROM_SHA256:
		return _fail("The A006 manifest targets another ROM revision.")
	var body_entry: Dictionary = {}
	for entry_variant in manifest.get("spans", []):
		if entry_variant is Dictionary and String(entry_variant.get("id", "")) == "a4eb_body":
			body_entry = entry_variant
			break
	var body := FileAccess.get_file_as_bytes(BODY_PATH)
	if body_entry.is_empty() \
			or String(body_entry.get("cpu_start", "")) != "$A4EB" \
			or String(body_entry.get("cpu_end_exclusive", "")) != "$A611" \
			or String(body_entry.get("bank_mapping", "")) != "PRG bank $01 at CPU $A000-$BFFF" \
			or int(body_entry.get("length", -1)) != BODY_END - BODY_START \
			or String(body_entry.get("sha256", "")) != BODY_SHA256 \
			or body.size() != BODY_END - BODY_START or _sha256(body) != BODY_SHA256 \
			or String(body_entry.get("bytes", "")) != body.hex_encode():
		return _fail("The bank-$01 A006 body failed its manifest, size, hash, or byte check.")
	var wait_offset := WAIT_START - BODY_START
	if body.slice(wait_offset, wait_offset + WAIT_BYTES.size()) != PackedByteArray(WAIT_BYTES):
		return _fail("ROM `$A571-$A57C` no longer matches the decoded input/timeout loop.")
	_configured = true
	return true


## Starts from the completed `$997A` helper return. This loop waits for a newly
## pressed A edge or expires after the source X countdown reaches zero.
func begin(palette_ramp_result: Dictionary, source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if not bool(palette_ramp_result.get("ok", false)) \
			or String(palette_ramp_result.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(palette_ramp_result.get("status", "")) != "returned_to_a503_wait_loop" \
			or bool(palette_ramp_result.get("trace_state_used", true)) \
			or bool(palette_ramp_result.get("emulator_data_used", true)):
		return _refused("A source-owned `$997A` return at `$A571` is required.")
	var cpu: Dictionary = palette_ramp_result.get("details", {}).get("cpu", {})
	var ram: Dictionary = palette_ramp_result.get("ram_after", {})
	if source_frame < 0 or int(cpu.get("pc", -1)) != 0xA571 \
			or int(cpu.get("a", -1)) != 0x1E or int(cpu.get("x", -1)) != INITIAL_TIMEOUT \
			or int(cpu.get("y", -1)) != 0x20 \
			or int(ram.get(0x004A, -1)) != 0x0F or int(ram.get(0x004B, -1)) != 0x0F:
		return _refused("The `$A571` input loop requires the exact `$997A` CPU and counter return state.")
	_state = {"status": "waiting_at_a571", "source_frame": source_frame,
		"remaining_x": INITIAL_TIMEOUT, "wait_tick_count": 0,
		"last_controller_sample": {}, "source_path": [0xA571]}
	return _result("waiting_at_a571", source_frame, 0, {})


## `controller_sample` is produced from the route's consecutive live pad states;
## this task validates the `$001C/$001E` edge rule and never consumes captures.
func advance_source_tick(source_frame: int, controller_sample: Dictionary) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _refused(error_message)
	if _state.is_empty() or String(_state.get("status", "")) != "waiting_at_a571":
		return _refused("The `$A571` wait has no live pending source continuation.")
	if source_frame <= int(_state.get("source_frame", -1)):
		return _refused("The `$A571` wait requires a later source-frame sample.")
	for field: String in ["previous", "current", "newly_pressed", "held_ram_001c", "edge_ram_001e"]:
		var value := int(controller_sample.get(field, -1))
		if value < 0 or value > 0xFF:
			return _refused("The live controller sampler is missing byte `$%s`." % field)
	var edge := int(controller_sample["newly_pressed"])
	var held := int(controller_sample["current"])
	var previous := int(controller_sample["previous"])
	if int(controller_sample["held_ram_001c"]) != held \
			or int(controller_sample["edge_ram_001e"]) != edge \
			or edge != ((previous ^ held) & held):
		return _refused("Controller sample does not match the ROM `$001C/$001E` edge rule.")
	var remaining := int(_state.get("remaining_x", -1))
	var source_path: Array = _state.get("source_path", []).duplicate()
	source_path.append_array([0xA573, 0x9FA8, 0xA576, 0xA578])
	_state["wait_tick_count"] = int(_state.get("wait_tick_count", 0)) + 1
	_state["source_frame"] = source_frame
	_state["last_controller_sample"] = controller_sample.duplicate(true)
	if (edge & NES_A_EDGE) != 0:
		source_path.append(0xA57D)
		_state["status"] = "returned_to_a57d_on_a_edge"
		_state["source_path"] = source_path
		return _result("returned_to_a57d_on_a_edge", source_frame, edge,
			{"cpu": {"pc": 0xA57D, "a": edge, "x": remaining, "y": 0x20},
			"controller_sample": controller_sample.duplicate(true)})
	remaining = (remaining - 1) & 0xFF
	_state["remaining_x"] = remaining
	if remaining == 0:
		_state["status"] = "timed_out_to_a57d"
		source_path.append_array([0xA57A, 0xA57B, 0xA57D])
		_state["source_path"] = source_path
		return _result("timed_out_to_a57d", source_frame, edge,
			{"cpu": {"pc": 0xA57D, "a": edge, "x": 0, "y": 0x20},
			"controller_sample": controller_sample.duplicate(true)})
	source_path.append_array([0xA57A, 0xA57B, 0xA571])
	_state["source_path"] = source_path
	return _result("waiting_at_a571", source_frame, edge,
		{"cpu": {"pc": 0xA571, "a": edge, "x": remaining, "y": 0x20},
		"controller_sample": controller_sample.duplicate(true)})


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message,
		"status": String(_state.get("status", "unstarted")),
		"source_frame": int(_state.get("source_frame", -1)),
		"remaining_x": int(_state.get("remaining_x", -1)),
		"wait_tick_count": int(_state.get("wait_tick_count", 0)),
		"source_rom_sha256": ROM_SHA256,
		"source_path": _state.get("source_path", []).duplicate(),
		"last_controller_sample": _state.get("last_controller_sample", {}).duplicate(true),
		"trace_state_used": false, "emulator_data_used": false,
		"physical_nes_timing_proven": false}


func _result(status: String, source_frame: int, edge: int, details: Dictionary) -> Dictionary:
	var result := get_status()
	result["ok"] = true
	result["kind"] = "rom_fresh_match_a503_input_wait"
	result["status"] = status
	result["source_frame"] = source_frame
	result["newly_pressed_buttons"] = edge
	result["details"] = details.duplicate(true)
	return result


func _refused(reason: String) -> Dictionary:
	return {"ok": false, "status": "source_state_rejected", "error": reason,
		"source_rom_sha256": ROM_SHA256, "trace_state_used": false,
		"emulator_data_used": false, "physical_nes_timing_proven": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()
