# KICK OFF field-introduction visual gap — 2026-10-28

## Scope and source identity

This note isolates the missing gameplay visuals between the Select edge at
source frame 8743 and the first command-panel transition at frame 8893. It uses
the supplied Turkish ROM (SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`) and the
muted, same-input FCEUX 2.7.0 trace under
`reference/diagnostics/kickoff_select_test_20261027/`. Screenshots and memory
snapshots below are observation evidence only, never runtime assets.

## What the route capture shows

| Source frame | Input | Observed display |
|---:|---|---|
| 8743 | Select | Kickoff narration over a field/sky view, score/time readout, ball, and dialogue box. This skips the remaining narration but does not leave the fresh-match route. |
| 8788 | none | A player-and-ball animation is active on the field with dialogue still visible. |
| 8863 | none | The field formation/radar is visible with the player energy line; the selected record is at 397 energy. |
| 8893 | B | The field/radar remains visible on the B edge. The command panel is not yet fully drawn. |
| 8938–8953 | none | The command prompt appears during this sampled interval; the complete first action panel is present by 8953. |

The full capture observations and frame-sampling bounds are in
`kickoff_first_command_menu_trace_20261027.md`. The route's selected-player
record transitions and source-derived stamina calculation are in
`first_command_player_state_source_20261027.md`.

## ROM path that produces these visuals

These frames are not a continuation of the bank-$05 cutscene VM's final
background. The field intro is produced by the match-start/gameplay path:

1. The bank-$10 scenario `$35` stream begins at CPU `$B7CD` (file
   `0x0237DD`). It includes the initial kickoff wait/event record; the
   documented A/B edge at frame 8593 advances the fresh-match setup.
2. Scenario `$36` begins at CPU `$B7E4` (file `0x0237F4`). Its decoded actor
   events select animation streams including `$4E`, `$66`, `$4C`, and `$E6`.
   The `$E6` stream's `$F8` redirect enters the `$961A` block. The actor/event
   to `$F1` packet crosswalk, including events around frames 8624–8781, is
   documented in `first_command_actor_scenario_event_source_audit_20261027.md`.
3. After the initial field loop begins, scenario `$1E` starts at CPU `$B7DA`
   (file `0x0237EA`) through `$E233`; its `$07 $45 $90 $F0` record starts the
   match's field actor set. Frame 8822 is the traced `$90` selection. The
   current ball-player slot and its ROM roster/stamina record drive the
   energy line; the 397 value is the result of a field-loop stamina update,
   not a constant to paint into the frame.
4. The bank-$10 reader at `$803F` parses event records; its bounded helper
   handles exact depth-zero route `$FB` termination and nested `$FA/$FB` stack
   effects. Live continuation/task state remains unresolved. The fixed-bank bridge `$ECF8–$ED06` starts the bank-$14 animation
   worker. Bank-$14 `$800F` selects animation streams, `$80AA` builds actor
   records from `$F1`, and `$83D9/$84DC` advance appearance/motion state.
   Fixed-bank `$EE9F` gathers the actor order/records; bank-$16 `$8000` turns
   actor descriptors into OAM. The ROM spans and capture-only limits are
   detailed in `first_command_actor_scenario_event_source_audit_20261027.md`,
   `first_command_actor_pose_path_20261027.md`, and
   `first_command_player_state_source_20261027.md`.
5. Kickoff field setup enters at fixed-bank `$DAAA`; it initializes the match
   side and score/time state, then reaches `$E0DF/$E145` for the source field
   loop. The source B handler at `$E349` exits that loop to the first action
   panel path. The panel's exact first-pixel frame is only bounded by the
   8938/8953 captures.

## Current Godot boundary

`KickoffRouteRuntime` currently accepts Select by stopping the cutscene VM and
switching to a coarse narration/field stage. It does not run the independent
bank-$10 scenario workers, construct and animate their ROM actor records, or
consume the field-loop's live match state. The field candidate is loaded only
on the later B edge, so it cannot represent the field/actor/energy sequence
already visible from frames 8743–8863. The current menu panel helper can render
ROM-described layout when given a player state, but its runtime route caller
and `$E14D`-eligible update events are still missing.

The existing `Bank10ScenarioBytecodeReader` classifies exact route root `$FB`
terminators when supplied depth is zero; nested/missing-depth continuations
remain external. The new callback API for
scenario `$44` concerns the separate bank-$10 gameplay event `$70`; it does
not establish scenario `$35/$36/$1E` worker scheduling or supply the earlier
shared state. Do not replace this boundary with elapsed-frame scripts, sampled
actor records/OAM, endpoint RAM, or a screenshot-derived field image.

## Next source-backed implementation slice

To reproduce this interval from ROM data, the next bounded runtime unit is a
cooperative match-start worker that:

- follows `$DAAA` into the decoded scenario `$35/$36/$1E` records and `$FB`
  continuation stack;
- dispatches the selected bank-$14 animation workers and applies `$F1/$F6`,
  `$83D9/$84DC`, and bank-$16 descriptor output from preserved ROM bytes;
- owns the match-zero roster/energy/position state derived from ROM tables;
- advances only on source-confirmed scheduler/field-loop events, then hands
  B to the ROM action-menu path without resolving an action.

That bounded replay is now recorded in
[`first_command_menu_wait_and_stamina_trace_20261028.md`](first_command_menu_wait_and_stamina_trace_20261028.md).
It reuses the validated anonymous frame-8399 state, mutes audio, and matches
two passes byte-for-byte. It locates the B/menu path (`$D575`, `$D5C3`,
`$8852/$88B9`), all nine menu queue cycles, the `$E145/$E14D` windows, and the
single `$E1F7/$E2BC` stamina call before B preempts the next one. These traces
establish validation events, not a runtime frame schedule. Still open are the
source reason for the 8856–8881 `$E145` gap, the live player-stat writer, the
full task/worker transitions, and Godot ownership of those events.
