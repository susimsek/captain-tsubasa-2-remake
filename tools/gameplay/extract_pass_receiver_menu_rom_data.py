#!/usr/bin/env python3
"""Export the supplied ROM's PASS receiver-menu descriptor and text rows.

This offline extractor reads only the pinned Turkish ROM. It does not read
emulator captures, screenshots, or audio.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/menus/pass_receiver_menu"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROM_SIZE = 0x60010
BANK18_FILE_BASE = 0x030010
DESCRIPTOR_TABLE_CPU = 0xB3CF
DESCRIPTOR_ID = 0x0F
ALIASED_DESCRIPTOR_ID = 0x0E
EXPECTED_DESCRIPTOR_CPU = 0xB58D
EXPECTED_NEXT_DESCRIPTOR_CPU = 0xB5A2
EXPECTED_HANDLER_CPU = 0xD7E8
EXPECTED_HANDLER_PREFIX = bytes.fromhex("A9 38 20 B0 CB A9 0F 20 7F EF")
ROW_TERMINATOR = 0xFC


def bank18_file_offset(cpu_address: int) -> int:
    if not 0x8000 <= cpu_address < 0xC000:
        raise ValueError(f"CPU address ${cpu_address:04X} is outside bank-$18's window")
    return BANK18_FILE_BASE + cpu_address - 0x8000


def fixed_c000_file_offset(cpu_address: int) -> int:
    if not 0xC000 <= cpu_address < 0xE000:
        raise ValueError(f"CPU address ${cpu_address:04X} is outside the fixed $C000 window")
    return 0x03C010 + cpu_address - 0xC000


def read_row(rom: bytes, cpu_address: int) -> bytes:
    offset = bank18_file_offset(cpu_address)
    limit = min(len(rom), offset + 0x100)
    end = rom.find(bytes([ROW_TERMINATOR]), offset, limit)
    if end < 0:
        raise ValueError(f"No `$FC` terminator within 256 bytes of ${cpu_address:04X}")
    return rom[offset : end + 1]


def parse_descriptor(rom: bytes) -> tuple[dict, bytes, list[bytes]]:
    table_cpu = DESCRIPTOR_TABLE_CPU + DESCRIPTOR_ID * 2
    table_offset = bank18_file_offset(table_cpu)
    pointer_bytes = rom[table_offset : table_offset + 2]
    next_pointer_bytes = rom[table_offset + 2 : table_offset + 4]
    if len(pointer_bytes) != 2 or len(next_pointer_bytes) != 2:
        raise ValueError("Descriptor pointer-table entry is truncated")

    descriptor_cpu = int.from_bytes(pointer_bytes, "little")
    next_descriptor_cpu = int.from_bytes(next_pointer_bytes, "little")
    if descriptor_cpu != EXPECTED_DESCRIPTOR_CPU:
        raise ValueError(f"Descriptor `$0F` pointer changed: got ${descriptor_cpu:04X}")
    if next_descriptor_cpu != EXPECTED_NEXT_DESCRIPTOR_CPU:
        raise ValueError(f"Next descriptor pointer changed: got ${next_descriptor_cpu:04X}")
    alias_table_offset = bank18_file_offset(
        DESCRIPTOR_TABLE_CPU + ALIASED_DESCRIPTOR_ID * 2
    )
    alias_cpu = int.from_bytes(rom[alias_table_offset : alias_table_offset + 2], "little")
    if alias_cpu != descriptor_cpu:
        raise ValueError(f"Descriptor `$0E` no longer aliases `$0F` at ${descriptor_cpu:04X}")

    descriptor_offset = bank18_file_offset(descriptor_cpu)
    header = rom[descriptor_offset : descriptor_offset + 9]
    if len(header) != 9:
        raise ValueError("Descriptor `$0F` header is truncated")
    row_count = header[8]
    descriptor_length = 9 + row_count * 4
    descriptor_raw = rom[descriptor_offset : descriptor_offset + descriptor_length]
    if len(descriptor_raw) != descriptor_length:
        raise ValueError("Descriptor `$0F` record stream is truncated")
    if descriptor_cpu + descriptor_length != next_descriptor_cpu:
        raise ValueError(
            f"Descriptor `$0F` span ends at ${descriptor_cpu + descriptor_length:04X}, "
            f"next pointer is ${next_descriptor_cpu:04X}"
        )

    rows: list[dict] = []
    row_resources: list[bytes] = []
    for row_index in range(row_count):
        record_offset = 9 + row_index * 4
        raw_coordinate_bytes = descriptor_raw[record_offset : record_offset + 2]
        text_pointer = int.from_bytes(
            descriptor_raw[record_offset + 2 : record_offset + 4], "little"
        )
        row_bytes = read_row(rom, text_pointer)
        row_resources.append(row_bytes)
        rows.append(
            {
                "row_index": row_index,
                "descriptor_record_offset": record_offset,
                "coordinate_bytes_raw": list(raw_coordinate_bytes),
                "coordinate_semantics": "raw descriptor bytes; not pixel coordinates",
                "text_pointer_cpu": f"0x{text_pointer:04X}",
                "text_pointer_file_offset": f"0x{bank18_file_offset(text_pointer):06X}",
                "text_source_length_bytes": len(row_bytes),
                "text_source_sha256": hashlib.sha256(row_bytes).hexdigest(),
                "text_source_bytes_hex": row_bytes.hex(" "),
                "text_resource": f"row_{row_index:02d}.bin",
                "text_byte_semantics": "raw ROM tile/control bytes; glyph interpretation is separate",
            }
        )

    entry = {
        "descriptor_id": f"0x{DESCRIPTOR_ID:02X}",
        "pointer_table_entry_cpu": f"0x{table_cpu:04X}",
        "pointer_table_entry_file_offset": f"0x{table_offset:06X}",
        "pointer_bytes_hex": pointer_bytes.hex(" "),
        "next_pointer_bytes_hex": next_pointer_bytes.hex(" "),
        "descriptor_cpu_address": f"0x{descriptor_cpu:04X}",
        "descriptor_file_offset": f"0x{descriptor_offset:06X}",
        "descriptor_length_bytes": descriptor_length,
        "descriptor_sha256": hashlib.sha256(descriptor_raw).hexdigest(),
        "descriptor_raw_hex": descriptor_raw.hex(" "),
        "header_raw_bytes": list(header),
        "window_width_tiles": header[2],
        "window_height_tiles": header[3],
        "row_record_count": row_count,
        "rows": rows,
    }
    return entry, descriptor_raw, row_resources


def main() -> None:
    if not ROM_PATH.is_file():
        raise SystemExit(f"Supplied ROM is missing: {ROM_PATH}")
    rom = ROM_PATH.read_bytes()
    rom_sha256 = hashlib.sha256(rom).hexdigest()
    if rom_sha256 != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_sha256}")
    if len(rom) != EXPECTED_ROM_SIZE or rom[:4] != b"NES\x1a":
        raise SystemExit("Unexpected iNES header or ROM size")

    handler_offset = fixed_c000_file_offset(EXPECTED_HANDLER_CPU)
    handler_bytes = rom[handler_offset : handler_offset + len(EXPECTED_HANDLER_PREFIX)]
    if handler_bytes != EXPECTED_HANDLER_PREFIX:
        raise SystemExit("PASS handler `$D7E8` no longer selects descriptor `$0F` as expected")

    descriptor, descriptor_bytes, row_resources = parse_descriptor(rom)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "descriptor_0F.bin").write_bytes(descriptor_bytes)
    for index, row_bytes in enumerate(row_resources):
        (OUTPUT_DIR / f"row_{index:02d}.bin").write_bytes(row_bytes)

    manifest = {
        "schema": "ct2-pass-receiver-menu-rom-data-v1",
        "name": "pass_receiver_menu_rom_data",
        "source_rom": ROM_PATH.name,
        "source_rom_sha256": rom_sha256,
        "runtime_source_kind": "ROM-derived byte spans; no emulator captures",
        "bank_mapping": {
            "bank18_cpu_window": "0x8000-0xBFFF",
            "bank18_file_offset_formula": "0x030010 + (CPU - 0x8000)",
            "fixed_c000_cpu_window": "0xC000-0xDFFF",
            "fixed_c000_file_offset_formula": "0x03C010 + (CPU - 0xC000)",
        },
        "descriptor_selection": {
            "handler_cpu_address": f"0x{EXPECTED_HANDLER_CPU:04X}",
            "handler_file_offset": f"0x{handler_offset:06X}",
            "handler_source_bytes_hex": handler_bytes.hex(" "),
            "decoded_scope": "source prefix requests scenario $38, then passes descriptor ID $0F to the $EF7F renderer wrapper",
        },
        "pointer_table": {
            "cpu_address": f"0x{DESCRIPTOR_TABLE_CPU:04X}",
            "descriptor_id": f"0x{DESCRIPTOR_ID:02X}",
            "entry_cpu_address": f"0x{DESCRIPTOR_TABLE_CPU + DESCRIPTOR_ID * 2:04X}",
            "entry_file_offset": f"0x{bank18_file_offset(DESCRIPTOR_TABLE_CPU + DESCRIPTOR_ID * 2):06X}",
            "descriptor_pointer_bytes_hex": rom[
                bank18_file_offset(DESCRIPTOR_TABLE_CPU + DESCRIPTOR_ID * 2) :
                bank18_file_offset(DESCRIPTOR_TABLE_CPU + DESCRIPTOR_ID * 2) + 2
            ].hex(" "),
            "next_pointer_bytes_hex": rom[
                bank18_file_offset(DESCRIPTOR_TABLE_CPU + (DESCRIPTOR_ID + 1) * 2) :
                bank18_file_offset(DESCRIPTOR_TABLE_CPU + (DESCRIPTOR_ID + 1) * 2) + 2
            ].hex(" "),
            "next_descriptor_id": f"0x{DESCRIPTOR_ID + 1:02X}",
            "next_descriptor_cpu_address": f"0x{EXPECTED_NEXT_DESCRIPTOR_CPU:04X}",
            "same_pointer_descriptor_ids": [
                f"0x{ALIASED_DESCRIPTOR_ID:02X}", f"0x{DESCRIPTOR_ID:02X}"
            ],
        },
        "descriptor_resource": "descriptor_0F.bin",
        "descriptor": descriptor,
        "shared_renderer_dependency": {
            "window_family_resource": "reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin",
            "note": "Shared border bytes are owned by the existing first-action-menu export; this package does not duplicate them.",
        },
        "evidence_boundary": {
            "source_bytes_verified_against_rom": True,
            "emulator_pixels_or_captured_audio_used_as_source": False,
            "runtime_player_or_match_state_baked": False,
            "raw_coordinate_semantics": "unresolved here; retained only as descriptor values",
        },
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Exported descriptor $0F and {len(row_resources)} ROM text rows to {OUTPUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
