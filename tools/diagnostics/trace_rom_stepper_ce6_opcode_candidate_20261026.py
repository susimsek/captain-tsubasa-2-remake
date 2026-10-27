#!/usr/bin/env python3
"""Diagnostics-only candidate with ROM-sourced FCEUX timing for opcode $CE."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc_cycle_boundary_candidate.py"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_stepper_opcode_ce6_candidate_20261026"

spec = importlib.util.spec_from_file_location("ce6_boundary_candidate", CANDIDATE_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"could not load candidate: {CANDIDATE_PATH}")
candidate = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = candidate
spec.loader.exec_module(candidate)
candidate.base.DEFAULT_OUT = DEFAULT_OUT


class OpcodeCE6TraceMachine(candidate.NewPPUBoundaryMachine):
    last_instance = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        type(self).last_instance = self
        py65_cycles = int(self.cpu.cycletime[0xCE])
        if py65_cycles != 3:
            raise RuntimeError(f"expected pinned Py65 $CE base cycle count 3; got {py65_cycles}")
        self.cpu.cycletime[0xCE] = 6
        self.opcode_timing_override = {
            "opcode": "$CE",
            "mnemonic": "DEC absolute",
            "py65_1_2_0_cycles": py65_cycles,
            "pinned_fceux_2_7_0_cycles": 6,
            "source": "pinned FCEUX x6502.cpp CycTable[0xCE]",
            "no_fitted_offset": True,
        }
        self.source380_rows = []

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
            self.source380_rows.append(before)


candidate.base.Machine = OpcodeCE6TraceMachine


def main() -> None:
    candidate.base.main()
    out_dir = DEFAULT_OUT
    args = sys.argv[1:]
    if "--out-dir" in args:
        index = args.index("--out-dir")
        if index + 1 < len(args):
            out_dir = Path(args[index + 1])
    machine = OpcodeCE6TraceMachine.last_instance
    rows = machine.source380_rows if machine else []
    columns = [
        "source_frame", "ppu_line", "call_start_dot", "call_end_dot", "call_dots", "group",
        "cycle_before", "cycle_after", "credit_before", "credit_after", "pc_before", "pc_after",
        "irq_before", "irq_after", "nmi_before", "nmi_after",
    ]
    path = out_dir / "source380_lines0_48_runppu_boundaries.csv"
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)
    report_path = out_dir / "source_stepper_report.json"
    report = __import__("json").loads(report_path.read_text(encoding="utf-8"))
    report["diagnostic_opcode_timing_override"] = machine.opcode_timing_override if machine else None
    report["source380_boundary_rows"] = {
        "count": len(rows),
        "path": str(path.resolve().relative_to(ROOT)),
        "uses_fceux_timestamps_as_execution_input": False,
    }
    report_path.write_text(__import__("json").dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
