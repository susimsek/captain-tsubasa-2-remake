#!/usr/bin/env python3
"""Trace ROM-only runppu state from source frame 380 line 0 through line 48."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc_cycle_boundary_candidate.py"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_stepper_source380_to_line48_trace_20261026"

spec = importlib.util.spec_from_file_location("source380_boundary_candidate", CANDIDATE_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"could not load candidate: {CANDIDATE_PATH}")
candidate = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = candidate
spec.loader.exec_module(candidate)
candidate.base.DEFAULT_OUT = DEFAULT_OUT


class Source380TraceMachine(candidate.NewPPUBoundaryMachine):
    last_instance = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        type(self).last_instance = self
        self.boundary_rows = []

    def _runppu_segment(self, dots: int, line: int, start_dot: int, group: str) -> None:
        selected = self.source_frame == 380 and 0 <= line <= 48
        before = None
        if selected:
            before = {
                "source_frame": self.source_frame,
                "ppu_line": line,
                "call_start_dot": start_dot,
                "call_end_dot": start_dot + dots,
                "call_dots": dots,
                "group": group,
                "cycle_before": self.cpu_cycles,
                "credit_before": self.cpu_credit,
                "pc_before": f"${self.cpu.pc:04X}",
                "irq_before": int(self.irq_pending),
                "nmi_before": int(self.nmi_pending),
            }
        super()._runppu_segment(dots, line, start_dot, group)
        if selected and before is not None:
            before.update({
                "cycle_after": self.cpu_cycles,
                "credit_after": self.cpu_credit,
                "pc_after": f"${self.cpu.pc:04X}",
                "irq_after": int(self.irq_pending),
                "nmi_after": int(self.nmi_pending),
            })
            self.boundary_rows.append(before)


candidate.base.Machine = Source380TraceMachine


def main() -> None:
    candidate.base.main()
    out_dir = DEFAULT_OUT
    args = sys.argv[1:]
    if "--out-dir" in args:
        index = args.index("--out-dir")
        if index + 1 < len(args):
            out_dir = Path(args[index + 1])
    machine = Source380TraceMachine.last_instance
    rows = machine.boundary_rows if machine else []
    path = out_dir / "source380_to_line48_runppu_boundaries.csv"
    columns = [
        "source_frame", "ppu_line", "call_start_dot", "call_end_dot", "call_dots", "group",
        "cycle_before", "cycle_after", "credit_before", "credit_after", "pc_before", "pc_after",
        "irq_before", "irq_after", "nmi_before", "nmi_after",
    ]
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
