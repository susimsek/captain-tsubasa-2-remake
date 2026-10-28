#!/usr/bin/env python3
"""Decode byte boundaries for KICK OFF cutscene commands from preserved ROM spans.

This creates source-indexed event manifests for research/runtime work. It does
not assign frame timing or claim that a parsed command has been implemented.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "reference/rom_extract/gameplay"
OUTPUT_DIR = ROOT / "assets/gameplay/rom_logic"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
COMMANDS = {
    0xE8: ("visual_preset", 1), 0xE9: ("screen_on", 0),
    0xEA: ("screen_off_clear", 0), 0xEB: ("wait_for_input", 0),
    0xEC: ("commentator_portrait", 1), 0xED: ("sound_command", 1),
    0xEE: ("clear_lower_area", 0), 0xEF: ("toggle_mouth", 0),
    0xF0: ("text_base_ppu_address", 2), 0xF1: ("dialog_window", 1),
    0xF2: ("text_speed", 1), 0xF3: ("palette_command", 1),
    0xF4: ("text_brightness_command", 1), 0xF5: ("visual_flag", 1),
    0xF6: ("pause_frames", 1), 0xF7: ("toggle_camera", 0),
    0xF8: ("visual_subroutine", 1), 0xF9: ("background_1", 1),
    0xFA: ("background_2", 1), 0xFB: ("animations", None),
    0xFC: ("fc_handler", 0), 0xFD: ("clear_text", 0),
    0xFE: ("jump", 2), 0xFF: ("exit", 0),
}
COMPACT_PAUSE_TICKS = [1, 10, 20, 40, 60, 80, 120, 240]


def decode(script: bytes, start_cpu: int, start_file: int) -> list[dict]:
    events: list[dict] = []
    cursor = 0
    while cursor < len(script):
        start = cursor
        opcode = script[cursor]
        event: dict
        if opcode <= 0xD7:
            cursor += 1
            while cursor < len(script) and script[cursor] <= 0xD7:
                cursor += 1
            event = {"kind": "text_tile_ids", "tile_ids": list(script[start:cursor])}
        elif 0xD8 <= opcode <= 0xDF:
            event = {"kind": "compact_pause", "ticks": COMPACT_PAUSE_TICKS[opcode - 0xD8]}
            cursor += 1
        elif 0xE0 <= opcode <= 0xE7:
            event = {"kind": "text_cursor_back", "tile_count": opcode - 0xE0}
            cursor += 1
        else:
            if opcode not in COMMANDS:
                raise ValueError(f"Unknown opcode ${opcode:02X} at script offset ${cursor:04X}")
            kind, fixed_length = COMMANDS[opcode]
            if opcode == 0xFB:
                operand_count = 1 + script[cursor + 1]
            elif opcode == 0xF3 and script[cursor + 1] == 0xFF:
                operand_count = 3
            else:
                operand_count = int(fixed_length)
            args = list(script[cursor + 1:cursor + 1 + operand_count])
            if len(args) != operand_count:
                raise ValueError(f"Truncated ${opcode:02X} command at script offset ${cursor:04X}")
            cursor += 1 + operand_count
            event = {"kind": kind, "opcode": opcode, "arguments": args}
            if opcode == 0xFB:
                event["animation_ids"] = args[1:]
            elif opcode in (0xED, 0xF9, 0xFA):
                event["id"] = args[0]
            elif opcode == 0xF6:
                event["frame_count_operand"] = args[0]
            elif opcode == 0xFE:
                event["target_cpu_address"] = args[0] | (args[1] << 8)

        raw = script[start:cursor]
        event.update({
            "event_index": len(events),
            "script_offset": start,
            "cpu_address": start_cpu + start,
            "file_offset": start_file + start,
            "raw_bytes": list(raw),
            "raw_hex": raw.hex(" "),
        })
        events.append(event)
        if opcode == 0xFF:
            if cursor != len(script):
                raise ValueError("Execution stream contains trailing bytes after the first FF.")
            break
    if not events or events[-1]["kind"] != "exit":
        raise ValueError("Execution stream does not end at the parsed FF command.")
    if bytes(value for event in events for value in event["raw_bytes"]) != script:
        raise ValueError("Decoded event byte spans do not reconstruct the source stream.")
    return events


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for cutscene_id in (1, 2):
        stem = f"kickoff_cutscene_{cutscene_id:02d}"
        metadata = json.loads((SOURCE_DIR / f"{stem}.json").read_text(encoding="utf-8"))
        if metadata.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
            raise SystemExit(f"Cutscene {cutscene_id} metadata belongs to another ROM.")
        script = (SOURCE_DIR / f"{stem}_execution.bin").read_bytes()
        digest = hashlib.sha256(script).hexdigest()
        if digest != metadata.get("execution_stream_sha256"):
            raise SystemExit(f"Cutscene {cutscene_id} execution stream hash mismatch.")
        events = decode(
            script,
            int(metadata["execution_stream_cpu_range"][0], 16),
            int(metadata["execution_stream_file_range"][0], 16),
        )
        output = {
            "schema": 1,
            "name": stem,
            "source_rom_sha256": EXPECTED_ROM_SHA256,
            "source_execution_stream_sha256": digest,
            "source_resource": metadata["execution_stream_resource"],
            "execution_stream_cpu_range": metadata["execution_stream_cpu_range"],
            "execution_stream_file_range": metadata["execution_stream_file_range"],
            "event_count": len(events),
            "event_boundaries_byte_verified": True,
            "frame_timing_decoded": False,
            "asset_producers_decoded": False,
            "events": events,
        }
        path = OUTPUT_DIR / f"{stem}_events.json"
        path.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"{path.relative_to(ROOT)}: {len(events)} ROM-indexed events; timing/assets remain open")


if __name__ == "__main__":
    main()
