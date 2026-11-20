#!/usr/bin/env python3
"""Preserve the two bank-$00 helpers called at the start of $A4EB."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUTPUT = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_a006"
PRG_OFFSET = 0x10
SPANS = (
    {
        "file": "bank00_match_pointer_pair_store_9B6F_9B74.bin",
        "cpu_start": 0x9B6F,
        "cpu_end_exclusive": 0x9B74,
        "file_offset": 0x1B7F,
        "role": "Store X/Y as the source pointer at $009E/$009F; RTS.",
    },
    {
        "file": "bank00_match_pointer_enable_flag_9B74_9B7F.bin",
        "cpu_start": 0x9B74,
        "cpu_end_exclusive": 0x9B7F,
        "file_offset": 0x1B84,
        "role": "Store X/Y at $00A0/$00A1 and set bit 7 in $009E; RTS.",
    },
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Input ROM does not match the pinned source revision.")
    if rom[:4] != b"NES\x1a" or len(rom) < PRG_OFFSET + 0x40000:
        raise SystemExit("Input is not the expected iNES image with 256 KiB PRG.")

    entries = []
    for spec in SPANS:
        start = int(spec["cpu_start"])
        end = int(spec["cpu_end_exclusive"])
        file_offset = int(spec["file_offset"])
        expected_offset = PRG_OFFSET + (start - 0x8000)
        if file_offset != expected_offset or end <= start:
            raise SystemExit(f"Invalid source mapping for {spec['file']}.")
        data = rom[file_offset : file_offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"Truncated source span for {spec['file']}.")
        (OUTPUT / str(spec["file"])).write_bytes(data)
        entries.append(
            {
                "file": spec["file"],
                "cpu_start": f"${start:04X}",
                "cpu_end_exclusive": f"${end:04X}",
                "file_offset": f"0x{file_offset:06X}",
                "length": len(data),
                "sha256": sha256(data),
                "bytes": data.hex(),
                "role": spec["role"],
            }
        )

    manifest = {
        "schema": "ct2-fresh-match-a4eb-prefix-v1",
        "rom": {"name": ROM_PATH.name, "sha256": ROM_SHA256},
        "mapping": "Bank $00 at CPU $8000-$9FFF maps file 0x000010 + (CPU-$8000).",
        "spans": entries,
    }
    (OUTPUT / "a4eb_prefix_helpers_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(entries)} source helpers from {ROM_PATH.name}.")
    for entry in entries:
        print(
            f"{entry['cpu_start']}-{entry['cpu_end_exclusive']}: "
            f"{entry['length']} bytes, SHA-256 {entry['sha256']}"
        )


if __name__ == "__main__":
    main()
