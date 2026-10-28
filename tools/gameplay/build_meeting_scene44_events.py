#!/usr/bin/env python3
"""Build a byte-indexed event stream for the supplied ROM's scene $44.

Scene $44 contains a real FE jump. Its two operand bytes overlap the following
scene's pointer span, so this tool preserves the two execution source segments
separately and also emits a flattened, project-owned runtime stream.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from build_kickoff_cutscene_events import EXPECTED_ROM_SHA256, decode


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DATA_DIR = ROOT / "reference/rom_extract/gameplay/meeting_menu"
OUTPUT_DIR = ROOT / "assets/gameplay/rom_logic"
ENTRY_CPU = 0xBE84
ENTRY_FILE = 0x00BE94
ENTRY_WITH_JUMP_OPERAND_END_CPU = 0xBEA0
ENTRY_WITH_JUMP_OPERAND_LENGTH = ENTRY_WITH_JUMP_OPERAND_END_CPU - ENTRY_CPU
TARGET_CPU = 0xBED6
TARGET_FILE = 0x00BEE6


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("Supplied ROM SHA-256 mismatch.")

    entry = (DATA_DIR / "bank5_meeting_advice_scene_44_entry.bin").read_bytes()
    jump_operands = rom[ENTRY_FILE + len(entry):ENTRY_FILE + ENTRY_WITH_JUMP_OPERAND_LENGTH]
    target = (DATA_DIR / "bank5_meeting_advice_scene_44_jump_target.bin").read_bytes()
    if len(entry) != 26 or entry[-1] != 0xFE or jump_operands != bytes((0xD6, 0xBE)):
        raise SystemExit("Scene $44 FE source/overlapping operand bytes differ from the traced ROM.")
    if TARGET_CPU != int.from_bytes(jump_operands, "little"):
        raise SystemExit("Scene $44 jump operand does not point to the preserved target span.")
    if target != bytes((0xE8, 0x01, 0xF3, 0x00, 0xFF)):
        raise SystemExit("Scene $44 jump target differs from its byte-checked ROM span.")

    entry_with_operand = entry + jump_operands
    execution_stream = entry_with_operand + target
    events = decode(execution_stream, ENTRY_CPU, ENTRY_FILE)
    for event in events:
        offset = int(event["script_offset"])
        if offset >= ENTRY_WITH_JUMP_OPERAND_LENGTH:
            segment_offset = offset - ENTRY_WITH_JUMP_OPERAND_LENGTH
            event["cpu_address"] = TARGET_CPU + segment_offset
            event["file_offset"] = TARGET_FILE + segment_offset
            event["source_segment_index"] = 1
        else:
            event["source_segment_index"] = 0

    entry_resource = DATA_DIR / "bank5_meeting_scene_44_entry_with_jump_operand.bin"
    execution_resource = DATA_DIR / "scene_44_execution.bin"
    entry_resource.write_bytes(entry_with_operand)
    execution_resource.write_bytes(execution_stream)

    span_manifest = {
        "name": "supplied_turkish_rom_scene_44_execution_spans",
        "source_rom": ROM_PATH.name,
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "execution_stream_sha256": sha256(execution_stream),
        "runtime_stream_resource": "reference/rom_extract/gameplay/meeting_menu/scene_44_execution.bin",
        "runtime_stream_is_flattened": True,
        "segments": [
            {
                "execution_stream_offset_range": [0, ENTRY_WITH_JUMP_OPERAND_LENGTH],
                "source_resource": "reference/rom_extract/gameplay/meeting_menu/bank5_meeting_scene_44_entry_with_jump_operand.bin",
                "cpu_start": f"0x{ENTRY_CPU:04X}",
                "file_start": f"0x{ENTRY_FILE:06X}",
                "length_bytes": len(entry_with_operand),
                "sha256": sha256(entry_with_operand),
            },
            {
                "execution_stream_offset_range": [ENTRY_WITH_JUMP_OPERAND_LENGTH, len(execution_stream)],
                "source_resource": "reference/rom_extract/gameplay/meeting_menu/bank5_meeting_advice_scene_44_jump_target.bin",
                "cpu_start": f"0x{TARGET_CPU:04X}",
                "file_start": f"0x{TARGET_FILE:06X}",
                "length_bytes": len(target),
                "sha256": sha256(target),
            },
        ],
        "note": "The $FE operands at $BE9E-$BE9F are also the first two bytes of the next pointer span; they are included in segment 0, not inferred or synthesized.",
    }
    (DATA_DIR / "scene_44_execution_spans.json").write_text(
        json.dumps(span_manifest, indent=2) + "\n", encoding="utf-8"
    )

    manifest = {
        "schema": 1,
        "name": "kickoff_meeting_scene_44",
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "source_execution_stream_sha256": sha256(execution_stream),
        "source_resource": "reference/rom_extract/gameplay/meeting_menu/scene_44_execution.bin",
        "execution_stream_cpu_range": [f"0x{ENTRY_CPU:04X}", f"0x{TARGET_CPU + len(target) - 1:04X}"],
        "execution_stream_file_range": [f"0x{ENTRY_FILE:06X}", f"0x{TARGET_FILE + len(target):06X}"],
        "execution_stream_length_bytes": len(execution_stream),
        "execution_segments": span_manifest["segments"],
        "event_count": len(events),
        "event_boundaries_byte_verified": True,
        "frame_timing_decoded": False,
        "asset_producers_decoded": False,
        "events": events,
    }
    output_path = OUTPUT_DIR / "kickoff_meeting_scene_44_events.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{output_path.relative_to(ROOT)}: {len(events)} ROM-indexed events, {len(execution_stream)} bytes")
    print(f"scene $44 source stream SHA-256: {sha256(execution_stream)}")


if __name__ == "__main__":
    main()
