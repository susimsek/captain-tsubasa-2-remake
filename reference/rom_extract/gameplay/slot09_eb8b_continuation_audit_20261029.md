# Root slot-$09 continuation after `$EB8B` — 2026-10-29

## Finding

The saved `$EB8B` point is a repeating match-loop continuation, not a one-time
setup return. In the retained muted route trace, slot `$09` resumes after the
frame-8460 `$EB86->$CB0F` yield, runs the continuation, and yields again through
`$CB0F` on frame 8461. The same slot continues to run in later scheduler scans.
The exact body is present in the existing ROM span `$EB86-$EC07`; its first
callee is fixed-bank `$EC08`, whose first state read is `$0516`.

For the first resumed invocation, the trace has `$0516=$00`, so `$EC08` takes
its immediate `RTS` path. The next call at `$EB9E` is `$ED85`; its first read is
`$05D2`, also zero on this initial route interval, taking that helper's short
return path. The root loop then calls bank-`$18` entries `$8003`, `$8006`, and
`$8009` before it returns to `$EB86` and yields again. Those banked workers and
their produced state are not part of the current live Godot route.

This continuation is an upstream match/field task that runs while the route
approaches the first command menu. It is not proven to draw the command panel
itself. Existing route evidence assigns the menu transition to the later field
loop's B handler at `$E349`; do not treat slot `$09` as the menu renderer.

## ROM identity and source spans

All offsets below are file offsets in the supplied ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
(iNES 1.0, mapper 4). The iNES header is 16 bytes. Fixed `$C000-$DFFF` maps
bank `$1E`; fixed `$E000-$FFFF` maps bank `$1F`; bank `$18` is the current
switchable low `$8000-$9FFF` window.

| CPU span | Bank/window | File offset | Bytes | SHA-256 | Status |
| --- | --- | ---: | --- | --- | --- |
| `$EB86-$EC07` | fixed `$1F` | `0x03EB96` | 130 | `91ee3ddc0110b7575a472103de8f5e4d1391a60efebe557b4f4238940d74f917` | Existing hash-checked span in `task_context/manifest.json` |
| `$EC08-$EC0F` | fixed `$1F` | `0x03EC18` | `AD 16 05 29 81 D0 01 60` | `ffe577104f3ec43bdd7af0ed111ca5096c0685d8c5d40f5831984b5ee511976d` | Newly mapped helper prefix |
| `$ED85-$ED8A` | fixed `$1F` | `0x03ED95` | `AD D2 05 D0 01 60` | `ddb8a7b385df09529ec1aa3f5c0eecf223fb07fd30fa25a7938a897d33e68044` | Newly mapped helper prefix |
| `$CE2D-$CE49` | fixed `$1E` | `0x03CE3D` | `A5 22 09 06 85 23 8D 00 80 A5 24 8D 01 80 A5 22 09 07 85 23 8D 00 80 A5 25 8D 01 80 60` | `6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c` | Existing mapper helper, newly consumed by this bounded component |
| `$8003-$8005` | bank `$18`, low window | `0x030013` | `4C F8 86` | `bebc313ee43ac49e4e74dbab33cea40cff8dd41c6705ad17b644715d9e29c2af` | First worker vector; lands at the stop boundary `$86F8` |
| `$8006-$800B` | bank `$18`, low window | `0x030016` | `4C 79 87 4C E6 87` | `64a9592a991603b6d6c3c2181cb332062acf2d08269d7c304c65aea3f8d53611` | Later vectors mapped by the earlier 9-byte static span; not executed here |

The root-loop span remains shared from `task_context/manifest.json`. The four
new component spans are packaged and hash-checked by
[`slot09_eb8b_continuation/manifest.json`](slot09_eb8b_continuation/manifest.json).
All source bytes were extracted from the same hash-identified ROM; no runtime
ROM or emulator dependency is added.

## Continuation and first unresolved inputs

The original `$EB86` entry is `LDA #$01; JSR $CB0F`. Its return address is
`$EB8B`. The focused slot-`$09` verifier derives task record
`01 76 00 01`, saved SP `$76`, and resume PC `$EB8B`; the dispatcher's RTS
restores the worker's `$78` stack depth. No captured RAM values are required to
derive that continuation.

The resumed ROM sequence is:

1. `$EB8B` reads `$0021`, masks it with `$1E`, reads `$0539`, optionally XORs
   `$0539` when nonzero, and stores the result back to `$0021` at `$EB99`.
2. `$EB9B: JSR $EC08` enters the first helper not yet consumed by the
   production route. Its prefix reads `$0516` and masks `$81`; if zero, it
   returns at `$EC0F`.
   In the first matched resumed pass, frame 8461 records
   `$scenario_0516_0518 = $00 $00`. The `$0516` value is route state and must
   remain source-produced; later the same trace records scenario activation.
3. `$EB9E: JSR $ED85` reads `$05D2`; `$ED85-$ED8A` returns immediately when
   `$05D2==0`. The task-write log shows the route's `$05D2` stores remain zero
   through the first resumed invocation. Later, frame 8707 records
   `$ECF7: $05D2 $00->$80` followed by `$ED94: $05D2 $80->$01`, proving that
   the no-op prefix is not a complete implementation for the full path.
4. The caller saves A, maps banks `$18/$19` through the fixed mapper helper,
   and calls `$8003`, `$8006`, and `$8009`. The ROM vectors target
   `$86F8`, `$8779`, and `$87E6` in bank `$18`. After their returns, the root
   loop checks its live match/task flags and either takes the source branch or
   loops to `$EB86`, where it yields again with continuation `$EB8B`.

The component consumes the live slot-`$09` yielded dispatch, including its
RAM, stack, and mapper state. It does not seed `$0516` or `$05D2` from the
trace. The first still-unimplemented source body is the bank-`$18` worker at
`$86F8`; the nonzero `$0539`, `$0516`, and `$05D2` branches also remain
unsupported.

## Bounded source component

[`rom_slot09_eb8b_continuation_prefix.gd`](../../../scripts/gameplay/rom_slot09_eb8b_continuation_prefix.gd)
consumes only the live `next_task_dispatch` dictionary produced by
[`rom_fresh_kickoff_source_route_runner.gd`](../../../scripts/gameplay/rom_fresh_kickoff_source_route_runner.gd).
That dispatch now carries the actual scheduler RAM image and stack page, plus
MMC3 register-select state derived from the scheduler's `$CAB9->$CE2D` mapping
and the slot-restored bank pair. The component
requires slot `$09`, yielded-resume path, PC `$EB8B`, A/X=`$78`, Y=`$05`,
SP `$7A`, and the live `$00/$01` banks. It copies this state; it does not read
trace RAM or supply values for `$0516/$05D2`.

The executor follows the checked source PCs in order: `$EB8B` masks `$0021`
with `$1E`; `$EB9B->$EC08` reads and masks `$0516`, then returns at `$EC0F`;
`$EB9E->$ED85` reads `$05D2`, then returns at `$ED8A`. It saves/restores A,
executes the fixed `$CE2D` MMC3 helper, writes bank pair `$18/$19`, calls the
bank-`$18` vector at `$8003`, and follows its checked `JMP $86F8`. It stops
before reading or executing any `$86F8` worker byte.

At that stop, the verifier checks the exact source-PC sequence, RAM writes,
MMC3 writes, registers, and stack. The final state is PC `$86F8`, mapper
`$18/$19`, SP `$78`, and a pending JSR return word `$EBB2` at stack offsets
`$0179/$017A`, which would return to `$EBB3`. It separately confirms that
nonzero `$0539`, `$0516`, or `$05D2` inputs are rejected at their unresolved
branches. The focused command
`godot --headless --path . --script tools/diagnostics/verify_rom_slot09_eb8b_continuation_prefix.gd`
passes.

This is a diagnostic source component and is not wired into
`KickoffRouteRuntime`. It does not execute the bank-`$18` worker, apply PPU
effects, render the first command menu, or establish same-input visual/audio
parity.

## Muted trace evidence

The evidence is the retained two-pass FCEUX 2.7.0 NTSC/NewPPU trace from the
signature-checked anonymous frame-8399 checkpoint, with audio muted and the
same recorded KICK OFF input prefix. Both passes agree; the source report
records event SHA-256
`5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a` and write
SHA-256
`c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22`.
The route-input SHA-256 is
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.

Relevant event/write rows in
`reference/diagnostics/first_command_task_boundary_20261028_070655_utc/`:

- Frame 8460, cycle 27721: slot `$09` enters `$CB0F` with A=`$01`, SP=`$78`,
  and banks `$00/$01`; this is the first `$EB8B` yield.
- Frame 8461, cycle 6398: `$EB9B` stores `$0021=$1E` (unchanged value),
  confirming the resumed root body reached its first helper callsite.
- Frame 8461, cycles 6447-6670: the caller maps bank `$18/$19` for the three
  worker calls; at cycle 6712 bank `$18` PC `$8814` writes `$0538=$00`.
- Frame 8461, cycle 6740: slot `$09` reaches `$CB0F` again with A=`$01`,
  X=`$00`, Y=`$05`, SP=`$78`, mapper banks `$18/$19`, and `$0516=$00`.
- Later rows show the slot running repeatedly; the full capture reaches the
  first command panel by frame 8953, but does not attribute panel pixels to
  the slot-`$09` routine.

These are emulator observations, not physical CPU/PPU timing claims or runtime
inputs. No new FCEUX run was needed for this mapping; the retained checkpoint
and two-pass trace already cover the relevant initial and later route states.

## Relation to the first command menu

The slot-`$09` loop is part of the match-start scheduler path and must be
modeled for the route's source state, worker order, and field progression to
match. It invokes three bank-`$18` workers on the observed route and later
responds to nonzero `$0516/$05D2` state. However, the retained evidence does not
show that these workers own the final command-panel tiles or text. The field
intro report places the command-panel transition on the field loop's B path at
`$E349` (input at frame 8893; panel complete by frame 8953). Keep slot-`$09`
continuation and panel rendering as connected but separate source questions.

## Stop boundary

The source executor stops at the first bank-`$18` worker entry `$86F8`, before
executing its body. `$8779`, `$87E6`, and the nonzero `$0516/$05D2` handler
branches remain undecoded. The source component is not production-route
integration and does not claim a complete field scene or first-menu pixel
parity.

## Follow-up route integration — 2026-10-29

The live route now executes the first worker's observed zero branch: the
hash-checked `$86F8` executor reads `$0532` from live RAM, takes `BEQ $8722`,
and returns through the pending `$EBB2` stack word to `$EBB3`. It stops before
the following `$8006->$8779` call. This does not extend nonzero scenario
coverage or establish field rendering.

## Scenario-$35 actor-seed continuation addendum — 2026-10-30

The production route now supplies the later scenario-$35 slot-$09 dispatch
from its scheduler RAM image. When the live values at `$EB8B` are
`$0516=$51`, `$0518=$35`, `$0519=$00`, `$0523-$052A = 02 3A 02 BC 2C 8F 73 00`,
and `$05CE=$00`, the prefix follows the checked `$EC8C-$ED15` path and stops
before the scheduler-owned `$ED15->$CAE7` call. It emits the complete source
callsite request and continuation boundary; it does not seed slot `$11` itself.
The route/scheduler layer validates that request, runs the `$CAE7` helper, and
returns the parent slot `$09` context at `$ED2D`. The prefix then consumes the
checked `$ED2D-$ED5A` caller tail and stops at the `$86F8` vector before the
worker body. ROM spans for the caller, helper, root loop, append handler, and
continuation are copied into this package so downstream validation can match
every request hash against a local manifest row.

The next observed slot-$09 resume has a nonzero scenario wait. Source `$EC37`
branches to `$ED5B`; the handler starts `DEX; STX $0519` and then either
returns or enters the bank-$10 worker path. The prefix validates the local
`$ED5B-$ED84` source span and stops at `$ED5B` before executing its first
opcode. Thus the decrement and ensuing worker are explicitly outside this
increment; no delay is fabricated. The `$ED15` request is derived only from
the live scheduler dispatch and source execution; retained trace bytes are
validation evidence, not runtime inputs.

The focused diagnostic `tools/diagnostics/verify_rom_slot09_live_actor_seed_prefix.gd`
starts from the ROM-derived fresh KICK OFF context and follows actual scheduler
state and caller-supplied NMI edges to the live `$0516=$51` boundary. It verifies
the `$ED15` request, scheduler-owned seed, and `$ED2D->$86F8` continuation
without running the worker body. Its current headless run passes. The broader
route runner then reaches `$EBD7` with live `$052E=$EB` and stops at `$EBDA`;
that nonzero countdown branch remains a separate unresolved source transition.
