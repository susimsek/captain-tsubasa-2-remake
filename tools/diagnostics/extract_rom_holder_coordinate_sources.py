#!/usr/bin/env python3
"""Preserve only the supplied ROM spans used by the holder-copy executor."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[2]
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUTPUT = ROOT / "reference/rom_extract/gameplay/first_command_field/holder_coordinates"
SPANS = [
    {
        "path": "bank_1f_e0f6_coordinate_copy_call.bin",
        "prg_bank": "$1F",
        "cpu_address": "$E0F6",
        "file_offset": 0x03E106,
        "size_bytes": 3,
        "source_role": "Fixed-bank callsite: JSR $E6EC from the first-command field setup path.",
    },
    {
        "path": "bank_1f_e6ec_holder_coordinate_copy.bin",
        "prg_bank": "$1F",
        "cpu_address": "$E6EC",
        "file_offset": 0x03E6FC,
        "size_bytes": 29,
        "source_role": "Loads holder slot $0441, resolves its record through $CD7C, copies +6/+8, and calls $CDE2.",
    },
    {
        "path": "bank_1f_cde2_coordinate_index_helper.bin",
        "prg_bank": "$1F",
        "cpu_address": "$CDE2",
        "file_offset": 0x03CDF2,
        "size_bytes": 38,
        "source_role": "Validates holder X/Y and calculates the field tile index returned to $E6EC.",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_rom_holder_coordinate_sources.py <supplied-rom.nes>", file=sys.stderr)
        return 2
    rom_path = pathlib.Path(sys.argv[1])
    rom = rom_path.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"supplied ROM SHA-256 mismatch: {rom_hash}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    entries = []
    for span in SPANS:
        offset = int(span["file_offset"])
        data = rom[offset : offset + int(span["size_bytes"])]
        if len(data) != int(span["size_bytes"]):
            raise SystemExit(f"truncated ROM span at {offset:#x}")
        file_name = str(span["path"])
        (OUTPUT / file_name).write_bytes(data)
        entries.append(
            {
                "path": file_name,
                "prg_bank": span["prg_bank"],
                "cpu_address": span["cpu_address"],
                "file_offset": f"0x{offset:06X}",
                "size_bytes": len(data),
                "sha256": sha256(data),
                "raw_hex": data.hex(" ").upper(),
                "source_role": span["source_role"],
            }
        )
    manifest = {
        "schema": "ct2-first-command-holder-coordinate-copy-v1",
        "resource_kind": "preserved supplied-ROM instruction bytes; no emulator capture data",
        "rom_sha256": rom_hash,
        "bank_mapping": {"fixed_bank_1f_cpu_c000_file_base": "0x03C010"},
        "coordinate_chain": [
            "E0F6 calls E6EC during field setup; this source package validates the call and callee instruction paths.",
            "E6EC reads holder slot $0441, calls $CD7C to write its record pointer to $0034/$0035, then reads record offsets +$06 and +$08.",
            "E6EC calls $CDE2 with the copied X/Y in registers and stores the returned tile index at $05FE.",
            "Initial record coordinates derive from the match-zero ROM position tables; holder selection remains caller-owned live logic.",
        ],
        "runtime_boundary": {
            "holder_slot": "caller-owned live $0441 value produced by source logic",
            "dynamic_movement": "not modeled by this initial-coordinate copy",
            "captures_used_as_runtime_inputs": False,
        },
        "entries": entries,
    }
    manifest_bytes = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()
    (OUTPUT / "manifest.json").write_bytes(manifest_bytes)
    print(f"ROM SHA-256: {rom_hash}")
    print(f"Manifest SHA-256: {sha256(manifest_bytes)}")
    for entry in entries:
        print(f"{entry['cpu_address']}: {entry['sha256']} {entry['raw_hex']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
