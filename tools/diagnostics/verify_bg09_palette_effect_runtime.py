#!/usr/bin/env python3
"""Verify the ROM-driven BG09 palette loop against captured RAM, PPU, and viewport references."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from compare_rom_intro_frames import compare, gd_rgb, png_rgb  # noqa: E402

CAPTURE_DIR = ROOT / "reference/opening_timing_capture_20261024_131726"
SCREEN_DIR = ROOT / "reference/opening_reference_capture/screens"
OUTPUT_DIR = ROOT / "reference/diagnostics/bg09_palette_effect_validation"
EXPECTED = {
    1779: (0x30, 0x0F),
    1780: (0x30, 0x0F),
    1781: (0x30, 0x30),
    1784: (0x21, 0x30),
    1785: (0x21, 0x21),
    1788: (0x30, 0x21),
    1789: (0x30, 0x30),
    1792: (0x25, 0x30),
    1793: (0x25, 0x25),
    2033: (0x25, 0x25),
    2034: (0x25, 0x25),
    2035: (0x25, 0x25),
    2036: (0x30, 0x25),
    2098: (0x25, 0x25),
    2100: (0x30, 0x25),
    2101: (0x30, 0x30),
    2102: (0x30, 0x30),
    2103: (0x30, 0x30),
    2104: (0x21, 0x30),
    2105: (0x21, 0x30),
    2106: (0x21, 0x31),
    2107: (0x21, 0x31),
    2108: (0x21, 0x21),
    2109: (0x21, 0x21),
    2110: (0x21, 0x21),
    2111: (0x21, 0x11),
    2112: (0x21, 0x11),
    2113: (0x21, 0x11),
    2114: (0x21, 0x01),
    2115: (0x21, 0x01),
    2116: (0x21, 0x01),
    2117: (0x21, 0x0F),
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-report", type=Path,
                        default=OUTPUT_DIR / "runtime_palette.json")
    args = parser.parse_args()
    report = json.loads(args.runtime_report.read_text(encoding="utf-8"))
    results = []
    for checkpoint in report["checkpoints"]:
        frame = int(checkpoint["source_frame"])
        expected = EXPECTED[frame]
        ram = (CAPTURE_DIR / "ram_states" / f"ram_{frame:05d}.bin").read_bytes()
        ppu = (CAPTURE_DIR / "ppu_states" / f"ppu_{frame:05d}.bin").read_bytes()
        captured_ram_004c = ram[0x004C]
        captured_ram = ram[0x0633]
        modeled_ram_004c = int(checkpoint["modeled_ram_004c"])
        captured_ppu = ppu[0x3F09]
        modeled_ram = int(checkpoint["modeled_ram_0633"])
        modeled_committed = int(checkpoint["modeled_committed_3f09"])
        renderer_palette = int(checkpoint["renderer_background_3f09"])
        if (captured_ram, captured_ppu) != expected:
            raise ValueError(f"Unexpected supplied capture palette at frame {frame}: "
                             f"RAM=${captured_ram:02X}, PPU=${captured_ppu:02X}")
        if modeled_ram != captured_ram:
            raise ValueError(f"Godot $0633 differs at frame {frame}: "
                             f"${modeled_ram:02X} != ${captured_ram:02X}")
        if modeled_ram_004c != captured_ram_004c:
            raise ValueError(f"Godot $004C differs at frame {frame}: "
                             f"${modeled_ram_004c:02X} != ${captured_ram_004c:02X}")
        if modeled_committed != captured_ppu or renderer_palette != captured_ppu:
            raise ValueError(f"Godot committed/render palette differs at frame {frame}: "
                             f"committed=${modeled_committed:02X}, "
                             f"renderer=${renderer_palette:02X}, capture=${captured_ppu:02X}")

        image_path = ROOT / str(checkpoint.get("viewport_png", "")).removeprefix("res://")
        viewport_check = None
        if str(checkpoint.get("viewport_png", "")):
            reference_path = SCREEN_DIR / f"frame_{frame:06d}.gd"
            if not image_path.is_file() or not reference_path.is_file():
                raise FileNotFoundError(f"Missing same-input viewport/reference at frame {frame}")
            exact, foreground, union, compared, ignored = compare(
                png_rgb(image_path), gd_rgb(reference_path)
            )
            viewport_check = {
                "reference": str(reference_path.relative_to(ROOT)),
                "candidate": str(image_path.relative_to(ROOT)),
                "rgb_exact_fraction": exact,
                "foreground_exact_fraction": foreground,
                "foreground_union_pixels": union,
                "compared_pixels": compared,
                "ignored_pixels": ignored,
            }
        results.append({
            "source_frame": frame,
            "captured_ram_004c": captured_ram_004c,
            "godot_ram_004c": modeled_ram_004c,
            "captured_ram_0633": captured_ram,
            "godot_ram_0633": modeled_ram,
            "captured_ppu_3f09": captured_ppu,
            "godot_committed_3f09": modeled_committed,
            "godot_renderer_3f09": renderer_palette,
            "bg09_effect_write_frame": checkpoint.get("effect_state", {}).get("last_palette_byte_write_source_frame"),
            "bg09_effect_packet_stage_frame": checkpoint.get("effect_state", {}).get("last_packet_stage_source_frame"),
            "bg09_effect_commit_frame": checkpoint.get("effect_state", {}).get("last_commit_source_frame"),
            "fade_counters": checkpoint.get("modeled_fade_counters"),
            "fade_running": checkpoint.get("modeled_fade_running"),
            "queue_cursor_0628": checkpoint.get("modeled_queue_cursor_0628"),
            "effect_capacity_retry_pending": checkpoint.get("effect_state", {}).get("capacity_retry_pending"),
            "viewport": viewport_check,
        })
    palette = (ROOT / "reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal").read_bytes()
    pink = list(palette[0x25 * 3:0x25 * 3 + 3])
    if pink != [255, 117, 182]:
        raise ValueError(f"Pinned FCEUX RGB entry $25 changed: {pink}")
    print(json.dumps({
        "validation_only": True,
        "source_rom_sha256": report["source_rom_sha256"],
        "effect_stream_source": report["effect_stream_source"],
        "palette_25_rgb": pink,
        "checkpoints": results,
    }, indent=2))


if __name__ == "__main__":
    main()
