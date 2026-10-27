#!/usr/bin/env python3
"""Diagnostic ROM-only NewPPU call model with FCEUX IRQ-return semantics.

The retained FCEUX dot/cycle traces are loaded only after the reset-to-frame
replay and are used solely for validation. This is not runtime code.
"""

from __future__ import annotations

import csv
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_PATH = ROOT / "tools/diagnostics/predict_a160_ppu_dots_chunked_candidate_20261026.py"
spec = importlib.util.spec_from_file_location("a160_chunked_base", BASE_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"Cannot import {BASE_PATH}")
base = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = base
spec.loader.exec_module(base)


class IRQReturnMachine(base.RasterPredictionMachine):
    """Mirror FCEUX X6502's prior-status update on interrupt-only returns."""

    def _cpu_instruction(self) -> None:
        cpu = self.cpu
        cycles_before = cpu.processorCycles
        pc_before = cpu.pc
        sp_before = cpu.sp
        super()._cpu_instruction()
        # FCEUX X6502_Run sets _PI = _P before returning when an interrupt
        # consumed the run budget. The source stepper otherwise leaves prev_p
        # stale if no opcode ran in this call. Interrupt entry changes PC/SP,
        # charges seven cycles, but does not advance Py65's opcode counter.
        if (cpu.processorCycles == cycles_before and self.cpu_credit <= 0
                and (cpu.pc != pc_before or cpu.sp != sp_before)
                and cpu.p & base.stepper.MPU.INTERRUPT):
            self.prev_p = cpu.p


def read_target_dots(path: Path) -> dict[tuple[int, int], dict]:
    return base.load_reference(path)


def read_target_cycles(path: Path) -> dict[tuple[int, int], int]:
    return base.load_reference_cycles(path)


def read_subframe_writes(path: Path) -> dict[tuple[int, int], dict]:
    """Read direct trace only for post-replay validation."""
    instructions = {"A178": 0xA175, "A17B": 0xA178}
    result = {}
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["type"] != "WRITE2006" or row["pc"] not in instructions:
                continue
            # The direct PPU trace's framectr leads the reference/source-frame
            # label by three. The retained ppu2006_writes.csv explicitly pairs
            # movie_frame 3523 with fceux_framectr 3520, same dot/value.
            frame = int(row["framectr"]) + 3
            pc = instructions[row["pc"]]
            result[(frame, pc)] = {
                "scanline": int(row["sl"]), "dot": int(row["dot_after"]),
                "value": int(row["value"], 16),
            }
    return result


def main() -> None:
    rom = base.ROM_PATH.read_bytes()
    if base.stepper.sha256(rom) != base.EXPECTED_ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 mismatch")
    inputs = base.stepper.load_input_timeline(base.INPUT_PATH)
    machine = IRQReturnMachine(rom, inputs)
    machine.run(3649)

    out_dir = ROOT / "reference/diagnostics/a160_fceux_subframe_trace_20261026"
    all_prediction_path = out_dir / "irq_return_phase_source_predictions.csv"
    with all_prediction_path.open("w", newline="", encoding="utf-8") as stream:
        fields = ("source_frame", "instruction_pc", "cpu_cycle", "value", "predicted_scanline", "predicted_dot", "frame_start_cpu_credit", "frame_dot_model", "mapped_prg_bank_8k")
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(machine.store_rows)

    reference_dots = read_target_dots(base.REFERENCE_PATH)
    reference_cycles = read_target_cycles(ROOT / "reference/opening_timing_capture_20261024_125300/bus_events.csv")
    predictions = {
        (int(row["source_frame"]), int(row["instruction_pc"].replace("$", ""), 16)): row
        for row in machine.store_rows
        if (int(row["source_frame"]), int(row["instruction_pc"].replace("$", ""), 16)) in reference_dots
    }
    details = []
    for key, expected in sorted(reference_dots.items()):
        row = predictions.get(key)
        if row is None:
            details.append({"frame": key[0], "pc": f"${key[1]:04X}", "status": "missing"})
            continue
        predicted_scanline = int(row["predicted_scanline"])
        predicted_dot = int(row["predicted_dot"])
        details.append({
            "frame": key[0], "pc": f"${key[1]:04X}",
            "predicted": [predicted_scanline, predicted_dot],
            "observed": [expected["scanline"], expected["dot"]],
            "scanline_match": predicted_scanline == expected["scanline"],
            "dot_error": predicted_dot - expected["dot"] if predicted_scanline == expected["scanline"] else None,
            "cycle_error": int(row["cpu_cycle"]) - reference_cycles.get(key, int(row["cpu_cycle"])),
            "value_match": int(row["value"]) == expected["value"],
        })

    present = [row for row in details if row.get("status") != "missing"]
    scanline_rows = [row for row in present if row["scanline_match"]]
    dot_errors = [row["dot_error"] for row in scanline_rows]
    # The direct subframe trace spans 98 frames. After deriving the call model
    # from pinned source and ROM execution, compare its complete write set,
    # including frames outside the original 18-frame residual subset.
    actual_subframe = read_subframe_writes(out_dir / "ppu_subframe_trace.csv")
    all_predictions = {
        (int(row["source_frame"]), int(row["instruction_pc"].replace("$", ""), 16)): row
        for row in machine.store_rows
    }
    target_frames = {frame for frame, _pc in reference_dots}
    window_comparisons = []
    for key, actual in sorted(actual_subframe.items()):
        row = all_predictions.get(key)
        if row is None:
            window_comparisons.append({"frame": key[0], "pc": f"${key[1]:04X}", "status": "missing_prediction"})
            continue
        window_comparisons.append({
            "frame": key[0], "pc": f"${key[1]:04X}",
            "predicted": [int(row["predicted_scanline"]), int(row["predicted_dot"])],
            "observed": [actual["scanline"], actual["dot"]],
            "scanline_match": int(row["predicted_scanline"]) == actual["scanline"],
            "dot_match": int(row["predicted_scanline"]) == actual["scanline"] and int(row["predicted_dot"]) == actual["dot"],
            "value_match": int(row["value"]) == actual["value"],
        })
    withheld = [row for row in window_comparisons if row["frame"] not in target_frames]
    window_summary = {
        "direct_trace_write_cases": len(window_comparisons),
        "prediction_cases": sum(row.get("status") != "missing_prediction" for row in window_comparisons),
        "scanline_matches": sum(row.get("scanline_match", False) for row in window_comparisons),
        "exact_scanline_and_dot": sum(row.get("dot_match", False) for row in window_comparisons),
        "value_matches": sum(row.get("value_match", False) for row in window_comparisons),
        "withheld_non_target_cases": len(withheld),
        "withheld_exact_scanline_and_dot": sum(row.get("dot_match", False) for row in withheld),
        "withheld_value_matches": sum(row.get("value_match", False) for row in withheld),
        "frame_range_source_frame": [min(row["frame"] for row in window_comparisons), max(row["frame"] for row in window_comparisons)] if window_comparisons else None,
        "frame_mapping": "source_frame = FCEUX framectr + 3, independently confirmed by ppu2006_writes.csv (movie_frame 3523 ↔ framectr 3520, including identical dots and values).",
        "note": "The model was run from reset without frame/line gates; direct trace rows were opened only after predictions were written.",
    }
    report = {
        "rom_sha256": base.EXPECTED_ROM_SHA256,
        "input_timeline_sha256": base.stepper.sha256(base.INPUT_PATH.read_bytes()),
        "source_frames_advanced": machine.source_frame,
        "prediction_count_total": len(machine.store_rows),
        "target_cases": len(details),
        "predicted_cases": len(present),
        "scanline_matches": len(scanline_rows),
        "scanline_and_dot_exact": sum(error == 0 for error in dot_errors),
        "dot_error_min_max": [min(dot_errors), max(dot_errors)] if dot_errors else None,
        "cpu_cycle_error_min_max": [
            min(row["cycle_error"] for row in present), max(row["cycle_error"] for row in present)
        ] if present else None,
        "value_matches": sum(row.get("value_match", False) for row in present),
        "validation_reads_captured_dots_only_after_source_replay": True,
        "full_subframe_trace_window_validation": window_summary,
        "all_source_predictions_csv": all_prediction_path.relative_to(ROOT).as_posix(),
        "per_store": details,
        "interpretation": "Diagnostic-only source-call model; no frame/line gates, captured-dot inputs, fixed offsets, or Godot runtime changes.",
    }
    out_path = out_dir / "irq_return_phase_prediction_report.json"
    out_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items() if key != "per_store"}, indent=2))
    print(f"report={out_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
