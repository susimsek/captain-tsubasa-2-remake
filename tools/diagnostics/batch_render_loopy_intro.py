#!/usr/bin/env python3
"""Batch the bounded loopy intro diagnostic while caching cumulative MMC3 state.

This is an offline fidelity-analysis harness only. It leaves the POC renderer's
frame model unchanged, renders ROM CHR into reference/diagnostics, and uses GD
captures only to calculate comparison metrics.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def clone_mmc3(state, state_type):
    clone = state_type()
    clone.mmc3_select = state.mmc3_select
    clone.mmc3_banks = list(state.mmc3_banks)
    return clone


class CurrentFrameEventView:
    """Expose only the current frame to POC replay after cumulative state cache."""

    def __init__(self, source_events):
        self.source_events = source_events
        self.frame = -1

    def __iter__(self):
        # render_frame() iterates keys only to rebuild the cumulative MMC3 state.
        return iter(())

    def get(self, key, default=None):
        if key == self.frame:
            return self.source_events.get(key, default)
        return default


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--palette-file", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--baseline-csv", type=Path, required=True)
    parser.add_argument("--screens-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--resume", action="store_true",
                        help="Keep existing candidate PNG/JSON pairs and render missing frames")
    args = parser.parse_args()

    for name in ("rom", "capture_dir", "palette_file", "manifest", "baseline_csv",
                 "screens_dir", "output_dir"):
        value = getattr(args, name)
        if not value.is_absolute():
            setattr(args, name, ROOT / value)

    poc = load_module("loopy_frame_poc", ROOT / "tools/diagnostics/render_loopy_event_frame_poc.py")
    compare = load_module("intro_frame_compare", ROOT / "tools/compare_rom_intro_frames.py")
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    source_frames = sorted({
        int(match.group(1))
        for entry in manifest["frames"]
        if (match := re.search(r"frame_(\d+)\.png$", entry["path"]))
    })
    frames, events = poc.load_capture(args.capture_dir)
    if not source_frames or any(frame not in frames for frame in source_frames):
        raise ValueError("Manifest source frames are missing from the timing capture")

    baseline = {
        int(row["frame"]): float(row["exact_rgb_fraction"])
        for row in csv.DictReader(args.baseline_csv.open(newline="", encoding="utf-8"))
    }
    state_type = poc.Mmc3State
    state = state_type()
    target_set = set(source_frames)
    state_at_frame = {}
    # This one-time pass replaces per-frame rescans of all prior bus events.
    # Snapshot values are identical to the POC's cumulative event fold.
    for source_frame in sorted(events):
        for event in events[source_frame]:
            address = int(event["address"].removeprefix("$"), 16)
            if address in (0x8000, 0x8001):
                value = int(event["value"].removeprefix("$"), 16)
                poc.apply_mmc3_write(state, address, value)
        if source_frame in target_set:
            state_at_frame[source_frame] = clone_mmc3(state, state_type)

    event_view = CurrentFrameEventView(events)
    current_frame = [-1]

    def cached_state_factory():
        return clone_mmc3(state_at_frame[current_frame[0]], state_type)

    poc.Mmc3State = cached_state_factory
    chr_rom, _, _ = poc.extract_chr(args.rom)
    rom_sha256 = hashlib.sha256(args.rom.read_bytes()).hexdigest()
    palette = poc.read_palette_file(args.palette_file)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    started = time.perf_counter()

    for index, source_frame in enumerate(source_frames, start=1):
        current_frame[0] = source_frame
        event_view.frame = source_frame
        output = args.output_dir / f"frame_{source_frame:06d}_loopy_poc.png"
        metadata_path = output.with_suffix(".json")
        if not (args.resume and output.is_file() and metadata_path.is_file()):
            poc.render_frame(source_frame, args.capture_dir, frames, event_view,
                             chr_rom, palette, args.output_dir, rom_sha256)

        reference = args.screens_dir / f"frame_{source_frame:06d}.gd"
        if not reference.is_file():
            raise FileNotFoundError(f"Missing synchronized reference: {reference}")
        exact, foreground, union = compare.compare(
            compare.png_rgb(output), compare.gd_rgb(reference)
        )
        previous = max(0, source_frame + poc.RAM_FRAME_OFFSET)
        baseline_rate = baseline.get(source_frame)
        rows.append({
            "frame": source_frame,
            "candidate_png": str(output.relative_to(ROOT)),
            "reference_gd": str(reference.relative_to(ROOT)),
            "exact_rgb_fraction": exact,
            "foreground_union_exact_fraction": foreground,
            "foreground_union_pixels": union,
            "baseline_exact_rgb_fraction": baseline_rate,
            "delta_exact_rgb_fraction": exact - baseline_rate if baseline_rate is not None else None,
            "ram_source_frame": previous,
            "screenshot_pixels_used_for_render": False,
        })
        if index % 100 == 0:
            print(f"progress={index}/{len(source_frames)} elapsed_seconds={time.perf_counter()-started:.1f}",
                  flush=True)

    with (args.output_dir / "match_rates.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    scenes = [
        ("logo_and_intro_dialogue", 26, 380),
        ("field_runner_dialogue", 380, 810),
        ("transition_to_tsubasa_portrait", 810, 1026),
        ("hyuga_action_dialogue", 1026, 1548),
        ("hyuga_portrait", 1548, 1780),
        ("shot_action_dialogue", 1780, 2118),
        ("taro_and_remaining_intro", 2118, 4481),
    ]
    scene_stats = []
    for name, first, after in scenes:
        group = [row for row in rows if first <= row["frame"] < after]
        if not group:
            continue
        deltas = [row["delta_exact_rgb_fraction"] for row in group
                  if row["delta_exact_rgb_fraction"] is not None]
        scene_stats.append({
            "scene": name,
            "frame_range": [first, after - 1],
            "frame_count": len(group),
            "candidate_mean_exact_rgb": sum(row["exact_rgb_fraction"] for row in group) / len(group),
            "baseline_mean_exact_rgb": sum(row["baseline_exact_rgb_fraction"] for row in group) / len(group),
            "mean_delta_exact_rgb": sum(deltas) / len(deltas),
            "regressed_frames": sum(delta < -1e-9 for delta in deltas),
            "improved_frames": sum(delta > 1e-9 for delta in deltas),
            "unchanged_frames": sum(abs(delta) <= 1e-9 for delta in deltas),
            "worst_frame": min(group, key=lambda row: row["exact_rgb_fraction"])["frame"],
            "worst_exact_rgb": min(row["exact_rgb_fraction"] for row in group),
        })

    summary = {
        "status": "diagnostic only; not runtime assets or manifest",
        "candidate_frame_count": len(rows),
        "source_frame_range": [source_frames[0], source_frames[-1]],
        "manifest_image_entries_including_startup_black": len(manifest["frames"]),
        "startup_black_has_no_synchronized_screenshot_metric": True,
        "mean_exact_rgb_fraction": sum(row["exact_rgb_fraction"] for row in rows) / len(rows),
        "baseline_mean_exact_rgb_fraction": sum(row["baseline_exact_rgb_fraction"] for row in rows) / len(rows),
        "mean_delta_exact_rgb_fraction": sum(row["delta_exact_rgb_fraction"] for row in rows) / len(rows),
        "regressed_frames": sum(row["delta_exact_rgb_fraction"] < -1e-9 for row in rows),
        "improved_frames": sum(row["delta_exact_rgb_fraction"] > 1e-9 for row in rows),
        "unchanged_frames": sum(abs(row["delta_exact_rgb_fraction"]) <= 1e-9 for row in rows),
        "worst_frame": min(rows, key=lambda row: row["exact_rgb_fraction"])["frame"],
        "worst_exact_rgb_fraction": min(row["exact_rgb_fraction"] for row in rows),
        "best_frame": max(rows, key=lambda row: row["exact_rgb_fraction"])["frame"],
        "best_exact_rgb_fraction": max(row["exact_rgb_fraction"] for row in rows),
        "rom_sha256": rom_sha256,
        "capture": str(args.capture_dir.relative_to(ROOT)),
        "baseline_metrics": str(args.baseline_csv.relative_to(ROOT)),
        "palette": str(args.palette_file.relative_to(ROOT)),
        "rom_screenshot_pixels_used_for_render": False,
        "reference_screenshots_used_only_for_metrics": True,
        "renderer_semantics": "Bounded loopy POC unchanged; cumulative MMC3 final register state cached once across chronological target frames; target-frame bus events are replayed by the POC renderer.",
        "remaining_gaps": [
            "Background fetch/shifter pipeline is approximated as immediate per-pixel tile lookup.",
            "Horizontal scroll uses fine-X and a simplified line-end t-to-v copy, not the full 2C02 fetch/increment schedule.",
            "$2007 writes use the bounded v model; captured target-frame nametable/palette is the base, so old/new memory contents during a frame are not distinguished.",
            "The CPU-RAM OAM shadow is from the preceding frame; physical OAM evaluation, sprite-zero hit/priority timing, and mid-frame OAM DMA are not modeled.",
            "MMC3 CHR writes are replayed at observed dots, but already-latched background/sprite pattern bytes are not represented by the immediate pixel lookup.",
            "Reference screenshots are from the earlier capture; frame/input parity is established, but the PPU trace and screenshot were not recorded in the same --newppu 1 run.",
        ],
        "scene_stats": scene_stats,
        "per_frame": rows,
        "render_and_compare_elapsed_seconds": time.perf_counter() - started,
    }
    (args.output_dir / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({key: summary[key] for key in (
        "candidate_frame_count", "mean_exact_rgb_fraction", "baseline_mean_exact_rgb_fraction",
        "mean_delta_exact_rgb_fraction", "regressed_frames", "improved_frames",
        "unchanged_frames", "worst_frame", "worst_exact_rgb_fraction",
        "render_and_compare_elapsed_seconds")}, indent=2))
    print("scene_stats=" + json.dumps(scene_stats, ensure_ascii=False))


if __name__ == "__main__":
    main()
