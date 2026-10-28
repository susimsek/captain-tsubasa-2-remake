# First-command actor animation tick source audit — 2026-10-28

## Evidence and scope

This audit uses the supplied Turkish ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, the
preserved route animation bytes under `first_command_actors/`, and the muted
same-input trace in
`reference/diagnostics/first_command_scenario_timing_20261028_045844_utc/`.
The trace validates source timing only; no event CSV, captured actor record,
OAM bytes, or endpoint pose is a runtime input.

## `$800F` source-tick handler

Bank `$14`'s jump table at CPU `$8000` sends the active actor-animation stream
to `$800F`. Its relevant bytes at file `0x02801F` include:

```text
AD 3A 05       LDA $053A
F0 6F          BEQ $8083
10 51          BPL $8067
...
$8067: CE 3B 05 DEC $053B
$806A: F0 01    BEQ $806D
$806C: 60       RTS
$806D: A0 00    LDY #$00
       B1 4C    LDA ($4C),Y
       C9 F0    CMP #$F0
       90 06    BCC $807B
       20 84 80 JSR $8084
       4C 6D 80 JMP $806D
$807B: 8D 3B 05 STA $053B
       A9 01    LDA #$01
       20 CF 83 JSR $83CF
       60       RTS
```

The handler loads an animation stream pointer from the bank-`$14` pointer
table, then decrements `$053B` on each `$800F` call. If it reaches zero during
that call, command parsing continues immediately; otherwise that call returns.
A byte below `$F0` is copied to `$053B` and advances the stream pointer by one.
Thus a positive value `N` delays the next command by `N` source animation calls;
zero wraps on the next decrement and delays the next command by 256 calls.
The active route trace independently observed one `$14:$800F` invocation per
source actor-loop frame in frames 8461–8953 (493 calls), but the decoder reports
relative animation ticks, not absolute route frames or hardware timing.

## `$F6` is an actor removal with an inline operand

The top-level command vector at CPU `$808A` maps `$F6` to bank-`$14` `$83AE`
(file `0x0283BE`). Its byte sequence is:

```text
A0 01          LDY #$01
B1 4C          LDA ($4C),Y
AA             TAX
A9 00          LDA #$00
9D 47 05       STA $0547,X
A9 02          LDA #$02
4C CF 83       JMP $83CF
```

The operand is an offset from `$0547`, the start of the actor-record array.
The handler clears that actor record's active/flag byte, advances the top-level
stream pointer by two bytes via `$83CF`, and returns to the animation loop.
The route `$78` stream contains `$F6 $00`, `$F6 $2A`, and `$F6 $3F`, removing
record indexes 0, 2, and 3. Treating the operand as a free low-byte wait would
mis-time this stream and leave stale actors on screen.

## Decoded source-relative schedule

The existing `RomActorAnimationStreamDecoder` now exposes
`decode_timeline(animation_id)` and `decode_scenario_event_record(token)`. The
bridge accepts only an `event_record` token from `Bank10ScenarioBytecodeReader`,
reads its ROM-derived `$0523/$0524/$0528/$0529` assignments, and returns the
selected ROM animation's typed events with relative `$800F` source ticks. It
keeps the scenario `$0523 → $0519` wait separate; the caller must invoke it at
the source `$EC94` wait handoff, not at an assumed frame. The API does not
mutate actor RAM, produce OAM, consume trace rows, or claim absolute route timing.

For scenario `$36`'s `$01` event, `$E6` starts with `F5 87 F8 1A 96` and
redirects into animation `$78` at CPU `$961A` / file `0x02962A`. The decoded
`$78` command schedule is:

| Relative `$800F` tick | ROM event | Effect |
| ---: | --- | --- |
| 0 | `$F1` packets at `0x02962F/35/3B/41` | Construct four actors |
| 0 | `$14` at `0x029647` | Set countdown to 20 |
| 20 | `$F4` selectors, three `$F6` packets at `0x02964D/4F/51`, `$F1` at `0x029653` | Select CHR pages, clear records 0/2/3, construct actor record 1 |
| 20 | `$02` at `0x029659` | Set countdown to 2 |
| 22 | `$F1` at `0x02965A`, then `$F0` at `0x029660` | Construct final actor packet and end stream |

This source schedule predicts the trace's observed constructor groups: the
first four at frame 8759, the fifth at 8779, and the sixth at 8781. It is a
cross-check, not a hardcoded runtime frame schedule.

## Integration boundary and remaining work

The bank-$10 reader and animation decoder can now pass a decoded scenario
record to a relative actor-command schedule. They are not yet connected to the
route. Inspection of `scripts/gameplay/kickoff_route_runtime.gd` and
`scenes/kickoff_route_runtime.tscn` found no bank-$10 `event_record` token
producer, `$0518–$0529` state, `$053A–$053D` animation worker state, or
`$001B.7` task/NMI scheduler. The route's generic `scheduler_tick` is not a
source for these events, so connecting the decoder to it would fabricate the
actor command onset. The minimum future route interface is a ROM-owned
scenario-task producer that emits:

1. The decoded four-byte event record and source event selector.
2. A `begin_scenario_wait` call at the actual `$EC94` handoff, followed by one
   wait-tick call at each source `$ED5B/$ED5F` countdown.
3. A `start_actor_animation` event at the `$ECF8–$ED06` worker launch, carrying
   the source animation ID/parameter and its decoded relative tick events.
4. Per-source-frame actor-loop ticks at the `$EE9F → $14:$800F` call boundary.

F5 setup side effects and F4's runtime selector writes are preserved but not
executed by the new schedule API. The route also needs the motion and
appearance table entries/spans used by its `$F1` packets, live `$83D9/$84DC`
interpretation, shared `$0546/$0517/$0538/$0540/$0541` state, and renderer/OAM
integration. These gaps prevent wiring a complete actor presenter or
displaying the frozen `$44/$5C` endpoint pose during earlier route frames.
