# BG0B camera value to OAM coordinates

Checked: 2026-10-25  
Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## Question and evidence

The BG0B scene at source frame 2715 looked displaced in Godot even though the
animation frame and ROM sprite descriptors matched. This trace checks whether
the live camera accumulator in CPU RAM `$7A` is applied to the sprite's X
coordinates before they reach the NES OAM shadow.

The muted, clean-power-on FCEUX replay is recorded under
[`reference/diagnostics/ram_oam_write_trace_20261025_121710/`](../../diagnostics/ram_oam_write_trace_20261025_121710/).
It uses the same input timeline as the opening capture and logs selected RAM
writes with source frame, CPU cycle, PC, and mapped PRG bank. The capture reaches
source frame 2722. The FCEUX Lua API did not provide scanline/dot values in this
run, so those columns are `-1`; CPU cycle and PC attribution remain available.
The trace metadata records the ROM MD5 but not a SHA-256. The SHA-256 above is
the project's independently recorded target ROM identity.

## ROM scene and camera data

The cutscene selects background `$0B` at source frame 2689. Its preserved ROM
record starts at file offset `$00E23A` / CPU `$A22A` and ends in `00 3F 08`
([`background_0B_layout.json`](background_0B_layout.json)). BG0B and BG0A use
the same shared background worker. Its parser at CPU `$8BD8` (file `$00BE8`)
decodes `$3F` into Q8.8 magnitude `$07C0`; the clear sign bit selects
`-$07C0`, or 7.75 pixels in the negative camera direction per update. The
final byte `$08` initializes an eight-chunk counter, with 32 pixels per chunk.
The leading `$00` is not read by the speed/count setup, so its meaning remains
unassigned. The worker's `$62` flags select one triple and stop after this
record.

The RAM write trace shows `$7A` reset to zero at frame 2694 by the routine
observed at PC `$8CB5`; the camera starts changing it at frame 2697. The write
hook reports PC `$9BD2` for `$7A` and `$9BE2` for `$7B`. Those values point just
past the stores: in the supplied ROM, file `$01BE0` is `85 7A` (`STA $7A`) and
file `$01BF0` is `85 7B` (`STA $7B`). The byte sequence at `$9BCA` (file
`$01BDA`) matches the annotated `sub_9BCA`: it records the signed worker step
in `$47`, adds it to `$7A`, and propagates carry/borrow into `$7B`. The worker
at file `$00D98` then updates `$7A/$7B`, the fractional accumulator, and `$47`
from the same movement state. The annotated source is used only after its code
bytes were checked against this ROM. At frame 2715, the raw pair is
`$7B:$7A=$FF:$6C` (16-bit `$FF6C`).

## Descriptor-to-OAM check

For the visible static phase, the ROM `$7C` animation descriptors match the
captured OAM shadow when the origin X uses the 8-bit transform
`(2 * 196 - RAM[$7A] + descriptor_x_offset) mod 256`.

| Source frame | `$7A` | OAM descriptors matched |
|---:|---:|---:|
| 2715 | `$6C` | 40 / 40 |
| 2720 | `$46` | 40 / 40 |
| 2722 | `$36` | 40 / 40 |

At frame 2715 the first predicted entry is `[Y=$6B, tile=$20, attr=$02, X=$04]`,
matching the first four bytes of the captured OAM shadow. PPU `$2005` X is `$74`
(116) at that frame; it does not equal `$7A`, and is not the sprite coordinate
offset.

The full RAM snapshots show 0/40 of these sprites visible at frames 2694 and
2700, 14/40 at frame 2710, 33/40 at 2713, 38/40 at 2714, and 40/40 at 2715.
The source rule for this staggered reveal is decoded below. The absolute
transform is only a checkpoint cross-check, not the ROM's per-frame movement
algorithm.

## Live animation X update

The same RAM/OAM trace shows that sprite X values are updated in RAM `$046B`,
`$046F`, and subsequent four-byte records by bank-0 code reported at PC
`$91DE`. In the supplied ROM, file `$11E8` contains `7D 6B 04` (`ADC $046B,X`)
and file `$11EB` contains `9D 6B 04` (`STA $046B,X`); the write hook reports
the PC just after the store. Examples include `$046B: $70->$78` at frame 2697,
`$88->$8F` at frame 2700, and `$FC->$04` at frame 2715. This proves that the
engine updates the live sprite coordinates each frame before the bank-2
shadow-to-PPU-OAM copy.

Animation `$7C` sets flag bit 4 in its `F9` step at file `$0141D1`. The common
animator tests this bit at CPU `$9168`; when set, branch `$91A6-$91B2` computes
`$E8 = 0 - $47`. The loop at `$91D8-$91DB` then adds this inverse camera step
to each sprite X at `$046B,X`. The target ROM bytes at file `$011E8` and
`$011EB` are `7D 6B 04` (`ADC $046B,X`) and `9D 6B 04` (`STA $046B,X`). The
write hook reports PC `$91DE`, just after the store.

Live examples confirm the per-frame rule: at frame 2697, `$47=$F8` and the
first X changes `$70->$78` (+8); at frame 2700, `$47=$F9` and `$88->$8F` (+7);
at frame 2715, `$FC->$04` (+8 with 8-bit wrap). These are `-$47` in 8-bit
arithmetic. The absolute `$7A` subtraction in the checkpoint table is only an
equivalent result at sampled frames, not the original update procedure.

The RAM shadow is then copied into PPU OAM by code in the live MMC3 `$A000`
window's mapped PRG bank `$02`. In the supplied ROM, file `$048F2` contains
`99 00 02` (`STA $0200,Y`), followed by the other three OAM-byte stores. The
write-hook PCs `$A8E5/$A8EB/$A8F1/$A8F7` are the post-store PCs for those
instructions. The preceding copier code at file `$048E5` loads source Y from
`$0468,Y`, reads the internal attribute from `$046A,Y`, and tests `AND #$0C`.
If those bits are nonzero, it writes Y=`$F8` to OAM; otherwise it writes the
source Y. The raw bytes are `A0 00 BE 68 04 B9 6A 04 29 0C F0 02 A2 F8 8A`.

The common animation loop at `$91DE-$91E8` toggles internal attribute bit
`$04` when an X addition wraps. Since the OAM copier hides entries while
`attr & $0C != 0`, each sprite becomes visible on the frame its own X crosses
the 8-bit boundary. This explains the observed staggered counts above from
ROM logic rather than a hard-coded frame threshold.

## What this establishes and what remains open

This traces the data path from the BG0B ROM camera record through the Q8.8
worker, its signed per-frame `$47` step, the `$7C` camera-follow animation
branch, sprite-X updates at `$046B,X`, and the bank-2 OAM copy. Godot
reproduces these source operations without reading captured RAM/OAM files at
runtime. The 40/40 absolute-coordinate checks are an independent cross-check,
not the implementation rule. A same-input Godot/FCEUX comparison is recorded
under `reference/diagnostics/bg0b_camera_motion_20261025/`; the visible-sprite
counts match at the sampled frames, while rendered RGB does not. A follow-up
code review found that Godot also needs to wrap each rendered sprite X as an
8-bit OAM value. The older checkpoint PNGs in that directory predate this
correction. A current 245-frame recapture after the BG0B raster and OAM changes
is in
[`reference/diagnostics/bg0b_source_transitions_20261025/`](../../diagnostics/bg0b_source_transitions_20261025/).
For 2694–2938, mean RGB rose from 89.011% to 92.161% and foreground-union
exactness from 16.147% to 33.228%; 205 frames improved, 4 regressed, and 36
were unchanged. The FCEUX OAM tuple/reveal-count checks and the current image
comparison measure different things: tuple agreement does not settle portrait
placement/composition. Within-frame PPU fetch/color timing remains open.

## Trace bookkeeping caveat

The trace's `metadata.txt` originally called this window `BG0A animation 0x7C`.
That label is stale: the window begins at frame 2694 after `FA 0B`, so it is
BG0B. The ROM record, frame mapping, and raw writes are unaffected by the label.
