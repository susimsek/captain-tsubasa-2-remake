#!/usr/bin/env python3
"""Extract the bounded bank-$14 actor interpreter source spans for Godot."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/actor_state_interpreter"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

SPECS = [
    {
        "name": "appearance_interpreter_83D9_84DB.bin",
        "file_offset": 0x0283E9,
        "length_bytes": 0x0103,
        "cpu_start": "$83D9",
        "cpu_end_exclusive": "$84DC",
        "prg_bank": "$14",
        "purpose": "Bank-$14 actor appearance interpreter and its local $F0-$F8 handlers.",
    },
    {
        "name": "motion_interpreter_84DC_8623.bin",
        "file_offset": 0x0284EC,
        "length_bytes": 0x0148,
        "cpu_start": "$84DC",
        "cpu_end_exclusive": "$8624",
        "prg_bank": "$14",
        "purpose": "Bank-$14 actor motion interpreter and local command/integration helpers through $8623.",
    },
    {
        "name": "appearance_loop_B026_B030.bin",
        "file_offset": 0x02B036,
        "length_bytes": 0x000B,
        "cpu_start": "$B026",
        "cpu_end_exclusive": "$B031",
        "prg_bank": "$14",
        "purpose": "Four timed descriptor pairs followed by source $F3 jump back to $B026.",
    },
    {
        "name": "appearance_hold_B5AC_B5B3.bin",
        "file_offset": 0x02B5BC,
        "length_bytes": 0x0008,
        "cpu_start": "$B5AC",
        "cpu_end_exclusive": "$B5B4",
        "prg_bank": "$14",
        "purpose": "Source $F7 descriptor-hold sequence used by the first-command actors.",
    },
    {
        "name": "fresh_actor_appearance_roots_B30E_B313.bin",
        "file_offset": 0x02B31E,
        "length_bytes": 0x0006,
        "cpu_start": "$B30E",
        "cpu_end_exclusive": "$B314",
        "prg_bank": "$14",
        "purpose": "First source $F7 descriptor-hold command at each of animation-$8F appearance roots $B30E/$B310/$B312.",
    },
    {
        "name": "motion_step_A38A_A390.bin",
        "file_offset": 0x02A39A,
        "length_bytes": 0x0007,
        "cpu_start": "$A38A",
        "cpu_end_exclusive": "$A391",
        "prg_bank": "$14",
        "purpose": "Source motion $01 one-step packet followed by $00 hold.",
    },
    {
        "name": "fresh_actor_motion_roots_A723_A734.bin",
        "file_offset": 0x02A733,
        "length_bytes": 0x0012,
        "cpu_start": "$A723",
        "cpu_end_exclusive": "$A735",
        "prg_bank": "$14",
        "purpose": "Fresh animation-$8F motion roots: timed fixed-point $01 commands and self-targeting $04 loop jumps at $A723/$A72C.",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    if not ROM_PATH.is_file():
        raise SystemExit(f"Source ROM is missing: {ROM_PATH}")
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: {rom_hash}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    resources = []
    for spec in SPECS:
        start = int(spec["file_offset"])
        end = start + int(spec["length_bytes"])
        data = rom[start:end]
        if len(data) != int(spec["length_bytes"]):
            raise SystemExit(f"ROM span truncated: {spec['name']}")
        path = OUTPUT_DIR / spec["name"]
        path.write_bytes(data)
        resources.append({**spec, "sha256": sha256(data), "runtime_rom_dependency": False})

    manifest = {
        "schema": "ct2-bank14-actor-interpreter-source-v1",
        "source_rom_filename": ROM_PATH.name,
        "source_rom_sha256": rom_hash,
        "prg_bank": "$14",
        "bank_window": {"cpu_start": "$8000", "file_start": "0x028010"},
        "runtime_rom_dependency": False,
        "capture_or_screenshot_bytes_included": False,
        "resources": resources,
    }
    manifest_path = OUTPUT_DIR / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Extracted {len(resources)} byte-verified actor interpreter resources to {OUTPUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
