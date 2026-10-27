#!/usr/bin/env python3
"""Diagnostics-only candidate using pinned FCEUX NewPPU runppu boundaries.

This wrapper imports the existing ROM-only stepper, replaces only its frame
scheduler, and leaves production scripts/assets/audio untouched. It mirrors the
NewPPU runppu call partition at 1-dot BG fetches, sprite-slot fetches, and the
slot-2 MMC3 hook. It does not model individual 6502 bus cycles.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_stepper_cycle_boundary_candidate_20261026_default"
spec = importlib.util.spec_from_file_location("rom_stepper_base", BASE_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"could not load base diagnostic: {BASE_PATH}")
base = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = base
spec.loader.exec_module(base)
base.DEFAULT_OUT = DEFAULT_OUT


class NewPPUBoundaryMachine(base.Machine):
    last_instance = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        type(self).last_instance = self
        self.cycle_boundary_candidate = {
            "scheduler": "pinned FCEUX NewPPU runppu call boundaries",
            "frame_380_line48_segments_before_irq_hook": [],
            "frame_380_line48_segments_after_irq_hook": [],
            "frame_380_line48_hook": None,
            "frame_summaries": [],
            "interrupts": [],
            "note": "segment dots only; signed CPU credit is retained by inherited runppu() across calls",
        }

    def _runppu_segment(self, dots: int, line: int, start_dot: int, group: str) -> None:
        self.ppu_line = line
        self.ppu_dot = start_dot
        if self.source_frame == 380 and line == 48 and 254 <= start_dot <= 282:
            key = ("frame_380_line48_segments_after_irq_hook"
                   if self.cycle_boundary_candidate["frame_380_line48_hook"] is not None
                   else "frame_380_line48_segments_before_irq_hook")
            self.cycle_boundary_candidate[key].append({
                "group": group,
                "dot": start_dot,
                "dots": dots,
                "cpu_cycle": self.cpu_cycles,
                "cpu_credit": self.cpu_credit,
                "pc": f"${self.cpu.pc:04X}",
            })
        self.runppu(dots)

    def _cpu_instruction(self) -> None:
        """Mirror FCEUX's _PI = _P update on an exhausted interrupt return."""
        cycles_before = self.cpu_cycles
        interrupts_before = len(self.cpu_interrupt_events)
        super()._cpu_instruction()
        accepted = self.cpu_interrupt_events[interrupts_before:]
        if (accepted and self.cpu_cycles - cycles_before == 7
                and self.cpu_credit <= 0):
            self.prev_p = self.cpu.p

    def _runppu_ones(self, count: int, line: int, start_dot: int, group: str) -> None:
        for index in range(count):
            self._runppu_segment(1, line, start_dot + index, group)

    def run_frame(self, frame: int) -> None:
        self.source_frame = frame
        self.frame_cycle_start = self.cpu_cycles
        cycle_start = self.cpu_cycles
        controls = self.input_timeline.get(frame, {})
        self.controller_state = (
            (int(bool(controls.get("A"))) << 0)
            | (int(bool(controls.get("B"))) << 1)
            | (int(bool(controls.get("select"))) << 2)
            | (int(bool(controls.get("start"))) << 3)
            | (int(bool(controls.get("up"))) << 4)
            | (int(bool(controls.get("down"))) << 5)
            | (int(bool(controls.get("left"))) << 6)
            | (int(bool(controls.get("right"))) << 7)
        )

        if self.dead_frames:
            # PPU.cpp's ppudead path uses two bulk calls, not per-dot calls.
            self._runppu_segment(20 * 341, 241, 0, "power-on vblank bulk")
            self._runppu_segment(242 * 341, 0, 0, "power-on remaining-frame bulk")
            self.dead_frames -= 1
            self.frame_stats.append({"source_frame": frame, "cycle_start": cycle_start,
                                     "cycle_end": self.cpu_cycles,
                                     "cycle_delta": self.cpu_cycles - cycle_start})
            self._record_frame_summary(frame, cycle_start)
            return

        # PPU.cpp: 20 individual vblank dots, then 20 scanlines of individual
        # runppu(1) calls (first scanline starts at dot 20).
        self.vblank = True
        self.ppu_status |= 0x80
        self.ppu_line = 241
        for dot in range(20):
            self._runppu_segment(1, 241, dot, "vblank lead-in")
        if self.ppu_regs[0] & 0x80:
            self.nmi_pending = True
        for scanline in range(20):
            start = 20 if scanline == 0 else 0
            ppu_line = 241 + scanline
            for dot in range(start, 341):
                self._runppu_segment(1, ppu_line, dot, "vblank line")
        self.ppu_status &= 0x7F
        self.vblank = False

        # NewPPU renders 241 lines. Each main-line BG tile read contains eight
        # runppu(1) calls. The first eight sprite slots are real and each uses
        # four two-dot calls, with GameHBIRQHook after slot 2's garbage fetch.
        for line in range(241):
            self.ppu_line = line
            self.ppu_dot = 0
            dot = 0

            for tile in range(32):
                self._runppu_ones(8, line, dot, f"BG tile {tile} fetch")
                dot += 8

            for slot in range(8):
                special_zero_garbage = (
                    (line == 0 and dot == 304)
                    or (line != 0 and line < 241 and dot == 256)
                )
                if special_zero_garbage:
                    # PPU.cpp's latch install splits the two garbage dots.
                    self._runppu_segment(1, line, dot, f"sprite slot {slot} latch dot 1")
                    self._runppu_segment(1, line, dot + 1, f"sprite slot {slot} latch dot 2")
                    self._runppu_segment(0, line, dot + 2, f"sprite slot {slot} zero-length runppu")
                    dot += 2
                else:
                    self._runppu_segment(2, line, dot, f"sprite slot {slot} garbage fetch")
                    dot += 2

                if slot == 2 and (self.ppu_regs[1] & 0x18) and (self.ppu_regs[0] & 0x38) != 0x18:
                    irq_before = len(self.mmc3_irq_events)
                    self._irq_clock(line, dot)
                    if frame == 380 and line == 48:
                        self.cycle_boundary_candidate["frame_380_line48_hook"] = {
                            "event": "GameHBIRQHook",
                            "irq_edge": len(self.mmc3_irq_events) > irq_before,
                            "group": "after sprite slot 2 garbage fetch",
                            "dot": dot,
                            "cpu_cycle": self.cpu_cycles,
                            "cpu_credit": self.cpu_credit,
                            "pc": f"${self.cpu.pc:04X}",
                            "irq_pending": int(self.irq_pending),
                            "mmc3_count": self.mmc3_count,
                            "mmc3_latch": self.mmc3_latch,
                            "mmc3_enabled": int(self.mmc3_enabled),
                            "ppu_mask": f"${self.ppu_regs[1]:02X}",
                            "ppu_ctrl": f"${self.ppu_regs[0]:02X}",
                        }

                for label in ("sprite fetch lead", "sprite plane 0", "sprite plane 1"):
                    self._runppu_segment(2, line, dot, f"sprite slot {slot} {label}")
                    dot += 2

            # NewPPU prefetches two BG tiles after all sprite slots.
            self._runppu_ones(16, line, dot, "BG tail prefetch")
            dot += 16
            self._runppu_segment(2, line, dot, "post-fetch idle 1")
            dot += 2

            if line == 0:
                short_line = bool(self.idle_synch and (self.ppu_regs[1] & 0x18))
                line_end = 340 if short_line else 341
                self.idle_synch ^= 1
            else:
                line_end = 341
            self._runppu_segment(2, line, dot, "post-fetch idle 2")
            dot += 2
            if line_end == 341:
                self._runppu_segment(1, line, dot, "final line dot")

        # NewPPU's final idle scanline.
        for dot in range(341):
            self._runppu_segment(1, 241, dot, "final idle line")

        self.frame_stats.append({"source_frame": frame, "cycle_start": cycle_start,
                                 "cycle_end": self.cpu_cycles,
                                 "cycle_delta": self.cpu_cycles - cycle_start})
        self._record_frame_summary(frame, cycle_start)

    def _record_frame_summary(self, frame: int, cycle_start: int) -> None:
        self.cycle_boundary_candidate["frame_summaries"].append({
            "source_frame": frame,
            "cycle_start": cycle_start,
            "cycle_end": self.cpu_cycles,
            "cycle_delta": self.cpu_cycles - cycle_start,
            "cpu_credit_end": self.cpu_credit,
            "pc_end": f"${self.cpu.pc:04X}",
        })


base.Machine = NewPPUBoundaryMachine


def main() -> None:
    base.main()
    # The base CLI keeps all normal export/comparison plumbing. Attach only
    # candidate scheduler metadata to its diagnostic report after it completes.
    out_dir = None
    for index, arg in enumerate(sys.argv[1:]):
        if arg == "--out-dir" and index + 2 <= len(sys.argv[1:]):
            out_dir = Path(sys.argv[index + 2])
    if out_dir is None:
        out_dir = base.DEFAULT_OUT
    report_path = out_dir / "source_stepper_report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    machine = NewPPUBoundaryMachine.last_instance
    report["cycle_boundary_candidate"] = {
        "script": str(Path(__file__).relative_to(ROOT)),
        "scheduler": "pinned FCEUX NewPPU runppu call boundaries, modeled in a separate diagnostic wrapper",
        "source_semantics": [
            "20 vblank lead-in runppu(1) calls and 20 x 341 vblank dot calls",
            "32 background records per line, each with eight runppu(1) calls",
            "sprite slots 0-7 with split runppu(1)+runppu(1)+runppu(0) latch path at dot 256 (or line-0 dot 304)",
            "GameHBIRQHook after sprite slot 2 garbage fetch at dot 274",
            "signed cpu_credit is inherited and retained across every runppu call",
        ],
        "status": "candidate run completed; see source_frame_cycles.csv and source_frame_updates.csv for comparisons",
        "frame_summaries": machine.cycle_boundary_candidate["frame_summaries"] if machine else [],
        "frame_380_line48_segments_before_irq_hook": machine.cycle_boundary_candidate["frame_380_line48_segments_before_irq_hook"] if machine else [],
        "frame_380_line48_segments_after_irq_hook": machine.cycle_boundary_candidate["frame_380_line48_segments_after_irq_hook"] if machine else [],
        "frame_380_line48_hook": machine.cycle_boundary_candidate["frame_380_line48_hook"] if machine else None,
    }
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
