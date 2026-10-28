# Fresh-match scheduler handoff trace — 28 Oct 2026

## Source identity and capture method

The trace uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, with
FCEUX 2.7.0, NTSC/NewPPU, and emulator audio muted. It loads the existing
opening and post-title input timelines. One anonymous in-memory savestate is
created at source frame 8399, checked against frame/cycle, 2 KiB RAM, 16 KiB
PPU memory, MMC3 state and mapped PRG bytes, then loaded for two replays. No
numbered user slot is used.

The new execution hooks record the ROM handoff from bank `$82` through the
fixed-bank task bootstrap. Both passes match: 6,086 task events and 62,357
watched writes each. Normalized trace hashes are listed in `validation.json`.
The output is diagnostic evidence only; it is not loaded by Godot runtime.

## Observed caller sequence

| Source frame | FCEUX cycles from frame start | ROM point | Observed source state |
| ---: | ---: | --- | --- |
| 8458 | 26,797 | Bank `$82:$A2AF` | Fresh-match setup begins; task records show prior route state. |
| 8459 | 22,669 | Bank `$82:$AA06` | The `$0468–$062F` zero-fill helper begins. |
| 8460 | 12,848 | Fixed `$C557` | `JMP $C6BE`, the source-owned scheduler handoff. |
| 8460 | 12,850 | Fixed `$C6BE` | Fresh task-slot setup begins. |
| 8460 | 22,661 | Fixed `$C6E8` | Root task bootstrap begins after the slot-clear helper. |
| 8460 | 24,252 | Fixed `$CA97` | Scheduler first enters its ROM-ordered slot scan. |

These are FCEUX source-timeline observations, not physical NES cycle claims or
Godot frame-delay constants. The causal implementation boundary is the
decoded `$A2E5 JMP $C557` followed by `$C6BE`; it can be modeled as a source
event without scheduling it from an elapsed-frame count or later A/B press.

## Task order correction

The same trace confirms the scheduler continues at `$CAA5` after a task yields
instead of restarting the scan at `$CA97` immediately:

1. Slot `$01` dispatches, then its `$CA4F` call reaches `$CB0F` with
   A/X/Y/SP=`$01/$28/$78/$28`.
2. The yield saves slot `$01` as `01 26 00 01`; `$CAA5` advances the slot cursor.
3. Slot `$05` dispatches with X/Y=`$05/$01`, then yields with A/X/Y/SP=`$01/$FF/$00/$48`.
4. Its record becomes `01 46 18 19`; slot `$09` dispatches next with X/Y=`$09/$05`.

The Godot scheduler runtime now preserves this scan cursor and scheduler Y
across the first two yielded tasks. It still does not execute the slot-`$05`
body: that callsite state is supplied only to the focused verifier so the
stack-save arithmetic and slot order can be compared with the trace.

## Artifacts and limits

- `../../diagnostics/first_command_task_boundary_20261028_115428_utc/metadata.txt`
- `../../diagnostics/first_command_task_boundary_20261028_115428_utc/task_events.csv`
- `../../diagnostics/first_command_task_boundary_20261028_115428_utc/task_events_repeat.csv`
- `../../diagnostics/first_command_task_boundary_20261028_115428_utc/task_writes.csv`
- `../../diagnostics/first_command_task_boundary_20261028_115428_utc/task_writes_repeat.csv`
- `../../diagnostics/first_command_task_boundary_20261028_115428_utc/validation.json`

This closes the exact observed `$C557`-to-bootstrap event order for this
input. It does not yet wire the source caller into `KickoffRouteRuntime`, run
the complete task graph/NMI cadence, generate actor/player state, reach the
first command menu, or prove whole-screen/audio parity.
