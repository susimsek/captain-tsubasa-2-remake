#!/usr/bin/env python3
"""Extract ROM tile/attribute records referenced by callback-$34 map-$2D.

This is a static data extraction tool only. It does not emulate the map worker,
produce PPU packets, or establish rendering order or timing.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
SOURCE_DIR = ROOT / "reference/rom_extract/gameplay/slot15_callback_34"
MAP_BLOCK_PATH = SOURCE_DIR / "map_2d_block.bin"
SELECTOR_SOURCE_PATH = SOURCE_DIR / "map_2d_selector_source.bin"
OUTPUT_DIR = SOURCE_DIR / "map_2d_metatiles"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROM_SIZE = 393232
EXPECTED_ROM_MAGIC = b"NES\x1a"
EXPECTED_MAPPER = 4
EXPECTED_PRG_SIZE = 0x40000
EXPECTED_CHR_SIZE = 0x20000

INES_HEADER_SIZE = 0x10
PRG_BANK_SIZE = 0x2000
PRG_BANK_COUNT_8K = EXPECTED_PRG_SIZE // PRG_BANK_SIZE

MAP_ID = 0x2D
MAP_SELECTOR = 0x02
MAP_SELECTOR_TABLE_CPU = 0x8B42
MAP_SELECTOR_BYTE_CPU = 0x8B4D
MAP_SELECTOR_BYTE_FILE = 0x016B5D
MAP_SELECTOR_BYTE = 0x6A
MAP_BLOCK_TABLE_CPU = 0x8B64
MAP_BLOCK_CPU = 0x9104
MAP_BLOCK_FILE = 0x017114
MAP_BLOCK_LENGTH = 0x20
MAP_BLOCK_SHA256 = "5f2a7c9e9b42fa9860e062f8df1ee57caf1d255424d85ff884c6158f1cf8e1e9"
EXPECTED_FIRST_BATCH_IDS = [0x00, 0x71, 0x72]

# The existing source manifest records this established address mapping.
BANK_0B_FILE_BASE = 0x016010
BANK_0B_CPU_BASE = 0x8000
BANK_0B_CPU_LIMIT = 0xA000
TILE_WINDOW_BANK_BASE = 0x12
TILE_WINDOW_CPU_BASE = 0xA000
TILE_WINDOW_FILE_BASE = 0x024010
ATTRIBUTE_FILE_BASE = 0x017BF4
ATTRIBUTE_CPU_BASE = 0x9BE4


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def bank_file_offset(bank: int, cpu_address: int) -> int:
	if not BANK_0B_CPU_BASE <= cpu_address < BANK_0B_CPU_LIMIT:
		raise ValueError(f"CPU address ${cpu_address:04X} is outside bank-$0B's window")
	if not 0 <= bank < PRG_BANK_COUNT_8K:
		raise ValueError(f"PRG bank ${bank:02X} is outside the canonical ROM")
	return INES_HEADER_SIZE + bank * PRG_BANK_SIZE + cpu_address - BANK_0B_CPU_BASE


def map_block_cpu_address(map_id: int) -> int:
	return MAP_BLOCK_TABLE_CPU + ((map_id >> 3) << 8) + ((map_id & 0x07) << 5)


def tile_record_location(selector: int, metatile_id: int) -> tuple[int, int, int]:
	window_offset = (selector << 12) + (metatile_id << 4)
	bank = TILE_WINDOW_BANK_BASE + (window_offset >> 13)
	cpu_address = TILE_WINDOW_CPU_BASE + (window_offset & 0x1FFF)
	file_offset = TILE_WINDOW_FILE_BASE + window_offset
	if file_offset != INES_HEADER_SIZE + bank * PRG_BANK_SIZE + (cpu_address - TILE_WINDOW_CPU_BASE):
		raise ValueError("Tile record bank/window and file-offset formulas disagree")
	return bank, cpu_address, file_offset


def attribute_record_location(selector: int, metatile_id: int) -> tuple[int, int, int]:
	cpu_address = ATTRIBUTE_CPU_BASE + (selector << 8) + metatile_id
	file_offset = ATTRIBUTE_FILE_BASE + (selector << 8) + metatile_id
	bank = 0x0B
	if file_offset != bank_file_offset(bank, cpu_address):
		raise ValueError("Attribute bank/window and file-offset formulas disagree")
	return bank, cpu_address, file_offset


def verify_ines_header(rom: bytes) -> dict:
	if len(rom) != EXPECTED_ROM_SIZE or rom[:4] != EXPECTED_ROM_MAGIC:
		raise ValueError("Canonical ROM size or iNES magic does not match")
	if (rom[7] & 0x0C) == 0x08:
		raise ValueError("This extractor expects the pinned iNES 1.0 header, not NES 2.0")
	mapper = (rom[6] >> 4) | (rom[7] & 0xF0)
	prg_size = rom[4] * 0x4000
	chr_size = rom[5] * 0x2000
	trainer_size = 0x200 if (rom[6] & 0x04) else 0
	if mapper != EXPECTED_MAPPER or prg_size != EXPECTED_PRG_SIZE \
			or chr_size != EXPECTED_CHR_SIZE or trainer_size != 0:
		raise ValueError(
			f"Unexpected header: mapper={mapper}, PRG={prg_size:#x}, "
			f"CHR={chr_size:#x}, trainer={trainer_size}"
		)
	if INES_HEADER_SIZE + trainer_size + prg_size + chr_size != len(rom):
		raise ValueError("iNES header sizes do not account for the ROM file length")
	return {
		"format": "iNES 1.0",
		"mapper": mapper,
		"trainer_bytes": trainer_size,
		"prg_rom_bytes": prg_size,
		"chr_rom_bytes": chr_size,
		"prg_bank_size_bytes": PRG_BANK_SIZE,
		"prg_bank_count_8k": PRG_BANK_COUNT_8K,
		"header_hex": rom[:INES_HEADER_SIZE].hex(" ").upper(),
	}


def extract(rom: bytes) -> dict:
	rom_sha256 = sha256(rom)
	if rom_sha256 != EXPECTED_ROM_SHA256:
		raise ValueError(f"Canonical ROM SHA-256 mismatch: {rom_sha256}")
	header = verify_ines_header(rom)

	selector_byte_offset = bank_file_offset(0x0B, MAP_SELECTOR_BYTE_CPU)
	selector_byte = rom[selector_byte_offset]
	if selector_byte_offset != MAP_SELECTOR_BYTE_FILE or selector_byte != MAP_SELECTOR_BYTE:
		raise ValueError("Map-$2D selector source differs from the pinned manifest")
	selector_index = MAP_ID >> 2
	resolved_selector = (selector_byte >> (2 * (MAP_ID & 0x03))) & 0x03
	if MAP_SELECTOR_TABLE_CPU + selector_index != MAP_SELECTOR_BYTE_CPU \
			or resolved_selector != MAP_SELECTOR:
		raise ValueError("Map-$2D selector table lookup no longer resolves to selector $02")

	map_block_cpu = map_block_cpu_address(MAP_ID)
	map_block_offset = bank_file_offset(0x0B, map_block_cpu)
	if map_block_cpu != MAP_BLOCK_CPU or map_block_offset != MAP_BLOCK_FILE:
		raise ValueError("Map-$2D block-map CPU/file address formula changed")
	map_block = rom[map_block_offset : map_block_offset + MAP_BLOCK_LENGTH]
	if len(map_block) != MAP_BLOCK_LENGTH or sha256(map_block) != MAP_BLOCK_SHA256:
		raise ValueError("Map-$2D block-map bytes do not match the pinned extraction")
	if not MAP_BLOCK_PATH.is_file() or MAP_BLOCK_PATH.read_bytes() != map_block:
		raise ValueError("Existing map_2d_block.bin differs from the canonical ROM span")
	if not SELECTOR_SOURCE_PATH.is_file() or SELECTOR_SOURCE_PATH.read_bytes() != bytes([selector_byte]):
		raise ValueError("Existing map_2d_selector_source.bin differs from the canonical ROM byte")

	unique_ids = list(dict.fromkeys(map_block))
	if map_block[: len(EXPECTED_FIRST_BATCH_IDS)] != bytes(EXPECTED_FIRST_BATCH_IDS):
		raise ValueError("The first three map-$2D block IDs changed")
	if not set(EXPECTED_FIRST_BATCH_IDS).issubset(unique_ids):
		raise ValueError("The map-$2D first-batch IDs are absent from the unique block IDs")

	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	metatiles: list[dict] = []
	for metatile_id in unique_ids:
		tiles_bank, tiles_cpu, tiles_offset = tile_record_location(MAP_SELECTOR, metatile_id)
		attribute_bank, attribute_cpu, attribute_offset = attribute_record_location(
			MAP_SELECTOR, metatile_id
		)
		tiles = rom[tiles_offset : tiles_offset + 0x10]
		attribute = rom[attribute_offset : attribute_offset + 1]
		if len(tiles) != 0x10 or len(attribute) != 1:
			raise ValueError(f"Metatile ${metatile_id:02X} source span is truncated")
		tiles_path = OUTPUT_DIR / f"metatile_{metatile_id:02X}_tiles.bin"
		attribute_path = OUTPUT_DIR / f"metatile_{metatile_id:02X}_attribute.bin"
		tiles_path.write_bytes(tiles)
		attribute_path.write_bytes(attribute)
		if tiles_path.read_bytes() != tiles or attribute_path.read_bytes() != attribute:
			raise ValueError(f"Metatile ${metatile_id:02X} output failed byte-for-byte verification")
		metatiles.append({
			"metatile_id": f"0x{metatile_id:02X}",
			"occurrences_in_map_block": [i for i, value in enumerate(map_block) if value == metatile_id],
			"tiles": {
				"path": tiles_path.name,
				"prg_bank": f"0x{tiles_bank:02X}",
				"cpu_address": f"0x{tiles_cpu:04X}",
				"file_offset": f"0x{tiles_offset:06X}",
				"length_bytes": len(tiles),
				"bytes_hex": tiles.hex(" ").upper(),
				"sha256": sha256(tiles),
			},
			"attribute": {
				"path": attribute_path.name,
				"prg_bank": f"0x{attribute_bank:02X}",
				"cpu_address": f"0x{attribute_cpu:04X}",
				"file_offset": f"0x{attribute_offset:06X}",
				"length_bytes": len(attribute),
				"bytes_hex": attribute.hex(" ").upper(),
				"sha256": sha256(attribute),
			},
		})

	manifest = {
		"schema": "ct2-slot15-callback-34-map-2d-metatiles-v1",
		"scope": "ROM byte extraction only; no runtime worker, tile expansion, PPU packet, frame timing, or APU behavior is modeled.",
		"source_rom": ROM_PATH.name,
		"source_rom_sha256": rom_sha256,
		"source_rom_size_bytes": len(rom),
		"ines_header": header,
		"mapper": "MMC3 (mapper 4)",
		"runtime_rom_dependency": False,
		"capture_or_screenshot_bytes_included": False,
		"map_source": {
			"map_id": f"0x{MAP_ID:02X}",
			"selector_table_cpu_address": f"0x{MAP_SELECTOR_TABLE_CPU:04X}",
			"selector_table_index": f"0x{selector_index:02X}",
			"selector_byte_cpu_address": f"0x{MAP_SELECTOR_BYTE_CPU:04X}",
			"selector_byte_file_offset": f"0x{selector_byte_offset:06X}",
			"selector_byte_hex": f"{selector_byte:02X}",
			"selector_formula": "(ROM[table_cpu + (map_id >> 2)] >> (2 * (map_id & 3))) & 3",
			"resolved_selector": f"0x{resolved_selector:02X}",
			"block_map_cpu_address": f"0x{map_block_cpu:04X}",
			"block_map_file_offset": f"0x{map_block_offset:06X}",
			"block_map_length_bytes": len(map_block),
			"block_map_bytes_hex": map_block.hex(" ").upper(),
			"block_map_sha256": sha256(map_block),
			"block_map_path": "reference/rom_extract/gameplay/slot15_callback_34/map_2d_block.bin",
			"block_map_cpu_formula": "0x8B64 + ((map_id >> 3) << 8) + ((map_id & 7) << 5)",
			"first_batch_ids": [f"0x{value:02X}" for value in EXPECTED_FIRST_BATCH_IDS],
			"unique_metatile_ids_in_first_occurrence_order": [f"0x{value:02X}" for value in unique_ids],
		},
		"bank_and_window_formulas": {
			"bank_0b_cpu_window": "0x8000-0x9FFF",
			"bank_0b_file_offset": "0x10 + (0x0B * 0x2000) + (CPU - 0x8000)",
			"selector_tile_window": "window_offset = (selector << 12) + (metatile_id << 4)",
			"tile_record_prg_bank": "0x12 + (window_offset >> 13)",
			"tile_record_cpu_address": "0xA000 + (window_offset & 0x1FFF)",
			"tile_record_file_offset": "0x024010 + window_offset",
			"attribute_record_cpu_address": "0x9BE4 + (selector << 8) + metatile_id",
			"attribute_record_file_offset": "0x017BF4 + (selector << 8) + metatile_id",
			"tile_record_length_bytes": 16,
			"attribute_record_length_bytes": 1,
		},
		"metatiles": metatiles,
		"limitations": [
			"The block IDs are read from the verified ROM map-$2D span; tile and attribute bytes are extracted from selector-$02 ROM windows using the recorded formulas.",
			"This extraction does not establish the map worker's live source-read order, queue cadence, screen output, or NMI/frame timing.",
			"The files are reference-derived data; adding them does not by itself connect or validate them in the Godot runtime.",
		],
	}
	MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	print(
		f"Extracted and byte-verified {len(unique_ids)} selector-$02 map-$2D metatiles "
		f"({len(unique_ids) * 2} binary records); ROM SHA-256 {rom_sha256}"
	)
	print(f"Manifest: {MANIFEST_PATH.relative_to(ROOT)}")


def main() -> None:
	if not ROM_PATH.is_file():
		raise SystemExit(f"Canonical supplied ROM is missing: {ROM_PATH}")
	try:
		extract(ROM_PATH.read_bytes())
	except (OSError, ValueError) as exc:
		raise SystemExit(str(exc)) from exc


if __name__ == "__main__":
	main()
