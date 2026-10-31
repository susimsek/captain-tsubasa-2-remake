# Scenario-$36 Queue and Scheduler Boundary

## Result

The recorded-input Godot route executes the fresh-match scenario-$36 caller
from the live slot-$05 `$DB0E` boundary through its first event, slot-$09
continuation, slot-$11 actor task, and all 32 slot-$15 map cells. It reuses the
same controller sequence as the FCEUX reference and does not inject captured
state. This route milestone is not end-to-end same-input parity: an earlier
fresh-match handoff/task timeline discrepancy is still open.

## 31 October route continuation

The live route dispatches slot `$09` and consumes the first bounded scenario-
`$36` prefix. The scenario pointer comes from the ROM table as `$B7E4`; the
runtime validates its manifest mapping and reads the F5/F9 setup plus first
event `10 3A 8F F0`. It applies ordered writes and returns from `$EC74` to
`$EB9E` after seeding callback slot `$15`. The caller resumes at `$EB9E` and
reaches the `$86F8` worker vector. Slot `$15` is dispatched from its live task
record: callback `$3A` runs `$8009->$814C->$8327`, its map handler reaches
`$8525`, and the map-$42 setup executes through `$856F->$C515`. The scheduler
saves the task and waits for the next external NMI.

The focused same-input verifier is
`tools/diagnostics/verify_slot09_scenario36_ec74_live_route.gd`. Godot 4.7.2
reported PASS for the recorded frame, `$EC74->$EB9E` return, bank mapping,
event bytes/pointer, transformed fields, live RAM writes, callback record and
stack seed, caller return to `$86F8`, callback `$3A` and map-worker setup
through `$856F->$C515`, scheduler NMI-wait boundary, and no-action/no-Continue
limit. The callback record's fourth byte is checked against live `$0018`; it
is not assumed to be cleared. The latest run passed; Godot reported two
ObjectDB instances and one resource still in use during shutdown.

The check initially exposed an incorrect expected scratch byte (`$0526`): the
live source result is `$3C`, not `$BC`. The verifier was corrected and extended
through the first map-worker batch. This validates the executor's live source
contract; it does not compare every produced queue byte with same-boundary
FCEUX RAM.

## 31 October map batches and first normal-NMI transfer

At the live `$CB0F` continuation, the slot-`$15` record is `00 E9 0B 0C` and
`$05C7/$05C8/$05C9=$40/$A0/$20`. `$05C8` is the map placement cursor; `$05C7`
is the queue offset, which the `$8572` worker resets before writing a batch.
Godot now accepts this source-observed initial cursor as well as the separate
zero/zero standalone case. It executes three map-$42 cells (block `$14`) and
builds a 96-byte queue at placement `$A0`, ending with `$05C7=$60`,
`$05C8=$A3`, `$05C9=$1D`, and ready flag `$0515=$80` before yielding at
`$856F->$C515`.

The route builds eleven ROM-derived batches through frame 8604, covering all
32 map cells. The normal batches contain 96 bytes. At placements `$B8-$BD`,
the worker tests `(placement & $3F) >= $38` at `$86AF-$86B4`, then compacts the
attribute packet and terminator from `$04C1,Y` to `$04B3,Y` at `$86BC-$86D0`
and advances X by `$12`. The two three-cell row-wrap batches each contain 54
bytes and return X/Y `$36/$29`. The terminal batch at `$BE-$BF` contains two
cells, advances X by `$24`, and returns Y `$17` at `$85BE`. The focused
same-input verifier passes for all eleven batches and confirms the worker's
yield registers against both FCEUX traces through the terminal yield.

### Queue-byte and terminal-return verification

The RAM snapshots for source frames 8602, 8603, and 8604 retain the final
row-wrap and terminal queues. Godot now compares each queue's length, payload,
terminator, and cursor with those FCEUX snapshots. All three payloads match
byte-for-byte. The comparison exposed a bug in the map placement address
formula: nametable page bits were shifted by two instead of four, producing
`$2380` where the ROM trace requires `$2B80`. The formula was corrected and the
three queue comparisons pass.

After the terminal yield, the live route resumes slot `$15` at `$85C1` with
cursor/placement `$24/$C0`, remaining count `$00`, and callback byte
`$05CD=$A0`. The ROM callback takes its nonzero branch: it writes `$05CE=$A0`,
then `$05CD=$80`, clears `$05DB-$05DD`, returns to `$819C`, sets bit `$10` in
`$0516`, and follows `$C512->$CAF7`. Godot now executes this branch from live
RAM/stack state, finishes slot `$15`, and returns the scheduler to its NMI wait
at source frame 8605. The scheduler's restored task bank now also updates its
`$0024/$0025` shadows, as the source dispatch routine does. The verifier
compares 24 selected callback/task/mapper bytes in the finished route RAM with
the same-input frame-8605 FCEUX snapshot; they match. This includes the
callback outputs and cleared slot-$15 record. Full 2 KB RAM parity is not
claimed: slot `$01`'s saved high-bank byte at `$0003` differs (`$00` in Godot,
`$16` in FCEUX), and that live scheduler-state mismatch remains open.

Godot's normal-NMI consumer still emits ordered PPU bus events without applying
them to its visible renderer. The complete field CHR, palette, nametable,
scroll, and raster baseline is not established. Visible field pixels, later
command-menu behavior, audio parity, and CPU-cycle timing remain unverified.
The focused verifier reports two ObjectDB instances and one resource in use at
shutdown.

## Slot-$11 continuation update

The live Godot route reaches a slot-$11 `$8047->$C515->$CB0F` countdown yield
and scheduler NMI wait at source frame 8606. This proves that a ROM-backed
worker runs to that boundary; it does **not** match the same-input FCEUX state.
The focused verifier compares two independent FCEUX trace passes, worker
registers, active stack words, actor counters, and frame-end task/RAM bytes.
Both trace passes agree, but the Godot comparison fails.

The focused verifier now records changes to Godot's live scenario RAM and
compares them with the frame-end FCEUX RAM captures. The snapshots already
differ by frame 8443: Godot has `$0516-$0519 = 00 00 00 00` and empty slot-$09/
slot-$11 records, while FCEUX has `$01AC0000`, slot `$09 = 00 00 00 09`, and
slot `$11 = 01 E0 00 02`. Godot has scenario `$35` fields by frame 8450, while
FCEUX is still in its `$01AC` state at that frame.
FCEUX enters the fresh-match handoff at `$A2AF` on frame 8458, clears RAM through
`$AA06` at 8459, initializes the root scheduler at 8460, and its frame-end RAM
first shows scenario `$35` fields at frame 8467. Godot first yields slot `$11`
at frame 8463. The separate two-pass FCEUX CPU-hook trace first observes the
actor-worker `$8047` yield at frame 8480, after the slot-`$15` callback has
finished. These are different observation boundaries: the exact first
slot-`$11` seed/write time between the frame-end RAM capture and the first
hooked worker yield has not been established. The route verifier does not yet
resolve the earlier scenario/task producer divergence.

By frame 8480 Godot has already run slot `$11` and reached stream index
`$0103`, delay `$E5`, and animation `$0D01E9`; FCEUX is at its initial `$8047`
yield with zero counters. The resulting counter mismatch is downstream of an
earlier task-order/source-state mismatch. It is not explained by the numerical
proximity between Godot's `$E5` and FCEUX's later `$E8` load.

On frame 8481, FCEUX resumes at `$804A`, enters the initial F4/F5 parser state,
and reaches the `$CC50` wait. By frame 8494, it loads the `$E8` countdown. At
frame 8606, Godot's `$05E9` is `$67` while FCEUX's is `$78`; Godot's animation
counter ends at `$0D016B` while FCEUX's is `$0D017C`. The next investigation is
the Godot scenario-`$35` producer and its scheduler predecessor relative to
FCEUX's `$A2AF->$AA06` fresh-match handoff. Then resolve slot `$11`'s first
seed/write boundary using same-input frame-end RAM and hook evidence, including
slot `$09`'s `$ED15->$CAE7` call. Do not correct this with an arbitrary delay
or extend the route to later field/menu tasks until the source transition
matches.

## ROM evidence and checks

- The caller is the fixed-bank entry at CPU `$DB0E`, file offset `0x03DB1E`,
  bytes `A9 36 20 B0 CB`; its extracted root and hash are in
  `first_command_scenarios/manifest.json`.
- The `$CBB0` helper bytes are packaged at
  `scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin`. They write
  `$0518=$36`, `$0516=$80`, and `$0005=$00`, then call `$CB0F`.
- The executor starts from the live scheduler RAM/stack/register snapshot. It
  validates the nested JSR words and writes against the instruction path; it
  does not consume captured RAM, screenshots, or audio.
- At `$CB0F` entry the nested caller stack pointer is `$4C`. The scheduler's
  source-verified save pushes X/Y and records slot `$05` at PC `$CB0F`, SP
  `$4A`, ready delay `$00`, and banks `$1C/$1D`.
- The post-yield scan selects slot `$09` at its pending-resume boundary. Its
  scenario consumer has not yet run.

## Verification at the earlier slot-selection boundary

Ran the same-input recorded route:

```text
CT2_ROUTE_EXPECT_SCENARIO36=1 godot --headless --path . --script res://tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: PASS. At source frame 8593, the route verifies the `$DC07` position
setup, all 22 position pairs against the same-input FCEUX RAM oracle, recorded-
route RNG state `$7F/$BE/$3C`, holder slot 8, receiver slot 6, scenario-$36
queue, slot-$05 save, and slot-$09 selection. These checks establish software
route state for one input hash; they do not establish CPU-cycle or PPU-dot
timing.

That earlier verifier's expected stop before slot-$09 dispatch is now stale;
it is historical evidence for the prior boundary only, not a PASS result for
the current route. Use the focused continuation verifier above.

## Remaining work

Trace the fresh-match handoff and slot-$11 source state through frames 8458–8480,
where Godot's scenario/task state is already ahead of FCEUX. Make the live
scheduler and worker select the same F4/F5 and
`$CC50` wait path before extending later tasks. Then require matching actor
counters and task state through frame 8606, resolve the slot-$01 bank-high
mismatch if it affects the handoff, establish the live field's ROM-derived PPU
baseline, apply queue events to the renderer, continue through the initial
command-menu request, implement cursor navigation, compare route audio, and
verify ROM/emulator-free runtime. The recorded input route still uses its
fixed-hash RNG replay; arbitrary input histories are not implemented.
