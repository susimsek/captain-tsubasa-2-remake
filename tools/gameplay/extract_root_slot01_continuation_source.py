#!/usr/bin/env python3
"""Preserve the fixed-bank slot-$01 caller loop following its first yield."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/root_task_continuation"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SPAN_FILE = "fixed_root_slot01_continuation_CA4D_CA5A.bin"
CPU_START = 0xCA4D
CPU_END_EXCLUSIVE = 0xCA5B
FILE_OFFSET = 0x03CA5D
EXPECTED_BYTES = bytes.fromhex("A9 01 20 0F CB 20 9F EE 20 CA E3 4C 4D CA")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
    source = rom[FILE_OFFSET : FILE_OFFSET + len(EXPECTED_BYTES)]
    if source != EXPECTED_BYTES or len(source) != CPU_END_EXCLUSIVE - CPU_START:
        raise SystemExit(
            f"Slot-$01 continuation bytes changed at file offset 0x{FILE_OFFSET:06X}: "
            f"{source.hex(' ').upper()}"
        )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / SPAN_FILE).write_bytes(source)
    manifest = {
        "schema": "root-slot01-continuation-v1",
        "rom_sha256": rom_hash,
        "mapping": "iNES PRG begins at file offset 0x0010; fixed bank CPU $C000-$FFFF maps to file 0x03C010+.",
        "spans": [
            {
                "file": SPAN_FILE,
                "cpu_address": f"0x{CPU_START:04X}",
                "cpu_end_exclusive": f"0x{CPU_END_EXCLUSIVE:04X}",
                "file_offset": f"0x{FILE_OFFSET:06X}",
                "length": len(source),
                "sha256": sha256(source),
                "bytes": source.hex(" ").upper(),
                "description": "fixed-bank slot-$01 continuation caller: LDA #$01 / JSR $CB0F, JSR $EE9F, JSR $E3CA, JMP $CA4D",
            }
        ],
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(source)} bytes at ${CPU_START:04X}-${CPU_END_EXCLUSIVE - 1:04X}")
    print(f"Source SHA-256: {sha256(source)}")


if __name__ == "__main__":
    main()
