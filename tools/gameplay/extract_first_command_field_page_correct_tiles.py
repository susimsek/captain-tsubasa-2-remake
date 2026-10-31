#!/usr/bin/env python3
"""Preserve selector-correct ROM metatiles for field maps $36, $42, and $56."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/page_correct_map_sources"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SELECTOR_TABLE_OFFSET = 0x016B52  # bank-$0B CPU $8B42
SELECTOR_TABLE_SIZE = 0x22
BLOCK_MAP_TABLE_OFFSET = 0x016B74  # bank-$0B CPU $8B64
ATTRIBUTE_TABLE_OFFSET = 0x017BF4  # bank-$0B CPU $9BE4
TILE_DATA_BASE_OFFSET = 0x024010  # bank-$12 CPU $A000

MAPS = {
    0x36: {
        "selector": 0x01,
        "animation_id": 0x45,
        "animation_record_offset": 0x016A3A,
        "expected_record_hex": "06 00 36",
        "expected_map_hex": (
            "2B 2B 2B 2B EE 2B 2B 2B "
            "2D 2E 2E 2E EF 2E 2E 2E "
            "30 30 30 30 30 30 30 30 "
            "31 31 31 31 31 31 31 31"
        ),
    },
    0x56: {
        "selector": 0x02,
        "animation_id": 0x70,
        "animation_record_offset": 0x016B48,
        "expected_record_hex": "06 00 56",
        "expected_map_hex": (
            "15 16 15 15 1A 16 15 15 "
            "AD AD AD AD AD AD AD AD "
            "AE AE AE AE AE AE AE AE "
            "AF AF AF AF AF AF AF AF"
        ),
    },
    0x42: {
        "selector": 0x01,
        "expected_map_hex": (
            "14 14 14 14 14 14 14 14 "
            "33 33 33 33 33 33 33 33 "
            "15 16 15 EA EB 16 15 16 "
            "14 14 14 14 14 14 14 14"
        ),
    },
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def decode_selector(selector_table: bytes, block_id: int) -> int:
    packed = selector_table[block_id >> 2]
    return (packed >> (2 * (block_id & 0x03))) & 0x03


def write_preserved(path: Path, data: bytes) -> None:
    if path.exists() and path.read_bytes() != data:
        raise SystemExit(f"Preserved source differs from supplied ROM: {path}")
    path.write_bytes(data)


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")

    selector_table = rom[SELECTOR_TABLE_OFFSET : SELECTOR_TABLE_OFFSET + SELECTOR_TABLE_SIZE]
    if len(selector_table) != SELECTOR_TABLE_SIZE:
        raise SystemExit("Selector table range is truncated.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, object]] = []

    selector_filename = "packed_map_selectors_8B42.bin"
    write_preserved(OUTPUT_DIR / selector_filename, selector_table)
    entries.append({
        "path": selector_filename,
        "file_offset": f"0x{SELECTOR_TABLE_OFFSET:06X}",
        "cpu_address": "0x8B42",
        "prg_bank": "0x0B",
        "size_bytes": len(selector_table),
        "sha256": sha256(selector_table),
        "source": "packed 2-bit map selectors read by bank-$0B $86D3",
    })

    for map_id, metadata in MAPS.items():
        map_offset = BLOCK_MAP_TABLE_OFFSET + map_id * 0x20
        block_map = rom[map_offset : map_offset + 0x20]
        expected_map = bytes.fromhex(str(metadata["expected_map_hex"]))
        selected = decode_selector(selector_table, map_id)
        if selected != int(metadata["selector"]):
            raise SystemExit(f"Map ${map_id:02X} selector changed: ${selected:02X}")
        if block_map != expected_map:
            raise SystemExit(f"Map ${map_id:02X} bytes differ from the audited target ROM.")
        if "animation_id" in metadata:
            record_offset = int(metadata["animation_record_offset"])
            animation_record = rom[record_offset : record_offset + 3]
            expected_record = bytes.fromhex(str(metadata["expected_record_hex"]))
            if animation_record != expected_record:
                raise SystemExit(f"Animation ${int(metadata['animation_id']):02X} record changed.")

            animation_filename = f"background_animation_{int(metadata['animation_id']):02X}_record.bin"
            write_preserved(OUTPUT_DIR / animation_filename, animation_record)
            entries.append({
                "path": animation_filename,
                "file_offset": f"0x{record_offset:06X}",
                "cpu_address": f"0x{0x8000 + (record_offset - 0x016010):04X}",
                "prg_bank": "0x0B",
                "size_bytes": len(animation_record),
                "sha256": sha256(animation_record),
                "animation_id": f"0x{int(metadata['animation_id']):02X}",
                "block_map_id": f"0x{map_id:02X}",
                "selector": f"0x{selected:02X}",
                "raw_hex": animation_record.hex(" ").upper(),
                "source": "background-animation record: wait, opcode $00, metatile-map ID",
            })

        map_filename = f"block_map_{map_id:02X}_selector_{selected:02X}.bin"
        write_preserved(OUTPUT_DIR / map_filename, block_map)
        entries.append({
            "path": map_filename,
            "file_offset": f"0x{map_offset:06X}",
            "cpu_address": f"0x{0x8000 + (map_offset - 0x016010):04X}",
            "prg_bank": "0x0B",
            "size_bytes": len(block_map),
            "sha256": sha256(block_map),
            "block_map_id": f"0x{map_id:02X}",
            "selector": f"0x{selected:02X}",
            "source": "8x4 metatile map selected by bank-$0B $8525 or callback map ID",
        })

        for metatile_id in sorted(set(block_map)):
            # $85C2 forms offset=(selector<<12)+(metatile_id<<4).  The
            # contiguous bank-$12/$13 file range permits this linear offset;
            # the CPU-visible bank/address split is recorded separately.
            tile_offset_in_window = (selected << 12) + (metatile_id << 4)
            tile_bank = 0x12 + (tile_offset_in_window >> 13)
            tile_cpu = 0xA000 + (tile_offset_in_window & 0x1FFF)
            tile_file_offset = TILE_DATA_BASE_OFFSET + tile_offset_in_window
            tile_bytes = rom[tile_file_offset : tile_file_offset + 0x10]
            if len(tile_bytes) != 0x10:
                raise SystemExit(f"Tile block ${metatile_id:02X} range is truncated.")
            tile_filename = f"map_{map_id:02X}_metatile_{metatile_id:02X}_tiles.bin"
            write_preserved(OUTPUT_DIR / tile_filename, tile_bytes)
            entries.append({
                "path": tile_filename,
                "file_offset": f"0x{tile_file_offset:06X}",
                "cpu_address": f"0x{tile_cpu:04X}",
                "prg_bank": f"0x{tile_bank:02X}",
                "size_bytes": len(tile_bytes),
                "sha256": sha256(tile_bytes),
                "metatile_id": f"0x{metatile_id:02X}",
                "block_map_id": f"0x{map_id:02X}",
                "selector": f"0x{selected:02X}",
                "source": "selector-derived 4x4 tile-ID record consumed by bank-$0B $85C2",
            })

            attribute_offset = ATTRIBUTE_TABLE_OFFSET + (selected << 8) + metatile_id
            attribute = rom[attribute_offset : attribute_offset + 1]
            attribute_filename = f"map_{map_id:02X}_metatile_{metatile_id:02X}_attribute.bin"
            write_preserved(OUTPUT_DIR / attribute_filename, attribute)
            entries.append({
                "path": attribute_filename,
                "file_offset": f"0x{attribute_offset:06X}",
                "cpu_address": f"0x{0x9BE4 + (selected << 8) + metatile_id:04X}",
                "prg_bank": "0x0B",
                "size_bytes": len(attribute),
                "sha256": sha256(attribute),
                "metatile_id": f"0x{metatile_id:02X}",
                "block_map_id": f"0x{map_id:02X}",
                "selector": f"0x{selected:02X}",
                "source": "selector-derived attribute byte read by bank-$0B $85C2",
            })

    manifest = {
        "schema": "first-command-page-correct-field-map-sources-v1",
        "resource_kind": "ROM-derived source bytes; no emulator capture data",
        "rom_filename": ROM_PATH.name,
        "rom_sha256": rom_hash,
        "source_mapping": {
            "bank_0B_file_base": "0x016010",
            "bank_0B_cpu_base": "0x8000",
            "bank_12_file_base": "0x024010",
            "bank_12_cpu_base": "0xA000",
            "bank_13_file_base": "0x026010",
            "bank_13_cpu_base": "0xA000",
            "selector_table_cpu": "0x8B42",
            "block_map_table_cpu": "0x8B64",
            "selector_formula": "selector=(table[map_id>>2]>>(2*(map_id&3)))&3",
            "tile_record_formula": "window_offset=(selector<<12)+(metatile_id<<4); bank=0x12+(window_offset>>13); cpu=0xA000+(window_offset&0x1FFF); file=0x024010+window_offset",
            "attribute_formula": "file=0x017BF4+(selector<<8)+metatile_id",
            "map_36": "background animation $45 record at bank-$0B $8A2A; selector $01",
            "map_56": "background animation $70 record at bank-$0B $8B38; selector $02",
            "map_42": "callback event $3A supplies map ID $42 to bank-$0B $8525; selector $01",
        },
        "entries": entries,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote selector-correct field-map source manifest: {MANIFEST_PATH}")
    print(f"Preserved {len(entries)} source records from the verified ROM.")


if __name__ == "__main__":
    main()
