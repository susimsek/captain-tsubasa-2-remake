#!/usr/bin/env python3
"""Extract the source-pinned bank-$10 scenario-$2E stream into its own package."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/scenario_2e"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
POINTER_PATH = OUTPUT_DIR / "scenario_pointer_2E.bin"
STREAM_PATH = OUTPUT_DIR / "scenario_2E.bin"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROM_SIZE = 393232
EXPECTED_ROM_MAGIC = b"NES\x1a"
SCENARIO_ID = 0x2E
POINTER_TABLE_CPU = 0x89BF
POINTER_TABLE_FILE_OFFSET = 0x0209CF
POINTER_ENTRY_FILE_OFFSET = 0x020A2B
CPU_WINDOW_START = 0x8000
CPU_WINDOW_END = 0xC000
FILE_WINDOW_BASE = 0x020010
EXPECTED_POINTER = 0xB74E
EXPECTED_BOUNDARY = 0xB754
EXPECTED_BOUNDARY_IDS = (0x3F,)
EXPECTED_POINTER_BYTES = bytes.fromhex("4E B7")
EXPECTED_STREAM_FILE_OFFSET = 0x02375E
EXPECTED_STREAM = bytes.fromhex("F5 78 36 8B 6D FB")


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def pointer_entry_offset(scenario_id: int) -> int:
	return POINTER_TABLE_FILE_OFFSET + scenario_id * 2


def read_pointer(rom: bytes, scenario_id: int) -> int:
	offset = pointer_entry_offset(scenario_id)
	return int.from_bytes(rom[offset:offset + 2], "little")


def cpu_window_file_offset(cpu_address: int) -> int:
	if not CPU_WINDOW_START <= cpu_address < CPU_WINDOW_END:
		raise ValueError(f"CPU address ${cpu_address:04X} is outside bank-$10's window")
	return FILE_WINDOW_BASE + cpu_address - CPU_WINDOW_START


def main() -> None:
	if not ROM_PATH.is_file():
		raise SystemExit(f"Supplied ROM is missing: {ROM_PATH}")
	rom = ROM_PATH.read_bytes()
	rom_hash = sha256(rom)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
	if len(rom) != EXPECTED_ROM_SIZE or rom[:4] != EXPECTED_ROM_MAGIC:
		raise SystemExit("Unexpected iNES header or ROM size")
	if pointer_entry_offset(SCENARIO_ID) != POINTER_ENTRY_FILE_OFFSET \
			or POINTER_TABLE_CPU != 0x89BF or read_pointer(rom, SCENARIO_ID) != EXPECTED_POINTER:
		raise SystemExit("Scenario-$2E pointer-table mapping or value changed")
	pointer_bytes = rom[POINTER_ENTRY_FILE_OFFSET:POINTER_ENTRY_FILE_OFFSET + 2]
	if pointer_bytes != EXPECTED_POINTER_BYTES:
		raise SystemExit("Scenario-$2E pointer bytes changed")
	pointers = [(read_pointer(rom, scenario_id), scenario_id) for scenario_id in range(0x100)]
	valid_pointers = [row for row in pointers if CPU_WINDOW_START <= row[0] < CPU_WINDOW_END]
	greater = [row for row in valid_pointers if row[0] > EXPECTED_POINTER]
	if not greater:
		raise SystemExit("Scenario-$2E has no greater pointer-table boundary")
	boundary = min(pointer for pointer, _ in greater)
	boundary_ids = tuple(scenario_id for pointer, scenario_id in valid_pointers if pointer == boundary)
	if boundary != EXPECTED_BOUNDARY or boundary_ids != EXPECTED_BOUNDARY_IDS:
		raise SystemExit(f"Scenario-$2E boundary changed: ${boundary:04X} / {boundary_ids}")
	start_offset = cpu_window_file_offset(EXPECTED_POINTER)
	end_offset = cpu_window_file_offset(boundary)
	stream = rom[start_offset:end_offset]
	if start_offset != EXPECTED_STREAM_FILE_OFFSET or stream != EXPECTED_STREAM:
		raise SystemExit("Scenario-$2E source span changed")

	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	POINTER_PATH.write_bytes(pointer_bytes)
	STREAM_PATH.write_bytes(stream)
	manifest = {
		"schema": "ct2-bank10-scenario-2e-source-v1",
		"source_rom_filename": ROM_PATH.name,
		"source_rom_sha256": rom_hash,
		"source_rom_size_bytes": len(rom),
		"runtime_rom_dependency": False,
		"capture_or_screenshot_bytes_included": False,
		"scenario": {
			"scenario_id": "$2E",
			"prg_bank": "$10",
			"pointer_table_cpu_address": f"0x{POINTER_TABLE_CPU:04X}",
			"pointer_table_file_offset": f"0x{POINTER_TABLE_FILE_OFFSET:06X}",
			"pointer_entry_file_offset": f"0x{POINTER_ENTRY_FILE_OFFSET:06X}",
			"pointer_entry_path": f"reference/rom_extract/gameplay/{OUTPUT_DIR.name}/{POINTER_PATH.name}",
			"pointer_entry_bytes_hex": pointer_bytes.hex(" ").upper(),
			"pointer_entry_sha256": sha256(pointer_bytes),
			"start_cpu_address": f"0x{EXPECTED_POINTER:04X}",
			"end_boundary_pointer_entry_ids": [f"${sid:02X}" for sid in boundary_ids],
			"end_cpu_address_exclusive": f"0x{boundary:04X}",
			"stream_file_offset": f"0x{start_offset:06X}",
			"stream_end_file_offset_exclusive": f"0x{end_offset:06X}",
			"stream_path": f"reference/rom_extract/gameplay/{OUTPUT_DIR.name}/{STREAM_PATH.name}",
			"length_bytes": len(stream),
			"stream_sha256": sha256(stream),
			"stream_bytes_hex": stream.hex(" ").upper(),
			"span_boundary_method": "smallest greater valid CPU pointer among all 256 bank-$10 table entries, exclusive",
			"decoded_scope": {
				"f5_effect": "The existing ROM-backed reader maps $F5 to the $87E6 routine, which writes zero to RAM $052A.",
				"record_bytes_hex": stream[1:5].hex(" ").upper(),
				"record_note": "The four source bytes are retained as a record; scenario-specific callback meaning and worker behavior are not claimed here.",
				"terminator": "The final $FB is the pointer-span root terminator.",
			},
		},
	}
	MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	print(
		f"Extracted scenario $2E: pointer @ 0x{POINTER_ENTRY_FILE_OFFSET:06X} "
		f"({pointer_bytes.hex(' ').upper()}), stream @ 0x{start_offset:06X} "
		f"({stream.hex(' ').upper()}), sha256 {sha256(stream)}"
	)


if __name__ == "__main__":
	main()
