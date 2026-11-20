#!/usr/bin/env python3
"""Preserve the ROM pointer and short stream used by slot-$09 value $82."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
MANIFEST_PATH = ROOT / "reference/rom_extract/gameplay/slot09_86f8_worker/manifest.json"
SOURCE_DIR = MANIFEST_PATH.parent
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
PRG_BANK_SIZE = 0x2000
HEADER_SIZE = 16
BANK = 0x19
SPANS = [
    {
        "file": "bank19_slot09_worker_pointer_entry_AD70.bin",
        "cpu_start": 0xAD70,
        "cpu_end_exclusive": 0xAD72,
        "file_offset": 0x032D80,
        "bytes_expected": bytes.fromhex("fc ad"),
        "description": "Bank-$19 pointer selected by live worker state $0532=$82; resolves to $ADFC.",
    },
    {
        "file": "bank19_slot09_worker_script82_ADFC_AE03.bin",
        "cpu_start": 0xADFC,
        "cpu_end_exclusive": 0xAE04,
        "file_offset": 0x032E0C,
        "bytes_expected": bytes.fromhex("33 0d 1a 0e 1a 0f 3a 32"),
        "description": "Eight-byte stream consumed by the live $82 worker branch: three $046F index/value writes followed by the source append call.",
    },
    {
        "file": "bank19_scenario36_worker_stream_AE03_AE0F.bin",
        "cpu_start": 0xAE03,
        "cpu_end_exclusive": 0xAE10,
        "file_offset": 0x032E13,
        "bytes_expected": bytes.fromhex("32 0e 3a 0f 1a 32 0d 3a 0e 1a 01 fc ad"),
        "description": "Scenario-$36 stream continuation: two timed two-pair batches at $AE03/$AE08, then selector $01 at $AE0D redirects to $ADFC.",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if len(rom) != 393232 or sha256(rom) != ROM_SHA256:
        raise SystemExit("The supplied target ROM identity does not match.")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("schema") != "ct2-slot09-86f8-worker-source-v1" \
            or manifest.get("rom", {}).get("sha256") != ROM_SHA256:
        raise SystemExit("The owning $86F8 manifest targets another ROM/schema.")

    rows = manifest.get("spans", [])
    for spec in SPANS:
        start = spec["cpu_start"]
        end = spec["cpu_end_exclusive"]
        offset = HEADER_SIZE + BANK * PRG_BANK_SIZE + start - 0xA000
        if offset != spec["file_offset"]:
            raise SystemExit(f"Bank/file mapping mismatch for {spec['file']}.")
        source = rom[offset : offset + end - start]
        if source != spec["bytes_expected"]:
            raise SystemExit(f"Unexpected source bytes for {spec['file']}.")
        (SOURCE_DIR / spec["file"]).write_bytes(source)
        row = next((item for item in rows if item.get("file") == spec["file"]), None)
        if row is None:
            row = {}
            rows.append(row)
        row.update({
            "file": spec["file"],
            "cpu_start": f"0x{start:04X}",
            "cpu_end_exclusive": f"0x{end:04X}",
            "bank": f"0x{BANK:02X}",
            "file_offset": f"0x{offset:06X}",
            "length": len(source),
            "sha256": sha256(source),
            "bytes": source.hex(" "),
            "description": spec["description"],
        })
        print(f"Preserved ${start:04X}-${end - 1:04X} ({len(source)} bytes) sha256 {sha256(source)}")

    manifest["spans"] = rows
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
