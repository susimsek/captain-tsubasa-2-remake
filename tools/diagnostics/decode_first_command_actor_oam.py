#!/usr/bin/env python3
"""Decode the first command-screen actor OAM from ROM sprite streams.

This is a diagnostic/research tool. The ROM actor records and OAM shadow are
read only as an endpoint validation fixture; neither is emitted as a runtime
asset. Sprite stream bytes, pointer tables, X/Y offset tables, and CHR banks are
read directly from the target ROM and checked against its whole-file hash.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
CAPTURE_DIR = ROOT / "reference/diagnostics/first_command_actor_oam_20261027_113609_utc"
TRACE_PATH = CAPTURE_DIR / "actor_draw_calls.csv"
RAM_PATH = CAPTURE_DIR / "cpu_ram_0000_07ff_frame_008953.bin"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK16_FILE_BASE = 0x02C010  # Bank $16 CPU $8000 maps here in the supplied ROM.
EXPECTED_ENGINE_WINDOW_SHA256 = "4c8913c90c578a7924f74b8a94b91ff5ac4b059c7c9e7304d3f48a7ae67f9894"
EXPECTED_Y_TABLE_SHA256 = "f8a1414565cd2b3ed41010e50a0aff4f4c632d8fb3a1454ff69e6eb1aa050621"
EXPECTED_X_TABLE_SHA256 = "73dab8cd8ab93df730bbc67c98531236ba89a73ad53e1b374379db55821be2c2"
EXPECTED_DESCRIPTOR_POINTER_TABLE_SHA256 = "307422f39c84f3bb3f12cd84879091d437582c0ed0d6d41adb2555c808ee6564"
OAM_BASE = 0x0200
EXPECTED_ACTORS = {
    "$0547": {"descriptor": 0x00, "first_pointer": 0x842C, "selected_pointer": 0x84DF, "count": 6},
    "$055C": {"descriptor": 0x04, "first_pointer": 0x87D9, "selected_pointer": 0x87F2, "count": 13},
    "$0586": {"descriptor": 0x0A, "first_pointer": 0x896B, "selected_pointer": 0x896B, "count": 22},
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_bank16(rom: bytes, address: int, count: int) -> bytes:
    if not 0x8000 <= address < 0xA000:
        raise ValueError(f"bank-$16 address out of range: ${address:04X}")
    offset = BANK16_FILE_BASE + address - 0x8000
    data = rom[offset : offset + count]
    if len(data) != count:
        raise ValueError(f"truncated ROM read at ${address:04X}")
    return data


def read_u16(rom: bytes, address: int) -> int:
    return int.from_bytes(read_bank16(rom, address, 2), "little")


def signed8(value: int) -> int:
    return value - 0x100 if value & 0x80 else value


def decode_stream(rom: bytes, root: int, selector: int) -> tuple[list[dict], list[dict]]:
    """Return compact stream events and per-sprite source records."""
    pointer = root
    cursor = 0
    events: list[dict] = []
    sprites: list[dict] = []
    visited: set[tuple[int, int]] = set()
    steps = 0
    y_offsets = read_bank16(rom, 0x81D2, 0x28)
    x_offsets = read_bank16(rom, 0x81FA, 0x40)

    while steps < 4096:
        steps += 1
        key = (pointer, cursor)
        if key in visited:
            raise ValueError(f"stream loop at ${pointer:04X}+${cursor:02X}")
        visited.add(key)
        control = read_bank16(rom, pointer + cursor, 1)[0]
        opcode = control & 0x07
        if opcode == 1:
            events.append({"kind": "end", "pointer": f"0x{pointer:04X}", "offset": cursor, "byte": control})
            break
        if opcode == 2:
            target = int.from_bytes(read_bank16(rom, pointer + cursor + 1, 2), "little")
            events.append({"kind": "jump", "pointer": f"0x{pointer:04X}", "offset": cursor, "target": f"0x{target:04X}"})
            pointer, cursor = target, 0
            continue
        if opcode == 3:
            normalized = selector - 0x0C if selector >= 0x0C else selector
            table_offset = cursor + 1 + normalized * 2
            target = int.from_bytes(read_bank16(rom, pointer + table_offset, 2), "little")
            events.append({
                "kind": "selector_branch",
                "pointer": f"0x{pointer:04X}",
                "offset": cursor,
                "selector": selector,
                "normalized_selector": normalized,
                "target": f"0x{target:04X}",
            })
            pointer, cursor = target, 0
            continue
        if opcode != 0:
            raise ValueError(f"unsupported control ${control:02X} at ${pointer + cursor:04X}")

        count_minus_one = (control & 0x38) >> 3
        count = count_minus_one + 1
        y_index = read_bank16(rom, pointer + cursor + 1, 1)[0]
        if y_index >= len(y_offsets):
            raise ValueError(f"Y table index ${y_index:02X} out of range at ${pointer + cursor:04X}")
        cursor += 2
        event = {
            "kind": "sprite_run",
            "pointer": f"0x{pointer:04X}",
            "offset": cursor - 2,
            "control": f"0x{control:02X}",
            "count": count,
            "y_offset_index": y_index,
            "y_offset_byte": f"0x{y_offsets[y_index]:02X}",
        }
        events.append(event)
        for entry_index in range(count):
            x_attribute_code = read_bank16(rom, pointer + cursor, 1)[0]
            tile = read_bank16(rom, pointer + cursor + 1, 1)[0]
            x_index = x_attribute_code >> 2
            if x_index >= len(x_offsets):
                raise ValueError(f"X table index ${x_index:02X} out of range")
            sprites.append({
                "stream_pointer": f"0x{pointer:04X}",
                "stream_offset": cursor,
                "x_attribute_code": x_attribute_code,
                "x_offset_index": x_index,
                "x_offset_byte": x_offsets[x_index],
                "attribute_low": x_attribute_code & 0x03,
                "tile": tile,
                "run_index": len(events) - 1,
                "run_entry_index": entry_index,
            })
            cursor += 2
    else:
        raise ValueError("stream exceeded 4096 parser steps")

    if not events or events[-1]["kind"] != "end":
        raise ValueError(f"stream ${root:04X} did not terminate with opcode 1")
    return events, sprites


def actor_row_by_address() -> dict[str, dict]:
    with TRACE_PATH.open(newline="", encoding="utf-8") as source:
        rows = [row for row in csv.DictReader(source) if int(row["source_frame"]) == 8953]
    return {row["actor_record"]: row for row in rows}


def model_actor(rom: bytes, ram: bytes, actor_row: dict, expected: dict, oam: bytes) -> dict:
    actor = bytes.fromhex(actor_row["actor_record_21_bytes"])
    if len(actor) != 21:
        raise ValueError("actor record length is not 21 bytes")
    record = actor_row["actor_record"]
    descriptor = int(actor_row["descriptor"].replace("$", ""), 16)
    selector = int(actor_row["graphic_selector_0546"].replace("$", ""), 16)
    pointer_entry = 0x8280 + descriptor * 2
    pointer = read_u16(rom, pointer_entry)
    if pointer != expected["first_pointer"]:
        raise ValueError(f"{record} descriptor ${descriptor:02X} pointer ${pointer:04X} != expected")
    events, source_sprites = decode_stream(rom, pointer, selector)
    if not events or events[0]["kind"] != "selector_branch":
        selected_pointer = pointer
    else:
        selected_pointer = int(events[0]["target"], 16)
    if selected_pointer != expected["selected_pointer"]:
        raise ValueError(f"{record} selector branch chose ${selected_pointer:04X}")

    flag = actor[0]
    mirror_mode = ram[0x0517]
    sprite_flip = ((flag & 0x60) << 1) ^ mirror_mode
    # This follows $8000-$8064: signed coordinate origin, scroll, whole-field
    # horizontal reflection, then the sprite-frame's 8-pixel origin correction.
    x_origin = (((flag & 1) << 8) | actor[8]) - 0x80
    x_origin -= ram[0x0538]
    if mirror_mode & 0x40:
        x_origin = 0x100 - x_origin
    x_origin &= 0xFFFF
    if sprite_flip & 0x40:
        x_origin = (x_origin - 8) & 0xFFFF
    movement_x = signed8(actor[0x13])
    if (flag ^ mirror_mode) & 0x40:
        movement_x = -movement_x
    x_origin = (x_origin + movement_x) & 0xFFFF

    y_subtract = 0x88 if sprite_flip & 0x80 else 0x80
    y_origin = (((flag >> 1) & 1) << 8) + actor[12] - y_subtract
    y_origin = (y_origin + signed8(actor[0x14])) & 0xFFFF
    y_min, y_max = ram[0x0540], ram[0x0541]
    oam_index = int(actor_row["oam_index_before"])
    generated = []
    compare_records = []

    for source in source_sprites:
        run = events[source["run_index"]]
        raw_y_offset = int(run["y_offset_byte"], 16)
        y_offset = signed8(raw_y_offset)
        if sprite_flip & 0x80:
            y_offset = -y_offset
        y16 = (y_origin + y_offset) & 0xFFFF
        clipped_y = bool((y16 >> 8) != 0 or (y16 & 0xFF) < y_min or (y16 & 0xFF) >= y_max)

        raw_x_offset = signed8(source["x_offset_byte"])
        x_offset = -raw_x_offset if sprite_flip & 0x40 else raw_x_offset
        x16 = (x_origin + x_offset) & 0xFFFF
        clipped_x = (x16 >> 8) != 0
        slot = oam_index // 4
        if clipped_y or clipped_x:
            actual_y = 0xF8 if clipped_y else 0xF8
            tuple_bytes = [actual_y, source["tile"], source["attribute_low"] | sprite_flip, x16 & 0xFF]
            expected_tuple = list(oam[slot * 4 : slot * 4 + 4])
            generated.append({"slot": slot, "hidden": True, "tuple": tuple_bytes})
            compare_records.append({"slot": slot, "matches": expected_tuple[0] == 0xF8, "expected": expected_tuple, "generated": tuple_bytes})
        else:
            tuple_bytes = [y16 & 0xFF, source["tile"], source["attribute_low"] | sprite_flip, x16 & 0xFF]
            expected_tuple = list(oam[slot * 4 : slot * 4 + 4])
            generated.append({
                "slot": slot,
                "hidden": False,
                "stream_pointer": source["stream_pointer"],
                "stream_offset": f"0x{source['stream_offset']:02X}",
                "tuple": [f"0x{value:02X}" for value in tuple_bytes],
            })
            compare_records.append({"slot": slot, "matches": expected_tuple == tuple_bytes, "expected": expected_tuple, "generated": tuple_bytes})
        oam_index += 4

    expected_after = int(actor_row["oam_index_after"])
    if oam_index != expected_after:
        raise ValueError(f"{record} generated OAM end ${oam_index:02X}, trace ends ${expected_after:02X}")
    if len(generated) != expected["count"]:
        raise ValueError(f"{record} decoded {len(generated)} sprites, expected {expected['count']}")

    return {
        "actor_record": record,
        "descriptor": f"0x{descriptor:02X}",
        "descriptor_table_address": f"0x{pointer_entry:04X}",
        "stream_root": f"0x{pointer:04X}",
        "selector_0546": selector,
        "selected_stream": f"0x{selected_pointer:04X}",
        "actor_record_hex": actor.hex(" ").upper(),
        "sprite_flip_flags": f"0x{sprite_flip:02X}",
        "base_x": f"0x{x_origin:04X}",
        "base_y": f"0x{y_origin:04X}",
        "streams": events,
        "generated_oam": generated,
        "validation": {
            "expected_oam_start": int(actor_row["oam_index_before"]) // 4,
            "expected_oam_end_exclusive": expected_after // 4,
            "decoded_sprite_count": len(generated),
            "all_source_oam_slots_match": all(entry["matches"] for entry in compare_records),
            "matched_slots": sum(entry["matches"] for entry in compare_records),
            "slot_count": len(compare_records),
            "slot_comparisons": compare_records,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "reference/diagnostics/first_command_actor_oam_20261027_113609_utc/rom_generated_oam_decode.json")
    args = parser.parse_args()
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("Target ROM SHA-256 mismatch.")
    ram = RAM_PATH.read_bytes()
    if len(ram) != 0x800:
        raise SystemExit("Endpoint CPU RAM fixture must contain 0x800 bytes.")
    actor_rows = actor_row_by_address()
    oam = ram[OAM_BASE:OAM_BASE + 0x100]

    # Validate the target ROM's static sprite-engine lookup and offset tables.
    descriptor_ptrs = {
        f"0x{descriptor:02X}": f"0x{read_u16(rom, 0x8280 + descriptor * 2):04X}"
        for descriptor in (0x00, 0x04, 0x0A)
    }
    table_y = read_bank16(rom, 0x81D2, 0x28)
    table_x = read_bank16(rom, 0x81FA, 0x40)
    engine_window = read_bank16(rom, 0x8000, 0x186)
    pointer_table = read_bank16(rom, 0x8280, 0x30)
    if sha256(engine_window) != EXPECTED_ENGINE_WINDOW_SHA256:
        raise SystemExit("Target ROM sprite-engine instruction/data window differs from the checked source.")
    if sha256(table_y) != EXPECTED_Y_TABLE_SHA256 or sha256(table_x) != EXPECTED_X_TABLE_SHA256:
        raise SystemExit("Target ROM sprite X/Y offset tables differ from the checked source.")
    if sha256(pointer_table) != EXPECTED_DESCRIPTOR_POINTER_TABLE_SHA256:
        raise SystemExit("Target ROM sprite descriptor pointer table differs from the checked source.")
    if descriptor_ptrs != {"0x00": "0x842C", "0x04": "0x87D9", "0x0A": "0x896B"}:
        raise SystemExit(f"Target ROM descriptor pointers differ: {descriptor_ptrs}")
    decoded = []
    for actor, expected in EXPECTED_ACTORS.items():
        row = actor_rows.get(actor)
        if row is None:
            raise SystemExit(f"Missing frame-8953 actor draw call {actor}")
        decoded.append(model_actor(rom, ram, row, expected, oam))

    output = {
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "target_frame": 8953,
        "mode": "ROM stream decoder; endpoint CPU RAM and OAM used only as validation inputs",
        "descriptor_pointer_table": f"0x{descriptor_ptrs['0x00']} / 0x{descriptor_ptrs['0x04']} / 0x{descriptor_ptrs['0x0A']}",
        "rom_byte_checks": {
            "bank16_sprite_engine_8000_8185_sha256": EXPECTED_ENGINE_WINDOW_SHA256,
            "bank16_sprite_descriptor_table_8280_82AF_sha256": EXPECTED_DESCRIPTOR_POINTER_TABLE_SHA256,
            "bank16_y_offset_table_81D2_81F9_sha256": EXPECTED_Y_TABLE_SHA256,
            "bank16_x_offset_table_81FA_8239_sha256": EXPECTED_X_TABLE_SHA256,
        },
        "x_offset_table_sha256": sha256(table_x),
        "y_offset_table_sha256": sha256(table_y),
        "actors": decoded,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    total = sum(actor["validation"]["slot_count"] for actor in decoded)
    matches = sum(actor["validation"]["matched_slots"] for actor in decoded)
    print(f"Decoded {len(decoded)} actors / {total} sprites from ROM descriptor streams.")
    print(f"Source OAM tuple comparison: {matches}/{total} slots matched; report: {args.output.relative_to(ROOT)}")
    if matches != total:
        for actor in decoded:
            validation = actor["validation"]
            if not validation["all_source_oam_slots_match"]:
                mismatches = [entry for entry in validation["slot_comparisons"] if not entry["matches"]]
                print(f"{actor['actor_record']} mismatches: {mismatches[:8]}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
