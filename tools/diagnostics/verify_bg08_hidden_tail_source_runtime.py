#!/usr/bin/env python3
"""Compare source-derived Godot OAM shadows with same-frame FCEUX RAM dumps."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT = PROJECT_ROOT / (
    "reference/diagnostics/bg08_hidden_tail_source_runtime_20261026/runtime_oam.json"
)
REFERENCE_RAM_ROOT = PROJECT_ROOT / "reference/opening_capture/ram_states"
OAM_SHADOW_START = 0x0468
OAM_SHADOW_END = 0x0568
HIDDEN_TAIL_SLOT = 5


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot-report", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()
    report = json.loads(args.godot_report.read_text())
    if report.get("rom_sha256") != "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097":
        raise SystemExit("Godot report ROM hash does not match the supplied Turkish ROM.")

    records = report.get("records", [])
    exact_frames = 0
    total_different_bytes = 0
    for record in records:
        source_frame = int(record["source_frame"])
        godot_path = args.godot_report.parent / str(record["shadow_path"])
        godot_oam = godot_path.read_bytes()
        ram_path = REFERENCE_RAM_ROOT / f"ram_{source_frame:05d}.bin"
        ram = ram_path.read_bytes()
        if len(godot_oam) != OAM_SHADOW_END - OAM_SHADOW_START:
            raise SystemExit(f"Unexpected Godot OAM length at frame {source_frame}.")
        if len(ram) < OAM_SHADOW_END:
            raise SystemExit(f"RAM dump is too short at frame {source_frame}.")
        source_oam = ram[OAM_SHADOW_START:OAM_SHADOW_END]
        differing = [i for i, (a, b) in enumerate(zip(godot_oam, source_oam)) if a != b]
        slot_offset = HIDDEN_TAIL_SLOT * 4
        slot_hex = godot_oam[slot_offset : slot_offset + 4].hex().upper()
        total_different_bytes += len(differing)
        if not differing:
            exact_frames += 1
        print(
            f"frame={source_frame} exact={not differing} "
            f"different_bytes={len(differing)} slot5={slot_hex}"
        )
        if differing:
            offsets = ",".join(f"${OAM_SHADOW_START + i:04X}" for i in differing[:12])
            print(f"  first_differences={offsets}")

    print(
        f"summary={exact_frames}/{len(records)} exact_frames "
        f"different_bytes={total_different_bytes}"
    )
    return 0 if exact_frames == len(records) else 1


if __name__ == "__main__":
    raise SystemExit(main())
