#!/usr/bin/env python3
"""Compare an end-of-frame OAM shadow render with the FCEUX screen sample.

This is diagnostic-only. It reads FCEUX frame-end RAM/PPU state and raw GD
screenshots for validation; none of these files are runtime game assets.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compare_rom_intro_frames import gd_rgb

WIDTH = 256
HEIGHT = 240
OAM_START = 0x0200
OAM_SIZE = 0x100
SPRITE_PATTERN_BASE = 0x1000  # The checked opening PPUCTRL value is $88.
PALETTE_START = 0x3F10


def rendered_oam_pixels(ram: bytes, ppu: bytes, rgb_palette: bytes) -> dict[int, bytes]:
    """Return opaque sprite pixels after OAM index priority is applied."""
    if len(ram) != 0x800 or len(ppu) != 0x4000 or len(rgb_palette) != 192:
        raise ValueError("Unexpected FCEUX RAM, PPU, or RGB palette size")
    oam = ram[OAM_START:OAM_START + OAM_SIZE]
    pixels: dict[int, bytes] = {}

    # OAM index zero has highest sprite priority, so paint entries backwards.
    for sprite_index in range(63, -1, -1):
        y, tile, attributes, x = oam[sprite_index * 4:sprite_index * 4 + 4]
        top_y = (y + 1) & 0xFF
        pattern = SPRITE_PATTERN_BASE + tile * 16
        palette_group = attributes & 0x03
        flip_h = bool(attributes & 0x40)
        flip_v = bool(attributes & 0x80)

        for pixel_y in range(8):
            screen_y = top_y + pixel_y
            if screen_y >= HEIGHT:
                continue
            source_y = 7 - pixel_y if flip_v else pixel_y
            low_plane = ppu[pattern + source_y]
            high_plane = ppu[pattern + 8 + source_y]
            for pixel_x in range(8):
                screen_x = x + pixel_x
                if screen_x >= WIDTH:
                    continue
                source_x = 7 - pixel_x if flip_h else pixel_x
                bit = 7 - source_x
                color_index = ((low_plane >> bit) & 1) | (((high_plane >> bit) & 1) << 1)
                if color_index == 0:
                    continue

                palette_address = PALETTE_START + palette_group * 4 + color_index
                nes_color = ppu[palette_address] & 0x3F
                palette_offset = nes_color * 3
                pixel_offset = screen_y * WIDTH + screen_x
                pixels[pixel_offset] = bytes(rgb_palette[palette_offset:palette_offset + 3])

    return pixels


def count_exact_pixels(screen: bytes, sprites: dict[int, bytes]) -> tuple[int, int]:
    exact = sum(screen[offset * 3:offset * 3 + 3] == color
                for offset, color in sprites.items())
    return exact, len(sprites)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-dir", type=Path, required=True,
                        help="FCEUX capture directory with ram_states/ and ppu_states/")
    parser.add_argument("--screens-dir", type=Path, required=True,
                        help="FCEUX raw gui.gdscreenshot() files")
    parser.add_argument("--rgb-palette", type=Path, required=True,
                        help="Documented 64-color FCEUX RGB palette")
    parser.add_argument("--apu-writes", type=Path,
                        help="Optional same-input CPU-bus trace with $4014 writes")
    parser.add_argument("--frames", type=int, nargs="+", required=True)
    args = parser.parse_args()

    rgb_palette = args.rgb_palette.read_bytes()
    apu_by_frame: dict[int, dict[str, str]] = {}
    if args.apu_writes is not None:
        with args.apu_writes.open(newline="", encoding="utf-8") as stream:
            for row in csv.DictReader(stream):
                if row["address"] == "$4014":
                    apu_by_frame[int(row["source_frame"])] = row

    print("screen_frame,ram_oam_frame,exact_sprite_pixels,opaque_sprite_pixels,dma_pc,dma_value,dma_cycle")
    for frame in args.frames:
        screen = gd_rgb(args.screens_dir / f"frame_{frame:06d}.gd")
        ppu = (args.capture_dir / "ppu_states" / f"ppu_{frame:05d}.bin").read_bytes()
        dma = apu_by_frame.get(frame, {})
        for ram_frame in (frame - 1, frame):
            ram = (args.capture_dir / "ram_states" / f"ram_{ram_frame:05d}.bin").read_bytes()
            exact, opaque = count_exact_pixels(screen, rendered_oam_pixels(ram, ppu, rgb_palette))
            print(f"{frame},{ram_frame},{exact},{opaque},"
                  f"{dma.get('pc', '')},{dma.get('value', '')},{dma.get('cpu_cycle', '')}")


if __name__ == "__main__":
    main()
