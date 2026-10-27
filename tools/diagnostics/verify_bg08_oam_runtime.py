#!/usr/bin/env python3
"""Compare the Godot BG08 C1/82 OAM path with ROM bytes and FCEUX captures.

All capture inputs are validation evidence only. They are never runtime assets.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from compare_rom_intro_frames import gd_rgb  # noqa: E402
from diagnostics.analyze_oam_display_latch import rendered_oam_pixels  # noqa: E402

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
WIDTH = 256
HEIGHT = 240
OAM_OFFSET = 0x200


def _decode_png_rgba(path: Path) -> tuple[bytes, bytes]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG file: {path}")
    pos = 8
    compressed = bytearray()
    width = height = bit_depth = color_type = interlace = None
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
                ">IIBBBBB", chunk
            )
            if compression != 0 or filtering != 0:
                raise ValueError(f"Unsupported PNG header: {path}")
        elif kind == b"IDAT":
            compressed.extend(chunk)
        pos += length + 12
    if (width, height, bit_depth, color_type, interlace) != (WIDTH, HEIGHT, 8, 6, 0):
        raise ValueError(f"Expected noninterlaced 8-bit RGBA 256x240 PNG: {path}")

    bpp = 4
    row_bytes = WIDTH * bpp
    decoded = zlib.decompress(compressed)
    if len(decoded) != HEIGHT * (row_bytes + 1):
        raise ValueError(f"Unexpected decoded PNG length: {path}")
    rgba = bytearray(HEIGHT * row_bytes)
    prior = bytearray(row_bytes)
    for y in range(HEIGHT):
        row_start = y * (row_bytes + 1)
        filter_type = decoded[row_start]
        filtered = decoded[row_start + 1:row_start + 1 + row_bytes]
        current = bytearray(row_bytes)
        for i, value in enumerate(filtered):
            left = current[i - bpp] if i >= bpp else 0
            up = prior[i]
            upper_left = prior[i - bpp] if i >= bpp else 0
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = up
            elif filter_type == 3:
                predictor = (left + up) // 2
            elif filter_type == 4:
                estimate = left + up - upper_left
                distances = (abs(estimate - left), abs(estimate - up), abs(estimate - upper_left))
                predictor = (left, up, upper_left)[distances.index(min(distances))]
            else:
                raise ValueError(f"Unsupported PNG filter {filter_type}: {path}")
            current[i] = (value + predictor) & 0xFF
        rgba[y * row_bytes:(y + 1) * row_bytes] = current
        prior = current
    rgb = bytearray(WIDTH * HEIGHT * 3)
    alpha = bytearray(WIDTH * HEIGHT)
    for pixel in range(WIDTH * HEIGHT):
        rgba_offset = pixel * 4
        rgb_offset = pixel * 3
        rgb[rgb_offset:rgb_offset + 3] = rgba[rgba_offset:rgba_offset + 3]
        alpha[pixel] = rgba[rgba_offset + 3]
    return bytes(rgb), bytes(alpha)


def _read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _verify_rom_bytes(rom_path: Path, timing: dict, frames: dict, used_frame_addresses: set[str]) -> dict:
    rom = rom_path.read_bytes()
    actual_sha = hashlib.sha256(rom).hexdigest()
    if actual_sha != EXPECTED_ROM_SHA256:
        raise ValueError(f"Supplied ROM hash differs: {actual_sha}")
    command_checks = 0
    for animation in timing["animations"]:
        if animation.get("animation_id") not in {"0xC1", "0x82"}:
            continue
        for command in animation["commands"]:
            raw_hex = command.get("raw_hex", "")
            if not raw_hex:
                continue
            offset = int(command["file_offset"], 16)
            raw = bytes.fromhex(raw_hex)
            if rom[offset:offset + len(raw)] != raw:
                raise ValueError(
                    f"ROM command mismatch {animation['animation_id']} {command['file_offset']} {raw_hex}"
                )
            command_checks += 1

    frame_by_address = {frame["cpu_address"].lower(): frame for frame in frames["frames"]}
    descriptor_checks = 0
    for address in sorted(used_frame_addresses):
        frame = frame_by_address[address.lower()]
        header_offset = int(frame["chr_selectors_source_file_offset"], 16)
        selectors = bytes.fromhex(frame["chr_selectors_hex"])
        if rom[header_offset:header_offset + 4] != selectors:
            raise ValueError(f"ROM CHR selector mismatch for sprite frame {address}")
        for sprite in frame["sprites"]:
            offset = int(sprite["source_file_offset"], 16)
            raw = bytes.fromhex(sprite["raw_hex"])
            if rom[offset:offset + len(raw)] != raw:
                raise ValueError(
                    f"ROM sprite descriptor mismatch at {sprite['source_file_offset']}: {sprite['raw_hex']}"
                )
            descriptor_checks += 1
    return {
        "rom_sha256": actual_sha,
        "command_byte_checks": command_checks,
        "frame_selector_checks": len(used_frame_addresses),
        "sprite_descriptor_byte_checks": descriptor_checks,
    }


def _sprite_tuple_from_descriptor(sprite: dict, origin_x: int, origin_y: int) -> tuple[int, int, int, int]:
    attributes = int(sprite["palette_low_bits"]) & 0x03
    if sprite.get("flip_h_bit", False):
        attributes |= 0x40
    sprite_y = origin_y + int(sprite["y_offset_from_animation"])
    sprite_x = origin_x + int(sprite["x_offset_from_animation"])
    # ROM $9541 writes coordinate overflow into attribute bits $04/$08 in the
    # CPU OAM shadow. The later $A8CE DMA copier, not this shadow writer,
    # substitutes Y=$F8 for marked entries.
    if sprite_x < 0 or sprite_x > 0xFF:
        attributes |= 0x04
    if sprite_y < 0 or sprite_y > 0xFF:
        attributes |= 0x08
    return (
        sprite_y & 0xFF,
        int(sprite["tile_id"], 16),
        attributes,
        sprite_x & 0xFF,
    )


def _expected_descriptor_slots(checkpoint: dict, frames: dict) -> tuple[dict[int, tuple[int, int, int, int]], set[str]]:
    frame_by_address = {frame["cpu_address"].lower(): frame for frame in frames["frames"]}
    expected: dict[int, tuple[int, int, int, int]] = {}
    used_frames: set[str] = set()
    for track in checkpoint["oam"]["tracks"]:
        address = track["frame_address"].lower()
        if not address:
            continue
        used_frames.add(address)
        frame = frame_by_address[address]
        record = bytes.fromhex(track["record_bytes_hex"])
        y_raw = record[4] | (record[5] << 8)
        x_raw = record[6] | (record[7] << 8)
        y_signed = y_raw - 0x10000 if y_raw >= 0x8000 else y_raw
        x_signed = x_raw - 0x10000 if x_raw >= 0x8000 else x_raw
        origin_y = int(y_signed // 128)
        origin_x = int(x_signed // 128)
        start_slot = int(track["oam_start_slot"])
        for index, sprite in enumerate(frame["sprites"]):
            slot = (start_slot + index) % 64
            expected[slot] = _sprite_tuple_from_descriptor(sprite, origin_x, origin_y)
    return expected, used_frames


def _slot_tuples(oam: bytes) -> list[tuple[int, int, int, int]]:
    return [tuple(oam[i * 4:i * 4 + 4]) for i in range(64)]


def _rom_dma_copy(oam_shadow: bytes) -> bytes:
    """Apply the verified $A8CE Y=$F8 hide rule to all 64 shadow tuples."""
    result = bytearray(oam_shadow)
    for slot in range(64):
        offset = slot * 4
        if result[offset + 2] & 0x0C:
            result[offset] = 0xF8
    return bytes(result)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-report", type=Path, required=True)
    parser.add_argument("--rom", type=Path, default=ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes")
    parser.add_argument("--capture-dir", type=Path, default=ROOT / "reference/opening_timing_capture_20261024_131726")
    parser.add_argument("--screens-dir", type=Path, default=ROOT / "reference/opening_reference_capture/screens")
    parser.add_argument("--rgb-palette", type=Path, default=ROOT / "reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal")
    args = parser.parse_args()

    timing = _read_json(ROOT / "reference/rom_extract/intro/animation_timing_entry.json")
    frames = _read_json(ROOT / "reference/rom_extract/intro/sprite_frames_entry.json")
    report = _read_json(args.runtime_report)
    rgb_palette = args.rgb_palette.read_bytes()
    results = []
    for checkpoint in report["checkpoints"]:
        display_frame = int(checkpoint["display_frame"])
        ram_frame = int(checkpoint["ram_oam_reference_frame"])
        ram = (args.capture_dir / "ram_states" / f"ram_{ram_frame:05d}.bin").read_bytes()
        ppu = (args.capture_dir / "ppu_states" / f"ppu_{display_frame:05d}.bin").read_bytes()
        godot_oam = bytes.fromhex(checkpoint["oam"]["shared_oam_bytes_hex"])
        reference_dma = ram[OAM_OFFSET:OAM_OFFSET + 0x100]
        reference_shadow = ram[0x468:0x568]
        if len(godot_oam) != 0x100 or len(reference_dma) != 0x100 or len(reference_shadow) != 0x100:
            raise ValueError(f"Bad OAM size at display frame {display_frame}")

        expected_slots, used_frames = _expected_descriptor_slots(checkpoint, frames)
        rom_checks = _verify_rom_bytes(args.rom, timing, frames, used_frames)
        shadow_tuples = _slot_tuples(reference_shadow)
        dma_tuples = _slot_tuples(reference_dma)
        unresolved_slot = 5 if any(
            track["frame_address"].lower() == "0xae08"
            for track in checkpoint["oam"]["tracks"]
        ) else -1
        known_expected_slots = {
            slot: expected for slot, expected in expected_slots.items() if slot != unresolved_slot
        }
        descriptor_tuple_matches = sum(
            shadow_tuples[slot] == expected for slot, expected in known_expected_slots.items()
        )
        oam_slots = _slot_tuples(godot_oam)
        mismatch_slots = [slot for slot, (actual, expected) in enumerate(zip(oam_slots, shadow_tuples))
                          if actual != expected]
        exact_slots_except_unresolved = sum(
            oam_slots[slot] == shadow_tuples[slot]
            for slot in range(64) if slot != unresolved_slot
        )
        godot_dma = _rom_dma_copy(godot_oam)
        source_dma = _rom_dma_copy(reference_shadow)
        godot_dma_matches = sum(a == b for a, b in zip(_slot_tuples(godot_dma), dma_tuples))
        source_dma_matches = sum(a == b for a, b in zip(_slot_tuples(source_dma), dma_tuples))

        source_screen = gd_rgb(args.screens_dir / f"frame_{display_frame:06d}.gd")
        reference_sprite_pixels = rendered_oam_pixels(ram, ppu, rgb_palette)
        candidate_sprite_rgb, candidate_alpha = _decode_png_rgba(
            args.runtime_report.parent / checkpoint["godot_sprite_composition_png"].split("/")[-1]
        )
        candidate_opaque = [pixel for pixel, alpha in enumerate(candidate_alpha) if alpha != 0]
        exact_against_screen = sum(
            candidate_sprite_rgb[pixel * 3:pixel * 3 + 3]
            == source_screen[pixel * 3:pixel * 3 + 3]
            for pixel in candidate_opaque
        )
        exact_against_source_oam = sum(
            candidate_sprite_rgb[pixel * 3:pixel * 3 + 3] == expected_color
            for pixel, expected_color in reference_sprite_pixels.items()
        )

        results.append({
            "display_frame": display_frame,
            "ram_oam_reference_frame": ram_frame,
            "descriptor_slots_expected": len(known_expected_slots),
            "decoded_descriptor_tuple_matches": descriptor_tuple_matches,
            "godot_oam_exact_slots": 64 - len(mismatch_slots),
            "godot_oam_exact_slots_excluding_unresolved": exact_slots_except_unresolved,
            "oam_mismatch_slots": mismatch_slots,
            "godot_dma_exact_slots_after_A8CE_rule": godot_dma_matches,
            "rom_shadow_to_dma_exact_slots_after_A8CE_rule": source_dma_matches,
            "unresolved_slot_5_reference_tuple": list(shadow_tuples[5]),
            "godot_slot_5_tuple": list(oam_slots[5]),
            "sprite_opaque_pixels": len(candidate_opaque),
            "godot_sprite_pixels_matching_fceux_screen": exact_against_screen,
            "godot_sprite_pixels_matching_source_oam_render": exact_against_source_oam,
            "rom_byte_checks": rom_checks,
        })
    print(json.dumps({"validation_only": True, "checkpoints": results}, indent=2))


if __name__ == "__main__":
    main()
