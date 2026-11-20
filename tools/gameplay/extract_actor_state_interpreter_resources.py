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
        "name": "fresh_actor_appearance_sequence_B30E_B315.bin",
        "file_offset": 0x02B31E,
        "length_bytes": 0x0008,
        "cpu_start": "$B30E",
        "cpu_end_exclusive": "$B316",
        "prg_bank": "$14",
        "purpose": "Animation-$8F appearance roots `$B30E/$B310/$B312`: source `$F7` shared-selector writes followed by `$F6 $04` descriptor hold.",
    },
    {
        "name": "slot11_actor_appearance_sequence_B2E0_B30D.bin",
        "file_offset": 0x02B2F0,
        "length_bytes": 0x002E,
        "cpu_start": "$B2E0",
        "cpu_end_exclusive": "$B30E",
        "prg_bank": "$14",
        "purpose": "Slot-$11 actor appearance stream from `$B2E0` through `$B30D`, including timed descriptor pairs and source `$F4/$F5/$F7` commands.",
    },
    {
        "name": "appearance_pair_B537_B538.bin",
        "file_offset": 0x02B547,
        "length_bytes": 0x0002,
        "cpu_start": "$B537",
        "cpu_end_exclusive": "$B539",
        "prg_bank": "$14",
        "purpose": "Frame-8663 route actor appearance pair: wait 4 actor updates, set descriptor $7D, then advance to $B539.",
    },
    {
        "name": "appearance_sequence_B539_B5AB.bin",
        "file_offset": 0x02B549,
        "length_bytes": 0x0073,
        "cpu_start": "$B539",
        "cpu_end_exclusive": "$B5AC",
        "prg_bank": "$14",
        "purpose": "Continuation of the frame-8663 route actor stream, including its timed descriptor pairs and local F6/F3/F8 commands through the next source span at $B5AC.",
    },
    {
        "name": "scenario_36_animation_4E_appearance_AF5F_AF60.bin",
        "file_offset": 0x02AF6F,
        "length_bytes": 0x0002,
        "cpu_start": "$AF5F",
        "cpu_end_exclusive": "$AF61",
        "prg_bank": "$14",
        "purpose": "Initial animation-$4E actor appearance command: $F7 holds descriptor $B7; the script pointer is not advanced on this command.",
    },
    {
        "name": "animation_66_appearance_AF81_AF94.bin",
        "file_offset": 0x02AF91,
        "length_bytes": 0x0013,
        "cpu_start": "$AF81",
        "cpu_end_exclusive": "$AF94",
        "prg_bank": "$14",
        "purpose": "Animation-$66 appearance script: set horizontal flip, emit the timed descriptor pair at $AF82, then source F1/F7 and F3 commands.",
    },
    {
        "name": "scenario_1C_animation_7A_appearance_AF11_AF12.bin",
        "file_offset": 0x02AF21,
        "length_bytes": 0x0002,
        "cpu_start": "$AF11",
        "cpu_end_exclusive": "$AF13",
        "prg_bank": "$14",
        "purpose": "Scenario-$1C animation-$7A F1 appearance index $1D: ROM `$AC47` resolves to `$AF11`, where `$F7 $14` holds descriptor `$14`.",
    },
    {
        "name": "scenario_1C_animation_7A_appearance_AF13_AF1A.bin",
        "file_offset": 0x02AF23,
        "length_bytes": 0x0008,
        "cpu_start": "$AF13",
        "cpu_end_exclusive": "$AF1B",
        "prg_bank": "$14",
        "purpose": "Scenario-$1C animation-$7A F1 appearance index $1E: ROM `$AC47` resolves to `$AF13`, whose timed pair, `$F2`, and `$F3 $AF13` form a self-loop.",
    },
    {
        "name": "scenario_1C_animation_7A_appearance_AFDB_AFE2.bin",
        "file_offset": 0x02AFEB,
        "length_bytes": 0x0008,
        "cpu_start": "$AFDB",
        "cpu_end_exclusive": "$AFE3",
        "prg_bank": "$14",
        "purpose": "Scenario-$1C live animation-$7A appearance path: three timed descriptors `$15/$16/$17`, followed by ROM `$F7 $15` hold.",
    },
    {
        "name": "scenario_1C_animation_7A_appearance_AF23_AF25.bin",
        "file_offset": 0x02AF33,
        "length_bytes": 0x0003,
        "cpu_start": "$AF23",
        "cpu_end_exclusive": "$AF26",
        "prg_bank": "$14",
        "purpose": "Scenario-$1C live animation-$7A appearance index `$22` resolved by ROM `$AC47`: timed descriptor `$1D`, then ROM `$F0` hold.",
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
        "name": "animation_66_motion_A692_A699.bin",
        "file_offset": 0x02A6A2,
        "length_bytes": 0x0007,
        "cpu_start": "$A692",
        "cpu_end_exclusive": "$A699",
        "prg_bank": "$14",
        "purpose": "Animation-$66 actor motion: its first ROM $01 fixed-point step and following $00 hold command.",
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
    {
        "name": "slot11_actor_motion_sequence_A865_A86B.bin",
        "file_offset": 0x02A875,
        "length_bytes": 0x0007,
        "cpu_start": "$A865",
        "cpu_end_exclusive": "$A86C",
        "prg_bank": "$14",
        "purpose": "Slot-$11 route motion root: source $01 duration/velocity packet at $A865 followed by the $00 hold at $A86B.",
    },
    {
        "name": "motion_command_03_A96E_A973.bin",
        "file_offset": 0x02A97E,
        "length_bytes": 0x0006,
        "cpu_start": "$A96E",
        "cpu_end_exclusive": "$A974",
        "prg_bank": "$14",
        "purpose": "Frame-8663 route motion command $03: load a 60-update fixed-point velocity packet and set actor motion flag $10.",
    },
    {
        "name": "scenario_36_animation_4C_appearance_B43E_B43F.bin",
        "file_offset": 0x02B44E,
        "length_bytes": 0x0002,
        "cpu_start": "$B43E",
        "cpu_end_exclusive": "$B440",
        "prg_bank": "$14",
        "purpose": "Scenario-$36 animation-$4C actor appearance pair: set descriptor $7D with a three-update timer.",
    },
    {
        "name": "scenario_36_animation_4C_appearance_B440_B470.bin",
        "file_offset": 0x02B450,
        "length_bytes": 0x0031,
        "cpu_start": "$B440",
        "cpu_end_exclusive": "$B471",
        "prg_bank": "$14",
        "purpose": "Scenario-$36 animation-$4C continuation: timed descriptor pairs, local offsets, flips, and the source $F3 loop at $B46E->$B462.",
    },
    {
        "name": "scenario_36_animation_4C_motion_A79B_A7A0.bin",
        "file_offset": 0x02A7AB,
        "length_bytes": 0x0006,
        "cpu_start": "$A79B",
        "cpu_end_exclusive": "$A7A1",
        "prg_bank": "$14",
        "purpose": "Scenario-$36 animation-$4C motion command $03: load a 50-update fixed-point velocity packet.",
    },
    {
        "name": "scenario_36_animation_E6_appearance_B01E_B0BA.bin",
        "file_offset": 0x02B02E,
        "length_bytes": 0x009C,
        "cpu_start": "$B01E",
        "cpu_end_exclusive": "$B0BA",
        "prg_bank": "$14",
        "purpose": "Scenario-$36 animation-$E6 appearance script roots and shared command loops.",
    },
    {
        "name": "scenario_36_animation_E6_motion_A6C7_A6D5.bin",
        "file_offset": 0x02A6D7,
        "length_bytes": 0x000E,
        "cpu_start": "$A6C7",
        "cpu_end_exclusive": "$A6D5",
        "prg_bank": "$14",
        "purpose": "Scenario-$36 animation-$E6 motion roots $A6C7/$A6CE and their zero-hold operands.",
    },
    {
        "name": "scenario_1C_animation_7A_motion_A6D5_A6DB.bin",
        "file_offset": 0x02A6E5,
        "length_bytes": 0x0007,
        "cpu_start": "$A6D5",
        "cpu_end_exclusive": "$A6DC",
        "prg_bank": "$14",
        "purpose": "Scenario-$1C animation-$7A F1 motion index $64: ROM `$A1B4` resolves to `$A6D5`, a timed `$01` step followed by `$00` hold.",
    },
    {
        "name": "scenario_1C_animation_7A_motion_A6DC_A6E2.bin",
        "file_offset": 0x02A6EC,
        "length_bytes": 0x0007,
        "cpu_start": "$A6DC",
        "cpu_end_exclusive": "$A6E3",
        "prg_bank": "$14",
        "purpose": "Scenario-$1C animation-$7A F1 motion index $65: ROM `$A1B4` resolves to `$A6DC`, a timed `$01` step followed by `$00` hold.",
    },
    {
        "name": "scenario_1C_animation_7A_motion_A6E3_A6E9.bin",
        "file_offset": 0x02A6F3,
        "length_bytes": 0x0007,
        "cpu_start": "$A6E3",
        "cpu_end_exclusive": "$A6EA",
        "prg_bank": "$14",
        "purpose": "Live scenario-$1C animation-$7A F1 motion index `$66` from ROM `$A1B4`: timed `$01` step at `$A6E3` followed by `$00` hold.",
    },
    {
        "name": "scenario_1C_pass_motion_A95C_A966.bin",
        "file_offset": 0x02A96C,
        "length_bytes": 0x000B,
        "cpu_start": "$A95C",
        "cpu_end_exclusive": "$A967",
        "prg_bank": "$14",
        "purpose": "Live PASS actor motion index `$A7` resolved by ROM `$A1B4`: `$03` packet, `$00` hold, and the full pointer-bounded entry bytes.",
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
