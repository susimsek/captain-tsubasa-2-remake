#!/usr/bin/env python3
"""Extract the byte-bounded synchronous prefix after the slot-$05 $DAAA handoff."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT = pathlib.Path("reference/rom_extract/gameplay/fresh_daaa_continuation")
SPANS = [
    ("fixed_reset_ram_clear_C64E_C679.bin", 0x1E, 0xC64E, 0xC67A, "fixed"),
    ("fixed_daaa_to_first_bank18_entry_DAAA_DACC.bin", 0x1E, 0xDAAA, 0xDACC, "fixed"),
    ("fixed_sound_queue_CBF1_CC01.bin", 0x1E, 0xCBF1, 0xCC02, "fixed"),
    ("fixed_branch_dispatch_DB24_DB62.bin", 0x1E, 0xDB24, 0xDB62, "fixed"),
    ("fixed_bank18_wrapper_EF7F_EF99.bin", 0x1F, 0xEF7F, 0xEF99, "fixed"),
    ("fixed_record_pointer_stub_C50C_C50F.bin", 0x1E, 0xC50C, 0xC50F, "fixed"),
    ("fixed_record_reset_CF4F_CF71.bin", 0x1E, 0xCF4F, 0xCF72, "fixed"),
    ("fixed_record_pointer_CD7C_CD88.bin", 0x1E, 0xCD7C, 0xCD89, "fixed"),
    ("fixed_record_pointer_table_CD89_CDB4.bin", 0x1E, 0xCD89, 0xCDB5, "fixed"),
    ("fixed_mapper_helper_CE2D_CE49.bin", 0x1E, 0xCE2D, 0xCE4A, "fixed"),
    ("bank1a_map_setup_8039_803B.bin", 0x1A, 0x8039, 0x803C, "low"),
    ("bank1a_fresh_gate_904E_906F.bin", 0x1A, 0x904E, 0x9070, "low"),
    ("bank1c_dispatch_trampoline_8003_8005.bin", 0x1C, 0x8003, 0x8006, "low"),
    ("bank1c_fresh_opponent_setup_8B22_8B93.bin", 0x1C, 0x8B22, 0x8B94, "low"),
    ("bank1d_opponent_pointer_entry_0_BAB2_BAB3.bin", 0x1D, 0xBAB2, 0xBAB4, "high"),
    ("bank1d_opponent_3_header_BAF6_BAFF.bin", 0x1D, 0xBAF6, 0xBB00, "high"),
    ("fixed_branch_table_dispatch_CB99_CBAF.bin", 0x1E, 0xCB99, 0xCBB0, "fixed"),
]


def file_offset(bank: int, start: int, window: str) -> int:
    if window == "fixed":
        return (0x3C010 + start - 0xC000) if start < 0xE000 else (0x3E010 + start - 0xE000)
    if start < 0xA000:
        return 0x10 + bank * 0x2000 + start - 0x8000
    return 0x10 + bank * 0x2000 + start - 0xA000


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_rom_fresh_daaa_continuation_sources.py <supplied-rom.nes>", file=sys.stderr)
        return 2
    rom_path = pathlib.Path(sys.argv[1])
    rom = rom_path.read_bytes()
    rom_hash = hashlib.sha256(rom).hexdigest()
    if rom_hash != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_hash}")
    OUT.mkdir(parents=True, exist_ok=True)
    entries = []
    for name, bank, start, end, window in SPANS:
        offset = file_offset(bank, start, window)
        data = rom[offset : offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"short extraction for {name}")
        (OUT / name).write_bytes(data)
        entries.append(
            {
                "file": name,
                "bank": f"0x{bank:02X}",
                "window": window,
                "cpu_start": f"0x{start:04X}",
                "cpu_end_exclusive": f"0x{end:04X}",
                "file_offset": f"0x{offset:06X}",
                "length": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
                "description": "Hash-checked ROM code/data for the synchronous fresh match-zero continuation to the first bank-$18 worker entry.",
                "bytes": data.hex(" "),
            }
        )
    manifest = {
        "schema": "ct2-fresh-daaa-continuation-source-v2",
        "rom_sha256": ROM_SHA256,
        "mapping": "iNES PRG starts at file offset 0x0010; fixed $C000-$DFFF maps bank $1E and $E000-$FFFF maps bank $1F; switchable 8 KiB slot-$8000/$A000 windows use the MMC3 bank pair.",
        "scope": "Synchronous source-byte execution from $DAAA through fresh selector dispatch, bank-$1C match-zero setup, and the first $EF7F wrapper into bank-$18:$800C. Stops at the asynchronous worker entry.",
        "spans": entries,
        "limitations": [
            "This package stops at bank-$18:$800C; the worker's later $8886/$C515 yield, scheduler/NMI cadence, and continuation are not executed.",
            "The packaged ROM bytes are runtime inputs; emulator traces are comparison-only validation.",
        ],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(entries)} hash-pinned spans into {OUT}")
    for entry in entries:
        print(f"{entry['cpu_start']}-{entry['cpu_end_exclusive']}: {entry['length']} bytes sha256={entry['sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
