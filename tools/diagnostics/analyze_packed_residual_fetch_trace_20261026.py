#!/usr/bin/env python3
"""Validate same-run FCEUX fetch evidence for all 45 current residual pixels."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TRACE_DIR = ROOT / "reference/diagnostics/oam_all_residual_trace_20261026"
RAM_DIR = ROOT / "reference/opening_reference_capture/ram_states"
TARGETS: dict[int, tuple[tuple[int, int], ...]] = {
    3523: ((140, 129),),
    3525: ((136, 129), (137, 129)),
    3527: ((135, 129),),
    3536: ((134, 129), (135, 129)),
    3547: ((132, 129), (136, 129), (137, 129), (138, 129), (139, 129)),
    3551: ((133, 129), (134, 129), (135, 129), (139, 129)),
    3555: ((139, 129),),
    3560: ((134, 129), (135, 129), (136, 129), (137, 129), (138, 129)),
    3561: ((139, 129),),
    3564: ((134, 129), (135, 129), (136, 129), (137, 129), (138, 129)),
    3571: ((139, 129),),
    3575: ((139, 129),),
    3576: ((134, 129), (135, 129), (136, 129), (137, 129), (138, 129)),
    3583: ((139, 129),),
    3594: ((134, 129), (135, 129), (136, 129), (137, 129), (138, 129)),
    3635: ((134, 149), (135, 149)),
    3645: ((139, 129),),
    3649: ((132, 121), (136, 121)),
}


def rows(name: str) -> list[dict[str, str]]:
    with (TRACE_DIR / name).open(newline="") as stream:
        return list(csv.DictReader(stream))


def hx(value: str) -> int:
    return int(value.replace("$", ""), 16)


def main() -> None:
    reads = rows("sprite_plane_reads.csv")
    writes = rows("ppu2006_writes.csv")
    final_pixels = rows("final_pixels.csv")
    oam_snapshots: dict[int, bytes] = {}
    checked_oam: set[tuple[int, int]] = set()
    output = []

    for read in reads:
        frame = int(read["movie_frame"])
        slot = int(read["oam_index"])
        key = (frame, slot)
        if key in checked_oam:
            continue
        ram_frame = frame - 1
        if ram_frame not in oam_snapshots:
            ram_path = RAM_DIR / f"ram_{ram_frame:06d}.bin"
            oam_snapshots[ram_frame] = ram_path.read_bytes()
        ram = oam_snapshots[ram_frame]
        expected = tuple(ram[0x200 + slot * 4 : 0x204 + slot * 4])
        observed = tuple(hx(read[k]) for k in ("sprite_y", "sprite_tile", "sprite_attr", "sprite_x"))
        assert expected == observed, (frame, slot, expected, observed)
        checked_oam.add(key)

    for frame, points in TARGETS.items():
        for x, y in points:
            row_reads = [
                r for r in reads
                if int(r["movie_frame"]) == frame
                and int(r["output_y"]) == y - 1
                and hx(r["sprite_x"]) <= x < hx(r["sprite_x"]) + 8
            ]
            p1_events = [r for r in row_reads if int(r["plane"]) == 1]
            split_events = []
            for p1 in p1_events:
                matches = [
                    w for w in writes
                    if int(w["movie_frame"]) == frame
                    and int(w["scanline"]) == int(p1["scanline"])
                    and int(w["dot"]) == int(p1["dot"])
                    and int(w["toggle_before"]) == 1
                ]
                for write in matches:
                    split_events.append((p1, write))

            assert len(split_events) == 1, (frame, (x, y), len(split_events))
            p1, write = split_events[0]
            p0_matches = [
                r for r in reads
                if int(r["movie_frame"]) == frame
                and int(r["output_y"]) == y - 1
                and int(r["oam_index"]) == int(p1["oam_index"])
                and int(r["plane"]) == 0
            ]
            assert len(p0_matches) == 1, (frame, (x, y), p1["oam_index"])
            p0 = p0_matches[0]

            composer = [
                r for r in final_pixels
                if int(r["movie_frame"]) == frame
                and int(r["output_x"]) == x
                and int(r["output_y"]) == y
            ]
            assert len(composer) == 1, (frame, (x, y), len(composer))
            final = composer[0]

            ram_frame = frame - 1
            if ram_frame not in oam_snapshots:
                ram_snapshots = RAM_DIR / f"ram_{ram_frame:06d}.bin"
                oam_snapshots[ram_frame] = ram_snapshots.read_bytes()
            ram = oam_snapshots[ram_frame]
            slot = int(p1["oam_index"])
            expected_p1 = (hx(write["temp_after"]) + 8) & 0x1FFF
            assert hx(p1["ppu_addr"]) == expected_p1, (frame, (x, y), p1, write)
            output.append({
                "frame": frame,
                "x": x,
                "y": y,
                "ram_oam_frame": ram_frame,
                "affected_oam_slot": slot,
                "tile": hx(p1["sprite_tile"]),
                "attr": hx(p1["sprite_attr"]),
                "ppu_scanline": int(p1["scanline"]),
                "plane0_dot": int(p0["dot"]),
                "plane0_addr": hx(p0["ppu_addr"]),
                "plane0_byte": hx(p0["ppu_data"]),
                "plane0_bank": int(p0["chr_1k_bank"]),
                "2006_low_dot": int(write["dot"]),
                "2006_low_value": hx(write["value"]),
                "2006_refresh_after": hx(write["refresh_after"]),
                "plane1_dot": int(p1["dot"]),
                "plane1_addr": hx(p1["ppu_addr"]),
                "plane1_byte": hx(p1["ppu_data"]),
                "plane1_bank": int(p1["chr_1k_bank"]),
                "selected_oam_slot": int(final["selected_oam_index"]),
                "selected_pixel_index": int(final["selected_spixel"]),
                "ppu_palette_byte": hx(final["pixelcolor_before_adjust"]),
                "adjusted_palette_byte": hx(final["pixelcolor_after_adjust"]),
            })

    out_path = TRACE_DIR / "residual_pixel_causal_attribution.csv"
    fieldnames = list(output[0])
    with out_path.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output)

    print(f"target_pixels={len(output)}")
    print(f"exact_2006_plane1_splits={sum(row['2006_low_dot'] == row['plane1_dot'] for row in output)}")
    print(f"p1_expected_from_refresh_plus_8={sum(row['plane1_addr'] == ((row['2006_refresh_after'] + 8) & 0x1fff) for row in output)}")
    print(f"unique_trace_oam_entries_checked={len(checked_oam)}")
    print(f"attribution_csv={out_path}")


if __name__ == "__main__":
    main()
