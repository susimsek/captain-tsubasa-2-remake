extends RefCounted
class_name RomFreshMatchPresetWaitIrqExecutor
## Executes the ROM-owned raster IRQ from the source-derived `$893B` prefix.
## The ROM-only scanline edge is a candidate timing input, not hardware proof.

const ASSET_PATH := "res://assets/gameplay/rom_logic/fresh_kickoff_preset_wait_irq_runtime.json"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
const SOURCE_MANIFEST_SHA256 := "5d7567d0b278f957fe2489517a45da4bedcc74dcf0553889cb82f411efda6e69"
const CANDIDATE_SCHEDULE_SHA256 := "92c52ccef07422c02eb95d40b3f0c5ce41fece6cc11784167572ea22be964d85"
const EXPECTED_SOURCE_EVENT_ID := "fresh-kickoff-893b-irq-edge:7266:216372246"
const WAIT_PC := 0x893B

const SPAN_EXPECTATIONS := {
	"vector_trampolines": {"start": 0xC500, "length": 9,
		"sha256": "4cacda47b1a9af1bdc11c78e5dc06357d5e8dfa4819ecf8f9c98bfe15b79151f"},
	"irq_dispatch": {"start": 0xC821, "length": 7,
		"sha256": "5e94774bfa2074975596f0f7b9468f6c2c13d47f943936edb5f2a0ac8fb3b883"},
	"irq_service": {"start": 0xC478, "length": 54,
		"sha256": "3bd224939351f06a7ff6e8138b52b8d8744c40b92bc955fe4b28e68b82c6917d"},
	"interrupt_vectors": {"start": 0xFFFA, "length": 6,
		"sha256": "72925dda7194399d7eb27eb4a7d41a2b4d4b8be47b049bc1fd06f95f6627edec"},
	"bank2_irq_consumer": {"start": 0xA160, "length": 130,
		"sha256": "50a0bf6f80ee2c2ca1e1f2034e6328b6f447a73838bb833fb0041fc9455b191a"},
	"bank2_irq_consumer_tail": {"start": 0xA1E2, "length": 2,
		"sha256": "322d846034eb1504f862d69cc84c8c42cf29fe205cae5962a7bf54618672d0ba"},
}

var error_message := ""
var _configured := false
var _asset: Dictionary = {}
var _spans: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_asset.clear()
	_spans.clear()
	if not FileAccess.file_exists(ASSET_PATH):
		return _fail("ROM IRQ runtime asset is missing.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSET_PATH))
	if not parsed is Dictionary:
		return _fail("ROM IRQ runtime asset is malformed JSON.")
	_asset = parsed
	if String(_asset.get("schema", "")) != "ct2-fresh-kickoff-preset-wait-irq-runtime-v1" \
			or String(_asset.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(_asset.get("input_route_sha256", "")) != INPUT_SHA256 \
			or String(_asset.get("source_manifest_sha256", "")) != SOURCE_MANIFEST_SHA256 \
			or String(_asset.get("candidate_schedule_sha256", "")) != CANDIDATE_SCHEDULE_SHA256 \
			or String(_asset.get("source_event_id", "")) != EXPECTED_SOURCE_EVENT_ID:
		return _fail("IRQ asset provenance differs from the pinned ROM, route, or candidate edge.")
	var span_docs: Variant = _asset.get("source_spans", {})
	if not span_docs is Dictionary:
		return _fail("IRQ source spans are missing.")
	for span_id: String in SPAN_EXPECTATIONS:
		var expected: Dictionary = SPAN_EXPECTATIONS[span_id]
		var span: Variant = span_docs.get(span_id, {})
		if not span is Dictionary:
			return _fail("IRQ asset omits source span `%s`." % span_id)
		var bytes: PackedByteArray = String(span.get("bytes_hex", "")).hex_decode()
		if bytes.size() != int(expected["length"]) \
				or _sha256(bytes) != String(expected["sha256"]) \
				or _hex_pc(String(span.get("cpu_start", ""))) != int(expected["start"]) \
				or int(span.get("length", -1)) != int(expected["length"]):
			return _fail("IRQ ROM span `%s` failed its fixed address, size, or hash check." % span_id)
		_spans[span_id] = bytes
	var edge: Dictionary = _asset.get("irq_edge", {})
	if int(edge.get("source_frame", -1)) != 7266 \
			or int(edge.get("source_cycle", -1)) != 216372246 \
			or int(edge.get("ppu_line", -1)) != 128 \
			or int(edge.get("ppu_dot", -1)) != 274 \
			or int(edge.get("counter_before", -1)) != 1 \
			or int(edge.get("counter_after", -1)) != 0 \
			or int(edge.get("latch", -1)) != 128 \
			or int(edge.get("irq_enabled", -1)) != 1:
		return _fail("ROM-only IRQ edge candidate differs from the reviewed `$893B` wait event.")
	_configured = true
	return true


## Consumes the live route's source prefix and sparse source RAM ledger. The
## audit schedule contributes only the candidate edge, never machine state.
func execute_from_wait_prefix(prefix_result: Dictionary, source_ram_image: Variant,
		ppu_shadows: Dictionary, source_frame: int) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return _failure(error_message)
	var checked := _validate_prefix(prefix_result, source_ram_image, ppu_shadows, source_frame)
	if not bool(checked.get("ok", false)):
		return _failure(String(checked.get("error", "Wait prefix is invalid.")))
	var event_id := String(prefix_result["source_event_id"]) + ":893B:" + EXPECTED_SOURCE_EVENT_ID
	var ram: Dictionary = checked["ram"].duplicate(true)
	var cpu: Dictionary = checked["registers"].duplicate(true)
	var stack: PackedByteArray = checked["stack_page"].duplicate()
	var initial_sp := int(cpu["sp"])
	var source_path: Array[int] = []
	var ram_writes: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var ppu_events: Array[Dictionary] = []
	var cycles := 0
	var ppu: Dictionary = {"ctrl_shadow": int(ppu_shadows["ctrl_shadow"]),
		"mask_shadow": int(ppu_shadows["mask_shadow"])}
	var mapper := _initial_mapper_state(ram)

	# The wait loop's LDA is the interrupted instruction boundary in the
	# candidate event. It is executed from the live `$78` byte, not a trace RAM.
	cpu["pc"] = WAIT_PC
	cpu["a"] = int(ram[0x0078])
	_set_nz(cpu, int(cpu["a"]))
	var interrupted_p := int(cpu["p"])
	var pushed_status := ((interrupted_p & 0xEF) | 0x20) & 0xFF
	var interrupted_pc := WAIT_PC
	if initial_sp < 3:
		return _failure("The physical CPU stack has no room for the IRQ frame.")
	stack[initial_sp] = (interrupted_pc >> 8) & 0xFF
	stack[(initial_sp - 1) & 0xFF] = interrupted_pc & 0xFF
	stack[(initial_sp - 2) & 0xFF] = pushed_status
	cpu["sp"] = (initial_sp - 3) & 0xFF
	cpu["p"] = int(cpu["p"]) | 0x04
	cycles = 7 # 2A03 IRQ entry; scanline edge timing remains a candidate model.

	# FFFE -> C506 JMP C821; BIT $1B selects the normal raster service.
	_record(source_path, 0xC506)
	cycles += 3
	_record(source_path, 0xC821)
	_bit(cpu, int(ram[0x001B]))
	cycles += 3
	_record(source_path, 0xC823)
	if (int(cpu["p"]) & 0x40) == 0:
		return _failure("ROM `$C821` selected an unsupported V-clear IRQ dispatch branch.")
	cycles += 2 # BVC not taken.
	_record(source_path, 0xC825)
	cycles += 3 # JMP $C478.
	_record(source_path, 0xC478)
	_bit(cpu, int(ram[0x003B]))
	cycles += 3
	_record(source_path, 0xC47A)
	if (int(cpu["p"]) & 0x80) != 0:
		return _failure("ROM `$C478` selected an unsupported negative `$003B` wrapper branch.")
	cycles += 2 # BMI not taken.
	_record(source_path, 0xC47C)
	cpu["p"] = int(cpu["p"]) | 0x01 # SEC.
	cycles += 2
	_record(source_path, 0xC47D)
	var old_3b := int(ram[0x003B])
	var rotated_3b := ((old_3b >> 1) | 0x80) & 0xFF
	cpu["p"] = (int(cpu["p"]) & 0xFE) | (old_3b & 1)
	_set_nz(cpu, rotated_3b)
	_ram_write(ram, ram_writes, event_id, 0xC47D, 0x003B, rotated_3b)
	cycles += 5
	_record(source_path, 0xC47F)
	_ram_write(ram, ram_writes, event_id, 0xC47F, 0x003C, int(cpu["a"]))
	cycles += 3
	_record(source_path, 0xC481)
	_ram_write(ram, ram_writes, event_id, 0xC481, 0x003D, int(cpu["x"]))
	cycles += 3
	_record(source_path, 0xC483)
	_ram_write(ram, ram_writes, event_id, 0xC483, 0x003E, int(cpu["y"]))
	cycles += 3

	_record(source_path, 0xC485)
	cpu["a"] = int(ram[0x0022])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(source_path, 0xC487)
	cpu["a"] = (int(cpu["a"]) | 0x07) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	cycles += 2
	_record(source_path, 0xC489)
	_mapper_write(mapper, mapper_writes, 0xC489, 0x8000, int(cpu["a"]))
	cycles += 4
	_record(source_path, 0xC48C)
	cpu["a"] = 0x02
	_set_nz(cpu, 0x02)
	cycles += 2
	_record(source_path, 0xC48E)
	_mapper_write(mapper, mapper_writes, 0xC48E, 0x8001, int(cpu["a"]))
	cycles += 4
	_record(source_path, 0xC491)
	if int(mapper.get("a000_prg_bank", -1)) != 0x02:
		return _failure("The ROM IRQ wrapper did not map bank `$02` at `$A000` for `$A160`.")
	if int(cpu["sp"]) < 2:
		return _failure("The source `$C491` JSR has no physical stack capacity.")
	stack[int(cpu["sp"])] = 0xC4
	stack[(int(cpu["sp"]) - 1) & 0xFF] = 0x93
	cpu["sp"] = (int(cpu["sp"]) - 2) & 0xFF
	cycles += 6 # JSR $A160.
	var release_cycle_offset := -1
	var executed_irq_body := _execute_a160(ram, cpu, mapper, ppu, stack,
		source_path, ram_writes, mapper_writes, ppu_events, cycles, event_id)
	if not bool(executed_irq_body.get("ok", false)):
		return _failure(String(executed_irq_body.get("error", "ROM `$A160` IRQ body stopped.")))
	cycles = int(executed_irq_body["cycles"])
	release_cycle_offset = int(executed_irq_body["release_cycle_offset"])
	cpu = executed_irq_body["cpu"]
	stack = executed_irq_body["stack_page"]

	# C494-C4AD restores PRG bank $06, selector $07, saved X/A, then LSR/RTI.
	_record(source_path, 0xC494)
	cpu["a"] = int(ram[0x0022])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(source_path, 0xC496)
	cpu["a"] = (int(cpu["a"]) | 0x07) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	cycles += 2
	_record(source_path, 0xC498)
	_mapper_write(mapper, mapper_writes, 0xC498, 0x8000, int(cpu["a"]))
	cycles += 4
	_record(source_path, 0xC49B)
	cpu["a"] = int(ram[0x0025])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(source_path, 0xC49D)
	_mapper_write(mapper, mapper_writes, 0xC49D, 0x8001, int(cpu["a"]))
	cycles += 4
	if int(mapper.get("a000_prg_bank", -1)) != 0x06:
		return _failure("The ROM IRQ wrapper did not restore saved bank `$06`.")
	_record(source_path, 0xC4A0)
	cpu["a"] = int(ram[0x0023])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(source_path, 0xC4A2)
	_mapper_write(mapper, mapper_writes, 0xC4A2, 0x8000, int(cpu["a"]))
	cycles += 4
	_record(source_path, 0xC4A5)
	cpu["y"] = int(ram[0x003E])
	_set_nz(cpu, int(cpu["y"]))
	cycles += 3
	_record(source_path, 0xC4A7)
	cpu["x"] = int(ram[0x003D])
	_set_nz(cpu, int(cpu["x"]))
	cycles += 3
	_record(source_path, 0xC4A9)
	cpu["a"] = int(ram[0x003C])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(source_path, 0xC4AB)
	var old_counter := int(ram[0x003B])
	var shifted_counter := old_counter >> 1
	cpu["p"] = (int(cpu["p"]) & 0xFE) | (old_counter & 1)
	_set_nz(cpu, shifted_counter)
	_ram_write(ram, ram_writes, event_id, 0xC4AB, 0x003B, shifted_counter)
	cycles += 5
	_record(source_path, 0xC4AD)
	var rti := _stack_rti(stack, int(cpu["sp"]))
	if not bool(rti.get("ok", false)):
		return _failure(String(rti.get("error", "IRQ RTI stack frame is invalid.")))
	cpu["pc"] = int(rti["pc"])
	cpu["sp"] = int(rti["sp"])
	cpu["p"] = int(rti["p"])
	cpu["p_known_mask"] = 0xFF
	cpu["p_known_value"] = int(rti["p"]) & 0xFF
	cycles += 6
	if int(cpu["pc"]) != WAIT_PC or int(cpu["sp"]) != initial_sp \
			or int(cpu["a"]) != int(ram[0x0078]) + 0x04:
		return _failure("The ROM IRQ did not RTI to the source wait loop with its saved registers/stack balanced.")
	var expected_ram := {0x001B: 0xC0, 0x003B: shifted_counter,
		0x0078: 0x00, 0x0079: 0x40, 0x007C: 0x80,
		0x007D: 0x00, 0x007E: 0x22, 0x0090: 0x00, 0x0091: 0x02}
	for address: int in expected_ram:
		if int(ram.get(address, -1)) != int(expected_ram[address]):
			return _failure("ROM IRQ output RAM `$%04X` differs from its executed source path." % address)
	var release_write: Dictionary = {}
	for write_variant in ram_writes:
		if write_variant is Dictionary \
				and int(write_variant.get("source_pc", -1)) == 0xA1C3 \
				and int(write_variant.get("address", -1)) == 0x0078:
			release_write = write_variant.duplicate(true)
			break
	if release_write.is_empty():
		return _failure("The ROM IRQ did not produce its `$A1C3` `$78` release write.")
	return {
		"ok": true, "kind": "rom_irq_wait_release",
		"status": "rom_irq_released_893b_wait_and_rti_returned",
		"source_rom_sha256": ROM_SHA256, "input_route_sha256": INPUT_SHA256,
		"source_event_id": event_id, "interrupt": "IRQ",
		"wait_pc": WAIT_PC, "return_pc": WAIT_PC,
		"source_frame": source_frame,
		"candidate_edge": _asset["irq_edge"].duplicate(true),
		"entry_registers": checked["registers"],
		"return_registers": cpu.duplicate(true),
		"ram_at_wait": checked["wait_ram"],
		"ram_after": ram.duplicate(true), "ram_writes": ram_writes,
		"source_path": source_path, "mapper_after": mapper,
		"mapper_bus_writes": mapper_writes, "ppu_after": ppu,
		"ppu_bus_events": ppu_events,
		"release_write": release_write,
		"release_cycle_offset_from_candidate_edge": release_cycle_offset,
		"cpu_cycles_from_candidate_irq_entry": cycles,
		"interrupt_stack_balanced": true,
		"physical_nes_timing_proven": false,
		"timing_status": "ROM and FCEUX candidate edge; CPU handler executes from source bytes, subframe alignment remains unverified.",
		"trace_state_used": false, "emulator_data_used": false,
		"candidate_state_used": false,
	}


func _execute_a160(ram: Dictionary, cpu: Dictionary, mapper: Dictionary,
		ppu: Dictionary, stack: PackedByteArray, path: Array[int],
		writes: Array[Dictionary], mapper_writes: Array[Dictionary],
		ppu_events: Array[Dictionary], cycles_in: int, event_id: String) -> Dictionary:
	var cycles := cycles_in
	_record(path, 0xA160)
	_mapper_write(mapper, mapper_writes, 0xA160, 0xE000, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA163)
	_mapper_write(mapper, mapper_writes, 0xA163, 0xE001, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA166)
	cpu["x"] = int(ram[0x0078])
	_set_nz(cpu, int(cpu["x"]))
	cycles += 3
	_record(path, 0xA168)
	cpu["a"] = int(ram[0x0078 + int(cpu["x"])])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA16A)
	if (int(cpu["p"]) & 0x80) == 0:
		return {"ok": false, "error": "ROM `$A16A` selected an unsupported BPL event-table branch."}
	cycles += 2
	_record(path, 0xA16C)
	cpu["y"] = 0x06
	_set_nz(cpu, 0x06)
	cycles += 2
	for delay_index in range(6):
		_record(path, 0xA16E)
		cpu["y"] = (int(cpu["y"]) - 1) & 0xFF
		_set_nz(cpu, int(cpu["y"]))
		cycles += 2
		_record(path, 0xA16F)
		cycles += 3 if int(cpu["y"]) != 0 else 2
	_record(path, 0xA171)
	cpu["a"] = int(ram[0x0079 + int(cpu["x"])])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA173)
	cpu["y"] = int(ram[0x007A + int(cpu["x"])])
	_set_nz(cpu, int(cpu["y"]))
	cycles += 4
	_record(path, 0xA175)
	_ppu_write(ppu, ppu_events, 0xA175, 0x2006, int(cpu["y"]), cycles)
	cycles += 4
	_record(path, 0xA178)
	_ppu_write(ppu, ppu_events, 0xA178, 0x2006, int(cpu["a"]), cycles)
	cycles += 4
	_record(path, 0xA17B)
	cpu["a"] = int(ram[0x0020])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(path, 0xA17D)
	cpu["a"] = int(cpu["a"]) & 0xFC
	_set_nz(cpu, int(cpu["a"]))
	cycles += 2
	_record(path, 0xA17F)
	_ppu_write(ppu, ppu_events, 0xA17F, 0x2000, int(cpu["a"]), cycles)
	cycles += 4
	_record(path, 0xA182)
	cpu["a"] = 0
	_set_nz(cpu, 0)
	cycles += 2
	_record(path, 0xA184)
	_ppu_write(ppu, ppu_events, 0xA184, 0x2005, 0, cycles)
	cycles += 4
	_record(path, 0xA187)
	_ppu_write(ppu, ppu_events, 0xA187, 0x2005, 0, cycles)
	cycles += 4
	_record(path, 0xA18A)
	cycles += 3 # JMP $A1A8.
	_record(path, 0xA1A8)
	cpu["a"] = int(ram[0x0078 + int(cpu["x"])])
	_set_nz(cpu, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA1AA)
	cpu["a"] = int(cpu["a"]) & 0x7F
	_set_nz(cpu, int(cpu["a"]))
	cycles += 2
	_record(path, 0xA1AC)
	if int(cpu["a"]) != 0:
		return {"ok": false, "error": "ROM `$A1AC` did not select the terminal `$78` release path."}
	cycles += 3
	_record(path, 0xA1C0)
	_mapper_write(mapper, mapper_writes, 0xA1C0, 0xE000, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA1C3)
	_ram_write(ram, writes, event_id, 0xA1C3, 0x0078, int(cpu["a"]))
	var release_cycle_offset := cycles
	cycles += 3
	_record(path, 0xA1C5)
	cpu["y"] = 0x18
	_set_nz(cpu, 0x18)
	cycles += 2
	_record(path, 0xA1C7)
	if int(cpu["sp"]) < 2:
		return {"ok": false, "error": "The source `$A1C7` JSR has no physical stack capacity."}
	stack[int(cpu["sp"])] = 0xA1
	stack[(int(cpu["sp"]) - 1) & 0xFF] = 0xC9
	cpu["sp"] = (int(cpu["sp"]) - 2) & 0xFF
	cycles += 6
	_record(path, 0xA1CB)
	cpu["x"] = int(ram[0x0078 + int(cpu["y"])])
	_set_nz(cpu, int(cpu["x"]))
	cycles += 4
	_record(path, 0xA1CD)
	cpu["a"] = 0
	_set_nz(cpu, 0)
	cycles += 2
	_record(path, 0xA1CF)
	cpu["a"] = (int(cpu["a"]) | int(ram[0x0022])) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(path, 0xA1D1)
	_mapper_write(mapper, mapper_writes, 0xA1D1, 0x8000, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA1D4)
	_mapper_write(mapper, mapper_writes, 0xA1D4, 0x8001, int(cpu["x"]))
	cycles += 4
	_record(path, 0xA1D7)
	cpu["x"] = int(ram[0x0079 + int(cpu["y"])])
	_set_nz(cpu, int(cpu["x"]))
	cycles += 4
	_record(path, 0xA1D9)
	cpu["a"] = 0x01
	_set_nz(cpu, 1)
	cycles += 2
	_record(path, 0xA1DB)
	cpu["a"] = (int(cpu["a"]) | int(ram[0x0022])) & 0xFF
	_set_nz(cpu, int(cpu["a"]))
	cycles += 3
	_record(path, 0xA1DD)
	_mapper_write(mapper, mapper_writes, 0xA1DD, 0x8000, int(cpu["a"]))
	cycles += 4
	_record(path, 0xA1E0)
	_mapper_write(mapper, mapper_writes, 0xA1E0, 0x8001, int(cpu["x"]))
	cycles += 4
	_record(path, 0xA1E3)
	var inner_rts := _stack_rts(stack, int(cpu["sp"]))
	if not bool(inner_rts.get("ok", false)) or int(inner_rts.get("pc", -1)) != 0xA1CA:
		return {"ok": false, "error": "The `$A1CB` helper RTS did not return to `$A1CA`."}
	cpu["sp"] = int(inner_rts["sp"])
	cpu["pc"] = int(inner_rts["pc"])
	cycles += 6
	_record(path, 0xA1CA)
	var outer_rts := _stack_rts(stack, int(cpu["sp"]))
	if not bool(outer_rts.get("ok", false)) or int(outer_rts.get("pc", -1)) != 0xC494:
		return {"ok": false, "error": "The `$A160` helper RTS did not return to `$C494`."}
	cpu["sp"] = int(outer_rts["sp"])
	cpu["pc"] = int(outer_rts["pc"])
	cycles += 6
	return {"ok": true, "cpu": cpu, "stack_page": stack,
		"cycles": cycles, "release_cycle_offset": release_cycle_offset}


func _validate_prefix(prefix: Dictionary, ram_image: Variant,
		ppu_shadows: Dictionary, source_frame: int) -> Dictionary:
	if not bool(prefix.get("ok", false)) \
			or String(prefix.get("status", "")) != "stopped_at_unresolved_source_predicate" \
			or String(prefix.get("source_rom_sha256", "")) != ROM_SHA256 \
			or bool(prefix.get("trace_state_used", true)) \
			or bool(prefix.get("emulator_data_used", true)) \
			or bool(prefix.get("candidate_state_used", false)) \
			or source_frame != 7266:
		return {"ok": false, "error": "A live ROM-source `$893B` prefix at candidate frame 7266 is required."}
	var source_event_id := String(prefix.get("source_event_id", ""))
	var boundary: Dictionary = prefix.get("boundary", {})
	var registers: Dictionary = prefix.get("boundary_registers", {}).duplicate(true)
	var stack_contract: Dictionary = prefix.get("stack_contract", {})
	var stack_value: Variant = prefix.get("stack_after", PackedByteArray())
	if source_event_id.is_empty() or int(boundary.get("pc", -1)) != WAIT_PC \
			or int(registers.get("pc", -1)) != WAIT_PC \
			or String(stack_contract.get("model", "")) != "physical_stack_page" \
			or not bool(stack_contract.get("physical_stack_page_known", false)) \
			or not bool(stack_contract.get("absolute_sp_known", false)) \
			or not stack_value is PackedByteArray or stack_value.size() != 0x100 \
			or int(registers.get("sp", -1)) != int(stack_contract.get("sp_at_893b", -2)):
		return {"ok": false, "error": "The `$893B` prefix must carry its checked physical CPU stack/PC boundary."}
	if not ram_image is Object or not ram_image.has_method("get_status"):
		return {"ok": false, "error": "IRQ RAM must come from the route's provenance-carrying source image."}
	var ram_status: Dictionary = ram_image.call("get_status")
	if String(ram_status.get("source_rom_sha256", "")) != ROM_SHA256 \
			or String(ram_status.get("status", "")) != "sparse_source_writes_only":
		return {"ok": false, "error": "IRQ RAM image does not match the pinned source ROM."}
	var ram: Dictionary = {}
	var known_values: Variant = ram_status.get("known_values", {})
	if not known_values is Dictionary:
		return {"ok": false, "error": "IRQ source RAM image has no known-byte map."}
	for address_variant in known_values:
		ram[int(address_variant)] = int(known_values[address_variant])
	var known_bits: Dictionary = ram_status.get("known_bits_by_address", {})
	for address_variant in known_bits:
		var bits: Dictionary = known_bits[address_variant]
		if int(bits.get("known_mask", 0)) == 0xFF:
			ram[int(address_variant)] = int(bits.get("known_value", -1))
	var prefix_ram: Dictionary = prefix.get("caller_ram_after", {})
	for address_variant in prefix_ram:
		ram[int(address_variant)] = int(prefix_ram[address_variant])
	for address in [0x001B, 0x0020, 0x0022, 0x0023, 0x0024, 0x0025,
			0x003B, 0x0078, 0x0079, 0x007C, 0x007D, 0x007E, 0x0090, 0x0091]:
		if not ram.has(address):
			return {"ok": false, "error": "ROM-source IRQ input `$%04X` is unknown." % address}
	var expected := {0x001B: 0xC0, 0x0022: 0x00, 0x0023: 0x07,
		0x0024: 0x00, 0x0025: 0x06, 0x003B: 0x55,
		0x0078: 0x04, 0x0079: 0x40, 0x007C: 0x80,
		0x007D: 0x00, 0x007E: 0x22, 0x0090: 0x00, 0x0091: 0x02}
	for address: int in expected:
		if int(ram[address]) != int(expected[address]):
			return {"ok": false, "error": "ROM-source IRQ input `$%04X` has `$%02X`, expected `$%02X`." % [address, int(ram[address]), int(expected[address])]}
	for name: String in ["ctrl_shadow", "mask_shadow"]:
		if not ppu_shadows.has(name) or int(ppu_shadows[name]) < 0 or int(ppu_shadows[name]) > 0xFF:
			return {"ok": false, "error": "Source PPU shadow `%s` is required." % name}
	return {"ok": true, "registers": registers, "ram": ram,
		"stack_page": stack_value, "wait_ram": {0x001B: ram[0x001B],
			0x0078: ram[0x0078], 0x0079: ram[0x0079], 0x003B: ram[0x003B]}}


func _initial_mapper_state(ram: Dictionary) -> Dictionary:
	return {"registers": [-1, -1, 0, 0, 0, 0, int(ram[0x0024]), int(ram[0x0025])],
		"known_register_mask": 0xC0, "command": int(ram[0x0023]),
		"prg_mode": (int(ram[0x0022]) & 0x40) != 0,
		"chr_inversion": (int(ram[0x0022]) & 0x80) != 0,
		"8000_prg_bank": int(ram[0x0024]),
		"a000_prg_bank": int(ram[0x0025]),
		"irq_latch": 128, "irq_counter": 1,
		"irq_enabled": true, "irq_pending": true,
		"registers_2_to_5_known": false,
		"source_rom_sha256": ROM_SHA256}


func _mapper_write(mapper: Dictionary, events: Array[Dictionary], source_pc: int,
		address: int, value: int) -> void:
	var normalized := value & 0xFF
	events.append({"source_pc": source_pc, "address": address, "value": normalized})
	if address == 0x8000:
		mapper["command"] = normalized
		mapper["prg_mode"] = (normalized & 0x40) != 0
		mapper["chr_inversion"] = (normalized & 0x80) != 0
	elif address == 0x8001:
		var index := int(mapper.get("command", 0)) & 0x07
		var registers: Array = mapper["registers"]
		registers[index] = normalized
		mapper["registers"] = registers
		mapper["known_register_mask"] = int(mapper.get("known_register_mask", 0)) | (1 << index)
		if index == 6:
			mapper["8000_prg_bank"] = normalized
		elif index == 7:
			mapper["a000_prg_bank"] = normalized
	elif address == 0xE000:
		mapper["irq_enabled"] = false
		mapper["irq_pending"] = false
	elif address == 0xE001:
		mapper["irq_enabled"] = true


func _ppu_write(ppu: Dictionary, events: Array[Dictionary], source_pc: int,
		register: int, value: int, cycle_offset: int) -> void:
	var normalized := value & 0xFF
	events.append({"operation": "write", "source_pc": source_pc,
		"ppu_register": register, "value": normalized,
		"cpu_cycle_offset_from_irq_edge": cycle_offset,
		"timing_status": "instruction-order source event; PPU dot is candidate-only"})
	if register == 0x2000:
		ppu["ctrl_shadow"] = normalized
	elif register == 0x2001:
		ppu["mask_shadow"] = normalized
	elif register == 0x2005:
		ppu["scroll_last"] = normalized


func _ram_write(ram: Dictionary, events: Array[Dictionary], event_id: String,
		source_pc: int, address: int, value: int) -> void:
	var normalized := value & 0xFF
	var event := {"source_pc": source_pc, "address": address,
		"value": normalized, "source_event_id": event_id}
	if ram.has(address):
		event["before"] = int(ram[address])
	ram[address] = normalized
	events.append(event)


func _stack_rts(stack: PackedByteArray, sp: int) -> Dictionary:
	if stack.size() != 0x100 or sp > 0xFD:
		return {"ok": false, "error": "RTS stack page or stack pointer is invalid."}
	var next_sp := (sp + 1) & 0xFF
	var low := int(stack[next_sp])
	next_sp = (next_sp + 1) & 0xFF
	var high := int(stack[next_sp])
	return {"ok": true, "sp": next_sp, "pc": (((high << 8) | low) + 1) & 0xFFFF}


func _stack_rti(stack: PackedByteArray, sp: int) -> Dictionary:
	if stack.size() != 0x100 or sp > 0xFC:
		return {"ok": false, "error": "RTI stack page or stack pointer is invalid."}
	var next_sp := (sp + 1) & 0xFF
	var status := int(stack[next_sp])
	var low := int(stack[(next_sp + 1) & 0xFF])
	var high := int(stack[(next_sp + 2) & 0xFF])
	return {"ok": true, "sp": (sp + 3) & 0xFF,
		"pc": ((high << 8) | low) & 0xFFFF, "p": status}


func _bit(cpu: Dictionary, value: int) -> void:
	var status := int(cpu["p"]) & 0x3D
	status |= value & 0xC0
	if (int(cpu["a"]) & value) == 0:
		status |= 0x02
	cpu["p"] = status


func _set_nz(cpu: Dictionary, value: int) -> void:
	var status := int(cpu["p"]) & 0x7D
	var normalized := value & 0xFF
	if normalized == 0:
		status |= 0x02
	if (normalized & 0x80) != 0:
		status |= 0x80
	cpu["p"] = status


func _record(path: Array[int], pc: int) -> void:
	path.append(pc)


func _hex_pc(value: String) -> int:
	var stripped := value.strip_edges().trim_prefix("$").trim_prefix("0x")
	return stripped.hex_to_int() if not stripped.is_empty() else -1


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}
