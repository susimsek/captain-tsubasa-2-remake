#!/usr/bin/env python3
"""Extract ROM spans selected by slot-$11 animation index $01."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST = OUT / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# (name, CPU start, PRG file offset, length, description)
SPANS = [
    (
        "bank1b_actor_animation_stream_01_A2CB_A2E7.bin",
        0xA2CB,
        0x0362DB,
        29,
        "Animation-index $01 command/index pairs and its active-worker $FF self-loop.",
    ),
    (
        "bank1b_actor_animation_packet_pointer_table_A42A_A433.bin",
        0xA42A,
        0x03643A,
        10,
        "Five little-endian PPU packet pointers consumed by the $A21A animation command parser.",
    ),
    (
        "bank1b_actor_animation_packets_04_A49E_A4C2.bin",
        0xA49E,
        0x0364AE,
        37,
        "ROM packet row 4, bounded by the next pointer at $A4C3; contains six PPU write packets and a zero terminator.",
    ),
]

REPLACED_FILES = {
    "bank1b_actor_animation_packet_pointer_table_A42A_A431.bin",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Target ROM SHA-256 mismatch.")
    if rom[0x0362DB : 0x0362DB + 29] != bytes.fromhex(
        "05 04 05 01 05 02 05 01 05 02 05 03 05 02 05 01 05 02 05 03 05 02 05 01 05 04 FF CB A2"
    ):
        raise SystemExit("Animation-index $01 command stream differs from the audited ROM bytes.")
    if rom[0x03643A : 0x03643A + 10] != bytes.fromhex(
        "6A A4 8F A4 94 A4 99 A4 9E A4"
    ):
        raise SystemExit("Animation PPU packet pointer rows differ from the audited ROM bytes.")
    if rom[0x0364AE : 0x0364AE + 37][-1] != 0:
        raise SystemExit("Animation PPU packet row 4 lost its zero terminator.")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("rom_sha256") != ROM_SHA256:
        raise SystemExit("Slot-$11 manifest targets another ROM revision.")

    entries = []
    for name, cpu_address, file_offset, length, description in SPANS:
        data = rom[file_offset : file_offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated ROM span: {name}")
        (OUT / name).write_bytes(data)
        entries.append(
            {
                "file": name,
                "bank": "bank1b",
                "cpu_address": f"0x{cpu_address:04X}",
                "file_offset": f"0x{file_offset:06X}",
                "length": length,
                "sha256": sha256(data),
                "description": description,
                "bytes": data.hex(" ").upper(),
            }
        )

    spans = [
        span
        for span in manifest.get("spans", [])
        if span.get("file") not in REPLACED_FILES
        and span.get("file") not in {entry["file"] for entry in entries}
    ]
    manifest["spans"] = spans + entries
    MANIFEST.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    for old_name in REPLACED_FILES:
        old_path = OUT / old_name
        if old_path.exists():
            old_path.unlink()
    print(f"Extracted {len(entries)} ROM source spans for animation index $01.")


if __name__ == "__main__":
    main()
