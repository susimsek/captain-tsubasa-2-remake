#!/usr/bin/env python3
"""Package ROM-rendered intro diagnostics into a standalone Godot timeline.

Only PNGs rebuilt from ROM CHR and native PPU/RAM layout are copied. FCEUX
screenshots are validation references and are never read by this tool.
"""

from __future__ import annotations

import argparse
import csv
import json
import shutil
from pathlib import Path


def indexed_frames(index_path: Path) -> list[int]:
    with index_path.open(newline="", encoding="utf-8") as stream:
        return sorted({int(row["frame"]) for row in csv.DictReader(stream)})


def ppu_state_intervals(index_path: Path) -> dict[int, int | None]:
    """Map each sparse PPU snapshot to the last frame before the next byte change.

    The capture samples PPU bytes every frame but only writes a file when those
    bytes differ. Therefore a sparse snapshot remains applicable until the next
    indexed snapshot, even when its filename frame is earlier than the target.
    """
    frames = indexed_frames(index_path)
    return {
        frame: frames[index + 1] - 1 if index + 1 < len(frames) else None
        for index, frame in enumerate(frames)
    }


def copy_frame(frame: int, primary: Path, title_build: Path, destination: Path,
               alternate_first: int, alternate_last: int,
               ppu_valid_through: dict[int, int | None],
               metadata_only: bool = False) -> dict[str, object]:
    stem = f"frame_{frame:06d}"
    source_dir = title_build if alternate_first <= frame <= alternate_last else primary
    png = source_dir / f"{stem}.png"
    metadata = source_dir / f"{stem}.json"
    if not png.is_file() or not metadata.is_file():
        raise FileNotFoundError(f"Missing ROM-rendered frame/provenance: {png}")
    evidence = json.loads(metadata.read_text(encoding="utf-8"))
    if evidence.get("screenshot_pixels_used") is not False:
        raise ValueError(f"Frame {frame} lacks screenshot-exclusion provenance")
    if not metadata_only:
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(png, destination / png.name)
    ram_offset = int(evidence.get("ram_source_frame_offset", 0))
    ppu_snapshot_frame = int(evidence["ppu_snapshot_frame"])
    ppu_valid_to = ppu_valid_through.get(ppu_snapshot_frame)
    ppu_byte_state_applicable = (
        ppu_snapshot_frame <= frame
        and (ppu_valid_to is None or frame <= ppu_valid_to)
    )
    return {
        "capture_frame": frame,
        "rendered_source": str(png),
        "metadata": str(metadata),
        "ppu_snapshot_frame": ppu_snapshot_frame,
        "ram_snapshot_frame": evidence["ram_snapshot_frame"],
        "ppu_snapshot_frame_matches_capture_frame": ppu_snapshot_frame == frame,
        "ppu_byte_state_valid_from_frame": ppu_snapshot_frame,
        "ppu_byte_state_valid_through_frame": ppu_valid_to,
        "ppu_byte_state_applicable_at_capture_frame": ppu_byte_state_applicable,
        "ppu_raster_timing_verified_at_capture_frame": False,
        "ram_snapshot_frame_matches_capture_frame": int(evidence["ram_snapshot_frame"]) == frame,
        "ram_source_frame_offset": ram_offset,
        "ram_snapshot_matches_expected_source_offset": (
            int(evidence["ram_snapshot_frame"]) == frame + ram_offset
        ),
        "oam_display_timing_verified_at_capture_frame": False,
        "nametable_page_calibration": "two-sided title assembly" if source_dir == title_build else "page 0",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-index", type=Path, required=True)
    parser.add_argument("--primary-render", type=Path, required=True,
                        help="ROM render calibrated to page 0")
    parser.add_argument("--title-build-render", type=Path, required=True,
                        help="ROM render of two-sided title assembly")
    parser.add_argument("--assets-dir", type=Path, required=True)
    parser.add_argument("--audio-path", default="res://assets/opening/audio/opening_timeline_rom_driver.wav")
    parser.add_argument("--intro-end", type=int, default=4481,
                        help="First frame after cold-start intro cycle")
    parser.add_argument("--loop-start", type=int, default=282)
    parser.add_argument("--transition-start", type=int, default=4661)
    parser.add_argument("--title-start", type=int, default=4692)
    parser.add_argument("--alternate-first", type=int, default=3602)
    parser.add_argument("--alternate-last", type=int, default=3652)
    parser.add_argument("--ppu-state-index", type=Path,
                        help="Sparse change-triggered PPU index; defaults to ppu_index.csv beside capture index")
    parser.add_argument("--metadata-only", action="store_true",
                        help="Regenerate manifest/provenance without copying or modifying rendered PNGs")
    args = parser.parse_args()

    if not 26 < args.loop_start < args.intro_end < args.transition_start < args.title_start:
        parser.error("Expected 26 < loop-start < intro-end < transition-start < title-start")
    source_frames = indexed_frames(args.capture_index)
    ppu_index_path = args.ppu_state_index or args.capture_index.with_name("ppu_index.csv")
    if not ppu_index_path.is_file():
        parser.error(f"Missing sparse PPU state index: {ppu_index_path}")
    ppu_valid_through = ppu_state_intervals(ppu_index_path)
    if not ppu_valid_through:
        parser.error(f"PPU state index is empty: {ppu_index_path}")
    intro_frames = [frame for frame in source_frames if 26 <= frame < args.intro_end]
    if not intro_frames or intro_frames[0] != 26:
        parser.error("Capture index must include frame 26, the first logo frame")

    captured_dir = args.assets_dir / "captured"
    evidence: list[dict[str, object]] = []
    entries: list[dict[str, object]] = [{
        "path": "res://assets/opening/intro/startup_black.png",
        "duration_frames": 26,
    }]
    for position, frame in enumerate(intro_frames):
        evidence.append(copy_frame(frame, args.primary_render, args.title_build_render,
                                   captured_dir, args.alternate_first, args.alternate_last,
                                   ppu_valid_through, args.metadata_only))
        following = intro_frames[position + 1] if position + 1 < len(intro_frames) else args.intro_end
        entries.append({
            "path": f"res://assets/opening/intro/captured/frame_{frame:06d}.png",
            "duration_frames": following - frame,
        })

    # Start is first pressed at frame 4661. The previous field composition is
    # retained for that frame, followed by the ROM's screen-off black interval.
    transition_field_frame = max(frame for frame in source_frames if frame < args.transition_start)
    evidence.append(copy_frame(transition_field_frame, args.primary_render,
                               args.title_build_render, captured_dir,
                               args.alternate_first, args.alternate_last,
                               ppu_valid_through, args.metadata_only))
    transition = [
        {"path": f"res://assets/opening/intro/captured/frame_{transition_field_frame:06d}.png",
         "duration_frames": 1},
        {"path": "res://assets/opening/intro/transition_black.png",
         "duration_frames": args.title_start - args.transition_start - 1},
    ]

    if sum(item["duration_frames"] for item in entries) != args.intro_end:
        raise AssertionError("Intro timeline does not start at frame 0 or has gaps")
    if sum(item["duration_frames"] for item in transition) != args.title_start - args.transition_start:
        raise AssertionError("Title transition timeline has a gap")

    ppu_timestamp_mismatches = sum(
        not item["ppu_snapshot_frame_matches_capture_frame"] for item in evidence
    )
    ppu_inapplicable = sum(
        not item["ppu_byte_state_applicable_at_capture_frame"] for item in evidence
    )
    manifest = {
        "fps": 60.0988,
        "playable": True,
        "fidelity_verified": False,
        "complete": False,
        "audio_path": args.audio_path,
        "audio_start_frame": 0,
        "loop_start_frame": args.loop_start,
        "frames": entries,
        "title_transition_frames": transition,
        "provenance": {
            "source": "original ROM CHR; emulator-native PPU nametable/palette and RAM OAM layout; PPU/MMC3 write trace",
            "render_metadata": "reference/diagnostics/full_intro_render/page0_lag1 and reference/diagnostics/full_intro_render/title_build_fixed",
            "source_frame_index": str(args.capture_index),
            "ppu_state_index": str(ppu_index_path),
            "per_frame_evidence": "reference/diagnostics/full_intro_render/packaged_frame_sources.json",
            "screenshot_pixels_used": False,
            "sparse_ppu_state_note": "PPU bytes are sampled every frame and indexed only when changed. The snapshot timestamp may precede a target frame; its byte state remains applicable through the frame before the next indexed PPU change. This establishes byte-state applicability only, not exact raster rendering timing.",
            "cold_start_note": "Frames 0..25 use ROM-derived black startup art. FCEUX frame-0 capture contains stale framebuffer and frames 2..10 contain emulator Power on overlay, so those screenshot pixels are excluded.",
            "intro_loop_note": "Intro segment 0..4480; frame 282 starts the repeatable cutscene. Captures show first repeated black at frame 4482; frame 4481 itself was not captured. Loop boundary at 4481 follows ROM audio cue reset and is provisional by one frame.",
            "title_transition_note": "Start is pressed at frame 4661. The previous rendered frame is held one frame, then black through frame 4691; title endpoint at 4692 is a separate ROM-derived menu scene.",
            "page_calibration_note": "Page 0 improves visual match in most intro scenes. Frames 3602..3652 use the ROM title nametable with two-sided raster scroll and a blank page-1 middle band; all 26 changed frames match synchronized FCEUX observations at 100% RGB and foreground pixels. Screenshot pixels are comparison-only.",
            "oam_timing_note": "Most intro frames use the preceding RAM/OAM shadow because sampled FCEUX screen pixels align with prior-frame OAM; see per-frame source offsets and comparison metrics.",
            "ppu_snapshot_timestamp_mismatches": ppu_timestamp_mismatches,
            "ppu_byte_state_inapplicable_frames": ppu_inapplicable,
            "limitations": "PPUSTATUS latch resets, mid-scanline writes, exact sprite/OAM timing, and all screen colors are not fully resolved. PPU byte-state applicability does not establish exact frame composition. This is a playable ROM-derived reconstruction, not an exact verified copy.",
        },
    }
    args.assets_dir.joinpath("frame_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    source_record = args.primary_render.parent / "packaged_frame_sources.json"
    source_record.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n",
                             encoding="utf-8")
    action = "Refreshed metadata for" if args.metadata_only else "Packaged"
    print(f"{action} {len(entries)} intro entries ({args.intro_end} frames), "
          f"{len(transition)} transition entries; PPU timestamp mismatches="
          f"{ppu_timestamp_mismatches}, inapplicable byte states={ppu_inapplicable}")
    print(f"Manifest: {args.assets_dir / 'frame_manifest.json'}")


if __name__ == "__main__":
    main()
