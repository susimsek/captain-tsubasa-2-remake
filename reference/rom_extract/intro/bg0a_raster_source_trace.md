# BG0A E8 preset and raster path

## Scope and ROM identity

This note traces the scroll/raster setup relevant to background `$0A` in the
supplied Turkish ROM (`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`).
ROM bytes define the model. RAM and PPU bus captures below are validation
evidence only; no captured image or per-frame memory dump is a runtime input.

## E8 `$01` seeds the shared raster state

The cutscene dispatch trace records `E8 01` at `$A08B` / file `0x00609B` on
source frame 814 (and at the start of the replayed script). The bank-0 handler
calls `$8920`, which reads the preset at bank-6 `$BF13`, file `0x00DF23`.
Its 19 source bytes are preserved unchanged in
[`raster_event_state/preset_01.bin`](raster_event_state/preset_01.bin):

```text
40 80 00 22 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

The copy operation writes byte 0 to `$79`, writes zero to `$7A`, leaves `$7B`
untouched, and copies bytes 1–18 to `$7C–$8D`. Thus the source-backed values
needed later are `$79=$40`, `$7A=0` at the E8 edge, and `$7C–$7E=$80,$00,$22`.
The byte-copy routine and bus/RAM cross-check are described in
[`e8_preset_01_trace.md`](e8_preset_01_trace.md).

The later script transition at `$A1BA` selects background `$0A`; `FB 03 C0 A2
7D` follows at `$A1BC` and `F3 00` at `$A1C1` (source frame 2367). These
commands do not rewrite the E8 raster fields. End-of-frame RAM snapshots at
frames 2367, 2608, and 2680 retain `$79=$40`, `$7C–$7E=$80,$00,$22`; `$7A/$7B`
are subsequently changed by the camera update.

## BG0A vblank setup and IRQ handler

The shared bank-2 setup routine at `$A086` begins with ROM bytes
`A5 7A 8D 05 20`: it writes `$7A` to `$2005`. It later loads `$79` and, when
nonzero, doubles it into the MMC3 latch/reload registers. For `$79=$40`, the
counter value is `$80`. The setup writes `$78=4` before enabling the IRQ.

Bank-2 `$A160` (file `0x004170`) is the IRQ consumer. It examines the event
marker at `$78+X`; at cursor 4, `$7C=$80` selects the address-reload branch.
That branch loads `$7D/$7E=$00/$22`, writes `$2006=$22,$00` (address `$2200`),
restores `$2000` and writes `$2005=0,0`. The terminal path `$A1C0` clears
`$78`, installs the lower CHR pair, and disables further IRQ work.

The shared handler and preset were observed with a line-aware trace for BG08:
the address write is on scanline 129, and the two zero-scroll writes straddle
scanlines 129/130. BG0A uses the same `$A086/$A160` handler and preset. Its
frame-2680 CPU bus trace confirms the same register order and values, but has
no PPU dot/scanline fields. The BG0A model therefore uses scanline 129 for the
address event and scanline 130 for the second scroll event, based on the
shared-handler trace. The exact first affected color pixel remains unverified.

## Moving camera producer and Godot state

Bank-0 `$8DB5` (file `0x00DC5`) performs `$7A -= $6A` and subtracts the borrow
from `$7B`. For F9 `$0A`, the generic record loader reaches the camera triple
at bank-7 `$A227` (file `0x00E237`), whose preserved bytes are `00 21 04`.
The setup at `$8BD4–$8BF7` converts `$21` into Q8.8 magnitude `$0040`, marks it
negative and selects the global `$7A/$7B` integrator; `$04` is four 32-pixel
chunks. `$8D88–$8DB3` adds the signed quarter-pixel step to `$69/$7A:$7B`,
accumulates the absolute fractional movement in `$6A`, and consumes one chunk
per 32 pixels. `$8DB5–$8DC5` applies the final residual. This decodes the first
triple only; it does not generalize later record formats.

The camera record is parsed at F9 dispatch (source frame 2340 in the captured
opening run), but motion starts only after the generic background packet
producer completes. The presenter supplies that completion edge to the model;
the two scheduler releases in the ROM record then place the first camera update
three source frames later. In the captured run, loader completion is frame
2367 and the first update is frame 2370. This explains why `$7A` remains zero
at frame 2367 and avoids starting the camera at F9 dispatch. The resulting
ROM-record/integrator model matches captured `$69/$6A/$72/$7A/$7B` at frames
2369, 2370, 2570, 2580, 2680, and 2682. These RAM snapshots are validation
only.

[`scripts/opening/rom_bg0a_raster_model.gd`](../../../scripts/opening/rom_bg0a_raster_model.gd)
validates the preserved E8 and BG0A source bytes, generates the `$2200` address
reload and zero-scroll raster events, and computes the first camera triple's
state from the record plus the loader-completion edge. The source presenter
feeds that state to the renderer; it does not read captured RAM at runtime.
The first affected pixel's exact subscanline phase remains unresolved, so the
scanline-129 address event and line-130 scroll event still rely on the shared
handler's BG08 line-aware trace described above.

Focused validation was run with `tools/diagnostics/verify_bg0a_raster_model.gd`
and `tools/diagnostics/capture_bg0a_runtime_frames.gd`. The RAM model check
matches the recorded camera registers at frames 2367, 2369, 2370, 2570, 2580,
2680, and 2682. At frames 2367 and 2369 the model is still at zero scroll;
frame 2370 applies the first one-pixel negative update. The renderer comparison
covers all 149 available same-input FCEUX screen checkpoints from frames
2370–2762. It advances and draws each source frame in sequence. Across all 149
frames, exact RGB match averages 74.75% with the old F9-dispatch camera anchor
and 75.20% with the loader-completion anchor. The 128 checkpoints through frame
2684, where the camera record is active, average 72.33% before and 72.86% after;
each comparison is non-worse. Frame 2682 remains the weakest post-fix checkpoint
at 66.55% exact RGB (65.85% before). The 21 later checkpoints from frame 2686
onward are unchanged. RAM scroll registers match at the verified anchors, so
the remaining visual difference is in composition and unresolved pixel phase,
not a mismatch in this camera value model.

## BG0A block placement and packet traversal correction (2026-10-25)

The BG0A record at file `0x00E201` / bank-7 CPU `$A1F1` stores four rows of
twelve block IDs in left-to-right record order. Its packed origin `$07` decodes
to PPU address `$201C`, but that address is the initial destination cursor for
the final record column (`c=11`), not record column zero. The loader emits each
record row from column 11 down through column 0, decrementing the 4-tile PPU
cursor at each block and wrapping modulo the two 32-tile nametables. Therefore
the source record's final world coordinate is
`x=(48+4*c) mod 64`, `y=4*r`. In particular, c=11 maps to x=28 / `$201C`, and
c=0 maps to x=48 (nametable `$2400`, local column 16).

This mapping was reconstructed by matching the ROM-selected 17-byte blocks to
the queued writes from the F9 `$0A` transfer over source frames 2342–2368.
All 240 packet destinations and payloads matched: one attribute packet and four
tile-row packets for each of 48 blocks. Page 1 first receives the BG0A packet
at frame 2346 (`$27C7` attribute); its final tile-row packet is frame 2368 at
`$25F0`. The preserved PPU/RAM capture is validation evidence only; runtime
layout and packet data continue to come from the ROM record and extracted ROM
blocks.

The previous static decoder treated `$201C` as the top-left origin and placed
column c at `(28+4*c) mod 64`, shifting every block by 20 tile columns. The
decoder now preserves record order but records the ROM's reverse-per-row packet
traversal and corrected world mapping. The runtime packet builder emits that
traversal for BG0A, while other background layouts retain their existing
row-major default until independently traced. FCEUX NewPPU source shows the
temporary `$2000/$2005` latches load at pre-render scanline 0, dot 304; the
renderer now applies BG0A `$2000=$89`, `$2005` Y=`$FF`, and current camera X to
the first visible row. This replaces the previous row-0-deferred, zero-offset
candidate. The corrected layout and latch model still need a fresh same-input
Godot image comparison; the split's exact first affected pixel and sub-scanline
phase remain unresolved.

The pre-fix screenshots were generated with a temporary diagnostic variant
that started the camera at F9 dispatch, then the production presenter was
restored. Captures are validation only. These figures do not claim exact scene
reconstruction; the address reload's exact first affected color pixel remains
unresolved. The sequential post-fix images and rates are in
[`reference/diagnostics/bg0a_camera_runtime_compare_1792909096/`](../../diagnostics/bg0a_camera_runtime_compare_1792909096/);
the matching pre-fix images are in
[`reference/diagnostics/bg0a_camera_runtime_compare_1792909169/`](../../diagnostics/bg0a_camera_runtime_compare_1792909169/).

## Initial PPUCTRL and lower CHR pair follow-up (2026-10-25)

The BG0A frame-2680 bus trace records `$2000=$89` at `$A086`, then `$2005=$B2,$FF`;
the IRQ writes `$2006=$2200`, restores `$2000=$88`, writes `$2005=0,0`, then
sets MMC3 background registers R0/R1 to `$00/$02` at `$A1D4/$A1D7` and
`$A1E0/$A1E3`. The raw PPUCTRL value and its horizontal nametable bit are kept
in `RomBG0ARasterModel` metadata. A first renderer attempt treated bit 0 as a
256-pixel world offset on scanline 0. It made the visible upper panorama worse:
at frames 2680/2682/2684, upper y=0–127 exact RGB moved from 58.57/58.29/66.75%
to 53.12/53.14/58.27%. The same attempt improved the lower split/text because
it applied the ROM-selected R0/R1 pair; exact RGB at y=144–207 became
99.77/100/99.63%, and y=208–239 became 100% at all three checkpoints.

The source of page `$2400–$27FF` is partially traceable in the same-input
capture: it held 72 nonzero tile bytes at frame 2335, was zero at frame 2336,
then held 204 at frame 2367 and 224 at frame 2368 while F9 `$0A`'s background
transfer completed. The associated `$2006/$2007` writes come through the NMI
queue at `$A030/$A03C`, and the ROM-derived BG0A map spans the two-page
nametable plane. This shows the populated page is written during the BG0A
load; the exact packet-to-page mapping and first-line loopy-address phase have
not yet been reconciled with the current renderer's two-page coordinate model.
The renderer therefore retains the observed `$2000=$89` and `$2005` Y=`$FF`
values as metadata, but currently uses zero initial NT-X and Y offsets. These
are provisional renderer mappings to avoid measured composition regressions;
they do not claim the hardware bits/writes are ignored or the true initial Y
scroll is zero. The lower R0/R1 split remains enabled, with its candidate first
affected scanline/dot still unverified.

Relevant evidence: `reference/opening_timing_capture_20261024_131726/bus_events.csv`,
`ppu_states/ppu_02335.bin`, `ppu_02336.bin`, `ppu_02367.bin`, and `ppu_02368.bin`.
The candidate NT-X render is retained for comparison at
[`reference/diagnostics/bg0a_camera_runtime_compare_1792909754/`](../../diagnostics/bg0a_camera_runtime_compare_1792909754/);
the NT-X=0/Y=`$FF` diagnostic at
[`reference/diagnostics/bg0a_camera_runtime_compare_1792910204/`](../../diagnostics/bg0a_camera_runtime_compare_1792910204/)
shows why the raw Y byte is not yet used as a viewport origin. The final
provisional renderer candidate, with raw PPUCTRL/scroll retained only as model
metadata and the lower CHR pair active, was captured sequentially at all 149
available checkpoints from frames 2370–2762 in
[`reference/diagnostics/bg0a_camera_runtime_compare_1792910385/`](../../diagnostics/bg0a_camera_runtime_compare_1792910385/).
Its mean exact RGB is 83.17% across those checkpoints. Frames 2680/2682/2684
are 77.43/77.34/81.75% exact overall. Their upper y=0–127 results
(58.57/58.29/66.75%) equal the camera-only baseline; y=128–143 improves to
93.75% at each frame, text y=144–207 is 99.77/100/99.63%, and y=208–239 is
100% at each frame. This validates the lower CHR gain without retaining the
upper regression, but does not resolve the initial NT-X/Y mapping or first
affected pixel phase.

## Evidence files

- `e8_preset_01_trace.md`: E8 handler, preset copy, and earlier capture checks.
- `later_f3_f4_palette_selection_trace.md`: BG0A command order and source frame.
- `bg09_pink_field_source_trace.md`: shared `$A086/$A160` PPU register sequence.
- `field_runner_chr_raster_split_trace.md`: source bytes and the line-aware
  shared IRQ trace, including scanline-129 address reload and line-130 scroll.
- `reference/opening_timing_capture_20261024_131726/ram_states/ram_02367.bin`,
  `ram_02370.bin`, and `ram_02680.bin`
  and `bus_events.csv`: BG0A source-frame RAM/CPU bus validation only.
