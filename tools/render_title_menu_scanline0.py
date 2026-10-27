#!/usr/bin/env python3
"""Build the title's first visible scanline from ROM/state, never screenshots."""

from __future__ import annotations

import argparse
import binascii
import csv
import hashlib
import json
import struct
import zlib
from pathlib import Path

from render_emulator_ppu_frame import read_palette_file
from render_rom_frame import extract_chr
from render_rom_raster_frame import render_band
from render_timing_capture_raster_frame import ppu_snapshot_legacy_layout


def write_rgb_png(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    if len(pixels) != 256:
        raise ValueError(f"Expected 256 scanline pixels, got {len(pixels)}")
    raw = b"\x00" + bytes(channel for rgb in pixels for channel in rgb)

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF))

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", 256, 1, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--frame", type=int, required=True, help="source frame key")
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--palette-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    with (args.capture_dir / "frames.csv").open(newline="", encoding="utf-8") as stream:
        rows = {int(row["source_frame"]): row for row in csv.DictReader(stream)}
    if args.frame not in rows:
        raise ValueError(f"No source frame {args.frame} in {args.capture_dir / 'frames.csv'}")
    frame_row = rows[args.frame]
    ppu_path = args.capture_dir / "ppu_states" / frame_row["ppu_file"]
    ram_path = args.capture_dir / "ram_states" / frame_row["ram_file"]
    ppu = ppu_snapshot_legacy_layout(ppu_path)
    ram = ram_path.read_bytes()
    if len(ram) != 2048:
        raise ValueError(f"Expected 2 KiB CPU RAM snapshot, got {len(ram)}")

    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    bands = plan.get("bands")
    if not isinstance(bands, list) or not bands:
        raise ValueError("Raster plan has no bands")
    band = next((item for item in bands if item.get("start_y") == 0), None)
    if not isinstance(band, dict):
        raise ValueError("Raster plan has no band beginning at row 0")
    chr_rom, chr_offset, rom_hash = extract_chr(args.rom)
    indices = render_band(chr_rom, ppu, ram, band)[:256]
    palette = read_palette_file(args.palette_file)
    pixels = [palette[index] for index in indices]
    write_rgb_png(args.output, pixels)

    metadata = {
        "asset": args.output.name,
        "dimensions": [256, 1],
        "source_rom": args.rom.name,
        "rom_sha256": rom_hash,
        "chr_file_offset": f"0x{chr_offset:X}",
        "chr_banks_by_ppu_slot": band["chr_banks_by_ppu_slot"],
        "capture_directory": str(args.capture_dir),
        "source_frame": args.frame,
        "script_frame": int(frame_row["script_frame"]),
        "emulator_frame_after": int(frame_row["emulator_frame_after"]),
        "ppu_source": str(ppu_path),
        "ppu_source_sha256": hashlib.sha256(ppu_path.read_bytes()).hexdigest(),
        "ppu_normalization": "captured PPU $0000-$2FFF plus palette RAM $3F00-$3F1F; CHR patterns replaced by mapped bytes from the supplied ROM",
        "ram_source": str(ram_path),
        "ram_source_sha256": hashlib.sha256(ram_path.read_bytes()).hexdigest(),
        "raster_plan": str(args.plan),
        "palette_file_external_to_rom": str(args.palette_file),
        "background_register_state": {
            "nametable_page": band["nametable_page"],
            "pattern_base": band["background_pattern_base"],
            "scroll_x": band["scroll_x"],
            "scroll_y": band["scroll_y"],
        },
        "decode_method": "NES loopy first-visible-line fetch: coarseY=31, fineY=7 for scrollY=$FF; nametable offsets $3E0-$3FF supply tile IDs; 2bpp pixels and RGB palette decoded from ROM CHR and captured PPU palette state",
        "screenshot_pixels_used_for_asset": False,
        "comparison_reference": "reference/opening_reference_capture/screens/frame_004692.gd (validation only; not read during asset generation)",
    }
    args.output.with_suffix(".json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote ROM-derived 256x1 title scanline: {args.output}")


if __name__ == "__main__":
    main()
