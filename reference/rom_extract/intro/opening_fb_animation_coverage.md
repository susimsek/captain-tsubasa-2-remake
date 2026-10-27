# Cold-opening `FB` animation coverage

## Scope and ROM identity

This is a static audit of every `FB` dispatch in the first cold-opening pass,
from script address `$A020` through the loop terminator at `$A29E`. The source
is the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Dispatch timing and effective MMC3 bank slots are from
[`cold_start_observed_dispatch.json`](cold_start_observed_dispatch.json),
which records interpreter-entry bus observations. Animation commands and
frame descriptors are decoded from ROM bytes by
[`animation_timing_entry.json`](animation_timing_entry.json) and
[`sprite_frames_entry.json`](sprite_frames_entry.json). Synchronized CPU-RAM
OAM snapshots are used only to check descriptor order and geometry.

## First-pass dispatch inventory

`FB n id...` installs `n` active ROM animation objects in list order. The
animation loader resolves each ID, reads the first byte of its animation
record into zero-page `$49`, and therefore leaves the last listed ID's byte as
the sprite-palette selector for a following full palette build. Animation
entries at IDs below `$6D` come from PRG bank 9; IDs `$6D` and above come from
bank 10. The entry offset and selector byte below were checked against the
captured MMC3 mapping and the supplied ROM.

| Source frame / script PC | `FB` bytes and IDs | Entry file offset / bank / CPU | Selector byte | Decoded frame descriptors |
| --- | --- | --- | --- | --- |
| 10 / `$A024` | `FB 01 8D` | `0x0143E3` / 10 / `$A3D3` | `$36` | `$B15B` (40 sprites; static) |
| 378 / `$A033` | `FB 01 6E` | `0x0140D6` / 10 / `$A0C6` | `$00` | `$A837` (42), `$A86F` (42), `$A8BA` (41), `$A908` (43); timed loop |
| 819 / `$A092` | `FB 01 75` | `0x014196` / 10 / `$A186` | `$01` | `$AA8C` (39; 60-tick hold) |
| 1047 / `$A0BF` | `FB 02 C1 82` | `C1: 0x014767` / `$A757`; `82: 0x01426F` / `$A25F` (bank 10) | `$02`, then `$02` | `C1: $B711` (14); `82: $ADF0` (50), `$AE12/$AE29/$AE38/$AE4C` (56 each), `$AE08` (55) |
| 1534 / `$A125` | `FB 01 76` | `0x01419F` / 10 / `$A18F` | `$01` | `$AAE7` (42; mirrored) |
| 1778 / `$A152` | `FB 01 84` | `0x0142DB` / 10 / `$A2CB` | `$00` | `$AE9E` (51), `$AEAE` (52), `$B311` (57), `$B325` (58), `$B339` (57), `$ADB8` (58); 2-tick cycle |
| 2126 / `$A195` | `FB 01 77` | `0x0141A9` / 10 / `$A199` | `$06` | `$AB4A` (41; 60-tick hold) |
| 2367 / `$A1BC` | `FB 03 C0 A2 7D` | `C0: 0x014760` / `$A750`; `A2: 0x01451E` / `$A50E`; `7D: 0x0141DA` / `$A1CA` (bank 10) | `$07`, `$07`, then `$07` | `C0: $B6EB` (16; static); `A2: $ADD6` (9); `7D: $AD72` (33), `$ADC2/$B258/$B297/$B2DA` (37 each), `$AD9A` (35) |
| 2694 / `$A200` | `FB 01 7C` | `0x0141D1` / 10 / `$A1C1` | `$08` | `$AD14` (40; 60-tick hold) |
| 2908 / `$A232` | `FB 01 0D` | `0x01229E` / 9 / `$A28E` | `$09` | `$A7CB` (63; static) |

All 13 selected IDs have an extracted `animation_<id>.bin` and a decoded
animation entry. Every timed frame address in the table resolves to a decoded
frame in `sprite_frames_entry.json`; the static entries resolve through their
decoded `commands` arrays. No additional generic loader or per-ID hand-written
animation implementation is needed for these records.

## Synchronized OAM spot checks

The following counts compare ROM frame descriptors with contiguous entries in
CPU-RAM OAM shadows; they do not use captured pixels. Existing
[`intro_sprite_oam_matches.json`](../../diagnostics/intro_sprite_oam_matches.json)
records exact matches for `75` 39/39 at frame 880, `76` 42/42 at 1600,
`77` 41/41 at 2190, `7C` 40/40 at 2800, and `0D` 63/63 at 4692. A separate
check against `opening_timing_capture_20261024_125148` matches `84` 51/51 at
frame 1779.

The multi-object scenes in `opening_timing_capture_20261024_125148` also
confirm list order in OAM: at source frame 1050,
`C1` occupies entries 0–13 and matches 14/14, followed by `82` at entries
14–63 matching 48/50. At frame 2368, `C0` occupies entries 0–15 (16/16),
`A2` entries 16–24 (9/9), and `7D` starts at entry 25. A frame-2369 spot
check matches 30/33 `7D` descriptors. The five unmatched records in these
two scenes are offscreen/hidden entries: the captured OAM uses Y=`248` and
attribute bit 3 where the current simple comparison predicts another Y or
does not set that bit. The complete hidden-sprite rule for these objects is
not established, so those partial counts are not claimed as exact.

## Palette selector 9 and the `0D` title object

The ordinary opening `F3 00` calls `$9A35`, which copies 16 background colors
from the table at ROM file `0x00D010` using `$48`, and 16 sprite colors from
the table based at `0x00D310` using `$49`. The copy routine calculates the
record address from the selector; it does not enforce the extracted
Godot-side table's nine-record limit. In the observed first-pass script, each
`F3` occurs after IDs whose final `$49` is in `00–08` (the multi-ID choices
are `82` and `7D`, the last ID in each list). There is **no `F3` after the
`FB 01 0D` at frame 2908** before the top-level loop, so the captured first
pass does not exercise selector `$09` through an `F3` command.

The title handoff does use `0D`: its ROM animation entry at bank 9 CPU `$A28E`
and file `0x01229E` begins `09 F1 26 3E 87 CB FF`. The shared animation loader
puts `$09` in `$49`; title setup then calls `$9A35` directly. Its palette
helper computes `$B300 + 16 × $49 = $B390` (bank 6), ROM file `0x00D3A0`,
immediately after the nine records `$00–$08` in the extracted 144-byte
`sprite_palette_table_00_08.bin`. The exact 16 bytes are
`0F 27 37 30 0F 06 16 26 0F 17 26 27 0F 0F 30 37`; their SHA-256 is
`7e47683c68602db72d4f3a40bc2e3dc160c5f01c9a5c2cfe8cfc570da42c1c32`.
They are preserved in
[`animation_0D_sprite_palette.bin`](animation_0D_sprite_palette.bin), with
the source offset and a byte-for-byte match to the frame-4692 PPU sprite
palette recorded in
[`animation_0D_sprite_palette.json`](animation_0D_sprite_palette.json).

Selector `$09` is the only **table-style selector from `$00–$09` outside the
extracted `$00–$08` slice** among the observed opening entries, but it is not
the only opening animation header byte numerically above 8: initial logo
animation `8D` begins with `$36`. That is a separate, already traced indexed
palette record at file `0x00D670` (bank 6 CPU `$B660`), matching the frame-100
PPU palette. The two cases are therefore `$0D → $09 → 0x00D3A0` and
`$8D → $36 → 0x00D670`; neither value implies missing palette data in the
ROM. The first-pass `F3` observations themselves only select indices
`00–08`.

## Godot renderer coverage and remaining gaps

[`rom_sprite_animation_prototype.gd`](../../../scripts/opening/rom_sprite_animation_prototype.gd)
loads any matching animation ID in `animation_timing_entry.json`, resolves
frame descriptors from `sprite_frames_entry.json`, decodes the selected tiles
from ROM-derived CHR, and draws the descriptor list. It handles timed and
static frame records, initial position, local mirroring, palette slots, and
descriptor draw order. Thus the existing renderer's input data format is
already generic enough for every ID above.

The current presenter stores each decoded `FB` ID in `animation_ids`, and
`_replace_active_animation_nodes()` instantiates a
`RomSpriteAnimationPrototype` for every active ID; `_apply_visual_state()`
advances and visibility-gates these nodes. `_load_f3_palette_sources()` also
validates the separately preserved `$0D` / palette-`$09` ROM record.

The presenter now has a source-backed motion-record path for `$A2`, alongside
the existing `$6E` runner path. It reads A2's preserved F1/F7 entry and decoded
tick list, handles only the observed `$29 00 00` and `$00 00 00` F7 forms, and
uses the shared `$975B` update order to set the A2 node origin. The RAM/OAM
anchors and source-byte decode are documented in
[`a2_motion_record_trace_20261025.md`](a2_motion_record_trace_20261025.md).
The ordinary animation renderer now assigns cumulative source OAM slots and
applies a shared first-eight-sprites-per-scanline visibility pass while keeping
the existing `$04/$08` DMA hide rule. The model and its limits are documented
in [`shared_oam_scanline_evaluation_20261025.md`](shared_oam_scanline_evaluation_20261025.md);
the changed composition has not yet received a same-input capture.

Remaining runtime gaps are source-exact composition: other animation IDs do
not yet execute their ROM `F7` motion state or scene-specific object lifetimes;
unused/stale OAM slots and the title's priority-bit mutation are not modeled.
The separate BG08 `$C1/$82` compositor also retains its old path and does not
yet use the new scanline evaluator. These are presenter/runtime gaps, not
missing decoded animation IDs or missing ROM frame descriptors.

The existing OAM checks confirm descriptor order and selected-frame geometry
for the listed snapshots only. The new row-limit model still needs focused
same-input checks and does not establish dot-level raster clipping, the exact
PPU commit edge, or frame-exact complete opening composition.
