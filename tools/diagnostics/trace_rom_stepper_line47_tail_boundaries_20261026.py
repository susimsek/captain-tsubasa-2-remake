#!/usr/bin/env python3
"""Export ROM-only runppu state across source frame 380's line-47 tail."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NEWPPU_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc_cycle_boundary_candidate.py"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_stepper_line47_tail_boundary_trace_20261026"
spec = importlib.util.spec_from_file_location("line47_tail_newppu_candidate", NEWPPU_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"could not load candidate: {NEWPPU_PATH}")
newppu = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = newppu
spec.loader.exec_module(newppu)
base = newppu.base
base.DEFAULT_OUT = DEFAULT_OUT


class Line47TailTraceMachine(newppu.NewPPUBoundaryMachine):
    last_instance = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        type(self).last_instance = self
        self.tail_trace = []

    def _runppu_segment(self, dots: int, line: int, start_dot: int, group: str) -> None:
        self.ppu_line = line
        self.ppu_dot = start_dot
        selected = (
            self.source_frame == 380
            and ((line == 47 and start_dot <= 340) or (line == 48 and start_dot == 0))
        )
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
            self.tail_trace.append(before)


base.Machine = Line47TailTraceMachine


def main() -> None:
    base.main()
    out_dir = DEFAULT_OUT
    args = sys.argv[1:]
    if "--out-dir" in args:
        index = args.index("--out-dir")
        if index + 1 < len(args):
            out_dir = Path(args[index + 1])
    machine = Line47TailTraceMachine.last_instance
    rows = machine.tail_trace if machine else []
    csv_path = out_dir / "line47_tail_runppu_boundaries.csv"
    columns = [
        "source_frame", "ppu_line", "call_start_dot", "call_end_dot", "call_dots", "group",
        "cycle_before", "cycle_after", "credit_before", "credit_after", "pc_before", "pc_after",
        "irq_before", "irq_after", "nmi_before", "nmi_after",
    ]
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        f.write(",".join(columns) + "\n")
        for row in rows:
            values = []
            for column in columns:
                value = str(row.get(column, ""))
                if "," in value or '"' in value:
                    value = '"' + value.replace('"', '""') + '"'
                values.append(value)
            f.write(",".join(values) + "\n")
    report_path = out_dir / "source_stepper_report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    report["line47_tail_boundary_trace"] = {
        "source_frame": 380,
        "ppu_line": 47,
        "recorded_calls": len(rows),
        "includes_line48_first_call": True,
        "output": str(csv_path.resolve().relative_to(ROOT)),
        "semantics": "per-call before/after state; align candidate call_end_dot with FCEUX post-increment ppur.status.cycle",
        "uses_fceux_timestamps_as_execution_input": False,
    }
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
