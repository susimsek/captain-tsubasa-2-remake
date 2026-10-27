#!/usr/bin/env python3
"""Extract the supplied Turkish ROM's cold-boot cutscene 0 without a disassembly.

This is a byte-preserving research export. It does not decode the scene art or
infer rendered frame times. All file offsets include the 16-byte iNES header.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference" / "rom_extract" / "intro"

COMMANDS = {
    0xE8: ("visual_preset", 1),
    0xE9: ("screen_on", 0),
    0xEA: ("screen_off_clear", 0),
    0xEB: ("wait_for_input", 0),
    0xEC: ("commentator_portrait", 1),
    0xED: ("sound_command", 1),
    0xEE: ("clear_lower_area", 0),
    0xEF: ("toggle_mouth", 0),
    0xF0: ("text_base_ppu_address", 2),
    0xF1: ("dialog_window", 1),
    0xF2: ("text_speed", 1),
    0xF3: ("palette_command", 1),
    0xF4: ("text_brightness_command", 1),
    0xF5: ("visual_flag", 1),
    0xF6: ("pause_frames", 1),
    0xF7: ("toggle_camera", 0),
    0xF8: ("visual_subroutine", 1),
    0xF9: ("background_1", 1),
    0xFA: ("background_2", 1),
    0xFB: ("animations", -1),
    0xFC: ("new_text_line", 0),
    0xFD: ("clear_text", 0),
    0xFE: ("jump", 2),
    0xFF: ("exit", 0),
}


def file_offset(bank: int, cpu_address: int) -> int:
    return 16 + bank * 0x2000 + cpu_address - 0xA000


def word(data: bytes, at: int) -> int:
    return data[at] | data[at + 1] << 8


def find_interpreter_end(rom: bytes, bank: int, start_cpu: int) -> int:
    """Return the CPU address immediately after the first reachable FF.

    FC is a counted graphics block in this ROM. Its payload bytes must not be
    interpreted as commands, and cutscene pointer-table entries are not
    necessarily exclusive end bounds.
    """
    p = start_cpu
    while True:
        at = file_offset(bank, p)
        op = rom[at]
        if op <= 0xD7:
            p += 1
            while rom[file_offset(bank, p)] <= 0xD7:
                p += 1
        elif 0xD8 <= op <= 0xE7 or op in (0xE9, 0xEA, 0xEB, 0xEE, 0xEF, 0xF7, 0xFD):
            p += 1
        elif op == 0xFC:
            count = rom[at + 1] or 0x100
            p += 2 + count
        elif op == 0xFB:
            p += 2 + rom[at + 1]
        elif op == 0xF0:
            p += 3
        elif op == 0xF3:
            p += 4 if rom[at + 1] == 0xFF else 2
        elif op in (0xE8, 0xEC, 0xED, 0xF1, 0xF2, 0xF4, 0xF5, 0xF6, 0xF8, 0xF9, 0xFA):
            p += 2
        elif op == 0xFE:
            raise ValueError(f"Reachable FE jump at CPU ${p:04X}; trace its target before bounding the stream")
        elif op == 0xFF:
            return p + 1
        else:
            raise ValueError(f"Unknown cutscene opcode {op:02X} at CPU ${p:04X}")


def h(value: int, width: int = 2) -> str:
    return f"0x{value:0{width}X}"


def parse_animation_entry(data: bytes, start_file_offset: int) -> dict:
    """Read the entry path only; branched bytecode after the first exit is raw."""
    commands = []
    p = 1
    while p < len(data):
        op = data[p]
        args = b""
        detail = {}
        terminal = False
        if op < 0x80:
            kind = "duration"
            detail["frames"] = op * 2
        elif op < 0xA0:
            kind = "sprite_frame"
            args = data[p + 1 : p + 2]
            if len(args) == 1:
                detail["cpu_address"] = h(((op + 0x20) << 8) | args[0], 4)
        elif op < 0xC0:
            kind = "jump"
            args = data[p + 1 : p + 2]
            if len(args) == 1:
                detail["target_cpu_address"] = h((op << 8) | args[0], 4)
            terminal = True
        elif op < 0xE0:
            kind = "branch_or_animation_internal"
            terminal = True
        elif op < 0xF0:
            kind = "repeat_begin"
            detail["count"] = op - 0xE0
        elif op == 0xF0:
            kind = "repeat_end"
        elif op == 0xF1:
            kind = "set_position_y_x"
            args = data[p + 1 : p + 3]
            if len(args) == 2:
                detail.update({"y": args[0], "x": args[1]})
        elif op in (0xF2, 0xF3, 0xF8):
            kind = {0xF2: "set_y", 0xF3: "set_x", 0xF8: "set_palette"}[op]
            args = data[p + 1 : p + 2]
        elif op in (0xF5, 0xF6):
            kind = "mirror_on" if op == 0xF5 else "mirror_off"
        elif op == 0xF7:
            kind = "physics"
            args = data[p + 1 : p + 4]
        elif op == 0xF9:
            kind = "set_animation_flag"
        elif op == 0xFA:
            kind = "dialog_branch"
            terminal = True
        elif op == 0xFF:
            kind = "exit"
            terminal = True
        else:
            kind = "unknown"
            terminal = True
        raw = data[p : p + 1 + len(args)]
        command = {"kind": kind, "file_offset": h(start_file_offset + p, 6), "raw_hex": raw.hex(" ")}
        command.update(detail)
        commands.append(command)
        p += len(raw)
        if terminal:
            break
    return {
        "sprite_palette_index": h(data[0]),
        "entry_commands": commands,
        "unparsed_tail_hex": data[p:].hex(" "),
        "caution": "Only the linear entry path is decoded. Jump targets and branch tails may share data and need the animation interpreter for full playback.",
    }


def main() -> None:
    rom = ROM.read_bytes()
    assert rom[:4] == b"NES\x1a" and rom[4] == 16 and rom[5] == 16
    sha = hashlib.sha256(rom).hexdigest()

    # The selected bank comes from the supplied ROM's $8AEE table. For
    # cutscene 0, CPU $8464 chooses bank 3; its first pointer is $A020.
    bank_table = rom[0xAFE:0xB07]
    assert bank_table == bytes.fromhex("00 03 10 04 20 05 60 06 FF")
    pointer_table_offset = file_offset(3, 0xA000)
    start_cpu = word(rom, pointer_table_offset)
    next_cpu = word(rom, pointer_table_offset + 2)
    assert (start_cpu, next_cpu) == (0xA020, 0xA2A1)
    start = file_offset(3, start_cpu)
    end = file_offset(3, next_cpu)
    script = rom[start:end]
    execution_end_cpu = find_interpreter_end(rom, 3, start_cpu)
    execution_end = file_offset(3, execution_end_cpu)
    execution_script = rom[start:execution_end]
    execution_terminator_cpu = execution_end_cpu - 1
    assert rom[file_offset(3, execution_terminator_cpu)] == 0xFF

    events: list[dict] = []
    i = 0
    while i < len(script):
        op = script[i]
        at = start + i
        if op <= 0xD7:
            j = i + 1
            while j < len(script) and script[j] <= 0xD7:
                j += 1
            raw = script[i:j]
            event = {"kind": "text_tile_ids", "tile_ids_hex": raw.hex(" ")}
            size = len(raw)
        elif 0xD8 <= op <= 0xDF:
            # Confirmed by supplied ROM's interpreter at file 0x0504–0x052C
            # and its eight delay values at file 0x0AF6–0x0AFD.
            event = {"kind": "compact_pause", "frames": rom[0xAF6 + op - 0xD8]}
            size = 1
        elif 0xE0 <= op <= 0xE7:
            event = {"kind": "text_cursor_back", "tiles": op - 0xE0}
            size = 1
        else:
            kind, argc = COMMANDS[op]
            if op == 0xFB:
                argc = 1 + script[i + 1]
            elif op == 0xF3 and script[i + 1] == 0xFF:
                argc = 3
            size = 1 + argc
            args = list(script[i + 1 : i + size])
            event = {"kind": kind, "opcode": h(op), "arguments_hex": bytes(args).hex(" ")}
            if kind == "animations":
                event["animation_ids"] = [h(x) for x in args[1:]]
            elif kind in ("background_1", "background_2"):
                event["background_id"] = h(args[0])
            elif kind in ("pause_frames",):
                event["frames"] = args[0]
            elif kind == "sound_command":
                event["sound_id"] = h(args[0])
            elif kind == "jump":
                event["target_cpu_address"] = h(args[0] | args[1] << 8, 4)
        event.update({"file_offset": h(at, 6), "cpu_address": h(start_cpu + i, 4), "raw_hex": script[i : i + size].hex(" ")})
        events.append(event)
        i += size
    assert i == len(script)
    assert events[-1]["kind"] == "jump" and events[-1]["target_cpu_address"] == "0xA020"

    # Background table is bank 7 at $A000. Copy just the entries used by
    # cutscene 0, each bounded by the next table pointer in the same bank.
    bg_ids = sorted({int(e["background_id"], 16) for e in events if "background_id" in e} | {0x17})
    bg_table = file_offset(7, 0xA000)
    backgrounds = []
    for bg_id in bg_ids:
        p = word(rom, bg_table + 2 * bg_id)
        q = word(rom, bg_table + 2 * (bg_id + 1))
        source = file_offset(7, p)
        data = rom[source : file_offset(7, q)]
        (OUT / f"background_{bg_id:02X}.bin").parent.mkdir(parents=True, exist_ok=True)
        (OUT / f"background_{bg_id:02X}.bin").write_bytes(data)
        backgrounds.append({
            "id": h(bg_id), "pointer_table_file_offset": h(bg_table + 2 * bg_id, 6),
            "cpu_address": h(p, 4), "file_offset": h(source, 6),
            "length_bytes": len(data), "raw_hex": data.hex(" "),
            "source_bin": f"reference/rom_extract/intro/background_{bg_id:02X}.bin",
            "used_by": "title_entry" if bg_id == 0x17 else "cutscene_00",
        })

    # Animation IDs 00–6C index bank 9; 6D onward index bank 10.
    anim_ids = sorted({int(a, 16) for e in events for a in e.get("animation_ids", [])})
    animations = []
    for anim_id in anim_ids:
        bank = 9 if anim_id < 0x6D else 10
        index = anim_id if bank == 9 else anim_id - 0x6D
        table = file_offset(bank, 0xA000)
        p = word(rom, table + 2 * index)
        q = word(rom, table + 2 * (index + 1))
        source = file_offset(bank, p)
        data = rom[source : file_offset(bank, q)] if q >= p else b""
        (OUT / f"animation_{anim_id:02X}.bin").write_bytes(data)
        animations.append({
            "id": h(anim_id), "prg_bank": bank,
            "pointer_table_file_offset": h(table + 2 * index, 6),
            "cpu_address": h(p, 4), "file_offset": h(source, 6),
            "next_pointer": h(q, 4), "length_bytes": len(data),
            "raw_hex": data.hex(" "),
            "source_bin": f"reference/rom_extract/intro/animation_{anim_id:02X}.bin",
            "entry_decode": parse_animation_entry(data, source) if data else None,
        })

    # One complete short animation command record: Tecmo Theater sprite.
    # Bank-0 interpreter $90FD takes the first byte as sprite palette index;
    # $9339 consumes F1,Y,X; $9241 maps 91 5B to CPU $B15B. The first four
    # bytes at that destination are read by $94D8 as sprite CHR bank selectors.
    logo_anim = next(a for a in animations if a["id"] == "0x8D")
    logo_raw = bytes.fromhex(logo_anim["raw_hex"])
    assert logo_raw == bytes.fromhex("36 F1 30 28 91 5B FF")
    logo_sprite_cpu = 0xB15B
    logo_sprite_file = file_offset(10, logo_sprite_cpu)
    logo_chr_header = rom[logo_sprite_file : logo_sprite_file + 4]
    (OUT / "animation_8D_sprite_chr_header.bin").write_bytes(logo_chr_header)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "cutscene_00.bin").write_bytes(script)
    (OUT / "cutscene_00_execution.bin").write_bytes(execution_script)
    result = {
        "rom_file": ROM.name,
        "rom_sha256": sha,
        "status": "byte-exact extraction; renderer semantics and per-frame timing not yet reconstructed",
        "events_semantics": "events below are a lexical export of the pointer-to-next-pointer byte span, not the handler-aware execution stream; see execution_stream and fc_scene_boundary_audit.md",
        "entry": {
            # Startup loads cutscene ID 0 at $8023, then calls $8464 at $8025.
            # File offset 0x32 is only the high operand byte of the prior
            # JSR $9BA0 at file offset 0x30 / CPU $8020.
            "reset_call_file_offset": "0x000035",
            "reset_call_cpu_address": "0x8025",
            "reset_call_bytes": "a9 00 20 64 84",
            "preceding_init_call_file_offset": "0x000030",
            "preceding_init_call_cpu_address": "0x8020",
            "preceding_init_call_bytes": "20 a0 9b",
            "file_0x32_role": "high operand byte 0x9B of preceding JSR $9BA0; not the cutscene dispatch call",
            "cutscene_dispatch_file_offset": "0x000474",
            "cutscene_bank_table_file_offset": "0x000AFE",
            "cutscene_bank_table_hex": bank_table.hex(" "),
            "cutscene_id": 0,
            "prg_bank": 3,
            "pointer_table_file_offset": h(pointer_table_offset, 6),
            "cpu_address": h(start_cpu, 4),
            "file_offset": h(start, 6),
            "length_bytes": len(script),
            "next_cutscene_cpu_address": h(next_cpu, 4),
            "pointer_span_note": "The next pointer is an entry point, not a proven exclusive end; cutscene entries can alias counted FC payload bytes.",
            "source_bin": "reference/rom_extract/intro/cutscene_00.bin",
            "script_sha256": hashlib.sha256(script).hexdigest(),
            "terminal_behavior": "The FC-aware stream reaches FF at CPU $A6DB; the apparent FE at $A29E lies inside the A1B0 FC payload and is not dispatched.",
        },
        "execution_stream": {
            "prg_bank": 3,
            "start_cpu_address": h(start_cpu, 4),
            "start_file_offset": h(start, 6),
            "end_cpu_exclusive": h(execution_end_cpu, 4),
            "end_file_exclusive": h(execution_end, 6),
            "length_bytes": len(execution_script),
            "terminator_cpu_address": h(execution_terminator_cpu, 4),
            "terminator_file_offset": h(execution_end - 1, 6),
            "source_bin": "reference/rom_extract/intro/cutscene_00_execution.bin",
            "sha256": hashlib.sha256(execution_script).hexdigest(),
            "boundary_method": "Trace handler-aware commands from the entry until the first reachable FF; FC consumes its operand and counted graphics payload, with operand 00 meaning 256 payload bytes.",
        },
        "compact_pause_values_file_offset": "0x000AF6",
        "compact_pause_values_frames": list(rom[0xAF6:0xAFE]),
        "title_entry": {
            "start_press_poll_cpu_address": "0x8027",
            "start_press_poll_file_offset": "0x000037",
            "sound_stop_command": "0x01",
            "sound_stop_file_offset": "0x000058",
            "background_id": "0x17",
            "background_command_file_offset": "0x00007A",
            "initial_cursor_ppu_address": "0x220A",
            "other_cursor_ppu_address": "0x224A",
            "cursor_tile_id": "0x7F",
            "title_input_poll_file_offset": "0x0000B7",
            "title_input_mask": "0x3C",
            "select_press": "toggle 0x220A <-> 0x224A",
            "up_press": "set cursor to 0x220A (KICK OFF)",
            "down_press": "set cursor to 0x224A (CONTINUE)",
            "confirmation_press": "Start",
            "a_and_b_press": "ignored by the title-menu button mask",
            "caution": "Entry and cursor control are from byte-verified ROM bank 0; frame-accurate transition rendering remains to be measured.",
        },
        "events": events,
        "backgrounds": backgrounds,
        "animations": animations,
        "decoded_animation_8D": {
            "source_file_offset": logo_anim["file_offset"],
            "sprite_palette_index": "0x36",
            "position_y": 0x30,
            "position_x": 0x28,
            "sprite_frame_cpu_address": "0xB15B",
            "sprite_frame_file_offset": h(logo_sprite_file, 6),
            "sprite_chr_bank_selectors_hex": logo_chr_header.hex(" "),
            "sprite_chr_header_source_bin": "reference/rom_extract/intro/animation_8D_sprite_chr_header.bin",
            "command_sequence": ["F1 30 28: set initial Y,X", "91 5B: load sprite frame at $B15B", "FF: terminate animation"],
            "limitation": "The remainder of the sprite-frame command stream and OAM composition still require decoding.",
        },
    }
    (OUT / "cutscene_00.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Extracted {len(script)} bytes, {len(events)} events, {len(backgrounds)} backgrounds, {len(animations)} animation records")


if __name__ == "__main__":
    main()
