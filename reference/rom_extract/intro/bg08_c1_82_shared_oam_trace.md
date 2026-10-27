# BG08 animation `$C1/$82` shared OAM composition

## Scope and source identity

This note covers the two animations installed by `FB 02 C1 82` at source
frame 1047, for the BG08 dialogue scene. The supplied Turkish ROM has SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Animation timing, sprite-frame descriptors, CHR, and palette data are decoded
from that ROM and retained under `reference/rom_extract/`. Emulator RAM and
screens are used only to validate the reconstructed OAM writes and visible
pixels.

## Source-driven record and write model

The bank-0 animation allocator at `$9085` creates 32-byte animation records
beginning at `$0568`; the two records for this FB set are `$0568` (`$C1`) and
`$0588` (`$82`). For these records, `+$10` is the byte start in the shared
`$0468–$0567` OAM shadow and `+$11` is the byte extent:

| Animation | OAM start byte | OAM start slot | Initial live extent | Maximum capacity | ROM frame counts |
|---|---:|---:|---:|---:|---|
| `$C1` | `$00` | 0 | `$38` (14 sprites) | `$38` (14 sprites) | `$B711`: 14 |
| `$82` | `$38` | 14 | `$C8` (50 sprites) | `$E0` (56 sprites) | `$ADF0`: 50; `$AE08`: 55; `$AE12/$AE29/$AE38/$AE4C`: 56 |

The record's `+$11` field is its **live** byte extent, not its maximum pose
capacity. At frame 1047, `$C1` is `$38` and `$82` is `$C8`; on frame 1107 the
first 56-descriptor `$AE12` pose grows `$82` from `$C8` to `$E0`. Runtime FB
slot starts are calculated using the maximum ROM descriptor counts, while the
live record extent is initialized from its first pose and updated only by the
source writer. The fixed starts are slot 0 for `$C1` and slot 14 for `$82`.
After growth, `$82`'s 56-slot live extent wraps through slot 5 (`14 + 56 = 70`,
modulo 64 gives slot 6). Writes happen in FB order, so `$82` overwrites `$C1`
slots 0–5 whenever `$82` emits a 56-entry pose. Unwritten slots retain their
earlier shadow bytes; a `$C1` record that exits stops moving and writing but
its surviving OAM entries remain visible.

The record positions are signed Q8.8. ROM `$9339`'s F1 path stores the signed
Y/X operands into the record's position fields; the ROM F7 handler `$93A7`
unpacks velocity/acceleration into `+$08..+$0E`; and `$975B` integrates each
active axis as `velocity += signed8(acceleration)`, then `position += velocity`.
For OAM coordinates, the signed Q8.8 position is doubled and floored to the
pixel coordinate; descriptor offsets are then added and wrapped to a byte.
The source sprite writer `$94D8–$96F1` supplies tile, attribute, and per-sprite
offset values. The renderer paints OAM indices from 63 down to 0 so lower
indices retain NES priority.

All command spans used by the runtime are byte-checked against the supplied
ROM via `animation_C1.bin` / `animation_82.bin` and their source offsets. The
targeted diagnostic also checks each frame's four CHR selectors and each
descriptor's raw bytes against the ROM file offset recorded in
`sprite_frames_entry.json`.

## Validation results

Command: `godot --headless --path . --script tools/diagnostics/capture_bg08_oam_runtime.gd`,
then `python3 tools/diagnostics/verify_bg08_oam_runtime.py --runtime-report
reference/diagnostics/bg08_oam_shared_composition_validation/runtime_oam.json`.
The generated Godot sprite-composition PNGs are under
`reference/diagnostics/bg08_oam_shared_composition_validation/`; they are diagnostic
outputs, never shipped assets.

| Godot displayed frame | FCEUX RAM/OAM frame | Decoded tuples matching | Godot OAM slots matching | Godot sprite pixels matching FCEUX screen | Matching ROM checks |
|---:|---:|---:|---:|---:|---|
| 1108 | 1107 | 64/64 | 64/64 | 2563/2563 | 120 animation command spans, 2 CHR headers, 70 descriptor spans |
| 1522 | 1521 | 63/63 known tuples | 63/64 (only slot 5 differs) | 2563/2563 | 120 animation command spans, 2 CHR headers, 69 descriptor spans |

The one-frame OAM display latch is independently supported by the existing
FCEUX screen/OAM diagnostic: screen 1108 is explained by RAM frame 1107's OAM
for all 2,563 opaque sprite pixels, and screen 1522 likewise by RAM frame
1521. The later RAM sample gives fewer matching sprite pixels.

At display frame 1522, the prior-frame `$0200` DMA page has slot 5
`F8 1B 00 94`; the earlier compositor retained `4A 1B 00 94`. The active
`$AE08` pose decodes to 55 descriptors while its animation record reserves 56
slots. The source writer is now identified in the supplied ROM:

- The `$96F2` frame terminator is at file offset `0x1702`. If record flag bit
  `$08` is already set, `$9703–$970C` computes `start + extent - live OAM
  cursor`. `$970E` exits on zero; `$9710` skips tail filling if the cursor has
  passed the allocation end. `$9712–$9715` divides the remaining byte count by
  four and `$9717–$9722` writes only `$F8` to each unrendered tuple's Y byte.
  If bit `$08` is clear, `$96FA–$9700` sets it and takes the first-render path
  without filling the tail.
- For `$82`, start `$38`, extent `$E0`, and 55 `$AE08` descriptors leave one
  tuple. The current cursor is `$14`, allocation end `$18`, so the fill writes
  `$F8` at shadow address `$047C` (slot 5), retaining tile/attribute/X bytes
  `$1B 00 $94` from the previous 56-descriptor pose.
- The shared motion loop `$91B4–$91F1` at file offset `0x11C4` advances every
  tuple in the record's live extent. It adds the computed Y and X deltas and
  toggles attribute overflow markers `$08`/`$04` only when the respective
  coordinate wraps; it does not alter tile bytes. The hidden slot therefore
  moves `$F8→$F7/$F9` on motion-only ticks and resets to `$F8` after the next
  pose render.

The runtime composer now models the source tick order: integrate motion over
the current live span, apply animation events, rewrite the selected pose, then
run the `$96F2` tail fill only on a pose-frame update and according to the
record flag. A same-frame check compares all 256 shadow bytes at source frames
1047–1159 against FCEUX RAM `$0468–$0567`: **113/113 frames exact** and zero
different bytes. This includes the frame-1107 growth from `$C8` to `$E0` and
the `$82/$AE08` hidden-tail sequence: slot 5 is `F8 1B 00 94`, `F7 1B 00 94`,
`F8 1B 00 94`, `F9 1B 00 94`, and `F8 1B 00 94` at frames 1155–1159. The
ROM-derived Godot captures are in
`reference/diagnostics/bg08_live_extent_source_runtime_20261026/`.

The source bytes and same-frame RAM snapshots establish the writer, condition,
and tuple values. The available capture has no PC-tagged `$96F2/$91B4` execution
for these exact frames, so the within-frame instruction call sequence is
source-derived and cross-checked against RAM, not directly hook-traced. The
earlier visual validation with render-only suppression matched 1157–1523 at
367/367 frames, but it predates this byte-accurate OAM model. A current full
visual recapture is required before carrying that result forward. The earlier
0–4692 baseline had 4673/4693 visible frames RGB-exact before this source-model
change and is likewise not current. See
`reference/diagnostics/oam_latch_recap_hidden_slot_20261026/README.md`.

### Frame-1088 overflow markers and DMA hiding

A focused slot dump now covers display frame 1088 against FCEUX RAM frame
1087. The internal shadow is `$0468–$0567`; the separate OAM DMA source is
`$0200–$02FF`. The 64 ROM-derived tuple coordinates, tiles, and base
palette/flip bits match the shadow apart from the shadow's 25 overflow-marker
bits. All 64 markers match the pre-wrap X/Y coordinates. Applying the target
ROM copier's `attr & $0C` rule reproduces all 64 DMA tuples, including Y=`$F8`
for marked entries.

The target-ROM mapping is recorded in
[`bg08_oam_frame1088_oam_audit`](../../diagnostics/bg08_oam_frame1088_oam_audit/README.md):
common descriptor writer `$9541` (file `0x001551`) marks X/Y overflow in
attribute bits `$04/$08`; bank-2 copier `$A8CE` (file `0x0048DE`) substitutes
Y=`$F8` when either bit is set; `$A215` jumps to `$A8CE`; `$A000` sets
`$2003=0` and starts OAM DMA from page `$02`. These bytes were checked against
ROM SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The slot CSV and capture commands are in the diagnostic folder. The source
routine bytes explain the data, but PC-tagged execution of `$9541/$A8CE` for
this exact BG08 frame is not present in the capture.

The 553 full-frame mismatches at frame 1088 are exactly the candidate
compositor's 553 extra opaque sprite pixels (`xor=0`); their FCEUX pixels are
all cyan. This isolates that frame's remaining right-edge difference to the
missing overflow/culling rule. The runtime fix is source-supported, but still
needs focused same-input captures at frames 1068, 1088, and 1108 before it is
promoted.

The headless Godot renderer cannot capture the complete composed viewport on
this host (`ViewportTexture.get_image()` is unavailable under its dummy
renderer). The diagnostic therefore compares the independently generated
ROM/CHR sprite-composition image to the FCEUX rendered frame and compares the
full OAM shadow separately. This does not establish full-scene RGB equality.

## Limits

- The compositor does not simulate 2C02 sprite evaluation, the eight-sprites-
  per-scanline limit, overflow behavior, or cycle-level sprite fetch timing.
- The parsed C1/82 descriptors use palette-low bits and horizontal flip; no
  vertical-flip or behind-background attribute bit appears in the checked
  tuples. Those hardware cases are not generalized by this path.
- OAM matching at the two checkpoints and pixel matching there do not prove
  every intermediate frame, raster boundary, or BG08 composition exact.
- The existing `$6E` runner renderer and motion model are unchanged.
