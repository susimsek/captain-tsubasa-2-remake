#!/usr/bin/env python3
"""Check the same-input FCEUX PC/RAM-write cycle trace for the F8 selectors."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"

EXPECTED_PC_EVENTS = [
    (3555, "$8B3F", 5725, 105845625, "$7C"),
    (3555, "$8B44", 5735, 105845635, "$7E"),
    (3597, "$8CA7", 6570, 107097251, "$7C"),
    (3597, "$8CAB", 6576, 107097257, "$7E"),
]
EXPECTED_RAM_WRITES = [
    (3555, "$0075", 5725, "$7C"),
    (3555, "$0076", 5735, "$7E"),
    (3597, "$008E", 6570, "$7C"),
    (3597, "$008F", 6576, "$7E"),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_metadata(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_dir", type=Path, help="FCEUX output directory containing events.csv and metadata.txt")
    args = parser.parse_args()
    trace_dir = args.trace_dir.resolve()

    assert sha256(ROM_PATH) == ROM_SHA256, "The local ROM does not match the checked revision."
    assert hashlib.md5(ROM_PATH.read_bytes()[16:]).hexdigest() == ROM_MD5, "The FCEUX PRG/CHR identity differs."
    assert sha256(INPUT_PATH) == INPUT_SHA256, "The local input timeline does not match the checked route."

    metadata = read_metadata(trace_dir / "metadata.txt")
    assert metadata.get("rom_md5") == ROM_MD5
    assert metadata.get("rom_sha256_expected") == ROM_SHA256
    assert metadata.get("input_timeline_expected_sha256") == INPUT_SHA256
    assert metadata.get("movie_stop", "").startswith("true"), "The configured startup movie was not stopped."
    assert metadata.get("done_frames") == "3598", "FCEUX did not finish the full 0–3597 source replay."

    with (trace_dir / "events.csv").open(newline="", encoding="utf-8") as handle:
        events = list(csv.DictReader(handle))

    measured_pc = []
    for frame, address, cycle, absolute, accumulator in EXPECTED_PC_EVENTS:
        matches = [row for row in events if row["event"] == "execute" and row["cpu_pc"] == address
                   and row["source_frame"] == str(frame)]
        assert len(matches) == 1, f"Expected exactly one {address} PC hook, found {len(matches)}."
        row = matches[0]
        observed = (int(row["source_frame"]), int(row["cycle_from_frame_start"]), int(row["cycle_absolute"]), row["a"])
        expected = (frame, cycle, absolute, accumulator)
        assert observed == expected, f"{address} mismatch: observed {observed}, expected {expected}."
        measured_pc.append({"source_frame": frame, "pc": address, "cycle_from_frame_start": cycle,
                            "cycle_absolute": absolute, "a": accumulator})

    measured_writes = []
    for frame, address, cycle, value in EXPECTED_RAM_WRITES:
        matches = [row for row in events if row["event"] == "write" and row["ram_address"] == address
                   and row["source_frame"] == str(frame)]
        assert len(matches) == 1, f"Expected exactly one write to {address} in frame {frame}, found {len(matches)}."
        row = matches[0]
        observed = (int(row["cycle_from_frame_start"]), row["ram_value"])
        expected = (cycle, value)
        assert observed == expected, f"{address} write mismatch: observed {observed}, expected {expected}."
        measured_writes.append({"source_frame": frame, "ram_address": address,
                                "cycle_from_frame_start": cycle, "value": value})

    report = {
        "result": "PASS",
        "fceux_version": "2.7.0",
        "rom_sha256": ROM_SHA256,
        "rom_md5": ROM_MD5,
        "input_timeline_sha256": INPUT_SHA256,
        "source_frame_range": [0, 3597],
        "audio": "disabled",
        "startup_movie_stopped": True,
        "pc_events": measured_pc,
        "ram_writes": measured_writes,
        "source_stepper_cycle_comparison": "all four PC hooks and corresponding RAM writes match",
    }
    output_path = trace_dir / "f8_selector_cycle_comparison.json"
    output_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: four F8 selector PC cycles and four RAM writes match the ROM-only schedule; report={output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
