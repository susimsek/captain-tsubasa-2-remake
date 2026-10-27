#!/usr/bin/env python3
"""Render a diagnostic frame using graphics decoded from the supplied ROM.

The PPU/RAM snapshot supplies layout, palette indices, and OAM placement only.
All 2bpp pattern pixels are read from exact 1 KiB CHR-ROM banks; the snapshot's
pattern bytes are used solely to identify which physical ROM bank was mapped.
The screenshot/WAV captures are never read by this tool.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from render_emulator_ppu_frame import (
    PPU_BYTES,
    background_pixels,
    encode_png,
    read_palette_file,
    render_sprites,
    resolve_snapshot,
)

ROM_HEADER = 16
PRG_BANK = 16_384
CHR_BANK = 1_024


def extract_chr(rom_path: Path) -> tuple[bytes, int, str]:
    rom = rom_path.read_bytes()
    if len(rom) < ROM_HEADER or rom[:4] != b"NES\x1a":
        raise ValueError(f"Not an iNES ROM: {rom_path}")
    trainer_bytes = 512 if rom[6] & 0x04 else 0
    prg_bytes = rom[4] * PRG_BANK
    chr_bytes = rom[5] * 8_192
    if chr_bytes == 0:
        raise ValueError("ROM uses CHR-RAM; this extraction path requires CHR-ROM")
    start = ROM_HEADER + trainer_bytes + prg_bytes
    end = start + chr_bytes
    if end > len(rom):
        raise ValueError("ROM is truncated before the declared CHR-ROM end")
    if (end - start) % CHR_BANK:
        raise ValueError("CHR-ROM size is not a whole number of 1 KiB MMC3 banks")
    return rom[start:end], start, hashlib.sha256(rom).hexdigest()


def map_pattern_banks(ppu: bytes, chr_rom: bytes) -> tuple[bytes, list[int]]:
    if len(ppu) != PPU_BYTES:
        raise ValueError(f"PPU state must be {PPU_BYTES} bytes, got {len(ppu)}")
    bank_lookup: dict[bytes, int] = {}
    for bank in range(len(chr_rom) // CHR_BANK):
        bank_data = chr_rom[bank * CHR_BANK:(bank + 1) * CHR_BANK]
        bank_lookup.setdefault(bank_data, bank)

    mapped_rom_patterns = bytearray()
    physical_banks: list[int] = []
    captured_patterns = ppu[:0x2000]
    for slot in range(8):
        captured_bank = captured_patterns[slot * CHR_BANK:(slot + 1) * CHR_BANK]
        physical_bank = bank_lookup.get(captured_bank)
        if physical_bank is None:
            raise ValueError(
                f"PPU slot {slot} does not exactly match any original 1 KiB CHR-ROM bank; "
                "the frame may use CHR-RAM or the selected capture may be incomplete."
            )
        physical_banks.append(physical_bank)
        start = physical_bank * CHR_BANK
        mapped_rom_patterns.extend(chr_rom[start:start + CHR_BANK])
    # Keep the snapshot's nametable, attributes and PPU palette RAM, replacing
    # its pattern memory with bytes directly sliced from the supplied ROM.
    return bytes(mapped_rom_patterns) + ppu[0x2000:], physical_banks


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True, help="Supplied iNES ROM")
    parser.add_argument("--capture-dir", type=Path, required=True,
                        help="FCEUX capture folder with PPU/RAM indexes")
    parser.add_argument("--frame", type=int, required=True,
                        help="Use the latest PPU/RAM snapshot at or before this frame")
    parser.add_argument("--palette-file", type=Path, required=True,
                        help="64 RGB entries (192 bytes); NES RGB palette is external to ROM")
    parser.add_argument("--output", type=Path, required=True, help="Godot-ready PNG output")
    parser.add_argument("--nametable-page", type=int, default=0, choices=range(4))
    parser.add_argument("--background-pattern-base", type=lambda s: int(s, 0), default=0,
                        choices=(0, 0x1000))
    parser.add_argument("--scroll-x", type=int, default=0)
    parser.add_argument("--scroll-y", type=int, default=0)
    parser.add_argument("--no-sprites", action="store_true")
    parser.add_argument("--sprite-height", type=int, default=8, choices=(8, 16))
    parser.add_argument("--sprite-pattern-base", type=lambda s: int(s, 0), default=0,
                        choices=(0, 0x1000))
    parser.add_argument("--oam-y-offset", type=int, default=1)
    parser.add_argument("--nametable-write", action="append", default=[],
                        metavar="PPU_ADDRESS=VALUE",
                        help="Apply a documented ROM-driven nametable tile write, e.g. 0x224A=0x7F")
    args = parser.parse_args()

    chr_rom, chr_file_offset, rom_hash = extract_chr(args.rom)
    ppu_path, ppu_frame = resolve_snapshot(args.capture_dir, "ppu", args.frame)
    ram_path, ram_frame = resolve_snapshot(args.capture_dir, "ram", args.frame)
    ppu = ppu_path.read_bytes()
    ram = ram_path.read_bytes()
    mapped_ppu, physical_banks = map_pattern_banks(ppu, chr_rom)
    mapped_mutable = bytearray(mapped_ppu)
    documented_writes: list[dict[str, str]] = []
    for item in args.nametable_write:
        try:
            raw_address, raw_value = item.split("=", 1)
            address, value = int(raw_address, 0), int(raw_value, 0)
        except ValueError as exc:
            raise ValueError(f"Invalid nametable write {item!r}") from exc
        if not 0x2000 <= address <= 0x2FFF or not 0 <= value <= 0xFF:
            raise ValueError(f"Nametable write outside valid range: {item!r}")
        mapped_mutable[address] = value
        documented_writes.append({"ppu_address": f"0x{address:04X}", "tile_id": f"0x{value:02X}"})
    mapped_ppu = bytes(mapped_mutable)
    palette_rgb = read_palette_file(args.palette_file)

    bg_indices, bg_opaque = background_pixels(
        mapped_ppu, page=args.nametable_page,
        pattern_base=args.background_pattern_base,
        scroll_x=args.scroll_x, scroll_y=args.scroll_y,
    )
    pixel_indices = render_sprites(
        mapped_ppu, ram, bg_indices, bg_opaque, enabled=not args.no_sprites,
        sprite_height=args.sprite_height, pattern_base=args.sprite_pattern_base,
        y_offset=args.oam_y_offset,
    )
    encode_png(args.output, (palette_rgb[index] for index in pixel_indices))

    metadata = {
        "source_rom": args.rom.name,
        "rom_sha256": rom_hash,
        "chr_file_offset": f"0x{chr_file_offset:X}",
        "chr_bank_size": CHR_BANK,
        "source_chr_banks_by_ppu_slot": physical_banks,
        "layout_reference": str(ppu_path),
        "oam_reference": str(ram_path),
        "requested_frame": args.frame,
        "ppu_snapshot_frame": ppu_frame,
        "ram_snapshot_frame": ram_frame,
        "palette_file_external_to_rom": str(args.palette_file),
        "nametable_page_assumption": args.nametable_page,
        "background_pattern_base_assumption": args.background_pattern_base,
        "sprite_height_assumption": args.sprite_height,
        "sprite_pattern_base_assumption": args.sprite_pattern_base,
        "scroll_assumption": [args.scroll_x, args.scroll_y],
        "oam_y_offset_assumption": args.oam_y_offset,
        "rom_driven_nametable_writes": documented_writes,
    }
    metadata_path = args.output.with_suffix(".json")
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
                             encoding="utf-8")
    print(f"Rendered {args.output} from original ROM CHR banks {physical_banks}.")
    print(f"Layout/OAM reference frames: PPU {ppu_frame}, RAM {ram_frame}; metadata: {metadata_path}")


if __name__ == "__main__":
    main()
