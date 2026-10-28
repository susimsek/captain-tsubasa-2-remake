#!/usr/bin/env python3
"""Audit the bank-$18 first-action menu packet algorithm against target-ROM bytes.

The generated packet is derived only from the supplied ROM. FCEUX RAM/PPU
snapshots are loaded afterward as validation references and never feed packet
construction.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
CAPTURE_ROOT = ROOT / "reference/diagnostics/kickoff_select_test_20261027"
RAM_CAPTURE = CAPTURE_ROOT / "ram/route_frame_008953.bin"
PPU_BEFORE_CAPTURE = CAPTURE_ROOT / "ppu/route_frame_008938.bin"
PPU_CAPTURE = CAPTURE_ROOT / "ppu/route_frame_008953.bin"
OUTPUT = ROOT / "reference/rom_extract/gameplay/menus/first_action_menu/renderer_packet_audit.json"

ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK18_BASE = 0x030010

# Half-open CPU ranges and hashes of the exact target-ROM bytes relied on.
# The last two ranges are tables, not executable code.
VERIFIED_WINDOWS = {
    (0x800C, 0x800F): "bfd10ca38c56f461f9d3a718da2b94402304fd864ca2c9976e33a34df2d20c9a",
    (0x8852, 0x88B9): "8d11372278149ca95c4915e95a8e1121b938348cf73ec83408d03f825b62b070",
    (0x88B9, 0x8986): "e9d2b95c91c49f329f0d9ffb45483c9ad19868c96cbf7e6161665e982ac24570",
    (0x8986, 0x89BA): "46ac5f0183f5e0d90c90f248768b6df75bae9c5300a679cc83dfc21efb53888e",
    (0x89FA, 0x8A04): "c88664c6bbf923a189ee6e8de8e34e39896f763451ec25a4de0dafbd8d7a14a4",
    (0x8CA5, 0x8CDC): "4a73cad95d37036f5679b38bcb90952dd8496e5fdeb84da134ce9888762c7f3a",
    (0x8CDC, 0x8D9E): "c403f2f776d73968bcb401a9362959cfbe51715cb56dc411ceab281afe0f0b1e",
    (0xB3BD, 0xB3C1): "df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b81119",
    (0x8D9E, 0x8DA7): "dcb1f10d1a9a0fa616fa2e065790ce038722b09968d265e7901770b3bf9133e0",
}
VERIFIED_FIXED_WINDOWS = {
    (0xC50C, 0xC50F): "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44",
    (0xC524, 0xC52A): "88599e3243cba4f91251f7646e9d6656f4ab61751cbdd7cc31c03d8a7fcfc7c3",
    (0xC53C, 0xC53F): "6419d5a470082bb95466023cfc1b7b935f42415f3a318be99c4c612ea9bfd9e5",
    (0xCE08, 0xCE2D): "aa0e7dbc45c7a808cc93aa3c3e0bc301f7bc78e51678a3221c1b1ae6ed5bab26",
    (0xCD7C, 0xCD89): "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
    (0xEF7F, 0xEFA0): "2b58982f5d1dd906d58eb693148f3a9ff511064fce6163432f7ff30b8512dca2",
}


def bank18_offset(cpu_address: int) -> int:
    return BANK18_BASE + cpu_address - 0x8000


def fixed_bank_offset(cpu_address: int) -> int:
    return 0x03C010 + cpu_address - 0xC000


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def read_u16le(data: bytes, offset: int) -> int:
    return data[offset] | (data[offset + 1] << 8)


def descriptor_bytes(rom: bytes, descriptor_id: int) -> tuple[int, bytes]:
    pointer_address = 0xB3CF + descriptor_id * 2
    pointer_offset = bank18_offset(pointer_address)
    cpu_address = read_u16le(rom, pointer_offset)
    file_offset = bank18_offset(cpu_address)
    descriptor = rom[file_offset : file_offset + 9]
    row_count = descriptor[8]
    descriptor = rom[file_offset : file_offset + 9 + 4 * row_count]
    return cpu_address, descriptor


def style_family(rom: bytes, descriptor_id: int) -> int:
    packed = rom[bank18_offset(0xB3BD + descriptor_id // 4)]
    return (packed >> (2 * (descriptor_id & 3))) & 0x03


def packet_for_progress(
    rom: bytes,
    descriptor_id: int,
    descriptor: bytes,
    progress: int,
    overlay_tiles: dict[int, int] | None = None,
) -> bytes:
    """Reproduce one `$04A5`-format record for the documented renderer path."""
    header = descriptor[:9]
    width = header[2]
    family = style_family(rom, descriptor_id)
    frame_table = rom[bank18_offset(0x8D9E) : bank18_offset(0x8D9E) + 36]

    # The three LSR/ROR pairs in $88C8-$88D4 convert progress into NES
    # nametable address units: (progress & 7) * 32 plus (progress >> 3) * 256.
    address = (header[0] | (header[1] << 8))
    address += (progress & 0x07) * 0x20 + (progress >> 3) * 0x100

    data = [0] * width
    top = header[5]
    bottom = header[5] + header[7]
    if progress == top:
        edge = 0
    elif progress == bottom:
        edge = 6
    elif top < progress < bottom:
        edge = 3
    else:
        edge = None

    if edge is not None:
        table_index = family * 9 + edge
        data[0] = frame_table[table_index]
        data[-1] = frame_table[table_index + 2]
        for index in range(1, width - 1):
            data[index] = frame_table[table_index + 1]

    if overlay_tiles:
        for tile_column, tile_id in overlay_tiles.items():
            if 0 <= tile_column < width:
                data[tile_column] = tile_id

    return bytes((width, address & 0xFF, (address >> 8) & 0xFF, *data))


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = hashlib.sha256(rom).hexdigest()
    require(rom_hash == ROM_SHA256, f"unexpected target ROM SHA-256: {rom_hash}")

    window_hashes: list[dict[str, str]] = []
    for (start, end), expected_hash in VERIFIED_WINDOWS.items():
        source = rom[bank18_offset(start) : bank18_offset(end)]
        actual_hash = hashlib.sha256(source).hexdigest()
        require(
            actual_hash == expected_hash,
            f"ROM code/table window ${start:04X}-${end - 1:04X} hash mismatch: {actual_hash}",
        )
        window_hashes.append(
            {
                "cpu_start": f"0x{start:04X}",
                "cpu_end_exclusive": f"0x{end:04X}",
                "file_start": f"0x{bank18_offset(start):06X}",
                "bank_mapping": "bank-$18 CPU window",
                "sha256": actual_hash,
            }
        )
    for (start, end), expected_hash in VERIFIED_FIXED_WINDOWS.items():
        source = rom[fixed_bank_offset(start) : fixed_bank_offset(end)]
        actual_hash = hashlib.sha256(source).hexdigest()
        require(
            actual_hash == expected_hash,
            f"fixed-bank helper window ${start:04X}-${end - 1:04X} hash mismatch: {actual_hash}",
        )
        window_hashes.append(
            {
                "cpu_start": f"0x{start:04X}",
                "cpu_end_exclusive": f"0x{end:04X}",
                "file_start": f"0x{fixed_bank_offset(start):06X}",
                "bank_mapping": "fixed CPU $C000-$FFFF window",
                "sha256": actual_hash,
            }
        )

    desc_cpu, descriptor = descriptor_bytes(rom, 0x03)
    require(desc_cpu == 0xB48A, f"descriptor $03 pointer changed: ${desc_cpu:04X}")
    require(descriptor.hex(" ") == "32 22 0c 0a 00 01 0c 09 05 01 02 21 bc 03 01 23 bc 05 01 2e bc 07 01 39 bc 09 01 44 bc", "descriptor $03 bytes changed")
    require(style_family(rom, 0x03) == 0, "descriptor $03 frame family is no longer family 0")

    progress_packets = [packet_for_progress(rom, 0x03, descriptor, progress) for progress in range(11)]
    final_packet = progress_packets[-1]
    expected_packet = bytes.fromhex("0c 72 23 9e a9 a9 a9 a9 a9 a9 a9 a9 a9 a9 9f")
    require(final_packet == expected_packet, f"ROM candidate changed: {final_packet.hex(' ')}")

    ram = RAM_CAPTURE.read_bytes()
    ppu_before = PPU_BEFORE_CAPTURE.read_bytes()
    ppu = PPU_CAPTURE.read_bytes()
    require(len(ram) == 0x800, f"unexpected RAM snapshot length: {len(ram)}")
    require(len(ppu_before) == 0x4000, f"unexpected prior PPU snapshot length: {len(ppu_before)}")
    require(len(ppu) == 0x4000, f"unexpected PPU snapshot length: {len(ppu)}")
    captured_packet = ram[0x04A5 : 0x04A5 + len(final_packet)]
    require(captured_packet == final_packet, f"RAM $04A5 mismatch: {captured_packet.hex(' ')}")

    ppu_start = (final_packet[2] << 8) | final_packet[1]
    captured_ppu_row = ppu[ppu_start : ppu_start + final_packet[0]]
    prior_ppu_row = ppu_before[ppu_start : ppu_start + final_packet[0]]
    candidate_payload = final_packet[3:]
    require(prior_ppu_row == bytes(final_packet[0]), f"frame-8938 bottom row was not blank before panel draw: {prior_ppu_row.hex(' ')}")
    require(captured_ppu_row == candidate_payload, f"PPU row ${ppu_start:04X} mismatch: {captured_ppu_row.hex(' ')}")
    panel_changed_cells = sum(
        ppu_before[0x2000 + row * 32 + column] != ppu[0x2000 + row * 32 + column]
        for row in range(18, 28)
        for column in range(18, 30)
    )

    # Validate visible descriptor rows and static label bytes against PPU only
    # after generating their addresses/columns from ROM descriptor semantics.
    label_checks: list[dict[str, object]] = []
    row_count = descriptor[8]
    for record_index in range(row_count):
        record = 9 + 4 * record_index
        row_coordinate = descriptor[record]
        column = descriptor[record + 1]
        text_cpu = read_u16le(descriptor, record + 2)
        text_offset = bank18_offset(text_cpu)
        row_stream = bytearray()
        cursor = text_offset
        while rom[cursor] != 0xFC:
            row_stream.append(rom[cursor])
            cursor += 1
        static_prefix = bytes(value for value in row_stream if value < 0xE0)
        # Dynamic commands terminate the verifiable static prefix. Keep the
        # source order; E0/E1 are not substituted from the capture.
        first_dynamic = next((i for i, value in enumerate(row_stream) if value >= 0xE0), len(row_stream))
        static_prefix = bytes(row_stream[:first_dynamic])
        if first_dynamic < len(row_stream) and row_stream[first_dynamic] == 0xE1:
            # E1 writes digits backward from the current output cursor. The
            # zero tiles immediately before it are reserved right-alignment
            # cells and may be overwritten by a multi-digit value.
            static_prefix = static_prefix.rstrip(b"\x00")
        ppu_row = 0x2232 + row_coordinate * 0x20
        ppu_column = column
        captured_static = ppu[ppu_row + ppu_column : ppu_row + ppu_column + len(static_prefix)]
        require(captured_static == static_prefix, f"static row {record_index} mismatch at ${ppu_row + ppu_column:04X}")
        label_checks.append(
            {
                "record": record_index,
                "relative_row": row_coordinate,
                "nametable_row": 17 + row_coordinate,
                "column": column,
                "ppu_address": f"0x{ppu_row + ppu_column:04X}",
                "rom_static_prefix_hex": static_prefix.hex(" "),
                "capture_static_prefix_match": True,
                "dynamic_token_bytes_hex": bytes(row_stream[first_dynamic:]).hex(" "),
            }
        )

    report = {
        "schema": "first-action-menu-renderer-audit-v1",
        "source": {
            "rom_file": ROM_PATH.name,
            "rom_sha256": rom_hash,
            "bank": "0x18",
            "file_offset_formula": "0x030010 + (CPU - 0x8000)",
            "parser": "target-byte-checked bank-$18 6502 control flow; independent packet arithmetic audit",
        },
        "verified_windows": window_hashes,
        "descriptor": {
            "id": "0x03",
            "cpu_address": "0xB48A",
            "file_offset": f"0x{bank18_offset(desc_cpu):06X}",
            "raw_hex": descriptor.hex(" "),
            "style_family": 0,
            "header_semantics": {
                "base_ppu_address": "0x2232",
                "packet_width_and_payload_length_tiles": 12,
                "last_progress_row_inclusive": 10,
                "frame_data_column_offset": 0,
                "top_edge_progress_row": 1,
                "border_width_tiles": 12,
                "bottom_edge_relative_offset": 9,
                "text_record_count": 5,
            },
            "row_coordinates": [
                {"relative_row": descriptor[9 + 4 * i], "column": descriptor[10 + 4 * i], "text_cpu": f"0x{read_u16le(descriptor, 11 + 4 * i):04X}"}
                for i in range(row_count)
            ],
        },
        "packet_candidate": {
            "progress_sequence": list(range(11)),
            "ram_04a5_final_progress": 10,
            "ram_05c5_after_completion": 11,
            "final_packet_hex": final_packet.hex(" "),
            "source_derived_without_capture_inputs": True,
        },
        "validation_only": {
            "ram_capture": str(RAM_CAPTURE.relative_to(ROOT)),
            "ram_04a5_hex": captured_packet.hex(" "),
            "ram_packet_exact_match": captured_packet == final_packet,
            "ppu_capture": str(PPU_CAPTURE.relative_to(ROOT)),
            "ppu_row_address": f"0x{ppu_start:04X}",
            "ppu_row_hex": captured_ppu_row.hex(" "),
            "ppu_row_exact_match": captured_ppu_row == candidate_payload,
            "ppu_delta_before_capture": str(PPU_BEFORE_CAPTURE.relative_to(ROOT)),
            "ppu_delta_before_sha256": hashlib.sha256(ppu_before).hexdigest(),
            "ppu_delta_panel_bounds": {"nametable_rows": [18, 27], "columns": [18, 29]},
            "ppu_delta_changed_panel_cells": panel_changed_cells,
            "ppu_delta_bottom_row_before_hex": prior_ppu_row.hex(" "),
            "ppu_delta_bottom_row_after_hex": captured_ppu_row.hex(" "),
            "ppu_delta_bottom_row_exact_match": prior_ppu_row == bytes(final_packet[0]) and captured_ppu_row == candidate_payload,
            "static_text_rows": label_checks,
        },
        "dynamic_substitutions": {
            "E0": "reads RAM $0441; emits two position tiles from $8D04+$index*2, a blank tile, then the selected player's ROM-backed name, padded to at least five name tiles. Current player selection/name data remain caller state.",
            "E1": "consumes the next stream byte as stat selector. Selector 0 reads current-player 16-bit energy at record offsets +1/+2. Selectors 1..3 call the stat evaluator; selectors 7..23 add 8 when ball-height RAM $044E is not 1. Decimal digits use tile ID $33+digit, are emitted least-significant-first while the destination index decrements (thus right-aligned), and omit leading zeroes. Stat computation/player state remain caller inputs.",
        },
        "unresolved": [
            "The descriptor and packet source mapping is recovered; the full fixed-bank player-name lookup and bank-$1C stat evaluator are not included in this small renderer audit.",
            "The RGB palette and CHR bank selection are not proved by this nametable-packet audit; use the separately documented frame-8953 capture mapping for validation only.",
            "The packet consumer/NMI phase and first-visible-pixel timing are not measured by this audit.",
        ],
    }
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"ROM renderer audit passed; report: {OUTPUT.relative_to(ROOT)}")
    print(f"descriptor $03 / progress 10 candidate: {final_packet.hex(' ')}")
    print(f"RAM $04A5, PPU row and before/after bottom-row delta exact-match validation: PASS ({panel_changed_cells} panel cells changed)")
    print(f"static descriptor text row prefix checks: {len(label_checks)}/{len(label_checks)} PASS")


if __name__ == "__main__":
    main()
