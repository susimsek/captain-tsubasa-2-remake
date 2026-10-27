#!/usr/bin/env python3
"""Render an indexed FCEUX intro timeline from ROM CHR and PPU/RAM snapshots.

Screenshots are never read. The screen index supplies only changed-frame IDs
and durations; pixels are rebuilt from the ROM's CHR banks, PPU nametables and
palette snapshot, RAM OAM, and the PPU/MMC3 write trace.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

from plan_rom_raster_bands import load_events, make_plan
from render_rom_frame import extract_chr
from render_rom_raster_frame import render_band
from render_emulator_ppu_frame import encode_png, read_palette_file, resolve_snapshot


def first_ppu_scroll_write_by_frame(trace: Path) -> dict[int, int]:
    """Recover the X scroll that follows each frame's PPUSTATUS latch reset.

    The generic raster planner lacks $2002 reads, so its $2005 write toggle
    can drift. FCEUX's trace records frame IDs and preserves write order.
    """
    first: dict[int, int] = {}
    with trace.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["address"] == "0x2005":
                first.setdefault(int(row["frame"]), int(row["value"], 16))
    return first


def rom_prefetch_top_row(chr_rom: bytes, ppu: bytes,
                         palette: list[tuple[int, int, int]],
                         scroll_x: int, first_page: int) -> list[tuple[int, int, int]]:
    """Rebuild the opening's one-scanline tile-prefetch artifact from ROM.

    CHR bank 61 tile 0x15 row 7 has the repeated color-code sequence visible
    before the normal background starts. The palette comes from PPU RAM;
    nametable page 1 is blank, page 0 repeats this source tile across X.
    """
    bank_start = 61 * 1024
    tile_start = bank_start + 0x15 * 16
    low = chr_rom[tile_start + 7]
    high = chr_rom[tile_start + 15]
    colors = [((low >> (7 - x)) & 1) | (((high >> (7 - x)) & 1) << 1)
              for x in range(8)]
    ppu_palette = ppu[0x3000:0x3020]
    result: list[tuple[int, int, int]] = []
    for x in range(256):
        world_x = x + scroll_x
        page = (first_page + world_x // 256) & 1
        palette_index = (ppu_palette[4 + colors[world_x % 8]] if page == 0
                         else ppu_palette[0]) & 0x3F
        result.append(palette[palette_index])
    return result


def screen_frames(capture_dir: Path, start: int, end: int) -> list[int]:
    with (capture_dir / "screen_index.csv").open(newline="", encoding="utf-8") as stream:
        frames = [int(row["frame"]) for row in csv.DictReader(stream)]
    selected = [frame for frame in frames if start <= frame <= end]
    if not selected:
        raise ValueError("No indexed screen frames in the requested interval")
    return selected


def render(plan: dict, chr_rom: bytes, ppu: bytes, ram: bytes,
           palette: list[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    pixels: list[int | None] = [None] * (256 * 240)
    for band in plan["bands"]:
        start = int(band["start_y"])
        end = int(band["end_y"])
        rendered = render_band(chr_rom, ppu, ram, band)
        lo, hi = start * 256, end * 256
        pixels[lo:hi] = rendered[lo:hi]
    if any(pixel is None for pixel in pixels):
        raise ValueError("Raster bands did not cover the full frame")
    return [palette[index] for index in pixels if index is not None]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--trace", type=Path, required=True)
    parser.add_argument("--palette-file", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--start-frame", type=int, default=10)
    parser.add_argument("--end-frame", type=int, required=True)
    parser.add_argument("--duration-end-frame", type=int,
                        help="Frame after the final visible frame; defaults to end-frame + 1")
    parser.add_argument("--scroll-override", action="append", default=[], metavar="START:END:Y",
                        help="Calibrated scroll Y for inclusive frame range, e.g. 380:1078:239")
    parser.add_argument("--page-override", type=int, choices=range(4))
    parser.add_argument("--ram-source-frame-offset", type=int, default=0,
                        help="Resolve OAM shadow from capture frame + offset. "
                             "FCEUX screen captures usually show previous-frame OAM at offset -1.")
    parser.add_argument("--lower-band-scroll-bias", action="append", default=[],
                        metavar="START:END:BIAS",
                        help="Apply a calibrated Y-scroll bias only to lower dialogue bands")
    parser.add_argument("--goal-pan-range", metavar="START:END",
                        help="Map goal background from page 1 using the frame's first $2005 X write")
    parser.add_argument("--rom-prefetch-top-row-range", action="append", default=[],
                        metavar="START:END",
                        help="Rebuild the field's first raster line from ROM CHR bank 61")
    parser.add_argument("--complete", action="store_true",
                        help="Mark complete only after a reviewer confirms full timing coverage")
    args = parser.parse_args()

    overrides: list[tuple[int, int, int]] = []
    for value in args.scroll_override:
        try:
            first, last, scroll = (int(part) for part in value.split(":"))
        except (TypeError, ValueError) as error:
            parser.error(f"invalid --scroll-override {value!r}; expected START:END:Y")
        if first > last or not 0 <= scroll <= 255:
            parser.error(f"invalid --scroll-override range/value: {value!r}")
        overrides.append((first, last, scroll))

    lower_bias_ranges: list[tuple[int, int, int]] = []
    for value in args.lower_band_scroll_bias:
        try:
            first, last, bias = (int(part) for part in value.split(":"))
        except (TypeError, ValueError):
            parser.error(f"invalid --lower-band-scroll-bias {value!r}; expected START:END:BIAS")
        if first > last:
            parser.error(f"invalid --lower-band-scroll-bias range: {value!r}")
        lower_bias_ranges.append((first, last, bias))

    goal_pan_range: tuple[int, int] | None = None
    if args.goal_pan_range:
        try:
            goal_first, goal_last = (int(part) for part in args.goal_pan_range.split(":"))
        except (TypeError, ValueError):
            parser.error("invalid --goal-pan-range; expected START:END")
        if goal_first > goal_last:
            parser.error("invalid --goal-pan-range: START exceeds END")
        goal_pan_range = (goal_first, goal_last)
    prefetch_ranges: list[tuple[int, int]] = []
    for value in args.rom_prefetch_top_row_range:
        try:
            first, last = (int(part) for part in value.split(":"))
        except (TypeError, ValueError):
            parser.error(f"invalid --rom-prefetch-top-row-range {value!r}; expected START:END")
        if first > last:
            parser.error(f"invalid --rom-prefetch-top-row-range: {value!r}")
        prefetch_ranges.append((first, last))

    frames = screen_frames(args.capture_dir, args.start_frame, args.end_frame)
    timeline_end = args.duration_end_frame or (args.end_frame + 1)
    chr_rom, chr_file_offset, rom_hash = extract_chr(args.rom)
    palette = read_palette_file(args.palette_file)
    trace_events = load_events(args.trace)
    scroll_x_by_frame = (first_ppu_scroll_write_by_frame(args.trace)
                         if goal_pan_range or prefetch_ranges else {})
    args.output_dir.mkdir(parents=True, exist_ok=True)

    manifest_entries: list[dict[str, object]] = []
    details: list[dict[str, object]] = []
    for index, frame in enumerate(frames):
        next_frame = frames[index + 1] if index + 1 < len(frames) else timeline_end
        duration = max(1, next_frame - frame)
        scroll_y = next((y for first, last, y in overrides if first <= frame <= last), None)
        plan = make_plan(args.trace, frame, 0, 0 if scroll_y is not None else None,
                         scroll_y, args.page_override, trace_events)
        lower_bias = next((bias for first, last, bias in lower_bias_ranges
                           if first <= frame <= last), 0)
        goal_scroll_x: int | None = None
        if goal_pan_range and goal_pan_range[0] <= frame <= goal_pan_range[1]:
            goal_scroll_x = scroll_x_by_frame.get(frame)
            # The first goal capture precedes the scroll update's visible frame.
            if frame == goal_pan_range[0] and goal_scroll_x == 0:
                goal_scroll_x = 255
            if goal_scroll_x is None:
                raise ValueError(f"Missing first $2005 write for goal-pan frame {frame}")
        for band in plan["bands"]:
            banks = band["chr_banks_by_ppu_slot"]
            if (goal_scroll_x is not None and banks[:4] == [60, 61, 76, 77]):
                band["nametable_page"] = 1
                band["scroll_x"] = goal_scroll_x
            if (lower_bias and int(band["start_y"]) >= 130
                    and banks[:4] == [0, 1, 2, 3]
                    and band["scroll_y"] == 239):
                band["scroll_y"] = (239 + lower_bias) & 0xFF
        ppu_path, ppu_frame = resolve_snapshot(args.capture_dir, "ppu", frame)
        ram_path, ram_frame = resolve_snapshot(
            args.capture_dir, "ram", frame + args.ram_source_frame_offset)
        rgb = render(plan, chr_rom, ppu_path.read_bytes(), ram_path.read_bytes(), palette)
        prefetch_top_row = any(first <= frame <= last
                               for first, last in prefetch_ranges)
        if prefetch_top_row:
            prefetch_scroll_x = scroll_x_by_frame.get(frame)
            if goal_scroll_x is not None:
                prefetch_scroll_x = goal_scroll_x
            if prefetch_scroll_x is None:
                raise ValueError(f"Missing first $2005 write for prefetch frame {frame}")
            rgb[:256] = rom_prefetch_top_row(
                chr_rom, ppu_path.read_bytes(), palette,
                prefetch_scroll_x, 1 if goal_scroll_x is not None else 0)
        name = f"frame_{frame:06d}.png"
        encode_png(args.output_dir / name, rgb)
        (args.output_dir / f"frame_{frame:06d}.json").write_text(
            json.dumps({
                "requested_capture_frame": frame,
                "duration_frames": duration,
                "ppu_snapshot_frame": ppu_frame,
                "ram_snapshot_frame": ram_frame,
                "ppu_exact": ppu_frame == frame,
                "ram_exact": ram_frame == frame,
                "ram_source_frame_offset": args.ram_source_frame_offset,
                "scroll_y_override": scroll_y,
                "lower_band_scroll_bias": lower_bias,
                "goal_scroll_x_first_2005": goal_scroll_x,
                "rom_prefetch_top_row": prefetch_top_row,
                "raster_plan": plan,
                "rom_sha256": rom_hash,
                "chr_file_offset": f"0x{chr_file_offset:X}",
                "layout_source": str(ppu_path),
                "oam_source": str(ram_path),
                "palette_source": str(args.palette_file),
                "screenshot_pixels_used": False,
            }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        manifest_entries.append({
            "path": f"res://assets/opening/intro/captured/{name}",
            "duration_frames": duration,
        })
        details.append({
            "frame": frame, "duration_frames": duration,
            "ppu_snapshot_frame": ppu_frame, "ram_snapshot_frame": ram_frame,
            "ram_source_frame_offset": args.ram_source_frame_offset,
            "scroll_y_override": scroll_y, "bands": len(plan["bands"]),
            "lower_band_scroll_bias": lower_bias,
            "goal_scroll_x_first_2005": goal_scroll_x,
            "rom_prefetch_top_row": prefetch_top_row,
        })

    manifest = {
        "fps": 60.0988,
        "complete": bool(args.complete),
        "audio_start_frame": 283,
        "frames": manifest_entries,
        "provenance": {
            "method": "ROM CHR bytes + emulator-native PPU nametable/palette and RAM OAM snapshots + PPU/MMC3 write trace",
            "rom_sha256": rom_hash,
            "capture_directory": str(args.capture_dir),
            "trace": str(args.trace),
            "ram_source_frame_offset": args.ram_source_frame_offset,
            "lower_band_scroll_bias_ranges": lower_bias_ranges,
            "goal_pan_range": goal_pan_range,
            "rom_prefetch_top_row_ranges": prefetch_ranges,
            "screen_index_role": "frame IDs and intervals only; no screenshot pixels read",
            "limitations": "PPUSTATUS read latch and sub-scanline state are not present in the trace. Scroll overrides are explicit calibration assumptions. Review all frames before setting complete true.",
        },
    }
    args.output_dir.joinpath("frame_manifest_candidate.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    args.output_dir.joinpath("frame_details.json").write_text(
        json.dumps(details, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered {len(frames)} changed-screen frames ({frames[0]}..{frames[-1]}) to {args.output_dir}")
    print(f"Manifest marked complete={bool(args.complete)}")


if __name__ == "__main__":
    main()
