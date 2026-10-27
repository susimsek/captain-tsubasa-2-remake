# ROM background 00 renderer prototype

`scenes/prototypes/rom_background_00.tscn` is a standalone, background-only
Godot renderer for the Tecmo Theater logo scene. It decodes pixels from
project-owned ROM CHR and palette bytes. It does not load an emulator image or
the `.nes` file at runtime.

## Pixel sources

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Background 00 record: PRG bank 7, file offset `0x00E0E4`, CPU `$A0D4`,
  preserved at `reference/rom_extract/intro/background_00.bin`. It selects
  CHR 1 KiB pages `[124, 125, 126, 127]` and palette record 1.
- CHR bytes: `reference/rom_extract/chr_rom.2bpp`, 131,072 bytes. Tile pixels
  use 16-byte NES 2bpp patterns (eight low-plane rows, then eight high-plane
  rows; most-significant bit first).
- Background palette: `reference/rom_extract/intro/background_palette_01.bin`,
  PRG bank 6 file offset `0x00D020`. NES color indices are converted using
  `reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal`, an external
  FCEUX 2.7.0 RGB palette because RGB values are not stored in the ROM.
- The F9 record's metatiles `0x22–0x24` remain byte-preserved in
  `block_22.bin`–`block_24.bin`. Their 48 placements do not match the title
  tile IDs written to the visible nametable, so the renderer no longer treats
  those placements as the complete visible logo layer.

## Validated title nametable mapping

`reference/rom_extract/intro/background_00_nametable_layout.json` contains 25
nonzero tile placements and their NES attribute subpalette IDs. The mapping is
transcribed from nametable 0 in
`reference/opening_reference_capture/ppu_states/ppu_000026.bin` (capture frame
26): `$2000–$23BF` supplies tile IDs and `$23C0–$23FF` supplies attributes.
Only this layout mapping is retained; the captured PPU image/pattern state is
not loaded by Godot. The runtime resolves each tile against the ROM CHR bytes
and resolves color indices against the ROM palette record.

The mapping is independently supported by ROM-driven PPU bus writes in
`reference/opening_timing_capture_20261024_131000/bus_events.csv` at source
frames 10–11. The title tile map is written in packets beginning at `$218C`,
`$21AC`, `$21CC`, `$21EC`, `$2190`, `$21B0`, `$21D0`, `$2194`, `$21B4`,
`$21F0`, and `$21F4`, covering the observed `$218C–$21F4` region. The title
tiles are IDs `$28–$3F` plus `$03`, `$07`, `$0A`, `$12`, and `$14`; the captured
attribute mapping selects palette 0 in this region.

Rendering those nametable tile IDs with the ROM's selected CHR pages
`[124, 125, 126, 127]` produces the `TECMO` / `THEATER` title lettering.
This verifies the renderer's tile/palette interpretation against the captured
PPU output. It does **not** yet identify the ROM table/routine that produces
all those nametable bytes: F9 background record 00 and blocks 22–24 do not
account for the title lettering. The E8 preset 1 path (19-byte setup at ROM
file offset `0x00DF23`) is now traced as raster/PPU configuration, including
an MMC3 IRQ setting; it is separate from the nametable tile payload and is not
the missing title-map table. The producer of the captured map remains
unidentified. See `reference/rom_extract/intro/e8_preset_01_trace.md`.

An exact-byte search found candidate copies of the two nine-tile horizontal
rows at ROM file offsets `0x027461` and `0x02746D` (nearby descriptors start
at `0x02745E` and `0x02746A`). Their bytes match the first two title rows, but
their producer/consumer path and relationship to the frame-10/11 PPU queue
have not been proven; they are leads, not an asserted source mapping.

## Limits

This prototype renders the observed background tile layer only. It does not
render animation `0x8D`, sprites/OAM, raster timing, or exact PPU visibility
timing, and it is not integrated into the main scene. The nametable mapping is
useful for reconstructing and validating this opening frame, but exact
ROM-derived command/data provenance for the title map, the E8 preset's full
raster schedule, and exact PPU visibility timing must still be established
before calling this slice fully reverse-engineered or exact.
