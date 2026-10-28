#!/usr/bin/env python3
"""Complete the block-$56 metatile tiles and selected page-2 attributes."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DATA_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field"
BLOCK_CANDIDATE_PATH = ROOT / "reference/rom_extract/gameplay/first_command_bg70_block56_rom_candidate.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
TILE_OFFSET = 0x024010 + 0x1A * 0x10
ATTRIBUTE_OFFSET = 0x017BF4 + 0x1A
ATTRIBUTE_PAGE_02_FILE_BASE = 0x017DF4
BLOCK_MAP_FILE_OFFSET = 0x017634
EXPECTED_BLOCK_MAP = bytes.fromhex(
	"15 16 15 15 1A 16 15 15 AD AD AD AD AD AD AD AD "
	"AE AE AE AE AE AE AE AE AF AF AF AF AF AF AF AF"
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 mismatch.")
    manifest_path = DATA_DIR / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("rom_sha256") != EXPECTED_ROM_SHA256:
        raise SystemExit("Field export manifest belongs to another ROM revision.")

    outputs = [
        ("metatile_1A_tiles.bin", TILE_OFFSET, 0x10, "bank 12 metatile tile IDs"),
        ("metatile_1A_attribute.bin", ATTRIBUTE_OFFSET, 1, "bank 0B page 0 attribute byte"),
    ]
    block_map = rom[BLOCK_MAP_FILE_OFFSET : BLOCK_MAP_FILE_OFFSET + len(EXPECTED_BLOCK_MAP)]
    if block_map != EXPECTED_BLOCK_MAP:
        raise SystemExit("Block-$56 map differs from the audited Turkish ROM bytes.")
    for metatile_id in sorted(set(block_map)):
        outputs.append((
            f"metatile_{metatile_id:02X}_attribute_page_02.bin",
            ATTRIBUTE_PAGE_02_FILE_BASE + metatile_id,
            1,
            "bank 0B page 2 attribute byte selected by $05CA=2",
        ))
    entries = manifest.setdefault("entries", [])
    by_path = {entry.get("path"): entry for entry in entries}
    for filename, offset, length, source in outputs:
        expected = rom[offset : offset + length]
        if len(expected) != length:
            raise SystemExit(f"ROM range for {filename} is truncated.")
        output_path = DATA_DIR / filename
        if output_path.exists() and output_path.read_bytes() != expected:
            raise SystemExit(f"Existing preserved bytes differ from the ROM: {filename}")
        output_path.write_bytes(expected)
        row = {
            "path": filename,
            "file_offset": f"0x{offset:06X}",
            "size_bytes": length,
            "sha256": sha256(expected),
            "raw_hex": " ".join(f"{byte:02X}" for byte in expected),
            "source": source,
        }
        if filename in by_path:
            if by_path[filename] != row:
                raise SystemExit(f"Existing manifest entry differs from ROM-derived metadata: {filename}")
        else:
            entries.append(row)

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    candidate = json.loads(BLOCK_CANDIDATE_PATH.read_text(encoding="utf-8"))
    if candidate.get("rom", {}).get("sha256") != EXPECTED_ROM_SHA256:
        raise SystemExit("Block-$56 candidate manifest belongs to another ROM revision.")
    decoded_block = candidate.get("decoded_block", {})
    if decoded_block.get("block_map_raw_hex", "").upper() != block_map.hex(" ").upper():
        raise SystemExit("Block-$56 candidate manifest map differs from the preserved ROM bytes.")
    metatile_rows = decoded_block.get("metatiles", [])
    if len(metatile_rows) != 4 or any(len(row) != 8 for row in metatile_rows):
        raise SystemExit("Block-$56 candidate manifest has an unexpected 4x8 metatile layout.")
    page_02_attributes = []
    for row_index, row in enumerate(metatile_rows):
        output_row = []
        for column_index, metatile in enumerate(row):
            metatile_id = int(metatile["tile_block_id"], 16)
            file_offset = ATTRIBUTE_PAGE_02_FILE_BASE + metatile_id
            value = rom[file_offset]
            metatile["attribute_file_offset"] = f"0x{file_offset:06X}"
            metatile["attribute_byte"] = f"0x{value:02X}"
            output_row.append(f"0x{value:02X}")
            if block_map[row_index * 8 + column_index] != metatile_id:
                raise SystemExit("Block-$56 metatile manifest ordering differs from the ROM map.")
        page_02_attributes.append(output_row)
    decoded_block["attribute_bytes_by_metatile_4x8"] = page_02_attributes
    source_decode = decoded_block.setdefault("source_decode", {})
    source_decode["attribute_cpu_base"] = "0x9DE4 (page selected by $05CA=2)"
    source_decode["attribute_file_base"] = f"0x{ATTRIBUTE_PAGE_02_FILE_BASE:06X}"
    source_decode["attribute_formula"] = f"file_offset = 0x{ATTRIBUTE_PAGE_02_FILE_BASE:06X} + tile_block_id"
    source_decode["attribute_selector_source"] = "bank-$0B $86D3 packs the block-$56 selector from table $8B42 into $05CA=2"
    decoded_block["attribute_table_layout"] = (
        "sub_85C2 reads $9BE4 + ($05CA << 8) + tile_block_id; "
        "block $56 selects $05CA=2, so its source table is $9DE4 / file 0x017DF4."
    )
    candidate["decoded_block"] = decoded_block
    BLOCK_CANDIDATE_PATH.write_text(json.dumps(candidate, indent=2) + "\n", encoding="utf-8")

    print("Added/verified block-$56 ROM source bytes:")
    for filename, offset, _, _ in outputs:
        print(f"  {filename}: ROM file 0x{offset:06X}")


if __name__ == "__main__":
    main()
