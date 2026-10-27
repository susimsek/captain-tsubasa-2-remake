#!/usr/bin/env python3
"""Build ROM-derived title background layers with alpha for sprite priority.

The PPU snapshot supplies only the title nametable, attribute, and palette
layout. Tile patterns come from the supplied ROM's CHR bytes. No emulator
screenshots or captured image pixels are used.
"""

from __future__ import annotations

import hashlib
import json
import struct
import zlib
from pathlib import Path

from render_emulator_ppu_frame import background_pixels, read_palette_file, resolve_snapshot
from render_rom_frame import extract_chr, map_pattern_banks


ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
CAPTURE_DIR = ROOT / "reference/opening_reference_capture"
RGB_PALETTE_PATH = ROOT / "reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal"
OUTPUT_DIR = ROOT / "assets/opening"
SPRITE_PALETTE_OFFSET = 0x00D3A0
TITLE_PPU_FRAME = 4692


def png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    body = chunk_type + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def write_rgba_png(path: Path, indices: list[int], opaque: list[bool],
                   palette: list[tuple[int, int, int]]) -> None:
    width, height = 256, 240
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # PNG filter: None
        row_start = y * width
        for x in range(width):
            pixel = row_start + x
            red, green, blue = palette[indices[pixel] & 0x3F]
            raw.extend((red, green, blue, 255 if opaque[pixel] else 0))

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", header)
        + png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + png_chunk(b"IEND", b"")
    )


def main() -> None:
    rom = ROM_PATH.read_bytes()
    chr_rom, chr_file_offset, rom_hash = extract_chr(ROM_PATH)
    ppu_path, ppu_frame = resolve_snapshot(CAPTURE_DIR, "ppu", TITLE_PPU_FRAME)
    ppu_source = ppu_path.read_bytes()
    mapped_ppu, banks = map_pattern_banks(ppu_source, chr_rom)
    expected_banks = [124, 125, 126, 127, 124, 125, 126, 127]
    if banks != expected_banks:
        raise ValueError(f"Unexpected title CHR mapping: {banks}")

    palette = read_palette_file(RGB_PALETTE_PATH)
    palette_hash = hashlib.sha256(RGB_PALETTE_PATH.read_bytes()).hexdigest()
    ppu_hash = hashlib.sha256(ppu_source).hexdigest()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    states = (
        ("title_menu_background", []),
        ("title_menu_continue_background", [(0x220A, 0x00), (0x224A, 0x7F)]),
    )
    for stem, writes in states:
        state = bytearray(mapped_ppu)
        for address, value in writes:
            state[address] = value
        indices, opaque = background_pixels(
            bytes(state), page=0, pattern_base=0, scroll_x=0, scroll_y=0
        )
        output_path = OUTPUT_DIR / f"{stem}.png"
        write_rgba_png(output_path, indices, opaque, palette)
        metadata = {
            "source_rom": ROM_PATH.name,
            "rom_sha256": rom_hash,
            "chr_file_offset": f"0x{chr_file_offset:X}",
            "source_chr_banks_by_ppu_slot": banks,
            "layout_reference": str(ppu_path.relative_to(ROOT)),
            "layout_reference_frame": ppu_frame,
            "layout_reference_sha256": ppu_hash,
            "rgb_palette_source": str(RGB_PALETTE_PATH.relative_to(ROOT)),
            "rgb_palette_sha256": palette_hash,
            "ppu_render_assumptions": {
                "nametable_page": 0,
                "background_pattern_base": 0,
                "scroll": [0, 0],
            },
            "runtime_layer": "background only; ROM sprite animation is rendered separately",
            "alpha_rule": "pixels whose CHR color index is zero are transparent so NES behind-background sprites can show through",
            "nametable_writes": [
                {"ppu_address": f"0x{address:04X}", "tile_id": f"0x{value:02X}"}
                for address, value in writes
            ],
            "screenshot_pixels_used": False,
        }
        output_path.with_suffix(".json").write_text(
            json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    sprite_palette = rom[SPRITE_PALETTE_OFFSET:SPRITE_PALETTE_OFFSET + 16]
    if len(sprite_palette) != 16:
        raise ValueError("ROM is truncated before the title sprite palette")
    palette_bin = ROOT / "reference/rom_extract/intro/animation_0D_sprite_palette.bin"
    palette_bin.write_bytes(sprite_palette)
    palette_metadata = {
        "rom_sha256": rom_hash,
        "animation_id": "0x0D",
        "animation_palette_operand": "0x09",
        "prg_bank": 6,
        "cpu_address": "0xB390",
        "source_file_offset": f"0x{SPRITE_PALETTE_OFFSET:06X}",
        "ppu_destination": "$3F10-$3F1F",
        "bytes_hex": sprite_palette.hex(" "),
        "reference_ppu_snapshot": str(ppu_path.relative_to(ROOT)),
        "reference_ppu_sprite_palette_hex": ppu_source[0x3010:0x3020].hex(" "),
        "matches_reference_ppu_palette": sprite_palette == ppu_source[0x3010:0x3020],
        "conversion": "raw 16-byte palette record copied unchanged from the supplied ROM",
    }
    palette_bin.with_suffix(".json").write_text(
        json.dumps(palette_metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("Built transparent ROM-CHR title backgrounds and preserved the exact cup palette bytes.")


if __name__ == "__main__":
    main()
