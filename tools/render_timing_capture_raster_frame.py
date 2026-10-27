#!/usr/bin/env python3
"""Render one source-frame from a timing capture and ROM CHR raster plan.

The timing capture stores a 16 KiB PPU address-space dump. The existing ROM
raster renderer expects 8 KiB CHR + 4 KiB nametable + 32 bytes palette, so this
tool normalizes only those captured regions in memory. No screenshot pixels are
read. Outputs are diagnostic references, not runtime game assets.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

from render_emulator_ppu_frame import encode_png, read_palette_file
from render_rom_frame import extract_chr
from render_rom_raster_frame import render_band


def frame_rows(capture: Path) -> dict[int, dict[str, str]]:
    rows: dict[int, dict[str, str]] = {}
    with (capture / "frames.csv").open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            key = int(row.get("source_frame", row["script_frame"]))
            rows[key] = row
    return rows


def ppu_snapshot_legacy_layout(path: Path) -> bytes:
    raw = path.read_bytes()
    if len(raw) != 0x4000:
        raise ValueError(f"Expected 16 KiB PPU address-space capture, got {len(raw)} bytes: {path}")
    # Keep $0000-$2FFF; take palette RAM from its canonical $3F00 address.
    normalized = raw[:0x3000] + raw[0x3F00:0x3F20]
    if len(normalized) != 12_320:
        raise AssertionError("Unexpected normalized PPU snapshot length")
    return normalized


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--frame", type=int, required=True,
                        help="source_frame key from frames.csv")
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--palette-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ram-frame-offset", type=int, default=0,
                        help="Use the RAM snapshot at source_frame + offset (default 0)")
    args = parser.parse_args()

    frames = frame_rows(args.capture_dir)
    if args.frame not in frames:
        raise ValueError(f"No source_frame {args.frame} record in {args.capture_dir / 'frames.csv'}")
    render_row = frames[args.frame]
    ram_frame = args.frame + args.ram_frame_offset
    if ram_frame not in frames:
        raise ValueError(f"No RAM snapshot frame {ram_frame} for requested frame {args.frame}")
    ram_row = frames[ram_frame]
    ppu_path = args.capture_dir / "ppu_states" / render_row["ppu_file"]
    ram_path = args.capture_dir / "ram_states" / ram_row["ram_file"]
    ppu = ppu_snapshot_legacy_layout(ppu_path)
    ram = ram_path.read_bytes()
    if len(ram) != 2_048:
        raise ValueError(f"Expected 2 KiB CPU RAM snapshot, got {len(ram)} bytes: {ram_path}")

    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    bands = plan.get("bands")
    if not isinstance(bands, list) or not bands:
        raise ValueError("Plan must contain a nonempty bands array")
    chr_rom, chr_offset, rom_hash = extract_chr(args.rom)
    palette = read_palette_file(args.palette_file)
    result: list[int | None] = [None] * (256 * 240)
    for band in bands:
        start, end = band.get("start_y"), band.get("end_y")
        if not isinstance(start, int) or not isinstance(end, int) or not 0 <= start < end <= 240:
            raise ValueError(f"Invalid scanline band [{start}, {end})")
        rendered = render_band(chr_rom, ppu, ram, band)
        start_pixel, end_pixel = start * 256, end * 256
        if any(pixel is not None for pixel in result[start_pixel:end_pixel]):
            raise ValueError(f"Overlapping scanline band [{start}, {end})")
        result[start_pixel:end_pixel] = rendered[start_pixel:end_pixel]
    if any(pixel is None for pixel in result):
        raise ValueError("Raster plan does not cover all 240 scanlines")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    encode_png(args.output, (palette[pixel] for pixel in result if pixel is not None))
    metadata = {
        "source_rom": args.rom.name,
        "rom_sha256": rom_hash,
        "chr_file_offset": f"0x{chr_offset:X}",
        "capture_directory": str(args.capture_dir),
        "capture_frame_key": args.frame,
        "source_frame": int(render_row.get("source_frame", args.frame)),
        "script_frame": int(render_row["script_frame"]),
        "emulator_frame_after": int(render_row.get("emulator_frame_after", render_row.get("emulator_frame", -1))),
        "cycle_start": int(render_row["cycle_start"]),
        "cycle_end": int(render_row["cycle_end"]),
        "ppu_source": str(ppu_path),
        "ppu_source_sha256": hashlib.sha256(ppu_path.read_bytes()).hexdigest(),
        "ppu_normalization": "captured PPU $0000-$2FFF plus palette RAM $3F00-$3F1F, concatenated to legacy renderer layout; CHR banks replaced per band from ROM",
        "ram_source": str(ram_path),
        "ram_source_frame": ram_frame,
        "ram_frame_offset": args.ram_frame_offset,
        "raster_plan": str(args.plan),
        "trace_reference": plan.get("trace_reference"),
        "palette_file_external_to_rom": str(args.palette_file),
        "bands": bands,
        "validation_status": plan.get("validation_status"),
        "screenshot_pixels_used": False,
    }
    args.output.with_suffix(".json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered source_frame {args.frame} (script_frame {render_row['script_frame']}, "
          f"emulator_frame_after {metadata['emulator_frame_after']}) from ROM CHR "
          f"with {len(bands)} raster bands: {args.output}")


if __name__ == "__main__":
    main()
