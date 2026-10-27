#!/usr/bin/env python3
"""Map the 16 unexplained opening residual pixels to prior-frame OAM/ROM CHR.

This is a read-only provenance audit. Emulator frames and raw RAM are used only
to identify the original OAM entries; pixel planes are read from the preserved
ROM-derived CHR resource. It does not synthesize or modify runtime assets.
"""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RAM_DIR = ROOT / "reference/opening_reference_capture/ram_states"
CHR_PATH = ROOT / "reference/rom_extract/chr_rom.2bpp"
PPU_WRITES = ROOT / "reference/opening_reference_capture/ppu_register_writes.csv"
TARGETS: dict[int, tuple[tuple[int, int], ...]] = {
    3523: ((140, 129),),
    3527: ((135, 129),),
    3536: ((134, 129), (135, 129)),
    3551: ((133, 129), (134, 129), (135, 129), (139, 129)),
    3555: ((139, 129),),
    3561: ((139, 129),),
    3571: ((139, 129),),
    3575: ((139, 129),),
    3583: ((139, 129),),
    3645: ((139, 129),),
    3649: ((132, 121), (136, 121)),
}
CHR_SELECTORS = (0x7C, 0x7D, 0x7E, 0x7F)
CHR_BYTES_PER_BANK = 1024


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_target_ppu_writes() -> dict[int, list[dict[str, int]]]:
    frames = set(TARGETS)
    result = {frame: [] for frame in TARGETS}
    with PPU_WRITES.open(newline="") as stream:
        for row in csv.DictReader(stream):
            frame = int(row["frame"])
            if frame not in frames or int(row["address"], 16) != 0x2006:
                continue
            result[frame].append({
                "cpu_cycle": int(row["cpu_cycles"]),
                "value": int(row["value"], 16),
            })
    return result


def candidates_for_pixel(ram: bytes, chr_data: bytes, x: int, y: int) -> list[dict[str, int | bool | str]]:
    candidates: list[dict[str, int | bool | str]] = []
    for slot in range(64):
        oam_y, tile, attr, oam_x = ram[0x200 + slot * 4 : 0x204 + slot * 4]
        top = oam_y + 1
        if not (oam_x <= x < oam_x + 8 and top <= y < top + 8):
            continue

        local_x = x - oam_x
        local_y = y - top
        if attr & 0x40:
            local_x = 7 - local_x
        if attr & 0x80:
            local_y = 7 - local_y

        selector = CHR_SELECTORS[tile >> 6]
        bank = selector  # The animation's selectors are 1 KiB CHR-bank IDs.
        pattern = bank * CHR_BYTES_PER_BANK + (tile & 0x3F) * 16
        low = chr_data[pattern + local_y]
        high = chr_data[pattern + 8 + local_y]
        bit = 7 - local_x
        pixel_index = ((low >> bit) & 1) | (((high >> bit) & 1) << 1)
        candidates.append({
            "oam_slot": slot,
            "oam_y": oam_y,
            "tile": tile,
            "attribute": attr,
            "oam_x": oam_x,
            "local_x": local_x,
            "local_y": local_y,
            "selector": selector,
            "chr_bank_1k": bank,
            "chr_low": low,
            "chr_high": high,
            "pixel_index": pixel_index,
            "palette": attr & 3,
            "behind_background": bool(attr & 0x20),
        })
    return candidates


def main() -> None:
    chr_data = CHR_PATH.read_bytes()
    assert len(chr_data) == 128 * CHR_BYTES_PER_BANK, len(chr_data)
    ppu_writes = read_target_ppu_writes()
    frames = []
    for frame, points in TARGETS.items():
        # Existing same-run plane traces align source frame N with end-of-frame
        # CPU RAM/OAM snapshot N-1 (e.g. target 3525 uses RAM frame 3524).
        ram_frame = frame - 1
        ram_path = RAM_DIR / f"ram_{ram_frame:06d}.bin"
        ram = ram_path.read_bytes()
        assert len(ram) == 0x800, (ram_path, len(ram))
        pixels = []
        for x, y in points:
            pixels.append({
                "point": [x, y],
                "prior_frame_oam_candidates": candidates_for_pixel(ram, chr_data, x, y),
            })
        frames.append({
            "source_frame": frame,
            "ram_oam_frame": ram_frame,
            "ram_sha256": sha256(ram),
            "ppu_2006_cpu_writes": ppu_writes[frame],
            "pixels": pixels,
        })

    payload = {
        "scope": "16 unresolved visible residual pixels from opening_residual_pixel_locations_20261026.md",
        "rom_chr_resource": str(CHR_PATH.relative_to(ROOT)),
        "chr_sha256": sha256(chr_data),
        "animation_chr_selectors_hex": [f"{value:02X}" for value in CHR_SELECTORS],
        "ppu_2006_capture": str(PPU_WRITES.relative_to(ROOT)),
        "frames": frames,
        "limitation": "RAM OAM and static ROM CHR identify candidates only. The retained capture does not log same-run per-plane reads and final selected sprite for these pixels; CPU-cycle $2006 timestamps are not PPU-dot plane-fetch evidence.",
    }
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
