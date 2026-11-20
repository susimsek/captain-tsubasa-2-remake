#!/usr/bin/env python3
"""Extract and verify ROM sources needed for first-command map-$12."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/map_12"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

MAP_ID = 0x12
EXPECTED_SELECTOR = 0x00
EXPECTED_PACKED_SELECTOR = 0x00
EXPECTED_BLOCK_MAP = bytes.fromhex(
    "00 08 00 06 07 00 0A 00 "
    "0D 0C 32 33 0D 0C 0D 0C "
    "12 12 12 12 12 12 12 12 "
    "13 13 13 13 13 13 13 13"
)
EXPECTED_CHR_PAIR = bytes.fromhex("3C 4A")
EXPECTED_SELECTOR_LOGIC = bytes.fromhex(
    "48 29 03 AA 68 48 4A 4A A8 B9 42 8B CA 30 05 4A "
    "4A 4C DF 86 29 03 8D CA 05 68 60"
)
EXPECTED_ROUTE_MAP_LOOKUP = 0x12
ROUTE_POSITION_INDEX = 5

SELECTOR_LOGIC_OFFSET = 0x0166E3  # bank-$0B CPU $86D3
SELECTOR_TABLE_OFFSET = 0x016B52  # bank-$0B CPU $8B42
BLOCK_MAP_TABLE_OFFSET = 0x016B74  # bank-$0B CPU $8B64
CHR_PAIR_TABLE_OFFSET = 0x0166FE  # bank-$0B CPU $86EE
CONTROL_MAP_TABLE_OFFSET = 0x0161E5  # bank-$0B CPU $81D5
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


def preserve_or_check(path: Path, data: bytes, *, check: bool) -> None:
    if check:
        if not path.is_file() or path.read_bytes() != data:
            raise SystemExit(f"ROM-derived artifact is missing or differs: {path.relative_to(ROOT)}")
        return
    if path.exists() and path.read_bytes() != data:
        raise SystemExit(f"Preserved source differs from the hash-matched ROM: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def build_artifacts(rom: bytes) -> dict[str, bytes]:
    selector_logic = checked_slice(
        rom, SELECTOR_LOGIC_OFFSET, len(EXPECTED_SELECTOR_LOGIC), "Selector logic"
    )
    selector_table_index = MAP_ID >> 2
    selector_proof_offset = SELECTOR_TABLE_OFFSET + selector_table_index
    selector_proof = checked_slice(rom, selector_proof_offset, 1, "Map-$12 selector proof")
    selector_shift = 2 * (MAP_ID & 0x03)
    selector = (selector_proof[0] >> selector_shift) & 0x03

    route_lookup_offset = CONTROL_MAP_TABLE_OFFSET + ROUTE_POSITION_INDEX
    route_map_lookup_proof = checked_slice(
        rom, route_lookup_offset, 1, "Map-$12 route map-lookup proof"
    )
    block_file_offset = BLOCK_MAP_TABLE_OFFSET + MAP_ID * 0x20
    block_map = checked_slice(rom, block_file_offset, 0x20, "Map-$12 block map")
    chr_file_offset = CHR_PAIR_TABLE_OFFSET + MAP_ID * 2
    chr_pair = checked_slice(rom, chr_file_offset, 2, "Map-$12 CHR pair")

    if selector_logic != EXPECTED_SELECTOR_LOGIC:
        raise SystemExit("Bank-$0B selector routine $86D3 differs from the pinned ROM bytes.")
    if selector_proof[0] != EXPECTED_PACKED_SELECTOR or selector != EXPECTED_SELECTOR:
        raise SystemExit(
            f"Map-$12 selector changed: packed=${selector_proof[0]:02X}, selector=${selector:02X}."
        )
    if route_map_lookup_proof[0] != EXPECTED_ROUTE_MAP_LOOKUP:
        raise SystemExit(
            f"Route position index {ROUTE_POSITION_INDEX} no longer resolves to map "
            f"${route_map_lookup_proof[0]:02X} at $81DA."
        )
    if block_map != EXPECTED_BLOCK_MAP:
        raise SystemExit("Map-$12 32-byte block map differs from the audited ROM source.")
    if chr_pair != EXPECTED_CHR_PAIR:
        raise SystemExit(f"Map-$12 CHR pair changed: {chr_pair.hex(' ').upper()}.")

    artifacts: dict[str, bytes] = {
        "selector_logic_86d3.bin": selector_logic,
        "selector_proof.bin": selector_proof,
        "route_map_lookup_proof.bin": route_map_lookup_proof,
        "block_map_12_selector_00.bin": block_map,
        "chr_pair_12.bin": chr_pair,
    }
    for metatile_id in sorted(set(block_map)):
        tile_window_offset = (selector << 12) + (metatile_id << 4)
        tile_file_offset = TILE_DATA_BASE_OFFSET + tile_window_offset
        tile_bytes = checked_slice(
            rom, tile_file_offset, 0x10, f"Metatile ${metatile_id:02X} tile IDs"
        )
        artifacts[f"metatile_{metatile_id:02X}_tiles.bin"] = tile_bytes

        attribute_file_offset = ATTRIBUTE_TABLE_OFFSET + (selector << 8) + metatile_id
        attribute = checked_slice(
            rom, attribute_file_offset, 1, f"Metatile ${metatile_id:02X} attribute"
        )
        artifacts[f"metatile_{metatile_id:02X}_attribute.bin"] = attribute

    return artifacts


def build_manifest(artifacts: dict[str, bytes]) -> dict[str, object]:
    selector_table_index = MAP_ID >> 2
    selector_proof_offset = SELECTOR_TABLE_OFFSET + selector_table_index
    selector_shift = 2 * (MAP_ID & 0x03)
    selector_proof = artifacts["selector_proof.bin"]
    selector = (selector_proof[0] >> selector_shift) & 0x03
    block_file_offset = BLOCK_MAP_TABLE_OFFSET + MAP_ID * 0x20
    chr_file_offset = CHR_PAIR_TABLE_OFFSET + MAP_ID * 2
    route_lookup_offset = CONTROL_MAP_TABLE_OFFSET + ROUTE_POSITION_INDEX
    entries: list[dict[str, object]] = []

    entries.append(prg_entry(
        path="selector_logic_86d3.bin", data=artifacts["selector_logic_86d3.bin"],
        file_offset=SELECTOR_LOGIC_OFFSET, cpu_address=0x86D3, prg_bank=0x0B,
        source="Bank-$0B selector routine: reads the packed selector table at $8B42 and stores the selected 2-bit value at $05CA.",
    ))
    entries.append(prg_entry(
        path="selector_proof.bin", data=selector_proof,
        file_offset=selector_proof_offset, cpu_address=0x8B42 + selector_table_index,
        prg_bank=0x0B,
        source="Packed selector table byte addressed by map ID $12 >> 2; selector=(byte >> (2*(map_id&3))) & 3.",
        map_id="0x12", table_index=selector_table_index,
        selector_shift=selector_shift, resolved_selector=f"0x{selector:02X}",
    ))
    entries.append(prg_entry(
        path="route_map_lookup_proof.bin", data=artifacts["route_map_lookup_proof.bin"],
        file_offset=route_lookup_offset, cpu_address=0x81D5 + ROUTE_POSITION_INDEX,
        prg_bank=0x0B,
        source="Callback-$01 control-map lookup byte at $81D5 + the observed route position index 5; resolves to map ID $12.",
        route_position_index=ROUTE_POSITION_INDEX,
        resolved_map_id="0x12",
    ))
    block_name = "block_map_12_selector_00.bin"
    entries.append(prg_entry(
        path=block_name, data=artifacts[block_name],
        file_offset=block_file_offset, cpu_address=0x8B64 + MAP_ID * 0x20,
        prg_bank=0x0B,
        source="8x4 metatile-ID block map selected by the ROM's map-$12 branch.",
        map_id="0x12", selector="0x00", dimensions_blocks="8x4",
    ))
    chr_name = "chr_pair_12.bin"
    entries.append(prg_entry(
        path=chr_name, data=artifacts[chr_name],
        file_offset=chr_file_offset, cpu_address=0x86EE + MAP_ID * 2,
        prg_bank=0x0B,
        source="The map-$12 CHR selector pair read by the bank-$0B map worker.",
        map_id="0x12", chr_pair_hex="3C 4A",
    ))

    metatile_ids = sorted(set(artifacts[block_name]))
    for metatile_id in metatile_ids:
        tile_window_offset = (selector << 12) + (metatile_id << 4)
        tile_file_offset = TILE_DATA_BASE_OFFSET + tile_window_offset
        tile_bank = 0x12 + (tile_window_offset >> 13)
        tile_cpu_address = 0xA000 + (tile_window_offset & 0x1FFF)
        tile_name = f"metatile_{metatile_id:02X}_tiles.bin"
        entries.append(prg_entry(
            path=tile_name, data=artifacts[tile_name],
            file_offset=tile_file_offset, cpu_address=tile_cpu_address,
            prg_bank=tile_bank,
            source="Selector-derived 4x4 tile-ID record referenced by the map-$12 block map.",
            map_id="0x12", selector=f"0x{selector:02X}",
            metatile_id=f"0x{metatile_id:02X}",
        ))

        attribute_file_offset = ATTRIBUTE_TABLE_OFFSET + (selector << 8) + metatile_id
        attribute_name = f"metatile_{metatile_id:02X}_attribute.bin"
        entries.append(prg_entry(
            path=attribute_name, data=artifacts[attribute_name],
            file_offset=attribute_file_offset,
            cpu_address=0x9BE4 + (selector << 8) + metatile_id,
            prg_bank=0x0B,
            source="Selector-derived attribute byte referenced by the map-$12 block map.",
            map_id="0x12", selector=f"0x{selector:02X}",
            metatile_id=f"0x{metatile_id:02X}",
        ))

    return {
        "schema": "ct2-first-command-map-12-rom-sources-v1",
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
            "map_id": "0x12",
            "resolved_selector": f"0x{selector:02X}",
            "selector_proof": {
                "logic_path": "selector_logic_86d3.bin",
                "logic_cpu_address": "0x86D3",
                "logic_file_offset": f"0x{SELECTOR_LOGIC_OFFSET:06X}",
                "table_base_cpu_address": "0x8B42",
                "table_byte_path": "selector_proof.bin",
                "table_index": selector_table_index,
                "table_entry_cpu_address": f"0x{0x8B42 + selector_table_index:04X}",
                "table_entry_file_offset": f"0x{selector_proof_offset:06X}",
                "packed_byte": f"0x{selector_proof[0]:02X}",
                "shift": selector_shift,
                "mask": "0x03",
                "result": f"0x{selector:02X}",
                "formula": "selector=(packed_byte>>(2*(map_id&3)))&3",
            },
            "route_map_lookup_proof": {
                "table_base_cpu_address": "0x81D5",
                "table_byte_path": "route_map_lookup_proof.bin",
                "position_index": ROUTE_POSITION_INDEX,
                "entry_cpu_address": f"0x{0x81D5 + ROUTE_POSITION_INDEX:04X}",
                "entry_file_offset": f"0x{route_lookup_offset:06X}",
                "result": f"0x{artifacts['route_map_lookup_proof.bin'][0]:02X}",
                "route_position_inputs": {
                    "$0637": "0x54",
                    "$0635": "0x84",
                    "$05FB": "0x00",
                },
                "interpretation": "The ROM coordinate helper maps the observed route inputs to position index 5; the table byte resolves that index to map $12.",
            },
            "block_map_path": "block_map_12_selector_00.bin",
            "block_map_dimensions": "8x4 metatiles",
            "metatile_ids_referenced": [f"0x{value:02X}" for value in metatile_ids],
            "chr_pair_path": chr_name,
            "chr_pair": [f"0x{value:02X}" for value in artifacts[chr_name]],
        },
        "source_mapping": {
            "bank_0b_file_base": "0x016010",
            "bank_0b_cpu_base": "0x8000",
            "bank_12_file_base": "0x024010",
            "bank_12_cpu_base": "0xA000",
            "selector_logic": "bank-$0B:$86D3; packed selector table at bank-$0B:$8B42",
            "route_map_lookup": "bank-$0B:$81D5; callback-$01 control-map lookup selected by the ROM coordinate helper",
            "block_map_formula": "file=0x016B74+(map_id*0x20); cpu=0x8B64+(map_id*0x20)",
            "chr_pair_formula": "file=0x0166FE+(map_id*2); cpu=0x86EE+(map_id*2)",
            "tile_record_formula": "window_offset=(selector<<12)+(metatile_id<<4); bank=0x12+(window_offset>>13); cpu=0xA000+(window_offset&0x1FFF); file=0x024010+window_offset",
            "attribute_formula": "cpu=0x9BE4+(selector<<8)+metatile_id; file=0x017BF4+(selector<<8)+metatile_id",
        },
        "entries": entries,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify artifacts without writing")
    args = parser.parse_args()

    rom = checked_rom()
    artifacts = build_artifacts(rom)
    manifest = build_manifest(artifacts)
    outputs = dict(artifacts)
    outputs["manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    for name, data in outputs.items():
        preserve_or_check(OUTPUT_DIR / name, data, check=args.check)

    action = "Verified" if args.check else "Extracted"
    print(
        f"{action} map $12: selector $00, 32 block bytes, CHR "
        f"{artifacts['chr_pair_12.bin'].hex(' ').upper()}, "
        f"{len(set(artifacts['block_map_12_selector_00.bin']))} referenced metatiles."
    )
    print(f"{action} {len(outputs)} artifacts in {OUTPUT_DIR.relative_to(ROOT)}.")


if __name__ == "__main__":
    main()
