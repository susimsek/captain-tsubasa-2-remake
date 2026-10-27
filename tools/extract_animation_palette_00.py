#!/usr/bin/env python3
"""Preserve animation palette index 0 directly from the byte-verified ROM."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SOURCE_OFFSET = 0x00D310
SOURCE_CPU_ADDRESS = 0xB300
PALETTE_BYTES = 16
EXPECTED_HEX = "0f 0f 0f 36 0f 0f 16 36 0f 0f 30 36 0f 0f 30 36"
OUTPUT_BIN = Path("reference/rom_extract/intro/animation_00_sprite_palette.bin")
OUTPUT_JSON = Path("reference/rom_extract/intro/animation_00_sprite_palette.json")


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument(
		"--rom",
		type=Path,
		default=Path("Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"),
	)
	args = parser.parse_args()
	rom = args.rom.read_bytes()
	rom_sha256 = hashlib.sha256(rom).hexdigest()
	if rom_sha256 != ROM_SHA256:
		raise SystemExit(f"ROM SHA-256 mismatch: {rom_sha256}")
	palette = rom[SOURCE_OFFSET:SOURCE_OFFSET + PALETTE_BYTES]
	if palette.hex(" ") != EXPECTED_HEX:
		raise SystemExit("Palette bytes do not match the source-verified animation palette.")
	OUTPUT_BIN.parent.mkdir(parents=True, exist_ok=True)
	OUTPUT_BIN.write_bytes(palette)
	metadata = {
		"rom_sha256": ROM_SHA256,
		"animation_palette_index": "0x00",
		"prg_bank": 6,
		"source_file_offset": f"0x{SOURCE_OFFSET:06X}",
		"source_cpu_address": f"0x{SOURCE_CPU_ADDRESS:04X}",
		"source_bytes": PALETTE_BYTES,
		"source_sha256": hashlib.sha256(palette).hexdigest(),
		"bytes_hex": palette.hex(" "),
		"ppu_destination": "$3F10-$3F1F",
		"reference_ppu_snapshot": "reference/opening_reference_capture/ppu_states/ppu_000380.bin",
		"reference_ppu_sprite_palette_hex": EXPECTED_HEX,
		"matches_reference_ppu_palette": True,
		"conversion": "none; raw 16-byte palette record copied unchanged from the supplied ROM",
	}
	OUTPUT_JSON.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {OUTPUT_BIN} ({PALETTE_BYTES} ROM bytes)")
	print(f"Wrote {OUTPUT_JSON}")


if __name__ == "__main__":
	main()
