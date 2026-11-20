#!/usr/bin/env python3
"""Preserve supplied-ROM callback control, map lookup, and CHR source spans."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT = ROOT / "reference/rom_extract/gameplay/first_command_field/callback_f2_control"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK_FILE_BASE = 0x016010

SPANS = [
    ("bank_0b_control_dispatch_81bc_81cc.bin", 0x81BC, 0x81CC,
     "F2 control subdispatch and its inline handler vector."),
    ("bank_0b_control_map_entry_81cc_81d5.bin", 0x81CC, 0x81D5,
     "Control-vector row zero; derives a field-position index and selects a map from the ROM table at $81D5."),
    ("bank_0b_control_map_lookup_81d5_824d.bin", 0x81D5, 0x824D,
     "120-byte ROM map lookup table used by control callback `$01` vector row zero."),
    ("bank_0b_position_map_entry_82f7_82fe.bin", 0x82F7, 0x82FE,
     "ROM wrapper that loads `$05FB`, calls the shared coordinate-index helper, and returns to `$81CC`."),
    ("bank_0b_position_map_handler_824d_827f.bin", 0x824D, 0x827F,
     "Position-relative map selector through the jump to $832B."),
    ("bank_0b_position_map_lookup_827f_82f7.bin", 0x827F, 0x82F7,
     "ROM map-ID lookup table indexed by the holder-relative field position."),
    ("bank_0b_position_map_index_helper_82fe_8327.bin", 0x82FE, 0x8327,
     "ROM field-coordinate to map-table-index helper."),
    ("bank_0b_event_72_control_f2.bin", 0x8B3E, 0x8B3F,
     "Callback-$72's source control byte."),
    ("bank_0b_map_00_chr_pair_86ee_86f0.bin", 0x86EE, 0x86F0,
     "Map-$00 CHR selector pair read by the shared $8525 worker."),
    ("bank_0b_map_0e_chr_pair_870a_870c.bin", 0x870A, 0x870C,
     "Map-$0E CHR selector pair read by the shared $8525 worker."),
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    actual = sha256(rom)
    if actual != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {actual}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    entries = []
    for name, start, end, source in SPANS:
        bank_base = BANK_FILE_BASE if start < 0xA000 else 0x016010
        file_offset = bank_base + start - 0x8000
        data = rom[file_offset:file_offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"Short ROM span: {name}")
        (OUTPUT / name).write_bytes(data)
        entries.append({
            "path": name,
            "cpu_start": f"0x{start:04X}",
            "cpu_end_exclusive": f"0x{end:04X}",
            "file_offset": f"0x{file_offset:06X}",
            "prg_bank": "0x0B",
            "size_bytes": len(data),
            "sha256": sha256(data),
            "raw_hex": data.hex(" ").upper(),
            "source": source,
        })
    manifest = {
        "schema": "slot15-callback-f2-position-map-v1",
        "rom_filename": ROM_PATH.name,
        "rom_sha256": ROM_SHA256,
        "source_mapping": {
            "bank_0b_file_base": "0x016010",
            "bank_0b_cpu_base": "0x8000",
            "route": "callback $72 F2 remains mapped through $824D; callback $01 F0 selects vector row zero at $81CC, then `$82F7` and `$81D5-$824C` choose a map before `$832B->$8525`",
            "runtime_rom_dependency": False,
            "emulator_captures_used_as_runtime_inputs": False,
        },
        "entries": entries,
    }
    (OUTPUT / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(entries)} verified ROM spans to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
