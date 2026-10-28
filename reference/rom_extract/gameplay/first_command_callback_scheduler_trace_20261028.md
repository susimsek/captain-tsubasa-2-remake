# First-command callback and scheduler trace — 2026-10-28

## Scope and conclusion

This follow-up checks the missing bank-`$10` scenario `$44` continuation and
bank-`$0B` callback path against the supplied Turkish ROM. It does not change
the Godot route. The callback dispatch and the `$8327` placement formula are
source-resolved, and the live muted replay confirms their order. The path is
not yet safe to wire into `KickoffRouteRuntime`: the byte reader and bounded
stack helper now classify the four exact route streams' depth-zero `$FB`
terminators, while the Godot route still lacks live continuation/task state and the
cooperative task/mapper/stack state and earlier callback history that provide
the incoming shared `$05CD` value.

## ROM call chain

The supplied ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The relevant source spans are:

| Source | ROM span | Resolved behavior |
|---|---|---|
| Scenario `$44` | file `0x0237E5`, `02 70 5C F0 FB` | The four-byte record yields `$0523=$02`, event selector `$0524=$70`, actor selector `$0528=$5C`, transformed parameter `$0529=$FF`; its exact hash-checked root stream classifies `$FB` as termination at explicit depth zero. The outer task/CPU return is not modeled. |
| Fixed task helper | `$C50F` file `0x03C51F` → `$CAE7` file `0x03CAF7` | Seeds task slot `$0015` with return `$8008`; the scheduler's RTS enters bank `$0B:$8009`. |
| Bank-`$0B` callback reader | `$814C` file `0x01615C`; event `$70` pointer entry `$88D6` file `0x0168E6` → `$8B38` | Resolves the callback pointer from `$87F6`, reads `06 00 56 02 00 80`, and dispatches its first operation. |
| Handler vector | `$81A7` file `0x0161B7` | Dispatch subindex `$00` resolves to `$8327`. The callback's third byte `$56` is the map selector. |
| Placement/map handler | `$8327` file `0x016337` → `$8525` file `0x016535` | Reads global `$05CD`, calls the map expander, then writes `$05CE` at `$8342` and toggles `$05CD` at `$8349`. `$05CD` is shared RAM, not a callback argument or task-slot field. |
| Cooperative yield | `$C515` file `0x03C525` → `$CB0F` file `0x03CB1F` | `$8525` calls the yield trampoline while building/transferring the map data. `$CB0F` saves task state and returns to the scheduler. |
| Task scheduler | `$CA97` file `0x03CAA7`; ready path `$CAD4–$CAE6`; task seed `$CAE7` | Scans task delay slots, handles `$FF` immediate-ready tasks, restores mapper/stack state, and yields between scheduled pieces using the `$001B.7` NMI-ready latch. |

The source bytes establish a coroutine-like route: `$8327` enters `$8525`,
which yields via `$CB0F`; the scheduler resumes that task on a later scan, and
only then does `$8327` complete the `$05CE/$05CD` transition. A one-frame
scenario timer or a direct `$44 → $8327` call would skip that execution state.

## Muted FCEUX replay

`tools/diagnostics/run_first_command_callback_state_trace.py` performs two
identical replays from the signature-checked anonymous in-memory checkpoint
at source frame `8399` (FCEUX 2.7.0, NTSC, NewPPU, audio muted). It does not
use numbered save slots. Each load checks source frame/cycle, all 2 KiB RAM,
all 16 KiB PPU memory, MMC3 selectors/banks, and mapped PRG bytes before
tracing. Inputs are hash-pinned in the output metadata; the ROM and route
input hashes are recorded there. Both passes produced 20,052 ordered hook
events and 51,562 watched writes; after normalizing the pass label, both event
and write traces match exactly. The run completed with exit code 0 in 13.981 s.

Trace outputs:

- [`metadata.txt`](../../diagnostics/first_command_callback_state_20261028_061906_utc/metadata.txt)
- [`callback_events.csv`](../../diagnostics/first_command_callback_state_20261028_061906_utc/callback_events.csv)
- [`callback_events_repeat.csv`](../../diagnostics/first_command_callback_state_20261028_061906_utc/callback_events_repeat.csv)
- [`callback_writes.csv`](../../diagnostics/first_command_callback_state_20261028_061906_utc/callback_writes.csv)
- [`callback_writes_repeat.csv`](../../diagnostics/first_command_callback_state_20261028_061906_utc/callback_writes_repeat.csv)

The replay observes scenario `$44` start at frame `8893`, followed in that
frame by task creation/seeding, the `$814C` callback reader, vector `$81A7`,
and the first `$8327` entry. At that entry the pointer is `$8B38`, the callback
bytes are `06 00 56`, and incoming shared `$05CD=$A0`. The handler enters the
yield path at `$CB0F` later in that same source frame. Its first placement
write occurs 12 source frames later, at frame `8905`: bank `$0B:$8342` writes `$05CE=$A0`, then
`$8349` writes `$05CD=$80` (write hooks report post-instruction PCs `$8345`
and `$834C`). The measured delay is produced by worker progress and scheduler
state; it is not encoded as a frame constant in the implementation.

Earlier `$8327` writes from this same replay explain how the incoming shared
byte was produced:

| Frame | Scenario / callback | `$05CD` before | `$05CE` written | `$05CD` after |
|---:|---|---:|---:|---:|
| 8479 | `$35 / $3A` | `$00` | `$00` | `$A0` |
| 8605 | `$36 / $3A` | `$A0` | `$A0` | `$80` |
| 8619 | `$36 / $0C` | `$80` | `$80` | `$A0` |
| 8647 | `$36 / $72` | `$A0` | `$A0` | `$80` |
| 8681 | `$36 / $1F` | `$80` | `$80` | `$A0` |
| 8734 | `$36 / $01` | `$A0` | `$A0` | `$80` |
| 8803 | `$1E / $45` | `$80` | `$80` | `$A0` |
| 8905 | `$44 / $70` | `$A0` | `$A0` | `$80` |

These frames are replay evidence only. The ROM formula explains each
transition, but Godot must generate the callback order and shared RAM value
from the route's decoded state rather than replaying this table or seeding
`$05CD=$A0`.

## Why the callback task remains unintegrated

The fixed-bank scheduler's core loop can be read from ROM bytes, but a safe
runtime port for this route needs the live task records and more than delay
counters: saved PC/return stack, stack pointer, bank pair, task ordering,
`$001B.7` readiness, and the exact yielding point inside `$8525`. It also
needs the bank-`$10` continuation state at `$5D/$5E`, `$0522`, and
`$051A–$0521`, plus callback-specific `$05CC–$05E2` and transfer-queue state.
The route must first execute the earlier `$35/$36/$1E` callbacks that own the
incoming `$05CD`. The existing source-backed callback API resolves only the
first `$44/$70` operation and intentionally requires `$05CD` from its caller.

Porting only a delay-slot scheduler would therefore appear reusable while
still fabricating the callback's return point and prior shared state. A later
bounded runtime model now handles the cold bootstrap, ROM-ordered task scan,
the first slot-`$01` startup through `$CA4F`, and the explicit `$8097` callback
seed; see
[`first_root_slot01_startup_runtime_20261028.md`](first_root_slot01_startup_runtime_20261028.md).
It still does not execute the callback continuation or route it through
`$814C → $8327 → $8525 → $C515/$CB0F`, and it does not produce the prior
`$05CD` history. The remaining increment is to model those source-owned task
continuations and compare their transitions with this trace before wiring the
live route.
