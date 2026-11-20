#!/usr/bin/env python3
"""Preserve the additional ROM palette row selected by animation $4C."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
PACKAGE = ROOT / "reference/rom_extract/gameplay/ee9f_actor_init_80"
MANIFEST_PATH = PACKAGE / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
FILE_NAME = "fixed_palette_table_FC38_FC50.bin"
CPU_START = 0xFC38
CPU_END = 0xFC50
BANK = 0x1F
FILE_OFFSET = 0x03FC48
EXPECTED_BYTES = bytes.fromhex(
    "0f 10 30 0f 30 00 31 30 10 0f 30 00 "
    "0f 0f 36 0f 30 36 0f 17 36 0f 31 30"
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if len(rom) != 393232 or sha256(rom) != ROM_SHA256:
        raise SystemExit("The supplied target ROM identity does not match.")
    mapped_offset = 0x10 + BANK * 0x2000 + CPU_START - 0xE000
    if mapped_offset != FILE_OFFSET:
        raise SystemExit("The fixed-bank CPU/file mapping is inconsistent.")
    source = rom[FILE_OFFSET : FILE_OFFSET + CPU_END - CPU_START]
    if source != EXPECTED_BYTES:
        raise SystemExit("The ROM palette source bytes differ from the expected row span.")

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("schema") != "ct2-ee9f-actor-init-80-source-v1" \
            or manifest.get("rom", {}).get("sha256") != ROM_SHA256:
        raise SystemExit("The owning $EE9F manifest targets another ROM or schema.")
    (PACKAGE / FILE_NAME).write_bytes(source)
    spans = manifest.get("spans", [])
    old_name = "fixed_palette_table_FC44_FC50.bin"
    row = next((item for item in spans if item.get("file") == old_name), None)
    if row is None:
        raise SystemExit("The expected earlier palette source row is missing.")
    row.update({
        "file": FILE_NAME,
        "bank": "$1F",
        "cpu_start": f"0x{CPU_START:04X}",
        "cpu_end_exclusive": f"0x{CPU_END:04X}",
        "file_offset": f"0x{FILE_OFFSET:06X}",
        "length": len(source),
        "sha256": sha256(source),
        "bytes": source.hex(" "),
        "description": "ROM palette rows selected by live `$F5 $09` and `$F5 $0A` handlers.",
    })
    manifest["scope"] = (
        "Live slot-$01 `$CA52->$EE9F` actor initialization for route animations "
        "$8F, $4E, $66, and $4C, through their checked `$F5/$F4/$F1/$F0` "
        "prefixes and the return to `$EEB1`. The executor stops before `$EEB1` executes."
    )
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(
        f"Preserved ${CPU_START:04X}-${CPU_END - 1:04X} ({len(source)} bytes), "
        f"sha256 {sha256(source)}"
    )


if __name__ == "__main__":
    main()
