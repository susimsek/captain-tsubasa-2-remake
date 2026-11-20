#!/usr/bin/env python3
"""Preserve ROM byte spans needed to resolve first-command scenario callbacks."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/callback_dispatch"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

BANK_0B_FILE_BASE = 0x016010

SOURCES = [
	{
		"path": "bank_0b_event_63_pointer_boundary.bin",
		"file_offset": 0x0168CC,
		"size_bytes": 4,
		"cpu_address": "0x88BC",
		"prg_bank": "0x0B",
		"source": "Callback-$63 pointer $8AD8 and following callback-$64 boundary $8ADB.",
	},
	{
		"path": "bank_0b_event_63_stream.bin",
		"file_offset": 0x016AE8,
		"size_bytes": 3,
		"cpu_address": "0x8AD8",
		"prg_bank": "0x0B",
		"source": "Pointer-bounded callback-$63 bytes through the callback-$64 boundary.",
	},
	{
		"path": "bank_0b_event_36_pointer_boundary.bin",
		"file_offset": 0x016872,
		"size_bytes": 4,
		"cpu_address": "0x8862",
		"prg_bank": "0x0B",
		"source": "Scenario-$2E callback-$36 pointer $89E7 and following callback-$37 boundary $89EA.",
	},
	{
		"path": "bank_0b_event_36_stream.bin",
		"file_offset": 0x0169F7,
		"size_bytes": 3,
		"cpu_address": "0x89E7",
		"prg_bank": "0x0B",
		"source": "Pointer-bounded scenario-$2E callback-$36 bytes through the callback-$37 boundary.",
	},
	{
		"path": "bank_0b_event_45_pointer_boundary.bin",
		"file_offset": 0x016890,
		"size_bytes": 4,
		"cpu_address": "0x8880",
		"prg_bank": "0x0B",
		"source": "Scenario-$1E callback-$45 pointer $8A2A and following callback-$46 boundary $8A2D.",
	},
	{
		"path": "bank_0b_event_45_stream.bin",
		"file_offset": 0x016A3A,
		"size_bytes": 3,
		"cpu_address": "0x8A2A",
		"prg_bank": "0x0B",
		"source": "Pointer-bounded scenario-$1E callback-$45 bytes through the callback-$46 boundary.",
	},
	{
		"path": "bank_0b_event_01_pointer_boundary.bin",
		"file_offset": 0x016808,
		"size_bytes": 4,
		"cpu_address": "0x87F8",
		"prg_bank": "0x0B",
		"source": "Callback-$01 pointer $88E3 and following callback-$02 boundary $88E4.",
	},
	{
		"path": "bank_0b_event_01_stream.bin",
		"file_offset": 0x0168F3,
		"size_bytes": 1,
		"cpu_address": "0x88E3",
		"prg_bank": "0x0B",
		"source": "Pointer-bounded callback-$01 control byte F0.",
	},
	{
		"path": "bank_0b_dispatcher_814c_81a6.bin",
		"file_offset": 0x01615C,
		"size_bytes": 0x5B,
		"cpu_address": "0x814C",
		"prg_bank": "0x0B",
		"source": "Scenario callback setup, pointer lookup, $0525 storage, and indirect-call entry up to $81A7.",
	},
	{
		"path": "bank_0b_dispatch_vector_81a7.bin",
		"file_offset": 0x0161B7,
		"size_bytes": 0x15,
		"cpu_address": "0x81A7",
		"prg_bank": "0x0B",
		"source": "JSR $C509 plus its inline callback-target table; index $00 resolves to $8327.",
	},
	{
		"path": "bank_0b_event_70_pointer.bin",
		"file_offset": 0x0168E6,
		"size_bytes": 2,
		"cpu_address": "0x87F6",
		"prg_bank": "0x0B",
		"source": "Scenario callback pointer-table entry $70: little-endian target $8B38.",
	},
	{
		"path": "bank_0b_event_72_pointer.bin",
		"file_offset": 0x0168EA,
		"size_bytes": 2,
		"cpu_address": "0x87F6",
		"prg_bank": "0x0B",
		"source": "Following valid scenario callback pointer-table entry $72: little-endian target $8B3E, bounding callback-$70's source span.",
	},
	{
		"path": "bank_0b_event_70_stream.bin",
		"file_offset": 0x016B48,
		"size_bytes": 6,
		"cpu_address": "0x8B38",
		"prg_bank": "0x0B",
		"source": "Pointer-bounded callback-$70 bytes through the next valid callback target $8B3E.",
	},
]


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def preserve(path: Path, data: bytes) -> None:
	if path.exists() and path.read_bytes() != data:
		raise SystemExit(f"Preserved source differs from supplied ROM: {path}")
	path.write_bytes(data)


def main() -> None:
	rom = ROM_PATH.read_bytes()
	rom_hash = sha256(rom)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

	entries: list[dict[str, object]] = []
	for source in SOURCES:
		offset = int(source["file_offset"])
		size = int(source["size_bytes"])
		data = rom[offset : offset + size]
		if len(data) != size:
			raise SystemExit(f"Truncated ROM source range: {source['path']}")
		filename = str(source["path"])
		preserve(OUTPUT_DIR / filename, data)
		entries.append({
			**source,
			"file_offset": f"0x{offset:06X}",
			"size_bytes": len(data),
			"sha256": sha256(data),
			"raw_hex": data.hex(" ").upper(),
		})

	manifest = {
		"schema": "first-command-callback-dispatch-sources-v1",
		"resource_kind": "preserved ROM bytes; no emulator capture data",
		"rom_filename": ROM_PATH.name,
		"rom_sha256": rom_hash,
		"bank_mapping": {"bank_0b_cpu_8000_file_base": f"0x{BANK_0B_FILE_BASE:06X}"},
		"source_behavior": {
			"scenario_1c_callback": "Scenario-$1C record 38 63 7A 58 selects callback $63; bank-$0B entry $88BC resolves to $8AD8 and the next entry bounds stream 02 00 51, whose vector row 0 resolves to $8327 and map selector $51.",
			"scenario_2e_callback": "Scenario-$2E event record selects callback $36; bank-$0B table entry $36 resolves to $89E7 and following entry $37 at $89EA bounds the three-byte stream 02 00 2F. The meaning of the final operand is unresolved.",
			"scenario_1e_callback": "Scenario-$1E task slot $15 selects callback $45; bank-$0B table entry $45 resolves to $8A2A and the next entry $46 bounds bytes 06 00 36.",
			"scenario_event": "bank-$10 scenario $44 record: 02 70 5C F0, followed by caller-owned $FB continuation",
			"callback_pointer_table": "bank-$0B $87F6 plus 2*$70 stores pointer $8B38; next valid entry $72 points to $8B3E",
			"dispatch_vector": "bank-$0B $81A7 inline target entry 0 is $8327",
			"shared_placement_state": "bank-$0B $8327 reads global RAM $05CD, writes $05CE, then updates $05CD",
		},
		"entries": entries,
	}
	(OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"Preserved {len(entries)} callback-dispatch source spans under {OUTPUT_DIR.relative_to(ROOT)}")
	for entry in entries:
		print(f"{entry['path']}: {entry['size_bytes']} bytes sha256 {entry['sha256']}")


if __name__ == "__main__":
	main()
