# ROM background 01 atlas renderer

`scripts/opening/rom_background_01_renderer.gd` decodes the field background's
two-nametable atlas from project-owned ROM extracts. It does not load the NES
file, emulator output, or captured pixels at runtime.

## Source mapping

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Background record: `reference/rom_extract/intro/background_01.bin`, file
  offset `0x00E0EF`, CPU `$A0DF`; the renderer checks those preserved bytes
  against `background_01_layout.json` before drawing.
- The record selects 1 KiB CHR banks 60–63. Tile patterns are decoded from
  `reference/rom_extract/chr_rom.2bpp`.
- Palette bytes come from
  `reference/rom_extract/intro/background_palette_02.bin` and are checked
  against the layout metadata. NES RGB values come from the separately stored
  `reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal`.
- ROM block/metatile decoding is represented by the 1,024 tile placements in
  `reference/rom_extract/intro/background_01_layout.json`. The resulting atlas
  is 512×128 pixels (64×16 tiles), covering the decoded two-nametable layout.

The project's ROM decoder reports that this layout's 1,024 tile IDs and 64
attribute bytes match the independent frame-380 PPU snapshot. The snapshot
provides validation evidence only; the renderer consumes the ROM-derived
record, CHR, palette, and layout data.

## Limits

This is an atlas renderer, not a complete field frame. It does not apply PPU
scroll/mirroring, compose OAM sprites, or reproduce the MMC3 mid-frame CHR
switch documented in `reference/rom_extract/intro/field_runner_chr_raster_split_trace.md`.
That trace places the bank update at scanline 134, but does not yet establish
the first affected pixel because the 2C02 pattern-fetch pipeline is unresolved.
