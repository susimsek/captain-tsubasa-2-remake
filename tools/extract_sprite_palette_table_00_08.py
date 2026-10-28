#!/usr/bin/env python3
"""Extract the ROM's sprite palette rows 00-08 and verify opening FB headers."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ROM_FILENAME = "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

PALETTE_TABLE_OFFSET = 0x00D310
PALETTE_TABLE_CPU_ADDRESS = 0xB300
PALETTE_COUNT = 9
PALETTE_BYTES = 16

INTRO_ANIMATION_HEADERS = (
    (0x6E, 0x0140D6),
    (0x75, 0x014196),
    (0xC1, 0x014767),
    (0x82, 0x01426F),
    (0x76, 0x01419F),
    (0x84, 0x0142DB),
    (0x77, 0x0141A9),
    (0xA2, 0x01451E),
    (0x7D, 0x0141DA),
    (0x7C, 0x0141D1),
)

REFERENCE_DIR = PROJECT_ROOT / "reference/rom_extract/intro"
PALETTE_BIN = REFERENCE_DIR / "sprite_palette_table_00_08.bin"
PALETTE_JSON = REFERENCE_DIR / "sprite_palette_table_00_08.json"
GAMEPLAY_PALETTE_BIN = REFERENCE_DIR / "sprite_palette_table_00_3F.bin"
GAMEPLAY_PALETTE_JSON = REFERENCE_DIR / "sprite_palette_table_00_3F.json"
ANIMATION_HEADERS_JSON = REFERENCE_DIR / "animation_palette_headers.json"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def hex_offset(value: int) -> str:
    return f"0x{value:06X}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--rom",
        type=Path,
        default=PROJECT_ROOT / ROM_FILENAME,
        help="Target Turkish ROM (defaults to the project root ROM).",
    )
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    rom_sha256 = sha256(rom)
    if rom_sha256 != ROM_SHA256:
        raise SystemExit(f"ROM SHA-256 mismatch: {rom_sha256}")

    table_size = PALETTE_COUNT * PALETTE_BYTES
    table = rom[PALETTE_TABLE_OFFSET : PALETTE_TABLE_OFFSET + table_size]
    if len(table) != table_size:
        raise SystemExit(f"Sprite palette table is truncated: {len(table)} bytes")

    animation_entries = []
    for animation_id, header_offset in INTRO_ANIMATION_HEADERS:
        source_path = REFERENCE_DIR / f"animation_{animation_id:02X}.bin"
        if not source_path.is_file():
            raise SystemExit(f"Missing extracted animation bytes: {source_path}")

        source_bytes = source_path.read_bytes()
        rom_record = rom[header_offset : header_offset + len(source_bytes)]
        if not source_bytes or source_bytes != rom_record:
            raise SystemExit(
                f"Extracted animation {animation_id:02X} does not match ROM at "
                f"{hex_offset(header_offset)}"
            )

        raw_first_byte = rom[header_offset]
        if source_bytes[0] != raw_first_byte:
            raise SystemExit(f"Animation {animation_id:02X} palette header mismatch")

        animation_entries.append(
            {
                "animation_id": f"0x{animation_id:02X}",
                "palette_index": raw_first_byte,
                "raw_first_byte": f"0x{raw_first_byte:02X}",
                "header_file_offset": hex_offset(header_offset),
                "source_bin": source_path.relative_to(PROJECT_ROOT).as_posix(),
                "source_sha256": sha256(source_bytes),
            }
        )

    palette_rows = []
    for palette_index in range(PALETTE_COUNT):
        start = palette_index * PALETTE_BYTES
        row = table[start : start + PALETTE_BYTES]
        palette_rows.append(
            {
                "palette_index": palette_index,
                "palette_id": f"0x{palette_index:02X}",
                "source_file_offset": hex_offset(PALETTE_TABLE_OFFSET + start),
                "table_byte_offset": start,
                "bytes_hex": row.hex(" "),
                "sha256": sha256(row),
            }
        )

    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    PALETTE_BIN.write_bytes(table)

    palette_metadata = {
        "schema": 1,
        "rom_file": ROM_FILENAME,
        "rom_sha256": ROM_SHA256,
        "resource_path": PALETTE_BIN.relative_to(PROJECT_ROOT).as_posix(),
        "resource_sha256": sha256(table),
        "source_file_offset": hex_offset(PALETTE_TABLE_OFFSET),
        "source_cpu_address": f"0x{PALETTE_TABLE_CPU_ADDRESS:04X}",
        "prg_bank": 6,
        "palette_index_base": 0,
        "palette_count": PALETTE_COUNT,
        "bytes_per_palette": PALETTE_BYTES,
        "source_bytes": table_size,
        "source_sha256": sha256(table),
        "conversion": "none; contiguous ROM bytes copied unchanged",
        "rows": palette_rows,
    }
    PALETTE_JSON.write_text(
        json.dumps(palette_metadata, indent=2) + "\n", encoding="utf-8"
    )

    gameplay_table = rom[PALETTE_TABLE_OFFSET : PALETTE_TABLE_OFFSET + 0x40 * PALETTE_BYTES]
    if len(gameplay_table) != 0x40 * PALETTE_BYTES:
        raise SystemExit("ROM sprite palette table 00-3F is truncated")
    gameplay_rows = []
    for palette_index in range(0x40):
        start = palette_index * PALETTE_BYTES
        row = gameplay_table[start : start + PALETTE_BYTES]
        gameplay_rows.append({
            "palette_index": palette_index,
            "source_file_offset": hex_offset(PALETTE_TABLE_OFFSET + start),
            "bytes_hex": row.hex(" "),
            "sha256": sha256(row),
        })
    GAMEPLAY_PALETTE_BIN.write_bytes(gameplay_table)
    GAMEPLAY_PALETTE_JSON.write_text(json.dumps({
        "schema": 1,
        "rom_file": ROM_FILENAME,
        "rom_sha256": ROM_SHA256,
        "resource_path": GAMEPLAY_PALETTE_BIN.relative_to(PROJECT_ROOT).as_posix(),
        "source_cpu_address": f"0x{PALETTE_TABLE_CPU_ADDRESS:04X}",
        "prg_bank": 6,
        "source_file_offset": hex_offset(PALETTE_TABLE_OFFSET),
        "palette_index_base": 0,
        "palette_count": 0x40,
        "bytes_per_palette": PALETTE_BYTES,
        "conversion": "none; exact contiguous ROM bytes copied unchanged",
        "rows": gameplay_rows,
    }, indent=2) + "\n", encoding="utf-8")

    animation_metadata = {
        "rom_sha256": ROM_SHA256,
        "entries": animation_entries,
    }
    ANIMATION_HEADERS_JSON.write_text(
        json.dumps(animation_metadata, indent=2) + "\n", encoding="utf-8"
    )

    print(f"Wrote {PALETTE_BIN.relative_to(PROJECT_ROOT)} ({table_size} ROM bytes)")
    print(f"Wrote {PALETTE_JSON.relative_to(PROJECT_ROOT)}")
    print(f"Wrote {GAMEPLAY_PALETTE_BIN.relative_to(PROJECT_ROOT)} (64 ROM palette rows)")
    print(f"Wrote {GAMEPLAY_PALETTE_JSON.relative_to(PROJECT_ROOT)}")
    print(f"Wrote {ANIMATION_HEADERS_JSON.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
