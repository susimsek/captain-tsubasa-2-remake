#!/usr/bin/env python3
"""Extract source tables used by the first-action-menu dynamic substitutions."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
CAPTURE_ROOT = ROOT / "reference/diagnostics/kickoff_select_test_20261027"
RAM_CAPTURE = CAPTURE_ROOT / "ram/route_frame_008953.bin"
PPU_CAPTURE = CAPTURE_ROOT / "ppu/route_frame_008953.bin"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/menus/first_action_menu"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def bank18(cpu: int) -> int:
    return 0x030010 + cpu - 0x8000


def fixed(cpu: int) -> int:
    return 0x03C010 + cpu - 0xC000


def bank1c(cpu: int) -> int:
    return 0x038010 + cpu - 0x8000


def read(rom: bytes, offset: int, size: int) -> bytes:
    value = rom[offset : offset + size]
    if len(value) != size:
        raise ValueError(f"short ROM read at {offset:#x} size {size:#x}")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def resolve_name_tiles(player_id: int, pointer_table: bytes, strings: bytes) -> tuple[int, bytes]:
    if not 1 <= player_id <= 0xEF:
        raise ValueError("this ROM name table supports IDs $01-$EF; ID $00 is match-state data")
    ptr_offset = player_id * 2
    pointer = pointer_table[ptr_offset] | (pointer_table[ptr_offset + 1] << 8)
    if not 0xF509 <= pointer < 0xFD15:
        raise ValueError(f"player ID ${player_id:02X} has out-of-range name pointer ${pointer:04X}")
    cursor = pointer - 0xF509
    result = bytearray()
    while cursor < len(strings):
        tile = strings[cursor]
        cursor += 1
        if tile == 0xFC:
            return pointer, bytes(result)
        if tile >= 0xE0:
            raise ValueError(f"player ID ${player_id:02X} uses an unsupported name command ${tile:02X}")
        result.append(tile)
    raise ValueError(f"player ID ${player_id:02X} name has no $FC terminator")


def profile_stat(
    player_id: int,
    stat_selector: int,
    level: int,
    low_profiles: bytes,
    profile_values: bytes,
    value_curve: bytes,
    profile_id: int | None = None,
) -> tuple[int, int, int]:
    if not 1 <= stat_selector <= 3:
        raise ValueError("the first action descriptor uses stat selectors 1–3")
    if profile_id is None:
        if not 1 <= player_id <= 0x22:
            raise ValueError("player IDs >= $23 require the caller's resolved stat_profile_id")
        profile_id = low_profiles[player_id * 4]
    if not 0 <= profile_id * 24 + stat_selector < len(profile_values):
        raise ValueError(f"stat profile ${profile_id:02X} is not present in extracted bytes")
    if level < 0:
        raise ValueError("player level is required")
    base_index = profile_values[profile_id * 24 + stat_selector]
    effective_index = min(0xBF, base_index + 2 * level)
    if effective_index >= len(value_curve):
        raise ValueError("stat curve index lies outside the verified 0x00–0xBF table")
    return profile_id, base_index, value_curve[effective_index]


def main() -> None:
    rom = ROM_PATH.read_bytes()
    actual_rom_sha = sha256(rom)
    require(actual_rom_sha == ROM_SHA256, f"target ROM SHA-256 mismatch: {actual_rom_sha}")

    tables = {
        "player_name_pointer_table_00_ef.bin": read(rom, fixed(0xF329), 0x1E0),
        "player_name_streams_f509_fd14.bin": read(rom, fixed(0xF509), 0x80C),
        "player_record_pointer_table_22.bin": read(rom, fixed(0xCD89), 22 * 2),
        "player_position_table_11.bin": read(rom, bank18(0x8D04), 22),
        "guest_player_name_tiles_11x4.bin": read(rom, bank18(0x8D40), 44),
        "player_stat_profile_map_00_22.bin": read(rom, bank1c(0x95D6), 35 * 4),
        "player_stat_profile_map_23_ef.bin": read(rom, bank1c(0x9662), 205 * 4),
        "player_stat_profiles_00_8c.bin": read(rom, bank1c(0x9FCE), 141 * 24),
        "player_stat_value_curve_00_bf.bin": read(rom, bank1c(0x9E4E), 0xC0),
    }

    pointers = tables["player_name_pointer_table_00_ef.bin"]
    strings = tables["player_name_streams_f509_fd14.bin"]
    low_profiles = tables["player_stat_profile_map_00_22.bin"]
    high_profiles = tables["player_stat_profile_map_23_ef.bin"]
    profile_values = tables["player_stat_profiles_00_8c.bin"]
    value_curve = tables["player_stat_value_curve_00_bf.bin"]
    position_table = tables["player_position_table_11.bin"]

    require(pointers[:2] == bytes.fromhex("eb 05"), "ID 0 pointer is no longer the RAM custom-name source")
    checked_name_ids: list[int] = []
    name_max_pointer = 0
    for player_id in range(1, 0xF0):
        pointer, tiles = resolve_name_tiles(player_id, pointers, strings)
        require(tiles, f"player ID ${player_id:02X} has an empty name")
        checked_name_ids.append(player_id)
        name_max_pointer = max(name_max_pointer, pointer + len(tiles) + 1)
    require(name_max_pointer <= 0xFD15, f"name stream end outside exported span: ${name_max_pointer:04X}")

    low_profile_ids = low_profiles[0::4]
    high_profile_ids = high_profiles[0::4]
    require(max(low_profile_ids) == 23, "low player profile table bound changed")
    require(max(high_profile_ids) == 140, "high player profile table bound changed")
    require(len(profile_values) == (max(high_profile_ids) + 1) * 24, "profile-table export bound mismatch")
    require(max(value_curve) <= 0xFF and len(value_curve) == 0xC0, "stat value curve size mismatch")

    for filename, data in tables.items():
        (OUT_DIR / filename).write_bytes(data)

    # The rest of this script uses the FCEUX capture only to check the ROM-only
    # resolver result. It never contributes to any exported byte resource.
    ram = RAM_CAPTURE.read_bytes()
    ppu = PPU_CAPTURE.read_bytes()
    require(len(ram) == 0x800 and len(ppu) == 0x4000, "unexpected validation capture size")
    observed_slot = ram[0x0441]
    # The fixed helper's pointer table is itself ROM data; validate index 6 to
    # record $0348 directly from the source bytes.
    record_pointer_table = tables["player_record_pointer_table_22.bin"]
    observed_record_pointer = int.from_bytes(record_pointer_table[observed_slot * 2 : observed_slot * 2 + 2], "little")
    record = ram[observed_record_pointer : observed_record_pointer + 4]
    observed_player_id = record[0]
    observed_level = record[3]
    observed_energy = record[1] | (record[2] << 8)

    require(observed_slot == 6 and observed_record_pointer == 0x0348, "capture player-slot tuple differs from documented endpoint")
    require(observed_player_id == 8, "capture record is not player ID 8")
    position_tiles = position_table[(observed_slot % 11) * 2 : (observed_slot % 11) * 2 + 2]
    name_pointer, name_tiles = resolve_name_tiles(observed_player_id, pointers, strings)
    padded_name = name_tiles + bytes(max(0, 5 - len(name_tiles)))
    player_line = bytes(position_tiles) + b"\x00" + padded_name

    # The panel has two blank text tiles before E1. Digits are right-aligned
    # backward from the next output column, as the ROM code does.
    def digits_to_tiles(value: int) -> bytes:
        return bytes(0x33 + int(char) for char in str(max(0, value)))

    energy_tiles = digits_to_tiles(observed_energy)
    profile_id, base_shot, shot = profile_stat(observed_player_id, 1, observed_level, low_profiles, profile_values, value_curve)
    _, base_pass, pass_value = profile_stat(observed_player_id, 2, observed_level, low_profiles, profile_values, value_curve)
    _, base_dribble, dribble = profile_stat(observed_player_id, 3, observed_level, low_profiles, profile_values, value_curve)

    # Capture layout addresses are checked only after the source reconstruction.
    ppu_player_line_address = 0x2232 + 1 * 0x20 + 2
    captured_player_line = ppu[ppu_player_line_address : ppu_player_line_address + len(player_line)]
    require(captured_player_line == player_line, f"E0 capture comparison mismatch at ${ppu_player_line_address:04X}")
    energy_start = 0x2232 + 3 * 0x20 + (1 + 8 - len(energy_tiles) + 1)
    captured_energy_tiles = ppu[energy_start : energy_start + len(energy_tiles)]
    require(captured_energy_tiles == energy_tiles, f"E1 energy capture comparison mismatch at ${energy_start:04X}")

    stat_capture_checks = []
    for row_progress, selector, value, base_index in [
        (9, 1, shot, base_shot),
        (7, 2, pass_value, base_pass),
        (5, 3, dribble, base_dribble),
    ]:
        output_column = 1 + 8 - len(str(value)) + 1
        address = 0x2232 + row_progress * 0x20 + output_column
        output_tiles = digits_to_tiles(value)
        captured = ppu[address : address + len(output_tiles)]
        require(captured == output_tiles, f"E1 selector {selector} capture comparison mismatch at ${address:04X}")
        stat_capture_checks.append(
            {
                "selector": selector,
                "source_base_index": base_index,
                "rom_value_at_captured_level": value,
                "captured_ppu_address": f"0x{address:04X}",
                "captured_tile_hex": captured.hex(" "),
                "matches": True,
            }
        )

    code_windows = [
        {"cpu_start": "0xF30F", "cpu_end_exclusive": "0xF329", "file_offset": f"0x{fixed(0xF30F):06X}", "sha256": sha256(read(rom, fixed(0xF30F), 0x1A))},
        {"cpu_start": "0x8000", "cpu_end_exclusive": "0x818E", "bank": "0x1C", "file_offset": f"0x{bank1c(0x8000):06X}", "sha256": sha256(read(rom, bank1c(0x8000), 0x18E))},
        {"cpu_start": "0xCD89", "cpu_end_exclusive": "0xCDB5", "file_offset": f"0x{fixed(0xCD89):06X}", "sha256": sha256(record_pointer_table)},
    ]
    report = {
        "schema": "first-action-menu-dynamic-source-audit-v1",
        "source_rom": {"name": ROM_PATH.name, "sha256": actual_rom_sha},
        "extractor": "python3 tools/gameplay/extract_first_action_menu_dynamic_tables.py",
        "rom_resources": {
            filename: {"size_bytes": len(data), "sha256": sha256(data)}
            for filename, data in tables.items()
        },
        "verified_code_windows": code_windows,
        "name_lookup": {
            "entry_point": {"cpu": "0xF30F", "file_offset": f"0x{fixed(0xF30F):06X}"},
            "pointer_table": {"cpu_start": "0xF329", "entries": 240, "last_entry_id": "0xEF", "entry_zero_bytes": pointers[:2].hex(" ")},
            "name_stream_bytes": {"cpu_start": "0xF509", "cpu_end_exclusive": "0xFD15", "all_nonzero_ids_terminate_with_fc": True},
            "position_table": {"cpu_start": "0x8D04", "entry_count": 11, "entry_for_slot_6_hex": position_tiles.hex(" ")},
            "known_id_8": {"pointer_table_entry_cpu": "0xF339", "pointer_bytes_hex": f"{name_pointer & 0xFF:02x} {name_pointer >> 8:02x}", "name_stream_cpu": f"0x{name_pointer:04X}", "name_tiles_hex": name_tiles.hex(" "), "padded_player_line_tiles_hex": player_line.hex(" ")},
            "zero_id_fallback": {"table_cpu": "0x8D40", "entries": 11, "tiles_per_entry": 4, "requires_guest_slot_11_to_21": True},
        },
        "stat_lookup": {
            "fixed_wrapper": {"cpu": "0xC527", "target": "0xCE08", "switches_prg_banks": ["0x1C", "0x1D"], "calls_bank_1c_8000": True},
            "evaluator": {"bank_cpu_entry": "0x8000", "internal_routine": "0x802D", "player_profile_helper": "0x803A", "stat_value_table_cpu": "0x9E4E", "profile_selector_table_low_cpu": "0x95D6", "profile_selector_table_high_cpu": "0x9662", "profile_values_base_cpu": "0x9FCE", "profile_record_size": 24, "level_increment": 2, "curve_index_clamp": "0xBF"},
            "energy_selector_0": "read current player record bytes +1/+2 as little-endian 16-bit energy; this is caller match state, not the ROM stat profile.",
            "known_id_8_level_0": {"player_id": 8, "profile_id": profile_id, "profile_record_cpu": "0xA05E", "profile_record_first_four_hex": profile_values[profile_id * 24 : profile_id * 24 + 4].hex(" "), "selector_values": {"1": shot, "2": pass_value, "3": dribble}, "value_curve_indices": {"1": base_shot, "2": base_pass, "3": base_dribble}, "uses_captured_level": observed_level},
            "capture_only_energy_validation": {"player_record_energy_bytes": record[1:3].hex(" "), "observed_energy": observed_energy, "emitted_tile_ids_hex": energy_tiles.hex(" ")},
            "capture_only_stat_validations": stat_capture_checks,
        },
        "validation_only": {
            "ram_capture": str(RAM_CAPTURE.relative_to(ROOT)),
            "ppu_capture": str(PPU_CAPTURE.relative_to(ROOT)),
            "observed_slot_index": observed_slot,
            "observed_player_id": observed_player_id,
            "observed_level": observed_level,
            "e0_ppu_line_address": f"0x{ppu_player_line_address:04X}",
            "e0_capture_match": captured_player_line == player_line,
            "e1_energy_address": f"0x{energy_start:04X}",
            "e1_energy_capture_match": captured_energy_tiles == energy_tiles,
        },
        "runtime_limits": [
            "The runtime receives slot index, player ID, level, and current energy from the match model; no captured value is embedded.",
            "For player IDs $01–$22, the normal profile ID comes from the ROM low profile map. IDs $23–$EF require the caller to provide the effective profile ID selected by the ROM's record-flag/alternate-ID path.",
            "Slots 0, 11, 30, and 31 use a special bank-$1C stat branch not handled by the regular profile formula. The first observed slot is 6.",
            "Player ID 0 is supported for the E0 fallback name only when the slot is 11–21; it requires the ROM's guest-name record. IDs above $EF and custom ID-0 home-player names require explicit caller override tiles.",
            "Energy selector 0 is always supplied from current match state. The ROM name and stat table exports do not establish an energy value independent of the live record.",
        ],
    }

    out_path = OUT_DIR / "dynamic_player_source_audit.json"
    out_path.write_text(json.dumps(report, indent=2) + "\n")
    print("Dynamic menu source tables extracted from the target ROM.")
    print(f"ROM-only player-8 E0 candidate: {player_line.hex(' ')}")
    print(f"ROM-only player-8 stats at captured level {observed_level}: selector 1={shot}, 2={pass_value}, 3={dribble}")
    print("Frame-8953 E0/name, energy, and stat tile comparisons: PASS (validation only)")
    print(f"Report: {out_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
