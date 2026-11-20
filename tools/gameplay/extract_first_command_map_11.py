#!/usr/bin/env python3
"""Extract the ROM-verified first-command field map-$11 resource bundle."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/map_11"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_MAP_ID = 0x11
EXPECTED_SELECTOR = 0x00
EXPECTED_SELECTOR_PROOF_BYTE = 0x00
EXPECTED_BLOCK_MAP = bytes.fromhex(
    "15 16 15 16 15 16 15 16 "
    "19 1A 19 1A 19 30 1C 1A "
    "14 14 14 14 14 14 14 14 "
    "13 13 13 13 13 13 13 13"
)
EXPECTED_CHR_PAIR = bytes.fromhex("3C 4A")
EXPECTED_SELECTOR_LOGIC = bytes.fromhex(
    "48 29 03 AA 68 48 4A 4A A8 B9 42 8B CA 30 05 4A "
    "4A 4C DF 86 29 03 8D CA 05 68 60"
)

SELECTOR_LOGIC_OFFSET = 0x0166E3  # bank-$0B CPU $86D3
SELECTOR_TABLE_OFFSET = 0x016B52  # bank-$0B CPU $8B42
BLOCK_MAP_TABLE_OFFSET = 0x016B74  # bank-$0B CPU $8B64
CHR_PAIR_TABLE_OFFSET = 0x0166FE  # bank-$0B CPU $86EE
ATTRIBUTE_TABLE_OFFSET = 0x017BF4  # bank-$0B CPU $9BE4
TILE_DATA_BASE_OFFSET = 0x024010  # bank-$12 CPU $A000


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def checked_rom() -> bytes:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
    if len(rom) != 0x60010 or rom[:4] != b"NES\x1a":
        raise SystemExit("The hash-matched source is not the expected iNES ROM layout.")
    header = rom[:16]
    mapper = (header[6] >> 4) | (header[7] & 0xF0)
    prg_size = header[4] * 0x4000
    chr_size = header[5] * 0x2000
    if mapper != 4 or prg_size != 0x40000 or chr_size != 0x20000 or header[6] & 0x04:
        raise SystemExit("ROM header no longer matches mapper-$04 PRG/CHR bank layout.")
    return rom


def checked_slice(rom: bytes, offset: int, length: int, label: str) -> bytes:
    result = rom[offset : offset + length]
    if len(result) != length:
        raise SystemExit(f"{label} source range is truncated at 0x{offset:06X}.")
    return result


def write_preserved(path: Path, data: bytes) -> None:
    if path.exists() and path.read_bytes() != data:
        raise SystemExit(f"Preserved source differs from the hash-matched ROM: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def prg_entry(
    *,
    path: str,
    data: bytes,
    file_offset: int,
    cpu_address: int,
    prg_bank: int,
    source: str,
    **extra: object,
) -> dict[str, object]:
    return {
        "path": path,
        "file_offset": f"0x{file_offset:06X}",
        "cpu_address": f"0x{cpu_address:04X}",
        "prg_bank": f"0x{prg_bank:02X}",
        "size_bytes": len(data),
        "sha256": sha256(data),
        "raw_hex": data.hex(" ").upper(),
        "source": source,
        **extra,
    }


def main() -> None:
    rom = checked_rom()
    selector_logic = checked_slice(rom, SELECTOR_LOGIC_OFFSET, len(EXPECTED_SELECTOR_LOGIC), "Selector logic")
    selector_table_index = EXPECTED_MAP_ID >> 2
    selector_proof_offset = SELECTOR_TABLE_OFFSET + selector_table_index
    selector_proof = checked_slice(rom, selector_proof_offset, 1, "Map-$11 selector proof")
    selector_shift = 2 * (EXPECTED_MAP_ID & 0x03)
    selector = (selector_proof[0] >> selector_shift) & 0x03
    if selector_logic != EXPECTED_SELECTOR_LOGIC:
        raise SystemExit("Bank-$0B selector routine $86D3 differs from the pinned ROM bytes.")
    if selector_proof[0] != EXPECTED_SELECTOR_PROOF_BYTE or selector != EXPECTED_SELECTOR:
        raise SystemExit(f"Map-$11 selector changed: packed=${selector_proof[0]:02X}, selector=${selector:02X}.")

    block_file_offset = BLOCK_MAP_TABLE_OFFSET + EXPECTED_MAP_ID * 0x20
    block_map = checked_slice(rom, block_file_offset, 0x20, "Map-$11 block map")
    if block_map != EXPECTED_BLOCK_MAP:
        raise SystemExit("Map-$11 32-byte block map differs from the audited ROM source.")

    chr_file_offset = CHR_PAIR_TABLE_OFFSET + EXPECTED_MAP_ID * 2
    chr_pair = checked_slice(rom, chr_file_offset, 2, "Map-$11 CHR pair")
    if chr_pair != EXPECTED_CHR_PAIR:
        raise SystemExit(f"Map-$11 CHR pair changed: {chr_pair.hex(' ').upper()}.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, object]] = []

    selector_logic_name = "selector_logic_86d3.bin"
    write_preserved(OUTPUT_DIR / selector_logic_name, selector_logic)
    entries.append(prg_entry(
        path=selector_logic_name,
        data=selector_logic,
        file_offset=SELECTOR_LOGIC_OFFSET,
        cpu_address=0x86D3,
        prg_bank=0x0B,
        source="Bank-$0B selector routine: reads the packed selector table at $8B42 and stores the selected 2-bit value at $05CA.",
    ))

    selector_name = "selector_proof.bin"
    write_preserved(OUTPUT_DIR / selector_name, selector_proof)
    entries.append(prg_entry(
        path=selector_name,
        data=selector_proof,
        file_offset=selector_proof_offset,
        cpu_address=0x8B42 + selector_table_index,
        prg_bank=0x0B,
        source="Packed selector table byte addressed by map ID $11 >> 2; selector=(byte >> (2*(map_id&3))) & 3.",
        map_id="0x11",
        table_index=selector_table_index,
        selector_shift=selector_shift,
        resolved_selector=f"0x{selector:02X}",
    ))

    block_name = "block_map_11_selector_00.bin"
    write_preserved(OUTPUT_DIR / block_name, block_map)
    entries.append(prg_entry(
        path=block_name,
        data=block_map,
        file_offset=block_file_offset,
        cpu_address=0x8B64 + EXPECTED_MAP_ID * 0x20,
        prg_bank=0x0B,
        source="8x4 metatile-ID block map selected by the ROM's map-$11 branch.",
        map_id="0x11",
        selector="0x00",
        dimensions_blocks="8x4",
    ))

    chr_name = "chr_pair_11.bin"
    write_preserved(OUTPUT_DIR / chr_name, chr_pair)
    entries.append(prg_entry(
        path=chr_name,
        data=chr_pair,
        file_offset=chr_file_offset,
        cpu_address=0x86EE + EXPECTED_MAP_ID * 2,
        prg_bank=0x0B,
        source="The map-$11 CHR selector pair read by the bank-$0B map worker.",
        map_id="0x11",
        chr_pair_hex="3C 4A",
    ))

    metatile_ids = sorted(set(block_map))
    for metatile_id in metatile_ids:
        tile_window_offset = (selector << 12) + (metatile_id << 4)
        tile_file_offset = TILE_DATA_BASE_OFFSET + tile_window_offset
        tile_bank = 0x12 + (tile_window_offset >> 13)
        tile_cpu_address = 0xA000 + (tile_window_offset & 0x1FFF)
        tile_bytes = checked_slice(rom, tile_file_offset, 0x10, f"Metatile ${metatile_id:02X} tile IDs")
        tile_name = f"metatile_{metatile_id:02X}_tiles.bin"
        write_preserved(OUTPUT_DIR / tile_name, tile_bytes)
        entries.append(prg_entry(
            path=tile_name,
            data=tile_bytes,
            file_offset=tile_file_offset,
            cpu_address=tile_cpu_address,
            prg_bank=tile_bank,
            source="Selector-derived 4x4 tile-ID record referenced by the map-$11 block map.",
            map_id="0x11",
            selector=f"0x{selector:02X}",
            metatile_id=f"0x{metatile_id:02X}",
        ))

        attribute_file_offset = ATTRIBUTE_TABLE_OFFSET + (selector << 8) + metatile_id
        attribute_cpu_address = 0x9BE4 + (selector << 8) + metatile_id
        attribute = checked_slice(rom, attribute_file_offset, 1, f"Metatile ${metatile_id:02X} attribute")
        attribute_name = f"metatile_{metatile_id:02X}_attribute.bin"
        write_preserved(OUTPUT_DIR / attribute_name, attribute)
        entries.append(prg_entry(
            path=attribute_name,
            data=attribute,
            file_offset=attribute_file_offset,
            cpu_address=attribute_cpu_address,
            prg_bank=0x0B,
            source="Selector-derived attribute byte referenced by the map-$11 block map.",
            map_id="0x11",
            selector=f"0x{selector:02X}",
            metatile_id=f"0x{metatile_id:02X}",
        ))

    manifest = {
        "schema": "ct2-first-command-map-11-rom-sources-v1",
        "resource_kind": "ROM-derived source bytes; no emulator capture data",
        "rom": {
            "filename": ROM_PATH.name,
            "sha256": EXPECTED_ROM_SHA256,
            "format": "iNES 1.0",
            "mapper": 4,
            "prg_size_bytes": "0x040000",
            "chr_size_bytes": "0x020000",
        },
        "map": {
            "map_id": "0x11",
            "resolved_selector": f"0x{selector:02X}",
            "selector_proof": {
                "logic_path": selector_logic_name,
                "logic_cpu_address": "0x86D3",
                "logic_file_offset": f"0x{SELECTOR_LOGIC_OFFSET:06X}",
                "table_base_cpu_address": "0x8B42",
                "table_byte_path": selector_name,
                "table_index": selector_table_index,
                "table_entry_cpu_address": f"0x{0x8B42 + selector_table_index:04X}",
                "table_entry_file_offset": f"0x{selector_proof_offset:06X}",
                "packed_byte": f"0x{selector_proof[0]:02X}",
                "shift": selector_shift,
                "mask": "0x03",
                "result": f"0x{selector:02X}",
                "formula": "selector=(packed_byte>>(2*(map_id&3)))&3",
            },
            "block_map_path": block_name,
            "block_map_dimensions": "8x4 metatiles",
            "metatile_ids_referenced": [f"0x{value:02X}" for value in metatile_ids],
            "chr_pair_path": chr_name,
            "chr_pair": ["0x3C", "0x4A"],
        },
        "source_mapping": {
            "bank_0b_file_base": "0x016010",
            "bank_0b_cpu_base": "0x8000",
            "bank_12_file_base": "0x024010",
            "bank_12_cpu_base": "0xA000",
            "selector_logic": "bank-$0B:$86D3; packed selector table at bank-$0B:$8B42",
            "block_map_formula": "file=0x016B74+(map_id*0x20); cpu=0x8B64+(map_id*0x20)",
            "chr_pair_formula": "file=0x0166FE+(map_id*2); cpu=0x86EE+(map_id*2)",
            "tile_record_formula": "window_offset=(selector<<12)+(metatile_id<<4); bank=0x12+(window_offset>>13); cpu=0xA000+(window_offset&0x1FFF); file=0x024010+window_offset",
            "attribute_formula": "cpu=0x9BE4+(selector<<8)+metatile_id; file=0x017BF4+(selector<<8)+metatile_id",
        },
        "entries": entries,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Extracted map $11: selector ${selector:02X}, {len(block_map)} block bytes, CHR {chr_pair.hex(' ').upper()}, {len(metatile_ids)} referenced metatiles.")
    print(f"Wrote manifest: {MANIFEST_PATH.relative_to(ROOT)} ({len(entries)} source records).")


if __name__ == "__main__":
    main()
