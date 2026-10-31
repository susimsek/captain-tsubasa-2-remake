#!/usr/bin/env python3
"""Extract descriptor $01 and its fresh-match ED/EE ROM source contract."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT = ROOT / "reference/rom_extract/gameplay/field_entry_window_01"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK18_BASE = 0x030010
FIXED_BASE = 0x03C010


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def bank18(cpu: int) -> int:
    return BANK18_BASE + cpu - 0x8000


def fixed(cpu: int) -> int:
    return FIXED_BASE + cpu - 0xC000


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha(rom) != ROM_SHA256 or len(rom) != 0x60010:
        raise SystemExit("Unexpected target ROM identity or size.")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    resources: list[dict] = []

    def save(name: str, data: bytes, cpu: int, offset: int, meaning: str) -> None:
        (OUTPUT / name).write_bytes(data)
        resources.append({
            "path": name,
            "cpu_address": f"0x{cpu:04X}",
            "file_offset": f"0x{offset:06X}",
            "size_bytes": len(data),
            "sha256": sha(data),
            "meaning": meaning,
        })

    pointer_cpu = 0xB3D1
    pointer_offset = bank18(pointer_cpu)
    pointer = rom[pointer_offset:pointer_offset + 2]
    descriptor_cpu = int.from_bytes(pointer, "little")
    if descriptor_cpu != 0xB464:
        raise SystemExit(f"Descriptor-$01 pointer changed to ${descriptor_cpu:04X}.")
    descriptor_offset = bank18(descriptor_cpu)
    descriptor = rom[descriptor_offset:descriptor_offset + 9]
    row_count = descriptor[8]
    if row_count != 4:
        raise SystemExit("Descriptor-$01 no longer has four source rows.")
    descriptor = rom[descriptor_offset:descriptor_offset + 9 + row_count * 4]
    next_pointer = int.from_bytes(rom[pointer_offset + 2:pointer_offset + 4], "little")
    if len(descriptor) != 25 or descriptor_cpu + len(descriptor) != next_pointer:
        raise SystemExit("Descriptor-$01 byte length no longer reaches descriptor $02.")
    save("descriptor_01_pointer.bin", pointer, pointer_cpu, pointer_offset,
         "ROM descriptor-table entry for window descriptor $01")
    save("descriptor_01.bin", descriptor, descriptor_cpu, descriptor_offset,
         "ROM header and four progress/column/token-stream records for descriptor $01")

    expected_rows = [(0xBBE0, 0xED), (0xBD9C, 0xEE),
                     (0xBBE3, 0xED), (0xBD9F, 0xEE)]
    for index, (cpu, token) in enumerate(expected_rows):
        offset = bank18(cpu)
        end = rom.find(b"\xFC", offset, offset + 16)
        if end < 0:
            raise SystemExit(f"Descriptor row {index} has no source $FC terminator.")
        row = rom[offset:end + 1]
        expected_operand = 0 if index in (0, 1) else 1
        if row != bytes([token, expected_operand, 0xFC]):
            raise SystemExit(f"Descriptor row {index} token or operand changed: {row.hex()}.")
        save(f"descriptor_01_row_{index:02d}.bin", row, cpu, offset,
             f"Descriptor-$01 row {index} token, operand, and ROM terminator")

    spans = [
        ("token_dispatch_vectors_E0_F0_89BA_89DC.bin", 0x89BA, 0x89DC,
         "$ED/$EE dispatch vectors from the ROM token table"),
        ("token_parser_8986_89BA.bin", 0x8986, 0x89BA,
         "ROM row parser: consumes a control token and its one-byte operand"),
        ("ed_text_loop_8A56_8A86.bin", 0x8A56, 0x8A86,
         "ROM inline-text scan, $C524 conversion, and $8C9F character emission"),
        ("ed_team_handler_8AE7_8B0A.bin", 0x8AE7, 0x8B0A,
         "$ED handler: selects $002A/$002B, length, and ROM team-name stream"),
        ("ed_team_name_lengths_8B0A_8B0E.bin", 0x8B0A, 0x8B0E,
         "Team-name output lengths for source team IDs 0 through 3"),
        ("ee_numeric_handler_8B2F_8B48.bin", 0x8B2F, 0x8B48,
         "$EE handler: selects $0628/$0629 and enters ROM decimal formatter"),
        ("decimal_formatter_8C55_8C85.bin", 0x8C55, 0x8C85,
         "ROM decimal formatting path; value zero emits no digit tile"),
        ("character_buffer_writer_8C85_8CA5.bin", 0x8C85, 0x8CA5,
         "ROM character-buffer writer and decimal output wrapper"),
    ]
    for name, start, end, meaning in spans:
        offset = bank18(start)
        save(name, rom[offset:offset + end - start], start, offset, meaning)

    fixed_spans = [
        ("fixed_text_helper_vector_C524_C527.bin", 0xC524, 0xC527,
         "ROM text-byte conversion helper vector"),
        ("fixed_team_name_dispatch_C53C_C53F.bin", 0xC53C, 0xC53F,
         "ROM team-name lookup dispatch vector"),
        ("fixed_text_converter_CBC2_CBF1.bin", 0xCBC2, 0xCBF1,
         "ROM character converter used by the $ED string loop"),
        ("fixed_team_name_lookup_F30F_F329.bin", 0xF30F, 0xF329,
         "ROM lookup routine mapping team-name selector to a string pointer"),
    ]
    for name, start, end, meaning in fixed_spans:
        offset = fixed(start)
        save(name, rom[offset:offset + end - start], start, offset, meaning)

    family_offset = bank18(0xB3BD)
    save("descriptor_frame_family_selector_B3BD.bin", rom[family_offset:family_offset + 1],
         0xB3BD, family_offset,
         "Packed ROM window-family selector; descriptor-$01 uses bits 2-3")

    # Selector A is team_id + $76. These four pointer words cover team IDs 0-3.
    table_cpu = 0xF329 + 0x76 * 2
    table_offset = fixed(table_cpu)
    pointer_words = rom[table_offset:table_offset + 8]
    save("fixed_team_name_pointer_entries_76_79_F415_F41D.bin", pointer_words,
         table_cpu, table_offset, "ROM name-pointer entries for fresh-match team IDs 0-3")
    name_entries = []
    for name, team_id, pointer_index, expected_cpu in [("team_00_name_stream.bin", 0, 0, 0xF776),
                                                        ("team_03_name_stream.bin", 3, 3, 0xF785)]:
        name_cpu = int.from_bytes(pointer_words[pointer_index * 2:pointer_index * 2 + 2], "little")
        if name_cpu != expected_cpu:
            raise SystemExit(f"ROM team-name pointer for team {pointer_index} changed: ${name_cpu:04X}.")
        name_offset = fixed(name_cpu)
        terminator = rom.find(b"\xFC", name_offset, name_offset + 64)
        if terminator < 0:
            raise SystemExit(f"ROM team-name stream {pointer_index} has no $FC terminator.")
        raw = rom[name_offset:terminator + 1]
        save(name, raw, name_cpu, name_offset,
             f"ROM team-name string for team ID {pointer_index * 3}; $ED emits its first three bytes")
        prefix = raw[:3]
        if any(value < 0x41 or value > 0x5A for value in prefix):
            raise SystemExit(f"Team {team_id} prefix left the verified uppercase ASCII path.")
        converted = bytes((value + 0x8C) & 0xFF for value in prefix)
        name_entries.append({"team_id": team_id, "selector": f"0x{0x76 + team_id:02X}",
                             "string_resource": name, "source_prefix_hex": prefix.hex(" ").upper(),
                             "converted_tile_ids_hex": converted.hex(" ").upper()})

    frame_path = "reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin"
    frame_data = (ROOT / frame_path).read_bytes()
    frame = {"path_from_project_root": frame_path, "cpu_address": "0x8D9E",
             "file_offset": "0x030DAE", "size_bytes": len(frame_data),
             "sha256": sha(frame_data), "raw_hex": frame_data.hex(" ")}

    manifest = {
        "schema": "ct2-field-entry-window-01-rom-sources-v1",
        "source_rom": {"name": ROM_PATH.name, "sha256": ROM_SHA256,
                       "size_bytes": len(rom), "runtime_dependency": False},
        "bank_mapping": {"bank_18_cpu_8000_file_base": "0x030010",
                         "fixed_cpu_c000_file_base": "0x03C010"},
        "resources": resources,
        "shared_frame_family": frame,
        "packet_contract": {
            "builder": "FirstActionMenuRomLayout.build_packets plus ROM $ED/$EE substitutions",
            "packet_bytes": "payload length, PPU address low, PPU address high, payload tiles",
            "descriptor_id": "0x01", "descriptor_cpu": "0xB464",
            "supported_fresh_match_inputs": {
                "$002A": "0x00", "$002B": "0x03", "$0628": "0x00", "$0629": "0x00"},
            "ed_handlers": "$89BA vector -> $8AE7; IDs 0 and 3 resolve through $F30F to ROM strings; $8B0A length table emits three characters",
            "ee_handlers": "$89BA vector -> $8B2F; reads $0628/$0629 and then $003C at $8C55; value zero may emit tile $33 when the $003C early-return is not taken",
            "team_name_outputs": name_entries,
            "source_input_producers": {
                "$002A/$002B": "hash-checked RomFreshMatchSelectorExecutor through $A20F->$A86E->$A8B6 RTS",
                "$0628": "fresh setup caller $A2AF invokes the hash-checked $AA06 zero-fill over $0468-$06FF",
                "$0629": "hash-checked RomFreshPeriodTask $D11E->$D182 writes fresh period zero"},
            "missing_caller_input": "$003C is not present in the hash-checked selector, fresh setup zero-fill, or fresh-period results; EE rows remain unqueueable until sourced.",
            "unsupported": "Other team IDs and nonzero $0628/$0629 values are refused; no later map/palette/OAM/raster work is included.",
        },
    }
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Extracted descriptor $01 sources to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
