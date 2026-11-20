#!/usr/bin/env python3
"""Record ROM-only scheduler, NMI, task-resume, and Start-poll events in a bounded window."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
DEFAULT_ROUTE_INPUT_PATH = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
STEPPER_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
OUT_DEFAULT = ROOT / "reference/diagnostics/start_poll_rom_source_timing_20261027"
FOCUS_PCS = {
	0x80E6: "kickoff_entry", 0x80EE: "cutscene_wait", 0x80F1: "caller_resume",
	0x80FA: "match_selector_call", 0x8114: "match_setup_call",
	0x82B5: "cutscene_wait_helper", 0x82EC: "cutscene_wait_return",
	0x8494: "cutscene_task_create", 0x84C6: "cutscene_worker_resume",
	0x84E7: "cutscene_interpreter", 0x893B: "match_setup_wait",
	0x9EED: "scheduler_scan", 0x9F04: "scheduler_nmi_gate",
	0x9F0C: "scheduler_ready_clear", 0x9F52: "task_resume",
	0x9F69: "task_create", 0x9FA8: "cooperative_yield",
	0x8B3F: "nmi_chr_pair_low_store_return", 0x8B44: "nmi_chr_pair_high_store_return",
	0x9248: "nmi_chr_table_pointer_high_store", 0x924E: "nmi_chr_table_pointer_low_store",
	0x8CA9: "nmi_chr_selector_low_store", 0x8CAD: "nmi_chr_selector_high_store",
	0x94E0: "nmi_chr_r2_store", 0x94E5: "nmi_chr_r3_store",
	0x94EB: "nmi_chr_r4_store", 0x94F0: "nmi_chr_r5_store",
	0xA20F: "match_selector_entry", 0xA15B: "match_selector_copy_loop",
	0xC421: "special_nmi_entry",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_stepper():
    spec = importlib.util.spec_from_file_location("ct2_poll_window_stepper", STEPPER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import stepper at {STEPPER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--first-frame", type=int, default=3596)
    parser.add_argument("--last-frame", type=int, default=3603)
    parser.add_argument("--end-frame", type=int, default=3603,
                        help="ROM-only execution cutoff (inclusive); must cover --last-frame")
    parser.add_argument("--out-dir", type=Path, default=OUT_DEFAULT)
    parser.add_argument("--route-input-timeline", type=Path, default=None,
                        help="optional route input CSV; its frames override the cold-start timeline")
    parser.add_argument("--snapshot-frame", type=int, default=None,
                        help="source frame at which to preserve one ROM-only state snapshot")
    parser.add_argument("--snapshot-pc", type=lambda value: int(value, 0), default=None,
                        help="CPU PC for the optional source-only state snapshot")
    parser.add_argument("--ram-write-addresses", nargs="*", type=lambda value: int(value, 0), default=[],
                        help="optional internal-RAM addresses whose ROM-only writes should be recorded")
    parser.add_argument("--status-flag-trace", action="store_true",
                        help="record source instructions and interrupts that change V, D, or I in the focused frame window")
    parser.add_argument("--status-flag-start-frame", type=int, default=1,
                        help="first source frame included by --status-flag-trace")
    parser.add_argument("--candidate-irq-mask-stall-return", action="store_true",
                        help="diagnostic-only candidate: preserve I in prev_p when IRQ entry exhausts CPU credit before first handler instruction")
    args = parser.parse_args()
    if args.first_frame < 1 or args.last_frame < args.first_frame or args.end_frame < args.last_frame:
        parser.error("require 1 <= first-frame <= last-frame <= end-frame")
    if args.status_flag_trace and not (1 <= args.status_flag_start_frame <= args.last_frame):
        parser.error("require 1 <= status-flag-start-frame <= last-frame")

    rom = ROM_PATH.read_bytes()
    input_bytes = INPUT_PATH.read_bytes()
    rom_hash, input_hash = sha256(rom), sha256(input_bytes)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: {rom_hash}")
    if input_hash != EXPECTED_INPUT_SHA256:
        raise SystemExit(f"input timeline identity mismatch: {input_hash}")

    stepper = load_stepper()
    input_timeline = stepper.load_input_timeline(INPUT_PATH)
    route_input_hash = None
    if args.route_input_timeline is not None:
        route_input_hash = sha256(args.route_input_timeline.read_bytes())
        with args.route_input_timeline.open(newline="", encoding="utf-8") as stream:
            for row in csv.DictReader(stream):
                frame = int(row["source_frame"])
                input_timeline[frame] = {
                    key: row[source_key] == "1"
                    for key, source_key in {
                        "up": "up", "down": "down", "left": "left", "right": "right",
                        "A": "A", "B": "B", "start": "Start", "select": "Select",
                    }.items()
                }
    machine = stepper.Machine(rom, input_timeline)
    events: list[dict] = []
    ram_write_events: list[dict] = []
    status_flag_events: list[dict] = []
    watched_ram_addresses = {address & 0x07FF for address in args.ram_write_addresses}
    original_setitem = stepper.Machine.__setitem__

    def trace_ram_write(instance, address: int, value: int) -> None:
        normalized_address = address & 0xFFFF
        if normalized_address < 0x2000:
            ram_address = normalized_address & 0x07FF
            source_pc = int(getattr(instance, "current_instruction_pc", 0))
            if ram_address in watched_ram_addresses \
                    and args.first_frame <= int(instance.source_frame) <= args.last_frame:
                old_value = int(instance.ram[ram_address])
                ram_write_events.append({
                    "source_frame": int(instance.source_frame),
                    "cycle": int(instance.cpu_cycles),
                    "pc": f"${source_pc:04X}",
                    "bank": instance._prg_bank(source_pc) if source_pc >= 0x8000 else -1,
                    "address": f"${ram_address:04X}",
                    "old_value": f"${old_value:02X}",
                    "value": f"${value & 0xFF:02X}",
                })
        original_setitem(instance, address, value)

    if watched_ram_addresses:
        stepper.Machine.__setitem__ = trace_ram_write
    resume_pcs: set[int] = set()
    corrected_irq_returns: list[dict] = []
    source_snapshot: dict = {}
    original_instruction = machine._cpu_instruction

    def event(kind: str, pc: int, cycle: int | None = None, continuation: int | None = None) -> None:
        frame = machine.source_frame
        if not args.first_frame <= frame <= args.last_frame:
            return
        x, y, sp = machine.cpu.x, machine.cpu.y, machine.cpu.sp
        stack_next_8 = "".join(f"{machine.ram[0x0100 + ((sp + index) & 0xFF)]:02X}" for index in range(1, 9))
        slot = machine.ram[0]
        slot_delay = machine.ram[slot] if slot < len(machine.ram) else -1
        resolved_cycle = machine.cpu_cycles if cycle is None else cycle
        row = {
            "source_frame": frame,
            "cycle_absolute": resolved_cycle,
            "cycle_from_frame_start": resolved_cycle - machine.frame_cycle_start,
            "event": kind,
            "pc": f"${pc:04X}",
            "opcode": f"${machine[pc]:02X}" if pc >= 0x8000 else "",
            "a": f"${machine.cpu.a:02X}", "x": f"${x:02X}", "y": f"${y:02X}",
            "sp": f"${sp:02X}", "p": f"${machine.cpu.p:02X}",
            "stack_next_8": stack_next_8,
            "ram_0000_001f": machine.ram[:0x20].hex().upper(),
            "task_slot_ram00": f"${slot:02X}", "task_delay_at_slot": f"${slot_delay:02X}" if slot_delay >= 0 else "",
            "script_pointer": f"${machine.ram[0x4D] | machine.ram[0x4E] << 8:04X}",
            "ram_001b": f"${machine.ram[0x1B]:02X}", "ram_001e": f"${machine.ram[0x1E]:02X}",
            "resume_pc": f"${continuation:04X}" if continuation is not None else "",
        }
        if kind.startswith(("nmi_chr_", "nmi_bg_")):
            chr_pointer = machine.ram[0xE6] | (machine.ram[0xE7] << 8)
            row["ram_0075_0076"] = bytes(machine.ram[0x75:0x77]).hex().upper()
            row["ram_00e6_00e7"] = bytes(machine.ram[0xE6:0xE8]).hex().upper()
            row["ram_0063_0064"] = bytes(machine.ram[0x63:0x65]).hex().upper()
            row["ram_0092_0093"] = bytes(machine.ram[0x92:0x94]).hex().upper()
            row["chr_pointer"] = f"${chr_pointer:04X}"
            row["chr_pointer_bank"] = machine._prg_bank(chr_pointer) if chr_pointer >= 0x8000 else "RAM"
            row["chr_source_bytes"] = bytes(machine[chr_pointer + i] for i in range(4)).hex().upper() \
                if chr_pointer >= 0x8000 else ""
            bg_pointer = machine.ram[0x63] | (machine.ram[0x64] << 8)
            row["bg_pointer"] = f"${bg_pointer:04X}"
            row["bg_pointer_bank"] = machine._prg_bank(bg_pointer) if bg_pointer >= 0x8000 else "RAM"
            row["bg_source_bytes"] = bytes(machine[bg_pointer + i] for i in range(4)).hex().upper() \
                if bg_pointer >= 0x8000 else ""
        events.append(row)
        if pc == args.snapshot_pc and frame == args.snapshot_frame:
            ram = bytes(machine.ram)
            is_nmi_entry = pc == 0xC421
            is_irq_handler = pc == 0xA160
            source_kind = "NMI" if is_nmi_entry else "IRQ" if is_irq_handler else "instruction"
            source_event = {
                "kind": source_kind,
                "source_event_id": f"rom-source-{source_kind.lower()}-frame-{frame}-pc-{pc:04X}-{machine.cpu_cycles}",
                "snapshot_pc": int(pc),
                "source_frame": frame,
                "cycle_absolute": int(machine.cpu_cycles),
                "snapshot_phase": "before_instruction_execution",
            }
            if is_nmi_entry:
                stack_status = ram[0x0100 + ((sp + 1) & 0xFF)]
                interrupted_pc = ram[0x0100 + ((sp + 2) & 0xFF)] \
                    | (ram[0x0100 + ((sp + 3) & 0xFF)] << 8)
                source_event.update({
                    "entry_pc": int(pc), "vector_pc": 0xC500,
                    "dispatch_pc": 0xC76E, "interrupted_pc": int(interrupted_pc),
                })
            elif is_irq_handler:
                source_event.update({
                    "vector_pc": 0xC506, "dispatch_pc": 0xC821,
                    "wrapper_pc": 0xC478,
                })
            registers = list(machine.mmc3_regs)
            mapper = {
                "registers": registers,
                "command": int(machine.mmc3_cmd),
                "prg_mode": (int(machine.mmc3_cmd) >> 6) & 1,
                "a000_prg_bank": int(registers[7]),
                "8000_prg_bank": int(registers[6]),
            }
            context = {
                "source_rom_sha256": rom_hash,
                "source_event": source_event,
                "snapshot_kind": "rom_only_instruction_boundary_before_execution",
                "cpu": {"pc": int(machine.cpu.pc), "a": int(machine.cpu.a), "x": int(machine.cpu.x),
                        "y": int(machine.cpu.y), "p": int(machine.cpu.p), "sp": int(machine.cpu.sp)},
                "mapper": mapper,
                "ppu": {"ctrl_shadow": int(ram[0x0020]), "mask_shadow": int(ram[0x0021])},
                "controller_inputs": {
                    "port1_buttons": int(f"{ram[0x001C]:08b}"[::-1], 2),
                    "port2_buttons": int(f"{ram[0x001D]:08b}"[::-1], 2),
                },
                "provenance": {
                    "kind": "rom_source_execution", "source_sha256": rom_hash,
                    "input_route_sha256": route_input_hash or input_hash,
                    "opening_input_sha256": input_hash,
                    "trace_state_used": False, "emulator_data_used": False,
                    "candidate_state_used": False,
                },
            }
            if is_nmi_entry:
                context["nmi_frame"] = {
                    "interrupted_pc": int(interrupted_pc),
                    "interrupted_p": int(stack_status),
                }
            source_snapshot.update({
                "context": context,
                "ram": ram,
                "stack_page": ram[0x0100:0x0200],
                "ppu_ram": bytes(machine.ppu_ram),
                "oam": bytes(machine.oam),
                "ppu_registers": list(machine.ppu_regs),
                "ppu_status": int(machine.ppu_status),
                "ppu_line": int(machine.ppu_line),
                "ppu_dot": int(machine.ppu_dot),
                "controller_state": int(machine.controller_state),
            })

    def trace_instruction() -> None:
        cpu = machine.cpu
        pc = cpu.pc
        p_before = int(cpu.p)
        cycle_before = int(machine.cpu_cycles)
        source_frame_before = int(machine.source_frame)
        prior_current_pc = machine.current_instruction_pc
        if args.first_frame <= machine.source_frame <= args.last_frame:
            if pc in FOCUS_PCS:
                event(FOCUS_PCS[pc], pc)
            if pc in resume_pcs:
                event("task_resume", pc, continuation=pc)
            if pc == 0x9FA8:
                sp = cpu.sp
                low = machine[0x0100 + ((sp + 1) & 0xFF)]
                high = machine[0x0100 + ((sp + 2) & 0xFF)]
                resume_pc = ((low | high << 8) + 1) & 0xFFFF
                resume_pcs.add(resume_pc)
                # Amend the already-appended yield with the reconstructed continuation.
                if events and events[-1]["event"] == "cooperative_yield" and events[-1]["pc"] == "$9FA8":
                    events[-1]["resume_pc"] = f"${resume_pc:04X}"

        interrupt_count = len(machine.cpu_interrupt_events)
        original_instruction()
        new_interrupts = machine.cpu_interrupt_events[interrupt_count:]
        if args.status_flag_trace and args.status_flag_start_frame <= source_frame_before <= args.last_frame:
            p_after = int(cpu.p)
            changed_flags = (p_before ^ p_after) & 0x4C  # V, D, I; exclude ordinary N/Z/C changes.
            if changed_flags:
                executed_pc = int(machine.current_instruction_pc)
                status_flag_events.append({
                    "source_frame": source_frame_before,
                    "cycle_before": cycle_before,
                    "pc_before": f"${pc:04X}",
                    "executed_pc": f"${executed_pc:04X}",
                    "opcode": f"${machine.current_instruction_opcode:02X}",
                    "bank": machine._prg_bank(executed_pc) if executed_pc >= 0x8000 else -1,
                    "p_before": f"${p_before:02X}",
                    "p_after": f"${p_after:02X}",
                    "changed_flags": f"${changed_flags:02X}",
                    "interrupts": ",".join(row["kind"] for row in new_interrupts),
                })
        for interrupt in new_interrupts:
            event(interrupt["kind"], int(interrupt["pc_before"].replace("$", ""), 16),
                  cycle=int(interrupt["cycle"]))
        if args.candidate_irq_mask_stall_return:
            # The partial CPU can return immediately after charging the IRQ's
            # 7 entry cycles when its PPU credit is exhausted. In that case it
            # has set the hardware I flag and moved PC to the vector, but has
            # not reached the normal prev_p=cpu.p assignment below the IRQ
            # check. Preserve the interrupt mask before the next instruction
            # so the same still-asserted IRQ is not accepted a second time.
            if (any(row["kind"] == "IRQ" for row in new_interrupts)
                    and machine.cpu.pc != pc
                    and machine.current_instruction_pc == prior_current_pc
                    and machine.cpu.p & 0x04):
                corrected_irq_returns.append({"source_frame": machine.source_frame,
                                               "cycle": machine.cpu_cycles,
                                               "pc_before": f"${pc:04X}",
                                               "pc_after": f"${machine.cpu.pc:04X}"})
                machine.prev_p = machine.cpu.p

    machine._cpu_instruction = trace_instruction
    machine.run(args.end_frame)
    if watched_ram_addresses:
        stepper.Machine.__setitem__ = original_setitem

    if (args.snapshot_frame is not None or args.snapshot_pc is not None) and not source_snapshot:
        raise SystemExit("Requested ROM-only snapshot boundary was not reached.")

    # The CPU/PPU source execution is now complete. Only after that point is it
    # safe to open the FCEUX trace as a comparison oracle.
    args.out_dir.mkdir(parents=True, exist_ok=True)
    events_path = args.out_dir / "rom_source_scheduler_window.csv"
    frame_path = args.out_dir / "rom_source_scheduler_window_frames.csv"
    event_fields = ["source_frame", "cycle_absolute", "cycle_from_frame_start", "event", "pc", "opcode",
                    "a", "x", "y", "sp", "p", "stack_next_8", "ram_0000_001f", "task_slot_ram00", "task_delay_at_slot",
                    "script_pointer", "ram_001b", "ram_001e", "ram_0075_0076", "ram_00e6_00e7",
                    "ram_0063_0064", "ram_0092_0093", "chr_pointer", "chr_pointer_bank",
                    "chr_source_bytes", "bg_pointer", "bg_pointer_bank", "bg_source_bytes", "resume_pc"]
    with events_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=event_fields)
        writer.writeheader()
        writer.writerows(sorted(events, key=lambda row: (row["cycle_absolute"], row["event"])))
    with frame_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=("source_frame", "cycle_start", "cycle_end", "cycle_delta"))
        writer.writeheader()
        for row in machine.frame_stats:
            if args.first_frame <= row["source_frame"] <= args.last_frame:
                writer.writerow(row)
    if watched_ram_addresses:
        write_path = args.out_dir / "rom_source_ram_writes.csv"
        write_fields = ["source_frame", "cycle", "pc", "bank", "address", "old_value", "value"]
        with write_path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=write_fields)
            writer.writeheader()
            writer.writerows(ram_write_events)
    if args.status_flag_trace:
        status_path = args.out_dir / "rom_source_status_flag_changes.csv"
        status_fields = ["source_frame", "cycle_before", "pc_before", "executed_pc", "opcode",
                         "bank", "p_before", "p_after", "changed_flags", "interrupts"]
        with status_path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=status_fields)
            writer.writeheader()
            writer.writerows(status_flag_events)
    if source_snapshot:
        snapshot_name = "rom_source_c421_snapshot" if args.snapshot_pc == 0xC421 else \
            "rom_source_a160_snapshot" if args.snapshot_pc == 0xA160 else "rom_source_boundary_snapshot"
        snapshot_dir = args.out_dir / snapshot_name
        snapshot_dir.mkdir(parents=True, exist_ok=True)
        (snapshot_dir / "ram.bin").write_bytes(source_snapshot["ram"])
        (snapshot_dir / "stack.bin").write_bytes(source_snapshot["stack_page"])
        (snapshot_dir / "ppu.bin").write_bytes(source_snapshot["ppu_ram"])
        (snapshot_dir / "oam.bin").write_bytes(source_snapshot["oam"])
        snapshot_report = {
            "schema": "ct2-rom-only-source-boundary-v1",
            "context": source_snapshot["context"],
            "ram_file": "ram.bin", "ram_sha256": sha256(source_snapshot["ram"]),
            "stack_file": "stack.bin", "stack_sha256": sha256(source_snapshot["stack_page"]),
            "ppu_file": "ppu.bin", "ppu_sha256": sha256(source_snapshot["ppu_ram"]),
            "oam_file": "oam.bin", "oam_sha256": sha256(source_snapshot["oam"]),
            "ppu_registers": source_snapshot["ppu_registers"],
            "ppu_status": source_snapshot["ppu_status"],
            "ppu_line": source_snapshot["ppu_line"], "ppu_dot": source_snapshot["ppu_dot"],
            "controller_state": source_snapshot["controller_state"],
        }
        (snapshot_dir / "context.json").write_text(json.dumps(snapshot_report, indent=2) + "\n", encoding="utf-8")
    report = {
        "rom_sha256": rom_hash,
        "input_timeline_sha256": input_hash,
        "route_input_timeline_sha256": route_input_hash,
        "source_execution_complete_before_fceux_read": True,
        "fceux_timestamps_used_as_execution_input": False,
        "source_frame_window": [args.first_frame, args.last_frame],
        "source_frames_advanced": machine.source_frame,
        "focus_pcs": {f"${pc:04X}": name for pc, name in FOCUS_PCS.items()},
        "task_resume_pc_source": "ROM-stepper JSR stack return address reconstructed at source $9FA8 entry; later source execution is hooked by PC",
        "cpu_interrupt_events_in_window": [row for row in machine.cpu_interrupt_events if args.first_frame <= row["source_frame"] <= args.last_frame],
        "event_count": len(events),
        "resume_pc_count": len(resume_pcs),
        "candidate_irq_mask_stall_return_enabled": args.candidate_irq_mask_stall_return,
        "candidate_corrected_irq_entry_stalls": corrected_irq_returns,
        "events_sha256": sha256(events_path.read_bytes()),
        "frames_sha256": sha256(frame_path.read_bytes()),
    }
    if args.status_flag_trace:
        status_path = args.out_dir / "rom_source_status_flag_changes.csv"
        report["status_flag_change_event_count"] = len(status_flag_events)
        report["status_flag_source_frame_window"] = [args.status_flag_start_frame, args.last_frame]
        report["status_flag_changes_sha256"] = sha256(status_path.read_bytes())
    (args.out_dir / "rom_source_scheduler_window_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: report[key] for key in ("source_frames_advanced", "event_count", "resume_pc_count", "events_sha256", "frames_sha256")}, indent=2))


if __name__ == "__main__":
    main()
