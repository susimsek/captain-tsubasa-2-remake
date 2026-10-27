# Shared OAM scanline evaluation

## Implemented behavior

`RomSpriteAnimationPrototype` now reports each decoded sprite using its source
hardware OAM slot. The presenter assigns slots cumulatively in original `FB`
list order, using each animation's largest decoded descriptor count as its
reserved extent. It then evaluates the shared 64-slot list from slot 0 upward
for each visible output row. The first eight sprites whose 8-pixel Y range
covers that row may draw on that row; later sprites are suppressed for that
row. Pattern transparency does not remove a sprite from the evaluation count.

The PPU row coordinate is derived from the existing NES OAM convention:
screen top is `OAM Y + 1`, so the descriptor renderer's `sprite_y` is the first
visible output row. Sprites already hidden by the ROM-derived `$04/$08`
overflow-marker rule are excluded from visible-line evaluation, preserving the
existing DMA-culling behavior. The output remains clipped to the 256×240
viewport.

## Evidence

- The supplied ROM's opening `FB 03 C0 A2 7D` at source frame 2367 installs
  three animation objects. The synchronized OAM audit records `$C0` at slots
  0–15, `$A2` at 16–24, and `$7D` beginning at 25. See
  [`opening_fb_animation_coverage.md`](opening_fb_animation_coverage.md),
  [`a2_oam_dma_culling_trace_20261025.md`](a2_oam_dma_culling_trace_20261025.md),
  and [`bg0a_raster_source_trace.md`](bg0a_raster_source_trace.md).
- The displayed frame 2369 uses the preceding OAM DMA page in
  `reference/opening_timing_capture_20261024_131726/ram_states/ram_02368.bin`.
  Slots 0–7 contain `00 00 00 08`; slots 8–15 contain `08 00 00 08`. Thus
  those first 16 entries intersect output rows 1–8 and 9–16 respectively,
  before `$7D`'s later slots are considered. Their tile ID is `$00`; in `$C0`'s
  selected CHR bank `$18`, tile 0 is all-zero/transparent, but these entries
  still consume the per-row sprite budget.
- The pinned FCEUX NewPPU implementation has `maxsprites = 8` and a ninth-sprite
  overflow path in `src/ppu.cpp` (revision
  [`a6d03e7968bd77a8156a7c9b628a673753f2f4c6`](https://github.com/TASEmulators/fceux/blob/a6d03e7968bd77a8156a7c9b628a673753f2f4c6/src/ppu.cpp)).
  This is the emulator's PPU model evidence for the row budget; it is not a
  cycle-level measurement of physical 2C02 sprite-fetch timing.

## Confirmed behavior versus limits

Confirmed: source OAM slot order is significant, an entry with transparent
pattern data still counts toward the eight-sprite scanline budget, and the ROM
overflow markers hide entries by replacing DMA Y with `$F8`. The implementation
does not special-case frame 2369; it uses the current pose and shared source
slots for every frame.

The renderer currently evaluates one 8-pixel-high sprite row against the
visible screen rows. It does not reproduce the 2C02's sprite-overflow hardware
bug, dot-by-dot OAM evaluation/fetch phases, or undocumented edge behavior for
Y=`$FF`. Entries in unused or stale allocated OAM slots also remain unresolved;
this pass considers decoded descriptors written for the current pose. The
separate `$C1/$82` BG08 compositor retains its existing path and does not yet
use this evaluator. These boundaries require focused capture evidence before
claiming complete NES OAM equivalence.

## Targeted validation

The fix was checked against the same-input FCEUX reference over frames
2367–2415 (49 frames) using both the complete 256×240 PPU output and FCEUX's
visible 224-line crop. Godot matched all 49 visible 256×224 frames exactly.
The 142 remaining raw-image pixel differences are all on row y=0; rows 8–231
and 232–239 have zero differences. Thus the former `$7D` sprite residual is
removed from the displayed game area. In the full 240-line comparison, 40/49
frames are exact because nine frames retain only this top overscan-row
difference. The check says nothing about unmeasured frames or dot-level OAM
evaluation.

The measurements and source/reference frame mapping are recorded in
`reference/diagnostics/oam_scanline_evaluation_20261025/README.md`. Do not infer
cycle-level 2C02 accuracy from a matching frame image.
