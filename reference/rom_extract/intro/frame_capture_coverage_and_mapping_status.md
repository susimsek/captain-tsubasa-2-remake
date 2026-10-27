# Opening capture coverage and code-to-pixel status

Checked: 2026-10-25  
Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## Complete per-frame memory snapshots

`reference/opening_timing_capture_20261024_131726/` contains a clean-power-on,
same-input replay from source frame 0 through 4692. `capture.log` reports 4,693
PPU snapshots and 4,693 RAM snapshots. The file inventory and `frames.csv`
were checked: both indexed sets are contiguous, contain one file for every
source frame 00000–04692, and all 4,693 frame-map rows identify the expected
source frame.

- Each PPU file is 16,384 bytes: FCEUX's mapped PPU address view `$0000–$3FFF`.
- Each RAM file is 2,048 bytes: CPU RAM `$0000–$07FF`, including the game's RAM
  OAM shadow at `$0200–$02FF`.
- `frames.csv` also records replay input, frame-cycle start/end, lag, and the
  emulator/source-frame mapping.
- `bus_events.csv` has 461,947 selected PPU/MMC3 register-event rows with CPU
  cycle offset and PC. The hooks cover selected register reads/writes; this is
  not a full 6502 instruction trace and it does not record every CHR fetch.
- The capture metadata explicitly says the documented FCEUX Lua API used here
  has no PPU scanline/dot getter. CPU cycle offsets do not establish the exact
  sub-cycle pixel phase.

These are end-of-frame memory snapshots, not rendered images. A PPU memory view
shows the bytes currently addressable through PPU memory; it does not preserve
the order/timing of every tile, attribute, or pattern-plane read used to draw
the preceding frame. RAM snapshots similarly show state, not the instructions
that produced that state.

## Rendered screen samples

`reference/opening_reference_capture/screen_index.csv` contains 981 distinct
screen captures across the same 0–4692 source-frame range. The `screens/`
directory contains 1,962 filesystem entries: 981 raw `gui.gdscreenshot()`
captures named `frame_*.gd`, plus 981 `.gd.uid` sidecars. The capture script
samples every other emulator frame and keeps a screenshot only when it differs
from the prior sample. Therefore this directory does **not** contain 1,962
image frames, and it does not include a screenshot for every source frame.

There is also a separate `reference/opening_capture/frames_png/` set of 707
PNG images; it is another sparse capture, not a complete 4,693-frame movie.

## How much frame-to-code mapping is solved

The mapping is partial, not complete. Evidence already connects the ROM script,
6502 handlers, PPU writes, and visible results for selected sections:

- The live dispatcher trace records 585 dispatch entries: the 551-command
  first opening pass and 34 entries of the replay before the Start/title handoff.
  It is not a record of every executed CPU instruction across all frames.
- The logo fade/clear path, several opening command handlers, field background
  packet generation, runner OAM descriptors/motion, field raster accumulator,
  title background packets, cursor update, and `$ED $58` sound-driver lookup
  have source-byte and/or live-trace evidence in the linked notes below.
- Selected PPU register writes have PC/cycle attribution, and same-input raw
  PPU/RAM states permit checking the state before/after a change. A register
  write does not by itself identify the first affected pixel; the PPU fetch and
  shifter timing is still required.

For source frame 1522, a diagnostic FCEUX build adds bounded fetch evidence:
2,584 background CHR-plane reads on scanlines 128–165 were logged with address,
byte, mapped bank, and PPU dot. All 2,584 bytes match the supplied ROM's CHR
extract. The dialogue tile `$48` is fetched on scanlines 152–159 from 1 KiB CHR
bank 1, addresses `$0480–$048F`; its 16 plane bytes match ROM offsets 1152–1167.
An enhanced trace now directly records that `$2269` supplies tile `$48` and
maps its eight pattern rows to x=72–79, y=151–158 in FCEUX NewPPU. The line-130
bank-0 fetch is separately identified as blank tile `$00` from `$2215`, mapped
to x=168–175, y=129. These coordinates follow the pinned FCEUX software
renderer; they are not a physical 2C02 shifter/color measurement and do not
map final palette color for every pixel. This also does not cover other frames.
See `reference/diagnostics/chr_plane_nt_trace_20261025/README.md` for the
source-cell trace and `reference/diagnostics/chr_plane_reads_20261024/README.md`
for the wider initial bank/fetch trace.

The source-cell provenance replay spans eight nearby replay frames and logs
19,456 background plane reads on the same scanlines. For source frame 1522 it
associates 2,432 on-screen plane reads with nametable address, tile ID, plane,
dot, mapped bank, ROM offset, and the x/y span computed by FCEUX NewPPU; all
source bytes match the ROM. The earlier 2,584-read count includes 152 fully
offscreen pattern-record reads. The trace does not include all source frames,
sprite evaluation, final per-pixel palette/priority composition, or physical
2C02 shifter timing. A full replay-scale trace should hook the renderer's
compact tile/output spans and add sprite composition, rather than emit tens of
millions of individual plane-read rows. The PPU does not execute a separate
ROM instruction for each pixel: the useful mapping is command/CPU writes →
PPU state and fetches → pixel composition.

The frame-1522 BG08 split is now applied from the ROM preset-01 event marker,
the `$BA96` selector stream, and the `$A160/$A1CB` consumer model. The renderer
selects each CHR plane using FCEUX NewPPU fetch positions. A same-input Godot
capture improved frame 1522 from 61.07% to 92.12% exact RGB and from 32.40% to
84.83% foreground-union exactness. A follow-up runtime check now also confirms
the pending-load selector transition: BG03 `$3A/$00` remains active through
frame 1047 and BG08 `$40/$00` is active on frame 1048. Frame 1050 measures
92.71% exact RGB. The BG08 C1/82 sprite layer is now built from the ROM's
shared OAM records and motion commands: the displayed frame-1522 sprite pixels
match all 2,563 opaque pixels, and 63/64 OAM slots match (hidden slot 5 is
unresolved). A new full viewport capture measures 96.41% exact RGB at frame
1522. Background/raster differences remain, and dot-phase values are
calibrated from frame 1522 and vary in other frames. See
`reference/diagnostics/frame1522_dynamic_chr_gap_audit_20261024.md` and
`tools/diagnostics/verify_bg08_pending_pair_runtime.gd` plus
`reference/rom_extract/intro/bg08_c1_82_shared_oam_trace.md`.

The BG09 field palette animation is now also implemented from its source
stream. The effect model validates the preserved bank-6 pointer at file offset
`0x00D812` and the 18 ROM bytes at `0x00D848`, decodes the `$30,$21,$30,$25`
loop, and submits the palette packets through the shared queue/NMI path. Its
F5/EA behavior keeps the effect alive during the fade, models the observed
`$05E8` queue-capacity retry, and stops at the FD transition. A targeted run
passed 32 RAM/PPU checkpoints from frames 1779–2117, including `$0633=$30` at
1779 / PPU `$3F09=$30` at 1781, `$0633=$21` at 1784 / PPU `$3F09=$21` at 1785,
and both bytes `$25` at frame 2034. `$4C=$81` remains through frame 2116 and is
cleared to `$00` on the frame-2117 FD transition in both model and capture.
During the exit fade, the sampled PPU byte sequence through `$0F` at 2117 also
matches. At frame 2034 the Godot viewport
contains the ROM-derived pink field and measures 89.74% full RGB exactness and
81.76% foreground exactness against FCEUX; this is not a pixel-exact frame.
Neighboring rendered checkpoints and state values are in
`reference/diagnostics/bg09_palette_effect_validation/`; the ROM trace and
asset offsets are in `reference/rom_extract/intro/bg09_pink_field_source_trace.md`.

Unresolved work includes complete semantic/timing coverage of the opening
command handlers, complete source-timed audio output, exact subscanline MMC3
phase outside measured checkpoints, and the mapping from every frame's
executed code and individual PPU fetches to all visible pixels. The BG09
palette loop and selected PPU commits are source-backed and state-checked, but
the viewport still differs and this does not solve the full per-pixel mapping.
The snapshots materially help the work, but do not solve it by themselves. Do
not call the opening pixel-exact or complete until same-input Godot and FCEUX
output is compared through the full requested range and the remaining
pipeline/audio gaps are closed.

## Post-integration sparse viewport comparison (2026-10-25)

After the BG08 shared-OAM and BG09 source-palette changes, the standalone
Godot opening was rendered again at all 981 available distinct screen
checkpoints through source frame 4692. The output is
`reference/diagnostics/opening_runtime_sparse_1792880258/`; per-frame metrics
are in `match_rates.csv`. Mean exact RGB is 85.87% and foreground-union exact
is 60.27%. Excluding the anomalous frame-2 initial-state sample (0.17% RGB),
the means are 85.95% and 60.33%. The BG09 range 1760–2120 has 170 checkpoints
at 91.29% RGB / 83.73% foreground; frame 2034 is 89.74% / 81.76%. Frame 1522
is 96.41% / 92.84%; title frame 4692 is 100% RGB. These are sparse viewport
comparisons, not per-pixel PPU fetch traces. They do not establish image
equivalence for the 3,712 unpictured source frames or close the remaining
per-pixel/code mapping.

## One raw-state result: field runner's first visible row

For source frames 380, 382, and 394, the FCEUX reference row 0 is reproducible
from the PPU snapshot, ROM CHR banks 60–63, palette bytes, and the external
FCEUX RGB palette: 256/256 RGB pixels. It is real PPU output, not an OAM or
screenshot artifact. The cause is the ROM's `$2005=$00,$FF` setup: scanline 0
uses coarse-Y 31/fine-Y 7, fetching tile IDs from `$23E0–$23FF`; the following
vertical increment wraps coarse-Y 31 to 0. See
`reference/diagnostics/field_runner_scanline0_source_render_20261024.md`.

The Godot renderer now models the initial `$FF` vertical scroll and coarse-Y
31 wrap, and the source presenter applies the dispatcher's 32 `$55` writes to
`$23E0–$23FF` at the observed frame-8 bootstrap edge. Those bytes are verified
against the ROM and the frame-8 CPU bus trace. Fresh runtime comparisons at
frames 380/382/394 are 98.34%/96.71%/93.75% exact RGB; the first eight rows
match 256/256 pixels at each checkpoint. Remaining scene differences include
other scanlines and the exact raster bank-switch phase. This is one solved
source-to-output slice, not a complete per-pixel/code mapping. The broader
coverage gaps above remain open.

## Reproduction references

- Complete memory replay: `reference/opening_timing_capture_20261024_131726/`
- Sparse raw screen samples: `reference/opening_reference_capture/screens/`
- Capture implementation: `tools/capture_opening_reference.lua` and
  `tools/capture_opening_timing.lua`
- Partial interpreter dispatch: `reference/rom_extract/intro/cold_start_observed_dispatch.json`
- Opening handler map: `reference/rom_extract/intro/cold_start_vector_handler_semantics.md`
- Field raster/source bank map: `reference/rom_extract/intro/field_runner_chr_raster_split_trace.md`
- Current post-integration renderer comparison: `reference/diagnostics/opening_runtime_sparse_1792880258/match_rates.csv`
- Historical field renderer comparison: `reference/diagnostics/raster_runtime_compare_1792872436/match_rates.csv`
- Field scanline-0 reconstruction and startup writer: `reference/diagnostics/field_runner_scanline0_source_render_20261024.md`

## Full opening viewport comparison and capture acceleration (2026-10-25)

The indexed FCEUX screen reference now has one row for every source frame
0–4692: 4,693 rows, 1,636 distinct images, and 3,057 held-image rows. The
post-fix Godot recapture wrote a candidate image for all 4,693 rows in
reference/diagnostics/opening_runtime_full_chunks_20261025_revalidated/;
per-frame results are in
reference/diagnostics/opening_runtime_full_chunks_20261025_revalidated/all_frame_metrics.csv.
The post-fine-X full rerun compares every one of the 4,693 candidate frames
against its indexed FCEUX frame. Its baseline mean exact RGB is 95.81%; mean
foreground-union exactness is 64.75%. The title transition/menu endpoint frames
4662–4692 are 100% exact RGB. Baseline per-scene RGB / foreground-union means
are 97.33% / 87.17% for 0–378, 97.44% / 87.59% for 379–1519, 91.26% / 56.50%
for 1520–2117, 93.88% / 60.54% for 2118–3000, and 96.92% / 48.48% for
3001–4661. This full capture predates the repeated-logo visibility/palette
fix below. Candidate screenshots remain validation-only.

Capture now computes a conservative visible-CanvasItem/render-texture state
key each source frame. If that key is identical to the prior frame, it reuses
the previous viewport image but still writes and compares a row against that
frame's FCEUX reference. The opening simulation still advances every source
frame. A 10-frame smoke capture reused the viewport image 9 times (1 readback)
and all ten PNGs matched the earlier renderer output pixel-for-pixel; frames
379–384 also matched their earlier PNGs exactly. The renderer now avoids
rebuilding unchanged sprite poses, BG08 OAM compositions, and MMC3 input state.
This reduces repeat work without using the emulator's `changed` flag to skip
candidate-only animation. This post-fix capture was freshly generated across
all 16 chunks. Earlier targeted captures for the same frames are byte-identical
only in the explicitly documented sample ranges; the full comparison above
establishes exact-RGB metrics against FCEUX, not byte identity between Godot PNGs.

This capture remains limited to the cold opening through the visible
`KICK OFF` / `CONTINUE` title endpoint. It does not cover matches or the rest
of the game.

### Repeated Tecmo logo loop (2026-10-25)

The source trace returns to `$A020` with `FE 20 A0` at frame 4207. It then
selects `F9 00`, `FB 01 8D`, and `E9`; the loop's `EA` fade/clear begins at
frame 4466 and `ED 58` plus `DC` dispatch at frame 4481. A frame-number
visibility window had hidden animation `$8D` after the first pass. The
presenter now derives visibility from the selected background, E9 screen-enable
state, and whether EA's clear has completed. On the repeated E9, it restores
the exact logo palettes before the ROM-derived fade: background bytes at file
`$D020` match `background_00_layout.json`, and the 16 sprite bytes at `$D670`
match `animation_8D_sprite_palette.bin` and its recorded hash. The supplied ROM
SHA-256 is checked as part of the background metadata.

Godot's offline audio driver was disabled for the recapture. The direct
same-source-frame capture in
`reference/diagnostics/repeated_logo_loop_direct_20261025/` contains all 275
frames 4207–4481. Every frame is 100% exact RGB and 100% foreground exact
against the FCEUX screen index; the viewport rendered 24 distinct images and
reused the prior image for 251 held frames. The output and per-frame metrics
are validation references, not shipped art. PPU palette snapshots at frames
4212, 4226, 4475, and 4480 independently match the ROM fade model; frame 4481
is black. The trace does not sample PPU dot timing, but the whole rendered
frame window now compares exactly.

The latest full-opening measurement includes the frame-13 OAM latch, BG0B
sprite-X wrap, and source-derived FD-origin/signed-E3 text cursor fixes. All
4,693 frames are present; the two first chunks (0–599) were safely reused
because neither cursor fix executes in that range. The arithmetic mean of
per-frame scores is **96.09% exact RGB / 70.66% foreground-union exact** before
excluding emulator-only output. For the game-pixel score, frames 0–8 (flat
FCEUX power-on output) are omitted, and the FCEUX `Power on` OSD rectangle
`(2,212)-(46,220)` is masked in frames 9–139. This gives **96.10% / 82.50%**
over frames 9–4692. Counts and method are in
`reference/diagnostics/opening_runtime_recapture_20261025_cursor_origin/game_pixel_match_summary.json`.
The run made 4,038 viewport readbacks and reused 655 unchanged images. Frames
2376–2385 score 97.20% / 94.36%; frames 3900–4660 average 99.91% / 99.81%;
the 4207–4481 logo loop and 4662–4692 title transition are 100% / 100%.
Weak spans include 1535–1755, 2018–2116, 2695–2903, and 2939–3599; frame 2369
is the lowest RGB result at 68.40%. Frames 2939–3599 average 92.49% RGB / 6.07%
foreground; the corrected text PPU cell `$2269=$67` now matches ROM, but
BG0B CHR-bank selection/raster timing remains open. The capture and per-frame
comparison are in
`reference/diagnostics/opening_runtime_recapture_20261025_cursor_origin/`.
Remaining visual gaps are unresolved. This is a same-input image comparison,
not proof that the opening's entire ROM/APU timing has been decoded. The audio
driver was Dummy, so this recapture did not verify audio. Capture method,
metric scope, and startup-overlay caveat are in that directory's `README.md`.

### Targeted fine-X reset correction (2026-10-25)

The ROM's bank-2 IRQ consumer writes `$2006=$2200`, then `$2005=$00,$00`
through `$A187/$A18A`. The event generator had stopped after the `$2006`
marker, leaving line-67 fine-X active in the lower band. It now emits the reset
at the effective next output row. Four targeted captures (502, 506, 758, 800)
score 98.27–98.89% full-frame exact RGB; rows 128–138 are 100% exact for all
four, and rows 139–226 are 99.94–100%. At that earlier correction, the full
4,693-frame RGB mean rose from 94.55% to 95.81% with no regressed frames. The
later full capture above includes additional changes. Remaining mismatches and
other scenes are still open. Evidence and candidate captures are in
`reference/diagnostics/raster_fine_x_reset_20261025/`; the linked cycle trace
is `reference/diagnostics/synchronized_cycle_order_20261024_134001/bus_events.csv`.

### PPU palette commit boundary (2026-10-25)

A second concrete visual gap was found. F9 background selection was causing the
Godot field renderer to use the layout's ROM palette immediately, even though
the actual PPU palette remained all `$0F` until the later F3 packet reached NMI.
The presenter now always feeds the field renderer the currently committed PPU
palette; F3 changes it only on the modeled commit edge. The first transition
(F9 frame 342, F3 frame 378, PPU palette writes frame 380) now matches all-black
FCEUX output at frames 342, 352, 362, 375, 378, and 379: 100% RGB each. Frame
380 is 97.79% exact. The full post-fix recapture also covers the later reveals:
frame 1049 is 96.03% exact RGB, frame 2369 is 68.40%, and frame 4579 is 97.79%.
The low 2369 score shows that the remaining scene-composition mismatch there is
not fixed by the palette boundary correction. Evidence and
candidate PNGs: `reference/diagnostics/palette_commit_boundary_20261025/`;
source notes: `reference/rom_extract/intro/f3_00_palette_source_trace.md` and
`later_f3_f4_palette_selection_trace.md`.

The next exactness work is the targeted command-helper/NMI trace, scene-specific
PPU fetch/OAM mapping, and source-timed DMC/audio path described in
`online_reverse_engineering_resources.md`.

### BG0B camera and sprite X update (2026-10-25)

A muted PC-attributed RAM/OAM trace now decodes BG0B's record at file `$00E23A`.
The shared worker reads `$3F` as signed Q8.8 `-$07C0` and `$08` as eight
32-pixel chunks; the leading `$00` is unused in that setup. `$7C` sets camera
follow flag bit 4, the animator computes `$E8=0-$47`, then adds that inverse
step to every sprite X at `$91D8-$91DB`. The trace confirms `$47=$F8` causes
`$70->$78` and `$47=$F9` causes `$88->$8F`. The copier checks per-sprite
attribute bits `$0C`: while set it writes OAM Y=`$F8`; after the X-wrap logic
toggles bit `$04` off, it writes the source Y and the sprite appears. Full RAM
snapshots show 14/40 visible at frame 2710, 33/40 at 2713, 38/40 at 2714, and
40/40 at 2715. A static `$7A` subtraction matches all descriptors at 2715,
2720, and 2722, but is only a checkpoint cross-check; PPU `$2005` is not the
sprite offset. Full details and remaining Godot verification:
`reference/rom_extract/intro/bg0b_camera_oam_trace_20261025.md`; raw files:
`reference/diagnostics/ram_oam_write_trace_20261025_121710/`.
