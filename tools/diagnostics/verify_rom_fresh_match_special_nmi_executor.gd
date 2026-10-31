extends SceneTree

const EXECUTOR_PATH := "res://scripts/gameplay/rom_fresh_match_special_nmi_executor.gd"
const SERVICE_BYTES_PATH := "res://reference/rom_extract/gameplay/fresh_kickoff_0078_wait_20261029/fixed_raster_nmi_service_C421_C472.bin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var executor_script: Script = load(EXECUTOR_PATH)
	if executor_script == null:
		_fail("Could not load the special-NMI executor script.")
		return
	var executor: RefCounted = executor_script.new()
	if not bool(executor.configure_from_project_sources()):
		_fail("ROM source manifest/hash validation failed: " + String(executor.error_message))
		return
	var status: Dictionary = executor.get_status()
	if String(status.get("rom_sha256", "")) != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097" \
			or not bool(status.get("executes_special_nmi_through_sound_driver_first_queue_scan", false)) \
			or int(status.get("sound_driver_entry_pc", -1)) != 0x8000 \
			or int(status.get("sound_driver_prefix_end_pc", -1)) != 0x8061 \
			or bool(status.get("executes_sound_driver_rts", true)) \
			or bool(status.get("executes_special_nmi_rti", true)) \
			or bool(status.get("advances_live_route", true)):
		_fail("Executor status does not describe the hash-bound, non-route boundary.")
		return
	var service_bytes := FileAccess.get_file_as_bytes(SERVICE_BYTES_PATH)
	if service_bytes.size() != 82 \
			or service_bytes.slice(0x19, 0x1C) != PackedByteArray([0x20, 0x00, 0xA0]) \
			or service_bytes.slice(0x28, 0x2B) != PackedByteArray([0x20, 0x00, 0x80]):
		_fail("C421 source bytes do not contain the expected `$A000` and banked `$8000` calls.")
		return
	var ram := PackedByteArray()
	ram.resize(0x800)
	# Explicit bounded source-state fixture exercises all four bank-range paths.
	# This is a verifier input, not a captured or route-produced game state.
	ram[0x0700] = 0x58
	ram[0x0701] = 0x3F
	ram[0x0702] = 0x48
	ram[0x0703] = 0x5C
	ram[0x0704] = 0x31
	ram[0x0705] = 0x01
	ram[0x07FC] = 0x0C
	var stack := PackedByteArray()
	stack.resize(0x100)
	# JSR $8000 at $C449 pushes return-minus-one $C44B at SP=$EE.
	stack[0xEF] = 0x4B
	stack[0xF0] = 0xC4
	var cpu := {"pc": 0x8000, "a": 0x0C, "x": 0x00, "y": 0x00, "p": 0x24}
	var mapper := {"registers": [0, 0, 0, 0, 0, 0, 0x0C, 0x0C],
		"command": 0x06, "prg_mode": false, "chr_inversion": false,
		"8000_prg_bank": 0x0C, "a000_prg_bank": 0x0C}
	var prefix: Dictionary = executor.call("_execute_sound_driver_first_pass",
		ram, stack, 0xEE, cpu, mapper)
	if not bool(prefix.get("ok", false)):
		_fail("Sound-driver first-pass fixture failed: " + String(prefix.get("error", "unknown error")))
		return
	var prefix_cpu: Dictionary = prefix["cpu"]
	var prefix_mapper: Dictionary = prefix["mapper"]
	var prefix_registers: Array = prefix_mapper["registers"]
	var scanned_slots := 0
	for pc: int in prefix["source_path"]:
		if pc == 0x8002:
			scanned_slots += 1
	if String(prefix.get("status", "")) != "stopped_before_second_sound_driver_pass" \
			or int(prefix_cpu.get("pc", -1)) != 0x8061 \
			or int(prefix_cpu.get("x", -1)) != 0xFF \
			or int(prefix_cpu.get("y", -1)) != 0x0F \
			or scanned_slots != 6 \
			or int(prefix["sp"]) != 0xEE \
			or int(prefix["stack_page"][0xEF]) != 0x4B \
			or int(prefix["stack_page"][0xF0]) != 0xC4 \
			or int(prefix["ram"][0x07FC]) != 0x0F \
			or int(prefix_registers[6]) != 0x0C \
			or int(prefix_registers[7]) != 0x0F \
			or int(prefix_mapper.get("8000_prg_bank", -1)) != 0x0C \
			or int(prefix_mapper.get("a000_prg_bank", -1)) != 0x0F \
			or prefix["ram_writes"].size() != 3 \
			or prefix["mapper_bus_writes"].size() != 12 \
			or bool(prefix.get("apu_state_required_for_this_prefix", true)):
		_fail("Sound-driver prefix state mismatch: pc=%04X x=%02X y=%02X slots=%d sp=%02X saved=%02X r6/r7=%02X/%02X map=%02X/%02X RAM-writes=%d MMC3-writes=%d APU-independent=%s." % [
			int(prefix_cpu.get("pc", -1)), int(prefix_cpu.get("x", -1)), int(prefix_cpu.get("y", -1)),
			scanned_slots, int(prefix["sp"]), int(prefix["ram"][0x07FC]),
			int(prefix_registers[6]), int(prefix_registers[7]),
			int(prefix_mapper.get("8000_prg_bank", -1)), int(prefix_mapper.get("a000_prg_bank", -1)),
			prefix["ram_writes"].size(), prefix["mapper_bus_writes"].size(),
			str(not bool(prefix.get("apu_state_required_for_this_prefix", true)))])
		return
	# No actual source-produced C421 context is currently available. Reject an
	# empty context rather than fabricating RAM, mapper, stack, or controller state.
	var rejected: Dictionary = executor.execute_from_c421({})
	if bool(rejected.get("ok", true)) or bool(rejected.get("advances_live_route", true)) \
			or bool(rejected.get("trace_state_used", true)) \
			or bool(rejected.get("candidate_state_used", true)):
		_fail("Executor did not safely reject missing source-owned CPU/stack/RAM context.")
		return
	print("PASS: source hashes and `$C421->$A000`/`$C449->$8000` bytes verified; explicit full-state fixture executes the six-slot `$8000-$8060` driver prefix and stops at `$8061` with its JSR pending; missing route context is rejected.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
