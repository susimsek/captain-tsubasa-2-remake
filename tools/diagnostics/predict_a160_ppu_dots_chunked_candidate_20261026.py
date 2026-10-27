#!/usr/bin/env python3
"""Predict the shared raster handler's $2006 store positions from ROM execution.

The FCEUX dot trace is read only after prediction, for validation. It is never
used to schedule this ROM-only CPU/MMC3/PPU replay.
"""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STEPPER_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
REFERENCE_PATH = ROOT / "reference/diagnostics/oam_all_residual_trace_20261026/ppu2006_writes.csv"
DEFAULT_OUT = ROOT / "reference/diagnostics/a160_rom_only_dot_prediction_20261026"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

spec = importlib.util.spec_from_file_location("ct2_source_stepper", STEPPER_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"Could not import ROM source stepper: {STEPPER_PATH}")
stepper = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = stepper
spec.loader.exec_module(stepper)


class RasterPredictionMachine(stepper.Machine):
    def __init__(self, *args, **kwargs):
        self.requested_ppu_dots = 0
        self.frame_start_ppu_progress = 0
        self.frame_start_cpu_credit = 0
        self.frame_short_first_line = False
        self._active_ppu_line = None
        self.active_line_dot = 0
        self._split_next_irq_remainder = False
        self.store_rows: list[dict] = []
        super().__init__(*args, **kwargs)

    def runppu(self, dots: int) -> None:
        if dots == 274:
            # The source's 274-dot lead-in is not one large FCEUX call: it is
            # 32 background records at one dot each, the 256-dot BG phase,
            # then the first two sprite slots and slot-2 garbage fetch.
            for total, quantum in ((256, 1), (2, 1), (6, 2), (8, 2), (2, 2)):
                self._run_fceux_calls(total, quantum)
            return
        if self._split_next_irq_remainder:
            self._split_next_irq_remainder = False
            # Pinned FCEUX 2.7.0 NewPPU source call order after MMC3 sprite
            # slot 2: finish slot 2 (three two-dot calls), fetch slots 3–7
            # (four two-dot calls each), read two BG records (16 one-dot
            # calls), then perform the final 2+2 and optional 1-dot calls.
            segments = [(6, 2), (40, 2), (16, 1), (4, 2)]
            if dots == 67:
                segments.append((1, 1))
            if sum(total for total, _quantum in segments) != dots:
                raise AssertionError(f"Unexpected FCEUX NewPPU line remainder: {dots} dots")
            for total, quantum in segments:
                self._run_fceux_calls(total, quantum)
            return

        if self._active_ppu_line != self.ppu_line:
            self._active_ppu_line = self.ppu_line
            self.active_line_dot = 0
        self.requested_ppu_dots += dots
        self.active_line_dot = (self.active_line_dot + dots) % 341
        super().runppu(dots)

    def _run_fceux_calls(self, total: int, quantum: int) -> None:
        """Batch identical NewPPU calls up to the next CPU instruction edge."""
        remaining = total
        while remaining:
            if self.cpu_credit > 0:
                dots = quantum
            else:
                dots_to_instruction = (-self.cpu_credit) // 16 + 1
                calls = max(1, (dots_to_instruction + quantum - 1) // quantum)
                dots = min(remaining, calls * quantum)
            dots = min(dots, remaining)
            self.runppu(dots)
            remaining -= dots

    def _irq_clock(self) -> None:
        super()._irq_clock()
        # The base frame runner inserts this hook at the NewPPU sprite slot-2
        # boundary (dot 274). Split only the following remainder into the
        # generic source-call pattern; no frame-specific trace data is used.
        self._split_next_irq_remainder = True

    def run_frame(self, frame: int) -> None:
        self.frame_start_cpu_credit = self.cpu_credit
        self.frame_start_ppu_progress = self.requested_ppu_dots - (self.cpu_credit // 16)
        # The source stepper's NewPPU model toggles this one-dot shortened line
        # on alternate rendered frames. The field scene has rendering enabled.
        self.frame_short_first_line = bool(self.idle_synch and (self.ppu_regs[1] & 0x18))
        super().run_frame(frame)

    def __setitem__(self, addr: int, value: int) -> None:
        addr &= 0xFFFF
        if addr == 0x2006 and self.current_instruction_pc in (0xA175, 0xA178):
            self.store_rows.append({
                "source_frame": self.source_frame,
                "instruction_pc": f"${self.current_instruction_pc:04X}",
                "cpu_cycle": self.cpu_cycles,
                "value": value & 0xFF,
                "predicted_scanline": self.ppu_line,
                "predicted_dot": self.active_line_dot,
                "frame_start_cpu_credit": self.frame_start_cpu_credit,
                "frame_dot_model": "ROM CPU/MMC3 stepper with generic pinned-NewPPU slot-2 call subdivision; captured dots are validation only",
                "mapped_prg_bank_8k": self._prg_bank(self.current_instruction_pc),
            })
        super().__setitem__(addr, value)


def load_reference(path: Path) -> dict[tuple[int, int], dict]:
    rows: dict[tuple[int, int], dict] = {}
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["writer_pc_assuming_sta_abs"] not in ("$A175", "$A178"):
                continue
            key = (int(row["movie_frame"]), int(row["writer_pc_assuming_sta_abs"].replace("$", ""), 16))
            rows[key] = {
                "scanline": int(row["scanline"]),
                "dot": int(row["dot"]),
                "cycle": None,
                "value": int(row["value"].replace("$", ""), 16),
            }
    return rows


def load_reference_cycles(path: Path) -> dict[tuple[int, int], int]:
    result: dict[tuple[int, int], int] = {}
    wanted = {3523,3525,3527,3536,3547,3551,3555,3560,3561,3564,3571,3575,3576,3583,3594,3635,3645,3649}
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            frame = int(row["source_frame"])
            if frame not in wanted or row["event"] != "PPUADDR_write":
                continue
            cycle = int(row["cycle_absolute"])
            cpu_pc = int(row["cpu_pc"].replace("$", ""), 16)
            # The bus callback records the 6502 PC after the 3-byte store.
            pc = {0xA178: 0xA175, 0xA17B: 0xA178}.get(cpu_pc)
            if pc is None:
                continue
            key = (frame, pc)
            if key in result:
                continue
            result[key] = cycle
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--end-frame", type=int, default=3649)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--input-timeline", type=Path, default=INPUT_PATH)
    parser.add_argument("--validate", action="store_true", help="compare predictions to the retained same-run FCEUX trace after prediction")
    parser.add_argument("--fceux-dots", type=Path, default=REFERENCE_PATH)
    parser.add_argument("--fceux-cycles", type=Path, default=ROOT / "reference/opening_timing_capture_20261024_125300/bus_events.csv")
    args = parser.parse_args()
    args.out_dir = args.out_dir.resolve()

    rom = ROM_PATH.read_bytes()
    if stepper.sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 does not match the expected source revision.")
    input_rows = stepper.load_input_timeline(args.input_timeline)
    machine = RasterPredictionMachine(rom, input_rows)
    machine.run(args.end_frame)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    prediction_path = args.out_dir / "rom_only_store_dot_predictions.csv"
    with prediction_path.open("w", newline="", encoding="utf-8") as stream:
        fields = ("source_frame", "instruction_pc", "cpu_cycle", "value", "predicted_scanline", "predicted_dot", "frame_start_cpu_credit", "frame_dot_model", "mapped_prg_bank_8k")
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(machine.store_rows)

    result = {
        "rom_sha256": EXPECTED_ROM_SHA256,
        "input_timeline_sha256": stepper.sha256(args.input_timeline.read_bytes()),
        "source_frames_advanced": args.end_frame,
        "predictions": len(machine.store_rows),
        "prediction_csv": prediction_path.relative_to(ROOT).as_posix(),
        "validation_uses_captured_dots_only_after_prediction": bool(args.validate),
    }
    if args.validate:
        ref_dots = load_reference(args.fceux_dots)
        ref_cycles = load_reference_cycles(args.fceux_cycles)
        predicted = {
            (int(row["source_frame"]), int(row["instruction_pc"].replace("$", ""), 16)): row
            for row in machine.store_rows
            if int(row["source_frame"]) in {frame for frame, _pc in ref_dots}
        }
        matches = []
        for key, actual in sorted(ref_dots.items()):
            guess = predicted.get(key)
            if guess is None:
                matches.append({"source_frame": key[0], "pc": f"${key[1]:04X}", "status": "missing_prediction"})
                continue
            pred_scan = int(guess["predicted_scanline"])
            pred_dot = int(guess["predicted_dot"])
            matches.append({
                "source_frame": key[0],
                "pc": f"${key[1]:04X}",
                "predicted": [pred_scan, pred_dot],
                "observed": [actual["scanline"], actual["dot"]],
                "dot_error": pred_dot - actual["dot"] if pred_scan == actual["scanline"] else None,
                "scanline_match": pred_scan == actual["scanline"],
                "cycle_error": int(guess["cpu_cycle"]) - ref_cycles.get(key, int(guess["cpu_cycle"])),
            })
        result["validation"] = {
            "cases": len(matches),
            "matched_scanline_and_dot": sum(1 for row in matches if row.get("status") != "missing_prediction" and row.get("predicted") == row.get("observed")),
            "matched_scanline": sum(1 for row in matches if row.get("status") != "missing_prediction" and row.get("scanline_match")),
            "cases_with_prediction": sum(1 for row in matches if row.get("status") != "missing_prediction"),
            "per_store": matches,
            "note": "Only the post-run validation reads FCEUX observations. Predicted dot rows were generated from ROM execution and the stepper's PPU/CPU schedule.",
        }
    result_path = args.out_dir / "prediction_report.json"
    result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"prediction_report": result_path.relative_to(ROOT).as_posix(), **result}, indent=2))


if __name__ == "__main__":
    main()
