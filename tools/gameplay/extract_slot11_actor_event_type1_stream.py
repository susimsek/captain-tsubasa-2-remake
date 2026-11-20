#!/usr/bin/env python3
"""Extract the ROM-backed type-$01 actor-event payload stream."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# Bank $18 maps CPU $8000 to file offset $030010. This bounded stream ends
# immediately before the already documented type-$02 stream at $8E94.
CPU_ADDRESS = 0x8E37
FILE_OFFSET = 0x030E47
LENGTH = 0x5D
EXPECTED_SHA256 = "375de5d8bd3612c321f2748c1235adbea1816467c44979b920decc1e49ec30de"
FILENAME = "bank18_actor_event_payload_stream_type1_8e37_8e94.bin"


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
            "ROM event-payload stream selected by the traced type-$01 event at "
            "$A43A. The span is bounded at $8E94, where the separately "
            "verified type-$02 payload stream begins."
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
