# Frame-26 Tecmo Theatre glyph trace

## Finding

The 409 RGB disagreements previously reported between the isolated Godot
presenter and the frame-26 reference are a one-pixel vertical background
scroll mismatch. They are not evidence of wrong glyph tile IDs or wrong CHR
patterns.

The prototype places the captured glyph tiles at their unscrolled nametable
coordinates. Frame 26's upper raster band has `scroll_y = 255` (NES `$FF`):
coarse Y starts at 31 and fine Y at 7. The vertical wrap at the first visible
scanline advances to nametable row 0 on screen line 1; later logo rows therefore
appear one screen pixel below their unscrolled tile origins. This agrees with
the captured FCEUX frame. The mapping from `$FF` to the one-pixel displacement
is the NES loopy vertical-scroll interpretation; the frame comparison directly
confirms the displacement.

## Reproducible comparison

Inputs:

- Direct Godot viewport PNG: `/tmp/cold_start_logo_frame_256.png`, 256×240.
- ROM/PPU reconstruction: `assets/opening/intro/ppu_timing/frame_000026.png`,
  256×240.
- FCEUX observation: `reference/opening_capture/frames_png/frame_00026.png`,
  256×240. Its emulator notification text at the lower-left is outside the
  logo region and was not used as an asset.

Compare only the complete logo test region x=104–175, y=90–139 (3,600 RGB
pixels). The direct Godot image differs from the PPU reconstruction at 409
pixels and from the FCEUX observation at the same 409 pixels. Translating the
Godot background/logo content down by one pixel yields 0/3,600 RGB differences
against each reference. The sprite is not translated. Outside the glyph test
region, the original unshifted Godot capture already matched the PPU
reconstruction. Comparison used decoded PNG RGB bytes, not a lossy video frame.

## ROM and PPU source data

ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

The frame-26 nametable tile IDs and attribute-derived palette IDs are listed in
`background_00_nametable_layout.json`. The title writes are observed in source
frames 10–11 at PPU `$218C–$21F4`; the end-of-frame frame-26 PPU nametable
retains the resulting layout. The glyph rows are:

| Nametable row | Columns | Tile IDs (hex) |
| --- | --- | --- |
| 12 | 13–21 | `28 29 2C 2D 38 37 39 3C 3D` |
| 13 | 13–21 | `2A 2B 2E 2F 3A 2A 3B 3E 3F` |
| 15 | 14–20 | `14 0A 07 03 14 07 12` |

Each listed tile is in pattern slot 0 (`$0000` pattern base), so its pattern is
the corresponding 16-byte tile in physical CHR 1 KiB bank 124. The extracted
CHR file begins at source ROM offset `0x40010`; bank 124 begins at file offset
`0x5F010`. A tile's byte offset is `0x5F010 + tile_id * 16`. The upper raster
band's selectors are `[124, 125, 126, 127]`; from scanline 130 the selectors
switch to `[0, 1, 2, 3]`. Therefore the glyph reconstruction uses bank 124, not
the final bank-0 mapping visible in the end-of-frame PPU memory snapshot. The
frame plan is `reference/diagnostics/rom_frame_000026.json`; its upper/lower
band source is `reference/diagnostics/timing_capture_20261024_125300_raster/frame_000026.plan.json`.

Palette attributes for the mapped logo cells are subpalette 0, confirmed by
frame-26 nametable attributes. The captured PPU palette's first 16 bytes match
the extracted background palette 1. This rules out palette selection as the
409-pixel cause.

## Scope and remaining gap

This evidence traces the static frame-26 glyph mismatch only. It does not
implement the scroll behavior in the presenter, prove the full cold-start PPU
commit schedule, or establish frame-accurate animation/audio. No renderer code
was changed by this trace. The comparison images remain observation and
validation material; runtime glyph pixels must continue to be decoded from the
ROM-owned CHR and mapping data.
