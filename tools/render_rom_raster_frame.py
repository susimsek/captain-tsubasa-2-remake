#!/usr/bin/env python3
"""Render raster bands from exact ROM CHR bytes and captured layout state.

The plan describes which ROM CHR banks and PPU scroll settings were active
for each vertical band. PPU/RAM snapshots supply nametable, palette-index,
and OAM layout only. Screenshot pixels are never read or copied.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from render_emulator_ppu_frame import (
    HEIGHT,
    WIDTH,
    background_pixels,
    decode_tiles,
    encode_png,
    read_palette_file,
    render_sprites,
    resolve_snapshot,
)
from render_rom_frame import CHR_BANK, extract_chr


def render_band(chr_rom: bytes, ppu_snapshot: bytes, ram_snapshot: bytes,
                band: dict[str, object]) -> list[int]:
    banks = band["chr_banks_by_ppu_slot"]
    if not isinstance(banks, list) or len(banks) != 8:
        raise ValueError("Each band needs exactly eight CHR bank numbers")
    mapped = bytearray(ppu_snapshot)
    for slot, bank in enumerate(banks):
        if not isinstance(bank, int) or not 0 <= bank < len(chr_rom) // CHR_BANK:
            raise ValueError(f"Invalid CHR bank {bank!r} in slot {slot}")
        mapped[slot * CHR_BANK:(slot + 1) * CHR_BANK] = (
            chr_rom[bank * CHR_BANK:(bank + 1) * CHR_BANK]
        )
    page = int(band.get("nametable_page", 0))
    bg_base = int(band.get("background_pattern_base", 0))
    sprite_base = int(band.get("sprite_pattern_base", 0))
    scroll_x = int(band.get("scroll_x", 0))
    scroll_y = int(band.get("scroll_y", 0))
    if bool(band.get("background_enabled", True)):
        bg, opaque = background_pixels(
            bytes(mapped), page=page, pattern_base=bg_base,
            scroll_x=scroll_x, scroll_y=scroll_y,
        )
        # $2005 Y=$FF loads coarse Y=31/fine Y=7 into loopy v at pre-render.
        # Unlike ordinary 240-line wrap, the first visible scanline fetches
        # tile bytes from nametable offsets $3E0-$3FF (the attribute area).
        # Render that hardware edge from the raw nametable/CHR bytes so the
        # diagnostic does not approximate it as a wrapped row 15/0.
        if (scroll_y & 0xFF) == 0xFF:
            line, line_opaque = loopy_first_scanline(
                bytes(mapped), page=page, pattern_base=bg_base,
                scroll_x=scroll_x, scroll_y=scroll_y,
            )
            bg[:WIDTH] = line
            opaque[:WIDTH] = line_opaque
    else:
        backdrop_index = mapped[0x3000] & 0x3F
        bg = [backdrop_index] * (WIDTH * HEIGHT)
        opaque = [False] * (WIDTH * HEIGHT)
    return render_sprites(
        bytes(mapped), ram_snapshot, bg, opaque,
        enabled=bool(band.get("sprites_enabled", True)),
        sprite_height=int(band.get("sprite_height", 8)),
        pattern_base=sprite_base,
        y_offset=int(band.get("oam_y_offset", 1)),
    )


def loopy_first_scanline(ppu: bytes, *, page: int, pattern_base: int,
                         scroll_x: int, scroll_y: int) -> tuple[list[int], list[bool]]:
    """Decode visible row 0 when pre-render loopy v starts at coarseY 31."""
    nametables = ppu[0x2000:0x3000]
    palette_ram = ppu[0x3000:0x3020]
    coarse_y, fine_y = (scroll_y >> 3) & 0x1F, scroll_y & 7
    world_x_start = scroll_x & 0xFF
    colors: list[int] = []
    opaque: list[bool] = []
    tile_cache: dict[int, list[list[int]]] = {}
    for screen_x in range(WIDTH):
        world_x = world_x_start + screen_x
        coarse_x, fine_x = (world_x // 8) & 0x1F, world_x & 7
        page_x = ((page & 1) + world_x // 256) & 1
        page_y = (page >> 1) & 1
        page_offset = (page_x | (page_y << 1)) * 0x400
        tile = nametables[page_offset + coarse_y * 32 + coarse_x]
        attr = nametables[page_offset + 960 + (coarse_y // 4) * 8 + coarse_x // 4]
        shift = ((coarse_y % 4) // 2) * 4 + ((coarse_x % 4) // 2) * 2
        subpalette = (attr >> shift) & 3
        decoded = tile_cache.get(tile)
        if decoded is None:
            decoded = decode_tiles(ppu[:0x2000], tile, pattern_base)
            tile_cache[tile] = decoded
        color = decoded[fine_y][fine_x]
        colors.append((palette_ram[0 if color == 0 else subpalette * 4 + color]) & 0x3F)
        opaque.append(color != 0)
    return colors, opaque


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--frame", type=int, required=True)
    parser.add_argument("--palette-file", type=Path, required=True)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    bands = plan.get("bands")
    if not isinstance(bands, list) or not bands:
        raise ValueError("Plan must contain a nonempty bands array")
    chr_rom, chr_file_offset, rom_hash = extract_chr(args.rom)
    ppu_path, ppu_frame = resolve_snapshot(args.capture_dir, "ppu", args.frame)
    ram_path, ram_frame = resolve_snapshot(args.capture_dir, "ram", args.frame)
    ppu_snapshot = ppu_path.read_bytes()
    ram_snapshot = ram_path.read_bytes()
    rgb_palette = read_palette_file(args.palette_file)
    result: list[int | None] = [None] * (WIDTH * HEIGHT)

    for band in bands:
        if not isinstance(band, dict):
            raise ValueError("Each band must be a JSON object")
        start = band.get("start_y")
        end = band.get("end_y")
        if not isinstance(start, int) or not isinstance(end, int) or not 0 <= start < end <= HEIGHT:
            raise ValueError(f"Invalid half-open scanline band [{start}, {end})")
        rendered = render_band(chr_rom, ppu_snapshot, ram_snapshot, band)
        begin_pixel, end_pixel = start * WIDTH, end * WIDTH
        if any(pixel is not None for pixel in result[begin_pixel:end_pixel]):
            raise ValueError(f"Overlapping scanline band [{start}, {end})")
        result[begin_pixel:end_pixel] = rendered[begin_pixel:end_pixel]

    if any(pixel is None for pixel in result):
        raise ValueError("Plan bands must cover all 240 scanlines")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    encode_png(args.output, (rgb_palette[pixel] for pixel in result if pixel is not None))
    metadata = {
        "source_rom": args.rom.name,
        "rom_sha256": rom_hash,
        "chr_file_offset": f"0x{chr_file_offset:X}",
        "layout_reference": str(ppu_path),
        "oam_shadow_reference": str(ram_path),
        "requested_frame": args.frame,
        "ppu_snapshot_frame": ppu_frame,
        "ram_snapshot_frame": ram_frame,
        "palette_file_external_to_rom": str(args.palette_file),
        "raster_plan": str(args.plan),
        "trace_reference": plan.get("trace_reference"),
        "chr_switch_cpu_cycle": plan.get("chr_switch_cpu_cycle"),
        "chr_switch_visible_scanline": plan.get("chr_switch_visible_scanline"),
        "bands": bands,
        "validation_status": plan.get("validation_status", "unvalidated diagnostic"),
    }
    args.output.with_suffix(".json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Rendered {args.output} from original ROM CHR with {len(bands)} raster bands")


if __name__ == "__main__":
    main()
