# Cold-start visibility edge audit

## Result

This audit narrows the opening's visual boundaries using the supplied Turkish
ROM and silent FCEUX captures. It supersedes the earlier frame-13/14 and
frame-281/282 brackets in `cold_start_ppu_timing_trace.md` where the evidence
below is stronger.

- **Power-on backdrop:** the clean full capture is uniform RGB `(117,117,117)`
  in source frame 0 and remains that color through frame 8. The end-of-frame
  PPU palette bytes are `$00` throughout frames 0–8; the external
  `FCEUX_internal_default_2.7.0_rgb.pal` maps NES color `$00` to RGB 117. The
  source-frame-8 RAM packet at `$05E8` starts `20 00 3F 0F` and contains 32
  `$0F` palette bytes. On source frame 9, the live NMI consumer at `$A03C`
  writes those bytes to `$2007` from `$3F00`; the PPU palette snapshots are
  all `$0F` from frames 9–12, which maps to black. This supplies the ROM-backed
  gray-to-black backdrop transition used by the source presenter.
- **Logo reveal:** source frame 12's game viewport is black. In source frame
  13, the first logo pixel in the FCEUX output is at `(x=79, y=77)`; the frame
  is visibly no longer black. The output row maps to visible PPU scanline 77
  under the capture's zero-based 256×240 frame layout. Do not use the FCEUX
  `Power on` overlay at the bottom of these diagnostic screenshots as game
  pixels. The overlay persists through source frame 139 in the clean full
  capture. Its visible card occupies x=2–46, y=212–220; including the outer
  edge, the raw pixel-difference footprint is x=1–47, y=211–221. Mask that
  footprint only during reference comparison and never render it in Godot.
- **Fade-to-black:** source frame 281 still shows the dim logo; source frame
  282 is an all-black game viewport. The synchronized trace places its palette
  upload in vblank before visible scanline 0, so black begins at the first
  displayed scanline of source frame 282. The exact PPU dot of that transition
  was not sampled by a pixel hook.

## Capture and alignment

The reference ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
`reference/diagnostics/synchronized_cycle_order_20261024_134001/` is a quiet
FCEUX 2.7.0 `--newppu 1` replay of the recorded input. It records PPU scanline
and dot with bus writes and shows each `frameadvance` starting and ending at
scanline 240. A second quiet run,
`reference/diagnostics/synchronized_cycle_order_20261024_154547/`, saved only
boundary screenshots and per-frame PPU/RAM snapshots. It uses the same ROM and
input timeline. Although this stock Homebrew build did not expose the patched
PPU scanline getter, its PPU and RAM snapshots are byte-identical to the
synchronized run at frames 12, 13, 14, 267, 268, 280, 281, 282, and 283. The
screenshots are observation evidence only, never runtime assets.

For source frame 13 the synchronized trace records palette `$2007` writes on
PPU scanlines 246–250 and restores `$2001=$1E` at scanline 251, dot 112. The
frameadvance interval starts at scanline 240 and wraps through visible lines
0–239 after these writes. Therefore the updated palette is active for source
frame 13's visible output; the screenshot pins the topmost logo pixel to output
row 77, rather than merely proving that the frame-end PPU snapshot is ready.
The exact PPU dot corresponding to screenshot column 79 is not independently
sampled; row-to-scanline mapping is based on FCEUX's raw 256×240 output layout.

For source frame 282 the `$05E8` packet writes `$0F` to all 32 palette bytes
during vblank (scanlines 246–250). The source's EA handler at `$858D` first
calls `$99F0`, then `$9B7F`, and invokes `$98E8` with `(address=$2000, rows=16,
width=32)` followed by `(address=$2400, rows=32, width=32)`. The live trace
records 1,536 zero `$2007` writes from PC `$9953`, beginning at scanline 55 and
ending at scanline 196, dot 80. Rendering is masked from vblank until
`$2001=$1E` at scanline 196, dot 194; by then the clear writes are done. The
frame-282 screenshot confirms the complete visible output is black. Frame 281's
screenshot and nonzero PPU palette snapshot confirm it is still visible before
that boundary.

The same ROM palette state drives the boot backdrop in the isolated source
presenter: palette index `$00` through frame 8 maps to gray RGB `(117,117,117)`;
the initial `$0F` packet committed in frame 9 maps to black through frame 12.
A narrow main-scene Godot capture of frames 0–13 matches the clean FCEUX
capture at every compared pixel after masking the OSD footprint. The frame-13
logo sprite is shown with the first-visible output edge despite the presenter's
one-frame OAM display latch.

## ROM and online-source check

The public `bank_80.asm` disassembly labels `$858D` as the EA screen-off handler
and annotates the two `$98E8` clear calls. The relevant local ROM bytes were
checked at `$858D` (file `0x0059D`), `$98E8` (`0x018F8`), and `$99F0`
(`0x01A00`); the project's broader comparison recorded all 3,872 annotated
bank-80 bytes as matching this ROM. Use those online labels as verified leads,
not as substitutes for this local byte/event trace. See the [annotated bank-80
listing](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/master/bank_80.asm)
and [FCEUX Lua API notes](https://fceux.com/web/help/LuaFunctionsList.html)
for frame advancement and diagnostic screenshot APIs.

## Remaining precision limits

The first logo output is now located to source frame 13, output pixel `(79,77)`;
its dot-level PPU coordinate has not been directly captured. Black output begins
on source frame 282's first displayed scanline, but no pixel callback sampled
the exact dot. The screenshot-only run and scanline/dot event run are separate
FCEUX processes, aligned by the same input replay and byte-identical PPU/RAM
snapshots at the sampled boundary frames. Neither screenshot image nor its
RGB/WAV data is a shipped asset.
