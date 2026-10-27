#!/usr/bin/env python3
"""Export title events from the ROM-only source CPU stepper trace."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
STEPPER = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
DEFAULT_INPUT = ROOT / "reference/diagnostics/title_rom_stepper_handoff_poc_20261026"
DEFAULT_OUTPUT = ROOT / "assets/opening/rom_logic/title_handoff_source_events.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stepper-dir", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    report_path = args.stepper_dir / "source_stepper_report.json"
    trace_path = args.stepper_dir / "title_cpu_instructions.csv"
    if sha256(ROM) != ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 does not match.")
    report = json.loads(report_path.read_text(encoding="utf-8"))
    if report.get("source_rom_sha256") != ROM_SHA256:
        raise SystemExit("Stepper report has a different source ROM.")
    stop_rows = report.get("title_stop_markers", [])
    if len(stop_rows) != 1 or stop_rows[0].get("pc") != "$8048" or stop_rows[0].get("immediate_stop_value") != "$01":
        raise SystemExit("Expected one ROM Start stop at $8048 with value $01.")
    start_cycle = int(stop_rows[0]["cycle"])
    with trace_path.open(newline="", encoding="utf-8") as stream:
        rows = sorted(csv.DictReader(stream), key=lambda row: int(row["cycle_start"]))
    events: list[dict] = []

    def emit(kind: str, cycle: int, frame: int, pc: str, bank: int | None = None, **extra: object) -> None:
        events.append({"kind": kind, "cycle_offset": cycle - start_cycle,
                       "source_frame": frame, "pc": pc, "prg_bank_8k": bank, **extra})

    start_row = next((row for row in rows if row["instruction_pc"] == "$8048"
                      and row["prg_bank_8k"] == "0"), None)
    if start_row is None or int(start_row["cycle_start"]) != start_cycle:
        raise SystemExit("$8048 stepper instruction does not match the Stop marker.")
    emit("start_stop", start_cycle, int(start_row["source_frame"]), "$8048", 0, immediate="$01")

    loader = next((row for row in rows if row["instruction_pc"] == "$8AF7"
                   and row["prg_bank_8k"] == "0"
                   and int(row["cycle_start"]) > start_cycle), None)
    if loader is None:
        raise SystemExit("Missing post-Start ROM $8AF7 loader call.")
    loader_cycle = int(loader["cycle_start"])
    emit("title_background_loader_enter", loader_cycle,
         int(loader["source_frame"]), "$8AF7", 0, background_id="$17")

    # $9B3F BCS taken to $9B2E is the ROM queue-capacity overflow path.
    capacity_branch = False
    waits = 0
    resumes = 0
    for row in rows:
        cycle = int(row["cycle_start"])
        if cycle <= loader_cycle or row["prg_bank_8k"] != "0":
            continue
        pc = row["instruction_pc"]
        frame = int(row["source_frame"])
        if pc == "$9B3F":
            capacity_branch = row["pc_after_instruction"] == "$9B2E"
        elif pc == "$9B30":
            if not capacity_branch:
                raise SystemExit(f"$9B30 at cycle {cycle} lacks the taken $9B3F capacity branch.")
            emit("queue_capacity_wait", cycle, frame, pc, 0, resume_pc="$9B33", queue_limit="$3D")
            waits += 1
            capacity_branch = False
        elif pc == "$9B33":
            emit("queue_capacity_resume", cycle, frame, pc, 0, scheduler_return="$9FA8")
            resumes += 1
    if waits != 27 or resumes != 27:
        raise SystemExit(f"Expected 27 verified queue waits/resumes; got {waits}/{resumes}.")

    setup = next((row for row in rows if row["instruction_pc"] == "$807A"
                  and row["prg_bank_8k"] == "0"
                  and int(row["cycle_start"]) > loader_cycle), None)
    if setup is None:
        raise SystemExit("Missing ROM title palette/cursor setup at $807A.")
    emit("title_palette_cursor_setup", int(setup["cycle_start"]),
         int(setup["source_frame"]), "$807A", 0)

    consumers = [row for row in rows if row["instruction_pc"] == "$A029"
                 and int(row["cycle_start"]) > loader_cycle]
    if len(consumers) != 242:
        raise SystemExit(f"Expected 240 background plus two palette/cursor consumers; got {len(consumers)}.")
    for ordinal, row in enumerate(consumers):
        emit("queue_consumer_packet", int(row["cycle_start"]),
             int(row["source_frame"]), "$A029", int(row["prg_bank_8k"]),
             ordinal=ordinal)

    interrupt_rows = report.get("source_cpu_instruction_trace", {}).get(
        "source_cpu_interrupt_accepts_in_window", [])
    nmis = [row for row in interrupt_rows
            if row.get("kind") == "NMI" and int(row["cycle"]) > start_cycle]
    if len(nmis) != 31:
        raise SystemExit(f"Expected 31 post-Start NMI accepts; got {len(nmis)}.")
    for row in nmis:
        emit("nmi_accept", int(row["cycle"]), int(row["source_frame"]),
             str(row["pc_before"]))

    events.sort(key=lambda event: int(event["cycle_offset"]))
    counts = {kind: sum(event["kind"] == kind for event in events)
              for kind in sorted({event["kind"] for event in events})}
    payload = {
        "schema": "ct2-title-handoff-rom-stepper-events-v1",
        "source_rom_sha256": ROM_SHA256,
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
        "captured_frame_intervals_used": False,
        "captured_pixels_or_audio_used": False,
        "runtime_requires_rom_emulator_or_stepper_trace": False,
        "start_anchor": {"pc": "$8048", "cycle": start_cycle,
                         "source_frame": int(start_row["source_frame"])},
        "event_counts": counts,
        "events": events,
        "limits": [
            "Events come from ROM-only 6502/PPU/DMC execution with the recorded cold-start input route.",
            "FCEUX is post-run validation only; no capture timing, pixels, or PCM are event-generation inputs.",
            "The stepper carries one CPU cycle per DMC read and reproduces the aggregate FCEUX APU-write cycle count (45,452/45,452); DMC timestamp counts differ by one (104,105/104,106), with one +3-cycle residual. It does not model physical 2A03 halt/get-put arbitration or full 3/4-cycle stalls, and title per-PC cycles are not independently matched to FCEUX per-PC timestamps.",
            "Cycle values do not establish physical 2C02 output-dot timing or live input-poll phase.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "event_counts": counts,
                      "max_cycle_offset": max(int(event["cycle_offset"]) for event in events)},
                     indent=2))


if __name__ == "__main__":
    main()
