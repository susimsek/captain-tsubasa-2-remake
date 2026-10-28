# Fresh root slot `$01` startup runtime slice — 28 Oct 2026

## What is implemented

`RomGameplayTaskScheduler` now loads and hash-checks the preserved fixed-bank
source span `$CA22–$CA51` from
`reference/rom_extract/gameplay/task_context/fixed_root_slot01_startup_CA22_CA51.bin`.
After the ROM-derived task bootstrap and initial scheduler dispatch, a bounded
opcode runner applies the span's supported `LDA`, `ORA`, and `STA` instructions
through the direct `$CA4F JSR $CB0F` yield. It rejects any unrecognized opcode,
changed source bytes, or write outside modeled internal RAM. It is a targeted
source slice, not a general 6502 interpreter.

The dispatch context is derived from the bootstrap/scheduler source: `$CAD4`
loads the task's saved SP into A, transfers it to X, then restores SP and RTSes
to `$CA22`; Y retains `$78`, loaded by the final root `$CAE7` seed. The retained
FCEUX trace is used only as an independent validation oracle.

## Verified result

The focused Godot 4.7.2 verifier runs the packaged ROM bytes and checks the
first yield against `reference/diagnostics/first_command_task_boundary_20261028_070655_utc/task_events.csv`:

- At `$CB0F`, A/X/Y/SP are `$01/$28/$78/$28` for slot `$01`.
- After the yield save, the next scheduler event sees task record
  `$01: 01 26 00 01` (one-tick delay, saved SP `$26`, bank pair `$00/$01`).
- The byte runner produces the setup stores at `$0490/$0491`, `$0087/$008E`,
  `$0469`, and `$0543–$0545`, with a stack continuation back to `$CA52`.
- The scheduler scan cursor then advances through slot `$05` and `$09`; it
  does not immediately restart at slot `$01`. The updated verifier exercises
  that order, including the observed slot-`$05` record
  `01 46 18 19` before slot `$09` dispatch. The later return to `$CA52` after
  NMI gating and intervening task bodies remains outside this bounded slice.

Command:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_gameplay_task_scheduler_runtime.gd
```

## Boundaries

The source slice does not model the mapper helper's complete CPU behavior, NMI
cadence, instructions after `$CA51`, other root-task bodies, or the route's
source call that enters `$C6BE`. `KickoffRouteRuntime` does not call this
scheduler slice, so the first-match command menu remains unreachable in the
production route. Same-input whole-screen and route-audio parity remain open.
The trace values above are validation data and are never loaded by runtime
code.

## Next continuation boundary

The supplied ROM bytes immediately after this packaged span, at fixed-bank
CPU `$CA52` (file `0x03CA62`), begin `20 9F EE 20 CA E3 4C 4D CA`: call
`$EE9F`, call `$E3CA`, and jump back to `$CA4D`, whose `$CA4F` call yields to
the scheduler. `$EE9F` is the actor update/draw path documented in
`first_command_actor_state_producer_20261027.md`. The Godot slice does not yet
execute these continuation instructions or reproduce their per-frame caller
state. This is the immediate source boundary after the implemented startup;
it does not itself connect the route to the first command menu.
