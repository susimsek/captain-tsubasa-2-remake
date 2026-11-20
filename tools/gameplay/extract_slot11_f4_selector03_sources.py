#!/usr/bin/env python3
"""Extract the ROM spans used by the live slot-$11 F4 selector-$03 route."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

SEGMENTS = [
    {
        "file": "bank18_actor_sequence_row_handler_811E_8122.bin",
        "cpu_address": 0x811E,
        "file_offset": 0x03012E,
        "length": 4,
        "description": "Bank-$18 F4 selector-$03 row handler: LDX $0629; RTS.",
    },
    {
        "file": "bank19_actor_f4_selector03_table_A3BD_A3C9.bin",
        "cpu_address": 0xA3BD,
        "file_offset": 0x0323CD,
        "length": 12,
        "description": "Bank-$19 F4 selector-$03 pointer table. Its five little-endian targets begin at $A3C9; row zero resolves to the live event stream at $A3C9.",
    },
    {
        "file": "bank19_actor_event_stream_a3c9_a43b.bin",
        "cpu_address": 0xA3C9,
        "file_offset": 0x0323D9,
        "length": 115,
        "description": "Bank-$19 actor event stream through $A43B, including the type-$01 continuation byte read by the first packet-wait route.",
    },
    {
        "file": "bank19_actor_event_stream_continuation_A43C.bin",
        "cpu_address": 0xA43C,
        "file_offset": 0x03244C,
        "length": 1,
        "description": "The next bank-$19 event-stream command byte read from $A439+$03 by the live packet-resume path.",
    },
    {
        "file": "bank19_actor_event_stream_text_A43D_A446.bin",
        "cpu_address": 0xA43D,
        "file_offset": 0x03244D,
        "length": 10,
        "description": "Bank-$19 actor event text and terminators consumed by the second live $A439 packet-resume path.",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    actual_rom_sha256 = sha256(rom)
    if actual_rom_sha256 != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Target ROM SHA-256 mismatch: {actual_rom_sha256}")

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("rom_sha256") != EXPECTED_ROM_SHA256:
        raise SystemExit("Slot-$11 source manifest targets another ROM revision.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    new_entries = []
    for segment in SEGMENTS:
        offset = int(segment["file_offset"])
        length = int(segment["length"])
        data = rom[offset : offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated ROM span for {segment['file']}.")
        filename = str(segment["file"])
        (OUTPUT_DIR / filename).write_bytes(data)
        new_entries.append(
            {
                "file": filename,
                "cpu_address": f"0x{int(segment['cpu_address']):04X}",
                "file_offset": f"0x{offset:06X}",
                "length": length,
                "sha256": sha256(data),
                "description": str(segment["description"]),
                "bytes": data.hex(" "),
            }
        )

    replaced = {entry["file"] for entry in new_entries}
    spans = [
        entry for entry in manifest.get("spans", [])
        if str(entry.get("file", "")) not in replaced
    ]
    spans.extend(new_entries)
    manifest["spans"] = spans
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Updated {len(new_entries)} slot-$11 F4 selector-$03 source spans.")


if __name__ == "__main__":
    main()
