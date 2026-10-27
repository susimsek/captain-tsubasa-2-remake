#!/usr/bin/env python3
"""Replay the ROM from reset and compare its source-derived Start poll cycles.

The supplied FCEUX trace is opened only after the ROM-only CPU/PPU/DMC replay
has completed. It is a post-run validation oracle, never a scheduler input.
"""

from __future__ import annotations

import argparse
import csv
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
STEPPER_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
DEFAULT_FCEUX_TRACE = ROOT / "reference/diagnostics/start_poll_fceux_cycles_20261027_080233"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/start_poll_rom_source_timing_20261027"
POLL_PC = 0x802C


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def import_stepper():
    spec = importlib.util.spec_from_file_location("ct2_rom_source_stepper", STEPPER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import source stepper: {STEPPER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def source_poll_events(stepper, rom: bytes, inputs: dict[int, dict], end_frame: int) -> list[dict]:
    machine = stepper.Machine(rom, inputs)
    events: list[dict] = []
    original_instruction = machine._cpu_instruction

    def trace_instruction() -> None:
        instruction_pc = machine.cpu.pc
        source_frame = machine.source_frame
        absolute_cycle_start = machine.cpu_cycles
        original_instruction()
        if instruction_pc != POLL_PC:
            return
        events.append({
            "source_frame": source_frame,
            "cycle_from_frame_start": machine.cpu_cycles - machine.frame_cycle_start,
            "cycle_absolute": machine.cpu_cycles,
            "instruction_cycle_start": absolute_cycle_start,
            "instruction_cycle_end": machine.cpu_cycles,
            "instruction_cycle_delta": machine.cpu_cycles - absolute_cycle_start,
            "instruction_pc": f"${instruction_pc:04X}",
            "next_pc": f"${machine.cpu.pc:04X}",
        })

    machine._cpu_instruction = trace_instruction
    machine.run(end_frame)
    return events


def load_fceux_poll_events(trace_dir: Path) -> tuple[list[dict], dict[str, str]]:
    events_path = trace_dir / "events.csv"
    frames_path = trace_dir / "frame_cycles.csv"
    metadata_path = trace_dir / "metadata.txt"
    if not events_path.is_file() or not frames_path.is_file():
        raise FileNotFoundError(f"FCEUX trace is missing events.csv or frame_cycles.csv: {trace_dir}")
    rows = []
    with events_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["event"] == "execute" and row["cpu_pc"] == f"${POLL_PC:04X}":
                rows.append({
                    "source_frame": int(row["source_frame"]),
                    "cycle_from_frame_start": int(row["cycle_from_frame_start"]),
                    "cycle_absolute": int(row["cycle_absolute"]),
                })
    hashes = {
        "events_csv_sha256": sha256(events_path.read_bytes()),
        "frame_cycles_csv_sha256": sha256(frames_path.read_bytes()),
    }
    if metadata_path.is_file():
        hashes["metadata_txt_sha256"] = sha256(metadata_path.read_bytes())
    return rows, hashes


def compare(source_rows: list[dict], fceux_rows: list[dict]) -> tuple[list[dict], dict]:
    source_by_frame = {int(row["source_frame"]): row for row in source_rows}
    fceux_by_frame = {int(row["source_frame"]): row for row in fceux_rows}
    if len(source_by_frame) != len(source_rows) or len(fceux_by_frame) != len(fceux_rows):
        raise ValueError("duplicate $802C poll frame in source replay or FCEUX trace")

    compared = []
    for frame in sorted(source_by_frame.keys() & fceux_by_frame.keys()):
        source = source_by_frame[frame]
        fceux = fceux_by_frame[frame]
        residual = int(source["cycle_from_frame_start"]) - int(fceux["cycle_from_frame_start"])
        compared.append({
            "source_frame": frame,
            "source_cycle_from_frame_start": int(source["cycle_from_frame_start"]),
            "fceux_cycle_from_frame_start": int(fceux["cycle_from_frame_start"]),
            "residual_source_minus_fceux": residual,
            "absolute_residual": abs(residual),
        })

    residuals = [row["residual_source_minus_fceux"] for row in compared]
    counts = Counter(residuals)
    buckets = []
    if compared:
        final_frame = max(row["source_frame"] for row in compared)
        for start in range(0, final_frame + 1, 500):
            group = [row for row in compared if start <= row["source_frame"] < start + 500]
            if group:
                buckets.append({
                    "frame_start_inclusive": start,
                    "frame_end_exclusive": start + 500,
                    "poll_count": len(group),
                    "exact_count": sum(row["residual_source_minus_fceux"] == 0 for row in group),
                    "within_3_cycles_count": sum(row["absolute_residual"] <= 3 for row in group),
                    "max_absolute_residual": max(row["absolute_residual"] for row in group),
                    "worst_frames": sorted(group, key=lambda row: (-row["absolute_residual"], row["source_frame"]))[:3],
                })

    worst = sorted(compared, key=lambda row: (-row["absolute_residual"], row["source_frame"]))[:20]
    summary = {
        "source_poll_count": len(source_rows),
        "fceux_poll_count": len(fceux_rows),
        "matched_frame_count": len(compared),
        "unmatched_source_frames": sorted(source_by_frame.keys() - fceux_by_frame.keys()),
        "unmatched_fceux_frames": sorted(fceux_by_frame.keys() - source_by_frame.keys()),
        "exact_count": sum(value == 0 for value in residuals),
        "within_1_cycle_count": sum(abs(value) <= 1 for value in residuals),
        "within_3_cycles_count": sum(abs(value) <= 3 for value in residuals),
        "within_3_cycles_fraction": (sum(abs(value) <= 3 for value in residuals) / len(residuals)) if residuals else None,
        "median_absolute_residual": sorted(abs(value) for value in residuals)[len(residuals) // 2] if residuals else None,
        "maximum_absolute_residual": max((abs(value) for value in residuals), default=None),
        "residual_histogram": {str(value): count for value, count in sorted(counts.items())},
        "frame_buckets_500": buckets,
        "worst_20_frames": worst,
    }
    return compared, summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--end-frame", type=int, default=4692, help="last source frame to execute (inclusive)")
    parser.add_argument("--fceux-trace-dir", type=Path, default=DEFAULT_FCEUX_TRACE)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if args.end_frame < 1:
        parser.error("--end-frame must be at least 1")

    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: expected {EXPECTED_ROM_SHA256}, got {rom_hash}")
    input_hash = sha256(INPUT_PATH.read_bytes())
    if input_hash != EXPECTED_INPUT_SHA256:
        raise SystemExit(f"input timeline identity mismatch: expected {EXPECTED_INPUT_SHA256}, got {input_hash}")

    stepper = import_stepper()
    inputs = stepper.load_input_timeline(INPUT_PATH)

    # Deliberate order: finish the complete ROM-only execution before opening
    # any FCEUX trace. Only the ROM and explicit per-frame controller inputs
    # influence the source poll events.
    source_rows = source_poll_events(stepper, rom, inputs, args.end_frame)

    fceux_rows, fceux_hashes = load_fceux_poll_events(args.fceux_trace_dir)
    compared, summary = compare(source_rows, fceux_rows)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    with (args.out_dir / "rom_source_poll_events.csv").open("w", newline="", encoding="utf-8") as stream:
        fields = tuple(source_rows[0].keys()) if source_rows else (
            "source_frame", "cycle_from_frame_start", "cycle_absolute", "instruction_cycle_start",
            "instruction_cycle_end", "instruction_cycle_delta", "instruction_pc", "next_pc",
        )
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(source_rows)
    with (args.out_dir / "poll_cycle_comparison.csv").open("w", newline="", encoding="utf-8") as stream:
        fields = tuple(compared[0].keys()) if compared else (
            "source_frame", "source_cycle_from_frame_start", "fceux_cycle_from_frame_start",
            "residual_source_minus_fceux", "absolute_residual",
        )
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(compared)

    report = {
        "purpose": "ROM-only Start poll cycle generation with post-run FCEUX validation",
        "scope": {"source_frames_executed_inclusive": [1, args.end_frame], "poll_pc": f"${POLL_PC:04X}"},
        "source_execution_inputs": {
            "rom_path": ROM_PATH.relative_to(ROOT).as_posix(),
            "rom_sha256": rom_hash,
            "controller_timeline_path": INPUT_PATH.relative_to(ROOT).as_posix(),
            "controller_timeline_sha256": input_hash,
            "source_stepper_path": STEPPER_PATH.relative_to(ROOT).as_posix(),
            "source_stepper_sha256": sha256(STEPPER_PATH.read_bytes()),
            "python_engine": "Py65 1.2.0, as required by the imported ROM-only stepper",
            "fceux_trace_read_during_execution": False,
            "fceux_cycles_used_as_execution_input": False,
        },
        "post_run_validation_reference": {
            "trace_directory": args.fceux_trace_dir.relative_to(ROOT).as_posix() if args.fceux_trace_dir.is_relative_to(ROOT) else str(args.fceux_trace_dir),
            **fceux_hashes,
            "semantics": "FCEUX registerexec hook cycle offsets are compared only after source replay completes; frame 4661 independently anchors the source instruction's post-instruction cycle convention.",
        },
        "comparison": summary,
        "limitations": [
            "This uses the existing partial CPU/PPU/DMC source stepper, not a complete NES hardware emulator.",
            "The stepper advances each modeled DMC ROM byte read by one CPU cycle and omits the 2A03's physical 3/4-cycle halt/alignment/get-put DMA arbitration; therefore the cycle schedule is not a proven physical-console schedule.",
            "The stepper's NTSC PPU/frame scheduler and register side effects are simplified. A small count of large poll-phase residuals must remain explicit; do not replace them with captured FCEUX timestamps in runtime.",
            "The controller timeline supplies the same per-frame inputs. It supplies no CPU-cycle or poll-phase values.",
            "The full comparison is validation, not a blind test: the source stepper has prior FCEUX-based development history. No FCEUX trace values are fitted or fed into this run.",
        ],
        "outputs": {
            "rom_source_poll_events_csv_sha256": sha256((args.out_dir / "rom_source_poll_events.csv").read_bytes()),
            "poll_cycle_comparison_csv_sha256": sha256((args.out_dir / "poll_cycle_comparison.csv").read_bytes()),
        },
    }
    (args.out_dir / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"out_dir": str(args.out_dir), "comparison": summary}, ensure_ascii=False))


if __name__ == "__main__":
    main()
