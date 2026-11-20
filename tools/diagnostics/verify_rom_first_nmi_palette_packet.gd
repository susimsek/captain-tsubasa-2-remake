extends SceneTree

const EXECUTOR_PATH := "res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd"
const SNAPSHOT_DIR := "res://reference/diagnostics/kickoff_first_nmi_source_context_20261101/rom_source_c421_snapshot/"
const FCEUX_PPU_DIR := "res://reference/diagnostics/kickoff_select_cleanup_counters_20261101_071320_utc/"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_ROUTE_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const EXPECTED_RAM_SHA256 := "0d0657c009902cb38320b1213d4272eb7d7e73b9fe3f0863288124a7948a3c0b"
const EXPECTED_STACK_SHA256 := "4e8a5fce6b030eb563f19aee0d442a13f6dc982a5f0992f4b4ff87c657b11e09"
const EXPECTED_PPU_SHA256 := "f74b4826148deba3b1465cf9bc42ce70070fdd3e638abff306c72e38a7994163"
const EXPECTED_FCEUX_PPU_SHA256 := "6741d2a36a89296e3d07a94e68bccdda617983bf272eb9db9a183c619ca231ee"
const PALETTE_START := 0x3F00
const PALETTE_BYTES := 32


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var snapshot_bytes := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "context.json")
	var parsed: Variant = JSON.parse_string(snapshot_bytes.get_string_from_utf8())
	if not parsed is Dictionary \
			or String(parsed.get("schema", "")) != "ct2-rom-only-source-boundary-v1":
		_fail("ROM-only first-NMI snapshot report is missing or malformed.")
		return
	var report: Dictionary = parsed
	var context_value: Variant = report.get("context", {})
	if not context_value is Dictionary:
		_fail("ROM-only first-NMI source context is missing.")
		return
	var context: Dictionary = context_value.duplicate(true)
	var ram := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "ram.bin")
	var stack := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "stack.bin")
	var source_ppu := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "ppu.bin")
	if ram.size() != 0x800 or stack.size() != 0x100 or source_ppu.size() != 0x4000 \
			or not _matches_hash(ram, EXPECTED_RAM_SHA256) \
			or not _matches_hash(stack, EXPECTED_STACK_SHA256) \
			or not _matches_hash(source_ppu, EXPECTED_PPU_SHA256):
		_fail("ROM-only first-NMI RAM, stack, or PPU bytes failed their source hashes.")
		return
	if String(context.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or String(context.get("provenance", {}).get("input_route_sha256", "")) != EXPECTED_ROUTE_SHA256 \
			or int(context.get("source_event", {}).get("source_frame", -1)) != 7258 \
			or int(context.get("source_event", {}).get("entry_pc", -1)) != 0xC421 \
			or int(context.get("nmi_frame", {}).get("interrupted_pc", -1)) != 0x9F04 \
			or int(context.get("nmi_frame", {}).get("interrupted_p", -1)) != 0x21:
		_fail("Source snapshot is not the recorded route's first frame-7258 `$C421` NMI.")
		return
	if int(ram[0x0628]) != 0x23 or int(ram[0x0629]) != 0x20 \
			or int(ram[0x05E8]) != 0x20 or int(ram[0x05E9]) != 0x00 \
			or int(ram[0x05EA]) != 0x3F:
		_fail("The first NMI does not contain the expected 35-byte `$3F00` palette packet.")
		return
	context["ram"] = ram
	context["stack_page"] = stack
	var executor_script: Script = load(EXECUTOR_PATH)
	if executor_script == null:
		_fail("Could not load the ROM special-NMI executor.")
		return
	var executor: RefCounted = executor_script.new()
	if not bool(executor.configure_from_project_sources()):
		_fail("Special-NMI source validation failed: " + String(executor.error_message))
		return
	var result: Dictionary = executor.execute_from_c421(context)
	if not bool(result.get("ok", false)):
		_fail("ROM first-NMI packet execution failed: " + String(result.get("error", "unknown error")))
		return
	var packet_result: Dictionary = result.get("ppu_packet_queue", {})
	if String(packet_result.get("status", "")) != "packet_buffer_drained" \
			or int(packet_result.get("packet_count", -1)) != 1 \
			or int(packet_result.get("payload_bytes", -1)) != PALETTE_BYTES \
			or int(packet_result.get("source_bytes_consumed", -1)) != 0x23:
		_fail("The ROM `$A000` executor did not drain the source-derived 35-byte palette packet.")
		return
	var ppu_events: Array = result.get("ppu_bus_events", [])
	var data_events: Array[Dictionary] = []
	for event_variant in ppu_events:
		if event_variant is Dictionary and int(event_variant.get("address", -1)) == 0x2007:
			data_events.append(event_variant)
	if data_events.size() != PALETTE_BYTES:
		_fail("ROM `$A000` did not emit exactly 32 PPU data writes.")
		return
	var applied_ppu := source_ppu.duplicate()
	for index in PALETTE_BYTES:
		var event: Dictionary = data_events[index]
		var expected_address := PALETTE_START + index
		var expected_value := int(ram[0x05EB + index])
		if int(event.get("source_pc", -1)) != 0xA039 \
				or int(event.get("ppu_address", -1)) != expected_address \
				or int(event.get("value", -1)) != expected_value:
			_fail("ROM `$A000` PPU event %d differs from its source packet byte." % index)
			return
		applied_ppu[expected_address] = expected_value
	var ram_after: PackedByteArray = result.get("ram_after", PackedByteArray())
	if ram_after.size() != 0x800 or int(ram_after[0x0628]) != 0:
		_fail("ROM `$A04A` did not clear the consumed `$0628` packet marker.")
		return
	for pass_name in ["frame_7258_ppu_pass1.bin", "frame_7258_ppu_pass2.bin"]:
		var fceux_ppu := FileAccess.get_file_as_bytes(FCEUX_PPU_DIR + pass_name)
		if fceux_ppu.size() != 0x4000 or not _matches_hash(fceux_ppu, EXPECTED_FCEUX_PPU_SHA256):
			_fail("Muted FCEUX frame-7258 PPU validation capture is missing or has changed: " + pass_name)
			return
		if applied_ppu.slice(PALETTE_START, PALETTE_START + PALETTE_BYTES) \
				!= fceux_ppu.slice(PALETTE_START, PALETTE_START + PALETTE_BYTES):
			_fail("The ROM-derived `$A000` packet does not reproduce the FCEUX palette: " + pass_name)
			return
	var resumed: Dictionary = executor.resume_empty_sound_slots_to_queue_head(result)
	var returned_cpu: Dictionary = resumed.get("cpu_after_nmi_rti", {})
	if not bool(resumed.get("ok", false)) \
			or int(returned_cpu.get("pc", -1)) != int(context["nmi_frame"]["interrupted_pc"]) \
			or int(returned_cpu.get("p", -1)) != int(context["nmi_frame"]["interrupted_p"]) \
			or int(returned_cpu.get("sp", -1)) != ((int(context["cpu"]["sp"]) + 3) & 0xFF) \
			or bool(resumed.get("trace_state_used", true)) \
			or bool(resumed.get("emulator_data_used", true)):
		_fail("The source NMI did not return to the interrupted `$9F04` CPU/stack state.")
		return
	print("PASS: ROM-only frame-7258 NMI drained the `$3F00` 32-byte palette packet, matched both muted FCEUX palette captures, cleared `$0628`, and RTI-restored the source `$9F04` state.")
	quit(0)


func _matches_hash(bytes: PackedByteArray, expected: String) -> bool:
	if expected.length() != 64:
		return false
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK:
		return false
	if hasher.update(bytes) != OK:
		return false
	return hasher.finish().hex_encode() == expected


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
