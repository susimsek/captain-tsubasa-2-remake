#!/usr/bin/env python3
"""Decode the sprite-frame bytecode referenced by Turkish ROM intro animations.

This follows the original bank-0 parser at CPU $94D8-$96F1. The output is
ROM-source relative geometry, not a reconstructed emulator screenshot.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference" / "rom_extract" / "intro"


def source_offset(bank: int, cpu: int) -> int:
    if not 0xA000 <= cpu <= 0xBFFF:
        raise ValueError(f"CPU address outside selected PRG bank: {cpu:04X}")
    return 16 + bank * 0x2000 + cpu - 0xA000


def signed(value: int, bits: int) -> int:
    mask = (1 << bits) - 1
    value &= mask
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def decode_frame(rom: bytes, bank: int, start: int) -> dict:
    header_offset = source_offset(bank, start)
    chr_selectors = list(rom[header_offset : header_offset + 4])
    if len(chr_selectors) != 4:
        raise ValueError("Truncated CHR selectors")

    pc = start + 4
    stack: list[int] = []
    commands: list[dict] = []
    sprites: list[dict] = []
    x_step = None
    y_step = 0
    last_y_step = None
    visited = set()
    for _ in range(4096):
        state = (pc, tuple(stack))
        if state in visited:
            raise ValueError(f"Repeated bytecode state in frame {start:04X}: {state}")
        visited.add(state)
        at = source_offset(bank, pc)
        op = rom[at]
        command: dict = {"cpu_address": f"0x{pc:04X}", "file_offset": f"0x{at:06X}"}

        if op < 0x80:
            tile = rom[at + 1]
            y_step = signed((op >> 2) & 0x0F, 4) * 8
            last_y_step = y_step
            desc = {
                "kind": "sprite", "tile_id": f"0x{tile:02X}",
                "y_offset_from_animation": y_step,
                "x_offset_from_animation": x_step,
                "x_source": "animation_x_plus_band" if x_step is not None else "zeroed_x_register",
                "palette_low_bits": op & 3,
                "flip_h_bit": bool(op & 0x40),
                "raw_hex": rom[at : at + 2].hex(" "),
                "source_file_offset": f"0x{at:06X}",
            }
            sprites.append(desc)
            command.update({"kind": "sprite", "raw_hex": desc["raw_hex"], "sprite_index": len(sprites) - 1})
            pc += 2
        elif op < 0xA0:
            y_step = signed(op & 0x1F, 5) * 8
            last_y_step = y_step
            command.update({"kind": "set_y_band", "raw_hex": f"{op:02x}", "y_offset_from_animation": y_step})
            pc += 1
        elif op < 0xC0:
            x_step = signed(op & 0x1F, 5) * 8
            command.update({"kind": "set_x_band", "raw_hex": f"{op:02x}", "x_offset_from_animation": x_step})
            pc += 1
        elif op < 0xD0:
            packed_y, tile = rom[at + 1], rom[at + 2]
            # ROM routine $95EC-$967F: low nibble is signed X pixel delta,
            # bits 2-5 of the next byte are signed Y pixel delta from last
            # ordinary sprite. Animation flag bit 6 mirrors X at playback.
            dx = signed(op & 0x0F, 4)
            dy = signed((packed_y >> 2) & 0x0F, 4)
            desc = {
                "kind": "composite_sprite", "tile_id": f"0x{tile:02X}",
                "y_offset_from_animation": last_y_step + dy if last_y_step is not None else None,
                "y_source": "animation_y_plus_last_sprite" if last_y_step is not None else "previous_y_register_unresolved",
                "x_offset_from_animation": x_step + dx if x_step is not None else None,
                "x_source": "animation_x_plus_band" if x_step is not None else "zeroed_x_register",
                "x_pixel_delta": dx, "y_pixel_delta": dy,
                "palette_low_bits": packed_y & 3,
                "flip_h_bit": bool(packed_y & 0x40),
                "raw_hex": rom[at : at + 3].hex(" "),
                "source_file_offset": f"0x{at:06X}",
            }
            sprites.append(desc)
            command.update({"kind": "composite_sprite", "raw_hex": desc["raw_hex"], "sprite_index": len(sprites) - 1})
            pc += 3
        elif op in (0xFA, 0xFB):
            target = rom[at + 1] | rom[at + 2] << 8
            command.update({"kind": "call" if op == 0xFA else "jump", "raw_hex": rom[at : at + 3].hex(" "), "target_cpu_address": f"0x{target:04X}"})
            if op == 0xFA:
                if len(stack) >= 4:
                    raise ValueError(f"ROM animation call stack exceeded at {pc:04X}")
                stack.append(pc + 3)
            pc = target
        elif op == 0xFE:
            if not stack:
                raise ValueError(f"Return without call at {pc:04X}")
            target = stack.pop()
            command.update({"kind": "return", "raw_hex": "fe", "target_cpu_address": f"0x{target:04X}"})
            pc = target
        elif op == 0xFF:
            command.update({"kind": "end", "raw_hex": "ff"})
            commands.append(command)
            break
        else:
            raise ValueError(f"Unrecognized frame opcode {op:02X} at CPU {pc:04X}")
        commands.append(command)
    else:
        raise ValueError(f"Sprite frame {start:04X} did not terminate")

    return {
        "prg_bank": bank,
        "cpu_address": f"0x{start:04X}",
        "file_offset": f"0x{header_offset:06X}",
        "chr_selectors_hex": bytes(chr_selectors).hex(" "),
        "chr_selectors_source_file_offset": f"0x{header_offset:06X}",
        "commands": commands,
        "sprites": sprites,
        "caution": "Positions are relative to the live animation Y/X. Runtime mirror, clipping, CHR mapping, palette, sprite priority, and OAM update scheduling still apply.",
    }


def main() -> None:
    rom = ROM.read_bytes()
    index = json.loads((OUT / "cutscene_00.json").read_text())
    timing = json.loads((OUT / "animation_timing_entry.json").read_text())
    references: dict[tuple[int, int], list[str]] = {}
    for animation in index["animations"]:
        for command in animation["entry_decode"]["entry_commands"]:
            if command["kind"] == "sprite_frame":
                key = animation["prg_bank"], int(command["cpu_address"], 16)
                references.setdefault(key, []).append(animation["id"])

    # Entry commands contain only the first selected frame. The ROM animation
    # interpreter can change frame later, so also decode every frame pointer
    # reached by the extracted timing stream. These remain ROM byte decodes;
    # no emulator pixels are inputs to this asset index.
    animations_by_id = {animation["id"]: animation for animation in index["animations"]}
    for track in timing["animations"]:
        animation = animations_by_id.get(track["animation_id"])
        if animation is None:
            continue
        for beat in track["beats"]:
            frame_address = beat.get("sprite_frame_cpu_address")
            if frame_address:
                key = animation["prg_bank"], int(frame_address, 16)
                references.setdefault(key, []).append(animation["id"])

    frames = []
    for bank, cpu in sorted(references):
        frame = decode_frame(rom, bank, cpu)
        frame["referenced_by_animation_ids"] = sorted(set(references[bank, cpu]))
        frames.append(frame)
    output = {
        "rom_sha256": hashlib.sha256(rom).hexdigest(),
        "interpreter_cpu_range": "0x94D8-0x96F1",
        "interpreter_prg_bank": 0,
        "scope": "Sprite frames selected on linear entry paths and extracted animation timing beats; runtime motion/scene scheduling remain separate.",
        "frames": frames,
    }
    path = OUT / "sprite_frames_entry.json"
    path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
    print(f"Decoded {len(frames)} distinct ROM sprite frames, {sum(len(f['sprites']) for f in frames)} sprite descriptors")


if __name__ == "__main__":
    main()
