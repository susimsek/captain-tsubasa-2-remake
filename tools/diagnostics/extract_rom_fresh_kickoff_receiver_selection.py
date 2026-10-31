#!/usr/bin/env python3
"""Extract the fixed-bank fresh-kickoff receiver-selection caller segment."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT = pathlib.Path("reference/rom_extract/gameplay/fresh_daf5_receiver_setup")
FILE_NAME = "fixed_receiver_selection_DAF5_DB0E.bin"
CPU_START = 0xDAF5
CPU_END_EXCLUSIVE = 0xDB0E
PRG_BANK = 0x1E
FILE_OFFSET = 0x03DB05
EXPECTED_BYTES = bytes.fromhex(
    "AD E2 00 29 07 C9 05 90 02 E9 05 AA BD 82 DC "
    "18 6D FB 05 8D FC 05 20 EC E6"
)


def main() -> int:
    if len(sys.argv) != 2:
        print(
            "usage: extract_rom_fresh_kickoff_receiver_selection.py <supplied-rom.nes>",
            file=sys.stderr,
        )
        return 2

    rom_path = pathlib.Path(sys.argv[1])
    rom = rom_path.read_bytes()
    rom_hash = hashlib.sha256(rom).hexdigest()
    if rom_hash != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_hash}")

    length = CPU_END_EXCLUSIVE - CPU_START
    if length != len(EXPECTED_BYTES):
        raise SystemExit("internal span length does not match the expected ROM bytes")
    data = rom[FILE_OFFSET : FILE_OFFSET + length]
    if data != EXPECTED_BYTES:
        raise SystemExit(
            "fixed-bank $DAF5-$DB0E bytes do not match the verified receiver-selection span"
        )

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / FILE_NAME).write_bytes(data)
    entry = {
        "file": FILE_NAME,
        "bank": f"0x{PRG_BANK:02X}",
        "window": "fixed",
        "cpu_start": f"0x{CPU_START:04X}",
        "cpu_end_exclusive": f"0x{CPU_END_EXCLUSIVE:04X}",
        "file_offset": f"0x{FILE_OFFSET:06X}",
        "length": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "source_role": (
            "After the fresh-match $DC07 position initializer returns, derive a "
            "receiver index from $00E2 & $07, fold indices 5..7 by subtracting "
            "5, read its offset from $DC82, add $05FB, store the selected slot "
            "at $05FC, and call $E6EC."
        ),
        "bytes": data.hex(" "),
    }
    manifest = {
        "schema": "ct2-fresh-daf5-receiver-setup-v1",
        "rom_sha256": ROM_SHA256,
        "mapping": (
            "iNES PRG starts at file offset 0x0010; fixed CPU window $C000-$DFFF "
            "maps bank $1E. $DAF5 maps to file offset 0x03DB05."
        ),
        "scope": "One ROM-derived caller span, fixed-bank $DAF5-$DB0E, ending after the JSR $E6EC call transfers control and before the callee executes.",
        "spans": [entry],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(
        f"Extracted {FILE_NAME}: bank ${PRG_BANK:02X}, "
        f"${CPU_START:04X}-${CPU_END_EXCLUSIVE:04X}, file 0x{FILE_OFFSET:06X}, "
        f"{len(data)} bytes, sha256={entry['sha256']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
