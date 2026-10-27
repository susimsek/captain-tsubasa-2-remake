# ROM-driven PPU nametable screen renderer

`RomPpuNametableScreenRenderer` renders a 256×240 viewport from a supplied
PPU-address-to-byte dictionary. It reads its pattern pixels from the project's
byte-preserved CHR extract, applies NES attribute-table palette selection, and
uses the separately recorded FCEUX RGB palette for RGB conversion. The default
profile is background `$01`; `set_background_profile(id)` switches to another
extracted record and its ROM palette.

## Integration API

- `set_ppu_memory(memory: Dictionary)` replaces the modeled PPU memory image.
  Keys are integer addresses such as `0x2000` and values are byte values.
- `set_background_palette_bytes(bytes: PackedByteArray)` supplies the current
  16-byte background palette from the modeled PPU palette state.
- `set_scroll_pixels(x: int, y: int = 0)` selects a viewport across two
  horizontally adjacent nametables. With no call, scroll starts at `(0, 0)`.
- `set_raster_chr_split(upper_banks, lower_banks, split_scanline)` supplies
  four 1 KiB CHR banks for each side of a visible scanline split. The current
  F9 01 runner profile uses upper banks `[60, 61, 62, 63]`, lower banks
  `[0, 1, 2, 3]`, and scanline 134.

The source-command prototype passes its modeled PPU memory after NMI packet
commits. A source palette packet can override the selected background record's
default 16-byte palette. The renderer can be displayed as a child node at
`(0, 0)` in the 256×240 source viewport.

## ROM sources and assumptions

- Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Pattern bytes: `reference/rom_extract/chr_rom.2bpp`.
- Background records/layouts and block mappings: `background_XX.bin` and
  `background_XX_layout.json`, checked against their preserved byte manifests.
- The active profile's 16-byte ROM palette is read from its layout. Callers
  can override it with bytes from a source-command palette operation.
- RGB conversion table: `reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal`.
- Nametable 0 and 1 are interpreted as a horizontal 512-pixel world. Scroll
  defaults to zero because the presenter does not yet supply the game's PPU
  scroll registers.
- Missing nametable bytes render as zero. The current loader fills only the
  ROM-derived packet addresses and separately modeled source zero-fills; this
  renderer does not fabricate missing tilemap bytes.

This is an intermediate screen renderer. It does not model vertical or
horizontal mirroring aliases, fine PPU scroll registers, OAM sprites,
emphasis bits, or PPU fetch-pipeline delays. The runner's MMC3 bank writes for
background `$01` are observed on scanline 134 at dots 131–213. The renderer
applies lower banks `[0, 1, 2, 3]` starting at pixel row 134 as an explicit
scanline-level approximation; it does not establish the first affected pixel
or reproduce the 2C02 fetch pipeline. Other profiles hold their four selected
CHR banks across the view. Its output is not yet a full frame-matched opening
screen and has not been runtime-validated.
