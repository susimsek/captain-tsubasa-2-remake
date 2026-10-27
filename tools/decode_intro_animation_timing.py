#!/usr/bin/env python3
"""Trace ROM intro animation bytecode timing, repeat stacks, and frame choices.

The bank-0 interpreter at CPU $9154-$94D7 supplies these bytecode rules.
Frame counts are interpreter ticks; scene scheduling and physical movement
must be combined separately to produce a final screen timeline.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference" / "rom_extract" / "intro"


def off(bank: int, cpu: int) -> int:
    if not 0xA000 <= cpu < 0xC000:
        raise ValueError(f"CPU pointer out of selected bank: {cpu:04X}")
    return 16 + bank * 0x2000 + cpu - 0xA000


def decode(rom: bytes, animation: dict) -> dict:
    bank = animation["prg_bank"]
    pc = int(animation["cpu_address"], 16) + 1
    stack: list[tuple[str, int, int]] = []
    state: dict = {
        "palette_index": int(animation["entry_decode"]["sprite_palette_index"], 16),
        "initial_y": None, "initial_x": None, "mirror_h": False,
        "physics_raw_hex": None, "sprite_frame_cpu_address": None,
    }
    beats: list[dict] = []
    commands: list[dict] = []
    tick = 0
    seen: dict[tuple, tuple[int, int]] = {}
    terminal: dict = {}

    for _ in range(8192):
        key = (pc, tuple(stack))
        if key in seen:
            old_tick, old_beat = seen[key]
            terminal = {"kind": "repeat_cycle", "at_relative_tick": tick,
                        "cycle_start_tick": old_tick, "cycle_length_ticks": tick - old_tick,
                        "cycle_start_beat_index": old_beat, "cpu_address": f"0x{pc:04X}"}
            break
        seen[key] = tick, len(beats)
        at = off(bank, pc)
        op = rom[at]
        raw_size = 1
        item: dict = {"at_relative_tick": tick, "cpu_address": f"0x{pc:04X}", "file_offset": f"0x{at:06X}"}
        next_pc = pc + 1
        stop_tick = False

        if op < 0x80:
            duration = op * 2
            item.update({"kind": "duration", "hold_ticks": duration})
            beats.append({"start_tick": tick, "hold_ticks": duration, **state})
            tick += duration
            stop_tick = True
        elif op < 0xA0:
            raw_size = 2
            frame = ((op + 0x20) << 8) | rom[at + 1]
            state["sprite_frame_cpu_address"] = f"0x{frame:04X}"
            item.update({"kind": "sprite_frame", "frame_cpu_address": f"0x{frame:04X}"})
            next_pc = pc + 2
        elif op < 0xC0:
            raw_size = 2
            target = (op << 8) | rom[at + 1]
            item.update({"kind": "jump", "target_cpu_address": f"0x{target:04X}"})
            next_pc = target
        elif op < 0xE0:
            raw_size = 2
            target = ((op - 0x20) << 8) | rom[at + 1]
            stack.append(("call", pc + 2, 0))
            item.update({"kind": "call", "target_cpu_address": f"0x{target:04X}", "depth": len(stack)})
            next_pc = target
        elif op < 0xF0:
            stack.append(("repeat", pc + 1, op - 0xE0))
            item.update({"kind": "repeat_begin", "count": op - 0xE0, "depth": len(stack)})
        elif op == 0xF0:
            if not stack or stack[-1][0] != "repeat":
                raise ValueError(f"Repeat end without repeat at {pc:04X}")
            kind, target, remaining = stack[-1]
            remaining -= 1
            if remaining:
                stack[-1] = kind, target, remaining
                next_pc = target
            else:
                stack.pop()
            item.update({"kind": "repeat_end", "remaining": remaining, "depth": len(stack)})
        elif op == 0xF1:
            raw_size = 3
            state["initial_y"], state["initial_x"] = rom[at + 1 : at + 3]
            item.update({"kind": "set_y_x", "y": state["initial_y"], "x": state["initial_x"]})
            next_pc = pc + 3
        elif op in (0xF2, 0xF3):
            raw_size = 2
            axis = "initial_y" if op == 0xF2 else "initial_x"
            state[axis] = rom[at + 1]
            item.update({"kind": "set_y" if op == 0xF2 else "set_x", "value": state[axis]})
            next_pc = pc + 2
        elif op == 0xF4:
            raw_size = 2
            duration = rom[at + 1]
            item.update({"kind": "direct_wait", "hold_ticks": duration})
            beats.append({"start_tick": tick, "hold_ticks": duration, **state})
            tick += duration
            next_pc = pc + 2
            stop_tick = True
        elif op in (0xF5, 0xF6):
            state["mirror_h"] = op == 0xF5
            item.update({"kind": "mirror_on" if op == 0xF5 else "mirror_off"})
        elif op == 0xF7:
            raw_size = 4
            state["physics_raw_hex"] = rom[at + 1 : at + 4].hex(" ")
            item.update({"kind": "set_physics", "physics_raw_hex": state["physics_raw_hex"]})
            next_pc = pc + 4
        elif op == 0xF8:
            raw_size = 2
            state["palette_index"] = rom[at + 1]
            item.update({"kind": "set_palette_index", "value": state["palette_index"]})
            next_pc = pc + 2
        elif op == 0xF9:
            item.update({"kind": "set_flag_bit4"})
        elif op == 0xFA:
            terminal = {"kind": "unresolved_fa_branch", "at_relative_tick": tick,
                        "cpu_address": f"0x{pc:04X}", "file_offset": f"0x{at:06X}"}
            item.update({"kind": "unresolved_fa_branch"})
        elif op == 0xFE:
            if not stack or stack[-1][0] != "call":
                raise ValueError(f"Call return without call at {pc:04X}")
            _, next_pc, _ = stack.pop()
            item.update({"kind": "call_return", "target_cpu_address": f"0x{next_pc:04X}"})
        elif op == 0xFF:
            terminal = {"kind": "exit", "at_relative_tick": tick,
                        "cpu_address": f"0x{pc:04X}", "file_offset": f"0x{at:06X}"}
            item.update({"kind": "exit"})
        else:
            terminal = {"kind": "unknown_opcode", "opcode": f"0x{op:02X}",
                        "at_relative_tick": tick, "cpu_address": f"0x{pc:04X}"}
            item.update({"kind": "unknown_opcode"})

        item["raw_hex"] = rom[at : at + raw_size].hex(" ")
        commands.append(item)
        pc = next_pc
        if terminal:
            break
        if stop_tick and tick > 100000:
            raise ValueError("Animation tick limit exceeded")
    else:
        raise ValueError(f"Animation {animation['id']} command limit exceeded")

    return {
        "animation_id": animation["id"], "prg_bank": bank,
        "start_cpu_address": animation["cpu_address"],
        "terminal": terminal, "beats": beats, "commands": commands,
        "caution": "Ticks follow ROM animation wait counters. Scene call timing, movement integration, palette effects and OAM clipping need separate reconstruction.",
    }


def main() -> None:
    rom = ROM.read_bytes()
    index = json.loads((OUT / "cutscene_00.json").read_text())
    animations = [decode(rom, a) for a in index["animations"]]
    path = OUT / "animation_timing_entry.json"
    path.write_text(json.dumps({
        "rom_sha256": hashlib.sha256(rom).hexdigest(),
        "interpreter_cpu_range": "0x9154-0x94D7", "animations": animations,
    }, indent=2) + "\n")
    for a in animations:
        print(a["animation_id"], len(a["beats"]), a["terminal"])


if __name__ == "__main__":
    main()
