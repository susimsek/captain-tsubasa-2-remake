#!/usr/bin/env python3
"""Record ROM-only scheduler, NMI, task-resume, and Start-poll events in a bounded window."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
STEPPER_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
OUT_DEFAULT = ROOT / "reference/diagnostics/start_poll_rom_source_timing_20261027"
FOCUS_PCS = {0x9EED: "scheduler_scan", 0x9FA8: "cooperative_yield", 0x802C: "start_poll"}


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
    parser.add_argument("--candidate-irq-mask-stall-return", action="store_true",
                        help="diagnostic-only candidate: preserve I in prev_p when IRQ entry exhausts CPU credit before first handler instruction")
    args = parser.parse_args()
    if args.first_frame < 1 or args.last_frame < args.first_frame or args.end_frame < args.last_frame:
        parser.error("require 1 <= first-frame <= last-frame <= end-frame")

    rom = ROM_PATH.read_bytes()
    input_bytes = INPUT_PATH.read_bytes()
    rom_hash, input_hash = sha256(rom), sha256(input_bytes)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: {rom_hash}")
    if input_hash != EXPECTED_INPUT_SHA256:
        raise SystemExit(f"input timeline identity mismatch: {input_hash}")

    stepper = load_stepper()
    machine = stepper.Machine(rom, stepper.load_input_timeline(INPUT_PATH))
    events: list[dict] = []
    resume_pcs: set[int] = set()
    corrected_irq_returns: list[dict] = []
    original_instruction = machine._cpu_instruction

    def event(kind: str, pc: int, cycle: int | None = None, continuation: int | None = None) -> None:
        frame = machine.source_frame
        if not args.first_frame <= frame <= args.last_frame:
            return
        x, y, sp = machine.cpu.x, machine.cpu.y, machine.cpu.sp
        slot = machine.ram[0]
        slot_delay = machine.ram[slot] if slot < len(machine.ram) else -1
        resolved_cycle = machine.cpu_cycles if cycle is None else cycle
        events.append({
            "source_frame": frame,
            "cycle_absolute": resolved_cycle,
            "cycle_from_frame_start": resolved_cycle - machine.frame_cycle_start,
            "event": kind,
            "pc": f"${pc:04X}",
            "opcode": f"${machine[pc]:02X}" if pc >= 0x8000 else "",
            "a": f"${machine.cpu.a:02X}", "x": f"${x:02X}", "y": f"${y:02X}",
            "sp": f"${sp:02X}", "p": f"${machine.cpu.p:02X}",
            "task_slot_ram00": f"${slot:02X}", "task_delay_at_slot": f"${slot_delay:02X}" if slot_delay >= 0 else "",
            "script_pointer": f"${machine.ram[0x4D] | machine.ram[0x4E] << 8:04X}",
            "ram_001b": f"${machine.ram[0x1B]:02X}", "ram_001e": f"${machine.ram[0x1E]:02X}",
            "resume_pc": f"${continuation:04X}" if continuation is not None else "",
        })

    def trace_instruction() -> None:
        cpu = machine.cpu
        pc = cpu.pc
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

    # The CPU/PPU source execution is now complete. Only after that point is it
    # safe to open the FCEUX trace as a comparison oracle.
    args.out_dir.mkdir(parents=True, exist_ok=True)
    events_path = args.out_dir / "rom_source_scheduler_window.csv"
    frame_path = args.out_dir / "rom_source_scheduler_window_frames.csv"
    event_fields = ["source_frame", "cycle_absolute", "cycle_from_frame_start", "event", "pc", "opcode",
                    "a", "x", "y", "sp", "p", "task_slot_ram00", "task_delay_at_slot",
                    "script_pointer", "ram_001b", "ram_001e", "resume_pc"]
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
    report = {
        "rom_sha256": rom_hash,
        "input_timeline_sha256": input_hash,
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
    import json
    (args.out_dir / "rom_source_scheduler_window_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: report[key] for key in ("source_frames_advanced", "event_count", "resume_pc_count", "events_sha256", "frames_sha256")}, indent=2))


if __name__ == "__main__":
    main()
