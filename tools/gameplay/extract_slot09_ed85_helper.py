#!/usr/bin/env python3
"""Preserve the slot-$09 $ED85 helper path through its source RTS."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
MANIFEST_PATH = ROOT / "reference/rom_extract/gameplay/slot09_eb8b_continuation/manifest.json"
SOURCE_DIR = MANIFEST_PATH.parent
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
FIXED_BANK_FILE_BASE = 0x03C010
CPU_START = 0xED85
CPU_END_EXCLUSIVE = 0xEE9F
SOURCE_FILE = "fixed_slot09_helper_ED85_EE9E.bin"
OLD_SOURCE_FILE = "fixed_slot09_helper_ED85_ED8A.bin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if len(rom) != 393232 or sha256(rom) != ROM_SHA256:
        raise SystemExit("The supplied target ROM identity does not match.")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("schema") != "ct2-slot09-eb8b-continuation-source-v1" \
            or manifest.get("rom", {}).get("sha256") != ROM_SHA256:
        raise SystemExit("The owning slot-$09 source manifest targets another ROM/schema.")

    file_offset = FIXED_BANK_FILE_BASE + CPU_START - 0xC000
    source = rom[file_offset : file_offset + CPU_END_EXCLUSIVE - CPU_START]
    if len(source) != CPU_END_EXCLUSIVE - CPU_START:
        raise SystemExit("The target ROM source span is truncated.")
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    (SOURCE_DIR / SOURCE_FILE).write_bytes(source)

    rows = manifest.get("spans", [])
    row = next((item for item in rows if item.get("file") in [OLD_SOURCE_FILE, SOURCE_FILE]), None)
    if row is None:
        raise SystemExit("The owning manifest has no existing $ED85 source row to update.")
    row.update({
        "file": SOURCE_FILE,
        "cpu_start": f"0x{CPU_START:04X}",
        "cpu_end_exclusive": f"0x{CPU_END_EXCLUSIVE:04X}",
        "bank": "0x1F",
        "file_offset": f"0x{file_offset:06X}",
        "length": len(source),
        "sha256": sha256(source),
        "bytes": source.hex(" "),
        "description": "$ED85-$EE9E; fixed bank $1F; zero return plus the source-observed scenario-$36 $05D2=$80 normalization/coordinate path",
    })
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Preserved ${CPU_START:04X}-${CPU_END_EXCLUSIVE - 1:04X} ({len(source)} bytes) sha256 {sha256(source)}")


if __name__ == "__main__":
    main()
