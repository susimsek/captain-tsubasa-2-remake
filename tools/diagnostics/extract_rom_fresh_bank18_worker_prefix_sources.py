#!/usr/bin/env python3
"""Extract hash-pinned ROM inputs for the first bank-$18 worker prefix."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT = pathlib.Path("reference/rom_extract/gameplay/fresh_bank18_worker_prefix")
SPANS = [
    ("bank18_worker_entry_to_yield_call_800C_8889.bin", 0x18, 0x800C, 0x8889, "low"),
    ("bank19_worker_lookup_B3BD_B3D1.bin", 0x19, 0xB3BD, 0xB3D1, "high"),
    ("fixed_task_yield_trampoline_C515_C518.bin", 0x1E, 0xC515, 0xC518, "fixed"),
]


def file_offset(bank: int, start: int, window: str) -> int:
    if window == "fixed":
        return (0x3C010 + start - 0xC000) if start < 0xE000 else (0x3E010 + start - 0xE000)
    if window == "low":
        return 0x10 + bank * 0x2000 + start - 0x8000
    return 0x10 + bank * 0x2000 + start - 0xA000


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_rom_fresh_bank18_worker_prefix_sources.py <supplied-rom.nes>", file=sys.stderr)
        return 2
    rom_path = pathlib.Path(sys.argv[1])
    rom = rom_path.read_bytes()
    rom_hash = hashlib.sha256(rom).hexdigest()
    if rom_hash != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_hash}")
    OUT.mkdir(parents=True, exist_ok=True)
    spans = []
    for name, bank, start, end, window in SPANS:
        offset = file_offset(bank, start, window)
        data = rom[offset : offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"short extraction for {name}")
        (OUT / name).write_bytes(data)
        spans.append(
            {
                "file": name,
                "bank": f"0x{bank:02X}",
                "window": window,
                "cpu_start": f"0x{start:04X}",
                "cpu_end_exclusive": f"0x{end:04X}",
                "file_offset": f"0x{offset:06X}",
                "length": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
                "description": "Source bytes for the first fresh match-zero bank-$18 worker, ending at its $C515 yield trampoline.",
                "bytes": data.hex(" "),
            }
        )
    manifest = {
        "schema": "ct2-fresh-bank18-worker-prefix-source-v1",
        "rom_sha256": ROM_SHA256,
        "mapping": "iNES PRG starts at 0x0010; fixed $C000-$DFFF is bank $1E; switchable $8000 and $A000 windows use the source MMC3 low/high bank pair.",
        "scope": "ROM-byte execution from bank-$18:$800C through the JSR target $C515. Stops at $C515 before executing the $CB0F yield handler.",
        "spans": spans,
        "limitations": [
            "CPU/RAM/stack/mapper entry state must be produced by the preceding ROM-source component; this package does not consume trace snapshots.",
            "This component does not execute $C515/$CB0F, task save/resume, scheduler scans, or NMI-ready cadence.",
            "Trace artifacts are validation evidence only and are not packaged as runtime inputs.",
        ],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(spans)} hash-pinned spans into {OUT}")
    for span in spans:
        print(f"{span['cpu_start']}-{span['cpu_end_exclusive']}: {span['length']} bytes sha256={span['sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
