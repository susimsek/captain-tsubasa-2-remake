# Opening EC pointer streams beyond entry 0

## Source and scope

This trace uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, and
the synchronized, same-input FCEUX capture
`reference/opening_timing_capture_20261024_125300/`. The live command trace is
`reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`.
RAM snapshots are end-of-source-frame; bus events timestamp the PPU writes.
The extract `ec_bank6_bd00_beff.bin` is bank 6 CPU `$BD00–$BEFF`, file offset
`$DD10`, SHA-256
`2d794632b7681192ade347ec004d15397726952c67c820bf104391894d27d2e1`.

## Pointer table and stream records

At bank-6 `$BD00`, the six little-endian pointer entries are:

| EC operand | Table bytes | Stream pointer | ROM file offset | Stream bytes through `$FE` |
|---:|---|---:|---:|---|
| `$00` | `0C BD` | `$BD0C` | `$DD1C` | `05 0D 15 0D 15 1D 15 0D 15 1D 15 0D 05 FE` |
| `$01` | `1A BD` | `$BD1A` | `$DD2A` | `24 2C 34 2C 34 2C 34 2C 24 FE` |
| `$02` | `24 BD` | `$BD24` | `$DD34` | `3D 45 4D 45 4D 45 3D 45 4D 45 4D 45 3D FE` |
| `$03` | `32 BD` | `$BD32` | `$DD42` | `55 5D 65 5D 65 5D 55 5D 65 5D 65 5D 65 5D FE` |
| `$04` | `41 BD` | `$BD41` | `$DD51` | `6B 73 83 7B 6D 75 85 7D 6B 73 83 7B FE` |
| `$05` | `4E BD` | `$BD4E` | `$DD5E` | `95 9D 95 9D 95 A7 9D A5 9F 95 8F 95 9F A7 9D A7 9D A7 9D A7 9D 95 8F FE` |

The stream bytes index 12-byte records beginning at `$BD80`: the group index is
`(byte & $F8) >> 3`, and the next byte's low three bits supply the nominal
delay. The payload records are shared. They are not pointers to separate
graphics banks or handler routines. The selected streams differ in which
groups they sequence; the verified consumer stages three four-byte writes at
the same nametable addresses `$2302`, `$2303`, and `$2304`, with `$2000=$84`
(PPUDATA increment +32). This is evidence for distinct data streams through
one PPU consumer, not proof of the editorial meaning of every stream.

The first records provide a direct ROM-to-capture check:

| Operand | First byte / group | Group bytes at source | Capture stage → PPU commit | Captured committed bytes at `$2302/$2303/$2304` |
|---:|---|---|---|---|
| `$00` | `$05` / 0, `$BD80` | `EB B6 BC BE / EE B7 BD BF / EF E2 E8 EA` | 380 → 381 | `EB / EE / EF` |
| `$05` | `$95` / 18, `$BE58` | `EB B6 BC AE / EE F1 D6 D3 / EF E2 E8 EA` | 1120 → 1121 | `EB / EE / EF` |
| `$02` | `$3D` / 7, `$BDD4` | `B4 E9 BC BE / B5 EC BD BF / E0 ED E8 EA` | 1780 → 1781 | `B4 / B5 / E0` |
| `$04` | `$6B` / 13, `$BE1C` | `DC DF B0 AE / B5 EC BD BF / E0 ED E8 EA` | 2369 → 2370 | `DC / B5 / E0` |

The source-frame anchors above are observed occurrences, not command-relative
constants. The corresponding EC dispatch frames are 342, 1119, 1760, and 2340.
The differing gaps include other script work and scheduler waits; do not infer
a general EC startup delay from them. At each listed stage frame, RAM `$0652`
advances from `$80` to `$81`; the matching `$2000/$2006/$2007` bus writes and
PPU snapshot show the payload committed at the next frame's NMI.

## `$FE`, `$FF`, and the 40-frame wait

`$0654/$0655` retain the selected base pointer and `$0652` carries the
progress index. Therefore a stream-data `$FE` clearing the low index bits
restarts at that stream's own base, not globally at `$BD0C`. This distinction
matters for operands `$02`, `$04`, and `$05`. Entry `$05` ends in `$FE` followed
by a physical `$FF`, but `$FE` returns to `$BD4E`; that following byte is not
reached by the observed loop.

The script command `EC FF` is different: bank-0 handler `$85D2` clears only
`$0652`, leaving `$0653` and `$0654/$0655` intact. The capture confirms this at
frames 814 (`00 01 0C BD`), 1529 (`00 03 4E BD`), 2121 (`00 04 24 BD`), and
2689 (`00 06 41 BD`). It is an active-stream clear, not pointer-table entry
`$FF` and not a special PPU effect.

For operand `$02`, the first groups stage at frames 1780, 1785, 1790, and 1795.
The script dispatches compact pause `$DB` at frame 1799 (40 scheduler ticks).
During frames 1800–1839, RAM `$0652/$0653` remains `$84/$01`; the next record
stages at 1840 and commits at 1841. The hold follows from the ROM call path:
`$89FF` has one callsite, `$896D`, inside the `$55`-iteration loop at `$895D`,
and the text handler reaches `$895D` only from `$84FC` for a glyph when
`$55 != 0`. The compact pause dispatches no text glyph, so it produces no
`$89FF` tick and the EC countdown remains at one. The earlier model's explicit
frame-range suspension has been removed.

The same callsite explains the initial gaps. EC `$00/$05/$02/$04` first
dispatch at frames `342/1119/1760/2340`; the first nonzero-speed glyph after
each command reaches its first `$9FA8(A=$01)` wait, then `$89FF` stages the
first record at `380/1120/1780/2369`. On the replayed `$00` loop, the first
group stages at frame 4579. These frames come from the presenter executing
ROM script bytes and its text-wait path; they are retained here as validation
observations, not runtime timing inputs.

## Godot model boundary

`RomEcStreamDecoder` verifies the preserved 512-byte extract and decodes all
six table entries. `RomEcStreamPlayer` exposes the captured entries `$00`,
`$02`, `$04`, and `$05`; `start(pointer_table_index)` no longer accepts a
capture frame. The presenter calls `advance_consumer_tick(frame)` only during
the ROM's positive-speed text wait, after that source frame's pending NMI
packet commit. This matches the `$89FF` frame-level call condition and all
1,377 compared RAM `$0652–$0655` bytes in the selected EC windows; the
repeatable diagnostic is `tools/diagnostics/verify_ec_rom_callsite_ticks_20261026.gd`.
Exact CPU-cycle and sub-frame order around `$9FA8`, `$89FF`, and NMI remain
unverified. No emulator image/audio capture is used as a runtime asset.
