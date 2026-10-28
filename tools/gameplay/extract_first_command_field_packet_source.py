#!/usr/bin/env python3
"""Preserve ROM bytes for the first-command field packet producer audit."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/first_command_field/packet_producer"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

SOURCES = [
	{
		"path": "bank_1f_f015_f159_code.bin",
		"file_offset": 0x03F025,
		"size_bytes": 0x145,
		"cpu_address": "0xF015",
		"prg_bank": "0x1F",
		"source": "ROM instructions F015-F158: descriptor loop, special F0B5 coordinate writer, and F114 stream copier",
	},
	{
		"path": "bank_1f_f10e_column_offsets.bin",
		"file_offset": 0x03F11E,
		"size_bytes": 6,
		"cpu_address": "0xF10E",
		"prg_bank": "0x1F",
		"source": "F015 low-byte offsets indexed by A: 00,01,02,08,09,0A",
	},
	{
		"path": "bank_1f_f15a_descriptor_addresses.bin",
		"file_offset": 0x03F16A,
		"size_bytes": 16,
		"cpu_address": "0xF15A",
		"prg_bank": "0x1F",
		"source": "four 4-byte descriptor address/attribute bases read by F015 and F0B5",
	},
	{
		"path": "bank_1f_f16a_descriptor_tiles.bin",
		"file_offset": 0x03F17A,
		"size_bytes": 24,
		"cpu_address": "0xF16A",
		"prg_bank": "0x1F",
		"source": "four six-byte descriptor tile-ID rows read by F015",
	},
	{
		"path": "bank_1f_f182_packet_pointers.bin",
		"file_offset": 0x03F192,
		"size_bytes": 12,
		"cpu_address": "0xF182",
		"prg_bank": "0x1F",
		"source": "six little-endian packet-stream pointers indexed by F015 input A",
	},
	{
		"path": "bank_1f_f18e_packet_streams.bin",
		"file_offset": 0x03F19E,
		"size_bytes": 0x78,
		"cpu_address": "0xF18E",
		"prg_bank": "0x1F",
		"source": "six F114 packet streams, each terminated by 00",
	},
	{
		"path": "bank_0b_8327_8360_map_placement_writer.bin",
		"file_offset": 0x016337,
		"size_bytes": 0x39,
		"cpu_address": "0x8327",
		"prg_bank": "0x0B",
		"source": "map opcode-$00 handler; includes the $05CE/$05CD placement update at CPU $8342",
	},
	{
		"path": "bank_0b_animation_70_route_prefix.bin",
		"file_offset": 0x016B48,
		"size_bytes": 8,
		"cpu_address": "0x8B38",
		"prg_bank": "0x0B",
		"source": "ROM background animation-$70 route prefix selecting block $56 and subsequent command bytes",
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
		"schema": "first-command-field-packet-producer-sources-v1",
		"resource_kind": "preserved ROM bytes; no emulator capture data",
		"rom_filename": ROM_PATH.name,
		"rom_sha256": rom_hash,
		"bank_mapping": {
			"bank_1f_cpu_e000_file_base": "0x03E010",
			"bank_0b_cpu_8000_file_base": "0x016010",
		},
		"source_logic": {
			"packet_producer": "bank-$1F $F015; six A values 00-05; descriptor from RAM $063D",
			"packet_stream_reader": "bank-$1F $F114; stream pointers from $F182 and scripts from $F18E",
			"placement_operand": "absolute operand bytes AD CE 05 read RAM $05CE; this is not RAM $06CE",
			"map_placement_writer": "bank-$0B $8327 handler stores $05CE at $8342 from the prior $05CD state and then toggles $05CD",
			"special_holder_writer": "bank-$1F $F0B5 reads $05CE and coordinates $0635/$0637; it is kept separate from static F015 packets",
		},
		"entries": entries,
	}
	MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"Preserved {len(entries)} ROM source ranges under {OUTPUT_DIR}")
	print(f"Manifest: {MANIFEST_PATH}")


if __name__ == "__main__":
	main()
