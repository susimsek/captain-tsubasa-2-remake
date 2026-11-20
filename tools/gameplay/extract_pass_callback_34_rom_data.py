#!/usr/bin/env python3
"""Extract ROM-owned callback-$34 / map-$2D source spans."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/slot15_callback_34"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_ROM_SIZE = 393232
INES_HEADER_SIZE = 0x10
PRG_BANK_SIZE = 0x2000
PRG_BANK = 0x0B
BANK_CPU_START = 0x8000
BANK_CPU_END = 0xA000
BANK_FILE_BASE = INES_HEADER_SIZE + PRG_BANK * PRG_BANK_SIZE
EXPECTED_BANK_FILE_BASE = 0x016010

CALLBACK_ID = 0x34
CALLBACK_POINTER_TABLE_CPU = 0x87F6
CALLBACK_POINTER_ENTRY_CPU = 0x885E
CALLBACK_POINTER_ENTRY_FILE = 0x01686E
EXPECTED_CALLBACK_POINTER = bytes.fromhex("E1 89")
SCRIPT_CPU = 0x89E1
SCRIPT_FILE = 0x0169F1
EXPECTED_SCRIPT = bytes.fromhex("02 00 2D")

MAP_ID = 0x2D
MAP_SELECTOR_TABLE_CPU = 0x8B42
MAP_SELECTOR_CPU = 0x8B4D
MAP_SELECTOR_FILE = 0x016B5D
EXPECTED_MAP_SELECTOR_BYTE = bytes.fromhex("6A")
EXPECTED_MAP_SELECTOR = 0x02
CHR_PAIR_TABLE_CPU = 0x86EE
CHR_PAIR_CPU = 0x8748
CHR_PAIR_FILE = 0x016758
EXPECTED_CHR_PAIR = bytes.fromhex("00 02")
MAP_BLOCK_CPU = 0x9104
MAP_BLOCK_FILE = 0x017114
MAP_BLOCK_LENGTH = 32
EXPECTED_MAP_BLOCK = bytes.fromhex(
	"00 71 72 72 73 72 74 00 00 75 76 77 78 79 7A 00 "
	"00 7B 7C 7D 7E 7F 80 00 00 81 82 82 83 82 84 00"
)
EXPECTED_MAP_BLOCK_SHA256 = "5f2a7c9e9b42fa9860e062f8df1ee57caf1d255424d85ff884c6158f1cf8e1e9"
NEIGHBOR_MAP_ID = 0x28
NEIGHBOR_MAP_BLOCK_CPU = 0x9064
NEIGHBOR_MAP_BLOCK_FILE = 0x017074

OUTPUTS = {
	"callback_34_script_pointer": "callback_34_script_pointer.bin",
	"callback_34_map_2d_script": "callback_34_map_2d_script.bin",
	"map_2d_selector_source": "map_2d_selector_source.bin",
	"map_2d_chr_pair": "map_2d_chr_pair.bin",
	"map_2d_block": "map_2d_block.bin",
}


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def file_offset(cpu_address: int) -> int:
	if not BANK_CPU_START <= cpu_address < BANK_CPU_END:
		raise ValueError(f"CPU address ${cpu_address:04X} is outside bank-$0B window")
	return BANK_FILE_BASE + cpu_address - BANK_CPU_START


def read_span(rom: bytes, cpu_address: int, length: int) -> bytes:
	start = file_offset(cpu_address)
	data = rom[start : start + length]
	if len(data) != length:
		raise ValueError(f"Truncated source at bank-$0B CPU ${cpu_address:04X}")
	return data


def source_record(
		key: str,
		role: str,
		cpu_address: int,
		data: bytes,
		*,
		relationship: str,
) -> dict:
	return {
		"path": f"reference/rom_extract/gameplay/slot15_callback_34/{OUTPUTS[key]}",
		"prg_bank": "$0B",
		"cpu_address": f"0x{cpu_address:04X}",
		"file_offset": f"0x{file_offset(cpu_address):06X}",
		"length_bytes": len(data),
		"bytes_hex": data.hex(" ").upper(),
		"sha256": sha256(data),
		"role": role,
		"relationship": relationship,
	}


def build_manifest(spans: dict[str, tuple[str, int, bytes, str]]) -> dict:
	records = {
		key: source_record(key, role, cpu_address, data, relationship=relationship)
		for key, (role, cpu_address, data, relationship) in spans.items()
	}
	return {
		"schema": "slot15-callback-34-map-2d-rom-sources-v1",
		"source_rom_filename": ROM_PATH.name,
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"source_rom_size_bytes": EXPECTED_ROM_SIZE,
		"runtime_rom_dependency": False,
		"capture_or_screenshot_bytes_included": False,
		"bank_mapping": {
			"mapper": "MMC3",
			"prg_bank_size_bytes": PRG_BANK_SIZE,
			"prg_bank": "$0B",
			"cpu_window": "0x8000-0x9FFF",
			"file_window_base": f"0x{BANK_FILE_BASE:06X}",
			"file_offset_formula": "0x10 + (PRG bank * 0x2000) + (CPU address - 0x8000)",
			"semantics": "All listed CPU addresses are in the same switchable 8 KiB PRG bank-$0B window.",
		},
		"callback_selector": {
			"callback_id": "$34",
			"pointer_table_cpu_address": f"0x{CALLBACK_POINTER_TABLE_CPU:04X}",
			"entry_formula": "table CPU address + 2 * callback ID",
			"entry_cpu_address": f"0x{CALLBACK_POINTER_ENTRY_CPU:04X}",
			"entry_file_offset": f"0x{CALLBACK_POINTER_ENTRY_FILE:06X}",
			"pointer_bytes_hex": records["callback_34_script_pointer"]["bytes_hex"],
			"pointer_target_cpu_address": f"0x{SCRIPT_CPU:04X}",
			"pointer_target_file_offset": f"0x{SCRIPT_FILE:06X}",
			"script_bytes_hex": records["callback_34_map_2d_script"]["bytes_hex"],
		},
		"map_2d_resolution": {
			"map_id": "$2D",
			"packed_selector_table_cpu_address": f"0x{MAP_SELECTOR_TABLE_CPU:04X}",
			"selector_byte_cpu_address": f"0x{MAP_SELECTOR_CPU:04X}",
			"selector_byte_file_offset": f"0x{MAP_SELECTOR_FILE:06X}",
			"selector_byte_hex": records["map_2d_selector_source"]["bytes_hex"],
			"selector_formula": "(byte >> (2 * (map ID & 3))) & 3, using table[map ID >> 2]",
			"resolved_selector": f"0x{EXPECTED_MAP_SELECTOR:02X}",
			"chr_pair_table_cpu_address": f"0x{CHR_PAIR_TABLE_CPU:04X}",
			"chr_pair_cpu_address": f"0x{CHR_PAIR_CPU:04X}",
			"chr_pair_file_offset": f"0x{CHR_PAIR_FILE:06X}",
			"chr_pair_hex": records["map_2d_chr_pair"]["bytes_hex"],
			"map_block_cpu_address": f"0x{MAP_BLOCK_CPU:04X}",
			"map_block_file_offset": f"0x{MAP_BLOCK_FILE:06X}",
			"map_block_length_bytes": MAP_BLOCK_LENGTH,
		"map_block_address_formula": "0x8B64 + ((map ID >> 3) << 8) + ((map ID & 7) << 5)",
			"map_block_sha256": records["map_2d_block"]["sha256"],
		"neighboring_block_note": (
			f"CPU 0x{NEIGHBOR_MAP_BLOCK_CPU:04X} / file 0x{NEIGHBOR_MAP_BLOCK_FILE:06X} "
			f"is map ID 0x{NEIGHBOR_MAP_ID:02X} under the same formula; it is not map-$2D runtime data."
		),
		},
		"source_spans": list(records.values()),
		"unresolved_execution_order": [
			"The extracted spans do not establish when callback $34 runs relative to the map-$2D selector, CHR-pair, or block reads.",
			"No frame/cycle ordering, PPU write sequence, or APU behavior is derived by this static extraction.",
		"The 32-byte map-$2D block is preserved from the source address selected by the verified $8525 address formula; live consumer cadence and full presentation remain unverified.",
		],
	}


def main() -> None:
	if not ROM_PATH.is_file():
		raise SystemExit(f"Supplied ROM is missing: {ROM_PATH}")
	rom = ROM_PATH.read_bytes()
	rom_hash = sha256(rom)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_hash}")
	if len(rom) != EXPECTED_ROM_SIZE or rom[:4] != b"NES\x1a":
		raise SystemExit("Unexpected iNES header or ROM size")
	if BANK_FILE_BASE != EXPECTED_BANK_FILE_BASE:
		raise SystemExit("Bank-$0B file-window base calculation changed")

	callback_entry_cpu = CALLBACK_POINTER_TABLE_CPU + 2 * CALLBACK_ID
	if callback_entry_cpu != CALLBACK_POINTER_ENTRY_CPU \
			or file_offset(callback_entry_cpu) != CALLBACK_POINTER_ENTRY_FILE:
		raise SystemExit("Callback-$34 pointer-table location changed")
	callback_pointer = read_span(rom, callback_entry_cpu, 2)
	if callback_pointer != EXPECTED_CALLBACK_POINTER \
			or int.from_bytes(callback_pointer, "little") != SCRIPT_CPU:
		raise SystemExit("Callback-$34 pointer no longer resolves to $89E1")
	if file_offset(SCRIPT_CPU) != SCRIPT_FILE:
		raise SystemExit("Callback-$34 script file mapping changed")
	script = read_span(rom, SCRIPT_CPU, len(EXPECTED_SCRIPT))
	if script != EXPECTED_SCRIPT or script[2] != MAP_ID:
		raise SystemExit("Callback-$34 map-$2D script bytes changed")

	selector_table_index = MAP_ID >> 2
	selector_cpu = MAP_SELECTOR_TABLE_CPU + selector_table_index
	selector_shift = 2 * (MAP_ID & 3)
	selector_byte = read_span(rom, selector_cpu, 1)
	if selector_cpu != MAP_SELECTOR_CPU or file_offset(selector_cpu) != MAP_SELECTOR_FILE \
			or selector_byte != EXPECTED_MAP_SELECTOR_BYTE:
		raise SystemExit("Map-$2D packed selector source changed")
	resolved_selector = (selector_byte[0] >> selector_shift) & 0x03
	if resolved_selector != EXPECTED_MAP_SELECTOR:
		raise SystemExit("Map-$2D packed selector no longer resolves to $02")

	chr_cpu = CHR_PAIR_TABLE_CPU + MAP_ID * 2
	if chr_cpu != CHR_PAIR_CPU or file_offset(chr_cpu) != CHR_PAIR_FILE:
		raise SystemExit("Map-$2D CHR-pair table mapping changed")
	chr_pair = read_span(rom, chr_cpu, len(EXPECTED_CHR_PAIR))
	if chr_pair != EXPECTED_CHR_PAIR:
		raise SystemExit("Map-$2D CHR pair changed")
	if file_offset(MAP_BLOCK_CPU) != MAP_BLOCK_FILE:
		raise SystemExit("Map-$2D block file mapping changed")
	map_block_cpu = 0x8B64 + ((MAP_ID >> 3) << 8) + ((MAP_ID & 0x07) << 5)
	neighbor_map_block_cpu = 0x8B64 + ((NEIGHBOR_MAP_ID >> 3) << 8) + ((NEIGHBOR_MAP_ID & 0x07) << 5)
	if map_block_cpu != MAP_BLOCK_CPU or neighbor_map_block_cpu != NEIGHBOR_MAP_BLOCK_CPU \
			or file_offset(map_block_cpu) != MAP_BLOCK_FILE \
			or file_offset(neighbor_map_block_cpu) != NEIGHBOR_MAP_BLOCK_FILE:
		raise SystemExit("Map block address formula or neighboring map-$28 mapping changed")
	map_block = read_span(rom, map_block_cpu, MAP_BLOCK_LENGTH)
	if map_block != EXPECTED_MAP_BLOCK or sha256(map_block) != EXPECTED_MAP_BLOCK_SHA256 \
			or len(map_block) != MAP_BLOCK_LENGTH:
		raise SystemExit("Map-$2D 32-byte source block changed")

	spans = {
		"callback_34_script_pointer": (
			"Callback-$34 little-endian script pointer-table entry.",
			callback_entry_cpu,
			callback_pointer,
			"Entry $34 at $87F6 + 2*$34 points to script $89E1.",
		),
		"callback_34_map_2d_script": (
			"Three-byte callback-$34 script prefix containing map ID $2D.",
			SCRIPT_CPU,
			script,
			"Pointer-table target for callback selector $34; bytes are preserved without assigning other operand semantics.",
		),
		"map_2d_selector_source": (
			"Packed map-selector table byte used by map ID $2D.",
			selector_cpu,
			selector_byte,
			"Map ID $2D selects table index $0B and bit pair 2, resolving byte $6A to selector $02.",
		),
		"map_2d_chr_pair": (
			"Map-$2D pair from the bank-$0B CHR-selector table.",
			chr_cpu,
			chr_pair,
			"Two ROM bytes associated with the map-$2D table index; execution timing is not established here.",
		),
		"map_2d_block": (
			"32-byte bank-$0B source block associated with map $2D.",
			MAP_BLOCK_CPU,
			map_block,
			"Raw source span only; exact consumer order and presentation cadence are unresolved.",
		),
	}

	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	for key, filename in OUTPUTS.items():
		OUTPUT_DIR.joinpath(filename).write_bytes(spans[key][2])
	manifest = build_manifest(spans)
	MANIFEST_PATH.write_text(
		json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
		encoding="utf-8",
	)
	print(
		"Extracted callback $34 / map $2D spans: "
		f"pointer {callback_pointer.hex(' ').upper()} at 0x{file_offset(callback_entry_cpu):06X}, "
		f"script {script.hex(' ').upper()} at 0x{file_offset(SCRIPT_CPU):06X}, "
		f"selector {selector_byte[0]:02X}, CHR pair {chr_pair.hex(' ').upper()}, "
		f"map block sha256 {sha256(map_block)}"
	)


if __name__ == "__main__":
	main()
