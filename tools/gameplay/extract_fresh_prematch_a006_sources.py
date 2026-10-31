#!/usr/bin/env python3
"""Package the supplied ROM's fresh pre-match `$A006` entry and body bytes."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_a006"

SPANS = [
    {
        "id": "a006_vector",
        "file": "bank01_prematch_setup_vector_A006_A009.bin",
        "cpu_start": "$A006",
        "cpu_end_exclusive": "$A009",
        "file_offset": "0x002016",
        "length": 3,
        "rom_offset": 0x2016,
        "bank_mapping": "PRG bank $01 at CPU $A000-$BFFF",
    },
    {
        "id": "a4eb_body",
        "file": "bank01_prematch_setup_body_A4EB_A610.bin",
        "cpu_start": "$A4EB",
        "cpu_end_exclusive": "$A611",
        "file_offset": "0x0024FB",
        "length": 0x126,
        "rom_offset": 0x24FB,
        "bank_mapping": "PRG bank $01 at CPU $A000-$BFFF",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    if not ROM_PATH.is_file():
        raise SystemExit(f"Supplied ROM not found: {ROM_PATH}")
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 differs from the audited Turkish revision")
    if rom[:4] != b"NES\x1a" or len(rom) < 16 + 0x40000:
        raise SystemExit("ROM header/layout is not the expected iNES PRG layout")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for span in SPANS:
        start = int(span["rom_offset"])
        data = rom[start : start + int(span["length"])]
        if len(data) != int(span["length"]):
            raise SystemExit(f"ROM span is truncated: {span['id']}")
        span["sha256"] = sha256(data)
        span["bytes"] = data.hex()
        (OUT_DIR / str(span["file"])).write_bytes(data)

    manifest = {
        "schema": "ct2-fresh-kickoff-a006-source-v1",
        "rom": {
            "name": ROM_PATH.name,
            "sha256": ROM_SHA256,
        },
        "mapping": "The iNES header is 16 bytes. PRG bank $01 is the second 8 KiB bank and maps to CPU $A000-$BFFF when selected in MMC3 register 7.",
        "scope": "Preserves the `$A006` bank-$01 vector and its complete `$A4EB-$A610` target body. The runtime entry executor only performs the verified JMP; the body has additional helpers and wait/scheduler behavior and is not yet implemented by that executor.",
        "spans": SPANS,
    }
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    for span in SPANS:
        print(f"{span['id']}: {span['cpu_start']}-{span['cpu_end_exclusive']} sha256={span['sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
