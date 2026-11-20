# Slot-$11 `$A21A` busy-queue gate and map-$36 continuation

## Result

The recorded-input Godot route now models the ROM's busy-queue branch at
`$A21A` as a cooperative task yield. Its animation pointer, wait counters, and
`$0515` queue flag match the same-input FCEUX RAM captures at all 15 sampled
frames from 8783 through 8797. The route then continues to frame 8801, where
the prior secondary queue is consumed and the map-$36 worker produces its next
three-metatile batch.

This validates selected task RAM and a map queue boundary. It does not prove
complete field composition, PPU-visible frame parity, actor pixels, audio
parity, or physical subframe timing.

## Source behavior

Hash-checked ROM bytes at `$A21A` are `AD 15 05 D0 F6`:

```text
LDA $0515
BNE $A215
```

Any nonzero queue value branches to `$A215`, whose bytes are `A9 01 20 15 C5`:

```text
LDA #$01
JSR $C515  ; JMP $CB0F, save this task continuation
```

The scheduler must select the saved slot-$11 task again before `$A21A` checks
`$0515` and continues building a packet. Resuming `$A21A` immediately after an
NMI skips intervening task scheduling and can consume the queue one frame too
early. The executor and live route now preserve this return/yield path and
recheck the queue only when the task is selected again.

The relevant extracted byte spans and hashes are listed in
[`slot11_actor_worker_resume_wait/manifest.json`](slot11_actor_worker_resume_wait/manifest.json).
The two-pass muted FCEUX event trace is in
[`slot11_actor_handoff_trace_20261030`](../../diagnostics/slot11_actor_handoff_trace_20261030/).
Per-frame RAM captures used for the alignment check are in
[`kickoff_select_test_20261027/ram`](../../diagnostics/kickoff_select_test_20261027/ram/).

## Verification

`tools/diagnostics/verify_kickoff_recorded_input_path.gd` compares the
ROM-derived route's slot-$11 `$0063-$0064` animation pointer, `$05F3-$05F5`
wait counters, and `$0515` flag with FCEUX RAM on each frame 8783–8797. The
frame-8801 route run completed without a failed assertion and reported:

- Map `$36` placements 155–157 at PPU addresses `$298C`, `$2990`, and `$2994`.
- The prior secondary queue was consumed: 15 packets and 96 bus events;
  `$0515` changed from `$80` to `$00`.
- The PPU renderer applied 51 nametable writes and reported zero unapplied
  writes.
- The route produced the next ROM-derived three-metatile batch and yielded at
  `$CB0F` for the scheduler's next NMI-ready cycle.

The verifier's reported route stop is frame 8801, stage
`source_route_waiting_for_nmi`. The 8801 result is a Godot route checkpoint;
it is not a claim that all PPU effects or the rendered field match FCEUX.
