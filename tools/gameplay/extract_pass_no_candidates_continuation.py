#!/usr/bin/env python3
"""Extract the ROM spans used by the bounded first PASS no-candidates path."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference/rom_extract/gameplay/pass_no_candidates_continuation"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_SIZE = 0x60010

# (name, bank, CPU start, CPU end-exclusive, mapped window start)
SPANS = [
    ("fixed_pass_caller_D68A_D6C7", 0x1E, 0xD68A, 0xD6C7, 0xC000),
    ("fixed_action_parameter_caller_D717_D746", 0x1E, 0xD717, 0xD746, 0xC000),
    ("fixed_holder_delta_D76B_D77A", 0x1E, 0xD76B, 0xD77B, 0xC000),
    ("fixed_mapper_helper_CE2D_CE4A", 0x1E, 0xCE2D, 0xCE4B, 0xC000),
    ("fixed_player_record_pointer_CD7C_CD9F", 0x1E, 0xCD7C, 0xCDA0, 0xC000),
    ("fixed_player_record_vector_C50C_C50F", 0x1E, 0xC50C, 0xC510, 0xC000),
    ("bank1c_vectors_8000_803A", 0x1C, 0x8000, 0x803A, 0x8000),
    ("bank1c_player_attribute_helper_803A_818E", 0x1C, 0x803A, 0x818E, 0x8000),
    ("bank1c_player_attribute_lookup_818E_819D", 0x1C, 0x818E, 0x819D, 0x8000),
    ("bank1d_player_effect_data_A060_A080", 0x1D, 0xA060, 0xA080, 0xA000),
    ("bank1c_action_parameters_819D_8298", 0x1C, 0x819D, 0x8298, 0x8000),
    ("bank1c_candidate_scan_8C06_8C3B", 0x1C, 0x8C06, 0x8C3B, 0x8000),
    ("bank1c_holder_candidate_pointer_8DC9_8DE2", 0x1C, 0x8DC9, 0x8DE2, 0x8000),
    ("bank1c_candidate_pointer_table_8E1B_8E3B", 0x1C, 0x8E1B, 0x8E3B, 0x8000),
    ("bank1c_holder6_empty_candidates_8F07_8F17", 0x1C, 0x8F07, 0x8F17, 0x8000),
    ("bank1c_player1_candidate_pointers_8F17_8F1F", 0x1C, 0x8F17, 0x8F1F, 0x8000),
    ("bank1c_action_parameter_pointer_table_9460_9468", 0x1C, 0x9460, 0x9468, 0x8000),
    ("bank1c_player_action_support_tables_9500_9600", 0x1C, 0x9500, 0x9600, 0x8000),
    ("bank1c_pass_action_parameters_9510_9530", 0x1C, 0x9510, 0x9530, 0x8000),
    ("bank1c_effect_conversion_table_9E4E_9F10", 0x1C, 0x9E4E, 0x9F10, 0x8000),
]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    if not ROM.is_file():
        raise SystemExit(f"Missing supplied ROM: {ROM}")
    rom = ROM.read_bytes()
    if len(rom) != ROM_SIZE or sha(rom) != ROM_SHA256 or rom[:4] != b"NES\x1a":
        raise SystemExit("The supplied ROM identity/header differs from the pinned revision.")
    OUT.mkdir(parents=True, exist_ok=True)
    resources = []
    for name, bank, start, end, window_start in SPANS:
        offset = 0x10 + bank * 0x2000 + (start - window_start)
        data = rom[offset : offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"Truncated ROM span {name}")
        filename = f"{name}.bin"
        (OUT / filename).write_bytes(data)
        resources.append({
            "name": name,
            "prg_bank": f"0x{bank:02X}",
            "cpu_start": f"0x{start:04X}",
            "cpu_end_exclusive": f"0x{end:04X}",
            "mapped_window_start": f"0x{window_start:04X}",
            "file_offset": f"0x{offset:06X}",
            "length_bytes": len(data),
            "resource": filename,
            "sha256": sha(data),
        })
    manifest = {
        "schema": "ct2-pass-no-candidates-continuation-v1",
        "source_rom": ROM.name,
        "rom_sha256": ROM_SHA256,
        "rom_size_bytes": ROM_SIZE,
        "runtime_source_kind": "ROM-derived code and lookup bytes; no emulator state/capture",
        "scope": "PASS action 1, holder slot 6, ROM no-candidates branch only; stops at caller PC $D6C7",
        "resources": resources,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(resources)} ROM spans ({sum(x['length_bytes'] for x in resources)} bytes).")


if __name__ == "__main__":
    main()
