# ROM-only KICK OFF RNG operand trace

## Method

The supplied Turkish ROM was executed from its reset vector by the local
6502/PPU/DMC source stepper using the retained recorded input timeline. This
run did not use FCEUX, captured RAM, screenshots, or WAV files as execution
inputs. The diagnostic instrumented RAM writes and the three indexed reads in
fixed-bank `$C9C5`.

The run completed at source frame 8593 with `$E1/$E2/$E3=$00/$BE/$00` and
receiver slot 6. It observed 8,446 `$A117` updates and 133 `$C9C5` calls. Each
`$C9C5` call reads one value through `$0300,X`, `$0700,X`, and `$0780,X`, for
399 observed operand reads. The detailed local diagnostics are in the ignored
directory
`reference/diagnostics/source_stepper_rng_operand_writers_20261030_203255_utc/`;
`ram_writer_events.csv` is diagnostic output, not a runtime resource.

## Cross-check

The 133 ROM-only calls were aligned by source frame with the retained muted
FCEUX `$C9C5` trace. All 133 triples of operand values and all 133 incoming
carry bits match. The resulting `$E1/$E2/$E3` states also match for all 133
calls. This cross-check establishes
that the ROM-only stepper reaches the same observed `$C9C5` inputs and outputs
on this recorded route; it does not prove arbitrary-input RNG behavior or
Godot runtime parity.

The persistent analysis used `py65` 1.2.0 installed for the current user after
the system-managed Python environment rejected a normal user install. No
project runtime dependency was added.

## Godot status

The route-specific Godot replay now packages the three operands, incoming
carry, and pre/post state. It computes every `$C9C5` result with the existing
byte-level arithmetic helper and checks it against the ROM-only stepper output.
`tools/diagnostics/verify_kickoff_rng_source_schedule.gd` passes: 3,901 retained
RAM snapshots match `$E1/$E2/$E3`, with 8,446 `$A117` calls, 133 arithmetic
replays, and receiver slot 6 at frame 8593. `RomFreshKickoffSourceRouteRunner`
consumes the replay at source-frame NMI boundaries, and the scheduler adopts
each monotonically advanced state before route work. The recorded-input route
verifier reaches the scenario-$36 `$CB0F` yield and slot-$09 selection with
receiver slot 6. The replay remains bound to one
recorded route; arbitrary input histories still require live RNG event
generation.

The schedule's `source_cycle` values identify the `$C9E5` commit write. The
ignored diagnostic operand-read CSV contains separate cycle stamps for each
indexed read; the replay does not claim those sub-frame phases.

The schedule is generated from the ROM and an explicit recorded input route;
target RAM dumps are not builder inputs. Captures are used only as
cross-checks. Keep that distinction and the fixed-route input hash guard.
