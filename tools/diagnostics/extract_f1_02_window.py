#!/usr/bin/env python3
"""Extract the supplied ROM's F1 02 PPU packet stream unchanged."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
PRG_BANK = 6
BANK_CPU_BASE = 0xA000
BANK_FILE_BASE = 0x10 + PRG_BANK * 0x2000
POINTER_TABLE_CPU = 0xBB40
WINDOW_ID = 0x02
DATA_CPU = 0xBBE8
RECORD_HEADER_SIZE = 3


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def bank6_offset(cpu: int) -> int:
	if not BANK_CPU_BASE <= cpu < BANK_CPU_BASE + 0x2000:
		raise ValueError(f"CPU address ${cpu:04X} is outside bank 6")
	return BANK_FILE_BASE + cpu - BANK_CPU_BASE


def decode(rom: bytes) -> tuple[bytes, list[dict[str, object]]]:
	if sha256(rom) != ROM_SHA256:
		raise ValueError("ROM hash does not match the supplied Turkish revision")
	pointer_cpu = POINTER_TABLE_CPU + WINDOW_ID * 2
	pointer_offset = bank6_offset(pointer_cpu)
	pointer_bytes = rom[pointer_offset:pointer_offset + 2]
	if len(pointer_bytes) != 2 or int.from_bytes(pointer_bytes, "little") != DATA_CPU:
		raise ValueError("F1 02 pointer-table entry at bank-6 $BB44 is not $BBE8")
	start = bank6_offset(DATA_CPU)
	position = start
	records: list[dict[str, object]] = []
	while position + RECORD_HEADER_SIZE <= len(rom):
		header = rom[position]
		payload_size = header & 0x3F
		end = position + RECORD_HEADER_SIZE + payload_size
		if end > len(rom):
			raise ValueError(f"F1 02 record at file 0x{position:06X} is truncated")
			raw = rom[position:end]
		address = int.from_bytes(rom[position + 1:position + 3], "little") & 0x3FFF
		record_bytes = rom[position:end]
		records.append({
			"index": len(records),
			"cpu_address": DATA_CPU + position - start,
			"file_offset": position,
			"header": header,
			"payload_size": payload_size,
			"ppu_address": address,
			"increment": 32 if header & 0x80 else 1,
			"final": bool(header & 0x40),
			"sha256": sha256(record_bytes),
		})
		position = end
		if header & 0x40:
			stream = rom[start:position]
			if len(records) != 4 or len(stream) != 90:
				raise ValueError("F1 02 record count/stream size differs from the observed four-record source")
			return stream, records
	raise ValueError("F1 02 record list has no final marker")


def write_outputs(rom_path: Path, stream: bytes, records: list[dict[str, object]], root: Path) -> None:
	ref_dir = root / "reference/rom_extract/gameplay/meeting_menu"
	runtime_dir = root / "assets/gameplay/rom_logic"
	ref_dir.mkdir(parents=True, exist_ok=True)
	runtime_dir.mkdir(parents=True, exist_ok=True)
	ref_bin = ref_dir / "f1_02_window.bin"
	runtime_bin = runtime_dir / "f1_02_window.bin"
	ref_bin.write_bytes(stream)
	runtime_bin.write_bytes(stream)
	manifest = {
		"schema": "ct2-f1-02-ppu-window-v1",
		"rom": {"file": rom_path.name, "sha256": ROM_SHA256},
		"source": {
			"prg_bank": PRG_BANK,
			"bank_cpu_window": "$A000-$BFFF",
			"pointer_table_cpu": f"0x{POINTER_TABLE_CPU:04X}",
			"window_id": WINDOW_ID,
			"pointer_entry_cpu": "$BB44",
			"pointer_entry_file_offset": f"0x{bank6_offset(POINTER_TABLE_CPU + WINDOW_ID * 2):06X}",
			"pointer_entry_bytes": "E8 BB",
			"stream_cpu_start": f"0x{DATA_CPU:04X}",
			"stream_file_start": f"0x{bank6_offset(DATA_CPU):06X}",
			"stream_file_end_exclusive": f"0x{bank6_offset(DATA_CPU) + len(stream):06X}",
		},
		"resource": {
			"path": "assets/gameplay/rom_logic/f1_02_window.bin",
			"reference_path": "reference/rom_extract/gameplay/meeting_menu/f1_02_window.bin",
			"byte_length": len(stream),
			"sha256": sha256(stream),
			"byte_identity": "copied unchanged from the supplied ROM",
		},
		"format": {
			"header": "count=header&0x3F; bit 7 means PPU increment 32; bit 6 marks final record",
			"records": records,
		},
		"runtime_policy": {
			"source_queue": "The buffered F1 path reserves 11 ROM-defined 30-byte zero rows, then these table records.",
			"capacity_test": "queue cursor + requested payload >= 0x3D yields through $9FA8(A=1) and retries after the source NMI queue drain.",
			"runtime_uses_original_rom": False,
			"runtime_uses_capture": False,
		},
	}
	manifest_bytes = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
	(ref_dir / "f1_02_window.json").write_bytes(manifest_bytes)
	(runtime_dir / "f1_02_window.json").write_bytes(manifest_bytes)


def main() -> int:
	root = Path(__file__).resolve().parents[2]
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("rom", nargs="?", type=Path,
		default=root / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes")
	args = parser.parse_args()
	rom_path = args.rom.resolve()
	stream, records = decode(rom_path.read_bytes())
	write_outputs(rom_path, stream, records, root)
	print(f"Extracted F1 02 $BBE8 stream: {len(stream)} bytes, {len(records)} records")
	print(f"SHA-256: {sha256(stream)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
