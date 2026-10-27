#!/usr/bin/env python3
"""Compare ROM-decoded intro sprite descriptors with reference OAM shadow.

The sprite pixels/tiles/geometry come from the supplied ROM through
decode_intro_sprite_frames.py. RAM snapshots are used only to validate the
decoder and infer the live animation origin; they are never exported as art.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
FRAME_INDEX = ROOT / "reference/rom_extract/intro/sprite_frames_entry.json"
RAM_DIR = ROOT / "reference/opening_reference_capture/ram_states"
PPU_DIR = ROOT / "reference/opening_reference_capture/ppu_states"
OUTPUT = ROOT / "reference/diagnostics/intro_sprite_oam_matches.json"

# Each frame ID is a synchronized FCEUX capture. Frame selection was first
# established by matching its ROM sprite tile IDs in OAM entry order.
SAMPLES = [
    (26, "0x8D", "0xB15B"),  # cold-start logo composition
    (100, "0x8D", "0xB15B"),  # Tecmo Theater logo
    (380, "0x6E", "0xA86F"),  # field runner crossing left edge
    (480, "0x6E", "0xA8BA"),  # field runner
    (803, "0x6E", "0xA837"),  # field runner
    (880, "0x75", "0xAA8C"),  # Tsubasa portrait
    (1600, "0x76", "0xAAE7"),  # mirrored Hyuga portrait
    (2190, "0x77", "0xAB4A"),  # later portrait
    (2800, "0x7C", "0xAD14"),  # goalkeeper portrait
    (4692, "0x0D", "0xA7CB"),  # title sprite layer
]


def title_transition_byte_evidence(rom: bytes) -> dict:
    """Assert original bank-0 title branch and two sprite state routines."""
    fragments = [
        (0x8061, "a9 0d 20 97 82", "load animation 0D through JSR $8297"),
        (0x806A, "a9 17 20 f7 8a", "load title background 17 through JSR $8AF7"),
        (0x806F, "a9 30 20 0c 89", "pass $30 to JSR $890C for animation Y shift"),
        (0x8074, "20 fb 88", "call $88FB to toggle animation priority bit 5"),
        (0x890C, "85 ed a2 00 bd 68 04 18 65 ed 9d 68 04 e8 e8 e8 e8 d0 f1 60",
         "for X=0,4,...,252: $0468+X += input A"),
        (0x88FB, "a2 00 bd 6a 04 49 20 9d 6a 04 e8 e8 e8 e8 d0 f2 60",
         "for X=0,4,...,252: $046A+X ^= $20"),
    ]
    result = []
    for cpu, hex_bytes, meaning in fragments:
        file_offset = 16 + cpu - 0x8000
        expected = bytes.fromhex(hex_bytes)
        actual = rom[file_offset:file_offset + len(expected)]
        if actual != expected:
            raise ValueError(f"Title transition ROM bytes changed at CPU ${cpu:04X}")
        result.append({
            "cpu_address": f"0x{cpu:04X}",
            "rom_file_offset": f"0x{file_offset:06X}",
            "raw_hex": actual.hex(" "),
            "machine_code_effect": meaning,
        })
    return {
        "call_order": ["animation 0D", "background 17", "add $30 to all animation Y slots", "toggle priority bit 5 in all animation attributes"],
        "fragments": result,
        "title_origin_y_derivation": "F1 Y=$26 -> 2*$26=$4C; then $890C adds $30 -> $7C (124), equal to OAM match",
        "title_priority_derivation": "Animation 0D descriptor palette/flip attributes gain bit $20 through $88FB, equal to title OAM match",
    }


def predicted_oam(sprite: dict, origin_x: int, origin_y: int,
                  mirror: bool, priority: bool) -> tuple[int, int, int, int]:
    dx = sprite["x_offset_from_animation"]
    dy = sprite["y_offset_from_animation"]
    if dx is None or dy is None:
        raise ValueError("Unresolved sprite offset in chosen sample")
    x = origin_x + (-dx if mirror else dx)
    y = origin_y + dy
    attribute = sprite["palette_low_bits"]
    if mirror ^ sprite["flip_h_bit"]:
        attribute |= 0x40
    if priority:
        attribute |= 0x20
    # The original renderer hides sprites that travel across the left edge by
    # moving their Y to 248 and setting attribute bit 2. The offscreen X byte
    # remains wrapped. This is evidenced by frame 380; the right-edge behavior
    # remains outside this analysis.
    if x < 0:
        y = 248
        attribute |= 0x04
    return y & 0xFF, int(sprite["tile_id"], 16), attribute, x & 0xFF


def analyze_sample(frames: dict[str, dict], frame_number: int,
                   animation_id: str, frame_cpu: str, rom: bytes) -> dict:
    frame = frames[frame_cpu]
    path = RAM_DIR / f"ram_{frame_number:06d}.bin"
    ram = path.read_bytes()
    if len(ram) != 2048:
        raise ValueError(f"Unexpected CPU RAM snapshot size: {path}")
    oam = [tuple(ram[0x200 + i * 4:0x204 + i * 4]) for i in range(64)]
    sprites = frame["sprites"]
    if not sprites or len(sprites) > 64:
        raise ValueError(f"Invalid descriptor count for {frame_cpu}")
    first = sprites[0]
    if first["x_offset_from_animation"] is None or first["y_offset_from_animation"] is None:
        raise ValueError(f"Unresolved initial sprite at {frame_cpu}")

    choices = []
    for mirror in (False, True):
        for priority in (False, True):
            raw_origin_x = oam[0][3] - (-first["x_offset_from_animation"] if mirror
                                          else first["x_offset_from_animation"])
            origin_y = (oam[0][0] - first["y_offset_from_animation"]) & 0xFF
            for wrap in (-1, 0, 1):
                origin_x = raw_origin_x + wrap * 256
                actual = oam[:len(sprites)]
                predicted = [predicted_oam(sprite, origin_x, origin_y, mirror, priority)
                             for sprite in sprites]
                matches = sum(a == b for a, b in zip(actual, predicted))
                choices.append((matches, origin_x, origin_y, mirror, priority, predicted))
    # All included samples have a unique perfect match at the selected origin.
    # Prefer the smallest-magnitude origin if modulo-256 alternatives tie.
    matches, origin_x, origin_y, mirror, priority, predicted = max(
        choices, key=lambda c: (c[0], -abs(c[1])))
    if matches != len(sprites):
        mismatches = [i for i, (a, b) in enumerate(zip(oam, predicted)) if a != b]
        raise ValueError(f"OAM differs for {frame_number}/{frame_cpu}: {matches}/"
                         f"{len(sprites)}, first bad entries {mismatches[:8]}")

    clipped = sum(sprite["x_offset_from_animation"] is not None and
                  origin_x + (-sprite["x_offset_from_animation"] if mirror
                              else sprite["x_offset_from_animation"]) < 0
                  for sprite in sprites)
    ppu_path = PPU_DIR / f"ppu_{frame_number:06d}.bin"
    chr_mapping = None
    if ppu_path.exists():
        ppu = ppu_path.read_bytes()
        if len(ppu) != 12320:
            raise ValueError(f"Unexpected PPU snapshot size: {ppu_path}")
        selectors = [int(part, 16) for part in frame["chr_selectors_hex"].split()]
        # iNES header + 256 KiB PRG = CHR start at 0x40010; each selector is a
        # 1 KiB CHR bank. The animation parser maps its four selector bytes to
        # sprite pattern slots $1000-$1FFF in this captured configuration.
        chr_base = 0x40010
        slot_matches = [ppu[(4 + i) * 1024:(5 + i) * 1024] ==
                        rom[chr_base + bank * 1024:chr_base + (bank + 1) * 1024]
                        for i, bank in enumerate(selectors)]
        chr_mapping = {
            "capture_ppu_path": str(ppu_path.relative_to(ROOT)),
            "chr_selectors": selectors,
            "ppu_slots_4_to_7_rom_byte_equal": slot_matches,
        }
        if not all(slot_matches):
            raise ValueError(f"Sprite CHR bank mismatch in PPU frame {frame_number}")
    return {
        "capture_frame": frame_number,
        "animation_id": animation_id,
        "sprite_frame_cpu_address": frame_cpu,
        "sprite_frame_rom_file_offset": frame["file_offset"],
        "sprite_frame_prg_bank": frame["prg_bank"],
        "capture_ram_path": str(path.relative_to(ROOT)),
        "capture_ram_sha256": hashlib.sha256(ram).hexdigest(),
        "origin_x_pixels": origin_x,
        "origin_y_oam_units": origin_y,
        "horizontal_mirror": mirror,
        "priority_behind_background": priority,
        "descriptor_count": len(sprites),
        "exact_oam_entries": matches,
        "left_clipped_entries": clipped,
        "first_oam_entry": list(oam[0]),
        "last_oam_entry": list(oam[len(sprites) - 1]),
        "chr_mapping_validation": chr_mapping,
    }


def main() -> None:
    index = json.loads(FRAME_INDEX.read_text())
    rom = ROM.read_bytes()
    if hashlib.sha256(rom).hexdigest() != index["rom_sha256"]:
        raise ValueError("ROM hash differs from decoded sprite-frame source")
    frames = {item["cpu_address"]: item for item in index["frames"]}
    results = [analyze_sample(frames, *sample, rom) for sample in SAMPLES]
    data = {
        "rom_sha256": index["rom_sha256"],
        "source_sprite_decoder": str(FRAME_INDEX.relative_to(ROOT)),
        "reference_role": "CPU RAM OAM-shadow snapshots validate ROM-source geometry; no capture pixels become assets.",
        "confirmed_model": {
            "ordinary_x": "animation_origin_x + descriptor_x",
            "mirrored_x": "animation_origin_x - descriptor_x",
            "y": "animation_origin_y + descriptor_y",
            "attribute_bit_6": "animation_mirror XOR descriptor_flip_h",
            "attribute_bit_5": "behind-background priority on title sample",
            "left_clip": "when computed X < 0, OAM Y=248 and attribute bit 2 set; X wraps to byte",
            "initial_position": "F1 X/Y operand doubles to OAM origin in logo/portrait samples; title Y receives ROM-proven extra +$30 via CPU $890C.",
        },
        "title_transition_byte_evidence": title_transition_byte_evidence(rom),
        "limitations": "Only listed frames and first contiguous sprite object were checked; scene-wide origin, animation tick scheduling, right-edge clipping and actual PPU OAM transfer require separate evidence.",
        "samples": results,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(data, indent=2) + "\n")
    for item in results:
        print(item["capture_frame"], item["animation_id"],
              item["sprite_frame_cpu_address"],
              f'{item["exact_oam_entries"]}/{item["descriptor_count"]}',
              f'origin=({item["origin_x_pixels"]},{item["origin_y_oam_units"]})',
              "mirrored" if item["horizontal_mirror"] else "normal")


if __name__ == "__main__":
    main()
