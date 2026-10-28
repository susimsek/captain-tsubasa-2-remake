#!/usr/bin/env python3
"""Preserve the target-ROM action-selection blink data for the first menu."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/menus/first_action_menu"
TARGET_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
FIXED_BASE = 0x3C010
WINDOW_CODE = (0xD638, 0xD679)
ACTION_MAP = (0xD6DE, 4)
POINTER_TABLE = (0xE9DA, 8)
STREAM_RANGE = (0xEA1C, 0xEA46)
RENDERER_CODE = (0xE93D, 0xE9D9)
RECEIVER_CODE = (0xDAF2, 0xDB19)
RECEIVER_OFFSETS = (0xDC82, 5)
RNG_UPDATE_BANK = 2
RNG_UPDATE_CODE = (0x8117, 0x8137)


def fixed_file_offset(cpu_address: int) -> int:
    return FIXED_BASE + cpu_address - 0xC000


def bank_file_offset(bank: int, cpu_address: int) -> int:
    return 16 + bank * 0x2000 + cpu_address - 0x8000


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha = sha256(rom)
    if rom_sha != TARGET_SHA256:
        raise SystemExit(f"Unexpected target ROM SHA-256: {rom_sha}")

    def read(cpu: int, size: int) -> bytes:
        start = fixed_file_offset(cpu)
        return rom[start : start + size]

    def read_bank(bank: int, cpu: int, size: int) -> bytes:
        start = bank_file_offset(bank, cpu)
        return rom[start : start + size]

    action_map = read(*ACTION_MAP)
    pointer_bytes = read(*POINTER_TABLE)
    stream_start, stream_end = STREAM_RANGE
    streams = read(stream_start, stream_end - stream_start)
    receiver_offsets = read(*RECEIVER_OFFSETS)
    rng_start, rng_end = RNG_UPDATE_CODE
    rng_update = read_bank(RNG_UPDATE_BANK, rng_start, rng_end - rng_start + 1)
    if len(action_map) != 4 or len(pointer_bytes) != 8 or len(streams) != 42 or len(receiver_offsets) != 5:
        raise SystemExit("Unexpected first-action blink table sizes.")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = {
        "action_id_to_render_variant_context_00.bin": (ACTION_MAP[0], action_map),
        "action_render_variant_pointer_table_00_03.bin": (POINTER_TABLE[0], pointer_bytes),
        "action_label_render_streams_EA1C_EA45.bin": (stream_start, streams),
        "first_match_receiver_offsets_DC82.bin": (RECEIVER_OFFSETS[0], receiver_offsets),
    }
    for name, (_cpu_address, data) in outputs.items():
        (OUT_DIR / name).write_bytes(data)

    action_names = {
        0: "shoot",
        1: "pass",
        2: "dribble",
        3: "one_two_pass",
    }
    records = []
    for action_id in range(4):
        variant = action_map[action_id]
        pointer_at = variant * 2
        pointer = pointer_bytes[pointer_at] | (pointer_bytes[pointer_at + 1] << 8)
        offset = pointer - stream_start
        header = streams[offset : offset + 3]
        if len(header) != 3:
            raise SystemExit(f"Invalid action label pointer ${pointer:04X}.")
        ppu_address = header[0] | (header[1] << 8)
        shape = header[2]
        rows = shape & 0x03
        width = shape >> 2
        cursor = offset + 3
        for _row in range(rows):
            remaining = width
            while remaining:
                if cursor >= len(streams):
                    raise SystemExit(f"Truncated action-label record at ${pointer:04X}.")
                tile = streams[cursor]
                cursor += 1
                if tile == 0xFE:
                    break
                remaining -= 1
        record_bytes = streams[offset:cursor]
        records.append(
            {
                "action_id": action_id,
                "action": action_names[action_id],
                "render_variant": variant,
                "stream_cpu_address": f"${pointer:04X}",
                "stream_offset": offset,
                "stream_bytes_hex": record_bytes.hex(" ").upper(),
                "ppu_address": f"${ppu_address:04X}",
                "row_count": rows,
                "payload_width": width,
            }
        )

    code = read(WINDOW_CODE[0], WINDOW_CODE[1] - WINDOW_CODE[0] + 1)
    renderer_code = read(RENDERER_CODE[0], RENDERER_CODE[1] - RENDERER_CODE[0] + 1)
    receiver_code = read(RECEIVER_CODE[0], RECEIVER_CODE[1] - RECEIVER_CODE[0] + 1)
    metadata = {
        "target_rom": ROM_PATH.name,
        "target_rom_sha256": rom_sha,
        "parser_method": (
            "Fixed-bank CPU addresses map to file offset 0x03C010 + (CPU-$C000). "
            "Context-0 action IDs index $D6DE. That render variant indexes the "
            "little-endian pointer table at $E9DA. Each selected stream begins "
            "with PPU low/high and a packed shape byte (low two bits row count, "
            "upper six bits row payload width). $FE fills the rest of that row "
            "with zero tiles. The high-bit suppression path in $E93D emits zero "
            "tiles for every cell; it does not change PPU attributes."
        ),
        "source": {
            "input_handler_cpu_range": [f"${WINDOW_CODE[0]:04X}", f"${WINDOW_CODE[1]:04X}"],
            "input_handler_file_range": [
                f"0x{fixed_file_offset(WINDOW_CODE[0]):06X}",
                f"0x{fixed_file_offset(WINDOW_CODE[1]):06X}",
            ],
            "input_handler_sha256": sha256(code),
            "action_renderer_cpu_range": [f"${RENDERER_CODE[0]:04X}", f"${RENDERER_CODE[1]:04X}"],
            "action_renderer_file_range": [
                f"0x{fixed_file_offset(RENDERER_CODE[0]):06X}",
                f"0x{fixed_file_offset(RENDERER_CODE[1]):06X}",
            ],
            "action_renderer_sha256": sha256(renderer_code),
            "receiver_formula_cpu_range": [f"${RECEIVER_CODE[0]:04X}", f"${RECEIVER_CODE[1]:04X}"],
            "receiver_formula_file_range": [
                f"0x{fixed_file_offset(RECEIVER_CODE[0]):06X}",
                f"0x{fixed_file_offset(RECEIVER_CODE[1]):06X}",
            ],
            "receiver_formula_sha256": sha256(receiver_code),
            "action_map_cpu": f"${ACTION_MAP[0]:04X}",
            "action_map_file_offset": f"0x{fixed_file_offset(ACTION_MAP[0]):06X}",
            "pointer_table_cpu": f"${POINTER_TABLE[0]:04X}",
            "pointer_table_file_offset": f"0x{fixed_file_offset(POINTER_TABLE[0]):06X}",
            "stream_cpu_range": [f"${stream_start:04X}", f"${stream_end - 1:04X}"],
            "stream_file_range": [
                f"0x{fixed_file_offset(stream_start):06X}",
                f"0x{fixed_file_offset(stream_end - 1):06X}",
            ],
            "receiver_offsets_cpu": f"${RECEIVER_OFFSETS[0]:04X}",
            "receiver_offsets_file_offset": f"0x{fixed_file_offset(RECEIVER_OFFSETS[0]):06X}",
            "rng_update_bank": f"${RNG_UPDATE_BANK:02X}",
            "rng_update_cpu_range": [f"${rng_start:04X}", f"${rng_end:04X}"],
            "rng_update_file_range": [
                f"0x{bank_file_offset(RNG_UPDATE_BANK, rng_start):06X}",
                f"0x{bank_file_offset(RNG_UPDATE_BANK, rng_end):06X}",
            ],
            "rng_update_sha256": sha256(rng_update),
        },
        "runtime_exports": {
            name: {
                "cpu_start": f"${cpu_address:04X}",
                "file_start": f"0x{fixed_file_offset(cpu_address):06X}",
                "length": len(data),
                "sha256": sha256(data),
                "bytes_hex": data.hex(" ").upper(),
            }
            for name, (cpu_address, data) in outputs.items()
        },
        "action_id_to_variant": list(action_map),
        "records": records,
        "validation_boundary": (
            "The captured unselected state is consistent with no selection overlay, "
            "but no same-input selected-action FCEUX probe was captured. These ROM "
            "packets are source-derived candidates, not a same-input visual proof. "
            "The capture observes the receiver transition to slot 6 at frame 8782 "
            "with $E2=$11, which maps through $DC82 to 6; the cold-start-to-write "
            "$E2 state/count is not reconstructed here."
        ),
    }
    (OUT_DIR / "action_blink_source_audit.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({"rom_sha256": rom_sha, "records": records}, indent=2))


if __name__ == "__main__":
    main()
