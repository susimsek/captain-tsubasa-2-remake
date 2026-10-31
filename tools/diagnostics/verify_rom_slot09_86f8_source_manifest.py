#!/usr/bin/env python3
"""Verify only the static ROM/source-span metadata for the $86F8 audit."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
PACKAGE = ROOT / "reference/rom_extract/gameplay/slot09_86f8_worker"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def bank_file_offset(cpu_start: int, bank: int) -> int:
    if 0x8000 <= cpu_start <= 0x9FFF:
        return 0x10 + bank * 0x2000 + (cpu_start - 0x8000)
    if 0xA000 <= cpu_start <= 0xBFFF:
        return 0x10 + bank * 0x2000 + (cpu_start - 0xA000)
    if 0xC000 <= cpu_start <= 0xDFFF:
        if bank != 0x1E:
            fail("fixed $C000-$DFFF source span must identify bank $1E")
        return 0x10 + bank * 0x2000 + (cpu_start - 0xC000)
    if 0xE000 <= cpu_start <= 0xFFFF:
        if bank != 0x1F:
            fail("fixed $E000-$FFFF source span must identify bank $1F")
        return 0x10 + bank * 0x2000 + (cpu_start - 0xE000)
    fail(f"unsupported CPU window at ${cpu_start:04X}")
    return -1


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha = hashlib.sha256(rom).hexdigest()
    if rom_sha != EXPECTED_ROM_SHA256:
        fail(f"ROM identity mismatch: {rom_sha}")
    manifest = json.loads((PACKAGE / "manifest.json").read_text())
    if manifest.get("schema") != "ct2-slot09-86f8-worker-source-v1":
        fail("unexpected manifest schema")
    if manifest.get("rom", {}).get("sha256") != EXPECTED_ROM_SHA256:
        fail("manifest ROM hash differs")

    spans = manifest.get("spans")
    if not isinstance(spans, list) or len(spans) != 4:
        fail("expected exactly four source spans")
    for span in spans:
        start = int(span["cpu_start"], 16)
        end = int(span["cpu_end_exclusive"], 16)
        bank = int(span["bank"], 16)
        file_offset = int(span["file_offset"], 16)
        length = int(span["length"])
        if end <= start or end - start != length:
            fail(f"invalid CPU length for {span['file']}")
        if bank_file_offset(start, bank) != file_offset:
            fail(f"CPU/bank/file-offset mapping mismatch for {span['file']}")
        source = rom[file_offset : file_offset + length]
        packaged = (PACKAGE / span["file"]).read_bytes()
        digest = hashlib.sha256(source).hexdigest()
        if len(source) != length or packaged != source or digest != span["sha256"]:
            fail(f"ROM bytes/hash mismatch for {span['file']}")
        if source.hex(" ") != span["bytes"].lower():
            fail(f"manifest byte list differs for {span['file']}")
    print("PASS: all four $86F8 audit spans match the identified ROM and bank mappings.")
    print("LIMIT: this verifies source metadata only; it does not execute 6502 code or prove route behavior.")


if __name__ == "__main__":
    main()
