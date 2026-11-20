#!/usr/bin/env python3
"""Preserve the ROM's first-match field player-marker renderer spans."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
PACKAGE = ROOT / "reference/rom_extract/gameplay/ee9f_actor_init_80"
MANIFEST_PATH = PACKAGE / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SPANS = [
    ("bank14_field_marker_renderer_8624_86DB.bin", 0x14, 0x8624, 0x86DB,
     "Source loop that writes route-time field-player marker sprites."),
    ("bank14_field_marker_filters_86DB_871F.bin", 0x14, 0x86DB, 0x871F,
     "Player-record and mode-zero visibility dispatch used by the marker loop."),
    ("bank14_field_marker_mode_table_8753_8768.bin", 0x14, 0x8753, 0x8768,
     "Inline mode dispatch and its source return target."),
    ("bank14_field_marker_mode1_8768_8771.bin", 0x14, 0x8768, 0x8771,
     "Mode-1 marker dispatch from `$0624` through `$C536` to the ROM OAM writer."),
    ("bank14_field_marker_oam_writer_87E7_881D.bin", 0x14, 0x87E7, 0x881D,
     "ROM OAM position, tile, and attribute writer for a field marker."),
    ("bank14_field_marker_holder_blink_881D_8861.bin", 0x14, 0x881D, 0x8861,
     "Source-selected holder-marker blink and tile table."),
    ("bank14_field_marker_position_offsets_88DA_88E4.bin", 0x14, 0x88DA, 0x88E4,
     "ROM mode-indexed marker position offsets."),
    ("fixed_record_pointer_vector_C50C_C50F.bin", 0x1E, 0xC50C, 0xC50F,
     "ROM fixed-bank vector from `$C50C` to the player-record resolver."),
    ("fixed_record_pointer_resolver_CD7C_CD89.bin", 0x1E, 0xCD7C, 0xCD89,
     "ROM fixed-bank resolver for the 22 match player-record pointers."),
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if len(rom) != 393232 or sha256(rom) != ROM_SHA256:
        raise SystemExit("The supplied target ROM identity does not match.")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("schema") != "ct2-ee9f-actor-init-80-source-v1" \
            or manifest.get("rom", {}).get("sha256") != ROM_SHA256:
        raise SystemExit("The owning $EE9F manifest targets another ROM or schema.")

    rows = manifest.get("spans", [])
    by_name = {row.get("file"): row for row in rows}
    bank_window_start = {0x14: 0x8000, 0x1E: 0xC000}
    for filename, bank, cpu_start, cpu_end, description in SPANS:
        file_offset = 0x10 + bank * 0x2000 + cpu_start - bank_window_start[bank]
        source = rom[file_offset:file_offset + cpu_end - cpu_start]
        if len(source) != cpu_end - cpu_start:
            raise SystemExit(f"ROM span `{filename}` is truncated.")
        (PACKAGE / filename).write_bytes(source)
        row = {
            "file": filename,
            "bank": f"${bank:02X}",
            "cpu_start": f"0x{cpu_start:04X}",
            "cpu_end_exclusive": f"0x{cpu_end:04X}",
            "file_offset": f"0x{file_offset:06X}",
            "length": len(source),
            "sha256": sha256(source),
            "bytes": source.hex(" "),
            "description": description,
        }
        by_name[filename] = row
        print(f"{filename}: {len(source)} bytes sha256={sha256(source)}")

    manifest["spans"] = list(by_name.values())
    manifest["scope"] = (
        "Live slot-$01 `$CA52->$EE9F` actor setup and first-match field actor work, "
        "including the source `$062D.7` player-marker branch for the verified "
        "fresh-start low-nibble modes 0 and 1. Other marker modes remain out of "
        "scope until their source inputs are observed and implemented."
    )
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
