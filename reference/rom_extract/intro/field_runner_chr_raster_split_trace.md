# Field-runner CHR split: source frames 380–808

## Evidence scope

Source ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The source frames 380–808 are present in the same-core, same-input FCEUX
capture `reference/diagnostics/synchronized_cycle_order_20261024_134001/`;
its metadata maps `script_frame = source_frame + 1`. Captured pixels are used
only for comparison. The ROM bytes, RAM snapshots, and PPU bus writes below
are the evidence.

## Background and CHR pair source

The Turkish ROM's background `01` record is at file offset `0x00E0EF` and
starts with `3C 3E`. `background_01_layout.json` independently decodes these
as the two 2 KiB CHR selectors for the field (`R0=$3C`, `R1=$3E`), which map
to 1 KiB pattern banks 60–63. Its field metatile layout matches all 1,024
captured nametable tile IDs and all 64 attribute bytes in the frame-380
snapshot (`intro/README.md`).

The source code that installs the two selector pairs is PRG bank 2. Relevant
bytes were read directly from the supplied ROM (file offsets include the
16-byte iNES header):

| CPU address | File offset | ROM bytes | Direct interpretation |
|---|---:|---|---|
| `$A091` | `0x0040A1` | `A0 16 20 CB A1` | `LDY #$16; JSR $A1CB` |
| `$A1C0` | `0x0041D0` | `8D 00 E0 85 78 A0 18 20 CB A1` | Disable/ack IRQ; clear `$78`; `LDY #$18`; call `$A1CB` |
| `$A1CB` | `0x0041DB` | `B6 78 A9 00 05 22 8D 00 80 8E 01 80 B6 79 A9 01 05 22 8D 00 80 8E 01 80 60` | Select R0 and write `($78+Y)` to `$8001`; select R1 and write `($79+Y)`; return |

The indexed source pair for Y=`$16` is RAM `$8E/$8F`; for Y=`$18` it is
`$90/$91`. Across all 429 captured source frames 380–808, end-of-frame RAM
keeps `$8E/$8F/$90/$91 = 3C 3E 00 02` and `$79=$18`. This identifies a
field-pattern pair and a second pair selected during the active raster path.

## Observed raster writes

The synchronized trace records the full-screen setup pair in vblank, then the
second pair during visible scanline 134. Frame 380 is representative:

| Source frame 380 event | PPU position | MMC3 write | Meaning from the verified routine |
|---|---:|---|---|
| setup | scanline 252, dots 307–319 | `$8000=$00`, `$8001=$3C` | R0 = `$3C` |
| setup | scanline 253, dots 17–29 | `$8000=$01`, `$8001=$3E` | R1 = `$3E` |
| raster update | scanline 134, dots 131–144 | `$8000=$00`, `$8001=$00` | R0 = `$00` |
| raster update | scanline 134, dots 182–195 | `$8000=$01`, `$8001=$02` | R1 = `$02` |

The line-134 sequence repeats in every source frame 380–808: the trace has
429 occurrences of each R0/R1 pair write. In MMC3 2 KiB mode, the first pair
selects banks 60–63, and the second selects banks 0–3. At the same time, the
visible-frame trace has `$8001` values `$88,$09,$0A,$0B` for R2–R5; on mapper
4 these retain 1 KiB pattern banks 8–11 for the other pattern slots.

The callback's `cpu_pc` is sampled after the write instruction: for example,
the `$8001=$00` event tagged `$A1D7` follows the ROM instruction at `$A1D4`
(`8E 01 80`, `STX $8001`); `$A1E3` similarly follows `$A1E0`.

## What this resolves and what remains open

This is a real mid-frame CHR change, not merely a frame-end snapshot showing
two alternative complete pattern sets. The 380–808 renderer can source both
ROM bank pairs and the trace pins the writes to scanline 134. However, the
R0/R1 writes complete at dot 195, during the visible part of that scanline.
The current diagnostic renderer changes its per-pixel CHR lookup at bus-event
positions, but it does not retain the 2C02 background fetch/shifter bytes
already latched before those writes. Therefore the first screen pixel/tile
that uses banks 0–3 is still unproven; a flat whole-row boundary at y=134 is
not established by these writes. Exact pixel placement requires a fetch-pipeline
model (including the MMC3 bank change's effect on subsequent pattern fetches),
not a different ROM asset or a screenshot-derived replacement.

This explains one concrete limit in the weakest runner/dialogue comparison
segment without claiming that it alone accounts for every color mismatch.
Runtime code was not changed.

## Scroll-event producer and PPU effects (24 Oct 2026)

Two additional silent same-input captures watched CPU RAM writes to
`$0078–$008D` during source frames 378–400. Their diagnostics are retained in
`reference/diagnostics/raster_table_writes_20261024_212456/` and
`reference/diagnostics/raster_table_writes_20261024_213332/`. The installed
Homebrew FCEUX build could not return PPU scanline/dot from Lua, so these files
provide CPU cycles/PCs while the earlier synchronized bus capture supplies
PPU positions. Captures are analysis-only; no per-frame table dump is a
runtime asset.

The bank-2 consumer is `$A160` (file `0x004170`). It uses `$78` as an event
index, reads the event marker and scroll/address fields, writes `$2000`,
`$2005` or `$2006`, advances the index by three bytes, and schedules the next
MMC3 IRQ. At the terminal marker it disables the IRQ and installs the lower
CHR pair. Source bytes `$A160–$A1D7` were checked directly in the supplied
ROM. The scroll-event producer is bank-2 `$A2E8` (file `0x0042F8`); its inner
stores at `$A317/$A326` (files `0x004327/0x004336`) were observed at callback
PCs `$A319/$A328`. It reads ROM delta tables `$AADF/$AAE0` (files
`0x004AEF/0x004AF0`) using scheduler phase `$ED`, then updates five
signed/fractional accumulators at `$7A/$7B`, `$7D/$7E`, `$80/$81`, `$83/$84`,
and `$86/$87`. `$78` controls the event-slot cursor; the event fields encode
the observed raster intervals and scroll/address values. For example, frame
394's producer writes `$7D=$01` and `$80=$04`; the IRQ consumer later emits
fine-X scroll `$01` at line 49 and `$04` at line 67. This confirms a reusable
ROM-derived delta generator rather than a fixed frame-to-scroll table.

The preset caller is now resolved from the F8 dispatch convention. At source
frame 378, script command `$F8 $0A` reads the bank-2 table word `$A5DB` at
`$A491`; the handler uses RTS, so execution enters `$A5DC` (file `0x0045FC`).
That subroutine writes `$57=0` through `$8895`, then calls `$8920` with A=`$05`.
`$9DEE` computes the 19-byte record offset and loads bank-6 `$BF5F` (file
`0x00DF6F`); its fields match the observed baseline `$79=$18`, `$7C=$08`,
`$7F=$20`, `$82=$80`, and `$84=$22`. The previously reported `$A5EA`/preset-4
interpretation was an address/index error and is withdrawn.

Task `$0D` has stack pointer `$94`; `$9FA8` saves `$ED` in its task stack. In
the new frame-379–394 RAM-write traces, each resume returns at `$A2FD` with
`$ED=$00` and `$EC=$0F`, then resets `$EC`, runs `$A2E8` through five entries
using the ROM delta data, and yields again. This identifies the inputs for
that sampled interval. The source-derived producer now runs in the Godot
opening presenter through `scripts/opening/rom_raster_event_generator.gd`.
It loads the preserved preset and delta bytes, reproduces the five fractional
accumulators and event list, and supplies events to
`scripts/opening/rom_ppu_nametable_screen_renderer.gd`. The generator's
`$78–$8D` frame-end table matched the live FCEUX RAM capture for every sampled
source frame 378–400 (23/23 frames, zero byte mismatches). Initial task
installation/NMI cycle timing remains frame-aligned rather than CPU-cycle-
executed.

The producer seed and saved-phase path were then confirmed in the ROM. Bank-0
`$8895` (file `0x0008A5`) receives A=0, writes `$57=0`, starts task slot `$0D`
through `$88A8/$88A9`, then calls `$9F69`. Bank-2 `$A2EC` copies `$57` into
`$ED`, clears `$E6–$FF`, and `$A2FA` yields through `$9FA8`. The yield stores
`$ED` at `$9FAE–$9FB0` (files `0x001FBE–0x001FC0`); scheduler restore at
`$9F4A` writes `$ED` (callback PC `$9F4D`, file `0x001F5D`). In the sampled
frames, the zero-valued task restore is followed by producer store `$A319`
exactly 63 CPU cycles later. The routine visits Y=`0,2,4,6,8` / event offsets
`0,3,6,9,12`; ROM `$AADF` deltas `10,10,40,00,00` update fraction
accumulators `$E6–$EA`, while `$AAE0` contributes zero deltas to the five
scroll-event values. This predicts the observed `$80=1` at frame 382 and
`$7A=1,$7D=1,$80=4` at frame 394. It removes the unknown preset/phase seed for
this interval; cycle-exact startup/NMI phase and runtime execution are still
open.

Pinned FCEUX 2.7.0 NewPPU source (`src/ppu.cpp`) establishes how these writes
affect output. The first `$2005` write changes fine-X `fh` immediately; for
the captured line-49/67 events, its first candidate pixel is x=0 on output
row y equal to that scanline. The horizontal coarse-X latch copies at dot 257,
after these writes, and affects later fetches; the sample values 0/1/4 all
have coarse X zero. The second `$2005` only changes temporary vertical state,
not active `v`. By contrast, the second `$2006` write immediately loads active
loopy state. The captured `$2006=$22,$00` pair completes on PPU line 133 before
the next row's two-tile prefetch, making `$2200` the address source for output
row y=133. Exact color changes still depend on CHR pixels and fetch/shifter
state. After the runtime hookup, same-input Godot RGB exactness improved at all
three checkpoints: frame 380 from 84.45% to 87.77%, frame 382 from 83.94% to
86.08%, and frame 394 from 82.91% to 83.54%. These remain substantial visual
mismatches, so the renderer is not exact. The comparison output is
`reference/diagnostics/raster_runtime_compare_1792867924/`. A separate audit
now matches the ROM `$6E` frame descriptors and Q8.8 object position to the
RAM OAM shadow at frames 380/382/394 (42/42, 41/41, 42/42 entries); the ROM
sprite palette at `$D310` also matches PPU `$3F10–$3F1F`. The observed hidden-X
OAM encoding matches those checkpoints, but its producing 6502 routine is
untraced. For frame 380, pinned FCEUX's fetch schedule predicts the first R1
pattern-plane reads after the dot-195 bank write at dots 196/198, feeding
pixels near x=208 at fine-X zero; this is a fetch prediction, not a measured
color edge. Frames 382/394 have different write phases. The renderer still
lacks the 2C02 fetch/shifter pipeline, and runtime sprite composition has not
been proven pixel-exact. A diagnostic cutoff candidate based on the predicted
read pairs made zero RGB changes relative to its unshifted POC control, so it
does not validate the proposed dot-to-pixel mapping and was not promoted.
Do not replace the source-derived event generation with a captured per-frame
table. See the OAM/fetch audit
`reference/diagnostics/field_runner_oam_palette_fetch_audit_20261024.md` and
the candidate report `reference/diagnostics/chr_fetch_cutoff_candidate_20261024.md`.
