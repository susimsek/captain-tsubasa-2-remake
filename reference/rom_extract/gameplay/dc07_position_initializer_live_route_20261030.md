# Live `$DC07` Position-Initializer Integration

## Scope

This increment connects the recorded title-route A press to the match-zero
position initializer. It starts at the live slot-`$05` call boundary `$DAF2`
and stops after the callee returns at `$DAF5`. The execution reads preserved
ROM-derived code, pointer tables, and coordinate tables; it does not read a
RAM capture as runtime input.

## Source-backed behavior

- The call at `$DAF2` is `JSR $DC07` (`20 07 DC`) and returns to `$DAF5`.
- `$DC07` reads formations from `$002C/$002E` and side `$05FB`; match zero
  resolves formations 0/0 and home side 0 for the recorded route.
- The routine derives an 11-slot table stride, selects bytes from `$DC87` or
  `$DCB3`, transforms each encoded position with `$CDC9`, and obtains the
  record address from `$CD89` through `$CD7C`.
- For each of 22 records it stores Y at `+8`, then X at `+6`. Slot 11 also
  clears `+7`. Scratch `$003A/$003B` hold incrementing formation-table
  indices; `$0034/$0035` finish at record `$03FC` (global slot 21).
- The modeled return restores SP to `$50`. `$DAF2`'s return word is `$DAF4`.
  The final loop count in A is `$16`; Y is `$06`, and X is the last player's
  transformed X coordinate. Only source-derived return flags are marked
  known. The route does not claim instruction-cycle or PPU/APU phase accuracy.

The source code and data spans are hash-checked by
`scripts/gameplay/rom_match_player_position_initializer.gd` against the
supplied ROM revision and `reference/rom_extract/gameplay/first_command_field/player_record_positions/manifest.json`.
`RomGameplayTaskScheduler` replays the executor's ordered RAM and stack writes
against the live `$DAF2` boundary before adopting its `$DAF5` result.

## Validation

The recorded-input route takes the one-frame A press at source frame 8593. It
reaches `$DAF2` with `$001C=$80`, `$001E=$80`, and `$0441=$08`, executes the
initializer, and stops at `$DAF5` with SP `$50`. All 22 derived record X/Y
pairs match the FCEUX RAM oracle
`reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008593.bin`
(SHA-256
`4e85e92b66673be7270fa104d765079e85ed93df4edb29d7905162401fd96162`). This
checks the same recorded input frame's position values; the capture is only a
diagnostic oracle and does not establish that both executors were sampled on
the same CPU instruction or cycle.

Command run:

```text
CT2_ROUTE_EXPECT_DAF5=1 godot --headless --path . --script res://tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: pass at `$DAF5`; the frame-8594 A-release event is confirmed in the
recorded input stream but is not consumed because the route stops at this
boundary.

## Remaining route work

The recorded route now continues from `$DAF5` through `$DC82` receiver
selection, `$E6EC` holder setup (including `$CDE2`), scenario-$36 enqueue, and
the actual `$CB0F` yield. It then scans the scheduler and selects slot `$09`
before dispatch. See
[`scenario36_queue_live_route_20261030.md`](scenario36_queue_live_route_20261030.md).
The slot-$09 scenario consumer, first command menu, visible field output,
audio parity, precise source-clock behavior, and runtime independence checks
remain open.
