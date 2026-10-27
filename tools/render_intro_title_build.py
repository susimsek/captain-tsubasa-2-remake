#!/usr/bin/env python3
"""Render the intro's two-sided title assembly from original ROM CHR bytes.

The ROM uses page 0 for the descending logo and rising menu, page 1 for a
blank middle band, and a fixed trophy sprite. The PPU write trace identifies
the title CHR bank and upper scroll sequence; the missed second-scroll latch
is reconstructed from the ROM title nametable and frame timing. Screenshots
are comparison references only and are never read here.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from plan_rom_raster_bands import load_events, make_plan
from render_emulator_ppu_frame import encode_png, read_palette_file, resolve_snapshot
from render_rom_frame import extract_chr
from render_rom_raster_frame import render_band


def title_bands(frame: int, base: dict[str, object]) -> list[dict[str, object]]:
    if frame % 2 or not 3602 <= frame <= 3652:
        raise ValueError("Title assembly is indexed on even frames 3602..3652")
    offset = 2 * (3654 - frame)
    upper_end = 129 - offset
    lower_start = 125 + offset
    upper = {**base, "start_y": 0, "end_y": upper_end,
             "nametable_page": 0, "scroll_x": 0, "scroll_y": offset - 1,
             "sprites_enabled": True, "background_enabled": True}
    middle = {**base, "start_y": upper_end, "end_y": lower_start,
              "nametable_page": 1, "scroll_x": 0, "scroll_y": 0,
              "sprites_enabled": True, "background_enabled": True}
    lower = {**base, "start_y": lower_start, "end_y": 240,
             "nametable_page": 0, "scroll_x": 0,
             "scroll_y": (243 - offset) % 240,
             "sprites_enabled": True, "background_enabled": True}
    if frame == 3602:
        # First visible title-build frame still has a blank lower page.
        lower["nametable_page"] = 1
        lower["scroll_y"] = 0
    elif frame == 3604:
        # The lower scroll begins one command later than the upper scroll.
        middle["end_y"] = 228
        lower["start_y"] = 228
        lower["scroll_y"] = 139
    return [upper, middle, lower]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--trace", type=Path, required=True)
    parser.add_argument("--palette-file", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    chr_rom, chr_offset, rom_hash = extract_chr(args.rom)
    palette = read_palette_file(args.palette_file)
    events = load_events(args.trace)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for frame in range(3602, 3654, 2):
        trace_plan = make_plan(args.trace, frame, 0, trace_events=events)
        bands = title_bands(frame, trace_plan["bands"][-1])
        ppu_path, ppu_frame = resolve_snapshot(args.capture_dir, "ppu", frame)
        ram_path, ram_frame = resolve_snapshot(args.capture_dir, "ram", frame - 1)
        ppu = ppu_path.read_bytes()
        ram = ram_path.read_bytes()
        indices: list[int] = []
        for band in bands:
            rendered = render_band(chr_rom, ppu, ram, band)
            start = int(band["start_y"]) * 256
            end = int(band["end_y"]) * 256
            indices.extend(rendered[start:end])
        if len(indices) != 256 * 240:
            raise AssertionError(f"Frame {frame} raster bands do not cover 240 lines")
        stem = f"frame_{frame:06d}"
        encode_png(args.output_dir / f"{stem}.png", (palette[index] for index in indices))
        metadata = {
            "requested_capture_frame": frame,
            "ppu_snapshot_frame": ppu_frame,
            "ram_snapshot_frame": ram_frame,
            "ppu_exact": ppu_frame == frame,
            "ram_exact": ram_frame == frame,
            "ram_source_frame_offset": -1,
            "rom_sha256": rom_hash,
            "chr_file_offset": f"0x{chr_offset:X}",
            "layout_source": str(ppu_path),
            "oam_source": str(ram_path),
            "trace_reference": str(args.trace),
            "palette_source": str(args.palette_file),
            "raster_bands": bands,
            "timing_model": "Upper page-0 scroll is 2*(3654-frame)-1; lower page-0 scroll is (243-2*(3654-frame)) mod 240, with page-1 blank middle band. First two frames have ROM command-entry exceptions.",
            "screenshot_pixels_used": False,
        }
        (args.output_dir / f"{stem}.json").write_text(
            json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered 26 title-assembly frames to {args.output_dir}")


if __name__ == "__main__":
    main()
