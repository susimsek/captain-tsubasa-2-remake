#!/usr/bin/env python3
"""Package the ROM-only CPU stepper's frame and Start-poll schedule for Godot."""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "reference/diagnostics/start_poll_rom_source_timing_20261027"
FRAME_CSV = SOURCE / "irq_mask_corrected_title_source_trace/source_frame_cycles.csv"
POLL_CSV = SOURCE / "irq_mask_corrected_full_audit/rom_source_poll_events.csv"
TITLE_EVENTS = ROOT / "assets/opening/rom_logic/title_handoff_source_events.json"
TITLE_PIXEL_REPORT = ROOT / "reference/diagnostics/source_only_title_virtual_raster_20261027.json"
OUTPUT = ROOT / "assets/opening/rom_logic/rom_source_clock_schedule.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
EXPECTED_STEPPER_SHA256 = "f20ca13ee59e1080ad0bef03b70001f53b2cd94c0af6e1d21a241e18288ecfe8"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def main() -> None:
    frame_rows = read_csv(FRAME_CSV)
    poll_rows = read_csv(POLL_CSV)
    if not frame_rows or not poll_rows:
        raise SystemExit("Source timing inputs are empty.")

    frame_deltas: list[int] = []
    previous_end = 0
    for expected_frame, row in enumerate(frame_rows, start=1):
        source_frame = int(row["source_frame"])
        cycle_start = int(row["cycle_start"])
        cycle_end = int(row["cycle_end"])
        cycle_delta = int(row["cycle_delta"])
        if source_frame != expected_frame or cycle_start != previous_end:
            raise SystemExit(f"Non-contiguous source frame clock at frame {expected_frame}.")
        if cycle_end - cycle_start != cycle_delta or cycle_delta <= 0:
            raise SystemExit(f"Invalid source frame duration at frame {expected_frame}.")
        frame_deltas.append(cycle_delta)
        previous_end = cycle_end

    poll_offsets = [-1] * (len(frame_deltas) + 1)
    for row in poll_rows:
        source_frame = int(row["source_frame"])
        cycle_offset = int(row["cycle_from_frame_start"])
        cycle_absolute = int(row["cycle_absolute"])
        if source_frame < 1 or source_frame > len(frame_deltas):
            raise SystemExit(f"Poll references an unavailable source frame: {source_frame}.")
        frame_start = int(frame_rows[source_frame - 1]["cycle_start"])
        if frame_start + cycle_offset != cycle_absolute:
            raise SystemExit(f"Poll absolute cycle does not match frame clock at {source_frame}.")
        if cycle_offset >= frame_deltas[source_frame - 1]:
            raise SystemExit(f"Poll offset falls outside source frame {source_frame}.")
        if poll_offsets[source_frame] >= 0:
            raise SystemExit(f"Duplicate Start poll for source frame {source_frame}.")
        poll_offsets[source_frame] = cycle_offset

    title_events = json.loads(TITLE_EVENTS.read_text(encoding="utf-8"))
    anchor_cycle = int(title_events["start_anchor"]["cycle"])
    handoff_frame = int(title_events["start_anchor"]["source_frame"])
    poll_cycle = int(next(row["cycle_absolute"] for row in poll_rows
                          if int(row["source_frame"]) == handoff_frame))
    poll_to_stop = anchor_cycle - poll_cycle
    if poll_to_stop <= 0 or poll_offsets[handoff_frame] < 0:
        raise SystemExit("Could not align the verified Start poll and $8048 event.")

    title_pixel_report = json.loads(TITLE_PIXEL_REPORT.read_text(encoding="utf-8"))
    virtual_pixel = title_pixel_report["derived_virtual_pixel_time"]
    if title_pixel_report.get("capture_timestamps_used_as_inputs") is not False \
            or title_pixel_report.get("capture_pixels_or_audio_used_as_inputs") is not False:
        raise SystemExit("Title-pixel virtual time must be derived without capture inputs.")
    title_pixel_absolute_cycle = int(virtual_pixel["absolute_cpu_cycle"])
    title_pixel_offset = int(virtual_pixel["cpu_cycle_offset_from_rom_start_stop"])
    final_consumer_cycle = int(virtual_pixel["final_packet_consumer_cycle"])
    if title_pixel_absolute_cycle - anchor_cycle != title_pixel_offset \
            or title_pixel_absolute_cycle - final_consumer_cycle != int(
                virtual_pixel["cycles_after_final_packet_consumer"]):
        raise SystemExit("Title-pixel virtual time does not align with the source handoff.")

    input_timeline_path = ROOT / "reference/opening_reference_capture/input_timeline.csv"
    if sha256(input_timeline_path) != EXPECTED_INPUT_SHA256:
        raise SystemExit("The input route hash differs from the audited source schedule.")

    document = {
        "schema": "ct2-rom-source-clock-schedule-v1",
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "source_stepper_sha256": EXPECTED_STEPPER_SHA256,
        "source_frame_clock": {
            "first_source_frame": 1,
            "last_source_frame": len(frame_deltas),
            "cycle_deltas": frame_deltas,
            "timebase": "ROM-only 6502/PPU/DMC stepper CPU cycles; row n is source frame n duration",
        },
        "start_poll_clock": {
            "first_source_frame": next(i for i, value in enumerate(poll_offsets) if value >= 0),
            "last_source_frame": max(i for i, value in enumerate(poll_offsets) if value >= 0),
            "cycle_offsets_by_source_frame": poll_offsets,
            "source_input_timeline_sha256": EXPECTED_INPUT_SHA256,
            "captured_emulator_timestamps_used_as_runtime_input": False,
        },
        "title_handoff_alignment": {
            "source_frame": handoff_frame,
            "poll_cycle_offset": poll_offsets[handoff_frame],
            "poll_absolute_cycle": poll_cycle,
            "stop_pc": str(title_events["start_anchor"]["pc"]),
            "stop_absolute_cycle": anchor_cycle,
            "poll_to_stop_cpu_cycles": poll_to_stop,
            "basis": "same ROM-only stepper cycle convention; FCEUX is post-run validation only",
        },
        "title_first_pixel_virtual_event": {
            "source_frame": int(title_pixel_report["target_source_frame"]),
            "x": int(title_pixel_report["title_pixel"]["x"]),
            "y": int(title_pixel_report["title_pixel"]["output_y"]),
            "ppu_line": int(title_pixel_report["title_pixel"]["ppu_line"]),
            "ppu_dot": int(title_pixel_report["title_pixel"]["ppu_dot"]),
            "absolute_cpu_cycle": title_pixel_absolute_cycle,
            "cycle_offset_from_start_stop": title_pixel_offset,
            "cycles_after_final_packet_consumer": int(
                virtual_pixel["cycles_after_final_packet_consumer"]),
            "source_report": TITLE_PIXEL_REPORT.relative_to(ROOT).as_posix(),
            "source_report_sha256": sha256(TITLE_PIXEL_REPORT),
            "meaning": "ROM-image/stepper-derived virtual beam event; desktop scanout is not measured",
        },
        "provenance": {
            "frame_clock_source": FRAME_CSV.relative_to(ROOT).as_posix(),
            "frame_clock_sha256": sha256(FRAME_CSV),
            "poll_source": POLL_CSV.relative_to(ROOT).as_posix(),
            "poll_source_sha256": sha256(POLL_CSV),
            "title_event_source": TITLE_EVENTS.relative_to(ROOT).as_posix(),
            "title_event_source_sha256": sha256(TITLE_EVENTS),
            "title_pixel_source_report_sha256": sha256(TITLE_PIXEL_REPORT),
            "source_timestamps_from_fceux_used": False,
            "rom_captures_or_screenshots_used": False,
        },
    }
    OUTPUT.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    print(f"Frames: {len(frame_deltas)}; source polls: {sum(value >= 0 for value in poll_offsets)}")
    print(f"Frame {handoff_frame} poll: +{poll_offsets[handoff_frame]} cycles; $8048: +{poll_to_stop} cycles")


if __name__ == "__main__":
    main()
