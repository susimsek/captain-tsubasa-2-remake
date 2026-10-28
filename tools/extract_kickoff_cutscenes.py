#!/usr/bin/env python3
"""Preserve the supplied ROM's KICK OFF cutscene script spans byte-for-byte.

This offline extractor creates research resources only. Godot does not read the
ROM, and this script does not claim that pointer spans alone describe runtime
command order, timing, graphics, or sound.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
POINTER_TABLE_FILE_OFFSET = 0x6010
POINTER_TABLE_PRG_BANK = 0x03
PRG_BANK_FILE_BASE = 0x10 + POINTER_TABLE_PRG_BANK * 0x2000
CUTSCENE_IDS = (1, 2)


def source_file_offset(cpu_address: int) -> int:
    return PRG_BANK_FILE_BASE + cpu_address - 0xA000


def find_linear_execution_end(rom: bytes, start_cpu: int) -> int:
    """Find the first FF reached by the supplied ROM's linear bytecode parser.

    In this ROM, FC dispatches to bank-0 $8837 and advances the script pointer
    by exactly one byte. Reachable FE branches need a separately traced bound.
    """
    cpu = start_cpu
    while True:
        offset = source_file_offset(cpu)
        opcode = rom[offset]
        if opcode <= 0xD7:
            cpu += 1
            while rom[source_file_offset(cpu)] <= 0xD7:
                cpu += 1
        elif 0xD8 <= opcode <= 0xE7 or opcode in (
            0xE9, 0xEA, 0xEB, 0xEE, 0xEF, 0xF7, 0xFC, 0xFD, 0xFF,
        ):
            cpu += 1
            if opcode == 0xFF:
                return cpu
        elif opcode == 0xFB:
            cpu += 2 + rom[offset + 1]
        elif opcode == 0xF0:
            cpu += 3
        elif opcode == 0xF3:
            cpu += 4 if rom[offset + 1] == 0xFF else 2
        elif opcode in (0xE8, 0xEC, 0xED, 0xF1, 0xF2, 0xF4, 0xF5, 0xF6, 0xF8, 0xF9, 0xFA):
            cpu += 2
        elif opcode == 0xFE:
            raise ValueError(f"Reachable FE branch at CPU ${cpu:04X}; trace its target before extraction")
        else:
            raise ValueError(f"Unknown opcode ${opcode:02X} at CPU ${cpu:04X}")
        if cpu >= 0xC000:
            raise ValueError("Cutscene parser crossed the mapped bank boundary before FF.")


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha256 = hashlib.sha256(rom).hexdigest()
    if rom_sha256 != EXPECTED_ROM_SHA256:
        raise SystemExit(f"Supplied ROM SHA-256 mismatch: {rom_sha256}")
    if rom[:4] != b"NES\x1a" or len(rom) != 0x60010:
        raise SystemExit("Unexpected iNES header or ROM size.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for cutscene_id in CUTSCENE_IDS:
        pointer_file_offset = POINTER_TABLE_FILE_OFFSET + cutscene_id * 2
        start_cpu = int.from_bytes(rom[pointer_file_offset:pointer_file_offset + 2], "little")
        next_file_offset = pointer_file_offset + 2
        next_cpu = int.from_bytes(rom[next_file_offset:next_file_offset + 2], "little")
        if not (0xA000 <= start_cpu < next_cpu <= 0xC000):
            raise SystemExit(f"Cutscene {cutscene_id} has an invalid pointer-table span.")
        start_file_offset = source_file_offset(start_cpu)
        end_file_offset = source_file_offset(next_cpu)
        script = rom[start_file_offset:end_file_offset]
        if not script or len(script) != end_file_offset - start_file_offset:
            raise SystemExit(f"Cutscene {cutscene_id} source span is truncated.")

        stem = f"kickoff_cutscene_{cutscene_id:02d}"
        binary_path = OUTPUT_DIR / f"{stem}.bin"
        metadata_path = OUTPUT_DIR / f"{stem}.json"
        binary_path.write_bytes(script)
        execution_end_cpu = find_linear_execution_end(rom, start_cpu)
        execution_start_file_offset = source_file_offset(start_cpu)
        execution_end_file_offset = source_file_offset(execution_end_cpu)
        execution_stream = rom[execution_start_file_offset:execution_end_file_offset]
        execution_binary_path = OUTPUT_DIR / f"{stem}_execution.bin"
        execution_binary_path.write_bytes(execution_stream)
        metadata = {
            "name": f"supplied_turkish_rom_cutscene_{cutscene_id:02d}",
            "source_rom_sha256": rom_sha256,
            "source_rom_size_bytes": len(rom),
            "prg_bank": POINTER_TABLE_PRG_BANK,
            "pointer_table_file_offset": f"0x{pointer_file_offset:06X}",
            "pointer_table_cpu_address": f"0x{0xA000 + pointer_file_offset - POINTER_TABLE_FILE_OFFSET:04X}",
            "start_cpu_address": f"0x{start_cpu:04X}",
            "next_pointer_cpu_address": f"0x{next_cpu:04X}",
            "source_file_range": [f"0x{start_file_offset:06X}", f"0x{end_file_offset:06X}"],
            "length_bytes": len(script),
            "source_sha256": hashlib.sha256(script).hexdigest(),
            "preserved_resource": f"reference/rom_extract/gameplay/{stem}.bin",
            "pointer_span_only": False,
            "execution_stream_cpu_range": [f"0x{start_cpu:04X}", f"0x{execution_end_cpu - 1:04X}"],
            "execution_stream_file_range": [f"0x{execution_start_file_offset:06X}", f"0x{execution_end_file_offset:06X}"],
            "execution_stream_length_bytes": len(execution_stream),
            "execution_stream_sha256": hashlib.sha256(execution_stream).hexdigest(),
            "execution_stream_resource": f"reference/rom_extract/gameplay/{stem}_execution.bin",
            "execution_boundary_method": "first linear FF using the supplied ROM interpreter widths; FC is a one-byte handler at bank-0 $8837; no reachable FE branch in these streams",
            "runtime_logic_decoded": False,
            "notes": "Pointer span and linear execution span both end at the first reachable FF. Command byte boundaries are ROM-interpreter verified; per-command runtime timing, graphics and audio still require separate reconstruction.",
        }
        metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        print(f"{stem}: ${start_cpu:04X}-${next_cpu - 1:04X}, {len(script)} bytes, {metadata['source_sha256']}")


if __name__ == "__main__":
    main()
