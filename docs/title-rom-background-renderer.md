# ROM-derived title background renderer

`RomTitleBackgroundRenderer` builds the 256×240 title endpoint from
`RomTitleBackgroundLoader` packets, a modeled first nametable/attribute table,
ROM 2bpp CHR and palette records. `scenes/title_menu.tscn` uses it directly;
`title_menu.gd` moves the cursor between `KICK OFF` and `CONTINUE` with the
source-observed one-frame presentation delay. Start confirmation remains
disabled for this milestone.

## Sources used

- Background ID `$17` is selected by `$806A → $8AF7` at source frame 4664;
  the loader resumes at `$806F` on frame 4690. The title-entry trace matches
  all 240 queue packets to the ROM record. The 48 metatile IDs, 31 block
  extracts, selected palette and ROM hash are documented in
  [the title background loader note](title-rom-background-loader.md).
- The title endpoint PPU state at source frame 4692 has the cursor tile `$7F`
  at `$220A`; `$224A` is zero. The renderer initializes `KICK OFF` selection
  from those observed tile values. `set_cursor_selection(1)` moves the final
  tile to `$224A`; it does not model the source queue's one-frame commit.
- `assets/opening/title_menu_scanline0.json` records the endpoint's PPU bank
  slots `[124,125,126,127,124,125,126,127]`, pattern base `$0000`, and
  `$2005` vertical scroll `$FF`. The first visible scanline is rendered from
  coarse Y 31 / fine Y 7: tile IDs come from PPU `$23E0–$23FF`, and the
  background palette selection uses the matching last-row attribute bytes.
  The source-derived row method matched all 256 diagnostic row pixels. The
  current GDScript renderer and Start handoff were then run headlessly with
  Dummy audio: frame 4692 (`KICK OFF`) and frame 4694 after Down (`CONTINUE`)
  each matched all 61,440 RGB pixels in the corresponding FCEUX capture.
  Reproducible images and the comparison record are in
  `reference/diagnostics/title_godot_verification_20261024/`.
- The independent title OAM evidence is retained in
  `reference/rom_extract/intro/title_menu_source_trace.md`: `$890C` adds
  `$30` to the cup sprite Y values and `$88FB` XORs priority bit `$20`.
  When `include_verified_cup_oam` is enabled, this renderer reuses the
  ROM-derived `title_cup_layer.gd` texture and composites those behind-BG
  pixels only where the background pattern color is zero.
- CHR source is `reference/rom_extract/chr_rom.2bpp` (ROM file offset
  `0x40010`); its extract SHA-256 is pinned in the renderer. The RGB table is
  `reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal`, separately
  sourced from FCEUX because RGB values are not stored in the ROM.

## Endpoint assumptions and limits

The renderer initializes the title's first nametable to zero, applies the
reconstructed loader packets in row-major block order, then sets the observed
initial cursor. The title record begins at tile row 4 and covers six rows by
eight blocks. Blank areas outside it therefore use tile `$00`; this is a
small endpoint-state assumption, not a proved title clear routine.

The title handoff uses `scripts/title_rom_handoff_queue.gd` to stage the 240
decoded ROM packets under the source `$3D` queue-capacity rule. The stream
naturally yields in the observed pattern (26 groups of nine, then six); each
pending group commits on the next modeled source-frame edge. After the final
background drain, the queue stages the palette and cursor, and the title is
revealed when that final queue commits. Focused Godot verification confirms
30 black frames, reveal on frame 31, all 240 packet contents/addresses/order,
and exact endpoint RGB output for both cursor positions. The first producer
release and next-frame NMI commits remain source-frame models rather than
CPU-cycle execution; Godot does not execute `$8AF7` or the `$A000` NMI consumer
as 6502 instructions. No screenshot pixels or captured WAV data are read.
CPU/NMI subframe timing and the precise first-pixel dot remain open.

This module models the endpoint's special first raster scanline and cup OAM
overlay. It does not simulate MMC3 writes at cycle granularity, PPU fetch and
shifter latches, sprite evaluation/overflow, sprite-zero hit, general scroll,
mirroring aliases, emphasis, or Start/title transition timing. The 256×240
texture is a byte-derived reconstruction, not a captured screen asset.
