#!/usr/bin/env python3
"""Extract the ROM-owned bank-$10 scenario-$38 root stream."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_scenarios"
SCENARIO_PATH = OUTPUT_DIR / "scenario_38.bin"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROM_SIZE = 393232
EXPECTED_ROM_MAGIC = b"NES\x1a"

SCENARIO_POINTER_TABLE_CPU = 0x89BF
SCENARIO_POINTER_TABLE_FILE_OFFSET = 0x0209CF
SCENARIO_FILE_WINDOW_BASE = 0x020010
SCENARIO_CPU_WINDOW_START = 0x8000
SCENARIO_CPU_WINDOW_END = 0xC000
SCENARIO_ID = 0x38
EXPECTED_POINTER_ENTRY_FILE_OFFSET = 0x020A3F
EXPECTED_POINTER_BYTES = bytes.fromhex("C6 B7")
EXPECTED_START_CPU = 0xB7C6
EXPECTED_BOUNDARY_CPU = 0xB7CD
EXPECTED_BOUNDARY_IDS = (0x35,)
EXPECTED_STREAM_FILE_OFFSET = 0x0237D6
EXPECTED_STREAM = bytes.fromhex("F7 17 01 34 00 F0 FB")
EXPECTED_ROOT_RECORD = bytes.fromhex("F7 17 01 34 00")
EXPECTED_CALLBACK_ID = 0x34


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def pointer_entry_offset(scenario_id: int) -> int:
	return SCENARIO_POINTER_TABLE_FILE_OFFSET + scenario_id * 2


def read_pointer(rom: bytes, scenario_id: int) -> tuple[int, bytes, int]:
	offset = pointer_entry_offset(scenario_id)
	raw = rom[offset : offset + 2]
	if len(raw) != 2:
		raise ValueError(f"Scenario ${scenario_id:02X} pointer entry is truncated")
	return int.from_bytes(raw, "little"), raw, offset


def file_offset_for_cpu(cpu_address: int) -> int:
	if not SCENARIO_CPU_WINDOW_START <= cpu_address < SCENARIO_CPU_WINDOW_END:
		raise ValueError(f"CPU address ${cpu_address:04X} is outside bank-$10's window")
	return SCENARIO_FILE_WINDOW_BASE + cpu_address - SCENARIO_CPU_WINDOW_START


def find_next_pointer_boundary(rom: bytes, start_pointer: int) -> tuple[int, list[int]]:
	pointers: list[tuple[int, int]] = []
	for scenario_id in range(0x100):
		pointer, _, _ = read_pointer(rom, scenario_id)
		if SCENARIO_CPU_WINDOW_START <= pointer < SCENARIO_CPU_WINDOW_END:
			pointers.append((pointer, scenario_id))
	greater = [pointer for pointer, _ in pointers if pointer > start_pointer]
	if not greater:
		raise ValueError(f"Scenario ${SCENARIO_ID:02X} has no greater valid pointer boundary")
	boundary = min(greater)
	boundary_ids = [scenario_id for pointer, scenario_id in pointers if pointer == boundary]
	return boundary, boundary_ids


def build_scenario_entry(stream: bytes, pointer_raw: bytes, pointer_offset: int,
		boundary_ids: list[int]) -> dict:
	return {
		"scenario_id": "$38",
		"path": "reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin",
		"prg_bank": "$10",
		"start_pointer_entry_id": "$38",
		"start_cpu_address": f"0x{EXPECTED_START_CPU:04X}",
		"start_pointer_entry": {
			"table_cpu_address": f"0x{SCENARIO_POINTER_TABLE_CPU:04X}",
			"table_file_offset": f"0x{pointer_offset:06X}",
			"length_bytes": len(pointer_raw),
			"bytes_hex": pointer_raw.hex(" ").upper(),
			"sha256": sha256(pointer_raw),
		},
		"end_boundary_pointer_entry_ids": [f"${entry_id:02X}" for entry_id in boundary_ids],
		"end_cpu_address_exclusive": f"0x{EXPECTED_BOUNDARY_CPU:04X}",
		"file_offset": f"0x{EXPECTED_STREAM_FILE_OFFSET:06X}",
		"end_file_offset_exclusive": f"0x{EXPECTED_STREAM_FILE_OFFSET + len(stream):06X}",
		"length_bytes": len(stream),
		"sha256": sha256(stream),
		"bytes_hex": stream.hex(" ").upper(),
		"source_span_method": "scenario-$38 root through the smallest greater valid CPU pointer among all 256 bank-$10 table entries, exclusive",
		"decoded_scope": {
			"root_record_file_offset": f"0x{EXPECTED_STREAM_FILE_OFFSET:06X}",
			"root_record_length_bytes": len(EXPECTED_ROOT_RECORD),
			"root_record_bytes_hex": EXPECTED_ROOT_RECORD.hex(" ").upper(),
			"record_selector": f"$F7 record selects callback ${EXPECTED_CALLBACK_ID:02X}, as identified by the existing static source audit",
			"audit_source": "reference/rom_extract/gameplay/first_pass_action_trace_20261110.md",
			"unresolved": [
				"Other root-record operand meanings are not assigned by this extraction.",
				"Callback $34 implementation, scenario continuation, scheduler return, frame timing, PPU output, and APU output remain unresolved.",
			],
		},
	}


def main() -> None:
	if not ROM_PATH.is_file():
		raise SystemExit(f"Supplied ROM is missing: {ROM_PATH}")
	rom = ROM_PATH.read_bytes()
	rom_hash = sha256(rom)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
	if len(rom) != EXPECTED_ROM_SIZE or rom[:4] != EXPECTED_ROM_MAGIC:
		raise SystemExit("Unexpected iNES header or ROM size")
	if SCENARIO_POINTER_TABLE_CPU != 0x89BF \
			or SCENARIO_POINTER_TABLE_FILE_OFFSET != 0x0209CF:
		raise SystemExit("Scenario pointer-table mapping constants are inconsistent")
	if pointer_entry_offset(SCENARIO_ID) != EXPECTED_POINTER_ENTRY_FILE_OFFSET:
		raise SystemExit("Scenario-$38 table entry does not map to file offset 0x020A3F")

	start_pointer, pointer_raw, pointer_offset = read_pointer(rom, SCENARIO_ID)
	if pointer_raw != EXPECTED_POINTER_BYTES or start_pointer != EXPECTED_START_CPU:
		raise SystemExit("Scenario-$38 pointer entry no longer resolves to $B7C6")
	boundary, boundary_ids = find_next_pointer_boundary(rom, start_pointer)
	if boundary != EXPECTED_BOUNDARY_CPU or tuple(boundary_ids) != EXPECTED_BOUNDARY_IDS:
		raise SystemExit(
			"Scenario-$38 exclusive boundary changed: "
			f"${boundary:04X} / {[f'${sid:02X}' for sid in boundary_ids]}"
		)

	start_offset = file_offset_for_cpu(start_pointer)
	end_offset = file_offset_for_cpu(boundary)
	if start_offset != EXPECTED_STREAM_FILE_OFFSET or end_offset - start_offset != len(EXPECTED_STREAM):
		raise SystemExit("Scenario-$38 CPU/file span mapping changed")
	stream = rom[start_offset:end_offset]
	if stream != EXPECTED_STREAM:
		raise SystemExit(
		"Scenario-$38 root stream changed: "
		f"expected {EXPECTED_STREAM.hex(' ').upper()}, got {stream.hex(' ').upper()}"
	)
	if stream[: len(EXPECTED_ROOT_RECORD)] != EXPECTED_ROOT_RECORD \
			or stream[3] != EXPECTED_CALLBACK_ID:
		raise SystemExit("Scenario-$38 decoded root-record selector check failed")

	if not MANIFEST_PATH.is_file():
		raise SystemExit(f"Scenario manifest is missing: {MANIFEST_PATH}")
	manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
	if manifest.get("schema") != "first-command-bank10-scenario-sources-v1" \
			or manifest.get("source_rom_sha256") != rom_hash \
			or int(manifest.get("source_rom_size_bytes", -1)) != len(rom):
		raise SystemExit("Existing scenario manifest does not identify the supplied ROM")

	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	SCENARIO_PATH.write_bytes(stream)
	new_entry = build_scenario_entry(stream, pointer_raw, pointer_offset, boundary_ids)
	scenario_entries = list(manifest.get("scenario_streams", []))
	scenario_entries = [entry for entry in scenario_entries if entry.get("scenario_id") != "$38"]
	insertion_index = next(
		(index + 1 for index, entry in enumerate(scenario_entries) if entry.get("scenario_id") == "$36"),
		len(scenario_entries),
	)
	scenario_entries.insert(insertion_index, new_entry)
	manifest["scenario_streams"] = scenario_entries

	pointer_table = manifest.setdefault("scenario_pointer_table", {})
	preserved_ids = list(pointer_table.get("preserved_entry_ids", []))
	if "$38" not in preserved_ids:
		if "$36" in preserved_ids:
			preserved_ids.insert(preserved_ids.index("$36") + 1, "$38")
		else:
			preserved_ids.append("$38")
	pointer_table["preserved_entry_ids"] = preserved_ids

	format_notes = list(manifest.get("format_notes", []))
	format_note = (
		"Scenario $38 is rooted at pointer-table file offset 0x020A3F ($B7C6), "
		"and ends at the smallest greater valid pointer, $B7CD from entry $35. "
		"Its seven-byte stream begins F7 17 01 34 00; the existing static source "
		"audit identifies callback selector $34. Callback behavior and timing "
		"remain unresolved."
	)
	if format_note not in format_notes:
		format_notes.append(format_note)
	manifest["format_notes"] = format_notes
	MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	print(
		"Extracted scenario $38: pointer @ 0x%06X (%s), stream @ 0x%06X (%s), sha256 %s"
		% (pointer_offset, pointer_raw.hex(" ").upper(), start_offset, stream.hex(" ").upper(), sha256(stream))
	)


if __name__ == "__main__":
	main()
