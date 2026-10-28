#!/usr/bin/env python3
"""Preserve ROM source spans used by the first-command actor presenter."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_actors"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK_14_FILE_BASE = 0x028010
BANK_14_CPU_BASE = 0x8000
ANIMATION_POINTER_TABLE_FILE_OFFSET = 0x028978

# These IDs are supported by the same-input fresh-start actor trace and local
# scenario bytes. $78/$79/$90 are included because the writer trace shows their
# packet roots, while their upstream selector conditions remain unresolved.
ROUTE_ANIMATION_IDS = {
    0x8F: "scenario $35 record at file offset 0x0237E0 (02 3A 8F 73)",
    0x4E: "scenario $36 record at file offset 0x0237FF (20 0C 4E 74)",
    0x66: "scenario $36 record at file offset 0x023808 (32 72 66 F0)",
    0x4C: "scenario $36 record at file offset 0x02380E (32 1F 4C F0)",
    0x78: "observed route actor-packet selector at source frame 8759; upstream selector condition unresolved",
    0x79: "observed route actor-packet selector at source frames 8779 and 8781; upstream selector condition unresolved",
    0x90: "observed route actor-packet selector at source frame 8822; upstream selector condition unresolved",
    0xE6: "scenario $36 record at file offset 0x023815 (3E 01 E6 75); F8 jumps to CPU $961A within animation $78",
}

SPANS = [
    ("animation_5C_actor_packets_9357.bin", 0x029367, 26,
     "bank-14 animation $5C packet stream at CPU $9357; F4 selectors and three F1 constructors"),
    ("actor_record_pointer_table_88E4_00_03.bin", 0x0288F4, 8,
     "bank-14 actor-record pointer table indexes $00-$03"),
    ("motion_pointer_table_A1B4_00.bin", 0x02A1C4, 2,
     "bank-14 motion-script pointer table entry $00"),
    ("appearance_pointer_table_AC47_CA_CD.bin", 0x02ADEB, 8,
     "bank-14 appearance-script pointer entries $CA-$CD"),
    ("motion_script_A38A_A390.bin", 0x02A39A, 7,
     "bank-14 actor motion commands $A38A-$A390; zero-delta step and hold"),
    ("appearance_scripts_B5AC_B5B3.bin", 0x02B5BC, 8,
     "bank-14 appearance-script prefixes $B5AC-$B5B3; F7 held descriptors"),
    ("player_graphic_class_table_88F0_ids_00_22.bin", 0x028900, 35,
     "bank-14 player ID to shared sprite-layout selector table"),
    ("normal_player_palette_table_B80C_ids_00_22.bin", 0x02B81C, 175,
     "bank-14 normal-player palette table; 35 five-byte entries for IDs $00-$22"),
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_u16(data: bytes, offset: int) -> int:
    return data[offset] | (data[offset + 1] << 8)


def extract_route_animation_spans(rom: bytes) -> list[dict]:
    entries: list[dict] = []
    for animation_id, route_evidence in ROUTE_ANIMATION_IDS.items():
        pointer_offset = ANIMATION_POINTER_TABLE_FILE_OFFSET + animation_id * 2
        if pointer_offset + 4 > len(rom):
            raise SystemExit(f"Animation ${animation_id:02X} pointer pair is truncated")
        start_cpu = read_u16(rom, pointer_offset)
        end_cpu = read_u16(rom, pointer_offset + 2)
        if not BANK_14_CPU_BASE <= start_cpu < end_cpu <= 0xC000:
            raise SystemExit(
                f"Animation ${animation_id:02X} has invalid bank-$14 pointer span "
                f"${start_cpu:04X}..${end_cpu:04X}"
            )
        start_offset = BANK_14_FILE_BASE + start_cpu - BANK_14_CPU_BASE
        end_offset = BANK_14_FILE_BASE + end_cpu - BANK_14_CPU_BASE
        raw = rom[start_offset:end_offset]
        if not raw:
            raise SystemExit(f"Animation ${animation_id:02X} pointer-defined span is empty")
        if animation_id != 0xE6 and raw[-1] != 0xF0:
            raise SystemExit(
                f"Animation ${animation_id:02X} pointer-defined span does not end in $F0"
            )
        filename = f"route_animation_{animation_id:02X}.bin"
        (OUTPUT_DIR / filename).write_bytes(raw)
        entries.append({
            "path": f"reference/rom_extract/gameplay/first_command_actors/{filename}",
            "animation_id": f"${animation_id:02X}",
            "prg_bank": "$14",
            "pointer_table_cpu_address": "$8968",
            "pointer_table_file_offset": f"0x{pointer_offset:06X}",
            "start_cpu_address": f"0x{start_cpu:04X}",
            "end_cpu_address_exclusive": f"0x{end_cpu:04X}",
            "file_offset": f"0x{start_offset:06X}",
            "end_file_offset_exclusive": f"0x{end_offset:06X}",
            "length_bytes": len(raw),
            "sha256": sha256(raw),
            "purpose": f"Fresh-start route actor-animation stream; {route_evidence}",
            "source_span_method": "bank-$14 animation pointer table: current ID pointer to following ID pointer",
            "last_byte": f"${raw[-1]:02X}",
            "terminator_note": (
                "$E6 is a five-byte F5/F8 dispatch prefix; its $F8 operand jumps to CPU $961A within ID $78, so the pointer-table boundary is the source-span end and no local $F0 terminator is expected."
                if animation_id == 0xE6 else "$F0"
            ),
        })
    return entries


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Target ROM SHA-256 mismatch: {rom_hash}")
    if len(rom) != 393232:
        raise SystemExit(f"Unexpected target ROM size: {len(rom)}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries = []
    for filename, offset, length, purpose in SPANS:
        data = rom[offset:offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated ROM span at file offset 0x{offset:06X}")
        (OUTPUT_DIR / filename).write_bytes(data)
        entries.append({
            "path": f"reference/rom_extract/gameplay/first_command_actors/{filename}",
            "file_offset": f"0x{offset:06X}",
            "length_bytes": length,
            "sha256": sha256(data),
            "purpose": purpose,
        })
    route_animation_entries = extract_route_animation_spans(rom)
    entries.extend(route_animation_entries)

    manifest = {
        "schema": "first-command-rom-actor-source-v1",
        "source_rom_filename": ROM_PATH.name,
        "source_rom_sha256": rom_hash,
        "runtime_rom_dependency": False,
        "capture_or_screenshot_bytes_included": False,
        "route_animation_pointer_table": {
            "cpu_address": "$8968",
            "file_offset": "0x028978",
            "prg_bank": "$14",
            "cpu_window": "$8000-$BFFF",
            "file_window_base": "0x028010",
            "entry_width_bytes": 2,
            "span_rule": "selected ID pointer through the following ID pointer, exclusive",
            "route_animation_ids": [f"${animation_id:02X}" for animation_id in ROUTE_ANIMATION_IDS],
        },
        "entries": entries,
        "decoding_notes": {
            "actor_packets": "Scenario $44 selects animation $5C; F1 byte 5 chooses actor index ((b & $1C) >> 2), low bits become active flags, bytes 1/2 select motion/appearance tables, and bytes 3/4 supply coordinates.",
            "held_pose": "F7 stores its operand as the held descriptor. Motion $A38A applies one zero-delta step before the $A390 hold command.",
            "palette": "The bank-$14 palette resolver returns the ordinary player ID unchanged; the normal-player table uses five-byte stride. Player ID $08 selects $B80C + 5*$08 = $B834.",
            "route_animation_streams": "Raw bank-$14 spans are preserved from the route animation pointer table, using the current pointer to the following pointer as the exclusive boundary; the pointer boundary is authoritative, and streams must not be truncated by scanning for $F0. Ordinary entries in this set end with $F0; $79 contains an earlier $F0 inside an $F1 packet operand. ID $E6 is a five-byte F5/F8 dispatch prefix ending at the $E7 pointer, with its $F8 target at CPU $961A inside the ID $78 span; it does not have a local $F0 terminator. IDs $8F/$4E/$66/$4C/$E6 come from byte-checked scenario records; $78/$79/$90 are selectors observed in the same-input actor writer trace, but their upstream selection conditions remain unresolved.",
        },
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(entries)} ROM source spans under {OUTPUT_DIR.relative_to(ROOT)}")
    for entry in entries:
        print(f"{entry['path'].rsplit('/', 1)[-1]}: {entry['length_bytes']} bytes sha256 {entry['sha256']}")


if __name__ == "__main__":
    main()
