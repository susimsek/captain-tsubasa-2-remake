#!/usr/bin/env python3
"""Export the ROM-stepper frame event for the F8 $00 helper return."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SCRIPT = ROOT / "reference/rom_extract/intro/cutscene_00.bin"
SCRIPT_F8_OFFSET = 0x27B
SCRIPT_BYTES = bytes.fromhex("F8 00 DF FE 20 A0")
STEPPER = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
DEFAULT_INPUT = ROOT / "reference/diagnostics/f8_return_source_trace_20261026"
DEFAULT_OUTPUT = ROOT / "assets/opening/rom_logic/f8_helper_return_event.json"

# These ordered PC edges prove the return from the F8 bank-2 service through
# the bank-0 wrapper and into the next script dispatch. Frames, not cycle
# offsets, are the runtime schedule signal.
REQUIRED_PC_EDGES = [
    ("$A53E", "$98A0", 3967, 2),
    ("$98DC", "$A541", 3967, 0),
    ("$A54F", "$98EA", 3967, 2),
    ("$895C", "$A557", 3968, 0),
    ("$A559", "$880A", 3968, 2),
    ("$880D", "$C4B9", 3968, 0),
    ("$8811", "$8879", 3968, 0),
    ("$8879", "$887A", 3968, 0),
    ("$84E7", "$84E9", 3968, 0),
    ("$8508", "$8509", 3968, 0),
    ("$8514", "$9FA8", 3968, 0),
    ("$9FA8", "$9FAA", 3968, 0),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stepper-dir", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    report_path = args.stepper_dir / "source_stepper_report.json"
    trace_path = args.stepper_dir / "source_cpu_instructions.csv"
    if sha256(ROM) != ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 does not match the pinned source.")
    if sha256(SCRIPT) != "499ccb62b8b2b9118d7ebfaa6e6b9fce46806cd3b9173b5e1d5d61de21c2a6b7":
        raise SystemExit("Extracted cutscene script hash does not match.")
    if SCRIPT.read_bytes()[SCRIPT_F8_OFFSET:SCRIPT_F8_OFFSET + len(SCRIPT_BYTES)] != SCRIPT_BYTES:
        raise SystemExit("F8/DF/FE script bytes differ from the expected ROM data.")

    report = json.loads(report_path.read_text(encoding="utf-8"))
    if report.get("source_rom_sha256") != ROM_SHA256:
        raise SystemExit("Stepper report targets a different ROM.")
    trace_report = report.get("source_cpu_instruction_trace", {})
    if trace_report.get("used_fceux_timestamps_or_pcm_as_scheduler_input") is not False:
        raise SystemExit("The source trace is not confirmed capture-independent.")
    if trace_report.get("path") != str(trace_path.relative_to(ROOT)):
        raise SystemExit("Stepper report points at a different instruction trace.")

    with trace_path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    cursor = -1
    events: list[dict[str, object]] = []
    for pc, next_pc, expected_frame, expected_bank in REQUIRED_PC_EDGES:
        match_index = next((i for i in range(cursor + 1, len(rows))
                            if rows[i]["instruction_pc"] == pc
                            and rows[i]["pc_after_instruction"] == next_pc), None)
        if match_index is None:
            raise SystemExit(f"Missing ordered source edge {pc}->{next_pc}.")
        row = rows[match_index]
        frame = int(row["source_frame"])
        bank = int(row["prg_bank_8k"])
        if frame != expected_frame or bank != expected_bank:
            raise SystemExit(
                f"Source edge {pc}->{next_pc} has frame/bank {frame}/{bank}, "
                f"expected {expected_frame}/{expected_bank}."
            )
        events.append({
            "kind": "cpu_pc_edge",
            "pc": pc,
            "next_pc": next_pc,
            "source_frame": frame,
            "prg_bank_8k": bank,
            "modeled_cycle": int(row["cycle_start"]),
        })
        cursor = match_index

    frame_events = [event for event in events if event["source_frame"] == 3968]
    if not frame_events or frame_events[-1]["pc"] != "$9FA8":
        raise SystemExit("The required frame-3968 helper/wait edge is not present.")

    payload = {
        "schema": "ct2-f8-helper-return-source-events-v1",
        "source_rom_sha256": ROM_SHA256,
        "cutscene_script_path": str(SCRIPT.relative_to(ROOT)),
        "cutscene_script_sha256": sha256(SCRIPT),
        "cutscene_f8_script_offset": f"0x{SCRIPT_F8_OFFSET:04X}",
        "cutscene_f8_script_bytes": SCRIPT_BYTES.hex(" ").upper(),
        "event_builder": str(Path(__file__).resolve().relative_to(ROOT)),
        "event_builder_sha256": sha256(Path(__file__).resolve()),
        "source_cpu_stepper": str(STEPPER.relative_to(ROOT)),
        "source_cpu_stepper_sha256": sha256(STEPPER),
        "stepper_report": str(report_path.relative_to(ROOT)),
        "stepper_report_sha256": sha256(report_path),
        "stepper_instruction_trace": str(trace_path.relative_to(ROOT)),
        "stepper_instruction_trace_sha256": sha256(trace_path),
        "input_timeline_path": report["input_timeline_path"],
        "input_timeline_sha256": report["input_timeline_sha256"],
        "service_completion_source_frame": 3967,
        "runtime_dispatch_frame": 3968,
        "runtime_consumes_cycle_offsets": False,
        "captured_frame_intervals_used": False,
        "captured_pixels_or_audio_used": False,
        "runtime_requires_rom_emulator_or_stepper_trace": False,
        "events": events,
        "limits": [
            "Event order and source-frame labels are generated from ROM-only CPU/PPU/DMC stepping; FCEUX timestamps, pixels, and PCM are not event-generation inputs.",
            "The runtime uses only the derived source-frame dispatch edge. The recorded per-PC modeled cycles are provenance and are not consumed by Godot.",
            "The stepper carries one CPU cycle per DMC read but does not model physical 2A03 3/4-cycle halt/get-put arbitration; title/helper per-PC cycle offsets are not independently validated against FCEUX per-PC cycles.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "output": str(args.output),
        "runtime_dispatch_frame": payload["runtime_dispatch_frame"],
        "ordered_pc_edges": len(events),
        "first_frame": events[0]["source_frame"],
        "last_frame": events[-1]["source_frame"],
    }, indent=2))


if __name__ == "__main__":
    main()
