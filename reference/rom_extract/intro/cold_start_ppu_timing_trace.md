# Cold-start logo lead-in and first palette reveal

## Scope and source identity

This trace examines the supplied Turkish ROM (`Captain Tsubasa 2-Super
Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`) against
`reference/opening_timing_capture_20261024_131316/`, a FCEUX power-on replay
with source frames 0–4692. The capture metadata records a successful
`FCEU.poweron()`, emulator frame 0, per-frame PPU/RAM snapshots, and
cycle-stamped CPU writes. ROM and CPU/PPU state are evidence; no screenshot or
recorded sound is used as a runtime asset.

The cycle counter is CPU-cycle granularity. FCEUX's Lua API used by this
capture did not expose the PPU scanline/dot for each event, so cycle offsets
cannot prove the exact pixel or scanline of a visible edge. Snapshot files are
end-of-frame state, not a raster video.

## Confirmed reset/start sequence

At bank-0 CPU `$8020` (ROM file `0x000030`), the startup path first calls
`$9BA0`, then executes `LDA #$00; JSR $8464` to dispatch cutscene 0. It then
enters a cooperative loop (`JSR $9FA8`) and checks the newly pressed Start bit
in `$1E & $10`; until Start is pressed it clears several work bytes and
continues the intro. The dispatch call is visible at ROM file `0x000035`
(`A9 00 20 64 84`). The E8 preset's byte-verified source and RAM copy are
separately documented in `e8_preset_01_trace.md`.

In the fresh timing capture, the first observed CPU-side PPU writes are
`$2000=$08` at source frame 1, cycle 18, PC `$C653`. Frames 0, 2, and 3 have
no captured `$2000/$2001/$2005/$2006/$2007` writes. At frame 4, cycle 22640,
startup code writes `$2001=$06` (PC `$C685`); later the same frame it selects
`$2000` and begins a large `$2007` transfer (757 writes, PC `$CB70`). `$06`
leaves both background and sprite rendering disabled (PPUMASK bits 3 and 4
clear), so these initial data transfers do not imply visible output. In frames
5–8 the initialization routines repeatedly stage CHR/nametable state and
change PPU control/mask. The frame-end mapped PPU snapshots are byte-identical
for frames 0–7; frame 8 first differs in 64 nametable bytes.

This documents the observed entry path and PPU setup effects; the full `$9BA0`
initialization routine's scheduler task graph is not reconstructed here.

## E8 / MMC3 and PPU state during the logo setup

E8 preset 1's source record and copy destinations are established in
`e8_preset_01_trace.md`. The fresh capture provides a concrete consumer-side
cross-check: beginning at source frame 9, CPU `$A09E/$A0A1/$A0A4` writes MMC3
IRQ latch `$C000=$80`, reload `$C001=$80`, and enable `$E001`; the same setup
repeats on following logo frames. IRQ acknowledgements/enables also occur
around cycle 16975 at PC `$A163/$A166`. MMC3 CHR bank writes are present in the
capture, including bank register 7 updates from the fixed-bank routines. This
supports that E8's preset participates in the mapper/raster setup, but does
not establish the IRQ's exact visible scanline, the full bank selection at
each PPU fetch, or a complete raster model.

At source frame 9 the screen-update path (PC `$A019`) briefly writes
`PPUMASK=$00` at cycle 608, uses `PPUCTRL=$80`, uploads palette bytes at
`$2007`, then restores `PPUMASK=$1E` at cycle 1177 (PC `$A062`), sets
`PPUCTRL=$88`, and writes scroll `(0,$FF)`. It performs a similar per-frame
palette/update sequence through the reveal. `$1E` enables background and
sprite rendering. The raster IRQ and bank changes continue during this
period, but the trace cannot map each register write to an exact scanline.
The source-addressed producer and NMI consumer for the `$05E8` palette packet
are traced in `cold_start_palette_nmi_commit_trace.md`: `$C76E` branches to
`$C421` when captured `$1B=$40`, and `$C421` calls the banked `$A000` packet
consumer. In source frame 13 that consumer uploads 32 bytes to `$3F00` at
cycles 649–1125 and restores rendering at cycle 1177. The cycle trace still
does not identify the first lit pixel or scanline.

## What the black lead-in evidence actually establishes

The prior note claiming the screen stays black through frame 25 and that the
logo first appears at frame 26 conflated the frame-26 reconstructed reference
with the cold-start onset. The fresh capture's palette snapshots disprove that
as a source-backed boundary:

- PPU palette RAM is all `$00` in frames 0–8. At frame 9 it becomes all `$0F`,
  which is the captured NES palette's black entry; it remains `$0F` through
  frame 12. These frames are black even when the renderer is enabled.
- In frame 13 the palette is first populated with non-`$0F` colors. The logo
  layout has already been staged: the mapped nametable changes at frame 8,
  and ROM-derived logo tile writes occur in frames 10–11. Therefore frame 13
  is the first frame-end PPU state capable of showing colored logo pixels.
- Frames 13–26 show evolving palette values consistent with a color reveal;
  the sprite and glyph patterns do not need to be re-uploaded each frame.
- The earliest directly observed non-black logo image in the older sparse
  screenshot set is file `reference/opening_capture/frames_png/frame_00014.png`.
  That capture has a different session/frame origin (it begins with an
  already-running soccer scene), so its filename must not be aligned directly
  to source frame 14 of the fresh `opening_timing_capture` replay.
- A ROM-derived frame-14 candidate already exists at
  `reference/diagnostics/full_intro_render_calibrated/frame_000014.png`.
  Its JSON records ROM CHR, PPU nametable/palette, RAM OAM, the external FCEUX
  palette, and `screenshot_pixels_used: false`. The candidate's PPU pattern,
  nametable and palette bytes plus RAM at frame 14 match the corresponding
  fresh-capture snapshot data. This proves that an original-data frame can be
  generated without copying screenshot pixels; it does not prove the raster
  plan or make the candidate a verified runtime frame.

Thus the fresh replay bounds the palette-based reveal to source frame 13 (first
non-black frame-end palette) but does **not** prove the exact first lit pixel.
The palette writes finish before rendering is restored at cycle 1177 in frame
13. Existing raster plans place visible scanline 0 about 2387 CPU cycles after
the frame-start baseline (a 21-scanline vblank assumption), so cycle 1177 is
estimated to be in vblank, before visible scanline 0. This makes scanline 0 of
source frame 13 the earliest plausible output edge, not a verified first-pixel
timestamp: the register capture has no actual PPU dot/scanline field and no
direct screenshot for that precise frame. The observed first-visible bracket
is therefore source-frame 13–14; first lit pixel and exact scanline remain
unproven. Frames 0–8 have all-zero palette snapshots; frames 9–12 are
black-palette states.

The first reconstructed image at frame 26 remains a useful composition target
(the background scroll and OAM/pattern mapping are documented in
`logo_frame26_glyph_trace.md`), but it is not the onset frame. A frame-13 PNG
can be regenerated from its PPU/RAM snapshots and ROM CHR with the diagnostic
renderer; exact frame-13 raster planning remains uncertain, so generating it
does not by itself justify a frame-exact runtime manifest change. The
conservative present decision is to retain the current manifest while the
first visible frame edge and palette-flash durations are resolved.

## EA screen-off / clear interval

End-of-frame RAM snapshots bracket the script pointer: `$A028` (DF pending)
at frame 27, `$A029` (EA pending) at frame 267, and `$A02C` after the `$ED $58`
sound command at frame 282. The ROM pause table defines DF as 240 ticks; the
observed 240-frame pointer interval is consistent with that wait, with a
possible one-frame boundary ambiguity from frame-end sampling.

During frames 268–281, the same screen-update path repeatedly masks rendering
while it changes palette entries. Frame 281's palette is still being cleared;
frame 282 performs a much larger PPU data transfer (1,568 `$2007` writes in
the fresh event log), including nametable/background cleanup. The pointer has
advanced to `$A02C` by the frame-282 snapshot. This supports an EA-driven
multi-frame fade/clear stage that settles to black around frame 282, not an
instantaneous `EA => hide` edge. However, the capture does not identify an
exact first all-black displayed frame, clear-completion scanline, or whether
one last rendered line uses the old palette. Do not implement an exact EA
transition frame from these snapshots alone.

## Palette packet transfer from synchronized capture

The later synchronized capture at
`reference/diagnostics/synchronized_cycle_order_20261024_134001/` adds PPU
scanline/dot coordinates and confirms the source path described in
`cold_start_palette_nmi_commit_trace.md`. The NMI route reaches fixed-bank `$C421` when
`$1B` bit 6 is set; `$C421` maps PRG bank 2 and calls its `$A000` packet
consumer. This is distinct from the `$C8FB` generic queue.

For the sampled palette fade, the packet staged at end-of-frame RAM in source
frame 12 is written byte-for-byte by `$A03C` to `$2007` during source frame
13; the frame-13 PPU palette snapshot matches those bytes. The packet staged
at frame 13 is written in source frame 14, whose PPU palette snapshot matches
it. These samples prove a one-NMI staging-to-PPU delay.

In source frame 13, the uploader writes `$2001=$00` at cycle 608, writes
`$2006=$3F,$00` at cycles 633 and 641, transfers 32 palette bytes at cycles
649–1125, then restores `$2001=$1E` at cycle 1177. The synchronized PPU
positions place these events on scanlines 246–251, during vblank. The next
visible scanline can use the new palette, but the exact first colored pixel
is still not captured. The earlier sparse screenshot's frame numbering is
from a different session and does not resolve that pixel boundary.

## Timing facts and remaining gaps

| Claim | Evidence | Status |
|---|---|---|
| Cold-start PPU register write begins | Frame 1, cycle 18, `$2000=$08`, PC `$C653` | Direct bus trace |
| Initial bulk PPU upload is hidden | Frame 4 `$2001=$06`; PPUMASK render bits are off | Direct bus trace + register semantics |
| E8 IRQ/raster setup active | Frame 9 `$C000/$C001=$80`, `$E001`; repeats | Direct bus trace, exact scanline unknown |
| Palette remains black after logo data is staged | Frames 9–12 palette bytes `$0F` | Direct frame-end PPU snapshots |
| First palette state can display colored logo | Frame 13 has nonblack palette; frame-13 update restores `$2001=$1E` | Direct PPU snapshot + bus trace; exact first pixel unknown |
| Logo visible in a direct screenshot | Separate sparse screenshot session, visible at its file frame 14 | Direct image, not same frame origin as fresh timing replay |
| DF duration | `$A028` at 27 to `$A029` at 267; ROM DF table=240 | Strongly supported, edge ±1 frame |
| EA clear settles | Palette is clearing in 268–281; bulk PPU clear in 282 | Multi-frame transition confirmed, first black output edge unknown |
| Palette packet transfer | Frame-12 staged packet is written in frame 13; frame-13 packet in frame 14 | Direct RAM/bus/PPU comparison; one-NMI delay for sampled fade packets |

No exact deterministic Godot scheduler mapping is proven by this trace; code
changes would be guesswork. The next evidence needed for a scanline-exact edge
is a synchronized frame/scanline/dot and displayed-pixel capture from the same
power-on replay, or a byte-verified FCEUX instrumentation build that records
those raster coordinates alongside the PPU register/mapper writes.

## 2026-10-24 visibility-edge update

The later silent boundary capture supersedes the frame-13/14 and frame-281/282
display brackets above. It shows source frame 12's game viewport black, the
first logo pixel in source frame 13 output at `(79,77)`, the dim logo in frame
281, and a fully black viewport in frame 282. The synchronized PPU trace places
the frame-13 palette writes and frame-282 final `$0F` packet in vblank before
visible scanline 0. Thus the observed logo pixel is at output row/scanline 77
of frame 13, and black starts at frame 282's first displayed scanline. Neither
pixel's exact PPU dot was directly sampled. Screenshot and raster-event
captures were separate processes, aligned with byte-identical PPU/RAM
snapshots at the sampled frames. Full method and source details:
`cold_start_visible_edge_audit.md`.
