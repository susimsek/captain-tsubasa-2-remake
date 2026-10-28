# First-command scenario event and continuation audit — 2026-10-28

## Scope and source identity

This is a ROM-byte audit of the bank-`$10` scenario reader, the scheduled
bank-`$0B` event callback, and the fixed-bank handoff that starts a bank-`$14`
actor animation stream. It does not execute or modify the Godot route. The
supplied Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Relevant PRG mappings are bank `$10` at file `0x020010` → CPU `$8000`, bank
`$0B` at `0x016010` → `$8000`, bank `$14` at `0x028010` → `$8000`, and the
fixed window at `0x03C010` → `$C000`. The muted replay cited below validates
timing only; its rows are not runtime data.

## Two different outputs in each four-byte scenario record

Bank `$10` `$803F–$808C` reads a record as four fields:

| Field | Source role | Consumer established by ROM bytes |
|---|---|---|
| `$0523` | Wait value | Fixed `$EC94` copies it to `$0519`; `$ED5B/$ED5F` decrements the counter. |
| `$0524` | Event-callback selector | Bank `$0B` `$814C` indexes callback pointer table `$87F6`. |
| `$0528` | Actor-animation selector | Fixed `$ECFA–$ED06` copies it to `$053C` and sets `$053A=$80` when not `$FF`. |
| `$0529` | Animation/worker parameter | Fixed `$ED15–$ED2D` copies it to `$05EA` and can start a separate bank-`$18` worker in slot `$0011` when not `$FF`; `$ED0F` separately copies `$052A` to `$0517`. |

The callback selector and actor-animation selector are therefore separate
ROM consumers. Their values occur in the same source record, but the callback
script is not itself the animation stream and an event ID must not be passed
off as an actor animation ID. The actor stream is selected by `$0528`; its
source-clock waits are interpreted at bank `$14:$800F` after the fixed-bank
launch.

## `$C50F` seeds a separate task return

The bank-`$10` record setup at `$8097–$80A8` sets X=`$15`, `$0016=$F0`,
`$0017=$0B`, A=`$80`, and Y=`$08`, then calls fixed `$C50F` (file
`0x03C51F`, bytes `4C E7 CA`). `$C50F` jumps to `$CAE7` (file `0x03CAF7`),
which writes the caller's `$08/$80` values to `$01F1/$01F2` and marks
`$0015=$FF`. These stack bytes are the initial `RTS` return address `$8008`;
the scheduler's RTS increments it and enters bank `$0B` at `$8009`, whose
stub jumps to `$814C`.

This proves `$C50F` starts a bank-`$0B` event callback task. `$CAE7`'s final
`RTS` also returns synchronously to the bank-`$10` reader's `JSR $C50F`
caller; that is separate from the scheduler's seeded `$8008 → $8009` task
entry. Neither the helper nor the reader call itself decodes the callback
script or launches an actor animation. The reader, callback task, fixed
wait/worker handoff, and actor interpreter are separate execution paths.

## `$814C` callback dispatch and scheduler exit

Bank `$0B:$814C` (file `0x01615C`) loads the `$87F6` pointer-table base,
indexes it by `$0524`, stores the selected callback-stream pointer in
`$52/$53`, initializes the local stream index `$3A`, and reads the stream's
command/operand bytes. If the first byte is below `$F0`, it stores that byte
to `$0525` and sends the next byte through `$81A7`'s ROM handler vector; a
first byte at or above `$F0` instead routes through `$81BC`. The handler path
then sets bit `$10` in `$0516` and jumps through fixed `$C512`
(file `0x03C522`, bytes `4C F7 CA`) to `$CAF7`, which clears the active task
slot and its delay and returns control to the scheduler scan. The callback
path may invoke handlers that set up other workers or mutate background/event
state; those effects depend on the selected handler and its current RAM
context.

The callback table and the live event IDs used by this route resolve as
follows. The final column gives source bytes at the selected callback entry;
it is included to identify the ROM stream, not to imply every command's full
semantics is known.

| Event `$0524` | `$87F6` target | Stream file offset | Initial bytes |
|---:|---:|---:|---|
| `$3A` | `$89F3` | `0x016A03` | `02 00 42 02 05 00 00 4B ...` |
| `$0C` | `$8911` | `0x016921` | `02 00 43 01 00 4F ...` |
| `$72` | `$8B3E` | `0x016B4E` | `F2 19 00 2B ...` |
| `$1F` | `$896A` | `0x01697A` | `02 03 00 04 52 ...` |
| `$01` | `$88E3` | `0x0168F3` | `F0 02 00 52 ...` |
| `$45` | `$8A2A` | `0x016A3A` | `06 00 36 02 00 37 ...` |
| `$70` | `$8B38` | `0x016B48` | `06 00 56 02 00 80 F2 19 ...` |

The `$70` entry is independently traced to handler `$8327`, which reads map
selector `$56` and feeds bank `$0B:$8525`; that routine resolves selector
`$56` through `$86EE` to CHR pair `$3C/$2E`. This is a confirmed ROM event
callback/background producer. It is distinct from animation `$5C` in the
same scenario record.

## Live scenario records and their split dispatches

The compact muted same-input trace in
[`first_command_scenario_timing_20261028_045844_utc/README.md`](../../diagnostics/first_command_scenario_timing_20261028_045844_utc/README.md)
measured the route's actual record writes, event dispatches, wait handoffs,
and actor launches. The record values below come from the ROM scenario streams;
frames are validation evidence, not a runtime schedule.

| Scenario | Record bytes | Dispatch frame / `$0524` | Wait + actor launch frame | Actor `$0528` / parameter `$0529` |
|---:|---|---:|---:|---|
| `$35` | `02 3A 8F 73` | 8467 / `$3A` | 8480 | `$8F / $73` |
| `$36` | `10 3A 8F F0` → parameter `$FF` | 8593 / `$3A` | 8606 | `$8F / $FF` |
| `$36` | `20 0C 4E 74` | 8607 / `$0C` | 8623 | `$4E / $74` |
| `$36` | `32 72 66 F0` → parameter `$FF` | 8624 / `$72` | 8656 | `$66 / $FF` |
| `$36` | `32 1F 4C F0` → parameter `$FF` | 8667 / `$1F` | 8707 | `$4C / $FF` |
| `$36` | `3E 01 E6 75` | 8718 / `$01` | 8758 | `$E6 / $75` |
| `$1E` | `07 45 90 F0` → parameter `$FF` | 8789 / `$45` | 8821 | `$90 / $FF` |
| `$44` | `02 70 5C F0` → parameter `$FF` | 8893 / `$70` | 8906 | `$5C / $FF` |

The observed `$EC94` loads occur at the listed wait/launch frames. At the
actor handoff, `$ED01` copies the selected `$0528` to `$053C`, then `$ED06`
sets `$053A=$80`. The trace sees the bank-`$14:$800F` actor handler once per
source field frame. Its decoded animation commands then create/remove actor
records on relative animation ticks. Neither the trace frames nor endpoint
RAM/OAM should be used to synthesize an earlier actor pose.

## Dynamic state still required for a reusable Godot producer

The source bytes identify the routines and selectors, but a standalone
producer still needs the evolving state that the current route runtime does
not own:

1. **Scenario interpreter context:** `$0518`, source pointer `$5D/$5E`, byte
   index `$3A`, continuation depth `$0522`, continuation words `$051A–$0521`,
   mode `$0516`, operands/flags `$052A–$052D`, and `$0530/$0531`. The exact
   pointer-bounded route streams `$1E/$35/$36/$44` are now classified as root
   `$FB` terminators when the caller supplies depth zero; see
   [`first_command_scenario_stack_continuation_source_20261028.md`](first_command_scenario_stack_continuation_source_20261028.md).
   Nested `$FB` still needs live continuation payload, and `$FD $00` still
   reads receiver/player state through `$0441` and `$0638`.
2. **Task/scheduler context:** current four-byte task record (`$0015` delay/
   ready marker, `$0016` saved stack pointer, `$0017/$0018` saved banks) and
   peer slots, mapper shadows `$0024/$0025`,
   NMI/scheduler flags in `$001B`, and the order in which `$CA97`, `$CB0F`,
   `$CAE7`, `$CAF7`, and `$CAB6` run. The measured `$0519` decrement cadence
   does not replace the task state or callback side effects.
3. **Event callback context:** selected `$0524`, current `$52/$53` pointer and
   `$3A` index, `$0525`, `$05D0/$05D1`, and the command-specific background,
   map, scroll, and PPU staging state (including `$05CC–$05E2`, `$0490–$0497`,
   and callback-created task records). Only the callback IDs exercised here
   have partial handler evidence; there is no complete semantic model for all
   their commands and child-task lifecycles.
4. **Actor runtime context:** `$0528/$0529`, `$0517`, `$053A–$053D`, `$05EA`,
   the `$0011` worker record, animation pointer `$4C/$4D`, live actor records
   beginning at `$0547`, appearance/motion interpreter state, and
   selectors/mirror/scroll/clipping state consumed by `$83D9/$84DC` and the
   OAM builder. The decoded relative stream schedule supplies commands but
   does not apply these state transitions.

The current static animation decoder supplies relative command events but
does not apply these state transitions. Wiring it to a generic route timer or
displaying a frozen endpoint pose would invent event onset/state. ROM bytes
support a reusable event/actor producer only after the above task, handler, and
actor-record state transitions are modeled; the present evidence is not enough
to implement it safely in isolation.

## Next focused trace when the emulator owner releases it

Continue from the validated anonymous checkpoint at source frame 8399 with
audio muted and the same hashed route input. Do not use numbered save slots.
Record a compact instruction/call trace (without logging the `$CAAE` idle-spin
loop) with PC, bank, source frame/cycle, A/X/Y/P, current stack pointer, and
before/after values for:

- task setup/dispatch: `$C50F`, `$CAE7`, `$CA97`, `$CAB6`, `$CB0F`, `$CAF7`;
- scenario record and continuation: `$803F–$80A8`, `$881A–$884F`, `$814C`,
  `$81A7`, `$81BC`, plus writes to `$0516–$0531` and `$5D/$5E`;
- wait and worker handoffs: `$EC94/$EC9A`, `$ECFA–$ED2D`, `$ED5B/$ED5F`;
- actor execution: `$EE9F`, `$14:$800F`, `$80AA`, `$83D9`, `$84DC`, and writes
  across `$053A–$0547`, `$0517`, `$05EA`, and the `$0011` task record.

Also snapshot task slots, mapper registers, callback/animation pointers, and
the relevant background/OAM RAM at each boundary. This would establish which
callback handlers schedule delayed work, whether `$0524` or another state
advances between callback invocations, and how each selected `$0528` stream
changes live actor records. The trace must retain the source ROM/input hashes
and checkpoint signature. Until then, keep callback timing and actor-animation
commands separate in documentation and runtime APIs.
