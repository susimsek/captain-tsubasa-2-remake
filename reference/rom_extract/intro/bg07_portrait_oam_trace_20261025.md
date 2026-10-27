# BG07 portrait `$76` OAM wrap trace

Checked: 2026-10-25  
Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## Finding

The partial portrait that Godot showed at source frame 1535 was an OAM
visibility error. The ROM had set the 42 `$76` portrait sprites' OAM Y bytes to
`$F8`, hiding them while their 8-bit X coordinates crossed the right edge. The
shared sprite copier substitutes `$F8` when an internal attribute has overflow
bits `$04/$08`; the ROM animation writer toggles X-overflow bit `$04` as each
sprite X wraps. Godot previously wrapped the animation X coordinate before
tracking that marker, so it drew portrait tiles before the ROM made their OAM
entries visible.

The shared ROM camera worker now drives BG07 animation `$76` in Godot. Its
per-frame predicted OAM tuples match the 42 captured source tuples at all saved
checkpoints from 1534 through 1755, including the one-sprite / six-sprite
partial reveal. This fixes the portrait's premature appearance and its second
disappearance after one full-width wrap. It does **not** make the complete
screen exact: the BG07 background patch is still on the wrong side of the
viewport, and later text composition remains mismatched.

## ROM and trace evidence

- Background `$07` record: file offset `$00E1A0`, raw bytes preserved in
  [`background_07.bin`](background_07.bin). Its trailing camera record is
  `00 3F 08` at `$00E1AE`; the layout metadata records the same bytes and the
  four selected CHR banks in
  [`background_07_layout.json`](background_07_layout.json).
- Animation `$76`: bank 10, CPU `$A18F`, file offset `$01419F`; its decoded
  sequence sets Y/X `$30/$C0`, enables horizontal mirroring, selects frame
  `$AAE7`, then sets animation flag bit 4. The decoded 42-sprite frame and
  timing entry are in
  [`animation_timing_entry.json`](animation_timing_entry.json) and
  [`sprite_frames_entry.json`](sprite_frames_entry.json).
- The same-input PC-tagged RAM/OAM writes are in
  [`ram_oam_writes.csv`](../../diagnostics/ram_oam_write_trace_20261025_121710/ram_oam_writes.csv),
  with checkpoint snapshots and trace scope in
  [`frame_state.csv`](../../diagnostics/ram_oam_write_trace_20261025_121710/frame_state.csv)
  and [`metadata.txt`](../../diagnostics/ram_oam_write_trace_20261025_121710/metadata.txt).
  Source frames 1534–1570 record the animation's OAM updates.
- In this trace `$7A/$7B` begin moving at frame 1537, three frames after the
  BG07 background load completes at frame 1534. The worker writes `$47=$F8`
  or `$F9` and updates the screen-space sprite X values through the shared
  animation path. The `$00E1AE` speed byte `$3F` gives a 7.75-pixel Q8.8 step;
  `$08` selects eight 32-pixel chunks, for 256 pixels of total movement.
- The common sprite descriptor writer at `$9541–$9569` encodes the computed
  X/Y overflow state into attribute bits `$04/$08`. The bank-2 copier at
  `$A8CE` checks `$046A & $0C` and writes Y=`$F8` when either marker is set;
  it still copies tile, attribute, and X. The corresponding byte audit and
  disassembly caveats are documented in
  [`a2_oam_dma_culling_trace_20261025.md`](a2_oam_dma_culling_trace_20261025.md).
  This BG07 trace logs the same copier's stores at PCs `$A8E5/$A8EB/$A8F1/$A8F7`.

The ROM-derived model predicts the full first-42 OAM tuple set from the `$76`
descriptors, mirrored base X, worker displacement, and the shared `$0C` mask.
Those predicted tuples match the captured tuples exactly at each saved
checkpoint:

| Source frame | Worker X offset | `$76` sprites visible / 42, model | Captured OAM | Full tuple match |
| ---: | ---: | ---: | ---: | ---: |
| 1534 | 0 | 0 | 0 | 42/42 |
| 1537 | 8 | 0 | 0 | 42/42 |
| 1548 | 93 | 0 | 0 | 42/42 |
| 1549 | 101 | 0 | 0 | 42/42 |
| 1550 | 109 | 1 | 1 | 42/42 |
| 1551 | 117 | 6 | 6 | 42/42 |
| 1552 | 124 | 13 | 13 | 42/42 |
| 1559 | 179 | 42 | 42 | 42/42 |
| 1560 | 186 | 42 | 42 | 42/42 |
| 1570 | 256 | 42 | 42 | 42/42 |
| 1600 | 256 | 42 | 42 | 42/42 |
| 1755 | 256 | 42 | 42 | 42/42 |

The source rows at 1550–1552 come from end-of-frame CPU RAM snapshots; the
exact PPU OAM DMA subframe edge is not logged. Thus this establishes the
observed frame-level hidden/visible sequence and tuple contents, not every
within-frame pixel edge.

**Update (2026-10-25):** The BG07 nametable destination was found to be shifted
20 world tiles from the record's logical origin. A focused change now matches
frames 1535–1549 exactly, including frame 1535's black screen and frame 1548's
six-pixel cyan edge. See
[`bg07_world_offset_fix_20261025`](../../diagnostics/bg07_world_offset_fix_20261025/README.md)
for the PPU-memory / `$2007` evidence and selected-frame comparison. This
resolves the BG07 background gaps listed below at frames 1535 and 1548; it does
not resolve the residual differences in frames 1550–1555 or establish
cycle-accurate PPU timing.

A second post-fix capture checked only frames 1600 and 1755. Both match all
61,440 FCEUX RGB pixels, including the 1755 text and portrait. The comparison
is in
[`bg07_world_offset_fix_checkpoints_20261025`](../../diagnostics/bg07_world_offset_fix_checkpoints_20261025/rom_frame_comparison.csv).
This supersedes the pre-offset frame-1755 mismatch reported in the interim
capture tables below.

## Godot change and capture comparison

`rom_background_camera_worker.gd` now accepts the byte-checked BG07 and BG0B
records, instead of duplicating the BG0B worker. The source presenter activates
that worker when the BG07 packet producer completes and applies it to `$76`
only. The sprite renderer keeps the full cumulative X displacement for the
overflow-marker parity while applying 8-bit wrap to the displayed OAM X. This
preserves distinct `$76` and `$7C` animation gating.

Godot 4.7.2 captured frames 1534–1560 plus 1600 and 1755 in
[`portrait_oam_wrap_fix_20261025/`](../../diagnostics/portrait_oam_wrap_fix_20261025/).
The comparison file uses the same source-frame mapping as
[`screen_index.csv`](../../opening_full_frame_capture_20261025_101014/screen_index.csv).
Relative to the previous Godot capture in
[`opening_runtime_recapture_20261025_cursor_origin/`](../../diagnostics/opening_runtime_recapture_20261025_cursor_origin/),
exact RGB improved by about 0.8 percentage points through the early reveal;
the unchanged later checkpoints show this was a targeted OAM correction:

| Frame | RGB exact before | RGB exact after | Foreground exact before | Foreground exact after |
| ---: | ---: | ---: | ---: | ---: |
| 1535 | 93.33% | 94.15% | 0.00% | 0.00% |
| 1548 | 92.86% | 93.68% | 0.00% | 0.00% |
| 1550 | 91.78% | 92.60% | 0.00% | 0.00% |
| 1551 | 91.23% | 92.04% | 0.00% | 0.00% |
| 1560 | 88.83% | 89.64% | 0.00% | 2.09% |
| 1600 | 90.41% | 90.41% | 7.88% | 7.88% |
| 1755 | 89.26% | 89.26% | 8.63% | 8.63% |

## Interim gaps before the 2026-10-25 world-X correction

- FCEUX is black at frame 1535, while the current Godot output still shows a
  BG07 cyan/gray patch at x=176–255, y=80–127. At frame 1548 FCEUX has only a
  narrow left-edge strip (x=0–5), while Godot still shows that right-side
  patch. The `$76` sprite tuples are hidden correctly in both states; the
  background's visible scroll/raster window is a separate unresolved issue.
- At frame 1560 the ROM and Godot portrait occupy the left side, but the Godot
  background and foreground pixel composition still differ. At frame 1755,
  the text/portrait composition is not exact.
- The exact PPU/OAM transfer phase inside the frame, the residual BG07
  composition beyond the corrected nametable placement, and the remaining
  text CHR/raster mapping are unresolved. No screenshot pixels or captured
  audio are runtime assets.

## BG07 scroll and lower-CHR follow-up (2026-10-25)

The camera-worker trace also explains the large right-edge background patch.
The presenter now supplies BG07's source raster events through the existing
generic PPU renderer:

- `$A086-$A091` writes the first-row scroll and control state. At source frame
  1538 the trace records `$2000=$89`, `$2005=$F8,$FF`; frame 1548 records
  `$89,$AA,$FF`; frame 1550 records `$89,$9B,$FF`; and frame 1560 records
  `$89,$4D,$FF`. These scroll bytes match the worker model's previous-frame
  state (1537, 1547, 1549, and 1559 respectively), so the renderer uses that
  one-frame latch. For example, source frame 1548 has 11 completed camera
  updates by frame 1547, giving the `$AA` scroll byte.
- `$A178/$A17B` reload PPU address `$2200` at scanline 129. `$A182` restores
  `$2000=$88`, followed by `$A187/$A18A` writing `$2005=0,0` across scanlines
  129–130. The presenter models those row events explicitly.
- At scanline 130, `$A1D4/$A1D7` selects MMC3 R0 `$00` and `$A1E0/$A1E3`
  selects R1 `$02`. A representative frame-1548 trace places their data writes
  at dots 146 and 197; the exact dot phase varies slightly by frame and remains
  unverified. The upper selectors remain the background record's `$3A/$00`.

The implementation is in
[`cold_start_source_command_presenter.gd`](../../../scripts/opening/cold_start_source_command_presenter.gd).
It uses ROM-derived camera state and captured CPU/PPU write evidence; no
screen-derived pixels were introduced. Godot 4.7.2 was recaptured at frames
1534–1555 and 1755, with same-input frame comparison in
[`bg07_raster_model_test_20261025/`](../../diagnostics/bg07_raster_model_test_20261025/).
Against the prior cursor-origin capture, exact RGB changed as follows:

| Source frame | Before | After | Foreground exact after |
| ---: | ---: | ---: | ---: |
| 1535 | 93.33% | 94.15% | 0.00% |
| 1548 | 92.86% | 99.53% | 0.00% |
| 1555 | 90.26% | 97.01% | 6.67% |
| 1755 | 89.26% | 95.01% | 24.83% |

At this capture revision, the right-side patch was no longer displaced at frame
1548, but the source's six-pixel-wide cyan strip at x=0–5, y=80–127 was still
omitted. At frame 1535 the 80×48 cyan/gray patch still appeared in Godot while
the mapped FCEUX screenshot was black. The available PPU snapshot/scanline
plan for frame 1548 rendered that left-edge strip at 99.6875% RGB exactness;
the later world-X correction cited above connects that result to the source
nametable destination and reproduces both target states.
Frame 1755 was recaptured, so it is no longer missing as a checkpoint, but the
remaining text/portrait composition is still not exact. Its current comparison
at this interim stage did not identify a verified text-glyph or per-pixel PPU
rule to apply; the later +20 nametable placement correction instead made the
whole 1755 frame 100% RGB exact.

The interim comparison was a targeted improvement, not an exact BG07
reconstruction. The +20 placement correction resolves the 1535 black state,
1548 strip, and 1755 text/portrait checkpoint; frames 1550–1555 still have
small residual differences, and within-frame PPU/CHR fetch phase remains open.
