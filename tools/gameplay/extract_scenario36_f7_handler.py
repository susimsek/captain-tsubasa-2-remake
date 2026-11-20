#!/usr/bin/env python3
"""Preserve the ROM handler used by scenario-$36's live F7 command."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/scenario_continuation"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
FILE_OFFSET = 0x020805
CPU_START = 0x87F5
SOURCE_BYTES = bytes.fromhex("A4 3A E6 3A B1 5D 8D 2B 05 60")
FILENAME = "bank10_f7_handler_87f5_87ff.bin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Unexpected ROM SHA-256: {rom_hash}")
    extracted = rom[FILE_OFFSET:FILE_OFFSET + len(SOURCE_BYTES)]
    if extracted != SOURCE_BYTES:
        raise SystemExit("ROM bytes at bank-$10:$87F5 differ from the expected F7 handler")

    manifest = json.loads(MANIFEST_PATH.read_text())
    if manifest.get("schema") != "bank10-scenario-continuation-sources-v1" \
            or manifest.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
        raise SystemExit("Scenario-continuation manifest targets another ROM or schema")
    row = {
        "path": FILENAME,
        "size_bytes": len(extracted),
        "sha256": sha256(extracted),
        "prg_bank": "$10",
        "cpu_start": f"0x{CPU_START:04X}",
        "cpu_end_exclusive": f"0x{CPU_START + len(extracted):04X}",
        "file_offset": f"0x{FILE_OFFSET:06X}",
        "role": "Scenario opcode $F7 handler; advances $003A and writes the next stream byte to $052B",
    }
    entries = manifest.setdefault("entries", [])
    existing = next((entry for entry in entries if entry.get("path") == FILENAME), None)
    if existing is not None and existing != row:
        raise SystemExit("Existing F7 handler manifest row differs from the extracted source")
    if existing is None:
        entries.append(row)

    OUTPUT_DIR.joinpath(FILENAME).write_bytes(extracted)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {FILENAME}: bank $10:${CPU_START:04X}, file 0x{FILE_OFFSET:06X}, "
          f"SHA-256 {row['sha256']}")


if __name__ == "__main__":
    main()
