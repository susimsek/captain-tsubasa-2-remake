#!/usr/bin/env python3
"""Render an FCEUX PPU/RAM snapshot as a diagnostic or Godot-importable PNG.

This reads emulator-native state dumps only. It never reads a ROM and never
copies screenshot pixels into the rendered image. An optional FCEUX .gd
screenshot can calibrate the 64-entry NES RGB palette: it is reduced to one
most-common RGB value per PPU palette index, then the output pixels are drawn
from decoded CHR patterns, nametable/attributes, palette RAM, and OAM shadow.

Example (title frame from the current capture):
  python3 tools/render_emulator_ppu_frame.py \
    --capture-dir reference/opening_reference_capture --frame 4692 \
    --calibration-gd reference/opening_reference_capture/screens/frame_004692.gd \
    --output assets/opening/title_from_ppu.png

Use --palette-file with a 192-byte RGB palette file instead of screenshot
calibration when an emulator palette export is available. PPU/RAM raw dumps
and the calibration screenshot are read-only inputs and remain unchanged.
"""

from __future__ import annotations

import argparse
import binascii
import csv
import struct
import zlib
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

WIDTH = 256
HEIGHT = 240
PPU_BYTES = 12_320
RAM_BYTES = 2_048
GD_HEADER_BYTES = 11


def resolve_snapshot(capture_dir: Path, kind: str, frame: int) -> tuple[Path, int]:
    """Use exact snapshot if present, otherwise latest indexed snapshot <= frame."""
    folder = capture_dir / ("ppu_states" if kind == "ppu" else "ram_states")
    index_path = capture_dir / f"{kind}_index.csv"
    if not index_path.exists():
        # A few capture folders use the older emulator_ppu/index.csv layout.
        if kind == "ppu":
            index_path = capture_dir / "emulator_ppu" / "index.csv"
            folder = capture_dir / "emulator_ppu" / "states"
    if not index_path.exists():
        raise FileNotFoundError(f"Missing {kind} index: {index_path}")

    candidates: list[tuple[int, str]] = []
    with index_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            row_frame = int(row["frame"])
            if row_frame <= frame:
                name = row.get("raw_file") or row.get("file")
                if name:
                    candidates.append((row_frame, name))
    if not candidates:
        raise ValueError(f"No {kind} snapshot at or before requested frame {frame}")

    selected_frame, filename = max(candidates, key=lambda item: item[0])
    path = folder / filename
    if not path.is_file():
        raise FileNotFoundError(f"Indexed {kind} snapshot is missing: {path}")
    return path, selected_frame


def decode_tiles(patterns: bytes, tile_id: int, base: int, flip_x: bool = False,
                 flip_y: bool = False) -> list[list[int]]:
    """Decode one NES 8x8, 2bpp pattern tile into values 0..3."""
    offset = base + tile_id * 16
    if offset < 0 or offset + 16 > len(patterns):
        raise ValueError(f"Pattern tile {tile_id} at base 0x{base:04x} is out of range")
    pixels: list[list[int]] = []
    for y in range(8):
        source_y = 7 - y if flip_y else y
        low = patterns[offset + source_y]
        high = patterns[offset + source_y + 8]
        row = []
        for x in range(8):
            source_x = 7 - x if flip_x else x
            bit = 7 - source_x
            row.append(((low >> bit) & 1) | (((high >> bit) & 1) << 1))
        pixels.append(row)
    return pixels


def background_pixels(ppu: bytes, *, page: int, pattern_base: int,
                      scroll_x: int, scroll_y: int) -> tuple[list[int], list[bool]]:
    patterns = ppu[:0x2000]
    nametables = ppu[0x2000:0x3000]
    palette_ram = ppu[0x3000:0x3020]
    if len(ppu) != PPU_BYTES:
        raise ValueError(f"PPU state must be {PPU_BYTES} bytes, got {len(ppu)}")
    if not 0 <= page <= 3:
        raise ValueError("Nametable page must be between 0 and 3")
    if pattern_base not in (0, 0x1000):
        raise ValueError("Background pattern base must be 0 or 0x1000")

    result = [0] * (WIDTH * HEIGHT)
    opaque = [False] * (WIDTH * HEIGHT)
    tile_cache: dict[int, list[list[int]]] = {}
    for y in range(HEIGHT):
        world_y = y + scroll_y
        for x in range(WIDTH):
            world_x = x + scroll_x
            # The four 0x400-byte nametables form a 2x2 viewport grid.
            # Scrolling across an edge selects the adjacent virtual page;
            # wrapping tile coordinates inside one fixed page loses the
            # vertical/horizontal split used by opening cutscenes.
            page_x = ((page & 1) + world_x // WIDTH) & 1
            page_y = (((page >> 1) & 1) + world_y // HEIGHT) & 1
            page_offset = (page_x | (page_y << 1)) * 0x400
            tile_x = ((world_x % WIDTH) // 8)
            tile_y = ((world_y % HEIGHT) // 8)
            local_y = world_y & 7
            local_x = world_x & 7
            tile = nametables[page_offset + tile_y * 32 + tile_x]
            attr = nametables[page_offset + 960 + (tile_y // 4) * 8 + tile_x // 4]
            attr_shift = ((tile_y % 4) // 2) * 4 + ((tile_x % 4) // 2) * 2
            subpalette = (attr >> attr_shift) & 0x03
            decoded = tile_cache.get(tile)
            if decoded is None:
                decoded = decode_tiles(patterns, tile, pattern_base)
                tile_cache[tile] = decoded
            color = decoded[local_y][local_x]
            palette_address = 0 if color == 0 else subpalette * 4 + color
            index = y * WIDTH + x
            result[index] = palette_ram[palette_address] & 0x3F
            opaque[index] = color != 0
    return result, opaque


def render_sprites(ppu: bytes, ram: bytes, indices: list[int], background_opaque: list[bool],
                   *, enabled: bool, sprite_height: int, pattern_base: int,
                   y_offset: int) -> list[int]:
    if not enabled:
        return indices
    if len(ram) != RAM_BYTES:
        raise ValueError(f"RAM snapshot must be {RAM_BYTES} bytes, got {len(ram)}")
    patterns = ppu[:0x2000]
    palette_ram = ppu[0x3000:0x3020]
    result = indices.copy()
    # NES OAM index 0 has highest visual priority. Painting back-to-front makes
    # a lower index overwrite a higher index where sprites overlap.
    for oam_index in range(63, -1, -1):
        y, tile, attr, x = ram[0x200 + oam_index * 4:0x204 + oam_index * 4]
        if y >= 240 or x >= 256:
            continue
        top = y + y_offset
        palette_number = attr & 0x03
        behind_background = bool(attr & 0x20)
        flip_x = bool(attr & 0x40)
        flip_y = bool(attr & 0x80)
        for dy in range(sprite_height):
            screen_y = top + dy
            if not 0 <= screen_y < HEIGHT:
                continue
            source_y = sprite_height - 1 - dy if flip_y else dy
            if sprite_height == 8:
                tile_number = tile
                tile_base = pattern_base
                tile_row = source_y
            else:
                tile_base = (tile & 1) * 0x1000
                tile_number = (tile & 0xFE) + source_y // 8
                tile_row = source_y & 7
            decoded = decode_tiles(patterns, tile_number, tile_base,
                                   flip_x=flip_x, flip_y=False)
            row = decoded[tile_row]
            for dx in range(8):
                screen_x = x + dx
                if not 0 <= screen_x < WIDTH:
                    continue
                color = row[dx]
                if color == 0:
                    continue
                pixel = screen_y * WIDTH + screen_x
                if behind_background and background_opaque[pixel]:
                    continue
                result[pixel] = palette_ram[16 + palette_number * 4 + color] & 0x3F
    return result


def read_gd_reference(path: Path) -> list[tuple[int, int, int]]:
    data = path.read_bytes()
    if len(data) < GD_HEADER_BYTES:
        raise ValueError(f"FCEUX GD file is too short: {path}")
    width, height = struct.unpack(">HH", data[2:6])
    rgba = data[GD_HEADER_BYTES:]
    if (width, height) != (WIDTH, HEIGHT):
        raise ValueError(f"Calibration GD must be {WIDTH}x{HEIGHT}; got {width}x{height}")
    if len(rgba) != WIDTH * HEIGHT * 4:
        raise ValueError("FCEUX GD pixel payload length does not match its dimensions")
    # FCEUX GD stores A,R,G,B. The screenshot is used only to estimate a global
    # RGB value for each decoded NES palette index; output geometry comes only
    # from PPU/RAM, and individual screenshot pixels are never copied.
    return [tuple(rgba[i + 1:i + 4]) for i in range(0, len(rgba), 4)]


def read_palette_file(path: Path) -> list[tuple[int, int, int]]:
    data = path.read_bytes()
    if len(data) != 64 * 3:
        raise ValueError("Palette file must contain exactly 64 RGB triples (192 bytes)")
    return [tuple(data[i:i + 3]) for i in range(0, len(data), 3)]


def calibrate_palette(indices: list[int], reference: list[tuple[int, int, int]]) -> dict[int, tuple[int, int, int]]:
    samples: dict[int, Counter[tuple[int, int, int]]] = defaultdict(Counter)
    for palette_index, rgb in zip(indices, reference):
        samples[palette_index][rgb] += 1
    return {index: counts.most_common(1)[0][0] for index, counts in samples.items()}


def encode_png(path: Path, rgb_pixels: Iterable[tuple[int, int, int]]) -> None:
    pixels = bytearray()
    for red, green, blue in rgb_pixels:
        pixels.extend((red, green, blue))
    rows = b"".join(
        b"\x00" + pixels[y * WIDTH * 3:(y + 1) * WIDTH * 3]
        for y in range(HEIGHT)
    )

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF))

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(rows, 9))
           + chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-dir", type=Path, required=True,
                        help="FCEUX capture folder with PPU/RAM index CSVs and raw states")
    parser.add_argument("--frame", type=int, required=True,
                        help="Emulator frame; latest indexed PPU/RAM snapshots at or before it are used")
    parser.add_argument("--output", type=Path, required=True, help="Generated PNG output path")
    palette = parser.add_mutually_exclusive_group(required=True)
    palette.add_argument("--palette-file", type=Path,
                         help="192-byte emulator RGB palette (64 RGB triples)")
    palette.add_argument("--calibration-gd", type=Path,
                         help="FCEUX GD observation used only to calibrate the global RGB palette")
    parser.add_argument("--nametable-page", type=int, default=0, choices=range(4),
                        help="Assumed starting nametable page (default: 0)")
    parser.add_argument("--background-pattern-base", type=lambda v: int(v, 0), default=0,
                        choices=(0, 0x1000), help="Assumed PPUCTRL background table (default: 0)")
    parser.add_argument("--scroll-x", type=int, default=0, help="Assumed horizontal scroll in pixels")
    parser.add_argument("--scroll-y", type=int, default=0, help="Assumed vertical scroll in pixels")
    parser.add_argument("--no-sprites", action="store_true", help="Render background only")
    parser.add_argument("--sprite-height", type=int, default=8, choices=(8, 16),
                        help="Assumed sprite size in pixels (default: 8)")
    parser.add_argument("--sprite-pattern-base", type=lambda v: int(v, 0), default=0,
                        choices=(0, 0x1000), help="Assumed 8x8 sprite table (default: 0)")
    parser.add_argument("--oam-y-offset", type=int, default=1,
                        help="Add to OAM Y before drawing (NES top coordinate is usually Y+1)")
    args = parser.parse_args()

    ppu_path, ppu_frame = resolve_snapshot(args.capture_dir, "ppu", args.frame)
    ram_path, ram_frame = resolve_snapshot(args.capture_dir, "ram", args.frame)
    ppu = ppu_path.read_bytes()
    ram = ram_path.read_bytes()
    if len(ppu) != PPU_BYTES:
        raise ValueError(f"{ppu_path} has {len(ppu)} bytes; expected {PPU_BYTES}")
    if len(ram) != RAM_BYTES:
        raise ValueError(f"{ram_path} has {len(ram)} bytes; expected {RAM_BYTES}")

    bg_indices, bg_opaque = background_pixels(
        ppu, page=args.nametable_page, pattern_base=args.background_pattern_base,
        scroll_x=args.scroll_x, scroll_y=args.scroll_y)
    pixel_indices = render_sprites(
        ppu, ram, bg_indices, bg_opaque, enabled=not args.no_sprites,
        sprite_height=args.sprite_height, pattern_base=args.sprite_pattern_base,
        y_offset=args.oam_y_offset)

    observed_rgb: list[tuple[int, int, int]] | None = None
    if args.calibration_gd:
        observed_rgb = read_gd_reference(args.calibration_gd)
        colors = calibrate_palette(pixel_indices, observed_rgb)
        print(f"Palette calibrated from {len(colors)} used PPU color indices; "
              "the screenshot contributed global colors only.")
    else:
        palette_rgb = read_palette_file(args.palette_file)
        colors = {index: palette_rgb[index] for index in set(pixel_indices)}

    rgb = [colors[index] for index in pixel_indices]
    encode_png(args.output, rgb)
    print(f"Rendered frame {args.frame} using PPU snapshot {ppu_frame} ({ppu_path}) "
          f"and RAM snapshot {ram_frame} ({ram_path}).")
    print(f"Output: {args.output} ({WIDTH}x{HEIGHT}, RGB PNG); "
          f"nametable={args.nametable_page}, BG pattern base=0x{args.background_pattern_base:04x}, "
          f"sprites={'off' if args.no_sprites else args.sprite_height}, OAM Y offset={args.oam_y_offset}.")
    if observed_rgb is not None:
        matches = sum(a == b for a, b in zip(rgb, observed_rgb))
        print(f"Reference exact-pixel agreement: {matches}/{WIDTH * HEIGHT} "
              f"({matches / (WIDTH * HEIGHT):.2%}). This is a diagnostic metric, "
              "not proof of exact PPU reconstruction.")


if __name__ == "__main__":
    main()
