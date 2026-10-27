#!/usr/bin/env python3
"""Extract the byte-verified bank-6 EC pointer/stream/group segment."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SOURCE_OFFSET = 0x00DD10
SOURCE_LENGTH = 0x0200
DEFAULT_ROM = "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DEFAULT_OUTPUT = Path("reference/rom_extract/intro/ec_bank6_bd00_beff.bin")


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, default=Path(DEFAULT_ROM))
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()

	rom = args.rom.read_bytes()
	rom_hash = sha256(rom)
	if rom_hash != ROM_SHA256:
		raise SystemExit(f"ROM hash mismatch: expected {ROM_SHA256}, got {rom_hash}")
	segment = rom[SOURCE_OFFSET:SOURCE_OFFSET + SOURCE_LENGTH]
	if len(segment) != SOURCE_LENGTH:
		raise SystemExit("ROM is too short for the expected bank-6 segment")

	args.output.parent.mkdir(parents=True, exist_ok=True)
	args.output.write_bytes(segment)
	metadata = {
		"rom_sha256": ROM_SHA256,
		"source_file_offset": "0x00DD10",
		"source_cpu_range": "$BD00-$BEFF",
		"source_prg_bank": 6,
		"length_bytes": SOURCE_LENGTH,
		"sha256": sha256(segment),
		"regions": [
			{"name": "pointer_table", "cpu_start": "$BD00", "length_bytes": 12},
			{"name": "ec_stream_00", "cpu_start": "$BD0C", "length_bytes": 116, "terminator": "$FF"},
			{"name": "ec_group_payloads", "cpu_start": "$BD80", "length_bytes": 384, "record_size_bytes": 12, "record_count": 32},
		],
		"runtime_note": "Extracted project-owned source bytes. No ROM or emulator runtime dependency.",
	}
	args.output.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n")
	print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
	main()
