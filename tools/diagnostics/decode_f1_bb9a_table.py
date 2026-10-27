#!/usr/bin/env python3
"""Decode the byte-verified F1 01 drawing packets from the supplied ROM."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
TABLE_CPU_ADDRESS = 0xBB9A
TABLE_FILE_OFFSET = 0x00DBAA  # Includes the 16-byte iNES header.
RECORD_HEADER_SIZE = 3


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def decode_records(rom: bytes) -> list[dict[str, object]]:
	"""Decode count/address/payload records through the bit-6 final marker."""
	if len(rom) < TABLE_FILE_OFFSET:
		raise ValueError("ROM is shorter than the F1 01 table offset")

	position = TABLE_FILE_OFFSET
	records: list[dict[str, object]] = []
	while position + RECORD_HEADER_SIZE <= len(rom):
		header = rom[position]
		count = header & 0x3F
		end = position + RECORD_HEADER_SIZE + count
		if end > len(rom):
			raise ValueError(f"record at file 0x{position:06X} exceeds the ROM")

		address_low = rom[position + 1]
		address_high = rom[position + 2]
		raw_address = (address_high << 8) | address_low
		record = rom[position:end]
		records.append({
			"index": len(records),
			"file_offset": position,
			"file_end_exclusive": end,
			"cpu_pointer": TABLE_CPU_ADDRESS + position - TABLE_FILE_OFFSET,
			"header": header,
			"count": count,
			"final": bool(header & 0x40),
			"increment": 32 if header & 0x80 else 1,
			"raw_address": raw_address,
			"ppu_address": raw_address & 0x3FFF,
			"payload": record[RECORD_HEADER_SIZE:],
			"record": record,
			"record_sha256": sha256(record),
			"payload_sha256": sha256(record[RECORD_HEADER_SIZE:]),
		})
		position = end
		if header & 0x40:
			return records

	raise ValueError("F1 01 table has no bit-6 final record")


def write_extract_files(rom_path: Path, rom: bytes, records: list[dict[str, object]],
						output_dir: Path) -> tuple[Path, Path]:
	"""Write the unchanged packet bytes and their provenance manifest."""
	stream_end = records[-1]["file_end_exclusive"]
	stream = rom[TABLE_FILE_OFFSET:stream_end]
	output_dir.mkdir(parents=True, exist_ok=True)
	resource_path = output_dir / "f1_01_graphics.bin"
	manifest_path = output_dir / "f1_01_graphics.json"
	resource_path.write_bytes(stream)

	manifest = {
		"schema": 1,
		"name": "f1_01_graphics",
		"rom": {
			"file": rom_path.name,
			"sha256": sha256(rom),
		},
		"source": {
			"prg_bank": 6,
			"bank_size_bytes": 8192,
			"cpu_window": "$A000-$BFFF",
			"cpu_address": "$BB9A",
			"file_offset_start": f"0x{TABLE_FILE_OFFSET:06X}",
			"file_offset_end_exclusive": f"0x{stream_end:06X}",
			"file_offset_end_inclusive": f"0x{stream_end - 1:06X}",
			"ines_header_bytes": 16,
		},
		"resource": {
			"file": resource_path.name,
			"byte_length": len(stream),
			"sha256": sha256(stream),
			"byte_identity": "copied unchanged from the ROM source range",
		},
		"format": {
			"description": "F1 01 PPU header/address/payload packet stream",
			"record_count": len(records),
			"records": [
				{
					"record_index": record["index"],
					"source_file_offset": f"0x{record['file_offset']:06X}",
					"header": f"0x{record['header']:02X}",
					"payload_length": record["count"],
					"ppu_address": f"0x{record['ppu_address']:04X}",
					"increment": record["increment"],
					"final": record["final"],
					"record_sha256": record["record_sha256"],
					"payload_sha256": record["payload_sha256"],
				}
				for record in records
			],
		},
	}
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	return resource_path, manifest_path


def main() -> int:
	project_root = Path(__file__).resolve().parents[2]
	default_rom = project_root / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("rom", nargs="?", type=Path, default=default_rom,
						help="supplied iNES ROM (defaults to the project reference ROM)")
	parser.add_argument("--extract-dir", type=Path,
					help="write byte-identical f1_01_graphics.bin and its JSON manifest here")
	parser.add_argument("--reference-copy", type=Path,
						help="also write the unchanged binary to this provenance/archive path")
	args = parser.parse_args()

	rom = args.rom.read_bytes()
	rom_hash = sha256(rom)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(
			f"ROM SHA-256 mismatch: expected {EXPECTED_ROM_SHA256}, got {rom_hash}"
		)
	records = decode_records(rom)
	stream_end = records[-1]["file_end_exclusive"]
	stream = rom[TABLE_FILE_OFFSET:stream_end]
	if args.extract_dir:
		resource_path, manifest_path = write_extract_files(args.rom, rom, records, args.extract_dir)
		print(f"Wrote byte-identical resource: {resource_path}")
		print(f"Wrote provenance manifest: {manifest_path}")
	if args.reference_copy:
		args.reference_copy.parent.mkdir(parents=True, exist_ok=True)
		args.reference_copy.write_bytes(stream)
		print(f"Wrote unchanged reference bytes: {args.reference_copy}")

	print(f"ROM SHA-256: {rom_hash}")
	print(f"F1 01 table: CPU ${TABLE_CPU_ADDRESS:04X}, file 0x{TABLE_FILE_OFFSET:06X}")
	print(f"Raw stream: {len(stream)} bytes, SHA-256 {sha256(stream)}")
	for record in records:
		print(
			f"[{record['index']}] CPU ${record['cpu_pointer']:04X} "
			f"file 0x{record['file_offset']:06X} "
			f"header ${record['header']:02X}, count {record['count']}, "
			f"dst ${record['ppu_address']:04X}, +{record['increment']}, "
			f"final={str(record['final']).lower()}"
		)
		print(f"    bytes: {record['record'].hex(' ').upper()}")
		print(f"    record SHA-256: {record['record_sha256']}")
		print(f"    payload SHA-256: {record['payload_sha256']}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
