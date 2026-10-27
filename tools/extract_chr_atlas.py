#!/usr/bin/env python3
"""Extract exact 2bpp CHR bytes and decode their pixel indices to a PNG atlas."""

from __future__ import annotations

import argparse
import binascii
import struct
import zlib
from pathlib import Path


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    body = kind + payload
    return struct.pack(">I", len(payload)) + body + struct.pack(">I", binascii.crc32(body) & 0xFFFFFFFF)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--columns", type=int, default=32)
    parser.add_argument(
        "--raw-output",
        type=Path,
        help="also write the exact CHR-ROM bytes (defaults to OUTPUT with .2bpp extension)",
    )
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    if len(rom) < 16 or rom[:4] != b"NES\x1a":
        raise SystemExit("Not an iNES ROM")

    flags6 = rom[6]
    prg_size = rom[4] * 16_384
    chr_size = rom[5] * 8_192
    trainer_size = 512 if flags6 & 0x04 else 0
    if chr_size == 0:
        raise SystemExit("ROM has CHR-RAM, not embedded CHR-ROM")

    chr_start = 16 + trainer_size + prg_size
    chr_data = rom[chr_start : chr_start + chr_size]
    if len(chr_data) != chr_size or chr_size % 16:
        raise SystemExit("Invalid or truncated CHR-ROM data")

    raw_output = args.raw_output or args.output.with_suffix(".2bpp")
    raw_output.parent.mkdir(parents=True, exist_ok=True)
    raw_output.write_bytes(chr_data)

    tile_count = len(chr_data) // 16
    columns = max(1, args.columns)
    rows = (tile_count + columns - 1) // columns
    width, height = columns * 8, rows * 8
    scanlines = bytearray()
    shades = (0, 85, 170, 255)

    for y in range(height):
        scanlines.append(0)  # PNG filter: None
        tile_y, pixel_y = divmod(y, 8)
        for tile_x in range(columns):
            tile_index = tile_y * columns + tile_x
            if tile_index >= tile_count:
                scanlines.extend(b"\x00\x00\x00\xff" * 8)
                continue
            offset = tile_index * 16
            plane0 = chr_data[offset + pixel_y]
            plane1 = chr_data[offset + 8 + pixel_y]
            for pixel_x in range(8):
                bit = 7 - pixel_x
                value = ((plane0 >> bit) & 1) | (((plane1 >> bit) & 1) << 1)
                shade = shades[value]
                scanlines.extend((shade, shade, shade, 255))

    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
    png.extend(png_chunk(b"IDAT", zlib.compress(bytes(scanlines), level=9)))
    png.extend(png_chunk(b"IEND", b""))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(png)
    print(
        f"Extracted {chr_size} exact CHR bytes to {raw_output}; "
        f"decoded {tile_count} 2bpp pixel-index tiles to {args.output} ({width}x{height})"
    )


if __name__ == "__main__":
    main()
