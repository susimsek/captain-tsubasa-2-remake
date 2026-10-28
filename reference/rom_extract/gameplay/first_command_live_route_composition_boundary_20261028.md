# First-command live route composition boundary — 2026-10-28

## Result

The scenario reader, callback pointer table, callback `$70` prefix, one-slot
task helper, six-slot scheduler scan, and `$8327` placement formula can be
validated together as a diagnostic chain. They cannot yet be composed into a
live `KickoffRouteRuntime` event path. The missing state is not a missing ROM
selector or an unknown `$8327` formula: it is the live task/scheduler context
that chooses which callback runs, followed by the callback-owned `$05CD` and
worker continuation state.

The focused check is
[`verify_first_command_live_route_composition.gd`](../../../tools/diagnostics/verify_first_command_live_route_composition.gd).
It checks ROM-derived scenario records and callback pointers against the
supplied ROM, then compares selector order with both retained muted trace
passes. The trace is an independent oracle only; it does not initialize any
model or supply a runtime value.

## Earlier scenario and callback selectors

The bank-$10 scenario sources and their event records decode to the following
sequence. The callback pointer and first three callback bytes are read from
the supplied ROM's bank-$0B `$87F6` table and pointed-to stream.

| Scenario | Event record / `$0524` callback selector | Pointer target | First callback bytes |
|---:|---|---:|---|
| `$35` | `02 3A 8F 73` / `$3A` | `$89F3` | `02 00 42` |
| `$36` | `10 3A 8F F0` / `$3A` | `$89F3` | `02 00 42` |
| `$36` | `20 0C 4E 74` / `$0C` | `$8911` | `02 00 43` |
| `$36` | `32 72 66 F0` / `$72` | `$8B3E` | `F2 19 00` |
| `$36` | `32 1F 4C F0` / `$1F` | `$896A` | `02 03 00` |
| `$36` | `3E 01 E6 75` / `$01` | `$88E3` | `F0 02 00` |
| `$1E` | `07 45 90 F0` / `$45` | `$8A2A` | `06 00 36` |
| `$44` | `02 70 5C F0` / `$70` | `$8B38` | `06 00 56` |

The two task-boundary trace passes independently show this callback selector
order on hook frames 8467, 8593, 8607, 8624, 8667, 8718, 8789, and 8893.
Those frame numbers are observations for this input, not a runtime schedule.
Some callback headers enter the index-zero `$8327` vector directly; others
start with control-flow or another vector entry. Their complete side effects
and worker returns are not implied by these three-byte prefixes. The source
stream bytes are also recorded in
[`first_command_scenario_event_continuation_audit_20261028.md`](first_command_scenario_event_continuation_audit_20261028.md).

## Root-task bootstrap and initial scheduler dispatch

The previous composition report stopped at an unavailable `$0001 +0`
ready/delay byte. That boundary is now resolved diagnostically from ROM
source. The `$C650` zero-fill precondition, fresh-game task-slot clear
`$C6BE–$C6E7`, and bootstrap `$C6E8–$C765` are preserved and hash-checked. The
bootstrap seeds slots `$01/$05/$09` as `FF 28 00 00`, `FF 50 00 00`, and
`FF 78 00 00`, with stack RTS continuations `$CA21/$D11D/$EB85`. The other
ready bytes are cleared before the first scan. Composing those records with
the six-slot scan selects `$01` for the first scheduler dispatch. The fresh
KICK OFF selector audit independently identifies fixed-bank `$C557 → $C6BE` as
the gameplay setup entry.

The diagnostic bootstrap/NMI model and two-pass frame-8460 comparison are
documented in
[`first_command_root_task_bootstrap_and_nmi_20261028.md`](first_command_root_task_bootstrap_and_nmi_20261028.md).
The retained trace validates the source-derived records and stack words; it
does not initialize them. `$001B.7` is also source-modeled for a supplied NMI
edge, but what produces each edge and its cadence are not modeled. The
separate `$8097–$80A8 → $C50F → $CAE7` path seeds callback task `$0015` as
`FF F0 0B 00`; that remains a later task distinct from the initial three.

This resolves the initial scheduler record value, not live scheduling. No
production source path currently executes `$CA21/$D11D/$EB85`, manages their
shared stack/mapper continuations, generates NMI edges, or decides when
callback task `$0015` runs. Do not feed the diagnostic state or captured task
records into `KickoffRouteRuntime`.

## Next missing state at `$8327`

Even if the scheduler boundary were supplied, callback `$70` stops at a second
explicit source requirement: the global `$05CD` byte immediately before
`$8327`. The placement transition can derive `$05CE` and the next `$05CD` from
ROM instructions, but `$05CD` is not a callback parameter or task-record
field. Its earlier route transitions depend on executing the `$35/$36/$1E`
callbacks and their worker/task continuations. The selector trace confirms
which callback IDs occurred; it does not execute their handlers or derive the
RAM history.

The existing replay notes record `$05CD/$05CE` values at eight `$8327`
transitions, ending in `$05CD=$A0` before the `$44/$70` write at frame 8905.
Those remain trace-only checks. The current composition verifier deliberately
calls the placement API without a byte and requires it to refuse with
`source_state_required`.

There is also an earlier scenario interpreter context gap: scenario `$36`'s
`$FD $00` at byte offset `$0F` requires `$0441`, the resolved player record,
and `$0638`; scenario `$1E`'s `$FD $02` at offset `$00` requires `$05FB`. The
reader preserves those unknowns rather than guessing them. Holder-coordinate
selection through `$F0B5` and RNG/active-player state are separate later gaps.

ROM-only static analysis identifies a source path that can set `$0048=$06`:
cutscene ID 2 begins `E8 01 F9 02`; its F9 handler calls bank-0 `$8AF7` at
`$8824`, which reads background record 2 (`background_02.bin`, file
`0x00E137`). Record byte 2 is `$06`; `$8AF7` masks it with `AND #$3F` and
stores it to `$0048` at `$8B4C` (file `0x000B5C`). The matching palette is
already preserved as `background_palette_06.bin` from ROM file `0x00D070`.
This is a byte-verified route candidate, but the retained same-input route RAM
snapshots only bracket the transition: `$0048=$1A` at source frame 8100,
`$0048=$06` by frame 8125, and `$0049=$0E` by frame 8134. The files are
[`route_frame_008100.bin`](../../diagnostics/kickoff_select_test_20261027/ram/route_frame_008100.bin),
[`route_frame_008125.bin`](../../diagnostics/kickoff_select_test_20261027/ram/route_frame_008125.bin),
and [`route_frame_008134.bin`](../../diagnostics/kickoff_select_test_20261027/ram/route_frame_008134.bin).
The already verified frame-8220 anonymous checkpoint also retains
`$0048=$06/$0049=$0E`. No retained PC/write trace ties `$8B4C` to the specific
frame-8125 transition. The attempted muted two-pass writer trace from a
signature-checked frame-8100 checkpoint stalled before FCEUX loaded the ROM or
Lua script, so the source path's exact execution frame/cycle remains
unverified. Do not initialize runtime state from these RAM snapshots.

## Verification and runtime boundary

On Godot 4.7.2, the focused composition verifier checks the root bootstrap,
initial `$CA97` dispatch, scenario/callback sources, and both selector-trace
passes. It uses the scenario test harness's inert eight-byte stack sentinel
only to verify that root-depth `$FB` leaves caller bytes unchanged; that
fixture is not passed to the task models or treated as a route stack snapshot.

No edits were made to `KickoffRouteRuntime` or the field presenter. The route
remains at its existing pending state until source-owned task bodies and
continuations produce the scenario/callback history and prior `$05CD`. Do not
replace these inputs with elapsed frames, the captured transition table, or
endpoint RAM/PPU. This composition does not validate dynamic holder choice,
RNG, or actor state.
