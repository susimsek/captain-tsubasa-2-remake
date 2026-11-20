#!/usr/bin/env python3
"""Extract verified first-action input and PASS handler spans from the pinned CT2 ROM."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_action_menu_input"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROM_SIZE = 0x60010
PRG_BANK = 0x1E
CPU_WINDOW_START = 0xC000
CPU_WINDOW_END_EXCLUSIVE = 0xE000
CPU_WINDOW_FILE_BASE = 0x03C010
TABLE_CPU_ADDRESS = 0xD6E8
TABLE_LENGTH = 4
TABLE_BYTES = bytes([0x00, 0x01, 0x03, 0x02])
TABLE_RESOURCE = "direction_action_ids_context_00_D6E8.bin"
SOURCE_SPANS = [
    {
        "name": "action_input_loop_and_dispatch",
        "purpose": "Context-zero action input loop, direction lookup, confirmation gate, and action dispatch table.",
        "cpu_start": 0xD5E0,
        "cpu_end_exclusive": 0xD6E8,
        "resource": "action_input_dispatch_D5E0_D6E7.bin",
        "expected_prefix": bytes.fromhex("A9 00 8D 1E 06 A9 01 20 0F CB"),
    },
    {
        "name": "pass_receiver_handler",
        "purpose": "PASS scenario-$38 request, receiver-panel setup, receiver input loop, candidate scan, and confirmation handlers.",
        "cpu_start": 0xD7E8,
        "cpu_end_exclusive": 0xD8F7,
        "resource": "pass_receiver_handler_D7E8_D8F6.bin",
        "expected_prefix": bytes.fromhex("A9 38 20 B0 CB A9 0F 20 7F EF"),
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    if not ROM_PATH.is_file():
        raise SystemExit(f"Supplied ROM is missing: {ROM_PATH}")
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if len(rom) != EXPECTED_ROM_SIZE or rom[:4] != b"NES\x1a":
        raise SystemExit("Unexpected iNES header or ROM size")
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")

    # At the source route boundary MMC3 maps PRG bank $1E into $C000-$DFFF.
    table_offset = CPU_WINDOW_FILE_BASE + (TABLE_CPU_ADDRESS - CPU_WINDOW_START)
    table_bytes = rom[table_offset : table_offset + TABLE_LENGTH]
    if table_bytes != TABLE_BYTES:
        raise SystemExit(
            f"Context-zero table at ${TABLE_CPU_ADDRESS:04X} changed: "
            f"{table_bytes.hex(' ')}"
        )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    resource_path = OUTPUT_DIR / TABLE_RESOURCE
    resource_path.write_bytes(table_bytes)

    source_span_records = []
    for span in SOURCE_SPANS:
        cpu_start = int(span["cpu_start"])
        cpu_end = int(span["cpu_end_exclusive"])
        if not CPU_WINDOW_START <= cpu_start < cpu_end <= CPU_WINDOW_END_EXCLUSIVE:
            raise SystemExit(f"ROM source span {span['name']} leaves the mapped CPU window")
        file_offset = CPU_WINDOW_FILE_BASE + (cpu_start - CPU_WINDOW_START)
        length = cpu_end - cpu_start
        source_bytes = rom[file_offset : file_offset + length]
        if len(source_bytes) != length:
            raise SystemExit(f"ROM source span {span['name']} is truncated")
        expected_prefix = bytes(span["expected_prefix"])
        if not source_bytes.startswith(expected_prefix):
            raise SystemExit(
                f"ROM source prefix mismatch for {span['name']} at ${cpu_start:04X}: "
                f"{source_bytes[:len(expected_prefix)].hex(' ')}"
            )
        output_path = OUTPUT_DIR / str(span["resource"])
        output_path.write_bytes(source_bytes)
        source_span_records.append(
            {
                "name": str(span["name"]),
                "purpose": str(span["purpose"]),
                "prg_bank": f"0x{PRG_BANK:02X}",
                "cpu_start": f"0x{cpu_start:04X}",
                "cpu_end_exclusive": f"0x{cpu_end:04X}",
                "cpu_window": f"0x{CPU_WINDOW_START:04X}-0x{CPU_WINDOW_END_EXCLUSIVE - 1:04X}",
                "file_offset": f"0x{file_offset:06X}",
                "length_bytes": length,
                "resource": str(span["resource"]),
                "sha256": sha256(source_bytes),
                "bytes_hex": source_bytes.hex(" "),
                "verified_prefix_hex": expected_prefix.hex(" "),
            }
        )

    manifest = {
        "schema": "ct2-first-action-menu-input-rom-data-v1",
        "name": "first_action_menu_input_rom_data",
        "source_rom": ROM_PATH.name,
        "source_rom_size_bytes": len(rom),
        "source_rom_sha256": rom_hash,
        "runtime_source_kind": "ROM-derived byte spans; no emulator captures",
        "bank_mapping": {
            "mapper": "MMC3",
            "source_route_prg_bank": f"0x{PRG_BANK:02X}",
            "cpu_window": f"0x{CPU_WINDOW_START:04X}-0x{CPU_WINDOW_END_EXCLUSIVE - 1:04X}",
            "file_offset_formula": "0x03C010 + (CPU address - 0xC000)",
            "note": "The source route maps PRG bank $1E into this window; spans retain the captured bank context.",
        },
        "table": {
            "context": 0,
            "cpu_address": f"0x{TABLE_CPU_ADDRESS:04X}",
            "prg_bank": f"0x{PRG_BANK:02X}",
            "cpu_window": f"0x{CPU_WINDOW_START:04X}-0x{CPU_WINDOW_END_EXCLUSIVE - 1:04X}",
            "file_offset": f"0x{table_offset:06X}",
            "length_bytes": len(table_bytes),
            "direction_order": ["Right", "Left", "Down", "Up"],
            "action_ids_by_direction": list(table_bytes),
            "resource": TABLE_RESOURCE,
            "sha256": sha256(table_bytes),
            "bytes_hex": table_bytes.hex(" "),
        },
        "source_spans": source_span_records,
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"ROM SHA-256: {rom_hash}")
    print(f"Extracted action table ${TABLE_CPU_ADDRESS:04X}: {sha256(table_bytes)}")
    for record in source_span_records:
        start_address = int(str(record["cpu_start"]), 16)
        end_address = int(str(record["cpu_end_exclusive"]), 16) - 1
        print(
            f"Extracted ${start_address:04X}-${end_address:04X} "
            f"to {record['resource']}: {record['sha256']}"
        )
    print(f"Manifest: {(OUTPUT_DIR / 'manifest.json').relative_to(ROOT)}")


if __name__ == "__main__":
    main()
