#!/usr/bin/env python3
"""Bounded diagnostic: explicit signed budget and IRQ acceptance per NewPPU call.

Builds on the corrected IRQ-mask-shadow/NewPPU wrapper. The ROM executes
without FCEUX timestamps as inputs; this candidate records signed CPU credit
and any interrupt acceptance at each relevant runppu() subcall boundary.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
NEWPPU_CANDIDATE_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc_cycle_boundary_candidate.py"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_stepper_subcall_irq_candidate_380_381_20261026"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"could not load diagnostic: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


newppu = load_module("rom_stepper_newppu_candidate", NEWPPU_CANDIDATE_PATH)
base = newppu.base
base.DEFAULT_OUT = DEFAULT_OUT


class SubcallIRQMachine(newppu.NewPPUBoundaryMachine):
    last_instance = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        type(self).last_instance = self
        self.subcall_irq_trace = {
            "runppu_boundaries": [],
            "interrupt_acceptances": [],
            "trace_window": {
                "frame_380": "PPU line 48, dots 254–284",
                "frame_381": "source cycles 11,328,000–11,328,160",
            },
        }

    def runppu(self, dots: int) -> None:
        cycle_start = self.cpu_cycles
        credit_before = self.cpu_credit
        pending_irq_before = int(self.irq_pending)
        pending_nmi_before = int(self.nmi_pending)
        pc_before = f"${self.cpu.pc:04X}"
        self.cpu_credit += dots * 16
        credit_after_dot_grant = self.cpu_credit
        first_acceptance = None

        # X6502_Run's signed `_count += dots*16; while (_count > 0)` contract.
        # Interrupt priority and the exhausted-IRQ mask-shadow fix are handled
        # by the inherited source-derived _cpu_instruction() at each boundary.
        while self.cpu_credit > 0:
            event_start = len(self.cpu_interrupt_events)
            pre_pc = f"${self.cpu.pc:04X}"
            pre_cycle = self.cpu_cycles
            pre_credit = self.cpu_credit
            self._cpu_instruction()
            accepted = self.cpu_interrupt_events[event_start:]
            if accepted:
                event = {
                    **accepted[-1],
                    "runppu_dot": self.ppu_dot,
                    "runppu_line": self.ppu_line,
                    "runppu_call_dots": dots,
                    "credit_before_acceptance": pre_credit,
                    "credit_after_service": self.cpu_credit,
                    "cpu_cycle_before": pre_cycle,
                    "cpu_cycle_after": self.cpu_cycles,
                    "pc_before_service": pre_pc,
                }
                if first_acceptance is None:
                    first_acceptance = event
                if self.source_frame in (380, 381):
                    self.subcall_irq_trace["interrupt_acceptances"].append(event)

        relevant = (
            (self.source_frame == 380 and self.ppu_line == 48 and 254 <= self.ppu_dot <= 284)
            or (self.source_frame == 381 and 11_328_000 <= self.cpu_cycles <= 11_328_160)
        )
        if relevant:
            self.subcall_irq_trace["runppu_boundaries"].append({
                "source_frame": self.source_frame,
                "ppu_line": self.ppu_line,
                "ppu_dot": self.ppu_dot,
                "runppu_call_dots": dots,
                "cpu_cycle_start": cycle_start,
                "cpu_cycle_end": self.cpu_cycles,
                "cpu_credit_before": credit_before,
                "cpu_credit_after_dot_grant": credit_after_dot_grant,
                "cpu_credit_after_call": self.cpu_credit,
                "pc_before": pc_before,
                "pc_after": f"${self.cpu.pc:04X}",
                "irq_pending_before": pending_irq_before,
                "nmi_pending_before": pending_nmi_before,
                "interrupt_accepted_in_call": first_acceptance,
            })


base.Machine = SubcallIRQMachine


def main() -> None:
    base.main()
    out_dir = DEFAULT_OUT
    args = sys.argv[1:]
    if "--out-dir" in args:
        index = args.index("--out-dir")
        if index + 1 < len(args):
            out_dir = Path(args[index + 1])
    report_path = out_dir / "source_stepper_report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    machine = SubcallIRQMachine.last_instance
    report["subcall_irq_candidate"] = {
        "script": str(Path(__file__).relative_to(ROOT)),
        "model": "signed CPU credit retained across pinned NewPPU runppu() calls; pending IRQ/NMI checked before each next opcode",
        "uses_fitted_cycle_offsets": False,
        "uses_fceux_timestamps_as_execution_input": False,
        "runppu_boundaries": machine.subcall_irq_trace["runppu_boundaries"] if machine else [],
        "interrupt_acceptances": machine.subcall_irq_trace["interrupt_acceptances"] if machine else [],
        "frame_380_hook": machine.cycle_boundary_candidate["frame_380_line48_hook"] if machine else None,
    }
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
