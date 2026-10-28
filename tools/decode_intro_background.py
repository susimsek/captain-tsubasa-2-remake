#!/usr/bin/env python3
"""Decode static 4x4 metatile layouts from the supplied Turkish ROM.

The export preserves NES tile IDs and palette indices. It does not choose an
RGB palette or resolve scroll/raster timing; those belong to the renderer.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference" / "rom_extract" / "intro"
BLOCK_PAGE_VARIANT_OFFSET = 0x1100
DEFAULT_BACKGROUND_IDS = (0x00, 0x01, 0x03, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x17)


def w(data: bytes, at: int) -> int:
    return data[at] | data[at + 1] << 8


def hexn(value: int, width: int = 2) -> str:
    return f"0x{value:0{width}X}"


def bank_file(bank: int, cpu: int) -> int:
    return 16 + 0x2000 * bank + cpu - 0xA000


def decode_background(rom: bytes, bg_id: int, output_dir: Path = OUT) -> dict:
    pointer_table = bank_file(7, 0xA000)
    cpu = w(rom, pointer_table + 2 * bg_id)
    source = bank_file(7, cpu)
    next_cpu = w(rom, pointer_table + 2 * (bg_id + 1))
    record = rom[source : bank_file(7, next_cpu)]
    if len(record) < 6:
        raise ValueError(f"Background ${bg_id:02X} record is truncated.")
    (output_dir / f"background_{bg_id:02X}.bin").write_bytes(record)
    chr_first, chr_second, palette_flag, block_rows, block_cols, packed_origin = record[:6]
    block_page_selector = (palette_flag >> 7) & 1
    block_page_offset = BLOCK_PAGE_VARIANT_OFFSET * block_page_selector
    block_page_base_source = bank_file(8, 0xA000) + block_page_offset
    count = block_rows * block_cols
    ids = list(record[6 : 6 + count])
    assert len(ids) == count

    # Supplied bank-0 routine $8B5F–$8B7F turns the packed origin into a PPU
    # nametable address. The first two nametables are represented here as a
    # 64-tile-wide plane; scroll decides which 32-tile window is visible.
    ppu_origin = 0x2000 + ((packed_origin & 0xF8) << 4) + ((packed_origin & 7) << 2)
    origin_nt = (ppu_origin - 0x2000) // 0x400
    origin_offset = (ppu_origin - 0x2000) % 0x400
    origin_x = 32 * origin_nt + origin_offset % 32
    origin_y = origin_offset // 32
    placements = []
    used_blocks = {}
    base_page_blocks = {}
    for block_index, block_id in enumerate(ids):
        block_row = block_index // block_cols
        block_column = block_index % block_cols
        base_block_source = bank_file(8, 0xA000) + 17 * block_id
        base_block = rom[base_block_source : base_block_source + 17]
        assert len(base_block) == 17
        base_page_blocks[block_id] = (base_block_source, base_block)
        (output_dir / f"block_{block_id:02X}.bin").write_bytes(base_block)

        block_source = base_block_source + block_page_offset
        block = rom[block_source : block_source + 17]
        assert len(block) == 17
        block_name = f"block_{block_id:02X}_page_11.bin" if block_page_selector else f"block_{block_id:02X}.bin"
        block_relative_path = (output_dir / block_name).relative_to(ROOT).as_posix()
        used_blocks[block_id] = (block_source, block, block_relative_path)
        if block_page_selector:
            (output_dir / block_name).write_bytes(block)
        attr = block[0]
        if bg_id == 0x0A:
            # The BG0A loader treats $201C as the destination cursor for the
            # final record column (c=11), then decrements the PPU cursor by a
            # 4-tile block for each packet. The source record itself remains
            # left-to-right, so c maps to world x=(48+4*c) modulo 64.
            bx = 48 + block_column * 4
        else:
            bx = origin_x + block_column * 4
        by = origin_y + block_row * 4
        for iy in range(4):
            for ix in range(4):
                quadrant = (iy // 2) * 2 + ix // 2
                palette_id = (attr >> (quadrant * 2)) & 3
                placements.append({
                    "x": (bx + ix) % 64,
                    "unwrapped_x": bx + ix,
                    "y": by + iy,
                    "tile_id": block[1 + iy * 4 + ix],
                    "palette_id": palette_id,
                    "block_id": block_id,
                "block_file_offset": hexn(block_source, 6),
                })

    palette_index = palette_flag & 0x3F
    palette_source = bank_file(6, 0xB000) + 16 * palette_index
    palette = rom[palette_source : palette_source + 16]
    assert len(palette) == 16
    (output_dir / f"background_palette_{palette_index:02X}.bin").write_bytes(palette)

    return {
        "background_id": hexn(bg_id),
        "rom_sha256": hashlib.sha256(rom).hexdigest(),
        "record_file_offset": hexn(source, 6),
        "record_cpu_address": hexn(cpu, 4),
        "record_raw_hex": record.hex(" "),
        "record_source_bin": (output_dir / f"background_{bg_id:02X}.bin").relative_to(ROOT).as_posix(),
        "chr_2k_bank_start_ids": [chr_first, chr_second],
        "chr_1k_banks_for_background": [chr_first, chr_first + 1, chr_second, chr_second + 1],
        "palette_flag_byte": hexn(palette_flag),
        "block_page_selector": block_page_selector,
        "block_page_offset": hexn(block_page_offset, 4),
        "block_page_base_file_offset": hexn(block_page_base_source, 6),
        "block_page_selector_source": "bank-0 $8B4E transfers palette-flag bit 7 to $5B bit 0; bank-0 $8EF0 adds $1100 when set",
        "palette_index": palette_index,
        "palette_file_offset": hexn(palette_source, 6),
        "palette_raw_hex": palette.hex(" "),
        "palette_source_bin": (output_dir / f"background_palette_{palette_index:02X}.bin").relative_to(ROOT).as_posix(),
        "metatile_rows": block_rows,
        "metatile_columns": block_cols,
        "metatile_ids_hex": bytes(ids).hex(" "),
        "packed_origin": hexn(packed_origin),
        "origin_ppu_address": hexn(ppu_origin, 4),
        "origin_x_in_two_nametables": origin_x,
        "origin_y": origin_y,
        **({
            "metatile_world_mapping": "record column c maps to x=(48+4*c) mod 64; rows are top-to-bottom",
            "block_packet_traversal": "right_to_left_per_row",
            "metatile_world_x_origin": 48,
            "block_packet_traversal_evidence": "BG0A F9 NMI packet trace frames 2342-2368; all 240 destination/payload packets match ROM blocks",
        } if bg_id == 0x0A else {}),
        "trailing_record_bytes_hex": record[6 + count :].hex(" "),
        "used_4x4_blocks": [
            {"id": hexn(i), "file_offset": hexn(v[0], 6), "raw_hex": v[1].hex(" "),
             "source_bin": v[2]}
            for i, v in sorted(used_blocks.items())
        ],
        "base_page_4x4_blocks": [
            {"id": hexn(i), "file_offset": hexn(v[0], 6), "raw_hex": v[1].hex(" "),
             "source_bin": (output_dir / f"block_{i:02X}.bin").relative_to(ROOT).as_posix()}
            for i, v in sorted(base_page_blocks.items())
        ] if block_page_selector else [],
        "tile_placements": placements,
        "limitations": "Static NES tile and 2-bit attribute layout with the ROM-selected block page; special traversal timing, scroll, mirroring, raster CHR switches, brightness, sprites and external NES RGB palette are separate.",
    }


def route_background_ids() -> list[int]:
    result: set[int] = set()
    event_root = ROOT / "assets/gameplay/rom_logic"
    for cutscene_id in (1, 2):
        path = event_root / f"kickoff_cutscene_{cutscene_id:02d}_events.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        if document.get("source_rom_sha256") != hashlib.sha256(ROM.read_bytes()).hexdigest():
            raise SystemExit(f"Cutscene event metadata ROM identity mismatch: {path}")
        for event in document.get("events", []):
            if event.get("kind") in ("background_1", "background_2"):
                result.add(int(event["id"]))
    return sorted(result)


def main() -> None:
    rom = ROM.read_bytes()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kickoff-cutscenes", action="store_true",
                        help="extract layouts used by the byte-indexed cutscene 1/2 event manifests")
    args = parser.parse_args()
    if args.kickoff_cutscenes:
        output_dir = ROOT / "reference/rom_extract/gameplay/backgrounds"
        background_ids = route_background_ids()
    else:
        output_dir = OUT
        background_ids = list(DEFAULT_BACKGROUND_IDS)
    output_dir.mkdir(parents=True, exist_ok=True)
    for bg_id in background_ids:
        result = decode_background(rom, bg_id, output_dir)
        (output_dir / f"background_{bg_id:02X}_layout.json").write_text(
            json.dumps(result, indent=2) + "\n", encoding="utf-8"
        )
        print(bg_id, result["metatile_rows"], result["metatile_columns"],
              result["origin_ppu_address"], len(result["tile_placements"]))


if __name__ == "__main__":
    main()
