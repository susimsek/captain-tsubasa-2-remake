extends RefCounted
class_name RomPassConfirmationWaiterPostNmiExecutor
## Continues the shared PASS waiter from a scheduler-restored `$CC53` boundary
## through its ROM `$CCD1 RTS` return to `$D70F`.
## NMI deliveries are explicit source proofs; CPU/PPU timing is not modeled.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const HOLDER_MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/manifest.json"
const HOLDER_MANIFEST_SHA256 := "a5222fd8d3573e27fb2f530ea9c9baebe9eeb091f26a52ae9f861f8dd9a4f403"
const CALLER_PATH := "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/pass_confirmation_wait_return_D70C_D717.bin"
const CALLER_SHA256 := "19344ff4a339d04a6004f5ab7d4656bfe2a017f3e51c63770f5d4e300f723aa4"
const WAITER_PATH := "res://reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_shared_waiter_CC46_CCD2.bin"
const WAITER_SHA256 := "21a4cd33eb56fe3d4da516e0eff910ff375a8d7c3ff42bfa46dfb691a846d5cc"
const NMI_CONSUMER_SCRIPT := preload("res://scripts/gameplay/rom_normal_nmi_ppu_queue_consumer.gd")

const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const PASS_SLOT := 0x05
const POST_NMI_PC := 0xCC53
const WAITER_RETURN_PC := 0xD70F
const PASS_COUNT := 0x06
const FIRST_PACKET_ITERATIONS := 7
const REQUIRED_NMI_RECEIPTS := 8
const P_C := 0x01
const P_Z := 0x02
const P_V := 0x40
const P_N := 0x80

var error_message := ""
var _configured := false
var _caller_bytes := PackedByteArray()
var _waiter_bytes := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	if not FileAccess.file_exists(HOLDER_MANIFEST_PATH) \
			or FileAccess.get_sha256(HOLDER_MANIFEST_PATH) != HOLDER_MANIFEST_SHA256:
		return _fail("The PASS holder-transfer source manifest is missing or changed.")
	var manifest_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(HOLDER_MANIFEST_PATH))
	if not manifest_variant is Dictionary:
		return _fail("The PASS holder-transfer manifest is malformed.")
	var manifest: Dictionary = manifest_variant
	var source_rom: Dictionary = manifest.get("source_rom", {})
	if String(manifest.get("schema", "")) != "ct2-pass-receiver-holder-transfer-source-v1" \
			or String(source_rom.get("sha256", "")) != ROM_SHA256 \
			or int(source_rom.get("size_bytes", -1)) != 393232 \
			or int(source_rom.get("mapper", -1)) != 4:
		return _fail("The PASS waiter manifest does not identify the pinned mapper-4 ROM.")
	_caller_bytes = _load_caller_span(manifest)
	if _caller_bytes.is_empty():
		return false
	_waiter_bytes = _load_waiter_dependency(manifest)
	if _waiter_bytes.is_empty():
		return false
	if _caller_bytes != PackedByteArray([0x20, 0x46, 0xCC, 0xA9, 0x00,
			0x8D, 0x2D, 0x06, 0x68, 0x68, 0x60]) \
			or _waiter_bytes.size() != 140 \
			or _waiter_bytes.slice(13, 23) != PackedByteArray([
				0xAD, 0x15, 0x05, 0xD0, 0xF6, 0xA9, 0x01, 0x8D, 0x15, 0x05]) \
			or _waiter_bytes.slice(23, 140) != PackedByteArray([
				0xA0, 0x4F, 0xA2, 0x00, 0x8A, 0x9D, 0xA5, 0x04, 0xE8, 0x88,
				0xD0, 0xF9, 0xA9, 0x18, 0x8D, 0xA5, 0x04, 0x8D, 0xC0, 0x04,
				0xA9, 0x20, 0x8D, 0xA6, 0x04, 0x68, 0x48, 0x09, 0x08, 0x4A,
				0x6E, 0xA6, 0x04, 0x4A, 0x6E, 0xA6, 0x04, 0x09, 0x20, 0x8D,
				0xA7, 0x04, 0x8D, 0xC2, 0x04, 0xAD, 0xA6, 0x04, 0x18, 0x69,
				0x20, 0x8D, 0xC1, 0x04, 0xA9, 0x80, 0x8D, 0x15, 0x05, 0x68,
				0x38, 0xE9, 0x01, 0x10, 0xAF, 0xA9, 0x01, 0x20, 0x0F, 0xCB,
				0xAD, 0x15, 0x05, 0xD0, 0xF6, 0xA9, 0x01, 0x8D, 0x15, 0x05,
				0xA9, 0x20, 0x8D, 0xA5, 0x04, 0xA9, 0xE0, 0x8D, 0xA6, 0x04,
				0xA9, 0x23, 0x8D, 0xA7, 0x04, 0xA2, 0x00, 0x8A, 0x9D, 0xA8,
				0x04, 0xE8, 0xE0, 0x21, 0xD0, 0xF8, 0xA9, 0x80, 0x8D, 0x15,
				0x05, 0xA9, 0x01, 0x20, 0x0F, 0xCB, 0x60]):
		return _fail("The pinned `$CC53-$CCD1` waiter instructions differ from the source bytes.")
	_configured = true
	return true


## Executes exactly one source-owned `$CC53` counted packet iteration and stops
## before the scheduler-owned JSR/save at `$CC50` or `$CCA0`. It performs no
## NMI, scheduler scan, queue consumption, or PPU transfer.
func execute_next_counted_packet_yield(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var valid := _validate_boundary(boundary, [], false, true)
	if not bool(valid.get("ok", false)):
		return _failure(String(valid.get("status", "invalid_pass_waiter_boundary")),
			String(valid.get("error", "Invalid PASS waiter `$CC53` step boundary."))
			+ " boundary=" + JSON.stringify(_boundary_summary(boundary)))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var cpu := {"pc": POST_NMI_PC, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF}
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var packet := _build_counted_packet(ram, stack, cpu, writes,
		stack_writes, stack_reads, reads, instruction_pcs)
	if not bool(packet.get("ok", false)):
		return _failure(String(packet.get("status", "unsupported_packet_state")),
			String(packet.get("error", "The `$CC53` source packet path refused the live state.")))
	var callsite_pc := int(packet["callsite_pc"])
	var resume_pc := int(packet["resume_pc"])
	cpu["pc"] = callsite_pc
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = callsite_pc
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS waiter counted packet ready at `$%04X` before scheduler JSR/save" % callsite_pc
	var call_request := {"kind": "rom_jsr_request", "callsite_pc": callsite_pc,
		"target_pc": 0xCB0F, "target_bank": 0x1E,
		"return_word": (callsite_pc + 2) & 0xFFFF,
		"return_pc": resume_pc, "sp_before_push": int(cpu["sp"]),
		"scheduler_must_push_call_frame": true}
	return {
		"ok": true,
		"status": "pass_waiter_counted_packet_yield_ready" if callsite_pc == 0xCC50 \
			else "pass_waiter_terminal_counted_packet_yield_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest": HOLDER_MANIFEST_PATH,
		"source_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"entry_pc": POST_NMI_PC,
		"entry_bank": 0x1E,
		"entry_sp": int(boundary["sp"]),
		"exit_pc": callsite_pc,
		"exit_bank": 0x1E,
		"resume_pc_after_scheduler_jsr": resume_pc,
		"counter_after_decrement": int(packet.get("counter_after_decrement", -1)),
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": instruction_pcs,
		"source_reads": reads,
		"source_writes": writes,
		"source_stack_writes": stack_writes,
		"source_stack_reads": stack_reads,
		"call_request": call_request,
		"next_boundary_snapshot": next_boundary,
		"scheduler_save_executed": false,
		"external_nmi_consumed": false,
		"normal_nmi_count": 0,
		"ppu_bus_events": [],
		"ppu_effects_applied": false,
		"apu_events": [],
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"input_boundary_unchanged": entry_ram == boundary["ram_image"] \
			and entry_stack == boundary["stack_page"],
		"scope": "One ROM-counted packet iteration through its real scheduler yield callsite; caller owns the JSR/save, NMI, and PPU transfer."
	}


## Executes the ROM busy-poll branch taken when `$0515` is still set at
## `$CC53`. It follows `LDA $0515; BNE $CC4E; LDA #$01` to the real
## `$CC50->$CB0F` scheduler callsite without rebuilding or consuming a packet.
func execute_busy_poll_scheduler_yield(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var valid := _validate_busy_poll_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _failure(String(valid.get("status", "invalid_busy_poll_boundary")),
			String(valid.get("error", "Invalid PASS waiter busy-poll boundary."))
			+ " boundary=" + JSON.stringify(_boundary_summary(boundary)))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var cpu := {"pc": POST_NMI_PC, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF}
	var instruction_pcs: Array[int] = [0xCC53, 0xCC56, 0xCC4E, 0xCC50]
	var reads: Array[Dictionary] = [{"source_pc": 0xCC53,
		"address": 0x0515, "value": int(ram[0x0515])}]
	_set_a(cpu, int(ram[0x0515]))
	if (int(cpu["p"]) & P_Z) != 0:
		return _failure("busy_poll_branch_not_taken",
			"The ROM `$CC56 BNE $CC4E` branch was not taken despite `$0515=$80`.")
	_set_a(cpu, 0x01)
	cpu["pc"] = 0xCC50
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = 0xCC50
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["source_label"] = "ROM-byte PASS confirmation waiter busy poll `$CC53->$CC4E->$CC50`; scheduler JSR/save pending"
	var call_request := {"kind": "rom_jsr_request", "callsite_pc": 0xCC50,
		"target_pc": 0xCB0F, "target_bank": 0x1E,
		"return_word": 0xCC52, "return_pc": 0xCC53,
		"sp_before_push": int(cpu["sp"]),
		"scheduler_must_push_call_frame": true}
	return {"ok": true, "status": "pass_waiter_busy_poll_yield_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest": "res://reference/rom_extract/gameplay/pass_receiver_holder_transfer/manifest.json",
		"source_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"entry_pc": POST_NMI_PC, "entry_bank": 0x1E,
		"entry_sp": int(boundary["sp"]), "exit_pc": 0xCC50, "exit_bank": 0x1E,
		"resume_pc_after_scheduler_jsr": POST_NMI_PC,
		"registers": cpu.duplicate(true), "source_instruction_pcs": instruction_pcs,
		"source_reads": reads, "source_writes": [],
		"source_stack_writes": [], "source_stack_reads": [],
		"call_request": call_request, "next_boundary_snapshot": next_boundary,
		"scheduler_save_executed": false, "external_nmi_consumed": false,
		"normal_nmi_count": 0, "ppu_bus_events": [], "ppu_effects_applied": false,
		"apu_events": [], "apu_effects_applied": false,
		"holder_transfer_applied": false, "source_cycle_timing_modeled": false,
		"trace_state_used": false, "emulator_data_used": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"input_boundary_unchanged": true,
		"source_control_flow": [{"source_pc": 0xCC56, "mnemonic": "BNE",
			"taken": true, "target_pc": 0xCC4E}],
		"scope": "ROM busy-poll branch to its existing `$CC50->$CB0F` scheduler yield; queue consumer and normal NMI remain caller-owned."}


## Executes the source `$CCA3` terminal packet and stops immediately before
## the scheduler-owned `$CCCE->$CB0F` JSR/save and NMI. The caller must still
## consume that queued packet through the ordinary NMI route.
func execute_next_terminal_packet_yield(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var valid := _validate_terminal_packet_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _failure(String(valid.get("status", "invalid_pass_waiter_boundary")),
			String(valid.get("error", "Invalid PASS waiter `$CCA3` terminal-packet boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var cpu := {"pc": 0xCCA3, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF}
	var writes: Array[Dictionary] = []
	var reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var final_packet := _build_terminal_packet(ram, cpu, writes, reads, instruction_pcs)
	if not bool(final_packet.get("ok", false)):
		return _failure(String(final_packet.get("status", "unsupported_final_packet_state")),
			String(final_packet.get("error", "The `$CCA3` terminal-packet path refused the live state.")))
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = 0xCCCE
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS waiter terminal packet ready at `$CCCE` before scheduler JSR/save"
	var call_request := {"kind": "rom_jsr_request", "callsite_pc": 0xCCCE,
		"target_pc": 0xCB0F, "target_bank": 0x1E,
		"return_word": 0xCCD0, "return_pc": 0xCCD1,
		"sp_before_push": int(cpu["sp"]),
		"scheduler_must_push_call_frame": true}
	return {
		"ok": true,
		"status": "pass_waiter_terminal_packet_yield_ready",
		"rom_sha256": ROM_SHA256,
		"source_manifest": HOLDER_MANIFEST_PATH,
		"source_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"entry_pc": 0xCCA3,
		"entry_bank": 0x1E,
		"entry_sp": int(boundary["sp"]),
		"exit_pc": 0xCCCE,
		"exit_bank": 0x1E,
		"resume_pc_after_scheduler_jsr": 0xCCD1,
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": instruction_pcs,
		"source_reads": reads,
		"source_writes": writes,
		"source_stack_writes": [],
		"source_stack_reads": [],
		"call_request": call_request,
		"next_boundary_snapshot": next_boundary,
		"scheduler_save_executed": false,
		"external_nmi_consumed": false,
		"normal_nmi_count": 0,
		"ppu_bus_events": [],
		"ppu_effects_applied": false,
		"apu_events": [],
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"input_boundary_unchanged": entry_ram == boundary["ram_image"] \
			and entry_stack == boundary["stack_page"],
		"scope": "One ROM terminal-packet iteration through its real scheduler yield callsite; caller owns the JSR/save, NMI, and PPU transfer."
	}


## Executes the ROM `$CCD1 RTS` after the terminal packet's scheduler/NMI
## round-trip and returns through the preserved `$D70C` caller frame to `$D70F`.
func execute_waiter_rts_return(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var valid := _validate_waiter_rts_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _failure(String(valid.get("status", "invalid_pass_waiter_rts_boundary")),
			String(valid.get("error", "Invalid PASS waiter `$CCD1` RTS boundary."))
			+ " boundary=" + JSON.stringify(_boundary_summary(boundary)))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var cpu := {"pc": 0xCCD1, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF}
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xCCD1]
	var returned := _pop_rts(stack, cpu, stack_reads, 0xCCD1)
	if not bool(returned.get("ok", false)) or int(returned.get("resume_pc", -1)) != 0xD70F \
			or int(cpu["sp"]) != 0x4A:
		return _failure("source_return_stack_mismatch",
			"The ROM `$CCD1 RTS` did not restore caller `$D70F`/SP `$4A`.")
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = 0xD70F
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS waiter `$CCD1 RTS->$D70F` caller return"
	return {
		"ok": true,
		"status": "pass_confirmation_waiter_returned_to_d70f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": HOLDER_MANIFEST_PATH,
		"source_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"entry_pc": 0xCCD1,
		"entry_bank": 0x1E,
		"entry_sp": int(boundary["sp"]),
		"exit_pc": 0xD70F,
		"exit_bank": 0x1E,
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": instruction_pcs,
		"source_reads": [],
		"source_writes": [],
		"source_stack_writes": [],
		"source_stack_reads": stack_reads,
		"scheduler_save_executed": false,
		"external_nmi_consumed": false,
		"normal_nmi_count": 0,
		"ppu_bus_events": [],
		"ppu_effects_applied": false,
		"apu_events": [],
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"next_boundary_snapshot": next_boundary,
		"input_boundary_unchanged": entry_ram == boundary["ram_image"] \
			and entry_stack == boundary["stack_page"],
		"scope": "One source RTS restores the preserved `$D70C` caller return; `$D70F` instructions are not executed."
	}


## Executes the extracted `$D70F-$D716` caller tail after the waiter RTS:
## `LDA #$00; STA $062D; PLA; PLA; RTS`. The return address is read from the
## live task stack; the full trace shows the natural return to `$D568`.
func execute_waiter_caller_cleanup(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var valid := _validate_waiter_caller_cleanup_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _failure(String(valid.get("status", "invalid_pass_waiter_cleanup_boundary")),
			String(valid.get("error", "Invalid PASS waiter `$D70F` cleanup boundary.")))
	var cleanup_bytes := _caller_bytes.slice(3, 11)
	if cleanup_bytes != PackedByteArray([0xA9, 0x00, 0x8D, 0x2D, 0x06,
			0x68, 0x68, 0x60]):
		return _failure("source_integrity_failure",
			"The extracted `$D70F-$D716` cleanup bytes no longer match the pinned caller sequence.")
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var entry_boundary_snapshot := boundary.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var cpu := {"pc": 0xD70F, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF}
	var writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	# LDA #$00 at `$D70F`; it sets A and N/Z before the memory clear.
	instruction_pcs.append(0xD70F)
	_set_a(cpu, 0)
	# STA $062D at `$D711`; the ROM uses the following PC `$D714` for its trace.
	instruction_pcs.append(0xD711)
	var old_062d := int(ram[0x062D])
	_write(ram, writes, 0xD711, 0x062D, 0)
	writes.back()["old"] = old_062d
	# The two PLA instructions discard the source caller's saved bytes.
	instruction_pcs.append(0xD714)
	_set_a(cpu, _pop_value(stack, cpu, stack_reads, 0xD714, "caller_saved_byte_1"))
	instruction_pcs.append(0xD715)
	_set_a(cpu, _pop_value(stack, cpu, stack_reads, 0xD715, "caller_saved_byte_2"))
	# RTS consumes the return word produced by the live D70F caller frame.
	instruction_pcs.append(0xD716)
	var returned := _pop_rts(stack, cpu, stack_reads, 0xD716)
	var natural_return_pc := int(returned.get("resume_pc", -1))
	if not bool(returned.get("ok", false)) or natural_return_pc != 0xD568 \
			or int(cpu["sp"]) != ((int(boundary["sp"]) + 4) & 0xFF):
		return _failure("source_return_stack_mismatch",
			"The live `$D70F` caller stack did not naturally return to `$D568` after two PLA instructions and RTS.")
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = natural_return_pc
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM-byte PASS waiter `$D70F-$D716` caller cleanup returned to `$D568`"
	return {
		"ok": true,
		"status": "pass_waiter_caller_cleanup_returned",
		"rom_sha256": ROM_SHA256,
		"source_manifest": HOLDER_MANIFEST_PATH,
		"source_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"source_span": CALLER_PATH,
		"source_span_sha256": CALLER_SHA256,
		"source_instruction_bytes": cleanup_bytes,
		"entry_pc": 0xD70F,
		"entry_bank": 0x1E,
		"entry_sp": int(boundary["sp"]),
		"exit_pc": natural_return_pc,
		"exit_bank": 0x1E,
		"natural_return_pc": natural_return_pc,
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": instruction_pcs,
		"source_reads": [],
		"source_writes": writes,
		"source_stack_writes": [],
		"source_stack_reads": stack_reads,
		"scheduler_save_executed": false,
		"external_nmi_consumed": false,
		"normal_nmi_count": 0,
		"ppu_bus_events": [],
		"ppu_effects_applied": false,
		"apu_events": [],
		"apu_effects_applied": false,
		"holder_transfer_applied": false,
		"source_cycle_timing_modeled": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"entry_boundary_snapshot": entry_boundary_snapshot,
		"next_boundary_snapshot": next_boundary,
		"input_boundary_unchanged": entry_ram == boundary["ram_image"] \
			and entry_stack == boundary["stack_page"],
		"trace_support": "Full-stack FCEUX trace at `$D716` contains `$014D/$014E=$67/$D5`, which yields `$D568`; a later `$E07E JSR $E709` produces a separate `$E709` hook.",
		"scope": "ROM-derived caller cleanup consumes the actual supplied stack and accepts only a natural `$D568` return; it does not execute the subsequent field-entry route."
	}


## `boundary` is the real or test `$CC53` task-resume snapshot. Each NMI proof
## must describe one normal `$C799->$C8FB` dispatch; the verified consumer
## drains the ROM-built secondary queue before the next source resume.
func execute_to_waiter_return(boundary: Dictionary,
		normal_nmi_proofs: Array) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _failure("source_integrity_failure", error_message)
	var valid := _validate_boundary(boundary, normal_nmi_proofs)
	if not bool(valid.get("ok", false)):
		return _failure(String(valid.get("status", "invalid_pass_waiter_boundary")),
			String(valid.get("error", "Invalid PASS waiter resume boundary.")))
	var ram: PackedByteArray = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack: PackedByteArray = (boundary["stack_page"] as PackedByteArray).duplicate()
	var cpu := {"pc": POST_NMI_PC, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary.get("p_known_mask", 0xFF)) & 0xFF}
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var nmi_receipts: Array[Dictionary] = []
	var ppu_bus_events: Array[Dictionary] = []
	var current_pc := POST_NMI_PC
	var proof_index := 0

	# The six-count source PHA at `$CC4D` is decremented after each generated
	# packet. Values 6..0 produce seven packet yields; the seventh exits to CCA0.
	for packet_index in FIRST_PACKET_ITERATIONS:
		if current_pc != POST_NMI_PC:
			return _failure("source_resume_mismatch", "Expected ROM continuation `$CC53` before packet %d." % packet_index)
		var expected_counter := PASS_COUNT - packet_index
		if int(stack[0x48]) != expected_counter:
			return _failure("source_counter_mismatch", "The ROM waiter counter at stack `$48` is $%02X, expected $%02X." % [int(stack[0x48]), expected_counter])
		var packet := _build_counted_packet(ram, stack, cpu, writes,
			stack_writes, stack_reads, reads, instruction_pcs)
		if not bool(packet.get("ok", false)):
			return _failure(String(packet.get("status", "unsupported_packet_state")),
				String(packet.get("error", "The `$CC53` source packet path refused the live state.")))
		var callsite_pc := int(packet["callsite_pc"])
		var resume_pc := int(packet["resume_pc"])
		var yield_result := _yield_through_source_nmi(callsite_pc, resume_pc,
			ram, stack, cpu, stack_writes, stack_reads, instruction_pcs,
			normal_nmi_proofs[proof_index], proof_index)
		if not bool(yield_result.get("ok", false)):
			return _failure(String(yield_result.get("status", "normal_nmi_queue_failure")),
				String(yield_result.get("error", "The normal-NMI queue consumer rejected a waiter packet.")))
		ram = yield_result["ram"]
		cpu = yield_result["cpu"]
		current_pc = resume_pc
		nmi_receipts.append(yield_result["receipt"])
		ppu_bus_events.append_array(yield_result["ppu_bus_events"])
		proof_index += 1
		if packet_index < 6 and (current_pc != POST_NMI_PC or int(cpu["sp"]) != 0x47):
			return _failure("source_resume_mismatch", "The ROM `$CC50->$CB0F` NMI return did not resume at `$CC53` with its persistent counter.")

	# The last counted packet takes `$CC9E->$CB0F`; after that NMI the source
	# resumes at `$CCA3`, constructs the terminal packet, and yields at `$CCCE`.
	if current_pc != 0xCCA3 or int(cpu["sp"]) != 0x48:
		return _failure("source_tail_mismatch", "The `$CC9E` NMI did not resume the counter tail at `$CCA3`.")
	var final_packet := _build_terminal_packet(ram, cpu, writes, reads, instruction_pcs)
	if not bool(final_packet.get("ok", false)):
		return _failure(String(final_packet.get("status", "unsupported_final_packet_state")),
			String(final_packet.get("error", "The `$CCA3` final-packet path refused the live state.")))
	var final_yield := _yield_through_source_nmi(0xCCCE, 0xCCD1,
		ram, stack, cpu, stack_writes, stack_reads, instruction_pcs,
		normal_nmi_proofs[proof_index], proof_index)
	if not bool(final_yield.get("ok", false)):
		return _failure(String(final_yield.get("status", "normal_nmi_queue_failure")),
			String(final_yield.get("error", "The normal-NMI queue consumer rejected the terminal packet.")))
	ram = final_yield["ram"]
	cpu = final_yield["cpu"]
	nmi_receipts.append(final_yield["receipt"])
	ppu_bus_events.append_array(final_yield["ppu_bus_events"])
	proof_index += 1
	if proof_index != REQUIRED_NMI_RECEIPTS or int(ram[0x0515]) != 0 \
			or int(cpu["pc"]) != 0xCCD1:
		return _failure("source_tail_mismatch", "The final NMI did not consume the terminal queue and resume at `$CCD1`.")

	# ROM `$CCD1 RTS` returns through the original `$D70C JSR $CC46` frame.
	instruction_pcs.append(0xCCD1)
	var waiter_rts := _pop_rts(stack, cpu, stack_reads, 0xCCD1)
	if not bool(waiter_rts.get("ok", false)) \
			or int(waiter_rts.get("resume_pc", -1)) != WAITER_RETURN_PC \
			or int(cpu["sp"]) != 0x4A:
		return _failure("source_return_stack_mismatch", "The ROM `$CCD1 RTS` did not return to `$D70F` with the caller SP restored.")
	var output_ram := ram.duplicate()
	for stack_index in STACK_SIZE:
		output_ram[0x0100 + stack_index] = stack[stack_index]
	var next_boundary := boundary.duplicate(true)
	next_boundary["pc"] = WAITER_RETURN_PC
	next_boundary["sp"] = int(cpu["sp"])
	next_boundary["a"] = int(cpu["a"])
	next_boundary["x"] = int(cpu["x"])
	next_boundary["y"] = int(cpu["y"])
	next_boundary["p"] = int(cpu["p"])
	next_boundary["p_known_mask"] = int(cpu["p_known_mask"])
	next_boundary["ram_image"] = output_ram.duplicate()
	next_boundary["stack_page"] = stack.duplicate()
	next_boundary["source_label"] = "ROM `$CC53->$CCD1 RTS` returned PASS waiter to `$D70F`"
	return {
		"ok": true,
		"status": "pass_confirmation_waiter_returned_to_d70f",
		"rom_sha256": ROM_SHA256,
		"source_manifest": HOLDER_MANIFEST_PATH,
		"source_manifest_sha256": HOLDER_MANIFEST_SHA256,
		"entry_pc": POST_NMI_PC,
		"entry_bank": 0x1E,
		"entry_sp": int(boundary["sp"]),
		"exit_pc": WAITER_RETURN_PC,
		"exit_bank": 0x1E,
		"registers": cpu.duplicate(true),
		"source_instruction_pcs": instruction_pcs,
		"source_reads": reads,
		"source_writes": writes,
		"source_stack_writes": stack_writes,
		"source_stack_reads": stack_reads,
		"normal_nmi_receipts": nmi_receipts,
		"normal_nmi_count": nmi_receipts.size(),
		"scheduler_save_executed": false,
		"ppu_bus_events": ppu_bus_events,
		"ppu_effects_applied": false,
		"apu_events": [],
		"apu_effects_applied": false,
		"source_cycle_timing_modeled": false,
		"holder_transfer_applied": false,
		"trace_state_used": false,
		"emulator_data_used": false,
		"test_fixture": bool(boundary.get("test_fixture", false)),
		"next_boundary_snapshot": next_boundary,
		"input_boundary_unchanged": entry_ram == boundary["ram_image"] \
			and entry_stack == boundary["stack_page"],
		"scope": "ROM waiter bytes and the checked normal-NMI secondary-queue consumer; live NMI cadence and PPU register effects remain caller-owned.",
		"evidence_gaps": [
			"No retained same-input FCEUX snapshot records the `$CC53` `$0515` branch values or the waiter return stack.",
			"The eight normal-NMI receipts and scheduler resumes are caller-supplied; this executor does not prove their live route cadence.",
			"The NMI consumer emits PPU bus events but does not apply PPU register or memory effects.",
		],
	}


func _build_counted_packet(ram: PackedByteArray, stack: PackedByteArray,
		cpu: Dictionary, writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_reads: Array[Dictionary], reads: Array[Dictionary],
		instruction_pcs: Array[int]) -> Dictionary:
	if int(cpu["pc"]) != POST_NMI_PC or int(ram[0x0515]) != 0 \
			or int(cpu["sp"]) != 0x47 or int(stack[0x48]) < 0 \
			or int(stack[0x48]) > PASS_COUNT:
		return {"ok": false, "status": "unsupported_cc53_boundary",
			"error": "`$CC53` requires the post-NMI clear queue flag and the live PASS count/caller stack."}
	instruction_pcs.append_array([0xCC53, 0xCC56, 0xCC58, 0xCC5A, 0xCC5D, 0xCC5F])
	reads.append({"source_pc": 0xCC53, "address": 0x0515, "value": 0})
	_set_a(cpu, 0)
	_set_a(cpu, 1)
	_write(ram, writes, 0xCC5A, 0x0515, 1)
	_set_y(cpu, 0x4F)
	_set_x(cpu, 0)
	for index in 0x4F:
		instruction_pcs.append_array([0xCC61, 0xCC62, 0xCC65, 0xCC66, 0xCC67])
		_set_a(cpu, int(cpu["x"]))
		_write(ram, writes, 0xCC62, 0x04A5 + int(cpu["x"]), int(cpu["a"]))
		_set_x(cpu, int(cpu["x"]) + 1)
		_set_y(cpu, int(cpu["y"]) - 1)
	instruction_pcs.append_array([0xCC69, 0xCC6B, 0xCC6E, 0xCC71, 0xCC73, 0xCC76,
		0xCC77, 0xCC78, 0xCC7A, 0xCC7B, 0xCC7E, 0xCC7F, 0xCC82, 0xCC84,
		0xCC87, 0xCC8A, 0xCC8D, 0xCC8E, 0xCC90, 0xCC93, 0xCC95, 0xCC98,
		0xCC99, 0xCC9A, 0xCC9C])
	_set_a(cpu, 0x18)
	_write(ram, writes, 0xCC6B, 0x04A5, 0x18)
	_write(ram, writes, 0xCC6E, 0x04C0, 0x18)
	_set_a(cpu, 0x20)
	_write(ram, writes, 0xCC73, 0x04A6, 0x20)
	var counter_before_packet := _pop_value(stack, cpu, stack_reads, 0xCC76,
		"pass_counter_before_packet")
	_set_a(cpu, counter_before_packet)
	_push_value(stack, cpu, stack_writes, counter_before_packet, 0xCC77)
	_set_a(cpu, int(cpu["a"]) | 0x08)
	_lsr_a(cpu)
	_ror_memory(ram, cpu, 0x04A6, writes, 0xCC7B)
	_lsr_a(cpu)
	_ror_memory(ram, cpu, 0x04A6, writes, 0xCC7F)
	_set_a(cpu, int(cpu["a"]) | 0x20)
	_write(ram, writes, 0xCC84, 0x04A7, int(cpu["a"]))
	_write(ram, writes, 0xCC87, 0x04C2, int(cpu["a"]))
	reads.append({"source_pc": 0xCC8A, "address": 0x04A6, "value": int(ram[0x04A6])})
	_set_a(cpu, int(ram[0x04A6]))
	_set_flag(cpu, P_C, false)
	_adc(cpu, 0x20)
	_write(ram, writes, 0xCC90, 0x04C1, int(cpu["a"]))
	_set_a(cpu, 0x80)
	_write(ram, writes, 0xCC95, 0x0515, 0x80)
	var counter := _pop_value(stack, cpu, stack_reads, 0xCC98, "pass_counter")
	_set_a(cpu, counter)
	_set_flag(cpu, P_C, true)
	_sbc(cpu, 1)
	var callsite_pc := 0xCC50
	var resume_pc := 0xCC53
	if (int(cpu["p"]) & P_N) != 0:
		# `$CC9C BPL $CC4D` is false at counter -1 and falls through to CC9E.
		instruction_pcs.append_array([0xCC9E, 0xCCA0])
		_set_a(cpu, 1)
		callsite_pc = 0xCCA0
		resume_pc = 0xCCA3
	else:
		instruction_pcs.append_array([0xCC4D, 0xCC4E, 0xCC50])
		_push_value(stack, cpu, stack_writes, int(cpu["a"]), 0xCC4D)
		_set_a(cpu, 1)
	return {"ok": true, "callsite_pc": callsite_pc,
		"resume_pc": resume_pc, "counter_after_decrement": int(cpu["a"]) if callsite_pc == 0xCCA0 else int(stack[0x48])}


func _build_terminal_packet(ram: PackedByteArray, cpu: Dictionary,
		writes: Array[Dictionary], reads: Array[Dictionary],
		instruction_pcs: Array[int]) -> Dictionary:
	if int(cpu["pc"]) != 0xCCA3 or int(ram[0x0515]) != 0:
		return {"ok": false, "status": "unsupported_cca3_boundary",
			"error": "`$CCA3` requires the NMI-cleared terminal queue state."}
	instruction_pcs.append_array([0xCCA3, 0xCCA6, 0xCCA8, 0xCCAA, 0xCCAD, 0xCCAF,
		0xCCB2, 0xCCB4, 0xCCB7, 0xCCB9, 0xCCBC])
	reads.append({"source_pc": 0xCCA3, "address": 0x0515, "value": 0})
	_set_a(cpu, 0)
	_set_a(cpu, 1)
	_write(ram, writes, 0xCCAA, 0x0515, 1)
	_set_a(cpu, 0x20)
	_write(ram, writes, 0xCCAF, 0x04A5, 0x20)
	_set_a(cpu, 0xE0)
	_write(ram, writes, 0xCCB4, 0x04A6, 0xE0)
	_set_a(cpu, 0x23)
	_write(ram, writes, 0xCCB9, 0x04A7, 0x23)
	_set_x(cpu, 0)
	for index in 0x21:
		instruction_pcs.append_array([0xCCBE, 0xCCBF, 0xCCC2, 0xCCC3, 0xCCC5])
		_set_a(cpu, int(cpu["x"]))
		_write(ram, writes, 0xCCBF, 0x04A8 + int(cpu["x"]), int(cpu["a"]))
		_set_x(cpu, int(cpu["x"]) + 1)
		_set_compare_flags(cpu, int(cpu["x"]), 0x21)
	instruction_pcs.append_array([0xCCC7, 0xCCC9, 0xCCCC, 0xCCCE])
	_set_a(cpu, 0x80)
	_write(ram, writes, 0xCCC9, 0x0515, 0x80)
	_set_a(cpu, 1)
	cpu["pc"] = 0xCCCE
	return {"ok": true}


func _yield_through_source_nmi(callsite_pc: int, resume_pc: int,
		ram: PackedByteArray, stack: PackedByteArray, cpu: Dictionary,
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		instruction_pcs: Array[int], nmi_proof_variant: Variant,
		nmi_index: int) -> Dictionary:
	if not nmi_proof_variant is Dictionary:
		return {"ok": false, "status": "missing_nmi_proof", "error": "NMI receipt %d is not a dictionary." % nmi_index}
	instruction_pcs.append(0xCB0F)
	var call := _push_jsr(stack, cpu, stack_writes, callsite_pc, 0xCB0F)
	if int(ram[0x0515]) != 0x80:
		return {"ok": false, "status": "packet_not_ready", "error": "ROM waiter callsite `$%04X` did not have `$0515=$80` before NMI %d." % [callsite_pc, nmi_index]}
	var consumer = NMI_CONSUMER_SCRIPT.new()
	var consumed: Dictionary = consumer.consume(ram, {}, nmi_proof_variant)
	if not bool(consumed.get("ok", false)) \
			or String(consumed.get("queue_kind", "")) != "secondary" \
			or int(consumed.get("source_ready_flag_after", -1)) != 0:
		return {"ok": false, "status": "normal_nmi_queue_failure",
			"error": "Source NMI %d did not consume the waiter secondary packet: %s" % [nmi_index, str(consumed)]}
	ram = consumed["updated_ram"]
	var rts := _pop_rts(stack, cpu, stack_reads, 0xCB0F)
	if not bool(rts.get("ok", false)) or int(rts.get("resume_pc", -1)) != resume_pc:
		return {"ok": false, "status": "scheduler_return_stack_mismatch",
			"error": "NMI %d scheduler RTS did not restore `$%04X`: %s" % [nmi_index, resume_pc, str(rts)]}
	return {"ok": true, "ram": ram, "cpu": cpu,
		"ppu_bus_events": consumed.get("bus_events", []),
		"receipt": {"index": nmi_index, "callsite_pc": callsite_pc,
			"resume_pc": resume_pc, "return_word": int(call["return_word"]),
			"queue_kind": consumed.get("queue_kind", ""),
			"source_flag_before": consumed.get("source_ready_flag_before", -1),
			"source_flag_after": consumed.get("source_ready_flag_after", -1),
			"packet_summaries": consumed.get("packets", []),
			"ppu_write_count": consumed.get("ppu_write_count", -1)}}


func _validate_boundary(boundary: Dictionary, normal_nmi_proofs: Array,
		require_full_nmi_proofs: bool = true,
		allow_decremented_counter: bool = false) -> Dictionary:
	# Scheduler task records do not save P. The resumed source prefix establishes
	# the flags it branches on before using them, so accept the scheduler-derived
	# known-bit mask instead of requiring an impossible full-P restore.
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "capture_state_rejected",
				"error": "Emulator captures cannot seed the PASS waiter executor."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var source_label := String(boundary.get("source_label", ""))
	var source_label_valid := source_label.begins_with("ROM-byte PASS confirmation") \
		or source_label.begins_with("ROM-byte PASS waiter") \
		or (bool(boundary.get("test_fixture", false)) \
			and source_label == "synthetic PASS `$CC53` post-NMI waiter fixture")
	var stack_counter_valid := false
	if stack is PackedByteArray and (stack as PackedByteArray).size() > 0x48:
		var stack_counter := int((stack as PackedByteArray)[0x48])
		if allow_decremented_counter:
			stack_counter_valid = stack_counter >= 0 and stack_counter <= PASS_COUNT
		else:
			stack_counter_valid = stack_counter == PASS_COUNT
	if not bool(boundary.get("ok", true)) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != PASS_SLOT \
			or int(boundary.get("active_task_slot", -1)) != PASS_SLOT \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != POST_NMI_PC \
			or int(boundary.get("sp", -1)) != 0x47 \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or not mapper is Dictionary \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("fixed_low", mapper.get("fixed_bank", -1))) != 0x1E \
			or int(mapper.get("fixed_high", mapper.get("fixed_bank", -1))) != 0x1F \
			or not ram is PackedByteArray or (ram as PackedByteArray).size() != RAM_SIZE \
			or not stack is PackedByteArray or (stack as PackedByteArray).size() != STACK_SIZE \
			or not source_label_valid \
			or int((ram as PackedByteArray)[0]) != PASS_SLOT \
			or int((ram as PackedByteArray)[0x0024]) != 0x1C \
			or int((ram as PackedByteArray)[0x0025]) != 0x1D \
			or int((ram as PackedByteArray)[0x0515]) != 0 \
			or int((ram as PackedByteArray)[0x0498]) != 0 \
			or not stack_counter_valid \
			or int((stack as PackedByteArray)[0x49]) != 0x0E \
			or int((stack as PackedByteArray)[0x4A]) != 0xD7 \
			or int(boundary.get("a", -1)) < 0 or int(boundary.get("a", -1)) > 0xFF \
			or int(boundary.get("x", -1)) < 0 or int(boundary.get("x", -1)) > 0xFF \
			or int(boundary.get("y", -1)) < 0 or int(boundary.get("y", -1)) > 0xFF \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF \
			or bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "status": "invalid_pass_waiter_boundary",
			"error": "The source boundary must be the hash-pinned slot-$05 `$CC53` post-NMI state with its actual waiter counter and caller stack."}
	for stack_index in STACK_SIZE:
		if int((ram as PackedByteArray)[0x0100 + stack_index]) != int((stack as PackedByteArray)[stack_index]):
			return {"ok": false, "status": "invalid_pass_waiter_boundary",
				"error": "RAM and stack snapshots disagree at `$%02X`." % stack_index}
	if require_full_nmi_proofs and normal_nmi_proofs.size() != REQUIRED_NMI_RECEIPTS:
		return {"ok": false, "status": "missing_nmi_proofs",
			"error": "The ROM path needs %d explicit NMI queue-consumption proofs; got %d." % [REQUIRED_NMI_RECEIPTS, normal_nmi_proofs.size()]}
	return {"ok": true}


func _boundary_summary(boundary: Dictionary) -> Dictionary:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var bytes := {}
	if ram is PackedByteArray and (ram as PackedByteArray).size() == RAM_SIZE:
		var ram_bytes: PackedByteArray = ram
		for address in [0x0000, 0x0024, 0x0025, 0x0048, 0x0498, 0x0515]:
			bytes["$%04X" % address] = int(ram_bytes[address])
	if stack is PackedByteArray and (stack as PackedByteArray).size() == STACK_SIZE:
		var stack_bytes: PackedByteArray = stack
		bytes["stack_48_4A"] = stack_bytes.slice(0x48, 0x4B).hex_encode()
	return {"slot": boundary.get("slot_base", -1), "active": boundary.get("active_task_slot", -1),
		"phase": boundary.get("phase", -1), "pc": boundary.get("pc", -1),
		"sp": boundary.get("sp", -1), "registers": [boundary.get("a", -1),
			boundary.get("x", -1), boundary.get("y", -1), boundary.get("p", -1),
			boundary.get("p_known_mask", -1)],
		"banks": [boundary.get("bank_low", -1), boundary.get("bank_high", -1)],
		"mapper": boundary.get("mapper", {}), "ram": bytes,
		"source_label": boundary.get("source_label", ""),
		"trace_state_used": boundary.get("trace_state_used", true),
		"test_fixture": boundary.get("test_fixture", false)}


func _validate_terminal_packet_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "capture_state_rejected",
				"error": "Emulator captures cannot seed the PASS terminal-packet executor."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var source_label := String(boundary.get("source_label", ""))
	var source_label_valid := source_label.begins_with("ROM-byte PASS confirmation") \
		or source_label.begins_with("ROM-byte PASS waiter") \
		or (bool(boundary.get("test_fixture", false)) \
			and source_label == "synthetic PASS `$CCA3` terminal-packet fixture")
	if not bool(boundary.get("ok", true)) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != PASS_SLOT \
			or int(boundary.get("active_task_slot", -1)) != PASS_SLOT \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xCCA3 \
			or int(boundary.get("sp", -1)) != 0x48 \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or not mapper is Dictionary \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("fixed_low", mapper.get("fixed_bank", -1))) != 0x1E \
			or int(mapper.get("fixed_high", mapper.get("fixed_bank", -1))) != 0x1F \
			or not ram is PackedByteArray or (ram as PackedByteArray).size() != RAM_SIZE \
			or not stack is PackedByteArray or (stack as PackedByteArray).size() != STACK_SIZE \
			or not source_label_valid \
			or int((ram as PackedByteArray)[0]) != PASS_SLOT \
			or int((ram as PackedByteArray)[0x0024]) != 0x1C \
			or int((ram as PackedByteArray)[0x0025]) != 0x1D \
			or int((ram as PackedByteArray)[0x0515]) != 0 \
			or int((ram as PackedByteArray)[0x0498]) != 0 \
			or int((stack as PackedByteArray)[0x49]) != 0x0E \
			or int((stack as PackedByteArray)[0x4A]) != 0xD7 \
			or int(boundary.get("a", -1)) < 0 or int(boundary.get("a", -1)) > 0xFF \
			or int(boundary.get("x", -1)) < 0 or int(boundary.get("x", -1)) > 0xFF \
			or int(boundary.get("y", -1)) < 0 or int(boundary.get("y", -1)) > 0xFF \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF \
			or bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "status": "invalid_pass_waiter_terminal_boundary",
			"error": "The source boundary must be the hash-pinned slot-$05 `$CCA3` post-NMI state with its caller stack."}
	for stack_index in STACK_SIZE:
		if int((ram as PackedByteArray)[0x0100 + stack_index]) != int((stack as PackedByteArray)[stack_index]):
			return {"ok": false, "status": "invalid_pass_waiter_terminal_boundary",
				"error": "RAM and stack snapshots disagree at `$%02X`." % stack_index}
	return {"ok": true}


func _validate_busy_poll_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "capture_state_rejected",
				"error": "Emulator captures cannot seed the PASS waiter busy-poll executor."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var source_label := String(boundary.get("source_label", ""))
	var source_label_valid := source_label.begins_with("ROM-byte PASS confirmation waiter")
	if not bool(boundary.get("ok", true)) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != PASS_SLOT \
			or int(boundary.get("active_task_slot", -1)) != PASS_SLOT \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != POST_NMI_PC \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or not mapper is Dictionary \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("fixed_low", mapper.get("fixed_bank", -1))) != 0x1E \
			or int(mapper.get("fixed_high", mapper.get("fixed_bank", -1))) != 0x1F \
			or not ram is PackedByteArray or (ram as PackedByteArray).size() != RAM_SIZE \
			or not stack is PackedByteArray or (stack as PackedByteArray).size() != STACK_SIZE \
			or not source_label_valid \
			or int((ram as PackedByteArray)[0]) != PASS_SLOT \
			or int((ram as PackedByteArray)[0x0024]) != 0x1C \
			or int((ram as PackedByteArray)[0x0025]) != 0x1D \
			or int((ram as PackedByteArray)[0x0515]) != 0x80 \
			or int((ram as PackedByteArray)[0x0498]) != 0 \
			or (int((ram as PackedByteArray)[0x001B]) & 0x40) != 0 \
			or int(boundary.get("sp", -1)) < 0 or int(boundary.get("sp", -1)) > 0xFF \
			or int(boundary.get("a", -1)) < 0 or int(boundary.get("a", -1)) > 0xFF \
			or int(boundary.get("x", -1)) < 0 or int(boundary.get("x", -1)) > 0xFF \
			or int(boundary.get("y", -1)) < 0 or int(boundary.get("y", -1)) > 0xFF \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF \
			or bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "status": "invalid_pass_waiter_busy_poll_boundary",
			"error": "The source boundary must be the hash-pinned slot-$05 `$CC53` busy-poll state with `$0515=$80`."}
	if (ram as PackedByteArray).slice(0x0100, 0x0200) != stack:
		return {"ok": false, "status": "invalid_pass_waiter_busy_poll_boundary",
			"error": "The source busy-poll RAM and scheduler stack snapshots disagree."}
	return {"ok": true}


func _validate_waiter_rts_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "capture_state_rejected",
				"error": "Emulator captures cannot seed the PASS waiter RTS executor."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var source_label := String(boundary.get("source_label", ""))
	var ram_ready_flag := int((ram as PackedByteArray)[0x0515]) \
		if ram is PackedByteArray and (ram as PackedByteArray).size() == RAM_SIZE else -1
	var terminal_queue_state_matches := ram_ready_flag == 0x80 \
		or (bool(boundary.get("test_fixture", false)) and ram_ready_flag == 0)
	var source_label_valid := source_label.begins_with("ROM-byte PASS confirmation") \
		or source_label.begins_with("ROM-byte PASS waiter") \
		or (bool(boundary.get("test_fixture", false)) \
			and source_label == "synthetic PASS `$CCD1` RTS return fixture")
	if not bool(boundary.get("ok", true)) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != PASS_SLOT \
			or int(boundary.get("active_task_slot", -1)) != PASS_SLOT \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xCCD1 \
			or int(boundary.get("sp", -1)) != 0x48 \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or not mapper is Dictionary \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("fixed_low", mapper.get("fixed_bank", -1))) != 0x1E \
			or int(mapper.get("fixed_high", mapper.get("fixed_bank", -1))) != 0x1F \
			or not ram is PackedByteArray or (ram as PackedByteArray).size() != RAM_SIZE \
			or not stack is PackedByteArray or (stack as PackedByteArray).size() != STACK_SIZE \
			or not source_label_valid \
			or int((ram as PackedByteArray)[0]) != PASS_SLOT \
			or int((ram as PackedByteArray)[0x0024]) != 0x1C \
			or int((ram as PackedByteArray)[0x0025]) != 0x1D \
			or not terminal_queue_state_matches \
			or int((ram as PackedByteArray)[0x0498]) != 0 \
			or int((stack as PackedByteArray)[0x49]) != 0x0E \
			or int((stack as PackedByteArray)[0x4A]) != 0xD7 \
			or int(boundary.get("a", -1)) < 0 or int(boundary.get("a", -1)) > 0xFF \
			or int(boundary.get("x", -1)) != 0x21 \
			or int(boundary.get("y", -1)) < 0 or int(boundary.get("y", -1)) > 0xFF \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF \
			or bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "status": "invalid_pass_waiter_rts_boundary",
			"error": "The source boundary must be the hash-pinned slot-$05 `$CCD1` state with its `$D70F` caller frame."}
	for stack_index in STACK_SIZE:
		if int((ram as PackedByteArray)[0x0100 + stack_index]) != int((stack as PackedByteArray)[stack_index]):
			return {"ok": false, "status": "invalid_pass_waiter_rts_boundary",
				"error": "RAM and stack snapshots disagree at `$%02X`." % stack_index}
	return {"ok": true}


func _validate_waiter_caller_cleanup_boundary(boundary: Dictionary) -> Dictionary:
	for forbidden_key in ["fceux_ram", "captured_ram", "trace_ram_image", "emulator_snapshot", "screenshot"]:
		if boundary.has(forbidden_key):
			return {"ok": false, "status": "capture_state_rejected",
				"error": "Emulator captures cannot seed the PASS caller-cleanup executor."}
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var source_label := String(boundary.get("source_label", ""))
	var source_label_valid := source_label.begins_with("ROM-byte PASS waiter") \
		or source_label.begins_with("ROM-byte PASS confirmation") \
		or (bool(boundary.get("test_fixture", false)) \
			and source_label == "synthetic PASS `$D70F` caller cleanup fixture")
	if not bool(boundary.get("ok", true)) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != PASS_SLOT \
			or int(boundary.get("active_task_slot", -1)) != PASS_SLOT \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xD70F \
			or int(boundary.get("sp", -1)) != 0x4A \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or not mapper is Dictionary \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("fixed_low", mapper.get("fixed_bank", -1))) != 0x1E \
			or int(mapper.get("fixed_high", mapper.get("fixed_bank", -1))) != 0x1F \
			or not ram is PackedByteArray or (ram as PackedByteArray).size() != RAM_SIZE \
			or not stack is PackedByteArray or (stack as PackedByteArray).size() != STACK_SIZE \
			or not source_label_valid \
			or int((ram as PackedByteArray)[0]) != PASS_SLOT \
			or int((ram as PackedByteArray)[0x0024]) != 0x1C \
			or int((ram as PackedByteArray)[0x0025]) != 0x1D \
			or int(boundary.get("a", -1)) < 0 or int(boundary.get("a", -1)) > 0xFF \
			or int(boundary.get("x", -1)) < 0 or int(boundary.get("x", -1)) > 0xFF \
			or int(boundary.get("y", -1)) < 0 or int(boundary.get("y", -1)) > 0xFF \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF \
			or bool(boundary.get("trace_state_used", true)):
		return {"ok": false, "status": "invalid_pass_waiter_cleanup_boundary",
			"error": "The source boundary must be `$D70F` with the live slot-$05 RAM and stack snapshot."}
	for stack_index in STACK_SIZE:
		if int((ram as PackedByteArray)[0x0100 + stack_index]) != int((stack as PackedByteArray)[stack_index]):
			return {"ok": false, "status": "invalid_pass_waiter_cleanup_boundary",
				"error": "RAM and stack snapshots disagree at `$%02X`." % stack_index}
	return {"ok": true}


func _load_caller_span(manifest: Dictionary) -> PackedByteArray:
	var found: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary and String((span_variant as Dictionary).get("name", "")) == "pass_confirmation_wait_return_D70C_D717":
			found = span_variant
			break
	if found.is_empty() or String(found.get("file", "")) != "pass_confirmation_wait_return_D70C_D717.bin" \
			or int(found.get("length_bytes", -1)) != 11 \
			or String(found.get("sha256", "")) != CALLER_SHA256 \
			or not FileAccess.file_exists(CALLER_PATH) \
			or FileAccess.get_sha256(CALLER_PATH) != CALLER_SHA256:
		_fail("The PASS `$D70C-$D717` caller span failed manifest/hash validation.")
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(CALLER_PATH)
	if String(found.get("bytes_hex", "")).replace(" ", "").to_lower() != bytes.hex_encode():
		_fail("The PASS caller manifest bytes differ from the packaged ROM bytes.")
		return PackedByteArray()
	return bytes


func _load_waiter_dependency(manifest: Dictionary) -> PackedByteArray:
	var dependency_valid := false
	for dep_variant in manifest.get("existing_dependencies", []):
		if dep_variant is Dictionary:
			var dep: Dictionary = dep_variant
			if String(dep.get("cpu", "")) == "$CC46-$CCD1" \
					and String(dep.get("path", "")) == "reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_shared_waiter_CC46_CCD2.bin" \
					and String(dep.get("sha256", "")) == WAITER_SHA256:
				dependency_valid = true
				break
	if not dependency_valid or not FileAccess.file_exists(WAITER_PATH) \
			or FileAccess.get_sha256(WAITER_PATH) != WAITER_SHA256:
		_fail("The shared `$CC46-$CCD1` waiter dependency failed manifest/hash validation.")
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(WAITER_PATH)


func _write(ram: PackedByteArray, writes: Array[Dictionary],
		source_pc: int, address: int, value: int) -> void:
	var masked := value & 0xFF
	ram[address & 0x07FF] = masked
	writes.append({"source_pc": source_pc, "trace_pc": _next_pc(source_pc),
		"address": address & 0xFFFF, "value": masked})


func _push_value(stack: PackedByteArray, cpu: Dictionary,
		stack_writes: Array[Dictionary], value: int, source_pc: int) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	stack[sp] = value & 0xFF
	stack_writes.append({"source_pc": source_pc, "address": 0x0100 + sp,
		"value": value & 0xFF, "operation": "PHA"})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop_value(stack: PackedByteArray, cpu: Dictionary,
		stack_reads: Array[Dictionary], source_pc: int, role: String) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	stack_reads.append({"source_pc": source_pc, "address": 0x0100 + sp,
		"value": value, "operation": "PLA", "role": role})
	return value


func _push_jsr(stack: PackedByteArray, cpu: Dictionary,
		stack_writes: Array[Dictionary], callsite_pc: int, target_pc: int) -> Dictionary:
	var return_word := (callsite_pc + 2) & 0xFFFF
	_push_value(stack, cpu, stack_writes, (return_word >> 8) & 0xFF, callsite_pc)
	stack_writes.back()["operation"] = "jsr_push_high"
	_push_value(stack, cpu, stack_writes, return_word & 0xFF, callsite_pc)
	stack_writes.back()["operation"] = "jsr_push_low"
	cpu["pc"] = target_pc
	return {"return_word": return_word}


func _pop_rts(stack: PackedByteArray, cpu: Dictionary,
		stack_reads: Array[Dictionary], source_pc: int) -> Dictionary:
	var low := _pop_value(stack, cpu, stack_reads, source_pc, "rts_return_low")
	var high := _pop_value(stack, cpu, stack_reads, source_pc, "rts_return_high")
	var resume := (((high << 8) | low) + 1) & 0xFFFF
	cpu["pc"] = resume
	return {"ok": true, "resume_pc": resume}


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_x(cpu: Dictionary, value: int) -> void:
	cpu["x"] = value & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _set_y(cpu: Dictionary, value: int) -> void:
	cpu["y"] = value & 0xFF
	_set_nz(cpu, int(cpu["y"]))


func _set_nz(cpu: Dictionary, value: int) -> void:
	_set_flag(cpu, P_N, (value & 0x80) != 0)
	_set_flag(cpu, P_Z, (value & 0xFF) == 0)


func _set_flag(cpu: Dictionary, mask: int, enabled: bool) -> void:
	var p := int(cpu["p"]) & 0xFF
	cpu["p"] = (p | mask) if enabled else (p & ~mask) & 0xFF
	cpu["p_known_mask"] = (int(cpu["p_known_mask"]) | mask) & 0xFF


func _lsr_a(cpu: Dictionary) -> void:
	var value := int(cpu["a"]) & 0xFF
	_set_flag(cpu, P_C, (value & 1) != 0)
	_set_a(cpu, value >> 1)


func _ror_memory(ram: PackedByteArray, cpu: Dictionary, address: int,
		writes: Array[Dictionary], source_pc: int) -> void:
	var before := int(ram[address])
	var carry_in := 0x80 if (int(cpu["p"]) & P_C) != 0 else 0
	_set_flag(cpu, P_C, (before & 1) != 0)
	var after := ((before >> 1) | carry_in) & 0xFF
	_write(ram, writes, source_pc, address, after)
	_set_nz(cpu, after)


func _adc(cpu: Dictionary, value: int) -> void:
	var before := int(cpu["a"]) & 0xFF
	var carry_in := 1 if (int(cpu["p"]) & P_C) != 0 else 0
	var sum := before + value + carry_in
	var result := sum & 0xFF
	_set_flag(cpu, P_C, sum > 0xFF)
	_set_flag(cpu, P_V, ((~(before ^ value) & (before ^ result)) & 0x80) != 0)
	_set_a(cpu, result)


func _sbc(cpu: Dictionary, value: int) -> void:
	var before := int(cpu["a"]) & 0xFF
	var carry_in := 1 if (int(cpu["p"]) & P_C) != 0 else 0
	var diff := before - value - (1 - carry_in)
	var result := diff & 0xFF
	_set_flag(cpu, P_C, diff >= 0)
	_set_flag(cpu, P_V, (((before ^ result) & (before ^ value)) & 0x80) != 0)
	_set_a(cpu, result)


func _set_compare_flags(cpu: Dictionary, lhs: int, rhs: int) -> void:
	var result := (lhs - rhs) & 0xFF
	_set_flag(cpu, P_C, lhs >= rhs)
	_set_nz(cpu, result)


func _next_pc(source_pc: int) -> int:
	if source_pc in [0xCC53, 0xCC56, 0xCC58, 0xCC5D, 0xCC5F, 0xCC61,
			0xCC65, 0xCC66, 0xCC67, 0xCC69, 0xCC71, 0xCC77, 0xCC79,
			0xCC7D, 0xCC81, 0xCC89, 0xCC8C, 0xCC92, 0xCC97, 0xCC98,
			0xCC9B, 0xCC9C, 0xCC9E, 0xCCA3, 0xCCA6, 0xCCA8, 0xCCAD,
			0xCCB2, 0xCCB7, 0xCCBC, 0xCCBE, 0xCCC2, 0xCCC3, 0xCCC5,
			0xCCC7, 0xCCCC, 0xCCD1]:
		return (source_pc + 1) & 0xFFFF
	return (source_pc + 3) & 0xFFFF


func _fail(message: String) -> bool:
	error_message = message
	return false


func _failure(status: String, message: String) -> Dictionary:
	return {"ok": false, "status": status, "error": message}
