#!/usr/bin/env python3
"""Extract the first ROM-owned slot-$11 actor packet-wait callsite."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# MMC3 bank $18 maps CPU $8000 to file offset $030010.
CPU_ADDRESS = 0x82F2
FILE_OFFSET = 0x030302
LENGTH = 5
EXPECTED_BYTES = bytes.fromhex("a9 01 20 15 c5")
FILENAME = "bank18_actor_animation_packet_wait_82f2_82f6.bin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Target ROM SHA-256 mismatch.")
    data = rom[FILE_OFFSET : FILE_OFFSET + LENGTH]
    if data != EXPECTED_BYTES:
        raise SystemExit(f"Unexpected ROM bytes at ${CPU_ADDRESS:04X}: {data.hex(' ')}")

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
            "Bank-$18 row-2 actor packet-wait entry: LDA #$01; JSR $C515. "
            "The saved JSR resumes at $82F7; its queue branch and packet builder "
            "are outside this span."
        ),
        "bytes": data.hex(" "),
    }
    spans = [item for item in manifest.get("spans", []) if item.get("file") != FILENAME]
    spans.append(entry)
    manifest["spans"] = spans
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Extracted {FILENAME} from ROM bank $18 at ${FILE_OFFSET:06X}.")


if __name__ == "__main__":
    main()
