#!/usr/bin/env python3
"""Diagnostics-only experiment staging an opcode across a pinned MMC3 hook.

This candidate is intentionally not production behavior. It builds on the
signed-credit NewPPU runner and tests a resumable semantics-commit seam: when
the source-predicted MMC3 slot-2 hook will assert IRQ, charge the next whole
opcode's base cycles and run its sound hook, but defer its Py65 semantics if
that charge exhausts the signed budget. If IRQ is pending when execution next
resumes, service it before committing the staged opcode; commit after RTI.
This is an experiment, not the pinned FCEUX atomic-opcode contract.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SUBCALL_CANDIDATE_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc_subcall_irq_candidate.py"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_stepper_deferred_commit_candidate_378_381_20261026"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"could not load diagnostic: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


subcall = load_module("rom_stepper_subcall_irq_candidate", SUBCALL_CANDIDATE_PATH)
base = subcall.base
base.DEFAULT_OUT = DEFAULT_OUT


class DeferredCommitMachine(subcall.SubcallIRQMachine):
    last_instance = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        type(self).last_instance = self
        self.current_runppu_group = ""
        self.staged_instruction = None
        self.deferred_commit_trace = {
            "staged_opcodes": [],
            "interrupts_before_commit": [],
            "committed_opcodes": [],
            "policy": "in frames 378-381 only, stage the opcode whose base-cycle charge exhausts credit at a slot-2 garbage-fetch call when ROM MMC3 state predicts the following hook will assert IRQ",
            "source_supported_hook": "pinned NewPPU calls GameHBIRQHook after slot 2 runppu(garbage_todo)",
        }

    def _runppu_segment(self, dots: int, line: int, start_dot: int, group: str) -> None:
        previous = self.current_runppu_group
        self.current_runppu_group = group
        try:
            super()._runppu_segment(dots, line, start_dot, group)
        finally:
            self.current_runppu_group = previous

    def _next_slot2_irq_is_source_predicted(self) -> bool:
        return (
            self.source_frame in (378, 379, 380, 381)
            and self.current_runppu_group == "sprite slot 2 garbage fetch"
            and self.ppu_regs[1] & 0x18 != 0
            and self.ppu_regs[0] & 0x38 != 0x18
            and self.mmc3_enabled
            and not self.mmc3_reload
            and self.mmc3_count == 1
            and not self.irq_pending
        )

    def _accept_pending_interrupt(self) -> bool:
        cpu = self.cpu
        if self.nmi_pending and not self.jammed:
            event = {
                "source_frame": self.source_frame,
                "cycle": self.cpu_cycles,
                "kind": "NMI",
                "pc_before": f"${cpu.pc:04X}",
                "runppu_line": self.ppu_line,
                "runppu_dot": self.ppu_dot,
                "credit_before_service": self.cpu_credit,
            }
            self._charge(7)
            self._hardware_interrupt(0xFFFA)
            self.nmi_pending = False
        elif self.irq_pending and not (self.prev_p & base.MPU.INTERRUPT) and not self.jammed:
            event = {
                "source_frame": self.source_frame,
                "cycle": self.cpu_cycles,
                "kind": "IRQ",
                "pc_before": f"${cpu.pc:04X}",
                "runppu_line": self.ppu_line,
                "runppu_dot": self.ppu_dot,
                "credit_before_service": self.cpu_credit,
            }
            self._charge(7)
            self._hardware_interrupt(0xFFFE)
        else:
            return False
        self.cpu_interrupt_events.append(event)
        self.prev_p = cpu.p
        if self.staged_instruction is not None:
            self.deferred_commit_trace["interrupts_before_commit"].append({
                **event,
                "staged_pc": f"${self.staged_instruction['pc']:04X}",
                "staged_opcode": f"${self.staged_instruction['opcode']:02X}",
                "credit_after_service": self.cpu_credit,
            })
        return True

    def _start_staged_instruction(self) -> None:
        cpu = self.cpu
        instruction_pc = cpu.pc
        opcode = self[instruction_pc]
        base_cycles = cpu.cycletime[opcode]
        self.current_instruction_pc = instruction_pc
        self.current_instruction_opcode = opcode
        mode = base.MPU.disassemble[opcode][1]
        self.current_instruction_len = 1 if mode in ("imp", "acc") else 2 if mode in ("imm", "zpg", "zpx", "zpy", "rel", "inx", "iny") else 3
        instruction_bank = self._prg_bank(instruction_pc)
        credit_before = self.cpu_credit
        self.prev_p = cpu.p
        cpu.pc = (cpu.pc + 1) & 0xFFFF
        cpu.excycles = 0
        cpu.addcycles = cpu.extracycles[opcode]
        self._charge(base_cycles)
        credit_after_base = self.cpu_credit
        hook_cycles = self.hook_cycles
        self.hook_cycles = 0
        hook_cycle_start = self.cpu_cycles - hook_cycles
        hook_cycle_end = self.cpu_cycles
        self._dmc_hook(hook_cycles)

        self.staged_instruction = {
            "pc": instruction_pc,
            "opcode": opcode,
            "mode": mode,
            "base_cycles": base_cycles,
            "instruction_len": self.current_instruction_len,
            "instruction_bank": instruction_bank,
            "credit_before": credit_before,
            "credit_after_base": credit_after_base,
            "hook_cycles": hook_cycles,
            "hook_cycle_start": hook_cycle_start,
            "hook_cycle_end": hook_cycle_end,
        }
        # Preserve the instruction address so a newly pending IRQ stacks the
        # resume PC, while Py65 has not yet applied the opcode's semantics.
        cpu.pc = instruction_pc
        self.deferred_commit_trace["staged_opcodes"].append({
            "source_frame": self.source_frame,
            "ppu_line": self.ppu_line,
            "ppu_dot": self.ppu_dot,
            "pc": f"${instruction_pc:04X}",
            "opcode": f"${opcode:02X}",
            "base_cycles": base_cycles,
            "cpu_cycle_after_base": self.cpu_cycles,
            "credit_before": credit_before,
            "credit_after_base": credit_after_base,
            "irq_pending": int(self.irq_pending),
        })

    def _commit_staged_instruction(self) -> None:
        pending = self.staged_instruction
        if pending is None:
            return
        cpu = self.cpu
        if cpu.pc != pending["pc"]:
            raise RuntimeError("staged opcode can only commit after its PC is restored")
        cpu.pc = (cpu.pc + 1) & 0xFFFF
        cpu.excycles = 0
        cpu.addcycles = cpu.extracycles[pending["opcode"]]
        cpu.instruct[pending["opcode"]](cpu)
        cpu.pc &= 0xFFFF
        extra = cpu.excycles
        if extra:
            self._charge(extra)
        cpu.processorCycles += pending["base_cycles"] + extra
        self.deferred_commit_trace["committed_opcodes"].append({
            "source_frame": self.source_frame,
            "cpu_cycle": self.cpu_cycles,
            "pc": f"${pending['pc']:04X}",
            "opcode": f"${pending['opcode']:02X}",
            "extra_cycles": extra,
            "resumed_after_irq": any(
                row["staged_pc"] == f"${pending['pc']:04X}"
                for row in self.deferred_commit_trace["interrupts_before_commit"]
            ),
        })
        self.staged_instruction = None

    def runppu(self, dots: int) -> None:
        self.cpu_credit += dots * 16
        while self.cpu_credit > 0:
            if self.staged_instruction is not None:
                if self.cpu.pc == self.staged_instruction["pc"]:
                    if self._accept_pending_interrupt():
                        if self.cpu_credit <= 0:
                            return
                        continue
                    self._commit_staged_instruction()
                    continue
                # A staged opcode remains suspended while its IRQ handler runs.
                super()._cpu_instruction()
                continue

            if self.reset_pending:
                super()._cpu_instruction()
                continue
            if self.nmi_pending or (self.irq_pending and not (self.prev_p & base.MPU.INTERRUPT)):
                super()._cpu_instruction()
                continue

            opcode = self[self.cpu.pc]
            required = self.cpu.cycletime[opcode] * 48
            if self._next_slot2_irq_is_source_predicted() and self.cpu_credit - required <= 0:
                self._start_staged_instruction()
                if self.cpu_credit <= 0:
                    return
                self._commit_staged_instruction()
                continue
            super()._cpu_instruction()


base.Machine = DeferredCommitMachine
base.DEFAULT_OUT = DEFAULT_OUT


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
    machine = DeferredCommitMachine.last_instance
    report["deferred_commit_candidate"] = {
        "script": str(Path(__file__).relative_to(ROOT)),
        "source_fceux_contract": "diagnostic variation: cycle charge and sound hook are source-timed, but opcode semantics are deferred across an MMC3 PPU callback when signed credit is exhausted",
        "uses_fitted_offsets": False,
        "uses_fceux_trace_as_execution_input": False,
        "trace": machine.deferred_commit_trace if machine else {},
    }
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
