#!/usr/bin/env python3
"""Preserve bank-$10 scenario source streams for the fresh KICK OFF route."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_scenarios"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

SCENARIO_POINTER_TABLE_FILE_OFFSET = 0x0209CF
SCENARIO_POINTER_TABLE_CPU_ADDRESS = 0x89BF
SCENARIO_BANK = 0x10
SCENARIO_CPU_WINDOW_START = 0x8000
SCENARIO_CPU_WINDOW_END = 0xC000
SCENARIO_FILE_WINDOW_BASE = 0x020010
SCENARIO_POINTER_ENTRY_WIDTH = 2

# Ordinals are zero-based among the known four-byte scenario records in each
# selected pointer-bounded stream. Byte offsets are retained independently;
# no frame timing or runtime semantics are inferred here.
EVENT_RECORDS = {
    0x1E: [
        (0, 5, bytes.fromhex("07 45 90 F0")),
    ],
    0x35: [
        (0, 3, bytes.fromhex("02 3A 8F 73")),
    ],
    0x36: [
        (0, 4, bytes.fromhex("10 3A 8F F0")),
        (1, 11, bytes.fromhex("20 0C 4E 74")),
        (2, 20, bytes.fromhex("32 72 66 F0")),
        (3, 26, bytes.fromhex("32 1F 4C F0")),
        (4, 33, bytes.fromhex("3E 01 E6 75")),
    ],
    0x44: [
        (0, 0, bytes.fromhex("02 70 5C F0")),
    ],
}

# Preserve each selected root entry and the pointer-table entry that provides
# its exclusive end boundary. The target table is not ordered by pointer value.
POINTER_ENTRY_IDS = (0x1E, 0x35, 0x36, 0x44, 0x15)

# Fixed-bank caller bytes at CPU $E233 establish the scenario-$1E root.
ENTRY_ROOTS = {
    "scenario_1E": {
        "cpu_address": 0xE233,
        "file_offset": 0x03E243,
        "expected_bytes": bytes.fromhex("A9 1E 20 B0 CB"),
        "scenario_id": 0x1E,
        "description": "Immediate scenario ID $1E followed by JSR $CBB0.",
    },
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_u16(data: bytes, offset: int) -> int:
    return data[offset] | (data[offset + 1] << 8)


def pointer_entry_offset(scenario_id: int) -> int:
    return SCENARIO_POINTER_TABLE_FILE_OFFSET + scenario_id * SCENARIO_POINTER_ENTRY_WIDTH


def file_offset_for_cpu(cpu_address: int) -> int:
    return SCENARIO_FILE_WINDOW_BASE + cpu_address - SCENARIO_CPU_WINDOW_START


def load_scenario_pointers(rom: bytes) -> list[tuple[int, int]]:
    pointers: list[tuple[int, int]] = []
    for scenario_id in range(0x100):
        offset = pointer_entry_offset(scenario_id)
        pointer = read_u16(rom, offset)
        if SCENARIO_CPU_WINDOW_START <= pointer < SCENARIO_CPU_WINDOW_END:
            pointers.append((pointer, scenario_id))
    return pointers


def entry_metadata(rom: bytes, scenario_id: int) -> dict:
    offset = pointer_entry_offset(scenario_id)
    raw = rom[offset:offset + SCENARIO_POINTER_ENTRY_WIDTH]
    if len(raw) != SCENARIO_POINTER_ENTRY_WIDTH:
        raise SystemExit(f"Scenario ${scenario_id:02X} pointer entry is truncated")
    pointer = read_u16(rom, offset)
    filename = f"scenario_pointer_{scenario_id:02X}.bin"
    (OUTPUT_DIR / filename).write_bytes(raw)
    return {
        "scenario_id": f"${scenario_id:02X}",
        "path": f"reference/rom_extract/gameplay/first_command_scenarios/{filename}",
        "cpu_address": f"0x{pointer:04X}",
        "table_cpu_address": f"0x{SCENARIO_POINTER_TABLE_CPU_ADDRESS:04X}",
        "table_file_offset": f"0x{offset:06X}",
        "length_bytes": len(raw),
        "bytes_hex": raw.hex(" ").upper(),
        "sha256": sha256(raw),
    }


def extract_scenarios(rom: bytes) -> tuple[list[dict], list[dict], list[dict]]:
    pointers = load_scenario_pointers(rom)
    route_ids = (0x1E, 0x35, 0x36, 0x44)
    scenario_entries: list[dict] = []
    boundaries: dict[int, int] = {}

    for scenario_id in route_ids:
        pointer = read_u16(rom, pointer_entry_offset(scenario_id))
        greater_pointers = [candidate for candidate, _ in pointers if candidate > pointer]
        if not greater_pointers:
            raise SystemExit(f"Scenario ${scenario_id:02X} has no following pointer boundary")
        end_pointer = min(greater_pointers)
        boundary_ids = [sid for candidate, sid in pointers if candidate == end_pointer]
        if len(boundary_ids) != 1:
            raise SystemExit(
                f"Scenario ${scenario_id:02X} boundary ${end_pointer:04X} has ambiguous table roots"
            )
        boundary_id = boundary_ids[0]
        boundaries[scenario_id] = boundary_id
        start_offset = file_offset_for_cpu(pointer)
        end_offset = file_offset_for_cpu(end_pointer)
        raw = rom[start_offset:end_offset]
        if not raw:
            raise SystemExit(f"Scenario ${scenario_id:02X} pointer span is empty")

        event_records = []
        for ordinal, byte_offset, expected in EVENT_RECORDS[scenario_id]:
            actual = raw[byte_offset:byte_offset + 4]
            if actual != expected:
                raise SystemExit(
                    f"Scenario ${scenario_id:02X} event record {ordinal} mismatch at +0x{byte_offset:X}: "
                    f"expected {expected.hex(' ').upper()}, got {actual.hex(' ').upper()}"
                )
            event_records.append({
                "record_index_zero_based": ordinal,
                "stream_byte_offset": f"0x{byte_offset:04X}",
                "file_offset": f"0x{start_offset + byte_offset:06X}",
                "bytes_hex": actual.hex(" ").upper(),
            })

        filename = f"scenario_{scenario_id:02X}.bin"
        (OUTPUT_DIR / filename).write_bytes(raw)
        scenario_entries.append({
            "scenario_id": f"${scenario_id:02X}",
            "path": f"reference/rom_extract/gameplay/first_command_scenarios/{filename}",
            "prg_bank": f"${SCENARIO_BANK:02X}",
            "start_pointer_entry_id": f"${scenario_id:02X}",
            "start_cpu_address": f"0x{pointer:04X}",
            "end_boundary_pointer_entry_id": f"${boundary_id:02X}",
            "end_cpu_address_exclusive": f"0x{end_pointer:04X}",
            "file_offset": f"0x{start_offset:06X}",
            "end_file_offset_exclusive": f"0x{end_offset:06X}",
            "length_bytes": len(raw),
            "sha256": sha256(raw),
            "source_span_method": "scenario pointer root through the smallest greater valid pointer in the same 256-entry table, exclusive",
            "event_record_index_basis": "Zero-based ordinal among the documented four-byte records in this stream; byte offsets and bytes are separately recorded. No timing or runtime semantics are implied.",
            "event_records": event_records,
        })

    pointer_entries = [entry_metadata(rom, sid) for sid in POINTER_ENTRY_IDS]
    entry_roots = []
    for name, root in ENTRY_ROOTS.items():
        start = root["file_offset"]
        raw = rom[start:start + len(root["expected_bytes"])]
        if raw != root["expected_bytes"]:
            raise SystemExit(f"Entry-root bytes changed at file offset 0x{start:06X}")
        filename = f"entry_root_{name}.bin"
        (OUTPUT_DIR / filename).write_bytes(raw)
        entry_roots.append({
            "name": name,
            "path": f"reference/rom_extract/gameplay/first_command_scenarios/{filename}",
            "prg_bank_listing": "$FF",
            "cpu_address": f"0x{root['cpu_address']:04X}",
            "file_offset": f"0x{start:06X}",
            "scenario_id": f"${root['scenario_id']:02X}",
            "length_bytes": len(raw),
            "bytes_hex": raw.hex(" ").upper(),
            "sha256": sha256(raw),
            "description": root["description"],
        })

    return scenario_entries, pointer_entries, entry_roots


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = sha256(rom)
    if rom_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Target ROM SHA-256 mismatch: {rom_hash}")
    if len(rom) != 393232:
        raise SystemExit(f"Unexpected target ROM size: {len(rom)}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    scenarios, pointer_entries, entry_roots = extract_scenarios(rom)
    manifest = {
        "schema": "first-command-bank10-scenario-sources-v1",
        "source_rom_filename": ROM_PATH.name,
        "source_rom_sha256": rom_hash,
        "source_rom_size_bytes": len(rom),
        "runtime_rom_dependency": False,
        "capture_or_screenshot_bytes_included": False,
        "scenario_pointer_table": {
            "cpu_address": f"0x{SCENARIO_POINTER_TABLE_CPU_ADDRESS:04X}",
            "file_offset": f"0x{SCENARIO_POINTER_TABLE_FILE_OFFSET:06X}",
            "prg_bank": f"${SCENARIO_BANK:02X}",
            "cpu_window": f"0x{SCENARIO_CPU_WINDOW_START:04X}-0x{SCENARIO_CPU_WINDOW_END - 1:04X}",
            "file_window_base": f"0x{SCENARIO_FILE_WINDOW_BASE:06X}",
            "entry_width_bytes": SCENARIO_POINTER_ENTRY_WIDTH,
            "entry_count_scanned": 256,
            "span_boundary_rule": "Pointer values are not monotonic by scenario ID. Each selected stream ends at the smallest greater valid CPU pointer among all table entries; end is exclusive.",
            "preserved_entry_ids": [f"${sid:02X}" for sid in POINTER_ENTRY_IDS],
        },
        "scenario_streams": scenarios,
        "pointer_table_entries": pointer_entries,
        "entry_roots": entry_roots,
        "format_notes": [
            "The extracted scenario bytes are preserved without interpretation or rewriting.",
            "The listed event-record anchors are source byte indexes only; they do not encode frame timing or establish runtime semantics.",
            "Scenario $1E is rooted by the byte sequence A9 1E 20 B0 CB at fixed-bank CPU $E233 / file 0x03E243.",
        ],
    }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(scenarios)} scenario streams, {len(pointer_entries)} pointer entries, and {len(entry_roots)} entry roots under {OUTPUT_DIR.relative_to(ROOT)}")
    for entry in scenarios:
        print(f"scenario_{entry['scenario_id'][1:]}.bin: {entry['length_bytes']} bytes sha256 {entry['sha256']}")


if __name__ == "__main__":
    main()
