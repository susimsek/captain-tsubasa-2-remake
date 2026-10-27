#!/usr/bin/env python3
"""Convert an FCEUX PPU/MMC3 write trace into a diagnostic raster-band plan.

This tool reads register writes only. It never opens the ROM or screenshot.
Plans are inputs to render_rom_raster_frame.py; they remain diagnostic until
PPUSTATUS latch resets, vblank phase, and any mid-scanline changes are checked.
"""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import asdict, dataclass
from pathlib import Path

WIDTH = 256
HEIGHT = 240
NTSC_CPU_CYCLES_PER_FRAME = 29_780
PPU_DOTS_PER_SCANLINE = 341
CPU_CYCLES_PER_PPU_DOT = 1 / 3
VBLANK_SCANLINES = 21


@dataclass
class State:
    ppu_ctrl: int = 0
    ppu_mask: int = 0
    scroll_x: int = 0
    scroll_y: int = 0
    scroll_next_is_y: bool = False
    mmc3_select: int = 0
    mmc3_banks: list[int] | None = None

    def __post_init__(self) -> None:
        if self.mmc3_banks is None:
            self.mmc3_banks = [0] * 8

    def chr_slots(self) -> list[int]:
        assert self.mmc3_banks is not None
        regs = self.mmc3_banks
        pair0 = [regs[0] & 0x7E, (regs[0] + 1) & 0x7F]
        pair1 = [regs[1] & 0x7E, (regs[1] + 1) & 0x7F]
        single = [value & 0x7F for value in regs[2:6]]
        return (single + pair0 + pair1) if self.mmc3_select & 0x80 else (pair0 + pair1 + single)

    def band(self, start_y: int, end_y: int, scroll_y_bias: int,
             scroll_x_override: int | None, scroll_y_override: int | None,
             page_override: int | None) -> dict[str, object]:
        return {
            "start_y": start_y,
            "end_y": end_y,
            "chr_banks_by_ppu_slot": self.chr_slots(),
            "nametable_page": (self.ppu_ctrl & 0x03) if page_override is None else page_override,
            "background_pattern_base": 0x1000 if self.ppu_ctrl & 0x10 else 0,
            "sprite_pattern_base": 0x1000 if self.ppu_ctrl & 0x08 else 0,
            "scroll_x": self.scroll_x if scroll_x_override is None else scroll_x_override,
            "scroll_y": ((self.scroll_y + scroll_y_bias) & 0xFF)
            if scroll_y_override is None else scroll_y_override,
            "sprites_enabled": bool(self.ppu_mask & 0x10),
            "background_enabled": bool(self.ppu_mask & 0x08),
            "sprite_height": 16 if self.ppu_ctrl & 0x20 else 8,
            "oam_y_offset": 1,
        }


def apply_write(state: State, address: int, value: int) -> None:
    if address == 0x8000:
        state.mmc3_select = value
    elif address == 0x8001:
        assert state.mmc3_banks is not None
        state.mmc3_banks[state.mmc3_select & 0x07] = value
    elif address == 0x2000:
        state.ppu_ctrl = value
    elif address == 0x2001:
        state.ppu_mask = value
    elif address == 0x2005:
        if state.scroll_next_is_y:
            state.scroll_y = value
        else:
            state.scroll_x = value
        state.scroll_next_is_y = not state.scroll_next_is_y
    elif address == 0x2006:
        # $2005 and $2006 share the PPU's two-write latch. The trace does not
        # contain $2002 reads, so read-triggered latch resets remain unknown.
        state.scroll_next_is_y = not state.scroll_next_is_y


def relevant(address: int) -> bool:
    return address in {0x2000, 0x2001, 0x2005, 0x2006, 0x8000, 0x8001}


def state_key(state: State, scroll_y_bias: int, scroll_x_override: int | None,
              scroll_y_override: int | None, page_override: int | None) -> tuple[object, ...]:
    return (
        tuple(state.chr_slots()), state.ppu_ctrl & 0xFC, state.ppu_mask,
        state.scroll_x if scroll_x_override is None else scroll_x_override,
        ((state.scroll_y + scroll_y_bias) & 0xFF)
        if scroll_y_override is None else scroll_y_override,
        (state.ppu_ctrl & 0x03) if page_override is None else page_override,
    )


def load_events(trace: Path) -> list[tuple[int, int, int]]:
    events: list[tuple[int, int, int]] = []
    with trace.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            address = int(row["address"], 16)
            if relevant(address):
                events.append((int(row["cpu_cycles"]), address, int(row["value"], 16)))
    events.sort()
    return events


def make_plan(trace: Path, frame: int, scroll_y_bias: int,
              scroll_x_override: int | None = None,
              scroll_y_override: int | None = None,
              page_override: int | None = None,
              trace_events: list[tuple[int, int, int]] | None = None) -> dict[str, object]:
    events = load_events(trace) if trace_events is None else trace_events

    frame_start = (frame - 1) * NTSC_CPU_CYCLES_PER_FRAME
    visible_start = frame_start + round(
        VBLANK_SCANLINES * PPU_DOTS_PER_SCANLINE / 3
    )
    frame_end = frame_start + NTSC_CPU_CYCLES_PER_FRAME
    state = State()
    line_events: dict[int, list[tuple[int, int]]] = {}
    for cycle, address, value in events:
        if cycle < frame_start:
            apply_write(state, address, value)
        elif cycle < visible_start:
            apply_write(state, address, value)
        elif cycle < frame_end:
            y = ((cycle - visible_start) * 3) // PPU_DOTS_PER_SCANLINE
            if 0 <= y < HEIGHT:
                line_events.setdefault(y, []).append((address, value))

    bands: list[dict[str, object]] = []
    start_y = 0
    current = state
    previous_key = state_key(current, scroll_y_bias, scroll_x_override,
                             scroll_y_override, page_override)
    for y in range(HEIGHT):
        if y in line_events:
            for address, value in line_events[y]:
                apply_write(current, address, value)
        key = state_key(current, scroll_y_bias, scroll_x_override,
                        scroll_y_override, page_override)
        if key != previous_key:
            if y > start_y:
                bands.append(current_band.copy())
                bands[-1]["end_y"] = y
            start_y = y
            current_band = current.band(y, HEIGHT, scroll_y_bias, scroll_x_override,
                                        scroll_y_override, page_override)
            previous_key = key
        elif y == 0:
            current_band = current.band(0, HEIGHT, scroll_y_bias, scroll_x_override,
                                        scroll_y_override, page_override)
    if not bands or bands[-1].get("end_y") != HEIGHT:
        current_band["end_y"] = HEIGHT
        bands.append(current_band)

    return {
        "validation_status": "diagnostic plan; PPUSTATUS latch reads and mid-scanline timing are not traced",
        "trace_reference": str(trace),
        "frame": frame,
        "frame_start_cpu_cycle": frame_start,
        "visible_start_cpu_cycle": visible_start,
        "cpu_cycles_per_frame_assumption": NTSC_CPU_CYCLES_PER_FRAME,
        "vblank_scanlines_assumption": VBLANK_SCANLINES,
        "scroll_y_bias_assumption": scroll_y_bias,
        "scroll_x_override_assumption": scroll_x_override,
        "scroll_y_override_assumption": scroll_y_override,
        "nametable_page_override_assumption": page_override,
        "bands": bands,
    }


def exact_capture_frames(capture_dir: Path) -> set[int]:
    """Return frames represented exactly in PPU, RAM, and screen indexes."""
    indexes: list[set[int]] = []
    for name in ("ppu_index.csv", "ram_index.csv", "screen_index.csv"):
        path = capture_dir / name
        with path.open(newline="", encoding="utf-8") as stream:
            indexes.append({int(row["frame"]) for row in csv.DictReader(stream)})
    return set.intersection(*indexes)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trace", type=Path, required=True)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--frame", type=int,
                           help="Generate one plan; --output must be a JSON file")
    selection.add_argument("--frames", type=str,
                           help="Comma-separated frame IDs; --output must be a directory")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--synchronized-capture-dir", type=Path,
                        help="Only permit frames present in all three PPU/RAM/screen indexes")
    parser.add_argument("--scroll-y-bias", type=int, default=0,
                        help="Optional reversible offset for effective-scroll calibration")
    parser.add_argument("--scroll-x-override", type=int,
                        help="Use a fixed calibrated X scroll for all bands")
    parser.add_argument("--scroll-y-override", type=int,
                        help="Use a fixed calibrated Y scroll for all bands")
    parser.add_argument("--nametable-page-override", type=int, choices=range(4),
                        help="Use a fixed calibrated nametable page for all bands")
    args = parser.parse_args()
    frames = ([args.frame] if args.frame is not None else
              sorted({int(value.strip()) for value in args.frames.split(",") if value.strip()}))
    if not frames:
        parser.error("--frames must contain at least one frame ID")
    if args.frame is not None and args.output.suffix.lower() != ".json":
        parser.error("--frame output must be a .json file")
    if args.frames is not None and args.output.suffix:
        parser.error("--frames output must be a directory path without a file suffix")
    if args.synchronized_capture_dir:
        allowed = exact_capture_frames(args.synchronized_capture_dir)
        invalid = [frame for frame in frames if frame not in allowed]
        if invalid:
            parser.error(f"frames are not exact PPU/RAM/screen snapshot intersections: {invalid}")
    outputs = []
    events = load_events(args.trace)
    for frame in frames:
        plan = make_plan(args.trace, frame, args.scroll_y_bias,
                         args.scroll_x_override, args.scroll_y_override,
                         args.nametable_page_override, events)
        target = (args.output if args.frame is not None else
                  args.output / f"frame_{frame:06d}.json")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n",
                          encoding="utf-8")
        outputs.append((frame, target, len(plan["bands"])))
    for frame, target, count in outputs:
        print(f"Wrote {count} diagnostic bands for frame {frame}: {target}")


if __name__ == "__main__":
    main()
