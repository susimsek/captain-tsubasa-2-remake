#!/usr/bin/env python3
"""Replay the ROM with the MMC3 hook gate evaluated at NewPPU slot 2.

This is diagnostics-only. It compares slot-2 count/reload state against a
muted, same-input FCEUX trace and does not feed captured values into execution.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODEL_PATH = ROOT / "tools/diagnostics/predict_a160_ppu_dots_irq_return_poc_20261026.py"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
TARGETS = {1029, 1760, 2121}

spec = importlib.util.spec_from_file_location("a160_irq_return_model", MODEL_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"Cannot import {MODEL_PATH}")
model = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = model
spec.loader.exec_module(model)


class SlotBoundaryMachine(model.IRQReturnMachine):
    """Use FCEUX's PPU-register gate at dot 274, after its lead-in calls."""

    def __init__(self, *args, **kwargs):
        self.slot_rows: list[dict] = []
        self.register_writes: list[dict] = []
        super().__init__(*args, **kwargs)
        if int(self.cpu.cycletime[0xCE]) != 3:
            raise RuntimeError("Expected Py65 $CE base cycle count of three")
        self.cpu.cycletime[0xCE] = 6

    def _irq_clock(self, source_ppu_line=None, source_ppu_dot=None) -> None:
        before = (self.mmc3_count, self.mmc3_reload, self.mmc3_enabled, self.irq_pending)
        super()._irq_clock()
        if self.source_frame in TARGETS:
            self.slot_rows.append({
                "source_frame": self.source_frame,
                "cycle_abs": self.cpu_cycles,
                "cycle_from_frame_start": self.cpu_cycles - self.frame_cycle_start,
                "ppu_line": source_ppu_line if source_ppu_line is not None else self.ppu_line,
                "ppu_dot": source_ppu_dot if source_ppu_dot is not None else self.ppu_dot,
                "hook_called": 1,
                "count_before": before[0],
                "count_after": self.mmc3_count,
                "reload_before": int(before[1]),
                "reload_after": int(self.mmc3_reload),
                "irq_enable": int(self.mmc3_enabled),
                "irq_pending_before": int(before[3]),
                "irq_pending_after": int(self.irq_pending),
                "pc": f"${self.cpu.pc:04X}",
                "p": f"${self.cpu.p:02X}",
                "pi": f"${self.prev_p:02X}",
            })

    def __setitem__(self, addr: int, value: int) -> None:
        addr &= 0xFFFF
        if self.source_frame in TARGETS and addr in (0x2000, 0x2001, 0xC000, 0xC001, 0xE000, 0xE001):
            self.register_writes.append({
                "source_frame": self.source_frame,
                "cycle_abs": self.cpu_cycles,
                "cycle_from_frame_start": self.cpu_cycles - self.frame_cycle_start,
                "address": f"${addr:04X}",
                "value": f"${value & 0xFF:02X}",
                "pc": f"${(self.current_instruction_pc + self.current_instruction_len) & 0xFFFF:04X}",
            })
        super().__setitem__(addr, value)

    def run_frame(self, frame: int) -> None:
        self.frame_start_cpu_credit = self.cpu_credit
        self.frame_start_ppu_progress = self.requested_ppu_dots - (self.cpu_credit // 16)
        cycle_start = self.cpu_cycles
        self.source_frame = frame
        self.frame_cycle_start = cycle_start
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
            self.runppu(20 * 341)
            self.runppu(242 * 341)
            self.dead_frames -= 1
            self.frame_stats.append({"source_frame": frame, "cycle_start": cycle_start, "cycle_end": self.cpu_cycles, "cycle_delta": self.cpu_cycles - cycle_start})
            return

        self.vblank = True
        self.ppu_status |= 0x80
        self.ppu_line = 241
        self.runppu(20)
        if self.ppu_regs[0] & 0x80:
            self.nmi_pending = True
        self.runppu(20 * 341 - 20)
        self.ppu_status &= 0x7F
        self.vblank = False

        short_first_line = bool(self.idle_synch and (self.ppu_regs[1] & 0x18))
        self.idle_synch ^= 1
        for line in range(241):
            self.ppu_line = line
            self.ppu_dot = 0
            line_len = 340 if line == 0 and short_first_line else 341

            # Pinned NewPPU source advances through BG records and sprite slots
            # before it tests PPUON/PPUCTRL for GameHBIRQHook at sprite slot 2.
            self.runppu(274)
            mask, ctrl = self.ppu_regs[1], self.ppu_regs[0]
            should_clock = bool(mask & 0x18) and ((ctrl & 0x38) != 0x18)
            if should_clock:
                self._irq_clock(line, 274)
            else:
                # The source still performs the post-slot-2 fetch calls when
                # MMC3's render-gated hook itself is skipped.
                self._split_next_irq_remainder = True
            self.runppu(line_len - 274)

        self.runppu(341)
        self.frame_stats.append({"source_frame": frame, "cycle_start": cycle_start, "cycle_end": self.cpu_cycles, "cycle_delta": self.cpu_cycles - cycle_start})


def write_rows(path: Path, rows: list[dict]) -> None:
    if not rows:
        raise RuntimeError(f"No rows to write for {path}")
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--end-frame", type=int, default=2121)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()
    rom = model.base.ROM_PATH.read_bytes()
    if model.base.stepper.sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 mismatch")
    inputs = model.base.stepper.load_input_timeline(model.base.INPUT_PATH)
    machine = SlotBoundaryMachine(rom, inputs)
    machine.run(args.end_frame)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_rows(args.out_dir / "rom_model_slot_boundary_hooks.csv", machine.slot_rows)
    write_rows(args.out_dir / "rom_model_slot_boundary_register_writes.csv", machine.register_writes)
    event_frames: dict[int, dict[str, dict]] = {}
    for row in machine.store_rows:
        pc = str(row["instruction_pc"])
        if pc not in ("$A175", "$A178"):
            continue
        frame = int(row["source_frame"])
        event_frames.setdefault(frame, {})[pc] = {
            "cpu_cycle": int(row["cpu_cycle"]),
            "scanline": int(row["predicted_scanline"]),
            "dot": int(row["predicted_dot"]),
            "value": int(row["value"]),
        }
    packed_frames = []
    for frame, writes_by_pc in sorted(event_frames.items()):
        if set(writes_by_pc) != {"$A175", "$A178"}:
            raise RuntimeError(f"Frame {frame} has an incomplete A160 write pair: {writes_by_pc}")
        packed_frames.append({
            "source_frame": frame,
            "writes": [writes_by_pc["$A175"], writes_by_pc["$A178"]],
        })
    input_bytes = model.base.INPUT_PATH.read_bytes()
    timeline = {
        "schema": 1,
        "rom_sha256": EXPECTED_ROM_SHA256,
        "source_model": "ROM-only 6502/MMC3/PPU stepper; NewPPU slot-2 PPUON/PPUCTRL gate evaluated at dot 274 with source-call subdivision and IRQ-return semantics",
        "source_predictor": Path(__file__).relative_to(ROOT).as_posix(),
        "source_stepper": model.base.stepper.__file__.replace(str(ROOT) + "/", ""),
        "controller_timeline_sha256": hashlib.sha256(input_bytes).hexdigest(),
        "controller_timeline_role": "captured input route drives ROM execution only; it is not PPU timing or memory-state input",
        "input_route_scope": "deterministic captured intro route, not a general arbitrary-input CPU emulator",
        "fceux_ppu_trace_or_visual_capture_used_for_generation": False,
        "fceux_validation_scope": "diagnostics-only candidate; compared against retained and pinned same-input FCEUX traces",
        "source_frame_range": [min(event_frames), max(event_frames)],
        "frame_count": len(packed_frames),
        "write_count": sum(len(frame["writes"]) for frame in packed_frames),
        "events": packed_frames,
    }
    candidate_path = args.out_dir / "a160_boundary_gate_candidate.json"
    candidate_path.write_text(json.dumps(timeline, indent=2) + "\n", encoding="utf-8")
    print(f"frames={machine.source_frame} hooks={len(machine.slot_rows)} writes={len(machine.register_writes)}")
    print(f"a160_frames={len(packed_frames)} a160_writes={timeline['write_count']} candidate={candidate_path}")
    for frame in sorted(TARGETS):
        rows = [row for row in machine.slot_rows if row["source_frame"] == frame]
        print(f"frame={frame} hooks={len(rows)} edge_cycles={[row['cycle_from_frame_start'] for row in rows if row['irq_pending_after'] and not row['irq_pending_before']]}")


if __name__ == "__main__":
    main()
