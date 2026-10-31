# ID-1 Select cleanup palette trace — 31 Oct 2026

## Finding

The `$004A/$004B` state consumed by ID-1's `$82DF->$9BA0` cleanup is produced
by the cutscene's ROM `$E9` fade-up. The final ID-1 `$E9` event is at stream
address `$A38B` (event 52 in
`assets/gameplay/rom_logic/kickoff_cutscene_01_events.json`). A muted FCEUX
two-pass trace observed task base `$05` increment both counters to `$0F` through
bank-$00 `$998C` on frames 7121–7135. The counters had no further writes before
Select. The shared `$99F0` cleanup then decremented them together to zero on
frames 7243–7257.

This means the cleanup fade can consume the event VM's source-modeled `$E9/$EA`
counter state. No frame-count constant or captured RAM seed is required. The
Godot route currently stops before the helper and does not yet consume it.

## Source-backed behavior

- The ROM is `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Cutscene 1's byte-verified event manifest maps `$A38B` to event 52, opcode
  `$E9` (`screen_on`). The trace shows `$004D/$004E=$A38B` during its final
  count-up writes.
- The ROM cleanup helper bytes are preserved in
  [`fade_down_99F0.bin`](../intro/ea_fade/fade_down_99F0.bin). This file covers
  `$99F0-$9A30`: it checks `$004A|$004B`, decrements each nonzero value, calls
  `$9A71`, and yields through `$9FA8(A=$01)`. The separate counter producer is
  bank `$00:$998C-$99AD`; its trace provenance is linked from the handoff audit.
- The recorded KICK OFF input produces the final `$E9` counter values `$0F/$0F`
  by frame 7135. There are no later `$004A/$004B` writes before the Select at
  frame 7243. The Select cleanup writes `$0E/$0E` at frame 7243, then `$00/$00`
  at frame 7257. The next frame-end sample is frame 7258.
- At each cleanup step, the `$05E8` packet header is `20 00 3F`. Its 32-byte
  payload matches the source `$9A71->$9AA2->$9EA2` conversion of the live
  `$062A-$0649` palette bytes at the decremented `$004A/$004B` values. In the
  same frame-end captures from 7244 through 7257, PPU palette `$3F00-$3F1F`
  matches the preceding frame's staged payload. This is frame-end agreement,
  not a physical PPU cycle measurement.

## Trace provenance

`reference/diagnostics/kickoff_select_cleanup_counters_20261031_001445_utc/`
contains the raw two-pass trace and `validation.json`. FCEUX 2.7.0 ran muted in
NTSC NewPPU mode. The trace replayed input frames 4693–7258 twice from one
anonymous in-memory checkpoint saved at frame 4692; both loads passed a
frame/cycle, full 2 KiB RAM, full 16 KiB PPU, MMC3-register, and mapped-PRG
signature check. The normalized counter-write logs and frame-end snapshots
matched across both passes.

Inputs were the opening timeline (SHA-256
`195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`) and
post-title route (SHA-256
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`). The
trace is observation and validation evidence only; it is not a runtime asset.

## Remaining limits

The Godot Select waiter still uses cutscene-VM state as a proxy for the ROM
`$4D/$4E` task pointer, and does not execute the CPU stack or task scheduler.
The runtime seeds paired `$99F0` counters from its ROM-modeled `$E9/$EA` level,
builds each `$05E8` packet from source palette bytes, applies it on the next
modeled tick, and matches all 15 FCEUX packets. It also applies `$98A0/$9B7F`
and matches the frame-7258 PPU/RAM snapshots. The checked `$82E2-$82EC` caller
block now applies its four zero stores and returns to `$80F1`; match setup,
automatic cutscene-2 dispatch, field construction, and the first command menu
remain ahead. Exact CPU/NMI phase remains unresolved. See the
[cleanup helper source report](cutscene_cleanup_helpers/README.md) and
[caller handoff audit](select_to_fresh_match_handoff_gap_20261031.md).
