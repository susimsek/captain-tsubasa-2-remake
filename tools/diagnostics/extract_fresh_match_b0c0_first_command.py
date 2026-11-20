#!/usr/bin/env python3
"""Extract the ROM-owned B0C0 dispatcher, handlers, and first PPU packets."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUTPUT = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_a006"
PRG_BANK_SIZE = 0x2000
PRG_FILE_START = 0x10

SPANS = [
    {
        "file": "bank01_match_b0c0_dispatch_B0C0_B1C9.bin",
        "bank": 0x01,
        "slot_start": 0xA000,
        "cpu_start": 0xB0C0,
        "cpu_end_exclusive": 0xB1C9,
    },
    {
        "file": "bank01_match_b0c0_stream_B305_B328.bin",
        "bank": 0x01,
        "slot_start": 0xA000,
        "cpu_start": 0xB305,
        "cpu_end_exclusive": 0xB328,
    },
    {
        "file": "bank01_match_b0c0_data_B328_B33D.bin",
        "bank": 0x01,
        "slot_start": 0xA000,
        "cpu_start": 0xB328,
        "cpu_end_exclusive": 0xB33D,
    },
    {
        "file": "bank01_match_b0c0_pointer_helper_B1C9_B1D3.bin",
        "bank": 0x01,
        "slot_start": 0xA000,
        "cpu_start": 0xB1C9,
        "cpu_end_exclusive": 0xB1D3,
    },
    {
        "file": "bank01_match_b0c0_argument_helpers_B1D3_B1E8.bin",
        "bank": 0x01,
        "slot_start": 0xA000,
        "cpu_start": 0xB1D3,
        "cpu_end_exclusive": 0xB1E8,
    },
    {
        "file": "bank00_ppu_clear_rts_98DC_98DD.bin",
        "bank": 0x00,
        "slot_start": 0x8000,
        "cpu_start": 0x98DC,
        "cpu_end_exclusive": 0x98DD,
    },
    {
        "file": "bank00_ppu_fill_98EA_997A.bin",
        "bank": 0x00,
        "slot_start": 0x8000,
        "cpu_start": 0x98EA,
        "cpu_end_exclusive": 0x997A,
    },
    {
        "file": "bank00_ppu_packet_reader_97B6_988A.bin",
        "bank": 0x00,
        "slot_start": 0x8000,
        "cpu_start": 0x97B6,
        "cpu_end_exclusive": 0x988A,
    },
]


def main() -> None:
    rom = ROM_PATH.read_bytes()
    digest = hashlib.sha256(rom).hexdigest()
    if digest != ROM_SHA256:
        raise SystemExit(f"ROM SHA-256 mismatch: {digest}")
    if len(rom) < PRG_FILE_START + 2 * PRG_BANK_SIZE:
        raise SystemExit("ROM does not contain the required mapped PRG bank.")

    OUTPUT.mkdir(parents=True, exist_ok=True)
    entries = []
    for span in SPANS:
        start = int(span["cpu_start"])
        end = int(span["cpu_end_exclusive"])
        bank = int(span["bank"])
        slot_start = int(span["slot_start"])
        if not slot_start <= start < end <= slot_start + PRG_BANK_SIZE:
            raise SystemExit(f"Unexpected CPU span: {start:04X}-{end:04X}")
        offset = PRG_FILE_START + bank * PRG_BANK_SIZE + start - slot_start
        payload = rom[offset : offset + end - start]
        if len(payload) != end - start:
            raise SystemExit(f"Truncated ROM span: {start:04X}-{end:04X}")
        (OUTPUT / str(span["file"])).write_bytes(payload)
        entries.append(
            {
                "file": span["file"],
                "bank": bank,
                "cpu_slot_start": f"${slot_start:04X}",
                "cpu_start": f"${start:04X}",
                "cpu_end_exclusive": f"${end:04X}",
                "file_offset": f"0x{offset:06X}",
                "length": len(payload),
                "sha256": hashlib.sha256(payload).hexdigest(),
                "bytes": payload.hex(),
            }
        )

    manifest = {
        "schema": "ct2-fresh-match-b0c0-stream-v2",
        "rom": {
            "file": ROM_PATH.name,
            "sha256": digest,
        },
        "mapping": "MMC3 PRG 8 KiB bank $01 at $A000 and bank $00 at $8000; source spans cover B0C0 dispatch, PPU fill/packet handlers, and the first B305 stream data",
        "spans": entries,
    }
    manifest_path = OUTPUT / "b0c0_first_command_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for entry in entries:
        print(f"{entry['file']}: {entry['length']} bytes sha256={entry['sha256']}")
    print(f"manifest: {manifest_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
