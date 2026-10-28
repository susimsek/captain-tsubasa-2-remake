# First-command field residual: ROM map scan

## Scope and inputs

This is a source-only follow-up to
[`first_command_field_background_producers_20261027.md`](first_command_field_background_producers_20261027.md).
It checks candidate metatile maps and route animation commands against the
existing frame-8953 PPU snapshot only as validation data. It does not use the
screen capture, copy captured bytes into a source resource, control FCEUX, or
change Godot runtime code.

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Validation PPU: `reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin`, SHA-256 `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e`.
- Validation RAM: `reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin`; it is consulted only for the endpoint selector and placement state.

## Residual confirmed

For the ROM-derived candidate placement of map `$56` at PPU `$2A00` (tile
origin `$A0`), the visible part of its 32-by-16 tile layer is 388/448 bytes
equal to the endpoint. The remaining 60 differences are exactly PPU nametable
rows 18–23, columns 2–11. The endpoint values are:

```text
98 AC AC AC 99 AC AC AC AC 99
98 99 A0 A0 AF A0 A0 A0 98 99
A1 AF A0 A0 A4 A5 A0 A0 AE A1
A3 AF A0 A0 A6 A7 A0 A0 AE A3
9A 9B A0 A0 AF A0 A0 A0 9A 9B
9A AD AD AD A2 AD AD AD AD 9B
```

The corresponding map `$56` attributes from its selector-`$02` source at
`$9DE4` / file `0x017DF4` match 26/32 bytes at `$2BE0`. The six differences
are offsets 0, 1, 2, 8, 9, and 10: ROM source `AA AA AA AA AA AA`; endpoint
`2A 0A 0A 22 00 00`. Map `$36` at `$2800` matches the visible final two rows
64/64 and its attributes at `$2BC0` match 32/32. This reproduces the earlier
combined 452/512 tile result and isolates the same six-by-ten rectangle.

## Route animation bytes and code-backed placements

The bank-$10 scenario pointer table is at file `0x0209CF`. Scenario `$1E`
points from file `0x020A0B` to `$B7DA` / file `0x0237EA`; its background event
at `0x0237EF` is `07 45 90 F0`. The first-command scenario `$44` points from
`0x020A57` to `$B7D5` / file `0x0237E5`; its event is `02 70 5C F0`.
Bank-$0B's background-animation pointer table begins at CPU `$87F6` / file
`0x016806`: animation `$45` resolves to `$8A2A` / file `0x016A3A`, and `$70`
resolves to `$8B38` / file `0x016B48`.

The target-ROM `$45` stream at `0x016A3A` includes these map commands:

```text
06 00 36 | 02 00 37 | 02 03 00 F5 5D | 02 03 00 0B 5E |
02 01 00 F5 00 5F 5F | 02 01 00 F5 00 60 60 | 02 03 00 0B 5D
```

The opcode-`$00` handler at bank-$0B `$8327` (file `0x016337`) reads the map
ID at record `+2`, calls `$8525` with `$05CD` as Y, then toggles `$05CD` between
`$80` and `$A0`. The opcode-`$03` path at `$8358` (file `0x016368`) reads its
map ID at `+4` and uses the same placement argument. The opcode-`$01` path
from `$83E7` (file `0x0163F7`) draws the current `$05CC` map at Y `$00`, then
the record's `+5` and `+6` maps at Y `$80` and `$A0`. Thus `$45` contains
source-backed placements for maps `$5F` and `$60` at `$2800` and `$2A00`;
whether each call ran and remained visible at frame 8953 is not recorded.

The `$70` bytes at file `0x016B48` begin `06 00 56 02 00 80 F2 19 ...`.
Its first opcode-`$00` selects map `$56`; the next selects map `$80`. The
`$F2` control at file `0x016B4E` routes through `$81BC` to `$824D` (file
`0x01625D`), which calculates a map from the ball-holder/player position and
then calls the common map writer. Its 120-byte lookup table `$827F–$82F6`
(file `0x01628F–0x016306`) contains only IDs `$00–$07`, `$0C–$13`, `$1A`, and
`$1B`; it cannot explain the sampled `$05CC=$56` by itself. The endpoint
`$05CC=$56`, `$05CD=$80`, `$05CE=$A0` is consistent with a common-writer call
for map `$56` at Y `$A0` followed by the source toggle, but does not prove the
last PPU packet, its caller, or commit time.

Map IDs and selector-correct block-map sources are:

| Route record | Map IDs / selectors | 32-byte map source offsets |
| --- | --- | --- |
| `$45` | `$36/$01`, `$37/$02`, `$5D/$01`, `$5E/$01`, `$5F/$01`, `$60/$01` | `0x017234`, `0x017254`, `0x017714`, `0x017734`, `0x017754`, `0x017774` |
| `$70` | `$56/$02`, `$80/$02` | `0x017634`, `0x017B74` |

Selectors are read by `$86D3` from packed table `$8B42` / file `0x016B52`.
`$8525` indexes block maps from `$8B64` / file `0x016B74`; `$85C2` at file
`0x0165D2` expands their 4-by-4 tile records and attributes. Map `$56` selector
`$02` reads tile records from bank `$13`, file base `0x026010`, and attributes
from `0x017DF4`. The ROM map extraction and hashes remain in
[`first_command_field/page_correct_map_sources/manifest.json`](first_command_field/page_correct_map_sources/manifest.json).

## Exhaustive map candidate result

The contiguous map table from file `0x016B74` to the attribute table at
`0x017BF4` contains 132 complete 32-byte maps, IDs `$00–$83`. I decoded every
map using the selector table and the target `$85C2` source addressing, then
compared all 4-tile-aligned in-page origins that overlap the 60 endpoint tile
IDs. No single map placement reproduced the rectangle. At the route-aligned
origin `$A0` (X 0, Y 16), the best map matched 1/60 tiles; across other
in-page placements that overlap at least 20 target cells, the best was 2/24.
At the same `$A0` attribute origin, no map's first two attribute rows/three
columns matches the six endpoint bytes; the best was 2/6. In particular,
`$45` maps `$5D–$60` and `$70` map `$80` do not explain this patch as one
metatile-map write.

## Confidence and open point

High confidence: the 60 tile differences and six attribute differences are
localized as stated; the scenario-to-animation pointers, route map IDs,
selector table, and handler placement arithmetic match the supplied ROM bytes.
The `$45` opcode-`$01` placement path is a concrete source-backed producer
candidate for the wider field layers. The map scan rules out a single
`$85C2` metatile map as the missing patch.

Still unknown: which `$45/$70` calls execute last on this route, whether a
multi-map or row-run worker composes the residual, the exact PPU packet order
and commit frame, and any gameplay scroll/raster timing at the endpoint. The
existing route capture lacks gameplay PC and `$2006/$2007` write history, so
the patch source remains unresolved; no runtime repair is justified by this
scan.
