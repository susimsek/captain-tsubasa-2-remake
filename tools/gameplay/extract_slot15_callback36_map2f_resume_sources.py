#!/usr/bin/env python3
"""Extract ROM-only inputs for callback-$36 map-$2F's resumed slot-$15 worker."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/map_2f_resume"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INES_HEADER_SIZE = 0x10
PRG_BANK_SIZE = 0x2000
PRG_BANK_0B = 0x0B
PRG_BANK_0B_CPU_BASE = 0x8000
PRG_BANK_12 = 0x12
PRG_BANK_12_CPU_BASE = 0xA000
MAP_ID = 0x2F
SELECTOR_TABLE_CPU = 0x8B42
BLOCK_MAP_TABLE_CPU = 0x8B64
SELECTOR_FORMULA = "(table[map_id >> 2] >> (2 * (map_id & 3))) & 3"
BLOCK_MAP_FORMULA = "0x8B64 + ((map_id >> 3) << 8) + ((map_id & 7) << 5)"
TILE_RECORD_FORMULA = "window=(selector << 12)+(metatile_id << 4); bank=0x12+(window >> 13); cpu=0xA000+(window & 0x1FFF); file=0x024010+window"
ATTRIBUTE_FORMULA = "file=0x017BF4+(selector << 8)+metatile_id; CPU address is bank-$0B $8000+(file-0x016010)"

WORKER_EXECUTED_SPANS = [
    {
        "name": "resumed_map_worker_prefix_8572_85c2",
        "path": "reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_8572_85c2.bin",
        "cpu_start": "0x8572",
        "cpu_end_exclusive": "0x85C2",
        "file_offset": "0x016582",
        "prg_bank": "0x0B",
        "size_bytes": 80,
        "sha256": "098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502",
    },
    {
        "name": "metatile_expander_85c2_86d3",
        "path": "reference/rom_extract/gameplay/first_command_field/map_worker_8525/bank_0b_85c2_86d3.bin",
        "cpu_start": "0x85C2",
        "cpu_end_exclusive": "0x86D3",
        "file_offset": "0x0165D2",
        "prg_bank": "0x0B",
        "size_bytes": 273,
        "sha256": "1aab318fd595b2cf9f82ed8176340dfe43d4fbdc792e9204ede31c2d21c79e15",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def hex_bytes(data: bytes) -> str:
    return " ".join(f"{value:02X}" for value in data)


def prg_file_offset(bank: int, cpu_base: int, cpu_address: int) -> int:
    if cpu_address < cpu_base or cpu_address >= cpu_base + PRG_BANK_SIZE:
        raise ValueError(f"CPU address ${cpu_address:04X} is outside bank ${bank:02X}'s mapped window")
    return INES_HEADER_SIZE + bank * PRG_BANK_SIZE + cpu_address - cpu_base


def write_binary(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
    if len(rom) < INES_HEADER_SIZE or rom[:4] != b"NES\x1a":
        raise SystemExit("Supplied ROM does not have the expected iNES header.")
    header = rom[:INES_HEADER_SIZE]
    prg_size = header[4] * 0x4000
    chr_size = header[5] * 0x2000
    mapper = (header[6] >> 4) | (header[7] & 0xF0)
    if (mapper != 4 or header[6] & 0x04 or len(rom) != INES_HEADER_SIZE + prg_size + chr_size
            or prg_size != 0x40000 or chr_size != 0x20000):
        raise SystemExit("ROM header/layout differs from the pinned mapper-4, 16x16KiB PRG / 16x8KiB CHR source.")

    selector_byte_cpu = SELECTOR_TABLE_CPU + (MAP_ID >> 2)
    selector_byte_offset = prg_file_offset(PRG_BANK_0B, PRG_BANK_0B_CPU_BASE, selector_byte_cpu)
    selector_byte = rom[selector_byte_offset]
    selector = (selector_byte >> (2 * (MAP_ID & 3))) & 3
    if selector != 1:
        raise SystemExit(f"ROM selector for map ${MAP_ID:02X} resolved to ${selector:02X}, expected $01.")

    block_map_cpu = BLOCK_MAP_TABLE_CPU + ((MAP_ID >> 3) << 8) + ((MAP_ID & 7) << 5)
    block_map_offset = prg_file_offset(PRG_BANK_0B, PRG_BANK_0B_CPU_BASE, block_map_cpu)
    block_map = rom[block_map_offset:block_map_offset + 0x20]
    if len(block_map) != 0x20:
        raise SystemExit("Map-$2F block table is truncated.")

    first_batch_ids = block_map[:3]
    unique_ids = list(dict.fromkeys(block_map))
    first_batch_unique_ids = list(dict.fromkeys(first_batch_ids))
    outputs: dict[str, bytes] = {
        "map_2f_block_map.bin": block_map,
        "first_batch_metatile_ids.bin": first_batch_ids,
    }
    unique_sources: list[dict[str, object]] = []
    source_by_id: dict[int, tuple[bytes, bytes]] = {}

    for metatile_id in unique_ids:
        window_offset = (selector << 12) + (metatile_id << 4)
        tile_bank = PRG_BANK_12 + (window_offset >> 13)
        tile_cpu = PRG_BANK_12_CPU_BASE + (window_offset & 0x1FFF)
        tile_offset = prg_file_offset(tile_bank, PRG_BANK_12_CPU_BASE, tile_cpu)
        if tile_offset != INES_HEADER_SIZE + PRG_BANK_12 * PRG_BANK_SIZE + window_offset:
            raise SystemExit(f"Tile formula/file mapping disagreement for metatile ${metatile_id:02X}.")
        tile_record = rom[tile_offset:tile_offset + 0x10]
        attribute_offset = 0x017BF4 + (selector << 8) + metatile_id
        attribute_record = rom[attribute_offset:attribute_offset + 1]
        if len(tile_record) != 0x10 or len(attribute_record) != 1:
            raise SystemExit(f"Metatile ${metatile_id:02X} source record is truncated.")
        if not (INES_HEADER_SIZE + PRG_BANK_0B * PRG_BANK_SIZE <= attribute_offset
                < INES_HEADER_SIZE + (PRG_BANK_0B + 1) * PRG_BANK_SIZE):
            raise SystemExit(f"Attribute source for metatile ${metatile_id:02X} is outside bank-$0B.")
        attribute_cpu = PRG_BANK_0B_CPU_BASE + attribute_offset - (
            INES_HEADER_SIZE + PRG_BANK_0B * PRG_BANK_SIZE
        )

        tile_name = f"metatile_{metatile_id:02x}_tile_record.bin"
        attribute_name = f"metatile_{metatile_id:02x}_attribute.bin"
        outputs[tile_name] = tile_record
        outputs[attribute_name] = attribute_record
        source_by_id[metatile_id] = (tile_record, attribute_record)
        unique_sources.append({
            "metatile_id": f"0x{metatile_id:02X}",
            "used_by_map_cell_indices": [index for index, value in enumerate(block_map) if value == metatile_id],
            "tile_record": {
                "path": tile_name,
                "prg_bank": f"0x{tile_bank:02X}",
                "cpu_address": f"0x{tile_cpu:04X}",
                "file_offset": f"0x{tile_offset:06X}",
                "size_bytes": len(tile_record),
                "sha256": sha256(tile_record),
                "bytes_hex": hex_bytes(tile_record),
            },
            "attribute": {
                "path": attribute_name,
                "prg_bank": "0x0B",
                "cpu_address": f"0x{attribute_cpu:04X}",
                "file_offset": f"0x{attribute_offset:06X}",
                "size_bytes": len(attribute_record),
                "sha256": sha256(attribute_record),
                "bytes_hex": hex_bytes(attribute_record),
            },
        })

    first_batch_records = b"".join(
        bytes([metatile_id]) + source_by_id[metatile_id][0] + source_by_id[metatile_id][1]
        for metatile_id in first_batch_ids
    )
    outputs["first_batch_metatile_source_records.bin"] = first_batch_records
    for name, data in outputs.items():
        write_binary(OUTPUT_DIR / name, data)

    manifest = {
        "schema": "ct2-slot15-callback36-map2f-resume-sources-v1",
        "scope": "ROM-byte extraction only. Includes the complete 8x4 map block and the metatile source records needed by its first three cells. It does not execute the resumed worker, generate PPU queue writes, or claim rendered-pixel parity.",
        "source_rom": {
            "filename": ROM_PATH.name,
            "sha256": rom_hash,
            "size_bytes": len(rom),
            "ines_header_hex": hex_bytes(header),
            "format": "iNES 1.0",
            "mapper": mapper,
            "prg_rom_bytes": prg_size,
            "chr_rom_bytes": chr_size,
            "prg_bank_size_bytes": PRG_BANK_SIZE,
            "trainer_bytes": 0,
        },
        "runtime_rom_dependency": False,
        "capture_or_screenshot_bytes_included": False,
        "route_context": {
            "scenario_id": "0x2E",
            "callback_id": "0x36",
            "map_id": f"0x{MAP_ID:02X}",
            "map_worker_entry": "0x8525",
            "resume_continuation_after_first_yield": "0x8572",
            "first_yield_callsite": "0x856F",
            "observed_route_boundary": "Primary-agent same-input FCEUX trace reports scenario-$2E/callback-$36/map-$2F through $856F->$C515 at source frame 9468; the extraction package itself does not contain that trace.",
        },
        "mapping": {
            "bank_0B_file_base": "0x016010",
            "bank_0B_cpu_base": "0x8000",
            "bank_12_file_base": "0x024010",
            "bank_12_cpu_base": "0xA000",
            "selector_table_cpu_address": f"0x{SELECTOR_TABLE_CPU:04X}",
            "selector_table_index": f"0x{MAP_ID >> 2:02X}",
            "selector_byte_cpu_address": f"0x{selector_byte_cpu:04X}",
            "selector_byte_file_offset": f"0x{selector_byte_offset:06X}",
            "selector_byte_hex": f"{selector_byte:02X}",
            "selector_formula": SELECTOR_FORMULA,
            "resolved_selector": f"0x{selector:02X}",
            "block_map_formula": BLOCK_MAP_FORMULA,
            "block_map_cpu_address": f"0x{block_map_cpu:04X}",
            "block_map_prg_bank": "0x0B",
            "block_map_file_offset": f"0x{block_map_offset:06X}",
            "block_map_dimensions": "8x4 metatiles (32 bytes, consumed in linear map-cell order)",
            "tile_record_formula": TILE_RECORD_FORMULA,
            "attribute_formula": ATTRIBUTE_FORMULA,
        },
        "block_map": {
            "path": "map_2f_block_map.bin",
            "size_bytes": len(block_map),
            "sha256": sha256(block_map),
            "bytes_hex": hex_bytes(block_map),
            "unique_metatile_ids_in_first_occurrence_order": [f"0x{value:02X}" for value in unique_ids],
        },
        "first_batch": {
            "resume_source_pc": "0x8572",
            "map_cell_indices": [0, 1, 2],
            "metatile_ids_path": "first_batch_metatile_ids.bin",
            "metatile_ids_hex": hex_bytes(first_batch_ids),
            "unique_metatile_ids_in_first_occurrence_order": [f"0x{value:02X}" for value in first_batch_unique_ids],
            "expanded_source_records_path": "first_batch_metatile_source_records.bin",
            "expanded_source_records_format": "Three 18-byte records in map-cell order: metatile ID (1 byte), its selector-derived 4x4 tile-ID record (16 bytes), then its selector-derived attribute byte (1 byte). This repeats metatile $15 for cells 0 and 2.",
            "expanded_source_records_size_bytes": len(first_batch_records),
            "expanded_source_records_sha256": sha256(first_batch_records),
            "expanded_source_records_hex": hex_bytes(first_batch_records),
            "ppu_queue_bytes_or_bus_events_extracted": False,
        },
        "worker_code_references": WORKER_EXECUTED_SPANS,
        "metatile_sources_for_all_map_cells": unique_sources,
        "extracted_files": [
            {"path": name, "size_bytes": len(data), "sha256": sha256(data)}
            for name, data in sorted(outputs.items())
        ],
    }
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: map-$2F block map ${block_map_cpu:04X} / file 0x{block_map_offset:06X}; "
          f"first batch={hex_bytes(first_batch_ids)}; {len(unique_ids)} metatile source records extracted.")
    print(f"Manifest: {MANIFEST_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
