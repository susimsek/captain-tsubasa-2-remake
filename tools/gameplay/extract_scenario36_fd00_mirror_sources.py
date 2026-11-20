#!/usr/bin/env python3
"""Extract the target-ROM bytes needed to execute scenario $36's FD $00 mirror handler."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_NAME = "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT = ROOT / "reference/rom_extract/gameplay/scenario36_fd00_mirror"
SPECS = [
    {"file": "bank10_fd00_handler_8877_88AA.bin", "bank": "$10", "cpu_start": 0x8877,
     "cpu_end_exclusive": 0x88AA, "file_offset": 0x020887},
    {"file": "fixed_record_pointer_helper_CD7C_CD89.bin", "bank": "fixed", "cpu_start": 0xCD7C,
     "cpu_end_exclusive": 0xCD89, "file_offset": 0x03CD8C},
    {"file": "fixed_player_record_pointer_table_CD89_CDC9.bin", "bank": "fixed-data", "cpu_start": 0xCD89,
     "cpu_end_exclusive": 0xCDC9, "file_offset": 0x03CD99},
    {"file": "fixed_value_div12_helper_CDC9_CDE2.bin", "bank": "fixed", "cpu_start": 0xCDC9,
     "cpu_end_exclusive": 0xCDE2, "file_offset": 0x03CDD9},
    {"file": "fixed_record_pointer_vector_C50C_C50F.bin", "bank": "fixed", "cpu_start": 0xC50C,
     "cpu_end_exclusive": 0xC50F, "file_offset": 0x03C51C},
    {"file": "fixed_value_div12_vector_C536_C539.bin", "bank": "fixed", "cpu_start": 0xC536,
     "cpu_end_exclusive": 0xC539, "file_offset": 0x03C546},
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rom", type=Path, default=ROOT / ROM_NAME)
    args = parser.parse_args()
    rom = args.rom.read_bytes()
    digest = sha256(rom)
    if digest != ROM_SHA256:
        raise SystemExit(f"Unsupported ROM SHA-256: {digest}")
    if len(rom) != 393232 or rom[:4] != b"NES\x1a":
        raise SystemExit("Unexpected iNES layout; expected the verified 393,232-byte mapper-4 ROM.")

    OUTPUT.mkdir(parents=True, exist_ok=True)
    spans = []
    for spec in SPECS:
        start = int(spec["file_offset"])
        length = int(spec["cpu_end_exclusive"]) - int(spec["cpu_start"])
        data = rom[start:start + length]
        if len(data) != length:
            raise SystemExit(f"Truncated ROM span: {spec['file']}")
        (OUTPUT / str(spec["file"])).write_bytes(data)
        spans.append({
            "file": spec["file"], "bank": spec["bank"],
            "cpu_start": f"0x{int(spec['cpu_start']):04X}",
            "cpu_end_exclusive": f"0x{int(spec['cpu_end_exclusive']):04X}",
            "file_offset": f"0x{start:06X}", "length": length,
            "sha256": sha256(data), "bytes": data.hex(" "),
        })
    manifest = {
        "schema": "ct2-scenario36-fd00-mirror-source-v1",
        "rom": {"file": ROM_NAME, "sha256": ROM_SHA256,
                "header": "iNES 1.0; 16-byte header; no trainer", "mapper": 4, "submapper": 0},
        "runtime_rom_dependency": False, "trace_state_included": False,
        "spans": spans,
    }
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Wrote {len(spans)} hash-checked spans to {OUTPUT}")
    for span in spans:
        print(f"{span['file']}: {span['length']} bytes sha256={span['sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
