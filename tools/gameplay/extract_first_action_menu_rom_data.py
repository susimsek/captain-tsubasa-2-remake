#!/usr/bin/env python3
"""Export first-action menu descriptors, frame tiles, and ROM text streams.

This is an offline extractor for the supplied Turkish ROM. It preserves source
bytes and emits a ROM-backed layout manifest; it does not read screenshots,
FCEUX state, or the emulator at runtime.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/menus/first_action_menu"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK18_FILE_BASE = 0x030010
MENU_DESCRIPTOR_TABLE_CPU = 0xB3CF
WINDOW_TILE_TABLE_CPU = 0x8D9E
WINDOW_TILE_COUNT = 9
STRING_END = 0xFC


def bank18_file_offset(cpu_address: int) -> int:
    if not 0x8000 <= cpu_address < 0xC000:
        raise ValueError(f"Address ${cpu_address:04X} is outside the bank-$18 CPU window")
    return BANK18_FILE_BASE + cpu_address - 0x8000


def parse_text_stream(rom: bytes, cpu_address: int) -> tuple[list[int], list[dict]]:
    """Read one descriptor-owned string through its FC terminator."""
    offset = bank18_file_offset(cpu_address)
    values: list[int] = []
    tokens: list[dict] = []
    cursor = offset
    while cursor < len(rom) and cursor - offset < 0x100:
        value = rom[cursor]
        values.append(value)
        if value == STRING_END:
            tokens.append({"kind": "row_end", "value": value})
            return values, tokens
        if value == 0xE0:
            tokens.append({"kind": "dynamic_player_name_position", "value": value})
            cursor += 1
            continue
        if value == 0xE1:
            if cursor + 1 >= len(rom):
                raise ValueError(f"Truncated E1 substitution at CPU ${cpu_address:04X}")
            argument = rom[cursor + 1]
            values.append(argument)
            tokens.append({"kind": "dynamic_player_stat", "value": value, "stat_index": argument})
            cursor += 2
            continue
        if value <= 0xD7:
            tokens.append({"kind": "chr_tile_character", "tile_id": value})
        else:
            tokens.append({"kind": "unclassified_control", "value": value})
        cursor += 1
    raise ValueError(f"No FC row terminator found within 256 bytes from ${cpu_address:04X}")


def parse_descriptor(rom: bytes, descriptor_id: int, next_pointer: int) -> tuple[dict, bytes]:
    table_entry_cpu = MENU_DESCRIPTOR_TABLE_CPU + descriptor_id * 2
    table_entry_offset = bank18_file_offset(table_entry_cpu)
    pointer_bytes = rom[table_entry_offset:table_entry_offset + 2]
    if len(pointer_bytes) != 2:
        raise ValueError(f"Descriptor pointer {descriptor_id} is truncated")
    descriptor_cpu = int.from_bytes(pointer_bytes, "little")
    descriptor_offset = bank18_file_offset(descriptor_cpu)
    header = rom[descriptor_offset:descriptor_offset + 9]
    if len(header) != 9:
        raise ValueError(f"Descriptor ${descriptor_id:02X} has a truncated header")
    row_count = header[8]
    descriptor_length = 9 + row_count * 4
    raw = rom[descriptor_offset:descriptor_offset + descriptor_length]
    if len(raw) != descriptor_length:
        raise ValueError(f"Descriptor ${descriptor_id:02X} has truncated row records")
    if descriptor_cpu + descriptor_length != next_pointer:
        raise ValueError(
            f"Descriptor ${descriptor_id:02X} span ends ${descriptor_cpu + descriptor_length:04X}, "
            f"but next table pointer is ${next_pointer:04X}"
        )

    rows: list[dict] = []
    for index in range(row_count):
        record_offset = 9 + index * 4
        coord_a, coord_b = raw[record_offset], raw[record_offset + 1]
        text_pointer = int.from_bytes(raw[record_offset + 2:record_offset + 4], "little")
        text_bytes, tokens = parse_text_stream(rom, text_pointer)
        rows.append({
            "row_index": index,
            "descriptor_record_offset": record_offset,
            "coordinate_bytes_raw": [coord_a, coord_b],
            "coordinate_semantics": "unresolved raw descriptor coordinates; do not treat as pixel positions",
            "text_pointer_cpu": f"0x{text_pointer:04X}",
            "text_pointer_file_offset": f"0x{bank18_file_offset(text_pointer):06X}",
            "text_source_bytes_hex": bytes(text_bytes).hex(" "),
            "text_source_length_bytes": len(text_bytes),
            "text_source_sha256": hashlib.sha256(bytes(text_bytes)).hexdigest(),
            "text_source_resource": f"reference/rom_extract/gameplay/menus/first_action_menu/menu_{descriptor_id:02X}_row_{index:02d}.bin",
            "tokens": tokens,
        })

    width_tiles = header[2]
    height_tiles = header[3]
    if width_tiles < 2 or height_tiles < 2:
        raise ValueError(f"Descriptor ${descriptor_id:02X} has invalid window dimensions")
    return {
        "descriptor_id": f"0x{descriptor_id:02X}",
        "pointer_table_entry_cpu": f"0x{table_entry_cpu:04X}",
        "pointer_table_entry_file_offset": f"0x{table_entry_offset:06X}",
        "pointer_bytes_hex": pointer_bytes.hex(" "),
        "descriptor_cpu_address": f"0x{descriptor_cpu:04X}",
        "descriptor_file_offset": f"0x{descriptor_offset:06X}",
        "descriptor_length_bytes": descriptor_length,
        "descriptor_sha256": hashlib.sha256(raw).hexdigest(),
        "descriptor_raw_hex": raw.hex(" "),
        "header_raw_bytes": list(header),
        "window_width_tiles": width_tiles,
        "window_height_tiles": height_tiles,
        "row_record_count": row_count,
        "rows": rows,
        "relative_window_tile_grid": build_window_grid(width_tiles, height_tiles, _WINDOW_TILES),
    }, raw


_WINDOW_TILES: bytes = b""


def build_window_grid(width: int, height: int, tile_family: bytes) -> list[list[int]]:
    """Expand the ROM's 3x3 border tile family into a relative window grid."""
    # ROM table $8D9E is laid out row-major: corners, then horizontal/vertical
    # edges and the center tile. The raw table is preserved separately below.
    grid: list[list[int]] = []
    for y in range(height):
        row: list[int] = []
        for x in range(width):
            if y == 0:
                row.append(tile_family[[0, 1, 2][0 if x == 0 else (2 if x == width - 1 else 1)]])
            elif y == height - 1:
                row.append(tile_family[[6, 7, 8][0 if x == 0 else (2 if x == width - 1 else 1)]])
            else:
                row.append(tile_family[[3, 4, 5][0 if x == 0 else (2 if x == width - 1 else 1)]])
        grid.append(row)
    return grid


def main() -> None:
    global _WINDOW_TILES
    rom = ROM_PATH.read_bytes()
    rom_sha256 = hashlib.sha256(rom).hexdigest()
    if rom_sha256 != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_sha256}")
    if len(rom) != 0x60010 or rom[:4] != b"NES\x1a":
        raise SystemExit("Unexpected iNES header or ROM size")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    window_offset = bank18_file_offset(WINDOW_TILE_TABLE_CPU)
    window_tiles = rom[window_offset:window_offset + WINDOW_TILE_COUNT]
    if len(window_tiles) != WINDOW_TILE_COUNT:
        raise SystemExit("Window tile family is truncated")
    (OUTPUT_DIR / "window_3x3_tile_ids.bin").write_bytes(window_tiles)
    _WINDOW_TILES = window_tiles

    descriptors: list[dict] = []
    for descriptor_id in (2, 3):
        entry_cpu = MENU_DESCRIPTOR_TABLE_CPU + descriptor_id * 2
        entry_offset = bank18_file_offset(entry_cpu)
        descriptor_cpu = int.from_bytes(rom[entry_offset:entry_offset + 2], "little")
        next_entry_offset = entry_offset + 2
        next_pointer = int.from_bytes(rom[next_entry_offset:next_entry_offset + 2], "little")
        descriptor, raw = parse_descriptor(rom, descriptor_id, next_pointer)
        descriptors.append(descriptor)
        (OUTPUT_DIR / f"menu_descriptor_{descriptor_id:02X}.bin").write_bytes(raw)
        for row in descriptor["rows"]:
            row_bytes = bytes.fromhex(row["text_source_bytes_hex"])
            (OUTPUT_DIR / f"menu_{descriptor_id:02X}_row_{row['row_index']:02d}.bin").write_bytes(row_bytes)

    status_start = 0xBC21
    status_end = 0xBC4F  # byte immediately after the fifth descriptor-owned FC row
    status_raw = rom[bank18_file_offset(status_start):bank18_file_offset(status_end)]
    (OUTPUT_DIR / "status_panel_text_rows.bin").write_bytes(status_raw)

    manifest = {
        "schema": 1,
        "name": "first_action_menu_rom_data",
        "source_rom": ROM_PATH.name,
        "source_rom_sha256": rom_sha256,
        "bank": "0x18",
        "file_offset_formula": "0x030010 + (CPU - 0x8000)",
        "parser": {
            "menu_descriptor_table_cpu": f"0x{MENU_DESCRIPTOR_TABLE_CPU:04X}",
            "descriptor_header_length": 9,
            "row_record_length": 4,
            "row_count_header_offset": 8,
            "text_row_terminator": f"0x{STRING_END:02X}",
            "dynamic_tokens": {
                "0xE0": "current player name/position substitution; value is runtime state",
                "0xE1": "current player stat substitution; next byte is source stat index",
            },
            "coordinate_interpretation": "raw bytes preserved; exact renderer coordinate semantics not inferred",
        },
        "window_frame": {
            "source_cpu_address": f"0x{WINDOW_TILE_TABLE_CPU:04X}",
            "source_file_offset": f"0x{window_offset:06X}",
            "source_bytes_hex": window_tiles.hex(" "),
            "source_sha256": hashlib.sha256(window_tiles).hexdigest(),
            "layout": "3x3 row-major border family expanded by width/height from each descriptor",
            "tile_order": ["top_left", "top_edge", "top_right", "left_edge", "center", "right_edge", "bottom_left", "bottom_edge", "bottom_right"],
        },
        "descriptor_resources": [
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_descriptor_02.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_descriptor_03.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_02_row_00.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_03_row_00.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_03_row_01.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_03_row_02.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_03_row_03.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/menu_03_row_04.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin",
            "reference/rom_extract/gameplay/menus/first_action_menu/status_panel_text_rows.bin",
        ],
        "descriptors": descriptors,
        "static_label_aliases": [
            {"source_text_cpu": "0xBC23", "source_text_file_offset": "0x033C33", "rom_tile_codes_hex": "45 6E 65 72 6A 69", "label": "Enerji"},
            {"source_text_cpu": "0xBC2E", "source_text_file_offset": "0x033C3E", "rom_tile_codes_hex": "43 61 6C 69 6D", "label": "Çalım", "note": "Turkish glyph alias is descriptive metadata; source bytes remain unchanged."},
            {"source_text_cpu": "0xBC39", "source_text_file_offset": "0x033C49", "rom_tile_codes_hex": "50 61 73", "label": "Pas"},
            {"source_text_cpu": "0xBC44", "source_text_file_offset": "0x033C54", "rom_tile_codes_hex": "53 75 74", "label": "Şut", "note": "Turkish glyph alias is descriptive metadata; source bytes remain unchanged."},
        ],
        "evidence_boundary": {
            "rom_bytes_are_runtime_source": True,
            "emulator_pixels_or_captured_audio_used_as_source": False,
            "dynamic_player_and_stats_baked": False,
            "captured_ppu_dump_used_for_validation_only": "reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin",
            "remaining": [
                "Full 6502 bank-18 renderer coordinate/first-row semantics are not decoded here.",
                "Dynamic E0/E1 substitutions must be executed from gameplay state.",
                "Field background, PPU raster changes, and exact menu packet timing are separate unresolved tasks.",
            ],
        },
    }
    (OUTPUT_DIR / "menu_rom_data.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Exported ROM descriptors 02/03 and {len(window_tiles)} window tiles to {OUTPUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
