#!/usr/bin/env python3
"""Build runtime-safe compact event data from byte-verified ROM extracts.

The ROM is read only by this offline authoring tool. Godot loads the generated
JSON and never opens the ROM. The archival 641-byte pointer span and the
handler-bounded execution stream are validated separately; generated event
spans must reconstruct the latter byte-for-byte before output is written.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
EXTRACT = ROOT / "reference/rom_extract/intro"
OUTPUT = ROOT / "assets/opening/rom_logic/cutscene_00_vm.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_POINTER_SPAN_SHA256 = "499ccb62b8b2b9118d7ebfaa6e6b9fce46806cd3b9173b5e1d5d61de21c2a6b7"
EXPECTED_EXECUTION_STREAM_SHA256 = "6b620e8a888690b2ddd42c1de986a880d3c78d0b264db5db1d0c226166f0cca4"

# Lengths for the supplied ROM's bank-0 cutscene interpreter. None means the
# command has a data-dependent length handled below.
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
# FC's handler at $8836 calls $9085; it consumes a count byte and that
# many graphics payload bytes before bytecode dispatch resumes.
    0xFC: ("dialog_line_control", 1), 0xFD: ("clear_text", 0),
    0xFE: ("jump", 2), 0xFF: ("exit", 0),
}

COMPACT_PAUSE_TICKS = [1, 10, 20, 40, 60, 80, 120, 240]


def byte_array(hex_text: str) -> list[int]:
    return list(bytes.fromhex(hex_text))


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha = hashlib.sha256(rom).hexdigest()
    if rom_sha != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_sha}")

    metadata = json.loads((EXTRACT / "cutscene_00.json").read_text())
    pointer_span = (EXTRACT / "cutscene_00.bin").read_bytes()
    pointer_span_sha = hashlib.sha256(pointer_span).hexdigest()
    if pointer_span_sha != EXPECTED_POINTER_SPAN_SHA256 or pointer_span_sha != metadata["entry"]["script_sha256"]:
        raise SystemExit(f"Cutscene pointer-span hash mismatch: {pointer_span_sha}")

    source_start = int(metadata["entry"]["file_offset"], 16)
    pointer_length = int(metadata["entry"]["length_bytes"])
    if pointer_span != rom[source_start : source_start + pointer_length]:
        raise SystemExit("Preserved pointer span is not byte-identical to the recorded ROM range")

    execution = metadata["execution_stream"]
    script = (EXTRACT / "cutscene_00_execution.bin").read_bytes()
    script_sha = hashlib.sha256(script).hexdigest()
    if script_sha != EXPECTED_EXECUTION_STREAM_SHA256 or script_sha != execution["sha256"]:
        raise SystemExit(f"Expanded execution-stream hash mismatch: {script_sha}")
    execution_start = int(execution["start_file_offset"], 16)
    execution_end = int(execution["end_file_exclusive"], 16)
    if execution_start != source_start or script != rom[execution_start:execution_end]:
        raise SystemExit("Expanded execution stream is not byte-identical to its recorded ROM range")

    # Validate the old pointer-span export as archival evidence, then decode
    # the bounded execution stream. FC owns its counted graphics payload.
    lexical_bytes = bytearray()
    for index, source_event in enumerate(metadata["events"]):
        raw = byte_array(source_event["raw_hex"])
        source_offset = int(source_event["file_offset"], 16)
        expected_offset = source_start + len(lexical_bytes)
        if source_offset != expected_offset:
            raise SystemExit(f"Lexical event {index} at {source_offset:#x}, expected {expected_offset:#x}")
        if rom[source_offset : source_offset + len(raw)] != bytes(raw):
            raise SystemExit(f"Lexical event {index} bytes disagree with ROM at {source_offset:#x}")
        lexical_bytes.extend(raw)
    if bytes(lexical_bytes) != pointer_span or len(metadata["events"]) != 181:
        raise SystemExit("Lexical export does not reproduce all 181 source records")

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
            event = {"k": "text_tile_ids", "tiles": list(script[start:cursor])}
        elif 0xD8 <= opcode <= 0xDF:
            event = {"k": "compact_pause", "ticks": COMPACT_PAUSE_TICKS[opcode - 0xD8]}
            cursor += 1
        elif 0xE0 <= opcode <= 0xE7:
            event = {"k": "text_cursor_back", "tiles": opcode - 0xE0}
            cursor += 1
        else:
            if opcode not in COMMANDS:
                raise SystemExit(f"Unknown cutscene opcode {opcode:02X} at source offset {source_start + cursor:#x}")
            kind, argc = COMMANDS[opcode]
            if opcode == 0xFB:
                argc = 1 + script[cursor + 1]
            elif opcode == 0xF3 and script[cursor + 1] == 0xFF:
                argc = 3
            elif opcode == 0xFC:
                payload_count = script[cursor + 1] or 0x100
                argc = 1 + payload_count
            raw_args = list(script[cursor + 1 : cursor + 1 + int(argc)])
            if len(raw_args) != int(argc):
                raise SystemExit(f"Truncated opcode {opcode:02X} at source offset {source_start + cursor:#x}")
            event = {"k": kind, "op": opcode, "a": raw_args}
            if opcode == 0xFC:
                event["handler_cpu"] = 0x8836
                event["handler_file"] = 0x00846
                count = raw_args[0] or 0x100
                event["operand"] = raw_args[0]
                event["payload_count"] = count
                event["payload"] = raw_args[1:]
                event["handler_semantics"] = "$9085 advances past FC and its count byte, consumes count graphics descriptors (operand 00 means 256), then resumes bytecode"
                event["semantics_complete"] = True
            elif opcode == 0xF2:
                event["handler_cpu"] = 0x8677
                event["handler_file"] = 0x00687
                event["sets_ram"] = 0x55
            elif opcode == 0xF1:
                event["handler_cpu"] = 0x8649
                event["handler_file"] = 0x00659
            elif opcode in (0xF9, 0xFA):
                event["id"] = raw_args[0]
            elif opcode == 0xFB:
                event["ids"] = raw_args[1:]
            elif opcode == 0xED:
                event["id"] = raw_args[0]
            elif opcode == 0xF6:
                event["ticks"] = raw_args[0]
            elif opcode == 0xFE:
                event["target"] = raw_args[0] | raw_args[1] << 8
            cursor += 1 + int(argc)

        raw = list(script[start:cursor])
        event["i"] = len(events)
        event["b"] = raw
        event["rom"] = source_start + start
        event["cpu"] = int(metadata["entry"]["cpu_address"], 16) + start
        events.append(event)

    reconstructed = bytes(value for event in events for value in event["b"])
    if reconstructed != script or events[-1].get("k") != "exit" or events[-1]["b"] != [0xFF]:
        raise SystemExit("FC-aware execution events do not reproduce the bounded stream through FF")

    output = {
        "schema": 1,
        "name": "turkish_rom_cutscene_00",
        "source": {
            "rom_sha256": rom_sha,
            "pointer_span_file_range": [source_start, source_start + pointer_length],
            "pointer_span_sha256": pointer_span_sha,
            "script_sha256": script_sha,
            "rom_file_range": [execution_start, execution_end],
            "prg_bank": int(metadata["entry"]["prg_bank"]),
            "cpu_range": [int(metadata["entry"]["cpu_address"], 16), int(execution["end_cpu_exclusive"], 16) - 1],
            "terminator_cpu": int(execution["terminator_cpu_address"], 16),
            "terminator_file": int(execution["terminator_file_offset"], 16),
            "boundary_method": execution["boundary_method"],
            "entry_dispatch_file_offset": int(metadata["entry"]["cutscene_dispatch_file_offset"], 16),
            "bank_table_file_offset": int(metadata["entry"]["cutscene_bank_table_file_offset"], 16),
            "pointer_table_file_offset": int(metadata["entry"]["pointer_table_file_offset"], 16),
        },
        "opcode_notes": {
            "text_bytes": "00-D7 are original text tile IDs; not Unicode.",
            "compact_pause": "D8-DF map through ROM file 0x000AF6-0x000AFD to exact wait operands 1,10,20,40,60,80,120,240.",
            "text_cursor_back": "E0-E7 move the interpreter text cursor backward by opcode-E0 tile units.",
            "control": "E8-FF opcodes use the byte lengths and command meanings recovered from the supplied ROM bank-0 interpreter; variable FB and F3-FF forms are preserved in event bytes/arguments.",
            "jump": "The lexical pointer-span record contains FE 20 A0 at $A29E, but FC $A1B0 consumes it as payload; no FE is reachable in this execution stream. Outer bank-0 code polls Start concurrently.",
            "input_wait": "The old 641-byte lexical pointer span contains no dispatched EB. The expanded FC-aware stream reaches EB at CPU $A326; its input condition and timing are not modeled here.",
            "timing_limit": "Pause operand values are exact; conversion to Godot/visible NES frames and text/animation/PPU commit scheduling are not fully verified.",
            "lexical_export_record_count": len(metadata["events"]),
            "visual_limit": "Visual subroutines, palette/fade effects, portrait composition, and animation playback are exposed as source events/state for a renderer; not all raster semantics are reconstructed by this VM.",
            "dialog_line_control": "FC dispatches through CPU $8836 / ROM file 0x000846 to $9085 / file 0x001095. It consumes the next byte as a descriptor count (00 means 256), then that many graphics descriptor bytes. Payload bytes are preserved in each event and never dispatched as commands.",
            "pointer_aliasing": "Cutscene table entries are starts, not exclusive ends. Entry 0's FC-aware stream overlaps entries 1 and 3, then reaches FF at $A6DB.",
        },
        "events": events,
    }
    OUTPUT.write_text(json.dumps(output, separators=(",", ":")) + "\n")
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(events)} handler-length events from {len(metadata['events'])} lexical records, {len(script)} ROM bytes)")


if __name__ == "__main__":
    main()
