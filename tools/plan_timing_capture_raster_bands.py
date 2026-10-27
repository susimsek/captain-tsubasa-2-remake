#!/usr/bin/env python3
"""Build a diagnostic raster plan from capture_opening_timing.lua output.

Unlike plan_rom_raster_bands.py, this reads frame-relative bus events and
per-frame cycle baselines. PPUSTATUS reads reset the shared $2005/$2006 write
toggle before the next PPU register write. Pixel timing is still quantized to
scanline boundaries; this does not model sub-scanline fetch behavior.
"""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path

from plan_rom_raster_bands import State, state_key

CPU_CYCLES_PER_PPU_SCANLINE = 341 / 3
DEFAULT_VISIBLE_START_OFFSET = round(21 * CPU_CYCLES_PER_PPU_SCANLINE)


@dataclass(frozen=True)
class Event:
    capture_frame: int
    script_frame: int
    emulator_frame: int
    cycle_offset: int
    kind: str
    address: int
    value: int
    ppu_scanline: int | None = None
    ppu_dot: int | None = None


def load_capture(capture: Path) -> tuple[dict[int, dict[str, str]], list[Event]]:
    frames: dict[int, dict[str, str]] = {}
    with (capture / "frames.csv").open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            frame_key = int(row.get("source_frame", row["script_frame"]))
            frames[frame_key] = row

    events: list[Event] = []
    with (capture / "bus_events.csv").open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            address = int(row["address"].removeprefix("$"), 16)
            kind = row["event"]
            if address not in {0x2000, 0x2001, 0x2002, 0x2005, 0x2006,
                               0x8000, 0x8001}:
                continue
            cycle_offset = int(row["cycle_from_frame_start"])
            if cycle_offset < 0:
                continue
            events.append(Event(
                capture_frame=int(row.get("source_frame", row["script_frame"])),
                script_frame=int(row["script_frame"]),
                emulator_frame=int(row.get("emulator_frame", row.get("emulator_frame_after", -1))),
                cycle_offset=cycle_offset,
                kind=kind,
                address=address,
                value=int(row["value"].removeprefix("$"), 16),
                ppu_scanline=int(row["ppu_scanline"]) if row.get("ppu_scanline") else None,
                ppu_dot=int(row["ppu_dot"]) if row.get("ppu_dot") else None,
            ))
    events.sort(key=lambda event: (event.capture_frame, event.cycle_offset))
    return frames, events


def apply_event(state: State, event: Event) -> None:
    if event.kind == "PPUSTATUS_read" or event.address == 0x2002:
        state.scroll_next_is_y = False
        return
    if event.kind in {"PPUCTRL_write", "PPUMASK_write", "PPUSCROLL_write",
                      "PPUADDR_write", "MMC3_bank_select", "MMC3_bank_data"}:
        from plan_rom_raster_bands import apply_write
        apply_write(state, event.address, event.value)


def make_plan(capture: Path, frame: int, visible_start_offset: int,
              scroll_y_bias: int = 0, scroll_x_override: int | None = None,
              scroll_y_override: int | None = None,
              page_override: int | None = None,
              use_ppu_coordinates: bool = False) -> dict[str, object]:
    frames, events = load_capture(capture)
    if frame not in frames:
        raise ValueError(f"No frames.csv record for script_frame {frame}")
    cycle_start = int(frames[frame]["cycle_start"])
    cycle_end = int(frames[frame]["cycle_end"])
    cycle_delta = int(frames[frame]["cycle_delta"])
    scanline_cycles = CPU_CYCLES_PER_PPU_SCANLINE
    state = State()
    frame_events = [event for event in events if event.capture_frame <= frame]
    by_frame: dict[int, list[Event]] = {}
    for event in frame_events:
        by_frame.setdefault(event.capture_frame, []).append(event)

    bands: list[dict[str, object]] = []
    for event_frame in sorted(by_frame):
        events_this_frame = by_frame[event_frame]
        if event_frame < frame:
            for event in events_this_frame:
                apply_event(state, event)
            continue

        line_events: dict[int, list[Event]] = {}
        for event in events_this_frame:
            if use_ppu_coordinates:
                if event.ppu_scanline is None:
                    raise ValueError("--use-ppu-coordinates requires ppu_scanline fields")
                # FCEUX starts frame advancement at scanline 240. Vblank and
                # pre-render writes (240..261) take effect before visible row 0.
                if event.ppu_scanline >= 240:
                    apply_event(state, event)
                elif 0 <= event.ppu_scanline < 240:
                    line_events.setdefault(event.ppu_scanline, []).append(event)
            elif event.cycle_offset < visible_start_offset:
                apply_event(state, event)
            else:
                y = int((event.cycle_offset - visible_start_offset) / scanline_cycles)
                if 0 <= y < 240:
                    line_events.setdefault(y, []).append(event)

        start_y = 0
        previous_key = state_key(state, scroll_y_bias, scroll_x_override,
                                 scroll_y_override, page_override)
        current_band = state.band(0, 240, scroll_y_bias, scroll_x_override,
                                  scroll_y_override, page_override)
        for y in range(240):
            for event in line_events.get(y, []):
                apply_event(state, event)
            key = state_key(state, scroll_y_bias, scroll_x_override,
                            scroll_y_override, page_override)
            if key != previous_key:
                if y > start_y:
                    current_band["end_y"] = y
                    bands.append(current_band)
                start_y = y
                current_band = state.band(y, 240, scroll_y_bias, scroll_x_override,
                                          scroll_y_override, page_override)
                previous_key = key
        current_band["end_y"] = 240
        bands.append(current_band)

        # Preserve writes after the final visible scanline for state tracking
        # if this function is extended to emit multiple consecutive frames.
        if not use_ppu_coordinates:
            for event in events_this_frame:
                if event.cycle_offset >= visible_start_offset + 240 * scanline_cycles:
                    apply_event(state, event)

    frame_row = frames[frame]
    return {
        "validation_status": "diagnostic; PPUSTATUS read resets shared $2005/$2006 latch; scanline-quantized, sub-scanline PPU timing not modeled",
        "trace_reference": str(capture / "bus_events.csv"),
        "frames_reference": str(capture / "frames.csv"),
        "capture_frame_key": frame,
        "source_frame": int(frame_row.get("source_frame", frame)),
        "script_frame": int(frame_row["script_frame"]),
        "emulator_frame": int(frame_row.get("emulator_frame_after", frame_row.get("emulator_frame", -1))),
        "cycle_start": cycle_start,
        "cycle_end": cycle_end,
        "cycle_delta": cycle_delta,
        "visible_start_offset_assumption": visible_start_offset,
        "cpu_cycles_per_scanline_assumption": scanline_cycles,
        "scanline_mapping": "floor((cycle_from_frame_start-visible_start_offset)/(341/3))",
        "ppu_coordinate_mapping": "recorded scanline/dot; scanline 240..261 precedes visible row 0; scanline 0..239 maps directly" if use_ppu_coordinates else None,
        "scroll_y_bias_assumption": scroll_y_bias,
        "scroll_x_override_assumption": scroll_x_override,
        "scroll_y_override_assumption": scroll_y_override,
        "nametable_page_override_assumption": page_override,
        "latch_model": "PPUSTATUS read sets shared PPU write toggle to first-write state; writes to $2005/$2006 toggle it",
        "initial_register_state_assumption": "PPUCTRL/PPUMASK/MMC3 bank registers and shared latch initialized to zero after power-on; all recorded earlier bus events replayed",
        "ppu_file": frame_row["ppu_file"],
        "ram_file": frame_row["ram_file"],
        "bands": bands,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--frame", type=int, required=True,
                        help="source_frame key when available; otherwise script_frame")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--visible-start-offset", type=int,
                        default=DEFAULT_VISIBLE_START_OFFSET,
                        help=f"CPU cycles from cycle_start to visible line 0 (default {DEFAULT_VISIBLE_START_OFFSET})")
    parser.add_argument("--use-ppu-coordinates", action="store_true",
                        help="Use actual ppu_scanline/ppu_dot timestamps from the new-PPU capture")
    parser.add_argument("--scroll-y-bias", type=int, default=0)
    parser.add_argument("--scroll-x-override", type=int)
    parser.add_argument("--scroll-y-override", type=int)
    parser.add_argument("--nametable-page-override", type=int, choices=range(4))
    args = parser.parse_args()
    plan = make_plan(args.capture_dir, args.frame, args.visible_start_offset,
                     args.scroll_y_bias, args.scroll_x_override,
                     args.scroll_y_override, args.nametable_page_override,
                     args.use_ppu_coordinates)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8")
    print(f"Wrote {len(plan['bands'])} diagnostic bands for capture frame {args.frame} "
          f"(script_frame {plan['script_frame']}, emulator_frame {plan['emulator_frame']}): {args.output}")


if __name__ == "__main__":
    main()
