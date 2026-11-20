# Slot-$11 actor worker: first resume and internal yield

## Result

The actor worker's first yield is followed by a real scheduler resume on the
next recorded source frame. The saved JSR return word resumes the bank-$18
worker at `$804A`. The worker later reaches a second yield inside fixed-bank
code at `$CC50`, whose return address resumes at `$CC53`. This is a nested
wait/yield boundary, not another execution of the initial `$8047` setup.

The retained trace establishes both task boundaries and their repeated
two-pass agreement. It does **not** instruction-trace every instruction between
`$804A` and `$CC50`, sample `$0515` at the wait branch, or establish rendered
actor pixels. A bounded ROM-byte executor now covers the initial F4/F5 stream
path through the first `$CC50` call, and a scheduler consumer applies that
result under a synthetic fixture. At the time of this report's initial capture,
the production route had not yet supplied this live boundary; the later route
extension is recorded below.

## ROM-derived continuation

The ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Source spans and their hashes are recorded in
[`slot11_actor_worker_resume_wait/manifest.json`](slot11_actor_worker_resume_wait/manifest.json).

After the initial `$8047: JSR $C515`, `$CB0F` saves the slot-$11 task record
with delay `$01`, stack pointer `$C6`, and bank pair `$18/$19`. The stack holds
the saved Y/X values `$E7/$42` and the JSR return-minus-one `$8049`; after the
scheduler restores Y/X and performs `RTS`, execution resumes at `$804A`.
Bank `$18` maps `$8000-$9FFF` to file offset `0x030010+`.

The bytes at `$804A` are:

```text
JSR $8053
JSR $C560
JMP $8045
```

The parameter-`$73` actor-stream pointer resolves to `$9F42`; the supported
match-zero path reads `F4 04 52 9F`, selects the pointer row at `$9F44/$9F45`,
and reaches `$F5` at `$9F52`. The bounded executor follows the hash-checked
worker, pointer selector, command handler, fixed jump, and waiter spans through
the `$CC50 JSR $CB0F` entry. It fails closed when the live worker state differs
from this exact branch. This establishes static source behavior for the
packaged branch; the trace corroborates its task boundary, not every emulated
instruction or its visible PPU result.

The fixed-bank bytes at `$CC46-$CC5C` implement this wait sequence:

```text
$CC4D: PHA                 ; retains the caller's $06
$CC4E: LDA #$01
$CC50: JSR $CB0F           ; yield/save
$CC53: LDA $0515           ; next continuation after the yield
$CC56: BNE $CC4E           ; repeat the yield while nonzero
$CC58: LDA #$01
$CC5A: STA $0515           ; proceed from the zero branch
```

The trace proves entry to `$CB0F` from `$CC50` on the later yield and proves
that the following scheduler resume retains the `$CC53` return address. It
does not record the exact `$0515` value at either decision, so the branch taken
in each observed pass remains unverified.

## 2026-10-30 production-route extension

The recorded-input Godot route now continues the initial animation wait beyond
the first `$E8` delay. It follows the `$05E9` decrement across repeated route
ticks and accepts the resulting live `$05E4=$01`, `$05E5=$03` continuation at
`$804A`. In the `$05E4` inline vector table, `$806A/$806B` contains
`18 82`, selecting bank-$18 `$8218`.

The earlier static interpretation that `$9F55=$08` selects `$81D1` is
superseded by the instruction-level FCEUX evidence below. The matching route
uses bank-$19 stream data at `$A3C9` and `$A439`; `$05E5=$01` reads `$20` and
`$10`. Since `$821F` is `BCS`, both bytes fall through to `$8234`; neither
reaches `$81D1`. The separate `$81D1` source span remains in the manifest, but
it is not part of this traced route.

The route's `$8234` handler shifts the event byte to select type 2 or 1. Both
indices return `$0E` from `$86B8`; `$8DC4/$8DC6` resolve to `$8E37/$8E94`, and
both payloads are `$2C,$22,$14`. The worker stores `$05E7=$14`, loads
`$05E8=$06`, and waits through `$8266/$826C` while the counter falls from 6 to
1. The hash-checked bank-$19 stream span is
`bank19_actor_event_stream_a3c9_a43b.bin`. The Godot executor models the
`$8218->$8234` instruction prefix but stops if the live event state does not
match the trace. In the current recorded-input Godot route, it reaches
`$8218` at software frame 8710 with pointer `$9F52`, index `$03`, and byte `$08`
at `$9F55`. That differs from the FCEUX event states at frames 8626/8761.
Because the frame clocks are not aligned, the state mismatch is confirmed but
its earliest cause is not. The previous `$9F56=$2E` and `$F610` hypotheses are
not established as the next transition for this observed route.

The route's Godot frame labels remain software ticks. They do not establish
FCEUX frame or CPU-cycle parity.

## Corrected muted FCEUX actor-dispatch trace

The trace used FCEUX 2.7.0, NTSC/NewPPU, muted audio, the same recorded input,
and a signature-checked in-memory checkpoint at frame 8399. It ran two passes
over frames 8400-8953 and captured 3277 event-hook rows per pass. All rows
matched after normalizing the pass number. The purpose-built script is
[`trace_slot11_actor_dispatch_after_8399.lua`](../../../tools/diagnostics/trace_slot11_actor_dispatch_after_8399.lua);
raw output and metadata are under
[`slot11_actor_dispatch_trace_20261030_final`](../../diagnostics/slot11_actor_dispatch_trace_20261030_final/metadata.txt).

| Frame | Source event | Observed state |
|---|---|---|
| 8481 | `$804A->$8087` F4/F5 dispatch | The worker reads F4 from `$9F42`, resolves the next stream pointer to `$9F52`, then reads F5 with selector `$02`. |
| 8494-8495 | `$E8` countdown setup | `$05E4/$05E5` becomes `$01/$03`; `$05E9` is loaded with `$E8` and starts decrementing on resumed worker ticks. |
| 8622 | Delayed worker | `$05E9` is still `$69` at `$804A` and `$68` after the `$804D` countdown step. |
| 8624 | New `$804A->$8087` F4 dispatch | A worker entry with pointer `$A3BD` reads selector `$03`; `$811E` reads live row `$0629=0`, and the pointer calculation resolves the active stream to `$A3C9`. |
| 8626 | `$8218->$821F->$8234` | Pointer `$A3C9`, index `$01`, event byte `$20`; type 2 selects `$0E` at `$86BA`. |
| 8626 | `$8234-$8261` payload setup | Type 2 selects pointer `$8E94`; payload is `$2C,$22,$14`. `$05E7` becomes `$14`, `$05E8` is loaded with `$06`. |
| 8627-8632 | `$8266/$826C` wait | Six queue/wait iterations, counter values `$06` down to `$01`. |
| 8761 | `$8218->$821F->$8234` | Pointer `$A439`, index `$01`, event byte `$10`; type 1 selects `$0E` at `$86B9` and pointer `$8E37`. |
| 8762-8767 | `$8266/$826C` wait | The same six-count wait pattern is observed. |

The same trace records the later inactive selector-$03 animation countdown:
frame 8664 executes `$A21A` with animation pointer `$A2B6`, then yields with
pointer `$A2B8` and `$05F5=$05`. At `$804A` on frames 8665-8670, the worker
retains `$A2B8` while `$05F5` decreases from `$05` to `$00`; frame 8671 runs
`$A21A` and advances the pointer to `$A2BA`. This trace confirms the `$A2B8`
wait state and its per-frame cadence; it does not establish the later `$A2BA`
animation branch.

Neither `$81D1` nor `$F610` executes in this trace. The next unresolved source
transition is the `$8DC2` payload's live queue/PPU consumer and how the actor
worker resumes after the `$8266/$826C` wait.

## Godot route boundary update — 3 November 2026

The production route now reaches the slot-$11 worker at frame 8624. ROM bytes
at bank-$18 `$811E` (`AE 29 06 60`) implement `LDX $0629; RTS`; bank-$19 bytes
at `$A3BD` (`F4 03 C9 A3 E3 A3 F7 A3 0C A4 29 A4`) contain the selector and
pointer rows. The executor hash-checks both spans and resolves selector `$03`
through `$0629` to `$A3C9`; the focused fixture verifier passes this mapping.
The live route still stops at `$8080` on the first `$01` delay byte, before its
`$804D` wrapper return and `$CB0F` yield are modeled. The full same-input route
verifier stops at frame 8624 and reports four assertions, including earlier
stack/NMI/PPU boundary mismatches. The FCEUX trace proceeds to event `$20` at
`$A3C9` on frame 8626, but that does not establish Godot route or visible-output
parity. See the production executor and verifier for the bounded implementation.

## FCEUX observations

The evidence comes from FCEUX 2.7.0, NTSC/NewPPU, muted audio, starting at the
signature-checked in-memory checkpoint at source frame 8399. Two passes across
frames 8400-8953 matched exactly after normalizing the pass number:

- task-event SHA-256: `5bb43126def3352bbaeb44530ed712c16a8b112badbc300d76ef2ff33c8f9a4a`
- watched-write SHA-256: `c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22`

Relevant pass-1 rows in
[`task_events.csv`](../../diagnostics/first_command_task_boundary_20261028_070655_utc/task_events.csv)
and [`task_writes.csv`](../../diagnostics/first_command_task_boundary_20261028_070655_utc/task_writes.csv):

| Source frame / cycle | Event | Evidence |
|---|---|---|
| 8480 / 5141 | Initial actor-worker `$CB0F` save | Slot `$11` is current; A/X/Y/P=`$01/$42/$E7/$20`; task stack contains return `$8049`. |
| 8481 / 1944 | Scheduler's first slot-$11 resume | Task record is `01 C6 18 19`; stack bytes restore Y/X=`$E7/$42` and return `$8049`, so the resumed worker PC is `$804A`. |
| 8481 / 22878 | Next slot-$11 `$CB0F` event | CPU is at `$CB0F`, A/X/Y/P=`$01/$52/$0C/$30`, SP=`$C1`; the live stack word at `$C2/$C3` is `$52/$CC`, identifying callsite `$CC50` and resume PC `$CC53`. The subsequent save writes delay `$01`, SP `$BF`, and mapper `$18/$19` to the slot-$11 record. |
| 8482 / 1944 | Slot-$11 resumes again | Record is `01 BF 18 19`; stack bytes begin `0C 52 52 CC`, preserving `$CC53` as the return target. |
| 8482 / 15790 | Another slot-$11 `$CB0F` event | The same `$CC50` return-minus-one is present. The trace is consistent with the wait loop, but does not sample `$0515` at the branch. |

The full trace metadata, input hashes, checkpoint signature, repeat-pass
validation, and event hooks are documented in
[`first_command_task_boundary_trace_20261028.md`](first_command_task_boundary_trace_20261028.md).
The CSV's `sp` field is a RAM sample, not CPU SP; the CPU SP values above come
from the task-boundary event hooks.

## Production consumer contract and stop condition

The next live consumer should accept only the scheduler's actual selected
slot-$11 context. For the first resume, it must carry the saved record
`01 C6 18 19`, full RAM/stack, registers, and mapper pair; dispatch must restore
`$804A` from the saved stack rather than injecting that PC. Execute the
ROM-derived continuation and reject unsupported actor-stream inputs. When the
source reaches `$CC50`, hand its actual A/X/Y/P/SP, stack, RAM, and mapper state
to the verified `$CB0F` save. The subsequent NMI/scheduler resume must restore
`$CC53` from the saved stack and read live `$0515`; do not replace the wait
with a fixed frame count.

The bounded next stop is the first `$CC50` yield, with a matched
same-input FCEUX record for task record/stack, mapper state, `$0515`, and
source-produced PPU queue. This current trace supplies task/stack evidence but
omits `$0515` and the complete PPU bus sequence at that boundary. It therefore
does not yet verify the next consumer or visible output. No field pixels,
actor pose, menu request, audio timing, or physical NES timing are claimed.

## Bounded executor and scheduler handoff

`RomSlot11ActorWorkerResumeExecutor` consumes a scheduler snapshot at `$804A`
and returns the ordered ROM-derived RAM/stack writes plus the pre-JSR state at
`$CC50`. It records the already-pushed JSR return word at stack `$C2/$C3` as
`$52/$CC`; the `$CB0F` entry state is A/X/Y=`$01/$52/$0C`, SP=`$C1`, and the
wait continuation is `$CC53`. The executor does not run `$CB0F`, model timing,
or produce PPU/APU events.

`RomGameplayTaskScheduler.apply_slot11_actor_worker_resume_result` checks the
source manifest and span hashes, confirms the executor's entry RAM/stack/
registers still match the active slot-$11 scheduler context, replays its
ordered writes, and calls the existing save logic with the pre-pushed frame.
It does not copy the executor's full RAM image or push `$CC52` a second time.
The focused verifier
[`verify_rom_slot11_actor_worker_resume_scheduler.gd`](../../../tools/diagnostics/verify_rom_slot11_actor_worker_resume_scheduler.gd)
passes with an explicitly synthetic `$804A` context and confirms the saved
record `01 BF 18 19`, X/Y stack bytes, return word, and scheduler cursor.

That verifier does not establish that the production route reaches `$804A` or
that same-input output matches FCEUX. The real route must still provide its
source-owned boundary and consume the returned save result. The later
`$CC53`/`$0515` wait decision, PPU queue effects, visible field output, and
matching audio remain outside this bounded transition.

## Production-route extension — 5 November 2026

The recorded-input production route now passes selector `$03` through
`$A3BD->$811E->$A3C9`, processes the slot-$11 event waiter, and returns through
`$804D` to the `$A217` animation gate. It stops at route frame 8637 because the
live type-$02 gate state has `$F5=$6A`; the same-input FCEUX state has `$F5=$6C`
with the other gate inputs matched. The route verifier still reports four
assertions, including earlier stack, NMI, and PPU-boundary mismatches. This is
not evidence that the counter should be adjusted: the scheduler/source-frame
ordering leading into the gate remains different.

The retained FCEUX `events.csv` shows the slot-$11 `$C4` waiter count falling
from `$06` to `$00` over source frames 8482–8487, followed by the `$C0` task
transition at frame 8489. The production route reaches `$C0` at frame 8487,
about two source frames earlier. The trace does not hook `$CC53` or sample
`$0515` at the branch, so it cannot identify which wait-loop condition accounts
for the phase difference. A direct CLI/Lua attempt did not produce a usable
branch trace; no new branch-read capture is claimed. Resolve this ordering at
the live `$CC53`/scheduler boundary before changing `$05F5` or asserting the
`$A217` yield. Field output and audio parity remain unverified.

## Production-route boundary update — 7 November 2026

The recorded-input verifier now passes the slot-$09 `$CAA5->$86F8` continuation,
the live E6 actor OAM path, and the no-direction `$CA55->$E3CA` return. It stops
at the next selected slot-$11 resume with stream `$A439`. The route snapshot has
`$05E4/$05E5=$00/$00`, `$C7=$EB`, and A/X/Y=`$39/$39/$EB`. The FCEUX
`actor_resume_804A` row at source frame 8761 instead has index `$01`, `$C7=$00`,
and A/X/Y=`$39/$39/$00`; the event byte at `$A439+$01` is `$10`. The pointer
match alone does not establish the same continuation. Resolve the earlier
source writes and route/emulator phase difference before extending this worker
branch. The verifier still reports four earlier stack/NMI/PPU assertions; no
field/menu or audio parity is established.
