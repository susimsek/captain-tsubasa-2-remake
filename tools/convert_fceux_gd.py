#!/usr/bin/env python3
"""Convert FCEUX's GD screenshots to PNG using only the Python standard library."""

from __future__ import annotations

import argparse
import binascii
import struct
import zlib
from pathlib import Path


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", binascii.crc32(kind + data) & 0xFFFFFFFF)
    )


def gd_to_png(source: Path, destination: Path) -> None:
    data = source.read_bytes()
    if len(data) < 11:
        raise ValueError(f"{source}: not a complete FCEUX GD image")

    # FCEUX GD v1 uses big-endian 16-bit width/height at bytes 2..5.
    width, height = struct.unpack(">HH", data[2:6])
    pixels = data[11:]
    if len(pixels) != width * height * 4:
        raise ValueError(
            f"{source}: header says {width}x{height}, "
            f"but pixel payload has {len(pixels)} bytes"
        )

    # FCEUX documents pixels as Alpha, Red, Green, Blue; alpha is always 0.
    rgb = bytearray(width * height * 3)
    rgb[0::3] = pixels[1::4]
    rgb[1::3] = pixels[2::4]
    rgb[2::3] = pixels[3::4]
    scanlines = b"".join(
        b"\x00" + rgb[y * width * 3 : (y + 1) * width * 3]
        for y in range(height)
    )
    png = (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(scanlines, level=9))
        + png_chunk(b"IEND", b"")
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(png)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Folder containing .gd captures")
    parser.add_argument("destination", type=Path, help="Folder to write .png captures")
    args = parser.parse_args()
    files = sorted(args.source.glob("*.gd"))
    for source in files:
        gd_to_png(source, args.destination / f"{source.stem}.png")
    print(f"Converted {len(files)} GD screenshots to PNG in {args.destination}")


if __name__ == "__main__":
    main()
