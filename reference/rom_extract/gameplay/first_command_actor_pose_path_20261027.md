# First command-menu actor pose path

## Scope and source identity

This is a static ROM-path audit for the first fresh-start command panel near
source frame 8953. It does not add a runtime actor renderer and does not use
captured OAM or screenshot pixels as artwork.

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Public disassembly lead: [pinned `bank_94.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_94.asm), [pinned `bank_96.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_96.asm), and [pinned `bank_FF.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_FF.asm). Address labels below were checked against bytes in the supplied Turkish ROM; the upstream disassembly is a structural lead, not the target binary.
- The existing muted frame-8953 RAM/OAM snapshot is diagnostic evidence only: `reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin`.

## ROM-side actor-to-OAM chain

The fixed-bank drawing loop at CPU `$EE9F` / file `0x03EEAF` walks the six
packed order nibbles in `$0543–$0545`. The table at CPU `$EF73` / file
`0x03EF83` maps indices 0–5 to actor records `$0547,$055C,$0571,$0586,$059B,
$05B0`. For records whose flag byte is negative, it selects bank `$14` and calls
its jump-table entries `$8006` and `$8003`, which dispatch to CPU `$83D9` / file
`0x0283E9` and CPU `$84DC` / file `0x0284EC`. It then selects bank `$16` and
calls sprite engine `$8000` (file `0x02C010`).
The corresponding local call bytes at the fixed-bank sites match the pinned
disassembly. The NMI later DMA-copies the OAM shadow; this drawing loop is the
ROM producer, rather than the captured OAM bytes.

The bank `$14` animation interpreter explains how a layout descriptor is
produced. Its `$8006` jump-table entry lands at CPU `$83D9` / file `0x0283E9`:

- The routine reads actor timer `+$10`. A positive nonzero
  timer is decremented; `$FF` returns without changing the pose; zero enters
  the script interpreter at `$83E9`.
- The interpreter clears actor movement offsets `+$13/+14`, reads the script
  pointer from `+$03/+04`, and processes script bytes. A regular timed pair
  stores its duration at `+$10` and its second byte at `+$12` (descriptor),
  then advances the script pointer (`$8419–$8437`).
- `$F3` redirects the script pointer. `$F8` writes its operand to shared RAM
  `$0546` (`$84D2–$84DB`). `$F0` ends the sequence by setting `+$10=$FF`.

The frame-8953 route snapshot has descriptor bytes at actor `+$12` equal to
`00,04,0D,0A,B9`; the first five records' `+$10` timers are `$FF`. Thus these
are held poses at the captured endpoint. `$0546=$08` is one shared snapshot
value, not a per-actor field. The later live trace records `$0546` at each
actor draw for frames 8481–8953; see
[`first_command_actor_state_producer_20261027.md`](first_command_actor_state_producer_20261027.md).
The endpoint snapshot alone is still insufficient to infer earlier selector
values or how the actor records were initialized.

## Descriptor streams and renderer

Bank `$16` CPU `$8000` / file `0x02C010` reads actor `+$12` at `$8084`, resolves
the pointer through table `$8280` / file `0x02C290`, derives origins and flip
from actor flag/coordinate fields, and parses compact OAM runs. Y offsets are
read from `$81D2` / file `0x02C1E2`; X offsets from `$81FA` / file `0x02C20A`.
Opcode `$03` selects one of twelve stream pointers from `$0546` (normalizing
values at or above `$0C`); opcodes `$00/$01/$02` encode runs/end/jumps.

Target-ROM pointer checks for the five endpoint descriptor values:

| Descriptor | Stream pointer | File offset | Leading bytes / observation |
|---:|---:|---:|---|
| `$00` | `$842C` | `0x02C43C` | Begins with `$03`; selector `$08` chooses `$84DF` at `0x02C4EF`. |
| `$04` | `$87D9` | `0x02C7E9` | Begins with `$03`; selector `$08` chooses `$87F2` at `0x02C802`. |
| `$0D` | `$899C` | `0x02C9AC` | Begins with `$08`; run/jump stream, no initial `$03` selector branch. |
| `$0A` | `$896B` | `0x02C97B` | Begins with `$08`; run/jump stream, no initial `$03` selector branch. |
| `$B9` | `$BB62` | `0x02FB72` | Begins with `$18`; counted run. |

The source-only parser and endpoint comparison are now documented in
[`first_command_field_live_source_summary_20261027.md`](first_command_field_live_source_summary_20261027.md):
for the three live descriptors `$00/$04/$0A`, selector `$08` produces all
41 endpoint sprites and matches the retained OAM shadow's 164/164 bytes.
That validation does not establish the route-time actor-state producer.
Descriptor `$0D` and `$B9` from other endpoint records are not part of that
three-actor comparison. The existing
`GameplayRomOamSpriteLayer` in `scripts/gameplay/rom_oam_sprite_layer.gd` can
composite a caller-supplied 64-entry OAM from CHR and palettes; it does not
interpret gameplay animation scripts or generate these actor OAM entries.
`RomSpriteAnimationPrototype` and its kickoff frame JSON cover cutscene
sprites, not this gameplay actor format.

## Why the route still lacks a runtime actor presenter

The ROM contains a clear source path, and the writer trace maps the `$F1`
constructor plus appearance/motion writers. The 2026-10-28 muted timing trace
also measures the NMI-ready handshake, `$0519` countdown, actor update cadence,
and relative `$800F` animation waits. The new ROM-byte decoder bridges a bank-
`$10` event record to that relative animation schedule. Those results still do
not establish a route-integrated Godot actor-state producer:

1. The actor-event timeline is not wired to the route's cooperative task graph;
   the scenario worker handoff and the exact point where it starts `$EC94` and
   the animation worker remain external to the new decoder.
2. The package preserves the final-pose pointer/script subset, not all
   route-selected `$A1B4/$AC47` motion/appearance entries and script spans
   needed by the observed `$F1` packets. The `$83D9/$84DC` interpreters must
   update live actor records before the OAM builder can draw route poses.
3. Shared mirror `$0517`, scroll `$0538`, clip `$0540/$0541`, selector
   `$0546`, F4 CHR writes, and F5 setup effects still need to come from live
   ROM-driven route state; the endpoint tuple does not supply their history.

The next implementation step is to preserve only the route-selected ROM pointer
entries and script spans, then execute `$F1/$F6` and the live `$83D9/$84DC`
state updates from decoded events and source ticks. The trace gives expected
event/cadence counts for validation; never feed its actor arrays or OAM shadow
into runtime.
