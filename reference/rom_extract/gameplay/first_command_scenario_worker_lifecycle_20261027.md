# First-command scenario worker lifecycle — 2026-10-27

## Scope and evidence

Static source audit of the supplied Turkish ROM (SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`). It
follows the fixed-bank task dispatcher, bank-$10 scenario reader, bank-$0B
event callback, and the active-field actor loop. A later muted timing trace
now checks these routines against the same-input route; see
[`first_command_actor_animation_tick_source_audit_20261028.md`](first_command_actor_animation_tick_source_audit_20261028.md)
and its linked trace README. Capture rows remain diagnostic evidence only.

The relevant bank mapping is bank `$10` at file `0x020010` for the
`$8000–$BFFF` scenario reader, bank `$0B` at file `0x016010` for its event
callback, and the fixed `$C000–$FFFF` window at file `0x03C010`.

## Scenario record to event callback

After the bank-$10 reader consumes one four-byte record, `$803F–$80A8` stores
its fields in `$0523/$0524/$0528/$0529`. Its task setup at `$8097–$80A8`
(file `0x0200A7–0x0200B8`) is:

```text
A2 15       LDX #$15       ; task-record slot
A9 F0       LDA #$F0
95 01       STA $01,X      ; SP baseline $0016=$F0
A9 0B       LDA #$0B
95 02       STA $02,X      ; new-task bank base $0017=$0B
A9 80       LDA #$80
A0 08       LDY #$08
20 0F C5    JSR $C50F
60          RTS
```

At fixed-bank `$C50F` / file `0x03C51F`, the bytes are `4C E7 CA`: a jump to
`$CAE7` / file `0x03CAF7`. `$CAE7` (`48 98 B4 01 99 01 01 68 99 02 01 A9 FF
95 00 60`) uses the caller's `$0016` value as a stack-page offset, writes the
supplied `$08/$80` bytes to `$01F1/$01F2`, marks `$0015=$FF`, and returns.
Those bytes form the low/high return address consumed by the scheduler's
initial-task `RTS`; they resume at CPU `$8009`.

The bank-$0B bytes at `$8009` / file `0x016019` are `4C 4C 81`, so the initial
callback is `$8009 → $814C`. At `$814C` / file `0x01615C`, the handler loads
the dispatch table pointer `$87F6`, reads the scenario event selector from
`$0524`, and routes through the event-vector table near `$81A7`. This closes
the earlier ambiguity: `$C50F` schedules the bank-$0B event callback; it does
not resume the bank-$10 parser at its post-call address. The parser and the
event callback are separate cooperative tasks.

## Scheduler release and bank/stack restoration

The fixed-bank scheduler begins at `$CA97` / file `0x03CAA7`. Its scan checks
task delay bytes at slot offsets `1, 5, 9, 13, 17, 21`:

- A zero slot is skipped. `$FF` branches to the initial-ready path at `$CAD4`.
- A finite nonzero delay is decremented; a transition to zero dispatches the
  task on that scan.
- After scanning all slots, `$CAAE–$CAB4` waits for bit 7 of `$001B`, clears
  that ready latch, and restarts the scan. The ordinary NMI body sets
  `$001B.7` at `$C7EE`; the alternate `$C421` NMI route sets it in the bank-$02
  path. Thus the NMI latch gates another scheduler scan, while already-ready
  tasks can run immediately in slot order within a scan.

For a newly ready `$FF` task, `$CAD4–$CAE6` loads the slot's bank base into
`$0024`, sets `$0025=$0024+1`, maps those banks through `$CE2D`, loads the
saved stack pointer from the slot, and executes `RTS`. With the scenario
reader's slot values, that enters bank `$0B` at `$8009`. For a resumed finite
delay task, `$CAB9–$CAD3` restores both saved bank values from slot offsets
`+2/+3`, maps them through `$CE2D`, restores the stack pointer, restores the
saved registers, and returns into that task's prior context.

The common yield/save entry is `$CB0F` / file `0x03CB1F`. It records A as the
task's next delay, saves the current `$0024/$0025` mapper shadows and stack
pointer in the current task slot, then jumps to `$CAA5` to continue scanning
from the following slot. `$CBB0` / file `0x03CBC0` starts a scenario by
writing the ID to `$0518`, setting `$0516=$80`, clearing `$0005`, and calling
`$CB0F` with A=`$00`.

## `$EC94` wait handoff and actor cadence

At fixed-bank `$EC94` / file `0x03ECA4`, the code begins `AD 23 05 8D 19 05`:
it copies scenario field `$0523` to wait counter `$0519`. The decrement/store
sequence is at `$ED5B–$ED5E` / file `0x03ED6B–0x03ED6E`:
`CA 8E 19 05` (`DEX; STX $0519`), followed by a compare against `$28` at
`$ED5F`. The prior scenario audit's `$ED59–$ED5A` label is two bytes early;
those addresses are the preceding helper's operand/return boundary.

Actor animation interpreters follow a distinct path. The fixed-bank field loop
at `$CA4D–$CA58` calls `$CB0F` with A=`$01`, then `$EE9F`, then `$E3CA`, and
repeats. `$EE9F` switches to bank `$14` and calls its `$8000` actor-update
entry; that entry walks actor records and invokes the `$83D9` appearance and
`$84DC` motion interpreters for applicable actors. The existing deterministic
actor trace covers source frames 8400–8953 and records exactly one `$EE9F`
call per frame from 8461 through 8953 (493 frames). At the stable first-menu
endpoint it records three appearance and three motion interpreter calls per
frame, matching the three active actor records there. Interpreter call counts
vary during route transitions; the current trace does not reduce those extra
calls to a general actor-count formula.

The 2026-10-28 follow-up trace supports the following distinction for this
route:

- Scenario event callbacks are task work selected by the cooperative
  scheduler. They are not dispatched by a hardcoded “one scenario event per
  video frame” loop. `$0523 → $0519` is loaded at `$EC94/$EC9A` and
  decremented once per source frame at `$ED5B/$ED5F` in the traced route.
- The actor update/draw loop runs once per source frame in the captured active
  field interval. The per-actor interpreters execute synchronously inside
  that loop for the applicable records; they are not themselves a separate
  scenario-event cadence.
- `$C7EE/$C7F0` sets `$001B.7` and the scheduler clears it at `$CAB6` in the
  same source frame. `$CA97` is scanned 494 times over frames 8460–8953; the
  extra first call is the scheduler entry before the 493 measured actor frames.

## Remaining limits

The timing trace omits the tight `$CAAE` spin loop, so it does not preserve every
within-frame scheduler polling iteration. It does establish the NMI-ready
set/clear, one `$0519` decrement per source frame, eight actual bank-$0B
`$814C` dispatches, and one `$EE9F`/`$800F` actor-loop call on each of 493
measured field frames. Immediate `$FF` task starts may still run more than one
cooperative task before the next NMI latch. These are FCEUX/source-model
measurements, not physical NES processor timing.

The existing writer trace's two passes produced byte-identical CSVs and
snapshots (7,662 actor writes and 3,371 routine-call rows); FCEUX exited `-11`
after writing complete outputs. See
[`first_command_actor_writer_trace_source_map_20261027.md`](first_command_actor_writer_trace_source_map_20261027.md)
and its trace metadata for hashes and the shutdown caveat. These records
validate the static path and cadence only; they are not runtime actor state.

## Smallest useful runtime model

For a Godot route producer, retain a native task-slot scheduler with the
`$001B.7` ready latch, saved bank/stack context, `$FF` immediate-ready
handling, and finite delay decrements. Have the bank-$10 reader emit a typed
event that starts the bank-$0B `$814C` selector handler; keep `$0523` wait
state separate from the `$0524` event selector. The new relative animation
decoder maps `$800F` low-byte waits and `$F6` actor-removal operands, but route
dispatch/worker scheduling and per-actor appearance/motion execution remain to
be connected from ROM bytes. The measured one-per-source-frame cadence
validates this replay; it is not itself runtime input.
