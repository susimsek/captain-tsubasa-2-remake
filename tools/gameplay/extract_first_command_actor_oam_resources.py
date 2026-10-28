#!/usr/bin/env python3
"""Preserve the target ROM bytes required by the gameplay actor OAM decoder."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/actor_oam"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK16_FILE_BASE = 0x02C010  # Bank $16 CPU $8000.

SEGMENTS = [
    {
        "name": "sprite_engine_8000_8185",
        "filename": "bank16_sprite_engine_8000_8185.bin",
        "cpu_start": 0x8000,
        "length": 0x186,
        "purpose": "actor transform, compact stream interpreter, and descriptor dispatch",
    },
    {
        "name": "sprite_offsets_81d2_8239",
        "filename": "bank16_sprite_offsets_81d2_8239.bin",
        "cpu_start": 0x81D2,
        "length": 0x68,
        "purpose": "40-byte Y offset table followed by 64-byte X offset table",
    },
    {
        "name": "sprite_descriptor_pointers_8280_82af",
        "filename": "bank16_sprite_descriptor_pointers_8280_82af.bin",
        "cpu_start": 0x8280,
        "length": 0x30,
        "purpose": "24 descriptor stream pointers; first 12 are direct, following values follow source table layout",
    },
    {
        "name": "first_command_sprite_streams_842c_8979",
        "filename": "bank16_first_command_sprite_streams_842c_8979.bin",
        "cpu_start": 0x842C,
        "length": 0x54E,
        "purpose": "descriptor $00/$04/$0A stream roots, selector tables, jump targets, and compact OAM runs",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha256 = sha256(rom)
    if rom_sha256 != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Target ROM SHA-256 mismatch: {rom_sha256}")
    if len(rom) != 393232:
        raise SystemExit(f"Unexpected target ROM size: {len(rom)}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries = []
    for segment in SEGMENTS:
        cpu_start = int(segment["cpu_start"])
        offset = BANK16_FILE_BASE + cpu_start - 0x8000
        length = int(segment["length"])
        data = rom[offset : offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated bank-$16 resource at CPU ${cpu_start:04X}")
        output_path = OUTPUT_DIR / str(segment["filename"])
        output_path.write_bytes(data)
        entries.append({
            "name": segment["name"],
            "path": str(output_path.relative_to(ROOT)),
            "bank": "0x16",
            "cpu_start": f"0x{cpu_start:04X}",
            "file_offset": f"0x{offset:06X}",
            "length_bytes": length,
            "sha256": sha256(data),
            "purpose": segment["purpose"],
        })

    manifest = {
        "resource_kind": "preserved ROM source bytes for the gameplay actor OAM decoder",
        "source_rom_filename": ROM_PATH.name,
        "source_rom_sha256": rom_sha256,
        "bank_window_file_base": f"0x{BANK16_FILE_BASE:06X}",
        "runtime_rom_dependency": False,
        "capture_or_screenshot_bytes_included": False,
        "segments": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(entries)} target-ROM bank-$16 source spans under {OUTPUT_DIR.relative_to(ROOT)}")
    for entry in entries:
        print(f"${entry['cpu_start'][2:]}: {entry['length_bytes']} bytes sha256 {entry['sha256']}")


if __name__ == "__main__":
    main()
