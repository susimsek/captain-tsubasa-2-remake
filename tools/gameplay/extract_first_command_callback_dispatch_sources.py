#!/usr/bin/env python3
"""Preserve the ROM byte spans needed to resolve scenario-$44 callback $70."""

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
