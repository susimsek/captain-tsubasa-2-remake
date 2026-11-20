extends SceneTree

const EXECUTOR_PATH := "res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd"
const MMC3_CHR_MAPPER := preload("res://scripts/gameplay/rom_mmc3_chr_mapper.gd")
const SNAPSHOT_DIR := "res://reference/diagnostics/kickoff_rom_source_context_snapshot_20261101/rom_source_c421_snapshot/"
const CHR_PATH := "res://reference/rom_extract/chr_rom.2bpp"
const FCEUX_PPU_DIR := "res://reference/diagnostics/kickoff_select_cleanup_counters_20261101_093929_utc/"
const EXPECTED_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const EXPECTED_ROUTE_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const EXPECTED_CHR_SHA256 := "721579f3a3dc2042534de98b24135371fc379958711a168a6861c989a10d85ad"
const EXPECTED_C421_CHR_BANKS: Array[int] = [0, 1, 2, 3, 112, 113, 102, 103]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var report_bytes := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "context.json")
	if report_bytes.is_empty():
		_fail("ROM-only C421 snapshot report is missing.")
		return
	var parsed: Variant = JSON.parse_string(report_bytes.get_string_from_utf8())
	if not parsed is Dictionary or String(parsed.get("schema", "")) != "ct2-rom-only-source-boundary-v1":
		_fail("ROM-only C421 snapshot report has an unknown schema.")
		return
	var report: Dictionary = parsed
	var context_value: Variant = report.get("context", {})
	if not context_value is Dictionary:
		_fail("ROM-only C421 snapshot context is missing.")
		return
	var context: Dictionary = context_value.duplicate(true)
	var ram := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "ram.bin")
	var stack := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "stack.bin")
	var ppu := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "ppu.bin")
	var oam := FileAccess.get_file_as_bytes(SNAPSHOT_DIR + "oam.bin")
	if ram.size() != 0x800 or stack.size() != 0x100 or ppu.size() != 0x4000 or oam.size() != 0x100:
		_fail("ROM-only snapshot RAM/stack/PPU/OAM image sizes are invalid.")
		return
	if not _matches_hash(ram, String(report.get("ram_sha256", ""))) \
			or not _matches_hash(stack, String(report.get("stack_sha256", ""))) \
			or not _matches_hash(ppu, String(report.get("ppu_sha256", ""))) \
			or not _matches_hash(oam, String(report.get("oam_sha256", ""))):
		_fail("ROM-only snapshot bytes do not match their recorded hashes.")
		return
	if not _verify_mmc3_chr_view(context):
		return
	context["ram"] = ram
	context["stack_page"] = stack
	if String(context.get("source_rom_sha256", "")) != EXPECTED_ROM_SHA256 \
			or String(context.get("provenance", {}).get("input_route_sha256", "")) != EXPECTED_ROUTE_SHA256:
		_fail("Snapshot provenance does not match the pinned ROM and route inputs.")
		return
	var executor_script: Script = load(EXECUTOR_PATH)
	if executor_script == null:
		_fail("Could not load the ROM NMI executor.")
		return
	var executor: RefCounted = executor_script.new()
	if not bool(executor.configure_from_project_sources()):
		_fail("ROM NMI executor source validation failed: " + String(executor.error_message))
		return
	var result: Dictionary = executor.execute_from_c421(context)
	if not bool(result.get("ok", false)):
		_fail("ROM-only source snapshot was rejected at C421: " + String(result.get("error", "unknown error")))
		return
	if String(result.get("status", "")) != "stopped_after_sound_driver_first_queue_scan" \
			or String(result.get("source_event_id", "")).is_empty() \
			or bool(result.get("trace_state_used", true)) \
			or bool(result.get("emulator_data_used", true)) \
			or bool(result.get("candidate_state_used", true)) \
			or bool(result.get("advances_live_route", true)):
		_fail("ROM-only C421 execution crossed its bounded result/provenance contract.")
		return
	var resumed: Dictionary = executor.resume_empty_sound_slots_to_queue_head(result)
	var resumed_cpu: Dictionary = resumed.get("cpu_after_nmi_rti", {})
	var resumed_ram: PackedByteArray = resumed.get("ram_after", PackedByteArray())
	var resumed_mapper: Dictionary = resumed.get("mapper_after", {})
	var resumed_registers: Array = resumed_mapper.get("registers", [])
	if not bool(resumed.get("ok", false)) \
			or String(resumed.get("status", "")) != "returned_from_special_nmi_to_interrupted_pc" \
			or int(resumed_cpu.get("pc", -1)) != 0xA15B \
			or int(resumed_cpu.get("p", -1)) != 0x20 \
			or int(resumed_cpu.get("sp", -1)) != 0x24 \
			or int(resumed_cpu.get("a", -1)) != 0x1F \
			or int(resumed_cpu.get("x", -1)) != 0x00 \
			or int(resumed_cpu.get("y", -1)) != 0x00 \
			or int(resumed.get("cpu_cycles_from_8061", -1)) != 728 \
			or not bool(resumed.get("queue_data_0706_read", false)) \
			or not bool(resumed.get("sound_driver_rts_reached", false)) \
			or not bool(resumed.get("nmi_rti_reached", false)) \
			or not bool(resumed.get("nmi_stack_frame_restored", false)) \
			or resumed_ram.size() != 0x800 or int(resumed_ram[0x003B]) != 0x55 \
			or resumed_registers.size() != 8 \
			or int(resumed_registers[6]) != int(resumed_ram[0x0024]) \
			or int(resumed_registers[7]) != int(resumed_ram[0x0025]) \
			or int(resumed_mapper.get("command", -1)) != int(resumed_ram[0x0023]) \
			or resumed.get("apu_writes", []) != [] \
			or bool(resumed.get("live_route_advanced", true)) \
			or bool(resumed.get("trace_state_used", true)) \
			or bool(resumed.get("emulator_data_used", true)) \
			or bool(resumed.get("candidate_state_used", true)):
		_fail("The ROM-only C421 context did not restore mapper/register state and RTI back to `$A15B`.")
		return
	print("PASS: ROM-only frame-%d C421 context (%s) passed the exact MMC3 CHR view and Godot zero-mask sound-driver, MMC3 restore, and RTI to `$A15B` in 728 modeled cycles; production-route integration remains pending." % [
		int(context.get("source_event", {}).get("source_frame", -1)), String(result["source_event_id"])])
	quit(0)


func _verify_mmc3_chr_view(context: Dictionary) -> bool:
	var chr_bytes := FileAccess.get_file_as_bytes(CHR_PATH)
	if chr_bytes.size() != 0x20000 or not _matches_hash(chr_bytes, EXPECTED_CHR_SHA256):
		_fail("ROM-derived CHR source failed its expected size/hash check.")
		return false
	var mapper_variant: Variant = context.get("mapper", {})
	if not mapper_variant is Dictionary:
		_fail("ROM-source C421 MMC3 state is missing.")
		return false
	var mapper: Dictionary = mapper_variant
	var mapped: Dictionary = MMC3_CHR_MAPPER.map_pattern_table(chr_bytes,
		mapper.get("registers", []), int(mapper.get("command", -1)))
	if not bool(mapped.get("ok", false)):
		_fail("Could not derive the C421 MMC3 CHR view: " + String(mapped.get("error", "unknown mapper error")))
		return false
	if mapped.get("chr_1k_banks", []) != EXPECTED_C421_CHR_BANKS:
		_fail("C421 MMC3 register state selected an unexpected 1 KiB CHR bank map.")
		return false
	var pattern_table: PackedByteArray = mapped.get("pattern_table", PackedByteArray())
	if pattern_table.size() != 0x2000:
		_fail("C421 MMC3 mapping did not produce the complete 8 KiB pattern table.")
		return false
	for pass_name: String in ["frame_7266_C421_ppu_pass1.bin", "frame_7266_C421_ppu_pass2.bin"]:
		var fceux_ppu := FileAccess.get_file_as_bytes(FCEUX_PPU_DIR + pass_name)
		if fceux_ppu.size() != 0x4000:
			_fail("Muted FCEUX PPU validation capture is missing or malformed: " + pass_name)
			return false
		if fceux_ppu.slice(0, 0x2000) != pattern_table:
			_fail("ROM CHR/MMC3 mapping differs from the FCEUX C421 pattern table: " + pass_name)
			return false
	return true


func _matches_hash(bytes: PackedByteArray, expected: String) -> bool:
	if expected.length() != 64:
		return false
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK:
		return false
	hasher.update(bytes)
	return hasher.finish().hex_encode() == expected


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
