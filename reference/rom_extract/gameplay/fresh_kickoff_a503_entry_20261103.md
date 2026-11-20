# Fresh Match `$A503` Entry, Text, Fade, and `$812F` Boundary

## Result

The production route executes the bounded `$A503` prefix after the ROM
`$B0C0` PPU stream. It clears RAM `$0044/$0045`, copies 52 bytes selected by
`$B271,Y` for `$Y=$CC..$FF` into `$0468-$049B`, and resolves descriptor pointer
`$BCFF`. It parses the first descriptor through `$9D27->$9D58->$88CA`, then
continues from `$A529` through the selected second descriptor and both
participant text IDs. The live route continues through the `$997A` palette
ramp, `$A571` input wait, `$99F0` fade, `$98A0` nametable clear, caller prefix
`$A583-$A58A`, the fresh match-00 `$A611` level loop, and returns through
`$A610` to `$811F`, then the `$C572->$DB62` fresh stamina initializer and
returns to `$8122`, then the live caller selects and stores BGM `$55` at
`$812C` and stops at `$812F`.

Two `$9B28` capacity waits drain full queues through the bounded ROM `$A000`
packet transfer. The two PPU event batches are applied to the live renderer.
This remains a partial setup result: the surrounding NMI, full controller
scan, sound driver, and later `$A000` PPU-shadow/mapper setup are not executed.
`$A611` supports only the verified fresh match-00 zero-experience/zero-level
branch. The stamina initializer supports the observed fresh match-00 roster;
its output writes have not yet been compared with a post-call FCEUX RAM capture.
The `$812F-$815C` caller tail and later match initialization remain open. The
direct BGM store is connected to the ROM-cue presenter, but audio onset and PCM
parity remain unverified.

## Source and data

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`.
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Bank `$01` code `$A503-$A610` is checked against the preserved
  `$A4EB-$A610` body at SHA-256
  `1897387554b3047615392719f5a00c32f4ceb24e56645c64fe7d8a11a3ed3587`.
- The extractor
  [`extract_fresh_match_a503_entry.py`](../../../tools/diagnostics/extract_fresh_match_a503_entry.py)
  preserves the table, descriptor, text, and helper spans in
  [`fresh_kickoff_a503/manifest.json`](fresh_kickoff_a503/manifest.json).
- `$B271,Y` with `$Y=$CC..$FF` reads `$B33D-$B370`; the destination expression
  `$039C,Y` writes `$0468-$049B`.
- Source RAM `$0026=$00` selects descriptor byte `$BCD1=$01`. Its high nibble
  indexes `$BCF3/$BCF4=$FF/$BC`, producing `$BCFF`.
- Independent py65 execution counts 222 instructions and 816 CPU cycles from
  `$A503` to the instruction immediately before `$9D27`. This metadata does
  not establish route timing or physical NES timing.

## First descriptor decode

- `$BCFF` contains `6A 21 42 0B 7A 0D 09 6F 20 43 75 70 FF`: destination
  `$216A`, ten payload bytes, then the `$FF` terminator.
- The ROM inner reader recognizes `$FF` as the block terminator. All ten
  payloads are below `$A0`, selecting the low-tile branch in `$88CA`; each byte
  is staged through `$9B28` as a five-byte record:
  `[82, destination-low, 21, 00, tile-byte]`.
- Runtime obtains the prior queue state only from ROM-source receipts:
  `$0628=$00` last written by `$A04A`, and `$0629=$20` last written by `$9B6B`.
  `$9B6B` is the final `STA $0629`; `$9B69` is the preceding `AND #$40`.
- The first descriptor emits 119 RAM-write receipts and leaves
  `$0628=$32`, `$0629=$82`, with 50 record bytes and a zero terminator at
  `$05E8-$061A`. No PPU event is emitted until a capacity wait drains the queue.
- A separate 791-instruction, 2,809-cycle py65 analysis reaches `$A529` with
  `A=$BD, X=$FF, Y=$0C` and the same queue bytes. This is cycle-count metadata,
  not physical timing evidence. FCEUX frame-7368 comparison checks the earlier
  52-byte copy, not the queue; same-time queue RAM comparison remains open.

## `$A529-$A56B` selected text setup

The checked caller bytes execute three ROM text readers:

| Selector | ROM pointer | ROM tile bytes (terminator omitted) | PPU destination |
| --- | --- | --- | --- |
| `$BCD1` low nibble `$01` | `$BD7C` via `$BD64` | `34 2E 4D 61 63` | `$2207` |
| RAM `$002A=$00` | `$BDF2` via `$BDA8` | `03 6F 20 1C 75 7D` | `$21D0` |
| RAM `$002B=$03` | `$BE09` via `$BDA8` | `46 6C 75 1F 7C 6E 0E` | `$2250` |

The streams end with `$FF`; terminators are consumed and not emitted as tiles.
Each character uses the ROM `$9D50->$9D58->$88CA->$9B28` path to append a
five-byte record `[82, address-low, address-high, 00, tile]`. Header `$82`
means two payload bytes with PPU increment 32, so each record writes zero at
the row address and the tile at the address 32 bytes above it.

Starting with the ten `$BCFF` records, the caller adds two `$BD7C` records
before `$9B28` yields at cursor `$3C`. The first bounded `$A000` transfer
drains twelve records (24 payload bytes). The caller resumes with three
remaining `$BD7C` characters, all six `$BDF2` characters, and the first three
`$BE09` characters, then yields again at cursor `$3C`. The second transfer
drains twelve records. The last four `$BE09` characters remain at cursor
`$14` when the caller reaches `$A56C` with `A=$04`, `X=$37`, `Y=$07`.

The same-input FCEUX trace reaches `$A56C` at frame 7269. In Godot, each
capacity wait advances to a later route tick, executes only the bounded
`$A000` packet-buffer transfer through `$A05F`, applies 66 PPU bus events to
the live renderer, then resumes the caller. Each transfer contains 12 packets,
24 payload bytes, and 24 applied nametable writes. This does not claim the
surrounding NMI, controller, sound-driver, DMA, or later PPU/mapper setup, and
does not establish physical NES subframe timing.

The production route receives no FCEUX RAM, screenshots, or captured audio.
The exact queue RAM bytes and emitted PPU events have not yet been compared
with same-time FCEUX observations. The frame-7368 RAM comparison corroborates
only the earlier A503 scratch clears and 52-byte copy.

## `$997A->$A571->$99F0->$98A0` continuation

The source trace enters `$A571` at frame 7284 with `X=$F0`; its first
post-`$9FA8` decrement is visible at frame 7285 with `X=$EF`. The live route
represents the entry yield separately, then advances the source wait loop once
per later route frame. Its frame-level controller adapter computes the
observed edge expression from consecutive live pad masks; it does not execute
the controller-scan NMI phase.

With the recorded A press, FCEUX reaches `$A57D` at frame 7393 with `A=$80`,
`X=$84`, RAM `$001C=$80/$001E=$80`, and the palette still lit. Godot's live
route reaches the same source boundary and register values. The verifier
compares the same-input RAM edge and confirms the frame-7393 PPU palette is
still lit.

The `$99F0` helper emits fifteen 35-byte palette packets from ROM-derived
palette data and the `$9EA2` lookup. Each is consumed by the bounded ROM
`$A000` transfer on the next route frame: producers are frames 7393-7407,
consumers 7394-7408, and each consumer emits 40 PPU register events. At the
zero-counter return, `$98A0` writes 2,048 zero bytes to PPU nametable space
`$2000-$27FF`. Godot's active background palette and nametable match the muted
FCEUX PPU capture at frame 7408 (all palette bytes `$0F`, nametable bytes zero).
The `$A583-$A58A` caller prefix writes `$00ED=0` and `$00EC=0`; `$A611` then
checks all eleven home records, leaves their zero level bytes unchanged, and
returns through `$A610` to `$811F`. The route then executes `$C572->$DB62` and
returns to `$8122`. The level-loop result is compared with
the frame-7409 FCEUX RAM observation. The matching-PC hook at `$A58B` was
captured in frame 7408; the frame-end RAM dump for frame 7408 predates that
hook, so it is not used as the `$A611` input oracle. A bounded py65 run uses
the hook's `$EC/$ED` values with the earlier frame-end RAM baseline, then
agrees with FCEUX frame 7409 on the relevant loop outputs.

This is frame-level state/output agreement only. It does not prove CPU-cycle,
within-frame PPU, controller-NMI, or audio timing equivalence.

## Production verification

Command:

```sh
CT2_ROUTE_FINAL_FRAME=7409 godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: PASS on Godot 4.7.2. The stamina executor returns to `$8122`; the
production caller then stores BGM `$55` at `$812C` and the route holds at
`$812F` on frame 7410 after
`$A611` and the stamina pass. The verifier checks the `$A503` entry and text setup, two queue drains,
the `$A571` frame-7393 A-edge boundary with `X=$84`, fifteen consecutive fade
packet producers/consumers, the 2,048-byte `$98A0` clear, the active palette
and nametable against FCEUX frame 7408, the `$A611` loop outputs against
FCEUX frame 7409, the stamina inputs against FCEUX frame 7409, all eleven
ROM-table stamina calculations and 22 source-RAM writes, and the caller
register/write contract. No post-call FCEUX RAM sample is available to claim
same-input confirmation of the energy outputs.
The earlier frame-7368 RAM comparison still corroborates only the scratch
clears and 52-byte copy. FCEUX state remains validation-only and is not passed
into the runtime executor.

## Remaining gaps

- The bounded `$A000` transfers do not cover surrounding NMI dispatch, OAM
  DMA, controller scan, sound-driver work, or PPU/mapper setup after `$A05F`;
  their bus writes still need comparison against same-time FCEUX observations.
- `$A611` is implemented only for fresh match-00 records with zero experience
  and zero levels; nonzero experience/level branches are not supported. The
  `$812F-$815C` caller tail and later match initialization are not yet executed by
  the production route. The surrounding NMI, full controller scan, audio
  driver, and PPU/mapper work are not part of the bounded helpers executed here.
- Fourteen earlier interrupt effects, exact frame/subframe timing, visible
  field/menu composition, route audio, navigation, and ROM/emulator-free
  packaging remain unverified.
