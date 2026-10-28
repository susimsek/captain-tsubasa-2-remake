#!/usr/bin/env python3
"""Export ROM-stepper timing facts for observed first-match BGM $55 events.

This is reference metadata only. It does not synthesize audio, read emulator
captures, or produce a runtime playback schedule.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
NTSC_CPU_HZ = 1_789_773
DEFAULT_MANIFEST = ROOT / "assets/gameplay/audio/match_track_55_rom_generated.json"
DEFAULT_OUTPUT = ROOT / "reference/rom_extract/gameplay/first_match_cue_timing_rom_stepper_20261027.json"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_hex(value: str) -> int:
    return int(value.strip().removeprefix("$").removeprefix("0x"), 16)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as source:
        return list(csv.DictReader(source))


def first_matching_write(
    rows: list[dict[str, str]], start_cycle: int, end_cycle: int, predicate: Any
) -> dict[str, str] | None:
    for row in rows:
        cycle = int(row["cycle"])
        if start_cycle < cycle < end_cycle and predicate(row):
            return row
    return None


def describe_write(row: dict[str, str], queue_cycle: int) -> dict[str, Any]:
    delta = int(row["cycle"]) - queue_cycle
    return {
        "source_frame": int(row["source_frame"]),
        "source_cycle": int(row["cycle"]),
        "pc": row["pc"],
        "address": row["address"],
        "value": row["value"],
        "cycles_after_queue_write": delta,
        "milliseconds_after_queue_write": round(delta * 1000 / NTSC_CPU_HZ, 6),
    }


def export_timing(
    stepper_report_path: Path,
    queue_csv_path: Path,
    apu_csv_path: Path,
    manifest_path: Path,
    output_path: Path,
) -> dict[str, Any]:
    report = json.loads(stepper_report_path.read_text(encoding="utf-8"))
    if report.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
        raise ValueError("Source-stepper report is for a different ROM revision.")
    if "no FCEUX trace used as scheduler input" not in str(report.get("purpose", "")):
        raise ValueError("Source-stepper report does not establish source-only event generation.")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
        raise ValueError("Cue manifest is for a different ROM revision.")
    if manifest.get("cue") != "0x55" or manifest.get("cue_kind") != "bgm":
        raise ValueError("Cue manifest does not describe BGM queue ID $55.")
    if not manifest.get("observed_route_queue"):
        raise ValueError("Cue manifest does not identify $55 as observed on this route.")
    if manifest.get("capture_used") or manifest.get("captured_pcm_used"):
        raise ValueError("Cue manifest must establish capture-free source rendering.")

    wav_path = ROOT / str(manifest["wav"])
    if sha256_file(wav_path) != manifest.get("wav_sha256"):
        raise ValueError("Cue WAV does not match its recorded manifest hash.")

    queue_rows = sorted(read_csv(queue_csv_path), key=lambda row: int(row["cycle"]))
    apu_rows = sorted(read_csv(apu_csv_path), key=lambda row: int(row["cycle"]))
    for row in queue_rows:
        if row["address"].upper() != "$0700":
            raise ValueError("Queue trace contains a row outside the sound queue address.")
    for row in apu_rows:
        if not row["address"].upper().startswith("$40"):
            raise ValueError("APU trace contains a row outside the APU register range.")

    occurrences: list[dict[str, Any]] = []
    for index, queue_row in enumerate(queue_rows):
        queue_id = parse_hex(queue_row["value"])
        if queue_id != 0x55:
            continue
        queue_cycle = int(queue_row["cycle"])
        next_queue_cycle = (
            int(queue_rows[index + 1]["cycle"])
            if index + 1 < len(queue_rows)
            else int(report["source_cpu_cycles"]) + 1
        )
        first_apu = first_matching_write(
            apu_rows,
            queue_cycle,
            next_queue_cycle,
            lambda row: True,
        )
        first_pulse1 = first_matching_write(
            apu_rows,
            queue_cycle,
            next_queue_cycle,
            lambda row: row["address"].upper() == "$4000",
        )
        if first_apu is None or first_pulse1 is None:
            raise ValueError(
                f"Could not find the following APU setup writes for queue event at cycle {queue_cycle}."
            )
        occurrences.append(
            {
                "queue_event": {
                    "source_frame": int(queue_row["source_frame"]),
                    "source_cycle": queue_cycle,
                    "pc_after_store": queue_row["pc"],
                    "queue_address": queue_row["address"],
                    "queue_id": "$55",
                },
                "next_queue_event_cycle_exclusive": next_queue_cycle,
                "first_apu_register_write": describe_write(first_apu, queue_cycle),
                "first_pulse1_register_write": describe_write(first_pulse1, queue_cycle),
            }
        )

    if len(occurrences) != 2:
        raise ValueError(f"Expected the two documented $55 route requests; found {len(occurrences)}.")

    output = {
        "schema": "ct2-first-match-cue-source-timing-v1",
        "purpose": "Reference-only source timing for ROM queue and APU events; not a runtime schedule or audible-onset claim.",
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "source_stepper_report_sha256": sha256_file(stepper_report_path),
        "source_input_timeline_sha256": report.get("input_timeline_sha256"),
        "source_frames_advanced": report.get("source_frames_advanced"),
        "source_cpu_cycles": report.get("source_cpu_cycles"),
        "source_event_inputs": {
            "sound_queue_csv_sha256": sha256_file(queue_csv_path),
            "apu_writes_csv_sha256": sha256_file(apu_csv_path),
            "cue_manifest_sha256": sha256_file(manifest_path),
            "cue_wav_sha256": manifest["wav_sha256"],
        },
        "cue_rom_source": {
            "queue_id": "$55",
            "runtime_pointer_table_file_offset": manifest["runtime_pointer_table_file_offset"],
            "runtime_pointer_cpu_address": manifest["runtime_pointer_cpu_address"],
            "sequence_file_offset": manifest["sequence_file_offset"],
            "sequence_prg_bank": manifest["sequence_prg_bank"],
        },
        "clock": {"ntsc_cpu_hz": NTSC_CPU_HZ},
        "capture_used_as_event_input": False,
        "captured_pcm_used": False,
        "runtime_consumes_this_file": False,
        "occurrences": occurrences,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stepper-report", type=Path, required=True)
    parser.add_argument("--queue-csv", type=Path, required=True)
    parser.add_argument("--apu-csv", type=Path, required=True)
    parser.add_argument("--cue-manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    result = export_timing(
        args.stepper_report,
        args.queue_csv,
        args.apu_csv,
        args.cue_manifest,
        args.output,
    )
    for occurrence in result["occurrences"]:
        event = occurrence["queue_event"]
        pulse1 = occurrence["first_pulse1_register_write"]
        print(
            f"$55 frame {event['source_frame']}: queue cycle {event['source_cycle']} → "
            f"$4000 frame {pulse1['source_frame']} cycle {pulse1['source_cycle']} "
            f"(+{pulse1['cycles_after_queue_write']} cycles, "
            f"{pulse1['milliseconds_after_queue_write']:.6f} ms)"
        )
    print(f"Wrote source-only timing reference: {args.output}")


if __name__ == "__main__":
    main()
