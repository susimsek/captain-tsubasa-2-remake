#!/usr/bin/env python3
"""Preserve ROM sources for fresh-route callback $1F and its map-$52 entry."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/callback_dispatch"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
MAP_WORKER_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/map_worker_8525"
MAP_WORKER_MANIFEST_PATH = MAP_WORKER_DIR / "manifest.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK_FILE_BASE = 0x016010
CPU_WINDOW_BASE = 0x8000
POINTER_TABLE_CPU = 0x87F6

SPANS = [
    ("bank_0b_event_1f_pointer_boundary.bin", 0x8834, bytes.fromhex("6A 89 6F 89"),
     "Callback-$1F pointer $896A and following valid callback-$20 boundary $896F."),
    ("bank_0b_event_1f_stream.bin", 0x896A, bytes.fromhex("02 03 00 04 52"),
     "Pointer-bounded callback-$1F command bytes through callback-$20 at $896F."),
    ("bank_0b_callback_1f_handler_8358_8363.bin", 0x8358,
     bytes.fromhex("20 D9 84 A9 80 8D D1 05 A0 04 D0 C5"),
     "Callback vector row 3 handler prefix; calls $84D9 and branches to the $8329 map-selector read."),
    ("bank_0b_callback_position_helper_84d9_84f3.bin", 0x84D9,
     bytes.fromhex("20 F4 84 2C 2A 05 50 0C 8A 49 FF AA 98 49 FF A8 E8 D0 01 C8 8E DE 05 8C DF 05 60"),
     "Callback helper reads its two-byte position and applies the $052A bit-$40 transform to $05DE/$05DF."),
    ("bank_0b_callback_data_helper_84f4_8501.bin", 0x84F4,
     bytes.fromhex("A0 02 B1 52 AA C8 B1 52 A8 C9 80 F0 01 60"),
     "Callback helper reads data bytes at stream offsets 2 and 3; $04 selects its early RTS."),
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_offset(cpu_address: int) -> int:
    return BANK_FILE_BASE + cpu_address - CPU_WINDOW_BASE


def main() -> None:
    rom = ROM_PATH.read_bytes()
    digest = sha256(rom)
    if digest != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Unexpected ROM SHA-256: {digest}")
    pointer_1f_offset = file_offset(POINTER_TABLE_CPU) + 2 * 0x1F
    pointer_20_offset = file_offset(POINTER_TABLE_CPU) + 2 * 0x20
    pointer_1f = rom[pointer_1f_offset:pointer_1f_offset + 2]
    pointer_20 = rom[pointer_20_offset:pointer_20_offset + 2]
    if pointer_1f != bytes.fromhex("6A 89") or pointer_20 != bytes.fromhex("6F 89"):
        raise SystemExit("ROM callback pointers do not bound callback-$1F at $896A-$896F")

    manifest = json.loads(MANIFEST_PATH.read_text())
    if manifest.get("schema") != "first-command-callback-dispatch-sources-v1" \
            or manifest.get("rom_sha256") != EXPECTED_ROM_SHA256:
        raise SystemExit("Callback-dispatch manifest targets another ROM or schema")
    entries = manifest.setdefault("entries", [])
    existing_by_path = {entry.get("path"): entry for entry in entries}
    for filename, start, expected, role in SPANS:
        offset = file_offset(start)
        extracted = rom[offset:offset + len(expected)]
        if extracted != expected:
            raise SystemExit(f"ROM source bytes differ for {filename} at 0x{offset:06X}")
        row = {
            "path": filename,
            "file_offset": f"0x{offset:06X}",
            "size_bytes": len(extracted),
            "cpu_address": f"0x{start:04X}",
            "prg_bank": "0x0B",
            "source": role,
            "sha256": sha256(extracted),
            "raw_hex": extracted.hex(" ").upper(),
        }
        existing = existing_by_path.get(filename)
        if existing is not None and existing != row:
            raise SystemExit(f"Existing manifest row differs for {filename}")
        if existing is None:
            entries.append(row)
        OUTPUT_DIR.joinpath(filename).write_bytes(extracted)

    map52_pair = rom[file_offset(0x8792):file_offset(0x8792) + 2]
    if map52_pair != bytes.fromhex("3C 4A"):
        raise SystemExit("ROM map-$52 CHR selector pair at $8792 does not match the expected source bytes")
    map_manifest = json.loads(MAP_WORKER_MANIFEST_PATH.read_text())
    if map_manifest.get("schema") != "first-command-slot15-map-worker-8525-v1" \
            or map_manifest.get("rom_sha256") != EXPECTED_ROM_SHA256:
        raise SystemExit("Map-worker manifest targets another ROM or schema")
    map_entries = map_manifest.setdefault("entries", [])
    map_pair_row = {
        "path": "bank_0b_86ee_map_52_chr_pair.bin",
        "file_offset": "0x0167A2",
        "cpu_address": "0x8792",
        "prg_bank": "0x0B",
        "size_bytes": 2,
        "sha256": sha256(map52_pair),
        "source": "CHR selector pair read by $8525 for callback-$1F map ID $52.",
        "raw_hex": map52_pair.hex(" ").upper(),
    }
    existing_map_rows = {entry.get("path"): entry for entry in map_entries}
    existing_map_row = existing_map_rows.get(map_pair_row["path"])
    if existing_map_row is not None and existing_map_row != map_pair_row:
        raise SystemExit("Existing map-$52 CHR pair manifest row differs")
    if existing_map_row is None:
        map_entries.append(map_pair_row)
    map_manifest.setdefault("source_mapping", {}).update({
        "map_id_0x52": "fresh scenario-$36 callback-$1F stream at $896A supplies map ID $52",
        "packed_selector_index_0x14": "packed selector byte at $8B56 is $80; selector formula yields $00",
        "map_52_chr_pair": "$8792 contains 3C 4A; map-worker shifts map $52 to map-data pointer $95A4",
    })
    MAP_WORKER_DIR.joinpath(map_pair_row["path"]).write_bytes(map52_pair)
    MAP_WORKER_MANIFEST_PATH.write_text(json.dumps(map_manifest, indent=2) + "\n")

    behavior = manifest.setdefault("source_behavior", {})
    behavior["fresh_callback_1f"] = (
        "Scenario $36 record 32 1F 4C F0 resolves selector $1F to $896A; "
        "stream 02 03 00 04 52 dispatches vector row 3 to $8358, then enters map worker $8525 with map $52."
    )
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")
    print("Extracted five ROM-verified callback-$1F source spans.")
    for filename, start, expected, _ in SPANS:
        print(f"{filename}: bank $0B:${start:04X}, offset 0x{file_offset(start):06X}, "
              f"SHA-256 {sha256(expected)}")


if __name__ == "__main__":
    main()
