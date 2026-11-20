#!/usr/bin/env python3
"""Extract the live parameter-$47 packet resume's selected ROM lookup row."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# `$8675` indexes four bytes through `$8686,X`; the live parameter-$47
# index-$01 packet route supplies X=`$D4`, selecting `$875A-$875D`.
CPU_ADDRESS = 0x875A
FILE_OFFSET = 0x03076A
LENGTH = 4
EXPECTED_SHA256 = "456db556cef5802457e8666bf34d2d83fc8d713565f385eadeec8e7fe8d9e3fd"
FILENAME = "bank18_actor_packet_parameter47_index01_lookup_875a_875e.bin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Target ROM SHA-256 mismatch.")
    data = rom[FILE_OFFSET : FILE_OFFSET + LENGTH]
    if len(data) != LENGTH or sha256(data) != EXPECTED_SHA256:
        raise SystemExit(f"Unexpected ROM bytes at ${CPU_ADDRESS:04X}: {sha256(data)}")

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("rom_sha256") != ROM_SHA256:
        raise SystemExit("Slot-$11 source manifest targets another ROM revision.")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / FILENAME).write_bytes(data)
    entry = {
        "file": FILENAME,
        "cpu_address": f"0x{CPU_ADDRESS:04X}",
        "file_offset": f"0x{FILE_OFFSET:06X}",
        "length": LENGTH,
        "sha256": sha256(data),
        "description": (
            "The four-byte `$8675` indexed lookup row selected by the live "
            "parameter-$47 index-$01 route: X=`$D4` addresses `$875A-$875D`."
        ),
        "bytes": data.hex(" "),
    }
    spans = [item for item in manifest.get("spans", []) if item.get("file") != FILENAME]
    spans.append(entry)
    manifest["spans"] = spans
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Extracted {FILENAME} from ROM bank $18 at ${FILE_OFFSET:06X}.")


if __name__ == "__main__":
    main()
