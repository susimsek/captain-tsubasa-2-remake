#!/usr/bin/env python3
"""Preserve the ROM spans needed to resume map-$42 worker slot $15."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/map_worker_8525"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK_0B_FILE_BASE = 0x016010
SPANS = {
    "worker_8572_85c2": (0x8572, 0x85C2),
    "metatile_expand_85c2_86d3": (0x85C2, 0x86D3),
    "map_2f_chr_pair": (0x874C, 0x874E),
    "map_36_chr_pair": (0x875A, 0x875C),
    "map_56_chr_pair": (0x879A, 0x879C),
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    entries = manifest.setdefault("entries", [])
    names = {item.get("name"): index for index, item in enumerate(entries)}
    for name, (cpu_start, cpu_end) in SPANS.items():
        file_offset = BANK_0B_FILE_BASE + cpu_start - 0x8000
        data = rom[file_offset : file_offset + cpu_end - cpu_start]
        if len(data) != cpu_end - cpu_start:
            raise SystemExit(f"Truncated source span at ${cpu_start:04X}.")
        filename = f"bank_0b_{cpu_start:04x}_{cpu_end:04x}.bin"
        path = OUTPUT_DIR / filename
        if path.exists() and path.read_bytes() != data:
            raise SystemExit(f"Preserved ROM source differs: {path}")
        path.write_bytes(data)
        entry = {
            "name": name,
            "path": filename,
            "file_offset": f"0x{file_offset:06X}",
            "cpu_start": f"0x{cpu_start:04X}",
            "cpu_end_exclusive": f"0x{cpu_end:04X}",
            "prg_bank": "0x0B",
            "size_bytes": len(data),
            "sha256": sha256(data),
            "source": ("ROM CHR selector table entry at $874C for callback-$36 map-$2F."
                       if name == "map_2f_chr_pair"
                       else "ROM CHR selector table entry for scenario-$44 callback-$70 map-$56."
                       if name == "map_56_chr_pair"
                       else "ROM CHR selector table entry for scenario-$1E callback-$45 map-$36."
                       if name == "map_36_chr_pair"
                       else "ROM bytes executed by the resumed slot-$15 map-$42 worker."),
        }
        if name in names:
            entries[names[name]] = entry
        else:
            names[name] = len(entries)
            entries.append(entry)
    mapping = manifest.setdefault("source_mapping", {})
    mapping["map_42_selector"] = "0x01"
    mapping["selector_note"] = "The packed table byte $52 at index $10 yields selector $01 for map $42."
    mapping["map_2f_selector"] = "The packed table byte $6A at index $0B yields selector $01 for map $2F."
    mapping["map_2f_chr_pair"] = "$874C contains 3C 4A for callback-$36 map ID $2F."
    mapping["map_36_selector"] = "0x01"
    mapping["map_36_chr_pair"] = "$875A contains 00 3C for map $36."
    mapping["map_56_chr_pair"] = "$879A contains 3C 2E for scenario-$44 callback-$70 map $56."
    manifest["entries"] = entries
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Preserved {len(SPANS)} bank-$0B source spans, including map-$2F, map-$36, and map-$56 CHR pairs.")


if __name__ == "__main__":
    main()
